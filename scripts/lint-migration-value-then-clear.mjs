#!/usr/bin/env node
/**
 * A migration must never pass a parameter a VALUE and its _Clear flag in the same call.
 *
 * The generated MJ create/update procs take `p_X` alongside `p_X_Clear`. `_Clear := TRUE` sets the
 * column to NULL, and it is correct beside `p_X := NULL`. Passed beside a real value it silently
 * discards that value — the call succeeds, the row is created, and the column is NULL.
 *
 * Observed live 2026-09-13: five OpenWater objects were created with
 *     p_Configuration := '{"AccessPath":{...}}', p_Configuration_Clear := TRUE
 * so their AccessPath has been NULL since creation, on every dialect (the T-SQL twins pass the same
 * flag). FetchChanges reads Configuration to decide whether to walk a parent; with it NULL the walk
 * is never entered and the fetch requests APIPath literally — which for these objects is a
 * DESCRIPTION, not a URL. Three failed with "Failed to parse URL", one 404'd on an unfilled
 * {mediaId}, one 500'd without its roundId. All five held their watermark and retried forever.
 *
 * Nothing in review catches this: the JSON is right there in the diff, a few hundred characters
 * before the flag that throws it away.
 */
import { readFileSync, readdirSync, existsSync, statSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));

/** Already applied; repaired by a later migration rather than edited (Flyway checksums). */
const GRANDFATHERED = new Set([
  'Events/OpenWater/migrations/V202608211500__openwater__DetailWalkObjects.sql',
  'Events/OpenWater/migrations/V202608212210__openwater__JudgeGrainAndUnionWalk.sql',
  'Events/OpenWater/migrations-pg/V202608211500__openwater__DetailWalkObjects.pg.sql',
  'Events/OpenWater/migrations-pg/V202608212210__openwater__JudgeGrainAndUnionWalk.pg.sql',
]);

// p_X := <something that is not NULL> , ... p_X_Clear := TRUE   (same call, value first)
const PAIR = /p_(\w+)\s*:=\s*(?!NULL\b)('(?:[^']|'')*'|\d+|TRUE|FALSE)\s*,\s*p_\1_Clear\s*:=\s*TRUE/gis;

const problems = [];
function walk(dir) {
  for (const e of readdirSync(dir)) {
    if (e === 'node_modules' || e === '.git' || e === 'dist') continue;
    const p = join(dir, e);
    if (statSync(p).isDirectory()) { walk(p); continue; }
    if (!/\.sql$/.test(e)) continue;
    const rel = p.slice(ROOT.length + 1);
    if (GRANDFATHERED.has(rel)) continue;
    // Strip -- comments: a header may legitimately QUOTE the bad pattern to explain it.
    const text = readFileSync(p, 'utf-8').split('\n')
      .map(l => (l.trimStart().startsWith('--') ? '' : l)).join('\n');
    for (const m of text.matchAll(PAIR)) {
      const line = text.slice(0, m.index).split('\n').length;
      problems.push({ rel, line, param: m[1], preview: m[2].slice(0, 60) });
    }
  }
}
walk(ROOT);

if (problems.length) {
  console.error('A parameter is given a value and cleared in the same call — the value is discarded.\n');
  for (const p of problems) {
    console.error(`  ${p.rel}:${p.line}`);
    console.error(`      p_${p.param} := ${p.preview}…  together with  p_${p.param}_Clear := TRUE`);
    console.error(`      fix: drop the _Clear flag, or pass NULL if the column really should be empty.`);
  }
  console.error(`\n${problems.length} site(s).`);
  process.exit(1);
}
console.log('No parameter is both set and cleared (grandfathered: %d file(s)).', GRANDFATHERED.size);
