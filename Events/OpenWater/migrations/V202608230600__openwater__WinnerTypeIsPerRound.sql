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
-- APPLYING THIS TO A TENANT THAT ALREADY HAS ROWS — the order matters:
--   1. run this migration (catalog only; nothing is dropped)
--   2. clear openwater.ApplicationWinnerType's existing rows, or run the object's next sync as a
--      fullSync. The 74 stored rows predate the column, so their roundId is NULL, and a key that
--      includes a NULL column cannot have its unique index built. This is the only destructive
--      step and it is recoverable in one sync: every row is re-fetched from /v2/Programs.
--   3. restart the API. The engine caches the IntegrationObject catalog at PROCESS START, so
--      neither the new field nor the AccessPath change is visible to a run started before it.
--   4. sync. The row count becomes the number of (round, winnerType) pairs.

-- ── 1. Declare roundId as part of the key ────────────────────────────────────────────────────────

INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length, AllowsNull, IsPrimaryKey,
     IsUniqueKey, IsReadOnly, IsRequired, RelatedIntegrationObjectID, Sequence, Status, IsCustom,
     MetadataSource)
SELECT '9C1E7B24-3F86-5A41-B7D2-58C0E1A4F933', o.ID, N'roundId', N'Round Id',
       N'The Round this winner type is declared on (/v2/Programs rounds[].winnerTypes[]). Part of the key: the same winner type id is declared on more than one round, so keying on id alone collapsed distinct (round, type) pairs into a single row.',
       N'String', 50, 0, 1,
       0, 1, 1, p.ID, 0, N'Active', 0,
       N'Declared'
FROM [__mj].Integration i
JOIN [__mj].IntegrationObject o ON o.IntegrationID = i.ID AND o.Name = N'ApplicationWinnerType'
JOIN [__mj].IntegrationObject p ON p.IntegrationID = i.ID AND p.Name = N'Rounds'
WHERE i.Name = 'openwater'
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
      WHERE i.Name = 'openwater' AND o.Name = N'ApplicationWinnerType');

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
  AND IntegrationID IN (SELECT ID FROM [__mj].Integration WHERE Name = 'openwater');
