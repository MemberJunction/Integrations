-- ============================================================================
-- MemberJunction PostgreSQL Migration
-- Converted from SQL Server using TypeScript conversion pipeline
-- ============================================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Schema
CREATE SCHEMA IF NOT EXISTS __mj;
SET search_path TO __mj, public;

-- Ensure backslashes in string literals are treated literally (not as escape sequences)
SET standard_conforming_strings = on;

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
  AND "IntegrationID" IN (SELECT "ID" FROM "__mj"."Integration" WHERE "Name" = 'openwater');

-- The same wrong key is quoted in the human-facing text of both rows.

UPDATE "__mj"."IntegrationObject"
SET "Description" = REPLACE("Description", 'roundSubmissions[] -> fieldValues[]',
                                       'roundSubmissions[] -> submissionFieldValues[]'),
    "APIPath"     = REPLACE("APIPath",     'roundSubmissions[].fieldValues[]',
                                       'roundSubmissions[].submissionFieldValues[]')
WHERE "Name" IN ('ApplicationFile', 'Media')
  AND "IntegrationID" IN (SELECT "ID" FROM "__mj"."Integration" WHERE "Name" = 'openwater');


-- ===================== Other =====================

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
