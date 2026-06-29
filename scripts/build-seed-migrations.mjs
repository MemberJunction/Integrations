#!/usr/bin/env node
/**
 * build-seed-migrations.mjs — the end-to-end seed-migration generator for connector Open Apps.
 *
 * For each connector in scope, against ONE generation DB (already at a core __mj baseline:
 * `mj migrate` + `mj codegen` so the spCreate* integration sprocs exist), it:
 *   1. RESETS the __mj integration catalog (IntegrationObjectField → IntegrationObject → Integration).
 *      Required because IntegrationObject.Name is globally unique (UQ_IntegrationObject_Name) — two
 *      connectors with a same-named object (e.g. both `Contact`) collide in one DB. "Fresh DB for each."
 *   2. Runs `mj sync push --dir <connector>/metadata --ci` — seeds the catalog, and (via the metadata's
 *      sqlLogging block, outputDirectory ../migrations) EMITS the raw spCreate* SQL into migrations/,
 *      while writing primaryKey/sync back into the metadata JSON (deterministic re-runs).
 *   3. `wrap-migration.mjs <Category>/<Connector>` — renames the raw emit to the repo convention
 *      V<YYYYMMDDHHMM>__<slug>__Metadata.sql + Flyway header.
 *   4. `build-pg-migrations.mjs <Category>/<Connector>` — emits the .pg.sql variant.
 *
 * Usage:
 *   node scripts/build-seed-migrations.mjs                 # all connectors in connector-publish-scope.json "publish"
 *   node scripts/build-seed-migrations.mjs CRM/Salesforce  # one connector
 *   node scripts/build-seed-migrations.mjs --hold          # the held 14 too
 *   node scripts/build-seed-migrations.mjs --no-pg         # skip the PG variant
 *   node scripts/build-seed-migrations.mjs --clean         # delete pre-existing stale migrations first
 *
 * DB connection comes from mj.config.cjs (which reads env: DB_HOST/DB_PORT/DB_DATABASE/DB_USERNAME/DB_PASSWORD).
 */
import { readFileSync, existsSync, readdirSync, rmSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO = join(__dirname, '..');

// ---- args ----
const args = process.argv.slice(2);
const flags = new Set(args.filter(a => a.startsWith('--')));
const positional = args.filter(a => !a.startsWith('--'));
const includeHold = flags.has('--hold');
const skipPg = flags.has('--no-pg');
const cleanFirst = flags.has('--clean');

// ---- scope ----
const scope = JSON.parse(readFileSync(join(__dirname, 'connector-publish-scope.json'), 'utf8'));
let connectors = positional.length ? positional : [...scope.publish, ...(includeHold ? scope.hold : [])];

// ---- DB config (from mj.config.cjs) ----
function loadDbConfig() {
  const cfgPath = join(REPO, 'mj.config.cjs');
  if (!existsSync(cfgPath)) {
    throw new Error(`No mj.config.cjs at repo root (${cfgPath}). Create it (DB connection) before generating seeds.`);
  }
  const cfg = require(cfgPath);
  const host = process.env.DB_HOST ?? cfg.dbHost;
  const port = Number(process.env.DB_PORT ?? cfg.dbPort ?? 1433);
  const database = process.env.DB_DATABASE ?? cfg.dbDatabase;
  const user = process.env.DB_USERNAME ?? cfg.dbUsername;
  const password = process.env.DB_PASSWORD ?? cfg.dbPassword;
  if (!host || !database || !user) throw new Error('Incomplete DB config — need host/database/user (env DB_HOST/DB_DATABASE/DB_USERNAME/DB_PASSWORD).');
  return { host, port, database, user, password };
}

// ---- reset the integration catalog (FK-ordered) via docker sqlcmd (no node mssql dep) ----
// Required because IntegrationObject.Name is globally unique — each connector needs a clean catalog.
const SQL_CONTAINER = process.env.SQL_CONTAINER || 'sql-claude';

// A connector's CredentialType IDs, read from its own metadata/credential-type/*.json. The reset must
// delete THESE so the next `mj sync push` re-EMITS the spCreateCredentialType call into the migration.
// Without this, the gen DB retains the CredentialType across runs, the push sees it already-present and
// logs no create, and the shipped migration references CredentialTypeID without creating the row →
// FK_Integration_CredentialType fails on every fresh `mj app install` (the install runs migrations
// before metadata sync). Deleting by EXACT ID (not by Category) is required because connector CredTypes
// are not uniformly 'Integration' (OpenWater/NeonCRM/Rhythm use 'Authentication', which core types share).
function connectorCredTypeIDs(connectorRel) {
  const ctDir = join(REPO, connectorRel, 'metadata', 'credential-type');
  if (!existsSync(ctDir)) return [];
  const ids = [];
  for (const f of readdirSync(ctDir).filter((x) => /-credential-type\.json$/.test(x))) {
    try { const j = JSON.parse(readFileSync(join(ctDir, f), 'utf8')); if (j.primaryKey?.ID) ids.push(j.primaryKey.ID); } catch { /* ignore */ }
  }
  return ids;
}

function resetCatalog(db, connectorRel) {
  // Delete Integrations (which FK→CredentialType) BEFORE the connector's CredentialType rows, and any
  // stored Credential rows pointing at them, so the CredentialType delete can't hit a FK violation.
  const credDeletes = connectorCredTypeIDs(connectorRel).map((id) =>
    `DELETE FROM [__mj].[Credential] WHERE CredentialTypeID='${id}'; DELETE FROM [__mj].[CredentialType] WHERE ID='${id}';`
  ).join(' ');
  const reset = `SET NOCOUNT ON; USE [${db.database}]; ` +
    `DELETE FROM [__mj].[IntegrationObjectField]; ` +
    `DELETE FROM [__mj].[IntegrationObject]; ` +
    `DELETE FROM [__mj].[Integration]; ` +
    credDeletes;
  execFileSync('docker', [
    'exec', SQL_CONTAINER, '/opt/mssql-tools18/bin/sqlcmd',
    '-S', `localhost,1433`, '-U', db.user, '-P', db.password, '-C', '-b', '-Q', reset,
  ], { stdio: ['ignore', 'ignore', 'inherit'] });
}

// ---- shell helper ----
function run(cmd, cmdArgs, opts = {}) {
  return execFileSync(cmd, cmdArgs, { cwd: REPO, stdio: 'inherit', ...opts });
}

function rawMigrationsBefore(connectorDir) {
  const mig = join(REPO, connectorDir, 'migrations');
  return existsSync(mig) ? readdirSync(mig).filter(f => f.endsWith('.sql')) : [];
}

// ---- main ----
const db = loadDbConfig();
console.log(`Generation DB: ${db.user}@${db.host}:${db.port}/${db.database}`);
console.log(`Connectors in scope: ${connectors.length}${includeHold ? ' (incl. held)' : ''}\n`);

const results = [];
for (const c of connectors) {
  const metaDir = join(REPO, c, 'metadata');
  if (!existsSync(metaDir)) { results.push({ c, ok: false, note: 'no metadata dir' }); console.log(`SKIP ${c} (no metadata)\n`); continue; }
  console.log(`\n=== ${c} ===`);
  try {
    if (cleanFirst) {
      const mig = join(REPO, c, 'migrations');
      if (existsSync(mig)) for (const f of readdirSync(mig).filter(f => f.endsWith('.sql'))) { rmSync(join(mig, f)); console.log(`  cleaned stale ${f}`); }
      const migpg = join(REPO, c, 'migrations-pg');
      if (existsSync(migpg)) for (const f of readdirSync(migpg).filter(f => f.endsWith('.sql'))) rmSync(join(migpg, f));
    }
    console.log('  [1/4] reset integration catalog (+ this connector’s CredentialType, so it re-emits)…');
    resetCatalog(db, c);
    console.log('  [2/4] mj sync push (seed + emit SQL, CLI 5.43.0)…');
    // --no-validate: the metadata carries framework "ideal-but-not-deployed" fields (Source→MetadataSource,
    // IsForeignKey, IsMutable, IsAppendOnly, IncludeInActionGeneration, SupportsRead, ParentObjectName) that
    // BaseEntity.SetLocal drops silently — only real columns get pushed/seeded. Strict --ci validation
    // false-rejects them; the push still does real @lookup resolution, so real FK/ref errors still surface.
    run('npx', ['@memberjunction/cli@5.43.0', 'sync', 'push', '--dir', join(c, 'metadata'), '--ci', '--no-validate']);
    console.log('  [3/4] wrap migration…');
    run('node', [join('scripts', 'wrap-migration.mjs'), c]);
    if (!skipPg) { console.log('  [4/4] build PG variant…'); run('node', [join('scripts', 'build-pg-migrations.mjs'), c]); }
    results.push({ c, ok: true });
  } catch (e) {
    console.error(`  ✗ ${c} FAILED: ${e.message}`);
    results.push({ c, ok: false, note: e.message?.slice(0, 120) });
  }
}

console.log('\n========== SUMMARY ==========');
const ok = results.filter(r => r.ok), bad = results.filter(r => !r.ok);
ok.forEach(r => console.log(`  ✅ ${r.c}`));
bad.forEach(r => console.log(`  ❌ ${r.c} — ${r.note ?? ''}`));
console.log(`\n${ok.length}/${results.length} generated.`);
if (bad.length) process.exit(1);
