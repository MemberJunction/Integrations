# @memberjunction/connector-wordpress

## 1.2.0

### Minor Changes

- 397e3d0: Sync the remaining WP Activity Log tables.

  1.1.0 covered the two tables that hold activity itself — `wsal_occurrences` and `wsal_metadata`. The
  Melapress schema documentation lists four more, and this adds them:

  | Object                       | Table                       | Fields |
  | ---------------------------- | --------------------------- | ------ |
  | `ActivityLogSession`         | `wsal_sessions`             | 9      |
  | `ActivityLogNotification`    | `wsal_custom_notifications` | 19     |
  | `ActivityLogGeneratedReport` | `wsal_generated_reports`    | 16     |
  | `ActivityLogPeriodicReport`  | `wsal_periodic_reports`     | 14     |

  **These four tables are not created by the free plugin.** They arrive with WP Activity Log PREMIUM
  extensions — `wsal_custom_notifications` has zero references in the free codebase at all. So every
  route is PRESENCE-GATED: a site without the table gets a 503 naming it, never a 500 and never an
  empty-but-successful page, because "there is no such table here" and "there is no activity" are
  different facts and the second one is a lie.

  Served by one generic handler rather than four near-identical ones, with two transforms that matter:

  - **Epoch columns gain an ISO-8601 sibling** (`created_on` → `created_on_at`). Same reason
    `ActivityLogEvent` has `created_at`: a bare epoch is ambiguous to date parsers, and seconds read as
    milliseconds date every row to 1970. A stored `0` becomes `null`, not 1970-01-01 — "never sent" is
    not a date.
  - **JSON-in-text columns are decoded** (`notification_settings`, `report_data`, the template and
    filter columns), so a consumer receives an object rather than a string to parse a second time.

  The OPTIONS schema for each is derived from `information_schema` at REQUEST time rather than frozen in
  code, because these tables' shapes vary by premium version — a hardcoded schema would misdescribe some
  sites while looking authoritative.

  None declares a watermark, and each says why in `Configuration.incrementalNote` rather than leaving it
  blank: sessions are deleted on logout so the set only describes the present moment; the other three
  record a creation timestamp but no modification one, so an edited rule or a finished report would
  never resurface under a watermark. All four are full-pulled and hash-diffed.

  Also adds `GET /mj-wsal/v1/tables` to the bridge — introspection reporting which `wsal_*` tables a
  site actually has, with columns and row counts, discovered BY PREFIX so a table from a newer extension
  still appears instead of being invisible. It reads structure and counts only, never row content. The
  companion `test/inspect-tables.mjs` drives it through the connector's own auth path, so a site can be
  surveyed before deciding what to enable.

  Verified against a live WordPress 7.1 + WooCommerce 11.0.1 + WSAL 5.6.6 install with all six tables
  populated: every route returns rows with correct headers, epoch/JSON transforms confirmed on the wire,
  a dropped table returns 503 naming it, and the declared metadata matches the live payload AND the
  OPTIONS schema field-for-field for all four objects. Delta migration `V202608312050` (+ its Postgres
  twin) takes the catalog 80 objects/1,080 fields → 84/1,138 on a tenant already at 1.1.0, additively.

## 1.1.0

### Minor Changes

- f24f517: Sync WP Activity Log events through the WordPress connector, via a bundled companion plugin.

  **The data had no REST surface to discover.** WP Activity Log (WSAL) — the plugin most WordPress
  sites use to record who did what — keeps its events in two custom tables, `wsal_occurrences` and
  `wsal_metadata`, and registers **no REST routes at all**. Verified against WSAL 5.6.6: neither
  `register_rest_route` nor `rest_api_init` appears anywhere in the plugin. Nothing is exposed under
  `wp/v2`, so `DiscoverObjects` could never see it no matter how the connector was configured. The
  data was reachable only by going around WordPress into MySQL directly.

  **So the missing routes are supplied instead.** `wp-plugin/mj-wsal-bridge` is a read-only WordPress
  plugin (two GET routes, no writes, no settings, no tables, no outbound calls) that serves the WSAL
  tables over `mj-wsal/v1`. The connector needs **no code change** to consume it — `DiscoverObjects`
  already treats any GET collection route registering `per_page` as a listable object and explicitly
  does not filter third-party namespaces, `DiscoverFields` reads the routes' `OPTIONS` schema, an
  Application Password already authenticates every namespace, and paging already terminates on
  `X-WP-Total` / `X-WP-TotalPages`. A site without the bridge simply never advertises the namespace,
  and the objects stay empty rather than erroring.

  Two objects, category `WP Activity Log`, added by delta migration `V202608300005` (+ its Postgres
  twin) on top of the 1.0.0 seed — additive only, so a tenant already on 1.0.0 upgrades without a
  catalog reset:

  - **`ActivityLogEvent`** (20 fields) — one row per logged event, watermarked and read-only. Event
    metadata is pivoted from the plugin's name/value table into a single `meta` object server-side, in
    one query per page rather than one per row.
  - **`ActivityLogEventType`** (8 fields) — the event-type catalog (~467 rows on a stock
    WordPress + WooCommerce install), read through WSAL's own `Alert_Manager` so third-party sensors
    register into it automatically. Joins on `alert_id`.

  **The watermark is `created_at`, not `created_on`, and this is the substantive design decision.**
  WSAL stores `created_on` as a double in _seconds_. MJ's date coercion — like most parsers — reads a
  bare number as _milliseconds_, which would date every event to January 1970. Rather than have the
  connector guess the unit, the bridge emits the same instant as an explicit ISO-8601 UTC string and
  the object watermarks on that. `created_on` is still passed through untouched for reconciliation
  against the table.

  The `after` bound is **inclusive**. `created_on` is not unique — events routinely share a timestamp,
  and the ISO form carries milliseconds where the column has microseconds — so an exclusive bound would
  silently drop every event sharing the last synced timestamp. Inclusive re-delivers the boundary event
  occasionally, which dedupes on `id`. Repeating an event is free; losing one is not.

  **Verified live**, not just in format: WordPress 7.1 + WooCommerce 11.0.1 + WSAL 5.6.6, with a
  read-only probe (`wp-plugin/mj-wsal-bridge/test/probe.mjs`, 30 assertions) covering route-index
  discovery, auth, bounded pagination as a total order over `(created_on, id)`, watermark inclusivity
  and non-regression, payload shape, catalog join integrity, and the OPTIONS schema. The delta
  migration was applied on top of the shipped 1.0.0 seed and verified to take the catalog from
  78 objects / 1,052 fields to 80 / 1,080. The connector's existing 92 tests are unaffected.

  Two defects were found and fixed by that live run rather than by inspection: `per_page` declared a
  `maximum` but did not enforce it — WordPress only applies min/max when an arg also declares a
  `validate_callback`, so `per_page=5000` sanitised straight through into the `LIMIT` and turned a
  route advertised as bounded into an unbounded read; and serialised metadata values (WSAL's
  `PluginData` is a serialised `stdClass`) were being emitted as raw `O:8:"stdClass":…` strings. They
  are now decoded to real JSON with `allowed_classes => false` and the inert placeholder flattened to
  its public properties, so no class is ever constructed.

  No existing object, field, ID or capability flag changes. The declared vendor-catalog census
  (`DeclaredAgainst.declaredCatalogCounts`, and `scopeRatio`) is deliberately left at 78 / 1,052 / 222:
  it measures coverage of the WP 7.1 + WooCommerce 11.0.1 stock REST universe, and these two objects
  are not part of that universe at all. Folding them in would overstate vendor coverage.
