# @memberjunction/connector-hubspot

## 1.1.3

### Patch Changes

- 6ee916d: Relicense to the Business Source License 1.1.

  Metadata and documentation only: the `license` field moves to `BUSL-1.1` and the
  repo gains a LICENSE file. No runtime behaviour, API surface, or dependency
  changes. The bump exists so the new licence metadata reaches npm, since the
  registry shows the licence of the latest published version.

## 1.1.2

### Patch Changes

- 517466f: Fix silent record loss in NetForum + ORCID pagination, and declare the missing `connector-schema-merge` runtime dependency in HubSpot + Totara.

  **NetForum**: `FetchChanges` requested `@TOP -1` (the entire result set in one SOAP call) and hardcoded `HasMore: false`, so `BatchSize` was ignored and the computed `NextAfterKeyValue` was discarded. Now issues a `@TOP <BatchSize>` window with an `ORDER BY` on the stable ordering key, applies a `> AfterKeyValue` keyset predicate on resume, and reports `HasMore` from the page fill. Objects with no ordering key can't be paged safely, so they keep the single-call behavior and now emit an `UNPAGINATED_FETCH` warning instead of failing silently. `NewWatermarkValue` advances only on the final page.

  **ORCID**: `ResolveOrcidIdUniverse` sliced the resolved iD universe to `BatchSize` and returned `HasMore: false` — every iD past the first page was permanently discarded on every sync. The universe is now returned whole and sorted, windowed by `AfterKeyValue`, with `HasMore` + `NextAfterKeyValue` set so the scan completes across pages. Watermark advances only on the last page.

  **HubSpot / Totara**: both `import` `@memberjunction/connector-schema-merge` at runtime but declared it under `devDependencies`, which does not ship to consumers — the same `ERR_MODULE_NOT_FOUND` shape that leaves HubSpot broken on npm at 1.1.1. Moved to `dependencies`.

- 663676d: Fix two silent 0-row sync defects, each shipped with the paired dialect migration that carries the fix to installed tenants.

  **HubSpot — primary key is `hs_object_id`, not `id` (33 CRM objects).** The catalog declared `id` as the PK, but `DiscoverFields` declares — and the sync path populates — `hs_object_id`, read out of the properties bag. The top-level `id` column is never written. With `id` as the PK the generated `spCreate` ends with a read-back `SELECT ... WHERE [id] = @id`; `@id` is NULL, and in SQL `x = NULL` is never true, so the read-back matched zero rows, the create was treated as failed (`Error creating new record, no rows returned from SQL`), and every one of the 33 objects synced **0 rows — silently**, with no meaningful error surfaced.

  **Totara — parent-scoped `courseid` must be writable.** The parent-iteration fetch injects the parent FK `courseid` into each child record of the parent-scoped objects (Course Enrolment Methods, Grade Items, Course Grades Overview, User Badges), but those fields were seeded `IsReadOnly: true`. CodeGen omits read-only fields from the generated create/update stored procedures, so `@courseid` was never a sproc parameter and every save failed with `@courseid is not a parameter for procedure spCreateCourse_Contents` — **0 rows persisted despite a fully successful fetch**. Safe by construction: Totara is a read-only _pull_ connector, so `courseid` is written into MJ and never sent to the vendor.

  Both ship as **delta migrations, not re-seeds**: the existing seeds stay untouched and applied, so no applied UUID is re-minted, no applied migration is deleted, and there is no Flyway checksum break or `UQ_IntegrationObject_Name` collision on tenants already running these connectors. HubSpot's delta creates the 33 missing `hs_object_id` catalog rows (with stable UUID5-derived IDs, so the migration is reproducible byte-for-byte) and clears `IsPrimaryKey` on each object's `id`; Totara's is a guarded in-place `UPDATE`. Both have verified PostgreSQL twins.

## 1.1.1

### Patch Changes

- 24f62b1: ClassName now follows the catalog convention (== npm package name) so instance discovery matches and the catalog card flips to installed; legacy 'HubSpotConnector' key stays registered and a delta migration fixes existing tenants' Integration rows.

## 1.1.0

### Minor Changes

- 37cfe35: Sample-union discovery for describe-endpoint connectors: each connector wires MJ's existing `DiscoverFieldsViaFetch` sampler into its declared catalog inside `IntrospectSchema`, unioned per object via the shared pure helper `mergeDeclaredWithSampledFields` — real widths and MJ-discovered custom columns land before the first sync (no `nvarchar(255)` overflow / `STRING_OVERFLOW_SKIPPED`). Connectors with no `IntrospectSchema` of their own get the standard `super.IntrospectSchema → sample → merge → return` override; connectors that already own an `IntrospectSchema` (HubSpot, Salesforce, Nimble AMS, YourMembership) are WRAPPED — their existing logic/caching is preserved and the union runs on the built result before return (Fonteva inherits it via Salesforce's `super`).

  The width rule is NEVER-SHRINK: `MaxLength = max(declared, measured)`. It only ever widens, so connectors that already carry real declared widths from their describe API (Salesforce/Fonteva) are never truncated below the real width, while connectors whose declared catalog has no width still adopt MJ's measured value. Connectors add no discovery/merge/sync logic of their own; MJ owns measurement, type/PK inference, persistence and reconcile. `DiscoverFields` is unchanged (no recursion). Schema-less / already-streaming connectors (PropFuel, FileFeed, RelationalDB, MJtoMJ, ORCID) are unaffected.
