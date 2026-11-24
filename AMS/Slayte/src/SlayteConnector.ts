import { z } from 'zod';
import { RegisterClass } from '@memberjunction/global';
import { Metadata, type UserInfo } from '@memberjunction/core';
import type {
    MJCompanyIntegrationEntity,
    MJCredentialEntity,
    MJIntegrationObjectEntity,
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
    type FetchWarning,
    type ExternalRecord,
    type GetRecordContext,
    type RateLimitPolicy,
    type SourceSchemaInfo,
    type SourceObjectInfo,
} from '@memberjunction/integration-engine';
import { mergeDeclaredWithSampledFields } from '@memberjunction/connector-schema-merge';

// ─── Design Note ────────────────────────────────────────────────────────
//
// Slayte API v2 (2026-10-01) is a per-workspace REST API authenticated via
// `X-Api-Key`. There is no shared vendor API host; each workspace exposes
// `<SiteUrl>/api/v2/...`.
//
// Bulk reads for Individuals and Organizations have no REST list route in v2 —
// they execute a workspace's Shared CRM Query via
// `POST /v2/crm/query/{queryId}/execute?cursor=...` with cursor pagination,
// where `queryId` comes from `CompanyIntegration.Configuration`
// (`individualQueryId` / `organizationQueryId`), never from a parent walk.
// Accordingly, the `Individual` and `Organization` metadata objects declare
// the untemplated door `/v2/crm/query`, and `FetchChanges` routes them to the
// configured query execution endpoint.
//
// REST collection endpoints (Committees, Events, Sessions, Speakers, Companies,
// Registrations, Registrants, Guests) use ZERO-based `page` numbering
// (`page=0` is the first page, `pageSize` max 250) and return
// `{ success: true, data: { items: [...], total: N } }`. Because
// `BaseRESTIntegrationConnector` uses 1-based `currentPage`, `BuildPaginatedURL`
// translates `page = Math.max(0, page - 1)`.
//
// Because Slayte workspaces define custom fields and custom CRM query columns,
// the metadata catalog declares only standard built-in Slayte v2 core fields,
// and `IntrospectSchema` unions them with live sampled fields via
// `@memberjunction/connector-schema-merge`.

// ─── Schemas & Types ────────────────────────────────────────────────────

const RawSlayteCredentialsSchema = z.object({
    SiteUrl: z.string().min(1).optional(),
    siteUrl: z.string().min(1).optional(),
    BaseURL: z.string().min(1).optional(),
    baseUrl: z.string().min(1).optional(),
    ApiKey: z.string().min(1).optional(),
    apiKey: z.string().min(1).optional(),
    QueryApiKey: z.string().min(1).optional(),
    queryApiKey: z.string().min(1).optional(),
}).passthrough();

/**
 * Per-connection settings stored in `CompanyIntegration.Configuration`.
 * All fields are optional at parse time; `individualQueryId` and
 * `organizationQueryId` are strictly required when syncing `Individual` or
 * `Organization`.
 */
export const SlayteConnectionSettingsSchema = z.object({
    /** Shared CRM query UUID or share-link ID used to bulk-fetch Individuals. */
    individualQueryId: z.string().min(1).optional(),
    /** Optional parameter map passed as `{ params }` when executing `individualQueryId`. */
    individualQueryParams: z.record(z.unknown()).optional(),
    /** Shared CRM query UUID or share-link ID used to bulk-fetch Organizations. */
    organizationQueryId: z.string().min(1).optional(),
    /** Optional parameter map passed as `{ params }` when executing `organizationQueryId`. */
    organizationQueryParams: z.record(z.unknown()).optional(),
    /** Optional comma-separated field list or field group for `GET /v2/crm/individual/{uuid}`. */
    individualFields: z.string().min(1).optional(),
    /** Optional comma-separated field list or field group for `GET /v2/crm/organization/{uuid}`. */
    organizationFields: z.string().min(1).optional(),
    /** Optional comma-separated field list or field group for `GET /v2/crm/committee`. */
    committeeFields: z.string().min(1).optional(),
    /** Non-secret API host override (e.g. local mock server for replay tests). Wins over SiteUrl. */
    ApiBaseUrl: z.string().url().optional(),
    /** Alternate camelCase host override. */
    apiBaseUrl: z.string().url().optional(),
    /** HTTP request timeout in milliseconds. Default: 30000. */
    requestTimeoutMs: z.number().int().positive().optional(),
    /** Maximum retry attempts for HTTP 429 / 502 / 503 / 504 responses. Default: 3. */
    maxRetries: z.number().int().min(0).max(10).optional(),
}).passthrough();

export type SlayteConnectionSettings = z.infer<typeof SlayteConnectionSettingsSchema>;

interface SlayteAuthContext extends RESTAuthContext {
    ApiKey: string;
    QueryApiKey: string;
    BaseUrl: string;
    Settings: SlayteConnectionSettings;
}

interface SlayteErrorDetail {
    code?: number;
    type?: string;
    message?: string;
    field?: string;
    details?: Record<string, unknown>;
}

interface SlayteErrorBody {
    success?: boolean;
    error?: SlayteErrorDetail;
    code?: string;
    message?: string;
}

interface SlayteQueryExecuteData {
    data?: unknown[];
    labels?: {
        membershipDefinitions?: Record<string, string>;
        membershipTiers?: Record<string, string>;
    };
    cursor?: string | null;
    totalRecordCount?: number | null;
    warnings?: string[];
}

interface SlayteDirectoryRecord {
    uuid: string;
    slug: string;
    name?: string;
    entityType?: string;
}

interface SlayteDirectoryPageData {
    data?: Array<{
        entityUuid?: string;
        entity?: Record<string, unknown>;
        tags?: string[];
    }>;
    cursor?: string | null;
    lastSyncAt?: string | null;
}

// ─── Constants ──────────────────────────────────────────────────────────

const DEFAULT_TIMEOUT_MS = 30000;
const DEFAULT_MAX_RETRIES = 3;
const DEFAULT_PAGE_SIZE = 100;
const MAX_REST_PAGE_SIZE = 250;
const MAX_DIRECTORY_PAGE_SIZE = 1000;
const INTROSPECT_CONCURRENCY = 4;

/** Standard built-in core fields requested on `GetRecord` when no custom `fields` group is configured. */
const DEFAULT_INDIVIDUAL_CORE_FIELDS = [
    'individualUuid', 'userUuid', 'recordNumber', 'firstName', 'middleName', 'lastName',
    'preferredName', 'prefix', 'suffix', 'profileEmail', 'profileTitle', 'imageUrl',
    'gender', 'taxExemptNumber', 'directoryOptOut', 'emailOptOut', 'isDeceased',
    'emails', 'profileAddress', 'addresses', 'profilePhoneNumber', 'phoneNumbers',
    'designations', 'expertises', 'industries', 'services', 'languages', 'region',
    'licenses', 'webLinks', 'userAccounts', 'membership', 'profileOrg', 'committees',
].join(',');

const DEFAULT_ORGANIZATION_CORE_FIELDS = [
    'organizationUuid', 'recordNumber', 'name', 'description', 'domain', 'profileEmail',
    'imageUrl', 'acronym', 'branchName', 'organizationType', 'employeeRange',
    'numberOfOffices', 'taxExemptNumber', 'directoryOptOut', 'emailOptOut', 'isClosed',
    'emails', 'profileAddress', 'addresses', 'profilePhoneNumber', 'phoneNumbers',
    'expertises', 'industries', 'services', 'region', 'webLinks', 'membership',
].join(',');

const QUERY_OBJECTS: Record<string, {
    entityType: 'ind' | 'org';
    configKey: 'individualQueryId' | 'organizationQueryId';
    paramsKey: 'individualQueryParams' | 'organizationQueryParams';
    primaryKeyField: 'individualUuid' | 'organizationUuid';
    keyCandidates: readonly string[];
}> = {
    Individual: {
        entityType: 'ind',
        configKey: 'individualQueryId',
        paramsKey: 'individualQueryParams',
        primaryKeyField: 'individualUuid',
        keyCandidates: ['individualUuid', 'uuid', 'id'],
    },
    Organization: {
        entityType: 'org',
        configKey: 'organizationQueryId',
        paramsKey: 'organizationQueryParams',
        primaryKeyField: 'organizationUuid',
        keyCandidates: ['organizationUuid', 'uuid', 'id'],
    },
};

// ─── SlayteConnector ────────────────────────────────────────────────────

/**
 * Slayte AMS connector (read-only) — extends `BaseRESTIntegrationConnector`.
 *
 * Registered under both the package name (fleet convention, matching
 * `Integration.ClassName`) and the class symbol alias.
 */
@RegisterClass(BaseIntegrationConnector, '@memberjunction/connector-slayte')
@RegisterClass(BaseIntegrationConnector, 'SlayteConnector')
export class SlayteConnector extends BaseRESTIntegrationConnector {

    /** Active incremental `changedSince` value scoped to one `super.FetchChanges` call. */
    private activeChangedSince: string | null = null;

    /** Active committee `fields` override scoped to one `super.FetchChanges` call. */
    private activeCommitteeFields: string | null = null;

    public override get IntegrationName(): string {
        return 'Slayte';
    }

    // Read-only connector in v0.1.0
    public override get SupportsCreate(): boolean { return false; }
    public override get SupportsUpdate(): boolean { return false; }
    public override get SupportsDelete(): boolean { return false; }
    public override get SupportsUpsert(): boolean { return false; }

    /** Cache-driven declared catalog + bounded runtime sampling is not authoritative for deactivation. */
    public override get DiscoveryIsAuthoritative(): boolean {
        return false;
    }

    /**
     * Slayte's default ceiling is 600 req/min (10 req/s) in a fixed UTC minute window.
     * 8 req/s with burst 20 stays <= 500 req/min with headroom for retries and other clients.
     */
    public override get RateLimitPolicy(): RateLimitPolicy {
        return { TokensPerSec: 8, Burst: 20 };
    }

    public override get MaxConcurrencyHint(): number {
        return 4;
    }

    public override ExtractRetryAfterMs(error: unknown): number | undefined {
        const fromBase = super.ExtractRetryAfterMs(error);
        if (fromBase !== undefined) return fromBase;
        if (error && typeof error === 'object') {
            const headers = (error as { headers?: Record<string, string> }).headers;
            if (headers) {
                const parsed = parseRetryDelayMs(headers);
                if (parsed !== undefined) return parsed;
            }
        }
        return undefined;
    }

    // ── Hybrid Schema Discovery (Connector Discovery Standard) ──────────

    /**
     * Unions the declared core Slayte v2 catalog with a bounded live sample via MJ's
     * `DiscoverFieldsViaFetch` + `mergeDeclaredWithSampledFields`. This is how workspace
     * custom fields and configured Shared CRM Query output columns are discovered before
     * the first sync without hardcoding any tenant-specific fields in metadata.
     */
    public override async IntrospectSchema(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<SourceSchemaInfo> {
        const schema = await super.IntrospectSchema(companyIntegration, contextUser);

        await runBounded(schema.Objects, INTROSPECT_CONCURRENCY, async (obj: SourceObjectInfo) => {
            try {
                const sampled = await this.DiscoverFieldsViaFetch(companyIntegration, obj.ExternalName, contextUser);
                obj.Fields = mergeDeclaredWithSampledFields(obj.Fields, sampled);
            } catch {
                // Keep declared fields for this object — sampling never breaks introspection
                // (e.g., an unconfigured query ID or a 403 SCOPE_REQUIRED surface).
            }
        });

        return schema;
    }

    // ── Authentication & Configuration ──────────────────────────────────

    protected override async Authenticate(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<SlayteAuthContext> {
        const settings = parseConnectionSettings(companyIntegration.Configuration);
        const rawCreds = await this.loadRawCredentials(companyIntegration, contextUser);
        const parsed = RawSlayteCredentialsSchema.safeParse(rawCreds);
        if (!parsed.success) {
            throw new Error(`Invalid Slayte credentials: ${parsed.error.message}`);
        }

        const apiKey = (parsed.data.ApiKey ?? parsed.data.apiKey ?? '').trim();
        const queryApiKey = (parsed.data.QueryApiKey ?? parsed.data.queryApiKey ?? '').trim() || apiKey;
        const rawSiteUrl = (
            settings.ApiBaseUrl ??
            settings.apiBaseUrl ??
            parsed.data.SiteUrl ??
            parsed.data.siteUrl ??
            parsed.data.BaseURL ??
            parsed.data.baseUrl ??
            ''
        ).trim();

        if (!apiKey) {
            throw new Error('Slayte credentials require ApiKey.');
        }
        if (!rawSiteUrl) {
            throw new Error('Slayte credentials require SiteUrl (your workspace root URL, e.g. https://your-site.slayte.com).');
        }

        const baseUrl = normalizeSlayteBaseUrl(rawSiteUrl);
        return {
            Token: apiKey,
            ApiKey: apiKey,
            QueryApiKey: queryApiKey,
            BaseUrl: baseUrl,
            Settings: settings,
        };
    }

    protected override BuildHeaders(auth: RESTAuthContext): Record<string, string> {
        const slayteAuth = auth as SlayteAuthContext;
        return {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'X-Api-Key': slayteAuth.ApiKey,
        };
    }

    protected buildQueryHeaders(auth: SlayteAuthContext): Record<string, string> {
        return {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            'X-Api-Key': auth.QueryApiKey,
        };
    }

    protected override GetBaseURL(
        companyIntegration: MJCompanyIntegrationEntity,
        auth: RESTAuthContext
    ): string {
        const slayteAuth = auth as SlayteAuthContext | undefined;
        if (slayteAuth?.BaseUrl) return slayteAuth.BaseUrl;
        const settings = parseConnectionSettings(companyIntegration?.Configuration);
        const override = settings.ApiBaseUrl ?? settings.apiBaseUrl;
        if (override) return normalizeSlayteBaseUrl(override);
        throw new Error('Slayte SiteUrl is not configured.');
    }

    // ── HTTP Transport ──────────────────────────────────────────────────

    protected override async MakeHTTPRequest(
        auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown
    ): Promise<RESTResponse> {
        const slayteAuth = auth as SlayteAuthContext;
        const timeoutMs = slayteAuth.Settings?.requestTimeoutMs ?? DEFAULT_TIMEOUT_MS;
        const maxRetries = slayteAuth.Settings?.maxRetries ?? DEFAULT_MAX_RETRIES;

        let lastResponse: RESTResponse | null = null;
        for (let attempt = 0; attempt <= maxRetries; attempt++) {
            const init: RequestInit = {
                method,
                headers,
                signal: AbortSignal.timeout(timeoutMs),
            };
            if (body !== undefined && method !== 'GET' && method !== 'HEAD') {
                init.body = typeof body === 'string' ? body : JSON.stringify(body);
            }

            const resp = await fetch(url, init);
            const respHeaders: Record<string, string> = {};
            resp.headers.forEach((value, key) => {
                respHeaders[key.toLowerCase()] = value;
            });

            const text = await resp.text();
            let parsedBody: unknown = text;
            if (text.length > 0) {
                try {
                    parsedBody = JSON.parse(text);
                } catch {
                    parsedBody = text;
                }
            } else {
                parsedBody = null;
            }

            const result: RESTResponse = {
                Status: resp.status,
                Body: parsedBody,
                Headers: respHeaders,
            };

            const retryable = resp.status === 429 || resp.status === 502 || resp.status === 503 || resp.status === 504;
            if (!retryable || attempt === maxRetries) {
                return result;
            }

            lastResponse = result;
            const retryAfterMs = parseRetryDelayMs(respHeaders);
            const backoffMs = retryAfterMs !== undefined
                ? Math.min(retryAfterMs, timeoutMs)
                : Math.min(500 * Math.pow(2, attempt), 8000);
            await this.sleep(backoffMs);
        }

        return lastResponse!;
    }

    /** Seam for deterministic backoff unit tests. */
    protected sleep(ms: number): Promise<void> {
        if (ms <= 0) return Promise.resolve();
        return new Promise((resolve) => setTimeout(resolve, ms));
    }

    // ── Response Normalization & Pagination ─────────────────────────────

    protected override NormalizeResponse(
        rawBody: unknown,
        responseDataKey: string | null
    ): Record<string, unknown>[] {
        if (Array.isArray(rawBody)) {
            return rawBody.filter(isPlainObject);
        }
        if (!isPlainObject(rawBody)) {
            return [];
        }

        // Respect explicit dot-path ResponseDataKey (e.g. "data.items", "data.data", "data")
        if (responseDataKey) {
            const resolved = readDotPath(rawBody, responseDataKey);
            if (Array.isArray(resolved)) {
                return resolved.filter(isPlainObject);
            }
        }

        // Fallback across standard Slayte v2 envelopes
        const data = rawBody.data;
        if (Array.isArray(data)) return data.filter(isPlainObject);
        if (isPlainObject(data)) {
            if (Array.isArray(data.items)) return data.items.filter(isPlainObject);
            if (Array.isArray(data.data)) return data.data.filter(isPlainObject);
        }
        return [];
    }

    protected override ExtractPaginationInfo(
        rawBody: unknown,
        paginationType: PaginationType,
        currentPage: number,
        _currentOffset: number,
        pageSize: number
    ): PaginationState {
        if (paginationType === 'None' || !isPlainObject(rawBody)) {
            return { HasMore: false };
        }

        const data = isPlainObject(rawBody.data) ? rawBody.data : rawBody;

        if (paginationType === 'Cursor') {
            const cursor = typeof data.cursor === 'string' && data.cursor.length > 0 ? data.cursor : undefined;
            const rows = Array.isArray(data.data) ? data.data : [];
            const total = typeof data.totalRecordCount === 'number' ? data.totalRecordCount : undefined;
            return {
                HasMore: Boolean(cursor && rows.length > 0),
                NextCursor: cursor,
                TotalRecords: total,
            };
        }

        if (paginationType === 'PageNumber') {
            const items = Array.isArray(data.items) ? data.items : [];
            const total = typeof data.total === 'number' ? data.total : undefined;
            const effectiveSize = typeof data.pageSize === 'number' && data.pageSize > 0
                ? data.pageSize
                : Math.min(MAX_REST_PAGE_SIZE, Math.max(1, pageSize || DEFAULT_PAGE_SIZE));
            // Slayte REST endpoints are 0-based; MJ's BaseRESTIntegrationConnector passes 1-based currentPage
            const zeroBasedPage = typeof data.page === 'number' && data.page >= 0
                ? data.page
                : Math.max(0, currentPage - 1);

            if (items.length === 0) {
                return { HasMore: false, TotalRecords: total };
            }
            if (total !== undefined) {
                const fetchedSoFar = (zeroBasedPage + 1) * effectiveSize;
                const hasMore = fetchedSoFar < total;
                return {
                    HasMore: hasMore,
                    NextPage: hasMore ? currentPage + 1 : undefined,
                    TotalRecords: total,
                };
            }
            // Fallback when total is absent: another page may exist iff a full page was returned
            const hasMore = items.length >= effectiveSize;
            return {
                HasMore: hasMore,
                NextPage: hasMore ? currentPage + 1 : undefined,
            };
        }

        return { HasMore: false };
    }

    /**
     * Translates MJ's 1-based `page` into Slayte's 0-based `page` (`minimum: 0`,
     * `pageSize` clamped to 1..250), and attaches `includeids=true` / `fields` on
     * Committee list calls and `changedSince` on incremental `EventRegistrant` calls.
     */
    protected override BuildPaginatedURL(
        basePath: string,
        obj: MJIntegrationObjectEntity,
        page: number,
        _offset: number,
        cursor?: string,
        effectivePageSize?: number
    ): string {
        const params = new URLSearchParams();
        const paginationType = (obj.PaginationType ?? 'None') as PaginationType;
        const pageSize = Math.min(
            MAX_REST_PAGE_SIZE,
            Math.max(1, effectivePageSize ?? obj.DefaultPageSize ?? DEFAULT_PAGE_SIZE)
        );

        if (paginationType === 'PageNumber') {
            const zeroBasedPage = Math.max(0, (page || 1) - 1);
            params.set('page', String(zeroBasedPage));
            params.set('pageSize', String(pageSize));
        } else if (paginationType === 'Cursor' && cursor) {
            params.set('cursor', cursor);
        }

        if (obj.Name === 'Committee') {
            params.set('includeids', 'true');
            if (this.activeCommitteeFields) {
                params.set('fields', this.activeCommitteeFields);
            }
        }

        if (obj.Name === 'EventRegistrant' && this.activeChangedSince) {
            params.set('changedSince', this.activeChangedSince);
        }

        const qs = params.toString();
        if (!qs) return basePath;
        return basePath.includes('?') ? `${basePath}&${qs}` : `${basePath}?${qs}`;
    }

    protected override ExtractErrorMessage(response: RESTResponse): string | undefined {
        return formatSlayteError(response);
    }

    // ── TestConnection ──────────────────────────────────────────────────

    /**
     * Validates credentials, workspace connectivity, and (when `individualQueryId`
     * and/or `organizationQueryId` are configured) probes the configured Shared CRM
     * Queries and fails with an actionable error if returned rows lack a primary key column.
     */
    public override async TestConnection(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<ConnectionTestResult> {
        let auth: SlayteAuthContext;
        try {
            auth = await this.Authenticate(companyIntegration, contextUser);
        } catch (err) {
            return {
                Success: false,
                Message: err instanceof Error ? err.message : String(err),
            };
        }

        let apiVersion: string | undefined;
        const checkedNotes: string[] = [];

        // 1. Validate any configured bulk Shared CRM Queries (and fail if rows omit a key column)
        for (const [objectName, spec] of Object.entries(QUERY_OBJECTS)) {
            const queryId = auth.Settings[spec.configKey];
            if (!queryId) continue;

            const params = auth.Settings[spec.paramsKey];
            const url = `${auth.BaseUrl}/v2/crm/query/${encodeURIComponent(queryId)}/execute`;
            const body = params && Object.keys(params).length > 0 ? { params } : {};
            let resp: RESTResponse;
            try {
                resp = await this.MakeHTTPRequest(auth, url, 'POST', this.buildQueryHeaders(auth), body);
            } catch (err) {
                return {
                    Success: false,
                    Message: `Failed to execute Slayte ${objectName} query '${queryId}': ${err instanceof Error ? err.message : String(err)}`,
                };
            }

            if (resp.Status < 200 || resp.Status >= 300) {
                return {
                    Success: false,
                    Message: `Slayte ${objectName} query '${queryId}' failed (HTTP ${resp.Status}): ${formatSlayteError(resp)}`,
                };
            }

            apiVersion = apiVersion ?? resp.Headers['x-api-version'];
            const queryData = extractQueryData(resp.Body);
            const rows = Array.isArray(queryData.data) ? queryData.data.filter(isPlainObject) : [];
            if (rows.length > 0) {
                const keyErr = validateQueryRowKey(objectName, queryId, rows[0], spec.primaryKeyField, spec.keyCandidates);
                if (keyErr) {
                    return { Success: false, Message: keyErr };
                }
            }
            checkedNotes.push(`${objectName} query verified (${rows.length} row(s) on first page)`);
        }

        // 2. Validate primary ApiKey when no queries were configured OR QueryApiKey differs from ApiKey
        const needPrimaryProbe = checkedNotes.length === 0 || auth.ApiKey !== auth.QueryApiKey;
        if (needPrimaryProbe) {
            const probePaths = [
                '/v2/crm/query?entityType=ind',
                '/v2/event?page=0&pageSize=1',
                '/v2/crm/committee?page=0&pageSize=1',
                '/v2/directory',
            ];
            let primaryOk = false;
            let lastFailure = '';

            for (const path of probePaths) {
                const headers = path.startsWith('/v2/crm/query') && checkedNotes.length === 0
                    ? this.buildQueryHeaders(auth)
                    : this.BuildHeaders(auth);
                let resp: RESTResponse;
                try {
                    resp = await this.MakeHTTPRequest(auth, `${auth.BaseUrl}${path}`, 'GET', headers);
                } catch (err) {
                    return {
                        Success: false,
                        Message: `Connection to Slayte workspace failed: ${err instanceof Error ? err.message : String(err)}`,
                    };
                }

                if (resp.Status >= 200 && resp.Status < 300) {
                    apiVersion = apiVersion ?? resp.Headers['x-api-version'];
                    primaryOk = true;
                    break;
                }

                lastFailure = `HTTP ${resp.Status}: ${formatSlayteError(resp)}`;
                // Auth failures (invalid/expired key) are fatal across every route — fail immediately
                if (resp.Status === 401) {
                    return { Success: false, Message: `Slayte authentication failed (${lastFailure})` };
                }
                // 403 SCOPE_REQUIRED on one surface → try the next read probe before failing
                if (resp.Status !== 403) {
                    return { Success: false, Message: `Slayte connection test failed (${lastFailure})` };
                }
            }

            if (!primaryOk) {
                return {
                    Success: false,
                    Message: `Slayte API key lacked required read scope on all probe routes (${lastFailure})`,
                };
            }
        }

        const detail = checkedNotes.length > 0 ? ` — ${checkedNotes.join('; ')}` : '';
        return {
            Success: true,
            Message: `Connected to Slayte API v2${detail}`,
            ServerVersion: apiVersion ?? '2026-10-01',
        };
    }

    // ── FetchChanges ────────────────────────────────────────────────────

    public override async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
        if (ctx.ObjectName === 'Individual' || ctx.ObjectName === 'Organization') {
            return await this.fetchCRMQueryObject(ctx, ctx.ObjectName);
        }
        if (ctx.ObjectName === 'CRMQuery') {
            return await this.fetchCRMQueryCatalog(ctx);
        }
        if (ctx.ObjectName === 'DirectoryEntry') {
            return await this.fetchDirectoryEntries(ctx);
        }

        // Standard REST GET collections (Committee, Event, EventRegistrant, etc.)
        const auth = await this.Authenticate(ctx.CompanyIntegration, ctx.ContextUser);
        this.activeChangedSince = ctx.ObjectName === 'EventRegistrant' && ctx.WatermarkValue
            ? ctx.WatermarkValue
            : null;
        this.activeCommitteeFields = ctx.ObjectName === 'Committee'
            ? (auth.Settings.committeeFields ?? null)
            : null;

        try {
            const result = await super.FetchChanges(ctx);
            if (ctx.ObjectName === 'EventRegistrant' && !result.HasMore) {
                const maxDate = computeMaxIsoTimestamp(result.Records, 'registrationDate');
                if (maxDate) {
                    result.NewWatermarkValue = maxDate;
                }
            }
            return result;
        } finally {
            this.activeChangedSince = null;
            this.activeCommitteeFields = null;
        }
    }

    /**
     * Bulk-fetches `Individual` or `Organization` via a configured Shared CRM Query
     * (`POST /v2/crm/query/{queryId}/execute?cursor=...`).
     *
     * Throws explicitly when the query ID is not configured OR when returned rows omit
     * a recognized primary key column — never returns a silent 0-row success.
     */
    private async fetchCRMQueryObject(
        ctx: FetchContext,
        objectName: 'Individual' | 'Organization'
    ): Promise<FetchBatchResult> {
        const spec = QUERY_OBJECTS[objectName];
        const auth = await this.Authenticate(ctx.CompanyIntegration, ctx.ContextUser);
        const queryId = auth.Settings[spec.configKey];

        if (!queryId) {
            throw new Error(
                `Slayte "${objectName}" sync requires CompanyIntegration.Configuration.${spec.configKey} ` +
                `(the UUID or share-link ID of a Shared CRM Query with entityType="${spec.entityType}"). ` +
                `Sync or inspect the CRMQuery object (GET /v2/crm/query?entityType=${spec.entityType}) to list available query IDs.`
            );
        }

        if (ctx.RateLimitAcquire) await ctx.RateLimitAcquire();

        const qs = ctx.CurrentCursor ? `?cursor=${encodeURIComponent(ctx.CurrentCursor)}` : '';
        const url = `${auth.BaseUrl}/v2/crm/query/${encodeURIComponent(queryId)}/execute${qs}`;
        const params = auth.Settings[spec.paramsKey];
        const body = params && Object.keys(params).length > 0 ? { params } : {};

        let resp: RESTResponse;
        try {
            resp = await this.MakeHTTPRequest(auth, url, 'POST', this.buildQueryHeaders(auth), body);
        } catch (err) {
            ctx.RateLimitReport?.(err);
            throw err;
        }

        if (resp.Status === 429) {
            const err = Object.assign(
                new Error(`Slayte rate limit hit (HTTP 429) on ${objectName} query '${queryId}': ${formatSlayteError(resp)}`),
                { status: 429, headers: resp.Headers }
            );
            ctx.RateLimitReport?.(err);
            throw err;
        }
        ctx.RateLimitReport?.();

        if (resp.Status < 200 || resp.Status >= 300) {
            throw new Error(
                `Slayte ${objectName} query '${queryId}' failed (HTTP ${resp.Status}): ${formatSlayteError(resp)}`
            );
        }

        const queryData = extractQueryData(resp.Body);
        const rawRows = Array.isArray(queryData.data) ? queryData.data.filter(isPlainObject) : [];
        const records: ExternalRecord[] = [];

        for (const row of rawRows) {
            const keyErr = validateQueryRowKey(objectName, queryId, row, spec.primaryKeyField, spec.keyCandidates);
            if (keyErr) {
                throw new Error(keyErr);
            }
            const idValue = extractFirstNonEmptyString(row, spec.keyCandidates)!;
            const normalizedFields: Record<string, unknown> = { ...row };
            if (normalizedFields[spec.primaryKeyField] === undefined || normalizedFields[spec.primaryKeyField] === null) {
                normalizedFields[spec.primaryKeyField] = idValue;
            }
            records.push({
                ExternalID: idValue,
                ObjectType: objectName,
                Fields: normalizedFields,
                IsDeleted: false,
            });
        }

        const nextCursor = typeof queryData.cursor === 'string' && queryData.cursor.length > 0
            ? queryData.cursor
            : undefined;
        const hasMore = Boolean(nextCursor && rawRows.length > 0);

        const warnings: FetchWarning[] = [];
        if (Array.isArray(queryData.warnings)) {
            for (const w of queryData.warnings) {
                if (typeof w === 'string' && w.trim().length > 0) {
                    warnings.push({
                        Code: 'SLAYTE_QUERY_WARNING',
                        Message: `${objectName} query '${queryId}': ${w}`,
                        Data: { object: objectName, queryId },
                    });
                }
            }
        }

        return {
            Records: records,
            HasMore: hasMore,
            NextCursor: hasMore ? nextCursor : undefined,
            Warnings: warnings.length > 0 ? warnings : undefined,
        };
    }

    /** Lists all shared CRM queries across both `entityType=ind` and `entityType=org`. */
    private async fetchCRMQueryCatalog(ctx: FetchContext): Promise<FetchBatchResult> {
        const auth = await this.Authenticate(ctx.CompanyIntegration, ctx.ContextUser);
        const records: ExternalRecord[] = [];

        for (const entityType of ['ind', 'org'] as const) {
            if (ctx.RateLimitAcquire) await ctx.RateLimitAcquire();
            const url = `${auth.BaseUrl}/v2/crm/query?entityType=${entityType}`;
            const resp = await this.MakeHTTPRequest(auth, url, 'GET', this.buildQueryHeaders(auth));
            if (resp.Status === 429) {
                const err = Object.assign(
                    new Error(`Slayte rate limit hit (HTTP 429) listing CRM queries (${entityType}): ${formatSlayteError(resp)}`),
                    { status: 429, headers: resp.Headers }
                );
                ctx.RateLimitReport?.(err);
                throw err;
            }
            ctx.RateLimitReport?.();

            if (resp.Status < 200 || resp.Status >= 300) {
                throw new Error(
                    `Slayte GET /v2/crm/query?entityType=${entityType} failed (HTTP ${resp.Status}): ${formatSlayteError(resp)}`
                );
            }

            const rows = this.NormalizeResponse(resp.Body, 'data');
            for (const row of rows) {
                const id = typeof row.uuid === 'string' ? row.uuid.trim() : '';
                if (!id) continue;
                records.push({
                    ExternalID: id,
                    ObjectType: 'CRMQuery',
                    Fields: { ...row, entityType },
                    IsDeleted: false,
                });
            }
        }

        return { Records: records, HasMore: false };
    }

    /**
     * Fetches `DirectoryEntry` rows across all configured directories via cursor-paginated
     * `POST /v2/directory/{identifier}?cursor=...`. Resumes across calls via
     * `AfterKeyValue` (`<dirIndex>|<cursor>`) and respects `IsDiscoverySample` /
     * `SampleTargetRecords` / `DeadlineMs`.
     */
    private async fetchDirectoryEntries(ctx: FetchContext): Promise<FetchBatchResult> {
        const auth = await this.Authenticate(ctx.CompanyIntegration, ctx.ContextUser);
        const headers = this.BuildHeaders(auth);

        // Fetch directory list once per call to resolve slugs & UUIDs
        if (ctx.RateLimitAcquire) await ctx.RateLimitAcquire();
        const dirResp = await this.MakeHTTPRequest(auth, `${auth.BaseUrl}/v2/directory`, 'GET', headers);
        ctx.RateLimitReport?.(dirResp.Status === 429 ? dirResp : undefined);
        if (dirResp.Status < 200 || dirResp.Status >= 300) {
            throw new Error(`Slayte GET /v2/directory failed (HTTP ${dirResp.Status}): ${formatSlayteError(dirResp)}`);
        }

        const directories = this.NormalizeResponse(dirResp.Body, 'data')
            .map((d): SlayteDirectoryRecord | null => {
                const uuid = typeof d.uuid === 'string' ? d.uuid.trim() : '';
                const slug = typeof d.slug === 'string' ? d.slug.trim() : '';
                if (!uuid || !slug) return null;
                return {
                    uuid,
                    slug,
                    name: typeof d.name === 'string' ? d.name : undefined,
                    entityType: typeof d.entityType === 'string' ? d.entityType : undefined,
                };
            })
            .filter((d): d is SlayteDirectoryRecord => d !== null);

        if (directories.length === 0) {
            return {
                Records: [],
                HasMore: false,
                Warnings: [{
                    Code: 'ZERO_PARENTS',
                    Message: 'Slayte workspace returned 0 configured directories; no DirectoryEntry records to sync.',
                }],
            };
        }

        const { dirIndex, cursor } = parseDirectoryResumeKey(ctx.AfterKeyValue);
        if (dirIndex >= directories.length) {
            return { Records: [], HasMore: false };
        }

        const pageSize = Math.min(MAX_DIRECTORY_PAGE_SIZE, Math.max(1, ctx.BatchSize || DEFAULT_PAGE_SIZE));
        const records: ExternalRecord[] = [];
        let currentIdx = dirIndex;
        let currentCursor = cursor;

        const sampleCtx = ctx as FetchContext & {
            IsDiscoverySample?: boolean;
            SampleTargetRecords?: number;
            DeadlineMs?: number;
        };

        while (currentIdx < directories.length) {
            if (sampleCtx.DeadlineMs && Date.now() >= sampleCtx.DeadlineMs) {
                return {
                    Records: records,
                    HasMore: true,
                    NextAfterKeyValue: encodeDirectoryResumeKey(currentIdx, currentCursor),
                };
            }

            const dir = directories[currentIdx];
            const qs = currentCursor ? `?cursor=${encodeURIComponent(currentCursor)}` : '';
            const url = `${auth.BaseUrl}/v2/directory/${encodeURIComponent(dir.slug)}${qs}`;

            if (ctx.RateLimitAcquire) await ctx.RateLimitAcquire();
            const resp = await this.MakeHTTPRequest(auth, url, 'POST', headers, { pageSize });
            if (resp.Status === 429) {
                const err = Object.assign(
                    new Error(`Slayte rate limit hit (HTTP 429) on directory '${dir.slug}': ${formatSlayteError(resp)}`),
                    { status: 429, headers: resp.Headers }
                );
                ctx.RateLimitReport?.(err);
                throw err;
            }
            ctx.RateLimitReport?.();

            if (resp.Status < 200 || resp.Status >= 300) {
                throw new Error(`Slayte POST /v2/directory/${dir.slug} failed (HTTP ${resp.Status}): ${formatSlayteError(resp)}`);
            }

            const pageData = extractDirectoryPageData(resp.Body);
            const entries = Array.isArray(pageData.data) ? pageData.data : [];
            for (const entry of entries) {
                const entityUuid = typeof entry?.entityUuid === 'string' ? entry.entityUuid.trim() : '';
                if (!entityUuid) continue;
                const entityCols = isPlainObject(entry.entity) ? entry.entity : {};
                records.push({
                    ExternalID: `${dir.uuid}::${entityUuid}`,
                    ObjectType: 'DirectoryEntry',
                    Fields: {
                        ...entityCols,
                        directoryUuid: dir.uuid,
                        directorySlug: dir.slug,
                        entityUuid,
                        tags: entry.tags ?? [],
                        entity: entityCols,
                    },
                    IsDeleted: false,
                });
            }

            const nextCursor = typeof pageData.cursor === 'string' && pageData.cursor.length > 0
                ? pageData.cursor
                : undefined;

            if (nextCursor && entries.length > 0) {
                // One page per batch keeps memory bounded and hands control back to the engine
                return {
                    Records: records,
                    HasMore: true,
                    NextAfterKeyValue: encodeDirectoryResumeKey(currentIdx, nextCursor),
                };
            }

            // Finished this directory — advance to next
            currentIdx++;
            currentCursor = undefined;

            if (sampleCtx.IsDiscoverySample && sampleCtx.SampleTargetRecords && records.length >= sampleCtx.SampleTargetRecords) {
                return {
                    Records: records,
                    HasMore: currentIdx < directories.length,
                    NextAfterKeyValue: currentIdx < directories.length
                        ? encodeDirectoryResumeKey(currentIdx, undefined)
                        : undefined,
                };
            }

            if (records.length >= pageSize && currentIdx < directories.length) {
                return {
                    Records: records,
                    HasMore: true,
                    NextAfterKeyValue: encodeDirectoryResumeKey(currentIdx, undefined),
                };
            }
        }

        return { Records: records, HasMore: false };
    }

    // ── Single-Record GetRecord ─────────────────────────────────────────

    /**
     * Supports direct point-lookups via Slayte's GET-by-UUID endpoints for
     * `Individual`, `Organization`, `Committee`, and `Event`.
     */
    public override async GetRecord(ctx: GetRecordContext): Promise<ExternalRecord | null> {
        const companyIntegration = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const auth = await this.Authenticate(companyIntegration, ctx.ContextUser as UserInfo);
        const id = encodeURIComponent(ctx.ExternalID);
        let url: string | null = null;

        switch (ctx.ObjectName) {
            case 'Individual': {
                const fields = encodeURIComponent(auth.Settings.individualFields ?? DEFAULT_INDIVIDUAL_CORE_FIELDS);
                url = `${auth.BaseUrl}/v2/crm/individual/${id}?includeids=true&fields=${fields}`;
                break;
            }
            case 'Organization': {
                const fields = encodeURIComponent(auth.Settings.organizationFields ?? DEFAULT_ORGANIZATION_CORE_FIELDS);
                url = `${auth.BaseUrl}/v2/crm/organization/${id}?includeids=true&fields=${fields}`;
                break;
            }
            case 'Committee': {
                const fieldsParam = auth.Settings.committeeFields
                    ? `&fields=${encodeURIComponent(auth.Settings.committeeFields)}`
                    : '';
                url = `${auth.BaseUrl}/v2/crm/committee/${id}?includeids=true${fieldsParam}`;
                break;
            }
            case 'Event': {
                url = `${auth.BaseUrl}/v2/event/${id}`;
                break;
            }
            default:
                return await super.GetRecord(ctx);
        }

        const resp = await this.MakeHTTPRequest(auth, url, 'GET', this.BuildHeaders(auth));
        if (resp.Status === 404) return null;
        if (resp.Status < 200 || resp.Status >= 300) {
            throw new Error(`Slayte GetRecord(${ctx.ObjectName}, ${ctx.ExternalID}) failed (HTTP ${resp.Status}): ${formatSlayteError(resp)}`);
        }

        const body = isPlainObject(resp.Body) && isPlainObject(resp.Body.data)
            ? resp.Body.data
            : (isPlainObject(resp.Body) ? resp.Body : null);
        if (!body) return null;

        return {
            ExternalID: ctx.ExternalID,
            ObjectType: ctx.ObjectName,
            Fields: body,
            IsDeleted: false,
        };
    }

    // ── Credential Loading ──────────────────────────────────────────────

    /** Loads credential JSON from `MJCredentialEntity` (with `Configuration` fallback for tests). */
    protected async loadRawCredentials(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<Record<string, unknown>> {
        if (companyIntegration.CredentialID) {
            const md = new Metadata();
            const cred = await md.GetEntityObject<MJCredentialEntity>('MJ: Credentials', contextUser);
            const loaded = await cred.Load(companyIntegration.CredentialID);
            if (!loaded) {
                throw new Error(`Failed to load Slayte credential '${companyIntegration.CredentialID}'.`);
            }
            const raw = cred.Values;
            if (typeof raw === 'string' && raw.trim().length > 0) {
                return JSON.parse(raw) as Record<string, unknown>;
            }
        }

        if (companyIntegration.Configuration && companyIntegration.Configuration.trim().length > 0) {
            const cfg = JSON.parse(companyIntegration.Configuration) as Record<string, unknown>;
            if (cfg.ApiKey || cfg.apiKey) {
                return cfg;
            }
        }

        throw new Error('No Slayte credential configured on CompanyIntegration (CredentialID is empty).');
    }
}

// ─── Pure Helpers ───────────────────────────────────────────────────────

/**
 * Normalizes a workspace `SiteUrl` so all `/v2/...` routes resolve cleanly to
 * `<origin>[<path>]/api/v2/...` without ever doubling `/api` or `/v2`.
 */
export function normalizeSlayteBaseUrl(rawUrl: string): string {
    let normalized = rawUrl.trim().replace(/\/+$/, '');
    if (normalized.toLowerCase().endsWith('/api/v2')) {
        normalized = normalized.slice(0, -3);
    } else if (!normalized.toLowerCase().endsWith('/api')) {
        normalized = `${normalized}/api`;
    }
    return normalized;
}

export function parseConnectionSettings(rawConfig: string | null | undefined): SlayteConnectionSettings {
    if (!rawConfig || !rawConfig.trim()) return {};
    try {
        const parsed = JSON.parse(rawConfig) as unknown;
        const result = SlayteConnectionSettingsSchema.safeParse(parsed);
        return result.success ? result.data : {};
    } catch {
        return {};
    }
}

function validateQueryRowKey(
    objectName: string,
    queryId: string,
    row: Record<string, unknown>,
    expectedField: string,
    candidates: readonly string[]
): string | null {
    const id = extractFirstNonEmptyString(row, candidates);
    if (id) return null;
    const cols = Object.keys(row);
    return (
        `Slayte ${objectName} query '${queryId}' returned a row without a recognized primary key column ` +
        `(expected non-empty '${expectedField}' or fallback ${candidates.slice(1).map((c) => `'${c}'`).join('/')}; ` +
        `received columns: [${cols.join(', ')}]). Add the UUID column to your Slayte shared query.`
    );
}

function extractFirstNonEmptyString(
    row: Record<string, unknown>,
    keys: readonly string[]
): string | null {
    for (const k of keys) {
        const v = row[k];
        if (typeof v === 'string' && v.trim().length > 0) return v.trim();
        if (typeof v === 'number' && Number.isFinite(v)) return String(v);
    }
    return null;
}

function extractQueryData(body: unknown): SlayteQueryExecuteData {
    if (!isPlainObject(body)) return {};
    if (isPlainObject(body.data)) return body.data as SlayteQueryExecuteData;
    return body as SlayteQueryExecuteData;
}

function extractDirectoryPageData(body: unknown): SlayteDirectoryPageData {
    if (!isPlainObject(body)) return {};
    if (isPlainObject(body.data)) return body.data as SlayteDirectoryPageData;
    return body as SlayteDirectoryPageData;
}

function parseDirectoryResumeKey(raw: string | null | undefined): { dirIndex: number; cursor?: string } {
    if (!raw) return { dirIndex: 0 };
    const sep = raw.indexOf('|');
    if (sep < 0) {
        const n = Number.parseInt(raw, 10);
        return { dirIndex: Number.isFinite(n) && n >= 0 ? n : 0 };
    }
    const idx = Number.parseInt(raw.slice(0, sep), 10);
    const cur = raw.slice(sep + 1);
    return {
        dirIndex: Number.isFinite(idx) && idx >= 0 ? idx : 0,
        cursor: cur.length > 0 ? cur : undefined,
    };
}

function encodeDirectoryResumeKey(dirIndex: number, cursor: string | undefined): string {
    return `${dirIndex}|${cursor ?? ''}`;
}

function formatSlayteError(response: RESTResponse): string {
    const body = response.Body as SlayteErrorBody | string | null;
    if (isPlainObject(body)) {
        const err = isPlainObject(body.error) ? (body.error as SlayteErrorDetail) : null;
        if (err) {
            const parts: string[] = [];
            if (err.type) parts.push(err.type);
            if (err.message) parts.push(err.message);
            if (err.type === 'SCOPE_REQUIRED' && isPlainObject(err.details) && typeof err.details.requiredScope === 'string') {
                parts.push(`requiredScope=${err.details.requiredScope}`);
            }
            if (err.field) parts.push(`field=${err.field}`);
            if (parts.length > 0) return parts.join(' — ');
        }
        if (typeof body.code === 'string' || typeof body.message === 'string') {
            return [body.code, body.message].filter(Boolean).join(' — ');
        }
    }
    if (typeof body === 'string' && body.trim().length > 0) {
        return body.trim().slice(0, 300);
    }
    return `HTTP ${response.Status}`;
}

function parseRetryDelayMs(headers: Record<string, string>): number | undefined {
    const retryAfter = headers['retry-after'];
    if (retryAfter) {
        const secs = Number(retryAfter);
        if (Number.isFinite(secs) && secs >= 0) return Math.ceil(secs * 1000);
        const dateMs = Date.parse(retryAfter);
        if (Number.isFinite(dateMs)) return Math.max(0, dateMs - Date.now());
    }
    const reset = headers['x-ratelimit-reset'];
    if (reset) {
        const epochSec = Number(reset);
        if (Number.isFinite(epochSec) && epochSec > 0) {
            return Math.max(0, epochSec * 1000 - Date.now());
        }
    }
    return undefined;
}

function computeMaxIsoTimestamp(records: ExternalRecord[], fieldName: string): string | undefined {
    let maxMs = -Infinity;
    let maxVal: string | undefined;
    for (const r of records) {
        const raw = r.Fields[fieldName];
        if (typeof raw !== 'string' || !raw) continue;
        const ms = Date.parse(raw);
        if (Number.isFinite(ms) && ms > maxMs) {
            maxMs = ms;
            maxVal = raw;
        }
    }
    return maxVal;
}

function readDotPath(obj: Record<string, unknown>, path: string): unknown {
    let cur: unknown = obj;
    for (const part of path.split('.')) {
        if (!isPlainObject(cur)) return undefined;
        cur = cur[part];
    }
    return cur;
}

function isPlainObject(value: unknown): value is Record<string, unknown> {
    return typeof value === 'object' && value !== null && !Array.isArray(value);
}

/** Local bounded-concurrency helper for `IntrospectSchema` sample-union. */
async function runBounded<T>(items: T[], limit: number, worker: (item: T) => Promise<void>): Promise<void> {
    const queue = [...items];
    const lanes = Array.from({ length: Math.max(1, Math.min(limit, queue.length)) }, async () => {
        for (;;) {
            const next = queue.shift();
            if (next === undefined) return;
            await worker(next);
        }
    });
    await Promise.all(lanes);
}
