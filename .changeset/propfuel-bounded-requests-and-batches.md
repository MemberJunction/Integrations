---
"@memberjunction/connector-propfuel": patch
---

Bound two unbounded paths in the PropFuel connector.

Every request now carries an `AbortSignal` deadline (default 60s, generous because the download path
transfers a whole export file). `requestTimeoutMs: 0` in Configuration opts out of the default
deadline but not out of ending — it falls back to a 10-minute absolute ceiling. Previously
`MakeHTTPRequest` called bare `fetch` with no signal, so a source that accepted the connection and
then never answered hung the caller forever; because discovery runs inside the connector-creation
pipeline, whose in-flight slot is released only when the stage settles, one hung request left the
connector unrefreshable until the API process restarted.

`FetchChanges` no longer treats an absent `BatchSize` as "download the entire retained backlog for
this data type into memory in one call". It applies a 50,000-record default limit plus a 250-file
per-call cap (the record count is only checked between files, so an unexpectedly large file could
otherwise overshoot it). Both caps are resumable rather than lossy: `HasMore` and the microtime
cursor bring the engine straight back for the remainder.
