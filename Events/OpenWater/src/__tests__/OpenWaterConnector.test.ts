import { describe, it, expect, vi, afterEach } from 'vitest';
import type {
    RESTAuthContext,
    RESTResponse,
    PaginationType,
    CreateRecordContext,
    UpdateRecordContext,
    DeleteRecordContext,
    FetchContext,
} from '@memberjunction/integration-engine';
import type { MJIntegrationObjectEntity, MJIntegrationObjectFieldEntity } from '@memberjunction/core-entities';
import { OpenWaterConnector } from '../OpenWaterConnector.js';

/**
 * Read-only / mocked-only test connector. Overrides the auth + HTTP transport seams (so no
 * network is touched and no credential is needed) and the engine-cache accessors
 * (GetCachedObject / GetCachedFields) so FetchChanges / CRUD run against in-memory IO/IOF
 * fixtures rather than the IntegrationEngineBase cache. Captures every request's URL/method/
 * body, and answers GET requests from a per-URL-substring response map.
 */
type CapturedRequest = { url: string; method: string; headers: Record<string, string>; body?: unknown };

class MockedOpenWaterConnector extends OpenWaterConnector {
    public Requests: CapturedRequest[] = [];
    /** Matched by URL substring → response. First match wins. Default: empty 200. */
    public Responses: Array<{ match: string; response: RESTResponse }> = [];
    /** Single queued response for CRUD-path tests (takes precedence when set). */
    public NextResponse: RESTResponse | null = null;

    private objects = new Map<string, MJIntegrationObjectEntity>();
    private fieldsByObjectID = new Map<string, MJIntegrationObjectFieldEntity[]>();

    public AddObject(obj: Partial<MJIntegrationObjectEntity>, fields: Array<Partial<MJIntegrationObjectFieldEntity>>): void {
        const full = obj as MJIntegrationObjectEntity;
        this.objects.set(full.Name, full);
        this.fieldsByObjectID.set(full.ID, fields.map((f, i) => ({ Sequence: i, Status: 'Active', ...f }) as MJIntegrationObjectFieldEntity));
    }

    protected override async Authenticate(): Promise<RESTAuthContext> {
        return { Config: { ClientKey: 'ck', ApiKey: 'ak', OrganizationCode: 'org', BaseURL: 'https://api.test' }, BaseURL: 'https://api.test' } as RESTAuthContext;
    }

    protected override GetCachedObject(_integrationID: string, objectName: string): MJIntegrationObjectEntity {
        const o = this.objects.get(objectName);
        if (!o) throw new Error(`mock: object not registered: ${objectName}`);
        return o;
    }

    protected override GetCachedFields(objectID: string): MJIntegrationObjectFieldEntity[] {
        return this.fieldsByObjectID.get(objectID) ?? [];
    }

    protected override async MakeHTTPRequest(
        _auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown
    ): Promise<RESTResponse> {
        this.Requests.push({ url, method, headers, body });
        if (this.NextResponse) return this.NextResponse;
        for (const r of this.Responses) {
            if (url.includes(r.match)) return r.response;
        }
        return { Status: 200, Body: [], Headers: {} };
    }
}

/** Exposes the REAL MakeHTTPRequest (no transport override) so the abort deadline can be asserted. */
class RealTransportOpenWaterConnector extends OpenWaterConnector {
    public async PublicMakeHTTP(auth: RESTAuthContext, url: string): Promise<RESTResponse> {
        return this.MakeHTTPRequest(auth, url, 'GET', {});
    }
}

function io(fields: Partial<MJIntegrationObjectEntity>): Partial<MJIntegrationObjectEntity> {
    return { SupportsPagination: true, PaginationType: 'PageNumber', DefaultPageSize: 100, ResponseDataKey: null, ...fields };
}

function createCtx(objectName: string, attributes: Record<string, unknown>): CreateRecordContext {
    return { CompanyIntegration: { IntegrationID: 'int-1' }, ContextUser: {}, ObjectName: objectName, Attributes: attributes } as unknown as CreateRecordContext;
}
function updateCtx(objectName: string, externalID: string, attributes: Record<string, unknown>): UpdateRecordContext {
    return { CompanyIntegration: { IntegrationID: 'int-1' }, ContextUser: {}, ObjectName: objectName, ExternalID: externalID, Attributes: attributes } as unknown as UpdateRecordContext;
}
function deleteCtx(objectName: string, externalID: string): DeleteRecordContext {
    return { CompanyIntegration: { IntegrationID: 'int-1' }, ContextUser: {}, ObjectName: objectName, ExternalID: externalID } as unknown as DeleteRecordContext;
}
function fetchCtx(objectName: string, overrides: Partial<FetchContext> = {}): FetchContext {
    return {
        CompanyIntegration: { IntegrationID: 'int-1' },
        ObjectName: objectName,
        WatermarkValue: null,
        BatchSize: 10_000,
        ContextUser: {},
        ...overrides,
    } as unknown as FetchContext;
}

// ─── Smoke / identity / capability ───────────────────────────────────────

describe('OpenWaterConnector (smoke)', () => {
    const connector = new OpenWaterConnector();

    it('instantiates without throwing', () => {
        expect(connector instanceof OpenWaterConnector).toBe(true);
    });

    it('IntegrationName getter returns the canonical name (three-way invariant)', () => {
        expect(connector.IntegrationName).toBe('OpenWater');
    });

    it('declares CRUD capabilities', () => {
        expect(connector.SupportsCreate).toBe(true);
        expect(connector.SupportsUpdate).toBe(true);
        expect(connector.SupportsDelete).toBe(true);
    });

    it('exposes a conservative rate-limit policy (3 tokens/sec)', () => {
        expect(connector.RateLimitPolicy).toEqual({ TokensPerSec: 3 });
    });

    it('GetDefaultConfiguration returns the OpenWater schema name', () => {
        expect(connector.GetDefaultConfiguration().DefaultSchemaName).toBe('OpenWater');
    });
});

// ─── Auth header shape ───────────────────────────────────────────────────

describe('OpenWaterConnector — BuildHeaders (dual custom headers)', () => {
    const connector = new OpenWaterConnector();
    const buildHeaders = (auth: RESTAuthContext) =>
        (connector as unknown as { BuildHeaders(a: RESTAuthContext): Record<string, string> }).BuildHeaders(auth);

    it('injects X-ClientKey + X-ApiKey, and X-OrganizationCode when present', () => {
        const headers = buildHeaders({ Config: { ClientKey: 'CK', ApiKey: 'AK', OrganizationCode: 'ORG' }, BaseURL: 'x' } as RESTAuthContext);
        expect(headers['X-ClientKey']).toBe('CK');
        expect(headers['X-ApiKey']).toBe('AK');
        expect(headers['X-OrganizationCode']).toBe('ORG');
        expect(headers['Accept']).toBe('application/json');
    });

    it('omits X-OrganizationCode when not configured', () => {
        const headers = buildHeaders({ Config: { ClientKey: 'CK', ApiKey: 'AK' }, BaseURL: 'x' } as RESTAuthContext);
        expect(headers['X-ClientKey']).toBe('CK');
        expect('X-OrganizationCode' in headers).toBe(false);
    });
});

// ─── NormalizeResponse ───────────────────────────────────────────────────

describe('OpenWaterConnector — NormalizeResponse', () => {
    const connector = new OpenWaterConnector();
    const normalize = (body: unknown, key: string | null = null) =>
        (connector as unknown as { NormalizeResponse(b: unknown, k: string | null): Record<string, unknown>[] }).NormalizeResponse(body, key);

    it('unwraps the paged { records: [...] } envelope', () => {
        expect(normalize({ records: [{ id: 1 }, { id: 2 }], pageIndex: 0, totalRecords: 2 })).toHaveLength(2);
    });

    it('passes through a bare array', () => {
        expect(normalize([{ id: 1 }])).toHaveLength(1);
    });

    it('wraps a single object as a one-element array', () => {
        expect(normalize({ id: 7, name: 'x' })).toEqual([{ id: 7, name: 'x' }]);
    });

    it('returns empty for null/empty', () => {
        expect(normalize(null)).toEqual([]);
        expect(normalize({})).toEqual([]);
    });
});

// ─── ExtractPaginationInfo (PageNumber) ──────────────────────────────────

describe('OpenWaterConnector — ExtractPaginationInfo', () => {
    const connector = new OpenWaterConnector();
    const extract = (body: unknown, type: PaginationType, page: number, pageSize: number) =>
        (connector as unknown as {
            ExtractPaginationInfo(b: unknown, t: PaginationType, p: number, o: number, s: number): { HasMore: boolean; NextPage?: number };
        }).ExtractPaginationInfo(body, type, page, 0, pageSize);

    it('full page advances pageIndex and reports more', () => {
        const body = { records: Array.from({ length: 100 }, (_, i) => ({ id: i })) };
        const r = extract(body, 'PageNumber', 0, 100);
        expect(r.HasMore).toBe(true);
        expect(r.NextPage).toBe(1);
    });

    it('short page stops pagination', () => {
        const body = { records: [{ id: 1 }, { id: 2 }] };
        expect(extract(body, 'PageNumber', 0, 100).HasMore).toBe(false);
    });

    it('honors totalRecords when supplied', () => {
        const body = { records: Array.from({ length: 100 }, (_, i) => ({ id: i })), totalRecords: 100 };
        // page 0 fetched 100 of 100 → no more.
        expect(extract(body, 'PageNumber', 0, 100).HasMore).toBe(false);
    });
});

// ─── BuildPaginatedURL uses pageIndex/pageSize ──────────────────────────

describe('OpenWaterConnector — BuildPaginatedURL', () => {
    const connector = new OpenWaterConnector();
    const build = (obj: Partial<MJIntegrationObjectEntity>, page: number) =>
        (connector as unknown as {
            BuildPaginatedURL(p: string, o: MJIntegrationObjectEntity, pg: number, off: number, c?: string, eps?: number): string;
        }).BuildPaginatedURL('/v2/Programs', io(obj) as MJIntegrationObjectEntity, page, 0, undefined, 50);

    it('emits OpenWater pageIndex/pageSize params', () => {
        const url = build({ PaginationType: 'PageNumber' }, 2);
        expect(url).toContain('pageIndex=2');
        expect(url).toContain('pageSize=50');
    });
});

// ─── FetchChanges: flat door + incremental watermark ────────────────────

describe('OpenWaterConnector — FetchChanges (flat door + watermark)', () => {
    it('fetches a flat door, passes full record through, and tracks max watermark', async () => {
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(
            io({ ID: 'o-app', Name: 'Application', APIPath: '/v2/Applications', SupportsIncrementalSync: true, IncrementalWatermarkField: 'lastModifiedUtc' }),
            [{ Name: 'id', IsPrimaryKey: true }, { Name: 'lastModifiedUtc' }]
        );
        connector.Responses = [
            { match: '/v2/Applications', response: { Status: 200, Body: { records: [
                { id: 1, name: 'A', lastModifiedUtc: '2026-01-02T00:00:00Z', custom_x: 'keep' },
                { id: 2, name: 'B', lastModifiedUtc: '2026-03-04T00:00:00Z' },
            ] }, Headers: {} } },
        ];

        const result = await connector.FetchChanges(fetchCtx('Application'));

        expect(result.Records).toHaveLength(2);
        expect(result.Records[0].ExternalID).toBe('1');
        // Full-record pass-through: an undeclared custom field survives into Fields.
        expect(result.Records[0].Fields['custom_x']).toBe('keep');
        // Max-seen watermark, not most-recent-in-order.
        expect(result.NewWatermarkValue).toBe('2026-03-04T00:00:00Z');
    });

    it('formats the watermark into the IncrementalWatermarkField query param on subsequent sync', async () => {
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(
            io({ ID: 'o-app', Name: 'Application', APIPath: '/v2/Applications', SupportsIncrementalSync: true, IncrementalWatermarkField: 'lastModifiedSinceUtc' }),
            [{ Name: 'id', IsPrimaryKey: true }]
        );
        connector.Responses = [{ match: '/v2/Applications', response: { Status: 200, Body: { records: [] }, Headers: {} } }];

        await connector.FetchChanges(fetchCtx('Application', { WatermarkValue: '2026-05-01T00:00:00Z' }));

        const req = connector.Requests.find(r => r.url.includes('/v2/Applications'));
        expect(req?.url).toContain('lastModifiedSinceUtc=2026-05-01T00%3A00%3A00Z');
    });
});

// ─── FetchChanges: nested access-path walk ──────────────────────────────

describe('OpenWaterConnector — FetchChanges (nested access-path walk)', () => {
    it('walks a path-template parent (FundTransactions via /Funds/{fundId}/Transactions)', async () => {
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(
            io({
                ID: 'o-ft', Name: 'FundTransaction', APIPath: '/v2/Funds/{fundId}/Transactions',
                Configuration: JSON.stringify({ AccessPath: {
                    door: 'Fund', doorPath: '/v2/Funds', parentParamName: 'fundId',
                    nestingSegments: ['transactions'], entryPath: '/v2/Funds/{fundId}/Transactions',
                } }),
            }),
            [{ Name: 'id', IsPrimaryKey: true }]
        );
        connector.Responses = [
            { match: '/v2/Funds/10/Transactions', response: { Status: 200, Body: { records: [{ id: 100 }, { id: 101 }] }, Headers: {} } },
            { match: '/v2/Funds/11/Transactions', response: { Status: 200, Body: { records: [{ id: 110 }] }, Headers: {} } },
            // The door enumeration (no /Transactions in the path).
            { match: '/v2/Funds', response: { Status: 200, Body: { records: [{ id: 10 }, { id: 11 }] }, Headers: {} } },
        ];

        const result = await connector.FetchChanges(fetchCtx('FundTransaction'));

        const ids = result.Records.map(r => r.ExternalID).sort();
        expect(ids).toEqual(['100', '101', '110']);
        // The door was walked.
        expect(connector.Requests.some(r => r.url.endsWith('pageSize=100') && r.url.includes('/v2/Funds?'))).toBe(true);
    });

    it('walks a roundId-gated query-param parent (JudgeAssignments via Program->rounds[]->roundId)', async () => {
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(
            io({
                ID: 'o-ja', Name: 'JudgeAssignment', APIPath: '/v2/JudgeAssignments/AssignedToRound',
                Configuration: JSON.stringify({ AccessPath: {
                    door: 'Program', doorPath: '/v2/Programs', parentParamName: 'roundId',
                    nestingSegments: ['rounds[]'], entryPath: '/v2/JudgeAssignments/AssignedToRound', parentParamIn: 'query',
                } }),
            }),
            [{ Name: 'userId', IsPrimaryKey: true }]
        );
        connector.Responses = [
            { match: 'AssignedToRound?roundId=55', response: { Status: 200, Body: { records: [{ userId: 7 }] }, Headers: {} } },
            { match: '/v2/Programs', response: { Status: 200, Body: { records: [{ id: 1, rounds: [{ id: 55 }] }] }, Headers: {} } },
        ];

        const result = await connector.FetchChanges(fetchCtx('JudgeAssignment'));

        expect(result.Records.map(r => r.ExternalID)).toEqual(['7']);
        // roundId was injected as a query param; the endpoint is never called without it.
        const leafReq = connector.Requests.find(r => r.url.includes('AssignedToRound'));
        expect(leafReq?.url).toContain('roundId=55');
        expect(connector.Requests.some(r => r.url.includes('AssignedToRound') && !r.url.includes('roundId='))).toBe(false);
    });

    it('emits an embedded-array object straight from the door payload (Rounds via Program.rounds[])', async () => {
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(
            io({
                ID: 'o-rounds', Name: 'Rounds', APIPath: '(embedded)', SupportsPagination: false, PaginationType: 'None',
                Configuration: JSON.stringify({ AccessPath: {
                    door: 'Program', doorPath: '/v2/Programs', nestingSegments: ['rounds[]'],
                    entryPath: '(embedded)', extractionMode: 'embedded-array',
                } }),
            }),
            [{ Name: 'id', IsPrimaryKey: true }]
        );
        connector.Responses = [
            { match: '/v2/Programs', response: { Status: 200, Body: { records: [
                { id: 1, rounds: [{ id: 55, name: 'R1' }, { id: 56, name: 'R2' }] },
                { id: 2, rounds: [{ id: 57, name: 'R3' }] },
            ] }, Headers: {} } },
        ];

        const result = await connector.FetchChanges(fetchCtx('Rounds'));

        expect(result.Records.map(r => r.ExternalID).sort()).toEqual(['55', '56', '57']);
        // No second call — records came from the door payload.
        expect(connector.Requests.every(r => r.url.includes('/v2/Programs'))).toBe(true);
    });

    it('attaches a ZERO_PARENTS warning when the door has no records', async () => {
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(
            io({
                ID: 'o-ft', Name: 'FundTransaction', APIPath: '/v2/Funds/{fundId}/Transactions',
                Configuration: JSON.stringify({ AccessPath: {
                    door: 'Fund', doorPath: '/v2/Funds', parentParamName: 'fundId',
                    nestingSegments: ['transactions'], entryPath: '/v2/Funds/{fundId}/Transactions',
                } }),
            }),
            [{ Name: 'id', IsPrimaryKey: true }]
        );
        connector.Responses = [{ match: '/v2/Funds', response: { Status: 200, Body: { records: [] }, Headers: {} } }];

        const result = await connector.FetchChanges(fetchCtx('FundTransaction'));

        expect(result.Records).toHaveLength(0);
        expect(result.Warnings?.[0]?.Code).toBe('ZERO_PARENTS');
    });

    it('a 401/403 leaf is reported as LEAF_FORBIDDEN, not swallowed into a silent zero', async () => {
        // REGRESSION. This was a console.warn on the server and nothing else, so a permission-scoped
        // endpoint produced zero records behind a SUCCESSFUL run — reading as "this tenant has no
        // OtherSessionItemTypes" rather than "this token may not read them". A live full-catalog run
        // scored three objects as unexplained zeros for exactly this reason.
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(
            io({
                ID: 'o-osit', Name: 'OtherSessionItemType', APIPath: '/v2/Programs/{programId}/OtherSessionItemTypes',
                Configuration: JSON.stringify({ AccessPath: {
                    door: 'Program', doorPath: '/v2/Programs', parentParamName: 'programId',
                    entryPath: '/v2/Programs/{programId}/OtherSessionItemTypes',
                } }),
            }),
            [{ Name: 'id', IsPrimaryKey: true }]
        );
        connector.Responses = [
            { match: '/OtherSessionItemTypes', response: { Status: 403, Body: {}, Headers: {} } },
            { match: '/v2/Programs', response: { Status: 200, Body: { records: [{ id: 7 }] }, Headers: {} } },
        ];

        const result = await connector.FetchChanges(fetchCtx('OtherSessionItemType'));

        expect(result.Records).toHaveLength(0);
        const w = result.Warnings?.find(x => x.Code === 'LEAF_FORBIDDEN');
        expect(w?.Data).toMatchObject({ object: 'OtherSessionItemType', status: 403 });
        // and it must NOT also claim the collection is empty — the two causes are different diagnoses
        expect(result.Warnings?.some(x => x.Code === 'ZERO_LEAVES')).toBe(false);
    });

    it('parents walked but every leaf empty is ZERO_LEAVES, naming the parents and paths tried', async () => {
        // ZERO_PARENTS covers "nothing to walk". "Walked everything, found nothing" had no code at all,
        // which is what made it indistinguishable from a malformed request.
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(
            io({
                ID: 'o-rep', Name: 'Report', APIPath: '/v2/Rounds/{roundId}/ApplicationReports',
                Configuration: JSON.stringify({ AccessPath: {
                    door: 'Program', doorPath: '/v2/Programs', nestingSegments: ['rounds[]'],
                    parentParamName: 'roundId', entryPath: '/v2/Rounds/{roundId}/ApplicationReports',
                    alternativePaths: ['/v2/Rounds/{roundId}/JudgeReports'],
                } }),
            }),
            [{ Name: 'id', IsPrimaryKey: true }]
        );
        connector.Responses = [
            { match: '/v2/Programs', response: { Status: 200, Body: { records: [{ id: 1, rounds: [{ id: 11 }, { id: 12 }] }] }, Headers: {} } },
            { match: '/v2/Rounds/', response: { Status: 200, Body: { records: [] }, Headers: {} } },
        ];

        const result = await connector.FetchChanges(fetchCtx('Report'));

        expect(result.Records).toHaveLength(0);
        const w = result.Warnings?.find(x => x.Code === 'ZERO_LEAVES');
        expect(w?.Data).toMatchObject({ object: 'Report', parents: 2, leafRequests: 4 });   // 2 rounds x 2 paths
        expect(w?.Message).toContain('/v2/Rounds/{roundId}/JudgeReports');
    });

    it('one parent the vendor refuses does not take the whole object to zero (LEAF_REQUEST_REJECTED)', async () => {
        // REGRESSION, live. `Report` failed with "HTTP 400" on the FIRST round it walked and threw, so
        // every other round's reports were discarded and the object returned nothing at all. The request
        // shape is right (OpenWater's own swagger: GET /v2/Rounds/{roundId}/ApplicationReports, roundId
        // int32 in path, pageIndex/pageSize optional) — a 400 is the vendor refusing THAT round, not the
        // object being unfetchable. So the walk keeps going and the refusal is recorded against its parent.
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(
            io({
                ID: 'o-rep', Name: 'Report', APIPath: '/v2/Rounds/{roundId}/ApplicationReports',
                Configuration: JSON.stringify({ AccessPath: {
                    door: 'Program', doorPath: '/v2/Programs', nestingSegments: ['rounds[]'],
                    parentParamName: 'roundId', entryPath: '/v2/Rounds/{roundId}/ApplicationReports',
                } }),
            }),
            [{ Name: 'id', IsPrimaryKey: true }]
        );
        connector.Responses = [
            { match: '/v2/Rounds/11/', response: { Status: 400, Body: { message: 'Round is judging only' }, Headers: {} } },
            { match: '/v2/Rounds/12/', response: { Status: 200, Body: { records: [{ id: 900 }] }, Headers: {} } },
            { match: '/v2/Programs', response: { Status: 200, Body: { records: [{ id: 1, rounds: [{ id: 11 }, { id: 12 }] }] }, Headers: {} } },
        ];

        const result = await connector.FetchChanges(fetchCtx('Report'));

        // The good round's records survive the bad round.
        expect(result.Records.map(r => r.ExternalID)).toEqual(['900']);
        const w = result.Warnings?.find(x => x.Code === 'LEAF_REQUEST_REJECTED');
        expect(w?.Data).toMatchObject({ object: 'Report', rejected: 1, leafRequests: 2, rejectedParentIDs: ['11'] });
        expect(w?.Message).toContain('/v2/Rounds/11/ApplicationReports');
        // A partial pull is not an empty one, and must not be described as the vendor having nothing.
        expect(result.Warnings?.some(x => x.Code === 'ZERO_LEAVES')).toBe(false);
    });

    it('every request refused is still a failure, not a clean zero', async () => {
        // The non-fatal path is per-parent. When NOTHING answered, the endpoint/credential/vendor is the
        // problem, and returning zero records behind a successful run would be the untruth all over again.
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(
            io({
                ID: 'o-rep', Name: 'Report', APIPath: '/v2/Rounds/{roundId}/ApplicationReports',
                Configuration: JSON.stringify({ AccessPath: {
                    door: 'Program', doorPath: '/v2/Programs', nestingSegments: ['rounds[]'],
                    parentParamName: 'roundId', entryPath: '/v2/Rounds/{roundId}/ApplicationReports',
                } }),
            }),
            [{ Name: 'id', IsPrimaryKey: true }]
        );
        connector.Responses = [
            { match: '/v2/Rounds/', response: { Status: 400, Body: { message: 'nope' }, Headers: {} } },
            { match: '/v2/Programs', response: { Status: 200, Body: { records: [{ id: 1, rounds: [{ id: 11 }, { id: 12 }] }] }, Headers: {} } },
        ];

        await expect(connector.FetchChanges(fetchCtx('Report'))).rejects.toThrow(
            /all 2 request\(s\).*HTTP 400 at .*\/v2\/Rounds\/11\/ApplicationReports/s);
    });

    it('a 5xx in a parent walk still throws — a server fault is not parent-scoped', async () => {
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(
            io({
                ID: 'o-rep', Name: 'Report', APIPath: '/v2/Rounds/{roundId}/ApplicationReports',
                Configuration: JSON.stringify({ AccessPath: {
                    door: 'Program', doorPath: '/v2/Programs', nestingSegments: ['rounds[]'],
                    parentParamName: 'roundId', entryPath: '/v2/Rounds/{roundId}/ApplicationReports',
                } }),
            }),
            [{ Name: 'id', IsPrimaryKey: true }]
        );
        connector.Responses = [
            { match: '/v2/Rounds/11/', response: { Status: 503, Body: {}, Headers: {} } },
            { match: '/v2/Rounds/12/', response: { Status: 200, Body: { records: [{ id: 900 }] }, Headers: {} } },
            { match: '/v2/Programs', response: { Status: 200, Body: { records: [{ id: 1, rounds: [{ id: 11 }, { id: 12 }] }] }, Headers: {} } },
        ];

        await expect(connector.FetchChanges(fetchCtx('Report'))).rejects.toThrow(/HTTP 503/);
    });

    it('an alternative path templated on a DIFFERENT param is skipped, not filled with the wrong id', async () => {
        // `Report` walks roundIds but lists /v2/Programs/{programId}/SessionReports among its
        // alternatives. Substituting a roundId there is not a near-miss — it is a well-formed request
        // for the wrong record, and the vendor is right to reject it (live: HTTP 400). The skip is
        // reported so a narrowed walk is never silent.
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(
            io({
                ID: 'o-rep2', Name: 'Report', APIPath: '/v2/Rounds/{roundId}/ApplicationReports',
                Configuration: JSON.stringify({ AccessPath: {
                    door: 'Program', doorPath: '/v2/Programs', nestingSegments: ['rounds[]'],
                    parentParamName: 'roundId', entryPath: '/v2/Rounds/{roundId}/ApplicationReports',
                    alternativePaths: ['/v2/Programs/{programId}/SessionReports'],
                } }),
            }),
            [{ Name: 'id', IsPrimaryKey: true }]
        );
        connector.Responses = [
            { match: '/v2/Programs/', response: { Status: 400, Body: { message: 'must not be reached' }, Headers: {} } },
            { match: '/v2/Programs', response: { Status: 200, Body: { records: [{ id: 1, rounds: [{ id: 11 }] }] }, Headers: {} } },
            { match: '/v2/Rounds/', response: { Status: 200, Body: { records: [{ id: 7 }] }, Headers: {} } },
        ];

        const result = await connector.FetchChanges(fetchCtx('Report'));

        // The programId-templated alternative was never requested — only the door and the roundId path.
        expect(connector.Requests.filter(r => r.url.includes('SessionReports'))).toHaveLength(0);
        expect(result.Records).toHaveLength(1);
        expect(result.Warnings?.find(x => x.Code === 'PATH_SKIPPED_PARAM_MISMATCH')?.Data)
            .toMatchObject({ object: 'Report', parentParamName: 'roundId',
                             skipped: ['/v2/Programs/{programId}/SessionReports'] });
    });

    it('a flat collection that is genuinely empty says so (EMPTY_COLLECTION), rather than saying nothing', async () => {
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(
            io({ ID: 'o-fund', Name: 'Fund', APIPath: '/v2/Funds' }),
            [{ Name: 'id', IsPrimaryKey: true }]
        );
        connector.Responses = [{ match: '/v2/Funds', response: { Status: 200, Body: { records: [] }, Headers: {} } }];

        const result = await connector.FetchChanges(fetchCtx('Fund'));

        expect(result.Records).toHaveLength(0);
        expect(result.Warnings?.find(x => x.Code === 'EMPTY_COLLECTION')?.Data)
            .toMatchObject({ object: 'Fund', path: '/v2/Funds' });
    });

    it('an incremental page that comes back empty is NOT reported as an empty collection', async () => {
        // Nothing-new-since-the-watermark is the normal steady state; warning on it would train
        // everyone to ignore the warning that matters.
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(
            io({ ID: 'o-fund2', Name: 'Fund', APIPath: '/v2/Funds', IncrementalWatermarkField: 'modifiedOn' }),
            [{ Name: 'id', IsPrimaryKey: true }]
        );
        connector.Responses = [{ match: '/v2/Funds', response: { Status: 200, Body: { records: [] }, Headers: {} } }];

        const result = await connector.FetchChanges(fetchCtx('Fund', { WatermarkValue: '2026-01-01T00:00:00Z' }));

        expect(result.Records).toHaveLength(0);
        expect(result.Warnings ?? []).toHaveLength(0);
    });
});

// ─── Generic CRUD via per-operation IO columns ──────────────────────────

describe('OpenWaterConnector — generic CRUD (per-operation columns)', () => {
    const writeIO = io({
        ID: 'o-users', Name: 'User', APIPath: '/v2/Users',
        CreateAPIPath: '/v2/Users', CreateMethod: 'POST', CreateBodyShape: 'flat', CreateIDLocation: 'body',
        UpdateAPIPath: '/v2/Users/{id}', UpdateMethod: 'PATCH', UpdateBodyShape: 'flat', UpdateIDLocation: 'path',
    });

    it('CreateRecord posts a flat body to CreateAPIPath and extracts the id from the body', async () => {
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(writeIO, [{ Name: 'id', IsPrimaryKey: true }]);
        connector.NextResponse = { Status: 201, Body: { id: 9001 }, Headers: {} };

        const result = await connector.CreateRecord(createCtx('User', { email: 'a@example.com' }));

        expect(result.Success).toBe(true);
        expect(result.ExternalID).toBe('9001');
        const req = connector.Requests.at(-1)!;
        expect(req.method).toBe('POST');
        expect(req.url).toBe('https://api.test/v2/Users');
        expect(req.body).toEqual({ email: 'a@example.com' });
    });

    it('CreateRecord fails LOUDLY when a 2xx response carries no record id', async () => {
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(writeIO, [{ Name: 'id', IsPrimaryKey: true }]);
        connector.NextResponse = { Status: 201, Body: {}, Headers: {} };

        const result = await connector.CreateRecord(createCtx('User', { email: 'a@example.com' }));

        expect(result.Success).toBe(false);
        expect(result.ExternalID ?? '').toBe('');
    });

    it('UpdateRecord PATCHes the id-templated path', async () => {
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(writeIO, [{ Name: 'id', IsPrimaryKey: true }]);
        connector.NextResponse = { Status: 200, Body: {}, Headers: {} };

        const result = await connector.UpdateRecord(updateCtx('User', '42', { firstName: 'X' }));

        expect(result.Success).toBe(true);
        const req = connector.Requests.at(-1)!;
        expect(req.method).toBe('PATCH');
        expect(req.url).toBe('https://api.test/v2/Users/42');
    });

    it('DeleteRecord issues the metadata-driven verb against the id path', async () => {
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(
            io({ ID: 'o-app', Name: 'Application', APIPath: '/v2/Applications', DeleteAPIPath: '/v2/Applications/{id}', DeleteMethod: 'DELETE', DeleteIDLocation: 'path' }),
            [{ Name: 'id', IsPrimaryKey: true }]
        );
        connector.NextResponse = { Status: 204, Body: null, Headers: {} };

        const result = await connector.DeleteRecord(deleteCtx('Application', '77'));

        expect(result.Success).toBe(true);
        const req = connector.Requests.at(-1)!;
        expect(req.method).toBe('DELETE');
        expect(req.url).toBe('https://api.test/v2/Applications/77');
    });
});

// ─── Literal-create / literal-update overrides ──────────────────────────
// Session, JudgeAssignment, ScheduleTimeSlot declare CreateBodyShape='literal'; ScheduleTimeSlot
// also declares UpdateBodyShape='literal'. These tests assert the connector sends the hand-built
// body each vendor schema requires (mocked HTTP — RequiresLiveVerification covers the real round-trip).

describe('OpenWaterConnector — literal-create overrides', () => {
    it('Session create resolves typeId from typeName via the SessionType endpoint', async () => {
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(
            io({ ID: 'o-sess', Name: 'Session', APIPath: '/v2/Sessions', CreateAPIPath: '/v2/Sessions', CreateMethod: 'POST', CreateBodyShape: 'literal', CreateIDLocation: 'body' }),
            [{ Name: 'id', IsPrimaryKey: true }]
        );
        connector.Responses = [
            { match: '/v2/Programs/5/SessionTypes', response: { Status: 200, Body: { records: [{ id: 88, name: 'Oral' }, { id: 89, name: 'Poster' }] }, Headers: {} } },
            { match: '/v2/Sessions', response: { Status: 201, Body: { id: 4321 }, Headers: {} } },
        ];

        const result = await connector.CreateRecord(createCtx('Session', { programId: 5, name: 'My Session', typeName: 'poster' }));

        expect(result.Success).toBe(true);
        expect(result.ExternalID).toBe('4321');
        const post = connector.Requests.find(r => r.method === 'POST' && r.url.endsWith('/v2/Sessions'))!;
        expect(post.body).toEqual({ programId: 5, typeId: 89, name: 'My Session' });
    });

    it('Session create accepts an explicit typeId without a lookup', async () => {
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(io({ ID: 'o-sess', Name: 'Session', APIPath: '/v2/Sessions' }), [{ Name: 'id', IsPrimaryKey: true }]);
        connector.Responses = [{ match: '/v2/Sessions', response: { Status: 201, Body: { id: 1 }, Headers: {} } }];

        const result = await connector.CreateRecord(createCtx('Session', { programId: 5, name: 'S', typeId: 88 }));

        expect(result.Success).toBe(true);
        // No SessionTypes lookup was needed.
        expect(connector.Requests.some(r => r.url.includes('SessionTypes'))).toBe(false);
        const post = connector.Requests.find(r => r.url.endsWith('/v2/Sessions'))!;
        expect(post.body).toEqual({ programId: 5, typeId: 88, name: 'S' });
    });

    it('JudgeAssignment create posts {judgeUserId, roundId} and synthesizes a composite id', async () => {
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(io({ ID: 'o-ja', Name: 'JudgeAssignment', APIPath: '/v2/JudgeAssignments/AssignedToRound' }), [{ Name: 'userId', IsPrimaryKey: true }]);
        connector.NextResponse = { Status: 200, Body: {}, Headers: {} };

        const result = await connector.CreateRecord(createCtx('JudgeAssignment', { userId: 7, roundId: 55 }));

        expect(result.Success).toBe(true);
        expect(result.ExternalID).toBe('55|7');
        const req = connector.Requests.at(-1)!;
        expect(req.method).toBe('POST');
        expect(req.url).toBe('https://api.test/v2/JudgeAssignments/Round');
        expect(req.body).toEqual({ judgeUserId: 7, roundId: 55 });
    });

    it('JudgeAssignment create fails loudly without round context', async () => {
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(io({ ID: 'o-ja', Name: 'JudgeAssignment', APIPath: '/v2/JudgeAssignments/AssignedToRound' }), [{ Name: 'userId', IsPrimaryKey: true }]);
        const result = await connector.CreateRecord(createCtx('JudgeAssignment', { userId: 7 }));
        expect(result.Success).toBe(false);
    });

    it('JudgeAssignment delete sends the {roundId, judgeUserId} pair as query params', async () => {
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(io({ ID: 'o-ja', Name: 'JudgeAssignment', APIPath: '/v2/JudgeAssignments/AssignedToRound' }), [{ Name: 'userId', IsPrimaryKey: true }]);
        connector.NextResponse = { Status: 204, Body: null, Headers: {} };

        const result = await connector.DeleteRecord(deleteCtx('JudgeAssignment', '55|7'));

        expect(result.Success).toBe(true);
        const req = connector.Requests.at(-1)!;
        expect(req.method).toBe('DELETE');
        expect(req.url).toContain('roundId=55');
        expect(req.url).toContain('judgeUserId=7');
    });

    it('ScheduleTimeSlot create maps availableOnlyInDayIds -> scheduleDayIds into the program-scoped path', async () => {
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(io({ ID: 'o-ts', Name: 'ScheduleTimeSlot', APIPath: '/v2/Programs/{programId}/Scheduler/TimeSlots' }), [{ Name: 'id', IsPrimaryKey: true }]);
        connector.NextResponse = { Status: 201, Body: { id: 333 }, Headers: {} };

        const result = await connector.CreateRecord(createCtx('ScheduleTimeSlot', {
            programId: 9, name: 'Morning', code: 'AM', startTime: '08:00', endTime: '09:00', availableOnlyInDayIds: [1, 2],
        }));

        expect(result.Success).toBe(true);
        expect(result.ExternalID).toBe('333');
        const req = connector.Requests.at(-1)!;
        expect(req.url).toBe('https://api.test/v2/Programs/9/Scheduler/TimeSlots');
        expect(req.body).toEqual({ name: 'Morning', code: 'AM', startTime: '08:00', endTime: '09:00', scheduleDayIds: [1, 2] });
    });

    it('ScheduleTimeSlot update PATCHes the id-keyed path with scheduleDayIds', async () => {
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(io({ ID: 'o-ts', Name: 'ScheduleTimeSlot', APIPath: '/v2/Programs/{programId}/Scheduler/TimeSlots' }), [{ Name: 'id', IsPrimaryKey: true }]);
        connector.NextResponse = { Status: 200, Body: {}, Headers: {} };

        const result = await connector.UpdateRecord(updateCtx('ScheduleTimeSlot', '333', {
            name: 'Noon', code: 'PM', startTime: '12:00', endTime: '13:00', availableOnlyInDayIds: [3],
        }));

        expect(result.Success).toBe(true);
        const req = connector.Requests.at(-1)!;
        expect(req.method).toBe('PATCH');
        expect(req.url).toBe('https://api.test/v2/Programs/Scheduler/TimeSlots/333');
        expect(req.body).toEqual({ name: 'Noon', code: 'PM', startTime: '12:00', endTime: '13:00', scheduleDayIds: [3] });
    });
});

// ─── ExtractRetryAfterMs ─────────────────────────────────────────────────

describe('OpenWaterConnector — ExtractRetryAfterMs', () => {
    const connector = new OpenWaterConnector();

    it('parses a numeric Retry-After (seconds) into ms on a 429', () => {
        expect(connector.ExtractRetryAfterMs({ Status: 429, Headers: { 'retry-after': '5' } })).toBe(5000);
    });

    it('returns undefined for a non-throttle error', () => {
        expect(connector.ExtractRetryAfterMs({ Status: 500, Headers: {} })).toBeUndefined();
        expect(connector.ExtractRetryAfterMs(new Error('boom'))).toBeUndefined();
    });
});

// ─── Transport deadline ─────────────────────────────────────────────────

describe('OpenWaterConnector — the read deadline outlives the fetch call', () => {
    afterEach(() => vi.unstubAllGlobals());

    const authWith = (timeoutMs: number): RESTAuthContext =>
        ({ Config: { RequestTimeoutMs: timeoutMs, MaxRetries: 0 }, BaseURL: 'https://api.example.com' }) as unknown as RESTAuthContext;

    it('the signal is still armed after the response headers arrive, so a stalled BODY still aborts', async () => {
        // `fetch` resolves on HEADERS; the body is read afterwards in BuildRESTResponse. The old
        // AbortController+clearTimeout pair disarmed the deadline in a `finally` at exactly that moment,
        // so a vendor that answered with headers and then stalled mid-body hung forever regardless.
        let captured: AbortSignal | undefined;
        vi.stubGlobal('fetch', vi.fn(async (_url: string, init: RequestInit) => {
            captured = init.signal as AbortSignal;
            return {
                status: 200,
                headers: new Headers({ 'content-type': 'text/plain' }),
                text: async () => 'ok',
            } as unknown as Response;
        }));

        await new RealTransportOpenWaterConnector().PublicMakeHTTP(authWith(20), 'https://api.example.com/v2/Programs');

        expect(captured).toBeInstanceOf(AbortSignal);
        expect(captured!.aborted).toBe(false);            // not yet — the request finished in time
        await new Promise(r => setTimeout(r, 60));
        expect(captured!.aborted).toBe(true);             // still armed: a stalled body would have aborted
    });

    it('each attempt gets its own deadline rather than sharing one across retries', async () => {
        const signals: AbortSignal[] = [];
        vi.stubGlobal('fetch', vi.fn(async (_url: string, init: RequestInit) => {
            signals.push(init.signal as AbortSignal);
            return {
                status: signals.length === 1 ? 429 : 200,
                headers: new Headers({ 'content-type': 'text/plain', 'retry-after': '0' }),
                text: async () => 'ok',
            } as unknown as Response;
        }));

        const auth = { Config: { RequestTimeoutMs: 5000, MaxRetries: 1 }, BaseURL: 'https://api.example.com' } as unknown as RESTAuthContext;
        await new RealTransportOpenWaterConnector().PublicMakeHTTP(auth, 'https://api.example.com/v2/Programs');

        expect(signals).toHaveLength(2);
        expect(signals[0]).not.toBe(signals[1]);
    });
});

// ─── Detail-walk extraction modes ────────────────────────────────────────

describe('OpenWaterConnector — FetchChanges (detail-walk modes)', () => {
    /** ApplicationRoundSubmission-shaped IO: detail-embedded over /v2/Applications/{applicationId}. */
    function addRoundSubmissionIO(connector: MockedOpenWaterConnector): void {
        connector.AddObject(
            io({
                ID: 'o-ars', Name: 'ApplicationRoundSubmission', APIPath: '(embedded)',
                SupportsPagination: false, PaginationType: 'None',
                Configuration: JSON.stringify({ AccessPath: {
                    door: 'Application', doorPath: '/v2/Applications', parentParamName: 'applicationId',
                    entryPath: '/v2/Applications/{applicationId}', nestingSegments: ['roundSubmissions[]'],
                    extractionMode: 'detail-embedded',
                } }),
            }),
            [{ Name: 'applicationId', IsPrimaryKey: true }, { Name: 'roundId', IsPrimaryKey: true }]
        );
    }

    it('detail-embedded: extracts the nested array from each parent detail and tags the parent id', async () => {
        const connector = new MockedOpenWaterConnector();
        addRoundSubmissionIO(connector);
        connector.Responses = [
            { match: '/v2/Applications/101', response: { Status: 200, Body: {
                id: 101, roundSubmissions: [{ roundId: 55, status: 'Complete' }, { roundId: 56, status: 'Incomplete' }] }, Headers: {} } },
            { match: '/v2/Applications/102', response: { Status: 200, Body: {
                id: 102, roundSubmissions: [{ roundId: 55, status: 'Complete' }] }, Headers: {} } },
            { match: '/v2/Applications', response: { Status: 200, Body: { records: [{ id: 101 }, { id: 102 }] }, Headers: {} } },
        ];

        const result = await connector.FetchChanges(fetchCtx('ApplicationRoundSubmission'));

        expect(result.Records.map(r => r.ExternalID).sort()).toEqual(['101|55', '101|56', '102|55']);
        // The parent id is injected — the elements themselves never carried applicationId.
        expect(result.Records.every(r => r.Fields['applicationId'] != null)).toBe(true);
    });

    it('detail-embedded: a 404 parent detail is skipped without failing the object', async () => {
        const connector = new MockedOpenWaterConnector();
        addRoundSubmissionIO(connector);
        connector.Responses = [
            { match: '/v2/Applications/101', response: { Status: 404, Body: null, Headers: {} } },
            { match: '/v2/Applications/102', response: { Status: 200, Body: {
                id: 102, roundSubmissions: [{ roundId: 57 }] }, Headers: {} } },
            { match: '/v2/Applications', response: { Status: 200, Body: { records: [{ id: 101 }, { id: 102 }] }, Headers: {} } },
        ];

        const result = await connector.FetchChanges(fetchCtx('ApplicationRoundSubmission'));

        expect(result.Records.map(r => r.ExternalID)).toEqual(['102|57']);
    });

    it('detail-embedded + elementFilter(exists): keeps only elements carrying the key (ApplicationFile)', async () => {
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(
            io({
                ID: 'o-af', Name: 'ApplicationFile', APIPath: '(embedded)',
                SupportsPagination: false, PaginationType: 'None',
                Configuration: JSON.stringify({ AccessPath: {
                    door: 'Application', doorPath: '/v2/Applications', parentParamName: 'applicationId',
                    entryPath: '/v2/Applications/{applicationId}',
                    nestingSegments: ['roundSubmissions[]', 'fieldValues[]'],
                    elementFilter: { key: 'mediaId', exists: true },
                    extractionMode: 'detail-embedded',
                } }),
            }),
            [{ Name: 'mediaId', IsPrimaryKey: true }]
        );
        connector.Responses = [
            { match: '/v2/Applications/101', response: { Status: 200, Body: { id: 101, roundSubmissions: [
                { roundId: 55, fieldValues: [
                    { alias: 'essay', value: 'plain text' },                    // no mediaId → filtered
                    { alias: 'headshot', mediaId: 9001, caption: 'portrait' },
                    { alias: 'deck', mediaId: 9002 },
                ] },
            ] }, Headers: {} } },
            { match: '/v2/Applications', response: { Status: 200, Body: { records: [{ id: 101 }] }, Headers: {} } },
        ];

        const result = await connector.FetchChanges(fetchCtx('ApplicationFile'));

        expect(result.Records.map(r => r.ExternalID).sort()).toEqual(['9001', '9002']);
    });

    it('detail-object via detail-harvest: harvested ids are deduped and each detail IS the record (Media)', async () => {
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(
            io({
                ID: 'o-media', Name: 'Media', APIPath: '/v2/Media/{mediaId}',
                SupportsPagination: false, PaginationType: 'None',
                Configuration: JSON.stringify({ AccessPath: {
                    door: 'Application', doorPath: '/v2/Applications',
                    parentSource: 'detail-harvest',
                    harvestDetailPath: '/v2/Applications/{applicationId}', harvestDetailParam: 'applicationId',
                    harvestSegments: ['roundSubmissions[]', 'fieldValues[]'], harvestIdKey: 'mediaId',
                    entryPath: '/v2/Media/{mediaId}', parentParamName: 'mediaId',
                    extractionMode: 'detail-object',
                } }),
            }),
            [{ Name: 'mediaId', IsPrimaryKey: true }]
        );
        connector.Responses = [
            // 9001 appears under BOTH applications: harvested once, fetched once.
            { match: '/v2/Applications/101', response: { Status: 200, Body: { id: 101, roundSubmissions: [
                { fieldValues: [{ mediaId: 9001 }] }] }, Headers: {} } },
            { match: '/v2/Applications/102', response: { Status: 200, Body: { id: 102, roundSubmissions: [
                { fieldValues: [{ mediaId: 9001 }, { mediaId: 9002 }] }] }, Headers: {} } },
            { match: '/v2/Media/9001', response: { Status: 200, Body: { url: 'https://cdn.test/a.pdf', fileName: 'a.pdf' }, Headers: {} } },
            { match: '/v2/Media/9002', response: { Status: 200, Body: { url: 'https://cdn.test/b.png', fileName: 'b.png' }, Headers: {} } },
            { match: '/v2/Applications', response: { Status: 200, Body: { records: [{ id: 101 }, { id: 102 }] }, Headers: {} } },
        ];

        const result = await connector.FetchChanges(fetchCtx('Media'));

        expect(result.Records.map(r => r.ExternalID).sort()).toEqual(['9001', '9002']);
        // The detail body carried no mediaId — it was tagged from the walked id.
        expect(result.Records.map(r => r.Fields['mediaId']).sort()).toEqual(['9001', '9002']);
        expect(connector.Requests.filter(r => r.url.includes('/v2/Media/9001'))).toHaveLength(1);
    });

    it('the detail cache collapses sibling walks over the same parent details', async () => {
        const connector = new MockedOpenWaterConnector();
        addRoundSubmissionIO(connector);
        connector.Responses = [
            { match: '/v2/Applications/101', response: { Status: 200, Body: {
                id: 101, roundSubmissions: [{ roundId: 55 }] }, Headers: {} } },
            { match: '/v2/Applications', response: { Status: 200, Body: { records: [{ id: 101 }] }, Headers: {} } },
        ];

        await connector.FetchChanges(fetchCtx('ApplicationRoundSubmission'));
        await connector.FetchChanges(fetchCtx('ApplicationRoundSubmission'));

        // Two full walks, ONE detail request: the second walk was served from the cache.
        expect(connector.Requests.filter(r => r.url.includes('/v2/Applications/101'))).toHaveLength(1);
    });

    it('embedded-array descends two nested array levels (ApplicationWinnerType via rounds[].winnerTypes[])', async () => {
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(
            io({
                ID: 'o-awt', Name: 'ApplicationWinnerType', APIPath: '(embedded)',
                SupportsPagination: false, PaginationType: 'None',
                Configuration: JSON.stringify({ AccessPath: {
                    door: 'Program', doorPath: '/v2/Programs',
                    nestingSegments: ['rounds[]', 'winnerTypes[]'], extractionMode: 'embedded-array',
                } }),
            }),
            [{ Name: 'id', IsPrimaryKey: true }]
        );
        connector.Responses = [
            { match: '/v2/Programs', response: { Status: 200, Body: { records: [
                { id: 1, rounds: [{ id: 55, winnerTypes: [{ id: 7, name: 'Gold' }, { id: 8, name: 'Silver' }] }] },
                { id: 2, rounds: [{ id: 56, winnerTypes: [{ id: 9, name: 'Honorable Mention' }] }] },
            ] }, Headers: {} } },
        ];

        const result = await connector.FetchChanges(fetchCtx('ApplicationWinnerType'));

        expect(result.Records.map(r => r.ExternalID).sort()).toEqual(['7', '8', '9']);
    });
});

// ─── Multi-door union walk (Judge) + pair-grain keys ─────────────────────

describe('OpenWaterConnector — FetchChanges (alternativeAccessPaths union)', () => {
    it('unions the round walk with embedded team rosters, deduplicating by primary key', async () => {
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(
            io({
                ID: 'o-judge', Name: 'Judge', APIPath: '/v2/JudgeAssignments/AssignedToRound',
                SupportsPagination: false, PaginationType: 'None',
                Configuration: JSON.stringify({
                    AccessPath: {
                        door: 'Program', doorPath: '/v2/Programs', nestingSegments: ['rounds[]'],
                        parentParamName: 'roundId', entryPath: '/v2/JudgeAssignments/AssignedToRound',
                        parentParamIn: 'query',
                    },
                    alternativeAccessPaths: [
                        { door: 'JudgeTeam', doorPath: '/v2/JudgeTeams', nestingSegments: ['judges[]'], extractionMode: 'embedded-array' },
                        { door: 'JudgeTeam', doorPath: '/v2/JudgeTeams', nestingSegments: ['managers[]'], extractionMode: 'embedded-array' },
                    ],
                }),
            }),
            [{ Name: 'userId', IsPrimaryKey: true }]
        );
        connector.Responses = [
            // Round walk: judges 7 and 8 assigned to round 55.
            { match: 'AssignedToRound?roundId=55', response: { Status: 200, Body: { records: [
                { userId: 7, firstName: 'A' }, { userId: 8, firstName: 'B' }] }, Headers: {} } },
            { match: '/v2/Programs', response: { Status: 200, Body: { records: [{ id: 1, rounds: [{ id: 55 }] }] }, Headers: {} } },
            // Team rosters: judge 8 again (dupe), judge 9 team-only, manager 10.
            { match: '/v2/JudgeTeams', response: { Status: 200, Body: { records: [
                { id: 300, judges: [{ userId: 8, firstName: 'B' }, { userId: 9, firstName: 'C' }],
                  managers: [{ userId: 10, firstName: 'D' }] }] }, Headers: {} } },
        ];

        const result = await connector.FetchChanges(fetchCtx('Judge'));

        expect(result.Records.map(r => r.ExternalID).sort()).toEqual(['10', '7', '8', '9']);
        // The round-sourced row carries its walk tag; the first occurrence of 8 (round walk) wins.
        const eight = result.Records.find(r => r.ExternalID === '8');
        expect(eight?.Fields['roundId']).toBe('55');
    });

    it('a pair-grain key keeps one row per (round, judge) instead of collapsing per person', async () => {
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(
            io({
                ID: 'o-ja2', Name: 'JudgeAssignment', APIPath: '/v2/JudgeAssignments/AssignedToRound',
                Configuration: JSON.stringify({ AccessPath: {
                    door: 'Program', doorPath: '/v2/Programs', parentParamName: 'roundId',
                    nestingSegments: ['rounds[]'], entryPath: '/v2/JudgeAssignments/AssignedToRound', parentParamIn: 'query',
                } }),
            }),
            [{ Name: 'userId', IsPrimaryKey: true }, { Name: 'roundId', IsPrimaryKey: true }]
        );
        connector.Responses = [
            // The same judge is assigned to BOTH rounds.
            { match: 'AssignedToRound?roundId=55', response: { Status: 200, Body: { records: [{ userId: 7 }] }, Headers: {} } },
            { match: 'AssignedToRound?roundId=56', response: { Status: 200, Body: { records: [{ userId: 7 }] }, Headers: {} } },
            { match: '/v2/Programs', response: { Status: 200, Body: { records: [{ id: 1, rounds: [{ id: 55 }, { id: 56 }] }] }, Headers: {} } },
        ];

        const result = await connector.FetchChanges(fetchCtx('JudgeAssignment'));

        expect(result.Records.map(r => r.ExternalID).sort()).toEqual(['7|55', '7|56']);
    });
});

// ─── Bounded, resumable detail walks (the sampling-cost defect) ──────────

describe('OpenWaterConnector — a detail walk is bounded by the caller\'s batch size', () => {
    /** Four applications, each detail carrying one round submission. */
    function fourApplications(connector: MockedOpenWaterConnector): void {
        connector.AddObject(
            io({
                ID: 'o-ars2', Name: 'ApplicationRoundSubmission', APIPath: '(embedded)',
                SupportsPagination: false, PaginationType: 'None',
                Configuration: JSON.stringify({ AccessPath: {
                    door: 'Application', doorPath: '/v2/Applications', parentParamName: 'applicationId',
                    entryPath: '/v2/Applications/{applicationId}', nestingSegments: ['roundSubmissions[]'],
                    extractionMode: 'detail-embedded',
                } }),
            }),
            [{ Name: 'applicationId', IsPrimaryKey: true }, { Name: 'roundId', IsPrimaryKey: true }]
        );
        connector.Responses = [
            ...['101', '102', '103', '104'].map(id => ({
                match: `/v2/Applications/${id}`,
                response: { Status: 200, Body: { id, roundSubmissions: [{ roundId: 55 }] }, Headers: {} },
            })),
            { match: '/v2/Applications', response: { Status: 200, Body: { records: [
                { id: 101 }, { id: 102 }, { id: 103 }, { id: 104 }] }, Headers: {} } },
        ];
    }

    it('a small batch stops early instead of walking every parent — this is what makes SAMPLING cheap', async () => {
        // The defect: the walk ran to completion inside one FetchChanges call, so
        // DiscoverFieldsViaFetch (which can only stop BETWEEN batches) paid ~2,000 detail calls
        // to infer fields for one object, blowing the discovery time budget.
        const connector = new MockedOpenWaterConnector();
        fourApplications(connector);

        const result = await connector.FetchChanges(fetchCtx('ApplicationRoundSubmission', { BatchSize: 2 }));

        expect(result.Records).toHaveLength(2);
        expect(result.HasMore).toBe(true);
        expect(result.NextCursor).toBe('detail:2');
        // Only the parents needed for this batch were fetched — 103/104 were never touched.
        expect(connector.Requests.some(r => r.url.includes('/v2/Applications/103'))).toBe(false);
    });

    it('resuming from the cursor continues at the offset and reports completion', async () => {
        const connector = new MockedOpenWaterConnector();
        fourApplications(connector);

        const result = await connector.FetchChanges(fetchCtx('ApplicationRoundSubmission', { BatchSize: 2, CurrentCursor: 'detail:2' }));

        expect(result.Records.map(r => r.ExternalID)).toEqual(['103|55', '104|55']);
        expect(result.HasMore).toBe(false);
        expect(result.NextCursor).toBeUndefined();
        // The already-consumed parents are not re-fetched on the resume.
        expect(connector.Requests.some(r => r.url.includes('/v2/Applications/101'))).toBe(false);
    });

    it('a large batch still walks everything in one call — real syncs are unchanged', async () => {
        const connector = new MockedOpenWaterConnector();
        fourApplications(connector);

        const result = await connector.FetchChanges(fetchCtx('ApplicationRoundSubmission'));

        expect(result.Records).toHaveLength(4);
        expect(result.HasMore).toBe(false);
    });

    it('the harvest stops collecting ids once the batch is covered (Media: one call per door row)', async () => {
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(
            io({
                ID: 'o-media2', Name: 'Media', APIPath: '/v2/Media/{mediaId}',
                SupportsPagination: false, PaginationType: 'None',
                Configuration: JSON.stringify({ AccessPath: {
                    door: 'Application', doorPath: '/v2/Applications',
                    parentSource: 'detail-harvest',
                    harvestDetailPath: '/v2/Applications/{applicationId}', harvestDetailParam: 'applicationId',
                    harvestSegments: ['roundSubmissions[]', 'fieldValues[]'], harvestIdKey: 'mediaId',
                    entryPath: '/v2/Media/{mediaId}', parentParamName: 'mediaId',
                    extractionMode: 'detail-object',
                } }),
            }),
            [{ Name: 'mediaId', IsPrimaryKey: true }]
        );
        connector.Responses = [
            ...['201', '202', '203', '204'].map((id, i) => ({
                match: `/v2/Applications/${id}`,
                response: { Status: 200, Body: { id, roundSubmissions: [{ fieldValues: [{ mediaId: 9000 + i }] }] }, Headers: {} },
            })),
            ...[0, 1, 2, 3].map(i => ({
                match: `/v2/Media/${9000 + i}`,
                response: { Status: 200, Body: { url: `https://cdn.test/${i}`, fileName: `f${i}` }, Headers: {} },
            })),
            { match: '/v2/Applications', response: { Status: 200, Body: { records: [
                { id: 201 }, { id: 202 }, { id: 203 }, { id: 204 }] }, Headers: {} } },
        ];

        const result = await connector.FetchChanges(fetchCtx('Media', { BatchSize: 1 }));

        expect(result.Records).toHaveLength(1);
        expect(result.HasMore).toBe(true);
        // Harvesting stopped as soon as it had enough ids: the later applications were untouched.
        expect(connector.Requests.some(r => r.url.includes('/v2/Applications/204'))).toBe(false);
    });
});

describe('OpenWaterConnector — a truncated harvest must not look finished', () => {
    it('walks EVERY media across resumable batches (the prefix-length trap)', async () => {
        // Bounding the harvest makes parentIDs a PREFIX of the real parent set, so reading its
        // length as the total reported HasMore:false with door rows still un-harvested — which
        // would have silently dropped every later record. Drive the whole object through
        // batch-sized calls and assert nothing is lost.
        const connector = new MockedOpenWaterConnector();
        connector.AddObject(
            io({
                ID: 'o-media3', Name: 'Media', APIPath: '/v2/Media/{mediaId}',
                SupportsPagination: false, PaginationType: 'None',
                Configuration: JSON.stringify({ AccessPath: {
                    door: 'Application', doorPath: '/v2/Applications',
                    parentSource: 'detail-harvest',
                    harvestDetailPath: '/v2/Applications/{applicationId}', harvestDetailParam: 'applicationId',
                    harvestSegments: ['roundSubmissions[]', 'fieldValues[]'], harvestIdKey: 'mediaId',
                    entryPath: '/v2/Media/{mediaId}', parentParamName: 'mediaId',
                    extractionMode: 'detail-object',
                } }),
            }),
            [{ Name: 'mediaId', IsPrimaryKey: true }]
        );
        const appIDs = ['301', '302', '303', '304', '305'];
        connector.Responses = [
            ...appIDs.map((id, i) => ({
                match: `/v2/Applications/${id}`,
                response: { Status: 200, Body: { id, roundSubmissions: [{ fieldValues: [{ mediaId: 8000 + i }] }] }, Headers: {} },
            })),
            ...appIDs.map((_, i) => ({
                match: `/v2/Media/${8000 + i}`,
                response: { Status: 200, Body: { url: `https://cdn.test/${i}`, fileName: `f${i}` }, Headers: {} },
            })),
            { match: '/v2/Applications', response: { Status: 200, Body: { records: appIDs.map(id => ({ id })) }, Headers: {} } },
        ];

        const seen: string[] = [];
        let cursor: string | undefined;
        for (let call = 0; call < 10; call++) {
            const r = await connector.FetchChanges(fetchCtx('Media', { BatchSize: 2, CurrentCursor: cursor }));
            seen.push(...r.Records.map(x => x.ExternalID));
            if (!r.HasMore) break;
            cursor = r.NextCursor;
            expect(cursor).toBeTruthy();
        }

        expect(seen.sort()).toEqual(['8000', '8001', '8002', '8003', '8004']);
    });
});
