#!/usr/bin/env node
/**
 * Floor-check for the Integrations repo. For every connector Open App (any directory with an
 * mj-app.json), asserts the invariants that make it installable + correct:
 *
 *  1. The manifest passes the real MJ Open App Zod schema (mjAppManifestSchema).
 *  2. It is a CONNECTOR PROFILE: no `schema`, no `migrations`, and metadata.processOnInstall === true.
 *  3. packages.server[0] references the shared package with role 'bootstrap' + the registerConnectors export.
 *  4. The seeded Integration metadata's ImportPath equals the shared package, and its ClassName is
 *     exported by packages/integration-connectors (the three-way invariant anchor: ClassName ↔ @RegisterClass).
 *
 * Run in CI after `npm install` (the schema comes from the @memberjunction/open-app-engine devDep).
 */
import { readFileSync, readdirSync, statSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const REPO_ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const SHARED_PACKAGE = '@memberjunction/integration-connectors';

let mjAppManifestSchema;
try {
  ({ mjAppManifestSchema } = await import('@memberjunction/open-app-engine'));
} catch {
  console.warn('⚠ @memberjunction/open-app-engine not installed — skipping Zod manifest validation (run after npm install).');
}

/** Recursively find every mj-app.json under the repo (excluding node_modules/dist). */
function findManifests(dir, out = []) {
  for (const entry of readdirSync(dir)) {
    if (['node_modules', 'dist', '.git', '.turbo', 'scripts', '.changeset', '.github'].includes(entry)) continue;
    const p = join(dir, entry);
    if (statSync(p).isDirectory()) findManifests(p, out);
    else if (entry === 'mj-app.json') out.push(p);
  }
  return out;
}

/** The set of class names exported by the shared connectors package (parsed from its index.ts). */
function exportedClassNames() {
  const index = join(REPO_ROOT, 'packages', 'integration-connectors', 'src', 'index.ts');
  const src = readFileSync(index, 'utf-8');
  const names = new Set();
  for (const m of src.matchAll(/export\s*\{\s*([A-Za-z0-9_]+)/g)) names.add(m[1]);
  return names;
}

const classNames = exportedClassNames();
const errors = [];
const manifests = findManifests(REPO_ROOT);

for (const manifestPath of manifests) {
  const appDir = dirname(manifestPath);
  const rel = manifestPath.slice(REPO_ROOT.length + 1);
  let manifest;
  try {
    manifest = JSON.parse(readFileSync(manifestPath, 'utf-8'));
  } catch (e) {
    errors.push(`${rel}: invalid JSON — ${e.message}`);
    continue;
  }

  // (1) Zod schema
  if (mjAppManifestSchema) {
    const parsed = mjAppManifestSchema.safeParse(manifest);
    if (!parsed.success) errors.push(`${rel}: manifest fails schema — ${parsed.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join('; ')}`);
  }

  // (2) connector profile
  if (manifest.schema) errors.push(`${rel}: connector profile must NOT declare a 'schema' block`);
  if (manifest.migrations) errors.push(`${rel}: connector profile must NOT declare a 'migrations' block`);
  if (manifest.metadata?.processOnInstall !== true) errors.push(`${rel}: metadata.processOnInstall must be true`);

  // (3) shared bootstrap package
  const server = manifest.packages?.server ?? [];
  const pkg = server[0];
  if (!pkg || pkg.name !== SHARED_PACKAGE) errors.push(`${rel}: packages.server[0].name must be '${SHARED_PACKAGE}'`);
  else if (pkg.role !== 'bootstrap' || pkg.startupExport !== 'registerConnectors') errors.push(`${rel}: shared package must be role 'bootstrap' with startupExport 'registerConnectors'`);

  // (4) three-way invariant via the seeded Integration metadata
  const integDir = join(appDir, 'metadata', 'integration');
  if (!existsSync(integDir)) { errors.push(`${rel}: missing metadata/integration directory`); continue; }
  const integFile = readdirSync(integDir).find((f) => f.endsWith('.integration.json'));
  if (!integFile) { errors.push(`${rel}: no *.integration.json under metadata/integration`); continue; }
  const integRaw = JSON.parse(readFileSync(join(integDir, integFile), 'utf-8'));
  const recs = Array.isArray(integRaw) ? integRaw : [integRaw];
  const integ = recs.find((r) => r?.fields?.ClassName)?.fields;
  if (!integ) { errors.push(`${rel}: no Integration record (with ClassName) in ${integFile}`); continue; }
  if (integ.ImportPath !== SHARED_PACKAGE) errors.push(`${rel}: Integration.ImportPath must be '${SHARED_PACKAGE}' (was '${integ.ImportPath}')`);
  if (!classNames.has(integ.ClassName)) errors.push(`${rel}: Integration.ClassName '${integ.ClassName}' is not exported by ${SHARED_PACKAGE}`);
}

if (errors.length > 0) {
  console.error(`✗ ${errors.length} invariant violation(s) across ${manifests.length} connector Open App(s):\n`);
  for (const e of errors) console.error('  - ' + e);
  process.exit(1);
}
console.log(`✓ ${manifests.length} connector Open App(s) pass all invariants${mjAppManifestSchema ? '' : ' (schema check skipped — deps not installed)'}.`);
