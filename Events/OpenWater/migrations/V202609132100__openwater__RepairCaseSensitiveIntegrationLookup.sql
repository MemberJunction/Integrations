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

-- OpenWater: the parent id every walked object carries was never declared, so the parent→child link was a
-- second-class citizen — real in the data, absent from the catalog.
--
-- Nine of the 25 objects are fetched by walking a parent (`/v2/Programs/{programId}/…`,
-- `/v2/Rounds/{roundId}/ApplicationReports`, `/v2/Funds/{fundId}/Transactions`). The connector tags each child
-- row with the id of the parent it was walked under — that is how every one of `Report`'s 68 rows carries
-- `roundId 82013`. But none of the nine DECLARED that field, so on a fresh tenant it arrives as an undeclared
-- value, lands in `__mj_integration_CustomOverflow`, and becomes a real column only if and when the engine
-- promotes it. Two consequences, both observed live:
--
--   1. The first sync of a walked object can run with FEWER field maps than the record has fields. On run
--      847A4E5E `ApplicationCategory` fetched its 43 records correctly with `fieldMapsCount: 0` and failed all
--      43 writes; `Report` had 2 field maps on one run and 3 on the next. Both objects were missing exactly the
--      walk's tag field. Declaring it removes the skew at its source (see docs/REQUIRED-FIXES.md item 6).
--   2. A promoted column is not a declared relation, so it gets no soft foreign key and no index. Ground truth
--      in MJ_CT48: of 25 declared relations, 17 have an `IDX_AUTO_MJ_FKEY_*` index and 8 do not — and the 8 are
--      exactly the ones whose column landed `NVARCHAR(MAX)` (see item 7). `ApplicationCategory.programId`,
--      `Report.roundId` and `SessionType.programId` were sized correctly by promotion but had no relation to
--      index in the first place.
--
-- WHY `String` AND NOT `Integer`, deliberately. These ids are int32 at the vendor, but the value the connector
-- injects is the parent id as a string — which is also exactly what the engine itself chose when it promoted
-- these fields (`Report.roundId` NVARCHAR(255), `ApplicationCategory.programId` NVARCHAR(812)). A declared
-- `Integer` with no Length is mapped to `NVARCHAR(MAX)`, which SQL Server cannot index, so declaring these as
-- Integer would have created nine more unindexable soft FKs and ALTERed two working sized columns down to MAX.
-- An unsized `String` maps to `NVARCHAR(812)`: sized, indexable, and never a shrink of what is already there.
--
-- This migration also back-fills the relation on two fields that already had the column but never declared what
-- it pointed at (`JudgeAssignment.roundId`, `JudgeRecusal.roundId`, both already `NVARCHAR(812)`).
--
-- Delta migration: the objects exist on installed tenants, so this INSERTs the missing fields and UPDATEs the
-- two missing relations. Every statement is guarded on its own absence — re-running is a no-op. IDs are
-- hardcoded (never NEWID()) so the same field carries the same ID on every tenant. Audit columns are not set.

-- ── 1. The nine walk-tag fields ──────────────────────────────────────────────────────────────────────────────

INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, AllowsNull, IsPrimaryKey, IsUniqueKey,
     IsReadOnly, IsRequired, RelatedIntegrationObjectID, Sequence, Status, IsCustom, MetadataSource)
SELECT v.FieldID, o.ID, v.FieldName, v.DisplayName, v.Descr, N'String', 1, 0, 0,
       0, 0, p.ID, 0, N'Active', 0, N'Declared'
FROM (VALUES
    ('2BFE5913-9D8F-5769-B46A-EC38C98FD9C6', 'ApplicationCategory',  'programId', 'Program Id', 'Program',
     N'The Program this record was walked under (/v2/Programs/{programId}/ApplicationCategories).'),
    ('2212B345-8394-5E7B-9A35-34110D54D538', 'FundTransaction',      'fundId',    'Fund Id',    'Fund',
     N'The Fund this record was walked under (/v2/Funds/{fundId}/Transactions).'),
    ('42F46EF8-074F-5BAD-8D36-6C5DE00862F3', 'OtherSessionItemType', 'programId', 'Program Id', 'Program',
     N'The Program this record was walked under (/v2/Programs/{programId}/OtherSessionItemTypes).'),
    ('DE1496E1-64A1-5F78-9BFC-B44C7EBFB569', 'Report',               'roundId',   'Round Id',   'Rounds',
     N'The Round this record was walked under (/v2/Rounds/{roundId}/ApplicationReports).'),
    ('5860D712-577F-57C2-89F2-1D51E934699F', 'ScheduleDay',          'programId', 'Program Id', 'Program',
     N'The Program this record was walked under (/v2/Programs/{programId}/Scheduler/Days).'),
    ('152C9C7A-DC82-5C11-81D4-92753315C3AC', 'ScheduleRoom',         'programId', 'Program Id', 'Program',
     N'The Program this record was walked under (/v2/Programs/{programId}/Scheduler/Rooms).'),
    ('26A08615-7040-5CDC-9162-6646C583C239', 'ScheduleTimeSlot',     'programId', 'Program Id', 'Program',
     N'The Program this record was walked under (/v2/Programs/{programId}/Scheduler/TimeSlots).'),
    ('7D9FF438-D975-5CD5-8E14-E3A5D40473F6', 'ScheduleItem',         'programId', 'Program Id', 'Program',
     N'The Program this record was walked under (/v2/Programs/{programId}/Scheduler/ScheduleItems).'),
    ('F5C6C9BF-B530-5C9C-8B56-FF89358C8428', 'SessionType',          'programId', 'Program Id', 'Program',
     N'The Program this record was walked under (/v2/Programs/{programId}/SessionTypes).')
) AS v(FieldID, ObjectName, FieldName, DisplayName, ParentObjectName, Descr)
JOIN [__mj].Integration i ON LOWER(i.Name) = 'openwater'
JOIN [__mj].IntegrationObject o ON o.IntegrationID = i.ID AND o.Name = v.ObjectName
JOIN [__mj].IntegrationObject p ON p.IntegrationID = i.ID AND p.Name = v.ParentObjectName
WHERE NOT EXISTS (
    SELECT 1 FROM [__mj].IntegrationObjectField f
    WHERE f.IntegrationObjectID = o.ID AND f.Name = v.FieldName);

-- ── 2. Fields that already have the column but never declared what it points at ──────────────────────────────
--
-- Two populations end up here, which is why this is name-driven rather than a list of objects:
--
--   * `MetadataSource='Discovered'` rows the engine created by PROMOTING the walk tag out of custom overflow.
--     On the proving tenant those are `ApplicationCategory.programId`, `Report.roundId` and
--     `SessionType.programId` — sized correctly (512 / 255 / 512) but with no relation, so they were never
--     eligible for a soft FK or an index. The INSERT above correctly skips them (they exist); this is what
--     actually completes them. A fresh tenant takes the INSERT path instead and needs no repair.
--   * Declared fields whose relation was simply never authored: `JudgeAssignment.roundId`,
--     `JudgeRecusal.roundId`.
--
-- Guarded on the relation being absent, so an already-declared relation is never overwritten.

UPDATE f
SET f.RelatedIntegrationObjectID = p.ID
FROM [__mj].IntegrationObjectField f
JOIN [__mj].IntegrationObject o ON o.ID = f.IntegrationObjectID
JOIN [__mj].Integration i ON i.ID = o.IntegrationID
JOIN (VALUES ('programId', 'Program'), ('roundId', 'Rounds'), ('fundId', 'Fund'))
     AS m(FieldName, ParentObjectName) ON m.FieldName = f.Name
JOIN [__mj].IntegrationObject p ON p.IntegrationID = i.ID AND p.Name = m.ParentObjectName
WHERE LOWER(i.Name) = 'openwater'
  AND f.RelatedIntegrationObjectID IS NULL;

GO

-- 2. Their declared fields (guarded direct INSERT, per the V202608050910 delta precedent) --------------------

INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length, AllowsNull, IsPrimaryKey,
     IsUniqueKey, IsReadOnly, IsRequired, RelatedIntegrationObjectID, Sequence, Status, IsCustom, MetadataSource)
SELECT v.FieldID, o.ID, v.FieldName, v.DisplayName, v.Descr, v.Type, v.Length, v.AllowsNull, v.IsPK,
       v.IsUnique, 0, v.IsReq, p.ID, 0, N'Active', 0, N'Declared'
FROM (VALUES
    ('9C281CA4-60CD-449F-8155-5CC7808B471D', N'ApplicationRoundSubmission', N'applicationId', N'Application Id', N'String', NULL, 0, 1, 0, 1, N'Application',
     N'The Application this submission belongs to. Injected by the connector from the access path (/v2/Applications/{applicationId} detail) rather than returned in the element body, so it is declared String - see V202608050910 for the sizing rationale.'),
    ('11581F42-B2CE-441A-B3D4-BDCEF0C31C12', N'ApplicationRoundSubmission', N'roundId', N'Round Id', N'String', NULL, 0, 1, 0, 1, N'Rounds',
     N'Round this submission belongs to. Declared String rather than Integer - see V202608050910 for the sizing rationale.'),
    ('A3B8ABD8-E494-40FA-8621-97A58E6E2030', N'ApplicationRoundSubmission', N'roundName', N'Round Name', N'String', NULL, 1, 0, 0, 0, NULL,
     N'Round name as denormalized on the submission.'),
    ('43E0A806-5C33-4DEE-861C-483C71343E4D', N'ApplicationRoundSubmission', N'status', N'Status', N'String', NULL, 1, 0, 0, 0, NULL,
     N'Submission status.'),
    ('65677BDB-30F3-4D8D-9236-B745FDF1E317', N'ApplicationRoundSubmission', N'startedAtUtc', N'Started At Utc', N'DateTime', NULL, 1, 0, 0, 0, NULL,
     N'When the applicant started this round submission (UTC).'),
    ('CC319DA2-36BD-46CB-BAF1-D33F510AAF64', N'ApplicationRoundSubmission', N'updatedAtUtc', N'Updated At Utc', N'DateTime', NULL, 1, 0, 0, 0, NULL,
     N'Last update to this round submission (UTC).'),
    ('D4223F1B-85EA-4B65-ABD9-AE4BA2F0A1B5', N'ApplicationRoundSubmission', N'updatedByUserAtUtc', N'Updated By User At Utc', N'DateTime', NULL, 1, 0, 0, 0, NULL,
     N'Last update made by the applicant (UTC).'),
    ('5B250646-C1FD-44AA-9663-4FAC882A6A67', N'ApplicationRoundSubmission', N'finalizedAtUtc', N'Finalized At Utc', N'DateTime', NULL, 1, 0, 0, 0, NULL,
     N'When the submission was finalized (UTC).'),
    ('3613D8EF-2D39-431E-9CE7-1DEB50748CAC', N'ApplicationRoundSubmission', N'allowUserToMakeEdits', N'Allow User To Make Edits', N'Boolean', NULL, 1, 0, 0, 0, NULL,
     N'Whether the applicant may still edit this submission.'),
    ('AE1DC9BD-DE4F-44C4-8D32-8ADBA02B2B73', N'ApplicationRoundSubmission', N'isPaid', N'Is Paid', N'Boolean', NULL, 1, 0, 0, 0, NULL,
     N'Whether payment for this submission is complete.'),
    ('600C17AB-7FE6-40E6-A133-B912086C825A', N'ApplicationRoundSubmission', N'isWinner', N'Is Winner', N'Boolean', NULL, 1, 0, 0, 0, NULL,
     N'Whether this submission was marked a winner.'),
    ('C0B7B305-A98B-41AE-902D-55F1B0908491', N'ApplicationRoundSubmission', N'invoiceId', N'Invoice Id', N'String', NULL, 1, 0, 0, 0, N'Invoice',
     N'Invoice attached to this submission, when any. Declared String - see V202608050910 for the sizing rationale.'),
    ('78A20156-801E-408A-95D9-C4A9B3ECD8B9', N'ApplicationFile', N'mediaId', N'Media Id', N'String', NULL, 0, 1, 1, 1, N'Media',
     N'Media id of the uploaded file (also this record identity). Declared String - see V202608050910 for the sizing rationale.'),
    ('0036DC50-6C4D-437D-9125-5D9E7A3AE9B9', N'ApplicationFile', N'applicationId', N'Application Id', N'String', NULL, 1, 0, 0, 0, N'Application',
     N'The Application this file belongs to. Injected by the connector from the access path (/v2/Applications/{applicationId} detail).'),
    ('E580B35C-C1E1-47C8-8B01-F45264A52AF7', N'ApplicationFile', N'alias', N'Alias', N'String', NULL, 1, 0, 0, 0, NULL,
     N'Field alias the file was uploaded under.'),
    ('6874A594-7919-489E-9C1D-CF3731138ACF', N'ApplicationFile', N'caption', N'Caption', N'String', NULL, 1, 0, 0, 0, NULL,
     N'Caption entered for the uploaded file.'),
    ('1FB33C79-4EE9-42AB-AA30-C02B0C9C146B', N'Media', N'mediaId', N'Media Id', N'String', NULL, 0, 1, 1, 1, NULL,
     N'Media id. Injected by the connector from the access path (/v2/Media/{mediaId}) - the ids are harvested from Application details.'),
    ('0F061F0D-9B9D-46F5-A9FF-1DDAA00105DC', N'Media', N'url', N'Url', N'String', 2048, 1, 0, 0, 0, NULL,
     N'Download URL of the file.'),
    ('FB8A6F19-DAC0-4E5B-A4A2-EE098A1B8983', N'Media', N'fileName', N'File Name', N'String', NULL, 1, 0, 0, 0, NULL,
     N'Original file name.'),
    ('CF825A2F-F232-4B8B-9506-27AEE250C1FA', N'ApplicationWinnerType', N'id', N'Id', N'String', NULL, 0, 1, 1, 1, NULL,
     N'Winner type id. Declared String - see V202608050910 for the sizing rationale.'),
    ('821BE41B-B855-49A0-BB88-E7AB661C13DD', N'ApplicationWinnerType', N'name', N'Name', N'String', NULL, 1, 0, 0, 0, NULL,
     N'Winner type name.')
) AS v(FieldID, ObjectName, FieldName, DisplayName, Type, Length, AllowsNull, IsPK, IsUnique, IsReq, RelatedObjectName, Descr)
JOIN [__mj].Integration i ON LOWER(i.Name) = 'openwater'
JOIN [__mj].IntegrationObject o ON o.IntegrationID = i.ID AND o.Name = v.ObjectName
LEFT JOIN [__mj].IntegrationObject p ON p.IntegrationID = i.ID AND p.Name = v.RelatedObjectName
WHERE NOT EXISTS (
    SELECT 1 FROM [__mj].IntegrationObjectField f
    WHERE f.IntegrationObjectID = o.ID AND f.Name = v.FieldName);

GO

-- 2. Declared fields: Judge x5 and JudgeAssignment.roundId (guarded direct INSERT) --------------------------

INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length, AllowsNull, IsPrimaryKey,
     IsUniqueKey, IsReadOnly, IsRequired, Sequence, RelatedIntegrationObjectID, Status, IsCustom, MetadataSource)
SELECT v.FieldID, o.ID, v.FieldName, v.DisplayName, v.Descr, v.Type, v.Length, v.AllowsNull, v.IsPK,
       v.IsUnique, 0, v.IsReq, v.Seq, p.ID, N'Active', 0, N'Declared'
FROM (VALUES
    ('388A1FE5-3917-4542-BD63-56E1D79A7AB0', N'Judge', N'userId', N'User Id', N'String', NULL, 0, 1, 1, 1, 0, NULL,
     N'Judge user id. Declared String rather than Integer - see V202608050910 for the sizing rationale.'),
    ('D397DDF0-2DC2-4375-A048-B1ECA72B10F0', N'Judge', N'firstName', N'First Name', N'String', NULL, 1, 0, 0, 0, 0, NULL,
     N'Judge first name.'),
    ('4CA26EE1-A6C4-4475-9982-0ADF19760AF0', N'Judge', N'lastName', N'Last Name', N'String', NULL, 1, 0, 0, 0, 0, NULL,
     N'Judge last name.'),
    ('51FFEDAB-DBED-41AB-8070-1F1C376E05AA', N'Judge', N'email', N'Email', N'String', 320, 1, 0, 0, 0, 0, NULL,
     N'Judge email.'),
    ('38DCBFE4-BDFF-4432-AD2C-A5123E9A846E', N'Judge', N'roundId', N'Round Id', N'String', NULL, 1, 0, 0, 0, 0, N'Rounds',
     N'The Round this judge was walked under. Present only on rows sourced from the AssignedToRound walk - team-sourced rows carry no round. Declared String - see V202608050910 for the sizing rationale.'),
    ('D0012814-B281-49DF-99B8-0B9618EB6DF4', N'JudgeAssignment', N'roundId', N'Round Id', N'String', NULL, 0, 1, 0, 1, 1, N'Rounds',
     N'The Round this assignment was walked under (/v2/JudgeAssignments/AssignedToRound?roundId=). PRIMARY KEY together with userId: with userId alone, a judge assigned to several rounds collapsed to one row per person, so the object silently held distinct judges instead of assignments. Declared String - see V202608050910 for the sizing rationale.')
) AS v(FieldID, ObjectName, FieldName, DisplayName, Type, Length, AllowsNull, IsPK, IsUnique, IsReq, Seq, RelatedObjectName, Descr)
JOIN [__mj].Integration i ON LOWER(i.Name) = 'openwater'
JOIN [__mj].IntegrationObject o ON o.IntegrationID = i.ID AND o.Name = v.ObjectName
LEFT JOIN [__mj].IntegrationObject p ON p.IntegrationID = i.ID AND p.Name = v.RelatedObjectName
WHERE NOT EXISTS (
    SELECT 1 FROM [__mj].IntegrationObjectField f
    WHERE f.IntegrationObjectID = o.ID AND f.Name = v.FieldName);

-- 3. Tenants where JudgeAssignment.roundId was already PROMOTED out of custom overflow: the INSERT above
--    correctly skipped it (it exists) - this is what completes it into the pair-grain key. --------------------

UPDATE f
SET f.IsPrimaryKey = 1,
    f.IsRequired = 1,
    f.AllowsNull = 0,
    f.RelatedIntegrationObjectID = COALESCE(f.RelatedIntegrationObjectID, r.ID)
FROM [__mj].IntegrationObjectField f
JOIN [__mj].IntegrationObject o ON o.ID = f.IntegrationObjectID
JOIN [__mj].Integration i ON i.ID = o.IntegrationID AND LOWER(i.Name) = 'openwater'
JOIN [__mj].IntegrationObject r ON r.IntegrationID = i.ID AND r.Name = N'Rounds'
WHERE o.Name = N'JudgeAssignment' AND f.Name = N'roundId' AND f.IsPrimaryKey = 0;

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

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 1,
    MetadataSource = N'Declared'
WHERE Name = N'roundId'
  AND (IsPrimaryKey = 0 OR MetadataSource <> N'Declared')
  AND IntegrationObjectID IN (
      SELECT o.ID
      FROM [__mj].IntegrationObject o
      JOIN [__mj].Integration i ON i.ID = o.IntegrationID
      WHERE LOWER(i.Name) = 'openwater' AND o.Name = N'JudgeAssignment');

-- OpenWater Connector — the application-detail payload names the field-value array
-- 'submissionFieldValues', not 'fieldValues'. Both detail-walk objects declared the wrong
-- segment and therefore extracted nothing.
--
-- V202608211500 declared ApplicationFile's nestingSegments and Media's harvestSegments as
-- roundSubmissions[] -> fieldValues[]. That second segment was taken from OpenWater's
-- documentation rather than from an observed response. Live evidence, from a shape probe that
-- prints key NAMES and types only (never values), on /v2/Applications/{applicationId}:
--
--   root{... roundSubmissions:array[1] ...}
--   roundSubmissions[]{... submissionFieldValues:array[67] ...}
--   fieldValues[]{}          <- the declared key is absent from the payload
--
-- The walk was structurally correct and did its full work: it queried the Application door,
-- paged it to 1,976 rows, and fetched every parent detail — then descended into a key that
-- does not exist, so both objects reported success with zero records and no error. Result:
-- ApplicationFile 0 of 4,001 expected, Media 0 of 4,001.
--
-- Written as a REPLACE against the declared JSON rather than a rewrite of the whole
-- Configuration so it applies cleanly on top of V202608211500 wherever that has already run,
-- and is a no-op where it has not. REPLACE is idempotent, so there is deliberately no LIKE
-- guard: the SS->PG converter renders LIKE N'%"fieldValues[]"%' as the Postgres regex
-- ~ '[fieldValues[]]' — a character class, which is a different predicate entirely.

UPDATE [__mj].IntegrationObject
SET Configuration = REPLACE(Configuration, N'"fieldValues[]"', N'"submissionFieldValues[]"')
WHERE Name IN (N'ApplicationFile', N'Media')
  AND IntegrationID IN (SELECT ID FROM [__mj].Integration WHERE LOWER(Name) = 'openwater');

-- The same wrong key is quoted in the human-facing text of both rows.
UPDATE [__mj].IntegrationObject
SET Description = REPLACE(Description, N'roundSubmissions[] -> fieldValues[]',
                                       N'roundSubmissions[] -> submissionFieldValues[]'),
    APIPath     = REPLACE(APIPath,     N'roundSubmissions[].fieldValues[]',
                                       N'roundSubmissions[].submissionFieldValues[]')
WHERE Name IN (N'ApplicationFile', N'Media')
  AND IntegrationID IN (SELECT ID FROM [__mj].Integration WHERE LOWER(Name) = 'openwater');

-- OpenWater: a winner type is declared PER ROUND, and keying it on `id` alone collapsed the pairs.
--
-- ApplicationWinnerType reads /v2/Programs -> rounds[] -> winnerTypes[]. A winnerType is
-- {id, name} (Models.Program.WinnerTypeModel in OpenWater's published swagger), and the SAME type
-- id is declared on more than one round. The object keyed on `id` alone, and the embedded-array
-- walk kept only the leaf — so the round was absent from the row and every repeat of a type across
-- rounds overwrote the previous one. Live: 74 rows against a client target of 89.
--
-- Two halves, and both are needed:
--   * the connector now copies the parent's id onto each leaf when the AccessPath declares
--     `embeddedParentTag` (connector-openwater; see ExtractEmbedded), and
--   * `roundId` is DECLARED here as part of the key. Declared, not left to discovery: MJ's
--     PK-promotion guard will not let a *Discovered* field join the key of an object that already
--     has a declared PK, so a discovered roundId would arrive as a plain column and the key would
--     stay wrong.
--
-- Length 50 is explicit. A declared String with no Length lands NVARCHAR(MAX), which cannot carry
-- an index — and with two key columns the pair must also stay inside the 900-byte index limit.
--
-- roundId is declared NULLABLE, which is deliberate. The rows a tenant already has predate the
-- column, so adding it as NOT NULL would fail outright on a populated table — and a key component
-- that is NULL only ever describes those legacy rows, every freshly walked row carries its round.
-- The next fullSync archives them by delete-detection, so nothing has to be deleted by hand.
--
-- APPLYING THIS TO A TENANT THAT ALREADY HAS ROWS — the order matters:
--   1. run this migration (catalog only; nothing is dropped, nothing is deleted)
--   2. restart the API. The engine caches the IntegrationObject catalog at PROCESS START, so
--      neither the new field nor the AccessPath change is visible to a run started before it.
--   3. run the object's next sync as a fullSync. The stale rows (roundId NULL) are archived by
--      delete-detection and the row count becomes the number of (round, winnerType) pairs.

-- ── 1. Declare roundId as part of the key ────────────────────────────────────────────────────────

INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length, AllowsNull, IsPrimaryKey,
     IsUniqueKey, IsReadOnly, IsRequired, RelatedIntegrationObjectID, Sequence, Status, IsCustom,
     MetadataSource)
SELECT '9C1E7B24-3F86-5A41-B7D2-58C0E1A4F933', o.ID, N'roundId', N'Round Id',
       N'The Round this winner type is declared on (/v2/Programs rounds[].winnerTypes[]). Part of the key: the same winner type id is declared on more than one round, so keying on id alone collapsed distinct (round, type) pairs into a single row.',
       N'String', 50, 1, 1,
       0, 1, 0, p.ID, 0, N'Active', 0,
       N'Declared'
FROM [__mj].Integration i
JOIN [__mj].IntegrationObject o ON o.IntegrationID = i.ID AND o.Name = N'ApplicationWinnerType'
JOIN [__mj].IntegrationObject p ON p.IntegrationID = i.ID AND p.Name = N'Rounds'
WHERE LOWER(i.Name) = 'openwater'
  AND NOT EXISTS (
    SELECT 1 FROM [__mj].IntegrationObjectField f
    WHERE f.IntegrationObjectID = o.ID AND f.Name = N'roundId');

-- ── 2. `id` alone is no longer unique ────────────────────────────────────────────────────────────

UPDATE [__mj].IntegrationObjectField
SET IsUniqueKey = 0
WHERE Name = N'id'
  AND IsUniqueKey = 1
  AND IntegrationObjectID IN (
      SELECT o.ID FROM [__mj].IntegrationObject o
      JOIN [__mj].Integration i ON i.ID = o.IntegrationID
      WHERE LOWER(i.Name) = 'openwater' AND o.Name = N'ApplicationWinnerType');

-- ── 3. Tell the walk to carry the round down ─────────────────────────────────────────────────────
--
-- The whole document is written, not patched. JSON_MODIFY is SQL-Server-only — the SS->PG converter
-- renders it as a quoted identifier for a function Postgres does not have — and this object's
-- AccessPath is four keys, all of them stated here, so there is nothing around the change to lose.
-- The guard is a plain substring test, which is the one LIKE shape that survives the conversion
-- intact (a pattern containing [] becomes a character class, which is a different predicate).

UPDATE [__mj].IntegrationObject
SET Configuration = N'{"AccessPath":{"door":"Program","doorPath":"/v2/Programs","nestingSegments":["rounds[]","winnerTypes[]"],"embeddedParentTag":{"sourceKey":"id","asKey":"roundId"},"extractionMode":"embedded-array"}}'
WHERE Name = N'ApplicationWinnerType'
  AND Configuration NOT LIKE '%embeddedParentTag%'
  AND IntegrationID IN (SELECT ID FROM [__mj].Integration WHERE LOWER(Name) = 'openwater');
