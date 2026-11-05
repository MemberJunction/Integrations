import { describe, it, expect, vi, beforeEach } from 'vitest';
import { generateKeyPairSync } from 'node:crypto';
import type { UserInfo } from '@memberjunction/core';
import type {
    MJCompanyIntegrationEntity,
    MJIntegrationObjectEntity,
} from '@memberjunction/core-entities';
import {
    GitHubConnector,
    parseNextLinkHeader,
    createGitHubAppJwt,
    DEFAULT_GITHUB_API_BASE_URL,
    GITHUB_API_VERSION,
    type GitHubAuthContext,
} from '../GitHubConnector.js';
import type { PaginationType, RESTResponse } from '@memberjunction/integration-engine';

// ─── Test Harness Subclass ───────────────────────────────────────────────────

class TestableGitHubConnector extends GitHubConnector {
    public mockResponses: RESTResponse[] = [];
    public recordedRequests: Array<{
        url: string;
        method: string;
        headers: Record<string, string>;
        body?: unknown;
    }> = [];

    public exposeAuthenticate(ci: MJCompanyIntegrationEntity, user: UserInfo): Promise<GitHubAuthContext> {
        return this.Authenticate(ci, user);
    }

    public exposeBuildHeaders(auth: GitHubAuthContext): Record<string, string> {
        return this.BuildHeaders(auth);
    }

    public exposeGetBaseURL(ci: MJCompanyIntegrationEntity, auth: GitHubAuthContext): string {
        return this.GetBaseURL(ci, auth);
    }

    public exposeNormalizeResponse(raw: unknown, key: string | null): Record<string, unknown>[] {
        return this.NormalizeResponse(raw, key);
    }

    public exposeTransformRecord(raw: Record<string, unknown>, objName: string): Record<string, unknown> {
        const obj = { Name: objName } as unknown as MJIntegrationObjectEntity;
        return this.TransformRecord(raw, obj, []);
    }

    public exposeExtractPaginationInfo(
        rawBody: unknown,
        paginationType: PaginationType,
        currentPage: number,
        currentOffset: number,
        pageSize: number,
        linkHeader?: string
    ) {
        this.lastResponseHeaders = linkHeader ? { link: linkHeader } : {};
        return this.ExtractPaginationInfo(rawBody, paginationType, currentPage, currentOffset, pageSize);
    }

    public exposeBuildPaginatedURL(
        basePath: string,
        obj: Partial<MJIntegrationObjectEntity>,
        page: number,
        offset: number,
        cursor?: string,
        effectivePageSize?: number
    ): string {
        return this.BuildPaginatedURL(
            basePath,
            obj as MJIntegrationObjectEntity,
            page,
            offset,
            cursor,
            effectivePageSize
        );
    }

    public exposeAppendDefaultQueryParams(
        url: string,
        obj: Partial<MJIntegrationObjectEntity>,
        watermark?: string | null,
        auth?: GitHubAuthContext | null
    ): string {
        this.currentWatermark = watermark ?? null;
        this.currentAuth = auth ?? null;
        return this.AppendDefaultQueryParams(url, obj as MJIntegrationObjectEntity);
    }

    protected override async MakeHTTPRequest(
        _auth: GitHubAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown
    ): Promise<RESTResponse> {
        this.recordedRequests.push({ url, method, headers, body });
        const next = this.mockResponses.shift() ?? {
            Status: 200,
            Body: {},
            Headers: { 'x-github-api-version': GITHUB_API_VERSION },
        };
        this.lastResponseHeaders = next.Headers;
        return next;
    }
}

function makeCompanyIntegration(overrides: Partial<Record<string, unknown>> = {}): MJCompanyIntegrationEntity {
    return {
        ID: 'ci-github-1',
        IntegrationID: 'int-github-1',
        ExternalSystemID: (overrides['ExternalSystemID'] as string) ?? null,
        NavigationBaseURL: (overrides['NavigationBaseURL'] as string) ?? null,
        Configuration: overrides['Configuration']
            ? typeof overrides['Configuration'] === 'string'
                ? overrides['Configuration']
                : JSON.stringify(overrides['Configuration'])
            : null,
        AccessToken: (overrides['AccessToken'] as string) ?? null,
        APIKey: (overrides['APIKey'] as string) ?? null,
        Get: (field: string) => overrides[field] ?? null,
    } as unknown as MJCompanyIntegrationEntity;
}

const mockUser = { ID: 'user-1', Email: 'dev@memberjunction.org' } as unknown as UserInfo;

describe('GitHubConnector', () => {
    let connector: TestableGitHubConnector;

    beforeEach(() => {
        connector = new TestableGitHubConnector();
    });

    describe('Identity & Capabilities', () => {
        it('returns "GitHub" as IntegrationName and true for MonotonicWatermark', () => {
            expect(connector.IntegrationName).toBe('GitHub');
            expect(connector.MonotonicWatermark).toBe(true);
        });

        it('advertises search, list, get, create, and update capabilities', () => {
            const caps = connector.GetActionGeneratorCapabilities();
            expect(caps).toEqual({
                SupportsSearch: true,
                SupportsList: true,
                SupportsGet: true,
                SupportsCreate: true,
                SupportsUpdate: true,
                SupportsDelete: false,
            });
        });
    });

    describe('Authentication (PAT, OAuth, and GitHub App JWT)', () => {
        it('authenticates with a Personal Access Token from Configuration and builds standard headers', async () => {
            const ci = makeCompanyIntegration({
                ExternalSystemID: 'MemberJunction',
                Configuration: {
                    token: 'ghp_test_token_123',
                    repositories: ['MemberJunction/MJ', 'MemberJunction/Integrations'],
                },
            });

            const auth = await connector.exposeAuthenticate(ci, mockUser);
            expect(auth.Token).toBe('ghp_test_token_123');
            expect(auth.BaseURL).toBe(DEFAULT_GITHUB_API_BASE_URL);
            expect(auth.Owner).toBe('MemberJunction');
            expect(auth.Repositories).toEqual(['MemberJunction/MJ', 'MemberJunction/Integrations']);
            expect(auth.AuthMode).toBe('pat');

            const headers = connector.exposeBuildHeaders(auth);
            expect(headers['Authorization']).toBe('Bearer ghp_test_token_123');
            expect(headers['Accept']).toBe('application/vnd.github+json');
            expect(headers['X-GitHub-Api-Version']).toBe(GITHUB_API_VERSION);
        });

        it('mints an RS256 JWT and exchanges it for a GitHub App installation token', async () => {
            const { privateKey } = generateKeyPairSync('rsa', {
                modulusLength: 2048,
                publicKeyEncoding: { type: 'spki', format: 'pem' },
                privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
            });

            const jwt = createGitHubAppJwt('123456', privateKey);
            expect(jwt.split('.')).toHaveLength(3);

            connector.mockResponses.push({
                Status: 201,
                Body: {
                    token: 'ghs_installation_token_abc',
                    expires_at: '2026-11-05T11:00:00Z',
                },
                Headers: {},
            });

            const ci = makeCompanyIntegration({
                Configuration: {
                    appId: '123456',
                    installationId: '987654',
                    privateKey,
                    owner: 'MemberJunction',
                },
            });

            const auth = await connector.exposeAuthenticate(ci, mockUser);
            expect(auth.AuthMode).toBe('github-app');
            expect(auth.Token).toBe('ghs_installation_token_abc');
            expect(auth.ExpiresAt).toBeInstanceOf(Date);
            expect(connector.recordedRequests[0]?.url).toBe(
                'https://api.github.com/app/installations/987654/access_tokens'
            );
            expect(connector.recordedRequests[0]?.method).toBe('POST');
        });

        it('throws a clear error when neither token nor GitHub App credentials are provided', async () => {
            const ci = makeCompanyIntegration({ Configuration: {} });
            await expect(connector.exposeAuthenticate(ci, mockUser)).rejects.toThrow(/GitHub credentials require/);
        });
    });

    describe('Pagination & Incremental Watermark Sync', () => {
        it('parses RFC 5988 Link headers with rel="next"', () => {
            const link =
                '<https://api.github.com/repositories/123/issues?page=2&per_page=100>; rel="next", ' +
                '<https://api.github.com/repositories/123/issues?page=5&per_page=100>; rel="last"';
            expect(parseNextLinkHeader(link)).toBe(
                'https://api.github.com/repositories/123/issues?page=2&per_page=100'
            );

            const state = connector.exposeExtractPaginationInfo(
                [{ id: 1 }],
                'PageNumber',
                1,
                0,
                100,
                link
            );
            expect(state.HasMore).toBe(true);
            expect(state.NextPage).toBe(2);
        });

        it('stops pagination when Link header has only rel="prev"', () => {
            const link = '<https://api.github.com/repositories/123/issues?page=1&per_page=100>; rel="prev"';
            const state = connector.exposeExtractPaginationInfo(
                [{ id: 2 }],
                'PageNumber',
                2,
                100,
                100,
                link
            );
            expect(state.HasMore).toBe(false);
        });

        it('builds page and per_page URLs and injects since watermark parameter', () => {
            const obj: Partial<MJIntegrationObjectEntity> = {
                Name: 'issues',
                SupportsPagination: true,
                PaginationType: 'PageNumber',
                DefaultPageSize: 100,
                SupportsIncrementalSync: true,
                DefaultQueryParams: JSON.stringify({ state: 'all', sort: 'updated', direction: 'asc' }),
            };

            const withDefaults = connector.exposeAppendDefaultQueryParams(
                '/repos/MemberJunction/MJ/issues',
                obj,
                '2026-11-01T00:00:00Z'
            );
            expect(withDefaults).toContain('state=all');
            expect(withDefaults).toContain('since=2026-11-01T00%3A00%3A00Z');

            const paginated = connector.exposeBuildPaginatedURL(withDefaults, obj, 3, 200, undefined, 50);
            expect(paginated).toContain('page=3&per_page=50');
        });
    });

    describe('Response Normalization & Record Flattening', () => {
        it('unwraps workflow_runs and installation repositories envelopes', () => {
            const runs = connector.exposeNormalizeResponse(
                { total_count: 1, workflow_runs: [{ id: 901, name: 'CI' }] },
                'workflow_runs'
            );
            expect(runs).toEqual([{ id: 901, name: 'CI' }]);

            const repos = connector.exposeNormalizeResponse(
                { total_count: 1, repositories: [{ id: 10, full_name: 'MemberJunction/MJ' }] },
                null
            );
            expect(repos).toEqual([{ id: 10, full_name: 'MemberJunction/MJ' }]);
        });

        it('flattens nested author, pull request refs, and commit metadata onto scalar fields', () => {
            const pr = connector.exposeTransformRecord(
                {
                    id: 5001,
                    number: 6382,
                    html_url: 'https://github.com/MemberJunction/MJ/pull/6382',
                    user: { login: 'AN-BC', id: 97354817 },
                    head: { ref: 'feat/github-integration', sha: '3f95ef5c0' },
                    base: { ref: 'next', sha: '002c601' },
                    merged_by: { login: 'acannon' },
                    labels: [{ name: 'enhancement' }],
                },
                'pull_requests'
            );
            expect(pr['author_login']).toBe('AN-BC');
            expect(pr['repository_full_name']).toBe('MemberJunction/MJ');
            expect(pr['head_ref']).toBe('feat/github-integration');
            expect(pr['base_ref']).toBe('next');
            expect(pr['merged_by_login']).toBe('acannon');
            expect(pr['labels_json']).toBe('[{"name":"enhancement"}]');

            const commit = connector.exposeTransformRecord(
                {
                    sha: '3f95ef5c0abcdef',
                    html_url: 'https://github.com/MemberJunction/MJ/commit/3f95ef5c0abcdef',
                    author: { login: 'AN-BC' },
                    commit: {
                        message: 'feat(ai,actions): add GitHub integration',
                        author: {
                            name: 'AN-BC',
                            email: 'dev@memberjunction.org',
                            date: '2026-11-05T16:00:00Z',
                        },
                    },
                },
                'commits'
            );
            expect(commit['id']).toBe('3f95ef5c0abcdef');
            expect(commit['message']).toBe('feat(ai,actions): add GitHub integration');
            expect(commit['author_name']).toBe('AN-BC');
            expect(commit['author_email']).toBe('dev@memberjunction.org');
            expect(commit['committed_at']).toBe('2026-11-05T16:00:00Z');
        });
    });

    describe('TestConnection & CRUD Operations', () => {
        it('returns Success: true on TestConnection when GET /user succeeds', async () => {
            connector.mockResponses.push({
                Status: 200,
                Body: { login: 'AN-BC', id: 97354817 },
                Headers: { 'x-github-api-version': GITHUB_API_VERSION },
            });

            const ci = makeCompanyIntegration({
                Configuration: { token: 'ghp_valid' },
            });
            const res = await connector.TestConnection(ci, mockUser);
            expect(res.Success).toBe(true);
            expect(res.Message).toContain('AN-BC');
        });

        it('creates and updates issues and pull requests with repository routing', async () => {
            connector.mockResponses.push({
                Status: 201,
                Body: { id: 99901, number: 42, title: 'Sync GitHub issues' },
                Headers: {},
            });

            const ci = makeCompanyIntegration({
                Configuration: {
                    token: 'ghp_valid',
                    repositories: ['MemberJunction/Integrations'],
                },
            });

            const createRes = await connector.CreateRecord({
                CompanyIntegration: ci,
                ObjectName: 'issues',
                Attributes: {
                    title: 'Sync GitHub issues',
                    body: 'Verify bidirectional issue sync',
                },
                ContextUser: mockUser,
            });
            expect(createRes.Success).toBe(true);
            expect(createRes.ExternalID).toBe('42');
            expect(connector.recordedRequests[0]?.url).toBe(
                'https://api.github.com/repos/MemberJunction/Integrations/issues'
            );

            connector.mockResponses.push({
                Status: 200,
                Body: { id: 99901, number: 42, state: 'closed' },
                Headers: {},
            });

            const updateRes = await connector.UpdateRecord({
                CompanyIntegration: ci,
                ObjectName: 'issues',
                ExternalID: '42',
                Attributes: { state: 'closed' },
                ContextUser: mockUser,
            });
            expect(updateRes.Success).toBe(true);
            expect(connector.recordedRequests[1]?.method).toBe('PATCH');
            expect(connector.recordedRequests[1]?.url).toBe(
                'https://api.github.com/repos/MemberJunction/Integrations/issues/42'
            );
        });
    });
});
