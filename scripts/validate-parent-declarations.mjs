#!/usr/bin/env node
/**
 * validate-parent-declarations.mjs — the guardrail for the "silent second layer" class.
 *
 * THE BUG CLASS: an IntegrationObject whose LIST door (AccessPath.door / apiPath)
 * contains a template var (e.g. /events/{eventCode}/sessions/) can only fetch if the
 * engine can resolve that var to a parent object. Resolution is BY AUTHORED METADATA
 * ONLY (BaseRESTIntegrationConnector §19 — the old name-guess heuristic was removed
 * because a wrong guess silently corrupted cross-owner data):
 *   - Configuration.parentObjectName  (single var), or
 *   - Configuration.parentObjectNames { "<var>": "<SiblingName>" } (multi var), or
 *   - an EXPLICIT FK field whose Name EXACTLY equals the var (RelatedIntegrationObjectID).
 * An undeclared var = the object fetches NOTHING, warns PARENT_UNRESOLVED, and the run
 * still reports success — invisible in every review, test, and build. PheedLoop shipped
 * 21 such objects (0 rows each) while its siblings (GrowthZone, Eventbrite) declared
 * parents correctly. This validator makes that class of miss a BUILD FAILURE.
 *
 * Modes:
 *   node scripts/validate-parent-declarations.mjs           # audit (CI): exit 1 on violations
 *   node scripts/validate-parent-declarations.mjs --list    # audit, verbose per-object
 *
 * Vars that are RECORD-detail placeholders, not parent scopes, are exempt: {ExternalID}.
 * Vars supplied by the CONNECTION configuration (tenant identifiers), not a parent
 * object, are exempt via CONNECTION_VARS below.
 */
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, basename } from 'node:path';

const ROOT = new URL('..', import.meta.url).pathname;
const EXEMPT_VARS = new Set(['externalid']);
/** Tenant-level vars filled from CompanyIntegration/credential config, not a parent object. */
const CONNECTION_VARS = new Set([
  'organization-code', 'organizationcode', 'org-code', 'orgcode',
  'tenantid', 'accountid', 'clientid', 'realmid', 'apiversion', 'siteid'
]);

function* integrationJsons(root) {
  for (const cat of readdirSync(root)) {
    const catPath = join(root, cat);
    if (!statSync(catPath).isDirectory() || cat.startsWith('.') || cat === 'scripts' || cat === 'node_modules') continue;
    for (const conn of readdirSync(catPath)) {
      const metaDir = join(catPath, conn, 'metadata', 'integration');
      let entries = [];
      try { entries = readdirSync(metaDir); } catch { continue; }
      for (const f of entries) {
        if (f.endsWith('.json') && f.includes('integration')) {
          yield { connector: `${cat}/${conn}`, file: join(metaDir, f) };
        }
      }
    }
  }
}

const parseConfig = raw =>
  raw == null ? {} : typeof raw === 'string' ? (() => { try { return JSON.parse(raw); } catch { return {}; } })() : raw;

const doorOf = cfg => cfg?.AccessPath?.door ?? cfg?.apiPath ?? '';

function varsOf(door) {
  return [...String(door).matchAll(/\{([a-zA-Z_][a-zA-Z0-9_-]*)\}/g)]
    .map(m => m[1])
    .filter(v => !EXEMPT_VARS.has(v.toLowerCase()) && !CONNECTION_VARS.has(v.toLowerCase()));
}

function auditConnector({ connector, file }) {
  const doc = JSON.parse(readFileSync(file, 'utf8'));
  const roots = Array.isArray(doc) ? doc : [doc];
  const violations = [];
  let templatedObjects = 0;
  for (const root of roots) {
    const objs = root?.relatedEntities?.['MJ: Integration Objects'] ?? [];
    for (const o of objs) {
      const f = o.fields ?? {};
      if ((f.Status ?? 'Active') !== 'Active') continue; // inactive objects don't fetch
      // Detail-only objects (listSupported:false) are fetched per-record, not by list door.
      const cfg = parseConfig(f.Configuration);
      if (cfg.listSupported === false) continue; // detail-only: no list fetch, no parent iteration
      const vars = varsOf(doorOf(cfg));
      if (vars.length === 0) continue;
      templatedObjects++;
      const single = typeof cfg.parentObjectName === 'string' && cfg.parentObjectName.trim();
      const map = cfg.parentObjectNames && typeof cfg.parentObjectNames === 'object' ? cfg.parentObjectNames : null;
      const fieldEntries = o.relatedEntities?.['MJ: Integration Object Fields'] ?? [];
      const fkByName = new Set(
        fieldEntries
          .filter(fe => fe.fields?.RelatedIntegrationObjectID)
          .map(fe => String(fe.fields.Name).toLowerCase())
      );
      const unresolved = vars.filter(v => {
        if (map && typeof map[v] === 'string' && map[v].trim()) return false;
        if (!map && single && vars.length === 1) return false;
        if (fkByName.has(v.toLowerCase())) return false;
        return true;
      });
      if (unresolved.length > 0) {
        violations.push({ object: f.Name, door: doorOf(cfg), unresolved });
      }
    }
  }
  return { connector, templatedObjects, violations };
}

const verbose = process.argv.includes('--list');
let bad = 0, totalTemplated = 0;
for (const target of integrationJsons(ROOT)) {
  const { connector, templatedObjects, violations } = auditConnector(target);
  totalTemplated += templatedObjects;
  if (verbose && templatedObjects > 0) {
    console.log(`${connector}: ${templatedObjects} templated-door object(s), ${violations.length} unresolved`);
  }
  for (const v of violations) {
    bad++;
    console.error(
      `✗ ${connector} :: ${v.object} — door "${v.door}" has unresolved template var(s) ` +
        `{${v.unresolved.join('}, {')}} — declare Configuration.parentObjectName / parentObjectNames ` +
        `or an exact-name FK field. Undeclared = the object silently fetches ZERO records.`
    );
  }
}
if (bad > 0) {
  console.error(`\n${bad} unresolved templated-door object(s). Failing build.`);
  process.exit(1);
}
console.log(`✓ parent declarations: ${totalTemplated} templated-door object(s) across the fleet, all resolvable.`);
