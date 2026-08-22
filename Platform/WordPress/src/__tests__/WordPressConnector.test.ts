import { describe, it, expect, beforeEach } from 'vitest';
import type {
    RESTAuthContext,
    RESTResponse,
    PaginationType,
    PaginationState,
    FetchContext,
    FetchBatchResult,
    ExternalFieldSchema,
    DeleteRecordContext,
    CreateRecordContext,
    UpdateRecordContext,
} from '@memberjunction/integration-engine';
import type {
    MJCompanyIntegrationEntity,
    MJIntegrationObjectEntity,
    MJIntegrationObjectFieldEntity,
} from '@memberjunction/core-entities';
import { WordPressConnector } from '../WordPressConnector.js';

// ─── Fixtures ─────────────────────────────────────────────────────────────────
//
// PROVENANCE: spec-derived. These payloads are shaped from the version-pinned derived spec
// (WP 7.1 + WooCommerce 11.0.1 `register_routes()` / `get_item_schema()`) and from READ-ONLY
// GET/OPTIONS observations of a stock local reference instance. The RealityProbe on this
// credential-free run produced NO scrubbed captures, so nothing here is labelled
// `reference-implementation-capture`. No PII, no real tenant data, no network.

/** Site route index (`GET <apiRoot>`), trimmed to the routes these tests exercise. */
const routeIndexFixture = {
    name: 'Example Site',
    description: '',
    url: 'https://example.org',
    // `WP_REST_Server::get_index()` publishes the site's UTC offset in HOURS, credential-free.
    gmt_offset: -5,
    timezone_string: 'America/New_York',
    namespaces: ['wp/v2', 'wc/v3', 'wc-admin', 'oembed/1.0', 'mp/v1'],
    routes: {
        '/': { namespace: '', methods: ['GET'], endpoints: [{ methods: ['GET'], args: {} }] },
        '/wp/v2': { namespace: 'wp/v2', methods: ['GET'], endpoints: [{ methods: ['GET'], args: {} }] },
        '/wp/v2/posts': {
            namespace: 'wp/v2', methods: ['GET', 'POST'],
            endpoints: [{ methods: ['GET'], args: { context: {}, page: {}, per_page: {}, modified_after: {} } }],
        },
        '/wp/v2/posts/(?P<id>[\\d]+)': {
            namespace: 'wp/v2', methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
            endpoints: [{ methods: ['GET'], args: { context: {} } }],
        },
        // Per-site CUSTOM POST TYPE — present on THIS site, absent from the declared stock floor.
        '/wp/v2/mj-events': {
            namespace: 'wp/v2', methods: ['GET', 'POST'],
            endpoints: [{ methods: ['GET'], args: { context: {}, page: {}, per_page: {} } }],
        },
        '/wp/v2/mj-events/(?P<id>[\\d]+)': {
            namespace: 'wp/v2', methods: ['GET', 'POST', 'DELETE'],
            endpoints: [{ methods: ['GET'], args: { context: {} } }],
        },
        // RPC route — readable, but registers no `per_page`, so it is NOT a record collection.
        '/wp/v2/block-renderer/(?P<name>[\\w-]+)': {
            namespace: 'wp/v2', methods: ['GET', 'POST'],
            endpoints: [{ methods: ['GET'], args: { context: {} } }],
        },
        '/wc/v3/products': {
            namespace: 'wc/v3', methods: ['GET', 'POST'],
            endpoints: [{ methods: ['GET'], args: { context: {}, page: {}, per_page: {}, modified_after: {} } }],
        },
        // An OPERATOR-SCOPED-OUT first-party namespace — must never be unioned in by discovery.
        '/wc-admin/options': {
            namespace: 'wc-admin', methods: ['GET', 'POST'],
            endpoints: [{ methods: ['GET'], args: { context: {}, page: {}, per_page: {} } }],
        },
        // A THIRD-PARTY plugin namespace — the metadata says these are reachable at runtime, so DO union it.
        '/mp/v1/members': {
            namespace: 'mp/v1', methods: ['GET'],
            endpoints: [{ methods: ['GET'], args: { context: {}, page: {}, per_page: {} } }],
        },
    },
};

/** `OPTIONS /wp/v2/posts` — the real endpoint JSON Schema shape (property → type/readonly/context). */
const postsOptionsFixture = {
    namespace: 'wp/v2',
    methods: ['GET', 'POST'],
    schema: {
        $schema: 'http://json-schema.org/draft-04/schema#',
        title: 'post',
        type: 'object',
        properties: {
            id: { description: 'Unique identifier for the post.', type: 'integer', context: ['view', 'edit', 'embed'], readonly: true },
            date: { description: 'Publish date.', type: ['string', 'null'], format: 'date-time', context: ['view', 'edit'] },
            modified: { description: 'Last modified.', type: 'string', format: 'date-time', context: ['view', 'edit'], readonly: true },
            slug: { description: 'Alphanumeric identifier.', type: 'string', context: ['view', 'edit'], maxLength: 200 },
            status: { description: 'Named status.', type: 'string', context: ['view', 'edit'] },
            meta: { description: 'Meta fields.', type: 'object', context: ['view', 'edit'] },
            // A per-site custom property the DECLARED catalog never carried.
            mj_site_custom: { description: 'Registered by a site plugin.', type: 'string', context: ['view', 'edit'] },
        },
    },
};

const postsPage1 = [
    { id: 1, slug: 'a', status: 'publish', modified: '2026-01-01T00:00:00', meta: { footnotes: '' }, mj_site_custom: 'x' },
    { id: 2, slug: 'b', status: 'publish', modified: '2026-03-02T00:00:00', meta: { footnotes: '' }, mj_site_custom: 'y' },
];
const postsPage2 = [
    { id: 3, slug: 'c', status: 'publish', modified: '2026-02-01T00:00:00', meta: { footnotes: '' } },
];
const postsTrashPage = [
    { id: 9, slug: 'gone', status: 'trash', modified: '2026-04-01T00:00:00', meta: {} },
];
const productsPage = [
    { id: 71, name: 'Widget', date_modified_gmt: '2026-05-01T10:00:00', meta_data: [] },
];
const wpErrorForbiddenContext = { code: 'rest_forbidden_context', message: 'Sorry, you are not allowed to edit posts in this post type.', data: { status: 401 } };
const wpErrorNoRoute = { code: 'rest_no_route', message: 'No route was found matching the URL and request method.', data: { status: 404 } };

// ─── Test doubles ─────────────────────────────────────────────────────────────

interface CapturedRequest {
    url: string;
    method: string;
    headers: Record<string, string>;
    body: unknown;
}

/** One canned response, optionally matched to a request predicate. */
interface CannedResponse {
    match?: (req: { url: string; method: string }) => boolean;
    response: RESTResponse;
}

function makeIO(over: Partial<MJIntegrationObjectEntity> & { ID: string; Name: string }): MJIntegrationObjectEntity {
    return {
        DisplayName: over.Name,
        Description: 'fixture',
        APIPath: '/wp/v2/posts',
        ResponseDataKey: null,
        DefaultPageSize: 100,
        SupportsPagination: true,
        PaginationType: 'PageNumber',
        SupportsWrite: true,
        SupportsIncrementalSync: false,
        IncrementalWatermarkField: null,
        StableOrderingKey: 'id',
        Configuration: null,
        DefaultQueryParams: null,
        Status: 'Active',
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
        Type: 'string',
        Length: null, Precision: null, Scale: null, DefaultValue: null,
        IsPrimaryKey: false, IsRequired: false, IsReadOnly: false, IsUniqueKey: false,
        AllowsNull: true, Sequence: 0, Status: 'Active',
        RelatedIntegrationObjectID: null, RelatedIntegrationObject: null, RelatedIntegrationObjectFieldName: null,
        ...over,
    } as unknown as MJIntegrationObjectFieldEntity;
}

const postFields = [
    makeIOF({ Name: 'id', Type: 'Int', IsPrimaryKey: true, IsUniqueKey: true, IsReadOnly: true, Sequence: 0 }),
    makeIOF({ Name: 'slug', Sequence: 1 }),
    makeIOF({ Name: 'status', Sequence: 2 }),
    makeIOF({ Name: 'modified', Type: 'Datetime', IsReadOnly: true, Sequence: 3 }),
];

const postConfig = JSON.stringify({
    namespace: 'wp/v2',
    listPath: '/wp/v2/posts',
    responseShape: 'array',
    pkField: 'id',
    pagination: { type: 'PageNumber', pageParam: 'page', sizeParam: 'per_page', maxPageSize: 100 },
    incrementalWatermark: {
        field: 'modified', filterParam: 'modified_after', beforeParam: 'modified_before',
        datesAreGmt: false, orderby: 'modified',
    },
    contextGatedFields: ['password', 'permalink_template', 'generated_slug'],
    deleteSemantics: { semantics: 'soft-delete-to-trash-by-default', requiresForce: false, hardDeleteParam: 'force=true' },
});

const productConfig = JSON.stringify({
    namespace: 'wc/v3',
    listPath: '/wc/v3/products',
    responseShape: 'array',
    pkField: 'id',
    pagination: { type: 'PageNumber', maxPageSize: 100 },
    incrementalWatermark: {
        field: 'date_modified_gmt', filterParam: 'modified_after', beforeParam: 'modified_before',
        datesAreGmt: true, orderby: 'modified',
    },
    contextGatedFields: [],
    deleteSemantics: { semantics: 'soft-delete-to-trash-by-default', requiresForce: false, hardDeleteParam: 'force=true' },
});

const userConfig = JSON.stringify({
    namespace: 'wp/v2',
    listPath: '/wp/v2/users',
    responseShape: 'array',
    pkField: 'id',
    pagination: { type: 'PageNumber', maxPageSize: 100 },
    // The metadata carries NO watermark here (users-no-incremental) — the connector must not synthesise one.
    incrementalWatermark: null,
    incrementalNote: "x-wp-incremental.watermark='none' — NO date filter is registered → full-scan only.",
    contextGatedFields: ['username', 'email', 'registered_date'],
    deleteSemantics: { semantics: 'hard-delete-only', requiresForce: true, requiresReassign: true },
});

const integrationConfig = JSON.stringify({
    OutOfScopeObjectFamilies: [
        { family: 'WooCommerce Admin', namespace: 'wc-admin', kind: 'first-party-namespace', reason: 'admin plumbing' },
        { family: 'oEmbed', namespace: 'oembed/1.0', kind: 'first-party-namespace', reason: 'RPC' },
        { family: 'MemberPress', namespace: 'mp/v1', kind: 'third-party-plugin', reason: 'reachable at runtime via route-index discovery' },
        { family: 'Any other', namespace: '(per-site)', kind: 'per-site-remainder', reason: 'per-site' },
    ],
});

/**
 * The canonical Mocked<Connector> pattern. Overrides ONLY the transport boundary (`rawRequest`) and the
 * engine-cache seams with fixture rows. Every WordPress behaviour under test — base-URL derivation,
 * `context=edit` degrade, pagination header reading, watermark math, query-param construction, delete
 * semantics, error classification — is the REAL connector code. Nothing hits a live endpoint or mutates.
 */
class MockedWordPressConnector extends WordPressConnector {
    public Captured: CapturedRequest[] = [];
    public Canned: CannedResponse[] = [];
    public IOFixtures = new Map<string, MJIntegrationObjectEntity>();
    public IOFFixtures = new Map<string, MJIntegrationObjectFieldEntity[]>();
    public IntegrationConfiguration: string | null = integrationConfig;

    protected override async rawRequest(
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown,
    ): Promise<RESTResponse> {
        this.Captured.push({ url, method, headers, body });
        const idx = this.Canned.findIndex(c => !c.match || c.match({ url, method }));
        if (idx < 0) throw new Error(`MockedWordPressConnector: no canned response for ${method} ${url}`);
        const [canned] = this.Canned.splice(idx, 1);
        // Mirror the real transport: record the headers against the parsed body object so
        // ExtractPaginationInfo can read X-WP-TotalPages the same way it does in production.
        if (canned.response.Body != null && typeof canned.response.Body === 'object') {
            (this as unknown as { headersByBody: WeakMap<object, Record<string, string>> })
                .headersByBody.set(canned.response.Body as object, canned.response.Headers ?? {});
        }
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
    protected override tryGetIntegration(_integrationID: string): { Configuration?: string | null } | null {
        return { Configuration: this.IntegrationConfiguration };
    }
    protected override tryGetIntegrationID(): string | null {
        return 'int-1';
    }

    // ── Public seams for direct unit assertions ──
    public PublicNormalize(body: unknown, key: string | null): Record<string, unknown>[] {
        return this.NormalizeResponse(body, key);
    }
    public PublicExtractPagination(body: unknown, type: PaginationType, page: number, pageSize: number): PaginationState {
        return this.ExtractPaginationInfo(body, type, page, 0, pageSize);
    }
    public PublicBuildPaginatedURL(basePath: string, obj: MJIntegrationObjectEntity, page: number, size?: number): string {
        return this.BuildPaginatedURL(basePath, obj, page, 0, undefined, size);
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
}

const contextUser = { ID: 'test', Email: 'test@example.com', Name: 'test' } as unknown as Parameters<WordPressConnector['TestConnection']>[1];

function makeCI(configuration: Record<string, unknown>): MJCompanyIntegrationEntity {
    return {
        ID: 'ci-1',
        IntegrationID: 'int-1',
        Name: 'WordPress',
        CredentialID: null,
        Configuration: JSON.stringify(configuration),
    } as unknown as MJCompanyIntegrationEntity;
}

const APP_PASSWORD_CONFIG = {
    siteUrl: 'https://example.org',
    apiRoot: 'https://example.org/wp-json',
    username: 'svc_user',
    applicationPassword: 'abcd EFGH ijkl MNOP',
};

function ok(body: unknown, headers: Record<string, string> = {}): RESTResponse {
    return { Status: 200, Body: body, Headers: headers };
}
function fail(status: number, body: unknown, headers: Record<string, string> = {}): RESTResponse {
    return { Status: status, Body: body, Headers: headers };
}

function makeConnector(): MockedWordPressConnector {
    const c = new MockedWordPressConnector();
    const post = makeIO({ ID: 'io-post', Name: 'Post', APIPath: '/wp/v2/posts', Configuration: postConfig });
    const product = makeIO({ ID: 'io-product', Name: 'Product', APIPath: '/wc/v3/products', Configuration: productConfig });
    const user = makeIO({ ID: 'io-user', Name: 'User', APIPath: '/wp/v2/users', Configuration: userConfig });
    c.IOFixtures.set('Post', post);
    c.IOFixtures.set('Product', product);
    c.IOFixtures.set('User', user);
    c.IOFFixtures.set('io-post', postFields);
    c.IOFFixtures.set('io-product', [makeIOF({ Name: 'id', IsPrimaryKey: true, Sequence: 0 })]);
    c.IOFFixtures.set('io-user', [makeIOF({ Name: 'id', IsPrimaryKey: true, Sequence: 0 })]);
    return c;
}

function fetchCtx(over: Partial<FetchContext> & { ObjectName: string }): FetchContext {
    return {
        CompanyIntegration: makeCI(APP_PASSWORD_CONFIG),
        WatermarkValue: null,
        BatchSize: 100,
        ContextUser: contextUser,
        ...over,
    } as FetchContext;
}

// ─── Tests ────────────────────────────────────────────────────────────────────

describe('identity + capabilities', () => {
    it('IntegrationName is the verbatim MJ: Integrations.Name (T1 three-way invariant)', () => {
        expect(new WordPressConnector().IntegrationName).toBe('WordPress');
    });

    it('declares write capabilities in lockstep with the per-operation IO columns', () => {
        const c = new WordPressConnector();
        expect(c.SupportsCreate).toBe(true);
        expect(c.SupportsUpdate).toBe(true);
        expect(c.SupportsDelete).toBe(true);
    });

    it('DiscoveryIsAuthoritative stays FALSE — nothing may ever be deactivated from discovery', () => {
        expect(new WordPressConnector().DiscoveryIsAuthoritative).toBe(false);
    });

    it('publishes NO fabricated rate-limit policy (no vendor-documented limit exists) but caps concurrency', () => {
        const c = new WordPressConnector();
        expect(c.RateLimitPolicy).toBeNull();
        expect(c.MaxConcurrencyHint).toBe(2);
    });
});

describe('base-URL derivation', () => {
    it('uses the Link rel="https://api.w.org/" header the site advertises — never siteUrl + "/wp-json"', async () => {
        const c = makeConnector();
        c.Canned.push({ response: ok(null, { link: '<https://example.org/custom-rest/>; rel="https://api.w.org/"' }) });
        const auth = await c.PublicAuthenticate(makeCI({ siteUrl: 'https://example.org', username: 'u', applicationPassword: 'p' }));
        expect(c.PublicGetBaseURL(makeCI({}), auth)).toBe('https://example.org/custom-rest');
        expect(c.Captured[0].method).toBe('HEAD');
    });

    it('falls back to {siteUrl}/wp-json when nothing is advertised, verified by a real route index', async () => {
        const c = makeConnector();
        c.Canned.push({ response: fail(405, null) });                 // HEAD /
        c.Canned.push({ response: fail(404, null) });                 // GET /
        c.Canned.push({ response: ok(routeIndexFixture) });           // GET /wp-json
        const auth = await c.PublicAuthenticate(makeCI({ siteUrl: 'https://example.org', username: 'u', applicationPassword: 'p' }));
        expect(c.PublicGetBaseURL(makeCI({}), auth)).toBe('https://example.org/wp-json');
    });

    it('falls back to the permalink-less ?rest_route= form and rewrites request URLs into it', async () => {
        const c = makeConnector();
        c.Canned.push({ response: fail(405, null) });                            // HEAD /
        c.Canned.push({ response: fail(404, null) });                            // GET /
        c.Canned.push({ response: fail(404, { code: 'rest_no_route' }) });        // GET /wp-json
        c.Canned.push({ response: ok(routeIndexFixture) });                       // GET /?rest_route=/
        const auth = await c.PublicAuthenticate(makeCI({ siteUrl: 'https://example.org', username: 'u', applicationPassword: 'p' }));
        const base = c.PublicGetBaseURL(makeCI({}), auth);
        expect(base).toBe('https://example.org/__mj_rest_route__');

        c.Canned.push({ response: ok([]) });
        await (c as unknown as {
            MakeHTTPRequest(a: RESTAuthContext, u: string, m: string, h: Record<string, string>): Promise<RESTResponse>;
        }).MakeHTTPRequest(auth, `${base}/wp/v2/posts?per_page=100`, 'GET', {});
        const last = c.Captured[c.Captured.length - 1].url;
        expect(last).toContain('https://example.org/?rest_route=%2Fwp%2Fv2%2Fposts');
        expect(last).toContain('per_page=100');
        expect(last).not.toContain('__mj_rest_route__');
    });

    it('throws a named error when the site advertises no REST API at all', async () => {
        const c = makeConnector();
        for (let i = 0; i < 4; i++) c.Canned.push({ response: fail(404, 'not found') });
        await expect(c.PublicAuthenticate(makeCI({ siteUrl: 'https://example.org' })))
            .rejects.toThrow(/Could not derive a WordPress REST API root/);
    });

    it('requires a per-connection site URL — WordPress is self-hosted, there is no vendor host', async () => {
        const c = makeConnector();
        await expect(c.PublicAuthenticate(makeCI({ username: 'u', applicationPassword: 'p' })))
            .rejects.toThrow(/SELF-HOSTED/);
    });
});

describe('Authenticate + BuildHeaders', () => {
    it('builds RFC-7617 Basic from username + Application Password via the shared auth-helper', async () => {
        const c = makeConnector();
        const auth = await c.PublicAuthenticate(makeCI(APP_PASSWORD_CONFIG));
        const headers = c.PublicBuildHeaders(auth);
        const expected = `Basic ${Buffer.from('svc_user:abcd EFGH ijkl MNOP', 'utf8').toString('base64')}`;
        expect(headers.Authorization).toBe(expected);
        expect(headers['Content-Type']).toBe('application/json');
    });

    it('falls back to the WooCommerce consumer key/secret pair when no Application Password is supplied', async () => {
        const c = makeConnector();
        const auth = await c.PublicAuthenticate(makeCI({
            siteUrl: 'https://example.org', apiRoot: 'https://example.org/wp-json',
            wooConsumerKey: 'ck_test', wooConsumerSecret: 'cs_test',
        }));
        const expected = `Basic ${Buffer.from('ck_test:cs_test', 'utf8').toString('base64')}`;
        expect(c.PublicBuildHeaders(auth).Authorization).toBe(expected);
    });

    it('does NOT throw on a credential-free connection — public routes and OPTIONS still answer', async () => {
        const c = makeConnector();
        const auth = await c.PublicAuthenticate(makeCI({ siteUrl: 'https://example.org', apiRoot: 'https://example.org/wp-json' }));
        expect(c.PublicBuildHeaders(auth).Authorization).toBeUndefined();
    });

    it('appends the Woo consumer key/secret as query params on wc/ URLs when the connection opts in', async () => {
        const c = makeConnector();
        const auth = await c.PublicAuthenticate(makeCI({
            siteUrl: 'https://example.org', apiRoot: 'https://example.org/wp-json',
            wooConsumerKey: 'ck_test', wooConsumerSecret: 'cs_test', wooAuthViaQueryParams: true,
        }));
        c.Canned.push({ response: ok([]) });
        c.Canned.push({ response: ok([]) });
        const call = (url: string) => (c as unknown as {
            MakeHTTPRequest(a: RESTAuthContext, u: string, m: string, h: Record<string, string>): Promise<RESTResponse>;
        }).MakeHTTPRequest(auth, url, 'GET', {});
        await call('https://example.org/wp-json/wc/v3/products');
        expect(c.Captured[0].url).toContain('consumer_key=ck_test');
        await call('https://example.org/wp-json/wp/v2/posts');
        expect(c.Captured[1].url).not.toContain('consumer_key');
    });
});

describe('context=edit graceful degrade', () => {
    it('requests context=edit on reads', async () => {
        const c = makeConnector();
        const auth = await c.PublicAuthenticate(makeCI(APP_PASSWORD_CONFIG));
        c.Canned.push({ response: ok([]) });
        await (c as unknown as {
            MakeHTTPRequest(a: RESTAuthContext, u: string, m: string, h: Record<string, string>): Promise<RESTResponse>;
        }).MakeHTTPRequest(auth, 'https://example.org/wp-json/wp/v2/posts', 'GET', {});
        expect(c.Captured[0].url).toContain('context=edit');
    });

    it('degrades to context=view on 401 and retries ONCE — never silently, never per page', async () => {
        const c = makeConnector();
        const auth = await c.PublicAuthenticate(makeCI(APP_PASSWORD_CONFIG));
        c.Canned.push({ response: fail(401, wpErrorForbiddenContext) });
        c.Canned.push({ response: ok(postsPage1, { 'x-wp-totalpages': '1' }) });
        const call = () => (c as unknown as {
            MakeHTTPRequest(a: RESTAuthContext, u: string, m: string, h: Record<string, string>): Promise<RESTResponse>;
        }).MakeHTTPRequest(auth, 'https://example.org/wp-json/wp/v2/posts', 'GET', {});

        const first = await call();
        expect(first.Status).toBe(200);
        expect(c.Captured[0].url).toContain('context=edit');
        expect(c.Captured[1].url).toContain('context=view');

        // The route is now remembered as degraded: the next call goes straight to view, no re-probe.
        c.Canned.push({ response: ok([], { 'x-wp-totalpages': '1' }) });
        await call();
        expect(c.Captured[2].url).toContain('context=view');
        expect(c.Captured.length).toBe(3);
    });

    it('does not inject context on a write', async () => {
        const c = makeConnector();
        const auth = await c.PublicAuthenticate(makeCI(APP_PASSWORD_CONFIG));
        c.Canned.push({ response: { Status: 201, Body: { id: 7 }, Headers: {} } });
        await (c as unknown as {
            MakeHTTPRequest(a: RESTAuthContext, u: string, m: string, h: Record<string, string>, b?: unknown): Promise<RESTResponse>;
        }).MakeHTTPRequest(auth, 'https://example.org/wp-json/wp/v2/posts', 'POST', {}, { title: 'x' });
        expect(c.Captured[0].url).not.toContain('context=');
    });
});

describe('NormalizeResponse', () => {
    let c: MockedWordPressConnector;
    beforeEach(() => { c = makeConnector(); });

    it('passes a bare array through (the `array` response shape — 73 of the declared objects)', () => {
        expect(c.PublicNormalize(postsPage1, null)).toHaveLength(2);
    });

    it('expands the `object-map` shape (types / statuses / taxonomies / menu-locations) to its values', () => {
        const map = { post: { slug: 'post', name: 'Posts' }, page: { slug: 'page', name: 'Pages' } };
        const out = c.PublicNormalize(map, null);
        expect(out).toHaveLength(2);
        expect(out[0].slug).toBe('post');
    });

    it('wraps the `single-object` shape (settings) as one record', () => {
        const settings = { title: 'Example', description: '', posts_per_page: 10, default_ping_status: 'open' };
        const out = c.PublicNormalize(settings, null);
        expect(out).toHaveLength(1);
        expect(out[0].title).toBe('Example');
    });

    it('never treats a WP_Error envelope as a record', () => {
        expect(c.PublicNormalize(wpErrorNoRoute, null)).toHaveLength(0);
    });

    it('honours an explicit ResponseDataKey when metadata declares one', () => {
        expect(c.PublicNormalize({ items: postsPage1 }, 'items')).toHaveLength(2);
    });

    it('returns nothing for null / scalar bodies', () => {
        expect(c.PublicNormalize(null, null)).toHaveLength(0);
        expect(c.PublicNormalize('a string', null)).toHaveLength(0);
    });
});

describe('ExtractPaginationInfo', () => {
    let c: MockedWordPressConnector;
    beforeEach(() => { c = makeConnector(); });

    function withHeaders(body: unknown, headers: Record<string, string>): unknown {
        (c as unknown as { headersByBody: WeakMap<object, Record<string, string>> })
            .headersByBody.set(body as object, headers);
        return body;
    }

    it('terminates on X-WP-TotalPages and surfaces X-WP-Total as the expected count', () => {
        const body = withHeaders([...postsPage1], { 'x-wp-total': '15', 'x-wp-totalpages': '8' });
        const state = c.PublicExtractPagination(body, 'PageNumber', 1, 2);
        expect(state.HasMore).toBe(true);
        expect(state.NextPage).toBe(2);
        expect(state.TotalRecords).toBe(15);

        const last = c.PublicExtractPagination(withHeaders([...postsPage2], { 'x-wp-totalpages': '8' }), 'PageNumber', 8, 2);
        expect(last.HasMore).toBe(false);
    });

    it('falls back to the RFC-5988 Link rel="next" header when TotalPages is absent', () => {
        const withNext = withHeaders([...postsPage1], { link: '<https://example.org/wp-json/wp/v2/posts?page=2>; rel="next"' });
        expect(c.PublicExtractPagination(withNext, 'PageNumber', 1, 2).HasMore).toBe(true);
        const withoutNext = withHeaders([...postsPage2], { link: '<https://example.org/wp-json/wp/v2/posts?page=1>; rel="prev"' });
        expect(c.PublicExtractPagination(withoutNext, 'PageNumber', 2, 2).HasMore).toBe(false);
    });

    it('falls back to a short-page heuristic when the site strips both headers', () => {
        expect(c.PublicExtractPagination([...postsPage1], 'PageNumber', 1, 2).HasMore).toBe(true);   // full page
        expect(c.PublicExtractPagination([...postsPage2], 'PageNumber', 2, 2).HasMore).toBe(false);  // short page
        expect(c.PublicExtractPagination([], 'PageNumber', 3, 2).HasMore).toBe(false);               // empty page
    });

    it('reports no continuation for a non-paginated object', () => {
        expect(c.PublicExtractPagination({ title: 'x' }, 'None', 1, 100).HasMore).toBe(false);
    });
});

describe('BuildPaginatedURL', () => {
    it('emits page + per_page and CLAMPS per_page to the metadata-declared cap (WP rejects, never clamps)', () => {
        const c = makeConnector();
        const post = c.IOFixtures.get('Post')!;
        expect(c.PublicBuildPaginatedURL('https://example.org/wp-json/wp/v2/posts', post, 2, 500))
            .toBe('https://example.org/wp-json/wp/v2/posts?page=2&per_page=100');
        expect(c.PublicBuildPaginatedURL('https://example.org/wp-json/wp/v2/posts?x=1', post, 1, 25))
            .toBe('https://example.org/wp-json/wp/v2/posts?x=1&page=1&per_page=25');
    });
});

describe('FetchChanges — pagination, params and identity', () => {
    it('walks EVERY page (never a single un-paged request) and keeps the FULL source record', async () => {
        const c = makeConnector();
        c.Canned.push({ response: ok(postsPage1, { 'x-wp-total': '3', 'x-wp-totalpages': '2' }) });
        c.Canned.push({ response: ok(postsPage2, { 'x-wp-total': '3', 'x-wp-totalpages': '2' }) });
        c.Canned.push({ response: ok([], { 'x-wp-totalpages': '1' }) });  // the trash sweep on the drained pass

        const result = await c.FetchChanges(fetchCtx({ ObjectName: 'Post' }));
        expect(c.Captured[0].url).toContain('page=1');
        expect(c.Captured[1].url).toContain('page=2');
        expect(c.Captured.filter(r => !r.url.includes('status=trash'))).toHaveLength(2);
        expect(result.Records).toHaveLength(3);
        // FULL-RECORD pass-through: the per-site custom property survives to ExternalRecord.Fields.
        expect(result.Records[0].Fields.mj_site_custom).toBe('x');
        expect(result.Records[0].Fields.meta).toEqual({ footnotes: '' });
        // and `_fields` is NEVER sent — it would truncate the record and break custom-column capture.
        expect(c.Captured[0].url).not.toContain('_fields');
    });

    it('requests the STABLE SORT so offset drift on deep pages is minimised', async () => {
        const c = makeConnector();
        c.Canned.push({ response: ok(postsPage2, { 'x-wp-totalpages': '1' }) });
        await c.FetchChanges(fetchCtx({ ObjectName: 'Post' }));
        expect(c.Captured[0].url).toContain('orderby=id');
        expect(c.Captured[0].url).toContain('order=asc');
    });

    it('derives ExternalID from the DECLARED primary key, stably across passes', async () => {
        const c = makeConnector();
        c.Canned.push({ response: ok(postsPage2, { 'x-wp-totalpages': '1' }) });
        const first = await c.FetchChanges(fetchCtx({ ObjectName: 'Post' }));
        c.Canned.push({ response: ok(postsPage2.map(r => ({ ...r, link: 'https://example.org/?p=3' })), { 'x-wp-totalpages': '1' }) });
        const second = await c.FetchChanges(fetchCtx({ ObjectName: 'Post' }));
        expect(first.Records[0].ExternalID).toBe('3');
        // A volatile field changing must NOT move the identity.
        expect(second.Records[0].ExternalID).toBe(first.Records[0].ExternalID);
    });

    it('does not send _fields even when the engine supplies RequestedSourceFields', async () => {
        const c = makeConnector();
        c.Canned.push({ response: ok(postsPage2, { 'x-wp-totalpages': '1' }) });
        await c.FetchChanges(fetchCtx({ ObjectName: 'Post', RequestedSourceFields: ['id', 'slug'] }));
        expect(c.Captured[0].url).not.toContain('_fields');
    });
});

describe('FetchChanges — incremental, strictly from metadata', () => {
    it('first sync (no watermark) sends NO date filter and persists the MAX modified seen', async () => {
        const c = makeConnector();
        const post = c.IOFixtures.get('Post')!;
        Object.assign(post, { SupportsIncrementalSync: true, IncrementalWatermarkField: 'modified' });
        c.Canned.push({ response: ok(postsPage1, { 'x-wp-totalpages': '1' }) });

        const result = await c.FetchChanges(fetchCtx({ ObjectName: 'Post' }));
        expect(c.Captured[0].url).not.toContain('modified_after');
        // max-SEEN, not most-recent-in-order: page order is 01-01 then 03-02.
        expect(result.NewWatermarkValue).toBe('2026-03-02T00:00:00');
    });

    it('subsequent sync sends the metadata-declared filter param and advances the max', async () => {
        const c = makeConnector();
        const post = c.IOFixtures.get('Post')!;
        Object.assign(post, { SupportsIncrementalSync: true, IncrementalWatermarkField: 'modified' });
        c.Canned.push({ response: ok(postsPage1, { 'x-wp-totalpages': '1' }) });

        const result = await c.FetchChanges(fetchCtx({ ObjectName: 'Post', WatermarkValue: '2026-01-01T00:00:00' }));
        expect(c.Captured[0].url).toContain('modified_after=2026-01-01T00%3A00%3A00');
        expect(c.Captured[0].url).not.toContain('dates_are_gmt');
        expect(result.NewWatermarkValue).toBe('2026-03-02T00:00:00');
    });

    it('adds dates_are_gmt=true for the WooCommerce resources that declare it', async () => {
        const c = makeConnector();
        const product = c.IOFixtures.get('Product')!;
        Object.assign(product, { SupportsIncrementalSync: true, IncrementalWatermarkField: 'date_modified_gmt' });
        c.Canned.push({ response: ok(productsPage, { 'x-wp-totalpages': '1' }) });

        const result = await c.FetchChanges(fetchCtx({ ObjectName: 'Product', WatermarkValue: '2026-04-01T00:00:00Z' }));
        expect(c.Captured[0].url).toContain('modified_after=');
        expect(c.Captured[0].url).toContain('dates_are_gmt=true');
        expect(result.NewWatermarkValue).toBe('2026-05-01T10:00:00');
    });

    it('emits NO delta path for wp/v2/users — the metadata declares no watermark and none may be synthesised', async () => {
        const c = makeConnector();
        c.Canned.push({ response: ok([{ id: 1, slug: 'admin' }], { 'x-wp-totalpages': '1' }) });
        const result = await c.FetchChanges(fetchCtx({ ObjectName: 'User', WatermarkValue: '2026-01-01T00:00:00' }));
        expect(c.Captured[0].url).not.toContain('modified_after');
        expect(c.Captured[0].url).not.toContain('registered_date');
        expect(result.NewWatermarkValue).toBeUndefined();
    });

    it('PARTIAL batch does NOT advance the watermark — the next run resumes from the stored value', async () => {
        const c = makeConnector();
        const post = c.IOFixtures.get('Post')!;
        Object.assign(post, { SupportsIncrementalSync: true, IncrementalWatermarkField: 'modified' });
        c.Canned.push({ response: ok(postsPage1, { 'x-wp-total': '9', 'x-wp-totalpages': '5' }) });

        const result = await c.FetchChanges(fetchCtx({ ObjectName: 'Post', BatchSize: 2 }));
        expect(result.HasMore).toBe(true);
        expect(result.NewWatermarkValue).toBeUndefined();
    });

    it('a mid-fetch failure leaves the watermark untouched (it propagates, it does not half-commit)', async () => {
        const c = makeConnector();
        const post = c.IOFixtures.get('Post')!;
        Object.assign(post, { SupportsIncrementalSync: true, IncrementalWatermarkField: 'modified' });
        c.Canned.push({ response: ok(postsPage1, { 'x-wp-total': '9', 'x-wp-totalpages': '5' }) });
        c.Canned.push({ response: fail(500, { code: 'internal_server_error', message: 'boom', data: { status: 500 } }) });
        await expect(c.FetchChanges(fetchCtx({ ObjectName: 'Post' }))).rejects.toThrow(/HTTP 500/);
    });
});

describe('FetchChanges — graceful degrades', () => {
    it('an unregistered route (a gated Woo feature) becomes a WARNED zero-record result, not a failed sync', async () => {
        const c = makeConnector();
        c.Canned.push({ response: fail(404, wpErrorNoRoute) });
        const result = await c.FetchChanges(fetchCtx({ ObjectName: 'Post' }));
        expect(result.Records).toHaveLength(0);
        expect(result.Warnings?.[0].Code).toBe('ROUTE_NOT_REGISTERED');
        expect(result.Warnings?.[0].Message).toContain('not registered on this site');
    });

    it('a capability-forbidden collection warns explicitly instead of failing or looking empty-and-green', async () => {
        const c = makeConnector();
        // First 401 triggers the context degrade; the retry is still forbidden → capability warning.
        c.Canned.push({ response: fail(401, wpErrorForbiddenContext) });
        c.Canned.push({ response: fail(401, { code: 'rest_forbidden', message: 'nope', data: { status: 401 } }) });
        const result = await c.FetchChanges(fetchCtx({ ObjectName: 'Post' }));
        expect(result.Records).toHaveLength(0);
        expect(result.Warnings?.[0].Code).toBe('CAPABILITY_FORBIDDEN');
    });

    it('an HTML-bodied 403 is classified as a WAF/host block — distinct from a JSON capability refusal', async () => {
        const c = makeConnector();
        c.Canned.push({ response: fail(403, '<!DOCTYPE html><html><body>Access Denied</body></html>') });
        c.Canned.push({ response: fail(403, '<!DOCTYPE html><html><body>Access Denied</body></html>') });
        const result = await c.FetchChanges(fetchCtx({ ObjectName: 'Post' }));
        expect(result.Warnings?.[0].Code).toBe('BLOCKED_BY_HOST_OR_WAF');
    });

    it('a 5xx propagates — it is never swallowed into an empty success', async () => {
        const c = makeConnector();
        c.Canned.push({ response: fail(500, { code: 'internal_server_error', message: 'boom', data: { status: 500 } }) });
        await expect(c.FetchChanges(fetchCtx({ ObjectName: 'Post' }))).rejects.toThrow(/HTTP 500/);
    });
});

describe('FetchChanges — dual-namespace credential guard', () => {
    it('a Woo-ONLY credential fails wp/v2 objects with an explicit capability warning, never an empty green sync', async () => {
        const c = makeConnector();
        const ci = makeCI({
            siteUrl: 'https://example.org', apiRoot: 'https://example.org/wp-json',
            wooConsumerKey: 'ck', wooConsumerSecret: 'cs',
        });
        const result = await c.FetchChanges(fetchCtx({ ObjectName: 'Post', CompanyIntegration: ci }));
        expect(result.Records).toHaveLength(0);
        expect(result.Warnings?.[0].Code).toBe('CAPABILITY_WOO_ONLY_CREDENTIAL');
        expect(c.Captured.filter(r => r.url.includes('/wp/v2/posts'))).toHaveLength(0);
    });

    it('the same Woo-only credential still reads wc/v3 objects normally', async () => {
        const c = makeConnector();
        const ci = makeCI({
            siteUrl: 'https://example.org', apiRoot: 'https://example.org/wp-json',
            wooConsumerKey: 'ck', wooConsumerSecret: 'cs',
        });
        c.Canned.push({ response: ok(productsPage, { 'x-wp-totalpages': '1' }) });
        const result = await c.FetchChanges(fetchCtx({ ObjectName: 'Product', CompanyIntegration: ci }));
        expect(result.Records).toHaveLength(1);
        expect(result.Warnings).toBeUndefined();
    });

    it('an Application Password authenticates BOTH namespaces — no guard fires', async () => {
        const c = makeConnector();
        c.Canned.push({ response: ok(productsPage, { 'x-wp-totalpages': '1' }) });
        const result = await c.FetchChanges(fetchCtx({ ObjectName: 'Product' }));
        expect(result.Records).toHaveLength(1);
    });
});

describe('FetchChanges — soft deletes', () => {
    it('sweeps status=trash for a post type on a drained pass and flags those records deleted', async () => {
        const c = makeConnector();
        c.Canned.push({ response: ok(postsPage1, { 'x-wp-totalpages': '1' }) });   // main pass
        c.Canned.push({ response: ok(postsTrashPage, { 'x-wp-totalpages': '1' }) }); // trash sweep

        const result = await c.FetchChanges(fetchCtx({ ObjectName: 'Post' }));
        expect(c.Captured[1].url).toContain('status=trash');
        expect(result.Records).toHaveLength(3);
        const trashed = result.Records.find(r => r.ExternalID === '9');
        expect(trashed?.IsDeleted).toBe(true);
        expect(result.Records.find(r => r.ExternalID === '1')?.IsDeleted).toBeUndefined();
    });

    it('does NOT sweep trash for a credential-free connection (an anonymous caller can never see it)', async () => {
        const c = makeConnector();
        const ci = makeCI({ siteUrl: 'https://example.org', apiRoot: 'https://example.org/wp-json' });
        c.Canned.push({ response: ok(postsPage1, { 'x-wp-totalpages': '1' }) });
        await c.FetchChanges(fetchCtx({ ObjectName: 'Post', CompanyIntegration: ci }));
        expect(c.Captured).toHaveLength(1);
    });

    it('reports the honest position when the trash sweep is capability-blocked — no delete DETECTION claimed', async () => {
        const c = makeConnector();
        c.Canned.push({ response: ok(postsPage1, { 'x-wp-totalpages': '1' }) });
        c.Canned.push({ response: fail(400, { code: 'rest_invalid_param', message: 'Status is forbidden.', data: { status: 400 } }) });
        const result = await c.FetchChanges(fetchCtx({ ObjectName: 'Post' }));
        expect(result.Warnings?.[0].Code).toBe('SOFT_DELETE_SWEEP_UNAVAILABLE');
        expect(result.Warnings?.[0].Message).toContain('KEY SWEEP');
    });
});

describe('DiscoverObjects — dynamic, never baked', () => {
    it('makes a RUNTIME route-index call and unions the per-site remainder over the declared floor', async () => {
        const c = makeConnector();
        c.Canned.push({ response: ok(routeIndexFixture) });
        const objects = await c.DiscoverObjects(makeCI(APP_PASSWORD_CONFIG), contextUser);
        const names = objects.map(o => o.Name);

        // the declared floor survives …
        expect(names).toContain('Post');
        expect(names).toContain('Product');
        // … and this site's custom post type is discovered on top of it.
        expect(names).toContain('/wp/v2/mj-events');
        // a route-index call actually happened (this is not a static catalog).
        expect(c.Captured.some(r => r.url.includes('/wp-json/'))).toBe(true);
    });

    it('does not re-add an object the declared floor already covers, matching templated paths canonically', async () => {
        const c = makeConnector();
        c.Canned.push({ response: ok(routeIndexFixture) });
        const objects = await c.DiscoverObjects(makeCI(APP_PASSWORD_CONFIG), contextUser);
        expect(objects.filter(o => o.Name === '/wp/v2/posts')).toHaveLength(0);
        expect(objects.filter(o => o.Name === 'Post')).toHaveLength(1);
    });

    it('skips first-party namespaces the metadata scoped out, but KEEPS third-party plugin namespaces', async () => {
        const c = makeConnector();
        c.Canned.push({ response: ok(routeIndexFixture) });
        const names = (await c.DiscoverObjects(makeCI(APP_PASSWORD_CONFIG), contextUser)).map(o => o.Name);
        expect(names).not.toContain('/wc-admin/options');
        expect(names).toContain('/mp/v1/members');
    });

    it('ignores RPC routes that register no per_page — they are not record collections', async () => {
        const c = makeConnector();
        c.Canned.push({ response: ok(routeIndexFixture) });
        const names = (await c.DiscoverObjects(makeCI(APP_PASSWORD_CONFIG), contextUser)).map(o => o.Name);
        expect(names.some(n => n.includes('block-renderer'))).toBe(false);
        expect(names).not.toContain('/wp/v2');
    });

    it('a discovery failure degrades to the declared floor — it NEVER deactivates anything', async () => {
        const c = makeConnector();
        c.Canned.push({ response: fail(500, { code: 'internal_server_error', message: 'x', data: { status: 500 } }) });
        const names = (await c.DiscoverObjects(makeCI(APP_PASSWORD_CONFIG), contextUser)).map(o => o.Name);
        expect(names).toEqual(expect.arrayContaining(['Post', 'Product', 'User']));
    });
});

describe('DiscoverFields — OPTIONS describe, union-only', () => {
    it('reads the endpoint JSON Schema from OPTIONS and unions per-site properties onto the declared set', async () => {
        const c = makeConnector();
        c.Canned.push({ response: ok(postsOptionsFixture) });
        const fields: ExternalFieldSchema[] = await c.DiscoverFields(makeCI(APP_PASSWORD_CONFIG), 'Post', contextUser);
        const byName = new Map(fields.map(f => [f.Name, f]));

        expect(c.Captured[0].method).toBe('OPTIONS');
        expect(c.Captured[0].url).toContain('/wp/v2/posts');
        // declared fields all survive …
        for (const declared of ['id', 'slug', 'status', 'modified']) expect(byName.has(declared)).toBe(true);
        // … and the per-site custom property is added.
        expect(byName.get('mj_site_custom')?.DataType).toBe('string');
    });

    it('maps schema attributes provable-only: readonly, nullable unions, maxLength, and NEVER a guessed FK', async () => {
        const c = makeConnector();
        c.Canned.push({ response: ok(postsOptionsFixture) });
        // Describe an object with no declared fields so the OPTIONS mapping is visible directly.
        c.IOFixtures.set('Bare', makeIO({ ID: 'io-bare', Name: 'Bare', APIPath: '/wp/v2/posts', Configuration: postConfig }));
        c.IOFFixtures.set('io-bare', []);
        const fields = await c.DiscoverFields(makeCI(APP_PASSWORD_CONFIG), 'Bare', contextUser);
        const byName = new Map(fields.map(f => [f.Name, f]));

        expect(byName.get('id')?.IsReadOnly).toBe(true);
        expect(byName.get('date')?.AllowsNull).toBe(true);
        expect(byName.get('slug')?.AllowsNull).toBeUndefined();      // provable-only: never inferred
        expect(byName.get('slug')?.MaxLength).toBe(200);
        expect(byName.get('modified')?.DataType).toBe('datetime');
        expect(fields.every(f => f.IsForeignKey === false)).toBe(true);
    });

    it('an OPTIONS failure keeps the declared field set intact — field absence is never authoritative', async () => {
        const c = makeConnector();
        c.Canned.push({ response: fail(401, { code: 'rest_forbidden', message: 'x', data: { status: 401 } }) });
        c.Canned.push({ response: fail(401, { code: 'rest_forbidden', message: 'x', data: { status: 401 } }) });
        const fields = await c.DiscoverFields(makeCI(APP_PASSWORD_CONFIG), 'Post', contextUser);
        expect(fields.map(f => f.Name)).toEqual(['id', 'slug', 'status', 'modified']);
    });

    it('skips OPTIONS for a parent-templated collection (there is no literal URL to describe)', async () => {
        const c = makeConnector();
        c.IOFixtures.set('OrderNote', makeIO({
            ID: 'io-note', Name: 'OrderNote', APIPath: '/wc/v3/orders/{order_id}/notes',
            Configuration: JSON.stringify({ namespace: 'wc/v3', listPath: '/wc/v3/orders/{order_id}/notes', parentObjectName: 'Order' }),
        }));
        c.IOFFixtures.set('io-note', [makeIOF({ Name: 'id', IsPrimaryKey: true })]);
        const fields = await c.DiscoverFields(makeCI(APP_PASSWORD_CONFIG), 'OrderNote', contextUser);
        expect(fields.map(f => f.Name)).toEqual(['id']);
        expect(c.Captured.filter(r => r.method === 'OPTIONS')).toHaveLength(0);
    });
});

describe('DeleteRecord — per-object semantics from metadata', () => {
    function deleteCtx(objectName: string, externalID: string, ci = makeCI(APP_PASSWORD_CONFIG)): DeleteRecordContext {
        return { CompanyIntegration: ci, ContextUser: contextUser, ObjectName: objectName, ExternalID: externalID } as unknown as DeleteRecordContext;
    }

    it('keeps the vendor SOFT delete (to trash) for a post type — no force is added', async () => {
        const c = makeConnector();
        const post = c.IOFixtures.get('Post')!;
        Object.assign(post, { DeleteAPIPath: '/wp/v2/posts/{id}', DeleteMethod: 'DELETE', DeleteIDLocation: 'path' });
        c.Canned.push({ response: ok({ deleted: true }) });
        const result = await c.DeleteRecord(deleteCtx('Post', '5'));
        expect(result.Success).toBe(true);
        expect(c.Captured[0].url).toContain('/wp/v2/posts/5');
        expect(c.Captured[0].url).not.toContain('force=true');
    });

    it('adds force=true where the metadata says the route requires it', async () => {
        const c = makeConnector();
        c.IOFixtures.set('Category', makeIO({
            ID: 'io-cat', Name: 'Category', APIPath: '/wp/v2/categories',
            DeleteAPIPath: '/wp/v2/categories/{id}', DeleteMethod: 'DELETE', DeleteIDLocation: 'path',
            Configuration: JSON.stringify({
                namespace: 'wp/v2', listPath: '/wp/v2/categories',
                deleteSemantics: { semantics: 'hard-delete-requires-force', requiresForce: true },
            }),
        }));
        c.IOFFixtures.set('io-cat', [makeIOF({ Name: 'id', IsPrimaryKey: true })]);
        c.Canned.push({ response: ok({ deleted: true }) });
        await c.DeleteRecord(deleteCtx('Category', '12'));
        expect(c.Captured[0].url).toContain('/wp/v2/categories/12');
        expect(c.Captured[0].url).toContain('force=true');
    });

    it('REFUSES to delete a user without a configured reassign target rather than choosing one', async () => {
        const c = makeConnector();
        const user = c.IOFixtures.get('User')!;
        Object.assign(user, { DeleteAPIPath: '/wp/v2/users/{id}', DeleteMethod: 'DELETE', DeleteIDLocation: 'path' });
        const result = await c.DeleteRecord(deleteCtx('User', '3'));
        expect(result.Success).toBe(false);
        expect(result.ErrorMessage).toContain('userDeleteReassignID');
        expect(c.Captured).toHaveLength(0);
    });

    it('sends force + reassign for a user when the connection configures the reassign target', async () => {
        const c = makeConnector();
        const user = c.IOFixtures.get('User')!;
        Object.assign(user, { DeleteAPIPath: '/wp/v2/users/{id}', DeleteMethod: 'DELETE', DeleteIDLocation: 'path' });
        const ci = makeCI({ ...APP_PASSWORD_CONFIG, userDeleteReassignID: '1' });
        c.Canned.push({ response: ok({ deleted: true }) });
        await c.DeleteRecord(deleteCtx('User', '3', ci));
        expect(c.Captured[0].url).toContain('force=true');
        expect(c.Captured[0].url).toContain('reassign=1');
    });
});

describe('generic CRUD via the per-operation IO columns', () => {
    it('CreateRecord posts to CreateAPIPath with the flat body and reads the id from the Location header', async () => {
        const c = makeConnector();
        const post = c.IOFixtures.get('Post')!;
        Object.assign(post, {
            CreateAPIPath: '/wp/v2/posts', CreateMethod: 'POST', CreateBodyShape: 'flat', CreateIDLocation: 'header',
        });
        c.Canned.push({ response: { Status: 201, Body: { id: 42 }, Headers: { location: 'https://example.org/wp-json/wp/v2/posts/42' } } });
        const ctx = {
            CompanyIntegration: makeCI(APP_PASSWORD_CONFIG), ContextUser: contextUser,
            ObjectName: 'Post', Attributes: { title: 'Hello', status: 'draft' },
        } as unknown as CreateRecordContext;
        const result = await c.CreateRecord(ctx);
        expect(result.Success).toBe(true);
        expect(result.ExternalID).toBe('42');
        expect(c.Captured[0].method).toBe('POST');
        expect(c.Captured[0].body).toEqual({ title: 'Hello', status: 'draft' });
    });

    it('UpdateRecord templates the id into UpdateAPIPath', async () => {
        const c = makeConnector();
        const post = c.IOFixtures.get('Post')!;
        Object.assign(post, { UpdateAPIPath: '/wp/v2/posts/{id}', UpdateMethod: 'POST', UpdateBodyShape: 'flat', UpdateIDLocation: 'path' });
        c.Canned.push({ response: ok({ id: 5 }) });
        const ctx = {
            CompanyIntegration: makeCI(APP_PASSWORD_CONFIG), ContextUser: contextUser,
            ObjectName: 'Post', ExternalID: '5', Attributes: { title: 'Changed' },
        } as unknown as UpdateRecordContext;
        const result = await c.UpdateRecord(ctx);
        expect(result.Success).toBe(true);
        expect(c.Captured[0].url).toContain('/wp/v2/posts/5');
    });

    it('surfaces the vendor error envelope (code + message) rather than a bare status', async () => {
        const c = makeConnector();
        const post = c.IOFixtures.get('Post')!;
        Object.assign(post, { CreateAPIPath: '/wp/v2/posts', CreateMethod: 'POST', CreateBodyShape: 'flat', CreateIDLocation: 'header' });
        c.Canned.push({ response: fail(400, { code: 'rest_invalid_param', message: 'Invalid parameter(s): status', data: { status: 400 } }) });
        const ctx = {
            CompanyIntegration: makeCI(APP_PASSWORD_CONFIG), ContextUser: contextUser,
            ObjectName: 'Post', Attributes: { status: 'nope' },
        } as unknown as CreateRecordContext;
        const result = await c.CreateRecord(ctx);
        expect(result.Success).toBe(false);
        expect(result.ErrorMessage).toContain('rest_invalid_param');
    });
});

describe('error classification from the WP_Error envelope', () => {
    let c: MockedWordPressConnector;
    beforeEach(() => { c = makeConnector(); });

    it('classifies 429 as retryable rate limiting', () => {
        const r = c.ClassifyWordPressResponse(429, { code: 'too_many_requests', message: 'slow down', data: { status: 429 } });
        expect(r.Code).toBe('RATE_LIMIT_EXCEEDED');
        expect(r.Retryable).toBe(true);
    });

    it('classifies 503 as retryable', () => {
        expect(c.ClassifyWordPressResponse(503, null).Retryable).toBe(true);
    });

    it('separates an HTML-bodied 403 (WAF / host block) from a JSON 403 (capability refusal)', () => {
        const waf = c.ClassifyWordPressResponse(403, '<html><body>Blocked</body></html>');
        expect(waf.Reason).toBe('waf-or-host-block-html-body');
        expect(waf.Retryable).toBe(false);
        expect(waf.VendorCode).toBeNull();

        const api = c.ClassifyWordPressResponse(403, { code: 'rest_forbidden', message: 'nope', data: { status: 403 } });
        expect(api.Reason).toBe('capability-or-credential');
        expect(api.VendorCode).toBe('rest_forbidden');
    });

    it('reads the stable machine code, never the localised message', () => {
        const r = c.ClassifyWordPressResponse(404, wpErrorNoRoute);
        expect(r.VendorCode).toBe('rest_no_route');
        expect(r.Reason).toBe('route-not-registered');
    });

    it('classifies a Woo 413 batch overflow as a validation error', () => {
        const r = c.ClassifyWordPressResponse(413, { code: 'woocommerce_rest_request_entity_too_large', message: 'too big', data: { status: 413 } });
        expect(r.Code).toBe('VALIDATION_ERROR');
        expect(r.VendorCode).toBe('woocommerce_rest_request_entity_too_large');
    });
});

describe('rate limiting', () => {
    it('throws 429 with headers intact so the engine can honour Retry-After', async () => {
        const c = makeConnector();
        const auth = await c.PublicAuthenticate(makeCI(APP_PASSWORD_CONFIG));
        c.Canned.push({ response: fail(429, { code: 'too_many_requests', message: 'x', data: { status: 429 } }, { 'retry-after': '30' }) });
        let thrown: unknown;
        try {
            await (c as unknown as {
                MakeHTTPRequest(a: RESTAuthContext, u: string, m: string, h: Record<string, string>): Promise<RESTResponse>;
            }).MakeHTTPRequest(auth, 'https://example.org/wp-json/wp/v2/posts?context=view', 'GET', {});
        } catch (e) { thrown = e; }
        expect(thrown).toBeInstanceOf(Error);
        expect(c.ExtractRetryAfterMs(thrown)).toBe(30_000);
    });

    it('parses the HTTP-date form of Retry-After', () => {
        const c = makeConnector();
        const when = new Date(Date.now() + 60_000).toUTCString();
        const ms = c.ExtractRetryAfterMs({ headers: { 'retry-after': when } });
        expect(ms).toBeGreaterThan(50_000);
        expect(ms).toBeLessThanOrEqual(61_000);
    });

    it('returns undefined when no Retry-After is present', () => {
        expect(makeConnector().ExtractRetryAfterMs(new Error('plain'))).toBeUndefined();
    });
});

describe('StableOrderingKey — the keyset/watermark engine contract', () => {
    it('returns null rather than guessing when the engine cache is unavailable', () => {
        expect(new WordPressConnector().StableOrderingKey('Post')).toBeNull();
    });

    // THE ROUND-0 DEFECT. `IntegrationEngine`'s §8a keyset block treats a StableOrderingKey and a
    // timestamp watermark as MUTUALLY EXCLUSIVE: any non-null key makes `isKeysetConnector` true, which
    // forces `initialWatermark = null` on every run AND clears the marker instead of saving a timestamp.
    // The connector previously declared `id` for EVERY object, so `FetchContext.WatermarkValue` was
    // always null, the `modified_after` builder below was never reached, and no watermark was ever
    // persisted — an incremental that silently full-re-listed forever while every unit test passed.
    it('withholds the keyset key for an object that declares a LIVE server-side watermark', () => {
        const c = makeConnector();
        Object.assign(c.IOFixtures.get('Post')!, { SupportsIncrementalSync: true, IncrementalWatermarkField: 'modified' });
        Object.assign(c.IOFixtures.get('Product')!, { SupportsIncrementalSync: true, IncrementalWatermarkField: 'date_modified_gmt' });
        expect(c.StableOrderingKey('Post')).toBeNull();
        expect(c.StableOrderingKey('Product')).toBeNull();
    });

    it('KEEPS the declared keyset key for a full-scan-only object (wp/v2/users declares no watermark)', () => {
        const c = makeConnector();
        expect(c.StableOrderingKey('User')).toBe('id');
    });

    it('KEEPS the keyset key when the watermark is DECORATIVE — a flag with no filter param on the wire', () => {
        // The six objects that register `modified_after` but expose no modified column carry a null
        // `incrementalWatermark` in metadata. A flag alone must never null the keyset key, because
        // nothing would then narrow the fetch AND the resume position would be gone too.
        const c = makeConnector();
        Object.assign(c.IOFixtures.get('User')!, { SupportsIncrementalSync: true, IncrementalWatermarkField: 'registered_date' });
        expect(c.StableOrderingKey('User')).toBe('id');
    });

    it('never declares BOTH signals for the same object — the invariant the engine cannot express', () => {
        const c = makeConnector();
        Object.assign(c.IOFixtures.get('Post')!, { SupportsIncrementalSync: true, IncrementalWatermarkField: 'modified' });
        Object.assign(c.IOFixtures.get('Product')!, { SupportsIncrementalSync: true, IncrementalWatermarkField: 'date_modified_gmt' });
        for (const [name, io] of c.IOFixtures) {
            const cfg = JSON.parse(io.Configuration ?? '{}') as { incrementalWatermark?: { filterParam?: string } | null };
            const hasLiveWatermark = !!io.SupportsIncrementalSync && !!io.IncrementalWatermarkField && !!cfg.incrementalWatermark?.filterParam;
            const declaresKeyset = c.StableOrderingKey(name) !== null;
            expect(hasLiveWatermark && declaresKeyset).toBe(false);
        }
    });
});

describe('incremental narrowing — the filter actually reaches the wire', () => {
    /** Seeds the two watermark-capable fixtures exactly as the applied metadata does. */
    function withWatermarks(c: ReturnType<typeof makeConnector>): ReturnType<typeof makeConnector> {
        Object.assign(c.IOFixtures.get('Post')!, { SupportsIncrementalSync: true, IncrementalWatermarkField: 'modified' });
        Object.assign(c.IOFixtures.get('Product')!, { SupportsIncrementalSync: true, IncrementalWatermarkField: 'date_modified_gmt' });
        return c;
    }

    it('PRESENT: a watermarked post type issues the server-side modified_after on the outgoing request', async () => {
        const c = withWatermarks(makeConnector());
        c.Canned.push({ response: ok(postsPage1, { 'x-wp-totalpages': '1' }) });

        await c.FetchChanges(fetchCtx({ ObjectName: 'Post', WatermarkValue: '2026-02-01T00:00:00' }));
        const collection = c.Captured.filter(r => r.url.includes('/wp/v2/posts') && !r.url.includes('status=trash'));
        expect(collection).toHaveLength(1);
        expect(collection[0].url).toContain('modified_after=2026-02-01T00%3A00%3A00');
        // The incremental pass re-sorts by the watermark so the max-seen advances monotonically.
        expect(collection[0].url).toContain('orderby=modified');
        // …and the soft-delete sweep on the same drained pass narrows too — a trash sweep that
        // re-listed the whole trash bin every run would put the full scan straight back.
        const sweep = c.Captured.filter(r => r.url.includes('status=trash'));
        expect(sweep).toHaveLength(1);
        expect(sweep[0].url).toContain('modified_after=2026-02-01T00%3A00%3A00');
    });

    it('PRESENT: a Woo CRUD resource issues modified_after AND dates_are_gmt=true', async () => {
        const c = withWatermarks(makeConnector());
        c.Canned.push({ response: ok(productsPage, { 'x-wp-totalpages': '1' }) });

        await c.FetchChanges(fetchCtx({ ObjectName: 'Product', WatermarkValue: '2026-04-01T00:00:00Z' }));
        expect(c.Captured[0].url).toContain('modified_after=2026-04-01T00%3A00%3A00Z');
        expect(c.Captured[0].url).toContain('dates_are_gmt=true');
    });

    it('ABSENT: a full-scan-only object issues NO date filter even when the engine hands it a watermark', async () => {
        const c = withWatermarks(makeConnector());
        c.Canned.push({ response: ok([{ id: 1, slug: 'admin' }], { 'x-wp-totalpages': '1' }) });

        await c.FetchChanges(fetchCtx({ ObjectName: 'User', WatermarkValue: '2026-04-01T00:00:00' }));
        expect(c.Captured[0].url).toContain('/wp/v2/users');
        expect(c.Captured[0].url).not.toContain('modified_after');
        expect(c.Captured[0].url).not.toContain('dates_are_gmt');
    });

    it('never sends modified_before — the engine supplies no upper bound, so a ceiling would be invented', async () => {
        const c = withWatermarks(makeConnector());
        c.Canned.push({ response: ok(postsPage1, { 'x-wp-totalpages': '1' }) });
        await c.FetchChanges(fetchCtx({ ObjectName: 'Post', WatermarkValue: '2026-02-01T00:00:00' }));
        for (const req of c.Captured) expect(req.url).not.toContain('modified_before');
    });

    it('the filter rides EVERY page of a multi-page incremental, not just the first', async () => {
        const c = withWatermarks(makeConnector());
        c.Canned.push({ response: ok(postsPage1, { 'x-wp-total': '3', 'x-wp-totalpages': '2' }) });
        c.Canned.push({ response: ok(postsPage2, { 'x-wp-total': '3', 'x-wp-totalpages': '2' }) });
        c.Canned.push({ response: ok([], { 'x-wp-totalpages': '1' }) });  // the trash sweep on the drained pass

        await c.FetchChanges(fetchCtx({ ObjectName: 'Post', WatermarkValue: '2026-02-01T00:00:00' }));
        const collection = c.Captured.filter(r => !r.url.includes('status=trash'));
        expect(collection).toHaveLength(2);
        expect(collection[0].url).toContain('page=1');
        expect(collection[1].url).toContain('page=2');
        for (const req of c.Captured) expect(req.url).toContain('modified_after=');
    });

    it('projects the engine\'s post-full-sync UTC instant into the SITE\'s wall clock for a site-local column', async () => {
        // After a clean FULL sync the engine replaces the connector's max-seen with wall-clock
        // `new Date().toISOString()` — a UTC instant. `modified_after` compares against the site-local
        // `post_modified` column, so on a UTC-5 site an unshifted UTC value skips a 5-hour window.
        const c = withWatermarks(makeConnector());
        c.Canned.push({ match: r => r.url.includes('/wp-json/?') || r.url.endsWith('/wp-json/'), response: ok(routeIndexFixture) });
        c.Canned.push({ response: ok(postsPage1, { 'x-wp-totalpages': '1' }) });

        await c.FetchChanges(fetchCtx({ ObjectName: 'Post', WatermarkValue: '2026-06-01T12:00:00.000Z' }));
        const collection = c.Captured.filter(r => r.url.includes('/wp/v2/posts') && !r.url.includes('status=trash'));
        expect(collection).toHaveLength(1);
        expect(collection[0].url).toContain('modified_after=2026-06-01T07%3A00%3A00');
        expect(collection[0].url).not.toContain('Z&');
    });

    it('does NOT shift a GMT-column object — dates_are_gmt already puts it on the _gmt columns', async () => {
        const c = withWatermarks(makeConnector());
        c.Canned.push({ response: ok(productsPage, { 'x-wp-totalpages': '1' }) });
        await c.FetchChanges(fetchCtx({ ObjectName: 'Product', WatermarkValue: '2026-06-01T12:00:00.000Z' }));
        expect(c.Captured[0].url).toContain('modified_after=2026-06-01T12%3A00%3A00Z');
    });

    it('does NOT shift a round-tripped value — it is already in the column\'s own representation', async () => {
        const c = withWatermarks(makeConnector());
        c.Canned.push({ response: ok(postsPage1, { 'x-wp-totalpages': '1' }) });
        await c.FetchChanges(fetchCtx({ ObjectName: 'Post', WatermarkValue: '2026-06-01T12:00:00' }));
        // No designator → no site-offset lookup at all, so no route-index request was needed.
        expect(c.Captured.every(r => r.url.includes('/wp/v2/posts'))).toBe(true);
        for (const req of c.Captured) expect(req.url).toContain('modified_after=2026-06-01T12%3A00%3A00');
    });

    it('sends the UTC instant UNSHIFTED, and says so, when the site publishes no gmt_offset', async () => {
        const c = withWatermarks(makeConnector());
        const { gmt_offset: _dropped, ...noOffsetIndex } = routeIndexFixture;
        c.Canned.push({ match: r => r.url.includes('/wp-json/'), response: ok(noOffsetIndex) });
        c.Canned.push({ response: ok(postsPage1, { 'x-wp-totalpages': '1' }) });

        await c.FetchChanges(fetchCtx({ ObjectName: 'Post', WatermarkValue: '2026-06-01T12:00:00.000Z' }));
        const collection = c.Captured.filter(r => r.url.includes('/wp/v2/posts') && !r.url.includes('status=trash'));
        expect(collection[0].url).toContain('modified_after=2026-06-01T12%3A00%3A00Z');
    });
});

describe('TestConnection', () => {
    it('succeeds when the route index answers AND the Application Password authenticates', async () => {
        const c = makeConnector();
        c.Canned.push({ response: ok(routeIndexFixture) });
        c.Canned.push({ response: ok({ id: 1, slug: 'svc_user' }) });
        const result = await c.TestConnection(makeCI(APP_PASSWORD_CONFIG), contextUser);
        expect(result.Success).toBe(true);
        expect(result.Message).toContain('wp/v2 + wc/v3');
    });

    it('reports the Woo-only asymmetry explicitly when only a consumer key/secret is supplied', async () => {
        const c = makeConnector();
        c.Canned.push({ response: ok(routeIndexFixture) });
        c.Canned.push({ response: ok([{ slug: 'countries' }]) });
        const result = await c.TestConnection(makeCI({
            siteUrl: 'https://example.org', apiRoot: 'https://example.org/wp-json',
            wooConsumerKey: 'ck', wooConsumerSecret: 'cs',
        }), contextUser);
        expect(result.Success).toBe(true);
        expect(result.Message).toContain('wc/v3 ONLY');
    });

    it('fails, with a useful message, when the site is reachable but no credential is configured', async () => {
        const c = makeConnector();
        c.Canned.push({ response: ok(routeIndexFixture) });
        const result = await c.TestConnection(makeCI({ siteUrl: 'https://example.org', apiRoot: 'https://example.org/wp-json' }), contextUser);
        expect(result.Success).toBe(false);
        expect(result.Message).toContain('NO credential is configured');
    });

    it('fails when the credential is rejected', async () => {
        const c = makeConnector();
        c.Canned.push({ response: ok(routeIndexFixture) });
        c.Canned.push({ response: fail(401, { code: 'rest_not_logged_in', message: 'x', data: { status: 401 } }) });
        c.Canned.push({ response: fail(401, { code: 'rest_not_logged_in', message: 'x', data: { status: 401 } }) });
        const result = await c.TestConnection(makeCI(APP_PASSWORD_CONFIG), contextUser);
        expect(result.Success).toBe(false);
        expect(result.Message).toContain('credential was rejected');
    });

    it('fails cleanly when the site is not a WordPress REST API at all', async () => {
        const c = makeConnector();
        c.Canned.push({ response: ok({ hello: 'world' }) });
        c.Canned.push({ response: ok({ hello: 'world' }) });
        const result = await c.TestConnection(makeCI(APP_PASSWORD_CONFIG), contextUser);
        expect(result.Success).toBe(false);
    });
});

describe('multi-tenant isolation', () => {
    it('two connections resolve independent auth contexts and do not cross-contaminate', async () => {
        const c = makeConnector();
        const a = await c.PublicAuthenticate(makeCI(APP_PASSWORD_CONFIG));
        const bCI = {
            ID: 'ci-2', IntegrationID: 'int-1', Name: 'WordPress', CredentialID: null,
            Configuration: JSON.stringify({ siteUrl: 'https://other.example', apiRoot: 'https://other.example/wp-json', username: 'u2', applicationPassword: 'p2' }),
        } as unknown as MJCompanyIntegrationEntity;
        const b = await c.PublicAuthenticate(bCI);
        expect(c.PublicGetBaseURL(makeCI({}), a)).toBe('https://example.org/wp-json');
        expect(c.PublicGetBaseURL(makeCI({}), b)).toBe('https://other.example/wp-json');
        expect(c.PublicBuildHeaders(a).Authorization).not.toBe(c.PublicBuildHeaders(b).Authorization);
    });
});

describe('no baked catalog', () => {
    it('the connector source contains no module-level object/field catalog constant', async () => {
        const { readFileSync } = await import('node:fs');
        const { fileURLToPath } = await import('node:url');
        const src = readFileSync(fileURLToPath(new URL('../WordPressConnector.ts', import.meta.url)), 'utf-8');
        expect(/^const\s+\w*(STREAMS|FIELD_CATALOG|OBJECTS|CATALOG)\b/m.test(src)).toBe(false);
        // The declared object names live in metadata, never here.
        for (const declaredOnlyInMetadata of ['ProductShippingClass', 'ReportTopSeller', 'UserApplicationPassword']) {
            expect(src.includes(declaredOnlyInMetadata)).toBe(false);
        }
    });
});
