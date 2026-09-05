---
'@memberjunction/connector-netforum-enterprise': patch
---

GetQuery sends an empty `szColumnList` instead of `*`. The vendor's own GetQuery page says it in so many words — "Asterisk (*) is not a valid value for szColumnList … you will get this fault" — and the vendor confirmed it against our xWeb credential: every `FetchChanges` call was faulting (surfacing as HTTP 500), and because xWeb counts faulted calls toward `MethodsFaultLimitPerDay` (default 100 a day in the 2017.1 docs, per xWeb user **and IP address**), the faults then locked the calling IP for that user until the next day, which is where the "locked" errors came from. The empty string is the documented form: it "returns the default column listing for the object's primary table", with the primary key always first.

That is a narrower column set than `*` promised, so a batch whose rows do not carry the object's `IncrementalWatermarkField` now says so (`WATERMARK_COLUMN_ABSENT`) instead of silently never advancing the watermark.

Not yet proven live, and said so: the same vendor page notes that `@TOP -1` needs named columns ("specific, named fields must be passed … in order to process using the -1 parameter"), and the connector still falls back to `@TOP -1` for an object with no stable ordering key. Every keyed object takes the paged path (`@TOP <BatchSize>` + `ORDER BY`). Whether either form is accepted with an empty list on a real tenant could not be verified for this release because the IP the fix was made from was still locked from the `*` faults.
