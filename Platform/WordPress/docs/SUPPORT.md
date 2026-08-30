# WordPress — Supported & Proven

> **Evidence tier:** 🧪 Mock-only (engine e2e vs mock; Activity Log routes verified live)  ·  **Last verified:** 2026-08-30  ·  **Proof DB(s):** SQL Server (`MJ_CONN_GEN`, disposable)

> 🧪 **Read this before relying on the numbers below.** The connector's evidence is **split**, and one
> tier cannot describe both halves honestly:
>
> - **The 78 core `wp/v2` + `wc/v3` objects** were never contacted with a credential. Their end-to-end
>   proof ran against a **mock** vendor server (`hybridE2E.mode = "mock"`), plus an **unauthenticated**
>   probe of a real WordPress instance that content-verified only the anonymous public routes —
>   **14 of 79 claims**. The build's own honest ceiling is `format-verified-no-creds`.
> - **The 2 WP Activity Log objects** were verified **authenticated, against a real WordPress
>   instance**, end to end over HTTP on 2026-08-30.
>
> **No live client or vendor-hosted WordPress site has ever been contacted, and nothing has been
> written to any WordPress site by this connector.**

## What this connector supports

**80 objects** declared across **1,080 fields** (source: `metadata/integration/.wordpress.integration.json`). 50 declare a write path; 30 are read-only (pull). 11 support incremental sync.

Three families: **WordPress Core** (36, `wp/v2`), **WooCommerce** (42, `wc/v3`), and **WP Activity Log**
(2, `mj-wsal/v1` — see below). All 80 are `Status='Active'`.

### How this vendor actually works

WordPress is **self-hosted**, which changes the shape of the connector in ways worth stating:

- **There is no vendor host.** The base URL is per-tenant and *derived*, never concatenated — the REST
  prefix is filterable (`rest_get_url_prefix()`), so the API root comes from the site's own advertised
  `Link: <…>; rel="https://api.w.org/"` header, falling back to `{site}/wp-json/` and the
  permalink-less `{site}/?rest_route=/`.
- **The object universe is per-site, not per-vendor.** The declared catalog is a stock-install *floor*,
  not a ceiling. `DiscoverObjects` reads the connection's own route index and unions in whatever that
  site actually exposes — custom post types, custom taxonomies, third-party plugin namespaces.
  `DiscoveryIsAuthoritative` is deliberately **false**: a namespace can vanish behind a feature flag,
  and field visibility is capability-gated, so absence proves nothing and nothing is ever deactivated.
- **Auth is HTTP Basic with an Application Password**, which authenticates *every* namespace. An
  optional WooCommerce consumer key/secret pair reaches `wc/*` **only** — a Woo-only credential cannot
  read `wp/v2` at all, and those objects fail with an explicit capability warning rather than an
  empty-but-green sync.
- **Application Passwords require HTTPS.** WordPress core refuses them over plain HTTP unless the site's
  environment type is `local`. A tenant on HTTP cannot be connected at all.
- **No documented rate limit exists.** Neither `wp/v2` nor `wc/v3` states one; throttling is
  host-imposed and per-tenant. `BatchMaxRequestCount` / `BatchRequestWaitTime` are deliberately NULL
  rather than carrying an invented number.

### WP Activity Log requires a companion plugin

The two `ActivityLog*` objects are **not part of the WordPress REST API**. WP Activity Log stores its
events in the custom tables `wsal_occurrences` / `wsal_metadata` and **registers no REST routes at
all** — verified against WSAL 5.6.6: neither `register_rest_route` nor `rest_api_init` appears anywhere
in the plugin.

They are served by the read-only companion plugin shipped in this package at
`wp-plugin/mj-wsal-bridge/`, which the site must have installed. **Without it those two objects return
nothing** — the namespace simply never appears in the site's route index, so they stay empty rather
than erroring.

| Object | Fields | Incremental | Push |
|---|---|---|---|
| `ActivityLogEvent` | 20 | ✓ watermark on `created_at` | — (read-only) |
| `ActivityLogEventType` | 8 | — (static catalog) | — (read-only) |

### Push

- **Status: Declared, never executed.** 50 objects declare a write path (`wp/v2` posts/pages/media/
  users/comments, `wc/v3` orders/products/customers/coupons and friends). **No create, update or delete
  has ever been run against any WordPress site, live or local.** Treat every write capability as an
  unproven declaration. The 30 read-only objects include all 2 Activity Log objects, which are
  read-only by design.

## Verification performed

**WP Activity Log objects — authenticated, real instance, 2026-08-30.** Against WordPress 7.1 +
WooCommerce 11.0.1 + WP Activity Log 5.6.6, using an Application Password over the real REST stack:

- **30/30 assertions pass** (`wp-plugin/mj-wsal-bridge/test/probe.mjs`, read-only): route-index
  discovery, unauthenticated 401 vs authenticated 200, bounded pagination as a total order over
  `(created_on, id)` with no row skipped or duplicated across page boundaries, watermark inclusivity
  and non-regression, payload shape, catalog join integrity, and the `OPTIONS` schema.
- The MJ metadata, the live `OPTIONS` schema and the actual payload were verified to match
  **field-for-field** for both objects (20 and 8).
- The delta migration was replayed on top of the shipped 1.0.0 catalog in SQL Server: **78 objects /
  1,052 fields → 80 / 1,080**, FKs resolving, with the corrected `message` length landing as 4000.
- That run found two real defects, fixed before release: `per_page` declared a `maximum` it did not
  enforce (an unbounded read on a large tenant), and serialised metadata leaking as raw
  `O:8:"stdClass":…` strings.

**Core `wp/v2` + `wc/v3` objects — no credential was ever used.**

- Engine end-to-end ran against a **mock** vendor server. On the current tree that run reports
  `firstSyncComplete = false` with `DEPENDENCY_LAYERING_DEGRADED` (78 objects, 44 FK edges, 3 layers,
  **9 unplaced/cyclic**). A full first sync has never completed, in mock or anywhere else.
- A **RealityProbe** contacted a real stock WordPress 7.1 + WooCommerce 11.0.1 instance
  **unauthenticated**: 79 claims, **14 content-verified** (anonymous public routes only), **19
  unverified**, and every `wc/v3` claim merely `gatedExists`. Route-index comparison confirmed 78 of 79
  declared objects resolve to live route families.
- The incremental/watermark path is connector-side and was confirmed on the wire: 8 captured requests
  carrying `modified_after=…` for both `wp/v2` (site-local) and `wc/v3` (`&dates_are_gmt=true`).
- **92/92 unit tests pass**, covering base-URL derivation, the dual-namespace credential guard,
  `context=edit` degrade, pagination, soft deletes, error classification and watermark narrowing.

## Residual gap (honest)

- **97.5% of the surface has never been credentialed.** 78 of 80 objects have no authenticated
  verification of any kind. Every `wc/v3` object in particular is `gatedExists` — its response shape,
  field names, pagination and declared primary key are unconfirmed against a real WooCommerce store.
- **Every write path is unproven.** 50 objects declare create/update/delete; none has been executed.
- **A full first sync has never completed**, even against the mock: the engine reports
  `DEPENDENCY_LAYERING_DEGRADED` with 9 objects unplaced or cyclic in the FK DAG.
- **No production or client WordPress site has been touched**, and no proven-row count is claimed —
  no rows have been landed in a proof database through the MJ engine from a real WordPress site.
- **The Activity Log proof is HTTP-level, not engine-level.** Those two objects were verified by
  driving their REST surface directly; they have not been synced through the MJ engine into a database.
- **Activity Log coverage is bounded by the site's own retention.** WP Activity Log prunes on a default
  of 3 months when enabled; anything older was deleted by the plugin and no integration can recover it.
- **29 objects declare `PaginationType: 'None'`** and are read in a single request. On a small site that
  is correct; on a large one it is a latent unbounded read.
