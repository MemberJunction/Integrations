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
    ClassifyError,
    computeContentHash,
    serializeKeyValue,
    type RESTAuthContext,
    type RESTResponse,
    type PaginationState,
    type PaginationType,
    type RateLimitPolicy,
    type ConnectionTestResult,
    type ExternalObjectSchema,
    type ExternalFieldSchema,
    type FetchContext,
    type FetchBatchResult,
    type FetchWarning,
    type ExternalRecord,
    type SourceSchemaInfo,
    type SyncErrorCode,
    type ErrorSeverity,
    type UpdateRecordContext,
    type DeleteRecordContext,
    type CRUDResult,
} from '@memberjunction/integration-engine';
import { mergeDeclaredWithSampledFields } from '@memberjunction/connector-schema-merge';

// ─── Design note — WHY THE GENERIC REST READ PATH IS OVERRIDDEN ────────────────
//
// Elevate's Report API is NOT a REST collection API and the base class's generic per-operation
// GET-list CRUD does not fit it. Every declared object is read through ONE endpoint
// (`POST <siteUrl>/api/reports`) and the object is chosen by a BODY field, not by a URL path
// segment or query param. `Configuration.ReadContract.differsFromGenericCRUD` (metadata) states
// this verbatim: "exactly ONE endpoint serves every object, the HTTP method is POST (not GET),
// object selection is a BODY field ... and column selection is an explicit `fields` allow-list".
// A generic `GET <APIPath>` emission answers 301/404/405 on EVERY object, so `FetchChanges` is
// overridden here. That is an evidenced idiosyncrasy, not a shortcut — the WRITE surface stays on
// the base class's generic per-operation slots (see CreateRecord, which is NOT overridden).
//
// The four things this connector must get right, all of them metadata-routed:
//
//  1. THE ENVELOPE. Every read POSTs { api_key, format, resource, fields, filters } to the single
//     door. `resource` comes from the IO's `Configuration.resourceWireValue` (e.g. 'accountingCode',
//     which the RealityProbe proved correct against the vendor's own prose spelling 'accountCode');
//     the door path comes from `IntegrationObject.APIPath` ('/api/reports' — the server's own 301
//     Location target, NOT the documented trailing-slash form). Nothing is guessed in code.
//
//  2. THE FIELD ALLOW-LIST IS NOT PASS-THROUGH. The door returns ONLY the columns the request asks
//     for, and rejects the WHOLE query (HTTP 500) for one unrecognised name. The selector is built
//     from the object's declared IOFs — using each IOF's `Configuration.wireSelector`, which carries
//     the vendor's DOT-PATH form ('product.title', 'user.member_id') rather than the MJ column name —
//     UNIONED with the field names runtime discovery has learned for THIS connection from the door's
//     own `response.labels` dictionary AND then PROVEN acceptable by an out-of-band probe. A hardcoded
//     list would truncate every record to the build-time guess without ever showing up as an error;
//     an UNPROVEN learned name in a data read would put every row of the object behind a guess, because
//     the allow-list is all-or-nothing. Discovery is speculative; the data read never is.
//
//  3. FORMAT IS json WHENEVER A DOT-PATH SELECTOR IS USED. The vendor's own words: "CSV, being a
//     'flat' data format, is limited to only the values in the top-most layer of the API response".
//     csv is opt-in per connection AND refused when the selection is not flat.
//
//  4. BULK IS DATE-WINDOWED, NOT PAGED. The RealityProbe DECIDED pagination NEGATIVE at volume
//     (29,003 rows unfiltered == the sum of 15 all-HTTP-200 yearly windows; limit/offset/page/
//     per_page/page_size all inert), so no paging scheme is invented here. Large pulls are chunked
//     into consecutive non-overlapping windows on the object's DECLARED date field via
//     `{"<field>":{"date":[from,to]}}` — the exact filter shape the probe partitioned with — and every
//     single read verifies the door's own `response.count` against `response.items.length`, which is
//     the silent-truncation tripwire above the volume actually probed.
//
// There is NO vendor host: `GetBaseURL` derives strictly from the connection's own `siteUrl`. The
// vendor's published demo host and demo key are probe-only artefacts and appear NOWHERE in this file.
// The api_key travels in the request BODY, is injected at the single transport choke point, and is
// never logged, never embedded in an error message, and never written to a fixture.

/** Vendor-documented cap on how many times a rejected field name is dropped before the read gives up. */
const MAX_SELECTOR_REPAIRS = 8;

/** Maximum times a single windowed query is halved when the door reports truncation. */
const MAX_WINDOW_SPLIT_DEPTH = 12;

/** Default window span, in days, for a chunked bulk pull — the probe partitioned by year. */
const DEFAULT_WINDOW_DAYS = 365;

/** Maximum 429 retries per request. A 500 from this door is a CLIENT error and is NEVER retried. */
const MAX_THROTTLE_RETRIES = 3;

/** Upper bound on any single honoured `Retry-After` sleep, so a hostile header cannot wedge a sync. */
const MAX_RETRY_AFTER_MS = 60_000;

/** Bound on the create-side `product_url` side-channel, so a long push cannot grow it without limit. */
const MAX_TRACKED_PRODUCT_URLS = 1_000;

/** Parsed per-connection credential. There is no vendor host, so `SiteUrl` is mandatory. */
interface ElevateCredentials {
    /** The client's OWN Elevate site root, e.g. `https://learn.example.org`. */
    SiteUrl?: string;
    /** The per-client Report/Registration API key. Travels in the request BODY on every call. */
    ApiKey?: string;
}

/** Resolved per-connection auth + routing context. */
interface ElevateAuthContext extends RESTAuthContext {
    /** Per-connection base URL derived from the connection's `siteUrl` — never a vendor default. */
    SiteUrl: string;
    /** The api_key injected into every request body. NEVER logged, NEVER put in an error message. */
    ApiKey: string;
    /** The IntegrationID this context was resolved for (metadata lookups off the request path). */
    IntegrationID: string;
}

/** The read contract for ONE object, entirely resolved from metadata. */
interface ElevateReadRoute {
    /** Door path, from `IntegrationObject.APIPath` (probe-corrected to the no-slash canonical form). */
    Door: string;
    /** Wire value for the envelope's `resource` selector, from the IO's `Configuration`. */
    Resource: string;
    /** Dotted path to the row array, from `IntegrationObject.ResponseDataKey`. */
    DataKey: string | null;
    /** Dotted path to the door's own total for the query — the completeness tripwire's left-hand side. */
    CountKey: string;
    /** Dotted path to the per-resource field→label dictionary that feeds runtime DiscoverFields. */
    LabelsKey: string;
}

/** One declared read column: the MJ column name plus how to ask for it and where it lands. */
interface ElevateReadColumn {
    /** MJ/IOF column name (flat, e.g. `product_title`). */
    Name: string;
    /** Wire selector the door accepts (dot-path, e.g. `product.title`). */
    WireSelector: string;
    /** Path into the response row where the value actually lands (e.g. `['product','title']`). */
    ResponsePath: string[];
}

/** One consecutive, non-overlapping date window of a chunked bulk pull. */
interface ElevateWindow {
    /** Inclusive lower bound, `YYYY-MM-DD`. */
    From: string;
    /** Inclusive upper bound, `YYYY-MM-DD`. */
    To: string;
}

/** A classified Elevate failure, derived from the observed error ENVELOPE rather than the status alone. */
export interface ElevateErrorClassification {
    /** Whether this response is a FAILURE at all. A 2xx carrying an error envelope is one. */
    IsError: boolean;
    /** Engine-level sync error code the run artifact reports. */
    Code: SyncErrorCode;
    /** Engine-level severity. */
    Severity: ErrorSeverity;
    /** Whether the engine may retry. A 500 from the read door is a CLIENT error → never retryable. */
    Retryable: boolean;
    /** Short machine-ish reason naming WHY this classification was chosen. */
    Reason: string;
    /** The unrecognised field name when the door rejected the `fields` allow-list, else null. */
    UnknownField: string | null;
}

/**
 * Typed transport failure. Carries the response headers so `ExtractRetryAfterMs` can honour
 * `Retry-After` off the error the engine sees, and the classification so callers do not re-parse.
 */
export class ElevateAPIError extends Error {
    public constructor(
        message: string,
        public readonly Status: number,
        public readonly Headers: Record<string, string>,
        public readonly Classification: ElevateErrorClassification,
    ) {
        super(message);
        this.name = 'ElevateAPIError';
    }
}

/**
 * Elevate LMS (Cadmium) connector.
 *
 * Reads ride the Report API's single POST door with a JSON envelope; writes ride the base class's
 * generic per-operation CRUD slots against the Registration API. Auth is a per-client `api_key`
 * carried in the request BODY.
 */
@RegisterClass(BaseIntegrationConnector, 'ElevateConnector')
export class ElevateConnector extends BaseRESTIntegrationConnector {

    /** Resolved auth per CompanyIntegration.ID. The api_key is static and has no refresh endpoint. */
    private authCache = new Map<string, ElevateAuthContext>();
    /** Field names the door's own `response.labels` dictionary has revealed, per connection+object. */
    private discoveredFieldNames = new Map<string, Set<string>>();
    /**
     * Learned field names this connection's door has PROVEN it accepts on a read, per connection+object.
     * Only these are ever allowed to join a DATA read's `fields` allow-list — see {@link VerifyLearnedFields}.
     */
    private verifiedFieldNames = new Map<string, Set<string>>();
    /** One sampled value per discovered field name, used ONLY for runtime type inference. */
    private discoveredSamples = new Map<string, Map<string, unknown>>();
    /** Field names this connection's door REJECTED — never requested again for that object. */
    private rejectedFieldNames = new Map<string, Set<string>>();
    /** Declared resources this connection accepted a probe query for. Absence NEVER deactivates. */
    private validatedResources = new Map<string, boolean>();
    /**
     * `product_url` returned alongside a created registration, keyed by the new registration_id — the
     * learner's link, which the generic `CRUDResult` has no slot for. Bounded (oldest evicted) so a long
     * push cannot grow it without limit.
     */
    public readonly LastCreatedProductURLs = new Map<string, string>();
    /** Warnings already emitted, so the log stays honest rather than noisy. */
    private warnedOnce = new Set<string>();

    // ── Identity (T1 three-way invariant) ─────────────────────────────────────

    /** Verbatim `MJ: Integrations.Name`. Load-bearing: T1 compares this === the metadata Name. */
    public override get IntegrationName(): string {
        return 'elevate';
    }

    // ── Capability getters (kept in lockstep with the per-operation IO columns) ──

    /** POST /api/registrations exists (productRegistration only) — `CreateAPIPath`/`CreateMethod` are populated. */
    public override get SupportsCreate(): boolean { return true; }

    /**
     * FALSE. `Configuration.WriteCapability.update` (metadata): "No update endpoint is documented for
     * any resource anywhere in the corpus." No IO carries `UpdateAPIPath`. `UpdateRecord` below fails
     * loudly rather than no-opping or degrading into a create.
     */
    public override get SupportsUpdate(): boolean { return false; }

    /**
     * TRUE only in the sense the metadata declares: `POST /registrations/cancel` is a domain-specific
     * CANCEL on one productRegistration, not a generic hard DELETE, and it is NOT reflected on the
     * read side (`Configuration.DeleteSemantics` = 'none'). Deletion RECONCILIATION therefore needs a
     * periodic key sweep — this connector never claims a delete FEED.
     */
    public override get SupportsDelete(): boolean { return true; }

    /**
     * FALSE, permanently. `Configuration.DiscoveryAuthoritativeness` records `no-describe-endpoint` at
     * BOTH object and field level with `deactivationPermitted: false`. With no describe endpoint,
     * absence at runtime proves nothing: a thin query result must never deactivate a persisted object
     * or field, which would be tenant-visible data loss.
     */
    public override get DiscoveryIsAuthoritative(): boolean {
        return false;
    }

    // ── Sync-efficiency hooks (§7/§10) ────────────────────────────────────────

    /**
     * Rate limiting provably EXISTS (Elevate Release 2025.02, verbatim: "Introduced rate limiting for
     * Report API requests") but is UNQUANTIFIED — no ceiling, window, burst or `Retry-After` format is
     * documented anywhere. The only empirical evidence is the RealityProbe's own pacing result recorded
     * in `Configuration.PaginationDefaultsNote`: a pass at ~1.1s between requests was rate-limited
     * (429s on 4 windows); the re-paced pass at ~3.4s completed 15 windows all HTTP 200. That is an
     * OBSERVATION, not a vendor commitment, so the sustained rate published here is deliberately below
     * the slower of the two (≈0.29/s) and the engine's AIMD limiter does the pacing — this connector
     * never sleeps on its own. Burst 1: the door serves one query per request, there is nothing to batch.
     */
    public override get RateLimitPolicy(): RateLimitPolicy {
        return {
            TokensPerSec: 0.29,
            Burst: 1,
            ThrottleBackoffFactor: 0.5,
            SuccessRampPerCall: 0.02,
            MinTokensPerSec: 0.05,
        };
    }

    /** One in flight. The limit exists, its numbers do not, and the door is a reporting engine. */
    public override get MaxConcurrencyHint(): number { return 1; }

    /**
     * Honours `Retry-After` (delta-seconds AND the HTTP-date form) off the typed error the transport
     * threw, so the engine's AIMD bucket backs off by the vendor's own instruction. Returns undefined
     * when the response carried no header — the metadata records `retryAfterHeaderDocumented: false`,
     * so the header's absence is expected and must not be papered over with an invented number.
     */
    public override ExtractRetryAfterMs(error: unknown): number | undefined {
        if (!(error instanceof ElevateAPIError)) return undefined;
        if (error.Status !== 429 && error.Status !== 503) return undefined;
        const raw = error.Headers['retry-after'];
        if (raw == null) return error.Status === 429 ? 1_000 : undefined;
        const seconds = Number(raw);
        if (Number.isFinite(seconds) && seconds >= 0) return Math.min(MAX_RETRY_AFTER_MS, Math.ceil(seconds * 1000));
        const when = Date.parse(String(raw));
        if (Number.isFinite(when)) return Math.min(MAX_RETRY_AFTER_MS, Math.max(0, when - Date.now()));
        return undefined;
    }

    /**
     * Strictly whatever the metadata declares. Only `Product` still carries one (`id`, probe-confirmed
     * populated 1985/1985); `User.member_id` and `AccountingCode.id` were WITHDRAWN by the RealityProbe
     * because they are not populated on every row, and a null-bearing column is not a resume cursor.
     * Never synthesised here.
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

    // ── Discovery (runtime, additive, NEVER deactivating) ─────────────────────

    /**
     * The declared catalog is the FLOOR, not the ceiling and not a code constant: it is seeded into the
     * engine cache from `metadata/integrations/elevate/.elevate.integration.json` and read back here via
     * the base implementation. On top of that floor this method VALIDATES each declared resource against
     * THIS connection with a minimal probe query — accepted ⇒ present.
     *
     * A probe that fails NEVER removes an object. `DiscoveryIsAuthoritative` is false and the metadata
     * records `deactivationPermitted: false`: with no describe endpoint, a rejection can mean a
     * per-tenant permission, a transient fault, or a genuinely absent resource, and those are not
     * distinguishable. The rejection is surfaced as a loud, once-per-connection warning instead.
     */
    public override async DiscoverObjects(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<ExternalObjectSchema[]> {
        const declared: ExternalObjectSchema[] = [];
        for (const obj of this.getCachedObjects(companyIntegration.IntegrationID)) {
            await this.ValidateResource(companyIntegration, contextUser, obj.Name);
            declared.push({
                ID: obj.ID,
                Name: obj.Name,
                Label: obj.DisplayName ?? obj.Name,
                Description: obj.Description ?? undefined,
                SupportsIncrementalSync: obj.SupportsIncrementalSync,
                SupportsWrite: obj.SupportsWrite,
            });
        }
        return declared;
    }

    /**
     * Two-stage, additive. Stage 1 is the declared floor from the engine cache (the base implementation).
     * Stage 2 probes THIS connection: every Report API response carries a `response.labels` dictionary
     * keying the resource's FULL retrievable field set to its display label — returned irrespective of
     * which columns the request asked for — so a site's configured custom/profile fields are reachable
     * per tenant without any describe endpoint. Discovered-only fields are appended, never substituted,
     * and a declared field is never dropped because a probe did not see it.
     */
    public override async DiscoverFields(
        companyIntegration: MJCompanyIntegrationEntity,
        objectName: string,
        contextUser: UserInfo,
    ): Promise<ExternalFieldSchema[]> {
        const declared = await super.DiscoverFields(companyIntegration, objectName, contextUser);
        await this.LearnFieldsFromSource(companyIntegration, contextUser, objectName);

        // A declared column is claimed under BOTH names: its MJ column name (`product_title`) and the
        // dot-path wire selector the door labels it by (`product.title`). Matching on only one of them
        // would re-emit every projected column a second time under its wire name.
        const claimed = new Set<string>();
        for (const f of declared) claimed.add(f.Name.toLowerCase());
        try {
            const obj = this.GetCachedObject(companyIntegration.IntegrationID, objectName);
            for (const col of this.ReadColumnsFor(this.GetCachedFields(obj.ID))) {
                claimed.add(col.Name.toLowerCase());
                claimed.add(col.WireSelector.toLowerCase());
            }
        } catch {
            /* no cached object → the `declared` names above are all we can claim. */
        }

        const key = this.CacheKey(companyIntegration, objectName);
        const samples = this.discoveredSamples.get(key);
        const rejected = this.rejectedFieldNames.get(key) ?? new Set<string>();
        const extra: ExternalFieldSchema[] = [];
        for (const name of this.SortedNames(this.discoveredFieldNames.get(key))) {
            if (claimed.has(name.toLowerCase()) || rejected.has(name)) continue;
            extra.push(this.SchemaForDiscoveredField(name, samples?.get(name)));
        }
        return [...declared, ...extra];
    }

    /**
     * Declared ∪ runtime-discovered, so a tenant's own columns reach the schema builder. Delegates the
     * union to the shared `mergeDeclaredWithSampledFields` helper (never-shrink by field name); the
     * connector supplies no merge logic of its own.
     */
    public override async IntrospectSchema(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<SourceSchemaInfo> {
        const info = await super.IntrospectSchema(companyIntegration, contextUser);
        await Promise.all(info.Objects.map(async (obj) => {
            try {
                const discovered = await this.DiscoverFields(companyIntegration, obj.ExternalName, contextUser);
                obj.Fields = mergeDeclaredWithSampledFields(obj.Fields, discovered);
            } catch (err) {
                this.WarnOnce(
                    `introspect:${obj.ExternalName}`,
                    `[elevate] Runtime field discovery for "${obj.ExternalName}" failed (${this.SafeMessage(err)}); ` +
                    `the DECLARED field floor still stands. Nothing was removed — absence proves nothing on a ` +
                    `source with no describe endpoint.`,
                );
            }
        }));
        return info;
    }

    // ── Connection test ───────────────────────────────────────────────────────

    /**
     * Runs the cheapest real read the door supports: a minimal single-column query against the first
     * declared resource. A 200 with the documented envelope proves the site URL, the api_key and the
     * door are all good together. The message never carries credential bytes.
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
                        '[elevate] No ACTIVE IntegrationObjects are seeded for this integration, so there is no ' +
                        'resource to probe. Push metadata/integrations/elevate before testing the connection.',
                };
            }
            const probed = objects[0].Name;
            const accepted = await this.ValidateResource(companyIntegration, contextUser, probed);
            if (!accepted) {
                return {
                    Success: false,
                    Message: `[elevate] The Report API door rejected a minimal query for resource "${probed}". ` +
                        'Check the site URL and the API key issued for this site.',
                };
            }
            return {
                Success: true,
                Message: `[elevate] Report API reachable at the configured site; resource "${probed}" answered a ` +
                    'minimal query.',
            };
        } catch (err) {
            return { Success: false, Message: `[elevate] Connection test failed: ${this.SafeMessage(err)}` };
        }
    }

    // ── The READ path — POST envelope to ONE door, date-windowed ──────────────

    /**
     * OVERRIDDEN because Elevate's reads are a POST-with-a-JSON-envelope to a SINGLE endpoint with the
     * object chosen by a body field — the base class's generic per-operation GET-list CRUD would 404/405
     * on every object. Everything that varies per object (door path, `resource` wire value, response
     * keys, watermark field, window field) is routed FROM METADATA; nothing is a string guess in code.
     */
    public override async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
        const companyIntegration = ctx.CompanyIntegration;
        const obj = this.GetCachedObject(companyIntegration.IntegrationID, ctx.ObjectName);
        const iofs = this.GetCachedFields(obj.ID);
        const auth = await this.Authenticate(companyIntegration, ctx.ContextUser);
        const route = this.ReadRouteFor(obj);
        const columns = this.ReadColumnsFor(iofs);
        const warnings: FetchWarning[] = [];

        const windowField = this.WindowFieldFor(obj);
        const plan = this.BuildWindowPlan(companyIntegration, ctx, windowField);
        // Chunk a BULK pull; keep a short delta as ONE precise `>=` query. Day-granularity windows
        // deliberately re-read the whole boundary day, which is safe but wasteful for a five-minute
        // delta — so a range that fits in a single chunk stays on the exact operator filter unless the
        // operator explicitly asked for a bounded window.
        const resuming = ctx.AfterKeyValue != null && String(ctx.AfterKeyValue).length > 0;
        const windows = plan.length > 1
            || (plan.length >= 1 && (resuming || this.HasExplicitWindowConfig(companyIntegration)))
            ? plan
            : [];
        const batchLimit = ctx.BatchSize && ctx.BatchSize > 0 ? ctx.BatchSize : Number.MAX_SAFE_INTEGER;

        // Prove any newly-learned per-tenant column BEFORE the data reads, scoped by the same filter the
        // first read will use. Nothing new to prove ⇒ no request. This is what keeps an unrecognised label
        // name off the data path entirely: Elevate's allow-list is all-or-nothing, so a speculative name in
        // a data read puts every row of the object behind a guess.
        const firstFilters = windows.length === 0
            ? this.WatermarkFilter(obj, ctx)
            : { [windowField as string]: { date: [windows[0].From, windows[0].To] } };
        await this.VerifyLearnedFields(auth, companyIntegration, obj, route, columns, firstFilters, warnings);

        const rows: Record<string, unknown>[] = [];
        let nextWindowStart: string | undefined;

        if (windows.length === 0) {
            // No declared date field, no lower bound to chunk from, or a delta that fits one chunk: ONE
            // query, and the completeness tripwire inside RunReportQuery is what proves it actually
            // returned everything.
            const filters = this.WatermarkFilter(obj, ctx);
            rows.push(...await this.RunReportQuery(auth, companyIntegration, obj, route, columns, filters, warnings, ctx));
        } else {
            for (let i = 0; i < windows.length; i++) {
                if (rows.length >= batchLimit) {
                    nextWindowStart = windows[i].From;
                    break;
                }
                rows.push(...await this.RunWindow(
                    auth, companyIntegration, obj, route, columns, windowField!, windows[i], warnings, ctx, 0,
                ));
            }
        }

        const pkNames = this.PrimaryKeyNames(iofs);
        const records = rows.map(raw => this.ToElevateRecord(
            this.applyTransformPreservingKeys(raw, obj, iofs), ctx.ObjectName, pkNames, columns, obj,
        ));

        const result: FetchBatchResult = {
            Records: records,
            HasMore: nextWindowStart != null,
            Warnings: warnings.length > 0 ? warnings : undefined,
        };
        if (nextWindowStart != null) result.NextAfterKeyValue = nextWindowStart;

        // Max-SEEN watermark, and only on a batch that completed without throwing: a mid-iteration
        // failure propagates out of this method, so the watermark is never advanced over a partial read.
        const watermark = this.MaxWatermark(obj, rows);
        if (watermark != null) result.NewWatermarkValue = watermark;
        return result;
    }

    // ── REST transport primitives ─────────────────────────────────────────────

    /**
     * Resolves the per-connection credential. Elevate's api_key is a single static per-client string
     * with no authorize/token endpoint, no scopes and no documented expiry, so there is nothing to
     * refresh and the resolved context is cached per CompanyIntegration. The credential is read through
     * the standard `MJ: Credentials` record when the connection carries one, with the connection's own
     * `Configuration` JSON as the fallback — no inline crypto anywhere.
     */
    protected override async Authenticate(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<ElevateAuthContext> {
        const cached = this.authCache.get(companyIntegration.ID);
        if (cached) return cached;

        const creds = await this.LoadCredentials(companyIntegration, contextUser);
        const siteUrl = this.NormalizeSiteUrl(creds.SiteUrl);
        if (!siteUrl) {
            throw new Error(
                '[elevate] No Elevate site URL configured. Elevate is deployed PER CLIENT — there is no shared ' +
                'vendor API host — so the connection must supply "siteUrl" (the client\'s own Elevate site root) ' +
                'on its credential or Configuration JSON.',
            );
        }
        if (!/^https?:\/\//i.test(siteUrl)) {
            throw new Error(`[elevate] Configured siteUrl "${siteUrl}" is not an absolute http(s) URL.`);
        }
        const apiKey = (creds.ApiKey ?? '').trim();
        if (!apiKey) {
            throw new Error(
                '[elevate] No API key configured. Elevate carries its credential as an `api_key` field in the ' +
                'BODY of every Report/Registration API request, so no call can be made without it. Supply ' +
                '"apiKey" on the connection credential (issued out-of-band by the client\'s Project Manager).',
            );
        }

        const ctx: ElevateAuthContext = {
            SiteUrl: siteUrl,
            ApiKey: apiKey,
            IntegrationID: companyIntegration.IntegrationID,
        };
        this.authCache.set(companyIntegration.ID, ctx);
        return ctx;
    }

    /**
     * Transport headers ONLY. Elevate's credential does NOT travel in a header or a query string on any
     * of its three POST operations — `Configuration.AuthHeaderPattern` is deliberately null and
     * `AuthCredentialParamLocation` is 'body'. Reaching for the generic Bearer/Basic header path for
     * this vendor is wrong, and no credential byte is ever placed here.
     */
    protected override BuildHeaders(_auth: RESTAuthContext): Record<string, string> {
        return { 'Content-Type': 'application/json', 'Accept': 'application/json' };
    }

    /**
     * The single wire choke point. It owns four vendor-specific concerns:
     *   1. Injecting `api_key` into the request BODY (never a header, never a query param, never logged).
     *   2. Treating a VENDOR ERROR ENVELOPE as a failure even on a 2xx — the read door has been observed
     *      answering `{ error: { message } }` and the write endpoints document `{ error_messages: {...} }`
     *      with no status code shown, so a body-blind success check would sync zero rows silently.
     *   3. Honouring 429 (and 503 carrying `Retry-After`) with bounded adaptive backoff.
     *   4. NEVER retrying a 500 — this door returns 500 for CLIENT errors (wrong resource name,
     *      non-existent field), and blind-retrying burns the unquantified rate-limit budget replaying a
     *      request that can never succeed.
     */
    protected override async MakeHTTPRequest(
        auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown,
    ): Promise<RESTResponse> {
        const ctx = auth as ElevateAuthContext;
        const payload = this.WithCredential(ctx, body);

        let attempt = 0;
        for (;;) {
            const response = await this.rawRequest(url, method, headers, payload);
            const classification = this.ClassifyElevateResponse(response.Status, response.Body);
            if (!classification.IsError) return response;

            const retryable = classification.Retryable && attempt < MAX_THROTTLE_RETRIES;
            if (!retryable) {
                throw new ElevateAPIError(
                    `[elevate] HTTP ${response.Status} (${classification.Reason}) from ${this.PathOf(url)}` +
                    `${classification.UnknownField ? ` — unknown field "${classification.UnknownField}"` : ''}` +
                    `: ${this.Redact(ctx, this.VendorMessage(response.Body) ?? 'no vendor message')}`,
                    response.Status,
                    response.Headers,
                    classification,
                );
            }
            attempt++;
            const probe = new ElevateAPIError('throttled', response.Status, response.Headers, classification);
            await this.Sleep(this.ExtractRetryAfterMs(probe) ?? Math.min(MAX_RETRY_AFTER_MS, 1_000 * 2 ** attempt));
        }
    }

    /**
     * Strips the Report API envelope. The shape was OBSERVED by the RealityProbe (key names only):
     * `{ response: { labels: {...}, items: [...], count: N } }`, so the rows are the array at the
     * metadata-declared `ResponseDataKey` = `response.items`. A dotted key is walked, never split on the
     * first segment only — declaring `response.items` and reading `response` would return zero rows.
     */
    protected override NormalizeResponse(rawBody: unknown, responseDataKey: string | null): Record<string, unknown>[] {
        const target = responseDataKey ? this.ReadPath(rawBody, responseDataKey.split('.')) : rawBody;
        if (!Array.isArray(target)) return [];
        return target.filter((r): r is Record<string, unknown> => r != null && typeof r === 'object' && !Array.isArray(r));
    }

    /**
     * ALWAYS `HasMore: false`. Pagination was PROBED AND DECIDED NEGATIVE at volume: 29,003 unfiltered
     * rows equalled the sum of 15 all-HTTP-200 yearly windows, and none of limit/offset/page/per_page/
     * page_size changed the row count. There is no scheme to extract, and inventing one would silently
     * truncate. Bulk beyond the probed ceiling is bounded by DATE WINDOWS in `FetchChanges`, not pages.
     */
    protected override ExtractPaginationInfo(
        _rawBody: unknown,
        _paginationType: PaginationType,
        _currentPage: number,
        _currentOffset: number,
        _pageSize: number,
    ): PaginationState {
        return { HasMore: false };
    }

    /** The connection's OWN Elevate site root. There is no vendor host and no fallback default. */
    protected override GetBaseURL(_companyIntegration: MJCompanyIntegrationEntity, auth: RESTAuthContext): string {
        return (auth as ElevateAuthContext).SiteUrl;
    }

    /**
     * Projects each declared dot-path column onto its flat MJ column name (`product.title` lands at
     * `raw.product.title`, the IOF is named `product_title`) while PRESERVING the complete source row:
     * the spread keeps every key the door returned so the framework's custom-column capture can still
     * see a per-tenant column this build never declared.
     */
    protected override TransformRecord(
        raw: Record<string, unknown>,
        _obj: MJIntegrationObjectEntity,
        fields: MJIntegrationObjectFieldEntity[],
    ): Record<string, unknown> {
        const columns = this.ReadColumnsFor(fields).filter(c => c.ResponsePath.length > 1);
        if (columns.length === 0) return raw;
        const projected: Record<string, unknown> = { ...raw };
        for (const col of columns) {
            if (col.Name in projected) continue;
            const value = this.ReadPath(raw, col.ResponsePath);
            if (value !== undefined) projected[col.Name] = value;
        }
        return projected;
    }

    // ── Write surface (generic slots, one idiosyncratic verb) ─────────────────

    // `CreateRecord` is DELIBERATELY NOT overridden. It stays on the base class's generic
    // per-operation path, which reads `CreateAPIPath` (`/api/registrations`), `CreateMethod` (`POST`),
    // `CreateBodyShape` (`flat`) and `CreateIDLocation` (`body.registration_id`) straight off the
    // IntegrationObject row. The vendor treats the call as an UPSERT keyed on `remote_user_id` (the SSO
    // identity), so a repeat for the same learner/product does not mint a duplicate person. The only
    // vendor-specific part — reading `registration_id` (and `product_url`) out of a DOTTED body
    // location — rides the `ExtractIDFromResponse` hook below, not a re-implemented CreateRecord.

    /**
     * Reads the created record's id from a DOTTED body location. The base helper understands only
     * `body` / `header`; Elevate declares `body.registration_id`, and `registration_id` is the ONLY
     * handle the Cancellation API accepts, so losing it here would make every cancel impossible.
     * `product_url` from the same body is stashed on {@link LastCreatedProductURLs}.
     */
    protected override ExtractIDFromResponse(response: RESTResponse, idLocation: string | null): string | undefined {
        if (idLocation && idLocation.startsWith('body.')) {
            const value = this.ReadPath(response.Body, idLocation.slice('body.'.length).split('.'));
            const id = value == null ? undefined : String(value);
            if (id != null) {
                const productURL = this.ReadPath(response.Body, ['product_url']);
                if (typeof productURL === 'string' && productURL.length > 0) {
                    if (this.LastCreatedProductURLs.size >= MAX_TRACKED_PRODUCT_URLS) {
                        const oldest = this.LastCreatedProductURLs.keys().next();
                        if (!oldest.done) this.LastCreatedProductURLs.delete(oldest.value);
                    }
                    this.LastCreatedProductURLs.set(id, productURL);
                }
            }
            return id;
        }
        return super.ExtractIDFromResponse(response, idLocation);
    }

    /** Reads the vendor's message out of either observed envelope: `{error:{message}}` / `{error_messages:{}}`. */
    protected override ExtractErrorMessage(response: RESTResponse): string | undefined {
        return this.VendorMessage(response.Body) ?? super.ExtractErrorMessage(response);
    }

    /**
     * ALWAYS fails, explicitly. No update endpoint is documented for ANY Elevate resource, so there is
     * nothing to call: no IO carries `UpdateAPIPath`. This method exists so the failure is a classified,
     * visible NOT-SUPPORTED rather than a silent no-op — and it must never degrade into a create, which
     * would mint a second registration for the same learner.
     */
    public override async UpdateRecord(ctx: UpdateRecordContext): Promise<CRUDResult> {
        const message =
            `[elevate] UPDATE_NOT_SUPPORTED (CONFIGURATION_ERROR): the Elevate API exposes no update ` +
            `endpoint for "${ctx.ObjectName}" (or for any other resource) — only registration create and ` +
            `registration cancel exist. Refusing to fall back to a create, which would mint a duplicate ` +
            `registration. External ID "${ctx.ExternalID}" was left untouched.`;
        return { Success: false, StatusCode: 501, ErrorMessage: message };
    }

    /**
     * OVERRIDDEN for one reason: the id location. Elevate's cancel is a POST whose `registration_id`
     * travels in the BODY (`DeleteIDLocation` = `body.registration_id`), and the base class's generic
     * delete sends NO body at all for a non-path id location — the call would arrive without the id and
     * cancel nothing. Everything else is still read from metadata: the verb comes from `DeleteMethod`
     * (POST, never assumed DELETE) and the path is used EXACTLY as declared — `/registrations/cancel`
     * genuinely has no `/api/` prefix, and "fixing" it would 404.
     */
    public override async DeleteRecord(ctx: DeleteRecordContext): Promise<CRUDResult> {
        const companyIntegration = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const contextUser = ctx.ContextUser as UserInfo;
        const obj = this.GetCachedObject(companyIntegration.IntegrationID, ctx.ObjectName);
        if (!obj.DeleteAPIPath || !obj.DeleteMethod) {
            return {
                Success: false,
                StatusCode: 501,
                ErrorMessage:
                    `[elevate] DELETE_NOT_SUPPORTED (CONFIGURATION_ERROR): "${ctx.ObjectName}" declares no ` +
                    `DeleteAPIPath/DeleteMethod. Elevate's only delete-shaped operation is the registration cancel.`,
            };
        }
        const idLocation = obj.DeleteIDLocation ?? 'body';
        if (!idLocation.startsWith('body')) {
            return {
                Success: false,
                StatusCode: 501,
                ErrorMessage:
                    `[elevate] DELETE_NOT_SUPPORTED (CONFIGURATION_ERROR): DeleteIDLocation "${idLocation}" is not a ` +
                    `body location; Elevate's cancel carries its id in the request body.`,
            };
        }
        if (!idLocation.includes('.')) {
            return {
                Success: false,
                StatusCode: 501,
                ErrorMessage:
                    `[elevate] DELETE_NOT_SUPPORTED (CONFIGURATION_ERROR): DeleteIDLocation is "${idLocation}" but does ` +
                    `not NAME the body key the cancel endpoint expects (metadata declares "body.registration_id"). ` +
                    `Refusing to guess a field name — a POST with the wrong key cancels nothing and still returns 200.`,
            };
        }
        const idKey = idLocation.slice(idLocation.indexOf('.') + 1);

        const auth = await this.Authenticate(companyIntegration, contextUser);
        const url = this.JoinURL(this.GetBaseURL(companyIntegration, auth), obj.DeleteAPIPath);
        const body: Record<string, unknown> = {};
        body[idKey] = ctx.ExternalID;

        const response = await this.MakeHTTPRequest(auth, url, obj.DeleteMethod, this.BuildHeaders(auth), body);
        if (response.Status >= 200 && response.Status < 300) {
            return { Success: true, StatusCode: response.Status, ExternalID: ctx.ExternalID };
        }
        return {
            Success: false,
            StatusCode: response.Status,
            ErrorMessage: this.ExtractErrorMessage(response) ?? `HTTP ${response.Status} on cancel`,
        };
    }

    // ── Error classification ──────────────────────────────────────────────────

    /**
     * Classifies from the observed error ENVELOPE, not the status alone. Two shapes exist and they are
     * NOT shared between surfaces (`Configuration.ErrorResponseShape.surfaceSplit`): the read door
     * answers `{ error: { message } }` (observed at HTTP 500) and the write endpoints document
     * `{ error_messages: { field: message } }` with NO status code ever shown. A 2xx carrying either is
     * a FAILURE — treating it as a successful empty read is exactly how a sync reports zero rows and
     * green at the same time.
     */
    public ClassifyElevateResponse(status: number, body: unknown): ElevateErrorClassification {
        const vendorMessage = this.VendorMessage(body);
        const unknownField = this.UnknownFieldFrom(vendorMessage);

        if (status === 429) {
            return { IsError: true, Code: 'RATE_LIMIT_EXCEEDED', Severity: 'Warning', Retryable: true, Reason: 'throttled', UnknownField: null };
        }
        if (status === 503) {
            return { IsError: true, Code: 'NETWORK_TIMEOUT', Severity: 'Warning', Retryable: true, Reason: 'service-unavailable', UnknownField: null };
        }
        if (unknownField != null) {
            return {
                IsError: true, Code: 'CONFIGURATION_ERROR', Severity: 'Critical', Retryable: false,
                Reason: 'unknown-field-in-allow-list', UnknownField: unknownField,
            };
        }
        if (vendorMessage != null && /wrong resource name/i.test(vendorMessage)) {
            return {
                IsError: true, Code: 'CONFIGURATION_ERROR', Severity: 'Critical', Retryable: false,
                Reason: 'unknown-resource', UnknownField: null,
            };
        }
        if (vendorMessage != null) {
            // A vendor error envelope on ANY status, 2xx included. NEVER retryable: this door answers
            // HTTP 500 for client-side mistakes, so a retry can only burn the rate-limit budget.
            const classified = ClassifyError(new Error(vendorMessage));
            return {
                IsError: true,
                Code: classified.Code === 'UNKNOWN_ERROR' ? 'CONNECTOR_ERROR' : classified.Code,
                Severity: classified.Severity, Retryable: false,
                Reason: status >= 200 && status < 300 ? 'vendor-error-in-2xx' : 'vendor-error-envelope',
                UnknownField: null,
            };
        }
        if (status < 200 || status >= 300) {
            return {
                IsError: true, Code: status === 401 || status === 403 ? 'CONFIGURATION_ERROR' : 'CONNECTOR_ERROR',
                Severity: 'Critical', Retryable: false, Reason: `http-${status}`, UnknownField: null,
            };
        }
        return { IsError: false, Code: 'UNKNOWN_ERROR', Severity: 'Info', Retryable: false, Reason: 'ok', UnknownField: null };
    }

    // ── Transport seam (test subclasses override THIS, not MakeHTTPRequest) ───

    /** The raw HTTP call. Isolated so a mocked subclass can capture the wire without losing the behaviour above. */
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

    // ── Metadata accessors (seams; test subclasses override these) ────────────

    /** All ACTIVE IntegrationObjects for this integration; `[]` when the engine cache is unavailable. */
    protected getCachedObjects(integrationID: string): MJIntegrationObjectEntity[] {
        try {
            return IntegrationEngineBase.Instance.GetActiveIntegrationObjects(integrationID);
        } catch {
            return [];
        }
    }

    /** The IntegrationID for this integration, or null when the engine cache is unavailable. */
    protected tryGetIntegrationID(): string | null {
        try {
            return IntegrationEngineBase.Instance.GetIntegrationByName(this.IntegrationName)?.ID ?? null;
        } catch {
            return null;
        }
    }

    // ── Read-path internals ───────────────────────────────────────────────────

    /**
     * Runs ONE report query and returns its rows. Two safety behaviours ride here because both are
     * per-query facts, not per-object ones:
     *   • THE COMPLETENESS TRIPWIRE — `response.count` is the door's own total for the query; when it
     *     exceeds `response.items.length` the read was silently truncated, which is the only protection
     *     that survives above the 29,003 rows the probe actually measured.
     *   • THE ALLOW-LIST REPAIR — a SAFETY NET for DECLARED columns (a wrong `wireSelector` in metadata):
     *     the door rejects the WHOLE query for one unrecognised column and names the offender, so that name
     *     is dropped, remembered and the query retried. Runtime-discovered names never rely on it — they
     *     are proven out of band by {@link VerifyLearnedFields} before they may enter a data read — and the
     *     repair refuses to act when the named column was not in the request it just sent, because dropping
     *     it changes nothing and the retry would replay an identical, already-failed call.
     */
    private async RunReportQuery(
        auth: ElevateAuthContext,
        companyIntegration: MJCompanyIntegrationEntity,
        obj: MJIntegrationObjectEntity,
        route: ElevateReadRoute,
        columns: ElevateReadColumn[],
        filters: Record<string, unknown> | null,
        warnings: FetchWarning[],
        ctx?: FetchContext,
    ): Promise<Record<string, unknown>[]> {
        const key = this.CacheKey(companyIntegration, obj.Name);
        const url = this.JoinURL(this.GetBaseURL(companyIntegration, auth), route.Door);
        const headers = this.BuildHeaders(auth);

        for (let repair = 0; repair <= MAX_SELECTOR_REPAIRS; repair++) {
            const selectors = this.SelectorsFor(companyIntegration, obj, columns, ctx);
            if (selectors.length === 0) {
                throw new Error(
                    `[elevate] No read-surface columns are declared for "${obj.Name}", so no \`fields\` allow-list ` +
                    'can be built. Elevate returns ONLY the columns a request names, so a fieldless query is useless.',
                );
            }
            const body = this.BuildEnvelope(companyIntegration, route.Resource, selectors, filters);
            try {
                const response = await this.MakeHTTPRequest(auth, url, 'POST', headers, body);
                const rows = this.NormalizeResponse(response.Body, route.DataKey);
                this.LearnLabels(key, response.Body, route, rows);
                this.CheckCompleteness(obj, response.Body, route, rows.length, filters, warnings);
                return rows;
            } catch (err) {
                // A catch binding is `unknown` under a `strict` tsconfig (the Open App package compiles with
                // `useUnknownInCatchVariables`), so narrow ONCE, here, on the only error shape this repair
                // can act on. Anything else — a transport failure, an abort — is rethrown untouched, which is
                // exactly what the previous `instanceof ? ... : null` expression did; this form just gives the
                // rest of the handler a typed `err` instead of a cast at every use.
                if (!(err instanceof ElevateAPIError)) throw err;
                const rejected = err.Classification.UnknownField;
                if (rejected == null || repair === MAX_SELECTOR_REPAIRS) throw err;
                if (!selectors.some(s => s.toLowerCase() === rejected.toLowerCase())) {
                    // The door named a column this request did NOT ask for. The all-or-nothing repair has
                    // nothing to act on: dropping the name changes no byte of the envelope, so retrying can
                    // only replay an identical, already-failed request against a rate-limited door until the
                    // repair budget runs out — and the eventual error still points at the field selector,
                    // which is NOT where the fault is. Fail immediately, and say which request was actually
                    // sent so the next reader looks at the routing rather than the columns.
                    throw new ElevateAPIError(
                        `${err.message} — but "${rejected}" was NOT in this request's \`fields\` allow-list ` +
                        `(sent: ${selectors.slice(0, 12).join(', ')}${selectors.length > 12 ? ', …' : ''}), so the ` +
                        'all-or-nothing repair cannot act on it. The rejection does not describe the request ' +
                        `that was sent for "${obj.Name}" — check the door/resource routing, not the selector.`,
                        err.Status,
                        err.Headers,
                        err.Classification,
                    );
                }
                this.RememberRejected(key, rejected);
                this.WarnOnce(
                    `rejected-field:${key}:${rejected}`,
                    `[elevate] The door rejected column "${rejected}" on "${obj.Name}" and Elevate's \`fields\` ` +
                    'allow-list is ALL-OR-NOTHING, so the whole query failed. Dropping that column for this ' +
                    'connection and retrying. If it is a DECLARED column, the metadata wire selector is wrong.',
                );
                warnings.push({
                    Code: 'FIELD_REJECTED',
                    Message: `Elevate rejected column "${rejected}" on "${obj.Name}"; it was dropped from the read selector.`,
                    Data: { objectName: obj.Name, field: rejected },
                });
            }
        }
        throw new Error(`[elevate] Field-selector repair for "${obj.Name}" did not converge.`);
    }

    /**
     * Runs one date window, halving it when the door reports truncation. That is the ADAPTIVE sizing the
     * probe's evidence calls for: it does not assume a chunk size is small enough, it verifies each chunk
     * against the door's own count and splits until every chunk is provably complete.
     */
    private async RunWindow(
        auth: ElevateAuthContext,
        companyIntegration: MJCompanyIntegrationEntity,
        obj: MJIntegrationObjectEntity,
        route: ElevateReadRoute,
        columns: ElevateReadColumn[],
        windowField: string,
        window: ElevateWindow,
        warnings: FetchWarning[],
        ctx: FetchContext,
        depth: number,
    ): Promise<Record<string, unknown>[]> {
        const before = warnings.length;
        const filters: Record<string, unknown> = {};
        filters[windowField] = { date: [window.From, window.To] };
        const rows = await this.RunReportQuery(auth, companyIntegration, obj, route, columns, filters, warnings, ctx);

        const truncated = warnings.slice(before).some(w => w.Code === 'INCOMPLETE_READ');
        if (!truncated || depth >= MAX_WINDOW_SPLIT_DEPTH) return rows;

        const halves = this.SplitWindow(window);
        if (halves == null) return rows;   // one-day window: nothing left to split — the warning stands.

        warnings.length = before;          // the parent window is superseded by its halves.
        const out: Record<string, unknown>[] = [];
        for (const half of halves) {
            out.push(...await this.RunWindow(
                auth, companyIntegration, obj, route, columns, windowField, half, warnings, ctx, depth + 1,
            ));
        }
        return out;
    }

    /**
     * Builds the request envelope. Key order is deliberate and stable — `resource` sits next to
     * `format` so a captured request is self-describing. `api_key` is NOT added here; it is injected at
     * the transport choke point so no caller can accidentally log or persist an envelope carrying it.
     */
    private BuildEnvelope(
        companyIntegration: MJCompanyIntegrationEntity,
        resource: string,
        selectors: string[],
        filters: Record<string, unknown> | null,
    ): Record<string, unknown> {
        const fields: Record<string, boolean> = {};
        for (const s of selectors) fields[s] = true;
        const envelope: Record<string, unknown> = {
            format: this.ResolveFormat(companyIntegration, selectors),
            resource,
            fields,
        };
        if (filters != null && Object.keys(filters).length > 0) envelope.filters = filters;
        return envelope;
    }

    /**
     * json unless the connection explicitly asks for csv AND every selector is flat. The vendor is
     * explicit that CSV "is limited to only the values in the top-most layer of the API response", so a
     * dot-path selection silently loses its columns in csv — the request is forced back to json and the
     * downgrade is announced rather than quietly honoured.
     */
    private ResolveFormat(companyIntegration: MJCompanyIntegrationEntity, selectors: string[]): string {
        const requested = this.ConfigString(companyIntegration, ['elevateFormat', 'format']);
        if (requested?.toLowerCase() !== 'csv') return 'json';
        const nested = selectors.filter(s => s.includes('.'));
        if (nested.length === 0) return 'csv';
        this.WarnOnce(
            'csv-refused',
            `[elevate] This connection asked for format=csv, but the read selector contains dot-path ` +
            `sub-resource columns (${nested.slice(0, 3).join(', ')}${nested.length > 3 ? ', …' : ''}). CSV is flat ` +
            'and would silently drop every column below the top layer, so the request is being sent as json.',
        );
        return 'json';
    }

    /**
     * The `fields` allow-list for one DATA read: the DECLARED read-surface wire selectors UNIONED with the
     * per-tenant column names this connection's door has PROVEN it accepts (see {@link VerifyLearnedFields}),
     * minus anything the door has already rejected. A build-time-only list would truncate every record to
     * what this build thought to ask for; the union is what makes a site's configured custom/profile
     * columns reachable.
     *
     * The union is over VERIFIED names, never over freshly-learned ones. Elevate's allow-list is
     * ALL-OR-NOTHING — one unrecognised name fails the WHOLE query — so folding an unproven label name
     * into a data read makes every row of that object hostage to a guess: the read has to fail at least
     * once, and it zeroes the object outright if the door's message does not NAME the offender (the
     * repair below can only act on a named column). Unproven names are therefore proven OUT OF BAND
     * first; a rejection there costs one probe and never a row.
     * `FetchContext.RequestedSourceFields`, when the engine supplies it, narrows the union to the columns
     * actually mapped.
     */
    private SelectorsFor(
        companyIntegration: MJCompanyIntegrationEntity,
        obj: MJIntegrationObjectEntity,
        columns: ElevateReadColumn[],
        ctx?: FetchContext,
    ): string[] {
        const key = this.CacheKey(companyIntegration, obj.Name);
        const rejected = this.rejectedFieldNames.get(key) ?? new Set<string>();
        const wanted = ctx?.RequestedSourceFields && ctx.RequestedSourceFields.length > 0
            ? new Set(ctx.RequestedSourceFields.map(f => f.toLowerCase()))
            : null;

        const out = new Set<string>();
        for (const col of columns) {
            if (rejected.has(col.WireSelector)) continue;
            if (wanted && !wanted.has(col.Name.toLowerCase()) && !wanted.has(col.WireSelector.toLowerCase())) continue;
            out.add(col.WireSelector);
        }
        const declaredSelectors = new Set(columns.map(c => c.WireSelector));
        const declaredNames = new Set(columns.map(c => c.Name.toLowerCase()));
        for (const name of this.SortedNames(this.verifiedFieldNames.get(key))) {
            if (rejected.has(name) || declaredSelectors.has(name) || declaredNames.has(name.toLowerCase())) continue;
            if (wanted && !wanted.has(name.toLowerCase())) continue;
            out.add(name);
        }
        return [...out];
    }

    /**
     * Proves — OUT OF BAND, before any data read — which of the names runtime discovery has learned for
     * this connection+object the door will actually accept in a `fields` allow-list. This is the whole
     * reason a learned label can no longer zero an object's sync:
     *
     *   • the DATA read only ever asks for DECLARED columns ∪ names proven here, so an unrecognised
     *     label can never fail it — named in the door's message or not;
     *   • a rejection costs exactly this probe (never a row), the offending name is remembered as
     *     rejected for the connection and is never asked for again;
     *   • a probe that fails for ANY OTHER reason leaves the names UNVERIFIED rather than rejected —
     *     absence of proof is not proof of absence, and the next sync re-attempts them.
     *
     * Zero-cost when there is nothing new to prove (the overwhelmingly common case): with no unproven
     * name the method makes no request at all. The probe is scoped by the SAME filter the imminent read
     * uses, so proving a column on a watermarked object does not drag the whole resource across the wire.
     */
    private async VerifyLearnedFields(
        auth: ElevateAuthContext,
        companyIntegration: MJCompanyIntegrationEntity,
        obj: MJIntegrationObjectEntity,
        route: ElevateReadRoute,
        columns: ElevateReadColumn[],
        filters: Record<string, unknown> | null,
        warnings: FetchWarning[],
    ): Promise<void> {
        const key = this.CacheKey(companyIntegration, obj.Name);
        let candidates = this.PendingLearnedFields(key, columns);
        if (candidates.length === 0) return;

        const url = this.JoinURL(this.GetBaseURL(companyIntegration, auth), route.Door);
        const headers = this.BuildHeaders(auth);

        for (let repair = 0; repair <= MAX_SELECTOR_REPAIRS && candidates.length > 0; repair++) {
            const body = this.BuildEnvelope(companyIntegration, route.Resource, candidates, filters);
            try {
                const response = await this.MakeHTTPRequest(auth, url, 'POST', headers, body);
                this.LearnLabels(key, response.Body, route, this.NormalizeResponse(response.Body, route.DataKey));
                this.MarkVerified(key, candidates);
                return;
            } catch (err) {
                const named = err instanceof ElevateAPIError ? err.Classification.UnknownField : null;
                if (named == null || !candidates.some(c => c.toLowerCase() === named.toLowerCase())) {
                    this.WarnOnce(
                        `verify-failed:${key}`,
                        `[elevate] Could not prove runtime-discovered column(s) ${candidates.join(', ')} on ` +
                        `"${obj.Name}" (${this.SafeMessage(err)}). They stay UNVERIFIED — not rejected — and are ` +
                        'left OUT of the read selector for now, so the object still syncs on its declared ' +
                        'columns. The next sync re-attempts them.',
                    );
                    return;
                }
                this.RememberRejected(key, named);
                this.WarnOnce(
                    `rejected-field:${key}:${named}`,
                    `[elevate] The door rejected runtime-discovered column "${named}" on "${obj.Name}". It was ` +
                    'refused during OUT-OF-BAND verification, so no data read ever carried it and no row was ' +
                    'lost. It will not be asked for again on this connection.',
                );
                warnings.push({
                    Code: 'FIELD_REJECTED',
                    Message: `Elevate rejected runtime-discovered column "${named}" on "${obj.Name}"; it was dropped before any data read.`,
                    Data: { objectName: obj.Name, field: named, phase: 'verification' },
                });
                candidates = candidates.filter(c => c.toLowerCase() !== named.toLowerCase());
            }
        }
    }

    /** Learned names not yet proven, not already rejected, and not already covered by a declared column. */
    private PendingLearnedFields(key: string, columns: ElevateReadColumn[]): string[] {
        const learned = this.discoveredFieldNames.get(key);
        if (!learned || learned.size === 0) return [];
        const rejected = this.rejectedFieldNames.get(key) ?? new Set<string>();
        const verified = this.verifiedFieldNames.get(key) ?? new Set<string>();
        const declaredSelectors = new Set(columns.map(c => c.WireSelector));
        const declaredNames = new Set(columns.map(c => c.Name.toLowerCase()));
        return this.SortedNames(learned).filter(name =>
            !rejected.has(name)
            && !verified.has(name)
            && !declaredSelectors.has(name)
            && !declaredNames.has(name.toLowerCase()));
    }

    /** Records the learned names this connection's door answered a read for. */
    private MarkVerified(key: string, names: string[]): void {
        const set = this.verifiedFieldNames.get(key) ?? new Set<string>();
        for (const name of names) set.add(name);
        this.verifiedFieldNames.set(key, set);
    }

    /**
     * Records the per-resource field dictionary the door returns on EVERY call (`response.labels`) as
     * runtime-discovered column names for this connection, plus one sampled value each for type
     * inference. This is discovery from a real runtime surface, not a build-time sample: nothing here is
     * written back to the declared metadata.
     */
    private LearnLabels(
        key: string,
        rawBody: unknown,
        route: ElevateReadRoute,
        rows: Record<string, unknown>[],
    ): void {
        const labels = this.ReadPath(rawBody, route.LabelsKey.split('.'));
        if (labels == null || typeof labels !== 'object' || Array.isArray(labels)) return;
        const known = this.discoveredFieldNames.get(key) ?? new Set<string>();
        const samples = this.discoveredSamples.get(key) ?? new Map<string, unknown>();
        for (const name of Object.keys(labels as Record<string, unknown>)) {
            known.add(name);
            if (!samples.has(name)) {
                const observed = rows.find(r => r[name] != null);
                if (observed) samples.set(name, observed[name]);
            }
        }
        this.discoveredFieldNames.set(key, known);
        this.discoveredSamples.set(key, samples);
    }

    /** Remembers a column this connection's door refused, so it is never requested for that object again. */
    private RememberRejected(key: string, field: string): void {
        const set = this.rejectedFieldNames.get(key) ?? new Set<string>();
        set.add(field);
        this.rejectedFieldNames.set(key, set);
    }

    /**
     * The silent-truncation tripwire. `response.count` is the door's OWN total for the query; when it
     * disagrees with the number of rows actually returned, the read was capped. Raised as a FetchWarning
     * so the engine surfaces it in the structured run artifact instead of it being a swallowed console line.
     */
    private CheckCompleteness(
        obj: MJIntegrationObjectEntity,
        rawBody: unknown,
        route: ElevateReadRoute,
        returned: number,
        filters: Record<string, unknown> | null,
        warnings: FetchWarning[],
    ): void {
        const reported = this.ReadPath(rawBody, route.CountKey.split('.'));
        if (typeof reported !== 'number' || !Number.isFinite(reported)) return;
        if (reported <= returned) return;
        warnings.push({
            Code: 'INCOMPLETE_READ',
            Message:
                `Elevate reported ${reported} row(s) for "${obj.Name}" but returned ${returned}. The door has no ` +
                'pagination control (probed negative), so the query must be narrowed by a date window — set ' +
                '"elevateWindowStart"/"elevateWindowDays" on the connection Configuration if this object has no ' +
                'watermark to chunk from.',
            Data: { objectName: obj.Name, reportedCount: reported, returnedCount: returned, filtered: filters != null },
        });
    }

    // ── Window planning ───────────────────────────────────────────────────────

    /**
     * The date column a bulk pull is chunked on — strictly the object's DECLARED
     * `IncrementalWatermarkField`, and nothing else. For productRegistration that is `modified_at`: the
     * probe-proven UPDATE watermark, deliberately not `transaction_at`, which is insert time and cannot
     * see an edit. `null` for every other object, and then NO window is ever synthesised.
     *
     * A date-shaped column is NOT enough to justify a filter here. `EarnedCredit.updated_at` looks like a
     * watermark and the metadata explicitly WITHHOLDS incremental capability for it: filters-envelope
     * reachability for that resource is unproven, so chunking on it would apply an unevidenced filter and
     * would silently drop every row whose column is null. Honour what the probe proved; do not re-derive it.
     */
    private WindowFieldFor(obj: MJIntegrationObjectEntity): string | null {
        return obj.IncrementalWatermarkField ?? null;
    }

    /**
     * Consecutive, NON-OVERLAPPING windows over `[start, end]`. The start is the sync watermark when the
     * engine supplied one (so a delta pass re-reads only what changed), the resume cursor when a prior
     * batch stopped mid-plan, or the connection's declared `elevateWindowStart`. With no lower bound at
     * all the plan is EMPTY and the object is read in one query — verified by the completeness tripwire
     * rather than assumed complete.
     */
    private BuildWindowPlan(
        companyIntegration: MJCompanyIntegrationEntity,
        ctx: FetchContext,
        windowField: string | null,
    ): ElevateWindow[] {
        if (windowField == null) return [];
        const resume = this.ToDayString(ctx.AfterKeyValue ?? null);
        const watermark = this.ToDayString(ctx.WatermarkValue);
        const configured = this.ToDayString(this.ConfigString(companyIntegration, ['elevateWindowStart']));
        const start = resume ?? watermark ?? configured;
        if (start == null) return [];

        const end = this.ToDayString(this.ConfigString(companyIntegration, ['elevateWindowEnd'])) ?? this.Today();
        if (end < start) return [];

        const days = this.ConfigNumber(companyIntegration, ['elevateWindowDays']) ?? DEFAULT_WINDOW_DAYS;
        const span = Number.isFinite(days) && days >= 1 ? Math.floor(days) : DEFAULT_WINDOW_DAYS;

        const windows: ElevateWindow[] = [];
        let cursor = start;
        while (cursor <= end && windows.length < 4_000) {
            const to = this.MinDay(this.AddDays(cursor, span - 1), end);
            windows.push({ From: cursor, To: to });
            cursor = this.AddDays(to, 1);
        }
        return windows;
    }

    /** Halves a window, or null when it is already a single day and cannot be narrowed further. */
    private SplitWindow(window: ElevateWindow): ElevateWindow[] | null {
        const spanDays = this.DayDiff(window.From, window.To);
        if (spanDays < 1) return null;
        const mid = this.AddDays(window.From, Math.floor(spanDays / 2));
        return [{ From: window.From, To: mid }, { From: this.AddDays(mid, 1), To: window.To }];
    }

    /**
     * The delta filter for an UNCHUNKED incremental read. Only ever built from the object's own declared
     * watermark; an object whose metadata declares none runs a FULL SCAN, and no delta path is invented
     * for it.
     */
    private WatermarkFilter(
        obj: MJIntegrationObjectEntity,
        ctx: FetchContext,
    ): Record<string, unknown> | null {
        if (!obj.SupportsIncrementalSync || !obj.IncrementalWatermarkField) return null;
        if (ctx.WatermarkValue == null || ctx.WatermarkValue.length === 0) return null;
        const filters: Record<string, unknown> = {};
        filters[obj.IncrementalWatermarkField] = { '>=': ctx.WatermarkValue };
        return filters;
    }

    /** Whether the connection explicitly asked for a bounded/chunked pull rather than the default. */
    private HasExplicitWindowConfig(companyIntegration: MJCompanyIntegrationEntity): boolean {
        const cfg = this.ParseJSONObject(companyIntegration.Configuration);
        if (!cfg) return false;
        return ['elevateWindowStart', 'elevateWindowEnd', 'elevateWindowDays'].some(k => cfg[k] != null);
    }

    /** Max-SEEN watermark across the batch (never "most recent row"), or null when the object has none. */
    private MaxWatermark(obj: MJIntegrationObjectEntity, rows: Record<string, unknown>[]): string | null {
        if (!obj.SupportsIncrementalSync || !obj.IncrementalWatermarkField) return null;
        const field = obj.IncrementalWatermarkField;
        let max: string | null = null;
        for (const row of rows) {
            const value = row[field];
            if (value == null) continue;
            const asString = value instanceof Date ? value.toISOString() : String(value);
            if (asString.length === 0) continue;
            if (max == null || asString > max) max = asString;
        }
        return max;
    }

    // ── Record assembly ───────────────────────────────────────────────────────

    /**
     * Builds one ExternalRecord. Identity is STABLE ACROSS PASSES by construction:
     *   • when the object's DECLARED primary key is fully populated, the ExternalID is that key;
     *   • otherwise — every Elevate object except Product, whose keys the RealityProbe demoted or
     *     falsified — the identity is a content hash over the DECLARED READ PROJECTION only, never over
     *     the whole raw row. That distinction is the point: hashing the raw row makes identity a
     *     function of any volatile or per-tenant byte the door happens to add, which is the drift class
     *     the two-pass idempotency rung exists to catch.
     * `Fields` still carries the COMPLETE source row (plus the flattened projections) so the framework's
     * custom-column capture sees everything the door returned.
     */
    private ToElevateRecord(
        raw: Record<string, unknown>,
        objectType: string,
        pkFieldNames: string[],
        columns: ElevateReadColumn[],
        obj: MJIntegrationObjectEntity,
    ): ExternalRecord {
        const allPkPresent = pkFieldNames.length > 0
            && pkFieldNames.every(name => raw[name] != null && serializeKeyValue(raw[name]).length > 0);
        const composite = pkFieldNames.map(name => serializeKeyValue(raw[name])).join('|');
        const resolvedID = allPkPresent ? composite : computeContentHash(this.IdentityBasis(raw, columns));

        let fields = raw;
        if (!allPkPresent && pkFieldNames.length === 1
            && (raw[pkFieldNames[0]] == null || serializeKeyValue(raw[pkFieldNames[0]]).length === 0)) {
            fields = { ...raw };
            fields[pkFieldNames[0]] = resolvedID;
        }

        const record: ExternalRecord = { ExternalID: resolvedID, ObjectType: objectType, Fields: fields };
        const watermark = obj.IncrementalWatermarkField ? raw[obj.IncrementalWatermarkField] : null;
        if (watermark != null) {
            const when = new Date(String(watermark));
            if (!Number.isNaN(when.getTime())) record.ModifiedAt = when;
        }
        return record;
    }

    /** The stable projection a keyless record's identity hashes over: declared columns only, by MJ name. */
    private IdentityBasis(raw: Record<string, unknown>, columns: ElevateReadColumn[]): Record<string, unknown> {
        const basis: Record<string, unknown> = {};
        for (const col of columns) {
            const value = col.Name in raw ? raw[col.Name] : this.ReadPath(raw, col.ResponsePath);
            if (value !== undefined) basis[col.Name] = value;
        }
        return Object.keys(basis).length > 0 ? basis : raw;
    }

    /** Declared PK names in Sequence order, mirroring the base class's `['ID']` synthetic fallback. */
    private PrimaryKeyNames(fields: MJIntegrationObjectFieldEntity[]): string[] {
        const pk = fields.filter(f => f.IsPrimaryKey).sort((a, b) => a.Sequence - b.Sequence).map(f => f.Name);
        return pk.length > 0 ? pk : ['ID'];
    }

    // ── Metadata routing helpers ──────────────────────────────────────────────

    /** The read route for one object, entirely from metadata. Throws rather than guessing a wire value. */
    private ReadRouteFor(obj: MJIntegrationObjectEntity): ElevateReadRoute {
        const cfg = this.ObjectConfig(obj);
        const readContract = this.AsObject(cfg?.readContract);
        const resource = this.FirstString(cfg, ['resourceWireValue'])
            ?? this.AccessPathResource(cfg);
        if (!resource) {
            throw new Error(
                `[elevate] IntegrationObject "${obj.Name}" declares no Configuration.resourceWireValue. Elevate ` +
                'selects the object with a BODY field, so without the wire value there is no query to send — and ' +
                'guessing it in code is exactly how the vendor\'s own prose spelling "accountCode" (rejected with ' +
                'HTTP 500) would get shipped instead of the proven "accountingCode".',
            );
        }
        return {
            Door: obj.APIPath,
            Resource: resource,
            DataKey: obj.ResponseDataKey,
            CountKey: this.FirstString(readContract, ['responseCountKey']) ?? 'response.count',
            LabelsKey: this.FirstString(readContract, ['responseLabelsKey']) ?? 'response.labels',
        };
    }

    /** Fallback resource resolution: the depth-0 access path's own body selector. Still metadata, not code. */
    private AccessPathResource(cfg: Record<string, unknown> | null): string | undefined {
        const paths = cfg?.accessPaths;
        if (!Array.isArray(paths)) return undefined;
        for (const entry of paths) {
            const path = this.AsObject(entry);
            if (path == null || (typeof path.depth === 'number' && path.depth !== 0)) continue;
            const body = this.AsObject(path.body);
            const resource = body ? body.resource : undefined;
            if (typeof resource === 'string' && resource.length > 0) return resource;
        }
        return undefined;
    }

    /**
     * The object's READ-surface columns. A field is excluded when the metadata marks it write-only or
     * explicitly excludes it from the read selector — `registration_id` is exactly that case: the probe
     * FALSIFIED it as a read column (`Field registration_id doesn't exist`) while it remains the only
     * handle the cancel API accepts. Sending it would fail the WHOLE query for the object.
     */
    private ReadColumnsFor(fields: MJIntegrationObjectFieldEntity[]): ElevateReadColumn[] {
        const out: ElevateReadColumn[] = [];
        for (const f of fields) {
            const cfg = this.ParseJSONObject(f.Configuration);
            if (this.FirstString(cfg, ['surface']) === 'write-only') continue;
            if (cfg?.excludeFromReadFieldSelector === true) continue;
            const wire = this.FirstString(cfg, ['wireSelector']) ?? f.Name;
            const path = Array.isArray(cfg?.responsePath)
                ? (cfg!.responsePath as unknown[]).filter((p): p is string => typeof p === 'string')
                : wire.split('.');
            out.push({ Name: f.Name, WireSelector: wire, ResponsePath: path.length > 0 ? path : [f.Name] });
        }
        return out;
    }

    /** Parsed `Configuration` JSON for one IntegrationObject. */
    private ObjectConfig(obj: MJIntegrationObjectEntity): Record<string, unknown> | null {
        return this.ParseJSONObject(obj.Configuration);
    }

    // ── Runtime validation probes ─────────────────────────────────────────────

    /**
     * Probes one declared resource against THIS connection with the cheapest possible query. Accepted ⇒
     * present. A rejection is remembered and warned about but NEVER removes the object — with no describe
     * endpoint, absence proves nothing, and deactivating on a thin result is tenant-visible data loss.
     */
    private async ValidateResource(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
        objectName: string,
    ): Promise<boolean> {
        const key = this.CacheKey(companyIntegration, objectName);
        const cached = this.validatedResources.get(key);
        if (cached != null) return cached;

        let accepted = false;
        try {
            const obj = this.GetCachedObject(companyIntegration.IntegrationID, objectName);
            const iofs = this.GetCachedFields(obj.ID);
            const columns = this.ReadColumnsFor(iofs);
            if (columns.length === 0) {
                this.WarnOnce(
                    `no-read-columns:${objectName}`,
                    `[elevate] "${objectName}" declares no read-surface column, so no probe query can be formed. ` +
                    'The object is still reported as present — discovery here is additive, never deactivating.',
                );
                this.validatedResources.set(key, false);
                return false;
            }
            const auth = await this.Authenticate(companyIntegration, contextUser);
            const route = this.ReadRouteFor(obj);
            const url = this.JoinURL(this.GetBaseURL(companyIntegration, auth), route.Door);
            const probeFields: Record<string, boolean> = {};
            probeFields[columns[0].WireSelector] = true;
            const response = await this.MakeHTTPRequest(auth, url, 'POST', this.BuildHeaders(auth), {
                format: 'json', resource: route.Resource, fields: probeFields,
            });
            this.LearnLabels(key, response.Body, route, this.NormalizeResponse(response.Body, route.DataKey));
            accepted = true;
        } catch (err) {
            this.WarnOnce(
                `probe-failed:${objectName}`,
                `[elevate] Declared resource "${objectName}" did not accept a minimal probe query on this ` +
                `connection (${this.SafeMessage(err)}). It is STILL reported by discovery: Elevate publishes no ` +
                'describe endpoint, so a rejection may be a per-tenant permission or a transient fault, and ' +
                'deactivating on it would delete real metadata.',
            );
        }
        this.validatedResources.set(key, accepted);
        return accepted;
    }

    /** Runs one read so the door's `response.labels` dictionary can be harvested for this connection. */
    private async LearnFieldsFromSource(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
        objectName: string,
    ): Promise<void> {
        try {
            await this.ValidateResource(companyIntegration, contextUser, objectName);
        } catch {
            /* ValidateResource already warned; the declared floor stands. */
        }
    }

    /** An `ExternalFieldSchema` for a column only runtime discovery has seen. Types inferred, never asserted. */
    private SchemaForDiscoveredField(name: string, sample: unknown): ExternalFieldSchema {
        return {
            Name: name,
            Label: name,
            Description: 'Discovered at runtime from the Elevate Report API `response.labels` dictionary for this connection.',
            DataType: this.InferType(sample),
            IsRequired: false,
            AllowsNull: true,
            IsUniqueKey: false,
            IsReadOnly: true,
            IsPrimaryKey: false,
            IsForeignKey: false,
        };
    }

    /** Conservative runtime type inference from one observed value. Unknown ⇒ String, never a guessed width. */
    private InferType(sample: unknown): string {
        if (typeof sample === 'boolean') return 'Boolean';
        if (typeof sample === 'number') return Number.isInteger(sample) ? 'Integer' : 'Decimal';
        if (typeof sample === 'string' && /^\d{4}-\d{2}-\d{2}([T ]\d{2}:\d{2})/.test(sample)) return 'Datetime';
        return 'String';
    }

    // ── Credential resolution ─────────────────────────────────────────────────

    /** Credential record first, connection Configuration second. No inline crypto; nothing is logged. */
    private async LoadCredentials(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<ElevateCredentials> {
        let fromCredential: ElevateCredentials | null = null;
        if (companyIntegration.CredentialID) {
            try {
                const md = new Metadata();
                const credential = await md.GetEntityObject<MJCredentialEntity>('MJ: Credentials', contextUser);
                const loaded = await credential.Load(companyIntegration.CredentialID);
                if (loaded && credential.Values) fromCredential = this.ParseCredentialJSON(credential.Values);
            } catch {
                // A credential the connection cannot load is a configuration problem, not a crash: the
                // Configuration fallback below still applies and Authenticate reports what is missing.
            }
        }
        const fromConfig = this.ParseCredentialJSON(companyIntegration.Configuration);
        return {
            SiteUrl: fromCredential?.SiteUrl ?? fromConfig?.SiteUrl,
            ApiKey: fromCredential?.ApiKey ?? fromConfig?.ApiKey,
        };
    }

    /**
     * The connection's site ROOT, with a door path removed if one was pasted in with it.
     *
     * `GetBaseURL` returns this verbatim and `JoinURL` then appends the object's own door
     * (`/api/reports`), so a `siteUrl` that already carries the door produced
     * `…/api/reports/api/reports`. That is a 404/405, `ValidateResource` swallows it, and
     * `TestConnection` reports "rejected a minimal query — check the site URL and the API key" —
     * naming two things that are both correct. Observed against a real tenant whose key and every
     * declared resource worked (86,074 ProductRegistration rows) while the connection would not save.
     *
     * The door paths are the ones this connector can append: `/api/reports` (read, and its `/form`
     * variant) and `/api/registrations` (write). Only a TRAILING occurrence is stripped, and only
     * whole path segments, so a site genuinely hosted under a directory of another name is untouched.
     *
     * @param raw The configured value, which may be null/undefined.
     * @returns The trimmed site root with no trailing slash, or '' when nothing was configured.
     */
    private NormalizeSiteUrl(raw: string | null | undefined): string {
        return (raw ?? '')
            .trim()
            .replace(/\/+$/, '')
            .replace(/\/api\/reports\/form$/i, '')
            .replace(/\/api\/(?:reports|registrations)$/i, '')
            .replace(/\/+$/, '');
    }

    /** Extracts the two Elevate credential fields from a credential/Configuration JSON string. */
    private ParseCredentialJSON(json: string | null): ElevateCredentials | null {
        const parsed = this.ParseJSONObject(json);
        if (!parsed) return null;
        return {
            SiteUrl: this.FirstString(parsed, ['siteUrl', 'SiteUrl', 'site_url', 'BaseURL', 'baseURL', 'BaseUrl', 'baseUrl']),
            ApiKey: this.FirstString(parsed, ['apiKey', 'ApiKey', 'api_key', 'APIKey', 'key']),
        };
    }

    // ── Small utilities ───────────────────────────────────────────────────────

    /** Merges the credential into the request body. The ONLY place the api_key ever touches the wire. */
    private WithCredential(auth: ElevateAuthContext, body: unknown): Record<string, unknown> {
        const merged: Record<string, unknown> = { api_key: auth.ApiKey };
        const asObject = this.AsObject(body);
        if (asObject) Object.assign(merged, asObject);
        return merged;
    }

    /** Removes any occurrence of the credential from a string before it reaches a log or an error. */
    private Redact(auth: ElevateAuthContext, text: string): string {
        if (!auth.ApiKey) return text;
        return text.split(auth.ApiKey).join('***');
    }

    /** The vendor's message from either observed envelope, or undefined when the body carries no error. */
    private VendorMessage(body: unknown): string | undefined {
        const obj = this.AsObject(body);
        if (!obj) return undefined;
        const error = this.AsObject(obj.error);
        if (error && typeof error.message === 'string') return error.message;
        if (typeof obj.error === 'string' && obj.error.length > 0) return obj.error;
        const messages = this.AsObject(obj.error_messages);
        if (messages) {
            const parts = Object.entries(messages).map(([k, v]) => `${k}: ${String(v)}`);
            return parts.length > 0 ? parts.join('; ') : 'error_messages';
        }
        return undefined;
    }

    /** Pulls the offending column out of the door's own `Field <name> doesn't exist` message. */
    private UnknownFieldFrom(message: string | undefined): string | null {
        if (!message) return null;
        const m = /field\s+([A-Za-z0-9_.]+)\s+does\s*n[o']?t\s+exist/i.exec(message);
        return m ? m[1] : null;
    }

    /** Walks a dotted path into a parsed body. Returns undefined at the first missing/non-object segment. */
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
        const base = baseURL.endsWith('/') ? baseURL.slice(0, -1) : baseURL;
        const path = apiPath.startsWith('/') ? apiPath : `/${apiPath}`;
        return `${base}${path}`;
    }

    /** Path-only view of a URL, for messages that must never carry a query string or a credential. */
    private PathOf(url: string): string {
        try { return new URL(url).pathname; } catch { return url; }
    }

    /** Cache key scoping a per-tenant discovery to one connection + object. */
    private CacheKey(companyIntegration: MJCompanyIntegrationEntity, objectName: string): string {
        return `${companyIntegration.ID}::${objectName}`;
    }

    /** Deterministic ordering so discovery output is byte-stable across passes. */
    private SortedNames(names: Set<string> | undefined): string[] {
        return names ? [...names].sort((a, b) => (a < b ? -1 : a > b ? 1 : 0)) : [];
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

    /** A trimmed string from the connection Configuration JSON. */
    private ConfigString(companyIntegration: MJCompanyIntegrationEntity, keys: string[]): string | undefined {
        return this.FirstString(this.ParseJSONObject(companyIntegration.Configuration), keys);
    }

    /** A finite number from the connection Configuration JSON. */
    private ConfigNumber(companyIntegration: MJCompanyIntegrationEntity, keys: string[]): number | undefined {
        const cfg = this.ParseJSONObject(companyIntegration.Configuration);
        if (!cfg) return undefined;
        for (const key of keys) {
            const v = cfg[key];
            const n = typeof v === 'number' ? v : typeof v === 'string' ? Number(v) : NaN;
            if (Number.isFinite(n)) return n;
        }
        return undefined;
    }

    /** Tolerant JSON-object parse; malformed configuration degrades to "absent" rather than crashing a sync. */
    private ParseJSONObject(json: string | null | undefined): Record<string, unknown> | null {
        if (!json || json.trim().length === 0) return null;
        try { return this.AsObject(JSON.parse(json)); } catch { return null; }
    }

    /** `YYYY-MM-DD` for today, in UTC — the granularity the probe partitioned with. */
    private Today(): string {
        return new Date().toISOString().slice(0, 10);
    }

    /** Normalises a watermark/config value to `YYYY-MM-DD`, or null when it is not a usable date. */
    private ToDayString(value: string | null | undefined): string | null {
        if (value == null) return null;
        const trimmed = String(value).trim();
        if (trimmed.length === 0) return null;
        if (/^\d{4}-\d{2}-\d{2}$/.test(trimmed)) return trimmed;
        const parsed = Date.parse(trimmed);
        return Number.isFinite(parsed) ? new Date(parsed).toISOString().slice(0, 10) : null;
    }

    /** `YYYY-MM-DD` + n days, UTC. */
    private AddDays(day: string, n: number): string {
        const base = Date.parse(`${day}T00:00:00.000Z`);
        return new Date(base + n * 86_400_000).toISOString().slice(0, 10);
    }

    /** Whole days between two `YYYY-MM-DD` values. */
    private DayDiff(from: string, to: string): number {
        return Math.round((Date.parse(`${to}T00:00:00.000Z`) - Date.parse(`${from}T00:00:00.000Z`)) / 86_400_000);
    }

    /** The earlier of two `YYYY-MM-DD` values (lexicographic order is chronological for this format). */
    private MinDay(a: string, b: string): string {
        return a <= b ? a : b;
    }

    /** Sleeps, bounded. Only ever reached on a 429/503 with a honoured `Retry-After`. */
    private async Sleep(ms: number): Promise<void> {
        const bounded = Math.max(0, Math.min(MAX_RETRY_AFTER_MS, ms));
        if (bounded === 0) return;
        await new Promise<void>(resolve => setTimeout(resolve, bounded));
    }

    /** An error message safe to log: never carries credential bytes. */
    private SafeMessage(err: unknown): string {
        const raw = err instanceof Error ? err.message : String(err);
        for (const auth of this.authCache.values()) {
            if (auth.ApiKey && raw.includes(auth.ApiKey)) return this.Redact(auth, raw);
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
