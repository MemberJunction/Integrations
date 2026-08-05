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

UPDATE [__mj].IntegrationObject
SET Configuration =
        JSON_MODIFY(
            Configuration,
            '$.parentScope',
            JSON_QUERY(N'{"parentWsFunction":"core_cohort_get_cohorts","paramName":"cohortids","paramStyle":"array","childIdField":"cohortid","parentIdField":"id","budgetMs":20000}')
        )
WHERE Name = 'Cohort Members'
  AND ISJSON(Configuration) = 1
  AND JSON_VALUE(Configuration, '$.wsfunction') = 'core_cohort_get_cohort_members'
  AND JSON_QUERY(Configuration, '$.parentScope') IS NULL
  AND IntegrationID IN (
      SELECT i.ID
      FROM [__mj].Integration i
      WHERE i.Name = 'totara'
  );
