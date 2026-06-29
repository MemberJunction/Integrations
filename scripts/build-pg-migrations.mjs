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

for (const appDir of targets) {
  const migDir = join(appDir, 'migrations');
  if (!existsSync(migDir)) continue;
  const ss = readdirSync(migDir).filter((f) => /^[BV]\d{12}__.*\.sql$/.test(f));
  if (ss.length === 0) continue;
  const pgDir = join(appDir, 'migrations-pg');
  const missing = ss.filter((f) => !existsSync(join(pgDir, f.replace(/\.sql$/, '.pg.sql'))));
  if (missing.length === 0) continue;

  const rel = appDir.slice(ROOT.length + 1);
  if (CHECK) { console.error(`✗ ${rel}: ${missing.length} SS migration(s) missing PG variant: ${missing.join(', ')}`); drift += missing.length; continue; }

  try {
    runConvert(appDir);
    converted += missing.length;
    console.log(`✓ ${rel}: converted ${missing.length} migration(s) → migrations-pg/`);
  } catch (e) {
    console.error(`✗ ${rel}: mj migrate convert failed — ${e.message}`);
    process.exit(1);
  }
}

if (CHECK && drift > 0) { console.error(`\n${drift} migration(s) need PG conversion — run \`npm run migrations:pg\` and commit.`); process.exit(1); }
console.log(CHECK ? 'PG migrations are up to date.' : `Done — converted ${converted} migration(s).`);
