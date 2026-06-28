#!/usr/bin/env node
/**
 * build-connectors-catalog.mjs — generates connectors-catalog.json: the declarative
 * source of truth for "which connectors a consumer CAN install" (the browse/gallery layer).
 *
 * This is the LIGHTWEIGHT tier. The heavy per-connector IO/IOF schema is NOT here —
 * that ships inside `mj app install` (the seed migration seeds Integration + IntegrationObject
 * + IntegrationObjectField into __mj). The catalog is just enough to render a "choose a system"
 * gallery and then install on select.
 *
 * Per PUBLISHED (non-private) connector Open App it merges the two name-bearing files:
 *   - metadata/integration/.<vendor>.integration.json — the MJ: Integrations row: the VENDOR
 *     Name the user picks (e.g. "GrowthZone"), ClassName (resolution key), Description, Icon
 *     (the LOGO), NavigationBaseURL — and the IO count (a cheap richness hint, NOT the IO/IOF).
 *   - mj-app.json — displayName, categories/tags, version, npm package.
 *   - the <Category>/<Connector> folder — install tag + subpath.
 *
 * Held (private) connectors are excluded — they aren't installable. Output is deterministic
 * (sorted, no timestamp) so re-runs only diff when a connector actually changes.
 *
 *   node scripts/build-connectors-catalog.mjs            # write connectors-catalog.json
 *   node scripts/build-connectors-catalog.mjs --check    # CI: fail if the catalog is stale
 */
import { readFileSync, writeFileSync, readdirSync, existsSync, statSync } from 'node:fs';
import { join, dirname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const CHECK = process.argv.includes('--check');

function findManifests(dir, out = []) {
  for (const e of readdirSync(dir)) {
    if (['node_modules', 'dist', '.git', '.github', '.changeset', 'scripts', '.turbo'].includes(e)) continue;
    const p = join(dir, e);
    let st; try { st = statSync(p); } catch { continue; }
    if (st.isDirectory()) findManifests(p, out);
    else if (e === 'mj-app.json') out.push(p);
  }
  return out;
}

// The Integration row lives in the metadata/integration/.<vendor>.integration.json whose
// record carries fields.ClassName. Returns { fields, objectCount } or null.
function readIntegrationRow(appDir) {
  const metaDir = join(appDir, 'metadata', 'integration');
  if (!existsSync(metaDir)) return null;
  for (const f of readdirSync(metaDir).filter((f) => f.endsWith('.json'))) {
    let recs;
    try { recs = JSON.parse(readFileSync(join(metaDir, f), 'utf8')); } catch { continue; }
    const list = Array.isArray(recs) ? recs : [recs];
    const rec = list.find((r) => r?.fields?.ClassName);
    if (rec) {
      const ios = rec.relatedEntities?.['MJ: Integration Objects'];
      return { fields: rec.fields, objectCount: Array.isArray(ios) ? ios.length : null };
    }
  }
  return null;
}

const connectors = [];
const problems = [];
for (const m of findManifests(ROOT)) {
  const appDir = dirname(m);
  const repoSubpath = relative(ROOT, appDir).replace(/\\/g, '/'); // e.g. AMS/GrowthZone
  const [category, connectorDir] = repoSubpath.split('/');
  const pkg = JSON.parse(readFileSync(join(appDir, 'package.json'), 'utf8'));
  if (pkg.private === true) continue; // held → not installable → not in the catalog
  const app = JSON.parse(readFileSync(m, 'utf8'));
  const integ = readIntegrationRow(appDir);
  if (!integ?.fields?.Name) { problems.push(`${repoSubpath}: no Integration.Name in metadata`); continue; }
  const f = integ.fields;

  connectors.push({
    name: f.Name,                                    // VENDOR name — what the user picks ("GrowthZone")
    displayName: app.displayName ?? f.Name,
    description: f.Description ?? app.description ?? '',
    category,                                         // nicely-cased folder segment (AMS, Events, CRM, …)
    tags: app.tags ?? [],
    logo: f.Icon ?? app.icon ?? null,                // LOGO — the connector's own metadata Icon only (no external fetch)
    navigationBaseURL: f.NavigationBaseURL ?? null,
    objectCount: integ.objectCount,                  // cheap richness hint; full IO/IOF arrives with install
    className: f.ClassName,                           // resolution key (== npm package)
    npmPackage: pkg.name,                             // install source
    version: pkg.version,
    mjVersionRange: app.mjVersionRange ?? null,
    repoSubpath,                                      // mj app install …/<repoSubpath>
    installTag: `${category}-${connectorDir}@${pkg.version}`, // the <Category>-<Connector>@<version> git tag
  });
}

connectors.sort((a, b) => (a.category + '/' + a.name).localeCompare(b.category + '/' + b.name));
const out = JSON.stringify({ schemaVersion: 1, count: connectors.length, connectors }, null, 2) + '\n';
const target = join(ROOT, 'connectors-catalog.json');

if (problems.length) { console.error('Catalog problems:\n  ' + problems.join('\n  ')); process.exit(1); }

if (CHECK) {
  const current = existsSync(target) ? readFileSync(target, 'utf8') : '';
  if (current !== out) { console.error('connectors-catalog.json is STALE — run: node scripts/build-connectors-catalog.mjs'); process.exit(1); }
  console.log(`connectors-catalog.json up to date (${connectors.length} installable connectors).`);
} else {
  writeFileSync(target, out);
  console.log(`Wrote connectors-catalog.json — ${connectors.length} installable connectors.`);
}
