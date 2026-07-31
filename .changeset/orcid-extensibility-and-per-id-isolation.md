---
'@memberjunction/connector-orcid': minor
---

ORCID: per-iD failure isolation, extensible internals, and a realistic concurrency ceiling.

Reported from a production consumer that subclasses `ORCIDConnector` over a ~38k-iD universe.

**Per-iD failure isolation.** `FetchChanges` fanned out over the resolved iD universe with no
per-iD error handling, so one bad iD (persistent 5xx, malformed record) threw and killed the whole
page. This got sharper when the connector moved to keyset pagination in 1.1.3: the engine can only
step past a failed page for offset/page pagination (`canSkipPage`), so a throw here stalls the scan
at that iD on *every* subsequent run — permanently. Each iD is now isolated; a failure emits an
`ID_FETCH_FAILED` warning naming the iD and the scan continues. 403/404 remain normal empties.

Because a swallowed failure looks like a clean fetch to the engine, the connector now **holds the
watermark** whenever any iD was skipped — otherwise the skipped iD's updates fall below the newly
advanced watermark and are never re-fetched. Holding costs one re-fetch next run, which content-hash
idempotency dedups, and lets the failed iD self-heal.

**Extensible internals.** `FetchForId`, `expandSection`, `ResolveOrcidIdUniverse`, `toRecord`,
`extractLastModifiedMs` and `parseWatermark` are now `protected` instead of `private`. They are
exactly the primitives a subclass needs to build a derived or differently-scoped fetch, and
consumers were reaching them through `as unknown as` casts that break on every upstream release.

**Concurrency ceiling.** Added `MaxConcurrencyHint = 16`. At the engine's default of 4 in-flight and
ORCID's ~1.4s typical latency, throughput capped near 3 req/s — well under the ~10 req/s the
connector's own `RateLimitPolicy` already permits, leaving the sync latency-bound rather than
rate-bound. This is a ceiling the adaptive controller ramps toward, not a floor; it still cuts on
429/503.

Minor rather than patch: widening `private` to `protected` enlarges the public API surface.
