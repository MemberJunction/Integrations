import { describe, it, expect } from 'vitest';
import { writeFileSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import {
    STAR, type SentCall, type World, type LearnedFileView,
    errorOf, fetchObject, internals, isolateConnectorState, learnedAt, makeConnector, statics, warningsOf,
} from './netforum-fake-xweb.js';

/**
 * Ported from scripts/smoke/netforum-object-scoped-faults.mjs.
 *
 * netFORUM faults learned on ONE object must not poison any OTHER object.
 *
 * The defect (a live tenant, 2026-09-27/28): one object's "'*' is not a valid value for szColumnList" fault was
 * latched CONNECTION-wide, so 326 of 820 objects were refused on every sync; and `table.column` pairs learned from
 * three Price* sub-objects were applied CONNECTION-wide, so Price / ProductType / ProductGeneric landed keys-only
 * and InvoiceDetail lost its 63 prc_ columns.
 */
describe('NetForumConnector — faults learned on one object never poison another', () => {
    const { freshRoot, warned } = isolateConnectorState();

    it("(a) a default-list '*' fault is scoped to the object that faulted", async () => {
        const world: World = {
            StarObj: { defaultFault: STAR },                       // its default list is '*'; nothing describes its columns
            GoodObj: { defaultCols: ['gd_key', 'gd_name'] },        // its default list is fine
            GoodObj2: { defaultCols: ['g2_key', 'g2_name'] },
            Listed: { fields: [['ls_key', true], ['ls_name', false]], defaultFault: STAR }, // persisted fields → explicit list known
        };
        const root = freshRoot();
        const calls: SentCall[] = [];
        const c = makeConnector(world, root, calls);

        const a1 = await fetchObject(c, 'StarObj');
        expect(a1.ok, "StarObj's '*' fault surfaces for StarObj").toBe(false);

        const b1 = await fetchObject(c, 'GoodObj');
        expect(calls.filter(x => x.obj === 'GoodObj' && x.list === ''), 'GoodObj still sends ONE probe of its own default list after StarObj faulted').toHaveLength(1);
        expect(b1.ok && b1.r.Records.length, `GoodObj returns its rows ${errorOf(b1)}`).toBe(2);

        const l1 = await fetchObject(c, 'Listed');
        const lc = calls.filter(x => x.obj === 'Listed');
        expect(l1.ok, `an object with a known explicit list still sends it ${errorOf(l1)}`).toBe(true);
        expect(lc, 'no default-list fault paid for it: one request').toHaveLength(1);
        expect(lc[0].list).toContain('ls_name');

        const before = calls.length;
        const a2 = await fetchObject(c, 'StarObj');
        expect(a2.ok, "StarObj's fault is paid once per process").toBe(false);
        expect(calls.length - before, 'second call sends nothing').toBe(0);
        expect(errorOf(a2), "StarObj's refusal names StarObj's OWN default list").toMatch(/StarObj/);
        expect(errorOf(a2), "…not the connection's").not.toMatch(/this connection's default column list/i);

        // restart: a new instance reading the same learned file
        const calls2: SentCall[] = [];
        const c2 = makeConnector(world, root, calls2);
        const a3 = await fetchObject(c2, 'StarObj');
        expect(a3.ok).toBe(false);
        expect(calls2.filter(x => x.obj === 'StarObj'), "after a restart StarObj's fault is still not re-paid (persisted)").toHaveLength(0);
        const b3 = await fetchObject(c2, 'GoodObj2');
        expect(b3.ok, `after a restart another never-probed object still probes ${errorOf(b3)}`).toBe(true);
        expect(calls2.filter(x => x.obj === 'GoodObj2' && x.list === '')).toHaveLength(1);

        // concurrency on ONE object: one probe, not three
        const calls3: SentCall[] = [];
        const c3 = makeConnector({ Twin: { defaultFault: STAR } }, freshRoot(), calls3);
        await Promise.all([fetchObject(c3, 'Twin'), fetchObject(c3, 'Twin'), fetchObject(c3, 'Twin')]);
        expect(calls3, 'three concurrent first calls on one object pay ONE default-list fault').toHaveLength(1);
    });

    it("(a') default-list probe faults are bounded per connection per UTC day, across restarts", async () => {
        const world: World = {};
        for (let i = 1; i <= 12; i++) world[`Star${i}`] = { defaultFault: STAR };
        world.Fine = { defaultCols: ['f_key'] };
        const root = freshRoot();
        const calls: SentCall[] = [];
        const c = makeConnector(world, root, calls);

        const shipped = statics().PROBE_FAULTS_PER_DAY.default;
        expect(shipped, "a default-list probe budget exists and is well below xWeb's ~100/day").toBeGreaterThan(0);
        expect(shipped).toBeLessThanOrEqual(25);

        const budget = 5; // a small budget so 12 objects overrun it (restored by the harness afterEach)
        statics().PROBE_FAULTS_PER_DAY = { ...statics().PROBE_FAULTS_PER_DAY, default: budget };
        const results = await Promise.all(Object.keys(world).filter(k => k.startsWith('Star')).map(k => fetchObject(c, k)));
        const faults = calls.filter(x => x.list === '').length;
        expect(faults, `12 concurrent '*' objects pay at most the budget (${budget}) in faults`).toBeLessThanOrEqual(budget);
        const refused = results.filter(r => !r.ok && /budget/i.test(r.e.message)).length;
        expect(refused, 'the objects over budget are refused WITHOUT a request, with a budget message').toBe(12 - faults);

        const f = await fetchObject(c, 'Fine');
        expect(f.ok, 'an object whose default list is fine cannot probe once the fault budget is spent').toBe(false);
        expect(calls.filter(x => x.obj === 'Fine'), '…refused with no request').toHaveLength(0);

        const calls2: SentCall[] = [];
        const c2 = makeConnector(world, root, calls2);
        await fetchObject(c2, 'Star12');
        await fetchObject(c2, 'Star1');
        expect(calls2, 'after a restart the SAME day the spent budget is still spent (no request)').toHaveLength(0);

        const calls3: SentCall[] = [];
        const c3 = makeConnector(world, root, calls3);
        internals(c3).UtcDay = () => '2999-01-01';
        const u = Object.keys(world).find(k => k.startsWith('Star') && !calls.some(x => x.obj === k))!;
        await fetchObject(c3, u);
        expect(calls3.filter(x => x.obj === u), 'on a later UTC day an unprobed object is probed again').toHaveLength(1);
    });

    const priceWorld = (): World => ({
        // A Price* sub-object whose list joins oe_price / oe_product_type under attributions its SQL cannot resolve
        PriceExhibitBooth: {
            def: { KeyColumn: 'pxb_key', Columns: [['ev_px', 'pxb_key'], ['ev_px', 'pxb_name'], ['oe_price', 'prc_key'],
                ['oe_price', 'prc_code'], ['oe_product_type', 'ptp_key'], ['oe_product_type', 'ptp_code']] },
            invalid: ['prc_key', 'prc_code', 'ptp_key', 'ptp_code'],
        },
        Price: {
            def: { KeyColumn: 'prc_key', Columns: [['oe_price', 'prc_key'], ['oe_price', 'prc_code'], ['oe_price', 'prc_amount'], ['oe_price', 'prc_change_date']] },
            wm: 'prc_change_date',
        },
        ProductType: { def: { KeyColumn: 'ptp_key', Columns: [['oe_product_type', 'ptp_key'], ['oe_product_type', 'ptp_code'], ['oe_product_type', 'ptp_name']] } },
        InvoiceDetail: { def: { KeyColumn: 'ivd_key', Columns: [['ac_invoice_detail', 'ivd_key'], ['ac_invoice_detail', 'ivd_amount'], ['oe_price', 'prc_code'], ['oe_price', 'prc_amount']] } },
    });
    const firstListOf = (calls: SentCall[], obj: string): string => calls.filter(x => x.obj === obj).map(x => x.list)[0] ?? '';

    it('(b) learned unresolvable pairs are scoped to the object that learned them', async () => {
        const world = priceWorld();
        const root = freshRoot();
        const calls: SentCall[] = [];
        const c = makeConnector(world, root, calls);

        const s = await fetchObject(c, 'PriceExhibitBooth');
        expect(s.ok, `the sub-object learns from its own fault and then reads ${errorOf(s)}`).toBe(true);

        const p = await fetchObject(c, 'Price');
        const pl = firstListOf(calls, 'Price');
        expect(pl, "Price's list keeps prc_code (not removed by PriceExhibitBooth's fault)").toMatch(/(^|,)oe_price\.prc_code(,|$)/);
        expect(pl, "…and prc_amount").toMatch(/(^|,)oe_price\.prc_amount(,|$)/);
        expect(pl.split(',')[0], "Price's own key leads its list, qualified (never dropped by a pair)").toBe('oe_price.prc_key');
        expect(p.ok, `Price reads ${errorOf(p)}`).toBe(true);

        await fetchObject(c, 'ProductType');
        const tl = firstListOf(calls, 'ProductType');
        expect(tl.split(',')[0], "ProductType's list leads with its key").toBe('oe_product_type.ptp_key');
        expect(tl, "…and keeps ptp_code").toContain('oe_product_type.ptp_code');

        await fetchObject(c, 'InvoiceDetail');
        const il = firstListOf(calls, 'InvoiceDetail');
        expect(il, 'InvoiceDetail keeps its prc_ columns').toContain('oe_price.prc_code');
        expect(il).toContain('oe_price.prc_amount');

        // the learning object's own protection survives a restart (it does not re-pay its fault)
        const calls2: SentCall[] = [];
        const s2 = await fetchObject(makeConnector(world, root, calls2), 'PriceExhibitBooth');
        expect(s2.ok, 'after a restart the sub-object reads').toBe(true);
        expect(calls2, '…with ZERO faults (its own facts persisted)').toHaveLength(1);
    });

    it("(b') an OLD (v1) learned file with connection-wide pairs and a connection-wide '*' latch does not re-poison", async () => {
        const world = priceWorld();
        world.GoodObj = { defaultCols: ['gd_key'] };
        const root = freshRoot();
        writeFileSync(join(root, '.nf-learned.json'), JSON.stringify({ version: 1, savedAt: '2026-09-28T00:00:00Z', connections: {
            '*': { unresolvable: ['oe_price.prc_code', 'oe_price.prc_key', 'oe_price.prc_amount', 'oe_product_type.ptp_code', 'oe_product_type.ptp_key'],
                objects: { priceexhibitbooth: { unselectable: ['prc_key', 'prc_code', 'ptp_key', 'ptp_code'] } } },
            CI1: { defaultListUnusable: true },
        } }));
        const calls: SentCall[] = [];
        const c = makeConnector(world, root, calls);

        await fetchObject(c, 'Price');
        const pl = firstListOf(calls, 'Price');
        expect(pl, "Price's list is NOT cut by the v1 connection-wide pairs").toContain('oe_price.prc_code');
        expect(pl.split(',')[0]).toBe('oe_price.prc_key');

        const g = await fetchObject(c, 'GoodObj');
        expect(g.ok, `the v1 connection-wide '*' latch does not refuse an object that never faulted ${errorOf(g)}`).toBe(true);
        expect(calls.some(x => x.obj === 'GoodObj' && x.list === '')).toBe(true);

        const s = await fetchObject(c, 'PriceExhibitBooth');
        expect(s.ok, 'the object that learned in v1 keeps its own protection (reads)').toBe(true);
        expect(calls.filter(x => x.obj === 'PriceExhibitBooth'), '…with zero faults').toHaveLength(1);

        const saved: LearnedFileView = learnedAt(root);
        const anyConnWide = Object.values(saved.connections ?? {}).some(sec => Array.isArray(sec.unresolvable) || sec.defaultListUnusable === true);
        expect(anyConnWide, 'the file written back carries no connection-wide unresolvable / defaultListUnusable (a rollback cannot re-poison)').toBe(false);
        expect(saved.version).toBe(2);
    });

    it("(b'') v1 pairs are budgeted suspects: probed once, cut only when today's legacy budget is spent", async () => {
        const v1 = (): string => JSON.stringify({ version: 1, connections: { '*': { unresolvable: ['oe_price.prc_code', 'oe_price.prc_amount', 'oe_price.prc_key'] } } });
        const real = statics().PROBE_FAULTS_PER_DAY;
        expect(real.legacy, 'a legacy-pair probe budget exists and is small').toBeGreaterThan(0);
        expect(real.legacy).toBeLessThanOrEqual(25);

        // budget spent → the object reads as v1 did (pairs left out, key still protected), and is not marked cleared
        statics().PROBE_FAULTS_PER_DAY = { ...real, legacy: 0 };
        const root = freshRoot();
        writeFileSync(join(root, '.nf-learned.json'), v1());
        const calls: SentCall[] = [];
        const p = await fetchObject(makeConnector(priceWorld(), root, calls), 'Price');
        const pl = firstListOf(calls, 'Price');
        expect(p.ok, `with the legacy budget spent, Price reads ${errorOf(p)}`).toBe(true);
        expect(pl, '…with the v1 cut').not.toContain('prc_code');
        expect(pl, '…but keeps its own key').toContain('prc_key');
        statics().PROBE_FAULTS_PER_DAY = real;

        // a legacy-carrying object whose full list really faults: one budgeted fault, per-object learning, then cleared
        const world = priceWorld();
        world.Price.invalid = ['prc_code'];
        const root2 = freshRoot();
        writeFileSync(join(root2, '.nf-learned.json'), v1());
        const calls2: SentCall[] = [];
        const p2 = await fetchObject(makeConnector(world, root2, calls2), 'Price');
        const saved = JSON.parse(readFileSync(join(root2, '.nf-learned.json'), 'utf8')) as LearnedFileView;
        const price = saved.connections?.CI1?.objects?.price;
        expect(p2.ok, `the legacy probe reads after learning ${errorOf(p2)}`).toBe(true);
        expect(saved.connections?.CI1?.probeFaults?.legacy?.count, 'the faulting legacy probe is counted against the budget (1)').toBe(1);
        expect(price?.unselectable, '…and the object learns only its own column').toEqual(['prc_code']);
        expect(price?.legacyCleared).toBe(true);

        const calls3: SentCall[] = [];
        await fetchObject(makeConnector(world, root2, calls3), 'Price');
        expect(calls3, 'after a restart the cleared object reads with zero faults').toHaveLength(1);
        expect(calls3[0].list).not.toContain('prc_code');
    });

    it('(c) a keys-only collapse is warned, naming the object', async () => {
        const world: World = { Narrow: { def: { KeyColumn: 'nr_key', Columns: [['t_nr', 'nr_key'], ['t_nr', 'nr_a'], ['t_nr', 'nr_b'], ['t_nr', 'nr_date']] },
            wm: 'nr_date', invalid: ['nr_a', 'nr_b'] } };
        const calls: SentCall[] = [];
        const r = await fetchObject(makeConnector(world, freshRoot(), calls), 'Narrow');
        const w = warningsOf(r).find(x => /COLLAPSED/i.test(x.Code ?? ''));
        expect(r.ok, errorOf(r)).toBe(true);
        expect(w, 'FetchChanges returns a COLUMN_LIST_COLLAPSED_TO_KEY warning').toBeDefined();
        expect(w!.Message, '…naming the object').toMatch(/Narrow/);
        expect(w!.Data?.ObjectName).toBe('Narrow');
        expect(warned.some(m => /Narrow/.test(m)), 'the collapse is also logged once (console.warn) naming the object').toBe(true);

        const r2 = await fetchObject(makeConnector({ Wide: { def: { KeyColumn: 'wd_key', Columns: [['t_wd', 'wd_key'], ['t_wd', 'wd_a']] } } }, freshRoot(), []), 'Wide');
        expect(r2.ok).toBe(true);
        expect(warningsOf(r2).some(x => /COLLAPSED/i.test(x.Code ?? '')), 'no collapse warning when other columns are sent').toBe(false);
    });
});
