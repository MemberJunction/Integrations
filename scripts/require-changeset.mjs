#!/usr/bin/env node
/**
 * require-changeset.mjs — an npm-AWARE changeset gate.
 *
 * Replaces the blanket `npx changeset status`, which false-fails EVERY connector change that has no
 * changeset — even when none is needed. In this repo connectors publish via the no-changeset path
 * (`changeset publish` picks up any non-private package whose version isn't on npm yet), so a NEW
 * connector at 1.0.0 needs no changeset. A changeset is genuinely required ONLY for a connector whose
 * CURRENT package.json version is ALREADY on npm — because shipping a further change then requires a
 * version bump, and that bump comes from a changeset. Private connectors never publish, so they're exempt.
 *
 * Red iff there's a real problem (a published connector changed with no bump), green otherwise.
 *
 * Usage: node scripts/require-changeset.mjs <baseRef>     # e.g. origin/next
 */
import { execSync } from 'node:child_process';
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join, dirname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { get } from 'node:https';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const baseRef = process.argv[2] || 'origin/next';
const sh = (cmd) => execSync(cmd, { cwd: ROOT, encoding: 'utf8' }).trim();

// 1. Changed files vs base → the connector dirs (nearest ancestor with an mj-app.json) that changed.
let changed = [];
let diffBase = baseRef;
try {
  changed = sh(`git diff --name-only ${baseRef}...HEAD`).split('\n').filter(Boolean);
  diffBase = sh(`git merge-base ${baseRef} HEAD`);
} catch { changed = sh(`git diff --name-only ${baseRef}`).split('\n').filter(Boolean); }

// ── Back-merge exemption ────────────────────────────────────────────────────────
// A back-merge (main → next) carries the release commits' version bumps for every
// connector that shipped. Each of those versions is BY DEFINITION already on npm —
// that's what publishing did — so the npm check below fires on all of them at once
// and demands a changeset. Satisfying it would bump each connector a SECOND time
// for a release that already happened, minting phantom versions.
//
// So: a connector whose entire diff vs. base is release metadata — package.json
// differing only in `version`, mj-app.json only in `version`/`mjVersionRange`,
// plus CHANGELOG.md — is a published release being reconciled, not new work.
// Anything else in the diff (source, metadata/, migrations/, deps, scripts) means
// real change, and the gate applies with full force.
const RELEASE_META_FILES = new Set(['package.json', 'mj-app.json', 'CHANGELOG.md']);
const RELEASE_META_KEYS = { 'package.json': ['version'], 'mj-app.json': ['version', 'mjVersionRange'] };

const showAtBase = (relPath) => {
  try { return JSON.parse(sh(`git show ${diffBase}:${relPath}`)); } catch { return null; }
};

/** True iff only the allowed keys differ between the base and head copies of a JSON file. */
function onlyAllowedKeysDiffer(relPath, allowed) {
  const before = showAtBase(relPath);
  if (!before) return false;                                   // new file → not a pure bump
  const after = JSON.parse(readFileSync(join(ROOT, relPath), 'utf8'));
  const keys = new Set([...Object.keys(before), ...Object.keys(after)]);
  for (const k of keys) {
    if (JSON.stringify(before[k]) !== JSON.stringify(after[k]) && !allowed.includes(k)) return false;
  }
  return true;
}

function isReleaseBumpOnly(dirAbs) {
  const prefix = relative(ROOT, dirAbs);
  const files = changed.filter((f) => f.startsWith(`${prefix}/`)).map((f) => f.slice(prefix.length + 1));
  if (files.length === 0) return false;
  if (!files.every((f) => RELEASE_META_FILES.has(f))) return false;
  for (const [file, allowed] of Object.entries(RELEASE_META_KEYS)) {
    if (files.includes(file) && !onlyAllowedKeysDiffer(`${prefix}/${file}`, allowed)) return false;
  }
  return true;
}

const connectorDirs = new Set();
for (const f of changed) {
  let d = dirname(join(ROOT, f));
  while (d.startsWith(ROOT) && d !== ROOT) {
    if (existsSync(join(d, 'mj-app.json')) && existsSync(join(d, 'package.json'))) { connectorDirs.add(d); break; }
    d = dirname(d);
  }
}

// 2. Changeset coverage: package names named in .changeset/*.md frontmatter.
const covered = new Set();
const csDir = join(ROOT, '.changeset');
if (existsSync(csDir)) {
  for (const f of readdirSync(csDir).filter((x) => x.endsWith('.md') && x.toLowerCase() !== 'readme.md')) {
    for (const m of readFileSync(join(csDir, f), 'utf8').matchAll(/^["']?(@[^"'\s:]+)["']?\s*:/gm)) covered.add(m[1]);
  }
}

// 3. Is name@version already on npm?
const onNpm = (name, version) => new Promise((resolve) => {
  get(`https://registry.npmjs.org/${encodeURIComponent(name).replace('%40', '@')}/${version}`, (res) => { res.resume(); resolve(res.statusCode === 200); })
    .on('error', () => resolve(false));
});

const need = [];
const reconciled = [];
for (const d of connectorDirs) {
  const pkg = JSON.parse(readFileSync(join(d, 'package.json'), 'utf8'));
  if (pkg.private) continue;                                   // never publishes → no changeset needed
  if (isReleaseBumpOnly(d)) {                                  // back-merge of an already-shipped release
    reconciled.push(`${pkg.name}@${pkg.version}`);
    continue;
  }
  if (await onNpm(pkg.name, pkg.version) && !covered.has(pkg.name)) {
    need.push(`${pkg.name}@${pkg.version}`);                   // already on npm + changed + uncovered
  }
}

if (reconciled.length) {
  console.log(`  (${reconciled.length} connector(s) exempt: release metadata only — a back-merge of versions already published)`);
  for (const n of reconciled) console.log(`    · ${n}`);
}

if (need.length) {
  console.error(`✗ ${need.length} already-published connector(s) changed with no covering changeset — a version bump is required to ship the change:`);
  for (const n of need) console.error(`  - ${n}   → run: npx changeset`);
  process.exit(1);
}
console.log(`✓ changeset gate: nothing requires a changeset (${connectorDirs.size} connector(s) changed; new/unpublished ones ship via the no-changeset publish path).`);
