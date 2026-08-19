/**
 * TotaraConnector — Totara LMS via the Moodle-inherited Web Services REST-RPC surface.
 *
 * Totara Web Services is a Moodle-derived layer: NOT resource-path REST and NOT OpenAPI/GraphQL. Every
 * operation is a POST to the SAME per-tenant endpoint (`{base_url}/webservice/rest/server.php`); the
 * operation identity lives entirely in the `wsfunction=` request parameter, and auth is a single opaque
 * `wstoken` passed as a REQUEST PARAMETER (never an Authorization header). This connector extends
 * BaseRESTIntegrationConnector (the ONLY protocol bases the engine exports are BaseIntegrationConnector +
 * BaseRESTIntegrationConnector — there is no Moodle/RPC base) and implements the REST-RPC protocol over the
 * base's HTTP seam.
 *
 * WHY the read + write paths are overridden (genuinely idiosyncratic per the CRUD-routing rule):
 *   - The base's generic GET-to-a-resource-path read loop cannot express "POST wsfunction=... to one shared
 *     endpoint, token-as-param, Moodle `limitfrom/limitnum(ber)` / `page` pagination, multi-collection
 *     envelopes (Notes: sitenotes+coursenotes+personalnotes; Contacts: online+offline+strangers), and an
 *     error signalled as a 200-status body ENVELOPE ({exception,errorcode,message})". So FetchChanges is
 *     overridden to drive the RPC read.
 *   - Writes use Moodle BRACKET-NOTATION urlencoded ARRAY bodies (e.g. `users[0][username]=...`), not a
 *     flat/wrapped JSON body — `CreateBodyShape/UpdateBodyShape='literal'` in the frozen metadata is the
 *     explicit "the connector builds the body" signal. CreateRecord/UpdateRecord/DeleteRecord are
 *     overridden for that encoding, and create STILL routes through {@link BuildCreatedResult} so a 2xx
 *     with no usable id fails LOUDLY (never a silent record-loss / duplicate-create-on-next-sync).
 *
 * The per-object `wsfunction`, response envelope key(s), pagination param names, stable ordering key, and
 * write function names are all read from each IntegrationObject's `Configuration` JSON — the catalog is
 * NEVER baked into this code (connector-code-conventions § "NEVER bake a catalog"). The per-tenant
 * `base_url` + `wstoken` are resolved from the credential store / CompanyIntegration.Configuration at
 * request time — ZERO tenant constants live in this file.
 *
 * DiscoveryIsAuthoritative stays false: the runtime introspection function (core_webservice_get_site_info)
 * enumerates the functions ENABLED FOR THE CALLING TOKEN — a role/capability-gated slice, NOT a complete
 * describe of the site — so absence in one token's view must never deactivate a Declared IO/IOF.
 */
import { RegisterClass } from '@memberjunction/global';
import { Metadata, type UserInfo } from '@memberjunction/core';
import type {
    MJCompanyIntegrationEntity,
    MJCredentialEntity,
    MJIntegrationObjectEntity,
    MJIntegrationObjectFieldEntity,
} from '@memberjunction/core-entities';
import { z } from 'zod';
import {
    BaseIntegrationConnector,
    BaseRESTIntegrationConnector,
    computeContentHash,
    serializeKeyValue,
    type RESTAuthContext,
    type RESTResponse,
    type PaginationState,
    type PaginationType,
    type ConnectionTestResult,
    type FetchContext,
    type FetchBatchResult,
    type ExternalRecord,
    type CreateRecordContext,
    type UpdateRecordContext,
    type DeleteRecordContext,
    type CRUDResult,
    type SourceSchemaInfo,
} from '@memberjunction/integration-engine';
import { IntegrationEngineBase } from '@memberjunction/integration-engine-base';
import { mergeDeclaredWithSampledFields } from '@memberjunction/connector-schema-merge';
import { ParseDerivedCollectionConfig, ExplodeCollection, DropConfiguredFields } from './DerivedCollections.js';
import { runIdWindowScan } from '@memberjunction/connector-id-window-scan';

// ─── Constants ─────────────────────────────────────────────────────────
const REST_ENDPOINT_SUFFIX = '/webservice/rest/server.php';
const RESTFORMAT_PARAM = 'moodlewsrestformat';
const RESTFORMAT_VALUE = 'json';
const WSFUNCTION_PARAM = 'wsfunction';
const WSTOKEN_PARAM = 'wstoken';
const SITE_INFO_FUNCTION = 'core_webservice_get_site_info';

// ─── Types ─────────────────────────────────────────────────────────────

/** Resolved connection settings (secret token + per-tenant base URL). NO tenant constants in code. */
interface TotaraConfig {
    /** The per-user Web Service token (wstoken) — injected as a request PARAM, never a header. */
    Token: string;
    /** The tenant's site base URL (e.g. https://learn.example.org). */
    BaseURL: string;
    /** Per-request read deadline in ms; 0 disables it. Defaults to {@link DEFAULT_REQUEST_TIMEOUT_MS}. */
    RequestTimeoutMs: number;
}

/** Auth context threaded through every request. Carries the token + the resolved RPC endpoint. */
export interface TotaraAuthContext extends RESTAuthContext {
    /** wstoken — injected as a urlencoded body param by MakeHTTPRequest. */
    Token: string;
    /** Fully-resolved RPC endpoint: `{base_url}/webservice/rest/server.php`. */
    Endpoint: string;
    /** Per-request read deadline in ms (0 = no deadline). Resolved once at Authenticate. */
    RequestTimeoutMs: number;
}

/**
 * The structured RPC request handed to {@link TotaraConnector.MakeHTTPRequest} as its `body`.
 * MakeHTTPRequest is where the urlencoded form (wstoken + moodlewsrestformat + wsfunction + params) is
 * actually built — so a test that mocks MakeHTTPRequest captures the meaningful wire intent (function +
 * params). `Params` keys are already Moodle-shaped (flat for reads; bracket-notation for write arrays).
 */
export interface MoodleRPCRequest {
    /** The wsfunction operation selector (e.g. core_course_get_courses). */
    WsFunction: string;
    /** Flat urlencoded params. wstoken/moodlewsrestformat/wsfunction are added by MakeHTTPRequest. */
    Params: Record<string, string | number>;
}

/** Zod schema for the resolved connection config. */
const ConfigSchema = z.object({
    Token: z.string().min(1, 'Totara wstoken is required'),
    BaseURL: z.string().min(1, 'Totara base_url is required').refine(
        v => /^https?:\/\//i.test(v),
        'Totara base_url must be an absolute http(s) URL',
    ),
});

/**
 * The declared stable ordering applied to an offset-paged read. Assembled from the object's own
 * `Configuration` (`orderingParams` + `stableOrderingKey`), never inferred — the option names are
 * per-wsfunction. See {@link TotaraConnector.readOffsetOrdering} for why an offset read without one is a
 * correctness defect and not merely a slow one.
 */
interface OffsetOrdering {
    SortByParam: string;
    SortDirectionParam: string;
    Key: string;
    Direction: string;
}

/**
 * Decoded parent-walk cursor. `After` is the parent the walk is finished THROUGH; `Partials` carries a
 * mid-parent offset for any parent at or past that point; `Fails` counts consecutive transient failures per
 * parent so a flaky parent is retried a bounded number of times instead of forever or never.
 * See {@link TotaraConnector.parseParentCursor} for the wire forms and why they are what they are.
 */
interface ParentCursor {
    After: string | null;
    Partials: Map<string, number>;
    Fails: Map<string, number>;
}

// ─── Connector ─────────────────────────────────────────────────────────

/**
 * Wall-clock budget for one parent-scoped fetch call, in ms. Deliberately under the engine's
 * `FetchChangesMs` (30000): a batch that overruns that is KILLED and persists nothing, so a walk that stops
 * itself at 20s with partial progress beats one that is 30s deep and loses everything. Per-object override:
 * `Configuration.parentScope.budgetMs`.
 */
const DEFAULT_PARENT_WALK_BUDGET_MS = 20000;

/**
 * How long a cached parent-id list stays usable, in ms. The list is re-read once per fetch batch otherwise,
 * and it is not cheap — `core_course_get_courses` measured 6.1s live, spent out of a budget that must fit
 * inside a 30000ms kill. Per-object override: `Configuration.parentScope.parentCacheMs` (0 disables).
 */
const DEFAULT_PARENT_LIST_CACHE_MS = 300000;

/**
 * Read deadline for a single web-service call, in ms. Deliberately UNDER the engine's
 * `FetchChangesMs = 30000` kill: a vendor that accepts the connection and then never answers used to hang
 * the fetch forever — observed twice as wedged worker processes that had to be killed from outside, which
 * is not a failed run and produces no artifact anyone can read. Aborting first turns that into an ordinary
 * fetch error the engine can retry and the run artifact can record.
 *
 * Override per connection with `requestTimeoutMs` in CompanyIntegration.Configuration; `0` disables it.
 */
const DEFAULT_REQUEST_TIMEOUT_MS = 25000;

/**
 * How many consecutive TRANSIENT failures one parent may cost before the walk abandons it and moves past.
 *
 * A transient failure must not advance the cursor over its parent: doing so drops that parent's unread records
 * silently, behind a green run. Measured live (run `9200B480`): 24 requests were aborted on the 25000ms read
 * deadline, and because every caught error marked its parent examined, each one advanced the cursor past a
 * course whose enrolments had not been fully read. But refusing to advance forever is the OTHER failure mode —
 * the `Users` `[invalidresponse]` deadlock was 61 identical failures, 0 records, and no forward progress
 * possible. So the attempt count rides the CURSOR (a per-call counter forgets it at every batch boundary), and
 * after this many tries the parent is abandoned with a warning that names it.
 *
 * Per-object override: `Configuration.parentScope.maxParentAttempts`.
 */
const DEFAULT_MAX_PARENT_ATTEMPTS = 3;

@RegisterClass(BaseIntegrationConnector, 'TotaraConnector')
export class TotaraConnector extends BaseRESTIntegrationConnector {

    /** Resolved auth per CompanyIntegration.ID — avoids re-loading the credential every fetch/CRUD call. */
    protected authCache = new Map<string, TotaraAuthContext>();

    /** Parent-id lists per connection+parent function, so a resumed parent walk does not re-read them. */
    protected parentIDCache = new Map<string, { IDs: string[]; At: number }>();

    /**
     * Short-lived cache of parent FETCH PAGES, keyed by (integration, parent object,
     * cursor). Derived collections re-run their parent's fetch; when several derived
     * objects share one parent (Enrolled Users carries roles AND groups) and sync in
     * the same run, this serves the later walks from memory instead of re-reading the
     * vendor. Deliberately small and short-TTL — it is an optimisation, never a
     * correctness dependency: a miss is just a vendor read.
     */
    protected derivedPageCache = new Map<string, { At: number; Result: FetchBatchResult }>();

    // ── Identity + capabilities ──────────────────────────────────────

    /** Verbatim MJ: Integrations.Name (three-way identity invariant). */
    public override get IntegrationName(): string { return 'totara'; }

    /** Create is wired (courses/users/cohorts/groups/groupings/notes/categories + association adds). */
    public override get SupportsCreate(): boolean { return true; }
    /** Update is wired for the objects that expose an update_* wsfunction (courses/users/cohorts/…/notes). */
    public override get SupportsUpdate(): boolean { return true; }
    /** Delete is wired for the objects that expose a delete/unenrol/remove wsfunction. */
    public override get SupportsDelete(): boolean { return true; }

    /**
     * core_webservice_get_site_info enumerates the functions ENABLED FOR THE CALLING TOKEN (role/capability
     * gated), NOT a complete-gamut describe of the site — so keep the base default false: a
     * comprehensive-refresh must never deactivate a Declared IO/IOF because one token can't see it.
     */
    public override get DiscoveryIsAuthoritative(): boolean { return false; }

    /**
     * Keyset/no-watermark resume hint — returns the IO's declared `Configuration.stableOrderingKey`
     * (usually the record's `id`), or null when the object declares none. Read from the frozen metadata,
     * never guessed.
     */
    public override StableOrderingKey(objectName: string): string | null {
        const integ = IntegrationEngineBase.Instance.GetIntegrationByName(this.IntegrationName);
        if (!integ) return null;
        const obj = IntegrationEngineBase.Instance.GetIntegrationObject(integ.ID, objectName);
        if (!obj) return null;
        return this.readConfigString(this.readIOConfig(obj), 'stableOrderingKey');
    }

    // ── TestConnection ────────────────────────────────────────────────

    /**
     * Verifies the wstoken + endpoint. The primary probe is core_webservice_get_site_info (it also carries
     * the site name / release), BUT some Totara instances / token-service configurations throw a NON-auth
     * "No service found in get_site_info" codingerror on it even for a fully valid token (verified live
     * against a real instance). So a non-auth failure on site-info FALLS BACK to a lightweight real read
     * (core_course_get_categories): if that returns a record array, the token is valid and the connection
     * works. Only a genuine auth error (invalid/expired token, access denied) — or a failing fallback read —
     * reports failure.
     */
    public async TestConnection(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<ConnectionTestResult> {
        let auth: TotaraAuthContext;
        try {
            auth = await this.Authenticate(companyIntegration, contextUser);
        } catch (err: unknown) {
            return { Success: false, Message: `Totara connection error: ${err instanceof Error ? err.message : String(err)}` };
        }

        try {
            const request: MoodleRPCRequest = { WsFunction: SITE_INFO_FUNCTION, Params: {} };
            const response = await this.MakeHTTPRequest(auth, auth.Endpoint, 'POST', this.BuildHeaders(auth), request);
            this.assertNoMoodleError(response.Body);
            const info = (response.Body ?? {}) as Record<string, unknown>;
            const siteName = typeof info.sitename === 'string' ? info.sitename : 'Totara site';
            const release = typeof info.release === 'string' ? info.release : undefined;
            return {
                Success: true,
                Message: `Connected to ${siteName} (Totara/Moodle Web Services)`,
                ServerVersion: release,
            };
        } catch (err: unknown) {
            const message = err instanceof Error ? err.message : String(err);
            if (this.isTotaraAuthError(message)) {
                return { Success: false, Message: `Totara authentication failed: ${message}` };
            }
            // Non-auth site-info failure (e.g. the "No service found" codingerror some instances throw) —
            // verify the connection with a real read instead of reporting a false failure.
            return await this.verifyConnectionViaRead(auth, message);
        }
    }

    /** A genuine credential / authorization failure — terminal; never fall back on these. */
    private isTotaraAuthError(message: string): boolean {
        return /invalidtoken|invalid_token|accessexception|access ?control|unauthor|permission|denied|expired|forbidden/i.test(message);
    }

    /**
     * Fallback connection check: a valid wstoken that returns a record array from a lightweight read
     * (core_course_get_categories) proves the connection even when site-info is unavailable on the instance.
     */
    private async verifyConnectionViaRead(auth: TotaraAuthContext, siteInfoMessage: string): Promise<ConnectionTestResult> {
        try {
            const request: MoodleRPCRequest = { WsFunction: 'core_course_get_categories', Params: {} };
            const response = await this.MakeHTTPRequest(auth, auth.Endpoint, 'POST', this.BuildHeaders(auth), request);
            this.assertNoMoodleError(response.Body);
            if (Array.isArray(response.Body)) {
                return { Success: true, Message: 'Connected to Totara/Moodle Web Services (verified via a read; site-info unavailable on this instance)' };
            }
            return { Success: false, Message: `Totara connection error: ${siteInfoMessage}` };
        } catch (err: unknown) {
            const message = err instanceof Error ? err.message : String(err);
            return {
                Success: false,
                Message: this.isTotaraAuthError(message) ? `Totara authentication failed: ${message}` : `Totara connection error: ${message}`,
            };
        }
    }

    // ── Auth (wstoken as a request PARAM, not a header) ───────────────

    /** Resolves the wstoken + endpoint from the credential store / Configuration. Cached per connection. */
    protected async Authenticate(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<TotaraAuthContext> {
        const cached = this.authCache.get(companyIntegration.ID);
        if (cached) return cached;

        const config = await this.ParseConfig(companyIntegration, contextUser);
        const auth: TotaraAuthContext = {
            Token: config.Token,
            Endpoint: this.buildEndpoint(config.BaseURL),
            RequestTimeoutMs: config.RequestTimeoutMs,
        };
        this.authCache.set(companyIntegration.ID, auth);
        return auth;
    }

    /**
     * Content-type headers for a Moodle REST-RPC POST. The wstoken is NOT a header — it is injected as a
     * urlencoded body PARAM in {@link MakeHTTPRequest} from the auth context.
     */
    protected BuildHeaders(_auth: RESTAuthContext): Record<string, string> {
        return {
            'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
            'Accept': 'application/json',
        };
    }

    /** The fully-resolved RPC endpoint (`{base_url}/webservice/rest/server.php`) from the auth context. */
    protected GetBaseURL(_companyIntegration: MJCompanyIntegrationEntity, auth: RESTAuthContext): string {
        return (auth as TotaraAuthContext).Endpoint;
    }

    // ── HTTP transport — urlencoded REST-RPC POST ─────────────────────

    /**
     * The Moodle REST-RPC transport boundary. `body` MUST be a {@link MoodleRPCRequest}; this builds the
     * urlencoded form — `wstoken` (from the auth context) + `moodlewsrestformat=json` + `wsfunction=<fn>` +
     * every entry of `Params` (already Moodle-shaped) — POSTs it, and parses the JSON response. Test
     * subclasses override this to capture the request and return canned bodies.
     */
    protected async MakeHTTPRequest(
        auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown,
    ): Promise<RESTResponse> {
        const request = body as MoodleRPCRequest | undefined;
        if (!request || typeof request.WsFunction !== 'string') {
            throw new Error('TotaraConnector.MakeHTTPRequest requires a MoodleRPCRequest body (WsFunction + Params)');
        }
        const token = (auth as TotaraAuthContext).Token ?? '';
        const form = new URLSearchParams();
        form.append(WSTOKEN_PARAM, token);
        form.append(RESTFORMAT_PARAM, RESTFORMAT_VALUE);
        form.append(WSFUNCTION_PARAM, request.WsFunction);
        for (const [key, value] of Object.entries(request.Params)) {
            form.append(key, String(value));
        }

        // The deadline covers the response BODY, not just the headers: a site that streams a header block
        // and then stalls mid-body hangs just as hard as one that never answers, so the same signal is
        // passed to fetch and held across the text() read.
        const timeoutMs = (auth as TotaraAuthContext).RequestTimeoutMs ?? DEFAULT_REQUEST_TIMEOUT_MS;
        const signal = timeoutMs > 0 ? AbortSignal.timeout(timeoutMs) : undefined;

        let httpResponse: Response;
        let text: string;
        try {
            httpResponse = await fetch(url, { method, headers, body: form.toString(), signal });
            text = await httpResponse.text();
        } catch (err: unknown) {
            // Surface an abort as an ordinary fetch error naming the function and the deadline, so the
            // engine retries it like any other transport failure and the run artifact records WHY. An
            // unnamed abort reads as a mystery; "core_enrol_get_enrolled_users exceeded 25000ms" is a
            // fact someone can act on.
            if (err instanceof Error && (err.name === 'TimeoutError' || err.name === 'AbortError')) {
                throw new Error(
                    `Totara web service "${request.WsFunction}" did not respond within ${timeoutMs}ms`
                    + ` and the request was aborted. Raise requestTimeoutMs in the connection's Configuration`
                    + ` (0 disables the deadline) if this function is legitimately slower than that.`
                );
            }
            throw err;
        }
        return {
            Status: httpResponse.status,
            Body: this.parseJson(text),
            Headers: this.headersToObject(httpResponse.headers),
        };
    }

    // ── NormalizeResponse — exception-envelope detection + record extraction ──

    /**
     * Extracts the record array from a Moodle response, DETECTING the exception envelope first: Moodle
     * signals errors via a 200-status body `{exception, errorcode, message, debuginfo}` — this throws an
     * ERROR carrying the errorcode rather than returning a silent empty (frozen contract ErrorResponseShape).
     * `responseDataKey` is the wrapping envelope key (e.g. `users`, `items`, `sitenotes`); null → the body is
     * a bare top-level array. A single wrapped object is returned as a one-element array.
     */
    protected NormalizeResponse(rawBody: unknown, responseDataKey: string | null): Record<string, unknown>[] {
        this.assertNoMoodleError(rawBody);
        if (rawBody == null) return [];

        let target: unknown = rawBody;
        if (responseDataKey) {
            if (rawBody && typeof rawBody === 'object' && !Array.isArray(rawBody)) {
                target = (rawBody as Record<string, unknown>)[responseDataKey];
                if (target === undefined) return []; // declared envelope key absent → no records
            } else {
                return [];
            }
        }
        return this.toRecordArray(target);
    }

    // ── ExtractPaginationInfo — Offset (limitfrom) / PageNumber (page) ──

    /**
     * Moodle list functions carry no envelope-level `HasMore`; termination is inferred from a full page
     * (record count == page size). Hierarchy `*_index` functions DO return `{page, pages, total}` metadata —
     * when present that is used for an exact stop. `None` never paginates.
     */
    protected ExtractPaginationInfo(
        rawBody: unknown,
        paginationType: PaginationType,
        currentPage: number,
        currentOffset: number,
        pageSize: number,
    ): PaginationState {
        if (paginationType === 'None') return { HasMore: false };

        // Exact stop when the response reports page/pages metadata (hierarchy_*_index shape).
        if (rawBody && typeof rawBody === 'object' && !Array.isArray(rawBody)) {
            const rec = rawBody as Record<string, unknown>;
            const pages = this.asNumber(rec.pages);
            const page = this.asNumber(rec.page) ?? currentPage;
            if (pages != null) {
                const hasMore = page < pages;
                return paginationType === 'Offset'
                    ? { HasMore: hasMore, NextOffset: currentOffset + this.recordCount(rawBody) }
                    : { HasMore: hasMore, NextPage: page + 1 };
            }
        }

        const count = this.recordCount(rawBody);
        const hasMore = pageSize > 0 && count >= pageSize;
        if (paginationType === 'Offset') {
            return { HasMore: hasMore, NextOffset: currentOffset + count };
        }
        return { HasMore: hasMore, NextPage: currentPage + 1 };
    }

    // ── IntrospectSchema — declared + sampled field union (connector standard) ──

    /**
     * Never-shrink SAMPLE-UNION: enrich each object's DECLARED (docs) field set with fields observed by live
     * SAMPLING ({@link DiscoverFieldsViaFetch}) so a tenant's custom user/course fields reach the schema
     * without ever losing or narrowing a declared field. Per object, parallel + best-effort — a sampling
     * failure (e.g. a scope-requiring function) leaves that object's declared fields authoritative. Wire at
     * IntrospectSchema, NEVER DiscoverFields (DiscoverFieldsViaFetch falls back to DiscoverFields → recursion).
     */
    public override async IntrospectSchema(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<SourceSchemaInfo> {
        const info = await super.IntrospectSchema(companyIntegration, contextUser);
        await Promise.all(info.Objects.map(async (obj) => {
            try {
                const sampled = await this.DiscoverFieldsViaFetch(companyIntegration, obj.ExternalName, contextUser);
                obj.Fields = mergeDeclaredWithSampledFields(obj.Fields, sampled);
            } catch { /* best-effort — declared fields remain authoritative on a sampling failure */ }
        }));
        return info;
    }

    // ── FetchChanges — Moodle REST-RPC read ───────────────────────────

    /**
     * Reads one object via its `Configuration.wsfunction`. Applies Offset (`limitfrom`/`limitnum(ber)`) or
     * PageNumber (`page`/`perpage`) pagination from the object's declared `paginationParams`, merges any
     * declared scope args, and unions every record collection the envelope exposes (single `responseEnvelopeKey`
     * OR multi-collection `recordCollectionKeys` — e.g. Notes' sitenotes+coursenotes+personalnotes). Fetches
     * ONE page per call; the engine loops on HasMore. Full-record pass-through: every source key reaches Fields.
     */
    public override async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
        const obj = this.GetCachedObject(ctx.CompanyIntegration.IntegrationID, ctx.ObjectName);
        const fields = this.GetCachedFields(obj.ID);
        const cfg = this.readIOConfig(obj);

        // Derived-collection objects (Configuration.derivedCollection) don't fetch the vendor
        // themselves at all — they run their PARENT object's fetch (same pagination, same
        // parent-scoping, same budgets; the cursor rides through unchanged) and explode one of
        // its array fields into child records. Delegate before every other path.
        const derivedRaw = (cfg as Record<string, unknown>)['derivedCollection'];
        if (derivedRaw != null) {
            return this.fetchDerivedCollection(obj, ctx, derivedRaw, fields);
        }

        const wsfunction = this.readConfigString(cfg, 'wsfunction');
        if (!wsfunction) {
            return {
                Records: [],
                HasMore: false,
                Warnings: [{
                    Code: 'NO_WSFUNCTION',
                    Message: `"${obj.Name}": no Configuration.wsfunction — cannot dispatch a Moodle read.`,
                    Data: { object: obj.Name },
                }],
            };
        }

        // Objects whose LIST function cannot be bulk-listed (no pagination params, and the vendor docs
        // explicitly warn it "could [be] very slow or timeout" without narrow criteria — core_user_get_users
        // is the canonical case) fetch through a bounded id-window scan against the by-field bulk reader
        // instead. Declared via Configuration.idWindowScan. Delegate before every other path.
        const idWindowScan = this.readConfigObject(cfg, 'idWindowScan');
        if (idWindowScan) {
            return this.fetchIdWindowScan(obj, cfg, ctx, idWindowScan);
        }

        // Parent-scoped RPC objects (e.g. core_enrol_get_enrolled_users / core_course_get_contents need a
        // `courseid`) iterate ONE request per parent — declared via Configuration.parentScope. Delegate
        // before the single-call path so these objects sync instead of failing with [invalidparameter].
        const parentScope = this.readConfigObject(cfg, 'parentScope');
        if (parentScope) {
            return this.fetchParentScoped(obj, cfg, ctx, wsfunction, parentScope);
        }

        const auth = await this.Authenticate(ctx.CompanyIntegration, ctx.ContextUser);
        const page = ctx.CurrentPage ?? 1;
        const offset = ctx.CurrentOffset ?? 0;
        const pageSize = obj.DefaultPageSize && obj.DefaultPageSize > 0 ? obj.DefaultPageSize : Math.max(1, ctx.BatchSize);

        const params = this.buildReadParams(obj, cfg, ctx, page, offset, pageSize);
        const request: MoodleRPCRequest = { WsFunction: wsfunction, Params: params };
        const response = await this.MakeHTTPRequest(auth, auth.Endpoint, 'POST', this.BuildHeaders(auth), request);

        // Extract across every declared record collection (multi-collection envelopes → one record stream).
        const collectionKeys = this.recordCollectionKeys(obj, cfg);
        const rawRecords: Record<string, unknown>[] = [];
        for (const key of collectionKeys) {
            rawRecords.push(...this.NormalizeResponse(response.Body, key));
        }

        const pkFieldNames = this.primaryKeyFieldNames(fields);
        const dropFields = this.dropFieldsFor(cfg);
        const records = rawRecords.map(r => this.buildExternalRecord(
            DropConfiguredFields(this.applyTransformPreservingKeys(r, obj, fields), dropFields),
            ctx.ObjectName,
            pkFieldNames,
        ));

        const pagination = this.ExtractPaginationInfo(response.Body, obj.PaginationType as PaginationType, page, offset, pageSize);
        return {
            Records: records,
            HasMore: pagination.HasMore,
            NextPage: pagination.NextPage,
            NextOffset: pagination.NextOffset,
        };
    }

    /**
     * Parent-scoped RPC fetch. Some Moodle read functions REQUIRE a parent id param — e.g.
     * core_enrol_get_enrolled_users / core_course_get_contents / core_enrol_get_course_enrolment_methods all
     * need a `courseid`. Declared via `Configuration.parentScope = { parentWsFunction, paramName, parentIdField? }`.
     * The connector loads the parent ids from the parent's own list wsfunction, then fires ONE request per
     * parent — keyset-resumable over the parent ids (ctx.AfterKeyValue), bounded per call (engine loops until
     * HasMore=false), concurrency + rate-limit governed by the engine hooks. A per-parent failure (e.g. an
     * accessexception on one course) is surfaced as a warning, never fatal to the whole batch.
     *
     * TWO shapes of parent param, because Moodle uses both:
     *   • scalar — `courseid=12` (core_enrol_get_enrolled_users, core_course_get_contents)
     *   • array  — `cohortids[0]=12` (core_cohort_get_cohort_members, core_group_get_group_members)
     * Declared as `paramStyle: 'scalar' | 'array'` (default scalar). Sending the array functions a scalar is
     * what made `Cohort Members` fail `[invalidparameter]` on every run, with 0 records, since it shipped.
     *
     * The walk is also bounded IN TIME, not just in parent count. The engine kills a FetchChanges that
     * overruns `FetchChangesMs` (30000) and **a killed batch persists nothing** — `Enrolled Users` timed out
     * 3x and landed 0 rows behind a green run for exactly this reason: a page cap of N parents says nothing
     * about how long N vendor calls take. `parentScope.budgetMs` (default 20000, under the kill) stops
     * dispatching new parents and returns partial progress with a cursor, and the cursor advances only over
     * the contiguous PREFIX of parents that actually completed — out-of-order completions past the prefix are
     * still emitted (upserts are idempotent) but are not counted as covered. The first parent of a call never
     * skips, so a call always makes forward progress and the scan cannot stall.
     */
    /**
     * A stable, human-readable signature of a (possibly chained) parent scope — the cache key, and the value
     * reported when the chain is truncated. Deepest hop first, matching the order the requests actually go in.
     */
    private parentChainSignature(scope: Record<string, unknown>): string {
        const inner = this.readConfigObject(scope, 'parentScope');
        const here = `${this.readConfigString(scope, 'parentWsFunction') ?? '?'}.${this.readConfigString(scope, 'parentIdField') ?? 'id'}`;
        return inner ? `${this.parentChainSignature(inner)} -> ${here}` : here;
    }

    /**
     * Resolves the ids the object's own request will iterate, following a parent CHAIN when one is declared.
     *
     * A one-hop scope is the common case: call `parentWsFunction` bare and read `parentIdField` off each row.
     * But some Moodle read functions are reachable only through two hops, because the thing that lists their
     * parents is ITSELF parent-scoped. `core_group_get_group_members(groupids[])` is the live example: nothing
     * lists a site's groups, so the group ids come from `core_group_get_course_groups(courseid)`, whose course
     * ids come from `core_course_get_courses`. Declaring only the near hop leaves the object with no way to
     * name a single id, which is why these objects shipped unfetchable.
     *
     * A chain is expressed by nesting the SAME shape under `parentScope`, so each level reads exactly like the
     * top one: the outer level's `parentWsFunction` is called once per id produced by the inner level, passed
     * through the inner level's `paramName`/`paramStyle`. Depth is arbitrary; two is what the catalog needs.
     *
     * The expansion is bounded by the SAME budget as the walk, because it costs one request per id at each
     * hop — a 408-course site is 408 requests just to learn the group ids, which would otherwise be spent
     * inside the engine's 30000ms kill and land nothing. Running out of time returns what was resolved plus
     * `Truncated`, and the caller declines to cache a truncated list so the next call re-enumerates.
     */
    private async resolveParentIDs(
        auth: TotaraAuthContext,
        scope: Record<string, unknown>,
        timed: (send: () => Promise<RESTResponse>) => Promise<RESTResponse>,
        outOfTime: () => boolean,
    ): Promise<{ IDs: string[]; Truncated: boolean }> {
        const wsFn = this.readConfigString(scope, 'parentWsFunction');
        const idField = this.readConfigString(scope, 'parentIdField') ?? 'id';
        if (!wsFn) return { IDs: [], Truncated: false };

        const collect = (body: unknown): string[] => this.NormalizeResponse(body, null)
            .map(r => r[idField]).filter(v => v != null && String(v).length > 0).map(String);
        const dedupeSorted = (ids: string[]): string[] =>
            Array.from(new Set(ids)).sort((a, b) => a.localeCompare(b));

        const inner = this.readConfigObject(scope, 'parentScope');
        if (!inner) {
            const resp = await timed(() => this.MakeHTTPRequest(auth, auth.Endpoint, 'POST', this.BuildHeaders(auth),
                { WsFunction: wsFn, Params: {} } as MoodleRPCRequest));
            return { IDs: dedupeSorted(collect(resp.Body)), Truncated: false };
        }

        const upstream = await this.resolveParentIDs(auth, inner, timed, outOfTime);
        const innerParam = this.readConfigString(inner, 'paramName');
        if (!innerParam) return { IDs: [], Truncated: upstream.Truncated };
        const innerIsArray = this.readConfigString(inner, 'paramStyle') === 'array';

        const ids: string[] = [];
        let truncated = upstream.Truncated;
        for (let i = 0; i < upstream.IDs.length; i++) {
            // The first hop always runs, for the same reason the first parent of a walk always runs: a call
            // that resolves nothing makes no progress and the engine would loop on an empty list forever.
            if (i > 0 && outOfTime()) { truncated = true; break; }
            const params: Record<string, string | number> = innerIsArray
                ? { [`${innerParam}[0]`]: upstream.IDs[i] }
                : { [innerParam]: upstream.IDs[i] };
            try {
                const resp = await timed(() => this.MakeHTTPRequest(auth, auth.Endpoint, 'POST', this.BuildHeaders(auth),
                    { WsFunction: wsFn, Params: params } as MoodleRPCRequest));
                ids.push(...collect(resp.Body));
            } catch {
                // One upstream id the site will not answer for (a course whose groups the token cannot read)
                // must not abort the enumeration — the same rule the per-parent walk already follows. The hop
                // contributes nothing and the rest of the chain proceeds.
            }
        }
        return { IDs: dedupeSorted(ids), Truncated: truncated };
    }

    private async fetchParentScoped(
        obj: MJIntegrationObjectEntity,
        cfg: Record<string, unknown>,
        ctx: FetchContext,
        wsfunction: string,
        parentScope: Record<string, unknown>,
    ): Promise<FetchBatchResult> {
        const parentWsFn = this.readConfigString(parentScope, 'parentWsFunction');
        const paramName = this.readConfigString(parentScope, 'paramName');
        const parentIdField = this.readConfigString(parentScope, 'parentIdField') ?? 'id';
        const isArrayParam = this.readConfigString(parentScope, 'paramStyle') === 'array';
        const budgetMs = this.readConfigNonNegativeInt(parentScope, 'budgetMs') ?? DEFAULT_PARENT_WALK_BUDGET_MS;
        if (!parentWsFn || !paramName) {
            return { Records: [], HasMore: false, Warnings: [{ Code: 'PARENT_SCOPE_INCOMPLETE',
                Message: `"${obj.Name}": Configuration.parentScope requires parentWsFunction + paramName.`, Data: { object: obj.Name } }] };
        }

        // The field the CHILD row carries the parent id in. Defaults to the request param name, which is right
        // for scalar params (`courseid`) and wrong for array ones (the param is `cohortids`, the field is
        // `cohortid`) — so array-shaped scopes declare it.
        const childIdField = this.readConfigString(parentScope, 'childIdField') ?? paramName;

        // The budget is measured from HERE, not from the start of the walk. The engine's FetchChangesMs timer
        // starts when this method is entered, and the parent LIST call below is part of that: measuring only
        // the walk meant "parent list (however long) + a full 20s of walking", which overran the 30000ms kill
        // and was killed with 0 records — the exact failure this budget exists to prevent, still happening
        // with the budget in place. Every parent request now competes with the parent list for one budget.
        const startedAt = this.nowMs();
        /**
         * How long the slowest request of this call took. The deadline is enforced against work ABOUT TO
         * START, not work already done: measured live, `core_enrol_get_enrolled_users` needs ~26s for a
         * 250-user page, so "elapsed < budget" would happily start a request that lands 26s past it. Stopping
         * when `elapsed + slowest >= budget` is what keeps the call under the engine's kill.
         */
        let slowestRequestMs = 0;
        // Generic so EVERY await inside the walk can be measured, not just the ones that return a response.
        // The rate-limit acquire is the one that mattered: untimed, it let a call outrun its own budget by 53x.
        const timed = async <T>(step: () => Promise<T>): Promise<T> => {
            const t0 = this.nowMs();
            try { return await step(); } finally { slowestRequestMs = Math.max(slowestRequestMs, this.nowMs() - t0); }
        };
        const outOfTime = (): boolean => budgetMs > 0 && this.nowMs() - startedAt + slowestRequestMs >= budgetMs;

        const auth = await this.Authenticate(ctx.CompanyIntegration, ctx.ContextUser);
        const fields = this.GetCachedFields(obj.ID);
        const pkFieldNames = this.primaryKeyFieldNames(fields);
        const dropFields = this.dropFieldsFor(cfg);
        const warnings: NonNullable<FetchBatchResult['Warnings']> = [];

        // 1) Parent ids from the parent's list wsfunction (bare array or single-collection envelope), CACHED.
        //    The walk is resumed once per batch and the list does not change between them, but re-reading it
        //    is not free: `core_course_get_courses` measured 6.1s live, which every batch was paying out of a
        //    budget that has to fit inside a 30000ms kill. Cached, that time goes to reading records instead.
        const cacheKey = `${ctx.CompanyIntegration.ID}|${this.parentChainSignature(parentScope)}`;
        const cacheMs = this.readConfigNonNegativeInt(parentScope, 'parentCacheMs') ?? DEFAULT_PARENT_LIST_CACHE_MS;
        const cached = this.parentIDCache.get(cacheKey);
        let allParentIDs: string[];
        let parentsTruncated = false;
        if (cached && this.nowMs() - cached.At < cacheMs) {
            allParentIDs = cached.IDs;
        } else {
            const resolved = await this.resolveParentIDs(auth, parentScope, timed, outOfTime);
            allParentIDs = resolved.IDs;
            parentsTruncated = resolved.Truncated;
            // A truncated chain is an INCOMPLETE parent list. Caching it would freeze that partial view for
            // the whole cache window and make every later batch walk the same short list — the run would then
            // look complete while missing every parent the budget never reached.
            if (!parentsTruncated) this.parentIDCache.set(cacheKey, { IDs: allParentIDs, At: this.nowMs() });
        }
        if (parentsTruncated) {
            warnings.push({
                Code: 'PARENT_CHAIN_TRUNCATED',
                Message: `"${obj.Name}": the parent chain ran out of time while enumerating ids, so this call`
                    + ` walked ${allParentIDs.length} parent(s) rather than all of them. The chain is`
                    + ` re-enumerated (uncached) on the next call, so coverage is not lost — but a run that`
                    + ` never completes the chain will not reach every parent.`,
                Data: { object: obj.Name, resolvedParents: allParentIDs.length,
                        chain: this.parentChainSignature(parentScope) },
            });
        }
        if (allParentIDs.length === 0) {
            warnings.push({ Code: 'ZERO_PARENTS',
                Message: `"${obj.Name}": ${parentWsFn} returned no parent ids to iterate ${paramName} over — sync the parent first.`, Data: { object: obj.Name } });
            return { Records: [], HasMore: false, Warnings: warnings };
        }

        // 2) Keyset-resume + bounded batch over the parent ids. The cursor is either "<parentID>" (that parent
        //    is DONE, start after it) or "<parentID>#<offset>" (that parent is PARTLY read, resume AT it).
        const cursor = this.parseParentCursor(ctx.AfterKeyValue);
        // Resume AT the earliest parent that still has unread pages, and after `After` otherwise. Taking the
        // earliest of the partials (rather than the single one the old cursor could name) is what makes a
        // multi-lane stop resumable: every parent from there on either carries its own offset or starts at 0.
        const firstPartial = [...cursor.Partials.keys()]
            .map(id => allParentIDs.indexOf(id))
            .filter(i => i >= 0)
            .sort((a, b) => a - b)[0];
        const remaining = firstPartial != null
            ? allParentIDs.slice(firstPartial)
            : cursor.After != null
                ? allParentIDs.filter(id => id.localeCompare(cursor.After as string) > 0)
                : allParentIDs;
        const batch = remaining.slice(0, Math.max(1, this.TemplateVarParentBatchSize()));

        // Paging WITHIN one parent. Only for functions that document offset params (Enrolled Users declares
        // options.limitfrom/options.limitnumber); objects with an empty paginationParams read a parent in one
        // request as before. This is not an optimisation: `core_enrol_get_enrolled_users` returns every
        // enrolment on a course with full user profiles, and on a real site ONE such call outruns the engine's
        // 30000ms kill — at which point the batch persists nothing, which is how this object landed 0 rows on
        // every live run. A per-call budget cannot save a single request that is itself too big.
        const pageParams = this.readConfigStringArray(cfg, 'paginationParams') ?? [];
        const parentPageSize = pageParams.length >= 2
            ? Math.max(1, this.readConfigPositiveInt(parentScope, 'pageSize') ?? obj.DefaultPageSize ?? ctx.BatchSize)
            : 0;   // 0 = this function has no paging; one request per parent

        // 3) One request per parent (bounded concurrency + adaptive rate-limit via the engine hooks), inside a
        //    wall-clock budget so the call returns partial progress instead of being killed with nothing.
        const out: ExternalRecord[] = [];
        const collectionKeys = this.recordCollectionKeys(obj, cfg);
        /** Parents read to the END — successfully OR with a recorded warning. Both are "nothing left here". */
        const examined = new Set<number>();
        /** Parents stopped mid-way by the budget → the offset to resume that parent from. */
        const partial = new Map<number, number>();
        let skippedForBudget = 0;
        /** Parents the vendor refused on PERMISSIONS, attributed as one fact after the walk, not one each. */
        const forbidden: string[] = [];
        let forbiddenMessage: string | undefined;
        /** Parents that failed TRANSIENTLY this call → their new consecutive-failure count, carried on the cursor. */
        const transientFails = new Map<number, number>();
        /** Parents abandoned because they have now failed transiently `maxParentAttempts` times in a row. */
        const abandoned: Array<{ id: string; attempts: number; message: string }> = [];

        const ordering = parentPageSize > 0 ? this.readOffsetOrdering(cfg) : undefined;
        const maxAttempts = this.readConfigNonNegativeInt(parentScope, 'maxParentAttempts') ?? DEFAULT_MAX_PARENT_ATTEMPTS;

        /**
         * Paged walks keep the engine's concurrency, because every lane's offset now survives the stop.
         *
         * This was `parentPageSize > 0 ? 1 : …` — paged walks were forced serial to stop the 1.74x re-read, since
         * a single-slot cursor threw away every lane's offset but one. That fixed the waste by removing the
         * parallelism, which is a poor trade on an object whose healthy cost is 68ms per record and which has
         * never once been read to completion. {@link ParentCursor} carries an offset per parent, so the cause is
         * gone and the concurrency can come back.
         */
        const parentConcurrency = Math.max(1, ctx.MaxConcurrency ?? 1);

        await this.runParentBounded(batch.map((id, index) => ({ id, index })), parentConcurrency,
            async ({ id: parentID, index }) => {
                // Index 0 always runs: a call that skips every parent makes no progress and the engine would
                // loop on the same cursor forever. Everything after it yields to the budget.
                if (index > 0 && outOfTime()) { skippedForBudget++; return; }
                // Any parent may resume mid-way now — it reads its own offset rather than the one slot the
                // cursor used to have. A parent with no recorded offset starts at its beginning.
                let offset = cursor.Partials.get(parentID) ?? 0;
                let issuedRequest = false;
                try {
                    for (;;) {
                        /**
                         * The rate-limit wait counts against the budget, and is checked before the request.
                         *
                         * This await used to sit outside the deadline entirely: it was not passed through
                         * `timed`, so its wait never entered `slowestStepMs`, and nothing re-checked the clock
                         * after it. A throttled walk therefore blew its own budget without bound — the engine
                         * measured single `Enrolled Users` calls at up to **1,063,987ms** on run `9200B480`
                         * against a 20000ms budget the connector believed it was honouring, and 15 such calls
                         * consumed 3.30 of the run's 4.22 fetch-hours for 3.7% of its records. A deadline that
                         * only sees the awaits it happens to wrap is not a deadline.
                         */
                        if (ctx.RateLimitAcquire) await timed(() => ctx.RateLimitAcquire!());
                        // Gate the request itself, not just the next loop turn — except for the very first
                        // request of parent 0, which must always go out or the call makes no progress at all.
                        if (outOfTime() && !(index === 0 && !issuedRequest)) {
                            if (offset > 0 || issuedRequest) partial.set(index, offset);
                            else skippedForBudget++;
                            return;
                        }
                        const params: Record<string, string | number> = isArrayParam
                            ? { [`${paramName}[0]`]: parentID }
                            : { [paramName]: parentID };
                        if (parentPageSize > 0) this.applyOffsetPagination(params, pageParams, offset, parentPageSize, ordering);
                        const resp = await timed(() => this.MakeHTTPRequest(auth, auth.Endpoint, 'POST', this.BuildHeaders(auth),
                            { WsFunction: wsfunction, Params: params } as MoodleRPCRequest));
                        issuedRequest = true;
                        let pageCount = 0;
                        for (const key of collectionKeys) {
                            for (const raw of this.NormalizeResponse(resp.Body, key)) {
                                // tag the child with the parent FK so its row links back to the parent record
                                const tagged = raw[childIdField] != null ? raw : { ...raw, [childIdField]: parentID };
                                out.push(this.buildExternalRecord(DropConfiguredFields(this.applyTransformPreservingKeys(tagged, obj, fields), dropFields), ctx.ObjectName, pkFieldNames));
                                pageCount++;
                            }
                        }
                        ctx.RateLimitReport?.();
                        // Unpaged function, or a short page → this parent is exhausted.
                        if (parentPageSize === 0 || pageCount < parentPageSize) break;
                        offset += pageCount;
                        // Mid-parent budget stop: record where to resume rather than dropping the rest.
                        if (outOfTime()) { partial.set(index, offset); return; }
                    }
                    examined.add(index);
                } catch (e) {
                    const msg = e instanceof Error ? e.message : String(e);
                    if (/429|rate.?limit|Retry-After/i.test(msg)) { ctx.RateLimitReport?.(e); throw e; }  // rate-limit → propagate for backoff
                    /**
                     * A TRANSIENT failure must not advance the cursor over its parent.
                     *
                     * Every caught error used to end with `examined.add(index)`, which marks the parent "nothing
                     * left here" and lets the cursor move past it. For a permission refusal that is correct — the
                     * token will not be granted mid-run. For a 25000ms read timeout it is **silent data loss**:
                     * run `9200B480` aborted 24 requests that way, including `courseid=1 (offset 18850)`, and
                     * each one retired a course whose enrolments had not been fully read, behind a green run.
                     *
                     * So a transient failure keeps the parent's offset and counts an attempt on the cursor. The
                     * bounded count is what stops this becoming the opposite bug (the `Users` `[invalidresponse]`
                     * deadlock: 61 identical failures and no forward progress possible).
                     */
                    if (/did not respond within|\bETIMEDOUT\b|\bECONNRESET\b|\bECONNREFUSED\b|\bEAI_AGAIN\b|socket hang up|fetch failed|network|\b5\d\d\b/i.test(msg)) {
                        const attempts = (cursor.Fails.get(parentID) ?? 0) + 1;
                        if (attempts >= maxAttempts) {
                            abandoned.push({ id: parentID, attempts, message: msg });
                            examined.add(index);   // give up deliberately, and say so — never silently
                        } else {
                            transientFails.set(index, attempts);
                            if (offset > 0) partial.set(index, offset);
                        }
                        return;
                    }
                    // A permission refusal is not a fetch error. Moodle answers `[accessexception]` for a
                    // function the token may not call at all, and it answers it for EVERY parent — so the
                    // per-parent error is the wrong grain: it says "52 things went wrong" about one credential
                    // that was never granted. Counted here, attributed once below.
                    if (/\[accessexception\]|\[requiredcapability\]|\[nopermission\]/i.test(msg)) {
                        forbidden.push(parentID);
                        forbiddenMessage ??= msg;
                    } else {
                        warnings.push({ Code: 'PARENT_FETCH_ERROR', Message: `"${obj.Name}" fetch for ${paramName}=${parentID}${offset ? ` (offset ${offset})` : ''}: ${msg}`, Data: { object: obj.Name, [paramName]: parentID, offset } });
                    }
                    examined.add(index);
                }
            });

        // Every parent this call reached was refused on permissions, and nothing was read. That is a credential
        // scope limit stated as one fact — the same grain OpenWater's `LEAF_FORBIDDEN` uses — rather than N
        // fetch errors that read like N separate faults. A PARTIAL refusal stays per-parent (below), because
        // "some courses' groups are readable" is genuinely different from "this function is not granted".
        if (forbidden.length > 0 && out.length === 0 && forbidden.length === examined.size) {
            warnings.push({
                Code: 'LEAF_FORBIDDEN',
                Message: `"${obj.Name}": ${wsfunction} refused every one of the ${forbidden.length} ${paramName}`
                    + ` value(s) this call reached — the token is not permitted this function on this site.`
                    + ` The parent chain resolved fine (${allParentIDs.length} parent id(s)), so this is a`
                    + ` credential scope limit, not a request-shape or empty-data result. Vendor: ${forbiddenMessage}`,
                Data: { object: obj.Name, wsfunction, refusedParents: forbidden.length,
                        resolvedParents: allParentIDs.length, sample: forbidden.slice(0, 5) },
            });
        } else if (forbidden.length > 0) {
            warnings.push({
                Code: 'LEAF_FORBIDDEN',
                Message: `"${obj.Name}": ${forbidden.length} of the ${examined.size} ${paramName} value(s) this`
                    + ` call reached were refused on permissions; the rest were read. Vendor: ${forbiddenMessage}`,
                Data: { object: obj.Name, wsfunction, refusedParents: forbidden.length,
                        examined: examined.size, sample: forbidden.slice(0, 5) },
            });
        }

        // A parent abandoned after repeated transient failures is stated, with the vendor's own words and the
        // attempt count. It is the one place the walk knowingly leaves records unread, so it must never be
        // quiet about it — and it names the parent so an operator can go and look at that course.
        if (abandoned.length > 0) {
            warnings.push({
                Code: 'PARENT_ABANDONED',
                Message: `"${obj.Name}": ${abandoned.length} ${paramName} value(s) failed ${maxAttempts} times in a`
                    + ` row on transport errors and were passed over so the walk can continue —`
                    + ` ${abandoned.slice(0, 5).map(a => a.id).join(', ')}. Their records are NOT synced. This is`
                    + ` usually a vendor-side slow response for that parent (raise requestTimeoutMs, or`
                    + ` parentScope.maxParentAttempts, if it is legitimately slow). Vendor: ${abandoned[0].message}`,
                Data: { object: obj.Name, wsfunction, abandoned: abandoned.length, maxAttempts,
                        sample: abandoned.slice(0, 5).map(a => ({ [paramName]: a.id, attempts: a.attempts })) },
            });
        }

        // The cursor may only advance over the contiguous prefix that was examined. A parent past a
        // budget-skipped one may well have completed (concurrency finishes out of order) and its records are
        // kept — upserts are idempotent — but claiming it as covered would silently drop the skipped parent.
        let covered = 0;
        while (covered < batch.length && examined.has(covered)) covered++;

        // Every parent at or past the covered prefix that holds mid-parent progress, or a transient-failure
        // count, is carried by id. Entries before the prefix are dropped: those parents are finished, and
        // keeping their state would resume a walk into ground it has already covered.
        const carriedPartials = new Map<string, number>();
        for (const [index, off] of partial) if (index >= covered) carriedPartials.set(batch[index], off);
        const carriedFails = new Map<string, number>();
        for (const [index, n] of transientFails) if (index >= covered) carriedFails.set(batch[index], n);

        const resumeOffset = partial.get(covered);
        const stopped = skippedForBudget > 0 || partial.size > 0;
        if (stopped) {
            warnings.push({
                Code: 'PARENT_BUDGET_STOP',
                Message: `"${obj.Name}": stopped after ${covered} of ${batch.length} ${paramName} values`
                    + (resumeOffset != null ? ` (plus ${resumeOffset} records into the next)` : '')
                    + (partial.size > 1 ? ` and ${partial.size} partly-read parent(s) whose offsets are carried` : '')
                    + ` on the ${budgetMs}ms budget — resuming from there.`,
                Data: { object: obj.Name, covered, batch: batch.length, skipped: skippedForBudget,
                        resumeOffset: resumeOffset ?? null, partlyRead: partial.size, budgetMs },
            });
        }

        // A parent held back for a retry is not covered, so the walk still has work even if the prefix reached
        // the end of the batch — otherwise a transient failure on the last parent would end the walk early.
        const hasMore = remaining.length > covered || carriedFails.size > 0 || carriedPartials.size > 0;
        return {
            Records: out,
            HasMore: hasMore,
            NextAfterKeyValue: !hasMore ? undefined
                : this.serializeParentCursor(covered > 0 ? batch[covered - 1] : null, carriedPartials, carriedFails),
            Warnings: warnings.length ? warnings : undefined,
        };
    }

    /**
     * Reads a parent-walk cursor.
     *
     * Three wire forms, all still parsed, because an in-flight walk must resume rather than restart:
     *
     * - `"<id>"` — that parent is finished; start after it.
     * - `"<id>#<offset>"` — that parent is partly read; resume AT it from that offset. **One** parent only.
     * - `'{"a":"<id>","p":{"<id>":<offset>},"f":{"<id>":<n>}}'` — the extended form: `a` is the finished-through
     *   parent, `p` maps ANY parent to its mid-parent offset, `f` counts consecutive transient failures per
     *   parent.
     *
     * The extended form exists because the single-slot form is what made paged walks serial. Only the head of
     * the covered prefix could carry an offset (pointing anywhere else would claim a budget-skipped parent as
     * done), so when N parents were read concurrently and the budget stopped them all mid-way, N-1 offsets were
     * thrown away and those parents restarted from 0 on the next call — every call, forever. Measured live on
     * `Enrolled Users` (run `9200B480`, `MaxConcurrency: 2`): 50,608 records fetched for 29,002 rows, a 1.74x
     * re-read that was entirely the discarded lane. Carrying every lane's offset fixes the cause, which is what
     * lets the walk keep the engine's concurrency instead of trading throughput for correctness.
     *
     * JSON rather than more delimiters: parent ids are vendor strings and a `;`/`,` scheme cannot be made safe
     * against one that contains the delimiter. The legacy forms are still EMITTED whenever they suffice, so a
     * cursor only grows when the walk actually has multi-lane state to carry.
     */
    private parseParentCursor(raw: string | null | undefined): ParentCursor {
        const empty: ParentCursor = { After: null, Partials: new Map(), Fails: new Map() };
        if (!raw) return empty;

        if (raw.startsWith('{')) {
            try {
                const p = JSON.parse(raw) as { a?: unknown; p?: unknown; f?: unknown };
                const nums = (v: unknown): Map<string, number> => {
                    const m = new Map<string, number>();
                    if (v && typeof v === 'object') {
                        for (const [k, n] of Object.entries(v as Record<string, unknown>)) {
                            const parsed = typeof n === 'number' ? n : Number.parseInt(String(n), 10);
                            if (Number.isFinite(parsed) && parsed >= 0) m.set(k, parsed);
                        }
                    }
                    return m;
                };
                return {
                    After: typeof p.a === 'string' && p.a.length > 0 ? p.a : null,
                    Partials: nums(p.p),
                    Fails: nums(p.f),
                };
            } catch {
                // A cursor we cannot read must not be guessed at: restarting the walk re-reads (idempotent
                // upserts) where a mis-parse could skip parents outright.
                return empty;
            }
        }

        const hash = raw.lastIndexOf('#');
        if (hash < 0) return { After: raw, Partials: new Map(), Fails: new Map() };
        const offset = Number.parseInt(raw.slice(hash + 1), 10);
        if (!Number.isFinite(offset) || offset < 0) return { After: raw.slice(0, hash), Partials: new Map(), Fails: new Map() };
        return { After: null, Partials: new Map([[raw.slice(0, hash), offset]]), Fails: new Map() };
    }

    /**
     * Writes the cursor back, preferring the legacy forms so it stays human-readable and short whenever there
     * is no multi-lane state to carry. `After` is the parent finished through; `partials`/`fails` are keyed by
     * parent id and must only ever describe parents at or past the covered prefix.
     */
    private serializeParentCursor(after: string | null, partials: Map<string, number>, fails: Map<string, number>): string | undefined {
        if (partials.size === 0 && fails.size === 0) return after ?? undefined;
        if (fails.size === 0 && partials.size === 1 && after == null) {
            const [id, offset] = [...partials.entries()][0];
            return `${id}#${offset}`;
        }
        const payload: { a?: string; p?: Record<string, number>; f?: Record<string, number> } = {};
        if (after != null) payload.a = after;
        if (partials.size > 0) payload.p = Object.fromEntries(partials);
        if (fails.size > 0) payload.f = Object.fromEntries(fails);
        return JSON.stringify(payload);
    }

    /** Wall clock, isolated so the budget is testable without fake timers. */
    protected nowMs(): number {
        return Date.now();
    }

    /**
     * Bounded id-window scan for objects whose list function cannot be bulk-listed.
     *
     * WHY THIS EXISTS. `core_user_get_users` declares no pagination params, and the Totara/Moodle docs are
     * explicit: "You can search without criteria, but the function is not designed for it. It could [be] very
     * slow or timeout" — and the `%` wildcard "may be considerably slower". Asking it for every user in one
     * shot (criteria email=%) is therefore a request the server is documented to be unable to satisfy: against
     * a real-sized site it never returns inside the engine's FetchChangesMs budget, the batch is killed, and the
     * object syncs ZERO rows behind an otherwise-green run. Observed live: 3x 30s timeouts, 0 users.
     *
     * WHAT THIS DOES INSTEAD. Walks the id space in bounded windows against the documented BULK reader
     * (`core_user_get_users_by_field`, field=id, values[]) — an indexed primary-key lookup rather than a search.
     *
     * The scan itself is NOT Totara-specific and does not live here: `runIdWindowScan` in
     * `@memberjunction/connector-id-window-scan` owns the windowing, the fetch budget, the bisection that
     * isolates records the vendor refuses, and the resume cursor. This method supplies only the two things that
     * ARE Totara-specific — how to turn a list of ids into a Moodle RPC call, and how to map the raw rows back
     * into `ExternalRecord`s. Any connector facing the same "the list endpoint cannot list" shape imports the
     * same helper rather than reimplementing it.
     */
    private async fetchIdWindowScan(
        obj: MJIntegrationObjectEntity,
        _cfg: Record<string, unknown>,
        ctx: FetchContext,
        scan: Record<string, unknown>,
    ): Promise<FetchBatchResult> {
        const scanWsFn = this.readConfigString(scan, 'wsFunction');
        const field = this.readConfigString(scan, 'field') ?? 'id';
        if (!scanWsFn) {
            return { Records: [], HasMore: false, Warnings: [{ Code: 'ID_WINDOW_SCAN_INCOMPLETE',
                Message: `"${obj.Name}": Configuration.idWindowScan requires wsFunction.`, Data: { object: obj.Name } }] };
        }

        const auth = await this.Authenticate(ctx.CompanyIntegration, ctx.ContextUser);
        const fields = this.GetCachedFields(obj.ID);
        const pkFieldNames = this.primaryKeyFieldNames(fields);
        const dropFields = this.dropFieldsFor(_cfg);

        const result = await runIdWindowScan({
            ObjectName: obj.Name,
            Config: {
                field,
                windowSize: this.readConfigPositiveInt(scan, 'windowSize') ?? undefined,
                windowsPerCall: this.readConfigPositiveInt(scan, 'windowsPerCall') ?? undefined,
                maxConsecutiveEmptyWindows: this.readConfigPositiveInt(scan, 'maxConsecutiveEmptyWindows') ?? undefined,
                // Non-negative (not positive): budgetMs=0 is meaningful — "spend no time beyond the first
                // window" — and it is what makes the deadline deterministically testable.
                budgetMs: this.readConfigNonNegativeInt(scan, 'budgetMs') ?? undefined,
                maxBisectSplitsPerCall: this.readConfigPositiveInt(scan, 'maxBisectSplitsPerCall') ?? undefined,
            },
            AfterKeyValue: ctx.AfterKeyValue,
            MaxConcurrency: ctx.MaxConcurrency,
            RateLimitAcquire: ctx.RateLimitAcquire,
            RateLimitReport: ctx.RateLimitReport,
            // Moodle takes the id list as bracket-notation params. NormalizeResponse THROWS on an in-band
            // Moodle exception envelope, which is exactly the signal the scan bisects on — so it must not be
            // caught here.
            FetchWindow: async (ids: number[]): Promise<Record<string, unknown>[]> => {
                const params: Record<string, string | number> = { field };
                ids.forEach((id, i) => { params[`values[${i}]`] = id; });
                const resp = await this.MakeHTTPRequest(auth, auth.Endpoint, 'POST', this.BuildHeaders(auth),
                    { WsFunction: scanWsFn, Params: params } as MoodleRPCRequest);
                return this.NormalizeResponse(resp.Body, null);
            },
        });

        return {
            Records: result.Records.map((raw) =>
                this.buildExternalRecord(DropConfiguredFields(this.applyTransformPreservingKeys(raw, obj, fields), dropFields), ctx.ObjectName, pkFieldNames)),
            HasMore: result.HasMore,
            ...(result.NextAfterKeyValue !== undefined ? { NextAfterKeyValue: result.NextAfterKeyValue } : {}),
            ...(result.Warnings ? { Warnings: result.Warnings } : {}),
        };
    }


    /** Bounded-concurrency runner (the base's RunBounded is private). Single-threaded async → array pushes are safe. */
    private async runParentBounded<T>(items: T[], concurrency: number, worker: (item: T) => Promise<void>): Promise<void> {
        let i = 0;
        const lanes = Array.from({ length: Math.min(Math.max(1, concurrency), Math.max(1, items.length)) }, async () => {
            while (i < items.length) { const idx = i++; await worker(items[idx]); }
        });
        await Promise.all(lanes);
    }

    // ── CRUD — Moodle bracket-notation urlencoded array bodies ────────

    /**
     * Create via the object's `Configuration.writeFunctions.create` wsfunction, encoding the record as a
     * Moodle bracket-notation array (`<param>[0][field]=...`). The new id is read from the response per
     * `createResponseIDField`; association creates (no server id) synthesize a deterministic identity from the
     * sent attributes. EITHER way the result routes through {@link BuildCreatedResult} so an empty id fails
     * LOUDLY — never a hand-built `{Success:true, ExternalID:''}`.
     */
    public override async CreateRecord(ctx: CreateRecordContext): Promise<CRUDResult> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const contextUser = ctx.ContextUser as UserInfo;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        if (!obj.CreateAPIPath || !obj.CreateMethod) {
            throw new Error(
                `CreateRecord not supported for "${ctx.ObjectName}": CreateAPIPath / CreateMethod not configured on IntegrationObject.`,
            );
        }
        const cfg = this.readIOConfig(obj);
        const wf = this.readWriteFunctions(cfg);
        const action = this.readConfigString(wf, 'create');
        if (!action) {
            return { Success: false, StatusCode: 400, ErrorMessage: `CreateRecord for "${ctx.ObjectName}": Configuration.writeFunctions.create not configured.` };
        }

        try {
            const fields = this.GetCachedFields(obj.ID);
            const attrs = this.filterWritable(ctx.Attributes, fields);
            const arrayParam = this.resolveWriteArrayParam(cfg, wf, action);
            const params = this.bracketEncodeRecord(arrayParam, attrs);
            const response = await this.postWrite(ci, contextUser, action, params);

            const inBandError = this.detectMoodleError(response.Body);
            if (inBandError) {
                return { Success: false, StatusCode: response.Status, ErrorMessage: `CreateRecord failed for ${ctx.ObjectName}: ${inBandError}` };
            }

            const idField = this.readConfigString(wf, 'createResponseIDField');
            const externalID = idField
                ? this.extractCreatedId(response.Body, idField)
                : this.synthesizeAssociationId(attrs); // association create (no server id) → deterministic identity
            return this.BuildCreatedResult(externalID, response.Status, ctx.ObjectName);
        } catch (err: unknown) {
            return this.buildCRUDError(err, 'CreateRecord', ctx.ObjectName);
        }
    }

    /**
     * Update via `Configuration.writeFunctions.update`, injecting the target ExternalID under the object's PK
     * field name inside the bracket-notation array body.
     */
    public override async UpdateRecord(ctx: UpdateRecordContext): Promise<CRUDResult> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const contextUser = ctx.ContextUser as UserInfo;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        if (!obj.UpdateAPIPath || !obj.UpdateMethod) {
            throw new Error(
                `UpdateRecord not supported for "${ctx.ObjectName}": UpdateAPIPath / UpdateMethod not configured on IntegrationObject.`,
            );
        }
        const cfg = this.readIOConfig(obj);
        const wf = this.readWriteFunctions(cfg);
        const action = this.readConfigString(wf, 'update');
        if (!action) {
            return { Success: false, StatusCode: 400, ErrorMessage: `UpdateRecord for "${ctx.ObjectName}": Configuration.writeFunctions.update not configured.` };
        }

        try {
            const fields = this.GetCachedFields(obj.ID);
            const attrs = this.filterWritable(ctx.Attributes, fields);
            const pkName = this.updateIdFieldName(wf, fields);
            if (attrs[pkName] === undefined) attrs[pkName] = ctx.ExternalID;
            const arrayParam = this.resolveWriteArrayParam(cfg, wf, action);
            const params = this.bracketEncodeRecord(arrayParam, attrs);
            const response = await this.postWrite(ci, contextUser, action, params);

            const inBandError = this.detectMoodleError(response.Body);
            if (inBandError) {
                return { Success: false, StatusCode: response.Status, ErrorMessage: `UpdateRecord failed for ${ctx.ObjectName}: ${inBandError}` };
            }
            return { Success: true, StatusCode: response.Status, ExternalID: ctx.ExternalID };
        } catch (err: unknown) {
            return this.buildCRUDError(err, 'UpdateRecord', ctx.ObjectName);
        }
    }

    /**
     * Delete via `Configuration.writeFunctions.delete` (verb NOT assumed — some are unenrol/remove), sending
     * the target ExternalID in the Moodle ids array (`<param>ids[0]=<id>`).
     */
    public override async DeleteRecord(ctx: DeleteRecordContext): Promise<CRUDResult> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const contextUser = ctx.ContextUser as UserInfo;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        if (!obj.DeleteAPIPath || !obj.DeleteMethod) {
            throw new Error(
                `DeleteRecord not supported for "${ctx.ObjectName}": DeleteAPIPath / DeleteMethod not configured on IntegrationObject.`,
            );
        }
        const cfg = this.readIOConfig(obj);
        const wf = this.readWriteFunctions(cfg);
        const action = this.readConfigString(wf, 'delete');
        if (!action) {
            return { Success: false, StatusCode: 400, ErrorMessage: `DeleteRecord for "${ctx.ObjectName}": Configuration.writeFunctions.delete not configured.` };
        }

        try {
            const idsParam = this.resolveDeleteIdsParam(wf, action);
            const params: Record<string, string | number> = { [`${idsParam}[0]`]: ctx.ExternalID };
            const response = await this.postWrite(ci, contextUser, action, params);

            const inBandError = this.detectMoodleError(response.Body);
            if (inBandError) {
                return { Success: false, StatusCode: response.Status, ErrorMessage: `DeleteRecord failed for ${ctx.ObjectName}: ${inBandError}` };
            }
            return { Success: true, StatusCode: response.Status, ExternalID: ctx.ExternalID };
        } catch (err: unknown) {
            return this.buildCRUDError(err, 'DeleteRecord', ctx.ObjectName);
        }
    }

    /** Shared write POST: authenticate + dispatch the wsfunction with the given (already-bracketed) params. */
    private async postWrite(
        ci: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
        action: string,
        params: Record<string, string | number>,
    ): Promise<RESTResponse> {
        const auth = await this.Authenticate(ci, contextUser);
        const request: MoodleRPCRequest = { WsFunction: action, Params: params };
        return this.MakeHTTPRequest(auth, auth.Endpoint, 'POST', this.BuildHeaders(auth), request);
    }

    // ── Read-param construction ───────────────────────────────────────

    /** Builds the read request params: declared scope args + pagination (Offset limitfrom / PageNumber page). */
    private buildReadParams(
        obj: MJIntegrationObjectEntity,
        cfg: Record<string, unknown>,
        ctx: FetchContext,
        page: number,
        offset: number,
        pageSize: number,
    ): Record<string, string | number> {
        const params: Record<string, string | number> = {};
        this.applyScopeArgs(params, obj, cfg, ctx.CompanyIntegration);

        if (!obj.SupportsPagination || obj.PaginationType === 'None') return params;
        const pagParams = this.readConfigStringArray(cfg, 'paginationParams') ?? [];
        if (obj.PaginationType === 'Offset') {
            this.applyOffsetPagination(params, pagParams, offset, pageSize);
        } else if (obj.PaginationType === 'PageNumber') {
            this.applyPageNumberPagination(params, pagParams, page, pageSize);
        }
        return params;
    }

    /**
     * Merges declared scope args for functions that require a parent scope (e.g. a courseid / userid /
     * groupids). Two sources, both metadata-driven (never guessed): the IO's own `Configuration.defaultArgs`,
     * and a per-connection `Configuration.objectArgs["<ObjectName>"]` override. Absent → nothing added; a
     * scope-requiring function then returns a Moodle exception, surfaced (not swallowed) by NormalizeResponse.
     */
    private applyScopeArgs(
        params: Record<string, string | number>,
        obj: MJIntegrationObjectEntity,
        cfg: Record<string, unknown>,
        companyIntegration: MJCompanyIntegrationEntity,
    ): void {
        const merge = (src: Record<string, unknown> | null): void => {
            if (!src) return;
            for (const [k, v] of Object.entries(src)) {
                if (typeof v === 'string' || typeof v === 'number') params[k] = v;
            }
        };
        merge(this.readConfigObject(cfg, 'defaultArgs'));
        const connCfg = this.parseConnectionConfig(companyIntegration);
        const objectArgs = this.readConfigObject(connCfg, 'objectArgs');
        if (objectArgs) merge(this.readConfigObject(objectArgs, obj.Name));
    }

    /**
     * Offset pagination. `paginationParams` = [fromName, countName]. A dotted name (`options.limitfrom`) is a
     * Moodle options-array param → emitted as `options[i][name]=limitfrom&options[i][value]=<n>`; a flat name
     * is emitted directly. `countName` may carry alternates (`limitnum|limitnumber`) — the first is used.
     */
    private applyOffsetPagination(
        params: Record<string, string | number>,
        pagParams: string[],
        offset: number,
        pageSize: number,
        ordering?: OffsetOrdering,
    ): void {
        const fromRaw = pagParams[0] ?? 'limitfrom';
        const countRaw = (pagParams[1] ?? 'limitnum').split('|')[0];
        const pairs: Array<[string, string | number]> = [[fromRaw, offset], [countRaw, pageSize]];
        // Ordering rides in the SAME option array as the limits, which is why it is written here rather than
        // by a second helper: a separate helper would start its own bracket indexes at 0 and overwrite the
        // limits it was meant to accompany.
        if (ordering) pairs.push([ordering.SortByParam, ordering.Key], [ordering.SortDirectionParam, ordering.Direction]);
        if (fromRaw.includes('.')) {
            const prefix = fromRaw.slice(0, fromRaw.indexOf('.'));
            const short = (n: string): string => (n.includes('.') ? n.slice(n.indexOf('.') + 1) : n);
            pairs.forEach(([name, value], i) => {
                params[`${prefix}[${i}][name]`] = short(name);
                params[`${prefix}[${i}][value]`] = value;
            });
        } else {
            for (const [name, value] of pairs) params[name] = value;
        }
    }

    /**
     * The declared stable ordering for an offset-paged read, or `undefined` when the object declares none.
     *
     * WHY THIS IS NOT OPTIONAL POLISH. `limitfrom`/`limitnumber` is SQL `OFFSET`/`LIMIT`, and an offset over a
     * result set with no `ORDER BY` has no defined page boundary: consecutive pages may repeat rows and, worse,
     * may never return others at all. Measured live on `Enrolled Users` (run `9200B480`): 50,608 records fetched
     * produced 29,002 distinct keyed rows — a 1.74x re-read — behind a run that reported success. Overlap costs
     * time; the gaps are silent data loss.
     *
     * Every object in this catalog already declares `stableOrderingKey`, and Totara/Moodle documents `sortby` +
     * `sortdirection` next to `limitfrom`/`limitnumber` on the paged functions. Both halves existed; nothing
     * joined them. Objects that declare no `orderingParams` are unchanged — the option names are per-function
     * and are read from the catalog, never guessed.
     */
    private readOffsetOrdering(cfg: Record<string, unknown>): OffsetOrdering | undefined {
        const orderParams = this.readConfigStringArray(cfg, 'orderingParams') ?? [];
        const key = this.readConfigString(cfg, 'stableOrderingKey');
        if (orderParams.length < 2 || !orderParams[0] || !orderParams[1] || !key) return undefined;
        return {
            SortByParam: orderParams[0],
            SortDirectionParam: orderParams[1],
            Key: key,
            Direction: this.readConfigString(cfg, 'orderingDirection') ?? 'ASC',
        };
    }

    /** PageNumber pagination. `paginationParams` = [pageName, sizeName?]; sizeName is optional (`page` alone). */
    private applyPageNumberPagination(
        params: Record<string, string | number>,
        pagParams: string[],
        page: number,
        pageSize: number,
    ): void {
        const pageName = pagParams[0] ?? 'page';
        params[pageName] = page;
        const sizeName = pagParams[1];
        if (sizeName) params[sizeName] = pageSize;
    }

    // ── Write-body encoding helpers ───────────────────────────────────

    /**
     * The Moodle array-parameter name for a write body. Resolution (metadata-driven, never a baked catalog):
     * (1) an explicit `Configuration.writeFunctions.arrayParam`; (2) the bracket prefix of a declared
     * `updateIDField`/`deleteIDField` (e.g. `courses[0][id]` → `courses`); (3) the trailing plural token of
     * the write function name (`core_user_create_users` → `users`). Genuinely-idiosyncratic association params
     * (enrolments, members) should carry an explicit `arrayParam` override — see CODE_REPORT.md.
     */
    private resolveWriteArrayParam(cfg: Record<string, unknown>, wf: Record<string, unknown>, action: string): string {
        const explicit = this.readConfigString(wf, 'arrayParam') ?? this.readConfigString(cfg, 'writeArrayParam');
        if (explicit) return explicit;
        const fromField = this.bracketPrefix(this.readConfigString(wf, 'updateIDField'));
        if (fromField) return fromField;
        return this.deriveArrayParamFromFunction(action);
    }

    /** The Moodle ids-array parameter for a delete/unenrol/remove call (e.g. `courseids`). */
    private resolveDeleteIdsParam(wf: Record<string, unknown>, action: string): string {
        const fromField = this.bracketPrefix(this.readConfigString(wf, 'deleteIDField'));
        if (fromField) return fromField;
        const explicit = this.readConfigString(wf, 'idsParam');
        if (explicit) return explicit;
        // e.g. core_course_delete_courses → courses → courseids (Moodle's delete-id array naming).
        const plural = this.deriveArrayParamFromFunction(action);
        return plural.endsWith('s') ? `${plural.slice(0, -1)}ids` : `${plural}ids`;
    }

    /** Trailing plural token of a Moodle wsfunction name (`core_user_create_users` → `users`). */
    private deriveArrayParamFromFunction(action: string): string {
        const m = action.match(/_(?:create|update|add|enrol|unenrol|delete)_(.+)$/);
        if (m) {
            const tail = m[1];
            // The bracket param is the last underscore-segment for the common record objects.
            const seg = tail.split('_').pop();
            return seg ?? tail;
        }
        return 'records';
    }

    /** The `[0][id]` prefix of a bracketed id-field path (`courses[0][id]` → `courses`; `courseids[0]` → `courseids`). */
    private bracketPrefix(idField: string | null): string | null {
        if (!idField) return null;
        const idx = idField.indexOf('[');
        const prefix = idx > 0 ? idField.slice(0, idx) : idField;
        return prefix.trim().length > 0 ? prefix.trim() : null;
    }

    /** The field name the ExternalID goes under on update (from a declared `updateIDField`, else the PK, else `id`). */
    private updateIdFieldName(wf: Record<string, unknown>, fields: MJIntegrationObjectFieldEntity[]): string {
        const declared = this.readConfigString(wf, 'updateIDField');
        if (declared) {
            const m = declared.match(/\[([^\]]+)\]\s*$/); // last bracket segment: courses[0][id] → id
            if (m) return m[1];
        }
        const pk = fields.filter(f => f.IsPrimaryKey).sort((a, b) => a.Sequence - b.Sequence)[0];
        return pk ? pk.Name : 'id';
    }

    /** Recursively renders a record into Moodle bracket-notation params under `<arrayParam>[0]`. */
    private bracketEncodeRecord(arrayParam: string, attrs: Record<string, unknown>): Record<string, string | number> {
        const out: Record<string, string | number> = {};
        this.bracketEncode(`${arrayParam}[0]`, attrs, out);
        return out;
    }

    private bracketEncode(prefix: string, value: unknown, out: Record<string, string | number>): void {
        if (value == null) return;
        if (Array.isArray(value)) {
            value.forEach((v, i) => this.bracketEncode(`${prefix}[${i}]`, v, out));
        } else if (typeof value === 'object') {
            for (const [k, v] of Object.entries(value as Record<string, unknown>)) {
                this.bracketEncode(`${prefix}[${k}]`, v, out);
            }
        } else if (typeof value === 'boolean') {
            out[prefix] = value ? 1 : 0; // Moodle booleans are int 1/0
        } else {
            out[prefix] = value as string | number;
        }
    }

    /** Drops IsReadOnly source fields from a write body (respects the read-only constraint). */
    private filterWritable(attrs: Record<string, unknown>, fields: MJIntegrationObjectFieldEntity[]): Record<string, unknown> {
        const readOnly = new Set(fields.filter(f => f.IsReadOnly).map(f => f.Name));
        if (readOnly.size === 0) return { ...attrs };
        return Object.fromEntries(Object.entries(attrs).filter(([k]) => !readOnly.has(k)));
    }

    // ── Response / record shaping ──────────────────────────────────────

    /**
     * Collection keys to extract from a read response, resolved in priority order:
     *   1. `Configuration.recordCollectionKeys` — multi-collection union (e.g. Notes' sitenotes+coursenotes+
     *      personalnotes), when the frozen metadata declares it.
     *   2. The first-class `ResponseDataKey` COLUMN — the canonical "where the return wraps records" slot
     *      (connector-code-conventions §4 / frozen-contract requirement). This is authoritative: the current
     *      Totara metadata carries the envelope key HERE (`users`, `statuses`, `items`, …) with
     *      `Configuration.responseEnvelopeKey` null, so the column MUST be read or a `{users:[…]}` envelope
     *      would be mis-emitted as a single wrapper record instead of the N wrapped records.
     *   3. `Configuration.responseEnvelopeKey` — backward-compatible fallback for older metadata shapes.
     * A resolved `null` means the body is a bare top-level array.
     */
    private recordCollectionKeys(obj: MJIntegrationObjectEntity, cfg: Record<string, unknown>): (string | null)[] {
        const multi = this.readConfigStringArray(cfg, 'recordCollectionKeys');
        if (multi && multi.length > 0) return multi;
        const column = typeof obj.ResponseDataKey === 'string' && obj.ResponseDataKey.trim().length > 0
            ? obj.ResponseDataKey.trim()
            : null;
        return [column ?? this.readConfigString(cfg, 'responseEnvelopeKey')];
    }

    private toRecordArray(target: unknown): Record<string, unknown>[] {
        if (target == null) return [];
        if (Array.isArray(target)) {
            return target.filter(x => x != null && typeof x === 'object' && !Array.isArray(x)) as Record<string, unknown>[];
        }
        if (typeof target === 'object') return [target as Record<string, unknown>];
        return [];
    }

    // ── Derived collections — child objects exploded from a parent's arrays ──

    /** TTL for cached parent fetch pages. Long enough to span sibling derived objects syncing
     *  back-to-back in one run; short enough that a re-run always re-reads the vendor. */
    private static readonly DERIVED_PAGE_CACHE_TTL_MS = 15 * 60_000;
    /** Page cap. ~64 pages of 100-record parents bounds worst-case memory at a few tens of MB. */
    private static readonly DERIVED_PAGE_CACHE_MAX = 64;

    /**
     * Serves a derived object's fetch by running its PARENT object's FetchChanges and exploding
     * `Configuration.derivedCollection.collectionField` into child records. Pagination is entirely
     * the parent's: HasMore / NextPage / NextOffset / NextAfterKeyValue pass through untouched, so
     * the engine walks the parent's cursor exactly as the parent itself would — including
     * parent-scoped budgets and keyset resume. Identity is the child object's DECLARED PK via the
     * ordinary buildExternalRecord rule (declared-PK-else-content-hash), so during discovery
     * sampling (no fields yet) children still get stable hash identities.
     */
    private async fetchDerivedCollection(
        obj: MJIntegrationObjectEntity,
        ctx: FetchContext,
        derivedRaw: unknown,
        fields: MJIntegrationObjectFieldEntity[],
    ): Promise<FetchBatchResult> {
        const config = ParseDerivedCollectionConfig(derivedRaw);
        if (!config) {
            return { Records: [], HasMore: false, Warnings: [{ Code: 'DERIVED_CONFIG_MISSING', Message: `"${obj.Name}": empty derivedCollection`, Data: { object: obj.Name } }] };
        }
        const parentObj = this.GetCachedObject(ctx.CompanyIntegration.IntegrationID, config.parentObjectName);
        if (!parentObj) {
            // Loud, not empty: a wrong parent name must fail the sync, not present as an
            // enabled-and-empty object nobody can explain.
            throw new Error(`"${obj.Name}": derivedCollection.parentObjectName "${config.parentObjectName}" is not an integration object of this integration.`);
        }

        const parentBatch = await this.fetchParentPageCached(parentObj.Name, ctx);
        const exploded = ExplodeCollection(parentBatch.Records, config);
        const pkFieldNames = this.primaryKeyFieldNames(fields);
        const records = exploded.ChildFields.map(f => this.buildExternalRecord(f, ctx.ObjectName, pkFieldNames));

        const warnings = [...(parentBatch.Warnings ?? [])];
        if (exploded.ElementsSkipped > 0) {
            warnings.push({
                Code: 'DERIVED_ELEMENTS_SKIPPED',
                Message: `"${obj.Name}": ${exploded.ElementsSkipped} element(s) did not match elementKind '${config.elementKind}' and were skipped.`,
                Data: { object: obj.Name, skipped: exploded.ElementsSkipped },
            });
        }
        return {
            Records: records,
            HasMore: parentBatch.HasMore,
            NextPage: parentBatch.NextPage,
            NextOffset: parentBatch.NextOffset,
            NextAfterKeyValue: parentBatch.NextAfterKeyValue,
            Warnings: warnings.length > 0 ? warnings : undefined,
        };
    }

    /**
     * The parent's FetchChanges for one cursor position, served from the page cache when a
     * sibling derived object (or the parent itself, run recently) already fetched it. Cache key
     * is the full cursor — page, offset, keyset value — so a hit is exactly the same page.
     */
    private async fetchParentPageCached(parentObjectName: string, ctx: FetchContext): Promise<FetchBatchResult> {
        const key = [
            ctx.CompanyIntegration.IntegrationID, parentObjectName,
            ctx.CurrentPage ?? '', ctx.CurrentOffset ?? '', ctx.AfterKeyValue ?? '',
        ].join('\u0001');
        const hit = this.derivedPageCache.get(key);
        if (hit && (this.nowMs() - hit.At) < TotaraConnector.DERIVED_PAGE_CACHE_TTL_MS) {
            return hit.Result;
        }
        const result = await this.FetchChanges({ ...ctx, ObjectName: parentObjectName });
        this.derivedPageCache.set(key, { At: this.nowMs(), Result: result });
        // FIFO eviction — insertion order is good enough for a sequential page walk.
        while (this.derivedPageCache.size > TotaraConnector.DERIVED_PAGE_CACHE_MAX) {
            const oldest = this.derivedPageCache.keys().next().value;
            if (oldest === undefined) break;
            this.derivedPageCache.delete(oldest);
        }
        return result;
    }

    /** Configuration.dropFields for this object, or null. Read once per shaping call. */
    private dropFieldsFor(cfg: Record<string, unknown>): string[] | null {
        const v = this.readConfigStringArray(cfg, 'dropFields');
        return v && v.length > 0 ? v : null;
    }

    /**
     * §4 identity: the declared PK when EVERY component is present + non-empty, else a deterministic content
     * hash (so PK-less / partial-key records stay syncable + dedupable). Full-record pass-through: Fields
     * carries the COMPLETE source record (with the synthetic id stamped into a single empty PK column).
     */
    private buildExternalRecord(
        raw: Record<string, unknown>,
        objectType: string,
        pkFieldNames: string[],
    ): ExternalRecord {
        const allPkPresent = pkFieldNames.length > 0
            && pkFieldNames.every(name => raw[name] != null && serializeKeyValue(raw[name]).length > 0);
        const resolvedID = allPkPresent
            ? pkFieldNames.map(name => serializeKeyValue(raw[name])).join('|')
            : computeContentHash(raw);
        let fields = raw;
        if (!allPkPresent && pkFieldNames.length === 1
            && (raw[pkFieldNames[0]] == null || serializeKeyValue(raw[pkFieldNames[0]]).length === 0)) {
            fields = { ...raw, [pkFieldNames[0]]: resolvedID };
        }
        return { ExternalID: resolvedID, ObjectType: objectType, Fields: fields };
    }

    private primaryKeyFieldNames(fields: MJIntegrationObjectFieldEntity[]): string[] {
        const pk = fields.filter(f => f.IsPrimaryKey).sort((a, b) => a.Sequence - b.Sequence).map(f => f.Name);
        return pk.length > 0 ? pk : ['id'];
    }

    /** Pulls the created record's id from a Moodle create response (bare array of created / wrapped collection). */
    private extractCreatedId(body: unknown, idField: string): string | undefined {
        const first = this.firstRecord(body);
        if (first && first[idField] != null) return String(first[idField]);
        const deep = this.deepFindKey(body, idField);
        return deep == null ? undefined : String(deep);
    }

    /** Deterministic identity for an association create with no server id (matches the §4 content-hash path). */
    private synthesizeAssociationId(attrs: Record<string, unknown>): string {
        return computeContentHash(attrs);
    }

    private detectMoodleError(body: unknown): string | null {
        if (body && typeof body === 'object' && !Array.isArray(body)) {
            const rec = body as Record<string, unknown>;
            if (typeof rec.exception === 'string' && rec.exception.length > 0) {
                const code = typeof rec.errorcode === 'string' && rec.errorcode.length > 0 ? rec.errorcode : rec.exception;
                const message = typeof rec.message === 'string' ? rec.message : 'unknown Moodle Web Services error';
                return `[${code}] ${message}`;
            }
        }
        return null;
    }

    /** Throws when the body is a Moodle exception envelope (surfaces the errorcode) — never a silent empty. */
    private assertNoMoodleError(body: unknown): void {
        const err = this.detectMoodleError(body);
        if (err) throw new Error(`Totara/Moodle Web Services error ${err}`);
    }

    private buildCRUDError(err: unknown, operation: string, objectName: string): CRUDResult {
        const message = err instanceof Error ? err.message : String(err);
        return { Success: false, ErrorMessage: `${operation} failed for ${objectName}: ${message}`, StatusCode: 500 };
    }

    // ── Config resolution ─────────────────────────────────────────────

    /** Resolves the wstoken + base_url from the credential store (secrets) + Configuration JSON (overrides). */
    protected async ParseConfig(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<TotaraConfig> {
        const raw: Record<string, unknown> = {};
        if (companyIntegration.CredentialID) {
            Object.assign(raw, await this.loadCredentialValues(companyIntegration.CredentialID, contextUser));
        }
        if (companyIntegration.Configuration) {
            try {
                Object.assign(raw, JSON.parse(companyIntegration.Configuration) as Record<string, unknown>);
            } catch { /* non-fatal — fall through to whatever the credential store provided */ }
        }
        return this.normalizeConfig(raw);
    }

    private async loadCredentialValues(credentialID: string, contextUser: UserInfo): Promise<Record<string, unknown>> {
        const md = new Metadata();
        const credential = await md.GetEntityObject<MJCredentialEntity>('MJ: Credentials', contextUser);
        const loaded = await credential.Load(credentialID);
        if (!loaded || !credential.Values) return {};
        try {
            return JSON.parse(credential.Values) as Record<string, unknown>;
        } catch {
            return {};
        }
    }

    private normalizeConfig(raw: Record<string, unknown>): TotaraConfig {
        const pick = (...keys: string[]): string | undefined => {
            for (const key of keys) {
                for (const [k, v] of Object.entries(raw)) {
                    if (k.toLowerCase() === key.toLowerCase() && typeof v === 'string' && v.length > 0) return v;
                }
            }
            return undefined;
        };
        // Numeric knob, read separately: `pick` only matches string values, and a timeout is normally
        // written as a number. Absent/invalid → the default; an explicit 0 → no deadline (opt out).
        const timeoutRaw = Object.entries(raw)
            .find(([k]) => k.toLowerCase() === 'requesttimeoutms')?.[1];
        const timeout = typeof timeoutRaw === 'number' ? timeoutRaw
            : typeof timeoutRaw === 'string' && timeoutRaw.trim() !== '' ? Number(timeoutRaw)
            : NaN;
        const candidate: TotaraConfig = {
            Token: pick('wstoken', 'token', 'wsToken', 'apiKey', 'api_key', 'apitoken') ?? '',
            BaseURL: pick('base_url', 'baseUrl', 'baseURL', 'url', 'site', 'siteUrl', 'site_url', 'host') ?? '',
            RequestTimeoutMs: Number.isFinite(timeout) && timeout >= 0 ? timeout : DEFAULT_REQUEST_TIMEOUT_MS,
        };
        const parsed = ConfigSchema.safeParse(candidate);
        if (!parsed.success) {
            throw new Error(`Totara configuration invalid: ${parsed.error.issues.map(i => i.message).join('; ')}`);
        }
        return candidate;
    }

    /** `{base_url}/webservice/rest/server.php`, tolerant of a base_url that already includes the suffix. */
    private buildEndpoint(baseURL: string): string {
        const base = baseURL.replace(/\/+$/, '');
        return base.endsWith(REST_ENDPOINT_SUFFIX) ? base : `${base}${REST_ENDPOINT_SUFFIX}`;
    }

    private parseConnectionConfig(companyIntegration: MJCompanyIntegrationEntity): Record<string, unknown> {
        if (!companyIntegration.Configuration) return {};
        try {
            const parsed = JSON.parse(companyIntegration.Configuration) as unknown;
            return parsed && typeof parsed === 'object' && !Array.isArray(parsed) ? parsed as Record<string, unknown> : {};
        } catch {
            return {};
        }
    }

    // ── IO Configuration readers ───────────────────────────────────────

    private readIOConfig(obj: MJIntegrationObjectEntity): Record<string, unknown> {
        if (!obj.Configuration) return {};
        try {
            const parsed = JSON.parse(obj.Configuration) as unknown;
            return parsed && typeof parsed === 'object' && !Array.isArray(parsed) ? parsed as Record<string, unknown> : {};
        } catch {
            return {};
        }
    }

    private readWriteFunctions(cfg: Record<string, unknown>): Record<string, unknown> {
        return this.readConfigObject(cfg, 'writeFunctions') ?? {};
    }

    private readConfigString(cfg: Record<string, unknown>, key: string): string | null {
        const v = cfg[key];
        return typeof v === 'string' && v.trim().length > 0 ? v.trim() : null;
    }

    private readConfigStringArray(cfg: Record<string, unknown>, key: string): string[] | null {
        const v = cfg[key];
        if (!Array.isArray(v)) return null;
        const out = v.filter((x): x is string => typeof x === 'string' && x.length > 0);
        return out.length > 0 ? out : null;
    }

    private readConfigObject(cfg: Record<string, unknown>, key: string): Record<string, unknown> | null {
        const v = cfg[key];
        return v && typeof v === 'object' && !Array.isArray(v) ? v as Record<string, unknown> : null;
    }

    /** Positive-integer config reader (accepts a numeric string). Returns null for absent/zero/negative/NaN. */
    private readConfigPositiveInt(cfg: Record<string, unknown>, key: string): number | null {
        const v = cfg[key];
        const n = typeof v === 'number' ? v : typeof v === 'string' ? Number.parseInt(v, 10) : Number.NaN;
        return Number.isFinite(n) && n > 0 ? Math.floor(n) : null;
    }

    /** As readConfigPositiveInt, but 0 is a legal value (e.g. a zero time budget). Returns null for absent/negative/NaN. */
    private readConfigNonNegativeInt(cfg: Record<string, unknown>, key: string): number | null {
        const v = cfg[key];
        const n = typeof v === 'number' ? v : typeof v === 'string' ? Number.parseInt(v, 10) : Number.NaN;
        return Number.isFinite(n) && n >= 0 ? Math.floor(n) : null;
    }

    // ── Small utilities ────────────────────────────────────────────────

    private parseJson(text: string): unknown {
        const trimmed = text.trim();
        if (trimmed.length === 0) return null; // Moodle returns empty/`null` on some successful writes (e.g. delete)
        try {
            return JSON.parse(trimmed);
        } catch {
            return trimmed; // non-JSON body (rare) — hand back the raw text
        }
    }

    private headersToObject(headers: Headers): Record<string, string> {
        const out: Record<string, string> = {};
        headers.forEach((value, key) => { out[key.toLowerCase()] = value; });
        return out;
    }

    /** The first record object in a response (bare array → [0]; wrapped → first array's [0]; object → itself). */
    private firstRecord(body: unknown): Record<string, unknown> | null {
        if (Array.isArray(body)) {
            const first = body.find(x => x != null && typeof x === 'object' && !Array.isArray(x));
            return (first as Record<string, unknown>) ?? null;
        }
        if (body && typeof body === 'object') {
            const arr = this.firstArrayValue(body as Record<string, unknown>);
            if (arr) {
                const first = arr.find(x => x != null && typeof x === 'object' && !Array.isArray(x));
                if (first) return first as Record<string, unknown>;
            }
            return body as Record<string, unknown>;
        }
        return null;
    }

    private firstArrayValue(body: Record<string, unknown>): unknown[] | null {
        for (const value of Object.values(body)) {
            if (Array.isArray(value)) return value;
            if (value && typeof value === 'object') {
                const nested = this.firstArrayValue(value as Record<string, unknown>);
                if (nested) return nested;
            }
        }
        return null;
    }

    private recordCount(rawBody: unknown): number {
        if (Array.isArray(rawBody)) return rawBody.length;
        if (rawBody && typeof rawBody === 'object') {
            const arr = this.firstArrayValue(rawBody as Record<string, unknown>);
            if (arr) return arr.length;
            return Object.keys(rawBody as Record<string, unknown>).length > 0 ? 1 : 0;
        }
        return 0;
    }

    private deepFindKey(body: unknown, key: string): unknown {
        if (!body || typeof body !== 'object') return undefined;
        if (Array.isArray(body)) {
            for (const item of body) {
                const found = this.deepFindKey(item, key);
                if (found !== undefined) return found;
            }
            return undefined;
        }
        const rec = body as Record<string, unknown>;
        if (key in rec) return rec[key];
        for (const value of Object.values(rec)) {
            const found = this.deepFindKey(value, key);
            if (found !== undefined) return found;
        }
        return undefined;
    }

    private asNumber(v: unknown): number | null {
        if (typeof v === 'number' && Number.isFinite(v)) return v;
        if (typeof v === 'string' && /^-?\d+$/.test(v)) return Number(v);
        return null;
    }
}

/** Tree-shaking prevention — import and call from the package entry point. */
export function LoadTotaraConnector(): void { /* no-op */ }
