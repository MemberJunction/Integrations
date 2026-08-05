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

-- Totara: Users could never sync, because its list function is not a list function.
--
-- `core_user_get_users` declares NO pagination params, and the vendor documentation is explicit about
-- what it is for:
--     "You can search without criteria, but the function is not designed for it. It could [be] very
--      slow or timeout. The function is designed to search some specific users."
-- and, on the wildcard the seed used:
--     email ... "you can use % for searching but it may be considerably slower!"
--
-- The seeded Configuration asked exactly the question the docs say the server cannot answer —
-- `criteria[0][key]=email, criteria[0][value]=%`, i.e. "return every user in one response". Against a
-- real-sized site the server cannot build that inside the engine's FetchChangesMs budget, so the batch
-- is killed and the object syncs ZERO rows behind an otherwise-green run.
--
-- Observed live (ACR, 2026-08-04, read-only): Users and Enrolled Users each timed out 3x at 30000ms and
-- persisted 0 records, while the run reported success for those entity maps. Course-side objects synced
-- normally, so the failure looked like "this site has no people" rather than a fetch defect.
--
-- FIX. Reads route through a bounded id-window scan against the documented BULK reader
-- `core_user_get_users_by_field` (field=id, values[]) — an indexed primary-key lookup rather than a
-- search. Every request is bounded by construction, so no single call can blow the fetch budget, and the
-- connector resumes across calls via the engine's keyset channel. Windows are contiguous, so coverage is
-- complete over the range scanned; the scan stops after `maxConsecutiveEmptyWindows` consecutive empty
-- windows and ALWAYS emits an ID_WINDOW_SCAN_END warning naming the range it covered, so a premature stop
-- is visible in the run instead of silently truncating the object. Sites whose user-id gaps exceed
-- windowSize * maxConsecutiveEmptyWindows (25 * 40 = 1,000 consecutive absent ids) should raise that knob.
--
-- The window values are the ones PROVEN live, not chosen on paper. 25 ids per window x 2 windows per call
-- reads 50 users in ~2.5s — an order of magnitude inside the kill even when a window must be bisected to
-- isolate an unreadable id (25 -> 12 -> 6 -> 3 -> 2 -> 1 is 5 splits, under the default 8). Wider was tried
-- first and failed live: 200 x 5 overran the budget and was killed with 0 records, and a 200-wide window
-- containing one unreadable id could not finish its bisection inside the budget at all.
--
-- `budgetMs` (20000, under the engine's 30000ms FetchChangesMs kill) bounds the CALL, not just each request.
-- Bounding requests alone was not enough: the first live run of this scan issued windowsPerCall requests in
-- one call, overran the budget together, was killed, and persisted nothing — the same 0-row symptom. With a
-- deadline the call returns what it has scanned and resumes from its cursor on the next call, emitting
-- ID_WINDOW_BUDGET_STOP so a short batch is never mistaken for a thin id range. At least one window is
-- always attempted, so the cursor can never stall.
--
-- `defaultArgs` is deliberately LEFT IN PLACE. It is unused while idWindowScan is present (the connector
-- delegates before the single-call path) and remains the legacy fallback if the scan config is removed.
--
-- Delta migration (not a re-seed): the catalog rows already exist on installed tenants, so this UPDATEs
-- Configuration in place. No IDs are minted and no rows are created, so nothing can collide with the
-- V202607201219 seed or re-mint an applied UUID.
--
-- Idempotent by WHERE: the update is skipped once `$.idWindowScan` is present, so re-running is a no-op
-- and a tenant that has already been patched is never rewritten.
--
-- NOTE: the Integration row is named 'totara' (lowercase) — matching the seeded identity exactly.

-- HAND-AUTHORED PG BODY. The SQL Server source uses JSON_MODIFY / JSON_QUERY / ISJSON, which the
-- conversion pipeline does not translate — it emitted them as quoted identifiers ("JSON_MODIFY"(...)),
-- i.e. calls to functions that do not exist in PostgreSQL, so the converted migration would have failed
-- on every PG tenant. The jsonb equivalent below is written by hand and is semantically identical:
--   * `||` merges the two new keys into the existing object (add-or-replace, same as nested JSON_MODIFY)
--   * `-> 'idWindowScan' IS NULL` is the same idempotence guard as JSON_QUERY(...) IS NULL
-- Configuration is a text column on PG (nvarchar(max) upstream), hence the ::jsonb read / ::text write.

UPDATE "__mj"."IntegrationObject"
SET "Configuration" = (
        ("Configuration")::jsonb
        || jsonb_build_object(
               'idWindowScan',
               '{"wsFunction":"core_user_get_users_by_field","field":"id","windowSize":25,"windowsPerCall":2,"maxConsecutiveEmptyWindows":40,"budgetMs":20000,"maxBisectSplitsPerCall":8}'::jsonb,
               'idWindowScanRationale',
               to_jsonb('core_user_get_users declares NO pagination params and the vendor docs state it "could [be] very slow or timeout" without narrow criteria (and that the % wildcard "may be considerably slower"). The defaultArgs email=% bulk list is therefore a documented anti-pattern: against a real-sized site it never returns inside the engine''s FetchChangesMs budget and the object syncs ZERO rows behind a green run (observed live: 3x 30s timeouts, 0 users). Reads route through the bounded id-window scan instead - an indexed PK lookup via the documented bulk reader. defaultArgs is retained only as the legacy fallback if idWindowScan is removed.'::text)
           )
    )::text
WHERE "Name" = 'Users'
  AND ("Configuration") IS JSON
  AND ("Configuration")::jsonb ->> 'wsfunction' = 'core_user_get_users'
  AND ("Configuration")::jsonb -> 'idWindowScan' IS NULL
  AND "IntegrationID" IN (
      SELECT i."ID"
      FROM "__mj"."Integration" i
      WHERE i."Name" = 'totara'
  );
