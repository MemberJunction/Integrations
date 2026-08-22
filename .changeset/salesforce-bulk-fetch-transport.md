---
'@memberjunction/connector-salesforce': patch
---

Bulk API 2.0 as a fetch transport, and two hardening fixes ported from the Nimble campaign.

- **Bulk query fetch transport** (opt-in per object: `DefaultQueryParams.fetch_transport =
  "bulk_query"`): backfills route through a Bulk API 2.0 query job — Salesforce materializes
  the export server-side and the connector downloads CSV pages via `Sforce-Locator`, so the
  serial REST cursor (seconds per page on wide objects) disappears from the big first pull.
  The query is stripped of ORDER BY, which Bulk 2.0 accepts but which disables PK Chunking
  (Salesforce's own remedy for bulk-query timeouts is to remove it).
  The cursor carries the whole job identity (`bulkq:{id, object, locator}`): mid-job restarts
  re-poll the same job, mid-download restarts resume at the locator. Failed/aborted jobs throw
  with the vendor errorMessage; a job created without an id throws rather than losing the job.
  Incremental trickle (a watermark exists) stays on the REST path where per-page watermark
  advance already works. Applies to every Salesforce-platform connector that extends this
  class (Fonteva today; Nimble AMS after its rebase).
- **SOQL datetime canonicalization**: Salesforce emits `+0000` offsets, which SOQL literal
  grammar rejects; the previous pass-through made watermarked queries MALFORMED_QUERY. One
  canonical UTC ISO form now.
- **Request timeout default 30s → 120s**, matching Salesforce's own server-side query timeout
  (`RequestTimeoutMs` still overrides per connection).
