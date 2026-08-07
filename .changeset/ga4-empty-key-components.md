---
'@memberjunction/connector-ga4': patch
---

Fix rows being lost when a UTM key dimension is empty.

GA4 reports untagged traffic — direct visits, links in an email signature, anything without UTM
parameters — with an empty `sessionCampaignName` and/or `sessionMedium`. Both are primary-key
components of `UtmPerformance` and `UtmContentPerformance`, and an empty key component does not
survive the write: MJ's generated `spCreate` inserts the row and then re-selects it by primary key,
an empty string is stored as NULL for a nullable column, and `= NULL` matches nothing. The create
returns "no rows returned from SQL", the record is dropped, and — because the engine counts that as
a failed create — the whole run ends `Failed` even though every other row landed.

Observed live: key `2026-08-05||email_signature|` failed a run that had already written 20,736
records.

Empty **key** components are now filled with `(not set)`, which is GA4's own literal for a dimension
with no value on a row — the same token the GA4 UI shows — so joins against anything else in GA4
line up. Non-key dimensions are deliberately left empty: there an empty value is a truthful "no
value" and writes without issue, so substituting would invent data.

`date` is exempt: a row whose date is unusable is already dropped upstream, since it has no identity
to upsert against.
