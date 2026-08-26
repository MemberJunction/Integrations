#!/usr/bin/env node
/**
 * lint-catalog-freshness-pin.mjs — every connector must say what its catalog was declared
 * against, and when (concern A9b).
 *
 * THE BUG CLASS this guards: a connector's declared object catalog is derived from a vendor
 * artifact — an OpenAPI doc, a WSDL, a plugin's PHP source, a support-site article. That
 * artifact moves. The catalog does not. With no record of WHICH artifact was read and WHEN,
 * a stale catalog is indistinguishable from a current one: nobody can tell whether a missing
 * object means the connector is wrong or the vendor changed after we looked, and nobody can
 * tell whether it is worth re-deriving. The declaration reads as settled fact because the
 * gap was never written down.
 *
 * This is NOT the same freshness as A9 (scripts/check-catalog-freshness.mjs), which compares
 * a package version to a git tag. A connector can be perfectly tag-current and declared
 * against a spec nobody has re-read in two years. A9 is silent on that; this is the guard
 * for it.
 *
 * THE RULE, per connector: metadata/integration/*.integration.json must carry
 * `fields.Configuration.DeclaredAgainst` containing, at any depth,
 *   (a) at least one source URL — what was read; AND
 *   (b) at least one ISO date (YYYY-MM-DD) — when it was read.
 *
 * That is a deliberately LOW bar: URL + date, nothing more. The richer pins in the tree —
 * a sha256 of the fetched artifact so a refetch can be diffed, a pinned vendor version so a
 * missing object can be attributed, a catalogLastEditedAt separating "source fetched" from
 * "catalog edited" — are what make a pin genuinely useful, and Platform/WordPress and
 * AMS/NetForum are the worked examples. They are documented best practice, NOT enforced:
 * a bar high enough to be ignored guards nothing.
 *
 * GRANDFATHERED connectors predate the rule and are exempt. The list is standing tech-debt,
 * not a licence: a NEW connector must pin from day one. The exemption is checked in BOTH
 * directions — once a grandfathered connector gains a valid pin, this fails until it is
 * removed from the list below, so the debt list can only shrink and can never quietly rot.
 *
 *   node scripts/lint-catalog-freshness-pin.mjs            # lint (fails on violation)
 *   node scripts/lint-catalog-freshness-pin.mjs --report   # print every connector's state, never fail
 *   node scripts/lint-catalog-freshness-pin.mjs --json     # machine-readable, never fail
 */
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, dirname, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const REPORT = process.argv.includes('--report');
const JSON_OUT = process.argv.includes('--json');
const SKIP_DIRS = new Set(['node_modules', 'dist', '.git', '.github', '.changeset', 'scripts', '.turbo', 'docs']);

// ── Standing debt: connectors that predate the rule. Remove an entry the moment that
// connector gains a real pin — this linter fails if a listed connector already has one.
const GRANDFATHERED = new Set([
  'AMS/Aptify',
  'AMS/Fonteva',
  'AMS/GrowthZone',
  'AMS/Impexium',
  'AMS/MemberSuite',
  'AMS/NimbleAMS',
  'AMS/Novi',
  'AMS/Rhythm',
  'AMS/Wicket',
  'AMS/WildApricot',
  'AMS/YourMembership',
  'AMS/iMIS',
  'CRM/Blackbaud',
  'CRM/DynamicsDataverse',
  'CRM/HubSpot',
  'CRM/NeonCRM',
  'CRM/Salesforce',
  'Events/Cvent',
  'Events/Eventbrite',
  'Events/OpenWater',
  'Events/PheedLoop',
  'Events/Whova',
  'Finance/BillCom',
  'Finance/BusinessCentral',
  'Finance/NetSuite',
  'Finance/QuickBooks',
  'Finance/SageIntacct',
  'Finance/Stripe',
  'LMS/PathLMS',
  'LMS/Reach360',
  'LMS/Totara',
  'Marketing/ConstantContact',
  'Marketing/GA4',
  'Marketing/MagnetMail',
  'Marketing/Mailchimp',
  'Marketing/PropFuel',
  'Marketing/Rasa',
  'Marketing/Reply',
  'PM/Asana',
  'PM/Everhour',
  'Platform/HigherLogicThriveCommunity',
  'Platform/HigherLogicVanilla',
  'Platform/Hivebrite',
  'Platform/MJtoMJ',
  'Platform/MongoDB',
  'Platform/MySQL',
  'Platform/ORCID',
  'Platform/Oracle',
  'Platform/PostgreSQL',
  'Platform/SQLServer',
  'Platform/SharePoint',
  'Platform/Snowflake',
  'Platform/Zendesk',
]);

const ISO_DATE = /\b\d{4}-\d{2}-\d{2}\b/;
const URL_RE = /^https?:\/\/\S+/;

function findIntegrationFiles(dir, out = []) {
  for (const e of readdirSync(dir)) {
    if (SKIP_DIRS.has(e)) continue;
    const p = join(dir, e);
    let st; try { st = statSync(p); } catch { continue; }
    if (st.isDirectory()) findIntegrationFiles(p, out);
    else if (e.endsWith('.integration.json')) out.push(p);
  }
  return out;
}

/** Any string in the block that is a URL / contains an ISO date, at any depth. */
function scan(node, acc = { urls: 0, dates: 0 }) {
  if (typeof node === 'string') {
    if (URL_RE.test(node.trim())) acc.urls++;
    if (ISO_DATE.test(node)) acc.dates++;
  } else if (Array.isArray(node)) {
    for (const v of node) scan(v, acc);
  } else if (node && typeof node === 'object') {
    for (const v of Object.values(node)) scan(v, acc);
  }
  return acc;
}

const results = [];
for (const file of findIntegrationFiles(ROOT)) {
  const rel = relative(ROOT, file);
  const connector = rel.split(sep).slice(0, 2).join('/');
  let recs;
  try { recs = JSON.parse(readFileSync(file, 'utf8')); }
  catch (e) { results.push({ connector, rel, state: 'unparseable', detail: e.message }); continue; }

  const cfg = (Array.isArray(recs) ? recs[0] : recs)?.fields?.Configuration ?? {};
  const block = cfg.DeclaredAgainst;
  if (block === undefined) { results.push({ connector, rel, state: 'missing' }); continue; }
  const { urls, dates } = scan(block);
  if (!urls || !dates) {
    results.push({ connector, rel, state: 'incomplete', urls, dates });
  } else {
    results.push({ connector, rel, state: 'pinned', urls, dates });
  }
}
results.sort((a, b) => a.connector.localeCompare(b.connector));

const pinned = results.filter((r) => r.state === 'pinned');
// A connector must pin unless grandfathered; a grandfathered one that HAS pinned must leave the list.
const unpinnedNotExempt = results.filter((r) => r.state !== 'pinned' && !GRANDFATHERED.has(r.connector));
const staleExemptions = pinned.filter((r) => GRANDFATHERED.has(r.connector));
const knownConnectors = new Set(results.map((r) => r.connector));
const orphanExemptions = [...GRANDFATHERED].filter((c) => !knownConnectors.has(c));

if (JSON_OUT) {
  console.log(JSON.stringify({
    total: results.length, pinned: pinned.length,
    grandfathered: GRANDFATHERED.size,
    violations: unpinnedNotExempt.length + staleExemptions.length + orphanExemptions.length,
    connectors: results,
  }, null, 2));
  process.exit(0);
}

if (REPORT) {
  for (const r of results) {
    const tag = GRANDFATHERED.has(r.connector) ? ' (grandfathered)' : '';
    console.log(`  ${r.state.padEnd(11)} ${r.connector}${tag}`);
  }
  console.log(`\n${pinned.length} of ${results.length} connector(s) carry a catalog-freshness pin.`);
  process.exit(0);
}

let bad = 0;
if (unpinnedNotExempt.length) {
  bad += unpinnedNotExempt.length;
  console.error(`✗ catalog-freshness pin: ${unpinnedNotExempt.length} connector(s) declare a catalog with no record of what it was declared against:`);
  for (const r of unpinnedNotExempt) {
    const why = r.state === 'missing' ? 'no Configuration.DeclaredAgainst block'
      : r.state === 'incomplete' ? `DeclaredAgainst present but ${!r.urls ? 'no source URL' : ''}${!r.urls && !r.dates ? ' and ' : ''}${!r.dates ? 'no ISO date' : ''}`
      : r.detail;
    console.error(`  - ${r.connector}  — ${why}  (${r.rel})`);
  }
  console.error(`\n  Fix: add fields.Configuration.DeclaredAgainst with the source URL(s) you derived the`);
  console.error(`  catalog from and the date you read them. See AMS/NetForum or Platform/WordPress for`);
  console.error(`  the fuller form (artifact sha256, pinned vendor version, catalogLastEditedAt).`);
}
if (staleExemptions.length) {
  bad += staleExemptions.length;
  console.error(`\n✗ catalog-freshness pin: ${staleExemptions.length} grandfathered connector(s) now carry a real pin — remove them from GRANDFATHERED:`);
  for (const r of staleExemptions) console.error(`  - ${r.connector}`);
  console.error(`\n  The debt list must only shrink. Delete these entries from scripts/lint-catalog-freshness-pin.mjs.`);
}
if (orphanExemptions.length) {
  bad += orphanExemptions.length;
  console.error(`\n✗ catalog-freshness pin: ${orphanExemptions.length} GRANDFATHERED entr(ies) match no connector (renamed or removed):`);
  for (const c of orphanExemptions) console.error(`  - ${c}`);
}
if (bad) { console.error(`\n${bad} violation(s). Failing build.`); process.exit(1); }

const exempt = results.length - pinned.length;
console.log(`✓ catalog-freshness pin: ${results.length} connector(s) checked; ${pinned.length} pinned, ${exempt} grandfathered (standing debt, list can only shrink).`);
