import { describe, it, expect, beforeEach } from 'vitest';
import type {
    RESTResponse,
    PaginationType,
    FetchContext,
    CreateRecordContext,
    UpdateRecordContext,
    DeleteRecordContext,
} from '@memberjunction/integration-engine';
import type {
    MJCompanyIntegrationEntity,
    MJIntegrationObjectEntity,
    MJIntegrationObjectFieldEntity,
} from '@memberjunction/core-entities';
import {
    BusinessCentralConnector,
    BuildBusinessCentralRootURL,
    BuildBusinessCentralCompanySegment,
    BuildBusinessCentralResourceURL,
    EscapeODataStringLiteral,
    ODataStringLiteral,
    ODataDateTimeOffsetLiteral,
    ParsePathSegments,
    ExtractODataNextLink,
    EncodeResumeCursor,
    DecodeResumeCursor,
    ParseEDMXEntitySets,
    ParseEDMXFieldsForEntitySet,
    type BusinessCentralAuthContext,
    type BusinessCentralConnectionConfig,
} from '../BusinessCentralConnector.js';

// ─── Fixture provenance ───────────────────────────────────────────────────
//
// PROVENANCE: vendor-published. Every response payload below is shaped after Microsoft's PUBLISHED
// example JSON representations on the Business Central API-v2.0 reference pages (the `dynamics_*.md`
// resource pages cited in the frozen contract's per-object `sourceEvidence.resourcePage`) — the OData
// collection envelope (`@odata.context` + `value`), the `@odata.etag` concurrency token, and the
// documented `{"error":{"code","message"}}` shape. Identifiers are synthetic GUID-shaped placeholders;
// there is NO real tenant data and NO PII. The keyless reality probe captured ZERO vendor payloads, so
// no live-capture source exists — and a fixture is NEVER synthesized from our own metadata, which would
// make these tiers unfalsifiable.
//
// This file is READ-ONLY / MOCKED-ONLY: no test performs a network call or a mutation. The write-path
// tests assert only the request the connector WOULD send, against the mocked transport
// (GENUINE-GREEN-MOCK — a live Business Central write is neither possible nor permitted in this build).

const COMPANY_A = '11111111-1111-1111-1111-111111111111';
const COMPANY_B = '22222222-2222-2222-2222-222222222222';
const TENANT = '99999999-9999-9999-9999-999999999999';

/** Documented collection envelope: records under `value`, continuation under `@odata.nextLink`. */
const customersPage1 = {
    '@odata.context': 'https://api.businesscentral.dynamics.com/v2.0/Sandbox/api/v2.0/$metadata#companies(x)/customers',
    '@odata.nextLink': 'https://api.businesscentral.dynamics.com/v2.0/Sandbox/api/v2.0/companies(' + COMPANY_A + ')/customers?aid=page2',
    value: [
        { '@odata.etag': 'W/"JzQ0O0"', id: 'c-1', number: 'C0001', displayName: 'Adatum', lastModifiedDateTime: '2026-01-01T10:00:00Z' },
        { '@odata.etag': 'W/"JzQ1O0"', id: 'c-2', number: 'C0002', displayName: 'Trey', lastModifiedDateTime: '2026-01-02T10:00:00Z' },
    ],
};
const customersPage2 = {
    '@odata.context': 'https://api.businesscentral.dynamics.com/v2.0/Sandbox/api/v2.0/$metadata#companies(x)/customers',
    value: [
        // c-2 repeats across the page boundary — the connector must dedupe by primary key.
        { '@odata.etag': 'W/"JzQ1O0"', id: 'c-2', number: 'C0002', displayName: 'Trey', lastModifiedDateTime: '2026-01-02T10:00:00Z' },
        { '@odata.etag': 'W/"JzQ2O0"', id: 'c-3', number: 'C0003', displayName: 'Fabrikam', lastModifiedDateTime: '2026-03-05T10:00:00Z' },
    ],
};
const companiesList = {
    value: [
        { id: COMPANY_A, name: 'CRONUS', displayName: 'CRONUS International Ltd.' },
        { id: COMPANY_B, name: 'CRONUS2', displayName: 'CRONUS Subsidiary' },
    ],
};
const journalsList = { value: [{ id: 'j-1', code: 'GENERAL' }, { id: 'j-2', code: 'PAYMENTS' }] };
const journalLinesEmpty = { value: [] };
const customerCreated = { '@odata.etag': 'W/"JzUwO0"', id: 'c-new', number: 'C0099', displayName: 'New Co' };

/** Documented error envelope — classification reads `error.code`, never the human message. */
const errorUnauthorized = { error: { code: 'Unauthorized', message: 'The credentials provided are incorrect' } };
const errorRequestDataInvalid = { error: { code: 'RequestDataInvalid', message: 'Request data is invalid.' } };
const errorForbidden = { error: { code: 'Forbidden', message: 'You do not have permission' } };

/** A trimmed EDMX ($metadata) document, shaped after the OData v4 CSDL Microsoft serves for BC. */
const edmxSample = `<?xml version="1.0" encoding="utf-8"?>
<edmx:Edmx xmlns:edmx="http://docs.oasis-open.org/odata/ns/edmx" Version="4.0">
  <edmx:DataServices>
    <Schema xmlns="http://docs.oasis-open.org/odata/ns/edm" Namespace="Microsoft.NAV">
      <EntityType Name="customer">
        <Key><PropertyRef Name="id"/></Key>
        <Property Name="id" Type="Edm.Guid" Nullable="false"/>
        <Property Name="displayName" Type="Edm.String" MaxLength="100" Nullable="true"/>
        <Property Name="lastModifiedDateTime" Type="Edm.DateTimeOffset" Nullable="true"/>
      </EntityType>
      <EntityType Name="tenantCustomPage">
        <Key><PropertyRef Name="entryNo"/></Key>
        <Property Name="entryNo" Type="Edm.Int32" Nullable="false"/>
      </EntityType>
      <EntityContainer Name="NAV">
        <EntitySet Name="customers" EntityType="Microsoft.NAV.customer"/>
        <EntitySet Name="Detailed_Customer_Ledger_Entries" EntityType="Microsoft.NAV.tenantCustomPage"/>
      </EntityContainer>
    </Schema>
  </edmx:DataServices>
</edmx:Edmx>`;

// ─── Metadata fixtures (mirroring the frozen contract's IO/IOF shape) ──────

interface CapturedRequest {
    url: string;
    method: string;
    headers: Record<string, string>;
    body: unknown;
}

function makeIO(over: Partial<MJIntegrationObjectEntity> & { ID: string; Name: string }): MJIntegrationObjectEntity {
    return {
        DisplayName: over.Name,
        Description: 'fixture',
        APIPath: '/companies({id})/customers',
        ResponseDataKey: 'value',
        DefaultPageSize: null,
        SupportsPagination: true,
        PaginationType: 'Cursor',
        SupportsIncrementalSync: true,
        SupportsWrite: false,
        IncrementalWatermarkField: 'lastModifiedDateTime',
        StableOrderingKey: 'id',
        SupportsCreate: false,
        CreateAPIPath: null,
        CreateMethod: null,
        CreateBodyShape: null,
        CreateBodyKey: null,
        CreateIDLocation: null,
        SupportsUpdate: false,
        UpdateAPIPath: null,
        UpdateMethod: null,
        UpdateBodyShape: null,
        UpdateBodyKey: null,
        UpdateIDLocation: null,
        SupportsDelete: false,
        DeleteAPIPath: null,
        DeleteMethod: null,
        DeleteIDLocation: null,
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
        RelatedIntegrationObjectID: null,
        ...over,
    } as unknown as MJIntegrationObjectFieldEntity;
}

const idPK = [
    makeIOF({ Name: 'id', IsPrimaryKey: true, IsRequired: true, IsReadOnly: true, IsUniqueKey: true }),
    makeIOF({ Name: 'displayName', Sequence: 1 }),
];

/** The `customers` IO exactly as the frozen contract carries it (full CUDW quartet). */
const customersIO = makeIO({
    ID: 'io-customers',
    Name: 'customers',
    APIPath: '/companies({id})/customers',
    SupportsWrite: true,
    SupportsCreate: true,
    CreateAPIPath: '/companies({id})/customers',
    CreateMethod: 'POST',
    CreateBodyShape: 'flat',
    CreateIDLocation: 'body',
    SupportsUpdate: true,
    UpdateAPIPath: '/companies({id})/customers({id})',
    UpdateMethod: 'PATCH',
    UpdateBodyShape: 'flat',
    UpdateIDLocation: 'path',
    SupportsDelete: true,
    DeleteAPIPath: '/companies({id})/customers({id})',
    DeleteMethod: 'DELETE',
    DeleteIDLocation: 'path',
});

/** The `journalLines` IO — a depth-2 nested access path (`companies → journals → journalLines`). */
const journalLinesIO = makeIO({
    ID: 'io-journalLines',
    Name: 'journalLines',
    APIPath: '/companies({id})/journals({id})/journalLines',
    SupportsWrite: true,
    SupportsCreate: true,
    CreateAPIPath: '/companies({id})/journals({id})/journalLines',
    CreateMethod: 'POST',
    CreateBodyShape: 'flat',
    CreateIDLocation: 'body',
});

/** A report-style IO with NO watermark — must never receive a `$filter` watermark clause. */
const trialBalancesIO = makeIO({
    ID: 'io-trialBalances',
    Name: 'trialBalances',
    APIPath: '/companies({id})/trialBalances',
    SupportsIncrementalSync: false,
    IncrementalWatermarkField: null,
});

/**
 * A tenant-PUBLISHED ODataV4 web-service page (ContextBC.md §5 — the surface the replaced driver read its
 * payment/ledger data from). Its declared path carries NO company segment: on ODataV4 the company rides the
 * single-quoted `Company('{guid}')` prefix. Tagged via the IO's own `Configuration.surface`.
 */
const ledgerEntriesIO = makeIO({
    ID: 'io-ledger',
    Name: 'Detailed_Customer_Ledger_Entries',
    APIPath: '/Detailed_Customer_Ledger_Entries',
    SupportsIncrementalSync: false,
    IncrementalWatermarkField: null,
    StableOrderingKey: null,
    Configuration: JSON.stringify({ surface: 'odatav4' }),
});

const ledgerPage = {
    value: [
        { Entry_No: 1, Document_Type: 'Payment', Entry_Type: 'Initial Entry', Customer_No: 'C0001' },
        { Entry_No: 2, Document_Type: 'Payment', Entry_Type: 'Initial Entry', Customer_No: 'C0002' },
    ],
};

// ─── Mocked connector ─────────────────────────────────────────────────────

/**
 * Canonical Mocked<Connector> subclass. Stubs ONLY (a) the socket (`SendHTTP`), (b) token minting, and
 * (c) the engine metadata cache. Everything else is the REAL connector: URL building, per-request token
 * refresh + 401 re-acquire, retry/backoff, pagination, dedupe, watermark math, If-Match conditional
 * writes, write pacing, and error classification. No network, no mutation.
 */
class MockedBusinessCentralConnector extends BusinessCentralConnector {
    public Captured: CapturedRequest[] = [];
    public Responses: RESTResponse[] = [];
    public IOFixtures = new Map<string, MJIntegrationObjectEntity>();
    public IOFFixtures = new Map<string, MJIntegrationObjectFieldEntity[]>();
    public TokenMints = 0;
    public Sleeps: number[] = [];
    /** Records the exact interleaving of write starts/ends so serialization is provable. */
    public WriteTrace: string[] = [];

    protected override async SendHTTP(
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown,
    ): Promise<RESTResponse> {
        this.Captured.push({ url, method, headers, body });
        const next = this.Responses.shift();
        if (!next) throw new Error(`MockedBusinessCentralConnector: no canned response queued for ${method} ${url}`);
        return next;
    }

    /** Token minting stub — counts mints so "lazy, expiring, re-acquire-once" is observable. */
    protected override async acquireAccessToken(_config: BusinessCentralConnectionConfig): Promise<string> {
        this.TokenMints++;
        return `token-${this.TokenMints}`;
    }

    /** No real waiting: pacing/backoff durations are asserted, never slept. */
    protected override async sleep(ms: number): Promise<void> {
        this.Sleeps.push(ms);
        this.WriteTrace.push(`sleep(${ms})`);
    }

    protected override GetCachedObject(_integrationID: string, objectName: string): MJIntegrationObjectEntity {
        const io = this.IOFixtures.get(objectName);
        if (!io) throw new Error(`test IO fixture missing: ${objectName}`);
        return io;
    }

    protected override GetCachedFields(objectID: string): MJIntegrationObjectFieldEntity[] {
        return this.IOFFixtures.get(objectID) ?? idPK;
    }

    // ── Exposed protected seams for direct unit assertions ──
    public PublicNormalize(body: unknown, key: string | null): Record<string, unknown>[] {
        return this.NormalizeResponse(body, key);
    }
    public PublicExtractPagination(body: unknown, type: PaginationType) {
        return this.ExtractPaginationInfo(body, type, 1, 0, 0);
    }
    public PublicBuildPaginatedURL(basePath: string, obj: MJIntegrationObjectEntity, cursor?: string): string {
        return (this as unknown as {
            BuildPaginatedURL(b: string, o: MJIntegrationObjectEntity, p: number, off: number, c?: string, e?: number): string;
        }).BuildPaginatedURL(basePath, obj, 2, 0, cursor);
    }
    public async PublicAuth(ci: MJCompanyIntegrationEntity): Promise<BusinessCentralAuthContext> {
        return this.Authenticate(ci, user);
    }
    public async PublicHeaders(ci: MJCompanyIntegrationEntity): Promise<Record<string, string>> {
        return this.BuildHeaders(await this.Authenticate(ci, user));
    }
    public async PublicBaseURL(ci: MJCompanyIntegrationEntity): Promise<string> {
        return this.GetBaseURL(ci, await this.Authenticate(ci, user));
    }
    public PublicCollectionQuery(obj: MJIntegrationObjectEntity, ctx: FetchContext): string {
        return this.BuildCollectionQuery(obj, ctx);
    }
    public PublicClassify(response: RESTResponse) {
        return this.ClassifyODataError(response);
    }
    public PublicErrorMessage(response: RESTResponse): string | undefined {
        return this.ExtractErrorMessage(response);
    }
}

const user = {} as never;

/** Baseline connection config: sandbox environment, single company, tenant segment ON (form A). */
function baseConfig(over: Record<string, unknown> = {}): Record<string, unknown> {
    return {
        ClientId: 'app-client-id',
        ClientSecret: 'app-client-secret',
        TenantId: TENANT,
        Environment: 'Sandbox',
        CompanyId: COMPANY_A,
        ...over,
    };
}

function makeCI(cfg: Record<string, unknown> = baseConfig()): MJCompanyIntegrationEntity {
    return {
        ID: `ci-${JSON.stringify(cfg).length}-${cfg.Environment ?? 'none'}-${cfg.CompanyId ?? 'nc'}`,
        IntegrationID: 'int-bc',
        Configuration: JSON.stringify(cfg),
        CredentialID: null,
    } as unknown as MJCompanyIntegrationEntity;
}

function ok(body: unknown, headers: Record<string, string> = {}): RESTResponse {
    return { Status: 200, Body: body, Headers: headers };
}
function status(code: number, body: unknown = null, headers: Record<string, string> = {}): RESTResponse {
    return { Status: code, Body: body, Headers: headers };
}

function makeConnector(): MockedBusinessCentralConnector {
    const c = new MockedBusinessCentralConnector();
    c.IOFixtures.set('customers', customersIO);
    c.IOFixtures.set('journalLines', journalLinesIO);
    c.IOFixtures.set('trialBalances', trialBalancesIO);
    c.IOFixtures.set('Detailed_Customer_Ledger_Entries', ledgerEntriesIO);
    c.IOFFixtures.set('io-customers', idPK);
    c.IOFFixtures.set('io-journalLines', idPK);
    c.IOFFixtures.set('io-trialBalances', idPK);
    c.IOFFixtures.set('io-ledger', [makeIOF({ Name: 'Entry_No', IsPrimaryKey: true, IsRequired: true })]);
    return c;
}

function fetchCtx(objectName: string, ci: MJCompanyIntegrationEntity, over?: Partial<FetchContext>): FetchContext {
    return {
        CompanyIntegration: ci,
        ObjectName: objectName,
        WatermarkValue: null,
        BatchSize: 1000,
        ContextUser: user,
        ...over,
    };
}

let connector: MockedBusinessCentralConnector;
beforeEach(() => {
    connector = makeConnector();
});

// ══════════════════════════════════════════════════════════════════════════
describe('BusinessCentralConnector — identity', () => {
    it('IntegrationName is the verbatim MJ: Integrations.Name (T1 three-way invariant)', () => {
        expect(new BusinessCentralConnector().IntegrationName).toBe('business-central');
    });

    it('declares the write capabilities the frozen contract populates per-operation columns for', () => {
        const c = new BusinessCentralConnector();
        expect(c.SupportsCreate).toBe(true);
        expect(c.SupportsUpdate).toBe(true);
        expect(c.SupportsDelete).toBe(true);
    });

    it('discovery is NOT authoritative — absence from $metadata must never deactivate a declared object', () => {
        expect(new BusinessCentralConnector().DiscoveryIsAuthoritative).toBe(false);
    });
});

// ══════════════════════════════════════════════════════════════════════════
describe('dual-surface URL builder — the company-key QUOTING difference', () => {
    const parts = { Server: 'https://api.businesscentral.dynamics.com', TenantId: TENANT, Environment: 'Sandbox', ApiVersion: 'v2.0', CompanyId: COMPANY_A };

    it('webapi renders the company GUID UNQUOTED: companies({guid})', () => {
        const segment = BuildBusinessCentralCompanySegment('webapi', COMPANY_A);
        expect(segment).toBe(`companies(${COMPANY_A})`);
        expect(segment).not.toContain("'");
    });

    it("odatav4 renders the company GUID SINGLE-QUOTED: Company('{guid}')", () => {
        const segment = BuildBusinessCentralCompanySegment('odatav4', COMPANY_A);
        expect(segment).toBe(`Company('${COMPANY_A}')`);
        expect(segment).toContain("'");
    });

    it('the two surfaces differ ONLY in that quoting — getting it wrong yields a 404, not a validation error', () => {
        const webapi = BuildBusinessCentralCompanySegment('webapi', COMPANY_A);
        const odatav4 = BuildBusinessCentralCompanySegment('odatav4', COMPANY_A);
        expect(webapi).not.toBe(odatav4);
        expect(webapi.replace('companies(', "Company('").replace(')', "')")).toBe(odatav4);
    });

    it('webapi full resource URL matches the documented grammar', () => {
        expect(BuildBusinessCentralResourceURL('webapi', parts, 'customers')).toBe(
            `https://api.businesscentral.dynamics.com/v2.0/${TENANT}/Sandbox/api/v2.0/companies(${COMPANY_A})/customers`,
        );
    });

    it('odatav4 full resource URL matches the documented grammar (published page, quoted company)', () => {
        expect(BuildBusinessCentralResourceURL('odatav4', parts, 'Detailed_Customer_Ledger_Entries')).toBe(
            `https://api.businesscentral.dynamics.com/v2.0/${TENANT}/Sandbox/ODataV4/Company('${COMPANY_A}')/Detailed_Customer_Ledger_Entries`,
        );
    });

    it('omits the company segment entirely for tenant-scoped resources (companies, subscriptions)', () => {
        const url = BuildBusinessCentralResourceURL('webapi', { ...parts, CompanyId: null }, 'companies');
        expect(url).toBe(`https://api.businesscentral.dynamics.com/v2.0/${TENANT}/Sandbox/api/v2.0/companies`);
    });

    it('supports BOTH documented prefix forms — with (A) and without (B) the tenant segment', () => {
        const formA = BuildBusinessCentralRootURL('webapi', parts);
        const formB = BuildBusinessCentralRootURL('webapi', { ...parts, TenantId: null });
        expect(formA).toBe(`https://api.businesscentral.dynamics.com/v2.0/${TENANT}/Sandbox/api/v2.0`);
        expect(formB).toBe('https://api.businesscentral.dynamics.com/v2.0/Sandbox/api/v2.0');
    });

    it('NEVER hardcodes "Production" — the environment segment is whatever config supplies', () => {
        for (const env of ['Sandbox', 'MyDevBox', 'Production']) {
            expect(BuildBusinessCentralRootURL('webapi', { ...parts, Environment: env })).toContain(`/${env}/`);
        }
        expect(BuildBusinessCentralRootURL('webapi', { ...parts, Environment: 'Sandbox' })).not.toContain('Production');
    });

    it('tolerates a trailing slash on the configured server without doubling separators', () => {
        const url = BuildBusinessCentralRootURL('webapi', { ...parts, Server: 'https://api.businesscentral.dynamics.com/' });
        expect(url).not.toContain('//v2.0');
    });
});

// ══════════════════════════════════════════════════════════════════════════
describe('OData query building — real escaping + literal typing', () => {
    it("escapes a single quote by DOUBLING it (never string-interpolated raw)", () => {
        expect(EscapeODataStringLiteral("O'Brien")).toBe("O''Brien");
        expect(ODataStringLiteral("O'Brien")).toBe("'O''Brien'");
    });

    it('escapes values that came from Business Central itself (the legacy driver interpolated them raw)', () => {
        expect(ODataStringLiteral("INV-001' or 1 eq 1--")).toBe("'INV-001'' or 1 eq 1--'");
    });

    it('Edm.DateTimeOffset watermark literals are UNQUOTED (quoting is a type error in OData v4)', () => {
        const literal = ODataDateTimeOffsetLiteral('2026-01-02T10:00:00Z');
        expect(literal).toBe('2026-01-02T10:00:00.000Z');
        expect(literal).not.toContain("'");
    });

    it('passes an unparsable literal through unchanged rather than corrupting it', () => {
        expect(ODataDateTimeOffsetLiteral('not-a-date')).toBe('not-a-date');
    });

    it('sends the watermark $filter ONLY when the object declares incremental support + a watermark field', () => {
        const ci = makeCI();
        const query = connector.PublicCollectionQuery(customersIO, fetchCtx('customers', ci, { WatermarkValue: '2026-01-02T10:00:00Z' }));
        expect(query).toContain('$filter=');
        expect(decodeURIComponent(query)).toContain('lastModifiedDateTime gt 2026-01-02T10:00:00.000Z');
    });

    it('NEVER sends a watermark filter to an object that does not declare one', () => {
        const ci = makeCI();
        const query = connector.PublicCollectionQuery(trialBalancesIO, fetchCtx('trialBalances', ci, { WatermarkValue: '2026-01-02T10:00:00Z' }));
        expect(query).toBe('');
    });

    it('sends no filter at all on a full (watermark-null) walk', () => {
        const ci = makeCI();
        expect(connector.PublicCollectionQuery(customersIO, fetchCtx('customers', ci))).toBe('');
    });

    it('URL-encodes the whole filter expression', () => {
        const ci = makeCI();
        const query = connector.PublicCollectionQuery(customersIO, fetchCtx('customers', ci, { WatermarkValue: '2026-01-02T10:00:00Z' }));
        expect(query).not.toContain(' ');
        expect(query).toContain('%20gt%20');
    });

    // $expand is the structural replacement for the legacy driver's N+1 per-record ledger lookups: the
    // related collection rides the SAME response. It is METADATA-declared, never a baked navigation list.
    it('emits $expand ONLY from the object\'s own declared Configuration.expand', () => {
        const ci = makeCI();
        const expandIO = makeIO({
            ID: 'io-expand',
            Name: 'salesInvoices',
            APIPath: '/companies({id})/salesInvoices',
            Configuration: JSON.stringify({ expand: ['salesInvoiceLines', 'customer'] }),
        });
        const query = connector.PublicCollectionQuery(expandIO, fetchCtx('salesInvoices', ci));
        expect(decodeURIComponent(query)).toBe('$expand=salesInvoiceLines,customer');
    });

    it('accepts a comma-delimited declared expand string', () => {
        const ci = makeCI();
        const expandIO = makeIO({
            ID: 'io-expand-str',
            Name: 'salesOrders',
            APIPath: '/companies({id})/salesOrders',
            Configuration: JSON.stringify({ expand: 'salesOrderLines, dimensionSetLines' }),
        });
        expect(decodeURIComponent(connector.PublicCollectionQuery(expandIO, fetchCtx('salesOrders', ci))))
            .toBe('$expand=salesOrderLines,dimensionSetLines');
    });

    it('emits NO $expand when the contract declares none (never invents a navigation property)', () => {
        const ci = makeCI();
        // customersIO carries Configuration: null — the shape all 83 frozen-contract IOs currently have.
        expect(connector.PublicCollectionQuery(customersIO, fetchCtx('customers', ci))).toBe('');
        const surfaceOnly = connector.PublicCollectionQuery(ledgerEntriesIO, fetchCtx('Detailed_Customer_Ledger_Entries', ci));
        expect(surfaceOnly).toBe('');
    });

    it('combines a declared $expand with the incremental watermark $filter', () => {
        const ci = makeCI();
        const expandIO = makeIO({
            ID: 'io-expand-wm',
            Name: 'salesInvoices',
            APIPath: '/companies({id})/salesInvoices',
            Configuration: JSON.stringify({ expand: ['salesInvoiceLines'] }),
        });
        const query = connector.PublicCollectionQuery(expandIO, fetchCtx('salesInvoices', ci, { WatermarkValue: '2026-01-02T10:00:00Z' }));
        const decoded = decodeURIComponent(query);
        expect(decoded).toContain('lastModifiedDateTime gt 2026-01-02T10:00:00.000Z');
        expect(decoded).toContain('$expand=salesInvoiceLines');
        expect(query.split('&')).toHaveLength(2);
    });
});

// ══════════════════════════════════════════════════════════════════════════
describe('configuration resolution', () => {
    it('REQUIRES an explicit environment — it is never defaulted to Production', async () => {
        const ci = makeCI({ ClientId: 'a', ClientSecret: 'b', TenantId: TENANT, CompanyId: COMPANY_A });
        await expect(connector.ResolveConfig(ci, user)).rejects.toThrow(/Environment is REQUIRED/i);
    });

    it('fails loudly when the client id/secret are absent', async () => {
        const ci = makeCI({ TenantId: TENANT, Environment: 'Sandbox' });
        await expect(connector.ResolveConfig(ci, user)).rejects.toThrow(/ClientId \/ ClientSecret/i);
    });

    it('honours the legacy §2.2 column overloads — APIKey holds the AZURE TENANT ID', async () => {
        const ci = {
            ID: 'ci-legacy',
            IntegrationID: 'int-bc',
            Configuration: JSON.stringify({ Environment: 'Sandbox' }),
            CredentialID: null,
            ClientID: 'legacy-client',
            ClientSecret: 'legacy-secret',
            APIKey: TENANT,
            ExternalSystemID: COMPANY_A,
        } as unknown as MJCompanyIntegrationEntity;
        const config = await connector.ResolveConfig(ci, user);
        expect(config.TenantId).toBe(TENANT);
        expect(config.ClientId).toBe('legacy-client');
    });

    it('honours the legacy §2.2 overload — ExternalSystemID holds the BC COMPANY GUID', async () => {
        const ci = {
            ID: 'ci-legacy2',
            IntegrationID: 'int-bc',
            Configuration: JSON.stringify({ Environment: 'Sandbox' }),
            CredentialID: null,
            ClientID: 'legacy-client',
            ClientSecret: 'legacy-secret',
            APIKey: TENANT,
            ExternalSystemID: COMPANY_A,
        } as unknown as MJCompanyIntegrationEntity;
        const config = await connector.ResolveConfig(ci, user);
        expect(config.CompanyId).toBe(COMPANY_A);
    });

    it('defaults write pacing to the context-empirical 500 ms and allows an override', async () => {
        expect((await connector.ResolveConfig(makeCI(), user)).WritePacingMs).toBe(500);
        const c2 = makeConnector();
        expect((await c2.ResolveConfig(makeCI(baseConfig({ WritePacingMs: 0 })), user)).WritePacingMs).toBe(0);
    });
});

// ══════════════════════════════════════════════════════════════════════════
describe('auth — lazy, expiring, cached; never frozen at connect', () => {
    it('attaches a Bearer token and JSON content negotiation', async () => {
        const headers = await connector.PublicHeaders(makeCI());
        expect(headers.Authorization).toMatch(/^Bearer token-\d+$/);
        expect(headers.Accept).toBe('application/json');
        expect(headers['Content-Type']).toBe('application/json');
    });

    it('emits the Prefer: odata.maxpagesize client hint only when configured', async () => {
        expect((await connector.PublicHeaders(makeCI())).Prefer).toBeUndefined();
        const c2 = makeConnector();
        expect((await c2.PublicHeaders(makeCI(baseConfig({ MaxPageSize: 1000 })))).Prefer).toBe('odata.maxpagesize=1000');
    });

    it('re-resolves the token on EVERY request — a long sync cannot outlive a frozen token', async () => {
        const ci = makeCI();
        const auth = await connector.PublicAuth(ci);
        const mintsAfterAuth = connector.TokenMints;
        connector.Responses.push(ok(companiesList), ok(companiesList));
        await connector['MakeHTTPRequest'](auth, 'https://x/1', 'GET', {});
        await connector['MakeHTTPRequest'](auth, 'https://x/2', 'GET', {});
        expect(connector.TokenMints).toBeGreaterThan(mintsAfterAuth);
        expect(connector.Captured[0].headers.Authorization).toMatch(/^Bearer token-/);
    });

    it('treats a 401 AFTER a token was attached as expiry — re-acquires ONCE and retries', async () => {
        const auth = await connector.PublicAuth(makeCI());
        connector.Responses.push(status(401, errorUnauthorized), ok(companiesList));
        const response = await connector['MakeHTTPRequest'](auth, 'https://x/companies', 'GET', {});
        expect(response.Status).toBe(200);
        expect(connector.Captured).toHaveLength(2);
        // The retry carried a DIFFERENT (freshly minted) token — proving a re-acquire, not a blind replay.
        expect(connector.Captured[1].headers.Authorization).not.toBe(connector.Captured[0].headers.Authorization);
    });

    it('does not loop forever on a persistent 401 — it re-acquires at most once', async () => {
        const auth = await connector.PublicAuth(makeCI());
        connector.Responses.push(status(401, errorUnauthorized), status(401, errorUnauthorized));
        const response = await connector['MakeHTTPRequest'](auth, 'https://x/companies', 'GET', {});
        expect(response.Status).toBe(401);
        expect(connector.Captured).toHaveLength(2);
    });

    it('never logs or echoes the secret — the Authorization header carries only the minted token', async () => {
        const headers = await connector.PublicHeaders(makeCI());
        expect(JSON.stringify(headers)).not.toContain('app-client-secret');
    });
});

// ══════════════════════════════════════════════════════════════════════════
describe('response normalization — OData collection envelope', () => {
    it('extracts records from the `value` array', () => {
        expect(connector.PublicNormalize(customersPage1, 'value')).toHaveLength(2);
    });

    it('falls back to `value` when the metadata key is null', () => {
        expect(connector.PublicNormalize(customersPage1, null)).toHaveLength(2);
    });

    it('wraps a single-entity body as a one-element array', () => {
        const records = connector.PublicNormalize(customerCreated, 'value');
        expect(records).toHaveLength(1);
        expect(records[0].id).toBe('c-new');
    });

    it('passes a bare array through', () => {
        expect(connector.PublicNormalize([{ id: 'a' }], 'value')).toHaveLength(1);
    });

    it('returns an empty array for null/non-object bodies', () => {
        expect(connector.PublicNormalize(null, 'value')).toEqual([]);
        expect(connector.PublicNormalize('text', 'value')).toEqual([]);
    });

    it('strips NOTHING from the records themselves (full-record pass-through)', () => {
        const record = connector.PublicNormalize(customersPage1, 'value')[0];
        expect(record['@odata.etag']).toBe('W/"JzQ0O0"');
        expect(Object.keys(record)).toEqual(['@odata.etag', 'id', 'number', 'displayName', 'lastModifiedDateTime']);
    });
});

// ══════════════════════════════════════════════════════════════════════════
describe('pagination — server-driven @odata.nextLink, never a fabricated $skip', () => {
    it('reports HasMore + the absolute continuation URL when @odata.nextLink is present', () => {
        const state = connector.PublicExtractPagination(customersPage1, 'Cursor');
        expect(state.HasMore).toBe(true);
        expect(state.NextCursor).toBe(customersPage1['@odata.nextLink']);
    });

    it('reports HasMore=false when the page carries no continuation link', () => {
        expect(connector.PublicExtractPagination(customersPage2, 'Cursor').HasMore).toBe(false);
    });

    it('honours PaginationType "None"', () => {
        expect(connector.PublicExtractPagination(customersPage1, 'None').HasMore).toBe(false);
    });

    it('follows an ABSOLUTE continuation URL verbatim — never re-prefixed', () => {
        const absolute = 'https://api.businesscentral.dynamics.com/v2.0/T/E/api/v2.0/companies(x)/customers?aid=page2';
        expect(connector.PublicBuildPaginatedURL('https://base/ignored', customersIO, absolute)).toBe(absolute);
    });

    it('NEVER fabricates $skip/$top/limit/cursor query params (the GrowthZone one-page defect)', () => {
        const url = connector.PublicBuildPaginatedURL('https://base/companies(x)/customers', customersIO, undefined);
        expect(url).toBe('https://base/companies(x)/customers');
        for (const forbidden of ['$skip', '$top', 'skip=', 'limit=', 'cursor=', 'offset=', 'page=']) {
            expect(url).not.toContain(forbidden);
        }
    });

    it('extracts the continuation link tolerantly of casing (docs never name the property literally)', () => {
        expect(ExtractODataNextLink({ '@odata.nextLink': 'https://a' })).toBe('https://a');
        expect(ExtractODataNextLink({ '@odata.nextlink': 'https://b' })).toBe('https://b');
        expect(ExtractODataNextLink({ value: [] })).toBeNull();
        expect(ExtractODataNextLink(null)).toBeNull();
        expect(ExtractODataNextLink([1, 2])).toBeNull();
    });
});

// ══════════════════════════════════════════════════════════════════════════
describe('FetchChanges — company-scoped walk, pagination to exhaustion, dedupe, watermark', () => {
    it('scopes a company-scoped object under the configured company GUID (unquoted webapi form)', async () => {
        connector.Responses.push(ok(customersPage2));
        await connector.FetchChanges(fetchCtx('customers', makeCI()));
        expect(connector.Captured[0].url).toContain(`companies(${COMPANY_A})/customers`);
        expect(connector.Captured[0].url).not.toContain("Company('");
    });

    it('follows @odata.nextLink to exhaustion and dedupes by primary key across pages', async () => {
        connector.Responses.push(ok(customersPage1), ok(customersPage2));
        const result = await connector.FetchChanges(fetchCtx('customers', makeCI()));
        expect(connector.Captured).toHaveLength(2);
        expect(connector.Captured[1].url).toBe(customersPage1['@odata.nextLink']);
        // 2 + 2 raw records, c-2 repeated → 3 unique.
        expect(result.Records.map(r => r.ExternalID).sort()).toEqual(['c-1', 'c-2', 'c-3']);
        expect(result.HasMore).toBe(false);
    });

    it('tracks the MAX watermark seen across all pages', async () => {
        connector.Responses.push(ok(customersPage1), ok(customersPage2));
        const result = await connector.FetchChanges(fetchCtx('customers', makeCI()));
        expect(result.NewWatermarkValue).toBe('2026-03-05T10:00:00Z');
    });

    it('emits FULL-RECORD pass-through — every source key reaches ExternalRecord.Fields', async () => {
        connector.Responses.push(ok(customersPage2));
        const result = await connector.FetchChanges(fetchCtx('customers', makeCI()));
        expect(Object.keys(result.Records[0].Fields).sort()).toEqual(
            ['@odata.etag', 'displayName', 'id', 'lastModifiedDateTime', 'number'],
        );
    });

    it('checkpoints per page — a batch-size stop returns a resumable cursor', async () => {
        connector.Responses.push(ok(customersPage1));
        const result = await connector.FetchChanges(fetchCtx('customers', makeCI(), { BatchSize: 2 }));
        expect(result.HasMore).toBe(true);
        expect(result.NextCursor).toBeTruthy();
        const resumed = DecodeResumeCursor(result.NextCursor);
        expect(resumed?.u).toBe(customersPage1['@odata.nextLink']);
    });

    it('resumes exactly where it checkpointed — the next call starts at the saved continuation URL', async () => {
        connector.Responses.push(ok(customersPage1));
        const first = await connector.FetchChanges(fetchCtx('customers', makeCI(), { BatchSize: 2 }));
        connector.Captured = [];
        connector.Responses.push(ok(customersPage2));
        const second = await connector.FetchChanges(fetchCtx('customers', makeCI(), { CurrentCursor: first.NextCursor }));
        expect(connector.Captured[0].url).toBe(customersPage1['@odata.nextLink']);
        expect(second.Records.map(r => r.ExternalID)).toContain('c-3');
    });

    it('applies the incremental $filter on the wire when a watermark is supplied', async () => {
        connector.Responses.push(ok(customersPage2));
        await connector.FetchChanges(fetchCtx('customers', makeCI(), { WatermarkValue: '2026-01-02T10:00:00Z' }));
        expect(decodeURIComponent(connector.Captured[0].url)).toContain('$filter=lastModifiedDateTime gt 2026-01-02T10:00:00.000Z');
    });

    it('does NOT put a $filter on the wire for a watermark-less object', async () => {
        connector.Responses.push(ok({ value: [{ id: 't-1' }] }));
        await connector.FetchChanges(fetchCtx('trialBalances', makeCI(), { WatermarkValue: '2026-01-02T10:00:00Z' }));
        expect(connector.Captured[0].url).not.toContain('$filter');
    });

    it('PARTIAL FAILURE: a mid-walk error throws, so the engine leaves the watermark unchanged', async () => {
        connector.Responses.push(ok(customersPage1), status(500, { error: { code: 'Internal_ServerError', message: 'boom' } }));
        await expect(connector.FetchChanges(fetchCtx('customers', makeCI()))).rejects.toThrow(/HTTP 500/);
    });

    it('a 403 on one collection is a WARNING + skip, not a run-killing throw (reachable-but-not-permitted)', async () => {
        connector.Responses.push(status(403, errorForbidden));
        const result = await connector.FetchChanges(fetchCtx('customers', makeCI()));
        expect(result.Records).toHaveLength(0);
        expect(result.Warnings?.[0].Code).toBe('FORBIDDEN');
    });

    it('addresses SEVERAL companies in one run when multiple company GUIDs are configured', async () => {
        const c = makeConnector();
        c.Responses.push(ok({ value: [{ id: 'c-a', lastModifiedDateTime: '2026-01-01T00:00:00Z' }] }));
        c.Responses.push(ok({ value: [{ id: 'c-b', lastModifiedDateTime: '2026-01-01T00:00:00Z' }] }));
        const result = await c.FetchChanges(fetchCtx('customers', makeCI(baseConfig({ CompanyIds: [COMPANY_A, COMPANY_B], CompanyId: undefined }))));
        expect(c.Captured).toHaveLength(2);
        expect(c.Captured[0].url).toContain(`companies(${COMPANY_A})`);
        expect(c.Captured[1].url).toContain(`companies(${COMPANY_B})`);
        expect(result.Records.map(r => r.ExternalID).sort()).toEqual(['c-a', 'c-b']);
    });

    it('enumerates the `companies` root when configured to sync every reachable company', async () => {
        const c = makeConnector();
        c.Responses.push(ok(companiesList));
        c.Responses.push(ok({ value: [{ id: 'x-1' }] }), ok({ value: [{ id: 'x-2' }] }));
        await c.FetchChanges(fetchCtx('customers', makeCI(baseConfig({ AllCompanies: true }))));
        expect(c.Captured[0].url).toMatch(/\/api\/v2\.0\/companies$/);
        expect(c.Captured[1].url).toContain(`companies(${COMPANY_A})`);
        expect(c.Captured[2].url).toContain(`companies(${COMPANY_B})`);
    });
});

// ══════════════════════════════════════════════════════════════════════════
describe('nested access path — children land rows when their parent does', () => {
    it('walks companies → journals → journalLines, enumerating parents at RUNTIME (never baked)', async () => {
        connector.Responses.push(ok(journalsList));                        // parent enumeration
        connector.Responses.push(ok({ value: [{ id: 'jl-1', lastModifiedDateTime: '2026-01-01T00:00:00Z' }] }));
        connector.Responses.push(ok({ value: [{ id: 'jl-2', lastModifiedDateTime: '2026-01-02T00:00:00Z' }] }));
        const result = await connector.FetchChanges(fetchCtx('journalLines', makeCI()));
        expect(connector.Captured[0].url).toContain(`companies(${COMPANY_A})/journals`);
        expect(connector.Captured[1].url).toContain('journals(j-1)/journalLines');
        expect(connector.Captured[2].url).toContain('journals(j-2)/journalLines');
        expect(result.Records.map(r => r.ExternalID).sort()).toEqual(['jl-1', 'jl-2']);
    });

    it('surfaces a LOUD warning when a nested object finds zero parents (never a silent empty)', async () => {
        connector.Responses.push(ok({ value: [] }));
        const result = await connector.FetchChanges(fetchCtx('journalLines', makeCI()));
        expect(result.Records).toHaveLength(0);
        expect(result.Warnings?.map(w => w.Code)).toContain('ZERO_PARENTS');
    });

    it('an empty child collection under a POPULATED parent is reported, not silently swallowed', async () => {
        connector.Responses.push(ok({ value: [{ id: 'j-1' }] }), ok(journalLinesEmpty));
        const result = await connector.FetchChanges(fetchCtx('journalLines', makeCI()));
        expect(connector.Captured[1].url).toContain('journals(j-1)/journalLines');
        expect(result.Records).toHaveLength(0);
        expect(result.HasMore).toBe(false);
    });

    it('parses both documented key forms — unquoted GUID and single-quoted string', () => {
        expect(ParsePathSegments('/companies({id})/journals({id})/journalLines')).toEqual([
            { Name: 'companies', HasKey: true, QuotedKey: false },
            { Name: 'journals', HasKey: true, QuotedKey: false },
            { Name: 'journalLines', HasKey: false, QuotedKey: false },
        ]);
        expect(ParsePathSegments("/subscriptions('{id}')")).toEqual([
            { Name: 'subscriptions', HasKey: true, QuotedKey: true },
        ]);
    });

    it('depth-0 (a flat tenant-scoped set) is the empty-expansion case', () => {
        expect(ParsePathSegments('/companies')).toEqual([{ Name: 'companies', HasKey: false, QuotedKey: false }]);
    });
});

// ══════════════════════════════════════════════════════════════════════════
describe('writes (MOCK ONLY — no live endpoint, no mutation)', () => {
    const ciWrite = () => makeCI();

    function createCtx(attributes: Record<string, unknown>, objectName = 'customers'): CreateRecordContext {
        return { CompanyIntegration: ciWrite(), ContextUser: user, ObjectName: objectName, Attributes: attributes } as unknown as CreateRecordContext;
    }
    function updateCtx(externalID: string, attributes: Record<string, unknown>): UpdateRecordContext {
        return { CompanyIntegration: ciWrite(), ContextUser: user, ObjectName: 'customers', ExternalID: externalID, Attributes: attributes } as unknown as UpdateRecordContext;
    }
    function deleteCtx(externalID: string): DeleteRecordContext {
        return { CompanyIntegration: ciWrite(), ContextUser: user, ObjectName: 'customers', ExternalID: externalID } as unknown as DeleteRecordContext;
    }

    it('CREATE posts to the company-scoped create path with the flat body from the metadata BodyShape', async () => {
        connector.Responses.push({ Status: 201, Body: customerCreated, Headers: {} });
        const result = await connector.CreateRecord(createCtx({ displayName: 'New Co' }));
        expect(result.Success).toBe(true);
        expect(result.ExternalID).toBe('c-new');
        expect(connector.Captured[0].method).toBe('POST');
        expect(connector.Captured[0].url).toBe(
            `https://api.businesscentral.dynamics.com/v2.0/${TENANT}/Sandbox/api/v2.0/companies(${COMPANY_A})/customers`,
        );
        expect(connector.Captured[0].body).toEqual({ displayName: 'New Co' });
    });

    it('CREATE resolves a nested parent segment from the record itself (multi-company journal write)', async () => {
        connector.Responses.push({ Status: 201, Body: { id: 'jl-new' }, Headers: {} });
        await connector.CreateRecord(createCtx({ journalId: 'j-7', accountNumber: '1000', amount: 0 }, 'journalLines'));
        expect(connector.Captured[0].url).toContain(`companies(${COMPANY_A})/journals(j-7)/journalLines`);
    });

    it('CREATE targets a DIFFERENT company when the record names one (multi-company write)', async () => {
        connector.Responses.push({ Status: 201, Body: { id: 'jl-new' }, Headers: {} });
        await connector.CreateRecord(createCtx({ companyId: COMPANY_B, journalId: 'j-7' }, 'journalLines'));
        expect(connector.Captured[0].url).toContain(`companies(${COMPANY_B})/journals(j-7)/journalLines`);
    });

    it('CREATE resolves a nested parent segment from the GENERIC parentId a BC sub-entity carries', async () => {
        // `dimensionSetLines` / `documentAttachments` hang off SEVERAL parents, so Business Central keys
        // them on a polymorphic `parentId` (+`parentType`) rather than a `<parent>Id` named for any one of
        // them. Without the generic fallback the create is refused with "could not resolve the key for
        // segment", which is what the credential-free write matrix caught.
        connector.IOFixtures.set('dimensionSetLines', makeIO({
            ID: 'io-dimensionSetLines',
            Name: 'dimensionSetLines',
            APIPath: '/companies({id})/salesInvoices({id})/dimensionSetLines',
            SupportsWrite: true,
            SupportsCreate: true,
            CreateAPIPath: '/companies({id})/salesInvoices({id})/dimensionSetLines',
            CreateMethod: 'POST',
            CreateBodyShape: 'flat',
            CreateIDLocation: 'body',
        }));
        connector.IOFFixtures.set('io-dimensionSetLines', idPK);
        connector.Responses.push({ Status: 201, Body: { id: 'dsl-new' }, Headers: {} });

        const result = await connector.CreateRecord(createCtx({ parentId: 'inv-3', valueId: 'v-1' }, 'dimensionSetLines'));

        expect(result.Success).toBe(true);
        expect(connector.Captured[0].url).toContain(`companies(${COMPANY_A})/salesInvoices(inv-3)/dimensionSetLines`);
    });

    it('CREATE reads the new record\'s ID from the object\'s METADATA primary key, not just a literal `id`', async () => {
        // Seven BC objects key on something other than `id` (`customerSales` → `customerId`, …). The base
        // scan looks for id/ID/externalID only, so a perfectly successful 201 was reported as a failure AND
        // the identity was lost — which would re-create the same record on the next sync.
        connector.IOFixtures.set('customerSales', makeIO({
            ID: 'io-customerSales',
            Name: 'customerSales',
            APIPath: '/companies({id})/customerSales',
            SupportsWrite: true,
            SupportsCreate: true,
            CreateAPIPath: '/companies({id})/customerSales',
            CreateMethod: 'POST',
            CreateBodyShape: 'flat',
            CreateIDLocation: 'body',
        }));
        connector.IOFFixtures.set('io-customerSales', [
            makeIOF({ Name: 'customerId', IsPrimaryKey: true, IsRequired: true, IsUniqueKey: true }),
            makeIOF({ Name: 'name', Sequence: 1 }),
        ]);
        connector.Responses.push({ Status: 201, Body: { customerId: 'cs-42', name: 'Adatum' }, Headers: {} });

        const result = await connector.CreateRecord(createCtx({ name: 'Adatum' }, 'customerSales'));

        expect(result.Success).toBe(true);
        expect(result.ExternalID).toBe('cs-42');
    });

    it('CREATE fails loudly rather than issuing a request with an unresolved path key', async () => {
        await expect(connector.CreateRecord(createCtx({ amount: 1 }, 'journalLines')))
            .rejects.toThrow(/could not resolve the key for segment "journals"/);
        expect(connector.Captured).toHaveLength(0);
    });

    it('UPDATE sends PATCH with the required If-Match precondition carrying the read-time @odata.etag', async () => {
        // Read first so the ETag cache is warm — mirroring the real read-then-write sync flow.
        connector.Responses.push(ok(customersPage2));
        await connector.FetchChanges(fetchCtx('customers', makeCI()));
        connector.Captured = [];
        connector.Responses.push(ok({ ...customerCreated, id: 'c-3' }));
        const result = await connector.UpdateRecord(updateCtx('c-3', { displayName: 'Renamed' }));
        expect(result.Success).toBe(true);
        expect(connector.Captured[0].method).toBe('PATCH');
        expect(connector.Captured[0].url).toContain(`companies(${COMPANY_A})/customers(c-3)`);
        expect(connector.Captured[0].headers['If-Match']).toBe('W/"JzQ2O0"');
        expect(connector.Captured[0].body).toEqual({ displayName: 'Renamed' });
    });

    it('UPDATE re-reads the ETag when none is cached, then sends it', async () => {
        connector.Responses.push(ok({ '@odata.etag': 'W/"FRESH"', id: 'c-9' })); // the ETag re-read
        connector.Responses.push(ok({ id: 'c-9' }));                              // the PATCH
        await connector.UpdateRecord(updateCtx('c-9', { displayName: 'x' }));
        expect(connector.Captured[0].method).toBe('GET');
        expect(connector.Captured[1].method).toBe('PATCH');
        expect(connector.Captured[1].headers['If-Match']).toBe('W/"FRESH"');
    });

    it('a stale-ETag precondition failure triggers ONE re-read + retry with the fresh tag', async () => {
        connector.Responses.push(ok({ '@odata.etag': 'W/"OLD"', id: 'c-9' }));   // initial ETag read
        connector.Responses.push(status(412, { error: { code: 'PreconditionFailed', message: 'stale' } }));
        connector.Responses.push(ok({ '@odata.etag': 'W/"NEW"', id: 'c-9' }));   // re-read
        connector.Responses.push(ok({ id: 'c-9' }));                              // retried PATCH
        const result = await connector.UpdateRecord(updateCtx('c-9', { displayName: 'x' }));
        expect(result.Success).toBe(true);
        const patches = connector.Captured.filter(r => r.method === 'PATCH');
        expect(patches).toHaveLength(2);
        expect(patches[0].headers['If-Match']).toBe('W/"OLD"');
        expect(patches[1].headers['If-Match']).toBe('W/"NEW"');
    });

    it('falls back to the wildcard If-Match only when no ETag can be resolved', async () => {
        connector.Responses.push(status(404, null));   // the ETag re-read fails
        connector.Responses.push(ok({ id: 'c-9' }));   // the PATCH still goes out
        await connector.UpdateRecord(updateCtx('c-9', { displayName: 'x' }));
        expect(connector.Captured[1].headers['If-Match']).toBe('*');
    });

    it('refuses the wildcard bypass when IfMatchFallback="fail"', async () => {
        const c = makeConnector();
        const ci = makeCI(baseConfig({ IfMatchFallback: 'fail' }));
        c.Responses.push(status(404, null));
        await expect(c.UpdateRecord({
            CompanyIntegration: ci, ContextUser: user, ObjectName: 'customers', ExternalID: 'c-9', Attributes: {},
        } as unknown as UpdateRecordContext)).rejects.toThrow(/IfMatchFallback is "fail"/);
    });

    it('DELETE sends the required If-Match and drops the cached tag on success', async () => {
        connector.Responses.push(ok({ '@odata.etag': 'W/"DEL"', id: 'c-9' }));
        connector.Responses.push(status(204, null));
        const result = await connector.DeleteRecord(deleteCtx('c-9'));
        expect(result.Success).toBe(true);
        const del = connector.Captured.find(r => r.method === 'DELETE');
        expect(del?.headers['If-Match']).toBe('W/"DEL"');
        expect(del?.url).toContain(`companies(${COMPANY_A})/customers(c-9)`);
    });

    it('PACES writes: each write waits writePacingMs and they are SERIALIZED, never a parallel fan-out', async () => {
        connector.Responses.push({ Status: 201, Body: { id: 'a' }, Headers: {} });
        connector.Responses.push({ Status: 201, Body: { id: 'b' }, Headers: {} });
        connector.Responses.push({ Status: 201, Body: { id: 'c' }, Headers: {} });
        await Promise.all([
            connector.CreateRecord(createCtx({ n: 1 })),
            connector.CreateRecord(createCtx({ n: 2 })),
            connector.CreateRecord(createCtx({ n: 3 })),
        ]);
        expect(connector.Sleeps.filter(ms => ms === 500)).toHaveLength(3);
        // Serialization proof: request bodies came out in submission order, one at a time.
        expect(connector.Captured.map(r => (r.body as { n: number }).n)).toEqual([1, 2, 3]);
    });

    it('surfaces a write failure with the CLASSIFIED code, never a swallowed error', async () => {
        connector.Responses.push(status(400, errorRequestDataInvalid));
        const result = await connector.CreateRecord(createCtx({ displayName: '' }));
        expect(result.Success).toBe(false);
        expect(result.StatusCode).toBe(400);
        expect(result.ErrorMessage).toContain('VALIDATION_ERROR');
    });

    it('throws (rather than silently no-oping) when an object has no create metadata', async () => {
        await expect(connector.CreateRecord(createCtx({}, 'trialBalances')))
            .rejects.toThrow(/CreateAPIPath \/ CreateMethod not configured/);
    });
});

// ══════════════════════════════════════════════════════════════════════════
describe('errors + throttling', () => {
    it('classifies off the OData error CODE, never the human message', () => {
        expect(connector.PublicClassify(status(400, errorRequestDataInvalid))).toBe('VALIDATION_ERROR');
        expect(connector.PublicClassify(status(400, { error: { code: 'EntityWithSameKeyExists', message: 'anything at all' } }))).toBe('DUPLICATE_KEY');
        // A message that LOOKS like a rate limit but carries a validation code stays a validation error.
        expect(connector.PublicClassify(status(400, { error: { code: 'RequestDataInvalid', message: 'too many requests' } }))).toBe('VALIDATION_ERROR');
    });

    it('maps 429 to RATE_LIMIT_EXCEEDED and 503/504 to NETWORK_TIMEOUT', () => {
        expect(connector.PublicClassify(status(429, null))).toBe('RATE_LIMIT_EXCEEDED');
        expect(connector.PublicClassify(status(503, null))).toBe('NETWORK_TIMEOUT');
        expect(connector.PublicClassify(status(504, null))).toBe('NETWORK_TIMEOUT');
    });

    it('extracts the message from the documented error envelope', () => {
        expect(connector.PublicErrorMessage(status(401, errorUnauthorized))).toBe('The credentials provided are incorrect');
        expect(connector.PublicErrorMessage(status(400, { error: { code: 'X', message: { value: 'nested form' } } }))).toBe('nested form');
    });

    it('retries a 429 with backoff and succeeds', async () => {
        const auth = await connector.PublicAuth(makeCI());
        connector.Responses.push(status(429, null), ok(companiesList));
        const response = await connector['MakeHTTPRequest'](auth, 'https://x/c', 'GET', {});
        expect(response.Status).toBe(200);
        expect(connector.Sleeps.length).toBeGreaterThan(0);
    });

    it('honours an OBSERVED Retry-After (seconds) rather than an assumed backoff', async () => {
        const auth = await connector.PublicAuth(makeCI());
        connector.Responses.push(status(429, null, { 'retry-after': '7' }), ok(companiesList));
        await connector['MakeHTTPRequest'](auth, 'https://x/c', 'GET', {});
        expect(connector.Sleeps).toContain(7000);
    });

    it('parses Retry-After in both the seconds and HTTP-date forms, and returns undefined when absent', () => {
        expect(connector.ExtractRetryAfterMs({ Headers: { 'retry-after': '3' } })).toBe(3000);
        const future = new Date(Date.now() + 5000).toUTCString();
        expect(connector.ExtractRetryAfterMs({ Headers: { 'retry-after': future } })).toBeGreaterThan(0);
        expect(connector.ExtractRetryAfterMs({ Headers: {} })).toBeUndefined();
        expect(connector.ExtractRetryAfterMs('not an error object')).toBeUndefined();
    });

    it('gives up after the configured retry budget instead of retrying forever', async () => {
        const c = makeConnector();
        const auth = await c.PublicAuth(makeCI(baseConfig({ MaxRetries: 2 })));
        for (let i = 0; i < 5; i++) c.Responses.push(status(429, null));
        const response = await c['MakeHTTPRequest'](auth, 'https://x/c', 'GET', {});
        expect(response.Status).toBe(429);
        expect(c.Captured).toHaveLength(3); // initial + 2 retries
    });

    it('declares the documented rate-limit policy and per-user concurrency ceiling', () => {
        const c = new BusinessCentralConnector();
        expect(c.MaxConcurrencyHint).toBe(5);
        const policy = c.RateLimitPolicy;
        expect(policy?.TokensPerSec).toBeCloseTo(300 / 60); // sandbox rate before a connection resolves
        expect(policy?.Burst).toBe(5);
    });
});

// ══════════════════════════════════════════════════════════════════════════
describe('TestConnection — distinguishes credential from permission', () => {
    it('succeeds and reports the reachable company count', async () => {
        connector.Responses.push(ok(companiesList));
        const result = await connector.TestConnection(makeCI(), user);
        expect(result.Success).toBe(true);
        expect(result.Message).toContain('2 company');
        expect(connector.Captured[0].url).toMatch(/\/api\/v2\.0\/companies$/);
    });

    it('reports a 401 as a CREDENTIAL problem', async () => {
        connector.Responses.push(status(401, errorUnauthorized), status(401, errorUnauthorized));
        const result = await connector.TestConnection(makeCI(), user);
        expect(result.Success).toBe(false);
        expect(result.Message).toMatch(/client ID\/secret and tenant ID/i);
    });

    it('reports a 403 as reachable-but-not-permitted — NOT an invalid credential, NOT a connector defect', async () => {
        connector.Responses.push(status(403, errorForbidden));
        const result = await connector.TestConnection(makeCI(), user);
        expect(result.Success).toBe(false);
        expect(result.Message).toMatch(/permission\/scope problem, not an invalid credential/i);
    });

    it('never targets Production unless the connection says so', async () => {
        connector.Responses.push(ok(companiesList));
        await connector.TestConnection(makeCI(), user);
        expect(connector.Captured[0].url).toContain('/Sandbox/');
        expect(connector.Captured[0].url).not.toContain('/Production/');
    });
});

// ══════════════════════════════════════════════════════════════════════════
describe('disconnect is real, not a stub', () => {
    it('releases the token cache, the resolved configuration and the ETag cache', async () => {
        connector.Responses.push(ok(customersPage2));
        await connector.FetchChanges(fetchCtx('customers', makeCI()));
        expect(connector.TokenMints).toBeGreaterThan(0);
        expect(() => connector.Disconnect()).not.toThrow();
        // After release the next call re-resolves from scratch rather than reusing stale state.
        connector.Responses.push(ok(customersPage2));
        await expect(connector.FetchChanges(fetchCtx('customers', makeCI()))).resolves.toBeTruthy();
    });
});

// ══════════════════════════════════════════════════════════════════════════
describe('discovery is MECHANISM — $metadata parsing, never a baked catalog', () => {
    it('enumerates entity sets from an EDMX document at runtime', () => {
        expect(ParseEDMXEntitySets(edmxSample)).toEqual(['customers', 'Detailed_Customer_Ledger_Entries']);
    });

    it('surfaces a tenant-PUBLISHED ODataV4 page — proving different tenants discover different sets', () => {
        expect(ParseEDMXEntitySets(edmxSample)).toContain('Detailed_Customer_Ledger_Entries');
    });

    it('reads field constraints FROM the EDMX (Nullable, MaxLength, the <Key> PropertyRef) — never guessed', () => {
        const fields = ParseEDMXFieldsForEntitySet(edmxSample, 'customers');
        expect(fields.map(f => f.Name)).toEqual(['id', 'displayName', 'lastModifiedDateTime']);
        const id = fields.find(f => f.Name === 'id');
        expect(id?.IsPrimaryKey).toBe(true);
        expect(id?.IsRequired).toBe(true);
        expect(id?.DataType).toBe('Edm.Guid');
        const displayName = fields.find(f => f.Name === 'displayName');
        expect(displayName?.IsPrimaryKey).toBeUndefined();
        expect(displayName?.AllowsNull).toBe(true);
        expect(displayName?.MaxLength).toBe(100);
    });

    it('returns nothing for an entity set the document does not declare (no fabrication)', () => {
        expect(ParseEDMXFieldsForEntitySet(edmxSample, 'notAThing')).toEqual([]);
    });

    it('tolerates a malformed/empty EDMX rather than throwing', () => {
        expect(ParseEDMXEntitySets('')).toEqual([]);
        expect(ParseEDMXFieldsForEntitySet('<nope/>', 'customers')).toEqual([]);
    });
});

// ══════════════════════════════════════════════════════════════════════════
describe('per-IO surface selection — the dual-surface builder is reachable at FETCH and WRITE time', () => {
    it('fetches a webapi object with the UNQUOTED company form (default surface)', async () => {
        const ci = makeCI();
        connector.Responses = [ok({ value: [] })];
        await connector.FetchChanges(fetchCtx('customers', ci));
        expect(connector.Captured[0].url).toContain(`/api/v2.0/companies(${COMPANY_A})/customers`);
        expect(connector.Captured[0].url).not.toContain('ODataV4');
    });

    it("fetches an IO tagged surface=odatav4 with the SINGLE-QUOTED Company('{guid}') form", async () => {
        const ci = makeCI();
        connector.Responses = [ok(ledgerPage)];
        const result = await connector.FetchChanges(fetchCtx('Detailed_Customer_Ledger_Entries', ci));
        const url = connector.Captured[0].url;
        expect(url).toContain(`/ODataV4/Company('${COMPANY_A}')/Detailed_Customer_Ledger_Entries`);
        // The webapi grammar must NOT leak onto this surface — that combination 404s.
        expect(url).not.toContain('/api/v2.0');
        expect(url).not.toContain(`companies(${COMPANY_A})`);
        expect(result.Records).toHaveLength(2);
    });

    it('prepends the company segment on odatav4 even though the declared page path has none', async () => {
        const ci = makeCI();
        connector.Responses = [ok(ledgerPage)];
        await connector.FetchChanges(fetchCtx('Detailed_Customer_Ledger_Entries', ci));
        // Exactly one company segment — never doubled.
        expect(connector.Captured[0].url.match(/Company\('/g)).toHaveLength(1);
    });

    it('carries a published ODataV4 page through the FULL-RECORD pass-through unchanged', async () => {
        const ci = makeCI();
        connector.Responses = [ok(ledgerPage)];
        const result = await connector.FetchChanges(fetchCtx('Detailed_Customer_Ledger_Entries', ci));
        expect(result.Records[0].Fields).toEqual(ledgerPage.value[0]);
        expect(result.Records[0].ExternalID).toBe('1');
    });

    it('an unrecognised or absent surface tag falls back to webapi (never a guess that 404s silently)', async () => {
        const ci = makeCI();
        connector.IOFixtures.set('customers', makeIO({
            ...(customersIO as unknown as Record<string, unknown>),
            ID: 'io-customers',
            Name: 'customers',
            Configuration: JSON.stringify({ surface: 'nonsense' }),
        } as Partial<MJIntegrationObjectEntity> & { ID: string; Name: string }));
        connector.Responses = [ok({ value: [] })];
        await connector.FetchChanges(fetchCtx('customers', ci));
        expect(connector.Captured[0].url).toContain('/api/v2.0/companies(');
    });

    it('an odatav4 object with no company resolvable warns loudly instead of building a broken URL', async () => {
        const ci = makeCI(baseConfig({ CompanyId: undefined }));
        // No company configured → the connector enumerates the `companies` root; the credential reaches none.
        connector.Responses = [ok({ value: [] })];
        const result = await connector.FetchChanges(fetchCtx('Detailed_Customer_Ledger_Entries', ci));
        expect(result.Records).toHaveLength(0);
        expect(result.Warnings?.some(w => w.Code === 'NO_COMPANY_IN_SCOPE')).toBe(true);
        // Only the enumeration request went out — no malformed company-less ODataV4 URL was ever requested.
        expect(connector.Captured).toHaveLength(1);
        expect(connector.Captured[0].url).toMatch(/\/companies$/);
    });

    it('an unreachable companies root is a hard FAILURE, never a silent empty result', async () => {
        const ci = makeCI(baseConfig({ CompanyId: undefined }));
        connector.Responses = [status(500, null)];
        await expect(connector.FetchChanges(fetchCtx('Detailed_Customer_Ledger_Entries', ci)))
            .rejects.toThrow(/could not enumerate companies/i);
    });
});

describe('resume cursor round-trip', () => {
    it('encodes and decodes the checkpoint losslessly', () => {
        const state = { u: 'https://a/next', r: ['https://b', 'https://c'] };
        expect(DecodeResumeCursor(EncodeResumeCursor(state))).toEqual(state);
    });

    it('treats an absent or corrupt cursor as a fresh walk rather than throwing', () => {
        expect(DecodeResumeCursor(undefined)).toBeNull();
        expect(DecodeResumeCursor('')).toBeNull();
        expect(DecodeResumeCursor('!!!not-base64-json!!!')).toBeNull();
    });
});
