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

-- Totara: Enrolled Users read every enrolment on a course in ONE request, and was killed for it.
--
-- The object walks parents (one call per course) and `core_enrol_get_enrolled_users` returns EVERY enrolment
-- on the course it is given, with full user profiles. On a real site a single such call does not finish
-- inside the engine's FetchChangesMs (30000ms), the batch is killed, and a killed batch persists NOTHING —
-- so the object landed 0 rows behind a green run on every live attempt (observed: 3x 30000ms timeouts).
--
-- Bounding the CALL was not sufficient, which is the point worth carrying elsewhere: a per-call deadline
-- cannot rescue a single request that is itself too big. The first parent of a call must always run, so a
-- course whose one request exceeds the budget times out no matter how the walk is scheduled.
--
-- FIX. The function documents `options.limitfrom` / `options.limitnumber` (already declared in this object's
-- paginationParams and, until now, ignored on the parent-scoped path). The walk pages WITHIN each parent at
-- `pageSize` records per request, so every request is bounded by construction. A budget stop between pages
-- resumes INTO the parent via a `"<courseid>#<offset>"` cursor rather than re-reading its first page forever.
--
-- pageSize 50 is measured, not guessed: a 250-user page took 25823ms live (~10 users/sec — the function builds
-- full user profiles), which alone blows the kill. 50 lands near 5s, small enough that the walk can start a page
-- and still stop cleanly inside its budget;
-- budgetMs 20000 sits under the 30000ms kill so the call returns partial progress with its cursor.
--
-- Delta migration (not a re-seed): UPDATEs Configuration in place; no IDs minted, no rows created.
-- Idempotent by WHERE: skipped once `$.parentScope.pageSize` is present.

-- HAND-AUTHORED PG BODY. The SQL Server source uses JSON_MODIFY / JSON_VALUE / ISJSON, which the conversion
-- pipeline does not translate (it emits them as quoted identifiers, i.e. calls to functions PostgreSQL does
-- not have). jsonb_set with create_if_missing writes the nested keys exactly as the nested JSON_MODIFY does;
-- `-> 'pageSize' IS NULL` is the same idempotence guard. Configuration is a text column on PG.

UPDATE "__mj"."IntegrationObject"
SET "Configuration" = jsonb_set(
        jsonb_set(("Configuration")::jsonb, '{parentScope,pageSize}', '50'::jsonb, true),
        '{parentScope,budgetMs}', '20000'::jsonb, true
    )::text
WHERE "Name" = 'Enrolled Users'
  AND ("Configuration") IS JSON
  AND ("Configuration")::jsonb ->> 'wsfunction' = 'core_enrol_get_enrolled_users'
  AND ("Configuration")::jsonb -> 'parentScope' -> 'pageSize' IS NULL
  AND "IntegrationID" IN (
      SELECT i."ID"
      FROM "__mj"."Integration" i
      WHERE i."Name" = 'totara'
  );
