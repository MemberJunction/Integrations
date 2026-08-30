#!/usr/bin/env node
/**
 * probe.mjs — live behavioural probe for the MJ WP Activity Log Bridge.
 *
 * Drives the bridge's real HTTP surface on a real WordPress install and asserts the properties the MJ
 * WordPress connector actually depends on: discoverability, bounded pagination, a correct incremental
 * watermark, and a schema for OPTIONS-based field discovery.
 *
 * Usage:
 *   WP_URL=http://localhost:8088 WP_USER=admin WP_APP_PASSWORD='xxxx xxxx …' \
 *     node Platform/WordPress/wp-plugin/mj-wsal-bridge/test/probe.mjs
 *
 * Read-only: it issues GET and OPTIONS only, and never writes to the site.
 */

const BASE = (process.env.WP_URL || 'http://localhost:8088').replace(/\/$/, '');
const USER = process.env.WP_USER;
const PASS = process.env.WP_APP_PASSWORD;

if (!USER || !PASS) {
  console.error('Set WP_USER and WP_APP_PASSWORD (a WordPress Application Password).');
  process.exit(2);
}

const NS = `${BASE}/wp-json/mj-wsal/v1`;
const AUTH = 'Basic ' + Buffer.from(`${USER}:${PASS}`).toString('base64');

const failures = [];
function check(name, ok, detail = '') {
  console.log(`  ${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? `   ${detail}` : ''}`);
  if (!ok) failures.push(name);
}

async function req(url, method = 'GET', withAuth = true) {
  const res = await fetch(url, { method, headers: withAuth ? { Authorization: AUTH } : {} });
  const text = await res.text();
  let body = null;
  try { body = JSON.parse(text); } catch { /* non-JSON body */ }
  return { status: res.status, headers: res.headers, body };
}

// ── 0. Discovery: what the connector's route-index scan will see ─────────────
console.log('\n0. discovery (route index)');
{
  const { body } = await req(`${BASE}/wp-json/`, 'GET', false);
  check('mj-wsal/v1 is advertised as a namespace', (body?.namespaces || []).includes('mj-wsal/v1'));
  const routes = body?.routes || {};
  for (const path of ['/mj-wsal/v1/events', '/mj-wsal/v1/event-types']) {
    const eps = routes[path]?.endpoints || [];
    const listable = eps.some((e) => (e.methods || []).includes('GET') && 'per_page' in (e.args || {}));
    // This is exactly the connector's discriminator: a GET collection route registering per_page.
    check(`${path} is a listable GET collection (registers per_page)`, listable);
  }
  const rootEps = routes['/mj-wsal/v1']?.endpoints || [];
  check('the namespace root is NOT mistaken for a collection',
    !rootEps.some((e) => 'per_page' in (e.args || {})));
}

// ── 1. Auth ──────────────────────────────────────────────────────────────────
console.log('\n1. auth');
{
  const anon = await req(`${NS}/events`, 'GET', false);
  check('unauthenticated read is denied', anon.status === 401 || anon.status === 403, `HTTP ${anon.status}`);
  const authed = await req(`${NS}/events?per_page=1`);
  check('authenticated read succeeds', authed.status === 200, `HTTP ${authed.status}`);
}

// ── 2. Pagination is bounded and totally ordered ─────────────────────────────
console.log('\n2. pagination');
const all = (await req(`${NS}/events?per_page=100`)).body || [];
{
  const first = await req(`${NS}/events?per_page=2&page=1`);
  const totalPages = parseInt(first.headers.get('x-wp-totalpages') || '0', 10);
  const total = parseInt(first.headers.get('x-wp-total') || '0', 10);
  check('X-WP-Total / X-WP-TotalPages are emitted', total > 0 && totalPages > 0, `total=${total} pages=${totalPages}`);

  const paged = [];
  for (let p = 1; p <= totalPages; p++) {
    const r = await req(`${NS}/events?per_page=2&page=${p}`);
    paged.push(...(r.body || []).map((e) => e.id));
  }
  const single = all.map((e) => e.id);
  check('paging yields the same rows as one big page', JSON.stringify(paged) === JSON.stringify(single),
    `paged=${paged.length} single=${single.length}`);
  check('no row is duplicated across page boundaries', new Set(paged).size === paged.length);
  check('X-WP-Total agrees with the row count', total === single.length, `header=${total} rows=${single.length}`);

  // The route must stay bounded: an oversized per_page is REJECTED, never honoured.
  const over = await req(`${NS}/events?per_page=5000`);
  check('per_page above the cap is rejected', over.status === 400, `HTTP ${over.status}`);
}

// ── 3. Incremental watermark — the property the sync path rests on ───────────
console.log('\n3. incremental watermark');
{
  const mid = all[Math.floor(all.length / 2)];
  const since = (await req(`${NS}/events?per_page=100&after=${encodeURIComponent(mid.created_at)}`)).body || [];
  check('after=<created_at> INCLUDES the boundary row', since.some((e) => e.id === mid.id), `boundary id=${mid.id}`);
  check('after returns nothing older than the bound',
    since.every((e) => e.created_on >= Math.floor(mid.created_on * 1000) / 1000));

  // THE core safety property. created_on is a double with microsecond precision, but created_at carries
  // only milliseconds, so several events can share one watermark value. Re-syncing from the newest
  // watermark must therefore return that row (and any co-timestamped sibling) — never zero rows, which
  // would mean an event was skipped, and never the whole history, which would mean no progress at all.
  const newest = all[all.length - 1];
  const resync = (await req(`${NS}/events?per_page=100&after=${encodeURIComponent(newest.created_at)}`)).body || [];
  const bucket = all.filter((e) => e.created_at === newest.created_at).length;
  check('re-sync from the newest watermark never skips an event', resync.some((e) => e.id === newest.id));
  check('re-sync re-delivers only the co-timestamped tail, not the history',
    resync.length === bucket && resync.length < all.length, `redelivered=${resync.length} bucket=${bucket} total=${all.length}`);

  const byEpoch = (await req(`${NS}/events?per_page=100&after=${mid.created_on}`)).body || [];
  check('after also accepts a raw epoch', JSON.stringify(byEpoch.map((e) => e.id)) === JSON.stringify(since.map((e) => e.id)));

  const bad = await req(`${NS}/events?after=not-a-date`);
  check('an unparseable after is rejected', bad.status === 400, `HTTP ${bad.status}`);
}

// ── 4. Payload shape ─────────────────────────────────────────────────────────
console.log('\n4. payload');
{
  const e = all[0];
  check('created_on / created_at describe the same instant',
    Math.abs(Date.parse(e.created_at) / 1000 - e.created_on) < 0.002,
    `${e.created_on} vs ${e.created_at}`);
  check('created_at is not the 1970 epoch-unit bug', new Date(e.created_at).getUTCFullYear() > 2000, e.created_at);
  check('severity resolves to a name', all.every((x) => x.severity_label && x.severity_label !== ''),
    JSON.stringify([...new Set(all.map((x) => `${x.severity}=${x.severity_label}`))]));
  check('alert_label is resolved', all.every((x) => typeof x.alert_label === 'string'));
  check('events carry pivoted metadata', all.some((x) => x.meta && Object.keys(x.meta).length > 0));
  // A serialised stdClass (WSAL's PluginData) must arrive as real JSON, not an "O:8:…" string.
  const structured = all.filter((x) => Object.values(x.meta || {}).some((v) => v && typeof v === 'object'));
  const rawSerialized = all.filter((x) => Object.values(x.meta || {}).some((v) => typeof v === 'string' && /^[OaC]:\d+:/.test(v)));
  check('serialised metadata is decoded to real structures', structured.length > 0, `${structured.length} row(s)`);
  check('no metadata value leaks as a raw PHP-serialised string', rawSerialized.length === 0, `${rawSerialized.length} row(s)`);
}

// ── 5. Catalog + join integrity ──────────────────────────────────────────────
console.log('\n5. event-type catalog');
{
  const first = await req(`${NS}/event-types?per_page=100`);
  const totalPages = parseInt(first.headers.get('x-wp-totalpages') || '0', 10);
  const types = [];
  for (let p = 1; p <= totalPages; p++) {
    types.push(...((await req(`${NS}/event-types?per_page=100&page=${p}`)).body || []));
  }
  check('catalog is populated', types.length > 300, `${types.length} event types`);
  const ids = new Set(types.map((t) => t.alert_id));
  check('catalog ids are unique', ids.size === types.length);
  const unresolved = all.map((e) => e.alert_id).filter((id) => !ids.has(id));
  check('every logged alert_id resolves in the catalog', unresolved.length === 0, `unresolved=${JSON.stringify(unresolved)}`);
  check('catalog rows carry label + category + severity',
    types.slice(0, 25).every((t) => t.label && t.category && t.severity));
}

// ── 6. OPTIONS schema — what DiscoverFields reads ────────────────────────────
console.log('\n6. OPTIONS schema');
{
  const { body } = await req(`${NS}/events`, 'OPTIONS');
  const props = body?.schema?.properties || {};
  check('OPTIONS advertises a field schema', Object.keys(props).length >= 20, `${Object.keys(props).length} properties`);
  check('created_at is typed as a date-time', props.created_at?.format === 'date-time');
  check('meta is typed as an object', props.meta?.type === 'object');
  const payloadKeys = Object.keys(all[0] || {});
  const undeclared = payloadKeys.filter((k) => !(k in props));
  check('every payload field is declared in the schema', undeclared.length === 0, `undeclared=${JSON.stringify(undeclared)}`);
}

console.log(failures.length ? `\n${failures.length} FAILURE(S): ${JSON.stringify(failures)}\n` : '\nALL PASS\n');
process.exit(failures.length ? 1 : 0);
