#!/usr/bin/env node
/**
 * lint-declared-foreign-keys.mjs — guards declared FK metadata against stranded references,
 * broken/dangling @lookup links, and sync-DAG cycles.
 *
 * THE BUG CLASSES:
 *   1. Stranded declared FKs: a field declares `Configuration.ReferencedType` (or `referencedType` /
 *      `ForeignKeyTarget`) naming an active sibling `IntegrationObject` with a single resolvable
 *      primary key, is scalar and SQL-Server-indexable, is not a Salesforce-style system audit
 *      column (`CreatedById`/`LastModifiedById`), is not explicitly marked soft/demoted
 *      (`softFKReason` / `FKDemotedReason` / `FKForm === 'soft'`), and can be wired without
 *      creating a self-reference or cycle — yet `RelatedIntegrationObjectID` was left NULL.
 *      Without `RelatedIntegrationObjectID`, runtime `SoftFKConfigEmitter` and `IntegrationEngine`
 *      cannot see the relationship.
 *   2. Broken / dangling wired FKs:
 *      - `@lookup:` references missing `&IntegrationID=@parent:IntegrationID` mis-resolve across
 *        connectors sharing generic object names (`Contact`, `User`, `Membership`) on a multi-connector
 *        install (see CONNECTOR_LIFECYCLE_GUIDE.md #3).
 *      - `RelatedIntegrationObjectID` pointing to a nonexistent or `Disabled` object leaves a dead
 *        edge in the catalog. Two pre-existing `CRM/Blackbaud` disabled-target edges are
 *        grandfathered below (shrink-only ratchet).
 *   3. Sync DAG cycles: `IntegrationEngine.buildEntityMapDependencyLayers` topologically sorts
 *      selected objects by the union of field-level `RelatedIntegrationObjectID` edges (both
 *      `@lookup:` and raw UUIDs) and IO-level `Configuration.parentObjectName` /
 *      `parentObjectNames` / `ReferencedType`. Multi-object cycles collapse layering and emit
 *      `DEPENDENCY_LAYERING_DEGRADED` warnings. Three pre-existing connectors are grandfathered
 *      below (shrink-only ratchet); any new cycle on any other connector fails CI.
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
/**
 * System audit lookup columns present on nearly every SObject pointing to `User`.
 * Wiring them creates massive fan-in to `User` and cycles against `User.AccountId`/`User.ContactId`;
 * `SalesforceConnector` applies the same exclusion during live `/describe` introspection.
 */
const AUDIT_FIELDS = new Set(['createdbyid', 'lastmodifiedbyid']);
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const REQUIRED_LOOKUP_QUALIFIER = 'IntegrationID=@parent:IntegrationID';

/**
 * Connectors that already carried multi-object FK cycles prior to this gate.
 * Ratchet only: if one becomes acyclic, this script fails until it is removed from the set.
 */
const GRANDFATHERED_CYCLIC_CONNECTORS = new Set([
  'AMS/iMIS',
  'CRM/DynamicsDataverse',
  'Platform/WordPress',
]);

/**
 * Pre-existing active fields whose `RelatedIntegrationObjectID` targets a `Disabled` object.
 * Ratchet only: once repaired or disabled, remove the entry from this set.
 */
const GRANDFATHERED_DISABLED_TARGET_FKS = new Set([
  'CRM/Blackbaud:constituent_fundraiser_assignment.fundraiser_id',
  'CRM/Blackbaud:fundraising_fundraiser_assignment.fundraiser_id',
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

function addEdge(adj, from, to) {
  if (!adj.has(from)) adj.set(from, new Set());
  adj.get(from).add(to);
}

function cloneAdj(adj) {
  const copy = new Map();
  for (const [k, v] of adj) copy.set(k, new Set(v));
  return copy;
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

function resolveWiredReference(rawLookup, objByName, allObjNames, objById, allObjById) {
  const s = String(rawLookup).trim();
  if (s.startsWith('@lookup:')) {
    const badQualifier = !s.includes(REQUIRED_LOOKUP_QUALIFIER);
    const m = s.match(/Name=([^&]+)/);
    if (!m || !m[1].trim()) {
      return { status: 'unparseable', targetName: null, badQualifier };
    }
    const targetName = m[1].trim();
    if (objByName.has(targetName)) return { status: 'active', targetName, badQualifier };
    if (allObjNames.has(targetName)) return { status: 'disabled', targetName, badQualifier };
    return { status: 'missing', targetName, badQualifier };
  }
  if (UUID_RE.test(s)) {
    const key = s.toUpperCase();
    if (objById.has(key)) return { status: 'active', targetName: objById.get(key).fields.Name, badQualifier: false };
    if (allObjById.has(key)) return { status: 'disabled', targetName: allObjById.get(key).fields.Name, badQualifier: false };
    return { status: 'missing', targetName: s, badQualifier: false };
  }
  return { status: 'unparseable', targetName: s, badQualifier: false };
}

function collectSoftParentsFromIOConfig(obj, objByLowerName) {
  const cfg = parseConfig(obj.fields?.Configuration);
  if (!cfg) return [];
  const rawNames = [cfg.parentObjectName, cfg.ReferencedType];
  if (cfg.parentObjectNames && typeof cfg.parentObjectNames === 'object' && !Array.isArray(cfg.parentObjectNames)) {
    rawNames.push(...Object.values(cfg.parentObjectNames));
  }
  const out = [];
  for (const name of rawNames) {
    if (typeof name !== 'string' || !name.trim()) continue;
    const canon = objByLowerName.get(name.trim().toLowerCase());
    if (canon) out.push(canon);
  }
  return out;
}

function auditConnector({ connector, jsonPath }) {
  const doc = JSON.parse(readFileSync(jsonPath, 'utf8'));
  const roots = Array.isArray(doc) ? doc : [doc];

  const stranded = [];
  const badQualifiers = [];
  const danglingTargets = [];
  const seenGrandfatheredDisabled = new Set();
  const stuckObjects = new Set();
  let wiredCount = 0;

  for (const root of roots) {
    const allObjects = (root?.relatedEntities?.['MJ: Integration Objects'] ?? []).filter((o) => o.fields?.Name);
    const objects = allObjects
      .filter((o) => !isDisabled(o.fields))
      .sort((a, b) => a.fields.Name.localeCompare(b.fields.Name));

    const allObjNames = new Set(allObjects.map((o) => o.fields.Name));
    const allObjById = new Map(
      allObjects.filter((o) => o.primaryKey?.ID).map((o) => [String(o.primaryKey.ID).toUpperCase(), o]),
    );
    const objByName = new Map(objects.map((o) => [o.fields.Name, o]));
    const objByLowerName = new Map(objects.map((o) => [o.fields.Name.toLowerCase(), o.fields.Name]));
    const objById = new Map(
      objects.filter((o) => o.primaryKey?.ID).map((o) => [String(o.primaryKey.ID).toUpperCase(), o]),
    );

    const adj = new Map();

    // Pass 1: Build the active dependency graph matching IntegrationEngine.computeSelectedDependencyGraph
    // (field-level RelatedIntegrationObjectID — both @lookup and raw UUIDs — plus IO-level soft parents).
    for (const obj of objects) {
      const src = obj.fields.Name;
      for (const field of obj.relatedEntities?.['MJ: Integration Object Fields'] ?? []) {
        if (isDisabled(field.fields)) continue;
        const lookup = field.fields?.RelatedIntegrationObjectID;
        if (!lookup) continue;
        wiredCount++;

        const resolved = resolveWiredReference(lookup, objByName, allObjNames, objById, allObjById);
        const fieldRef = `${src}.${field.fields.Name}`;
        if (resolved.badQualifier) {
          badQualifiers.push(`${fieldRef} (${lookup})`);
        }
        if (resolved.status === 'active') {
          if (resolved.targetName !== src) addEdge(adj, src, resolved.targetName);
        } else if (resolved.status === 'disabled') {
          const key = `${connector}:${fieldRef}`;
          if (GRANDFATHERED_DISABLED_TARGET_FKS.has(key)) {
            seenGrandfatheredDisabled.add(key);
          } else {
            danglingTargets.push(`${fieldRef} -> ${resolved.targetName} (target object is Disabled)`);
          }
        } else {
          danglingTargets.push(`${fieldRef} -> ${resolved.targetName ?? lookup} (${resolved.status})`);
        }
      }

      for (const parentName of collectSoftParentsFromIOConfig(obj, objByLowerName)) {
        if (parentName !== src) addEdge(adj, src, parentName);
      }
    }

    const stuck = countCycleStuckObjects([...objByName.keys()], adj);
    for (const name of stuck) stuckObjects.add(name);

    // Pass 2: Audit stranded scalar FKs against a simulated working copy of `adj` so mutual
    // stranded pairs never demand wiring both directions into a cycle.
    const simAdj = cloneAdj(adj);
    for (const obj of objects) {
      const srcName = obj.fields.Name;
      const sortedFields = [...(obj.relatedEntities?.['MJ: Integration Object Fields'] ?? [])].sort((a, b) =>
        String(a.fields?.Name ?? '').localeCompare(String(b.fields?.Name ?? '')),
      );
      for (const field of sortedFields) {
        const fields = field.fields;
        if (!fields || fields.RelatedIntegrationObjectID || isDisabled(fields)) continue;

        const cfg = parseConfig(fields.Configuration);
        const ref = cfg && (cfg.ReferencedType || cfg.referencedType || cfg.ForeignKeyTarget);
        if (typeof ref !== 'string' || !ref.trim()) continue;

        const fieldType = String(fields.Type ?? '').toLowerCase().trim();
        if (NON_SCALAR_TYPES.has(fieldType) || fields.Length === -1) continue;
        if (cfg.softFKReason || cfg.FKDemotedReason || cfg.FKForm === 'soft') continue;
        if (AUDIT_FIELDS.has(String(fields.Name ?? '').toLowerCase())) continue;

        const targetObj = objByName.get(ref);
        if (!targetObj) continue;
        const targetFieldName = resolveTargetFieldName(field, targetObj);
        if (!targetFieldName) continue;
        if (srcName === ref) continue;
        if (canReach(simAdj, ref, srcName)) continue;

        addEdge(simAdj, srcName, ref);
        stranded.push(`${srcName}.${fields.Name} -> ${ref}.${targetFieldName}`);
      }
    }
  }

  return { connector, wiredCount, stranded, badQualifiers, danglingTargets, seenGrandfatheredDisabled, stuckObjects };
}

const files = findIntegrationJsonFiles(ROOT);
let errors = 0;
let totalWired = 0;
const allSeenGrandfatheredDisabled = new Set();

for (const entry of files) {
  const {
    connector,
    wiredCount,
    stranded,
    badQualifiers,
    danglingTargets,
    seenGrandfatheredDisabled,
    stuckObjects,
  } = auditConnector(entry);
  totalWired += wiredCount;
  for (const k of seenGrandfatheredDisabled) allSeenGrandfatheredDisabled.add(k);
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

  if (badQualifiers.length > 0) {
    errors += badQualifiers.length;
    console.error(
      `✗ ${connector} — ${badQualifiers.length} @lookup RelatedIntegrationObjectID reference(s) missing ` +
        `${REQUIRED_LOOKUP_QUALIFIER} (first 5: ${badQualifiers.slice(0, 5).join(', ')})`,
    );
  }

  if (danglingTargets.length > 0) {
    errors += danglingTargets.length;
    console.error(
      `✗ ${connector} — ${danglingTargets.length} dangling/disabled RelatedIntegrationObjectID target(s) ` +
        `(first 5: ${danglingTargets.slice(0, 5).join(', ')})`,
    );
  }

  if (stuckObjects.size > 0 && !isGrandfathered) {
    errors++;
    console.error(
      `✗ ${connector} — dependency graph contains cycle(s) stranding ${stuckObjects.size} object(s) ` +
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

for (const key of GRANDFATHERED_DISABLED_TARGET_FKS) {
  if (!allSeenGrandfatheredDisabled.has(key)) {
    errors++;
    console.error(
      `✗ ${key} — no longer targets a disabled object! Remove it from GRANDFATHERED_DISABLED_TARGET_FKS in scripts/lint-declared-foreign-keys.mjs.`,
    );
  }
}

if (errors > 0) {
  console.error(`\n${errors} declared-FK issue(s) found. Failing build.`);
  process.exit(1);
}
console.log(
  `✓ declared foreign keys: ${totalWired} wired FK(s) across ${files.length} connectors, 0 stranded DAG-safe scalar FKs, 0 broken/dangling refs, 0 new DAG cycles.`,
);
