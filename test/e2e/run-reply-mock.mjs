/**
 * Reply.io credential-free hybrid-e2e runner — reproduces the 22-cell matrix cited in the
 * Reply connector's PR. No vendor credential is involved: the connector is driven against a
 * mock vendor replaying `fixtures/reply.fixtures.json`, which is built from Reply's published
 * OpenAPI v3 examples.
 *
 * Nothing is hardcoded that a reviewer would have to edit. Every environment-specific value —
 * DB host/port/name, the MJAPI URL, the CompanyIntegration ID, and BOTH secrets (the SQL
 * password and the MJ system key) — comes from the environment. There are no credentials in
 * this file, and there must never be.
 *
 * Usage:
 *   E2E_DB_PASSWORD=... MJ_API_KEY=... \
 *   E2E_DB_PORT=1505 E2E_DB_NAME=MJ_REPLY_E2E E2E_GRAPHQL_URL=http://localhost:4017/ \
 *   E2E_COMPANY_ID=<CompanyIntegration ID> \
 *   node test/e2e/run-reply-mock.mjs
 *
 * Full environment bring-up (SQL container, MJAPI, seeding the catalog) is described in README.md
 * beside this file. Expected result: `topOk: true`, 22/22 cells, and — the assertion that matters —
 * `coverage.all-objects` reporting every syncable object with rows and ZERO legit-empty exemptions.
 */
import { writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { connectorE2EMock } from './plans.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));

const CONNECTOR = 'reply';
const INTEGRATION = 'Reply';

// ── Required from the environment. Fail loudly and specifically rather than silently
//    falling back to a default that would make a red run look like an environment problem.
const REQUIRED = ['E2E_DB_PASSWORD', 'MJ_API_KEY', 'E2E_COMPANY_ID'];
const missing = REQUIRED.filter((k) => !process.env[k]);
if (missing.length > 0) {
    console.error(`[run-reply-mock] missing required env var(s): ${missing.join(', ')}\n` +
        `  E2E_DB_PASSWORD  password for the SQL Server holding the e2e database\n` +
        `  MJ_API_KEY       MJ system key the harness uses to call MJAPI over GraphQL\n` +
        `  E2E_COMPANY_ID   the CompanyIntegration ID for Reply in that database\n` +
        `See README.md beside this file for the full bring-up.`);
    process.exit(2);
}

const OUT = process.env.E2E_RESULT_PATH || join(HERE, 'reply-mock-result.json');

Object.assign(process.env, {
    E2E_CONNECTOR: CONNECTOR,
    E2E_INTEGRATION: INTEGRATION,
    E2E_MODE: 'mock',
    E2E_REGEN_FIXTURES: 'false',
    E2E_PLATFORM: process.env.E2E_PLATFORM || 'sqlserver',
    // The harness resolves fixtures as <plans.mjs dir>/fixtures/<connector>/fixtures/fixtures.json,
    // which is exactly where this bundle keeps them, so this is the default and not an override.
    E2E_FIXTURES_DIR: process.env.E2E_FIXTURES_DIR || join(HERE, 'fixtures', CONNECTOR, 'fixtures'),
    HS_LIVE_GRAPHQL_URL: process.env.E2E_GRAPHQL_URL || 'http://localhost:4017/',
    HS_LIVE_PLATFORM: process.env.E2E_PLATFORM || 'sqlserver',
    HS_LIVE_COMPANY_ID: process.env.E2E_COMPANY_ID,
    HS_LIVE_DB_HOST: process.env.E2E_DB_HOST || 'localhost',
    HS_LIVE_DB_PORT: process.env.E2E_DB_PORT || '1505',
    HS_LIVE_DB_NAME: process.env.E2E_DB_NAME || 'MJ_REPLY_E2E',
    HS_LIVE_DB_USER: process.env.E2E_DB_USER || 'sa',
    HS_LIVE_MJ_SCHEMA: process.env.E2E_MJ_SCHEMA || '__mj',
    // The full declared catalog — never a subset. A narrowed object list cannot support an
    // all-objects coverage claim, so the sentinel is the only supported value here.
    HS_LIVE_OBJECTS: '__ALL__',
    E2E_DB_REQUEST_TIMEOUT_MS: process.env.E2E_DB_REQUEST_TIMEOUT_MS || '600000',
});

const t0 = Date.now();
const res = await connectorE2EMock(
    { dbPassword: process.env.E2E_DB_PASSWORD, mjSystemKey: process.env.MJ_API_KEY },
    (x) => x,
);
const ms = Date.now() - t0;

const steps = res.steps || {};
const cells = {};
for (const [name, val] of Object.entries(steps)) {
    const arr = Array.isArray(val) ? val : [val];
    const real = arr.filter((s) => s && typeof s === 'object');
    const passed = real.filter((s) => s.ok === true).length;
    const skipped = real.filter((s) => s.skipped || s.skipReason).length;
    cells[name] = `${passed}/${real.length}${skipped ? `(${skipped}skip)` : ''}`;
}

const fwd = (steps.forward || []).filter((s) => s && s.name === 'forward.completeness');
const zero = fwd.filter((s) => (s.destRows || 0) === 0);
const coverage = (steps.coverage || []).find((s) => s && s.name === 'coverage.all-objects');

console.log('=== Reply MOCK MATRIX ===');
console.log('topOk:', res.ok, ' ms:', ms);
console.log(`forward: objects>0 rows: ${fwd.length - zero.length} / ${fwd.length} | zero-row: ${zero.length}`);
if (coverage) console.log('coverage.all-objects ok:', coverage.ok, JSON.stringify(coverage));
console.log('cells:', JSON.stringify(cells, null, 2));

writeFileSync(OUT, JSON.stringify(res, null, 2));
console.log('full result ->', OUT);
process.exit(res.ok ? 0 : 1);
