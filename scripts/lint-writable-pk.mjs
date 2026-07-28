#!/usr/bin/env node
/**
 * lint-writable-pk.mjs — a WRITABLE object must declare a primary key.
 *
 * THE BUG CLASS this guards. An `MJ: Integration Object` whose fields carry no
 * `IsPrimaryKey: true` produces a derived entity with no primary key. On SQL
 * Server that mostly limps along; on **Postgres** MJ's save audit-wrapper builds
 * an empty record identifier and every save fails with
 *
 *     syntax error at or near ","
 *
 * Fetch still succeeds, so the connector looks healthy — nothing persists, and
 * the failure is per-save rather than per-run, so it reads as a data problem at
 * the far end rather than a metadata defect at this end. The HubSpot
 * `hs_object_id` fix (#105) was one instance of this class; there are more.
 *
 * The rule is AT LEAST one, deliberately not exactly one. Join/association
 * objects legitimately carry a COMPOSITE key — HubSpot's `associations_*` family
 * keys on (`fromObjectId`, `toObjectId`), and MJ models that natively with
 * `CompositeKey`. Demanding a single key would have flagged 63 correct HubSpot
 * objects and pushed the fix in exactly the wrong direction.
 *
 * SCOPE. Only objects that declare fields AND `SupportsWrite: true`. A read-only
 * object with no PK is a lesser problem (it can't fail a save it never attempts)
 * and is tracked separately — see the read-only tail in the PR 10 register.
 *
 * ── RATCHET ──────────────────────────────────────────────────────────────────
 * The tree currently violates this rule in `writable-pk-baseline.json` places.
 * Rather than block every PR until all of them are researched — each needs a
 * vendor-doc decision plus paired dialect migrations, which is a large piece of
 * work — this gate accepts exactly the baselined set and fails on anything else.
 * The baseline is a RATCHET: it may only shrink. Removing an entry is how you
 * record a fix; a stale entry (baselined but now compliant) also fails, so the
 * file can never drift into fiction.
 *
 *   node scripts/lint-writable-pk.mjs             # gate (fails on drift)
 *   node scripts/lint-writable-pk.mjs --report    # print the baseline grouped by connector
 *   node scripts/lint-writable-pk.mjs --write     # regenerate the baseline (review the diff!)
 */
import { readFileSync, writeFileSync, readdirSync, statSync, existsSync } from 'node:fs';
import { join, dirname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const BASELINE_PATH = join(ROOT, 'scripts', 'writable-pk-baseline.json');
const SKIP_DIRS = new Set(['node_modules', 'dist', '.git', '.github', '.changeset', '.turbo']);

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
 * Scan the tree and return every writable object that declares no primary key,
 * keyed `<Family>/<Connector>::<ObjectName>` — stable across field reordering and
 * independent of the metadata file's path depth.
 */
function scan() {
  const violations = [];
  for (const file of findMetadataFiles(ROOT)) {
    const rel = relative(ROOT, file);
    let parsed;
    try {
      parsed = JSON.parse(readFileSync(file, 'utf-8'));
    } catch (e) {
      violations.push({ key: `${rel}::<parse>`, reason: `invalid JSON — ${e.message}` });
      continue;
    }
    const record = Array.isArray(parsed) ? parsed[0] : parsed;
    const connector = rel.split('/').slice(0, 2).join('/');
    const objects = record?.relatedEntities?.['MJ: Integration Objects'] ?? [];
    for (const obj of objects) {
      const f = obj.fields ?? {};
      if (f.SupportsWrite !== true) continue;
      const fields = obj.relatedEntities?.['MJ: Integration Object Fields'] ?? [];
      // An object with no declared fields has nothing to stamp — it's a different
      // (also real, also tracked) gap, not this one.
      if (fields.length === 0) continue;
      const pks = fields.filter((x) => x.fields?.IsPrimaryKey === true);
      if (pks.length >= 1) continue;
      violations.push({
        key: `${connector}::${f.Name}`,
        reason: `no field declares IsPrimaryKey (${fields.length} field${fields.length === 1 ? '' : 's'} declared)`
      });
    }
  }
  violations.sort((a, b) => a.key.localeCompare(b.key));
  return violations;
}

const violations = scan();

if (WRITE) {
  writeFileSync(
    BASELINE_PATH,
    `${JSON.stringify({ generatedBy: 'scripts/lint-writable-pk.mjs --write', count: violations.length, keys: violations.map((v) => v.key) }, null, 2)}\n`
  );
  console.log(`Wrote ${violations.length} baselined violation(s) to ${relative(ROOT, BASELINE_PATH)}`);
  process.exit(0);
}

if (REPORT) {
  const byConnector = new Map();
  for (const v of violations) {
    const [connector, object] = v.key.split('::');
    if (!byConnector.has(connector)) byConnector.set(connector, []);
    byConnector.get(connector).push(`${object} — ${v.reason}`);
  }
  for (const [connector, items] of [...byConnector].sort((a, b) => b[1].length - a[1].length)) {
    console.log(`\n${connector} (${items.length})`);
    for (const i of items) console.log(`  ${i}`);
  }
  console.log(`\nTotal: ${violations.length} writable object(s) without a primary key.`);
  process.exit(0);
}

if (!existsSync(BASELINE_PATH)) {
  console.error(`✗ Missing ${relative(ROOT, BASELINE_PATH)} — run: node scripts/lint-writable-pk.mjs --write`);
  process.exit(1);
}
const baseline = new Set(JSON.parse(readFileSync(BASELINE_PATH, 'utf-8')).keys ?? []);
const current = new Set(violations.map((v) => v.key));

const added = violations.filter((v) => !baseline.has(v.key));
const stale = [...baseline].filter((k) => !current.has(k)).sort();

if (added.length === 0 && stale.length === 0) {
  console.log(`✓ writable-PK gate: ${violations.length} baselined violation(s), no drift.`);
  process.exit(0);
}

if (added.length > 0) {
  console.error(`\n✗ ${added.length} NEW writable object(s) without a primary key:\n`);
  for (const v of added) console.error(`    ${v.key} — ${v.reason}`);
  console.error(
    '\n  A writable object with no primary key CANNOT SAVE on Postgres — the derived\n' +
      '  entity has no key, so MJ\'s save audit-wrapper emits an empty record identifier\n' +
      '  and every save fails with: syntax error at or near ","\n\n' +
      '  Fix: stamp IsPrimaryKey on the field that is the record key for this object,\n' +
      '  and ship paired dialect migrations for the change (migrations/ + migrations-pg/).\n' +
      '  See #105 for the template. Do NOT add the object to the baseline — the baseline\n' +
      '  is the pre-existing debt register and only shrinks.'
  );
}

if (stale.length > 0) {
  console.error(`\n✗ ${stale.length} baselined entr${stale.length === 1 ? 'y is' : 'ies are'} no longer violating — remove from the baseline:\n`);
  for (const k of stale) console.error(`    ${k}`);
  console.error('\n  A fixed object must leave the baseline, or the file stops describing reality.');
}

process.exit(1);
