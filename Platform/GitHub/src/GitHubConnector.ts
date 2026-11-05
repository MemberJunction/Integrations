import { createSign } from 'node:crypto';
import { RegisterClass } from '@memberjunction/global';
import { Metadata, type UserInfo } from '@memberjunction/core';
import type {
    MJCompanyIntegrationEntity,
    MJCredentialEntity,
    MJIntegrationObjectEntity,
    MJIntegrationObjectFieldEntity,
} from '@memberjunction/core-entities';
import {
    BaseIntegrationConnector,
    BaseRESTIntegrationConnector,
    DiscoverFieldsViaFetch,
    mergeDeclaredWithSampledFields,
    type RESTAuthContext,
    type RESTResponse,
    type PaginationState,
    type PaginationType,
    type ConnectionTestResult,
    type SourceSchemaInfo,
    type IntrospectSchemaOptions,
    type FetchContext,
    type FetchBatchResult,
    type CreateRecordContext,
    type UpdateRecordContext,
    type GetRecordContext,
    type CRUDResult,
    type ConnectorActionCapabilities,
} from '@memberjunction/integration-engine';

/** Default GitHub REST API base URL. Can be overridden per connection for GitHub Enterprise Server. */
export const DEFAULT_GITHUB_API_BASE_URL = 'https://api.github.com';

/** Pinned GitHub REST API version header (2022-11-28). */
export const GITHUB_API_VERSION = '2022-11-28';

/** Maximum page size supported by GitHub REST API v3 list endpoints. */
export const GITHUB_MAX_PAGE_SIZE = 100;

/**
 * Authentication and scope context resolved for a GitHub integration connection.
 */
export interface GitHubAuthContext extends RESTAuthContext {
    /** Bearer token (PAT, 3LO OAuth token, or minted GitHub App installation token). */
    Token: string;
    /** Base URL for GitHub API requests (defaults to `https://api.github.com`). */
    BaseURL: string;
    /** Optional organization or user login scoping repository discovery. */
    Owner?: string;
    /** Optional explicit list of `owner/repo` full names configured on the connection. */
    Repositories?: string[];
    /** Authentication mode used to acquire the token. */
    AuthMode: 'pat' | 'oauth' | 'github-app';
}

/**
 * GitHub REST API v3 (2022-11-28) connector for MemberJunction Integration Engine.
 *
 * Syncs `repositories`, `issues`, `issue_comments`, `pull_requests`,
 * `pull_request_comments`, `releases`, `commits`, and `workflow_runs` into
 * MemberJunction and supports creating/updating `issues`, `issue_comments`,
 * and `pull_requests`.
 *
 * ### Supported Authentication Modes
 * 1. **Personal Access Token (PAT) / OAuth Bearer Token**:
 *    Provide `token`, `apiToken`, `personalAccessToken`, or `accessToken` in the linked
 *    `MJ: Credential` Values JSON or `CompanyIntegration.Configuration`.
 * 2. **GitHub App Installation Token**:
 *    Provide `appId`, `installationId`, and `privateKey` (PEM). The connector signs a short-lived
 *    RS256 JWT and exchanges it via `POST /app/installations/{installationId}/access_tokens`.
 *
 * ### Pagination & Incremental Watermark Sync
 * - Uses GitHub's `page` and `per_page` (up to 100) parameters plus RFC 5988 `Link: <...>; rel="next"` headers.
 * - Incremental sync uses GitHub's `since` ISO-8601 timestamp parameter (`?since=<WatermarkValue>&sort=updated&direction=asc`)
 *   and advances the watermark to the highest `updated_at` timestamp observed in the batch.
 */
@RegisterClass(BaseIntegrationConnector, '@memberjunction/connector-github')
@RegisterClass(BaseIntegrationConnector, 'GitHubConnector')
export class GitHubConnector extends BaseRESTIntegrationConnector {
    /** Verbatim three-way invariant name matching `fields.Name` in `.github.integration.json`. */
    public override get IntegrationName(): string {
        return 'GitHub';
    }

    /**
     * GitHub's `since` parameter filters by `updated_at >= since` in ascending order when paired with
     * `sort=updated&direction=asc`, making the watermark monotonic across incremental runs.
     */
    public override get MonotonicWatermark(): boolean {
        return true;
    }

    /** Watermark from the active `FetchChanges` call, consumed by `AppendDefaultQueryParams`. */
    protected currentWatermark: string | null = null;

    /** Last HTTP response headers observed, used by `ExtractPaginationInfo` to inspect RFC 5988 `Link` headers. */
    protected lastResponseHeaders: Record<string, string> = {};

    /** Active auth context cached during `FetchChanges` so repository path helpers can read connection scope. */
    protected currentAuth: GitHubAuthContext | null = null;

    // ─── Schema Introspection ──────────────────────────────────────────────

    /**
     * Introspects the GitHub schema by sampling live endpoints and merging with declared metadata
     * so empty repositories or endpoints still expose their full declared column catalog.
     */
    public override async IntrospectSchema(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
        options?: IntrospectSchemaOptions
    ): Promise<SourceSchemaInfo> {
        let sampled: SourceSchemaInfo = { Objects: [] };
        try {
            sampled = await DiscoverFieldsViaFetch(this, companyIntegration, contextUser, options);
        } catch {
            // Fall back to declared metadata when credentials are not yet reachable during offline introspection
        }
        return mergeDeclaredWithSampledFields(companyIntegration.IntegrationID, sampled, options);
    }

    // ─── Action Generator Capabilities ─────────────────────────────────────

    public override GetActionGeneratorCapabilities(): ConnectorActionCapabilities {
        return {
            SupportsSearch: true,
            SupportsList: true,
            SupportsGet: true,
            SupportsCreate: true,
            SupportsUpdate: true,
            SupportsDelete: false,
        };
    }

    // ─── Connection Test ───────────────────────────────────────────────────

    /**
     * Verifies connectivity and credentials against `GET /user` (for PAT/OAuth tokens)
     * or `GET /orgs/{owner}` / `GET /installation/repositories` (for GitHub App installation tokens).
     */
    public async TestConnection(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<ConnectionTestResult> {
        try {
            const auth = await this.Authenticate(companyIntegration, contextUser);
            const headers = this.BuildHeaders(auth);
            const baseUrl = this.GetBaseURL(companyIntegration, auth).replace(/\/+$/, '');

            const probeUrl = auth.AuthMode === 'github-app'
                ? `${baseUrl}/installation/repositories?per_page=1`
                : `${baseUrl}/user`;

            const response = await this.MakeHTTPRequest(auth, probeUrl, 'GET', headers);
            if (response.Status >= 200 && response.Status < 300) {
                const body = isRecord(response.Body) ? response.Body : {};
                const identity = typeof body['login'] === 'string'
                    ? body['login']
                    : auth.Owner ?? 'GitHub Installation';
                return {
                    Success: true,
                    Message: `Connected to GitHub as ${identity}`,
                    ServerVersion: response.Headers['x-github-api-version'] ?? GITHUB_API_VERSION,
                };
            }
            return {
                Success: false,
                Message: `GitHub API returned HTTP ${response.Status}: ${extractGitHubErrorMessage(response.Body)}`,
            };
        } catch (err: unknown) {
            const message = err instanceof Error ? err.message : String(err);
            return {
                Success: false,
                Message: `GitHub connection failed: ${message}`,
            };
        }
    }

    // ─── Authentication & Transport ────────────────────────────────────────

    protected async Authenticate(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<GitHubAuthContext> {
        const config = await this.LoadConfiguration(companyIntegration, contextUser);

        const rawBaseUrl = pickString(config, ['baseUrl', 'BaseURL', 'apiUrl', 'apiBaseUrl'])
            ?? companyIntegration.NavigationBaseURL
            ?? DEFAULT_GITHUB_API_BASE_URL;
        const baseUrl = normalizeApiBaseUrl(rawBaseUrl);

        const owner = pickString(config, ['owner', 'Owner', 'organization', 'Organization', 'org'])
            ?? (companyIntegration.ExternalSystemID?.trim() || undefined);

        const repositories = parseRepositoryList(config['repositories'] ?? config['Repositories'] ?? config['repo']);

        const directToken = pickString(config, [
            'token',
            'Token',
            'apiToken',
            'personalAccessToken',
            'accessToken',
            'AccessToken',
            'githubToken',
        ]);

        if (directToken) {
            const authMode = pickString(config, ['authMode']) === 'oauth' ? 'oauth' : 'pat';
            const ctx: GitHubAuthContext = {
                Token: directToken,
                BaseURL: baseUrl,
                Owner: owner,
                Repositories: repositories,
                AuthMode: authMode,
            };
            this.currentAuth = ctx;
            return ctx;
        }

        const appId = pickString(config, ['appId', 'AppId', 'githubAppId']);
        const installationId = pickString(config, ['installationId', 'InstallationId', 'githubInstallationId']);
        const privateKey = pickString(config, ['privateKey', 'PrivateKey', 'githubPrivateKey']);

        if (appId && installationId && privateKey) {
            const installationToken = await this.ExchangeGitHubAppInstallationToken(
                baseUrl,
                appId,
                installationId,
                privateKey
            );
            const ctx: GitHubAuthContext = {
                Token: installationToken.token,
                ExpiresAt: installationToken.expiresAt,
                BaseURL: baseUrl,
                Owner: owner,
                Repositories: repositories,
                AuthMode: 'github-app',
            };
            this.currentAuth = ctx;
            return ctx;
        }

        throw new Error(
            'GitHub credentials require either a Bearer token (token / personalAccessToken / accessToken) ' +
            'or GitHub App credentials (appId, installationId, privateKey) in the linked MJ Credential or Configuration.'
        );
    }

    /**
     * Mints a short-lived RS256 GitHub App JWT and exchanges it for an installation access token.
     */
    protected async ExchangeGitHubAppInstallationToken(
        baseUrl: string,
        appId: string,
        installationId: string,
        privateKeyPem: string
    ): Promise<{ token: string; expiresAt?: Date }> {
        const jwt = createGitHubAppJwt(appId, privateKeyPem);
        const url = `${baseUrl.replace(/\/+$/, '')}/app/installations/${encodeURIComponent(installationId)}/access_tokens`;
        const headers: Record<string, string> = {
            'Authorization': `Bearer ${jwt}`,
            'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': GITHUB_API_VERSION,
            'User-Agent': 'MemberJunction-GitHubConnector/1.0',
        };
        const response = await this.MakeHTTPRequest({ Token: jwt }, url, 'POST', headers);
        if (response.Status < 200 || response.Status >= 300 || !isRecord(response.Body)) {
            throw new Error(
                `Failed to exchange GitHub App installation token (HTTP ${response.Status}): ${extractGitHubErrorMessage(response.Body)}`
            );
        }
        const token = typeof response.Body['token'] === 'string' ? response.Body['token'] : '';
        if (!token) {
            throw new Error('GitHub App installation token response did not include a token.');
        }
        const expiresAt = typeof response.Body['expires_at'] === 'string'
            ? new Date(response.Body['expires_at'])
            : undefined;
        return { token, expiresAt };
    }

    protected BuildHeaders(auth: RESTAuthContext): Record<string, string> {
        return {
            'Authorization': `Bearer ${auth.Token ?? ''}`,
            'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': GITHUB_API_VERSION,
            'User-Agent': 'MemberJunction-GitHubConnector/1.0',
        };
    }

    protected GetBaseURL(
        companyIntegration: MJCompanyIntegrationEntity,
        auth: RESTAuthContext
    ): string {
        const ghAuth = auth as Partial<GitHubAuthContext>;
        if (ghAuth.BaseURL) return ghAuth.BaseURL;
        if (companyIntegration.NavigationBaseURL) {
            return normalizeApiBaseUrl(companyIntegration.NavigationBaseURL);
        }
        return DEFAULT_GITHUB_API_BASE_URL;
    }

    protected async MakeHTTPRequest(
        _auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown
    ): Promise<RESTResponse> {
        // GitHub repository endpoints use `/repos/{full_name}/...` where `{full_name}` is `owner/repo`.
        // If URL-encoding turned `owner/repo` into `owner%2Frepo` inside `/repos/...`, restore the slash.
        const normalizedUrl = restoreRepoFullNameSlash(url);

        const reqHeaders: Record<string, string> = { ...headers };
        const init: RequestInit = { method, headers: reqHeaders };
        if (body !== undefined && method !== 'GET' && method !== 'HEAD') {
            init.body = typeof body === 'string' ? body : JSON.stringify(body);
            reqHeaders['Content-Type'] = 'application/json';
        }

        const response = await fetch(normalizedUrl, init);
        const responseHeaders: Record<string, string> = {};
        response.headers.forEach((value, key) => {
            responseHeaders[key.toLowerCase()] = value;
        });
        this.lastResponseHeaders = responseHeaders;

        const text = await response.text();
        let parsed: unknown = text;
        const contentType = responseHeaders['content-type'] ?? '';
        if (contentType.includes('json') || (text.length > 0 && (text[0] === '{' || text[0] === '['))) {
            try {
                parsed = JSON.parse(text);
            } catch {
                parsed = text;
            }
        }

        return {
            Status: response.status,
            Body: parsed,
            Headers: responseHeaders,
        };
    }

    // ─── Response Normalization & Record Transformation ────────────────────

    protected NormalizeResponse(
        rawBody: unknown,
        responseDataKey: string | null
    ): Record<string, unknown>[] {
        if (Array.isArray(rawBody)) {
            return rawBody.filter(isRecord);
        }
        if (isRecord(rawBody)) {
            if (responseDataKey && responseDataKey in rawBody) {
                const nested = rawBody[responseDataKey];
                if (Array.isArray(nested)) return nested.filter(isRecord);
                if (isRecord(nested)) return [nested];
            }
            // GitHub App `/installation/repositories` wraps repositories in `{ repositories: [...] }`
            if (Array.isArray(rawBody['repositories'])) {
                return (rawBody['repositories'] as unknown[]).filter(isRecord);
            }
            // GitHub Actions `/repos/{full_name}/actions/runs` wraps runs in `{ workflow_runs: [...] }`
            if (Array.isArray(rawBody['workflow_runs'])) {
                return (rawBody['workflow_runs'] as unknown[]).filter(isRecord);
            }
            return [rawBody];
        }
        return [];
    }

    /**
     * Flattens common nested GitHub objects (author/user logins, commit fields, head/base refs,
     * repository full_name) into scalar columns declared in `.github.integration.json` while
     * preserving all raw keys via `applyTransformPreservingKeys`.
     */
    protected override TransformRecord(
        raw: Record<string, unknown>,
        obj: MJIntegrationObjectEntity,
        _fields: MJIntegrationObjectFieldEntity[]
    ): Record<string, unknown> {
        const out: Record<string, unknown> = { ...raw };

        // Flatten nested user/author/sender/merged_by login & id
        const userObj = isRecord(raw['user']) ? raw['user'] : isRecord(raw['author']) ? raw['author'] : null;
        if (userObj) {
            if (out['author_login'] === undefined && typeof userObj['login'] === 'string') {
                out['author_login'] = userObj['login'];
            }
            if (out['user_login'] === undefined && typeof userObj['login'] === 'string') {
                out['user_login'] = userObj['login'];
            }
            if (out['user_id'] === undefined && userObj['id'] !== undefined) {
                out['user_id'] = userObj['id'];
            }
        }

        const ownerObj = isRecord(raw['owner']) ? raw['owner'] : null;
        if (ownerObj && out['owner_login'] === undefined && typeof ownerObj['login'] === 'string') {
            out['owner_login'] = ownerObj['login'];
        }

        const assigneeObj = isRecord(raw['assignee']) ? raw['assignee'] : null;
        if (assigneeObj && out['assignee_login'] === undefined && typeof assigneeObj['login'] === 'string') {
            out['assignee_login'] = assigneeObj['login'];
        }

        // Flatten repository_full_name from html_url or repository_url when not already stamped
        if (out['repository_full_name'] === undefined) {
            const repoObj = isRecord(raw['repository']) ? raw['repository'] : null;
            if (repoObj && typeof repoObj['full_name'] === 'string') {
                out['repository_full_name'] = repoObj['full_name'];
            } else if (typeof raw['repository_url'] === 'string') {
                const match = /\/repos\/([^/]+\/[^/]+)$/.exec(raw['repository_url']);
                if (match) out['repository_full_name'] = match[1];
            } else if (typeof raw['html_url'] === 'string') {
                const match = /github\.com\/([^/]+\/[^/]+)\//.exec(raw['html_url']);
                if (match) out['repository_full_name'] = match[1];
            }
        }

        // Object-specific projections
        if (obj.Name === 'pull_requests') {
            const head = isRecord(raw['head']) ? raw['head'] : null;
            const base = isRecord(raw['base']) ? raw['base'] : null;
            if (head) {
                if (typeof head['ref'] === 'string') out['head_ref'] = head['ref'];
                if (typeof head['sha'] === 'string') out['head_sha'] = head['sha'];
            }
            if (base) {
                if (typeof base['ref'] === 'string') out['base_ref'] = base['ref'];
                if (typeof base['sha'] === 'string') out['base_sha'] = base['sha'];
            }
            const mergedBy = isRecord(raw['merged_by']) ? raw['merged_by'] : null;
            if (mergedBy && typeof mergedBy['login'] === 'string') {
                out['merged_by_login'] = mergedBy['login'];
            }
        } else if (obj.Name === 'commits') {
            // Commits use `sha` as primary identifier; alias `id` = `sha` for uniform PK handling
            if (out['id'] === undefined && typeof raw['sha'] === 'string') {
                out['id'] = raw['sha'];
            }
            const commitInner = isRecord(raw['commit']) ? raw['commit'] : null;
            if (commitInner) {
                if (typeof commitInner['message'] === 'string') {
                    out['message'] = commitInner['message'];
                }
                const gitAuthor = isRecord(commitInner['author']) ? commitInner['author'] : null;
                if (gitAuthor) {
                    if (typeof gitAuthor['name'] === 'string') out['author_name'] = gitAuthor['name'];
                    if (typeof gitAuthor['email'] === 'string') out['author_email'] = gitAuthor['email'];
                    if (typeof gitAuthor['date'] === 'string') out['committed_at'] = gitAuthor['date'];
                }
            }
        } else if (obj.Name === 'issues') {
            // Flag whether an issue row returned by `/repos/{full_name}/issues` is actually a pull request
            out['is_pull_request'] = isRecord(raw['pull_request']);
        }

        // Serialize label arrays to JSON string if present
        if (Array.isArray(raw['labels']) && out['labels_json'] === undefined) {
            out['labels_json'] = JSON.stringify(raw['labels']);
        }

        return out;
    }

    // ─── Pagination & Incremental Sync ─────────────────────────────────────

    protected ExtractPaginationInfo(
        rawBody: unknown,
        paginationType: PaginationType,
        currentPage: number,
        _currentOffset: number,
        pageSize: number
    ): PaginationState {
        if (paginationType === 'None') {
            return { HasMore: false };
        }

        const effectivePageSize = Math.min(GITHUB_MAX_PAGE_SIZE, Math.max(1, pageSize || GITHUB_MAX_PAGE_SIZE));

        // 1. Prefer RFC 5988 `Link: <...>; rel="next"` header when present
        const linkHeader = this.lastResponseHeaders['link'] ?? '';
        if (linkHeader) {
            const nextUrl = parseNextLinkHeader(linkHeader);
            if (nextUrl) {
                const nextPageParam = extractPageNumberFromUrl(nextUrl);
                return {
                    HasMore: true,
                    NextPage: nextPageParam ?? currentPage + 1,
                    NextCursor: nextUrl,
                };
            }
            // If a Link header is present and has no `rel="next"`, we are on the final page
            return { HasMore: false };
        }

        // 2. Fallback when Link header is absent: check if a full page of items was returned
        const records = this.NormalizeResponse(rawBody, null);
        const totalCount = isRecord(rawBody) && typeof rawBody['total_count'] === 'number'
            ? rawBody['total_count']
            : undefined;

        if (totalCount !== undefined) {
            const fetchedSoFar = currentPage * effectivePageSize;
            if (fetchedSoFar < totalCount && records.length > 0) {
                return {
                    HasMore: true,
                    NextPage: currentPage + 1,
                    TotalRecords: totalCount,
                };
            }
            return { HasMore: false, TotalRecords: totalCount };
        }

        if (records.length >= effectivePageSize) {
            return {
                HasMore: true,
                NextPage: currentPage + 1,
            };
        }

        return { HasMore: false };
    }

    protected override BuildPaginatedURL(
        basePath: string,
        obj: MJIntegrationObjectEntity,
        page: number,
        offset: number,
        cursor?: string,
        effectivePageSize?: number
    ): string {
        if (!obj.SupportsPagination || obj.PaginationType === 'None') {
            return basePath;
        }
        const perPage = Math.min(
            GITHUB_MAX_PAGE_SIZE,
            Math.max(1, effectivePageSize ?? obj.DefaultPageSize ?? GITHUB_MAX_PAGE_SIZE)
        );
        if (obj.PaginationType === 'PageNumber' || obj.PaginationType === 'Cursor') {
            const sep = basePath.includes('?') ? '&' : '?';
            return `${basePath}${sep}page=${page}&per_page=${perPage}`;
        }
        return super.BuildPaginatedURL(basePath, obj, page, offset, cursor, effectivePageSize);
    }

    protected override AppendDefaultQueryParams(
        url: string,
        obj: MJIntegrationObjectEntity
    ): string {
        let resolvedUrl = url;
        // When `repositories` is fetched with an Owner configured on the connection, scope to `/orgs/{owner}/repos`
        if (obj.Name === 'repositories' && this.currentAuth?.Owner && resolvedUrl === '/user/repos') {
            resolvedUrl = `/orgs/${encodeURIComponent(this.currentAuth.Owner)}/repos`;
        } else if (obj.Name === 'repositories' && this.currentAuth?.AuthMode === 'github-app' && resolvedUrl === '/user/repos') {
            resolvedUrl = '/installation/repositories';
        }

        let out = super.AppendDefaultQueryParams(resolvedUrl, obj);
        if (obj.SupportsIncrementalSync && this.currentWatermark) {
            out = appendQueryParam(out, 'since', this.currentWatermark);
        }
        return out;
    }

    public override async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
        this.currentWatermark = ctx.WatermarkValue ?? null;
        try {
            const result = await super.FetchChanges(ctx);
            if (!ctx.Object.SupportsIncrementalSync) {
                return result;
            }
            const watermarkField = ctx.Object.IncrementalWatermarkField || 'updated_at';
            let maxWatermark = ctx.WatermarkValue ?? null;
            for (const rec of result.Records) {
                const candidate = rec.Fields[watermarkField];
                if (typeof candidate === 'string' && candidate.length > 0) {
                    if (!maxWatermark || candidate > maxWatermark) {
                        maxWatermark = candidate;
                    }
                }
            }
            return maxWatermark ? { ...result, NewWatermarkValue: maxWatermark } : result;
        } finally {
            this.currentWatermark = null;
        }
    }

    // ─── Write / CRUD Operations (Issues, Issue Comments, Pull Requests) ───

    public override async CreateRecord(ctx: CreateRecordContext): Promise<CRUDResult> {
        try {
            const auth = await this.Authenticate(ctx.CompanyIntegration, ctx.ContextUser);
            const headers = this.BuildHeaders(auth);
            const baseUrl = this.GetBaseURL(ctx.CompanyIntegration, auth).replace(/\/+$/, '');
            const apiPath = this.ResolveWriteCollectionPath(ctx.ObjectName, ctx.Attributes, auth);
            const payload = this.FilterWritePayload(ctx.Attributes);

            const response = await this.MakeHTTPRequest(auth, `${baseUrl}${apiPath}`, 'POST', headers, payload);
            if (response.Status >= 200 && response.Status < 300 && isRecord(response.Body)) {
                const externalId = String(response.Body['number'] ?? response.Body['id'] ?? '');
                return {
                    Success: true,
                    ExternalID: externalId,
                    StatusCode: response.Status,
                };
            }
            return {
                Success: false,
                StatusCode: response.Status,
                ErrorMessage: `GitHub CreateRecord failed (HTTP ${response.Status}): ${extractGitHubErrorMessage(response.Body)}`,
            };
        } catch (err: unknown) {
            return {
                Success: false,
                StatusCode: 500,
                ErrorMessage: err instanceof Error ? err.message : String(err),
            };
        }
    }

    public override async UpdateRecord(ctx: UpdateRecordContext): Promise<CRUDResult> {
        try {
            const auth = await this.Authenticate(ctx.CompanyIntegration, ctx.ContextUser);
            const headers = this.BuildHeaders(auth);
            const baseUrl = this.GetBaseURL(ctx.CompanyIntegration, auth).replace(/\/+$/, '');
            const itemPath = this.ResolveWriteItemPath(ctx.ObjectName, ctx.ExternalID, ctx.Attributes, auth);
            const payload = this.FilterWritePayload(ctx.Attributes);

            const response = await this.MakeHTTPRequest(auth, `${baseUrl}${itemPath}`, 'PATCH', headers, payload);
            if (response.Status >= 200 && response.Status < 300 && isRecord(response.Body)) {
                const externalId = String(response.Body['number'] ?? response.Body['id'] ?? ctx.ExternalID);
                return {
                    Success: true,
                    ExternalID: externalId,
                    StatusCode: response.Status,
                };
            }
            return {
                Success: false,
                StatusCode: response.Status,
                ErrorMessage: `GitHub UpdateRecord failed (HTTP ${response.Status}): ${extractGitHubErrorMessage(response.Body)}`,
            };
        } catch (err: unknown) {
            return {
                Success: false,
                StatusCode: 500,
                ErrorMessage: err instanceof Error ? err.message : String(err),
            };
        }
    }

    public override async GetRecord(ctx: GetRecordContext): Promise< ExternalRecord | null> {
        const auth = await this.Authenticate(ctx.CompanyIntegration, ctx.ContextUser);
        const headers = this.BuildHeaders(auth);
        const baseUrl = this.GetBaseURL(ctx.CompanyIntegration, auth).replace(/\/+$/, '');
        const itemPath = this.ResolveSingleRecordPath(ctx.ObjectName, ctx.ExternalID, auth);

        const response = await this.MakeHTTPRequest(auth, `${baseUrl}${itemPath}`, 'GET', headers);
        if (response.Status === 404) {
            return null;
        }
        if (response.Status >= 200 && response.Status < 300 && isRecord(response.Body)) {
            return {
                ExternalID: String(response.Body['id'] ?? response.Body['sha'] ?? ctx.ExternalID),
                ObjectType: ctx.ObjectName,
                Fields: response.Body,
            };
        }
        throw new Error(
            `GitHub GetRecord failed for ${ctx.ObjectName}/${ctx.ExternalID} (HTTP ${response.Status}): ${extractGitHubErrorMessage(response.Body)}`
        );
    }

    // ─── Internal Helpers ──────────────────────────────────────────────────

    protected ResolveRepositoryFullName(
        attributes: Record<string, unknown>,
        auth: GitHubAuthContext
    ): string {
        const fromAttrs = pickString(attributes, ['full_name', 'repository_full_name', 'repo', 'repository']);
        if (fromAttrs && fromAttrs.includes('/')) {
            return fromAttrs;
        }
        const owner = pickString(attributes, ['owner', 'owner_login']) ?? auth.Owner;
        if (owner && fromAttrs) {
            return `${owner}/${fromAttrs}`;
        }
        if (auth.Repositories && auth.Repositories.length > 0) {
            return auth.Repositories[0];
        }
        throw new Error(
            'Repository full_name ("owner/repo") is required in record attributes or CompanyIntegration.Configuration.repositories.'
        );
    }

    protected ResolveWriteCollectionPath(
        objectName: string,
        attributes: Record<string, unknown>,
        auth: GitHubAuthContext
    ): string {
        const fullName = this.ResolveRepositoryFullName(attributes, auth);
        switch (objectName) {
            case 'issues':
                return `/repos/${fullName}/issues`;
            case 'pull_requests':
                return `/repos/${fullName}/pulls`;
            case 'issue_comments': {
                const issueNumber = attributes['issue_number'] ?? attributes['number'];
                if (!issueNumber) {
                    throw new Error('issue_comments CreateRecord requires an issue_number attribute.');
                }
                return `/repos/${fullName}/issues/${encodeURIComponent(String(issueNumber))}/comments`;
            }
            default:
                throw new Error(`Write operations are not supported for GitHub object "${objectName}".`);
        }
    }

    protected ResolveWriteItemPath(
        objectName: string,
        externalId: string,
        attributes: Record<string, unknown>,
        auth: GitHubAuthContext
    ): string {
        const fullName = this.ResolveRepositoryFullName(attributes, auth);
        switch (objectName) {
            case 'issues':
                return `/repos/${fullName}/issues/${encodeURIComponent(externalId)}`;
            case 'pull_requests':
                return `/repos/${fullName}/pulls/${encodeURIComponent(externalId)}`;
            case 'issue_comments':
                return `/repos/${fullName}/issues/comments/${encodeURIComponent(externalId)}`;
            default:
                throw new Error(`Update operations are not supported for GitHub object "${objectName}".`);
        }
    }

    protected ResolveSingleRecordPath(
        objectName: string,
        externalId: string,
        auth: GitHubAuthContext
    ): string {
        if (objectName === 'repositories' && externalId.includes('/')) {
            return `/repos/${externalId}`;
        }
        const fullName = auth.Repositories?.[0];
        if (!fullName) {
            throw new Error(
                `Single-record lookup for "${objectName}" requires a repository in CompanyIntegration.Configuration.repositories.`
            );
        }
        switch (objectName) {
            case 'repositories':
                return `/repos/${fullName}`;
            case 'issues':
                return `/repos/${fullName}/issues/${encodeURIComponent(externalId)}`;
            case 'issue_comments':
                return `/repos/${fullName}/issues/comments/${encodeURIComponent(externalId)}`;
            case 'pull_requests':
                return `/repos/${fullName}/pulls/${encodeURIComponent(externalId)}`;
            case 'pull_request_comments':
                return `/repos/${fullName}/pulls/comments/${encodeURIComponent(externalId)}`;
            case 'releases':
                return `/repos/${fullName}/releases/${encodeURIComponent(externalId)}`;
            case 'commits':
                return `/repos/${fullName}/commits/${encodeURIComponent(externalId)}`;
            case 'workflow_runs':
                return `/repos/${fullName}/actions/runs/${encodeURIComponent(externalId)}`;
            default:
                return `/repos/${fullName}/${objectName}/${encodeURIComponent(externalId)}`;
        }
    }

    protected FilterWritePayload(attributes: Record<string, unknown>): Record<string, unknown> {
        const routingKeys = new Set([
            'full_name',
            'repository_full_name',
            'repo',
            'repository',
            'owner',
            'owner_login',
            'issue_number',
        ]);
        const payload: Record<string, unknown> = {};
        for (const [key, value] of Object.entries(attributes)) {
            if (!routingKeys.has(key) && value !== undefined) {
                payload[key] = value;
            }
        }
        return payload;
    }

    /**
     * Loads and merges configuration from `CompanyIntegration.Configuration` and the linked `MJ: Credential` entity.
     */
    protected async LoadConfiguration(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<Record<string, unknown>> {
        const merged: Record<string, unknown> = {};

        if (companyIntegration.Configuration) {
            try {
                const parsed = JSON.parse(companyIntegration.Configuration);
                if (isRecord(parsed)) Object.assign(merged, parsed);
            } catch {
                // Ignore invalid JSON in Configuration
            }
        }

        const credentialId = companyIntegration.Get?.('CredentialID') as string | null | undefined;
        if (credentialId) {
            const md = new Metadata();
            const credential = await md.GetEntityObject<MJCredentialEntity>('MJ: Credentials', contextUser);
            const loaded = await credential.Load(credentialId);
            if (loaded && credential.Values) {
                try {
                    const parsedCreds = JSON.parse(credential.Values);
                    if (isRecord(parsedCreds)) Object.assign(merged, parsedCreds);
                } catch {
                    // Ignore invalid JSON in Credential.Values
                }
            }
        }

        if (companyIntegration.AccessToken && !merged['accessToken']) {
            merged['accessToken'] = companyIntegration.AccessToken;
        }
        if (companyIntegration.APIKey && !merged['token']) {
            merged['token'] = companyIntegration.APIKey;
        }

        return merged;
    }
}

// ─── Pure Helper Functions ─────────────────────────────────────────────

type ExternalRecord = import('@memberjunction/integration-engine').ExternalRecord;

function isRecord(value: unknown): value is Record<string, unknown> {
    return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function pickString(source: Record<string, unknown>, keys: string[]): string | undefined {
    for (const key of keys) {
        const val = source[key];
        if (typeof val === 'string' && val.trim().length > 0) {
            return val.trim();
        }
    }
    return undefined;
}

function parseRepositoryList(raw: unknown): string[] | undefined {
    if (Array.isArray(raw)) {
        const list = raw
            .map(item => (typeof item === 'string' ? item.trim() : ''))
            .filter(Boolean);
        return list.length > 0 ? list : undefined;
    }
    if (typeof raw === 'string' && raw.trim().length > 0) {
        const list = raw
            .split(',')
            .map(s => s.trim())
            .filter(Boolean);
        return list.length > 0 ? list : undefined;
    }
    return undefined;
}

function normalizeApiBaseUrl(url: string): string {
    const trimmed = url.trim().replace(/\/+$/, '');
    if (trimmed === 'https://github.com' || trimmed === 'http://github.com') {
        return DEFAULT_GITHUB_API_BASE_URL;
    }
    return trimmed;
}

function restoreRepoFullNameSlash(url: string): string {
    return url.replace(/\/repos\/([^/?#]+)%2F([^/?#]+)/gi, '/repos/$1/$2');
}

function appendQueryParam(url: string, name: string, value: string): string {
    const sep = url.includes('?') ? '&' : '?';
    return `${url}${sep}${encodeURIComponent(name)}=${encodeURIComponent(value)}`;
}

/**
 * Extracts the URL for `rel="next"` from an RFC 5988 `Link` header.
 */
export function parseNextLinkHeader(linkHeader: string): string | null {
    const parts = linkHeader.split(',');
    for (const part of parts) {
        const match = /<([^>]+)>\s*;\s*rel="next"/i.exec(part);
        if (match?.[1]) {
            return match[1];
        }
    }
    return null;
}

function extractPageNumberFromUrl(url: string): number | undefined {
    const match = /[?&]page=(\d+)/.exec(url);
    if (match?.[1]) {
        const num = Number.parseInt(match[1], 10);
        return Number.isFinite(num) ? num : undefined;
    }
    return undefined;
}

function extractGitHubErrorMessage(body: unknown): string {
    if (isRecord(body) && typeof body['message'] === 'string') {
        return body['message'];
    }
    if (typeof body === 'string' && body.length > 0) {
        return body.slice(0, 300);
    }
    return 'Unknown GitHub API error';
}

function base64UrlEncode(input: Buffer | string): string {
    const buf = typeof input === 'string' ? Buffer.from(input, 'utf8') : input;
    return buf
        .toString('base64')
        .replace(/=/g, '')
        .replace(/\+/g, '-')
        .replace(/\//g, '_');
}

/**
 * Creates a short-lived RS256 JWT for GitHub App authentication (`iat = now - 60s`, `exp = now + 9m`).
 */
export function createGitHubAppJwt(appId: string, privateKeyPem: string): string {
    const nowSeconds = Math.floor(Date.now() / 1000);
    const header = base64UrlEncode(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
    const payload = base64UrlEncode(
        JSON.stringify({
            iat: nowSeconds - 60,
            exp: nowSeconds + 9 * 60,
            iss: appId,
        })
    );
    const signingInput = `${header}.${payload}`;
    const normalizedPem = privateKeyPem.replace(/\\n/g, '\n');
    const signer = createSign('RSA-SHA256');
    signer.update(signingInput);
    signer.end();
    const signature = base64UrlEncode(signer.sign(normalizedPem));
    return `${signingInput}.${signature}`;
}
