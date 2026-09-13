-- OpenWater -- replay the field declarations PostgreSQL silently skipped
--
-- REPAIR. Every statement replayed here already exists in an earlier migration and was a silent
-- no-op on PostgreSQL. They resolved the integration with
--
--     JOIN "__mj"."Integration" i ON i."Name" = 'openwater'
--
-- The Integration row is named 'OpenWater'. SQL Server's default collation is case-INSENSITIVE, so
-- the predicate matched there and the rows landed; PostgreSQL compares strings case-SENSITIVELY, so
-- it matched nothing, the INSERT ... SELECT inserted zero rows, and the migration reported success.
--
-- Observed live on a PostgreSQL workspace 2026-09-13: OpenWater installed 30 objects and
-- 5 of them had ZERO fields -- ApplicationFile, ApplicationRoundSubmission, ApplicationWinnerType, Judge and Media.
-- No fields means no primary key, so discovery skipped all 5 with `entity.skipped-no-pk` and an
-- empty message. The same connector on a SQL Server workspace has every field.
--
-- The earlier migrations are NOT edited: they are already applied and Flyway validates their
-- checksums. This replays their statements with a case-insensitive lookup instead. Every one is
-- either guarded by NOT EXISTS or an idempotent UPDATE, so on a workspace that already has the rows
-- this migration changes nothing.
--
-- Source statements replayed: V202608050910__openwater__DeclareParentWalkTagFields, V202608211500__openwater__DetailWalkObjects, V202608212210__openwater__JudgeGrainAndUnionWalk, V202608222100__openwater__PromotedPKMustSayDeclared, V202608230150__openwater__HarvestSegmentIsSubmissionFieldValues, V202608230600__openwater__WinnerTypeIsPerRound

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
JOIN "__mj"."Integration" i ON lower(i."Name") = 'openwater'
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
  AND lower(i."Name") = 'openwater'
  AND f."RelatedIntegrationObjectID" IS NULL;

-- 2. Their declared fields (guarded direct INSERT, per the V202608050910 delta precedent) --------------------

INSERT INTO "__mj"."IntegrationObjectField"
    ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length", "AllowsNull",
     "IsPrimaryKey", "IsUniqueKey", "IsReadOnly", "IsRequired", "RelatedIntegrationObjectID", "Sequence",
     "Status", "IsCustom", "MetadataSource")
SELECT v.field_id::uuid, o."ID", v.field_name, v.display_name, v.descr, v.type, v.length, v.allows_null,
       v.is_pk, v.is_unique, false, v.is_req, p."ID", 0, 'Active', false, 'Declared'
FROM (VALUES
    ('9C281CA4-60CD-449F-8155-5CC7808B471D', 'ApplicationRoundSubmission', 'applicationId', 'Application Id', 'String', NULL::int, false, true, false, true, 'Application',
     'The Application this submission belongs to. Injected by the connector from the access path (/v2/Applications/{applicationId} detail) rather than returned in the element body, so it is declared String - see V202608050910 for the sizing rationale.'),
    ('11581F42-B2CE-441A-B3D4-BDCEF0C31C12', 'ApplicationRoundSubmission', 'roundId', 'Round Id', 'String', NULL::int, false, true, false, true, 'Rounds',
     'Round this submission belongs to. Declared String rather than Integer - see V202608050910 for the sizing rationale.'),
    ('A3B8ABD8-E494-40FA-8621-97A58E6E2030', 'ApplicationRoundSubmission', 'roundName', 'Round Name', 'String', NULL::int, true, false, false, false, NULL,
     'Round name as denormalized on the submission.'),
    ('43E0A806-5C33-4DEE-861C-483C71343E4D', 'ApplicationRoundSubmission', 'status', 'Status', 'String', NULL::int, true, false, false, false, NULL,
     'Submission status.'),
    ('65677BDB-30F3-4D8D-9236-B745FDF1E317', 'ApplicationRoundSubmission', 'startedAtUtc', 'Started At Utc', 'DateTime', NULL::int, true, false, false, false, NULL,
     'When the applicant started this round submission (UTC).'),
    ('CC319DA2-36BD-46CB-BAF1-D33F510AAF64', 'ApplicationRoundSubmission', 'updatedAtUtc', 'Updated At Utc', 'DateTime', NULL::int, true, false, false, false, NULL,
     'Last update to this round submission (UTC).'),
    ('D4223F1B-85EA-4B65-ABD9-AE4BA2F0A1B5', 'ApplicationRoundSubmission', 'updatedByUserAtUtc', 'Updated By User At Utc', 'DateTime', NULL::int, true, false, false, false, NULL,
     'Last update made by the applicant (UTC).'),
    ('5B250646-C1FD-44AA-9663-4FAC882A6A67', 'ApplicationRoundSubmission', 'finalizedAtUtc', 'Finalized At Utc', 'DateTime', NULL::int, true, false, false, false, NULL,
     'When the submission was finalized (UTC).'),
    ('3613D8EF-2D39-431E-9CE7-1DEB50748CAC', 'ApplicationRoundSubmission', 'allowUserToMakeEdits', 'Allow User To Make Edits', 'Boolean', NULL::int, true, false, false, false, NULL,
     'Whether the applicant may still edit this submission.'),
    ('AE1DC9BD-DE4F-44C4-8D32-8ADBA02B2B73', 'ApplicationRoundSubmission', 'isPaid', 'Is Paid', 'Boolean', NULL::int, true, false, false, false, NULL,
     'Whether payment for this submission is complete.'),
    ('600C17AB-7FE6-40E6-A133-B912086C825A', 'ApplicationRoundSubmission', 'isWinner', 'Is Winner', 'Boolean', NULL::int, true, false, false, false, NULL,
     'Whether this submission was marked a winner.'),
    ('C0B7B305-A98B-41AE-902D-55F1B0908491', 'ApplicationRoundSubmission', 'invoiceId', 'Invoice Id', 'String', NULL::int, true, false, false, false, 'Invoice',
     'Invoice attached to this submission, when any. Declared String - see V202608050910 for the sizing rationale.'),
    ('78A20156-801E-408A-95D9-C4A9B3ECD8B9', 'ApplicationFile', 'mediaId', 'Media Id', 'String', NULL::int, false, true, true, true, 'Media',
     'Media id of the uploaded file (also this record identity). Declared String - see V202608050910 for the sizing rationale.'),
    ('0036DC50-6C4D-437D-9125-5D9E7A3AE9B9', 'ApplicationFile', 'applicationId', 'Application Id', 'String', NULL::int, true, false, false, false, 'Application',
     'The Application this file belongs to. Injected by the connector from the access path (/v2/Applications/{applicationId} detail).'),
    ('E580B35C-C1E1-47C8-8B01-F45264A52AF7', 'ApplicationFile', 'alias', 'Alias', 'String', NULL::int, true, false, false, false, NULL,
     'Field alias the file was uploaded under.'),
    ('6874A594-7919-489E-9C1D-CF3731138ACF', 'ApplicationFile', 'caption', 'Caption', 'String', NULL::int, true, false, false, false, NULL,
     'Caption entered for the uploaded file.'),
    ('1FB33C79-4EE9-42AB-AA30-C02B0C9C146B', 'Media', 'mediaId', 'Media Id', 'String', NULL::int, false, true, true, true, NULL,
     'Media id. Injected by the connector from the access path (/v2/Media/{mediaId}) - the ids are harvested from Application details.'),
    ('0F061F0D-9B9D-46F5-A9FF-1DDAA00105DC', 'Media', 'url', 'Url', 'String', 2048, true, false, false, false, NULL,
     'Download URL of the file.'),
    ('FB8A6F19-DAC0-4E5B-A4A2-EE098A1B8983', 'Media', 'fileName', 'File Name', 'String', NULL::int, true, false, false, false, NULL,
     'Original file name.'),
    ('CF825A2F-F232-4B8B-9506-27AEE250C1FA', 'ApplicationWinnerType', 'id', 'Id', 'String', NULL::int, false, true, true, true, NULL,
     'Winner type id. Declared String - see V202608050910 for the sizing rationale.'),
    ('821BE41B-B855-49A0-BB88-E7AB661C13DD', 'ApplicationWinnerType', 'name', 'Name', 'String', NULL::int, true, false, false, false, NULL,
     'Winner type name.')
) AS v(field_id, object_name, field_name, display_name, type, length, allows_null, is_pk, is_unique, is_req, related_object_name, descr)
JOIN "__mj"."Integration" i ON lower(i."Name") = 'openwater'
JOIN "__mj"."IntegrationObject" o ON o."IntegrationID" = i."ID" AND o."Name" = v.object_name
LEFT JOIN "__mj"."IntegrationObject" p ON p."IntegrationID" = i."ID" AND p."Name" = v.related_object_name
WHERE NOT EXISTS (
    SELECT 1 FROM "__mj"."IntegrationObjectField" f
    WHERE f."IntegrationObjectID" = o."ID" AND f."Name" = v.field_name);

-- 2. Declared fields: Judge x5 and JudgeAssignment.roundId (guarded direct INSERT) --------------------------

INSERT INTO "__mj"."IntegrationObjectField"
    ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length", "AllowsNull",
     "IsPrimaryKey", "IsUniqueKey", "IsReadOnly", "IsRequired", "Sequence", "RelatedIntegrationObjectID",
     "Status", "IsCustom", "MetadataSource")
SELECT v.field_id::uuid, o."ID", v.field_name, v.display_name, v.descr, v.type, v.length, v.allows_null,
       v.is_pk, v.is_unique, false, v.is_req, v.seq, p."ID", 'Active', false, 'Declared'
FROM (VALUES
    ('388A1FE5-3917-4542-BD63-56E1D79A7AB0', 'Judge', 'userId', 'User Id', 'String', NULL::int, false, true, true, true, 0, NULL,
     'Judge user id. Declared String rather than Integer - see V202608050910 for the sizing rationale.'),
    ('D397DDF0-2DC2-4375-A048-B1ECA72B10F0', 'Judge', 'firstName', 'First Name', 'String', NULL::int, true, false, false, false, 0, NULL,
     'Judge first name.'),
    ('4CA26EE1-A6C4-4475-9982-0ADF19760AF0', 'Judge', 'lastName', 'Last Name', 'String', NULL::int, true, false, false, false, 0, NULL,
     'Judge last name.'),
    ('51FFEDAB-DBED-41AB-8070-1F1C376E05AA', 'Judge', 'email', 'Email', 'String', 320, true, false, false, false, 0, NULL,
     'Judge email.'),
    ('38DCBFE4-BDFF-4432-AD2C-A5123E9A846E', 'Judge', 'roundId', 'Round Id', 'String', NULL::int, true, false, false, false, 0, 'Rounds',
     'The Round this judge was walked under. Present only on rows sourced from the AssignedToRound walk - team-sourced rows carry no round. Declared String - see V202608050910 for the sizing rationale.'),
    ('D0012814-B281-49DF-99B8-0B9618EB6DF4', 'JudgeAssignment', 'roundId', 'Round Id', 'String', NULL::int, false, true, false, true, 1, 'Rounds',
     'The Round this assignment was walked under (/v2/JudgeAssignments/AssignedToRound?roundId=). PRIMARY KEY together with userId: with userId alone, a judge assigned to several rounds collapsed to one row per person, so the object silently held distinct judges instead of assignments. Declared String - see V202608050910 for the sizing rationale.')
) AS v(field_id, object_name, field_name, display_name, type, length, allows_null, is_pk, is_unique, is_req, seq, related_object_name, descr)
JOIN "__mj"."Integration" i ON lower(i."Name") = 'openwater'
JOIN "__mj"."IntegrationObject" o ON o."IntegrationID" = i."ID" AND o."Name" = v.object_name
LEFT JOIN "__mj"."IntegrationObject" p ON p."IntegrationID" = i."ID" AND p."Name" = v.related_object_name
WHERE NOT EXISTS (
    SELECT 1 FROM "__mj"."IntegrationObjectField" f
    WHERE f."IntegrationObjectID" = o."ID" AND f."Name" = v.field_name);

-- 3. Tenants where JudgeAssignment.roundId was already promoted: complete it into the pair-grain key --------

UPDATE "__mj"."IntegrationObjectField" f
SET "IsPrimaryKey" = true,
    "IsRequired" = true,
    "AllowsNull" = false,
    "RelatedIntegrationObjectID" = COALESCE(f."RelatedIntegrationObjectID", r."ID")
FROM "__mj"."IntegrationObject" o
JOIN "__mj"."Integration" i ON i."ID" = o."IntegrationID" AND lower(i."Name") = 'openwater'
JOIN "__mj"."IntegrationObject" r ON r."IntegrationID" = i."ID" AND r."Name" = 'Rounds'
WHERE f."IntegrationObjectID" = o."ID"
  AND o."Name" = 'JudgeAssignment' AND f."Name" = 'roundId' AND f."IsPrimaryKey" = false;

-- NOTE: Earlier converter versions made INTEGER to BOOLEAN cast implicit by
-- modifying the system catalog so SS-style INSERT INTO bool_col VALUES (1)
-- would work. That modification required pg_catalog write privileges, which
-- managed PG (RDS, Aurora, Cloud SQL, Azure) does not grant. As of v5.30 all
-- bulk INSERTs are emitted with native TRUE/FALSE values directly, so the
-- cast modification is no longer needed. Removed to support managed-PG
-- installs out of the box.


-- ===================== Data (INSERT/UPDATE/DELETE) =====================

-- A field promoted to PRIMARY KEY by a delta migration must also be relabelled Declared.
--
-- V202608212210 completed JudgeAssignment's key into the (userId, roundId) pair, and on tenants
-- where `roundId` already existed it did that through an UPDATE rather than the INSERT. The UPDATE
-- set IsPrimaryKey/IsRequired/AllowsNull but left MetadataSource alone — so on those tenants
-- roundId became a PRIMARY KEY still labelled 'Discovered'.
--
-- The engine's overlay (decidePKPromotion) then does exactly what it is designed to do: an object
-- that has a declared PK cannot have a *Discovered* field in its key, so the next schema refresh
-- demotes it. Observed on a live tenant: the catalog went from `declared=roundId,userId` back to
-- `declared=userId`, which is the person-grain collapse V202608212210 existed to fix — a judge
-- assigned to several rounds folds to one row per person. The self-heal was right; the row was
-- mislabelled.
--
-- Matched by object + field name, not by ID: the row this has to repair is the pre-existing
-- promoted one, whose ID differs per tenant. Idempotent, and a no-op on tenants that took the
-- INSERT path (already 'Declared'). Re-asserts IsPrimaryKey because a refresh may already have
-- demoted it.

-- Written as a subquery rather than UPDATE ... FROM ... JOIN so the same statement is valid in
-- both dialects: the T-SQL update-through-alias form does not survive conversion to Postgres,
-- where the update target may not also appear in FROM.

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = TRUE,
    "MetadataSource" = 'Declared'
WHERE "Name" = 'roundId'
  AND ("IsPrimaryKey" = FALSE OR "MetadataSource" <> 'Declared')
  AND "IntegrationObjectID" IN (
      SELECT o."ID"
      FROM "__mj"."IntegrationObject" o
      JOIN "__mj"."Integration" i ON i."ID" = o."IntegrationID"
      WHERE lower(i."Name") = 'openwater' AND o."Name" = 'JudgeAssignment');

-- NOTE: Earlier converter versions made INTEGER to BOOLEAN cast implicit by
-- modifying the system catalog so SS-style INSERT INTO bool_col VALUES (1)
-- would work. That modification required pg_catalog write privileges, which
-- managed PG (RDS, Aurora, Cloud SQL, Azure) does not grant. As of v5.30 all
-- bulk INSERTs are emitted with native TRUE/FALSE values directly, so the
-- cast modification is no longer needed. Removed to support managed-PG
-- installs out of the box.


-- ===================== Data (INSERT/UPDATE/DELETE) =====================

UPDATE "__mj"."IntegrationObject"
SET "Configuration" = REPLACE("Configuration", '"fieldValues[]"', '"submissionFieldValues[]"')
WHERE "Name" IN ('ApplicationFile', 'Media')
  AND "IntegrationID" IN (SELECT "ID" FROM "__mj"."Integration" WHERE lower("Name") = 'openwater');

-- The same wrong key is quoted in the human-facing text of both rows.

UPDATE "__mj"."IntegrationObject"
SET "Description" = REPLACE("Description", 'roundSubmissions[] -> fieldValues[]',
                                       'roundSubmissions[] -> submissionFieldValues[]'),
    "APIPath"     = REPLACE("APIPath",     'roundSubmissions[].fieldValues[]',
                                       'roundSubmissions[].submissionFieldValues[]')
WHERE "Name" IN ('ApplicationFile', 'Media')
  AND "IntegrationID" IN (SELECT "ID" FROM "__mj"."Integration" WHERE lower("Name") = 'openwater');

-- 1. Declare roundId as part of the key, sized so it can be indexed.
INSERT INTO "__mj"."IntegrationObjectField"
    ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length",
     "AllowsNull", "IsPrimaryKey", "IsUniqueKey", "IsReadOnly", "IsRequired",
     "RelatedIntegrationObjectID", "Sequence", "Status", "IsCustom", "MetadataSource")
SELECT '9C1E7B24-3F86-5A41-B7D2-58C0E1A4F933'::uuid, o."ID", 'roundId', 'Round Id',
       'The Round this winner type is declared on (/v2/Programs rounds[].winnerTypes[]). Part of the key: the same winner type id is declared on more than one round, so keying on id alone collapsed distinct (round, type) pairs into a single row.',
       'String', 50,
       true, true, false, true, false,
       p."ID", 0, 'Active', false, 'Declared'
FROM "__mj"."Integration" i
JOIN "__mj"."IntegrationObject" o ON o."IntegrationID" = i."ID" AND o."Name" = 'ApplicationWinnerType'
JOIN "__mj"."IntegrationObject" p ON p."IntegrationID" = i."ID" AND p."Name" = 'Rounds'
WHERE lower(i."Name") = 'openwater'
  AND NOT EXISTS (
    SELECT 1 FROM "__mj"."IntegrationObjectField" f
    WHERE f."IntegrationObjectID" = o."ID" AND f."Name" = 'roundId');

-- 2. `id` alone is no longer unique.
UPDATE "__mj"."IntegrationObjectField"
SET "IsUniqueKey" = false
WHERE "Name" = 'id'
  AND "IsUniqueKey" = true
  AND "IntegrationObjectID" IN (
      SELECT o."ID" FROM "__mj"."IntegrationObject" o
      JOIN "__mj"."Integration" i ON i."ID" = o."IntegrationID"
      WHERE lower(i."Name") = 'openwater' AND o."Name" = 'ApplicationWinnerType');

-- 3. Tell the walk to carry the round down onto each leaf.
UPDATE "__mj"."IntegrationObject"
SET "Configuration" = '{"AccessPath":{"door":"Program","doorPath":"/v2/Programs","nestingSegments":["rounds[]","winnerTypes[]"],"embeddedParentTag":{"sourceKey":"id","asKey":"roundId"},"extractionMode":"embedded-array"}}'
WHERE "Name" = 'ApplicationWinnerType'
  AND "Configuration" NOT LIKE '%embeddedParentTag%'
  AND "IntegrationID" IN (SELECT "ID" FROM "__mj"."Integration" WHERE lower("Name") = 'openwater');
