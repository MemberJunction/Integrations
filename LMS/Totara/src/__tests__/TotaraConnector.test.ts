import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
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
import { IntegrationEngineBase } from '@memberjunction/integration-engine-base';
import { TotaraConnector, type TotaraAuthContext, type MoodleRPCRequest } from '../TotaraConnector.js';

// ─── Fixtures ──────────────────────────────────────────────────────────────
// Shapes descend from the Moodle/Totara Web Services REST-RPC surface documented in the frozen contract:
//   PROVENANCE: metadata/integrations/totara/.totara.integration.json (Declared, credential-free docs).
// All synthetic-but-shaped; no PII, no live endpoint contacted (T4/T5 mocked tier).

const seededAuth: TotaraAuthContext = {
    Token: 'WSTOKEN-ABC-123',
    Endpoint: 'https://learn.example.org/webservice/rest/server.php',
};

/** Moodle exception envelope (HTTP 200 body signalling an error). */
const exceptionBody = {
    exception: 'moodle_exception',
    errorcode: 'invalidtoken',
    message: 'Invalid token - token not found',
    debuginfo: '',
};

/** core_course_get_courses returns a BARE array (responseEnvelopeKey=null). */
const coursesBody = [
    { id: 2, fullname: 'Intro to Rheumatology', shortname: 'RHEU-101', categoryid: 3, visible: 1 },
    { id: 5, fullname: 'Advanced Immunology', shortname: 'IMM-301', categoryid: 3, visible: 1 },
];

/** core_user_get_users wraps records under `users`. */
const usersBody = {
    users: [
        { id: 10, username: 'jdoe', firstname: 'J', lastname: 'Doe', email: 'a@example.com' },
        { id: 11, username: 'rroe', firstname: 'R', lastname: 'Roe', email: 'b@example.com' },
    ],
};

/** core_notes_get_course_notes returns THREE record collections that must be unioned. */
const notesBody = {
    sitenotes: [{ id: 1, content: 'site note', userid: 10 }],
    coursenotes: [{ id: 2, content: 'course note', userid: 11 }],
    personalnotes: [{ id: 3, content: 'personal note', userid: 10 }],
};

/** hierarchy_organisation_index returns `{items, page, pages, total}` pagination metadata. */
const orgsBodyPage1 = {
    items: [{ id: 100, fullname: 'HQ' }, { id: 101, fullname: 'Field' }],
    page: 1,
    pages: 2,
    total: 3,
};

/** core_course_create_courses returns an array of created records with `id`. */
const createdCoursesBody = [{ id: 42, shortname: 'NEW-1' }];
/** core_course_create_courses that returned NO id (must fail loudly). */
const createdNoIdBody: unknown[] = [];

// ─── Entity fixture builders ─────────────────────────────────────────────────

function makeIO(over: Partial<MJIntegrationObjectEntity> & { ID: string; Name: string; Configuration: string }): MJIntegrationObjectEntity {
    return {
        DisplayName: over.Name,
        Description: 'fixture',
        APIPath: '/webservice/rest/server.php',
        ResponseDataKey: null,
        DefaultPageSize: 0,
        SupportsPagination: false,
        PaginationType: 'None',
        SupportsIncrementalSync: false,
        SupportsWrite: false,
        IncrementalWatermarkField: null,
        Status: 'Active',
        CreateAPIPath: null,
        CreateMethod: null,
        UpdateAPIPath: null,
        UpdateMethod: null,
        DeleteAPIPath: null,
        DeleteMethod: null,
        ...over,
    } as unknown as MJIntegrationObjectEntity;
}

function makeIOF(over: Partial<MJIntegrationObjectFieldEntity> & { Name: string }): MJIntegrationObjectFieldEntity {
    return {
        Type: 'string', IsPrimaryKey: false, IsRequired: false, IsReadOnly: false, IsUniqueKey: false,
        Sequence: 0, Status: 'Active', RelatedIntegrationObjectID: null, Length: null, Precision: null, Scale: null,
        DefaultValue: null, DisplayName: over.Name, Description: null, ...over,
    } as unknown as MJIntegrationObjectFieldEntity;
}

const idPK = (): MJIntegrationObjectFieldEntity[] => [
    makeIOF({ Name: 'id', IsPrimaryKey: true, IsRequired: true, IsUniqueKey: true, Type: 'integer', Sequence: 0 }),
    makeIOF({ Name: 'fullname', Type: 'string', Sequence: 1 }),
    makeIOF({ Name: 'timecreated', Type: 'integer', IsReadOnly: true, Sequence: 2 }),
];

// ─── Mocked connector (captures the RPC request, no live endpoint) ───────────

interface CapturedRequest { url: string; method: string; headers: Record<string, string>; body: MoodleRPCRequest | undefined; }

class MockedTotaraConnector extends TotaraConnector {
    public Captured: CapturedRequest[] = [];
    public Responses: RESTResponse[] = [];
    public IOFixtures = new Map<string, MJIntegrationObjectEntity>();
    public IOFFixtures = new Map<string, MJIntegrationObjectFieldEntity[]>();

    protected override async ParseConfig(): Promise<never> {
        return { Token: seededAuth.Token, BaseURL: 'https://learn.example.org' } as never;
    }

    protected override async MakeHTTPRequest(
        _auth: RESTAuthContext, url: string, method: string, headers: Record<string, string>, body?: unknown,
    ): Promise<RESTResponse> {
        this.Captured.push({ url, method, headers, body: body as MoodleRPCRequest | undefined });
        const next = this.Responses.shift();
        if (!next) throw new Error(`MockedTotaraConnector: no canned response queued for ${method} ${url}`);
        return next;
    }

    protected override GetCachedObject(_integrationID: string, objectName: string): MJIntegrationObjectEntity {
        const io = this.IOFixtures.get(objectName);
        if (!io) throw new Error(`test IO fixture missing: ${objectName}`);
        return io;
    }
    protected override GetCachedFields(objectID: string): MJIntegrationObjectFieldEntity[] {
        return this.IOFFixtures.get(objectID) ?? [];
    }

    // Exposed protected seams for direct unit assertions.
    public PublicNormalize(body: unknown, key: string | null): Record<string, unknown>[] { return this.NormalizeResponse(body, key); }
    public PublicPagination(body: unknown, type: PaginationType, page = 1, offset = 0, size = 50): { HasMore: boolean; NextPage?: number; NextOffset?: number } {
        return this.ExtractPaginationInfo(body, type, page, offset, size);
    }
    public PublicHeaders(): Record<string, string> { return this.BuildHeaders(seededAuth); }

    public seedIO(io: MJIntegrationObjectEntity, fields: MJIntegrationObjectFieldEntity[]): void {
        this.IOFixtures.set(io.Name, io);
        this.IOFFixtures.set(io.ID, fields);
    }
    public queue(...bodies: unknown[]): void {
        for (const b of bodies) this.Responses.push({ Status: 200, Body: b, Headers: {} });
    }
}

/** Exposes the REAL MakeHTTPRequest (no override) so the urlencoded wire body can be asserted. */
class RealTransportTotaraConnector extends TotaraConnector {
    public async PublicMakeHTTP(auth: RESTAuthContext, url: string, body: unknown): Promise<RESTResponse> {
        return this.MakeHTTPRequest(auth, url, 'POST', this.BuildHeaders(auth), body);
    }
}

const ci = { ID: 'ci-1', IntegrationID: 'int-1', Configuration: null, CredentialID: null } as unknown as MJCompanyIntegrationEntity;
const user = {} as never;

function fetchCtx(objectName: string, over?: Partial<FetchContext>): FetchContext {
    return { CompanyIntegration: ci, ObjectName: objectName, WatermarkValue: null, BatchSize: 100, ContextUser: user, ...over };
}

// IO Configuration JSON (mirrors metadata/integrations/totara/.totara.integration.json).
const coursesCfg = JSON.stringify({ wsfunction: 'core_course_get_courses', responseEnvelopeKey: null, stableOrderingKey: 'id', writeFunctions: { create: 'core_course_create_courses', update: 'core_course_update_courses', delete: 'core_course_delete_courses', createResponseIDField: 'id', updateIDField: 'courses[0][id]', deleteIDField: 'courseids[0]' } });
const usersCfg = JSON.stringify({ wsfunction: 'core_user_get_users', responseEnvelopeKey: 'users', stableOrderingKey: 'id' });
const notesCfg = JSON.stringify({ wsfunction: 'core_notes_get_course_notes', responseEnvelopeKey: 'sitenotes', recordCollectionKeys: ['sitenotes', 'coursenotes', 'personalnotes'], stableOrderingKey: 'id' });
const enrolledCfg = JSON.stringify({ wsfunction: 'core_enrol_get_enrolled_users', responseEnvelopeKey: null, paginationParams: ['options.limitfrom', 'options.limitnumber'], writeFunctions: { create: 'enrol_manual_enrol_users', delete: 'enrol_manual_unenrol_users', createResponseIDField: null } });
const badgesCfg = JSON.stringify({ wsfunction: 'core_badges_get_user_badges', responseEnvelopeKey: 'badges', paginationParams: ['page', 'perpage'] });

// ═══════════════════════════════════════════════════════════════════════════

describe('TotaraConnector — identity + capabilities', () => {
    it('IntegrationName is the verbatim MJ: Integrations.Name (totara)', () => {
        expect(new TotaraConnector().IntegrationName).toBe('totara');
    });

    it('declares Create + Update + Delete and NON-authoritative discovery (token-scoped site info)', () => {
        const c = new TotaraConnector();
        expect(c.SupportsCreate).toBe(true);
        expect(c.SupportsUpdate).toBe(true);
        expect(c.SupportsDelete).toBe(true);
        expect(c.DiscoveryIsAuthoritative).toBe(false);
    });
});

describe('TotaraConnector — BuildHeaders (wstoken is NOT a header)', () => {
    it('sends urlencoded content-type with NO Authorization header', () => {
        const h = new MockedTotaraConnector().PublicHeaders();
        expect(h['Content-Type']).toContain('application/x-www-form-urlencoded');
        expect(h['Accept']).toBe('application/json');
        expect(h['Authorization']).toBeUndefined();
    });
});

describe('TotaraConnector — MakeHTTPRequest (wstoken + format + wsfunction as PARAMS)', () => {
    let calls: Array<{ url: string; init: RequestInit }>;
    beforeEach(() => {
        calls = [];
        vi.stubGlobal('fetch', vi.fn(async (url: string, init: RequestInit) => {
            calls.push({ url, init });
            return { status: 200, text: async () => JSON.stringify(coursesBody), headers: new Headers({ 'content-type': 'application/json' }) } as unknown as Response;
        }));
    });
    afterEach(() => vi.unstubAllGlobals());

    it('urlencodes wstoken, moodlewsrestformat=json, wsfunction, and params into the POST body', async () => {
        const c = new RealTransportTotaraConnector();
        const req: MoodleRPCRequest = { WsFunction: 'core_course_get_courses', Params: { limitfrom: 0, 'options[0][name]': 'x' } };
        const res = await c.PublicMakeHTTP(seededAuth, seededAuth.Endpoint, req);

        expect(calls).toHaveLength(1);
        expect(calls[0].url).toBe(seededAuth.Endpoint);
        expect(calls[0].init.method).toBe('POST');
        const bodyStr = String(calls[0].init.body);
        expect(bodyStr).toContain('wstoken=WSTOKEN-ABC-123');
        expect(bodyStr).toContain('moodlewsrestformat=json');
        expect(bodyStr).toContain('wsfunction=core_course_get_courses');
        expect(bodyStr).toContain('limitfrom=0');
        // bracket keys are percent-encoded but round-trip to Moodle array syntax
        expect(decodeURIComponent(bodyStr)).toContain('options[0][name]=x');
        expect(Array.isArray(res.Body)).toBe(true);
    });
});

describe('TotaraConnector — TestConnection (site-info + resilient fallback)', () => {
    let c: MockedTotaraConnector;
    beforeEach(() => { c = new MockedTotaraConnector(); });

    it('succeeds when core_webservice_get_site_info returns site info', async () => {
        c.queue({ sitename: 'ACR Learn', release: '4.1.2' });
        const res = await c.TestConnection(ci, user);
        expect(res.Success).toBe(true);
        expect(res.ServerVersion).toBe('4.1.2');
        expect(c.Captured).toHaveLength(1);   // site-info only; no fallback needed
        expect(c.Captured[0].body?.WsFunction).toBe('core_webservice_get_site_info');
    });

    it('FALLS BACK to a real read when get_site_info throws a NON-auth codingerror ("No service found")', async () => {
        c.queue(
            { exception: 'moodle_exception', errorcode: 'codingerror', message: 'No service found in get_site_info' },
            [{ id: 1, name: 'Cat' }],   // core_course_get_categories returns a record array → connected
        );
        const res = await c.TestConnection(ci, user);
        expect(res.Success).toBe(true);
        expect(c.Captured.map(r => r.body?.WsFunction)).toEqual(['core_webservice_get_site_info', 'core_course_get_categories']);
    });

    it('reports failure (no fallback) on a genuine auth error (invalidtoken)', async () => {
        c.queue({ exception: 'webservice_access_exception', errorcode: 'invalidtoken', message: 'Invalid token - token not found' });
        const res = await c.TestConnection(ci, user);
        expect(res.Success).toBe(false);
        expect(res.Message).toMatch(/authentication failed/i);
        expect(c.Captured).toHaveLength(1);   // terminal — never attempts the fallback read
    });

    it('reports failure when get_site_info is unavailable AND the fallback read also fails', async () => {
        c.queue(
            { exception: 'moodle_exception', errorcode: 'codingerror', message: 'No service found in get_site_info' },
            { exception: 'moodle_exception', errorcode: 'servererror', message: 'read failed' },
        );
        const res = await c.TestConnection(ci, user);
        expect(res.Success).toBe(false);
    });
});

describe('TotaraConnector — NormalizeResponse (exception envelope + record extraction)', () => {
    const c = new MockedTotaraConnector();

    it('THROWS with the errorcode when the 200 body is a Moodle exception envelope', () => {
        expect(() => c.PublicNormalize(exceptionBody, null)).toThrow(/invalidtoken/);
    });

    it('extracts a BARE top-level array (responseEnvelopeKey=null)', () => {
        const recs = c.PublicNormalize(coursesBody, null);
        expect(recs).toHaveLength(2);
        expect(recs[0].id).toBe(2);
    });

    it('extracts records under a single envelope key', () => {
        const recs = c.PublicNormalize(usersBody, 'users');
        expect(recs).toHaveLength(2);
        expect(recs[1].username).toBe('rroe');
    });

    it('wraps a single wrapped object into a one-element array', () => {
        const recs = c.PublicNormalize({ completionstatus: { completed: true, aggregation: 1 } }, 'completionstatus');
        expect(recs).toHaveLength(1);
        expect(recs[0].completed).toBe(true);
    });

    it('returns [] when the declared envelope key is absent', () => {
        expect(c.PublicNormalize({ other: [] }, 'users')).toEqual([]);
    });
});

describe('TotaraConnector — ExtractPaginationInfo', () => {
    const c = new MockedTotaraConnector();

    it('None → never HasMore', () => {
        expect(c.PublicPagination(coursesBody, 'None').HasMore).toBe(false);
    });

    it('Offset — a FULL page means HasMore + advances NextOffset by the page count', () => {
        const full = [{ id: 1 }, { id: 2 }];
        const p = c.PublicPagination(full, 'Offset', 1, 10, 2);
        expect(p.HasMore).toBe(true);
        expect(p.NextOffset).toBe(12);
    });

    it('Offset — a PARTIAL page means no more', () => {
        expect(c.PublicPagination([{ id: 1 }], 'Offset', 1, 0, 2).HasMore).toBe(false);
    });

    it('PageNumber — uses page/pages metadata when present (exact stop)', () => {
        expect(c.PublicPagination(orgsBodyPage1, 'PageNumber', 1, 0, 50).HasMore).toBe(true);
        expect(c.PublicPagination(orgsBodyPage1, 'PageNumber', 1, 0, 50).NextPage).toBe(2);
        const lastPage = { items: [{ id: 1 }], page: 2, pages: 2 };
        expect(c.PublicPagination(lastPage, 'PageNumber', 2, 0, 50).HasMore).toBe(false);
    });
});

describe('TotaraConnector — FetchChanges (Moodle REST-RPC read)', () => {
    let c: MockedTotaraConnector;
    beforeEach(() => { c = new MockedTotaraConnector(); });

    it('reads a BARE-list object and passes the FULL source record through Fields', async () => {
        c.seedIO(makeIO({ ID: 'io-c', Name: 'Courses', Configuration: coursesCfg }), idPK());
        c.queue(coursesBody);
        const res = await c.FetchChanges(fetchCtx('Courses'));

        expect(c.Captured[0].body?.WsFunction).toBe('core_course_get_courses');
        expect(res.Records).toHaveLength(2);
        expect(res.Records[0].ExternalID).toBe('2');
        // full-record pass-through — every source key reaches Fields
        expect(res.Records[0].Fields).toMatchObject({ id: 2, fullname: 'Intro to Rheumatology', shortname: 'RHEU-101', categoryid: 3 });
    });

    it('extracts records under a single envelope key (Users → users[])', async () => {
        c.seedIO(makeIO({ ID: 'io-u', Name: 'Users', Configuration: usersCfg }), idPK());
        c.queue(usersBody);
        const res = await c.FetchChanges(fetchCtx('Users'));
        expect(res.Records).toHaveLength(2);
        expect(res.Records[0].Fields.username).toBe('jdoe');
    });

    it('PARENT-SCOPED: iterates ONE request per parent course (Enrolled Users → courseid) + tags each child', async () => {
        const cfg = JSON.stringify({ wsfunction: 'core_enrol_get_enrolled_users', responseEnvelopeKey: null,
            parentScope: { parentWsFunction: 'core_course_get_courses', paramName: 'courseid', parentIdField: 'id' } });
        c.seedIO(makeIO({ ID: 'io-eu', Name: 'Enrolled Users', Configuration: cfg }), idPK());
        c.queue(
            [{ id: 1 }, { id: 2 }],              // core_course_get_courses → parent ids
            [{ id: 10, fullname: 'Alice' }],     // enrolled users for course 1
            [{ id: 11, fullname: 'Bob' }],       // enrolled users for course 2
        );
        const res = await c.FetchChanges(fetchCtx('Enrolled Users'));
        // one parent-list call, then one request per course carrying the courseid param
        expect(c.Captured.map(r => r.body?.WsFunction)).toEqual(['core_course_get_courses', 'core_enrol_get_enrolled_users', 'core_enrol_get_enrolled_users']);
        expect(c.Captured[1].body?.Params).toMatchObject({ courseid: '1' });
        expect(c.Captured[2].body?.Params).toMatchObject({ courseid: '2' });
        // both children aggregated + tagged with their parent courseid
        expect(res.Records).toHaveLength(2);
        expect(res.Records[0].Fields).toMatchObject({ id: 10, fullname: 'Alice', courseid: '1' });
        expect(res.Records[1].Fields).toMatchObject({ id: 11, fullname: 'Bob', courseid: '2' });
    });

    it('PARENT-SCOPED: a per-parent error is a WARNING, never fatal to the batch', async () => {
        const cfg = JSON.stringify({ wsfunction: 'core_enrol_get_enrolled_users', responseEnvelopeKey: null,
            parentScope: { parentWsFunction: 'core_course_get_courses', paramName: 'courseid', parentIdField: 'id' } });
        c.seedIO(makeIO({ ID: 'io-eu2', Name: 'Enrolled Users', Configuration: cfg }), idPK());
        c.queue(
            [{ id: 1 }, { id: 2 }],
            { exception: 'moodle_exception', errorcode: 'accessexception', message: 'Access control exception' }, // course 1 → error
            [{ id: 11, fullname: 'Bob' }],       // course 2 → ok
        );
        const res = await c.FetchChanges(fetchCtx('Enrolled Users'));
        expect(res.Records).toHaveLength(1);     // course 2 still lands despite course 1 failing
        expect(res.Records[0].Fields).toMatchObject({ id: 11 });
        expect(res.Warnings?.some(w => w.Code === 'PARENT_FETCH_ERROR')).toBe(true);
    });

    it('reads the envelope key from the first-class ResponseDataKey COLUMN when Configuration omits it (frozen-metadata shape)', async () => {
        // Mirrors the real Totara metadata: ResponseDataKey column carries the key; Configuration.responseEnvelopeKey is null.
        const cfgNoEnv = JSON.stringify({ wsfunction: 'core_user_get_users', responseEnvelopeKey: null, stableOrderingKey: 'id' });
        c.seedIO(makeIO({ ID: 'io-u2', Name: 'Users', Configuration: cfgNoEnv, ResponseDataKey: 'users' }), idPK());
        c.queue(usersBody);
        const res = await c.FetchChanges(fetchCtx('Users'));
        expect(res.Records).toHaveLength(2); // NOT 1 (would be the bogus wrapper record if the column were ignored)
        expect(res.Records[0].Fields.username).toBe('jdoe');
        expect(res.Records[1].ExternalID).toBe('11');
    });

    it('UNIONS multi-collection envelopes (Notes → sitenotes + coursenotes + personalnotes)', async () => {
        c.seedIO(makeIO({ ID: 'io-n', Name: 'Notes', Configuration: notesCfg }), idPK());
        c.queue(notesBody);
        const res = await c.FetchChanges(fetchCtx('Notes'));
        expect(res.Records).toHaveLength(3);
        expect(res.Records.map(r => r.Fields.content)).toEqual(['site note', 'course note', 'personal note']);
    });

    it('Offset pagination — emits the Moodle options-array limitfrom/limitnumber params', async () => {
        c.seedIO(makeIO({ ID: 'io-e', Name: 'Enrolled Users', Configuration: enrolledCfg, SupportsPagination: true, PaginationType: 'Offset', DefaultPageSize: 50 }), idPK());
        c.queue([{ id: 1 }]);
        await c.FetchChanges(fetchCtx('Enrolled Users', { CurrentOffset: 100 }));
        const p = c.Captured[0].body?.Params ?? {};
        expect(p['options[0][name]']).toBe('limitfrom');
        expect(p['options[0][value]']).toBe(100);
        expect(p['options[1][name]']).toBe('limitnumber');
        expect(p['options[1][value]']).toBe(50);
    });

    it('PageNumber pagination — emits page + perpage', async () => {
        c.seedIO(makeIO({ ID: 'io-b', Name: 'User Badges', Configuration: badgesCfg, SupportsPagination: true, PaginationType: 'PageNumber', DefaultPageSize: 25 }), idPK());
        c.queue({ badges: [{ id: 9 }] });
        await c.FetchChanges(fetchCtx('User Badges', { CurrentPage: 3 }));
        const p = c.Captured[0].body?.Params ?? {};
        expect(p['page']).toBe(3);
        expect(p['perpage']).toBe(25);
    });

    it('surfaces a Moodle exception as an ERROR (throws — never a silent empty)', async () => {
        c.seedIO(makeIO({ ID: 'io-c', Name: 'Courses', Configuration: coursesCfg }), idPK());
        c.queue(exceptionBody);
        await expect(c.FetchChanges(fetchCtx('Courses'))).rejects.toThrow(/invalidtoken/);
    });

    it('returns a NO_WSFUNCTION warning when the object has no wsfunction configured', async () => {
        c.seedIO(makeIO({ ID: 'io-x', Name: 'Broken', Configuration: JSON.stringify({}) }), idPK());
        const res = await c.FetchChanges(fetchCtx('Broken'));
        expect(res.Records).toHaveLength(0);
        expect(res.Warnings?.[0].Code).toBe('NO_WSFUNCTION');
    });
});

describe('TotaraConnector — CreateRecord (bracket-notation array body)', () => {
    let c: MockedTotaraConnector;
    const coursesWriteIO = () => makeIO({
        ID: 'io-c', Name: 'Courses', Configuration: coursesCfg,
        CreateAPIPath: '/webservice/rest/server.php', CreateMethod: 'POST',
    });
    beforeEach(() => { c = new MockedTotaraConnector(); });

    it('builds courses[0][field] params, extracts the created id, and returns Success', async () => {
        c.seedIO(coursesWriteIO(), idPK());
        c.queue(createdCoursesBody);
        const ctx: CreateRecordContext = { CompanyIntegration: ci, ContextUser: user, ObjectName: 'Courses', Attributes: { fullname: 'New Course', shortname: 'NEW-1' } };
        const res = await c.CreateRecord(ctx);

        expect(c.Captured[0].body?.WsFunction).toBe('core_course_create_courses');
        const p = c.Captured[0].body?.Params ?? {};
        expect(p['courses[0][fullname]']).toBe('New Course');
        expect(p['courses[0][shortname]']).toBe('NEW-1');
        expect(res.Success).toBe(true);
        expect(res.ExternalID).toBe('42');
    });

    it('drops IsReadOnly fields from the write body', async () => {
        c.seedIO(coursesWriteIO(), idPK());
        c.queue(createdCoursesBody);
        const ctx: CreateRecordContext = { CompanyIntegration: ci, ContextUser: user, ObjectName: 'Courses', Attributes: { fullname: 'X', timecreated: 12345 } };
        await c.CreateRecord(ctx);
        const p = c.Captured[0].body?.Params ?? {};
        expect(p['courses[0][timecreated]']).toBeUndefined(); // read-only filtered
        expect(p['courses[0][fullname]']).toBe('X');
    });

    it('FAILS LOUDLY when a 2xx create returns no record id (never Success:true with empty ExternalID)', async () => {
        c.seedIO(coursesWriteIO(), idPK());
        c.queue(createdNoIdBody);
        const ctx: CreateRecordContext = { CompanyIntegration: ci, ContextUser: user, ObjectName: 'Courses', Attributes: { fullname: 'Y' } };
        const res = await c.CreateRecord(ctx);
        expect(res.Success).toBe(false);
    });

    it('an ASSOCIATION create (no server id) synthesizes a deterministic identity → Success', async () => {
        c.seedIO(makeIO({ ID: 'io-e', Name: 'Enrolled Users', Configuration: enrolledCfg, CreateAPIPath: '/webservice/rest/server.php', CreateMethod: 'POST' }), idPK());
        c.queue(null); // enrol_manual_enrol_users returns null on success
        const ctx: CreateRecordContext = { CompanyIntegration: ci, ContextUser: user, ObjectName: 'Enrolled Users', Attributes: { userid: 10, courseid: 2, roleid: 5 } };
        const res = await c.CreateRecord(ctx);
        expect(c.Captured[0].body?.WsFunction).toBe('enrol_manual_enrol_users');
        expect(res.Success).toBe(true);
        expect((res.ExternalID ?? '').length).toBeGreaterThan(0);
    });

    it('returns failure with the errorcode when the create body is a Moodle exception', async () => {
        c.seedIO(coursesWriteIO(), idPK());
        c.queue(exceptionBody);
        const ctx: CreateRecordContext = { CompanyIntegration: ci, ContextUser: user, ObjectName: 'Courses', Attributes: { fullname: 'Z' } };
        const res = await c.CreateRecord(ctx);
        expect(res.Success).toBe(false);
        expect(res.ErrorMessage).toContain('invalidtoken');
    });
});

describe('TotaraConnector — UpdateRecord / DeleteRecord', () => {
    let c: MockedTotaraConnector;
    beforeEach(() => { c = new MockedTotaraConnector(); });

    it('Update injects the ExternalID under the PK field inside courses[0][id]', async () => {
        c.seedIO(makeIO({ ID: 'io-c', Name: 'Courses', Configuration: coursesCfg, UpdateAPIPath: '/webservice/rest/server.php', UpdateMethod: 'POST' }), idPK());
        c.queue(null);
        const ctx: UpdateRecordContext = { CompanyIntegration: ci, ContextUser: user, ObjectName: 'Courses', ExternalID: '42', Attributes: { fullname: 'Renamed' } };
        const res = await c.UpdateRecord(ctx);
        expect(c.Captured[0].body?.WsFunction).toBe('core_course_update_courses');
        const p = c.Captured[0].body?.Params ?? {};
        expect(p['courses[0][id]']).toBe('42');
        expect(p['courses[0][fullname]']).toBe('Renamed');
        expect(res.Success).toBe(true);
        expect(res.ExternalID).toBe('42');
    });

    it('Delete sends the ExternalID in the courseids[0] Moodle ids array', async () => {
        c.seedIO(makeIO({ ID: 'io-c', Name: 'Courses', Configuration: coursesCfg, DeleteAPIPath: '/webservice/rest/server.php', DeleteMethod: 'POST' }), idPK());
        c.queue(null);
        const ctx: DeleteRecordContext = { CompanyIntegration: ci, ContextUser: user, ObjectName: 'Courses', ExternalID: '42' };
        const res = await c.DeleteRecord(ctx);
        expect(c.Captured[0].body?.WsFunction).toBe('core_course_delete_courses');
        expect((c.Captured[0].body?.Params ?? {})['courseids[0]']).toBe('42');
        expect(res.Success).toBe(true);
    });
});

describe('TotaraConnector — StableOrderingKey (keyset hint from IO Configuration)', () => {
    beforeEach(() => {
        IntegrationEngineBase.Instance.SeedForTesting({
            Integrations: [{ ID: 'int-totara', Name: 'totara' }],
            IntegrationObjects: [{ ID: 'io-courses', IntegrationID: 'int-totara', Name: 'Courses', Status: 'Active', Configuration: coursesCfg }],
        });
    });

    it('returns the declared stableOrderingKey for a known object', () => {
        expect(new TotaraConnector().StableOrderingKey('Courses')).toBe('id');
    });

    it('returns null for an unknown object (keyset resume simply unavailable)', () => {
        expect(new TotaraConnector().StableOrderingKey('Nonexistent')).toBeNull();
    });
});
