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
    type SyncErrorCode,
    type CreateRecordContext,
    type UpdateRecordContext,
    type DeleteRecordContext,
    type CRUDResult,
    type SourceSchemaInfo,
} from '@memberjunction/integration-engine';
import { mergeDeclaredWithSampledFields } from '@memberjunction/connector-schema-merge';

/**
 * 5.x COMPATIBILITY SHIM for the engine's shared `buildAPIKeyHeaderValue` auth-helper.
 *
 * The shared helper (`auth-helpers/APIKeyHeaderBuilder`) landed AFTER 5.51.0, the newest published
 * `@memberjunction/integration-engine` — it exists only in the unreleased 6.x line. This package pins the
 * 5.x range so it installs today, so importing the shared helper here would not resolve at all.
 *
 * This is a byte-for-byte reimplementation of that helper's `buildAPIKeyHeaderValue`, guards INCLUDED:
 * the empty-key rejection and the CR/LF header-injection rejection are the whole point of centralizing it,
 * so dropping them for convenience would be a security regression, not a simplification.
 *
 * REPLACE this shim with the shared import the moment an engine version exporting it is published — the
 * point of the helper is that no connector hand-maintains this logic.
 */
function buildAPIKeyHeaderValue(req: { HeaderName?: string; ApiKey: string; ValuePrefix?: string }): string {
    const HEADER_INJECTION = /[\r\n]/;
    const key = (req.ApiKey ?? '').trim();
    if (key.length === 0) {
        throw new Error('APIKeyHeaderBuilder: ApiKey is required and cannot be empty.');
    }
    if (HEADER_INJECTION.test(key)) {
        throw new Error('APIKeyHeaderBuilder: ApiKey must not contain CR/LF characters.');
    }
    const prefix = (req.ValuePrefix ?? '').trim();
    if (prefix.length > 0 && HEADER_INJECTION.test(prefix)) {
        throw new Error('APIKeyHeaderBuilder: ValuePrefix must not contain CR/LF characters.');
    }
    return prefix.length > 0 ? `${prefix} ${key}` : key;
}

// ─── Design note ────────────────────────────────────────────────────────
//
// This connector is PURE MECHANISM. The object/field catalog is NOT baked here — it lives in the Declared
// metadata (metadata/integrations/reply/.reply.integration.json), extracted from the credential-free
// Reply.io OpenAPI v3 bundle (case-1 discovery: a publicly reachable schema-of-record, no token needed).
// Discovery is INHERITED from BaseRESTIntegrationConnector: DiscoverObjects / DiscoverFields /
// IntrospectSchema read that persisted Declared metadata from the IntegrationEngineBase cache, so the
// standard universe re-yields credential-free. A live credential is purely ADDITIVE — the sample-union
// IntrospectSchema override below adds a tenant's custom fields on top. There is NO hardcoded object list,
// NO field catalog, and NO baked PK/FK/required/readonly constants in this file.
//
// What this class supplies (the Reply.io protocol shape over REST/JSON):
//  - Auth: `Authorization: Bearer <api key>`, composed by the SHARED auth-helper `buildAPIKeyHeaderValue`
//    (never a hand-built literal). The key is static and opaque: no token exchange, no signature, no refresh
//    and NO inline crypto — so the OAuth1a/OAuth2 grant helpers deliberately do not apply here.
//  - Base URL `https://api.reply.io`; every path carries its own `/v3` prefix in the metadata APIPath.
//  - Pagination: offset only — `top` (page size) + `skip` (offset), continuation from the envelope's
//    `hasMore` flag, page size capped at each endpoint's DECLARED ceiling (IO.DefaultPageSize).
//  - Cross-page primary-key dedupe: offset paging over a mutating collection shifts the window, so a page
//    boundary is NOT a record boundary and the same record can appear on two consecutive pages.
//  - NO incremental watermark: the extractor searched for and found none (Configuration.watermarkNegative
//    "found":"none" on every IO; SupportsIncrementalSync=false on all 84). Every object is FullPullHashDiff —
//    this connector therefore neither reads nor writes a watermark. Change detection is the engine's
//    content-hash diff; near-real-time deltas are the vendor's webhooks, not a polled watermark.
//  - Errors: RFC 9457 `application/problem+json` carrying a STABLE machine `code` slug
//    (`<resource>.<variant>`). Classification reads the CODE, never the human `detail`. A 401 body is
//    documented EMPTY, so the parser must never assume a body exists.
//  - 403 = reachable-but-not-entitled (missing scope / feature not on the tenant's plan). It is never an
//    invalid credential and never a connector defect; it is surfaced as a structured FetchWarning.
//  - Bulk / non-atomic partial success: a 2xx whose body is a dictionary of ONLY the failed items
//    (`{ "<id>": { error, errorDetails } }`, `{}` = all succeeded). Outcomes are asserted from that
//    dictionary — never from HTTP 200 alone and never from a `Status === 'Success'` field.

// ─── Types ────────────────────────────────────────────────────────────

/** Parsed Reply.io credential. The API key is sent verbatim as the Bearer token. */
interface ReplyCredentials {
    /** Reply.io API key (Bearer token). */
    ApiKey?: string;
}

/** Auth context carrying the composed Bearer header + the resolved base URL. */
interface ReplyAuthContext extends RESTAuthContext {
    /** Full `Authorization: Bearer <key>` header value. */
    AuthHeader: string;
    /**
     * Explicit base-URL override read from the connection Configuration (`BaseURL` / `APIBaseURL`).
     * Production never sets this (the base is always https://api.reply.io); it exists so a sandbox or a
     * spec-generated mock can redirect the connector by DATA alone, with no code branch on environment.
     */
    BaseURLOverride?: string;
}

/** Reply.io list envelope — every paginated collection returns this shape. */
interface ReplyListEnvelope {
    items?: unknown;
    hasMore?: boolean;
}

/** RFC 9457 problem-details body. `code` is present on business problems, absent on middleware problems. */
interface ReplyProblem {
    /** Short, human-readable summary. */
    title?: string;
    /** HTTP status code echoed in the body. */
    status?: number;
    /** Human-readable explanation — for DISPLAY only; never classify on this. */
    detail?: string;
    /** Stable, machine-readable slug `<resource>.<variant>` — the classification key. */
    code?: string;
    /** Validation problems add a per-field error array. */
    errors?: unknown;
}

/** One per-item failure from a non-atomic (bulk) response dictionary. */
interface ReplyNotProcessedItem {
    /** camelCase resource-specific failure variant (`contactAlreadyInSequence`, `notFound`, …). */
    error?: string;
    /** Human-readable detail, nullable per the vendor schema. */
    errorDetails?: string | null;
}

/** The last non-2xx problem observed on the wire, retained so FetchChanges can explain an empty result. */
interface ObservedProblem {
    Status: number;
    URL: string;
    Problem: ReplyProblem | null;
}

/** An embedded-array projection: an object whose records live INSIDE another object's payload. */
interface EmbeddedProjection {
    /** The owning object's name as declared in `Configuration.resourceKey` (`"null"` when unowned). */
    OwnerName: string;
    /** The JSON key of the nested array to descend (`customFields`, `holidays`, `variants`, …). */
    NestedKey: string;
}

// ─── Constants ────────────────────────────────────────────────────────

/** Vendor default host. Overridable per-connection by data (Configuration.BaseURL) — never hardcoded downstream. */
const REPLY_DEFAULT_BASE_URL = 'https://api.reply.io';

/**
 * Absolute ceiling for the `top` page-size parameter. The spec documents `top` as "max 1000" on the
 * collection endpoints; per-endpoint ceilings that are LOWER are carried per-IO in DefaultPageSize and win.
 */
const REPLY_MAX_TOP = 1000;

/** Page size used when an IO declares pagination but no explicit ceiling — deliberately conservative. */
const REPLY_FALLBACK_TOP = 100;

/** Reply.io credential-verification endpoint. Documented `x-required-scope: none` — any valid key may call it. */
const REPLY_WHOAMI_PATH = '/v3/whoami';

/**
 * RATE-LIMIT PACING (not a catalog): request PATH families the vendor documents as more expensive than an
 * ordinary collection read — reporting and the per-entity statistics/state rollups. The frozen contract
 * carries ONE uniform budget for every IO (`Configuration.rateLimit` = 100/min + 3,000/hr on all 84), so
 * this is not an object/field claim and nothing here declares what exists; it only slows THIS connector's
 * own request rate on the families vendor guidance calls out, so a stats-heavy walk does not consume the
 * shared per-user budget faster than the rest of the sync can tolerate.
 */
const REPLY_STRICT_PACED_URL_PATTERNS: readonly RegExp[] = [
    /\/v3\/reporting\//i,          // /v3/reporting/*      — reporting surface
    /\/stats(?:[/?]|$)/i,          // .../{id}/stats       — e.g. email-account + sequence statistics
    /\/statuses(?:[/?]|$)/i,       // .../{id}/statuses    — per-contact status rollup
    /\/contacts\/state(?:[/?]|$)/i // /v3/sequences/{id}/contacts/state
];

/**
 * Minimum gap between two STRICT-family requests (≈60/min for those paths, vs the vendor's 100/min overall).
 * Applies only to this connector's own strict-family calls; the engine's AIMD bucket still governs globally.
 */
const REPLY_STRICT_FAMILY_MIN_GAP_MS = 1000;

// ─── ReplyConnector ────────────────────────────────────────────────────

/**
 * Reply.io connector — extends BaseRESTIntegrationConnector (REST/JSON over HTTP).
 *
 * Discovery, template-var read traversal (second-layer objects resolve their parent through
 * Configuration.parentObjectName), the paginated GET loop and the generic per-operation CRUD dispatch are
 * all INHERITED. This class supplies the Reply-specific protocol surface: Bearer auth, top/skip offset
 * pagination with per-endpoint ceilings, cross-page PK dedupe, embedded-array projection, RFC 9457 problem
 * handling with entitlement (403) separation, non-atomic bulk outcome assertion, and the §7/§10
 * sync-efficiency hooks the frozen contract evidences.
 */
@RegisterClass(BaseIntegrationConnector, 'ReplyConnector')
export class ReplyConnector extends BaseRESTIntegrationConnector {

    /** Cached auth for the lifetime of a sync run — Reply API keys are static, there is no refresh step. */
    private cachedAuth: ReplyAuthContext | null = null;

    /** Last non-2xx problem seen on the wire, used to explain an empty fetch instead of failing silently. */
    private lastProblem: ObservedProblem | null = null;

    /**
     * `Retry-After` (in ms) captured from the most recent 429 seen on the wire, held for exactly ONE read.
     *
     * WHY this exists: the inherited read path validates a non-2xx by throwing a PLAIN `Error` carrying only
     * a status + body preview — the response HEADERS are gone by the time the engine calls
     * `ExtractRetryAfterMs(error)`. Without this capture the vendor's own `Retry-After` instruction is
     * silently discarded on every throttled read and the engine falls back to a generic backoff curve,
     * which is precisely what the contract forbids (100/min AND 3,000/hr are SHARED per user — guessing the
     * wait either wastes the client's quota or hammers a closed window). Captured at the wire boundary,
     * consumed once, then cleared so a stale value can never be replayed against a later error.
     */
    private pendingRetryAfterMs: number | null = null;

    /** Wall-clock ms at which the last STRICT-family (reporting/stats) request was issued. */
    private lastStrictFamilyRequestAt = 0;

    // ── Identity (T1 three-way invariant) ────────────────────────────

    /** Verbatim `MJ: Integrations.Name`. Load-bearing: the T1 three-way check compares this === metadata Name. */
    public override get IntegrationName(): string {
        return 'Reply';
    }

    // ── Capability getters (kept in lockstep with the per-operation metadata columns) ──
    //
    // 34 of the 84 emitted IOs carry SupportsCreate|SupportsUpdate|SupportsDelete with populated
    // Create*/Update*/Delete* columns, so all three verbs are genuinely available. Per-object capability is
    // still enforced by the generic dispatch, which throws when an object's columns are null.

    public override get SupportsCreate(): boolean { return true; }
    public override get SupportsUpdate(): boolean { return true; }
    public override get SupportsDelete(): boolean { return true; }

    /**
     * Discovery is NON-authoritative. Reply.io publishes no describe-all endpoint (Configuration
     * DiscoveryIsAuthoritative=false in the frozen contract; the 270-path spec has no introspection route),
     * so a refresh can only re-yield what is already Active. Absence in a refresh proves nothing → never
     * deactivate an object on its basis.
     */
    public override get DiscoveryIsAuthoritative(): boolean {
        return false;
    }

    /**
     * Sample-union enrichment (MJ connector standard). The Declared metadata is spec-derived and cannot know
     * a tenant's CUSTOM fields (Reply exposes user-defined custom fields on contacts). After the base
     * cache-driven introspection, each object's live read shape is sampled via `DiscoverFieldsViaFetch` and
     * UNIONed into the declared set with `mergeDeclaredWithSampledFields` (never-shrink, declared-wins).
     * Best-effort + parallel — a sample failure (or an unentitled 403 family) leaves the declared set
     * untouched. Overrides `IntrospectSchema`, NOT `DiscoverFields` (that would recurse into
     * `DiscoverFieldsViaFetch`'s own fallback). Connector-agnostic: no Reply-specific field logic.
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

    // ── Sync-efficiency hooks (§7/§10 — each backed by a frozen-contract fact) ──

    /**
     * From every IO's Configuration.rateLimit: 100 requests/minute AND 3,000/hour, SHARED per API user
     * across all of that user's tools. 100/min ≈ 1.67/s; we publish 1.5/s with a small burst so the hourly
     * ceiling (0.83/s sustained) is approached conservatively rather than sprinting into a 429 wall. The
     * engine's AIMD bucket cuts on 429 (honoring Retry-After below) and ramps back slowly.
     */
    public override get RateLimitPolicy(): RateLimitPolicy | null {
        return {
            TokensPerSec: 1.5,
            Burst: 5,
            ThrottleBackoffFactor: 0.5,
            SuccessRampPerCall: 0.05,
            MinTokensPerSec: 0.25,
        };
    }

    /**
     * Reply.io returns `Retry-After` (integer SECONDS, minimum 1) on 429 — the vendor's own instruction, so
     * it is honored exactly rather than approximated with a local backoff curve.
     *
     * Two sources, in order: (1) headers carried ON the error, when the caller surfaced a rich error; (2) the
     * value captured at the wire boundary on the last 429, because the inherited read path throws a plain
     * `Error` with the headers already discarded. The captured value is consumed once and cleared, so it can
     * never be replayed against an unrelated later error.
     */
    public override ExtractRetryAfterMs(error: unknown): number | undefined {
        const fromHeaders = this.retryAfterFromHeaders(this.extractHeadersFromError(error));
        if (fromHeaders !== undefined) {
            this.pendingRetryAfterMs = null;
            return fromHeaders;
        }
        const captured = this.pendingRetryAfterMs;
        this.pendingRetryAfterMs = null;
        return captured ?? undefined;
    }

    /** Parses a `Retry-After` header (integer seconds per the vendor) into ms; undefined when absent/unparseable. */
    private retryAfterFromHeaders(headers: Record<string, string> | undefined): number | undefined {
        if (!headers) return undefined;
        const raw = headers['retry-after'] ?? headers['Retry-After'];
        if (raw == null) return undefined;
        const secs = Number(raw);
        return Number.isFinite(secs) && secs >= 0 ? Math.ceil(secs * 1000) : undefined;
    }

    /**
     * Deliberately LOW. The rate budget is per-user and shared, and the vendor's guidance is sequential /
     * low-concurrency access; parallelism here buys nothing but 429s against a 100/min ceiling.
     */
    public override get MaxConcurrencyHint(): number | null { return 2; }

    /**
     * Every object is no-watermark (FullPullHashDiff), so resume relies on the object's declared stable
     * ordering key (the extractor emitted `StableOrderingKey` per IO — usually `id`). Returns null when the
     * object declares none and has no single primary key.
     */
    public override StableOrderingKey(objectName: string): string | null {
        const obj = this.tryGetCachedObject(objectName);
        if (!obj) return null;
        const declared = obj.StableOrderingKey;
        if (declared && declared.trim().length > 0) return declared.trim();
        const pk = this.GetCachedFields(obj.ID).find(f => f.IsPrimaryKey);
        return pk?.Name ?? null;
    }

    // ── Abstract REST hooks ──────────────────────────────────────────

    /**
     * Resolves the Bearer credential from the linked Credential entity (preferred — `apiKey`, per the
     * "API Key" credential type schema) or the CompanyIntegration Configuration JSON (fallback). Cached for
     * the run. There is no token exchange, no signature and no expiry, so no auth-helper grant flow applies.
     */
    protected override async Authenticate(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<RESTAuthContext> {
        if (this.cachedAuth) return this.cachedAuth;
        const creds = await this.loadCredentials(companyIntegration, contextUser);
        if (!creds.ApiKey) {
            throw new Error(
                'Reply.io credential incomplete: attach a credential of type "API Key" carrying `apiKey`, ' +
                'or set the connection Configuration key "ApiKey".'
            );
        }
        this.cachedAuth = {
            // Composed by the SHARED auth-helper (`buildAPIKeyHeaderValue`), not a hand-built literal: it
            // enforces the non-empty-key and CR/LF header-injection guards centrally. Reply's key is a static
            // opaque bearer token — there is no token exchange, signature or refresh, so no crypto is involved
            // and no OAuth grant helper applies.
            AuthHeader: buildAPIKeyHeaderValue({
                HeaderName: 'Authorization',
                ApiKey: creds.ApiKey,
                ValuePrefix: 'Bearer',
            }),
            BaseURLOverride: this.resolveBaseURLOverride(companyIntegration) ?? undefined,
        };
        return this.cachedAuth;
    }

    /** Static header set — the Bearer value is composed once in Authenticate. */
    protected override BuildHeaders(auth: RESTAuthContext): Record<string, string> {
        return {
            'Authorization': (auth as ReplyAuthContext).AuthHeader,
            'Content-Type': 'application/json',
            'Accept': 'application/json, application/problem+json',
        };
    }

    /**
     * HTTP transport (fetch). Owns the wire boundary; test subclasses override this to capture requests.
     *
     * CRITICAL: a Reply.io 401 is documented to carry an EMPTY BODY (the scheme is signalled by the
     * `WWW-Authenticate` header). Parsing is therefore guarded on a non-empty payload — `JSON.parse('')`
     * on the most common failure path would crash the connector before it could report the auth failure.
     * Any non-2xx is recorded (status + parsed problem) so FetchChanges can explain an empty result.
     */
    protected override async MakeHTTPRequest(
        _auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown
    ): Promise<RESTResponse> {
        await this.PaceStrictFamily(url);
        const response = await fetch(url, {
            method,
            headers,
            body: body !== undefined ? JSON.stringify(body) : undefined,
        });
        const respHeaders: Record<string, string> = {};
        response.headers.forEach((v, k) => { respHeaders[k.toLowerCase()] = v; });
        const text = await response.text();
        let parsed: unknown = null;
        if (text.trim().length > 0) {
            try { parsed = JSON.parse(text); } catch { parsed = text; }
        }
        const result: RESTResponse = { Status: response.status, Body: parsed, Headers: respHeaders };
        this.recordProblem(result, url);
        return result;
    }

    /**
     * Extra self-throttle for the reporting / statistics families. The rate budget (100/min AND 3,000/hr) is
     * SHARED per API user across every tool that key drives, and these paths are the expensive ones — so this
     * connector paces them to roughly one request per second rather than letting a stats-heavy object sprint
     * the shared budget into a 429 wall that then stalls the whole sync.
     *
     * Deliberately NOT a retry and NOT a backoff: 429 handling stays with the engine's AIMD bucket +
     * `ExtractRetryAfterMs` (which honors the vendor's `Retry-After` exactly). This is pure pre-emptive
     * spacing, and it is a no-op for every ordinary collection read.
     */
    protected async PaceStrictFamily(url: string): Promise<void> {
        if (!REPLY_STRICT_PACED_URL_PATTERNS.some(re => re.test(url))) return;
        const now = this.NowMs();
        const waitMs = REPLY_STRICT_FAMILY_MIN_GAP_MS - (now - this.lastStrictFamilyRequestAt);
        if (this.lastStrictFamilyRequestAt > 0 && waitMs > 0) await this.Sleep(waitMs);
        this.lastStrictFamilyRequestAt = this.NowMs();
    }

    /** Clock seam — overridable so a test can assert pacing without real elapsed time. */
    protected NowMs(): number { return Date.now(); }

    /** Sleep seam — overridable so a test can assert pacing without actually waiting. */
    protected Sleep(ms: number): Promise<void> {
        return new Promise<void>(resolve => setTimeout(resolve, ms));
    }

    /**
     * Strips the Reply.io list envelope. Resolution order (deterministic — never "pick any array"):
     *   1. the object's declared ResponseDataKey, when it names an array;
     *   2. a bare array body;
     *   3. the vendor-wide `items` envelope key (documented on every paginated collection);
     *   4. a single non-enveloped object → a one-record array (get-one and the singleton doors such as
     *      `/v3/contacts/{id}/statuses`, `/v3/whoami`, `/v3/sequence-templates`).
     */
    protected override NormalizeResponse(rawBody: unknown, responseDataKey: string | null): Record<string, unknown>[] {
        if (rawBody == null) return [];
        if (Array.isArray(rawBody)) return rawBody as Record<string, unknown>[];
        if (typeof rawBody !== 'object') return [];
        const body = rawBody as Record<string, unknown>;
        if (responseDataKey) {
            const declared = body[responseDataKey];
            if (Array.isArray(declared)) return declared as Record<string, unknown>[];
        }
        const items = (body as ReplyListEnvelope).items;
        if (Array.isArray(items)) return items as Record<string, unknown>[];
        return [body];
    }

    /**
     * Reply.io pagination is OFFSET ONLY. Continuation is the envelope's explicit `hasMore` boolean; when a
     * response omits it (the non-enveloped singleton doors) a full page is treated as "more may follow" and
     * a short page ends the walk. Cursor / page-number never occur in this vendor's surface.
     */
    protected override ExtractPaginationInfo(
        rawBody: unknown,
        paginationType: PaginationType,
        _currentPage: number,
        currentOffset: number,
        pageSize: number
    ): PaginationState {
        if (paginationType !== 'Offset' || !rawBody || typeof rawBody !== 'object') return { HasMore: false };
        const env = rawBody as ReplyListEnvelope;
        const count = Array.isArray(env.items) ? env.items.length : (Array.isArray(rawBody) ? rawBody.length : 0);
        const hasMore = typeof env.hasMore === 'boolean'
            ? env.hasMore
            : (pageSize > 0 && count >= pageSize);
        return { HasMore: hasMore, NextOffset: currentOffset + count };
    }

    /**
     * Reply.io offset params are `top` (page size) + `skip` (offset) — NOT the base defaults `limit`/`offset`.
     * The page size is clamped to the endpoint's DECLARED ceiling (IO.DefaultPageSize, probe-confirmed) and
     * to the vendor-wide documented maximum, so a batch-capacity request can never exceed what the endpoint
     * accepts (an over-large `top` is a 400 `*.invalidPagination`, not a silent truncation).
     */
    protected override BuildPaginatedURL(
        basePath: string,
        obj: MJIntegrationObjectEntity,
        _page: number,
        offset: number,
        _cursor?: string,
        effectivePageSize?: number
    ): string {
        if (obj.PaginationType !== 'Offset') return basePath;
        const ceiling = Math.min(obj.DefaultPageSize ?? REPLY_FALLBACK_TOP, REPLY_MAX_TOP);
        const top = Math.max(1, Math.min(effectivePageSize ?? ceiling, ceiling));
        const separator = basePath.includes('?') ? '&' : '?';
        return `${basePath}${separator}top=${top}&skip=${offset}`;
    }

    /** Base host for every request. A Configuration override (sandbox / spec-mock) wins over the vendor host. */
    protected override GetBaseURL(_companyIntegration: MJCompanyIntegrationEntity, auth: RESTAuthContext): string {
        const ctx = auth as ReplyAuthContext;
        if (ctx.BaseURLOverride) return ctx.BaseURLOverride.replace(/\/+$/, '');
        return REPLY_DEFAULT_BASE_URL;
    }

    // ── FetchChanges (embedded projection + cross-page dedupe + entitlement reporting) ──

    /**
     * OVERRIDDEN for three Reply-specific read concerns; everything else delegates to the inherited base
     * GET path (which uses the pagination overrides above and resolves template vars per-parent).
     *
     *  1. EMBEDDED-ARRAY PROJECTION — 17 of the 84 IOs have no endpoint of their own: their records live
     *     inside another object's payload, declared as `Configuration.resourceKey = "<Owner>.<key>[]"`
     *     (e.g. `Contact.customFields[]`, `HolidayCalendar.holidays[]`, `SequenceStep.variants[]`). For those
     *     we fetch the OWNER through the inherited path — so the owner's own pagination, parent-iteration and
     *     resume state all apply — then descend the declared key to emit the leaf records.
     *  2. CROSS-PAGE PRIMARY-KEY DEDUPE — offset paging over a mutating collection shifts the window, so the
     *     same record can appear on two pages of one walk. Records are de-duplicated by ExternalID.
     *  3. ENTITLEMENT REPORTING — a 403 means "reachable but not entitled" (missing scope / plan feature).
     *     The base skips 403 objects with a console.warn; we additionally attach a structured FetchWarning so
     *     an unentitled family is REPORTED, not silently dropped and not counted as a pass.
     */
    public override async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
        const obj = this.GetCachedObject(ctx.CompanyIntegration.IntegrationID, ctx.ObjectName);
        const projection = this.resolveEmbeddedProjection(obj);
        this.lastProblem = null;

        // 4. PER-PAGE CHECKPOINTING — see ClampBatchToOnePage. The walked object is the CONTAINER for a
        //    projection (its endpoint is what actually pages), else the object itself.
        const walked = projection ? this.resolveContainerObject(obj, projection) : obj;
        const pagedCtx = this.ClampBatchToOnePage(ctx, walked);

        const result = projection
            ? await this.fetchProjected(obj, projection, pagedCtx)
            : await super.FetchChanges(pagedCtx);

        const deduped = this.dedupeByExternalID(result.Records);
        const warnings = this.collectWarnings(obj, deduped.length, result.Warnings);
        return { ...result, Records: deduped, Warnings: warnings };
    }

    /**
     * Caps a fetch call to ONE endpoint page so the engine checkpoints after every page.
     *
     * The inherited pagination loop keeps requesting pages until it has accumulated `BatchSize` records,
     * and only THEN returns `NextOffset` for the engine to persist. With Reply.io's 3,000-requests/hour
     * ceiling a first full sync of a large tenant runs for HOURS, and an interruption anywhere inside that
     * loop discards every page fetched since the last engine checkpoint — pages that cost real, shared,
     * per-user quota that cannot be bought back. Clamping the batch to the endpoint's own page ceiling
     * makes the loop return after a single request, so `NextOffset` is persisted per PAGE and a resumed
     * sync re-requests at most one page. Cost: nothing — the same number of HTTP requests either way.
     *
     * No-op for non-offset / non-paginated objects (single-shot doors) and when the engine already asked
     * for a batch at or below the page ceiling.
     */
    protected ClampBatchToOnePage(ctx: FetchContext, walked: MJIntegrationObjectEntity): FetchContext {
        if (!walked.SupportsPagination || walked.PaginationType !== 'Offset') return ctx;
        const ceiling = Math.min(walked.DefaultPageSize ?? REPLY_FALLBACK_TOP, REPLY_MAX_TOP);
        const batch = ctx.BatchSize > 0 ? Math.min(ctx.BatchSize, ceiling) : ceiling;
        return batch === ctx.BatchSize ? ctx : { ...ctx, BatchSize: batch };
    }

    /**
     * Reads the embedded-projection declaration off an IO. The extractor writes
     * `Configuration.resourceKey = "<OwnerObjectName>.<nestedKey>[]"` for an object that is an array nested
     * inside another payload, and a plain slash-path (`"contacts/statuses"`) for one that has its own
     * endpoint — so the two cases are distinguished by DECLARED metadata, never by guessing at the URL.
     */
    private resolveEmbeddedProjection(obj: MJIntegrationObjectEntity): EmbeddedProjection | null {
        const resourceKey = this.readConfigString(obj, 'resourceKey');
        if (!resourceKey) return null;
        // The OWNER segment may be an object Name (`Contact`, `HolidayCalendar`) OR a hyphenated resource
        // slug when the projection has no owning IO row (`sequence-templates.globalTemplates[]`). Both are
        // declared forms the extractor emits, so the owner charset must admit `-`; a `[A-Za-z0-9_]+`-only
        // owner silently rejected the slug form and sent those objects down the ordinary endpoint path,
        // where the container payload itself was emitted as a single record instead of its nested array.
        // The NESTED-KEY segment stays strict (a JSON property name) so an ordinary slash-path resourceKey
        // such as "contacts/statuses" can never be misread as a projection.
        const m = /^([A-Za-z0-9_-]+)\.([A-Za-z0-9_]+)\[\]$/.exec(resourceKey);
        if (!m) return null;
        return { OwnerName: m[1], NestedKey: m[2] };
    }

    /**
     * Fetches an embedded-projection object: pull the CONTAINER records through the inherited fetch path,
     * then descend the declared nested key on each one to emit the leaf records.
     *
     * The container is the OWNER object named in `resourceKey` when that object exists and shares this
     * object's APIPath (so the owner's declared pagination/parent-iteration governs the walk); otherwise —
     * e.g. the sequence-template groups, whose owner is declared as `null` — the projection's own IO row is
     * the container. Both cases read only DECLARED metadata.
     */
    private async fetchProjected(
        obj: MJIntegrationObjectEntity,
        projection: EmbeddedProjection,
        ctx: FetchContext
    ): Promise<FetchBatchResult> {
        const container = this.resolveContainerObject(obj, projection);
        const containerCtx: FetchContext = { ...ctx, ObjectName: container.Name };
        const containerResult = await super.FetchChanges(containerCtx);

        const fields = this.GetCachedFields(obj.ID);
        const declaredNames = new Set(fields.map(f => f.Name));
        const pkFieldNames = this.pkFieldNames(fields);
        const leaves: ExternalRecord[] = [];

        for (const containerRecord of containerResult.Records) {
            const nested = containerRecord.Fields[projection.NestedKey];
            if (!Array.isArray(nested)) continue;
            for (const raw of nested) {
                if (!raw || typeof raw !== 'object' || Array.isArray(raw)) continue;
                const leaf = this.inheritDeclaredOwnerKeys(
                    { ...(raw as Record<string, unknown>) },
                    containerRecord.Fields,
                    declaredNames
                );
                const transformed = this.applyTransformPreservingKeys(leaf, obj, fields);
                leaves.push(this.buildExternalRecord(transformed, obj.Name, pkFieldNames));
            }
        }

        return {
            Records: leaves,
            HasMore: containerResult.HasMore,
            NextOffset: containerResult.NextOffset,
            NextPage: containerResult.NextPage,
            NextCursor: containerResult.NextCursor,
            NextAfterKeyValue: containerResult.NextAfterKeyValue,
            Warnings: containerResult.Warnings,
        };
    }

    /** The IO whose endpoint actually returns the container payload for a projection (owner, else self). */
    private resolveContainerObject(obj: MJIntegrationObjectEntity, projection: EmbeddedProjection): MJIntegrationObjectEntity {
        const owner = this.tryGetCachedObject(projection.OwnerName);
        if (owner && owner.APIPath === obj.APIPath) return owner;
        return obj;
    }

    /**
     * Copies owner-record keys down onto a leaf record — but ONLY keys the leaf object DECLARES as its own
     * fields and does not already carry. This links a nested row back to its owner (the parent id the base
     * tagged onto the container) without inventing columns: an undeclared owner key is never copied.
     */
    private inheritDeclaredOwnerKeys(
        leaf: Record<string, unknown>,
        ownerFields: Record<string, unknown>,
        declaredNames: Set<string>
    ): Record<string, unknown> {
        for (const name of declaredNames) {
            if (name in leaf) continue;
            const v = ownerFields[name];
            if (v === undefined || v === null || typeof v === 'object') continue;
            leaf[name] = v;
        }
        return leaf;
    }

    /**
     * Drops repeats of the same primary key WITHIN one fetch batch — which is exactly "across pages", since
     * the inherited loop accumulates every page of the walk into one batch. Records with no resolvable
     * ExternalID are passed through untouched (they cannot be compared, and silently collapsing them would
     * lose data). Across BATCHES the engine's content-hash idempotency makes a repeat a no-op update.
     */
    private dedupeByExternalID(records: ExternalRecord[]): ExternalRecord[] {
        const seen = new Set<string>();
        const out: ExternalRecord[] = [];
        for (const r of records) {
            if (!r.ExternalID) { out.push(r); continue; }
            if (seen.has(r.ExternalID)) continue;
            seen.add(r.ExternalID);
            out.push(r);
        }
        return out;
    }

    /**
     * Turns an observed 403/401 into a structured warning when the fetch produced nothing, so an unentitled
     * or unauthenticated family is REPORTED rather than read as "this object is legitimately empty".
     * 403 is explicitly NOT an invalid credential and NOT a connector defect.
     */
    private collectWarnings(
        obj: MJIntegrationObjectEntity,
        recordCount: number,
        existing?: FetchWarning[]
    ): FetchWarning[] | undefined {
        const warnings = existing ? [...existing] : [];
        const parentIssue = this.parentDeclarationWarning(obj);
        if (parentIssue) warnings.push(parentIssue);
        const problem = this.lastProblem;
        // 403 is the ONLY non-2xx that reaches here: the base validates every other status and throws,
        // whereas a 403 is swallowed into an empty result — exactly the silent drop this warning prevents.
        if (problem && problem.Status === 403 && recordCount === 0) {
            warnings.push({
                Code: 'NOT_ENTITLED',
                Message:
                    `"${obj.Name}": Reply.io returned HTTP 403 — the path is reachable but this tenant/API key is ` +
                    `NOT ENTITLED to it (missing scope, or the feature is not on the plan). This is neither an ` +
                    `invalid credential nor a connector defect; grant the scope or leave the object inactive. ` +
                    `Vendor code: ${problem.Problem?.code ?? '(none)'}.`,
                Data: { object: obj.Name, status: 403, code: problem.Problem?.code, detail: problem.Problem?.detail },
            });
        }
        return warnings.length > 0 ? warnings : undefined;
    }

    /**
     * Diagnoses a parent-iterated object whose DECLARED parent cannot actually yield the ids its path
     * needs, and reports it as a structured warning.
     *
     * This does NOT repair the declaration — a wrong `Configuration.parentObjectName` is an upstream
     * metadata defect that belongs in the extractor's amendment loop, and guessing a replacement here is
     * exactly the silent cross-owner corruption the base class refuses to commit. What it prevents is the
     * WORSE outcome: such an object fetches zero rows (the parent yields no usable ids) and, with no
     * warning attached, that empty result is indistinguishable from "this object is legitimately empty" —
     * a green sync that quietly carries nothing.
     *
     * Two detectable defects, both provable from metadata alone:
     *  - a MULTI-var path (`/v3/sequences/{sequence_id}/contacts/{contact_id}/preview`) with only the
     *    single-valued `parentObjectName` — both vars would resolve to the same parent, which the base
     *    rejects as a dependency cycle;
     *  - a declared parent that is missing, or that declares NO primary key (e.g. an embedded projection
     *    such as `ContactCustomField`, whose fields are `key`/`value`) — there is no id column to iterate.
     */
    private parentDeclarationWarning(obj: MJIntegrationObjectEntity): FetchWarning | null {
        const vars = obj.APIPath.match(/\{\w+\}/g);
        if (!vars || vars.length === 0) return null;

        if (vars.length > 1 && !this.readConfigString(obj, 'parentObjectNames')) {
            const hasMap = this.hasConfigObject(obj, 'parentObjectNames');
            if (!hasMap) {
                return {
                    Code: 'PARENT_DECLARATION_INCOMPLETE',
                    Message:
                        `"${obj.Name}": APIPath "${obj.APIPath}" has ${vars.length} template variables but the ` +
                        `metadata declares only the single-valued Configuration.parentObjectName. Each variable ` +
                        `needs its own entry in Configuration.parentObjectNames; without it every variable resolves ` +
                        `to the same parent and the fetch yields nothing. This is a METADATA gap, not a ` +
                        `connector defect — re-run the extractor for this object.`,
                    Data: { object: obj.Name, apiPath: obj.APIPath, templateVars: vars },
                };
            }
        }

        const parentName = this.readConfigString(obj, 'parentObjectName');
        if (!parentName) return null;
        const parent = this.tryGetCachedObject(parentName);
        if (!parent) {
            return {
                Code: 'PARENT_DECLARATION_INVALID',
                Message:
                    `"${obj.Name}": Configuration.parentObjectName="${parentName}" names no active ` +
                    `IntegrationObject, so the {${vars[0].slice(1, -1)}} variable cannot be iterated. ` +
                    `METADATA gap — re-run the extractor for this object.`,
                Data: { object: obj.Name, declaredParent: parentName },
            };
        }
        const parentHasPK = this.GetCachedFields(parent.ID).some(f => f.IsPrimaryKey);
        if (!parentHasPK) {
            return {
                Code: 'PARENT_DECLARATION_INVALID',
                Message:
                    `"${obj.Name}": Configuration.parentObjectName="${parentName}" resolves to an object that ` +
                    `declares NO primary key, so it can supply no ids for {${vars[0].slice(1, -1)}} and this ` +
                    `object will fetch nothing. METADATA gap — re-run the extractor for this object.`,
                Data: { object: obj.Name, declaredParent: parentName },
            };
        }
        return null;
    }

    /** True when the IO's Configuration carries KEY as a non-empty object (used for the per-var parent map). */
    private hasConfigObject(obj: MJIntegrationObjectEntity, key: string): boolean {
        if (!obj.Configuration) return false;
        try {
            const cfg = JSON.parse(obj.Configuration) as Record<string, unknown>;
            const v = cfg[key];
            return !!v && typeof v === 'object' && !Array.isArray(v) && Object.keys(v).length > 0;
        } catch {
            return false;
        }
    }

    // ── CRUD ─────────────────────────────────────────────────────────
    //
    // The per-operation metadata columns (Create*/Update*/Delete*) drive all three verbs — this class does
    // NOT re-implement per-object write logic. The three overrides below exist for exactly two documented
    // vendor idiosyncrasies that the generic dispatch cannot express, and they route back through the base's
    // own BuildOperationBody / ExtractIDFromResponse / BuildCreatedResult helpers:
    //
    //   (a) NON-ATOMIC PARTIAL SUCCESS. Reply.io answers its non-atomic write endpoints with HTTP 200 and a
    //       dictionary of ONLY the failed items. Trusting the status code (or a `Status === 'Success'` field,
    //       which this vendor does not even emit) reports a silent failure as a success. Every write outcome
    //       is therefore asserted from the per-item dictionary.
    //   (b) NAMED / NESTED PATH VARS. Write paths carry parent segments (`/v3/sequences/{id}/steps/{step_id}`,
    //       `/v3/ai-sdr/knowledge-bases/{knowledge_base_id}/documents/{document_id}`); the base substitutes
    //       only `{id}`. See the SubstituteIDInPath override.
    //
    // NO write is ever auto-retried here. A send / enrollment / approval / start that times out may well have
    // taken effect, so a blind retry can double-send; recovery must begin with a verifying READ (GetRecord),
    // which is the engine's decision, not this connector's.

    /** Create — generic per-operation dispatch + parent-var substitution + partial-success assertion. */
    public override async CreateRecord(ctx: CreateRecordContext): Promise<CRUDResult> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        if (!obj.CreateAPIPath || !obj.CreateMethod) return super.CreateRecord(ctx);

        const path = this.substitutePathVarsFromAttributes(obj.CreateAPIPath, ctx.Attributes);
        const body = this.BuildOperationBody(ctx.Attributes, obj.CreateBodyShape, obj.CreateBodyKey);
        const response = await this.executeWrite(ci, ctx.ContextUser as UserInfo, path, obj.CreateMethod, body);

        const failure = this.assertWriteOutcome(response, 'create', ctx.ObjectName);
        if (failure) return failure;
        return this.BuildCreatedResult(
            this.ExtractIDFromResponse(response, obj.CreateIDLocation),
            response.Status,
            ctx.ObjectName
        );
    }

    /** Update — generic per-operation dispatch (PUT or PATCH per IO) + partial-success assertion. */
    public override async UpdateRecord(ctx: UpdateRecordContext): Promise<CRUDResult> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        if (!obj.UpdateAPIPath || !obj.UpdateMethod) return super.UpdateRecord(ctx);

        const path = this.SubstituteIDInPath(obj.UpdateAPIPath, ctx.ExternalID, obj.UpdateIDLocation);
        const body = this.BuildOperationBody(ctx.Attributes, obj.UpdateBodyShape, obj.UpdateBodyKey);
        const response = await this.executeWrite(ci, ctx.ContextUser as UserInfo, path, obj.UpdateMethod, body);

        const failure = this.assertWriteOutcome(response, 'update', ctx.ObjectName);
        if (failure) return failure;
        return { Success: true, StatusCode: response.Status, ExternalID: ctx.ExternalID };
    }

    /** Delete — generic per-operation dispatch (hard delete; the vendor has no universal tombstone). */
    public override async DeleteRecord(ctx: DeleteRecordContext): Promise<CRUDResult> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        if (!obj.DeleteAPIPath || !obj.DeleteMethod) return super.DeleteRecord(ctx);

        const path = this.SubstituteIDInPath(obj.DeleteAPIPath, ctx.ExternalID, obj.DeleteIDLocation);
        const response = await this.executeWrite(ci, ctx.ContextUser as UserInfo, path, obj.DeleteMethod, undefined);

        const failure = this.assertWriteOutcome(response, 'delete', ctx.ObjectName);
        if (failure) return failure;
        return { Success: true, StatusCode: response.Status, ExternalID: ctx.ExternalID };
    }

    /** Authenticates, resolves the URL and fires ONE write request. No retry — see the CRUD section note. */
    private async executeWrite(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
        path: string,
        method: string,
        body: unknown
    ): Promise<RESTResponse> {
        const auth = await this.Authenticate(companyIntegration, contextUser);
        const baseURL = this.GetBaseURL(companyIntegration, auth);
        const headers = this.BuildHeaders(auth);
        return this.MakeHTTPRequest(auth, this.joinURL(baseURL, path), method, headers, body);
    }

    /**
     * Asserts a write actually happened. Returns a failure CRUDResult, or null when the write succeeded.
     *
     * Order matters: a non-2xx is a failure classified off the problem CODE; a 2xx is only a success once the
     * body has been checked for the non-atomic per-item failure dictionary. HTTP 200 alone proves the request
     * was ACCEPTED, not that the item was PROCESSED — the two are different on this vendor.
     */
    private assertWriteOutcome(response: RESTResponse, verb: string, objectName: string): CRUDResult | null {
        if (response.Status < 200 || response.Status >= 300) {
            const problem = this.parseProblem(response.Body);
            return {
                Success: false,
                StatusCode: response.Status,
                ErrorMessage: this.describeProblem(response.Status, problem, `${verb} ${objectName}`),
            };
        }
        const notProcessed = this.parseNotProcessed(response.Body);
        if (notProcessed && notProcessed.size > 0) {
            const detail = [...notProcessed.entries()]
                .map(([id, item]) => `${id}: ${item.error ?? 'unknown'}${item.errorDetails ? ` (${item.errorDetails})` : ''}`)
                .join('; ');
            return {
                Success: false,
                StatusCode: response.Status,
                ErrorMessage:
                    `Reply.io ${verb} on "${objectName}" returned HTTP ${response.Status} but the non-atomic result ` +
                    `reported ${notProcessed.size} item(s) NOT PROCESSED — ${detail}. ` +
                    `Do NOT retry blindly: verify with a read first.`,
            };
        }
        return null;
    }

    /**
     * Parses a non-atomic (bulk) response body: a dictionary keyed by item id whose values are
     * `{ error, errorDetails }` — ONLY failed items appear, and `{}` means everything succeeded. Returns null
     * when the body is not that shape (an ordinary single-record response), so this check costs nothing on
     * the normal path and can never misread a created record as a failure.
     */
    public parseNotProcessed(body: unknown): Map<string, ReplyNotProcessedItem> | null {
        if (!body || typeof body !== 'object' || Array.isArray(body)) return null;
        const entries = Object.entries(body as Record<string, unknown>);
        if (entries.length === 0) return new Map();     // `{}` — the documented all-succeeded signal
        const out = new Map<string, ReplyNotProcessedItem>();
        for (const [key, value] of entries) {
            if (!value || typeof value !== 'object' || Array.isArray(value)) return null;
            const v = value as Record<string, unknown>;
            if (typeof v.error !== 'string') return null;  // not a NotProcessedItemResult → not a bulk body
            out.set(key, {
                error: v.error,
                errorDetails: typeof v.errorDetails === 'string' ? v.errorDetails : null,
            });
        }
        return out;
    }

    /**
     * OVERRIDDEN so the generic Update/Delete/Get path can template Reply's NAMED and NESTED path vars
     * (`{step_id}`, `{variant_id}`, `{knowledge_base_id}`, `{document_id}`, `{tagId}`) — the base substitutes
     * only `{id}`/`{ExternalID}`. A single-var path takes the whole ExternalID; a multi-var (nested) path
     * takes the composite `parent|child` ExternalID split in path order.
     */
    protected override SubstituteIDInPath(path: string, externalID: string, idLocation: string | null): string {
        if (idLocation && idLocation !== 'path') return path;
        const vars = path.match(/\{\w+\}/g);
        if (!vars || vars.length === 0) return path;
        if (vars.length === 1) return path.replace(vars[0], encodeURIComponent(externalID));
        const parts = externalID.split('|');
        let out = path;
        vars.forEach((v, i) => {
            const val = parts[i] ?? parts[parts.length - 1] ?? externalID;
            out = out.replace(v, encodeURIComponent(val));
        });
        return out;
    }

    /** Fills a create path's PARENT template vars from the record's own attributes (nested creates). */
    private substitutePathVarsFromAttributes(path: string, attributes: Record<string, unknown>): string {
        return path.replace(/\{(\w+)\}/g, (match, name: string) => {
            const v = attributes[name];
            return v != null && String(v).length > 0 ? encodeURIComponent(String(v)) : match;
        });
    }

    // ── Error classification (RFC 9457, code-driven) ─────────────────

    /**
     * OVERRIDDEN for the RFC 9457 `application/problem+json` envelope. Never assumes a body exists — a
     * Reply.io 401 carries none. The message leads with the STABLE machine `code` so the engine's classifier
     * and any human reader both key off the slug rather than the localized `detail`.
     */
    protected override ExtractErrorMessage(response: RESTResponse): string | undefined {
        const problem = this.parseProblem(response.Body);
        if (!problem && response.Status < 400) return undefined;
        return this.describeProblem(response.Status, problem, undefined);
    }

    /** Parses an RFC 9457 problem body; null for an empty/non-problem payload (401 has NO body). */
    public parseProblem(body: unknown): ReplyProblem | null {
        if (!body || typeof body !== 'object' || Array.isArray(body)) return null;
        const b = body as Record<string, unknown>;
        // A problem document is identified by its STABLE machine slug, or by the RFC's status+title/detail
        // pair. `title` alone is NOT sufficient — ordinary Reply records carry a `title` field (a contact's
        // job title), and treating one as a problem would misclassify a perfectly good record.
        const hasCode = typeof b.code === 'string';
        const hasStatusPair = typeof b.status === 'number' && (typeof b.title === 'string' || typeof b.detail === 'string');
        if (!hasCode && !hasStatusPair) return null;
        return {
            title: typeof b.title === 'string' ? b.title : undefined,
            status: typeof b.status === 'number' ? b.status : undefined,
            detail: typeof b.detail === 'string' ? b.detail : undefined,
            code: typeof b.code === 'string' ? b.code : undefined,
            errors: b.errors,
        };
    }

    /**
     * Maps a Reply.io response to a `SyncErrorCode` using the STABLE machine slug first and the HTTP status
     * as the fallback — never the human-readable `detail`, which is localized prose and free to change.
     *
     * 403 maps to CONFIGURATION_ERROR (an entitlement/scope gap the operator resolves), deliberately NOT to
     * an auth failure: the credential is valid, the tenant simply is not entitled to that surface.
     */
    public ClassifyProblem(status: number, problem: ReplyProblem | null): SyncErrorCode {
        const variant = problem?.code?.split('.')[1]?.toLowerCase();
        if (variant) {
            if (variant === 'invalidpagination' || variant === 'validationfailed' || variant === 'invalidinput') {
                return 'VALIDATION_ERROR';
            }
            if (variant === 'forbidden' || variant === 'featurenotavailable' || variant === 'readonly') {
                return 'CONFIGURATION_ERROR';
            }
            if (variant === 'duplicatename' || variant === 'alreadyexists') return 'DUPLICATE_KEY';
        }
        if (status === 429) return 'RATE_LIMIT_EXCEEDED';
        if (status === 401) return 'CONFIGURATION_ERROR';
        if (status === 403) return 'CONFIGURATION_ERROR';
        if (status === 400 || status === 422) return 'VALIDATION_ERROR';
        if (status === 409) return 'DUPLICATE_KEY';
        if (status === 408 || status === 504) return 'NETWORK_TIMEOUT';
        if (status >= 500) return 'CONNECTOR_ERROR';
        return 'CONNECTOR_ERROR';
    }

    /**
     * Renders a problem into a message that (a) leads with the machine slug, (b) states the classification,
     * and (c) carries wording the engine's message-based `ClassifyError` maps to the SAME SyncErrorCode —
     * so the code the connector determined survives the string boundary instead of being re-guessed.
     */
    private describeProblem(status: number, problem: ReplyProblem | null, context: string | undefined): string {
        const code = this.ClassifyProblem(status, problem);
        const hint = this.classifierHint(code);
        const where = context ? ` on ${context}` : '';
        const slug = problem?.code ? `code=${problem.code}` : 'code=(none — middleware problem)';
        const detail = problem?.detail ?? (status === 401 ? 'empty body (RFC 9457 401 carries none)' : 'no detail');
        const entitlement = status === 403
            ? ' NOTE: 403 means REACHABLE BUT NOT ENTITLED (missing scope / plan feature) — the credential is valid.'
            : '';
        return `Reply.io HTTP ${status}${where}: ${slug}; ${hint}; detail="${detail}".${entitlement}`;
    }

    /** A phrase the engine's message-based ClassifyError maps to the given code (keeps both paths in sync). */
    private classifierHint(code: SyncErrorCode): string {
        switch (code) {
            case 'RATE_LIMIT_EXCEEDED': return 'rate limit exceeded';
            case 'VALIDATION_ERROR': return 'validation failure';
            case 'DUPLICATE_KEY': return 'duplicate key';
            case 'NETWORK_TIMEOUT': return 'request timeout';
            case 'CONFIGURATION_ERROR': return 'configuration/entitlement problem';
            default: return 'connector error';
        }
    }

    /**
     * Records the last non-2xx seen on the wire so an empty fetch can be explained rather than guessed at,
     * and captures a 429's `Retry-After` before the inherited validator throws it away (see
     * {@link pendingRetryAfterMs}).
     */
    private recordProblem(response: RESTResponse, url: string): void {
        if (response.Status >= 200 && response.Status < 300) return;
        this.lastProblem = { Status: response.Status, URL: url, Problem: this.parseProblem(response.Body) };
        if (response.Status === 429) {
            this.pendingRetryAfterMs = this.retryAfterFromHeaders(response.Headers) ?? null;
        }
    }

    // ── Connection test ──────────────────────────────────────────────

    /**
     * Verifies the credential against `GET /v3/whoami` — documented `x-required-scope: none`, so ANY valid
     * key can call it and a failure there is unambiguous. 401 = bad/missing key (empty body by design);
     * 403 on this endpoint would still mean the key is valid but the account is restricted, so it is reported
     * as a NON-credential problem.
     */
    public override async TestConnection(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<ConnectionTestResult> {
        try {
            const auth = await this.Authenticate(companyIntegration, contextUser);
            const baseURL = this.GetBaseURL(companyIntegration, auth);
            const headers = this.BuildHeaders(auth);
            const response = await this.MakeHTTPRequest(auth, `${baseURL}${REPLY_WHOAMI_PATH}`, 'GET', headers);

            if (response.Status >= 200 && response.Status < 300) {
                const body = (response.Body && typeof response.Body === 'object')
                    ? response.Body as Record<string, unknown>
                    : {};
                const who = body.username != null ? ` (user ${String(body.username)}, team ${String(body.teamId ?? '?')})` : '';
                return { Success: true, Message: `Reply.io connection successful${who}.` };
            }
            if (response.Status === 401) {
                return {
                    Success: false,
                    Message: 'Reply.io authentication failed (HTTP 401) — the API key is missing, invalid or revoked. ' +
                        'The vendor returns an empty body on 401; check the key value itself.',
                };
            }
            if (response.Status === 403) {
                return {
                    Success: false,
                    Message: 'Reply.io returned HTTP 403 on /v3/whoami — the key is VALID but the account is not ' +
                        'entitled to this call. This is an entitlement/plan problem, not a bad credential.',
                };
            }
            return {
                Success: false,
                Message: this.describeProblem(response.Status, this.parseProblem(response.Body), 'TestConnection'),
            };
        } catch (err) {
            const msg = err instanceof Error ? err.message : String(err);
            return { Success: false, Message: `Reply.io connection test error: ${msg}` };
        }
    }

    // ── Credential loading ───────────────────────────────────────────

    /** Reads the API key from the linked Credential entity, falling back to the Configuration JSON. */
    private async loadCredentials(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<ReplyCredentials> {
        let creds: ReplyCredentials | null = null;
        if (companyIntegration.CredentialID) {
            creds = await this.loadFromCredentialEntity(companyIntegration.CredentialID, contextUser);
        }
        const configCreds = companyIntegration.Configuration
            ? this.parseCredentialJson(companyIntegration.Configuration)
            : null;
        if (!creds && !configCreds) {
            throw new Error(
                'No Reply.io credential found. Attach a credential of type "API Key" (field `apiKey`), ' +
                'or set the connection Configuration key "ApiKey".'
            );
        }
        return { ApiKey: creds?.ApiKey ?? configCreds?.ApiKey };
    }

    /** Loads a credential row and parses its Values JSON. */
    private async loadFromCredentialEntity(
        credentialID: string,
        contextUser: UserInfo,
        provider?: IMetadataProvider
    ): Promise<ReplyCredentials | null> {
        const md = provider ?? new Metadata();
        const credential = await md.GetEntityObject<MJCredentialEntity>('MJ: Credentials', contextUser);
        const loaded = await credential.Load(credentialID);
        if (!loaded || !credential.Values) return null;
        return this.parseCredentialJson(credential.Values);
    }

    /** Extracts the API key from a credential/config JSON string (tolerant of absent/invalid). */
    private parseCredentialJson(json: string): ReplyCredentials | null {
        try {
            const parsed = JSON.parse(json) as Record<string, unknown>;
            return { ApiKey: this.firstString(parsed, ['apiKey', 'ApiKey', 'apikey', 'api_key', 'token', 'Token']) };
        } catch {
            return null;
        }
    }

    /**
     * Reads an explicit base-URL override from the connection Configuration. Only an absolute http(s) URL is
     * honored, so a stray value cannot misroute a production tenant. Null (the normal case) → the vendor host.
     */
    private resolveBaseURLOverride(companyIntegration: MJCompanyIntegrationEntity): string | null {
        if (!companyIntegration.Configuration) return null;
        let parsed: Record<string, unknown>;
        try { parsed = JSON.parse(companyIntegration.Configuration) as Record<string, unknown>; } catch { return null; }
        const raw = this.firstString(parsed, ['BaseURL', 'BaseUrl', 'baseURL', 'baseUrl', 'APIBaseURL', 'ApiBaseURL', 'apiBaseUrl']);
        return raw && /^https?:\/\//i.test(raw.trim()) ? raw.trim() : null;
    }

    // ── Helpers ──────────────────────────────────────────────────────

    /** Joins a base URL and a path (mirrors the base's private BuildFullURL). */
    private joinURL(baseURL: string, apiPath: string): string {
        const base = baseURL.endsWith('/') ? baseURL.slice(0, -1) : baseURL;
        const path = apiPath.startsWith('/') ? apiPath : `/${apiPath}`;
        return `${base}${path}`;
    }

    /** PK field names in declared Sequence order; empty when the object declares none. */
    private pkFieldNames(fields: MJIntegrationObjectFieldEntity[]): string[] {
        return fields.filter(f => f.IsPrimaryKey).sort((a, b) => a.Sequence - b.Sequence).map(f => f.Name);
    }

    /**
     * Builds an ExternalRecord whose Fields carry the FULL source record (full-record pass-through — the
     * framework's custom-column capture diffs keys(Fields) against the active field maps, so a narrowed
     * literal would make custom columns permanently invisible). ExternalID is the composite of the declared
     * PK fields when all are present, else the vendor's universal `id`, else empty.
     */
    private buildExternalRecord(raw: Record<string, unknown>, objectType: string, pkFieldNames: string[]): ExternalRecord {
        const allPresent = pkFieldNames.length > 0 && pkFieldNames.every(n => raw[n] != null && String(raw[n]).length > 0);
        const externalID = allPresent
            ? pkFieldNames.map(n => String(raw[n])).join('|')
            : (raw.id != null ? String(raw.id) : '');
        return { ExternalID: externalID, ObjectType: objectType, Fields: raw };
    }

    /**
     * Gets an IO by NAME alone from the engine cache, without throwing (callers may run before the cache is
     * warm, and StableOrderingKey has no IntegrationID to hand). Protected so a test/mock subclass can
     * substitute fixture rows exactly as it does for GetCachedObject.
     */
    protected tryGetCachedObject(objectName: string): MJIntegrationObjectEntity | null {
        try {
            const integ = IntegrationEngineBase.Instance.GetIntegrationByName(this.IntegrationName);
            if (!integ) return null;
            return IntegrationEngineBase.Instance.GetIntegrationObject(integ.ID, objectName) ?? null;
        } catch {
            return null;
        }
    }

    /** Reads a trimmed string value from an IntegrationObject's Configuration JSON (tolerant of absent/invalid). */
    private readConfigString(obj: MJIntegrationObjectEntity, key: string): string | null {
        const raw = obj.Configuration;
        if (!raw) return null;
        try {
            const cfg = JSON.parse(raw) as Record<string, unknown>;
            const v = cfg[key];
            return typeof v === 'string' && v.trim().length > 0 ? v.trim() : null;
        } catch {
            return null;
        }
    }

    /** Returns the first present, non-empty string value among the given keys. */
    private firstString(obj: Record<string, unknown>, keys: string[]): string | undefined {
        for (const k of keys) {
            const v = obj[k];
            if (typeof v === 'string' && v.length > 0) return v;
        }
        return undefined;
    }

    /** Best-effort extraction of response headers from an error object (for ExtractRetryAfterMs). */
    private extractHeadersFromError(error: unknown): Record<string, string> | undefined {
        if (!error || typeof error !== 'object') return undefined;
        const e = error as Record<string, unknown>;
        const resp = (e.response as Record<string, unknown> | undefined) ?? e;
        const headers = (resp as Record<string, unknown>).headers ?? (resp as Record<string, unknown>).Headers;
        if (headers && typeof headers === 'object') return headers as Record<string, string>;
        return undefined;
    }
}
