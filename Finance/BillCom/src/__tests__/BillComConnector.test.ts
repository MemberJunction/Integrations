import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { BillComConnector } from '../BillComConnector.js';

/**
 * Mock-first per repo convention: the wire boundary (`fetch`) is stubbed, and the protected surface is
 * reached through a narrow test subclass rather than casts. These tests exercise the three things that
 * are genuinely Bill.com-specific and easy to get wrong — session lifecycle, cursor termination, and the
 * per-object write-method asymmetry — not the generic machinery the base class already owns.
 */

/** Exposes protected members for assertion without weakening the production type. */
class TestableBillCom extends BillComConnector {
    public callBuildHeaders(auth: Parameters<BillComConnector['BuildHeaders']>[0]) {
        return this['BuildHeaders'](auth);
    }
    public callNormalize(body: unknown, key: string | null) {
        return this['NormalizeResponse'](body, key);
    }
    public callExtractPagination(body: unknown) {
        return this['ExtractPaginationInfo'](body, 'Cursor', 0, 0, 100);
    }
    public callBuildPaginatedURL(basePath: string, cursor?: string, pageSize?: number) {
        const obj = { DefaultPageSize: 100 } as Parameters<BillComConnector['BuildPaginatedURL']>[1];
        return this['BuildPaginatedURL'](basePath, obj, 0, 0, cursor, pageSize);
    }
    public callExtractError(response: Parameters<BillComConnector['ExtractErrorMessage']>[0]) {
        return this['ExtractErrorMessage'](response);
    }
    public callMakeHTTPRequest(
        auth: Parameters<BillComConnector['MakeHTTPRequest']>[0],
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown
    ) {
        return this['MakeHTTPRequest'](auth, url, method, headers, body);
    }
    public callResolveBaseURL(creds: { ApiUrl?: string; Environment?: string }) {
        return (this as unknown as { ResolveBaseURL(c: unknown): string }).ResolveBaseURL({
            Username: 'u', Password: 'p', OrganizationID: 'org', DevKey: 'dk', ...creds,
        });
    }
    /** Stands in for the engine's object cache so the archive path can be read from Configuration. */
    public stubCachedObject(configuration: string | null): void {
        (this as unknown as { GetCachedObject(): unknown }).GetCachedObject = () => ({ Configuration: configuration });
    }
    /** Makes GetCachedObject behave like an unseeded database. */
    public stubMissingObject(): void {
        (this as unknown as { GetCachedObject(): unknown }).GetCachedObject = () => {
            throw new Error('IntegrationObject not found: "invoices"');
        };
    }
    /** Seeds the private credential cache so the 401 re-login path is reachable in isolation. */
    public seedCredentials(): void {
        (this as unknown as { cachedCredentials: unknown }).cachedCredentials = {
            Username: 'u', Password: 'p', OrganizationID: 'org', DevKey: 'dk', Environment: 'sandbox',
        };
    }
}

const authCtx = () => ({ SessionID: 'sess-1', DevKey: 'dev-1', BaseURL: 'https://mock/connect/v3', LastUsedAt: Date.now() });

function jsonResponse(status: number, body: unknown): Response {
    return new Response(JSON.stringify(body), {
        status,
        headers: { 'content-type': 'application/json' },
    });
}

describe('BillComConnector', () => {
    let connector: TestableBillCom;

    beforeEach(() => {
        connector = new TestableBillCom();
    });
    afterEach(() => {
        vi.restoreAllMocks();
    });

    describe('identity and capabilities', () => {
        it('reports the integration name the catalog binds to', () => {
            expect(connector.IntegrationName).toBe('Bill.com');
        });

        it('caps concurrency at 3 — BDC_1322 is per devKey per org', () => {
            expect(connector.MaxConcurrencyHint).toBe(3);
        });

        it('does not treat discovery as authoritative (no describe-all endpoint exists)', () => {
            expect(connector.DiscoveryIsAuthoritative).toBe(false);
        });

        it('declares no delete support — invoices archive, they do not delete', () => {
            expect(connector.SupportsDelete).toBe(false);
            expect(connector.SupportsCreate).toBe(true);
            expect(connector.SupportsUpdate).toBe(true);
        });
    });

    describe('headers', () => {
        it('sends sessionId and devKey as headers, not bearer auth', () => {
            const headers = connector.callBuildHeaders(authCtx());
            expect(headers.sessionId).toBe('sess-1');
            expect(headers.devKey).toBe('dev-1');
            expect(headers.Authorization).toBeUndefined();
        });
    });

    describe('response normalization', () => {
        it('unwraps the results[] envelope', () => {
            const rows = connector.callNormalize({ results: [{ id: '00e1' }, { id: '00e2' }], nextPage: 'p2' }, 'results');
            expect(rows).toHaveLength(2);
            expect(rows[0].id).toBe('00e1');
        });

        it('defaults to results when no data key is supplied', () => {
            expect(connector.callNormalize({ results: [{ id: 'x' }] }, null)).toHaveLength(1);
        });

        it('treats a single-record body as one row', () => {
            const rows = connector.callNormalize({ id: '0cu1', name: 'Acme' }, 'results');
            expect(rows).toHaveLength(1);
            expect(rows[0].name).toBe('Acme');
        });

        it('returns empty for null rather than throwing', () => {
            expect(connector.callNormalize(null, 'results')).toEqual([]);
        });
    });

    describe('cursor pagination', () => {
        it('continues while nextPage is present', () => {
            const state = connector.callExtractPagination({ results: [{ id: 'a' }], nextPage: 'TOKEN-2' });
            expect(state.HasMore).toBe(true);
            expect(state.NextCursor).toBe('TOKEN-2');
        });

        it('terminates on ABSENCE of nextPage, not on an empty page', () => {
            // The trap: an empty page WITH a cursor must keep going...
            const stillGoing = connector.callExtractPagination({ results: [], nextPage: 'TOKEN-3' });
            expect(stillGoing.HasMore).toBe(true);

            // ...and a full page WITHOUT a cursor is the end.
            const done = connector.callExtractPagination({ results: [{ id: 'a' }, { id: 'b' }] });
            expect(done.HasMore).toBe(false);
        });

        it('treats an empty-string cursor as terminal', () => {
            expect(connector.callExtractPagination({ results: [], nextPage: '' }).HasMore).toBe(false);
        });

        it('always sends max explicitly (docs disagree: 100 vs 20)', () => {
            expect(connector.callBuildPaginatedURL('/v3/invoices')).toContain('max=100');
        });

        it('caps max at the documented ceiling of 100', () => {
            expect(connector.callBuildPaginatedURL('/v3/invoices', undefined, 500)).toContain('max=100');
        });

        it('passes the opaque cursor as page, url-encoded', () => {
            const url = connector.callBuildPaginatedURL('/v3/invoices', 'a b/c');
            expect(url).toContain('page=a%20b%2Fc');
        });

        it('respects an existing query string', () => {
            const url = connector.callBuildPaginatedURL('/v3/invoices?filters=archived%3Aeq%3Afalse');
            expect(url).toContain('?filters=');
            expect(url).toContain('&max=');
        });
    });

    describe('error extraction', () => {
        it('surfaces the vendor message', () => {
            const msg = connector.callExtractError({ Status: 400, Body: { message: 'BDC_1322 too many concurrent' }, Headers: {} });
            expect(msg).toBe('BDC_1322 too many concurrent');
        });

        it('returns undefined when there is nothing to report', () => {
            expect(connector.callExtractError({ Status: 200, Body: {}, Headers: {} })).toBeUndefined();
        });

        it('joins the messages of an array body — BILL reports validation failures that way', () => {
            const msg = connector.callExtractError({
                Status: 400,
                Body: [{ severity: 'ERROR', message: 'customer: must not be null' }, { severity: 'ERROR', message: 'invoiceLineItems: must not be null' }],
                Headers: {},
            });
            expect(msg).toBe('customer: must not be null; invoiceLineItems: must not be null');
        });

        it('returns undefined for an array carrying no messages', () => {
            expect(connector.callExtractError({ Status: 400, Body: [{ severity: 'ERROR' }], Headers: {} })).toBeUndefined();
        });
    });

    describe('session lifecycle', () => {
        it('re-logins once on a 401 and replays the request', async () => {
            connector.seedCredentials();
            const calls: string[] = [];
            vi.spyOn(globalThis, 'fetch').mockImplementation(async (input: RequestInfo | URL) => {
                const url = String(input);
                calls.push(url);
                if (url.endsWith('/login')) return jsonResponse(200, { sessionId: 'sess-2' });
                // First data call 401s; the replay after re-login succeeds.
                return calls.filter((c) => !c.endsWith('/login')).length === 1
                    ? jsonResponse(401, { message: 'session expired' })
                    : jsonResponse(200, { results: [{ id: '00e9' }] });
            });

            const res = await connector.callMakeHTTPRequest(
                authCtx(), 'https://mock/connect/v3/invoices', 'GET', { sessionId: 'sess-1', devKey: 'dev-1' }
            );

            expect(res.Status).toBe(200);
            expect(calls.filter((c) => c.endsWith('/login'))).toHaveLength(1);
        });

        it('does not attempt re-login when no credentials are cached', async () => {
            const calls: string[] = [];
            vi.spyOn(globalThis, 'fetch').mockImplementation(async (input: RequestInfo | URL) => {
                calls.push(String(input));
                return jsonResponse(401, { message: 'unauthorized' });
            });

            const res = await connector.callMakeHTTPRequest(
                authCtx(), 'https://mock/connect/v3/invoices', 'GET', {}
            );

            expect(res.Status).toBe(401);
            expect(calls.filter((c) => c.endsWith('/login'))).toHaveLength(0);
        });

        it('does not send a body on GET', async () => {
            let sawBody: unknown;
            vi.spyOn(globalThis, 'fetch').mockImplementation(async (_i: RequestInfo | URL, init?: RequestInit) => {
                sawBody = init?.body;
                return jsonResponse(200, { results: [] });
            });
            await connector.callMakeHTTPRequest(authCtx(), 'https://mock/x', 'GET', {}, { ignored: true });
            expect(sawBody).toBeUndefined();
        });

        it('serializes a JSON body on POST', async () => {
            let sawBody: unknown;
            vi.spyOn(globalThis, 'fetch').mockImplementation(async (_i: RequestInfo | URL, init?: RequestInit) => {
                sawBody = init?.body;
                return jsonResponse(200, { id: '00e1' });
            });
            await connector.callMakeHTTPRequest(authCtx(), 'https://mock/x', 'POST', {}, { customerId: '0cu1' });
            expect(sawBody).toBe(JSON.stringify({ customerId: '0cu1' }));
        });
    });
});

/**
 * The version segment belongs to the path, not the base (#390). These are regression tests for a defect
 * that made EVERY generic CRUD and fetch call 404 while `TestConnection` kept reporting success.
 */
describe('gateway base URL', () => {
    const connector = new TestableBillCom();

    it('defaults to the sandbox gateway without a version segment', () => {
        expect(connector.callResolveBaseURL({})).toBe('https://gateway.stage.bill.com/connect');
    });

    it('selects production only on an explicit environment', () => {
        expect(connector.callResolveBaseURL({ Environment: 'production' })).toBe('https://gateway.prod.bill.com/connect');
        expect(connector.callResolveBaseURL({ Environment: 'Production ' })).toBe('https://gateway.prod.bill.com/connect');
        expect(connector.callResolveBaseURL({ Environment: 'anything-else' })).toBe('https://gateway.stage.bill.com/connect');
    });

    it('strips a trailing /v3 from a configured apiUrl — the credential help text recommends that spelling', () => {
        expect(connector.callResolveBaseURL({ ApiUrl: 'https://gateway.stage.bill.com/connect/v3' })).toBe('https://gateway.stage.bill.com/connect');
        expect(connector.callResolveBaseURL({ ApiUrl: 'https://gateway.stage.bill.com/connect/v3/' })).toBe('https://gateway.stage.bill.com/connect');
    });

    it('leaves a version-less apiUrl alone, and keeps a path that merely contains v3', () => {
        expect(connector.callResolveBaseURL({ ApiUrl: 'https://mock.local/connect' })).toBe('https://mock.local/connect');
        expect(connector.callResolveBaseURL({ ApiUrl: 'https://mock.local/v3/proxy' })).toBe('https://mock.local/v3/proxy');
    });

    it('addresses the version on login, so base + catalog path stays unversioned', async () => {
        const urls: string[] = [];
        vi.spyOn(globalThis, 'fetch').mockImplementation(async (input: RequestInfo | URL) => {
            urls.push(String(input));
            return jsonResponse(200, { sessionId: 'sess-1' });
        });
        await (connector as unknown as { Login(c: unknown): Promise<unknown> }).Login({
            Username: 'u', Password: 'p', OrganizationID: 'org', DevKey: 'dk', Environment: 'sandbox',
        });
        expect(urls).toEqual(['https://gateway.stage.bill.com/connect/v3/login']);
        vi.restoreAllMocks();
    });
});

/**
 * Cancellation is `POST /v3/invoices/{id}/archive` — never a field write. `UpdateRecord({archived:true})`
 * is answered 400 by BILL because the invoices object updates with PUT, which is a full replace (#391).
 */
describe('invoice archive and restore', () => {
    let connector: TestableBillCom;
    const ci = { ID: 'ci-1', IntegrationID: 'int-1' } as never;
    const user = {} as never;

    /** Answers every call with `status`, recording the URL and method it was asked for. */
    const wire = (status: number, body: unknown = { archived: true }) => {
        const seen: Array<{ url: string; method?: string; body?: unknown }> = [];
        vi.spyOn(globalThis, 'fetch').mockImplementation(async (input: RequestInfo | URL, init?: RequestInit) => {
            seen.push({ url: String(input), method: init?.method, body: init?.body });
            return jsonResponse(status, body);
        });
        return seen;
    };

    beforeEach(() => {
        connector = new TestableBillCom();
        connector.seedCredentials();
        (connector as unknown as { cachedAuth: unknown }).cachedAuth = authCtx();
        connector.stubCachedObject(JSON.stringify({ archivePath: '/v3/invoices/{invoiceId}/archive', restorePath: '/v3/invoices/{invoiceId}/restore' }));
    });

    afterEach(() => vi.restoreAllMocks());

    it('POSTs the archive sub-resource with no body and reports the invoice back', async () => {
        const seen = wire(200);
        const result = await connector.ArchiveInvoice({ CompanyIntegration: ci, ExternalID: '00e1', ContextUser: user });
        expect(result).toEqual({ Success: true, StatusCode: 200, ExternalID: '00e1' });
        expect(seen).toHaveLength(1);
        expect(seen[0].url).toBe('https://mock/connect/v3/invoices/00e1/archive');
        expect(seen[0].method).toBe('POST');
        expect(seen[0].body).toBeUndefined();
    });

    it('restores through the configured restore path', async () => {
        const seen = wire(200, { archived: false });
        const result = await connector.RestoreInvoice({ CompanyIntegration: ci, ExternalID: '00e1', ContextUser: user });
        expect(result.Success).toBe(true);
        expect(seen[0].url).toBe('https://mock/connect/v3/invoices/00e1/restore');
    });

    it('falls back to the documented path when Configuration predates the key', async () => {
        connector.stubCachedObject(JSON.stringify({ archiveNote: 'no paths here' }));
        const seen = wire(200);
        await connector.ArchiveInvoice({ CompanyIntegration: ci, ExternalID: '00e1', ContextUser: user });
        expect(seen[0].url).toBe('https://mock/connect/v3/invoices/00e1/archive');
    });

    it('still archives when the object is not seeded at all — a missing cache must not block a cancel', async () => {
        connector.stubMissingObject();
        const seen = wire(200);
        const result = await connector.ArchiveInvoice({ CompanyIntegration: ci, ExternalID: '00e1', ContextUser: user });
        expect(result.Success).toBe(true);
        expect(seen[0].url).toBe('https://mock/connect/v3/invoices/00e1/archive');
    });

    it('url-encodes the id rather than interpolating it raw', async () => {
        const seen = wire(200);
        await connector.ArchiveInvoice({ CompanyIntegration: ci, ExternalID: '00e 1/x', ContextUser: user });
        expect(seen[0].url).toBe('https://mock/connect/v3/invoices/00e%201%2Fx/archive');
    });

    it('refuses an empty id without reaching the wire', async () => {
        const seen = wire(200);
        const result = await connector.ArchiveInvoice({ CompanyIntegration: ci, ExternalID: '  ', ContextUser: user });
        expect(result.Success).toBe(false);
        expect(seen).toHaveLength(0);
    });

    it("surfaces BILL's array-shaped validation errors instead of a bare status", async () => {
        wire(400, [
            { timestamp: '2026-09-21T00:00:00Z', severity: 'ERROR', message: 'customer: must not be null' },
            { timestamp: '2026-09-21T00:00:00Z', severity: 'ERROR', message: 'invoiceLineItems: must not be null' },
        ]);
        const result = await connector.ArchiveInvoice({ CompanyIntegration: ci, ExternalID: '00e1', ContextUser: user });
        expect(result.Success).toBe(false);
        expect(result.StatusCode).toBe(400);
        expect(result.ErrorMessage).toBe('customer: must not be null; invoiceLineItems: must not be null');
    });
});

describe('action generation surface', () => {
    const connector = new BillComConnector();

    it('declares its objects — returning [] would mean no Actions can ever be generated', () => {
        const objects = connector.GetIntegrationObjects();
        expect(objects.length).toBeGreaterThan(0);
        expect(objects.map((o) => o.Name).sort()).toEqual(['customers', 'invoices', 'receivable-payments']);
    });

    it('marks every object writable — each has a documented create path', () => {
        expect(connector.GetIntegrationObjects().every((o) => o.SupportsWrite)).toBe(true);
    });

    it('declares id as the primary key on every object', () => {
        for (const obj of connector.GetIntegrationObjects()) {
            const pks = obj.Fields.filter((f) => f.IsPrimaryKey).map((f) => f.Name);
            expect(pks).toEqual(['id']);
        }
    });

    it('supplies a generator config carrying those objects', () => {
        const cfg = connector.GetActionGeneratorConfig();
        expect(cfg).not.toBeNull();
        expect(cfg?.IntegrationName).toBe('Bill.com');
        expect(cfg?.Objects).toHaveLength(3);
    });

    /**
     * Regression guard for a defect found only by live sandbox writes. BILL's invoice READ shape
     * returns a flat `customerId` string, but its CREATE shape requires a nested `customer` object
     * (`InvoiceCustomer`, e.g. {"id":"0cu…"}). Fields are derived from the response DTO, so a naive
     * regeneration reintroduces `customerId` as writable and every O-UC6 create fails with HTTP 400.
     *
     * Neither the mock suite nor a read-only probe can surface this — the wire is stubbed in one and
     * never written to in the other — so it is asserted directly against the declared catalog.
     */
    describe('invoice customer reference — read/write divergence', () => {
        const invoiceFields = () => {
            const invoices = connector.GetIntegrationObjects().find((o) => o.Name === 'invoices');
            if (!invoices) throw new Error('invoices object missing from catalog');
            return invoices.Fields;
        };

        it('declares `customer` as a writable, required json object', () => {
            const customer = invoiceFields().find((f) => f.Name === 'customer');
            expect(customer, '`customer` missing — invoice creation will fail with HTTP 400').toBeDefined();
            expect(customer?.IsReadOnly).toBe(false);
            expect(customer?.IsRequired).toBe(true);
            // `json`, not `string`: a bare ID is rejected with "Cannot construct instance of InvoiceCustomer".
            expect(customer?.Type).toBe('json');
        });

        it('keeps `customerId` read-only — BILL returns it on read but rejects it on write', () => {
            const customerId = invoiceFields().find((f) => f.Name === 'customerId');
            expect(customerId).toBeDefined();
            expect(customerId?.IsReadOnly).toBe(true);
        });
    });

    it('keeps the generated objects in step with the shipped catalog', async () => {
        // Guards the drift this design exists to prevent: both come from one extraction run.
        const catalog = await import('../../metadata/integration/.billcom.integration.json', {
            with: { type: 'json' },
        }) as unknown as { default: Array<{ relatedEntities: Record<string, Array<{ fields: { Name: string } }>> }> };
        const catalogNames = catalog.default[0].relatedEntities['MJ: Integration Objects']
            .map((o) => o.fields.Name).sort();
        expect(connector.GetIntegrationObjects().map((o) => o.Name).sort()).toEqual(catalogNames);
    });
});
