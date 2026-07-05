#!/usr/bin/env node
/**
 * require-metadata-migration.mjs — metadata changes MUST ship a catalog migration.
 *
 * THE BUG CLASS: a connector's metadata JSON is the AUTHORING layer only. Tenants
 * get their `__mj` catalog rows from the connector's migrations/ (Skyway at
 * install/upgrade) — and upgrades apply only NEW migration files. A release that
 * edits metadata/ without adding a migration ships a fix that reaches NOBODY:
 * fresh installs seed the stale catalog, upgrades apply nothing (wave-1/2 shipped
 * parent declarations + field widths this way — inert on every tenant until the
 * V202607032105/06 deltas). This validator makes that class a BUILD FAILURE.
 *
 * Rule, per connector (<Category>/<Connector>):
 *   changed  metadata/credential-type/*.json or metadata/integration/*.json
 *   ⇒ the SAME diff range must ADD a migrations/V*.sql file for that connector.
 *
 * Generate the migration with the documented pipeline (CONNECTOR_LIFECYCLE_GUIDE.md):
 *   reset gen DB → apply the connector's RELEASED migrations (previous state) →
 *   `mj sync push --dir <conn>/metadata --ci --no-validate` (emits the delta) →
 *   `node scripts/wrap-migration.mjs <conn>` → `node scripts/build-pg-migrations.mjs <conn>`
 *
 * Base resolution: $BASE_SHA (CI passes the PR base) → origin/next → origin/main.
 */
import { execFileSync } from 'node:child_process';

const git = (...a) => execFileSync('git', a, { encoding: 'utf8' }).trim();

function resolveBase() {
  const candidates = [process.env.BASE_SHA, 'origin/next', 'origin/main'].filter(Boolean);
  for (const c of candidates) {
    try {
      return git('merge-base', c, 'HEAD');
    } catch {
      /* next candidate */
    }
  }
  throw new Error('Could not resolve a diff base (set BASE_SHA or fetch origin/next).');
}

const base = resolveBase();
const nameStatus = git('diff', '--name-status', `${base}..HEAD`)
  .split('\n')
  .filter(Boolean)
  .map((l) => {
    const [status, ...paths] = l.split('\t');
    return { status: status[0], path: paths[paths.length - 1] };
  });

// Record-bearing metadata files only — schemas/.mj-sync.json don't seed catalog rows.
const META_RE = /^([^/]+\/[^/]+)\/metadata\/(integration|credential-type)\/[^/]+\.json$/;
const MIG_RE = /^([^/]+\/[^/]+)\/migrations\/V\d{12}__.+\.sql$/;

const metaChanged = new Map(); // connector → [files]
const migAdded = new Set(); // connectors with an added V*.sql

for (const { status, path } of nameStatus) {
  const m = path.match(META_RE);
  if (m) {
    if (!metaChanged.has(m[1])) metaChanged.set(m[1], []);
    metaChanged.get(m[1]).push(path);
  }
  const g = path.match(MIG_RE);
  if (g && status === 'A') migAdded.add(g[1]);
}

let bad = 0;
for (const [conn, files] of metaChanged) {
  if (migAdded.has(conn)) continue;
  bad++;
  console.error(
    `✗ ${conn} — metadata changed (${files.length} file(s)) but NO new migrations/V*.sql was added.\n` +
      `  Metadata alone reaches no tenant: upgrades apply only new migrations, fresh installs run the old seed.\n` +
      `  Generate the delta: gen-DB at released state → mj sync push --dir ${conn}/metadata --ci --no-validate\n` +
      `  → node scripts/wrap-migration.mjs ${conn} → node scripts/build-pg-migrations.mjs ${conn}`
  );
}

if (bad > 0) {
  console.error(`\n${bad} connector(s) with catalog-invisible metadata changes. Failing build.`);
  process.exit(1);
}
console.log(
  metaChanged.size === 0
    ? '✓ metadata-migration guard: no record-bearing metadata changes in range.'
    : `✓ metadata-migration guard: ${metaChanged.size} connector(s) changed metadata, all ship a new migration.`
);
