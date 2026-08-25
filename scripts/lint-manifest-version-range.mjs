#!/usr/bin/env node
/**
 * lint-manifest-version-range.mjs — assert mj-app.json.mjVersionRange equals the connector's
 * @memberjunction/core peer range.
 *
 * WHY THIS GATE EXISTS
 *   The two values are two statements of one fact: which MemberJunction majors the connector supports.
 *   package.json's peer range is what npm enforces at install; mj-app.json's mjVersionRange is what MJ
 *   reads to gate `mjdev app register` / link. When they disagree, the connector is installable by one
 *   rule and rejected by the other, and the failure surfaces on a customer's host rather than in CI.
 *
 *   That happened. Business Central widened its peers to `>=5.43.0 <7.0.0` for MJ 6.x while its manifest
 *   stayed `<6.0.0`, so `mjdev app register` rejected it on a 6.1.0 host even though the package
 *   advertised support (issue #208). The cause was sync-manifest-versions.mjs deriving the ceiling as
 *   min-major+1 instead of reading the declared one — correct for 54 of 55 connectors by coincidence,
 *   wrong for the one that had actually been widened, and it reverted any manual correction on the next
 *   release.
 *
 *   The derivation is fixed. This gate is what stops the class from returning: if a peer range moves and
 *   the manifest does not, CI fails here instead of a customer's install failing later.
 *
 *   Run: node scripts/lint-manifest-version-range.mjs
 */
import { readFileSync, readdirSync, statSync, existsSync } from 'node:fs';
import { join, dirname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));

function manifests(dir, out = []) {
    for (const entry of readdirSync(dir)) {
        if (entry === 'node_modules' || entry === '.git' || entry.startsWith('.')) continue;
        const full = join(dir, entry);
        if (!statSync(full).isDirectory()) continue;
        if (existsSync(join(full, 'mj-app.json'))) out.push(join(full, 'mj-app.json'));
        else manifests(full, out);
    }
    return out;
}

const problems = [];
let checked = 0;

for (const mPath of manifests(ROOT)) {
    const appDir = dirname(mPath);
    const pkgPath = join(appDir, 'package.json');
    if (!existsSync(pkgPath)) continue;

    const m = JSON.parse(readFileSync(mPath, 'utf-8'));
    const pkg = JSON.parse(readFileSync(pkgPath, 'utf-8'));
    const coreRange =
        pkg.peerDependencies?.['@memberjunction/core'] ?? pkg.dependencies?.['@memberjunction/core'];

    if (!coreRange) continue; // no MJ core dependency — nothing to agree with
    checked++;

    const expected = coreRange.trim().replace(/\s+/g, ' ');
    const actual = (m.mjVersionRange ?? '').trim().replace(/\s+/g, ' ');

    // Only compare when the peer range states an explicit ceiling. A caret or bare version has no
    // ceiling to copy, so the manifest is legitimately derived rather than mirrored.
    if (!/^>=\s*\d+\.\d+\.\d+\s+<\s*\d+\.\d+\.\d+$/.test(expected)) continue;

    if (actual !== expected) {
        problems.push({ dir: relative(ROOT, appDir), actual: actual || '(missing)', expected });
    }
}

if (problems.length) {
    console.error('✗ manifest version-range gate: mjVersionRange disagrees with the @memberjunction/core peer range.\n');
    for (const p of problems) {
        console.error(`  ${p.dir}`);
        console.error(`      mj-app.json  mjVersionRange : ${p.actual}`);
        console.error(`      package.json core peer      : ${p.expected}\n`);
    }
    console.error('  These are two statements of one fact. npm enforces the peer range at install; MJ reads');
    console.error('  mjVersionRange to gate `mjdev app register`, so a disagreement makes the connector');
    console.error('  installable by one rule and rejected by the other.\n');
    console.error('  Fix: node scripts/sync-manifest-versions.mjs');
    process.exit(1);
}

console.log(`✓ manifest version-range gate: ${checked} connector(s) — mjVersionRange matches the @memberjunction/core peer range.`);
