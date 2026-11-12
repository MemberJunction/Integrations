---
"@memberjunction/connector-sqlserver": patch
---

SQL Server: a sync no longer skips rows when more than two pages have changed (#506). The engine raises the watermark to each page's newest value and also passes the row offset the connector returned. The connector returned an offset counted from the start of the scan, so every page after the first skipped rows it had not read: about 1,600 of 7,000 changed rows were fetched, the run reported success, and the stored watermark moved past the rest. The connector now returns the offset relative to the watermark the engine sends next, which is the number of rows already read that carry that watermark value. An object with no watermark column pages as before.

Rows skipped by earlier runs are behind the stored watermark and are not read again by this fix. For each object that was synced with more than 400 changed rows in one run, move its watermark back to before the first such run, or run a full sync.
