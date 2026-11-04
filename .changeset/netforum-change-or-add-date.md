---
"@memberjunction/connector-netforum-enterprise": patch
---

NetForum: an incremental read returns rows ADDED since the watermark, not only rows changed.

netFORUM stamps `<prefix>_change_date` only when a record is edited; a newly inserted row carries `<prefix>_add_date` and a NULL change date. The incremental read sent `<prefix>_change_date >= '<watermark>'` alone, so an append-only object never returned a new row: on a live tenant seven objects (member dues, membership and course participation history, GL transactions, payment detail, …) read a clean 0 rows every night for two weeks while netFORUM held new rows for each (with the connector's own column list, `mdh_change_date >= X` returned 0 rows and `mdh_add_date >= X` returned a full page, every row with an empty change date).

- **Predicate.** When the object's definition has `<prefix>_add_date` on the same table as its `<prefix>_change_date` watermark, and the request's column list names it, the read sends `(<change> >= X OR <add> >= X)`, both qualified. Any other watermark, an object without a definition, the default (empty) list, or an add date xWeb answered "Invalid column name" for (learned out of the list) keep the change-date predicate alone. Verified against a live xWeb: the OR form returns the same rows as the add-date form.
- **Next watermark.** The latest of either date across the batch, so rows that were only added move it. An empty value is no longer taken as a watermark (a batch whose change dates were all empty returned `''`).
