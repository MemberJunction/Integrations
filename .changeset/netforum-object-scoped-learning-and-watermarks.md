---
"@memberjunction/connector-netforum-enterprise": minor
---

NetForum: object-scoped fault learning, an own-table fallback, and watermark integrity (supersedes #418).

- **Fault learning, per object and persisted.** What an xWeb fault teaches (unselectable columns, unbound qualifiers, missing tables, an unusable default list, a list that breaks the SQL) is scoped to the object that paid for it and kept in `.nf-learned.json`, so a restart does not re-pay it against xWeb's ~100/day lock. Requests nothing has vouched for are probes under a persisted daily budget. Under MJAPI the file lives in `<root>/state/netforum`, outside the release directory a deploy replaces.
- **Own-table fallback.** An object whose full column list breaks xWeb's SQL is read through its own table's columns (the table that holds its key — not always the definition's MainTable) instead of being refused on every sync.
- **Watermark integrity.** The predicate value is sent as a literal SQL Server parses (offset dropped, `Z` backed off a day, US-form datetimes understood); an object with an incremental watermark is never a keyset object (`StableOrderingKey` returns null), so its date watermark is no longer dropped or replaced by a row key; a stored watermark that is not a date is not sent; a date-conversion fault on the predicate is never learned as a broken column list.
