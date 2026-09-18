---
"@memberjunction/connector-netforum-enterprise": patch
---

Retry GetQuery with an explicit column list when xWeb rejects its own default.

An empty `szColumnList` asks xWeb for the object's configured default columns. On a tenant whose default list is itself `*`, the door rejects the value it just supplied: `'*' is not a valid value for szColumnList`. The connector never sends `*` — this is a fault about the tenant's configuration surfacing as a fault about our request.

Measured on the BC sandbox 2026-09-18, a discovery over 888 objects: **862 faulted this way**, roughly 15 seconds each. That exhausted the 45-minute stage deadline at object 336, and because the pipeline fails rather than persisting what it gathered, **nothing was written at all** — 45 minutes of successful introspection discarded. The 26 objects that did succeed were exactly the 26 carrying a declared `Configuration.columnList`, which is what let them bypass the default.

`FetchChanges` now retries once with a named column list when it sees that specific fault. Named columns bypass the default entirely, so the second attempt succeeds. The column names come from the best source available at the moment of the call:

- during discovery, the columns `GetQueryDefinition` returned earlier in the same run — the fields are not persisted yet, so nothing else knows them;
- during sync, the object's cached fields.

Either way the list is completed with the primary key, ordering key and watermark, because the door returns ONLY named columns and `FetchChanges` reads all three.

Behaviour is unchanged on tenants whose default list is usable: the first attempt is still an empty `szColumnList` and they never reach the retry. An unrelated HTTP 500 is not retried and still surfaces as the error it is.

Both tests are mutation-proof by construction — the first queued response is the fault, so deleting the retry makes them fail. That is deliberate: the 1.6.0 test for the sibling fix passed with its fix removed, because the sampler's fallback reached the same endpoint.

Known limits, stated rather than implied:
- This makes sampling *reachable*, not complete. An object whose columns no source knows still gets an empty list and still faults.
- The run deadline is untouched. A catalog wide enough to exceed 45 minutes of honest work still fails and still discards everything; persisting on deadline is an engine-side change, not a connector one.
- `GetQueryDefinition` carries no key indicator, so enumerated-only objects gain columns but no primary key, and the schema builder still skips them.
