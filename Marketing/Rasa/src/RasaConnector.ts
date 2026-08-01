import { RegisterClass } from '@memberjunction/global';
import { Metadata, type IMetadataProvider, type UserInfo } from '@memberjunction/core';
import type {
    MJCompanyIntegrationEntity,
    MJCredentialEntity,
    MJIntegrationObjectEntity,
} from '@memberjunction/core-entities';
import { mergeDeclaredWithSampledFields } from '@memberjunction/connector-schema-merge';
import { IntegrationEngineBase } from '@memberjunction/integration-engine-base';
import {
    BaseIntegrationConnector,
    BaseRESTIntegrationConnector,
    type ConnectionTestResult,
    type ExternalFieldSchema,
    type ExternalObjectSchema,
    type ExternalRecord,
    type FetchBatchResult,
    type FetchContext,
    type FetchWarning,
    type GetRecordContext,
    type PaginationState,
    type PaginationType,
    type RESTAuthContext,
    type RESTResponse,
    type SourceSchemaInfo,
} from '@memberjunction/integration-engine';
import { z } from 'zod';

// ─── Vendor constants (mechanism, NOT catalog) ───────────────────────
//
// These are transport facts about the rasa.io SERVICE, not a schema: the host root, the
// credential-free schema-of-record URLs, and timing. No object list, no field list, no
// constraint, and nothing tenant-specific lives in this file — the object/field universe is
// DISCOVERED at runtime (public OpenAPI walk + persisted Declared metadata + live sampling).

/**
 * Host ROOT (no version segment). The frozen contract's `apiBaseURLNote` records that each
 * IntegrationObject's `APIPath` already carries its own `/v1` or `/v2` prefix, so a version-scoped
 * base double-prefixes (`…/v1` + `/v2/lists` → `/v1/v2/lists` → HTTP 404). Both generations hang
 * off the host root. Overridable per connection via `BaseURL`.
 */
const RASA_API_HOST = 'https://api.rasa.io';

/**
 * Credential-free schema-of-record. rasa.io publishes both API generations as public Swagger 2.0
 * documents (SOURCES.json, Tier 1 / OpenAPISpec, both HTTP 200 unauthenticated). Discovery reads
 * THESE — a live credential is purely ADDITIVE (it only contributes tenant-observed customs), so
 * `DiscoverObjects`/`DiscoverFields` re-yield the full standard universe with no token.
 */
const RASA_PUBLIC_SPEC_URLS: readonly string[] = [
    'https://api-docs.rasa.io/v1/swagger.json',
    'https://api-docs.rasa.io/swagger.json',
];

/** Token lifetime guard — refresh well inside the JWT `exp` the vendor issues. */
const TOKEN_TTL_MS = 45 * 60 * 1000;

/** Per-request timeout. */
const REQUEST_TIMEOUT_MS = 60_000;

/** Timeout for the credential-free public-spec fetch used by discovery. */
const SPEC_FETCH_TIMEOUT_MS = 20_000;

/** Transport retry budget (network blips, 401 token refresh, 429 back-off). */
const MAX_RETRIES = 3;

/**
 * Page-size fallback when an IntegrationObject declares no `DefaultPageSize`. The v1 spec caps
 * `limit` at 50 (`maximum: 50` on GET /persons); v2 defaults to 50. Never used to OVERRIDE a
 * metadata-declared page size — only as the floor when metadata is silent.
 */
const RASA_FALLBACK_PAGE_SIZE = 50;

// ─── Config / envelope typing (Zod — no `any`) ───────────────────────

const RasaConnectionConfigSchema = z.object({
    /** rasa.io API key presented in the token-exchange body. */
    APIKey: z.string().min(1),
    /** Account username (email) for the token-exchange HTTP Basic header. */
    Username: z.string().min(1),
    /** Account password for the token-exchange HTTP Basic header. */
    Password: z.string().min(1),
    /** Optional host override (self-hosted / proxy / test double). Defaults to the vendor host root. */
    BaseURL: z.string().url().optional(),
});

/** Connection configuration parsed from the MJ Credential (or CompanyIntegration.Configuration). */
export type RasaConnectionConfig = z.infer<typeof RasaConnectionConfigSchema>;

/** Auth context carried through the REST pipeline. */
interface RasaAuthContext extends RESTAuthContext {
    Config: RasaConnectionConfig;
}

/**
 * Per-object vendor specifics the canonical IntegrationObject columns have no home for. Emitted by
 * the extractor into `IntegrationObject.Configuration`; read here, never invented.
 */
const RasaObjectConfigSchema = z.object({
    apiVersion: z.string().optional(),
    /** Swagger definition name(s) backing this object — the bridge into the public spec. */
    recordSchemas: z.array(z.string()).optional(),
    /** Query-param name carrying the incremental watermark (`updated_since` / `created_since` / …). */
    watermarkParam: z.string().optional(),
    /**
     * RealityProbe `recordEnvelopeShape` verdict, materialized by the extractor: the per-record path to
     * unwrap BEFORE field mapping (e.g. `data` → `results[].data`). ABSENT means the verdict is
     * `flat`-or-unverified for this object and the connector MUST NOT unwrap (see NormalizeResponse).
     */
    recordUnwrapPath: z.string().optional(),
    /** Nested-graph access path: the door, the descent, and the owning parent object. */
    accessPath: z
        .object({
            door: z.string().optional(),
            nesting: z.array(z.string()).optional(),
            parentObject: z.string().nullable().optional(),
            parentKeyField: z.string().nullable().optional(),
        })
        .optional(),
}).passthrough();

type RasaObjectConfig = z.infer<typeof RasaObjectConfigSchema>;

/** Minimal Swagger 2.0 shape this connector reads. Opaque elsewhere. */
interface SwaggerSchema {
    $ref?: string;
    type?: string;
    format?: string;
    description?: string;
    items?: SwaggerSchema;
    properties?: Record<string, SwaggerSchema>;
    required?: string[];
    maxLength?: number;
}
interface SwaggerOperation {
    summary?: string;
    description?: string;
    responses?: Record<string, { schema?: SwaggerSchema }>;
}
interface SwaggerDoc {
    definitions?: Record<string, SwaggerSchema>;
    paths?: Record<string, Record<string, SwaggerOperation>>;
}

/** A record type discovered from the public spec. */
interface SpecRecordType {
    /** Swagger definition name, e.g. `PersonsApiGetResponseItem`. */
    DefinitionName: string;
    /** The readable path it was reached through, for the description. */
    Door: string;
    /** Operation summary from the spec, when present. */
    Summary?: string;
}

/** Response context for the current fetch — the base's NormalizeResponse signature carries no object. */
interface RasaResponseContext {
    ObjectName: string;
    /** Fully-resolved extraction path (ResponseDataKey composed with the verdicted unwrap path). */
    DataPath: string | null;
    /** Whether an envelope-unwrap verdict was DECLARED for this object. */
    UnwrapDeclared: boolean;
}

// ─── Connector ───────────────────────────────────────────────────────

/**
 * rasa.io connector (v1 + v2 REST, single host).
 *
 * Everything routine rides `BaseRESTIntegrationConnector`'s metadata-driven machinery — generic
 * per-operation CRUD, pagination loop, template-var/parent iteration, record→ExternalRecord
 * conversion. Four things are genuinely idiosyncratic and are the ONLY behavioural overrides:
 *
 *  1. **Two-step auth** — `POST /v1/tokens` (HTTP Basic + `{key}` body) mints a JWT that every
 *     subsequent request presents in a CUSTOM `rasa-token` header, not `Authorization: Bearer`.
 *  2. **`skip`/`limit` + response-metadata paging** — the base emits `offset`/`limit`; rasa.io uses
 *     `skip`/`limit` (RealityProbe: "'skip' advanced past page 1 via offset") and drives the loop from
 *     `metadata.next_link`, whose own `skip` value is numeric for offset endpoints and an opaque token
 *     for others.
 *  3. **`*_since` watermarks** — the incremental filter is a per-object query param
 *     (`updated_since` / `created_since` / `archived_since`) read from the frozen contract.
 *  4. **Conditional per-record envelope unwrapping** — rasa.io wraps each record JSON:API-style as
 *     `{data, links}` on SOME objects. Driven strictly by the per-object `recordUnwrapPath` verdict;
 *     never guessed (see {@link NormalizeResponse}).
 */
/** CANONICAL registration key — the repo's catalog convention is `ClassName` == the npm package name, so
 *  instance discovery matches. `Integration.ClassName` is seeded to this value.
 *  The short `RasaConnector` key below stays registered for continuity: `ConnectorFactory.Resolve` looks the
 *  Integration row's ClassName up verbatim in the ClassFactory, so any tenant row still carrying the legacy
 *  short name resolves rather than failing with "No connector registered". Zero cost to keep; removing it
 *  would be a breaking change independent of this release's rename. */
@RegisterClass(BaseIntegrationConnector, '@memberjunction/connector-rasa-io')
@RegisterClass(BaseIntegrationConnector, 'RasaConnector')
export class RasaConnector extends BaseRESTIntegrationConnector {
    // ── Instance state ───────────────────────────────────────────────

    /** Cached JWT + mint time (idiosyncrasy #1). */
    private cachedToken: string | null = null;
    private tokenObtainedAt = 0;

    /** Response context for the in-flight fetch (see {@link RasaResponseContext}). */
    private responseCtx: RasaResponseContext | null = null;

    /** Watermark value for the in-flight fetch — consumed by {@link AppendDefaultQueryParams}. */
    private currentWatermark: string | null = null;

    /** Non-fatal diagnostics raised during the in-flight fetch, drained into the FetchBatchResult. */
    private pendingWarnings: FetchWarning[] = [];

    /** Running max of the watermark FIELD across the batches of one object's sync pass. */
    private readonly watermarkHighWater = new Map<string, string>();

    /** Integration ID observed on the last operation — lets `StableOrderingKey(name)` reach the cache. */
    private lastIntegrationID: string | null = null;

    /** Merged public-spec cache (credential-free); populated lazily by discovery. */
    private specCache: { Definitions: Record<string, SwaggerSchema>; RecordTypes: SpecRecordType[] } | null = null;

    // ── Identity + capability ────────────────────────────────────────

    /** Verbatim from the identity handoff / `MJ: Integrations.Name`. */
    public override get IntegrationName(): string {
        return 'rasa';
    }

    /** v1 `POST /persons|/posts|/lead-posts`, v2 `POST /lists|/contacts|/subscriptions` — all metadata-driven. */
    public override get SupportsCreate(): boolean {
        return true;
    }

    /** v1 `PUT /persons/{id}|/posts/{id}|/lead-posts`, v2 `PUT /contacts/{id}|/subscriptions/{id}`. */
    public override get SupportsUpdate(): boolean {
        return true;
    }

    /** v1 `DELETE /persons/{id}` (GDPR hard delete), v2 `DELETE /contacts/{id}` (archive). */
    public override get SupportsDelete(): boolean {
        return true;
    }

    /**
     * `updated_since` / `created_since` are inclusive server-side filters over a monotonically
     * advancing timestamp column, so the highest value seen is a safe resume point.
     */
    public override get MonotonicWatermark(): boolean {
        return true;
    }

    /**
     * Keyset hint the extractor emitted per object (`IntegrationObject.StableOrderingKey`). Returns the
     * declared key, or null when the object has none — never a guess.
     */
    public override StableOrderingKey(objectName: string): string | null {
        if (!this.lastIntegrationID) return null;
        try {
            const obj = this.GetCachedObject(this.lastIntegrationID, objectName);
            const key = obj.StableOrderingKey;
            return key && key.trim().length > 0 ? key.trim() : null;
        } catch {
            return null;
        }
    }

    // ── Idiosyncrasy #1 — two-step token exchange ────────────────────

    /**
     * Step 1 of the vendor's documented flow: `POST {host}/v1/tokens` with an HTTP Basic
     * `Authorization` header AND a `{ key: <apiKey> }` body; the JWT comes back at
     * `results[0]['rasa-token']`. Step 2 (the custom header) is {@link BuildHeaders}.
     */
    protected async Authenticate(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<RESTAuthContext> {
        this.lastIntegrationID = companyIntegration.IntegrationID;
        const config = await this.ParseConfig(companyIntegration, contextUser);
        const token = await this.MintToken(config);
        const auth: RasaAuthContext = { Token: token, Config: config };
        return auth;
    }

    /** Mints (or reuses) the session JWT. Never logs any credential-derived value. */
    private async MintToken(config: RasaConnectionConfig): Promise<string> {
        if (this.cachedToken && Date.now() - this.tokenObtainedAt < TOKEN_TTL_MS) {
            return this.cachedToken;
        }
        const basic = Buffer.from(`${config.Username}:${config.Password}`, 'utf8').toString('base64');
        const response = await fetch(`${this.HostOf(config)}/v1/tokens`, {
            method: 'POST',
            headers: {
                Authorization: `Basic ${basic}`,
                'Content-Type': 'application/json',
                Accept: 'application/json',
            },
            body: JSON.stringify({ key: config.APIKey }),
            signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
        });
        if (!response.ok) {
            throw new Error(`[rasa] token exchange failed: HTTP ${response.status} from POST /v1/tokens`);
        }
        const token = this.ReadTokenFromBody(await response.json());
        if (!token) throw new Error('[rasa] token exchange succeeded but no "rasa-token" was present in the response');
        this.cachedToken = token;
        this.tokenObtainedAt = Date.now();
        return token;
    }

    /**
     * Reads the JWT out of the token envelope. Primary shape is the documented
     * `ApiResonseTokenCreated` → `results[0]['rasa-token']` (`definitions.RasaToken`); the `data`-wrapped
     * and v2 `access_token` shapes are accepted as transport tolerance, not as a schema claim.
     */
    private ReadTokenFromBody(body: unknown): string | null {
        const root = this.AsRecord(body);
        if (!root) return null;
        const candidates: Array<Record<string, unknown> | null> = [root];
        const results = root.results;
        if (Array.isArray(results) && results.length > 0) {
            const first = this.AsRecord(results[0]);
            candidates.unshift(first, this.AsRecord(first?.data));
        }
        for (const candidate of candidates) {
            if (!candidate) continue;
            for (const key of ['rasa-token', 'access_token', 'token']) {
                const value = candidate[key];
                if (typeof value === 'string' && value.length > 0) return value;
            }
        }
        return null;
    }

    /** Step 2: the JWT rides a CUSTOM header (`securityDefinitions.authorizer`), not `Authorization`. */
    protected BuildHeaders(auth: RESTAuthContext): Record<string, string> {
        return {
            'rasa-token': auth.Token ?? '',
            Accept: 'application/json',
            'Content-Type': 'application/json',
        };
    }

    /** Host root for every request; APIPath supplies its own `/v1` or `/v2` segment. */
    protected GetBaseURL(_companyIntegration: MJCompanyIntegrationEntity, auth: RESTAuthContext): string {
        return this.HostOf((auth as RasaAuthContext).Config);
    }

    private HostOf(config: RasaConnectionConfig | undefined): string {
        return (config?.BaseURL ?? RASA_API_HOST).replace(/\/+$/, '');
    }

    // ── Transport ────────────────────────────────────────────────────

    /**
     * HTTP transport with bounded retry: network blips, a 401 (mint a fresh JWT and replay once the
     * cached one has aged out), and 429 honouring `Retry-After` when the vendor sends one.
     */
    protected async MakeHTTPRequest(
        auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown,
    ): Promise<RESTResponse> {
        for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
            let response: Response;
            try {
                response = await fetch(url, this.BuildRequestInit(method, headers, body));
            } catch (err) {
                if (attempt < MAX_RETRIES && this.IsRetriableNetworkError(err)) {
                    await this.Sleep(500 * (attempt + 1));
                    continue;
                }
                throw err;
            }

            if (response.status === 401 && attempt < MAX_RETRIES) {
                this.cachedToken = null;
                const fresh = await this.MintToken((auth as RasaAuthContext).Config);
                auth.Token = fresh;
                headers['rasa-token'] = fresh;
                continue;
            }
            if (response.status === 429 && attempt < MAX_RETRIES) {
                await this.Sleep(this.RetryAfterMs(response.headers) ?? 2000 * 2 ** attempt);
                continue;
            }
            return this.ToRESTResponse(response);
        }
        throw new Error(`[rasa] request failed after ${MAX_RETRIES} retries: ${method} ${url}`);
    }

    private BuildRequestInit(method: string, headers: Record<string, string>, body?: unknown): RequestInit {
        const init: RequestInit = { method, headers, signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS) };
        if (body !== undefined && method.toUpperCase() !== 'GET') init.body = JSON.stringify(body);
        return init;
    }

    /** Normalizes a fetch Response, tolerating empty/non-JSON bodies (e.g. a 204 from DELETE). */
    private async ToRESTResponse(response: Response): Promise<RESTResponse> {
        const outHeaders: Record<string, string> = {};
        response.headers.forEach((value, key) => {
            outHeaders[key.toLowerCase()] = value;
        });
        const text = await response.text();
        let parsed: unknown = text;
        if (text.length === 0) parsed = null;
        else {
            try {
                parsed = JSON.parse(text) as unknown;
            } catch {
                /* leave as text — ExtractErrorMessage/NormalizeResponse both tolerate it */
            }
        }
        return { Status: response.status, Body: parsed, Headers: outHeaders };
    }

    /** `Retry-After` in seconds or as an HTTP-date; null when the vendor sent neither. */
    private RetryAfterMs(headers: Headers): number | null {
        const raw = headers.get('retry-after');
        if (!raw) return null;
        const seconds = Number(raw);
        if (Number.isFinite(seconds)) return Math.max(0, seconds * 1000);
        const when = Date.parse(raw);
        return Number.isFinite(when) ? Math.max(0, when - Date.now()) : null;
    }

    private IsRetriableNetworkError(err: unknown): boolean {
        if (!(err instanceof Error)) return false;
        const msg = err.message.toLowerCase();
        return ['timeout', 'abort', 'econnreset', 'econnrefused', 'enotfound', 'fetch failed'].some(t =>
            msg.includes(t),
        );
    }

    private Sleep(ms: number): Promise<void> {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    // ── Idiosyncrasy #4 — conditional per-record envelope unwrapping ──

    /**
     * Strips the rasa.io response envelope. TWO layers, both metadata-driven:
     *
     *  1. the LIST envelope — `{ code, event, metadata, results, status_code }` — via the object's
     *     `ResponseDataKey` (`results`, `results[].data`, `results[].lists`, …);
     *  2. the PER-RECORD envelope — rasa.io wraps some records JSON:API-style as `{ data, links }` —
     *     via the object's `Configuration.recordUnwrapPath`, which materializes the RealityProbe's
     *     `recordEnvelopeShape` verdict. Present ⇒ verdict was `nested` ⇒ unwrap. **Absent ⇒ we do NOT
     *     unwrap** — a missing verdict is DEFERRED, never resolved as "flat" by assumption. When an
     *     un-verdicted object nonetheless arrives looking exactly like the vendor's envelope
     *     (`{data, links}` and nothing else), we emit a `RECORD_ENVELOPE_UNVERIFIED` warning naming the
     *     object so the gap is loud in the run artifact rather than silently mis-mapped.
     */
    protected NormalizeResponse(rawBody: unknown, responseDataKey: string | null): Record<string, unknown>[] {
        const ctx = this.responseCtx;
        const path = ctx ? ctx.DataPath : responseDataKey;
        const records = this.ExtractByPath(rawBody, path);
        if (ctx && !ctx.UnwrapDeclared) this.FlagUndeclaredEnvelope(ctx.ObjectName, records);
        return records;
    }

    /**
     * Evaluates a dotted extraction path against a response body. A segment may be a plain key or a
     * `key[]` list segment; arrays are flattened either way, so `results`, `results[].data` and
     * `results[].data.topics` all resolve uniformly. A null path returns the body itself (array or object).
     */
    private ExtractByPath(body: unknown, path: string | null): Record<string, unknown>[] {
        if (body == null) return [];
        let current: unknown[] = Array.isArray(body) ? [...body] : [body];
        if (path) {
            for (const segment of path.split('.')) {
                const key = segment.endsWith('[]') ? segment.slice(0, -2) : segment;
                const next: unknown[] = [];
                for (const node of current) {
                    const record = this.AsRecord(node);
                    const value = record ? record[key] : undefined;
                    if (value == null) continue;
                    if (Array.isArray(value)) next.push(...value);
                    else next.push(value);
                }
                current = next;
            }
        }
        return current.filter((n): n is Record<string, unknown> => this.AsRecord(n) !== null);
    }

    /** Raises a one-per-fetch diagnostic when an un-verdicted object arrives inside the vendor envelope. */
    private FlagUndeclaredEnvelope(objectName: string, records: Record<string, unknown>[]): void {
        if (records.length === 0) return;
        const looksWrapped = records.every(r => {
            const keys = Object.keys(r);
            return keys.includes('data') && keys.every(k => k === 'data' || k === 'links');
        });
        if (!looksWrapped) return;
        if (this.pendingWarnings.some(w => w.Code === 'RECORD_ENVELOPE_UNVERIFIED' && w.Data?.object === objectName)) {
            return;
        }
        this.pendingWarnings.push({
            Code: 'RECORD_ENVELOPE_UNVERIFIED',
            Message:
                `"${objectName}": records arrived in the vendor's per-record envelope ({data,links}) but no ` +
                `recordEnvelopeShape verdict is declared for this object (Configuration.recordUnwrapPath is ` +
                `absent). The connector DEFERS rather than assuming a shape — re-run the reality probe for ` +
                `this object and amend the contract; field mapping is unreliable until then.`,
            Data: { object: objectName, observedTopLevelKeys: Object.keys(records[0]) },
        });
    }

    // ── Idiosyncrasy #2 — skip/limit + next_link paging ──────────────

    /**
     * rasa.io pages with `skip` + `limit` (NOT the base's `offset`/`limit`). The `skip` value is a
     * numeric offset on offset endpoints and an opaque token on the endpoints whose `next_link` carries
     * a non-numeric `skip` — {@link ExtractPaginationInfo} classifies it, we replay whichever it gave us.
     * `limit` is capped by the object's declared `DefaultPageSize` (the v1 spec's hard `maximum: 50`).
     */
    protected override BuildPaginatedURL(
        basePath: string,
        obj: MJIntegrationObjectEntity,
        _page: number,
        offset: number,
        cursor?: string,
        effectivePageSize?: number,
    ): string {
        const cap = obj.DefaultPageSize ?? RASA_FALLBACK_PAGE_SIZE;
        const limit = Math.max(1, Math.min(effectivePageSize ?? cap, cap));
        const params = new URLSearchParams();
        if (cursor) params.set('skip', cursor);
        else if (offset > 0) params.set('skip', String(offset));
        params.set('limit', String(limit));
        return `${basePath}${basePath.includes('?') ? '&' : '?'}${params.toString()}`;
    }

    /**
     * Drives the loop from the response-metadata envelope
     * (`PersonsApiResponseMetadata` / `InsightApiResponseMetadata` / v2 `ResponseMetadata`):
     * `next_link` is the vendor's own next-page URL. A short page (fewer records than requested) always
     * terminates — the vendor emits `next_link` past the end of the dataset, so it is not a sufficient
     * stop signal on its own.
     */
    protected ExtractPaginationInfo(
        rawBody: unknown,
        _paginationType: PaginationType,
        _currentPage: number,
        currentOffset: number,
        pageSize: number,
    ): PaginationState {
        const root = this.AsRecord(rawBody);
        const metadata = this.AsRecord(root?.metadata);
        const totalRecords = typeof metadata?.record_count === 'number' ? metadata.record_count : undefined;
        const returned = this.ExtractByPath(rawBody, this.responseCtx?.DataPath ?? 'results').length;

        if (returned === 0 || (pageSize > 0 && returned < pageSize)) {
            return { HasMore: false, TotalRecords: totalRecords };
        }
        const nextLink = typeof metadata?.next_link === 'string' ? metadata.next_link : '';
        if (nextLink.length === 0) return { HasMore: false, TotalRecords: totalRecords };

        const skip = this.ReadSkipParam(nextLink);
        if (skip !== null && !/^\d+$/.test(skip)) {
            return { HasMore: true, NextCursor: skip, TotalRecords: totalRecords };
        }
        const nextOffset = skip !== null ? Number(skip) : currentOffset + returned;
        return { HasMore: true, NextOffset: nextOffset, TotalRecords: totalRecords };
    }

    /** Reads the `skip` query param out of a vendor `next_link`, tolerating a relative URL. */
    private ReadSkipParam(nextLink: string): string | null {
        try {
            return new URL(nextLink, RASA_API_HOST).searchParams.get('skip');
        } catch {
            return null;
        }
    }

    // ── Idiosyncrasy #3 — *_since watermarks ─────────────────────────

    /**
     * Appends the object's declared incremental filter — `Configuration.watermarkParam`
     * (`updated_since` / `created_since` / `archived_since`) — to every request of a watermarked
     * object. Applied HERE rather than in {@link BuildPaginatedURL} so it also reaches non-paginated
     * single-page fetches. Never invents a param name: silent metadata ⇒ full pull.
     */
    protected override AppendDefaultQueryParams(url: string, obj: MJIntegrationObjectEntity): string {
        const withDefaults = super.AppendDefaultQueryParams(url, obj);
        const watermark = this.currentWatermark;
        if (!watermark || !obj.SupportsIncrementalSync) return withDefaults;
        const param = this.ObjectConfig(obj).watermarkParam;
        if (!param) return withDefaults;
        if (new RegExp(`[?&]${param}=`, 'i').test(withDefaults)) return withDefaults;
        const separator = withDefaults.includes('?') ? '&' : '?';
        return `${withDefaults}${separator}${encodeURIComponent(param)}=${encodeURIComponent(watermark)}`;
    }

    // ── Fetch orchestration ──────────────────────────────────────────

    /**
     * Thin wrapper around the base's metadata-driven fetch. It (a) publishes the per-object response
     * context the base's object-less `NormalizeResponse` signature can't carry, (b) bridges the frozen
     * contract's `accessPath.parentObject` onto the key the base's parent resolver reads, (c) tracks the
     * watermark high-water mark across the object's batches and emits it ONLY on the terminal batch, so
     * a mid-pass failure (which throws before we return) leaves the stored watermark untouched.
     */
    public override async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
        this.lastIntegrationID = ctx.CompanyIntegration.IntegrationID;
        const obj = this.GetCachedObject(ctx.CompanyIntegration.IntegrationID, ctx.ObjectName);
        this.AssertReadable(obj, ctx.ObjectName);
        this.PublishResponseContext(obj, ctx.ObjectName);
        this.BridgeAccessPathToParentConfig(obj);
        this.currentWatermark = ctx.WatermarkValue;
        this.pendingWarnings = [];
        if (this.IsFirstBatch(ctx)) this.watermarkHighWater.delete(ctx.ObjectName);

        const result = await super.FetchChanges(ctx);
        this.AdvanceWatermarkHighWater(ctx.ObjectName, obj, result.Records);

        const warnings = [...(result.Warnings ?? []), ...this.pendingWarnings];
        this.pendingWarnings = [];
        return {
            ...result,
            Warnings: warnings.length > 0 ? warnings : undefined,
            NewWatermarkValue: result.HasMore ? undefined : this.FinalWatermark(ctx),
        };
    }

    /**
     * Refuses a read against an object that declares NO read door, instead of letting the base compose a
     * request against the API ROOT. rasa.io has one such object — `Lead Post` is write-only (`APIPath`
     * empty, `CreateAPIPath: /v1/lead-posts`, Create+Update only) — and a caller that syncs "all objects"
     * will ask it to read. Without this guard the empty path resolves to `GET {baseURL}/`, whose failure
     * mode is worse than an error: if the vendor root ever answers 200 (a status/banner document), the
     * envelope reader would treat that payload as this object's record set. Fail precisely and name the
     * cause instead.
     */
    private AssertReadable(obj: MJIntegrationObjectEntity, objectName: string): void {
        if ((obj.APIPath ?? '').trim().length > 0) return;
        throw new Error(
            `Object "${objectName}" declares no read path (APIPath is empty) and cannot be read. ` +
                `It is write-only in this connector's contract; use its per-operation write path instead.`,
        );
    }

    /** GetRecord also runs NormalizeResponse — publish the same response context first. */
    public override async GetRecord(ctx: GetRecordContext): Promise<ExternalRecord | null> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        this.lastIntegrationID = ci.IntegrationID;
        this.PublishResponseContext(this.GetCachedObject(ci.IntegrationID, ctx.ObjectName), ctx.ObjectName);
        this.currentWatermark = null;
        return super.GetRecord(ctx);
    }

    private IsFirstBatch(ctx: FetchContext): boolean {
        return !ctx.CurrentOffset && !ctx.CurrentPage && !ctx.CurrentCursor && !ctx.AfterKeyValue;
    }

    /** Resolves and stores the extraction path + unwrap-verdict state for the object being fetched. */
    private PublishResponseContext(obj: MJIntegrationObjectEntity, objectName: string): void {
        const config = this.ObjectConfig(obj);
        this.responseCtx = {
            ObjectName: objectName,
            DataPath: this.EffectiveDataPath(obj, config),
            UnwrapDeclared: !!config.recordUnwrapPath,
        };
    }

    /**
     * Composes the LIST path (`ResponseDataKey`) with the verdicted PER-RECORD unwrap path. The unwrap
     * verdict is anchored at the list root, so `results` + `data` → `results[].data`, and
     * `results[].topics` + `data.topics` → `results[].data.topics` (the probe's re-point: the declared
     * fields live under `data`, not at the record root). No verdict ⇒ the declared key verbatim.
     */
    private EffectiveDataPath(obj: MJIntegrationObjectEntity, config: RasaObjectConfig): string | null {
        const declaredKey = obj.ResponseDataKey && obj.ResponseDataKey.length > 0 ? obj.ResponseDataKey : null;
        const unwrap = config.recordUnwrapPath;
        if (!unwrap) return declaredKey;
        const listRoot = (declaredKey ?? 'results').split('[]')[0].split('.')[0];
        return `${listRoot}[].${unwrap}`;
    }

    /**
     * The frozen contract expresses an object's owner as `Configuration.accessPath.parentObject`; the
     * base's template-var resolver reads `Configuration.parentObjectName`. Same declared fact, two
     * spellings — bridged here (in memory only, never persisted) so a `{var}` path resolves its parent
     * instead of returning PARENT_UNRESOLVED. Additive: an existing `parentObjectName` always wins.
     */
    private BridgeAccessPathToParentConfig(obj: MJIntegrationObjectEntity): void {
        if (!/\{\w+\}/.test(obj.APIPath ?? '')) return;
        const parent = this.ObjectConfig(obj).accessPath?.parentObject;
        if (!parent) return;
        try {
            const raw = obj.Configuration;
            const parsed = raw ? (JSON.parse(raw) as Record<string, unknown>) : {};
            if (typeof parsed.parentObjectName === 'string' && parsed.parentObjectName.length > 0) return;
            obj.Configuration = JSON.stringify({ ...parsed, parentObjectName: parent });
        } catch {
            /* unparseable configuration — the base already warns and skips rather than guessing */
        }
    }

    /** Folds this batch's watermark-field values into the object's running high-water mark. */
    private AdvanceWatermarkHighWater(
        objectName: string,
        obj: MJIntegrationObjectEntity,
        records: ExternalRecord[],
    ): void {
        const field = obj.IncrementalWatermarkField;
        if (!field || records.length === 0) return;
        let best = this.watermarkHighWater.get(objectName) ?? null;
        for (const record of records) {
            const raw = record.Fields[field];
            if (typeof raw !== 'string' && typeof raw !== 'number') continue;
            const candidate = String(raw);
            const parsed = Date.parse(candidate);
            if (!Number.isFinite(parsed)) continue;
            if (best === null || parsed > Date.parse(best)) best = candidate;
        }
        if (best !== null) this.watermarkHighWater.set(objectName, best);
    }

    /** Terminal-batch watermark: the run's high-water mark, else the caller's value unchanged. */
    private FinalWatermark(ctx: FetchContext): string | undefined {
        const best = this.watermarkHighWater.get(ctx.ObjectName);
        this.watermarkHighWater.delete(ctx.ObjectName);
        return best ?? ctx.WatermarkValue ?? undefined;
    }

    // ── Write-path envelope helpers (generic CRUD stays generic) ─────

    /**
     * The generic `CreateRecord` is used as-is; only ID extraction is vendor-shaped. rasa.io returns the
     * new record inside the standard envelope — `PersonApiPostResponse.example` is
     * `{ code, metadata, results: [ { id } ] }` — so the base's root-level `body.id` probe finds nothing.
     * We look at `results[0]` and, when the per-record envelope is in play, `results[0].data`.
     */
    protected override ExtractIDFromResponse(response: RESTResponse, idLocation: string | null): string | undefined {
        if (idLocation && idLocation !== 'body') return super.ExtractIDFromResponse(response, idLocation);
        const root = this.AsRecord(response.Body);
        const results = root?.results;
        const first = Array.isArray(results) && results.length > 0 ? this.AsRecord(results[0]) : null;
        for (const candidate of [first, this.AsRecord(first?.data), root]) {
            if (!candidate) continue;
            const value = candidate.id;
            if (typeof value === 'string' || typeof value === 'number') return String(value);
        }
        return super.ExtractIDFromResponse(response, idLocation);
    }

    /** Vendor error envelope: `metadata.errors` alongside the standard `code` / `status_code`. */
    protected override ExtractErrorMessage(response: RESTResponse): string | undefined {
        const root = this.AsRecord(response.Body);
        const errors = this.AsRecord(root?.metadata)?.errors;
        if (typeof errors === 'string' && errors.length > 0) return errors;
        if (Array.isArray(errors) && errors.length > 0) return JSON.stringify(errors);
        return super.ExtractErrorMessage(response);
    }

    // ── Discovery — credential-free public schema of record ──────────

    /**
     * Enumerates the object universe from rasa.io's PUBLICLY-PUBLISHED OpenAPI documents (both API
     * generations), unioned with the persisted Declared metadata. Deliberately credential-free: the
     * runtime structure self-check runs without a token, so standard objects MUST re-yield without one.
     * A live credential is additive only (see {@link IntrospectSchema}). If the specs are unreachable the
     * method degrades to the persisted set rather than failing the sync.
     */
    public override async DiscoverObjects(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<ExternalObjectSchema[]> {
        this.lastIntegrationID = companyIntegration.IntegrationID;
        const persisted = await super.DiscoverObjects(companyIntegration, contextUser);
        const spec = await this.LoadPublicSpecs();
        if (!spec) return persisted;

        const byName = new Map<string, ExternalObjectSchema>();
        for (const obj of persisted) byName.set(obj.Name.toLowerCase(), obj);

        const declaredBySchema = this.IndexDeclaredObjectsByRecordSchema(companyIntegration.IntegrationID);
        const declaredDoors = this.IndexDeclaredDoors(companyIntegration.IntegrationID);
        for (const recordType of spec.RecordTypes) {
            const mapped = declaredBySchema.get(recordType.DefinitionName);
            const name = mapped ?? this.DeriveObjectName(recordType.DefinitionName);
            // A spec record type whose DOOR is already served by a Declared object is that same
            // resource under its schema-derived alias, NOT a second object. Name dedup alone cannot
            // catch this: `DeriveObjectName('CommunitiesApiGetResponseItem')` yields the PLURAL
            // `Communities`, which never collides with the Declared singular `Community` — so the
            // pre-fix code emitted BOTH, i.e. two objects (two target tables) for one endpoint.
            // The door is the structural identity of a resource; compare on that.
            if (!mapped && declaredDoors.has(this.NormalizeDoor(recordType.Door))) continue;
            if (byName.has(name.toLowerCase())) continue;
            byName.set(name.toLowerCase(), {
                Name: name,
                Label: name,
                Description:
                    recordType.Summary ??
                    `Record type "${recordType.DefinitionName}" exposed at ${recordType.Door} (rasa.io public OpenAPI).`,
                SupportsIncrementalSync: false,
                SupportsWrite: false,
            });
        }
        return [...byName.values()];
    }

    /**
     * Fields for one object: the persisted Declared set, unioned with every property the PUBLIC spec
     * declares on the object's backing definitions (`Configuration.recordSchemas`). Credential-free —
     * a token contributes nothing here. Declared entries win on collision; spec-only properties are
     * appended so a vendor schema addition surfaces without a metadata re-extract.
     */
    public override async DiscoverFields(
        companyIntegration: MJCompanyIntegrationEntity,
        objectName: string,
        contextUser: UserInfo,
    ): Promise<ExternalFieldSchema[]> {
        this.lastIntegrationID = companyIntegration.IntegrationID;
        const declared = await this.SafeDeclaredFields(companyIntegration, objectName, contextUser);
        const schemaNames = this.RecordSchemaNamesFor(companyIntegration.IntegrationID, objectName);
        const spec = schemaNames.length > 0 ? await this.LoadPublicSpecs() : null;
        if (!spec) return declared;

        const byName = new Map<string, ExternalFieldSchema>();
        for (const field of declared) byName.set(field.Name.toLowerCase(), field);
        for (const schemaName of schemaNames) {
            for (const field of this.FieldsFromDefinition(spec.Definitions, schemaName)) {
                if (!byName.has(field.Name.toLowerCase())) byName.set(field.Name.toLowerCase(), field);
            }
        }
        return [...byName.values()];
    }

    /**
     * Sample-union enrichment (MJ connector standard): after the cache-driven introspection, sample each
     * object's LIVE read shape and union it into the declared field set — this is where a tenant's own
     * custom person attributes reach the schema. Best-effort; a sample failure leaves the declared set
     * untouched. Overrides `IntrospectSchema`, NOT `DiscoverFields` (which would recurse into
     * `DiscoverFieldsViaFetch`'s own fallback).
     *
     * SEQUENTIAL, and that is load-bearing. {@link FetchChanges} publishes its per-object response
     * context onto INSTANCE state (`responseCtx`/`currentWatermark`/`pendingWarnings`) which is read
     * back AFTER the HTTP round-trip. Sampling the catalog with `Promise.all` therefore raced: every
     * concurrent call overwrote `responseCtx`, so a response was normalized against some OTHER object's
     * `DataPath`, matched nothing, and yielded ZERO records — cleanly, with no throw and no warning.
     * Observed live: 17 of 18 objects that reached the sampler logged `rows=0 | cols: []`, the sole
     * survivor being the one that happened to win the race, and the resulting all-null field widths
     * were what made the framework's unknown-width defect drop 8,841 records. The sync engine iterates
     * objects sequentially, which is why the identical read path works there. Do not re-parallelize
     * this without first threading the response context through the call instead of the instance.
     */
    public override async IntrospectSchema(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<SourceSchemaInfo> {
        const info = await super.IntrospectSchema(companyIntegration, contextUser);
        for (const obj of info.Objects) {
            try {
                const sampled = await this.DiscoverFieldsViaFetch(companyIntegration, obj.ExternalName, contextUser);
                obj.Fields = mergeDeclaredWithSampledFields(obj.Fields, sampled);
            } catch (err) {
                // Best-effort — the declared set stands. But NEVER swallow silently: a bare `catch {}`
                // here is what hid 16 objects failing before they ever reached the sampler.
                console.warn(
                    `[RasaConnector.IntrospectSchema] sample-union skipped for "${obj.ExternalName}": ` +
                        `${err instanceof Error ? err.message : String(err)}`,
                );
            }
        }
        return info;
    }

    /** Declared fields, tolerating an object the cache doesn't carry (a spec-only discovery). */
    private async SafeDeclaredFields(
        companyIntegration: MJCompanyIntegrationEntity,
        objectName: string,
        contextUser: UserInfo,
    ): Promise<ExternalFieldSchema[]> {
        try {
            return await super.DiscoverFields(companyIntegration, objectName, contextUser);
        } catch {
            return [];
        }
    }

    /** The Swagger definition name(s) backing an object, per its declared `Configuration.recordSchemas`. */
    private RecordSchemaNamesFor(integrationID: string, objectName: string): string[] {
        try {
            return this.ObjectConfig(this.GetCachedObject(integrationID, objectName)).recordSchemas ?? [];
        } catch {
            return [];
        }
    }

    /** Reverse index: Swagger definition name → the Declared object that claims it. */
    private IndexDeclaredObjectsByRecordSchema(integrationID: string): Map<string, string> {
        const index = new Map<string, string>();
        for (const obj of this.ActiveObjects(integrationID)) {
            for (const schemaName of this.ObjectConfig(obj).recordSchemas ?? []) {
                if (!index.has(schemaName)) index.set(schemaName, obj.Name);
            }
        }
        return index;
    }

    /**
     * The set of doors (normalized endpoint paths) already served by a Declared object. Used to suppress
     * spec-only "objects" that are really an alias of a Declared resource — see the door test in
     * {@link DiscoverObjects}. Both the frozen contract's `accessPath.door` and the row's own `APIPath`
     * are indexed, since either may carry the endpoint for a given object.
     */
    private IndexDeclaredDoors(integrationID: string): Set<string> {
        const doors = new Set<string>();
        for (const obj of this.ActiveObjects(integrationID)) {
            for (const raw of [this.ObjectConfig(obj).accessPath?.door, obj.APIPath]) {
                const normalized = this.NormalizeDoor(raw);
                if (normalized.length > 0) doors.add(normalized);
            }
        }
        return doors;
    }

    /**
     * Canonical form of an endpoint path for identity comparison: version segment dropped (a Declared
     * `APIPath` carries `/v1`|`/v2`; a Swagger 2.0 path key does not — the prefix lives in `basePath`),
     * path parameters collapsed to `{}` (`/persons/{id}/topics` ≡ `/persons/{person_id}/topics`), and
     * casing/trailing slashes normalized.
     */
    private NormalizeDoor(path: string | null | undefined): string {
        if (!path) return '';
        return path
            .replace(/^\/?(v\d+)\//i, '/')
            .replace(/\{[^}]*\}/g, '{}')
            .replace(/\/+$/, '')
            .toLowerCase();
    }

    /**
     * Every ACTIVE IntegrationObject for this integration, read from the same engine cache the base
     * class reads (`IntegrationEngineBase.GetActiveIntegrationObjects`). Empty when the engine has not
     * been configured yet — discovery then degrades to the spec-only naming, never throws.
     */
    private ActiveObjects(integrationID: string): MJIntegrationObjectEntity[] {
        try {
            return IntegrationEngineBase.Instance.GetActiveIntegrationObjects(integrationID);
        } catch {
            return [];
        }
    }

    // ── Public-spec reading ──────────────────────────────────────────

    /**
     * Fetches + merges rasa.io's public Swagger documents (v1 and v2) with NO credential, and walks
     * every readable operation to enumerate RECORD TYPES (not entry points): each GET's success schema
     * is resolved through the `{code, metadata, results[]}` envelope down to the item definition. Only
     * the item type itself is yielded — nested `$ref`'d sub-objects are NOT promoted to record types
     * (see {@link EnumerateRecordTypes}). Cached for the process lifetime.
     */
    private async LoadPublicSpecs(): Promise<{ Definitions: Record<string, SwaggerSchema>; RecordTypes: SpecRecordType[] } | null> {
        if (this.specCache) return this.specCache;
        const docs: SwaggerDoc[] = [];
        for (const url of RASA_PUBLIC_SPEC_URLS) {
            const doc = await this.FetchSpec(url);
            if (doc) docs.push(doc);
        }
        if (docs.length === 0) return null;

        const definitions: Record<string, SwaggerSchema> = {};
        for (const doc of docs) Object.assign(definitions, doc.definitions ?? {});
        const recordTypes: SpecRecordType[] = [];
        const seen = new Set<string>();
        for (const doc of docs) {
            for (const found of this.EnumerateRecordTypes(doc, definitions)) {
                if (seen.has(found.DefinitionName)) continue;
                seen.add(found.DefinitionName);
                recordTypes.push(found);
            }
        }
        this.specCache = { Definitions: definitions, RecordTypes: recordTypes };
        return this.specCache;
    }

    private async FetchSpec(url: string): Promise<SwaggerDoc | null> {
        try {
            const response = await fetch(url, {
                method: 'GET',
                headers: { Accept: 'application/json' },
                signal: AbortSignal.timeout(SPEC_FETCH_TIMEOUT_MS),
            });
            if (!response.ok) return null;
            return (await response.json()) as SwaggerDoc;
        } catch {
            return null; // offline / blocked — discovery degrades to the persisted Declared set
        }
    }

    /** Walks every readable operation in one document, yielding the record types it exposes. */
    private EnumerateRecordTypes(doc: SwaggerDoc, definitions: Record<string, SwaggerSchema>): SpecRecordType[] {
        const out: SpecRecordType[] = [];
        for (const [path, operations] of Object.entries(doc.paths ?? {})) {
            for (const [method, operation] of Object.entries(operations)) {
                if (method.toLowerCase() !== 'get') continue;
                const schema = operation.responses?.['200']?.schema ?? operation.responses?.['201']?.schema;
                const itemName = this.ResolveRecordDefinitionName(schema, definitions);
                if (!itemName) continue;
                out.push({ DefinitionName: itemName, Door: path, Summary: operation.summary });
                // Deliberately NOT promoting `$ref`'d child properties to objects. A child definition
                // (`AttributesItem`, `UserAction`, `AnalyticsActivityData`, `ExternalIdentifier`, …) is a
                // nested structure of its parent record, reachable only THROUGH the parent's door. Emitted
                // as a top-level object it carries no door of its own, so it can never be fetched — a
                // permanently-empty target table. When a child collection IS independently syncable, the
                // Declared metadata says so with its own `accessPath` (door + nesting) and its
                // `recordSchemas` claims the definition, so `declaredBySchema` already maps it and it is
                // already present in `persisted`. Promoting the UNdeclared remainder can therefore only
                // ever manufacture junk. Measured on rasa.io: this loop plus plural-alias duplication
                // inflated discovery to 52 objects against 34 Declared.
            }
        }
        return out;
    }

    /** Descends the `{code, metadata, results[]}` envelope to the item definition name. */
    private ResolveRecordDefinitionName(
        schema: SwaggerSchema | undefined,
        definitions: Record<string, SwaggerSchema>,
    ): string | null {
        const rootName = this.RefName(schema);
        const root = rootName ? definitions[rootName] : schema;
        if (!root) return null;
        const results = root.properties?.results;
        const itemName = this.RefName(results?.items) ?? this.RefName(results);
        if (itemName) {
            const item = definitions[itemName];
            // One more hop when the item is itself the {data, links} per-record envelope.
            const inner = this.RefName(item?.properties?.data);
            return inner ?? itemName;
        }
        return rootName;
    }

    private RefName(schema: SwaggerSchema | undefined): string | null {
        const ref = schema?.$ref;
        if (typeof ref !== 'string') return null;
        const parts = ref.split('/');
        return parts.length > 0 ? parts[parts.length - 1] : null;
    }

    /** Maps a Swagger definition's properties onto ExternalFieldSchema. Constraints come from the spec only. */
    private FieldsFromDefinition(
        definitions: Record<string, SwaggerSchema>,
        definitionName: string,
    ): ExternalFieldSchema[] {
        const definition = definitions[definitionName];
        if (!definition?.properties) return [];
        const required = new Set(definition.required ?? []);
        return Object.entries(definition.properties).map(([name, property]) => ({
            Name: name,
            Label: name,
            Description: property.description,
            DataType: property.format ?? property.type ?? 'string',
            IsRequired: required.has(name),
            IsUniqueKey: false,
            IsReadOnly: false,
            MaxLength: typeof property.maxLength === 'number' ? property.maxLength : null,
        }));
    }

    /** Human-readable object name for a spec-only record type (`PersonsApiGetResponseItem` → `Persons`). */
    private DeriveObjectName(definitionName: string): string {
        const stripped = definitionName
            .replace(/(Api)?(Get|Post|Put|Patch|Delete)?(Response|Request|Body)?(Item)?$/i, '')
            .replace(/(Api)$/i, '');
        const base = stripped.length > 0 ? stripped : definitionName;
        return base.replace(/([a-z0-9])([A-Z])/g, '$1 $2').trim();
    }

    // ── Connection test ──────────────────────────────────────────────

    /**
     * Proves the whole auth chain end-to-end: mint the JWT (step 1) and spend it on a read (step 2).
     * Uses `/v1/communities` — the smallest documented readable surface every v1 credential can reach.
     */
    public async TestConnection(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<ConnectionTestResult> {
        try {
            const config = await this.ParseConfig(companyIntegration, contextUser);
            const token = await this.MintToken(config);
            const response = await fetch(`${this.HostOf(config)}/v1/communities`, {
                method: 'GET',
                headers: { 'rasa-token': token, Accept: 'application/json' },
                signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
            });
            if (!response.ok) {
                return { Success: false, Message: `Connection failed: HTTP ${response.status} from GET /v1/communities` };
            }
            const communities = this.ExtractByPath(await response.json(), 'results');
            return {
                Success: true,
                Message: `Connected to rasa.io — ${communities.length} community(ies) reachable with this credential`,
                ServerVersion: 'rasa.io API v1 + v2',
            };
        } catch (err) {
            return { Success: false, Message: `Connection failed: ${err instanceof Error ? err.message : String(err)}` };
        }
    }

    // ── Configuration parsing ────────────────────────────────────────

    /** Credential record first (the supported path), CompanyIntegration.Configuration as the fallback. */
    private async ParseConfig(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser?: UserInfo,
        provider?: IMetadataProvider,
    ): Promise<RasaConnectionConfig> {
        if (companyIntegration.CredentialID) {
            return this.ParseConfigFromCredential(companyIntegration.CredentialID, contextUser, provider);
        }
        if (companyIntegration.Configuration) {
            return this.NormalizeConfigValues(JSON.parse(companyIntegration.Configuration) as Record<string, unknown>);
        }
        throw new Error('[rasa] connector requires either a CredentialID or a CompanyIntegration.Configuration JSON');
    }

    private async ParseConfigFromCredential(
        credentialID: string,
        contextUser?: UserInfo,
        provider?: IMetadataProvider,
    ): Promise<RasaConnectionConfig> {
        const md = provider ?? new Metadata();
        const credential = await md.GetEntityObject<MJCredentialEntity>('MJ: Credentials', contextUser);
        await credential.Load(credentialID);
        if (!credential.Values) throw new Error('[rasa] credential record has no Values JSON');
        return this.NormalizeConfigValues(JSON.parse(credential.Values) as Record<string, unknown>);
    }

    /** Case-insensitive key matching over the credential payload, then strict Zod validation. */
    private NormalizeConfigValues(values: Record<string, unknown>): RasaConnectionConfig {
        const read = (...aliases: string[]): string | undefined => {
            for (const [key, value] of Object.entries(values)) {
                if (typeof value !== 'string' || value.length === 0) continue;
                if (aliases.includes(key.toLowerCase())) return value;
            }
            return undefined;
        };
        const parsed = RasaConnectionConfigSchema.safeParse({
            APIKey: read('apikey', 'api_key', 'key'),
            Username: read('username', 'user', 'email'),
            Password: read('password', 'pass'),
            BaseURL: read('baseurl', 'base_url', 'host'),
        });
        if (!parsed.success) {
            const missing = parsed.error.issues.map(i => i.path.join('.')).join(', ');
            throw new Error(`[rasa] configuration is missing or invalid for: ${missing} (need APIKey, Username, Password)`);
        }
        return parsed.data;
    }

    // ── Small shared helpers ─────────────────────────────────────────

    /** Parses an IntegrationObject's Configuration JSON into the typed per-object shape. */
    private ObjectConfig(obj: MJIntegrationObjectEntity): RasaObjectConfig {
        try {
            const raw = obj.Configuration;
            if (!raw) return {};
            const parsed = RasaObjectConfigSchema.safeParse(JSON.parse(raw));
            return parsed.success ? parsed.data : {};
        } catch {
            return {};
        }
    }

    /** Narrows an unknown to a plain object record, or null. */
    private AsRecord(value: unknown): Record<string, unknown> | null {
        return value !== null && typeof value === 'object' && !Array.isArray(value)
            ? (value as Record<string, unknown>)
            : null;
    }
}
