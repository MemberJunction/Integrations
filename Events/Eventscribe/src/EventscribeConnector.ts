import { AsyncLocalStorage } from 'node:async_hooks';
import { z } from 'zod';
import { RegisterClass } from '@memberjunction/global';
import { Metadata, type UserInfo } from '@memberjunction/core';
import type {
    MJCompanyIntegrationEntity,
    MJCredentialEntity,
    MJIntegrationObjectEntity,
    MJIntegrationObjectFieldEntity,
} from '@memberjunction/core-entities';
import { IntegrationEngineBase } from '@memberjunction/integration-engine-base';
import {
    BaseIntegrationConnector,
    BaseRESTIntegrationConnector,
    computeContentHash,
    serializeKeyValue,
    type RESTAuthContext,
    type RESTResponse,
    type PaginationState,
    type PaginationType,
    type RateLimitPolicy,
    type ConnectionTestResult,
    type ExternalRecord,
    type FetchContext,
    type FetchBatchResult,
    type FetchWarning,
    type SourceSchemaInfo,
    type SyncErrorCode,
    type ErrorSeverity,
    type CreateRecordContext,
    type UpdateRecordContext,
    type DeleteRecordContext,
    type GetRecordContext,
    type CRUDResult,
} from '@memberjunction/integration-engine';
import { mergeDeclaredWithSampledFields } from '@memberjunction/connector-schema-merge';

// ─── Design note — WHAT THIS VENDOR ACTUALLY IS ───────────────────────────────
//
// Cadmium/Eventscribe is NOT a resource-oriented REST API. `Configuration.ReadContract` (metadata)
// states it verbatim: "RPC-over-querystring ... Multiple, sometimes dozens of, unrelated operations
// share the exact same URL and even the same HTTP verb -- the `Method` query param IS the
// routing/dispatch mechanism". Three consequences shape every override in this file:
//
//   1. THE CREDENTIAL IS A QUERY PARAM, NOT A HEADER. `Configuration.AuthCredentialTransport` =
//      'query-param', `AuthHeaderPattern` = null. `BuildHeaders` therefore carries NOTHING
//      auth-related; the credential is injected in the request-building path (`SendRequest`).
//      A Bearer/Basic header here would simply never authenticate.
//
//   2. THERE IS NO SINGLE BASE URL. `Configuration.BaseURLsByFamily` carries FIVE family tags across
//      THREE hosts, and `BaseURLsByFamilyNote` is explicit that a connector which bakes one base URL —
//      or which collapses 'asset' and 'eventscribe-web' because they happen to resolve to the same
//      host — produces a runtime failure. `GetBaseURL` therefore resolves PER OBJECT from that object's
//      own metadata. The base class's `GetBaseURL(ci, auth)` signature has no object slot, so the
//      per-call object identity rides an AsyncLocalStorage scope (see {@link scope}) rather than a
//      mutable field that two concurrent pushes would race on.
//
//   3. THE OBJECT UNIVERSE IS LARGER THAN ITS DOORS. Roughly half the declared objects carry
//      `accessPath.depth >= 1`: they have NO read operation of their own and arrive nested inside a
//      door operation's response under a declared container key. `FetchChanges` walks that access path
//      instead of assuming one flat query per object — assuming flat would pull ZERO rows for each.
//      (The count is deliberately not written down here; it is whatever the metadata declares.)
//
// NO CATALOG LIVES IN THIS FILE. Cadmium publishes no describe/list endpoint anywhere in the corpus
// (`Configuration.DiscoveryIsAuthoritative` = false), so the DECLARED IntegrationObject /
// IntegrationObjectField rows ARE the catalog. `DiscoverObjects`/`DiscoverFields` are deliberately NOT
// overridden: the base implementations read those rows back through the engine cache, which is the
// only correct source. A literal object/field array in this file would be the frozen-catalog defect.

// ─── Metadata shapes (parsed, never guessed) ──────────────────────────────────

/** `IntegrationObject.Configuration.accessPath` — how this object's records are actually reached. */
const ZAccessPath = z
    .object({
        doorOperation: z.string().optional(),
        doorObject: z.string().optional(),
        nestingFieldPath: z.string().optional(),
        depth: z.number().optional(),
        isArray: z.boolean().optional(),
    })
    .passthrough();

/** `IntegrationObject.Configuration.dispatch` — the RPC routing facts for this object's read door. */
const ZDispatch = z
    .object({
        mechanism: z.string().optional(),
        methodParamName: z.string().optional(),
        methodValue: z.string().nullable().optional(),
    })
    .passthrough();

/** `IntegrationObject.Configuration.pagination.envelope` — where the page counters live in the body. */
const ZPaginationEnvelope = z
    .object({
        totalRecordsKey: z.string().optional(),
        totalPagesKey: z.string().optional(),
        currentPageKey: z.string().optional(),
        container: z.string().optional(),
    })
    .passthrough();

/** `IntegrationObject.Configuration.pagination` — the PROVEN request param + response envelope. */
const ZPagination = z
    .object({
        paramName: z.string().optional(),
        type: z.string().optional(),
        pageSize: z.number().optional(),
        envelope: ZPaginationEnvelope.optional(),
    })
    .passthrough();

/** A rate-limit fact, at either integration or object scope. */
const ZRateLimit = z
    .object({
        requestsPerWindow: z.number().optional(),
        windowMs: z.number().optional(),
        scope: z.string().optional(),
    })
    .passthrough();

/** `IntegrationObject.Configuration.writeOperation` / `.deleteOperation`. */
const ZWriteOperation = z
    .object({
        operationId: z.string().optional(),
        verb: z.string().optional(),
        idParam: z.string().nullable().optional(),
        bodyShape: z.string().nullable().optional(),
        requestShape: z.string().optional(),
        createIDLocation: z.string().nullable().optional(),
    })
    .passthrough();

/**
 * `IntegrationObject.Configuration.watermark` — the vendor's OWN server-side time-window filter for
 * one object's read door, when it documents one. Absent ⇒ the object has no incremental mechanism and
 * a full pull is the only honest read (this vendor's `watermarkProvenNegative` says so per object).
 */
const ZWatermark = z
    .object({
        field: z.string().optional(),
        startParam: z.string().optional(),
        endParam: z.string().optional(),
        valueFormat: z.string().optional(),
        urlEncodeRequired: z.boolean().optional(),
    })
    .passthrough();

/** `IntegrationObject.Configuration.outOfScope` — why an emitted object ships Disabled. */
const ZOutOfScope = z
    .object({
        family: z.string().optional(),
        emittedButDisabled: z.boolean().optional(),
        credentialModel: z.string().optional(),
    })
    .passthrough();

const ZObjectConfig = z
    .object({
        family: z.string().optional(),
        absoluteEndpoint: z.string().optional(),
        baseUrl: z.string().optional(),
        dispatch: ZDispatch.optional(),
        accessPath: ZAccessPath.optional(),
        pagination: ZPagination.optional(),
        rateLimit: ZRateLimit.optional(),
        nestedContainerKey: z.string().optional(),
        parentObjectName: z.string().optional(),
        parentObjectIDFieldName: z.string().optional(),
        requiresRecordKeyToRead: z.string().optional(),
        responseFormat: z.string().optional(),
        watermark: ZWatermark.optional(),
        outOfScope: ZOutOfScope.optional(),
        writeOperation: ZWriteOperation.optional(),
        deleteOperation: ZWriteOperation.optional(),
    })
    .passthrough();

type EventscribeObjectConfig = z.infer<typeof ZObjectConfig>;

const ZFamilyBaseURL = z.object({ family: z.string(), baseUrl: z.string() }).passthrough();

const ZRateLimitOverride = z
    .object({
        methods: z.array(z.string()).optional(),
        requestsPerWindow: z.number().optional(),
        windowMs: z.number().optional(),
    })
    .passthrough();

const ZIntegrationConfig = z
    .object({
        AuthCredentialParamName: z.string().optional(),
        AuthMultiTenantParam: z
            .object({ name: z.string().optional(), required: z.boolean().optional() })
            .passthrough()
            .optional(),
        ReadContract: z.object({ methodParamName: z.string().optional() }).passthrough().optional(),
        BaseURLsByFamily: z.array(ZFamilyBaseURL).optional(),
        /**
         * Single-origin OVERRIDE. When set, EVERY object resolves to this origin regardless of
         * family — the deliberate escape hatch for pointing the whole connector at one host that
         * is standing in for all five Cadmium hosts: a mock server, a sandbox, or a corporate
         * proxy. Unset in production, where {@link BaseURLsByFamily} is the real resolver.
         *
         * This is NOT the "baked host" the family map exists to prevent: it is explicit
         * configuration supplied per connection, never a constant in this file.
         */
        BaseURL: z.string().optional(),
        RateLimits: z
            .object({ standard: ZRateLimit.optional(), overrides: z.array(ZRateLimitOverride).optional() })
            .passthrough()
            .optional(),
        BatchSemantics: z.record(z.unknown()).optional(),
    })
    .passthrough();

type EventscribeIntegrationConfig = z.infer<typeof ZIntegrationConfig>;

// ─── Connector-local types ────────────────────────────────────────────────────

/** The two per-connection credential values. `eID` is optional per `Configuration.AuthMultiTenantParam`. */
interface EventscribeCredentials {
    APIKey?: string;
    EventID?: string;
}

/** Resolved auth for one connection. The API key is static — Cadmium documents no token endpoint. */
export interface EventscribeAuthContext extends RESTAuthContext {
    APIKey: string;
    /** Per-CONNECTION (tenant) event scope. NEVER a value baked into this class. */
    EventID?: string;
    IntegrationID: string;
}

/** Which object + verb the current async call chain belongs to. Drives multi-host URL resolution. */
interface EventscribeCallScope {
    IntegrationID: string;
    ObjectName: string;
    Verb: 'read' | 'create' | 'update' | 'delete' | 'get';
    /**
     * The DECLARED incremental-window query parameters for THIS read, already resolved from the
     * object's `Configuration.watermark` plus the engine-supplied watermark value. Absent = full pull.
     */
    WindowParams?: Record<string, string>;
}

/** A classified vendor failure, kept structured so the engine can route it. */
export interface EventscribeErrorClassification {
    Code: SyncErrorCode;
    Severity: ErrorSeverity;
    Retryable: boolean;
    Reason: string;
}

/** Typed transport failure carrying the vendor's own message and the classified verdict. */
export class EventscribeAPIError extends Error {
    public constructor(
        message: string,
        public readonly Status: number,
        public readonly Headers: Record<string, string>,
        public readonly Classification: EventscribeErrorClassification,
        public readonly VendorMessage?: string,
    ) {
        super(message);
        this.name = 'EventscribeAPIError';
    }
}

/** One per-record outcome read back out of a non-atomic array-body write. */
interface BatchItemOutcome {
    Success: boolean;
    ExternalID?: string;
    ErrorMessage?: string;
}

@RegisterClass(BaseIntegrationConnector, 'EventscribeConnector')
export class EventscribeConnector extends BaseRESTIntegrationConnector {

    /**
     * The object + verb the CURRENT async call chain is serving. The base class's `GetBaseURL`,
     * `ExtractPaginationInfo`, `BuildOperationBody` and `ExtractIDFromResponse` hooks are called
     * without an object argument, but every one of them is per-object on this vendor (five families,
     * three hosts, per-object pagination envelope, per-object array-body write convention). An
     * AsyncLocalStorage scope carries the identity correctly even when the engine pushes several
     * objects concurrently — a mutable `this.currentObject` field would silently cross the wires.
     */
    private readonly scope = new AsyncLocalStorage<EventscribeCallScope>();

    /** Resolved auth per CompanyIntegration.ID. The APIKey is static; there is nothing to refresh. */
    private readonly authCache = new Map<string, EventscribeAuthContext>();

    /** Earliest permitted send time per `host|MethodValue`, so the vendor's documented spacing is honoured. */
    private readonly nextAllowedAt = new Map<string, number>();

    /** Warnings already emitted, so a long sync logs honestly rather than noisily. */
    private readonly warnedOnce = new Set<string>();

    // ── Identity (T1 three-way invariant) ─────────────────────────────────────

    /** Verbatim `MJ: Integrations.Name`. Load-bearing: T1 compares this === the metadata Name. */
    public override get IntegrationName(): string {
        return 'eventscribe';
    }

    // ── Capability getters (kept in lockstep with the per-operation IO columns) ──

    /**
     * TRUE. `Configuration.WriteCapability` documents `addUpdateAccount` (eventscribe-web),
     * `addUpdateExhibitor` / `addUpdateBooth` / `addUpdateExhibitorStaff` (expo-harvester) and
     * `addUpdatePresenter` / `addUpdatePresentation` (education-harvester); those objects carry
     * populated `CreateAPIPath` + `CreateMethod` columns and ride the base class's generic create.
     */
    public override get SupportsCreate(): boolean { return true; }

    /** TRUE for the same `addUpdate*` upsert operations — they are create-OR-update in one call. */
    public override get SupportsUpdate(): boolean { return true; }

    /**
     * TRUE, but narrowly: only Account (`cancelAccount` / `deleteAccount`) and Presentation
     * (`deletePresentation`) declare a delete operation. `Configuration.WriteCapability` records
     * expo-harvester's `unassignBooth` as explicitly NOT a delete, and abstract-scorecard as 100%
     * read-only, so those objects leave `DeleteAPIPath` null and the generic delete refuses them.
     */
    public override get SupportsDelete(): boolean { return true; }

    /**
     * FALSE, permanently. `Configuration.DiscoveryIsAuthoritativeReason` (metadata): Cadmium documents
     * NO list/describe/schema endpoint anywhere in the corpus, so "absence from a sample response
     * proves nothing about what the vendor's schema actually supports". A thin runtime result must
     * never deactivate a persisted object or field — that would be tenant-visible data loss.
     */
    public override get DiscoveryIsAuthoritative(): boolean { return false; }

    // ── Sync-efficiency hooks (§7/§10) — each backed by a metadata fact ───────

    /**
     * Read STRAIGHT off `Configuration.RateLimits.standard` ("1 request per 1000 ms, most methods,
     * vendor-wide"). Returns null when the integration row carries no rate-limit facts — the engine
     * then paces itself rather than obeying a number this class invented. The per-METHOD overrides
     * (the two vendor-documented heavy methods at 1/60s) cannot be expressed in this connector-wide
     * policy, so they are enforced per request in {@link PaceRequest}.
     */
    public override get RateLimitPolicy(): RateLimitPolicy | null {
        const standard = this.IntegrationConfig()?.RateLimits?.standard;
        const perWindow = standard?.requestsPerWindow;
        const windowMs = standard?.windowMs;
        if (!Number.isFinite(perWindow) || !Number.isFinite(windowMs) || (windowMs as number) <= 0) return null;
        const tokensPerSec = ((perWindow as number) * 1000) / (windowMs as number);
        if (!Number.isFinite(tokensPerSec) || tokensPerSec <= 0) return null;
        return {
            TokensPerSec: tokensPerSec,
            Burst: Math.max(1, Math.floor(perWindow as number)),
            ThrottleBackoffFactor: 0.5,
            SuccessRampPerCall: tokensPerSec / 10,
            MinTokensPerSec: tokensPerSec / 20,
        };
    }

    /**
     * One in flight when the vendor's documented standard allowance is one request per window —
     * derived from the same `Configuration.RateLimits.standard` fact, not asserted here. Null when the
     * metadata carries no allowance, so the engine keeps its own default.
     */
    public override get MaxConcurrencyHint(): number | null {
        const perWindow = this.IntegrationConfig()?.RateLimits?.standard?.requestsPerWindow;
        return Number.isFinite(perWindow) && (perWindow as number) >= 1 ? Math.floor(perWindow as number) : null;
    }

    /**
     * Strictly whatever the object's own `StableOrderingKey` column declares. Never synthesised: an
     * invented resume cursor on a source with no server-side ordering guarantee silently skips rows.
     */
    public override StableOrderingKey(objectName: string): string | null {
        const integrationID = this.tryGetIntegrationID();
        if (!integrationID) return null;
        try {
            return this.GetCachedObject(integrationID, objectName).StableOrderingKey ?? null;
        } catch {
            return null;
        }
    }

    /**
     * TRUE. The `addUpdate*` operations are REAL batch endpoints: `Configuration.BatchSemantics`
     * documents "JSON array in the raw POST body (single-object writes still require wrapping in a
     * one-element array)" with per-record, NON-ATOMIC processing. See {@link BatchCreateRecords}.
     */
    public override get SupportsBatchWrite(): boolean { return true; }

    // ── Discovery ─────────────────────────────────────────────────────────────
    //
    // STATIC-CATALOG: Cadmium documents NO list/describe/schema/introspection endpoint anywhere in the
    // corpus (`Configuration.DiscoveryIsAuthoritativeReason`, 11 PDFs + 1 XLSX, zero OpenAPI/Swagger/
    // Postman/GraphQL/SDK artifacts) and publishes no credential-free schema-of-record, so there is no
    // runtime enumeration to call and no public schema to parse — the object/field universe is knowable
    // only from the Declared metadata rows.
    //
    // `DiscoverObjects` and `DiscoverFields` are therefore DELIBERATELY NOT overridden: the Declared
    // IntegrationObject / IntegrationObjectField rows ARE the schema of record, and the base
    // implementations read exactly those rows back through `IntegrationEngineBase` — CREDENTIAL-FREE,
    // which is what keeps the runtime structure self-check green without a token. Writing the object
    // list into this file — even as a `.map()` over a local array — would freeze the catalog AND make
    // the next build read its own output back as a source. A live credential is purely ADDITIVE here:
    // it only adds tenant-specific columns, via the sample-union in `IntrospectSchema` below.

    /**
     * Declared ∪ live-sampled, so a tenant's own columns reach the schema builder. Cadmium's field
     * sets are demonstrably per-tenant (`AccountCustomField1..10`, `AuthorCustomFieldN`,
     * `SubmitterCustomFieldN`, `ReviewAnswerN` are all templated in the vendor docs), and with no
     * describe endpoint the ONLY way to learn which of them a given event actually populates is to
     * read real records. The union is delegated to the shared never-shrink helper; this connector
     * supplies no merge logic of its own, and a sampling failure leaves the DECLARED floor intact.
     */
    public override async IntrospectSchema(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<SourceSchemaInfo> {
        const info = await super.IntrospectSchema(companyIntegration, contextUser);
        await Promise.all(info.Objects.map(async (obj) => {
            try {
                const sampled = await this.DiscoverFieldsViaFetch(companyIntegration, obj.ExternalName, contextUser);
                obj.Fields = mergeDeclaredWithSampledFields(obj.Fields, sampled);
            } catch (err) {
                this.WarnOnce(
                    `introspect:${obj.ExternalName}`,
                    `[eventscribe] Live field sampling for "${obj.ExternalName}" failed (${this.SafeMessage(err)}); ` +
                    'the DECLARED field floor still stands. Nothing was removed — Cadmium publishes no describe ' +
                    'endpoint, so absence proves nothing.',
                );
            }
        }));
        return info;
    }

    // ── Connection test ───────────────────────────────────────────────────────

    /**
     * Runs the cheapest real read this connection can make: the first ACTIVE, directly-queryable
     * object's own door. Objects whose only door needs a caller-supplied record key
     * (`Configuration.requiresRecordKeyToRead`) are skipped — calling them unkeyed proves nothing.
     * The message never carries credential bytes.
     */
    public override async TestConnection(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<ConnectionTestResult> {
        try {
            const objects = this.getCachedObjects(companyIntegration.IntegrationID);
            if (objects.length === 0) {
                return {
                    Success: false,
                    Message:
                        '[eventscribe] No ACTIVE IntegrationObjects are seeded for this integration, so there is ' +
                        'no door to probe. Push metadata/integrations/eventscribe before testing the connection.',
                };
            }
            const probe = objects.find((o) => {
                const cfg = this.ObjectConfig(o);
                return this.DepthOf(cfg) === 0 && cfg?.requiresRecordKeyToRead == null && this.DoorOperationFor(o, cfg) != null;
            });
            if (!probe) {
                return {
                    Success: false,
                    Message:
                        '[eventscribe] Every ACTIVE object either has no read door or declares ' +
                        'requiresRecordKeyToRead, so no credential-only probe exists. Enable an enumerable object ' +
                        '(for example one of the abstract-scorecard get* doors) before testing.',
                };
            }
            const auth = await this.Authenticate(companyIntegration, contextUser);
            const url = this.DoorURL(
                companyIntegration,
                auth,
                probe,
                this.DoorOperationFor(probe, this.ObjectConfig(probe))!,
            );
            const response = await this.MakeHTTPRequest(auth, url, 'GET', this.BuildHeaders(auth));
            if (response.Status >= 200 && response.Status < 300) {
                return {
                    Success: true,
                    Message: `[eventscribe] Reachable: door "${probe.Name}" answered HTTP ${response.Status} for this API key.`,
                };
            }
            return {
                Success: false,
                Message:
                    `[eventscribe] Door "${probe.Name}" answered HTTP ${response.Status}` +
                    `${this.VendorMessage(response.Body) ? `: ${this.VendorMessage(response.Body)}` : ''}. ` +
                    'Check the API key and, for a multi-event key, the event id (eID) on this connection.',
            };
        } catch (err) {
            return { Success: false, Message: `[eventscribe] Connection test failed: ${this.SafeMessage(err)}` };
        }
    }

    // ── The READ path ─────────────────────────────────────────────────────────

    /**
     * OVERRIDDEN for two evidenced reasons, and it delegates back to the base for everything else.
     *
     *   (a) MULTI-HOST. The object's identity has to be in scope before `GetBaseURL` runs, because the
     *       base's signature has no object slot and this vendor has three hosts.
     *   (b) NESTED ACCESS PATHS. A large minority of the declared objects carry `accessPath.depth >= 1`
     *       with the note "This object has no read operation of its own; its records arrive nested
     *       inside the door operation's response under the '<key>' key." A flat per-object query
     *       returns ZERO rows for every one of them, so those walk the declared path instead.
     *
     * A depth-0 object goes straight back to `super.FetchChanges` — the base's pagination loop,
     * batch limiting and record assembly are used AS IS. Two metadata-declared refusals run FIRST
     * ({@link WireFormatGate}, {@link RecordKeyGate}) so an object this connector cannot honestly read
     * reports a structured warning instead of a silent, green, zero-row batch.
     */
    public override async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
        const companyIntegration = ctx.CompanyIntegration;
        const obj = this.GetCachedObject(companyIntegration.IntegrationID, ctx.ObjectName);
        const cfg = this.ObjectConfig(obj);

        const wireGate = this.WireFormatGate(obj, cfg);
        if (wireGate) return { Records: [], HasMore: false, Warnings: [wireGate] };

        const gate = this.RecordKeyGate(companyIntegration, obj, cfg);
        if (gate) return { Records: [], HasMore: false, Warnings: [gate] };

        const callScope: EventscribeCallScope = {
            IntegrationID: companyIntegration.IntegrationID,
            ObjectName: ctx.ObjectName,
            Verb: 'read',
            WindowParams: this.WindowParamsFor(obj, cfg, ctx),
        };
        const batch = this.DepthOf(cfg) === 0
            ? await this.scope.run(callScope, () => super.FetchChanges(ctx))
            : await this.scope.run(callScope, () => this.FetchNestedViaDoor(ctx, obj, cfg));
        // Reached ONLY on a batch that completed without throwing — a mid-iteration failure propagates
        // out of the awaits above, so the watermark is never advanced over a partial read.
        return this.WithMaxSeenWatermark(batch, obj, ctx);
    }

    /**
     * Refuses an object whose metadata declares a wire format this connector does not parse.
     * `Configuration.responseFormat` is a per-object FACT: the five in-scope families are all `json`,
     * while the EdgeReg family ships `xml` (and its own `responseFormatNote`: "The connector must parse
     * XML for this object") together with a DIFFERENT credential model. Those objects are seeded
     * `Status = 'Disabled'` so they normally never reach a sync at all; this gate is what happens if an
     * operator activates one anyway. Without it the XML body fails to parse as JSON, `NormalizeResponse`
     * yields `[]`, and the run reports zero rows and GREEN — the silent-empty this framework exists to
     * prevent. The refusal names the declared format and the credential model so the fix is obvious.
     */
    private WireFormatGate(obj: MJIntegrationObjectEntity, cfg: EventscribeObjectConfig | null): FetchWarning | null {
        const declared = cfg?.responseFormat;
        if (!declared || declared.trim().toLowerCase() === 'json') return null;
        const credentialModel = cfg?.outOfScope?.credentialModel;
        return {
            Code: 'UNSUPPORTED_WIRE_FORMAT',
            Message:
                `"${obj.Name}" declares Configuration.responseFormat = "${declared}", which this connector does ` +
                'not parse — it speaks the JSON families only. Refusing to fire the request rather than return ' +
                'an empty batch that would read as "this event has no records". ' +
                (credentialModel
                    ? `This object also declares a different credential model (${credentialModel}), so the ` +
                      'connection\'s Eventscribe APIKey would not authenticate it either. '
                    : '') +
                'Leave the object Disabled until a build adds the parser and the credential.',
            Data: {
                object: obj.Name,
                responseFormat: declared,
                family: cfg?.family ?? null,
                credentialModel: credentialModel ?? null,
            },
        };
    }

    /**
     * The DECLARED incremental window for one read, or undefined for a full pull. Everything is
     * metadata: the parameter name comes from the object's own `Configuration.watermark.startParam`,
     * and the VALUE is the watermark the engine handed back — which this connector originally took
     * from the record's OWN `IncrementalWatermarkField` (see {@link WithMaxSeenWatermark}), so it is
     * already in the vendor's own serialization and no format is invented on the wire.
     *
     * `endParam` is deliberately NOT sent even where declared: an upper bound would silently drop any
     * record the vendor writes between the request being built and being served. No `startParam` in
     * metadata ⇒ no window — this vendor's per-object `watermarkProvenNegative` records that the five
     * in-scope families document no server-side modified-since filter at all, and an invented one
     * either returns nothing or is ignored.
     */
    private WindowParamsFor(
        obj: MJIntegrationObjectEntity,
        cfg: EventscribeObjectConfig | null,
        ctx: FetchContext,
    ): Record<string, string> | undefined {
        if (!obj.SupportsIncrementalSync) return undefined;
        const startParam = cfg?.watermark?.startParam;
        if (!startParam) return undefined;
        const since = ctx.WatermarkValue;
        if (since == null || String(since).trim().length === 0) return undefined;
        return { [startParam]: String(since).trim() };
    }

    /**
     * Advances the watermark to the MAX value SEEN in this batch, and only for an object whose metadata
     * declares one (`SupportsIncrementalSync` + `IncrementalWatermarkField`). Never advances past a
     * value already recorded, and never invents a watermark for a full-pull object — the five in-scope
     * families are all `FullPullHashDiff`, where the engine's content-hash idempotency does the work.
     */
    private WithMaxSeenWatermark(
        batch: FetchBatchResult,
        obj: MJIntegrationObjectEntity,
        ctx: FetchContext,
    ): FetchBatchResult {
        const field = obj.SupportsIncrementalSync ? obj.IncrementalWatermarkField : null;
        if (!field) return batch;

        let max: string | null = null;
        for (const record of batch.Records) {
            const raw = record.Fields[field];
            if (raw == null) continue;
            const value = String(raw).trim();
            if (value.length === 0) continue;
            if (max == null || this.CompareWatermark(value, max) > 0) max = value;
        }
        if (max == null) return batch;
        if (ctx.WatermarkValue != null && this.CompareWatermark(max, ctx.WatermarkValue) <= 0) return batch;
        return { ...batch, NewWatermarkValue: max };
    }

    /** Chronological when BOTH values parse as dates, lexicographic otherwise. Never coerces one side. */
    private CompareWatermark(a: string, b: string): number {
        const ta = Date.parse(a);
        const tb = Date.parse(b);
        if (Number.isFinite(ta) && Number.isFinite(tb)) return ta === tb ? 0 : (ta < tb ? -1 : 1);
        return a === b ? 0 : (a < b ? -1 : 1);
    }

    /**
     * Walks a declared nesting path: fire the DOOR operation, then descend into the declared container
     * key on each door record and emit the leaf rows. Everything that varies — the door's Method value,
     * the container key, the parent key field to tag the leaf with — comes from the object's own
     * `Configuration.accessPath` / `nestedContainerKey` / `parentObjectIDFieldName`; nothing is guessed.
     *
     * Returns ONE batch with `HasMore: false`. Every depth>=1 object declares
     * `SupportsPagination = false`, so the door is a single unpaged call: splitting the leaves across
     * batches would force a full re-read of the door per batch for no benefit.
     */
    private async FetchNestedViaDoor(
        ctx: FetchContext,
        obj: MJIntegrationObjectEntity,
        cfg: EventscribeObjectConfig | null,
    ): Promise<FetchBatchResult> {
        const companyIntegration = ctx.CompanyIntegration;
        const doorOperation = this.DoorOperationFor(obj, cfg);
        if (!doorOperation) {
            throw new Error(
                `[eventscribe] "${obj.Name}" is a nested object (accessPath.depth ` +
                `${this.DepthOf(cfg)}) but declares no accessPath.doorOperation, dispatch.methodValue or ` +
                'DefaultQueryParams Method. There is no operation to call — refusing to invent one.',
            );
        }
        const containerKey = this.NestedContainerKeyFor(cfg);
        if (!containerKey) {
            throw new Error(
                `[eventscribe] "${obj.Name}" is nested under door "${doorOperation}" but declares no ` +
                'Configuration.nestedContainerKey and no accessPath.nestingFieldPath to derive it from. ' +
                'Refusing to guess which response key carries its records.',
            );
        }
        const parentIDField = cfg?.parentObjectIDFieldName ?? null;
        const doorObjectName = cfg?.accessPath?.doorObject ?? cfg?.parentObjectName ?? null;
        const doorObject = doorObjectName
            ? this.TryGetCachedObject(companyIntegration.IntegrationID, doorObjectName)
            : null;

        const auth = await this.Authenticate(companyIntegration, ctx.ContextUser);
        const url = this.DoorURL(companyIntegration, auth, obj, doorOperation);
        const response = await this.MakeHTTPRequest(auth, url, 'GET', this.BuildHeaders(auth));
        if (response.Status < 200 || response.Status >= 300) {
            throw this.ErrorFor(response, url);
        }

        const doorRows = this.NormalizeResponse(response.Body, obj.ResponseDataKey ?? doorObject?.ResponseDataKey ?? null);
        const fields = this.GetCachedFields(obj.ID);
        const pkNames = this.PrimaryKeyNames(fields);
        const records: ExternalRecord[] = [];

        for (const doorRow of doorRows) {
            const container = doorRow[containerKey];
            if (container == null) continue;
            const items = Array.isArray(container) ? container : [container];
            const parentID = parentIDField != null ? doorRow[parentIDField] : undefined;
            for (const item of items) {
                const leaf = this.AsObject(item);
                if (!leaf) continue;
                // FULL-RECORD PASS-THROUGH: the complete nested row, plus the parent key the vendor's
                // nested payload omits. A value the source itself supplied is never overwritten.
                const raw: Record<string, unknown> = { ...leaf };
                if (parentIDField && parentID != null && !(parentIDField in raw)) raw[parentIDField] = parentID;
                records.push(this.ToEventscribeRecord(
                    this.applyTransformPreservingKeys(raw, obj, fields),
                    ctx.ObjectName,
                    pkNames,
                    obj,
                ));
            }
        }

        const warnings: FetchWarning[] = [];
        if (records.length === 0) {
            warnings.push({
                Code: 'EMPTY_NESTED_CONTAINER',
                Message:
                    `"${obj.Name}": door "${doorOperation}" returned ${doorRows.length} record(s) but none carried a ` +
                    `"${containerKey}" container, so no nested rows were emitted. Either this event has none, or the ` +
                    'declared container key no longer matches the vendor payload.',
                Data: { object: obj.Name, door: doorOperation, containerKey, doorRows: doorRows.length },
            });
        }
        return { Records: records, HasMore: false, Warnings: warnings.length > 0 ? warnings : undefined };
    }

    /**
     * The honest refusal for an object whose ONLY read door needs a caller-supplied record key.
     * `Configuration.requiresRecordKeyToRead` states it verbatim: "A full sync cannot enumerate this
     * object unaided". The vendor documents no parameter name for that key on the read side, so this
     * returns an empty batch with a loud, structured warning rather than firing a call that is
     * guaranteed to fail — or, worse, inventing a query parameter.
     */
    private RecordKeyGate(
        companyIntegration: MJCompanyIntegrationEntity,
        obj: MJIntegrationObjectEntity,
        cfg: EventscribeObjectConfig | null,
    ): FetchWarning | null {
        const own = cfg?.requiresRecordKeyToRead;
        if (own) {
            return {
                Code: 'REQUIRES_RECORD_KEY',
                Message: `"${obj.Name}": ${own}`,
                Data: { object: obj.Name, door: this.DoorOperationFor(obj, cfg) },
            };
        }
        if (this.DepthOf(cfg) === 0) return null;
        const doorObjectName = cfg?.accessPath?.doorObject ?? cfg?.parentObjectName;
        if (!doorObjectName) return null;
        const doorObject = this.TryGetCachedObject(companyIntegration.IntegrationID, doorObjectName);
        const doorGate = doorObject ? this.ObjectConfig(doorObject)?.requiresRecordKeyToRead : undefined;
        if (!doorGate) return null;
        return {
            Code: 'REQUIRES_RECORD_KEY',
            Message:
                `"${obj.Name}" is nested under door object "${doorObjectName}", whose only read operation needs a ` +
                `caller-supplied record key: ${doorGate}`,
            Data: { object: obj.Name, doorObject: doorObjectName },
        };
    }

    // ── REST transport primitives ─────────────────────────────────────────────

    /**
     * Resolves the per-connection credential. Cadmium's APIKey is a single static per-client string
     * with no authorize/token endpoint, no scopes and no documented expiry, so there is nothing to
     * refresh and the resolved context is cached per CompanyIntegration. `eID` is the per-CONNECTION
     * (TENANT) event scope — `Configuration.AuthMultiTenantParam` is explicit that it is "never baked
     * into connector code" — and is optional, used only when the key is provisioned for multi-event
     * access. The credential is read through the standard `MJ: Credentials` record when the connection
     * carries one, with the connection's own `Configuration` JSON as the fallback. No inline crypto.
     */
    protected override async Authenticate(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<EventscribeAuthContext> {
        const cached = this.authCache.get(companyIntegration.ID);
        if (cached) return cached;

        const creds = await this.LoadCredentials(companyIntegration, contextUser);
        const apiKey = (creds.APIKey ?? '').trim();
        if (!apiKey) {
            throw new Error(
                '[eventscribe] No API key configured. Cadmium carries its credential as a QUERY PARAMETER on ' +
                'every request (Configuration.AuthCredentialTransport = "query-param"), so no call can be made ' +
                'without it. Supply "APIKey" on the connection credential or its Configuration JSON.',
            );
        }
        const eventID = (creds.EventID ?? '').trim();
        const ctx: EventscribeAuthContext = {
            APIKey: apiKey,
            IntegrationID: companyIntegration.IntegrationID,
        };
        if (eventID.length > 0) ctx.EventID = eventID;
        this.authCache.set(companyIntegration.ID, ctx);
        return ctx;
    }

    /**
     * Transport headers ONLY — deliberately NOTHING auth-related. `Configuration.AuthHeaderPattern` is
     * null and `AuthCredentialParamLocation` is 'query': the API key travels in the query string, and a
     * Bearer/Basic header on this vendor is simply wrong. The credential is injected in
     * {@link SendRequest}, which is the one place it ever touches the wire.
     */
    protected override BuildHeaders(_auth: RESTAuthContext): Record<string, string> {
        return { 'Accept': 'application/json', 'Content-Type': 'application/json' };
    }

    /**
     * The wire choke point used by every read and every single-record write. On top of
     * {@link SendRequest} (credential injection, vendor pacing, the documented 404+`[]` empty case) it
     * adds ONE rule: a 2xx response whose body carries the vendor's `{"error": ...}` envelope is a
     * FAILURE, not an empty read. `Configuration.ErrorContract` documents that envelope as applying
     * "across API methods"; a body-blind success check would sync zero rows and report green.
     *
     * On a READ it adds the SAME status gate the connector's other two read call sites already apply
     * ({@link FetchNestedViaDoor}, {@link GetRecord}): a non-2xx never reaches record assembly, and it
     * surfaces as the connector's own classified {@link EventscribeAPIError} rather than an unclassified
     * failure — a 5xx must reach the engine as `Retryable: true`, a 401/403 as a non-retryable
     * configuration error. The flat/paginated read the base class drives was the one transport path
     * with no such gate, so its errors carried no `Code`/`Severity`/`Retryable` verdict at all.
     *
     * OUTSIDE a read, NON-2xx responses are returned, not thrown, so the base class's generic CRUD can
     * build a proper `CRUDResult`, `GetRecord` keeps its documented 404 ⇒ null, and `TestConnection`
     * can report the status it observed. The batch path calls {@link SendRequest} directly because for
     * `addUpdateAccount` an HTTP 400 can accompany partially-succeeded records and must be INSPECTED
     * rather than treated as total failure.
     */
    protected override async MakeHTTPRequest(
        auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown,
    ): Promise<RESTResponse> {
        const response = await this.SendRequest(auth, url, method, headers, body);
        if (response.Status >= 200 && response.Status < 300 && this.VendorMessage(response.Body) != null) {
            throw this.ErrorFor(response, url);
        }
        // The read gate. Scoped to the read verb via the SAME per-call scope every other per-object
        // decision in this class rides, because the base class's pagination loop is private and cannot
        // be overridden — this is the only seam a flat read passes through. The documented 404+`[]`
        // empty case is already normalised to a 200 in {@link SendRequest}, so it stays a success.
        if (this.scope.getStore()?.Verb === 'read' && (response.Status < 200 || response.Status >= 300)) {
            throw this.ErrorFor(response, url);
        }
        return response;
    }

    /**
     * Credential injection + vendor pacing + the documented empty-result special case. Returns the
     * response verbatim for every status; classification is the caller's decision.
     *
     * `Configuration.ErrorContract.specialCases` is explicit for the asset family: HTTP 404 with a body
     * of `[]` means "no presentations or posters were found" — an EMPTY RESULT, never a connector
     * failure. It is normalised to a 200 here so both the base read path (which validates on status)
     * and this connector's own paths see an empty success.
     */
    protected async SendRequest(
        auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown,
    ): Promise<RESTResponse> {
        const ctx = auth as EventscribeAuthContext;
        const requestURL = this.WithCredentialParams(ctx, this.WithWindowParams(url));
        await this.PaceRequest(requestURL);
        const response = await this.rawRequest(requestURL, method, headers, body);
        if (response.Status === 404 && Array.isArray(response.Body) && response.Body.length === 0) {
            return { Status: 200, Body: [], Headers: response.Headers };
        }
        return response;
    }

    /** Raw transport. Isolated so tests can substitute it without touching any connector behaviour. */
    protected async rawRequest(
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown,
    ): Promise<RESTResponse> {
        const response = await fetch(url, {
            method,
            headers,
            body: body !== undefined ? JSON.stringify(body) : undefined,
            redirect: 'manual',
        });
        const respHeaders: Record<string, string> = {};
        response.headers.forEach((v, k) => { respHeaders[k.toLowerCase()] = v; });
        const text = await response.text();
        let parsed: unknown = null;
        if (text.length > 0) {
            try { parsed = JSON.parse(text); } catch { parsed = text; }
        }
        return { Status: response.status, Body: parsed, Headers: respHeaders };
    }

    /**
     * Strips the vendor envelope. A BARE JSON ARRAY is the common shape across this vendor (Asset,
     * Expo, Education Harvester); `ResponseDataKey` is applied ONLY where the object's metadata
     * declares one (the abstract-scorecard family's `{ metadata: {...}, results: [...] }`). A single
     * record object is a one-element result — several doors (`getAccount`, `getSingle*`) answer with
     * one object, not an array — but an error envelope is never mistaken for a record.
     */
    protected override NormalizeResponse(rawBody: unknown, responseDataKey: string | null): Record<string, unknown>[] {
        const target = responseDataKey ? this.ReadPath(rawBody, responseDataKey.split('.')) : rawBody;
        if (Array.isArray(target)) {
            return target.filter((r): r is Record<string, unknown> => this.AsObject(r) != null);
        }
        const single = this.AsObject(target);
        if (!single) return [];
        if (this.VendorMessage(single) != null) return [];
        return [single];
    }

    /**
     * PageNumber only, and only from the object's OWN declared envelope
     * (`Configuration.pagination.envelope` = `{ container: 'metadata', totalRecordsKey: 'totalRecords',
     * totalPagesKey: 'pages', currentPageKey: 'page' }`). An object whose metadata declares
     * `SupportsPagination = false` never reaches here — the base short-circuits it — and when the
     * envelope is not declared this returns `HasMore: false` rather than inventing a counter name.
     * Inventing one either truncates the sync or loops it forever.
     */
    protected override ExtractPaginationInfo(
        rawBody: unknown,
        paginationType: PaginationType,
        currentPage: number,
        _currentOffset: number,
        pageSize: number,
        obj?: MJIntegrationObjectEntity,
    ): PaginationState {
        if (paginationType !== 'PageNumber') return { HasMore: false };
        const target = obj ?? this.ScopedObject();
        const envelope = target ? this.ObjectConfig(target)?.pagination?.envelope : undefined;
        if (!envelope) return { HasMore: false };

        const container = envelope.container ? this.AsObject(this.ReadPath(rawBody, envelope.container.split('.'))) : this.AsObject(rawBody);
        if (!container) return { HasMore: false };

        const page = this.FiniteNumber(envelope.currentPageKey ? container[envelope.currentPageKey] : undefined) ?? currentPage;
        const totalPages = this.FiniteNumber(envelope.totalPagesKey ? container[envelope.totalPagesKey] : undefined);
        const totalRecords = this.FiniteNumber(envelope.totalRecordsKey ? container[envelope.totalRecordsKey] : undefined);

        if (totalPages != null) {
            const hasMore = page < totalPages;
            return { HasMore: hasMore, NextPage: hasMore ? page + 1 : undefined, TotalRecords: totalRecords ?? undefined };
        }
        if (totalRecords != null && pageSize > 0) {
            const hasMore = page * pageSize < totalRecords;
            return { HasMore: hasMore, NextPage: hasMore ? page + 1 : undefined, TotalRecords: totalRecords };
        }
        return { HasMore: false };
    }

    /**
     * Emits ONLY the page parameter the object's metadata proves
     * (`Configuration.pagination.paramName`). The base class's default would append `page=` AND
     * `pageSize=`; Cadmium's vendor table documents the page-number parameter and NO page-size
     * parameter at all, so sending one would be an invented name on the wire.
     */
    protected override BuildPaginatedURL(
        basePath: string,
        obj: MJIntegrationObjectEntity,
        page: number,
        _offset: number,
        _cursor?: string,
        _effectivePageSize?: number,
    ): string {
        if (obj.PaginationType !== 'PageNumber') return basePath;
        const paramName = this.ObjectConfig(obj)?.pagination?.paramName;
        if (!paramName) return basePath;
        const separator = basePath.includes('?') ? '&' : '?';
        return `${basePath}${separator}${encodeURIComponent(paramName)}=${page}`;
    }

    /**
     * PER-OBJECT, multi-host. Resolution order, all of it metadata:
     *   1. the object's own `Configuration.baseUrl`, when a build ever declares one;
     *   2. `Integration.Configuration.BaseURLsByFamily` keyed by the object's `Configuration.family`
     *      (falling back to `IntegrationObject.Category`, which carries the same family tag);
     *   3. the object's `Configuration.absoluteEndpoint` with its own declared `APIPath` suffix
     *      removed — the last resort that still rescues a family with no table entry.
     *
     * 'asset' and 'eventscribe-web' both key this table and both must stay: they resolve to the same
     * host TODAY, which is data, not a licence to collapse the tags in code. There is no default and
     * no baked host — a family with no resolvable base URL raises, it does not silently pick one.
     */
    protected override GetBaseURL(
        companyIntegration: MJCompanyIntegrationEntity,
        _auth: RESTAuthContext,
        objectName?: string,
    ): string {
        const name = objectName ?? this.scope.getStore()?.ObjectName;
        if (!name) {
            throw new Error(
                '[eventscribe] GetBaseURL was called with no object in scope. This vendor has five object ' +
                'families across three hosts, so a base URL cannot be resolved without knowing which object the ' +
                'request is for.',
            );
        }
        // A single-origin override is a PER-CONNECTION fact — this connection points at a sandbox,
        // a proxy, or a mock standing in for all three Cadmium hosts, while another connection on the
        // same Integration still talks to production. So CompanyIntegration.Configuration is checked
        // FIRST and the Integration-level value is only the fallback. (Reading solely the Integration
        // row is why an earlier attempt at this override never fired: harnesses patch the CONNECTION.)
        const perConnection = this.SingleOriginOverride(companyIntegration.Configuration);
        if (perConnection) return this.TrimTrailingSlash(perConnection);

        return this.BaseURLForObject(this.GetCachedObject(companyIntegration.IntegrationID, name));
    }

    /** `BaseURL` off a connection's Configuration JSON, when present and non-empty. */
    private SingleOriginOverride(configurationJSON: string | null | undefined): string | null {
        const parsed = this.ParseJSONObject(configurationJSON ?? null);
        const raw = parsed && typeof parsed === 'object' ? (parsed as Record<string, unknown>).BaseURL : null;
        return typeof raw === 'string' && raw.trim().length > 0 ? raw.trim() : null;
    }

    /** The per-object base URL resolution described on {@link GetBaseURL}. */
    private BaseURLForObject(obj: MJIntegrationObjectEntity): string {
        // Single-origin override wins over EVERYTHING, including a per-object baseUrl. When one host
        // is standing in for all five Cadmium hosts — a mock server, a sandbox, a proxy — it must
        // capture every request, or the objects carrying their own absolute baseUrl silently escape
        // to the real internet while the rest are redirected. That split is exactly how a mock-mode
        // run lands 0 rows and still looks like it ran.
        const override = this.IntegrationConfig()?.BaseURL;
        if (override) return this.TrimTrailingSlash(override);

        const cfg = this.ObjectConfig(obj);
        if (cfg?.baseUrl) return this.TrimTrailingSlash(cfg.baseUrl);

        const family = cfg?.family ?? obj.Category ?? null;
        const table = this.IntegrationConfig()?.BaseURLsByFamily;
        if (family && table) {
            const hit = table.find(e => e.family === family);
            if (hit?.baseUrl) return this.TrimTrailingSlash(hit.baseUrl);
        }
        const absolute = cfg?.absoluteEndpoint;
        if (absolute) {
            const path = obj.APIPath.startsWith('/') ? obj.APIPath : `/${obj.APIPath}`;
            if (absolute.endsWith(path)) return this.TrimTrailingSlash(absolute.slice(0, absolute.length - path.length));
        }
        throw new Error(
            `[eventscribe] No base URL resolves for object "${obj.Name}" (family "${family ?? 'unset'}"). ` +
            'Declare it on the object\'s Configuration.baseUrl/absoluteEndpoint, or add the family to ' +
            'Integration.Configuration.BaseURLsByFamily. This connector never falls back to a baked host.',
        );
    }

    // ── Write surface ─────────────────────────────────────────────────────────
    //
    // CreateRecord / UpdateRecord / DeleteRecord below are NOT re-implementations. Each is a THIN
    // wrapper whose only job is to establish the per-call object scope that the multi-host
    // `GetBaseURL` (and the per-object array-body decision) needs; the body of the operation is the
    // base class's generic per-operation dispatch, reading CreateAPIPath/CreateMethod/CreateBodyShape/
    // CreateBodyKey/CreateIDLocation, Update*, Delete* straight off the IntegrationObject row.
    // `GetRecord` is the ONE read the generic path cannot express here — see its own note.

    /** Scope-only wrapper; the create itself is the base class's metadata-driven generic dispatch. */
    public override async CreateRecord(ctx: CreateRecordContext): Promise<CRUDResult> {
        return this.scope.run(this.ScopeFor(ctx.CompanyIntegration, ctx.ObjectName, 'create'), () => super.CreateRecord(ctx));
    }

    /** Scope-only wrapper; the update itself is the base class's metadata-driven generic dispatch. */
    public override async UpdateRecord(ctx: UpdateRecordContext): Promise<CRUDResult> {
        return this.scope.run(this.ScopeFor(ctx.CompanyIntegration, ctx.ObjectName, 'update'), () => super.UpdateRecord(ctx));
    }

    /**
     * Scope-only wrapper around the base class's metadata-driven generic dispatch, PLUS one refusal:
     * a delete whose declared request carries NO record identifier never goes on the wire. See
     * {@link UnidentifiedDeleteGuard} — this is a safety gate, not a re-implementation.
     */
    public override async DeleteRecord(ctx: DeleteRecordContext): Promise<CRUDResult> {
        const refusal = this.UnidentifiedDeleteGuard(ctx);
        if (refusal) return refusal;
        return this.scope.run(this.ScopeFor(ctx.CompanyIntegration, ctx.ObjectName, 'delete'), () => super.DeleteRecord(ctx));
    }

    /**
     * Refuses a DESTRUCTIVE request that cannot name the record it is destroying.
     *
     * The base's generic delete substitutes the external id into the path ONLY when
     * `DeleteIDLocation = 'path'` and the path carries an `{ID}` placeholder, and it sends NO body at
     * all. Some of this vendor's delete-adjacent operations declare `DeleteIDLocation = 'n/a'` with
     * `deleteOperation.idParam = null` because — per the frozen contract's own gap list — "the op
     * documents no ID parameter at all in its parameters array". Firing that path verbatim would put
     * an UNIDENTIFIED delete on a live event with nothing but the API key, the event scope and the
     * Method name. Best case it 400s; worst case the vendor interprets it broadly. Neither is a risk
     * worth taking to make a capability flag look satisfied.
     *
     * So this returns a FAILED CRUDResult naming the exact missing fact, rather than either (a) firing
     * blind or (b) inventing a query-parameter name the vendor never documented — which would be the
     * connector silently working around a metadata gap. Objects whose delete DOES carry an identifier
     * (`...&AccountID={ID}` with `DeleteIDLocation = 'path'`) are untouched and ride the generic path.
     */
    private UnidentifiedDeleteGuard(ctx: DeleteRecordContext): CRUDResult | null {
        let obj: MJIntegrationObjectEntity;
        try {
            obj = this.GetCachedObject((ctx.CompanyIntegration as MJCompanyIntegrationEntity).IntegrationID, ctx.ObjectName);
        } catch {
            return null; // no metadata to judge by — let the base report the real configuration error
        }
        const path = obj.DeleteAPIPath;
        if (!path) return null; // the base already refuses an unconfigured delete, with its own message

        const substitutes = obj.DeleteIDLocation === 'path' && /\{(ID|id|ExternalID)\}/.test(path);
        if (substitutes) return null;

        const cfg = this.ObjectConfig(obj);
        const idParam = cfg?.deleteOperation?.idParam;
        if (idParam) return null; // an identifier IS declared; the request can name its target

        return {
            Success: false,
            // 0 = no request was made. There is no HTTP status to report because nothing was sent —
            // reporting a real code here would misrepresent a refusal as a vendor rejection.
            StatusCode: 0,
            ErrorMessage:
                `[eventscribe] Refusing to delete "${ctx.ObjectName}" (${ctx.ExternalID}): its declared delete ` +
                `operation carries no record identifier — DeleteIDLocation is "${obj.DeleteIDLocation ?? 'unset'}", ` +
                'the declared path has no {ID} placeholder, and Configuration.deleteOperation.idParam is null ' +
                '(the vendor documents no ID parameter for this operation). Sending it would be an UNIDENTIFIED ' +
                'destructive request. Fix the IntegrationObject Delete* columns upstream — this connector will ' +
                'not invent a parameter name for a destructive call.',
        };
    }

    /**
     * THE SECOND GENUINELY IDIOSYNCRATIC PATH. This is the one read the base class cannot express on an
     * RPC-over-querystring API: its generic `GetRecord` reuses `UpdateAPIPath` as the get-one path
     * ("typically the same as the get-one path" — true of resource-oriented REST, where `/accounts/{id}`
     * is both). Here `UpdateAPIPath` is `...?Method=addUpdateAccount&AccountID={ID}`, so the generic path
     * would send a GET whose `Method` names a WRITE operation. `Configuration.ReadContract` is explicit
     * that "the Method query param IS the routing/dispatch mechanism" — the verb does not disambiguate
     * it — so that request is an upsert dispatched with no body, aimed at a live event. Refusing to build
     * it is the same judgement as {@link UnidentifiedDeleteGuard}.
     *
     * Instead the read goes through the object's DECLARED READ DOOR ({@link DoorOperationFor}) with the
     * record key on the query string under its DECLARED parameter name ({@link RecordKeyParamFor}).
     * Everything is metadata; nothing is inferred from the verb or invented from a naming convention.
     * A throw here is safe and preferred over a wrong request: the engine's only caller treats a failed
     * re-read as "proceed with the full attribute set", so a refusal degrades to prior behaviour.
     */
    public override async GetRecord(ctx: GetRecordContext): Promise<ExternalRecord | null> {
        const companyIntegration = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const contextUser = ctx.ContextUser as UserInfo;
        const obj = this.GetCachedObject(companyIntegration.IntegrationID, ctx.ObjectName);
        const cfg = this.ObjectConfig(obj);

        const wireGate = this.WireFormatGate(obj, cfg);
        if (wireGate) throw new Error(wireGate.Message);

        if (this.DepthOf(cfg) !== 0) {
            throw new Error(
                `[eventscribe] "${ctx.ObjectName}" has no read door of its own — its metadata declares ` +
                `accessPath.depth ${this.DepthOf(cfg)}, i.e. its records arrive nested inside another ` +
                "object's response. There is no single-record read for it; re-read the door object instead.",
            );
        }

        const door = this.DoorOperationFor(obj, cfg);
        if (!door) {
            throw new Error(
                `[eventscribe] No read operation is declared for "${ctx.ObjectName}" ` +
                '(Configuration.accessPath.doorOperation / dispatch.methodValue / DefaultQueryParams). ' +
                'On this RPC-over-querystring API a read cannot be dispatched without one.',
            );
        }

        const keyParam = this.RecordKeyParamFor(obj, cfg);
        if (!keyParam) {
            throw new Error(
                `[eventscribe] Cannot read one "${ctx.ObjectName}" by id: no record-key parameter is declared ` +
                '(Configuration.writeOperation.idParam / deleteOperation.idParam, and the object declares no ' +
                'single primary key to fall back on). This connector will not guess a query-parameter name.',
            );
        }

        return this.scope.run(this.ScopeFor(companyIntegration, ctx.ObjectName, 'get'), async () => {
            const auth = await this.Authenticate(companyIntegration, contextUser);
            const doorURL = this.DoorURL(companyIntegration, auth, obj, door);
            const url = `${doorURL}${doorURL.includes('?') ? '&' : '?'}${encodeURIComponent(keyParam)}=${encodeURIComponent(ctx.ExternalID)}`;
            const response = await this.MakeHTTPRequest(auth, url, 'GET', this.BuildHeaders(auth));
            if (response.Status === 404) return null;
            if (response.Status < 200 || response.Status >= 300) throw this.ErrorFor(response, url);

            const rows = this.NormalizeResponse(response.Body, obj.ResponseDataKey);
            if (rows.length === 0) return null;
            const fields = this.GetCachedFields(obj.ID);
            return this.ToEventscribeRecord(rows[0], ctx.ObjectName, this.PrimaryKeyNames(fields), obj);
        });
    }

    /**
     * The query-parameter name that names ONE record on a read, in metadata order: the operation's own
     * declared `idParam` first, then the object's single declared primary key. A COMPOSITE key returns
     * null — this vendor documents no multi-key single-record door, and splitting one across invented
     * parameter names would be a fabrication. So does an object with no declared key at all: the frozen
     * contract withdrew seven weakly-evidenced keys, and its no-identity path forbids substituting a guess.
     */
    private RecordKeyParamFor(obj: MJIntegrationObjectEntity, cfg: EventscribeObjectConfig | null): string | null {
        const declared = cfg?.writeOperation?.idParam ?? cfg?.deleteOperation?.idParam;
        if (declared) return declared;
        const pks = this.PrimaryKeyNames(this.GetCachedFields(obj.ID));
        return pks.length === 1 ? pks[0] : null;
    }

    /**
     * Wraps the generic flat body in a ONE-ELEMENT ARRAY for the operations whose metadata declares the
     * array-body convention. `Configuration.BatchSemantics` is explicit: "JSON array in the raw POST
     * body (single-object writes still require wrapping in a one-element array)". Sending the bare
     * object instead is a malformed request for those operations. Everything else keeps the base
     * class's shape untouched — the decision is per-operation and read from metadata (see
     * {@link UsesArrayBody}), never a list of vendor operation names written into this file.
     */
    protected override BuildOperationBody(
        attributes: Record<string, unknown>,
        bodyShape: string | null,
        bodyKey: string | null,
    ): unknown {
        const body = super.BuildOperationBody(attributes, bodyShape, bodyKey);
        const store = this.scope.getStore();
        if (!store || store.Verb === 'read' || store.Verb === 'get') return body;
        return this.UsesArrayBody(store.IntegrationID, store.ObjectName, store.Verb) ? [body] : body;
    }

    /**
     * Reads the new record's id from the vendor's response. The base helper only knows the generic
     * `id`/`ID` names; Cadmium returns the record's OWN key (Booth's `createIDBasis`: "the operation's
     * own sample response contains the record key 'BoothID'"), and for an array-body write the response
     * is an ARRAY of per-record results. Candidate names come from the object's declared
     * `writeOperation.idParam` and then its declared primary-key columns — from metadata, in order.
     * `IDLocation = 'n/a'` means the vendor documents NO id in the response; that returns undefined
     * rather than reaching for a field that was never promised.
     */
    protected override ExtractIDFromResponse(response: RESTResponse, idLocation: string | null): string | undefined {
        if (!idLocation || idLocation === 'body' || idLocation === 'n/a') {
            const first = Array.isArray(response.Body) ? this.AsObject(response.Body[0]) : this.AsObject(response.Body);
            if (first) {
                for (const name of this.WriteIDFieldNames()) {
                    const value = first[name];
                    if (typeof value === 'string' || typeof value === 'number') return String(value);
                }
            }
        }
        // 'n/a' is the metadata's statement that the vendor promises NO id on this response
        // (Account's `createIDBasis`: "the created record must be re-read by its natural key"). The scan
        // above is opportunistic — if the vendor did not return the record's OWN declared key, this
        // stops here rather than falling through to the base helper's generic `id`/`ID` guesses, which
        // this vendor never documented. The base then fails the create LOUDLY, which is correct: an
        // untrackable create must not be reported green.
        if (idLocation === 'n/a') return undefined;
        return super.ExtractIDFromResponse(response, idLocation);
    }

    /** Reads the vendor's own message out of the documented `{"error": ...}` envelope. */
    protected override ExtractErrorMessage(response: RESTResponse): string | undefined {
        return this.VendorMessage(response.Body) ?? super.ExtractErrorMessage(response);
    }

    /**
     * THE ONE GENUINELY IDIOSYNCRATIC WRITE PATH. `Configuration.BatchSemantics.addUpdateAccount`:
     * "non-atomic -- each record in the array is processed INDEPENDENTLY ... If ANY record in the batch
     * fails, the overall HTTP response status is 400 -- but valid records in the SAME request are still
     * created/updated. Callers must inspect the individual per-record results in the response body".
     *
     * So this sends ONE request carrying the whole array and then reads the PER-RECORD results out of
     * the body — a 400 is not treated as total failure. When the per-record results cannot be located
     * positionally, it degrades CONSERVATIVELY: a 2xx reports success, a non-2xx reports failure for
     * every record with the vendor's message, and no record is ever claimed successful on a guess
     * (the `addUpdate*` operations are upserts, so a conservative re-push is idempotent).
     */
    public override async BatchCreateRecords(ctxs: CreateRecordContext[]): Promise<CRUDResult[]> {
        return this.RunArrayBodyBatch(ctxs, 'create', c => this.CreateRecord(c));
    }

    /**
     * Same array-body batch, for the `addUpdate*` upserts on the update side — but ONLY when the
     * object's declared `UpdateAPIPath` carries no `{ID}` placeholder. Every current object declares
     * one (`...&AccountID={ID}`), which is the SINGLE-record URL shape, and stripping it to force a
     * batch would be inventing a request. Those fall back to the per-record path: correctness first,
     * throughput second.
     */
    public override async BatchUpdateRecords(ctxs: UpdateRecordContext[]): Promise<CRUDResult[]> {
        return this.RunArrayBodyBatch(ctxs, 'update', c => this.UpdateRecord(c));
    }

    /** Groups by object, batches the eligible groups, and routes the rest through the single-record path. */
    private async RunArrayBodyBatch<C extends { CompanyIntegration: unknown; ContextUser: unknown; ObjectName: string; Attributes: Record<string, unknown> }>(
        ctxs: C[],
        verb: 'create' | 'update',
        single: (ctx: C) => Promise<CRUDResult>,
    ): Promise<CRUDResult[]> {
        const results = new Array<CRUDResult>(ctxs.length);
        const groups = new Map<string, number[]>();
        for (let i = 0; i < ctxs.length; i++) {
            const list = groups.get(ctxs[i].ObjectName);
            if (list) list.push(i); else groups.set(ctxs[i].ObjectName, [i]);
        }

        for (const [objectName, indexes] of groups) {
            const companyIntegration = ctxs[indexes[0]].CompanyIntegration as MJCompanyIntegrationEntity;
            const contextUser = ctxs[indexes[0]].ContextUser as UserInfo;
            const obj = this.GetCachedObject(companyIntegration.IntegrationID, objectName);
            const path = verb === 'create' ? obj.CreateAPIPath : obj.UpdateAPIPath;
            const method = verb === 'create' ? obj.CreateMethod : obj.UpdateMethod;
            const idLocation = verb === 'create' ? obj.CreateIDLocation : obj.UpdateIDLocation;

            const eligible = path != null
                && method != null
                && !/\{(ID|id|ExternalID)\}/.test(path)
                && this.UsesArrayBody(companyIntegration.IntegrationID, objectName, verb);
            if (!eligible) {
                for (const i of indexes) results[i] = await single(ctxs[i]);
                continue;
            }

            const bodies = indexes.map(i => ctxs[i].Attributes);
            const auth = await this.Authenticate(companyIntegration, contextUser);
            const url = this.JoinURL(this.GetBaseURL(companyIntegration, auth, objectName), path as string);
            // Same per-call object scope the single-record path establishes, so the per-record id is read
            // with the object's OWN declared key names rather than a generic guess.
            const scope = this.ScopeFor(companyIntegration, objectName, verb);
            const { response, outcomes } = await this.scope.run(scope, async () => {
                const sent = await this.SendRequest(auth, url, method as string, this.BuildHeaders(auth), bodies);
                return { response: sent, outcomes: this.ReadPerRecordOutcomes(sent, bodies.length, idLocation) };
            });
            for (let k = 0; k < indexes.length; k++) {
                const outcome = outcomes[k];
                results[indexes[k]] = outcome.Success
                    ? { Success: true, StatusCode: response.Status, ExternalID: outcome.ExternalID }
                    : { Success: false, StatusCode: response.Status, ErrorMessage: outcome.ErrorMessage };
            }
        }
        return results;
    }

    /**
     * Reads the per-record results out of a non-atomic array-body response. The vendor documents that
     * they exist and must be inspected, but never prints their exact schema, so this locates them
     * POSITIONALLY: the response array (or the first array-valued property of the response object)
     * whose length matches the request array. Each item fails when it carries the documented error
     * envelope; otherwise it succeeded — even under an overall HTTP 400, which is precisely the
     * partial-success case. No positional array ⇒ the conservative all-or-nothing verdict.
     */
    private ReadPerRecordOutcomes(response: RESTResponse, expected: number, idLocation: string | null): BatchItemOutcome[] {
        const items = this.LocatePositionalResults(response.Body, expected);
        const ok = response.Status >= 200 && response.Status < 300;
        if (!items) {
            const message = this.VendorMessage(response.Body)
                ?? `HTTP ${response.Status} on batch write; the vendor's per-record results were not present in the response body`;
            return Array.from({ length: expected }, () => (
                ok ? { Success: true } : { Success: false, ErrorMessage: message }
            ));
        }
        return items.map((item) => {
            const asObject = this.AsObject(item);
            const error = this.VendorMessage(item);
            if (error != null) return { Success: false, ErrorMessage: error };
            const id = asObject
                ? this.ExtractIDFromResponse({ Status: response.Status, Body: asObject, Headers: response.Headers }, idLocation)
                : undefined;
            return { Success: true, ExternalID: id };
        });
    }

    /** The response array whose length matches the request array, at the root or one level down. */
    private LocatePositionalResults(body: unknown, expected: number): unknown[] | null {
        if (Array.isArray(body)) return body.length === expected ? body : null;
        const asObject = this.AsObject(body);
        if (!asObject) return null;
        for (const value of Object.values(asObject)) {
            if (Array.isArray(value) && value.length === expected) return value;
        }
        return null;
    }

    /**
     * Whether the object's write/delete operation takes a JSON ARRAY body, decided ENTIRELY from
     * metadata: a structural `requestShape` on the operation, a structural
     * `Integration.Configuration.BatchSemantics[<operationId>]` entry, or the vendor's own
     * cross-operation convention statement — which is matched against the operation id the OBJECT's
     * metadata supplies, so no vendor operation name is ever written into this file.
     */
    private UsesArrayBody(integrationID: string, objectName: string, verb: 'create' | 'update' | 'delete'): boolean {
        let cfg: EventscribeObjectConfig | null;
        try {
            cfg = this.ObjectConfig(this.GetCachedObject(integrationID, objectName));
        } catch {
            return false;
        }
        const operation = verb === 'delete' ? cfg?.deleteOperation : cfg?.writeOperation;
        const operationID = operation?.operationId;
        if (!operationID) return false;
        if (operation?.requestShape && /array/i.test(operation.requestShape)) return true;

        const semantics = this.IntegrationConfig()?.BatchSemantics;
        if (!semantics) return false;
        const entry = this.AsObject(semantics[operationID]);
        if (entry) {
            const shape = entry.requestShape;
            if (typeof shape !== 'string' || /array/i.test(shape)) return true;
        }
        for (const value of Object.values(semantics)) {
            const convention = this.AsObject(value);
            const description = convention?.description;
            if (typeof description === 'string' && description.includes(operationID)) return true;
        }
        return false;
    }

    /** Candidate id field names for the CURRENT scope's object, in metadata order. Never a guessed name. */
    private WriteIDFieldNames(): string[] {
        const store = this.scope.getStore();
        if (!store) return [];
        let obj: MJIntegrationObjectEntity;
        try {
            obj = this.GetCachedObject(store.IntegrationID, store.ObjectName);
        } catch {
            return [];
        }
        const cfg = this.ObjectConfig(obj);
        const names: string[] = [];
        const declared = store.Verb === 'delete' ? cfg?.deleteOperation?.idParam : cfg?.writeOperation?.idParam;
        if (declared) names.push(declared);
        for (const name of this.PrimaryKeyNames(this.GetCachedFields(obj.ID))) {
            if (!names.includes(name)) names.push(name);
        }
        return names;
    }

    // ── Rate limiting (vendor-documented, per METHOD) ─────────────────────────

    /**
     * Honours the vendor's documented spacing before every request. The window comes from metadata —
     * `Integration.Configuration.RateLimits.standard` for the vendor-wide allowance, its `overrides`
     * (and any object whose own `Configuration.rateLimit` is scoped `object-override`) for the two
     * documented heavy methods that require 60 s between calls. Keyed by `host|MethodValue`, because
     * on this RPC API a "method" is the operation, not the URL path. No window in metadata ⇒ no pacing
     * invented here; the engine's own adaptive limiter still applies.
     *
     * SCOPED TO THE HOSTS THE METADATA DECLARES ({@link VendorHosts}). The documented allowance is a
     * property of Cadmium's OWN service, identified in metadata by host. When a connection is pointed
     * somewhere else — an operator's gateway, a staging or replay endpoint — this connector holds NO
     * documented allowance for that host, and imposing a 60-second sleep on a service whose real policy
     * is unknown is an invented number, not a safe default. Those requests are governed by the engine's
     * adaptive limiter and its 429 handling instead. Declares no host at all ⇒ everything is paced.
     */
    private async PaceRequest(url: string): Promise<void> {
        const host = this.HostOf(url).toLowerCase();
        const declaredHosts = this.VendorHosts();
        if (declaredHosts.size > 0 && !declaredHosts.has(host)) return;
        const methodValue = this.MethodValueFromURL(url);
        const windowMs = this.RateWindowFor(methodValue);
        if (!Number.isFinite(windowMs) || windowMs <= 0) return;
        const key = `${host}|${methodValue ?? ''}`;
        const now = Date.now();
        const earliest = this.nextAllowedAt.get(key) ?? 0;
        const wait = Math.max(0, earliest - now);
        this.nextAllowedAt.set(key, Math.max(now, earliest) + windowMs);
        if (wait > 0) await this.Sleep(wait);
    }

    /** The documented spacing for one operation: per-method override first, vendor-wide standard second. */
    private RateWindowFor(methodValue: string | null): number {
        const config = this.IntegrationConfig();
        const limits = config?.RateLimits;
        if (methodValue) {
            for (const override of limits?.overrides ?? []) {
                if (override.methods?.includes(methodValue) && Number.isFinite(override.windowMs)) {
                    return override.windowMs as number;
                }
            }
            const perObject = this.ObjectRateOverrideFor(methodValue);
            if (perObject != null) return perObject;
        }
        return Number.isFinite(limits?.standard?.windowMs) ? (limits!.standard!.windowMs as number) : 0;
    }

    /** A per-object `Configuration.rateLimit` explicitly scoped `object-override`, matched by Method value. */
    private ObjectRateOverrideFor(methodValue: string): number | null {
        const integrationID = this.tryGetIntegrationID();
        if (!integrationID) return null;
        for (const obj of this.getCachedObjects(integrationID)) {
            const cfg = this.ObjectConfig(obj);
            const rate = cfg?.rateLimit;
            if (!rate || rate.scope !== 'object-override' || !Number.isFinite(rate.windowMs)) continue;
            if (this.DoorOperationFor(obj, cfg) === methodValue) return rate.windowMs as number;
        }
        return null;
    }

    /**
     * The hosts the METADATA declares for this vendor: every `BaseURLsByFamily` entry plus every
     * object's own `Configuration.absoluteEndpoint` (which is what carries the out-of-scope families
     * whose hosts the family table deliberately omits). This is the set the vendor's documented
     * rate-limit applies to — see {@link PaceRequest}. Never a literal: an empty set means the
     * metadata named no host, and the conservative "pace everything" branch takes over.
     */
    private VendorHosts(): Set<string> {
        const hosts = new Set<string>();
        for (const entry of this.IntegrationConfig()?.BaseURLsByFamily ?? []) {
            const host = this.HostOf(entry.baseUrl).toLowerCase();
            if (host.length > 0) hosts.add(host);
        }
        const integrationID = this.tryGetIntegrationID();
        if (integrationID) {
            for (const obj of this.getCachedObjects(integrationID)) {
                const endpoint = this.ObjectConfig(obj)?.absoluteEndpoint;
                if (!endpoint) continue;
                const host = this.HostOf(endpoint).toLowerCase();
                if (host.length > 0) hosts.add(host);
            }
        }
        return hosts;
    }

    /** Sleeps. Isolated so tests can assert the pacing decision without waiting for it. */
    protected async Sleep(ms: number): Promise<void> {
        if (ms <= 0) return;
        await new Promise<void>(resolve => setTimeout(resolve, ms));
    }

    // ── URL + credential assembly ─────────────────────────────────────────────

    /**
     * Adds the credential query parameters. Their NAMES come from
     * `Integration.Configuration.AuthCredentialParamName` ("APIKey") and
     * `Configuration.AuthMultiTenantParam.name` ("eID"); if the metadata does not name the credential
     * parameter, this raises rather than guessing a name onto the wire. `eID` is added only when the
     * connection actually carries an event id, and an existing value in the URL is never overwritten.
     */
    private WithCredentialParams(auth: EventscribeAuthContext, url: string): string {
        const config = this.IntegrationConfig();
        const keyParam = config?.AuthCredentialParamName;
        if (!keyParam) {
            throw new Error(
                '[eventscribe] Integration.Configuration.AuthCredentialParamName is not set, so the name of the ' +
                'credential query parameter is unknown. This connector will not guess a parameter name onto the ' +
                'wire — push metadata/integrations/eventscribe first.',
            );
        }
        const existing = this.QueryKeys(url);
        let out = url;
        if (!existing.has(keyParam.toLowerCase())) {
            out += `${out.includes('?') ? '&' : '?'}${encodeURIComponent(keyParam)}=${encodeURIComponent(auth.APIKey)}`;
        }
        const eventParam = config?.AuthMultiTenantParam?.name;
        if (eventParam && auth.EventID && !existing.has(eventParam.toLowerCase())) {
            out += `${out.includes('?') ? '&' : '?'}${encodeURIComponent(eventParam)}=${encodeURIComponent(auth.EventID)}`;
        }
        return out;
    }

    /**
     * Appends the DECLARED incremental-window parameters resolved by {@link WindowParamsFor} for the
     * read currently in scope. Absent scope, or an object with no declared window, is a no-op — so a
     * full-pull object's URL is byte-identical to what it was before. An existing value on the URL is
     * never overwritten.
     */
    private WithWindowParams(url: string): string {
        const window = this.scope.getStore()?.WindowParams;
        if (!window) return url;
        const existing = this.QueryKeys(url);
        let out = url;
        for (const [name, value] of Object.entries(window)) {
            if (existing.has(name.toLowerCase())) continue;
            out += `${out.includes('?') ? '&' : '?'}${encodeURIComponent(name)}=${encodeURIComponent(value)}`;
        }
        return out;
    }

    /**
     * `<familyBase><APIPath>?<MethodParam>=<operation>` for one object's door.
     *
     * The base URL is resolved through {@link GetBaseURL} — NOT by calling {@link BaseURLForObject}
     * directly — so that EVERY request this connector makes goes through the ONE resolution seam.
     * `GetBaseURL` is the documented per-connection override point (an operator pointing a connection
     * at a gateway, a harness redirecting the origin); a path that reaches around it would obey the
     * declared vendor host while the rest of the connector obeyed the override, which is exactly the
     * kind of split-brain routing that sends half a sync to the wrong origin.
     */
    private DoorURL(
        companyIntegration: MJCompanyIntegrationEntity,
        auth: RESTAuthContext,
        obj: MJIntegrationObjectEntity,
        operation: string,
    ): string {
        const base = this.JoinURL(this.GetBaseURL(companyIntegration, auth, obj.Name), obj.APIPath);
        const param = this.MethodParamName(obj);
        if (!param) {
            throw new Error(
                `[eventscribe] No dispatch parameter name is declared for "${obj.Name}" ` +
                '(Integration.Configuration.ReadContract.methodParamName / Configuration.dispatch.methodParamName). ' +
                'On this RPC-over-querystring API the operation cannot be selected without it.',
            );
        }
        // The credential is deliberately absent here: SendRequest is the single place it touches the wire.
        return `${base}${base.includes('?') ? '&' : '?'}${encodeURIComponent(param)}=${encodeURIComponent(operation)}`;
    }

    /** The dispatch parameter name: the object's own declaration first, the integration contract second. */
    private MethodParamName(obj: MJIntegrationObjectEntity): string | null {
        return this.ObjectConfig(obj)?.dispatch?.methodParamName
            ?? this.IntegrationConfig()?.ReadContract?.methodParamName
            ?? null;
    }

    /** The Method value carried on a built URL, used only to key the vendor's per-method pacing. */
    private MethodValueFromURL(url: string): string | null {
        const param = this.IntegrationConfig()?.ReadContract?.methodParamName;
        if (!param) return null;
        try {
            return new URL(url).searchParams.get(param);
        } catch {
            return null;
        }
    }

    // ── Metadata routing helpers ──────────────────────────────────────────────

    /**
     * The operation that RETURNS this object's records. For a nested object that is the DOOR
     * (`accessPath.doorOperation`); for a directly-queryable object it is its own read method. The
     * declared access path wins over `dispatch.methodValue`, because the access path is the statement
     * about where the records actually come from.
     */
    private DoorOperationFor(obj: MJIntegrationObjectEntity, cfg: EventscribeObjectConfig | null): string | null {
        const fromAccessPath = cfg?.accessPath?.doorOperation;
        if (fromAccessPath) return fromAccessPath;
        const fromDispatch = cfg?.dispatch?.methodValue;
        if (fromDispatch) return fromDispatch;
        const param = this.MethodParamName(obj);
        const defaults = this.ParseJSONObject(obj.DefaultQueryParams);
        const fromDefaults = param && defaults ? defaults[param] : undefined;
        return typeof fromDefaults === 'string' && fromDefaults.length > 0 ? fromDefaults : null;
    }

    /** How deep this object sits under its door. 0 = directly queryable. */
    private DepthOf(cfg: EventscribeObjectConfig | null): number {
        const depth = cfg?.accessPath?.depth;
        return typeof depth === 'number' && Number.isFinite(depth) ? depth : 0;
    }

    /**
     * The response key carrying a nested object's rows: the explicit `nestedContainerKey`, else the
     * last segment of the declared `accessPath.nestingFieldPath` (`"Exhibitor → Booths[]"` → `Booths`).
     * Both are metadata; nothing is inferred from the payload.
     */
    private NestedContainerKeyFor(cfg: EventscribeObjectConfig | null): string | null {
        const explicit = cfg?.nestedContainerKey;
        if (explicit) return explicit;
        const path = cfg?.accessPath?.nestingFieldPath;
        if (!path) return null;
        const segments = path.split('→').map(s => s.trim()).filter(s => s.length > 0);
        const last = segments[segments.length - 1];
        if (!last) return null;
        const cleaned = last.replace(/\[\]$/, '').trim();
        return cleaned.length > 0 ? cleaned : null;
    }

    /** Parsed `Configuration` JSON for one IntegrationObject; malformed degrades to absent. */
    private ObjectConfig(obj: MJIntegrationObjectEntity): EventscribeObjectConfig | null {
        const parsed = this.ParseJSONObject(obj.Configuration);
        if (!parsed) return null;
        const result = ZObjectConfig.safeParse(parsed);
        return result.success ? result.data : null;
    }

    /** Parsed `Integration.Configuration` — the connector-wide vendor facts. */
    private IntegrationConfig(): EventscribeIntegrationConfig | null {
        const parsed = this.ParseJSONObject(this.IntegrationConfigurationJSON());
        if (!parsed) return null;
        const result = ZIntegrationConfig.safeParse(parsed);
        return result.success ? result.data : null;
    }

    /** The raw `Integration.Configuration` string. Isolated so tests can supply it without the engine. */
    protected IntegrationConfigurationJSON(): string | null {
        try {
            return IntegrationEngineBase.Instance.GetIntegrationByName(this.IntegrationName)?.Configuration ?? null;
        } catch {
            return null;
        }
    }

    /** The object the current async call chain is serving, when one is in scope. */
    private ScopedObject(): MJIntegrationObjectEntity | null {
        const store = this.scope.getStore();
        if (!store) return null;
        try {
            return this.GetCachedObject(store.IntegrationID, store.ObjectName);
        } catch {
            return null;
        }
    }

    /** The cached IntegrationObject by name, or null. Routes through the same seam every read path uses. */
    private TryGetCachedObject(integrationID: string, objectName: string): MJIntegrationObjectEntity | null {
        try {
            return this.GetCachedObject(integrationID, objectName);
        } catch {
            return null;
        }
    }

    /** ACTIVE objects for this integration; absent metadata degrades to an empty list, never a throw. */
    protected getCachedObjects(integrationID: string): MJIntegrationObjectEntity[] {
        try {
            return IntegrationEngineBase.Instance.GetActiveIntegrationObjects(integrationID);
        } catch {
            return [];
        }
    }

    /** This integration's ID by its verbatim name, or null when metadata is not loaded. */
    protected tryGetIntegrationID(): string | null {
        try {
            return IntegrationEngineBase.Instance.GetIntegrationByName(this.IntegrationName)?.ID ?? null;
        } catch {
            return null;
        }
    }

    /** The per-call scope a generic CRUD verb runs inside. */
    private ScopeFor(companyIntegration: unknown, objectName: string, verb: EventscribeCallScope['Verb']): EventscribeCallScope {
        return {
            IntegrationID: (companyIntegration as MJCompanyIntegrationEntity).IntegrationID,
            ObjectName: objectName,
            Verb: verb,
        };
    }

    // ── Record assembly ───────────────────────────────────────────────────────

    /**
     * Builds an `ExternalRecord` whose `Fields` is the COMPLETE source row — never a projection — so
     * the framework's custom-column capture can still see a per-tenant column this build never
     * declared. Composite keys join with `|`. When a declared key value is missing (several of this
     * vendor's nested leaves have only a WEAK, shape-derived key) the identity falls back to a content
     * hash: a soft key must never be able to REJECT a valid row.
     */
    private ToEventscribeRecord(
        raw: Record<string, unknown>,
        objectType: string,
        pkFieldNames: string[],
        obj: MJIntegrationObjectEntity,
    ): ExternalRecord {
        const allPresent = pkFieldNames.length > 0
            && pkFieldNames.every(name => raw[name] != null && serializeKeyValue(raw[name]).length > 0);
        const externalID = allPresent
            ? pkFieldNames.map(name => serializeKeyValue(raw[name])).join('|')
            : computeContentHash(raw);

        const record: ExternalRecord = { ExternalID: externalID, ObjectType: objectType, Fields: raw };
        const watermarkField = obj.IncrementalWatermarkField;
        const watermark = watermarkField ? raw[watermarkField] : null;
        if (watermark != null) {
            const when = new Date(String(watermark));
            if (!Number.isNaN(when.getTime())) record.ModifiedAt = when;
        }
        return record;
    }

    /**
     * The DECLARED primary-key names in Sequence order — and NOTHING else. Deliberately does NOT use
     * the base class's synthetic `['ID']` fallback: the frozen contract WITHDREW seven weakly-evidenced
     * keys (they survive as ordinary nullable columns, and the `StableOrderingKey` columns that pointed
     * at them were nulled to match), and its no-identity path is explicit that a PK-less object must
     * make NO idempotent-identity claim and must NOT substitute a guessed alternative. Returning `['ID']`
     * here would be exactly that guess — and would silently start claiming identity the day a tenant's
     * payload happens to carry a column literally named `ID`. An empty list routes the object to the
     * content-hash identity in {@link ToEventscribeRecord}, i.e. the append/full-refresh path the
     * contract prescribes, where the engine's own hash idempotency does the deduplication.
     */
    private PrimaryKeyNames(fields: MJIntegrationObjectFieldEntity[]): string[] {
        return fields.filter(f => f.IsPrimaryKey).sort((a, b) => a.Sequence - b.Sequence).map(f => f.Name);
    }

    // ── Credential resolution ─────────────────────────────────────────────────

    /** Credential record first, connection Configuration second. No inline crypto; nothing is logged. */
    private async LoadCredentials(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<EventscribeCredentials> {
        let fromCredential: EventscribeCredentials | null = null;
        if (companyIntegration.CredentialID) {
            try {
                const md = new Metadata();
                const credential = await md.GetEntityObject<MJCredentialEntity>('MJ: Credentials', contextUser);
                const loaded = await credential.Load(companyIntegration.CredentialID);
                if (loaded && credential.Values) fromCredential = this.ParseCredentialJSON(credential.Values);
            } catch {
                // A credential the connection cannot load is a configuration problem, not a crash: the
                // Configuration fallback still applies and Authenticate reports precisely what is missing.
            }
        }
        const fromConfig = this.ParseCredentialJSON(companyIntegration.Configuration);
        return {
            APIKey: fromCredential?.APIKey ?? fromConfig?.APIKey,
            EventID: fromCredential?.EventID ?? fromConfig?.EventID,
        };
    }

    /** Extracts the two credential values from a credential / Configuration JSON string. */
    private ParseCredentialJSON(json: string | null): EventscribeCredentials | null {
        const parsed = this.ParseJSONObject(json);
        if (!parsed) return null;
        return {
            APIKey: this.FirstString(parsed, ['APIKey', 'apiKey', 'ApiKey', 'api_key', 'apikey', 'key']),
            EventID: this.FirstString(parsed, ['eID', 'eId', 'EID', 'eventID', 'EventID', 'eventId', 'event_id']),
        };
    }

    // ── Error classification ──────────────────────────────────────────────────

    /**
     * Classifies from the vendor's own envelope AND the status. `Configuration.ErrorContract` documents
     * `{"error": "<human-readable message>"}` with 400 and 404 observed, and states it applies "across
     * API methods" — so a 2xx carrying that envelope is a FAILURE, which is exactly how a sync would
     * otherwise report zero rows and green at the same time. The one documented exception (404 with a
     * body of `[]`) is normalised to an empty success in {@link SendRequest} and never reaches here.
     */
    private ErrorFor(response: RESTResponse, url: string): EventscribeAPIError {
        const vendorMessage = this.VendorMessage(response.Body);
        const classification = this.ClassifyEventscribeResponse(response.Status, vendorMessage);
        return new EventscribeAPIError(
            `[eventscribe] HTTP ${response.Status} (${classification.Reason}) from ${this.PathOf(url)}: ` +
            `${vendorMessage ?? 'no vendor message'}`,
            response.Status,
            response.Headers,
            classification,
            vendorMessage,
        );
    }

    /** The status/envelope → structured verdict mapping, exposed so tests can assert it directly. */
    public ClassifyEventscribeResponse(status: number, vendorMessage: string | undefined): EventscribeErrorClassification {
        if (status === 429) {
            return { Code: 'RATE_LIMIT_EXCEEDED', Severity: 'Warning', Retryable: true, Reason: 'throttled' };
        }
        if (status >= 500) {
            return { Code: 'CONNECTOR_ERROR', Severity: 'Critical', Retryable: true, Reason: 'server-error' };
        }
        if (status === 401 || status === 403) {
            return { Code: 'CONFIGURATION_ERROR', Severity: 'Critical', Retryable: false, Reason: 'credential-rejected' };
        }
        if (status === 404) {
            return { Code: 'CONNECTOR_ERROR', Severity: 'Warning', Retryable: false, Reason: 'not-found' };
        }
        if (status === 400) {
            return { Code: 'VALIDATION_ERROR', Severity: 'Critical', Retryable: false, Reason: 'rejected-by-vendor' };
        }
        // A 2xx that carried the documented error envelope: a real failure wearing a success status.
        return {
            Code: vendorMessage != null ? 'CONNECTOR_ERROR' : 'UNKNOWN_ERROR',
            Severity: 'Critical',
            Retryable: false,
            Reason: vendorMessage != null ? 'error-envelope-on-success-status' : 'unclassified',
        };
    }

    /** The vendor's message from the documented envelope, or undefined when the body carries no error. */
    private VendorMessage(body: unknown): string | undefined {
        const asObject = this.AsObject(body);
        if (!asObject) return undefined;
        const error = asObject.error ?? asObject.Error;
        if (typeof error === 'string' && error.length > 0) return error;
        const nested = this.AsObject(error);
        if (nested && typeof nested.message === 'string' && nested.message.length > 0) return nested.message;
        if (nested) return JSON.stringify(nested);
        return undefined;
    }

    // ── Small utilities ───────────────────────────────────────────────────────

    /** Walks a dotted path into a parsed body. Returns undefined at the first missing segment. */
    private ReadPath(source: unknown, path: string[]): unknown {
        let cursor: unknown = source;
        for (const segment of path) {
            const asObject = this.AsObject(cursor);
            if (!asObject || !(segment in asObject)) return undefined;
            cursor = asObject[segment];
        }
        return cursor;
    }

    /** Joins a base URL with an API path exactly as declared — no path is invented or normalised away. */
    private JoinURL(baseURL: string, apiPath: string): string {
        const base = this.TrimTrailingSlash(baseURL);
        const path = apiPath.startsWith('/') ? apiPath : `/${apiPath}`;
        return `${base}${path}`;
    }

    private TrimTrailingSlash(value: string): string {
        const trimmed = value.trim();
        return trimmed.endsWith('/') ? trimmed.slice(0, -1) : trimmed;
    }

    /** Lowercased query-parameter keys already present on a URL. */
    private QueryKeys(url: string): Set<string> {
        const out = new Set<string>();
        const q = url.indexOf('?');
        if (q < 0) return out;
        for (const pair of url.slice(q + 1).split('&')) {
            const eq = pair.indexOf('=');
            const key = eq < 0 ? pair : pair.slice(0, eq);
            if (key.length > 0) out.add(decodeURIComponent(key).toLowerCase());
        }
        return out;
    }

    /** Host of a URL, for pacing keys. Falls back to the raw string when it is not parseable. */
    private HostOf(url: string): string {
        try { return new URL(url).host; } catch { return url; }
    }

    /** Path-only view of a URL, for messages that must never carry a query string or a credential. */
    private PathOf(url: string): string {
        try { return new URL(url).pathname; } catch { return url.split('?')[0]; }
    }

    /** A narrowing cast to a plain object, or null. */
    private AsObject(value: unknown): Record<string, unknown> | null {
        return value != null && typeof value === 'object' && !Array.isArray(value)
            ? value as Record<string, unknown>
            : null;
    }

    /** First non-empty string value among `keys` on a parsed object. */
    private FirstString(source: Record<string, unknown> | null | undefined, keys: string[]): string | undefined {
        if (!source) return undefined;
        for (const key of keys) {
            const v = source[key];
            if (typeof v === 'string' && v.trim().length > 0) return v.trim();
        }
        return undefined;
    }

    /** A finite number from an arbitrary JSON value, or null. Vendor counters arrive as either type. */
    private FiniteNumber(value: unknown): number | null {
        const n = typeof value === 'number' ? value : typeof value === 'string' ? Number(value) : NaN;
        return Number.isFinite(n) ? n : null;
    }

    /** Tolerant JSON-object parse; malformed configuration degrades to "absent" rather than crashing. */
    private ParseJSONObject(json: string | null | undefined): Record<string, unknown> | null {
        if (!json || json.trim().length === 0) return null;
        try { return this.AsObject(JSON.parse(json)); } catch { return null; }
    }

    /** An error message safe to log: never carries credential bytes. */
    private SafeMessage(err: unknown): string {
        let raw = err instanceof Error ? err.message : String(err);
        for (const auth of this.authCache.values()) {
            if (auth.APIKey && raw.includes(auth.APIKey)) raw = raw.split(auth.APIKey).join('***');
            if (auth.EventID && raw.includes(auth.EventID)) raw = raw.split(auth.EventID).join('***');
        }
        return raw;
    }

    /** Emits a warning at most once per connector lifetime, so the log stays honest rather than noisy. */
    private WarnOnce(key: string, message: string): void {
        if (this.warnedOnce.has(key)) return;
        this.warnedOnce.add(key);
        console.warn(message);
    }
}

/** Forces the module (and its `@RegisterClass` side effect) to be retained by a bundler. */
export function LoadEventscribeConnector(): void {
    // no-op: registration happened on import
}
