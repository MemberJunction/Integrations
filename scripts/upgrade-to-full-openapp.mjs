#!/usr/bin/env node
/**
 * Upgrades every connector Open App from the lightweight connector-profile (runtime metadata push)
 * to the FULL Open App model (schema + migrations), matching bizapps-common. One-time + idempotent.
 *
 * For each <Category>/<Connector>/mj-app.json:
 *   - adds  "schema":     { "name": "mj_connector_<slug>", "createIfNotExists": true }
 *           (the app's namespace + flyway_schema_history anchor; holds no tables of its own)
 *   - adds  "migrations": { "directory": "migrations", "engine": "skyway" }
 *   - sets  "metadata":   { "directory": "metadata" }   (dev-time source; processOnInstall dropped)
 *   - metadata/.mj-sync.json gets a sqlLogging block so `mj sync push` captures the seed SQL
 *     (raw, literal __mj — NOT formatAsMigration) into ../migrations
 *   - creates migrations/ and migrations-pg/ with a README (the SQL is the human's `mj sync push` step)
 */
import { readFileSync, writeFileSync, mkdirSync, readdirSync, statSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const writeJson = (p, o) => writeFileSync(p, JSON.stringify(o, null, 2) + '\n');

function findManifests(dir, out = []) {
  for (const e of readdirSync(dir)) {
    if (['node_modules', 'dist', '.git', '.github', '.changeset', 'scripts', 'packages'].includes(e)) continue;
    const p = join(dir, e);
    if (statSync(p).isDirectory()) findManifests(p, out);
    else if (e === 'mj-app.json') out.push(p);
  }
  return out;
}

/** Rebuild the manifest with a stable, readable key order, injecting schema + migrations + metadata. */
function rebuild(m, schemaName) {
  const ordered = {};
  const order = ['$schema', 'manifestVersion', 'name', 'displayName', 'description', 'version', 'license', 'icon', 'color', 'publisher', 'repository', 'mjVersionRange', 'schema', 'migrations', 'metadata', 'packages', 'dependencies', 'hooks', 'categories', 'tags'];
  m.schema = { name: schemaName, createIfNotExists: true };
  m.migrations = { directory: 'migrations', engine: 'skyway' };
  m.metadata = { directory: 'metadata' };
  for (const k of order) if (m[k] !== undefined) ordered[k] = m[k];
  for (const k of Object.keys(m)) if (ordered[k] === undefined) ordered[k] = m[k];
  return ordered;
}

const MIGRATIONS_README = `# Migrations

These are GENERATED, not hand-authored. The connector's metadata (\`../metadata/\`) is the source of truth.

**Human step (migration creation):** against a dev MJ database, run from this connector directory:

\`\`\`bash
mj sync push --dir metadata     # sqlLogging captures the seed SQL (literal __mj) into ./migrations
\`\`\`

Then standardize the filename to \`V<YYYYMMDDHHMM>__<connector>__Metadata.sql\` (the helper
\`scripts/wrap-migration.mjs\` does this). The migration body runs \`EXEC __mj.spCreateIntegrationObject …\`
to seed the core integration tables; the connector's own \`mj_connector_<name>\` schema only holds the
Flyway history.

**CI step (automated):** \`scripts/build-pg-migrations.mjs\` runs \`mj migrate convert\` to produce the
PostgreSQL variants in \`../migrations-pg/\`. Do not hand-edit those.
`;

let n = 0;
for (const manifestPath of findManifests(ROOT)) {
  const appDir = dirname(manifestPath);
  const m = JSON.parse(readFileSync(manifestPath, 'utf-8'));
  const slug = m.name.replace(/^connector-/, '').replace(/-/g, '_');
  writeJson(manifestPath, rebuild(m, `mj_connector_${slug}`));

  // metadata/.mj-sync.json — add sqlLogging (raw SQL into ../migrations)
  const syncPath = join(appDir, 'metadata', '.mj-sync.json');
  if (existsSync(syncPath)) {
    const sync = JSON.parse(readFileSync(syncPath, 'utf-8'));
    sync.sqlLogging = { enabled: true, outputDirectory: '../migrations', formatAsMigration: false };
    writeJson(syncPath, sync);
  }

  // migrations/ + migrations-pg/ dirs (+ README in migrations/)
  mkdirSync(join(appDir, 'migrations'), { recursive: true });
  mkdirSync(join(appDir, 'migrations-pg'), { recursive: true });
  if (!existsSync(join(appDir, 'migrations', 'README.md'))) writeFileSync(join(appDir, 'migrations', 'README.md'), MIGRATIONS_README);
  if (!existsSync(join(appDir, 'migrations-pg', '.gitkeep'))) writeFileSync(join(appDir, 'migrations-pg', '.gitkeep'), '');
  n++;
}
console.log(`Upgraded ${n} connector Open Apps to the full schema + migrations model.`);
