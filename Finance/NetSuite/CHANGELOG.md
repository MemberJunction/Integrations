# @memberjunction/connector-netsuite

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
