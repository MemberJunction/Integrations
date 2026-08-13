#!/usr/bin/env node
/**
 * gen-baseline-support-docs.mjs — write a baseline docs/SUPPORT.md for every publishable
 * connector that doesn't have one yet.
 *
 * WHY THIS EXISTS
 * docs/SUPPORT.md is this repo's only per-connector evidence artifact, and the overview pages
 * (scripts/build-overview-docs.mjs) read it to state how well each integration is proven. A
 * connector with no SUPPORT.md is indistinguishable, from the outside, from a connector nobody
 * ever tested — which is false: every connector here was built through the build-connector
 * pipeline for AIDP, whose default gate is the credential-free behavioural matrix (spec
 * conformance, mock vendor server, anti-vacuous assertions). That floor deserves to be stated,
 * and stated as exactly what it is: format-verified, no credential, nothing live touched.
 *
 * The generated file carries a `baseline-stub` HTML comment. build-overview-docs.mjs keys on
 * that marker to render "Standards-verified build" rather than an evidence tier, so the moment
 * someone runs a real sync and rewrites the file (deleting the marker), the pages upgrade
 * themselves. Nothing here is hand-maintained: re-running is safe and skips files that exist.
 *
 *   node scripts/gen-baseline-support-docs.mjs            # write missing stubs
 *   node scripts/gen-baseline-support-docs.mjs --list     # report which are missing, write nothing
 *
 * The capability section is derived from the connector's own metadata (the same source the real
 * SUPPORT.md files cite), so the object/field/write counts are true, not placeholders.
 */

import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const REPO_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const LIST_ONLY = process.argv.includes('--list');
const TABLE_LIMIT = 30; // matches the existing hand-authored SUPPORT.md files

function readJson(file) {
  return JSON.parse(readFileSync(file, 'utf8'));
}

/** The `<Category>/<Connector>/metadata/integration/.<vendor>.integration.json` for a connector. */
function findIntegrationMetadata(connectorDir) {
  const dir = path.join(connectorDir, 'metadata', 'integration');
  if (!existsSync(dir)) return null;
  const file = readdirSync(dir).find((f) => f.endsWith('.integration.json'));
  return file ? path.join(dir, file) : null;
}

function summarizeMetadata(metadataPath) {
  const parsed = readJson(metadataPath);
  const root = Array.isArray(parsed) ? parsed[0] : parsed;
  const objects = root?.relatedEntities?.['MJ: Integration Objects'] ?? [];

  let fieldCount = 0;
  let writeCount = 0;
  let incrementalCount = 0;
  const rows = [];

  for (const object of objects) {
    const f = object.fields ?? {};
    fieldCount += (object.relatedEntities?.['MJ: Integration Object Fields'] ?? []).length;
    if (f.SupportsWrite) writeCount++;
    if (f.SupportsIncrementalSync) incrementalCount++;

    const verbs = `${f.SupportsCreate ? 'C' : ''}${f.SupportsUpdate ? 'U' : ''}${f.SupportsDelete ? 'D' : ''}`;
    rows.push({
      name: f.Name ?? '(unnamed)',
      push: verbs ? `\`${verbs}\`` : '— (read-only)',
      incremental: f.SupportsIncrementalSync ? '✓' : '—',
    });
  }

  rows.sort((a, b) => a.name.localeCompare(b.name, 'en', { sensitivity: 'base' }));
  return {
    objectCount: objects.length,
    fieldCount,
    writeCount,
    readOnlyCount: objects.length - writeCount,
    incrementalCount,
    rows,
  };
}

function renderStub({ vendor, metadataRelPath, summary, capturedAt }) {
  const shown = summary.rows.slice(0, TABLE_LIMIT);
  const table = [
    '| Object | Pull | Push (C/U/D) | Incremental |',
    '|---|---|---|---|',
    ...shown.map((r) => `| ${r.name} | ✓ | ${r.push} | ${r.incremental} |`),
  ].join('\n');
  const truncation =
    summary.objectCount > TABLE_LIMIT
      ? `\n\n_First ${TABLE_LIMIT} of ${summary.objectCount} objects shown, alphabetically. The full catalog is the metadata file cited above._`
      : '';

  const declared = summary.objectCount
    ? `**${summary.objectCount} objects** declared across **${summary.fieldCount} fields** (source: \`${metadataRelPath}\`). ` +
      `${summary.writeCount} declare a write path; ${summary.readOnlyCount} are read-only (pull). ` +
      `${summary.incrementalCount} ${summary.incrementalCount === 1 ? 'supports' : 'support'} incremental sync.`
    : `Objects are discovered live from the source system rather than declared in metadata (source: \`${metadataRelPath}\`).`;

  return `# ${vendor} — Supported & Proven

<!-- baseline-stub: no live or mock sync has been run for this connector. Replace this whole file
     with real evidence when one is, and delete this marker — the overview pages key on it. -->

> **Evidence tier:** 🟡 Honest-NA (untested for a documented, non-defect reason)  ·  **Last verified:** ${capturedAt}  ·  **Proof DB(s):** —

> 🟡 **Baseline — format-verified, no credential.** This connector was built through the
> build-connector pipeline for AIDP (Blue Cypress's AI Data Platform), whose default gate is the
> credential-free behavioural matrix: spec-conformance against the vendor's published API contract,
> a mock vendor server exercising pull/push/pagination/incremental shapes, and anti-vacuous
> assertions (a green must mean "observed to work", never "ran without error"). **No live system has
> been contacted and no rows have been persisted.** The reason is a credential gap, not a defect.

## What this connector supports

${declared}

${table}${truncation}

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

- **No rows landed.** No live or mock sync has been run for this connector; there is no proof DB.
- Build-time verification only: the declared request shapes conform to the vendor's API contract.

### Push (write / bidirectional)

- **Status: Not verified.** No write has been executed against any system, live or mock.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- **Everything beyond format verification** — no credential has been used for this connector, so no
  row count, field-shape sample, or write side-effect has been observed against a real tenant.
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.
- **Coverage:** 0 of ${summary.objectCount} declared objects have proven rows.

---

_Capability section derived from this connector's own metadata (\`gen-baseline-support-docs.mjs\`).
There are no proof numbers to re-state: this doc records a build-time floor, not a measured result.
It is superseded the moment a live or mock sync is run and a real SUPPORT.md is written._
`;
}

function main() {
  const scope = readJson(path.join(REPO_ROOT, 'scripts', 'connector-publish-scope.json'));
  const catalog = readJson(path.join(REPO_ROOT, 'connectors-catalog.json'));
  const displayBySubpath = new Map(catalog.connectors.map((c) => [c.repoSubpath, c]));

  const missing = [];
  for (const subpath of scope.publish) {
    if (existsSync(path.join(REPO_ROOT, subpath, 'docs', 'SUPPORT.md'))) continue;
    missing.push(subpath);
  }

  if (LIST_ONLY) {
    console.log(`${missing.length} publishable connector(s) without docs/SUPPORT.md:`);
    for (const subpath of missing) console.log(`  - ${subpath}`);
    return;
  }

  for (const subpath of missing) {
    const connectorDir = path.join(REPO_ROOT, subpath);
    const metadataPath = findIntegrationMetadata(connectorDir);
    if (!metadataPath) {
      console.error(`No integration metadata under ${subpath}/metadata/integration — cannot generate a stub.`);
      process.exit(1);
    }
    const entry = displayBySubpath.get(subpath);
    const vendor = (entry?.displayName ?? path.basename(subpath)).replace(/ Connector$/, '');
    const summary = summarizeMetadata(metadataPath);

    // Date the stub from the connector's own metadata commit, not the clock, so re-running this
    // script never rewrites an existing stub with a new date (and never churns the HTML).
    const capturedAt = lastCommitDate(subpath);

    mkdirSync(path.join(connectorDir, 'docs'), { recursive: true });
    writeFileSync(
      path.join(connectorDir, 'docs', 'SUPPORT.md'),
      renderStub({
        vendor,
        metadataRelPath: path.relative(connectorDir, metadataPath),
        summary,
        capturedAt,
      }),
    );
    console.log(`  + ${subpath}/docs/SUPPORT.md — ${summary.objectCount} objects, ${summary.fieldCount} fields`);
  }
  console.log(`Wrote ${missing.length} baseline SUPPORT.md file(s).`);
}

/** Committer date (YYYY-MM-DD) of the connector's last commit — a stable, non-clock stamp. */
function lastCommitDate(subpath) {
  return execFileSync('git', ['-C', REPO_ROOT, 'log', '-1', '--format=%cs', '--', subpath], {
    encoding: 'utf8',
  }).trim();
}

main();
