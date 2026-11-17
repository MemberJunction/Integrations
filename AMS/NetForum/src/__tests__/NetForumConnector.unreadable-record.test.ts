/**
 * One record xWeb cannot write as XML (a control character in one of its values) faults every GetQuery page that
 * holds it: "' ', hexadecimal value 0x02, is an invalid character." The fault is about that record's data, not about
 * the column list, and the page holding it is the same on every read.
 */
import { describe, expect, it } from 'vitest';
import type { FetchBatchResult, FetchContext, RESTResponse } from '@memberjunction/integration-engine';
import type { NetForumConnector } from '../NetForumConnector.js';
import { fault, internals, isolateConnectorState, makeConnector, objOf, type SentCall, type World } from './netforum-fake-xweb.js';

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

const rowsOf = (cols: string[], keys: string[]): RESTResponse => ({
    Status: 200,
    Headers: {},
    Body: `<?xml version="1.0"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body>` +
        `<GetQueryResponse><GetQueryResult><Results>` +
        keys.map(k => `<Result>${cols.map(c => `<${c}>${c === 'ind_cst_key' ? k : `${c}-${k}`}</${c}>`).join('')}</Result>`).join('') +
        `</Results></GetQueryResult></GetQueryResponse></soap:Body></soap:Envelope>`,
});

/** A fake xWeb over KEYS: honours `@TOP n` and `<key> > '<k>'`, and faults any page that names a data column and holds BAD. */
function connectorWithBadRecord(root: string): NetForumConnector {
    const calls: SentCall[] = [];
    const c = makeConnector(world, root, calls);
    internals(c).SendGetQuery = async (_url: string, args: Record<string, string>) => {
        const top = Number(/@TOP\s+(\d+)/i.exec(args.szObjectName)?.[1] ?? KEYS.length);
        const after = /ind_cst_key > '([^']*)'/.exec(args.szWhereClause ?? '')?.[1];
        const page = KEYS.filter(k => after === undefined || k > after).slice(0, top);
        const cols = (args.szColumnList ?? '').split(',').map(s => s.trim().split('.').pop()!.toLowerCase()).filter(Boolean);
        const keyOnly = cols.every(col => col === 'ind_cst_key');
        if (!keyOnly && page.includes(BAD)) return fault(INVALID_CHARACTER);
        return rowsOf(cols, page);
    };
    return c;
}

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
