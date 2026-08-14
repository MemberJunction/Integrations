import { RegisterClass } from '@memberjunction/global';
import { Metadata, type IMetadataProvider, type UserInfo } from '@memberjunction/core';
import type {
    MJCompanyIntegrationEntity,
    MJCredentialEntity,
    MJIntegrationObjectEntity,
} from '@memberjunction/core-entities';
import {
    BaseIntegrationConnector,
    BaseRESTIntegrationConnector,
    type ActionGeneratorConfig,
    type ConnectionTestResult,
    type IntegrationObjectInfo,
    type PaginationState,
    type PaginationType,
    type RateLimitPolicy,
    type RESTAuthContext,
    type RESTResponse,
} from '@memberjunction/integration-engine';
import { BILLCOM_OBJECTS } from './generated/objects.js';

// ── Constants ────────────────────────────────────────────────────────

/** Sandbox gateway. Deliberately the default — a mis-provisioned connection must not reach production. */
const BILLCOM_SANDBOX_BASE = 'https://gateway.stage.bill.com/connect/v3';
/** Production gateway. Note `gateway.prod.bill.com`, NOT `gateway.bill.com`. */
const BILLCOM_PRODUCTION_BASE = 'https://gateway.prod.bill.com/connect/v3';

/** `max` ceiling on list endpoints. The concepts page says the default is 100 and the endpoint
 *  reference pages say 20 — so we always send it explicitly rather than trusting either. */
const BILLCOM_LIST_MAX_PAGE = 100;

/**
 * Sessions expire after 35 minutes of INACTIVITY (sliding, not absolute) and there is no refresh
 * mechanism — re-login is the only recovery. We proactively re-login at 25 minutes idle so a long
 * sync never discovers expiry mid-batch. The 10-minute margin absorbs clock skew and a slow request.
 */
const BILLCOM_SESSION_IDLE_MS = 25 * 60 * 1000;

/**
 * 3 concurrent requests per developer key per organization (error `BDC_1322`). This is the binding
 * constraint on sync design — far tighter than the 20,000/hour ceiling (`BDC_1144`), which no
 * realistic sync approaches. The engine's token bucket enforces the rate; MaxConcurrencyHint
 * enforces the parallelism.
 */
const BILLCOM_MAX_CONCURRENCY = 3;

/** 20,000 requests/hour ≈ 5.5/sec sustained. Kept conservative; concurrency is the real limit. */
const BILLCOM_TOKENS_PER_SEC = 5;

// ── Types ────────────────────────────────────────────────────────────

/** Credentials resolved from `MJ: Credentials.Values` or `CompanyIntegration.Configuration`. */
interface BillComCredentials {
    Username: string;
    Password: string;
    OrganizationID: string;
    DevKey: string;
    /** 'sandbox' | 'production'. Drives the default base URL when ApiUrl is absent. */
    Environment?: string;
    /** Explicit override; wins over Environment. */
    ApiUrl?: string;
}

/** Auth context for Bill.com. The base `RESTAuthContext` already models `SessionID` for session APIs. */
interface BillComAuthContext extends RESTAuthContext {
    SessionID: string;
    DevKey: string;
    BaseURL: string;
    /** Epoch ms of the last request made on this session — drives idle-expiry detection. */
    LastUsedAt: number;
}

/** Bill.com list envelope. `nextPage`/`prevPage` are opaque cursor tokens. */
interface BillComListEnvelope {
    results?: unknown[];
    nextPage?: string;
    prevPage?: string;
}

/**
 * Bill.com (BILL) v3 Connect API connector — accounts receivable.
 *
 * Serves the AIDP AR use cases: create an invoice for an order, cancel an unpaid invoice, and detect
 * received payments. Refunds are deliberately absent: v3 has no AR refund endpoint, `/v3/orders` does
 * not exist, and negative invoices are unsupported. The sanctioned reversing document is a credit memo,
 * which adjusts the ledger without moving money — see the catalog notes and bc-aidp-next-golive#51.
 *
 * Three vendor characteristics shape this class:
 *
 *  1. **Session auth, not OAuth or a static key.** `POST /login` returns an opaque `sessionId` carried
 *     on subsequent calls alongside `devKey`. Sessions die after 35 minutes idle with no refresh, and
 *     logins are capped at 200/hour — so the session is cached, re-used, and only re-acquired when
 *     genuinely stale or rejected.
 *  2. **Concurrency capped at 3** per devKey per org. Declared via MaxConcurrencyHint.
 *  3. **Opaque cursor pagination.** `nextPage` is a token, not a number, and its ABSENCE — not an empty
 *     page — is the termination signal.
 *
 * DUAL registration: the class-symbol key `BillComConnector` is the natural handle; the package-name key
 * is what the Integrations repo's `validate-invariants` requires to be `@RegisterClass`-exported by the
 * package's own src, and it must match `Integration.ClassName` in the catalog.
 */
@RegisterClass(BaseIntegrationConnector, 'BillComConnector')
@RegisterClass(BaseIntegrationConnector, '@memberjunction/connector-bill-com')
export class BillComConnector extends BaseRESTIntegrationConnector {
    /** Cached session. Reused across requests; re-acquired on idle expiry or a 401. */
    private cachedAuth: BillComAuthContext | null = null;
    /** Credentials retained so a mid-run re-login does not need another metadata round-trip. */
    private cachedCredentials: BillComCredentials | null = null;

    // ── Identity & capabilities ──────────────────────────────────────

    public override get IntegrationName(): string {
        return 'Bill.com';
    }

    public override get SupportsCreate(): boolean { return true; }
    public override get SupportsUpdate(): boolean { return true; }
    public override get SupportsDelete(): boolean { return false; }

    /**
     * Bill.com exposes no describe-all endpoint, so a discovery pass that fails to see an object proves
     * nothing about whether it exists. Absence must never deactivate a declared object.
     */
    public override get DiscoveryIsAuthoritative(): boolean {
        return false;
    }

    public override get RateLimitPolicy(): RateLimitPolicy | null {
        return {
            TokensPerSec: BILLCOM_TOKENS_PER_SEC,
            Burst: BILLCOM_MAX_CONCURRENCY,
            ThrottleBackoffFactor: 0.5,
        };
    }

    public override get MaxConcurrencyHint(): number | null {
        return BILLCOM_MAX_CONCURRENCY;
    }

    // ── Action generation ────────────────────────────────────────────

    /**
     * Static object model for `ActionMetadataGenerator`. Returning `[]` — the base-class default — means
     * NO Actions can be generated for this connector at all, which is precisely why Business Central
     * ships none today.
     *
     * The list is generated by `scripts/extract-catalog.mjs` from the same OpenAPI extraction that
     * produces the sync catalog, so the Action surface and the catalog cannot drift apart.
     *
     * The generator emits Get/Search/List for every object, plus write verbs only where
     * `SupportsWrite` is true — so `receivable-payments` yields a Create ("charge a customer") but the
     * read verbs carry the payment-detection path.
     */
    public override GetIntegrationObjects(): IntegrationObjectInfo[] {
        return BILLCOM_OBJECTS;
    }

    public override GetActionGeneratorConfig(): ActionGeneratorConfig | null {
        return {
            IntegrationName: this.IntegrationName,
            CategoryName: 'Bill.com',
            IconClass: 'fa-solid fa-file-invoice-dollar',
            Objects: this.GetIntegrationObjects(),
        };
    }

    // ── Auth ─────────────────────────────────────────────────────────

    /**
     * Returns a live session, logging in only when necessary.
     *
     * Called once per FetchChanges, but a long sync can outlive the 35-minute idle window, so the
     * staleness check lives here AND a 401 retry lives in MakeHTTPRequest. Both paths matter: this one
     * avoids a predictable failure, that one recovers from an unpredictable one.
     */
    protected override async Authenticate(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<RESTAuthContext> {
        if (this.cachedAuth && !this.IsSessionStale(this.cachedAuth)) {
            return this.cachedAuth;
        }
        const creds = await this.LoadCredentials(companyIntegration, contextUser);
        this.cachedCredentials = creds;
        this.cachedAuth = await this.Login(creds);
        return this.cachedAuth;
    }

    /** True when the session has been idle long enough that Bill.com may have expired it. */
    private IsSessionStale(auth: BillComAuthContext): boolean {
        return Date.now() - auth.LastUsedAt >= BILLCOM_SESSION_IDLE_MS;
    }

    /**
     * `POST /login` → `{ sessionId, organizationId, userId }`.
     *
     * Throws rather than returning null: without a session nothing downstream can work, and a silent
     * failure here would surface later as an inscrutable 401 on an unrelated object.
     */
    private async Login(creds: BillComCredentials): Promise<BillComAuthContext> {
        const baseURL = this.ResolveBaseURL(creds);
        const response = await fetch(`${baseURL}/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
            body: JSON.stringify({
                username: creds.Username,
                password: creds.Password,
                organizationId: creds.OrganizationID,
                devKey: creds.DevKey,
            }),
        });

        const bodyText = await response.text();
        let parsed: Record<string, unknown> = {};
        try {
            parsed = bodyText.length > 0 ? (JSON.parse(bodyText) as Record<string, unknown>) : {};
        } catch {
            throw new Error(
                `Bill.com login returned non-JSON (HTTP ${response.status}): ${bodyText.slice(0, 200)}`
            );
        }

        const sessionId = typeof parsed.sessionId === 'string' ? parsed.sessionId : '';
        if (!response.ok || sessionId.length === 0) {
            const message = typeof parsed.message === 'string' ? parsed.message : bodyText.slice(0, 200);
            throw new Error(`Bill.com login failed (HTTP ${response.status}): ${message || 'no sessionId returned'}`);
        }

        return {
            SessionID: sessionId,
            DevKey: creds.DevKey,
            BaseURL: baseURL,
            LastUsedAt: Date.now(),
        };
    }

    /** Explicit `apiUrl` wins; otherwise environment selects a gateway, defaulting to sandbox. */
    private ResolveBaseURL(creds: BillComCredentials): string {
        if (creds.ApiUrl && creds.ApiUrl.trim().length > 0) {
            return creds.ApiUrl.trim().replace(/\/+$/, '');
        }
        return creds.Environment?.trim().toLowerCase() === 'production'
            ? BILLCOM_PRODUCTION_BASE
            : BILLCOM_SANDBOX_BASE;
    }

    protected override BuildHeaders(auth: RESTAuthContext): Record<string, string> {
        const ctx = auth as BillComAuthContext;
        return {
            'sessionId': ctx.SessionID,
            'devKey': ctx.DevKey,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        };
    }

    protected override GetBaseURL(companyIntegration: MJCompanyIntegrationEntity, auth: RESTAuthContext): string {
        const ctx = auth as BillComAuthContext | undefined;
        if (ctx?.BaseURL) return ctx.BaseURL;
        const cfg = companyIntegration?.Configuration;
        if (cfg) {
            try {
                const parsed = JSON.parse(cfg) as Record<string, unknown>;
                const override = parsed.apiUrl ?? parsed.ApiUrl ?? parsed.BaseURL;
                if (typeof override === 'string' && override.trim().length > 0) {
                    return override.trim().replace(/\/+$/, '');
                }
            } catch {
                /* Configuration is not JSON — fall through to the sandbox default */
            }
        }
        return BILLCOM_SANDBOX_BASE;
    }

    // ── Transport ────────────────────────────────────────────────────

    /**
     * HTTP transport. Owns the wire boundary — tests subclass and stub this.
     *
     * Re-logins once on a 401 and replays the request. A 401 here means the session lapsed despite the
     * idle check (clock skew, a server-side invalidation, a concurrent logout), and re-login is the only
     * recovery Bill.com offers. Exactly one retry: a second 401 is a credential problem, not a stale
     * session, and retrying would burn the 200/hour login budget.
     */
    protected override async MakeHTTPRequest(
        auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown
    ): Promise<RESTResponse> {
        const first = await this.SendOnce(url, method, headers, body);
        if (first.Status !== 401) {
            this.TouchSession(auth);
            return first;
        }

        if (!this.cachedCredentials) {
            // Nothing to re-login with — surface the 401 rather than pretend we can recover.
            return first;
        }

        this.cachedAuth = await this.Login(this.cachedCredentials);
        const retried = await this.SendOnce(url, method, this.BuildHeaders(this.cachedAuth), body);
        this.TouchSession(this.cachedAuth);
        return retried;
    }

    /** Single request/response cycle with no retry semantics. */
    private async SendOnce(
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown
    ): Promise<RESTResponse> {
        const init: RequestInit = { method, headers };
        if (body !== undefined && body !== null && method.toUpperCase() !== 'GET') {
            init.body = typeof body === 'string' ? body : JSON.stringify(body);
        }

        const response = await fetch(url, init);
        const text = await response.text();
        let parsedBody: unknown = null;
        if (text.length > 0) {
            try {
                parsedBody = JSON.parse(text);
            } catch {
                parsedBody = text;
            }
        }

        const responseHeaders: Record<string, string> = {};
        response.headers.forEach((value, key) => {
            responseHeaders[key.toLowerCase()] = value;
        });

        return { Status: response.status, Body: parsedBody, Headers: responseHeaders };
    }

    /** Records activity so the idle-expiry window is measured from the last real request. */
    private TouchSession(auth: RESTAuthContext): void {
        const ctx = auth as BillComAuthContext;
        if (typeof ctx.LastUsedAt === 'number') ctx.LastUsedAt = Date.now();
    }

    // ── Response shape ───────────────────────────────────────────────

    /**
     * List responses wrap rows in `results`; single-record reads return the object directly. The data key
     * is metadata-driven (`ResponseDataKey`) with a `results` fallback so the catalog stays authoritative.
     */
    protected override NormalizeResponse(rawBody: unknown, responseDataKey: string | null): Record<string, unknown>[] {
        if (rawBody == null) return [];
        if (Array.isArray(rawBody)) return rawBody as Record<string, unknown>[];
        if (typeof rawBody === 'object') {
            const body = rawBody as Record<string, unknown>;
            const key = responseDataKey ?? 'results';
            const arr = body[key];
            if (Array.isArray(arr)) return arr as Record<string, unknown>[];
            // Single-record read, or a write acknowledgement: the body IS the record.
            return [body];
        }
        return [];
    }

    /**
     * Pagination is an opaque cursor. `nextPage` is a token — never a page number — and its **absence**
     * is the termination signal. An empty `results` array with a `nextPage` present still means keep
     * going; treating an empty page as the end would silently truncate a sync.
     */
    protected override ExtractPaginationInfo(
        rawBody: unknown,
        _paginationType: PaginationType,
        _currentPage: number,
        _currentOffset: number,
        _pageSize: number
    ): PaginationState {
        if (rawBody && typeof rawBody === 'object') {
            const env = rawBody as BillComListEnvelope;
            if (typeof env.nextPage === 'string' && env.nextPage.length > 0) {
                return { HasMore: true, NextCursor: env.nextPage };
            }
        }
        return { HasMore: false };
    }

    /**
     * Appends `max` and, when continuing, the opaque `page` cursor. `max` is always sent explicitly
     * because the vendor docs disagree on the default (100 vs 20).
     */
    protected override BuildPaginatedURL(
        basePath: string,
        obj: MJIntegrationObjectEntity,
        _page: number,
        _offset: number,
        cursor?: string,
        effectivePageSize?: number
    ): string {
        const pageSize = Math.min(
            effectivePageSize ?? obj.DefaultPageSize ?? BILLCOM_LIST_MAX_PAGE,
            BILLCOM_LIST_MAX_PAGE
        );
        const separator = basePath.includes('?') ? '&' : '?';
        const parts = [`max=${pageSize}`];
        if (cursor) parts.push(`page=${encodeURIComponent(cursor)}`);
        return `${basePath}${separator}${parts.join('&')}`;
    }

    /** Bill.com reports failures as `{ message }` (sometimes `{ error }`) alongside a non-2xx status. */
    protected override ExtractErrorMessage(response: RESTResponse): string | undefined {
        const body = response.Body;
        if (body && typeof body === 'object') {
            const rec = body as Record<string, unknown>;
            for (const key of ['message', 'error', 'errorMessage', 'detail']) {
                const val = rec[key];
                if (typeof val === 'string' && val.length > 0) return val;
            }
        }
        if (typeof body === 'string' && body.length > 0) return body.slice(0, 300);
        return undefined;
    }

    // ── Connection test ──────────────────────────────────────────────

    /**
     * A successful `POST /login` is the connection test — it exercises every credential field
     * (username, password, organizationId, devKey) and the chosen gateway in one call.
     */
    public override async TestConnection(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<ConnectionTestResult> {
        try {
            const creds = await this.LoadCredentials(companyIntegration, contextUser);
            const auth = await this.Login(creds);
            this.cachedCredentials = creds;
            this.cachedAuth = auth;
            return {
                Success: true,
                Message: `Connected to Bill.com at ${auth.BaseURL}`,
            };
        } catch (error: unknown) {
            const message = error instanceof Error ? error.message : String(error);
            return { Success: false, Message: `Bill.com connection failed: ${message}` };
        }
    }

    // ── Credentials ──────────────────────────────────────────────────

    /**
     * Prefers the linked `MJ: Credentials` row; falls back to `CompanyIntegration.Configuration` so a
     * connection can be stood up before the credential store is populated.
     */
    private async LoadCredentials(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
        provider?: IMetadataProvider
    ): Promise<BillComCredentials> {
        const credentialID = companyIntegration.CredentialID;
        if (credentialID) {
            const fromStore = await this.LoadFromCredentialEntity(credentialID, contextUser, provider);
            if (fromStore) return fromStore;
        }
        const fromConfig = companyIntegration.Configuration
            ? this.ParseCredentialJson(companyIntegration.Configuration)
            : null;
        if (fromConfig) return fromConfig;

        throw new Error(
            'Bill.com credentials not found. Provide username, password, organizationId and devKey ' +
            'via a linked MJ: Credentials record or CompanyIntegration.Configuration.'
        );
    }

    /** Loads a credential row and parses its Values JSON. */
    private async LoadFromCredentialEntity(
        credentialID: string,
        contextUser: UserInfo,
        provider?: IMetadataProvider
    ): Promise<BillComCredentials | null> {
        const md = provider ?? new Metadata();
        const credential = await md.GetEntityObject<MJCredentialEntity>('MJ: Credentials', contextUser);
        const loaded = await credential.Load(credentialID);
        if (!loaded || !credential.Values) return null;
        return this.ParseCredentialJson(credential.Values);
    }

    /**
     * Extracts credentials from a JSON string, accepting both camelCase and PascalCase keys so a
     * hand-authored Configuration blob and a schema-generated credential both resolve.
     */
    private ParseCredentialJson(json: string): BillComCredentials | null {
        try {
            const parsed = JSON.parse(json) as Record<string, unknown>;
            const username = this.FirstString(parsed, ['username', 'Username', 'userName', 'UserName']);
            const password = this.FirstString(parsed, ['password', 'Password']);
            const orgId = this.FirstString(parsed, ['organizationId', 'OrganizationId', 'OrganizationID', 'orgId']);
            const devKey = this.FirstString(parsed, ['devKey', 'DevKey', 'developerKey']);
            if (!username || !password || !orgId || !devKey) return null;
            return {
                Username: username,
                Password: password,
                OrganizationID: orgId,
                DevKey: devKey,
                Environment: this.FirstString(parsed, ['environment', 'Environment']),
                ApiUrl: this.FirstString(parsed, ['apiUrl', 'ApiUrl', 'ApiURL', 'baseUrl', 'BaseURL']),
            };
        } catch {
            return null;
        }
    }

    /** First non-empty string value among the candidate keys. */
    private FirstString(source: Record<string, unknown>, keys: string[]): string | undefined {
        for (const key of keys) {
            const val = source[key];
            if (typeof val === 'string' && val.trim().length > 0) return val.trim();
        }
        return undefined;
    }
}
