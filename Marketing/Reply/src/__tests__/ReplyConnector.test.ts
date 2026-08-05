import { readFileSync } from 'node:fs';
import { join } from 'node:path';
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
import { ReplyConnector } from '../ReplyConnector.js';

// ─── Fixtures ─────────────────────────────────────────────────────────────
//
// READ-ONLY / MOCKED-ONLY. Nothing in this file touches a live endpoint and nothing performs a real
// mutation — the write tests assert the request the connector WOULD send, captured at the transport
// boundary of a Mocked subclass.
//
// Every fixture descends from the VENDOR's own published examples in the bundled OpenAPI v3 spec
// (`connectors-registry/reply/sources/reply-openapi-v3.bundled.yaml`) — never synthesized from the
// connector's metadata, which would make this tier unfalsifiable. Provenance (spec pointer, verbatim vs
// derived, and the note that the S7 probe ran unauthenticated with 0 capturable live pages) is recorded
// per file in `fixtures/reply/PROVENANCE.json`.

const FIXTURES = join(__dirname, 'fixtures', 'reply');
function fixture<T = Record<string, unknown>>(name: string): T {
    return JSON.parse(readFileSync(join(FIXTURES, name), 'utf8')) as T;
}

const sequencesPage1 = fixture('sequences.list.page1.json');
const sequencesPage2Overlap = fixture('sequences.list.page2.overlap.json');
const contactsList = fixture('contacts.list.json');
const contactGet = fixture('contact.get.json');
const contactCreated = fixture('contact.create.201.json');
const contactStatuses = fixture('contact.statuses.json');
const problem400 = fixture('error.400.problem.json');
const problem403 = fixture('error.403.problem.json');
const problem404 = fixture('error.404.problem.json');
const problem429 = fixture('error.429.problem.json');
const bulkNotProcessed = fixture('bulk.notprocessed.sequence-contact-links.json');
const bulkAllSucceeded = fixture('bulk.notprocessed.empty.json');

// ─── Test scaffolding ─────────────────────────────────────────────────────

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
        APIPath: '/v3/sequences',
        ResponseDataKey: null,
        DefaultPageSize: 100,
        SupportsPagination: true,
        PaginationType: 'Offset',
        SupportsIncrementalSync: false,
        IncrementalWatermarkField: null,
        StableOrderingKey: 'id',
        SupportsWrite: false,
        Configuration: null,
        Status: 'Active',
        CreateAPIPath: null, CreateMethod: null, CreateBodyShape: null, CreateBodyKey: null, CreateIDLocation: null,
        UpdateAPIPath: null, UpdateMethod: null, UpdateBodyShape: null, UpdateBodyKey: null, UpdateIDLocation: null,
        DeleteAPIPath: null, DeleteMethod: null, DeleteIDLocation: null,
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

const idPK = [makeIOF({ Name: 'id', Type: 'integer', IsPrimaryKey: true, IsRequired: true, IsReadOnly: true })];

const user = {} as never;

/**
 * The canonical Mocked<Connector> pattern: override ONLY the transport boundary and the engine-cache
 * accessors. The REAL auth composition, pagination params, envelope normalization, projection descent,
 * dedupe, error classification and CRUD dispatch all execute.
 */
class MockedReplyConnector extends ReplyConnector {
    public Captured: CapturedRequest[] = [];
    public Responses: RESTResponse[] = [];
    public IOFixtures = new Map<string, MJIntegrationObjectEntity>();
    public IOFFixtures = new Map<string, MJIntegrationObjectFieldEntity[]>();

    protected override async MakeHTTPRequest(
        _auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown
    ): Promise<RESTResponse> {
        this.Captured.push({ url, method, headers, body });
        const next = this.Responses.shift();
        if (!next) throw new Error(`MockedReplyConnector: no canned response queued for ${method} ${url}`);
        // Mirror the real transport's problem-recording so the 403 warning path is exercised end to end.
        (this as unknown as { recordProblem(r: RESTResponse, u: string): void }).recordProblem(next, url);
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
    protected override tryGetCachedObject(objectName: string): MJIntegrationObjectEntity | null {
        return this.IOFixtures.get(objectName) ?? null;
    }

    public Register(io: MJIntegrationObjectEntity, fields: MJIntegrationObjectFieldEntity[]): void {
        this.IOFixtures.set(io.Name, io);
        this.IOFFixtures.set(io.ID, fields);
    }

    // ── Protected seams exposed for direct unit assertions ──
    public PublicNormalize(body: unknown, key: string | null): Record<string, unknown>[] {
        return this.NormalizeResponse(body, key);
    }
    public PublicExtractPagination(body: unknown, type: PaginationType, offset = 0, pageSize = 100) {
        return this.ExtractPaginationInfo(body, type, 1, offset, pageSize);
    }
    public PublicBuildPaginatedURL(basePath: string, obj: MJIntegrationObjectEntity, offset: number, effective?: number): string {
        return (this as unknown as {
            BuildPaginatedURL(b: string, o: MJIntegrationObjectEntity, p: number, off: number, c?: string, e?: number): string;
        }).BuildPaginatedURL(basePath, obj, 1, offset, undefined, effective);
    }
    public PublicSubstituteIDInPath(path: string, id: string, loc: string | null): string {
        return (this as unknown as { SubstituteIDInPath(p: string, i: string, l: string | null): string })
            .SubstituteIDInPath(path, id, loc);
    }
    public PublicExtractErrorMessage(r: RESTResponse): string | undefined {
        return (this as unknown as { ExtractErrorMessage(r: RESTResponse): string | undefined }).ExtractErrorMessage(r);
    }
    public async PublicHeaders(ci: MJCompanyIntegrationEntity): Promise<Record<string, string>> {
        return this.BuildHeaders(await this.Authenticate(ci, user));
    }
    public async PublicBaseURL(ci: MJCompanyIntegrationEntity): Promise<string> {
        return this.GetBaseURL(ci, await this.Authenticate(ci, user));
    }

    // ── Deterministic clock + sleep, so rate-limit pacing is asserted without real elapsed time ──
    public FakeNowMs = 1_000_000;
    public Slept: number[] = [];
    protected override NowMs(): number { return this.FakeNowMs; }
    protected override Sleep(ms: number): Promise<void> {
        this.Slept.push(ms);
        this.FakeNowMs += ms;   // a real sleep advances the clock; the fake one must too
        return Promise.resolve();
    }
    public PublicPace(url: string): Promise<void> { return this.PaceStrictFamily(url); }

    /** Fires ONE request through the real transport seam (so wire-boundary capture runs) and returns it. */
    public PublicRawRequest(url: string, method = 'GET'): Promise<RESTResponse> {
        return this.MakeHTTPRequest({} as RESTAuthContext, url, method, {});
    }
}

/** CompanyIntegration whose Configuration carries the API key (no credential row needed offline). */
function makeCI(cfg: Record<string, unknown> = { ApiKey: 'reply-test-key' }): MJCompanyIntegrationEntity {
    return { IntegrationID: 'int-1', Configuration: JSON.stringify(cfg), CredentialID: null } as unknown as MJCompanyIntegrationEntity;
}

function fetchCtx(objectName: string, over?: Partial<FetchContext>): FetchContext {
    return {
        CompanyIntegration: makeCI(),
        ObjectName: objectName,
        WatermarkValue: null,
        BatchSize: 100,
        ContextUser: user,
        ...over,
    } as FetchContext;
}

const ok = (body: unknown, status = 200, headers: Record<string, string> = {}): RESTResponse =>
    ({ Status: status, Body: body, Headers: headers });

let c: MockedReplyConnector;
beforeEach(() => { c = new MockedReplyConnector(); });

// ═══════════════════════════════════════════════════════════════════════════

describe('ReplyConnector — identity + declared capabilities', () => {
    it('IntegrationName is the verbatim MJ: Integrations.Name', () => {
        expect(new ReplyConnector().IntegrationName).toBe('Reply');
    });

    it('declares Create/Update/Delete (34 write-capable IOs) and NON-authoritative discovery', () => {
        const r = new ReplyConnector();
        expect(r.SupportsCreate).toBe(true);
        expect(r.SupportsUpdate).toBe(true);
        expect(r.SupportsDelete).toBe(true);
        // No describe-all endpoint in the 270-path spec → a refresh can never prove absence.
        expect(r.DiscoveryIsAuthoritative).toBe(false);
    });

    it('does NOT claim batch write — the frozen contract points no CRUD column at a bulk endpoint', () => {
        expect(new ReplyConnector().SupportsBatchWrite).toBe(false);
    });

    it('publishes a rate-limit policy under the 100/min ceiling and a LOW concurrency hint', () => {
        const r = new ReplyConnector();
        const policy = r.RateLimitPolicy;
        expect(policy).not.toBeNull();
        // 100/min = 1.67/s; we stay under it, and well under the 3,000/hr (0.83/s) sustained ceiling.
        expect(policy!.TokensPerSec).toBeLessThan(100 / 60);
        expect(r.MaxConcurrencyHint).toBe(2);
    });
});

describe('ReplyConnector — stricter pacing for the reporting / statistics families', () => {
    it('does NOT delay an ordinary collection read, however many times it is called', async () => {
        await c.PublicPace('https://api.reply.io/v3/contacts?top=100&skip=0');
        await c.PublicPace('https://api.reply.io/v3/contacts?top=100&skip=100');
        await c.PublicPace('https://api.reply.io/v3/sequences?top=100&skip=0');
        expect(c.Slept).toEqual([]);
    });

    it('spaces consecutive stats/reporting calls to at least the strict-family gap', async () => {
        await c.PublicPace('https://api.reply.io/v3/email-accounts/7/stats');   // first: no wait
        expect(c.Slept).toEqual([]);
        await c.PublicPace('https://api.reply.io/v3/email-accounts/8/stats');   // immediately after: waits
        expect(c.Slept.length).toBe(1);
        expect(c.Slept[0]).toBeGreaterThan(0);
        expect(c.Slept[0]).toBeLessThanOrEqual(1000);
    });

    it('covers reporting, per-contact statuses and sequence contact-state as strict families', async () => {
        for (const url of [
            'https://api.reply.io/v3/reporting/sequences?top=50',
            'https://api.reply.io/v3/contacts/12345/statuses',
            'https://api.reply.io/v3/sequences/99/contacts/state?top=100&skip=0',
        ]) {
            const conn = new MockedReplyConnector();
            await conn.PublicPace(url);
            await conn.PublicPace(url);
            expect(conn.Slept.length, `expected strict pacing for ${url}`).toBe(1);
        }
    });

    it('does not wait when enough time already elapsed between two strict calls', async () => {
        await c.PublicPace('https://api.reply.io/v3/email-accounts/7/stats');
        c.FakeNowMs += 5_000;
        await c.PublicPace('https://api.reply.io/v3/email-accounts/8/stats');
        expect(c.Slept).toEqual([]);
    });

    it('pacing is pre-emptive spacing only — it never retries and never swallows a response', async () => {
        // A strict-family GET still yields exactly one captured request and the canned body.
        const io = makeIO({ ID: 'io-st', Name: 'EmailAccountStat', APIPath: '/v3/email-accounts/7/stats', PaginationType: 'None', SupportsPagination: false });
        c.Register(io, idPK);
        c.Responses = [ok({ id: 7, sent: 10 })];
        const res = await c.FetchChanges(fetchCtx('EmailAccountStat'));
        expect(c.Captured.length).toBe(1);
        expect(res.Records.length).toBe(1);
    });
});

describe('ReplyConnector — auth (Bearer) + base URL', () => {
    it('sends Authorization: Bearer <key> and accepts problem+json', async () => {
        const headers = await c.PublicHeaders(makeCI());
        expect(headers['Authorization']).toBe('Bearer reply-test-key');
        expect(headers['Accept']).toContain('application/problem+json');
    });

    // The header is composed by the SHARED auth-helper (buildAPIKeyHeaderValue), not a local literal, so its
    // centralized guards apply here. These two assert the guards are genuinely in force rather than bypassed.
    it('rejects a CR/LF-bearing key via the shared helper (header-injection guard)', async () => {
        const conn = new MockedReplyConnector();
        await expect(conn.PublicHeaders(makeCI({ ApiKey: 'abc\r\nX-Injected: 1' })))
            .rejects.toThrow(/CR\/LF/i);
    });

    it('rejects a whitespace-only key rather than sending "Bearer "', async () => {
        const conn = new MockedReplyConnector();
        await expect(conn.PublicHeaders(makeCI({ ApiKey: '   ' }))).rejects.toThrow();
    });

    it('defaults to the vendor host https://api.reply.io', async () => {
        expect(await c.PublicBaseURL(makeCI())).toBe('https://api.reply.io');
    });

    it('honors a Configuration base-URL override by DATA (spec-mock / sandbox), no code branch', async () => {
        const conn = new MockedReplyConnector();
        expect(await conn.PublicBaseURL(makeCI({ ApiKey: 'k', BaseURL: 'http://127.0.0.1:4010/' })))
            .toBe('http://127.0.0.1:4010');
    });

    it('ignores a non-absolute override so a stray value cannot misroute a tenant', async () => {
        const conn = new MockedReplyConnector();
        expect(await conn.PublicBaseURL(makeCI({ ApiKey: 'k', BaseURL: 'not-a-url' }))).toBe('https://api.reply.io');
    });

    it('fails loudly when no API key is present anywhere', async () => {
        const conn = new MockedReplyConnector();
        await expect(conn.PublicHeaders(makeCI({}))).rejects.toThrow(/credential/i);
    });
});

describe('ReplyConnector — offset pagination (top/skip)', () => {
    const seqIO = makeIO({ ID: 'io-seq', Name: 'Sequence', APIPath: '/v3/sequences', DefaultPageSize: 100 });

    it('emits the VENDOR params top/skip — never the base defaults limit/offset', () => {
        const url = c.PublicBuildPaginatedURL('https://api.reply.io/v3/sequences', seqIO, 200);
        expect(url).toBe('https://api.reply.io/v3/sequences?top=100&skip=200');
        expect(url).not.toContain('limit=');
        expect(url).not.toContain('offset=');
    });

    it('clamps top to the endpoint DECLARED ceiling (an over-large top is a 400, not a truncation)', () => {
        const capped = makeIO({ ID: 'io-cap', Name: 'Capped', APIPath: '/v3/x', DefaultPageSize: 25 });
        expect(c.PublicBuildPaginatedURL('https://api.reply.io/v3/x', capped, 0, 1000)).toContain('top=25');
    });

    it('clamps top to the vendor-wide maximum of 1000 even if an IO declares more', () => {
        const huge = makeIO({ ID: 'io-huge', Name: 'Huge', APIPath: '/v3/x', DefaultPageSize: 100000 });
        expect(c.PublicBuildPaginatedURL('https://api.reply.io/v3/x', huge, 0, 100000)).toContain('top=1000');
    });

    it('honors the remaining batch capacity so a page cannot overshoot the batch', () => {
        expect(c.PublicBuildPaginatedURL('https://api.reply.io/v3/sequences', seqIO, 0, 7)).toContain('top=7');
    });

    it('appends with & when the declared path already carries a query string', () => {
        const q = makeIO({ ID: 'io-q', Name: 'Q', APIPath: '/v3/x?state=open', DefaultPageSize: 50 });
        expect(c.PublicBuildPaginatedURL('https://api.reply.io/v3/x?state=open', q, 0))
            .toBe('https://api.reply.io/v3/x?state=open&top=50&skip=0');
    });

    it('adds no params when the object declares no pagination', () => {
        const none = makeIO({ ID: 'io-n', Name: 'N', APIPath: '/v3/whoami', PaginationType: 'None', SupportsPagination: false });
        expect(c.PublicBuildPaginatedURL('https://api.reply.io/v3/whoami', none, 0)).toBe('https://api.reply.io/v3/whoami');
    });

    it('reads continuation from the envelope hasMore flag and advances skip by the page length', () => {
        expect(c.PublicExtractPagination(sequencesPage1, 'Offset', 0, 100))
            .toEqual({ HasMore: true, NextOffset: 2 });
        expect(c.PublicExtractPagination(sequencesPage2Overlap, 'Offset', 2, 100))
            .toEqual({ HasMore: false, NextOffset: 4 });
    });

    it('falls back to a full-page heuristic only when the envelope omits hasMore', () => {
        expect(c.PublicExtractPagination({ items: [{ id: 1 }, { id: 2 }] }, 'Offset', 0, 2).HasMore).toBe(true);
        expect(c.PublicExtractPagination({ items: [{ id: 1 }] }, 'Offset', 0, 2).HasMore).toBe(false);
    });
});

describe('ReplyConnector — response normalization', () => {
    it('unwraps the vendor-wide `items` envelope', () => {
        expect(c.PublicNormalize(sequencesPage1, null)).toHaveLength(2);
    });

    it('prefers an explicitly declared ResponseDataKey over the envelope default', () => {
        expect(c.PublicNormalize({ rows: [{ id: 1 }], items: [{ id: 9 }, { id: 8 }] }, 'rows'))
            .toEqual([{ id: 1 }]);
    });

    it('passes a bare array through', () => {
        expect(c.PublicNormalize([{ id: 1 }], null)).toEqual([{ id: 1 }]);
    });

    it('wraps a single non-enveloped object (get-one, /v3/whoami, singleton doors) as one record', () => {
        expect(c.PublicNormalize(contactGet, null)).toEqual([contactGet]);
    });

    it('returns [] for an absent body — a 401 carries NO body at all', () => {
        expect(c.PublicNormalize(null, null)).toEqual([]);
        expect(c.PublicNormalize(undefined, null)).toEqual([]);
    });

    it('never guesses an arbitrary array property when neither key nor `items` is present', () => {
        const body = { widgets: [{ id: 1 }, { id: 2 }] };
        expect(c.PublicNormalize(body, null)).toEqual([body]);   // one record, not two guessed ones
    });
});

describe('ReplyConnector — read path: paging, cross-page dedupe, full-record pass-through', () => {
    beforeEach(() => {
        c.Register(makeIO({ ID: 'io-seq', Name: 'Sequence', APIPath: '/v3/sequences' }), idPK);
    });

    it('walks pages with top/skip and de-duplicates a record that straddles a shifted page window', async () => {
        c.Responses = [ok(sequencesPage1), ok(sequencesPage2Overlap)];
        const result = await c.FetchChanges(fetchCtx('Sequence'));

        // 2 + 2 fetched, but id 12346 appears on BOTH pages (offset paging over a mutating collection
        // shifts the window) — a page boundary is NOT a record boundary.
        expect(result.Records).toHaveLength(3);
        expect(result.Records.map(r => r.ExternalID)).toEqual(['12345', '12346', '12347']);

        expect(c.Captured[0].url).toContain('skip=0');
        expect(c.Captured[1].url).toContain('skip=2');
    });

    it('returns a NextOffset checkpoint so a multi-hour first sync resumes rather than restarting', async () => {
        c.Responses = [ok(sequencesPage1)];
        const result = await c.FetchChanges(fetchCtx('Sequence', { BatchSize: 2 }));
        expect(result.HasMore).toBe(true);
        expect(result.NextOffset).toBe(2);
    });

    it('resumes from a supplied offset instead of re-reading page 1', async () => {
        c.Responses = [ok(sequencesPage2Overlap)];
        await c.FetchChanges(fetchCtx('Sequence', { CurrentOffset: 2 }));
        expect(c.Captured[0].url).toContain('skip=2');
    });

    it('emits NO watermark — Reply publishes no incremental filter on any of the 84 objects', async () => {
        c.Responses = [ok(sequencesPage2Overlap)];
        const result = await c.FetchChanges(fetchCtx('Sequence'));
        expect(result.NewWatermarkValue).toBeUndefined();
        expect(c.Captured[0].url).not.toMatch(/since|updatedAfter|modified/i);
    });

    it('carries the FULL source record into ExternalRecord.Fields (custom-column capture contract)', async () => {
        c.Register(makeIO({ ID: 'io-contact', Name: 'Contact', APIPath: '/v3/contacts' }), idPK);
        c.Responses = [ok(contactsList)];
        const result = await c.FetchChanges(fetchCtx('Contact'));
        const fields = result.Records[0].Fields;
        // Every key the vendor sent survives — including ones no declared IOF covers.
        const source = (contactsList.items as Record<string, unknown>[])[0];
        expect(Object.keys(fields).sort()).toEqual(Object.keys(source).sort());
        expect(fields.linkedInSalesNavigatorUrl).toBe(source.linkedInSalesNavigatorUrl);
    });
});

describe('ReplyConnector — embedded-array projection (18 IOs have no endpoint of their own)', () => {
    it('descends the declared nested key and emits the leaf rows', async () => {
        // Configuration.resourceKey = "<Owner>.<key>[]" is the extractor's DECLARED marker for a projection.
        c.Register(
            makeIO({
                ID: 'io-css', Name: 'ContactStatusSequence',
                APIPath: '/v3/contacts/statuses',
                PaginationType: 'None', SupportsPagination: false,
                Configuration: JSON.stringify({ resourceKey: 'ContactStatus.sequences[]' }),
            }),
            [makeIOF({ Name: 'sequenceId', Type: 'integer', IsPrimaryKey: true }), makeIOF({ Name: 'contactId', Type: 'integer' })],
        );
        c.Responses = [ok(contactStatuses)];
        const result = await c.FetchChanges(fetchCtx('ContactStatusSequence'));

        expect(result.Records).toHaveLength(2);
        expect(result.Records.map(r => r.ExternalID)).toEqual(['100', '101']);
        expect(result.Records[0].ObjectType).toBe('ContactStatusSequence');
        // The nested row keeps its own full shape…
        expect(result.Records[0].Fields.statusInSequence).toBe('active');
        // …and inherits the owner key it DECLARES as its own field (the link back to the parent).
        expect(result.Records[0].Fields.contactId).toBe(12345);
    });

    it('does NOT copy owner keys the leaf object never declared', async () => {
        c.Register(
            makeIO({
                ID: 'io-css2', Name: 'ContactStatusSequence',
                APIPath: '/v3/contacts/statuses',
                PaginationType: 'None', SupportsPagination: false,
                Configuration: JSON.stringify({ resourceKey: 'ContactStatus.sequences[]' }),
            }),
            [makeIOF({ Name: 'sequenceId', Type: 'integer', IsPrimaryKey: true })],
        );
        c.Responses = [ok(contactStatuses)];
        const result = await c.FetchChanges(fetchCtx('ContactStatusSequence'));
        expect(result.Records[0].Fields.callStatus).toBeUndefined();
        expect(result.Records[0].Fields.contactId).toBeUndefined();
    });

    it('descends a projection nested in a PAGINATED owner payload (Contact.customFields[])', async () => {
        c.Register(
            makeIO({
                ID: 'io-ccf', Name: 'ContactCustomField', APIPath: '/v3/contacts',
                Configuration: JSON.stringify({ resourceKey: 'Contact.customFields[]' }),
            }),
            [makeIOF({ Name: 'key', IsPrimaryKey: true }), makeIOF({ Name: 'value' })],
        );
        c.Responses = [ok(contactsList)];
        const result = await c.FetchChanges(fetchCtx('ContactCustomField'));
        expect(result.Records.map(r => r.ExternalID)).toEqual(['leadSource', 'budget']);
        expect(c.Captured[0].url).toContain('/v3/contacts?top=');   // the OWNER endpoint, paged as declared
    });

    it('treats a slash-form resourceKey as a real leaf endpoint, not a projection', async () => {
        c.Register(
            makeIO({
                ID: 'io-cs', Name: 'ContactStatus', APIPath: '/v3/contacts/statuses',
                PaginationType: 'None', SupportsPagination: false,
                Configuration: JSON.stringify({ resourceKey: 'contacts/statuses' }),
            }),
            [makeIOF({ Name: 'contactId', Type: 'integer', IsPrimaryKey: true })],
        );
        c.Responses = [ok(contactStatuses)];
        const result = await c.FetchChanges(fetchCtx('ContactStatus'));
        expect(result.Records).toHaveLength(1);
        expect(result.Records[0].ExternalID).toBe('12345');
        expect(result.Records[0].Fields.sequences).toBeDefined();   // nested array preserved, not descended
    });
});

describe('ReplyConnector — 403 is REACHABLE-BUT-NOT-ENTITLED, never a silent drop', () => {
    beforeEach(() => {
        c.Register(makeIO({ ID: 'io-lead', Name: 'LiveDataSearch', APIPath: '/v3/live-data/searches' }), idPK);
    });

    it('surfaces a structured NOT_ENTITLED warning instead of reporting an empty pass', async () => {
        c.Responses = [ok(problem403, 403)];
        const result = await c.FetchChanges(fetchCtx('LiveDataSearch'));

        expect(result.Records).toHaveLength(0);
        const warning = result.Warnings?.find(w => w.Code === 'NOT_ENTITLED');
        expect(warning).toBeDefined();
        expect(warning!.Message).toMatch(/NOT ENTITLED/);
        expect(warning!.Message).toMatch(/neither an invalid credential nor a connector defect/i);
        expect(warning!.Data).toMatchObject({ status: 403, code: 'contact.forbidden' });
    });

    it('does NOT warn when the object is legitimately empty (no 403 was seen)', async () => {
        c.Responses = [ok({ items: [], hasMore: false })];
        const result = await c.FetchChanges(fetchCtx('LiveDataSearch'));
        expect(result.Warnings?.some(w => w.Code === 'NOT_ENTITLED')).toBeFalsy();
    });

    it('does not leak a prior run 403 into a later successful fetch', async () => {
        c.Responses = [ok(problem403, 403), ok(sequencesPage2Overlap)];
        await c.FetchChanges(fetchCtx('LiveDataSearch'));
        const second = await c.FetchChanges(fetchCtx('LiveDataSearch'));
        expect(second.Records.length).toBeGreaterThan(0);
        expect(second.Warnings?.some(w => w.Code === 'NOT_ENTITLED')).toBeFalsy();
    });
});

describe('ReplyConnector — RFC 9457 problem handling (classify on the CODE, tolerate an empty body)', () => {
    it('classifies off the stable machine slug, not the human detail', () => {
        expect(c.ClassifyProblem(400, c.parseProblem(problem400))).toBe('VALIDATION_ERROR');
        expect(c.ClassifyProblem(403, c.parseProblem(problem403))).toBe('CONFIGURATION_ERROR');
        expect(c.ClassifyProblem(429, c.parseProblem(problem429))).toBe('RATE_LIMIT_EXCEEDED');
    });

    it('403 is an entitlement problem — NEVER an authentication/credential failure', () => {
        const msg = c.PublicExtractErrorMessage(ok(problem403, 403))!;
        expect(msg).toContain('code=contact.forbidden');
        expect(msg).toMatch(/REACHABLE BUT NOT ENTITLED/);
        expect(msg).not.toMatch(/invalid (api )?key/i);
    });

    it('does not crash on the documented EMPTY 401 body and still reports the status', () => {
        const msg = c.PublicExtractErrorMessage({ Status: 401, Body: null, Headers: {} })!;
        expect(msg).toContain('HTTP 401');
        expect(msg).toContain('code=(none');
    });

    it('classifies a 429 with NO code slug by status (middleware problems carry no code)', () => {
        expect(c.parseProblem(problem429)!.code).toBeUndefined();
        expect(c.ClassifyProblem(429, c.parseProblem(problem429))).toBe('RATE_LIMIT_EXCEEDED');
    });

    it('parses a 404 problem body carrying its resource-scoped slug', () => {
        const p = c.parseProblem(problem404)!;
        expect(p.code).toBe('contact.notFound');
        expect(p.status).toBe(404);
    });

    it('returns null for a body that is not a problem document', () => {
        expect(c.parseProblem(contactGet)).toBeNull();
        expect(c.parseProblem(null)).toBeNull();
        expect(c.parseProblem('')).toBeNull();
    });

    it('honors Retry-After exactly (vendor documents integer SECONDS, minimum 1)', () => {
        expect(c.ExtractRetryAfterMs({ response: { headers: { 'retry-after': '60' } } })).toBe(60000);
        expect(c.ExtractRetryAfterMs({ headers: { 'retry-after': '1' } })).toBe(1000);
        expect(c.ExtractRetryAfterMs({ headers: {} })).toBeUndefined();
        expect(c.ExtractRetryAfterMs(new Error('boom'))).toBeUndefined();
    });

    // REGRESSION: the inherited read path validates a non-2xx by throwing a PLAIN Error carrying only a
    // status + body preview — the response headers are already gone by the time the engine asks for the
    // backoff. Reading Retry-After only off the error therefore discarded the vendor's own instruction on
    // every throttled READ (the exact path a 100/min + 3,000/hr shared budget makes routine), leaving the
    // engine to guess a backoff curve. The value is now captured at the wire boundary instead.
    it('recovers Retry-After from the wire when the surfaced error carries no headers', async () => {
        c.Responses.push(ok(null, 429, { 'retry-after': '30' }));
        await c.PublicRawRequest('https://api.reply.io/v3/contacts?top=100&skip=0');
        // A header-less error is exactly what the base's ValidateHTTPResponse throws.
        expect(c.ExtractRetryAfterMs(new Error('HTTP 429 from https://api.reply.io/v3/contacts'))).toBe(30000);
    });

    it('consumes a captured Retry-After ONCE — a stale value never replays against a later error', async () => {
        c.Responses.push(ok(null, 429, { 'retry-after': '30' }));
        await c.PublicRawRequest('https://api.reply.io/v3/contacts');
        expect(c.ExtractRetryAfterMs(new Error('HTTP 429'))).toBe(30000);
        expect(c.ExtractRetryAfterMs(new Error('HTTP 500 later, unrelated'))).toBeUndefined();
    });

    it('prefers headers carried ON the error over the captured value', async () => {
        c.Responses.push(ok(null, 429, { 'retry-after': '30' }));
        await c.PublicRawRequest('https://api.reply.io/v3/contacts');
        expect(c.ExtractRetryAfterMs({ headers: { 'retry-after': '5' } })).toBe(5000);
        // The captured value was cleared by that read, not left to leak into the next error.
        expect(c.ExtractRetryAfterMs(new Error('HTTP 429'))).toBeUndefined();
    });

    it('does not capture a Retry-After from a non-429 failure', async () => {
        c.Responses.push(ok(null, 500, { 'retry-after': '30' }));
        await c.PublicRawRequest('https://api.reply.io/v3/contacts');
        expect(c.ExtractRetryAfterMs(new Error('HTTP 500'))).toBeUndefined();
    });
});

describe('ReplyConnector — non-atomic bulk partial success (the silent-fail trap)', () => {
    it('reads the per-item failure dictionary — HTTP 200 alone is NOT an outcome', () => {
        const parsed = c.parseNotProcessed(bulkNotProcessed)!;
        expect(parsed.size).toBe(2);
        expect(parsed.get('12345')!.error).toBe('contactAlreadyInSequence');
        expect(parsed.get('12346')!.error).toBe('contactNotFound');
    });

    it('treats the documented empty dictionary {} as all-succeeded', () => {
        expect(c.parseNotProcessed(bulkAllSucceeded)!.size).toBe(0);
    });

    it('does not misread an ordinary created record as a bulk failure dictionary', () => {
        expect(c.parseNotProcessed(contactCreated)).toBeNull();
        expect(c.parseNotProcessed([{ id: 1 }])).toBeNull();
    });
});

describe('ReplyConnector — write path (MOCKED request construction only; nothing is ever sent)', () => {
    const contactWriteIO = makeIO({
        ID: 'io-contact-w', Name: 'Contact', APIPath: '/v3/contacts', SupportsWrite: true,
        CreateAPIPath: '/v3/contacts', CreateMethod: 'POST', CreateBodyShape: 'flat', CreateIDLocation: 'body',
        UpdateAPIPath: '/v3/contacts/{id}', UpdateMethod: 'PATCH', UpdateBodyShape: 'flat', UpdateIDLocation: 'path',
        DeleteAPIPath: '/v3/contacts/{id}', DeleteMethod: 'DELETE', DeleteIDLocation: 'path',
    });

    const createCtx = (attrs: Record<string, unknown>): CreateRecordContext => ({
        CompanyIntegration: makeCI(), ObjectName: 'Contact', Attributes: attrs, ContextUser: user,
    } as unknown as CreateRecordContext);
    const updateCtx = (id: string, attrs: Record<string, unknown>): UpdateRecordContext => ({
        CompanyIntegration: makeCI(), ObjectName: 'Contact', ExternalID: id, Attributes: attrs, ContextUser: user,
    } as unknown as UpdateRecordContext);
    const deleteCtx = (id: string): DeleteRecordContext => ({
        CompanyIntegration: makeCI(), ObjectName: 'Contact', ExternalID: id, ContextUser: user,
    } as unknown as DeleteRecordContext);

    beforeEach(() => { c.Register(contactWriteIO, idPK); });

    it('CREATE builds the declared POST from the metadata columns and extracts the new id', async () => {
        c.Responses = [ok(contactCreated, 201)];
        const result = await c.CreateRecord(createCtx({ email: 'a@b.com', firstName: 'A' }));

        expect(result.Success).toBe(true);
        expect(result.ExternalID).toBe('12345');
        expect(c.Captured[0].method).toBe('POST');
        expect(c.Captured[0].url).toBe('https://api.reply.io/v3/contacts');
        expect(c.Captured[0].body).toEqual({ email: 'a@b.com', firstName: 'A' });
        expect(c.Captured[0].headers['Authorization']).toBe('Bearer reply-test-key');
    });

    it('UPDATE uses the declared PATCH verb and substitutes {id} into the path', async () => {
        c.Responses = [ok(null, 204)];
        const result = await c.UpdateRecord(updateCtx('12345', { title: 'VP' }));

        expect(result.Success).toBe(true);
        expect(c.Captured[0].method).toBe('PATCH');
        expect(c.Captured[0].url).toBe('https://api.reply.io/v3/contacts/12345');
        expect(c.Captured[0].body).toEqual({ title: 'VP' });
    });

    it('DELETE issues the declared hard delete with no body', async () => {
        c.Responses = [ok(null, 204)];
        const result = await c.DeleteRecord(deleteCtx('12345'));
        expect(result.Success).toBe(true);
        expect(c.Captured[0].method).toBe('DELETE');
        expect(c.Captured[0].url).toBe('https://api.reply.io/v3/contacts/12345');
        expect(c.Captured[0].body).toBeUndefined();
    });

    it('a 200 carrying a NotProcessed dictionary is reported as FAILURE, not success', async () => {
        c.Responses = [ok(bulkNotProcessed, 200)];
        const result = await c.CreateRecord(createCtx({ email: 'a@b.com' }));

        expect(result.Success).toBe(false);
        expect(result.ErrorMessage).toMatch(/NOT PROCESSED/);
        expect(result.ErrorMessage).toMatch(/contactAlreadyInSequence/);
        expect(result.ErrorMessage).toMatch(/verify with a read first/i);
    });

    it('a non-2xx write surfaces the stable slug and classification', async () => {
        c.Responses = [ok(problem400, 400)];
        const result = await c.UpdateRecord(updateCtx('12345', { email: 'nope' }));
        expect(result.Success).toBe(false);
        expect(result.StatusCode).toBe(400);
        expect(result.ErrorMessage).toContain('code=contact.invalidPagination');
    });

    it('NEVER auto-retries a write — exactly ONE request leaves the connector per call', async () => {
        c.Responses = [ok(problem429, 429), ok(contactCreated, 201)];
        const result = await c.CreateRecord(createCtx({ email: 'a@b.com' }));
        expect(result.Success).toBe(false);
        expect(c.Captured).toHaveLength(1);   // a blind retry of a send/enrollment can double-act
    });

    it('substitutes NAMED and NESTED path vars the base would leave untouched', () => {
        expect(c.PublicSubstituteIDInPath('/v3/sequences/{id}/steps/{step_id}', '900|17', 'path'))
            .toBe('/v3/sequences/900/steps/17');
        expect(c.PublicSubstituteIDInPath('/v3/ai-sdr/knowledge-bases/{knowledge_base_id}/documents/{document_id}', '5|9', 'path'))
            .toBe('/v3/ai-sdr/knowledge-bases/5/documents/9');
        expect(c.PublicSubstituteIDInPath('/v3/contacts/{id}', '12345', 'path')).toBe('/v3/contacts/12345');
        expect(c.PublicSubstituteIDInPath('/v3/contacts/{id}', 'a b', 'path')).toBe('/v3/contacts/a%20b');
    });

    it('leaves the path alone when the ID does not live in it', () => {
        expect(c.PublicSubstituteIDInPath('/v3/contacts', '12345', 'body')).toBe('/v3/contacts');
    });

    it('fills a CREATE path parent var from the record attributes (nested create)', async () => {
        c.Register(makeIO({
            ID: 'io-var', Name: 'SequenceStepVariant', APIPath: '/v3/sequences/{id}/steps/{step_id}/variants',
            CreateAPIPath: '/v3/sequences/{sequenceId}/steps/{stepId}/variants', CreateMethod: 'POST',
            CreateBodyShape: 'flat', CreateIDLocation: 'body',
        }), idPK);
        c.Responses = [ok({ id: 777 }, 201)];
        const result = await c.CreateRecord({
            CompanyIntegration: makeCI(), ObjectName: 'SequenceStepVariant', ContextUser: user,
            Attributes: { sequenceId: 900, stepId: 17, subject: 'Hi' },
        } as unknown as CreateRecordContext);

        expect(result.Success).toBe(true);
        expect(c.Captured[0].url).toBe('https://api.reply.io/v3/sequences/900/steps/17/variants');
    });
});

describe('ReplyConnector — TestConnection (GET /v3/whoami, scope-free)', () => {
    it('succeeds on 200 and names the authenticated user', async () => {
        c.Responses = [ok({ username: 'ops@acme.com', teamId: 7 })];
        const r = await c.TestConnection(makeCI(), user);
        expect(r.Success).toBe(true);
        expect(c.Captured[0].url).toBe('https://api.reply.io/v3/whoami');
        expect(c.Captured[0].method).toBe('GET');
    });

    it('reports 401 (EMPTY body) as a credential failure', async () => {
        c.Responses = [{ Status: 401, Body: null, Headers: { 'www-authenticate': 'Bearer' } }];
        const r = await c.TestConnection(makeCI(), user);
        expect(r.Success).toBe(false);
        expect(r.Message).toMatch(/invalid or revoked|authentication failed/i);
    });

    it('reports 403 as an ENTITLEMENT problem and explicitly not a bad credential', async () => {
        c.Responses = [ok(problem403, 403)];
        const r = await c.TestConnection(makeCI(), user);
        expect(r.Success).toBe(false);
        expect(r.Message).toMatch(/entitle/i);
        expect(r.Message).toMatch(/not a bad credential/i);
    });
});

describe('ReplyConnector — read mapping (GetRecord) and stable ordering', () => {
    beforeEach(() => {
        c.Register(makeIO({
            ID: 'io-contact-g', Name: 'Contact', APIPath: '/v3/contacts',
            UpdateAPIPath: '/v3/contacts/{id}', UpdateIDLocation: 'path',
        }), idPK);
    });

    it('maps a single record with the declared PK as ExternalID and the full body as Fields', async () => {
        c.Responses = [ok(contactGet)];
        const rec = await c.GetRecord({
            CompanyIntegration: makeCI(), ObjectName: 'Contact', ExternalID: '12345', ContextUser: user,
        } as never);
        expect(rec).not.toBeNull();
        expect(rec!.ExternalID).toBe('12345');
        expect(rec!.Fields.email).toBe(contactGet.email);
        expect(c.Captured[0].url).toBe('https://api.reply.io/v3/contacts/12345');
    });

    it('returns null on a 404 problem rather than throwing', async () => {
        c.Responses = [ok(problem404, 404)];
        const rec = await c.GetRecord({
            CompanyIntegration: makeCI(), ObjectName: 'Contact', ExternalID: '99999', ContextUser: user,
        } as never);
        expect(rec).toBeNull();
    });

    it('StableOrderingKey returns the declared key (every object is no-watermark, so resume needs one)', () => {
        expect(c.StableOrderingKey('Contact')).toBe('id');
    });

    it('StableOrderingKey is null for an unknown object rather than inventing one', () => {
        expect(c.StableOrderingKey('NoSuchObject')).toBeNull();
    });
});
