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

-- Totara: Cohort Members failed [invalidparameter] on every run, and landed 0 rows every time.
--
-- `core_cohort_get_cohort_members` REQUIRES the cohorts to read, as an array — `cohortids[0]=7`. The seeded
-- Configuration declared no parent scope at all, so the connector dispatched the function bare, and Totara
-- answered every call with:
--     [invalidparameter] Invalid parameter value detected
-- at batch 1, identically on every run. Observed live (ACR, 2026-08-04, read-only, run 8D59A6B9): 0 records,
-- while the entity map still reported success — the same "this site has no cohort members" shape as the
-- Users defect, from a different cause.
--
-- FIX. Declare the object parent-scoped over Cohorts (`core_cohort_get_cohorts`, which — unlike the members
-- function — treats its ids as optional and lists them all). The connector already walks parents one request
-- at a time, keyset-resumable, so this only needed the scope declared plus two shape facts:
--
--   `paramStyle: array`  — send `cohortids[0]=<id>`, not a scalar `cohortids=<id>`. Moodle's plural-id
--                          functions reject the scalar form; this is the actual [invalidparameter].
--   `childIdField`       — the row's parent-FK column is SINGULAR (`cohortid`) while the request param is
--                          plural (`cohortids`). Tagging with the param name would invent a `cohortids`
--                          field that matches no declared field and leave the real FK null.
--
-- `budgetMs` (20000, under the engine's 30000ms FetchChangesMs kill) bounds the walk in TIME as well as in
-- parent count. A batch that overruns FetchChangesMs is killed and persists NOTHING, so a page cap alone is
-- not a bound — `Enrolled Users` timed out and lost every record it had already fetched for exactly that
-- reason. With the budget the call returns its partial rows plus a cursor covering only the contiguous
-- prefix of parents actually examined, and emits PARENT_BUDGET_STOP so a short batch is never silent. The
-- first parent of a call always runs, so the walk cannot stall.
--
-- Delta migration (not a re-seed): the catalog rows already exist on installed tenants, so this UPDATEs
-- Configuration in place. No IDs are minted and no rows are created.
--
-- Idempotent by WHERE: skipped once `$.parentScope` is present, so re-running is a no-op.

-- HAND-AUTHORED PG BODY. The SQL Server source uses JSON_MODIFY / JSON_QUERY / ISJSON, which the
-- conversion pipeline does not translate — it emits them as quoted identifiers ("JSON_MODIFY"(...)),
-- i.e. calls to functions that do not exist in PostgreSQL. The jsonb equivalent below is written by hand
-- and is semantically identical: `||` add-or-replaces the key (same as JSON_MODIFY), and
-- `-> 'parentScope' IS NULL` is the same idempotence guard as JSON_QUERY(...) IS NULL. Configuration is a
-- text column on PG (nvarchar(max) upstream), hence the ::jsonb read / ::text write.

UPDATE "__mj"."IntegrationObject"
SET "Configuration" = (
        ("Configuration")::jsonb
        || jsonb_build_object(
               'parentScope',
               '{"parentWsFunction":"core_cohort_get_cohorts","paramName":"cohortids","paramStyle":"array","childIdField":"cohortid","parentIdField":"id","budgetMs":20000}'::jsonb
           )
    )::text
WHERE "Name" = 'Cohort Members'
  AND ("Configuration") IS JSON
  AND ("Configuration")::jsonb ->> 'wsfunction' = 'core_cohort_get_cohort_members'
  AND ("Configuration")::jsonb -> 'parentScope' IS NULL
  AND "IntegrationID" IN (
      SELECT i."ID"
      FROM "__mj"."Integration" i
      WHERE i."Name" = 'totara'
  );
