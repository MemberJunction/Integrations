import { describe, it, expect, vi, afterEach } from 'vitest';
import type { MJCompanyIntegrationEntity } from '@memberjunction/core-entities';
import type { UserInfo } from '@memberjunction/core';
import type { ConnectionTestResult } from '@memberjunction/integration-engine';
import { NetForumConnector } from '../NetForumConnector.js';
import {
    type SentCall, type World,
    errorOf, fetchObject, isolateConnectorState, makeConnector, objOf,
} from './netforum-fake-xweb.js';

/**
 * Two live-tenant defects (2026-10-16), neither of which any configuration could fix:
 *
 *  1. The per-request HTTP timeout was a hard-coded 30 s. An object whose list query takes longer on xWeb's side
 *     (ViewPricingControl: a view over a dozen tables, ordered by a computed key) timed out on EVERY run, and raising
 *     the engine's `fetchTimeoutMs` changed nothing because the connector aborted its own request at 30 s first.
 *  2. SQL Server's "Ambiguous column name 'x'" taught the fault-learning loop nothing, so the list was marked
 *     unsendable (ChapterPhone: both its full and its own-table list ended refused). The fault names the column: a
 *     bare reference can be qualified from the definition, and a bare KEY is the duplicate of the copy xWeb prepends
 *     to every query, so it can simply be left out.
 */
describe('NetForumConnector — Configuration.requestTimeoutMs', () => {
    const ci = (extra: Record<string, unknown>): MJCompanyIntegrationEntity => ({
        ID: 'CI1', IntegrationID: 'I1', CredentialID: null,
        Configuration: JSON.stringify({ BaseURL: 'https://xweb.invalid', Username: 'u', Password: 'p', ...extra }),
    }) as unknown as MJCompanyIntegrationEntity;

    /** A fetch that never answers; it rejects with an AbortError when the connector's timer aborts it. */
    const hangingFetch = () => vi.fn((_url: string, init: RequestInit) => new Promise<Response>((_resolve, reject) => {
        init.signal?.addEventListener('abort', () => {
            const e = new Error('The operation was aborted.');
            e.name = 'AbortError';
            reject(e);
        });
    }));

    afterEach(() => {
        vi.useRealTimers();
        vi.unstubAllGlobals();
        vi.restoreAllMocks();
    });

    /** Starts TestConnection (Authenticate → one SOAP request) and returns a probe of whether it has settled. */
    const start = (c: NetForumConnector, conn: MJCompanyIntegrationEntity): { settled: () => ConnectionTestResult | undefined; done: Promise<void> } => {
        let result: ConnectionTestResult | undefined;
        const done = c.TestConnection(conn, {} as UserInfo).then(r => { result = r; });
        return { settled: () => result, done };
    };

    it('a connection-level requestTimeoutMs replaces the 30 s per-request abort', async () => {
        vi.useFakeTimers();
        vi.spyOn(console, 'warn').mockImplementation(() => undefined);
        const fetchMock = hangingFetch();
        vi.stubGlobal('fetch', fetchMock);

        const run = start(new NetForumConnector(), ci({ requestTimeoutMs: 120_000, fetchTimeoutMs: 180_000 }));
        await vi.advanceTimersByTimeAsync(30_001);
        expect(fetchMock, 'the request went out').toHaveBeenCalledTimes(1);
        expect(run.settled(), 'still waiting past the old 30 s ceiling').toBeUndefined();

        await vi.advanceTimersByTimeAsync(90_000);
        await run.done;
        expect(run.settled()?.Success).toBe(false);
        expect(run.settled()?.Message, 'aborted at the configured ceiling, and says which').toMatch(/timed out after 120000ms/);
    });

    it('without requestTimeoutMs the request still aborts at 30 s', async () => {
        vi.useFakeTimers();
        vi.stubGlobal('fetch', hangingFetch());
        const run = start(new NetForumConnector(), ci({}));
        await vi.advanceTimersByTimeAsync(30_001);
        await run.done;
        expect(run.settled()?.Message).toMatch(/timed out after 30000ms/);
    });

    it('reads a JSON number only, clamps to 5 s – 10 min, and falls back to 30 s otherwise', () => {
        const from = (cfg: unknown): number => NetForumConnector.RequestTimeoutMsFrom(cfg === undefined ? null : JSON.stringify(cfg));
        expect(from(undefined)).toBe(30_000);
        expect(NetForumConnector.RequestTimeoutMsFrom('not json')).toBe(30_000);
        expect(from({})).toBe(30_000);
        expect(from({ requestTimeoutMs: '90000' }), 'a string is not a number').toBe(30_000);
        expect(from({ requestTimeoutMs: -5 })).toBe(30_000);
        expect(from({ requestTimeoutMs: 45_000 })).toBe(45_000);
        expect(from({ requestTimeoutMs: 1_000 }), 'raised to the 5 s floor').toBe(5_000);
        expect(from({ requestTimeoutMs: 10_000_000 }), 'capped at 10 minutes').toBe(600_000);
    });

    it('warns once when requestTimeoutMs is raised but the engine fetchTimeoutMs would still cut the page first', async () => {
        vi.useFakeTimers();
        const warned: string[] = [];
        vi.spyOn(console, 'warn').mockImplementation((...a: unknown[]) => { warned.push(a.map(String).join(' ')); });
        vi.stubGlobal('fetch', hangingFetch());
        const c = new NetForumConnector();
        const conn = ci({ requestTimeoutMs: 120_000 });
        const r1 = start(c, conn);
        await vi.advanceTimersByTimeAsync(120_001);
        await r1.done;
        const r2 = start(c, conn);
        await vi.advanceTimersByTimeAsync(120_001);
        await r2.done;
        const hits = warned.filter(m => /requestTimeoutMs/.test(m) && /fetchTimeoutMs/.test(m));
        expect(hits, 'one warning naming both settings').toHaveLength(1);
    });
});

describe('NetForumConnector — "Ambiguous column name" is learned, not a verdict on the list', () => {
    const { freshRoot } = isolateConnectorState();

    it('a declared columnList naming the key bare: the duplicated key is left out and the same call reads', async () => {
        // ChapterPhone-shaped: its own columns declared unqualified; no definition, so ORDER BY names the key bare.
        const world: World = {
            ChapterPhone: {
                pk: 'cph_key', wm: 'cph_change_date', ambiguousKey: 'cph_key',
                config: { columnList: ['cph_add_date', 'cph_change_date', 'cph_key', 'cph_phn_key'] },
            },
        };
        const root = freshRoot();
        const calls: SentCall[] = [];
        const r = await fetchObject(makeConnector(world, root, calls), 'ChapterPhone', '2026-10-14T16:27:00');
        expect(r.ok, `reads in the same call: ${errorOf(r)}`).toBe(true);
        expect(calls, 'one fault, one corrected request').toHaveLength(2);
        expect(calls[0].list.split(','), 'the first request named the key').toContain('cph_key');
        expect(calls[1].list, '…the corrected one leaves it to xWeb').toBe('cph_add_date,cph_change_date,cph_phn_key');
        expect(r.ok && r.r.Records.length).toBe(2);
        expect(r.ok && r.r.Records.every(x => !!x.Fields.cph_key), 'rows still carry the key (xWeb\'s copy)').toBe(true);
        expect(objOf(root, 'ChapterPhone').ambiguous, 'the fact is persisted for the object').toEqual(['cph_key']);
        expect(objOf(root, 'ChapterPhone').unsendable, 'the list is NOT marked unsendable').toBeUndefined();

        // A restart reads the learned fact: one request, no fault.
        const calls2: SentCall[] = [];
        const r2 = await fetchObject(makeConnector(world, root, calls2), 'ChapterPhone', '2026-10-14T16:27:00');
        expect(r2.ok, errorOf(r2)).toBe(true);
        expect(calls2.map(x => x.list)).toEqual(['cph_add_date,cph_change_date,cph_phn_key']);
    });

    it('a full list whose key the definition gives no table: the key is left out instead of the list being refused', async () => {
        const world: World = {
            Thing: {
                def: { MainTable: 'tt', KeyColumn: 'tt_key', Columns: [['', 'tt_key'], ['tt', 'tt_name'], ['tt', 'tt_change_date']] },
                pk: 'tt_key', wm: 'tt_change_date', ambiguousKey: 'tt_key',
            },
        };
        const root = freshRoot();
        const calls: SentCall[] = [];
        const r = await fetchObject(makeConnector(world, root, calls), 'Thing');
        expect(r.ok, `reads in the same call: ${errorOf(r)}`).toBe(true);
        expect(calls).toHaveLength(2);
        expect(calls[0].list.split(','), 'the full list named the key bare').toContain('tt_key');
        expect(calls[1].list.split(','), '…the corrected one does not').not.toContain('tt_key');
        expect(calls[1].list.split(',')).toEqual(expect.arrayContaining(['tt.tt_name', 'tt.tt_change_date']));
        expect(objOf(root, 'Thing').unsendable).toBeUndefined();
        expect(objOf(root, 'Thing').ambiguous).toEqual(['tt_key']);
    });

    it('a non-key name a declared list sends bare is qualified from the definition', async () => {
        const world: World = {
            Thing2: {
                def: { MainTable: 'aa', KeyColumn: 'aa_key', Columns: [['aa', 'aa_key'], ['aa', 'aa_name'], ['bb', 'shared_code', 'B1']] },
                pk: 'aa_key', ambiguousBare: ['shared_code'],
                config: { columnList: ['aa_key', 'aa_name', 'shared_code'] },
            },
        };
        const root = freshRoot();
        const calls: SentCall[] = [];
        const r = await fetchObject(makeConnector(world, root, calls), 'Thing2');
        expect(r.ok, `reads in the same call: ${errorOf(r)}`).toBe(true);
        expect(calls.map(x => x.list)).toEqual(['aa_key,aa_name,shared_code', 'aa_key,aa_name,B1.shared_code']);
        expect(objOf(root, 'Thing2').ambiguous).toEqual(['shared_code']);
    });

    it('an ambiguous name that can be neither qualified nor left out still ends the call, with one request', async () => {
        const world: World = { Thing3: { pk: 'k3', ambiguousBare: ['x3'], config: { columnList: ['k3', 'x3'] } } };
        const root = freshRoot();
        const calls: SentCall[] = [];
        const r = await fetchObject(makeConnector(world, root, calls), 'Thing3');
        expect(r.ok).toBe(false);
        expect(errorOf(r)).toMatch(/Ambiguous column name 'x3'/);
        expect(calls, 'nothing changed, so nothing is re-sent').toHaveLength(1);
    });
});
