# @memberjunction/connector-orcid

## 1.3.0

### Minor Changes

- af7f48c: One ORCID call per person, sections derived from the stored record and flattened into real columns.

  Ported from a production consumer that subclasses `ORCIDConnector` over a ~38k-iD universe, whose earlier findings became 1.1.3 and 1.2.0. What was still only in that subclass comes into stock here, so it can drop its overrides and new deployments start on the stock connector.

  **One call per person.** Each section object (works, employments, fundings, …) issued its own `GET /{iD}/<section>` per person: 12 calls per member, and at ORCID's ~10 req/s a 50k-member association was a multi-day initial load. `GET /{iD}/record` already carries every section summary under `activities-summary` and `person`. Now only the `record` object calls ORCID; it stores `activities-summary` (new json field) beside the existing `person`, and every section object is derived by reading the page's stored records back — one local query per page, by the column the connection maps `orcid-id` to (an engine-built table's own key), no API call. If the stored records can't be read at all (no active `record` mapping, `orcid-id` unmapped, a failed query), the section still completes by fetching live, and the real cause is reported once per scan as `RECORD_READBACK_FAILED`. The record object is the FK parent of every section, so the engine's dependency ordering syncs it first. "Stored" is judged per section: a row must carry the block the section lives in (`activities-summary` for works, employments, fundings, …; `person` for the person sections). An iD without it — no stored record, a row synced before `activities-summary` existed, the unrefreshed tail of an interrupted re-sync — is fetched live and reported as `RECORD_FALLBACK_FETCH`, so a section is never silently empty. Live fetches are capped per section page at the root page's size, so a page keeps the same time budget; the rest roll to the next page. The first 100 records fetched that way are kept for the rest of the run so later sections reuse them rather than refetching.

  **An unread iD now fails the end of its object's scan.** A per-iD failure was, and still is, isolated into an `ID_FETCH_FAILED` warning so one bad iD can't stall a page. But the engine only treats a fetch as incomplete when `FetchChanges` throws: on a full sync, warnings alone left it "clean", so delete detection archived or deleted the unread iD's existing rows and the watermark advanced past its updates. A scan that left any iD unread now returns every page as before, then fails one final empty call. The engine keeps the watermark and skips delete detection for that object, and the iD is read again next run. The fetch error appears in the run's log and progress stream (the run itself can still finish as Success); the warnings name the iDs.

  **Records ORCID will never serve are not failures.** Per ORCID's own exception mapping, a locked or deactivated account answers 409 and a merged one 301 to the surviving iD. These never change on retry, so they no longer count as unread (which would hold every scan open, run after run): 409/410/3xx are treated like a 404 — nothing to sync, existing rows are deleted on a full sync — and reported once per run as `ID_UNAVAILABLE` with the reason, naming the surviving iD for a merge so the source list can be updated. Redirects are no longer followed: following one stored the surviving account's record under the old iD, and with both iDs in scope two people claimed the same works.

  **Concurrent, rate-governed root pages.** The root page is fetched across `ctx.MaxConcurrency` workers, each request gated by the engine's `RateLimitAcquire` and reported back through `RateLimitReport`, so throughput reaches the rate ceiling instead of the sequential-latency floor (~0.7 req/s at ORCID's ~1.4s latency). The root page is 10 iDs regardless of `BatchSize`: every `FetchChanges` call must finish inside the engine's 30s limit even after the rate limiter has backed off. A derived page carries 100 iDs. Both grow with the universe only as far as needed to keep the scan under 4,000 pages, because the engine stops an object after 5,000 pages and the next run starts the scan again from the top — a fixed 10-iD page could never read past the 50,000th iD. The root page tops out at 50 (200,000 iDs); a larger universe is reported as `UNIVERSE_EXCEEDS_RUN`. A search-scoped universe is resolved once per run rather than once per page.

  **Flattened fields.** Section items arrived with ORCID's nesting intact, so `title`, `organization`, `start-date` and the `{value}` wrappers landed as JSON in their columns. Every section now also carries flat fields: the asserting source (`source-name`, `source-orcid`), organization (`organization-name`, `-city`, `-region`, `-country`, `-disambiguated-id`, `-disambiguation-source`), partial dates as integer parts (`start-`/`end-`/`publication-`/`completion-year`/`-month`/`-day`), titles (`work-title`, `work-subtitle`, `funding-title`, `translated-title`, `resource-title`), funding `amount-value`/`amount-currency`, and the peer-review subject. Top-level `{value}` wrappers are unwrapped in place, so declared String columns such as `journal-title` and `review-url` receive the string. The nested json fields are unchanged; nothing the API returns is dropped. Funding `amount` exists only on ORCID's per-item detail endpoint, so it is null on a derived item.

  **Six person-section objects.** `other-names`, `keywords`, `email`, `address`, `researcher-urls`, `external-identifiers` (Scopus Author ID, ResearcherID, …), each keyed by `put-code` with an `orcid-id` FK to `record`, derived from the stored record's `person` block. 12 objects become 18.

  **Upgrading an existing connection.** Its record rows hold `person` but not `activities-summary`, so until they are refreshed every activity section is read live (the old per-person cost, with a `RECORD_FALLBACK_FETCH` warning per page) rather than from storage. Before the first sync on 1.3.0: map the record object's new `activities-summary` field (and the six new objects, if wanted), then run the `record` object once on its own. After that the sections read from storage. Skipping these steps is safe, just slow.

  Ships as `V202610182210__orcid__SingleRecordFetchAndFlattenedFields` (+ its Postgres twin): 6 new objects, 221 new fields, and the 12 existing objects' Configuration notes updated to describe the derived fetch model. Additive only; no existing row is removed or renamed.

  Storage note: the record row now holds the full `activities-summary` block, and the engine's snapshot column holds the mapped fields again, so a prolific author's record row can reach several hundred KB. The consumer above saw its database roughly double over ~40k records; size the database for it.

## 1.2.2

### Patch Changes

- 06b2b4b: Allow MemberJunction 6.x as a peer. Every connector capped its `@memberjunction/*` peers at `<6.0.0`; the ceiling moves to `<7.0.0`, and `mj-app.json.mjVersionRange` moves with it so npm and `mjdev app register` agree. Floors are unchanged, so 5.x hosts are unaffected.

  Why the ceiling is the fix on a 6.x host: pnpm's `auto-install-peers` satisfies an unmet peer range by installing a **second** copy of `@memberjunction/core`, and two copies of core in one process is the failure that surfaces as thousands of unrelated-looking type errors. Business Central hit exactly this and was widened alone (#180, then #208 for the manifest); this brings the other 56 connectors, the two private platform packages, and the shared `connector-id-window-scan` package to the same range, so the duplicate cannot return transitively through a shared dependency either. The scaffolding scripts (`new-connector`, `scaffold-openapps`, `split-into-packages`) now mint `<7.0.0` too, so a new connector does not reintroduce the cap.

  Verified at compile time, not at runtime: all 61 packages in the repo (57 connectors, the two private platform packages, the two shared packages) type-check against `@memberjunction/*@6.1.0-edge.5` — the only 6.x published at the time; there is no stable 6.x yet — with every framework `.d.ts` resolved from the 6.x install and none from 5.x. That check is `npm run check:mj-compat` (`scripts/typecheck-against-mj.mjs`), added with this change so the claim can be re-run against any MJ version. It is API compatibility at the type level; the only runtime evidence on a 6.x host remains the Business Central team's edge deployment.

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
