# @memberjunction/connector-totara

## 0.2.1

### Patch Changes

- 517466f: Fix silent record loss in NetForum + ORCID pagination, and declare the missing `connector-schema-merge` runtime dependency in HubSpot + Totara.

  **NetForum**: `FetchChanges` requested `@TOP -1` (the entire result set in one SOAP call) and hardcoded `HasMore: false`, so `BatchSize` was ignored and the computed `NextAfterKeyValue` was discarded. Now issues a `@TOP <BatchSize>` window with an `ORDER BY` on the stable ordering key, applies a `> AfterKeyValue` keyset predicate on resume, and reports `HasMore` from the page fill. Objects with no ordering key can't be paged safely, so they keep the single-call behavior and now emit an `UNPAGINATED_FETCH` warning instead of failing silently. `NewWatermarkValue` advances only on the final page.

  **ORCID**: `ResolveOrcidIdUniverse` sliced the resolved iD universe to `BatchSize` and returned `HasMore: false` — every iD past the first page was permanently discarded on every sync. The universe is now returned whole and sorted, windowed by `AfterKeyValue`, with `HasMore` + `NextAfterKeyValue` set so the scan completes across pages. Watermark advances only on the last page.

  **HubSpot / Totara**: both `import` `@memberjunction/connector-schema-merge` at runtime but declared it under `devDependencies`, which does not ship to consumers — the same `ERR_MODULE_NOT_FOUND` shape that leaves HubSpot broken on npm at 1.1.1. Moved to `dependencies`.

- 663676d: Fix two silent 0-row sync defects, each shipped with the paired dialect migration that carries the fix to installed tenants.

  **HubSpot — primary key is `hs_object_id`, not `id` (33 CRM objects).** The catalog declared `id` as the PK, but `DiscoverFields` declares — and the sync path populates — `hs_object_id`, read out of the properties bag. The top-level `id` column is never written. With `id` as the PK the generated `spCreate` ends with a read-back `SELECT ... WHERE [id] = @id`; `@id` is NULL, and in SQL `x = NULL` is never true, so the read-back matched zero rows, the create was treated as failed (`Error creating new record, no rows returned from SQL`), and every one of the 33 objects synced **0 rows — silently**, with no meaningful error surfaced.

  **Totara — parent-scoped `courseid` must be writable.** The parent-iteration fetch injects the parent FK `courseid` into each child record of the parent-scoped objects (Course Enrolment Methods, Grade Items, Course Grades Overview, User Badges), but those fields were seeded `IsReadOnly: true`. CodeGen omits read-only fields from the generated create/update stored procedures, so `@courseid` was never a sproc parameter and every save failed with `@courseid is not a parameter for procedure spCreateCourse_Contents` — **0 rows persisted despite a fully successful fetch**. Safe by construction: Totara is a read-only _pull_ connector, so `courseid` is written into MJ and never sent to the vendor.

  Both ship as **delta migrations, not re-seeds**: the existing seeds stay untouched and applied, so no applied UUID is re-minted, no applied migration is deleted, and there is no Flyway checksum break or `UQ_IntegrationObject_Name` collision on tenants already running these connectors. HubSpot's delta creates the 33 missing `hs_object_id` catalog rows (with stable UUID5-derived IDs, so the migration is reproducible byte-for-byte) and clears `IsPrimaryKey` on each object's `id`; Totara's is a guarded in-place `UPDATE`. Both have verified PostgreSQL twins.

- 3b9b36e: Give every writable object a primary key (or withdraw the write it cannot honor).

  A writable `MJ: Integration Object` with no `IsPrimaryKey` field derives a **keyless** entity. On
  Postgres the save audit-wrapper then emits an empty record identifier and every save fails with
  `syntax error at or near ","` — while fetch keeps succeeding, so the object reads green and persists
  nothing. Five objects across these three connectors were in that state.

  Each key is taken from the vendor's own schema, never invented:

  - **Stripe `cash_balance`** → `customer`. Stripe's `CashBalance` schema declares `customer` as a
    property of the object, and the resource is a singleton per customer
    (`/v1/customers/{customer}/cash_balance`, GET + POST only, no collection and no item id). It is
    returned in the payload, so the column is populated rather than null.
  - **Stripe `balance_settings`** → write withdrawn. `BalanceSettings` declares exactly two
    properties, `object` and `payments`; `/v1/balance_settings` takes no path variable because the
    account is implied by the API key. There is nothing to key on, and the object declared no
    create/update/delete operation either — the flag described a capability with no implementation.
    Reads are unaffected.
  - **Totara `Cohort Members`** → `cohortid`. `core_cohort_get_cohort_members` returns one row per
    **cohort** (`{cohortid, userids[]}`), so the cohort is the record identity.
  - **Totara `Group Members`** → `groupid`. `core_group_get_group_members` returns one row per
    **group** (`{groupid, userids[]}`), same shape; the field was already writable.
  - **Eventbrite `Media Upload`** → `upload_token`. Eventbrite's two-step media workflow issues the
    token from `GET /media/upload/` and it identifies the upload for the subsequent POST. It is the
    only identifier in the Media Upload MSON type and it is vendor-issued and returned.

  All three connectors are published, so each ships a **delta** migration (SQL Server + Postgres) that
  UPDATEs the existing catalog rows in place — no IDs minted, no rows created, idempotent by `WHERE`,
  and nothing can collide with an already-applied seed.

## 0.2.0

### Minor Changes

- e8c7693: Totara connector published as an Open App.
