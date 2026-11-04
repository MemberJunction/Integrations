import { describe, it, expect } from 'vitest';
import {
    type SentCall, type World, type FakeObject,
    ctxFor, errorOf, fetchObject, isolateConnectorState, makeConnector,
} from './netforum-fake-xweb.js';

/**
 * The defect (a live tenant, 2026-10-29). netFORUM stamps `<prefix>_change_date` only when a record is EDITED; a newly
 * inserted row carries `<prefix>_add_date` and a NULL change date. The incremental read sent `<prefix>_change_date >=
 * '<wm>'` alone, so an append-only object (dues, membership and course history, GL transactions, payment detail) never
 * returned a new row: seven objects read a clean 0 rows every night for two weeks while netFORUM held 200+ new rows
 * each (measured with the connector's own column list: `mdh_change_date >= '20261012'` → 0 rows, `mdh_add_date >=
 * '20261012'` → 200, every one with an empty mdh_change_date).
 *
 * The read now asks for rows changed OR added since the watermark, and the next watermark is the latest of either.
 */
describe('NetForumConnector — append-only objects (change date OR add date)', () => {
    const { freshRoot } = isolateConnectorState();

    const T = 'mb_member_dues_history';
    const duesDef = (): NonNullable<FakeObject['def']> => ({ MainTable: T, KeyColumn: 'mdh_key',
        Columns: [[T, 'mdh_key'], [T, 'mdh_add_date'], [T, 'mdh_change_date'], [T, 'mdh_amount'], ['co_customer', 'cst_name_cp']] });
    const WM = '2026-10-12T08:00:00-05:00';
    const SINCE = "'20261012 08:00:00'";

    it('(1) the predicate asks for rows changed OR added since the watermark, both qualified', async () => {
        const world: World = { MemberDuesHistory: { def: duesDef(), wm: 'mdh_change_date', pk: 'mdh_key', mode: 'ok' } };
        const calls: SentCall[] = [];
        const r = await fetchObject(makeConnector(world, freshRoot(), calls), 'MemberDuesHistory', WM);
        expect(r.ok, errorOf(r)).toBe(true);
        expect(calls).toHaveLength(1);
        expect(calls[0].list, 'the add date is in the list (its value sets the next watermark)').toContain(`${T}.mdh_add_date`);
        expect(calls[0].where).toBe(`(${T}.mdh_change_date >= ${SINCE} OR ${T}.mdh_add_date >= ${SINCE})`);
    });

    it('(2) rows that were only ADDED (change date empty) advance the watermark to the latest add date', async () => {
        const world: World = { MemberDuesHistory: { def: duesDef(), wm: 'mdh_change_date', pk: 'mdh_key', mode: 'ok',
            values: { mdh_change_date: ['', '', ''], mdh_add_date: ['2026-10-20T09:00:00', '2026-10-27T14:00:00', '2026-10-21T10:00:00'] } } };
        const r = await fetchObject(makeConnector(world, freshRoot(), []), 'MemberDuesHistory', WM);
        expect(r.ok, errorOf(r)).toBe(true);
        expect(r.ok && r.r.NewWatermarkValue, 'the latest add date — not empty, not unchanged').toBe('2026-10-27T14:00:00');
    });

    it('(3) the next watermark is the latest of BOTH dates across the batch', async () => {
        const world: World = { MemberDuesHistory: { def: duesDef(), wm: 'mdh_change_date', pk: 'mdh_key', mode: 'ok',
            values: { mdh_change_date: ['2026-10-28T11:00:00', '', ''], mdh_add_date: ['2026-01-05T09:00:00', '2026-10-27T14:00:00', '2026-10-21T10:00:00'] } } };
        const r = await fetchObject(makeConnector(world, freshRoot(), []), 'MemberDuesHistory', WM);
        expect(r.ok && r.r.NewWatermarkValue, 'an edit later than every add wins').toBe('2026-10-28T11:00:00');
    });

    it('(4) an object whose definition has no matching add date keeps the change-date predicate alone', async () => {
        const world: World = { Invoice: { def: { MainTable: 'ac_invoice', KeyColumn: 'inv_key',
            Columns: [['ac_invoice', 'inv_key'], ['ac_invoice', 'inv_change_date'], ['co_customer', 'cst_add_date']] },
            wm: 'inv_change_date', pk: 'inv_key', mode: 'ok' } };
        const calls: SentCall[] = [];
        const r = await fetchObject(makeConnector(world, freshRoot(), calls), 'Invoice', WM);
        expect(r.ok, errorOf(r)).toBe(true);
        expect(calls[0].where, 'no OR, and never another table\'s add date').toBe(`ac_invoice.inv_change_date >= ${SINCE}`);
    });

    it('(5) an add date xWeb cannot resolve is learned out of the list AND out of the predicate', async () => {
        const world: World = { MemberDuesHistory: { def: duesDef(), wm: 'mdh_change_date', pk: 'mdh_key', mode: 'ok',
            invalidOneAtATime: ['mdh_add_date'] } };
        const calls: SentCall[] = [];
        const r = await fetchObject(makeConnector(world, freshRoot(), calls), 'MemberDuesHistory', WM);
        expect(r.ok, errorOf(r)).toBe(true);
        expect(calls, 'the fault, then the rebuilt request').toHaveLength(2);
        expect(calls[1].list).not.toContain('mdh_add_date');
        expect(calls[1].where, 'the rebuilt request does not name the column it just learned').toBe(`${T}.mdh_change_date >= ${SINCE}`);
    });

    it('(6) with a keyset position, the OR group is ANDed with the seek predicate', async () => {
        const world: World = { MemberDuesHistory: { def: duesDef(), wm: 'mdh_change_date', pk: 'mdh_key', mode: 'ok' } };
        const calls: SentCall[] = [];
        const c = makeConnector(world, freshRoot(), calls);
        await c.FetchChanges({ ...ctxFor('MemberDuesHistory', WM), AfterKeyValue: 'k-100' });
        expect(calls[0].where).toBe(`(${T}.mdh_change_date >= ${SINCE} OR ${T}.mdh_add_date >= ${SINCE}) AND ${T}.mdh_key > 'k-100'`);
    });
});
