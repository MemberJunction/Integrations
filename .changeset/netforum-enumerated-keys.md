---
"@memberjunction/connector-netforum-enterprise": patch
---

Keep the key netFORUM names for every enumerated object, and never read a whole table to sample fifty rows.

`GetFacadeObjectList` returns `obj_name`, `obj_key` and `obj_description` for every facade. The parser read the first and third and dropped `obj_key`, and `GetQueryDefinition` — the only other source of column metadata — describes columns without marking a key. So every enumerated-only object arrived keyless: 862 of 888 on a live tenant.

Keyless cost three things, all observed live:

- the schema builder skipped the object, so it never got a table;
- the soft-key classifier was asked to guess a key it had no signal for (no wizard hint, `*_key` names outside its naming tier, no sample rows), and reported every one of them unresolved;
- `FetchChanges` pages on the key, and without one it sent `@TOP -1` — the **entire table** in one SOAP call — to sample fifty rows. Across ~860 objects that is the discovery that took hours and the resident memory the kernel killed (15.3 GB and 15.6 GB anon-RSS on a 15.7 GB box, 2026-09-18 and 2026-09-21).

Now:

- `DiscoverObjects` records each `obj_key`; `DiscoverFields` marks that column `IsPrimaryKey` when nothing declared carries a key. A declared key always wins.
- `DiscoverFields` no longer throws for an object the engine cache does not know yet — the endpoint's column list does not depend on the cache — so enumerated-only objects get their columns and key on the first pass instead of the second.
- `FetchChanges` uses the enumerated key for paging while the persisted catalog does not carry it yet, and bounds any discovery sample by `SampleTargetRecords` whether or not the object can page (`@TOP n` needs no ordering key; the rows are simply in the door's natural order). A sync of a genuinely keyless object is unchanged: still one unbounded fetch, still `UNPAGINATED_FETCH`.
- The facade list is fetched at most once per connector instance, success or failure. A failing `GetFacadeObjectList` is never retried per object, because xWeb counts faults against the daily budget that locks the account.

Known limits, stated rather than implied:

- A key named by the enumeration must also be a column `GetQueryDefinition` returns; otherwise the object stays keyless, honestly.
- `@TOP n` without `ORDER BY` on the door is unproven live; the vendor's caveat about `@TOP -1` needing named columns is not known to apply to a positive `n`.
