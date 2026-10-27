/**
 * SpektrixConnector — credential-free, NON-MUTATING unit tests (T4/T5 tier).
 *
 * Nothing here reaches a network: the connector's raw transport (`SendHTTP`) is replaced by an
 * in-memory responder, so signing, URL construction, status gating, access-path walking and
 * write-request construction all run for real while no request ever leaves the process.
 *
 * Inputs are never hand-authored:
 *  - the IntegrationEngineBase cache is seeded from the FROZEN metadata file
 *    (metadata/integration/.spektrix.integration.json — the catalog this package ships), so every window parameter name,
 *    access path, expand and write column under test is the contract's own;
 *  - response bodies come from the doc-example fixture manifest
 *    (src/__tests__/fixtures/spektrix/fixtures.json, Provenance.Kind = doc-example, PII-free).
 */
import { describe, it, expect, beforeAll, beforeEach, vi } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { createHash, createHmac } from 'node:crypto';
import type { UserInfo } from '@memberjunction/core';
import type {
    MJCompanyIntegrationEntity,
    MJIntegrationEntity,
    MJIntegrationObjectEntity,
    MJIntegrationObjectFieldEntity,
} from '@memberjunction/core-entities';
import { MJGlobal } from '@memberjunction/global';
import { IntegrationEngineBase } from '@memberjunction/integration-engine-base';
import {
    BaseIntegrationConnector,
    ClassifyError,
    IsRetryableError,
    type FetchBatchResult,
    type PaginationState,
    type RESTResponse,
} from '@memberjunction/integration-engine';
import {
    SpektrixConnector,
    SpektrixAPIError,
    BuildSpektrixStringToSign,
    BuildSpektrixAuthorization,
    BuildSpektrixDateWindows,
    type SpektrixAuthContext,
} from '../SpektrixConnector.js';

// ─── RunView stand-in for the base class's parent-ID load (template-var children) ─────────────────
// The base class reads already-synced parent IDs from the MJ database; here that read is answered
// from memory so the REAL base iteration (resume, tagging, scope) runs without a database.

const parentRows = vi.hoisted(() => new Map<string, Array<Record<string, unknown>>>());

vi.mock('@memberjunction/core', async (importOriginal) => {
    const actual = await importOriginal<typeof import('@memberjunction/core')>();
    class InMemoryRunView {
        public async RunView(params: { EntityName?: string; ExtraFilter?: string }): Promise<{ Success: boolean; Results: Array<Record<string, unknown>> }> {
            if (params.EntityName === 'MJ: Company Integration Entity Maps') {
                const objectName = /ExternalObjectName='([^']+)'/.exec(params.ExtraFilter ?? '')?.[1] ?? '';
                return { Success: true, Results: [{ EntityID: 'entity-map', Entity: `Spektrix ${objectName}` }] };
            }
            const objectName = (params.EntityName ?? '').replace(/^Spektrix /, '');
            return { Success: true, Results: parentRows.get(objectName) ?? [] };
        }
    }
    return { ...actual, RunView: InMemoryRunView };
});

// ─── Contract + fixture loading ───────────────────────────────────────────────────────────────────

interface MetaRow { fields: Record<string, unknown> }
interface MetaIO extends MetaRow { relatedEntities?: { 'MJ: Integration Object Fields'?: MetaRow[] } }
interface MetaIntegration extends MetaRow { relatedEntities: { 'MJ: Integration Objects': MetaIO[] } }

interface FixtureRoute {
    Path: string;
    Method?: string;
    Status: number;
    Body?: unknown;
    Match?: string | string[];
}
interface FixtureWindowSet {
    Object: string;
    FromParam: string;
    ToParam: string;
    Windows: Array<{ Name: string; Month: string; RecordIDs: string[] }>;
}
interface FixtureManifest {
    Configuration: Record<string, string>;
    Routes: FixtureRoute[];
    FetchWindows: FixtureWindowSet[];
    ErrorRoutes: {
        NotFound: { Path: string; ParentID: string; Object: string };
        RateLimit: { Path: string; RetryAfter: string };
    };
}

function loadJSON<T>(relativeToThisFile: string): T {
    return JSON.parse(readFileSync(fileURLToPath(new URL(relativeToThisFile, import.meta.url)), 'utf8')) as T;
}

const META = loadJSON<MetaIntegration[]>('../../metadata/integration/.spektrix.integration.json')[0];
const FIXTURES = loadJSON<FixtureManifest>('./fixtures/spektrix/fixtures.json');
// The authored catalog stores Integration.Configuration as an object (the catalog-freshness pin lint reads it
// that way); mj sync serializes it to the JSON string the DB column holds. Accept either shape here.
const RAW_INTEGRATION_CONFIG = META.fields.Configuration;
const INTEGRATION_CONFIG = (typeof RAW_INTEGRATION_CONFIG === 'string' ? JSON.parse(RAW_INTEGRATION_CONFIG) : RAW_INTEGRATION_CONFIG) as Record<string, unknown>;
const META_IOS = META.relatedEntities['MJ: Integration Objects'];

const INTEGRATION_ID = 'int-spektrix';
const BASE_URL = 'https://mock.spektrix.test/v3';
const NOW = new Date('2026-10-14T09:30:00Z');
const SECRET_B64 = FIXTURES.Configuration.ApiSecretKey;
const USER = {} as UserInfo;

const ioID = (name: string): string => `io-${name}`;
const str = (v: unknown): string => (v == null ? '' : String(v));
const strOrNull = (v: unknown): string | null => (v == null ? null : String(v));
const bool = (v: unknown): boolean => v === true;
const jsonText = (v: unknown): string | null => (v == null ? null : (typeof v === 'string' ? v : JSON.stringify(v)));
type Shape = MJIntegrationObjectEntity['CreateBodyShape'];
type IDLoc = MJIntegrationObjectEntity['CreateIDLocation'];
type Status = MJIntegrationObjectEntity['Status'];
const shape = (v: unknown): Shape => (v === 'flat' || v === 'literal' || v === 'wrapped' ? v : null);
const idLoc = (v: unknown): IDLoc => (v === 'body' || v === 'header' || v === 'n/a' || v === 'path' ? v : null);
const status = (v: unknown): Status => (v === 'Disabled' || v === 'Deprecated' ? v : 'Active');

function ioRow(io: MetaIO): Partial<MJIntegrationObjectEntity> {
    const f = io.fields;
    const name = str(f.Name);
    return {
        ID: ioID(name), IntegrationID: INTEGRATION_ID, Name: name, DisplayName: strOrNull(f.DisplayName),
        Description: strOrNull(f.Description), APIPath: str(f.APIPath), ResponseDataKey: strOrNull(f.ResponseDataKey),
        SupportsPagination: bool(f.SupportsPagination), PaginationType: 'None', DefaultPageSize: 0,
        SupportsIncrementalSync: bool(f.SupportsIncrementalSync), SupportsWrite: bool(f.SupportsWrite),
        DefaultQueryParams: jsonText(f.DefaultQueryParams), Configuration: jsonText(f.Configuration),
        Sequence: Number(f.Sequence ?? 0), Status: status(f.Status), StableOrderingKey: strOrNull(f.StableOrderingKey),
        SupportsCreate: bool(f.SupportsCreate), SupportsUpdate: bool(f.SupportsUpdate), SupportsDelete: bool(f.SupportsDelete),
        CreateAPIPath: strOrNull(f.CreateAPIPath), CreateMethod: strOrNull(f.CreateMethod), CreateBodyShape: shape(f.CreateBodyShape),
        CreateBodyKey: strOrNull(f.CreateBodyKey), CreateIDLocation: idLoc(f.CreateIDLocation),
        UpdateAPIPath: strOrNull(f.UpdateAPIPath), UpdateMethod: strOrNull(f.UpdateMethod), UpdateBodyShape: shape(f.UpdateBodyShape),
        UpdateBodyKey: strOrNull(f.UpdateBodyKey), UpdateIDLocation: idLoc(f.UpdateIDLocation),
        DeleteAPIPath: strOrNull(f.DeleteAPIPath), DeleteMethod: strOrNull(f.DeleteMethod), DeleteIDLocation: idLoc(f.DeleteIDLocation),
    };
}

function relatedIOID(v: unknown): string | null {
    const m = /Name=([^&]+)&/.exec(str(v));
    return m ? ioID(m[1]) : null;
}

function iofRow(io: MetaIO, row: MetaRow): Partial<MJIntegrationObjectFieldEntity> {
    const f = row.fields;
    const ioName = str(io.fields.Name);
    return {
        ID: `iof-${ioName}-${str(f.Name)}`, IntegrationObjectID: ioID(ioName), Name: str(f.Name),
        DisplayName: strOrNull(f.DisplayName), Type: str(f.Type), IsRequired: bool(f.IsRequired), IsReadOnly: bool(f.IsReadOnly),
        IsPrimaryKey: bool(f.IsPrimaryKey), IsUniqueKey: bool(f.IsUniqueKey), AllowsNull: f.AllowsNull !== false,
        Length: null, Precision: null, Scale: null, DefaultValue: null, Sequence: Number(f.Sequence ?? 0),
        Configuration: jsonText(f.Configuration), Status: status(f.Status), RelatedIntegrationObjectID: relatedIOID(f.RelatedIntegrationObjectID),
    };
}

function seedEngine(adjust: (f: Partial<MJIntegrationObjectFieldEntity>) => Partial<MJIntegrationObjectFieldEntity> = f => f): void {
    const integration: Partial<MJIntegrationEntity> = { ID: INTEGRATION_ID, Name: str(META.fields.Name), Configuration: jsonText(META.fields.Configuration) };
    IntegrationEngineBase.Instance.SeedForTesting({
        Integrations: [integration],
        IntegrationObjects: META_IOS.map(ioRow),
        IntegrationObjectFields: META_IOS.flatMap(io => (io.relatedEntities?.['MJ: Integration Object Fields'] ?? []).map(r => adjust(iofRow(io, r)))),
    });
}

function objectConfig(name: string): Record<string, unknown> {
    const io = META_IOS.find(i => i.fields.Name === name);
    if (!io) throw new Error(`no IO ${name} in the frozen metadata`);
    return io.fields.Configuration as Record<string, unknown>;
}

function companyIntegration(config: Record<string, unknown> = {}): MJCompanyIntegrationEntity {
    const ci: Partial<MJCompanyIntegrationEntity> = {
        ID: `ci-${JSON.stringify(config).length}`,
        IntegrationID: INTEGRATION_ID,
        CredentialID: null,
        Configuration: JSON.stringify({ ...FIXTURES.Configuration, BaseURL: BASE_URL, ...config }),
    };
    return ci as MJCompanyIntegrationEntity;
}

// ─── Mocked transport ─────────────────────────────────────────────────────────────────────────────

interface CapturedRequest {
    url: string;
    method: string;
    headers: Record<string, string>;
    body: string | undefined;
}

type Responder = (req: CapturedRequest) => RESTResponse;

class MockedSpektrixConnector extends SpektrixConnector {
    public Requests: CapturedRequest[] = [];
    public Sleeps: number[] = [];
    public Responder: Responder = fixtureResponder(FIXTURES.Routes);

    protected override async SendHTTP(url: string, method: string, headers: Record<string, string>, body: string | undefined): Promise<RESTResponse> {
        const req: CapturedRequest = { url, method, headers, body };
        this.Requests.push(req);
        return this.Responder(req);
    }
    protected override async Sleep(ms: number): Promise<void> { this.Sleeps.push(ms); }
    protected override CurrentTime(): Date { return NOW; }

    public Normalize(raw: unknown, rdk: string | null): Record<string, unknown>[] { return this.NormalizeResponse(raw, rdk); }
    public Auth(ci: MJCompanyIntegrationEntity): Promise<SpektrixAuthContext> { return this.Authenticate(ci, USER); }
    public Send(auth: SpektrixAuthContext, url: string, method: string, body?: unknown): Promise<RESTResponse> {
        return this.MakeHTTPRequest(auth, url, method, this.BuildHeaders(auth), body);
    }
    public Pagination(): PaginationState { return this.ExtractPaginationInfo([], 'None', 1, 0, 0); }
}

function relativePath(url: string): { path: string; query: string; params: URLSearchParams } {
    const parsed = new URL(url);
    const basePath = new URL(BASE_URL).pathname;
    const path = parsed.pathname.startsWith(basePath) ? parsed.pathname.slice(basePath.length) : parsed.pathname;
    return { path, query: decodeURIComponent(parsed.search.replace(/^\?/, '')), params: parsed.searchParams };
}

/** Faithful to the e2e mock: same path + method, every `Match` substring present in the decoded query, most-constrained wins. */
function fixtureResponder(routes: FixtureRoute[]): Responder {
    return (req) => {
        const { path, query } = relativePath(req.url);
        let best: FixtureRoute | null = null;
        let bestScore = -1;
        for (const route of routes) {
            if ((route.Method ?? 'GET').toUpperCase() !== req.method || route.Path.split('?')[0] !== path) continue;
            const needles = route.Match == null ? [] : (Array.isArray(route.Match) ? route.Match : [route.Match]);
            if (!needles.every(n => query.toLowerCase().includes(n.toLowerCase()))) continue;
            if (needles.length > bestScore) { best = route; bestScore = needles.length; }
        }
        if (!best) return { Status: 404, Body: '<html><body>Not Found</body></html>', Headers: { 'content-type': 'text/html' } };
        return { Status: best.Status, Body: structuredClone(best.Body ?? null), Headers: { 'content-type': 'application/json' } };
    };
}

function expectedSignature(method: string, url: string, date: string, body?: string): string {
    let toSign = `${method}\n${url}\n${date}`;
    if (method !== 'GET') toSign += `\n${createHash('md5').update(body ?? '', 'utf8').digest('base64')}`;
    return createHmac('sha1', Buffer.from(SECRET_B64, 'base64')).update(toSign, 'utf8').digest('base64');
}

function ids(batch: FetchBatchResult, field = 'id'): string[] {
    return batch.Records.map(r => str(r.Fields[field]));
}

async function fetchAll(connector: SpektrixConnector, objectName: string, ci: MJCompanyIntegrationEntity, batchSize = 200): Promise<FetchBatchResult[]> {
    const batches: FetchBatchResult[] = [];
    let after: string | null = null;
    for (let i = 0; i < 50; i++) {
        const batch = await connector.FetchChanges({ CompanyIntegration: ci, ObjectName: objectName, WatermarkValue: null, BatchSize: batchSize, ContextUser: USER, AfterKeyValue: after });
        batches.push(batch);
        if (!batch.HasMore) break;
        after = batch.NextAfterKeyValue ?? null;
    }
    return batches;
}

// ─── Suite ────────────────────────────────────────────────────────────────────────────────────────

describe('SpektrixConnector', () => {
    let connector: MockedSpektrixConnector;

    beforeAll(() => seedEngine());
    beforeEach(() => {
        seedEngine();
        parentRows.clear();
        connector = new MockedSpektrixConnector();
    });

    describe('identity + capability', () => {
        it('IntegrationName is the verbatim MJ: Integrations.Name and the class is registered under its ClassName', () => {
            expect(connector.IntegrationName).toBe(META.fields.Name);
            const created = MJGlobal.Instance.ClassFactory.CreateInstance<BaseIntegrationConnector>(BaseIntegrationConnector, str(META.fields.ClassName));
            expect(created).toBeInstanceOf(SpektrixConnector);
        });

        it('derives Create/Update/Delete capability from the per-operation IO columns', () => {
            const anyWith = (pred: (f: Record<string, unknown>) => boolean): boolean => META_IOS.some(io => io.fields.Status === 'Active' && pred(io.fields));
            expect(connector.SupportsCreate).toBe(anyWith(f => f.SupportsCreate === true && !!f.CreateAPIPath));
            expect(connector.SupportsUpdate).toBe(anyWith(f => f.SupportsUpdate === true && !!f.UpdateAPIPath));
            expect(connector.SupportsDelete).toBe(anyWith(f => f.SupportsDelete === true && !!f.DeleteAPIPath));
            expect(connector.SupportsCreate && connector.SupportsUpdate && connector.SupportsDelete).toBe(true);
        });

        it('keeps discovery non-authoritative, requests sequential concurrency, and reads StableOrderingKey from metadata', () => {
            expect(connector.DiscoveryIsAuthoritative).toBe(false);
            expect(connector.MaxConcurrencyHint).toBe(1);
            expect(connector.StableOrderingKey('Country')).toBe('isoCode');
            expect(connector.StableOrderingKey('Address')).toBeNull();
        });

        it('reports no pagination (proven negative)', () => {
            expect(connector.Pagination()).toEqual({ HasMore: false });
        });
    });

    describe('SpektrixAPI3 signer', () => {
        const key = Buffer.from(SECRET_B64, 'base64');
        const date = 'Wed, 14 Oct 2026 09:30:00 GMT';

        it('GET: METHOD \\n URL \\n Date — no body hash', () => {
            const url = 'https://mock.spektrix.test/v3/events?instanceStart_from=2026-10-14';
            expect(BuildSpektrixStringToSign('get', url, date)).toBe(`GET\n${url}\n${date}`);
            const auth = BuildSpektrixAuthorization({ LoginName: 'login', SigningKey: key, Method: 'GET', Url: url, DateHeader: date });
            expect(auth).toBe(`SpektrixAPI3 login:${expectedSignature('GET', url, date)}`);
        });

        it('POST: appends BASE64(MD5(UTF-8 body)) and signs it', () => {
            const url = 'https://mock.spektrix.test/v3/customers';
            const body = '{"firstName":"Zoë","lastName":"Test"}';
            const md5 = createHash('md5').update(body, 'utf8').digest('base64');
            expect(BuildSpektrixStringToSign('POST', url, date, body)).toBe(`POST\n${url}\n${date}\n${md5}`);
            const auth = BuildSpektrixAuthorization({ LoginName: 'login', SigningKey: key, Method: 'POST', Url: url, DateHeader: date, Body: body });
            expect(auth).toBe(`SpektrixAPI3 login:${expectedSignature('POST', url, date, body)}`);
        });

        it('DELETE without a body still carries the MD5 of the empty body (non-GET rule)', () => {
            const s = BuildSpektrixStringToSign('DELETE', 'https://x.test/a', date);
            expect(s.split('\n')).toEqual(['DELETE', 'https://x.test/a', date, '1B2M2Y8AsgTpgAmY7PhCfg==']);
        });

        it('signs the byte-identical canonical URL that goes on the wire, with a fresh RFC-7231 Date', async () => {
            const auth = await connector.Auth(companyIntegration());
            connector.Responder = () => ({ Status: 200, Body: [], Headers: {} });
            await connector.Send(auth, `${BASE_URL}/orders?$expand=tickets/customItems&q=a b`, 'GET');
            const sent = connector.Requests[0];
            expect(sent.url).toBe(new URL(`${BASE_URL}/orders?$expand=tickets/customItems&q=a b`).href);
            expect(sent.headers.Date).toBe(NOW.toUTCString());
            expect(sent.headers.Authorization).toBe(`SpektrixAPI3 ${FIXTURES.Configuration.ApiLoginName}:${expectedSignature('GET', sent.url, sent.headers.Date)}`);
        });

        it('rejects a non-base-64 ApiSecretKey with a clear configuration error that never echoes the secret', async () => {
            const bad = 'not*base64!secret';
            await expect(connector.Auth(companyIntegration({ ApiSecretKey: bad }))).rejects.toThrow(/ApiSecretKey is not a valid base-64/);
            const result = await connector.TestConnection(companyIntegration({ ApiSecretKey: bad }), USER);
            expect(result.Success).toBe(false);
            expect(result.Message).not.toContain(bad);
            expect(connector.Requests).toHaveLength(0);
        });

        it('requires ApiLoginName', async () => {
            await expect(connector.Auth(companyIntegration({ ApiLoginName: '' }))).rejects.toThrow(/ApiLoginName is missing/);
        });
    });

    describe('base URL + headers', () => {
        it('a connection BaseURL override wins (ClientName not required)', async () => {
            const auth = await connector.Auth(companyIntegration({ BaseURL: 'https://custom.example.test/api/v3/', ClientName: '' }));
            expect(auth.BaseURL).toBe('https://custom.example.test/api/v3');
        });

        it('otherwise uses Integration.Configuration.BaseURLTemplate with the CONNECTION ClientName', async () => {
            const auth = await connector.Auth(companyIntegration({ BaseURL: '', ClientName: 'some tenant' }));
            const template = str(INTEGRATION_CONFIG.BaseURLTemplate);
            expect(auth.BaseURL).toBe(template.replace('{ClientName}', encodeURIComponent('some tenant')));
        });

        it('fails clearly when neither ClientName nor BaseURL is configured', async () => {
            await expect(connector.Auth(companyIntegration({ BaseURL: '', ClientName: '' }))).rejects.toThrow(/ClientName/);
        });

        it('bakes no tenant constant, vendor host, id or custom-attribute name into the class source', () => {
            const source = readFileSync(fileURLToPath(new URL('../SpektrixConnector.ts', import.meta.url)), 'utf8');
            expect(source).not.toMatch(/apitesting/i);
            expect(source).not.toMatch(/fixture-client/i);
            expect(source).not.toMatch(/system\.spektrix\.com/i);
            expect(source).not.toMatch(/attribute_[A-Z]\w+/);
            expect(source).not.toMatch(/\b\d{5}[A-Z]{20,}\b/);
        });

        it('sends Accept: application/json on every request and Content-Type only with a body', async () => {
            const auth = await connector.Auth(companyIntegration());
            connector.Responder = () => ({ Status: 200, Body: {}, Headers: {} });
            await connector.Send(auth, `${BASE_URL}/system/config`, 'GET');
            await connector.Send(auth, `${BASE_URL}/customers`, 'POST', { firstName: 'A' });
            expect(connector.Requests.map(r => r.headers.Accept)).toEqual(['application/json', 'application/json']);
            expect(connector.Requests[0].headers['Content-Type']).toBeUndefined();
            expect(connector.Requests[1].headers['Content-Type']).toMatch(/^application\/json/);
            expect(connector.Requests[1].body).toBe('{"firstName":"A"}');
        });
    });

    describe('response normalisation', () => {
        it('bare array → records; bare object → one record; envelope only when ResponseDataKey is declared', () => {
            expect(connector.Normalize([{ id: 1 }, { id: 2 }, 'noise'], null)).toEqual([{ id: 1 }, { id: 2 }]);
            expect(connector.Normalize({ currency: 'GBP' }, null)).toEqual([{ currency: 'GBP' }]);
            expect(connector.Normalize({ data: [{ id: 1 }] }, null)).toEqual([{ data: [{ id: 1 }] }]);
            expect(connector.Normalize({ data: [{ id: 1 }, { id: 2 }] }, 'data')).toEqual([{ id: 1 }, { id: 2 }]);
            expect(connector.Normalize(null, null)).toEqual([]);
        });

        it('reads the system-config singleton door as exactly one record', async () => {
            const [batch] = await fetchAll(connector, 'Config', companyIntegration());
            expect(batch.Records).toHaveLength(1);
            expect(batch.Records[0].Fields.currency).toBe('GBP');
        });
    });

    describe('read-verb error gate', () => {
        const errorFor = async (respond: RESTResponse, objectName = 'Band'): Promise<unknown> => {
            connector.Responder = () => respond;
            try {
                await connector.FetchChanges({ CompanyIntegration: companyIntegration(), ObjectName: objectName, WatermarkValue: null, BatchSize: 200, ContextUser: USER });
            } catch (err) {
                return err;
            }
            return null;
        };

        it('HTML 404 = route error (configuration, not retryable) — never an empty batch', async () => {
            const err = await errorFor({ Status: 404, Body: '<html>Not Found</html>', Headers: {} });
            expect(err).toBeInstanceOf(SpektrixAPIError);
            expect((err as SpektrixAPIError).Classification.Code).toBe('CONFIGURATION_ERROR');
            expect(ClassifyError(err).Code).toBe('CONFIGURATION_ERROR');
        });

        it('JSON 404 ResourceNotFound on a flat read throws a NON-retryable error (not a DNS/database false positive)', async () => {
            const err = await errorFor({ Status: 404, Body: { resourceType: 'Band', resourceIdentifiers: {}, errorCode: 'ResourceNotFound', message: 'x' }, Headers: {} });
            expect((err as SpektrixAPIError).Classification.Code).toBe('CONFIGURATION_ERROR');
            expect(ClassifyError(err).Code).toBe('CONFIGURATION_ERROR');
            expect(IsRetryableError(ClassifyError(err).Code)).toBe(false);
        });

        it('an unexpected read status is surfaced as a non-retryable UNKNOWN error', async () => {
            const err = await errorFor({ Status: 410, Body: { message: 'gone' }, Headers: {} });
            expect((err as SpektrixAPIError).Classification.Code).toBe('UNKNOWN_ERROR');
            expect(ClassifyError(err).Code).toBe('UNKNOWN_ERROR');
        });

        it.each([
            [401, 'CONFIGURATION_ERROR', false],
            [403, 'CONFIGURATION_ERROR', false],
            [405, 'CONFIGURATION_ERROR', false],
            [400, 'VALIDATION_ERROR', false],
            [503, 'NETWORK_TIMEOUT', true],
        ])('HTTP %i → %s (engine classifier agrees; retryable=%s)', async (statusCode, code, retryable) => {
            const err = await errorFor({ Status: statusCode, Body: { message: 'Order 4290 was rejected' }, Headers: {} });
            expect((err as SpektrixAPIError).Classification.Code).toBe(code);
            expect(ClassifyError(err).Code).toBe(code);
            expect(IsRetryableError(ClassifyError(err).Code)).toBe(retryable);
            expect((err as Error).message).not.toContain('4290');
        });

        it('a 200 with a non-JSON body is a configuration error, not zero rows', async () => {
            const err = await errorFor({ Status: 200, Body: '<html>login</html>', Headers: {} });
            expect((err as SpektrixAPIError).Classification.Code).toBe('CONFIGURATION_ERROR');
        });

        it('429 + Retry-After is waited out and retried (fixture RateLimit route)', async () => {
            let hits = 0;
            const fixture = fixtureResponder(FIXTURES.Routes);
            connector.Responder = (req) => {
                if (relativePath(req.url).path === FIXTURES.ErrorRoutes.RateLimit.Path && hits++ === 0) {
                    return { Status: 429, Body: null, Headers: { 'retry-after': FIXTURES.ErrorRoutes.RateLimit.RetryAfter } };
                }
                return fixture(req);
            };
            const [batch] = await fetchAll(connector, 'Venue', companyIntegration());
            expect(connector.Sleeps).toEqual([Number(FIXTURES.ErrorRoutes.RateLimit.RetryAfter) * 1000]);
            expect(batch.Records.length).toBeGreaterThan(0);
            expect(connector.Requests[0].headers.Date).toBeDefined();
        });

        it('exhausted 429s throw RATE_LIMIT_EXCEEDED carrying the vendor Retry-After', async () => {
            const err = await errorFor({ Status: 429, Body: null, Headers: { 'retry-after': '7' } });
            expect(ClassifyError(err).Code).toBe('RATE_LIMIT_EXCEEDED');
            expect(connector.ExtractRetryAfterMs(err)).toBe(7000);
            expect(connector.Requests).toHaveLength(3);
        });
    });

    describe('date windows', () => {
        it('BuildSpektrixDateWindows: calendar-month windows, To = next From, never spanning two months', () => {
            const windows = BuildSpektrixDateWindows(new Date('2026-10-14T00:00:00Z'), new Date('2027-01-01T00:00:00Z'), null);
            expect(windows).toEqual([
                { From: '2026-10-14', To: '2026-11-01' },
                { From: '2026-11-01', To: '2026-12-01' },
                { From: '2026-12-01', To: '2027-01-01' },
            ]);
            expect(BuildSpektrixDateWindows(new Date('2026-10-01T00:00:00Z'), new Date('2026-10-20T00:00:00Z'), 7)).toEqual([
                { From: '2026-10-01', To: '2026-10-08' },
                { From: '2026-10-08', To: '2026-10-15' },
                { From: '2026-10-15', To: '2026-10-20' },
            ]);
            expect(BuildSpektrixDateWindows(new Date('2026-10-20T00:00:00Z'), new Date('2026-10-01T00:00:00Z'), null)).toEqual([]);
        });

        it('every windowed object sends EXACTLY its metadata parameter names (never normalised)', async () => {
            const windowed = META_IOS.filter(io => {
                const cfg = io.fields.Configuration as { fetchWindow?: unknown; accessPath?: { doorFetchWindow?: unknown } };
                return io.fields.Status === 'Active' && !str(io.fields.APIPath).includes('{') && (cfg.fetchWindow || cfg.accessPath?.doorFetchWindow);
            });
            expect(windowed.length).toBeGreaterThan(3);
            connector.Responder = () => ({ Status: 200, Body: [], Headers: {} });
            const ci = companyIntegration({ fetchWindowHorizonMonths: 0 });
            for (const io of windowed) {
                const cfg = io.fields.Configuration as { fetchWindow?: { fromParam: string; toParam: string }; accessPath?: { doorFetchWindow?: { fromParam: string; toParam: string } } };
                const spec = cfg.fetchWindow ?? cfg.accessPath?.doorFetchWindow;
                connector.Requests = [];
                await fetchAll(connector, str(io.fields.Name), ci);
                expect(connector.Requests.length).toBeGreaterThan(0);
                for (const req of connector.Requests) {
                    const params = relativePath(req.url).params;
                    expect(params.get(spec!.fromParam)).toBe('2026-10-14');
                    expect(params.get(spec!.toParam)).toBe('2026-11-01');
                }
            }
        });

        it.each(['Event', 'Instance'])('%s: strict fixture windows W1 + W2 are both read, starting today', async (objectName) => {
            const expected = FIXTURES.FetchWindows.find(w => w.Object === objectName)!;
            const batches = await fetchAll(connector, objectName, companyIntegration());
            expect(batches.flatMap(b => ids(b)).sort()).toEqual(expected.Windows.flatMap(w => w.RecordIDs).sort());
            const froms = connector.Requests.map(r => relativePath(r.url).params.get(expected.FromParam));
            expect(froms[0]).toBe('2026-10-14');
            expect(froms).toContain('2026-11-01');
            expect(froms).toHaveLength(13);
        });

        it('lenient Order windows are de-duplicated within a call (5 unique orders, not 60)', async () => {
            const batches = await fetchAll(connector, 'Order', companyIntegration());
            expect(batches).toHaveLength(1);
            expect(new Set(ids(batches[0])).size).toBe(ids(batches[0]).length);
            expect(ids(batches[0])).toHaveLength(5);
        });

        it('is resumable: a full batch hands back NextAfterKeyValue and the next call starts at that window', async () => {
            const ci = companyIntegration();
            const first = await connector.FetchChanges({ CompanyIntegration: ci, ObjectName: 'Event', WatermarkValue: null, BatchSize: 3, ContextUser: USER });
            expect(first.HasMore).toBe(true);
            expect(first.NextAfterKeyValue).toBe('window:2026-11-01');
            connector.Requests = [];
            const second = await connector.FetchChanges({ CompanyIntegration: ci, ObjectName: 'Event', WatermarkValue: null, BatchSize: 3, ContextUser: USER, AfterKeyValue: first.NextAfterKeyValue });
            expect(relativePath(connector.Requests[0].url).params.get('instanceStart_from')).toBe('2026-11-01');
            expect(ids(second)).toHaveLength(2);
        });

        it('takes window start / size / per-object overrides from the CONNECTION Configuration', async () => {
            connector.Responder = () => ({ Status: 200, Body: [], Headers: {} });
            await fetchAll(connector, 'Instance', companyIntegration({ fetchWindowStart: '2026-01-01', fetchWindowEnd: '2026-01-15', fetchWindowDays: 7 }));
            expect(connector.Requests.map(r => relativePath(r.url).params.get('startFrom'))).toEqual(['2026-01-01', '2026-01-08']);
            connector.Requests = [];
            await fetchAll(connector, 'Order', companyIntegration({ fetchWindows: { Order: { start: '2025-12-20', end: '2026-01-05' } } }));
            expect(connector.Requests.map(r => [relativePath(r.url).params.get('DateFrom'), relativePath(r.url).params.get('DateTo')]))
                .toEqual([['2025-12-20', '2026-01-01'], ['2026-01-01', '2026-01-05']]);
            // The door's override governs every object read through that door (Customer ← /orders).
            connector.Requests = [];
            await fetchAll(connector, 'Customer', companyIntegration({ fetchWindows: { Order: { start: '2025-12-20', end: '2026-01-05' } } }));
            expect(connector.Requests.map(r => relativePath(r.url).params.get('DateFrom'))).toEqual(['2025-12-20', '2026-01-01']);
        });
    });

    describe('access-path nesting (Order + Customer from the /orders door)', () => {
        it('Customer rows are the nested customer objects of each order, with attribute_* passed through', async () => {
            const [batch] = await fetchAll(connector, 'Customer', companyIntegration());
            expect(ids(batch).sort()).toEqual(['61001HRCFJBQJRMYVJIXMOTTMDBJAHKIM', '61002EAVWEMNDKPMLYZIIIDDLXPPKQJTW', '61003FLCXOVTUZLIJBIMBWUKQTSVMSXCN', '61004CKKQVIVOALYMERYPCXAWVFGVMJJX', '61005DLWZHHRYOUVGZHLINCKBDSVTSNGK']);
            const fields = batch.Records[0].Fields;
            expect(fields.attribute_FixtureFlag).toBeDefined();
            expect(fields.attribute_FixtureNote).toBeDefined();
            expect(relativePath(connector.Requests[0].url).path).toBe('/orders');
        });

        it('honours Configuration.expand on the door request and tags the declared parent key', async () => {
            const [batch] = await fetchAll(connector, 'Ticket', companyIntegration());
            const params = relativePath(connector.Requests[0].url).params;
            expect(params.getAll('$expand')).toEqual(['tickets']);
            expect(params.get('DateFrom')).toBe('2026-10-14');
            for (const record of batch.Records) expect(str(record.Fields.orderId)).toMatch(/^75\d{3}/);
        });

        it('a two-level path tags from the ancestor the metadata names (CustomItem ← MerchandiseItem; Address ← Order)', async () => {
            const [items] = await fetchAll(connector, 'CustomItem', companyIntegration());
            expect(items.Records.length).toBe(20);
            for (const r of items.Records) expect(str(r.Fields.merchandiseItemId)).toMatch(/^130\d{2}/);
            expect(relativePath(connector.Requests[0].url).params.get('$expand')).toBe('merchandiseItems/customItems');
            const [addresses] = await fetchAll(connector, 'Address', companyIntegration());
            expect(addresses.Records.length).toBe(10);
            for (const r of addresses.Records) expect(str(r.Fields.orderId)).toMatch(/^75\d{3}/);
        });

        it('typed references are stored as their valuePath; embedded json objects as JSON text; collections untouched', async () => {
            const [orders] = await fetchAll(connector, 'Order', companyIntegration());
            const order = orders.Records.find(r => r.Fields.id === '75001NPCDVLMLKIBMORFHYZYIVSNQYHUG')!.Fields;
            expect(order.customer).toBe('61001HRCFJBQJRMYVJIXMOTTMDBJAHKIM');
            expect(Array.isArray(order.tickets)).toBe(true);
            const [customers] = await fetchAll(connector, 'Customer', companyIntegration());
            const customer = customers.Records.find(r => r.Fields.id === '61001HRCFJBQJRMYVJIXMOTTMDBJAHKIM')!.Fields;
            expect(customer.billingAddress).toBe('24001WECRAEEMIRUMSJDAUOJGXURJDYSX');
            expect(JSON.parse(str(customer.creditBalance))).toEqual({ tinyValue: 7.5 });
        });

        it('unions recursive same-object collections (Plan.areas) and tags the parent key', async () => {
            const [batch] = await fetchAll(connector, 'Plan', companyIntegration());
            const area = batch.Records.find(r => r.Fields.id === '70006ZOTZJFDBTTLAPJUTTADRBOVRVDSD');
            expect(area?.Fields.parentPlanId).toBe('70001WXIDLDTVRFVEHVCPTERKHBKDKHMU');
            expect(batch.Records).toHaveLength(6);
            expect(relativePath(connector.Requests[0].url).params.get('$expand')).toBe('areas');
        });
    });

    describe('template-var children (base-class parent iteration)', () => {
        const customerIDs = ['61001HRCFJBQJRMYVJIXMOTTMDBJAHKIM', '61002EAVWEMNDKPMLYZIIIDDLXPPKQJTW', '61005DLWZHHRYOUVGZHLINCKBDSVTSNGK'];

        it('substitutes each parent into the child route; JSON-404 ResourceNotFound = no rows for that parent (warned)', async () => {
            parentRows.set('Customer', customerIDs.map(id => ({ id })));
            const batch = await connector.FetchChanges({ CompanyIntegration: companyIntegration(), ObjectName: 'CustomerAddress', WatermarkValue: null, BatchSize: 200, ContextUser: USER });
            expect(connector.Requests.map(r => relativePath(r.url).path)).toEqual(customerIDs.map(id => `/customers/${id}/addresses`));
            expect(batch.Records.length).toBeGreaterThan(0);
            expect(batch.Records.every(r => customerIDs.slice(0, 2).includes(str(r.Fields.customerId)))).toBe(true);
            const warning = batch.Warnings?.find(w => w.Code === 'PARENT_NOT_FOUND');
            expect(warning?.Data?.parents).toEqual([FIXTURES.ErrorRoutes.NotFound.ParentID]);
        });

        it('walks a nested detail door (/customers/{id}?$expand=allTags → allTags[]) and keys it on the composite PK', async () => {
            parentRows.set('Customer', [{ id: customerIDs[0] }]);
            const batch = await connector.FetchChanges({ CompanyIntegration: companyIntegration(), ObjectName: 'CustomerTag', WatermarkValue: null, BatchSize: 200, ContextUser: USER });
            expect(relativePath(connector.Requests[0].url).params.get('$expand')).toBe('allTags');
            expect(batch.Records.map(r => r.ExternalID)).toEqual([
                `59002EIXRMEJNPGQLLQUOTUSYEXRKHLRV|${customerIDs[0]}`,
                `59003FDGULKBNZWMRONYBQMXHTXZOOCIH|${customerIDs[0]}`,
            ]);
        });

        it('keys CustomerTagGroup on (customerId, id): the documented group Id plus the detail door\'s tagged parent key', async () => {
            parentRows.set('Customer', [{ id: customerIDs[0] }]);
            const batch = await connector.FetchChanges({ CompanyIntegration: companyIntegration(), ObjectName: 'CustomerTagGroup', WatermarkValue: null, BatchSize: 200, ContextUser: USER });
            expect(relativePath(connector.Requests[0].url).params.get('$expand')).toBe('allTagsByGroup');
            expect(batch.Records.map(r => r.ExternalID)).toEqual([`1|${customerIDs[0]}`, `2|${customerIDs[0]}`]);
            expect(batch.Records.every(r => r.Fields.customerId === customerIDs[0])).toBe(true);
        });

        it('a windowed child sends ONE full-span window per parent with its exact parameter names', async () => {
            parentRows.set('Event', [{ id: '77001TBEMCSYVHITRKAPVNHFHSXLELXSN' }]);
            const batch = await connector.FetchChanges({ CompanyIntegration: companyIntegration(), ObjectName: 'EventInstanceAvailabilityDto', WatermarkValue: null, BatchSize: 200, ContextUser: USER });
            const spec = (objectConfig('EventInstanceAvailabilityDto').accessPath as { doorFetchWindow: { fromParam: string; toParam: string } }).doorFetchWindow;
            expect(connector.Requests).toHaveLength(1);
            const params = relativePath(connector.Requests[0].url).params;
            expect(params.get(spec.fromParam)).toBe('2026-10-14');
            expect(params.get(spec.toParam)).toBe('2027-11-01');
            expect(batch.Records.length).toBeGreaterThan(0);
            expect(batch.Records.every(r => r.Fields.eventId === '77001TBEMCSYVHITRKAPVNHFHSXLELXSN')).toBe(true);
        });

        it('a nested child of a template door tags the door key (PriceList.id) and the template parent (Instance.id)', async () => {
            parentRows.set('Instance', [{ id: '60001EBOOCBKFLXOKSATFNEHTNROZWFHD' }]);
            const prices = await connector.FetchChanges({ CompanyIntegration: companyIntegration(), ObjectName: 'Price', WatermarkValue: null, BatchSize: 200, ContextUser: USER });
            expect(prices.Records.map(r => [r.Fields.priceListId, r.Fields.instanceId])).toEqual([
                ['28001ETWXZAOBALRZVHJWOUNNJKMGPDJC', '60001EBOOCBKFLXOKSATFNEHTNROZWFHD'],
                ['28001ETWXZAOBALRZVHJWOUNNJKMGPDJC', '60001EBOOCBKFLXOKSATFNEHTNROZWFHD'],
            ]);
            expect(prices.Records[0].Fields.ticketType).toBe('59001HJLWLLACOXMOJFTIIVVQQAJZZGEX');
            // PriceCustomItem (PriceList → prices[] → customItems[]) is Disabled — no provable key (sources/derived/identity-decisions.json).
            expect(relativePath(connector.Requests[connector.Requests.length - 1].url).params.get('$expand')).toBe('prices');
        });

        it('discovery samples a child by streaming its parent through FetchChanges (no database)', async () => {
            const sampled = await connector.DiscoverFieldsViaFetch(companyIntegration(), 'CustomerAddress', USER, { MaxRecords: 3 });
            expect(sampled.map(f => f.Name)).toEqual(expect.arrayContaining(['id', 'line1', 'customerId']));
            expect(connector.Requests.some(r => relativePath(r.url).path === '/orders')).toBe(true);
            expect(connector.Requests.some(r => /\/customers\/\w+\/addresses$/.test(relativePath(r.url).path))).toBe(true);
        });
    });

    describe('discovery', () => {
        it('DiscoverObjects returns the Declared active objects without a credential or a request', async () => {
            const objects = await connector.DiscoverObjects(companyIntegration({ ApiSecretKey: '' }), USER);
            const active = META_IOS.filter(io => io.fields.Status === 'Active').map(io => str(io.fields.Name)).sort();
            expect(objects.map(o => o.Name).sort()).toEqual(active);
            expect(connector.Requests).toHaveLength(0);
        });

        it('IntrospectSchema unions sampled attribute_* custom columns onto the Declared floor', async () => {
            const info = await connector.IntrospectSchema(companyIntegration(), USER, { ObjectNames: ['Event'] });
            expect(info.IsAuthoritative).toBe(false);
            const names = info.Objects[0].Fields.map(f => f.Name);
            expect(names).toEqual(expect.arrayContaining(['id', 'name', 'attribute_FixtureFlag', 'attribute_FixtureNote']));
            const declared = (META_IOS.find(io => io.fields.Name === 'Event')!.relatedEntities!['MJ: Integration Object Fields'] ?? []).map(r => str(r.fields.Name));
            // Declared floor first (nothing removed), tenant customs appended after it.
            expect([...names.slice(0, declared.length)].sort()).toEqual([...declared].sort());
            expect(names.indexOf('attribute_FixtureFlag')).toBeGreaterThanOrEqual(declared.length);
        });
    });

    describe('connection test + GetRecord', () => {
        it('probes a System-Owner-only door from metadata and passes on a JSON 200', async () => {
            const result = await connector.TestConnection(companyIntegration(), USER);
            expect(result.Success).toBe(true);
            const probePath = relativePath(connector.Requests[0].url).path;
            const probe = META_IOS.find(io => io.fields.APIPath === probePath)!;
            expect((objectConfig(str(probe.fields.Name)).door as { modes: string[] }).modes).toEqual(['Owner']);
            expect(connector.Requests[0].headers.Authorization).toMatch(/^SpektrixAPI3 /);
        });

        it('fails (without leaking the secret) when the signature is rejected', async () => {
            connector.Responder = () => ({ Status: 401, Body: { message: 'Authorization has been denied' }, Headers: {} });
            const result = await connector.TestConnection(companyIntegration(), USER);
            expect(result.Success).toBe(false);
            expect(result.Message).toMatch(/401/);
            expect(result.Message).not.toContain(SECRET_B64);
        });

        it('re-fetches through the declared get-by-id door; JSON 404 → null; no door → refused', async () => {
            const record = await connector.GetRecord({ CompanyIntegration: companyIntegration(), ObjectName: 'Event', ExternalID: '77001TBEMCSYVHITRKAPVNHFHSXLELXSN', ContextUser: USER });
            expect(relativePath(connector.Requests[0].url).path).toBe('/events/77001TBEMCSYVHITRKAPVNHFHSXLELXSN');
            expect(record?.Fields.attribute_FixtureFlag).toBeDefined();
            connector.Responder = () => ({ Status: 404, Body: { resourceType: 'Order', resourceIdentifiers: { id: 'x' }, errorCode: 'ResourceNotFound' }, Headers: {} });
            expect(await connector.GetRecord({ CompanyIntegration: companyIntegration(), ObjectName: 'Order', ExternalID: 'x', ContextUser: USER })).toBeNull();
            await expect(connector.GetRecord({ CompanyIntegration: companyIntegration(), ObjectName: 'Ticket', ExternalID: 'x', ContextUser: USER })).rejects.toThrow(/get-by-id/);
        });
    });

    describe('write request construction (mocked — nothing is mutated)', () => {
        const ok = (body: unknown, headers: Record<string, string> = {}): Responder => () => ({ Status: 200, Body: body, Headers: headers });

        it('CustomerTag delete substitutes BOTH vars and keeps the query string (/customers/tags/{id}?id={customerId})', async () => {
            connector.Responder = ok(null);
            const result = await connector.DeleteRecord({ CompanyIntegration: companyIntegration(), ObjectName: 'CustomerTag', ExternalID: 'TAG1|CUST9', ContextUser: USER });
            expect(result.Success).toBe(true);
            const sent = connector.Requests[0];
            expect(sent.method).toBe('DELETE');
            expect(sent.url).toBe(`${BASE_URL}/customers/tags/TAG1?id=CUST9`);
            expect(sent.body).toBeUndefined();
            expect(sent.headers.Authorization).toBe(`SpektrixAPI3 ${FIXTURES.Configuration.ApiLoginName}:${expectedSignature('DELETE', sent.url, sent.headers.Date)}`);
        });

        it('CustomerAddress create resolves the parent scope from attributes, keeps it out of the body and returns the composite ExternalID', async () => {
            connector.Responder = ok({ id: 'ADDR1', line1: '1 Street' });
            const result = await connector.CreateRecord({ CompanyIntegration: companyIntegration(), ObjectName: 'CustomerAddress', ContextUser: USER, Attributes: { customerId: 'CUST9', line1: '1 Street', id: 'ignored-read-only' } });
            expect(result).toEqual({ Success: true, StatusCode: 200, ExternalID: 'ADDR1|CUST9' });
            const sent = connector.Requests[0];
            expect([sent.method, relativePath(sent.url).path]).toEqual(['POST', '/customers/CUST9/addresses']);
            expect(JSON.parse(sent.body!)).toEqual({ line1: '1 Street' });
            expect(sent.headers.Authorization).toBe(`SpektrixAPI3 ${FIXTURES.Configuration.ApiLoginName}:${expectedSignature('POST', sent.url, sent.headers.Date, sent.body)}`);
        });

        it('CustomerAddress update + delete resolve {customerId} from the composite ExternalID alone (a delete carries no attributes)', async () => {
            connector.Responder = ok({ id: 'ADDR1', line1: '2 Street' });
            const updated = await connector.UpdateRecord({ CompanyIntegration: companyIntegration(), ObjectName: 'CustomerAddress', ExternalID: 'ADDR1|CUST9', ContextUser: USER, Attributes: { line1: '2 Street' } });
            expect(updated.Success).toBe(true);
            expect([connector.Requests[0].method, relativePath(connector.Requests[0].url).path]).toEqual(['PATCH', '/customers/CUST9/addresses/ADDR1']);
            expect(JSON.parse(connector.Requests[0].body!)).toEqual({ line1: '2 Street' });
            connector.Requests = [];
            connector.Responder = ok(null);
            const deleted = await connector.DeleteRecord({ CompanyIntegration: companyIntegration(), ObjectName: 'CustomerAddress', ExternalID: 'ADDR1|CUST9', ContextUser: USER });
            expect(deleted.Success).toBe(true);
            const sent = connector.Requests[0];
            expect([sent.method, relativePath(sent.url).path]).toEqual(['DELETE', '/customers/CUST9/addresses/ADDR1']);
            expect(sent.body).toBeUndefined();
            expect(sent.headers.Authorization).toBe(`SpektrixAPI3 ${FIXTURES.Configuration.ApiLoginName}:${expectedSignature('DELETE', sent.url, sent.headers.Date)}`);
        });

        it('Customer update is a first-level PATCH of the writable attributes only', async () => {
            connector.Responder = ok({});
            const result = await connector.UpdateRecord({ CompanyIntegration: companyIntegration(), ObjectName: 'Customer', ExternalID: 'CUST9', ContextUser: USER, Attributes: { email: 'a@example.invalid', name: 'read-only full name', attribute_Tier: 'Gold' } });
            expect(result.Success).toBe(true);
            const sent = connector.Requests[0];
            expect([sent.method, relativePath(sent.url).path]).toEqual(['PATCH', '/customers/CUST9']);
            expect(JSON.parse(sent.body!)).toEqual({ email: 'a@example.invalid', attribute_Tier: 'Gold' });
        });

        it('Order attribute PATCH (literal) sends only the custom attributes', async () => {
            connector.Responder = ok({});
            await connector.UpdateRecord({ CompanyIntegration: companyIntegration(), ObjectName: 'Order', ExternalID: 'ORD1', ContextUser: USER, Attributes: { notes: 'x', attribute_Source: 'Web' } });
            const sent = connector.Requests[0];
            expect([sent.method, relativePath(sent.url).path]).toEqual(['PATCH', '/orders/ORD1/attributes']);
            expect(JSON.parse(sent.body!)).toEqual({ attribute_Source: 'Web' });
            connector.Requests = [];
            const empty = await connector.UpdateRecord({ CompanyIntegration: companyIntegration(), ObjectName: 'Order', ExternalID: 'ORD1', ContextUser: USER, Attributes: { notes: 'x' } });
            expect(empty.Success).toBe(false);
            expect(connector.Requests).toHaveLength(0);
        });

        it('CustomerAgreedStatement create posts a one-element array and returns the composite ExternalID', async () => {
            connector.Responder = ok([{ id: 'OTHER' }, { id: 'STMT1', text: 't', agreed: true }]);
            const result = await connector.CreateRecord({ CompanyIntegration: companyIntegration(), ObjectName: 'CustomerAgreedStatement', ContextUser: USER, Attributes: { customerId: 'CUST9', id: 'STMT1', text: 'read-only' } });
            const sent = connector.Requests[0];
            expect(relativePath(sent.url).path).toBe('/customers/CUST9/agreed-statements');
            expect(JSON.parse(sent.body!)).toEqual([{ id: 'STMT1' }]);
            expect(result).toEqual({ Success: true, StatusCode: 200, ExternalID: 'STMT1|CUST9' });
        });

        it('Event create (ID location n/a) accepts a Location header when the body carries no id', async () => {
            connector.Responder = ok(null, { location: `${BASE_URL}/events/EVT42` });
            const result = await connector.CreateRecord({ CompanyIntegration: companyIntegration(), ObjectName: 'Event', ContextUser: USER, Attributes: { name: 'New' } });
            expect(result).toEqual({ Success: true, StatusCode: 200, ExternalID: 'EVT42' });
        });

        it('PriceList update sends the documented PricePatch items as structured JSON, even with the runtime Type of prices overlaid', async () => {
            seedEngine(f => (f.ID === 'iof-PriceList-prices' ? { ...f, Type: 'nvarchar(MAX)' } : f)); // what runtime discovery leaves in the DB
            connector.Responder = ok({ prices: [], id: 'PL1' });
            const prices = [
                { isBandDefault: true, amount: 7.5, ticketType: { name: 'TT', id: 'TT1' }, priceBand: { name: 'B', id: 'B1' }, customItems: [], id: 'P1' },
                { ticketTypeId: 'TT2', priceBandId: 'B2', updatedPrice: 9, extra: 'dropped' },
            ];
            const result = await connector.UpdateRecord({ CompanyIntegration: companyIntegration(), ObjectName: 'PriceList', ExternalID: 'PL1', ContextUser: USER, Attributes: { instanceId: 'INST1', prices: JSON.stringify(prices) } });
            expect(result.Success).toBe(true);
            const sent = connector.Requests[0];
            expect([sent.method, relativePath(sent.url).path]).toEqual(['PATCH', '/instances/INST1/price-list']);
            expect(JSON.parse(sent.body!)).toEqual({ prices: [{ ticketTypeId: 'TT1', priceBandId: 'B1', updatedPrice: 7.5 }, { ticketTypeId: 'TT2', priceBandId: 'B2', updatedPrice: 9 }] });
        });

        it('refuses (no request) when a path variable cannot be resolved', async () => {
            const result = await connector.UpdateRecord({ CompanyIntegration: companyIntegration(), ObjectName: 'PriceList', ExternalID: 'PL1', ContextUser: USER, Attributes: { prices: '[]' } });
            expect(result.Success).toBe(false);
            expect(result.ErrorMessage).toMatch(/\{instanceId\}/);
            expect(connector.Requests).toHaveLength(0);
        });

        it('returns the vendor status + message on a failed write instead of throwing', async () => {
            connector.Responder = () => ({ Status: 400, Body: { Message: 'The request is invalid.', ModelState: { email: ['bad'] } }, Headers: {} });
            const result = await connector.UpdateRecord({ CompanyIntegration: companyIntegration(), ObjectName: 'Customer', ExternalID: 'CUST9', ContextUser: USER, Attributes: { email: 'bad' } });
            expect(result.Success).toBe(false);
            expect(result.StatusCode).toBe(400);
            expect(result.ErrorMessage).toContain('The request is invalid.');
        });
    });
});
