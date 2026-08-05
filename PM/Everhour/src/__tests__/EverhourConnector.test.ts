import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { describe, it, expect, beforeEach } from 'vitest';
import type { RESTResponse, PaginationType, FetchContext } from '@memberjunction/integration-engine';
import type {
    MJCompanyIntegrationEntity,
    MJIntegrationObjectEntity,
    MJIntegrationObjectFieldEntity,
} from '@memberjunction/core-entities';
import type { UserInfo } from '@memberjunction/core';
import {
    EverhourConnector,
    incrementalFromDate,
    maxDate,
    parseLookbackDays,
    platformFromID,
    restoreColons,
    serializeCollection,
} from '../EverhourConnector.js';

/**
 * The SHIPPED catalog, not a hand-made stub.
 *
 * The IntegrationObject rows these tests drive the base class with are read out of the metadata file
 * this package actually deploys. That is the point: the connector's behaviour (which params it
 * appends, which page size it clamps to, which doors iterate a parent) is a function of that metadata,
 * so a test built on an invented stub could pass while the shipped catalog said something else.
 */
interface MetadataObject {
    fields: Record<string, unknown>;
    relatedEntities: { 'MJ: Integration Object Fields': Array<{ fields: Record<string, unknown> }> };
}
interface MetadataDoc {
    fields: Record<string, unknown>;
    relatedEntities: { 'MJ: Integration Objects': MetadataObject[] };
}

const METADATA = JSON.parse(
    readFileSync(
        fileURLToPath(new URL('../../metadata/integration/.everhour.integration.json', import.meta.url)),
        'utf-8'
    )
) as MetadataDoc[];

const INTEGRATION = METADATA[0];
const OBJECTS = INTEGRATION.relatedEntities['MJ: Integration Objects'];

const objectMetadata = (name: string): MetadataObject => {
    const found = OBJECTS.find(o => o.fields.Name === name);
    if (!found) throw new Error(`no object "${name}" in the shipped metadata`);
    return found;
};

/** Projects a shipped metadata record into the entity shape the base class reads. */
const ioRow = (name: string): MJIntegrationObjectEntity =>
    ({ ID: `io-${name}`, ...objectMetadata(name).fields } as unknown as MJIntegrationObjectEntity);

const ioFields = (name: string): MJIntegrationObjectFieldEntity[] =>
    objectMetadata(name).relatedEntities['MJ: Integration Object Fields'].map(
        r => r.fields as unknown as MJIntegrationObjectFieldEntity
    );

/** The fixed clock every test runs against, so `to=` and the lookback window are deterministic. */
const TODAY = '2026-08-05';

/**
 * MOCKED-ONLY test connector. Overrides just the seams that reach the outside world — the credential
 * load, the HTTP transport and the clock — plus the engine metadata cache. Everything else, including
 * the whole paginated fetch loop and URL assembly, is the real production code path.
 */
class TestEverhourConnector extends EverhourConnector {
    public Routes = new Map<string, RESTResponse>();
    public RequestedURLs: string[] = [];
    public TestApiKey: string | undefined = 'test-key';

    protected override async Authenticate(): Promise<{ ApiKey: string }> {
        if (!this.TestApiKey) throw new Error('No Everhour credential found — link an "API Key" credential.');
        return { ApiKey: this.TestApiKey };
    }

    protected override async MakeHTTPRequest(
        _auth: { ApiKey: string },
        url: string
    ): Promise<RESTResponse> {
        // restoreColons runs in the real MakeHTTPRequest, so record the URL exactly as it would go on
        // the wire — that is the thing worth asserting.
        const wire = restoreColons(url);
        this.RequestedURLs.push(wire);
        return this.Routes.get(wire) ?? { Status: 404, Body: { message: `unrouted ${wire}` }, Headers: {} };
    }

    protected override Today(): string { return TODAY; }

    protected override GetCachedObject(_integrationID: string, objectName: string): MJIntegrationObjectEntity {
        return ioRow(objectName);
    }

    protected override GetCachedFields(objectID: string): MJIntegrationObjectFieldEntity[] {
        return ioFields(objectID.replace(/^io-/, ''));
    }

    // Exposed protected seams for direct assertions.
    public callNormalize(body: unknown, key: string | null) { return this.NormalizeResponse(body, key); }
    public callPagination(body: unknown, type: PaginationType, page = 1, pageSize = 100) {
        return this.ExtractPaginationInfo(body, type, page, 0, pageSize);
    }
    public callBuildPaginatedURL(name: string, page = 1, pageSize?: number) {
        const obj = ioRow(name);
        return this.BuildPaginatedURL(obj.APIPath, obj, page, 0, undefined, pageSize);
    }
    public callAppendParams(name: string, url: string, watermark: string | null) {
        this.currentWatermark = watermark;
        try { return this.AppendDefaultQueryParams(url, ioRow(name)); }
        finally { this.currentWatermark = null; }
    }
    public callTransform(name: string, raw: Record<string, unknown>) {
        return this.TransformRecord(raw, ioRow(name), ioFields(name));
    }
    public callBuildHeaders() { return this.BuildHeaders({ ApiKey: 'test-key' }); }
}

const ctxFor = (objectName: string, over: Partial<FetchContext> = {}): FetchContext => ({
    CompanyIntegration: { ID: 'ci-1', IntegrationID: 'int-1' } as unknown as MJCompanyIntegrationEntity,
    ObjectName: objectName,
    WatermarkValue: null,
    BatchSize: 100,
    ContextUser: {} as UserInfo,
    ...over,
});

/** Everhour responds with a bare array — no envelope, which is why ResponseDataKey is empty. */
const page = (rows: unknown[]): RESTResponse => ({
    Status: 200,
    Body: rows,
    Headers: { 'content-type': 'application/json' },
});

const USERS_URL = 'https://api.everhour.com/team/users';
const PROJECTS_PAGE1 = 'https://api.everhour.com/projects?page=1&limit=100';

let c: TestEverhourConnector;
beforeEach(() => { c = new TestEverhourConnector(); });

describe('identity', () => {
    it('uses the same name as the shipped Integration record and the package', () => {
        expect(c.IntegrationName).toBe('Everhour');
        expect(INTEGRATION.fields.Name).toBe('Everhour');
        expect(INTEGRATION.fields.ClassName).toBe('@memberjunction/connector-everhour');
        expect(INTEGRATION.fields.ImportPath).toBe('@memberjunction/connector-everhour');
    });

    it('authenticates with X-Api-Key and pins the API version the catalog was validated against', () => {
        const headers = c.callBuildHeaders();
        expect(headers['X-Api-Key']).toBe('test-key');
        // Without this header Everhour serves "the most recent version" — a silent shape change.
        expect(headers['X-Accept-Version']).toBe('1.2');
    });

    it('declares a monotonic watermark and no keyset ordering key', () => {
        expect(c.MonotonicWatermark).toBe(true);
        expect(c.StableOrderingKey('TimeRecords')).toBeNull();
    });
});

describe('response envelope', () => {
    it('reads a bare array, which is what every Everhour listing returns', () => {
        expect(c.callNormalize([{ id: 1 }, { id: 2 }], '')).toHaveLength(2);
        expect(c.callNormalize([{ id: 1 }], null)).toHaveLength(1);
    });

    it('wraps a single-object response so /users/me-shaped bodies are not silently dropped', () => {
        expect(c.callNormalize({ id: 1, name: 'Ada' }, '')).toEqual([{ id: 1, name: 'Ada' }]);
    });

    it('returns nothing for a non-collection body rather than fabricating a record', () => {
        expect(c.callNormalize('server error', '')).toEqual([]);
        expect(c.callNormalize(null, '')).toEqual([]);
    });
});

describe('pagination', () => {
    /**
     * A bare array carries no next-page marker, so a full page is the only "there may be more" signal
     * there is.
     */
    it('asks for another page when the page came back full', () => {
        expect(c.callPagination(new Array(100).fill({ id: 1 }), 'PageNumber', 3, 100))
            .toEqual({ HasMore: true, NextPage: 4 });
    });

    it('ends the stream on a short page', () => {
        expect(c.callPagination([{ id: 1 }], 'PageNumber', 1, 100)).toEqual({ HasMore: false });
        expect(c.callPagination([], 'PageNumber', 1, 100)).toEqual({ HasMore: false });
    });

    it('ends the stream for a non-paginated object', () => {
        expect(c.callPagination([{ id: 1 }], 'None', 1, 100)).toEqual({ HasMore: false });
    });

    /**
     * The base class's PageNumber case emits `pageSize=`, which Everhour ignores rather than errors
     * on — it would fall back to its own page width, and ExtractPaginationInfo would then compare the
     * returned count against a width nobody requested. This keeps the override from being "cleaned up".
     */
    it("spells the page size Everhour's way (limit=), not the base class's way (pageSize=)", () => {
        const url = c.callBuildPaginatedURL('Projects', 2);
        expect(url).toContain('page=2');
        expect(url).toContain('limit=');
        expect(url).not.toContain('pageSize=');
    });

    it('clamps limit to the documented per-endpoint maximum', () => {
        // Tasks is the one Everhour states outright: 250 max.
        expect(c.callBuildPaginatedURL('Tasks', 1, 5000)).toContain('limit=250');
        expect(c.callBuildPaginatedURL('Projects', 1, 5000)).toContain('limit=100');
        expect(c.callBuildPaginatedURL('TimeRecords', 1, 99_999)).toContain('limit=1000');
        expect(c.callBuildPaginatedURL('Projects', 1, 40)).toContain('limit=40');
        expect(c.callBuildPaginatedURL('Projects', 1, 0)).toContain('limit=1');
    });

    it('leaves a non-paginated object without page params', () => {
        expect(c.callBuildPaginatedURL('Users')).toBe('/team/users');
    });
});

describe('the colon in every Everhour id', () => {
    /**
     * The base substitutes template vars with encodeURIComponent, so `{project_id}` = `as:123` becomes
     * `as%3A123`. The substitution helper is private, so this is the only seam that can undo it — and
     * every Everhour project and task id contains a colon.
     */
    it('restores %3A to a literal colon', () => {
        expect(restoreColons('https://api.everhour.com/projects/as%3A123/tasks'))
            .toBe('https://api.everhour.com/projects/as:123/tasks');
        expect(restoreColons('/projects/as%3a123/tasks')).toBe('/projects/as:123/tasks');
    });

    /** Not a general URL decode: an encoded & or space in a query value must survive intact. */
    it('leaves every other percent-escape alone', () => {
        expect(restoreColons('/x?q=a%26b%20c')).toBe('/x?q=a%26b%20c');
        expect(restoreColons('/x?q=100%25')).toBe('/x?q=100%25');
    });

    it('parses the source-platform code out of the id prefix', () => {
        expect(platformFromID('as:1234567890')).toBe('as');
        expect(platformFromID('ev:99')).toBe('ev');
        expect(platformFromID('b3:99')).toBe('b3');
    });

    /** A future id format must not silently produce a garbage platform value. */
    it('returns null rather than guessing when there is no prefix', () => {
        expect(platformFromID('1234567890')).toBeNull();
        expect(platformFromID('ASANA:1')).toBeNull();
        expect(platformFromID('asana:1')).toBeNull();
        expect(platformFromID(12345)).toBeNull();
        expect(platformFromID(null)).toBeNull();
    });
});

describe('per-run query params', () => {
    it('applies the from/to window only to the object that declares incremental sync', () => {
        const withWindow = c.callAppendParams('TimeRecords', '/team/time', '2026-07-01');
        expect(withWindow).toContain('from=');
        expect(withWindow).toContain(`to=${TODAY}`);
        // Everhour would ACCEPT from/to on other doors and silently narrow the result set, so a
        // leaked filter here is data loss with no error anywhere.
        expect(c.callAppendParams('Projects', '/projects', '2026-07-01')).not.toContain('from=');
        expect(c.callAppendParams('Tasks', '/projects/as:1/tasks', '2026-07-01')).not.toContain('from=');
    });

    /**
     * A first run must pull the whole history, not one lookback window — the failure mode of getting
     * this backwards is a sync that looks complete while holding seven days of data.
     */
    it('sends an open-ended from on a first (watermark-less) run', () => {
        expect(c.callAppendParams('TimeRecords', '/team/time', null)).toContain('from=2010-01-01');
    });

    /**
     * A time record's `date` is the day the work happened, but the record stays editable afterwards.
     * Filtering strictly from the high-water mark would land those later edits never.
     */
    it('backdates from by the lookback window declared in the object Configuration', () => {
        expect(parseLookbackDays(objectMetadata('TimeRecords').fields.Configuration as string)).toBe(7);
        expect(c.callAppendParams('TimeRecords', '/team/time', '2026-07-20')).toContain('from=2026-07-13');
    });
});

describe('lookback configuration', () => {
    it('falls back to 7 days when nothing is declared', () => {
        expect(parseLookbackDays(null)).toBe(7);
        expect(parseLookbackDays('{}')).toBe(7);
        expect(parseLookbackDays('{"parentObjectName":"Projects"}')).toBe(7);
    });

    it('honours a declared value', () => {
        expect(parseLookbackDays('{"lookbackDays":30}')).toBe(30);
        expect(parseLookbackDays('{"lookbackDays":0}')).toBe(0);
    });

    /** Tenant-editable config: a typo must not take the object's sync down. */
    it('falls back rather than throwing on a malformed or absurd value', () => {
        expect(parseLookbackDays('not json')).toBe(7);
        expect(parseLookbackDays('{"lookbackDays":"30"}')).toBe(7);
        expect(parseLookbackDays('{"lookbackDays":-1}')).toBe(7);
        expect(parseLookbackDays('{"lookbackDays":99999}')).toBe(7);
        expect(parseLookbackDays('[1,2,3]')).toBe(7);
    });
});

describe('incremental window', () => {
    it('backdates the watermark by the lookback', () => {
        expect(incrementalFromDate('2026-07-20', 7, TODAY)).toBe('2026-07-13');
        expect(incrementalFromDate('2026-03-01', 1, TODAY)).toBe('2026-02-28');
    });

    it('tolerates a watermark carrying a time component', () => {
        expect(incrementalFromDate('2026-07-20T13:45:00.000Z', 7, TODAY)).toBe('2026-07-13');
    });

    /** A watermark ahead of the clock (skew, a hand-edited value) must not invert the window. */
    it('never lets from land past today', () => {
        expect(incrementalFromDate('2027-01-01', 0, TODAY)).toBe(TODAY);
    });

    it('falls back to the open-ended bound for a missing or unparseable watermark', () => {
        expect(incrementalFromDate(null, 7, TODAY)).toBe('2010-01-01');
        expect(incrementalFromDate('not-a-date', 7, TODAY)).toBe('2010-01-01');
    });
});

describe('fetch — through the real base fetch loop', () => {
    it('lands a record from a non-paginated door with no page params at all', async () => {
        c.Routes.set(USERS_URL, page([{ id: 1304, name: 'Ada', email: 'ada@example.com', role: 'admin' }]));

        const result = await c.FetchChanges(ctxFor('Users'));

        expect(c.RequestedURLs).toEqual([USERS_URL]);
        expect(result.Records).toHaveLength(1);
        expect(result.Records[0].Fields.id).toBe(1304);
    });

    it('stops after one short page, and asks for the next when the page came back full', async () => {
        c.Routes.set(PROJECTS_PAGE1, page([{ id: 'as:1' }]));
        const result = await c.FetchChanges(ctxFor('Projects', { BatchSize: 100 }));
        expect(c.RequestedURLs).toEqual([PROJECTS_PAGE1]);
        expect(result.Records.map(r => r.Fields.id)).toEqual(['as:1']);

        c = new TestEverhourConnector();
        c.Routes.set(PROJECTS_PAGE1, page(new Array(100).fill(0).map((_, i) => ({ id: `as:${i}` }))));
        const PROJECTS_PAGE2 = 'https://api.everhour.com/projects?page=2&limit=100';
        c.Routes.set(PROJECTS_PAGE2, page([{ id: 'as:last' }]));
        const walked = await c.FetchChanges(ctxFor('Projects', { BatchSize: 200 }));
        expect(c.RequestedURLs).toEqual([PROJECTS_PAGE1, PROJECTS_PAGE2]);
        expect(walked.Records).toHaveLength(101);
    });

    it('carries the id prefix through to the URL rather than percent-encoding it away', () => {
        // Drive the child door the way the engine does: substituted path, encoded colon and all.
        const url = c.callAppendParams('Tasks', '/projects/as%3A1234/tasks?page=1&limit=100', null);
        expect(restoreColons(`https://api.everhour.com${url}`))
            .toBe('https://api.everhour.com/projects/as:1234/tasks?page=1&limit=100');
    });

    it('surfaces a missing credential as an error rather than an empty success', async () => {
        c.TestApiKey = undefined;
        await expect(c.FetchChanges(ctxFor('Users'))).rejects.toThrow(/credential/i);
    });

    /** The stash is per-call state; leaking it would apply one object's window to the next. */
    it('clears the per-run watermark even when the fetch throws', async () => {
        c.TestApiKey = undefined;
        await expect(c.FetchChanges(ctxFor('TimeRecords'))).rejects.toThrow();
        expect(c.callAppendParams('TimeRecords', '/team/time', null)).toContain('from=2010-01-01');
    });
});

describe('record flattening', () => {
    it('projects billing, rate and budget onto their declared columns in vendor units', () => {
        const out = c.callTransform('Projects', {
            id: 'as:1',
            billing: { type: 'fixed_fee', fee: 1_000_000 },
            rate: { type: 'project_rate', rate: 12_500 },
            budget: {
                type: 'money', budget: 500_000, progress: 120_000,
                timeProgress: 100_000, expenseProgress: 20_000, period: 'general',
            },
        });
        expect(out.billing_type).toBe('fixed_fee');
        // Cents, NOT dollars — the legacy driver divided by 100 on the way into its own schema.
        expect(out.billing_fee).toBe(1_000_000);
        expect(out.rate_type).toBe('project_rate');
        expect(out.rate_rate).toBe(12_500);
        expect(out.budget_budget).toBe(500_000);
        expect(out.budget_time_progress).toBe(100_000);
        expect(out.budget_expense_progress).toBe(20_000);
        expect(out.budget_period).toBe('general');
    });

    it('projects estimate, time and the nested task reference', () => {
        const task = c.callTransform('Tasks', {
            id: 'ev:9',
            estimate: { total: 7200, type: 'overall' },
            time: { total: 3600, users: { '1304': 3600 } },
        });
        expect(task.estimate_total).toBe(7200);
        expect(task.estimate_type).toBe('overall');
        expect(task.time_total).toBe(3600);

        const time = c.callTransform('TimeRecords', {
            id: 2660155,
            task: { id: 'ev:9', name: 'Build the thing', projects: ['as:1'] },
        });
        expect(time.task_id).toBe('ev:9');
        expect(time.task_name).toBe('Build the thing');
    });

    it('lands null — not undefined — when Everhour explicitly nulls a sub-object', () => {
        const out = c.callTransform('Projects', { id: 'as:1', billing: null, budget: null });
        expect(out.billing_type).toBeNull();
        expect(out.billing_fee).toBeNull();
        expect(out.budget_budget).toBeNull();
    });

    it('lands null for a key the sub-object omits, rather than leaving the column unwritten', () => {
        // An hourly project has a billing.type but no billing.fee.
        const out = c.callTransform('Projects', { id: 'as:1', billing: { type: 'hourly' } });
        expect(out.billing_type).toBe('hourly');
        expect(out.billing_fee).toBeNull();
    });

    /**
     * Labels, assigned users and per-integration attributes/metrics are unbounded or defined per
     * workspace, so none can be a column in a fixed catalog.
     */
    it('serializes unbounded collections to JSON', () => {
        const out = c.callTransform('Tasks', {
            id: 'ev:9',
            labels: ['high', 'bug'],
            projects: ['as:1', 'as:2'],
            attributes: { Client: 'Everhour', Priority: 'high' },
            metrics: { efforts: 42 },
        });
        expect(JSON.parse(out.labels_json as string)).toEqual(['high', 'bug']);
        expect(JSON.parse(out.project_ids_json as string)).toEqual(['as:1', 'as:2']);
        expect(JSON.parse(out.attributes_json as string)).toEqual({ Client: 'Everhour', Priority: 'high' });
        expect(JSON.parse(out.metrics_json as string)).toEqual({ efforts: 42 });
    });

    /** "No labels" and "not returned" must read the same downstream, and "[]" is neither. */
    it('nulls an empty collection rather than storing "[]" or "{}"', () => {
        expect(serializeCollection([])).toBeNull();
        expect(serializeCollection({})).toBeNull();
        expect(serializeCollection(null)).toBeNull();
        expect(serializeCollection(undefined)).toBeNull();
        expect(c.callTransform('Tasks', { id: 'ev:9', labels: [] }).labels_json).toBeNull();
    });

    it('promotes the source-platform prefix to its own column', () => {
        expect(c.callTransform('Projects', { id: 'as:1234' }).platform).toBe('as');
        expect(c.callTransform('Projects', { id: 'ev:1234' }).platform).toBe('ev');
        // No prefix → the column is left unwritten rather than filled with a guess.
        expect(c.callTransform('TimeRecords', { id: 2660155 }).platform).toBeUndefined();
    });

    it('leaves every original key in place so full-record custom-column capture still sees them', () => {
        const out = c.callTransform('Projects', {
            id: 'as:1',
            billing: { type: 'hourly' },
            some_future_everhour_key: 'x',
        });
        expect(out.billing).toEqual({ type: 'hourly' });
        expect(out.some_future_everhour_key).toBe('x');
    });

    it('survives a record that omits every nested field', () => {
        expect(c.callTransform('Users', { id: 1304, name: 'Ada' })).toEqual({ id: 1304, name: 'Ada' });
    });
});

describe('watermark', () => {
    it('advances to the highest date actually observed', () => {
        expect(maxDate(
            [{ Fields: { date: '2026-03-01' } }, { Fields: { date: '2026-05-02' } }, { Fields: { date: '2026-04-01' } }],
            null
        )).toBe('2026-05-02');
    });

    /**
     * The lookback window guarantees every incremental batch contains records older than the
     * watermark. If those could move it, the window would walk backwards a week per run forever.
     */
    it('never moves backwards, which the lookback window makes a certainty rather than an edge case', () => {
        expect(maxDate([{ Fields: { date: '2026-01-01' } }], '2026-05-01')).toBeNull();
    });

    it('reports no movement for a batch with no dates at all', () => {
        expect(maxDate([{ Fields: { id: 1 } }], null)).toBeNull();
        expect(maxDate([], '2026-05-01')).toBeNull();
    });

    it('emits NewWatermarkValue only when the batch actually moved it', async () => {
        // limit=100, not the declared 1000: the base narrows the page size to the batch's remaining
        // capacity (BatchSize 100 here), and the clamp in BuildPaginatedURL only ever lowers it.
        const first = `https://api.everhour.com/team/time?page=1&limit=100&from=2010-01-01&to=${TODAY}`;
        c.Routes.set(first, page([{ id: 1, date: '2026-06-01' }]));
        expect((await c.FetchChanges(ctxFor('TimeRecords'))).NewWatermarkValue).toBe('2026-06-01');

        c = new TestEverhourConnector();
        const resumed = `https://api.everhour.com/team/time?page=1&limit=100&from=2026-05-25&to=${TODAY}`;
        c.Routes.set(resumed, page([{ id: 1, date: '2026-05-30' }]));
        const unmoved = await c.FetchChanges(ctxFor('TimeRecords', { WatermarkValue: '2026-06-01' }));
        expect(unmoved.NewWatermarkValue).toBeUndefined();
    });
});

describe('connection test', () => {
    const ME_URL = 'https://api.everhour.com/users/me';

    it('succeeds when the key resolves, and reports the pinned API version', async () => {
        c.Routes.set(ME_URL, {
            Status: 200,
            Body: { id: 1304, name: 'Ada', email: 'ada@example.com' },
            Headers: { 'content-type': 'application/json' },
        });
        const result = await c.TestConnection({} as MJCompanyIntegrationEntity, {} as UserInfo);
        expect(result.Success).toBe(true);
        expect(result.Message).toContain('Ada');
        expect(result.ServerVersion).toBe('1.2');
    });

    it('reports a rejected key distinctly from any other failure', async () => {
        c.Routes.set(ME_URL, { Status: 401, Body: {}, Headers: {} });
        const result = await c.TestConnection({} as MJCompanyIntegrationEntity, {} as UserInfo);
        expect(result.Success).toBe(false);
        expect(result.Message).toContain('401');
    });

    it('reports a non-401 failure with its status rather than as a credential problem', async () => {
        c.Routes.set(ME_URL, { Status: 503, Body: {}, Headers: {} });
        const result = await c.TestConnection({} as MJCompanyIntegrationEntity, {} as UserInfo);
        expect(result.Success).toBe(false);
        expect(result.Message).toContain('503');
    });

    it('returns a failure result rather than throwing when the credential is missing', async () => {
        c.TestApiKey = undefined;
        const result = await c.TestConnection({} as MJCompanyIntegrationEntity, {} as UserInfo);
        expect(result.Success).toBe(false);
        expect(result.Message).toMatch(/credential/i);
    });
});

/**
 * These assert the SHIPPED catalog, because a templated door whose parent is undeclared fetches zero
 * rows and still reports success — the silent-empty class that shipped 21 dead PheedLoop objects.
 */
describe('shipped catalog', () => {
    const names = new Set(OBJECTS.map(o => o.fields.Name as string));

    it('declares the four Everhour surfaces', () => {
        expect([...names].sort()).toEqual(['Projects', 'Tasks', 'TimeRecords', 'Users']);
    });

    it('declares Tasks as a child of Projects stamped onto project_id', () => {
        const cfg = JSON.parse(objectMetadata('Tasks').fields.Configuration as string);
        expect(cfg.parentObjectName).toBe('Projects');
        expect(cfg.parentObjectIDFieldName).toBe('project_id');
        // The declared parent must be a real sibling, or the engine warns PARENT_UNRESOLVED and the
        // object fetches nothing.
        expect(names.has(cfg.parentObjectName as string)).toBe(true);
        // The stamped FK must be a declared column, or the engine writes the parent id nowhere.
        expect(ioFields('Tasks').some(f => f.Name === 'project_id')).toBe(true);
    });

    /**
     * The legacy driver read time per project. Everhour's team-wide door returns the same records
     * without an N+1 over the project list, which at ~20 requests / 10 seconds is the dominant cost of
     * a run — so TimeRecords must NOT acquire a parent.
     */
    it('keeps TimeRecords on the team-wide door with no parent', () => {
        const cfg = JSON.parse(objectMetadata('TimeRecords').fields.Configuration as string);
        expect(cfg.parentObjectName).toBeUndefined();
        expect(objectMetadata('TimeRecords').fields.APIPath).toBe('/team/time');
    });

    it('declares a parent exactly where the path actually has a template var', () => {
        for (const o of OBJECTS) {
            const path = o.fields.APIPath as string;
            const cfg = JSON.parse(o.fields.Configuration as string);
            expect(path.includes('{'), `${o.fields.Name as string} path vs parent declaration`)
                .toBe(cfg.parentObjectName !== undefined);
        }
    });

    it('mirrors APIPath into Configuration.apiPath, which is what the parent validator reads', () => {
        for (const o of OBJECTS) {
            expect(JSON.parse(o.fields.Configuration as string).apiPath).toBe(o.fields.APIPath);
        }
    });

    it('gives every object exactly one primary key, named id', () => {
        for (const o of OBJECTS) {
            const pks = o.relatedEntities['MJ: Integration Object Fields'].filter(f => f.fields.IsPrimaryKey);
            expect(pks.map(p => p.fields.Name)).toEqual(['id']);
        }
    });

    /** Everhour sends bare arrays; a stray data key would unwrap nothing and land zero records. */
    it('declares no response envelope key on any object', () => {
        for (const o of OBJECTS) expect(o.fields.ResponseDataKey).toBe('');
    });

    /**
     * Every declared column must be something the connector can actually produce: a key Everhour
     * returns at the top level, a flattened projection of a nested one, or a value the engine stamps.
     * A column with none of those behind it lands null on every record while the run reports success.
     */
    it('backs every declared column with a vendor key, a flattening rule, or an engine stamp', () => {
        const derived = new Set([
            'platform',
            'billing_type', 'billing_fee', 'rate_type', 'rate_rate',
            'budget_type', 'budget_budget', 'budget_period', 'budget_progress',
            'budget_time_progress', 'budget_expense_progress', 'budget_applied_from',
            'budget_threshold', 'budget_disallow_overbudget',
            'budget_exclude_unbillable_time', 'budget_exclude_expenses',
            'estimate_total', 'estimate_type', 'time_total',
            'task_id', 'task_name',
            'users_json', 'project_ids_json', 'labels_json',
            'attributes_json', 'metrics_json', 'history_json',
        ]);
        const stamped = new Set(['project_id']);
        // Top-level keys Everhour documents on each resource.
        const vendorKeys: Record<string, Set<string>> = {
            Users: new Set(['id', 'name', 'email', 'headline', 'avatarUrl', 'role', 'status']),
            Projects: new Set(['id', 'name', 'workspaceId', 'workspaceName', 'client', 'type', 'favorite']),
            Tasks: new Set(['id', 'name', 'description', 'section', 'position', 'dueAt', 'status', 'unbillable']),
            TimeRecords: new Set(['id', 'time', 'user', 'date', 'comment', 'isLocked', 'isInvoiced']),
        };

        for (const o of OBJECTS) {
            const name = o.fields.Name as string;
            for (const f of o.relatedEntities['MJ: Integration Object Fields']) {
                const column = f.fields.Name as string;
                const backed = vendorKeys[name].has(column) || derived.has(column) || stamped.has(column);
                expect(backed, `${name}.${column} has nothing behind it`).toBe(true);
            }
        }
    });

    it('names date as the watermark field on the one incremental object', () => {
        const incremental = OBJECTS.filter(o => o.fields.SupportsIncrementalSync);
        expect(incremental.map(o => o.fields.Name)).toEqual(['TimeRecords']);
        expect(incremental[0].fields.IncrementalWatermarkField).toBe('date');
        expect(ioFields('TimeRecords').some(f => f.Name === 'date')).toBe(true);
    });

    it('declares a page size no larger than the connector will ever request', () => {
        const caps: Record<string, number> = { Projects: 100, Tasks: 250, TimeRecords: 1000 };
        for (const o of OBJECTS) {
            const cap = caps[o.fields.Name as string];
            if (cap === undefined) continue;
            expect(o.fields.DefaultPageSize as number).toBeLessThanOrEqual(cap);
        }
    });

    it('ships read-only — no object claims a write capability', () => {
        for (const o of OBJECTS) expect(o.fields.SupportsWrite).toBe(false);
    });
});
