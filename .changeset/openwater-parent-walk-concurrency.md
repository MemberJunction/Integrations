---
'@memberjunction/connector-openwater': minor
---

Walk parent details concurrently, and model four embedded collections as their own objects.

A detail walk is one HTTP call per parent and the loop awaited each one before starting the
next. Three objects derive from the same Application door, so each paid the full serial cost
of ~2,079 application details — measured 6,273 records in ~20 minutes on the sandbox, against
13,518 in 73 seconds for objects that fetch a list directly. Parents are now fetched in bounded
concurrent slices and processed in order, so the resume cursor and the record budget behave
exactly as before. Slice width follows the remaining budget, which keeps discovery sampling as
cheap as it was. `fetchConcurrency` on the connection overrides the default of 8, capped at 16.

Four collections embedded in an application's round submissions — judge scorecards, received
and pending recommendations, and aggregated scoring-question scores — were reaching tenants as
unmapped overflow keys, offered as JSON-blob columns on the parent. They are now declared
objects walked through the same detail path, each tagged with its applicationId so it joins the
dependency graph as a child table rather than a stringified array.

Also repairs the T-SQL twin of the case-sensitivity migration, which carried two orphaned END
statements and failed with "Incorrect syntax near 'END'". The Postgres twin was unaffected, so
this never showed on a Postgres tenant — but it meant the catalog repair, and every migration
after it, could not apply on SQL Server at all.
