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
 * Everhour time-tracking connector (REST API v1.2, read-only).
 *
 * ── Everhour ids carry a platform prefix, and that is the whole `as:` story ──
 * An Everhour project id is literally `as:1234567890` (Asana-sourced), `jr:…` (Jira), `ev:…` (native),
 * and so on — the prefix is part of the vendor's own identifier, documented in its Project schema, not
 * an addressing convention a caller adds. The legacy AIDP driver looked like it was doing something
 * exotic (`/projects/as:${externalId}/tasks`) only because it had *stripped* the prefix on the way in,
 * with `id.slice(3)`, to make the remainder match an Asana gid — then had to put it back to make the
 * next call. This connector keeps every id exactly as Everhour issued it, so the prefix never has to
 * be reconstructed and the connector never has to know that some Everhour workspaces are backed by
 * Asana. Nothing here is Asana-aware.
 *
 * ── Vendor units are preserved, not converted ──
 * Everhour reports money in cents and durations in seconds. The legacy driver divided fees, rates and
 * budgets by 100 on the way into AIDP's schema; that is a presentation choice belonging to whoever
 * consumes the data, and doing it here would make the landed value disagree with what the API returned
 * and with what Everhour's own UI reports. Every amount lands in the vendor's unit and every field
 * description names that unit.
 *
 * ── Time records come from the team-wide door, not per project ──
 * The legacy driver read time one project at a time (`/projects/{id}/time`), which is an N+1 over the
 * project list and, at Everhour's ~20 requests / 10 seconds, the dominant cost of a run. Everhour also
 * publishes `/team/time?from=&to=`, which returns the same records for the whole team in one paged
 * stream. TimeRecords therefore has no parent door at all, and `from`/`to` gives the incremental
 * filter directly.
 *
 * ── Tasks is a templated child door ──
 * Everhour exposes no unfiltered team-wide task listing (`/tasks/search` requires a search term), so
 * tasks are addressable only per project. Tasks declares `Configuration.parentObjectName: "Projects"`
 * so the engine iterates the already-synced projects; without that declaration it would fetch zero
 * rows and the run would still report success.
 */
// Primary key follows the catalog convention (className == npm package name; see
// scripts/build-connectors-catalog.mjs) — instance discovery reports the package name, so a bare
// class-symbol key would never match in the catalog. The bare symbol stays registered as an alias.
@RegisterClass(BaseIntegrationConnector, '@memberjunction/connector-everhour')
@RegisterClass(BaseIntegrationConnector, 'EverhourConnector')
export class EverhourConnector extends BaseRESTIntegrationConnector {

    /** Verbatim three-way invariant name: ClassName / IntegrationName getter / MJ: Integrations.Name. */
    public override get IntegrationName(): string {
        return 'Everhour';
    }

    /**
     * The only incremental object is TimeRecords, watermarked on `date`, and the watermark only ever
     * advances to the maximum date actually observed. Records are never re-dated backwards by Everhour
     * — an edit changes `time`/`comment`, not which day the work happened — so the high-water mark is
     * monotonic even though the records behind it are mutable. The lookback window below is what
     * covers those mutations.
     */
    public override get MonotonicWatermark(): boolean {
        return true;
    }

    /**
     * Everhour's list endpoints document no ordering guarantee and offer no sort parameter, so there
     * is no key a keyset resume could resume against. Paging is `page`/`limit`.
     */
    public override StableOrderingKey(_objectName: string): string | null {
        return null;
    }

    /**
     * The watermark for the object currently being fetched, stashed by FetchChanges so
     * AppendDefaultQueryParams — which the base calls per page and which receives no context — can
     * apply the `from`/`to` window. Cleared on the way out so a non-incremental object can never
     * inherit the previous object's filter.
     */
    protected currentWatermark: string | null = null;

    // ─── Auth + transport (BaseRESTIntegrationConnector abstracts) ────

    /**
     * Resolves the API key. Everhour has no separate tenant identifier: the key *is* the team scope,
     * which is why nothing here reads ExternalSystemID and why there is no workspace parameter on any
     * request.
     */
    protected async Authenticate(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<EverhourAuthContext> {
        const apiKey = await this.LoadCredentials(companyIntegration, contextUser);
        return { ApiKey: apiKey };
    }

    protected BuildHeaders(auth: EverhourAuthContext): Record<string, string> {
        return {
            'X-Api-Key': auth.ApiKey,
            'Accept': 'application/json',
            // Everhour describes its API as BETA and, absent this header, serves whatever version is
            // newest — so an unannounced vendor release could reshape responses under a catalog that
            // was validated against 1.2. Pinning turns that from a silent shape change into a
            // deliberate, reviewable version bump here.
            'X-Accept-Version': EVERHOUR_API_VERSION,
        };
    }

    protected GetBaseURL(_companyIntegration: MJCompanyIntegrationEntity, _auth: EverhourAuthContext): string {
        return EVERHOUR_API_BASE;
    }

    /**
     * Plain fetch, with one deliberate URL normalization: `%3A` is decoded back to `:`.
     *
     * Every Everhour project and task id contains a colon (`as:1234567890`), and the base substitutes
     * template variables with encodeURIComponent, which turns the id in `/projects/{project_id}/tasks`
     * into `as%3A1234567890`. That substitution helper is private, so the path cannot be fixed where it
     * is built — this is the one seam that sees the final URL. A colon is a legal character in both a
     * path segment and a query value under RFC 3986, so decoding it is safe everywhere in the URL, and
     * it removes any dependence on Everhour's router happening to percent-decode before matching.
     */
    protected async MakeHTTPRequest(
        _auth: EverhourAuthContext,
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
        const response = await fetch(restoreColons(url), init);
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

    /**
     * Everhour returns bare JSON arrays with no envelope — there is no data key to unwrap, which is
     * why every object declares an empty ResponseDataKey.
     */
    protected NormalizeResponse(rawBody: unknown, responseDataKey: string | null): Record<string, unknown>[] {
        if (responseDataKey && isRecord(rawBody)) {
            const inner = rawBody[responseDataKey];
            if (Array.isArray(inner)) return inner.filter(isRecord);
            if (isRecord(inner)) return [inner];
        }
        if (Array.isArray(rawBody)) return rawBody.filter(isRecord);
        if (isRecord(rawBody)) return [rawBody];
        return [];
    }

    /**
     * A bare array carries no next-page marker, so the only available signal is whether the page came
     * back full. A short page is the last page; a full page means ask for another.
     *
     * That inference is safe against the one case it could loop on — an endpoint that silently ignores
     * `page` and re-serves page one forever — because the base compares the first record of
     * consecutive pages and stops on a repeat. This matters concretely: Everhour documents `page` on
     * `/projects/{id}/tasks` and `/team/time` but NOT on `/projects`, where only `limit` is listed.
     * The parameter does work there (the legacy driver paged projects in production for years), but
     * the guarantee that a doc omission cannot become an infinite loop comes from that guard, not from
     * the vendor.
     */
    protected ExtractPaginationInfo(
        rawBody: unknown,
        paginationType: PaginationType,
        currentPage: number,
        _currentOffset: number,
        pageSize: number
    ): PaginationState {
        if (paginationType !== 'PageNumber') return { HasMore: false };
        const count = Array.isArray(rawBody) ? rawBody.length : 0;
        if (pageSize > 0 && count >= pageSize) {
            return { HasMore: true, NextPage: currentPage + 1 };
        }
        return { HasMore: false };
    }

    /**
     * Everhour spells its page size `limit`, where the base's PageNumber case emits `pageSize`. An
     * unknown parameter is not an error Everhour reports — it falls back to its own default page size,
     * so the fetch would quietly run at the wrong width and, worse, `ExtractPaginationInfo` would then
     * be comparing the returned count against a page size that was never requested and could end the
     * object early. This override is the one place that mismatch is fixed.
     *
     * `limit` is also clamped to the documented per-endpoint maximum: Everhour rejects an over-large
     * `limit` on tasks (250 max) rather than silently capping it.
     */
    protected override BuildPaginatedURL(
        basePath: string,
        obj: MJIntegrationObjectEntity,
        page: number,
        offset: number,
        cursor?: string,
        effectivePageSize?: number
    ): string {
        if (obj.PaginationType !== 'PageNumber') {
            return super.BuildPaginatedURL(basePath, obj, page, offset, cursor, effectivePageSize);
        }
        const max = MAX_PAGE_SIZE_BY_OBJECT[obj.Name] ?? DEFAULT_MAX_PAGE_SIZE;
        const requested = effectivePageSize ?? obj.DefaultPageSize ?? max;
        const limit = Math.min(max, Math.max(1, requested));
        const separator = basePath.includes('?') ? '&' : '?';
        return `${basePath}${separator}page=${page}&limit=${limit}`;
    }

    /**
     * Adds the incremental date window, which is per-run rather than per-object and so cannot be
     * declared metadata.
     *
     * `from` is deliberately backdated by a lookback window (default 7 days, overridable per tenant as
     * `Configuration.lookbackDays`). A time record's `date` is the day the work happened, but the
     * record itself stays editable — comments, durations and invoiced/locked flags change after the
     * fact. Filtering strictly from the high-water mark would land those edits never. Re-reading a
     * week of days costs nothing beyond the read: records upsert by id, and the engine's content-hash
     * prefetch turns unchanged ones into zero writes.
     *
     * `to` is sent explicitly rather than left to Everhour's default, so the window is one this
     * connector defined instead of one the vendor may redefine.
     */
    protected override AppendDefaultQueryParams(url: string, obj: MJIntegrationObjectEntity): string {
        let out = super.AppendDefaultQueryParams(url, obj);
        if (obj.SupportsIncrementalSync) {
            const today = this.Today();
            const lookbackDays = parseLookbackDays(obj.Configuration);
            out = appendParam(out, 'from', incrementalFromDate(this.currentWatermark, lookbackDays, today));
            out = appendParam(out, 'to', today);
        }
        return out;
    }

    /** Today in UTC as `YYYY-MM-DD`. Isolated so tests can pin the clock. */
    protected Today(): string {
        return new Date().toISOString().slice(0, 10);
    }

    // ─── Fetch ───────────────────────────────────────────────────────

    /**
     * Delegates the whole fetch to the base (pagination, parent iteration, batching) and adds only
     * what the base has no way to know: the per-run date window, and the new watermark.
     *
     * The watermark advances to the maximum `date` actually observed, never to the wall clock. A
     * clock-based watermark would claim coverage of days whose records had not been fetched yet when
     * the run ended.
     */
    public override async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
        this.currentWatermark = ctx.WatermarkValue;
        try {
            const result = await super.FetchChanges(ctx);
            const newWatermark = maxDate(result.Records, ctx.WatermarkValue);
            return newWatermark ? { ...result, NewWatermarkValue: newWatermark } : result;
        } finally {
            this.currentWatermark = null;
        }
    }

    /**
     * Flattens Everhour's nested sub-objects onto the declared columns.
     *
     * Everhour returns compound values as objects (`billing: {type,fee}`, `estimate: {total,type}`,
     * `task: {id,name,…}`) and open-ended ones as arrays or maps (`labels`, `users`, per-integration
     * `attributes`/`metrics`). The sync engine maps a declared column only from a top-level key of the
     * same name, so without this every one of those columns lands null while the run reports success.
     * The base's applyTransformPreservingKeys keeps the original nested keys alongside these, so
     * full-record custom-column capture still sees everything Everhour sent.
     *
     * The open-ended ones are serialized rather than declared: `attributes` and `metrics` are whatever
     * the upstream integration defines per workspace, `userRateOverrides` is keyed by user id, and
     * `labels`/`users` are unbounded. None can be a column in a fixed catalog, so each lands as JSON
     * for downstream projection — an empty collection as null rather than "[]", so "no labels" and
     * "not returned" read the same downstream.
     */
    protected override TransformRecord(
        raw: Record<string, unknown>,
        _obj: MJIntegrationObjectEntity,
        _fields: MJIntegrationObjectFieldEntity[]
    ): Record<string, unknown> {
        const out: Record<string, unknown> = { ...raw };

        for (const [parent, key, target] of NESTED_SCALARS) {
            const value = raw[parent];
            if (isRecord(value)) out[target] = value[key] ?? null;
            else if (value === null) out[target] = null;
        }

        for (const [source, target] of JSON_COLLECTIONS) {
            if (source in raw) out[target] = serializeCollection(raw[source]);
        }

        // The id prefix is the vendor's source-platform discriminator (`as` Asana, `jr` Jira, `ev`
        // native Everhour, …) and is the same value the `platform` filter on /projects accepts. It is
        // promoted to its own column because filtering landed rows by source is otherwise a substring
        // match on the primary key.
        const platform = platformFromID(raw['id']);
        if (platform !== null) out['platform'] = platform;

        return out;
    }

    // ─── Connection test ─────────────────────────────────────────────

    /**
     * Probes `/users/me`. Unlike a workspace-scoped vendor there is no second thing to verify: the API
     * key carries the team, so a key that authenticates is a key that can see the team's data. A 401
     * is reported distinctly from any other failure because it is the only one the tenant can fix by
     * re-entering a credential.
     */
    public override async TestConnection(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<ConnectionTestResult> {
        try {
            const auth = await this.Authenticate(companyIntegration, contextUser);
            const headers = this.BuildHeaders(auth);
            const me = await this.MakeHTTPRequest(auth, `${EVERHOUR_API_BASE}/users/me`, 'GET', headers);
            if (me.Status === 401) {
                return { Success: false, Message: 'Everhour rejected the API key (HTTP 401).' };
            }
            if (me.Status >= 400) {
                return { Success: false, Message: `Everhour /users/me returned HTTP ${me.Status}.` };
            }
            const body = isRecord(me.Body) ? me.Body : {};
            const who = stringOrNull(body['name'])
                ?? stringOrNull(body['email'])
                ?? (body['id'] != null ? String(body['id']) : 'unknown user');
            return {
                Success: true,
                Message: `Connected to Everhour as ${who}.`,
                ServerVersion: EVERHOUR_API_VERSION,
            };
        } catch (err: unknown) {
            const message = err instanceof Error ? err.message : String(err);
            return { Success: false, Message: `Everhour connection error: ${message}` };
        }
    }

    // ─── Credential resolution ───────────────────────────────────────

    /**
     * Resolves the API key from the linked Credential entity, falling back to the
     * CompanyIntegration.Configuration JSON.
     *
     * CompanyIntegration.APIKey is deliberately NOT read — which is a change from the legacy driver,
     * whose `connect()` took the key straight off that column. It is not a decrypt-on-read column, so
     * a value written through mj-sync encryption comes back as the literal `$ENC$…` string and would
     * be sent to Everhour verbatim, authenticating as nobody while looking configured.
     */
    private async LoadCredentials(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<string> {
        let apiKey: string | undefined;

        if (companyIntegration.CredentialID) {
            apiKey = await this.LoadFromCredentialEntity(companyIntegration.CredentialID, contextUser) ?? undefined;
        }
        if (!apiKey && companyIntegration.Configuration) {
            apiKey = this.ParseCredentialJson(companyIntegration.Configuration) ?? undefined;
        }
        if (!apiKey) {
            throw new Error(
                'No Everhour credential found — link an "API Key" credential holding the Everhour API ' +
                'key, or supply one as "apiKey" in the CompanyIntegration.Configuration JSON.'
            );
        }
        return apiKey;
    }

    private async LoadFromCredentialEntity(
        credentialID: string,
        contextUser: UserInfo,
        provider?: IMetadataProvider
    ): Promise<string | null> {
        const md = provider ?? new Metadata();
        const credential = await md.GetEntityObject<MJCredentialEntity>('MJ: Credentials', contextUser);
        const loaded = await credential.Load(credentialID);
        if (!loaded || !credential.Values) return null;
        return this.ParseCredentialJson(credential.Values);
    }

    /** Parses a credential/Configuration JSON blob, tolerating the usual casing/naming aliases. */
    private ParseCredentialJson(json: string): string | null {
        try {
            const result = EverhourCredentialSchema.safeParse(JSON.parse(json));
            if (!result.success) return null;
            const p = result.data;
            const key = p.apiKey ?? p.ApiKey ?? p.APIKey ?? p.key ?? p.Token ?? p.token;
            return key != null && String(key).length > 0 ? String(key) : null;
        } catch {
            return null;
        }
    }
}

// ─── Module-level constants, types + helpers (mechanism, NOT a catalog) ───

/** Everhour's REST base. Single-tenant SaaS with no per-customer host, so there is nothing to configure. */
const EVERHOUR_API_BASE = 'https://api.everhour.com';

/** The API version this catalog was validated against, pinned via X-Accept-Version. */
const EVERHOUR_API_VERSION = '1.2';

/**
 * Documented per-endpoint `limit` maxima. Tasks is the only one Everhour states outright ("250 max");
 * the others use the value the docs show, which is the conservative reading. Time records accept up to
 * 50000, far above any batch this connector would ask for, so the lower cap costs nothing and keeps a
 * runaway page size from turning into a multi-megabyte response.
 */
const MAX_PAGE_SIZE_BY_OBJECT: Readonly<Record<string, number>> = {
    Projects: 100,
    Tasks: 250,
    TimeRecords: 1000,
};

const DEFAULT_MAX_PAGE_SIZE = 100;

/** `[nested object, key within it, flat column]` — Everhour's compound scalars. */
const NESTED_SCALARS: ReadonlyArray<readonly [string, string, string]> = [
    ['billing', 'type', 'billing_type'],
    ['billing', 'fee', 'billing_fee'],
    ['rate', 'type', 'rate_type'],
    ['rate', 'rate', 'rate_rate'],
    ['budget', 'type', 'budget_type'],
    ['budget', 'budget', 'budget_budget'],
    ['budget', 'period', 'budget_period'],
    ['budget', 'progress', 'budget_progress'],
    ['budget', 'timeProgress', 'budget_time_progress'],
    ['budget', 'expenseProgress', 'budget_expense_progress'],
    ['budget', 'appliedFrom', 'budget_applied_from'],
    ['budget', 'threshold', 'budget_threshold'],
    ['budget', 'disallowOverbudget', 'budget_disallow_overbudget'],
    ['budget', 'excludeUnbillableTime', 'budget_exclude_unbillable_time'],
    ['budget', 'excludeExpenses', 'budget_exclude_expenses'],
    ['estimate', 'total', 'estimate_total'],
    ['estimate', 'type', 'estimate_type'],
    ['time', 'total', 'time_total'],
    ['task', 'id', 'task_id'],
    ['task', 'name', 'task_name'],
];

/** Unbounded / workspace-defined collections → the JSON column each is serialized onto. */
const JSON_COLLECTIONS: ReadonlyArray<readonly [string, string]> = [
    ['users', 'users_json'],
    ['projects', 'project_ids_json'],
    ['labels', 'labels_json'],
    ['attributes', 'attributes_json'],
    ['metrics', 'metrics_json'],
    ['history', 'history_json'],
];

/** Auth context: Everhour's single API key, which carries the team scope by itself. */
interface EverhourAuthContext extends RESTAuthContext {
    ApiKey: string;
}

const EverhourCredentialSchema = z.object({
    apiKey: z.string().optional(),
    ApiKey: z.string().optional(),
    APIKey: z.string().optional(),
    key: z.string().optional(),
    Token: z.string().optional(),
    token: z.string().optional(),
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
 * Undoes percent-encoding of the colon.
 *
 * Exported for the tests that pin this behaviour: it is the difference between
 * `/projects/as%3A123/tasks` and `/projects/as:123/tasks`, and every Everhour project id has a colon
 * in it. Only `%3A`/`%3a` is touched — this is not a general URL decode, which would corrupt any
 * legitimately encoded `&`, `=` or space in a query value.
 */
export function restoreColons(url: string): string {
    return url.replace(/%3A/gi, ':');
}

/**
 * Serializes an unbounded collection to JSON, or null when it is empty or absent.
 *
 * Empty collapses to null so that "the project has no assigned users" and "Everhour did not return
 * users" are the same landed value — a literal `"[]"` would read as data downstream and would also
 * change the record's content hash the first time the vendor started omitting an empty array.
 */
export function serializeCollection(value: unknown): string | null {
    if (value == null) return null;
    if (Array.isArray(value)) return value.length > 0 ? JSON.stringify(value) : null;
    if (typeof value === 'object') {
        return Object.keys(value as Record<string, unknown>).length > 0 ? JSON.stringify(value) : null;
    }
    return null;
}

/**
 * The source-platform prefix of an Everhour id (`as:1234` → `as`), or null when the id carries none.
 *
 * Deliberately narrow: two characters followed by a colon is the documented shape of every platform
 * code Everhour publishes (`as`, `ev`, `b2`, `b3`, `pv`, `gh`, `in`, `tr`, `jr` — note two of them
 * contain a digit, hence alphanumeric rather than alphabetic). Anything else is left alone rather than
 * guessed at, so a future id format cannot silently produce a garbage platform value.
 */
export function platformFromID(id: unknown): string | null {
    if (typeof id !== 'string') return null;
    const match = /^([a-z][a-z0-9]):/.exec(id);
    return match ? match[1] : null;
}

/**
 * The start date for a first, unwatermarked sync. Everhour launched well after this, and its API
 * rejects no date this old, so it is "everything" expressed as a bound the vendor will accept —
 * `from` is not optional in the way `to` is, and omitting it lets Everhour choose the window instead.
 */
const EVERHOUR_EPOCH_DATE = '2010-01-01';

/** Default days of already-synced history to re-read on each incremental run. */
const DEFAULT_LOOKBACK_DAYS = 7;

/** A lookback beyond this is indistinguishable from a full re-sync; treat it as a misconfiguration. */
const MAX_LOOKBACK_DAYS = 3650;

/**
 * The `from` date for an incremental fetch: the watermark backdated by the lookback window, clamped
 * so it can never land in the future.
 *
 * With no watermark yet — a first run — this returns the epoch bound rather than `today - lookback`,
 * so the initial sync pulls the full history. Getting that backwards would make a first sync look
 * complete while holding one week of data.
 */
export function incrementalFromDate(
    watermark: string | null,
    lookbackDays: number,
    today: string
): string {
    if (!watermark) return EVERHOUR_EPOCH_DATE;
    const base = Date.parse(`${watermark.slice(0, 10)}T00:00:00Z`);
    if (Number.isNaN(base)) return EVERHOUR_EPOCH_DATE;
    const shifted = new Date(base - lookbackDays * 86_400_000).toISOString().slice(0, 10);
    return shifted > today ? today : shifted;
}

/**
 * Reads `lookbackDays` out of an IntegrationObject's Configuration JSON, falling back to the default.
 *
 * A non-numeric, negative or absurd value falls back rather than throwing: this is tenant-editable
 * configuration, and a typo in it should not take the object's sync down.
 */
export function parseLookbackDays(configuration: string | null): number {
    if (!configuration) return DEFAULT_LOOKBACK_DAYS;
    try {
        const parsed: unknown = JSON.parse(configuration);
        if (!isRecord(parsed)) return DEFAULT_LOOKBACK_DAYS;
        const value = parsed['lookbackDays'];
        if (typeof value !== 'number' || !Number.isFinite(value)) return DEFAULT_LOOKBACK_DAYS;
        if (value < 0 || value > MAX_LOOKBACK_DAYS) return DEFAULT_LOOKBACK_DAYS;
        return Math.floor(value);
    } catch {
        return DEFAULT_LOOKBACK_DAYS;
    }
}

/**
 * The highest `date` across a batch, or null when the batch moves it nowhere.
 *
 * Compared as strings, which is correct for the fixed-width `YYYY-MM-DD` form Everhour emits. The
 * previous watermark seeds the comparison so a batch containing only older records — which the
 * lookback window guarantees on every incremental run — can never drag the high-water mark backwards.
 */
export function maxDate(
    records: ReadonlyArray<{ Fields: Record<string, unknown> }>,
    previous: string | null
): string | null {
    let best = previous;
    for (const record of records) {
        const value = record.Fields['date'];
        if (typeof value !== 'string' || value.length === 0) continue;
        if (best === null || value > best) best = value;
    }
    return best === previous ? null : best;
}
