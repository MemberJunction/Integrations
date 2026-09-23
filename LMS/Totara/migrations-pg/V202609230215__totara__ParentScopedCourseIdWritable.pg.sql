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

-- Totara: parent-scoped `courseid` must be writable, so the sync can persist what the fetch injected.
--
-- THE DEFECT. Totara's parent-iteration fetch injects the parent foreign key (`courseid`) into every
-- child record of a parent-scoped object. Those `courseid` fields were declared `IsReadOnly = 1`.
-- CodeGen omits a read-only field from the generated create/update procedures, so there was no
-- parameter for the injected value to land in, and every save failed with
--     @courseid is not a parameter for procedure spCreateCourse_Contents
-- A successful fetch that persists nothing: the run looks healthy and the table stays empty.
--
-- WHY MAKING IT WRITABLE IS SAFE. This is a read-only PULL connector. `courseid` is written INTO
-- MemberJunction and is never sent back to Totara, so `IsReadOnly = 0` changes nothing about what
-- the connector asks the vendor for. Read scope is unchanged — full-record pass-through and the
-- never-shrink sample union still surface every field.
--
-- WHY A MIGRATION AND NOT JUST THE METADATA. metadata/integration/.totara.integration.json is the
-- AUTHORING source; it reaches no tenant on its own. An upgrade applies only new migrations and a
-- fresh install runs the seed, so a metadata-only change is invisible to every existing tenant
-- (scripts/require-metadata-migration.mjs enforces exactly this, and failed this branch without it).
--
-- SCOPE. Three objects, one field each — the three whose `courseid` actually flips in this change:
-- Enrolled Users, Enrolled User Roles, Enrolled User Groups. Other objects already carried a
-- writable `courseid` and are deliberately untouched.
--
-- Rows are resolved with LOWER(...) so the predicates do not depend on collation — see
-- scripts/lint-migration-name-case.mjs and the 2026-09-13 PostgreSQL incident. The
-- `IsReadOnly = 1` predicate makes a re-run a no-op rather than a second write. Audit columns are
-- not set. No object, field, or row is created or removed.
--
-- SHAPE: `WHERE IntegrationObjectID IN (SELECT ...)`, deliberately NOT `UPDATE f ... FROM ... JOIN`.
-- The T-SQL update-through-alias form is not portable, and scripts/build-pg-migrations.mjs converts
-- it literally: it emitted `UPDATE f SET f."IsReadOnly" = FALSE FROM "__mj"."IntegrationObjectField" f`,
-- where `f` is not a relation and the target is repeated in the FROM list — invalid on PostgreSQL,
-- and invalid silently, because the converter checks identifier translation rather than syntax. That
-- is the same class of defect as the OpenWater `Incorrect syntax near 'END'` migration, on the other
-- dialect. The subquery form below is valid in both dialects, so the converter only has to requote
-- identifiers.

UPDATE "__mj"."IntegrationObjectField"
SET "IsReadOnly" = FALSE
WHERE "IsReadOnly" = TRUE
  AND LOWER("Name") = 'courseid'
  AND "IntegrationObjectID" IN (
        SELECT o."ID"
        FROM "__mj"."IntegrationObject" o
        JOIN "__mj"."Integration" i ON i."ID" = o."IntegrationID"
        WHERE LOWER(i."Name") = 'totara'
          AND LOWER(o."Name") IN ('enrolled users', 'enrolled user roles', 'enrolled user groups')
      );
