import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { readFileSync } from 'node:fs';
import { extractSectionRawItems, extractMs } from '../orcidRecordExtraction.js';
import type {
    RESTResponse,
    RESTAuthContext,
    FetchContext,
    PaginationType,
} from '@memberjunction/integration-engine';
import type { MJCompanyIntegrationEntity, MJIntegrationObjectEntity, MJIntegrationObjectFieldEntity } from '@memberjunction/core-entities';
import { ORCIDConnector } from '../ORCIDConnector.js';

// ─── Fixtures (scrubbed; ORCID Public API v3.0 shapes) ────────────────
// Derived from documented ORCID Public API example payloads. ORCID iDs in the
// 0000-* test ranges are public sample identifiers; no PII beyond synthetic names.

const SEARCH_FIXTURE = {
    'num-found': 2,
    result: [
        { 'orcid-identifier': { path: '0000-0002-1825-0097', uri: 'https://orcid.org/0000-0002-1825-0097' } },
        { 'orcid-identifier': { path: '0000-0001-2345-6789', uri: 'https://orcid.org/0000-0001-2345-6789' } },
    ],
};

const RECORD_FIXTURE = {
    'orcid-identifier': { path: '0000-0002-1825-0097', uri: 'https://orcid.org/0000-0002-1825-0097' },
    'last-modified-date': { value: 1700000000000 },
    history: {
        'submission-date': { value: 1500000000000 },
        claimed: true,
        'verified-email': true,
    },
    person: {
        name: {
            'given-names': { value: 'Test' },
            'family-name': { value: 'Researcher' },
            'credit-name': { value: 'T. Researcher' },
        },
        biography: { content: '<redacted>' },
        emails: { email: [] },
        keywords: { keyword: [] },
    },
};

// A works group envelope: group[].work-summary[] with put-code leaf items.
const WORKS_FIXTURE = {
    'last-modified-date': { value: 1700000000000 },
    group: [
        {
            'work-summary': [
                { 'put-code': 111, title: { title: { value: 'Paper A' } }, type: 'journal-article', 'last-modified-date': { value: 1600000000000 } },
            ],
        },
        {
            'work-summary': [
                { 'put-code': 222, title: { title: { value: 'Paper B' } }, type: 'book', 'last-modified-date': { value: 1800000000000 } },
            ],
        },
    ],
};

// ORCID's published sample record (Josiah Carberry, ORCID's fictional test researcher), as served by
// GET /0000-0002-1825-0097/record: real activities-summary + person envelopes for every section.
const FULL_RECORD = JSON.parse(
    readFileSync(new URL('./fixtures/record-0000-0002-1825-0097.json', import.meta.url), 'utf8')
) as Record<string, unknown>;

/** A valid-looking, distinct ORCID iD for synthetic universes (checksum digit unchecked by the connector). */
function syntheticId(n: number): string {
    return `0000-0009-${String(Math.floor(n / 10000)).padStart(4, '0')}-${String(n % 10000).padStart(4, '0')}`;
}

// ─── Mock metadata builders ───────────────────────────────────────────

function mockField(over: Partial<MJIntegrationObjectFieldEntity> & { Name: string }): MJIntegrationObjectFieldEntity {
    return {
        Name: over.Name,
        Type: over.Type ?? 'String',
        IsPrimaryKey: over.IsPrimaryKey ?? false,
        IsRequired: over.IsRequired ?? false,
        IsReadOnly: over.IsReadOnly ?? true,
        IsUniqueKey: over.IsUniqueKey ?? false,
        Status: 'Active',
        Sequence: over.Sequence ?? 0,
        DisplayName: over.Name,
        RelatedIntegrationObjectID: over.RelatedIntegrationObjectID ?? null,
    } as unknown as MJIntegrationObjectFieldEntity;
}

function mockObject(name: string): MJIntegrationObjectEntity {
    return {
        ID: `io-${name}`,
        Name: name,
        APIPath: `/{iD}/${name === 'record' ? 'record' : name}`,
        PaginationType: 'None',
        SupportsPagination: false,
        SupportsIncrementalSync: true,
        SupportsWrite: false,
        Status: 'Active',
    } as unknown as MJIntegrationObjectEntity;
}

const RECORD_FIELDS: MJIntegrationObjectFieldEntity[] = [
    mockField({ Name: 'orcid-id', IsPrimaryKey: true, IsRequired: true, IsUniqueKey: true, Sequence: 0 }),
    mockField({ Name: 'given-names', Sequence: 1 }),
    mockField({ Name: 'family-name', Sequence: 2 }),
    mockField({ Name: 'last-modified-date', Type: 'DateTime', Sequence: 3 }),
];

const WORKS_FIELDS: MJIntegrationObjectFieldEntity[] = [
    mockField({ Name: 'orcid-id', IsRequired: true, Sequence: 0, RelatedIntegrationObjectID: 'io-record' }),
    mockField({ Name: 'put-code', Type: 'Integer', IsPrimaryKey: true, IsRequired: true, IsUniqueKey: true, Sequence: 1 }),
    mockField({ Name: 'type', Sequence: 2 }),
    mockField({ Name: 'last-modified-date', Type: 'DateTime', Sequence: 3 }),
];

const OBJECTS: Record<string, { obj: MJIntegrationObjectEntity; fields: MJIntegrationObjectFieldEntity[] }> = {
    record: { obj: mockObject('record'), fields: RECORD_FIELDS },
    works: { obj: mockObject('works'), fields: WORKS_FIELDS },
};

/**
 * Test connector: overrides auth + HTTP transport + cached-metadata accessors so
 * FetchChanges runs end-to-end with NO credentials and NO real network. Captures
 * outbound calls and serves canned fixtures keyed by URL substring.
 */
class TestORCIDConnector extends ORCIDConnector {
    public Calls: Array<{ url: string; method: string; headers: Record<string, string> }> = [];
    public Responder: (url: string) => RESTResponse = () => ({ Status: 200, Body: {}, Headers: {} });
    /** PascalCase ORCIDConnectionConfig overrides — the shape parseConfig would produce. */
    public Config: Record<string, unknown> = { SearchQuery: 'affiliation-org-name:"Test University"' };
    /** The canned "already synced" record store a derived section reads from (iD → /record JSON). */
    public Stored: Map<string, Record<string, unknown>> = new Map();
    /** Simulated per-request latency (ms), so concurrency is observable. 0 = resolve immediately. */
    public Latency = 0;
    public InFlight = 0;
    public MaxInFlight = 0;

    protected override async LoadStoredRecords(_ctx: FetchContext, orcidIds: string[]): Promise<Map<string, Record<string, unknown>>> {
        const out = new Map<string, Record<string, unknown>>();
        for (const iD of orcidIds) {
            const rec = this.Stored.get(iD);
            if (rec) out.set(iD, rec);
        }
        return out;
    }

    protected override async Authenticate(): Promise<RESTAuthContext> {
        return {
            Token: 'test-token',
            ExpiresAt: new Date(Date.now() + 3600_000),
            BaseUrl: 'https://pub.orcid.org/v3.0',
            Config: { ClientID: 'cid', ClientSecret: 'sec', UseSandbox: false, ...this.Config },
        } as RESTAuthContext;
    }

    protected override async MakeHTTPRequest(
        _auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>
    ): Promise<RESTResponse> {
        this.Calls.push({ url, method, headers });
        this.InFlight++;
        this.MaxInFlight = Math.max(this.MaxInFlight, this.InFlight);
        try {
            if (this.Latency > 0) await new Promise(resolve => setTimeout(resolve, this.Latency));
            return this.Responder(url);
        } finally {
            this.InFlight--;
        }
    }

    protected override GetCachedObject(_integrationID: string, objectName: string): MJIntegrationObjectEntity {
        return OBJECTS[objectName].obj;
    }

    protected override GetCachedFields(objectID: string): MJIntegrationObjectFieldEntity[] {
        const name = objectID.replace(/^io-/, '');
        return OBJECTS[name].fields;
    }
}

function ctx(objectName: string, watermark: string | null = null, over: Partial<FetchContext> = {}): FetchContext {
    return {
        CompanyIntegration: { ID: 'ci-1', IntegrationID: 'int-1' } as MJCompanyIntegrationEntity,
        ObjectName: objectName,
        WatermarkValue: watermark,
        BatchSize: 1000,
        ContextUser: {} as never,
        ...over,
    };
}

function respond(url: string): RESTResponse {
    if (url.includes('/search')) return { Status: 200, Body: SEARCH_FIXTURE, Headers: {} };
    if (url.includes('/record')) return { Status: 200, Body: RECORD_FIXTURE, Headers: {} };
    if (url.includes('/works')) return { Status: 200, Body: WORKS_FIXTURE, Headers: {} };
    return { Status: 404, Body: null, Headers: {} };
}

// ─── Identity + capability ────────────────────────────────────────────

describe('ORCIDConnector — identity & capabilities', () => {
    const c = new ORCIDConnector();

    it('instantiates and exposes the verbatim IntegrationName', () => {
        expect(c).toBeInstanceOf(ORCIDConnector);
        expect(c.IntegrationName).toBe('ORCID');
    });

    it('is PULL-ONLY (no create/update/delete)', () => {
        expect(c.SupportsCreate).toBe(false);
        expect(c.SupportsUpdate).toBe(false);
        expect(c.SupportsDelete).toBe(false);
    });

    it('declares a conservative RateLimitPolicy under the 40 req/s burst', () => {
        const policy = c.RateLimitPolicy;
        expect(policy).not.toBeNull();
        expect(policy!.TokensPerSec).toBeLessThanOrEqual(40);
        expect(policy!.Burst).toBe(40);
    });

    it('raises MaxConcurrencyHint above the engine default so the sync is rate-bound, not latency-bound', () => {
        // At the engine's default of 4 in-flight and ~1.4s/request, throughput caps near 3 req/s —
        // well under the ~10 req/s the RateLimitPolicy already allows.
        expect(c.MaxConcurrencyHint).toBeGreaterThan(4);
        expect(c.MaxConcurrencyHint!).toBeLessThanOrEqual(c.RateLimitPolicy!.Burst!);
    });

    it('StableOrderingKey is null for the search-scoped universe (keyset N/A)', () => {
        expect(c.StableOrderingKey('record')).toBeNull();
        expect(c.StableOrderingKey('works')).toBeNull();
    });

    it('CreateRecord throws via the base stub (capability false)', async () => {
        await expect(c.CreateRecord({} as never)).rejects.toThrow();
    });
});

// ─── TestConnection ───────────────────────────────────────────────────

describe('ORCIDConnector — TestConnection', () => {
    let c: TestORCIDConnector;
    beforeEach(() => { c = new TestORCIDConnector(); });

    it('happy path: a 200 probe yields Success', async () => {
        c.Responder = () => ({ Status: 200, Body: RECORD_FIXTURE, Headers: {} });
        const res = await c.TestConnection({} as MJCompanyIntegrationEntity, {} as never);
        expect(res.Success).toBe(true);
        expect(res.ServerVersion).toContain('v3.0');
    });

    it('auth-fail path: a 401 probe yields failure', async () => {
        c.Responder = () => ({ Status: 401, Body: null, Headers: {} });
        const res = await c.TestConnection({} as MJCompanyIntegrationEntity, {} as never);
        expect(res.Success).toBe(false);
        expect(res.Message).toContain('401');
    });

    it('network-error path: a thrown transport error yields failure', async () => {
        c.Responder = () => { throw new Error('ENOTFOUND pub.orcid.org'); };
        // exhaust retries quickly by treating it as non-retryable? It IS retryable; cap retries via config.
        c.Config = { ...c.Config, MaxRetries: 0 };
        const res = await c.TestConnection({} as MJCompanyIntegrationEntity, {} as never);
        expect(res.Success).toBe(false);
    });
});

// ─── DiscoverObjects / DiscoverFields (base cache path is not exercised; verify shape via fields) ──

describe('ORCIDConnector — schema mapping', () => {
    it('record IO declares orcid-id as the PK', () => {
        const pk = RECORD_FIELDS.filter(f => f.IsPrimaryKey).map(f => f.Name);
        expect(pk).toEqual(['orcid-id']);
    });
    it('works IO declares put-code as the PK and orcid-id as the FK', () => {
        const pk = WORKS_FIELDS.filter(f => f.IsPrimaryKey).map(f => f.Name);
        expect(pk).toEqual(['put-code']);
        const fk = WORKS_FIELDS.find(f => f.Name === 'orcid-id');
        expect(fk?.RelatedIntegrationObjectID).toBe('io-record');
    });
});

// ─── FetchChanges: iD universe resolution + per-iD fan-out ────────────

describe('ORCIDConnector — FetchChanges (record)', () => {
    let c: TestORCIDConnector;
    beforeEach(() => { c = new TestORCIDConnector(); c.Responder = respond; });

    it('resolves the iD universe via /search then fetches /{iD}/record per iD', async () => {
        const result = await c.FetchChanges(ctx('record'));
        // Two iDs found → two /record fetches (plus the /search call).
        const recordCalls = c.Calls.filter(x => x.url.includes('/record'));
        const searchCalls = c.Calls.filter(x => x.url.includes('/search'));
        expect(searchCalls.length).toBeGreaterThanOrEqual(1);
        expect(recordCalls.length).toBe(2);
        expect(result.Records.length).toBe(2);
    });

    it('sends Lucene query + offset pagination params to /search', async () => {
        await c.FetchChanges(ctx('record'));
        const search = c.Calls.find(x => x.url.includes('/search'))!;
        expect(search.url).toContain('q=');
        expect(search.url).toContain('start=0');
        expect(search.url).toContain('rows=');
    });

    it('flattens person scalars and the PK onto Fields while preserving full record', async () => {
        const result = await c.FetchChanges(ctx('record'));
        // Select by iD rather than by index: the iD universe is now sorted lexicographically so it
        // can serve as a keyset pagination key, which means position is not a stable handle.
        const rec = result.Records.find(r => r.Fields['orcid-id'] === '0000-0002-1825-0097')!;
        expect(rec).toBeDefined();
        expect(rec.Fields['given-names']).toBe('Test');
        expect(rec.Fields['family-name']).toBe('Researcher');
        expect(rec.Fields['orcid-id']).toBe('0000-0002-1825-0097');
        // full-record pass-through: nested blobs retained
        expect(rec.Fields['person']).toBeDefined();
        expect(rec.Fields['history']).toBeDefined();
        // PK drives ExternalID
        expect(rec.ExternalID).toBe('0000-0002-1825-0097');
    });

    it('sets Authorization bearer + Accept JSON headers', async () => {
        await c.FetchChanges(ctx('record'));
        const call = c.Calls[0];
        expect(call.headers['Authorization']).toBe('Bearer test-token');
        expect(call.headers['Accept']).toBe('application/json');
    });

    it('uses explicit orcidIds when no searchQuery is set (no /search call)', async () => {
        c.Config = { OrcidIds: ['0000-0002-1825-0097'] };
        const result = await c.FetchChanges(ctx('record'));
        expect(c.Calls.find(x => x.url.includes('/search'))).toBeUndefined();
        expect(result.Records.length).toBe(1);
    });

    // ── iD-universe pagination ──────────────────────────────────────────
    // Regression cover for silent data loss: the universe used to be sliced to BatchSize and the
    // remainder DISCARDED, while still reporting HasMore:false. Any iD past the first BatchSize was
    // permanently unsyncable — a 500-iD universe at BatchSize 100 lost 400 iDs on every run.

    const paged = (after?: string): FetchContext => ({
        CompanyIntegration: { IntegrationID: 'int-1' } as MJCompanyIntegrationEntity,
        ObjectName: 'record',
        WatermarkValue: null,
        BatchSize: 1,
        ContextUser: {} as never,
        AfterKeyValue: after,
    });

    it('bounds the batch to BatchSize iDs and signals HasMore with a resume key', async () => {
        const page1 = await c.FetchChanges(paged());
        expect(page1.Records).toHaveLength(1);
        expect(page1.HasMore).toBe(true);
        // Universe is sorted, so the lexicographically-first iD leads.
        expect(page1.Records[0].Fields['orcid-id']).toBe('0000-0001-2345-6789');
        expect(page1.NextAfterKeyValue).toBe('0000-0001-2345-6789');
    });

    it('resumes strictly after AfterKeyValue and ends the scan on the final page', async () => {
        const page2 = await c.FetchChanges(paged('0000-0001-2345-6789'));
        expect(page2.Records).toHaveLength(1);
        expect(page2.Records[0].Fields['orcid-id']).toBe('0000-0002-1825-0097');
        expect(page2.HasMore).toBe(false);
    });

    it('loses no iD across the full paged scan (the bug this replaces)', async () => {
        const seen: string[] = [];
        let after: string | undefined;
        for (let guard = 0; guard < 10; guard++) {
            const page = await c.FetchChanges(paged(after));
            for (const r of page.Records) seen.push(String(r.Fields['orcid-id']));
            if (!page.HasMore) break;
            after = page.NextAfterKeyValue;
        }
        expect(seen.sort()).toEqual(['0000-0001-2345-6789', '0000-0002-1825-0097']);
    });

    it('returns a ZERO_SCOPE warning when Configuration scopes nothing', async () => {
        c.Config = {};
        const result = await c.FetchChanges(ctx('record'));
        expect(result.Records).toEqual([]);
        expect(result.Warnings?.[0]?.Code).toBe('ZERO_SCOPE');
    });
});

// ─── Per-iD failure isolation ─────────────────────────────────────────

describe('ORCIDConnector — per-iD failure isolation', () => {
    let c: TestORCIDConnector;
    const GOOD = '0000-0002-1825-0097';
    const BAD = '0000-0001-2345-6789';

    /** Serves the normal fixtures except for BAD's /record, which hard-fails with a 500. */
    function respondWithOneBadId(url: string): RESTResponse {
        if (url.includes(BAD) && url.includes('/record')) return { Status: 500, Body: null, Headers: {} };
        return respond(url);
    }

    beforeEach(() => {
        c = new TestORCIDConnector();
        c.Responder = respondWithOneBadId;
        c.Config = { OrcidIds: [GOOD, BAD] };
    });

    it('skips a failing iD and still returns the healthy ones', async () => {
        const result = await c.FetchChanges(ctx('record'));
        expect(result.Records.length).toBe(1);
        expect(result.Records[0].Fields['orcid-id']).toBe(GOOD);
    });

    it('surfaces the skip as an ID_FETCH_FAILED warning naming the iD', async () => {
        const result = await c.FetchChanges(ctx('record'));
        const warning = result.Warnings?.find(w => w.Code === 'ID_FETCH_FAILED');
        expect(warning).toBeDefined();
        expect(warning!.Message).toContain(BAD);
        expect(warning!.Data?.['orcidId']).toBe(BAD);
    });

    it('HOLDS the watermark when an iD was skipped, so the skipped record is not stranded', async () => {
        const result = await c.FetchChanges(ctx('record'));
        // A clean run advances the watermark; a run with a skip must not, or the skipped iD's
        // updates fall permanently below the new watermark and are never re-fetched.
        expect(result.NewWatermarkValue).toBeUndefined();
    });

    it('still advances the watermark when every iD succeeds', async () => {
        c.Responder = respond;
        const result = await c.FetchChanges(ctx('record'));
        expect(result.Records.length).toBe(2);
        expect(result.Warnings?.some(w => w.Code === 'ID_FETCH_FAILED')).toBeFalsy();
        expect(result.NewWatermarkValue).toBeDefined();
    });

    it('a 404 iD is a normal empty, not a skip-warning', async () => {
        c.Responder = (url: string) =>
            url.includes(BAD) && url.includes('/record')
                ? { Status: 404, Body: null, Headers: {} }
                : respond(url);
        const result = await c.FetchChanges(ctx('record'));
        expect(result.Records.length).toBe(1);
        expect(result.Warnings?.some(w => w.Code === 'ID_FETCH_FAILED')).toBeFalsy();
    });
});

// ─── Derived sections: built from the stored record, no per-section API call ──

const SAMPLE = '0000-0002-1825-0097';
const SAMPLE_WORKS = extractSectionRawItems(FULL_RECORD, 'works', SAMPLE);
const SAMPLE_WORK_LMDS = SAMPLE_WORKS.map(w => extractMs(w['last-modified-date'])!).sort((a, b) => a - b);

describe('ORCIDConnector — FetchChanges (derived section: works)', () => {
    let c: TestORCIDConnector;
    beforeEach(() => {
        c = new TestORCIDConnector();
        c.Responder = respond;
        c.Config = { OrcidIds: [SAMPLE] };
        c.Stored.set(SAMPLE, FULL_RECORD);
    });

    it('makes NO ORCID call: every item comes out of the stored record', async () => {
        const result = await c.FetchChanges(ctx('works'));
        expect(c.Calls).toHaveLength(0);
        expect(result.Records.length).toBe(SAMPLE_WORKS.length);
        expect(result.Records.length).toBeGreaterThan(0);
        expect(result.Warnings?.some(w => w.Code === 'RECORD_FALLBACK_FETCH')).toBeFalsy();
    });

    it('expands the group envelope into individual put-code items tagged with orcid-id', async () => {
        const result = await c.FetchChanges(ctx('works'));
        const putCodes = result.Records.map(r => r.Fields['put-code']);
        expect(new Set(putCodes).size).toBe(putCodes.length);
        for (const r of result.Records) expect(r.Fields['orcid-id']).toBe(SAMPLE);
    });

    it('put-code drives the ExternalID per item', async () => {
        const result = await c.FetchChanges(ctx('works'));
        for (const r of result.Records) expect(r.ExternalID).toBe(String(r.Fields['put-code']));
    });

    it('flattens the nested shapes into the declared column-shaped keys', async () => {
        const result = await c.FetchChanges(ctx('works'));
        const titled = result.Records.find(r => r.Fields['work-title'] === 'A Methodology for the Emulation of Architecture');
        expect(titled).toBeDefined();
        expect(titled!.Fields['work-subtitle']).toBe('Journal of Psychoceramics');
        expect(typeof titled!.Fields['publication-year']).toBe('number');
        expect(typeof titled!.Fields['source-name']).toBe('string');
        // Dates are coerced to ISO strings for the DateTime columns, as before.
        expect(typeof titled!.Fields['last-modified-date']).toBe('string');
        // The nested title blob is still there — nothing the API returned is dropped.
        expect(titled!.Fields['title']).toBeDefined();
    });

    it('falls back to ONE /record fetch for an iD with no stored record, and says so', async () => {
        const other = '0000-0001-2345-6789';
        c.Config = { OrcidIds: [SAMPLE, other] };
        c.Responder = (url: string) => url.includes('/record')
            ? { Status: 200, Body: FULL_RECORD, Headers: {} }
            : respond(url);
        const result = await c.FetchChanges(ctx('works'));
        const recordCalls = c.Calls.filter(x => x.url.includes('/record'));
        expect(recordCalls).toHaveLength(1);
        expect(recordCalls[0].url).toContain(other);
        expect(c.Calls.some(x => x.url.includes('/works'))).toBe(false);
        // Both people's works are present: the stored one and the live-fetched one.
        expect(result.Records.filter(r => r.Fields['orcid-id'] === SAMPLE)).toHaveLength(SAMPLE_WORKS.length);
        expect(result.Records.filter(r => r.Fields['orcid-id'] === other)).toHaveLength(SAMPLE_WORKS.length);
        const warning = result.Warnings?.find(w => w.Code === 'RECORD_FALLBACK_FETCH');
        expect(warning).toBeDefined();
        expect(warning!.Data?.['count']).toBe(1);
        expect(warning!.Data?.['orcidIds']).toEqual([other]);
    });

    it('a stored record with no such section yields no items and no error', async () => {
        c.Stored.set(SAMPLE, { person: FULL_RECORD['person'], 'activities-summary': {} });
        const result = await c.FetchChanges(ctx('works'));
        expect(result.Records).toEqual([]);
        expect(c.Calls).toHaveLength(0);
    });
});

describe('ORCIDConnector — FetchChanges (derived person sections)', () => {
    let c: TestORCIDConnector;
    beforeEach(() => {
        c = new TestORCIDConnector();
        c.Responder = respond;
        c.Config = { OrcidIds: [SAMPLE] };
        c.Stored.set(SAMPLE, FULL_RECORD);
        OBJECTS['keywords'] = { obj: mockObject('keywords'), fields: WORKS_FIELDS };
        OBJECTS['external-identifiers'] = { obj: mockObject('external-identifiers'), fields: WORKS_FIELDS };
        OBJECTS['email'] = { obj: mockObject('email'), fields: WORKS_FIELDS };
    });

    it('keywords come out of the person block with content as a plain string', async () => {
        const result = await c.FetchChanges(ctx('keywords'));
        expect(c.Calls).toHaveLength(0);
        expect(result.Records.length).toBeGreaterThan(0);
        for (const r of result.Records) {
            expect(typeof r.Fields['content']).toBe('string');
            expect(r.Fields['orcid-id']).toBe(SAMPLE);
            expect(r.ExternalID).toBe(String(r.Fields['put-code']));
        }
    });

    it('external identifiers carry type/value and an unwrapped url', async () => {
        const result = await c.FetchChanges(ctx('external-identifiers'));
        const scopus = result.Records.find(r => r.Fields['external-id-type'] === 'Scopus Author ID');
        expect(scopus).toBeDefined();
        expect(scopus!.Fields['external-id-value']).toBe('7007156898');
        expect(typeof scopus!.Fields['external-id-url']).toBe('string');
    });

    it('an empty person list (email) is a clean empty result', async () => {
        const result = await c.FetchChanges(ctx('email'));
        expect(result.Records).toEqual([]);
        expect(result.Warnings).toBeUndefined();
    });
});

// ─── Incremental watermark + content-hash idempotency ────────────────

describe('ORCIDConnector — incremental sync', () => {
    let c: TestORCIDConnector;
    const oldest = SAMPLE_WORK_LMDS[0];
    const newest = SAMPLE_WORK_LMDS[SAMPLE_WORK_LMDS.length - 1];
    beforeEach(() => {
        c = new TestORCIDConnector();
        c.Responder = respond;
        c.Config = { OrcidIds: [SAMPLE] };
        c.Stored.set(SAMPLE, FULL_RECORD);
    });

    it('first sync (no watermark) returns all items and a NewWatermarkValue = max last-modified', async () => {
        const result = await c.FetchChanges(ctx('works', null));
        expect(result.Records.length).toBe(SAMPLE_WORKS.length);
        expect(result.NewWatermarkValue).toBe(String(newest));
    });

    it('subsequent sync narrows to items strictly newer than the watermark', async () => {
        expect(oldest).toBeLessThan(newest); // the fixture has to span more than one modification time
        const result = await c.FetchChanges(ctx('works', String(oldest)));
        const expected = SAMPLE_WORK_LMDS.filter(t => t > oldest).length;
        expect(result.Records.length).toBe(expected);
        expect(result.NewWatermarkValue).toBe(String(newest));
    });

    it('no advancement when nothing is newer than the watermark (NewWatermarkValue omitted)', async () => {
        const result = await c.FetchChanges(ctx('works', String(newest)));
        expect(result.Records.length).toBe(0);
        expect(result.NewWatermarkValue).toBeUndefined();
    });

    it('content-hash idempotency: re-running yields identical ExternalIDs/Fields (PK-stable)', async () => {
        const a = await c.FetchChanges(ctx('works', null));
        const b = await c.FetchChanges(ctx('works', null));
        expect(a.Records.map(r => r.ExternalID).sort()).toEqual(b.Records.map(r => r.ExternalID).sort());
        expect(a.Records.map(r => r.Fields)).toEqual(b.Records.map(r => r.Fields));
    });
});

// ─── Root page: concurrency, page cap, universe caching ───────────────

describe('ORCIDConnector — root fetch concurrency and paging', () => {
    let c: TestORCIDConnector;
    const universe = Array.from({ length: 12 }, (_, i) => syntheticId(i + 1));
    beforeEach(() => {
        c = new TestORCIDConnector();
        c.Responder = respond;
        c.Config = { OrcidIds: universe };
    });

    it('caps a root page at 10 iDs regardless of BatchSize, so a page fits the engine timeout at concurrency 1', async () => {
        const page1 = await c.FetchChanges(ctx('record', null, { BatchSize: 1000 }));
        expect(page1.Records).toHaveLength(10);
        expect(page1.HasMore).toBe(true);
        expect(c.Calls.filter(x => x.url.includes('/record'))).toHaveLength(10);
        const page2 = await c.FetchChanges(ctx('record', null, { BatchSize: 1000, AfterKeyValue: page1.NextAfterKeyValue }));
        expect(page2.Records).toHaveLength(2);
        expect(page2.HasMore).toBe(false);
    });

    it('a derived page is not capped at 10: all 12 stored iDs come back in one page', async () => {
        for (const iD of universe) c.Stored.set(iD, FULL_RECORD);
        const page = await c.FetchChanges(ctx('works', null, { BatchSize: 1000 }));
        expect(page.HasMore).toBe(false);
        expect(new Set(page.Records.map(r => r.Fields['orcid-id'])).size).toBe(12);
        expect(c.Calls).toHaveLength(0);
    });

    it('fans the page across MaxConcurrency in-flight requests, each gated by RateLimitAcquire', async () => {
        c.Latency = 5;
        let acquired = 0;
        const reports: unknown[] = [];
        await c.FetchChanges(ctx('record', null, {
            MaxConcurrency: 4,
            RateLimitAcquire: async () => { acquired++; },
            RateLimitReport: (err?: unknown) => { reports.push(err); },
        }));
        expect(c.MaxInFlight).toBe(4);
        expect(acquired).toBe(10);
        expect(reports).toHaveLength(10);
        expect(reports.every(r => r === undefined)).toBe(true);
    });

    it('with no engine hooks it runs one request at a time (old behaviour)', async () => {
        c.Latency = 2;
        await c.FetchChanges(ctx('record'));
        expect(c.MaxInFlight).toBe(1);
    });

    it('a throttled iD (429) is reported to the rate limiter with its headers, and still isolated', async () => {
        const bad = universe[3];
        c.Responder = (url: string) => url.includes(bad)
            ? { Status: 429, Body: null, Headers: { 'retry-after': '3' } }
            : respond(url);
        c.Config = { ...c.Config, MaxRetries: 0 };
        const reports: unknown[] = [];
        const result = await c.FetchChanges(ctx('record', null, { MaxConcurrency: 3, RateLimitReport: (e?: unknown) => { reports.push(e); } }));
        expect(result.Records).toHaveLength(9);
        const throttles = reports.filter(r => r !== undefined);
        expect(throttles).toHaveLength(1);
        // The engine reads Retry-After off the reported error via ExtractRetryAfterMs.
        expect(c.ExtractRetryAfterMs(throttles[0])).toBe(3000);
        expect(result.Warnings?.find(w => w.Code === 'ID_FETCH_FAILED')?.Data?.['orcidId']).toBe(bad);
    });

    it('a plain failure (500) is isolated but NOT reported as a throttle — the engine would back off the whole connection', async () => {
        const bad = universe[3];
        c.Responder = (url: string) => url.includes(bad) ? { Status: 500, Body: null, Headers: {} } : respond(url);
        c.Config = { ...c.Config, MaxRetries: 0 };
        const reports: unknown[] = [];
        const result = await c.FetchChanges(ctx('record', null, { MaxConcurrency: 3, RateLimitReport: (e?: unknown) => { reports.push(e); } }));
        expect(result.Records).toHaveLength(9);
        expect(reports).toHaveLength(9); // one clean report per success, nothing for the 500
        expect(reports.every(r => r === undefined)).toBe(true);
        expect(result.Warnings?.find(w => w.Code === 'ID_FETCH_FAILED')?.Data?.['orcidId']).toBe(bad);
    });

    it('resolves a search-scoped universe once and reuses it across pages', async () => {
        c.Config = { SearchQuery: 'affiliation-org-name:"Test University"' };
        const page1 = await c.FetchChanges(ctx('record', null, { BatchSize: 1 }));
        await c.FetchChanges(ctx('record', null, { BatchSize: 1, AfterKeyValue: page1.NextAfterKeyValue }));
        expect(c.Calls.filter(x => x.url.includes('/search'))).toHaveLength(1);
    });
});

// ─── NormalizeResponse + pagination ───────────────────────────────────

describe('ORCIDConnector — NormalizeResponse / pagination', () => {
    let c: TestORCIDConnector;
    beforeEach(() => { c = new TestORCIDConnector(); });

    it('NormalizeResponse wraps a single object as a one-element array', () => {
        const out = (c as unknown as { NormalizeResponse(b: unknown, k: string | null): Record<string, unknown>[] })
            .NormalizeResponse(RECORD_FIXTURE, null);
        expect(out.length).toBe(1);
    });

    it('NormalizeResponse extracts an array under a responseDataKey', () => {
        const out = (c as unknown as { NormalizeResponse(b: unknown, k: string | null): Record<string, unknown>[] })
            .NormalizeResponse(SEARCH_FIXTURE, 'result');
        expect(out.length).toBe(2);
    });

    it('NormalizeResponse returns [] for null body', () => {
        const out = (c as unknown as { NormalizeResponse(b: unknown, k: string | null): Record<string, unknown>[] })
            .NormalizeResponse(null, null);
        expect(out).toEqual([]);
    });

    it('ExtractPaginationInfo always reports HasMore=false (per-iD endpoints unpaginated)', () => {
        const state = (c as unknown as {
            ExtractPaginationInfo(b: unknown, t: PaginationType, p: number, o: number, s: number): { HasMore: boolean };
        }).ExtractPaginationInfo(RECORD_FIXTURE, 'None', 1, 0, 50);
        expect(state.HasMore).toBe(false);
    });
});

// ─── Retry-After parsing ──────────────────────────────────────────────

describe('ORCIDConnector — ExtractRetryAfterMs', () => {
    const c = new ORCIDConnector();
    it('parses delta-seconds Retry-After into ms', () => {
        expect(c.ExtractRetryAfterMs({ Headers: { 'retry-after': '2' } })).toBe(2000);
    });
    it('returns undefined when no Retry-After present', () => {
        expect(c.ExtractRetryAfterMs({ Headers: {} })).toBeUndefined();
        expect(c.ExtractRetryAfterMs(new Error('boom'))).toBeUndefined();
    });
});

// ─── Anonymous Public API mode ────────────────────────────────────────

/**
 * Drives the REAL auth path (parseConfig → Authenticate → obtainAccessToken →
 * MakeHTTPRequest → doFetch) by stubbing global fetch, so these tests observe what
 * actually goes on the wire: whether the OAuth token endpoint is hit at all, and
 * whether an Authorization header is attached. Only the cached-metadata accessors
 * are overridden (they'd otherwise need a live provider).
 */
class WireORCIDConnector extends ORCIDConnector {
    protected override GetCachedObject(_integrationID: string, objectName: string): MJIntegrationObjectEntity {
        return OBJECTS[objectName].obj;
    }
    protected override GetCachedFields(objectID: string): MJIntegrationObjectFieldEntity[] {
        return OBJECTS[objectID.replace(/^io-/, '')].fields;
    }
}

/** A CompanyIntegration with NO CredentialID, so parseConfig reads Configuration only. */
function ciWithConfig(config: Record<string, unknown>): MJCompanyIntegrationEntity {
    return {
        IntegrationID: 'int-1',
        CredentialID: null,
        Configuration: JSON.stringify(config),
    } as unknown as MJCompanyIntegrationEntity;
}

interface WireCall { url: string; headers: Record<string, string> }

/**
 * Stubs global fetch. Records every outbound call, answers the ORCID token endpoint
 * with a bearer token, and answers API calls with `apiStatus` + the record fixture.
 */
function stubWire(apiStatus = 200): WireCall[] {
    const calls: WireCall[] = [];
    vi.stubGlobal('fetch', async (url: string, init?: { headers?: Record<string, string> }) => {
        calls.push({ url: String(url), headers: (init?.headers ?? {}) as Record<string, string> });
        const isToken = String(url).includes('/oauth/token');
        const payload = isToken
            ? { access_token: 'wire-token', token_type: 'bearer', expires_in: 3600 }
            : RECORD_FIXTURE;
        const status = isToken ? 200 : apiStatus;
        // obtainAccessToken reads .ok/.json() directly off fetch; doFetch reads .status/.text().
        return {
            ok: status >= 200 && status < 300,
            status,
            headers: { forEach: (fn: (v: string, k: string) => void) => { fn('application/json', 'content-type'); } },
            text: async () => JSON.stringify(payload),
            json: async () => payload,
        };
    });
    return calls;
}

describe('ORCIDConnector — anonymous Public API mode', () => {
    afterEach(() => { vi.unstubAllGlobals(); });

    it('with NO credential: skips the OAuth grant entirely and sends no Authorization header', async () => {
        const calls = stubWire();
        const c = new WireORCIDConnector();

        const res = await c.TestConnection(ciWithConfig({ orcidIds: ['0000-0002-1825-0097'] }), {} as never);

        expect(res.Success).toBe(true);
        // Not one request to the token endpoint — the grant is skipped, not merely ignored.
        expect(calls.filter(x => x.url.includes('/oauth/token'))).toHaveLength(0);
        // And the API call carries no Authorization header at all (absent, not empty).
        const apiCalls = calls.filter(x => x.url.includes('/record'));
        expect(apiCalls.length).toBeGreaterThan(0);
        for (const call of apiCalls) {
            expect(Object.keys(call.headers).map(k => k.toLowerCase())).not.toContain('authorization');
            expect(call.headers['Accept']).toBe('application/json');
        }
    });

    it('reports anonymous mode in the TestConnection message so the operator sees which mode ran', async () => {
        stubWire();
        const c = new WireORCIDConnector();
        const res = await c.TestConnection(ciWithConfig({ orcidIds: ['0000-0002-1825-0097'] }), {} as never);
        expect(res.Success).toBe(true);
        expect(res.Message.toLowerCase()).toContain('anonymous');
    });

    it('with BOTH credentials: still runs the client_credentials grant and sends the bearer', async () => {
        const calls = stubWire();
        const c = new WireORCIDConnector();

        const res = await c.TestConnection(
            ciWithConfig({ clientId: 'cid', clientSecret: 'sec', orcidIds: ['0000-0002-1825-0097'] }),
            {} as never
        );

        expect(res.Success).toBe(true);
        expect(calls.filter(x => x.url.includes('/oauth/token'))).toHaveLength(1);
        const apiCall = calls.find(x => x.url.includes('/record'));
        expect(apiCall!.headers['Authorization']).toBe('Bearer wire-token');
        expect(res.Message.toLowerCase()).not.toContain('anonymous');
    });

    it('with only HALF a credential: fails loudly rather than silently degrading to anonymous', async () => {
        stubWire();
        const c = new WireORCIDConnector();

        // A missing secret is a misconfiguration; quietly syncing public-only data would hide it.
        const res = await c.TestConnection(ciWithConfig({ clientId: 'cid' }), {} as never);

        expect(res.Success).toBe(false);
        expect(res.Message).toMatch(/both/i);
    });

    it('a 401 in anonymous mode does NOT trigger a token grant or a retry storm', async () => {
        // There is no grant to re-run, and the resource simply is not public — retrying would
        // burn the retry budget on a response that can never change.
        const calls = stubWire(401);
        const c = new WireORCIDConnector();

        const res = await c.TestConnection(ciWithConfig({ orcidIds: ['0000-0002-1825-0097'] }), {} as never);

        expect(res.Success).toBe(false);
        expect(calls.filter(x => x.url.includes('/oauth/token'))).toHaveLength(0);
        expect(calls.filter(x => x.url.includes('/record'))).toHaveLength(1);
    });
});
