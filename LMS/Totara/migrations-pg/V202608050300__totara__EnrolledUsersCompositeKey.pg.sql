-- Totara: `Enrolled Users` was keyed on the USER id alone, so enrolments overwrote each other.
--
-- `core_enrol_get_enrolled_users` is read PER COURSE — the object is parent-scoped over
-- `core_course_get_courses`. A user enrolled in several courses is therefore returned once per course, each
-- time carrying THAT course's roles and groups. The seeded catalog declared exactly one key field, `id`
-- ("ID of the user"), and marked it IsUniqueKey=1. Every one of those per-course rows upserted onto the same
-- key, so the last course written won and the earlier ones were silently destroyed.
--
-- Observed live (ACR, 2026-08-04, read-only, run 5E8070E2): 26,300 records processed, 13,950 rows landed,
-- and of the courses walked only 2 distinct courseid values survived in the table. Nothing errored.
--
-- The object's own metadata has said the correct identity all along, in writeFunctions.createResponseNote:
-- "identity is the composite (userid,courseid)". The write surface makes the stakes concrete:
-- `enrol_manual_unenrol_users` is wired as DELETE, and a delete keyed on user id alone does not name the
-- course it is unenrolling from.
--
-- NOTE FOR OPERATORS: this widens the key of an EXISTING synced table. Rows already collapsed cannot be
-- recovered here — the overwritten enrolments were never stored. After this migration the object needs one
-- full (non-incremental) pull to repopulate the per-course rows.
--
-- Idempotent on all four statements (WHERE guards plus a NOT EXISTS on the create); re-running is a no-op.
--
-- HAND-AUTHORED PG BODY, for the same reason as V202608041720: the SQL Server source uses JSON_MODIFY /
-- ISJSON / JSON_VALUE, which the conversion pipeline does not translate — it emits them as quoted
-- identifiers, i.e. calls to functions that do not exist in PostgreSQL. (As of this commit
-- `scripts/build-pg-migrations.mjs` FAILS generation on that shape rather than shipping it, so the escape
-- hatch is now the enforced path rather than a convention.) `jsonb_set` with create_if_missing is the same
-- add-or-replace as JSON_MODIFY; Configuration is a text column on PG, hence the ::jsonb read / ::text write.

-- 1. Make the parent-id stamp explicit.
UPDATE "__mj"."IntegrationObject"
SET "Configuration" = jsonb_set(
        ("Configuration")::jsonb,
        '{parentScope,childIdField}',
        '"courseid"'::jsonb,
        true
    )::text
WHERE "Name" = 'Enrolled Users'
  AND ("Configuration") IS JSON
  AND ("Configuration")::jsonb ->> 'wsfunction' = 'core_enrol_get_enrolled_users'
  AND ("Configuration")::jsonb -> 'parentScope' IS NOT NULL
  AND ("Configuration")::jsonb -> 'parentScope' ->> 'childIdField' IS NULL
  AND "IntegrationID" IN (SELECT i."ID" FROM "__mj"."Integration" i WHERE i."Name" = 'totara');

-- 2. `id` is a key PART, not a unique key.
UPDATE "__mj"."IntegrationObjectField" f
SET "IsUniqueKey" = false,
    "Description" = 'ID of the user. NOT unique on this object: core_enrol_get_enrolled_users is read per '
                 || 'COURSE, so a user enrolled in several courses is returned once per course, each time '
                 || 'carrying THAT course''s roles and groups. Identity is the composite (courseid, id).'
FROM "__mj"."IntegrationObject" o, "__mj"."Integration" i
WHERE o."ID" = f."IntegrationObjectID"
  AND i."ID" = o."IntegrationID"
  AND i."Name" = 'totara'
  AND o."Name" = 'Enrolled Users'
  AND f."Name" = 'id'
  AND f."IsUniqueKey" = true;

-- 3a. PROMOTE an existing discovered `courseid` to a declared key.
--
-- This is the branch that actually fires on a tenant that has synced this object even once: because the
-- parent id was already landing in a `courseid` column, schema discovery created the field itself, as
-- IsCustom / MetadataSource='Discovered' / Sequence 999, IsPrimaryKey=false and (wrongly) IsUniqueKey=true.
-- An INSERT-only migration would find the row present, no-op, and change nothing on precisely the tenants
-- that have the defect.
UPDATE "__mj"."IntegrationObjectField" f
SET "IsPrimaryKey" = true,
    "IsUniqueKey" = false,          -- neither half is unique alone; the discovered row claimed otherwise
    "IsReadOnly" = true,
    "IsRequired" = true,
    "AllowsNull" = false,
    "Type" = 'integer',
    "Sequence" = 0,
    "Status" = 'Active',
    "IsCustom" = false,
    "MetadataSource" = 'Declared',
    "DisplayName" = 'Courseid',
    "RelatedIntegrationObjectID" = (
        SELECT c."ID" FROM "__mj"."IntegrationObject" c
        WHERE c."Name" = 'Courses' AND c."IntegrationID" = o."IntegrationID"),
    "RelatedIntegrationObjectFieldName" = 'id',
    "Description" = 'ID of the course this enrolment is in. Stamped from the parent scope (childIdField), '
                 || 'and the other half of this object''s identity: core_enrol_get_enrolled_users answers '
                 || 'per course, so the same user id recurs once per course they are enrolled in. Declared '
                 || 'as a key so those rows stay distinct instead of overwriting one another, and so a '
                 || 'delete (enrol_manual_unenrol_users) names the course it is unenrolling from.'
FROM "__mj"."IntegrationObject" o, "__mj"."Integration" i
WHERE o."ID" = f."IntegrationObjectID"
  AND i."ID" = o."IntegrationID"
  AND i."Name" = 'totara'
  AND o."Name" = 'Enrolled Users'
  AND f."Name" = 'courseid'
  AND f."IsPrimaryKey" = false;

-- 3b. Declare `courseid` from scratch on a tenant that has never synced the object.
--
-- Through the spCreateIntegrationObjectField function, the same entry point the PG seed migration uses for
-- all 269 other fields — not a raw INSERT, so the field goes in via MJ's own create path with audit columns
-- and defaults handled by the function rather than written by hand. Object IDs are stable fleet-wide and
-- hardcoded in the seed, so they are hardcoded here. Dollar quoting means the inner literals use ordinary
-- '' escaping.
DO $$
DECLARE
  p_ID_courseid UUID := '3C1E9A46-52B7-4D0F-9E88-7A4F5C21B9D3';
  p_ObjID_courseid UUID := '611CFE3A-7CCE-441D-9A30-F7DB93E6872F';
  p_RelObjID_courseid UUID := '0C6E06DC-30D4-462C-BC4C-A70432CCA78F';
  p_Desc_courseid TEXT :=
      'ID of the course this enrolment is in. Stamped from the parent scope (childIdField), and the other '
   || 'half of this object''s identity: core_enrol_get_enrolled_users answers per course, so the same '
   || 'user id recurs once per course they are enrolled in. Declared as a key so those rows stay distinct '
   || 'instead of overwriting one another, and so a delete (enrol_manual_unenrol_users) names the course '
   || 'it is unenrolling from.';
BEGIN
  IF NOT EXISTS (
      SELECT 1 FROM "__mj"."IntegrationObjectField"
      WHERE "IntegrationObjectID" = p_ObjID_courseid AND "Name" = 'courseid'
  ) THEN
    PERFORM __mj."spCreateIntegrationObjectField"(
      p_ID := p_ID_courseid,
      p_IntegrationObjectID := p_ObjID_courseid,
      p_Name := 'courseid',
      p_DisplayName := 'Courseid',
      p_Description := p_Desc_courseid,
      p_Category := NULL, p_Category_Clear := TRUE,
      p_Type := 'integer',
      p_Length := NULL, p_Length_Clear := TRUE,
      p_Precision := NULL, p_Precision_Clear := TRUE,
      p_Scale := NULL, p_Scale_Clear := TRUE,
      p_AllowsNull := FALSE,
      p_DefaultValue := NULL, p_DefaultValue_Clear := TRUE,
      p_IsPrimaryKey := TRUE,
      p_IsUniqueKey := FALSE,
      p_IsReadOnly := TRUE,
      p_IsRequired := TRUE,
      p_RelatedIntegrationObjectID := p_RelObjID_courseid,
      p_RelatedIntegrationObjectFieldName := 'id',
      p_Sequence := 0,
      p_Configuration := NULL, p_Configuration_Clear := TRUE,
      p_Status := 'Active',
      p_IsCustom := FALSE,
      p_MetadataSource := 'Declared'
    );
  END IF;
END $$;
