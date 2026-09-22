-- Totara: disable the four objects the vendor exposes without any derivable key.
--
-- Course Completion Status, Activity Completion Status, Grade Items and Course Grades Overview
-- declare fields but no primary key, and none can be given one honestly. Their wsfunctions
-- (core_completion_get_course_completion_status, core_completion_get_activities_completion_status,
-- gradereport_user_get_grade_items, gradereport_overview_get_course_grades) are per-(course, user)
-- or per-user readers that return no row identity of their own; two of the four could only ever
-- be walked per course-user PAIR, which on the proving site is 428 courses x 24,682 users of
-- requests. docs/SUPPORT.md has classified them "keyless by design" since 2026-08-05: no entity
-- map has ever existed for them (24 maps for 28 objects), and the connector declines to sync
-- unkeyed rows.
--
-- What was wrong is not the declining but the OFFERING. An Active object with no key either costs
-- the soft-PK classifier a per-tenant inference at every discovery, or lands `entity.skipped-no-pk`
-- and is still shown in the picker as data that could arrive. Neither is true of a Disabled object:
-- the engine filters to Status = Active (GetActiveIntegrationObjects), so it is neither inferred
-- against nor offered. Disabled is the fleet convention for this (132 objects across other
-- connectors already carry it) and is one of the three values CK_IntegrationObject_Status allows.
--
-- This is the connector-side half of the read-only primary-key gate (scripts/lint-writable-pk.mjs,
-- read-only scope), which exempts non-Active objects for exactly this reason.
--
-- Delta migration: one UPDATE by the objects' seeded IDs, which are hardcoded in
-- V202606271410__totara__Metadata.sql and therefore identical on every tenant. Re-running is a
-- no-op. Fields are left untouched; the object row governs what the engine offers. Audit columns
-- are not set.

UPDATE [__mj].[IntegrationObject]
SET [Status] = 'Disabled'
WHERE [ID] IN (
    '3D273C11-7773-47ED-BC7F-8AAE42AD412C',
    'B8FF8330-A5F3-4CCD-BC6E-32FE71FAE93E',
    '98E285B0-7BAB-46D1-9F49-E8F1AE0259D6',
    '5DCADB19-14BA-431F-BDDB-FEC8C8CFB041'
);
