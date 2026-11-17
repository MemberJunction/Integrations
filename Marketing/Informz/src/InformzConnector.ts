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
 * Writes (`Integration.Configuration.WriteScope`): an object is writable only when its
 * `IntegrationObject.Configuration.writeActions` declares the operation; any other object answers 403
 * with no request. A create or update is ONE ActionRequest document whose action, element map,
 * interest action and identity read-back all come from `writeActions`, posted inside the same
 * PostInformzMessage envelope with the same credential block, escaping and SOAPAction as a
 * GridRequest. A code guard refuses every interest action except the keyed add-or-update one, from
 * metadata or connection settings alike. Interest names and demographic `<Field>` elements come only
 * from connection settings (`SubscribeInterestNames`, `SubscribeFieldDefinitions`), never metadata.
 * The ActionResponse carries no record id, so identity is READ BACK from the declared grid; a create
 * reads back BEFORE posting too (WRITE_STUDY.md writeDefaultOverrides: the vendor's match key is
 * undocumented, so a re-push must not depend on it). Delete is unsupported: an Unsubscribe is a
 * consent status change, not a record delete. No write failure ever reports StatusCode 403 except a
 * write to a read-only object — the engine treats 403 as a permanent skip and would lose the change.
 *
 * Discovery is the base's cache-driven Declared rows (the AAPI has no describe endpoint;
 * `DiscoveryIsAuthoritative` stays false); a live credential only ADDS columns through the
 * sample-union in {@link InformzConnector.IntrospectSchema}.
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
/** The ONLY interest action a per-record push may send (C4 guard): keyed add-or-update, never list-replacing. */
const ALLOWED_INTEREST_ACTION = 'AddOrUpdateSubscribers';
/** WRITE_STUDY.md gap 2 safe default for a connection FieldDefinition that names no DataType. */
const DEFAULT_FIELD_DATA_TYPE = 'String';
/** The only identity mode modelled: the ActionResponse carries no record id, so it is read back from a grid. */
const IDENTITY_MODE_READBACK = 'readback';
/** Two rows are enough to tell "exactly one" from "ambiguous" on an identity read-back. */
const READBACK_ROWS = 2;
const ACTION_STATUS_SUCCESS = 'success';
const STATUS_OK = 200;
/** A request or configuration defect: retrying the same document will not help. */
const STATUS_BAD_REQUEST = 400;
/** Credential / brand-IP precondition. Never 403 (see the design note). */
const STATUS_UNAUTHORIZED = 401;
/** Reserved for a write to an object with no writeActions: the engine skips it with a warning. */
const STATUS_READ_ONLY_OBJECT = 403;
const STATUS_NOT_FOUND = 404;
const STATUS_METHOD_NOT_ALLOWED = 405;
/** Identity could not be established (zero / several read-back rows) or would change. */
const STATUS_CONFLICT = 409;
/** The record itself cannot be written (blank required element, vendor-reported invalid subscriber). */
const STATUS_UNPROCESSABLE = 422;
const STATUS_INTERNAL_ERROR = 500;
/** The vendor answered with something unclassified (generic fault, non-SOAP HTTP error, protocol drift). */
const STATUS_BAD_GATEWAY = 502;
/** 429 / 503 / transport failures after the inline retries. */
const STATUS_SERVICE_UNAVAILABLE = 503;
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
const DEFAULT_COLD_START_DATE = '2010-01-01';
const DEFAULT_WINDOW_DAYS = 30;
const MS_PER_DAY = 86_400_000;
const ISO_DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

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

const ZFaultClassification = z.object({
    authOrPrecondition: z.array(z.string()).optional().catch(undefined),
    requestDefect: z.array(z.string()).optional().catch(undefined),
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
        classification: ZFaultClassification.optional().catch(undefined),
    }).passthrough().optional().catch(undefined),
    WriteContract: z.object({
        faults: z.object({
            classification: ZFaultClassification.optional().catch(undefined),
        }).passthrough().optional().catch(undefined),
    }).passthrough().optional().catch(undefined),
    WriteScope: z.object({
        deleteDecision: z.object({
            reasons: z.array(z.string()).optional().catch(undefined),
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
    /** Per-operation write declarations; each entry is validated strictly by ZWriteAction when used. */
    writeActions: z.object({
        create: z.unknown().optional(),
        update: z.unknown().optional(),
    }).passthrough().optional().catch(undefined),
}).passthrough();

/**
 * One `writeActions.<op>` entry. Strict on purpose: a malformed declaration is a configuration error,
 * never a silent default (in particular `interestAction` is never defaulted).
 */
const ZWriteAction = z.object({
    document: z.string().min(1),
    action: z.string().min(1),
    interestAction: z.string().min(1),
    /** wire element (e.g. the Subscriber child) → Declared IOF name; key order = document order. */
    elements: z.record(z.string().min(1)),
    requiredElements: z.array(z.string().min(1)).optional(),
    identity: z.object({
        mode: z.string().min(1),
        grid: z.string().min(1),
        conditions: z.array(z.string().min(1)).min(1),
        key: z.string().min(1),
    }).passthrough(),
}).passthrough();

/** One connection `SubscribeFieldDefinitions` entry (tenant data). */
const ZSubscribeFieldDefinition = z.object({
    Name: z.string().trim().min(1),
    DataType: z.string().trim().min(1).optional(),
    DefaultValue: z.union([z.string(), z.number(), z.boolean()]).nullable().optional(),
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
type InformzWriteAction = z.infer<typeof ZWriteAction>;

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
    /** Interest names every Subscribe joins (`Configuration.SubscribeInterestNames`; tenant data, never metadata). */
    SubscribeInterestNames?: string[];
    /** Demographic `<Field element>`s a Subscribe may carry, each with its `<FieldDefinition>` (tenant data). */
    SubscribeFieldDefinitions?: InformzSubscribeFieldDefinition[];
    /** Problems found in the Subscribe settings. A write refuses while any exist; reads ignore them. */
    SubscribeSettingIssues?: string[];
    /** Every connection value whose key names an InterestAction — input to the C4 guard only, never sent. */
    InterestActionOverrides?: string[];
}

/** One `<FieldDefinition>` a connection declares for Subscribe (non-secret; never metadata). */
export interface InformzSubscribeFieldDefinition {
    Name: string;
    DataType: string;
    DefaultValue?: string;
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
    /** ErrorContract ∪ WriteContract.faults classes — used for every write (and its read-backs). */
    WriteFaultClasses: InformzFaultClasses;
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
    Pacing?: InformzMigrationPacing | null;
    RequestsMade?: number;
    /** Set only for a write: the call carries this ActionRequest instead of a GridRequest. */
    Action?: InformzActionCall;
}

/** Metered migration pacing & run-budget configuration (`CompanyIntegration.Configuration.migrationPacing`). */
export interface InformzMigrationPacing {
    tokensPerSec?: number;
    burst?: number;
    maxConcurrency?: number;
    minDelayBetweenRequestsMs?: number;
    maxRequestsPerRun?: number;
    maxWindowsPerRun?: number;
    checkpointPerWindow?: boolean;
}

/** Per-grid or global sliding date-window configuration for Informz AAPI `<Conditions>`. */
export interface InformzDateWindowConfig {
    startDate?: string;
    windowDays?: number;
    lookbackDays?: number;
    upperComparator?: string;
}

/** Inclusive `[From, To]` ISO `YYYY-MM-DD` date window. */
export interface InformzDateWindow {
    From: string;
    To: string;
}

/** Composite cursor `v1|<Today>|<From>|<To>|<StartRow>|<ScopeKey>` for resumable bounded-window AAPI grid harvests. */
export interface InformzWindowCursor {
    Today: string;
    From: string;
    To: string;
    StartRow: number;
    ScopeKey: string;
}

export function addInformzDays(iso: string, days: number): string {
    const base = Date.parse(`${iso.slice(0, 10)}T00:00:00Z`);
    if (Number.isNaN(base)) return iso;
    return new Date(base + days * MS_PER_DAY).toISOString().slice(0, 10);
}

export function initialInformzDateWindow(
    cfg: InformzDateWindowConfig,
    watermark: string | null | undefined,
    today: string,
): InformzDateWindow {
    const startFloor = cfg.startDate && ISO_DATE_RE.test(cfg.startDate.slice(0, 10))
        ? cfg.startDate.slice(0, 10)
        : DEFAULT_COLD_START_DATE;
    const lookback = Math.max(0, cfg.lookbackDays ?? 0);
    const windowDays = Math.max(1, cfg.windowDays ?? DEFAULT_WINDOW_DAYS);

    let from = watermark && ISO_DATE_RE.test(watermark.slice(0, 10))
        ? addInformzDays(watermark.slice(0, 10), -lookback)
        : startFloor;
    if (cfg.startDate && ISO_DATE_RE.test(cfg.startDate.slice(0, 10)) && cfg.startDate.slice(0, 10) > from) {
        from = cfg.startDate.slice(0, 10);
    }
    if (from > today) from = today;
    const candidateTo = addInformzDays(from, windowDays - 1);
    const to = candidateTo < today ? candidateTo : today;
    return { From: from, To: to };
}

export function nextInformzDateWindow(
    current: InformzDateWindow,
    cfg: InformzDateWindowConfig,
    today: string,
): InformzDateWindow | null {
    if (current.To >= today) return null;
    const windowDays = Math.max(1, cfg.windowDays ?? DEFAULT_WINDOW_DAYS);
    const from = addInformzDays(current.To, 1);
    const candidateTo = addInformzDays(from, windowDays - 1);
    const to = candidateTo < today ? candidateTo : today;
    return { From: from, To: to };
}

export function formatInformzWindowCursor(c: InformzWindowCursor): string {
    return ['v1', c.Today, c.From, c.To, String(Math.max(0, c.StartRow || 0)), c.ScopeKey || ''].join('|');
}

export function parseInformzWindowCursor(raw: string | null | undefined): InformzWindowCursor | null {
    if (!raw || !raw.startsWith('v1|')) return null;
    const parts = raw.split('|');
    if (parts.length < 5) return null;
    const [, today, from, to, startRowRaw, scopeKey = ''] = parts;
    if (!ISO_DATE_RE.test(today) || !ISO_DATE_RE.test(from) || !ISO_DATE_RE.test(to)) return null;
    const parsedRow = Number.parseInt(startRowRaw, 10);
    const startRow = Number.isFinite(parsedRow) && parsedRow >= 0 ? parsedRow : 0;
    return { Today: today, From: from, To: to, StartRow: startRow, ScopeKey: scopeKey };
}


/** What a request is, for messages: `grid "x"` / `the GridRequest for grid "x"`. */
interface RequestLabel {
    Subject: string;
    Request: string;
}

/** One ActionRequest POST. It rides the same call scope as a grid read (C7). */
interface InformzActionCall {
    /** The unescaped ActionRequest document; the envelope escapes it exactly like a GridRequest. */
    Document: string;
    Action: string;
    /** The LOGICAL Create/UpdateAPIPath, stripped from the URL to recover the service URL. */
    APIPath: string;
    Label: RequestLabel;
}

/** The parsed `Responses > <action>` node of an ActionResponse. */
interface InformzActionOutcome {
    Kind: 'InformzActionOutcome';
    Status: string | null;
    Message: string | null;
    /** max(the Message "N invalid addresses" count, the number of `<InvalidSubscribers>` children). */
    InvalidCount: number;
}

type WriteOperation = 'create' | 'update';

/** One writeActions element, resolved against the Declared fields. */
interface WriteElement {
    Element: string;
    Field: string;
    Required: boolean;
    /** The Declared IOF type is integer, so the value must be an integer literal. */
    Integer: boolean;
    /** The field is one of the identity read-back conditions (it must never change on an update). */
    Identity: boolean;
}

/** Everything one write needs, resolved from metadata + connection settings before any request. */
interface WriteSpec {
    Object: MJIntegrationObjectEntity;
    Action: InformzWriteAction;
    APIPath: string;
    Elements: WriteElement[];
    FieldIndex: Map<string, string>;
    /** lower-cased Declared names of read-only IOFs (vendor-owned; dropped from attributes). */
    ReadOnlyFields: Set<string>;
    ReadbackObject: MJIntegrationObjectEntity;
    /** The Declared name of the read-back key on the read-back object. */
    ReadbackKey: string;
    Label: RequestLabel;
    InterestNames: string[];
    FieldDefinitions: InformzSubscribeFieldDefinition[];
}

interface WriteFieldValue {
    Definition: InformzSubscribeFieldDefinition;
    Value: string;
}

/** The attributes of one write, classified: identity elements and connection-configured Fields. */
interface WriteDraft {
    /** element → trimmed text ('' when the attribute was blank). */
    Elements: Map<string, string>;
    Fields: WriteFieldValue[];
}

interface SubscribeSettings {
    InterestNames?: string[];
    FieldDefinitions?: InformzSubscribeFieldDefinition[];
    InterestActions: string[];
    Issues: string[];
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

/** A write refused before (or instead of) a vendor call, carrying the CRUD StatusCode to report. */
class InformzWriteRefusal extends Error {
    public constructor(message: string, public readonly StatusCode: number) {
        super(message);
        this.name = 'InformzWriteRefusal';
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

    /** Active metered migration pacing for the current run. */
    private activePacing: InformzMigrationPacing | null = null;

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

    /**
     * Create/update via ActionRequest (`Integration.Configuration.WriteScope`). Connector-level only:
     * an object without `Configuration.writeActions` still refuses per object (403, no request).
     */
    public override get SupportsCreate(): boolean {
        return true;
    }

    public override get SupportsUpdate(): boolean {
        return true;
    }

    /**
     * FALSE per `WriteScope.deleteDecision` (supported:false): an Unsubscribe is a global consent
     * status change, not a delete, and no delete document is implemented.
     */
    public override get SupportsDelete(): boolean {
        return false;
    }

    /** The engine never calls Upsert; create already reads back before posting. */
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

    /** Conservative rate-limit policy for Informz AAPI; dynamically overridden by `migrationPacing`. */
    public get RateLimitPolicy(): { TokensPerSec: number; Burst: number } | null {
        const tokensPerSec = this.activePacing?.tokensPerSec ?? 2;
        const burst = this.activePacing?.burst ?? 4;
        return { TokensPerSec: tokensPerSec, Burst: burst };
    }

    /** Serializes large AAPI GridRequest queries by default; dynamically overridden by `migrationPacing.maxConcurrency`. */
    public get MaxConcurrencyHint(): number {
        return this.activePacing?.maxConcurrency ?? 2;
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
     * reports the max watermark seen. When `dateWindowing` is configured (or a `v1|...` cursor is resumed)
     * on an incremental grid, runs bounded `[windowFrom, windowTo]` two-condition slices so `StartRow`
     * resets to `StartRowBase` on each window advance and avoids deep-offset SQL timeouts.
     */
    public override async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
        const obj = this.GetCachedObject(ctx.CompanyIntegration.IntegrationID, ctx.ObjectName);
        const pacing = this.readMigrationPacing(ctx.CompanyIntegration);
        this.activePacing = pacing;
        const auth = await this.Authenticate(ctx.CompanyIntegration, ctx.ContextUser);
        const plan = this.buildGridPlan(obj, auth);

        const windowCfg = this.resolveDateWindowConfig(ctx.CompanyIntegration, obj.Name);
        const resumedCursor = parseInformzWindowCursor(ctx.CurrentCursor) ?? parseInformzWindowCursor(ctx.WatermarkValue);
        if (plan.Watermark && (windowCfg || resumedCursor)) {
            return this.fetchDateWindowedChanges(ctx, plan, pacing, windowCfg ?? {}, resumedCursor);
        }

        const scope: InformzCallScope = {
            Plan: plan,
            Conditions: this.watermarkConditions(plan, ctx.WatermarkValue),
            Pacing: pacing,
            RequestsMade: 0,
        };
        const batch = await this.callScope.run(scope, () => super.FetchChanges(ctx));
        const newWatermark = maxWatermark(plan, batch.Records);
        return newWatermark ? { ...batch, NewWatermarkValue: newWatermark } : batch;
    }

    /**
     * Bounded date-window harvester (`v1|<Today>|<From>|<To>|<StartRow>|`) for Informz AAPI grids.
     * Injects a two-sided `<Conditions>` pair (`GTE` on `window.From` and `LTE` on `window.To`) into each
     * `GridRequest`, delegates inner page iteration to `super.FetchChanges`, and resets `StartRow` to
     * `plan.StartRowBase` whenever a window completes.
     */
    private async fetchDateWindowedChanges(
        ctx: FetchContext,
        plan: InformzGridPlan,
        pacing: InformzMigrationPacing | null,
        windowCfg: InformzDateWindowConfig,
        resumedCursor: InformzWindowCursor | null,
    ): Promise<FetchBatchResult> {
        const batchLimit = ctx.BatchSize && ctx.BatchSize > 0 ? ctx.BatchSize : Number.MAX_SAFE_INTEGER;
        const maxRequests = pacing?.maxRequestsPerRun && pacing.maxRequestsPerRun > 0
            ? pacing.maxRequestsPerRun
            : Number.MAX_SAFE_INTEGER;
        const maxWindows = pacing?.maxWindowsPerRun && pacing.maxWindowsPerRun > 0
            ? pacing.maxWindowsPerRun
            : Number.MAX_SAFE_INTEGER;
        const checkpointPerWindow = pacing?.checkpointPerWindow === true;

        const today = resumedCursor?.Today ?? new Date().toISOString().slice(0, 10);
        let window: InformzDateWindow = resumedCursor
            ? { From: resumedCursor.From, To: resumedCursor.To }
            : initialInformzDateWindow(windowCfg, ctx.WatermarkValue, today);
        let startRow = resumedCursor?.StartRow ?? plan.StartRowBase;

        const out: ExternalRecord[] = [];
        let totalRequestsMade = 0;
        let windowsCompleted = 0;
        let lastCompletedWindowTo: string | null = null;
        let hasMore = true;

        while (hasMore && out.length < batchLimit) {
            if (totalRequestsMade >= maxRequests || windowsCompleted >= maxWindows) {
                break;
            }
            const remainingRows = Math.max(1, batchLimit - out.length);
            const remainingReqs = Math.max(1, maxRequests - totalRequestsMade);
            const perWindowCap = remainingReqs < Number.MAX_SAFE_INTEGER
                ? Math.min(remainingRows, remainingReqs * Math.max(1, plan.PageSize))
                : remainingRows;

            const scope: InformzCallScope = {
                Plan: plan,
                Conditions: this.boundedWindowConditions(plan, window, windowCfg),
                Pacing: pacing,
                RequestsMade: totalRequestsMade,
            };
            const windowCtx: FetchContext = {
                ...ctx,
                CurrentOffset: startRow,
                BatchSize: perWindowCap,
            };
            const windowBatch = await this.callScope.run(scope, () => super.FetchChanges(windowCtx));
            totalRequestsMade = scope.RequestsMade ?? totalRequestsMade;
            out.push(...windowBatch.Records);

            if (windowBatch.HasMore) {
                startRow = windowBatch.NextOffset ?? (startRow + windowBatch.Records.length);
                break;
            }

            // Current date window [window.From, window.To] is completely drained!
            lastCompletedWindowTo = window.To;
            windowsCompleted++;
            startRow = plan.StartRowBase;

            const nextWin = nextInformzDateWindow(window, windowCfg, today);
            if (nextWin) {
                window = nextWin;
                if (checkpointPerWindow) {
                    break;
                }
            } else {
                hasMore = false;
                break;
            }
        }

        const nextCursor = hasMore
            ? formatInformzWindowCursor({ Today: today, From: window.From, To: window.To, StartRow: startRow, ScopeKey: '' })
            : undefined;
        const maxSeen = maxWatermark(plan, out);
        const candidateWatermark = maxSeen ?? (lastCompletedWindowTo ? `${lastCompletedWindowTo}T23:59:59Z` : undefined);

        return {
            Records: out,
            HasMore: hasMore,
            NextCursor: nextCursor,
            NextOffset: hasMore ? startRow : undefined,
            NewWatermarkValue: (!hasMore || lastCompletedWindowTo !== null) ? candidateWatermark : undefined,
        };
    }

    /**
     * Builds two-sided `[window.From, window.To]` `<Condition>` entries (`GTE` + `LTE`) for bounded date-window harvesting.
     */
    private boundedWindowConditions(
        plan: InformzGridPlan,
        window: InformzDateWindow,
        windowCfg: InformzDateWindowConfig,
    ): GridCondition[] {
        if (!plan.Watermark) return [];
        const lowerIso = `${window.From.slice(0, 10)}T00:00:00Z`;
        const upperIso = `${window.To.slice(0, 10)}T23:59:59Z`;
        const lower: GridCondition = {
            DataElement: plan.Watermark.Element,
            Comparator: plan.Watermark.Comparator,
            DataValue: this.formatWatermarkValue(lowerIso, plan.Watermark),
        };
        const upper: GridCondition = {
            DataElement: plan.Watermark.Element,
            Comparator: windowCfg.upperComparator ?? 'LTE',
            DataValue: this.formatWatermarkValue(upperIso, plan.Watermark),
        };
        return [lower, upper];
    }

    private readMigrationPacing(companyIntegration: MJCompanyIntegrationEntity): InformzMigrationPacing | null {
        const parsed = parseJSONObject(companyIntegration.Configuration);
        const raw = parsed ? parsed.migrationPacing : undefined;
        if (!isPlainObject(raw)) return null;
        return {
            tokensPerSec: typeof raw.tokensPerSec === 'number' ? raw.tokensPerSec : undefined,
            burst: typeof raw.burst === 'number' ? raw.burst : undefined,
            maxConcurrency: typeof raw.maxConcurrency === 'number' ? raw.maxConcurrency : undefined,
            minDelayBetweenRequestsMs: typeof raw.minDelayBetweenRequestsMs === 'number' ? raw.minDelayBetweenRequestsMs : undefined,
            maxRequestsPerRun: typeof raw.maxRequestsPerRun === 'number' ? raw.maxRequestsPerRun : undefined,
            maxWindowsPerRun: typeof raw.maxWindowsPerRun === 'number' ? raw.maxWindowsPerRun : undefined,
            checkpointPerWindow: raw.checkpointPerWindow === true || raw.checkpointPerWindow === 'true',
        };
    }

    private resolveDateWindowConfig(
        companyIntegration: MJCompanyIntegrationEntity,
        objectName: string,
    ): InformzDateWindowConfig | null {
        const parsed = parseJSONObject(companyIntegration.Configuration);
        if (!parsed) return null;
        const globalStartDate = typeof parsed.startDate === 'string' ? parsed.startDate : undefined;
        const globalWindowDays = typeof parsed.windowDays === 'number' ? parsed.windowDays : undefined;
        const dw = parsed.dateWindowing;
        let ciWin: Record<string, unknown> | null = null;
        if (dw === true) {
            ciWin = {};
        } else if (isPlainObject(dw)) {
            const perObj = dw[objectName];
            if (perObj === true) ciWin = {};
            else if (isPlainObject(perObj)) ciWin = perObj;
            else if (dw.enabled === true) ciWin = dw;
        }
        if (!ciWin) return null;
        return {
            startDate: typeof ciWin.startDate === 'string' ? ciWin.startDate : globalStartDate,
            windowDays: typeof ciWin.windowDays === 'number' ? ciWin.windowDays : globalWindowDays,
            lookbackDays: typeof ciWin.lookbackDays === 'number' ? ciWin.lookbackDays : undefined,
            upperComparator: typeof ciWin.upperComparator === 'string' ? ciWin.upperComparator : undefined,
        };
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
     * The wire choke point for every request: strips the logical path (`/grids/<token>` + internal
     * paging markers, or the write's Create/UpdateAPIPath) to recover the service URL, POSTs the SOAP
     * envelope carrying the escaped GridRequest or ActionRequest, waits out 429/503 (Retry-After
     * honoured, capped) and transport blips, then gates: any non-2xx or SOAP Fault THROWS a classified
     * {@link InformzAPIError} — never an empty page. The method argument is ignored: the AAPI has
     * exactly one operation and it is a POST.
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
        const requestsSoFar = scope.RequestsMade ?? 0;
        const minDelayMs = scope.Pacing?.minDelayBetweenRequestsMs ?? 0;
        if (requestsSoFar > 0 && minDelayMs > 0) {
            await this.Sleep(minDelayMs);
        }
        scope.RequestsMade = requestsSoFar + 1;
        if (scope.Action) return this.sendActionRequest(context, url, headers, scope.Action);
        const target = splitGridURL(url, scope.Plan.APIPath);
        const envelope = this.buildEnvelope(context, scope, target.Page);
        const wire = await this.sendWithRetry(context, target.ServiceURL, headers, envelope, gridLabel(scope.Plan.GridType).Subject);
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

    // ── Write path (ActionRequest) ──────────────────────────────────────────────────────────────
    //
    // Overridden (not the base's generic per-operation CRUD) because the AAPI is ONE SOAP operation:
    // a write is an ActionRequest document inside the PostInformzMessage envelope, not a REST verb on
    // Create/UpdateAPIPath (those are LOGICAL paths, like `/grids/<token>`), and its response carries
    // no record id, so identity is read back from a grid. Every failure is a CRUDResult with a
    // non-403 StatusCode except a write to a read-only object (the engine's skip-with-warning case).

    public override async CreateRecord(ctx: CreateRecordContext): Promise<CRUDResult> {
        return this.runWrite('create', ctx.CompanyIntegration as MJCompanyIntegrationEntity, ctx.ContextUser as UserInfo, ctx.ObjectName, null, ctx.Attributes);
    }

    public override async UpdateRecord(ctx: UpdateRecordContext): Promise<CRUDResult> {
        return this.runWrite('update', ctx.CompanyIntegration as MJCompanyIntegrationEntity, ctx.ContextUser as UserInfo, ctx.ObjectName, ctx.ExternalID, ctx.Attributes);
    }

    /**
     * Sends nothing. `WriteScope.deleteDecision` keeps delete unsupported: the vendor's nearest
     * operation is a global consent status change, which an MJ row delete must never trigger. 405,
     * not 403: a 403 would make the engine skip AND advance its push watermark.
     */
    public override async DeleteRecord(ctx: DeleteRecordContext): Promise<CRUDResult> {
        const integrationID = (ctx.CompanyIntegration as MJCompanyIntegrationEntity).IntegrationID;
        return {
            Success: false,
            StatusCode: STATUS_METHOD_NOT_ALLOWED,
            ErrorMessage: `${INTEGRATION_NAME}: DeleteRecord is not supported for "${ctx.ObjectName}", so nothing was sent. ${this.deleteReasons(integrationID)}`,
        };
    }

    // ═══ Private: write path ══════════════════════════════════════════════════════════════════════

    /**
     * One create or update: per-object gate (403, no request) → interest-action guard → write spec
     * (metadata + connection settings) → attribute classification → the operation. Every failure is
     * returned as a CRUDResult; nothing throws to the engine.
     */
    private async runWrite(
        operation: WriteOperation,
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
        objectName: string,
        externalID: string | null,
        attributes: Record<string, unknown>,
    ): Promise<CRUDResult> {
        let writeClasses: InformzFaultClasses | null = null;
        try {
            const obj = this.GetCachedObject(companyIntegration.IntegrationID, objectName);
            const action = this.writeActionFor(obj, operation);
            if (!action) return readOnlyResult(obj.Name);
            guardInterestAction(action.interestAction, `IntegrationObject "${obj.Name}" Configuration.writeActions.${operation}.interestAction`);
            const auth = await this.Authenticate(companyIntegration, contextUser);
            writeClasses = auth.WriteFaultClasses;
            const spec = this.resolveWriteSpec(obj, operation, action, auth);
            const draft = draftWrite(spec, attributes ?? {});
            return operation === 'create'
                ? await this.createViaAction(companyIntegration, auth, spec, draft)
                : await this.updateViaAction(companyIntegration, contextUser, auth, spec, draft, externalID ?? '');
        } catch (err) {
            return writeFailure(err, writeClasses);
        }
    }

    /** The object's `writeActions.<op>`; null when undeclared (the object is read-only for it). */
    private writeActionFor(obj: MJIntegrationObjectEntity, operation: WriteOperation): InformzWriteAction | null {
        const raw = this.objectConfig(obj).writeActions?.[operation];
        if (raw === undefined || raw === null) return null;
        const parsed = ZWriteAction.safeParse(raw);
        if (!parsed.success) {
            throw configurationError(`IntegrationObject "${obj.Name}" Configuration.writeActions.${operation} is malformed (${zodIssues(parsed.error)})`);
        }
        return parsed.data;
    }

    /** Validates the declaration against the Declared fields + connection settings. No request is made. */
    private resolveWriteSpec(
        obj: MJIntegrationObjectEntity,
        operation: WriteOperation,
        action: InformzWriteAction,
        auth: InformzAuthContext,
    ): WriteSpec {
        assertSubscribeSettings(auth.Connection);
        if (action.identity.mode !== IDENTITY_MODE_READBACK) {
            throw configurationError(`IntegrationObject "${obj.Name}" writeActions.${operation}.identity.mode "${action.identity.mode}" is not supported; only "${IDENTITY_MODE_READBACK}" is modelled`);
        }
        const apiPath = (operation === 'create' ? obj.CreateAPIPath : obj.UpdateAPIPath)?.trim();
        if (!apiPath) {
            throw configurationError(`IntegrationObject "${obj.Name}" declares writeActions.${operation} but no ${operation === 'create' ? 'CreateAPIPath' : 'UpdateAPIPath'}`);
        }
        assertXmlNames(obj.Name, [action.document, action.action, ...Object.keys(action.elements)]);
        const fields = this.GetCachedFields(obj.ID);
        const fieldIndex = this.buildFieldIndex(fields);
        const readbackObject = this.readbackObject(obj, action.identity.grid);
        return {
            Object: obj,
            Action: action,
            APIPath: apiPath,
            Elements: writeElements(obj.Name, action, fields, fieldIndex),
            FieldIndex: fieldIndex,
            ReadOnlyFields: new Set(fields.filter(f => f.IsReadOnly).map(f => f.Name.toLowerCase())),
            ReadbackObject: readbackObject,
            ReadbackKey: this.readbackKey(readbackObject, action.identity.key),
            Label: actionLabel(action.document, action.action, obj.Name),
            InterestNames: auth.Connection.SubscribeInterestNames ?? [],
            FieldDefinitions: auth.Connection.SubscribeFieldDefinitions ?? [],
        };
    }

    /** The Active object whose grid is `identity.grid` — the written object itself first. */
    private readbackObject(obj: MJIntegrationObjectEntity, grid: string): MJIntegrationObjectEntity {
        const wanted = grid.toLowerCase();
        const servesGrid = (candidate: MJIntegrationObjectEntity): boolean => {
            const cfg = this.objectConfig(candidate);
            return [cfg.gridType ?? '', ...(cfg.gridTypeAliases ?? [])].some(t => t.toLowerCase() === wanted);
        };
        if (servesGrid(obj)) return obj;
        const found = this.activeObjects(obj.IntegrationID).find(servesGrid);
        if (!found) throw configurationError(`the identity read-back grid "${grid}" of "${obj.Name}" is not the grid of any Active IntegrationObject`);
        return found;
    }

    private readbackKey(obj: MJIntegrationObjectEntity, key: string): string {
        const declared = this.buildFieldIndex(this.GetCachedFields(obj.ID)).get(key.toLowerCase());
        if (!declared) throw configurationError(`the identity read-back key "${key}" is not a Declared field of "${obj.Name}"`);
        return declared;
    }

    /**
     * Create = pre-write read-back (WRITE_STUDY.md writeDefaultOverrides, 360032697272: the vendor's
     * match key is undocumented): one row → link it without posting; several → 409, nothing sent;
     * none → one Subscribe, then a post-write read-back that must find exactly one row. Never
     * Success without an ExternalID (the engine would re-create the record on every run).
     */
    private async createViaAction(
        companyIntegration: MJCompanyIntegrationEntity,
        auth: InformzAuthContext,
        spec: WriteSpec,
        draft: WriteDraft,
    ): Promise<CRUDResult> {
        const values = completeElements(spec, draft.Elements);
        const existing = await this.readBackIdentity(companyIntegration, auth, spec, values);
        if (existing.length > 1) throw identityConflict(spec, existing.length, 'before posting, so nothing was sent');
        if (existing.length === 1) return identityResult(spec, existing[0]);
        await this.postAction(companyIntegration, auth, spec, values, draft.Fields);
        const created = await this.readBackIdentity(companyIntegration, auth, spec, values);
        if (created.length !== 1) throw identityConflict(spec, created.length, `after ${spec.Label.Request} was accepted`);
        return identityResult(spec, created[0]);
    }

    /**
     * Update = re-read the stored row (GetRecord on the ExternalID), fill the elements the attributes
     * do not carry from it and refuse a change to an identity element (WRITE_STUDY.md gaps 6-7), post
     * one Subscribe, then read back: the row found must be the same ExternalID.
     */
    private async updateViaAction(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
        auth: InformzAuthContext,
        spec: WriteSpec,
        draft: WriteDraft,
        externalID: string,
    ): Promise<CRUDResult> {
        if (externalID.trim().length === 0) {
            throw new InformzWriteRefusal(`${INTEGRATION_NAME}: UpdateRecord for "${spec.Object.Name}" carries no ExternalID; nothing was sent.`, STATUS_UNPROCESSABLE);
        }
        const stored = await this.GetRecord({ CompanyIntegration: companyIntegration, ObjectName: spec.Object.Name, ContextUser: contextUser, ExternalID: externalID });
        if (!stored) {
            throw new InformzWriteRefusal(`${INTEGRATION_NAME}: no "${spec.Object.Name}" ${externalID} exists in Informz, so there is nothing to update; nothing was sent.`, STATUS_NOT_FOUND);
        }
        const values = completeElements(spec, withStoredIdentity(spec, draft.Elements, stored.Fields, externalID));
        await this.postAction(companyIntegration, auth, spec, values, draft.Fields);
        const landed = await this.readBackIdentity(companyIntegration, auth, spec, values);
        if (landed.length !== 1 || landed[0] !== externalID) {
            throw new InformzWriteRefusal(
                `${INTEGRATION_NAME}: ${spec.Label.Request} was accepted, but the identity read-back found ${landed.length} row(s) `
                + `${landed.length === 1 ? `(${spec.ReadbackKey} ${landed[0] ?? 'missing'}) ` : ''}instead of exactly "${spec.Object.Name}" ${externalID}; the update is not confirmed.`,
                STATUS_CONFLICT,
            );
        }
        return { Success: true, StatusCode: STATUS_OK, ExternalID: externalID };
    }

    /** `identity.conditions`, each EQ its element's value (conjunctive), on the read-back grid; NumberOfRows 2. */
    private async readBackIdentity(
        companyIntegration: MJCompanyIntegrationEntity,
        auth: InformzAuthContext,
        spec: WriteSpec,
        values: Map<string, string>,
    ): Promise<Array<string | null>> {
        const conditions = spec.Action.identity.conditions.map((field): GridCondition => ({
            DataElement: field,
            Comparator: 'EQ',
            // The vendor lower-cases incoming email addresses (360032692392), so a lower-cased value
            // matches the stored one under any collation; integer ids are unaffected.
            DataValue: (values.get(identityElement(spec, field).Element) ?? '').toLowerCase(),
        }));
        const read = await this.readSinglePage(companyIntegration, auth, spec.ReadbackObject, conditions, READBACK_ROWS);
        return read.Records.map(record => scalarOrNull(record[spec.ReadbackKey]));
    }

    /** One ActionRequest inside the call scope (C7); throws unless the ActionResponse reports success. */
    private async postAction(
        companyIntegration: MJCompanyIntegrationEntity,
        auth: InformzAuthContext,
        spec: WriteSpec,
        values: Map<string, string>,
        fields: WriteFieldValue[],
    ): Promise<void> {
        const document = buildActionDocument(auth, spec, values, fields);
        const call: InformzActionCall = { Document: document, Action: spec.Action.action, APIPath: spec.APIPath, Label: spec.Label };
        const scope: InformzCallScope = { Plan: this.buildGridPlan(spec.ReadbackObject, auth), Conditions: [], Action: call };
        const url = joinURL(this.GetBaseURL(companyIntegration, auth), spec.APIPath);
        const response = await this.callScope.run(scope, () => this.MakeHTTPRequest(auth, url, 'POST', this.BuildHeaders(auth), document));
        assertActionSucceeded(spec.Label, response.Body);
    }

    /** POSTs one ActionRequest and parses `Responses > <action>`; faults use the write fault classes. */
    private async sendActionRequest(
        auth: InformzAuthContext,
        url: string,
        headers: Record<string, string>,
        call: InformzActionCall,
    ): Promise<RESTResponse> {
        const serviceURL = serviceURLOf(new URL(url), call.APIPath);
        const wire = await this.sendWithRetry(auth, serviceURL, headers, wrapEnvelope(auth.Transport, call.Document), call.Label.Subject);
        const document = this.unwrapDocument(auth, auth.WriteFaultClasses, call.Label, wire);
        const outcome = readActionOutcome(document, call.Action);
        if (!outcome) {
            throw protocolError(call.Label.Subject, wire, `the escaped document is not an ActionResponse carrying a <${call.Action}> response`);
        }
        return { Status: wire.Status, Headers: wire.Headers, Body: outcome };
    }

    /** The delete refusal's reason, read from `WriteScope.deleteDecision` (generic when unavailable). */
    private deleteReasons(integrationID: string): string {
        let reasons: string[] = [];
        try {
            reasons = this.integrationConfig(integrationID).WriteScope?.deleteDecision?.reasons ?? [];
        } catch {
            reasons = [];
        }
        return reasons.length > 0
            ? `Integration.Configuration.WriteScope.deleteDecision: ${reasons.join('; ')}.`
            : 'Deleting a record is outside the operator write scope (Integration.Configuration.WriteScope).';
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
        return wrapEnvelope(auth.Transport, this.buildGridRequest(auth, scope, page));
    }

    /**
     * The GridRequest in the documented element order: the credential block (Password, Brand@id
     * + optional name, User), then one Grid carrying Conditions, ReturnFields, SortField, StartRow,
     * NumberOfRows. Every credential and value is XML-escaped; attribute values are double-quoted.
     */
    private buildGridRequest(auth: InformzAuthContext, scope: InformzCallScope, page: GridPageRequest): string {
        const plan = scope.Plan;
        const doc = plan.RequestDocument;
        return `<${doc} xmlns="${escapeXml(auth.Transport.MessageNamespace)}">`
            + credentialBlock(auth.Connection)
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
        subject: string,
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
                throw transportError(err, subject, timeoutMs, auth.Connection.Password);
            }
            if (!isThrottleStatus(wire.Status) || attempt >= retries) return wire;
            const waitMs = throttleWaitMs(wire, attempt);
            if (waitMs === null) return wire;
            await this.Sleep(waitMs);
        }
    }

    /** Gate + parse a GridRequest answer: shared unwrap (see {@link unwrapDocument}) → GridResponse → page. */
    private interpretResponse(
        auth: InformzAuthContext,
        plan: InformzGridPlan,
        page: GridPageRequest,
        wire: InformzWireResponse,
    ): RESTResponse {
        const label = gridLabel(plan.GridType);
        const document = this.unwrapDocument(auth, auth.FaultClasses, label, wire);
        const grid = selectGrid(document, plan);
        if (grid === undefined) throw protocolError(label.Subject, wire, 'the escaped document is not a GridResponse');
        return { Status: wire.Status, Headers: wire.Headers, Body: toGridPage(plan, page, grid) };
    }

    /**
     * The gate every AAPI answer passes, read or write: throttle → SOAP Fault → other non-2xx →
     * envelope → the escaped result document → an in-document fault. Returns the parsed document.
     */
    private unwrapDocument(
        auth: InformzAuthContext,
        classes: InformzFaultClasses,
        label: RequestLabel,
        wire: InformzWireResponse,
    ): Record<string, unknown> {
        const secret = auth.Connection.Password;
        const wrapper = auth.Transport.ResponseWrapper;
        if (isThrottleStatus(wire.Status)) throw throttleError(wire, label.Subject);
        const envelope = this.parseXml(wire.Text);
        const fault = envelope ? findSoapFault(envelope) : null;
        if (fault) throw faultError(classes, label, wire, fault, secret);
        if (wire.Status < 200 || wire.Status >= 300) throw httpError(wire, label.Subject, secret);
        const resultText = envelope ? findElementText(envelope, wrapper.toLowerCase(), 0) : null;
        if (resultText === null) throw protocolError(label.Subject, wire, `the body carries no <${wrapper}> element`);
        const document = this.parseXml(resultText);
        if (!document) throw protocolError(label.Subject, wire, `<${wrapper}> is not an XML document`);
        const documentFault = findDocumentFault(document);
        if (documentFault) throw faultError(classes, label, wire, documentFault, secret);
        return document;
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
        const read = integration.ErrorContract?.classification;
        const write = integration.WriteContract?.faults?.classification;
        return {
            Kind: 'InformzAAPI',
            Connection: connection,
            ServiceURL: resolveServiceURL(connection, integration),
            Transport: this.resolveTransport(integration),
            FaultClasses: {
                AuthOrPrecondition: lowerSet(read?.authOrPrecondition),
                RequestDefect: lowerSet(read?.requestDefect),
            },
            WriteFaultClasses: {
                AuthOrPrecondition: lowerSet([...(read?.authOrPrecondition ?? []), ...(write?.authOrPrecondition ?? [])]),
                RequestDefect: lowerSet([...(read?.requestDefect ?? []), ...(write?.requestDefect ?? [])]),
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
        const ordered = [...this.activeObjects(integrationID)].sort((a, b) => a.Sequence - b.Sequence);
        return ordered[0] ?? null;
    }

    private activeObjects(integrationID: string): MJIntegrationObjectEntity[] {
        try {
            return IntegrationEngineBase.Instance.GetActiveIntegrationObjects(integrationID);
        } catch {
            return [];
        }
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
    const subscribe = parseSubscribeSettings(values);
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
        SubscribeInterestNames: subscribe.InterestNames,
        SubscribeFieldDefinitions: subscribe.FieldDefinitions,
        SubscribeSettingIssues: subscribe.Issues.length > 0 ? subscribe.Issues : undefined,
        InterestActionOverrides: subscribe.InterestActions.length > 0 ? subscribe.InterestActions : undefined,
    };
}

/**
 * The connection's Subscribe settings, parsed leniently so a malformed one never breaks a READ: each
 * problem is recorded in `Issues` and a write refuses while any exist. Every key naming an
 * InterestAction is captured for the C4 guard (there is no supported setting by that name).
 */
function parseSubscribeSettings(values: Record<string, unknown>): SubscribeSettings {
    const issues: string[] = [];
    const interestActions = Object.entries(values)
        .filter(([key, value]) => /interestaction/i.test(key) && value !== null && value !== undefined)
        .map(([, value]) => (typeof value === 'string' ? value.trim() : JSON.stringify(value)));
    return {
        InterestNames: parseInterestNames(values.SubscribeInterestNames, issues),
        FieldDefinitions: parseFieldDefinitions(values.SubscribeFieldDefinitions, issues),
        InterestActions: interestActions,
        Issues: issues,
    };
}

function parseInterestNames(raw: unknown, issues: string[]): string[] | undefined {
    if (raw === undefined || raw === null) return undefined;
    const parsed = z.array(z.string().trim().min(1)).safeParse(raw);
    if (!parsed.success) {
        issues.push('SubscribeInterestNames must be a JSON array of non-empty interest names');
        return undefined;
    }
    return [...new Set(parsed.data)];
}

function parseFieldDefinitions(raw: unknown, issues: string[]): InformzSubscribeFieldDefinition[] | undefined {
    if (raw === undefined || raw === null) return undefined;
    const parsed = z.array(ZSubscribeFieldDefinition).safeParse(raw);
    if (!parsed.success) {
        issues.push('SubscribeFieldDefinitions must be a JSON array of { Name, DataType?, DefaultValue? } objects');
        return undefined;
    }
    const seen = new Set<string>();
    const out: InformzSubscribeFieldDefinition[] = [];
    for (const d of parsed.data) {
        const key = d.Name.toLowerCase();
        if (seen.has(key)) {
            issues.push(`SubscribeFieldDefinitions declares "${d.Name}" more than once`);
            continue;
        }
        seen.add(key);
        const definition: InformzSubscribeFieldDefinition = { Name: d.Name, DataType: d.DataType ?? DEFAULT_FIELD_DATA_TYPE };
        if (d.DefaultValue !== undefined && d.DefaultValue !== null) definition.DefaultValue = String(d.DefaultValue);
        out.push(definition);
    }
    return out;
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

function zodIssues(error: z.ZodError): string {
    return error.issues.map(i => `${i.path.join('.') || '(root)'}: ${i.message}`).join('; ');
}

// ─── Pure helpers: write guard + document ─────────────────────────────────────────────────────────

/**
 * C4: the ONLY interest action a per-record push may send is the keyed add-or-update one. Any other
 * value, from metadata or a connection setting, is a configuration error before any request.
 */
function guardInterestAction(value: string, source: string): void {
    if (value === ALLOWED_INTEREST_ACTION) return;
    // Refuses ReplaceAllSubscribers above all: it empties the interest of everyone not in the document.
    throw configurationError(`${source} is "${value}", but a per-record push only ever sends InterestAction ${ALLOWED_INTEREST_ACTION}; any other interest action is refused before any request is made`);
}

/** Connection Subscribe settings must be valid and must not try to change the interest action. */
function assertSubscribeSettings(connection: InformzConnectionConfig): void {
    const issues = connection.SubscribeSettingIssues ?? [];
    if (issues.length > 0) throw configurationError(`the connection's Subscribe settings are invalid: ${issues.join('; ')}`);
    for (const value of connection.InterestActionOverrides ?? []) {
        guardInterestAction(value, 'the connection Configuration InterestAction');
    }
}

/** Element / document / action names become TAGS, which cannot be escaped — they must be XML names. */
function assertXmlNames(objectName: string, names: string[]): void {
    const bad = names.filter(n => !/^[A-Za-z_][\w.-]*$/.test(n));
    if (bad.length > 0) {
        throw configurationError(`IntegrationObject "${objectName}" writeActions names ${bad.map(n => `"${n}"`).join(', ')}, which are not XML element names`);
    }
}

/** writeActions.elements resolved against the Declared fields, in declaration (= document) order. */
function writeElements(
    objectName: string,
    action: InformzWriteAction,
    fields: MJIntegrationObjectFieldEntity[],
    index: Map<string, string>,
): WriteElement[] {
    const required = new Set(action.requiredElements ?? []);
    const identity = new Set(action.identity.conditions.map(c => c.toLowerCase()));
    const missingRequired = [...required].filter(r => !(r in action.elements));
    if (missingRequired.length > 0) {
        throw configurationError(`IntegrationObject "${objectName}" writeActions requiredElements ${missingRequired.join(', ')} are not mapped in writeActions.elements`);
    }
    const elements = Object.entries(action.elements).map(([element, fieldName]): WriteElement => {
        const field = fields.find(f => f.Name === index.get(fieldName.toLowerCase()));
        if (!field) throw configurationError(`IntegrationObject "${objectName}" writeActions.elements maps <${element}> to "${fieldName}", which is not a Declared field`);
        return { Element: element, Field: field.Name, Required: required.has(element), Integer: field.Type === 'integer', Identity: identity.has(field.Name.toLowerCase()) };
    });
    const unmapped = action.identity.conditions.filter(c => !elements.some(e => e.Field.toLowerCase() === c.toLowerCase()));
    if (unmapped.length > 0) {
        throw configurationError(`IntegrationObject "${objectName}" identity conditions ${unmapped.join(', ')} are not written by any writeActions element, so the read-back has no value for them`);
    }
    return elements;
}

function identityElement(spec: WriteSpec, field: string): WriteElement {
    const element = spec.Elements.find(e => e.Field.toLowerCase() === field.toLowerCase());
    if (!element) throw configurationError(`identity condition "${field}" of "${spec.Object.Name}" is not written by any element`);
    return element;
}

/**
 * C3: classifies every non-null attribute. An element's field → that element; a connection
 * SubscribeFieldDefinitions name → a `<Field>`; a Declared read-only field → dropped (vendor-owned);
 * anything else → a configuration error naming it (a demographic is never guessed).
 */
function draftWrite(spec: WriteSpec, attributes: Record<string, unknown>): WriteDraft {
    const byField = new Map(spec.Elements.map(e => [e.Field.toLowerCase(), e]));
    const definitions = new Map(spec.FieldDefinitions.map(d => [d.Name.toLowerCase(), d]));
    const draft: WriteDraft = { Elements: new Map(), Fields: [] };
    for (const [key, raw] of Object.entries(attributes)) {
        if (raw === null || raw === undefined) continue;
        const canonical = (spec.FieldIndex.get(key.toLowerCase()) ?? key).toLowerCase();
        const element = byField.get(canonical);
        const definition = element ? undefined : definitions.get(key.toLowerCase()) ?? definitions.get(canonical);
        if (element) setOnce(draft.Elements, element.Element, scalarText(raw, key).trim(), key);
        else if (definition) addField(draft, definition, scalarText(raw, key), key);
        else if (!spec.ReadOnlyFields.has(canonical)) {
            throw configurationError(`attribute "${key}" of "${spec.Object.Name}" is neither a writeActions element, a connection SubscribeFieldDefinitions element nor a read-only Declared field, so it cannot be written (a demographic field is never guessed)`);
        }
    }
    if (draft.Elements.size === 0 && draft.Fields.length === 0) {
        throw new InformzWriteRefusal(`${INTEGRATION_NAME}: the "${spec.Object.Name}" write carries no writable attribute (no writeActions element and no connection-configured Field); nothing was sent.`, STATUS_UNPROCESSABLE);
    }
    return draft;
}

function setOnce(target: Map<string, string>, element: string, value: string, key: string): void {
    const prior = target.get(element);
    if (prior !== undefined && prior !== value) throw configurationError(`two attributes (one is "${key}") map to <${element}> with different values`);
    target.set(element, value);
}

function addField(draft: WriteDraft, definition: InformzSubscribeFieldDefinition, value: string, key: string): void {
    if (draft.Fields.some(f => f.Definition === definition)) throw configurationError(`two attributes (one is "${key}") map to the Field element "${definition.Name}"`);
    draft.Fields.push({ Definition: definition, Value: value });
}

/** Text form of one attribute value; objects/arrays have none and are refused. */
function scalarText(value: unknown, key: string): string {
    if (typeof value === 'string') return value;
    if (typeof value === 'number' && Number.isFinite(value)) return String(value);
    if (typeof value === 'bigint' || typeof value === 'boolean') return String(value);
    if (value instanceof Date && !Number.isNaN(value.getTime())) return value.toISOString();
    throw new InformzWriteRefusal(`${INTEGRATION_NAME}: attribute "${key}" carries a value with no XML text form; nothing was sent.`, STATUS_UNPROCESSABLE);
}

/** Required elements present and non-blank; integer-typed elements are integer literals. Before any request. */
function completeElements(spec: WriteSpec, values: Map<string, string>): Map<string, string> {
    for (const element of spec.Elements) {
        const value = values.get(element.Element) ?? '';
        if (element.Required && value.length === 0) {
            throw new InformzWriteRefusal(`${INTEGRATION_NAME}: <${element.Element}> (field "${element.Field}") is required by ${spec.Label.Request} but is absent or blank; nothing was sent.`, STATUS_UNPROCESSABLE);
        }
        if (value.length > 0 && element.Integer && !/^-?\d+$/.test(value)) {
            throw new InformzWriteRefusal(`${INTEGRATION_NAME}: <${element.Element}> (field "${element.Field}") must be an integer; nothing was sent.`, STATUS_UNPROCESSABLE);
        }
    }
    return values;
}

/**
 * Update: an element the attributes do not carry comes from the stored row. An identity element that
 * differs from a stored non-blank value is refused (WRITE_STUDY.md gaps 6-7, 360032697272: whether
 * Subscribe can change it, and which key AddOrUpdate matches on, is undocumented). Values are not echoed.
 */
function withStoredIdentity(spec: WriteSpec, given: Map<string, string>, stored: Record<string, unknown>, externalID: string): Map<string, string> {
    const merged = new Map(given);
    for (const element of spec.Elements) {
        const current = (scalarOrNull(stored[element.Field]) ?? '').trim();
        const incoming = given.get(element.Element) ?? '';
        if (incoming.length === 0) {
            if (current.length > 0) merged.set(element.Element, current);
            continue;
        }
        if (element.Identity && current.length > 0 && !sameIdentityValue(incoming, current)) {
            throw new InformzWriteRefusal(
                `${INTEGRATION_NAME}: the update would change <${element.Element}> (field "${element.Field}") of "${spec.Object.Name}" ${externalID} from its stored value. `
                + 'An identity change is never pushed: whether Subscribe can change it and which key AddOrUpdateSubscribers matches on are undocumented; nothing was sent.',
                STATUS_CONFLICT,
            );
        }
    }
    return merged;
}

function sameIdentityValue(a: string, b: string): boolean {
    if (/^-?\d+$/.test(a) && /^-?\d+$/.test(b)) return BigInt(a) === BigInt(b);
    return a.trim().toLowerCase() === b.trim().toLowerCase();
}

/**
 * The ActionRequest (WRITE_STUDY.md order): credential block (the GridRequest's), then
 * Actions > <action> > InterestDetails (InterestNames only when configured, then InterestAction) >
 * SubscriberData (FieldDefinitions only for Fields sent, then Subscribers > Subscriber with the
 * elements in declaration order and Fields last). Every value is escaped; absent values are omitted.
 */
function buildActionDocument(auth: InformzAuthContext, spec: WriteSpec, values: Map<string, string>, fields: WriteFieldValue[]): string {
    const a = spec.Action;
    return `<${a.document} xmlns="${escapeXml(auth.Transport.MessageNamespace)}">`
        + credentialBlock(auth.Connection)
        + `<Actions><${a.action}>`
        + interestDetailsXml(spec.InterestNames, a.interestAction)
        + subscriberDataXml(spec.Elements, values, fields)
        + `</${a.action}></Actions></${a.document}>`;
}

function interestDetailsXml(names: string[], interestAction: string): string {
    guardInterestAction(interestAction, 'the interest action about to be serialised');
    const list = names.length > 0 ? `<InterestNames>${names.map(n => `<InterestName>${escapeXml(n)}</InterestName>`).join('')}</InterestNames>` : '';
    return `<InterestDetails>${list}<InterestAction>${escapeXml(interestAction)}</InterestAction></InterestDetails>`;
}

function subscriberDataXml(elements: WriteElement[], values: Map<string, string>, fields: WriteFieldValue[]): string {
    const definitions = fields.length > 0 ? `<FieldDefinitions>${fields.map(f => fieldDefinitionXml(f.Definition)).join('')}</FieldDefinitions>` : '';
    const identity = elements.map(e => {
        const value = values.get(e.Element) ?? '';
        return value.length > 0 ? `<${e.Element}>${escapeXml(value)}</${e.Element}>` : '';
    }).join('');
    const data = fields.length > 0
        ? `<Fields>${fields.map(f => `<Field element="${escapeXml(f.Definition.Name)}">${escapeXml(f.Value)}</Field>`).join('')}</Fields>`
        : '';
    return `<SubscriberData>${definitions}<Subscribers><Subscriber>${identity}${data}</Subscriber></Subscribers></SubscriberData>`;
}

function fieldDefinitionXml(d: InformzSubscribeFieldDefinition): string {
    return `<FieldDefinition><Name>${escapeXml(d.Name)}</Name><DataType>${escapeXml(d.DataType)}</DataType>`
        + (d.DefaultValue !== undefined ? `<DefaultValue>${escapeXml(d.DefaultValue)}</DefaultValue>` : '')
        + '</FieldDefinition>';
}

/** Password, Brand@id (+ optional name), User — shared by GridRequest and ActionRequest. */
function credentialBlock(c: InformzConnectionConfig): string {
    return `<Password>${escapeXml(c.Password)}</Password>`
        + `<Brand id="${escapeXml(c.BrandID)}">${escapeXml(c.BrandName ?? '')}</Brand>`
        + `<User>${escapeXml(c.Username)}</User>`;
}

/** SOAP 1.1 envelope whose request-wrapper text is the XML-escaped AAPI document. */
function wrapEnvelope(t: InformzTransport, document: string): string {
    return `<?xml version="1.0" encoding="utf-8"?>`
        + `<s:Envelope xmlns:s="${SOAP11_ENVELOPE_NAMESPACE}"><s:Body>`
        + `<${t.Operation} xmlns="${escapeXml(t.MessageNamespace)}"><${t.RequestWrapper}>${escapeXml(document)}</${t.RequestWrapper}></${t.Operation}>`
        + `</s:Body></s:Envelope>`;
}

function gridLabel(gridType: string): RequestLabel {
    return { Subject: `grid "${gridType}"`, Request: `the GridRequest for grid "${gridType}"` };
}

function actionLabel(document: string, action: string, objectName: string): RequestLabel {
    return { Subject: `${document} ${action} for "${objectName}"`, Request: `the ${document} ${action} for "${objectName}"` };
}

// ─── Pure helpers: write results ──────────────────────────────────────────────────────────────────

/** C2: the only legitimate 403 — the engine skips the record with a warning. */
function readOnlyResult(objectName: string): CRUDResult {
    return { Success: false, StatusCode: STATUS_READ_ONLY_OBJECT, ErrorMessage: `${objectName} is read-only in Informz: writes are not supported` };
}

/** One read-back row → ExternalID; a row without the key is a conflict, never Success without an id. */
function identityResult(spec: WriteSpec, key: string | null): CRUDResult {
    if (key === null || key.trim().length === 0) {
        throw new InformzWriteRefusal(`${INTEGRATION_NAME}: the identity read-back for "${spec.Object.Name}" returned a row without ${spec.ReadbackKey}; no ExternalID can be linked.`, STATUS_CONFLICT);
    }
    return { Success: true, StatusCode: STATUS_OK, ExternalID: key.trim() };
}

function identityConflict(spec: WriteSpec, rows: number, when: string): InformzWriteRefusal {
    const why = rows === 0
        ? 'found no row, so the vendor id cannot be established'
        : `found ${rows} or more rows, so the record is ambiguous and is never guessed`;
    const conditions = spec.Action.identity.conditions.join(' AND ');
    return new InformzWriteRefusal(`${INTEGRATION_NAME}: the "${spec.Object.Name}" identity read-back (${conditions}) ${why} ${when}. No ExternalID is returned; the record is re-sent on the next push.`, STATUS_CONFLICT);
}

/** Gap 3 safe default: Status must be success, and neither the Message count nor InvalidSubscribers may report one. */
function assertActionSucceeded(label: RequestLabel, body: unknown): void {
    if (!isActionOutcome(body)) {
        throw new InformzAPIError(`${LOG_PREFIX} expected a parsed ActionResponse outcome from MakeHTTPRequest.`, 'Protocol', null, {}, null);
    }
    const succeeded = (body.Status ?? '').trim().toLowerCase() === ACTION_STATUS_SUCCESS;
    if (succeeded && body.InvalidCount === 0) return;
    const invalid = body.InvalidCount > 0 ? `; ${body.InvalidCount} invalid subscriber(s) reported` : '';
    const message = body.Message ? `; message: ${preview(body.Message)}` : '';
    throw new InformzWriteRefusal(`${INTEGRATION_NAME} AAPI did not accept ${label.Request}: status "${body.Status ?? 'none'}"${invalid}${message}. Nothing was linked.`, STATUS_UNPROCESSABLE);
}

/**
 * C5 status for a thrown failure: 429/503/transport → 503; configuration and request defects → 400;
 * credential / brand-IP precondition → 401; anything unclassified → 502. Never 403. A fault from a
 * read-back GridRequest is re-classified with the write fault classes (ErrorContract ∪ WriteContract).
 */
function writeFailure(err: unknown, writeClasses: InformzFaultClasses | null): CRUDResult {
    if (err instanceof InformzWriteRefusal) return { Success: false, StatusCode: err.StatusCode, ErrorMessage: err.message };
    if (!(err instanceof InformzAPIError)) {
        return { Success: false, StatusCode: STATUS_INTERNAL_ERROR, ErrorMessage: `${INTEGRATION_NAME} write failed: ${safeMessage(err)}` };
    }
    if (err.Retryable) return { Success: false, StatusCode: STATUS_SERVICE_UNAVAILABLE, ErrorMessage: err.message };
    const classification = err.FaultCode && writeClasses ? classifyFault(err.FaultCode, writeClasses) : err.Classification;
    const status = classification === 'Configuration' || classification === 'RequestDefect' ? STATUS_BAD_REQUEST
        : classification === 'AuthOrPrecondition' ? STATUS_UNAUTHORIZED
        : STATUS_BAD_GATEWAY;
    return { Success: false, StatusCode: status, ErrorMessage: err.message };
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
    return { ServiceURL: serviceURLOf(parsed, apiPath), Page: { StartRow: startRow, NumberOfRows: rows, SortField: sortField } };
}

/** The real service URL behind a LOGICAL path (`/grids/<token>`, `/actions/<name>`): the suffix is removed. */
function serviceURLOf(parsed: URL, apiPath: string): string {
    const logical = apiPath.replace(/\/+$/, '');
    if (logical.length > 0 && parsed.pathname.toLowerCase().endsWith(logical.toLowerCase())) {
        parsed.pathname = parsed.pathname.slice(0, parsed.pathname.length - logical.length) || '/';
    }
    return parsed.search.length > 0 ? parsed.toString() : `${parsed.origin}${parsed.pathname}`;
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

/**
 * `ActionResponse > Responses > <action>` (tags matched case-insensitively): ActionStatus Status +
 * Message, and the invalid-subscriber count as max(Message "N invalid addresses", InvalidSubscribers
 * children). SubscriberCounts is never read (0 for 3 added records in the documented sample).
 */
function readActionOutcome(document: Record<string, unknown>, action: string): InformzActionOutcome | null {
    const response = childObject(childObject(childObject(document, 'actionresponse'), 'responses'), action.toLowerCase());
    if (!response) return null;
    const status = childObject(response, 'actionstatus');
    const message = xmlText(status?.message);
    return {
        Kind: 'InformzActionOutcome',
        Status: xmlText(status?.status),
        Message: message,
        InvalidCount: Math.max(invalidCountFromMessage(message), invalidEntryCount(response.invalidsubscribers)),
    };
}

function invalidCountFromMessage(message: string | null): number {
    const match = /(\d+)\s+invalid\s+address/i.exec(message ?? '');
    return match ? Number.parseInt(match[1], 10) : 0;
}

/** Children of `<InvalidSubscribers>` (shape undocumented): every element child counts; so does bare text. */
function invalidEntryCount(node: unknown): number {
    if (typeof node === 'string') return node.trim().length > 0 ? 1 : 0;
    if (!isPlainObject(node)) return 0;
    let count = 0;
    for (const [key, value] of Object.entries(node)) {
        if (key.startsWith('@')) continue;
        if (key === '#text') count += typeof value === 'string' && value.trim().length > 0 ? 1 : 0;
        else count += asArray(value).length;
    }
    return count;
}

function isActionOutcome(value: unknown): value is InformzActionOutcome {
    return isPlainObject(value) && value.Kind === 'InformzActionOutcome' && typeof value.InvalidCount === 'number';
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

function faultError(
    classes: InformzFaultClasses,
    label: RequestLabel,
    wire: InformzWireResponse,
    fault: ParsedFault,
    secret: string,
): InformzAPIError {
    const classification = classifyFault(fault.Code, classes);
    const message = redact(faultMessage(classification, label.Request, fault), secret);
    return new InformzAPIError(message, classification, wire.Status, wire.Headers, fault.Code);
}

/** `request` names what was sent, e.g. `the GridRequest for grid "x"` or `the ActionRequest Subscribe for "X"`. */
function faultMessage(classification: InformzErrorClassification, request: string, fault: ParsedFault): string {
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
        return `${INTEGRATION_NAME} AAPI rejected ${request} as a request defect (${code})${detail}. Retrying the same request will not help.`;
    }
    if (!fault.HasDetail) {
        return `${INTEGRATION_NAME} AAPI answered ${request} with a generic SOAP fault (${code})${detail} and no AAPI fault detail. `
            + 'Higher Logic answers this way when the credentials or the brand\'s registered IP address are not accepted: verify the connection configuration and the brand-IP registration.';
    }
    return `${INTEGRATION_NAME} AAPI answered ${request} with SOAP fault ${code}${detail}.`;
}

function throttleError(wire: InformzWireResponse, subject: string): InformzAPIError {
    const retryAfter = wire.Headers['retry-after'];
    return new InformzAPIError(
        `${INTEGRATION_NAME} AAPI rate limit / temporary unavailability: HTTP ${wire.Status} for ${subject}${retryAfter ? ` (Retry-After ${retryAfter})` : ''}.`,
        'Throttled', wire.Status, wire.Headers, null,
    );
}

function httpError(wire: InformzWireResponse, subject: string, secret: string): InformzAPIError {
    const contentType = wire.Headers['content-type'];
    const hint = wire.Status >= 300 && wire.Status < 400
        ? ' The redirect was not followed (credentials are never re-posted elsewhere); check the ServiceURL configuration.'
        : (wire.Status === 401 || wire.Status === 403 || wire.Status === 404 ? ' Check the ServiceURL / Region configuration of this connection.' : '');
    const message = `${INTEGRATION_NAME} AAPI answered HTTP ${wire.Status} for ${subject} without a SOAP fault`
        + `${contentType ? ` (content-type ${contentType})` : ''}: ${preview(wire.Text)}.${hint}`;
    return new InformzAPIError(redact(message, secret), 'HTTP', wire.Status, wire.Headers, null);
}

function protocolError(subject: string, wire: InformzWireResponse, detail: string): InformzAPIError {
    return new InformzAPIError(
        `${INTEGRATION_NAME} AAPI answered HTTP ${wire.Status} for ${subject} but ${detail}.`,
        'Protocol', wire.Status, wire.Headers, null,
    );
}

function transportError(err: unknown, subject: string, timeoutMs: number, secret: string): InformzAPIError {
    const timedOut = err instanceof Error && (err.name === 'TimeoutError' || err.name === 'AbortError');
    const message = timedOut
        ? `${INTEGRATION_NAME} AAPI request for ${subject} timed out after ${timeoutMs}ms.`
        : `${INTEGRATION_NAME} AAPI transport failure for ${subject}: ${safeMessage(err)}`;
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

/** A normalized record value as text (numbers / booleans stringified); null for null, undefined and objects. */
function scalarOrNull(value: unknown): string | null {
    if (typeof value === 'string') return value;
    if (typeof value === 'number' || typeof value === 'bigint' || typeof value === 'boolean') return String(value);
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
