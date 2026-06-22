#!/usr/bin/env node
/**
 * Floor-check for the Integrations repo. Each connector is its OWN self-contained Open App package.
 * For every connector Open App (any directory with an mj-app.json) this asserts:
 *
 *  1. The manifest passes the real MJ Open App Zod schema (mjAppManifestSchema).
 *  2. It is a CONNECTOR PROFILE: no `schema`, no `migrations`, metadata.processOnInstall === true.
 *  3. The Open App owns its package: packages.server[0].name === the sibling package.json `name`,
 *     role 'bootstrap', startupExport 'registerConnector', and that export exists in src/index.ts.
 *  4. The three-way invariant: packages.server[0].name === the seeded Integration's ImportPath, and
 *     that Integration's ClassName (@RegisterClass driver) is exported by this package's own source.
 *
 * Run in CI after `npm install` (the schema comes from the @memberjunction/open-app-engine devDep).
 */
import { readFileSync, readdirSync, statSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const REPO_ROOT = dirname(dirname(fileURLToPath(import.meta.url)));

let mjAppManifestSchema;
try { ({ mjAppManifestSchema } = await import('@memberjunction/open-app-engine')); }
catch { console.warn('⚠ @memberjunction/open-app-engine not installed — skipping Zod manifest validation (run after npm install).'); }

function findManifests(dir, out = []) {
  for (const entry of readdirSync(dir)) {
    if (['node_modules', 'dist', '.git', '.turbo', 'scripts', '.changeset', '.github'].includes(entry)) continue;
    const p = join(dir, entry);
    if (statSync(p).isDirectory()) findManifests(p, out);
    else if (entry === 'mj-app.json') out.push(p);
  }
  return out;
}

/** Class names exported by an Open App's own package (parsed from src/index.ts + the connector source). */
function exportedClasses(appDir) {
  const names = new Set();
  const idx = join(appDir, 'src', 'index.ts');
  for (const file of [idx]) {
    if (!existsSync(file)) continue;
    const src = readFileSync(file, 'utf-8');
    for (const m of src.matchAll(/export\s*\*\s*from\s*['"]\.\/(\w+)\.js['"]/g)) {
      const cf = join(appDir, 'src', `${m[1]}.ts`);
      if (existsSync(cf)) for (const r of readFileSync(cf, 'utf-8').matchAll(/@RegisterClass\([^,]+,\s*['"](\w+)['"]/g)) names.add(r[1]);
    }
    for (const m of src.matchAll(/export\s*\{\s*([A-Za-z0-9_]+)/g)) names.add(m[1]);
  }
  return names;
}

const errors = [];
const manifests = findManifests(REPO_ROOT);
for (const manifestPath of manifests) {
  const appDir = dirname(manifestPath);
  const rel = manifestPath.slice(REPO_ROOT.length + 1);
  let manifest;
  try { manifest = JSON.parse(readFileSync(manifestPath, 'utf-8')); }
  catch (e) { errors.push(`${rel}: invalid JSON — ${e.message}`); continue; }

  if (mjAppManifestSchema) {
    const parsed = mjAppManifestSchema.safeParse(manifest);
    if (!parsed.success) errors.push(`${rel}: manifest fails schema — ${parsed.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join('; ')}`);
  }
  if (manifest.schema) errors.push(`${rel}: connector profile must NOT declare a 'schema' block`);
  if (manifest.migrations) errors.push(`${rel}: connector profile must NOT declare a 'migrations' block`);
  if (manifest.metadata?.processOnInstall !== true) errors.push(`${rel}: metadata.processOnInstall must be true`);

  // (3) owns its package
  const pkgPath = join(appDir, 'package.json');
  if (!existsSync(pkgPath)) { errors.push(`${rel}: missing sibling package.json (each Open App is its own package)`); continue; }
  const pkgName = JSON.parse(readFileSync(pkgPath, 'utf-8')).name;
  const server = manifest.packages?.server ?? [];
  const pkg = server[0];
  if (!pkg || pkg.name !== pkgName) errors.push(`${rel}: packages.server[0].name must be this Open App's own package '${pkgName}' (was '${pkg?.name}')`);
  else if (pkg.role !== 'bootstrap' || pkg.startupExport !== 'registerConnector') errors.push(`${rel}: package must be role 'bootstrap' with startupExport 'registerConnector'`);
  const classes = exportedClasses(appDir);
  if (!classes.has('registerConnector') && !existsSync(join(appDir, 'src', 'index.ts'))) errors.push(`${rel}: missing src/index.ts`);

  // (4) three-way invariant
  const integDir = join(appDir, 'metadata', 'integration');
  if (!existsSync(integDir)) { errors.push(`${rel}: missing metadata/integration`); continue; }
  const integFile = readdirSync(integDir).find((f) => f.endsWith('.integration.json'));
  const integRaw = JSON.parse(readFileSync(join(integDir, integFile), 'utf-8'));
  const recs = Array.isArray(integRaw) ? integRaw : [integRaw];
  const integ = recs.find((r) => r?.fields?.ClassName)?.fields;
  if (!integ) { errors.push(`${rel}: no Integration record in ${integFile}`); continue; }
  if (integ.ImportPath !== pkgName) errors.push(`${rel}: Integration.ImportPath must be '${pkgName}' (was '${integ.ImportPath}')`);
  if (!classes.has(integ.ClassName)) errors.push(`${rel}: Integration.ClassName '${integ.ClassName}' is not @RegisterClass-exported by this package`);
}

if (errors.length) {
  console.error(`✗ ${errors.length} invariant violation(s) across ${manifests.length} connector Open App(s):\n`);
  for (const e of errors) console.error('  - ' + e);
  process.exit(1);
}
console.log(`✓ ${manifests.length} connector Open App(s) pass all invariants${mjAppManifestSchema ? '' : ' (schema check skipped — deps not installed)'}.`);
