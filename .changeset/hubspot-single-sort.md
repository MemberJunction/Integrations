---
"@memberjunction/connector-hubspot": patch
---

Send one sort to HubSpot's search API, so incremental sync stops failing with HTTP 400.

`FetchChangesViaSearch` and the archived-record scan both sent `sorts: [dateField, hs_object_id]`. HubSpot's v3 search accepts exactly one sort and answers 400 to any request carrying two, so **every incremental sync failed outright** — only full syncs worked, and schedules had to pass `FullSync: true` to run at all (#424).

Both call sites now sort on the date field alone.

The second sort was not decoration: the >10k keyset re-anchor used `(dateField > anchor) OR (dateField == anchor AND hs_object_id > anchorId)`, which is sound only when results are ordered by `(dateField, hs_object_id)`. That ordering cannot be requested, so within a same-timestamp cluster the order is unspecified, and taking the last row of an unordered cluster as the anchor would skip every other row in it.

The re-anchor is therefore **disabled rather than left to guess**. A scan whose total exceeds the 10,000-record window now takes the existing `stalled` path: it aborts loudly, leaves the watermark un-advanced, and the next sync retries. A visible gap is strictly better than silent loss on the largest objects — and it is no worse than today, where the request 400s before returning anything at all.

Under the cap — which is the ordinary case — `after` paginates one server-side result set, a single sort is sufficient, and incremental sync simply works again.

Restoring >10k support needs a single-sort keyset: sort on `hs_object_id` alone with the date as a pure filter, carrying the running max date in the cursor since id order no longer places the latest date on the last page. That wants verifying against a real portal with a >10k same-timestamp cluster before it ships, so it is not attempted here.
