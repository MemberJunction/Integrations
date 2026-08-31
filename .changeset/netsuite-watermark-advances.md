---
"@memberjunction/connector-netsuite": patch
---

NetSuite watermarks actually advance, and an absent record type is reported as such.

Three defects kept every incremental sync doing a full re-fetch. The change stamp was read from the
record by its DECLARED name, but SuiteQL returns its keys lower-cased, so `lastModifiedDate` matched
nothing and every scan emitted no watermark at all. The value was also computed from the final page
only, which under `ORDER BY id` is not the scan's maximum. And the watermark field itself fell back
to a guessed `lastModifiedDate`, which would have started failing custom tables the moment a
watermark did persist — the same shape as the `ORDER BY` failures keyset paging had to fix.

The change field is now resolved from evidence (the IO's declaration, else the object's own
described columns, else none — and an object with no change field simply has no incremental story,
so it is scanned whole rather than narrowed on a guess). The stamp is read case-insensitively, the
maximum is carried across the whole scan and emitted every page, and it is clamped to when the scan
started so a record edited mid-walk at an already-passed id still falls inside the next run's
window. A stamp that cannot be parsed is never emitted, since the stored value goes straight back
into the next query. The incremental predicate now uses an explicit `TO_DATE` mask instead of
leaning on the account's NLS settings to convert a bare string.

Separately, a SuiteQL `Record 'x' was not found` — a record type the catalog lists but the account
has not enabled — is now thrown with `code: 'OBJECT_UNAVAILABLE'` so the engine can record it once
and stop asking, instead of spending a request, an error and a retry ladder on it every run.
