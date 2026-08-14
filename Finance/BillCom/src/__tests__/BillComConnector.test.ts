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
