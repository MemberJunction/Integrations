#!/usr/bin/env node
/**
 * inspect-tables.mjs — what WP Activity Log data does THIS site actually hold?
 *
 * Answers the question that has to come before extending the connector: which `wsal_*` tables exist
 * on a given install, what columns do they carry, and how many rows are in them. It authenticates
 * exactly the way the MJ WordPress connector does — the REST root derived from the site's own
 * `Link rel="https://api.w.org/"` header, then HTTP Basic with an Application Password — so a pass
 * here means the connector's own auth path reaches this data, not merely that some HTTP call worked.
 *
 * WHY ASK RATHER THAN ASSUME
 * Table presence is not a constant. The FREE plugin creates only `wsal_occurrences` and
 * `wsal_metadata`; `wsal_sessions`, `wsal_custom_notifications`, `wsal_generated_reports` and
 * `wsal_periodic_reports` arrive with premium extensions, and their columns vary by version.
 * Declaring objects for tables a site does not have ships a catalog that silently returns nothing.
 *
 * Requires the MJ WSAL Bridge plugin (this directory) to be installed and activated on the site:
 * WP Activity Log publishes no REST surface of its own, so without the bridge there is nothing to ask.
 *
 * Usage:
 *   WP_URL=https://example.org WP_USER=svc-mj WP_APP_PASSWORD='xxxx xxxx …' \
 *     node Platform/WordPress/wp-plugin/mj-wsal-bridge/test/inspect-tables.mjs
 *
 * Read-only: GET only. Reports structure and counts; no activity-log row content is read.
 */

// People paste the URL they were looking at, which is usually wp-admin. Strip the well-known
// WordPress entry points so the site ROOT is what gets probed — the REST root is derived from the
// root's own Link header, and /wp-admin does not carry one.
const SITE = (process.env.WP_URL || '')
  .trim()
  .replace(/\/+$/, '')
  .replace(/\/wp-admin(?:\/.*)?$/i, '')
  .replace(/\/wp-login\.php.*$/i, '')
  .replace(/\/wp-json\/?$/i, '')
  .replace(/\/+$/, '');
const USER = process.env.WP_USER;
const PASS = process.env.WP_APP_PASSWORD;

if (!SITE || !USER || !PASS) {
  console.error('Set WP_URL, WP_USER and WP_APP_PASSWORD (a WordPress Application Password).');
  process.exit(2);
}

const AUTH = 'Basic ' + Buffer.from(`${USER}:${PASS}`).toString('base64');
const redact = (s) => String(s ?? '').split(PASS).join('«redacted»').replace(/(Basic\s+)[A-Za-z0-9+/=]+/g, '$1«redacted»');

async function get(url, withAuth = true) {
  const res = await fetch(url, { headers: withAuth ? { Authorization: AUTH } : {} });
  const text = await res.text();
  let body = null;
  try { body = JSON.parse(text); } catch { /* non-JSON */ }
  return { status: res.status, headers: res.headers, text, body };
}

/** The REST root is DERIVED, exactly as the connector does it — the prefix is filterable. */
async function restRoot() {
  try {
    const head = await fetch(SITE, { method: 'HEAD' });
    const m = /<([^>]+)>;\s*rel="https:\/\/api\.w\.org\/"/i.exec(head.headers.get('link') ?? '');
    if (m) return m[1];
  } catch { /* fall through */ }
  for (const c of [`${SITE}/wp-json/`, `${SITE}/?rest_route=/`]) {
    try {
      const r = await get(c, false);
      if (r.status === 200 && r.text.trim().startsWith('{')) return c;
    } catch { /* next */ }
  }
  return null;
}

const root = await restRoot();
if (!root) {
  console.error(`Could not reach the WordPress REST API at ${SITE}.`);
  process.exit(1);
}
const join = (p) => (root.includes('rest_route=') ? `${root}${p.replace(/^\//, '')}` : `${root.replace(/\/$/, '')}${p}`);

console.log(`\nSite:      ${SITE}`);
console.log(`REST root: ${root}`);

// The bridge must be present, and this is the same namespace check the connector's discovery makes.
// Match on the PARSED namespaces array. PHP's json_encode escapes forward slashes, so the raw body
// contains "mj-wsal\/v1" — a regex for the unescaped form silently never matches on real WordPress.
const index = await get(root, false);
const namespaces = Array.isArray(index.body?.namespaces) ? index.body.namespaces : [];
if (!namespaces.includes('mj-wsal/v1')) {
  console.error('\nThe MJ WSAL Bridge plugin is NOT installed or not activated on this site.');
  console.error('WP Activity Log publishes no REST routes of its own, so without the bridge there is');
  console.error('nothing to inspect. Install Platform/WordPress/wp-plugin/mj-wsal-bridge and activate it.\n');
  process.exit(1);
}

const res = await get(join('/mj-wsal/v1/tables'));
if (res.status === 401 || res.status === 403) {
  console.error(`\nAuthentication failed (HTTP ${res.status}). The bridge requires an administrator.`);
  console.error(redact(res.text).slice(0, 300));
  process.exit(1);
}
if (res.status !== 200 || !res.body) {
  console.error(`\nUnexpected HTTP ${res.status} from /mj-wsal/v1/tables.`);
  console.error(redact(res.text).slice(0, 400));
  process.exit(1);
}

const { base_prefix: prefix, present = [], missing = [] } = res.body;
console.log(`Prefix:    ${prefix}\n`);

const SUPPORTED = new Set(['wsal_occurrences', 'wsal_metadata']);

console.log(`PRESENT — ${present.length} table(s)\n`);
for (const t of present) {
  const mark = t.supported ? 'SUPPORTED  ' : 'not yet    ';
  console.log(`  ${mark}${t.suffix}`);
  console.log(`             ${t.rows.toLocaleString()} row(s), ${t.columns.length} column(s)`);
  console.log(`             ${t.note}`);
  const cols = t.columns.map((c) => `${c.name}:${c.type}${c.key === 'PRI' ? ' [PK]' : ''}`);
  // Wrap the column list rather than truncating it — the whole point is to see the real shape.
  let line = '             ';
  for (const c of cols) {
    if (line.length + c.length > 110) { console.log(line); line = '             '; }
    line += c + '  ';
  }
  if (line.trim()) console.log(line);
  console.log('');
}

if (missing.length) {
  console.log(`ABSENT — ${missing.length} documented table(s) this site does not have\n`);
  for (const m of missing) console.log(`  ${m.suffix}\n             ${m.note}`);
  console.log('');
}

const extendable = present.filter((t) => !t.supported);
console.log('─'.repeat(70));
console.log(`  ${present.length} present · ${present.filter((t) => t.supported).length} already supported · ${extendable.length} could be added · ${missing.length} absent`);
if (extendable.length) {
  console.log(`  candidates: ${extendable.map((t) => `${t.suffix} (${t.rows.toLocaleString()} rows)`).join(', ')}`);
  const empty = extendable.filter((t) => t.rows === 0).map((t) => t.suffix);
  if (empty.length) console.log(`  note: ${empty.join(', ')} exist but hold NO rows — supporting them would add empty objects.`);
} else {
  console.log('  nothing beyond what the connector already supports is present on this site.');
}
console.log('');

// Unsupported-but-populated tables are the only ones where extending the connector buys anything.
process.exit(extendable.some((t) => t.rows > 0) ? 0 : 0);
