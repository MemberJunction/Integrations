import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

// ─── Shipped catalog: the four slugs NetSuite refuses must stay retired ────────────────────────
//
// The Declared catalog was authored by camel-collapsing NetSuite's UI labels into record-type
// slugs. For four objects the label and the real record-type id diverge, so FetchChanges'
// `SELECT * FROM <slug>` fails on every account, on every run, with HTTP 400
// `Invalid search type: <slug>` (INVALID_PARAMETER) — the object can never sync. These tests read
// the SHIPPED metadata AND the delta migration (both dialects) so the two cannot drift: metadata
// alone reaches no tenant, and a migration alone would be undone by the next `mj sync push`.
//
// NOT covered here, deliberately: objects that fail with `Record 'x' was not found`. That is a
// real record type the ACCOUNT has not enabled (the connector reports it as OBJECT_UNAVAILABLE)
// and it syncs the moment the feature is turned on — it must stay Active.

const __dirname = dirname(fileURLToPath(import.meta.url));
const CONNECTOR_ROOT = join(__dirname, '..', '..');
const SHIPPED_METADATA = join(CONNECTOR_ROOT, 'metadata', 'integration', '.netsuite.integration.json');
const DELTA_SS = join(CONNECTOR_ROOT, 'migrations', 'V202609082300__netsuite__RetireInvalidSuiteQLTypes.sql');
const DELTA_PG = join(CONNECTOR_ROOT, 'migrations-pg', 'V202609082300__netsuite__RetireInvalidSuiteQLTypes.pg.sql');

interface ShippedObject {
    fields: { Name: string; Status: string; Description?: string; Configuration?: { suiteQLTable?: string } };
    primaryKey: { ID: string };
}
const shipped = JSON.parse(readFileSync(SHIPPED_METADATA, 'utf8')) as Array<{
    relatedEntities: { 'MJ: Integration Objects': ShippedObject[] };
}>;
const objects = shipped[0].relatedEntities['MJ: Integration Objects'];

/** Declared name → the dead slug it names, and the record-type id NetSuite actually has. */
const INVALID_SUITEQL_TYPES: Record<string, { dead: string; real: string }> = {
    'Requisition': { dead: 'requisition', real: 'purchaserequisition' },
    'Weekly Timesheet': { dead: 'weeklytimesheet', real: 'timesheet' },
    'Bin Putaway Worksheet': { dead: 'binputawayworksheet', real: 'binworksheet' },
    'Advanced Intercompany Journal Entry': { dead: 'advancedintercompanyjournalentry', real: 'advintercompanyjournalentry' },
};

describe('NetSuite shipped catalog — the four invalid SuiteQL types are retired', () => {
    it('each of the four is Disabled and says why, and still declares the dead slug it was retired for', () => {
        for (const [name, { dead, real }] of Object.entries(INVALID_SUITEQL_TYPES)) {
            const obj = objects.find(o => o.fields.Name === name);
            expect(obj, `${name} missing from the shipped catalog`).toBeDefined();
            // Not deleted and not remapped: installed tenants hold these rows (with derived
            // entities behind them), and remapping onto the real slug would put a second object
            // over one table — discovery already surfaces the real type from the account.
            expect(obj!.fields.Configuration?.suiteQLTable).toBe(dead);
            expect(obj!.fields.Status).toBe('Disabled');
            expect(obj!.fields.Description ?? '').toContain('Invalid search type');
            expect(obj!.fields.Description ?? '').toContain(real);
        }
    });

    it('NOTHING ELSE was retired — every other declared object stays Active', () => {
        // The blast radius of this change is exactly four rows. In particular no object that
        // merely fails `Record 'x' was not found` (feature-gated per account) may be caught here.
        const retired = objects.filter(o => o.fields.Status !== 'Active').map(o => o.fields.Name).sort();
        expect(retired).toEqual(Object.keys(INVALID_SUITEQL_TYPES).sort());
    });

    it('the delta migration retires exactly the same four rows, by their seeded IDs, in BOTH dialects', () => {
        const ss = readFileSync(DELTA_SS, 'utf8');
        const pg = readFileSync(DELTA_PG, 'utf8');
        const idsInMetadata = Object.keys(INVALID_SUITEQL_TYPES)
            .map(n => objects.find(o => o.fields.Name === n)!.primaryKey.ID)
            .sort();

        for (const sql of [ss, pg]) {
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
});
