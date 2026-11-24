import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { UserInfo } from '@memberjunction/core';
import type { MJCompanyIntegrationEntity, MJIntegrationObjectEntity } from '@memberjunction/core-entities';
import type { RESTResponse, FetchContext, SourceSchemaInfo, ExternalFieldSchema } from '@memberjunction/integration-engine';
import { SlayteConnector, normalizeSlayteBaseUrl } from '../SlayteConnector.js';

interface RecordedRequest {
    url: string;
    method: string;
    headers: Record<string, string>;
    body?: unknown;
}

/** Test double exposing protected seams without touching network or DB. */
class TestSlayteConnector extends SlayteConnector {
    public requests: RecordedRequest[] = [];
    public responder: (req: RecordedRequest) => RESTResponse | Promise<RESTResponse> = () => ({
        Status: 200,
        Body: { success: true, data: [] },
        Headers: { 'x-api-version': '2026-10-01' },
    });
    public mockCreds: Record<string, unknown> = {
        SiteUrl: 'https://example.slayte.test',
        ApiKey: 'test-primary-key',
    };

    protected override async loadRawCredentials(): Promise<Record<string, unknown>> {
        return this.mockCreds;
    }

    protected override async MakeHTTPRequest(
        _auth: unknown,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown
    ): Promise<RESTResponse> {
        const req: RecordedRequest = { url, method, headers, body };
        this.requests.push(req);
        return await this.responder(req);
    }

    protected override sleep(): Promise<void> {
        return Promise.resolve();
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

    public exposeNormalizeResponse(rawBody: unknown, key: string | null): Record<string, unknown>[] {
        return this.NormalizeResponse(rawBody, key);
    }

    public exposeExtractPaginationInfo(
        rawBody: unknown,
        type: 'Cursor' | 'None' | 'Offset' | 'PageNumber',
        currentPage: number,
        currentOffset: number,
        pageSize: number
    ) {
        return this.ExtractPaginationInfo(rawBody, type, currentPage, currentOffset, pageSize);
    }
}

const mockUser = { ID: '00000000-0000-0000-0000-000000000001' } as UserInfo;

function makeCI(config: Record<string, unknown> = {}): MJCompanyIntegrationEntity {
    return {
        ID: '00000000-0000-0000-0000-000000000002',
        IntegrationID: '00000000-0000-0000-0000-000000000003',
        CredentialID: '00000000-0000-0000-0000-000000000004',
        Configuration: JSON.stringify(config),
    } as unknown as MJCompanyIntegrationEntity;
}

function makeFetchCtx(
    objectName: string,
    config: Record<string, unknown> = {},
    overrides: Partial<FetchContext> = {}
): FetchContext {
    return {
        CompanyIntegration: makeCI(config),
        ObjectName: objectName,
        WatermarkValue: null,
        BatchSize: 100,
        ContextUser: mockUser,
        ...overrides,
    };
}

describe('SlayteConnector', () => {
    let connector: TestSlayteConnector;

    beforeEach(() => {
        connector = new TestSlayteConnector();
    });

    it('exposes identity, read-only capabilities, and rate limit policy', () => {
        expect(connector.IntegrationName).toBe('Slayte');
        expect(connector.SupportsGet).toBe(true);
        expect(connector.SupportsCreate).toBe(false);
        expect(connector.SupportsUpdate).toBe(false);
        expect(connector.SupportsDelete).toBe(false);
        expect(connector.SupportsUpsert).toBe(false);
        expect(connector.DiscoveryIsAuthoritative).toBe(false);
        expect(connector.RateLimitPolicy).toEqual({ TokensPerSec: 8, Burst: 20 });
    });

    it('normalizes workspace SiteUrl consistently without doubling /api or /v2', () => {
        expect(normalizeSlayteBaseUrl('https://workspace.example.org')).toBe('https://workspace.example.org/api');
        expect(normalizeSlayteBaseUrl('https://workspace.example.org/')).toBe('https://workspace.example.org/api');
        expect(normalizeSlayteBaseUrl('https://workspace.example.org/api')).toBe('https://workspace.example.org/api');
        expect(normalizeSlayteBaseUrl('https://workspace.example.org/api/')).toBe('https://workspace.example.org/api');
        expect(normalizeSlayteBaseUrl('https://workspace.example.org/api/v2')).toBe('https://workspace.example.org/api');
        expect(normalizeSlayteBaseUrl('https://workspace.example.org/api/v2/')).toBe('https://workspace.example.org/api');
    });

    describe('TestConnection', () => {
        it('succeeds and validates configured Individual & Organization queries using QueryApiKey', async () => {
            connector.mockCreds = {
                SiteUrl: 'https://workspace.example.org',
                ApiKey: 'primary-read-key',
                QueryApiKey: 'query-only-key',
            };
            connector.responder = (req) => {
                if (req.url.includes('/v2/crm/query/ind-q1/execute')) {
                    return {
                        Status: 200,
                        Body: { success: true, data: { data: [{ individualUuid: 'ind-1', firstName: 'Ada' }], cursor: null } },
                        Headers: { 'x-api-version': '2026-10-01' },
                    };
                }
                if (req.url.includes('/v2/crm/query/org-q1/execute')) {
                    return {
                        Status: 200,
                        Body: { success: true, data: { data: [{ organizationUuid: 'org-1', name: 'Acme Assoc' }], cursor: null } },
                        Headers: { 'x-api-version': '2026-10-01' },
                    };
                }
                return {
                    Status: 200,
                    Body: { success: true, data: { items: [], total: 0 } },
                    Headers: { 'x-api-version': '2026-10-01' },
                };
            };

            const res = await connector.TestConnection(
                makeCI({ individualQueryId: 'ind-q1', organizationQueryId: 'org-q1' }),
                mockUser
            );

            expect(res.Success).toBe(true);
            expect(res.ServerVersion).toBe('2026-10-01');
            expect(connector.requests[0].headers['X-Api-Key']).toBe('query-only-key');
            expect(connector.requests[1].headers['X-Api-Key']).toBe('query-only-key');
            // Primary key probed because QueryApiKey differs from ApiKey
            expect(connector.requests[2].headers['X-Api-Key']).toBe('primary-read-key');
        });

        it('fails TestConnection with a clear message when a configured query returns rows without any key column', async () => {
            connector.responder = () => ({
                Status: 200,
                Body: { success: true, data: { data: [{ firstName: 'Ada', profileEmail: 'ada@example.org' }], cursor: null } },
                Headers: {},
            });

            const res = await connector.TestConnection(makeCI({ individualQueryId: 'ind-no-key' }), mockUser);
            expect(res.Success).toBe(false);
            expect(res.Message).toMatch(/without a recognized primary key column/i);
            expect(res.Message).toContain('firstName');
        });

        it('reports 401 API_KEY_EXPIRED and 403 SCOPE_REQUIRED clearly', async () => {
            connector.responder = () => ({
                Status: 401,
                Body: { success: false, error: { code: 401, type: 'API_KEY_EXPIRED', message: 'Key expired' } },
                Headers: {},
            });
            const expired = await connector.TestConnection(makeCI(), mockUser);
            expect(expired.Success).toBe(false);
            expect(expired.Message).toContain('API_KEY_EXPIRED');

            connector.responder = () => ({
                Status: 403,
                Body: {
                    success: false,
                    error: {
                        code: 403,
                        type: 'SCOPE_REQUIRED',
                        message: 'Missing scope',
                        details: { requiredScope: 'crm:query' },
                    },
                },
                Headers: {},
            });
            const noScope = await connector.TestConnection(makeCI(), mockUser);
            expect(noScope.Success).toBe(false);
            expect(noScope.Message).toContain('SCOPE_REQUIRED');
            expect(noScope.Message).toContain('requiredScope=crm:query');
        });
    });

    describe('Bulk Shared CRM Query FetchChanges (Individual & Organization)', () => {
        it('throws an error (never silent 0-row success) when query ID is not configured', async () => {
            await expect(connector.FetchChanges(makeFetchCtx('Individual', {})))
                .rejects.toThrow(/individualQueryId/);
            await expect(connector.FetchChanges(makeFetchCtx('Organization', {})))
                .rejects.toThrow(/organizationQueryId/);
        });

        it('paginates POST /v2/crm/query/{id}/execute via cursor, forwards params, preserves all columns, and surfaces warnings', async () => {
            connector.mockCreds = {
                SiteUrl: 'https://workspace.example.org',
                ApiKey: 'primary-key',
                QueryApiKey: 'query-key',
            };
            connector.responder = (req) => {
                if (!req.url.includes('cursor=')) {
                    return {
                        Status: 200,
                        Body: {
                            success: true,
                            data: {
                                data: [
                                    { individualUuid: 'u-1', firstName: 'Grace', customMembershipTier: 'Gold' },
                                    { uuid: 'u-2', firstName: 'Alan', customMembershipTier: 'Silver' },
                                ],
                                cursor: 'cur-page-2',
                                totalRecordCount: 3,
                                warnings: ['Deprecated column ignored'],
                            },
                        },
                        Headers: {},
                    };
                }
                return {
                    Status: 200,
                    Body: {
                        success: true,
                        data: {
                            data: [{ individualUuid: 'u-3', firstName: 'Linus' }],
                            cursor: null,
                            totalRecordCount: 3,
                        },
                    },
                    Headers: {},
                };
            };

            const cfg = {
                individualQueryId: 'q-ind-all',
                individualQueryParams: { 'p-1': 'active' },
            };

            const page1 = await connector.FetchChanges(makeFetchCtx('Individual', cfg));
            expect(page1.Records).toHaveLength(2);
            expect(page1.Records[0].ExternalID).toBe('u-1');
            expect(page1.Records[0].Fields.customMembershipTier).toBe('Gold');
            // Fallback uuid normalized onto individualUuid while preserving original uuid
            expect(page1.Records[1].ExternalID).toBe('u-2');
            expect(page1.Records[1].Fields.individualUuid).toBe('u-2');
            expect(page1.HasMore).toBe(true);
            expect(page1.NextCursor).toBe('cur-page-2');
            expect(page1.Warnings?.[0].Code).toBe('SLAYTE_QUERY_WARNING');
            expect(connector.requests[0].method).toBe('POST');
            expect(connector.requests[0].url).toBe('https://workspace.example.org/api/v2/crm/query/q-ind-all/execute');
            expect(connector.requests[0].headers['X-Api-Key']).toBe('query-key');
            expect(connector.requests[0].body).toEqual({ params: { 'p-1': 'active' } });

            const page2 = await connector.FetchChanges(makeFetchCtx('Individual', cfg, { CurrentCursor: 'cur-page-2' }));
            expect(page2.Records).toHaveLength(1);
            expect(page2.HasMore).toBe(false);
            expect(page2.NextCursor).toBeUndefined();
            expect(connector.requests[1].url).toBe('https://workspace.example.org/api/v2/crm/query/q-ind-all/execute?cursor=cur-page-2');
        });

        it('throws on FetchChanges when a query row omits any recognized primary key column', async () => {
            connector.responder = () => ({
                Status: 200,
                Body: {
                    success: true,
                    data: {
                        data: [{ name: 'No Key Corp', domain: 'example.org' }],
                        cursor: null,
                    },
                },
                Headers: {},
            });

            await expect(
                connector.FetchChanges(makeFetchCtx('Organization', { organizationQueryId: 'q-org-bad' }))
            ).rejects.toThrow(/without a recognized primary key column/i);
        });
    });

    describe('CRMQuery & DirectoryEntry', () => {
        it('fetches CRMQuery catalog across both ind and org entity types', async () => {
            connector.responder = (req) => ({
                Status: 200,
                Body: {
                    success: true,
                    data: req.url.includes('entityType=ind')
                        ? [{ uuid: 'q-1', name: 'All Individuals', params: [] }]
                        : [{ uuid: 'q-2', name: 'All Orgs', params: [] }],
                },
                Headers: {},
            });

            const res = await connector.FetchChanges(makeFetchCtx('CRMQuery'));
            expect(res.HasMore).toBe(false);
            expect(res.Records).toHaveLength(2);
            expect(res.Records[0].Fields.entityType).toBe('ind');
            expect(res.Records[1].Fields.entityType).toBe('org');
        });

        it('paginates DirectoryEntry across configured directories via cursor and AfterKeyValue', async () => {
            connector.responder = (req) => {
                if (req.method === 'GET' && req.url.endsWith('/v2/directory')) {
                    return {
                        Status: 200,
                        Body: { success: true, data: [{ uuid: 'dir-1', slug: 'members', entityType: 'ind' }] },
                        Headers: {},
                    };
                }
                if (req.method === 'POST' && !req.url.includes('cursor=')) {
                    return {
                        Status: 200,
                        Body: {
                            success: true,
                            data: {
                                data: [{ entityUuid: 'e-1', tags: ['active'], entity: { displayName: 'Jane' } }],
                                cursor: 'dir-cur-2',
                            },
                        },
                        Headers: {},
                    };
                }
                return {
                    Status: 200,
                    Body: {
                        success: true,
                        data: {
                            data: [{ entityUuid: 'e-2', tags: [], entity: { displayName: 'John' } }],
                            cursor: null,
                        },
                    },
                    Headers: {},
                };
            };

            const batch1 = await connector.FetchChanges(makeFetchCtx('DirectoryEntry'));
            expect(batch1.HasMore).toBe(true);
            expect(batch1.NextAfterKeyValue).toBe('0|dir-cur-2');
            expect(batch1.Records[0].ExternalID).toBe('dir-1::e-1');
            expect(batch1.Records[0].Fields.displayName).toBe('Jane');

            const batch2 = await connector.FetchChanges(
                makeFetchCtx('DirectoryEntry', {}, { AfterKeyValue: batch1.NextAfterKeyValue })
            );
            expect(batch2.HasMore).toBe(false);
            expect(batch2.Records[0].ExternalID).toBe('dir-1::e-2');
        });
    });

    describe('Zero-based REST Pagination, Normalization, & GetRecord', () => {
        it('translates 1-based MJ pages to 0-based Slayte pages and clamps pageSize to 250', () => {
            const url1 = connector.exposeBuildPaginatedURL(
                'https://workspace.example.org/api/v2/event',
                { Name: 'Event', PaginationType: 'PageNumber', DefaultPageSize: 100 },
                1,
                0,
                undefined,
                500
            );
            expect(url1).toBe('https://workspace.example.org/api/v2/event?page=0&pageSize=250');

            const url2 = connector.exposeBuildPaginatedURL(
                'https://workspace.example.org/api/v2/crm/committee',
                { Name: 'Committee', PaginationType: 'PageNumber', DefaultPageSize: 50 },
                2,
                50,
                undefined,
                50
            );
            expect(url2).toBe('https://workspace.example.org/api/v2/crm/committee?page=1&pageSize=50&includeids=true');
        });

        it('computes HasMore accurately from 0-based page and total count', () => {
            const page0 = connector.exposeExtractPaginationInfo(
                { success: true, data: { items: [{ uuid: '1' }, { uuid: '2' }], total: 3, page: 0, pageSize: 2 } },
                'PageNumber',
                1,
                0,
                2
            );
            expect(page0.HasMore).toBe(true);
            expect(page0.NextPage).toBe(2);
            expect(page0.TotalRecords).toBe(3);

            const page1 = connector.exposeExtractPaginationInfo(
                { success: true, data: { items: [{ uuid: '3' }], total: 3, page: 1, pageSize: 2 } },
                'PageNumber',
                2,
                2,
                2
            );
            expect(page1.HasMore).toBe(false);
            expect(page1.TotalRecords).toBe(3);
        });

        it('executes point-lookup GetRecord for Individual and Organization with includeids=true and fields', async () => {
            connector.responder = () => ({
                Status: 200,
                Body: { success: true, data: { individualUuid: 'ind-42', firstName: 'Nadia' } },
                Headers: {},
            });

            const rec = await connector.GetRecord({
                CompanyIntegration: makeCI({ individualFields: 'firstName,lastName' }),
                ObjectName: 'Individual',
                ExternalID: 'ind-42',
                ContextUser: mockUser,
            });

            expect(rec?.ExternalID).toBe('ind-42');
            expect(rec?.Fields.firstName).toBe('Nadia');
            expect(connector.requests[0].url).toBe(
                'https://example.slayte.test/api/v2/crm/individual/ind-42?includeids=true&fields=firstName%2ClastName'
            );
        });

        it('returns null on GetRecord 404', async () => {
            connector.responder = () => ({
                Status: 404,
                Body: { success: false, error: { code: 404, type: 'NOT_FOUND', message: 'Not found' } },
                Headers: {},
            });
            const rec = await connector.GetRecord({
                CompanyIntegration: makeCI(),
                ObjectName: 'Organization',
                ExternalID: 'missing-uuid',
                ContextUser: mockUser,
            });
            expect(rec).toBeNull();
        });
    });

    describe('IntrospectSchema sample-union', () => {
        it('merges declared core fields with live sampled custom columns and widens MaxLength', async () => {
            const declaredSchema: SourceSchemaInfo = {
                IsAuthoritative: false,
                Objects: [
                    {
                        ExternalName: 'Individual',
                        Label: 'Individual',
                        Fields: [
                            {
                                Name: 'individualUuid',
                                Label: 'Individual Uuid',
                                SourceType: 'String',
                                IsRequired: true,
                                IsPrimaryKey: true,
                                IsUniqueKey: true,
                                IsReadOnly: true,
                                MaxLength: 100,
                            },
                            {
                                Name: 'profileTitle',
                                Label: 'Profile Title',
                                SourceType: 'String',
                                IsRequired: false,
                                IsPrimaryKey: false,
                                IsUniqueKey: false,
                                IsReadOnly: true,
                                MaxLength: 255,
                            },
                        ],
                        Relationships: [],
                    },
                ],
            };

            const superSpy = vi.spyOn(
                Object.getPrototypeOf(SlayteConnector.prototype),
                'IntrospectSchema'
            );
            superSpy.mockResolvedValueOnce(declaredSchema);

            const sampledFields: ExternalFieldSchema[] = [
                {
                    Name: 'profileTitle',
                    Label: 'Profile Title',
                    DataType: 'String',
                    IsRequired: false,
                    IsUniqueKey: false,
                    IsReadOnly: true,
                    MaxLength: 310,
                },
                {
                    Name: 'membershipStatus',
                    Label: 'Membership Status',
                    DataType: 'String',
                    IsRequired: false,
                    IsUniqueKey: false,
                    IsReadOnly: true,
                    MaxLength: 45,
                },
            ];
            vi.spyOn(connector, 'DiscoverFieldsViaFetch').mockResolvedValueOnce(sampledFields);

            const merged = await connector.IntrospectSchema(makeCI(), mockUser);
            const fields = merged.Objects[0].Fields;
            expect(fields.find((f) => f.Name === 'profileTitle')?.MaxLength).toBe(512);
            expect(fields.find((f) => f.Name === 'membershipStatus')?.MaxLength).toBe(64);

            superSpy.mockRestore();
        });
    });

    describe('Retry-After extraction & rate limits', () => {
        it('extracts Retry-After seconds from 429 errors', () => {
            const err = Object.assign(new Error('HTTP 429'), {
                status: 429,
                headers: { 'retry-after': '12' },
            });
            expect(connector.ExtractRetryAfterMs(err)).toBe(12000);
        });
    });
});
