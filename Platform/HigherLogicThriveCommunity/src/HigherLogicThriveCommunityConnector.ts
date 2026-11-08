import { RegisterClass } from '@memberjunction/global';
import { Metadata, type IMetadataProvider, type UserInfo } from '@memberjunction/core';
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
    type RESTAuthContext,
    type RESTResponse,
    type PaginationState,
    type PaginationType,
    type ConnectionTestResult,
    type FetchContext,
    type FetchBatchResult,
    type FetchWarning,
    type ExternalRecord,
    type RateLimitPolicy,
    type CreateRecordContext,
    type DeleteRecordContext,
    type CRUDResult,
    type SourceSchemaInfo,
} from '@memberjunction/integration-engine';
import { mergeDeclaredWithSampledFields } from '@memberjunction/connector-schema-merge';

// ─── Design note ────────────────────────────────────────────────────────
//
// Higher Logic Thrive Community — RPC-style JSON-over-HTTP API (ASP.NET Web API 2). The connector is PURE
// MECHANISM: the 35-object / 700+-field catalog is NOT baked here — it lives in the Declared metadata
// (metadata/integrations/higherlogic-thrive/.higherlogic-thrive.integration.json), seeded from the
// credential-free HelpPage catalog (236 operations / 25 controllers). Discovery is INHERITED from
// BaseRESTIntegrationConnector (cache-driven DiscoverObjects / DiscoverFields / IntrospectSchema over the
// persisted Declared rows). No hardcoded object list, no field catalog, no baked PK/FK/required constants.
//
// What this class supplies (the Higher Logic protocol shape over REST):
//  - Auth: two-step login-for-token. POST api/v2.0/Authentication/Login {Username=IAM Key, Password=IAM
//    Password} → an AuthToken {Token}; that token is presented on every subsequent call. Built via the
//    auth flow below — NO inline crypto. A pre-issued token (or the OIDC-API-auth token variant) can be
//    supplied directly on the credential to skip the Login round-trip. SSO (SAML/OIDC/OAuth2-code) is
//    END-USER login, NOT the connector's auth path — never implemented here.
//  - Region: GetBaseURL selects the vendor's fixed regional host from Configuration/credential.region
//    (US → api.connectedcommunity.org / api.higherlogic.com; Canada → api.onlinecommunity.ca). ZERO
//    tenant-specific host baked in — the tenant is identified by the token, not the host.
//  - Routing: RPC verb-in-path. Each IO's APIPath is its specific list operation (no generic collection
//    root). The `api/v2.0/...` prefix = base host `/api` + the metadata APIPath `/v2.0/...`.
//  - Pagination: four real schemes, driven per-IO by Configuration.paginationDetail — (a) seek-key
//    (after<X>Key/before<X>Key + limit), (b) continuation-token (continuationToken + maxRecords; the next
//    token is CLIENT-DERIVED from the last row's key field — the envelope echoes none), (c) marker-direction
//    (Marker + Direction + NumberToReturn, over a POST body), (d) offset (StartRecord/EndRecord, over a POST
//    body); plus the capped/full-set None case. Never a bare one-page fetch.
//  - Incremental: EventRegistrants documents a real server-side `modifiedDateTime` watermark param; where
//    present it is passed and the max-seen watermark is tracked + persisted on full drain. Other objects
//    with a watermark field but no server param re-fetch and rely on content-hash idempotency.
//  - Write: generic per-operation CRUD (metadata-driven) for the write-capable RECORD IOs. CreateRecord is
//    overridden ONLY to substitute parent template vars (`{parent}`, `{blogKey}`, …) into the create path
//    from the record's own attributes — still routed through BuildCreatedResult. RPC ACTION ops
//    (Follow/Recommend/RSVP/Approve) are NOT modeled as generic CRUD.

// ─── Types ────────────────────────────────────────────────────────────

type HLTRegion = 'US' | 'Canada';

/** The five real vendor pagination schemes, derived from the per-IO Configuration.paginationDetail. */
export type PageScheme = 'none' | 'seek-key' | 'continuation-token' | 'marker-direction' | 'offset' | 'query-offset';

/** Metered migration pacing & run-budget controls configured via CompanyIntegration.Configuration.migrationPacing. */
export interface HLTMigrationPacing {
    /** Override token-bucket fill rate (default: 3 req/s). */
    tokensPerSec?: number;
    /** Override token-bucket burst capacity (default: 6). */
    burst?: number;
    /** Override MaxConcurrencyHint (default: 2). */
    maxConcurrency?: number;
    /** Extra deterministic inter-request delay floor in milliseconds (default: 0). */
    minDelayBetweenRequestsMs?: number;
    /** Hard cap on total HTTP requests in a single FetchChanges invocation; pauses with HasMore: true when reached. */
    maxRequestsPerRun?: number;
    /** Hard cap on date windows processed in a single FetchChanges invocation; pauses with HasMore: true when reached. */
    maxWindowsPerRun?: number;
    /** When true, stops after each completed date window to persist NewWatermarkValue + NextCursor immediately. */
    checkpointPerWindow?: boolean;
}

/** Inclusive date window `[From, To]` (`YYYY-MM-DD`). */
export interface HLTDateWindow {
    From: string;
    To: string;
}

/** Configuration for sliding date-window / lookback slicing on legacy capped endpoints. */
export interface HLTDateWindowConfig {
    /** Earliest historical date to backfill from when no watermark exists (default: `'2010-01-01'`). */
    startDate?: string;
    /** Width of each date slice in days (default: `30`). */
    windowDays?: number;
    /** Days to step back from an existing watermark to catch late-arriving revisions (default: `0`). */
    lookbackDays?: number;
    /** Alternate API path to use when date-windowing is active (e.g. `/v2.0/Events/SearchEvents`). */
    windowAPIPath?: string;
    /** HTTP method for the windowed endpoint (default: `'POST'`). */
    windowMethod?: 'GET' | 'POST';
    /** Parameter name for the window start date (default: `'StartDate'`). */
    fromParam?: string;
    /** Parameter name for the window end date (default: `'EndDate'`). */
    toParam?: string;
    /** Maximum records cap parameter name (default: `'MaxRecords'`). */
    capParam?: string;
    /** Maximum records cap value per window request (default: `500`). */
    capLimit?: number;
    /** Adaptive bisection threshold — if a multi-day window returns `>= capThreshold` rows, bisect the window in half. */
    capThreshold?: number;
    /** Optional list of parent scope keys (e.g. `libraryKey` values) to walk sequentially. */
    scopeKeys?: string[];
    /** Parameter name for the parent scope key (e.g. `'libraryKey'`). */
    scopeParamName?: string;
}

/**
 * Composite cursor encoding both outer date-window / parent-scope state and inner pagination position.
 * Wire format: `v1|<Today>|<From>|<To>|<InnerPos>|<ScopeKey>`
 */
export interface HLTWindowCursor extends HLTDateWindow {
    /** Pinned UTC date (`YYYY-MM-DD`) for the entire multi-page run so crossing midnight never shifts windows. */
    Today: string;
    /** Inner page/offset/continuation position within `[From, To]` (`'0'` at window start). */
    InnerPos: string;
    /** Optional parent scope key currently being walked (`''` when unscoped). */
    ScopeKey: string;
}

/** Parsed Higher Logic credential + connection facts. */
interface HLTCredentials {
    /** IAM Key (the Login `Username`). */
    IAMKey?: string;
    /** IAM Password (the Login `Password`). */
    IAMPassword?: string;
    /** Pre-issued auth token (skips the Login round-trip; also the OIDC-API-auth token slot). */
    Token?: string;
    /** Tenant region selecting the fixed regional host. */
    Region?: HLTRegion;
    /** Optional explicit full base-URL override (sandbox / mock) — wins over the regional host. */
    BaseURL?: string;
    /** Override the auth header name (default `Authorization`). The exact wire header is vendor-undocumented. */
    AuthHeaderName?: string;
    /** Override the auth header scheme prefix (default `Bearer`). Empty string → raw token, no prefix. */
    AuthHeaderScheme?: string;
}

/** Extended auth context carrying the resolved token + region + header shape. */
interface HLTAuthContext extends RESTAuthContext {
    Token: string;
    Region: HLTRegion;
    BaseURLOverride?: string;
    AuthHeaderName: string;
    AuthHeaderScheme: string;
}

/** Per-IO pagination descriptor derived from Configuration.paginationDetail. */
interface PaginationDescriptor {
    Scheme: PageScheme;
    /** Query/body param names the operation accepts for paging. */
    Params: string[];
    /** POST when the read operation uses a JSON request body (offset / marker-direction / declared POST). */
    ReadMethod: 'GET' | 'POST';
}

// ─── Constants & Window Arithmetic ────────────────────────────────────

/** Fixed regional hosts (vendor-documented, tenant-AGNOSTIC — the tenant is identified by the token). */
const REGIONAL_HOSTS: Record<HLTRegion, string> = {
    US: 'https://api.connectedcommunity.org',
    Canada: 'https://api.onlinecommunity.ca',
};
/** US mirror host (selected when Configuration.useMirrorHost is true). */
const US_MIRROR_HOST = 'https://api.higherlogic.com';
/** Login operation (relative to base host + `/api`). */
const LOGIN_PATH = '/v2.0/Authentication/Login';
/** Conservative page sizes per scheme (the vendor documents no hard limits; these are safe defaults). */
const DEFAULT_SEEK_LIMIT = 100;
const DEFAULT_CONTINUATION_MAX = 100;
const DEFAULT_MARKER_COUNT = 25; // DataFeed NumberToReturn caps at 25
const DEFAULT_OFFSET_WINDOW = 50; // CommunityMembers StartRecord/EndRecord & Messaging firstRecord/maxRecords default window
const DEFAULT_COLD_START_DATE = '2010-01-01';
const DEFAULT_WINDOW_DAYS = 30;
const MS_PER_DAY = 86_400_000;
const ISO_DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

/** Opt-in private/social objects gated by `CompanyIntegration.Configuration.includePrivateSocialObjects`. */
export const PRIVATE_SOCIAL_OBJECTS: ReadonlySet<string> = new Set([
    'InboxMessages',
    'SentMessages',
    'Friends',
    'FriendRequests',
]);

/** Returns the UTC date string (`YYYY-MM-DD`) for a Date instance. */
export function toISODate(d: Date): string {
    return d.toISOString().slice(0, 10);
}

/** Shifts an ISO `YYYY-MM-DD` date by whole days. */
export function addDays(iso: string, days: number): string {
    const base = Date.parse(`${iso.slice(0, 10)}T00:00:00Z`);
    if (Number.isNaN(base)) return iso;
    return new Date(base + days * MS_PER_DAY).toISOString().slice(0, 10);
}

/** Whole-day difference between two ISO dates (`to - from`), minimum 1. */
export function daysBetween(fromIso: string, toIso: string): number {
    const a = Date.parse(`${fromIso.slice(0, 10)}T00:00:00Z`);
    const b = Date.parse(`${toIso.slice(0, 10)}T00:00:00Z`);
    if (Number.isNaN(a) || Number.isNaN(b)) return DEFAULT_WINDOW_DAYS;
    return Math.max(1, Math.ceil((b - a) / MS_PER_DAY));
}

const minDate = (a: string, b: string): string => (a < b ? a : b);
const maxDate = (a: string, b: string): string => (a > b ? a : b);

/** Computes the first date window `[From, To]` of a run from the watermark or configured `startDate`. */
export function initialDateWindow(cfg: HLTDateWindowConfig, watermark: string | null | undefined, today: string): HLTDateWindow {
    const startFloor = cfg.startDate && ISO_DATE_RE.test(cfg.startDate.slice(0, 10))
        ? cfg.startDate.slice(0, 10)
        : DEFAULT_COLD_START_DATE;
    const lookback = Math.max(0, cfg.lookbackDays ?? 0);
    const windowDays = Math.max(1, cfg.windowDays ?? DEFAULT_WINDOW_DAYS);

    let from = watermark && ISO_DATE_RE.test(watermark.slice(0, 10))
        ? addDays(watermark.slice(0, 10), -lookback)
        : startFloor;
    if (cfg.startDate && ISO_DATE_RE.test(cfg.startDate.slice(0, 10))) {
        from = maxDate(from, cfg.startDate.slice(0, 10));
    }
    from = minDate(from, today);
    const to = minDate(addDays(from, windowDays - 1), today);
    return { From: from, To: to };
}

/** Computes the next date window after `current`, or `null` once `current.To >= today`. */
export function nextDateWindow(current: HLTDateWindow, cfg: HLTDateWindowConfig, today: string): HLTDateWindow | null {
    if (current.To >= today) return null;
    const windowDays = Math.max(1, cfg.windowDays ?? DEFAULT_WINDOW_DAYS);
    const from = addDays(current.To, 1);
    const to = minDate(addDays(from, windowDays - 1), today);
    return { From: from, To: to };
}

/**
 * Adaptive window bisection: when a multi-day window `[From, To]` hits a server cap, splits it in half
 * `[From, Mid]` so the caller can re-query a narrower slice (down to 1-day granularity) without silent truncation.
 * Returns `null` when `From === To` (already a single day).
 */
export function bisectDateWindow(current: HLTDateWindow): HLTDateWindow | null {
    if (current.From >= current.To) return null;
    const span = daysBetween(current.From, current.To);
    const half = Math.max(0, Math.floor(span / 2) - 1);
    const mid = addDays(current.From, half);
    if (mid >= current.To) return { From: current.From, To: current.From };
    return { From: current.From, To: mid };
}

/** Formats a composite `HLTWindowCursor` into its wire representation `v1|<Today>|<From>|<To>|<InnerPos>|<ScopeKey>`. */
export function formatWindowCursor(c: HLTWindowCursor): string {
    return ['v1', c.Today, c.From, c.To, c.InnerPos || '0', c.ScopeKey || ''].join('|');
}

/** Parses a composite `v1|...` window cursor, returning `null` if absent or not a v1 window cursor. */
export function parseWindowCursor(raw: string | null | undefined): HLTWindowCursor | null {
    if (!raw || !raw.startsWith('v1|')) return null;
    const parts = raw.split('|');
    if (parts.length < 6) return null;
    const [, today, from, to, innerPos, ...scopeRest] = parts;
    if (!ISO_DATE_RE.test(today) || !ISO_DATE_RE.test(from) || !ISO_DATE_RE.test(to)) return null;
    if (from > to) return null;
    return {
        Today: today,
        From: from,
        To: to,
        InnerPos: innerPos || '0',
        ScopeKey: scopeRest.join('|'),
    };
}

// ─── HigherLogicThriveCommunityConnector ─────────────────────────────────

/**
 * Higher Logic Thrive Community connector — extends BaseRESTIntegrationConnector (REST/JSON RPC over HTTP).
 *
 * Discovery + generic per-operation CRUD are inherited; this class supplies the Higher Logic protocol
 * surface: two-step token auth, region-selected base URL, the five real pagination schemes (over GET and
 * POST, including GET query-offset `firstRecord`/`maxRecords` for Messaging), opt-in private/social object
 * gating (`InboxMessages`, `SentMessages`, `Friends`, `FriendRequests`), metered migration pacing, sliding
 * date-window / lookback slicing for legacy capped endpoints, connection testing, and the §7/§10
 * sync-efficiency hooks the frozen contract evidences.
 */
// Catalog convention: registration key == npm package name (what instance
// discovery reports and the catalog resolves installed state by).
@RegisterClass(BaseIntegrationConnector, '@memberjunction/connector-higher-logic-thrive-community')
export class HigherLogicThriveCommunityConnector extends BaseRESTIntegrationConnector {

    /** Cached auth for the lifetime of a single sync run (the token is presented on every call). */
    private cachedAuth: HLTAuthContext | null = null;
    /** Active migration pacing overrides parsed from the most recent CompanyIntegration configuration. */
    private activePacing: HLTMigrationPacing | null = null;

    // ── Identity (T1 three-way invariant) ────────────────────────────

    /** Verbatim `MJ: Integrations.Name`. Load-bearing: the T1 three-way name check compares this === metadata Name. */
    public override get IntegrationName(): string {
        return 'higherlogic-thrive';
    }

    // ── Capability getters (kept in lockstep with the per-op metadata columns) ──

    public override get SupportsCreate(): boolean { return true; }
    public override get SupportsUpdate(): boolean { return true; }
    public override get SupportsDelete(): boolean { return true; }

    /**
     * Discovery is NON-authoritative. There is NO complete-gamut describe endpoint in the 236-operation
     * catalog; per-tenant custom Demographics + AutomationRules fieldLists flow through runtime discovery +
     * the framework's custom-column capture. Absence in a refresh proves nothing → never deactivate. Matches
     * Configuration.DiscoveryIsAuthoritative=false in the frozen contract.
     */
    public override get DiscoveryIsAuthoritative(): boolean {
        return false;
    }

    // ── Sync-efficiency hooks (§7/§10 — from frozen-contract Configuration facts) ──

    /**
     * From Configuration.RateLimitGuidance: ~180–240 calls/minute (~3–4 req/s) acceptable-use guidance;
     * NO hard server-enforced numeric limit is documented (excessive usage risks IP blocking, not a
     * deterministic 429). Honors `CompanyIntegration.Configuration.migrationPacing` when configured so
     * multi-day historical migrations can dial the token bucket down (e.g., 1 req/s, burst 2).
     */
    public override get RateLimitPolicy(): RateLimitPolicy | null {
        const tokensPerSec = this.activePacing?.tokensPerSec;
        const burst = this.activePacing?.burst;
        return {
            TokensPerSec: typeof tokensPerSec === 'number' && tokensPerSec > 0 ? tokensPerSec : 3,
            Burst: typeof burst === 'number' && burst > 0 ? burst : 6,
        };
    }

    /** Conservative in-flight cap — honors `migrationPacing.maxConcurrency` when set (default: 2). */
    public override get MaxConcurrencyHint(): number | null {
        const mc = this.activePacing?.maxConcurrency;
        return typeof mc === 'number' && mc > 0 ? mc : 2;
    }

    /**
     * No-watermark objects resume by their StableOrderingKey — read from the IO metadata (the extractor
     * emits it, typically the `<Object>Key` PK). Returns null when the object declares no stable key or the
     * cache is unavailable (unit-test context).
     */
    public override StableOrderingKey(objectName: string): string | null {
        const obj = this.tryGetCachedObject(objectName);
        if (!obj) return null;
        const declared = (obj as unknown as { StableOrderingKey?: string | null }).StableOrderingKey;
        if (declared && declared.trim().length > 0) return declared.trim();
        const pk = this.GetCachedFields(obj.ID).find(f => f.IsPrimaryKey);
        return pk?.Name ?? null;
    }

    /**
     * Sample-union enrichment (MJ connector standard): the Declared metadata is HelpPage-derived and misses
     * a tenant's custom demographic / automation-rule fields. After cache-driven introspection, sample each
     * object's live read shape and UNION it into the declared field set — never-shrink, declared-wins.
     * Override IntrospectSchema (NOT DiscoverFields — that recurses into DiscoverFieldsViaFetch's fallback).
     */
    public override async IntrospectSchema(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<SourceSchemaInfo> {
        const info = await super.IntrospectSchema(companyIntegration, contextUser);
        await Promise.all(
            info.Objects.map(async (obj) => {
                try {
                    const sampled = await this.DiscoverFieldsViaFetch(companyIntegration, obj.ExternalName, contextUser);
                    obj.Fields = mergeDeclaredWithSampledFields(obj.Fields, sampled);
                } catch {
                    /* best-effort — a sample failure leaves the declared fields as-is */
                }
            }),
        );
        return info;
    }

    // ── Abstract REST hooks ──────────────────────────────────────────

    /**
     * Two-step login-for-token. When the credential carries a pre-issued Token (or the OIDC-API-auth token
     * slot) it is used directly; otherwise POST the Login operation with the IAM Key + IAM Password and read
     * the returned AuthToken.Token. Cached for the run. No inline crypto — the "signing" is the vendor's
     * own token exchange over the transport hook.
     */
    protected override async Authenticate(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<RESTAuthContext> {
        this.activePacing = this.readMigrationPacing(companyIntegration);
        if (this.cachedAuth) return this.cachedAuth;
        const creds = await this.loadCredentials(companyIntegration, contextUser);
        const region = this.resolveRegion(companyIntegration, creds);
        const baseURLOverride = this.resolveBaseURLOverride(companyIntegration, creds);
        const authHeaderName = creds.AuthHeaderName?.trim() || 'Authorization';
        const authHeaderScheme = creds.AuthHeaderScheme != null ? creds.AuthHeaderScheme.trim() : 'Bearer';

        let token = creds.Token?.trim();
        if (!token) {
            token = await this.loginForToken(creds, region, baseURLOverride);
        }
        this.cachedAuth = {
            Token: token,
            Region: region,
            BaseURLOverride: baseURLOverride ?? undefined,
            AuthHeaderName: authHeaderName,
            AuthHeaderScheme: authHeaderScheme,
        };
        return this.cachedAuth;
    }

    /**
     * Presents the Login-issued token on every request. The EXACT header scheme is vendor-undocumented
     * (see Configuration.AuthHeaderPatternNote) — defaults to `Authorization: Bearer <token>` and is fully
     * overridable by data (AuthHeaderName / AuthHeaderScheme on the credential) so a live-verified scheme
     * can be applied without a code change. RequiresLiveVerification.
     */
    protected override BuildHeaders(auth: RESTAuthContext): Record<string, string> {
        const ctx = auth as HLTAuthContext;
        const value = ctx.AuthHeaderScheme.length > 0 ? `${ctx.AuthHeaderScheme} ${ctx.Token}` : ctx.Token;
        return {
            [ctx.AuthHeaderName]: value,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        };
    }

    /** HTTP transport (fetch). Owns the wire boundary; test subclasses override this to capture requests. */
    protected override async MakeHTTPRequest(
        _auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown
    ): Promise<RESTResponse> {
        const response = await fetch(url, {
            method,
            headers,
            body: body !== undefined ? JSON.stringify(body) : undefined,
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

    /** Injectable delay seam for metered migration pacing (`minDelayBetweenRequestsMs`). Overridden in unit tests. */
    protected async Sleep(ms: number): Promise<void> {
        if (ms <= 0) return;
        await new Promise<void>(resolve => setTimeout(resolve, ms));
    }

    /**
     * Strips the HelpPage response envelope to the per-object record array. The Community API returns three
     * shapes: a BARE array (e.g. EventRegistrantConcise[]), a `{ RecordCount, <Plural>Data: [...] }` page
     * wrapper (e.g. DiscussionPostPage), or a `{ <Plural>: [...], HasMore…, Next, Previous }` seek envelope.
     * When ResponseDataKey is set it wins; otherwise the array property is auto-detected (the sole/first
     * array-valued property), falling back to a single record wrapped as `[record]`.
     */
    protected override NormalizeResponse(rawBody: unknown, responseDataKey: string | null): Record<string, unknown>[] {
        if (rawBody == null) return [];
        if (Array.isArray(rawBody)) return rawBody as Record<string, unknown>[];
        if (typeof rawBody !== 'object') return [];
        const body = rawBody as Record<string, unknown>;
        if (responseDataKey) {
            const arr = body[responseDataKey];
            if (Array.isArray(arr)) return arr as Record<string, unknown>[];
            const one = body[responseDataKey];
            if (one && typeof one === 'object' && !Array.isArray(one)) return [one as Record<string, unknown>];
        }
        // Auto-detect: the first array-valued property is the record collection (…Data / <Plural>).
        for (const v of Object.values(body)) {
            if (Array.isArray(v)) return v as Record<string, unknown>[];
        }
        // No array property → treat the object itself as a single record (get-one shape).
        return [body];
    }

    /**
     * Envelope-based pagination signal. Higher Logic seek-key responses MAY carry a `HasMore…` boolean and
     * a `Next` cursor; page wrappers carry `RecordCount`. This reads those when present. The primary
     * next-cursor for continuation-token / seek-key / marker schemes is CLIENT-DERIVED from the last record
     * (the envelope echoes no token) — computed in the FetchChanges loop, which OR-combines this envelope
     * signal with a record-count heuristic. currentPage/offset are used for the Offset window.
     */
    protected override ExtractPaginationInfo(
        rawBody: unknown,
        paginationType: PaginationType,
        _currentPage: number,
        currentOffset: number,
        pageSize: number
    ): PaginationState {
        if (!rawBody || typeof rawBody !== 'object') return { HasMore: false };
        const body = rawBody as Record<string, unknown>;
        const total = this.readNumber(body, ['RecordCount', 'TotalRecords', 'TotalCount', 'Count']);

        if (paginationType === 'Offset') {
            const seen = currentOffset + pageSize;
            const hasMore = total != null ? seen < total : false;
            return { HasMore: hasMore, NextOffset: seen, TotalRecords: total ?? undefined };
        }
        if (paginationType === 'Cursor') {
            const nextCursor = this.readString(body, ['Next', 'NextContinuationToken', 'continuationToken', 'ContinuationToken']);
            const hasMoreFlag = this.readBooleanStartsWith(body, 'HasMore');
            if (nextCursor) return { HasMore: true, NextCursor: nextCursor, TotalRecords: total ?? undefined };
            if (hasMoreFlag === true) return { HasMore: true, TotalRecords: total ?? undefined };
            if (hasMoreFlag === false) return { HasMore: false, TotalRecords: total ?? undefined };
            return { HasMore: false, TotalRecords: total ?? undefined };
        }
        return { HasMore: false, TotalRecords: total ?? undefined };
    }

    /**
     * Region-selected base host + `/api` (the `api/v2.0/...` operation prefix = this base + the metadata
     * APIPath `/v2.0/...`). An explicit Configuration/credential BaseURL override (sandbox / mock) wins so
     * the connector can be redirected by data alone. NO tenant-specific host is ever baked in.
     */
    protected override GetBaseURL(companyIntegration: MJCompanyIntegrationEntity, auth: RESTAuthContext): string {
        const ctx = auth as HLTAuthContext;
        if (ctx.BaseURLOverride) return `${ctx.BaseURLOverride.replace(/\/+$/, '')}`;
        const host = ctx.Region === 'US' && this.readConfigFlag(companyIntegration, 'useMirrorHost')
            ? US_MIRROR_HOST
            : REGIONAL_HOSTS[ctx.Region];
        return `${host}/api`;
    }

    // ── FetchChanges override — five pagination schemes + opt-in gating + metered pacing + sliding date windows ──

    /**
     * OVERRIDDEN: the Community API is genuinely idiosyncratic for reads — five distinct pagination schemes
     * (`seek-key`, `continuation-token`, `marker-direction`, `offset` over POST `StartRecord`/`EndRecord`, and
     * `query-offset` over GET `firstRecord`/`maxRecords`), opt-in private/social object gating (`InboxMessages`,
     * `SentMessages`, `Friends`, `FriendRequests`), metered migration pacing (`minDelayBetweenRequestsMs`,
     * `maxRequestsPerRun`, `maxWindowsPerRun`), and sliding date-window / lookback slicing (`v1|...` cursor)
     * for legacy capped endpoints (`Events/SearchEvents`, `CommunityMembers` delta updates, and
     * `ResourceLibraryDocuments` lookback + library walk).
     */
    public override async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
        const obj = this.GetCachedObject(ctx.CompanyIntegration.IntegrationID, ctx.ObjectName);

        // 1. Opt-in private/social object gate (InboxMessages, SentMessages, Friends, FriendRequests).
        if (this.isPrivateSocialOptInObject(obj) && !this.isPrivateSocialEnabled(ctx.CompanyIntegration, obj.Name)) {
            return {
                Records: [],
                HasMore: false,
                Warnings: [{
                    Code: 'OPT_IN_DISABLED',
                    Message: `"${obj.Name}" is an opt-in private/social object. Set "includePrivateSocialObjects": true in CompanyIntegration.Configuration to include it in sync/migration.`,
                    Data: { object: obj.Name, optInKey: 'includePrivateSocialObjects' },
                }],
            };
        }

        const fields = this.GetCachedFields(obj.ID);
        const pacing = this.readMigrationPacing(ctx.CompanyIntegration);
        this.activePacing = pacing;
        const auth = await this.Authenticate(ctx.CompanyIntegration, ctx.ContextUser) as HLTAuthContext;
        const baseURL = this.GetBaseURL(ctx.CompanyIntegration, auth);
        const headers = this.BuildHeaders(auth);
        const desc = this.describePagination(obj);
        const pkFieldNames = this.pkFieldNames(fields);
        const scopeParams = this.readObjectScopeParams(ctx.CompanyIntegration, obj.Name);
        const wmField = obj.SupportsIncrementalSync ? (obj.IncrementalWatermarkField ?? null) : null;

        // 2. Sliding date-window / parent-scope state machine when configured or resuming a `v1|...` cursor.
        const windowCfg = this.resolveDateWindowConfig(ctx.CompanyIntegration, obj, scopeParams);
        if (windowCfg || (ctx.CurrentCursor && ctx.CurrentCursor.startsWith('v1|'))) {
            return this.fetchDateWindowedChanges(
                ctx, obj, fields, auth, baseURL, headers, desc, pkFieldNames, scopeParams, wmField, pacing,
                windowCfg ?? {}
            );
        }

        const batchLimit = ctx.BatchSize && ctx.BatchSize > 0 ? ctx.BatchSize : Number.MAX_SAFE_INTEGER;
        const pageSize = this.pageSizeForScheme(desc.Scheme);
        const minDelayMs = pacing?.minDelayBetweenRequestsMs ?? 0;
        const maxRequests = pacing?.maxRequestsPerRun && pacing.maxRequestsPerRun > 0
            ? pacing.maxRequestsPerRun
            : Number.MAX_SAFE_INTEGER;

        const out: ExternalRecord[] = [];
        const warnings: FetchWarning[] = [];
        let cursor = ctx.CurrentCursor;
        let offset = ctx.CurrentOffset ?? 0;
        let hasMore = true;
        let maxWatermark: string | null = null;
        let fullyDrained = true;
        let requestsMade = 0;

        while (hasMore && out.length < batchLimit) {
            if (requestsMade >= maxRequests) {
                fullyDrained = false;
                break;
            }
            if (requestsMade > 0 && minDelayMs > 0) {
                await this.Sleep(minDelayMs);
            }
            const remaining = Math.max(1, batchLimit - out.length);
            const req = this.buildReadRequest(obj, baseURL, desc, cursor, offset, Math.min(pageSize, remaining), scopeParams, ctx, wmField);
            const response = await this.MakeHTTPRequest(auth, req.URL, req.Method, headers, req.Body);
            requestsMade++;
            if (response.Status === 403) {
                warnings.push({ Code: 'FORBIDDEN', Message: `"${obj.Name}": HTTP 403 — insufficient API entitlement; skipping.`, Data: { object: obj.Name } });
                hasMore = false;
                break;
            }
            this.assert2xx(response, req.URL, obj.Name);
            const raw = this.NormalizeResponse(response.Body, obj.ResponseDataKey);

            // Optional dual-door merge for FriendRequests (GetFriendRequestsReceived + GetFriendRequestsSent).
            const objCfg = this.parseObjectConfig(obj);
            const secondaryPath = typeof objCfg?.secondaryAPIPath === 'string' ? objCfg.secondaryAPIPath : null;
            if (secondaryPath && scopeParams.includeSent !== 'false' && requestsMade < maxRequests) {
                for (const r of raw) {
                    if (r.Direction == null) r.Direction = 'Received';
                }
                if (minDelayMs > 0) await this.Sleep(minDelayMs);
                const secUrl = this.appendQuery(this.joinURL(baseURL, secondaryPath), scopeParams);
                const secResp = await this.MakeHTTPRequest(auth, secUrl, 'GET', headers);
                requestsMade++;
                if (secResp.Status >= 200 && secResp.Status < 300) {
                    const secRaw = this.NormalizeResponse(secResp.Body, obj.ResponseDataKey);
                    for (const sr of secRaw) {
                        if (sr.Direction == null) sr.Direction = 'Sent';
                        raw.push(sr);
                    }
                }
            }

            if (raw.length === 0) { hasMore = false; break; }

            for (const r of raw) {
                out.push(this.buildExternalRecord(this.applyTransformPreservingKeys(r, obj, fields), obj.Name, pkFieldNames));
                maxWatermark = this.trackWatermark(maxWatermark, r, wmField);
            }

            const next = this.computeNextPage(desc, response.Body, raw, obj, pkFieldNames, offset, pageSize);
            // Break on a non-advancing cursor (broken/exhausted paging) to avoid an infinite loop.
            const isOffsetScheme = desc.Scheme === 'offset' || desc.Scheme === 'query-offset';
            if (next.HasMore && !isOffsetScheme && next.NextCursor != null && next.NextCursor === cursor) {
                hasMore = false;
                break;
            }
            hasMore = next.HasMore;
            cursor = next.NextCursor ?? cursor;
            offset = next.NextOffset ?? offset;
            if (hasMore && out.length >= batchLimit) { fullyDrained = false; }
        }

        const isOffsetScheme = desc.Scheme === 'offset' || desc.Scheme === 'query-offset';
        const result: FetchBatchResult = {
            Records: out,
            HasMore: hasMore,
            NextCursor: cursor,
            NextOffset: isOffsetScheme ? offset : undefined,
            Warnings: warnings.length > 0 ? warnings : undefined,
        };
        // Advance the watermark ONLY on full drain (partial batch resumes from the same point next call).
        if (!hasMore && fullyDrained && wmField && maxWatermark) {
            result.NewWatermarkValue = this.laterWatermark(ctx.WatermarkValue, maxWatermark);
        }
        return result;
    }

    // ── Sliding Date-Window & Parent-Scope Execution ─────────────────

    /**
     * Executes a stateful sliding date-window / parent-scope harvest using the `v1|<Today>|<From>|<To>|<InnerPos>|<ScopeKey>`
     * cursor. Supports adaptive window bisection when a multi-day slice hits `capThreshold`, plus metered
     * `maxRequestsPerRun`, `maxWindowsPerRun`, and `checkpointPerWindow` controls.
     */
    private async fetchDateWindowedChanges(
        ctx: FetchContext,
        obj: MJIntegrationObjectEntity,
        fields: MJIntegrationObjectFieldEntity[],
        auth: HLTAuthContext,
        baseURL: string,
        headers: Record<string, string>,
        desc: PaginationDescriptor,
        pkFieldNames: string[],
        scopeParams: Record<string, string>,
        wmField: string | null,
        pacing: HLTMigrationPacing | null,
        windowCfg: HLTDateWindowConfig
    ): Promise<FetchBatchResult> {
        const batchLimit = ctx.BatchSize && ctx.BatchSize > 0 ? ctx.BatchSize : Number.MAX_SAFE_INTEGER;
        const minDelayMs = pacing?.minDelayBetweenRequestsMs ?? 0;
        const maxRequests = pacing?.maxRequestsPerRun && pacing.maxRequestsPerRun > 0
            ? pacing.maxRequestsPerRun
            : Number.MAX_SAFE_INTEGER;
        const maxWindows = pacing?.maxWindowsPerRun && pacing.maxWindowsPerRun > 0
            ? pacing.maxWindowsPerRun
            : Number.MAX_SAFE_INTEGER;
        const checkpointPerWindow = pacing?.checkpointPerWindow === true;

        const scopeKeys = windowCfg.scopeKeys && windowCfg.scopeKeys.length > 0 ? windowCfg.scopeKeys : [''];
        const scopeParamName = windowCfg.scopeParamName ?? 'libraryKey';
        const parsedCursor = parseWindowCursor(ctx.CurrentCursor);
        const today = parsedCursor?.Today ?? toISODate(new Date());
        let currentScopeIdx = parsedCursor?.ScopeKey ? Math.max(0, scopeKeys.indexOf(parsedCursor.ScopeKey)) : 0;
        let currentScopeKey = scopeKeys[currentScopeIdx] ?? '';
        let window: HLTDateWindow = parsedCursor
            ? { From: parsedCursor.From, To: parsedCursor.To }
            : initialDateWindow(windowCfg, ctx.WatermarkValue, today);
        let innerPos = parsedCursor?.InnerPos ?? '0';

        const out: ExternalRecord[] = [];
        const warnings: FetchWarning[] = [];
        let requestsMade = 0;
        let windowsCompleted = 0;
        let lastCompletedWindowTo: string | null = null;
        let maxWatermark: string | null = null;
        let hasMore = true;

        const capLimit = windowCfg.capLimit ?? 500;
        const capThreshold = windowCfg.capThreshold ?? capLimit;
        const fromParam = windowCfg.fromParam ?? 'StartDate';
        const toParam = windowCfg.toParam ?? 'EndDate';
        const capParam = windowCfg.capParam ?? 'MaxRecords';
        const targetPath = windowCfg.windowAPIPath ?? obj.APIPath;
        const method = windowCfg.windowMethod ?? desc.ReadMethod;

        while (hasMore && out.length < batchLimit) {
            if (requestsMade >= maxRequests || windowsCompleted >= maxWindows) {
                break;
            }
            if (requestsMade > 0 && minDelayMs > 0) {
                await this.Sleep(minDelayMs);
            }

            const effectiveScope: Record<string, string> = { ...scopeParams };
            if (currentScopeKey.length > 0) {
                effectiveScope[scopeParamName] = currentScopeKey;
            }

            const req = this.buildWindowedReadRequest(
                baseURL, targetPath, method, desc, window, innerPos, capLimit, fromParam, toParam, capParam, effectiveScope, obj
            );
            const response = await this.MakeHTTPRequest(auth, req.URL, req.Method, headers, req.Body);
            requestsMade++;

            if (response.Status === 403) {
                warnings.push({ Code: 'FORBIDDEN', Message: `"${obj.Name}": HTTP 403 — insufficient API entitlement; skipping.`, Data: { object: obj.Name } });
                hasMore = false;
                break;
            }
            this.assert2xx(response, req.URL, obj.Name);
            const raw = this.NormalizeResponse(response.Body, obj.ResponseDataKey);

            // Adaptive window bisection: if a single-page capped endpoint returns >= capThreshold rows across a
            // multi-day window, bisect the window into a narrower date range and re-query before emitting rows.
            if (desc.Scheme === 'none' && raw.length >= capThreshold) {
                const bisected = bisectDateWindow(window);
                if (bisected) {
                    warnings.push({
                        Code: 'WINDOW_BISECTED',
                        Message: `"${obj.Name}": window [${window.From}, ${window.To}] returned ${raw.length} rows (>= cap ${capThreshold}); bisecting to [${bisected.From}, ${bisected.To}].`,
                        Data: { object: obj.Name, originalFrom: window.From, originalTo: window.To, bisectedTo: bisected.To },
                    });
                    window = bisected;
                    innerPos = '0';
                    continue;
                } else {
                    warnings.push({
                        Code: 'WINDOW_CAP_REACHED',
                        Message: `"${obj.Name}": single-day window [${window.From}, ${window.To}] returned ${raw.length} rows (at cap ${capThreshold}).`,
                        Data: { object: obj.Name, date: window.From, count: raw.length },
                    });
                }
            }

            for (const r of raw) {
                out.push(this.buildExternalRecord(this.applyTransformPreservingKeys(r, obj, fields), obj.Name, pkFieldNames));
                maxWatermark = this.trackWatermark(maxWatermark, r, wmField);
            }

            // Check inner pagination within the current window (when the windowed endpoint also pages).
            const innerOffset = Number.isInteger(Number(innerPos)) ? Number(innerPos) : 0;
            const pageSize = this.pageSizeForScheme(desc.Scheme);
            const nextInner = desc.Scheme === 'none'
                ? { HasMore: false }
                : this.computeNextPage(desc, response.Body, raw, obj, pkFieldNames, innerOffset, pageSize);

            if (nextInner.HasMore) {
                const nextPos = (desc.Scheme === 'offset' || desc.Scheme === 'query-offset')
                    ? String(nextInner.NextOffset ?? (innerOffset + raw.length))
                    : String(nextInner.NextCursor ?? innerPos);
                if (nextPos !== innerPos) {
                    innerPos = nextPos;
                    continue;
                }
            }

            // Current window is fully drained! Advance to the next window (or next parent scope key).
            lastCompletedWindowTo = window.To;
            windowsCompleted++;
            innerPos = '0';

            const nextWin = nextDateWindow(window, windowCfg, today);
            if (nextWin) {
                window = nextWin;
                if (checkpointPerWindow) {
                    break;
                }
            } else if (currentScopeIdx + 1 < scopeKeys.length) {
                currentScopeIdx++;
                currentScopeKey = scopeKeys[currentScopeIdx];
                window = initialDateWindow(windowCfg, ctx.WatermarkValue, today);
                if (checkpointPerWindow) {
                    break;
                }
            } else {
                hasMore = false;
                break;
            }
        }

        const nextCursor = hasMore
            ? formatWindowCursor({ Today: today, From: window.From, To: window.To, InnerPos: innerPos, ScopeKey: currentScopeKey })
            : undefined;

        const result: FetchBatchResult = {
            Records: out,
            HasMore: hasMore,
            NextCursor: nextCursor,
            Warnings: warnings.length > 0 ? warnings : undefined,
        };

        // Advance watermark on full drain OR on a completed window boundary when checkpointing.
        const candidateWatermark = maxWatermark ?? lastCompletedWindowTo;
        if (candidateWatermark && (!hasMore || lastCompletedWindowTo != null)) {
            result.NewWatermarkValue = this.laterWatermark(ctx.WatermarkValue, candidateWatermark);
        }
        return result;
    }

    /** Builds the HTTP request for a single date-windowed slice. */
    private buildWindowedReadRequest(
        baseURL: string,
        apiPath: string,
        method: 'GET' | 'POST',
        desc: PaginationDescriptor,
        window: HLTDateWindow,
        innerPos: string,
        capLimit: number,
        fromParam: string,
        toParam: string,
        capParam: string,
        scopeParams: Record<string, string>,
        obj: MJIntegrationObjectEntity
    ): { URL: string; Method: 'GET' | 'POST'; Body?: unknown } {
        const path = this.joinURL(baseURL, apiPath);
        const offset = Number.isInteger(Number(innerPos)) ? Number(innerPos) : 0;
        const pageSize = this.pageSizeForScheme(desc.Scheme);

        // Special handling for ResourceLibraryDocuments (`DaysBack` integer lookback param).
        const usesDaysBack = /^DaysBack$/i.test(fromParam) || obj.Name === 'ResourceLibraryDocuments';

        if (method === 'POST') {
            const body: Record<string, unknown> = { ...scopeParams };
            if (usesDaysBack) {
                body.DaysBack = daysBetween(window.From, window.To);
                body[capParam] = capLimit;
            } else {
                body[fromParam] = window.From;
                body[toParam] = window.To;
                if (capParam) body[capParam] = capLimit;
            }
            if (desc.Scheme === 'offset') {
                body.StartRecord = offset + 1;
                body.EndRecord = offset + pageSize;
            } else if (desc.Scheme === 'marker-direction') {
                if (innerPos && innerPos !== '0') body.Marker = innerPos;
                body.Direction = 'down';
                body.NumberToReturn = pageSize;
            }
            return { URL: path, Method: 'POST', Body: body };
        }

        const query: Record<string, string> = {
            ...scopeParams,
            [fromParam]: window.From,
            [toParam]: window.To,
        };
        if (capParam) query[capParam] = String(capLimit);
        if (desc.Scheme === 'query-offset') {
            query.firstRecord = String(offset);
            query.maxRecords = String(pageSize);
        } else if (desc.Scheme === 'seek-key') {
            const afterParam = desc.Params.find(p => /^after.+Key$/i.test(p));
            if (afterParam && innerPos && innerPos !== '0') query[afterParam] = innerPos;
            query.limit = String(pageSize);
        } else if (desc.Scheme === 'continuation-token') {
            if (innerPos && innerPos !== '0') query.continuationToken = innerPos;
            query.maxRecords = String(pageSize);
        }
        return { URL: this.appendQuery(path, query), Method: 'GET' };
    }

    // ── Pagination internals ─────────────────────────────────────────

    /** Derives the per-IO pagination scheme + params + read verb from Configuration.paginationDetail/accessPath. */
    private describePagination(obj: MJIntegrationObjectEntity): PaginationDescriptor {
        const cfg = this.parseObjectConfig(obj);
        const detail = (cfg?.paginationDetail ?? null) as { params?: unknown } | null;
        const params = Array.isArray(detail?.params) ? (detail!.params as unknown[]).filter((p): p is string => typeof p === 'string') : [];
        const declaredReadMethod = this.readNestedString(cfg, ['accessPath', 'readMethod']);

        let scheme: PageScheme = 'none';
        if (obj.SupportsPagination && obj.PaginationType !== 'None') {
            if (params.some(p => /^StartRecord$/i.test(p)) && params.some(p => /^EndRecord$/i.test(p))) scheme = 'offset';
            else if (params.some(p => /^firstRecord$/i.test(p)) && params.some(p => /^maxRecords$/i.test(p))) scheme = 'query-offset';
            else if (params.some(p => /^Marker$/i.test(p)) && params.some(p => /^Direction$/i.test(p))) scheme = 'marker-direction';
            else if (params.some(p => /^continuationToken$/i.test(p))) scheme = 'continuation-token';
            else if (params.some(p => /^after.+Key$/i.test(p))) scheme = 'seek-key';
            else scheme = 'none';
        }
        const readMethod: 'GET' | 'POST' =
            declaredReadMethod?.toUpperCase() === 'POST' || scheme === 'offset' || scheme === 'marker-direction'
                ? 'POST'
                : 'GET';
        return { Scheme: scheme, Params: params, ReadMethod: readMethod };
    }

    /** Builds one paginated read request (URL + method + optional POST body) for the current page. */
    private buildReadRequest(
        obj: MJIntegrationObjectEntity,
        baseURL: string,
        desc: PaginationDescriptor,
        cursor: string | undefined,
        offset: number,
        pageSize: number,
        scopeParams: Record<string, string>,
        ctx: FetchContext,
        wmField: string | null
    ): { URL: string; Method: 'GET' | 'POST'; Body?: unknown } {
        const path = this.joinURL(baseURL, obj.APIPath);
        const watermark = wmField ? (ctx.WatermarkValue ?? undefined) : undefined;

        if (desc.ReadMethod === 'POST') {
            const body: Record<string, unknown> = { ...scopeParams };
            if (desc.Scheme === 'offset') {
                body.StartRecord = offset + 1;
                body.EndRecord = offset + pageSize;
            } else if (desc.Scheme === 'marker-direction') {
                if (cursor) body.Marker = cursor;
                body.Direction = 'down';
                body.NumberToReturn = pageSize;
            } else if (obj.Name === 'ResourceLibraryDocuments') {
                // ResourceLibrary/GetLibraryDocuments defaults to DaysBack=30, MaxRecords=10 unless overridden.
                if (body.DaysBack == null) {
                    const startDate = this.readConfigString(ctx.CompanyIntegration, 'startDate');
                    body.DaysBack = startDate ? daysBetween(startDate, toISODate(new Date())) : 3650;
                }
                if (body.MaxRecords == null) {
                    body.MaxRecords = Math.max(pageSize, 500);
                }
            }
            return { URL: path, Method: 'POST', Body: body };
        }

        // GET — query params.
        const query: Record<string, string> = { ...scopeParams };
        if (desc.Scheme === 'seek-key') {
            const afterParam = desc.Params.find(p => /^after.+Key$/i.test(p));
            if (afterParam && cursor) query[afterParam] = cursor;
            query.limit = String(pageSize);
        } else if (desc.Scheme === 'continuation-token') {
            if (cursor) query.continuationToken = cursor;
            query.maxRecords = String(pageSize);
        } else if (desc.Scheme === 'query-offset') {
            query.firstRecord = String(offset);
            query.maxRecords = String(pageSize);
        } else {
            // None: apply a cap param when the operation documents one (from the accepted door_args).
            const capParam = this.objectDoorArgs(obj).find(p => /^(maxRecords|maxResults|maxToRetrieve|numberToReturn)$/i.test(p));
            if (capParam && query[capParam] == null) query[capParam] = String(pageSize);
        }
        // Server-side incremental: EventRegistrants documents a real `modifiedDateTime` watermark param.
        if (watermark && wmField && this.objectDoorArgs(obj).some(a => /^modifiedDateTime$/i.test(a))) {
            query.modifiedDateTime = watermark;
        }
        return { URL: this.appendQuery(path, query), Method: 'GET' };
    }

    /** Computes the next page's cursor/offset + whether more remain, combining the envelope signal with the record-derived cursor. */
    private computeNextPage(
        desc: PaginationDescriptor,
        rawBody: unknown,
        records: Record<string, unknown>[],
        obj: MJIntegrationObjectEntity,
        pkFieldNames: string[],
        offset: number,
        pageSize: number
    ): PaginationState {
        if (desc.Scheme === 'none') return { HasMore: false };

        const envelope = this.ExtractPaginationInfo(rawBody, obj.PaginationType, 1, offset, pageSize);
        if (desc.Scheme === 'offset' || desc.Scheme === 'query-offset') {
            const full = records.length >= pageSize;
            return { HasMore: envelope.HasMore || full, NextOffset: offset + records.length };
        }

        // Cursor family — the next token is the last record's key field (envelope echoes none).
        const derived = this.lastRecordCursor(desc, records, pkFieldNames);
        const full = records.length >= pageSize;
        const nextCursor = envelope.NextCursor ?? derived;
        const hasMore = (envelope.HasMore || full) && nextCursor != null;
        return { HasMore: hasMore, NextCursor: nextCursor };
    }

    /** Derives the continuation cursor VALUE from the last record per scheme (seek-key / continuation / marker). */
    private lastRecordCursor(
        desc: PaginationDescriptor,
        records: Record<string, unknown>[],
        pkFieldNames: string[]
    ): string | undefined {
        if (records.length === 0) return undefined;
        const last = records[records.length - 1];
        if (desc.Scheme === 'marker-direction') return this.readRecordString(last, ['Marker']);
        if (desc.Scheme === 'seek-key') {
            const afterParam = desc.Params.find(p => /^after.+Key$/i.test(p));
            const keyName = afterParam ? afterParam.replace(/^after/i, '') : undefined; // afterContactKey → ContactKey
            const candidates = [keyName, ...pkFieldNames].filter((k): k is string => !!k);
            return this.readRecordString(last, candidates);
        }
        // continuation-token — the object's PK field is the documented first-field continuation key.
        return this.readRecordString(last, pkFieldNames);
    }

    /** Per-scheme default page size. */
    protected pageSizeForScheme(scheme: PageScheme): number {
        switch (scheme) {
            case 'seek-key': return DEFAULT_SEEK_LIMIT;
            case 'continuation-token': return DEFAULT_CONTINUATION_MAX;
            case 'marker-direction': return DEFAULT_MARKER_COUNT;
            case 'offset':
            case 'query-offset': return DEFAULT_OFFSET_WINDOW;
            default: return DEFAULT_SEEK_LIMIT;
        }
    }

    // ── Auth internals ───────────────────────────────────────────────

    /** POSTs the Login operation and reads the returned AuthToken.Token. */
    private async loginForToken(creds: HLTCredentials, region: HLTRegion, baseURLOverride: string | null): Promise<string> {
        if (!creds.IAMKey || !creds.IAMPassword) {
            throw new Error(
                'Higher Logic credential incomplete: provide an IAM Key + IAM Password (the Login Username/Password), ' +
                'or a pre-issued Token. SSO (SAML/OIDC/OAuth2-code) is end-user login and is NOT the connector auth path.'
            );
        }
        const host = baseURLOverride ? baseURLOverride.replace(/\/+$/, '') : `${REGIONAL_HOSTS[region]}/api`;
        const url = this.joinURL(host, LOGIN_PATH);
        const headers = { 'Content-Type': 'application/json', 'Accept': 'application/json' };
        const preAuth: HLTAuthContext = { Token: '', Region: region, AuthHeaderName: 'Authorization', AuthHeaderScheme: 'Bearer' };
        const response = await this.MakeHTTPRequest(preAuth, url, 'POST', headers, {
            Username: creds.IAMKey,
            Password: creds.IAMPassword,
        });
        if (response.Status < 200 || response.Status >= 300) {
            throw new Error(`Higher Logic Login failed: HTTP ${response.Status}. Check the IAM Key + IAM Password and region.`);
        }
        const token = this.readTokenFromLogin(response.Body);
        if (!token) {
            throw new Error('Higher Logic Login returned HTTP 2xx but no AuthToken.Token was present in the response body.');
        }
        return token;
    }

    /** Reads the AuthToken.Token (or a bare `Token`) from a Login response body. */
    private readTokenFromLogin(body: unknown): string | undefined {
        if (!body || typeof body !== 'object') return undefined;
        const b = body as Record<string, unknown>;
        const direct = this.readString(b, ['Token', 'token', 'AuthToken', 'authToken', 'AccessToken', 'accessToken']);
        if (direct) return direct;
        const nested = b.AuthToken ?? b.authToken;
        if (nested && typeof nested === 'object') {
            return this.readString(nested as Record<string, unknown>, ['Token', 'token']);
        }
        return undefined;
    }

    /** Resolves the tenant region from Configuration/credential; defaults to US. */
    private resolveRegion(companyIntegration: MJCompanyIntegrationEntity, creds: HLTCredentials): HLTRegion {
        const raw = (this.readConfigString(companyIntegration, 'region') ?? creds.Region ?? 'US').toString().trim().toLowerCase();
        return raw === 'canada' || raw === 'ca' ? 'Canada' : 'US';
    }

    /** Reads an explicit full base-URL override from Configuration/credential (sandbox / mock). */
    private resolveBaseURLOverride(companyIntegration: MJCompanyIntegrationEntity, creds: HLTCredentials): string | null {
        const raw = this.readConfigString(companyIntegration, 'BaseURL') ?? this.readConfigString(companyIntegration, 'baseURL') ?? creds.BaseURL;
        if (raw && /^https?:\/\//i.test(raw.trim())) return raw.trim();
        return null;
    }

    // ── CRUD ──────────────────────────────────────────────────────────
    //
    // Update / Delete / Get use the INHERITED generic per-operation path (the per-IO Update*/Delete* columns +
    // the base's {id} path substitution / body-ID handling). CreateRecord is overridden ONLY to substitute
    // PARENT template vars into the create path (the base doesn't fill `{parent}`/`{blogKey}`/…), preserving
    // the wrapped/flat body build and the loud-on-empty-id BuildCreatedResult contract.

    /**
     * OVERRIDDEN for one idiosyncrasy: nested create paths carry parent template vars filled from the
     * record's own attributes (e.g. `/v2.0/Blogs/AddComment?blogKey={parent}`,
     * `/v2.0/ResourceLibrary/PostDocument?libraryKey={parent}`, the join-key vars on
     * `/v2.0/Volunteer/VolunteerForOpportunity?volunteerOpportunityKey={volunteerOpportunityKey}`). Everything
     * else matches the generic path. Action-style creates whose IDLocation is `n/a` (a join with no returned
     * record id) derive their identity from the join-key attributes so BuildCreatedResult still succeeds
     * honestly rather than failing on an empty id. Multipart ResourceLibrary uploads are best-effort here
     * (RequiresLiveVerification).
     */
    public override async CreateRecord(ctx: CreateRecordContext): Promise<CRUDResult> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const contextUser = ctx.ContextUser as UserInfo;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        if (!obj.CreateAPIPath || !obj.CreateMethod) {
            return super.CreateRecord(ctx); // delegate the "not configured" error consistently
        }
        const auth = await this.Authenticate(ci, contextUser);
        const baseURL = this.GetBaseURL(ci, auth);
        const headers = this.BuildHeaders(auth);
        const path = this.substitutePathVarsFromAttributes(obj.CreateAPIPath, ctx.Attributes);
        const url = this.joinURL(baseURL, path);
        const body = this.BuildOperationBody(ctx.Attributes, obj.CreateBodyShape, obj.CreateBodyKey);
        const response = await this.MakeHTTPRequest(auth, url, obj.CreateMethod, headers, body);
        if (response.Status >= 200 && response.Status < 300) {
            let externalID = this.ExtractIDFromResponse(response, obj.CreateIDLocation);
            if (!externalID && obj.CreateIDLocation === 'n/a') {
                // Volunteers' withdraw-from-opportunity delete needs the opportunity key back (the vendor's
                // 204-No-Content create response carries none), so its identity is a composite
                // `<volunteerOpportunityKey>|<own key>` rather than the bare joinKeyIdentity() — DeleteRecord
                // below splits it back apart to rebuild the withdraw URL.
                externalID = ctx.ObjectName === 'Volunteers'
                    ? this.volunteerJoinIdentity(ctx.Attributes)
                    : this.joinKeyIdentity(obj, ctx.Attributes); // action/join create — identity = key pair
            }
            return this.BuildCreatedResult(externalID, response.Status, ctx.ObjectName);
        }
        return {
            Success: false,
            StatusCode: response.Status,
            ErrorMessage: this.ExtractErrorMessage(response) ?? `HTTP ${response.Status} on create`,
        };
    }

    /**
     * OVERRIDDEN for one idiosyncrasy: Volunteers.DeleteAPIPath templates named vars
     * (`{volunteerOpportunityKey}`, `{comments}`), not the base's `{id}`/`{ID}`/`{ExternalID}` sentinel —
     * DeleteRecordContext carries only a single ExternalID, so the generic SubstituteIDInPath can never fill
     * them. ExternalID for Volunteers is the composite `<volunteerOpportunityKey>|<own key>` synthesized in
     * CreateRecord above; split it back apart here. Everything else delegates to the generic path.
     */
    public override async DeleteRecord(ctx: DeleteRecordContext): Promise<CRUDResult> {
        if (ctx.ObjectName !== 'Volunteers') return super.DeleteRecord(ctx);
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const contextUser = ctx.ContextUser as UserInfo;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        if (!obj.DeleteAPIPath || !obj.DeleteMethod) return super.DeleteRecord(ctx);
        const [volunteerOpportunityKey] = String(ctx.ExternalID ?? '').split('|');
        const auth = await this.Authenticate(ci, contextUser);
        const baseURL = this.GetBaseURL(ci, auth);
        const headers = this.BuildHeaders(auth);
        const path = obj.DeleteAPIPath
            .replace(/\{volunteerOpportunityKey\}/g, encodeURIComponent(volunteerOpportunityKey ?? ''))
            .replace(/\{comments\}/g, '');
        const url = this.joinURL(baseURL, path);
        const response = await this.MakeHTTPRequest(auth, url, obj.DeleteMethod, headers);
        if (response.Status >= 200 && response.Status < 300) {
            return { Success: true, StatusCode: response.Status };
        }
        return {
            Success: false,
            StatusCode: response.Status,
            ErrorMessage: this.ExtractErrorMessage(response) ?? `HTTP ${response.Status} on delete`,
        };
    }

    // ── Connection test ──────────────────────────────────────────────

    /**
     * Tests the connection by exercising the auth flow (token exchange) + a lightweight read. A successful
     * Authenticate proves the credential + region resolve; a 2xx read proves the token is accepted. 401/403
     * → auth failure; other non-2xx → error.
     */
    public override async TestConnection(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<ConnectionTestResult> {
        try {
            const auth = await this.Authenticate(companyIntegration, contextUser);
            const baseURL = this.GetBaseURL(companyIntegration, auth);
            const headers = this.BuildHeaders(auth);
            const url = this.joinURL(baseURL, '/v2.0/Communities/GetMyCommunities');
            const response = await this.MakeHTTPRequest(auth, url, 'GET', headers);
            if (response.Status >= 200 && response.Status < 300) {
                return { Success: true, Message: 'Higher Logic Thrive Community connection successful.' };
            }
            if (response.Status === 401 || response.Status === 403) {
                return { Success: false, Message: `Higher Logic authentication failed (HTTP ${response.Status}). Check the IAM Key + IAM Password / token and region.` };
            }
            return { Success: false, Message: `Higher Logic connection test returned HTTP ${response.Status}.` };
        } catch (err) {
            const msg = err instanceof Error ? err.message : String(err);
            return { Success: false, Message: `Higher Logic connection test error: ${msg}` };
        }
    }

    // ── Credential loading ───────────────────────────────────────────

    /** Reads the Higher Logic credential from the linked Credential entity, or the Configuration JSON fallback. */
    private async loadCredentials(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<HLTCredentials> {
        let creds: HLTCredentials | null = null;
        if (companyIntegration.CredentialID) {
            creds = await this.loadFromCredentialEntity(companyIntegration.CredentialID, contextUser);
        }
        const configCreds = companyIntegration.Configuration ? this.parseCredentialJson(companyIntegration.Configuration) : null;
        if (!creds && !configCreds) {
            throw new Error(
                'No Higher Logic credential found. Attach a credential carrying the IAM Key + IAM Password ' +
                '(or a pre-issued Token), or set the connection Configuration JSON.'
            );
        }
        return { ...(configCreds ?? {}), ...(creds ?? {}) };
    }

    /** Loads a credential row and parses its Values JSON. */
    private async loadFromCredentialEntity(
        credentialID: string,
        contextUser: UserInfo,
        provider?: IMetadataProvider
    ): Promise<HLTCredentials | null> {
        const md = provider ?? new Metadata();
        const credential = await md.GetEntityObject<MJCredentialEntity>('MJ: Credentials', contextUser);
        const loaded = await credential.Load(credentialID);
        if (!loaded || !credential.Values) return null;
        return this.parseCredentialJson(credential.Values);
    }

    /** Extracts Higher Logic credential fields from a credential/config JSON string. */
    private parseCredentialJson(json: string): HLTCredentials | null {
        try {
            const parsed = JSON.parse(json) as Record<string, unknown>;
            const region = this.readString(parsed, ['region', 'Region']);
            return {
                IAMKey: this.readString(parsed, ['IAMKey', 'iamKey', 'iam_key', 'Username', 'username', 'IAMKeyEnv']),
                IAMPassword: this.readString(parsed, ['IAMPassword', 'iamPassword', 'iam_password', 'Password', 'password']),
                Token: this.readString(parsed, ['Token', 'token', 'AuthToken', 'authToken']),
                Region: region === 'Canada' || region === 'canada' || region === 'ca' ? 'Canada' : region === 'US' || region === 'us' ? 'US' : undefined,
                BaseURL: this.readString(parsed, ['BaseURL', 'baseURL', 'BaseUrl', 'baseUrl']),
                AuthHeaderName: this.readString(parsed, ['AuthHeaderName', 'authHeaderName']),
                // Scheme may legitimately be an EMPTY string (raw token, no `Bearer ` prefix) — preserve it.
                AuthHeaderScheme: this.readStringAllowEmpty(parsed, ['AuthHeaderScheme', 'authHeaderScheme']),
            };
        } catch {
            return null;
        }
    }

    // ── Helpers ──────────────────────────────────────────────────────

    /** Substitutes `{var}` tokens in a create path from the record's own attributes (nested/parent-scoped creates). */
    private substitutePathVarsFromAttributes(path: string, attributes: Record<string, unknown>): string {
        return path.replace(/\{(\w+)\}/g, (match, name: string) => {
            // Support the generic `{parent}` sentinel by trying the object's obvious parent-key attributes.
            const direct = attributes[name];
            if (direct != null && String(direct).length > 0) return encodeURIComponent(String(direct));
            if (name === 'parent') {
                const parentVal = this.firstParentKeyValue(attributes);
                if (parentVal) return encodeURIComponent(parentVal);
            }
            return match;
        });
    }

    /** Finds the first `<X>Key`-shaped attribute value (a parent key) for a `{parent}` sentinel substitution. */
    private firstParentKeyValue(attributes: Record<string, unknown>): string | null {
        for (const [k, v] of Object.entries(attributes)) {
            if (/Key$/.test(k) && v != null && String(v).length > 0) return String(v);
        }
        return null;
    }

    /** Builds a composite identity from the object's PK attributes (for action/join creates with no returned id). */
    private joinKeyIdentity(obj: MJIntegrationObjectEntity, attributes: Record<string, unknown>): string | undefined {
        const pk = this.pkFieldNames(this.GetCachedFields(obj.ID));
        const parts = pk.map(n => attributes[n]).filter(v => v != null && String(v).length > 0).map(v => String(v));
        return parts.length > 0 ? parts.join('|') : undefined;
    }

    /**
     * Volunteers-specific identity: `<volunteerOpportunityKey>|<VolunteerOpportunityVolunteerKey>`. Unlike
     * joinKeyIdentity (PK fields only), this ALSO carries the opportunity key so DeleteRecord (withdraw) can
     * rebuild the vendor's `{volunteerOpportunityKey}` path var without a second read round-trip.
     */
    private volunteerJoinIdentity(attributes: Record<string, unknown>): string | undefined {
        const oppKey = attributes['volunteerOpportunityKey'] ?? attributes['VolunteerOpportunityKey'];
        const ownKey = attributes['VolunteerOpportunityVolunteerKey'];
        if (oppKey == null || String(oppKey).length === 0) return undefined;
        return `${String(oppKey)}|${ownKey != null ? String(ownKey) : ''}`;
    }

    /** Joins a base URL and a path (mirrors the base's private BuildFullURL). */
    private joinURL(baseURL: string, apiPath: string): string {
        const base = baseURL.endsWith('/') ? baseURL.slice(0, -1) : baseURL;
        const path = apiPath.startsWith('/') ? apiPath : `/${apiPath}`;
        return `${base}${path}`;
    }

    /** Appends a query-param map to a URL, encoding keys + values (skips empty values). */
    private appendQuery(url: string, params: Record<string, string>): string {
        const entries = Object.entries(params).filter(([, v]) => v != null && String(v).length > 0);
        if (entries.length === 0) return url;
        const sep = url.includes('?') ? '&' : '?';
        const qs = entries.map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`).join('&');
        return `${url}${sep}${qs}`;
    }

    /** Throws a descriptive error on a non-2xx (403 is handled by the caller as a skip). */
    private assert2xx(response: RESTResponse, url: string, objectName: string): void {
        if (response.Status < 200 || response.Status >= 300) {
            throw new Error(`[higherlogic-thrive] fetch of "${objectName}" failed: HTTP ${response.Status} from ${url}`);
        }
    }

    /** Tracks the maximum watermark value seen (string compare on ISO-datetime / key fields). */
    private trackWatermark(current: string | null, record: Record<string, unknown>, wmField: string | null): string | null {
        if (!wmField) return current;
        const v = record[wmField];
        if (v == null) return current;
        const s = String(v);
        if (s.length === 0) return current;
        if (current == null || s > current) return s;
        return current;
    }

    /** Returns the later of two watermark strings (null-safe). */
    private laterWatermark(existing: string | null, candidate: string): string {
        if (existing == null) return candidate;
        return candidate > existing ? candidate : existing;
    }

    /** PK field names in Sequence order (falls back to ['ID'] when unmarked). */
    private pkFieldNames(fields: MJIntegrationObjectFieldEntity[]): string[] {
        const pk = fields.filter(f => f.IsPrimaryKey).sort((a, b) => a.Sequence - b.Sequence).map(f => f.Name);
        return pk.length > 0 ? pk : ['ID'];
    }

    /**
     * Builds an ExternalRecord with the FULL source record in Fields (full-record pass-through — the
     * framework's custom-column capture diffs keys(Fields) against the field maps). ExternalID is the
     * composite PK when every component is present + non-empty, else empty (the base ToExternalRecord's
     * content-hash fallback is not reachable here, so a keyless row keeps its raw shape).
     */
    private buildExternalRecord(raw: Record<string, unknown>, objectType: string, pkFieldNames: string[]): ExternalRecord {
        const allPresent = pkFieldNames.length > 0 && pkFieldNames.every(n => raw[n] != null && String(raw[n]).length > 0);
        const externalID = allPresent ? pkFieldNames.map(n => String(raw[n])).join('|') : '';
        return { ExternalID: externalID, ObjectType: objectType, Fields: raw };
    }

    /** Reads CompanyIntegration.Configuration.objectParams[objectName] as a string→string scope-param map. */
    private readObjectScopeParams(companyIntegration: MJCompanyIntegrationEntity, objectName: string): Record<string, string> {
        if (!companyIntegration.Configuration) return {};
        try {
            const cfg = JSON.parse(companyIntegration.Configuration) as Record<string, unknown>;
            const op = cfg.objectParams;
            if (!op || typeof op !== 'object') return {};
            const forObj = (op as Record<string, unknown>)[objectName];
            if (!forObj || typeof forObj !== 'object') return {};
            const out: Record<string, string> = {};
            for (const [k, v] of Object.entries(forObj as Record<string, unknown>)) {
                if (v != null && (typeof v === 'string' || typeof v === 'number' || typeof v === 'boolean')) out[k] = String(v);
            }
            return out;
        } catch {
            return {};
        }
    }

    /** Reads the accessPath.door_args array from an IO's Configuration (the operation's accepted params). */
    private objectDoorArgs(obj: MJIntegrationObjectEntity): string[] {
        const cfg = this.parseObjectConfig(obj);
        const ap = cfg?.accessPath as { door_args?: unknown } | undefined;
        return Array.isArray(ap?.door_args) ? (ap!.door_args as unknown[]).filter((a): a is string => typeof a === 'string') : [];
    }

    /** Parses an IntegrationObject's Configuration JSON (tolerant of absent/invalid). */
    private parseObjectConfig(obj: MJIntegrationObjectEntity): Record<string, unknown> | null {
        const raw = (obj as unknown as { Configuration?: string | null }).Configuration;
        if (!raw || typeof raw !== 'string') return null;
        try { return JSON.parse(raw) as Record<string, unknown>; } catch { return null; }
    }

    /** Gets an IO from the cache without throwing (used by StableOrderingKey, which may be called early). */
    private tryGetCachedObject(objectName: string): MJIntegrationObjectEntity | null {
        try {
            const integ = IntegrationEngineBase.Instance.GetIntegrationByName(this.IntegrationName);
            if (!integ) return null;
            return IntegrationEngineBase.Instance.GetIntegrationObject(integ.ID, objectName) ?? null;
        } catch {
            return null;
        }
    }

    /** Reads a trimmed string value from a CompanyIntegration's Configuration JSON. */
    private readConfigString(companyIntegration: MJCompanyIntegrationEntity, key: string): string | null {
        if (!companyIntegration.Configuration) return null;
        try {
            const cfg = JSON.parse(companyIntegration.Configuration) as Record<string, unknown>;
            const v = cfg[key];
            return typeof v === 'string' && v.trim().length > 0 ? v.trim() : null;
        } catch {
            return null;
        }
    }

    /** Reads a boolean flag from a CompanyIntegration's Configuration JSON. */
    private readConfigFlag(companyIntegration: MJCompanyIntegrationEntity, key: string): boolean {
        if (!companyIntegration.Configuration) return false;
        try {
            const cfg = JSON.parse(companyIntegration.Configuration) as Record<string, unknown>;
            return cfg[key] === true || cfg[key] === 'true';
        } catch {
            return false;
        }
    }

    /** Returns the first present, non-empty string among the given keys. */
    private readString(obj: Record<string, unknown>, keys: string[]): string | undefined {
        for (const k of keys) {
            const v = obj[k];
            if (typeof v === 'string' && v.length > 0) return v;
        }
        return undefined;
    }

    /** Reads a string value, PRESERVING an explicit empty string (key present) — undefined only when absent. */
    private readStringAllowEmpty(obj: Record<string, unknown>, keys: string[]): string | undefined {
        for (const k of keys) {
            const v = obj[k];
            if (typeof v === 'string') return v;
        }
        return undefined;
    }

    /** Reads a string from a record, coercing number keys to strings. */
    private readRecordString(record: Record<string, unknown>, keys: string[]): string | undefined {
        for (const k of keys) {
            const v = record[k];
            if (typeof v === 'string' && v.length > 0) return v;
            if (typeof v === 'number') return String(v);
        }
        return undefined;
    }

    /** Returns the first present numeric value among the given keys. */
    private readNumber(obj: Record<string, unknown>, keys: string[]): number | null {
        for (const k of keys) {
            const v = obj[k];
            if (typeof v === 'number' && Number.isFinite(v)) return v;
        }
        return null;
    }

    /** Returns the first present boolean value on a key whose name starts with `prefix`. */
    private readBooleanStartsWith(obj: Record<string, unknown>, prefix: string): boolean | undefined {
        for (const [k, v] of Object.entries(obj)) {
            if (k.startsWith(prefix) && typeof v === 'boolean') return v;
        }
        return undefined;
    }

    /** Reads a nested string value via a key path (tolerant of absent/invalid). */
    private readNestedString(obj: Record<string, unknown> | null, path: string[]): string | undefined {
        let cur: unknown = obj;
        for (const p of path) {
            if (!cur || typeof cur !== 'object') return undefined;
            cur = (cur as Record<string, unknown>)[p];
        }
        return typeof cur === 'string' && cur.length > 0 ? cur : undefined;
    }

    /** Returns true when the object is an opt-in private/social object (InboxMessages, SentMessages, Friends, FriendRequests). */
    private isPrivateSocialOptInObject(obj: MJIntegrationObjectEntity): boolean {
        if (PRIVATE_SOCIAL_OBJECTS.has(obj.Name)) return true;
        const cfg = this.parseObjectConfig(obj);
        return cfg?.optInGroup === 'PrivateSocialObjects' || cfg?.optInRequired === true;
    }

    /** Returns true when opt-in private/social objects are enabled on the CompanyIntegration configuration. */
    private isPrivateSocialEnabled(companyIntegration: MJCompanyIntegrationEntity, objectName: string): boolean {
        if (this.readConfigFlag(companyIntegration, 'includePrivateSocialObjects')) return true;
        const scope = this.readObjectScopeParams(companyIntegration, objectName);
        return scope.enabled === 'true' || scope.includePrivateSocialObjects === 'true';
    }

    /** Reads `migrationPacing` overrides from CompanyIntegration.Configuration. */
    private readMigrationPacing(companyIntegration: MJCompanyIntegrationEntity): HLTMigrationPacing | null {
        if (!companyIntegration.Configuration) return null;
        try {
            const cfg = JSON.parse(companyIntegration.Configuration) as Record<string, unknown>;
            const raw = cfg.migrationPacing;
            if (!raw || typeof raw !== 'object') return null;
            const p = raw as Record<string, unknown>;
            return {
                tokensPerSec: typeof p.tokensPerSec === 'number' ? p.tokensPerSec : undefined,
                burst: typeof p.burst === 'number' ? p.burst : undefined,
                maxConcurrency: typeof p.maxConcurrency === 'number' ? p.maxConcurrency : undefined,
                minDelayBetweenRequestsMs: typeof p.minDelayBetweenRequestsMs === 'number' ? p.minDelayBetweenRequestsMs : undefined,
                maxRequestsPerRun: typeof p.maxRequestsPerRun === 'number' ? p.maxRequestsPerRun : undefined,
                maxWindowsPerRun: typeof p.maxWindowsPerRun === 'number' ? p.maxWindowsPerRun : undefined,
                checkpointPerWindow: p.checkpointPerWindow === true || p.checkpointPerWindow === 'true',
            };
        } catch {
            return null;
        }
    }

    /**
     * Resolves optional `HLTDateWindowConfig` for an object from:
     * 1. `CompanyIntegration.Configuration.dateWindowing[obj.Name]` (or boolean `true` with defaults)
     * 2. `IntegrationObject.Configuration.dateWindowing` (when enabled)
     * 3. `scopeParams.windowDays` / `scopeParams.startDate` / `scopeParams.libraryKeys`
     */
    private resolveDateWindowConfig(
        companyIntegration: MJCompanyIntegrationEntity,
        obj: MJIntegrationObjectEntity,
        scopeParams: Record<string, string>
    ): HLTDateWindowConfig | null {
        const objCfg = this.parseObjectConfig(obj);
        const objWin = (objCfg?.dateWindowing && typeof objCfg.dateWindowing === 'object')
            ? (objCfg.dateWindowing as Record<string, unknown>)
            : null;

        let ciWin: Record<string, unknown> | null = null;
        let globalStartDate: string | undefined;
        let globalWindowDays: number | undefined;
        let useDeltaMemberUpdates = false;

        if (companyIntegration.Configuration) {
            try {
                const parsed = JSON.parse(companyIntegration.Configuration) as Record<string, unknown>;
                if (typeof parsed.startDate === 'string') globalStartDate = parsed.startDate;
                if (typeof parsed.windowDays === 'number') globalWindowDays = parsed.windowDays;
                useDeltaMemberUpdates = parsed.useDeltaMemberUpdates === true || parsed.useDeltaMemberUpdates === 'true';
                const dw = parsed.dateWindowing;
                if (dw && typeof dw === 'object') {
                    const perObj = (dw as Record<string, unknown>)[obj.Name];
                    if (perObj === true) ciWin = {};
                    else if (perObj && typeof perObj === 'object') ciWin = perObj as Record<string, unknown>;
                }
            } catch {
                /* ignore malformed JSON */
            }
        }

        const hasScopeWindow = scopeParams.windowDays != null || scopeParams.libraryKeys != null;
        const isDeltaMembers = obj.Name === 'CommunityMembers' && useDeltaMemberUpdates;
        const objWinEnabled = objWin != null && objWin.enabled === true;

        if (!ciWin && !objWinEnabled && !hasScopeWindow && !isDeltaMembers) {
            return null;
        }

        const merged: Record<string, unknown> = { ...(objWin ?? {}), ...(ciWin ?? {}) };
        const scopeKeysRaw = merged.scopeKeys ?? (scopeParams.libraryKeys ? scopeParams.libraryKeys.split(',').map(s => s.trim()).filter(Boolean) : undefined);
        const scopeKeys = Array.isArray(scopeKeysRaw)
            ? scopeKeysRaw.map(k => String(k).trim()).filter(Boolean)
            : undefined;

        // Default endpoints for known windowed objects when not explicitly overridden:
        const defaultWindowAPIPath =
            obj.Name === 'Events' ? '/v2.0/Events/SearchEvents'
            : isDeltaMembers ? '/v2.0/System/GetCommunityMemberUpdates'
            : undefined;
        const defaultWindowMethod: 'GET' | 'POST' | undefined =
            (obj.Name === 'Events' || isDeltaMembers || obj.Name === 'ResourceLibraryDocuments') ? 'POST' : undefined;

        return {
            startDate: typeof merged.startDate === 'string' ? merged.startDate : (scopeParams.startDate ?? globalStartDate),
            windowDays: typeof merged.windowDays === 'number'
                ? merged.windowDays
                : (scopeParams.windowDays ? Number(scopeParams.windowDays) : globalWindowDays),
            lookbackDays: typeof merged.lookbackDays === 'number' ? merged.lookbackDays : undefined,
            windowAPIPath: typeof merged.windowAPIPath === 'string' ? merged.windowAPIPath : defaultWindowAPIPath,
            windowMethod: (merged.windowMethod === 'GET' || merged.windowMethod === 'POST') ? merged.windowMethod : defaultWindowMethod,
            fromParam: typeof merged.fromParam === 'string' ? merged.fromParam : undefined,
            toParam: typeof merged.toParam === 'string' ? merged.toParam : undefined,
            capParam: typeof merged.capParam === 'string' ? merged.capParam : undefined,
            capLimit: typeof merged.capLimit === 'number' ? merged.capLimit : undefined,
            capThreshold: typeof merged.capThreshold === 'number' ? merged.capThreshold : undefined,
            scopeKeys,
            scopeParamName: typeof merged.scopeParamName === 'string' ? merged.scopeParamName : undefined,
        };
    }
}

