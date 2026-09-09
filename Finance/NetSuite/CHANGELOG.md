# @memberjunction/connector-netsuite

## 1.4.2

### Patch Changes

- f620c10: Read a 401 on an already-served connection as a concurrency throttle instead of an auth failure.

  NetSuite governs by concurrent requests per account, and past the grant it does not always answer 429. Under 8 concurrent fetches it intermittently answered HTTP 401 "Invalid login attempt" mid-walk, on objects whose earlier pages had just succeeded with the same token. Classified as a persistent auth error the page was skipped, the object finished INCOMPLETE, and roughly 58s of retry budget went with each hit — 41 stalls of 10s or more summed 19.9 minutes of one 59.8-minute run.

  The connector now treats a 401 as congestion only once this process has watched NetSuite serve a 2xx for that connection (auth mode + account): it backs off like a 429 and reports through `onThrottle`, which is what halves the engine's adaptive fetch gate, so the account's real grant is found rather than guessed. A 401 on the first request of a connection — what a bad or missing credential actually looks like — and any 401 from `TestConnection` stay genuine auth failures, surfaced immediately with no retry. The one case the heuristic can misread, a token revoked mid-run, costs three backoff retries before the same 401 is surfaced unchanged.

  `MaxConcurrencyHint` (5, the smallest documented tier grant) already shipped and is what makes the engine's opt-in fetch gate exist at all; a test now pins the value so the gate cannot be silently removed.

- 8af4156: Declare a 120s per-page fetch budget (`FetchChangesTimeoutMs`) so large SuiteQL tables stop losing pages to the framework's 30s default.

  The engine bounds every `FetchChanges` call with a fixed 30s timeout unless the connector (or the connection's `Configuration.fetchTimeoutMs`) says otherwise. A SuiteQL page on a large NetSuite transaction table routinely takes longer than that under account-level queueing while the request itself is healthy — the connector's own per-request abort is 90s — so the engine cut the page at 30s, retried, cut it again, and the object finished INCOMPLETE with pages skipped. Every fresh connection ran at that guillotine because the connector declared nothing.

  The connector now declares `FetchChangesTimeoutMs = 120000`. Engine precedence is connection `Configuration.fetchTimeoutMs` → this property → framework default, so a deployment keeps the last word. The property is read duck-typed (the same posture as the `OBJECT_UNAVAILABLE` error code): an engine that predates the per-connector timeout hook ignores it, with no behaviour change there.

- 84a39ff: Retire the four declared objects whose `suiteQLTable` NetSuite rejects outright.

  The Declared catalog was authored by camel-collapsing NetSuite's UI labels into record-type slugs. For most of the 200+ standard types the collapse lands on the real record-type id; for four it does not, and `FetchChanges` runs `SELECT * FROM <slug>` through SuiteQL, so the read fails on every account, on every run, with HTTP 400 `Invalid search type: <slug>` (`INVALID_PARAMETER`). Requisition (real id `purchaserequisition`), Weekly Timesheet (`timesheet`), Bin Putaway Worksheet (`binworksheet`) and Advanced Intercompany Journal Entry (`advintercompanyjournalentry`) could never sync, yet each shipped Active, was auto-mapped, and spent a request, an error and a retry ladder every run.

  They are now `Status='Disabled'` in the metadata and in a new delta migration (SQL Server + Postgres) keyed by the seeded row IDs — nothing is deleted, no ID is re-minted, and the released seed is untouched, so no Flyway checksum breaks. They are not remapped either: `DiscoverObjects` unions the Declared floor with the account's live metadata-catalog and passes unknown slugs through verbatim, so tenants already surface the real record type as its own object, and a remap would put two objects over one table.

  Objects that fail with `Record 'x' was not found` are explicitly out of scope: that record type is real and merely not provisioned for the account (already reported as `OBJECT_UNAVAILABLE`), and it syncs as soon as the feature is enabled. A catalog test pins the metadata and both migration dialects to exactly these four rows.

## 1.4.1

### Patch Changes

- 6f5c1cd: NetSuite watermarks actually advance, and an absent record type is reported as such.

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

## 1.4.0

### Minor Changes

- 1fd09c3: Keyset (seek) paging, throttle surfacing, and concurrency-tier alignment for SuiteQL reads.

  - **Keyset paging replaces OFFSET.** `?offset=N` makes NetSuite re-evaluate and skip N rows on every page, so a full walk costs O(n²) and each page is slower than the last. Reads now seek — `WHERE id > <last seen> ORDER BY id` — so every page reads only frontier rows at constant cost. `id` is unique, so page boundaries are exact (no skips or repeats, which a timestamp ordering cannot promise). The position is returned as `NextAfterKeyValue` (the engine persists it — durable resume across restarts, which previously never happened because no position was returned by either route) and `NextCursor` (arms the engine's prefetch pipelining). Non-numeric seek keys are rejected before reaching the SQL (injection guard) and fall back to an unseeked page.
  - **Absorbed 429s now reach the engine.** The internal retry made a 429 invisible — the fetch ultimately "succeeded" — so the engine kept firing at a rate the account had just rejected. Each 429 is now surfaced via `ctx.RateLimitReport` (with the server's `Retry-After` in the shape `ExtractRetryAfterMs` parses) before the connector backs off, so the engine's adaptive concurrency cap converges on the account's real grant. Transient 5xx retries do not report.
  - **`MaxConcurrencyHint` is now 5** — the smallest documented tier's actual grant, rather than sitting under it; the engine's adaptive gate handles accounts whose real grant is lower.
  - **Default SuiteQL `limit` is now 100** (per-object/config overrides unchanged): matches the page sizes NetSuite actually serves for many object types, and keeps each request short so concurrency slots recycle quickly on this concurrency-governed API.

## 1.3.2

### Patch Changes

- 88143ae: NetSuite auth failures now carry the server's own diagnosis, and mode inference cannot be hijacked by leftover OAuth2 keys.

  - 401/403 messages (TestConnection, metadata-catalog) include the `WWW-Authenticate` header and `o:errorDetails` — the parts that name token_rejected vs invalid_signature vs timestamp_refused. Previously the reason was discarded and operators saw a bare "HTTP 401".
  - `ResolveAuthMode` now prefers a COMPLETE TBA credential set (ConsumerKey+ConsumerSecret+TokenID+TokenSecret) over leftover BearerToken/AccessToken/RefreshToken fragments when no explicit AuthFlow is set. A stale OAuth2 key from an earlier attempt silently flipped the mode and 401'd every request while four valid TBA secrets sat unused. Explicit AuthFlow still always wins.

## 1.3.1

### Patch Changes

- 6ee916d: Relicense to the Business Source License 1.1.

  Metadata and documentation only: the `license` field moves to `BUSL-1.1` and the
  repo gains a LICENSE file. No runtime behaviour, API surface, or dependency
  changes. The bump exists so the new licence metadata reaches npm, since the
  registry shows the licence of the latest published version.

## 1.3.0

### Minor Changes

- 37cfe35: Sample-union discovery for describe-endpoint connectors: each connector wires MJ's existing `DiscoverFieldsViaFetch` sampler into its declared catalog inside `IntrospectSchema`, unioned per object via the shared pure helper `mergeDeclaredWithSampledFields` — real widths and MJ-discovered custom columns land before the first sync (no `nvarchar(255)` overflow / `STRING_OVERFLOW_SKIPPED`). Connectors with no `IntrospectSchema` of their own get the standard `super.IntrospectSchema → sample → merge → return` override; connectors that already own an `IntrospectSchema` (HubSpot, Salesforce, Nimble AMS, YourMembership) are WRAPPED — their existing logic/caching is preserved and the union runs on the built result before return (Fonteva inherits it via Salesforce's `super`).

  The width rule is NEVER-SHRINK: `MaxLength = max(declared, measured)`. It only ever widens, so connectors that already carry real declared widths from their describe API (Salesforce/Fonteva) are never truncated below the real width, while connectors whose declared catalog has no width still adopt MJ's measured value. Connectors add no discovery/merge/sync logic of their own; MJ owns measurement, type/PK inference, persistence and reconcile. `DiscoverFields` is unchanged (no recursion). Schema-less / already-streaming connectors (PropFuel, FileFeed, RelationalDB, MJtoMJ, ORCID) are unaffected.

## 1.2.1

### Patch Changes

- 59c047c: Declare semantic lengths for url-class string fields (255 default → 2048). Oversize values are skipped, not truncated — silent record loss risk.

## 1.2.0

### Minor Changes

- 991a336: Fix the seed migration so `mj app install` succeeds — the migration now creates the connector's CredentialType **before** the Integration.

  These connectors define their own `MJ: Credential Types` row (e.g. `PropFuel API`, `GrowthZone OAuth2`, `Salesforce JWT Bearer`) and their `Integration` row references it via `CredentialTypeID`. The published migration seeded the `Integration` but **never created the CredentialType**, so every fresh install aborted at the migration step (which runs before any metadata sync) with:

  ```
  The INSERT statement conflicted with the FOREIGN KEY constraint "FK_Integration_CredentialType" (SQL Server)
  function __mj.spCreateIntegration(...) — FK_Integration_CredentialType (PostgreSQL)
  ```

  Root cause was in the seed-migration generator: it reset the `Integration`/`IntegrationObject`/`IntegrationObjectField` catalog between connectors but **left CredentialType rows in the generation DB**, so `mj sync push`'s SQL-logging saw the type already present and emitted no `spCreateCredentialType` call. Fixed the generator to also delete each connector's own CredentialType before its push, so the create is re-emitted; the existing `directoryOrder` (credential-type before integration) places it ahead of the Integration in the migration.

  Verified: each connector's regenerated migration applies cleanly against a real `__mj` schema (real `FK_Integration_CredentialType` + `spCreate*` functions) — CredentialType created, then Integration, then objects, 0 errors. Both SQL Server and PostgreSQL migrations regenerated; same migration version (in place).

  Connectors that reference a **core** credential type (`OAuth2 Client Credentials`, `Azure Service Principal`, `API Key`, `OAuth2 Password Grant`) are unaffected and unchanged — those types exist on every fresh instance.

  The `spCreateCredentialType` call is also guarded with `IF NOT EXISTS` (both dialects), so installing two connectors that share a credential type (Fonteva and Salesforce both use `Salesforce JWT Bearer`) on the same instance no longer collides — the second install skips the already-created type. Verified: Salesforce-then-Fonteva on one instance, both Integrations created, 0 errors.

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
