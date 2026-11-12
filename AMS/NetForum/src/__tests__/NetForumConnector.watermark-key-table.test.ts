import { describe, it, expect } from 'vitest';
import { writeFileSync } from 'node:fs';
import { join } from 'node:path';
import {
    type SentCall, type World, type FakeObject, type FetchOutcome,
    errorOf, fetchObject, isolateConnectorState, makeConnector, warningsOf,
} from './netforum-fake-xweb.js';

/**
 * The defect (a live tenant, 2026-11-11). Two objects keyed on ev_registrant.reg_key carry a watermark of a JOINED
 * table, ev_registration_dem.rdm_change_date. Fewer than 0.1% of registrations have a row there, so the incremental
 * read (`rdm_change_date >= X`, with or without rdm_add_date) matched almost none and no new registration was read after
 * the initial load. A third object (AddressChangeLog) read 0 rows each night with its change-date predicate alone, and
 * nothing in the run said why its add date was not sent.
 *
 * A watermark on a table other than the key's also reads the rows changed or added on the KEY's table, and says so; a
 * change-date watermark sent without its add date says why.
 */
describe('NetForumConnector — a watermark on a joined table, and an add date that is not sent', () => {
    const { freshRoot, warned } = isolateConnectorState();

    const RDM = 'ev_registration_dem';
    const REG = 'ev_registrant';
    const orderEntryDef = (): NonNullable<FakeObject['def']> => ({ MainTable: RDM, KeyColumn: 'rdm_key', Columns: [
        [RDM, 'rdm_key'], [RDM, 'rdm_change_date'], [RDM, 'rdm_add_date'], [RDM, 'rdm_answer'],
        [REG, 'reg_key'], [REG, 'reg_evt_key'], [REG, 'reg_add_date'], [REG, 'reg_change_date'],
    ] });
    const orderEntry = (extra: Partial<FakeObject> = {}): World => ({
        EventRegistrationOrderEntry: { def: orderEntryDef(), pk: 'reg_key', wm: 'rdm_change_date', mode: 'ok', ...extra },
    });
    const WM = '2026-10-13T16:50:39-05:00';
    const S = "'20261013 16:50:00'";
    const warningOf = (o: FetchOutcome, code: string) => warningsOf(o).find(w => w.Code === code);

    /** The tenant's learned state for the registration objects: the full list broke xWeb's SQL, the own-table list reads. */
    const seedOwnListUsable = (root: string, object: string): void => {
        writeFileSync(join(root, '.nf-learned.json'), JSON.stringify({ version: 2, connections: { CI1: { objects: {
            [object.toLowerCase()]: { unsendable: true, ownListUsable: true },
        } } } }));
    };

    it("(1) own-table read: the key table's change and add dates are ORed with the joined table's watermark", async () => {
        const root = freshRoot();
        seedOwnListUsable(root, 'EventRegistrationOrderEntry');
        const calls: SentCall[] = [];
        const r = await fetchObject(makeConnector(orderEntry(), root, calls), 'EventRegistrationOrderEntry', WM);
        expect(r.ok, errorOf(r)).toBe(true);
        expect(calls).toHaveLength(1);
        expect(calls[0].list, 'the own-table list').not.toContain('rdm_answer');
        expect(calls[0].where).toBe(
            `(${RDM}.rdm_change_date >= ${S} OR ${REG}.reg_change_date >= ${S} OR ${REG}.reg_add_date >= ${S})`);
    });

    it('(2) full read: the watermark, its add date, and the key table\'s change and add dates', async () => {
        const calls: SentCall[] = [];
        const r = await fetchObject(makeConnector(orderEntry(), freshRoot(), calls), 'EventRegistrationOrderEntry', WM);
        expect(r.ok, errorOf(r)).toBe(true);
        expect(calls[0].where).toBe(`(${RDM}.rdm_change_date >= ${S} OR ${RDM}.rdm_add_date >= ${S} OR ` +
            `${REG}.reg_change_date >= ${S} OR ${REG}.reg_add_date >= ${S})`);
        expect(warningOf(r, 'WATERMARK_ADD_DATE_NOT_SENT'), 'rdm_add_date is sent').toBeUndefined();
    });

    it('(3) registrations with no row on the joined table advance the watermark by their own add date', async () => {
        const root = freshRoot();
        seedOwnListUsable(root, 'EventRegistrationOrderEntry');
        const world = orderEntry({ values: {
            rdm_change_date: ['', '', ''],
            reg_change_date: ['', '', ''],
            reg_add_date: ['2026-11-02T09:00:00', '2026-11-05T16:00:00', '2026-11-03T10:00:00'],
        } });
        const r = await fetchObject(makeConnector(world, root, []), 'EventRegistrationOrderEntry', WM);
        expect(r.ok, errorOf(r)).toBe(true);
        expect(r.ok && r.r.NewWatermarkValue, 'the latest registration add date').toBe('2026-11-05T16:00:00');
    });

    it('(4) a watermark on a joined table is reported on every batch and logged once', async () => {
        const c = makeConnector(orderEntry(), freshRoot(), []);
        const first = await fetchObject(c, 'EventRegistrationOrderEntry', WM);
        const second = await fetchObject(c, 'EventRegistrationOrderEntry', WM);
        for (const r of [first, second]) {
            const w = warningOf(r, 'WATERMARK_NOT_ON_KEY_TABLE');
            expect(w, errorOf(r)).toBeDefined();
            expect(w!.Data).toMatchObject({ WatermarkTable: RDM, KeyTable: REG, KeyTableDates: ['reg_change_date', 'reg_add_date'] });
        }
        expect(warned.filter(m => m.includes('EventRegistrationOrderEntry') && m.includes(REG))).toHaveLength(1);
    });

    // ── AddressChangeLog: the add date is not sent, and the read says why ──────────────────────────────────────────

    const ACL = 'co_address_change_log';
    const aclColumns = (): Array<[string, string]> => [
        [ACL, 'acl_key'], [ACL, 'acl_adr_key'], [ACL, 'acl_add_date'], [ACL, 'acl_change_date'], [ACL, 'acl_reason'],
    ];
    const addressChangeLog = (o: Partial<FakeObject>): World => ({
        AddressChangeLog: { pk: 'acl_key', wm: 'acl_change_date', mode: 'ok', ...o },
    });
    const gapOf = async (world: World): Promise<Record<string, unknown> | undefined> => {
        const r = await fetchObject(makeConnector(world, freshRoot(), []), 'AddressChangeLog', WM);
        expect(r.ok, errorOf(r)).toBe(true);
        return warningOf(r, 'WATERMARK_ADD_DATE_NOT_SENT')?.Data as Record<string, unknown> | undefined;
    };

    it('(5) no definition: the reason says so', async () => {
        const gap = await gapOf(addressChangeLog({ defaultCols: ['acl_key', 'acl_add_date', 'acl_change_date'] }));
        expect(gap).toMatchObject({ WatermarkField: 'acl_change_date', AddDateField: 'acl_add_date', Reason: 'no-definition' });
    });

    it('(6) a definition without the add date: the reason says so', async () => {
        const gap = await gapOf(addressChangeLog({ def: { MainTable: ACL, KeyColumn: 'acl_key',
            Columns: aclColumns().filter(([, n]) => n !== 'acl_add_date') } }));
        expect(gap).toMatchObject({ Reason: 'not-defined' });
    });

    it('(7) a declared Configuration.columnList without the add date: the reason names the list', async () => {
        const gap = await gapOf(addressChangeLog({ def: { MainTable: ACL, KeyColumn: 'acl_key', Columns: aclColumns() },
            config: { columnList: ['acl_key', 'acl_reason'] } }));
        expect(gap).toMatchObject({ Reason: 'not-in-list', List: 'declared' });
    });

    it('(8) the add date left out of the full list by a join that drops rows: the reason names the join', async () => {
        const gap = await gapOf(addressChangeLog({ def: { MainTable: 'co_address', KeyColumn: 'adr_key',
            Columns: [['co_address', 'adr_key'], ['co_address', 'adr_city'], ...aclColumns()],
            joins: { [ACL]: { type: 'Join', on: 'acl_adr_key = adr_key' } } } }));
        expect(gap).toMatchObject({ Reason: 'not-in-list', List: 'full' });
        expect(String(gap?.Detail)).toContain(ACL);
    });

    it('(9) the add-date warning is logged once per object, and reported on every batch', async () => {
        const world = addressChangeLog({ def: { MainTable: ACL, KeyColumn: 'acl_key',
            Columns: aclColumns().filter(([, n]) => n !== 'acl_add_date') } });
        const c = makeConnector(world, freshRoot(), []);
        const first = await fetchObject(c, 'AddressChangeLog', WM);
        const second = await fetchObject(c, 'AddressChangeLog', WM);
        expect(warningOf(first, 'WATERMARK_ADD_DATE_NOT_SENT')).toBeDefined();
        expect(warningOf(second, 'WATERMARK_ADD_DATE_NOT_SENT')).toBeDefined();
        expect(warned.filter(m => m.includes('AddressChangeLog') && m.includes('acl_add_date'))).toHaveLength(1);
    });
});
