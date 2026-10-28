/**
 * InformzConnector — Higher Logic Thrive Marketing Professional (formerly Informz), read through the
 * Informz Advanced API (AAPI).
 *
 * ─── Design note — what this vendor actually is ──────────────────────────────────────────────────
 *
 * The AAPI is not a REST API. It is ONE SOAP 1.1 operation (document/literal, WCF BasicHttpBinding)
 * whose single `xs:string` parameter carries a whole, XML-escaped AAPI document. Every read is a
 * `GridRequest` POSTed to the SAME service URL; the grid (the "object") is selected INSIDE the
 * document by `<Grid type="…">`, never by the URL. Every vendor fact this class uses comes from the
 * frozen metadata, never from a literal in this file:
 *
 *   - `Integration.Configuration.Transport` — operation, SOAPAction and the request/response wrapper
 *     elements. The message namespace is `Transport.elementNamespace` when declared, else derived from
 *     the declared SOAPAction by the WCF default-Action rule (`<contract ns><Contract>/<Operation>`).
 *     `Transport.namespace` carries the WSDL definitions' targetNamespace, which is NOT the namespace
 *     of the `PostInformzMessage` element (the WSDL's xsd0 is), so it is only a last-resort fallback.
 *   - `BaseURLTemplate` + `RegionHosts` + `DefaultRegion` — the documented service URL per region;
 *     a connection-level `ServiceURL` overrides it (custom endpoints and the credential-free mocks).
 *   - `Paging` / `PaginationDefaults` / `ErrorContract` — row cap, StartRow base, fault classification.
 *   - `IntegrationObject.Configuration` — `gridType`, `sortField`, per-grid paging, `watermark`.
 *   - The Declared IntegrationObjectFields — the `<ReturnFields>` list and the canonical key casing.
 *
 * The connector rides `BaseRESTIntegrationConnector`'s metadata-driven read loop unchanged. Each IO's
 * `APIPath` (`/grids/<token>`) is a LOGICAL path: `BuildPaginatedURL` encodes the page (StartRow,
 * NumberOfRows, SortField) as internal URL markers, and `MakeHTTPRequest` turns logical URL + markers +
 * the per-call grid scope into the SOAP POST against the real service URL, then parses the escaped
 * `GridResponse` into a typed page. Which object a call is serving rides an AsyncLocalStorage scope,
 * because the base hooks (`BuildPaginatedURL`, `MakeHTTPRequest`, `NormalizeResponse`) carry no
 * per-call context and the engine may sync several objects concurrently on one instance.
 *
 * Pull-only: `Integration.Configuration.WriteScope` is operator-pull-only, so no write path exists
 * here and the CRUD writers refuse loudly. Discovery is the base's cache-driven Declared rows (the
 * AAPI has no describe endpoint; `DiscoveryIsAuthoritative` stays false); a live credential only ADDS
 * columns through the sample-union in {@link InformzConnector.IntrospectSchema}.
 */
import { AsyncLocalStorage } from 'node:async_hooks';
import { XMLParser } from 'fast-xml-parser';
import { z } from 'zod';
import { RegisterClass } from '@memberjunction/global';
import { Metadata, type UserInfo } from '@memberjunction/core';
import type {
    MJCompanyIntegrationEntity,
    MJCredentialEntity,
    MJIntegrationEntity,
    MJIntegrationObjectEntity,
    MJIntegrationObjectFieldEntity,
} from '@memberjunction/core-entities';
import { IntegrationEngineBase } from '@memberjunction/integration-engine-base';
import {
    BaseIntegrationConnector,
    BaseRESTIntegrationConnector,
    type ConnectionTestResult,
    type CreateRecordContext,
    type CRUDResult,
    type DeleteRecordContext,
    type ExternalRecord,
    type FetchBatchResult,
    type FetchContext,
    type GetRecordContext,
    type IntrospectSchemaOptions,
    type PaginationState,
    type PaginationType,
    type RESTAuthContext,
    type RESTResponse,
    type SourceSchemaInfo,
    type UpdateRecordContext,
} from '@memberjunction/integration-engine';
import { mergeDeclaredWithSampledFields } from '@memberjunction/connector-schema-merge';
import { ParseRetryAfterValue } from './RetryAfter.js';

/**
 * `IntrospectSchemaOptions.OnProgress` arrived in integration-engine 6.x; this package compiles against
 * the 5.x line (peer range >=5.43 <7), so the 6.x member is declared here and honored when present.
 */
type IntrospectSchemaOptionsCompat = IntrospectSchemaOptions & { OnProgress?: (done: number, total: number) => void };

// ─── Protocol mechanics (no catalog, no host, no tenant value) ────────────────────────────────────

const LOG_PREFIX = '[InformzConnector]';
/** Display name used in messages; the unit suite pins it to the `IntegrationName` getter literal. */
const INTEGRATION_NAME = 'Higher Logic Thrive Marketing Professional';
/** The SOAP 1.1 envelope namespace — fixed by the SOAP 1.1 specification itself, not a vendor host. */
const SOAP11_ENVELOPE_NAMESPACE = 'http://schemas.xmlsoap.org/soap/envelope/';
const PULL_ONLY_MESSAGE = 'pull-only connector (operator scope)';
/** Internal URL markers BuildPaginatedURL writes and MakeHTTPRequest consumes (never sent on the wire). */
const START_ROW_MARKER = 'mjInformzStartRow';
const ROW_COUNT_MARKER = 'mjInformzNumberOfRows';
const SORT_FIELD_MARKER = 'mjInformzSortField';
const REGION_HOST_TOKEN = '{RegionHost}';
const DEFAULT_REQUEST_DOCUMENT = 'GridRequest';
const DEFAULT_WATERMARK_COMPARATOR = 'GTE';
const DEFAULT_REQUEST_DATE_FORMAT = 'YYYY-MM-DDThh:mm:ss';
const AUTH_CACHE_TTL_MS = 5 * 60_000;
const DEFAULT_REQUEST_TIMEOUT_MS = 60_000;
const DEFAULT_THROTTLE_RETRIES = 3;
const BASE_RETRY_BACKOFF_MS = 1_000;
/** Longest Retry-After waited out INSIDE one call; anything longer is handed to the engine's limiter. */
const MAX_INLINE_RETRY_WAIT_MS = 60_000;
/** One FetchChanges call may wait out several Retry-After windows (see sendWithRetry). */
const FETCH_CHANGES_TIMEOUT_MS = 300_000;
const SAMPLING_CONCURRENCY = 4;
const ERROR_PREVIEW_CHARS = 300;

// ─── Metadata shapes (Zod) ────────────────────────────────────────────────────────────────────────
// A malformed individual key degrades to `undefined` (`.catch`) instead of discarding the whole blob.

const ZPositiveInt = z.coerce.number().int().positive();
const ZNonNegativeInt = z.coerce.number().int().nonnegative();

const ZTransport = z.object({
    operation: z.string().min(1),
    soapAction: z.string().min(1),
    namespace: z.string().min(1).optional(),
    elementNamespace: z.string().min(1).optional(),
    requestWrapper: z.string().min(1).optional(),
    responseWrapper: z.string().min(1).optional(),
}).passthrough();

const ZPaging = z.object({
    maxRowsPerRequest: ZPositiveInt.nullable().optional().catch(undefined),
    startRowBase: ZNonNegativeInt.nullable().optional().catch(undefined),
}).passthrough();

const ZIntegrationConfig = z.object({
    Transport: ZTransport.optional().catch(undefined),
    BaseURLTemplate: z.string().min(1).optional().catch(undefined),
    RegionHosts: z.record(z.string()).optional().catch(undefined),
    DefaultRegion: z.string().min(1).optional().catch(undefined),
    Paging: ZPaging.optional().catch(undefined),
    PaginationDefaults: z.object({
        maxPageSize: ZPositiveInt.nullable().optional().catch(undefined),
    }).passthrough().optional().catch(undefined),
    ErrorContract: z.object({
        classification: z.object({
            authOrPrecondition: z.array(z.string()).optional().catch(undefined),
            requestDefect: z.array(z.string()).optional().catch(undefined),
        }).passthrough().optional().catch(undefined),
    }).passthrough().optional().catch(undefined),
}).passthrough();

const ZObjectConfig = z.object({
    gridType: z.string().min(1).optional().catch(undefined),
    gridTypeAliases: z.array(z.string()).optional().catch(undefined),
    wire: z.object({
        requestDocument: z.string().min(1).optional().catch(undefined),
    }).passthrough().optional().catch(undefined),
    paging: ZPaging.optional().catch(undefined),
    sortField: z.string().min(1).nullable().optional().catch(undefined),
    watermark: z.object({
        element: z.string().min(1).optional().catch(undefined),
        comparator: z.string().min(1).optional().catch(undefined),
        format: z.string().min(1).optional().catch(undefined),
        databaseTimezone: z.string().min(1).optional().catch(undefined),
    }).passthrough().optional().catch(undefined),
}).passthrough();

const ZFieldConfig = z.object({
    wireAliases: z.array(z.string()).optional().catch(undefined),
    conditional: z.boolean().nullable().optional().catch(undefined),
}).passthrough();

const ZConnectionSettings = z.object({
    Region: z.string().min(1).optional().catch(undefined),
    ServiceURL: z.string().min(1).optional().catch(undefined),
    PageSize: ZPositiveInt.optional().catch(undefined),
    ExtraReturnFields: z.record(z.array(z.string())).optional().catch(undefined),
    RequestTimeoutMs: ZPositiveInt.optional().catch(undefined),
    RateLimitRetries: ZNonNegativeInt.optional().catch(undefined),
}).passthrough();

type IntegrationConfig = z.infer<typeof ZIntegrationConfig>;
type ObjectConfig = z.infer<typeof ZObjectConfig>;
type TransportConfig = z.infer<typeof ZTransport>;

// ─── Types ────────────────────────────────────────────────────────────────────────────────────────

/**
 * Per-connection values. Required keys are exactly the `Informz AAPI` credential-type schema keys;
 * the optional keys are connection settings. Values come from the `MJ: Credentials` record bound to
 * the CompanyIntegration, else from the connection's Configuration JSON.
 */
export interface InformzConnectionConfig {
    Username: string;
    Password: string;
    BrandID: string;
    BrandName?: string;
    Region?: string;
    ServiceURL?: string;
    PageSize?: number;
    ExtraReturnFields?: Record<string, string[]>;
    RequestTimeoutMs?: number;
    RateLimitRetries?: number;
}

/** The SOAP transport resolved from `Integration.Configuration.Transport`. */
interface InformzTransport {
    Operation: string;
    SOAPAction: string;
    MessageNamespace: string;
    RequestWrapper: string;
    ResponseWrapper: string;
}

/** Fault-code classes from `Integration.Configuration.ErrorContract.classification` (lower-cased). */
interface InformzFaultClasses {
    AuthOrPrecondition: Set<string>;
    RequestDefect: Set<string>;
}

/** Auth context: the AAPI has no token — the credentials travel inside every document body. */
interface InformzAuthContext extends RESTAuthContext {
    Kind: 'InformzAAPI';
    Connection: InformzConnectionConfig;
    ServiceURL: string;
    Transport: InformzTransport;
    FaultClasses: InformzFaultClasses;
    StartRowBase: number;
    MaxRowsPerRequest: number | null;
}

interface InformzWatermarkPlan {
    /** Canonical record key (the Declared IOF name) the watermark is read from. */
    Field: string;
    /** Wire element the incremental `<Condition>` filters on. */
    Element: string;
    Comparator: string;
    Format: string | null;
    TimeZone: string | null;
}

/** Everything one grid read needs, resolved from metadata + connection settings once per call. */
interface InformzGridPlan {
    ObjectName: string;
    APIPath: string;
    GridType: string;
    GridTypeAliases: string[];
    RequestDocument: string;
    ReturnFields: string[];
    /** lower-cased wire name / wire alias → Declared IOF name (case-insensitive key mapping). */
    FieldIndex: Map<string, string>;
    SortField: string | null;
    PageSize: number;
    MaxRowsPerRequest: number | null;
    StartRowBase: number;
    Watermark: InformzWatermarkPlan | null;
}

interface GridCondition {
    DataElement: string;
    Comparator: string;
    DataValue: string;
}

/** The per-call scope carried by AsyncLocalStorage. */
interface InformzCallScope {
    Plan: InformzGridPlan;
    Conditions: GridCondition[];
}

interface GridPageRequest {
    StartRow: number;
    NumberOfRows: number;
    SortField: string | null;
}

interface InformzGridField {
    Element: string;
    Value: string | null;
}

interface InformzGridRecord {
    /** `Record@row` — used for paging only; it never enters the record (it shifts between syncs). */
    Row: number | null;
    Fields: InformzGridField[];
}

/** The parsed body MakeHTTPRequest hands back to the base read loop. */
export interface InformzGridPage {
    Kind: 'InformzGridPage';
    GridType: string;
    StartRow: number;
    RequestedRows: number;
    Records: InformzGridRecord[];
}

/** Raw HTTP exchange result from {@link InformzConnector.SendHTTP}. */
export interface InformzWireResponse {
    Status: number;
    Headers: Record<string, string>;
    Text: string;
}

interface ParsedFault {
    Code: string | null;
    Reason: string | null;
    HasDetail: boolean;
}

export type InformzErrorClassification =
    | 'Configuration'
    | 'AuthOrPrecondition'
    | 'RequestDefect'
    | 'Fault'
    | 'Throttled'
    | 'Transport'
    | 'HTTP'
    | 'Protocol';

/**
 * A classified AAPI failure. The message wording is chosen so the engine's `ClassifyError` lands on
 * the right retry decision: throttles read as "rate limit" (retryable), transport failures keep their
 * timeout / `fetch failed` cause chain (retryable), and credential / precondition faults read as a
 * configuration problem (never retried). Messages never carry the password.
 */
export class InformzAPIError extends Error {
    public constructor(
        message: string,
        public readonly Classification: InformzErrorClassification,
        public readonly Status: number | null,
        public readonly Headers: Record<string, string>,
        public readonly FaultCode: string | null,
        options?: { cause?: unknown },
    ) {
        super(message, options);
        this.name = 'InformzAPIError';
    }

    /** True only for the failures the ErrorContract says may be retried (429/503/transport). */
    public get Retryable(): boolean {
        return this.Classification === 'Throttled' || this.Classification === 'Transport';
    }
}

// ─── Connector ────────────────────────────────────────────────────────────────────────────────────

@RegisterClass(BaseIntegrationConnector, 'InformzConnector')
export class InformzConnector extends BaseRESTIntegrationConnector {

    /** Which grid the current async call chain is reading (see the design note). */
    private readonly callScope = new AsyncLocalStorage<InformzCallScope>();

    /** Resolved auth per connection (+ credential + Configuration), refreshed after AUTH_CACHE_TTL_MS. */
    private readonly authCache = new Map<string, { Context: InformzAuthContext; ExpiresAt: number }>();

    /** Warnings already logged, so a long sync logs honestly rather than noisily. */
    private readonly warnedOnce = new Set<string>();

    /**
     * Namespace-agnostic, case-insensitive XML reader: prefixes are stripped and element/attribute
     * names lower-cased, values are kept as strings (no number coercion), and the standard-entity
     * expansion count is unbounded (object form) — a 1,000-row page carries far more than the
     * boolean-form default of 1,000 `&lt;` references inside its escaped GridResponse.
     */
    private readonly xmlParser = new XMLParser({
        ignoreAttributes: false,
        attributeNamePrefix: '@',
        removeNSPrefix: true,
        parseTagValue: false,
        parseAttributeValue: false,
        trimValues: false,
        textNodeName: '#text',
        ignoreDeclaration: true,
        ignorePiTags: true,
        htmlEntities: true,
        processEntities: { enabled: true },
        transformTagName: (name: string) => name.toLowerCase(),
        transformAttributeName: (name: string) => name.toLowerCase(),
        isArray: (name: string) => name === 'grid' || name === 'record' || name === 'field',
    });

    // ── Identity + capabilities ─────────────────────────────────────────────────────────────────

    /** Verbatim `MJ: Integrations.Name` — a literal so the T1 three-way name check can read it. */
    public override get IntegrationName(): string {
        return 'Higher Logic Thrive Marketing Professional';
    }

    /** Pull-only by operator decision (`Integration.Configuration.WriteScope`). */
    public override get SupportsCreate(): boolean {
        return false;
    }

    public override get SupportsUpdate(): boolean {
        return false;
    }

    public override get SupportsDelete(): boolean {
        return false;
    }

    public override get SupportsUpsert(): boolean {
        return false;
    }

    /**
     * FALSE, permanently (`Configuration.DiscoveryIsAuthoritative`): no AAPI endpoint enumerates a
     * brand's grids, so absence from a sample proves nothing and must never deactivate anything.
     */
    public override get DiscoveryIsAuthoritative(): boolean {
        return false;
    }

    /**
     * One call may wait out up to `RateLimitRetries` Retry-After windows (each capped at
     * MAX_INLINE_RETRY_WAIT_MS) on top of the request itself; the engine's 30s default cannot hold
     * that. `Configuration.fetchTimeoutMs` still wins.
     */
    // No `override`: the hook exists on integration-engine 6.x only. On a 6.x runtime this still overrides it;
    // on 5.x it is simply unused.
    public get FetchChangesTimeoutMs(): number | null {
        return FETCH_CHANGES_TIMEOUT_MS;
    }

    /** Reads `Retry-After` off an {@link InformzAPIError}; anything else → the standard reader. */
    public override ExtractRetryAfterMs(error: unknown): number | undefined {
        if (error instanceof InformzAPIError) {
            return ParseRetryAfterValue(error.Headers['retry-after']);
        }
        return super.ExtractRetryAfterMs(error);
    }

    // ── Discovery ───────────────────────────────────────────────────────────────────────────────
    //
    // DiscoverObjects / DiscoverFields are DELIBERATELY NOT overridden: the Declared IO/IOF rows
    // (seeded credential-free from the vendor's public help-center grid articles) ARE the standard
    // schema of record and the base reads exactly those rows back — credential-free, so the runtime
    // structure self-check never depends on a brand-registered IP. A live credential is ADDITIVE.

    /**
     * Declared ∪ live-sampled fields, so brand-specific elements requested through
     * `Configuration.ExtraReturnFields` reach the schema. Best-effort and bounded-parallel: a sampling
     * failure leaves the Declared floor intact (the shared never-shrink merge only ever adds), and a
     * connection with no usable credentials skips sampling entirely.
     */
    public override async IntrospectSchema(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
        options?: IntrospectSchemaOptions,
    ): Promise<SourceSchemaInfo> {
        const info = await super.IntrospectSchema(companyIntegration, contextUser);
        const wanted = options?.ObjectNames && options.ObjectNames.length > 0 ? new Set(options.ObjectNames) : null;
        if (wanted) info.Objects = info.Objects.filter(o => wanted.has(o.ExternalName));
        if (!(await this.canSample(companyIntegration, contextUser))) return info;
        let done = 0;
        await runBounded(info.Objects, SAMPLING_CONCURRENCY, async (obj) => {
            try {
                const sampled = await this.DiscoverFieldsViaFetch(companyIntegration, obj.ExternalName, contextUser);
                obj.Fields = mergeDeclaredWithSampledFields(obj.Fields, sampled);
            } catch (err) {
                this.warnOnce(`introspect:${obj.ExternalName}`,
                    `${LOG_PREFIX} Live field sampling for "${obj.ExternalName}" failed (${safeMessage(err)}); the Declared field floor stands.`);
            }
            done++;
            try { (options as IntrospectSchemaOptionsCompat | undefined)?.OnProgress?.(done, info.Objects.length); } catch { /* progress never breaks introspection */ }
        });
        return info;
    }

    // ── Connection test ─────────────────────────────────────────────────────────────────────────

    /**
     * One `NumberOfRows=1` GridRequest on the first Active grid by Sequence (chosen from metadata,
     * never a baked grid name). A refusal surfaces as its classified message — e.g. the brand-IP
     * registration precondition — and never carries credential bytes.
     */
    public override async TestConnection(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<ConnectionTestResult> {
        try {
            const auth = await this.Authenticate(companyIntegration, contextUser);
            const probe = this.connectionProbe(companyIntegration.IntegrationID);
            if (!probe) {
                return {
                    Success: false,
                    Message: `${INTEGRATION_NAME}: no Active IntegrationObject is declared for this integration, so there is no grid to probe. Push the integration metadata before testing.`,
                };
            }
            const read = await this.readSinglePage(companyIntegration, auth, probe, [], 1);
            return {
                Success: true,
                Message: `Connected to ${INTEGRATION_NAME}: the AAPI accepted the configured brand credentials and grid "${read.Page.GridType}" answered with ${read.Page.Records.length} row(s).`,
            };
        } catch (err) {
            return { Success: false, Message: safeMessage(err) };
        }
    }

    // ── Read path ───────────────────────────────────────────────────────────────────────────────

    /**
     * Resolves the object's grid plan, adds the incremental `<Condition>` when the object supports
     * incremental sync and a watermark is in play, runs the base read loop inside the call scope, and
     * reports the max watermark seen. A failure anywhere in the batch throws, so no watermark is
     * returned for a partial batch.
     */
    public override async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
        const obj = this.GetCachedObject(ctx.CompanyIntegration.IntegrationID, ctx.ObjectName);
        const auth = await this.Authenticate(ctx.CompanyIntegration, ctx.ContextUser);
        const plan = this.buildGridPlan(obj, auth);
        const scope: InformzCallScope = { Plan: plan, Conditions: this.watermarkConditions(plan, ctx.WatermarkValue) };
        const batch = await this.callScope.run(scope, () => super.FetchChanges(ctx));
        const newWatermark = maxWatermark(plan, batch.Records);
        return newWatermark ? { ...batch, NewWatermarkValue: newWatermark } : batch;
    }

    /**
     * Re-reads ONE record with a single `EQ` condition on the object's single Declared key. Objects
     * with no single filterable key cannot be addressed singly — refused loudly rather than guessed.
     */
    public override async GetRecord(ctx: GetRecordContext): Promise<ExternalRecord | null> {
        const companyIntegration = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const contextUser = ctx.ContextUser as UserInfo;
        const obj = this.GetCachedObject(companyIntegration.IntegrationID, ctx.ObjectName);
        const key = this.singleFilterableKey(obj);
        const auth = await this.Authenticate(companyIntegration, contextUser);
        const condition: GridCondition = { DataElement: key, Comparator: 'EQ', DataValue: ctx.ExternalID };
        const read = await this.readSinglePage(companyIntegration, auth, obj, [condition], 1);
        if (read.Records.length === 0) return null;
        return { ExternalID: ctx.ExternalID, ObjectType: ctx.ObjectName, Fields: read.Records[0] };
    }

    /** Encodes the page as INTERNAL markers on the logical grid URL; MakeHTTPRequest consumes them. */
    protected override BuildPaginatedURL(
        basePath: string,
        obj: MJIntegrationObjectEntity,
        _page: number,
        offset: number,
        _cursor?: string,
        effectivePageSize?: number,
    ): string {
        const plan = this.requireScope(obj.Name).Plan;
        return appendPagingMarkers(basePath, {
            StartRow: offset > 0 ? offset : plan.StartRowBase,
            NumberOfRows: numberOfRows(plan, effectivePageSize),
            SortField: plan.SortField,
        });
    }

    /**
     * One record per `<Record>`. Keys are the Declared IOF names matched case-insensitively (the
     * documented casing drift); undeclared `<Field element>` keys pass through verbatim for the
     * runtime custom-column capture; an empty/self-closing `<Field/>` is NULL; `Record@row` never
     * enters the record.
     */
    protected override NormalizeResponse(rawBody: unknown, _responseDataKey: string | null): Record<string, unknown>[] {
        if (!isGridPage(rawBody)) {
            throw new InformzAPIError(`${LOG_PREFIX} expected a parsed AAPI GridResponse page from MakeHTTPRequest.`, 'Protocol', null, {}, null);
        }
        const index = this.callScope.getStore()?.Plan.FieldIndex;
        return rawBody.Records.map(record => toRecordFields(record, index));
    }

    /**
     * HasMore = the page came back FULL (records == requested NumberOfRows). The next StartRow comes
     * from the response's own row numbers (they continue across pages: rows 1–50 then StartRow 51), so
     * paging stays resumable through `CurrentOffset`. A page whose rows do not move past the requested
     * StartRow is a duplicate/rewound page → stop rather than loop.
     */
    protected override ExtractPaginationInfo(
        rawBody: unknown,
        _paginationType: PaginationType,
        _currentPage: number,
        _currentOffset: number,
        _pageSize: number,
    ): PaginationState {
        if (!isGridPage(rawBody) || rawBody.Records.length === 0) return { HasMore: false };
        const next = nextStartRow(rawBody);
        if (next <= rawBody.StartRow) {
            this.warnOnce(`duplicate-page:${rawBody.GridType}`,
                `${LOG_PREFIX} Grid "${rawBody.GridType}" answered StartRow ${rawBody.StartRow} with rows that do not advance past it; treating it as a duplicate page and stopping.`);
            return { HasMore: false };
        }
        return { HasMore: rawBody.Records.length >= rawBody.RequestedRows, NextOffset: next };
    }

    // ── Transport ───────────────────────────────────────────────────────────────────────────────

    /**
     * Resolves and VALIDATES the connection once per TTL: credentials (credential record first, the
     * connection Configuration second), the service URL and the SOAP transport. Nothing is logged.
     */
    protected override async Authenticate(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<InformzAuthContext> {
        const cacheKey = `${companyIntegration.ID}|${companyIntegration.CredentialID ?? ''}|${companyIntegration.Configuration ?? ''}`;
        const cached = this.authCache.get(cacheKey);
        if (cached && cached.ExpiresAt > Date.now()) return cached.Context;
        const values = await this.loadConnectionValues(companyIntegration, contextUser);
        const context = this.buildAuthContext(companyIntegration, values);
        this.authCache.set(cacheKey, { Context: context, ExpiresAt: Date.now() + AUTH_CACHE_TTL_MS });
        return context;
    }

    /** SOAP 1.1 transport headers. The AAPI has no Authorization header — credentials ride the body. */
    protected override BuildHeaders(auth: RESTAuthContext): Record<string, string> {
        const action = this.requireAuth(auth).Transport.SOAPAction;
        return {
            'Content-Type': 'text/xml; charset=utf-8',
            SOAPAction: action.startsWith('"') ? action : `"${action}"`,
            Accept: 'text/xml',
        };
    }

    /**
     * The wire choke point for every read: strips the logical `/grids/<token>` path + the internal
     * paging markers to recover the service URL, POSTs the SOAP envelope carrying the escaped
     * GridRequest, waits out 429/503 (Retry-After honoured, capped) and transport blips, then gates:
     * any non-2xx or SOAP Fault THROWS a classified {@link InformzAPIError} — never an empty page.
     * The method argument is ignored: the AAPI has exactly one operation and it is a POST.
     */
    protected override async MakeHTTPRequest(
        auth: RESTAuthContext,
        url: string,
        _method: string,
        headers: Record<string, string>,
        _body?: unknown,
    ): Promise<RESTResponse> {
        const context = this.requireAuth(auth);
        const scope = this.callScope.getStore();
        if (!scope) {
            throw new InformzAPIError(`${LOG_PREFIX} a grid request was issued outside a FetchChanges / TestConnection / GetRecord scope.`, 'Protocol', null, {}, null);
        }
        const target = splitGridURL(url, scope.Plan.APIPath);
        const envelope = this.buildEnvelope(context, scope, target.Page);
        const wire = await this.sendWithRetry(context, target.ServiceURL, headers, envelope, scope.Plan.GridType);
        return this.interpretResponse(context, scope.Plan, target.Page, wire);
    }

    protected override GetBaseURL(_companyIntegration: MJCompanyIntegrationEntity, auth: RESTAuthContext): string {
        return this.requireAuth(auth).ServiceURL;
    }

    /**
     * Raw transport, isolated so tests substitute it without touching envelope building or gating.
     * Redirects are NOT followed: credentials inside the body are never re-posted to another URL.
     */
    protected async SendHTTP(
        url: string,
        headers: Record<string, string>,
        body: string,
        timeoutMs: number,
    ): Promise<InformzWireResponse> {
        const response = await fetch(url, {
            method: 'POST',
            headers,
            body,
            redirect: 'manual',
            signal: AbortSignal.timeout(timeoutMs),
        });
        const responseHeaders: Record<string, string> = {};
        response.headers.forEach((value, key) => { responseHeaders[key.toLowerCase()] = value; });
        return { Status: response.status, Headers: responseHeaders, Text: await response.text() };
    }

    /** Waits. Isolated so tests can assert the back-off decision without sleeping. */
    protected async Sleep(ms: number): Promise<void> {
        if (ms <= 0) return;
        await new Promise<void>(resolve => setTimeout(resolve, ms));
    }

    // ── Write path (pull-only) ──────────────────────────────────────────────────────────────────
    //
    // Overridden only to refuse: the AAPI write surface (ActionRequest documents) is out of scope by
    // operator decision (Integration.Configuration.WriteScope / OutOfScopeObjectFamilies).

    public override async CreateRecord(ctx: CreateRecordContext): Promise<CRUDResult> {
        throw pullOnlyError('CreateRecord', ctx.ObjectName);
    }

    public override async UpdateRecord(ctx: UpdateRecordContext): Promise<CRUDResult> {
        throw pullOnlyError('UpdateRecord', ctx.ObjectName);
    }

    public override async DeleteRecord(ctx: DeleteRecordContext): Promise<CRUDResult> {
        throw pullOnlyError('DeleteRecord', ctx.ObjectName);
    }

    // ═══ Private: grid plan ═══════════════════════════════════════════════════════════════════════

    private buildGridPlan(obj: MJIntegrationObjectEntity, auth: InformzAuthContext): InformzGridPlan {
        const cfg = this.objectConfig(obj);
        if (!cfg.gridType) {
            throw new InformzAPIError(
                `${INTEGRATION_NAME} integration configuration error: IntegrationObject "${obj.Name}" declares no Configuration.gridType, so its grid cannot be requested.`,
                'Configuration', null, {}, null,
            );
        }
        const fields = this.GetCachedFields(obj.ID);
        const aliases = cfg.gridTypeAliases ?? [];
        const fieldIndex = this.buildFieldIndex(fields);
        const extra = extraReturnFieldsFor(auth.Connection.ExtraReturnFields, cfg.gridType, aliases);
        return {
            ObjectName: obj.Name,
            APIPath: obj.APIPath,
            GridType: cfg.gridType,
            GridTypeAliases: aliases,
            RequestDocument: cfg.wire?.requestDocument ?? DEFAULT_REQUEST_DOCUMENT,
            ReturnFields: buildReturnFields(fields, extra),
            FieldIndex: fieldIndex,
            SortField: cfg.sortField ?? null,
            PageSize: auth.Connection.PageSize ?? obj.DefaultPageSize,
            MaxRowsPerRequest: cfg.paging?.maxRowsPerRequest ?? auth.MaxRowsPerRequest,
            StartRowBase: cfg.paging?.startRowBase ?? auth.StartRowBase,
            Watermark: watermarkPlan(obj, cfg, fieldIndex),
        };
    }

    /** lower-cased Declared name + every wire alias → the Declared IOF name (first claim wins). */
    private buildFieldIndex(fields: MJIntegrationObjectFieldEntity[]): Map<string, string> {
        const index = new Map<string, string>();
        for (const field of fields) {
            const key = field.Name.toLowerCase();
            if (!index.has(key)) index.set(key, field.Name);
        }
        for (const field of fields) {
            for (const alias of this.fieldConfig(field).wireAliases ?? []) {
                const key = alias.toLowerCase();
                if (!index.has(key)) index.set(key, field.Name);
            }
        }
        return index;
    }

    /** Incremental `<Condition>`: only for incremental objects, only when a watermark is in play. */
    private watermarkConditions(plan: InformzGridPlan, watermarkValue: string | null): GridCondition[] {
        if (!plan.Watermark || !watermarkValue) return [];
        return [{
            DataElement: plan.Watermark.Element,
            Comparator: plan.Watermark.Comparator,
            DataValue: this.formatWatermarkValue(watermarkValue, plan.Watermark),
        }];
    }

    /**
     * Renders the stored watermark in the documented REQUEST form (`watermark.format`) as wall-clock
     * time in the vendor's DATABASE time zone (`watermark.databaseTimezone`). Responses are UTC while
     * conditions are evaluated against database time, so converting the UTC high-water mark into that
     * zone re-reads the 4–5h DST offset window instead of skipping it (`watermark.overlapNote`).
     */
    private formatWatermarkValue(value: string, wm: InformzWatermarkPlan): string {
        if (!wm.Format && !wm.TimeZone) return value;
        const epochMs = Date.parse(value);
        if (Number.isNaN(epochMs)) return value;
        const parts = this.wallClockParts(new Date(epochMs), wm.TimeZone);
        return renderDateTemplate(wm.Format ?? DEFAULT_REQUEST_DATE_FORMAT, parts);
    }

    private wallClockParts(date: Date, timeZone: string | null): Record<string, string> {
        try {
            return dateParts(date, timeZone ?? 'UTC');
        } catch {
            this.warnOnce(`timezone:${timeZone ?? ''}`,
                `${LOG_PREFIX} Watermark time zone "${timeZone ?? ''}" is not recognised by this runtime; rendering the condition in UTC.`);
            return dateParts(date, 'UTC');
        }
    }

    private singleFilterableKey(obj: MJIntegrationObjectEntity): string {
        const keys = this.GetCachedFields(obj.ID).filter(f => f.IsPrimaryKey);
        if (keys.length !== 1) {
            throw new Error(`${LOG_PREFIX} GetRecord: "${obj.Name}" declares ${keys.length} primary key field(s); a single record can only be re-read through exactly one key.`);
        }
        if (this.fieldConfig(keys[0]).conditional === false) {
            throw new Error(`${LOG_PREFIX} GetRecord: the key "${keys[0].Name}" of "${obj.Name}" is documented as not usable in a Condition.`);
        }
        return keys[0].Name;
    }

    // ═══ Private: request + response ══════════════════════════════════════════════════════════════

    /** One page of one grid outside the base loop (TestConnection, GetRecord). */
    private async readSinglePage(
        companyIntegration: MJCompanyIntegrationEntity,
        auth: InformzAuthContext,
        obj: MJIntegrationObjectEntity,
        conditions: GridCondition[],
        rows: number,
    ): Promise<{ Page: InformzGridPage; Records: Record<string, unknown>[] }> {
        const plan = this.buildGridPlan(obj, auth);
        const url = appendPagingMarkers(joinURL(this.GetBaseURL(companyIntegration, auth), obj.APIPath), {
            StartRow: plan.StartRowBase,
            NumberOfRows: rows,
            SortField: plan.SortField,
        });
        return this.callScope.run({ Plan: plan, Conditions: conditions }, async () => {
            const response = await this.MakeHTTPRequest(auth, url, 'POST', this.BuildHeaders(auth));
            if (!isGridPage(response.Body)) {
                throw new InformzAPIError(`${LOG_PREFIX} expected a parsed AAPI GridResponse page.`, 'Protocol', null, {}, null);
            }
            return { Page: response.Body, Records: this.NormalizeResponse(response.Body, obj.ResponseDataKey) };
        });
    }

    /** SOAP 1.1 envelope whose wrapper text is the XML-escaped GridRequest document. */
    private buildEnvelope(auth: InformzAuthContext, scope: InformzCallScope, page: GridPageRequest): string {
        const t = auth.Transport;
        const document = this.buildGridRequest(auth, scope, page);
        return `<?xml version="1.0" encoding="utf-8"?>`
            + `<s:Envelope xmlns:s="${SOAP11_ENVELOPE_NAMESPACE}"><s:Body>`
            + `<${t.Operation} xmlns="${escapeXml(t.MessageNamespace)}"><${t.RequestWrapper}>${escapeXml(document)}</${t.RequestWrapper}></${t.Operation}>`
            + `</s:Body></s:Envelope>`;
    }

    /**
     * The GridRequest in the documented element order: Password, Brand@id (+ optional name), User,
     * then one Grid carrying Conditions, ReturnFields, SortField, StartRow, NumberOfRows. Every
     * credential and value is XML-escaped; attribute values are double-quoted.
     */
    private buildGridRequest(auth: InformzAuthContext, scope: InformzCallScope, page: GridPageRequest): string {
        const c = auth.Connection;
        const plan = scope.Plan;
        const doc = plan.RequestDocument;
        return `<${doc} xmlns="${escapeXml(auth.Transport.MessageNamespace)}">`
            + `<Password>${escapeXml(c.Password)}</Password>`
            + `<Brand id="${escapeXml(c.BrandID)}">${escapeXml(c.BrandName ?? '')}</Brand>`
            + `<User>${escapeXml(c.Username)}</User>`
            + `<Grids><Grid type="${escapeXml(plan.GridType)}">`
            + conditionsXml(scope.Conditions)
            + returnFieldsXml(plan.ReturnFields)
            + (page.SortField ? `<SortField order="asc">${escapeXml(page.SortField)}</SortField>` : '')
            + `<StartRow>${page.StartRow}</StartRow>`
            + `<NumberOfRows>${page.NumberOfRows}</NumberOfRows>`
            + `</Grid></Grids></${doc}>`;
    }

    /**
     * POST with bounded retries: transport timeouts / network blips and 429/503 are retried up to
     * `RateLimitRetries` times. A 429/503 waits its Retry-After (else exponential back-off); a
     * Retry-After longer than MAX_INLINE_RETRY_WAIT_MS is not waited out here — the response is
     * returned so it surfaces as a retryable rate-limit error the engine's limiter backs off on.
     */
    private async sendWithRetry(
        auth: InformzAuthContext,
        serviceURL: string,
        headers: Record<string, string>,
        envelope: string,
        gridType: string,
    ): Promise<InformzWireResponse> {
        const retries = auth.Connection.RateLimitRetries ?? DEFAULT_THROTTLE_RETRIES;
        const timeoutMs = auth.Connection.RequestTimeoutMs ?? DEFAULT_REQUEST_TIMEOUT_MS;
        for (let attempt = 0; ; attempt++) {
            let wire: InformzWireResponse;
            try {
                wire = await this.SendHTTP(serviceURL, headers, envelope, timeoutMs);
            } catch (err) {
                if (attempt < retries && isTransientTransportError(err)) {
                    await this.Sleep(backoffMs(attempt));
                    continue;
                }
                throw transportError(err, gridType, timeoutMs, auth.Connection.Password);
            }
            if (!isThrottleStatus(wire.Status) || attempt >= retries) return wire;
            const waitMs = throttleWaitMs(wire, attempt);
            if (waitMs === null) return wire;
            await this.Sleep(waitMs);
        }
    }

    /** Gate + parse: throttle → SOAP Fault → other non-2xx → envelope → escaped GridResponse → page. */
    private interpretResponse(
        auth: InformzAuthContext,
        plan: InformzGridPlan,
        page: GridPageRequest,
        wire: InformzWireResponse,
    ): RESTResponse {
        if (isThrottleStatus(wire.Status)) throw throttleError(wire, plan.GridType);
        const envelope = this.parseXml(wire.Text);
        const fault = envelope ? findSoapFault(envelope) : null;
        if (fault) throw this.faultError(auth, plan, wire, fault);
        if (wire.Status < 200 || wire.Status >= 300) throw httpError(wire, plan.GridType, auth.Connection.Password);
        const resultText = envelope ? findElementText(envelope, auth.Transport.ResponseWrapper.toLowerCase(), 0) : null;
        if (resultText === null) throw protocolError(plan.GridType, wire, `the body carries no <${auth.Transport.ResponseWrapper}> element`);
        const document = this.parseXml(resultText);
        if (!document) throw protocolError(plan.GridType, wire, `<${auth.Transport.ResponseWrapper}> is not an XML document`);
        const documentFault = findDocumentFault(document);
        if (documentFault) throw this.faultError(auth, plan, wire, documentFault);
        const grid = selectGrid(document, plan);
        if (grid === undefined) throw protocolError(plan.GridType, wire, 'the escaped document is not a GridResponse');
        return { Status: wire.Status, Headers: wire.Headers, Body: toGridPage(plan, page, grid) };
    }

    private faultError(auth: InformzAuthContext, plan: InformzGridPlan, wire: InformzWireResponse, fault: ParsedFault): InformzAPIError {
        const classification = classifyFault(fault.Code, auth.FaultClasses);
        const message = redact(faultMessage(classification, plan.GridType, fault), auth.Connection.Password);
        return new InformzAPIError(message, classification, wire.Status, wire.Headers, fault.Code);
    }

    /** Parses text as XML when it looks like XML; null for anything else (JSON error bodies, HTML, empty). */
    private parseXml(text: string): Record<string, unknown> | null {
        if (!text.trimStart().startsWith('<')) return null;
        try {
            const parsed: unknown = this.xmlParser.parse(text);
            return isPlainObject(parsed) ? parsed : null;
        } catch {
            return null;
        }
    }

    // ═══ Private: auth + configuration ════════════════════════════════════════════════════════════

    private buildAuthContext(companyIntegration: MJCompanyIntegrationEntity, values: Record<string, unknown>): InformzAuthContext {
        const connection = validateConnection(values);
        const integration = this.integrationConfig(companyIntegration.IntegrationID);
        return {
            Kind: 'InformzAAPI',
            Connection: connection,
            ServiceURL: resolveServiceURL(connection, integration),
            Transport: this.resolveTransport(integration),
            FaultClasses: {
                AuthOrPrecondition: lowerSet(integration.ErrorContract?.classification?.authOrPrecondition),
                RequestDefect: lowerSet(integration.ErrorContract?.classification?.requestDefect),
            },
            StartRowBase: integration.Paging?.startRowBase ?? 0,
            MaxRowsPerRequest: integration.Paging?.maxRowsPerRequest ?? integration.PaginationDefaults?.maxPageSize ?? null,
        };
    }

    private resolveTransport(integration: IntegrationConfig): InformzTransport {
        const t = integration.Transport;
        if (!t) throw configurationError('Integration.Configuration.Transport (operation, soapAction, wrappers) is missing');
        const namespace = this.messageNamespace(t);
        const requestWrapper = leadingXmlName(t.requestWrapper);
        if (!namespace || !requestWrapper) {
            throw configurationError('Integration.Configuration.Transport lacks a usable message namespace or requestWrapper');
        }
        return {
            Operation: t.operation,
            SOAPAction: t.soapAction.replace(/^"|"$/g, ''),
            MessageNamespace: namespace,
            RequestWrapper: requestWrapper,
            ResponseWrapper: leadingXmlName(t.responseWrapper) ?? `${t.operation}Result`,
        };
    }

    /** `elementNamespace` when declared; else the WCF default-Action derivation; else `namespace`. */
    private messageNamespace(t: TransportConfig): string | null {
        if (t.elementNamespace) return t.elementNamespace;
        const derived = namespaceFromSoapAction(t.soapAction, t.operation);
        if (derived) return derived;
        this.warnOnce('transport-namespace',
            `${LOG_PREFIX} Could not derive the message namespace from Transport.soapAction; falling back to Transport.namespace.`);
        return t.namespace ?? null;
    }

    private integrationConfig(integrationID: string): IntegrationConfig {
        let integration: MJIntegrationEntity | undefined;
        try {
            integration = IntegrationEngineBase.Instance.GetIntegrationByID(integrationID);
        } catch {
            integration = undefined;
        }
        if (!integration) throw configurationError(`the Integration row ${integrationID} is not loaded in the integration metadata cache`);
        const parsed = ZIntegrationConfig.safeParse(parseJSONObject(integration.Configuration) ?? {});
        if (!parsed.success) throw configurationError('Integration.Configuration is not a valid JSON object');
        return parsed.data;
    }

    /** Credential record first (per key), connection Configuration second. Nothing is logged. */
    private async loadConnectionValues(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<Record<string, unknown>> {
        const fromConfig = parseJSONObject(companyIntegration.Configuration) ?? {};
        const fromCredential = await this.loadCredentialValues(companyIntegration, contextUser);
        const merged: Record<string, unknown> = { ...fromConfig };
        for (const [key, value] of Object.entries(fromCredential)) {
            if (value !== null && value !== undefined && String(value).length > 0) merged[key] = value;
        }
        return merged;
    }

    private async loadCredentialValues(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<Record<string, unknown>> {
        if (!companyIntegration.CredentialID) return {};
        try {
            const credential = await new Metadata().GetEntityObject<MJCredentialEntity>('MJ: Credentials', contextUser);
            if (await credential.Load(companyIntegration.CredentialID)) return parseJSONObject(credential.Values) ?? {};
        } catch {
            // An unloadable credential is a configuration problem, not a crash: the Configuration
            // fallback still applies and validateConnection reports precisely which keys are missing.
        }
        return {};
    }

    // ═══ Private: metadata access ═════════════════════════════════════════════════════════════════

    private objectConfig(obj: MJIntegrationObjectEntity): ObjectConfig {
        const parsed = ZObjectConfig.safeParse(parseJSONObject(obj.Configuration) ?? {});
        return parsed.success ? parsed.data : {};
    }

    private fieldConfig(field: MJIntegrationObjectFieldEntity): z.infer<typeof ZFieldConfig> {
        const parsed = ZFieldConfig.safeParse(parseJSONObject(field.Configuration) ?? {});
        return parsed.success ? parsed.data : {};
    }

    /** First Active IntegrationObject by Sequence — the metadata-chosen connection probe. */
    private connectionProbe(integrationID: string): MJIntegrationObjectEntity | null {
        let objects: MJIntegrationObjectEntity[] = [];
        try {
            objects = IntegrationEngineBase.Instance.GetActiveIntegrationObjects(integrationID);
        } catch {
            objects = [];
        }
        const ordered = [...objects].sort((a, b) => a.Sequence - b.Sequence);
        return ordered[0] ?? null;
    }

    private async canSample(companyIntegration: MJCompanyIntegrationEntity, contextUser: UserInfo): Promise<boolean> {
        try {
            await this.Authenticate(companyIntegration, contextUser);
            return true;
        } catch (err) {
            this.warnOnce(`introspect-auth:${companyIntegration.ID}`,
                `${LOG_PREFIX} Live field sampling skipped (${safeMessage(err)}); the Declared field floor stands.`);
            return false;
        }
    }

    private requireScope(objectName: string): InformzCallScope {
        const scope = this.callScope.getStore();
        if (!scope || scope.Plan.ObjectName !== objectName) {
            throw new InformzAPIError(`${LOG_PREFIX} grid "${objectName}" was paged outside its FetchChanges scope.`, 'Protocol', null, {}, null);
        }
        return scope;
    }

    private requireAuth(auth: RESTAuthContext): InformzAuthContext {
        if (!isInformzAuth(auth)) {
            throw new InformzAPIError(`${LOG_PREFIX} received an auth context this connector did not create.`, 'Protocol', null, {}, null);
        }
        return auth;
    }

    private warnOnce(key: string, message: string): void {
        if (this.warnedOnce.has(key)) return;
        this.warnedOnce.add(key);
        console.warn(message);
    }
}

// ─── Pure helpers: configuration ──────────────────────────────────────────────────────────────────

function validateConnection(values: Record<string, unknown>): InformzConnectionConfig {
    const username = readText(values, 'Username');
    const password = readSecret(values, 'Password');
    const brandID = readText(values, 'BrandID');
    const missing = [
        username ? null : 'Username',
        password ? null : 'Password',
        brandID ? null : 'BrandID',
    ].filter((k): k is string => k !== null);
    if (!username || !password || !brandID) {
        throw configurationError(`the connection is missing required credential value(s): ${missing.join(', ')} — bind a credential with Username, Password and BrandID or supply them in the connection Configuration`);
    }
    const parsed = ZConnectionSettings.safeParse(values);
    const settings = parsed.success ? parsed.data : {};
    return {
        Username: username,
        Password: password,
        BrandID: brandID,
        BrandName: readText(values, 'BrandName'),
        Region: settings.Region,
        ServiceURL: settings.ServiceURL,
        PageSize: settings.PageSize,
        ExtraReturnFields: settings.ExtraReturnFields,
        RequestTimeoutMs: settings.RequestTimeoutMs,
        RateLimitRetries: settings.RateLimitRetries,
    };
}

/** Connection `ServiceURL` wins; else `BaseURLTemplate` with `{RegionHost}` = RegionHosts[Region ?? DefaultRegion]. */
function resolveServiceURL(connection: InformzConnectionConfig, integration: IntegrationConfig): string {
    if (connection.ServiceURL) return normalizeServiceURL(connection.ServiceURL);
    const template = integration.BaseURLTemplate;
    const hosts = integration.RegionHosts;
    if (!template || !hosts) throw configurationError('Integration.Configuration has no BaseURLTemplate / RegionHosts and the connection sets no ServiceURL');
    const region = (connection.Region ?? integration.DefaultRegion ?? '').trim().toLowerCase();
    const hostKey = Object.keys(hosts).find(k => k.toLowerCase() === region);
    if (!hostKey) {
        throw configurationError(`Region "${region}" is not one of the documented AAPI regions (${Object.keys(hosts).join(', ')})`);
    }
    return normalizeServiceURL(template.split(REGION_HOST_TOKEN).join(hosts[hostKey]));
}

function normalizeServiceURL(value: string): string {
    let parsed: URL;
    try {
        parsed = new URL(value.trim());
    } catch {
        throw configurationError('the ServiceURL is not an absolute URL');
    }
    if (parsed.protocol !== 'https:' && parsed.protocol !== 'http:') throw configurationError('the ServiceURL must be http(s)');
    return parsed.href.replace(/\/+$/, '');
}

/**
 * WCF's default Action is `<contract namespace><ContractName>/<Operation>`, and the PostInformzMessage
 * element lives in that contract namespace (WSDL xsd0). Strip `/<Operation>` and the contract name.
 */
function namespaceFromSoapAction(soapAction: string, operation: string): string | null {
    const action = soapAction.replace(/^"|"$/g, '');
    const suffix = `/${operation}`;
    if (!action.endsWith(suffix)) return null;
    const contract = action.slice(0, action.length - suffix.length);
    const cut = contract.lastIndexOf('/');
    if (cut <= 0 || cut === contract.length - 1) return null;
    return contract.slice(0, cut + 1);
}

function configurationError(detail: string): InformzAPIError {
    return new InformzAPIError(`${INTEGRATION_NAME} configuration error: ${detail}.`, 'Configuration', null, {}, null);
}

function pullOnlyError(verb: string, objectName: string): Error {
    return new Error(`${PULL_ONLY_MESSAGE}: ${INTEGRATION_NAME} does not write, so ${verb} is not available for "${objectName}".`);
}

// ─── Pure helpers: grid plan ──────────────────────────────────────────────────────────────────────

function watermarkPlan(obj: MJIntegrationObjectEntity, cfg: ObjectConfig, index: Map<string, string>): InformzWatermarkPlan | null {
    if (!obj.SupportsIncrementalSync || !obj.IncrementalWatermarkField) return null;
    const declared = obj.IncrementalWatermarkField;
    return {
        Field: index.get(declared.toLowerCase()) ?? declared,
        Element: cfg.watermark?.element ?? declared,
        Comparator: cfg.watermark?.comparator ?? DEFAULT_WATERMARK_COMPARATOR,
        Format: cfg.watermark?.format ?? null,
        TimeZone: cfg.watermark?.databaseTimezone ?? null,
    };
}

/** Every Declared (and operator-Custom) IOF wire name, in Sequence order, then the connection's extras. */
function buildReturnFields(fields: MJIntegrationObjectFieldEntity[], extra: string[]): string[] {
    const out: string[] = [];
    const seen = new Set<string>();
    const add = (name: string): void => {
        const key = name.trim().toLowerCase();
        if (key.length === 0 || seen.has(key)) return;
        seen.add(key);
        out.push(name.trim());
    };
    for (const field of fields) {
        if (field.MetadataSource !== 'Discovered') add(field.Name);
    }
    for (const name of extra) add(name);
    return out;
}

/** `Configuration.ExtraReturnFields[<gridToken>]`, keyed case-insensitively by the token or an alias. */
function extraReturnFieldsFor(extra: Record<string, string[]> | undefined, gridType: string, aliases: string[]): string[] {
    if (!extra) return [];
    const tokens = new Set([gridType, ...aliases].map(t => t.toLowerCase()));
    const out: string[] = [];
    for (const [key, names] of Object.entries(extra)) {
        if (tokens.has(key.toLowerCase())) out.push(...names);
    }
    return out;
}

function numberOfRows(plan: InformzGridPlan, effectivePageSize: number | undefined): number {
    const caps = [plan.PageSize, plan.MaxRowsPerRequest, effectivePageSize]
        .filter((n): n is number => typeof n === 'number' && Number.isFinite(n) && n > 0);
    return caps.length > 0 ? Math.max(1, Math.floor(Math.min(...caps))) : 1;
}

function maxWatermark(plan: InformzGridPlan, records: ExternalRecord[]): string | undefined {
    if (!plan.Watermark) return undefined;
    let best: string | undefined;
    for (const record of records) {
        const value = record.Fields[plan.Watermark.Field];
        if (typeof value !== 'string' || value.length === 0) continue;
        if (best === undefined || compareWatermarks(value, best) > 0) best = value;
    }
    return best;
}

function compareWatermarks(a: string, b: string): number {
    const ta = Date.parse(a);
    const tb = Date.parse(b);
    if (Number.isFinite(ta) && Number.isFinite(tb) && ta !== tb) return ta - tb;
    return a === b ? 0 : (a < b ? -1 : 1);
}

function dateParts(date: Date, timeZone: string): Record<string, string> {
    const formatter = new Intl.DateTimeFormat('en-US', {
        timeZone,
        hourCycle: 'h23',
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
    });
    const parts: Record<string, string> = {};
    for (const part of formatter.formatToParts(date)) parts[part.type] = part.value;
    return parts;
}

function renderDateTemplate(template: string, parts: Record<string, string>): string {
    return template.replace(/YYYY|MM|DD|hh|mm|ss/g, (token) => {
        switch (token) {
            case 'YYYY': return parts.year ?? '';
            case 'MM': return parts.month ?? '';
            case 'DD': return parts.day ?? '';
            case 'hh': return parts.hour ?? '';
            case 'mm': return parts.minute ?? '';
            default: return parts.second ?? '';
        }
    });
}

// ─── Pure helpers: wire ───────────────────────────────────────────────────────────────────────────

function appendPagingMarkers(url: string, page: GridPageRequest): string {
    const parsed = new URL(url);
    parsed.searchParams.set(START_ROW_MARKER, String(page.StartRow));
    parsed.searchParams.set(ROW_COUNT_MARKER, String(page.NumberOfRows));
    if (page.SortField) parsed.searchParams.set(SORT_FIELD_MARKER, page.SortField);
    else parsed.searchParams.delete(SORT_FIELD_MARKER);
    return parsed.toString();
}

/** Recovers the service URL (logical `/grids/<token>` path + internal markers removed) and the page. */
function splitGridURL(url: string, apiPath: string): { ServiceURL: string; Page: GridPageRequest } {
    const parsed = new URL(url);
    const startRow = Number.parseInt(parsed.searchParams.get(START_ROW_MARKER) ?? '', 10);
    const rows = Number.parseInt(parsed.searchParams.get(ROW_COUNT_MARKER) ?? '', 10);
    const sortField = parsed.searchParams.get(SORT_FIELD_MARKER);
    if (!Number.isFinite(startRow) || !Number.isFinite(rows)) {
        throw new InformzAPIError(`${LOG_PREFIX} grid URL carries no paging markers.`, 'Protocol', null, {}, null);
    }
    for (const marker of [START_ROW_MARKER, ROW_COUNT_MARKER, SORT_FIELD_MARKER]) parsed.searchParams.delete(marker);
    const logical = apiPath.replace(/\/+$/, '');
    if (logical.length > 0 && parsed.pathname.toLowerCase().endsWith(logical.toLowerCase())) {
        parsed.pathname = parsed.pathname.slice(0, parsed.pathname.length - logical.length) || '/';
    }
    const serviceURL = parsed.search.length > 0 ? parsed.toString() : `${parsed.origin}${parsed.pathname}`;
    return { ServiceURL: serviceURL, Page: { StartRow: startRow, NumberOfRows: rows, SortField: sortField } };
}

function joinURL(base: string, path: string): string {
    return `${base.replace(/\/+$/, '')}/${path.replace(/^\/+/, '')}`;
}

function conditionsXml(conditions: GridCondition[]): string {
    if (conditions.length === 0) return '';
    const items = conditions.map(c => '<Condition><Single>'
        + `<DataElement>${escapeXml(c.DataElement)}</DataElement>`
        + `<DataValue>${escapeXml(c.DataValue)}</DataValue>`
        + `<Comparator>${escapeXml(c.Comparator)}</Comparator>`
        + '</Single></Condition>');
    return `<Conditions>${items.join('')}</Conditions>`;
}

function returnFieldsXml(fields: string[]): string {
    if (fields.length === 0) return '';
    return `<ReturnFields>${fields.map(f => `<DataElement>${escapeXml(f)}</DataElement>`).join('')}</ReturnFields>`;
}

/** & → &amp;, < → &lt;, > → &gt;, " → &quot;, ' → &apos; */
function escapeXml(value: string): string {
    return value
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&apos;');
}

function leadingXmlName(text: string | undefined): string | null {
    const match = /^\s*([A-Za-z_][\w.-]*)/.exec(text ?? '');
    return match ? match[1] : null;
}

function isThrottleStatus(status: number): boolean {
    return status === 429 || status === 503;
}

function backoffMs(attempt: number): number {
    return BASE_RETRY_BACKOFF_MS * 2 ** attempt;
}

function throttleWaitMs(wire: InformzWireResponse, attempt: number): number | null {
    const wait = ParseRetryAfterValue(wire.Headers['retry-after']) ?? backoffMs(attempt);
    return wait > MAX_INLINE_RETRY_WAIT_MS ? null : wait;
}

/** A request timeout or undici's network-level `fetch failed` (the real cause rides `cause`). */
function isTransientTransportError(err: unknown): boolean {
    if (!(err instanceof Error)) return false;
    return err.name === 'TimeoutError' || err.name === 'AbortError'
        || (err instanceof TypeError && /fetch failed/i.test(err.message));
}

// ─── Pure helpers: response parsing ───────────────────────────────────────────────────────────────

function findSoapFault(root: Record<string, unknown>): ParsedFault | null {
    const body = childObject(childObject(root, 'envelope'), 'body');
    const fault = childObject(body, 'fault') ?? childObject(root, 'fault');
    return fault ? extractFault(fault) : null;
}

/** SOAP 1.1 (faultcode / faultstring / detail) with SOAP 1.2 Code/Reason tolerated; detail type-agnostic. */
function extractFault(fault: Record<string, unknown>): ParsedFault {
    const detail = firstObjectChild(childObject(fault, 'detail'));
    const code = xmlText(detail?.code) ?? stripPrefix(xmlText(fault.faultcode) ?? xmlText(childObject(fault, 'code')?.value));
    const reason = xmlText(detail?.reason) ?? xmlText(detail?.message) ?? xmlText(fault.faultstring)
        ?? xmlText(childObject(fault, 'reason')?.text);
    return { Code: code, Reason: reason, HasDetail: detail !== null };
}

/** A fault document returned INSIDE the result string (InformzServiceFault / InformzAAPIFault). */
function findDocumentFault(document: Record<string, unknown>): ParsedFault | null {
    for (const [name, value] of Object.entries(document)) {
        if (!name.endsWith('fault') || !isPlainObject(value)) continue;
        return { Code: xmlText(value.code), Reason: xmlText(value.reason) ?? xmlText(value.message), HasDetail: true };
    }
    return null;
}

/** Depth-limited, namespace-agnostic search for the response wrapper's text. */
function findElementText(node: Record<string, unknown>, name: string, depth: number): string | null {
    if (depth > 4) return null;
    for (const [key, value] of Object.entries(node)) {
        if (key === name) return xmlText(value) ?? '';
        if (isPlainObject(value)) {
            const found = findElementText(value, name, depth + 1);
            if (found !== null) return found;
        }
    }
    return null;
}

/**
 * The requested grid inside a GridResponse: matched by `type` (token or alias, case-insensitive),
 * else the only grid present. `undefined` = not a GridResponse; `null` = a GridResponse with no rows.
 */
function selectGrid(document: Record<string, unknown>, plan: InformzGridPlan): Record<string, unknown> | null | undefined {
    if (!('gridresponse' in document)) return undefined;
    const grids = asArray(childObject(childObject(document, 'gridresponse'), 'grids')?.grid).filter(isPlainObject);
    const wanted = new Set([plan.GridType, ...plan.GridTypeAliases].map(t => t.toLowerCase()));
    const match = grids.find(g => wanted.has((xmlText(g['@type']) ?? '').toLowerCase()));
    return match ?? (grids.length === 1 ? grids[0] : null);
}

function toGridPage(plan: InformzGridPlan, page: GridPageRequest, grid: Record<string, unknown> | null): InformzGridPage {
    const records = grid ? asArray(grid.record).filter(isPlainObject).map(toGridRecord) : [];
    return { Kind: 'InformzGridPage', GridType: plan.GridType, StartRow: page.StartRow, RequestedRows: page.NumberOfRows, Records: records };
}

function toGridRecord(node: Record<string, unknown>): InformzGridRecord {
    const row = Number.parseInt(xmlText(node['@row']) ?? '', 10);
    const fieldNodes = [...asArray(childObject(node, 'fields')?.field), ...asArray(node.field)].filter(isPlainObject);
    const fields: InformzGridField[] = [];
    for (const f of fieldNodes) {
        const element = xmlText(f['@element']);
        if (!element) continue;
        const value = xmlText(f['#text']);
        fields.push({ Element: element, Value: value === null || value.length === 0 ? null : value });
    }
    return { Row: Number.isFinite(row) ? row : null, Fields: fields };
}

function toRecordFields(record: InformzGridRecord, index: Map<string, string> | undefined): Record<string, unknown> {
    const out: Record<string, unknown> = {};
    for (const field of record.Fields) {
        const key = index?.get(field.Element.toLowerCase()) ?? field.Element;
        if (key === '__proto__' || key === 'constructor' || key === 'prototype') continue;
        if (field.Value === null && out[key] !== undefined && out[key] !== null) continue;
        out[key] = field.Value;
    }
    return out;
}

function nextStartRow(page: InformzGridPage): number {
    let last: number | null = null;
    for (const record of page.Records) {
        if (record.Row !== null && (last === null || record.Row > last)) last = record.Row;
    }
    return last !== null ? last + 1 : page.StartRow + page.Records.length;
}

function isGridPage(value: unknown): value is InformzGridPage {
    return isPlainObject(value) && value.Kind === 'InformzGridPage' && Array.isArray(value.Records);
}

function isInformzAuth(auth: RESTAuthContext): auth is InformzAuthContext {
    return auth.Kind === 'InformzAAPI' && isPlainObject(auth.Connection) && isPlainObject(auth.Transport)
        && typeof auth.ServiceURL === 'string';
}

// ─── Pure helpers: errors ─────────────────────────────────────────────────────────────────────────

function classifyFault(code: string | null, classes: InformzFaultClasses): InformzErrorClassification {
    const key = (code ?? '').toLowerCase();
    if (classes.AuthOrPrecondition.has(key)) return 'AuthOrPrecondition';
    if (classes.RequestDefect.has(key)) return 'RequestDefect';
    return 'Fault';
}

function faultMessage(classification: InformzErrorClassification, gridType: string, fault: ParsedFault): string {
    const code = fault.Code ?? 'no fault code';
    const detail = fault.Reason ? `: ${preview(fault.Reason)}` : '';
    if (classification === 'AuthOrPrecondition' && /ip\s*address/i.test(code)) {
        return `${INTEGRATION_NAME} AAPI refused the request from this server's IP address (${code})${detail}. `
            + 'Precondition: Higher Logic checks the brand id against the IP address registered with the brand, so this server\'s public IP '
            + 'must be registered for the configured brand (a Higher Logic support case) before any AAPI call succeeds. '
            + 'This is a configuration precondition, not a connector defect; retrying will not help.';
    }
    if (classification === 'AuthOrPrecondition') {
        return `${INTEGRATION_NAME} AAPI refused the configured credentials (${code})${detail}. `
            + 'Check the Username, Password and BrandID configuration of this connection; retrying will not help.';
    }
    if (classification === 'RequestDefect') {
        return `${INTEGRATION_NAME} AAPI rejected the GridRequest for grid "${gridType}" as a request defect (${code})${detail}. Retrying the same request will not help.`;
    }
    if (!fault.HasDetail) {
        return `${INTEGRATION_NAME} AAPI answered the GridRequest for grid "${gridType}" with a generic SOAP fault (${code})${detail} and no AAPI fault detail. `
            + 'Higher Logic answers this way when the credentials or the brand\'s registered IP address are not accepted: verify the connection configuration and the brand-IP registration.';
    }
    return `${INTEGRATION_NAME} AAPI answered the GridRequest for grid "${gridType}" with SOAP fault ${code}${detail}.`;
}

function throttleError(wire: InformzWireResponse, gridType: string): InformzAPIError {
    const retryAfter = wire.Headers['retry-after'];
    return new InformzAPIError(
        `${INTEGRATION_NAME} AAPI rate limit / temporary unavailability: HTTP ${wire.Status} for grid "${gridType}"${retryAfter ? ` (Retry-After ${retryAfter})` : ''}.`,
        'Throttled', wire.Status, wire.Headers, null,
    );
}

function httpError(wire: InformzWireResponse, gridType: string, secret: string): InformzAPIError {
    const contentType = wire.Headers['content-type'];
    const hint = wire.Status >= 300 && wire.Status < 400
        ? ' The redirect was not followed (credentials are never re-posted elsewhere); check the ServiceURL configuration.'
        : (wire.Status === 401 || wire.Status === 403 || wire.Status === 404 ? ' Check the ServiceURL / Region configuration of this connection.' : '');
    const message = `${INTEGRATION_NAME} AAPI answered HTTP ${wire.Status} for grid "${gridType}" without a SOAP fault`
        + `${contentType ? ` (content-type ${contentType})` : ''}: ${preview(wire.Text)}.${hint}`;
    return new InformzAPIError(redact(message, secret), 'HTTP', wire.Status, wire.Headers, null);
}

function protocolError(gridType: string, wire: InformzWireResponse, detail: string): InformzAPIError {
    return new InformzAPIError(
        `${INTEGRATION_NAME} AAPI answered HTTP ${wire.Status} for grid "${gridType}" but ${detail}.`,
        'Protocol', wire.Status, wire.Headers, null,
    );
}

function transportError(err: unknown, gridType: string, timeoutMs: number, secret: string): InformzAPIError {
    const timedOut = err instanceof Error && (err.name === 'TimeoutError' || err.name === 'AbortError');
    const message = timedOut
        ? `${INTEGRATION_NAME} AAPI request for grid "${gridType}" timed out after ${timeoutMs}ms.`
        : `${INTEGRATION_NAME} AAPI transport failure for grid "${gridType}": ${safeMessage(err)}`;
    return new InformzAPIError(redact(message, secret), 'Transport', null, {}, null, { cause: err });
}

function redact(text: string, secret: string): string {
    return secret.length >= 3 ? text.split(secret).join('***') : text;
}

function preview(text: string): string {
    const flat = text.replace(/\s+/g, ' ').trim();
    return flat.length > ERROR_PREVIEW_CHARS ? `${flat.slice(0, ERROR_PREVIEW_CHARS)}…` : flat;
}

function safeMessage(err: unknown): string {
    return err instanceof Error ? err.message : String(err);
}

// ─── Pure helpers: generic ────────────────────────────────────────────────────────────────────────

function isPlainObject(value: unknown): value is Record<string, unknown> {
    return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function asArray(value: unknown): unknown[] {
    if (value === undefined || value === null || value === '') return [];
    return Array.isArray(value) ? value : [value];
}

function childObject(node: Record<string, unknown> | null | undefined, name: string): Record<string, unknown> | null {
    const value = node ? node[name] : undefined;
    return isPlainObject(value) ? value : null;
}

function firstObjectChild(node: Record<string, unknown> | null): Record<string, unknown> | null {
    if (!node) return null;
    for (const [key, value] of Object.entries(node)) {
        if (!key.startsWith('@') && key !== '#text' && isPlainObject(value)) return value;
    }
    return null;
}

/** Text of a parsed node: a bare string, or the `#text` of an element that also carries attributes. */
function xmlText(value: unknown): string | null {
    if (typeof value === 'string') return value;
    if (typeof value === 'number' || typeof value === 'boolean') return String(value);
    if (isPlainObject(value) && typeof value['#text'] === 'string') return value['#text'];
    return null;
}

function stripPrefix(qualified: string | null): string | null {
    if (qualified === null) return null;
    const cut = qualified.lastIndexOf(':');
    return cut >= 0 ? qualified.slice(cut + 1) : qualified;
}

function lowerSet(values: string[] | undefined): Set<string> {
    return new Set((values ?? []).map(v => v.toLowerCase()));
}

function parseJSONObject(value: unknown): Record<string, unknown> | null {
    if (isPlainObject(value)) return value;
    if (typeof value !== 'string' || value.trim().length === 0) return null;
    try {
        const parsed: unknown = JSON.parse(value);
        return isPlainObject(parsed) ? parsed : null;
    } catch {
        return null;
    }
}

function readText(source: Record<string, unknown>, key: string): string | undefined {
    const value = source[key];
    if (typeof value === 'number' && Number.isFinite(value)) return String(value);
    if (typeof value !== 'string') return undefined;
    const trimmed = value.trim();
    return trimmed.length > 0 ? trimmed : undefined;
}

/** Secrets are used verbatim (never trimmed); only emptiness is rejected. */
function readSecret(source: Record<string, unknown>, key: string): string | undefined {
    const value = source[key];
    return typeof value === 'string' && value.length > 0 ? value : undefined;
}

async function runBounded<T>(items: T[], concurrency: number, worker: (item: T) => Promise<void>): Promise<void> {
    let next = 0;
    const lanes: Promise<void>[] = [];
    const lane = async (): Promise<void> => {
        while (next < items.length) {
            const item = items[next++];
            await worker(item);
        }
    };
    for (let i = 0; i < Math.min(concurrency, items.length); i++) lanes.push(lane());
    await Promise.all(lanes);
}
