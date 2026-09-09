---
'@memberjunction/connector-netsuite': patch
---

Retire the four declared objects whose `suiteQLTable` NetSuite rejects outright.

The Declared catalog was authored by camel-collapsing NetSuite's UI labels into record-type slugs. For most of the 200+ standard types the collapse lands on the real record-type id; for four it does not, and `FetchChanges` runs `SELECT * FROM <slug>` through SuiteQL, so the read fails on every account, on every run, with HTTP 400 `Invalid search type: <slug>` (`INVALID_PARAMETER`). Requisition (real id `purchaserequisition`), Weekly Timesheet (`timesheet`), Bin Putaway Worksheet (`binworksheet`) and Advanced Intercompany Journal Entry (`advintercompanyjournalentry`) could never sync, yet each shipped Active, was auto-mapped, and spent a request, an error and a retry ladder every run.

They are now `Status='Disabled'` in the metadata and in a new delta migration (SQL Server + Postgres) keyed by the seeded row IDs — nothing is deleted, no ID is re-minted, and the released seed is untouched, so no Flyway checksum breaks. They are not remapped either: `DiscoverObjects` unions the Declared floor with the account's live metadata-catalog and passes unknown slugs through verbatim, so tenants already surface the real record type as its own object, and a remap would put two objects over one table.

Objects that fail with `Record 'x' was not found` are explicitly out of scope: that record type is real and merely not provisioned for the account (already reported as `OBJECT_UNAVAILABLE`), and it syncs as soon as the feature is enabled. A catalog test pins the metadata and both migration dialects to exactly these four rows.
