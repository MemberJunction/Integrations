-- HAND-WRITTEN. Do not regenerate this file from the SQL Server original.
--
-- `mj migrate convert` could not produce correct Postgres for this migration, in three distinct
-- ways, each verified by reading its output:
--   * boolean columns stayed numeric (`'String', 0, 1,` where AllowsNull/IsPrimaryKey/IsReadOnly
--     need false/true) — Postgres will not implicitly cast integer to boolean, so the INSERT fails;
--   * `UPDATE ... SET Length = 50` came out with the identifier unquoted, which Postgres folds to
--     `length` and then cannot find, because the column is `"Length"`;
--   * an earlier draft using JSON_MODIFY was emitted as `"JSON_MODIFY"(...)` — a quoted identifier
--     for a function Postgres does not have.
-- The SQL Server original is the authored one; this is its reviewed equivalent. See the header of
-- migrations/V202608230600__openwater__WinnerTypeIsPerRound.sql for what it does and why, and for
-- the order it must be applied in on a tenant that already has rows.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE SCHEMA IF NOT EXISTS __mj;
SET search_path TO __mj, public;
SET standard_conforming_strings = on;

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
WHERE i."Name" = 'openwater'
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
      WHERE i."Name" = 'openwater' AND o."Name" = 'ApplicationWinnerType');

-- 3. Tell the walk to carry the round down onto each leaf.
UPDATE "__mj"."IntegrationObject"
SET "Configuration" = '{"AccessPath":{"door":"Program","doorPath":"/v2/Programs","nestingSegments":["rounds[]","winnerTypes[]"],"embeddedParentTag":{"sourceKey":"id","asKey":"roundId"},"extractionMode":"embedded-array"}}'
WHERE "Name" = 'ApplicationWinnerType'
  AND "Configuration" NOT LIKE '%embeddedParentTag%'
  AND "IntegrationID" IN (SELECT "ID" FROM "__mj"."Integration" WHERE "Name" = 'openwater');
