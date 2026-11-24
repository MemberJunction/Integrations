#!/usr/bin/env node
/**
 * lint-declared-foreign-keys.mjs — guards declared FK metadata against stranded references and DAG cycles.
 *
 * THE BUG CLASSES:
 *   1. Stranded declared FKs: a field declares `Configuration.ReferencedType` (or `referencedType` /
 *      `ForeignKeyTarget`) naming a sibling `IntegrationObject` with a single resolvable primary key,
 *      is scalar and SQL-Server-indexable, is not a system audit column (`CreatedById`/`LastModifiedById`),
 *      is not explicitly marked soft/demoted, and can be wired without creating a self-reference or cycle —
 *      yet `RelatedIntegrationObjectID` was left NULL. Without `RelatedIntegrationObjectID`, runtime
 *      `SoftFKConfigEmitter` and `IntegrationEngine` cannot see the relationship.
 *   2. Sync DAG cycles: `IntegrationEngine.buildEntityMapDependencyLayers` topologically sorts selected
 *      objects by `RelatedIntegrationObjectID`. Multi-object cycles collapse layering and emit
 *      `DEPENDENCY_LAYERING_DEGRADED` warnings. Three pre-existing connectors are grandfathered below
 *      (ratchet: the list may only shrink); any new cycle on any other connector fails CI.
 *
 * Usage:
 *   node scripts/lint-declared-foreign-keys.mjs           # CI audit (exit 1 on violations)
 *   node scripts/lint-declared-foreign-keys.mjs --list    # verbose per-connector summary
 */
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const VERBOSE = process.argv.includes('--list');

const SKIP_DIRS = new Set([
  'node_modules', 'dist', '.git', '.github', '.changeset', '.turbo', 'scripts', 'docs', 'patches', 'packages',
]);
const NON_SCALAR_TYPES = new Set([
  'json', 'object', 'array', 'text', 'nvarchar(max)', 'varchar(max)', 'ntext', 'richtext',
]);
const AUDIT_FIELDS = new Set(['createdbyid', 'lastmodifiedbyid']);

/**
 * Connectors that already carried multi-object FK cycles prior to this gate.
 * Ratchet only: if one becomes acyclic, this script fails until it is removed from the set.
 */
const GRANDFATHERED_CYCLIC_CONNECTORS = new Set([
  'AMS/iMIS',
  'CRM/DynamicsDataverse',
  'Platform/WordPress',
]);

function parseConfig(raw) {
  if (raw == null) return null;
  if (typeof raw === 'string') {
    try {
      return JSON.parse(raw);
    } catch {
      return null;
    }
  }
  return typeof raw === 'object' ? raw : null;
}

function findIntegrationJsonFiles(dir, out = []) {
  for (const entry of readdirSync(dir).sort()) {
    if (entry.startsWith('.') || SKIP_DIRS.has(entry)) continue;
    const catPath = join(dir, entry);
    if (!statSync(catPath).isDirectory()) continue;
    for (const conn of readdirSync(catPath).sort()) {
      const connDir = join(catPath, conn);
      if (!statSync(connDir).isDirectory()) continue;
      const metaDir = join(connDir, 'metadata', 'integration');
      if (!existsSync(metaDir)) continue;
      for (const file of readdirSync(metaDir).sort()) {
        if (file.endsWith('.json') && !file.startsWith('.mj-sync')) {
          out.push({ connector: `${entry}/${conn}`, jsonPath: join(metaDir, file) });
        }
      }
    }
  }
  return out;
}

function isDisabled(fields) {
  return String(fields?.Status ?? '').trim().toLowerCase() === 'disabled';
}

function resolveTargetFieldName(fieldObj, targetObj) {
  const targetFields = (targetObj.relatedEntities?.['MJ: Integration Object Fields'] ?? []).filter(
    (tf) => !isDisabled(tf.fields),
  );
  const explicit = fieldObj.fields?.RelatedIntegrationObjectFieldName;
  if (explicit) {
    return targetFields.some((tf) => tf.fields?.Name === explicit) ? explicit : null;
  }
  const pks = targetFields.filter((tf) => tf.fields?.IsPrimaryKey).map((tf) => tf.fields?.Name).filter(Boolean);
  return pks.length === 1 ? pks[0] : null;
}

function canReach(adj, start, goal) {
  const visited = new Set([start]);
  const stack = [start];
  while (stack.length > 0) {
    const cur = stack.pop();
    if (cur === goal) return true;
    const neighbors = adj.get(cur);
    if (!neighbors) continue;
    for (const nxt of neighbors) {
      if (!visited.has(nxt)) {
        visited.add(nxt);
        stack.push(nxt);
      }
    }
  }
  return false;
}

function countCycleStuckObjects(objectNames, adj) {
  const remaining = new Set(objectNames);
  while (remaining.size > 0) {
    const ready = [...remaining].filter(
      (u) => !adj.has(u) || [...adj.get(u)].every((v) => !remaining.has(v)),
    );
    if (ready.length === 0) break;
    for (const u of ready) remaining.delete(u);
  }
  return remaining;
}

function auditConnector({ connector, jsonPath }) {
  const doc = JSON.parse(readFileSync(jsonPath, 'utf8'));
  const roots = Array.isArray(doc) ? doc : [doc];

  const stranded = [];
  let stuckObjects = new Set();
  let wiredCount = 0;

  for (const root of roots) {
    const objects = (root?.relatedEntities?.['MJ: Integration Objects'] ?? []).filter(
      (o) => o.fields?.Name && !isDisabled(o.fields),
    );
    const objByName = new Map(objects.map((o) => [o.fields.Name, o]));
    const adj = new Map();

    for (const obj of objects) {
      const src = obj.fields.Name;
      for (const field of obj.relatedEntities?.['MJ: Integration Object Fields'] ?? []) {
        if (isDisabled(field.fields)) continue;
        const lookup = field.fields?.RelatedIntegrationObjectID;
        if (!lookup) continue;
        wiredCount++;
        const m = String(lookup).match(/Name=([^&]+)/);
        if (m && m[1] !== src && objByName.has(m[1])) {
          if (!adj.has(src)) adj.set(src, new Set());
          adj.get(src).add(m[1]);
        }
      }
    }

    const stuck = countCycleStuckObjects([...objByName.keys()], adj);
    for (const name of stuck) stuckObjects.add(name);

    for (const obj of objects) {
      const srcName = obj.fields.Name;
      for (const field of obj.relatedEntities?.['MJ: Integration Object Fields'] ?? []) {
        const fields = field.fields;
        if (!fields || fields.RelatedIntegrationObjectID || isDisabled(fields)) continue;

        const cfg = parseConfig(fields.Configuration);
        const ref = cfg && (cfg.ReferencedType || cfg.referencedType || cfg.ForeignKeyTarget);
        if (typeof ref !== 'string' || !ref.trim()) continue;

        const fieldType = String(fields.Type ?? '').toLowerCase().trim();
        if (NON_SCALAR_TYPES.has(fieldType) || fields.Length === -1) continue;
        if (cfg.softFKReason || cfg.FKDemotedReason || cfg.FKForm === 'soft' || cfg.evidence === 'wsdl+docs') continue;
        if (AUDIT_FIELDS.has(String(fields.Name ?? '').toLowerCase())) continue;

        const targetObj = objByName.get(ref);
        if (!targetObj || !targetObj.primaryKey?.ID || !field.primaryKey?.ID) continue;
        const targetFieldName = resolveTargetFieldName(field, targetObj);
        if (!targetFieldName) continue;
        if (srcName === ref) continue;
        if (canReach(adj, ref, srcName)) continue;

        stranded.push(`${srcName}.${fields.Name} -> ${ref}.${targetFieldName}`);
      }
    }
  }

  return { connector, wiredCount, stranded, stuckObjects };
}

const files = findIntegrationJsonFiles(ROOT);
let errors = 0;
let totalWired = 0;

for (const entry of files) {
  const { connector, wiredCount, stranded, stuckObjects } = auditConnector(entry);
  totalWired += wiredCount;
  const isGrandfathered = GRANDFATHERED_CYCLIC_CONNECTORS.has(connector);

  if (VERBOSE && (wiredCount > 0 || stranded.length > 0 || stuckObjects.size > 0)) {
    console.log(
      `${connector}: ${wiredCount} wired FK(s), ${stranded.length} stranded, ${stuckObjects.size} cycle-stuck${isGrandfathered ? ' (grandfathered)' : ''}`,
    );
  }

  if (stranded.length > 0) {
    errors += stranded.length;
    console.error(
      `✗ ${connector} — ${stranded.length} eligible DAG-safe scalar FK(s) declared in Configuration.ReferencedType ` +
        `without RelatedIntegrationObjectID (first 5: ${stranded.slice(0, 5).join(', ')})`,
    );
  }

  if (stuckObjects.size > 0 && !isGrandfathered) {
    errors++;
    console.error(
      `✗ ${connector} — RelatedIntegrationObjectID graph contains cycle(s) stranding ${stuckObjects.size} object(s) ` +
        `(first 5: ${[...stuckObjects].slice(0, 5).join(', ')}). Break back-edges so sync DAG layering stays acyclic.`,
    );
  }

  if (stuckObjects.size === 0 && isGrandfathered) {
    errors++;
    console.error(
      `✗ ${connector} — now acyclic! Remove it from GRANDFATHERED_CYCLIC_CONNECTORS in scripts/lint-declared-foreign-keys.mjs.`,
    );
  }
}

if (errors > 0) {
  console.error(`\n${errors} declared-FK issue(s) found. Failing build.`);
  process.exit(1);
}
console.log(
  `✓ declared foreign keys: ${totalWired} wired FK(s) across ${files.length} connectors, 0 stranded DAG-safe scalar FKs, 0 new DAG cycles.`,
);
