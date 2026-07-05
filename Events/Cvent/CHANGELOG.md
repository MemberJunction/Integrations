# @memberjunction/connector-cvent

## 1.2.0

### Minor Changes

- 37cfe35: Sample-union discovery for describe-endpoint connectors: each connector wires MJ's existing `DiscoverFieldsViaFetch` sampler into its declared catalog inside `IntrospectSchema`, unioned per object via the shared pure helper `mergeDeclaredWithSampledFields` — real widths and MJ-discovered custom columns land before the first sync (no `nvarchar(255)` overflow / `STRING_OVERFLOW_SKIPPED`). Connectors with no `IntrospectSchema` of their own get the standard `super.IntrospectSchema → sample → merge → return` override; connectors that already own an `IntrospectSchema` (HubSpot, Salesforce, Nimble AMS, YourMembership) are WRAPPED — their existing logic/caching is preserved and the union runs on the built result before return (Fonteva inherits it via Salesforce's `super`).

  The width rule is NEVER-SHRINK: `MaxLength = max(declared, measured)`. It only ever widens, so connectors that already carry real declared widths from their describe API (Salesforce/Fonteva) are never truncated below the real width, while connectors whose declared catalog has no width still adopt MJ's measured value. Connectors add no discovery/merge/sync logic of their own; MJ owns measurement, type/PK inference, persistence and reconcile. `DiscoverFields` is unchanged (no recursion). Schema-less / already-streaming connectors (PropFuel, FileFeed, RelationalDB, MJtoMJ, ORCID) are unaffected.

## 1.1.2

### Patch Changes

- dbffddf: Declare semantic lengths for url/email-class string fields (255 default → url 2048, email 320). Oversize values are skipped, not truncated — silent record-loss risk.

## 1.1.1

### Patch Changes

- cc38129: Widen prose string fields (description/notes/bio/summary/…) from the 255 default to 4000. The engine skips-not-truncates oversize values, so every such field was a silent record-skip risk — live repro: PheedLoop Members.about skipped 54 records/sync at 255 vs real 2,595-char values.

## 1.1.0

### Minor Changes

- cda2822: Fix the PostgreSQL seed migration so `mj app install` succeeds on PostgreSQL.

  Cvent's 1.0.0 PostgreSQL migration (`V202606280836__cvent__Metadata.pg.sql`) was generated with a stale SS→PG converter (CLI 5.36, which predates the boolean SP-argument coercion shipped in 5.40.x). It emitted the integration-catalog `spCreate*` calls with integer `_Clear` flags (`p_<col>_Clear := 1`) against `BOOLEAN` parameters (2371 occurrences across 179 objects + 2191 fields). PostgreSQL resolves function overloads by exact argument type and has no implicit `integer → boolean` cast for a named argument, so the install aborted with:

  ```
  ERROR: function __mj.spCreateIntegrationObject(... p_<col>_clear => integer ...) does not exist
  ```

  Regenerated the `.pg.sql` in place (same migration version) with CLI 5.43.0, which emits native `:= TRUE`/`:= FALSE` and also corrects the 5.36 identifier-quoting defect (`."Configuration"`) in seeded string literals. Verified: applies clean on PostgreSQL (179 IOs + 2191 IOF calls, `ON_ERROR_STOP=1`, 0 errors). The SQL Server migration is unchanged.
