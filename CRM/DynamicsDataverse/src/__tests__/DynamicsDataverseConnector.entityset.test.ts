import { describe, it, expect } from 'vitest';
import { DynamicsDataverseConnector } from '../DynamicsDataverseConnector.js';

/**
 * Entity-set path repair.
 *
 * A table that arrives through runtime discovery reaches the IO row carrying only its LOGICAL name,
 * because `ExternalObjectSchema` has no field for an API path. Joined onto the org root that yields
 * `<EnvironmentUrl>/pa_batchlog` — singular, and with no Web API segment — which Dataverse 404s.
 * The frozen catalog hides this for the 592 standard tables; a discovery-only leaf such as Protech
 * (UX 365) hits it on every object.
 */

const ENV = 'https://org.crm.dynamics.com';

/** Minimal DynamicsAuthContext — the repair only reads BaseUrl / ApiBaseUrl / Config. */
function authFor(apiVersion = 'v9.2'): Record<string, unknown> {
    return {
        Token: 'token',
        Config: { EnvironmentUrl: ENV, MaxRetries: 0 },
        BaseUrl: ENV,
        ApiBaseUrl: `${ENV}/api/data/${apiVersion}`,
    };
}

const DEFS = [
    { LogicalName: 'account', EntitySetName: 'accounts' },
    { LogicalName: 'pa_batchlog', EntitySetName: 'pa_batchlogs' },
    // Irregular plural — the reason the set name must be read, never derived by appending "s".
    { LogicalName: 'pa_country', EntitySetName: 'pa_countries' },
];

type Call = { url: string; method: string };

/** Stubs the private one-shot transport so every request URL is observable. */
function harness(defs: unknown[] = DEFS) {
    const connector = new DynamicsDataverseConnector();
    const calls: Call[] = [];
    (connector as unknown as Record<string, unknown>).ExecuteOneRequest = async (url: string, method: string) => {
        calls.push({ url, method });
        const body = url.includes('/EntityDefinitions') ? { value: defs } : { value: [] };
        return { Status: 200, Headers: {}, Body: body };
    };
    const request = (url: string, method = 'GET') =>
        (connector as unknown as {
            MakeHTTPRequest(a: unknown, u: string, m: string, h: Record<string, string>): Promise<unknown>;
        }).MakeHTTPRequest(authFor(), url, method, {});
    return { connector, calls, request };
}

/** URLs actually put on the wire, minus the EntityDefinitions sweep. */
const dataCalls = (calls: Call[]) => calls.filter(c => !c.url.includes('/EntityDefinitions')).map(c => c.url);
const sweeps = (calls: Call[]) => calls.filter(c => c.url.includes('/EntityDefinitions')).length;

describe('DynamicsDataverseConnector — entity-set path repair', () => {
    it('leaves a frozen catalog path untouched and never sweeps for it', async () => {
        const { calls, request } = harness();
        await request(`${ENV}/api/data/v9.2/accounts?$top=50`);
        expect(dataCalls(calls)).toEqual([`${ENV}/api/data/v9.2/accounts?$top=50`]);
        expect(sweeps(calls)).toBe(0);
    });

    it('rewrites a discovered logical-name path into the Web API collection path', async () => {
        const { calls, request } = harness();
        await request(`${ENV}/pa_batchlog`);
        expect(dataCalls(calls)).toEqual([`${ENV}/api/data/v9.2/pa_batchlogs`]);
    });

    it('reads the irregular plural from EntityDefinitions instead of appending "s"', async () => {
        const { calls, request } = harness();
        await request(`${ENV}/pa_country`);
        expect(dataCalls(calls)).toEqual([`${ENV}/api/data/v9.2/pa_countries`]);
    });

    it('preserves the query string and the single-record key expression', async () => {
        const { calls, request } = harness();
        await request(`${ENV}/pa_batchlog?$select=pa_name&$top=10`);
        await request(`${ENV}/pa_batchlog(00000000-0000-0000-0000-000000000001)`, 'PATCH');
        expect(dataCalls(calls)).toEqual([
            `${ENV}/api/data/v9.2/pa_batchlogs?$select=pa_name&$top=10`,
            `${ENV}/api/data/v9.2/pa_batchlogs(00000000-0000-0000-0000-000000000001)`,
        ]);
    });

    it('resolves a path that already names the collection to itself', async () => {
        const { calls, request } = harness();
        await request(`${ENV}/pa_batchlogs`);
        expect(dataCalls(calls)).toEqual([`${ENV}/api/data/v9.2/pa_batchlogs`]);
    });

    it('takes the version segment from ApiBaseUrl rather than hardcoding v9.2', async () => {
        const connector = new DynamicsDataverseConnector();
        const calls: Call[] = [];
        (connector as unknown as Record<string, unknown>).ExecuteOneRequest = async (url: string, method: string) => {
            calls.push({ url, method });
            return { Status: 200, Headers: {}, Body: url.includes('/EntityDefinitions') ? { value: DEFS } : { value: [] } };
        };
        await (connector as unknown as {
            MakeHTTPRequest(a: unknown, u: string, m: string, h: Record<string, string>): Promise<unknown>;
        }).MakeHTTPRequest(authFor('v9.1'), `${ENV}/pa_batchlog`, 'GET', {});
        expect(dataCalls(calls)).toEqual([`${ENV}/api/data/v9.1/pa_batchlogs`]);
    });

    it('never rewrites a foreign absolute URL (nextLink / deltaLink continuations)', async () => {
        const { calls, request } = harness();
        const deltaLink = 'https://other.crm.dynamics.com/api/data/v9.2/accounts?$deltatoken=abc';
        await request(deltaLink);
        expect(dataCalls(calls)).toEqual([deltaLink]);
        expect(sweeps(calls)).toBe(0);
    });

    it('sweeps EntityDefinitions once per environment, not once per request', async () => {
        const { calls, request } = harness();
        await request(`${ENV}/pa_batchlog`);
        await request(`${ENV}/pa_country`);
        await request(`${ENV}/account`);
        expect(sweeps(calls)).toBe(1);
        expect(dataCalls(calls)).toEqual([
            `${ENV}/api/data/v9.2/pa_batchlogs`,
            `${ENV}/api/data/v9.2/pa_countries`,
            `${ENV}/api/data/v9.2/accounts`,
        ]);
    });

    it('fails loudly on a name the environment does not expose, and does not re-sweep for it', async () => {
        const { calls, request } = harness();
        await expect(request(`${ENV}/pa_not_installed`)).rejects.toThrow(/matches no table or entity set/i);
        await expect(request(`${ENV}/pa_not_installed`)).rejects.toThrow(/matches no table or entity set/i);
        expect(sweeps(calls)).toBe(1);
        expect(dataCalls(calls)).toEqual([]);
    });

    it('follows EntityDefinitions paging so a table on a later page still resolves', async () => {
        const connector = new DynamicsDataverseConnector();
        const calls: Call[] = [];
        const nextLink = `${ENV}/api/data/v9.2/EntityDefinitions?$skiptoken=page2`;
        (connector as unknown as Record<string, unknown>).ExecuteOneRequest = async (url: string, method: string) => {
            calls.push({ url, method });
            if (url.includes('$skiptoken=page2')) {
                return { Status: 200, Headers: {}, Body: { value: [{ LogicalName: 'pa_late', EntitySetName: 'pa_lates' }] } };
            }
            if (url.includes('/EntityDefinitions')) {
                return { Status: 200, Headers: {}, Body: { value: [DEFS[0]], '@odata.nextLink': nextLink } };
            }
            return { Status: 200, Headers: {}, Body: { value: [] } };
        };
        await (connector as unknown as {
            MakeHTTPRequest(a: unknown, u: string, m: string, h: Record<string, string>): Promise<unknown>;
        }).MakeHTTPRequest(authFor(), `${ENV}/pa_late`, 'GET', {});
        expect(dataCalls(calls)).toEqual([`${ENV}/api/data/v9.2/pa_lates`]);
    });
});
