# @memberjunction/connector-cvent

## 1.1.0

### Minor Changes

- cda2822: Fix the PostgreSQL seed migration so `mj app install` succeeds on PostgreSQL.

  Cvent's 1.0.0 PostgreSQL migration (`V202606280836__cvent__Metadata.pg.sql`) was generated with a stale SS→PG converter (CLI 5.36, which predates the boolean SP-argument coercion shipped in 5.40.x). It emitted the integration-catalog `spCreate*` calls with integer `_Clear` flags (`p_<col>_Clear := 1`) against `BOOLEAN` parameters (2371 occurrences across 179 objects + 2191 fields). PostgreSQL resolves function overloads by exact argument type and has no implicit `integer → boolean` cast for a named argument, so the install aborted with:

  ```
  ERROR: function __mj.spCreateIntegrationObject(... p_<col>_clear => integer ...) does not exist
  ```

  Regenerated the `.pg.sql` in place (same migration version) with CLI 5.43.0, which emits native `:= TRUE`/`:= FALSE` and also corrects the 5.36 identifier-quoting defect (`."Configuration"`) in seeded string literals. Verified: applies clean on PostgreSQL (179 IOs + 2191 IOF calls, `ON_ERROR_STOP=1`, 0 errors). The SQL Server migration is unchanged.
