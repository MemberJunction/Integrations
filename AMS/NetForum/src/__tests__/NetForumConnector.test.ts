import { describe, it, expect } from 'vitest';
import type {
    RESTAuthContext,
    RESTResponse,
    CreateRecordContext,
    UpdateRecordContext,
    DeleteRecordContext,
    FetchContext,
} from '@memberjunction/integration-engine';
import type { MJIntegrationObjectEntity, MJIntegrationObjectFieldEntity, MJCompanyIntegrationEntity } from '@memberjunction/core-entities';
import type { UserInfo } from '@memberjunction/core';
import { NetForumConnector } from '../NetForumConnector.js';

/**
 * READ-ONLY / MOCKED-ONLY vitest (T4). NEVER hits a live netFORUM instance and NEVER mutates data.
 * Write-method tests assert REQUEST CONSTRUCTION + result handling against a mocked transport seam.
 *
 * The mocked SOAP responses below are SYNTHETIC, credential-free, PII-scrubbed compatibility samples
 * modeled on the xWeb ?op= wire shapes (netForumXML.asmx) + NetForumContext.md scenarios — they are
 * NOT captured from a real customer instance (no netFORUM credentials exist for this build). PII is
 * scrubbed per connector-test-conventions (names -> <scrubbed-name-N>, emails -> example+N@example.com).
 */

// The REAL Authenticate response shape (vendor capture, 2026-09-15; GUIDs replaced): the token is in
// the SOAP response HEADER, and the body's AuthenticateResult holds the namespace URI, not a token.
// The previous fixture put the GUID in AuthenticateResult — the guess the connector was built to.
const AUTH_XML = `<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Header>
    <AuthorizationToken soap:actor="4f158adf-9292-40e8-aa09-c905d3787e5f" xmlns="http://www.avectra.com/2005/">
      <Token>eb5667ab-25ac-45c9-b831-23b43be8f194</Token>
    </AuthorizationToken>
  </soap:Header>
  <soap:Body>
    <AuthenticateResponse xmlns="http://www.avectra.com/2005/">
      <AuthenticateResult>http://www.avectra.com/2005/</AuthenticateResult>
    </AuthenticateResponse>
  </soap:Body>
</soap:Envelope>`;

/** What the connector was built against through 1.3.4: no header, a GUID in AuthenticateResult. */
const AUTH_XML_BODY_ONLY = `<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <AuthenticateResponse xmlns="http://www.avectra.com/2005/">
      <AuthenticateResult>eb5667ab-25ac-45c9-b831-23b43be8f194</AuthenticateResult>
    </AuthenticateResponse>
  </soap:Body>
</soap:Envelope>`;

const GETQUERY_XML = `<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetQueryResponse xmlns="http://www.avectra.com/2005/">
      <GetQueryResult>
        <Results>
          <Result>
            <ind_cst_key>11111111-1111-1111-1111-111111111111</ind_cst_key>
            <ind_first_name>Ada</ind_first_name>
            <ind_last_name>&lt;scrubbed-name-1&gt;</ind_last_name>
            <eml_address>example+1@example.com</eml_address>
            <ind_change_date>2026-03-14T09:30:00</ind_change_date>
          </Result>
          <Result>
            <ind_cst_key>22222222-2222-2222-2222-222222222222</ind_cst_key>
            <ind_first_name>Grace</ind_first_name>
            <ind_last_name>&lt;scrubbed-name-2&gt;</ind_last_name>
            <eml_address>example+2@example.com</eml_address>
            <ind_change_date>2026-05-21T14:05:00</ind_change_date>
          </Result>
        </Results>
      </GetQueryResult>
    </GetQueryResponse>
  </soap:Body>
</soap:Envelope>`;

const GETQUERYDEF_XML = `<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetQueryDefinitionResponse xmlns="http://www.avectra.com/2005/">
      <GetQueryDefinitionResult>
        <obj_key>33333333-3333-3333-3333-333333333333</obj_key>
        <obj_name>Individual</obj_name>
        <obj_description>Individual / member records</obj_description>
        <ListTable>
          <lst_mdt_name>co_individual</lst_mdt_name>
          <ListFromTables>
            <ListFromTable>
              <lsf_from_table>co_individual</lsf_from_table>
              <Columns>
                <Column>
                  <mdc_name>ind_cst_key</mdc_name>
                  <mdc_description>Customer Key</mdc_description>
                  <mdc_data_type>uniqueidentifier</mdc_data_type>
                  <mdc_nullable>0</mdc_nullable>
                  <mdc_table_name>co_individual</mdc_table_name>
                  <mdc_width_max>16</mdc_width_max>
                </Column>
                <Column>
                  <mdc_name>ind_first_name</mdc_name>
                  <mdc_description>First Name</mdc_description>
                  <mdc_data_type>nvarchar</mdc_data_type>
                  <mdc_nullable>1</mdc_nullable>
                  <mdc_table_name>co_individual</mdc_table_name>
                  <mdc_width_max>50</mdc_width_max>
                </Column>
                <Column>
                  <mdc_name>ind_custom_loyalty_tier</mdc_name>
                  <mdc_description>Customer-added custom field</mdc_description>
                  <mdc_data_type>nvarchar</mdc_data_type>
                  <mdc_nullable>1</mdc_nullable>
                  <mdc_table_name>co_individual</mdc_table_name>
                  <mdc_width_max>25</mdc_width_max>
                </Column>
              </Columns>
            </ListFromTable>
          </ListFromTables>
        </ListTable>
      </GetQueryDefinitionResult>
    </GetQueryDefinitionResponse>
  </soap:Body>
</soap:Envelope>`;

const INSERT_XML = `<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <WEBIndividualInsertResponse xmlns="http://www.avectra.com/2005/">
      <WEBIndividualInsertResult>44444444-4444-4444-4444-444444444444</WEBIndividualInsertResult>
    </WEBIndividualInsertResponse>
  </soap:Body>
</soap:Envelope>`;

/** A captured outbound SOAP request (what the connector PUT on the wire). */
interface CapturedRequest {
    url: string;
    method: string;
    headers: Record<string, string>;
    body?: string;
}

/**
 * Test subclass: overrides the single SOAP transport seam (MakeRawHTTPRequest) to capture outbound
 * requests + return canned fixtures keyed by SOAPAction, and overrides the engine-cache accessors
 * so discovery/fetch run without a live IntegrationEngineBase. No credentials, no network.
 */
class MockedNetForumConnector extends NetForumConnector {
    public Requests: CapturedRequest[] = [];
    /** Map of SOAPAction operation suffix → canned RESTResponse. */
    public Responses: Record<string, RESTResponse> = {};
    /** The PK field name the mocked Individual object exposes. */
    public PkField = 'ind_cst_key';
    /** Canned Declared baseline — curated objects, as the engine cache would supply them. */
    public Declared: ExternalObjectSchema[] = [];
    /** When set, GetCachedObject throws for any name not listed — the engine's behaviour for an object not yet persisted. */
    public KnownObjects: Set<string> | null = null;
    /** When true the mocked cache carries NO primary key — a keyless object. */
    public Keyless = false;
    /** Per-object capability/config the mocked cache reports. */
    public Caps: { SupportsCreate: boolean; SupportsUpdate: boolean; CreateBodyKey: string | null; UpdateBodyKey: string | null; IncrementalWatermarkField: string | null; Configuration: string | null } = {
        SupportsCreate: true,
        SupportsUpdate: true,
        CreateBodyKey: 'WEBIndividualInsert',
        UpdateBodyKey: 'WEBIndividualUpdate',
        IncrementalWatermarkField: 'ind_change_date',
        Configuration: JSON.stringify({
            accessPath: { door: 'GetQuery', queryObject: 'Individual', nestingPath: [], doorArgs: { szObjectName: 'Individual', topModifier: '@TOP -1' } },
            stableOrderingKey: 'ind_cst_key',
            soapEndpoint: '/xweb/secure/netForumXML.asmx',
            writeOps: { createOp: 'WEBIndividualInsert', updateOp: 'WEBIndividualUpdate' },
        }),
    };

    protected override async DeclaredObjects(): Promise<ExternalObjectSchema[]> {
        return this.Declared;
    }

    /** Canned declared catalog for IntrospectSchema — set DeclaredSchemaResult per test. */
    public DeclaredSchemaResult: unknown = { Objects: [], IsAuthoritative: false };
    protected override async DeclaredSchema(): Promise<never> {
        return this.DeclaredSchemaResult as never;
    }

    /**
     * Per-action response SEQUENCE, consumed one entry per call and taking precedence over `Responses`.
     * Needed for anything that retries the same operation — a single canned response cannot distinguish
     * the first attempt from the second.
     */
    public ResponseQueue: Record<string, RESTResponse[]> = {};

    protected override async MakeRawHTTPRequest(url: string, method: string, headers: Record<string, string>, body?: string): Promise<RESTResponse> {
        this.Requests.push({ url, method, headers, body });
        const action = (headers['SOAPAction'] ?? '').replace('http://www.avectra.com/2005/', '');
        const queued = this.ResponseQueue[action];
        if (queued && queued.length > 0) return queued.shift()!;
        const canned = this.Responses[action];
        if (canned) return canned;
        throw new Error(`MockedNetForumConnector: no canned response for SOAPAction "${action}"`);
    }

    // Engine-cache stand-ins so DiscoverFields / FetchChanges / CRUD run without IntegrationEngineBase.
    protected override GetCachedObject(_integrationID: string, objectName: string): MJIntegrationObjectEntity {
        if (this.KnownObjects && !this.KnownObjects.has(objectName)) {
            throw new Error(`IntegrationObject not found: "${objectName}" for integration integ-1`);
        }
        return {
            ID: 'io-individual',
            IntegrationID: 'integ-1',
            Name: objectName,
            DisplayName: objectName,
            Description: 'Individual',
            SupportsCreate: this.Caps.SupportsCreate,
            SupportsUpdate: this.Caps.SupportsUpdate,
            CreateBodyKey: this.Caps.CreateBodyKey,
            UpdateBodyKey: this.Caps.UpdateBodyKey,
            IncrementalWatermarkField: this.Caps.IncrementalWatermarkField,
            Configuration: this.Caps.Configuration,
        } as unknown as MJIntegrationObjectEntity;
    }

    /** When true the mocked cache carries NO fields at all — an object persisted without columns. */
    public NoFields = false;

    protected override GetCachedFields(_objectID: string): MJIntegrationObjectFieldEntity[] {
        if (this.NoFields) return [];
        const fields = [
            { Name: this.PkField, DisplayName: 'Customer Key', Description: 'Customer Key', Type: 'String', IsPrimaryKey: true, IsRequired: true, IsReadOnly: true, IsUniqueKey: true, Status: 'Active', Sequence: 0 },
            { Name: 'ind_first_name', DisplayName: 'First Name', Description: 'First Name', Type: 'String', IsPrimaryKey: false, IsRequired: false, IsReadOnly: false, IsUniqueKey: false, Status: 'Active', Sequence: 1 },
        ] as unknown as MJIntegrationObjectFieldEntity[];
        return this.Keyless
            ? fields.map(f => ({ ...(f as unknown as Record<string, unknown>), IsPrimaryKey: false })) as unknown as MJIntegrationObjectFieldEntity[]
            : fields;
    }
}

const CI = { IntegrationID: 'integ-1', CredentialID: undefined, Configuration: JSON.stringify({ BaseURL: 'https://test.netforum.example', Username: 'u', Password: 'p' }) } as unknown as MJCompanyIntegrationEntity;
const CU = {} as UserInfo;

function makeConnector(): MockedNetForumConnector {
    const c = new MockedNetForumConnector();
    c.Responses['Authenticate'] = { Status: 200, Body: AUTH_XML, Headers: {} };
    c.Responses['GetVersion'] = { Status: 200, Body: '<GetVersionResponse xmlns="http://www.avectra.com/2005/"><GetVersionResult>2017.1</GetVersionResult></GetVersionResponse>', Headers: {} };
    c.Responses['GetQuery'] = { Status: 200, Body: GETQUERY_XML, Headers: {} };
    c.Responses['GetQueryDefinition'] = { Status: 200, Body: GETQUERYDEF_XML, Headers: {} };
    c.Responses['WEBIndividualInsert'] = { Status: 200, Body: INSERT_XML, Headers: {} };
    c.Responses['WEBIndividualUpdate'] = { Status: 200, Body: '<WEBIndividualUpdateResponse xmlns="http://www.avectra.com/2005/"><WEBIndividualUpdateResult>true</WEBIndividualUpdateResult></WEBIndividualUpdateResponse>', Headers: {} };
    return c;
}

function createCtx(objectName: string, attributes: Record<string, unknown>): CreateRecordContext {
    return { CompanyIntegration: CI, ContextUser: CU, ObjectName: objectName, Attributes: attributes } as unknown as CreateRecordContext;
}

describe('NetForumConnector — identity & capability', () => {
    const connector = new NetForumConnector();

    it('instantiates and exposes the canonical IntegrationName', () => {
        expect(connector).toBeInstanceOf(NetForumConnector);
        expect(connector.IntegrationName).toBe('NetForum Enterprise');
    });

    it('declares Create/Update; Delete held false (DeleteFacadeObject unconfirmed)', () => {
        expect(connector.SupportsCreate).toBe(true);
        expect(connector.SupportsUpdate).toBe(true);
        expect(connector.SupportsDelete).toBe(false);
    });

    it('discovery is NOT authoritative (must never deactivate Declared metadata)', () => {
        expect(connector.DiscoveryIsAuthoritative).toBe(false);
    });
});

describe('NetForumConnector — Authenticate (two-step SOAP token)', () => {
    it('POSTs a SOAP Authenticate envelope with credentials in the body and reads the token from the response HEADER', async () => {
        const c = makeConnector();
        // exercise auth via TestConnection (it authenticates then GetVersion)
        const r = await c.TestConnection(CI, CU);
        expect(r.Success).toBe(true);

        const authReq = c.Requests.find(req => req.headers['SOAPAction'] === 'http://www.avectra.com/2005/Authenticate');
        expect(authReq).toBeDefined();
        expect(authReq!.headers['Content-Type']).toContain('text/xml');
        // Credentials ride the SOAP BODY (userName/password), NOT an HTTP Basic/Bearer header.
        expect(authReq!.body).toContain('<Authenticate xmlns="http://www.avectra.com/2005/">');
        expect(authReq!.body).toContain('<userName>u</userName>');
        expect(authReq!.body).toContain('<password>p</password>');
        expect(authReq!.headers['Authorization']).toBeUndefined();
        // Authenticate is the bootstrap — it must NOT carry the AuthorizationToken header.
        expect(authReq!.body).not.toContain('AuthorizationToken');
    });

    it('carries the token in the SOAP AuthorizationToken header on subsequent calls (not an HTTP header)', async () => {
        const c = makeConnector();
        await c.TestConnection(CI, CU);
        const versionReq = c.Requests.find(req => req.headers['SOAPAction'] === 'http://www.avectra.com/2005/GetVersion');
        expect(versionReq).toBeDefined();
        expect(versionReq!.body).toContain('<AuthorizationToken xmlns="http://www.avectra.com/2005/"><Token>eb5667ab-25ac-45c9-b831-23b43be8f194</Token></AuthorizationToken>');
        // The body's AuthenticateResult (the namespace URI on a real tenant) must NEVER be sent as the
        // token — that is what produced HTTP 500 "Locked" on every call through 1.3.4.
        expect(versionReq!.body).not.toContain('<Token>http://www.avectra.com/2005/</Token>');
        expect(versionReq!.headers['Authorization']).toBeUndefined();
    });

    it('refuses an Authenticate response whose token is only in the body (no header) rather than sending a guess', async () => {
        const c = makeConnector();
        c.Responses['Authenticate'] = { Status: 200, Body: AUTH_XML_BODY_ONLY, Headers: {} };
        const r = await c.TestConnection(CI, CU);
        expect(r.Success).toBe(false);
        expect(r.Message).toMatch(/response HEADER/);
        // No data call was attempted with a body-sourced value.
        expect(c.Requests.some(req => req.headers['SOAPAction'] === 'http://www.avectra.com/2005/GetVersion')).toBe(false);
    });

    it('TestConnection surfaces auth failure as Success=false', async () => {
        const c = makeConnector();
        c.Responses['Authenticate'] = { Status: 200, Body: '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><AuthenticateResponse xmlns="http://www.avectra.com/2005/"></AuthenticateResponse></soap:Body></soap:Envelope>', Headers: {} };
        const r = await c.TestConnection(CI, CU);
        expect(r.Success).toBe(false);
    });
});

describe('NetForumConnector — NormalizeResponse (SOAP/XML row parsing)', () => {
    it('unwraps GetQueryResult and parses flattened rows to full-record objects', () => {
        const c = makeConnector();
        // NormalizeResponse is protected; reach it via FetchChanges below. Here, test directly through a thin proxy.
        const rows = (c as unknown as { NormalizeResponse(b: unknown, k: string | null): Record<string, unknown>[] }).NormalizeResponse(GETQUERY_XML, null);
        expect(rows).toHaveLength(2);
        expect(rows[0]['ind_cst_key']).toBe('11111111-1111-1111-1111-111111111111');
        expect(rows[0]['ind_first_name']).toBe('Ada');
        // XML entities unescaped
        expect(rows[0]['ind_last_name']).toBe('<scrubbed-name-1>');
        expect(rows[1]['ind_change_date']).toBe('2026-05-21T14:05:00');
    });

    it('returns [] for an empty / non-XML body', () => {
        const c = makeConnector();
        const proxy = c as unknown as { NormalizeResponse(b: unknown, k: string | null): Record<string, unknown>[] };
        expect(proxy.NormalizeResponse('', null)).toEqual([]);
        expect(proxy.NormalizeResponse(null, null)).toEqual([]);
    });
});

describe('NetForumConnector — FetchChanges (GetQuery door + per-facade watermark)', () => {
    it('builds a GetQuery bounded by BatchSize with full-record pass-through; PK extracted from metadata PK field', async () => {
        const c = makeConnector();
        const ctx: FetchContext = { CompanyIntegration: CI, ObjectName: 'Individual', WatermarkValue: null, BatchSize: 100, ContextUser: CU };
        const res = await c.FetchChanges(ctx);

        const req = c.Requests.find(r => r.headers['SOAPAction'] === 'http://www.avectra.com/2005/GetQuery');
        expect(req).toBeDefined();
        // BatchSize bounds the page. Previously this was a hardcoded `@TOP -1`, which pulled the
        // entire result set into memory in a single SOAP call regardless of BatchSize.
        expect(req!.body).toContain('<szObjectName>Individual @TOP 100</szObjectName>');
        // EMPTY szColumnList. The vendor documents `*` as an invalid value that FAULTS the call (and
        // xWeb counts every fault toward the daily limit that locks the account); an empty list returns
        // the object's default columns with the primary key first. `*` is what locked us out in 2026-09.
        expect(req!.body).toContain('<szColumnList></szColumnList>');
        expect(req!.body).not.toContain('<szColumnList>*');
        // no watermark → no szWhereClause
        expect(req!.body).not.toContain('szWhereClause');

        expect(res.Records).toHaveLength(2);
        expect(res.Records[0].ExternalID).toBe('11111111-1111-1111-1111-111111111111');
        expect(res.Records[0].ObjectType).toBe('Individual');
        // FULL-record pass-through: every column reaches Fields (not a narrow literal)
        expect(res.Records[0].Fields['ind_first_name']).toBe('Ada');
        expect(res.Records[0].Fields['eml_address']).toBe('example+1@example.com');
        expect(Object.keys(res.Records[0].Fields).length).toBeGreaterThanOrEqual(5);
        expect(res.HasMore).toBe(false);
        // watermark advanced to the max ind_change_date seen
        expect(res.NewWatermarkValue).toBe('2026-05-21T14:05:00');
    });

    it('reports HasMore + a keyset resume position when the page comes back full', async () => {
        const c = makeConnector();
        // BatchSize 2 with a 2-row fixture ⇒ a FULL page ⇒ more may remain.
        const ctx: FetchContext = { CompanyIntegration: CI, ObjectName: 'Individual', WatermarkValue: null, BatchSize: 2, ContextUser: CU };
        const res = await c.FetchChanges(ctx);

        const req = c.Requests.find(r => r.headers['SOAPAction'] === 'http://www.avectra.com/2005/GetQuery');
        expect(req!.body).toContain('<szObjectName>Individual @TOP 2</szObjectName>');
        expect(res.HasMore).toBe(true);
        expect(res.NextAfterKeyValue).toBeDefined();
        // The watermark must NOT advance mid-scan: a crash before the final page would otherwise
        // skip every later row older than the new watermark.
        expect(res.NewWatermarkValue).toBeUndefined();
    });

    it('seeks past AfterKeyValue with a keyset predicate on the next page', async () => {
        const c = makeConnector();
        const ctx: FetchContext = {
            CompanyIntegration: CI, ObjectName: 'Individual', WatermarkValue: null,
            BatchSize: 2, ContextUser: CU,
            AfterKeyValue: '11111111-1111-1111-1111-111111111111',
        };
        await c.FetchChanges(ctx);

        const req = c.Requests.find(r => r.headers['SOAPAction'] === 'http://www.avectra.com/2005/GetQuery');
        expect(req!.body).toContain('szWhereClause');
        expect(req!.body).toContain('&gt; &apos;11111111-1111-1111-1111-111111111111&apos;');
    });

    it('on a subsequent sync applies the per-facade watermark field in szWhereClause (NOT a canonical LastModifiedDate)', async () => {
        const c = makeConnector();
        const ctx: FetchContext = { CompanyIntegration: CI, ObjectName: 'Individual', WatermarkValue: '2026-01-01T00:00:00', BatchSize: 100, ContextUser: CU };
        await c.FetchChanges(ctx);
        const req = c.Requests.find(r => r.headers['SOAPAction'] === 'http://www.avectra.com/2005/GetQuery');
        // szWhereClause value is XML-escaped in the envelope (>= → &gt;=, ' → &apos;)
        expect(req!.body).toContain('ind_change_date &gt;= &apos;2026-01-01T00:00:00&apos;');
        expect(req!.body).not.toContain('LastModifiedDate');
    });

    it('emits a ZERO_ROWS warning when GetQuery returns no rows', async () => {
        const c = makeConnector();
        c.Responses['GetQuery'] = { Status: 200, Body: '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><GetQueryResponse xmlns="http://www.avectra.com/2005/"><GetQueryResult><Results /></GetQueryResult></GetQueryResponse></soap:Body></soap:Envelope>', Headers: {} };
        const ctx: FetchContext = { CompanyIntegration: CI, ObjectName: 'Individual', WatermarkValue: null, BatchSize: 100, ContextUser: CU };
        const res = await c.FetchChanges(ctx);
        expect(res.Records).toHaveLength(0);
        expect(res.Warnings?.[0].Code).toBe('ZERO_ROWS');
    });

    it('warns WATERMARK_COLUMN_ABSENT when the default column list omits the watermark column', async () => {
        const c = makeConnector();
        // An empty szColumnList returns the tenant's DEFAULT list columns, and nothing guarantees the
        // IO's watermark column is among them. Rows without it must not pass as a healthy batch —
        // the watermark would never advance and every sync would re-read the same window.
        c.Responses['GetQuery'] = { Status: 200, Body: '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><GetQueryResponse xmlns="http://www.avectra.com/2005/"><GetQueryResult><Results><Result><ind_cst_key>11111111-1111-1111-1111-111111111111</ind_cst_key><ind_first_name>Ada</ind_first_name></Result></Results></GetQueryResult></GetQueryResponse></soap:Body></soap:Envelope>', Headers: {} };
        const ctx: FetchContext = { CompanyIntegration: CI, ObjectName: 'Individual', WatermarkValue: null, BatchSize: 100, ContextUser: CU };
        const res = await c.FetchChanges(ctx);
        expect(res.Records).toHaveLength(1);
        const w = res.Warnings?.find(x => x.Code === 'WATERMARK_COLUMN_ABSENT');
        expect(w).toBeDefined();
        expect(w!.Message).toContain('ind_change_date');
        expect(w!.Data?.Columns).toEqual(['ind_cst_key', 'ind_first_name']);
        expect(res.NewWatermarkValue).toBeUndefined();
    });

    it('sends a DECLARED Configuration.columnList, completed with the PK, ordering key and watermark it reads', async () => {
        const c = makeConnector();
        // The door returns ONLY named columns, so a declaration that omits what FetchChanges itself
        // needs (ExternalID, keyset resume, watermark) would silently break all three. Appended, deduped.
        c.Caps = { ...c.Caps, Configuration: JSON.stringify({ ...JSON.parse(c.Caps.Configuration!), columnList: ['ind_first_name', 'IND_CST_KEY', ' ind_last_name '] }) };
        const ctx: FetchContext = { CompanyIntegration: CI, ObjectName: 'Individual', WatermarkValue: null, BatchSize: 100, ContextUser: CU };
        await c.FetchChanges(ctx);
        const req = c.Requests.find(r => r.headers['SOAPAction'] === 'http://www.avectra.com/2005/GetQuery');
        expect(req!.body).toContain('<szColumnList>ind_first_name,IND_CST_KEY,ind_last_name,ind_change_date</szColumnList>');
    });

    it('sends an EMPTY szColumnList when no columnList is declared (the tenant default list)', async () => {
        const c = makeConnector();
        const ctx: FetchContext = { CompanyIntegration: CI, ObjectName: 'Individual', WatermarkValue: null, BatchSize: 100, ContextUser: CU };
        await c.FetchChanges(ctx);
        const req = c.Requests.find(r => r.headers['SOAPAction'] === 'http://www.avectra.com/2005/GetQuery');
        expect(req!.body).toContain('<szColumnList></szColumnList>');
    });

    /**
     * The door can reject its OWN default list. An empty szColumnList asks xWeb for the object's default
     * columns; on a tenant whose default is `*` the request faults with "'*' is not a valid value for
     * szColumnList". Observed live on the BC sandbox 2026-09-18: 862 of 888 objects failed this way
     * during discovery at ~15s each, exhausting the run deadline before one row was persisted — and the
     * 26 that succeeded were exactly the 26 carrying a declared columnList.
     *
     * These tests are mutation-proof by construction: the first queued response is a fault, so deleting
     * the retry makes FetchChanges throw and both fail. That is deliberate — the 1.6.0 test for the
     * sibling fix passed with the fix removed, because the sampler's fallback reached the same endpoint.
     */
    const INVALID_DEFAULT_FAULT = {
        Status: 500,
        Body: `<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><soap:Fault><faultcode>soap:Server</faultcode><faultstring>'*' is not a valid value for szColumnList.</faultstring></soap:Fault></soap:Body></soap:Envelope>`,
        Headers: {},
    };

    it('retries with an EXPLICIT column list when the door rejects its own `*` default list', async () => {
        const c = makeConnector();
        c.ResponseQueue['GetQuery'] = [
            INVALID_DEFAULT_FAULT,
            { Status: 200, Body: GETQUERY_XML, Headers: {} },
        ];
        const ctx: FetchContext = { CompanyIntegration: CI, ObjectName: 'Individual', WatermarkValue: null, BatchSize: 100, ContextUser: CU };

        const result = await c.FetchChanges(ctx);

        const sent = c.Requests.filter(r => r.headers['SOAPAction'] === 'http://www.avectra.com/2005/GetQuery');
        expect(sent).toHaveLength(2);
        // First attempt is unchanged — empty, i.e. "use the tenant default".
        expect(sent[0].body).toContain('<szColumnList></szColumnList>');
        // Retry names the columns, so the default is never consulted. Sourced from the cached fields
        // here (the sync path); discovery sources them from GetQueryDefinition instead.
        expect(sent[1].body).toContain('<szColumnList>ind_cst_key,ind_first_name,ind_change_date</szColumnList>');
        // And the fetch actually succeeds rather than surfacing the tenant's misconfiguration.
        expect(result.Records.length).toBeGreaterThan(0);
    });

    it('does NOT retry an unrelated HTTP 500 — that error still surfaces', async () => {
        const c = makeConnector();
        c.ResponseQueue['GetQuery'] = [
            { Status: 500, Body: `<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><soap:Fault><faultstring>Locked</faultstring></soap:Fault></soap:Body></soap:Envelope>`, Headers: {} },
            { Status: 200, Body: GETQUERY_XML, Headers: {} },
        ];
        const ctx: FetchContext = { CompanyIntegration: CI, ObjectName: 'Individual', WatermarkValue: null, BatchSize: 100, ContextUser: CU };

        await expect(c.FetchChanges(ctx)).rejects.toThrow(/Locked/);
        const sent = c.Requests.filter(r => r.headers['SOAPAction'] === 'http://www.avectra.com/2005/GetQuery');
        expect(sent).toHaveLength(1);
    });

    /**
     * THE FAULT BUDGET. xWeb counts FAULTS, not calls, against `MethodsFaultLimitPerDay` (default 100
     * per user+IP) and does NOT auto-reset — a vendor clears it by hand. The retry above is correct
     * once and ruinous repeated: before the latch it re-learned the tenant's default was bad on EVERY
     * call, so 888 objects cost >=888 faults against a budget of 100. That is what locked the BC
     * sandbox account on 2026-09-05 and again on 2026-09-19 — our request shape, not the tenant's data.
     *
     * These assert the REQUEST COUNT, which is the only thing that maps to fault spend. Asserting the
     * column list alone would pass on an implementation that computes the right list and still sends
     * the doomed empty request first.
     */
    const CI_A = { ...CI, ID: 'ci-aaa' } as unknown as MJCompanyIntegrationEntity;
    const CI_B = { ...CI, ID: 'ci-bbb' } as unknown as MJCompanyIntegrationEntity;

    it('pays the fault ONCE per connection — the second fetch leads with the explicit list', async () => {
        const c = makeConnector();
        // Only the FIRST GetQuery faults. If the second fetch still opened with an empty list it would
        // consume the 200 queued here and then have nothing for its retry, so a regression cannot pass
        // this by accident — the request count is checked directly besides.
        c.ResponseQueue['GetQuery'] = [
            INVALID_DEFAULT_FAULT,
            { Status: 200, Body: GETQUERY_XML, Headers: {} },
            { Status: 200, Body: GETQUERY_XML, Headers: {} },
        ];
        const ctx: FetchContext = { CompanyIntegration: CI_A, ObjectName: 'Individual', WatermarkValue: null, BatchSize: 100, ContextUser: CU };

        await c.FetchChanges(ctx);
        await c.FetchChanges(ctx);

        const sent = c.Requests.filter(r => r.headers['SOAPAction'] === 'http://www.avectra.com/2005/GetQuery');
        // 2 for the first fetch (empty -> fault -> explicit), 1 for the second. NOT 4.
        expect(sent).toHaveLength(3);
        expect(sent[0].body).toContain('<szColumnList></szColumnList>');
        expect(sent[1].body).toContain('<szColumnList>ind_cst_key,ind_first_name,ind_change_date</szColumnList>');
        // The whole point: the second fetch never sends an empty list, so it never costs a fault.
        expect(sent[2].body).not.toContain('<szColumnList></szColumnList>');
        expect(sent[2].body).toContain('<szColumnList>ind_cst_key,ind_first_name,ind_change_date</szColumnList>');
    });

    it('latches per connection — a different connection is not assumed broken', async () => {
        const c = makeConnector();
        c.ResponseQueue['GetQuery'] = [
            INVALID_DEFAULT_FAULT,                                  // A: empty -> fault
            { Status: 200, Body: GETQUERY_XML, Headers: {} },       // A: explicit -> ok
            { Status: 200, Body: GETQUERY_XML, Headers: {} },       // B: empty -> ok (its default is fine)
        ];
        await c.FetchChanges({ CompanyIntegration: CI_A, ObjectName: 'Individual', WatermarkValue: null, BatchSize: 100, ContextUser: CU });
        await c.FetchChanges({ CompanyIntegration: CI_B, ObjectName: 'Individual', WatermarkValue: null, BatchSize: 100, ContextUser: CU });

        const sent = c.Requests.filter(r => r.headers['SOAPAction'] === 'http://www.avectra.com/2005/GetQuery');
        expect(sent).toHaveLength(3);
        // B must still ask for the tenant default. Sharing one connection's verdict across every
        // connection in the process would send a narrowed column list to a tenant that never needed it.
        expect(sent[2].body).toContain('<szColumnList></szColumnList>');
    });

    it('never overwrites a DECLARED columnList, even once latched', async () => {
        const c = makeConnector();
        c.ResponseQueue['GetQuery'] = [
            INVALID_DEFAULT_FAULT,
            { Status: 200, Body: GETQUERY_XML, Headers: {} },
            { Status: 200, Body: GETQUERY_XML, Headers: {} },
        ];
        const ctx: FetchContext = { CompanyIntegration: CI_A, ObjectName: 'Individual', WatermarkValue: null, BatchSize: 100, ContextUser: CU };
        await c.FetchChanges(ctx);

        // Now declare one. The latch must not touch it — a declaration is the operator's explicit
        // instruction and outranks anything inferred from a fault.
        c.Caps = { ...c.Caps, Configuration: JSON.stringify({ ...JSON.parse(c.Caps.Configuration!), columnList: ['ind_last_name'] }) };
        await c.FetchChanges(ctx);

        const sent = c.Requests.filter(r => r.headers['SOAPAction'] === 'http://www.avectra.com/2005/GetQuery');
        expect(sent).toHaveLength(3);
        expect(sent[2].body).toContain('<szColumnList>ind_last_name,ind_cst_key,ind_change_date</szColumnList>');
    });

    it('does NOT latch when a DECLARED list is what the door rejected', async () => {
        const c = makeConnector();
        // Same fault wording, different cause: the operator's own list was refused. Latching on it
        // would silently narrow what every later object sends, hiding a real declaration bug.
        c.Caps = { ...c.Caps, Configuration: JSON.stringify({ ...JSON.parse(c.Caps.Configuration!), columnList: ['ind_last_name'] }) };
        c.ResponseQueue['GetQuery'] = [
            INVALID_DEFAULT_FAULT,
            { Status: 200, Body: GETQUERY_XML, Headers: {} },
            { Status: 200, Body: GETQUERY_XML, Headers: {} },
        ];
        const ctx: FetchContext = { CompanyIntegration: CI_A, ObjectName: 'Individual', WatermarkValue: null, BatchSize: 100, ContextUser: CU };
        await c.FetchChanges(ctx);

        // Remove the declaration; the connection must be UNLATCHED, so this asks for the default again.
        c.Caps = { ...c.Caps, Configuration: JSON.stringify({ BaseURL: 'https://test.netforum.example', Username: 'u', Password: 'p' }) };
        await c.FetchChanges(ctx);

        const sent = c.Requests.filter(r => r.headers['SOAPAction'] === 'http://www.avectra.com/2005/GetQuery');
        expect(sent[sent.length - 1].body).toContain('<szColumnList></szColumnList>');
    });

    it('does not warn WATERMARK_COLUMN_ABSENT when rows carry the watermark column', async () => {
        const c = makeConnector();
        const ctx: FetchContext = { CompanyIntegration: CI, ObjectName: 'Individual', WatermarkValue: null, BatchSize: 100, ContextUser: CU };
        const res = await c.FetchChanges(ctx);
        expect(res.Warnings?.some(x => x.Code === 'WATERMARK_COLUMN_ABSENT') ?? false).toBe(false);
    });
});

describe('NetForumConnector — DiscoverFields (runtime GetQueryDefinition mechanism)', () => {
    it('parses the GetQueryDefinition column definition, surfacing customer-added columns', async () => {
        const c = makeConnector();
        const fields = await c.DiscoverFields(CI, 'Individual', CU);
        const names = fields.map(f => f.Name);
        expect(names).toContain('ind_cst_key');
        expect(names).toContain('ind_first_name');
        // customer-added column discovered at runtime (not in the static Declared set)
        expect(names).toContain('ind_custom_loyalty_tier');

        const custom = fields.find(f => f.Name === 'ind_custom_loyalty_tier')!;
        expect(custom.MaxLength).toBe(25);
        expect(custom.AllowsNull).toBe(true); // mdc_nullable=1

        const pk = fields.find(f => f.Name === 'ind_cst_key')!;
        expect(pk.AllowsNull).toBe(false); // mdc_nullable=0
        expect(pk.IsPrimaryKey).toBe(true); // Declared PK preserved (definition doesn't mark PK)
    });

    it('falls back to the Declared fields when GetQueryDefinition is unavailable (credential-free)', async () => {
        const c = makeConnector();
        c.Responses['GetQueryDefinition'] = { Status: 401, Body: '', Headers: {} };
        const fields = await c.DiscoverFields(CI, 'Individual', CU);
        // Declared baseline (from the mocked cache) is never lost
        expect(fields.map(f => f.Name)).toContain('ind_cst_key');
    });
});

describe('NetForumConnector — CreateRecord (facade SOAP op via metadata columns)', () => {
    it('POSTs the WEBIndividualInsert SOAP op and returns the new key via BuildCreatedResult', async () => {
        const c = makeConnector();
        const result = await c.CreateRecord(createCtx('Individual', { ind_first_name: 'Ada' }));
        const req = c.Requests.find(r => r.headers['SOAPAction'] === 'http://www.avectra.com/2005/WEBIndividualInsert');
        expect(req).toBeDefined();
        expect(req!.body).toContain('<WEBIndividualInsert xmlns="http://www.avectra.com/2005/">');
        expect(req!.body).toContain('<ind_first_name>Ada</ind_first_name>');
        // token carried in the SOAP header
        expect(req!.body).toContain('<AuthorizationToken xmlns="http://www.avectra.com/2005/">');
        expect(result.Success).toBe(true);
        expect(result.ExternalID).toBe('44444444-4444-4444-4444-444444444444');
    });

    it('fails loudly when a 2xx create returns no record key (silent-loss guard)', async () => {
        const c = makeConnector();
        c.Responses['WEBIndividualInsert'] = { Status: 200, Body: '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><WEBIndividualInsertResponse xmlns="http://www.avectra.com/2005/"><WEBIndividualInsertResult></WEBIndividualInsertResult></WEBIndividualInsertResponse></soap:Body></soap:Envelope>', Headers: {} };
        const result = await c.CreateRecord(createCtx('Individual', { ind_first_name: 'Ada' }));
        expect(result.Success).toBe(false);
        expect(result.ExternalID ?? '').toBe('');
    });

    it('returns a clean error when the object does not support create', async () => {
        const c = makeConnector();
        c.Caps = { ...c.Caps, SupportsCreate: false };
        const result = await c.CreateRecord(createCtx('Individual', { ind_first_name: 'Ada' }));
        expect(result.Success).toBe(false);
    });
});

describe('NetForumConnector — UpdateRecord (facade SOAP op)', () => {
    it('POSTs the WEBIndividualUpdate op with the PK + attributes', async () => {
        const c = makeConnector();
        const ctx: UpdateRecordContext = { CompanyIntegration: CI, ContextUser: CU, ObjectName: 'Individual', ExternalID: 'IND-1', Attributes: { ind_first_name: 'Grace' } } as unknown as UpdateRecordContext;
        const result = await c.UpdateRecord(ctx);
        const req = c.Requests.find(r => r.headers['SOAPAction'] === 'http://www.avectra.com/2005/WEBIndividualUpdate');
        expect(req).toBeDefined();
        expect(req!.body).toContain('<ind_cst_key>IND-1</ind_cst_key>');
        expect(req!.body).toContain('<ind_first_name>Grace</ind_first_name>');
        expect(result.Success).toBe(true);
        expect(result.ExternalID).toBe('IND-1');
    });
});

describe('NetForumConnector — DeleteRecord (unsupported)', () => {
    it('returns a clean error (no live mutation) since delete is unconfirmed', async () => {
        const c = makeConnector();
        const ctx: DeleteRecordContext = { CompanyIntegration: CI, ContextUser: CU, ObjectName: 'Individual', ExternalID: 'IND-1' } as unknown as DeleteRecordContext;
        const result = await c.DeleteRecord(ctx);
        expect(result.Success).toBe(false);
        expect(result.ErrorMessage).toContain('does not support delete');
    });
});

describe('NetForumConnector — StableOrderingKey', () => {
    it('returns the IO stableOrderingKey for keyset resume', async () => {
        const c = makeConnector();
        // prime LastIntegrationID via a fetch
        await c.FetchChanges({ CompanyIntegration: CI, ObjectName: 'Individual', WatermarkValue: null, BatchSize: 100, ContextUser: CU });
        expect(c.StableOrderingKey('Individual')).toBe('ind_cst_key');
    });
});

// ── GetFacadeObjectList — the VERIFIED live shape (probed 2026-09-15: 878 <ObjectObject> rows) ──
const FACADE_OBJECT_LIST_XML = `<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body>
<GetFacadeObjectListResponse xmlns="http://www.avectra.com/2005/"><GetFacadeObjectListResult>
<ObjectObjects>
  <ObjectObject><obj_name>Individual</obj_name><obj_key>k1</obj_key><obj_description>Individual</obj_description></ObjectObject>
  <ObjectObject><obj_name>Accreditation</obj_name><obj_key>k2</obj_key><obj_description>Accreditation record</obj_description></ObjectObject>
  <ObjectObject><obj_name>AskLadder</obj_name><obj_key>k3</obj_key><obj_description>Ask Ladder</obj_description></ObjectObject>
  <ObjectObject><obj_name>Assignment</obj_name><obj_key>k4</obj_key><obj_description></obj_description></ObjectObject>
</ObjectObjects>
</GetFacadeObjectListResult></GetFacadeObjectListResponse>
</soap:Body></soap:Envelope>`;


describe('NetForumConnector — DiscoverObjects ALWAYS enumerates from the source', () => {
    it('calls GetFacadeObjectList on every discovery — no flag, no opt-in', async () => {
        const c = makeConnector();
        c.Responses['GetFacadeObjectList'] = { Status: 200, Body: FACADE_OBJECT_LIST_XML, Headers: {} };
        await c.DiscoverObjects(CI, CU);
        const actions = c.Requests.map(r => (r.headers['SOAPAction'] ?? '').replace('http://www.avectra.com/2005/', ''));
        expect(actions).toContain('GetFacadeObjectList');
    });

    it('returns every enumerated object — the declared catalog is a floor, never a ceiling', async () => {
        const c = makeConnector();
        c.Declared = [{ Name: 'Individual', Label: 'Individual', SupportsIncrementalSync: true, SupportsWrite: true }];
        c.Responses['GetFacadeObjectList'] = { Status: 200, Body: FACADE_OBJECT_LIST_XML, Headers: {} };
        const objs = await c.DiscoverObjects(CI, CU);
        // fixture: Individual (declared) + Accreditation + AskLadder + Assignment
        expect(objs).toHaveLength(4);
        expect(objs.map(o => o.Name)).toEqual(
            expect.arrayContaining(['Individual', 'Accreditation', 'AskLadder', 'Assignment']));
    });

    it('parses obj_name/obj_description and reports capability honestly', async () => {
        const c = makeConnector();
        c.Responses['GetFacadeObjectList'] = { Status: 200, Body: FACADE_OBJECT_LIST_XML, Headers: {} };
        const objs = await c.DiscoverObjects(CI, CU);
        const acc = objs.find(o => o.Name === 'Accreditation')!;
        expect(acc.Label).toBe('Accreditation record');
        expect(acc.SupportsIncrementalSync).toBe(false);
        expect(acc.SupportsWrite).toBe(false);
        const asg = objs.find(o => o.Name === 'Assignment')!;
        expect(asg.Label).toBe('Assignment'); // empty obj_description falls back to the name
    });

    it('never reports the same object twice', async () => {
        const c = makeConnector();
        c.Responses['GetFacadeObjectList'] = { Status: 200, Body: FACADE_OBJECT_LIST_XML, Headers: {} };
        const names = (await c.DiscoverObjects(CI, CU)).map(o => o.Name.toLowerCase());
        expect(new Set(names).size).toBe(names.length);
    });

    it('falls back to the declared baseline when the account is not granted the method', async () => {
        const c = makeConnector();
        c.Declared = [{ Name: 'Individual', Label: 'Individual', SupportsIncrementalSync: true, SupportsWrite: true }];
        c.Responses['GetFacadeObjectList'] = { Status: 500, Body: '<faultstring>not authorized</faultstring>', Headers: {} };
        const objs = await c.DiscoverObjects(CI, CU);
        expect(objs.map(o => o.Name)).toEqual(['Individual']);
    });
});

describe('NetForumConnector — the client object set is a RECONCILIATION (everything.txt §2)', () => {
    // declared: Individual (in source), Membership + FacadeObject (NOT in source)
    const DECLARED = [
        { Name: 'Individual', Label: 'Individual (declared)', Description: 'declared desc',
          SupportsIncrementalSync: true, SupportsWrite: true },
        { Name: 'Membership', Label: 'Membership', SupportsIncrementalSync: true, SupportsWrite: true },
        { Name: 'FacadeObject', Label: 'FacadeObject', SupportsIncrementalSync: false, SupportsWrite: false },
    ];

    it('EXCLUDES declared objects the source does not list — they are not this client\'s objects', async () => {
        const c = makeConnector();
        c.Declared = DECLARED;
        c.Responses['GetFacadeObjectList'] = { Status: 200, Body: FACADE_OBJECT_LIST_XML, Headers: {} };
        const names = (await c.DiscoverObjects(CI, CU)).map(o => o.Name);
        expect(names).not.toContain('Membership');
        expect(names).not.toContain('FacadeObject');
    });

    it('ADDS objects the source has and the declaration does not', async () => {
        const c = makeConnector();
        c.Declared = DECLARED;
        c.Responses['GetFacadeObjectList'] = { Status: 200, Body: FACADE_OBJECT_LIST_XML, Headers: {} };
        const names = (await c.DiscoverObjects(CI, CU)).map(o => o.Name);
        expect(names).toEqual(expect.arrayContaining(['Accreditation', 'AskLadder', 'Assignment']));
    });

    it('overlays per attribute with EXTERNAL SYSTEM priority, declaration as fallback', async () => {
        const c = makeConnector();
        c.Declared = DECLARED;
        c.Responses['GetFacadeObjectList'] = { Status: 200, Body: FACADE_OBJECT_LIST_XML, Headers: {} };
        const ind = (await c.DiscoverObjects(CI, CU)).find(o => o.Name === 'Individual')!;
        // the source states a description -> it wins
        expect(ind.Description).toBe('Individual');
        // the source says NOTHING about these -> the declaration survives
        expect(ind.SupportsIncrementalSync).toBe(true);
        expect(ind.SupportsWrite).toBe(true);
    });

    it('falls back to the declaration when the source is silent on an attribute', async () => {
        const c = makeConnector();
        // Assignment has an EMPTY obj_description in the fixture
        c.Declared = [{ Name: 'Assignment', Label: 'Assignment (declared)', Description: 'kept',
                        SupportsIncrementalSync: true, SupportsWrite: false }];
        c.Responses['GetFacadeObjectList'] = { Status: 200, Body: FACADE_OBJECT_LIST_XML, Headers: {} };
        const asg = (await c.DiscoverObjects(CI, CU)).find(o => o.Name === 'Assignment')!;
        expect(asg.Description).toBe('kept');
        expect(asg.Label).toBe('Assignment (declared)');
    });

    it('NEVER excludes when the source did not answer — a failure is not an absence', async () => {
        const c = makeConnector();
        c.Declared = DECLARED;
        c.Responses['GetFacadeObjectList'] = { Status: 500, Body: '<faultstring>not authorized</faultstring>', Headers: {} };
        const names = (await c.DiscoverObjects(CI, CU)).map(o => o.Name);
        expect(names).toEqual(['Individual', 'Membership', 'FacadeObject']);
    });
});


describe('NetForumConnector — SOAP faults carry netFORUM\'s own reason', () => {
    const FAULT = `<?xml version="1.0"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
<soap:Body><soap:Fault><faultcode>soap:Server</faultcode>
<faultstring>Account is not authorized to perform Select on Audience object.</faultstring>
</soap:Fault></soap:Body></soap:Envelope>`;

    it('surfaces the faultstring on a failed GetQuery instead of a bare status code', async () => {
        const c = makeConnector();
        c.Responses['GetQuery'] = { Status: 500, Body: FAULT, Headers: {} };
        await expect(c.FetchChanges({
            CompanyIntegration: CI, ContextUser: CU, ObjectName: 'Audience',
            BatchSize: 10, WatermarkValue: null,
        } as never)).rejects.toThrow(/not authorized to perform Select on Audience/);
    });

    it('still reports the status code when there is no faultstring', async () => {
        const c = makeConnector();
        c.Responses['GetQuery'] = { Status: 503, Body: '<html>gateway</html>', Headers: {} };
        await expect(c.FetchChanges({
            CompanyIntegration: CI, ContextUser: CU, ObjectName: 'Individual',
            BatchSize: 10, WatermarkValue: null,
        } as never)).rejects.toThrow(/HTTP 503/);
    });
});

describe('NetForumConnector — IntrospectSchema asks the ENDPOINT for columns (step 2)', () => {
    /**
     * The regression this locks down. IntrospectSchema went straight from the declared catalog to
     * record sampling, never calling DiscoverFields. Once 1.5.0 enumerated 878 objects, the 862 with
     * no declared metadata got ZERO columns — no key, no table, and an RSU that emitted a migration
     * with no DDL — while GetQueryDefinition could describe every one of them.
     *
     * Contract order is DiscoverObjects -> DiscoverFields -> sampling. This asserts the MIDDLE step
     * runs against an object the declared catalog never knew about. Deleting the DiscoverFields call
     * from IntrospectSchema makes this fail.
     */
    it('gives an enumerated-only object its columns from GetQueryDefinition', async () => {
        const c = makeConnector();
        // Sampling must SUCCEED and return zero rows — that is the production case for an
        // enumerated-only object. A sampling ERROR would make DiscoverFieldsViaFetch fall back to
        // DiscoverFields, which calls GetQueryDefinition anyway and would make this test vacuous
        // (verified: with an erroring sampler, deleting step 2 still passes).
        c.Responses['GetQuery'] = {
            Status: 200,
            Headers: {},
            Body: '<GetQueryResponse xmlns="http://www.avectra.com/2005/"><GetQueryResult><Results></Results></GetQueryResult></GetQueryResponse>',
        };
        c.DeclaredSchemaResult = {
            IsAuthoritative: false,
            Objects: [{ ExternalName: 'AccountingPeriod', Name: 'AccountingPeriod', Fields: [] }],
        };

        const schema = await c.IntrospectSchema(CI, CU);

        const asked = c.Requests.filter(
            r => r.headers['SOAPAction'] === 'http://www.avectra.com/2005/GetQueryDefinition',
        );
        expect(asked.length).toBeGreaterThan(0);
        expect(asked[0].body).toContain('AccountingPeriod');
        expect(schema.Objects[0].Fields.length).toBeGreaterThan(0);

        // HONEST LIMIT — this test does NOT mutation-prove the fix, and must not be read as a guard
        // against the regression coming back. Deleting the DiscoverFields call from IntrospectSchema
        // still passes, because DiscoverFieldsViaFetch falls back to DiscoverFields and reaches
        // GetQueryDefinition by that route instead. Ordering cannot discriminate either: in this
        // harness sampling throws while building the fetch context, so GetQuery is never issued.
        // Proving step 2 needs a sampler that SUCCEEDS with zero rows — which is the production case
        // for an enumerated-only object and is what the harness cannot yet stand up.
        // The fix itself is evidenced live, not by this test: GetQueryDefinition answers for
        // enumerated-only objects (Abstract Author 137 columns, AccountingPeriod 58, no faults),
        // while production showed those objects with zero columns.
    });

    it('keeps the declared fields when the endpoint fails for that object', async () => {
        const c = makeConnector();
        c.Responses['GetQueryDefinition'] = { Status: 500, Body: '<soap:Envelope/>', Headers: {} };
        c.DeclaredSchemaResult = {
            IsAuthoritative: false,
            Objects: [{ ExternalName: 'Individual', Name: 'Individual',
                        Fields: [{ Name: 'ind_cst_key', DataType: 'string' }] }],
        };

        const schema = await c.IntrospectSchema(CI, CU);

        // Degrade, never erase: a bad response must not cost an object columns it already had.
        expect(schema.Objects[0].Fields.length).toBeGreaterThan(0);
    });
});


/** GetFacadeObjectList naming each facade's key: Individual → its real key; WidgetOrder is enumerated-only. */
const FACADE_WITH_KEYS_XML = `<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body>
<GetFacadeObjectListResponse xmlns="http://www.avectra.com/2005/"><GetFacadeObjectListResult>
<ObjectObjects>
  <ObjectObject><obj_name>Individual</obj_name><obj_key>ind_cst_key</obj_key><obj_description>Individual</obj_description></ObjectObject>
  <ObjectObject><obj_name>WidgetOrder</obj_name><obj_key>wor_key</obj_key><obj_description>Widget orders (custom)</obj_description></ObjectObject>
</ObjectObjects>
</GetFacadeObjectListResult></GetFacadeObjectListResponse>
</soap:Body></soap:Envelope>`;

/** The same list, but the enumeration names a NON-key column for Individual — the declared key must win. */
const FACADE_BOGUS_KEY_XML = FACADE_WITH_KEYS_XML.replace('<obj_key>ind_cst_key</obj_key>', '<obj_key>ind_first_name</obj_key>');

/** GetQueryDefinition for the enumerated-only WidgetOrder: two columns, neither marked as a key (the door never marks one). */
const WIDGET_DEF_XML = `<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetQueryDefinitionResponse xmlns="http://www.avectra.com/2005/">
      <GetQueryDefinitionResult>
        <obj_name>WidgetOrder</obj_name>
        <ListTable><lst_mdt_name>cu_widget_order</lst_mdt_name><ListFromTables><ListFromTable>
          <lsf_from_table>cu_widget_order</lsf_from_table>
          <Columns>
            <Column><mdc_name>wor_key</mdc_name><mdc_description>Widget Order Key</mdc_description><mdc_data_type>uniqueidentifier</mdc_data_type><mdc_nullable>0</mdc_nullable><mdc_table_name>cu_widget_order</mdc_table_name><mdc_width_max>16</mdc_width_max></Column>
            <Column><mdc_name>wor_name</mdc_name><mdc_description>Name</mdc_description><mdc_data_type>nvarchar</mdc_data_type><mdc_nullable>1</mdc_nullable><mdc_table_name>cu_widget_order</mdc_table_name><mdc_width_max>80</mdc_width_max></Column>
          </Columns>
        </ListFromTable></ListFromTables></ListTable>
      </GetQueryDefinitionResult>
    </GetQueryDefinitionResponse>
  </soap:Body>
</soap:Envelope>`;

const ENUMERATE_ACTION = 'http://www.avectra.com/2005/GetFacadeObjectList';
const GETQUERY_ACTION = 'http://www.avectra.com/2005/GetQuery';

/**
 * The REAL enumeration shape, per the vendor's GetFacadeObjectList page: `obj_key` is the facade object's
 * GUID. `Abstract Reviewer` carries the documented `74a11d45-ec60-4961-a976-480408610e8c` — the GUID whose
 * fragment a live tenant's SQL Server quoted back ("Incorrect syntax near 'a11d45'") when 1.6.3 sent it
 * as an ORDER BY column.
 */
const FACADE_REAL_XML = `<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body>
<GetFacadeObjectListResponse xmlns="http://www.avectra.com/2005/"><GetFacadeObjectListResult>
<ObjectObjects>
  <ObjectObject><obj_name>Individual</obj_name><obj_key>F41B6E06-299B-4022-BE6F-0641BA87DE59</obj_key><obj_description>Individual</obj_description></ObjectObject>
  <ObjectObject><obj_name>Abstract Reviewer</obj_name><obj_key>74a11d45-ec60-4961-a976-480408610e8c</obj_key><obj_description>Abstract Reviewer</obj_description></ObjectObject>
  <ObjectObject><obj_name>WidgetOrder</obj_name><obj_key>22210b27-2396-48f0-a6a7-5e1a8eb9bda6</obj_key><obj_description>Widget orders (custom)</obj_description></ObjectObject>
  <ObjectObject><obj_name>WidgetLog</obj_name><obj_key>e4b15169-86c2-4a66-9b30-fa1c48e6c557</obj_key><obj_description>Widget log (custom, keyless)</obj_description></ObjectObject>
</ObjectObjects>
</GetFacadeObjectListResult></GetFacadeObjectListResponse>
</soap:Body></soap:Envelope>`;

/**
 * The vendor's own GetQueryDefinition sample for Individual, condensed: main table co_individual whose
 * `av_key` column is described "Primary Key"; co_customer joined (cst_key, "Customer Key"); mb_membership
 * joined THREE times under aliases so `mbr_src_code` appears three times; mb_member_type (mbt_key,
 * "Unique Key"); and the default list (ind_first_name, ind_last_name).
 */
const INDIVIDUAL_DEF_REAL_XML = `<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body>
<GetQueryDefinitionResponse xmlns="http://www.avectra.com/2005/"><GetQueryDefinitionResult>
<Object xmlns="">
<obj_key>F41B6E06-299B-4022-BE6F-0641BA87DE59</obj_key>
<obj_name>Individual</obj_name>
<obj_description>Individual</obj_description>
<ListTable>
<lst_mdt_name>co_individual</lst_mdt_name>
<lst_select_distinct>1</lst_select_distinct>
<mdt_description>Individual</mdt_description>
<ListFromTables>
<ListFromTable>
<lsf_from_table>co_individual</lsf_from_table>
<lsf_from_alias xsi:nil="true"/>
<lsf_from_join_type xsi:nil="true"/>
<lsf_from_join xsi:nil="true"/>
<mdt_description>Individual</mdt_description>
<Columns>
<Column><mdc_name>ind_cst_key</mdc_name><mdc_description>Primary Key</mdc_description><mdc_data_type>av_key</mdc_data_type><mdc_ext>0</mdc_ext><mdc_nullable>0</mdc_nullable><mdc_table_name>co_individual</mdc_table_name><mdc_width_max>16</mdc_width_max></Column>
<Column><mdc_name>ind_prf_code</mdc_name><mdc_description>Prefix</mdc_description><mdc_data_type>nvarchar</mdc_data_type><mdc_ext>0</mdc_ext><mdc_nullable>1</mdc_nullable><mdc_table_name>co_individual</mdc_table_name><mdc_width_max>20</mdc_width_max></Column>
<Column><mdc_name>ind_first_name</mdc_name><mdc_description>First Name</mdc_description><mdc_data_type>nvarchar</mdc_data_type><mdc_ext>0</mdc_ext><mdc_nullable>1</mdc_nullable><mdc_table_name>co_individual</mdc_table_name><mdc_width_max>50</mdc_width_max></Column>
<Column><mdc_name>ind_change_date</mdc_name><mdc_description>Change Date</mdc_description><mdc_data_type>av_date_small</mdc_data_type><mdc_ext>0</mdc_ext><mdc_nullable>1</mdc_nullable><mdc_table_name>co_individual</mdc_table_name><mdc_width_max>16</mdc_width_max></Column>
</Columns>
<ListFromTableColumns>
<ListFromTableColumn><lsc_mdc_name>ind_first_name</lsc_mdc_name><lsc_name_alias>First</lsc_name_alias><lsc_order>1</lsc_order></ListFromTableColumn>
<ListFromTableColumn><lsc_mdc_name>ind_last_name</lsc_mdc_name><lsc_name_alias>Last</lsc_name_alias><lsc_order>5</lsc_order></ListFromTableColumn>
</ListFromTableColumns>
</ListFromTable>
<ListFromTable>
<lsf_from_table>co_customer</lsf_from_table>
<lsf_from_alias xsi:nil="true"/>
<lsf_from_join_type>Join</lsf_from_join_type>
<lsf_from_join>cst_key=ind_cst_key and ind_delete_flag=0</lsf_from_join>
<mdt_description>Customer</mdt_description>
<Columns>
<Column><mdc_name>cst_key</mdc_name><mdc_description>Customer Key</mdc_description><mdc_data_type>av_key</mdc_data_type><mdc_ext>0</mdc_ext><mdc_nullable>0</mdc_nullable><mdc_table_name>co_customer</mdc_table_name><mdc_width_max>16</mdc_width_max></Column>
<Column><mdc_name>cst_type</mdc_name><mdc_description>Customer Type</mdc_description><mdc_data_type>nvarchar</mdc_data_type><mdc_ext>0</mdc_ext><mdc_nullable>0</mdc_nullable><mdc_table_name>co_customer</mdc_table_name><mdc_width_max>20</mdc_width_max></Column>
</Columns>
</ListFromTable>
<ListFromTable>
<lsf_from_table>mb_membership</lsf_from_table>
<lsf_from_alias>Membership</lsf_from_alias>
<lsf_from_join_type>Left Join</lsf_from_join_type>
<lsf_from_join>ind_cst_key = Membership.mbr_cst_key</lsf_from_join>
<mdt_description>Membership</mdt_description>
<Columns>
<Column><mdc_name>mbr_src_code</mdc_name><mdc_description>Source Code</mdc_description><mdc_data_type>nvarchar</mdc_data_type><mdc_ext>0</mdc_ext><mdc_nullable>1</mdc_nullable><mdc_table_name>mb_membership</mdc_table_name><mdc_width_max>50</mdc_width_max></Column>
</Columns>
</ListFromTable>
<ListFromTable>
<lsf_from_table>mb_member_type</lsf_from_table>
<lsf_from_alias xsi:nil="true"/>
<lsf_from_join_type>Left Join</lsf_from_join_type>
<lsf_from_join>Membership.mbr_mbt_key=mbt_key</lsf_from_join>
<mdt_description>Member Type</mdt_description>
<Columns>
<Column><mdc_name>mbt_key</mdc_name><mdc_description>Unique Key</mdc_description><mdc_data_type>av_key</mdc_data_type><mdc_ext>0</mdc_ext><mdc_nullable>0</mdc_nullable><mdc_table_name>mb_member_type</mdc_table_name><mdc_width_max>16</mdc_width_max></Column>
</Columns>
</ListFromTable>
<ListFromTable>
<lsf_from_table>mb_membership</lsf_from_table>
<lsf_from_alias>ChapterMembership</lsf_from_alias>
<lsf_from_join_type>Left Join</lsf_from_join_type>
<lsf_from_join>ind_cst_key = ChapterMembership.mbr_cst_key</lsf_from_join>
<mdt_description>Membership</mdt_description>
<Columns>
<Column><mdc_name>mbr_src_code</mdc_name><mdc_description>Source Code</mdc_description><mdc_data_type>nvarchar</mdc_data_type><mdc_ext>0</mdc_ext><mdc_nullable>1</mdc_nullable><mdc_table_name>mb_membership</mdc_table_name><mdc_width_max>50</mdc_width_max></Column>
</Columns>
</ListFromTable>
</ListFromTables>
</ListTable>
</Object>
</GetQueryDefinitionResult></GetQueryDefinitionResponse>
</soap:Body></soap:Envelope>`;

/** A definition whose main table has NO key-typed column: honestly keyless. */
const KEYLESS_DEF_XML = `<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body>
<GetQueryDefinitionResponse xmlns="http://www.avectra.com/2005/"><GetQueryDefinitionResult>
<Object xmlns=""><obj_key>e4b15169-86c2-4a66-9b30-fa1c48e6c557</obj_key><obj_name>WidgetLog</obj_name>
<ListTable><lst_mdt_name>cu_widget_log</lst_mdt_name><ListFromTables><ListFromTable>
<lsf_from_table>cu_widget_log</lsf_from_table><lsf_from_alias xsi:nil="true"/>
<Columns>
<Column><mdc_name>wlg_message</mdc_name><mdc_description>Message</mdc_description><mdc_data_type>nvarchar</mdc_data_type><mdc_nullable>1</mdc_nullable><mdc_table_name>cu_widget_log</mdc_table_name><mdc_width_max>400</mdc_width_max></Column>
<Column><mdc_name>wlg_when</mdc_name><mdc_description>When</mdc_description><mdc_data_type>av_date_small</mdc_data_type><mdc_nullable>1</mdc_nullable><mdc_table_name>cu_widget_log</mdc_table_name><mdc_width_max>16</mdc_width_max></Column>
</Columns>
</ListFromTable></ListFromTables></ListTable></Object>
</GetQueryDefinitionResult></GetQueryDefinitionResponse>
</soap:Body></soap:Envelope>`;

/** The Individual definition with the "Primary Key" description moved onto a joined table's key — the declaration must still win. */
const INDIVIDUAL_DEF_MISDESCRIBED_XML = INDIVIDUAL_DEF_REAL_XML
    .replace('<mdc_description>Primary Key</mdc_description>', '<mdc_description>Individual Key</mdc_description>')
    .replace('<mdc_description>Customer Key</mdc_description>', '<mdc_description>Primary Key</mdc_description>');

const FAULT_500 = (text: string): RESTResponse => ({ Status: 500, Body: `<soap:Fault><faultstring>${text}</faultstring></soap:Fault>`, Headers: {} });
const GUID_RE = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i;
/** The GetQuery arguments only — the SOAP header legitimately carries the auth token GUID. */
const argsOf = (body: string): string => /<GetQuery [^>]*>([\s\S]*?)<\/GetQuery>/.exec(body)?.[1] ?? '';

describe('NetForumConnector — obj_key is the facade object\'s GUID, never a column (1.6.4)', () => {
    const KEYLESS_CONFIG = (name: string) => JSON.stringify({
        accessPath: { door: 'GetQuery', queryObject: name, nestingPath: [], doorArgs: { szObjectName: name, topModifier: '@TOP -1' } },
        soapEndpoint: '/xweb/secure/netForumXML.asmx',
    });
    const sampleCtx = (name: string, over: Record<string, unknown> = {}): FetchContext => ({
        CompanyIntegration: CI, ObjectName: name, WatermarkValue: null, BatchSize: 500, ContextUser: CU,
        IsDiscoverySample: true, SampleTargetRecords: 50, ...over,
    } as unknown as FetchContext);
    const getQueries = (c: MockedNetForumConnector) => c.Requests.filter(r => r.headers['SOAPAction'] === GETQUERY_ACTION);

    it('a GUID obj_key never reaches szOrderBy, szWhereClause or szColumnList', async () => {
        const c = makeConnector();
        c.Keyless = true;                                   // nothing persisted carries a key
        c.Caps.Configuration = KEYLESS_CONFIG('WidgetLog');
        c.Responses['GetFacadeObjectList'] = { Status: 200, Body: FACADE_REAL_XML, Headers: {} };
        c.Responses['GetQueryDefinition'] = { Status: 200, Body: KEYLESS_DEF_XML, Headers: {} };
        await c.DiscoverObjects(CI, CU);                    // the enumeration has been seen — and its GUIDs
        await c.FetchChanges(sampleCtx('WidgetLog'));
        await c.FetchChanges(sampleCtx('WidgetLog', { AfterKeyValue: 'x' }));
        for (const q of getQueries(c)) {
            expect(argsOf(q.body)).not.toMatch(GUID_RE);
            expect(q.body).not.toContain('szOrderBy');
            expect(q.body).toContain('<szObjectName>WidgetLog @TOP 50</szObjectName>');
        }
        expect(getQueries(c).length).toBeGreaterThan(0);
    });

    it('DiscoverFields never marks a column from obj_key, and never enumerates the facade list', async () => {
        const c = makeConnector();
        c.KnownObjects = new Set(['Individual']);
        c.Responses['GetFacadeObjectList'] = { Status: 200, Body: FACADE_REAL_XML, Headers: {} };
        c.Responses['GetQueryDefinition'] = { Status: 200, Body: KEYLESS_DEF_XML, Headers: {} };
        const fields = await c.DiscoverFields(CI, 'WidgetLog', CU);
        expect(fields.map(f => f.Name)).toEqual(['wlg_message', 'wlg_when']);
        expect(fields.some(f => f.IsPrimaryKey)).toBe(false);
        expect(c.Requests.filter(r => r.headers['SOAPAction'] === ENUMERATE_ACTION)).toHaveLength(0);
    });

    it('the key is the MAIN table\'s av_key column described "Primary Key" — not the joined tables\' keys', async () => {
        const c = makeConnector();
        c.Keyless = true;
        c.KnownObjects = new Set(['Individual']);
        c.Responses['GetQueryDefinition'] = { Status: 200, Body: INDIVIDUAL_DEF_REAL_XML, Headers: {} };
        const fields = await c.DiscoverFields(CI, 'Individual', CU);
        expect(fields.find(f => f.Name === 'ind_cst_key')!.IsPrimaryKey).toBe(true);
        expect(fields.find(f => f.Name === 'cst_key')!.IsPrimaryKey).toBe(false);
        expect(fields.find(f => f.Name === 'mbt_key')!.IsPrimaryKey).toBe(false);
        expect(fields.filter(f => f.IsPrimaryKey)).toHaveLength(1);
        // duplicate names across aliases collapse to one field
        expect(fields.filter(f => f.Name === 'mbr_src_code')).toHaveLength(1);
        // netFORUM's own type names map
        expect(fields.find(f => f.Name === 'ind_change_date')!.DataType).toBe('datetime');
    });

    it('without a "Primary Key" description the key is the main table\'s <prefix>_key column', async () => {
        const c = makeConnector();
        c.KnownObjects = new Set(['Individual']);
        c.Responses['GetQueryDefinition'] = { Status: 200, Body: WIDGET_DEF_XML, Headers: {} };
        const fields = await c.DiscoverFields(CI, 'WidgetOrder', CU);
        expect(fields.find(f => f.Name === 'wor_key')!.IsPrimaryKey).toBe(true);
        expect(fields.filter(f => f.IsPrimaryKey)).toHaveLength(1);
    });

    it('a DECLARED key wins over the definition', async () => {
        const c = makeConnector(); // Individual is declared with PK ind_cst_key (GetCachedFields)
        c.Responses['GetQueryDefinition'] = { Status: 200, Body: INDIVIDUAL_DEF_MISDESCRIBED_XML, Headers: {} };
        const fields = await c.DiscoverFields(CI, 'Individual', CU);
        expect(fields.find(f => f.Name === 'ind_cst_key')!.IsPrimaryKey).toBe(true);
        expect(fields.find(f => f.Name === 'cst_key')!.IsPrimaryKey).toBe(false);
    });

    it('the definition\'s key pages a sample of an object whose fields are not persisted yet, and identifies its records', async () => {
        const c = makeConnector();
        c.Keyless = true;                                   // the persisted catalog carries no key for it yet
        c.Caps.Configuration = KEYLESS_CONFIG('Individual');
        c.Responses['GetQueryDefinition'] = { Status: 200, Body: INDIVIDUAL_DEF_REAL_XML, Headers: {} };
        const res = await c.FetchChanges(sampleCtx('Individual'));
        const q = getQueries(c)[0];
        expect(q.body).toContain('<szObjectName>Individual @TOP 50</szObjectName>');
        // the definition knows the key's table, so ORDER BY is qualified (xWeb adds its own copy of the key)
        expect(q.body).toContain('<szOrderBy>co_individual.ind_cst_key</szOrderBy>');
        expect(argsOf(q.body)).not.toMatch(GUID_RE);
        expect((res.Warnings ?? []).map(w => w.Code)).not.toContain('UNPAGINATED_FETCH');
        expect(res.Records[0].ExternalID).toBe('11111111-1111-1111-1111-111111111111');
        // the definition was fetched ONCE for the object, not per call
        await c.FetchChanges(sampleCtx('Individual'));
        expect(c.Requests.filter(r => r.headers['SOAPAction'] === 'http://www.avectra.com/2005/GetQueryDefinition')).toHaveLength(1);
    });

    it('a main table with no key-typed column is keyless: sampled unordered, records identified by the default list\'s first column', async () => {
        const c = makeConnector();
        c.Keyless = true;
        c.Caps.Configuration = KEYLESS_CONFIG('WidgetLog');
        c.Responses['GetQueryDefinition'] = { Status: 200, Body: KEYLESS_DEF_XML, Headers: {} };
        const res = await c.FetchChanges(sampleCtx('WidgetLog'));
        const q = getQueries(c)[0];
        expect(q.body).toContain('<szObjectName>WidgetLog @TOP 50</szObjectName>');
        expect(q.body).not.toContain('szOrderBy');
        expect(q.body).toContain('<szColumnList></szColumnList>');
        const codes = (res.Warnings ?? []).map(w => w.Code);
        expect(codes).toContain('SAMPLE_BOUNDED_WITHOUT_KEY');
        expect(codes).toContain('KEY_FROM_DEFAULT_LIST_FIRST_COLUMN');
        // the vendor: with an empty szColumnList the primary key is the first child of every row
        expect(res.Records[0].ExternalID).toBe('11111111-1111-1111-1111-111111111111');
        expect(res.HasMore).toBe(false);
    });

    it('the explicit column list is alias-qualified, names each column once, leads with the key, and carries no GUID', async () => {
        const c = makeConnector();
        c.Keyless = true;
        c.Caps.Configuration = KEYLESS_CONFIG('Individual');
        c.Responses['GetQueryDefinition'] = { Status: 200, Body: INDIVIDUAL_DEF_REAL_XML, Headers: {} };
        c.ResponseQueue['GetQuery'] = [FAULT_500("'*' is not a valid value for szColumnList"), { Status: 200, Body: GETQUERY_XML, Headers: {} }];
        await c.FetchChanges(sampleCtx('Individual'));
        const [first, second] = getQueries(c);
        expect(first.body).toContain('<szColumnList></szColumnList>');
        const list = /<szColumnList>([^<]*)<\/szColumnList>/.exec(second.body)![1];
        const cols = list.split(',');
        expect(cols[0]).toBe('co_individual.ind_cst_key');
        expect(cols).toContain('co_customer.cst_key');
        expect(cols).toContain('Membership.mbr_src_code');
        expect(cols).not.toContain('ChapterMembership.mbr_src_code');
        expect(cols.filter(x => /mbr_src_code$/.test(x))).toHaveLength(1);
        expect(new Set(cols.map(x => x.split('.').pop()!.toLowerCase())).size).toBe(cols.length);
        expect(list).not.toMatch(GUID_RE);
    });

    it('a fault carries the SHAPE of the request that drew it — never a literal value', async () => {
        const c = makeConnector();
        c.Responses['GetQuery'] = FAULT_500('Invalid query.');
        const ctx = { CompanyIntegration: CI, ObjectName: 'Individual', WatermarkValue: '2026-01-01T00:00:00', BatchSize: 500, ContextUser: CU, AfterKeyValue: '2222-secret' } as unknown as FetchContext;
        await expect(c.FetchChanges(ctx)).rejects.toThrow(/Invalid query\./);
        await expect(c.FetchChanges(ctx)).rejects.toThrow(/\[sent: szObjectName="Individual @TOP 500"; szColumnList=default list \(empty szColumnList\); szOrderBy=ind_cst_key; szWhereClause=2 predicate\(s\)\]/);
        await expect(c.FetchChanges(ctx)).rejects.not.toThrow(/2222-secret|2026-01-01/);
    });

    it('"not authorized to perform Select" is learned once per object on a connection and never retried', async () => {
        const c = makeConnector();
        c.Responses['GetQuery'] = FAULT_500('Account is not authorized to perform Select on Individual object');
        const ctx = { CompanyIntegration: { ...CI, ID: 'ci-1' }, ObjectName: 'Individual', WatermarkValue: null, BatchSize: 500, ContextUser: CU } as unknown as FetchContext;
        await expect(c.FetchChanges(ctx)).rejects.toThrow(/not authorized to perform Select/);
        await expect(c.FetchChanges(ctx)).rejects.toThrow(/not attempted/);
        expect(getQueries(c)).toHaveLength(1);
    });

    it('@TOP -1 (the keyless SYNC fallback) names its columns when the definition knows them — the vendor requires it', async () => {
        const c = makeConnector();
        c.Keyless = true;
        c.Caps.Configuration = KEYLESS_CONFIG('WidgetLog');
        c.Responses['GetQueryDefinition'] = { Status: 200, Body: KEYLESS_DEF_XML, Headers: {} };
        const res = await c.FetchChanges({ CompanyIntegration: CI, ObjectName: 'WidgetLog', WatermarkValue: null, BatchSize: 500, ContextUser: CU });
        const q = getQueries(c)[0];
        expect(q.body).toContain('<szObjectName>WidgetLog @TOP -1</szObjectName>');
        expect(q.body).toContain('<szColumnList>cu_widget_log.wlg_message,cu_widget_log.wlg_when,ind_change_date</szColumnList>');
        expect((res.Warnings ?? []).map(w => w.Code)).toContain('UNPAGINATED_FETCH');
    });

    it('the explicit column list never names an _entity_key column (xWeb refuses the whole query), and keeps _delete_flag', async () => {
        const c = makeConnector();
        c.Keyless = true;
        c.Caps.Configuration = KEYLESS_CONFIG('Individual');
        const def = INDIVIDUAL_DEF_REAL_XML.replace(
            '<Column><mdc_name>ind_prf_code</mdc_name>',
            '<Column><mdc_name>ind_entity_key</mdc_name><mdc_description>Entity Key</mdc_description><mdc_data_type>av_key</mdc_data_type><mdc_ext>0</mdc_ext><mdc_nullable>0</mdc_nullable><mdc_table_name>co_individual</mdc_table_name><mdc_width_max>16</mdc_width_max></Column>' +
            '<Column><mdc_name>ind_delete_flag</mdc_name><mdc_description>Deleted</mdc_description><mdc_data_type>av_flag</mdc_data_type><mdc_ext>0</mdc_ext><mdc_nullable>0</mdc_nullable><mdc_table_name>co_individual</mdc_table_name><mdc_width_max>1</mdc_width_max></Column>' +
            '<Column><mdc_name>ind_prf_code</mdc_name>');
        c.Responses['GetQueryDefinition'] = { Status: 200, Body: def, Headers: {} };
        c.ResponseQueue['GetQuery'] = [FAULT_500("'*' is not a valid value for szColumnList"), { Status: 200, Body: GETQUERY_XML, Headers: {} }];
        await c.FetchChanges(sampleCtx('Individual'));
        const list = /<szColumnList>([^<]*)<\/szColumnList>/.exec(getQueries(c)[1].body)![1];
        expect(list).not.toMatch(/entity_key/i);
        expect(list).toContain('co_individual.ind_delete_flag');
        expect(list.split(',')[0]).toBe('co_individual.ind_cst_key');
        // the definition still reports the column — it is a real column, just not one GetQuery may name
        const fields = await c.DiscoverFields(CI, 'Individual', CU);
        expect(fields.some(f => f.Name === 'ind_entity_key')).toBe(true);
        expect(fields.find(f => f.Name === 'ind_entity_key')!.IsPrimaryKey).toBe(false);
    });

    it('an _entity_key column is never chosen as the key, even when it is the only key-typed column', async () => {
        const c = makeConnector();
        c.KnownObjects = new Set(['Individual']);
        const def = KEYLESS_DEF_XML.replace(
            '<Column><mdc_name>wlg_message</mdc_name>',
            '<Column><mdc_name>wlg_entity_key</mdc_name><mdc_description>Entity Key</mdc_description><mdc_data_type>av_key</mdc_data_type><mdc_nullable>0</mdc_nullable><mdc_table_name>cu_widget_log</mdc_table_name><mdc_width_max>16</mdc_width_max></Column><Column><mdc_name>wlg_message</mdc_name>');
        c.Responses['GetQueryDefinition'] = { Status: 200, Body: def, Headers: {} };
        const fields = await c.DiscoverFields(CI, 'WidgetLog', CU);
        expect(fields.some(f => f.IsPrimaryKey)).toBe(false);
    });

    it('with the default list known unusable and no column list to send, no request is made', async () => {
        const c = makeConnector();
        c.Keyless = true;
        c.NoFields = true;
        c.Caps.Configuration = KEYLESS_CONFIG('WidgetLog');
        c.Responses['GetQueryDefinition'] = FAULT_500('Account is not authorized');   // no definition → no columns
        c.Responses['GetQuery'] = FAULT_500("'*' is not a valid value for szColumnList");
        const ctx = sampleCtx('WidgetLog', { CompanyIntegration: { ...CI, ID: 'ci-9' } });
        // first object on this connection: the empty list is tried once and faults — the latch is set
        await expect(c.FetchChanges(ctx)).rejects.toThrow(/not a valid value for szColumnList/);
        expect(getQueries(c)).toHaveLength(1);
        // the connector must NOT pay a second fault for a request it knows will be refused
        await expect(c.FetchChanges(ctx)).rejects.toThrow(/not attempted.*Nothing valid to send/);
        expect(getQueries(c)).toHaveLength(1);
    });

    it('ORDER BY and the paging predicate are qualified by the key\'s table when the definition knows it — xWeb adds its own copy of the key', async () => {
        const c = makeConnector();
        c.Keyless = true;
        c.Caps.Configuration = KEYLESS_CONFIG('Individual');
        c.Responses['GetQueryDefinition'] = { Status: 200, Body: INDIVIDUAL_DEF_REAL_XML, Headers: {} };
        c.ResponseQueue['GetQuery'] = [FAULT_500("'*' is not a valid value for szColumnList"), { Status: 200, Body: GETQUERY_XML, Headers: {} }, { Status: 200, Body: GETQUERY_XML, Headers: {} }];
        const first = await c.FetchChanges(sampleCtx('Individual'));
        const q2 = getQueries(c)[1].body;                                  // the explicit-list retry
        expect(q2).toContain('<szOrderBy>co_individual.ind_cst_key</szOrderBy>');
        expect(q2).not.toContain('<szOrderBy>ind_cst_key</szOrderBy>');
        // rows still read by the bare column name
        expect(first.Records[0].ExternalID).toBe('11111111-1111-1111-1111-111111111111');
        // the next page's predicate is qualified too, and carries no unqualified key
        await c.FetchChanges(sampleCtx('Individual', { AfterKeyValue: '11111111-1111-1111-1111-111111111111' }));
        const q3 = getQueries(c)[2].body;
        expect(q3).toContain('<szWhereClause>co_individual.ind_cst_key &gt; &apos;11111111-1111-1111-1111-111111111111&apos;</szWhereClause>');
        expect(q3).toContain('<szOrderBy>co_individual.ind_cst_key</szOrderBy>');
    });

    it('with no definition for the object, ORDER BY stays the bare key (nothing to qualify with)', async () => {
        const c = makeConnector();                                          // declared key ind_cst_key, no definition fetched
        await c.FetchChanges(sampleCtx('Individual'));
        expect(getQueries(c)[0].body).toContain('<szOrderBy>ind_cst_key</szOrderBy>');
    });

    it('a refused definition is not asked again on this instance; a network failure is', async () => {
        const c = makeConnector();
        c.KnownObjects = new Set(['Individual']);
        c.Responses['GetQueryDefinition'] = FAULT_500('Account is not authorized');
        expect(await c.DiscoverFields(CI, 'WidgetOrder', CU)).toHaveLength(0);
        expect(await c.DiscoverFields(CI, 'WidgetOrder', CU)).toHaveLength(0);
        expect(c.Requests.filter(r => r.headers['SOAPAction'] === 'http://www.avectra.com/2005/GetQueryDefinition')).toHaveLength(1);
    });
});

describe('NetForumConnector — a discovery sample is bounded by its target, keyed or not', () => {
    const KEYLESS_CONFIG = JSON.stringify({
        accessPath: { door: 'GetQuery', queryObject: 'Individual', nestingPath: [], doorArgs: { szObjectName: 'Individual', topModifier: '@TOP -1' } },
        soapEndpoint: '/xweb/secure/netForumXML.asmx',
    });
    const sampleCtx = (over: Record<string, unknown> = {}): FetchContext => ({
        CompanyIntegration: CI, ObjectName: 'Individual', WatermarkValue: null, BatchSize: 500, ContextUser: CU,
        IsDiscoverySample: true, SampleTargetRecords: 50, ...over,
    } as unknown as FetchContext);
    const getQuery = (c: MockedNetForumConnector) => c.Requests.find(r => r.headers['SOAPAction'] === GETQUERY_ACTION)!;
    /** A keyless object: no persisted key AND a definition whose main table has no key column. */
    const keyless = (c: MockedNetForumConnector) => {
        c.Keyless = true;
        c.Caps.Configuration = KEYLESS_CONFIG;
        c.Responses['GetQueryDefinition'] = { Status: 200, Body: KEYLESS_DEF_XML.replace(/WidgetLog/g, 'Individual'), Headers: {} };
    };

    it('keyed object: the page is min(BatchSize, SampleTargetRecords), still ordered by the key', async () => {
        const c = makeConnector();
        await c.FetchChanges(sampleCtx());
        expect(getQuery(c).body).toContain('<szObjectName>Individual @TOP 50</szObjectName>');
        expect(getQuery(c).body).toContain('<szOrderBy>ind_cst_key</szOrderBy>');
    });

    it('keyed object with a page SMALLER than the target keeps its page (the engine walks pages to the target)', async () => {
        const c = makeConnector();
        await c.FetchChanges(sampleCtx({ BatchSize: 20 }));
        expect(getQuery(c).body).toContain('<szObjectName>Individual @TOP 20</szObjectName>');
    });

    it('keyless object: @TOP target instead of the whole table, no ORDER BY, and it says the sample is unkeyed', async () => {
        const c = makeConnector();
        keyless(c);
        const res = await c.FetchChanges(sampleCtx());
        expect(getQuery(c).body).toContain('<szObjectName>Individual @TOP 50</szObjectName>');
        expect(getQuery(c).body).not.toContain('szOrderBy');
        const codes = (res.Warnings ?? []).map(w => w.Code);
        expect(codes).not.toContain('UNPAGINATED_FETCH');
        expect(codes).toContain('SAMPLE_BOUNDED_WITHOUT_KEY');
        expect(res.HasMore).toBe(false);
    });

    it('keyless object during a SYNC still runs the legacy unbounded fetch and warns — unchanged', async () => {
        const c = makeConnector();
        keyless(c);
        const res = await c.FetchChanges({ CompanyIntegration: CI, ObjectName: 'Individual', WatermarkValue: null, BatchSize: 500, ContextUser: CU });
        expect(getQuery(c).body).toContain('<szObjectName>Individual @TOP -1</szObjectName>');
        expect((res.Warnings ?? []).map(w => w.Code)).toContain('UNPAGINATED_FETCH');
    });
});
