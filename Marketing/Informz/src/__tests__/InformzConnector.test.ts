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
import {
    InformzAPIError,
    InformzConnector,
    parseInformzWindowCursor,
    formatInformzWindowCursor,
    initialInformzDateWindow,
    nextInformzDateWindow,
    type InformzGridPage,
    type InformzWireResponse,
} from '../InformzConnector.js';

// ─── Real metadata + fixtures ─────────────────────────────────────────────────────────────────────

const HERE = dirname(fileURLToPath(import.meta.url));
// The catalog this package ships, and the doc-derived wire fixtures + vendor action catalog vendored beside this test.
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
/** The fixture's error-route objects (the builder picks non-priority grids; they move when the catalog changes). */
const FAULT_OBJECT = String((FIXTURES as unknown as { ErrorRoutes: { ServiceFault: { Object: string } } }).ErrorRoutes.ServiceFault.Object);
const RETRY_OBJECT = String((FIXTURES as unknown as { ErrorRoutes: { RetryAfter: { Object: string } } }).ErrorRoutes.RetryAfter.Object);
/** The subscriber_id values the fixture's subscriber page routes serve, in StartRow order (the builder mints them). */
function fixtureSubscriberIds(): string[] {
    const pages = FIXTURES.Routes
        .filter(r => (r.Match ?? []).includes('type=&quot;subscriber&quot;') && (r.Match ?? []).some(m => /^&lt;StartRow&gt;\d+&lt;\/StartRow&gt;$/.test(m)))
        .map(r => ({ start: Number(/&lt;StartRow&gt;(\d+)/.exec((r.Match ?? []).join(' '))?.[1]), body: r.Body }))
        .sort((a, b) => a.start - b.start);
    const ids: string[] = [];
    for (const page of pages) {
        const doc = unescapeXml(unescapeXml(page.body));
        for (const m of doc.matchAll(/<Field element="subscriber_id">(\d+)<\/Field>/g)) if (!ids.includes(m[1])) ids.push(m[1]);
    }
    return ids;
}
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

/** The IO's Declared primary-key fields, in the Sequence order the base read loop joins them in. */
function keyNames(ioName: string): string[] {
    return iofNames(ioName).filter(name =>
        (ioRow(ioName).relatedEntities?.['MJ: Integration Object Fields'] ?? []).some(f => f.fields.Name === name && f.fields.IsPrimaryKey === true));
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

function seedEngine(root: MetadataRow = METADATA_ROOT): void {
    const ios: Array<Partial<MJIntegrationObjectEntity>> = [];
    const iofs: Array<Partial<MJIntegrationObjectFieldEntity>> = [];
    (root.relatedEntities?.['MJ: Integration Objects'] ?? []).forEach((io, i) => {
        const ioID = `seed-io-${i + 1}`;
        ios.push(seedRow<MJIntegrationObjectEntity>(io.fields, { ID: ioID, IntegrationID: INTEGRATION_ID }));
        (io.relatedEntities?.['MJ: Integration Object Fields'] ?? []).forEach((f, j) => {
            iofs.push(seedRow<MJIntegrationObjectFieldEntity>(f.fields, { ID: `seed-iof-${i + 1}-${j + 1}`, IntegrationObjectID: ioID }));
        });
    });
    IntegrationEngineBase.Instance.SeedForTesting({
        Integrations: [seedRow<MJIntegrationEntity>(root.fields, { ID: INTEGRATION_ID })],
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

// ─── Write-path helpers (mocked transport only — nothing is ever sent anywhere) ─────────────────

interface ActionsCatalog {
    paths: Record<string, { post?: { 'x-informz-wire'?: { interestActions?: string[] } } }>;
}

interface FaultClassification {
    authOrPrecondition?: string[];
    requestDefect?: string[];
}

const ACTIONS_CATALOG_FILE = resolve(HERE, 'fixtures/informz/informz.actions.openapi.json');
const ACTIONS_CATALOG = JSON.parse(readFileSync(ACTIONS_CATALOG_FILE, 'utf8')) as ActionsCatalog;
const ADD_OR_UPDATE = 'AddOrUpdateSubscribers';
/**
 * The documented list-replacing interest action, read from the derived vendor catalog at run time so
 * its literal never appears anywhere under src (the grep gate allows it only on the connector's refusal line).
 */
const LIST_REPLACING_ACTION = (ACTIONS_CATALOG.paths['/actions/Subscribe']?.post?.['x-informz-wire']?.interestActions ?? [])
    .find(a => a !== ADD_OR_UPDATE) ?? '';
const WRITE_CONTRACT = asRecord(INTEGRATION_CONFIG.WriteContract);
const WRITE_FAULT_CLASSES = asRecord(WRITE_CONTRACT.faults).classification as FaultClassification;
const ERROR_CONTRACT_CODES = asRecord(INTEGRATION_CONFIG.ErrorContract).codes as string[];
const DELETE_REASONS = asRecord(asRecord(INTEGRATION_CONFIG.WriteScope).deleteDecision).reasons as string[];

type SubscriberRow = [subscriberID: string, email: string, userID: string | null];

const ROW: SubscriberRow = ['950001', 'new.member@example.invalid', '321'];
const OTHER_ROW: SubscriberRow = ['950009', 'new.member@example.invalid', '321'];
const ATTRS: Record<string, unknown> = { email: ROW[1], user_id: 321 };

/** Message namespace = the AAPI contract namespace (WCF default Action = <ns><Contract>/<Op>). */
function messageNamespace(): string {
    const contract = TRANSPORT.soapAction.slice(0, TRANSPORT.soapAction.lastIndexOf('/'));
    return contract.slice(0, contract.lastIndexOf('/') + 1);
}

/** The real metadata with the Subscriber writeActions edited (deep copy; the frozen file is untouched). */
function metadataWithWriteActions(edit: (writeActions: Record<string, Record<string, unknown>>) => void): MetadataRow {
    const root = JSON.parse(JSON.stringify(METADATA_ROOT)) as MetadataRow;
    const io = (root.relatedEntities?.['MJ: Integration Objects'] ?? []).find(r => r.fields.Name === 'Subscriber');
    if (!io) throw new Error('metadata has no Subscriber IO');
    const cfg = asRecord(parseMaybeJSON(io.fields.Configuration));
    edit(cfg.writeActions as Record<string, Record<string, unknown>>);
    io.fields.Configuration = cfg;
    return root;
}

/** An IO that declares no writeActions — read from the metadata, never a baked name. */
function firstReadOnlyIOName(): string {
    const row = ioRows().find(r => asRecord(parseMaybeJSON(r.fields.Configuration)).writeActions === undefined);
    if (!row) throw new Error('metadata has no IO without writeActions');
    return String(row.fields.Name);
}

function subscriberRows(rows: SubscriberRow[]): InformzWireResponse {
    return gridEnvelope('subscriber', rows.map(([id, email, userID], i) => ({
        Row: i + 1,
        Fields: [['subscriber_id', id], ['email', email], ['user_id', userID]] as Array<[string, string | null]>,
    })));
}

/** The documented ActionResponse shape (360032692392), escaped inside PostInformzMessageResult. */
function actionEnvelope(options: { Status?: string; Invalid?: number; InvalidXml?: string } = {}): InformzWireResponse {
    const invalid = options.Invalid ?? 0;
    const message = `1 total records:\n${invalid > 0 ? 0 : 1} added.\n0 previous subscribers.\n0 previous unsubscribers.\n0 duplicate subscribers.\n${invalid} invalid addresses.`;
    const doc = '<?xml version="1.0" encoding="utf-8"?><ActionResponse xmlns:xsi="urn:xsi" xmlns="urn:aapi"><Brand id="1" /><User>u</User><Responses><Subscribe>'
        + `<SubscriberCounts>0</SubscriberCounts><ActionStatus><Status>${options.Status ?? 'success'}</Status>`
        + `<Message xsi:type="xsd:string">${escapeXml(message)}</Message></ActionStatus>${options.InvalidXml ?? '<InvalidSubscribers />'}`
        + '</Subscribe></Responses></ActionResponse>';
    return {
        Status: 200,
        Headers: { 'content-type': 'text/xml; charset=utf-8' },
        Text: `<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Body><PostInformzMessageResponse><PostInformzMessageResult>${escapeXml(doc)}</PostInformzMessageResult></PostInformzMessageResponse></s:Body></s:Envelope>`,
    };
}

function isActionRequest(request: CapturedRequest): boolean {
    return gridRequestOf(request).startsWith('<ActionRequest');
}

function conditionsOf(request: CapturedRequest): string {
    return /<Conditions>([\s\S]*?)<\/Conditions>/.exec(gridRequestOf(request))?.[1] ?? '';
}

function eq(element: string, value: string): string {
    return `<Condition><Single><DataElement>${element}</DataElement><DataValue>${value}</DataValue><Comparator>EQ</Comparator></Single></Condition>`;
}

type OptionalUserIdSubscriberRow = [id: string, email: string, userID: string | null];

interface WriteScript {
    /** Rows the identity read-back store holds BEFORE any Subscribe was posted (filtered by EQ condition). */
    Before?: OptionalUserIdSubscriberRow[];
    /** Rows it finds after a Subscribe. */
    After?: SubscriberRow[];
    /** The row GetRecord (subscriber_id EQ) finds. */
    Stored?: SubscriberRow | null;
    /** Optional wire response override for read-back GridRequests (e.g. testing read-back fault classification). */
    Readback?: (request: CapturedRequest, index: number) => InformzWireResponse | null;
    Action?: (request: CapturedRequest, index: number) => InformzWireResponse;
}

function matchesGridConditions(row: OptionalUserIdSubscriberRow, condXml: string): boolean {
    for (const m of condXml.matchAll(/<Single><DataElement>([^<]+)<\/DataElement><DataValue>([\s\S]*?)<\/DataValue><Comparator>EQ<\/Comparator><\/Single>/g)) {
        const element = m[1];
        const expected = unescapeXml(m[2]).trim().toLowerCase();
        const actual = element === 'subscriber_id' ? row[0] : element === 'email' ? row[1] : element === 'user_id' ? (row[2] ?? '') : '';
        if (actual.trim().toLowerCase() !== expected) return false;
    }
    return true;
}

/** A stateful mock vendor: pre-write read-backs filter `Before` by EQ condition, post-write sees `After`, GetRecord sees `Stored`. */
function writeResponder(script: WriteScript): Responder {
    let posted = false;
    return (request, index) => {
        if (isActionRequest(request)) {
            posted = true;
            return script.Action ? script.Action(request, index) : actionEnvelope();
        }
        const conds = conditionsOf(request);
        if (conds.includes('<DataElement>subscriber_id</DataElement>')) return subscriberRows(script.Stored ? [script.Stored] : []);
        const overridden = script.Readback?.(request, index) ?? null;
        if (overridden) return overridden;
        if (!posted) {
            const matched = (script.Before ?? []).filter(r => matchesGridConditions(r, conds));
            return gridEnvelope('subscriber', matched.map(([id, email, userID], i) => ({
                Row: i + 1,
                Fields: [['subscriber_id', id], ['email', email], ['user_id', userID]] as Array<[string, string | null]>,
            })));
        }
        return subscriberRows(script.After ?? []);
    };
}

function createCtx(ci: MJCompanyIntegrationEntity, attributes: Record<string, unknown>, objectName = 'Subscriber') {
    return { CompanyIntegration: ci, ObjectName: objectName, ContextUser: USER, Attributes: attributes };
}

function updateCtx(ci: MJCompanyIntegrationEntity, externalID: string, attributes: Record<string, unknown>, objectName = 'Subscriber') {
    return { CompanyIntegration: ci, ObjectName: objectName, ContextUser: USER, ExternalID: externalID, Attributes: attributes };
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
            expect(batch.Records.map(r => r.ExternalID)).toEqual(fixtureSubscriberIds());
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
            expect(second.Records.map(r => r.ExternalID)).toEqual(fixtureSubscriberIds().slice(2, 4));
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
            // Every wire element (the fixture answers this grid in alias casing) lands on its Declared name,
            // and nothing else is added: the grid declares a composite key, so the base read loop joins its
            // parts (in Sequence order) into the ExternalID instead of stamping a synthetic content-hash `ID`.
            const declared = iofNames('SubscriberMailingHistory');
            expect(Object.keys(fields).filter(k => !declared.includes(k))).toEqual([]);
            const keys = keyNames('SubscriberMailingHistory');
            expect(keys).toEqual(['Mailing_instance_id', 'Subscriber_ID']);
            expect(history.Records[0].ExternalID).toBe(keys.map(k => String(fields[k])).join('|'));

            const subscribers = await connector.FetchChanges(fetchContext(companyIntegration(baseConfig()), 'Subscriber'));
            expect(subscribers.Records[0].Fields.fixture_member_level).toBe('Level 1');
        });
    });

    describe('errors', () => {
        it('classifies the WSDL InformzServiceFault as a non-retryable request defect', async () => {
            // The fixture's TestConnection-shaped probe route: the ServiceFault grid at StartRow 0 with NumberOfRows 1.
            const err = await captureError(connector.FetchChanges(fetchContext(companyIntegration(baseConfig()), FAULT_OBJECT, { BatchSize: 1 })));
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
            const batch = await connector.FetchChanges(fetchContext(companyIntegration(baseConfig()), RETRY_OBJECT));
            expect(connector.Sleeps).toEqual([1000]);
            expect(connector.Requests[0].Body).toBe(connector.Requests[1].Body);
            expect(batch.Records.length).toBeGreaterThan(0);
        });

        it('surfaces a persistent 503 as a retryable rate-limit error carrying Retry-After', async () => {
            connector.Responder = () => ({ Status: 503, Headers: { 'retry-after': '1' }, Text: '' });
            const err = await captureError(connector.FetchChanges(fetchContext(companyIntegration(baseConfig()), RETRY_OBJECT)));
            expect(err.Classification).toBe('Throttled');
            expect(ClassifyError(err).Code).toBe('RATE_LIMIT_EXCEEDED');
            expect(connector.ExtractRetryAfterMs(err)).toBe(1000);
            expect(connector.Requests).toHaveLength(4);
        });

        it('hands a long Retry-After to the engine instead of sleeping inline', async () => {
            connector.Responder = () => ({ Status: 429, Headers: { 'retry-after': '120' }, Text: '' });
            const err = await captureError(connector.FetchChanges(fetchContext(companyIntegration(baseConfig()), RETRY_OBJECT)));
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

    describe('write path (Subscribe ActionRequest, mocked)', () => {
        it('declares create and update while delete and upsert stay off', () => {
            expect([connector.SupportsCreate, connector.SupportsUpdate, connector.SupportsDelete, connector.SupportsUpsert]).toEqual([true, true, false, false]);
            expect(connector.DiscoveryIsAuthoritative).toBe(false);
            expect(DELETE_REASONS.length).toBeGreaterThan(0);
        });

        it('creates through one escaped Subscribe ActionRequest in the GridRequest envelope, Email then ID', async () => {
            connector.Responder = writeResponder({ Before: [], After: [['950001', "o'brien&co@example.invalid", '321']] });
            const result = await connector.CreateRecord(createCtx(companyIntegration(baseConfig()), { email: "O'Brien&Co@example.invalid", user_id: 321 }));
            expect(result).toEqual({ Success: true, StatusCode: 200, ExternalID: '950001' });
            expect(connector.Requests.map(isActionRequest)).toEqual([false, false, true, false]);
            const action = connector.Requests[2];
            expect(action.URL).toBe(`${SERVICE_URL}/`);
            expect(action.URL).toBe(connector.Requests[0].URL);
            expect(action.Headers.SOAPAction).toBe(`"${TRANSPORT.soapAction}"`);
            expect(action.Headers['Content-Type']).toBe('text/xml; charset=utf-8');
            expect(action.Body).toContain(`<PostInformzMessage xmlns="${messageNamespace()}">`);
            const doc = gridRequestOf(action);
            expect(doc.startsWith(`<ActionRequest xmlns="${messageNamespace()}">`)).toBe(true);
            expect(indexesInOrder(doc, [
                '<Password>', '<Brand id="1">', '<User>fixture-user</User>', '<Actions><Subscribe>', '<InterestDetails>',
                `<InterestAction>${ADD_OR_UPDATE}</InterestAction>`, '</InterestDetails>', '<SubscriberData>', '<Subscribers><Subscriber>',
                '<Email>', '<ID>321</ID>', '</Subscriber></Subscribers></SubscriberData></Subscribe></Actions></ActionRequest>',
            ])).toBe(true);
            expect(doc).toContain('<Email>O&apos;Brien&amp;Co@example.invalid</Email><ID>321</ID>');
            expect(action.Body).toContain('&lt;Email&gt;O&amp;apos;Brien&amp;amp;Co@example.invalid&lt;/Email&gt;');
            expect(action.Body).not.toContain("O'Brien&Co");
        });

        it('only ever sends the AddOrUpdateSubscribers interest action, for create and update', async () => {
            connector.Responder = writeResponder({ Before: [], After: [ROW], Stored: ROW });
            const ci = companyIntegration(baseConfig());
            expect((await connector.CreateRecord(createCtx(ci, ATTRS))).Success).toBe(true);
            expect((await connector.UpdateRecord(updateCtx(ci, ROW[0], ATTRS))).Success).toBe(true);
            const docs = connector.Requests.filter(isActionRequest).map(gridRequestOf);
            expect(docs).toHaveLength(2);
            for (const doc of docs) {
                expect([...doc.matchAll(/<InterestAction>([^<]*)<\/InterestAction>/g)].map(m => m[1])).toEqual([ADD_OR_UPDATE]);
            }
        });

        it('refuses a list-replacing interest action from metadata or connection settings with zero requests', async () => {
            expect(LIST_REPLACING_ACTION.length).toBeGreaterThan(0);
            connector.Responder = writeResponder({ Before: [], After: [ROW], Stored: ROW });
            seedEngine(metadataWithWriteActions(wa => {
                wa.create.interestAction = LIST_REPLACING_ACTION;
                wa.update.interestAction = LIST_REPLACING_ACTION;
            }));
            const plain = companyIntegration(baseConfig());
            const results = [await connector.CreateRecord(createCtx(plain, ATTRS)), await connector.UpdateRecord(updateCtx(plain, ROW[0], ATTRS))];
            seedEngine();
            for (const key of ['SubscribeInterestAction', 'InterestAction']) {
                const ci = companyIntegration(baseConfig({ [key]: LIST_REPLACING_ACTION }));
                results.push(await connector.CreateRecord(createCtx(ci, ATTRS)), await connector.UpdateRecord(updateCtx(ci, ROW[0], ATTRS)));
            }
            expect(results).toHaveLength(6);
            for (const result of results) {
                expect(result.Success).toBe(false);
                expect(result.StatusCode).toBe(400);
                expect(result.ErrorMessage).toMatch(/configuration error/);
                expect(result.ErrorMessage).toContain(ADD_OR_UPDATE);
            }
            expect(connector.Requests).toHaveLength(0);
        });

        it('never puts the list-replacing interest action into any request body', async () => {
            const ci = companyIntegration(baseConfig({ SubscribeInterestNames: ['Members'], SubscribeFieldDefinitions: [{ Name: 'First_Name' }] }));
            connector.Responder = writeResponder({ Before: [], After: [ROW], Stored: ROW });
            await connector.CreateRecord(createCtx(ci, { ...ATTRS, First_Name: 'Ada' }));
            await connector.UpdateRecord(updateCtx(ci, ROW[0], { First_Name: 'Ada' }));
            await connector.DeleteRecord({ CompanyIntegration: ci, ObjectName: 'Subscriber', ContextUser: USER, ExternalID: ROW[0] });
            connector.Responder = writeResponder({ Before: [], After: [], Action: () => actionEnvelope({ Invalid: 1 }) });
            await connector.CreateRecord(createCtx(ci, ATTRS));
            expect(connector.Requests.filter(isActionRequest).length).toBeGreaterThanOrEqual(3);
            for (const request of connector.Requests) {
                expect(request.Body).not.toContain(LIST_REPLACING_ACTION);
                expect(unescapeXml(unescapeXml(request.Body))).not.toContain(LIST_REPLACING_ACTION);
            }
        });

        it('links an existing subscriber found by the pre-write read-back without posting when only identity is sent', async () => {
            connector.Responder = writeResponder({ Before: [['950002', 'mixed.case@example.invalid', '322']] });
            const result = await connector.CreateRecord(createCtx(companyIntegration(baseConfig()), { email: 'Mixed.Case@Example.invalid', user_id: '322' }));
            expect(result).toEqual({ Success: true, StatusCode: 200, ExternalID: '950002' });
            expect(connector.Requests).toHaveLength(2);
            const doc = gridRequestOf(connector.Requests[0]);
            expect(doc).toContain('<Grid type="subscriber">');
            expect(doc).toContain('<NumberOfRows>2</NumberOfRows>');
            // Each identity condition is queried on its own before posting so partial-key collisions are caught.
            expect(conditionsOf(connector.Requests[0])).toBe(eq('user_id', '322'));
            expect(conditionsOf(connector.Requests[1])).toBe(eq('email', 'mixed.case@example.invalid'));
        });

        it('posts Subscribe on create when an existing subscriber matches both keys AND the draft carries interests or demographic Fields', async () => {
            const existing: SubscriberRow = ['950002', 'mixed.case@example.invalid', '322'];
            const withInterests = companyIntegration(baseConfig({ SubscribeInterestNames: ['Members'] }));
            connector.Responder = writeResponder({ Before: [existing], After: [existing] });
            const r1 = await connector.CreateRecord(createCtx(withInterests, { email: existing[1], user_id: existing[2] }));
            expect(r1).toEqual({ Success: true, StatusCode: 200, ExternalID: '950002' });
            expect(connector.Requests.map(isActionRequest)).toEqual([false, false, true, false]);
            expect(gridRequestOf(connector.Requests[2])).toContain('<InterestName>Members</InterestName>');

            connector.Requests = [];
            const withField = companyIntegration(baseConfig({ SubscribeFieldDefinitions: [{ Name: 'First_Name' }] }));
            connector.Responder = writeResponder({ Before: [existing], After: [existing] });
            const r2 = await connector.CreateRecord(createCtx(withField, { email: existing[1], user_id: existing[2], First_Name: 'Ada' }));
            expect(r2).toEqual({ Success: true, StatusCode: 200, ExternalID: '950002' });
            expect(connector.Requests.map(isActionRequest)).toEqual([false, false, true, false]);
            expect(gridRequestOf(connector.Requests[2])).toContain('<Field element="First_Name">Ada</Field>');

            // Post-write confirmation must still find the same subscriber_id
            connector.Requests = [];
            connector.Responder = writeResponder({ Before: [existing], After: [['959999', existing[1], existing[2]]] });
            const mismatch = await connector.CreateRecord(createCtx(withField, { email: existing[1], user_id: existing[2], First_Name: 'Ada' }));
            expect(mismatch.Success).toBe(false);
            expect(mismatch.StatusCode).toBe(409);
        });

        it('refuses create with 409 before posting when either email or user_id already belongs to another identity, while allowing a blank stored user_id to be filled in', async () => {
            const ci = companyIntegration(baseConfig());

            // Direction 1: Informz already holds email under a different non-blank user_id ('999' vs incoming '321')
            connector.Responder = writeResponder({ Before: [['950077', ROW[1], '999']] });
            const emailTaken = await connector.CreateRecord(createCtx(ci, ATTRS));
            expect(emailTaken.Success).toBe(false);
            expect(emailTaken.StatusCode).toBe(409);
            expect(emailTaken.ErrorMessage).toMatch(/identity change is never pushed/);
            expect(emailTaken.ErrorMessage).not.toContain('999');
            expect(connector.Requests.filter(isActionRequest)).toHaveLength(0);

            // Direction 2: Informz already holds user_id under a different email
            connector.Requests = [];
            connector.Responder = writeResponder({ Before: [['950078', 'other.person@example.invalid', '321']] });
            const idTaken = await connector.CreateRecord(createCtx(ci, ATTRS));
            expect(idTaken.Success).toBe(false);
            expect(idTaken.StatusCode).toBe(409);
            expect(idTaken.ErrorMessage).toMatch(/identity change is never pushed/);
            expect(idTaken.ErrorMessage).not.toContain('other.person@example.invalid');
            expect(connector.Requests.filter(isActionRequest)).toHaveLength(0);

            // Direction 3: Separate keys match two distinct rows (e.g. one holds user_id with blank email, another holds email with blank user_id) -> 409, nothing sent
            connector.Requests = [];
            connector.Responder = writeResponder({ Before: [['950079', '', '321'], ['950080', ROW[1], null]] });
            const splitRows = await connector.CreateRecord(createCtx(ci, ATTRS));
            expect(splitRows.Success).toBe(false);
            expect(splitRows.StatusCode).toBe(409);
            expect(splitRows.ErrorMessage).toMatch(/distinct rows/);
            expect(connector.Requests.filter(isActionRequest)).toHaveLength(0);

            // Blank stored user_id: Informz has email with no user_id yet -> allowed, posts Subscribe to populate ID and confirms 950088
            connector.Requests = [];
            connector.Responder = writeResponder({ Before: [['950088', ROW[1], null]], After: [['950088', ROW[1], '321']] });
            const filledIn = await connector.CreateRecord(createCtx(ci, ATTRS));
            expect(filledIn).toEqual({ Success: true, StatusCode: 200, ExternalID: '950088' });
            expect(connector.Requests.map(isActionRequest)).toEqual([false, false, true, false]);
        });

        it('reads the identity back after Subscribe: one row links, zero or several fail with 409 and no ExternalID', async () => {
            const ci = companyIntegration(baseConfig());
            const cases: Array<{ After: SubscriberRow[]; Expect: RegExp | null }> = [
                { After: [ROW], Expect: null },
                { After: [], Expect: /found no row/ },
                { After: [ROW, OTHER_ROW], Expect: /ambiguous/ },
            ];
            for (const c of cases) {
                connector.Requests = [];
                connector.Responder = writeResponder({ Before: [], After: c.After });
                const result = await connector.CreateRecord(createCtx(ci, ATTRS));
                expect(connector.Requests.map(isActionRequest)).toEqual([false, false, true, false]);
                expect(conditionsOf(connector.Requests[3])).toBe(eq('user_id', '321') + eq('email', ROW[1]));
                if (c.Expect === null) {
                    expect(result).toEqual({ Success: true, StatusCode: 200, ExternalID: ROW[0] });
                    continue;
                }
                expect(result.Success).toBe(false);
                expect(result.StatusCode).toBe(409);
                expect(result.ExternalID).toBeUndefined();
                expect(result.ErrorMessage).toMatch(c.Expect);
            }
        });

        it('refuses an ambiguous pre-write read-back with 409 and posts nothing', async () => {
            connector.Responder = writeResponder({ Before: [ROW, OTHER_ROW] });
            const result = await connector.CreateRecord(createCtx(companyIntegration(baseConfig()), ATTRS));
            expect(result.Success).toBe(false);
            expect(result.StatusCode).toBe(409);
            expect(result.ExternalID).toBeUndefined();
            expect(result.ErrorMessage).toMatch(/nothing was sent/);
            expect(connector.Requests.filter(isActionRequest)).toHaveLength(0);
        });

        it('updates through GetRecord when the attributes carry neither Email nor ID', async () => {
            const stored: SubscriberRow = ['950003', 'stored@example.invalid', '323'];
            const ci = companyIntegration(baseConfig({ SubscribeFieldDefinitions: [{ Name: 'First_Name' }] }));
            connector.Responder = writeResponder({ Stored: stored, After: [stored] });
            const result = await connector.UpdateRecord(updateCtx(ci, stored[0], { First_Name: 'Ada' }));
            expect(result).toEqual({ Success: true, StatusCode: 200, ExternalID: stored[0] });
            expect(connector.Requests.map(isActionRequest)).toEqual([false, true, false]);
            expect(conditionsOf(connector.Requests[0])).toBe(eq('subscriber_id', stored[0]));
            const doc = gridRequestOf(connector.Requests[1]);
            expect(doc).toContain('<FieldDefinitions><FieldDefinition><Name>First_Name</Name><DataType>String</DataType></FieldDefinition></FieldDefinitions>');
            expect(doc).toContain('<Subscriber><Email>stored@example.invalid</Email><ID>323</ID><Fields><Field element="First_Name">Ada</Field></Fields></Subscriber>');
            expect(conditionsOf(connector.Requests[2])).toBe(eq('user_id', '323') + eq('email', 'stored@example.invalid'));
        });

        it('refuses an update that would change the stored email, and a missing row, before posting', async () => {
            const stored: SubscriberRow = ['950003', 'stored@example.invalid', '323'];
            const ci = companyIntegration(baseConfig());
            connector.Responder = writeResponder({ Stored: stored, After: [stored] });
            const changed = await connector.UpdateRecord(updateCtx(ci, stored[0], { email: 'changed@example.invalid' }));
            expect(changed.Success).toBe(false);
            expect(changed.StatusCode).toBe(409);
            expect(changed.ErrorMessage).toMatch(/identity change is never pushed/);
            expect(changed.ErrorMessage).not.toContain('changed@example.invalid');
            expect(connector.Requests.filter(isActionRequest)).toHaveLength(0);
            // The vendor lower-cases addresses, so a case-only difference is not a change.
            const sameAddress = await connector.UpdateRecord(updateCtx(ci, stored[0], { email: 'STORED@example.invalid' }));
            expect(sameAddress).toEqual({ Success: true, StatusCode: 200, ExternalID: stored[0] });
            connector.Requests = [];
            connector.Responder = writeResponder({ Stored: null });
            const missing = await connector.UpdateRecord(updateCtx(ci, '950404', ATTRS));
            expect(missing.StatusCode).toBe(404);
            expect(connector.Requests.filter(isActionRequest)).toHaveLength(0);
        });

        it('never serialises a null or undefined attribute', async () => {
            const ci = companyIntegration(baseConfig({ SubscribeFieldDefinitions: [{ Name: 'First_Name' }, { Name: 'Last_Name', DefaultValue: 'Customer' }] }));
            connector.Responder = writeResponder({ Before: [], After: [ROW] });
            const result = await connector.CreateRecord(createCtx(ci, { ...ATTRS, First_Name: null, Last_Name: undefined, modified_date: null }));
            expect(result.Success).toBe(true);
            const doc = gridRequestOf(connector.Requests.filter(isActionRequest)[0]);
            expect(doc).toContain(`<SubscriberData><Subscribers><Subscriber><Email>${ROW[1]}</Email><ID>321</ID></Subscriber></Subscribers></SubscriberData>`);
            expect(doc).not.toMatch(/<Fields>|<FieldDefinitions>|First_Name|Last_Name|modified_date/);
            expect(doc).not.toMatch(/>(null|undefined)</);
        });

        it('refuses a blank, missing or non-integer Email / ID before any request', async () => {
            const ci = companyIntegration(baseConfig());
            connector.Responder = writeResponder({ Before: [], After: [ROW] });
            const cases: Array<Record<string, unknown>> = [
                { email: '', user_id: 321 },
                { email: '   ', user_id: 321 },
                { email: ROW[1], user_id: null },
                { email: ROW[1] },
                { user_id: 321 },
                { email: ROW[1], user_id: 'not-a-number' },
            ];
            for (const attributes of cases) {
                const result = await connector.CreateRecord(createCtx(ci, attributes));
                expect(result.Success).toBe(false);
                expect(result.StatusCode).toBe(422);
                expect(result.ErrorMessage).toMatch(/nothing was sent/);
            }
            expect(connector.Requests).toHaveLength(0);
        });

        it('answers 403 with no request only for an object without writeActions', async () => {
            const readOnly = firstReadOnlyIOName();
            const ci = companyIntegration(baseConfig());
            const create = await connector.CreateRecord(createCtx(ci, { anything: 'x' }, readOnly));
            const update = await connector.UpdateRecord(updateCtx(ci, '1', { anything: 'x' }, readOnly));
            for (const result of [create, update]) {
                expect(result).toEqual({ Success: false, StatusCode: 403, ErrorMessage: `${readOnly} is read-only in Informz: writes are not supported` });
            }
            expect(connector.Requests).toHaveLength(0);
        });

        it('fails the record with 422 when the ActionResponse reports invalid subscribers or a non-success status', async () => {
            const ci = companyIntegration(baseConfig());
            const variants = [
                actionEnvelope({ Invalid: 1, InvalidXml: `<InvalidSubscribers><Subscriber><Email>${ROW[1]}</Email><ID>321</ID></Subscriber></InvalidSubscribers>` }),
                actionEnvelope({ InvalidXml: `<InvalidSubscribers><Subscriber><Email>${ROW[1]}</Email></Subscriber></InvalidSubscribers>` }),
                actionEnvelope({ Invalid: 2 }),
                actionEnvelope({ Status: 'failure' }),
            ];
            for (const variant of variants) {
                connector.Requests = [];
                connector.Responder = writeResponder({ Before: [], After: [ROW], Action: () => variant });
                const result = await connector.CreateRecord(createCtx(ci, ATTRS));
                expect(result.Success).toBe(false);
                expect(result.StatusCode).toBe(422);
                expect(result.ExternalID).toBeUndefined();
                // pre-write read-backs (2) + the Subscribe; no post-write read-back once the vendor refused the record.
                expect(connector.Requests.map(isActionRequest)).toEqual([false, false, true]);
            }
        });

        it('escapes Field names/values, refuses XML 1.0 control characters with 422, confirms update ExternalID, validates XML tag names, and reclassifies read-back faults', async () => {
            // 1. Escapes `&`, `<`, `"` in <FieldDefinition><Name>, <Field element="…">, and <Field> value
            const specialField = 'Tier&"1"<A>';
            const ciEsc = companyIntegration(baseConfig({
                SubscribeFieldDefinitions: [{ Name: specialField, DataType: 'String', DefaultValue: 'D&"<' }],
            }));
            connector.Responder = writeResponder({ Before: [], After: [ROW] });
            const escRes = await connector.CreateRecord(createCtx(ciEsc, { ...ATTRS, [specialField]: 'Gold & <"Platinum">' }));
            expect(escRes).toEqual({ Success: true, StatusCode: 200, ExternalID: ROW[0] });
            const escDoc = gridRequestOf(connector.Requests.filter(isActionRequest)[0]);
            expect(escDoc).toContain('<FieldDefinition><Name>Tier&amp;&quot;1&quot;&lt;A&gt;</Name><DataType>String</DataType><DefaultValue>D&amp;&quot;&lt;</DefaultValue></FieldDefinition>');
            expect(escDoc).toContain('<Fields><Field element="Tier&amp;&quot;1&quot;&lt;A&gt;">Gold &amp; &lt;&quot;Platinum&quot;&gt;</Field></Fields>');

            // 2. Rejects XML 1.0 illegal control characters in scalarText with 422 before sending any request
            connector.Requests = [];
            const ctrlCi = companyIntegration(baseConfig({ SubscribeFieldDefinitions: [{ Name: 'Note' }] }));
            for (const bad of ['a\x01b', 'a\x00b', 'a\x1fb']) {
                const ctrlRes = await connector.CreateRecord(createCtx(ctrlCi, { ...ATTRS, Note: bad }));
                expect(ctrlRes.Success).toBe(false);
                expect(ctrlRes.StatusCode).toBe(422);
                expect(ctrlRes.ErrorMessage).toContain('"Note"');
            }
            expect(connector.Requests).toHaveLength(0);

            // 3. Update confirmation pins both `landed.length !== 1` (0 and 2 rows) and `landed[0] !== externalID`
            const stored: SubscriberRow = ['950003', 'stored@example.invalid', '323'];
            const updCi = companyIntegration(baseConfig({ SubscribeFieldDefinitions: [{ Name: 'First_Name' }] }));
            for (const badAfter of [[], [stored, OTHER_ROW], [['999888', stored[1], stored[2]] as SubscriberRow]]) {
                connector.Requests = [];
                connector.Responder = writeResponder({ Stored: stored, After: badAfter });
                const unconfirmed = await connector.UpdateRecord(updateCtx(updCi, stored[0], { First_Name: 'Ada' }));
                expect(unconfirmed.Success).toBe(false);
                expect(unconfirmed.StatusCode).toBe(409);
                expect(unconfirmed.ErrorMessage).toMatch(/not confirmed/);
            }

            // 4. Reclassifies a WriteContract-only fault (InsufficientDataToCreateSubscriberException) raised during a read-back GridRequest as 400 (not 502)
            connector.Requests = [];
            connector.Responder = writeResponder({
                Before: [],
                Readback: () => faultEnvelope('InformzServiceFault', 'InsufficientDataToCreateSubscriberException', 'bad readback input'),
            });
            const readbackFault = await connector.CreateRecord(createCtx(companyIntegration(baseConfig()), ATTRS));
            expect(readbackFault.Success).toBe(false);
            expect(readbackFault.StatusCode).toBe(400);

            // 5. assertXmlNames rejects non-XML tag names in writeActions metadata with 400 and zero requests
            connector.Requests = [];
            seedEngine(metadataWithWriteActions(wa => {
                wa.create.action = 'Bad Name';
            }));
            const badTag = await connector.CreateRecord(createCtx(companyIntegration(baseConfig()), ATTRS));
            expect(badTag.Success).toBe(false);
            expect(badTag.StatusCode).toBe(400);
            expect(badTag.ErrorMessage).toMatch(/not XML element names/);
            expect(connector.Requests).toHaveLength(0);
            seedEngine();
        });

        it('classifies write faults per ErrorContract + WriteContract: request defect 400, brand-IP precondition 401, never 403', async () => {
            const ci = companyIntegration(baseConfig());
            const codes = new Set([...ERROR_CONTRACT_CODES, ...(WRITE_FAULT_CLASSES.authOrPrecondition ?? []), ...(WRITE_FAULT_CLASSES.requestDefect ?? [])]);
            expect(codes.size).toBeGreaterThanOrEqual(20);
            const statusOf = new Map<string, number>();
            for (const code of codes) {
                connector.Responder = writeResponder({ Before: [], Action: () => faultEnvelope('InformzServiceFault', code, `rejected (${code})`) });
                const result = await connector.CreateRecord(createCtx(ci, ATTRS));
                expect(result.Success).toBe(false);
                expect(result.StatusCode).not.toBe(403);
                expect(result.ErrorMessage).toContain(code);
                expect(result.ErrorMessage).not.toContain(String(FIXTURES.Configuration.Password));
                statusOf.set(code, result.StatusCode);
            }
            expect(statusOf.get('InsufficientDataToCreateSubscriberException')).toBe(400);
            expect(statusOf.get('NoAvailableIPAddressException')).toBe(401);
            expect(statusOf.get('ConfigurationErrorException')).toBe(401);
            connector.Responder = writeResponder({ Before: [], Action: () => faultEnvelope('InformzServiceFault', 'NoAvailableIPAddressException', 'No available IP address') });
            const ip = await connector.CreateRecord(createCtx(ci, ATTRS));
            expect(ip.StatusCode).toBe(401);
            expect(ip.ErrorMessage).toMatch(/IP address registered with the brand/);
            connector.Responder = writeResponder({
                Before: [],
                Action: () => ({ Status: 500, Headers: {}, Text: '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Body><s:Fault><faultcode>s:Server</faultcode><faultstring>boom</faultstring></s:Fault></s:Body></s:Envelope>' }),
            });
            const generic = await connector.CreateRecord(createCtx(ci, ATTRS));
            expect(generic.StatusCode).toBe(502);
        });

        it('retries 429/503 honouring Retry-After and transport failures, then reports 503 (never 403)', async () => {
            const ci = companyIntegration(baseConfig());
            connector.Responder = writeResponder({ Before: [], Action: () => ({ Status: 503, Headers: { 'retry-after': '2' }, Text: '' }) });
            const throttled = await connector.CreateRecord(createCtx(ci, ATTRS));
            expect(throttled.StatusCode).toBe(503);
            expect(connector.Sleeps).toEqual([2000, 2000, 2000]);
            expect(connector.Requests.filter(isActionRequest)).toHaveLength(4);
            connector.Requests = [];
            connector.Sleeps = [];
            connector.Responder = writeResponder({ Before: [], Action: () => { throw new TypeError('fetch failed'); } });
            const transport = await connector.CreateRecord(createCtx(ci, ATTRS));
            expect(transport.StatusCode).toBe(503);
            expect(connector.Requests.filter(isActionRequest)).toHaveLength(4);
            connector.Requests = [];
            connector.Sleeps = [];
            let attempts = 0;
            connector.Responder = writeResponder({ Before: [], After: [ROW], Action: () => (++attempts === 1 ? { Status: 429, Headers: { 'retry-after': '1' }, Text: '' } : actionEnvelope()) });
            const recovered = await connector.CreateRecord(createCtx(ci, ATTRS));
            expect(recovered).toEqual({ Success: true, StatusCode: 200, ExternalID: ROW[0] });
            expect(connector.Sleeps).toEqual([1000]);
        });

        it('refuses delete with 405, the WriteScope reasons, and sends nothing', async () => {
            const result = await connector.DeleteRecord({ CompanyIntegration: companyIntegration(baseConfig()), ObjectName: 'Subscriber', ContextUser: USER, ExternalID: ROW[0] });
            expect(result.Success).toBe(false);
            expect(result.StatusCode).toBe(405);
            expect(result.ErrorMessage).toMatch(/not supported/);
            expect(result.ErrorMessage).toContain(DELETE_REASONS[0]);
            expect(connector.Requests).toHaveLength(0);
        });

        it('takes interest names and field definitions only from connection settings', async () => {
            // Metadata carries neither (tenant data never lives there).
            const writeActions = asRecord(asRecord(parseMaybeJSON(ioRow('Subscriber').fields.Configuration)).writeActions);
            expect(JSON.stringify(writeActions)).not.toMatch(/InterestName|FieldDefinition/);
            connector.Responder = writeResponder({ Before: [], After: [ROW] });
            await connector.CreateRecord(createCtx(companyIntegration(baseConfig()), { ...ATTRS, modified_date: '2026-01-01T00:00:00Z', subscriber_id: '1' }));
            const bare = gridRequestOf(connector.Requests.filter(isActionRequest)[0]);
            expect(bare).toContain(`<InterestDetails><InterestAction>${ADD_OR_UPDATE}</InterestAction></InterestDetails>`);
            expect(bare).not.toMatch(/<InterestNames>|<FieldDefinitions>|<Fields>|modified_date|subscriber_id/);

            connector.Requests = [];
            const unconfigured = await connector.CreateRecord(createCtx(companyIntegration(baseConfig()), { ...ATTRS, First_Name: 'Ada' }));
            expect(unconfigured.StatusCode).toBe(400);
            expect(unconfigured.ErrorMessage).toMatch(/"First_Name"/);
            expect(connector.Requests).toHaveLength(0);

            const ci = companyIntegration(baseConfig({
                SubscribeInterestNames: ['Members & Friends', 'News'],
                SubscribeFieldDefinitions: [{ Name: 'First_Name', DataType: 'String', DefaultValue: 'Member' }, { Name: 'Last_Name' }],
            }));
            connector.Responder = writeResponder({ Before: [], After: [ROW] });
            expect((await connector.CreateRecord(createCtx(ci, { ...ATTRS, First_Name: 'Ada' }))).Success).toBe(true);
            const doc = gridRequestOf(connector.Requests.filter(isActionRequest)[0]);
            expect(doc).toContain(`<InterestDetails><InterestNames><InterestName>Members &amp; Friends</InterestName><InterestName>News</InterestName></InterestNames><InterestAction>${ADD_OR_UPDATE}</InterestAction></InterestDetails>`);
            expect(doc).toContain('<FieldDefinitions><FieldDefinition><Name>First_Name</Name><DataType>String</DataType><DefaultValue>Member</DefaultValue></FieldDefinition></FieldDefinitions>');
            expect(doc).toContain('<Fields><Field element="First_Name">Ada</Field></Fields>');
            expect(doc).not.toContain('Last_Name');

            connector.Requests = [];
            const malformed = await connector.CreateRecord(createCtx(companyIntegration(baseConfig({ SubscribeInterestNames: 'Members' })), ATTRS));
            expect(malformed.StatusCode).toBe(400);
            expect(malformed.ErrorMessage).toMatch(/SubscribeInterestNames/);
            expect(connector.Requests).toHaveLength(0);
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

        it('contains no URL literal except the SOAP 1.1 envelope namespace and no dangling local study references', () => {
            const urls = [...source.matchAll(/https?:\/\/[^\s'"`)]+/g)].map(m => m[0]);
            expect(new Set(urls)).toEqual(new Set(['http://schemas.xmlsoap.org/soap/envelope/']));
            expect(source).not.toContain('WRITE_STUDY.md');
        });
    });

    describe('bounded date-window <Conditions> & migrationPacing', () => {
        it('serializes and parses v1 InformzWindowCursor losslessly', () => {
            const cursor = { Today: '2026-04-20', From: '2025-01-01', To: '2025-01-30', StartRow: 51, ScopeKey: '' };
            const s = formatInformzWindowCursor(cursor);
            expect(s).toBe('v1|2026-04-20|2025-01-01|2025-01-30|51|');
            expect(parseInformzWindowCursor(s)).toEqual(cursor);
            expect(initialInformzDateWindow({ startDate: '2025-01-01', windowDays: 10 }, null, '2026-04-20')).toEqual({
                From: '2025-01-01',
                To: '2025-01-10',
            });
            expect(nextInformzDateWindow({ From: '2025-01-01', To: '2025-01-10' }, { windowDays: 10 }, '2026-04-20')).toEqual({
                From: '2025-01-11',
                To: '2025-01-20',
            });
        });

        it('emits two-sided GTE + LTE <Conditions>, resets StartRow per window, and applies migrationPacing', async () => {
            const ci = companyIntegration(baseConfig({
                dateWindowing: {
                    Subscriber: {
                        startDate: '2026-01-01',
                        windowDays: 10,
                    },
                },
                migrationPacing: {
                    tokensPerSec: 1.5,
                    burst: 3,
                    maxConcurrency: 1,
                    minDelayBetweenRequestsMs: 150,
                    maxWindowsPerRun: 1,
                    checkpointPerWindow: true,
                },
            }));

            // Window 1 [2026-01-01, 2026-01-10]: Page 1 (StartRow 0, 2 rows) → Page 2 (StartRow 3, 1 row) → window drained
            const responses: InformzWireResponse[] = [
                gridEnvelope('subscriber', [
                    { Row: 1, Fields: [['subscriber_id', '140001'], ['email', 'a@example.invalid'], ['modified_date', '2026-01-02T10:00:00Z']] },
                    { Row: 2, Fields: [['subscriber_id', '140002'], ['email', 'b@example.invalid'], ['modified_date', '2026-01-05T10:00:00Z']] },
                ]),
                gridEnvelope('subscriber', [
                    { Row: 3, Fields: [['subscriber_id', '140003'], ['email', 'c@example.invalid'], ['modified_date', '2026-01-08T10:00:00Z']] },
                ]),
            ];
            connector.Responder = (_req, idx) => responses[idx] ?? gridEnvelope('subscriber', []);

            const initialCur = formatInformzWindowCursor({
                Today: '2026-01-20',
                From: '2026-01-01',
                To: '2026-01-10',
                StartRow: 0,
                ScopeKey: '',
            });

            const batch1 = await connector.FetchChanges(fetchContext(ci, 'Subscriber', { CurrentCursor: initialCur }));

            expect(connector.RateLimitPolicy).toEqual({ TokensPerSec: 1.5, Burst: 3 });
            expect(connector.MaxConcurrencyHint).toBe(1);
            expect(connector.Sleeps).toEqual([150]);
            expect(batch1.Records.map(r => r.ExternalID)).toEqual(['140001', '140002', '140003']);
            expect(batch1.HasMore).toBe(true);
            expect(batch1.NextCursor).toBe('v1|2026-01-20|2026-01-11|2026-01-20|0|');
            expect(batch1.NewWatermarkValue).toBe('2026-01-08T10:00:00Z');

            const doc0 = gridRequestOf(connector.Requests[0]);
            expect(doc0).toContain('<Condition><Single><DataElement>modified_date</DataElement><DataValue>2025-12-31T19:00:00</DataValue><Comparator>GTE</Comparator></Single></Condition>');
            expect(doc0).toContain('<Condition><Single><DataElement>modified_date</DataElement><DataValue>2026-01-10T18:59:59</DataValue><Comparator>LTE</Comparator></Single></Condition>');
            expect(doc0).toContain('<StartRow>0</StartRow>');
            expect(gridRequestOf(connector.Requests[1])).toContain('<StartRow>3</StartRow>');
        });
    });
});

