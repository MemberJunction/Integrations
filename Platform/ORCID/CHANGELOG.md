# @memberjunction/connector-orcid

## 1.2.1

### Patch Changes

- 6ee916d: Relicense to the Business Source License 1.1.

  Metadata and documentation only: the `license` field moves to `BUSL-1.1` and the
  repo gains a LICENSE file. No runtime behaviour, API surface, or dependency
  changes. The bump exists so the new licence metadata reaches npm, since the
  registry shows the licence of the latest published version.

## 1.2.0

### Minor Changes

- e0ceae8: ORCID: anonymous Public API access, per-iD failure isolation, extensible internals, and a realistic
  concurrency ceiling.

  Reported from a production consumer that subclasses `ORCIDConnector` over a ~38k-iD universe.

  **Anonymous Public API access.** The ORCID Public API serves public records with no token, but the
  connector threw unless a `client_credentials` pair was configured — so it could not be used out of
  the box. A connection that supplies _no_ credential now skips the OAuth grant entirely and sends no
  `Authorization` header. Supplying only one half of the pair is still a hard error: half a credential
  can only be a misconfiguration, and silently degrading it to anonymous would hide the real problem
  behind a sync that quietly returns public-only data. `TestConnection` reports which mode ran, and a
  401 in anonymous mode no longer triggers a pointless token refresh + retry cycle.

  **Per-iD failure isolation.** `FetchChanges` fanned out over the resolved iD universe with no
  per-iD error handling, so one bad iD (persistent 5xx, malformed record) threw and killed the whole
  page. This got sharper when the connector moved to keyset pagination in 1.1.3: the engine can only
  step past a failed page for offset/page pagination (`canSkipPage`), so a throw here stalls the scan
  at that iD on _every_ subsequent run — permanently. Each iD is now isolated; a failure emits an
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

## 1.1.3

### Patch Changes

- 517466f: Fix silent record loss in NetForum + ORCID pagination, and declare the missing `connector-schema-merge` runtime dependency in HubSpot + Totara.

  **NetForum**: `FetchChanges` requested `@TOP -1` (the entire result set in one SOAP call) and hardcoded `HasMore: false`, so `BatchSize` was ignored and the computed `NextAfterKeyValue` was discarded. Now issues a `@TOP <BatchSize>` window with an `ORDER BY` on the stable ordering key, applies a `> AfterKeyValue` keyset predicate on resume, and reports `HasMore` from the page fill. Objects with no ordering key can't be paged safely, so they keep the single-call behavior and now emit an `UNPAGINATED_FETCH` warning instead of failing silently. `NewWatermarkValue` advances only on the final page.

  **ORCID**: `ResolveOrcidIdUniverse` sliced the resolved iD universe to `BatchSize` and returned `HasMore: false` — every iD past the first page was permanently discarded on every sync. The universe is now returned whole and sorted, windowed by `AfterKeyValue`, with `HasMore` + `NextAfterKeyValue` set so the scan completes across pages. Watermark advances only on the last page.

  **HubSpot / Totara**: both `import` `@memberjunction/connector-schema-merge` at runtime but declared it under `devDependencies`, which does not ship to consumers — the same `ERR_MODULE_NOT_FOUND` shape that leaves HubSpot broken on npm at 1.1.1. Moved to `dependencies`.

## 1.1.2

### Patch Changes

- dbffddf: Declare semantic lengths for url/email-class string fields (255 default → url 2048, email 320). Oversize values are skipped, not truncated — silent record-loss risk.

## 1.1.1

### Patch Changes

- cc38129: Widen prose string fields (description/notes/bio/summary/…) from the 255 default to 4000. The engine skips-not-truncates oversize values, so every such field was a silent record-skip risk — live repro: PheedLoop Members.about skipped 54 records/sync at 255 vs real 2,595-char values.

## 1.1.0

### Minor Changes

- fe75578: Fix the PostgreSQL seed migration so `mj app install` succeeds on PostgreSQL.

  The 1.0.0 PostgreSQL migration (`migrations-pg/*.pg.sql`) was generated with a stale SS→PG converter (CLI 5.36, which predates the boolean SP-argument coercion shipped in 5.40.x). It emitted the integration-catalog `spCreate*` calls with integer `_Clear` flags (`p_<col>_Clear := 1`) against `BOOLEAN` parameters. Because PostgreSQL resolves function overloads by exact argument type and has no implicit `integer → boolean` cast for a named argument, every such call aborted on apply with:

  ```
  ERROR: function __mj.spCreateIntegrationObject(... p_<col>_clear => integer ...) does not exist
  ```

  Regenerated each `.pg.sql` with CLI 5.43.0, which emits native `:= TRUE`/`:= FALSE`. The same regeneration also corrects a second 5.36 defect: identifier-quoting (`."Configuration"`) leaking into string literals inside seeded descriptions and `Configuration` JSON.

  SQL Server migrations (`migrations/*.sql`) are unchanged — this is a PostgreSQL-only fix.

## 1.0.0

### Major Changes

- 50cb849: Initial release: self-contained Open App shipping its Integration metadata (objects + fields) and credential type. Strict-TypeScript build clean.
