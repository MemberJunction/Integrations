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
    buildBasicAuthHeaderValue,
    type RESTAuthContext,
    type RESTResponse,
    type PaginationState,
    type PaginationType,
    type ConnectionTestResult,
    type FetchContext,
    type FetchBatchResult,
    type CreateRecordContext,
    type UpdateRecordContext,
    type DeleteRecordContext,
    type CRUDResult,
    type SourceSchemaInfo,
} from '@memberjunction/integration-engine';
import { mergeDeclaredWithSampledFields } from '@memberjunction/connector-schema-merge';

// ─── Design note ────────────────────────────────────────────────────────
//
// This connector is PURE MECHANISM. The object/field catalog is NOT baked here — it lives in the Declared
// metadata (metadata/integrations/mailchimp/.mailchimp.integration.json), seeded from Mailchimp's
// credential-free OpenAPI spec + published docs (case-1 discovery). Discovery is INHERITED from
// BaseRESTIntegrationConnector: DiscoverObjects / DiscoverFields / IntrospectSchema read the persisted
// Declared metadata from the IntegrationEngineBase cache. There is NO hardcoded object list, NO field
// catalog, NO baked PK/FK/required/readonly constants in this file.
//
// What this class supplies (the Mailchimp Marketing API v3 protocol shape over REST/JSON):
//  - Auth: HTTP Basic where the userid is the literal `anystring` and the password is the API key (or an
//    OAuth2 access token) — `Authorization: Basic base64("anystring:{key}")`. Built via the auth-helper
//    (buildBasicAuthHeaderValue); NO inline base64/crypto. A long-lived credential, no refresh step.
//  - Tenancy: every request targets `https://{dc}.api.mailchimp.com/3.0/…`; the per-account data-center
//    prefix {dc} (e.g. `us15`) is read from the connection Configuration / credential, or parsed from the
//    `-<dc>` suffix on the API key — ZERO data center baked into this vendor-wide code.
//  - Pagination: uniform Offset pagination — `count` (≤1000) + `offset` — on every collection GET, with
//    continuation gated by the response's `total_items`.
//  - Envelope: each collection nests its records under a per-object data key (`members` / `campaigns` /
//    `stores` / …) alongside `total_items` + `_links`; NormalizeResponse strips it. A single-record GET
//    (no data key) is returned as a one-element array.
//  - Incremental: per-endpoint `since_<field>` ISO-8601 date filters (only where documented — 2 IOs:
//    list members `since_last_changed`, list segments `since_updated_at`), appended during a watermarked
//    fetch. Non-incremental objects fall back to the engine's content-hash idempotency.
//  - Write: generic per-operation CRUD (metadata-driven) for the write-capable top-level IOs. The one
//    documented idiosyncrasy — Mailchimp nested resources carry NAMED parent path vars
//    (`/lists/{list_id}/members/{subscriber_hash}`) the base's `{ID}`-only substitution can't express — is
//    handled by a named-var SubstituteIDInPath override plus attribute-sourced parent-var filling on the
//    nested Create/Update/Delete paths. All creates are flat-body with the id at the response root, so the
//    generic body/id extraction applies unchanged.

// ─── Types ──────────────────────────────────────────────────────────────

/** Parsed Mailchimp credential + tenant data center. */
interface MailchimpCredentials {
    /** Mailchimp API key (optionally suffixed `-<dc>`, e.g. `abc123-us15`) or OAuth2 access token. */
    ApiKey?: string;
    /** Explicit data-center prefix (e.g. `us15`). Overrides the suffix parsed from the key. */
    DataCenter?: string;
    /** Optional full base-URL override (sandbox / test / mock). Wins over the dc-derived host. */
    BaseURLOverride?: string;
    /** Auth transport: 'basic' (default) or 'bearer' (OAuth2 access token as a Bearer header). */
    Scheme?: 'basic' | 'bearer';
}

/** Extended auth context carrying the resolved Basic/Bearer header + the per-account data center. */
interface MailchimpAuthContext extends RESTAuthContext {
    /** Full `Authorization` header value (Basic or Bearer). */
    AuthHeader: string;
    /** Resolved data-center prefix used to build every request host (e.g. `us15`). */
    DataCenter: string;
    /** Optional explicit full base-URL override (sandbox/test/mock); wins over the dc host in GetBaseURL. */
    BaseURLOverride?: string;
}

/** Mailchimp collection envelope — records under a per-object key, alongside `total_items`. */
interface MailchimpCollectionEnvelope {
    total_items?: number;
    [key: string]: unknown;
}

/** OAuth2 metadata endpoint response (used only as a runtime dc-resolution fallback for bearer tokens). */
interface MailchimpOAuthMetadata {
    dc?: string;
    api_endpoint?: string;
}

// ─── Constants ────────────────────────────────────────────────────────────

/** OAuth2 metadata endpoint — resolves the data center for an OAuth access token when not otherwise known. */
const MAILCHIMP_OAUTH_METADATA_URL = 'https://login.mailchimp.com/oauth2/metadata';

/** Default page size (metadata DefaultPageSize normally supplies this; safe fallback well below the ceiling). */
const DEFAULT_PAGE_SIZE = 200;

/** Absolute per-page ceiling enforced by the Mailchimp API (`count` maxes at 1000). */
const MAX_PAGE_SIZE = 1000;

/** Basic-auth userid — Mailchimp ignores the userid, so any non-empty string works (`anystring` per docs). */
const BASIC_AUTH_USERID = 'anystring';

/** Max in-flight backoff retries for a 429 / 503 transient response. */
const DEFAULT_MAX_RETRIES = 5;

// ─── MailchimpConnector ─────────────────────────────────────────────────

/**
 * Mailchimp Marketing API (v3.0) connector — extends BaseRESTIntegrationConnector (REST/JSON over HTTP).
 *
 * Discovery, template-var read traversal (second-layer objects resolve their parent via
 * Configuration.parentObjectName — e.g. `lists/{list_id}/members` iterates over synced `lists`), and the
 * paginated GET loop are inherited. This class supplies only the Mailchimp-specific protocol surface:
 * Basic auth, per-account base URL, offset pagination, per-endpoint incremental date filtering, connection
 * testing, generic per-operation CRUD with named parent-var path templating, and the §7/§10
 * sync-efficiency hooks the frozen contract evidences.
 */
@RegisterClass(BaseIntegrationConnector, 'MailchimpConnector')
export class MailchimpConnector extends BaseRESTIntegrationConnector {

    /** Cached auth for the lifetime of a single sync run (Mailchimp API keys don't expire). */
    private cachedAuth: MailchimpAuthContext | null = null;

    /** Active watermark for the current FetchChanges call — exposed to AppendDefaultQueryParams. */
    private currentWatermark: string | null = null;

    // ── Identity (T1 three-way invariant) ────────────────────────────

    /** Verbatim `MJ: Integrations.Name`. Load-bearing: the T1 three-way name check compares this === metadata Name. */
    public override get IntegrationName(): string {
        return 'mailchimp';
    }

    // ── Capability getters (kept in lockstep with the per-op metadata columns) ──

    public override get SupportsCreate(): boolean { return true; }
    public override get SupportsUpdate(): boolean { return true; }
    public override get SupportsDelete(): boolean { return true; }

    /**
     * Discovery is NON-authoritative: DiscoverObjects / IntrospectSchema are cache-driven (they re-read
     * persisted ACTIVE Declared metadata, NOT a live full-gamut enumeration). Mailchimp exposes no complete
     * describe endpoint; per-list custom merge fields flow through the sample-union enrichment below plus the
     * framework's custom-column capture. Absence in a refresh proves nothing → never deactivate. Matches the
     * frozen contract (no complete-gamut describe endpoint).
     */
    public override get DiscoveryIsAuthoritative(): boolean {
        return false;
    }

    // ── Sync-efficiency hooks (§7/§10 — populated ONLY from evidenced frozen-contract facts) ──

    /**
     * Mailchimp's documented limit is a CONCURRENCY cap ("a limit of 10 simultaneous connections"), NOT a
     * documented requests-per-window token rate — and it emits no `X-RateLimit-*` / `Retry-After` headers.
     * So the evidenced hook is the concurrency ceiling (below); RateLimitPolicy stays null (no token rate to
     * fabricate — the engine derives a conservative rate) and ExtractRetryAfterMs stays default (nothing to
     * parse). The internal transport still honors an opportunistic Retry-After on a 429 as defensive backoff.
     */
    public override get MaxConcurrencyHint(): number | null { return 10; }

    // ── Sample-union field enrichment (MJ connector standard) ─────────

    /**
     * Sample-union enrichment: Declared metadata is spec-derived and misses a tenant's per-list custom merge
     * fields. After the base cache-driven introspection, we sample each object's live read shape via
     * `DiscoverFieldsViaFetch` and UNION it into the declared field set with `mergeDeclaredWithSampledFields`
     * (never-shrink, declared-wins, capacities widened). Best-effort + parallel; a sample failure leaves the
     * declared set untouched. We override `IntrospectSchema` (NOT `DiscoverFields` — that would recurse into
     * `DiscoverFieldsViaFetch`'s own fallback). Connector-agnostic: no Mailchimp-specific field logic.
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

    // ── TestConnection ────────────────────────────────────────────────

    /** Pings the Mailchimp API root (`/ping`) to verify connectivity + authentication (read-only). */
    public async TestConnection(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<ConnectionTestResult> {
        try {
            const auth = await this.Authenticate(companyIntegration, contextUser);
            const url = `${this.GetBaseURL(companyIntegration, auth)}/ping`;
            const response = await this.MakeHTTPRequest(auth, url, 'GET', this.BuildHeaders(auth));
            if (response.Status >= 200 && response.Status < 300) {
                const body = response.Body as { health_status?: string } | null;
                return {
                    Success: true,
                    Message: `Connected to Mailchimp (${auth.DataCenter}): ${body?.health_status ?? 'OK'}`,
                    ServerVersion: 'Mailchimp Marketing API v3.0',
                };
            }
            if (response.Status === 401 || response.Status === 403) {
                return { Success: false, Message: `Mailchimp authentication failed (HTTP ${response.Status}).` };
            }
            return { Success: false, Message: `Mailchimp /ping returned HTTP ${response.Status}.` };
        } catch (err: unknown) {
            return { Success: false, Message: `Connection failed: ${err instanceof Error ? err.message : String(err)}` };
        }
    }

    // ── FetchChanges override (watermark exposure only) ───────────────

    /**
     * Overridden ONLY to expose the active watermark to AppendDefaultQueryParams (which appends the
     * per-endpoint `since_<field>` incremental filter). All read traversal — flat, offset-paginated, and
     * per-parent template-var — is delegated to the inherited base implementation.
     */
    public override async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
        this.currentWatermark = ctx.WatermarkValue ?? null;
        try {
            return await super.FetchChanges(ctx);
        } finally {
            this.currentWatermark = null;
        }
    }

    // ── Abstract REST hooks ───────────────────────────────────────────

    /** Resolves credentials + data center once per run and pre-builds the Authorization header via the helper. */
    protected override async Authenticate(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<MailchimpAuthContext> {
        if (this.cachedAuth) return this.cachedAuth;
        const creds = await this.loadCredentials(companyIntegration, contextUser);
        if (!creds.ApiKey) {
            throw new Error('Mailchimp connector: no API key found on the Credential or CompanyIntegration Configuration.');
        }
        const dataCenter = await this.resolveDataCenter(creds);
        const authHeader = creds.Scheme === 'bearer'
            ? `Bearer ${creds.ApiKey}`
            : buildBasicAuthHeaderValue({ Username: BASIC_AUTH_USERID, Password: creds.ApiKey });
        this.cachedAuth = {
            AuthHeader: authHeader,
            DataCenter: dataCenter,
            BaseURLOverride: creds.BaseURLOverride,
        };
        return this.cachedAuth;
    }

    /** Static request headers; the Authorization value was built once in Authenticate. */
    protected override BuildHeaders(auth: RESTAuthContext): Record<string, string> {
        return {
            'Authorization': (auth as MailchimpAuthContext).AuthHeader,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        };
    }

    /**
     * HTTP transport (fetch), with bounded 429/503 backoff. Owns the wire boundary; test subclasses override
     * this to capture the outbound request and return canned responses.
     */
    protected override async MakeHTTPRequest(
        auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown,
    ): Promise<RESTResponse> {
        for (let attempt = 0; attempt <= DEFAULT_MAX_RETRIES; attempt++) {
            const response = await fetch(url, {
                method,
                headers,
                body: body !== undefined && body !== null ? JSON.stringify(body) : undefined,
            });
            if ((response.status === 429 || response.status === 503) && attempt < DEFAULT_MAX_RETRIES) {
                await this.sleep(this.computeBackoffMs(response, attempt));
                continue;
            }
            const respHeaders: Record<string, string> = {};
            response.headers.forEach((v, k) => { respHeaders[k.toLowerCase()] = v; });
            const text = await response.text();
            let parsed: unknown = null;
            if (text.length > 0) {
                try { parsed = JSON.parse(text); } catch { parsed = text; }
            }
            return { Status: response.status, Body: parsed, Headers: respHeaders };
        }
        throw new Error(`Mailchimp request failed after ${DEFAULT_MAX_RETRIES} retries: ${method} ${url}`);
    }

    /**
     * Strips the Mailchimp collection envelope to the per-object record array
     * (`{ members: [...], total_items }` → ResponseDataKey='members'). A single-record GET (no data key, or
     * the key absent) is returned as a one-element array. A bare array body passes through unchanged.
     */
    protected override NormalizeResponse(rawBody: unknown, responseDataKey: string | null): Record<string, unknown>[] {
        if (rawBody == null) return [];
        if (Array.isArray(rawBody)) return rawBody as Record<string, unknown>[];
        if (typeof rawBody !== 'object') return [];
        const body = rawBody as Record<string, unknown>;
        if (responseDataKey) {
            const arr = body[responseDataKey];
            if (Array.isArray(arr)) return arr as Record<string, unknown>[];
        }
        // Single-record / already-unwrapped object (or an empty/mismatched data key).
        return [body];
    }

    /**
     * Offset pagination: continue while `offset + fetched < total_items` (when the envelope reports a total),
     * else while a full page came back. The base loop advances `offset` by the fetched count.
     *
     * Mailchimp's collection pagination is UNIFORMLY count/offset with a `total_items` count across every
     * list endpoint — including the single IO the frozen contract classifies `Cursor`
     * (`audiences/{audience_id}/contacts`), which returns the identical `{ <key>: [...], total_items }`
     * envelope over the same `count`/`offset` params. So Offset AND Cursor advance by offset+fetched here;
     * only `None` (and unknown types) are single-page. Treating the lone Cursor IO via the same mechanism
     * prevents a silent one-page truncation (the endpoint could otherwise drop everything past page 1).
     * Flagged RequiresLiveVerification in CODE_REPORT — the reality probe could not fill `{audience_id}`.
     */
    protected override ExtractPaginationInfo(
        rawBody: unknown,
        paginationType: PaginationType,
        _currentPage: number,
        currentOffset: number,
        pageSize: number,
    ): PaginationState {
        if (paginationType !== 'Offset' && paginationType !== 'Cursor') return { HasMore: false };
        const env = (rawBody && typeof rawBody === 'object' ? rawBody : {}) as MailchimpCollectionEnvelope;
        const total = typeof env.total_items === 'number' ? env.total_items : undefined;
        const fetched = this.countEnvelopeRecords(env);
        const nextOffset = currentOffset + fetched;
        const hasMore = total != null ? nextOffset < total : fetched >= pageSize;
        return { HasMore: hasMore, NextOffset: hasMore ? nextOffset : undefined, TotalRecords: total };
    }

    /** Mailchimp offset pagination params: `count=<n>` (≤1000) + `offset=<n>` (NOT the base default `limit`/`offset`). */
    protected override BuildPaginatedURL(
        basePath: string,
        obj: MJIntegrationObjectEntity,
        _page: number,
        offset: number,
        _cursor?: string,
        effectivePageSize?: number,
    ): string {
        const pageSize = Math.min(effectivePageSize ?? obj.DefaultPageSize ?? DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE);
        const separator = basePath.includes('?') ? '&' : '?';
        return `${basePath}${separator}count=${pageSize}&offset=${offset}`;
    }

    /**
     * Appends the per-endpoint incremental filter on a watermarked fetch: `since_<IncrementalWatermarkField>`
     * (Mailchimp's documented date-filter convention — e.g. `since_last_changed` for list members). Only
     * fires for objects the metadata marks `SupportsIncrementalSync` with a watermark field AND when a
     * watermark value is present. Then delegates to the base for any metadata-declared DefaultQueryParams.
     */
    protected override AppendDefaultQueryParams(url: string, obj: MJIntegrationObjectEntity): string {
        let out = super.AppendDefaultQueryParams(url, obj);
        if (this.currentWatermark && obj.SupportsIncrementalSync && obj.IncrementalWatermarkField) {
            const param = `since_${obj.IncrementalWatermarkField}`;
            if (!this.urlHasParam(out, param)) {
                out += (out.includes('?') ? '&' : '?') + `${param}=${encodeURIComponent(this.currentWatermark)}`;
            }
        }
        return out;
    }

    /** Per-account base host. The `/3.0` version segment is included; each object's APIPath is appended by the base. */
    protected override GetBaseURL(_companyIntegration: MJCompanyIntegrationEntity, auth: RESTAuthContext): string {
        const ctx = auth as MailchimpAuthContext;
        if (ctx.BaseURLOverride) return ctx.BaseURLOverride.replace(/\/+$/, '');
        return `https://${ctx.DataCenter}.api.mailchimp.com/3.0`;
    }

    // ── Path templating ───────────────────────────────────────────────

    /**
     * OVERRIDE (idiosyncrasy): Mailchimp single-record paths use NAMED vars (`/campaigns/{campaign_id}`), not
     * the base's `{ID}` placeholder. Fill each named `{var}` from the ExternalID — left-to-right across the
     * `|`-split components of a composite ExternalID (mirrors ToExternalRecord's composite-PK join), so a
     * single-var top-level path takes the whole ExternalID. This makes the INHERITED generic
     * UpdateRecord / DeleteRecord / GetRecord work for all top-level writable IOs. (Nested paths that carry a
     * PARENT var not present in the single-key ExternalID are handled by the Create/Update overrides below.)
     */
    protected override SubstituteIDInPath(path: string, externalID: string, idLocation: string | null): string {
        if (idLocation && idLocation !== 'path') return path;
        const vars = this.detectPathVars(path);
        if (vars.length === 0) return path;
        const parts = String(externalID).split('|');
        let out = path;
        vars.forEach((v, i) => {
            const val = parts[i] ?? parts[parts.length - 1] ?? externalID;
            out = out.replace(`{${v}}`, encodeURIComponent(val));
        });
        return out;
    }

    // ── CRUD ──────────────────────────────────────────────────────────
    //
    // Top-level writable IOs (campaigns, templates, lists, stores, …) use the INHERITED generic
    // CreateRecord / UpdateRecord / DeleteRecord / GetRecord — all creates are flat-body with the new id at
    // the response root, and single-var single-record paths resolve via the SubstituteIDInPath override
    // above. The Create/Update/Delete methods here override ONLY the genuinely idiosyncratic case: NESTED
    // resources whose write path carries a named PARENT var (`{list_id}`, `{store_id}`, …) that is not part
    // of the child's single-key ExternalID and must be sourced from the record's own attributes.

    /** Create: nested paths fill parent vars from the record attributes; top-level delegates to the generic path. */
    public override async CreateRecord(ctx: CreateRecordContext): Promise<CRUDResult> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const contextUser = ctx.ContextUser as UserInfo;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        if (!obj.CreateAPIPath || !obj.CreateMethod) return super.CreateRecord(ctx);
        if (this.detectPathVars(obj.CreateAPIPath).length === 0) return super.CreateRecord(ctx);

        const auth = await this.Authenticate(ci, contextUser);
        const path = this.fillPathFromAttributes(obj.CreateAPIPath, ctx.Attributes, null);
        this.assertPathResolved(path, ctx.ObjectName, 'create');
        const url = `${this.GetBaseURL(ci, auth)}${path.startsWith('/') ? path : `/${path}`}`;
        const body = this.BuildOperationBody(ctx.Attributes, obj.CreateBodyShape, obj.CreateBodyKey);
        const response = await this.MakeHTTPRequest(auth, url, obj.CreateMethod, this.BuildHeaders(auth), body);
        if (response.Status >= 200 && response.Status < 300) {
            const externalID = this.ExtractIDFromResponse(response, obj.CreateIDLocation);
            return this.BuildCreatedResult(externalID, response.Status, ctx.ObjectName);
        }
        return { Success: false, StatusCode: response.Status, ErrorMessage: this.ExtractErrorMessage(response) ?? `HTTP ${response.Status} on create` };
    }

    /** Update: nested paths fill parent vars from attributes + the innermost var from the ExternalID; top-level delegates. */
    public override async UpdateRecord(ctx: UpdateRecordContext): Promise<CRUDResult> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const contextUser = ctx.ContextUser as UserInfo;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        if (!obj.UpdateAPIPath || !obj.UpdateMethod) return super.UpdateRecord(ctx);
        if (this.detectPathVars(obj.UpdateAPIPath).length <= 1) return super.UpdateRecord(ctx);

        const auth = await this.Authenticate(ci, contextUser);
        const path = this.fillPathFromAttributes(obj.UpdateAPIPath, ctx.Attributes, ctx.ExternalID);
        this.assertPathResolved(path, ctx.ObjectName, 'update');
        const url = `${this.GetBaseURL(ci, auth)}${path.startsWith('/') ? path : `/${path}`}`;
        const body = this.BuildOperationBody(ctx.Attributes, obj.UpdateBodyShape, obj.UpdateBodyKey);
        const response = await this.MakeHTTPRequest(auth, url, obj.UpdateMethod, this.BuildHeaders(auth), body);
        if (response.Status >= 200 && response.Status < 300) {
            return { Success: true, StatusCode: response.Status, ExternalID: ctx.ExternalID };
        }
        return { Success: false, StatusCode: response.Status, ErrorMessage: this.ExtractErrorMessage(response) ?? `HTTP ${response.Status} on update` };
    }

    /**
     * Delete: nested paths resolve every `{var}` from the `|`-split composite ExternalID (right-aligned:
     * `{list_id}`,`{subscriber_hash}` ← `list1|hashaaa`); top-level delegates. A nested delete whose parent
     * var still can't be resolved (e.g. a single-component ExternalID that carries only the child key) fails
     * loudly rather than issuing a request with an unresolved `{parent}` — a live-verification concern flagged
     * in CODE_REPORT.
     */
    public override async DeleteRecord(ctx: DeleteRecordContext): Promise<CRUDResult> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const contextUser = ctx.ContextUser as UserInfo;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        if (!obj.DeleteAPIPath || !obj.DeleteMethod) return super.DeleteRecord(ctx);
        if (this.detectPathVars(obj.DeleteAPIPath).length <= 1) return super.DeleteRecord(ctx);

        const auth = await this.Authenticate(ci, contextUser);
        const path = this.fillPathFromAttributes(obj.DeleteAPIPath, {}, ctx.ExternalID);
        const unresolved = this.detectPathVars(path);
        if (unresolved.length > 0) {
            return {
                Success: false,
                StatusCode: 0,
                ErrorMessage: `Delete of nested "${ctx.ObjectName}" could not resolve parent path var(s) {${unresolved.join(', ')}} — a nested delete needs the parent id, which the delete context does not carry (requires live verification / composite key).`,
            };
        }
        const url = `${this.GetBaseURL(ci, auth)}${path.startsWith('/') ? path : `/${path}`}`;
        const response = await this.MakeHTTPRequest(auth, url, obj.DeleteMethod, this.BuildHeaders(auth));
        if (response.Status >= 200 && response.Status < 300) {
            return { Success: true, StatusCode: response.Status, ExternalID: ctx.ExternalID };
        }
        return { Success: false, StatusCode: response.Status, ErrorMessage: this.ExtractErrorMessage(response) ?? `HTTP ${response.Status} on delete` };
    }

    // ── Helpers ───────────────────────────────────────────────────────

    /**
     * Counts the records in a Mailchimp collection envelope by finding the per-object data array (the first
     * array-valued property that isn't the `_links` HATEOAS list). Used for pagination advancement — the
     * data key isn't passed to ExtractPaginationInfo, so we locate the array structurally. Returns 0 for a
     * single-record body (no array), which correctly reports "no more pages".
     */
    private countEnvelopeRecords(env: MailchimpCollectionEnvelope): number {
        for (const [key, value] of Object.entries(env)) {
            if (key === '_links') continue;
            if (Array.isArray(value)) return value.length;
        }
        return 0;
    }

    /** Extracts `{var}` names from a path template, in left-to-right order. */
    private detectPathVars(path: string): string[] {
        const matches = path.match(/\{(\w+)\}/g);
        return matches ? matches.map(m => m.slice(1, -1)) : [];
    }

    /**
     * Fills each `{var}` in a nested write path by resolving, per var, in this order:
     *   1. a same-named attribute on the record (e.g. the base tags fetched children with their parent FK
     *      field, so a synced member carries `list_id`);
     *   2. the RIGHT-ALIGNED component of the `|`-split ExternalID — mirroring ToExternalRecord's composite-PK
     *      join order (`parent|…|child`): the innermost (last) var is the record's OWN key, preceding vars are
     *      the parent id(s). So a member's ExternalID `list1|hashaaa` fills `{list_id}`→`list1`,
     *      `{subscriber_hash}`→`hashaaa`, which is exactly what a nested update/delete needs even with no
     *      attributes present.
     * Create paths pass externalID=null and thus fill purely from attributes. Any var that resolves to nothing
     * is left in place so {@link assertPathResolved} / the delete guard can surface it (fail loudly, never
     * issue a request with an unresolved `{parent}`).
     */
    private fillPathFromAttributes(template: string, attributes: Record<string, unknown>, externalID: string | null): string {
        const vars = this.detectPathVars(template);
        const components = externalID != null ? String(externalID).split('|') : [];
        const offset = vars.length - components.length; // right-align components to the tail of the var list
        let out = template;
        vars.forEach((v, i) => {
            let val: unknown = attributes[v];
            if (val == null || val === '') {
                const compIdx = i - offset;
                if (compIdx >= 0 && compIdx < components.length) val = components[compIdx];
            }
            if (val != null && val !== '') out = out.replace(`{${v}}`, encodeURIComponent(String(val)));
        });
        return out;
    }

    /** Throws a clear error if a nested write path still has unresolved `{var}`s (missing parent id). */
    private assertPathResolved(path: string, objectName: string, op: string): void {
        const unresolved = this.detectPathVars(path);
        if (unresolved.length > 0) {
            throw new Error(
                `Mailchimp ${op} of "${objectName}": unresolved path var(s) {${unresolved.join(', ')}} — ` +
                `the record must carry the parent id field(s) (e.g. list_id / store_id) in its attributes.`,
            );
        }
    }

    /** True when a URL already carries a query param with `name` (case-insensitive). */
    private urlHasParam(url: string, name: string): boolean {
        const q = url.indexOf('?');
        if (q < 0) return false;
        const lname = name.toLowerCase();
        return url.substring(q + 1).split('&').some(p => {
            const eq = p.indexOf('=');
            const k = (eq >= 0 ? p.substring(0, eq) : p).toLowerCase();
            return k === lname;
        });
    }

    /** Loads credentials from the linked Credential entity (preferred) or the CompanyIntegration Configuration JSON. */
    private async loadCredentials(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<MailchimpCredentials> {
        const fromConfig = companyIntegration.Configuration ? this.parseCredentialJson(companyIntegration.Configuration) : null;
        let fromCred: MailchimpCredentials | null = null;
        if (companyIntegration.CredentialID) {
            fromCred = await this.loadFromCredential(companyIntegration.CredentialID, contextUser);
        }
        // Credential secret (ApiKey) wins; Configuration supplies non-secret dc / base-URL overrides.
        return { ...(fromConfig ?? {}), ...(fromCred ?? {}) };
    }

    /** Loads a credential row and parses its Values JSON. */
    private async loadFromCredential(
        credentialID: string,
        contextUser: UserInfo,
        provider?: IMetadataProvider,
    ): Promise<MailchimpCredentials | null> {
        const md = provider ?? new Metadata();
        const credential = await md.GetEntityObject<MJCredentialEntity>('MJ: Credentials', contextUser);
        const loaded = await credential.Load(credentialID);
        if (!loaded || !credential.Values) return null;
        return this.parseCredentialJson(credential.Values);
    }

    /** Parses a Mailchimp credential/config JSON blob, tolerant of key casing variants. */
    private parseCredentialJson(json: string): MailchimpCredentials | null {
        let parsed: Record<string, unknown>;
        try { parsed = JSON.parse(json) as Record<string, unknown>; } catch { return null; }
        const scheme = this.firstString(parsed, ['scheme', 'Scheme', 'authScheme', 'AuthScheme']);
        return {
            ApiKey: this.firstString(parsed, ['ApiKey', 'apiKey', 'API_Key', 'apikey', 'apiToken', 'ApiToken', 'token', 'Token', 'accessToken', 'AccessToken']),
            DataCenter: this.firstString(parsed, ['DataCenter', 'dataCenter', 'ServerPrefix', 'serverPrefix', 'server', 'dc', 'prefix']),
            BaseURLOverride: this.firstBaseURL(parsed, ['BaseURL', 'BaseUrl', 'baseURL', 'baseUrl', 'APIBaseURL', 'ApiBaseURL', 'apiBaseUrl']),
            Scheme: scheme === 'bearer' ? 'bearer' : 'basic',
        };
    }

    /**
     * Resolves the data-center prefix (e.g. `us15`):
     *   1. explicit DataCenter / ServerPrefix from config/credential;
     *   2. the `-<dc>` suffix parsed off the API key;
     *   3. (runtime fallback for an OAuth bearer token with no dc) the OAuth2 metadata endpoint.
     * A BaseURLOverride short-circuits the need for a real dc (used for sandbox/test/mock).
     */
    private async resolveDataCenter(creds: MailchimpCredentials): Promise<string> {
        if (creds.DataCenter && creds.DataCenter.trim().length > 0) return creds.DataCenter.trim().toLowerCase();
        const fromKey = this.parseDataCenterFromKey(creds.ApiKey ?? '');
        if (fromKey) return fromKey;
        if (creds.BaseURLOverride) return 'override'; // dc unused when an explicit base URL is present
        return this.fetchDataCenterFromOAuthMetadata(creds.ApiKey ?? '', creds.Scheme);
    }

    /** Extracts `<dc>` from a Mailchimp API key of the form `<secret>-<dc>` (e.g. `abc123-us15` → `us15`). */
    private parseDataCenterFromKey(apiKey: string): string | null {
        const idx = apiKey.lastIndexOf('-');
        if (idx < 0 || idx >= apiKey.length - 1) return null;
        const suffix = apiKey.slice(idx + 1).toLowerCase();
        return /^[a-z]{2}\d{1,3}$/.test(suffix) ? suffix : null;
    }

    /** Runtime fallback: GET /oauth2/metadata to discover the data center for an OAuth access token. */
    private async fetchDataCenterFromOAuthMetadata(token: string, scheme?: 'basic' | 'bearer'): Promise<string> {
        const authValue = scheme === 'bearer' ? `Bearer ${token}` : `OAuth ${token}`;
        const response = await fetch(MAILCHIMP_OAUTH_METADATA_URL, {
            method: 'GET',
            headers: { 'Authorization': authValue, 'Accept': 'application/json' },
        });
        if (!response.ok) {
            throw new Error(`Mailchimp /oauth2/metadata returned ${response.status}; cannot resolve the data center. Set DataCenter (or ServerPrefix) explicitly.`);
        }
        const body = await response.json() as MailchimpOAuthMetadata;
        if (!body.dc) throw new Error('Mailchimp /oauth2/metadata response did not include a dc field.');
        return body.dc.toLowerCase();
    }

    /** Returns the first non-empty string value among the candidate keys, else undefined. */
    private firstString(obj: Record<string, unknown>, keys: string[]): string | undefined {
        for (const k of keys) {
            const v = obj[k];
            if (typeof v === 'string' && v.trim().length > 0) return v.trim();
            if (typeof v === 'number') return String(v);
        }
        return undefined;
    }

    /** Returns the first candidate key whose value is a valid absolute http(s) URL, else undefined. */
    private firstBaseURL(obj: Record<string, unknown>, keys: string[]): string | undefined {
        const raw = this.firstString(obj, keys);
        return raw && /^https?:\/\//i.test(raw) ? raw : undefined;
    }

    /** Computes a 429/503 backoff delay, honoring an opportunistic Retry-After header when present. */
    private computeBackoffMs(response: Response, attempt: number): number {
        const retryAfter = response.headers.get('retry-after');
        if (retryAfter) {
            const secs = Number(retryAfter);
            if (Number.isFinite(secs) && secs > 0) return Math.min(secs * 1000, 60_000);
        }
        return Math.min(500 * Math.pow(2, attempt) + Math.floor(Math.random() * 250), 30_000);
    }

    /** Sleep helper. */
    private sleep(ms: number): Promise<void> {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}

/** Tree-shaking prevention — call from the package entry point. */
export function LoadMailchimpConnector(): void { /* no-op */ }
