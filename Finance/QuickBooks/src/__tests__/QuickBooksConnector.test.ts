import { describe, it, expect } from 'vitest';
import type {
    RESTAuthContext,
    RESTResponse,
    PaginationType,
    FetchContext,
    UpdateRecordContext,
    DeleteRecordContext,
    GetRecordContext,
} from '@memberjunction/integration-engine';
import type {
    MJCompanyIntegrationEntity,
    MJIntegrationObjectEntity,
    MJIntegrationObjectFieldEntity,
} from '@memberjunction/core-entities';
import { QuickBooksConnector } from '../QuickBooksConnector.js';

// ─── Fixtures (credential-free, read-only, PII-scrubbed) ───────────────────
// Payloads are shaped after the documented QuickBooks Online Accounting API v3 response envelopes:
//   - a /query response nests records under `QueryResponse.<Entity>` with startPosition/maxResults/totalCount;
//   - a single GET / create response nests one object under `<Entity>`;
//   - the CDC door returns `CDCResponse[].QueryResponse[].<Entity>[]` with a per-row `status`;
//   - errors use the Fault envelope `{ fault: { error: [{ message, detail, code }] } }` (lowercased JSON keys);
//   - the watermark is `MetaData.LastUpdatedTime` (ISO-8601).
// Provenance: envelope shapes trace to Intuit's public Accounting API v3 reference + OpenAPI captured during
// extraction; all ids/names/amounts are synthetic scrubbed values (no PII, no real vendor/tenant data).
// Every test drives the REAL connector logic above a mocked transport + mocked Authenticate — nothing hits a
// live endpoint, nothing mutates data.

const invoicePage1 = {
    QueryResponse: {
        Invoice: [
            { Id: '1', SyncToken: '0', TotalAmt: 100.0, CustomerRef: { value: '55', name: '<scrubbed-customer-1>' }, MetaData: { CreateTime: '2026-01-01T08:00:00-08:00', LastUpdatedTime: '2026-01-02T09:00:00-08:00' } },
            { Id: '2', SyncToken: '1', TotalAmt: 250.5, CustomerRef: { value: '56', name: '<scrubbed-customer-2>' }, MetaData: { CreateTime: '2026-01-01T08:00:00-08:00', LastUpdatedTime: '2026-01-03T10:00:00-08:00' } },
        ],
        startPosition: 1,
        maxResults: 2,
        totalCount: 5,
    },
    time: '2026-01-10T00:00:00.000-08:00',
};

const cdcDeletions = {
    CDCResponse: [
        {
            QueryResponse: [
                {
                    Invoice: [
                        { Id: '9', status: 'Deleted', MetaData: { LastUpdatedTime: '2026-01-04T11:00:00-08:00' } },
                    ],
                },
            ],
        },
    ],
    time: '2026-01-10T00:00:00.000-08:00',
};

const invoiceGetOne = { Invoice: { Id: 'inv1', SyncToken: '3', TotalAmt: 42.0 }, time: '2026-01-10T00:00:00.000-08:00' };
const invoiceUpdated = { Invoice: { Id: 'inv1', SyncToken: '4', TotalAmt: 99.0 }, time: '2026-01-10T00:00:00.000-08:00' };
const customerGetOne = { Customer: { Id: 'cust1', SyncToken: '2', Active: true, DisplayName: '<scrubbed>' }, time: '2026-01-10T00:00:00.000-08:00' };
const customerDeactivated = { Customer: { Id: 'cust1', SyncToken: '3', Active: false }, time: '2026-01-10T00:00:00.000-08:00' };
const companyInfoOk = { CompanyInfo: { Id: '1', CompanyName: '<scrubbed-company>' }, time: '2026-01-10T00:00:00.000-08:00' };
const staleTokenFault = { fault: { type: 'ValidationFault', error: [{ message: 'Stale Object Error', detail: 'Object version does not match. 5010', code: '5010', element: 'SyncToken' }] }, time: '2026-01-10T00:00:00.000-08:00' };
const authFault = { fault: { type: 'AUTHENTICATION', error: [{ message: 'AuthenticationFailed', detail: 'Token invalid', code: '3200' }] }, time: '2026-01-10T00:00:00.000-08:00' };

// ─── Captured outbound request (assert the exact wire shape) ───────────────

interface CapturedRequest {
    url: string;
    method: string;
    headers: Record<string, string>;
    body: unknown;
}

const AUTH_BASE = 'https://sandbox-quickbooks.api.intuit.com/v3/company/REALM123';

function makeIO(over: Partial<MJIntegrationObjectEntity> & { ID: string; Name: string }): MJIntegrationObjectEntity {
    return {
        DisplayName: over.Name,
        Description: 'fixture',
        SupportsIncrementalSync: false,
        IncrementalWatermarkField: null,
        SupportsUpdate: false,
        UpdateAPIPath: null,
        SupportsDelete: false,
        Configuration: null,
        Status: 'Active',
        ...over,
    } as unknown as MJIntegrationObjectEntity;
}

function makeIOF(over: Partial<MJIntegrationObjectFieldEntity> & { Name: string }): MJIntegrationObjectFieldEntity {
    return {
        Type: 'string',
        IsPrimaryKey: false,
        IsRequired: false,
        IsReadOnly: false,
        IsUniqueKey: false,
        Sequence: 0,
        Status: 'Active',
        ...over,
    } as unknown as MJIntegrationObjectFieldEntity;
}

const idPK = [makeIOF({ Name: 'Id', IsPrimaryKey: true, IsRequired: true, IsReadOnly: true, IsUniqueKey: true })];

const invoiceConfig = JSON.stringify({ QueryEntity: 'Invoice', entityClass: 'transaction', cdcEligible: true, pagination: { skipParamBase: 1 } });
const customerConfig = JSON.stringify({ QueryEntity: 'Customer', entityClass: 'namelist', cdcEligible: true, pagination: { skipParamBase: 1 } });
const companyInfoConfig = JSON.stringify({ QueryEntity: 'CompanyInfo', entityClass: 'read-only', cdcEligible: false });
const recurringConfig = JSON.stringify({ QueryEntity: 'RecurringTransaction', entityClass: 'transaction', cdcEligible: false });

/**
 * Test subclass — the canonical Mocked<Connector> pattern. Overrides ONLY the transport boundary
 * (MakeHTTPRequest), the OAuth boundary (Authenticate), and the engine-cache accessors
 * (GetCachedObject / GetCachedFields) with fixture rows. The REAL query-building, envelope-stripping,
 * pagination, incremental watermark, CDC parsing, record-shaping, and CRUD-routing logic runs.
 */
class MockedQuickBooksConnector extends QuickBooksConnector {
    public Captured: CapturedRequest[] = [];
    public Responses: RESTResponse[] = [];
    public IOFixtures = new Map<string, MJIntegrationObjectEntity>();
    public IOFFixtures = new Map<string, MJIntegrationObjectFieldEntity[]>();

    protected override async MakeHTTPRequest(
        _auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown,
    ): Promise<RESTResponse> {
        this.Captured.push({ url, method, headers, body });
        const next = this.Responses.shift();
        if (!next) throw new Error(`MockedQuickBooksConnector: no canned response queued for ${method} ${url}`);
        return next;
    }

    // Bypass the real OAuth round-trip; return a fixed sandbox auth context.
    protected override async Authenticate(): Promise<RESTAuthContext & { Token: string; RealmId: string; CompanyBaseURL: string }> {
        return { Token: 'access-token-xyz', RealmId: 'REALM123', CompanyBaseURL: AUTH_BASE, ExpiresAt: new Date(Date.now() + 3_600_000) };
    }

    protected override GetCachedObject(_integrationID: string, objectName: string): MJIntegrationObjectEntity {
        const io = this.IOFixtures.get(objectName);
        if (!io) throw new Error(`test IO fixture missing: ${objectName}`);
        return io;
    }
    protected override GetCachedFields(objectID: string): MJIntegrationObjectFieldEntity[] {
        return this.IOFFixtures.get(objectID) ?? [];
    }

    public queue(...responses: RESTResponse[]): void { this.Responses.push(...responses); }
    public registerIO(io: MJIntegrationObjectEntity, fields: MJIntegrationObjectFieldEntity[]): void {
        this.IOFixtures.set(io.Name, io);
        this.IOFFixtures.set(io.ID, fields);
    }

    // ── Expose protected/private seams for direct unit assertions ──
    public PublicNormalize(body: unknown, key: string | null): Record<string, unknown>[] {
        return this.NormalizeResponse(body, key);
    }
    public PublicExtractPagination(body: unknown, type: PaginationType, offset = 0, pageSize = 200) {
        return this.ExtractPaginationInfo(body, type, 1, offset, pageSize);
    }
    public PublicExtractError(response: RESTResponse): string | undefined {
        return this.ExtractErrorMessage(response);
    }
    public PublicHeaders(): Record<string, string> {
        return this.BuildHeaders({ Token: 'access-token-xyz' } as RESTAuthContext);
    }
    public PublicBuildQuery(entity: string, wm: string | null, wmField: string | null, start: number, max: number): string {
        return (this as unknown as {
            buildQueryText(e: string, w: string | null, f: string | null, s: number, m: number): string;
        }).buildQueryText(entity, wm, wmField, start, max);
    }
    public PublicParseCdc(body: unknown, entity: string, objectType: string) {
        return (this as unknown as {
            parseCdcDeletions(b: unknown, e: string, o: string): unknown[];
        }).parseCdcDeletions(body, entity, objectType);
    }
}

const user = {} as never;

function ok(body: unknown, status = 200): RESTResponse {
    return { Status: status, Body: body, Headers: {} };
}

function makeCI(): MJCompanyIntegrationEntity {
    return { IntegrationID: 'int-qb', ExternalSystemID: 'REALM123', CredentialID: null } as unknown as MJCompanyIntegrationEntity;
}

function fetchCtx(objectName: string, over?: Partial<FetchContext>): FetchContext {
    return {
        CompanyIntegration: makeCI(),
        ObjectName: objectName,
        WatermarkValue: null,
        BatchSize: 200,
        ContextUser: user,
        ...over,
    };
}

function invoiceIO(): MJIntegrationObjectEntity {
    return makeIO({
        ID: 'io-invoice', Name: 'Invoice', Configuration: invoiceConfig,
        SupportsIncrementalSync: true, IncrementalWatermarkField: 'MetaData.LastUpdatedTime',
        SupportsUpdate: true, UpdateAPIPath: '/invoice', SupportsDelete: true,
    });
}
function customerIO(): MJIntegrationObjectEntity {
    return makeIO({
        ID: 'io-customer', Name: 'Customer', Configuration: customerConfig,
        SupportsIncrementalSync: true, IncrementalWatermarkField: 'MetaData.LastUpdatedTime',
        SupportsUpdate: true, UpdateAPIPath: '/customer', SupportsDelete: false,
    });
}

function decodeQuery(url: string): string {
    const m = url.match(/[?&]query=([^&]+)/);
    return m ? decodeURIComponent(m[1]) : '';
}

// ═══════════════════════════════════════════════════════════════════════════

describe('QuickBooksConnector — identity + capabilities', () => {
    it('IntegrationName is the verbatim MJ: Integrations.Name (QuickBooks)', () => {
        expect(new QuickBooksConnector().IntegrationName).toBe('QuickBooks');
    });

    it('declares Create/Update/Delete capabilities and non-authoritative discovery', () => {
        const c = new QuickBooksConnector();
        expect(c.SupportsCreate).toBe(true);
        expect(c.SupportsUpdate).toBe(true);
        expect(c.SupportsDelete).toBe(true);
        expect(c.DiscoveryIsAuthoritative).toBe(false);
    });

    it('exposes the evidenced QBO rate policy (500/min → ~8.33/s) + 10-concurrent cap from documented fallbacks', () => {
        const c = new QuickBooksConnector();
        expect(c.MaxConcurrencyHint).toBe(10);
        const policy = c.RateLimitPolicy;
        expect(policy).not.toBeNull();
        expect(policy?.TokensPerSec).toBeCloseTo(500 / 60, 5);
        expect(policy?.Burst).toBe(10);
        // A plain error carries no Retry-After (only an exhausted-429 transport error does).
        expect(c.ExtractRetryAfterMs(new Error('x'))).toBeUndefined();
    });
});

describe('QuickBooksConnector — headers', () => {
    it('sends Bearer auth + JSON Accept (QBO defaults to XML without an explicit Accept)', () => {
        const headers = new MockedQuickBooksConnector().PublicHeaders();
        expect(headers['Authorization']).toBe('Bearer access-token-xyz');
        expect(headers['Accept']).toBe('application/json');
        expect(headers['Content-Type']).toBe('application/json');
    });
});

describe('QuickBooksConnector — NormalizeResponse (QueryResponse envelope)', () => {
    const c = new MockedQuickBooksConnector();

    it('strips QueryResponse.<Entity> to the record array', () => {
        const recs = c.PublicNormalize(invoicePage1, 'Invoice');
        expect(recs).toHaveLength(2);
        expect(recs[0].Id).toBe('1');
    });

    it('returns an empty QueryResponse (no matching entity array) as []', () => {
        expect(c.PublicNormalize({ QueryResponse: { startPosition: 1 }, time: 't' }, 'Invoice')).toEqual([]);
    });

    it('returns a single-entity body (no QueryResponse) as a one-element array', () => {
        expect(c.PublicNormalize(invoiceGetOne, 'Invoice')).toEqual([invoiceGetOne.Invoice]);
    });

    it('returns [] for null/non-object bodies', () => {
        expect(c.PublicNormalize(null, 'Invoice')).toEqual([]);
        expect(c.PublicNormalize('oops', 'Invoice')).toEqual([]);
    });
});

describe('QuickBooksConnector — ExtractPaginationInfo (offset via totalCount)', () => {
    const c = new MockedQuickBooksConnector();

    it('HasMore=true with NextOffset when fetched count has not reached totalCount', () => {
        const p = c.PublicExtractPagination(invoicePage1, 'Offset', 0, 2);
        expect(p.HasMore).toBe(true);
        expect(p.NextOffset).toBe(2);
        expect(p.TotalRecords).toBe(5);
    });

    it('HasMore=false when the running offset reaches totalCount', () => {
        const lastPage = { QueryResponse: { Invoice: [{ Id: '5' }], totalCount: 5 }, time: 't' };
        const p = c.PublicExtractPagination(lastPage, 'Offset', 4, 2);
        expect(p.HasMore).toBe(false);
        expect(p.NextOffset).toBeUndefined();
    });

    it('non-offset pagination reports no more', () => {
        expect(c.PublicExtractPagination(invoicePage1, 'None', 0, 2).HasMore).toBe(false);
    });
});

describe('QuickBooksConnector — ExtractErrorMessage (Fault envelope, lowercase JSON keys)', () => {
    const c = new MockedQuickBooksConnector();

    it('renders fault.error[] entries with code + message + detail', () => {
        const msg = c.PublicExtractError(ok(staleTokenFault, 400));
        expect(msg).toContain('5010');
        expect(msg).toContain('Stale Object Error');
    });

    it('returns undefined when there is no fault', () => {
        expect(c.PublicExtractError(ok(invoiceGetOne))).toBeUndefined();
    });
});

describe('QuickBooksConnector — buildQueryText (STARTPOSITION/MAXRESULTS + watermark in-query)', () => {
    const c = new MockedQuickBooksConnector();

    it('emits pagination tokens only for a full (non-incremental) scan', () => {
        const q = c.PublicBuildQuery('Invoice', null, null, 1, 200);
        expect(q).toBe('select * from Invoice startposition 1 maxresults 200');
    });

    it('emits WHERE + ORDERBY on the watermark field for an incremental scan', () => {
        const q = c.PublicBuildQuery('Invoice', '2026-01-01T00:00:00-08:00', 'MetaData.LastUpdatedTime', 1, 200);
        expect(q).toContain("where MetaData.LastUpdatedTime > '2026-01-01T00:00:00-08:00'");
        expect(q).toContain('orderby MetaData.LastUpdatedTime');
        expect(q).toContain('startposition 1 maxresults 200');
    });

    it('escapes single quotes in the watermark literal (injection-safe)', () => {
        const q = c.PublicBuildQuery('Invoice', "2026-01-01'; drop", 'MetaData.LastUpdatedTime', 1, 200);
        expect(q).toContain("> '2026-01-01''; drop'");
    });
});

describe('QuickBooksConnector — TestConnection', () => {
    it('succeeds against CompanyInfo and surfaces the company name', async () => {
        const c = new MockedQuickBooksConnector();
        c.queue(ok(companyInfoOk));
        const r = await c.TestConnection(makeCI(), user);
        expect(r.Success).toBe(true);
        expect(r.Message).toContain('<scrubbed-company>');
        expect(c.Captured[0].url).toContain('/companyinfo/REALM123');
        expect(c.Captured[0].url).toContain('minorversion=75');
    });

    it('reports failure with the Fault message on a 401', async () => {
        const c = new MockedQuickBooksConnector();
        c.queue(ok(authFault, 401));
        const r = await c.TestConnection(makeCI(), user);
        expect(r.Success).toBe(false);
        expect(r.Message).toMatch(/authentication/i);
    });
});

describe('QuickBooksConnector — FetchChanges (/query door)', () => {
    it('builds a paginated full-scan query, strips the envelope, and reports HasMore + NextOffset', async () => {
        const c = new MockedQuickBooksConnector();
        c.registerIO(invoiceIO(), idPK);
        c.queue(ok(invoicePage1));
        const batch = await c.FetchChanges(fetchCtx('Invoice'));
        expect(batch.Records).toHaveLength(2);
        expect(batch.HasMore).toBe(true);
        expect(batch.NextOffset).toBe(2);
        const q = decodeQuery(c.Captured[0].url);
        expect(q).toBe('select * from Invoice startposition 1 maxresults 200');
        expect(c.Captured[0].url).toContain('/query?');
    });

    it('advances STARTPOSITION on a subsequent page (offset drives skip = offset + skipBase)', async () => {
        const c = new MockedQuickBooksConnector();
        c.registerIO(invoiceIO(), idPK);
        c.queue(ok(invoicePage1));
        await c.FetchChanges(fetchCtx('Invoice', { CurrentOffset: 2, BatchSize: 2 }));
        expect(decodeQuery(c.Captured[0].url)).toBe('select * from Invoice startposition 3 maxresults 2');
    });

    it('caps MAXRESULTS at the QBO 1000/query ceiling', async () => {
        const c = new MockedQuickBooksConnector();
        c.registerIO(invoiceIO(), idPK);
        c.queue(ok(invoicePage1));
        await c.FetchChanges(fetchCtx('Invoice', { BatchSize: 5000 }));
        expect(decodeQuery(c.Captured[0].url)).toContain('maxresults 1000');
    });

    it('passes the FULL source record through to Fields (custom-column contract), and sets ExternalID from Id', async () => {
        const c = new MockedQuickBooksConnector();
        c.registerIO(invoiceIO(), idPK);
        c.queue(ok(invoicePage1));
        const batch = await c.FetchChanges(fetchCtx('Invoice'));
        const rec = batch.Records[0];
        expect(rec.ExternalID).toBe('1');
        // full record preserved — nested CustomerRef + MetaData survive, nothing narrowed to a {Id,...} literal
        expect(rec.Fields.CustomerRef).toEqual({ value: '55', name: '<scrubbed-customer-1>' });
        expect((rec.Fields.MetaData as Record<string, unknown>).LastUpdatedTime).toBe('2026-01-02T09:00:00-08:00');
        expect(rec.Fields.TotalAmt).toBe(100.0);
    });
});

describe('QuickBooksConnector — FetchChanges incremental + CDC deletions', () => {
    it('adds the watermark WHERE clause, returns the max LastUpdatedTime, and merges CDC tombstones on page 0', async () => {
        const c = new MockedQuickBooksConnector();
        c.registerIO(invoiceIO(), idPK);
        c.queue(ok(invoicePage1), ok(cdcDeletions));
        const batch = await c.FetchChanges(fetchCtx('Invoice', { WatermarkValue: '2026-01-01T00:00:00-08:00' }));

        // query call carries the watermark predicate
        const q = decodeQuery(c.Captured[0].url);
        expect(q).toContain("where MetaData.LastUpdatedTime > '2026-01-01T00:00:00-08:00'");
        // CDC call issued second
        expect(c.Captured[1].url).toContain('/cdc?entities=Invoice');
        expect(c.Captured[1].url).toContain('changedSince=');

        // 2 live + 1 deleted tombstone
        expect(batch.Records).toHaveLength(3);
        const deleted = batch.Records.find(r => r.IsDeleted);
        expect(deleted?.ExternalID).toBe('9');
        expect(deleted?.IsDeleted).toBe(true);
        // new watermark = the max LastUpdatedTime among the live query rows
        expect(batch.NewWatermarkValue).toBe('2026-01-03T10:00:00-08:00');
    });

    it('does NOT issue a CDC call for a non-incremental (full) scan', async () => {
        const c = new MockedQuickBooksConnector();
        c.registerIO(invoiceIO(), idPK);
        c.queue(ok(invoicePage1));
        await c.FetchChanges(fetchCtx('Invoice'));
        expect(c.Captured).toHaveLength(1);
        expect(c.Captured[0].url).not.toContain('/cdc');
    });

    it('does NOT re-probe CDC on a later page (offset > 0)', async () => {
        const c = new MockedQuickBooksConnector();
        c.registerIO(invoiceIO(), idPK);
        c.queue(ok(invoicePage1));
        await c.FetchChanges(fetchCtx('Invoice', { WatermarkValue: '2026-01-01T00:00:00-08:00', CurrentOffset: 2 }));
        expect(c.Captured).toHaveLength(1);
        expect(c.Captured[0].url).not.toContain('/cdc');
    });
});

describe('QuickBooksConnector — parseCdcDeletions', () => {
    const c = new MockedQuickBooksConnector();
    it('extracts only Deleted-status rows as IsDeleted tombstones', () => {
        const out = c.PublicParseCdc(cdcDeletions, 'Invoice', 'Invoice') as Array<{ ExternalID: string; IsDeleted?: boolean }>;
        expect(out).toHaveLength(1);
        expect(out[0].ExternalID).toBe('9');
        expect(out[0].IsDeleted).toBe(true);
    });
    it('ignores non-deleted rows and malformed envelopes', () => {
        const mixed = { CDCResponse: [{ QueryResponse: [{ Invoice: [{ Id: '10', status: 'Created' }] }] }] };
        expect(c.PublicParseCdc(mixed, 'Invoice', 'Invoice')).toHaveLength(0);
        expect(c.PublicParseCdc({}, 'Invoice', 'Invoice')).toHaveLength(0);
    });
});

describe('QuickBooksConnector — FetchChanges singleton (read-only resource)', () => {
    it('reads CompanyInfo via a single GET at /{entity}/{realmId} with no query door', async () => {
        const c = new MockedQuickBooksConnector();
        c.registerIO(makeIO({ ID: 'io-ci', Name: 'CompanyInfo', Configuration: companyInfoConfig }), idPK);
        c.queue(ok(companyInfoOk));
        const batch = await c.FetchChanges(fetchCtx('CompanyInfo'));
        expect(batch.HasMore).toBe(false);
        expect(batch.Records).toHaveLength(1);
        expect(batch.Records[0].ExternalID).toBe('1');
        expect(c.Captured[0].url).toContain('/companyinfo/REALM123');
        expect(c.Captured[0].url).not.toContain('/query');
    });
});

describe('QuickBooksConnector — GetRecord', () => {
    it('reads /{entity}/{id} and unwraps the nested entity object', async () => {
        const c = new MockedQuickBooksConnector();
        c.registerIO(invoiceIO(), idPK);
        c.queue(ok(invoiceGetOne));
        const rec = await c.GetRecord({ CompanyIntegration: makeCI(), ObjectName: 'Invoice', ContextUser: user, ExternalID: 'inv1' } as GetRecordContext);
        expect(rec?.ExternalID).toBe('inv1');
        expect(rec?.Fields.SyncToken).toBe('3');
        expect(c.Captured[0].method).toBe('GET');
        expect(c.Captured[0].url).toContain('/invoice/inv1');
    });

    it('returns null on a 404', async () => {
        const c = new MockedQuickBooksConnector();
        c.registerIO(invoiceIO(), idPK);
        c.queue(ok(null, 404));
        const rec = await c.GetRecord({ CompanyIntegration: makeCI(), ObjectName: 'Invoice', ContextUser: user, ExternalID: 'nope' } as GetRecordContext);
        expect(rec).toBeNull();
    });
});

describe('QuickBooksConnector — UpdateRecord (full-object POST + SyncToken + sparse)', () => {
    it('POSTs the full object with Id, the carried SyncToken, and sparse:true', async () => {
        const c = new MockedQuickBooksConnector();
        c.registerIO(invoiceIO(), idPK);
        c.queue(ok(invoiceUpdated));
        const r = await c.UpdateRecord({
            CompanyIntegration: makeCI(), ObjectName: 'Invoice', ContextUser: user,
            ExternalID: 'inv1', Attributes: { TotalAmt: 99.0, SyncToken: '3' },
        } as UpdateRecordContext);
        expect(r.Success).toBe(true);
        expect(r.ExternalID).toBe('inv1');
        const req = c.Captured[0];
        expect(req.method).toBe('POST');
        expect(req.url).toContain('/invoice?');
        const body = req.body as Record<string, unknown>;
        expect(body.Id).toBe('inv1');
        expect(body.SyncToken).toBe('3');
        expect(body.sparse).toBe(true);
        expect(body.TotalAmt).toBe(99.0);
    });

    it('fetch-or-carry: reads the current SyncToken via GetRecord when the caller did not supply one', async () => {
        const c = new MockedQuickBooksConnector();
        c.registerIO(invoiceIO(), idPK);
        c.queue(ok(invoiceGetOne), ok(invoiceUpdated)); // GET then POST
        const r = await c.UpdateRecord({
            CompanyIntegration: makeCI(), ObjectName: 'Invoice', ContextUser: user,
            ExternalID: 'inv1', Attributes: { TotalAmt: 99.0 },
        } as UpdateRecordContext);
        expect(r.Success).toBe(true);
        expect(c.Captured[0].method).toBe('GET');
        expect(c.Captured[0].url).toContain('/invoice/inv1');
        expect(c.Captured[1].method).toBe('POST');
        expect((c.Captured[1].body as Record<string, unknown>).SyncToken).toBe('3'); // from the fetched record
    });

    it('classifies a stale SyncToken (code 5010) as a conflict failure — no blind retry', async () => {
        const c = new MockedQuickBooksConnector();
        c.registerIO(invoiceIO(), idPK);
        c.queue(ok(staleTokenFault, 400));
        const r = await c.UpdateRecord({
            CompanyIntegration: makeCI(), ObjectName: 'Invoice', ContextUser: user,
            ExternalID: 'inv1', Attributes: { TotalAmt: 99.0, SyncToken: '0' },
        } as UpdateRecordContext);
        expect(r.Success).toBe(false);
        expect(r.ErrorMessage).toMatch(/stale SyncToken/i);
        expect(c.Captured).toHaveLength(1); // exactly one attempt — not retried
    });

    it('refuses to update an object whose metadata declares no update path', async () => {
        const c = new MockedQuickBooksConnector();
        c.registerIO(makeIO({ ID: 'io-ro', Name: 'ReadOnlyThing', Configuration: companyInfoConfig, SupportsUpdate: false }), idPK);
        const r = await c.UpdateRecord({
            CompanyIntegration: makeCI(), ObjectName: 'ReadOnlyThing', ContextUser: user,
            ExternalID: 'x', Attributes: {},
        } as UpdateRecordContext);
        expect(r.Success).toBe(false);
        expect(r.ErrorMessage).toMatch(/not supported/i);
        expect(c.Captured).toHaveLength(0);
    });
});

describe('QuickBooksConnector — DeleteRecord (hard-delete transactions vs deactivate name-lists)', () => {
    it('hard-deletes a transaction entity via POST ?operation=delete with {Id, SyncToken}', async () => {
        const c = new MockedQuickBooksConnector();
        c.registerIO(invoiceIO(), idPK);
        c.queue(ok(invoiceGetOne), ok({ Invoice: { Id: 'inv1', status: 'Deleted' } })); // GET token, then delete
        const r = await c.DeleteRecord({ CompanyIntegration: makeCI(), ObjectName: 'Invoice', ContextUser: user, ExternalID: 'inv1' } as DeleteRecordContext);
        expect(r.Success).toBe(true);
        const del = c.Captured[1];
        expect(del.method).toBe('POST');
        expect(del.url).toContain('operation=delete');
        const body = del.body as Record<string, unknown>;
        expect(body.Id).toBe('inv1');
        expect(body.SyncToken).toBe('3');
    });

    it('deactivates a name-list entity via sparse Active=false (no operation=delete)', async () => {
        const c = new MockedQuickBooksConnector();
        c.registerIO(customerIO(), idPK);
        c.queue(ok(customerGetOne), ok(customerDeactivated)); // GET token, then deactivate
        const r = await c.DeleteRecord({ CompanyIntegration: makeCI(), ObjectName: 'Customer', ContextUser: user, ExternalID: 'cust1' } as DeleteRecordContext);
        expect(r.Success).toBe(true);
        const req = c.Captured[1];
        expect(req.url).not.toContain('operation=delete');
        const body = req.body as Record<string, unknown>;
        expect(body.Active).toBe(false);
        expect(body.sparse).toBe(true);
        expect(body.SyncToken).toBe('2');
    });

    it('fails loudly for a transaction whose delete is not enabled — without spending a token read', async () => {
        const c = new MockedQuickBooksConnector();
        c.registerIO(makeIO({ ID: 'io-recur', Name: 'RecurringTransaction', Configuration: recurringConfig, SupportsDelete: false }), idPK);
        const r = await c.DeleteRecord({ CompanyIntegration: makeCI(), ObjectName: 'RecurringTransaction', ContextUser: user, ExternalID: 'r1' } as DeleteRecordContext);
        expect(r.Success).toBe(false);
        expect(r.ErrorMessage).toMatch(/does not support delete/i);
        expect(c.Captured).toHaveLength(0); // no wasted GET
    });
});

describe('QuickBooksConnector — keyless record content-hash idempotency', () => {
    it('stamps a deterministic content hash into the PK field when the source record has no Id', async () => {
        const c = new MockedQuickBooksConnector();
        // an object whose declared PK column is present in metadata but absent from the sampled record
        c.registerIO(makeIO({ ID: 'io-keyless', Name: 'Keyless', Configuration: JSON.stringify({ QueryEntity: 'Keyless', entityClass: 'transaction', cdcEligible: false }) }), idPK);
        const page = { QueryResponse: { Keyless: [{ Amount: 5, Note: 'a' }], totalCount: 1 }, time: 't' };
        c.queue(ok(page));
        const batch = await c.FetchChanges(fetchCtx('Keyless'));
        const rec = batch.Records[0];
        expect(rec.ExternalID.length).toBeGreaterThan(0);
        // the synthetic id is stamped into the single PK field so the record is still keyed + idempotent
        expect(rec.Fields.Id).toBe(rec.ExternalID);
        expect(rec.Fields.Amount).toBe(5); // full record still passes through
    });
});
