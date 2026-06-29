import { RegisterClass } from '@memberjunction/global';
import { Metadata, type IMetadataProvider, type UserInfo } from '@memberjunction/core';
import type { MJCompanyIntegrationEntity, MJCredentialEntity, MJIntegrationObjectEntity } from '@memberjunction/core-entities';
import {
    BaseIntegrationConnector,
    BaseRESTIntegrationConnector,
    type RESTAuthContext,
    type RESTResponse,
    type PaginationState,
    type PaginationType,
    type ConnectionTestResult,
    type FetchContext,
    type FetchBatchResult,
    type RateLimitPolicy,
} from '@memberjunction/integration-engine';

// ─── Connection configuration ─────────────────────────────────────────

/**
 * Per-connection configuration for the Eventbrite Platform REST API v3 connector.
 *
 * Eventbrite has a single shared host (`https://www.eventbriteapi.com/v3`). Auth is
 * a Bearer token — either a long-lived private token (issued from the account API Keys
 * page) or an OAuth2 authorization-code access token. Both are used verbatim as
 * `Authorization: Bearer <token>`; the connector does not perform the token exchange
 * (the resolved token lives in the credential store).
 */
export interface EventbriteConnectionConfig {
    /**
     * The resolved Bearer token (private token OR OAuth2 access token). From the credential
     * store (keys PrivateToken / Token / AccessToken / apiKey). Secrets never live in code.
     */
    Token?: string;
    /**
     * Non-secret API host override (e.g. a local mock for replay/contract testing). When set,
     * it WINS over the production host. Mirrors the ORCID/Novi `ApiBaseUrl` pattern — required
     * for the mock-floor e2e testability tier.
     */
    ApiBaseUrl?: string;
    /** HTTP request timeout in milliseconds. Default: 30000. */
    RequestTimeoutMs?: number;
    /** Maximum retries for rate-limited / transient failures. Default: 4. */
    MaxRetries?: number;
    /** Minimum interval between outbound requests (ms). Default: 100. */
    MinRequestIntervalMs?: number;
}

/** Authenticated context carried through one request cycle. */
interface EventbriteAuthContext extends RESTAuthContext {
    Token: string;
    BaseUrl: string;
    Config: EventbriteConnectionConfig;
}

/** Eventbrite's pagination envelope shape returned alongside every list resource array. */
interface EventbritePagination {
    object_count?: number;
    page_number?: number;
    page_size?: number;
    page_count?: number;
    has_more_items?: boolean;
    continuation?: string;
}

// ─── Constants ────────────────────────────────────────────────────────

const PROD_API_HOST = 'https://www.eventbriteapi.com/v3';

const DEFAULT_REQUEST_TIMEOUT_MS = 30000;
const DEFAULT_MAX_RETRIES = 4;
const DEFAULT_MIN_REQUEST_INTERVAL_MS = 100;

/**
 * Eventbrite documents a default rate limit of 2,000 calls per hour per token
 * (≈0.55/s). Run conservatively under that: ~0.27 tokens/s with a small burst so the
 * engine's AIMD bucket throttles + backs off on the 429 HIT_RATE_LIMIT error.
 */
const RATE_LIMIT_TOKENS_PER_SEC = 0.27;
const RATE_LIMIT_BURST = 10;

// ─── Connector implementation ─────────────────────────────────────────

/**
 * Connector for the Eventbrite Platform REST API v3.
 *
 * Authenticates via a Bearer token (private token or OAuth2 access token, resolved
 * upstream and held in the credential store). Reads ride the base
 * {@link BaseRESTIntegrationConnector} pull path; this class overrides only the
 * genuinely Eventbrite-specific bits:
 *  - {@link BuildHeaders}: `Authorization: Bearer <token>` + `Accept: application/json`.
 *  - {@link GetBaseURL}: the shared `https://www.eventbriteapi.com/v3` host (or a
 *    non-secret `ApiBaseUrl` override for mock testing).
 *  - {@link NormalizeResponse}: unwraps the named-key list envelope (the IO's
 *    `ResponseDataKey`, e.g. `events`/`attendees`/`orders`) which sits alongside a
 *    `pagination` object; a bare object is a one-record detail; null → [].
 *  - {@link ExtractPaginationInfo} / {@link BuildPaginatedURL}: Eventbrite continuation-cursor
 *    pagination (`?continuation=<token>` + `pagination.has_more_items`/`.continuation`),
 *    plus the `changed_since=<watermark>` param for incremental objects (Order/Attendee) —
 *    fully metadata-driven (read `obj.IncrementalWatermarkField` + `obj.SupportsIncrementalSync`),
 *    NEVER keyed off a hardcoded object name.
 *  - {@link FetchChanges}: sets the watermark context, delegates to the base, then advances
 *    the watermark from the records' `changed` field on the final batch only (HasMore=false)
 *    so a partial-failure mid-pagination leaves the watermark unchanged.
 *
 * Create/Update/Delete use the generic per-operation column path
 * (CreateAPIPath/Method/BodyShape/BodyKey/IDLocation, Update*, Delete*) driven entirely
 * by the IO metadata — no per-verb override. Eventbrite uses POST for update (its
 * convention) and wrapped bodies for most resources (CreateBodyKey =
 * event|ticket_class|venue|discount|question|webhook|...). Parent template vars
 * ({organization_id}/{event_id}) are resolved by the engine's parent-iteration from each
 * IO's `Configuration.parentObjectName`.
 */
@RegisterClass(BaseIntegrationConnector, 'EventbriteConnector')
export class EventbriteConnector extends BaseRESTIntegrationConnector {

    /** Cached auth context (token + resolved host). */
    private authState: EventbriteAuthContext | null = null;
    /** Timestamp of the last outbound request, used for throttling. */
    private lastRequestTime = 0;
    /** Watermark for the current FetchChanges cycle, emitted as the IO's incremental param. */
    private currentWatermark: string | undefined;

    // ── Identity + capability getters ───────────────────────────────────

    /** Verbatim from the metadata Integration row — part of the three-way name invariant. */
    public override get IntegrationName(): string { return 'Eventbrite'; }

    // Eventbrite exposes a documented write API for a subset of objects (Events, Ticket
    // Classes, Venues, Discounts, Questions, Webhooks, Ticket Groups, Inventory Tiers, Event
    // Teams, Media). The generic per-operation path enforces null-capability honesty per IO
    // (an IO with no CreateAPIPath throws on create), so these getters reflect that SOME IOs
    // are writable; the actual writable set is each IO's per-op columns in the metadata.
    public override get SupportsCreate(): boolean { return true; }
    public override get SupportsUpdate(): boolean { return true; }
    public override get SupportsDelete(): boolean { return true; }

    // ── Sync-efficiency hooks ───────────────────────────────────────────

    /**
     * Eventbrite documents a default 2,000 calls/hour per token (HTTP 429 HIT_RATE_LIMIT
     * over it). Run under that ceiling; the engine's AIMD bucket throttles + backs off.
     */
    public override get RateLimitPolicy(): RateLimitPolicy | null {
        return { TokensPerSec: RATE_LIMIT_TOKENS_PER_SEC, Burst: RATE_LIMIT_BURST, ThrottleBackoffFactor: 0.5 };
    }

    /**
     * Cap how many EVENT/ORG parents a second-layer object (TicketClass, Attendee, Question,
     * EventTeam, InventoryTier, …) iterates per FetchChanges call. At Eventbrite's deliberately
     * conservative 0.27 tok/s (~3.7 s/request once the SHARED burst is spent by earlier objects in
     * the same sync), the base default of 10 parents costs ~37 s and blows the 30 s FetchChanges
     * op-timeout — the batch is then abandoned and the object syncs 0 records for any org with that
     * many events. A batch of 4 costs ~15 s (well under 30 s) and the engine resumes the remaining
     * parents via HasMore/keyset, so a high-event-count org still syncs completely.
     */
    protected override TemplateVarParentBatchSize(): number {
        return 4;
    }

    /** Parse Eventbrite's Retry-After header (delta-seconds or HTTP-date) into milliseconds. */
    public override ExtractRetryAfterMs(error: unknown): number | undefined {
        const headers = (error as { Headers?: Record<string, string> })?.Headers;
        if (!headers) return undefined;
        const retryAfter = headers['retry-after'] ?? headers['Retry-After'];
        if (typeof retryAfter !== 'string' || retryAfter.length === 0) return undefined;
        const asSeconds = Number(retryAfter);
        if (!isNaN(asSeconds) && asSeconds >= 0) return Math.round(asSeconds * 1000);
        const asDate = Date.parse(retryAfter);
        if (!isNaN(asDate)) {
            const delta = asDate - Date.now();
            if (delta > 0) return delta;
        }
        return undefined;
    }

    // ─── TestConnection ──────────────────────────────────────────────

    /**
     * Verifies connectivity via `GET /users/me/`. A 2xx confirms the Bearer token is valid;
     * a 401/403 means the token was rejected (NOT_AUTH / NOT_PERMITTED).
     */
    public async TestConnection(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<ConnectionTestResult> {
        try {
            const auth = await this.Authenticate(companyIntegration, contextUser) as EventbriteAuthContext;
            const headers = this.BuildHeaders(auth);
            const probeUrl = `${auth.BaseUrl}/users/me/`;
            const resp = await this.MakeHTTPRequest(auth, probeUrl, 'GET', headers);
            if (resp.Status === 401 || resp.Status === 403) {
                return { Success: false, Message: `Eventbrite TestConnection failed: HTTP ${resp.Status} (token rejected)` };
            }
            if (resp.Status >= 500) {
                return { Success: false, Message: `Eventbrite TestConnection failed: HTTP ${resp.Status} (server error)` };
            }
            if (resp.Status < 200 || resp.Status >= 300) {
                return { Success: false, Message: `Eventbrite returned HTTP ${resp.Status} from ${probeUrl}` };
            }
            return {
                Success: true,
                Message: `Connected to Eventbrite Platform API v3 at ${auth.BaseUrl}`,
                ServerVersion: 'Eventbrite API v3',
            };
        } catch (err: unknown) {
            const message = err instanceof Error ? err.message : String(err);
            return { Success: false, Message: `Connection failed: ${message}` };
        }
    }

    // ─── FetchChanges (watermark-aware) ───────────────────────────────

    /**
     * Sets the watermark context that {@link BuildPaginatedURL} emits as the IO's
     * incremental `changed_since` param (for Order/Attendee), delegates the actual fetch +
     * cursor pagination to the base, then advances the watermark from the returned records'
     * `changed` field on the FINAL batch only (HasMore=false) so a partial-failure
     * mid-pagination leaves the watermark unchanged.
     */
    public override async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
        this.currentWatermark = ctx.WatermarkValue ?? undefined;

        const result = await super.FetchChanges(ctx);

        const obj = this.GetCachedObject(ctx.CompanyIntegration.IntegrationID, ctx.ObjectName);
        if (obj.SupportsIncrementalSync && obj.IncrementalWatermarkField && !result.HasMore) {
            const advanced = this.ExtractLatestWatermark(result.Records, obj.IncrementalWatermarkField);
            const newWatermark = advanced ?? ctx.WatermarkValue ?? undefined;
            if (newWatermark != null) return { ...result, NewWatermarkValue: newWatermark };
        }
        return result;
    }

    /**
     * Scans a batch for the latest watermark value. Eventbrite's incremental objects
     * (Order, Attendee) carry a `changed` ISO-8601 timestamp per record (the field named by
     * the IO's `IncrementalWatermarkField`); we take the max so the next run's `changed_since`
     * resumes from there.
     */
    private ExtractLatestWatermark(
        records: { Fields: Record<string, unknown> }[],
        watermarkField: string
    ): string | null {
        let latest: Date | null = null;
        for (const rec of records) {
            const raw = rec.Fields?.[watermarkField];
            if (typeof raw !== 'string' || raw.length === 0) continue;
            const d = new Date(raw);
            if (!isNaN(d.getTime()) && (latest === null || d > latest)) latest = d;
        }
        return latest ? latest.toISOString() : null;
    }

    // ─── Auth + transport (abstract base requirements) ────────────────

    protected async Authenticate(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<RESTAuthContext> {
        if (this.authState) return this.authState;
        const config = await this.parseConfig(companyIntegration, contextUser);
        const state: EventbriteAuthContext = {
            Token: config.Token ?? '',
            BaseUrl: this.resolveBaseUrl(config),
            Config: config,
        };
        this.authState = state;
        return state;
    }

    /** Builds the Eventbrite auth header: `Authorization: Bearer <token>` + `Accept: application/json`. */
    protected BuildHeaders(auth: RESTAuthContext): Record<string, string> {
        const ebAuth = auth as EventbriteAuthContext;
        return {
            'Authorization': `Bearer ${ebAuth.Token}`,
            'Accept': 'application/json',
            'Content-Type': 'application/json',
        };
    }

    /**
     * Unwraps Eventbrite's response shapes:
     *  - List endpoints: `{ <responseDataKey>: [ ... ], pagination: { ... } }` → the named array.
     *  - Single-record detail (no responseDataKey): a bare object → a one-element array.
     *  - null → [].
     * The IO metadata's `responseDataKey` (e.g. `events`/`attendees`/`orders`) is the
     * authoritative envelope key; when absent the body is treated as a bare detail object.
     */
    protected NormalizeResponse(rawBody: unknown, responseDataKey: string | null): Record<string, unknown>[] {
        if (rawBody == null) return [];
        const asObj = this.asObject(rawBody);

        // Explicit metadata-declared envelope key wins (the list case).
        if (responseDataKey && asObj) {
            if (responseDataKey in asObj) return this.coerceToArray(asObj[responseDataKey]);
            // Key declared but absent (e.g. an error or empty envelope) — nothing to emit.
            return [];
        }
        if (asObj) {
            // Bare single-record detail object (no responseDataKey, e.g. User / Media / Organizer).
            return [asObj];
        }
        // Bare array fallback (defensive — Eventbrite list shapes are always keyed).
        if (Array.isArray(rawBody)) return rawBody.filter(this.isRecord) as Record<string, unknown>[];
        return [];
    }

    private coerceToArray(node: unknown): Record<string, unknown>[] {
        if (Array.isArray(node)) return node.filter(this.isRecord) as Record<string, unknown>[];
        if (node && typeof node === 'object') return [node as Record<string, unknown>];
        return [];
    }

    private isRecord(node: unknown): node is Record<string, unknown> {
        return node != null && typeof node === 'object' && !Array.isArray(node);
    }

    /**
     * Continuation-cursor pagination: Eventbrite returns a `pagination` envelope carrying
     * `has_more_items` (boolean) and `continuation` (opaque cursor token). There are more
     * records while `has_more_items` is true AND a continuation token is present. The
     * total record count (`object_count`) is surfaced when available.
     *
     * The `Cursor` pagination type drives this; non-cursor objects (`None`) report no more.
     */
    protected ExtractPaginationInfo(
        rawBody: unknown,
        paginationType: PaginationType,
        currentPage: number,
        currentOffset: number,
        _pageSize: number
    ): PaginationState {
        if (paginationType !== 'Cursor') {
            return { HasMore: false, NextPage: currentPage, NextOffset: currentOffset };
        }
        const asObj = this.asObject(rawBody);
        const pagination = asObj ? this.asObject(asObj['pagination']) as EventbritePagination | undefined : undefined;

        const hasMore = pagination?.has_more_items === true
            && typeof pagination?.continuation === 'string'
            && pagination.continuation.length > 0;
        const totalRecords = typeof pagination?.object_count === 'number' ? pagination.object_count : undefined;

        return {
            HasMore: hasMore,
            NextPage: currentPage + 1,
            NextOffset: currentOffset,
            NextCursor: hasMore ? pagination?.continuation : undefined,
            TotalRecords: totalRecords,
        };
    }

    /**
     * Builds the paginated request URL. Eventbrite cursor pagination uses `?continuation=<token>`
     * (the base default emits `?cursor=...&limit=...`), so we override to emit the vendor's
     * param. Also emits the IO's `IncrementalWatermarkField` as `changed_since=<watermark>`
     * when this is an incremental object (Order/Attendee) and a watermark is in context —
     * fully metadata-driven (read `obj.IncrementalWatermarkField` + `obj.SupportsIncrementalSync`),
     * NEVER keyed off a hardcoded object name.
     *
     * Parent template vars ({organization_id}/{event_id}) are NOT substituted here — those are
     * resolved by the engine's parent-iteration from the IO's `Configuration.parentObjectName`.
     */
    protected override BuildPaginatedURL(
        basePath: string,
        obj: MJIntegrationObjectEntity,
        _page: number,
        _offset: number,
        cursor?: string,
        _effectivePageSize?: number
    ): string {
        const separator = basePath.includes('?') ? '&' : '?';
        const params = new URLSearchParams();

        // Incremental param (changed_since) for objects that declare a watermark field.
        const watermarkParam = this.resolveWatermarkParam(obj);
        if (obj.SupportsIncrementalSync && watermarkParam && this.currentWatermark) {
            params.set(watermarkParam, this.currentWatermark);
        }

        // Continuation cursor for the Cursor pagination type (after the first page).
        if (obj.PaginationType === 'Cursor' && cursor) {
            params.set('continuation', cursor);
        }

        const qs = params.toString();
        return qs.length > 0 ? `${basePath}${separator}${qs}` : basePath;
    }

    /**
     * Resolves the vendor-side query param name for an incremental object. Eventbrite's
     * incremental filter param is `changed_since` (the IO's `IncrementalWatermarkField` is the
     * RECORD field `changed`). Metadata-driven: only objects whose `SupportsIncrementalSync` is
     * true and whose watermark field is set receive the param.
     */
    private resolveWatermarkParam(obj: MJIntegrationObjectEntity): string | undefined {
        if (!obj.SupportsIncrementalSync || !obj.IncrementalWatermarkField) return undefined;
        return 'changed_since';
    }

    protected GetBaseURL(
        _companyIntegration: MJCompanyIntegrationEntity,
        auth: RESTAuthContext
    ): string {
        return (auth as EventbriteAuthContext).BaseUrl;
    }

    // ─── HTTP transport with retry + throttling ───────────────────────

    protected async MakeHTTPRequest(
        auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown
    ): Promise<RESTResponse> {
        const ebAuth = auth as EventbriteAuthContext;
        const cfg = ebAuth.Config;
        const maxRetries = cfg.MaxRetries ?? DEFAULT_MAX_RETRIES;
        const timeoutMs = cfg.RequestTimeoutMs ?? DEFAULT_REQUEST_TIMEOUT_MS;
        const minInterval = cfg.MinRequestIntervalMs ?? DEFAULT_MIN_REQUEST_INTERVAL_MS;

        for (let attempt = 0; attempt <= maxRetries; attempt++) {
            await this.throttle(minInterval);
            try {
                const resp = await this.doFetch(url, method, headers, body, timeoutMs);
                this.lastRequestTime = Date.now();

                if ((resp.Status === 429 || resp.Status === 503) && attempt < maxRetries) {
                    await this.sleep(this.backoffFromResponse(resp, attempt));
                    continue;
                }
                return resp;
            } catch (err: unknown) {
                if (attempt === maxRetries) throw err;
                if (!this.isRetryableError(err)) throw err;
                await this.sleep(this.backoffMs(attempt));
            }
        }
        throw new Error(`Eventbrite request to ${url} exhausted ${maxRetries + 1} attempts`);
    }

    /** Single fetch() with an AbortController-backed timeout. */
    private async doFetch(
        url: string,
        method: string,
        headers: Record<string, string>,
        body: unknown,
        timeoutMs: number
    ): Promise<RESTResponse> {
        const controller = new AbortController();
        const handle = setTimeout(() => controller.abort(), timeoutMs);
        try {
            const resp = await fetch(url, {
                method,
                headers,
                body: body !== undefined && method !== 'GET' ? JSON.stringify(body) : undefined,
                signal: controller.signal,
            });
            const respHeaders: Record<string, string> = {};
            resp.headers.forEach((value, key) => { respHeaders[key.toLowerCase()] = value; });
            const text = await resp.text();
            const parsed = text.length > 0 ? this.safeParseJSON(text) : null;
            return { Status: resp.status, Body: parsed, Headers: respHeaders };
        } finally {
            clearTimeout(handle);
        }
    }

    private safeParseJSON(text: string): unknown {
        try { return JSON.parse(text) as unknown; } catch { return text; }
    }

    private isRetryableError(err: unknown): boolean {
        const msg = err instanceof Error ? err.message : String(err);
        return /abort|timeout|ECONNRESET|ENOTFOUND|ETIMEDOUT|ECONNREFUSED|fetch failed|network/i.test(msg);
    }

    private backoffMs(attempt: number): number {
        const base = Math.min(1000 * Math.pow(2, attempt), 20000);
        const jitter = Math.floor(Math.random() * 500);
        return base + jitter;
    }

    private backoffFromResponse(resp: RESTResponse, attempt: number): number {
        const fromHeader = this.ExtractRetryAfterMs({ Headers: resp.Headers });
        if (fromHeader != null) return Math.min(fromHeader, 30000);
        return this.backoffMs(attempt);
    }

    private async throttle(minIntervalMs: number): Promise<void> {
        const elapsed = Date.now() - this.lastRequestTime;
        if (elapsed < minIntervalMs) await this.sleep(minIntervalMs - elapsed);
    }

    private sleep(ms: number): Promise<void> {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    private asObject(node: unknown): Record<string, unknown> | undefined {
        return node && typeof node === 'object' && !Array.isArray(node) ? node as Record<string, unknown> : undefined;
    }

    // ─── Config parsing ───────────────────────────────────────────────

    /**
     * Resolves the connection config: the Bearer token from the credential store; the
     * non-secret host override + transport tunables from CompanyIntegration.Configuration.
     * Secrets are NEVER baked into code.
     */
    private async parseConfig(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<EventbriteConnectionConfig> {
        const fromCredential = companyIntegration.CredentialID
            ? await this.loadFromCredential(companyIntegration.CredentialID, contextUser)
            : null;
        const fromConfig = this.parseConfigurationJson(companyIntegration.Configuration);

        const merged: EventbriteConnectionConfig = { ...fromConfig, ...fromCredential };
        // Credential's Token wins; host override + tunables come from Configuration.
        merged.Token = (fromCredential?.Token ?? fromConfig.Token);
        merged.ApiBaseUrl = merged.ApiBaseUrl ?? fromConfig.ApiBaseUrl;
        merged.RequestTimeoutMs = merged.RequestTimeoutMs ?? fromConfig.RequestTimeoutMs;
        merged.MaxRetries = merged.MaxRetries ?? fromConfig.MaxRetries;
        merged.MinRequestIntervalMs = merged.MinRequestIntervalMs ?? fromConfig.MinRequestIntervalMs;

        if (!merged.Token) {
            throw new Error(
                'EventbriteConnector: a Bearer token (PrivateToken / Token / AccessToken / apiKey) ' +
                'must be provided via the credential store or CompanyIntegration.Configuration.'
            );
        }
        return merged;
    }

    /** Resolves the API host: the non-secret override wins over the production host. */
    private resolveBaseUrl(config: EventbriteConnectionConfig): string {
        const raw = (config.ApiBaseUrl ?? PROD_API_HOST).trim();
        return raw.replace(/\/+$/, '');
    }

    /** Parses the non-secret host/tunables config from CompanyIntegration.Configuration JSON. */
    private parseConfigurationJson(raw: string | null): EventbriteConnectionConfig {
        if (!raw || raw.trim().length === 0) return {};
        let parsed: Record<string, unknown>;
        try {
            parsed = JSON.parse(raw) as Record<string, unknown>;
        } catch {
            throw new Error('EventbriteConnector: CompanyIntegration.Configuration is not valid JSON.');
        }
        const str = (...keys: string[]): string | undefined => {
            for (const k of keys) {
                const hit = Object.entries(parsed).find(([key]) => key.toLowerCase() === k.toLowerCase());
                if (hit && typeof hit[1] === 'string' && hit[1].length > 0) return hit[1] as string;
            }
            return undefined;
        };
        const num = (...keys: string[]): number | undefined => {
            for (const k of keys) {
                const hit = Object.entries(parsed).find(([key]) => key.toLowerCase() === k.toLowerCase());
                if (hit && typeof hit[1] === 'number') return hit[1] as number;
            }
            return undefined;
        };
        return {
            // A token MAY be carried in Configuration for credential-free replay harnesses;
            // the credential store remains preferred (parseConfig gives fromCredential precedence).
            Token: str('PrivateToken', 'Token', 'AccessToken', 'accessToken', 'apiKey', 'api_key'),
            ApiBaseUrl: str('apiBaseUrl', 'api_base_url', 'APIBaseURL', 'baseUrl', 'base_url'),
            RequestTimeoutMs: num('requestTimeoutMs'),
            MaxRetries: num('maxRetries'),
            MinRequestIntervalMs: num('minRequestIntervalMs'),
        };
    }

    /** Loads the Bearer token from the MJ credential store. */
    private async loadFromCredential(
        credentialID: string,
        contextUser: UserInfo,
        provider?: IMetadataProvider
    ): Promise<EventbriteConnectionConfig | null> {
        const md = provider ?? new Metadata();
        const credential = await md.GetEntityObject<MJCredentialEntity>('MJ: Credentials', contextUser);
        const loaded = await credential.Load(credentialID);
        if (!loaded || !credential.Values) return null;
        let raw: Record<string, unknown>;
        try {
            raw = JSON.parse(credential.Values) as Record<string, unknown>;
        } catch {
            return null;
        }
        const get = (...keys: string[]): string | undefined => {
            for (const k of keys) {
                const hit = Object.entries(raw).find(([key]) => key.toLowerCase() === k.toLowerCase());
                if (hit && typeof hit[1] === 'string') return hit[1] as string;
            }
            return undefined;
        };
        return {
            Token: get('PrivateToken', 'Token', 'AccessToken', 'accessToken', 'apiKey', 'api_key', 'key'),
        };
    }
}

/** Tree-shaking prevention function — import and call from the package entry point. */
export function LoadEventbriteConnector(): void { /* no-op */ }
