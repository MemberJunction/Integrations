import { describe, it, expect } from 'vitest';
import { NetForumConnector } from '../NetForumConnector.js';
import {
    type SentCall, type World, type FakeObject,
    errorOf, fetchObject, isolateConnectorState, makeConnector, warningsOf,
} from './netforum-fake-xweb.js';

/**
 * The defect (a live tenant, 2026-10-29). A netFORUM list definition says how each table is joined
 * (`<lsf_from_join_type>`: 'Join' or 'Left Join'). Individual INNER-joins ce_course_participant, np_constituent and
 * co_email_optout; Organization INNER-joins co_related_association behind a LEFT join. Naming any of their columns
 * keeps only the individuals who took a course AND are donors AND opted out of email: the full list read 0 rows for
 * the 364 individuals added since 09-25, while a list of Individual's own columns read all 55,988.
 *
 * An INNER join is kept only when it is a lookup — the joined table's own `<prefix>_key` equated to a column of a
 * table always present (the main table, or another such lookup): co_customer, ev_event. Any other INNER join, and
 * anything joined through one, can drop rows, so its columns are left out of the full list (and the read says so).
 */
describe('NetForumConnector — joins that drop rows are left out of the full list', () => {
    const { freshRoot } = isolateConnectorState();

    const individualDef = (): NonNullable<FakeObject['def']> => ({
        MainTable: 'co_individual', KeyColumn: 'ind_cst_key',
        Columns: [
            ['co_individual', 'ind_cst_key'], ['co_individual', 'ind_first_name'], ['co_individual', 'ind_add_date'],
            ['co_customer', 'cst_key'], ['co_customer', 'cst_eml_address_dn'], ['co_customer', 'cst_change_date'], ['co_customer', 'cst_add_date'],
            ['co_address', 'adr_key'], ['co_address', 'adr_city'],
            ['ce_course_participant', 'cup_key'], ['ce_course_participant', 'cup_cst_key'], ['ce_course_participant', 'cup_grade'],
            ['ce_course_event', 'cec_key'], ['ce_course_event', 'cec_name'],
            ['np_constituent', 'dnr_cst_key'], ['np_constituent', 'dnr_type'],
            ['co_email_optout', 'emo_key'], ['co_email_optout', 'emo_cst_key'], ['co_email_optout', 'emo_reason'],
            // Extender columns: listed under their from-table, mdc_table_name the `_ext` table (see `ext`).
            ['co_individual', 'ind_custom_tier'], ['np_constituent', 'dnr_custom_flag'], ['co_email_optout', 'emo_key_ext'],
        ],
        ext: { ind_custom_tier: 'co_individual_ext', dnr_custom_flag: 'np_constituent_ext', emo_key_ext: 'co_email_optout_ext' },
        joins: {
            co_customer: { type: 'Join', on: 'cst_key=ind_cst_key and ind_delete_flag=0 and ind_deceased_flag=0' },
            co_address: { type: 'Left Join', on: 'adr_key=cst_cxa_key' },
            ce_course_participant: { type: 'Join', on: 'ind_cst_key=cup_cst_key' },
            ce_course_event: { type: 'Left Join', on: 'cup_cec_key=cec_key' },
            np_constituent: { type: 'Join', on: 'cst_key = dnr_cst_key and dnr_delete_flag = 0' },
            co_email_optout: { type: 'Join', on: 'emo_cst_key=cst_key' },
        },
    });
    const WM = '2026-10-12T08:00:00-05:00';
    const leftOut = (o: Awaited<ReturnType<typeof fetchObject>>) => warningsOf(o).find(w => w.Code === 'ROW_FILTERING_JOINS_LEFT_OUT');

    it('(1) Individual: the optional INNER joins (and what hangs off them) are left out; lookups and LEFT joins stay', async () => {
        const world: World = { Individual: { def: individualDef(), wm: 'cst_change_date', pk: 'ind_cst_key', mode: 'ok' } };
        const calls: SentCall[] = [];
        const r = await fetchObject(makeConnector(world, freshRoot(), calls), 'Individual', WM);
        expect(r.ok, errorOf(r)).toBe(true);
        const list = calls[0].list;
        for (const kept of ['co_individual.ind_first_name', 'co_customer.cst_eml_address_dn', 'co_customer.cst_change_date', 'co_address.adr_city']) {
            expect(list, `${kept} is sent`).toContain(kept);
        }
        for (const gone of ['cup_grade', 'cup_key', 'cec_name', 'dnr_type', 'emo_reason']) {
            expect(list, `${gone} is not sent (its table would drop rows)`).not.toContain(gone);
        }
        // Live, 2026-10-29: with the three tables' own columns left out but their Extender columns still named, xWeb
        // joined the tables back in and returned 0 rows; leaving those out too returned a full page.
        for (const gone of ['dnr_custom_flag', 'emo_key_ext']) {
            expect(list, `${gone} (an Extender column under a row-dropping join) is not sent`).not.toContain(gone);
        }
        expect(list, 'an Extender column of the main table stays').toContain('co_individual_ext.ind_custom_tier');
        const w = leftOut(r);
        expect(w, 'the read says which tables it left out').toBeDefined();
        for (const t of ['ce_course_participant', 'ce_course_event', 'np_constituent', 'co_email_optout']) expect(w!.Message).toContain(t);
        expect(w!.Message).not.toContain('co_customer');
    });

    it('(2) Organization: an INNER lookup behind a LEFT join can drop rows; the aliased co_customer lookup cannot', async () => {
        const world: World = { Organization: { def: {
            MainTable: 'co_organization', KeyColumn: 'org_cst_key',
            Columns: [
                ['co_organization', 'org_cst_key'], ['co_organization', 'org_name'],
                ['co_customer', 'cst_key', 'org_customer'], ['co_customer', 'cst_change_date', 'org_customer'],
                ['co_customer_x_related_association', 'rca_key'], ['co_customer_x_related_association', 'rca_rla_key'],
                ['co_related_association', 'rla_key'], ['co_related_association', 'rla_name'],
            ],
            joins: {
                org_customer: { type: 'Join', on: 'org_customer.cst_key=org_cst_key and org_delete_flag = 0' },
                co_customer_x_related_association: { type: 'Left Join', on: 'org_cst_key=rca_cst_key and rca_delete_flag = 0' },
                co_related_association: { type: 'Join', on: 'rca_rla_key = rla_key and rla_delete_flag = 0' },
            },
        }, wm: 'cst_change_date', pk: 'org_cst_key', mode: 'ok' } };
        const calls: SentCall[] = [];
        const r = await fetchObject(makeConnector(world, freshRoot(), calls), 'Organization', WM);
        expect(r.ok, errorOf(r)).toBe(true);
        expect(calls[0].list).toContain('org_customer.cst_change_date');
        expect(calls[0].list, 'the LEFT-joined cross table itself stays').toContain('co_customer_x_related_association.rca_rla_key');
        expect(calls[0].list).not.toContain('rla_name');
        expect(leftOut(r)?.Message).toContain('co_related_association');
    });

    it('(3) EventsRegistrant: INNER lookups by their own key (Customer, ev_event) stay, and nothing is reported', async () => {
        const world: World = { EventsRegistrant: { def: {
            MainTable: 'ev_registrant', KeyColumn: 'reg_key',
            Columns: [
                ['ev_registrant', 'reg_key', 'Registrant'], ['ev_registrant', 'reg_evt_key', 'Registrant'], ['ev_registrant', 'reg_change_date', 'Registrant'],
                ['co_customer', 'cst_key', 'Customer'], ['co_customer', 'cst_name_cp', 'Customer'],
                ['ev_event', 'evt_key'], ['ev_event', 'evt_code'],
            ],
            joins: {
                Customer: { type: 'Join', on: 'Registrant.reg_cst_key=Customer.cst_key and Customer.cst_delete_flag=0 and Registrant.reg_delete_flag=0' },
                ev_event: { type: 'Join', on: 'Registrant.reg_evt_key=evt_key' },
            },
        }, wm: 'reg_change_date', pk: 'reg_key', mode: 'ok' } };
        const calls: SentCall[] = [];
        const r = await fetchObject(makeConnector(world, freshRoot(), calls), 'EventsRegistrant', WM);
        expect(r.ok, errorOf(r)).toBe(true);
        expect(calls[0].list).toContain('Customer.cst_name_cp');
        expect(calls[0].list).toContain('ev_event.evt_code');
        expect(leftOut(r)).toBeUndefined();
    });

    it('(4) a definition that states no join types (older netFORUM) is read as before', async () => {
        const def = individualDef();
        for (const j of Object.values(def.joins!)) delete j.type;
        const calls: SentCall[] = [];
        const r = await fetchObject(makeConnector({ Individual: { def, wm: 'cst_change_date', pk: 'ind_cst_key', mode: 'ok' } }, freshRoot(), calls), 'Individual', WM);
        expect(r.ok, errorOf(r)).toBe(true);
        expect(calls[0].list).toContain('cup_grade');
        expect(leftOut(r)).toBeUndefined();
    });

    it('(5) the read\'s own key / watermark on a row-dropping table is still sent', async () => {
        const def = individualDef();
        const calls: SentCall[] = [];
        const r = await fetchObject(makeConnector({ Individual: { def, wm: 'dnr_type', pk: 'ind_cst_key', mode: 'ok' } }, freshRoot(), calls), 'Individual', WM);
        expect(r.ok, errorOf(r)).toBe(true);
        expect(calls[0].list, 'the watermark is protected').toContain('dnr_type');
        expect(calls[0].list).not.toContain('emo_reason');
    });

    it('(6) <lsf_from_join_type> is parsed from the definition', () => {
        const xml = `<GetQueryDefinitionResult><ListTable><lst_mdt_name>co_individual</lst_mdt_name><ListFromTables>
            <ListFromTable><lsf_from_table>co_individual</lsf_from_table><Columns><Column><mdc_name>ind_cst_key</mdc_name><mdc_table_name>co_individual</mdc_table_name></Column></Columns></ListFromTable>
            <ListFromTable><lsf_from_table>np_constituent</lsf_from_table><lsf_from_join_type>Join</lsf_from_join_type><lsf_from_join>cst_key = dnr_cst_key</lsf_from_join><Columns><Column><mdc_name>dnr_type</mdc_name><mdc_table_name>np_constituent</mdc_table_name></Column></Columns></ListFromTable>
            <ListFromTable><lsf_from_table>co_address</lsf_from_table><lsf_from_join_type>Left Join</lsf_from_join_type><lsf_from_join>adr_key=cst_cxa_key</lsf_from_join><Columns><Column><mdc_name>adr_city</mdc_name><mdc_table_name>co_address</mdc_table_name></Column></Columns></ListFromTable>
            </ListFromTables></ListTable></GetQueryDefinitionResult>`;
        const parse = (new NetForumConnector() as unknown as { ParseQueryDefinition(x: string): { FromTables: Array<{ Table: string; Join: string; JoinType: string }> } }).ParseQueryDefinition(xml);
        expect(parse.FromTables.map(f => [f.Table, f.JoinType, f.Join])).toEqual([
            ['co_individual', '', ''],
            ['np_constituent', 'Join', 'cst_key = dnr_cst_key'],
            ['co_address', 'Left Join', 'adr_key=cst_cxa_key'],
        ]);
    });
});
