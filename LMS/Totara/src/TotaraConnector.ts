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
}

/** Auth context threaded through every request. Carries the token + the resolved RPC endpoint. */
export interface TotaraAuthContext extends RESTAuthContext {
    /** wstoken — injected as a urlencoded body param by MakeHTTPRequest. */
    Token: string;
    /** Fully-resolved RPC endpoint: `{base_url}/webservice/rest/server.php`. */
    Endpoint: string;
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

// ─── Connector ─────────────────────────────────────────────────────────

@RegisterClass(BaseIntegrationConnector, 'TotaraConnector')
export class TotaraConnector extends BaseRESTIntegrationConnector {

    /** Resolved auth per CompanyIntegration.ID — avoids re-loading the credential every fetch/CRUD call. */
    protected authCache = new Map<string, TotaraAuthContext>();

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

        const httpResponse = await fetch(url, { method, headers, body: form.toString() });
        const text = await httpResponse.text();
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
        const records = rawRecords.map(r => this.buildExternalRecord(
            this.applyTransformPreservingKeys(r, obj, fields),
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
     */
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
        if (!parentWsFn || !paramName) {
            return { Records: [], HasMore: false, Warnings: [{ Code: 'PARENT_SCOPE_INCOMPLETE',
                Message: `"${obj.Name}": Configuration.parentScope requires parentWsFunction + paramName.`, Data: { object: obj.Name } }] };
        }

        const auth = await this.Authenticate(ctx.CompanyIntegration, ctx.ContextUser);
        const fields = this.GetCachedFields(obj.ID);
        const pkFieldNames = this.primaryKeyFieldNames(fields);

        // 1) Load parent ids from the parent's list wsfunction (bare array or single-collection envelope).
        const parentResp = await this.MakeHTTPRequest(auth, auth.Endpoint, 'POST', this.BuildHeaders(auth),
            { WsFunction: parentWsFn, Params: {} } as MoodleRPCRequest);
        const parentRecords = this.NormalizeResponse(parentResp.Body, null);
        const allParentIDs = Array.from(new Set(parentRecords
            .map(r => r[parentIdField]).filter(v => v != null && String(v).length > 0).map(String)))
            .sort((a, b) => a.localeCompare(b));
        if (allParentIDs.length === 0) {
            return { Records: [], HasMore: false, Warnings: [{ Code: 'ZERO_PARENTS',
                Message: `"${obj.Name}": ${parentWsFn} returned no parent ids to iterate ${paramName} over — sync the parent first.`, Data: { object: obj.Name } }] };
        }

        // 2) Keyset-resume + bounded batch over the parent ids.
        const after = ctx.AfterKeyValue ?? null;
        const remaining = after != null ? allParentIDs.filter(id => id.localeCompare(after) > 0) : allParentIDs;
        const batch = remaining.slice(0, Math.max(1, this.TemplateVarParentBatchSize()));

        // 3) One request per parent (bounded concurrency + adaptive rate-limit via the engine hooks).
        const out: ExternalRecord[] = [];
        const warnings: NonNullable<FetchBatchResult['Warnings']> = [];
        const collectionKeys = this.recordCollectionKeys(obj, cfg);
        await this.runParentBounded(batch, Math.max(1, ctx.MaxConcurrency ?? 1), async (parentID) => {
            if (ctx.RateLimitAcquire) await ctx.RateLimitAcquire();
            try {
                const resp = await this.MakeHTTPRequest(auth, auth.Endpoint, 'POST', this.BuildHeaders(auth),
                    { WsFunction: wsfunction, Params: { [paramName]: parentID } } as MoodleRPCRequest);
                for (const key of collectionKeys) {
                    for (const raw of this.NormalizeResponse(resp.Body, key)) {
                        // tag the child with the parent FK so its row links back to the parent record
                        const tagged = raw[paramName] != null ? raw : { ...raw, [paramName]: parentID };
                        out.push(this.buildExternalRecord(this.applyTransformPreservingKeys(tagged, obj, fields), ctx.ObjectName, pkFieldNames));
                    }
                }
                ctx.RateLimitReport?.();
            } catch (e) {
                const msg = e instanceof Error ? e.message : String(e);
                if (/429|rate.?limit|Retry-After/i.test(msg)) { ctx.RateLimitReport?.(e); throw e; }  // rate-limit → propagate for backoff
                warnings.push({ Code: 'PARENT_FETCH_ERROR', Message: `"${obj.Name}" fetch for ${paramName}=${parentID}: ${msg}`, Data: { object: obj.Name, [paramName]: parentID } });
            }
        });

        const hasMore = remaining.length > batch.length;
        return { Records: out, HasMore: hasMore, NextAfterKeyValue: hasMore ? batch[batch.length - 1] : undefined, Warnings: warnings.length ? warnings : undefined };
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
    ): void {
        const fromRaw = pagParams[0] ?? 'limitfrom';
        const countRaw = (pagParams[1] ?? 'limitnum').split('|')[0];
        if (fromRaw.includes('.')) {
            const prefix = fromRaw.split('.')[0];
            const fromName = fromRaw.slice(prefix.length + 1);
            const countName = countRaw.includes('.') ? countRaw.slice(countRaw.indexOf('.') + 1) : countRaw;
            params[`${prefix}[0][name]`] = fromName;
            params[`${prefix}[0][value]`] = offset;
            params[`${prefix}[1][name]`] = countName;
            params[`${prefix}[1][value]`] = pageSize;
        } else {
            params[fromRaw] = offset;
            params[countRaw] = pageSize;
        }
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
        const candidate: TotaraConfig = {
            Token: pick('wstoken', 'token', 'wsToken', 'apiKey', 'api_key', 'apitoken') ?? '',
            BaseURL: pick('base_url', 'baseUrl', 'baseURL', 'url', 'site', 'siteUrl', 'site_url', 'host') ?? '',
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
