-- Totara: the two writable objects that carried no primary key.
--
-- A writable IntegrationObject with no IsPrimaryKey field yields a KEYLESS derived entity. On
-- Postgres, MJ's save audit-wrapper then emits an empty record identifier and every save fails with
--     syntax error at or near ","
-- while fetch keeps succeeding — so the object reads green and persists nothing.
--
-- Both objects are keyed on the PARENT, because that is the grain the vendor actually returns:
--
-- 1. Cohort Members -> key on `cohortid`.
--    `core_cohort_get_cohort_members` returns one row per COHORT — {cohortid, userids[]} — not one
--    row per member, so the cohort is the record identity. The field already carries the FK to
--    Cohorts.id.
--
-- 2. Group Members -> key on `groupid`.
--    `core_group_get_group_members` returns one row per GROUP — {groupid, userids[]} — same shape.
--    The field is already required and writable and already carries the FK to Groups.id.
--
-- `cohortid` is additionally flipped WRITABLE. CodeGen omits read-only fields from the generated
-- create/update stored procedures, which is exactly the failure V202607271200 fixed for `courseid`
--     (@courseid is not a parameter for procedure spCreateCourse_Contents)
-- and a read-only primary key would reproduce it here. Safe by construction: Totara is a read-only
-- PULL connector, so `cohortid` is written INTO MJ and never sent back to the vendor. `groupid` is
-- already writable and needs no change.
--
-- Delta migration (not a re-seed): the catalog rows already exist on installed tenants, so this
-- UPDATEs them in place. No IDs are minted and no rows are created, so nothing can collide with the
-- V202607201219 seed or re-mint an applied UUID. Idempotent by WHERE.
--
-- NOTE: the Integration row is named 'totara' (lowercase) — matching the seeded identity exactly.

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 1,
    IsUniqueKey  = 1,
    IsRequired   = 1,
    AllowsNull   = 0
WHERE Name = 'cohortid'
  AND IntegrationObjectID IN (
      SELECT o.ID
      FROM [__mj].IntegrationObject o
      INNER JOIN [__mj].Integration i ON i.ID = o.IntegrationID
      WHERE i.Name = 'totara'
        AND o.Name = 'Cohort Members'
  );

UPDATE [__mj].IntegrationObjectField
SET IsReadOnly = 0
WHERE Name = 'cohortid'
  AND IsReadOnly = 1
  AND IntegrationObjectID IN (
      SELECT o.ID
      FROM [__mj].IntegrationObject o
      INNER JOIN [__mj].Integration i ON i.ID = o.IntegrationID
      WHERE i.Name = 'totara'
        AND o.Name = 'Cohort Members'
  );

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 1,
    IsUniqueKey  = 1,
    IsRequired   = 1,
    AllowsNull   = 0
WHERE Name = 'groupid'
  AND IntegrationObjectID IN (
      SELECT o.ID
      FROM [__mj].IntegrationObject o
      INNER JOIN [__mj].Integration i ON i.ID = o.IntegrationID
      WHERE i.Name = 'totara'
        AND o.Name = 'Group Members'
  );
