-- Totara: `Enrolled Users` was keyed on the USER id alone, so enrolments overwrote each other.
--
-- `core_enrol_get_enrolled_users` is read PER COURSE — the object is parent-scoped over
-- `core_course_get_courses`. A user enrolled in several courses is therefore returned once per course, each
-- time carrying THAT course's roles and groups. The seeded catalog declared exactly one key field, `id`
-- ("ID of the user"), and marked it IsUniqueKey=1. Every one of those per-course rows upserted onto the same
-- key, so the last course written won and the earlier ones were silently destroyed.
--
-- Observed live (ACR, 2026-08-04, read-only, run 5E8070E2): **26,300 records processed, 13,950 rows landed**,
-- and of the courses walked only **2 distinct courseid values survived** in the table — the rest had been
-- overwritten. Nothing errored. The run was green and the object looked populated, which is why this went
-- unnoticed behind the fetch defects that were fixed first.
--
-- The object's own metadata has said the correct identity all along, in writeFunctions.createResponseNote:
--     "identity is the composite (userid,courseid)"
-- and the write surface makes the stakes concrete: `enrol_manual_unenrol_users` is wired as DELETE, and a
-- delete keyed on user id alone does not name the course it is unenrolling from.
--
-- FIX, in three parts:
--
--   1. `parentScope.childIdField = 'courseid'` — the parent id was only landing in a `courseid` column
--      incidentally, because `paramName` happens to be a sensible column name. Declaring childIdField makes
--      the stamp intentional and matches how `Cohort Members` was fixed (V202608041720).
--   2. `id` becomes IsUniqueKey=0. It is a key PART, not a unique key; the old value was a false claim.
--   3. `courseid` is declared as a second IsPrimaryKey field, FK'd to `Courses`.
--
-- A two-field key is the established shape in this catalog, not a novelty: 38 objects already use one,
-- including HubSpot's association objects (contact_id + deal_id), which are the same join shape and are
-- likewise IsPrimaryKey=1 / IsUniqueKey=0 on both halves.
--
-- NOTE FOR OPERATORS: this widens the key of an EXISTING synced table. Rows already collapsed cannot be
-- recovered here — the overwritten enrolments were never stored. After this migration the object needs one
-- full (non-incremental) pull to repopulate the per-course rows.
--
-- Delta migration (not a re-seed): the catalog rows already exist on installed tenants, so this UPDATEs in
-- place and INSERTs only the one missing field. One hardcoded ID, no NEWID(), no audit columns written.
--
-- Idempotent on all four statements (WHERE guards plus a NOT EXISTS on the create); re-running is a no-op.

-- 1. Make the parent-id stamp explicit.
UPDATE [__mj].IntegrationObject
SET Configuration = JSON_MODIFY(Configuration, '$.parentScope.childIdField', 'courseid')
WHERE Name = 'Enrolled Users'
  AND ISJSON(Configuration) = 1
  AND JSON_VALUE(Configuration, '$.wsfunction') = 'core_enrol_get_enrolled_users'
  AND JSON_QUERY(Configuration, '$.parentScope') IS NOT NULL
  AND JSON_VALUE(Configuration, '$.parentScope.childIdField') IS NULL
  AND IntegrationID IN (SELECT i.ID FROM [__mj].Integration i WHERE i.Name = 'totara');

-- 2. `id` is a key PART, not a unique key.
UPDATE f
SET f.IsUniqueKey = 0,
    f.Description = N'ID of the user. NOT unique on this object: core_enrol_get_enrolled_users is read per '
                  + N'COURSE, so a user enrolled in several courses is returned once per course, each time '
                  + N'carrying THAT course''s roles and groups. Identity is the composite (courseid, id).'
FROM [__mj].IntegrationObjectField f
JOIN [__mj].IntegrationObject o ON o.ID = f.IntegrationObjectID
JOIN [__mj].Integration i ON i.ID = o.IntegrationID
WHERE i.Name = 'totara'
  AND o.Name = 'Enrolled Users'
  AND f.Name = 'id'
  AND f.IsUniqueKey = 1;

-- 3a. PROMOTE an existing discovered `courseid` to a declared key.
--
-- This is the branch that actually fires on a tenant that has synced this object even once. Because the
-- parent id was already landing in a `courseid` column, schema discovery created the field itself — as
-- IsCustom=1 / MetadataSource='Discovered' / Sequence=999, IsPrimaryKey=0, and (wrongly) IsUniqueKey=1.
-- An INSERT-only migration would find the row present, no-op, and change nothing on precisely the tenants
-- that have the defect. Verified against the live test catalog, where exactly this row existed.
UPDATE f
SET f.IsPrimaryKey = 1,
    f.IsUniqueKey = 0,          -- neither half is unique alone; the discovered row claimed otherwise
    f.IsReadOnly = 1,
    f.IsRequired = 1,
    f.AllowsNull = 0,
    f.Type = 'integer',
    f.Sequence = 0,
    f.Status = 'Active',
    f.IsCustom = 0,
    f.MetadataSource = 'Declared',
    f.DisplayName = 'Courseid',
    f.RelatedIntegrationObjectID = (
        SELECT c.ID FROM [__mj].IntegrationObject c
        WHERE c.Name = 'Courses' AND c.IntegrationID = o.IntegrationID),
    f.RelatedIntegrationObjectFieldName = 'id',
    f.Description = N'ID of the course this enrolment is in. Stamped from the parent scope (childIdField), '
                  + N'and the other half of this object''s identity: core_enrol_get_enrolled_users answers '
                  + N'per course, so the same user id recurs once per course they are enrolled in. Declared '
                  + N'as a key so those rows stay distinct instead of overwriting one another, and so a '
                  + N'delete (enrol_manual_unenrol_users) names the course it is unenrolling from.'
FROM [__mj].IntegrationObjectField f
JOIN [__mj].IntegrationObject o ON o.ID = f.IntegrationObjectID
JOIN [__mj].Integration i ON i.ID = o.IntegrationID
WHERE i.Name = 'totara'
  AND o.Name = 'Enrolled Users'
  AND f.Name = 'courseid'
  AND f.IsPrimaryKey = 0;

-- 3b. Declare `courseid` from scratch on a tenant that has never synced the object.
--
-- Through spCreateIntegrationObjectField, the same entry point the seed migration uses for all 269 other
-- fields — not a raw INSERT. Two reasons: the field goes in via MJ's own create path (audit columns and
-- defaults handled by the sproc, never written by hand), and `lint:catalog-completeness` counts seeded
-- fields by counting these calls, so a raw INSERT would ship the field while still reporting the catalog as
-- one field short. Object IDs are stable fleet-wide and hardcoded in the seed, so they are hardcoded here.
IF NOT EXISTS (
    SELECT 1 FROM [__mj].IntegrationObjectField
    WHERE IntegrationObjectID = '611CFE3A-7CCE-441D-9A30-F7DB93E6872F' AND Name = 'courseid'
)
BEGIN
    DECLARE @ID_courseid UNIQUEIDENTIFIER = '3C1E9A46-52B7-4D0F-9E88-7A4F5C21B9D3',
            @ObjID_courseid UNIQUEIDENTIFIER = '611CFE3A-7CCE-441D-9A30-F7DB93E6872F',
            @RelObjID_courseid UNIQUEIDENTIFIER = '0C6E06DC-30D4-462C-BC4C-A70432CCA78F',
            @Desc_courseid NVARCHAR(MAX) =
                N'ID of the course this enrolment is in. Stamped from the parent scope (childIdField), and '
              + N'the other half of this object''s identity: core_enrol_get_enrolled_users answers per '
              + N'course, so the same user id recurs once per course they are enrolled in. Declared as a '
              + N'key so those rows stay distinct instead of overwriting one another, and so a delete '
              + N'(enrol_manual_unenrol_users) names the course it is unenrolling from.';

    EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_courseid,
      @IntegrationObjectID = @ObjID_courseid,
      @Name = N'courseid',
      @DisplayName = N'Courseid',
      @Description = @Desc_courseid,
      @Category = NULL, @Category_Clear = 1,
      @Type = N'integer',
      @Length = NULL, @Length_Clear = 1,
      @Precision = NULL, @Precision_Clear = 1,
      @Scale = NULL, @Scale_Clear = 1,
      @AllowsNull = 0,
      @DefaultValue = NULL, @DefaultValue_Clear = 1,
      @IsPrimaryKey = 1,
      @IsUniqueKey = 0,
      @IsReadOnly = 1,
      @IsRequired = 1,
      @RelatedIntegrationObjectID = @RelObjID_courseid,
      @RelatedIntegrationObjectFieldName = N'id',
      @Sequence = 0,
      @Configuration = NULL, @Configuration_Clear = 1,
      @Status = N'Active',
      @IsCustom = 0,
      @MetadataSource = N'Declared';
END;
