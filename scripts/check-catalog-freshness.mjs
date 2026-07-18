#!/usr/bin/env node
/**
 * check-catalog-freshness.mjs — branch-vs-tag catalog freshness gate (concern A9).
 *
 * THE DRIFT this catches: releases are cut on `main` and tagged `<Category>-<Connector>@<ver>`,
 * but the version-bump commit is frequently NEVER merged back to `next` — so `next`'s
 * package.json (and therefore the generated connectors-catalog.json, which bakes
 * `version` + `installTag` from package.json) LAGS the newest published tag. The old
 * freshness gate (`build-connectors-catalog.mjs --check`) only compares WITHIN the
 * branch (catalog vs package.json on `next`); it is blind to `next`-vs-tag drift.
 * This gate closes that gap: for every connector it compares the working-tree
 * package.json version to the highest semver git tag for that connector, and FAILS
 * when the tree lags a tag (i.e. a published release never made it back to `next`).
 *
 * Resolution note (A9 part a): installs/upgrades resolve BY TAG — the catalog's
 * `installTag` field is literally `<Category>-<Connector>@<version>`, a git tag ref,
 * and nothing in this repo reads a connector version from the live `next` branch at
 * install time. So this drift is repo-hygiene (stale conservative defaults authored on
 * `next`), not per-install correctness — but it must be reconciled so `next` == truth.
 *
 * Requires full tag history: in CI use `actions/checkout` with `fetch-depth: 0` (or
 * `git fetch --tags --force`) so every `<Category>-<Connector>@x.y.z` tag is present.
 *
 *   node scripts/check-catalog-freshness.mjs           # report + exit 1 if any lag (CI gate)
 *   node scripts/check-catalog-freshness.mjs --report  # report only, always exit 0
 *   node scripts/check-catalog-freshness.mjs --public-only  # ignore private (held) connectors
 *   node scripts/check-catalog-freshness.mjs --json    # machine-readable lag list
 */
import { readFileSync, readdirSync, statSync, existsSync } from 'node:fs';
import { join, dirname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execSync } from 'node:child_process';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const REPORT_ONLY = process.argv.includes('--report');
const PUBLIC_ONLY = process.argv.includes('--public-only');
const JSON_OUT = process.argv.includes('--json');
const SKIP_DIRS = new Set(['node_modules', 'dist', '.git', '.github', '.changeset', 'scripts', '.turbo']);

// A connector dir = a folder holding both mj-app.json and package.json.
function findConnectors(dir, out = []) {
  for (const e of readdirSync(dir)) {
    if (SKIP_DIRS.has(e)) continue;
    const p = join(dir, e);
    let st; try { st = statSync(p); } catch { continue; }
    if (st.isDirectory()) {
      if (existsSync(join(p, 'mj-app.json')) && existsSync(join(p, 'package.json'))) out.push(p);
      else findConnectors(p, out);
    }
  }
  return out;
}

const SEMVER = /^(\d+)\.(\d+)\.(\d+)$/;
function cmpSemver(a, b) {
  const pa = a.match(SEMVER), pb = b.match(SEMVER);
  for (let i = 1; i <= 3; i++) { const d = Number(pa[i]) - Number(pb[i]); if (d) return d; }
  return 0;
}

let allTags = [];
try { allTags = execSync('git tag', { cwd: ROOT, encoding: 'utf8' }).split('\n').filter(Boolean); }
catch { console.error('Could not list git tags (is this a git checkout with tags fetched?)'); process.exit(2); }

if (allTags.length === 0) {
  console.error('✗ No git tags found. In CI, checkout with fetch-depth: 0 (or run `git fetch --tags --force`) so tag-vs-branch drift is visible.');
  process.exit(2);
}

const rows = [];
for (const dir of findConnectors(ROOT)) {
  const repoSubpath = relative(ROOT, dir).replace(/\\/g, '/'); // e.g. AMS/GrowthZone
  const [category, connectorDir] = repoSubpath.split('/');
  const pkg = JSON.parse(readFileSync(join(dir, 'package.json'), 'utf8'));
  const isPrivate = pkg.private === true;
  if (PUBLIC_ONLY && isPrivate) continue;
  const prefix = `${category}-${connectorDir}@`;
  const versions = allTags.filter((t) => t.startsWith(prefix)).map((t) => t.slice(prefix.length)).filter((v) => SEMVER.test(v));
  versions.sort(cmpSemver);
  const newestTag = versions[versions.length - 1] ?? null;
  const lag = !!newestTag && SEMVER.test(pkg.version) && cmpSemver(pkg.version, newestTag) < 0;
  rows.push({ repoSubpath, isPrivate, branchVersion: pkg.version, newestTag, lag });
}
rows.sort((a, b) => a.repoSubpath.localeCompare(b.repoSubpath));

const lagging = rows.filter((r) => r.lag);

if (JSON_OUT) {
  console.log(JSON.stringify({ total: rows.length, lagging: lagging.length, connectors: lagging.map((r) => ({ connector: r.repoSubpath, next: r.branchVersion, newestTag: r.newestTag, private: r.isPrivate })) }, null, 2));
} else {
  console.log(`Catalog freshness — next (package.json) vs newest git tag, ${rows.length} connector(s):\n`);
  for (const r of lagging) {
    console.log(`  LAG  ${r.repoSubpath.padEnd(38)} next=${String(r.branchVersion).padEnd(9)} newestTag=${r.newestTag}${r.isPrivate ? '  (private)' : ''}`);
  }
  if (!lagging.length) console.log('  (none — every connector on next is at or ahead of its newest tag)');
  console.log(`\n${lagging.length} lagging / ${rows.length} connectors${PUBLIC_ONLY ? ' (public only)' : ''}.`);
  if (lagging.length) {
    console.log(`\nEach lagging connector had a release cut+tagged on main whose version-bump was never merged back to next.`);
    console.log(`Reconcile by merging each release's version-bump (package.json + mj-app.json + CHANGELOG) back into next,`);
    console.log(`then regenerate the catalog (node scripts/build-connectors-catalog.mjs). See A9 in the concern register.`);
  }
}

if (!REPORT_ONLY && lagging.length) process.exit(1);
