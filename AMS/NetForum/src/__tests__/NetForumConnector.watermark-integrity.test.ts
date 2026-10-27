import { describe, it, expect } from 'vitest';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { NetForumConnector } from '../NetForumConnector.js';
import {
    type SentCall, type World, type FakeObject, type LearnedFileView,
    errorOf, fetchObject, internals, isolateConnectorState, makeConnector, objOf, warningsOf,
} from './netforum-fake-xweb.js';

/**
 * Ported from scripts/smoke/netforum-watermark-integrity.mjs (harness shared with the own-table fallback port).
 *
 * The defect (a live tenant, 2026-10-14). The engine asks StableOrderingKey(object) once per map to decide "keyset
 * resume" vs "timestamp watermark", and NetForum answered from LastIntegrationID — set only by the first
 * FetchChanges — so the answer flipped within one run. Keyset maps nulled their date watermark and parked a GUID row
 * key on the watermark row (WatermarkType='Cursor'); a later timestamp-mode run sent `inv_change_date >= '<GUID>'`,
 * xWeb answered "Conversion failed when converting date and/or time", and the connector learned THAT as "this column
 * list breaks xWeb's SQL": 26 objects (Invoice, Payment, Address, IndividualEmail, …) refused on every run.
 */
describe('NetForumConnector — watermark integrity', () => {
    const { freshRoot } = isolateConnectorState();

    const GUID = 'd1f032ab-dae9-4392-9af6-5fec96826e0b';
    const invoiceDef = (): NonNullable<FakeObject['def']> => ({ MainTable: 'ac_invoice', KeyColumn: 'inv_key',
        Columns: [['ac_invoice', 'inv_key'], ['ac_invoice', 'inv_code'], ['ac_invoice', 'inv_change_date'], ['co_customer', 'cst_name_cp']] });

    it('(1) StableOrderingKey is null for a watermarked object, the key for one without a watermark', () => {
        const world: World = {
            Invoice: { def: invoiceDef(), wm: 'inv_change_date', pk: 'inv_key', mode: 'ok' },
            Lookup: { def: { MainTable: 'lk', KeyColumn: 'lk_key', Columns: [['lk', 'lk_key'], ['lk', 'lk_name']] }, pk: 'lk_key', mode: 'ok' },
        };
        const c = makeConnector(world, freshRoot(), []);
        internals(c).LastIntegrationID = 'I1';
        expect(c.StableOrderingKey('Invoice'), 'watermarked Invoice → null (the engine keeps its date watermark)').toBeNull();
        expect(c.StableOrderingKey('Lookup'), 'watermark-less Lookup → its key (keyset resume stays available)').toBe('lk_key');
    });

    it('(2) a GUID left on the watermark row reads the object without the watermark predicate, and says so', async () => {
        const world: World = { Invoice: { def: invoiceDef(), wm: 'inv_change_date', pk: 'inv_key', mode: 'conversion' } };
        const root = freshRoot();
        const calls: SentCall[] = [];
        const r = await fetchObject(makeConnector(world, root, calls), 'Invoice', GUID);
        expect(r.ok, `rows come back ${errorOf(r)}`).toBe(true);
        expect(calls, 'one request').toHaveLength(1);
        expect(calls[0].where, 'no `inv_change_date >= <GUID>` predicate was sent').not.toMatch(/>=/);
        expect(warningsOf(r).some(w => w.Code === 'WATERMARK_NOT_A_DATE' && /Invoice/.test(w.Message)),
            'a WATERMARK_NOT_A_DATE warning names the object and the value').toBe(true);
        expect(objOf(root, 'Invoice'), 'nothing is learned against the object').toEqual({});

        const calls2: SentCall[] = [];
        await fetchObject(makeConnector(world, freshRoot(), calls2), 'Invoice', '2026-10-12T10:34:44-05:00');
        expect(calls2.length).toBeGreaterThanOrEqual(1);
        expect(calls2[0].where, 'a real date watermark still sends its predicate').toMatch(/inv_change_date >= '20261012 10:34:00'/);
    });

    it('(3) "Conversion failed when converting date and/or time" does not mark the list unsendable', async () => {
        const world: World = { Invoice: { def: invoiceDef(), wm: 'inv_change_date', pk: 'inv_key', mode: 'conversion' } };
        const root = freshRoot();
        const calls: SentCall[] = [];
        const r = await fetchObject(makeConnector(world, root, calls), 'Invoice', '2026-10-12T10:34:44-05:00');
        expect(r.ok, 'the fetch fails loudly').toBe(false);
        expect(errorOf(r), '…naming the watermark').toMatch(/watermark/i);
        expect(errorOf(r)).toMatch(/Conversion failed/i);
        expect(objOf(root, 'Invoice').unsendable, 'the learned file holds NO unsendable verdict for Invoice').toBeFalsy();
        expect(objOf(root, 'Invoice').ownListUnsendable, '…nor ownListUnsendable').toBeFalsy();
        expect(calls, 'exactly one request (no learn rounds spent on it)').toHaveLength(1);

        world.Invoice.mode = 'ok';
        const calls2: SentCall[] = [];
        const r2 = await fetchObject(makeConnector(world, root, calls2), 'Invoice', '2026-10-12T10:34:44-05:00');
        expect(r2.ok, `the next call reads ${errorOf(r2)}`).toBe(true);
        expect(calls2, '…in one request').toHaveLength(1);
        expect(calls2[0].list, '…sending the FULL list again (joined column included)').toContain('cst_name_cp');
    });

    /**
     * xWeb's US-format datetimes ("9/9/2024 1:29:00 PM") are dates. A live tenant's MembershipChapter (2026-10-14):
     * its watermark was stored as "9/9/2024 1:29:00 PM". DateWatermarkLiteral took only ISO text, so every run dropped
     * the predicate and re-read the whole object; and the max watermark was picked by TEXT order, where "9/9/2024"
     * outranks "10/1/2024" and "12/31/2023".
     */
    it('(5) US-format datetimes: the predicate is sent, and the max watermark is the latest DATE (stored ISO)', async () => {
        const world: World = { MembershipChapter: {
            def: { MainTable: 'mb_membership_chapter', KeyColumn: 'mbc_key',
                Columns: [['mb_membership_chapter', 'mbc_key'], ['mb_membership_chapter', 'mbc_name'], ['mb_membership_chapter', 'mbr_change_date']] },
            wm: 'mbr_change_date', pk: 'mbc_key', mode: 'ok',
            values: { mbr_change_date: ['9/9/2024 1:29:00 PM', '12/31/2023 11:05:00 AM', '10/1/2024 9:00:00 PM'] },
        } };
        const calls: SentCall[] = [];
        const r = await fetchObject(makeConnector(world, freshRoot(), calls), 'MembershipChapter', '9/9/2024 1:29:00 PM');
        expect(r.ok, errorOf(r)).toBe(true);
        expect(calls).toHaveLength(1);
        expect(calls[0].where, 'the US-format watermark is sent as a date predicate (13:29, not dropped)').toMatch(/mbr_change_date >= '20240909 13:29:00'/);
        expect(warningsOf(r).some(w => w.Code === 'WATERMARK_NOT_A_DATE'), 'no WATERMARK_NOT_A_DATE warning for it').toBe(false);
        expect(r.ok && r.r.NewWatermarkValue, 'NewWatermarkValue is the latest DATE, as ISO').toBe('2024-10-01T21:00:00');

        const calls2: SentCall[] = [];
        const r2 = await fetchObject(makeConnector({ Invoice: { def: invoiceDef(), wm: 'inv_change_date', pk: 'inv_key', mode: 'ok',
            values: { inv_change_date: ['2026-10-12T10:34:44-05:00', '2026-09-01T08:00:00-05:00'] } } }, freshRoot(), calls2), 'Invoice', '2026-10-12T10:34:44-05:00');
        expect(r2.ok && r2.r.NewWatermarkValue, 'ISO values are untouched (Invoice keeps its offset form and its max)').toBe('2026-10-12T10:34:44-05:00');
    });

    it('(4) learned state survives a deploy: <mjapi>/state/netforum, carried over from the release dir once', async () => {
        expect(NetForumConnector.StateRootFor('/home/ec2-user/mjapi/releases/252d5254/apps/MJAPI'), 'a release cwd maps to <root>/state/netforum')
            .toBe('/home/ec2-user/mjapi/state/netforum');
        expect(NetForumConnector.StateRootFor('/tmp/x'), 'any other cwd keeps the old place (null)').toBeNull();

        const legacy = freshRoot();
        writeFileSync(join(legacy, '.nf-learned.json'), JSON.stringify({ version: 2, connections: { CI1: { objects: { invoice: { unsendable: true, ownListUsable: true } } } } }));
        const state = join(freshRoot(), 'state', 'netforum');
        NetForumConnector.LearnedRoot = state;   // restored by the harness afterEach

        const world: World = { Invoice: { def: invoiceDef(), wm: 'inv_change_date', pk: 'inv_key', mode: 'joinedBreaks' } };
        const calls: SentCall[] = [];
        const r = await fetchObject(makeConnector(world, legacy, calls), 'Invoice', '2026-10-12T10:34:44-05:00');
        expect(r.ok, `the release-dir file is read when the state file does not exist yet ${errorOf(r)}`).toBe(true);
        expect(calls, '…the own list is sent directly').toHaveLength(1);
        expect(calls[0].list).not.toContain('cst_name_cp');

        const c2 = makeConnector({ Ghost: { def: invoiceDef(), wm: 'inv_change_date', pk: 'inv_key', mode: 'allBreaks' } }, legacy, []);
        await fetchObject(c2, 'Ghost', '2026-10-12T10:34:44-05:00');
        const statePath = join(state, '.nf-learned.json');
        expect(existsSync(statePath), 'a learn writes to the state dir (created)').toBe(true);
        const saved = JSON.parse(readFileSync(statePath, 'utf8')) as LearnedFileView;
        expect(saved.connections?.CI1?.objects?.invoice?.ownListUsable, '…and carries the release-dir facts with it').toBe(true);
        expect(saved.connections?.CI1?.objects?.ghost, '…alongside the new learn').toBeDefined();
    });
});
