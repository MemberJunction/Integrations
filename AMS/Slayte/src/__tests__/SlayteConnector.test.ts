import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { RunView, type UserInfo } from '@memberjunction/core';
import type {
    MJCompanyIntegrationEntity,
    MJIntegrationObjectEntity,
    MJIntegrationObjectFieldEntity,
} from '@memberjunction/core-entities';
import { IntegrationEngineBase } from '@memberjunction/integration-engine-base';
import type {
    RESTResponse,
    FetchContext,
    FetchBatchResult,
    SourceSchemaInfo,
    ExternalFieldSchema,
} from '@memberjunction/integration-engine';
import {
    SlayteConnector,
    normalizeSlayteBaseUrl,
    parseConnectionSettings,
    deletedParentAsEmpty,
} from '../SlayteConnector.js';

interface RecordedRequest {
    url: string;
    method: string;
    headers: Record<string, string>;
    body?: unknown;
}

/**
 * Test subclass that overrides ONLY `loadRawCredentials` — exercises the REAL
 * `MakeHTTPRequest` + `fetch`, `super.FetchChanges`, `BuildPaginatedURL`,
 * `ExtractPaginationInfo`, 429 error propagation, and deleted-parent 404 handling.
 */
class FetchBackedSlayteConnector extends SlayteConnector {
    public mockCreds: Record<string, unknown> = {
        SiteUrl: 'https://example.slayte.test',
        ApiKey: 'test-primary-key',
    };

    protected override async loadRawCredentials(): Promise<Record<string, unknown>> {
        return this.mockCreds;
    }

    protected override sleep(): Promise<void> {
        return Promise.resolve();
    }
}

const INTEGRATION_ID = '00000000-0000-0000-0000-000000000003';
const COMPANY_INTEGRATION_ID = '00000000-0000-0000-0000-000000000002';
const mockUser = { ID: '00000000-0000-0000-0000-000000000001' } as UserInfo;

function makeCI(config: Record<string, unknown> = {}): MJCompanyIntegrationEntity {
    return {
        ID: COMPANY_INTEGRATION_ID,
        IntegrationID: INTEGRATION_ID,
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

function jsonResponse(body: unknown, status = 200, headers: Record<string, string> = {}): Response {
    return new Response(body == null ? '' : JSON.stringify(body), {
        status,
        headers: { 'content-type': 'application/json', ...headers },
    });
}

function makeCachedObject(overrides: Partial<MJIntegrationObjectEntity>): MJIntegrationObjectEntity {
    return {
        ID: overrides.ID ?? 'obj-default',
        IntegrationID: INTEGRATION_ID,
        Name: overrides.Name ?? 'Event',
        DisplayName: overrides.DisplayName ?? overrides.Name ?? 'Event',
        APIPath: overrides.APIPath ?? '/v2/event',
        Status: 'Active',
        PaginationType: overrides.PaginationType ?? 'PageNumber',
        SupportsPagination: (overrides.PaginationType ?? 'PageNumber') !== 'None',
        DefaultPageSize: overrides.DefaultPageSize ?? 100,
        DefaultQueryParams: null,
        ResponseDataKey: overrides.ResponseDataKey ?? 'data.items',
        SupportsIncrementalSync: overrides.SupportsIncrementalSync ?? false,
        SupportsWrite: false,
        Configuration: overrides.Configuration ?? JSON.stringify({ syncStrategy: 'FullPullHashDiff' }),
        ...overrides,
    } as unknown as MJIntegrationObjectEntity;
}

function makeCachedField(
    objectID: string,
    name: string,
    overrides: Partial<MJIntegrationObjectFieldEntity> = {}
): MJIntegrationObjectFieldEntity {
    return {
        ID: `field-${objectID}-${name}`,
        IntegrationObjectID: objectID,
        Name: name,
        DisplayName: name,
        Type: 'String',
        Status: 'Active',
        IsPrimaryKey: false,
        IsUniqueKey: false,
        IsRequired: false,
        IsReadOnly: true,
        AllowsNull: true,
        Length: 100,
        RelatedIntegrationObjectID: null,
        RelatedIntegrationObjectFieldName: null,
        ...overrides,
    } as unknown as MJIntegrationObjectFieldEntity;
}

describe('SlayteConnector', () => {
    let connector: FetchBackedSlayteConnector;
    let recorded: RecordedRequest[];
    let fetchHandler: (req: RecordedRequest) => Response | Promise<Response>;

    beforeEach(() => {
        connector = new FetchBackedSlayteConnector();
        recorded = [];
        fetchHandler = () => jsonResponse({ success: true, data: [] }, 200, { 'x-api-version': '2026-10-01' });

        vi.stubGlobal('fetch', vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
            const url = typeof input === 'string' ? input : input.toString();
            const method = (init?.method ?? 'GET').toUpperCase();
            const headers: Record<string, string> = {};
            if (init?.headers && typeof init.headers === 'object' && !Array.isArray(init.headers)) {
                for (const [k, v] of Object.entries(init.headers as Record<string, string>)) {
                    headers[k] = v;
                }
            }
            let body: unknown = undefined;
            if (typeof init?.body === 'string' && init.body.length > 0) {
                try { body = JSON.parse(init.body); } catch { body = init.body; }
            }
            const req: RecordedRequest = { url, method, headers, body };
            recorded.push(req);
            return await fetchHandler(req);
        }));
    });

    afterEach(() => {
        vi.restoreAllMocks();
        vi.unstubAllGlobals();
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

    it('surfaces invalid CompanyIntegration.Configuration instead of silently discarding all settings', () => {
        expect(() => parseConnectionSettings('{not-json')).toThrow(/Invalid JSON/);
        expect(() =>
            parseConnectionSettings(JSON.stringify({ individualQueryId: 'q-1', requestTimeoutMs: -5 }))
        ).toThrow(/Invalid Slayte CompanyIntegration\.Configuration.*requestTimeoutMs/);
    });

    describe('TestConnection', () => {
        it('validates configured Individual & Organization queries using QueryApiKey and probes ApiKey when keys differ', async () => {
            connector.mockCreds = {
                SiteUrl: 'https://workspace.example.org',
                ApiKey: 'primary-read-key',
                QueryApiKey: 'query-only-key',
            };
            fetchHandler = (req) => {
                if (req.url.includes('/v2/crm/query/ind-q1/execute')) {
                    return jsonResponse(
                        { success: true, data: { data: [{ individualUuid: 'ind-1', firstName: 'Ada' }], cursor: null } },
                        200,
                        { 'x-api-version': '2026-10-01' }
                    );
                }
                if (req.url.includes('/v2/crm/query/org-q1/execute')) {
                    return jsonResponse(
                        { success: true, data: { data: [{ organizationUuid: 'org-1', name: 'Acme Assoc' }], cursor: null } },
                        200,
                        { 'x-api-version': '2026-10-01' }
                    );
                }
                return jsonResponse({ success: true, data: { items: [], total: 0 } }, 200, { 'x-api-version': '2026-10-01' });
            };

            const res = await connector.TestConnection(
                makeCI({ individualQueryId: 'ind-q1', organizationQueryId: 'org-q1' }),
                mockUser
            );

            expect(res.Success).toBe(true);
            expect(res.ServerVersion).toBe('2026-10-01');
            expect(recorded[0].headers['X-Api-Key']).toBe('query-only-key');
            expect(recorded[1].headers['X-Api-Key']).toBe('query-only-key');
            expect(recorded[2].headers['X-Api-Key']).toBe('primary-read-key');
        });

        it('validates BOTH QueryApiKey and primary ApiKey when keys differ and no query IDs are configured', async () => {
            connector.mockCreds = {
                SiteUrl: 'https://workspace.example.org',
                ApiKey: 'primary-read-key',
                QueryApiKey: 'query-only-key',
            };
            fetchHandler = () => jsonResponse({ success: true, data: { items: [], total: 0 } }, 200);

            const res = await connector.TestConnection(makeCI({}), mockUser);
            expect(res.Success).toBe(true);
            // ServerVersion is omitted (never fabricated) when X-Api-Version header is absent
            expect(res.ServerVersion).toBeUndefined();
            expect(recorded.map((r) => ({ url: r.url, key: r.headers['X-Api-Key'] }))).toEqual([
                { url: 'https://workspace.example.org/api/v2/crm/query?entityType=ind', key: 'query-only-key' },
                { url: 'https://workspace.example.org/api/v2/event?page=0&pageSize=1', key: 'primary-read-key' },
            ]);
        });

        it('fails TestConnection when a configured query returns rows without any key column', async () => {
            fetchHandler = () =>
                jsonResponse({ success: true, data: { data: [{ firstName: 'Ada', profileEmail: 'ada@example.org' }], cursor: null } });

            const res = await connector.TestConnection(makeCI({ individualQueryId: 'ind-no-key' }), mockUser);
            expect(res.Success).toBe(false);
            expect(res.Message).toMatch(/without a recognized primary key column/i);
            expect(res.Message).toContain('firstName');
        });

        it('reports 401 API_KEY_EXPIRED and 403 SCOPE_REQUIRED clearly', async () => {
            fetchHandler = () =>
                jsonResponse({ success: false, error: { code: 401, type: 'API_KEY_EXPIRED', message: 'Key expired' } }, 401);
            const expired = await connector.TestConnection(makeCI(), mockUser);
            expect(expired.Success).toBe(false);
            expect(expired.Message).toContain('API_KEY_EXPIRED');

            fetchHandler = () =>
                jsonResponse(
                    {
                        success: false,
                        error: {
                            code: 403,
                            type: 'SCOPE_REQUIRED',
                            message: 'Missing scope',
                            details: { requiredScope: 'crm:query' },
                        },
                    },
                    403
                );
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

        it('paginates POST /v2/crm/query/{id}/execute via cursor, returns SourceTotalRecords, forwards params, and surfaces warnings', async () => {
            connector.mockCreds = {
                SiteUrl: 'https://workspace.example.org',
                ApiKey: 'primary-key',
                QueryApiKey: 'query-key',
            };
            fetchHandler = (req) => {
                if (!req.url.includes('cursor=')) {
                    return jsonResponse({
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
                    });
                }
                return jsonResponse({
                    success: true,
                    data: {
                        data: [{ individualUuid: 'u-3', firstName: 'Linus' }],
                        cursor: null,
                        totalRecordCount: 3,
                    },
                });
            };

            const cfg = {
                individualQueryId: 'q-ind-all',
                individualQueryParams: { 'p-1': 'active' },
            };

            const page1 = (await connector.FetchChanges(makeFetchCtx('Individual', cfg))) as FetchBatchResult & {
                SourceTotalRecords?: number;
            };
            expect(page1.Records).toHaveLength(2);
            expect(page1.Records[0].ExternalID).toBe('u-1');
            expect(page1.Records[0].Fields.customMembershipTier).toBe('Gold');
            expect(page1.Records[1].ExternalID).toBe('u-2');
            expect(page1.Records[1].Fields.individualUuid).toBe('u-2');
            expect(page1.HasMore).toBe(true);
            expect(page1.NextCursor).toBe('cur-page-2');
            expect(page1.SourceTotalRecords).toBe(3);
            expect(page1.Warnings?.[0].Code).toBe('SLAYTE_QUERY_WARNING');
            expect(recorded[0].method).toBe('POST');
            expect(recorded[0].url).toBe('https://workspace.example.org/api/v2/crm/query/q-ind-all/execute');
            expect(recorded[0].headers['X-Api-Key']).toBe('query-key');
            expect(recorded[0].body).toEqual({ params: { 'p-1': 'active' } });

            const page2 = await connector.FetchChanges(makeFetchCtx('Individual', cfg, { CurrentCursor: 'cur-page-2' }));
            expect(page2.Records).toHaveLength(1);
            expect(page2.HasMore).toBe(false);
            expect(page2.NextCursor).toBeUndefined();
            expect(recorded[1].url).toBe('https://workspace.example.org/api/v2/crm/query/q-ind-all/execute?cursor=cur-page-2');
        });

        it('throws on FetchChanges when a query row omits any recognized primary key column', async () => {
            fetchHandler = () =>
                jsonResponse({ success: true, data: { data: [{ name: 'No Key Corp', domain: 'example.org' }], cursor: null } });

            await expect(
                connector.FetchChanges(makeFetchCtx('Organization', { organizationQueryId: 'q-org-bad' }))
            ).rejects.toThrow(/without a recognized primary key column/i);
        });
    });

    describe('super.FetchChanges Integration Paths (BaseRESTIntegrationConnector)', () => {
        function stubEngineCatalog(objects: MJIntegrationObjectEntity[], fieldsByObj: Record<string, MJIntegrationObjectFieldEntity[]>) {
            vi.spyOn(IntegrationEngineBase.Instance, 'GetActiveIntegrationObjects').mockReturnValue(objects);
            vi.spyOn(IntegrationEngineBase.Instance, 'GetIntegrationObjectsByIntegrationID').mockReturnValue(objects);
            vi.spyOn(IntegrationEngineBase.Instance, 'GetIntegrationObject').mockImplementation(
                (_intId: string, name: string) => objects.find((o) => o.Name === name)
            );
            vi.spyOn(IntegrationEngineBase.Instance, 'GetIntegrationObjectByID').mockImplementation(
                (id: string) => objects.find((o) => o.ID === id)
            );
            vi.spyOn(IntegrationEngineBase.Instance, 'GetIntegrationObjectFields').mockImplementation(
                (objId: string) => fieldsByObj[objId] ?? []
            );
        }

        it('keeps pageSize fixed on PageNumber paging even when BatchSize (300) exceeds DefaultPageSize (250) so no rows are skipped', async () => {
            const eventObj = makeCachedObject({
                ID: 'obj-event',
                Name: 'Event',
                APIPath: '/v2/event',
                PaginationType: 'PageNumber',
                DefaultPageSize: 250,
            });
            stubEngineCatalog([eventObj], {
                'obj-event': [
                    makeCachedField('obj-event', 'uuid', { IsPrimaryKey: true, IsUniqueKey: true }),
                    makeCachedField('obj-event', 'name'),
                ],
            });

            // 550 total events across 3 fixed pages of 250 (0..249, 250..499, 500..549)
            fetchHandler = (req) => {
                const u = new URL(req.url);
                const page = Number(u.searchParams.get('page'));
                const pageSize = Number(u.searchParams.get('pageSize'));
                const start = page * pageSize;
                const count = Math.max(0, Math.min(pageSize, 550 - start));
                const items = Array.from({ length: count }, (_, i) => ({
                    uuid: `ev-${start + i}`,
                    name: `Event ${start + i}`,
                }));
                return jsonResponse({ success: true, data: { items, total: 550 } });
            };

            const seenIds: string[] = [];
            let page: number | undefined = 1;
            let hasMore = true;
            while (hasMore) {
                const batch = await connector.FetchChanges(
                    makeFetchCtx('Event', {}, { BatchSize: 300, CurrentPage: page })
                );
                seenIds.push(...batch.Records.map((r) => r.ExternalID));
                hasMore = batch.HasMore;
                page = batch.NextPage;
            }

            // Every request used fixed pageSize=250 (never shrunk to 50) and all 550 unique events landed
            expect(recorded.map((r) => new URL(r.url).searchParams.get('pageSize'))).toEqual(['250', '250', '250']);
            expect(recorded.map((r) => new URL(r.url).searchParams.get('page'))).toEqual(['0', '1', '2']);
            expect(new Set(seenIds).size).toBe(550);
            expect(seenIds.length).toBe(550);
        });

        it('preserves child uuid on CommitteeAssignedPosition when walking parent Committee via {committeeUuid}', async () => {
            const committeeObj = makeCachedObject({
                ID: 'obj-committee',
                Name: 'Committee',
                APIPath: '/v2/crm/committee',
                PaginationType: 'PageNumber',
                DefaultPageSize: 100,
            });
            const assignedPosObj = makeCachedObject({
                ID: 'obj-cap',
                Name: 'CommitteeAssignedPosition',
                APIPath: '/v2/crm/committee/{committeeUuid}/position',
                PaginationType: 'None',
                Configuration: JSON.stringify({
                    parentObjectName: 'Committee',
                    apiPath: '/v2/crm/committee/{committeeUuid}/position',
                    syncStrategy: 'FullPullHashDiff',
                }),
            });
            stubEngineCatalog([committeeObj, assignedPosObj], {
                'obj-committee': [
                    makeCachedField('obj-committee', 'committeeUuid', { IsPrimaryKey: true, IsUniqueKey: true }),
                ],
                'obj-cap': [
                    makeCachedField('obj-cap', 'uuid', { IsPrimaryKey: true, IsUniqueKey: true }),
                    makeCachedField('obj-cap', 'committeeUuid', {
                        IsPrimaryKey: true,
                        IsUniqueKey: true,
                        RelatedIntegrationObjectID: 'obj-committee',
                        RelatedIntegrationObjectFieldName: 'committeeUuid',
                    }),
                    makeCachedField('obj-cap', 'name'),
                ],
            });

            // Stub RunView so BaseRESTIntegrationConnector loads parent Committee IDs from the mapped MJ entity
            vi.spyOn(RunView.prototype, 'RunView').mockImplementation(async (params: { EntityName?: string }) => {
                if (params.EntityName === 'MJ: Company Integration Entity Maps') {
                    return { Success: true, Results: [{ EntityID: 'ent-comm', Entity: 'Slayte Committees' }] } as never;
                }
                if (params.EntityName === 'Slayte Committees') {
                    return { Success: true, Results: [{ committeeUuid: 'comm-A' }] } as never;
                }
                return { Success: true, Results: [] } as never;
            });

            fetchHandler = () =>
                jsonResponse({
                    success: true,
                    data: {
                        items: [
                            { uuid: 'pos-1', name: 'Chair', committeeUuid: 'comm-A' },
                            { uuid: 'pos-2', name: 'Secretary', committeeUuid: 'comm-A' },
                        ],
                        total: 2,
                    },
                });

            const batch = await connector.FetchChanges(makeFetchCtx('CommitteeAssignedPosition'));
            expect(recorded[0].url).toBe('https://example.slayte.test/api/v2/crm/committee/comm-A/position');
            expect(batch.Records).toHaveLength(2);
            // Distinct child uuids preserved (NOT overwritten by comm-A!)
            expect(batch.Records[0].Fields.uuid).toBe('pos-1');
            expect(batch.Records[1].Fields.uuid).toBe('pos-2');
            expect(batch.Records[0].Fields.committeeUuid).toBe('comm-A');
            expect(batch.Records[0].ExternalID).not.toBe(batch.Records[1].ExternalID);
        });

        it('forwards changedSince watermark on EventRegistrant through super.FetchChanges and leaves NewWatermarkValue unset for engine now-watermark', async () => {
            const eventObj = makeCachedObject({ ID: 'obj-event', Name: 'Event', APIPath: '/v2/event' });
            const regObj = makeCachedObject({
                ID: 'obj-reg',
                Name: 'EventRegistrant',
                APIPath: '/v2/event/{eventUuid}/registrant',
                PaginationType: 'PageNumber',
                DefaultPageSize: 100,
                SupportsIncrementalSync: true,
                Configuration: JSON.stringify({
                    parentObjectName: 'Event',
                    apiPath: '/v2/event/{eventUuid}/registrant',
                    watermarkParam: 'changedSince',
                    syncStrategy: 'IncrementalWatermark',
                }),
            });
            stubEngineCatalog([eventObj, regObj], {
                'obj-event': [makeCachedField('obj-event', 'uuid', { IsPrimaryKey: true, IsUniqueKey: true })],
                'obj-reg': [
                    makeCachedField('obj-reg', 'registrantUuid', { IsPrimaryKey: true, IsUniqueKey: true }),
                    makeCachedField('obj-reg', 'eventUuid', { RelatedIntegrationObjectID: 'obj-event', RelatedIntegrationObjectFieldName: 'uuid' }),
                    makeCachedField('obj-reg', 'registrationDate'),
                ],
            });

            vi.spyOn(RunView.prototype, 'RunView').mockImplementation(async (params: { EntityName?: string }) => {
                if (params.EntityName === 'MJ: Company Integration Entity Maps') {
                    return { Success: true, Results: [{ EntityID: 'ent-ev', Entity: 'Slayte Events' }] } as never;
                }
                if (params.EntityName === 'Slayte Events') {
                    return { Success: true, Results: [{ uuid: 'ev-1' }, { uuid: 'ev-deleted' }] } as never;
                }
                return { Success: true, Results: [] } as never;
            });

            fetchHandler = (req) => {
                if (req.url.includes('/ev-deleted/')) {
                    return jsonResponse({ success: false, error: { code: 404, type: 'NOT_FOUND', message: 'Deleted event' } }, 404);
                }
                return jsonResponse({
                    success: true,
                    data: {
                        items: [{ registrantUuid: 'r-1', registrationDate: '2024-01-15T00:00:00Z' }],
                        total: 1,
                    },
                });
            };

            const batch = await connector.FetchChanges(
                makeFetchCtx('EventRegistrant', {}, { WatermarkValue: '2026-11-01T00:00:00Z' })
            );

            // Both event requests carried changedSince shifted back by the 15-minute overlap window,
            // deleted event 404 did not abort sync, and old registrationDate is NOT emitted as NewWatermarkValue
            expect(recorded).toHaveLength(2);
            expect(new URL(recorded[0].url).searchParams.get('changedSince')).toBe('2026-10-31T23:45:00.000Z');
            expect(new URL(recorded[1].url).searchParams.get('changedSince')).toBe('2026-10-31T23:45:00.000Z');
            expect(batch.Records).toHaveLength(1);
            expect(batch.Records[0].ExternalID).toBe('r-1');
            expect(batch.NewWatermarkValue).toBeUndefined();
        });
    });

    describe('HTTP 429 Propagation, 5xx Single Retry, Deleted-Parent 404, & GetRecord', () => {
        it('retries transient HTTP 503 once and succeeds without touching 429 semantics', async () => {
            let calls = 0;
            fetchHandler = () => {
                calls++;
                if (calls === 1) {
                    return jsonResponse({ success: false, error: { code: 503, type: 'UNEXPECTED_ERROR', message: 'Gateway busy' } }, 503);
                }
                return jsonResponse({
                    success: true,
                    data: { data: [{ individualUuid: 'u-retry-ok', firstName: 'Recovered' }], cursor: null },
                });
            };

            const batch = await connector.FetchChanges(makeFetchCtx('Individual', { individualQueryId: 'q-1' }));
            expect(recorded).toHaveLength(2);
            expect(batch.Records).toHaveLength(1);
            expect(batch.Records[0].ExternalID).toBe('u-retry-ok');
        });

        it('throws immediately on HTTP 429 with Retry-After headers intact (no transport sleep) so ExtractRetryAfterMs sees it', async () => {
            fetchHandler = () =>
                jsonResponse(
                    { success: false, error: { code: 429, type: 'RATE_LIMITED', message: 'Too many requests' } },
                    429,
                    { 'retry-after': '17' }
                );

            let caught: unknown;
            try {
                await connector.FetchChanges(makeFetchCtx('Individual', { individualQueryId: 'q-1' }));
            } catch (err) {
                caught = err;
            }

            expect(caught).toBeInstanceOf(Error);
            expect(recorded).toHaveLength(1); // No internal retry/sleep inside MakeHTTPRequest
            expect(connector.ExtractRetryAfterMs(caught)).toBe(17000);
        });

        it('converts 404 on parent-scoped child collections to empty 200 while leaving GetRecord 404 intact', async () => {
            const childEmpty = deletedParentAsEmpty(
                'https://example.slayte.test/api/v2/event/ev-gone/session?page=0&pageSize=100',
                'GET',
                { Status: 404, Body: { success: false }, Headers: {} }
            );
            expect(childEmpty.Status).toBe(200);

            const singleGet = deletedParentAsEmpty(
                'https://example.slayte.test/api/v2/event/ev-gone',
                'GET',
                { Status: 404, Body: { success: false }, Headers: {} }
            );
            expect(singleGet.Status).toBe(404);

            fetchHandler = () =>
                jsonResponse({ success: false, error: { code: 404, type: 'NOT_FOUND', message: 'Not found' } }, 404);
            const rec = await connector.GetRecord({
                CompanyIntegration: makeCI(),
                ObjectName: 'Organization',
                ExternalID: 'missing-uuid',
                ContextUser: mockUser,
            });
            expect(rec).toBeNull();
        });

        it('executes point-lookup GetRecord for Individual with includeids=true and fields', async () => {
            fetchHandler = () =>
                jsonResponse({ success: true, data: { individualUuid: 'ind-42', firstName: 'Nadia' } });

            const rec = await connector.GetRecord({
                CompanyIntegration: makeCI({ individualFields: 'firstName,lastName' }),
                ObjectName: 'Individual',
                ExternalID: 'ind-42',
                ContextUser: mockUser,
            });

            expect(rec?.ExternalID).toBe('ind-42');
            expect(rec?.Fields.firstName).toBe('Nadia');
            expect(recorded[0].url).toBe(
                'https://example.slayte.test/api/v2/crm/individual/ind-42?includeids=true&fields=firstName%2ClastName'
            );
        });
    });

    describe('CRMQuery, DirectoryEntry, & IntrospectSchema sample-union', () => {
        it('fetches CRMQuery catalog across both ind and org entity types', async () => {
            fetchHandler = (req) =>
                jsonResponse({
                    success: true,
                    data: req.url.includes('entityType=ind')
                        ? [{ uuid: 'q-1', name: 'All Individuals', params: [] }]
                        : [{ uuid: 'q-2', name: 'All Orgs', params: [] }],
                });

            const res = await connector.FetchChanges(makeFetchCtx('CRMQuery'));
            expect(res.HasMore).toBe(false);
            expect(res.Records).toHaveLength(2);
            expect(res.Records[0].Fields.entityType).toBe('ind');
            expect(res.Records[1].Fields.entityType).toBe('org');
        });

        it('paginates DirectoryEntry across configured directories via cursor and AfterKeyValue', async () => {
            fetchHandler = (req) => {
                if (req.method === 'GET' && req.url.endsWith('/v2/directory')) {
                    return jsonResponse({ success: true, data: [{ uuid: 'dir-1', slug: 'members', entityType: 'ind' }] });
                }
                if (req.method === 'POST' && !req.url.includes('cursor=')) {
                    return jsonResponse({
                        success: true,
                        data: {
                            data: [{ entityUuid: 'e-1', tags: ['active'], entity: { displayName: 'Jane' } }],
                            cursor: 'dir-cur-2',
                        },
                    });
                }
                return jsonResponse({
                    success: true,
                    data: {
                        data: [{ entityUuid: 'e-2', tags: [], entity: { displayName: 'John' } }],
                        cursor: null,
                    },
                });
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

            const superSpy = vi.spyOn(Object.getPrototypeOf(SlayteConnector.prototype), 'IntrospectSchema');
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
});
