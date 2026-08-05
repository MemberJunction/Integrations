#!/usr/bin/env node
/**
 * Generates the PostgreSQL variants of each connector's migrations via `mj migrate convert`
 * (SQL Server → Postgres, rule-based, deterministic, no database). Runs in CI and locally.
 *
 *   node scripts/build-pg-migrations.mjs [<Category>/<Connector> ...]   (default: all connectors)
 *   --check   fail (exit 1) if any SS migration lacks an up-to-date .pg.sql (CI drift gate)
 *
 * For each connector with `migrations/*.sql` lacking a `migrations-pg/*.pg.sql` counterpart, runs:
 *   mj migrate convert --source-dir migrations --output-dir migrations-pg --schema __mj
 * (the migration body targets __mj literally, so __mj is the conversion schema). Connector migrations
 * are pure data seeds, the most converter-friendly case.
 */
import { readFileSync, readdirSync, statSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const CHECK = process.argv.includes('--check');
const explicit = process.argv.slice(2).filter((a) => !a.startsWith('--'));

// Pin the converter CLI version. The ambient global `mj` may be stale — e.g. 5.36 predates the
// `_Clear`/boolean SP-arg coercion fix (added in the SS→PG converter in 5.40.x), which silently
// emits broken PG (`_Clear := 1` against a BOOLEAN param → `function ... does not exist` on apply).
// Match the pinned version build-seed-migrations.mjs uses for the SS push; MJ_CLI overrides
// (e.g. a locally-built binary path) for offline/dev runs.
const MJ_CLI = process.env.MJ_CLI || null;
const PINNED_CLI = '@memberjunction/cli@5.43.0';
function runConvert(appDir) {
  const argv = ['migrate', 'convert', '--source-dir', 'migrations', '--output-dir', 'migrations-pg', '--schema', '__mj'];
  if (MJ_CLI) execFileSync(MJ_CLI, argv, { cwd: appDir, stdio: 'inherit' });
  else execFileSync('npx', ['-y', PINNED_CLI, ...argv], { cwd: appDir, stdio: 'inherit' });
}

/**
 * Strips SQL comments and string/dollar-quoted literals so the scan below reads CODE only.
 * Without this, the honest prose in a hand-authored .pg.sql ("the converter emits "JSON_MODIFY"(...)")
 * would be flagged as the very defect it documents.
 */
function stripNonCode(sql) {
  let out = '', i = 0;
  while (i < sql.length) {
    const two = sql.slice(i, i + 2);
    if (two === '--') { const nl = sql.indexOf('\n', i); i = nl === -1 ? sql.length : nl; continue; }
    if (two === '/*') { const end = sql.indexOf('*/', i + 2); i = end === -1 ? sql.length : end + 2; continue; }
    if (sql[i] === "'") {
      i++;
      while (i < sql.length) { if (sql[i] === "'" && sql[i + 1] === "'") i += 2; else if (sql[i] === "'") { i++; break; } else i++; }
      out += "''"; continue;
    }
    const dollar = /^\$[A-Za-z_]*\$/.exec(sql.slice(i));
    if (dollar) {
      const tag = dollar[0];
      const end = sql.indexOf(tag, i + tag.length);
      i = end === -1 ? sql.length : end + tag.length;
      out += "''"; continue;
    }
    out += sql[i++];
  }
  return out;
}

/**
 * A quoted ALL-CAPS identifier used as a FUNCTION CALL — `"JSON_MODIFY"(...)` — is the converter's
 * signature for a T-SQL builtin it could not translate: it fell back to quoting the name, producing a
 * call to a function that does not exist in PostgreSQL. The file looks plausible, passes generation, and
 * fails on EVERY PG tenant at apply time, far from whoever authored it. Catching the whole shape rather
 * than a hardcoded list of JSON functions means the next untranslatable builtin is caught too.
 */
function findUntranslated(sql) {
  const hits = new Set();
  for (const m of stripNonCode(sql).matchAll(/"([A-Z][A-Z0-9_]{2,})"\s*\(/g)) hits.add(m[1]);
  return [...hits];
}

function auditPgDir(pgDir, rel) {
  if (!existsSync(pgDir)) return [];
  const bad = [];
  for (const f of readdirSync(pgDir).filter((x) => x.endsWith('.pg.sql'))) {
    const fns = findUntranslated(readFileSync(join(pgDir, f), 'utf8'));
    if (fns.length) bad.push(`${rel}/migrations-pg/${f}: untranslated T-SQL function(s) ${fns.map((n) => `${n}()`).join(', ')}`);
  }
  return bad;
}

function allConnectorDirs(dir, out = []) {
  for (const e of readdirSync(dir)) {
    if (['node_modules', 'dist', '.git', '.github', '.changeset', 'scripts', 'packages'].includes(e)) continue;
    const p = join(dir, e);
    if (!statSync(p).isDirectory()) continue;
    if (existsSync(join(p, 'mj-app.json'))) out.push(p);
    else allConnectorDirs(p, out);
  }
  return out;
}

const targets = explicit.length ? explicit.map((r) => join(ROOT, r)) : allConnectorDirs(ROOT);
let drift = 0, converted = 0;
const untranslated = [];

for (const appDir of targets) {
  const migDir = join(appDir, 'migrations');
  if (!existsSync(migDir)) continue;
  const ss = readdirSync(migDir).filter((f) => /^[BV]\d{12}__.*\.sql$/.test(f));
  if (ss.length === 0) continue;
  const pgDir = join(appDir, 'migrations-pg');
  const rel = appDir.slice(ROOT.length + 1);
  const missing = ss.filter((f) => !existsSync(join(pgDir, f.replace(/\.sql$/, '.pg.sql'))));

  if (missing.length === 0) {
    // Nothing to convert, but everything already generated still gets audited — a bad file that was
    // committed before this guard existed must not stay invisible just because it is not "new".
    untranslated.push(...auditPgDir(pgDir, rel));
    continue;
  }

  if (CHECK) {
    console.error(`✗ ${rel}: ${missing.length} SS migration(s) missing PG variant: ${missing.join(', ')}`);
    drift += missing.length;
    untranslated.push(...auditPgDir(pgDir, rel));
    continue;
  }

  try {
    runConvert(appDir);
    converted += missing.length;
    console.log(`✓ ${rel}: converted ${missing.length} migration(s) → migrations-pg/`);
  } catch (e) {
    console.error(`✗ ${rel}: mj migrate convert failed — ${e.message}`);
    process.exit(1);
  }
  untranslated.push(...auditPgDir(pgDir, rel));
}

if (untranslated.length > 0) {
  console.error(`\n✗ ${untranslated.length} generated PG migration(s) call T-SQL functions that do not exist in PostgreSQL:\n`);
  for (const line of untranslated) console.error(`  ${line}`);
  console.error(
    `\nThe converter could not translate these and quoted the names instead, which produces SQL that`
    + `\nlooks fine here and fails on EVERY PG tenant at apply time. Do not commit them. Delete the`
    + `\ngenerated file and hand-author the .pg.sql with the jsonb equivalent — see`
    + `\nLMS/Totara/migrations-pg/V202608041327__totara__UsersIdWindowScan.pg.sql, which does exactly`
    + `\nthis and says so in a comment. The SQL Server original stays untouched.\n`
  );
  process.exit(1);
}

if (CHECK && drift > 0) { console.error(`\n${drift} migration(s) need PG conversion — run \`npm run migrations:pg\` and commit.`); process.exit(1); }
console.log(CHECK ? 'PG migrations are up to date.' : `Done — converted ${converted} migration(s).`);
