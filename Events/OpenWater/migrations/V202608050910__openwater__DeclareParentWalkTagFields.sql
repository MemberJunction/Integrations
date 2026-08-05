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
JOIN [__mj].Integration i ON i.Name = 'openwater'
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
WHERE i.Name = 'openwater'
  AND f.RelatedIntegrationObjectID IS NULL;
