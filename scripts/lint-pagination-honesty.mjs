#!/usr/bin/env node
/**
 * lint-pagination-honesty.mjs — a connector that reports `HasMore: false` must
 * actually be able to advance a page.
 *
 * THE BUG CLASS this guards. `HasMore: false` is how a connector tells the sync
 * engine "that was the last page, stop". A connector with no working page-advance
 * mechanism returns it on page one, forever — so every object silently caps at a
 * single page. Nothing errors. The run goes green, the row counts look plausible
 * (a first page IS real data), and the truncation only shows up as "the client
 * says records are missing" weeks later.
 *
 * GrowthZone shipped exactly this: its paging param was `skip` where the vendor
 * wanted `$skip`, so page two was never requested and all 17 objects were capped
 * at one page — through a full green build.
 *
 * ── THE RULE, AND WHY IT ISN'T THE OBVIOUS ONE ────────────────────────────────
 * The obvious rule — "no `HasMore: false` without honoring BatchSize" — is wrong
 * in this repo, and measurably so: `BatchSize` is not the plumbing name (it's
 * `ctx.PageSize`), and cursor-paginated connectors legitimately have no page-size
 * param at all. Applied literally it flags two CORRECT connectors and misses the
 * actual defect shape.
 *
 * So the rule is the honest generalization: a source that returns a literal
 * `HasMore: false` must reference at least one page-advance mechanism —
 *   • a page size  (`PageSize` / `BatchSize`),
 *   • a cursor     (`NextCursor` / `nextRecordsUrl` / `nextPageToken` / `nextLink`), or
 *   • a page number (an advancing `{pageNumber}` path segment).
 *
 * NimbleAMS passes on the cursor arm: it deliberately omits a SOQL `LIMIT`
 * because Salesforce paginates natively via `done`/`nextRecordsUrl`, and a LIMIT
 * would cap the entire result set. That is correct code, and a BatchSize-shaped
 * rule would have pushed someone to "fix" it into a bug.
 *
 * File granularity is deliberate. Deciding whether a PARTICULAR `HasMore: false`
 * is the legitimate terminal (last page, empty result, `PaginationType: 'None'`,
 * error path) or the bug needs the enclosing method's semantics, and a gate that
 * guesses at that produces false positives — which get muted, which kills the
 * gate. "Does this connector possess a page-advance mechanism at all" is answerable
 * mechanically and catches the shape that actually shipped.
 */
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, dirname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const SKIP_DIRS = new Set(['node_modules', 'dist', '.git', '.github', '.changeset', '.turbo', 'migrations', 'migrations-pg']);

/** A literal `HasMore: false` / `HasMore = false` (not `HasMore: someExpr`). */
const RETURNS_FALSE = /HasMore\s*[:=]\s*false\b/;
/**
 * Any page-advance mechanism. FOUR families, because the repo genuinely ships
 * all four and a rule that knows only one turns correct code into a "violation":
 *   • page size   — offset/limit style
 *   • cursor      — vendor hands back an opaque next-page token or URL
 *   • page number — Impexium advances a {pageNumber} PATH segment (no query param
 *                   and no cursor at all), declared as PaginationType 'PageNumber'
 *   • keyset      — the connector advances a KEY it derives itself and hands back
 *                   through the engine's own keyset channel (`NextAfterKeyValue` →
 *                   `FetchContext.AfterKeyValue`). This is what a parent-scope walk
 *                   and an id-window scan use; there is no vendor cursor and no page
 *                   size, and the object is nonetheless fully resumable. Omitting
 *                   this arm flagged `Shared/IdWindowScan` — a module whose entire
 *                   purpose is bounded, resumable reads — as unable to paginate.
 * No leading \b: `_pageSize` (the unused-parameter convention) must still count.
 */
const CAN_ADVANCE = /(pageSize|batchSize|nextCursor|nextRecordsUrl|nextPageToken|nextLink|nextPageURL|pageNumber|afterKeyValue)\b/i;

/**
 * Connectors with NO page-advance mechanism that are nonetheless correct, each
 * with the reason. Keep this tiny and justified — an entry here is a promise
 * that the source genuinely cannot paginate, not that the warning was annoying.
 */
const EXEMPT = {
  'Platform/FileFeed/src/FileFeedConnector.ts':
    'Reads a delimited file in full — there is no remote page to advance to. ' +
    'Its `HasMore: false` is the only truthful answer, on every call.'
};

function findSources(dir, out = []) {
  for (const entry of readdirSync(dir)) {
    if (SKIP_DIRS.has(entry)) continue;
    const p = join(dir, entry);
    if (statSync(p).isDirectory()) findSources(p, out);
    else if (entry.endsWith('.ts') && !entry.endsWith('.test.ts') && !entry.endsWith('.d.ts')) out.push(p);
  }
  return out;
}

const violations = [];
const unusedExemptions = new Set(Object.keys(EXEMPT));

for (const file of findSources(ROOT)) {
  const rel = relative(ROOT, file);
  const src = readFileSync(file, 'utf-8');
  if (!RETURNS_FALSE.test(src)) continue;
  if (EXEMPT[rel]) {
    unusedExemptions.delete(rel);
    continue;
  }
  if (!CAN_ADVANCE.test(src)) violations.push(rel);
}

// A stale exemption is its own failure: it means the file was renamed, deleted,
// or gained pagination, and the promise attached to it no longer describes
// anything. Silent-but-wrong exemptions are how gates rot.
const stale = [...unusedExemptions].sort();

if (violations.length === 0 && stale.length === 0) {
  console.log('✓ pagination-honesty gate: every connector that reports HasMore:false can advance a page.');
  process.exit(0);
}

if (violations.length > 0) {
  console.error(`\n✗ ${violations.length} source(s) return a literal HasMore:false with no way to advance a page:\n`);
  for (const v of violations) console.error(`    ${v}`);
  console.error(
    '\n  A connector with no page-advance mechanism returns HasMore:false on page ONE,\n' +
      '  so every object silently caps at a single page. Nothing errors; the run goes\n' +
      '  green with a plausible row count. GrowthZone shipped this way (paging param\n' +
      '  `skip` where the vendor wanted `$skip`) across all 17 of its objects.\n\n' +
      '  Fix: plumb the page size (ctx.PageSize) or the vendor cursor (NextCursor)\n' +
      '  through the fetch path. If the source genuinely cannot paginate — it reads a\n' +
      '  whole file, or the vendor returns one fixed document — add it to EXEMPT in\n' +
      '  this script WITH the reason.'
  );
}

if (stale.length > 0) {
  console.error(`\n✗ ${stale.length} EXEMPT entr${stale.length === 1 ? 'y matches' : 'ies match'} nothing — remove or re-point:\n`);
  for (const s of stale) console.error(`    ${s}`);
  console.error('\n  The file was renamed, deleted, or gained pagination; the exemption is now fiction.');
}

process.exit(1);
