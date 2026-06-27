#!/usr/bin/env node
/**
 * Completes each connector's metadata IN THIS REPO (surgical, additive — does NOT re-scaffold, so the
 * full-Open-App + one-package-per-connector transforms already applied are preserved). Adds the two
 * integration-specific metadata categories the original scaffold did not copy:
 *
 *   1. metadata/credential-type/  — the connector's VENDOR-SPECIFIC credential type (the one its
 *      Integration.CredentialTypeID references), + its @file JSON schema. Generic primitives
 *      (API Key, OAuth2 *, Basic Auth, AWS IAM, Azure Service Principal, Database Connection,
 *      MCP OAuth Token, API Key with Endpoint) STAY in core and are NOT copied — the connector
 *      @lookups them. directoryOrder is set so credential-type pushes BEFORE integration
 *      (Integration.CredentialTypeID @lookup must resolve).
 *   2. metadata/additionalSchemaInfo.json — the vendor's slice of core's additionalSchemaInfo
 *      (schema hints used when the connector's synced objects materialize as tables). Only the
 *      keys for THIS connector are kept. (Not an mj-sync record — a config file consumed by the
 *      build/runtime.)
 *
 *   CORE_META=/clean/next/metadata node scripts/add-connector-metadata.mjs
 */
import { readFileSync, writeFileSync, readdirSync, statSync, existsSync, mkdirSync, copyFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const REPO_ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const CORE_META = process.env.CORE_META;
if (!CORE_META) { console.error('Set CORE_META to a clean next metadata dir.'); process.exit(1); }

const GENERIC_CREDENTIAL_TYPES = new Set([
  'API Key', 'API Key with Endpoint', 'OAuth2 Client Credentials', 'OAuth2 Password Grant',
  'Basic Auth', 'AWS IAM', 'Azure Service Principal', 'Database Connection', 'MCP OAuth Token',
]);

const writeJson = (p, obj) => { mkdirSync(dirname(p), { recursive: true }); writeFileSync(p, JSON.stringify(obj, null, 2) + '\n', 'utf-8'); };
const slugify = (name) => String(name).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
/** Core's additionalSchemaInfo vendor-key normalization (per-char non-alnum → underscore). */
const asiKey = (name) => String(name).toLowerCase().replace(/[^a-z0-9]/g, '_');
const credLookupRe = /Credential Types\.Name=([^"&]+)/;

// ── Load core sources ─────────────────────────────────────────────────────
const credRows = (() => {
  const p = join(CORE_META, 'credential-types', '.credential-types.json');
  const raw = JSON.parse(readFileSync(p, 'utf-8'));
  const m = new Map();
  for (const r of (Array.isArray(raw) ? raw : [raw])) if (r?.fields?.Name) m.set(r.fields.Name, r);
  return m;
})();
const additionalSchemaInfo = (() => {
  const p = join(CORE_META, 'integrations', 'additionalSchemaInfo.json');
  if (!existsSync(p)) return {};
  const raw = JSON.parse(readFileSync(p, 'utf-8'));
  return Array.isArray(raw) ? (raw[0] ?? {}) : raw;
})();

// ── Find connector app dirs (have an mj-app.json) ─────────────────────────
function connectorDirs(dir, out = []) {
  for (const e of readdirSync(dir)) {
    if (['node_modules', 'dist', '.git', '.github', '.changeset', 'scripts', 'packages'].includes(e)) continue;
    const p = join(dir, e);
    if (!statSync(p).isDirectory()) continue;
    if (existsSync(join(p, 'mj-app.json'))) out.push(p);
    else connectorDirs(p, out);
  }
  return out;
}

/** Read a connector's Integration record (Name + CredentialTypeID lookup name). */
function readConnectorIntegration(appDir) {
  const intDir = join(appDir, 'metadata', 'integration');
  if (!existsSync(intDir)) return null;
  const f = readdirSync(intDir).find((x) => x.endsWith('.integration.json'));
  if (!f) return null;
  const raw = JSON.parse(readFileSync(join(intDir, f), 'utf-8'));
  const rec = (Array.isArray(raw) ? raw : [raw]).find((r) => r?.fields?.ClassName);
  if (!rec) return null;
  const cid = rec.fields.CredentialTypeID;
  const m = typeof cid === 'string' && cid.match(credLookupRe);
  return { name: rec.fields.Name, credTypeName: m ? m[1].trim() : null };
}

let credAdded = 0, asiAdded = 0, ordersFixed = 0;
for (const appDir of connectorDirs(REPO_ROOT)) {
  const rel = appDir.slice(REPO_ROOT.length + 1);
  const integ = readConnectorIntegration(appDir);
  if (!integ) { console.warn(`skip (no integration metadata): ${rel}`); continue; }
  const slug = slugify(integ.name);
  const metaRoot = join(appDir, 'metadata');

  // 1. Vendor credential type (skip generics — they stay in core and are @lookup'd)
  if (integ.credTypeName && !GENERIC_CREDENTIAL_TYPES.has(integ.credTypeName)) {
    const row = credRows.get(integ.credTypeName);
    if (!row) {
      console.warn(`  ${rel}: credential type "${integ.credTypeName}" not found in core — skipped`);
    } else {
      const ctDir = join(metaRoot, 'credential-type');
      writeJson(join(ctDir, '.mj-sync.json'), { entity: 'MJ: Credential Types', filePattern: '**/.*.json', defaults: {} });
      writeJson(join(ctDir, `.${slug}-credential-type.json`), row);
      // copy the @file schema referenced by FieldSchema, if any
      const sm = String(row.fields?.FieldSchema ?? '').match(/^@file:(.+)$/);
      if (sm) {
        const src = join(CORE_META, 'credential-types', sm[1].trim());
        const dst = join(ctDir, sm[1].trim());
        if (existsSync(src)) { mkdirSync(dirname(dst), { recursive: true }); copyFileSync(src, dst); }
        else console.warn(`  ${rel}: schema file ${sm[1]} missing in core`);
      }
      credAdded++;
    }
  }

  // 2. additionalSchemaInfo slice (vendor key match)
  const key = asiKey(integ.name);
  if (Object.prototype.hasOwnProperty.call(additionalSchemaInfo, key)) {
    writeJson(join(metaRoot, 'additionalSchemaInfo.json'), { [key]: additionalSchemaInfo[key] });
    asiAdded++;
  }

  // 3. directoryOrder: credential-type must push before integration; keep actions last.
  const syncPath = join(metaRoot, '.mj-sync.json');
  if (existsSync(syncPath)) {
    const sync = JSON.parse(readFileSync(syncPath, 'utf-8'));
    const have = new Set([
      existsSync(join(metaRoot, 'credential-type')) ? 'credential-type' : null,
      existsSync(join(metaRoot, 'integration')) ? 'integration' : null,
      existsSync(join(metaRoot, 'actions')) ? 'actions' : null,
    ].filter(Boolean));
    const desired = ['credential-type', 'integration', 'actions'].filter((d) => have.has(d));
    if (JSON.stringify(sync.directoryOrder) !== JSON.stringify(desired)) {
      sync.directoryOrder = desired;
      writeJson(syncPath, sync);
      ordersFixed++;
    }
  }
  console.log(`✓ ${rel}  (${integ.name})`);
}
console.log(`\nDone — credential types added: ${credAdded}, additionalSchemaInfo slices added: ${asiAdded}, directoryOrder fixed: ${ordersFixed}.`);
