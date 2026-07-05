#!/usr/bin/env node
/**
 * infer-field-lengths.mjs — semantic length inference for string fields.
 *
 * WHY: the engine SKIPS (does not truncate) any record whose string value exceeds
 * its column width, and a string field with no declared Length defaults to 255.
 * Real-world sizing is empirical — you only find out a bio is 2,595 chars when a
 * live tenant syncs one (PheedLoop Members.about: 54 records/sync silently
 * skipped). Waiting for trial-and-error per field is how records go missing, so
 * this tool GUESSES BETTER up front: it assigns generous, loss-proof defaults by
 * field-name semantics at authoring time, and CI keeps every connector honest.
 *
 * Tiers (name → Length). Widening is loss-proof (columns only grow; tenant
 * schemas ALTER up via schema evolution), so confidence errs generous:
 *   prose   → 4000   about, description, bio(graphy), note(s), summary, body,
 *                    content, message, comment(s), detail(s), abstract,
 *                    overview, remark(s), instruction(s), agenda, blurb, text
 *   url     → 2048   url, uri, link, href, website, homepage, image, photo,
 *                    picture, avatar, logo, banner, thumbnail
 *   email   → 320    email (RFC max is 254; 320 leaves display-name headroom)
 *
 * Only string-typed fields with NO declared Length or Length === 255 (the raw
 * default) are touched — an author's explicit non-default Length always wins.
 *
 * Modes:
 *   node scripts/infer-field-lengths.mjs --check   # CI: exit 1 if any prose
 *                                                  # field sits at the 255
 *                                                  # default (the evidenced
 *                                                  # record-skip class); url /
 *                                                  # email tiers warn only
 *   node scripts/infer-field-lengths.mjs --apply   # authoring: write inferred
 *                                                  # lengths into metadata
 */
import { readFileSync, writeFileSync, readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';

const ROOT = new URL('..', import.meta.url).pathname;

const TIERS = [
  {
    name: 'prose',
    length: 4000,
    failInCheck: true,
    re: /^(about|description|bio|biography|notes?|summary|body|content|message|comments?|details?|abstract|overview|remarks?|instructions?|agenda|blurb|text)$/i
  },
  {
    name: 'url',
    length: 2048,
    failInCheck: false,
    re: /^(url|uri|link|href|website|homepage|image(url)?|photo(url)?|picture(url)?|avatar(url)?|logo(url)?|banner(url)?|thumbnail(url)?)$/i
  },
  {
    name: 'email',
    length: 320,
    failInCheck: false,
    re: /^(email|emailaddress)$/i
  }
];

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

const tierOf = name => TIERS.find(t => t.re.test(name ?? ''));

function scan({ connector, file }, apply) {
  const doc = JSON.parse(readFileSync(file, 'utf8'));
  const roots = Array.isArray(doc) ? doc : [doc];
  const hits = [];
  let changed = false;
  for (const root of roots) {
    for (const o of root?.relatedEntities?.['MJ: Integration Objects'] ?? []) {
      for (const fe of o.relatedEntities?.['MJ: Integration Object Fields'] ?? []) {
        const ff = fe.fields ?? {};
        if ((ff.Type ?? '').toLowerCase() !== 'string') continue;
        if (ff.Length != null && ff.Length !== 255) continue; // explicit author sizing wins
        const tier = tierOf(ff.Name);
        if (!tier) continue;
        hits.push({ object: o.fields?.Name, field: ff.Name, tier: tier.name, length: tier.length, fails: tier.failInCheck });
        if (apply) { ff.Length = tier.length; changed = true; }
      }
    }
  }
  if (apply && changed) writeFileSync(file, JSON.stringify(doc, null, 2) + '\n');
  return { connector, hits };
}

const apply = process.argv.includes('--apply');
let failures = 0, warns = 0, applied = 0;
for (const target of integrationJsons(ROOT)) {
  const { connector, hits } = scan(target, apply);
  if (hits.length === 0) continue;
  if (apply) {
    applied += hits.length;
    console.log(`${connector}: inferred ${hits.length} length(s)`);
    continue;
  }
  for (const h of hits) {
    const line = `${connector} :: ${h.object}.${h.field} — ${h.tier} field at the 255 default; declare Length (inferred: ${h.length}). Oversize values are SKIPPED, not truncated.`;
    if (h.fails) { failures++; console.error(`✗ ${line}`); }
    else { warns++; console.warn(`⚠ ${line}`); }
  }
}
if (apply) {
  console.log(`\n✓ applied ${applied} inferred length(s). Review the diff, then commit.`);
} else if (failures > 0) {
  console.error(`\n${failures} prose field(s) at the 255 default (${warns} advisory). Run --apply or declare lengths. Failing build.`);
  process.exit(1);
} else {
  console.log(`✓ field lengths: no prose fields at the 255 default (${warns} advisory url/email hint(s)).`);
}
