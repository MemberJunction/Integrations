import { RegisterClass } from '@memberjunction/global';
import { Metadata, type IMetadataProvider, type UserInfo } from '@memberjunction/core';
import type {
    MJCompanyIntegrationEntity,
    MJCredentialEntity,
    MJIntegrationObjectEntity,
    MJIntegrationObjectFieldEntity,
} from '@memberjunction/core-entities';
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
} from '@memberjunction/integration-engine';
import { z } from 'zod';

/**
 * Asana work-management connector (REST API v1.0, read-only).
 *
 * ── Why this connector is almost entirely metadata ──
 * Asana's four synced surfaces are plain GETs whose paths, page sizes and field projections are all
 * expressible as IntegrationObject metadata, so the base class drives the whole fetch. What is left
 * here is exactly the five things metadata cannot express: the bearer header, the per-tenant
 * workspace scope, Asana's non-standard cursor spelling, the `modified_since` incremental filter,
 * and the flattening of Asana's nested sub-objects onto declared columns.
 *
 * ── Workspace scope is a query param, NOT a template variable ──
 * Every Asana listing is workspace-scoped, and the workspace gid lives on
 * CompanyIntegration.ExternalSystemID. It is deliberately NOT modelled as a `{workspace}` template
 * var: template vars are resolved by iterating a *synced parent object*, and there is no Workspaces
 * object to iterate (nor should there be — a connection is one workspace). It is injected as a query
 * param instead, which is the tenant-level scoping that the `CONNECTION_VARS` exemption in
 * scripts/validate-parent-declarations.mjs describes.
 *
 * ── Tasks and Subtasks are templated child doors ──
 * Asana publishes no workspace-wide task listing: tasks are addressable only per project
 * (`/tasks?project=`) and subtasks only per task (`/tasks/{gid}/subtasks`). Both objects therefore
 * declare `Configuration.parentObjectName` so the engine iterates the already-synced parents. Without
 * that declaration each would fetch zero rows and the run would still report success — the exact
 * silent-empty class validate-parent-declarations.mjs guards.
 *
 * ── Left behind from the legacy AIDP driver on purpose ──
 * The legacy driver resolved Asana records against AIDP's own Employee/Project/Task tables and wrote
 * three hardcoded custom-field gids back into Asana. None of that is vendor shape — it is one
 * tenant's model — so this connector lands raw Asana records and nothing else. Likewise the driver's
 * four named custom fields (Role / Skills / Status / ETC) are one workspace's configuration, not
 * Asana's: custom fields are declared per workspace and cannot be columns, so the whole array lands
 * as `custom_fields_json` for downstream projection.
 */
// Primary key follows the catalog convention (className == npm package name; see
// scripts/build-connectors-catalog.mjs) — instance discovery reports the package name, so a bare
// class-symbol key would never match in the catalog. The bare symbol stays registered as an alias.
@RegisterClass(BaseIntegrationConnector, '@memberjunction/connector-asana')
@RegisterClass(BaseIntegrationConnector, 'AsanaConnector')
export class AsanaConnector extends BaseRESTIntegrationConnector {

    /** Verbatim three-way invariant name: ClassName / IntegrationName getter / MJ: Integrations.Name. */
    public override get IntegrationName(): string {
        return 'Asana';
    }

    /**
     * The watermark is `modified_at`, which Asana advances monotonically, and the incremental filter
     * (`modified_since`) is inclusive-from — so a resumed sync can never step backwards over records
     * it already holds.
     */
    public override get MonotonicWatermark(): boolean {
        return true;
    }

    /**
     * Asana's list endpoints have no documented stable sort key and no `order_by` parameter, so a
     * keyset resume would be resuming against an ordering the vendor never promised. Paging is the
     * opaque `offset` cursor instead.
     */
    public override StableOrderingKey(_objectName: string): string | null {
        return null;
    }

    /**
     * The watermark for the object currently being fetched, stashed by FetchChanges so
     * AppendDefaultQueryParams — which the base calls per page and which receives no context — can
     * apply `modified_since`. Cleared on the way out so a non-incremental object can never inherit
     * the previous object's filter.
     */
    protected currentWatermark: string | null = null;

    /** Workspace gid for the connection currently being fetched — stashed for the same reason. */
    protected currentWorkspace: string | null = null;

    // ─── Auth + transport (BaseRESTIntegrationConnector abstracts) ────

    /**
     * Resolves the personal access token and the workspace gid. The token comes from the linked
     * Credential entity, falling back to CompanyIntegration.Configuration; the workspace comes from
     * ExternalSystemID, which is what that column means for a workspace-scoped vendor, with a
     * Configuration override for tenants that set it there instead.
     */
    protected async Authenticate(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<AsanaAuthContext> {
        const resolved = await this.LoadCredentials(companyIntegration, contextUser);
        const workspace = companyIntegration.ExternalSystemID ?? resolved.Workspace;
        if (!workspace) {
            throw new Error(
                'Asana workspace is not configured. Every Asana listing is workspace-scoped; set the ' +
                'workspace gid on CompanyIntegration.ExternalSystemID (or "workspace" in the Configuration JSON).'
            );
        }
        return { Token: resolved.Token, Workspace: String(workspace) };
    }

    protected BuildHeaders(auth: AsanaAuthContext): Record<string, string> {
        return {
            'Authorization': `Bearer ${auth.Token}`,
            'Accept': 'application/json',
            // Asana gates behaviour changes behind opt-in headers rather than a version in the URL.
            // These two are the deprecations the legacy driver already opted into; without them the
            // shapes of user task lists and goal memberships differ from what this catalog declares.
            'Asana-Enable': 'new_goal_memberships,new_user_task_lists',
        };
    }

    protected GetBaseURL(_companyIntegration: MJCompanyIntegrationEntity, _auth: AsanaAuthContext): string {
        return ASANA_API_BASE;
    }

    protected async MakeHTTPRequest(
        _auth: AsanaAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown
    ): Promise<RESTResponse> {
        const init: RequestInit = { method, headers };
        if (body !== undefined && method !== 'GET' && method !== 'HEAD') {
            init.body = typeof body === 'string' ? body : JSON.stringify(body);
            (init.headers as Record<string, string>)['Content-Type'] = 'application/json';
        }
        const response = await fetch(url, init);
        const responseHeaders: Record<string, string> = {};
        response.headers.forEach((value, key) => { responseHeaders[key.toLowerCase()] = value; });
        const text = await response.text();
        let parsed: unknown = text;
        const contentType = responseHeaders['content-type'] ?? '';
        if (contentType.includes('json') || (text.length > 0 && (text[0] === '{' || text[0] === '['))) {
            try { parsed = JSON.parse(text); } catch { parsed = text; }
        }
        return { Status: response.status, Body: parsed, Headers: responseHeaders };
    }

    /** Asana wraps every collection response in `{ "data": [...] }` (the declared ResponseDataKey). */
    protected NormalizeResponse(rawBody: unknown, responseDataKey: string | null): Record<string, unknown>[] {
        const key = responseDataKey ?? 'data';
        if (isRecord(rawBody)) {
            const inner = rawBody[key];
            if (Array.isArray(inner)) return inner.filter(isRecord);
            if (isRecord(inner)) return [inner];
        }
        if (Array.isArray(rawBody)) return rawBody.filter(isRecord);
        return [];
    }

    /**
     * Asana's cursor lives at `next_page.offset`, and its ABSENCE — not a flag — is what ends the
     * stream: `next_page` is null on the last page. So treating a missing cursor as "done" is the
     * vendor's own contract rather than an inference.
     */
    protected ExtractPaginationInfo(
        rawBody: unknown,
        paginationType: PaginationType,
        _currentPage: number,
        _currentOffset: number,
        _pageSize: number
    ): PaginationState {
        if (paginationType !== 'Cursor') return { HasMore: false };
        if (isRecord(rawBody)) {
            const nextPage = rawBody['next_page'];
            if (isRecord(nextPage)) {
                const offset = nextPage['offset'];
                if (typeof offset === 'string' && offset.length > 0) {
                    return { HasMore: true, NextCursor: offset };
                }
            }
        }
        return { HasMore: false };
    }

    /**
     * Asana spells its cursor `offset` and its page size `limit`, where the base class's Cursor case
     * emits `cursor=`. Sending the base's spelling is not an error Asana reports — it ignores the
     * unknown param and re-serves page one, which the base's duplicate-page guard would catch only
     * after a wasted round trip and a truncated object. This override is the one place that mismatch
     * is fixed.
     *
     * `limit` is clamped into Asana's documented 1..100 range: the base passes the remaining batch
     * capacity as the effective page size, and a value outside that range is a 400 from Asana.
     */
    protected override BuildPaginatedURL(
        basePath: string,
        obj: MJIntegrationObjectEntity,
        page: number,
        offset: number,
        cursor?: string,
        effectivePageSize?: number
    ): string {
        if (obj.PaginationType !== 'Cursor') {
            return super.BuildPaginatedURL(basePath, obj, page, offset, cursor, effectivePageSize);
        }
        const requested = effectivePageSize ?? obj.DefaultPageSize ?? ASANA_MAX_PAGE_SIZE;
        const limit = Math.min(ASANA_MAX_PAGE_SIZE, Math.max(1, requested));
        const separator = basePath.includes('?') ? '&' : '?';
        return cursor
            ? `${basePath}${separator}offset=${encodeURIComponent(cursor)}&limit=${limit}`
            : `${basePath}${separator}limit=${limit}`;
    }

    /**
     * Adds the two params that are per-connection or per-run rather than per-object: the workspace
     * scope and the incremental `modified_since` filter.
     *
     * The static `opt_fields` projection is deliberately NOT added here — it is declared metadata
     * (DefaultQueryParams), which the base appends, so the field projection stays next to the field
     * declarations it has to agree with.
     */
    protected override AppendDefaultQueryParams(url: string, obj: MJIntegrationObjectEntity): string {
        let out = super.AppendDefaultQueryParams(url, obj);
        if (WORKSPACE_SCOPED_OBJECTS.has(obj.Name) && this.currentWorkspace) {
            out = appendParam(out, 'workspace', this.currentWorkspace);
        }
        if (obj.SupportsIncrementalSync && this.currentWatermark) {
            out = appendParam(out, 'modified_since', toAsanaTimestamp(this.currentWatermark));
        }
        return out;
    }

    // ─── Fetch ───────────────────────────────────────────────────────

    /**
     * Delegates the whole fetch to the base (pagination, parent iteration, batching) and adds only
     * what the base has no way to know: the per-run scope params, and the new watermark.
     *
     * The watermark advances to the maximum `modified_at` actually observed, never to the wall clock.
     * A clock-based watermark would silently skip anything modified between the last page fetched and
     * the moment the run finished, and `modified_since` is compared against Asana's server clock, not
     * ours — so the only safe high-water mark is one the server itself stamped on a record we hold.
     */
    public override async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
        const auth = await this.Authenticate(ctx.CompanyIntegration, ctx.ContextUser);
        this.currentWorkspace = auth.Workspace;
        this.currentWatermark = ctx.WatermarkValue;
        try {
            const result = await super.FetchChanges(ctx);
            const newWatermark = maxModifiedAt(result.Records, ctx.WatermarkValue);
            return newWatermark ? { ...result, NewWatermarkValue: newWatermark } : result;
        } finally {
            this.currentWorkspace = null;
            this.currentWatermark = null;
        }
    }

    /**
     * Flattens Asana's nested sub-objects onto the declared columns.
     *
     * Asana returns compound values as objects (`owner: {gid}`, `current_status: {color,title,text}`,
     * `memberships: [{section: {name}}]`), and the sync engine maps a declared column only from a
     * top-level key of the same name — so without this every one of those columns lands null while
     * the run reports success. The base's applyTransformPreservingKeys keeps the original nested keys
     * alongside these, so full-record custom-column capture still sees everything Asana sent.
     */
    protected override TransformRecord(
        raw: Record<string, unknown>,
        _obj: MJIntegrationObjectEntity,
        _fields: MJIntegrationObjectFieldEntity[]
    ): Record<string, unknown> {
        const out: Record<string, unknown> = { ...raw };

        for (const [source, target] of NESTED_GID_FIELDS) {
            const value = raw[source];
            if (isRecord(value)) out[target] = stringOrNull(value['gid']);
            else if (value === null) out[target] = null;
        }

        const status = raw['current_status'];
        if (isRecord(status)) {
            out['current_status_color'] = stringOrNull(status['color']);
            out['current_status_title'] = stringOrNull(status['title']);
            out['current_status_text'] = stringOrNull(status['text']);
        } else if (status === null) {
            out['current_status_color'] = null;
            out['current_status_title'] = null;
            out['current_status_text'] = null;
        }

        // Asana returns one membership per project the task belongs to. This connector fetches tasks
        // one project at a time, so the first membership is the one for the project door we came
        // through — the same choice the legacy driver made, but without its extra per-task GET:
        // `memberships.section.name` is an opt_field on the listing, so the section arrives with the
        // task rather than costing one request per record.
        const memberships = raw['memberships'];
        if (Array.isArray(memberships)) {
            const first = memberships.find(isRecord);
            const section = first ? first['section'] : undefined;
            out['section_name'] = isRecord(section) ? stringOrNull(section['name']) : null;
        }

        const customFields = raw['custom_fields'];
        if (customFields !== undefined) {
            out['custom_fields_json'] = Array.isArray(customFields) && customFields.length > 0
                ? JSON.stringify(customFields)
                : null;
        }

        return out;
    }

    // ─── Connection test ─────────────────────────────────────────────

    /**
     * Probes `/users/me`, the one Asana endpoint valid for every token regardless of workspace
     * membership or scope — so a failure there is unambiguously a credential problem rather than a
     * permissions one. The configured workspace is then checked against the workspaces the token can
     * actually see, because a token that authenticates but cannot see the configured workspace
     * produces empty-but-successful syncs, which is the failure most worth catching here.
     */
    public override async TestConnection(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<ConnectionTestResult> {
        try {
            const auth = await this.Authenticate(companyIntegration, contextUser);
            const headers = this.BuildHeaders(auth);
            const me = await this.MakeHTTPRequest(auth, `${ASANA_API_BASE}/users/me`, 'GET', headers);
            if (me.Status === 401) {
                return { Success: false, Message: 'Asana rejected the access token (HTTP 401).' };
            }
            if (me.Status >= 400) {
                return { Success: false, Message: `Asana /users/me returned HTTP ${me.Status}.` };
            }

            const body = isRecord(me.Body) ? me.Body : {};
            const data = isRecord(body['data']) ? body['data'] : {};
            const who = stringOrNull(data['name']) ?? stringOrNull(data['gid']) ?? 'unknown user';
            const workspaces = Array.isArray(data['workspaces']) ? data['workspaces'].filter(isRecord) : [];
            const visible = workspaces
                .map(w => stringOrNull(w['gid']))
                .filter((g): g is string => g !== null);
            if (visible.length > 0 && !visible.includes(auth.Workspace)) {
                return {
                    Success: false,
                    Message:
                        `Asana token authenticated as ${who}, but workspace "${auth.Workspace}" is not one of ` +
                        `the workspaces it can see (${visible.join(', ')}). Every listing is workspace-scoped, ` +
                        `so this connection would sync zero records.`,
                };
            }
            return { Success: true, Message: `Connected to Asana as ${who} (workspace ${auth.Workspace}).` };
        } catch (err: unknown) {
            const message = err instanceof Error ? err.message : String(err);
            return { Success: false, Message: `Asana connection error: ${message}` };
        }
    }

    // ─── Credential resolution ───────────────────────────────────────

    /**
     * Resolves the access token from the linked Credential entity, falling back to the
     * CompanyIntegration.Configuration JSON.
     *
     * CompanyIntegration.APIKey is deliberately NOT read: it is not a decrypt-on-read column, so a
     * value written through mj-sync encryption comes back as the literal `$ENC$…` string and would be
     * sent to Asana verbatim — authenticating as nobody while looking configured.
     */
    private async LoadCredentials(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<AsanaResolvedCredentials & { Token: string }> {
        let token: string | undefined;
        let workspace: string | undefined;

        if (companyIntegration.CredentialID) {
            const fromCred = await this.LoadFromCredentialEntity(companyIntegration.CredentialID, contextUser);
            if (fromCred) {
                token = fromCred.Token ?? token;
                workspace = fromCred.Workspace ?? workspace;
            }
        }
        if (companyIntegration.Configuration) {
            const fromConfig = this.ParseCredentialJson(companyIntegration.Configuration);
            if (fromConfig) {
                token = token ?? fromConfig.Token;
                workspace = workspace ?? fromConfig.Workspace;
            }
        }
        if (!token) {
            throw new Error(
                'No Asana credential found — link an "API Key" credential holding a personal access ' +
                'token, or supply one as "token" in the CompanyIntegration.Configuration JSON.'
            );
        }
        return { Token: token, Workspace: workspace };
    }

    private async LoadFromCredentialEntity(
        credentialID: string,
        contextUser: UserInfo,
        provider?: IMetadataProvider
    ): Promise<AsanaResolvedCredentials | null> {
        const md = provider ?? new Metadata();
        const credential = await md.GetEntityObject<MJCredentialEntity>('MJ: Credentials', contextUser);
        const loaded = await credential.Load(credentialID);
        if (!loaded || !credential.Values) return null;
        return this.ParseCredentialJson(credential.Values);
    }

    /** Parses a credential/Configuration JSON blob, tolerating the usual casing/naming aliases. */
    private ParseCredentialJson(json: string): AsanaResolvedCredentials | null {
        try {
            const result = AsanaCredentialSchema.safeParse(JSON.parse(json));
            if (!result.success) return null;
            const p = result.data;
            const token = p.Token ?? p.token ?? p.apiKey ?? p.ApiKey ?? p.accessToken ?? p.personalAccessToken;
            const workspace = p.Workspace ?? p.workspace ?? p.workspaceGid ?? p.WorkspaceID;
            if (token == null && workspace == null) return null;
            return {
                Token: token != null ? String(token) : undefined,
                Workspace: workspace != null ? String(workspace) : undefined,
            };
        } catch {
            return null;
        }
    }
}

// ─── Module-level constants, types + helpers (mechanism, NOT a catalog) ───

/** Asana's REST base. Single-tenant SaaS with no per-customer host, so there is nothing to configure. */
const ASANA_API_BASE = 'https://app.asana.com/api/1.0';

/** Asana rejects `limit` outside 1..100 with a 400. */
const ASANA_MAX_PAGE_SIZE = 100;

/**
 * The objects whose listing needs an explicit `workspace` param. The templated child doors are
 * already scoped by the parent id in their path, and Asana rejects `workspace` alongside `project`.
 */
const WORKSPACE_SCOPED_OBJECTS = new Set(['Users', 'Projects']);

/** Nested `{gid}` sub-objects → the flat column each is projected onto. */
const NESTED_GID_FIELDS: ReadonlyArray<readonly [string, string]> = [
    ['owner', 'owner_gid'],
    ['team', 'team_gid'],
    ['workspace', 'workspace_gid'],
    ['assignee', 'assignee_gid'],
    ['parent', 'parent_gid'],
];

/** Auth context: bearer token plus the workspace every listing is scoped to. */
interface AsanaAuthContext extends RESTAuthContext {
    Token: string;
    Workspace: string;
}

interface AsanaResolvedCredentials {
    Token?: string;
    Workspace?: string;
}

const AsanaCredentialSchema = z.object({
    Token: z.string().optional(),
    token: z.string().optional(),
    apiKey: z.string().optional(),
    ApiKey: z.string().optional(),
    accessToken: z.string().optional(),
    personalAccessToken: z.string().optional(),
    Workspace: z.union([z.string(), z.number()]).optional(),
    workspace: z.union([z.string(), z.number()]).optional(),
    workspaceGid: z.union([z.string(), z.number()]).optional(),
    WorkspaceID: z.union([z.string(), z.number()]).optional(),
}).passthrough();

function isRecord(v: unknown): v is Record<string, unknown> {
    return typeof v === 'object' && v !== null && !Array.isArray(v);
}

function stringOrNull(v: unknown): string | null {
    return typeof v === 'string' && v.length > 0 ? v : null;
}

function appendParam(url: string, key: string, value: string): string {
    const separator = url.includes('?') ? '&' : '?';
    return `${url}${separator}${encodeURIComponent(key)}=${encodeURIComponent(value)}`;
}

/**
 * Asana's `modified_since` wants a full ISO-8601 instant. A watermark that already is one passes
 * through untouched; a date-only watermark is widened to the start of that day rather than narrowed,
 * because widening re-reads records (harmless — they upsert by gid) while narrowing loses them.
 */
export function toAsanaTimestamp(watermark: string): string {
    if (watermark.includes('T')) return watermark;
    return `${watermark}T00:00:00.000Z`;
}

/**
 * The highest `modified_at` across a batch, or null when the batch moves it nowhere.
 *
 * Compared as ISO strings, which is lexicographically correct for the fixed-width UTC form Asana
 * emits. The previous watermark seeds the comparison so a batch containing only older records can
 * never drag the high-water mark backwards.
 */
export function maxModifiedAt(
    records: ReadonlyArray<{ Fields: Record<string, unknown> }>,
    previous: string | null
): string | null {
    let best = previous;
    for (const record of records) {
        const value = record.Fields['modified_at'];
        if (typeof value !== 'string' || value.length === 0) continue;
        if (best === null || value > best) best = value;
    }
    return best === previous ? null : best;
}
