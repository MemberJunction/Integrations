---
'@memberjunction/connector-netsuite': patch
---

Declare a 120s per-page fetch budget (`FetchChangesTimeoutMs`) so large SuiteQL tables stop losing pages to the framework's 30s default.

The engine bounds every `FetchChanges` call with a fixed 30s timeout unless the connector (or the connection's `Configuration.fetchTimeoutMs`) says otherwise. A SuiteQL page on a large NetSuite transaction table routinely takes longer than that under account-level queueing while the request itself is healthy — the connector's own per-request abort is 90s — so the engine cut the page at 30s, retried, cut it again, and the object finished INCOMPLETE with pages skipped. Every fresh connection ran at that guillotine because the connector declared nothing.

The connector now declares `FetchChangesTimeoutMs = 120000`. Engine precedence is connection `Configuration.fetchTimeoutMs` → this property → framework default, so a deployment keeps the last word. The property is read duck-typed (the same posture as the `OBJECT_UNAVAILABLE` error code): an engine that predates the per-connector timeout hook ignores it, with no behaviour change there.
