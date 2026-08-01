#!/usr/bin/env node
/**
 * lint-catalog-completeness.mjs — every object a connector DECLARES must actually
 * be SEEDED by that connector's migrations.
 *
 * THE BUG CLASS this guards. `metadata/` is the AUTHORING layer. Tenants never
 * read it — they receive catalog rows exclusively from `migrations/`, and an
 * upgrade applies only files it has not seen. So a connector whose metadata grows
 * without a matching migration ships a catalog the customer never gets. The
 * connector installs, TestConnection passes, sync runs green — against a fraction
 * of its objects. Nothing anywhere reports the shortfall.
 *
 * Constant Contact shipped exactly this. Its v2.0.0 redo grew the catalog from
 * 8 objects to 65 (531 fields) and shipped no migration, so every tenant would
 * have installed 8 of 65 objects — 12% of the connector — and been told nothing.
 *
 * WHY THE EXISTING GATES MISSED IT. `require-metadata-migration.mjs` asks "did
 * this PR touch metadata without adding a migration" — a DELTA question, so it
 * cannot see an absolute gap that already exists on the branch. `check-catalog-
 * freshness.mjs` covers connectors-catalog.json (version resolution), a different
 * artifact entirely. This gate asks the absolute question the other two don't:
 * does the shipped migration set actually contain everything the metadata claims?
 *
 * ── HOW IT COMPARES ───────────────────────────────────────────────────────────
 * Objects are matched BY NAME, not by count, so a rename can't net out to zero.
 * The generated SQL declares each record's params with a shared hash suffix —
 *
 *     SET @Name_4d88bd56 = N'account_emails'
 *     EXEC [__mj].spCreateIntegrationObject @ID = @ID_4d88bd56, @Name = @Name_4d88bd56, ...
 *
 * so the EXEC's suffix resolves to its SET, and object names extract exactly.
 * Fields are compared by total count per connector — a name-level match would
 * need per-object scoping for little added signal, and a count mismatch already
 * pins the connector for a human to open.
 *
 * The comparison is DIRECTIONAL: it fails on declared-but-not-seeded only. Seeded
 * rows the metadata no longer declares (and the higher seeded field total that
 * comes with them) are what a major REDO correctly looks like — it drops objects
 * from the catalog and soft-deprecates the seeded rows in a delta migration rather
 * than pruning them, since installed tenants still have them. A rename, the case
 * that motivated matching by name, still fails: the new name is not seeded.
 *
 * Connectors with zero declared objects (the raw database connectors —
 * SQLServer, Postgres, MongoDB, Snowflake, …) discover their schema at runtime
 * and are skipped rather than special-cased: nothing declared, nothing to seed.
 */
import { readFileSync, readdirSync, statSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const FAMILIES = ['AMS', 'CRM', 'Events', 'Finance', 'LMS', 'Marketing', 'Platform'];

/** Declared objects + field total from a connector's metadata tree. */
function readDeclared(metadataDir) {
  const objectNames = new Set();
  let fieldCount = 0;
  const walk = (dir) => {
    for (const entry of readdirSync(dir)) {
      const p = join(dir, entry);
      if (statSync(p).isDirectory()) {
        walk(p);
      } else if (entry.endsWith('.integration.json')) {
        const parsed = JSON.parse(readFileSync(p, 'utf-8'));
        const record = Array.isArray(parsed) ? parsed[0] : parsed;
        for (const obj of record?.relatedEntities?.['MJ: Integration Objects'] ?? []) {
          if (obj.fields?.Name) objectNames.add(obj.fields.Name);
          fieldCount += obj.relatedEntities?.['MJ: Integration Object Fields']?.length ?? 0;
        }
      }
    }
  };
  walk(metadataDir);
  return { objectNames, fieldCount };
}

/** Objects + field total actually seeded across a connector's migrations. */
function readSeeded(migrationsDir) {
  const objectNames = new Set();
  let fieldCount = 0;
  if (!existsSync(migrationsDir)) return { objectNames, fieldCount };
  for (const entry of readdirSync(migrationsDir)) {
    if (!entry.endsWith('.sql')) continue;
    const sql = readFileSync(join(migrationsDir, entry), 'utf-8');

    // Map every `SET @Name_<hash> = N'value'` so an EXEC's suffix resolves to its name.
    const namesByHash = new Map();
    for (const m of sql.matchAll(/@Name_([a-f0-9]+)\s*=\s*N'((?:[^']|'')*)'/g)) {
      namesByHash.set(m[1], m[2].replace(/''/g, "'"));
    }
    for (const m of sql.matchAll(/spCreateIntegrationObject\s*@ID\s*=\s*@ID_([a-f0-9]+)/g)) {
      const name = namesByHash.get(m[1]);
      if (name) objectNames.add(name);
    }
    fieldCount += (sql.match(/spCreateIntegrationObjectField\s*@/g) ?? []).length;
  }
  return { objectNames, fieldCount };
}

const problems = [];
for (const family of FAMILIES) {
  const familyDir = join(ROOT, family);
  if (!existsSync(familyDir)) continue;
  for (const connector of readdirSync(familyDir)) {
    const dir = join(familyDir, connector);
    const metadataDir = join(dir, 'metadata');
    if (!existsSync(metadataDir) || !statSync(dir).isDirectory()) continue;

    const declared = readDeclared(metadataDir);
    // Runtime-schema connectors declare nothing; there is nothing to seed.
    if (declared.objectNames.size === 0 && declared.fieldCount === 0) continue;

    const seeded = readSeeded(join(dir, 'migrations'));
    const missing = [...declared.objectNames].filter((n) => !seeded.objectNames.has(n)).sort();
    const orphaned = [...seeded.objectNames].filter((n) => !declared.objectNames.has(n)).sort();
    const fieldGap = declared.fieldCount - seeded.fieldCount;

    // DIRECTIONAL on purpose: fail only when the metadata declares MORE than the migrations
    // ship. The reverse — seeded rows the metadata no longer declares, and therefore a seeded
    // field total above the declared one — is what a major REDO correctly looks like: it drops
    // objects from the catalog and soft-deprecates the seeded rows (Status='Deprecated') in a
    // delta migration rather than pruning them, because installed tenants still have them.
    // QuickBooks 2.0.0 is exactly that shape (39 declared / 92 seeded, 53 deprecated), so an
    // `orphaned.length || fieldGap !== 0` test would have failed every future REDO. A RENAME,
    // the case that motivated matching by name, still fails here: the new name is missing.
    if (missing.length || fieldGap > 0) {
      problems.push({ connector: `${family}/${connector}`, missing, orphaned, fieldGap, declared, seeded });
    }
  }
}

if (problems.length === 0) {
  console.log('✓ catalog-completeness gate: every declared object is seeded by a migration.');
  process.exit(0);
}

console.error(`\n✗ ${problems.length} connector(s) declare a catalog their migrations do not ship:\n`);
for (const p of problems) {
  console.error(`  ${p.connector}`);
  console.error(
    `    objects: ${p.declared.objectNames.size} declared / ${p.seeded.objectNames.size} seeded` +
      `    fields: ${p.declared.fieldCount} declared / ${p.seeded.fieldCount} seeded`
  );
  if (p.missing.length) {
    const shown = p.missing.slice(0, 12);
    console.error(`    NOT SEEDED (${p.missing.length}): ${shown.join(', ')}${p.missing.length > shown.length ? ', …' : ''}`);
  }
  if (p.orphaned.length) {
    // Context, not the failure: seeded-but-undeclared is the normal residue of a REDO.
    const shown = p.orphaned.slice(0, 12);
    console.error(`    (also seeded but not declared, not itself a failure — ${p.orphaned.length}): ${shown.join(', ')}${p.orphaned.length > shown.length ? ', …' : ''}`);
  }
}
console.error(
  '\n  Tenants receive catalog rows ONLY from migrations/ — metadata/ is the authoring\n' +
    '  layer and is never read at install time. A connector in this list installs with\n' +
    '  fewer objects than it declares, passes TestConnection, and syncs green against\n' +
    '  the subset. Constant Contact would have shipped 8 of its 65 objects this way.\n\n' +
    '  Fix: regenerate the seed migration against a baselined generation DB —\n' +
    '      node scripts/build-seed-migrations.mjs <Family>/<Connector>\n' +
    '  which emits both dialects and writes primaryKey/sync back into the metadata.'
);
process.exit(1);
