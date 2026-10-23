import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { RasaConnector } from './RasaConnector';

/**
 * v2 client-credentials auth (3.0.0). rasa.io directed integrations to v2 only; the 2.x connector
 * minted a v1 token (`POST /v1/tokens`, Basic + `{key}`) and sent it to v2 paths, which answer 401.
 * No network: `fetch` is stubbed and every call is recorded.
 */

interface Call {
    url: string;
    method: string;
    headers: Record<string, string>;
    body: unknown;
}

const HOST = 'https://rasa.test';

/** A CompanyIntegration carrying its credential in Configuration (no Credential record lookup). */
function companyIntegration(values: Record<string, string>) {
    return {
        IntegrationID: 'int-1',
        CredentialID: null,
        Configuration: JSON.stringify({ BaseURL: HOST, ...values }),
    } as never;
}

const user = {} as never;
const V2_CREDS = { ClientId: 'client-abc', ClientSecret: 'secret-xyz' };

function jsonResponse(status: number, body: unknown): Response {
    return new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });
}

/** Typed access to the connector's protected/private members for white-box assertions. */
type Internals = {
    Authenticate(ci: unknown, user: unknown): Promise<{ Token?: string }>;
    BuildHeaders(auth: { Token?: string }): Record<string, string>;
    MakeHTTPRequest(
        auth: { Token?: string },
        url: string,
        method: string,
        headers: Record<string, string>,
    ): Promise<{ Status: number }>;
};

describe('RasaConnector v2 auth', () => {
    let calls: Call[];
    let responder: (call: Call) => Response;

    beforeEach(() => {
        calls = [];
        vi.stubGlobal('fetch', async (input: string | URL, init?: RequestInit) => {
            const call: Call = {
                url: String(input),
                method: init?.method ?? 'GET',
                headers: (init?.headers ?? {}) as Record<string, string>,
                body: typeof init?.body === 'string' ? JSON.parse(init.body) : undefined,
            };
            calls.push(call);
            return responder(call);
        });
    });

    afterEach(() => {
        vi.unstubAllGlobals();
        vi.useRealTimers();
    });

    const tokenCalls = () => calls.filter(c => c.url.endsWith('/v2/tokens'));

    it('mints via POST /v2/tokens with a JSON client_credentials body', async () => {
        responder = () => jsonResponse(200, { access_token: 'jwt-1', token_type: 'Bearer', expires_in: 3600 });
        const connector = new RasaConnector() as unknown as Internals;

        const auth = await connector.Authenticate(companyIntegration(V2_CREDS), user);

        expect(auth.Token).toBe('jwt-1');
        expect(calls).toHaveLength(1);
        expect(calls[0].url).toBe(`${HOST}/v2/tokens`);
        expect(calls[0].method).toBe('POST');
        expect(calls[0].headers['Content-Type']).toBe('application/json');
        expect(calls[0].headers.Authorization).toBeUndefined();
        expect(calls[0].body).toEqual({
            grant_type: 'client_credentials',
            client_id: 'client-abc',
            client_secret: 'secret-xyz',
        });
        expect(calls.some(c => c.url.includes('/v1/'))).toBe(false);
    });

    it('presents the token as Authorization: Bearer only (the live API rejects rasa-token)', () => {
        const connector = new RasaConnector() as unknown as Internals;
        const headers = connector.BuildHeaders({ Token: 'jwt-1' });
        expect(headers.Authorization).toBe('Bearer jwt-1');
        expect(headers['rasa-token']).toBeUndefined();
    });

    it('reuses the token until shortly before expires_in, then re-mints', async () => {
        vi.useFakeTimers();
        vi.setSystemTime(new Date('2026-10-16T12:00:00Z'));
        let n = 0;
        responder = () => jsonResponse(200, { access_token: `jwt-${++n}`, expires_in: 600 });
        const connector = new RasaConnector() as unknown as Internals;
        const ci = companyIntegration(V2_CREDS);

        expect((await connector.Authenticate(ci, user)).Token).toBe('jwt-1');
        vi.setSystemTime(new Date('2026-10-16T12:08:00Z')); // 8 min: inside the 10-min lifetime
        expect((await connector.Authenticate(ci, user)).Token).toBe('jwt-1');
        vi.setSystemTime(new Date('2026-10-16T12:09:30Z')); // inside the 60 s refresh buffer
        expect((await connector.Authenticate(ci, user)).Token).toBe('jwt-2');
        expect(tokenCalls()).toHaveLength(2);
    });

    it('re-mints once on a 401 and replays the request with the fresh token', async () => {
        let n = 0;
        let dataCalls = 0;
        responder = call => {
            if (call.url.endsWith('/v2/tokens')) return jsonResponse(200, { access_token: `jwt-${++n}`, expires_in: 3600 });
            dataCalls++;
            return dataCalls === 1 ? jsonResponse(401, {}) : jsonResponse(200, { results: [] });
        };
        const connector = new RasaConnector() as unknown as Internals;
        const auth = await connector.Authenticate(companyIntegration(V2_CREDS), user);

        const res = await connector.MakeHTTPRequest(auth, `${HOST}/v2/lists`, 'GET', connector.BuildHeaders(auth));

        expect(res.Status).toBe(200);
        const replay = calls[calls.length - 1];
        expect(replay.headers.Authorization).toBe('Bearer jwt-2');
    });

    it('fails clearly, without leaking the secret, when the token endpoint rejects the client', async () => {
        responder = () => jsonResponse(401, { message: 'invalid client' });
        const connector = new RasaConnector() as unknown as Internals;
        const err = await connector.Authenticate(companyIntegration(V2_CREDS), user).catch((e: Error) => e);
        expect(String(err)).toContain('HTTP 401 from POST /v2/tokens');
        expect(String(err)).not.toContain('secret-xyz');
    });

    it('rejects a v1 credential with a pointer to the v2 client ID and secret', async () => {
        responder = () => jsonResponse(500, {});
        const connector = new RasaConnector() as unknown as Internals;
        const err = await connector
            .Authenticate(companyIntegration({ APIKey: 'k', Username: 'u@x.io', Password: 'p' }), user)
            .catch((e: Error) => e);
        expect(String(err)).toContain('need ClientId, ClientSecret');
        expect(String(err)).toContain('v1 credential');
        expect(calls).toHaveLength(0);
    });

    it('accepts snake_case credential keys', async () => {
        responder = () => jsonResponse(200, { access_token: 'jwt-1', expires_in: 3600 });
        const connector = new RasaConnector() as unknown as Internals;
        await connector.Authenticate(companyIntegration({ client_id: 'a', client_secret: 'b' }), user);
        expect(calls[0].body).toMatchObject({ client_id: 'a', client_secret: 'b' });
    });

    it("routes the token and every read to the credential form's optional API host", async () => {
        responder = call =>
            call.url.endsWith('/v2/tokens')
                ? jsonResponse(200, { access_token: 'jwt-1', expires_in: 3600 })
                : jsonResponse(200, { results: [] });
        const connector = new RasaConnector();
        // Credential-form key casing (`baseUrl`), typed without a scheme and with a trailing slash.
        const ci = { IntegrationID: 'int-1', CredentialID: null,
            Configuration: JSON.stringify({ clientId: 'a', clientSecret: 'b', baseUrl: ' api-dev.rasa.io/ ' }) } as never;

        await connector.TestConnection(ci, user);

        expect(calls.map(c => c.url)).toEqual([
            'https://api-dev.rasa.io/v2/tokens',
            'https://api-dev.rasa.io/v2/lists?limit=1',
        ]);
    });

    it('defaults to the production host when the API host is left blank', async () => {
        responder = () => jsonResponse(200, { access_token: 'jwt-1', expires_in: 3600 });
        const connector = new RasaConnector() as unknown as Internals;
        const ci = { IntegrationID: 'int-1', CredentialID: null,
            Configuration: JSON.stringify({ clientId: 'a', clientSecret: 'b', baseUrl: '' }) } as never;

        await connector.Authenticate(ci, user);

        expect(calls[0].url).toBe('https://api.rasa.io/v2/tokens');
    });

    it('TestConnection mints and reads GET /v2/lists', async () => {
        responder = call =>
            call.url.endsWith('/v2/tokens')
                ? jsonResponse(200, { access_token: 'jwt-1', expires_in: 3600 })
                : jsonResponse(200, { results: [] });
        const connector = new RasaConnector();

        const result = await connector.TestConnection(companyIntegration(V2_CREDS), user);

        expect(result.Success).toBe(true);
        const read = calls[1];
        expect(read.url).toBe(`${HOST}/v2/lists?limit=1`);
        expect(read.headers.Authorization).toBe('Bearer jwt-1');
    });
});
