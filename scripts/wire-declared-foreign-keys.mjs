#!/usr/bin/env node
/**
 * wire-declared-foreign-keys.mjs — repairs stranded declared foreign-key metadata across connectors.
 *
 * Several connectors authored foreign-key targets inside `Configuration.ReferencedType` (and often
 * `IsForeignKey: true`), but never populated `RelatedIntegrationObjectID` (with `@lookup:...`) or
 * `RelatedIntegrationObjectFieldName` — and their shipped seed migrations therefore seeded NULLs.
 *
 * Structural eligibility rules (derived from @memberjunction/integration-schema-builder + connector
 * DAG constraints, never hardcoded connector names):
 *   1. Field has no `RelatedIntegrationObjectID`, carries a seeded `primaryKey.ID`, and resolves a
 *      single non-empty string target (`ReferencedType` / `referencedType` / `ForeignKeyTarget`) to
 *      a sibling `IntegrationObject` in the same connector with a seeded `primaryKey.ID`.
 *   2. Field type is scalar and indexable — excludes non-scalar/unbounded types (`json`, `object`,
 *      `array`, `text`, `nvarchar(max)`, `varchar(max)`, `ntext`, `richtext`) and `Length === -1`
 *      so CodeGen's `IDX_AUTO_MJ_FKEY` index creation never attempts to index an unbounded column.
 *   3. Excludes explicit soft-FK / cycle-breaker declarations (`softFKReason`, `FKDemotedReason`,
 *      `FKForm === 'soft'`) and noisy `wsdl+docs` scraper rows (`evidence === 'wsdl+docs'`).
 *   4. Requires an unambiguous target field: either `RelatedIntegrationObjectFieldName` matches a
 *      field on the target object, or the target object has a single `IsPrimaryKey: true` field.
 *   5. On connectors that already have `RelatedIntegrationObjectID` links (`alreadyWired > 0`), skips
 *      self-references and 2-cycle back-edges where the target already points back to the source.
 *
 * Usage:
 *   node scripts/wire-declared-foreign-keys.mjs             # --dry-run (audit only)
 *   node scripts/wire-declared-foreign-keys.mjs --dry-run   # --dry-run (explicit)
 *   node scripts/wire-declared-foreign-keys.mjs --apply     # updates JSON + emits SQL/PG deltas
 */
import { existsSync, mkdirSync, readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const APPLY = process.argv.includes('--apply');
const MIGRATION_TIMESTAMP = '202611161330';
const SQL_BATCH_SIZE = 500;
const SKIP_DIRS = new Set([
  'node_modules', 'dist', '.git', '.github', '.changeset', '.turbo', 'scripts', 'docs', 'patches', 'packages',
]);
const NON_SCALAR_TYPES = new Set([
  'json', 'object', 'array', 'text', 'nvarchar(max)', 'varchar(max)', 'ntext', 'richtext',
]);
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

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

function escapeSqlLiteral(value) {
  return String(value).replace(/'/g, "''");
}

function assertUuid(value, label) {
  const s = String(value ?? '').trim();
  if (!UUID_RE.test(s)) {
    throw new Error(`Expected valid UUID for ${label}, got: ${JSON.stringify(value)}`);
  }
  return s.toUpperCase();
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
          out.push({
            connector: `${entry}/${conn}`,
            connectorDir: connDir,
            jsonPath: join(metaDir, file),
          });
        }
      }
    }
  }
  return out;
}

function resolveTargetFieldName(fieldObj, targetObj) {
  const targetFields = targetObj.relatedEntities?.['MJ: Integration Object Fields'] ?? [];
  const explicit = fieldObj.fields?.RelatedIntegrationObjectFieldName;
  if (explicit) {
    return targetFields.some((tf) => tf.fields?.Name === explicit) ? explicit : null;
  }
  const pks = targetFields.filter((tf) => tf.fields?.IsPrimaryKey).map((tf) => tf.fields?.Name).filter(Boolean);
  return pks.length === 1 ? pks[0] : null;
}

function collectReverseEdgeSet(objects) {
  const edges = new Set();
  for (const obj of objects) {
    const srcName = obj.fields?.Name;
    if (!srcName) continue;
    for (const field of obj.relatedEntities?.['MJ: Integration Object Fields'] ?? []) {
      const lookup = field.fields?.RelatedIntegrationObjectID;
      if (!lookup) continue;
      const match = String(lookup).match(/Name=([^&]+)/);
      if (match) edges.add(`${srcName}->${match[1]}`);
    }
  }
  return edges;
}

function processConnector({ connector, connectorDir, jsonPath }) {
  const raw = readFileSync(jsonPath, 'utf8');
  const eol = raw.includes('\r\n') ? '\r\n' : '\n';
  const endsWithNewline = raw.endsWith('\n');
  const doc = JSON.parse(raw);
  const roots = Array.isArray(doc) ? doc : [doc];

  const repairs = [];
  const skipped = {
    nonScalarOrUnbounded: 0,
    explicitSoftOrWsdl: 0,
    cycleOrSelfOnPartiallyWired: 0,
    unresolvedTargetOrPk: 0,
  };

  for (const root of roots) {
    const objects = root?.relatedEntities?.['MJ: Integration Objects'] ?? [];
    const objByName = new Map(objects.filter((o) => o.fields?.Name).map((o) => [o.fields.Name, o]));
    const existingEdges = collectReverseEdgeSet(objects);
    const alreadyWiredCount = objects.reduce(
      (sum, o) =>
        sum + (o.relatedEntities?.['MJ: Integration Object Fields'] ?? []).filter((f) => f.fields?.RelatedIntegrationObjectID).length,
      0,
    );

    for (const obj of objects) {
      const srcName = obj.fields?.Name ?? '';
      for (const field of obj.relatedEntities?.['MJ: Integration Object Fields'] ?? []) {
        const fields = field.fields;
        if (!fields || fields.RelatedIntegrationObjectID) continue;

        const cfg = parseConfig(fields.Configuration);
        const ref = cfg && (cfg.ReferencedType || cfg.referencedType || cfg.ForeignKeyTarget);
        if (typeof ref !== 'string' || !ref.trim()) continue;

        const fieldType = String(fields.Type ?? '').toLowerCase().trim();
        if (NON_SCALAR_TYPES.has(fieldType) || fields.Length === -1) {
          skipped.nonScalarOrUnbounded++;
          continue;
        }
        if (cfg.softFKReason || cfg.FKDemotedReason || cfg.FKForm === 'soft' || cfg.evidence === 'wsdl+docs') {
          skipped.explicitSoftOrWsdl++;
          continue;
        }

        const targetObj = objByName.get(ref);
        if (!targetObj || !targetObj.primaryKey?.ID || !field.primaryKey?.ID) {
          skipped.unresolvedTargetOrPk++;
          continue;
        }
        const targetFieldName = resolveTargetFieldName(field, targetObj);
        if (!targetFieldName) {
          skipped.unresolvedTargetOrPk++;
          continue;
        }
        if (alreadyWiredCount > 0 && (srcName === ref || existingEdges.has(`${ref}->${srcName}`))) {
          skipped.cycleOrSelfOnPartiallyWired++;
          continue;
        }

        repairs.push({
          fieldRecord: field,
          fieldId: assertUuid(field.primaryKey.ID, `${connector}:${srcName}.${fields.Name}`),
          targetObjId: assertUuid(targetObj.primaryKey.ID, `${connector}:${ref}`),
          targetObjName: ref,
          targetFieldName,
          sourceLabel: `${srcName}.${fields.Name}`,
        });
      }
    }
  }

  if (APPLY && repairs.length > 0) {
    for (const r of repairs) {
      r.fieldRecord.fields.RelatedIntegrationObjectID =
        `@lookup:MJ: Integration Objects.Name=${r.targetObjName}&IntegrationID=@parent:IntegrationID`;
      if (!r.fieldRecord.fields.RelatedIntegrationObjectFieldName) {
        r.fieldRecord.fields.RelatedIntegrationObjectFieldName = r.targetFieldName;
      }
    }
    let serialized = JSON.stringify(doc, null, 2);
    if (eol === '\r\n') serialized = serialized.replace(/\n/g, '\r\n');
    if (endsWithNewline) serialized += eol;
    writeFileSync(jsonPath, serialized, 'utf8');

    writeDeltaMigrations(connector, connectorDir, repairs);
  }

  return { connector, jsonPath, repairs, skipped };
}

function resolveSlug(connectorDir) {
  const manifestPath = join(connectorDir, 'mj-app.json');
  if (!existsSync(manifestPath)) {
    throw new Error(`Missing mj-app.json in ${connectorDir}`);
  }
  const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));
  return String(manifest.name).replace(/^connector-/, '');
}

function assertMonotonicTimestamp(migDir, connector) {
  if (!existsSync(migDir)) return;
  const existing = readdirSync(migDir)
    .map((f) => /^[BV](\d{12})__/.exec(f)?.[1])
    .filter(Boolean)
    .sort();
  const latest = existing[existing.length - 1];
  if (latest && MIGRATION_TIMESTAMP <= latest) {
    throw new Error(
      `${connector}: migration timestamp ${MIGRATION_TIMESTAMP} must be strictly greater than existing ${latest}`,
    );
  }
}

function chunkArray(items, size) {
  const chunks = [];
  for (let i = 0; i < items.length; i += size) {
    chunks.push(items.slice(i, i + size));
  }
  return chunks;
}

function buildSqlServerMigration(connector, repairs) {
  const header = [
    `-- ${connector}: wire ${repairs.length} declared foreign-key relationship(s) into IntegrationObjectField.`,
    `--`,
    `-- These fields carried Configuration.ReferencedType (and IsForeignKey metadata) pointing to`,
    `-- sibling IntegrationObjects in the same connector, but RelatedIntegrationObjectID was left NULL`,
    `-- when the catalog was originally authored/seeded.`,
    `--`,
    `-- DELTA migration, deliberately not a re-seed: existing installed tenants keep their seeded row`,
    `-- IDs and Flyway checksums intact. Idempotent (updates directly by seeded IntegrationObjectField.ID).`,
    '',
  ];
  const chunks = chunkArray(repairs, SQL_BATCH_SIZE);
  const statements = chunks.map((batch, idx) => {
    const values = batch
      .map(
        (r, rowIdx) =>
          `    ('${r.fieldId}', '${r.targetObjId}', N'${escapeSqlLiteral(r.targetFieldName)}')${rowIdx < batch.length - 1 ? ',' : ''} -- ${r.sourceLabel} -> ${r.targetObjName}.${r.targetFieldName}`,
      )
      .join('\n');
    return [
      chunks.length > 1 ? `-- Batch ${idx + 1} of ${chunks.length} (${batch.length} row(s))` : '',
      `UPDATE iof`,
      `SET RelatedIntegrationObjectID = CAST(v.TargetObjectID AS UNIQUEIDENTIFIER),`,
      `    RelatedIntegrationObjectFieldName = v.TargetFieldName`,
      `FROM [__mj].[IntegrationObjectField] AS iof`,
      `INNER JOIN (VALUES`,
      values,
      `) AS v(FieldID, TargetObjectID, TargetFieldName)`,
      `    ON iof.ID = CAST(v.FieldID AS UNIQUEIDENTIFIER);`,
    ]
      .filter(Boolean)
      .join('\n');
  });
  return [...header, ...statements, ''].join('\n\n').replace(/\n\n\n+/g, '\n\n');
}

function buildPostgresMigration(connector, repairs) {
  const header = [
    `-- ============================================================================`,
    `-- MemberJunction PostgreSQL Migration`,
    `-- ${connector}: wire ${repairs.length} declared foreign-key relationship(s) into IntegrationObjectField.`,
    `-- ============================================================================`,
    '',
    `CREATE EXTENSION IF NOT EXISTS "pgcrypto";`,
    `CREATE EXTENSION IF NOT EXISTS "uuid-ossp";`,
    '',
    `CREATE SCHEMA IF NOT EXISTS __mj;`,
    `SET search_path TO __mj, public;`,
    `SET standard_conforming_strings = on;`,
    '',
    `-- ===================== Data (UPDATE) =====================`,
    '',
  ];
  const chunks = chunkArray(repairs, SQL_BATCH_SIZE);
  const statements = chunks.map((batch, idx) => {
    const values = batch
      .map(
        (r, rowIdx) =>
          `    ('${r.fieldId}', '${r.targetObjId}', '${escapeSqlLiteral(r.targetFieldName)}')${rowIdx < batch.length - 1 ? ',' : ''} -- ${r.sourceLabel} -> ${r.targetObjName}.${r.targetFieldName}`,
      )
      .join('\n');
    return [
      chunks.length > 1 ? `-- Batch ${idx + 1} of ${chunks.length} (${batch.length} row(s))` : '',
      `UPDATE "__mj"."IntegrationObjectField" AS iof`,
      `SET "RelatedIntegrationObjectID" = v.target_id::uuid,`,
      `    "RelatedIntegrationObjectFieldName" = v.target_field`,
      `FROM (VALUES`,
      values,
      `) AS v(field_id, target_id, target_field)`,
      `WHERE iof."ID" = v.field_id::uuid;`,
    ]
      .filter(Boolean)
      .join('\n');
  });
  return [...header, ...statements, ''].join('\n\n').replace(/\n\n\n+/g, '\n\n');
}

function writeDeltaMigrations(connector, connectorDir, repairs) {
  const slug = resolveSlug(connectorDir);
  const migDir = join(connectorDir, 'migrations');
  const pgDir = join(connectorDir, 'migrations-pg');
  assertMonotonicTimestamp(migDir, connector);
  mkdirSync(migDir, { recursive: true });
  mkdirSync(pgDir, { recursive: true });

  const baseName = `V${MIGRATION_TIMESTAMP}__${slug}__WireDeclaredForeignKeys`;
  writeFileSync(join(migDir, `${baseName}.sql`), buildSqlServerMigration(connector, repairs), 'utf8');
  writeFileSync(join(pgDir, `${baseName}.pg.sql`), buildPostgresMigration(connector, repairs), 'utf8');
}

function main() {
  const files = findIntegrationJsonFiles(ROOT);
  const results = files.map(processConnector);
  const repaired = results.filter((r) => r.repairs.length > 0);
  const skippedTotal = {
    nonScalarOrUnbounded: 0,
    explicitSoftOrWsdl: 0,
    cycleOrSelfOnPartiallyWired: 0,
    unresolvedTargetOrPk: 0,
  };

  for (const r of results) {
    for (const k of Object.keys(skippedTotal)) skippedTotal[k] += r.skipped[k];
  }

  console.log(`Mode: ${APPLY ? 'APPLY' : 'DRY-RUN'}`);
  console.log(`Scanned ${results.length} connector metadata file(s).`);
  let totalRepaired = 0;
  for (const r of repaired) {
    totalRepaired += r.repairs.length;
    console.log(`  ${r.connector}: ${r.repairs.length} FK(s) (${relative(ROOT, r.jsonPath)})`);
  }
  console.log(`Total scalar FKs ${APPLY ? 'wired' : 'eligible'}: ${totalRepaired} across ${repaired.length} connector(s).`);
  console.log(`Skipped candidates:`, skippedTotal);
}

main();
