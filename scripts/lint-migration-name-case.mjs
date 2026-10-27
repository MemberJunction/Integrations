#!/usr/bin/env node
/**
 * A migration that matches a metadata row by NAME must not depend on the database's collation.
 *
 * `WHERE i.Name = 'openwater'` matches on SQL Server, whose default collation is case-INSENSITIVE,
 * and matches NOTHING on PostgreSQL, which compares strings case-SENSITIVELY. An `INSERT ... SELECT`
 * whose join matches nothing inserts zero rows and reports success, so the failure is silent and
 * dialect-specific: the same connector is complete on one workspace and missing rows on another.
 *
 * Observed live 2026-09-13 — OpenWater on a PostgreSQL workspace had 5 of 30 objects with ZERO
 * fields (ApplicationFile, ApplicationRoundSubmission, ApplicationWinnerType, Judge, Media), because
 * six migrations resolved the integration with `i."Name" = 'openwater'` while the row is 'OpenWater'.
 * No fields means no primary key, so discovery skipped all five and none of them can ever sync.
 *
 * Rule: if a migration compares a "Name" column to a string literal, and that literal differs ONLY
 * BY CASE from the connector's declared Integration name, wrap the column in LOWER()/lower().
 *
 * Already-applied migrations cannot be edited — Flyway validates their checksums — so the known
 * offenders are grandfathered. The list may only SHRINK: a new migration must never join this way.
 */
import { readFileSync, readdirSync, existsSync, statSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));

/** Applied before the rule existed; repaired by a later migration rather than edited in place. */
const GRANDFATHERED = new Set([
  'Events/OpenWater/migrations/V202608050910__openwater__DeclareParentWalkTagFields.sql',
  'Events/OpenWater/migrations/V202608211500__openwater__DetailWalkObjects.sql',
  'Events/OpenWater/migrations/V202608212210__openwater__JudgeGrainAndUnionWalk.sql',
  'Events/OpenWater/migrations/V202608222100__openwater__PromotedPKMustSayDeclared.sql',
  'Events/OpenWater/migrations/V202608230150__openwater__HarvestSegmentIsSubmissionFieldValues.sql',
  'Events/OpenWater/migrations/V202608230600__openwater__WinnerTypeIsPerRound.sql',
  'Events/OpenWater/migrations-pg/V202608050910__openwater__DeclareParentWalkTagFields.pg.sql',
  'Events/OpenWater/migrations-pg/V202608211500__openwater__DetailWalkObjects.pg.sql',
  'Events/OpenWater/migrations-pg/V202608212210__openwater__JudgeGrainAndUnionWalk.pg.sql',
  'Events/OpenWater/migrations-pg/V202608222100__openwater__PromotedPKMustSayDeclared.pg.sql',
  'Events/OpenWater/migrations-pg/V202608230150__openwater__HarvestSegmentIsSubmissionFieldValues.pg.sql',
  'Events/OpenWater/migrations-pg/V202608230600__openwater__WinnerTypeIsPerRound.pg.sql',
  'Platform/Hivebrite/migrations/V202607271500__hivebrite__WritablePK.sql',
  'Platform/Hivebrite/migrations-pg/V202607271500__hivebrite__WritablePK.pg.sql',
]);

/** The connector's declared Integration name, from its authoring metadata. */
function integrationName(connDir) {
  const d = join(ROOT, connDir, 'metadata', 'integration');
  if (!existsSync(d)) return null;
  for (const e of readdirSync(d)) {
    if (!e.endsWith('.json')) continue;
    try {
      const raw = JSON.parse(readFileSync(join(d, e), 'utf-8'));
      const node = Array.isArray(raw) ? raw[0] : raw;
      const name = node?.fields?.Name;
      if (name) return name;
    } catch { /* not an integration manifest */ }
  }
  return null;
}

function connectorDirs() {
  const out = [];
  for (const cat of readdirSync(ROOT)) {
    const catPath = join(ROOT, cat);
    if (cat.startsWith('.') || !statSync(catPath).isDirectory()) continue;
    for (const c of readdirSync(catPath)) {
      const p = join(catPath, c);
      if (statSync(p).isDirectory() && existsSync(join(p, 'mj-app.json'))) out.push(`${cat}/${c}`);
    }
  }
  return out;
}

// A "Name" column compared to a literal, with an optional table qualifier, NOT already lowered.
const NAME_EQ = /(?<!lower\(|LOWER\()((?:\w+\.)?\[?"?Name"?\]?)\s*=\s*N?'([^']+)'/g;

const problems = [];
for (const conn of connectorDirs()) {
  const declared = integrationName(conn);
  if (!declared) continue;
  for (const sub of ['migrations', 'migrations-pg']) {
    const dir = join(ROOT, conn, sub);
    if (!existsSync(dir)) continue;
    for (const file of readdirSync(dir)) {
      if (!file.endsWith('.sql')) continue;
      const rel = `${conn}/${sub}/${file}`;
      const text = readFileSync(join(dir, file), 'utf-8');
      text.split('\n').forEach((line, i) => {
        if (line.trim().startsWith('--')) return;
        for (const m of line.matchAll(NAME_EQ)) {
          const lit = m[2];
          if (lit === declared) continue;                    // exact: collation-independent
          if (lit.toLowerCase() !== declared.toLowerCase()) continue; // a different row entirely
          if (GRANDFATHERED.has(rel)) return;
          problems.push({ rel, line: i + 1, lit, declared, col: m[1] });
        }
      });
    }
  }
}

if (problems.length) {
  console.error('Migrations match an Integration by a case-mismatched name literal.');
  console.error('On PostgreSQL these match ZERO rows and the statement silently does nothing.\n');
  for (const p of problems) {
    console.error(`  ${p.rel}:${p.line}`);
    console.error(`      ${p.col} = '${p.lit}'   but the Integration row is '${p.declared}'`);
    console.error(`      fix: wrap the column — lower(${p.col}) = '${p.lit.toLowerCase()}'`);
  }
  console.error(`\n${problems.length} site(s).`);
  process.exit(1);
}
console.log('Migration name matching is collation-independent (grandfathered: %d file(s)).', GRANDFATHERED.size);
