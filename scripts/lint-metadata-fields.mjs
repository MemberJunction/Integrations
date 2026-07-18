#!/usr/bin/env node
/**
 * lint-metadata-fields.mjs — metadata field allowlist gate (concern A11).
 *
 * THE BUG CLASS this guards: a connector's metadata/integration/*.json is the
 * AUTHORING layer. Its record `fields.*` keys are pushed into the __mj catalog by
 * `mj sync push`, but `BaseEntity.SetLocal` SILENTLY DROPS any key that is not a
 * real entity column — so an authored-but-inert field (e.g. `APIBaseURL` on the
 * Integration row, which is NOT a column — the real one is `NavigationBaseURL`)
 * looks declared but reaches no tenant and no test can see the drop. That is the
 * "validate against a declaration the code never uses → a green check confirms a
 * fiction" failure this repo already hit. This linter makes it a BUILD FAILURE:
 * every `fields.*` key on an Integration / IntegrationObject / IntegrationObjectField
 * record must be either
 *   (a) a REAL entity column — proven by appearing as an `@Param` on the matching
 *       spCreate/spUpdate sproc call in some connector's generated migration, seeded
 *       with a hardcoded floor of the known columns; OR
 *   (b) a documented FRAMEWORK-IDEAL field — a "framework-ideal-but-not-deployed"
 *       key that SetLocal drops on purpose (kept for authoring intent; see
 *       scripts/build-seed-migrations.mjs), pushed only under `--no-validate`; OR
 *   (c) a GRANDFATHERED key — a real inert declaration already in the tree, listed
 *       here as explicit tech-debt for the A11 sweep to remove/wire (NOT a licence
 *       to add more — new off-allowlist keys still fail).
 *
 * SCOPE: only the structured entity-field surfaces (record `fields.*` at the three
 * nesting levels). The free-form `Configuration` JSON blob is DELIBERATELY out of
 * scope — it is open-ended per-connector documentation (300+ distinct keys, *Note /
 * *Gap / *Rationale conventions), not entity columns, and linting it would be wrong.
 *
 *   node scripts/lint-metadata-fields.mjs            # lint (fails on violation)
 *   node scripts/lint-metadata-fields.mjs --audit    # also print the universalPK shape audit
 */
import { readFileSync, readdirSync, statSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const AUDIT = process.argv.includes('--audit');

const SKIP_DIRS = new Set(['node_modules', 'dist', '.git', '.github', '.changeset', 'scripts', '.turbo']);

// ── Ground-truth LIVE column floor (spCreate* sproc signatures, __mj core) ──────
// These are the columns the seed sprocs accept; the union with migration-derived
// params below only ever ADDS. Anything here is guaranteed-live even for a brand-new
// connector that has not generated a migration yet.
const INTEGRATION_COLUMNS = new Set([
  'ID', 'Name', 'Description', 'ClassName', 'ImportPath', 'CredentialTypeID',
  'NavigationBaseURL', 'BatchMaxRequestCount', 'BatchRequestWaitTime', 'Configuration', 'Icon',
]);
const INTEGRATION_OBJECT_COLUMNS = new Set([
  'ID', 'IntegrationID', 'Name', 'DisplayName', 'Description', 'APIPath', 'Category', 'Configuration',
  'Status', 'Sequence', 'PaginationType', 'DefaultPageSize', 'DefaultQueryParams', 'ResponseDataKey',
  'SupportsPagination', 'SupportsIncrementalSync', 'IncrementalWatermarkField', 'SyncStrategy',
  'StableOrderingKey', 'ContentHashApplicable', 'IsCustom', 'MetadataSource',
  // NB: SupportsRead is NOT a column (no spCreate/spUpdateIntegrationObject migration ever
  // passes it as a @Param — unlike the four below); it is framework-ideal only. See FRAMEWORK_IDEAL.
  'SupportsWrite', 'SupportsCreate', 'SupportsUpdate', 'SupportsDelete',
  'CreateAPIPath', 'CreateMethod', 'CreateBodyShape', 'CreateBodyKey', 'CreateIDLocation',
  'UpdateAPIPath', 'UpdateMethod', 'UpdateBodyShape', 'UpdateBodyKey', 'UpdateIDLocation',
  'DeleteAPIPath', 'DeleteMethod', 'DeleteIDLocation', 'WriteAPIPath', 'WriteMethod',
]);
const INTEGRATION_OBJECT_FIELD_COLUMNS = new Set([
  'ID', 'IntegrationObjectID', 'Name', 'DisplayName', 'Description', 'Type', 'Category', 'Configuration',
  'Status', 'Sequence', 'Length', 'Precision', 'Scale', 'DefaultValue', 'AllowsNull', 'IsCustom',
  'IsPrimaryKey', 'IsUniqueKey', 'IsRequired', 'IsReadOnly', 'MetadataSource',
  'RelatedIntegrationObjectID', 'RelatedIntegrationObjectFieldName',
]);

// ── Framework-ideal ("ideal-but-not-deployed") fields that SetLocal drops on purpose.
// Documented in scripts/build-seed-migrations.mjs. Authored for intent; never a column.
const FRAMEWORK_IDEAL = new Set([
  'Source',                     // superseded by MetadataSource (the real column)
  'IsForeignKey', 'IsMutable', 'IsAppendOnly', 'IncludeInActionGeneration', 'SupportsRead',
  'ParentObjectName', 'ParentObjectIDFieldName', 'HierarchyPath',
]);

// ── Grandfathered inert declarations already in the tree (A11 sweep debt). ──────
// Each entry: a real INERT key (proven not a column) that predates this linter.
// Do NOT extend this list — resolve entries by removing/wiring the field, then delete
// them here. New off-allowlist keys must fail instead of being grandfathered.
//   APIBaseURL — Integration-level; not a spCreateIntegration column (NavigationBaseURL
//   is). Present on AMS/WildApricot and Events/PheedLoop. Dropped by SetLocal today.
const GRANDFATHERED = {
  Integration: new Set(['APIBaseURL']),
  IntegrationObject: new Set(),
  IntegrationObjectField: new Set(),
};

// ── Derive additional LIVE columns from generated migrations (self-maintaining). ─
// Every spCreate/spUpdate sproc call in a migration passes ONLY real columns as
// @Params (the metadata push drops non-columns before emitting SQL), so the union
// of those param names is a provably-live column set that auto-tracks schema growth.
function harvestMigrationColumns() {
  const re = {
    Integration: /EXEC\s+\[__mj\]\.sp(?:Create|Update)Integration\s+([\s\S]*?);/g,
    IntegrationObject: /EXEC\s+\[__mj\]\.sp(?:Create|Update)IntegrationObject\s+([\s\S]*?);/g,
    IntegrationObjectField: /EXEC\s+\[__mj\]\.sp(?:Create|Update)IntegrationObjectField\s+([\s\S]*?);/g,
  };
  const found = { Integration: new Set(), IntegrationObject: new Set(), IntegrationObjectField: new Set() };
  const walk = (dir) => {
    for (const e of readdirSync(dir)) {
      if (SKIP_DIRS.has(e)) continue;
      const p = join(dir, e);
      let st; try { st = statSync(p); } catch { continue; }
      if (st.isDirectory()) { if (e === 'migrations') harvestFile(p, found, re); walk(p); }
    }
  };
  const harvestFile = (migDir) => {
    for (const f of readdirSync(migDir).filter((x) => x.endsWith('.sql'))) {
      const sql = readFileSync(join(migDir, f), 'utf8');
      for (const [level, rx] of Object.entries(re)) {
        rx.lastIndex = 0;
        let m;
        while ((m = rx.exec(sql))) for (const pm of m[1].matchAll(/@([A-Za-z][A-Za-z0-9]*)\s*=/g)) found[level].add(pm[1]);
      }
    }
  };
  walk(ROOT);
  return found;
}

const harvested = harvestMigrationColumns();
const allow = {
  Integration: new Set([...INTEGRATION_COLUMNS, ...harvested.Integration]),
  IntegrationObject: new Set([...INTEGRATION_OBJECT_COLUMNS, ...harvested.IntegrationObject]),
  IntegrationObjectField: new Set([...INTEGRATION_OBJECT_FIELD_COLUMNS, ...harvested.IntegrationObjectField]),
};

// ── Walk metadata/integration/*.integration.json record surfaces. ───────────────
function findIntegrationFiles(dir, out = []) {
  for (const e of readdirSync(dir)) {
    if (SKIP_DIRS.has(e)) continue;
    const p = join(dir, e);
    let st; try { st = statSync(p); } catch { continue; }
    if (st.isDirectory()) findIntegrationFiles(p, out);
    else if (e.endsWith('.integration.json')) out.push(p);
  }
  return out;
}

const isAllowed = (level, key) => allow[level].has(key) || FRAMEWORK_IDEAL.has(key) || GRANDFATHERED[level].has(key);

const violations = [];
const universalPKShapes = []; // { file, shape }

function checkRecord(level, rec, relPath) {
  if (rec?.fields && typeof rec.fields === 'object') {
    for (const key of Object.keys(rec.fields)) {
      if (!isAllowed(level, key)) violations.push({ level, key, file: relPath });
    }
    // universalPK shape audit (informational — lives inside the free-form Configuration blob).
    const cfg = rec.fields.Configuration;
    if (cfg && typeof cfg === 'object' && 'universalPK' in cfg) {
      const v = cfg.universalPK;
      universalPKShapes.push({ file: relPath, shape: typeof v === 'string' ? 'string' : Array.isArray(v) ? 'array' : 'object' });
    }
    if (cfg && typeof cfg === 'object' && 'universalPKGap' in cfg) universalPKShapes.push({ file: relPath, shape: 'gap-note' });
  }
  const io = rec?.relatedEntities?.['MJ: Integration Objects'];
  if (Array.isArray(io)) for (const o of io) {
    checkObjectRecord(o, relPath);
  }
}

function checkObjectRecord(obj, relPath) {
  if (obj?.fields && typeof obj.fields === 'object') {
    for (const key of Object.keys(obj.fields)) {
      if (!isAllowed('IntegrationObject', key)) violations.push({ level: 'IntegrationObject', key, file: relPath });
    }
    // Per-object universalPK (the string-form `"universalPK": "Id"` lives here, inside
    // each object's free-form Configuration) — inventory it for the deferred shape sweep.
    const ocfg = obj.fields.Configuration;
    if (ocfg && typeof ocfg === 'object' && 'universalPK' in ocfg) {
      const v = ocfg.universalPK;
      universalPKShapes.push({ file: `${relPath} › ${obj.fields.Name ?? 'object'}`, shape: typeof v === 'string' ? 'string(per-object)' : Array.isArray(v) ? 'array(per-object)' : 'object(per-object)' });
    }
  }
  const iof = obj?.relatedEntities?.['MJ: Integration Object Fields'];
  if (Array.isArray(iof)) for (const fld of iof) {
    if (fld?.fields && typeof fld.fields === 'object') {
      for (const key of Object.keys(fld.fields)) {
        if (!isAllowed('IntegrationObjectField', key)) violations.push({ level: 'IntegrationObjectField', key, file: relPath });
      }
    }
  }
}

let recordCount = 0;
for (const file of findIntegrationFiles(ROOT)) {
  const relPath = file.slice(ROOT.length + 1).replace(/\\/g, '/');
  let recs;
  try { recs = JSON.parse(readFileSync(file, 'utf8')); } catch (e) { violations.push({ level: 'file', key: `unparseable: ${e.message}`, file: relPath }); continue; }
  for (const rec of (Array.isArray(recs) ? recs : [recs])) { recordCount++; checkRecord('Integration', rec, relPath); }
}

// ── Report ──────────────────────────────────────────────────────────────────────
if (AUDIT || universalPKShapes.length) {
  const counts = universalPKShapes.reduce((m, s) => (m[s.shape] = (m[s.shape] || 0) + 1, m), {});
  console.log(`universalPK shape audit (informational, non-gating — A11 shape-standardization is deferred):`);
  console.log(`  shapes: ${JSON.stringify(counts)}  across ${universalPKShapes.length} declaration(s)`);
  if (AUDIT) for (const s of universalPKShapes.sort((a, b) => a.shape.localeCompare(b.shape))) console.log(`    ${s.shape.padEnd(9)} ${s.file}`);
  console.log('');
}

if (violations.length) {
  console.error(`✗ metadata-field lint: ${violations.length} off-allowlist field key(s) declared (SetLocal will silently drop them — declared ≠ deployed):`);
  const byKey = new Map();
  for (const v of violations) {
    const id = `${v.level}.${v.key}`;
    if (!byKey.has(id)) byKey.set(id, []);
    byKey.get(id).push(v.file);
  }
  for (const [id, files] of [...byKey.entries()].sort()) {
    console.error(`  - ${id}  (${files.length} file(s)): ${[...new Set(files)].join(', ')}`);
  }
  console.error(`\n  Fix: either remove the inert key, or (if it should deploy) rename it to the real column.`);
  console.error(`  Real columns are proven by the spCreate* params in generated migrations. Framework-ideal`);
  console.error(`  intent fields belong to the documented FRAMEWORK_IDEAL set only.`);
  process.exit(1);
}

console.log(`✓ metadata-field lint: ${recordCount} integration record(s) checked; every fields.* key maps to a live column, a framework-ideal field, or a grandfathered debt entry.`);
