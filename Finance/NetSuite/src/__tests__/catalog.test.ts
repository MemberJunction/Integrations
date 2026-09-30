import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

// ─── Shipped catalog: the slugs NetSuite refuses must stay retired ─────────────────────────────
//
// The Declared catalog was authored by camel-collapsing NetSuite's UI labels into record-type
// slugs. Where the label and the real record-type id diverge, FetchChanges' `SELECT * FROM <slug>`
// fails on every account, on every run, with HTTP 400 `Invalid search type: <slug>`
// (INVALID_PARAMETER) — the object can never sync, yet it ships Active, is auto-mapped, and spends
// a request, an error and a retry ladder per run, forever.
//
// These tests read the SHIPPED metadata AND the delta migrations (both dialects) so the two cannot
// drift: metadata alone reaches no tenant, and a migration alone would be undone by the next
// `mj sync push`.
//
// TWO WAVES, AND THEY ARE NOT THE SAME EVIDENCE. The first four were reproduced live on a customer
// account. The remaining twelve were identified by the same criterion — the slug is absent from
// NetSuite's own record.Type id set — without a live failure for each one. They are kept in
// separate constants, and in separate migrations, so that distinction stays visible to whoever
// reads this next.
//
// NOT covered here, deliberately: objects that fail with `Record 'x' was not found`. That is a
// real record type the ACCOUNT has not enabled (the connector reports it as OBJECT_UNAVAILABLE)
// and it syncs the moment the feature is turned on — it must stay Active.

const __dirname = dirname(fileURLToPath(import.meta.url));
const CONNECTOR_ROOT = join(__dirname, '..', '..');
const SHIPPED_METADATA = join(CONNECTOR_ROOT, 'metadata', 'integration', '.netsuite.integration.json');

interface ShippedObject {
    fields: { Name: string; Status: string; Description?: string; Configuration?: { suiteQLTable?: string } };
    primaryKey: { ID: string };
}
const shipped = JSON.parse(readFileSync(SHIPPED_METADATA, 'utf8')) as Array<{
    relatedEntities: { 'MJ: Integration Objects': ShippedObject[] };
}>;
const objects = shipped[0].relatedEntities['MJ: Integration Objects'];

/** Declared name → the dead slug it names, and the record-type id NetSuite actually has. */
type DeadType = { dead: string; real: string | null };

/** Wave 1 — reproduced live on a customer account. Retired by V202609082300. */
const CONFIRMED_LIVE: Record<string, DeadType> = {
    'Requisition': { dead: 'requisition', real: 'purchaserequisition' },
    'Weekly Timesheet': { dead: 'weeklytimesheet', real: 'timesheet' },
    'Bin Putaway Worksheet': { dead: 'binputawayworksheet', real: 'binworksheet' },
    'Advanced Intercompany Journal Entry': { dead: 'advancedintercompanyjournalentry', real: 'advintercompanyjournalentry' },
};

/**
 * Wave 2 — the same shape by the same criterion, without a per-object live failure. Retired by
 * V202609122100. `real: null` means no standard NetSuite record carries the id at all, so there is
 * nothing to remap to either.
 */
const IDENTIFIED_BY_CRITERION: Record<string, DeadType> = {
    'Class': { dead: 'class', real: 'classification' },
    'Event': { dead: 'event', real: 'calendarevent' },
    'Unit of Measure': { dead: 'unitofmeasure', real: 'unitstype' },
    'Tax Control Account': { dead: 'taxcontrolaccount', real: 'taxacct' },
    'GL Audit Numbering Sequence': { dead: 'glauditnumberingsequence', real: 'glnumberingsequence' },
    'Period End Journal Entry': { dead: 'periodendjournalentry', real: 'periodendjournal' },
    'Revenue Recognition Schedule': { dead: 'revenuerecognitionschedule', real: 'revrecschedule' },
    'Revenue Recognition Template': { dead: 'revenuerecognitiontemplate', real: 'revrectemplate' },
    'Other Charge for Purchase Item': { dead: 'otherchargeforpurchaseitem', real: 'otherchargepurchaseitem' },
    'Other Charge for Resale Item': { dead: 'otherchargeforresaleitem', real: 'otherchargeresaleitem' },
    'Other Charge for Sale Item': { dead: 'otherchargeforsaleitem', real: 'otherchargesaleitem' },
    'Change Order': { dead: 'changeorder', real: null },
};

const WAVES: Array<{ label: string; types: Record<string, DeadType>; ss: string; pg: string }> = [
    {
        label: 'confirmed live (V202609082300)',
        types: CONFIRMED_LIVE,
        ss: join(CONNECTOR_ROOT, 'migrations', 'V202609082300__netsuite__RetireInvalidSuiteQLTypes.sql'),
        pg: join(CONNECTOR_ROOT, 'migrations-pg', 'V202609082300__netsuite__RetireInvalidSuiteQLTypes.pg.sql'),
    },
    {
        label: 'identified by criterion (V202609122100)',
        types: IDENTIFIED_BY_CRITERION,
        ss: join(CONNECTOR_ROOT, 'migrations', 'V202609122100__netsuite__RetireRemainingInvalidSuiteQLTypes.sql'),
        pg: join(CONNECTOR_ROOT, 'migrations-pg', 'V202609122100__netsuite__RetireRemainingInvalidSuiteQLTypes.pg.sql'),
    },
];

const ALL_RETIRED = { ...CONFIRMED_LIVE, ...IDENTIFIED_BY_CRITERION };

/**
 * Genuine record types that a register of live failures ALSO listed. They are feature-gated in some
 * accounts (`Record 'x' was not found` = account-unavailability, which the connector already
 * reports as OBJECT_UNAVAILABLE) — not dead. Retiring them would drop real objects.
 */
const REAL_BUT_FEATURE_GATED = ['costcategory', 'department', 'expensereport', 'generaltoken', 'issue'];

describe('NetSuite shipped catalog — invalid SuiteQL types are retired', () => {
    it('each retired object is Disabled, says why, and still declares the dead slug it was retired for', () => {
        for (const [name, { dead, real }] of Object.entries(ALL_RETIRED)) {
            const obj = objects.find(o => o.fields.Name === name);
            expect(obj, `${name} missing from the shipped catalog`).toBeDefined();
            // Not deleted and not remapped: installed tenants hold these rows (with derived
            // entities behind them), and remapping onto the real slug would put a second object
            // over one table — discovery already surfaces the real type from the account.
            expect(obj!.fields.Configuration?.suiteQLTable).toBe(dead);
            expect(obj!.fields.Status).toBe('Disabled');
            expect(obj!.fields.Description ?? '').toContain('Invalid search type');
            if (real) expect(obj!.fields.Description ?? '').toContain(real);
        }
    });

    it('NOTHING ELSE was retired — every other declared object stays Active', () => {
        // The blast radius is exactly these rows. In particular no object that merely fails
        // `Record 'x' was not found` (feature-gated per account) may be caught here.
        const retired = objects.filter(o => o.fields.Status !== 'Active').map(o => o.fields.Name).sort();
        expect(retired).toEqual(Object.keys(ALL_RETIRED).sort());
    });

    it('the feature-gated record types stay Active — they sync as soon as the account enables them', () => {
        for (const slug of REAL_BUT_FEATURE_GATED) {
            const obj = objects.find(o => o.fields.Configuration?.suiteQLTable === slug);
            if (!obj) continue; // not every register entry is a declared object
            expect(obj.fields.Status, `${slug} is feature-gated, not dead`).toBe('Active');
        }
    });

    for (const { label, types, ss, pg } of WAVES) {
        it(`the ${label} migration retires exactly its own rows, by seeded ID, in BOTH dialects`, () => {
            const idsInMetadata = Object.keys(types)
                .map(n => objects.find(o => o.fields.Name === n)!.primaryKey.ID.toUpperCase())
                .sort();

            for (const sql of [readFileSync(ss, 'utf8'), readFileSync(pg, 'utf8')]) {
                const updatedIDs = [...sql.matchAll(/WHERE\s+\[?"?ID"?\]?\s*=\s*'([0-9A-Fa-f-]{36})'/g)]
                    .map(m => m[1].toUpperCase())
                    .sort();
                // Same rows, no more and no fewer — metadata and migration cannot drift apart.
                expect(updatedIDs).toEqual(idsInMetadata);
                expect(sql).toContain("'Disabled'");
                // A delta, never a re-seed: re-minting a seeded row would break the Flyway checksum
                // of V202606271402 and collide on UQ_IntegrationObject_Name.
                expect(sql).not.toMatch(/spCreateIntegrationObject/);
                expect(sql).not.toMatch(/\bDELETE\s+FROM\b/i);
            }
        });
    }
});
