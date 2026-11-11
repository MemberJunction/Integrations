import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { BaseRESTIntegrationConnector } from '@memberjunction/integration-engine';
import { RasaConnector } from './RasaConnector';

/**
 * Parent-scoped objects are read one bounded batch per call, and resume from `NextCursor`.
 *
 * The base's per-parent loop read every page of up to 10 parents in one call. On a production install (MJ 6.1.6,
 * 2026-11-06) four newsletters' 162k action events came back as one batch and the sync failed with
 * "Maximum call stack size exceeded", with no watermark saved. These tests drive the connector the
 * way the engine does (call, then call again with the returned cursor) against a fake rasa.io.
 */

const DAY_MS = 86_400_000;
const NOW = Date.parse('2026-11-10T12:00:00Z');

type FakeObject = {
    ID: string;
    Name: string;
    APIPath: string;
    ResponseDataKey: string | null;
    Configuration: string;
    IncrementalWatermarkField: string | null;
    SupportsIncrementalSync: boolean;
    SupportsPagination: boolean;
    PaginationType: string;
    DefaultPageSize: number;
};

const newsletterAction: FakeObject = {
    ID: 'obj-na',
    Name: 'Newsletter Action',
    APIPath: '/v2/insights/newsletter/{id}/actions',
    ResponseDataKey: 'results',
    Configuration: JSON.stringify({
        parentObjectName: 'Newsletter',
        parentObjectIDFieldName: 'newsletter_id',
        watermarkParam: 'created_since',
        maxLookbackDays: 725,
    }),
    IncrementalWatermarkField: 'created',
    SupportsIncrementalSync: true,
    SupportsPagination: true,
    PaginationType: 'Offset',
    DefaultPageSize: 3,
};

const newsletterContact: FakeObject = {
    ...newsletterAction,
    ID: 'obj-nc',
    Name: 'Newsletter Contact',
    APIPath: '/v2/messaging/newsletter/{id}/contacts',
    Configuration: JSON.stringify({ parentObjectName: 'Newsletter', parentObjectIDFieldName: 'newsletter_id', watermarkParam: null }),
    IncrementalWatermarkField: null,
    SupportsIncrementalSync: false,
};

const keyFields = [
    { Name: 'newsletter_id', IsPrimaryKey: true, Sequence: 1 },
    { Name: 'id', IsPrimaryKey: true, Sequence: 2 },
];

type Event = { id: string; created: string };

/** A fake rasa.io: per-parent event lists, paged by skip/limit, filtered by created_since/created_before. */
function fakeServer(events: Record<string, Event[]>, contacts: Record<string, Array<{ id: string }>> = {}) {
    const requests: string[] = [];
    const handler = async (_auth: unknown, url: string) => {
        requests.push(url);
        const u = new URL(url);
        const actions = u.pathname.match(/^\/v2\/insights\/newsletter\/([^/]+)\/actions$/);
        const members = u.pathname.match(/^\/v2\/messaging\/newsletter\/([^/]+)\/contacts$/);
        let rows: Array<Record<string, unknown>>;
        if (actions) {
            const since = u.searchParams.get('created_since');
            const before = u.searchParams.get('created_before');
            rows = (events[decodeURIComponent(actions[1])] ?? []).filter(e =>
                (!since || Date.parse(e.created) >= Date.parse(since)) && (!before || Date.parse(e.created) < Date.parse(before)));
        } else if (members) {
            rows = contacts[decodeURIComponent(members[1])] ?? [];
        } else {
            return { Status: 404, Body: { metadata: { errors: 'not found' } }, Headers: {} };
        }
        const skip = Number(u.searchParams.get('skip') ?? 0);
        const limit = Number(u.searchParams.get('limit') ?? 50);
        const page = rows.slice(skip, skip + limit);
        const next = new URL(url);
        next.searchParams.set('skip', String(skip + limit));
        return { Status: 200, Body: { results: page, metadata: { record_count: page.length, next_link: next.toString() } }, Headers: {} };
    };
    return { requests, handler };
}

type Batch = {
    Records: Array<{ ExternalID: string; Fields: Record<string, unknown> }>;
    HasMore: boolean;
    NextPage?: number;
    NextOffset?: number;
    NextCursor?: string;
    NewWatermarkValue?: string;
    SourceTotalRecords?: number;
};

function connectorFor(obj: FakeObject, server: ReturnType<typeof fakeServer>, parents: string[]) {
    const connector = new RasaConnector();
    const c = connector as unknown as Record<string, unknown>;
    c.Authenticate = async () => ({ Token: 't', Config: { ClientId: 'id', ClientSecret: 'secret' } });
    c.MakeHTTPRequest = server.handler;
    c.ReadConnectionParentIDs = async () => [...parents].sort();
    vi.spyOn(BaseRESTIntegrationConnector.prototype as never, 'GetCachedObject').mockImplementation((() => obj) as never);
    vi.spyOn(BaseRESTIntegrationConnector.prototype as never, 'GetCachedFields').mockImplementation((() => keyFields) as never);
    return connector;
}

/** Calls FetchChanges the way the engine does until HasMore is false. */
async function drain(connector: RasaConnector, obj: FakeObject, opts: { batchSize: number; watermark?: string | null; configuration?: string }) {
    const batches: Batch[] = [];
    let position: { CurrentPage?: number; CurrentOffset?: number; CurrentCursor?: string } = {};
    for (let i = 0; i < 500; i++) {
        const batch = (await connector.FetchChanges({
            CompanyIntegration: { ID: 'ci-1', IntegrationID: 'int-1', Configuration: opts.configuration ?? null },
            ObjectName: obj.Name,
            WatermarkValue: opts.watermark ?? null,
            BatchSize: opts.batchSize,
            ContextUser: {},
            ...position,
            AfterKeyValue: null,
        } as never)) as unknown as Batch;
        batches.push(batch);
        if (!batch.HasMore) return batches;
        position = { CurrentPage: batch.NextPage, CurrentOffset: batch.NextOffset, CurrentCursor: batch.NextCursor };
    }
    throw new Error('fetch never finished');
}

function eventsOver(parent: string, count: number, firstDay: number, everyDays: number): Event[] {
    return Array.from({ length: count }, (_, i) => ({
        id: `${parent}-e${i}`,
        created: new Date(NOW - (firstDay - i * everyDays) * DAY_MS).toISOString(),
    }));
}

describe('parent-scoped fetch', () => {
    beforeEach(() => vi.useFakeTimers({ now: NOW, toFake: ['Date'] }));
    afterEach(() => {
        vi.useRealTimers();
        vi.restoreAllMocks();
    });

    it('returns every record once, in batches no larger than BatchSize, keyed with the parent id', async () => {
        const server = fakeServer({}, {
            n1: Array.from({ length: 7 }, (_, i) => ({ id: `c${i}` })),
            n2: [],
            n3: Array.from({ length: 4 }, (_, i) => ({ id: `d${i}` })),
        });
        const connector = connectorFor(newsletterContact, server, ['n1', 'n2', 'n3']);
        const batches = await drain(connector, newsletterContact, { batchSize: 5 });

        const ids = batches.flatMap(b => b.Records.map(r => r.ExternalID));
        expect(ids).toHaveLength(11);
        expect(new Set(ids).size).toBe(11);
        expect(ids).toContain('n1|c6');
        expect(ids).toContain('n3|d0');
        expect(batches.every(b => b.Records.length <= 5)).toBe(true);
        expect(batches.flatMap(b => b.Records).every(r => typeof r.Fields.newsletter_id === 'string')).toBe(true);
        // One parent's total is not the object's.
        expect(batches.every(b => b.SourceTotalRecords === undefined)).toBe(true);
    });

    it('resumes mid-parent from the cursor instead of re-reading the parent', async () => {
        const server = fakeServer({}, { n1: Array.from({ length: 10 }, (_, i) => ({ id: `c${i}` })) });
        const connector = connectorFor(newsletterContact, server, ['n1']);
        const batches = await drain(connector, newsletterContact, { batchSize: 4 });

        expect(batches.map(b => b.Records.length)).toEqual([4, 4, 2]);
        const skips = server.requests.map(r => new URL(r).searchParams.get('skip') ?? '0');
        expect(new Set(skips).size).toBe(skips.length);
    });

    it('reads a windowed feed window by window across parents, oldest first, and reports finished windows as a safe watermark', async () => {
        // 60 days of daily events per newsletter, a 30-day window, and a 100-day lookback.
        const server = fakeServer({ n1: eventsOver('n1', 60, 59, 1), n2: eventsOver('n2', 60, 59, 1) });
        const connector = connectorFor(newsletterAction, server, ['n1', 'n2']);
        const batches = await drain(connector, newsletterAction, {
            batchSize: 10,
            configuration: JSON.stringify({ maxLookbackDays: 100, historyWindowDays: 30 }),
        });

        const ids = batches.flatMap(b => b.Records.map(r => r.ExternalID));
        expect(ids).toHaveLength(120);
        expect(new Set(ids).size).toBe(120);

        // The connection's 100 days replaced the object's 725: the first window starts 100 days back.
        const sinces = server.requests.map(r => new URL(r).searchParams.get('created_since'));
        expect(Date.parse(sinces[0]!)).toBeGreaterThan(NOW - 101 * DAY_MS);
        expect(Date.parse(sinces[0]!)).toBeLessThanOrEqual(NOW - 99 * DAY_MS);

        // Every request but those of the last window carries a 30-day upper bound; the last is open.
        for (const url of server.requests) {
            const p = new URL(url).searchParams;
            const before = p.get('created_before');
            if (before) expect(Date.parse(before) - Date.parse(p.get('created_since')!)).toBe(30 * DAY_MS);
        }
        expect(new URL(server.requests.at(-1)!).searchParams.get('created_before')).toBeNull();

        // Safe watermarks only ever move forward, and each is a window start.
        const marks = batches.slice(0, -1).map(b => b.NewWatermarkValue).filter((m): m is string => !!m);
        expect(marks.length).toBeGreaterThan(0);
        expect([...marks].sort()).toEqual(marks);
        for (const m of marks) expect(sinces).toContain(m);
        // The final watermark is the newest event seen.
        expect(batches.at(-1)!.NewWatermarkValue).toBe(eventsOver('n1', 60, 59, 1).at(-1)!.created);
    });

    it('never reports a watermark past an event it has not returned', async () => {
        const server = fakeServer({ n1: eventsOver('n1', 40, 80, 2), n2: eventsOver('n2', 40, 80, 2) });
        const connector = connectorFor(newsletterAction, server, ['n1', 'n2']);
        const batches = await drain(connector, newsletterAction, {
            batchSize: 7,
            configuration: JSON.stringify({ maxLookbackDays: 100, historyWindowDays: 20 }),
        });

        const returned: number[] = [];
        for (const batch of batches.slice(0, -1)) {
            for (const r of batch.Records) returned.push(Date.parse(String(r.Fields.created)));
            if (!batch.NewWatermarkValue) continue;
            const mark = Date.parse(batch.NewWatermarkValue);
            const all = [...eventsOver('n1', 40, 80, 2), ...eventsOver('n2', 40, 80, 2)];
            const unreturnedBefore = all.filter(e => Date.parse(e.created) < mark).length
                - returned.filter(t => t < mark).length;
            expect(unreturnedBefore).toBe(0);
        }
    });

    it('caps the requests one call makes when parents are empty', async () => {
        const parents = Array.from({ length: 25 }, (_, i) => `n${String(i).padStart(2, '0')}`);
        const server = fakeServer({}, {});
        const connector = connectorFor(newsletterContact, server, parents);
        const batches = await drain(connector, newsletterContact, { batchSize: 200 });

        expect(batches.length).toBe(3);
        expect(server.requests).toHaveLength(25);
    });

    it('reports no parents instead of reading anything', async () => {
        const server = fakeServer({}, {});
        const connector = connectorFor(newsletterContact, server, []);
        const [batch] = await drain(connector, newsletterContact, { batchSize: 50 });

        expect(batch.HasMore).toBe(false);
        expect(server.requests).toHaveLength(0);
        expect((batch as unknown as { Warnings: Array<{ Code: string }> }).Warnings[0].Code).toBe('ZERO_PARENTS');
    });

    it('keeps paging a flat object when the batch is smaller than a page', async () => {
        // The base asks for only what fits the batch; a full answer to that smaller request is not the end.
        const flat: FakeObject = { ...newsletterContact, APIPath: '/v2/messaging/newsletter/n1/contacts', Configuration: '{}', DefaultPageSize: 500 };
        const server = fakeServer({}, { n1: Array.from({ length: 450 }, (_, i) => ({ id: `c${i}`, newsletter_id: 'n1' })) });
        const connector = connectorFor(flat, server, []);
        const batches = await drain(connector, flat, { batchSize: 200 });

        expect(batches.map(b => b.Records.length)).toEqual([200, 200, 50]);
    });

    it('reads the next parent from its start when the cursor names a parent that is gone', async () => {
        const data = {
            n1: Array.from({ length: 5 }, (_, i) => ({ id: `c${i}` })),
            n2: Array.from({ length: 5 }, (_, i) => ({ id: `d${i}` })),
        };
        const first = (await drain(connectorFor(newsletterContact, fakeServer({}, data), ['n1']), newsletterContact, { batchSize: 3 }))[0];
        expect(first.HasMore).toBe(true);

        const connector = connectorFor(newsletterContact, fakeServer({}, data), ['n2']);
        const batch = (await connector.FetchChanges({
            CompanyIntegration: { ID: 'ci-1', IntegrationID: 'int-1', Configuration: null },
            ObjectName: newsletterContact.Name,
            WatermarkValue: null,
            BatchSize: 50,
            ContextUser: {},
            CurrentCursor: first.NextCursor,
            AfterKeyValue: null,
        } as never)) as unknown as Batch;

        expect(batch.Records.map(r => r.ExternalID)).toEqual(['n2|d0', 'n2|d1', 'n2|d2', 'n2|d3', 'n2|d4']);
    });

    it('starts over when handed a cursor it did not write', async () => {
        const server = fakeServer({}, { n1: [{ id: 'c0' }, { id: 'c1' }] });
        const connector = connectorFor(newsletterContact, server, ['n1']);
        const batch = (await connector.FetchChanges({
            CompanyIntegration: { ID: 'ci-1', IntegrationID: 'int-1', Configuration: null },
            ObjectName: newsletterContact.Name,
            WatermarkValue: null,
            BatchSize: 50,
            ContextUser: {},
            CurrentCursor: 'opaque-token',
            AfterKeyValue: null,
        } as never)) as unknown as Batch;

        expect(batch.Records.map(r => r.ExternalID)).toEqual(['n1|c0', 'n1|c1']);
    });
});
