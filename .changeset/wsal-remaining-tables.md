---
'@memberjunction/connector-wordpress': minor
---

Sync the remaining WP Activity Log tables.

1.1.0 covered the two tables that hold activity itself — `wsal_occurrences` and `wsal_metadata`. The
Melapress schema documentation lists four more, and this adds them:

| Object | Table | Fields |
|---|---|---|
| `ActivityLogSession` | `wsal_sessions` | 9 |
| `ActivityLogNotification` | `wsal_custom_notifications` | 19 |
| `ActivityLogGeneratedReport` | `wsal_generated_reports` | 16 |
| `ActivityLogPeriodicReport` | `wsal_periodic_reports` | 14 |

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
