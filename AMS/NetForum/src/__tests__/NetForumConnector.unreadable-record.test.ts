/**
 * One record xWeb cannot write as XML (a control character in one of its values) faults every GetQuery page that
 * holds it: "' ', hexadecimal value 0x02, is an invalid character." The fault is about that record's data, not about
 * the column list, and the page holding it is the same on every read.
 */
import { afterEach, describe, expect, it, vi } from 'vitest';
import type { FetchBatchResult, FetchContext, RESTResponse } from '@memberjunction/integration-engine';
import { NetForumConnector } from '../NetForumConnector.js';
import { fault, internals, isolateConnectorState, makeConnector, objOf, statics, type World } from './netforum-fake-xweb.js';

const { freshRoot } = isolateConnectorState();

const KEYS = ['k01', 'k02', 'k03', 'k04', 'k05', 'k06', 'k07', 'k08', 'k09', 'k10', 'k11'];
const BAD = 'k05';
const INVALID_CHARACTER = "Server was unable to process request. ---> ' ', hexadecimal value 0x02, is an invalid character. Line 21, position 60.";

const world: World = {
    Individual: {
        def: { KeyColumn: 'ind_cst_key', Columns: [['co_individual', 'ind_cst_key'], ['co_individual', 'ind_first_name'], ['co_customer', 'cst_recno']] },
        pk: 'ind_cst_key',
    },
};

/** A GetQuery answer with one <Result> per row id (`<key>#<n>`), each column's value derived from the row id. */
const rowsOf = (cols: string[], rowIds: string[]): RESTResponse => ({
    Status: 200,
    Headers: {},
    Body: `<?xml version="1.0"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body>` +
        `<GetQueryResponse><GetQueryResult><Results>` +
        rowIds.map(id => `<Result>${cols.map(c => `<${c}>${c === 'ind_cst_key' ? id.split('#')[0] : `${c}-${id}`}</${c}>`).join('')}</Result>`).join('') +
        `</Results></GetQueryResult></GetQueryResponse></soap:Body></soap:Envelope>`,
});

/** One GetQuery the fake xWeb answered. */
interface Sent {
    top: number;
    /** The key of each row the request covered, in order. */
    page: string[];
    faulted: boolean;
    /** The WHERE clause narrowed the request to one key. */
    narrowed: boolean;
}

/**
 * A fake xWeb over `keys`: honours `@TOP n` (rows), `<key> > '<k>'` and `<key> = '<k>'`. Like xWeb, it joins only the
 * tables a list names: a list that names a co_customer column gets `rowsPerKey[k]` rows for key k (a one-to-many join),
 * any other list one row per key. A request that names a data column faults when its rows include a row in `bad`: a
 * key (any of its rows) or one row of it (`<key>#<n>`).
 */
function connectorWithBadRecords(root: string, keys: string[], bad: string[], sent: Sent[] = [], rowsPerKey: Record<string, number> = {}): NetForumConnector {
    const c = makeConnector(world, root, []);
    internals(c).SendGetQuery = async (_url: string, args: Record<string, string>) => {
        const top = Number(/@TOP\s+(\d+)/i.exec(args.szObjectName)?.[1] ?? Number.MAX_SAFE_INTEGER);
        const where = args.szWhereClause ?? '';
        const after = [...where.matchAll(/ind_cst_key > '([^']*)'/g)].map(m => m[1]);
        const equal = /ind_cst_key = '([^']*)'/.exec(where)?.[1];
        const cols = (args.szColumnList ?? '').split(',').map(s => s.trim().split('.').pop()!.toLowerCase()).filter(Boolean);
        const joined = cols.includes('cst_recno');
        const rowIds = keys
            .filter(k => after.every(a => k > a) && (equal === undefined || k === equal))
            .flatMap(k => Array.from({ length: joined ? rowsPerKey[k] ?? 1 : 1 }, (_, i) => `${k}#${i + 1}`))
            .slice(0, top);
        const keyOnly = cols.every(col => col === 'ind_cst_key');
        const faulted = !keyOnly && rowIds.some(id => bad.includes(id) || bad.includes(id.split('#')[0]));
        sent.push({ top, page: rowIds.map(id => id.split('#')[0]), faulted, narrowed: equal !== undefined });
        return faulted ? fault(INVALID_CHARACTER) : rowsOf(cols, rowIds);
    };
    return c;
}

const connectorWithBadRecord = (root: string): NetForumConnector => connectorWithBadRecords(root, KEYS, [BAD]);

const ctx = (BatchSize: number, AfterKeyValue: string | null = null): FetchContext => ({
    CompanyIntegration: { ID: 'CI1', IntegrationID: 'I1' },
    ContextUser: {},
    ObjectName: 'Individual',
    BatchSize,
    WatermarkValue: null,
    AfterKeyValue,
}) as unknown as FetchContext;

/** Calls FetchChanges the way the engine pages: from each batch's NextAfterKeyValue until HasMore is false or a call throws. */
async function readAll(c: NetForumConnector, batchSize: number): Promise<{ keys: string[]; batches: FetchBatchResult[]; error: string | null }> {
    const keys: string[] = [];
    const batches: FetchBatchResult[] = [];
    let after: string | null = null;
    for (let i = 0; i < 50; i++) {
        let r: FetchBatchResult;
        try {
            r = await c.FetchChanges(ctx(batchSize, after));
        } catch (e) {
            return { keys, batches, error: e instanceof Error ? e.message : String(e) };
        }
        batches.push(r);
        for (const rec of r.Records) if (!keys.includes(rec.ExternalID)) keys.push(rec.ExternalID);
        if (!r.HasMore) return { keys, batches, error: null };
        after = r.NextAfterKeyValue ?? after;
    }
    throw new Error('read did not end');
}

describe('NetForum: a record xWeb cannot write as XML', () => {
    it('does not mark the object\'s column list unsendable', async () => {
        const root = freshRoot();
        await connectorWithBadRecord(root).FetchChanges(ctx(6)).catch(() => undefined);
        expect(objOf(root, 'Individual').unsendable).toBeUndefined();
    });

    it('returns the rows before the unreadable record and resumes after it', async () => {
        const r = await connectorWithBadRecord(freshRoot()).FetchChanges(ctx(6));
        expect(r.Records.map(x => x.ExternalID)).toEqual(['k01', 'k02', 'k03', 'k04']);
        expect(r.HasMore).toBe(true);
        expect(r.NextAfterKeyValue).toBe(BAD);
        const w = (r.Warnings ?? []).find(x => x.Code === 'RECORD_UNREADABLE');
        expect(w?.Message).toContain(BAD);
    });

    it('reads every other record, then ends with an error that names the skipped record on every later call', async () => {
        const c = connectorWithBadRecord(freshRoot());
        const read = await readAll(c, 4);
        expect(read.keys).toEqual(KEYS.filter(k => k !== BAD));
        expect(read.error).toContain(BAD);
        // The engine may retry a failed fetch: the read must not then look complete.
        await expect(c.FetchChanges(ctx(4, 'k11'))).rejects.toThrow(BAD);
    });
});

describe('NetForum: the xWeb faults a record that cannot be written as XML costs', () => {
    afterEach(() => vi.unstubAllGlobals());

    it('sends a request that draws this fault once, not again', async () => {
        const c = new NetForumConnector();
        (c as unknown as { Sleep: (ms: number) => Promise<void> }).Sleep = async () => undefined;
        const fetchMock = vi.fn(async () => new Response(String(fault(INVALID_CHARACTER).Body), { status: 500 }));
        vi.stubGlobal('fetch', fetchMock);
        const r = await internals(c).SendGetQuery('https://xweb.invalid/x', { szObjectName: 'Individual @TOP 6', szColumnList: 'ind_cst_key, ind_first_name' }, 't');
        expect(r.Status).toBe(500);
        expect(fetchMock).toHaveBeenCalledTimes(1);
    });

    it('does not search for a record past the per-read limit', async () => {
        const keys = Array.from({ length: 20 }, (_, i) => `k${String(i + 1).padStart(2, '0')}`);
        const sent: Sent[] = [];
        const read = await readAll(connectorWithBadRecords(freshRoot(), keys, ['k02', 'k04', 'k06', 'k08', 'k10', 'k12'], sent), 4);
        expect(read.error).toContain('k10');
        expect(read.error).not.toContain('k12');
        // A search for the sixth record would send requests smaller than a page, starting after the fifth.
        expect(sent.filter(s => s.top < 4 && s.page[0] === 'k11')).toHaveLength(0);
    });

    it('spends at most the daily fault budget on the search, also in the next connector', async () => {
        statics().PROBE_FAULTS_PER_DAY = { ...statics().PROBE_FAULTS_PER_DAY, unreadable: 3 };
        const root = freshRoot();
        const searchFaults = (sent: Sent[]): number => sent.filter(s => s.faulted && (s.top < 8 || s.narrowed)).length;
        const first: Sent[] = [];
        const read = await readAll(connectorWithBadRecords(root, KEYS, ['k05', 'k07'], first), 8);
        expect(searchFaults(first)).toBe(3);
        expect(read.error).toMatch(/budget/i);
        expect(read.error).toContain('k05');

        const again: Sent[] = [];
        const reread = await readAll(connectorWithBadRecords(root, KEYS, ['k05', 'k07'], again), 8);
        expect(searchFaults(again)).toBe(0);
        expect(reread.error).toMatch(/budget/i);
    });
});

describe('NetForum: a record xWeb cannot write as XML that spans several rows of the list', () => {
    const distinct = (r: FetchBatchResult): string[] => [...new Set(r.Records.map(x => x.ExternalID))];

    it('skips the record when the bad value is on a later row of it', async () => {
        const c = connectorWithBadRecords(freshRoot(), KEYS, ['k05#2'], [], { k03: 2, k05: 2 });
        const r = await c.FetchChanges(ctx(8));
        expect(distinct(r)).toEqual(['k01', 'k02', 'k03', 'k04']);
        expect(r.HasMore).toBe(true);
        expect(r.NextAfterKeyValue).toBe('k05');
        expect((r.Warnings ?? []).find(x => x.Code === 'RECORD_UNREADABLE')?.Message).toContain('k05');
    });

    it('skips the record when the bad value is on its first row', async () => {
        const c = connectorWithBadRecords(freshRoot(), KEYS, ['k05#1'], [], { k03: 2, k05: 2 });
        const r = await c.FetchChanges(ctx(8));
        expect(distinct(r)).toEqual(['k01', 'k02', 'k03', 'k04']);
        expect(r.NextAfterKeyValue).toBe('k05');
    });
});
