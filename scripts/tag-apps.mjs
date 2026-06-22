#!/usr/bin/env node
/**
 * After `changeset publish`, creates the per-connector SUBPATH-scoped git tags the MJ install engine
 * resolves: `<Category>-<Connector>@<version>` (e.g. `CRM-HubSpot@1.2.0`). The install is given the
 * subpath (`CRM/HubSpot`) and looks for tags named `<subpath-with-dashes>@<version>` — so this maps each
 * connector directory to its current package version and tags it. (changesets' own `<pkg>@<version>` tags
 * remain too; these subpath tags are what `mj app install …/CRM/HubSpot --version X` uses.)
 *
 * Idempotent: skips a tag that already exists. Pushes the new tags. Run as the last release step.
 */
import { readFileSync, readdirSync, statSync, existsSync } from 'node:fs';
import { join, dirname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
function manifests(dir, out = []) {
  for (const e of readdirSync(dir)) {
    if (['node_modules', 'dist', '.git', '.github', '.changeset', 'scripts', 'packages'].includes(e)) continue;
    const p = join(dir, e);
    if (statSync(p).isDirectory()) manifests(p, out);
    else if (e === 'mj-app.json') out.push(p);
  }
  return out;
}
const git = (...args) => execFileSync('git', args, { cwd: ROOT, stdio: 'pipe' }).toString().trim();
const tagExists = (t) => { try { git('rev-parse', '-q', '--verify', `refs/tags/${t}`); return true; } catch { return false; } };

const created = [];
for (const mPath of manifests(ROOT)) {
  const appDir = dirname(mPath);
  const pkgPath = join(appDir, 'package.json');
  if (!existsSync(pkgPath)) continue;
  const version = JSON.parse(readFileSync(pkgPath, 'utf-8')).version;
  const subpath = relative(ROOT, appDir).replace(/\\/g, '/'); // e.g. CRM/HubSpot
  const tag = `${subpath.replace(/\//g, '-')}@${version}`;     // e.g. CRM-HubSpot@1.2.0
  if (tagExists(tag)) continue;
  git('tag', tag);
  created.push(tag);
}

if (created.length) {
  git('push', 'origin', ...created.map((t) => `refs/tags/${t}`));
  console.log(`Created + pushed ${created.length} connector tag(s):\n  ${created.join('\n  ')}`);
} else {
  console.log('No new connector tags (all current versions already tagged).');
}
