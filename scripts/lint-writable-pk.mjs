#!/usr/bin/env node
/**
 * lint-writable-pk.mjs — every ACTIVE object that declares fields must declare a primary key.
 *
 * Two scopes, two baselines, one rule.
 *
 * WRITABLE (SupportsWrite: true) — zero tolerance. An `MJ: Integration Object` whose fields
 * carry no `IsPrimaryKey: true` produces a derived entity with no primary key. On SQL Server
 * that mostly limps along; on **Postgres** MJ's save audit-wrapper builds an empty record
 * identifier and every save fails with
 *
 *     syntax error at or near ","
 *
 * Fetch still succeeds, so the connector looks healthy — nothing persists, and the failure is
 * per-save rather than per-run, so it reads as a data problem at the far end rather than a
 * metadata defect at this end. The HubSpot `hs_object_id` fix (#105) was one instance of this
 * class. The writable baseline (`writable-pk-baseline.json`) is empty and must stay empty.
 *
 * READ-ONLY (SupportsWrite: false) — ratcheted. An earlier version of this file said a
 * read-only keyless object "can't fail a save it never attempts" and left it alone. That
 * reasoning was incomplete: a synced object is written INTO MJ regardless of whether it
 * supports writing back to the vendor. A keyless read-only object therefore does one of two
 * things, neither of them free. Either the soft-PK classifier infers a key at discovery time,
 * which is work — including LLM inference — repeated per tenant per discovery on the stage that
 * has already exhausted memory and taken a workspace down on an 888-object catalog; or
 * inference fails and the object lands `entity.skipped-no-pk`, visible but never able to sync,
 * so the picker offers data that cannot arrive. Declaring the key removes both. The read-only
 * baseline (`readonly-pk-baseline.json`) is the debt register: 264 Active objects at seeding
 * (2026-09-22; a further 63 keyless objects were already Disabled and are exempt), concentrated
 * in YourMembership, Cvent, NeonCRM, ConstantContact, MagnetMail. Four of the 264 are OpenWater's
 * #364 detail children, declared with only their parent tag until the vendor element shape is
 * known; they are debt to work off, not a pattern to repeat.
 *
 * The rule is AT LEAST one key, deliberately not exactly one. Join/association objects
 * legitimately carry a COMPOSITE key — HubSpot's `associations_*` family keys on
 * (`fromObjectId`, `toObjectId`), and MJ models that natively with `CompositeKey`. Demanding a
 * single key would have flagged 63 correct HubSpot objects and pushed the fix the wrong way.
 *
 * SCOPE. Only objects that declare fields AND are `Status: Active`. An object with no declared
 * fields has nothing to stamp — a different (also real, also tracked) gap. A Disabled or
 * Deprecated object is not offered by the engine (`GetActiveIntegrationObjects` filters on
 * Active), so it cannot cost classifier work or promise data; disabling an object the vendor
 * exposes without any derivable key is a legitimate way to leave this list.
 *
 * ── RATCHET ──────────────────────────────────────────────────────────────────
 * Each baseline may only SHRINK. Removing an entry is how you record a fix; a stale entry
 * (baselined but now compliant) also fails, so neither file can drift into fiction. A NEW
 * violation in either scope fails: do not add to a baseline, fix the object.
 *
 *   node scripts/lint-writable-pk.mjs             # gate (fails on drift in either scope)
 *   node scripts/lint-writable-pk.mjs --report    # print both scopes grouped by connector
 *   node scripts/lint-writable-pk.mjs --write     # regenerate BOTH baselines (review the diff!)
 */
import { readFileSync, writeFileSync, readdirSync, statSync, existsSync } from 'node:fs';
import { join, dirname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const SKIP_DIRS = new Set(['node_modules', 'dist', '.git', '.github', '.changeset', '.turbo']);

const SCOPES = [
  {
    name: 'writable',
    baselinePath: join(ROOT, 'scripts', 'writable-pk-baseline.json'),
    matches: (f) => f.SupportsWrite === true,
    onNew:
      '\n  A writable object with no primary key CANNOT SAVE on Postgres — the derived\n' +
      '  entity has no key, so MJ\'s save audit-wrapper emits an empty record identifier\n' +
      '  and every save fails with: syntax error at or near ","\n\n' +
      '  Fix: stamp IsPrimaryKey on the field that is the record key for this object,\n' +
      '  and ship paired dialect migrations for the change (migrations/ + migrations-pg/).\n' +
      '  See #105 for the template. Do NOT add the object to the baseline — the baseline\n' +
      '  is the pre-existing debt register and only shrinks.',
  },
  {
    name: 'read-only',
    baselinePath: join(ROOT, 'scripts', 'readonly-pk-baseline.json'),
    matches: (f) => f.SupportsWrite !== true,
    onNew:
      '\n  A read-only object with no primary key either costs the soft-PK classifier a\n' +
      '  per-tenant inference at every discovery, or lands `entity.skipped-no-pk` and can\n' +
      '  never sync while the picker still offers it.\n\n' +
      '  Fix: stamp IsPrimaryKey on the record key (composite is fine) and ship paired\n' +
      '  dialect migrations; or, if the vendor exposes no derivable key at all, set the\n' +
      '  object Status to Disabled (with a migration) so it is not offered. Do NOT add the\n' +
      '  object to the baseline — it is the pre-existing debt register and only shrinks.',
  },
];

const REPORT = process.argv.includes('--report');
const WRITE = process.argv.includes('--write');

/** Every `*.integration.json` under the connector trees. */
function findMetadataFiles(dir, out = []) {
  for (const entry of readdirSync(dir)) {
    if (SKIP_DIRS.has(entry)) continue;
    const p = join(dir, entry);
    if (statSync(p).isDirectory()) findMetadataFiles(p, out);
    else if (entry.endsWith('.integration.json')) out.push(p);
  }
  return out;
}

/**
 * Scan the tree once and return, per scope, every ACTIVE object with fields but no primary key,
 * keyed `<Family>/<Connector>::<ObjectName>` — stable across field reordering and independent
 * of the metadata file's path depth.
 */
function scan() {
  const violations = Object.fromEntries(SCOPES.map((s) => [s.name, []]));
  for (const file of findMetadataFiles(ROOT)) {
    const rel = relative(ROOT, file);
    let parsed;
    try {
      parsed = JSON.parse(readFileSync(file, 'utf-8'));
    } catch (e) {
      for (const s of SCOPES) violations[s.name].push({ key: `${rel}::<parse>`, reason: `invalid JSON — ${e.message}` });
      continue;
    }
    const record = Array.isArray(parsed) ? parsed[0] : parsed;
    const connector = rel.split('/').slice(0, 2).join('/');
    const objects = record?.relatedEntities?.['MJ: Integration Objects'] ?? [];
    for (const obj of objects) {
      const f = obj.fields ?? {};
      // Not offered by the engine → cannot cost inference or promise data. See SCOPE above.
      if ((f.Status ?? 'Active') !== 'Active') continue;
      const fields = obj.relatedEntities?.['MJ: Integration Object Fields'] ?? [];
      // An object with no declared fields has nothing to stamp — a different gap, not this one.
      if (fields.length === 0) continue;
      const pks = fields.filter((x) => x.fields?.IsPrimaryKey === true);
      if (pks.length >= 1) continue;
      const scope = SCOPES.find((s) => s.matches(f));
      violations[scope.name].push({
        key: `${connector}::${f.Name}`,
        reason: `no field declares IsPrimaryKey (${fields.length} field${fields.length === 1 ? '' : 's'} declared)`,
      });
    }
  }
  for (const s of SCOPES) violations[s.name].sort((a, b) => a.key.localeCompare(b.key));
  return violations;
}

const violations = scan();

if (WRITE) {
  for (const s of SCOPES) {
    const v = violations[s.name];
    writeFileSync(
      s.baselinePath,
      `${JSON.stringify({ generatedBy: 'scripts/lint-writable-pk.mjs --write', scope: s.name, count: v.length, keys: v.map((x) => x.key) }, null, 2)}\n`
    );
    console.log(`Wrote ${v.length} ${s.name} baselined violation(s) to ${relative(ROOT, s.baselinePath)}`);
  }
  process.exit(0);
}

if (REPORT) {
  for (const s of SCOPES) {
    const byConnector = new Map();
    for (const v of violations[s.name]) {
      const [connector, object] = v.key.split('::');
      if (!byConnector.has(connector)) byConnector.set(connector, []);
      byConnector.get(connector).push(`${object} — ${v.reason}`);
    }
    console.log(`\n══ ${s.name.toUpperCase()} ══`);
    for (const [connector, items] of [...byConnector].sort((a, b) => b[1].length - a[1].length)) {
      console.log(`\n${connector} (${items.length})`);
      for (const i of items) console.log(`  ${i}`);
    }
    console.log(`\nTotal: ${violations[s.name].length} ${s.name} object(s) without a primary key.`);
  }
  process.exit(0);
}

let failed = false;
const summary = [];
for (const s of SCOPES) {
  if (!existsSync(s.baselinePath)) {
    console.error(`✗ Missing ${relative(ROOT, s.baselinePath)} — run: node scripts/lint-writable-pk.mjs --write`);
    process.exit(1);
  }
  const baseline = new Set(JSON.parse(readFileSync(s.baselinePath, 'utf-8')).keys ?? []);
  const current = new Set(violations[s.name].map((v) => v.key));
  const added = violations[s.name].filter((v) => !baseline.has(v.key));
  const stale = [...baseline].filter((k) => !current.has(k)).sort();
  summary.push(`${s.name} ${violations[s.name].length} baselined`);

  if (added.length > 0) {
    failed = true;
    console.error(`\n✗ ${added.length} NEW ${s.name} object(s) without a primary key:\n`);
    for (const v of added) console.error(`    ${v.key} — ${v.reason}`);
    console.error(s.onNew);
  }
  if (stale.length > 0) {
    failed = true;
    console.error(`\n✗ ${stale.length} ${s.name} baselined entr${stale.length === 1 ? 'y is' : 'ies are'} no longer violating — remove from ${relative(ROOT, s.baselinePath)}:\n`);
    for (const k of stale) console.error(`    ${k}`);
    console.error('\n  A fixed object must leave the baseline, or the file stops describing reality.');
  }
}

if (!failed) {
  console.log(`✓ PK gate: ${summary.join(', ')}, no drift.`);
  process.exit(0);
}
process.exit(1);
