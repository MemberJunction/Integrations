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
    RequestTimeoutMs: 25000,
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

    /**
     * Controllable clock for the parent-walk budget. `null` = the real one. A function makes elapsed time
     * deterministic without fake timers, which would deadlock here — the walk awaits real promises.
     */
    public Clock: (() => number) | null = null;
    protected override nowMs(): number { return this.Clock ? this.Clock() : super.nowMs(); }
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

    it('passes an abort signal carrying the resolved deadline, so a silent vendor cannot hang the fetch', async () => {
        // The original transport passed no signal at all: a site that accepts the connection and then
        // never answers wedged the worker with no failed run and no artifact anyone could read.
        const c = new RealTransportTotaraConnector();
        await c.PublicMakeHTTP(seededAuth, seededAuth.Endpoint,
            { WsFunction: 'core_course_get_courses', Params: {} } as MoodleRPCRequest);

        expect(calls[0].init.signal).toBeInstanceOf(AbortSignal);
    });

    it('translates an abort into a named error identifying the function and the deadline', async () => {
        vi.stubGlobal('fetch', vi.fn(async () => {
            const err = new Error('The operation was aborted due to timeout');
            err.name = 'TimeoutError';
            throw err;
        }));
        const c = new RealTransportTotaraConnector();

        await expect(c.PublicMakeHTTP({ ...seededAuth, RequestTimeoutMs: 1234 }, seededAuth.Endpoint,
            { WsFunction: 'core_enrol_get_enrolled_users', Params: {} } as MoodleRPCRequest))
            .rejects.toThrow(/core_enrol_get_enrolled_users" did not respond within 1234ms/);
    });

    it('a non-abort transport error is re-thrown untouched, not relabelled as a timeout', async () => {
        vi.stubGlobal('fetch', vi.fn(async () => { throw new Error('ECONNREFUSED'); }));
        const c = new RealTransportTotaraConnector();

        await expect(c.PublicMakeHTTP(seededAuth, seededAuth.Endpoint,
            { WsFunction: 'core_course_get_courses', Params: {} } as MoodleRPCRequest))
            .rejects.toThrow('ECONNREFUSED');
    });

    it('RequestTimeoutMs:0 opts out — no signal is passed', async () => {
        // Some sites legitimately have a function slower than any sane default; the escape hatch has to
        // exist, and it has to be the connection's choice rather than a code edit.
        const c = new RealTransportTotaraConnector();
        await c.PublicMakeHTTP({ ...seededAuth, RequestTimeoutMs: 0 }, seededAuth.Endpoint,
            { WsFunction: 'core_course_get_courses', Params: {} } as MoodleRPCRequest);

        expect(calls[0].init.signal).toBeUndefined();
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

    // ── ID-WINDOW SCAN ────────────────────────────────────────────────────
    // core_user_get_users declares no pagination and the vendor docs warn it "could [be] very slow or
    // timeout" without narrow criteria. Live, the criteria=email:% bulk list timed out 3x at 30s and synced
    // ZERO users behind a green run. Reads now walk the id space in bounded windows against the documented
    // bulk reader instead. windowSize is kept tiny here so the wire assertions stay readable.
    const scanCfg = (over: Record<string, unknown> = {}) => JSON.stringify({
        wsfunction: 'core_user_get_users', responseEnvelopeKey: 'users', stableOrderingKey: 'id',
        idWindowScan: { wsFunction: 'core_user_get_users_by_field', field: 'id', windowSize: 2, windowsPerCall: 2, maxConsecutiveEmptyWindows: 2, ...over },
    });

    it('ID-WINDOW SCAN: bounded PK lookups against the bulk reader — never the unbounded criteria search', async () => {
        c.seedIO(makeIO({ ID: 'io-scan', Name: 'Users', Configuration: scanCfg() }), idPK());
        c.queue([{ id: 1, username: 'a' }, { id: 2, username: 'b' }], [{ id: 3, username: 'c' }]);
        const res = await c.FetchChanges(fetchCtx('Users'));

        // every call is the BULK by-field reader; the unbounded core_user_get_users is never issued
        expect(c.Captured.map(r => r.body?.WsFunction)).toEqual(['core_user_get_users_by_field', 'core_user_get_users_by_field']);
        expect(c.Captured.some(r => r.body?.WsFunction === 'core_user_get_users')).toBe(false);
        // contiguous id windows in Moodle bracket-array notation
        expect(c.Captured[0].body?.Params).toMatchObject({ field: 'id', 'values[0]': 1, 'values[1]': 2 });
        expect(c.Captured[1].body?.Params).toMatchObject({ field: 'id', 'values[0]': 3, 'values[1]': 4 });
        expect(res.Records.map(r => r.ExternalID)).toEqual(['1', '2', '3']);
        // more to scan → keyset cursor carries the next start id and the empty-run counter
        expect(res.HasMore).toBe(true);
        expect(res.NextAfterKeyValue).toBe('5|0|3|0');
    });

    it('ID-WINDOW SCAN: resumes from the keyset cursor instead of re-reading from id 1', async () => {
        c.seedIO(makeIO({ ID: 'io-scan2', Name: 'Users', Configuration: scanCfg() }), idPK());
        c.queue([{ id: 401 }], [{ id: 403 }]);
        const res = await c.FetchChanges(fetchCtx('Users', { AfterKeyValue: '401|1' }));
        expect(c.Captured[0].body?.Params).toMatchObject({ 'values[0]': 401, 'values[1]': 402 });
        expect(res.NextAfterKeyValue).toBe('405|0|403|0');   // records found → empty-run resets
    });

    it('ID-WINDOW SCAN: stops after N consecutive EMPTY windows and says so out loud (never a silent truncation)', async () => {
        c.seedIO(makeIO({ ID: 'io-scan3', Name: 'Users', Configuration: scanCfg() }), idPK());
        c.queue([], []);                              // two empty windows === maxConsecutiveEmptyWindows
        const res = await c.FetchChanges(fetchCtx('Users'));
        expect(res.HasMore).toBe(false);
        expect(res.NextAfterKeyValue).toBeUndefined();
        const end = res.Warnings?.find(w => w.Code === 'ID_WINDOW_SCAN_END');
        expect(end).toBeDefined();                     // a stop is ALWAYS reported, with the range scanned
        expect(end?.Data).toMatchObject({ scannedThrough: 4, windowSize: 2, maxConsecutiveEmptyWindows: 2 });
    });

    it('ID-WINDOW SCAN: a FAILED window is not an empty one — it cannot trip the stop heuristic', async () => {
        // The truncation trap: if an errored window counted as empty, a blip would end the scan early and
        // silently drop every user past it. A window whose ids the vendor refuses is bisected and skipped by
        // id, but it must NEVER be counted toward the past-the-end heuristic.
        const fail = { exception: 'moodle_exception', errorcode: 'servererror', message: 'upstream blew up' };
        c.seedIO(makeIO({ ID: 'io-scan4', Name: 'Users', Configuration: scanCfg() }), idPK());
        c.queue(
            [],                                     // window 1 (ids 1-2): genuinely empty
            fail,                                   // window 2 (ids 3-4): FAILED → bisect
            fail, fail,                             // id 3: first try + retry
            fail, fail,                             // id 4: first try + retry
        );
        const res = await c.FetchChanges(fetchCtx('Users'));
        expect(res.Warnings?.some(w => w.Code === 'ID_WINDOW_FETCH_ERROR')).toBe(true);
        expect(res.Warnings?.some(w => w.Code === 'ID_WINDOW_SCAN_END')).toBe(false);  // NOT stopped
        expect(res.HasMore).toBe(true);
        // Past the refused window (nothing is left behind unexamined), and the empty-run still counts ONLY
        // the genuinely empty window — the refused one contributed nothing to the stop decision.
        expect(res.NextAfterKeyValue).toBe('5|1|0|2');
    });

    it('ID-WINDOW SCAN: an unreadable window with the budget ALREADY spent still advances the cursor', async () => {
        // The live stall, in miniature: budget gone AND the first window unreadable. If the deadline applied
        // here the call would resolve no id at all, return empty with an unchanged cursor, and repeat forever
        // — the exact symptom the whole scan exists to remove. The deadline is therefore suspended until one
        // id has been examined, and the descent to find it goes down the left spine only.
        const invalid = { exception: 'moodle_exception', errorcode: 'invalidresponse', message: 'Invalid response value detected' };
        c.seedIO(makeIO({ ID: 'io-scan7', Name: 'Users', Configuration: scanCfg({ budgetMs: 0, windowSize: 4, windowsPerCall: 1 }) }), idPK());
        c.queue(
            invalid,             // window ids 1-4
            invalid,             // left half ids 1-2
            invalid, invalid,    // id 1 alone: first try + retry → skipped
        );
        const res = await c.FetchChanges(fetchCtx('Users'));
        expect(res.Warnings?.find(w => w.Code === 'ID_WINDOW_RECORD_SKIPPED')?.Data).toMatchObject({ id: 1 });
        expect(res.HasMore).toBe(true);
        expect(res.NextAfterKeyValue).toBe('2|0|0|1');   // moved past id 1 — the cursor is never stuck again
    });

    it('ID-WINDOW SCAN: isolates the ONE id the vendor refuses and keeps the rest of the window', async () => {
        // Live failure mode: Moodle/Totara validate their own response per record, so a single bad user row
        // fails the whole call with [invalidresponse]. Before bisection that killed the window, the cursor
        // never advanced, and the object synced 0 rows forever. One bad user must cost one user.
        const invalid = { exception: 'moodle_exception', errorcode: 'invalidresponse', message: 'Invalid response value detected' };
        c.seedIO(makeIO({ ID: 'io-scan6', Name: 'Users', Configuration: scanCfg() }), idPK());
        c.queue(
            invalid,                 // window 1 (ids 1-2) fails because of id 1
            invalid, invalid,        // id 1 alone: first try + retry → skipped
            [{ id: 2 }],             // id 2 alone: reads fine
            [{ id: 3 }, { id: 4 }],  // window 2 (ids 3-4): normal
        );
        const res = await c.FetchChanges(fetchCtx('Users'));
        const skip = res.Warnings?.find(w => w.Code === 'ID_WINDOW_RECORD_SKIPPED');
        expect(skip?.Data).toMatchObject({ id: 1, field: 'id' });         // names the exact unreadable id
        expect(res.Records.map(r => r.ExternalID)).toEqual(['2', '3', '4']);   // the good rows all survive
        expect(res.HasMore).toBe(true);
        expect(res.NextAfterKeyValue).toBe('5|0|4|0');                        // and the scan MOVES ON
    });

    it('ID-WINDOW SCAN: stops at the fetch budget and resumes, instead of being killed with nothing to show', async () => {
        // The engine kills a FetchChanges that overruns FetchChangesMs and a killed batch persists NOTHING —
        // which is how the first live run of this scan died (5 windows, 30000ms, 0 users). With budgetMs=0
        // every window after the first is skipped, so the call returns the first window's rows plus a cursor.
        c.seedIO(makeIO({ ID: 'io-scan5', Name: 'Users', Configuration: scanCfg({ budgetMs: 0, windowsPerCall: 3 }) }), idPK());
        c.queue([{ id: 1, username: 'a' }], [{ id: 3, username: 'c' }], [{ id: 5, username: 'e' }]);
        const res = await c.FetchChanges(fetchCtx('Users'));

        expect(c.Captured.length).toBe(1);              // ONE window attempted — the rest never started
        expect(res.Records.length).toBe(1);             // and its rows are kept, not thrown away
        expect(res.HasMore).toBe(true);
        expect(res.NextAfterKeyValue).toBe('3|0|1|0');      // resumes exactly where the budget cut it off
        const stop = res.Warnings?.find(w => w.Code === 'ID_WINDOW_BUDGET_STOP');
        expect(stop).toBeDefined();                     // a short batch is always explained, never silent
        expect(stop?.Data).toMatchObject({ scannedThrough: 2, windowSize: 2 });
    });

    it('ID-WINDOW SCAN: an already-spent budget still attempts one window, so the cursor can never stall', async () => {
        // Guard against the deadlock the deadline could otherwise create: skip EVERY window and the call
        // returns no rows with an unchanged cursor — the same call, forever.
        c.seedIO(makeIO({ ID: 'io-scan6', Name: 'Users', Configuration: scanCfg({ budgetMs: 0 }) }), idPK());
        c.queue([{ id: 1, username: 'a' }], [{ id: 3, username: 'c' }]);
        const res = await c.FetchChanges(fetchCtx('Users'));
        expect(c.Captured.length).toBeGreaterThanOrEqual(1);
        expect(res.NextAfterKeyValue).not.toBe('1|0');   // the cursor MOVED
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
        // A non-permission fault stays per-parent, because it genuinely is per-parent. Permission refusals are
        // attributed separately as LEAF_FORBIDDEN (see the two refusal tests below) — one ungranted credential
        // is one fact, not one fault per id.
        const cfg = JSON.stringify({ wsfunction: 'core_enrol_get_enrolled_users', responseEnvelopeKey: null,
            parentScope: { parentWsFunction: 'core_course_get_courses', paramName: 'courseid', parentIdField: 'id' } });
        c.seedIO(makeIO({ ID: 'io-eu2', Name: 'Enrolled Users', Configuration: cfg }), idPK());
        c.queue(
            [{ id: 1 }, { id: 2 }],
            { exception: 'moodle_exception', errorcode: 'invalidrecord', message: 'Can not find data record in database' }, // course 1 → error
            [{ id: 11, fullname: 'Bob' }],       // course 2 → ok
        );
        const res = await c.FetchChanges(fetchCtx('Enrolled Users'));
        expect(res.Records).toHaveLength(1);     // course 2 still lands despite course 1 failing
        expect(res.Records[0].Fields).toMatchObject({ id: 11 });
        expect(res.Warnings?.some(w => w.Code === 'PARENT_FETCH_ERROR')).toBe(true);
    });

    it('PARENT-SCOPED (array param): Cohort Members sends cohortids[0], not a scalar cohortid', async () => {
        // REGRESSION. core_cohort_get_cohort_members takes an ARRAY of ids; sending it a scalar (or nothing at
        // all, which is what an unscoped object sends) is answered with [invalidparameter] and the object
        // lands 0 rows on every run — it did, on every live run, until this was wired.
        const cfg = JSON.stringify({ wsfunction: 'core_cohort_get_cohort_members', responseEnvelopeKey: null,
            parentScope: { parentWsFunction: 'core_cohort_get_cohorts', paramName: 'cohortids',
                paramStyle: 'array', childIdField: 'cohortid', parentIdField: 'id' } });
        c.seedIO(makeIO({ ID: 'io-cm', Name: 'Cohort Members', Configuration: cfg }), idPK());
        c.queue(
            [{ id: 7 }, { id: 9 }],                       // core_cohort_get_cohorts → parent ids
            [{ cohortid: 7, userids: [1, 2] }],           // members of cohort 7
            [{ userids: [3] }],                           // cohort 9 answers WITHOUT echoing cohortid
        );
        const res = await c.FetchChanges(fetchCtx('Cohort Members'));
        expect(c.Captured[1].body?.Params).toEqual({ 'cohortids[0]': '7' });
        expect(c.Captured[2].body?.Params).toEqual({ 'cohortids[0]': '9' });
        // the tag uses the CHILD field name (cohortid), never the plural request param
        expect(res.Records[1].Fields).toMatchObject({ userids: [3], cohortid: '9' });
        expect(res.Records[1].Fields.cohortids).toBeUndefined();
    });

    it('CHAINED PARENT SCOPE: Group Members reaches its ids through Courses -> course groups', async () => {
        // core_group_get_group_members(groupids[]) is a by-id reader and NOTHING in Moodle lists a site's
        // groups, so one hop cannot name a single id — the object shipped dispatching the function bare, which
        // is the [invalidparameter] defect Cohort Members had. Two hops: courses -> that course's groups ->
        // group ids -> members.
        const cfg = JSON.stringify({ wsfunction: 'core_group_get_group_members', responseEnvelopeKey: null,
            parentScope: {
                parentWsFunction: 'core_group_get_course_groups', paramName: 'groupids', paramStyle: 'array',
                childIdField: 'groupid', parentIdField: 'id',
                parentScope: { parentWsFunction: 'core_course_get_courses', paramName: 'courseid',
                    paramStyle: 'scalar', parentIdField: 'id' },
            } });
        c.seedIO(makeIO({ ID: 'io-gm', Name: 'Group Members', Configuration: cfg }), idPK());
        c.queue(
            [{ id: 1 }, { id: 2 }],                       // core_course_get_courses  → course ids
            [{ id: 30, courseid: 1 }],                    // course 1 → group 30
            [{ id: 31, courseid: 2 }],                    // course 2 → group 31
            [{ groupid: 30, userids: [5, 6] }],           // members of group 30
            [{ userids: [7] }],                           // group 31 answers WITHOUT echoing groupid
        );
        const res = await c.FetchChanges(fetchCtx('Group Members'));

        // Hop 2 is scoped by the scalar param the inner level declares...
        expect(c.Captured[1].body?.WsFunction).toBe('core_group_get_course_groups');
        expect(c.Captured[1].body?.Params).toEqual({ courseid: '1' });
        expect(c.Captured[2].body?.Params).toEqual({ courseid: '2' });
        // ...and the object's own request takes the resolved GROUP ids in array form.
        expect(c.Captured[3].body?.WsFunction).toBe('core_group_get_group_members');
        expect(c.Captured[3].body?.Params).toEqual({ 'groupids[0]': '30' });
        expect(c.Captured[4].body?.Params).toEqual({ 'groupids[0]': '31' });
        expect(res.Records).toHaveLength(2);
        expect(res.Records[1].Fields).toMatchObject({ userids: [7], groupid: '31' });
    });

    it('CHAINED PARENT SCOPE: an upstream hop that errors costs its own ids, not the whole enumeration', async () => {
        const cfg = JSON.stringify({ wsfunction: 'core_group_get_group_members', responseEnvelopeKey: null,
            parentScope: {
                parentWsFunction: 'core_group_get_course_groups', paramName: 'groupids', paramStyle: 'array',
                childIdField: 'groupid', parentIdField: 'id',
                parentScope: { parentWsFunction: 'core_course_get_courses', paramName: 'courseid',
                    paramStyle: 'scalar', parentIdField: 'id' },
            } });
        c.seedIO(makeIO({ ID: 'io-gm2', Name: 'Group Members', Configuration: cfg }), idPK());
        c.queue(
            [{ id: 1 }, { id: 2 }],
            { exception: 'moodle_exception', errorcode: 'accessexception', message: 'Access control exception' },
            [{ id: 31 }],
            [{ groupid: 31, userids: [7] }],
        );
        const res = await c.FetchChanges(fetchCtx('Group Members'));
        expect(res.Records).toHaveLength(1);
        expect(res.Records[0].Fields).toMatchObject({ groupid: 31 });
    });

    it('CHAINED PARENT SCOPE: a chain cut short by the budget says so, and is not cached as complete', async () => {
        // The enumeration costs one request per upstream id, so on a real site it competes with the walk for
        // the same budget. A truncated chain is an INCOMPLETE parent list: reporting it is what keeps a short
        // walk from reading as a complete one, and not caching it is what lets the next call finish the job.
        const cfg = JSON.stringify({ wsfunction: 'core_group_get_group_members', responseEnvelopeKey: null,
            parentScope: {
                parentWsFunction: 'core_group_get_course_groups', paramName: 'groupids', paramStyle: 'array',
                childIdField: 'groupid', parentIdField: 'id', budgetMs: 50,
                parentScope: { parentWsFunction: 'core_course_get_courses', paramName: 'courseid',
                    paramStyle: 'scalar', parentIdField: 'id' },
            } });
        c.seedIO(makeIO({ ID: 'io-gm3', Name: 'Group Members', Configuration: cfg }), idPK());
        c.queue([{ id: 1 }, { id: 2 }, { id: 3 }], [{ id: 30 }], [{ id: 31 }], [{ id: 32 }],
            [{ groupid: 30, userids: [1] }]);
        let reads = 0;
        c.Clock = () => (reads++ === 0 ? 0 : 1000);   // every request looks like it consumed the whole budget

        const res = await c.FetchChanges(fetchCtx('Group Members'));

        const w = res.Warnings?.find(x => x.Code === 'PARENT_CHAIN_TRUNCATED');
        expect(w?.Data).toMatchObject({ object: 'Group Members' });
        expect(w?.Message).toContain('re-enumerated');
    });

    it('PARENT-SCOPED: stops at the wall-clock budget and resumes, instead of being killed with nothing', async () => {
        // Enrolled Users walks one call per course; 428 courses did not fit FetchChangesMs and the batch was
        // killed with 0 records on every live run. The budget stops DISPATCHING and keeps what landed.
        const cfg = JSON.stringify({ wsfunction: 'core_enrol_get_enrolled_users', responseEnvelopeKey: null,
            parentScope: { parentWsFunction: 'core_course_get_courses', paramName: 'courseid', parentIdField: 'id', budgetMs: 50 } });
        c.seedIO(makeIO({ ID: 'io-eu3', Name: 'Enrolled Users', Configuration: cfg }), idPK());
        c.queue([{ id: 1 }, { id: 2 }, { id: 3 }], [{ id: 10 }], [{ id: 11 }], [{ id: 12 }]);
        let reads = 0;
        c.Clock = () => (reads++ === 0 ? 0 : 1000);   // the first read starts the clock; every later one is past the budget

        const res = await c.FetchChanges(fetchCtx('Enrolled Users'));
        expect(c.Captured.map(r => r.body?.WsFunction))
            .toEqual(['core_course_get_courses', 'core_enrol_get_enrolled_users']);   // ONE parent attempted
        expect(res.Records).toHaveLength(1);          // and its rows are KEPT, not discarded
        expect(res.HasMore).toBe(true);
        expect(res.NextAfterKeyValue).toBe('1');      // cursor covers only the contiguous prefix examined
        const stop = res.Warnings?.find(w => w.Code === 'PARENT_BUDGET_STOP');
        expect(stop?.Data).toMatchObject({ covered: 1, batch: 3, skipped: 2, budgetMs: 50 });
    });

    it('PARENT-SCOPED: PAGES within one parent when the function documents limitfrom/limitnumber', async () => {
        // A per-CALL budget cannot save a single request that is itself too big:
        // core_enrol_get_enrolled_users returns every enrolment on a course with full user profiles, and on a
        // real site ONE such call outran the 30000ms kill — persisting nothing. The walk pages inside the parent.
        const cfg = JSON.stringify({ wsfunction: 'core_enrol_get_enrolled_users', responseEnvelopeKey: null,
            paginationParams: ['options.limitfrom', 'options.limitnumber'],
            parentScope: { parentWsFunction: 'core_course_get_courses', paramName: 'courseid', parentIdField: 'id', pageSize: 2 } });
        c.seedIO(makeIO({ ID: 'io-eu5', Name: 'Enrolled Users', Configuration: cfg }), idPK());
        c.queue(
            [{ id: 1 }],                          // one course
            [{ id: 10 }, { id: 11 }],             // full page → there is more
            [{ id: 12 }],                         // short page → this course is exhausted
        );
        const res = await c.FetchChanges(fetchCtx('Enrolled Users'));
        expect(c.Captured[1].body?.Params).toMatchObject({ courseid: '1', 'options[0][name]': 'limitfrom', 'options[0][value]': 0, 'options[1][name]': 'limitnumber', 'options[1][value]': 2 });
        expect(c.Captured[2].body?.Params).toMatchObject({ courseid: '1', 'options[0][value]': 2 });   // second page
        expect(res.Records).toHaveLength(3);
        expect(res.HasMore).toBe(false);          // the only course was read to the end
    });

    it('PARENT-SCOPED: a mid-parent budget stop resumes INTO that parent, not at its first page again', async () => {
        const cfg = JSON.stringify({ wsfunction: 'core_enrol_get_enrolled_users', responseEnvelopeKey: null,
            paginationParams: ['options.limitfrom', 'options.limitnumber'],
            parentScope: { parentWsFunction: 'core_course_get_courses', paramName: 'courseid', parentIdField: 'id', pageSize: 2, budgetMs: 50 } });
        c.seedIO(makeIO({ ID: 'io-eu6', Name: 'Enrolled Users', Configuration: cfg }), idPK());
        c.queue([{ id: 1 }, { id: 2 }], [{ id: 10 }, { id: 11 }]);   // full page, then the budget bites
        let reads = 0;
        c.Clock = () => (reads++ === 0 ? 0 : 1000);

        const res = await c.FetchChanges(fetchCtx('Enrolled Users'));
        expect(res.Records).toHaveLength(2);              // the page that landed is KEPT
        expect(res.NextAfterKeyValue).toBe('1#2');        // resume AT course 1, from record 2
        const stop = res.Warnings?.find(w => w.Code === 'PARENT_BUDGET_STOP');
        expect(stop?.Data).toMatchObject({ covered: 0, resumeOffset: 2 });

        // and the resume actually starts there rather than re-reading the first page
        const c2 = new MockedTotaraConnector();
        c2.seedIO(makeIO({ ID: 'io-eu6', Name: 'Enrolled Users', Configuration: cfg }), idPK());
        c2.queue([{ id: 1 }, { id: 2 }], [{ id: 12 }], [{ id: 20 }]);
        await c2.FetchChanges(fetchCtx('Enrolled Users', { AfterKeyValue: '1#2' }));
        expect(c2.Captured[1].body?.Params).toMatchObject({ courseid: '1', 'options[0][value]': 2 });
        expect(c2.Captured[2].body?.Params).toMatchObject({ courseid: '2', 'options[0][value]': 0 });
    });

    it('PARENT-SCOPED: a PAGED walk runs ONE parent at a time however much concurrency the engine offers', async () => {
        // The cursor can name exactly one mid-parent resume offset, and only for the head of the covered
        // prefix. Read two parents concurrently and let the budget stop both, and the second lane's offset is
        // discarded — so it re-reads its pages from 0 on the next call, every call. Live (MaxConcurrency 2,
        // run 9200B480): 50,608 records fetched for 29,002 rows, a 1.74x re-read that was purely this.
        const cfg = JSON.stringify({ wsfunction: 'core_enrol_get_enrolled_users', responseEnvelopeKey: null,
            paginationParams: ['options.limitfrom', 'options.limitnumber'],
            parentScope: { parentWsFunction: 'core_course_get_courses', paramName: 'courseid', parentIdField: 'id', pageSize: 2 } });
        c.seedIO(makeIO({ ID: 'io-eu-seq', Name: 'Enrolled Users', Configuration: cfg }), idPK());
        c.queue(
            [{ id: 1 }, { id: 2 }],               // two courses
            [{ id: 10 }, { id: 11 }],             // course 1, full page
            [{ id: 12 }],                         // course 1, short page → exhausted
            [{ id: 20 }],                         // course 2, short page → exhausted
        );
        const res = await c.FetchChanges(fetchCtx('Enrolled Users', { MaxConcurrency: 8 }));
        // Course 1 is read to the END before course 2 is touched at all — no interleaving.
        expect(c.Captured.map(r => r.body?.Params?.['courseid'])).toEqual([undefined, '1', '1', '2']);
        expect(res.Records).toHaveLength(4);
    });

    it('PARENT-SCOPED: an UNPAGED walk keeps the engine concurrency (no partial progress to lose)', async () => {
        const cfg = JSON.stringify({ wsfunction: 'core_group_get_course_groups', responseEnvelopeKey: null,
            parentScope: { parentWsFunction: 'core_course_get_courses', paramName: 'courseid', parentIdField: 'id' } });
        c.seedIO(makeIO({ ID: 'io-grp-conc', Name: 'Groups', Configuration: cfg }), idPK());
        c.queue([{ id: 1 }, { id: 2 }], [{ id: 10 }], [{ id: 20 }]);
        const res = await c.FetchChanges(fetchCtx('Groups', { MaxConcurrency: 4 }));
        expect(res.Records).toHaveLength(2);   // one request per parent, both read
    });

    it('PARENT-SCOPED: offset paging sends the DECLARED stable ordering, so pages cannot overlap or gap', async () => {
        // limitfrom/limitnumber is SQL OFFSET/LIMIT. Without ORDER BY there is no defined page boundary:
        // consecutive pages repeat rows and may never return others (the gaps are silent data loss). The vendor
        // documents sortby/sortdirection beside the limits and the catalog already declared stableOrderingKey.
        const cfg = JSON.stringify({ wsfunction: 'core_enrol_get_enrolled_users', responseEnvelopeKey: null,
            paginationParams: ['options.limitfrom', 'options.limitnumber'],
            orderingParams: ['options.sortby', 'options.sortdirection'],
            stableOrderingKey: 'id',
            parentScope: { parentWsFunction: 'core_course_get_courses', paramName: 'courseid', parentIdField: 'id', pageSize: 2 } });
        c.seedIO(makeIO({ ID: 'io-eu-ord', Name: 'Enrolled Users', Configuration: cfg }), idPK());
        c.queue([{ id: 1 }], [{ id: 10 }]);
        await c.FetchChanges(fetchCtx('Enrolled Users'));
        // All four options share ONE bracket array — ordering must not restart the indexes and clobber the limits.
        expect(c.Captured[1].body?.Params).toMatchObject({
            courseid: '1',
            'options[0][name]': 'limitfrom', 'options[0][value]': 0,
            'options[1][name]': 'limitnumber', 'options[1][value]': 2,
            'options[2][name]': 'sortby', 'options[2][value]': 'id',
            'options[3][name]': 'sortdirection', 'options[3][value]': 'ASC',
        });
    });

    it('PARENT-SCOPED: an object declaring no orderingParams is UNCHANGED (option names are per-wsfunction)', async () => {
        const cfg = JSON.stringify({ wsfunction: 'core_enrol_get_enrolled_users', responseEnvelopeKey: null,
            paginationParams: ['options.limitfrom', 'options.limitnumber'], stableOrderingKey: 'id',
            parentScope: { parentWsFunction: 'core_course_get_courses', paramName: 'courseid', parentIdField: 'id', pageSize: 2 } });
        c.seedIO(makeIO({ ID: 'io-eu-noord', Name: 'Enrolled Users', Configuration: cfg }), idPK());
        c.queue([{ id: 1 }], [{ id: 10 }]);
        await c.FetchChanges(fetchCtx('Enrolled Users'));
        expect(c.Captured[1].body?.Params).not.toHaveProperty('options[2][name]');
    });

    it('PARENT-SCOPED: a walk the vendor refuses on PERMISSIONS says so ONCE, not once per parent', async () => {
        // Live (run DE595754): core_group_get_group_members answered [accessexception] for all 52 batches of
        // group ids. Reported per-parent that reads like 52 separate faults; it is one ungranted credential.
        const cfg = JSON.stringify({ wsfunction: 'core_group_get_group_members', responseEnvelopeKey: null,
            parentScope: { parentWsFunction: 'core_course_get_courses', paramName: 'groupids', paramStyle: 'array',
                childIdField: 'groupid', parentIdField: 'id' } });
        c.seedIO(makeIO({ ID: 'io-gm-forbid', Name: 'Group Members', Configuration: cfg }), idPK());
        c.queue(
            [{ id: 1 }, { id: 2 }],
            { exception: 'webservice_access_exception', errorcode: 'accessexception', message: 'Access control exception' },
            { exception: 'webservice_access_exception', errorcode: 'accessexception', message: 'Access control exception' },
        );
        const res = await c.FetchChanges(fetchCtx('Group Members'));
        expect(res.Records).toHaveLength(0);
        expect(res.Warnings?.filter(w => w.Code === 'PARENT_FETCH_ERROR')).toHaveLength(0);
        const forbidden = res.Warnings?.filter(w => w.Code === 'LEAF_FORBIDDEN') ?? [];
        expect(forbidden).toHaveLength(1);
        expect(forbidden[0].Data).toMatchObject({ wsfunction: 'core_group_get_group_members', refusedParents: 2 });
        expect(forbidden[0].Message).toContain('not permitted this function');
    });

    it('PARENT-SCOPED: a PARTIAL permission refusal stays distinguishable from an ungranted function', async () => {
        const cfg = JSON.stringify({ wsfunction: 'core_group_get_group_members', responseEnvelopeKey: null,
            parentScope: { parentWsFunction: 'core_course_get_courses', paramName: 'groupids', paramStyle: 'array',
                childIdField: 'groupid', parentIdField: 'id' } });
        c.seedIO(makeIO({ ID: 'io-gm-part', Name: 'Group Members', Configuration: cfg }), idPK());
        c.queue(
            [{ id: 1 }, { id: 2 }],
            [{ id: 10 }],
            { exception: 'webservice_access_exception', errorcode: 'accessexception', message: 'Access control exception' },
        );
        const res = await c.FetchChanges(fetchCtx('Group Members'));
        expect(res.Records).toHaveLength(1);
        const forbidden = res.Warnings?.find(w => w.Code === 'LEAF_FORBIDDEN');
        expect(forbidden?.Data).toMatchObject({ refusedParents: 1, examined: 2 });
        expect(forbidden?.Message).not.toContain('not permitted this function');
    });

    it('PARENT-SCOPED: an already-spent budget still fetches ONE parent, so the walk can never stall', async () => {
        // Skipping every parent would return no rows with an unchanged cursor — the same call, forever.
        const cfg = JSON.stringify({ wsfunction: 'core_enrol_get_enrolled_users', responseEnvelopeKey: null,
            parentScope: { parentWsFunction: 'core_course_get_courses', paramName: 'courseid', parentIdField: 'id', budgetMs: 1 } });
        c.seedIO(makeIO({ ID: 'io-eu4', Name: 'Enrolled Users', Configuration: cfg }), idPK());
        c.queue([{ id: 1 }, { id: 2 }], [{ id: 10 }]);
        let reads = 0;
        c.Clock = () => (reads++ === 0 ? 0 : 10_000_000);   // the budget is gone the instant the walk starts

        const res = await c.FetchChanges(fetchCtx('Enrolled Users'));
        expect(res.Records).toHaveLength(1);
        expect(res.NextAfterKeyValue).toBe('1');   // the cursor MOVED
        expect(res.HasMore).toBe(true);
    });

    it('PARENT-SCOPED: the budget stops work ABOUT TO START, judged by the slowest request so far', async () => {
        // `elapsed >= budget` is the wrong test when one request is a large fraction of the whole budget:
        // live, a single enrolled-users page took 25823ms, so a walk 900ms into a 1000ms budget would happily
        // dispatch one more and land 26s past the kill. The gate is `elapsed + slowestSoFar >= budget`.
        const cfg = JSON.stringify({ wsfunction: 'core_enrol_get_enrolled_users', responseEnvelopeKey: null,
            parentScope: { parentWsFunction: 'core_course_get_courses', paramName: 'courseid', parentIdField: 'id', budgetMs: 1000 } });
        c.seedIO(makeIO({ ID: 'io-eu7', Name: 'Enrolled Users', Configuration: cfg }), idPK());
        c.queue([{ id: 1 }, { id: 2 }], [{ id: 10 }], [{ id: 11 }]);
        let reads = 0;
        c.Clock = () => (reads++ < 2 ? 0 : 900);   // the parent list took 900ms; elapsed stays 900 thereafter

        const res = await c.FetchChanges(fetchCtx('Enrolled Users'));
        // elapsed (900) is UNDER the 1000ms budget — the old rule would have started another 900ms request.
        expect(c.Captured.map(r => r.body?.WsFunction))
            .toEqual(['core_course_get_courses', 'core_enrol_get_enrolled_users']);
        expect(res.Records).toHaveLength(1);
        expect(res.Warnings?.find(w => w.Code === 'PARENT_BUDGET_STOP')?.Data).toMatchObject({ covered: 1, skipped: 1 });
    });

    it('PARENT-SCOPED: the parent-id list is cached across calls, and parentCacheMs:0 opts out', async () => {
        // core_course_get_courses measured 6147ms live. Re-reading it on every resumed call spends a fifth of
        // the budget before the walk begins — on a list that cannot change meaningfully inside one sync.
        const cfg = JSON.stringify({ wsfunction: 'core_enrol_get_enrolled_users', responseEnvelopeKey: null,
            parentScope: { parentWsFunction: 'core_course_get_courses', paramName: 'courseid', parentIdField: 'id' } });
        c.seedIO(makeIO({ ID: 'io-eu8', Name: 'Enrolled Users', Configuration: cfg }), idPK());
        c.queue([{ id: 1 }], [{ id: 10 }], [{ id: 11 }]);
        await c.FetchChanges(fetchCtx('Enrolled Users'));
        await c.FetchChanges(fetchCtx('Enrolled Users'));
        expect(c.Captured.filter(r => r.body?.WsFunction === 'core_course_get_courses')).toHaveLength(1);

        const c2 = new MockedTotaraConnector();
        const cfgNoCache = JSON.stringify({ wsfunction: 'core_enrol_get_enrolled_users', responseEnvelopeKey: null,
            parentScope: { parentWsFunction: 'core_course_get_courses', paramName: 'courseid', parentIdField: 'id', parentCacheMs: 0 } });
        c2.seedIO(makeIO({ ID: 'io-eu8', Name: 'Enrolled Users', Configuration: cfgNoCache }), idPK());
        c2.queue([{ id: 1 }], [{ id: 10 }], [{ id: 1 }], [{ id: 11 }]);
        await c2.FetchChanges(fetchCtx('Enrolled Users'));
        await c2.FetchChanges(fetchCtx('Enrolled Users'));
        expect(c2.Captured.filter(r => r.body?.WsFunction === 'core_course_get_courses')).toHaveLength(2);
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
