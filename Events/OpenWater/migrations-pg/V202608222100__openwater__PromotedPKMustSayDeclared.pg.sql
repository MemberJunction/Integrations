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
      WHERE i."Name" = 'openwater' AND o."Name" = 'JudgeAssignment');
