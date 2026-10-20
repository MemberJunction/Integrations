/**
 * SpektrixConnector — Spektrix API v3 (System Owner mode) integration connector.
 *
 * ─── Design note — what this vendor actually is ──────────────────────────────────────────────────
 *
 * Spektrix v3 is a resource-oriented REST API, but four facts recorded in the frozen metadata
 * (`Integration.Configuration` + each `IntegrationObject.Configuration`) shape every override here:
 *
 *   1. EVERY REQUEST IS SIGNED. `Configuration.AuthScheme` (SpektrixAPI3): a `Date` header plus
 *      `Authorization: SpektrixAPI3 <ApiLoginName>:<Signature>`, where the signature is
 *      BASE64(HMAC-SHA1(BASE64-DECODE(ApiSecretKey), UTF-8(METHOD \n FULL-URL \n DATE [\n BASE64(MD5(body))])))
 *      over the byte-identical URL that goes on the wire. `BuildHeaders` has no method/URL/body, so
 *      signing happens inside {@link SpektrixConnector.MakeHTTPRequest}; the crypto itself lives in
 *      the engine's shared auth-helpers (`DecodeBase64SigningKey` / `ComputeHmacBase64` /
 *      `ComputeBodyMd5Base64`) — no inline crypto here.
 *
 *   2. THE OBJECT UNIVERSE IS LARGER THAN ITS DOORS. Customer has no list door at all (every direct
 *      GET needs an id or a lookup value); it and every Order line item arrive NESTED inside the
 *      `/orders` door. Each IO declares `Configuration.accessPath` (door path, nesting segments, an
 *      optional `parentTag`), and record collections are pulled in with `$expand`
 *      (`Configuration.expand` / `DefaultQueryParams`). The connector walks that access path
 *      generically — no object name appears in this file.
 *
 *   3. NO PAGINATION, BUT DATE WINDOWS. `Configuration.PaginationCapability` is proven-negative; the
 *      vendor instead advises small date batches for the heavy doors. Objects that declare
 *      `Configuration.fetchWindow` (or inherit their door's `accessPath.doorFetchWindow`) are read in
 *      calendar-month windows using the EXACT per-object parameter names from metadata
 *      (`instanceStart_from`/`instanceStart_to`, `startFrom`/`startTo`, `DateFrom`/`DateTo`,
 *      `start_from`/`start_to`), resumable through `NextAfterKeyValue`. Window start, size and
 *      horizon come from the CONNECTION's Configuration — no date is baked in here.
 *
 *   4. TENANT-SPECIFIC CUSTOM PROPERTIES. `attribute_*` keys are per tenant
 *      (`Configuration.CustomAttributes`), never declared. Every fetched record reaches
 *      `ExternalRecord.Fields` in full, and `IntrospectSchema` unions the Declared fields with a
 *      live sample so the tenant's customs reach the schema.
 *
 * Per-call object identity (which object, which window, whether a template-var child is being read)
 * rides an AsyncLocalStorage scope, because the base class's `AppendDefaultQueryParams` /
 * `NormalizeResponse` / `MakeHTTPRequest` hooks carry no object argument and the engine may run
 * several objects concurrently — a mutable instance field would cross the wires.
 */
import { AsyncLocalStorage } from 'node:async_hooks';
import { z } from 'zod';
import { RegisterClass } from '@memberjunction/global';
import { UUIDMap } from './UUIDMap.js';
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
    type ErrorSeverity,
    type ExternalRecord,
    type FetchBatchResult,
    type FetchContext,
    type FetchWarning,
    type GetRecordContext,
    type IntrospectSchemaOptions,
    type PaginationState,
    type PaginationType,
    type RESTAuthContext,
    type RESTResponse,
    type SourceSchemaInfo,
    type SyncErrorCode,
    type UpdateRecordContext,
} from '@memberjunction/integration-engine';
import { ComputeBodyMd5Base64, ComputeHmacBase64, DecodeBase64SigningKey, HmacKeyFormatError } from './HmacRequestSigner.js';
import { MAX_HONORED_RETRY_AFTER_MS, ParseRetryAfterValue } from './RetryAfter.js';

// ── Forward compatibility with the 6.x engine ──────────────────────────────────────────────────
// This Open App compiles against the published 5.x engine (peer range >=5.43 <7). The 6.x engine adds
// the optional fields below; declaring them optional keeps 5.x hosts working (they are simply absent)
// while 6.x hosts still pass and honour them at runtime.
type CompatIntrospectSchemaOptions = IntrospectSchemaOptions & { OnProgress?: (done: number, total: number) => void };
type CompatFetchContext = FetchContext & { IsDiscoverySample?: boolean; SampleTargetRecords?: number; DeadlineMs?: number };
/** 6.x base signature (deadline + watch key); the 5.x base takes the first five and ignores the rest. */
type DiscoverySampleStreamFn = (companyIntegration: MJCompanyIntegrationEntity, objectName: string, contextUser: UserInfo, batchSize: number, maxRecords: number, deadlineMs?: number, watchKey?: string) => AsyncGenerator<Record<string, unknown>>;
import { mergeDeclaredWithSampledFields } from '@memberjunction/connector-schema-merge';

// ─── Metadata shapes (Zod) ────────────────────────────────────────────────────────────────────────
// Every value read out of a Configuration JSON blob is validated here. A malformed individual key
// degrades to `undefined` (`.catch`) instead of discarding the whole blob.

const ZFetchWindowSpec = z.object({
    fromParam: z.string().min(1),
    toParam: z.string().min(1),
    format: z.string().nullable().optional(),
}).passthrough();

const ZParentTag = z.object({
    fromObject: z.string().min(1),
    fromField: z.string().min(1),
    asField: z.string().min(1),
}).passthrough();

const ZAccessPath = z.object({
    doorObject: z.string().optional().catch(undefined),
    doorPath: z.string().optional().catch(undefined),
    nestingFieldPath: z.string().optional().catch(undefined),
    nestingSegments: z.array(z.string()).optional().catch(undefined),
    parentTag: ZParentTag.optional().catch(undefined),
    doorFetchWindow: ZFetchWindowSpec.optional().catch(undefined),
}).passthrough();

const ZUnionAccessPath = z.object({
    nestingFieldPath: z.string().min(1),
    recursive: z.boolean().optional(),
    parentKeyField: z.string().optional(),
    expand: z.string().optional(),
}).passthrough();

const ZDoor = z.object({
    op: z.string().optional().catch(undefined),
    kind: z.string().optional().catch(undefined),
    modes: z.array(z.string()).optional().catch(undefined),
}).passthrough();

const ZAlternateDoor = z.object({
    door: z.string().min(1),
    doorKind: z.string().optional(),
}).passthrough();

const ZCollection = z.object({
    field: z.string().min(1),
    itemType: z.string().optional(),
    io: z.string().optional(),
}).passthrough();

const ZObjectConfig = z.object({
    door: ZDoor.optional().catch(undefined),
    accessPath: ZAccessPath.optional().catch(undefined),
    fetchWindow: ZFetchWindowSpec.optional().catch(undefined),
    expand: z.array(z.string()).optional().catch(undefined),
    unionAccessPaths: z.array(ZUnionAccessPath).optional().catch(undefined),
    parentObjectName: z.string().optional().catch(undefined),
    parentObjectIDFieldName: z.string().optional().catch(undefined),
    alternateDoors: z.array(ZAlternateDoor).optional().catch(undefined),
    collections: z.array(ZCollection).optional().catch(undefined),
    customAttributePrefix: z.string().optional().catch(undefined),
    ioKind: z.string().optional().catch(undefined),
}).passthrough();

/** A collection's documented WRITE item shape: write key → dotted read path (IOF `Configuration.writeShape`). */
const ZWriteShape = z.object({
    itemProjection: z.record(z.string(), z.string()).optional().catch(undefined),
}).passthrough();

const ZFieldConfig = z.object({
    valuePath: z.string().min(1).optional().catch(undefined),
    specType: z.string().optional().catch(undefined),
    writeShape: ZWriteShape.optional().catch(undefined),
}).passthrough();

const ZIntegrationConfig = z.object({
    BaseURLTemplate: z.string().optional().catch(undefined),
}).passthrough();

const ZWindowOverride = z.object({
    start: z.string().optional().catch(undefined),
    end: z.string().optional().catch(undefined),
    horizonMonths: z.number().int().min(0).optional().catch(undefined),
    days: z.number().int().positive().optional().catch(undefined),
}).passthrough();

const ZConnectionSettings = z.object({
    BaseURL: z.string().optional().catch(undefined),
    fetchWindowStart: z.string().optional().catch(undefined),
    fetchWindowEnd: z.string().optional().catch(undefined),
    fetchWindowHorizonMonths: z.number().int().min(0).optional().catch(undefined),
    fetchWindowDays: z.number().int().positive().optional().catch(undefined),
    fetchWindows: z.record(z.string(), ZWindowOverride).optional().catch(undefined),
    requestTimeoutMs: z.number().int().positive().optional().catch(undefined),
    rateLimitRetries: z.number().int().min(0).optional().catch(undefined),
}).passthrough();

type SpektrixObjectConfig = z.infer<typeof ZObjectConfig>;
type SpektrixFetchWindowSpec = z.infer<typeof ZFetchWindowSpec>;
type SpektrixAccessPath = z.infer<typeof ZAccessPath>;
type SpektrixConnectionSettings = z.infer<typeof ZConnectionSettings>;

// ─── Operational defaults (policy, not vendor data — every one is overridable per connection) ────

const LOG_PREFIX = '[spektrix]';
/** Resolved credentials are re-read after this long, so a rotated secret takes effect without a restart. */
const AUTH_CACHE_TTL_MS = 5 * 60_000;
/** Per-request socket budget (`Configuration.requestTimeoutMs`). */
const DEFAULT_REQUEST_TIMEOUT_MS = 60_000;
/** In-request 429 retries honouring Retry-After (`Configuration.rateLimitRetries`); the engine retries further. */
const DEFAULT_RATE_LIMIT_RETRIES = 2;
/** Months ahead of today the window plan reaches when no explicit end is configured. */
const DEFAULT_WINDOW_HORIZON_MONTHS = 12;
/** A windowed FetchChanges stops opening new windows after this long, so one call never outlives its timeout. */
const WINDOW_CALL_BUDGET_MS = 60_000;
/** Safety bound on recursive same-object unions (Plan → areas → areas …). */
const MAX_UNION_DEPTH = 32;
/** Opaque resume-cursor prefix for windowed reads (`NextAfterKeyValue`). */
const WINDOW_CURSOR_PREFIX = 'window:';
/** The only representation this connector parses; the API also serves text/xml. */
const JSON_MEDIA_TYPE = 'application/json';

// ─── Public types ─────────────────────────────────────────────────────────────────────────────────

/** The per-connection credential values (from the `MJ: Credentials` record, else connection Configuration). */
interface SpektrixCredentialValues {
    ClientName?: string;
    ApiLoginName?: string;
    ApiSecretKey?: string;
    BaseURL?: string;
}

/** Resolved, ready-to-sign auth for one connection. The decoded key never leaves process memory. */
export interface SpektrixAuthContext extends RESTAuthContext {
    ApiLoginName: string;
    SigningKey: Buffer;
    BaseURL: string;
    RequestTimeoutMs: number;
    RateLimitRetries: number;
}

/** Inputs to the SpektrixAPI3 signature. */
export interface SpektrixSignatureInput {
    LoginName: string;
    SigningKey: Buffer;
    Method: string;
    /** The exact URL that goes on the wire, query string included. */
    Url: string;
    /** The exact `Date` header value (RFC 7231, UTC). */
    DateHeader: string;
    /** The exact request body text, when the request carries one. */
    Body?: string;
}

/** One date window: `From` inclusive, `To` the next window's start (ISO `YYYY-MM-DD`). */
export interface SpektrixDateWindow {
    From: string;
    To: string;
}

/** A classified vendor failure, kept structured so the engine can route it. */
export interface SpektrixErrorClassification {
    Code: SyncErrorCode;
    Severity: ErrorSeverity;
    Retryable: boolean;
    Reason: string;
}

/**
 * A Spektrix HTTP failure. The `message` carries only fixed classification phrases (the engine's
 * `ClassifyError` reads message text, so a vendor id containing "429" must never leak into it);
 * the vendor's own text is kept on {@link SpektrixAPIError.VendorMessage}.
 */
export class SpektrixAPIError extends Error {
    public constructor(
        message: string,
        public readonly Status: number,
        public readonly Headers: Record<string, string>,
        public readonly Classification: SpektrixErrorClassification,
        public readonly VendorMessage?: string,
    ) {
        super(message);
        this.name = 'SpektrixAPIError';
    }
}

// ─── Internal types ───────────────────────────────────────────────────────────────────────────────

type SpektrixCallVerb = 'read' | 'get' | 'test' | 'write';

/** Where the leaf rows of an object live inside its door's response body. */
interface ReadPlan {
    /** Wire keys to descend, outermost first (`[]` markers stripped). Empty = the door rows ARE the records. */
    Segments: string[];
    /** Copies a key from an ancestor onto each leaf (`accessPath.parentTag`). */
    ParentTag: ResolvedParentTag | null;
    /** Recursive same-object collections unioned into the record set (`unionAccessPaths`). */
    Unions: ResolvedUnion[];
}

interface ResolvedParentTag {
    /** Index into a leaf's ancestor chain (0 = the door record). */
    AncestorIndex: number;
    FromField: string;
    AsField: string;
}

interface ResolvedUnion {
    Field: string;
    Recursive: boolean;
    ParentKeyField: string | null;
    KeyField: string | null;
}

interface WalkNode {
    Record: Record<string, unknown>;
    Ancestors: Record<string, unknown>[];
}

interface SpektrixWindowRequest {
    Spec: SpektrixFetchWindowSpec;
    Window: SpektrixDateWindow;
}

/** Which object / verb / window the current async call chain is serving. */
interface SpektrixCallScope {
    Verb: SpektrixCallVerb;
    ObjectName: string;
    APIPathTemplate: string;
    Read?: ReadPlan;
    Window?: SpektrixWindowRequest;
    /** True while the base class iterates a `{template-var}` child over its parents. */
    TemplateChild: boolean;
    Warnings: FetchWarning[];
    /** Parents the vendor answered JSON-404 ResourceNotFound for (treated as "no child rows"). */
    NotFoundParents: string[];
}

/** Per-object value transforms derived from IOF metadata (cached per field-cache generation). */
interface FieldTransformPlan {
    /** Typed references stored as one property of the referenced object (`Configuration.valuePath`). */
    Projections: Array<{ Field: string; ValuePath: string }>;
    /** Declared `json` columns whose source value is an embedded object (stored as JSON text). */
    EmbeddedJson: string[];
}

interface WindowSettings {
    Start: Date;
    EndExclusive: Date;
    WindowDays: number | null;
}

type WriteOperation = 'Create' | 'Update' | 'Delete';

interface WriteColumns {
    Path: string | null;
    Method: string | null;
    BodyShape: string | null;
    BodyKey: string | null;
    IDLocation: string | null;
}

interface ResolvedOperationPath {
    Path: string;
    /** Attribute keys that addressed the request (parent keys) — never repeated in the body. */
    ConsumedAttributeKeys: Set<string>;
    /** Every substituted `{var}` → its raw value. */
    PathValues: Record<string, string>;
}

// ─── Pure helpers ─────────────────────────────────────────────────────────────────────────────────

function isPlainObject(value: unknown): value is Record<string, unknown> {
    return value !== null && typeof value === 'object' && !Array.isArray(value) && !(value instanceof Date);
}

/** Reads a dotted path (`a.b.c`); a reference stored as a bare id (string / number) satisfies a trailing `.id` step. */
function readDottedPath(source: Record<string, unknown>, path: string): unknown {
    let current: unknown = source;
    const steps = path.split('.');
    for (let i = 0; i < steps.length; i++) {
        if (isPlainObject(current)) { current = current[steps[i]]; continue; }
        if ((typeof current === 'string' || typeof current === 'number') && i === steps.length - 1 && steps[i] === 'id') return current;
        return undefined;
    }
    return current;
}

function parseJSONObject(raw: string | null | undefined): Record<string, unknown> | null {
    if (!raw || typeof raw !== 'string') return null;
    try {
        const parsed: unknown = JSON.parse(raw);
        return isPlainObject(parsed) ? parsed : null;
    } catch {
        return null;
    }
}

function findKeyCaseInsensitive(source: Record<string, unknown>, name: string): string | null {
    if (Object.prototype.hasOwnProperty.call(source, name)) return name;
    const lower = name.toLowerCase();
    for (const key of Object.keys(source)) {
        if (key.toLowerCase() === lower) return key;
    }
    return null;
}

function readNonEmptyString(source: Record<string, unknown> | null, name: string): string | undefined {
    if (!source) return undefined;
    const key = findKeyCaseInsensitive(source, name);
    const value = key != null ? source[key] : undefined;
    return typeof value === 'string' && value.trim().length > 0 ? value : undefined;
}

function templateVarsOf(path: string): string[] {
    return [...path.matchAll(/\{(\w+)\}/g)].map(m => m[1]);
}

function joinURL(baseURL: string, apiPath: string): string {
    const base = baseURL.replace(/\/+$/, '');
    const path = apiPath.startsWith('/') ? apiPath : `/${apiPath}`;
    return `${base}${path}`;
}

/** Query-component encoding that keeps the characters Spektrix documents literally (`$expand=a/b,c`). */
function encodeQueryComponent(value: string): string {
    return encodeURIComponent(value).replace(/%24/g, '$').replace(/%2F/gi, '/').replace(/%2C/gi, ',');
}

function existingQueryKeys(url: string): Set<string> {
    const keys = new Set<string>();
    const q = url.indexOf('?');
    if (q < 0) return keys;
    for (const pair of url.slice(q + 1).split('&')) {
        const eq = pair.indexOf('=');
        const key = eq >= 0 ? pair.slice(0, eq) : pair;
        try {
            keys.add(decodeURIComponent(key).toLowerCase());
        } catch {
            keys.add(key.toLowerCase());
        }
    }
    return keys;
}

function appendQueryParams(url: string, params: Map<string, string>): string {
    if (params.size === 0) return url;
    const existing = existingQueryKeys(url);
    const parts: string[] = [];
    for (const [key, value] of params) {
        if (existing.has(key.toLowerCase())) continue;
        parts.push(`${encodeQueryComponent(key)}=${encodeQueryComponent(value)}`);
    }
    if (parts.length === 0) return url;
    return `${url}${url.includes('?') ? '&' : '?'}${parts.join('&')}`;
}

function isoDate(d: Date): string {
    return d.toISOString().slice(0, 10);
}

function utcMidnight(d: Date): Date {
    return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
}

function firstOfMonthOffsetUTC(d: Date, monthOffset: number): Date {
    return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + monthOffset, 1));
}

function addDaysUTC(d: Date, days: number): Date {
    return new Date(d.getTime() + days * 86_400_000);
}

/** Strict `YYYY-MM-DD` → UTC midnight; anything else (incl. impossible dates like 2026-02-31) → null. */
function parseISODate(value: string | undefined): Date | null {
    if (!value) return null;
    const trimmed = value.trim();
    const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(trimmed);
    if (!m) return null;
    const d = new Date(Date.UTC(Number(m[1]), Number(m[2]) - 1, Number(m[3])));
    return isoDate(d) === trimmed ? d : null;
}

/** `Configuration.ErrorContract["404-json"]`: `{ resourceType, resourceIdentifiers, errorCode, message }`. */
function isResourceNotFoundBody(body: unknown): body is Record<string, unknown> {
    return isPlainObject(body)
        && (typeof body.errorCode === 'string' || 'resourceType' in body || 'resourceIdentifiers' in body);
}

function parseResponseBody(text: string): unknown {
    if (text.length === 0) return null;
    try {
        return JSON.parse(text) as unknown;
    } catch {
        return text;
    }
}

function safeMessage(err: unknown): string {
    return err instanceof Error ? err.message : String(err);
}

function idFromBody(body: unknown): string | undefined {
    const candidate = Array.isArray(body) && body.length === 1 ? body[0] : body;
    if (!isPlainObject(candidate)) return undefined;
    const value = candidate.id;
    return typeof value === 'string' || typeof value === 'number' ? String(value) : undefined;
}

// ─── Signing + window planning (exported pure functions) ──────────────────────────────────────────

/**
 * The SpektrixAPI3 string-to-sign (`Configuration.AuthScheme.StringToSign`):
 * `UPPERCASE(method) \n full-URL \n Date` and, for every non-GET request,
 * `\n BASE64(MD5(UTF-8 body))` (an absent body hashes as the empty string).
 */
export function BuildSpektrixStringToSign(method: string, url: string, dateHeader: string, body?: string): string {
    const verb = method.toUpperCase();
    const head = `${verb}\n${url}\n${dateHeader}`;
    return verb === 'GET' ? head : `${head}\n${ComputeBodyMd5Base64(body ?? '')}`;
}

/** `SpektrixAPI3 <LoginName>:<BASE64(HMAC-SHA1(decoded key, UTF-8(StringToSign)))>`. */
export function BuildSpektrixAuthorization(input: SpektrixSignatureInput): string {
    const stringToSign = BuildSpektrixStringToSign(input.Method, input.Url, input.DateHeader, input.Body);
    return `SpektrixAPI3 ${input.LoginName}:${ComputeHmacBase64('sha1', input.SigningKey, stringToSign)}`;
}

/**
 * Splits `[start, endExclusive)` into consecutive windows: calendar months by default (no window
 * spans two months), or fixed `windowDays`-day windows when configured. Each window's `To` is the
 * next window's `From`, so a vendor that treats the upper bound as inclusive OR exclusive still
 * sees every instant exactly once or twice (boundary duplicates collapse on the record identity).
 */
export function BuildSpektrixDateWindows(start: Date, endExclusive: Date, windowDays: number | null): SpektrixDateWindow[] {
    const windows: SpektrixDateWindow[] = [];
    let cursor = utcMidnight(start);
    const end = utcMidnight(endExclusive);
    for (let guard = 0; cursor < end && guard < 10_000; guard++) {
        const next = windowDays && windowDays > 0 ? addDaysUTC(cursor, windowDays) : firstOfMonthOffsetUTC(cursor, 1);
        const to = next < end ? next : end;
        windows.push({ From: isoDate(cursor), To: isoDate(to) });
        cursor = next;
    }
    return windows;
}

// ─── Connector ────────────────────────────────────────────────────────────────────────────────────

@RegisterClass(BaseIntegrationConnector, 'SpektrixConnector')
export class SpektrixConnector extends BaseRESTIntegrationConnector {

    /** Object / verb / window of the current async call chain (see the design note). */
    private readonly callScope = new AsyncLocalStorage<SpektrixCallScope>();

    /** Resolved auth per connection (+ credential + Configuration), refreshed after {@link AUTH_CACHE_TTL_MS}. */
    private readonly authCache = new Map<string, { Context: SpektrixAuthContext; ExpiresAt: number }>();

    /** Warnings already logged, so a long sync logs honestly rather than noisily. */
    private readonly warnedOnce = new Set<string>();

    /** Parsed `IntegrationObject.Configuration`, per cached entity instance. */
    private readonly objectConfigs = new WeakMap<MJIntegrationObjectEntity, SpektrixObjectConfig>();

    /** Field transform plans per IntegrationObject ID, invalidated whenever the engine replaces its field cache. */
    private fieldPlans = new UUIDMap<FieldTransformPlan>();
    private fieldPlanSource: MJIntegrationObjectFieldEntity[] | null = null;

    // ── Identity ────────────────────────────────────────────────────────────────────────────────

    /** Verbatim `MJ: Integrations.Name` (T1 three-way invariant). */
    public override get IntegrationName(): string {
        return 'Spektrix';
    }

    // ── Capability getters — derived from the per-operation IO columns, never asserted ──────────

    public override get SupportsCreate(): boolean {
        return this.anyActiveObject(o => o.SupportsCreate && !!o.CreateAPIPath && !!o.CreateMethod);
    }

    public override get SupportsUpdate(): boolean {
        return this.anyActiveObject(o => o.SupportsUpdate && !!o.UpdateAPIPath && !!o.UpdateMethod);
    }

    public override get SupportsDelete(): boolean {
        return this.anyActiveObject(o => o.SupportsDelete && !!o.DeleteAPIPath && !!o.DeleteMethod);
    }

    /**
     * FALSE, permanently. `Configuration.DiscoveryIsAuthoritative` = false: no Spektrix endpoint
     * enumerates a tenant's object or attribute gamut, so absence from a sample proves nothing and
     * must never deactivate a persisted object or field.
     */
    public override get DiscoveryIsAuthoritative(): boolean {
        return false;
    }

    // ── Sync-efficiency hooks (each backed by a metadata fact) ──────────────────────────────────

    /**
     * ONE in flight. `Configuration.RateLimits.guidance`: numbers are undocumented and the vendor
     * advises sequential requests (wait for each response). `RateLimitPolicy` is deliberately left at
     * the base default (null) because `RateLimits.documentedNumbers` is null — no rate is invented.
     */
    public override get MaxConcurrencyHint(): number | null {
        return 1;
    }

    /**
     * A windowed read opens several date windows per call (bounded by {@link WINDOW_CALL_BUDGET_MS})
     * and a template-var child walks a batch of parents sequentially, each a signed request that may
     * wait out a Retry-After. 30s is too tight for that; `Configuration.fetchTimeoutMs` still wins.
     */
    public get FetchChangesTimeoutMs(): number | null { // a 6.x engine hook; inert on 5.x hosts
        return 180_000;
    }

    /** Strictly the object's own `StableOrderingKey` column — never synthesised. */
    public override StableOrderingKey(objectName: string): string | null {
        const integrationID = this.integrationIDByName();
        if (!integrationID) return null;
        try {
            return IntegrationEngineBase.Instance.GetIntegrationObject(integrationID, objectName)?.StableOrderingKey ?? null;
        } catch {
            return null;
        }
    }

    /** Reads the vendor's `Retry-After` off a {@link SpektrixAPIError}; anything else → the standard reader. */
    public override ExtractRetryAfterMs(error: unknown): number | undefined {
        if (error instanceof SpektrixAPIError) {
            return ParseRetryAfterValue(error.Headers['retry-after']);
        }
        return super.ExtractRetryAfterMs(error);
    }

    // ── Discovery ───────────────────────────────────────────────────────────────────────────────
    //
    // DiscoverObjects / DiscoverFields are DELIBERATELY NOT overridden: the Declared IO/IOF rows
    // (seeded credential-free from the vendor's public Help pages) ARE the standard schema of
    // record, and the base implementations read exactly those rows back — credential-free, so the
    // runtime structure self-check stays green without a token. A live credential is ADDITIVE: it
    // only adds the tenant's own `attribute_*` columns, via the sample-union below.

    /**
     * Declared ∪ live-sampled fields, so a tenant's custom `attribute_*` properties reach the schema
     * builder. Sampling runs SEQUENTIALLY (the vendor advises sequential requests); a sampling failure
     * leaves the DECLARED floor intact — the shared never-shrink merge only ever adds.
     */
    public override async IntrospectSchema(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
        options?: CompatIntrospectSchemaOptions,
    ): Promise<SourceSchemaInfo> {
        const info = await super.IntrospectSchema(companyIntegration, contextUser);
        const wanted = options?.ObjectNames && options.ObjectNames.length > 0 ? new Set(options.ObjectNames) : null;
        if (wanted) info.Objects = info.Objects.filter(o => wanted.has(o.ExternalName));
        let done = 0;
        for (const obj of info.Objects) {
            try {
                const sampled = await this.DiscoverFieldsViaFetch(companyIntegration, obj.ExternalName, contextUser);
                obj.Fields = mergeDeclaredWithSampledFields(obj.Fields, sampled);
            } catch (err) {
                this.warnOnce(
                    `introspect:${obj.ExternalName}`,
                    `${LOG_PREFIX} Live field sampling for "${obj.ExternalName}" failed (${safeMessage(err)}); the Declared field floor stands.`,
                );
            }
            done++;
            try { options?.OnProgress?.(done, info.Objects.length); } catch { /* progress never breaks introspection */ }
        }
        return info;
    }

    /**
     * Discovery-time sampling. A depth-0 / nested object samples through this connector's own
     * {@link FetchChanges} (windows + access paths included) via the base loop. A `{template-var}`
     * child is sampled here instead: the base sampler would read its parent through the parent's
     * raw APIPath, which for Spektrix is wrong twice over — Customer's APIPath is the `/orders` door
     * (the parent rows are nested), and `/instances` / `/events` must be read in date windows. So the
     * parent is streamed through {@link FetchChanges} and each parent's child route is read directly,
     * stopping at `maxRecords` or the deadline.
     */
    protected override async *DiscoverySampleRecordStream(
        companyIntegration: MJCompanyIntegrationEntity,
        objectName: string,
        contextUser: UserInfo,
        batchSize: number,
        maxRecords: number,
        deadlineMs?: number,
        watchKey?: string,
    ): AsyncGenerator<Record<string, unknown>> {
        const obj = this.GetCachedObject(companyIntegration.IntegrationID, objectName);
        const vars = templateVarsOf(obj.APIPath);
        if (vars.length === 0) {
            const baseStream: DiscoverySampleStreamFn = super.DiscoverySampleRecordStream.bind(this);
            yield* baseStream(companyIntegration, objectName, contextUser, batchSize, maxRecords, deadlineMs, watchKey);
            return;
        }
        yield* this.sampleTemplateChild(companyIntegration, contextUser, obj, vars, batchSize, maxRecords, deadlineMs);
    }

    // ── Connection test ─────────────────────────────────────────────────────────────────────────

    /**
     * Probes ONE System-Owner-only list door (Help `modes` = Owner only), so a bad signature cannot
     * pass by hitting a public Web-mode route. The probe is chosen from metadata (lowest-Sequence
     * active depth-0 door, un-windowed preferred); a windowed probe sends a one-day window. The
     * message never carries credential bytes.
     */
    public override async TestConnection(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<ConnectionTestResult> {
        try {
            const auth = await this.Authenticate(companyIntegration, contextUser);
            const probe = this.selectConnectionProbe(companyIntegration.IntegrationID);
            if (!probe) {
                return {
                    Success: false,
                    Message: `${LOG_PREFIX} No active System-Owner-only list door is declared in this integration's metadata, ` +
                        'so the request signature cannot be verified. Push metadata/integrations/spektrix before testing.',
                };
            }
            const url = this.connectionProbeURL(auth, probe);
            const scope = this.plainScope('test', probe);
            const response = await this.callScope.run(scope, () => this.MakeHTTPRequest(auth, url, 'GET', this.BuildHeaders(auth)));
            return this.describeConnectionProbe(response, probe);
        } catch (err) {
            return { Success: false, Message: safeMessage(err) };
        }
    }

    // ── Read path ───────────────────────────────────────────────────────────────────────────────

    /**
     * Routes one read by the object's DECLARED shape:
     *   - `{template-var}` child (`/customers/{customerId}/…`) → the base class iterates parents
     *     (Configuration.parentObjectName); a windowed child gets one full-span window per parent;
     *   - windowed door (own `fetchWindow` or its door's `doorFetchWindow`) → date windows;
     *   - anything else → one request.
     * Every path descends `accessPath.nestingSegments` inside {@link NormalizeResponse}, so nested
     * objects (Customer, Order line items, availability rows…) come out as leaf records.
     */
    public override async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
        const integrationID = ctx.CompanyIntegration.IntegrationID;
        const obj = this.GetCachedObject(integrationID, ctx.ObjectName);
        const cfg = this.objectConfig(obj);
        const plan = this.buildReadPlan(integrationID, obj, cfg);
        const spec = this.windowSpecFor(cfg);

        if (templateVarsOf(obj.APIPath).length > 0) {
            return this.fetchTemplateChildren(ctx, obj, plan, spec);
        }
        if (spec) {
            return this.fetchWindowed(ctx, obj, plan, spec);
        }
        const scope = this.readScope(obj, plan, undefined, false);
        const batch = await this.callScope.run(scope, () => super.FetchChanges(ctx));
        return this.withScopeWarnings(scope, batch);
    }

    /**
     * Door-request query: the object's `DefaultQueryParams`, ONE merged `$expand` (DefaultQueryParams
     * ∪ `Configuration.expand` ∪ every `unionAccessPaths[].expand`), and the in-scope date window
     * under the object's EXACT declared parameter names. Keys already on the URL are never duplicated.
     */
    protected override AppendDefaultQueryParams(url: string, obj: MJIntegrationObjectEntity): string {
        const cfg = this.objectConfig(obj);
        const params = new Map<string, string>();
        const expand: string[] = [];
        for (const [key, value] of Object.entries(parseJSONObject(obj.DefaultQueryParams) ?? {})) {
            if (value == null) continue;
            if (key.toLowerCase() === '$expand') {
                expand.push(...String(value).split(',').map(s => s.trim()).filter(s => s.length > 0));
                continue;
            }
            params.set(key, String(value));
        }
        expand.push(...(cfg.expand ?? []));
        for (const union of cfg.unionAccessPaths ?? []) {
            if (union.expand) expand.push(union.expand);
        }
        const uniqueExpand = [...new Set(expand)];
        if (uniqueExpand.length > 0) params.set('$expand', uniqueExpand.join(','));

        const scope = this.callScope.getStore();
        if (scope?.Window && scope.ObjectName === obj.Name) {
            params.set(scope.Window.Spec.fromParam, scope.Window.Window.From);
            params.set(scope.Window.Spec.toParam, scope.Window.Window.To);
        }
        return appendQueryParams(url, params);
    }

    /**
     * Bare JSON array → its objects; a bare OBJECT (system config, by-id and detail doors) → one
     * record; `ResponseDataKey` is applied ONLY where metadata declares one. Then, inside a read
     * scope, the object's access path is walked down to its leaf rows, ancestor keys are tagged on
     * (`parentTag`) and recursive same-object collections are unioned in (`unionAccessPaths`).
     * Leaves are passed through WHOLE — every source key reaches `ExternalRecord.Fields`.
     */
    protected override NormalizeResponse(rawBody: unknown, responseDataKey: string | null): Record<string, unknown>[] {
        const roots = this.stripEnvelope(rawBody, responseDataKey);
        const plan = this.callScope.getStore()?.Read;
        return plan ? this.walkReadPlan(roots, plan) : roots;
    }

    /** No paging parameter exists on any GET (`Configuration.PaginationCapability`, proven negative). */
    protected override ExtractPaginationInfo(
        _rawBody: unknown,
        _paginationType: PaginationType,
        _currentPage: number,
        _currentOffset: number,
        _pageSize: number,
    ): PaginationState {
        return { HasMore: false };
    }

    /**
     * Metadata-driven value shaping, per IOF (no key is ever dropped):
     *  - a typed reference whose IOF declares `Configuration.valuePath` ("stored as the referenced
     *    X.id") arrives as the referenced OBJECT and is stored as that one property;
     *  - a declared `json` column whose value is an embedded OBJECT is stored as its JSON text, so it
     *    lands in the declared column instead of being flattened away into `<name>_<child>` keys.
     * Collections (arrays) and undeclared keys (`attribute_*`) pass through untouched.
     */
    protected override TransformRecord(
        raw: Record<string, unknown>,
        obj: MJIntegrationObjectEntity,
        fields: MJIntegrationObjectFieldEntity[],
    ): Record<string, unknown> {
        const plan = this.fieldTransformPlan(obj, fields);
        let out: Record<string, unknown> | null = null;
        for (const projection of plan.Projections) {
            const value = raw[projection.Field];
            if (!isPlainObject(value) || !(projection.ValuePath in value)) continue;
            out ??= { ...raw };
            out[projection.Field] = value[projection.ValuePath];
        }
        for (const name of plan.EmbeddedJson) {
            const value = raw[name];
            if (!isPlainObject(value)) continue;
            out ??= { ...raw };
            out[name] = JSON.stringify(value);
        }
        return out ?? raw;
    }

    /**
     * Re-fetches ONE record through the object's declared get-by-id door
     * (`Configuration.alternateDoors[doorKind='get-by-id']`, e.g. `GET /orders/{id}`). Objects with no
     * such door (nested rows, composite-key children) cannot be addressed singly — that is refused
     * loudly rather than guessed (`APIPath/{id}` would hit the parent door).
     */
    public override async GetRecord(ctx: GetRecordContext): Promise<ExternalRecord | null> {
        const companyIntegration = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const contextUser = ctx.ContextUser as UserInfo;
        const obj = this.GetCachedObject(companyIntegration.IntegrationID, ctx.ObjectName);
        const door = this.getByIdDoor(this.objectConfig(obj));
        if (!door) {
            throw new Error(`${LOG_PREFIX} GetRecord: "${obj.Name}" declares no get-by-id door (Configuration.alternateDoors), so a single record cannot be re-fetched.`);
        }
        const auth = await this.Authenticate(companyIntegration, contextUser);
        const path = door.replace(/\{\w+\}/, encodeURIComponent(ctx.ExternalID));
        const url = joinURL(auth.BaseURL, path);
        const scope = this.plainScope('get', obj);
        const response = await this.callScope.run(scope, () => this.MakeHTTPRequest(auth, url, 'GET', this.BuildHeaders(auth)));
        if (response.Status === 404) return null;
        const records = this.stripEnvelope(response.Body, obj.ResponseDataKey);
        if (records.length === 0) return null;
        const fields = this.GetCachedFields(obj.ID);
        return {
            ExternalID: ctx.ExternalID,
            ObjectType: ctx.ObjectName,
            Fields: this.applyTransformPreservingKeys(records[0], obj, fields),
        };
    }

    // ── Transport ───────────────────────────────────────────────────────────────────────────────

    /**
     * Resolves and VALIDATES the signing inputs once per connection: ApiLoginName, the base-64
     * ApiSecretKey (decoded strictly — a non-base-64 secret is a clear configuration error, never a
     * crash or a silently-wrong key) and the base URL. Credentials come from the connection's
     * `MJ: Credentials` record, with the connection Configuration JSON as the fallback. Nothing is logged.
     */
    protected override async Authenticate(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<SpektrixAuthContext> {
        const cacheKey = `${companyIntegration.ID}|${companyIntegration.CredentialID ?? ''}|${companyIntegration.Configuration ?? ''}`;
        const cached = this.authCache.get(cacheKey);
        if (cached && cached.ExpiresAt > Date.now()) return cached.Context;
        const credentials = await this.loadCredentials(companyIntegration, contextUser);
        const context = this.buildAuthContext(companyIntegration, credentials);
        this.authCache.set(cacheKey, { Context: context, ExpiresAt: Date.now() + AUTH_CACHE_TTL_MS });
        return context;
    }

    /** Transport headers only. Date + Authorization depend on method/URL/body — added in {@link MakeHTTPRequest}. */
    protected override BuildHeaders(_auth: RESTAuthContext): Record<string, string> {
        return { Accept: JSON_MEDIA_TYPE };
    }

    /**
     * The wire choke point for every read and write:
     *  1. canonicalises the URL ONCE (`new URL(url).href`) — the exact bytes `fetch` sends are the
     *     bytes that are signed;
     *  2. signs with a fresh `Date` (and the body's MD5 on non-GET) per attempt;
     *  3. waits out a 429 (Retry-After honoured, capped) up to `rateLimitRetries` times;
     *  4. on a READ, gates the status: any non-2xx THROWS a classified {@link SpektrixAPIError} — never
     *     an empty batch. The one exception is JSON-404 ResourceNotFound on a `{template-var}` child,
     *     which means "this parent has no child rows" (warned, not failed). Writes and the connection
     *     test get the raw response so they can report the status they observed.
     */
    protected override async MakeHTTPRequest(
        auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown,
    ): Promise<RESTResponse> {
        const context = this.requireSpektrixAuth(auth);
        const verb = method.toUpperCase();
        const requestURL = this.canonicalURL(url);
        const bodyText = body === undefined ? undefined : (typeof body === 'string' ? body : JSON.stringify(body));
        for (let attempt = 0; ; attempt++) {
            const response = await this.sendSigned(context, verb, requestURL, headers, bodyText);
            if (response.Status === 429 && attempt < context.RateLimitRetries) {
                await this.Sleep(this.throttleDelayMs(response, attempt));
                continue;
            }
            return this.gateResponse(response, verb);
        }
    }

    protected override GetBaseURL(_companyIntegration: MJCompanyIntegrationEntity, auth: RESTAuthContext): string {
        return this.requireSpektrixAuth(auth).BaseURL;
    }

    /**
     * Raw transport. Isolated so tests substitute it without touching signing or gating. Redirects
     * are NOT followed: a signed request re-sent to another URL would carry a signature for the old one.
     */
    protected async SendHTTP(
        url: string,
        method: string,
        headers: Record<string, string>,
        body: string | undefined,
        timeoutMs: number,
    ): Promise<RESTResponse> {
        const response = await fetch(url, {
            method,
            headers,
            body,
            redirect: 'manual',
            signal: AbortSignal.timeout(timeoutMs),
        });
        const responseHeaders: Record<string, string> = {};
        response.headers.forEach((value, key) => { responseHeaders[key.toLowerCase()] = value; });
        return { Status: response.status, Body: parseResponseBody(await response.text()), Headers: responseHeaders };
    }

    /** Waits. Isolated so tests can assert the back-off decision without sleeping. */
    protected async Sleep(ms: number): Promise<void> {
        if (ms <= 0) return;
        await new Promise<void>(resolve => setTimeout(resolve, ms));
    }

    /** The clock behind the `Date` header and "today" in the window plan. Isolated for deterministic tests. */
    protected CurrentTime(): Date {
        return new Date();
    }

    // ── Write path ──────────────────────────────────────────────────────────────────────────────
    //
    // Overridden (not the base's generic CRUD) for one genuine idiosyncrasy: Spektrix write paths
    // address a record through MORE than `{id}` — a parent scope (`/customers/{customerId}/addresses`)
    // and, for association rows, a composite key with a query-string variable
    // (`/customers/tags/{id}?id={customerId}`). The base substitutes only `{id}` on update/delete and
    // nothing at all on create. Everything else is still read verbatim from the per-operation IO
    // columns (path, method, body shape/key, ID location); only the path resolver and the documented
    // `literal` body shapes are connector-owned. PUT (replace-whole-collection) is never used.

    public override async CreateRecord(ctx: CreateRecordContext): Promise<CRUDResult> {
        return this.executeWrite('Create', ctx.CompanyIntegration as MJCompanyIntegrationEntity, ctx.ContextUser as UserInfo, ctx.ObjectName, null, ctx.Attributes);
    }

    public override async UpdateRecord(ctx: UpdateRecordContext): Promise<CRUDResult> {
        return this.executeWrite('Update', ctx.CompanyIntegration as MJCompanyIntegrationEntity, ctx.ContextUser as UserInfo, ctx.ObjectName, ctx.ExternalID, ctx.Attributes);
    }

    public override async DeleteRecord(ctx: DeleteRecordContext): Promise<CRUDResult> {
        return this.executeWrite('Delete', ctx.CompanyIntegration as MJCompanyIntegrationEntity, ctx.ContextUser as UserInfo, ctx.ObjectName, ctx.ExternalID, {});
    }

    /**
     * New record id from the create response: the body's `id` (object, or a one-element array), else
     * — only where metadata says the location is undocumented (`n/a`, e.g. POST /events) — a Location
     * header if the vendor sent one. Still nothing → the base reports the create as failed, loudly.
     */
    protected override ExtractIDFromResponse(response: RESTResponse, idLocation: string | null): string | undefined {
        const location = (idLocation ?? 'body').toLowerCase();
        if (location === 'header') return super.ExtractIDFromResponse(response, 'header');
        const fromBody = idFromBody(response.Body);
        if (fromBody) return fromBody;
        return location === 'n/a' ? super.ExtractIDFromResponse(response, 'header') : undefined;
    }

    /** Spektrix / ASP.NET error shapes: `message` / `Message` / `errorCode`, plus `ModelState` detail. */
    protected override ExtractErrorMessage(response: RESTResponse): string | undefined {
        const body = response.Body;
        if (typeof body === 'string') return body.trim().length > 0 ? body.trim().slice(0, 300) : undefined;
        if (!isPlainObject(body)) return undefined;
        const message = readNonEmptyString(body, 'message') ?? readNonEmptyString(body, 'errorCode');
        const modelState = isPlainObject(body.ModelState) ? ` ${JSON.stringify(body.ModelState)}` : '';
        if (message) return `${message}${modelState}`;
        return super.ExtractErrorMessage(response);
    }

    // ═══ Private: discovery ═══════════════════════════════════════════════════════════════════════

    private async *sampleTemplateChild(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
        obj: MJIntegrationObjectEntity,
        vars: string[],
        batchSize: number,
        maxRecords: number,
        deadlineMs?: number,
    ): AsyncGenerator<Record<string, unknown>> {
        const cfg = this.objectConfig(obj);
        const parent = cfg.parentObjectName
            ? this.tryGetObject(companyIntegration.IntegrationID, cfg.parentObjectName)
            : null;
        const parentKey = parent ? this.singlePrimaryKey(parent) : null;
        if (vars.length !== 1 || !parent || !parentKey) {
            this.warnOnce(`sample-adjourn:${obj.Name}`,
                `${LOG_PREFIX} "${obj.Name}": cannot sample (needs exactly one template var and a declared parent with a single key); Declared fields only until first sync.`);
            return;
        }
        const fkField = cfg.parentObjectIDFieldName ?? vars[0];
        const seen = new Set<string>();
        let yielded = 0;
        let parentCtx: CompatFetchContext = {
            CompanyIntegration: companyIntegration, ObjectName: parent.Name, WatermarkValue: null,
            BatchSize: batchSize, ContextUser: contextUser, IsDiscoverySample: true,
            SampleTargetRecords: maxRecords, DeadlineMs: deadlineMs,
        };
        for (;;) {
            const batch = await this.FetchChanges(parentCtx);
            for (const record of batch.Records) {
                const parentID = record.Fields[parentKey];
                if (parentID == null || seen.has(String(parentID))) continue;
                seen.add(String(parentID));
                for (const row of await this.fetchTemplateChildRows(companyIntegration, contextUser, obj, vars[0], fkField, String(parentID))) {
                    yield row;
                    if (++yielded >= maxRecords) return;
                }
                if (deadlineMs !== undefined && Date.now() >= deadlineMs) return;
            }
            if (!batch.HasMore || (deadlineMs !== undefined && Date.now() >= deadlineMs)) return;
            parentCtx = { ...parentCtx, AfterKeyValue: batch.NextAfterKeyValue ?? parentCtx.AfterKeyValue };
        }
    }

    /** One parent's child rows, read exactly as the base sync path reads them (same scope, same tagging). */
    private async fetchTemplateChildRows(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
        obj: MJIntegrationObjectEntity,
        templateVar: string,
        fkField: string,
        parentID: string,
    ): Promise<Record<string, unknown>[]> {
        const auth = await this.Authenticate(companyIntegration, contextUser);
        const cfg = this.objectConfig(obj);
        const plan = this.buildReadPlan(companyIntegration.IntegrationID, obj, cfg);
        const spec = this.windowSpecFor(cfg);
        const window = spec ? this.fullSpanWindow(companyIntegration, obj, spec) : undefined;
        const scope = this.readScope(obj, plan, window, true);
        const fields = this.GetCachedFields(obj.ID);
        return this.callScope.run(scope, async () => {
            const path = obj.APIPath.replace(`{${templateVar}}`, encodeURIComponent(parentID));
            const url = this.AppendDefaultQueryParams(joinURL(auth.BaseURL, path), obj);
            const response = await this.MakeHTTPRequest(auth, url, 'GET', this.BuildHeaders(auth));
            return this.NormalizeResponse(response.Body, obj.ResponseDataKey).map(row => {
                row[fkField] = parentID;
                return this.applyTransformPreservingKeys(row, obj, fields);
            });
        });
    }

    // ═══ Private: connection probe ════════════════════════════════════════════════════════════════

    /** Lowest-Sequence active, flat, depth-0 door whose Help modes are System Owner ONLY; un-windowed first. */
    private selectConnectionProbe(integrationID: string): MJIntegrationObjectEntity | null {
        const candidates = this.activeObjects(integrationID).filter(o => {
            const cfg = this.objectConfig(o);
            const modes = cfg.door?.modes ?? [];
            const nested = (cfg.accessPath?.nestingSegments ?? []).length > 0;
            return templateVarsOf(o.APIPath).length === 0 && !nested
                && modes.includes('Owner') && !modes.includes('Web') && !modes.includes('Agent');
        });
        candidates.sort((a, b) => {
            const aw = this.windowSpecFor(this.objectConfig(a)) ? 1 : 0;
            const bw = this.windowSpecFor(this.objectConfig(b)) ? 1 : 0;
            return aw !== bw ? aw - bw : a.Sequence - b.Sequence;
        });
        return candidates[0] ?? null;
    }

    private connectionProbeURL(auth: SpektrixAuthContext, probe: MJIntegrationObjectEntity): string {
        const url = joinURL(auth.BaseURL, probe.APIPath);
        const spec = this.windowSpecFor(this.objectConfig(probe));
        if (!spec) return url;
        const today = utcMidnight(this.CurrentTime());
        const params = new Map<string, string>([
            [spec.fromParam, isoDate(today)],
            [spec.toParam, isoDate(addDaysUTC(today, 1))],
        ]);
        return appendQueryParams(url, params);
    }

    private describeConnectionProbe(response: RESTResponse, probe: MJIntegrationObjectEntity): ConnectionTestResult {
        const where = `GET ${probe.APIPath}`;
        if (response.Status >= 200 && response.Status < 300) {
            if (Array.isArray(response.Body) || isPlainObject(response.Body)) {
                return { Success: true, Message: `${LOG_PREFIX} Authenticated: the System Owner door ${where} accepted the SpektrixAPI3 signature (HTTP ${response.Status}).` };
            }
            return { Success: false, Message: `${LOG_PREFIX} ${where} answered HTTP ${response.Status} without a JSON body — the base URL does not look like a Spektrix v3 API root.` };
        }
        if (response.Status === 401) {
            return { Success: false, Message: `${LOG_PREFIX} ${where} rejected the signature (HTTP 401). Check ApiLoginName, ApiSecretKey, ClientName/BaseURL and the server clock.` };
        }
        if (response.Status === 403) {
            return { Success: false, Message: `${LOG_PREFIX} ${where} answered HTTP 403 — the API user lacks System Owner permission for this route.` };
        }
        return { Success: false, Message: `${LOG_PREFIX} ${where} answered HTTP ${response.Status}${this.vendorMessageSuffix(response)}.` };
    }

    // ═══ Private: read routing ════════════════════════════════════════════════════════════════════

    private async fetchTemplateChildren(
        ctx: FetchContext,
        obj: MJIntegrationObjectEntity,
        plan: ReadPlan,
        spec: SpektrixFetchWindowSpec | null,
    ): Promise<FetchBatchResult> {
        // ONE full-span window per parent: the vendor's batching advice is about the /events and
        // /instances LIST calls; a per-parent child request is already bounded by its parent.
        const window = spec ? this.fullSpanWindow(ctx.CompanyIntegration, obj, spec) : undefined;
        const scope = this.readScope(obj, plan, window, true);
        const batch = await this.callScope.run(scope, () => super.FetchChanges(ctx));
        return this.withScopeWarnings(scope, batch);
    }

    /**
     * Reads date windows from the resume cursor onward, accumulating (de-duplicated by ExternalID,
     * last observation wins) until the batch is full, the discovery sample is met, the deadline or
     * the per-call budget passes, or the plan is exhausted. A window is never split — the API has no
     * paging. Resumable: `NextAfterKeyValue` = the next window's start.
     */
    private async fetchWindowed(
        ctx: FetchContext,
        obj: MJIntegrationObjectEntity,
        plan: ReadPlan,
        spec: SpektrixFetchWindowSpec,
    ): Promise<FetchBatchResult> {
        const windows = this.planWindows(ctx.CompanyIntegration, obj);
        if (windows.length === 0) {
            return { Records: [], HasMore: false, Warnings: [this.emptyWindowPlanWarning(obj)] };
        }
        const startedAt = Date.now();
        const target = this.batchTarget(ctx);
        const collected = new Map<string, ExternalRecord>();
        const warnings: FetchWarning[] = [];
        let index = this.resumeWindowIndex(windows, ctx.AfterKeyValue);
        while (index < windows.length) {
            const scope = this.readScope(obj, plan, { Spec: spec, Window: windows[index] }, false);
            const batch = await this.callScope.run(scope, () => super.FetchChanges({ ...ctx, AfterKeyValue: null }));
            for (const record of batch.Records) collected.set(record.ExternalID, record);
            warnings.push(...(this.withScopeWarnings(scope, batch).Warnings ?? []));
            index++;
            if (this.windowBatchFull(ctx, collected.size, target, startedAt)) break;
        }
        const hasMore = index < windows.length;
        return {
            Records: [...collected.values()],
            HasMore: hasMore,
            NextAfterKeyValue: hasMore ? `${WINDOW_CURSOR_PREFIX}${windows[index].From}` : undefined,
            Warnings: warnings.length > 0 ? warnings : undefined,
        };
    }

    private batchTarget(ctx: CompatFetchContext): number {
        const batch = ctx.BatchSize > 0 ? ctx.BatchSize : Number.MAX_SAFE_INTEGER;
        return ctx.IsDiscoverySample && ctx.SampleTargetRecords ? Math.min(batch, ctx.SampleTargetRecords) : batch;
    }

    private windowBatchFull(ctx: CompatFetchContext, collected: number, target: number, startedAt: number): boolean {
        if (collected >= target) return true;
        if (ctx.DeadlineMs !== undefined && Date.now() >= ctx.DeadlineMs) return true;
        return Date.now() - startedAt >= WINDOW_CALL_BUDGET_MS;
    }

    private resumeWindowIndex(windows: SpektrixDateWindow[], after: string | null | undefined): number {
        if (!after || !after.startsWith(WINDOW_CURSOR_PREFIX)) return 0;
        const from = after.slice(WINDOW_CURSOR_PREFIX.length);
        const index = windows.findIndex(w => w.From >= from);
        return index >= 0 ? index : 0;
    }

    private emptyWindowPlanWarning(obj: MJIntegrationObjectEntity): FetchWarning {
        return {
            Code: 'EMPTY_FETCH_WINDOW_PLAN',
            Message: `"${obj.Name}" is read in date windows, but the connection's window start is not before its end, ` +
                'so no window was requested. Check fetchWindowStart / fetchWindowEnd / fetchWindowHorizonMonths in the connection Configuration.',
            Data: { object: obj.Name },
        };
    }

    // ═══ Private: window planning ═════════════════════════════════════════════════════════════════

    /** `Configuration.fetchWindow`, else the door's `accessPath.doorFetchWindow`, else none. */
    private windowSpecFor(cfg: SpektrixObjectConfig): SpektrixFetchWindowSpec | null {
        return cfg.fetchWindow ?? cfg.accessPath?.doorFetchWindow ?? null;
    }

    private planWindows(companyIntegration: MJCompanyIntegrationEntity, obj: MJIntegrationObjectEntity): SpektrixDateWindow[] {
        const settings = this.windowSettings(companyIntegration, obj);
        return BuildSpektrixDateWindows(settings.Start, settings.EndExclusive, settings.WindowDays);
    }

    private fullSpanWindow(
        companyIntegration: MJCompanyIntegrationEntity,
        obj: MJIntegrationObjectEntity,
        spec: SpektrixFetchWindowSpec,
    ): SpektrixWindowRequest | undefined {
        const settings = this.windowSettings(companyIntegration, obj);
        if (settings.Start >= settings.EndExclusive) return undefined;
        return { Spec: spec, Window: { From: isoDate(settings.Start), To: isoDate(settings.EndExclusive) } };
    }

    /**
     * Window plan inputs: a per-object override (`fetchWindows[<object>]`), else the override of the
     * object's DOOR (`fetchWindows[<accessPath.doorObject>]` — so `fetchWindows.Order` governs Customer
     * and every Order line item read through the same `/orders` door), else the connection defaults
     * (`fetchWindowStart` / `fetchWindowEnd` / `fetchWindowHorizonMonths` / `fetchWindowDays`).
     * Start defaults to TODAY (the vendor's "starting from today unless historic data is required");
     * the end defaults to the close of the month {@link DEFAULT_WINDOW_HORIZON_MONTHS} months ahead.
     */
    private windowSettings(companyIntegration: MJCompanyIntegrationEntity, obj: MJIntegrationObjectEntity): WindowSettings {
        const settings = this.connectionSettings(companyIntegration);
        const doorObject = this.objectConfig(obj).accessPath?.doorObject;
        const override = settings.fetchWindows?.[obj.Name] ?? (doorObject ? settings.fetchWindows?.[doorObject] : undefined);
        const today = utcMidnight(this.CurrentTime());
        const start = this.configuredDate(override?.start ?? settings.fetchWindowStart, 'start') ?? today;
        const horizon = override?.horizonMonths ?? settings.fetchWindowHorizonMonths ?? DEFAULT_WINDOW_HORIZON_MONTHS;
        const end = this.configuredDate(override?.end ?? settings.fetchWindowEnd, 'end')
            ?? firstOfMonthOffsetUTC(today, horizon + 1);
        return { Start: start, EndExclusive: end, WindowDays: override?.days ?? settings.fetchWindowDays ?? null };
    }

    private configuredDate(value: string | undefined, label: string): Date | null {
        if (!value) return null;
        const parsed = parseISODate(value);
        if (!parsed) {
            this.warnOnce(`window-${label}:${value}`, `${LOG_PREFIX} Ignoring fetch-window ${label} "${value}" — expected YYYY-MM-DD.`);
        }
        return parsed;
    }

    // ═══ Private: access-path walking ═════════════════════════════════════════════════════════════

    private buildReadPlan(integrationID: string, obj: MJIntegrationObjectEntity, cfg: SpektrixObjectConfig): ReadPlan {
        const accessPath = cfg.accessPath;
        const segments = this.nestingSegments(accessPath);
        const keyField = this.singlePrimaryKey(obj);
        return {
            Segments: segments,
            ParentTag: accessPath?.parentTag ? this.resolveParentTag(integrationID, obj, accessPath, segments) : null,
            Unions: (cfg.unionAccessPaths ?? []).map(u => ({
                Field: u.nestingFieldPath,
                Recursive: u.recursive === true,
                ParentKeyField: u.parentKeyField ?? null,
                KeyField: keyField,
            })),
        };
    }

    private nestingSegments(accessPath: SpektrixAccessPath | undefined): string[] {
        const raw = accessPath?.nestingSegments
            ?? (accessPath?.nestingFieldPath ? accessPath.nestingFieldPath.split('.') : []);
        return raw.map(s => (s.endsWith('[]') ? s.slice(0, -2) : s)).filter(s => s.length > 0);
    }

    /**
     * Which ancestor a `parentTag` reads from, resolved from metadata: the object type at each level
     * is the door object, then each level's `Configuration.collections[field].io`. A single-level path
     * has exactly one ancestor, so it needs no type chain.
     */
    private resolveParentTag(
        integrationID: string,
        obj: MJIntegrationObjectEntity,
        accessPath: SpektrixAccessPath,
        segments: string[],
    ): ResolvedParentTag | null {
        const tag = accessPath.parentTag;
        if (!tag || segments.length === 0) return null;
        const levelTypes = this.levelTypes(integrationID, accessPath.doorObject ?? obj.Name, segments);
        let index = levelTypes.slice(0, segments.length).indexOf(tag.fromObject);
        if (index < 0 && segments.length === 1) index = 0;
        if (index < 0) {
            this.warnOnce(`parent-tag:${obj.Name}`,
                `${LOG_PREFIX} "${obj.Name}": accessPath.parentTag.fromObject "${tag.fromObject}" is not on its access path; "${tag.asField}" is not tagged.`);
            return null;
        }
        return { AncestorIndex: index, FromField: tag.fromField, AsField: tag.asField };
    }

    private levelTypes(integrationID: string, doorObject: string, segments: string[]): Array<string | null> {
        const types: Array<string | null> = [doorObject];
        for (const segment of segments) {
            const previous = types[types.length - 1];
            const previousObj = previous ? this.tryGetObject(integrationID, previous) : null;
            const collection = previousObj
                ? (this.objectConfig(previousObj).collections ?? []).find(c => c.field === segment)
                : undefined;
            types.push(collection?.io ?? collection?.itemType ?? null);
        }
        return types;
    }

    private stripEnvelope(rawBody: unknown, responseDataKey: string | null): Record<string, unknown>[] {
        let target: unknown = rawBody;
        if (responseDataKey) {
            for (const key of responseDataKey.split('.')) {
                target = isPlainObject(target) ? target[key] : undefined;
            }
        }
        if (Array.isArray(target)) return target.filter(isPlainObject);
        return isPlainObject(target) ? [target] : [];
    }

    private walkReadPlan(roots: Record<string, unknown>[], plan: ReadPlan): Record<string, unknown>[] {
        let nodes: WalkNode[] = roots.map(record => ({ Record: record, Ancestors: [] }));
        for (const segment of plan.Segments) nodes = this.descendSegment(nodes, segment);
        const leaves = nodes.map(node => this.applyParentTag(node, plan.ParentTag));
        return plan.Unions.length > 0 ? this.expandUnions(leaves, plan.Unions) : leaves;
    }

    /** One level down. Wire keys are matched EXACTLY (never re-cased); a single object counts as one item. */
    private descendSegment(nodes: WalkNode[], segment: string): WalkNode[] {
        const next: WalkNode[] = [];
        for (const node of nodes) {
            const value = node.Record[segment];
            if (value == null) continue;
            const items: unknown[] = Array.isArray(value) ? value : [value];
            for (const item of items) {
                if (isPlainObject(item)) next.push({ Record: item, Ancestors: [...node.Ancestors, node.Record] });
            }
        }
        return next;
    }

    /** Copies the ancestor's key onto the leaf. A value the source itself supplied is never overwritten. */
    private applyParentTag(node: WalkNode, tag: ResolvedParentTag | null): Record<string, unknown> {
        if (!tag || tag.AsField in node.Record) return node.Record;
        const value = node.Ancestors[tag.AncestorIndex]?.[tag.FromField];
        return value == null ? node.Record : { ...node.Record, [tag.AsField]: value };
    }

    /** Unions recursive same-object collections (a Plan's `areas` are Plans) into the record set, tagging each child's parent key. */
    private expandUnions(records: Record<string, unknown>[], unions: ResolvedUnion[]): Record<string, unknown>[] {
        const out: Record<string, unknown>[] = [];
        const visit = (record: Record<string, unknown>, depth: number): void => {
            out.push(record);
            if (depth >= MAX_UNION_DEPTH) return;
            for (const union of unions) {
                const children = record[union.Field];
                if (!Array.isArray(children)) continue;
                const parentKey = union.KeyField ? record[union.KeyField] : undefined;
                for (const child of children) {
                    if (!isPlainObject(child)) continue;
                    const tagged = union.ParentKeyField && parentKey != null && !(union.ParentKeyField in child)
                        ? { ...child, [union.ParentKeyField]: parentKey }
                        : child;
                    if (union.Recursive) visit(tagged, depth + 1);
                    else out.push(tagged);
                }
            }
        };
        for (const record of records) visit(record, 0);
        return out;
    }

    // ═══ Private: scope + warnings ════════════════════════════════════════════════════════════════

    private readScope(
        obj: MJIntegrationObjectEntity,
        plan: ReadPlan,
        window: SpektrixWindowRequest | undefined,
        templateChild: boolean,
    ): SpektrixCallScope {
        if (window?.Spec.format && window.Spec.format.toUpperCase() !== 'YYYY-MM-DD') {
            this.warnOnce(`window-format:${obj.Name}`,
                `${LOG_PREFIX} "${obj.Name}": window format "${window.Spec.format}" is not YYYY-MM-DD; sending ISO dates.`);
        }
        return {
            Verb: 'read', ObjectName: obj.Name, APIPathTemplate: obj.APIPath, Read: plan, Window: window,
            TemplateChild: templateChild, Warnings: [], NotFoundParents: [],
        };
    }

    private plainScope(verb: SpektrixCallVerb, obj: MJIntegrationObjectEntity): SpektrixCallScope {
        return { Verb: verb, ObjectName: obj.Name, APIPathTemplate: obj.APIPath, TemplateChild: false, Warnings: [], NotFoundParents: [] };
    }

    private withScopeWarnings(scope: SpektrixCallScope, batch: FetchBatchResult): FetchBatchResult {
        const warnings = [...scope.Warnings, ...(batch.Warnings ?? [])];
        if (scope.NotFoundParents.length > 0) {
            warnings.push({
                Code: 'PARENT_NOT_FOUND',
                Message: `"${scope.ObjectName}": Spektrix answered JSON 404 ResourceNotFound for ${scope.NotFoundParents.length} parent(s) on ` +
                    `${scope.APIPathTemplate}; treated as "no child rows" for those parents (the parent was removed or is unknown to the vendor).`,
                Data: { object: scope.ObjectName, parents: scope.NotFoundParents.slice(0, 10), count: scope.NotFoundParents.length },
            });
        }
        return warnings.length > 0 ? { ...batch, Warnings: warnings } : batch;
    }

    private warnOnce(key: string, message: string): void {
        if (this.warnedOnce.has(key)) return;
        this.warnedOnce.add(key);
        console.warn(message);
    }

    // ═══ Private: transport + error classification ════════════════════════════════════════════════

    private async sendSigned(
        auth: SpektrixAuthContext,
        verb: string,
        url: string,
        headers: Record<string, string>,
        bodyText: string | undefined,
    ): Promise<RESTResponse> {
        const dateHeader = this.CurrentTime().toUTCString();
        const authorization = BuildSpektrixAuthorization({
            LoginName: auth.ApiLoginName, SigningKey: auth.SigningKey, Method: verb, Url: url, DateHeader: dateHeader, Body: bodyText,
        });
        const wire: Record<string, string> = { ...headers, Accept: JSON_MEDIA_TYPE, Date: dateHeader, Authorization: authorization };
        if (bodyText !== undefined) wire['Content-Type'] = `${JSON_MEDIA_TYPE}; charset=utf-8`;
        return this.SendHTTP(url, verb, wire, bodyText, auth.RequestTimeoutMs);
    }

    private throttleDelayMs(response: RESTResponse, attempt: number): number {
        const stated = ParseRetryAfterValue(response.Headers['retry-after']);
        if (stated !== undefined) return stated;
        return Math.min(1000 * 2 ** attempt, MAX_HONORED_RETRY_AFTER_MS);
    }

    private canonicalURL(url: string): string {
        try {
            return new URL(url).href;
        } catch {
            throw new Error(`${LOG_PREFIX} The request URL is not absolute — check the BaseURL / ClientName connection configuration.`);
        }
    }

    private gateResponse(response: RESTResponse, verb: string): RESTResponse {
        const scope = this.callScope.getStore();
        const kind: SpektrixCallVerb = scope?.Verb ?? (verb === 'GET' ? 'read' : 'write');
        if (kind === 'write' || kind === 'test') return response;
        if (response.Status >= 200 && response.Status < 300) {
            if (typeof response.Body === 'string' && response.Body.trim().length > 0) {
                throw this.errorFor(response, verb, scope, true);
            }
            return response;
        }
        if (response.Status === 404 && isResourceNotFoundBody(response.Body)) {
            if (kind === 'get') return response;
            if (scope?.TemplateChild) {
                scope.NotFoundParents.push(this.notFoundIdentifier(response.Body));
                this.warnOnce(`parent-404:${scope.ObjectName}`,
                    `${LOG_PREFIX} "${scope.ObjectName}": JSON 404 ResourceNotFound for a parent — treated as no child rows for that parent.`);
                return { Status: 200, Body: [], Headers: response.Headers };
            }
        }
        throw this.errorFor(response, verb, scope, false);
    }

    private notFoundIdentifier(body: Record<string, unknown>): string {
        const identifiers = body.resourceIdentifiers;
        if (isPlainObject(identifiers)) {
            const first = Object.values(identifiers).find(v => typeof v === 'string' || typeof v === 'number');
            if (first !== undefined) return String(first);
        }
        return typeof body.resourceType === 'string' ? body.resourceType : 'unknown';
    }

    private errorFor(response: RESTResponse, verb: string, scope: SpektrixCallScope | undefined, nonJSONSuccess: boolean): SpektrixAPIError {
        const target = `${verb} ${scope?.APIPathTemplate ?? 'request'}${scope ? ` for "${scope.ObjectName}"` : ''}`;
        const { Classification, Phrase } = this.classifyResponse(response, nonJSONSuccess);
        const vendorMessage = this.ExtractErrorMessage(response);
        return new SpektrixAPIError(`${LOG_PREFIX} HTTP ${response.Status} — ${Phrase} (${target}).`, response.Status, response.Headers, Classification, vendorMessage);
    }

    /**
     * Status → classification (`Configuration.ErrorContract`). The phrases are chosen for the engine's
     * text classifier: 429 says "rate limit", 5xx says "timeout" (both retryable), the configuration
     * class says "configuration", anything else carries no keyword (UNKNOWN, not retryable) — and none
     * carries vendor text: a vendor id containing "429", the token "ResourceNotFound" (⊃ "enotfound")
     * or the word "connector" (⊃ "connect") would each misroute it to a retryable class.
     */
    private classifyResponse(response: RESTResponse, nonJSONSuccess: boolean): { Classification: SpektrixErrorClassification; Phrase: string } {
        const status = response.Status;
        const config = (reason: string, phrase: string) => ({
            Classification: { Code: 'CONFIGURATION_ERROR' as SyncErrorCode, Severity: 'Critical' as ErrorSeverity, Retryable: false, Reason: reason },
            Phrase: phrase,
        });
        if (nonJSONSuccess) return config('non-json-success', 'success status with a non-JSON body; the BaseURL configuration does not address the Spektrix v3 JSON API');
        if (status === 429) {
            return { Classification: { Code: 'RATE_LIMIT_EXCEEDED', Severity: 'Warning', Retryable: true, Reason: 'throttled' }, Phrase: 'rate limit exceeded; retry after the stated Retry-After' };
        }
        if (status >= 500) {
            return { Classification: { Code: 'NETWORK_TIMEOUT', Severity: 'Warning', Retryable: true, Reason: 'server-error' }, Phrase: 'transient Spektrix server error; retryable (gateway timeout class)' };
        }
        if (status === 401) return config('auth', 'authentication failed: Spektrix rejected the SpektrixAPI3 signature. Check the connection configuration (ApiLoginName, ApiSecretKey, ClientName/BaseURL) and that the server clock is current UTC');
        if (status === 403) return config('forbidden', 'the API user lacks System Owner permission for this route; check the connection configuration');
        if (status === 405) return config('unsupported-form', 'this request form is not supported by the route (e.g. a list read the vendor serves only by id or lookup); a metadata configuration error, not transient');
        if (status >= 300 && status < 400) return config('redirect', 'redirected; signed requests are never re-sent to another URL, so set BaseURL in the connection configuration to the final v3 API root');
        if (status === 404 && !isResourceNotFoundBody(response.Body)) {
            return config('route', 'unknown route (non-JSON 404); the object APIPath or the BaseURL configuration does not address a Spektrix v3 route');
        }
        if (status === 400) {
            return { Classification: { Code: 'VALIDATION_ERROR', Severity: 'Critical', Retryable: false, Reason: 'rejected' }, Phrase: 'Spektrix rejected the request (validation failure)' };
        }
        if (status === 404) {
            // A JSON 404 on a read that is NOT a per-parent child: the route is real but the resource the
            // object's declared path addresses does not exist. Never the literal "ResourceNotFound" token
            // (⊃ "enotfound", read as a transient DNS failure) and never the word "connector" (⊃ "connect",
            // read as a retryable database failure).
            return config('not-found', 'resource not found (JSON 404): the route exists but the resource the object APIPath configuration addresses does not');
        }
        return { Classification: { Code: 'UNKNOWN_ERROR', Severity: 'Critical', Retryable: false, Reason: 'unexpected' }, Phrase: 'unexpected response status for a read' };
    }

    private vendorMessageSuffix(response: RESTResponse): string {
        const message = this.ExtractErrorMessage(response);
        return message ? `: ${message}` : '';
    }

    // ═══ Private: credentials + base URL ══════════════════════════════════════════════════════════

    private requireSpektrixAuth(auth: RESTAuthContext): SpektrixAuthContext {
        if (typeof auth.ApiLoginName === 'string' && Buffer.isBuffer(auth.SigningKey) && typeof auth.BaseURL === 'string'
            && typeof auth.RequestTimeoutMs === 'number' && typeof auth.RateLimitRetries === 'number') {
            return auth as SpektrixAuthContext;
        }
        throw new Error(`${LOG_PREFIX} Internal invariant: the transport received an auth context without the signing inputs Authenticate resolves.`);
    }

    private buildAuthContext(companyIntegration: MJCompanyIntegrationEntity, credentials: SpektrixCredentialValues): SpektrixAuthContext {
        const login = credentials.ApiLoginName?.trim();
        if (!login) {
            throw new Error(`${LOG_PREFIX} ApiLoginName is missing — supply it on the connection credential (or its configuration).`);
        }
        if (!credentials.ApiSecretKey || credentials.ApiSecretKey.trim().length === 0) {
            throw new Error(`${LOG_PREFIX} ApiSecretKey is missing — supply the base-64 secret on the connection credential (or its configuration).`);
        }
        let signingKey: Buffer;
        try {
            signingKey = DecodeBase64SigningKey(credentials.ApiSecretKey, 'ApiSecretKey');
        } catch (err) {
            if (err instanceof HmacKeyFormatError) throw new Error(`${LOG_PREFIX} ${err.message} (connection configuration)`);
            throw err;
        }
        const settings = this.connectionSettings(companyIntegration);
        return {
            ApiLoginName: login,
            SigningKey: signingKey,
            BaseURL: this.resolveBaseURL(companyIntegration, credentials, settings),
            RequestTimeoutMs: settings.requestTimeoutMs ?? DEFAULT_REQUEST_TIMEOUT_MS,
            RateLimitRetries: settings.rateLimitRetries ?? DEFAULT_RATE_LIMIT_RETRIES,
        };
    }

    /**
     * `Configuration.BaseURLOverridePrecedence`: connection BaseURL (custom domain, or a test harness
     * origin) > `Integration.Configuration.BaseURLTemplate` with the CONNECTION's ClientName. The host
     * and path shape come from metadata; no tenant value is ever baked into this class.
     */
    private resolveBaseURL(
        companyIntegration: MJCompanyIntegrationEntity,
        credentials: SpektrixCredentialValues,
        settings: SpektrixConnectionSettings,
    ): string {
        const override = (settings.BaseURL ?? credentials.BaseURL)?.trim();
        if (override) return this.normalizeBaseURL(override);
        const template = this.integrationConfig(companyIntegration.IntegrationID)?.BaseURLTemplate;
        if (!template || !template.includes('{ClientName}')) {
            throw new Error(`${LOG_PREFIX} Integration.Configuration.BaseURLTemplate is not declared and the connection sets no BaseURL — check the configuration.`);
        }
        const clientName = credentials.ClientName?.trim();
        if (!clientName) {
            throw new Error(`${LOG_PREFIX} ClientName (the Spektrix system name) is missing — supply it, or set BaseURL, in the connection configuration.`);
        }
        return this.normalizeBaseURL(template.replace('{ClientName}', encodeURIComponent(clientName)));
    }

    private normalizeBaseURL(value: string): string {
        let parsed: URL;
        try {
            parsed = new URL(value);
        } catch {
            throw new Error(`${LOG_PREFIX} BaseURL "${value}" is not an absolute URL — check the connection configuration.`);
        }
        if (parsed.protocol !== 'https:' && parsed.protocol !== 'http:') {
            throw new Error(`${LOG_PREFIX} BaseURL must be http(s) — check the connection configuration.`);
        }
        return parsed.href.replace(/\/+$/, '');
    }

    /** Credential record first (per key), connection Configuration second. Nothing is logged. */
    private async loadCredentials(companyIntegration: MJCompanyIntegrationEntity, contextUser: UserInfo): Promise<SpektrixCredentialValues> {
        let fromCredential: Record<string, unknown> | null = null;
        if (companyIntegration.CredentialID) {
            try {
                const credential = await new Metadata().GetEntityObject<MJCredentialEntity>('MJ: Credentials', contextUser);
                if (await credential.Load(companyIntegration.CredentialID)) fromCredential = parseJSONObject(credential.Values);
            } catch {
                // An unloadable credential is a configuration problem, not a crash: the Configuration
                // fallback still applies and buildAuthContext reports precisely what is missing.
            }
        }
        const fromConfig = parseJSONObject(companyIntegration.Configuration);
        const pick = (key: keyof SpektrixCredentialValues): string | undefined =>
            readNonEmptyString(fromCredential, key) ?? readNonEmptyString(fromConfig, key);
        return { ClientName: pick('ClientName'), ApiLoginName: pick('ApiLoginName'), ApiSecretKey: pick('ApiSecretKey'), BaseURL: pick('BaseURL') };
    }

    private connectionSettings(companyIntegration: MJCompanyIntegrationEntity): SpektrixConnectionSettings {
        const parsed = ZConnectionSettings.safeParse(parseJSONObject(companyIntegration.Configuration) ?? {});
        return parsed.success ? parsed.data : {};
    }

    // ═══ Private: write execution ═════════════════════════════════════════════════════════════════

    private async executeWrite(
        operation: WriteOperation,
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
        objectName: string,
        externalID: string | null,
        attributes: Record<string, unknown>,
    ): Promise<CRUDResult> {
        const obj = this.GetCachedObject(companyIntegration.IntegrationID, objectName);
        const columns = this.writeColumns(obj, operation);
        if (!columns.Path || !columns.Method) {
            throw new Error(`${LOG_PREFIX} ${operation}Record not supported for "${objectName}": ${operation}APIPath / ${operation}Method are not configured on the IntegrationObject.`);
        }
        const method = columns.Method.toUpperCase();
        if (method === 'PUT') {
            return { Success: false, StatusCode: 0, ErrorMessage: `${LOG_PREFIX} "${objectName}": PUT replaces a whole Spektrix collection and is never used for a single-record ${operation.toLowerCase()}.` };
        }
        const fields = this.GetCachedFields(obj.ID);
        const keyValues = this.keyValuesFor(fields, externalID);
        const resolved = this.resolveOperationPath(columns.Path, columns.IDLocation, externalID, keyValues, attributes);
        if ('Error' in resolved) {
            return { Success: false, StatusCode: 0, ErrorMessage: `${LOG_PREFIX} ${operation} "${objectName}": ${resolved.Error}` };
        }
        const body = operation === 'Delete' ? undefined : this.buildWriteBody(obj, fields, attributes, columns, resolved.ConsumedAttributeKeys);
        if (body !== undefined && this.isEmptyBody(body)) {
            return { Success: false, StatusCode: 0, ErrorMessage: `${LOG_PREFIX} ${operation} "${objectName}": no writable attributes to send.` };
        }
        const auth = await this.Authenticate(companyIntegration, contextUser);
        const url = joinURL(auth.BaseURL, resolved.Path);
        const response = await this.callScope.run(this.plainScope('write', obj),
            () => this.MakeHTTPRequest(auth, url, method, this.BuildHeaders(auth), body));
        return this.writeResult(operation, obj, fields, response, columns, externalID, attributes, resolved);
    }

    private writeColumns(obj: MJIntegrationObjectEntity, operation: WriteOperation): WriteColumns {
        if (operation === 'Create') {
            return { Path: obj.CreateAPIPath, Method: obj.CreateMethod, BodyShape: obj.CreateBodyShape, BodyKey: obj.CreateBodyKey, IDLocation: obj.CreateIDLocation };
        }
        if (operation === 'Update') {
            return { Path: obj.UpdateAPIPath, Method: obj.UpdateMethod, BodyShape: obj.UpdateBodyShape, BodyKey: obj.UpdateBodyKey, IDLocation: obj.UpdateIDLocation };
        }
        return { Path: obj.DeleteAPIPath, Method: obj.DeleteMethod, BodyShape: null, BodyKey: null, IDLocation: obj.DeleteIDLocation };
    }

    private writeResult(
        operation: WriteOperation,
        obj: MJIntegrationObjectEntity,
        fields: MJIntegrationObjectFieldEntity[],
        response: RESTResponse,
        columns: WriteColumns,
        externalID: string | null,
        attributes: Record<string, unknown>,
        resolved: ResolvedOperationPath,
    ): CRUDResult {
        if (response.Status < 200 || response.Status >= 300) {
            return { Success: false, StatusCode: response.Status, ErrorMessage: this.ExtractErrorMessage(response) ?? `HTTP ${response.Status} on ${operation.toLowerCase()}` };
        }
        if (operation === 'Create') {
            return this.BuildCreatedResult(this.createdExternalID(fields, response, columns.IDLocation, attributes, resolved), response.Status, obj.Name);
        }
        return { Success: true, StatusCode: response.Status, ExternalID: externalID ?? undefined };
    }

    /** Primary-key values carried by an ExternalID: composite keys are `|`-joined in IOF Sequence order (the read path's convention). */
    private keyValuesFor(fields: MJIntegrationObjectFieldEntity[], externalID: string | null): Record<string, string> {
        if (externalID == null) return {};
        const keys = fields.filter(f => f.IsPrimaryKey).sort((a, b) => a.Sequence - b.Sequence).map(f => f.Name);
        if (keys.length === 1) return { [keys[0]]: externalID };
        const parts = externalID.split('|');
        if (keys.length === 0 || parts.length !== keys.length) return {};
        return Object.fromEntries(keys.map((k, i) => [k, parts[i]]));
    }

    /**
     * Substitutes EVERY `{var}` in an operation path (path segments AND query string, which is kept
     * intact): `{id}` / `{ID}` / `{ExternalID}` from the record's key (when the ID location is the
     * path), any other var from the composite key, then from the record's attributes. An unresolved
     * var is a refusal — a malformed URL is never sent.
     */
    private resolveOperationPath(
        template: string,
        idLocation: string | null,
        externalID: string | null,
        keyValues: Record<string, string>,
        attributes: Record<string, unknown>,
    ): ResolvedOperationPath | { Error: string } {
        const consumed = new Set<string>();
        const values: Record<string, string> = {};
        const missing: string[] = [];
        const path = template.replace(/\{(\w+)\}/g, (match: string, name: string) => {
            const value = this.pathVariableValue(name, idLocation, externalID, keyValues, attributes, consumed);
            if (value == null) {
                missing.push(name);
                return match;
            }
            values[name] = value;
            return encodeURIComponent(value);
        });
        if (missing.length > 0) {
            return { Error: `cannot resolve {${missing.join('}, {')}} in "${template}" from the record key or attributes — refusing to send a malformed URL.` };
        }
        return { Path: path, ConsumedAttributeKeys: consumed, PathValues: values };
    }

    private pathVariableValue(
        name: string,
        idLocation: string | null,
        externalID: string | null,
        keyValues: Record<string, string>,
        attributes: Record<string, unknown>,
        consumed: Set<string>,
    ): string | null {
        const idInPath = idLocation == null || idLocation.toLowerCase() === 'path';
        if (/^(id|ID|ExternalID)$/.test(name) && externalID != null && idInPath) {
            const idKey = findKeyCaseInsensitive(keyValues, 'id');
            if (idKey != null) return keyValues[idKey];
            return Object.keys(keyValues).length <= 1 ? externalID : null;
        }
        const keyName = findKeyCaseInsensitive(keyValues, name);
        if (keyName != null) return keyValues[keyName];
        const attributeName = findKeyCaseInsensitive(attributes, name);
        const value = attributeName != null ? attributes[attributeName] : undefined;
        if (attributeName == null || value == null || String(value).length === 0) return null;
        consumed.add(attributeName);
        return String(value);
    }

    /**
     * Request body per the IO's body shape:
     *  - `flat` / null → the attributes, minus read-only IOFs and the keys that addressed the request;
     *  - `wrapped`     → the same, under `CreateBodyKey` / `UpdateBodyKey`;
     *  - `literal`     → {@link buildLiteralBody}.
     * PATCH bodies are first-level only: nested values are sent whole, never deep-merged.
     */
    private buildWriteBody(
        obj: MJIntegrationObjectEntity,
        fields: MJIntegrationObjectFieldEntity[],
        attributes: Record<string, unknown>,
        columns: WriteColumns,
        consumed: Set<string>,
    ): unknown {
        if (columns.BodyShape === 'literal') return this.buildLiteralBody(obj, fields, attributes, consumed);
        const readOnly = new Set(fields.filter(f => f.IsReadOnly).map(f => f.Name));
        const body: Record<string, unknown> = {};
        for (const [key, value] of Object.entries(attributes)) {
            if (consumed.has(key) || readOnly.has(key)) continue;
            body[key] = value;
        }
        return columns.BodyShape === 'wrapped' && columns.BodyKey ? { [columns.BodyKey]: body } : body;
    }

    /**
     * The documented `literal` request DTOs, derived from metadata rather than object names:
     *  - an object declaring `customAttributePrefix` (e.g. OrderAttributesPatch) takes ONLY its
     *    custom-attribute keys;
     *  - otherwise the non-addressing attributes, keeping JSON fields (a DTO built around a collection,
     *    e.g. PriceListPatch.prices — JSON text is sent as structured JSON, shaped by the IOF's declared
     *    `writeShape`) but dropping read-only scalars. JSON-ness is the DECLARED shape ({@link isDeclaredJson}),
     *    never the runtime Type alone, which discovery overlays (json → nvarchar(MAX));
     *  - an association IO (`ioKind = association`) posts to its collection, which takes an ARRAY:
     *    the single record is sent as a one-element array.
     */
    private buildLiteralBody(
        obj: MJIntegrationObjectEntity,
        fields: MJIntegrationObjectFieldEntity[],
        attributes: Record<string, unknown>,
        consumed: Set<string>,
    ): unknown {
        const cfg = this.objectConfig(obj);
        const prefix = cfg.customAttributePrefix?.toLowerCase();
        const byName = new Map(fields.map(f => [f.Name, f]));
        const body: Record<string, unknown> = {};
        for (const [key, value] of Object.entries(attributes)) {
            if (consumed.has(key)) continue;
            if (prefix) {
                if (key.toLowerCase().startsWith(prefix)) body[key] = value;
                continue;
            }
            const field = byName.get(key);
            if (field && this.isDeclaredJson(field)) body[key] = this.writeShaped(field, this.structuredJSON(value));
            else if (!field?.IsReadOnly) body[key] = value;
        }
        return cfg.ioKind === 'association' ? [body] : body;
    }

    private structuredJSON(value: unknown): unknown {
        if (typeof value !== 'string') return value;
        try {
            return JSON.parse(value) as unknown;
        } catch {
            return value;
        }
    }

    /**
     * JSON by the DECLARED shape: `Type === 'json'`, or an IOF `Configuration.specType` that is a collection (`array<…>`), an
     * embedded model (`$ref:…`) or `object`. Runtime discovery overlays the column Type (json → nvarchar(MAX)), so the Type alone
     * silently turned a documented collection body into a dropped read-only scalar. A typed reference (`valuePath`) is a scalar id.
     */
    private isDeclaredJson(field: MJIntegrationObjectFieldEntity): boolean {
        if (field.Type === 'json') return true;
        const parsed = ZFieldConfig.safeParse(parseJSONObject(field.Configuration) ?? {});
        if (!parsed.success || parsed.data.valuePath) return false;
        return /^(array<|\$ref:|object$)/.test(parsed.data.specType ?? '');
    }

    /**
     * Shapes a collection value into its documented WRITE items when the IOF declares `Configuration.writeShape.itemProjection`
     * (write key → dotted read path): an item that already carries every write key passes through (pruned to them); a read-shape
     * item is projected; a reference stored as its bare id satisfies a trailing `.id` step. No projection → value unchanged.
     */
    private writeShaped(field: MJIntegrationObjectFieldEntity, value: unknown): unknown {
        const parsed = ZFieldConfig.safeParse(parseJSONObject(field.Configuration) ?? {});
        const projection = parsed.success ? parsed.data.writeShape?.itemProjection : undefined;
        if (!projection || !Array.isArray(value)) return value;
        const writeKeys = Object.keys(projection);
        return value.map(item => {
            if (!isPlainObject(item)) return item;
            if (writeKeys.every(k => k in item)) return Object.fromEntries(writeKeys.map(k => [k, item[k]]));
            const out: Record<string, unknown> = {};
            for (const [writeKey, readPath] of Object.entries(projection)) {
                const projected = readDottedPath(item, readPath);
                if (projected !== undefined) out[writeKey] = projected;
            }
            return out;
        });
    }

    private isEmptyBody(body: unknown): boolean {
        if (Array.isArray(body)) return body.every(item => isPlainObject(item) && Object.keys(item).length === 0);
        return isPlainObject(body) && Object.keys(body).length === 0;
    }

    /**
     * The created record's ExternalID in the SAME form the read path produces: for a composite key
     * (association rows like CustomerTag = id + customerId) the member id from the response (or the
     * posted id echoed back in a collection response) joined with the parent key from the path.
     */
    private createdExternalID(
        fields: MJIntegrationObjectFieldEntity[],
        response: RESTResponse,
        idLocation: string | null,
        attributes: Record<string, unknown>,
        resolved: ResolvedOperationPath,
    ): string | undefined {
        const keys = fields.filter(f => f.IsPrimaryKey).sort((a, b) => a.Sequence - b.Sequence).map(f => f.Name);
        const memberID = this.ExtractIDFromResponse(response, idLocation) ?? this.postedIDEchoed(response, attributes);
        if (keys.length <= 1) return memberID;
        const parts: string[] = [];
        for (const key of keys) {
            const fromPath = resolved.PathValues[key];
            const attributeName = findKeyCaseInsensitive(attributes, key);
            const fromAttributes = attributeName != null && attributes[attributeName] != null ? String(attributes[attributeName]) : undefined;
            const value = key.toLowerCase() === 'id' ? (memberID ?? fromAttributes) : (fromPath ?? fromAttributes);
            if (value == null || value.length === 0) return undefined;
            parts.push(value);
        }
        return parts.join('|');
    }

    private postedIDEchoed(response: RESTResponse, attributes: Record<string, unknown>): string | undefined {
        if (!Array.isArray(response.Body)) return undefined;
        const idName = findKeyCaseInsensitive(attributes, 'id');
        const posted = idName != null ? attributes[idName] : undefined;
        if (posted == null) return undefined;
        const echoed = response.Body.some(item => isPlainObject(item) && item.id != null && String(item.id) === String(posted));
        return echoed ? String(posted) : undefined;
    }

    // ═══ Private: metadata access ═════════════════════════════════════════════════════════════════

    private objectConfig(obj: MJIntegrationObjectEntity): SpektrixObjectConfig {
        const cached = this.objectConfigs.get(obj);
        if (cached) return cached;
        const parsed = ZObjectConfig.safeParse(parseJSONObject(obj.Configuration) ?? {});
        const cfg: SpektrixObjectConfig = parsed.success ? parsed.data : {};
        this.objectConfigs.set(obj, cfg);
        return cfg;
    }

    private integrationConfig(integrationID: string): z.infer<typeof ZIntegrationConfig> | null {
        let integration: MJIntegrationEntity | undefined;
        try {
            integration = IntegrationEngineBase.Instance.GetIntegrationByID(integrationID);
        } catch {
            return null;
        }
        const parsed = ZIntegrationConfig.safeParse(parseJSONObject(integration?.Configuration) ?? {});
        return parsed.success ? parsed.data : null;
    }

    private integrationIDByName(): string | null {
        try {
            return IntegrationEngineBase.Instance.GetIntegrationByName(this.IntegrationName)?.ID ?? null;
        } catch {
            return null;
        }
    }

    private activeObjects(integrationID: string): MJIntegrationObjectEntity[] {
        try {
            return IntegrationEngineBase.Instance.GetActiveIntegrationObjects(integrationID);
        } catch {
            return [];
        }
    }

    private anyActiveObject(predicate: (obj: MJIntegrationObjectEntity) => boolean): boolean {
        const integrationID = this.integrationIDByName();
        return integrationID ? this.activeObjects(integrationID).some(predicate) : false;
    }

    private tryGetObject(integrationID: string, objectName: string): MJIntegrationObjectEntity | null {
        try {
            return IntegrationEngineBase.Instance.GetIntegrationObject(integrationID, objectName) ?? null;
        } catch {
            return null;
        }
    }

    private singlePrimaryKey(obj: MJIntegrationObjectEntity): string | null {
        const keys = this.GetCachedFields(obj.ID).filter(f => f.IsPrimaryKey);
        return keys.length === 1 ? keys[0].Name : null;
    }

    /** The object's get-by-id door path (`GET /orders/{id}` → `/orders/{id}`), when exactly one var addresses it. */
    private getByIdDoor(cfg: SpektrixObjectConfig): string | null {
        const door = (cfg.alternateDoors ?? []).find(d => d.doorKind === 'get-by-id');
        const match = door ? /^GET\s+(\S+)$/i.exec(door.door.trim()) : null;
        return match && templateVarsOf(match[1]).length === 1 ? match[1] : null;
    }

    private fieldTransformPlan(obj: MJIntegrationObjectEntity, fields: MJIntegrationObjectFieldEntity[]): FieldTransformPlan {
        const source = IntegrationEngineBase.Instance.IntegrationObjectFields;
        if (this.fieldPlanSource !== source) {
            this.fieldPlans = new UUIDMap<FieldTransformPlan>();
            this.fieldPlanSource = source;
        }
        const cached = this.fieldPlans.Get(obj.ID);
        if (cached) return cached;
        const plan: FieldTransformPlan = { Projections: [], EmbeddedJson: [] };
        for (const field of fields) {
            const parsed = ZFieldConfig.safeParse(parseJSONObject(field.Configuration) ?? {});
            const valuePath = parsed.success ? parsed.data.valuePath : undefined;
            if (valuePath) plan.Projections.push({ Field: field.Name, ValuePath: valuePath });
            else if (field.Type === 'json') plan.EmbeddedJson.push(field.Name);
        }
        if (fields.length > 0) this.fieldPlans.Set(obj.ID, plan);
        return plan;
    }
}
