import { describe, it, expect } from 'vitest';
import { writeFileSync } from 'node:fs';
import { join } from 'node:path';
import {
    type SentCall, type World, type FakeObject,
    errorOf, fetchObject, internals, isolateConnectorState, learnedAt, makeConnector, objOf, statics, warningsOf,
} from './netforum-fake-xweb.js';

/**
 * Ported from scripts/smoke/netforum-own-table-fallback.mjs.
 *
 * An object whose FULL explicit column list broke xWeb's SQL falls back, ONCE and under a budget, to its OWN-TABLE
 * list (main-table columns + key/ordering key/watermark) and keeps reading.
 *
 * The defect (a live tenant, 2026-10-13): 100 of 820 objects never synced. FetchChanges sends every column of the
 * object's GetQueryDefinition, JOINED tables' columns included; when xWeb answered "Incorrect syntax near …" (or a
 * fault that taught nothing) the object was marked `unsendable` and every later call was refused — "a statement
 * that broke once is broken with any list". The platform's direct loader read ~15M rows from those same objects by
 * asking only their OWN main-table columns: the joined columns are what break the SQL.
 */
describe('NetForumConnector — own-table fallback for an object whose full list breaks xWeb\'s SQL', () => {
    const { freshRoot, warned } = isolateConnectorState();

    // Address-shaped: main table co_address (key adr_key, watermark adr_change_date, adr_entity_key never sent),
    // joined co_customer columns and an ALIASED join of the main table itself — the joined ones break xWeb's SQL.
    const addressDef = (main = 'co_address', p = 'adr'): NonNullable<FakeObject['def']> => ({
        MainTable: main, KeyColumn: `${p}_key`,
        Columns: [[main, `${p}_key`], [main, `${p}_line1`], [main, `${p}_city`], [main, `${p}_entity_key`], [main, `${p}_change_date`],
            ['co_customer', 'cst_name_cp'], ['co_customer', 'cst_recno'], [main, `${p}_alt_line`, 'AltAddr']],
    });
    const isJoined = (item: string): boolean => /^(co_customer|AltAddr)\./i.test(item) || /(^|,)(cst_name_cp|cst_recno|\w+_alt_line)$/i.test(item);
    const seedLearned = (root: string, objects: Record<string, Record<string, unknown>>): void =>
        writeFileSync(join(root, '.nf-learned.json'), JSON.stringify({ version: 2, connections: { CI1: { objects } } }));

    it('(1/2) an object whose full list broke reads through ONE own-table list, persisted across a restart', async () => {
        const world: World = { Address: { def: addressDef(), wm: 'adr_change_date', mode: 'joinedBreaks' } };
        const root = freshRoot();
        const calls: SentCall[] = [];
        const c = makeConnector(world, root, calls);

        const a1 = await fetchObject(c, 'Address', '2026-10-01T00:00:00');
        expect(a1.ok, "the full list draws xWeb's syntax fault").toBe(false);
        expect(calls).toHaveLength(1);
        expect(calls[0].list.split(',').some(isJoined), '…the full list includes joined columns').toBe(true);
        expect(objOf(root, 'Address').unsendable, '…and is marked unsendable').toBe(true);

        const before = calls.length;
        const a2 = await fetchObject(c, 'Address', '2026-10-01T00:00:00');
        const sent = calls.slice(before);
        const own = sent[0]?.list ?? '';
        const items = own.split(',');
        expect(sent, `the NEXT call sends exactly ONE request: the own-table list ${errorOf(a2)}`).toHaveLength(1);
        expect(own, 'the own-table list is non-empty').not.toBe('');
        expect(items.some(isJoined), 'the own-table list names no joined column (other table or aliased join)').toBe(false);
        expect(items[0], 'the own-table list leads with the key (qualified)').toBe('co_address.adr_key');
        expect(items, '…carries the watermark, qualified like the full list').toContain('co_address.adr_change_date');
        expect(items).toContain('co_address.adr_line1');
        expect(own, 'the own-table list never names *_entity_key').not.toMatch(/_entity_key/i);
        expect(sent[0].orderBy, 'ORDER BY stays qualified by the main table').toBe('co_address.adr_key');
        expect(sent[0].where, 'WHERE stays qualified by the main table').toMatch(/^co_address\.adr_change_date >= '/);
        expect(a2.ok && a2.r.Records.length, 'the own-table read returns its rows').toBe(2);
        const w = warningsOf(a2).find(x => x.Code === 'COLUMN_LIST_OWN_TABLE_ONLY');
        expect(w, 'FetchChanges returns a COLUMN_LIST_OWN_TABLE_ONLY warning').toBeDefined();
        expect(w!.Message, '…naming the object').toMatch(/Address/);
        expect(w!.Data?.ObjectName).toBe('Address');
        expect(objOf(root, 'Address').ownListUsable, 'ownListUsable is persisted for the object').toBe(true);
        expect(learnedAt(root).connections?.CI1?.probeFaults?.own?.count ?? 0, '…and the own probe cost no fault').toBe(0);

        const before3 = calls.length;
        const a3 = await fetchObject(c, 'Address');
        expect(a3.ok, 'a later call on the same instance reads').toBe(true);
        expect(calls.length - before3, '…with one request').toBe(1);
        expect(calls[before3].list, '…sending the own list directly').toBe(own);
        expect(warned.filter(m => /Address/.test(m) && /own-table/i.test(m)), 'the own-table read is logged once per process naming the object').toHaveLength(1);

        // restart
        const calls2: SentCall[] = [];
        const r1 = await fetchObject(makeConnector(world, root, calls2), 'Address');
        expect(r1.ok, `after a restart the object reads ${errorOf(r1)}`).toBe(true);
        expect(calls2.map(x => x.list), '…sending its own list directly: ONE request, no fault').toEqual([own]);
        expect(r1.ok && r1.r.Records.length).toBe(2);
    });

    it("(2') a v2 learned file written before this fix (unsendable, no own verdict) loads and falls back", async () => {
        const def = addressDef('co_customer_x', 'cst');
        def.Columns = def.Columns.filter(([t]) => t !== 'co_customer'); // joined = the aliased one only
        def.Columns.push(['co_individual', 'ind_first_name']);
        const world: World = { Customer: { def, wm: 'cst_change_date', mode: 'joinedBreaks' } };
        const root = freshRoot();
        writeFileSync(join(root, '.nf-learned.json'), JSON.stringify({ version: 2, savedAt: '2026-10-13T00:00:00Z', connections: {
            CI1: { probeFaults: { default: { day: '2026-10-13', count: 4 } }, objects: { customer: { unsendable: true, unselectable: ['cst_gone'] } } } } }));
        const calls: SentCall[] = [];
        const r = await fetchObject(makeConnector(world, root, calls), 'Customer');
        expect(r.ok, `the first call after deploy reads ${errorOf(r)}`).toBe(true);
        expect(calls, '…sending ONE own-table list').toHaveLength(1);
        expect(calls[0].list).not.toContain('ind_first_name');
        const o = objOf(root, 'Customer');
        expect(o.unsendable, 'the earlier verdicts are kept').toBe(true);
        expect(o.unselectable).toEqual(['cst_gone']);
        expect(learnedAt(root).connections?.CI1?.probeFaults?.default?.count).toBe(4);
        expect(o.ownListUsable, '…and ownListUsable is added').toBe(true);
    });

    it("(2'') an \"Invalid column name\" fault on the own list drops that own column and reads", async () => {
        const world: World = { Task: { def: addressDef('ac_task', 'tsk'), mode: 'joinedBreaks', invalid: ['tsk_city'] } };
        const root = freshRoot();
        seedLearned(root, { task: { unsendable: true } });
        const calls: SentCall[] = [];
        const r = await fetchObject(makeConnector(world, root, calls), 'Task');
        expect(r.ok, errorOf(r)).toBe(true);
        expect(calls, 'two requests: the own list, then the own list without the named column').toHaveLength(2);
        expect(calls[0].list).toContain('tsk_city');
        expect(calls[1].list).not.toContain('tsk_city');
        expect(calls[1].list.split(',').some(isJoined)).toBe(false);
        expect(objOf(root, 'Task').ownListUsable, 'the own list is persisted usable').toBe(true);
        expect(objOf(root, 'Task').unselectable ?? [], 'the column is learned for the object').toContain('tsk_city');
    });

    it("(2''') protected columns are kept in the own list wherever they live", async () => {
        const world: World = { Activity: { def: { MainTable: 'co_customer_activity', KeyColumn: 'cav_key', Columns: [
            ['co_customer_activity', 'cav_key'], ['co_customer_activity', 'cav_note'], ['co_customer', 'cst_change_date'], ['co_customer', 'cst_name_cp']] },
        wm: 'cst_change_date', mode: 'joinedBreaks', allowJoined: ['cst_change_date'] } };
        const root = freshRoot();
        seedLearned(root, { activity: { unsendable: true } });
        const calls: SentCall[] = [];
        const r = await fetchObject(makeConnector(world, root, calls), 'Activity');
        expect(r.ok, errorOf(r)).toBe(true);
        expect(calls.map(x => x.list), 'the own list keeps the joined watermark (qualified) and drops the other joined column')
            .toEqual(['co_customer_activity.cav_key,co_customer_activity.cav_note,co_customer.cst_change_date']);
    });

    /**
     * The definition's MainTable does not own the key: the KEY's table is the own table. A live tenant's
     * EventsRegistrant (2026-10-13): netFORUM's definition names ev_registration_dem (rdm_*) as its main table, but
     * the object is keyed on ev_registrant.reg_key (persisted IsPrimaryKey) and watermarked on reg_change_date. The
     * own list was built from rdm_* only → "names no main-table column beyond its key/watermark" → refused on every
     * run, so no registration after 2026-09-28 reached the tenant through the schedule. The direct loader reads the
     * same object with the key's own reg_* columns.
     */
    it("(2'''') MainTable without the key: the own list is the key's table (ev_registrant), not the definition's MainTable", async () => {
        const world: World = { EventsRegistrant: { def: { MainTable: 'ev_registration_dem', KeyColumn: 'rdm_key', Columns: [
            ['ev_registration_dem', 'rdm_key'], ['ev_registration_dem', 'rdm_change_date'],
            ['ev_registrant', 'reg_key'], ['ev_registrant', 'reg_evt_key'], ['ev_registrant', 'reg_cst_key'],
            ['ev_registrant', 'reg_add_date'], ['ev_registrant', 'reg_change_date'], ['ev_registrant', 'reg_entity_key'],
            ['co_customer', 'cst_org_name_dn'], ['ev_registrant', 'reg_cancel_date', 'CancelReg']] },
        pk: 'reg_key', wm: 'reg_change_date', mode: 'joinedBreaks', ownTable: 'ev_registrant' } };
        const root = freshRoot();
        seedLearned(root, { eventsregistrant: { unsendable: true } });
        const calls: SentCall[] = [];
        const r = await fetchObject(makeConnector(world, root, calls), 'EventsRegistrant');
        expect(r.ok, errorOf(r)).toBe(true);
        expect(calls.map(x => x.list), "ONE request with the key table's own columns (key first; no rdm_*, no joined, no alias, no _entity_key)")
            .toEqual(['ev_registrant.reg_key,ev_registrant.reg_evt_key,ev_registrant.reg_cst_key,ev_registrant.reg_add_date,ev_registrant.reg_change_date']);
        expect(objOf(root, 'EventsRegistrant').ownListUsable, 'the own list is persisted usable').toBe(true);

        // Unchanged when the key IS on MainTable (Address): the key's table and MainTable are one and the same.
        const world2: World = { Address: { def: addressDef(), wm: 'adr_change_date', mode: 'joinedBreaks', pk: 'adr_key' } };
        const root2 = freshRoot();
        seedLearned(root2, { address: { unsendable: true } });
        const calls2: SentCall[] = [];
        const r2 = await fetchObject(makeConnector(world2, root2, calls2), 'Address');
        expect(r2.ok, errorOf(r2)).toBe(true);
        expect(calls2.map(x => x.list), "a key on MainTable: the own list is MainTable's, as before")
            .toEqual(['co_address.adr_key,co_address.adr_line1,co_address.adr_city,co_address.adr_change_date']);
    });

    it('(3) an object whose own-table list breaks too is marked ownListUnsendable and refused without a request', async () => {
        const world: World = { InvoiceDetail: { def: addressDef('ac_invoice_detail', 'ivd'), wm: 'ivd_change_date', mode: 'allBreaks' } };
        const root = freshRoot();
        const calls: SentCall[] = [];
        const c = makeConnector(world, root, calls);
        await fetchObject(c, 'InvoiceDetail');

        const b = calls.length;
        const r2 = await fetchObject(c, 'InvoiceDetail');
        const probe = calls.slice(b);
        expect(r2.ok, 'the second call sends ONE own-table probe, which faults').toBe(false);
        expect(probe).toHaveLength(1);
        expect(probe[0].list.split(',').some(isJoined)).toBe(false);
        expect(objOf(root, 'InvoiceDetail').ownListUnsendable, 'ownListUnsendable is persisted').toBe(true);
        expect(objOf(root, 'InvoiceDetail').ownListUsable).not.toBe(true);
        expect(learnedAt(root).connections?.CI1?.probeFaults?.own?.count, '…and the fault counted against the own budget (1)').toBe(1);

        const b3 = calls.length;
        const r3 = await fetchObject(c, 'InvoiceDetail');
        expect(r3.ok, 'a third call is refused').toBe(false);
        expect(calls.length - b3, '…with NO request').toBe(0);
        expect(errorOf(r3), '…naming the own-table list').toMatch(/own-table list/i);
        expect(errorOf(r3), '…and the object').toMatch(/InvoiceDetail/);

        const calls2: SentCall[] = [];
        const r4 = await fetchObject(makeConnector(world, root, calls2), 'InvoiceDetail');
        expect(r4.ok, 'after a restart it is still refused').toBe(false);
        expect(calls2, '…with no request').toHaveLength(0);
    });

    it('(4) objects whose full list works are untouched', async () => {
        const world: World = { Individual: { def: addressDef('co_individual', 'ind'), wm: 'ind_change_date', mode: 'ok' } };
        const root = freshRoot();
        const calls: SentCall[] = [];
        const c = makeConnector(world, root, calls);
        const r1 = await fetchObject(c, 'Individual');
        const r2 = await fetchObject(c, 'Individual');
        expect(r1.ok && r2.ok, 'both calls read').toBe(true);
        expect(calls, 'each call sends ONE request').toHaveLength(2);
        expect(calls.every(x => x.list === calls[0].list), '…with the same FULL list').toBe(true);
        expect(calls[0].list, '…joined columns included').toContain('co_customer.cst_name_cp');
        expect(calls[0].list.startsWith('co_individual.ind_key,'), '…key first').toBe(true);
        expect(warningsOf(r1).some(x => x.Code === 'COLUMN_LIST_OWN_TABLE_ONLY'), 'no own-table warning').toBe(false);
        expect(objOf(root, 'Individual').ownListUsable, 'nothing own-related persisted').toBeUndefined();
        expect(objOf(root, 'Individual').ownListUnsendable).toBeUndefined();
    });

    it('(6) a full list whose three learn rounds all fail falls back to the own-table list on the next call', async () => {
        const world: World = { Certificant: { def: { MainTable: 'cn_certificant', KeyColumn: 'crt_key', Columns: [
            ['cn_certificant', 'crt_key'], ['cn_certificant', 'crt_status'],
            ['co_customer', 'cst_a'], ['co_customer', 'cst_b'], ['co_customer', 'cst_c'], ['co_customer', 'cst_d']] },
        mode: 'ok', invalidOneAtATime: ['cst_a', 'cst_b', 'cst_c', 'cst_d'] } };
        const root = freshRoot();
        const calls: SentCall[] = [];
        const c = makeConnector(world, root, calls);
        const r1 = await fetchObject(c, 'Certificant');
        expect(r1.ok, 'the first call pays the full list + 3 learn rounds and still faults').toBe(false);
        expect(calls).toHaveLength(4);
        expect(objOf(root, 'Certificant').unsendable, '…and marks the full list unsendable').toBe(true);

        const b = calls.length;
        const r2 = await fetchObject(c, 'Certificant');
        expect(r2.ok, `the next call reads ${errorOf(r2)}`).toBe(true);
        expect(calls.slice(b).map(x => x.list), '…sending ONE own-table list').toEqual(['cn_certificant.crt_key,cn_certificant.crt_status']);
    });

    it('(5) own-table probe faults are bounded by a persisted daily budget', async () => {
        const real = statics().PROBE_FAULTS_PER_DAY;
        const total = real.default + real.legacy + real.own;
        expect(real.own, "an 'own' probe budget exists").toBeGreaterThan(0);
        expect(real.own, '…is small').toBeLessThanOrEqual(20);
        expect(total, "…and all probe kinds together stay well under xWeb's ~100/day").toBeLessThanOrEqual(50);

        const budget = 3; // restored by the harness afterEach
        statics().PROBE_FAULTS_PER_DAY = { ...real, own: budget };
        const world: World = {};
        const objects: Record<string, Record<string, unknown>> = {};
        for (let i = 1; i <= 10; i++) {
            world[`Pkg${i}`] = { def: addressDef(`oe_pkg${i}`, `pk${i}`), mode: 'allBreaks' };
            objects[`pkg${i}`] = { unsendable: true };
        }
        world.Twin = { def: addressDef('oe_twin', 'tw'), mode: 'allBreaks' };
        objects.twin = { unsendable: true };
        const root = freshRoot();
        seedLearned(root, objects);

        const calls: SentCall[] = [];
        const c = makeConnector(world, root, calls);
        const res = await Promise.all(Object.keys(world).filter(k => k.startsWith('Pkg')).map(k => fetchObject(c, k)));
        expect(calls.length, `10 concurrent unsendable objects whose own lists break pay at most the budget (${budget}) in faults`).toBeLessThanOrEqual(budget);
        expect(calls.length).toBeGreaterThan(0);
        const refusedBudget = res.filter(r => !r.ok && /budget/i.test(r.e.message)).length;
        expect(refusedBudget, 'the objects over budget are refused WITHOUT a request, with a budget message').toBe(10 - calls.length);
        expect(learnedAt(root).connections?.CI1?.probeFaults?.own?.count, 'the spent count is persisted').toBe(calls.length);

        const calls2: SentCall[] = [];
        const c2 = makeConnector(world, root, calls2);
        await Promise.all(['Pkg1', 'Pkg5', 'Pkg10'].map(k => fetchObject(c2, k)));
        expect(calls2, 'after a restart the SAME day the spent own budget is still spent (no request)').toHaveLength(0);

        const calls3: SentCall[] = [];
        const c3 = makeConnector(world, root, calls3);
        internals(c3).UtcDay = () => '2999-01-01';
        const u = Object.keys(world).find(k => k.startsWith('Pkg') && !calls.some(x => x.obj === k))!;
        await fetchObject(c3, u);
        expect(calls3.map(x => x.obj), 'on a later UTC day an unprobed object is probed again (once)').toEqual([u]);

        // three concurrent first calls on ONE object: one own probe, not three
        const calls4: SentCall[] = [];
        const c4 = makeConnector(world, root, calls4);
        internals(c4).UtcDay = () => '2999-01-02';
        await Promise.all([fetchObject(c4, 'Twin'), fetchObject(c4, 'Twin'), fetchObject(c4, 'Twin')]);
        expect(calls4, 'three concurrent calls on one object pay ONE own-table probe fault').toHaveLength(1);
    });
});
