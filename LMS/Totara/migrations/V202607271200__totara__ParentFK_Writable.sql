-- Totara parent-scoped `courseid` must be WRITABLE so the sync can persist it.
--
-- Totara's parent-iteration fetch injects the parent FK `courseid` into each child record of the
-- parent-scoped objects. Those fields were seeded IsReadOnly = 1. CodeGen omits read-only fields from
-- the generated create/update stored procedures, so `@courseid` was never a sproc parameter and every
-- save failed with:
--     @courseid is not a parameter for procedure spCreateCourse_Contents
-- Net effect: 0 rows persisted despite a fully successful fetch from the tenant.
--
-- Safe by construction: Totara is a read-only PULL connector, so `courseid` is written INTO MJ and is
-- never sent back to the vendor. Read scope is unchanged — this only makes the injected parent FK a
-- write column.
--
-- Delta migration (not a re-seed): the catalog rows already exist on installed tenants, so this UPDATEs
-- them in place. No IDs are minted and no rows are created, so nothing can collide with the
-- V202607201219 seed or re-mint an applied UUID. Idempotent by WHERE.
--
-- NOTE: the Integration row is named 'totara' (lowercase) — matching the seeded identity exactly.
-- Do not "correct" the casing here; that is a separate, deliberate change.

UPDATE [__mj].IntegrationObjectField
SET IsReadOnly = 0
WHERE Name = 'courseid'
  AND IsReadOnly = 1
  AND IntegrationObjectID IN (
      SELECT o.ID
      FROM [__mj].IntegrationObject o
      INNER JOIN [__mj].Integration i ON i.ID = o.IntegrationID
      WHERE i.Name = 'totara'
        AND o.Name IN (
            'Course Enrolment Methods',
            'Grade Items',
            'Course Grades Overview',
            'User Badges'
        )
  );
