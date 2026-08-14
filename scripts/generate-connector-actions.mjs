#!/usr/bin/env node
/**
 * generate-connector-actions.mjs — emit a connector's MJ Action metadata.
 *
 * Actions are GENERATED from the connector's own object model, never hand-authored: the connector
 * declares `GetActionGeneratorConfig()`, ActionMetadataGenerator emits one Action per applicable
 * object/verb, and every Action carries `DriverClass='IntegrationActionExecutor'` with a
 * {IntegrationName, ObjectName, Verb} Config triple. That triple IS the implementation — there is no
 * per-action code. Generating rather than writing them by hand is what stops the Action surface
 * drifting from the sync catalog.
 *
 * Output: <Category>/<Connector>/metadata/actions/.<integration>-actions.json, ready for `mj sync push`.
 *
 * LIMITATION, and it decides which connectors this works for: a connector whose
 * `GetIntegrationObjects()` reads the runtime IntegrationEngineBase cache (Stripe, Salesforce) needs
 * a seeded database, so it cannot be generated offline and this script will report an empty catalog
 * rather than silently emitting nothing. Connectors returning a static object model (Bill.com, whose
 * catalog is extracted from the vendor's OpenAPI at build time) generate anywhere.
 *
 *   node scripts/generate-connector-actions.mjs Finance/BillCom
 */
import { writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const target = process.argv[2];
if (!target) {
    console.error('usage: node scripts/generate-connector-actions.mjs <Category>/<Connector>');
    process.exit(1);
}

const root = resolve(import.meta.dirname, '..');
const dir = join(root, target);
if (!existsSync(dir)) {
    console.error(`no such connector directory: ${target}`);
    process.exit(1);
}

const { ActionMetadataGenerator } = await import('@memberjunction/integration-engine');

// The connector registers itself on import; instantiate via its exported class.
const entry = pathToFileURL(join(dir, 'dist', 'index.js')).href;
const mod = await import(entry);
const ConnectorClass = Object.values(mod).find(
    (v) => typeof v === 'function' && /Connector$/.test(v.name)
);
if (!ConnectorClass) {
    console.error(`no *Connector class exported from ${target}/dist/index.js — is it built?`);
    process.exit(1);
}

const connector = new ConnectorClass();
const config = connector.GetActionGeneratorConfig();
if (!config) {
    console.error(
        `${target}: GetActionGeneratorConfig() returned null.\n` +
        `  Either the connector declares no objects, or its object model comes from the runtime\n` +
        `  metadata cache and needs a seeded database. Nothing written.`
    );
    process.exit(2);
}

const generated = new ActionMetadataGenerator().Generate(config);
const outDir = join(dir, 'metadata', 'actions');
mkdirSync(outDir, { recursive: true });

const slug = config.IntegrationName.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
const outFile = join(outDir, `.${slug}-actions.json`);
writeFileSync(outFile, `${JSON.stringify(generated.ActionRecords, null, 2)}\n`);

const verbs = new Set(generated.ActionRecords.map((a) => a.fields.Config?.Verb ?? a.fields.Config_?.Verb));
console.log(`${target}: ${generated.ActionRecords.length} actions across ${config.Objects.length} objects`);
console.log(`  verbs: ${[...verbs].filter(Boolean).sort().join(', ')}`);
console.log(`  wrote ${outFile.replace(root + '/', '')}`);
if (generated.CategoryRecords.length) {
    console.log(`  (+${generated.CategoryRecords.length} category record(s) — CreateCategory is on)`);
}
