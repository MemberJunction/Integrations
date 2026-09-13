---
'@memberjunction/connector-openwater': patch
'@memberjunction/connector-hivebrite': patch
---

Field declarations that PostgreSQL silently discarded are replayed, and the pattern is now linted.

Six OpenWater migrations resolved the integration with

    JOIN "__mj"."Integration" i ON i."Name" = 'openwater'

while the Integration row is named `OpenWater`. SQL Server's default collation is case-INSENSITIVE,
so the predicate matched there and every row landed. PostgreSQL compares strings case-SENSITIVELY, so
it matched nothing — and an `INSERT ... SELECT` whose join matches nothing inserts zero rows and
reports success.

Measured on a PostgreSQL workspace 2026-09-13: OpenWater installed all 30 objects and **24 field
declarations never arrived**, leaving five objects with no columns at all — `ApplicationFile`,
`ApplicationRoundSubmission`, `ApplicationWinnerType`, `Judge`, `Media`. No columns means no primary
key, so discovery ended each with `entity.skipped-no-pk` (and an empty message), and none of the five
can ever sync. The same connector on SQL Server has all of them. These five are exactly the objects
added by the detail-walk work, so the whole of that effort was inert on PostgreSQL.

They cannot be sampled into existence either: all five are detail-walk children whose `APIPath` is a
description rather than a URL (`(embedded in /v2/Applications/{applicationId} roundSubmissions[])`),
reachable only through `Configuration.AccessPath`. The connector walks it at sync time; discovery's
sampler does not. Two of them say so out loud — `ApplicationWinnerType` fails with `Failed to parse
URL` and `Judge` with an HTTP error — and the other three return nothing, silently. So the declared
catalog is their only possible source of columns.

The already-applied migrations are NOT edited — Flyway validates their checksums. Instead a new
migration per connector replays the affected statements with `lower(...)`. Every replayed statement is
either `NOT EXISTS`-guarded or an idempotent `UPDATE`, so on a workspace that already has the rows it
changes nothing.

Hivebrite carried the same defect in `V202607271500__hivebrite__WritablePK` (4 sites) and is repaired
the same way.

A new `scripts/lint-migration-name-case.mjs` fails CI when a migration compares a `Name` column to a
literal differing only by case from the connector's declared Integration name. The 14 already-applied
files are grandfathered and that list may only shrink.
