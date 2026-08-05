#!/usr/bin/env node
/**
 * audit-unlistable-objects.mjs — find the objects that can only be read in ONE SHOT, and rank the ones
 * where that will eventually mean "zero rows behind a green run".
 *
 * ── THE BUG CLASS ────────────────────────────────────────────────────────────
 * An object declared with no pagination is read in a single request. On a small tenant that is fine and
 * common (lookup tables, code lists, a handful of categories). On a LARGE tenant the same declaration is a
 * time bomb: the request cannot complete inside the engine's `FetchChangesMs` (30000ms) budget, the batch
 * is KILLED, and a killed batch persists **nothing** — so the object lands zero rows while its entity map
 * still reports success. It reads as "this tenant has no people", not as an error, which is why it survives
 * review, survives the run artifact, and surfaces weeks later as "the client says records are missing".
 *
 * Totara `Users` shipped exactly this: `core_user_get_users` declares no pagination params and the vendor's
 * own docs say it "could [be] very slow or timeout" without narrow criteria. Against a real site it timed
 * out 3x at 30000ms and synced 0 of ~25,000 users, green the whole way.
 *
 * ── THE REMEDY, AND WHY THIS IS AN AUDIT AND NOT A GATE ──────────────────────
 * Nearly every API that cannot LIST an object can still read it BY KEY in bulk ("give me exactly these
 * ids"), which is an indexed lookup rather than a search. `@memberjunction/connector-id-window-scan` walks
 * the key space in bounded windows through that reader, so every request is bounded by construction and
 * the scan resumes across calls. Declaring `Configuration.idWindowScan` on the object is the whole fix.
 *
 * This is NOT a CI gate, deliberately. "Unpaginated" is not by itself a defect — most of the 700+ hits
 * below are genuinely small reference objects where one shot is correct, and a gate that fails on all of
 * them would be muted within a day, which is how gates die. Only a human who knows whether the object is
 * big on a real tenant can make the call, so this ranks the candidates and gets out of the way.
 *
 * The ranking is a NAME HEURISTIC, and it is stated as one: an object named like a transactional or
 * membership table is the kind that grows without bound. It is a prompt to check, never a verdict.
 *
 * Usage:  node scripts/audit-unlistable-objects.mjs [--all] [--connector <Name>]
 *           --all         list every hit, not just the high-risk ones
 *           --connector   restrict to one connector directory name (e.g. Totara)
 */
import { readFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));

/**
 * Objects whose row count tracks a tenant's SIZE rather than its configuration. These are the ones where a
 * one-shot read is a bet that every customer stays small — the bet Totara Users lost.
 */
const UNBOUNDED_SHAPES = [
    'user', 'member', 'contact', 'person', 'people', 'account', 'attendee', 'registrant', 'registration',
    'enrol', 'enroll', 'order', 'invoice', 'payment', 'transaction', 'donation', 'gift', 'subscription',
    'ticket', 'message', 'activity', 'event log', 'audit', 'submission', 'application', 'response',
    'certificate', 'completion', 'grade', 'attendance', 'note', 'interaction', 'engagement',
];

const args = process.argv.slice(2);
const showAll = args.includes('--all');
const onlyConnector = args[args.indexOf('--connector') + 1] && !args[args.indexOf('--connector') + 1].startsWith('--')
    ? args[args.indexOf('--connector') + 1]
    : null;

const files = execFileSync('find', ['.', '-path', './node_modules', '-prune', '-o', '-name', '*.integration.json', '-print'], {
    cwd: ROOT, encoding: 'utf8',
}).split('\n').filter(Boolean);

/** Metadata files nest object records at arbitrary depth; an object is any `fields` block declaring PaginationType. */
function collectObjects(node, out = []) {
    if (Array.isArray(node)) { for (const child of node) collectObjects(child, out); return out; }
    if (node && typeof node === 'object') {
        if (node.fields && typeof node.fields === 'object' && 'PaginationType' in node.fields) out.push(node.fields);
        for (const value of Object.values(node)) collectObjects(value, out);
    }
    return out;
}

const rows = [];
for (const file of files) {
    const connector = file.split('/')[2];
    if (onlyConnector && connector !== onlyConnector) continue;
    let parsed;
    try { parsed = JSON.parse(readFileSync(`${ROOT}/${file}`, 'utf8')); } catch { continue; }
    for (const obj of collectObjects(parsed)) {
        const pagination = obj.PaginationType || 'None';
        if (pagination !== 'None') continue;
        const config = String(obj.Configuration ?? '');
        // Already handled: a parent-scoped walk is bounded by its parent list, and an id-window scan IS the fix.
        if (config.includes('parentScope') || config.includes('idWindowScan')) continue;
        const name = String(obj.Name ?? '(unnamed)');
        const lower = name.toLowerCase();
        const risky = UNBOUNDED_SHAPES.some((shape) => lower.includes(shape));
        rows.push({ connector, name, risky });
    }
}

const high = rows.filter((r) => r.risky);
const byConnector = new Map();
for (const row of showAll ? rows : high) {
    if (!byConnector.has(row.connector)) byConnector.set(row.connector, []);
    byConnector.get(row.connector).push(row.name);
}

console.log(`\nOne-shot readers (PaginationType 'None', no parent scope, no id-window scan): ${rows.length}`);
console.log(`Of those, named like an unbounded table — check these first: ${high.length}\n`);

for (const [connector, names] of [...byConnector.entries()].sort((a, b) => b[1].length - a[1].length)) {
    console.log(`  ${connector} (${names.length})`);
    for (const name of names.sort()) console.log(`      ${name}`);
}

console.log(`
The remedy where the vendor offers a bulk-by-key reader:

    Configuration.idWindowScan = {
      "wsFunction": "<the bulk-by-key endpoint>",   // connector-specific name for it
      "field": "id", "windowSize": 25, "windowsPerCall": 2,
      "maxConsecutiveEmptyWindows": 40, "budgetMs": 20000, "maxBisectSplitsPerCall": 8
    }

and delegate the fetch to runIdWindowScan() from @memberjunction/connector-id-window-scan (see
LMS/Totara/src/TotaraConnector.ts for a worked example — it supplies only the vendor-specific
"turn these ids into a request" callback).

Ranking is a NAME HEURISTIC, not a verdict. An object listed here is fine if it is genuinely small on every
tenant; one NOT listed is still a hazard if it happens to be big. The question is always the same: on your
largest customer, can this object be read in a single request inside 30 seconds?
`);
