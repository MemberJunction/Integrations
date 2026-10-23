/**
 * InformzConnector — credential-free, read-only unit tests (T4).
 *
 * NOTHING here touches the network or mutates anything: `MockedInformzConnector` replaces the raw
 * transport (`SendHTTP`) with a responder and `Sleep` with a recorder. The integration metadata is
 * the REAL frozen metadata file (seeded into IntegrationEngineBase exactly the way the offline tier
 * harness seeds it), and replayed responses come from the registry fixture file
 * (connectors-registry/informz/fixtures/fixtures.json — provenance recorded inside it). The few
 * fault / throttle / JSON bodies that the fixture set does not carry are built inline from the
 * documented wire shapes (WSDL InformzServiceFault, help-center InformzAAPIFault).
 */
import { describe, it, expect, beforeEach } from 'vitest';
import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import type { UserInfo } from '@memberjunction/core';
import { MJGlobal } from '@memberjunction/global';
import type {
    MJCompanyIntegrationEntity,
    MJIntegrationEntity,
    MJIntegrationObjectEntity,
    MJIntegrationObjectFieldEntity,
} from '@memberjunction/core-entities';
import { IntegrationEngineBase } from '@memberjunction/integration-engine-base';
import {
    BaseIntegrationConnector,
    ClassifyError,
    IsRetryableError,
    type FetchContext,
    type PaginationState,
} from '@memberjunction/integration-engine';
import { InformzAPIError, InformzConnector, type InformzGridPage, type InformzWireResponse } from '../InformzConnector.js';

// ─── Real metadata + fixtures ─────────────────────────────────────────────────────────────────────

const HERE = dirname(fileURLToPath(import.meta.url));
// The catalog this package ships, and the doc-derived wire fixtures vendored beside this test.
const METADATA_FILE = resolve(HERE, '../../metadata/integration/.informz.integration.json');
const FIXTURES_FILE = resolve(HERE, 'fixtures/informz/fixtures.json');
const CONNECTOR_SOURCE = resolve(HERE, '../InformzConnector.ts');

interface MetadataRow {
    fields: Record<string, unknown>;
    relatedEntities?: Record<string, MetadataRow[]>;
}

interface FixtureRoute {
    Match?: string[];
    Status?: number;
    Headers?: Record<string, string>;
    Body: unknown;
}

interface FixtureManifest {
    Configuration: Record<string, unknown>;
    Routes: FixtureRoute[];
}

interface TransportFacts {
    soapAction: string;
    namespace: string;
    requestWrapper: string;
    wsdlServiceAddress: string;
}

const METADATA_ROOT = (JSON.parse(readFileSync(METADATA_FILE, 'utf8')) as MetadataRow[])[0];
const FIXTURES = JSON.parse(readFileSync(FIXTURES_FILE, 'utf8')) as FixtureManifest;
const INTEGRATION_CONFIG = asRecord(parseMaybeJSON(METADATA_ROOT.fields.Configuration));
const TRANSPORT = INTEGRATION_CONFIG.Transport as TransportFacts;
const REGION_HOSTS = INTEGRATION_CONFIG.RegionHosts as Record<string, string>;
const INTEGRATION_ID = 'informz-test-integration';
const SERVICE_URL = 'http://127.0.0.1:9';

function parseMaybeJSON(value: unknown): unknown {
    return typeof value === 'string' ? JSON.parse(value) : value;
}

function asRecord(value: unknown): Record<string, unknown> {
    return (value ?? {}) as Record<string, unknown>;
}

function ioRows(): MetadataRow[] {
    return METADATA_ROOT.relatedEntities?.['MJ: Integration Objects'] ?? [];
}

function ioRow(name: string): MetadataRow {
    const row = ioRows().find(r => r.fields.Name === name);
    if (!row) throw new Error(`metadata has no IO "${name}"`);
    return row;
}

/** An IO with no Declared primary key — read from the metadata so a later doc-backed PK can't invalidate the test. */
function firstKeylessIOName(): string {
    const row = ioRows().find(r => !(r.relatedEntities?.['MJ: Integration Object Fields'] ?? []).some(f => f.fields.IsPrimaryKey === true));
    if (!row) throw new Error('metadata has no IO without a Declared primary key');
    return String(row.fields.Name);
}

function iofNames(ioName: string): string[] {
    return (ioRow(ioName).relatedEntities?.['MJ: Integration Object Fields'] ?? [])
        .slice()
        .sort((a, b) => Number(a.fields.Sequence) - Number(b.fields.Sequence))
        .map(r => String(r.fields.Name));
}

/** Plain-object rows shaped like the entities — the same seeding the offline tier harness performs. */
function seedRow<T>(fields: Record<string, unknown>, extra: Record<string, unknown>): Partial<T> {
    const row: Record<string, unknown> = {};
    for (const [key, value] of Object.entries(fields)) {
        if (typeof value === 'string' && (value.startsWith('@lookup:') || value.startsWith('@parent:'))) row[key] = null;
        else if (key === 'Configuration' && value !== null && typeof value === 'object') row[key] = JSON.stringify(value);
        else row[key] = value;
    }
    if (row.Status == null) row.Status = 'Active';
    return { ...row, ...extra } as Partial<T>;
}

function seedEngine(): void {
    const ios: Array<Partial<MJIntegrationObjectEntity>> = [];
    const iofs: Array<Partial<MJIntegrationObjectFieldEntity>> = [];
    ioRows().forEach((io, i) => {
        const ioID = `seed-io-${i + 1}`;
        ios.push(seedRow<MJIntegrationObjectEntity>(io.fields, { ID: ioID, IntegrationID: INTEGRATION_ID }));
        (io.relatedEntities?.['MJ: Integration Object Fields'] ?? []).forEach((f, j) => {
            iofs.push(seedRow<MJIntegrationObjectFieldEntity>(f.fields, { ID: `seed-iof-${i + 1}-${j + 1}`, IntegrationObjectID: ioID }));
        });
    });
    IntegrationEngineBase.Instance.SeedForTesting({
        Integrations: [seedRow<MJIntegrationEntity>(METADATA_ROOT.fields, { ID: INTEGRATION_ID })],
        IntegrationObjects: ios,
        IntegrationObjectFields: iofs,
    });
}

function companyIntegration(configuration: Record<string, unknown>): MJCompanyIntegrationEntity {
    return {
        ID: `ci-${JSON.stringify(configuration).length}`,
        IntegrationID: INTEGRATION_ID,
        Name: 'informz-test',
        CredentialID: null,
        Configuration: JSON.stringify(configuration),
    } as unknown as MJCompanyIntegrationEntity;
}

const USER = { ID: 'test-user', Email: 'test@example.invalid', Name: 'test' } as unknown as UserInfo;

function baseConfig(overrides: Record<string, unknown> = {}): Record<string, unknown> {
    return { ...FIXTURES.Configuration, ServiceURL: SERVICE_URL, ...overrides };
}

function fetchContext(ci: MJCompanyIntegrationEntity, objectName: string, extra: Partial<FetchContext> = {}): FetchContext {
    return { CompanyIntegration: ci, ObjectName: objectName, WatermarkValue: null, BatchSize: 100, ContextUser: USER, ...extra };
}

// ─── Mocked transport ─────────────────────────────────────────────────────────────────────────────

interface CapturedRequest {
    URL: string;
    Headers: Record<string, string>;
    Body: string;
}

type Responder = (request: CapturedRequest, index: number) => InformzWireResponse;

class MockedInformzConnector extends InformzConnector {
    public Requests: CapturedRequest[] = [];
    public Sleeps: number[] = [];
    public Responder: Responder = () => { throw new Error('no responder configured'); };

    protected override async SendHTTP(url: string, headers: Record<string, string>, body: string): Promise<InformzWireResponse> {
        const request = { URL: url, Headers: { ...headers }, Body: body };
        this.Requests.push(request);
        return this.Responder(request, this.Requests.length - 1);
    }

    protected override async Sleep(ms: number): Promise<void> {
        this.Sleeps.push(ms);
    }

    public Paging(body: InformzGridPage): PaginationState {
        return this.ExtractPaginationInfo(body, 'Offset', 1, body.StartRow, body.RequestedRows);
    }
}

/** Replays fixture routes with the offline mock's semantics: every Match substring present; most specific wins. */
function fixtureResponder(routes: FixtureRoute[] = FIXTURES.Routes): Responder {
    return (request) => {
        const body = request.Body.toLowerCase();
        let best: FixtureRoute | null = null;
        for (const route of routes) {
            const match = (route.Match ?? []).map(m => m.toLowerCase());
            if (!match.every(m => body.includes(m))) continue;
            if (!best || match.length > (best.Match ?? []).length) best = route;
        }
        if (!best) return { Status: 404, Headers: { 'content-type': 'application/json' }, Text: '{"error":"no fixture"}' };
        return {
            Status: best.Status ?? 200,
            Headers: lowerKeys(best.Headers ?? {}),
            Text: typeof best.Body === 'string' ? best.Body : JSON.stringify(best.Body),
        };
    };
}

function lowerKeys(headers: Record<string, string>): Record<string, string> {
    return Object.fromEntries(Object.entries(headers).map(([k, v]) => [k.toLowerCase(), v]));
}

function escapeXml(value: string): string {
    return value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&apos;');
}

function unescapeXml(value: string): string {
    return value.replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&apos;/g, "'").replace(/&amp;/g, '&');
}

/** The GridRequest document carried (escaped) inside the envelope's request wrapper. */
function gridRequestOf(request: CapturedRequest): string {
    const wrapper = TRANSPORT.requestWrapper.trim().split(/\s/)[0];
    const match = new RegExp(`<${wrapper}>([\\s\\S]*)</${wrapper}>`).exec(request.Body);
    if (!match) throw new Error('request carries no wrapper element');
    return unescapeXml(match[1]);
}

/** A SOAP response whose result is an escaped GridResponse — the fixture wire shape. */
function gridEnvelope(gridType: string, records: Array<{ Row: number; Fields: Array<[string, string | null]> }>): InformzWireResponse {
    const grid = records.length === 0
        ? `<Grid type="${gridType}"/>`
        : `<Grid type="${gridType}">${records.map(r => `<Record row="${r.Row}"><Fields>${r.Fields.map(([k, v]) =>
            v === null ? `<Field element="${k}" />` : `<Field element="${k}">${escapeXml(v)}</Field>`).join('')}</Fields></Record>`).join('')}</Grid>`;
    const doc = `<?xml version="1.0" encoding="utf-8"?><GridResponse><Brand id="1" /><User>u</User><Grids>${grid}</Grids></GridResponse>`;
    return {
        Status: 200,
        Headers: { 'content-type': 'text/xml; charset=utf-8' },
        Text: `<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Body><PostInformzMessageResponse><PostInformzMessageResult>${escapeXml(doc)}</PostInformzMessageResult></PostInformzMessageResponse></s:Body></s:Envelope>`,
    };
}

/** SOAP 1.1 fault: WSDL `InformzServiceFault` (Code/Message/Reason) or help-center `InformzAAPIFault` (code/reason). */
function faultEnvelope(shape: 'InformzServiceFault' | 'InformzAAPIFault', code: string, reason: string, status = 500): InformzWireResponse {
    const detail = shape === 'InformzServiceFault'
        ? `<InformzServiceFault xmlns="urn:fault-ns"><Code>${code}</Code><Message>m</Message><Reason>${escapeXml(reason)}</Reason></InformzServiceFault>`
        : `<f:InformzAAPIFault xmlns:f="urn:other-fault-ns"><f:code>${code}</f:code><f:reason>${escapeXml(reason)}</f:reason></f:InformzAAPIFault>`;
    return {
        Status: status,
        Headers: { 'content-type': 'text/xml; charset=utf-8' },
        Text: `<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Body><s:Fault><faultcode>s:Client</faultcode><faultstring>${escapeXml(reason)}</faultstring><detail>${detail}</detail></s:Fault></s:Body></s:Envelope>`,
    };
}

async function captureError(promise: Promise<unknown>): Promise<InformzAPIError> {
    try {
        await promise;
    } catch (err) {
        if (err instanceof InformzAPIError) return err;
        throw err;
    }
    throw new Error('expected the call to throw');
}

function indexesInOrder(text: string, needles: string[]): boolean {
    let last = -1;
    for (const needle of needles) {
        const at = text.indexOf(needle);
        if (at <= last) return false;
        last = at;
    }
    return true;
}

// ─── Suite ────────────────────────────────────────────────────────────────────────────────────────

describe('InformzConnector', () => {
    let connector: MockedInformzConnector;

    beforeEach(() => {
        seedEngine();
        connector = new MockedInformzConnector();
        connector.Responder = fixtureResponder();
    });

    describe('identity + pull-only scope', () => {
        it('reports the verbatim integration name and registers under its class name', () => {
            expect(connector.IntegrationName).toBe(METADATA_ROOT.fields.Name);
            expect(MJGlobal.Instance.ClassFactory.GetRegistration(BaseIntegrationConnector, 'InformzConnector')).not.toBeNull();
        });

        it('declares no write capability and refuses every writer', async () => {
            expect([connector.SupportsCreate, connector.SupportsUpdate, connector.SupportsDelete, connector.SupportsUpsert]).toEqual([false, false, false, false]);
            expect(connector.DiscoveryIsAuthoritative).toBe(false);
            const ctx = { CompanyIntegration: companyIntegration(baseConfig()), ObjectName: 'Subscriber', ContextUser: USER };
            await expect(connector.CreateRecord({ ...ctx, Attributes: {} })).rejects.toThrow(/pull-only connector \(operator scope\)/);
            await expect(connector.UpdateRecord({ ...ctx, ExternalID: '1', Attributes: {} })).rejects.toThrow(/pull-only connector \(operator scope\)/);
            await expect(connector.DeleteRecord({ ...ctx, ExternalID: '1' })).rejects.toThrow(/pull-only connector \(operator scope\)/);
            expect(connector.Requests).toHaveLength(0);
        });
    });

    describe('SOAP envelope + GridRequest', () => {
        it('POSTs one SOAP 1.1 envelope to the service URL with the metadata SOAPAction', async () => {
            await connector.FetchChanges(fetchContext(companyIntegration(baseConfig()), 'Subscriber'));
            const first = connector.Requests[0];
            expect(first.URL).toBe(`${SERVICE_URL}/`);
            expect(first.URL).not.toMatch(/grids|mjInformz/);
            expect(first.Headers['Content-Type']).toBe('text/xml; charset=utf-8');
            expect(first.Headers.SOAPAction).toBe(`"${TRANSPORT.soapAction}"`);
            // The message namespace is the AAPI contract namespace (WCF default Action = <ns><Contract>/<Op>),
            // NOT Transport.namespace (the WSDL definitions' targetNamespace).
            const contract = TRANSPORT.soapAction.slice(0, TRANSPORT.soapAction.lastIndexOf('/'));
            const messageNamespace = contract.slice(0, contract.lastIndexOf('/') + 1);
            expect(first.Body).toContain(`<PostInformzMessage xmlns="${messageNamespace}">`);
            expect(first.Body).not.toContain(TRANSPORT.namespace);
            expect(gridRequestOf(first)).toContain(`<GridRequest xmlns="${messageNamespace}">`);
            // The exact substrings the offline mock routes on.
            expect(first.Body).toContain('type=&quot;subscriber&quot;');
            expect(first.Body).toContain('&lt;StartRow&gt;0&lt;/StartRow&gt;');
        });

        it('writes credentials and grid elements in the documented order', async () => {
            await connector.FetchChanges(fetchContext(companyIntegration(baseConfig()), 'Subscriber'));
            const doc = gridRequestOf(connector.Requests[0]);
            expect(indexesInOrder(doc, [
                '<Password>', '<Brand id="1">', '<User>fixture-user</User>', '<Grids>', '<Grid type="subscriber">',
                '<ReturnFields>', '<SortField order="asc">subscriber_id</SortField>', '<StartRow>0</StartRow>', '<NumberOfRows>2</NumberOfRows>',
            ])).toBe(true);
            expect(doc).not.toContain('<Conditions>');
        });

        it('XML-escapes every credential value (twice on the wire: document, then wrapper text)', async () => {
            const ci = companyIntegration(baseConfig({ Password: `p<&>"'w`, BrandName: 'A & B "C"', Username: "o'brien" }));
            await connector.FetchChanges(fetchContext(ci, 'AccountingCode'));
            const request = connector.Requests[0];
            const doc = gridRequestOf(request);
            expect(doc).toContain('<Password>p&lt;&amp;&gt;&quot;&apos;w</Password>');
            expect(doc).toContain('<Brand id="1">A &amp; B &quot;C&quot;</Brand>');
            expect(doc).toContain('<User>o&apos;brien</User>');
            expect(request.Body).toContain('&lt;Password&gt;p&amp;lt;&amp;amp;&amp;gt;&amp;quot;&amp;apos;w&lt;/Password&gt;');
            expect(request.Body).not.toContain(`p<&>"'w`);
        });

        it('requests every Declared field plus the connection ExtraReturnFields for the grid', async () => {
            const ci = companyIntegration(baseConfig({ ExtraReturnFields: { SUBSCRIBER: ['fixture_member_level', 'Email'] } }));
            await connector.FetchChanges(fetchContext(ci, 'Subscriber'));
            const doc = gridRequestOf(connector.Requests[0]);
            const requested = [...doc.matchAll(/<DataElement>([^<]+)<\/DataElement>/g)].map(m => m[1]);
            // Declared IOFs in Sequence order, then the extra element; 'Email' duplicates 'email' case-insensitively.
            expect(requested).toEqual([...iofNames('Subscriber'), 'fixture_member_level']);
        });
    });

    describe('paging', () => {
        it('advances StartRow from the response row numbers until a short page', async () => {
            const batch = await connector.FetchChanges(fetchContext(companyIntegration(baseConfig()), 'Subscriber'));
            const pages = connector.Requests.map(r => /<StartRow>(\d+)<\/StartRow><NumberOfRows>(\d+)<\/NumberOfRows>/.exec(gridRequestOf(r))?.slice(1));
            expect(pages).toEqual([['0', '2'], ['3', '2'], ['5', '2']]);
            expect(batch.Records.map(r => r.ExternalID)).toEqual(['140001', '140002', '140003', '140004']);
            expect(batch.HasMore).toBe(false);
        });

        it('caps NumberOfRows at the documented maximum and at the remaining batch capacity', async () => {
            const maxRows = Number(asRecord(asRecord(parseMaybeJSON(ioRow('AccountingCode').fields.Configuration)).paging).maxRowsPerRequest);
            connector.Responder = () => gridEnvelope('accounting_code', []);
            const ci = companyIntegration(baseConfig({ PageSize: maxRows * 5 }));
            await connector.FetchChanges(fetchContext(ci, 'AccountingCode', { BatchSize: maxRows * 10 }));
            await connector.FetchChanges(fetchContext(ci, 'AccountingCode', { BatchSize: 7 }));
            const rows = connector.Requests.map(r => /<NumberOfRows>(\d+)<\/NumberOfRows>/.exec(gridRequestOf(r))?.[1]);
            expect(rows).toEqual([String(maxRows), '7']);
        });

        it('stops mid-pagination with a resumable offset when the batch is full', async () => {
            const ci = companyIntegration(baseConfig());
            const first = await connector.FetchChanges(fetchContext(ci, 'Subscriber', { BatchSize: 2 }));
            expect(first.Records).toHaveLength(2);
            expect(first.HasMore).toBe(true);
            expect(first.NextOffset).toBe(3);
            const second = await connector.FetchChanges(fetchContext(ci, 'Subscriber', { BatchSize: 2, CurrentOffset: first.NextOffset }));
            expect(second.Records.map(r => r.ExternalID)).toEqual(['140003', '140004']);
        });

        it('computes HasMore / NextOffset from row numbers with a duplicate-page guard', () => {
            const page = (startRow: number, rows: Array<number | null>, requested: number): InformzGridPage => ({
                Kind: 'InformzGridPage', GridType: 'subscriber', StartRow: startRow, RequestedRows: requested,
                Records: rows.map(row => ({ Row: row, Fields: [] })),
            });
            expect(connector.Paging(page(0, [1, 2], 2))).toEqual({ HasMore: true, NextOffset: 3 });
            expect(connector.Paging(page(51, [51, 52, 53], 50))).toEqual({ HasMore: false, NextOffset: 54 });
            expect(connector.Paging(page(10, [1, 2], 2))).toEqual({ HasMore: false });
            expect(connector.Paging(page(4, [null, null], 2))).toEqual({ HasMore: true, NextOffset: 6 });
            expect(connector.Paging(page(0, [], 2))).toEqual({ HasMore: false });
        });
    });

    describe('incremental sync', () => {
        it('adds a GTE condition in database time and reports the max watermark seen', async () => {
            const ci = companyIntegration(baseConfig());
            const batch = await connector.FetchChanges(fetchContext(ci, 'Subscriber', { WatermarkValue: '2026-03-05T12:00:00.0000000Z' }));
            const doc = gridRequestOf(connector.Requests[0]);
            expect(doc).toContain('<Conditions><Condition><Single><DataElement>modified_date</DataElement>'
                + '<DataValue>2026-03-05T07:00:00</DataValue><Comparator>GTE</Comparator></Single></Condition></Conditions>');
            expect(indexesInOrder(doc, ['<Conditions>', '<ReturnFields>', '<SortField', '<StartRow>', '<NumberOfRows>'])).toBe(true);
            const seen = batch.Records.map(r => String(r.Fields.modified_date)).sort((a, b) => Date.parse(a) - Date.parse(b));
            expect(batch.NewWatermarkValue).toBe(seen[seen.length - 1]);
        });

        it('ignores the watermark for an object without incremental support', async () => {
            const batch = await connector.FetchChanges(fetchContext(companyIntegration(baseConfig()), 'AccountingCode', { WatermarkValue: '2026-03-05T12:00:00Z' }));
            expect(gridRequestOf(connector.Requests[0])).not.toContain('<Conditions>');
            expect(batch.NewWatermarkValue).toBeUndefined();
        });

        it('returns no watermark when a later page fails (the whole batch throws)', async () => {
            const replay = fixtureResponder();
            connector.Responder = (request, index) => index === 0 ? replay(request, index) : { Status: 500, Headers: { 'content-type': 'application/json' }, Text: '{"error":"boom"}' };
            await expect(connector.FetchChanges(fetchContext(companyIntegration(baseConfig()), 'Subscriber', { WatermarkValue: '2026-01-01T00:00:00Z' })))
                .rejects.toBeInstanceOf(InformzAPIError);
        });
    });

    describe('normalization', () => {
        it('maps an empty Field to NULL and never lets Record@row into the record', async () => {
            const batch = await connector.FetchChanges(fetchContext(companyIntegration(baseConfig()), 'Subscriber'));
            const first = batch.Records[0].Fields;
            expect(first.bounce_date).toBeNull();
            expect(first.cancel_id).toBe('2430631');
            for (const record of batch.Records) {
                expect(Object.keys(record.Fields).some(k => /^@?row$/i.test(k))).toBe(false);
            }
        });

        it('treats a self-closing Grid as zero rows, not an error', async () => {
            connector.Responder = () => gridEnvelope('subscriber', []);
            const batch = await connector.FetchChanges(fetchContext(companyIntegration(baseConfig()), 'Subscriber'));
            expect(batch.Records).toEqual([]);
            expect(batch.HasMore).toBe(false);
        });

        it('maps Declared names case-insensitively and passes undeclared elements through verbatim', async () => {
            const history = await connector.FetchChanges(fetchContext(companyIntegration(baseConfig()), 'SubscriberMailingHistory'));
            const fields = history.Records[0].Fields;
            expect(fields).toHaveProperty('Was_Clicked');
            expect(fields).not.toHaveProperty('was_clicked');
            // Every wire element (the fixture answers this grid in alias casing) lands on its Declared name.
            // The only other key is the base read loop's synthetic content-hash `ID`, stamped on keyless
            // objects (this grid's PK is deferred in the frozen contract) — engine behaviour, not a wire key.
            const declared = iofNames('SubscriberMailingHistory');
            expect(Object.keys(fields).filter(k => !declared.includes(k))).toEqual(['ID']);
            expect(fields.ID).toBe(history.Records[0].ExternalID);

            const subscribers = await connector.FetchChanges(fetchContext(companyIntegration(baseConfig()), 'Subscriber'));
            expect(subscribers.Records[0].Fields.fixture_member_level).toBe('Level 1');
        });
    });

    describe('errors', () => {
        it('classifies the WSDL InformzServiceFault as a non-retryable request defect', async () => {
            // The fixture's TestConnection-shaped probe route: event at StartRow 0 with NumberOfRows 1.
            const err = await captureError(connector.FetchChanges(fetchContext(companyIntegration(baseConfig()), 'Event', { BatchSize: 1 })));
            expect(err.Classification).toBe('RequestDefect');
            expect(err.FaultCode).toBe('InvalidGridCategoryException');
            expect(err.Status).toBe(500);
            expect(IsRetryableError(ClassifyError(err).Code)).toBe(false);
        });

        it('reads the help-center InformzAAPIFault shape namespace-agnostically', async () => {
            connector.Responder = () => faultEnvelope('InformzAAPIFault', 'InvalidCredentialsException', 'Bad credentials');
            const err = await captureError(connector.FetchChanges(fetchContext(companyIntegration(baseConfig()), 'Subscriber')));
            expect(err.Classification).toBe('AuthOrPrecondition');
            expect(err.FaultCode).toBe('InvalidCredentialsException');
            expect(ClassifyError(err).Code).toBe('CONFIGURATION_ERROR');
            expect(err.message).not.toContain(String(FIXTURES.Configuration.Password));
        });

        it('names the brand-IP registration precondition for NoAvailableIPAddressException', async () => {
            connector.Responder = () => faultEnvelope('InformzServiceFault', 'NoAvailableIPAddressException', 'No available IP address');
            const err = await captureError(connector.FetchChanges(fetchContext(companyIntegration(baseConfig()), 'Subscriber')));
            expect(err.Classification).toBe('AuthOrPrecondition');
            expect(err.message.startsWith(`${connector.IntegrationName} AAPI`)).toBe(true);
            expect(err.message).toMatch(/IP address registered with the brand/);
            expect(err.message).toMatch(/precondition/);
            expect(IsRetryableError(ClassifyError(err).Code)).toBe(false);
        });

        it('explains a generic fault without AAPI detail (the observed refusal shape)', async () => {
            connector.Responder = () => ({
                Status: 500,
                Headers: { 'content-type': 'text/xml; charset=utf-8' },
                Text: '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Body><s:Fault><faultcode xmlns:a="urn:x">a:InternalServiceFault</faultcode><faultstring>The server was unable to process the request due to an internal error.</faultstring></s:Fault></s:Body></s:Envelope>',
            });
            const err = await captureError(connector.FetchChanges(fetchContext(companyIntegration(baseConfig()), 'Subscriber')));
            expect(err.Classification).toBe('Fault');
            expect(err.FaultCode).toBe('InternalServiceFault');
            expect(err.message).toMatch(/brand-IP registration/);
        });

        it('throws on a JSON HTTP 500 instead of returning an empty page', async () => {
            connector.Responder = () => ({ Status: 500, Headers: { 'content-type': 'application/json' }, Text: '{"error":"mock 500"}' });
            const err = await captureError(connector.FetchChanges(fetchContext(companyIntegration(baseConfig()), 'Subscriber')));
            expect(err.Classification).toBe('HTTP');
            expect(err.Status).toBe(500);
        });

        it('throws on a 2xx body that is not a SOAP GridResponse', async () => {
            connector.Responder = () => ({ Status: 200, Headers: { 'content-type': 'application/json' }, Text: '[]' });
            const err = await captureError(connector.FetchChanges(fetchContext(companyIntegration(baseConfig()), 'Subscriber')));
            expect(err.Classification).toBe('Protocol');
        });

        it('waits out a 503 Retry-After and retries the same request', async () => {
            const replay = fixtureResponder();
            connector.Responder = (request, index) => index === 0
                ? { Status: 503, Headers: { 'retry-after': '1' }, Text: '' }
                : replay(request, index);
            const batch = await connector.FetchChanges(fetchContext(companyIntegration(baseConfig()), 'EmailBlockStatus'));
            expect(connector.Sleeps).toEqual([1000]);
            expect(connector.Requests[0].Body).toBe(connector.Requests[1].Body);
            expect(batch.Records.length).toBeGreaterThan(0);
        });

        it('surfaces a persistent 503 as a retryable rate-limit error carrying Retry-After', async () => {
            connector.Responder = () => ({ Status: 503, Headers: { 'retry-after': '1' }, Text: '' });
            const err = await captureError(connector.FetchChanges(fetchContext(companyIntegration(baseConfig()), 'EmailBlockStatus')));
            expect(err.Classification).toBe('Throttled');
            expect(ClassifyError(err).Code).toBe('RATE_LIMIT_EXCEEDED');
            expect(connector.ExtractRetryAfterMs(err)).toBe(1000);
            expect(connector.Requests).toHaveLength(4);
        });

        it('hands a long Retry-After to the engine instead of sleeping inline', async () => {
            connector.Responder = () => ({ Status: 429, Headers: { 'retry-after': '120' }, Text: '' });
            const err = await captureError(connector.FetchChanges(fetchContext(companyIntegration(baseConfig()), 'EmailBlockStatus')));
            expect(connector.Sleeps).toEqual([]);
            expect(connector.ExtractRetryAfterMs(err)).toBe(120_000);
        });
    });

    describe('endpoint + credentials', () => {
        it('uses the documented region template when no ServiceURL is configured', async () => {
            const template = String(INTEGRATION_CONFIG.BaseURLTemplate);
            const defaultRegion = String(INTEGRATION_CONFIG.DefaultRegion);
            const noURL = { ...FIXTURES.Configuration };
            await connector.FetchChanges(fetchContext(companyIntegration({ ...noURL, Region: 'ca' }), 'AccountingCode'));
            await connector.FetchChanges(fetchContext(companyIntegration({ ...noURL, Region: undefined }), 'AccountingCode'));
            expect(connector.Requests[0].URL).toBe(template.replace('{RegionHost}', REGION_HOSTS.ca));
            expect(connector.Requests[1].URL).toBe(template.replace('{RegionHost}', REGION_HOSTS[defaultRegion]));
        });

        it('rejects an undocumented region and missing credentials as configuration errors', async () => {
            const badRegion = await connector.TestConnection(companyIntegration({ ...FIXTURES.Configuration, Region: 'mars' }), USER);
            expect(badRegion.Success).toBe(false);
            expect(badRegion.Message).toMatch(/not one of the documented AAPI regions/);

            const noPassword = baseConfig();
            delete noPassword.Password;
            const err = await captureError(connector.FetchChanges(fetchContext(companyIntegration(noPassword), 'Subscriber')));
            expect(err.Classification).toBe('Configuration');
            expect(err.message).toMatch(/Password/);
            expect(connector.Requests).toHaveLength(0);
        });
    });

    describe('TestConnection + GetRecord', () => {
        it('probes the first Active grid by Sequence with NumberOfRows=1', async () => {
            const first = ioRows().filter(r => (r.fields.Status ?? 'Active') === 'Active')
                .sort((a, b) => Number(a.fields.Sequence) - Number(b.fields.Sequence))[0];
            const gridType = String(asRecord(parseMaybeJSON(first.fields.Configuration)).gridType);
            const result = await connector.TestConnection(companyIntegration(baseConfig()), USER);
            expect(result.Success).toBe(true);
            const doc = gridRequestOf(connector.Requests[0]);
            expect(doc).toContain(`<Grid type="${gridType}">`);
            expect(doc).toContain('<NumberOfRows>1</NumberOfRows>');
        });

        it('surfaces the classified fault without echoing the password', async () => {
            connector.Responder = () => faultEnvelope('InformzServiceFault', 'NoAvailableIPAddressException', 'refused');
            const result = await connector.TestConnection(companyIntegration(baseConfig()), USER);
            expect(result.Success).toBe(false);
            expect(result.Message).toMatch(/precondition/);
            expect(result.Message).not.toContain(String(FIXTURES.Configuration.Password));
        });

        it('re-reads one record through an EQ condition on the single Declared key', async () => {
            connector.Responder = () => gridEnvelope('subscriber', [{ Row: 1, Fields: [['subscriber_id', '140001'], ['email', 'a@example.invalid']] }]);
            const record = await connector.GetRecord({ CompanyIntegration: companyIntegration(baseConfig()), ObjectName: 'Subscriber', ContextUser: USER, ExternalID: '140001' });
            expect(record?.Fields.email).toBe('a@example.invalid');
            expect(gridRequestOf(connector.Requests[0])).toContain(
                '<Condition><Single><DataElement>subscriber_id</DataElement><DataValue>140001</DataValue><Comparator>EQ</Comparator></Single></Condition>');
            await expect(connector.GetRecord({ CompanyIntegration: companyIntegration(baseConfig()), ObjectName: firstKeylessIOName(), ContextUser: USER, ExternalID: '1' }))
                .rejects.toThrow(/primary key/);
        });
    });

    describe('schema sample-union', () => {
        it('adds the connection ExtraReturnFields element to the Declared field floor', async () => {
            const info = await connector.IntrospectSchema(companyIntegration(baseConfig()), USER, { ObjectNames: ['Subscriber'] });
            const names = info.Objects[0].Fields.map(f => f.Name);
            expect(names).toEqual(expect.arrayContaining([...iofNames('Subscriber'), 'fixture_member_level']));
        });
    });

    describe('source hygiene', () => {
        const source = readFileSync(CONNECTOR_SOURCE, 'utf8');

        it('carries no vendor host, tenant value or baked catalog', () => {
            const forbidden = [
                ...Object.values(REGION_HOSTS),
                new URL(TRANSPORT.wsdlServiceAddress).host,
                TRANSPORT.namespace,
                TRANSPORT.soapAction,
                String(FIXTURES.Configuration.Username),
                String(FIXTURES.Configuration.Password),
            ];
            for (const literal of forbidden) expect(source).not.toContain(literal);
            for (const io of ioRows()) {
                const gridType = String(asRecord(parseMaybeJSON(io.fields.Configuration)).gridType);
                expect(source).not.toContain(`'${gridType}'`);
                expect(source).not.toContain(`"${gridType}"`);
            }
            expect(source).not.toMatch(/^(?:export\s+)?const\s+\w+\s*(?::[^=]+)?=\s*[[{]/m);
        });

        it('contains no URL literal except the SOAP 1.1 envelope namespace', () => {
            const urls = [...source.matchAll(/https?:\/\/[^\s'"`)]+/g)].map(m => m[0]);
            expect(new Set(urls)).toEqual(new Set(['http://schemas.xmlsoap.org/soap/envelope/']));
        });
    });
});
