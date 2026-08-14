---
"@memberjunction/connector-business-central": minor
---

Batch writes for Business Central via OData `$batch`.

The connector inherited the framework's default batch implementation, which loops single-record
`CreateRecord` — and Business Central serializes every write through a paced chain, so each record
costs a round trip plus a pacing sleep. A 60-line journal batch was 60 requests and 60 sleeps. It is
now one request.

Constraints taken from Microsoft's contract rather than inferred:

- **100 operations per envelope**, the documented ceiling. Larger inputs are chunked, so a 250-line
  journal is three envelopes rather than an error.
- **Responses are matched by `id`, never by position.** Response order is not guaranteed to mirror
  request order; matching positionally would attribute one record's created ID to a different record.
- **Partial success is normal.** Each sub-response carries its own status, so results are built per
  record using the same ID extraction and error classification as the single-record path.
- **A missing sub-response fails that record loudly** rather than defaulting to success — a silently
  dropped create becomes a duplicate on the next sync.

Falls back to the sequential path where batching cannot apply: a single record, the `odatav4` surface
(published pages do not share the API's batch grammar), or a mixed set of CompanyIntegrations or
objects, since one envelope is scoped to a single tenant and entity set.
