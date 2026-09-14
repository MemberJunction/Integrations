/**
 * SFMCConnector — credential-free, NON-MUTATING unit suite (T4 mocked-fixture tier).
 *
 * Every vendor call is intercepted: the OAuth token round-trip by a stubbed `globalThis.fetch` that
 * replays the recorded `/v2/token` response (so `Authenticate` and the token-response-derived base-URI
 * logic run FOR REAL), and every REST/SOAP request by {@link MockedSFMCConnector}, which CAPTURES the
 * outbound URL / headers / body and replays a RECORDED vendor response through the connector's REAL
 * JSON and SOAP parsers. Nothing here touches a live endpoint and nothing mutates: the write-path tests
 * assert the exact request the connector WOULD send and the CRUDResult it derives from a recorded reply.
 *
 * Fixtures live at `packages/Integration/connectors-registry/sfmc/fixtures/` and every one descends from
 * the pinned vendor corpus under `packages/Integration/connectors-registry/sfmc/sources/` (per-file
 * provenance in `fixtures/fixtures.json` -> `_provenance`) — NEVER synthesised from the connector's own
 * metadata, which would make this suite circular.
 *
 * The engine cache is seeded from the REAL frozen metadata file, so every assertion about transport
 * markers, ObjectType tokens, `$`-prefixed page params, watermark fields and the per-operation
 * Create/Update/Delete columns is an assertion about the SHIPPED metadata, not a hand-written stub.
 */
import { describe, it, expect, beforeAll, beforeEach, afterEach, vi } from 'vitest';
import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import type { UserInfo } from '@memberjunction/core';
import type {
    MJCompanyIntegrationEntity,
    MJIntegrationEntity,
    MJIntegrationObjectEntity,
    MJIntegrationObjectFieldEntity,
} from '@memberjunction/core-entities';
import { IntegrationEngineBase } from '@memberjunction/integration-engine-base';
import type { FetchContext, RESTAuthContext, RESTResponse } from '@memberjunction/integration-engine';
import { SFMCConnector, SFMCRequestError, type SFMCAuthContext } from '../SFMCConnector.js';

// ─── Paths ───────────────────────────────────────────────────────────────────────────────────────

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(HERE, '../../../../..');
const METADATA_FILE = resolve(REPO_ROOT, 'metadata/integrations/sfmc/.sfmc.integration.json');
const FIXTURES = resolve(REPO_ROOT, 'packages/Integration/connectors-registry/sfmc/fixtures');
const CONNECTOR_SOURCE = resolve(HERE, '../SFMCConnector.ts');

const MOCK_ORIGIN = 'https://mock-sfmc.invalid';

const fixtureText = (name: string): string =>
    readFileSync(resolve(FIXTURES, name), 'utf-8').replace(/\{\{MOCK_ORIGIN\}\}/g, MOCK_ORIGIN);
const fixtureJson = (name: string): unknown => JSON.parse(fixtureText(name));

/** Strips block and line comments so a source-scan assertion reads CODE, not prose. */
const stripComments = (source: string): string =>
    source.replace(/\/\*[\s\S]*?\*\//g, '').replace(/(^|[^:])\/\/.*$/gm, '$1');

// ─── Metadata seeding (the same shape the offline tier harness seeds) ────────────────────────────

interface MetadataFieldRow { fields: Record<string, unknown> }
interface MetadataObjectRow { fields: Record<string, unknown>; relatedEntities?: Record<string, MetadataFieldRow[]> }
interface MetadataRoot { fields: Record<string, unknown>; relatedEntities?: Record<string, MetadataObjectRow[]> }

const INTEGRATION_ID = 'sfmc-test-integration';

/** Metadata `Configuration` columns are objects in the file but STRINGS on the entity — mirror that. */
function stringifyConfiguration(row: Record<string, unknown>): Record<string, unknown> {
    const out: Record<string, unknown> = { ...row };
    if (out.Configuration != null && typeof out.Configuration === 'object') out.Configuration = JSON.stringify(out.Configuration);
    for (const [k, v] of Object.entries(out)) {
        if (typeof v === 'string' && (v.startsWith('@lookup:') || v.startsWith('@parent:'))) out[k] = null;
    }
    if (out.Status == null) out.Status = 'Active';
    return out;
}

let metadataRoot: MetadataRoot;
let metadataObjects: MetadataObjectRow[] = [];

function seedEngine(companyIntegration: Partial<MJCompanyIntegrationEntity>): void {
    const integ = stringifyConfiguration(metadataRoot.fields) as Partial<MJIntegrationEntity>;
    (integ as Record<string, unknown>).ID = INTEGRATION_ID;
    const objects: Array<Partial<MJIntegrationObjectEntity>> = [];
    const fields: Array<Partial<MJIntegrationObjectFieldEntity>> = [];
    metadataObjects.forEach((row, i) => {
        const io = stringifyConfiguration(row.fields) as Partial<MJIntegrationObjectEntity>;
        (io as Record<string, unknown>).ID = `io-${i + 1}`;
        (io as Record<string, unknown>).IntegrationID = INTEGRATION_ID;
        objects.push(io);
        const iofRows = row.relatedEntities?.['MJ: Integration Object Fields'] ?? [];
        iofRows.forEach((fr, j) => {
            const iof = stringifyConfiguration(fr.fields) as Partial<MJIntegrationObjectFieldEntity>;
            (iof as Record<string, unknown>).ID = `iof-${i + 1}-${j + 1}`;
            (iof as Record<string, unknown>).IntegrationObjectID = `io-${i + 1}`;
            fields.push(iof);
        });
    });
    IntegrationEngineBase.Instance.SeedForTesting({
        Integrations: [integ],
        IntegrationObjects: objects,
        IntegrationObjectFields: fields,
        CompanyIntegrations: [companyIntegration],
    });
}

/** The Integration Object row straight out of the frozen metadata file (assertions read from it). */
function metadataObject(name: string): Record<string, unknown> {
    const row = metadataObjects.find(o => o.fields.Name === name);
    if (!row) throw new Error(`Integration Object "${name}" is not in the frozen metadata.`);
    return row.fields;
}

/** An IO's `Configuration` block as it appears in the frozen metadata file. */
function metadataConfig(name: string): Record<string, unknown> {
    const config = metadataObject(name).Configuration;
    return (config ?? {}) as Record<string, unknown>;
}

/** Credential-free connection: replay settings live in Configuration; CredentialID is null. */
function companyIntegration(overrides: Record<string, unknown> = {}): MJCompanyIntegrationEntity {
    const configuration = JSON.stringify({
        Subdomain: 'replay-subdomain',
        ClientID: 'replay-only-not-a-real-client-id',
        ClientSecret: 'replay-only-not-a-real-secret',
        AccountID: '0000000',
        AuthBaseURL: MOCK_ORIGIN,
        ...overrides,
    });
    const row: Partial<MJCompanyIntegrationEntity> = {
        ID: `ci-${Math.random().toString(36).slice(2)}`,
        IntegrationID: INTEGRATION_ID,
        CredentialID: null,
        Configuration: configuration,
    };
    return row as MJCompanyIntegrationEntity;
}

const CONTEXT_USER = {} as UserInfo;

// ─── Mocked transport ────────────────────────────────────────────────────────────────────────────

interface CapturedRequest {
    URL: string;
    Method: string;
    Headers: Record<string, string>;
    /** The exact outbound SOAP envelope, when the request was a SOAP call. */
    Envelope: string | null;
    /** The ObjectType the SOAP request addressed. */
    ObjectType: string | null;
    /** The exact outbound JSON body, when the request was a REST write. */
    JSONBody: unknown;
}

interface CannedResponse {
    Status: number;
    /** A recorded SOAP envelope — parsed by the connector's REAL ParseSoapResponse. */
    Xml?: string;
    /** A recorded JSON body. */
    Json?: unknown;
    Headers?: Record<string, string>;
}

/**
 * Captures every outbound request and replays a RECORDED response through the connector's real
 * parsing. Responses are consumed in order; the last one repeats, so a paginating loop can be driven
 * with exactly as many recordings as there are pages.
 */
class MockedSFMCConnector extends SFMCConnector {
    public readonly Requests: CapturedRequest[] = [];
    public Responses: CannedResponse[] = [];
    private cursor = 0;

    public Enqueue(...responses: CannedResponse[]): this {
        this.Responses = responses;
        this.cursor = 0;
        return this;
    }

    protected override async MakeHTTPRequest(
        auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown,
    ): Promise<RESTResponse> {
        const soap = this.CapturedSoap(body);
        this.Requests.push({
            URL: url,
            Method: method,
            Headers: headers,
            Envelope: soap?.Envelope ?? null,
            ObjectType: soap?.ObjectType ?? null,
            JSONBody: soap ? null : body ?? null,
        });
        const canned = this.Responses[Math.min(this.cursor, this.Responses.length - 1)];
        this.cursor++;
        if (!canned) throw new Error(`MockedSFMCConnector: no canned response for ${method} ${url}`);
        if (canned.Xml !== undefined) {
            return this.ParseSoapResponse(canned.Xml, canned.Status, canned.Headers ?? {});
        }
        return { Status: canned.Status, Body: canned.Json ?? null, Headers: canned.Headers ?? {} };
    }

    private CapturedSoap(body: unknown): { Envelope: string; ObjectType: string } | null {
        if (typeof body !== 'object' || body === null) return null;
        const rec = body as Record<string, unknown>;
        if (typeof rec.Envelope !== 'string') return null;
        return { Envelope: rec.Envelope, ObjectType: typeof rec.ObjectType === 'string' ? rec.ObjectType : '' };
    }
}

/** Installs a `globalThis.fetch` stub that answers ONLY the recorded `/v2/token` endpoint. */
function stubTokenEndpoint(): { calls: Array<{ url: string; body: string }> } {
    const calls: Array<{ url: string; body: string }> = [];
    const tokenBody = fixtureText('auth/token.json');
    vi.stubGlobal('fetch', async (input: string | URL, init?: RequestInit): Promise<Response> => {
        const url = String(input);
        if (!url.includes('/v2/token')) throw new Error(`Unexpected live fetch in a credential-free suite: ${url}`);
        calls.push({ url, body: typeof init?.body === 'string' ? init.body : '' });
        return new Response(tokenBody, { status: 200, headers: { 'content-type': 'application/json' } });
    });
    return { calls };
}

/** A fetch context with the standard credential-free connection. */
function fetchContext(objectName: string, overrides: Partial<FetchContext> = {}): FetchContext {
    return {
        CompanyIntegration: companyIntegration(),
        ObjectName: objectName,
        WatermarkValue: null,
        BatchSize: 5000,
        ContextUser: CONTEXT_USER,
        ...overrides,
    };
}

beforeAll(() => {
    metadataRoot = (JSON.parse(readFileSync(METADATA_FILE, 'utf-8')) as MetadataRoot[])[0];
    // ACTIVE rows only — the catalog also carries objects deliberately retired from the read surface
    // (the three SOAP write-RESPONSE payload types, `Status='Deprecated'`, which extend CreateResult /
    // UpdateResult and are not members of the retrievable object set). The connector must NOT discover
    // those, so the expected discovery set is the Active subset, not every row in the file.
    const allObjects = metadataRoot.relatedEntities?.['MJ: Integration Objects'] ?? [];
    metadataObjects = allObjects.filter(o => ((o.fields.Status as string | undefined) ?? 'Active') === 'Active');
});

beforeEach(() => {
    seedEngine(companyIntegration());
    stubTokenEndpoint();
});

afterEach(() => {
    vi.unstubAllGlobals();
});

// ═════════════════════════════════════════════════════════════════════════════════════════════════
describe('SFMCConnector — identity + capability invariants', () => {
// ═════════════════════════════════════════════════════════════════════════════════════════════════

    it('IntegrationName is the verbatim MJ: Integrations.Name from the frozen metadata', () => {
        expect(new SFMCConnector().IntegrationName).toBe(metadataRoot.fields.Name);
        expect(new SFMCConnector().IntegrationName).toBe('sfmc');
    });

    it('the class symbol matches the metadata ClassName (the three-way identity invariant)', () => {
        expect(SFMCConnector.name).toBe(metadataRoot.fields.ClassName);
    });

    it('declares the write capabilities the metadata actually carries', () => {
        const writeCapable = metadataObjects.filter(o => o.fields.SupportsCreate || o.fields.SupportsUpdate || o.fields.SupportsDelete);
        expect(writeCapable.length).toBeGreaterThan(0);
        const connector = new SFMCConnector();
        expect(connector.SupportsCreate).toBe(true);
        expect(connector.SupportsUpdate).toBe(true);
        expect(connector.SupportsDelete).toBe(true);
    });

    it('never claims authoritative discovery (nothing may be deactivated from a discovery absence)', () => {
        expect(new SFMCConnector().DiscoveryIsAuthoritative).toBe(false);
        const integrationConfig = metadataRoot.fields.Configuration as Record<string, unknown>;
        expect(integrationConfig.DiscoveryIsAuthoritative).toBe(false);
    });

    it('declares NO rate-limit policy, because the vendor publishes no numeric limit', () => {
        expect(new SFMCConnector().RateLimitPolicy).toBeNull();
        expect(new SFMCConnector().MaxConcurrencyHint).toBeNull();
    });

    it('returns the declared StableOrderingKey for an object it has seen', async () => {
        const connector = new MockedSFMCConnector().Enqueue({ Status: 200, Json: {} });
        await connector.DiscoverObjects(companyIntegration(), CONTEXT_USER);
        const declared = metadataObject('Application').StableOrderingKey;
        expect(connector.StableOrderingKey('Application')).toBe(declared);
        expect(connector.StableOrderingKey('Account')).toBeNull(); // metadata declares none
    });

    it('bakes NO tenant host, subdomain, MID or account id into the connector source', () => {
        // Scan CODE only — the class doc-comment legitimately NAMES the neighbouring-product hosts in
        // order to forbid them, and a naive whole-file scan would flag that prose as a violation.
        const source = stripComments(readFileSync(CONNECTOR_SOURCE, 'utf-8'));
        // Every marketingcloudapis host must be the {subdomain} TEMPLATE, never a concrete tenant.
        for (const match of source.matchAll(/https:\/\/([A-Za-z0-9{}_.-]+)\.(auth|rest|soap)\.marketingcloudapis\.com/g)) {
            expect(match[1]).toBe('{subdomain}');
        }
        // The neighbouring-product hosts must not appear at all.
        expect(source).not.toMatch(/api\.salesforce\.com/);
        expect(source).not.toMatch(/pi\.pardot\.com/);
        expect(source).not.toMatch(/services\/data/);
        // A 28-char SFMC tenant subdomain shape must not be hardcoded anywhere.
        expect(source).not.toMatch(/\bmc[a-z0-9]{16,}\b/);
    });

    it('carries no module-level object/field catalog (catalogs live in metadata, not code)', () => {
        const source = readFileSync(CONNECTOR_SOURCE, 'utf-8');   // comments included: a catalog in a comment is still a smell
        expect(source).not.toMatch(/^const\s+\w*(FIELD|OBJECT|STREAM|CATALOG|SCHEMA)\w*\s*(:|=)\s*[[{]/m);
        // DiscoverObjects must AWAIT a runtime enumeration, not return a frozen array.
        const discoverBody = source.slice(source.indexOf('public override async DiscoverObjects'));
        expect(discoverBody.slice(0, 1600)).toMatch(/await this\.EnumerateDataExtensions\(/);
    });
});

// ═════════════════════════════════════════════════════════════════════════════════════════════════
describe('SFMCConnector — auth + token-response-derived base URIs', () => {
// ═════════════════════════════════════════════════════════════════════════════════════════════════

    it('POSTs a client_credentials grant to {auth host}/v2/token with account_id when configured', async () => {
        const stub = stubTokenEndpoint();
        const connector = new MockedSFMCConnector();
        const result = await connector.TestConnection(companyIntegration(), CONTEXT_USER);

        expect(result.Success).toBe(true);
        expect(stub.calls).toHaveLength(1);
        expect(stub.calls[0].url).toBe(`${MOCK_ORIGIN}/v2/token`);
        const form = new URLSearchParams(stub.calls[0].body);
        expect(form.get('grant_type')).toBe('client_credentials');
        expect(form.get('client_id')).toBe('replay-only-not-a-real-client-id');
        expect(form.get('client_secret')).toBe('replay-only-not-a-real-secret');
        expect(form.get('account_id')).toBe('0000000');
    });

    it('omits account_id and scope when the connection does not configure them', async () => {
        const stub = stubTokenEndpoint();
        const ci = companyIntegration({ AccountID: undefined, Scope: undefined });
        // Rebuild without the keys entirely (undefined would serialize away, but be explicit).
        const config = JSON.parse(ci.Configuration as string) as Record<string, unknown>;
        delete config.AccountID;
        (ci as { Configuration: string }).Configuration = JSON.stringify(config);

        await new MockedSFMCConnector().TestConnection(ci, CONTEXT_USER);
        const form = new URLSearchParams(stub.calls[0].body);
        expect(form.get('account_id')).toBeNull();
        expect(form.get('scope')).toBeNull();
    });

    it('takes the REST and SOAP base URIs from the TOKEN RESPONSE, not from code', async () => {
        stubTokenEndpoint();
        const connector = new MockedSFMCConnector().Enqueue({ Status: 200, Xml: fixtureText('soap/subscriber-batch2.soap.xml') });
        await connector.FetchChanges(fetchContext('Subscriber'));
        // rest_instance_url / soap_instance_url in the recorded token body both point at the mock origin,
        // and the SOAP door is appended because the instance URL names the host, not Service.asmx.
        expect(connector.Requests[0].URL).toBe(`${MOCK_ORIGIN}/Service.asmx`);
    });

    it('falls back to the documented {subdomain} template when the token response omits instance URLs', async () => {
        vi.stubGlobal('fetch', async (): Promise<Response> => new Response(
            JSON.stringify({ access_token: 'no-instance-urls', token_type: 'Bearer', expires_in: 1079 }),
            { status: 200, headers: { 'content-type': 'application/json' } },
        ));
        const connector = new MockedSFMCConnector().Enqueue({ Status: 200, Xml: fixtureText('soap/subscriber-batch2.soap.xml') });
        await connector.FetchChanges(fetchContext('Subscriber'));
        expect(connector.Requests[0].URL).toBe('https://replay-subdomain.soap.marketingcloudapis.com/Service.asmx');
    });

    it('sends the bearer token on REST and the <fueloauth> SOAP header on SOAP — never both', async () => {
        const connector = new MockedSFMCConnector().Enqueue(
            { Status: 200, Json: fixtureJson('rest/campaigns-page2.json') },
        );
        await connector.FetchChanges(fetchContext('Campaign', { BatchSize: 2 }));
        expect(connector.Requests[0].Headers.Authorization).toBe('Bearer REPLAY-ONLY-NOT-A-REAL-TOKEN');

        const soapConnector = new MockedSFMCConnector().Enqueue({ Status: 200, Xml: fixtureText('soap/subscriber-batch2.soap.xml') });
        await soapConnector.FetchChanges(fetchContext('Subscriber'));
        expect(soapConnector.Requests[0].Headers.Authorization).toBeUndefined();
        expect(soapConnector.Requests[0].Headers.SOAPAction).toBe('Retrieve');
        expect(soapConnector.Requests[0].Envelope).toContain('<fueloauth>REPLAY-ONLY-NOT-A-REAL-TOKEN</fueloauth>');
    });

    it('scrubs the bearer token out of any surfaced message', () => {
        const connector = new SFMCConnector();
        expect(connector.ScrubSecrets('failed with Authorization: Bearer abc.def-123')).toBe('failed with Authorization: Bearer ***');
        expect(connector.ScrubSecrets('<fueloauth>abc123</fueloauth>')).toBe('<fueloauth>***</fueloauth>');
        expect(connector.ScrubSecrets('client_secret=shhh&grant_type=x')).toBe('client_secret=***&grant_type=x');
    });
});

// ═════════════════════════════════════════════════════════════════════════════════════════════════
describe('SFMCConnector — transport dispatch is metadata-driven', () => {
// ═════════════════════════════════════════════════════════════════════════════════════════════════

    it('routes every active object by its declared Configuration.transport, never by a hardcoded list', () => {
        const connector = new SFMCConnector();
        let soap = 0;
        let rest = 0;
        for (const row of metadataObjects) {
            const name = row.fields.Name as string;
            const declared = (row.fields.Configuration as Record<string, unknown>).transport;
            const io = IntegrationEngineBase.Instance.GetIntegrationObject(INTEGRATION_ID, name);
            expect(io, `IO ${name} should be seeded`).toBeTruthy();
            expect(connector.ResolveTransport(io as MJIntegrationObjectEntity)).toBe(declared);
            if (declared === 'soap') soap++; else rest++;
        }
        expect(soap).toBeGreaterThan(0);
        expect(rest).toBeGreaterThan(0);
        expect(soap + rest).toBe(metadataObjects.length);
    });

    it('routes a runtime-DISCOVERED Data Extension (no transport marker of its own) to SOAP', () => {
        const connector = new SFMCConnector();
        const discovered = { Name: 'DataExtensionObject[Airlines]', APIPath: '/Service.asmx', Configuration: null } as unknown as MJIntegrationObjectEntity;
        expect(connector.ResolveTransport(discovered)).toBe('soap');
    });

    it('takes the SOAP ObjectType from the declared soapObjectType, never from the IO name alone', () => {
        const connector = new SFMCConnector();
        const io = IntegrationEngineBase.Instance.GetIntegrationObject(INTEGRATION_ID, 'SentEvent') as MJIntegrationObjectEntity;
        expect(connector.SoapObjectTypeFor(io)).toBe(metadataConfig('SentEvent').soapObjectType);
    });
});

// ═════════════════════════════════════════════════════════════════════════════════════════════════
describe('SFMCConnector — SOAP envelope construction', () => {
// ═════════════════════════════════════════════════════════════════════════════════════════════════

    it('builds a RetrieveRequestMsg with ObjectType, the declared Properties, and no Filter when no watermark', async () => {
        const connector = new MockedSFMCConnector().Enqueue({ Status: 200, Xml: fixtureText('soap/subscriber-batch2.soap.xml') });
        await connector.FetchChanges(fetchContext('Subscriber'));
        const envelope = connector.Requests[0].Envelope ?? '';

        expect(envelope).toContain('<par:RetrieveRequestMsg>');
        expect(envelope).toContain('<par:ObjectType>Subscriber</par:ObjectType>');
        expect(envelope).toContain('<par:Properties>SubscriberKey</par:Properties>');
        expect(envelope).toContain('<par:Properties>EmailAddress</par:Properties>');
        expect(envelope).not.toContain('<par:Filter');
        expect(envelope).not.toContain('<par:ContinueRequest>');
    });

    it('omits complex (json-typed) declared members from Properties — the API rejects a non-scalar request', async () => {
        const connector = new MockedSFMCConnector().Enqueue({ Status: 200, Xml: fixtureText('soap/subscriber-batch2.soap.xml') });
        await connector.FetchChanges(fetchContext('Subscriber'));
        const envelope = connector.Requests[0].Envelope ?? '';

        const declaredFields = metadataObjects.find(o => o.fields.Name === 'Subscriber')?.relatedEntities?.['MJ: Integration Object Fields'] ?? [];
        const jsonTyped = declaredFields.filter(f => f.fields.Type === 'json').map(f => f.fields.Name as string);
        const scalar = declaredFields.filter(f => f.fields.Type !== 'json').map(f => f.fields.Name as string);
        expect(jsonTyped.length).toBeGreaterThan(0);
        for (const name of jsonTyped) expect(envelope).not.toContain(`<par:Properties>${name}</par:Properties>`);
        for (const name of scalar) expect(envelope).toContain(`<par:Properties>${name}</par:Properties>`);
    });

    it('emits the declared SimpleFilterPart date filter when a watermark exists', async () => {
        const connector = new MockedSFMCConnector().Enqueue({ Status: 200, Xml: fixtureText('soap/subscriber-batch2.soap.xml') });
        await connector.FetchChanges(fetchContext('Subscriber', { WatermarkValue: '2018-03-01T00:00:00.000Z' }));
        const envelope = connector.Requests[0].Envelope ?? '';

        const declaredWatermark = metadataObject('Subscriber').IncrementalWatermarkField as string;
        expect(declaredWatermark).toBe('ModifiedDate');
        expect(envelope).toContain('<par:Filter xsi:type="par:SimpleFilterPart">');
        expect(envelope).toContain(`<par:Property>${declaredWatermark}</par:Property>`);
        expect(envelope).toContain('<par:SimpleOperator>greaterThan</par:SimpleOperator>');
        expect(envelope).toContain('<par:DateValue>2018-03-01T00:00:00.000Z</par:DateValue>');
        // The declared filter format in metadata is the shape the connector emits.
        expect(String(metadataConfig('Subscriber').incrementalFilterFormat)).toContain('SimpleFilterPart');
    });

    it('passes an ISO watermark through VERBATIM — no timezone offset is ever assumed', () => {
        const connector = new SFMCConnector();
        expect(connector.FormatWatermark('2018-03-01T08:15:44.000')).toBe('2018-03-01T08:15:44.000');
        expect(connector.FormatWatermark('2018-03-01T08:15:44.000Z')).toBe('2018-03-01T08:15:44.000Z');
        expect(connector.FormatWatermark('1519891200000')).toBe(new Date(1519891200000).toISOString());
    });

    it('emits NO filter for an object that declares no watermark — a full scan, never an invented delta', async () => {
        const connector = new MockedSFMCConnector().Enqueue({ Status: 200, Json: fixtureJson('rest/campaigns-page2.json') });
        expect(metadataObject('Campaign').IncrementalWatermarkField).toBeNull();
        expect(metadataObject('Campaign').SupportsIncrementalSync).toBe(false);
        await connector.FetchChanges(fetchContext('Campaign', { WatermarkValue: '2020-01-01T00:00:00Z', BatchSize: 2 }));
        expect(connector.Requests[0].URL).not.toContain('$filter');
    });
});

// ═════════════════════════════════════════════════════════════════════════════════════════════════
describe('SFMCConnector — SOAP pagination (ContinueRequest continuation)', () => {
// ═════════════════════════════════════════════════════════════════════════════════════════════════

    it('re-issues ContinueRequest with the returned RequestID until OverallStatus stops saying MoreDataAvailable', async () => {
        const connector = new MockedSFMCConnector().Enqueue(
            { Status: 200, Xml: fixtureText('soap/subscriber-batch1.soap.xml') },  // MoreDataAvailable + RequestID
            { Status: 200, Xml: fixtureText('soap/subscriber-batch2.soap.xml') },  // terminal
        );
        const result = await connector.FetchChanges(fetchContext('Subscriber'));

        expect(connector.Requests).toHaveLength(2);
        expect(connector.Requests[0].Envelope).not.toContain('<par:ContinueRequest>');
        expect(connector.Requests[1].Envelope).toContain('<par:ContinueRequest>a5d36471-e636-478c-a29b-fd3571714602</par:ContinueRequest>');
        // The continuation still names the ObjectType, as every vendor sample does.
        expect(connector.Requests[1].Envelope).toContain('<par:ObjectType>Subscriber</par:ObjectType>');
        // Both batches are accumulated — a single Retrieve would have capped this object at 2 records.
        expect(result.Records).toHaveLength(3);
        expect(result.HasMore).toBe(false);
    });

    it('yields back to the engine with the RequestID as NextCursor when BatchSize is reached mid-stream', async () => {
        const connector = new MockedSFMCConnector().Enqueue(
            { Status: 200, Xml: fixtureText('soap/subscriber-batch1.soap.xml') },
        );
        const result = await connector.FetchChanges(fetchContext('Subscriber', { BatchSize: 2 }));

        expect(connector.Requests).toHaveLength(1);
        expect(result.HasMore).toBe(true);
        expect(result.NextCursor).toBe('a5d36471-e636-478c-a29b-fd3571714602');
    });

    it('RESUMES from the engine-supplied cursor instead of re-issuing the first Retrieve', async () => {
        const connector = new MockedSFMCConnector().Enqueue(
            { Status: 200, Xml: fixtureText('soap/subscriber-batch2.soap.xml') },
        );
        await connector.FetchChanges(fetchContext('Subscriber', { CurrentCursor: 'a5d36471-e636-478c-a29b-fd3571714602' }));
        expect(connector.Requests[0].Envelope).toContain('<par:ContinueRequest>a5d36471-e636-478c-a29b-fd3571714602</par:ContinueRequest>');
    });

    it('advances the watermark to the max ModifiedDate seen across ALL batches', async () => {
        const connector = new MockedSFMCConnector().Enqueue(
            { Status: 200, Xml: fixtureText('soap/subscriber-batch1.soap.xml') },
            { Status: 200, Xml: fixtureText('soap/subscriber-batch2.soap.xml') },
        );
        const result = await connector.FetchChanges(fetchContext('Subscriber'));
        expect(result.NewWatermarkValue).toBe('2018-03-02T07:04:31.000');
    });

    it('does NOT return a watermark when a batch fails mid-iteration (partial-failure semantics)', async () => {
        const connector = new MockedSFMCConnector().Enqueue(
            { Status: 200, Xml: fixtureText('soap/subscriber-batch1.soap.xml') },
            { Status: 500, Xml: fixtureText('soap/fault-rate-limited-500.soap.xml') },
        );
        await expect(connector.FetchChanges(fetchContext('Subscriber'))).rejects.toBeInstanceOf(SFMCRequestError);
        // The throw is the point: no FetchBatchResult is produced, so the engine persists no watermark.
        expect(connector.Requests).toHaveLength(2);
    });
});

// ═════════════════════════════════════════════════════════════════════════════════════════════════
describe('SFMCConnector — REST pagination ($-prefixed params, per-endpoint page cap)', () => {
// ═════════════════════════════════════════════════════════════════════════════════════════════════

    it('walks >=2 pages using the $-prefixed params the metadata records (NOT the unprefixed table form)', async () => {
        const connector = new MockedSFMCConnector().Enqueue(
            { Status: 200, Json: fixtureJson('rest/campaigns-page1.json') },   // links.next present
            { Status: 200, Json: fixtureJson('rest/campaigns-page2.json') },   // terminal
        );
        const result = await connector.FetchChanges(fetchContext('Campaign'));

        expect(connector.Requests).toHaveLength(2);
        expect(connector.Requests[0].URL).toContain('$page=1');
        expect(connector.Requests[0].URL).toContain('$pageSize=');
        expect(connector.Requests[1].URL).toContain('$page=2');
        // The vendor's parameter TABLE documents page/pageSize; its EXAMPLE sends $page/$pageSize.
        expect(connector.Requests[0].URL).not.toMatch(/[?&]page=/);
        expect(connector.Requests[0].URL).not.toMatch(/[?&]pageSize=/);
        expect(result.Records).toHaveLength(3);
        expect(result.HasMore).toBe(false);
    });

    it('honours the PER-ENDPOINT page-size maximum the metadata records (campaigns caps at 50)', async () => {
        const declaredMax = (metadataConfig('Campaign').pagination as Record<string, unknown>).pageSizeMax;
        expect(declaredMax).toBe(50);

        const connector = new MockedSFMCConnector().Enqueue({ Status: 200, Json: fixtureJson('rest/campaigns-page2.json') });
        await connector.FetchChanges(fetchContext('Campaign', { BatchSize: 5000 }));
        const url = new URL(connector.Requests[0].URL);
        expect(Number(url.searchParams.get('$pageSize'))).toBeLessThanOrEqual(50);
    });

    it('reads the page-param NAMES off each IO rather than assuming one spelling', () => {
        const connector = new SFMCConnector();
        const category = IntegrationEngineBase.Instance.GetIntegrationObject(INTEGRATION_ID, 'Category') as MJIntegrationObjectEntity;
        const declared = ((metadataConfig('Category').pagination as Record<string, unknown>).params ?? []) as string[];
        expect(declared).toContain('$pagesize'); // the vendor spells this endpoint's param lowercase
        const params = connector.RestPageParamsFor(category);
        expect(declared).toContain(params.SizeParam);
        expect(params.PageParam).toBe('$page');
    });

    it('stops on a SHORT page when the envelope declares nothing about paging', async () => {
        const connector = new MockedSFMCConnector().Enqueue(
            { Status: 200, Json: { items: [{ id: '1' }] } },     // 1 row, no links/count → short page
        );
        const result = await connector.FetchChanges(fetchContext('Interaction'));
        expect(connector.Requests).toHaveLength(1);
        expect(result.HasMore).toBe(false);
    });

    it('issues exactly ONE request for a non-paginating single-record resource', async () => {
        expect(metadataObject('AttributeSetDefinition').SupportsPagination).toBe(false);
        const connector = new MockedSFMCConnector().Enqueue({ Status: 200, Json: { id: 'asd-1', name: 'Email Addresses' } });
        const ci = companyIntegration({ pathParams: { id: 'asd-1' } });
        const result = await connector.FetchChanges({ ...fetchContext('AttributeSetDefinition'), CompanyIntegration: ci });
        expect(connector.Requests).toHaveLength(1);
        expect(connector.Requests[0].URL).toContain('/contacts/v1/attributeSetDefinitions/asd-1');
        expect(result.Records).toHaveLength(1);
    });

    it('emits a PATH_PARAMS_UNRESOLVED warning and fires NO request when a :param has no value', async () => {
        const connector = new MockedSFMCConnector().Enqueue({ Status: 200, Json: {} });
        const result = await connector.FetchChanges(fetchContext('MessageContactDelivery'));
        expect(connector.Requests).toHaveLength(0);
        expect(result.Records).toHaveLength(0);
        expect(result.Warnings?.[0].Code).toBe('PATH_PARAMS_UNRESOLVED');
        expect(result.Warnings?.[0].Message).toContain('messageId');
    });

    it('appends the DECLARED REST $filter once a watermark exists', async () => {
        const declaredFormat = metadataConfig('Definition').incrementalFilterFormat as string;
        expect(declaredFormat).toContain('$filter');

        const connector = new MockedSFMCConnector().Enqueue({ Status: 200, Json: { definitions: [], count: 0, page: 1, pageSize: 50 } });
        await connector.FetchChanges(fetchContext('Definition', { WatermarkValue: '2024-01-01T00:00:00Z' }));
        const url = new URL(connector.Requests[0].URL);
        const filter = url.searchParams.get('$filter');
        expect(filter).toBe(`${metadataObject('Definition').IncrementalWatermarkField} gt '2024-01-01T00:00:00Z'`);
    });
});

// ═════════════════════════════════════════════════════════════════════════════════════════════════
describe('SFMCConnector — SOAP response parsing + full-record pass-through', () => {
// ═════════════════════════════════════════════════════════════════════════════════════════════════

    it('parses a RetrieveResponseMsg prefix-agnostically and maps xsi:nil to null', async () => {
        const connector = new MockedSFMCConnector().Enqueue({ Status: 200, Xml: fixtureText('soap/subscriber-batch1.soap.xml') });
        const result = await connector.FetchChanges(fetchContext('Subscriber', { BatchSize: 2 }));

        const first = result.Records[0].Fields;
        expect(first.SubscriberKey).toBe('acruz@example.com');
        expect(first.Status).toBe('Active');
        expect(first.PartnerKey).toBeNull();          // <par:PartnerKey xsi:nil="true"/>
        expect(first.ModifiedDate).toBe('2018-03-01T08:15:44.000');
    });

    it('hoists Subscriber Attributes{Name,Value} so a TENANT profile attribute reaches Fields', async () => {
        const connector = new MockedSFMCConnector().Enqueue({ Status: 200, Xml: fixtureText('soap/subscriber-batch1.soap.xml') });
        const result = await connector.FetchChanges(fetchContext('Subscriber', { BatchSize: 2 }));

        const fields = result.Records[0].Fields;
        // Neither attribute is a DECLARED Subscriber field — they are tenant profile attributes.
        const declared = (metadataObjects.find(o => o.fields.Name === 'Subscriber')?.relatedEntities?.['MJ: Integration Object Fields'] ?? [])
            .map(f => f.fields.Name as string);
        expect(declared).not.toContain('First Name');
        expect(fields['First Name']).toBe('Angela');
        expect(fields['Last Name']).toBe('Cruz');
        // The original nested container is preserved too — nothing from the source is dropped.
        expect(fields.Attributes).toBeTruthy();
    });

    it('does NOT let a hoisted pair clobber an envelope member of the same name', () => {
        const connector = new SFMCConnector();
        const parsed = connector.ParseSoapResponse(
            `<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:par="http://exacttarget.com/wsdl/partnerAPI">
               <soap:Body><par:RetrieveResponseMsg><par:OverallStatus>OK</par:OverallStatus>
                 <par:Results><par:CustomerKey>envelope-key</par:CustomerKey>
                   <par:Properties><par:Property><par:Name>CustomerKey</par:Name><par:Value>row-value</par:Value></par:Property></par:Properties>
                 </par:Results>
               </par:RetrieveResponseMsg></soap:Body>
             </soap:Envelope>`,
            200, {},
        );
        const records = connector.NormalizeResponse(parsed.Body, null);
        expect(records[0].CustomerKey).toBe('envelope-key');
    });

    it('passes an UNDECLARED tenant Data-Extension column straight through to ExternalRecord.Fields', async () => {
        const connector = new MockedSFMCConnector().Enqueue(
            { Status: 200, Xml: fixtureText('soap/dataextensionfield-airlines.soap.xml') },     // column discovery
            { Status: 200, Xml: fixtureText('soap/dataextensionobject-airlines-rows.soap.xml') }, // the rowset
        );
        const result = await connector.FetchChanges(fetchContext('DataExtensionObject[Airlines]'));

        expect(result.Records).toHaveLength(2);
        const fields = result.Records[0].Fields;
        expect(fields['IATA-Code']).toBe('AA');
        expect(fields.Loyalty_Tier__c).toBe('Platinum');
        // Tenant_Promo_Segment__c is in NO declared metadata and NO discovery result — if the connector
        // filtered to a known column set this would be gone, and the capture gate would pass vacuously.
        expect(fields.Tenant_Promo_Segment__c).toBe('SPRING-FLYER-2024');
        const declaredNames = metadataObjects.flatMap(o => (o.relatedEntities?.['MJ: Integration Object Fields'] ?? []).map(f => f.fields.Name as string));
        expect(declaredNames).not.toContain('Tenant_Promo_Segment__c');
    });

    it('addresses a Data Extension rowset by its key and requests the DISCOVERED columns', async () => {
        const connector = new MockedSFMCConnector().Enqueue(
            { Status: 200, Xml: fixtureText('soap/dataextensionfield-airlines.soap.xml') },
            { Status: 200, Xml: fixtureText('soap/dataextensionobject-airlines-rows.soap.xml') },
        );
        await connector.FetchChanges(fetchContext('DataExtensionObject[Airlines]'));

        expect(connector.Requests[0].Envelope).toContain('<par:ObjectType>DataExtensionField</par:ObjectType>');
        expect(connector.Requests[0].Envelope).toContain('<par:Property>DataExtension.CustomerKey</par:Property>');
        const rowRequest = connector.Requests[1].Envelope ?? '';
        expect(rowRequest).toContain('<par:ObjectType>DataExtensionObject[Airlines]</par:ObjectType>');
        expect(rowRequest).toContain('<par:Properties>IATA-Code</par:Properties>');
        expect(rowRequest).toContain('<par:Properties>Loyalty_Tier__c</par:Properties>');
    });
});

// ═════════════════════════════════════════════════════════════════════════════════════════════════
describe('SFMCConnector — identity stability across passes', () => {
// ═════════════════════════════════════════════════════════════════════════════════════════════════

    it('keys a record on the DECLARED primary key when every component is present', async () => {
        const connector = new MockedSFMCConnector().Enqueue({ Status: 200, Xml: fixtureText('soap/subscriber-batch1.soap.xml') });
        const result = await connector.FetchChanges(fetchContext('Subscriber', { BatchSize: 2 }));
        const declaredPk = (metadataObjects.find(o => o.fields.Name === 'Subscriber')?.relatedEntities?.['MJ: Integration Object Fields'] ?? [])
            .filter(f => f.fields.IsPrimaryKey).map(f => f.fields.Name as string);
        expect(declaredPk).toEqual(['ObjectID']);
        expect(result.Records[0].ExternalID).toBe('9f2c1b08-0f06-4f4e-9b2f-6bb9d3f0a001');
    });

    it('content-hashes a row whose declared PK the source leaves empty, and REPEATS it across passes', async () => {
        const run = async (): Promise<string[]> => {
            const connector = new MockedSFMCConnector().Enqueue(
                { Status: 200, Xml: fixtureText('soap/dataextensionfield-airlines.soap.xml') },
                { Status: 200, Xml: fixtureText('soap/dataextensionobject-airlines-rows.soap.xml') },
            );
            const result = await connector.FetchChanges(fetchContext('DataExtensionObject[Airlines]'));
            return result.Records.map(r => r.ExternalID);
        };
        const first = await run();
        const second = await run();
        expect(first).toEqual(second);            // stable across passes — no duplicate growth on re-sync
        expect(new Set(first).size).toBe(2);       // and distinct per row
        expect(first[0]).not.toBe('');
    });

    it('keeps the tracking-event objects keyed on their declared PK so a re-sync cannot duplicate them', async () => {
        // SentEvent's declared PK is ObjectID; the fixture supplies it, so identity is the PK, not a hash.
        const declaredPk = (metadataObjects.find(o => o.fields.Name === 'SentEvent')?.relatedEntities?.['MJ: Integration Object Fields'] ?? [])
            .filter(f => f.fields.IsPrimaryKey).map(f => f.fields.Name as string);
        expect(declaredPk).toEqual(['ObjectID']);

        const xml = fixtureText('objects/soap/SentEvent.soap.xml');
        const first = new MockedSFMCConnector().Enqueue({ Status: 200, Xml: xml });
        const second = new MockedSFMCConnector().Enqueue({ Status: 200, Xml: xml });
        const a = await first.FetchChanges(fetchContext('SentEvent'));
        const b = await second.FetchChanges(fetchContext('SentEvent'));
        expect(a.Records.map(r => r.ExternalID)).toEqual(b.Records.map(r => r.ExternalID));
        expect(a.Records[0].ExternalID).toBe(a.Records[0].Fields.ObjectID);
    });
});

// ═════════════════════════════════════════════════════════════════════════════════════════════════
describe('SFMCConnector — error classification (throttle-shaped HTTP 500 is the headline case)', () => {
// ═════════════════════════════════════════════════════════════════════════════════════════════════

    it('classifies the vendor’s HTTP 500 SOAP throttle fault as RETRYABLE, not fatal', async () => {
        const connector = new MockedSFMCConnector().Enqueue({ Status: 500, Xml: fixtureText('soap/fault-rate-limited-500.soap.xml') });
        const error = await connector.FetchChanges(fetchContext('Subscriber')).catch((e: unknown) => e);

        expect(error).toBeInstanceOf(SFMCRequestError);
        const typed = error as SFMCRequestError;
        expect(typed.Status).toBe(500);
        expect(typed.Transport).toBe('soap');
        expect(typed.VendorCode).toBe('17');
        expect(typed.SyncCode).toBe('RATE_LIMIT_EXCEEDED');
    });

    it('does NOT treat every SOAP 500 as a throttle — a non-throttle fault stays fatal', async () => {
        const connector = new MockedSFMCConnector().Enqueue({ Status: 500, Xml: fixtureText('soap/fault-invalid-token.soap.xml') });
        const error = await connector.FetchChanges(fetchContext('Subscriber')).catch((e: unknown) => e) as SFMCRequestError;

        expect(error.SyncCode).not.toBe('RATE_LIMIT_EXCEEDED');
        expect(error.SyncCode).toBe('CONFIGURATION_ERROR');
    });

    it('recognises a throttle fault by Code=17 OR by the fault text (the vendor code table is non-exhaustive)', () => {
        const connector = new SFMCConnector();
        expect(connector.IsSoapThrottle({ FaultString: 'Rate Limited', Code: '17', Message: 'Rate Limited' })).toBe(true);
        expect(connector.IsSoapThrottle({ FaultString: 'Too Many Requests', Code: '', Message: '' })).toBe(true);
        expect(connector.IsSoapThrottle({ FaultString: 'Not Authenticated', Code: '10', Message: 'invalid token' })).toBe(false);
    });

    it('honours REST 429 + Retry-After (errorcode 50100) and feeds it to the adaptive limiter', async () => {
        const connector = new MockedSFMCConnector().Enqueue({
            Status: 429,
            Json: fixtureJson('rest/error-429-50100.json'),
            Headers: { 'retry-after': '5' },
        });
        const error = await connector.FetchChanges(fetchContext('Campaign')).catch((e: unknown) => e) as SFMCRequestError;

        expect(error.Transport).toBe('rest');
        expect(error.SyncCode).toBe('RATE_LIMIT_EXCEEDED');
        expect(error.RetryAfterMs).toBe(5000);
        expect(connector.ExtractRetryAfterMs(error)).toBe(5000);
    });

    it('classifies REST 429 errorcode 50200 as a throttle even with NO Retry-After (exponential backoff)', async () => {
        const connector = new MockedSFMCConnector().Enqueue({ Status: 429, Json: fixtureJson('rest/error-429-50200.json') });
        const error = await connector.FetchChanges(fetchContext('Campaign')).catch((e: unknown) => e) as SFMCRequestError;

        expect(error.SyncCode).toBe('RATE_LIMIT_EXCEEDED');
        expect(error.RetryAfterMs).toBeUndefined();
    });

    it('classifies a REST 400 validation error from the vendor’s own custom-code table', async () => {
        const connector = new MockedSFMCConnector().Enqueue({ Status: 400, Json: fixtureJson('rest/error-400-10002.json') });
        const error = await connector.FetchChanges(fetchContext('Campaign')).catch((e: unknown) => e) as SFMCRequestError;

        expect(error.SyncCode).toBe('VALIDATION_ERROR');
        expect(error.VendorCode).toBe('10002');
        expect(error.message).toContain('Missing Required Field');
    });

    it('does NOT apply the SOAP 500-means-throttle rule to a plain REST 500', () => {
        const connector = new SFMCConnector();
        expect(connector.ClassifyRestStatus(500)).not.toBe('RATE_LIMIT_EXCEEDED');
        expect(connector.ClassifyRestStatus(401)).toBe('CONFIGURATION_ERROR');
        expect(connector.ClassifyRestStatus(404)).toBe('MATCH_RESOLUTION_ERROR');
        expect(connector.ClassifyRestStatus(409)).toBe('DUPLICATE_KEY');
    });
});

// ═════════════════════════════════════════════════════════════════════════════════════════════════
describe('SFMCConnector — discovery (declared catalog credential-free, Data Extensions at runtime)', () => {
// ═════════════════════════════════════════════════════════════════════════════════════════════════

    it('returns the FULL declared catalog even when the runtime enumeration fails (credential-free)', async () => {
        // No canned response at all → the SOAP enumeration throws internally and degrades to declared-only.
        const connector = new MockedSFMCConnector().Enqueue({ Status: 500, Xml: fixtureText('soap/fault-invalid-token.soap.xml') });
        const objects = await connector.DiscoverObjects(companyIntegration(), CONTEXT_USER);

        expect(objects).toHaveLength(metadataObjects.length);
        for (const row of metadataObjects) {
            expect(objects.some(o => o.Name === row.fields.Name), `declared object ${String(row.fields.Name)} must survive`).toBe(true);
        }
    });

    it('ADDS this connection’s Data Extensions on top of the declared catalog', async () => {
        const connector = new MockedSFMCConnector().Enqueue({ Status: 200, Xml: fixtureText('soap/dataextension-list.soap.xml') });
        const objects = await connector.DiscoverObjects(companyIntegration(), CONTEXT_USER);

        expect(objects).toHaveLength(metadataObjects.length + 1);
        const de = objects.find(o => o.Name === 'DataExtensionObject[Airlines]');
        expect(de).toBeTruthy();
        expect(de?.Label).toBe('Airlines');
        // The enumeration is a REAL runtime call against the declared mechanism ObjectType.
        expect(connector.Requests[0].Envelope).toContain('<par:ObjectType>DataExtension</par:ObjectType>');
    });

    it('never mints a Data Extension into the DECLARED metadata (customs stay discovered)', () => {
        const declaredNames = metadataObjects.map(o => o.fields.Name as string);
        expect(declaredNames).not.toContain('DataExtensionObject[Airlines]');
        expect(declaredNames).toContain('DataExtension');       // the MECHANISM is declared
        expect(declaredNames).toContain('DataExtensionField');
    });

    it('discovers a Data Extension’s columns at runtime, with provable-only constraint flags', async () => {
        const connector = new MockedSFMCConnector().Enqueue({ Status: 200, Xml: fixtureText('soap/dataextensionfield-airlines.soap.xml') });
        const fields = await connector.DiscoverFields(companyIntegration(), 'DataExtensionObject[Airlines]', CONTEXT_USER);

        expect(fields.map(f => f.Name)).toEqual(['IATA-Code', 'Airline', 'Country', 'Loyalty_Tier__c']);
        const pk = fields.find(f => f.IsPrimaryKey);
        expect(pk?.Name).toBe('IATA-Code');
        expect(pk?.IsRequired).toBe(true);
        expect(pk?.AllowsNull).toBe(false);       // the vendor reported IsNillable=false — provable
        expect(pk?.MaxLength).toBe(10);
        const optional = fields.find(f => f.Name === 'Airline');
        expect(optional?.AllowsNull).toBe(true);
        expect(optional?.IsPrimaryKey).toBe(false);
    });

    it('returns the DECLARED fields for a declared object without any credential-bearing call', async () => {
        const connector = new MockedSFMCConnector();
        const fields = await connector.DiscoverFields(companyIntegration(), 'Campaign', CONTEXT_USER);
        const declared = (metadataObjects.find(o => o.fields.Name === 'Campaign')?.relatedEntities?.['MJ: Integration Object Fields'] ?? [])
            .map(f => f.fields.Name as string);

        expect(fields.map(f => f.Name)).toEqual(declared);
        expect(connector.Requests).toHaveLength(0);   // no HTTP at all — this is the T3 credential-free path
    });
});

// ═════════════════════════════════════════════════════════════════════════════════════════════════
describe('SFMCConnector — write-shape construction (MOCKED; no live call, no mutation)', () => {
// ═════════════════════════════════════════════════════════════════════════════════════════════════

    it('builds a SOAP CreateRequest from the declared per-operation columns and reads NewObjectID back', async () => {
        expect(metadataObject('Subscriber').CreateAPIPath).toBe('/Service.asmx');
        expect(metadataObject('Subscriber').CreateMethod).toBe('POST');

        const connector = new MockedSFMCConnector().Enqueue({ Status: 200, Xml: fixtureText('soap/create-subscriber-response.soap.xml') });
        const result = await connector.CreateRecord({
            CompanyIntegration: companyIntegration(),
            ContextUser: CONTEXT_USER,
            ObjectName: 'Subscriber',
            Attributes: { EmailAddress: 'dnguyen@example.com', SubscriberKey: 'dnguyen@example.com' },
        });

        const envelope = connector.Requests[0].Envelope ?? '';
        expect(connector.Requests[0].Headers.SOAPAction).toBe('Create');
        expect(envelope).toContain('<par:CreateRequest>');
        expect(envelope).toContain('<par:Options/>');
        expect(envelope).toContain('<par:Objects xsi:type="par:Subscriber">');
        expect(envelope).toContain('<par:EmailAddress>dnguyen@example.com</par:EmailAddress>');
        expect(result.Success).toBe(true);
        expect(result.ExternalID).toBe('9f2c1b08-0f06-4f4e-9b2f-6bb9d3f0a004');
    });

    it('fails a SOAP write LOUDLY when the partnerAPI returns StatusCode=Error on an HTTP 200', async () => {
        const connector = new MockedSFMCConnector().Enqueue({ Status: 200, Xml: fixtureText('soap/update-subscriber-error.soap.xml') });
        const result = await connector.UpdateRecord({
            CompanyIntegration: companyIntegration(),
            ContextUser: CONTEXT_USER,
            ObjectName: 'Subscriber',
            ExternalID: '9f2c1b08-0f06-4f4e-9b2f-6bb9d3f0a002',
            Attributes: { Status: 'Held' },
        });
        expect(result.Success).toBe(false);
        expect(result.ErrorMessage).toContain('Unable to find the applicable subscriber');
    });

    it('injects the update target’s identity under the DECLARED primary key when the caller omits it', async () => {
        const connector = new MockedSFMCConnector().Enqueue({ Status: 200, Xml: fixtureText('soap/update-subscriber-error.soap.xml') });
        await connector.UpdateRecord({
            CompanyIntegration: companyIntegration(),
            ContextUser: CONTEXT_USER,
            ObjectName: 'Subscriber',
            ExternalID: '9f2c1b08-0f06-4f4e-9b2f-6bb9d3f0a002',
            Attributes: { Status: 'Held' },
        });
        const envelope = connector.Requests[0].Envelope ?? '';
        expect(envelope).toContain('<par:UpdateRequest>');
        expect(envelope).toContain('<par:ObjectID>9f2c1b08-0f06-4f4e-9b2f-6bb9d3f0a002</par:ObjectID>');
    });

    it('builds a REST create from the declared path/method/body shape and reads the id back', async () => {
        expect(metadataObject('Campaign').CreateAPIPath).toBe('/hub/v1/campaigns');
        expect(metadataObject('Campaign').CreateMethod).toBe('POST');
        expect(metadataObject('Campaign').CreateBodyShape).toBe('flat');

        const connector = new MockedSFMCConnector().Enqueue({ Status: 202, Json: fixtureJson('rest/campaign-created.json') });
        const result = await connector.CreateRecord({
            CompanyIntegration: companyIntegration(),
            ContextUser: CONTEXT_USER,
            ObjectName: 'Campaign',
            Attributes: { name: 'Annual Sale 2012', description: 'Yearly sale', campaignCode: 'annual2012', color: '0000ff', favorite: false },
        });

        expect(connector.Requests[0].Method).toBe('POST');
        expect(connector.Requests[0].URL).toBe(`${MOCK_ORIGIN}/hub/v1/campaigns`);
        expect(connector.Requests[0].JSONBody).toEqual({ name: 'Annual Sale 2012', description: 'Yearly sale', campaignCode: 'annual2012', color: '0000ff', favorite: false });
        expect(result.Success).toBe(true);
        expect(result.ExternalID).toBe('505');
    });

    it('substitutes the Express-style :param in a REST delete path from the declared metadata', async () => {
        expect(metadataObject('Campaign').DeleteAPIPath).toBe('/hub/v1/campaigns/:id');
        const connector = new MockedSFMCConnector().Enqueue({ Status: 204, Json: null });
        const result = await connector.DeleteRecord({
            CompanyIntegration: companyIntegration(),
            ContextUser: CONTEXT_USER,
            ObjectName: 'Campaign',
            ExternalID: '505',
        });
        expect(connector.Requests[0].Method).toBe('DELETE');
        expect(connector.Requests[0].URL).toBe(`${MOCK_ORIGIN}/hub/v1/campaigns/505`);
        expect(result.Success).toBe(true);
    });

    it('refuses a verb whose capability metadata is not populated, rather than guessing a path', async () => {
        expect(metadataObject('Asset').CreateAPIPath).toBeNull();
        const connector = new MockedSFMCConnector();
        await expect(connector.CreateRecord({
            CompanyIntegration: companyIntegration(),
            ContextUser: CONTEXT_USER,
            ObjectName: 'Asset',
            Attributes: { name: 'x' },
        })).rejects.toThrow(/CreateAPIPath \/ CreateMethod not configured/);
        expect(connector.Requests).toHaveLength(0);
    });

    it('every metadata object flagged write-capable carries the matching path+method pair', () => {
        const gaps: string[] = [];
        for (const row of metadataObjects) {
            const f = row.fields;
            if (f.SupportsCreate && !(f.CreateAPIPath && f.CreateMethod)) gaps.push(`${String(f.Name)}:create`);
            if (f.SupportsUpdate && !(f.UpdateAPIPath && f.UpdateMethod)) gaps.push(`${String(f.Name)}:update`);
            if (f.SupportsDelete && !(f.DeleteAPIPath && f.DeleteMethod)) gaps.push(`${String(f.Name)}:delete`);
        }
        expect(gaps).toEqual([]);
    });
});

// ═════════════════════════════════════════════════════════════════════════════════════════════════
describe('SFMCConnector — GetRecord (read-only)', () => {
// ═════════════════════════════════════════════════════════════════════════════════════════════════

    it('reads one SOAP record by filtering on the declared primary key', async () => {
        const connector = new MockedSFMCConnector().Enqueue({ Status: 200, Xml: fixtureText('soap/subscriber-batch1.soap.xml') });
        const record = await connector.GetRecord({
            CompanyIntegration: companyIntegration(),
            ContextUser: CONTEXT_USER,
            ObjectName: 'Subscriber',
            ExternalID: '9f2c1b08-0f06-4f4e-9b2f-6bb9d3f0a002',
        });
        const envelope = connector.Requests[0].Envelope ?? '';
        expect(envelope).toContain('<par:Property>ObjectID</par:Property>');
        expect(envelope).toContain('<par:SimpleOperator>equals</par:SimpleOperator>');
        expect(record?.ExternalID).toBe('9f2c1b08-0f06-4f4e-9b2f-6bb9d3f0a002');
    });

    it('returns null for a REST 404 instead of throwing', async () => {
        const connector = new MockedSFMCConnector().Enqueue({ Status: 404, Json: { message: 'Object Not Found', errorcode: 30003 } });
        const record = await connector.GetRecord({
            CompanyIntegration: companyIntegration(),
            ContextUser: CONTEXT_USER,
            ObjectName: 'Definition',
            ExternalID: 'missing-key',
        });
        expect(record).toBeNull();
    });
});

// ═════════════════════════════════════════════════════════════════════════════════════════════════
describe('SFMCConnector — REST path shapes the vendor actually publishes', () => {
// ═════════════════════════════════════════════════════════════════════════════════════════════════

    it('preserves an APIPath that already carries a query string and appends page params with &', async () => {
        expect(metadataObject('typenotSent').APIPath).toBe('/messaging/v1/email/messages/?type=notSent');
        const connector = new MockedSFMCConnector().Enqueue({ Status: 200, Json: { messages: [] } });
        await connector.FetchChanges(fetchContext('typenotSent'));

        const url = new URL(connector.Requests[0].URL);
        expect(url.pathname).toBe('/messaging/v1/email/messages/');
        expect(url.searchParams.get('type')).toBe('notSent');
        expect(url.searchParams.get('$page')).toBe('1');
    });

    it('fills an EMPTY-valued query parameter from the declared pathParams instead of sending it blank', async () => {
        expect(metadataObject('StatusoperationID').APIPath).toBe('/contacts/v1/contacts/actions/delete/status?operationID=');
        const ci = companyIntegration({ pathParams: { operationID: 'op-7' } });
        const connector = new MockedSFMCConnector().Enqueue({ Status: 200, Json: { operationID: 'op-7', status: 'Complete' } });
        const result = await connector.FetchChanges({ ...fetchContext('StatusoperationID'), CompanyIntegration: ci });

        expect(result.Warnings ?? []).toHaveLength(0);
        expect(new URL(connector.Requests[0].URL).searchParams.get('operationID')).toBe('op-7');
    });

    it('treats an empty-valued query parameter as UNRESOLVED when nothing supplies it', async () => {
        const connector = new MockedSFMCConnector().Enqueue({ Status: 200, Json: {} });
        const result = await connector.FetchChanges(fetchContext('StatusoperationID'));
        expect(connector.Requests).toHaveLength(0);
        expect(result.Warnings?.[0].Code).toBe('PATH_PARAMS_UNRESOLVED');
    });
});

// ═════════════════════════════════════════════════════════════════════════════════════════════════
describe('SFMCConnector — IntrospectSchema sample-union (declared widened, never shrunk)', () => {
// ═════════════════════════════════════════════════════════════════════════════════════════════════

    it('keeps every declared field and APPENDS a tenant attribute the live sample measured', async () => {
        const connector = new MockedSFMCConnector().Enqueue(
            { Status: 200, Xml: fixtureText('soap/subscriber-batch2.soap.xml') },
        );
        const schema = await connector.IntrospectSchema(companyIntegration(), CONTEXT_USER);

        expect(schema.IsAuthoritative).toBe(false);
        const subscriber = schema.Objects.find(o => o.ExternalName === 'Subscriber');
        expect(subscriber).toBeTruthy();
        const declared = (metadataObjects.find(o => o.fields.Name === 'Subscriber')?.relatedEntities?.['MJ: Integration Object Fields'] ?? [])
            .map(f => f.fields.Name as string);
        // NEVER shrinks: every declared field survives the merge.
        for (const name of declared) {
            expect(subscriber?.Fields.some(f => f.Name === name), `declared field ${name} must survive`).toBe(true);
        }
        // WIDENS: the tenant profile attribute that only exists in the live data is appended.
        expect(subscriber?.Fields.some(f => f.Name === 'First Name')).toBe(true);
    }, 120_000);
});
