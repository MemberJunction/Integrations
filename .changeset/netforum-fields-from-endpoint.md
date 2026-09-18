---
"@memberjunction/connector-netforum-enterprise": minor
---

Ask the endpoint for an object's columns before sampling its data.

`IntrospectSchema` went straight from the declared catalog to record sampling, never calling `DiscoverFields`. The contract's order is DiscoverObjects → DiscoverFields → sampling, and the middle step was missing.

It mattered once 1.5.0 started enumerating the real catalog. On a live netFORUM, discovery found 888 objects; the 862 with no declared metadata could only get columns if streaming their records happened to work, and they landed with **zero** columns — so no primary key, no table, and an RSU that emitted a migration with no DDL. `GetQueryDefinition` could describe every one of them the whole time: measured live, `Abstract Author` 137 columns, `AccountingPeriod` 58, `Individual` 1161, no faults. It also returns data type, nullability and `mdc_width_max`, so widths no longer depend on sampling reaching the object.

`IntrospectSchema` now merges the endpoint's column list into each object before sampling. Sampling is unchanged and still unconditional — it remains the only source for primary-key statistics and for columns that exist in data but in no schema. Any object whose endpoint call fails or returns nothing keeps exactly the fields it had, so a bad response can never empty a working catalog.

Cost matters here too: one schema call per object is trivial next to paging rows, so building the column list no longer competes with the run deadline. A discovery observed taking 20 minutes was still in its field-discovery stage when an unrelated restart killed it.

Also adds a `DeclaredSchema` test seam mirroring `DeclaredObjects`, so `IntrospectSchema`'s step ordering is reachable from unit tests at all — without it the missing call went unnoticed through 38 passing tests.

Known limits, stated rather than implied:
- The response carries no key indicator, so enumerated-only objects gain columns but still no primary key, and the schema builder skips objects without one. netFORUM's `<prefix>_key` convention plus `mdc_table_name` makes this derivable; that is a separate change.
- When sampling fails, `DiscoverFields` now runs twice for that object — once here, once via the sampler's own fallback. Harmless, but redundant.
- The new test does not mutation-prove the fix and says so in place: deleting the call still passes, because the sampler's fallback reaches the same endpoint. A real guard needs a sampler that succeeds with zero rows.
