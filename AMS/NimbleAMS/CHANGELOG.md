# @memberjunction/connector-nimble-ams

## 1.3.4

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

- 4c5b32b: Salesforce sync hardening: the five defects that kept a real org from ever finishing a sync.

  - **Chunked SOQL projection** — Salesforce's REST edge rejects an over-long request line with
    HTTP 431 (the URI counts against the header budget), so a wide object (Account: 674 queryable
    fields) failed batch 1 of every run. When the encoded projection exceeds 12,000 chars, the
    SAME row window is fetched as several narrower queries (each always carrying Id + the
    watermark field), pinned to one page size (`Sforce-Query-Options: batchSize=200`) so pages
    stay aligned, and reassembled by Id — misalignment THROWS rather than writing half-populated
    rows. A chunked cursor is the JSON array of per-chunk nextRecordsUrl values; narrow objects
    take the exact single-request path they take today.
  - **Per-page watermark advance** — the watermark only recorded under `done=true`, so an object
    too big to finish one run recorded nothing and restarted from row zero forever (subsumes the
    standalone per-page PR).
  - **Watermark resolution against real fields** + the 120s discovery deadline (subsumes the
    nimble half of the watermark/sampler PR).
  - **`StableOrderingKey` → null** — declaring one made the engine run keyset pagination INSTEAD
    of the watermark filter; every sync re-walked from row zero.
  - **SOQL datetime literals canonicalized** — Salesforce emits offsets without a colon
    (`+0000`); the colon-only test appended a stray `Z` and every watermarked query died with
    MALFORMED_QUERY (HTTP 400). One canonical form now: UTC ISO `Z`.

  All five ran in production for a week as instance patches: the measured result on one org was
  ~250 → ~20,000 rows/min sustained and a 3.87M-row object reaching source parity.

- Updated dependencies [5ca7755]
- Updated dependencies [8f4efad]
  - @memberjunction/connector-salesforce@1.3.2

## 1.3.3

### Patch Changes

- 6ee916d: Relicense to the Business Source License 1.1.

  Metadata and documentation only: the `license` field moves to `BUSL-1.1` and the
  repo gains a LICENSE file. No runtime behaviour, API surface, or dependency
  changes. The bump exists so the new licence metadata reaches npm, since the
  registry shows the licence of the latest published version.

## 1.3.2

### Patch Changes

- 0ae445a: `DiscoverObjects` now throws a diagnosable error instead of silently returning an empty list when
  Salesforce's global describe response doesn't match the Nimble AMS scope (standard objects
  `Account`/`Contact`, or the `NU__`/`NUINT__` managed-package namespace).

  Observed live: a connection whose credentials authenticate fine (`TestConnection` passes) but whose
  Salesforce org does not have the Nimble AMS managed package installed reported "0 tables" with no
  error anywhere — indistinguishable from a genuinely empty source. For an operator who holds only API
  credentials and cannot log into the Salesforce org directly to check Setup → Installed Packages, that
  silence was a dead end.

  Two distinct cases are now surfaced:

  - Salesforce returned object metadata, but none of it matched the Nimble AMS scope — almost always
    means the managed package isn't installed in this org, or the credentials point at the wrong org.
  - Salesforce returned no object metadata at all — a different, more fundamental problem (API version,
    org-wide describe restriction), not a missing-package question.

  No change to matched-object behavior — a normal org with Nimble AMS installed sees identical results.

## 1.3.1

### Patch Changes

- c978def: Nimble AMS — two live-verified sync fixes (0 → 7,221 Contacts synced after the fix).

  - **SOQL fetch was a total blocker.** `BuildSOQL` issued `SELECT FIELDS(ALL)`, which Salesforce rejects unless a `LIMIT ≤ 200` is present — but the connector deliberately omits `LIMIT` so Salesforce's native `nextRecordsUrl` pagination isn't capped. The two requirements are mutually exclusive, so every SOQL object returned HTTP 400 `MALFORMED_QUERY` ("The SOQL FIELDS function must have a LIMIT of at most 200") and synced 0 rows. Replaced `FIELDS(ALL)` with a describe-driven explicit field list (compound `address`/`location` fields excluded — they can't be SELECTed directly, which is why `FIELDS(ALL)` was originally used). An explicit SELECT has no `LIMIT` requirement, so native pagination is preserved and every object now fetches.
  - **client_credentials token host.** The token exchange was posted to `LoginUrl` (default `login.salesforce.com`), which returns `invalid_grant` "request not supported on this domain" — Salesforce's client_credentials flow is only valid against the org's My Domain host. `ObtainToken` now uses the InstanceURL (My Domain) as the token host for the client_credentials grant; the refresh_token grant is unchanged.

## 1.3.0

### Minor Changes

- 37cfe35: Sample-union discovery for describe-endpoint connectors: each connector wires MJ's existing `DiscoverFieldsViaFetch` sampler into its declared catalog inside `IntrospectSchema`, unioned per object via the shared pure helper `mergeDeclaredWithSampledFields` — real widths and MJ-discovered custom columns land before the first sync (no `nvarchar(255)` overflow / `STRING_OVERFLOW_SKIPPED`). Connectors with no `IntrospectSchema` of their own get the standard `super.IntrospectSchema → sample → merge → return` override; connectors that already own an `IntrospectSchema` (HubSpot, Salesforce, Nimble AMS, YourMembership) are WRAPPED — their existing logic/caching is preserved and the union runs on the built result before return (Fonteva inherits it via Salesforce's `super`).

  The width rule is NEVER-SHRINK: `MaxLength = max(declared, measured)`. It only ever widens, so connectors that already carry real declared widths from their describe API (Salesforce/Fonteva) are never truncated below the real width, while connectors whose declared catalog has no width still adopt MJ's measured value. Connectors add no discovery/merge/sync logic of their own; MJ owns measurement, type/PK inference, persistence and reconcile. `DiscoverFields` is unchanged (no recursion). Schema-less / already-streaming connectors (PropFuel, FileFeed, RelationalDB, MJtoMJ, ORCID) are unaffected.

## 1.2.1

### Patch Changes

- cc38129: Widen prose string fields (description/notes/bio/summary/…) from the 255 default to 4000. The engine skips-not-truncates oversize values, so every such field was a silent record-skip risk — live repro: PheedLoop Members.about skipped 54 records/sync at 255 vs real 2,595-char values.

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
