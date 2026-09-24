---
"@memberjunction/connector-netforum-enterprise": patch
---

`obj_key` is the facade object's GUID, not its key column. Stop sending it as one; take the key from the object's own definition.

1.6.3 read `<obj_key>` from `GetFacadeObjectList` as the key COLUMN of every enumerated object. It is the facade object's GUID — the vendor's page shows `<obj_name>ProductSubscription</obj_name><obj_key>22210b27-2396-48f0-a6a7-5e1a8eb9bda6</obj_key>` — so on a tenant with 878 enumerated objects every sample went out as `ORDER BY <guid>` with the GUID in the explicit column list. SQL Server answered in its own words: `Incorrect syntax near 'a11d45'` (the documented `74a11d45-ec60-…` of Abstract Reviewer, split by its tokenizer), `The floating point value '07e325' is out of the range of computer representation` (a hex fragment read as a float), and `Invalid query.` — 975 faults, zero rows, and no key on any of 878 objects in one discovery (2026-09-24). The faults are also what trips xWeb's daily fault lock.

Now:

- `obj_key` is kept as the object's identifier and never reaches `szColumnList`, `szWhereClause` or `szOrderBy`, and never marks a field `IsPrimaryKey`.
- The key comes from `GetQueryDefinition`, whose shape the vendor documents: among the MAIN table's columns (`lst_mdt_name`, unaliased), the `av_key` column described "Primary Key" (the vendor's own sample marks `ind_cst_key` so); else `<prefix>_key`, then `<prefix>_cst_key` (netFORUM's naming: `arp_key`, `evt_key`; `ind_cst_key` / `org_cst_key` for the customer subclasses); else the main table's first key-typed column. A key that cannot be anchored to the main table is not guessed — on a live tenant 493 of 878 objects carry more than one `<x>_key` column and the most frequent prefix is usually a joined table's — and the object is sampled unordered for the statistical classifier to decide. A declared key still wins.
- The definition is fetched once per object per instance and is the source for both `DiscoverFields` and `FetchChanges`, so an object is keyed on the first discovery pass, before its fields are persisted. A definite refusal is not asked again; a network failure is.
- The explicit column list (sent after the tenant's default list faults, or for `@TOP -1`, which the vendor says needs named columns) is built from the definition: every column qualified by its table alias or name (`Membership.mbr_src_code`, `co_individual.ind_cst_key` — required where a table is joined more than once), each name once, the key first.
- With no key known and the default list requested, the vendor guarantees the object's primary key is the first column of every row; the record is identified by it and its name is reported (`KEY_FROM_DEFAULT_LIST_FIRST_COLUMN`).
- A `GetQuery` fault now carries the SHAPE of the request that drew it — object and `@TOP`, named-column count or "default list", the `ORDER BY` column, the number of `WHERE` predicates — never a literal value, so the run log says what was sent.
- "Account is not authorized to perform Select on <object>" is remembered per object and connection; later calls fail locally instead of spending another ~7.5 s fault on a grant that does not appear between calls.
- `DiscoverFields` no longer enumerates the facade list: `obj_key` has nothing to say about columns.
- netFORUM's own type names map (`av_key` → string, `av_date_*` → datetime, `av_flag` → boolean).

Not proven live: the vendor's definition shape against this tenant's build (the account is fault-locked from 1.6.3's run), so `scripts/netforum-xweb-test.sh` steps 4b and 5 in the platform repo print `obj_key` samples, the definition's element names and the accepted `GetQuery` shapes before any discovery is started on 1.6.4.
