-- OpenWater: declare the parent id every walked object carries.
-- Postgres twin of V202608050910__openwater__DeclareParentWalkTagFields.sql — see that file for the full
-- rationale: the field-map skew on the first sync (REQUIRED-FIXES item 6), the 8-of-25 unindexed soft FKs
-- (item 7), and why the type is `String` rather than `Integer`.
--
-- Idempotent: every statement is guarded on its own absence. IDs are hardcoded so the same field carries the
-- same ID on every tenant. Audit columns are not set.

-- ── 1. The nine walk-tag fields ──────────────────────────────────────────────────────────────────────────────

INSERT INTO "__mj"."IntegrationObjectField"
    ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "AllowsNull", "IsPrimaryKey",
     "IsUniqueKey", "IsReadOnly", "IsRequired", "RelatedIntegrationObjectID", "Sequence", "Status", "IsCustom",
     "MetadataSource")
SELECT v.field_id::uuid, o."ID", v.field_name, v.display_name, v.descr, 'String', true, false,
       false, false, false, p."ID", 0, 'Active', false, 'Declared'
FROM (VALUES
    ('2BFE5913-9D8F-5769-B46A-EC38C98FD9C6', 'ApplicationCategory',  'programId', 'Program Id', 'Program',
     'The Program this record was walked under (/v2/Programs/{programId}/ApplicationCategories).'),
    ('2212B345-8394-5E7B-9A35-34110D54D538', 'FundTransaction',      'fundId',    'Fund Id',    'Fund',
     'The Fund this record was walked under (/v2/Funds/{fundId}/Transactions).'),
    ('42F46EF8-074F-5BAD-8D36-6C5DE00862F3', 'OtherSessionItemType', 'programId', 'Program Id', 'Program',
     'The Program this record was walked under (/v2/Programs/{programId}/OtherSessionItemTypes).'),
    ('DE1496E1-64A1-5F78-9BFC-B44C7EBFB569', 'Report',               'roundId',   'Round Id',   'Rounds',
     'The Round this record was walked under (/v2/Rounds/{roundId}/ApplicationReports).'),
    ('5860D712-577F-57C2-89F2-1D51E934699F', 'ScheduleDay',          'programId', 'Program Id', 'Program',
     'The Program this record was walked under (/v2/Programs/{programId}/Scheduler/Days).'),
    ('152C9C7A-DC82-5C11-81D4-92753315C3AC', 'ScheduleRoom',         'programId', 'Program Id', 'Program',
     'The Program this record was walked under (/v2/Programs/{programId}/Scheduler/Rooms).'),
    ('26A08615-7040-5CDC-9162-6646C583C239', 'ScheduleTimeSlot',     'programId', 'Program Id', 'Program',
     'The Program this record was walked under (/v2/Programs/{programId}/Scheduler/TimeSlots).'),
    ('7D9FF438-D975-5CD5-8E14-E3A5D40473F6', 'ScheduleItem',         'programId', 'Program Id', 'Program',
     'The Program this record was walked under (/v2/Programs/{programId}/Scheduler/ScheduleItems).'),
    ('F5C6C9BF-B530-5C9C-8B56-FF89358C8428', 'SessionType',          'programId', 'Program Id', 'Program',
     'The Program this record was walked under (/v2/Programs/{programId}/SessionTypes).')
) AS v(field_id, object_name, field_name, display_name, parent_object_name, descr)
JOIN "__mj"."Integration" i ON i."Name" = 'openwater'
JOIN "__mj"."IntegrationObject" o ON o."IntegrationID" = i."ID" AND o."Name" = v.object_name
JOIN "__mj"."IntegrationObject" p ON p."IntegrationID" = i."ID" AND p."Name" = v.parent_object_name
WHERE NOT EXISTS (
    SELECT 1 FROM "__mj"."IntegrationObjectField" f
    WHERE f."IntegrationObjectID" = o."ID" AND f."Name" = v.field_name);

-- ── 2. Fields that already have the column but never declared what it points at ──────────────────────────────
-- Name-driven because two populations land here: `Discovered` rows the engine created by promoting the walk tag
-- out of custom overflow (sized, but with no relation, so never eligible for a soft FK), and declared fields
-- whose relation was never authored. Guarded on the relation being absent — never overwrites one.

UPDATE "__mj"."IntegrationObjectField" f
SET "RelatedIntegrationObjectID" = p."ID"
FROM "__mj"."IntegrationObject" o,
     "__mj"."Integration" i,
     "__mj"."IntegrationObject" p,
     (VALUES ('programId', 'Program'), ('roundId', 'Rounds'), ('fundId', 'Fund'))
        AS m(field_name, parent_object_name)
WHERE o."ID" = f."IntegrationObjectID"
  AND i."ID" = o."IntegrationID"
  AND m.field_name = f."Name"
  AND p."IntegrationID" = i."ID" AND p."Name" = m.parent_object_name
  AND i."Name" = 'openwater'
  AND f."RelatedIntegrationObjectID" IS NULL;
