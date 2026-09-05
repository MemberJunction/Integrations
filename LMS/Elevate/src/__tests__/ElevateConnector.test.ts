import { describe, it, expect, beforeEach } from 'vitest';
import type {
    RESTAuthContext,
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
import { ElevateConnector, ElevateAPIError } from '../ElevateConnector.js';

// ─── Fixtures ─────────────────────────────────────────────────────────────────
//
// PROVENANCE: spec-derived (see packages/Integration/connectors-registry/elevate/fixtures/PROVENANCE.json).
// The RealityProbe for this build was verdicts-only against the vendor's published demo host and copied
// NO response content, so there are no captured pages to descend from: every VALUE here is synthetic and
// every SHAPE traces to the derived spec, the vendor's worked examples, or a probe verdict (envelope key
// names, the `Field <name> doesn't exist` message, the yearly window partition). No PII, no tenant data,
// no credential bytes, no network, no mutation.

/** The Report API envelope, exactly as the probe recorded its key names. */
function envelope(items: Record<string, unknown>[], labels: Record<string, string>, count?: number): unknown {
    return { response: { labels, items, count: count ?? items.length } };
}

const productLabels = { id: 'Product ID', title: 'Title', remote_accounting_code: 'Accounting Code' };
const registrationLabels = {
    transaction_at: 'Transaction Date',
    modified_at: 'Modified Date',
    'product.title': 'Product Title',
    'user.member_id': 'Member ID',
    'payment.card_partial': 'Card (last 4)',
};
const earnedCreditLabels = {
    earning_method: 'Earning Method',
    updated_at: 'Updated Date',
    credit_type_label: 'Credit Type',
};

const productRows = [
    { id: 101, title: 'Introduction to Compliance', remote_accounting_code: 'GL-4100' },
    { id: 102, title: 'Retired Legacy Course', remote_accounting_code: 'GL-4200' },
];

const registrationRows = [
    {
        transaction_at: '2025-03-04T10:00:00',
        modified_at: '2025-03-05T09:00:00',
        product: { title: 'Introduction to Compliance', remote_accounting_code: 'GL-4100' },
        user: { member_id: 'M-0001', email: 'example+1@example.org' },
        payment: { card_partial: '1111' },
        // A per-tenant column the declared floor never carried — it MUST survive into ExternalRecord.Fields.
        site_custom_cohort: 'cohort-a',
    },
];

const userRows = [
    { member_id: 'M-0001', firstname: '<scrubbed-given-1>', lastname: '<scrubbed-family-1>', email: 'example+1@example.org' },
    { member_id: null, firstname: '<scrubbed-given-4>', lastname: '<scrubbed-family-4>', email: 'example+4@example.org' },
];

// ─── Test doubles ─────────────────────────────────────────────────────────────

interface CapturedRequest {
    url: string;
    method: string;
    headers: Record<string, string>;
    body: Record<string, unknown> | undefined;
}

interface CannedResponse {
    match?: (req: { url: string; method: string; body: Record<string, unknown> | undefined }) => boolean;
    response: RESTResponse;
}

function makeIO(over: Partial<MJIntegrationObjectEntity> & { ID: string; Name: string }): MJIntegrationObjectEntity {
    return {
        DisplayName: over.Name,
        Description: 'fixture',
        APIPath: '/api/reports',
        ResponseDataKey: 'response.items',
        DefaultPageSize: 0,
        SupportsPagination: false,
        PaginationType: 'None',
        SupportsWrite: false,
        SupportsCreate: false,
        SupportsUpdate: false,
        SupportsDelete: false,
        SupportsIncrementalSync: false,
        IncrementalWatermarkField: null,
        StableOrderingKey: null,
        ContentHashApplicable: true,
        SyncStrategy: 'FullPullHashDiff',
        Configuration: null,
        DefaultQueryParams: null,
        Status: 'Active',
        Sequence: 0,
        CreateAPIPath: null, CreateMethod: null, CreateBodyShape: null, CreateBodyKey: null, CreateIDLocation: null,
        UpdateAPIPath: null, UpdateMethod: null, UpdateBodyShape: null, UpdateBodyKey: null, UpdateIDLocation: null,
        DeleteAPIPath: null, DeleteMethod: null, DeleteIDLocation: null,
        ...over,
    } as unknown as MJIntegrationObjectEntity;
}

function makeIOF(over: Partial<MJIntegrationObjectFieldEntity> & { Name: string }): MJIntegrationObjectFieldEntity {
    return {
        ID: `iof-${over.Name}`,
        DisplayName: over.Name,
        Type: 'String',
        Length: null, Precision: null, Scale: null, DefaultValue: null,
        IsPrimaryKey: false, IsRequired: false, IsReadOnly: false, IsUniqueKey: false,
        AllowsNull: true, Sequence: 0, Status: 'Active', Configuration: null,
        RelatedIntegrationObjectID: null, RelatedIntegrationObject: null, RelatedIntegrationObjectFieldName: null,
        ...over,
    } as unknown as MJIntegrationObjectFieldEntity;
}

/** IOF Configuration exactly as the metadata carries it: MJ column name + dot-path wire selector + landing path. */
function projectedIOF(name: string, wireSelector: string, sequence: number): MJIntegrationObjectFieldEntity {
    return makeIOF({
        Name: name,
        Sequence: sequence,
        Configuration: JSON.stringify({ wireSelector, responsePath: wireSelector.split('.') }),
    });
}

const productIO = makeIO({
    ID: 'io-product', Name: 'Product',
    StableOrderingKey: 'id',
    Configuration: JSON.stringify({
        resourceWireValue: 'product',
        readContract: { door: '/api/reports', method: 'POST', bodySelector: 'resource', responseCountKey: 'response.count', responseLabelsKey: 'response.labels' },
        accessPaths: [{ door: '/api/reports', method: 'POST', body: { resource: 'product' }, nesting: [], depth: 0 }],
    }),
});
const productIOFs = [
    makeIOF({ Name: 'id', Type: 'Integer', IsPrimaryKey: true, IsUniqueKey: true, IsReadOnly: true, Sequence: 0, Configuration: JSON.stringify({ wireSelector: 'id', responsePath: ['id'] }) }),
    makeIOF({ Name: 'remote_accounting_code', Sequence: 1, Configuration: JSON.stringify({ wireSelector: 'remote_accounting_code', responsePath: ['remote_accounting_code'] }) }),
    makeIOF({ Name: 'title', Sequence: 2, Configuration: JSON.stringify({ wireSelector: 'title', responsePath: ['title'] }) }),
];

const registrationIO = makeIO({
    ID: 'io-registration', Name: 'ProductRegistration',
    SupportsIncrementalSync: true,
    IncrementalWatermarkField: 'modified_at',
    SyncStrategy: 'WatermarkIncremental',
    SupportsWrite: true, SupportsCreate: true, SupportsDelete: true,
    CreateAPIPath: '/api/registrations', CreateMethod: 'POST', CreateBodyShape: 'flat', CreateIDLocation: 'body.registration_id',
    DeleteAPIPath: '/registrations/cancel', DeleteMethod: 'POST', DeleteIDLocation: 'body.registration_id',
    Configuration: JSON.stringify({
        resourceWireValue: 'productRegistration',
        readContract: { door: '/api/reports', method: 'POST', bodySelector: 'resource', responseCountKey: 'response.count', responseLabelsKey: 'response.labels' },
    }),
});
const registrationIOFs = [
    makeIOF({ Name: 'transaction_at', Type: 'Datetime', Sequence: 0, Configuration: JSON.stringify({ wireSelector: 'transaction_at', responsePath: ['transaction_at'] }) }),
    makeIOF({ Name: 'modified_at', Type: 'Datetime', IsReadOnly: true, Sequence: 1, Configuration: JSON.stringify({ wireSelector: 'modified_at', responsePath: ['modified_at'] }) }),
    projectedIOF('product_title', 'product.title', 2),
    projectedIOF('user_member_id', 'user.member_id', 3),
    projectedIOF('payment_card_partial', 'payment.card_partial', 4),
    // The record key AND write-only, at the same time — mirrors the shipped metadata verbatim.
    // IsPrimaryKey: the cancel API addresses exactly one registration by this value, so it IS the
    // record key. surface/excludeFromReadFieldSelector: the probe proved the READ door has no such
    // column (`Field registration_id doesn't exist`), and the allow-list is all-or-nothing, so asking
    // for it would fail the WHOLE query. Type is String, not Integer, because this column carries the
    // record's external identity from either provenance — the vendor's integer on create, and the
    // connector's minted content-hash identity on read (an INT column cannot hold a sha256).
    makeIOF({
        Name: 'registration_id', Type: 'String', IsPrimaryKey: true, IsReadOnly: true, Sequence: 5,
        Configuration: JSON.stringify({ surface: 'write-only', excludeFromReadFieldSelector: true }),
    }),
    makeIOF({
        Name: 'remote_user_id', Sequence: 6,
        Configuration: JSON.stringify({ surface: 'write-only', wireSelector: 'remote_user_id' }),
    }),
];

const userIO = makeIO({
    ID: 'io-user', Name: 'User',
    Configuration: JSON.stringify({ resourceWireValue: 'user' }),
});
const userIOFs = [
    makeIOF({ Name: 'member_id', Sequence: 0, Configuration: JSON.stringify({ wireSelector: 'member_id', responsePath: ['member_id'] }) }),
    makeIOF({ Name: 'firstname', Sequence: 1, Configuration: JSON.stringify({ wireSelector: 'firstname', responsePath: ['firstname'] }) }),
    makeIOF({ Name: 'lastname', Sequence: 2, Configuration: JSON.stringify({ wireSelector: 'lastname', responsePath: ['lastname'] }) }),
    makeIOF({ Name: 'email', Sequence: 3, Configuration: JSON.stringify({ wireSelector: 'email', responsePath: ['email'] }) }),
];

const earnedCreditIO = makeIO({
    ID: 'io-earnedcredit', Name: 'EarnedCredit',
    Configuration: JSON.stringify({ resourceWireValue: 'earnedCredit' }),
});
const earnedCreditIOFs = [
    makeIOF({ Name: 'earning_method', Sequence: 0, Configuration: JSON.stringify({ wireSelector: 'earning_method', responsePath: ['earning_method'] }) }),
    makeIOF({ Name: 'updated_at', Type: 'Datetime', Sequence: 1, Configuration: JSON.stringify({ wireSelector: 'updated_at', responsePath: ['updated_at'] }) }),
];

/** No `resourceWireValue` anywhere — the connector must refuse rather than guess a wire value. */
const unroutableIO = makeIO({ ID: 'io-unroutable', Name: 'Unroutable', Configuration: null });

/**
 * The canonical Mocked<Connector> pattern: overrides ONLY the transport boundary (`rawRequest`) and the
 * engine-cache seams. Every Elevate behaviour under test — envelope construction, the field allow-list,
 * date-window chunking, watermark math, identity, error classification, write routing — is the REAL
 * connector code. Nothing hits a live endpoint and nothing mutates.
 */
class MockedElevateConnector extends ElevateConnector {
    public Captured: CapturedRequest[] = [];
    public Canned: CannedResponse[] = [];
    public IOFixtures = new Map<string, MJIntegrationObjectEntity>();
    public IOFFixtures = new Map<string, MJIntegrationObjectFieldEntity[]>();

    protected override async rawRequest(
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown,
    ): Promise<RESTResponse> {
        const parsedBody = body as Record<string, unknown> | undefined;
        this.Captured.push({ url, method, headers, body: parsedBody });
        const idx = this.Canned.findIndex(c => !c.match || c.match({ url, method, body: parsedBody }));
        if (idx < 0) throw new Error(`MockedElevateConnector: no canned response for ${method} ${url}`);
        const [canned] = this.Canned.splice(idx, 1);
        return canned.response;
    }

    protected override GetCachedObject(_integrationID: string, objectName: string): MJIntegrationObjectEntity {
        const io = this.IOFixtures.get(objectName);
        if (!io) throw new Error(`IntegrationObject not found: "${objectName}"`);
        return io;
    }
    protected override GetCachedFields(objectID: string): MJIntegrationObjectFieldEntity[] {
        return this.IOFFixtures.get(objectID) ?? [];
    }
    protected override getCachedObjects(_integrationID: string): MJIntegrationObjectEntity[] {
        return [...this.IOFixtures.values()];
    }
    protected override tryGetIntegrationID(): string | null {
        return 'int-elevate';
    }

    // ── Public seams for direct unit assertions ──
    public PublicNormalize(body: unknown, key: string | null): Record<string, unknown>[] {
        return this.NormalizeResponse(body, key);
    }
    public PublicBuildHeaders(auth: RESTAuthContext): Record<string, string> {
        return this.BuildHeaders(auth);
    }
    public PublicAuthenticate(ci: MJCompanyIntegrationEntity): Promise<RESTAuthContext> {
        return this.Authenticate(ci, contextUser);
    }
    public PublicGetBaseURL(ci: MJCompanyIntegrationEntity, auth: RESTAuthContext): string {
        return this.GetBaseURL(ci, auth);
    }
    public PublicExtractPagination(body: unknown, type: PaginationType): { HasMore: boolean } {
        return this.ExtractPaginationInfo(body, type, 1, 0, 50);
    }
    /** The last request body the connector actually put on the wire. */
    public LastBody(): Record<string, unknown> {
        return this.Captured[this.Captured.length - 1].body as Record<string, unknown>;
    }
    /** Every `fields` allow-list the connector sent, in order. */
    public SelectorsSent(): string[][] {
        return this.Captured
            .filter(c => c.body != null && typeof c.body.fields === 'object')
            .map(c => Object.keys(c.body!.fields as Record<string, boolean>));
    }
}

const contextUser = { ID: 'test', Email: 'test@example.com', Name: 'test' } as unknown as Parameters<ElevateConnector['TestConnection']>[1];
const FIXTURE_KEY = 'fixture-placeholder-not-a-real-credential';

/** Reads a captured window filter back to [fromDay, toDay] from the vendor's operator form. */
function windowDays(r: CapturedRequest, field: string): [string, string] {
    const f = (r.body as { filters: Record<string, Record<string, string>> }).filters[field];
    return [f['>='].slice(0, 10), f['<='].slice(0, 10)];
}

function makeCI(configuration: Record<string, unknown>): MJCompanyIntegrationEntity {
    return {
        ID: 'ci-elevate',
        IntegrationID: 'int-elevate',
        Name: 'elevate',
        CredentialID: null,
        Configuration: JSON.stringify(configuration),
    } as unknown as MJCompanyIntegrationEntity;
}

const baseConfig = { siteUrl: 'https://learn.example.org', apiKey: FIXTURE_KEY };

function ok(body: unknown, headers: Record<string, string> = {}): RESTResponse {
    return { Status: 200, Body: body, Headers: headers };
}

function makeConnector(objects: Array<[MJIntegrationObjectEntity, MJIntegrationObjectFieldEntity[]]>): MockedElevateConnector {
    const c = new MockedElevateConnector();
    for (const [io, iofs] of objects) {
        c.IOFixtures.set(io.Name, io);
        c.IOFFixtures.set(io.ID, iofs);
    }
    return c;
}

function fetchCtx(ci: MJCompanyIntegrationEntity, objectName: string, over: Partial<FetchContext> = {}): FetchContext {
    return {
        CompanyIntegration: ci,
        ObjectName: objectName,
        WatermarkValue: null,
        BatchSize: 100,
        ContextUser: contextUser,
        ...over,
    } as FetchContext;
}

// ─── Tests ────────────────────────────────────────────────────────────────────

describe('ElevateConnector — identity and declared capabilities', () => {
    it('returns the verbatim MJ: Integrations.Name from the IntegrationName getter', () => {
        expect(new ElevateConnector().IntegrationName).toBe('elevate');
    });

    it('declares create and delete but NOT update — no update endpoint exists for any resource', () => {
        const c = new ElevateConnector();
        expect(c.SupportsCreate).toBe(true);
        expect(c.SupportsDelete).toBe(true);
        expect(c.SupportsUpdate).toBe(false);
    });

    it('never claims authoritative discovery — absence proves nothing without a describe endpoint', () => {
        expect(new ElevateConnector().DiscoveryIsAuthoritative).toBe(false);
    });

    it('publishes a conservative rate policy and single concurrency (limit exists, numbers do not)', () => {
        const c = new ElevateConnector();
        expect(c.RateLimitPolicy?.TokensPerSec).toBeGreaterThan(0);
        expect(c.RateLimitPolicy?.TokensPerSec).toBeLessThan(0.3);
        expect(c.MaxConcurrencyHint).toBe(1);
    });

    it('reads StableOrderingKey from metadata only — withdrawn keys stay null', () => {
        const c = makeConnector([[productIO, productIOFs], [userIO, userIOFs]]);
        expect(c.StableOrderingKey('Product')).toBe('id');
        expect(c.StableOrderingKey('User')).toBeNull();
    });
});

describe('ElevateConnector — the POST envelope read path', () => {
    let connector: MockedElevateConnector;
    let ci: MJCompanyIntegrationEntity;

    beforeEach(() => {
        connector = makeConnector([[productIO, productIOFs]]);
        ci = makeCI(baseConfig);
    });

    it('POSTs the { api_key, format, resource, fields } envelope to the ONE door, not a GET list', async () => {
        connector.Canned.push({ response: ok(envelope(productRows, productLabels)) });
        await connector.FetchChanges(fetchCtx(ci, 'Product'));

        const req = connector.Captured[0];
        expect(req.method).toBe('POST');
        expect(req.url).toBe('https://learn.example.org/api/reports');
        expect(req.body).toMatchObject({ api_key: FIXTURE_KEY, format: 'json', resource: 'product' });
        expect(Object.keys(req.body!.fields as Record<string, boolean>).sort())
            .toEqual(['id', 'remote_accounting_code', 'title']);
        expect(Object.values(req.body!.fields as Record<string, boolean>).every(v => v === true)).toBe(true);
    });

    it('routes the resource wire value FROM METADATA and refuses to guess when it is absent', async () => {
        const c = makeConnector([[unroutableIO, []]]);
        await expect(c.FetchChanges(fetchCtx(ci, 'Unroutable')))
            .rejects.toThrow(/Configuration\.resourceWireValue/);
        expect(c.Captured).toHaveLength(0);
    });

    // A RUNTIME-DISCOVERED object has no declared Configuration at all — DiscoverObjects learns it
    // from this site's /api/reports page and can only report its name. Before the catalog became a
    // wire-value source, every such object was born unqueryable: FetchChanges threw, no fields were
    // ever learned, and it appeared in the table picker as "No fields found for this table" with no
    // way to ever sync it. That was all 18 discovered objects on a live tenant while the 5 declared
    // ones worked, which is what made it look like discovery had failed.
    describe('the catalog as a wire-value source', () => {
        const catalogIO = makeIO({ ID: 'io-quizaccess', Name: 'quizAccess', Configuration: null });
        const catalogIOFs = [
            makeIOF({ Name: 'id', Sequence: 0, IsPrimaryKey: true, Configuration: JSON.stringify({ wireSelector: 'id', responsePath: ['id'] }) }),
        ];
        const seedCatalog = (c: MockedElevateConnector, names: string[]): void => {
            (c as unknown as { catalogPage: Map<string, Array<{ Name: string; Fields: []; Relations: [] }>> })
                .catalogPage.set(ci.ID, names.map(n => ({ Name: n, Fields: [], Relations: [] })));
        };

        it('queries a discovered object using the resource name the site itself published', async () => {
            const c = makeConnector([[catalogIO, catalogIOFs]]);
            seedCatalog(c, ['quizAccess', 'surveyResult']);
            c.Canned.push({ response: ok(envelope([], { id: 'ID' })) });

            await c.FetchChanges(fetchCtx(ci, 'quizAccess'));

            expect(c.Captured).toHaveLength(1);
            expect((c.Captured[0].body as { resource?: string }).resource).toBe('quizAccess');
        });

        it('sends the catalog\'s EXACT spelling, not the object\'s casing', async () => {
            // The wire value is what the site said. Matching is case-insensitive so a differently-
            // cased IntegrationObject still routes, but the string sent is the catalog's.
            const c = makeConnector([[makeIO({ ID: 'io-qa2', Name: 'QuizAccess', Configuration: null }), catalogIOFs]]);
            seedCatalog(c, ['quizAccess']);
            c.Canned.push({ response: ok(envelope([], { id: 'ID' })) });

            await c.FetchChanges(fetchCtx(ci, 'QuizAccess'));

            expect((c.Captured[0].body as { resource?: string }).resource).toBe('quizAccess');
        });

        it('still refuses an object the catalog does not list', async () => {
            // The refusal exists because the vendor's prose spells the accounting resource
            // "accountCode" and that is rejected with HTTP 500 — only "accountingCode" works. A name
            // absent from the catalog is exactly that kind of unproven guess and must stay refused.
            const c = makeConnector([[unroutableIO, []]]);
            seedCatalog(c, ['quizAccess']);
            await expect(c.FetchChanges(fetchCtx(ci, 'Unroutable')))
                .rejects.toThrow(/Configuration\.resourceWireValue/);
            expect(c.Captured).toHaveLength(0);
        });

        it('refuses when no catalog has been read for this connection', async () => {
            const c = makeConnector([[catalogIO, catalogIOFs]]);
            await expect(c.FetchChanges(fetchCtx(ci, 'quizAccess')))
                .rejects.toThrow(/Configuration\.resourceWireValue/);
        });

        it('never lets the catalog override a declared wire value', async () => {
            // Declared stays authoritative: the catalog is the THIRD source, consulted only when the
            // declaration is silent.
            const c = makeConnector([[productIO, productIOFs]]);
            seedCatalog(c, ['somethingElse', 'Product']);
            c.Canned.push({ response: ok(envelope([], { id: 'ID' })) });

            await c.FetchChanges(fetchCtx(ci, 'Product'));

            expect((c.Captured[0].body as { resource?: string }).resource).toBe('product');
        });
    });

    it('falls back to the depth-0 access path body selector — still metadata, never a literal in code', async () => {
        const io = makeIO({
            ID: 'io-ac', Name: 'AccountingCode',
            Configuration: JSON.stringify({
                accessPaths: [{ door: '/api/reports', method: 'POST', body: { resource: 'accountingCode' }, nesting: [], depth: 0 }],
            }),
        });
        const c = makeConnector([[io, [makeIOF({ Name: 'id', Type: 'Integer' })]]]);
        c.Canned.push({ response: ok(envelope([{ id: 4100 }], { id: 'Accounting Code ID' })) });
        await c.FetchChanges(fetchCtx(ci, 'AccountingCode'));
        expect(c.LastBody().resource).toBe('accountingCode');
    });

    it('asks for DOT-PATH wire selectors, not the flattened MJ column names', async () => {
        const c = makeConnector([[registrationIO, registrationIOFs]]);
        c.Canned.push({ response: ok(envelope(registrationRows, registrationLabels)) });
        await c.FetchChanges(fetchCtx(c1(ci), 'ProductRegistration'));
        const selectors = Object.keys(c.LastBody().fields as Record<string, boolean>);
        expect(selectors).toContain('product.title');
        expect(selectors).toContain('user.member_id');
        expect(selectors).toContain('payment.card_partial');
        expect(selectors).not.toContain('product_title');
        expect(selectors).not.toContain('payment_card_partial');
    });

    it('EXCLUDES write-only columns from the read allow-list (registration_id would fail the whole query)', async () => {
        const c = makeConnector([[registrationIO, registrationIOFs]]);
        c.Canned.push({ response: ok(envelope(registrationRows, registrationLabels)) });
        await c.FetchChanges(fetchCtx(c1(ci), 'ProductRegistration'));
        const selectors = Object.keys(c.LastBody().fields as Record<string, boolean>);
        expect(selectors).not.toContain('registration_id');
        expect(selectors).not.toContain('remote_user_id');
    });

    it('walks the DOTTED ResponseDataKey — response.items, never the first segment only', () => {
        const rows = connector.PublicNormalize(envelope(productRows, productLabels), 'response.items');
        expect(rows).toHaveLength(2);
        expect(connector.PublicNormalize(envelope(productRows, productLabels), 'response')).toEqual([]);
    });

    it('reports no pagination — the probe decided it negative at volume, so none is invented', () => {
        expect(connector.PublicExtractPagination(envelope(productRows, productLabels), 'None').HasMore).toBe(false);
        expect(connector.PublicExtractPagination(envelope(productRows, productLabels), 'Offset').HasMore).toBe(false);
    });
});

/** ProductRegistration reads need the window config off for the un-chunked assertions. */
function c1(ci: MJCompanyIntegrationEntity): MJCompanyIntegrationEntity {
    return ci;
}

describe('ElevateConnector — the field allow-list is discovered, not frozen', () => {
    it('UNIONS runtime-discovered per-tenant columns into the request once the door has PROVEN them', async () => {
        const c = makeConnector([[earnedCreditIO, earnedCreditIOFs]]);
        const ci = makeCI(baseConfig);
        const body = envelope([{ earning_method: 'assessment', updated_at: '2025-04-01T12:00:00', credit_type_label: 'CME' }], earnedCreditLabels);
        c.Canned.push({ response: ok(body) }, { response: ok(body) }, { response: ok(body) }, { response: ok(body) });

        await c.FetchChanges(fetchCtx(ci, 'EarnedCredit'));
        expect(c.SelectorsSent()[0].sort()).toEqual(['earning_method', 'updated_at']);

        // Second pass: the door's own `response.labels` dictionary taught the connector a column the
        // declared floor never carried. It is proven OUT OF BAND first (a probe asking for JUST that
        // column, so a rejection can cost no rows) and only THEN joins the data read — a hardcoded list
        // would never ask for it at all.
        await c.FetchChanges(fetchCtx(ci, 'EarnedCredit'));
        expect(c.SelectorsSent()[1]).toEqual(['credit_type_label']);
        expect(c.SelectorsSent()[2].sort()).toEqual(['credit_type_label', 'earning_method', 'updated_at']);

        // Third pass: the proof is remembered for the connection — no second probe, straight to the read.
        await c.FetchChanges(fetchCtx(ci, 'EarnedCredit'));
        expect(c.SelectorsSent()).toHaveLength(4);
        expect(c.SelectorsSent()[3].sort()).toEqual(['credit_type_label', 'earning_method', 'updated_at']);
    });

    it('proves a learned column OUT OF BAND: a rejected label never reaches a data read, so no row is lost', async () => {
        const c = makeConnector([[earnedCreditIO, earnedCreditIOFs]]);
        const ci = makeCI(baseConfig);
        const labels = { ...earnedCreditLabels, unsupported_label_field: 'Report-only Column' };
        const good = envelope([{ earning_method: 'assessment', updated_at: '2025-04-01T12:00:00' }], labels);
        c.Canned.push(
            { response: ok(good) },
            // The door rejects the whole query for one unrecognised name — and NAMES the offender. This
            // lands on the VERIFICATION probe, which is exactly the point: the data read is never exposed.
            { response: { Status: 500, Body: { error: { message: "Field unsupported_label_field doesn't exist" } }, Headers: {} } },
            { response: ok(good) },
            { response: ok(good) },
            { response: ok(good) },
        );

        await c.FetchChanges(fetchCtx(ci, 'EarnedCredit'));                // learns the labels
        const batch = await c.FetchChanges(fetchCtx(ci, 'EarnedCredit')); // proves them, one is refused
        expect(batch.Records).toHaveLength(1);
        expect(c.SelectorsSent()[1]).toContain('unsupported_label_field');   // the probe asked
        expect(c.SelectorsSent()[2]).not.toContain('unsupported_label_field'); // the retried probe did not
        expect(c.SelectorsSent()[2]).toContain('credit_type_label');           // the good sibling survives
        expect(batch.Warnings?.some(w => w.Code === 'FIELD_REJECTED')).toBe(true);

        await c.FetchChanges(fetchCtx(ci, 'EarnedCredit'));
        expect(c.SelectorsSent()[4]).not.toContain('unsupported_label_field');

        // THE INVARIANT: no request that actually READ DATA (i.e. carried the declared columns) ever
        // carried the unproven name. A bad label cannot zero this object's sync.
        const dataReads = c.SelectorsSent().filter(sel => sel.includes('earning_method'));
        expect(dataReads.length).toBeGreaterThan(0);
        for (const sel of dataReads) expect(sel).not.toContain('unsupported_label_field');
    });

    // THE LIVE FAILURE. This door answers a bad field name with a bare HTTP 500 and NO vendor
    // message, so `Classification.UnknownField` is null and the targeted repair has nothing to
    // aim at. Before bisection the connector surrendered the whole batch on that first refusal:
    // a real tenant learned 32 columns on one object and 26 on another and verified NONE of them,
    // every run, because the same few unusable names poisoned the same batch each time.
    it('isolates the offender by bisection when the door refuses WITHOUT naming a field', async () => {
        const c = makeConnector([[earnedCreditIO, earnedCreditIOFs]]);
        const ci = makeCI(baseConfig);
        const labels = { ...earnedCreditLabels, good_one: 'Good', bad_one: 'Rollup', good_two: 'Also Good' };
        const good = envelope([{ earning_method: 'assessment', updated_at: '2025-04-01T12:00:00' }], labels);
        const blind500 = { Status: 500, Body: {}, Headers: {} };

        c.Canned.push(
            { response: ok(good) },                                            // learn the labels
            // Any probe carrying `bad_one` fails, unattributed. Everything else succeeds.
            { match: ({ body }) => JSON.stringify((body as Record<string, unknown>)?.fields ?? {}).includes('bad_one'), response: blind500 },
            { match: ({ body }) => JSON.stringify((body as Record<string, unknown>)?.fields ?? {}).includes('bad_one'), response: blind500 },
            { match: ({ body }) => JSON.stringify((body as Record<string, unknown>)?.fields ?? {}).includes('bad_one'), response: blind500 },
            { match: ({ body }) => JSON.stringify((body as Record<string, unknown>)?.fields ?? {}).includes('bad_one'), response: blind500 },
            { response: ok(good) }, { response: ok(good) }, { response: ok(good) },
            { response: ok(good) }, { response: ok(good) }, { response: ok(good) },
        );

        await c.FetchChanges(fetchCtx(ci, 'EarnedCredit'));
        const batch = await c.FetchChanges(fetchCtx(ci, 'EarnedCredit'));

        // The offender was asked for ALONE at some point — that is what isolation means.
        const solo = c.SelectorsSent().filter(sel => sel.length === 1 && sel[0] === 'bad_one');
        expect(solo.length).toBeGreaterThan(0);
        expect(batch.Warnings?.some(w => w.Code === 'FIELD_REJECTED')).toBe(true);

        // And the good siblings were NOT discarded with it — the whole point.
        await c.FetchChanges(fetchCtx(ci, 'EarnedCredit'));
        const later = c.SelectorsSent()[c.SelectorsSent().length - 1];
        expect(later).toContain('good_one');
        expect(later).toContain('good_two');
        expect(later).not.toContain('bad_one');
    });

    it('never lets an unproven name reach a data read, even while bisecting', async () => {
        const c = makeConnector([[earnedCreditIO, earnedCreditIOFs]]);
        const ci = makeCI(baseConfig);
        const labels = { ...earnedCreditLabels, bad_one: 'Rollup' };
        const good = envelope([{ earning_method: 'assessment', updated_at: '2025-04-01T12:00:00' }], labels);
        const blind = { match: ({ body }: { body?: Record<string, unknown> }) => JSON.stringify(body?.fields ?? {}).includes('bad_one'), response: { Status: 500, Body: {}, Headers: {} } };
        // The offender fails EVERY time it is asked for, including alone — that is what makes it
        // the offender. Canning a single failure would let the isolation probe succeed and prove
        // the opposite of the thing under test.
        c.Canned.push(
            { response: ok(good) },
            blind, blind, blind, blind,
            { response: ok(good) }, { response: ok(good) }, { response: ok(good) },
        );
        await c.FetchChanges(fetchCtx(ci, 'EarnedCredit'));
        await c.FetchChanges(fetchCtx(ci, 'EarnedCredit'));

        // A DATA read is one carrying the declared columns. None may carry an unproven name.
        const dataReads = c.SelectorsSent().filter(sel => sel.includes('earning_method'));
        expect(dataReads.length).toBeGreaterThan(0);
        for (const sel of dataReads) expect(sel).not.toContain('bad_one');
    });

    it('fails FAST when the door names a column the request never sent — it does not replay the same call', async () => {
        const c = makeConnector([[productIO, productIOFs]]);
        const ci = makeCI(baseConfig);
        // An error-in-a-200 naming a field that is NOT in this request's allow-list. Dropping it changes
        // no byte of the envelope, so a repair retry could only replay an identical, already-failed call
        // against a rate-limited door until the repair budget ran out.
        c.Canned.push({ response: ok({ error: { message: "Field never_requested_column doesn't exist" } }) });

        await expect(c.FetchChanges(fetchCtx(ci, 'Product'))).rejects.toThrow(/NOT in this request's `fields` allow-list/);
        expect(c.Captured).toHaveLength(1);
    });

    it('narrows the allow-list to the engine-requested source fields when it supplies them', async () => {
        const c = makeConnector([[productIO, productIOFs]]);
        const ci = makeCI(baseConfig);
        c.Canned.push({ response: ok(envelope(productRows, productLabels)) });
        await c.FetchChanges(fetchCtx(ci, 'Product', { RequestedSourceFields: ['id', 'title'] }));
        expect(Object.keys(c.LastBody().fields as Record<string, boolean>).sort()).toEqual(['id', 'title']);
    });

    it('refuses to read an object with no read-surface column rather than sending a fieldless query', async () => {
        const io = makeIO({ ID: 'io-empty', Name: 'Empty', Configuration: JSON.stringify({ resourceWireValue: 'empty' }) });
        const c = makeConnector([[io, [makeIOF({ Name: 'w', Configuration: JSON.stringify({ surface: 'write-only' }) })]]]);
        await expect(c.FetchChanges(fetchCtx(makeCI(baseConfig), 'Empty'))).rejects.toThrow(/No read-surface columns/);
    });
});

describe('ElevateConnector — format', () => {
    it('defaults to json', async () => {
        const c = makeConnector([[productIO, productIOFs]]);
        c.Canned.push({ response: ok(envelope(productRows, productLabels)) });
        await c.FetchChanges(fetchCtx(makeCI(baseConfig), 'Product'));
        expect(c.LastBody().format).toBe('json');
    });

    it('REFUSES csv when the selection uses dot-paths — csv is flat and would drop every sub-column', async () => {
        const c = makeConnector([[registrationIO, registrationIOFs]]);
        c.Canned.push({ response: ok(envelope(registrationRows, registrationLabels)) });
        await c.FetchChanges(fetchCtx(makeCI({ ...baseConfig, elevateFormat: 'csv' }), 'ProductRegistration'));
        expect(c.LastBody().format).toBe('json');
    });

    it('honours csv only when the caller asks AND every selector is flat', async () => {
        const c = makeConnector([[productIO, productIOFs]]);
        c.Canned.push({ response: ok(envelope(productRows, productLabels)) });
        await c.FetchChanges(fetchCtx(makeCI({ ...baseConfig, elevateFormat: 'csv' }), 'Product'));
        expect(c.LastBody().format).toBe('csv');
    });
});

describe('ElevateConnector — date-windowed bulk extraction', () => {
    const windowed = { ...baseConfig, elevateWindowStart: '2025-01-01', elevateWindowEnd: '2026-12-31', elevateWindowDays: 365 };

    it('chunks into CONSECUTIVE, NON-OVERLAPPING windows on the declared watermark field', async () => {
        const c = makeConnector([[registrationIO, registrationIOFs]]);
        c.Canned.push(
            { response: ok(envelope(registrationRows, registrationLabels)) },
            { response: ok(envelope([{ ...registrationRows[0], transaction_at: '2026-02-10T08:15:00', modified_at: '2026-02-10T08:16:00' }], registrationLabels)) },
        );
        const batch = await c.FetchChanges(fetchCtx(makeCI(windowed), 'ProductRegistration'));

        expect(c.Captured).toHaveLength(2);
        // The vendor's own documented filter form: operator keys with full datetimes. The old
        // { date: [from, to] } shape matched NOTHING on the wire — zero rows on 29k-row tables, live.
        expect(c.Captured[0].body!.filters).toEqual({ modified_at: { '>=': '2025-01-01 00:00:00', '<=': '2025-12-31 23:59:59' } });
        expect(c.Captured[1].body!.filters).toEqual({ modified_at: { '>=': '2026-01-01 00:00:00', '<=': '2026-12-31 23:59:59' } });
        expect(batch.Records).toHaveLength(2);
        expect(batch.HasMore).toBe(false);
    });

    it('never windows an object whose metadata declares no watermark, even when window config is present', async () => {
        const c = makeConnector([[productIO, productIOFs]]);
        c.Canned.push({ response: ok(envelope(productRows, productLabels)) });
        await c.FetchChanges(fetchCtx(makeCI(windowed), 'Product'));
        expect(c.Captured).toHaveLength(1);
        expect(c.LastBody().filters).toBeUndefined();
    });

    it('SPLITS a window adaptively when the door reports more rows than it returned', async () => {
        const c = makeConnector([[registrationIO, registrationIOFs]]);
        const truncated = envelope(registrationRows, registrationLabels, 9_999);
        c.Canned.push(
            { response: ok(truncated) },                                    // 2025 window: truncated
            { response: ok(envelope(registrationRows, registrationLabels)) }, // first half: complete
            { response: ok(envelope(registrationRows, registrationLabels)) }, // second half: complete
            { response: ok(envelope(registrationRows, registrationLabels)) }, // 2026 window: complete
        );
        const batch = await c.FetchChanges(fetchCtx(makeCI(windowed), 'ProductRegistration'));

        expect(c.Captured).toHaveLength(4);
        const halves = [c.Captured[1], c.Captured[2]].map(r => windowDays(r, 'modified_at'));
        expect(halves[0][0]).toBe('2025-01-01');
        expect(halves[1][1]).toBe('2025-12-31');
        // The halves meet without a gap and without an overlap.
        expect(new Date(halves[1][0]).getTime() - new Date(halves[0][1]).getTime()).toBe(86_400_000);
        expect((batch.Warnings ?? []).some(w => w.Code === 'INCOMPLETE_READ')).toBe(false);
    });

    it('stops at BatchSize and hands back a resume cursor the engine feeds to the next call', async () => {
        const c = makeConnector([[registrationIO, registrationIOFs]]);
        c.Canned.push({ response: ok(envelope(registrationRows, registrationLabels)) });
        const first = await c.FetchChanges(fetchCtx(makeCI(windowed), 'ProductRegistration', { BatchSize: 1 }));
        expect(first.HasMore).toBe(true);
        expect(first.NextAfterKeyValue).toBe('2026-01-01');

        c.Canned.push({ response: ok(envelope(registrationRows, registrationLabels)) });
        const second = await c.FetchChanges(fetchCtx(makeCI(windowed), 'ProductRegistration', { BatchSize: 1, AfterKeyValue: first.NextAfterKeyValue }));
        expect(windowDays(c.Captured[1], 'modified_at')[0]).toBe('2026-01-01');
        expect(second.HasMore).toBe(false);
    });

    it('CONTINUES on the window plan when the engine hands back a resume cursor, never restarting the range', async () => {
        const c = makeConnector([[registrationIO, registrationIOFs]]);
        c.Canned.push({ response: ok(envelope(registrationRows, registrationLabels)) });
        // No explicit window config: a single remaining chunk would normally collapse to one `>=` query,
        // which on a RESUME would re-read the whole range from the original watermark.
        await c.FetchChanges(fetchCtx(makeCI(baseConfig), 'ProductRegistration', {
            WatermarkValue: '2026-08-01T00:00:00', AfterKeyValue: '2026-08-20',
        }));
        // Intent preserved in the vendor's wire form: the resume chunk is BOUNDED (has an upper
        // bound) and starts at the cursor — never an open-ended >= from the original watermark.
        const filters = c.LastBody().filters as Record<string, Record<string, string>>;
        expect(filters.modified_at['>=']).toBe('2026-08-20 00:00:00');
        expect(filters.modified_at['<=']).toBeDefined();
    });

    it('raises INCOMPLETE_READ when an UNCHUNKABLE object comes back truncated — never a silent success', async () => {
        const c = makeConnector([[productIO, productIOFs]]);
        c.Canned.push({ response: ok(envelope(productRows, productLabels, 50_000)) });
        const batch = await c.FetchChanges(fetchCtx(makeCI(baseConfig), 'Product'));
        const warn = batch.Warnings?.find(w => w.Code === 'INCOMPLETE_READ');
        expect(warn).toBeDefined();
        expect(warn?.Data).toMatchObject({ reportedCount: 50_000, returnedCount: 2 });
    });
});

describe('ElevateConnector — incremental sync', () => {
    it('sends ONE precise >= filter on the DECLARED watermark for a short delta, and reports the max SEEN value', async () => {
        const c = makeConnector([[registrationIO, registrationIOFs]]);
        const yesterday = new Date(Date.now() - 86_400_000).toISOString();
        const rows = [
            { ...registrationRows[0], modified_at: '2025-03-05T09:00:00' },
            { ...registrationRows[0], modified_at: '2025-09-01T00:00:00' },
            { ...registrationRows[0], modified_at: '2025-06-01T00:00:00' },
        ];
        c.Canned.push({ response: ok(envelope(rows, registrationLabels)) });
        const batch = await c.FetchChanges(fetchCtx(makeCI(baseConfig), 'ProductRegistration', { WatermarkValue: yesterday }));

        expect(c.Captured).toHaveLength(1);
        // Sub-day precision is PRESERVED: a short delta is not rounded down to a whole-day window.
        expect(c.LastBody().filters).toEqual({ modified_at: { '>=': yesterday } });
        expect(batch.NewWatermarkValue).toBe('2025-09-01T00:00:00');
    });

    it('CHUNKS a long catch-up from the watermark rather than issuing one unbounded query', async () => {
        const c = makeConnector([[registrationIO, registrationIOFs]]);
        c.Canned.push({ response: ok(envelope(registrationRows, registrationLabels)) });
        for (let i = 0; i < 20; i++) c.Canned.push({ response: ok(envelope([], registrationLabels)) });
        await c.FetchChanges(fetchCtx(makeCI(baseConfig), 'ProductRegistration', { WatermarkValue: '2020-01-01T00:00:00' }));

        expect(c.Captured.length).toBeGreaterThan(1);
        const spans = c.Captured.map(r => windowDays(r, 'modified_at'));
        expect(spans[0][0]).toBe('2020-01-01');
        for (let i = 1; i < spans.length; i++) {
            // consecutive and non-overlapping: each window starts the day after the previous one ended
            expect(new Date(spans[i][0]).getTime() - new Date(spans[i - 1][1]).getTime()).toBe(86_400_000);
        }
    });

    it('runs a FULL SCAN for an object with no declared watermark — no delta path is synthesised', async () => {
        const c = makeConnector([[userIO, userIOFs]]);
        c.Canned.push({ response: ok(envelope(userRows, { member_id: 'Member ID' })) });
        const batch = await c.FetchChanges(fetchCtx(makeCI(baseConfig), 'User', { WatermarkValue: '2025-03-01T00:00:00' }));
        expect(c.LastBody().filters).toBeUndefined();
        expect(batch.NewWatermarkValue).toBeUndefined();
    });

    it('leaves the watermark untouched when a window fails mid-iteration', async () => {
        const c = makeConnector([[registrationIO, registrationIOFs]]);
        const windowed = { ...baseConfig, elevateWindowStart: '2025-01-01', elevateWindowEnd: '2026-12-31', elevateWindowDays: 365 };
        c.Canned.push(
            { response: ok(envelope(registrationRows, registrationLabels)) },
            { response: { Status: 500, Body: { error: { message: 'Wrong resource name.' } }, Headers: {} } },
        );
        await expect(c.FetchChanges(fetchCtx(makeCI(windowed), 'ProductRegistration'))).rejects.toThrow(ElevateAPIError);
    });
});

describe('ElevateConnector — record identity and full-record pass-through', () => {
    it('uses the declared primary key when every component is populated', async () => {
        const c = makeConnector([[productIO, productIOFs]]);
        c.Canned.push({ response: ok(envelope(productRows, productLabels)) });
        const batch = await c.FetchChanges(fetchCtx(makeCI(baseConfig), 'Product'));
        expect(batch.Records.map(r => r.ExternalID)).toEqual(['101', '102']);
    });

    it('falls back to a CONTENT HASH for a demoted/keyless object, including a null-key row', async () => {
        const c = makeConnector([[userIO, userIOFs]]);
        c.Canned.push({ response: ok(envelope(userRows, { member_id: 'Member ID' })) });
        const batch = await c.FetchChanges(fetchCtx(makeCI(baseConfig), 'User'));
        expect(batch.Records).toHaveLength(2);
        for (const record of batch.Records) {
            expect(record.ExternalID).toMatch(/^[0-9a-f]{64}$/);
            expect(record.Fields.ID).toBe(record.ExternalID);
        }
        expect(batch.Records[0].ExternalID).not.toBe(batch.Records[1].ExternalID);
    });

    it('keeps identity STABLE across passes when the source adds volatile bytes (the two-pass drift class)', async () => {
        const c = makeConnector([[userIO, userIOFs]]);
        const ci = makeCI(baseConfig);
        c.Canned.push({ response: ok(envelope(userRows, { member_id: 'Member ID' })) });
        const pass1 = await c.FetchChanges(fetchCtx(ci, 'User'));

        const noisy = userRows.map(r => ({ ...r, __audit_fetched_at: `${Date.now()}-${Math.random()}` }));
        c.Canned.push({ response: ok(envelope(noisy, { member_id: 'Member ID' })) });
        const pass2 = await c.FetchChanges(fetchCtx(ci, 'User'));

        expect(pass2.Records.map(r => r.ExternalID)).toEqual(pass1.Records.map(r => r.ExternalID));
        expect(pass2.Records).toHaveLength(pass1.Records.length);
    });

    it('passes the COMPLETE source row through to Fields, including undeclared per-tenant columns', async () => {
        const c = makeConnector([[registrationIO, registrationIOFs]]);
        c.Canned.push({ response: ok(envelope(registrationRows, registrationLabels)) });
        const batch = await c.FetchChanges(fetchCtx(makeCI(baseConfig), 'ProductRegistration'));
        const fields = batch.Records[0].Fields;
        expect(fields.site_custom_cohort).toBe('cohort-a');
        expect(fields.product).toEqual({ title: 'Introduction to Compliance', remote_accounting_code: 'GL-4100' });
    });

    it('back-fills the minted identity into the DECLARED PK so a read-sourced row is addressable, without changing ExternalID', async () => {
        // registration_id is the record key (the cancel API addresses one registration by it) AND is
        // unreadable through the Report door. Those two facts have to hold together: the identity the
        // connector mints for a read-sourced row must land IN the declared PK column — otherwise the
        // persisted row has a NULL key and its save cannot select itself back — while the record's
        // ExternalID stays the content hash it has always been, so stamping the PK moves no identity.
        const c = makeConnector([[registrationIO, registrationIOFs]]);
        c.Canned.push({ response: ok(envelope(registrationRows, registrationLabels)) });
        const batch = await c.FetchChanges(fetchCtx(makeCI(baseConfig), 'ProductRegistration'));
        const record = batch.Records[0];

        expect(record.ExternalID).toMatch(/^[0-9a-f]{64}$/);              // content-hash identity, unchanged
        expect(record.Fields.registration_id).toBe(record.ExternalID);    // …and it POPULATES the declared PK
        expect(registrationRows[0]).not.toHaveProperty('registration_id'); // the door never supplied it
    });

    it('projects dot-path columns onto their flat MJ column names without dropping the nested original', async () => {
        const c = makeConnector([[registrationIO, registrationIOFs]]);
        c.Canned.push({ response: ok(envelope(registrationRows, registrationLabels)) });
        const batch = await c.FetchChanges(fetchCtx(makeCI(baseConfig), 'ProductRegistration'));
        const fields = batch.Records[0].Fields;
        expect(fields.product_title).toBe('Introduction to Compliance');
        expect(fields.user_member_id).toBe('M-0001');
        expect(fields.payment_card_partial).toBe('1111');
        expect(batch.Records[0].ModifiedAt?.toISOString()).toContain('2025-03-05');
    });
});

describe('ElevateConnector — auth, base URL and credential hygiene', () => {
    it('derives the base URL from the connection siteUrl — no vendor host is baked anywhere', async () => {
        const c = makeConnector([[productIO, productIOFs]]);
        const ci = makeCI({ siteUrl: 'https://tenant-a.example.net/', apiKey: FIXTURE_KEY });
        const auth = await c.PublicAuthenticate(ci);
        expect(c.PublicGetBaseURL(ci, auth)).toBe('https://tenant-a.example.net');
    });

    it('fails loudly when the connection supplies no site URL', async () => {
        const c = makeConnector([[productIO, productIOFs]]);
        await expect(c.PublicAuthenticate(makeCI({ apiKey: FIXTURE_KEY }))).rejects.toThrow(/site URL/i);
    });

    // The connection was created through the standard credential UI, which writes the shape declared
    // by this integration's own CredentialTypeID ("API Key with Endpoint"): {apiKey, endpoint}. The
    // site root therefore arrives under `endpoint`, which was missing from the alias list — so SiteUrl
    // resolved to undefined and Authenticate threw BEFORE any HTTP call, on a connection whose key and
    // URL were both correct. ValidateResource reported that as the door rejecting the query, so a live
    // tenant read "check the site URL and the API key" while curl against the same pair returned 200.
    it('accepts the site root under `endpoint`, the key the credential type actually writes', async () => {
        const c = makeConnector([[productIO, productIOFs]]);
        const ci = makeCI({ endpoint: 'https://tenant-a.example.net', apiKey: FIXTURE_KEY });
        const auth = await c.PublicAuthenticate(ci);
        expect(c.PublicGetBaseURL(ci, auth)).toBe('https://tenant-a.example.net');
    });

    it('still prefers an explicit siteUrl when both are present', async () => {
        const c = makeConnector([[productIO, productIOFs]]);
        const ci = makeCI({ siteUrl: 'https://explicit.example.net', endpoint: 'https://fallback.example.net', apiKey: FIXTURE_KEY });
        const auth = await c.PublicAuthenticate(ci);
        expect(c.PublicGetBaseURL(ci, auth)).toBe('https://explicit.example.net');
    });

    // A tenant handed over its site URL with the door path already on it. GetBaseURL returns siteUrl
    // verbatim and JoinURL then appends /api/reports, so every call went to /api/reports/api/reports —
    // a 404/405 that ValidateResource swallows, leaving TestConnection to report "check the site URL
    // and the API key" about a key and a tenant that were both fine (86,074 rows were reachable).
    it.each([
        ['https://tenant-a.example.net/api/reports', 'the read door'],
        ['https://tenant-a.example.net/api/reports/', 'the read door with a trailing slash'],
        ['https://tenant-a.example.net/api/reports/form', 'the form variant'],
        ['https://tenant-a.example.net/api/registrations', 'the write door'],
        ['https://tenant-a.example.net/API/Reports', 'the door in a different case'],
    ])('strips a pasted door path from siteUrl: %s (%s)', async (configured) => {
        const c = makeConnector([[productIO, productIOFs]]);
        const ci = makeCI({ siteUrl: configured, apiKey: FIXTURE_KEY });
        const auth = await c.PublicAuthenticate(ci);
        expect(c.PublicGetBaseURL(ci, auth)).toBe('https://tenant-a.example.net');
    });

    it('appends the door exactly once when siteUrl already carried it', async () => {
        const c = makeConnector([[productIO, productIOFs]]);
        c.Canned.push({ response: ok(envelope(productRows, productLabels)) });
        await c.FetchChanges(fetchCtx(makeCI({ siteUrl: 'https://learn.example.org/api/reports', apiKey: FIXTURE_KEY }), 'Product'));
        expect(c.Captured[0].url).toBe('https://learn.example.org/api/reports');
    });

    // Only whole trailing segments are stripped, so a site genuinely served from a directory keeps it.
    it.each([
        'https://tenant-a.example.net/lms',
        'https://tenant-a.example.net/api/reportsdata',
        'https://tenant-a.example.net/api/reports/extra',
    ])('leaves a legitimate site path intact: %s', async (configured) => {
        const c = makeConnector([[productIO, productIOFs]]);
        const ci = makeCI({ siteUrl: configured, apiKey: FIXTURE_KEY });
        const auth = await c.PublicAuthenticate(ci);
        expect(c.PublicGetBaseURL(ci, auth)).toBe(configured);
    });

    it('fails loudly when the connection supplies no api_key', async () => {
        const c = makeConnector([[productIO, productIOFs]]);
        await expect(c.PublicAuthenticate(makeCI({ siteUrl: 'https://learn.example.org' }))).rejects.toThrow(/API key/i);
    });

    it('never puts the credential in a header — it travels in the body and nowhere else', async () => {
        const c = makeConnector([[productIO, productIOFs]]);
        const ci = makeCI(baseConfig);
        c.Canned.push({ response: ok(envelope(productRows, productLabels)) });
        await c.FetchChanges(fetchCtx(ci, 'Product'));
        const headers = c.Captured[0].headers;
        expect(JSON.stringify(headers)).not.toContain(FIXTURE_KEY);
        expect(headers.Authorization).toBeUndefined();
        expect(c.PublicBuildHeaders(await c.PublicAuthenticate(ci))).toEqual({
            'Content-Type': 'application/json', 'Accept': 'application/json',
        });
    });

    it('redacts the credential out of an error message even when the vendor echoes it', async () => {
        const c = makeConnector([[productIO, productIOFs]]);
        // An UNEXPLAINED 500 gets one bounded retry, so the failure must be durable: two canned copies.
        const echo = { response: { Status: 500, Body: { error: { message: `bad key ${FIXTURE_KEY}` } }, Headers: {} } };
        c.Canned.push(echo, echo, echo, echo);
        await expect(c.FetchChanges(fetchCtx(makeCI(baseConfig), 'Product')))
            .rejects.toThrow(/\*\*\*/);
        await expect(c.FetchChanges(fetchCtx(makeCI(baseConfig), 'Product')).catch(e => { throw new Error(String((e as Error).message)); }))
            .rejects.not.toThrow(new RegExp(FIXTURE_KEY));
    });
});

describe('ElevateConnector — error classification', () => {
    let connector: MockedElevateConnector;

    beforeEach(() => { connector = makeConnector([[productIO, productIOFs]]); });

    it('treats an error envelope carried by an HTTP 200 as a FAILURE, not a successful empty read', async () => {
        connector.Canned.push({ response: ok({ error: { message: 'Something went wrong' } }) });
        await expect(connector.FetchChanges(fetchCtx(makeCI(baseConfig), 'Product'))).rejects.toThrow(ElevateAPIError);
    });

    it('classifies a 2xx error_messages write envelope as a failure too', () => {
        const c = connector.ClassifyElevateResponse(200, { error_messages: { product: 'The requested product could not be found.' } });
        expect(c.IsError).toBe(true);
        expect(c.Retryable).toBe(false);
    });

    it('NEVER retries a 500 — this door returns 500 for client-side mistakes', async () => {
        connector.Canned.push({ response: { Status: 500, Body: { error: { message: 'Wrong resource name.' } }, Headers: {} } });
        await expect(connector.FetchChanges(fetchCtx(makeCI(baseConfig), 'Product'))).rejects.toThrow(ElevateAPIError);
        expect(connector.Captured).toHaveLength(1);
    });

    it('requests only requestable names — an embedded-only column stays OUT of the allow-list but IN the record', async () => {
        // The door RETURNS more than it ACCEPTS: row-embedded aggregates (products_labels_*) are
        // real columns but naming one in `fields` draws a 500. Persisted embedded-only columns must
        // therefore never re-enter the request — while their data still arrives in the raw row.
        const embeddedIOF = makeIOF({
            Name: 'categories_labels_sum5', Sequence: 99, MetadataSource: 'Discovered',
            Configuration: JSON.stringify({ wireSelector: 'categories_labels_sum5', responsePath: ['categories_labels_sum5'] }),
        });
        const c = makeConnector([[productIO, [...productIOFs, embeddedIOF]]]);
        const ci = makeCI(baseConfig);
        (c as unknown as { catalogPage: Map<string, Array<{ Name: string; Fields: Array<{ Name: string }>; Relations: string[] }>> })
            .catalogPage.set(ci.ID, [{ Name: 'product', Fields: productIOFs.map(f => ({ Name: f.Name })), Relations: [] }]);
        const rowWithEmbedded = productRows.map(r => ({ ...r, categories_labels_sum5: 7 }));
        c.Canned.push({ response: ok(envelope(rowWithEmbedded, productLabels)) });
        const batch = await c.FetchChanges(fetchCtx(ci, 'Product'));
        const sent = c.Captured[0].body as { fields: Record<string, boolean> };
        expect(Object.keys(sent.fields)).not.toContain('categories_labels_sum5');
        expect(Object.keys(sent.fields)).toContain('id');
        expect(batch.Records[0].Fields['categories_labels_sum5']).toBe(7);
    });

    it('retries an UNEXPLAINED 500 exactly once — heavy reports flake', async () => {
        // Live: the same EarnedCredit query answered 71k rows one day and 500 (no message) the next.
        connector.Canned.push(
            { response: { Status: 500, Body: {}, Headers: {} } },
            { response: ok(envelope(productRows, productLabels)) },
        );
        const batch = await connector.FetchChanges(fetchCtx(makeCI(baseConfig), 'Product'));
        expect(batch.Records.length).toBeGreaterThan(0);
        expect(connector.Captured).toHaveLength(2);
    });

    it('a second unexplained 500 propagates after chunked salvage also fails — the retry is bounded', async () => {
        // full request 500s, the bounded retry 500s, then salvage tries each column alone
        // ([id,remote_accounting_code] and [id,title]) — both die too, both get quarantined,
        // salvage yields nothing, and the ORIGINAL error still propagates.
        connector.Canned.push(
            { response: { Status: 500, Body: {}, Headers: {} } },
            { response: { Status: 500, Body: {}, Headers: {} } },
            { response: { Status: 500, Body: {}, Headers: {} } },
            { response: { Status: 500, Body: {}, Headers: {} } },
        );
        await expect(connector.FetchChanges(fetchCtx(makeCI(baseConfig), 'Product'))).rejects.toThrow(ElevateAPIError);
        expect(connector.Captured).toHaveLength(4);
    });

    it('an unfetchable full report is salvaged in PK-joined field chunks', async () => {
        // Live: a site whose report cost is additive per column and whose proxy kills slow reports —
        // the full allow-list dies with an EMPTY 500 while every subset answers fine.
        const isChunk = (fields: string[]) => (req: { body: Record<string, unknown> | undefined }) => {
            const sent = Object.keys((req.body?.fields as Record<string, boolean>) ?? {});
            return fields.every(f => sent.includes(f)) && sent.length === fields.length;
        };
        connector.Canned.push(
            { response: { Status: 500, Body: {}, Headers: {} } },
            { response: { Status: 500, Body: {}, Headers: {} } },
            {
                match: isChunk(['id', 'remote_accounting_code']),
                response: ok(envelope(productRows.map(r => ({ id: r.id, remote_accounting_code: r.remote_accounting_code })), productLabels)),
            },
            {
                match: isChunk(['id', 'title']),
                response: ok(envelope(productRows.map(r => ({ id: r.id, title: r.title })), productLabels)),
            },
        );
        const batch = await connector.FetchChanges(fetchCtx(makeCI(baseConfig), 'Product'));
        expect(batch.Records).toHaveLength(2);
        const one = batch.Records.find(r => r.Fields['id'] === 101);
        expect(one?.Fields['title']).toBe('Introduction to Compliance');
        expect(one?.Fields['remote_accounting_code']).toBe('GL-4100');
        // every chunk request carried the PK — the join key
        for (const sent of connector.SelectorsSent().slice(2)) expect(sent).toContain('id');
        expect(connector.Captured).toHaveLength(4);
    });

    it('a column whose report dies even alone is quarantined and the rest of the object still lands', async () => {
        const hasField = (f: string) => (req: { body: Record<string, unknown> | undefined }) =>
            Object.keys((req.body?.fields as Record<string, boolean>) ?? {}).includes(f);
        connector.Canned.push(
            { response: { Status: 500, Body: {}, Headers: {} } },
            { response: { Status: 500, Body: {}, Headers: {} } },
            {
                match: hasField('remote_accounting_code'),
                response: ok(envelope(productRows.map(r => ({ id: r.id, remote_accounting_code: r.remote_accounting_code })), productLabels)),
            },
            { match: hasField('title'), response: { Status: 500, Body: {}, Headers: {} } },
        );
        const batch = await connector.FetchChanges(fetchCtx(makeCI(baseConfig), 'Product'));
        expect(batch.Records).toHaveLength(2);
        expect(batch.Records[0].Fields['remote_accounting_code']).toBeDefined();
        expect(batch.Records[0].Fields['title']).toBeUndefined();
    });

    it('a keyless object refuses chunk salvage — row order across reports is not a contract', async () => {
        const keylessIOFs = productIOFs.map(f => makeIOF({
            Name: f.Name, Sequence: f.Sequence, Configuration: f.Configuration,
        }));
        const c = makeConnector([[productIO, keylessIOFs]]);
        c.Canned.push(
            { response: { Status: 500, Body: {}, Headers: {} } },
            { response: { Status: 500, Body: {}, Headers: {} } },
        );
        await expect(c.FetchChanges(fetchCtx(makeCI(baseConfig), 'Product'))).rejects.toThrow(ElevateAPIError);
        expect(c.Captured).toHaveLength(2); // no chunk requests were attempted
    });

    it('the proven chunk plan is replayed on the next fetch — no doomed full request first', async () => {
        const isChunk = (fields: string[]) => (req: { body: Record<string, unknown> | undefined }) => {
            const sent = Object.keys((req.body?.fields as Record<string, boolean>) ?? {});
            return fields.every(f => sent.includes(f)) && sent.length === fields.length;
        };
        const chunkResponses = () => [
            {
                match: isChunk(['id', 'remote_accounting_code']),
                response: ok(envelope(productRows.map(r => ({ id: r.id, remote_accounting_code: r.remote_accounting_code })), productLabels)),
            },
            {
                match: isChunk(['id', 'title']),
                response: ok(envelope(productRows.map(r => ({ id: r.id, title: r.title })), productLabels)),
            },
        ];
        connector.Canned.push(
            { response: { Status: 500, Body: {}, Headers: {} } },
            { response: { Status: 500, Body: {}, Headers: {} } },
            ...chunkResponses(),
        );
        await connector.FetchChanges(fetchCtx(makeCI(baseConfig), 'Product'));
        expect(connector.Captured).toHaveLength(4);

        connector.Canned.push(...chunkResponses());
        const again = await connector.FetchChanges(fetchCtx(makeCI(baseConfig), 'Product'));
        expect(again.Records).toHaveLength(2);
        // exactly two more requests, both chunks — the full request was never replayed
        expect(connector.Captured).toHaveLength(6);
        for (const sent of connector.SelectorsSent().slice(4)) expect(sent.length).toBe(2);
    });

    it('classifies an unknown resource and an unknown field distinctly, naming the field', () => {
        const resource = connector.ClassifyElevateResponse(500, { error: { message: 'Wrong resource name.' } });
        expect(resource.Reason).toBe('unknown-resource');
        const field = connector.ClassifyElevateResponse(500, { error: { message: "Field payment_card_partial doesn't exist" } });
        expect(field.Reason).toBe('unknown-field-in-allow-list');
        expect(field.UnknownField).toBe('payment_card_partial');
    });

    it('treats a clean 2xx as no error at all', () => {
        expect(connector.ClassifyElevateResponse(200, envelope(productRows, productLabels)).IsError).toBe(false);
    });

    it('honours Retry-After in both the delta-seconds and the HTTP-date forms', () => {
        const seconds = new ElevateAPIError('t', 429, { 'retry-after': '12' }, connector.ClassifyElevateResponse(429, null));
        expect(connector.ExtractRetryAfterMs(seconds)).toBe(12_000);

        const when = new Date(Date.now() + 5_000).toUTCString();
        const dated = new ElevateAPIError('t', 429, { 'retry-after': when }, connector.ClassifyElevateResponse(429, null));
        expect(connector.ExtractRetryAfterMs(dated)).toBeGreaterThan(1_000);

        const notThrottled = new ElevateAPIError('t', 500, { 'retry-after': '12' }, connector.ClassifyElevateResponse(500, null));
        expect(connector.ExtractRetryAfterMs(notThrottled)).toBeUndefined();
    });

    it('surfaces a 301 from the documented trailing-slash door form instead of following it into a GET', async () => {
        connector.Canned.push({ response: { Status: 301, Body: null, Headers: { location: 'https://learn.example.org/api/reports' } } });
        await expect(connector.FetchChanges(fetchCtx(makeCI(baseConfig), 'Product'))).rejects.toThrow(/HTTP 301/);
    });
});

describe('ElevateConnector — runtime discovery is additive and never deactivating', () => {
    it('still reports a declared object whose probe was rejected', async () => {
        const c = makeConnector([[productIO, productIOFs], [userIO, userIOFs]]);
        c.Canned.push(
            { match: req => (req.body?.resource as string) === 'product', response: { Status: 500, Body: { error: { message: 'Wrong resource name.' } }, Headers: {} } },
            { response: ok(envelope(userRows, { member_id: 'Member ID' })) },
        );
        const objects = await c.DiscoverObjects(makeCI(baseConfig), contextUser);
        expect(objects.map(o => o.Name).sort()).toEqual(['Product', 'User']);
    });

    it('unions runtime-discovered columns into DiscoverFields without duplicating declared dot-paths', async () => {
        const c = makeConnector([[registrationIO, registrationIOFs]]);
        const ci = makeCI(baseConfig);
        c.Canned.push({ response: ok(envelope(registrationRows, { ...registrationLabels, site_custom_cohort: 'Cohort' })) });
        const fields = await c.DiscoverFields(ci, 'ProductRegistration', contextUser);
        const names = fields.map(f => f.Name);
        expect(names).toContain('product_title');
        expect(names).not.toContain('product.title');       // the wire alias of a declared column
        expect(names).toContain('site_custom_cohort');       // a genuine per-tenant column
        expect(fields.find(f => f.Name === 'site_custom_cohort')?.IsReadOnly).toBe(true);
    });

    it('produces byte-identical discovery on a second pass (no non-determinism)', async () => {
        const c = makeConnector([[productIO, productIOFs]]);
        const ci = makeCI(baseConfig);
        c.Canned.push({ response: ok(envelope(productRows, productLabels)) });
        const first = await c.DiscoverFields(ci, 'Product', contextUser);
        const second = await c.DiscoverFields(ci, 'Product', contextUser);
        expect(JSON.stringify(second)).toBe(JSON.stringify(first));
    });

    it('TestConnection probes a real resource and never leaks the credential into its message', async () => {
        const c = makeConnector([[productIO, productIOFs]]);
        c.Canned.push({ response: ok(envelope(productRows, productLabels)) });
        const result = await c.TestConnection(makeCI(baseConfig), contextUser);
        expect(result.Success).toBe(true);
        expect(result.Message).not.toContain(FIXTURE_KEY);
    });
});

describe('ElevateConnector — writes (generic slots, one idiosyncratic verb)', () => {
    const ci = makeCI(baseConfig);

    it('creates through the GENERIC per-operation path: flat body to the declared create path', async () => {
        const c = makeConnector([[registrationIO, registrationIOFs]]);
        c.Canned.push({ response: ok({ product_url: 'https://learn.example.org/p/101', registration_id: 55501 }) });
        const ctx: CreateRecordContext = {
            CompanyIntegration: ci, ObjectName: 'ProductRegistration', ContextUser: contextUser,
            Attributes: {
                remote_user_id: 'SSO-9', firstname: '<scrubbed-given-1>', lastname: '<scrubbed-family-1>',
                email: 'example+1@example.org', remote_product_id: '101',
            },
        };
        const result = await c.CreateRecord(ctx);

        expect(c.Captured[0].method).toBe('POST');
        expect(c.Captured[0].url).toBe('https://learn.example.org/api/registrations');
        expect(c.Captured[0].body).toMatchObject({ api_key: FIXTURE_KEY, remote_user_id: 'SSO-9', remote_product_id: '101' });
        expect(result.Success).toBe(true);
        expect(result.ExternalID).toBe('55501');
        expect(c.LastCreatedProductURLs.get('55501')).toBe('https://learn.example.org/p/101');
    });

    it('refuses to update — explicitly, without touching the network and without degrading to a create', async () => {
        const c = makeConnector([[registrationIO, registrationIOFs]]);
        const ctx: UpdateRecordContext = {
            CompanyIntegration: ci, ObjectName: 'ProductRegistration', ContextUser: contextUser,
            ExternalID: '55501', Attributes: { amount_paid: '10.00' },
        };
        const result = await c.UpdateRecord(ctx);
        expect(result.Success).toBe(false);
        expect(result.ErrorMessage).toMatch(/UPDATE_NOT_SUPPORTED/);
        expect(result.ErrorMessage).toMatch(/CONFIGURATION_ERROR/);
        expect(c.Captured).toHaveLength(0);
    });

    it('cancels with the DECLARED verb and path, carrying registration_id in the BODY', async () => {
        const c = makeConnector([[registrationIO, registrationIOFs]]);
        c.Canned.push({ response: ok({}) });
        const ctx: DeleteRecordContext = {
            CompanyIntegration: ci, ObjectName: 'ProductRegistration', ContextUser: contextUser, ExternalID: '55501',
        };
        const result = await c.DeleteRecord(ctx);

        expect(c.Captured[0].method).toBe('POST');                                   // from DeleteMethod, never assumed DELETE
        expect(c.Captured[0].url).toBe('https://learn.example.org/registrations/cancel'); // exactly as declared — no /api/ prefix
        expect(c.Captured[0].body).toEqual({ api_key: FIXTURE_KEY, registration_id: '55501' });
        expect(result.Success).toBe(true);
    });

    it('refuses to cancel when DeleteIDLocation does not NAME the body key — never guesses a field name', async () => {
        const io = makeIO({
            ...registrationIO, ID: 'io-reg-loose', Name: 'LooseRegistration',
            DeleteAPIPath: '/registrations/cancel', DeleteMethod: 'POST', DeleteIDLocation: 'body',
        } as Partial<MJIntegrationObjectEntity> & { ID: string; Name: string });
        const c = makeConnector([[io, registrationIOFs]]);
        const result = await c.DeleteRecord({
            CompanyIntegration: ci, ObjectName: 'LooseRegistration', ContextUser: contextUser, ExternalID: '55501',
        });
        expect(result.Success).toBe(false);
        expect(result.ErrorMessage).toMatch(/does not NAME the body key/);
        expect(c.Captured).toHaveLength(0);
    });

    it('refuses to cancel an object that declares no delete slot', async () => {
        const c = makeConnector([[productIO, productIOFs]]);
        const result = await c.DeleteRecord({
            CompanyIntegration: ci, ObjectName: 'Product', ContextUser: contextUser, ExternalID: '101',
        });
        expect(result.Success).toBe(false);
        expect(result.ErrorMessage).toMatch(/DELETE_NOT_SUPPORTED/);
        expect(c.Captured).toHaveLength(0);
    });
});

// EVERY object this site publishes must yield its columns, INCLUDING the ones with no
// persisted IntegrationObject — which is every runtime-discovered object, because the
// pipeline samples before it persists.
//
// The break this pins: BaseRESTIntegrationConnector.DiscoverFields opens with
// GetCachedObject, which throws "IntegrationObject not found" for exactly those objects.
// That throw escaped this method and defeated the engine's own fallback — the pipeline
// calls DiscoverFieldsViaFetch, its fetch fails on the same missing row, the engine
// catches and falls back HERE, and this rethrew. The pipeline then persisted the object
// with an EMPTY field list. On a live tenant that was 18 of 23 objects: listed in the
// picker, "No fields found for this table", permanently unsyncable.
//
// Site-agnostic by construction: the expectations below are derived from the catalog page
// alone, so any Elevate site's own page drives its own result.
describe('every catalogued object yields fields without a persisted IntegrationObject', () => {
    const CATALOG: Array<[string, number]> = [
        ['accountingCode', 1], ['cart', 5], ['category', 10], ['discountUsage', 5],
        ['earnedCredit', 27], ['liveInPerson', 12], ['package', 23], ['payment', 18],
        ['product', 23], ['productManaged', 23], ['productRegistration', 26],
        ['productType', 2], ['quiz', 11], ['quizAccess', 7], ['quizAnswer', 7],
        ['quizResult', 11], ['quizUser', 11], ['speaker', 5], ['survey', 6],
        ['surveyAnswer', 9], ['surveyResult', 8], ['user', 24], ['webContent', 10],
    ];

    const ci = makeCI(baseConfig);

    /** A connector with an EMPTY engine cache — nothing is persisted, as during discovery. */
    function unpersistedConnector(): MockedElevateConnector {
        const c = makeConnector([]);
        (c as unknown as { catalogPage: Map<string, Array<{ Name: string; Fields: Array<{ Name: string }>; Relations: string[] }>> })
            .catalogPage.set(ci.ID, CATALOG.map(([name, n]) => ({
                Name: name,
                Fields: Array.from({ length: n }, (_v, i) => ({ Name: `${name}_f${i}` })),
                Relations: [],
            })));
        return c;
    }

    it('returns the page\'s fields for ALL 23 objects, none of them persisted', async () => {
        const c = unpersistedConnector();
        const got: Array<[string, number]> = [];
        for (const [name] of CATALOG) {
            const fields = await c.DiscoverFields(ci, name, contextUser);
            got.push([name, fields.length]);
        }
        // Every object must yield at least what the page documents — none may come back empty.
        expect(got.filter(([, n]) => n === 0)).toEqual([]);
        expect(got).toEqual(CATALOG);
    });

    it('does not depend on the object name matching a declared one', async () => {
        // A site publishing a resource nobody declared still gets its columns.
        const c = makeConnector([]);
        (c as unknown as { catalogPage: Map<string, unknown> }).catalogPage.set(ci.ID, [
            { Name: 'somethingNobodyDeclared', Fields: [{ Name: 'a' }, { Name: 'b' }], Relations: [] },
        ]);
        const fields = await c.DiscoverFields(ci, 'somethingNobodyDeclared', contextUser);
        expect(fields.map(f => f.Name).sort()).toEqual(['a', 'b']);
    });

    it('still returns nothing when the site published no catalog at all', async () => {
        // No page, no persisted object → genuinely nothing to say, and it must not throw.
        const c = makeConnector([]);
        (c as unknown as { catalogPage: Map<string, unknown> }).catalogPage.set(ci.ID, null);
        await expect(c.DiscoverFields(ci, 'quizAccess', contextUser)).resolves.toEqual([]);
    });
});

// ALWAYS-STREAM. Discovery must stream records for EVERY object on first contact — including one
// that exists only in this site's /api/reports catalog, with no persisted IntegrationObject and no
// declared fields. The contract is explicit ("always do stream discovery"); the cache miss is a
// persistence-ordering detail and must not decide whether sampling happens.
//
// Before this, FetchChanges opened by throwing on exactly those objects, so the stream never ran:
// no statistical primary key, no observed widths, no data-only columns — the page's field NAMES
// were the ceiling of what discovery could ever learn about them.
describe('always-stream: FetchChanges for an object that exists only in the catalog', () => {
    const ci = makeCI(baseConfig);
    const seedPage = (c: MockedElevateConnector): void => {
        (c as unknown as { catalogPage: Map<string, unknown> }).catalogPage.set(ci.ID, [
            { Name: 'quizAccess', Fields: [{ Name: 'id' }, { Name: 'user_id' }, { Name: 'minutes_accessed' }], Relations: [] },
        ]);
    };

    it('streams records using the page\'s wire value and field selectors', async () => {
        // First contact for quizAccess itself, with the integration's declared floor present —
        // which is every real install (the metadata migration seeds it). A connector with NO
        // declared metadata at all cannot know its door; that refusal is pinned below.
        const c = makeConnector([[productIO, productIOFs]]);
        seedPage(c);
        c.Canned.push({ match: (r) => (r.body as { resource?: string })?.resource === 'quizAccess',
                        response: ok(envelope(
            [{ id: 'qa-1', user_id: 'u-1', minutes_accessed: '12' }],
            { id: 'ID', user_id: 'User', minutes_accessed: 'Minutes' }
        )) });

        const result = await c.FetchChanges(fetchCtx(ci, 'quizAccess'));

        expect(result.Records).toHaveLength(1);
        expect(result.Records[0].Fields['id']).toBe('qa-1');
        expect(c.Captured).toHaveLength(1);
        const body = c.Captured[0].body as { resource?: string; fields?: Record<string, boolean> };
        expect(body.resource).toBe('quizAccess');
        expect(Object.keys(body.fields ?? {}).sort()).toEqual(['id', 'minutes_accessed', 'user_id']);
    });

    it('a PERSISTED discovered object reads through the declared door, not its stamped APIPath', async () => {
        // Live regression: the pipeline persists runtime objects with APIPath = the bare object
        // name (the schema type carries no route), and trusting it sent every read to /cart,
        // /quiz, … — HTTP 405 on all 18 discovered tables. Provenance rules: discovered objects
        // inherit the declared access path that surfaced them.
        const poisoned = makeIO({
            ID: 'io-cart', Name: 'cart', Configuration: null,
            MetadataSource: 'Discovered', APIPath: 'cart', ResponseDataKey: '',
        });
        const poisonedIOFs = [
            makeIOF({ Name: 'id', Sequence: 0, IsPrimaryKey: true, MetadataSource: 'Discovered',
                      Configuration: JSON.stringify({ wireSelector: 'id', responsePath: ['id'] }) }),
        ];
        const c = makeConnector([[productIO, productIOFs], [poisoned, poisonedIOFs]]);
        (c as unknown as { catalogPage: Map<string, unknown> }).catalogPage.set(ci.ID, [
            { Name: 'cart', Fields: [{ Name: 'id' }], Relations: [] },
        ]);
        c.Canned.push({ match: (r) => (r.body as { resource?: string })?.resource === 'cart',
                        response: ok(envelope([{ id: 'c-1' }], { id: 'ID' })) });

        await c.FetchChanges(fetchCtx(ci, 'cart'));

        expect(c.Captured[0].url).toContain('/api/reports');
        expect(c.Captured[0].url).not.toContain('/cart');
    });

    it('REFUSES to guess a door when the integration declares no metadata at all', async () => {
        const c = makeConnector([]);   // zero declared objects — no access path to inherit
        seedPage(c);
        await expect(c.FetchChanges(fetchCtx(ci, 'quizAccess'))).rejects.toThrow(/no declared access path/);
        expect(c.Captured).toHaveLength(0);
    });

    it('borrows the door and response keys from the integration\'s declared objects', async () => {
        const c = makeConnector([[productIO, productIOFs]]);   // one declared object to borrow from
        seedPage(c);
        c.Canned.push({ match: (r) => (r.body as { resource?: string })?.resource === 'quizAccess',
                        response: ok(envelope([{ id: 'qa-2' }], { id: 'ID' })) });

        await c.FetchChanges(fetchCtx(ci, 'quizAccess'));

        expect(c.Captured[0].url).toContain('/api/reports');
    });

    it('still throws the original cache miss when the page does not list the object', async () => {
        // No page entry means there is genuinely nothing to route by — synthesis must not invent
        // a wire value, which is the guess the HTTP-500 "accountCode" spelling proved fatal.
        const c = makeConnector([]);
        seedPage(c);
        await expect(c.FetchChanges(fetchCtx(ci, 'somethingElse'))).rejects.toThrow(/not found/i);
        expect(c.Captured).toHaveLength(0);
    });
});

