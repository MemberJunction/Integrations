#!/usr/bin/env node
/**
 * Keeps each connector's mj-app.json in sync with its package after `changeset version`:
 *   - mj-app.json.version      ← the connector package.json version
 *   - mj-app.json.mjVersionRange ← derived from the connector's @memberjunction/core peer-dep range
 *     (e.g. ">=5.43.0 <6.0.0"), so the Open App's MJ compatibility matches the framework it builds against.
 * Run as part of the `version` step (after changeset version) so the bump + sync commit together.
 * Mirrors the bizapps publish.yml "Sync mj-app.json version and MJ version range" step, per-connector.
 */
import { readFileSync, writeFileSync, readdirSync, statSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

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

let n = 0;
for (const mPath of manifests(ROOT)) {
  const appDir = dirname(mPath);
  const pkgPath = join(appDir, 'package.json');
  if (!existsSync(pkgPath)) continue;
  const m = JSON.parse(readFileSync(mPath, 'utf-8'));
  const pkg = JSON.parse(readFileSync(pkgPath, 'utf-8'));
  let changed = false;

  if (m.version !== pkg.version) { m.version = pkg.version; changed = true; }

  const coreRange = pkg.peerDependencies?.['@memberjunction/core'] ?? pkg.dependencies?.['@memberjunction/core'];
  if (coreRange) {
    // Take the peer range VERBATIM. mjVersionRange and the @memberjunction/core peer range are two
    // statements of one fact, so deriving one from the other is the bug, not the feature.
    //
    // This previously read the MINIMUM out of the range and computed the ceiling as major+1:
    //     const range = `>=${min[0]} <${Number(min[1]) + 1}.0.0`;
    // which is right only while every connector's ceiling happens to be min-major+1. It was, for 54 of
    // 55. Business Central widened its peers to `<7.0.0` for MJ 6.x and the script kept rewriting its
    // manifest to `<6.0.0`, so `mjdev app register` rejected the connector on a 6.x host even though its
    // package advertised support (issue #208). Setting the manifest by hand did not hold either — the
    // next release ran this and reverted it.
    const explicit = coreRange.trim().match(/^>=\s*\d+\.\d+\.\d+\s+<\s*\d+\.\d+\.\d+$/);
    let range;
    if (explicit) {
      range = coreRange.trim().replace(/\s+/g, ' ');
    } else {
      // Anything not in `>=X <Y` form (a caret, a bare version) has no ceiling to copy, so fall back to
      // the old derivation rather than emitting something the manifest schema will not accept.
      const min = coreRange.match(/(\d+)\.(\d+)\.(\d+)/);
      if (!min) continue;
      range = `>=${min[0]} <${Number(min[1]) + 1}.0.0`;
      console.warn(`  ${appDir}: peer range "${coreRange}" has no explicit ceiling — derived ${range}`);
    }
    if (m.mjVersionRange !== range) { m.mjVersionRange = range; changed = true; }
  }
  if (changed) { writeFileSync(mPath, JSON.stringify(m, null, 2) + '\n'); n++; }
}
console.log(`Synced ${n} mj-app.json version/mjVersionRange to their packages.`);
