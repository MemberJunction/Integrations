---
"@memberjunction/connector-hubspot": patch
"@memberjunction/connector-totara": patch
---

Fix two silent 0-row sync defects, each shipped with the paired dialect migration that carries the fix to installed tenants.

**HubSpot — primary key is `hs_object_id`, not `id` (33 CRM objects).** The catalog declared `id` as the PK, but `DiscoverFields` declares — and the sync path populates — `hs_object_id`, read out of the properties bag. The top-level `id` column is never written. With `id` as the PK the generated `spCreate` ends with a read-back `SELECT ... WHERE [id] = @id`; `@id` is NULL, and in SQL `x = NULL` is never true, so the read-back matched zero rows, the create was treated as failed (`Error creating new record, no rows returned from SQL`), and every one of the 33 objects synced **0 rows — silently**, with no meaningful error surfaced.

**Totara — parent-scoped `courseid` must be writable.** The parent-iteration fetch injects the parent FK `courseid` into each child record of the parent-scoped objects (Course Enrolment Methods, Grade Items, Course Grades Overview, User Badges), but those fields were seeded `IsReadOnly: true`. CodeGen omits read-only fields from the generated create/update stored procedures, so `@courseid` was never a sproc parameter and every save failed with `@courseid is not a parameter for procedure spCreateCourse_Contents` — **0 rows persisted despite a fully successful fetch**. Safe by construction: Totara is a read-only *pull* connector, so `courseid` is written into MJ and never sent to the vendor.

Both ship as **delta migrations, not re-seeds**: the existing seeds stay untouched and applied, so no applied UUID is re-minted, no applied migration is deleted, and there is no Flyway checksum break or `UQ_IntegrationObject_Name` collision on tenants already running these connectors. HubSpot's delta creates the 33 missing `hs_object_id` catalog rows (with stable UUID5-derived IDs, so the migration is reproducible byte-for-byte) and clears `IsPrimaryKey` on each object's `id`; Totara's is a guarded in-place `UPDATE`. Both have verified PostgreSQL twins.
