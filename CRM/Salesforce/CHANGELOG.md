# @memberjunction/connector-salesforce

## 1.3.2

### Patch Changes

- 5ca7755: Nimble AMS extends the Salesforce base connector instead of duplicating its Salesforce layer.

  Nimble carried its own copy of the SOQL stack, which is how the hardening ladder proven on a
  customer org existed in exactly one of the three Salesforce-platform connectors while Fonteva
  and the base still had the defects. The duplicate is gone: `NimbleAMSConnector` now extends
  `SalesforceConnector` and deletes ~230 lines of copied machinery (`FetchSOQL`, `BuildSOQL`,
  `FormatSOQLDateTime`, `ResolveWatermarkField`, `ChunkSOQLFields`, `MergeChunkedRecords`).

  What Nimble keeps is what is actually Nimble: the Fuse inbound/outbound doors, the LMS REST
  family, `NU__`/`NUINT__` namespace scoping, its own OAuth token flow, and the literal-create
  body shapes. Its `FetchChanges` routes those families itself and delegates the default door to
  the base.

  Moved INTO the base with this change (so Fonteva and every future Salesforce connector inherit
  them, not just Nimble):

  - **Chunked wide projections** — Salesforce's REST edge 431s an over-long request line; a
    674-field object failed batch 1 of every run. Wide projections split into aligned chunks
    (pinned to the one page size Salesforce honors exactly) and reassemble by Id; misalignment
    throws rather than writing half-populated rows.
  - **Declared-watermark honoring** — an explicit `IncrementalWatermarkField` now wins over the
    audit-column preference, so objects that expose only `CreatedDate` stop 400-ing.

  The SOQL-mechanics test coverage moved with the code: 11 cases now live in the base's suite
  (construction, declared-watermark precedence, per-page watermark advance, chunk splitting,
  aligned reassembly, misalignment throw, chunked-cursor round-trip) — base 59/59, Nimble 24/24,
  Fonteva 62/62 unchanged.

- 8f4efad: Bulk API 2.0 as a fetch transport, and two hardening fixes ported from the Nimble campaign.

  - **Bulk query fetch transport** (opt-in per object: `Configuration.FetchTransport =
"bulk_query"`, or `DefaultQueryParams.fetch_transport` as a fallback): backfills route through a Bulk API 2.0 query job — Salesforce materializes
    the export server-side and the connector downloads CSV pages via `Sforce-Locator`, so the
    serial REST cursor (seconds per page on wide objects) disappears from the big first pull.
    The query is stripped of ORDER BY, which Bulk 2.0 accepts but which disables PK Chunking
    (Salesforce's own remedy for bulk-query timeouts is to remove it).
    The cursor carries the whole job identity (`bulkq:{id, object, locator}`): mid-job restarts
    re-poll the same job, mid-download restarts resume at the locator. Failed/aborted jobs throw
    with the vendor errorMessage; a job created without an id throws rather than losing the job.
    Incremental trickle (a watermark exists) stays on the REST path where per-page watermark
    advance already works. Applies to every Salesforce-platform connector that extends this
    class (Fonteva today; Nimble AMS after its rebase).
  - **SOQL datetime canonicalization**: Salesforce emits `+0000` offsets, which SOQL literal
    grammar rejects; the previous pass-through made watermarked queries MALFORMED_QUERY. One
    canonical UTC ISO form now.
  - **Request timeout default 30s → 120s**, matching Salesforce's own server-side query timeout
    (`RequestTimeoutMs` still overrides per connection).

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
