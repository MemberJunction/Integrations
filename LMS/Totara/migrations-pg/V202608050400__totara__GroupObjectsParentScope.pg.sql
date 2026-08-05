-- Totara: `Groups`, `Groupings` and `Group Members` were dispatched with no parent scope at all.
--
-- See the SQL Server twin (V202608050400) for the full reasoning. In short: all three declared a BY-ID reader
-- (core_group_get_groups / core_group_get_groupings / core_group_get_group_members) as their LIST function.
-- A by-id reader answers with the records you already name, so dispatched bare it returns [invalidparameter]
-- and the object lands 0 rows on every run — the same defect `Cohort Members` had (V202608041720).
--
-- Groups/Groupings switch to Moodle's only enumerators, which are per-course, and are scoped over Courses.
-- Group Members keeps its function and gains a TWO-hop chain (courses -> that course's groups -> group ids),
-- expressed as a parentScope nested inside a parentScope.
--
-- NOT PROVEN LIVE: all three are [accessexception] on the only Totara site available, so this is correct by
-- the vendor's documented contract and covered by unit tests, but unconfirmed against real rows.
--
-- HAND-AUTHORED PG BODY, same reason as V202608041720 / V202608050300: the SQL Server source uses
-- JSON_MODIFY / ISJSON / JSON_VALUE / JSON_QUERY, which the conversion pipeline does not translate — it emits
-- them as quoted identifiers, i.e. calls to functions that do not exist in PostgreSQL. `build-pg-migrations.mjs`
-- now FAILS generation on that shape rather than shipping it, so this hand-authored twin is the enforced path.
-- Configuration is a text column on PG, hence the ::jsonb read / ::text write.
--
-- Idempotent (each statement guards on the value it is replacing); re-running is a no-op.

-- 1. Groups: read via the per-course enumerator, scoped over Courses.
UPDATE "__mj"."IntegrationObject" o
SET "Configuration" = jsonb_set(
        jsonb_set(("Configuration")::jsonb, '{wsfunction}', '"core_group_get_course_groups"'::jsonb, true),
        '{parentScope}',
        '{"parentWsFunction":"core_course_get_courses","paramName":"courseid","paramStyle":"scalar","childIdField":"courseid","parentIdField":"id","budgetMs":20000}'::jsonb,
        true)::text,
    "DefaultQueryParams" = 'wsfunction=core_group_get_course_groups&moodlewsrestformat=json'
FROM "__mj"."Integration" i
WHERE i."ID" = o."IntegrationID"
  AND i."Name" = 'totara'
  AND o."Name" = 'Groups'
  AND (o."Configuration") IS JSON
  AND (o."Configuration")::jsonb ->> 'wsfunction' = 'core_group_get_groups';

-- 2. Groupings: same shape.
UPDATE "__mj"."IntegrationObject" o
SET "Configuration" = jsonb_set(
        jsonb_set(("Configuration")::jsonb, '{wsfunction}', '"core_group_get_course_groupings"'::jsonb, true),
        '{parentScope}',
        '{"parentWsFunction":"core_course_get_courses","paramName":"courseid","paramStyle":"scalar","childIdField":"courseid","parentIdField":"id","budgetMs":20000}'::jsonb,
        true)::text,
    "DefaultQueryParams" = 'wsfunction=core_group_get_course_groupings&moodlewsrestformat=json'
FROM "__mj"."Integration" i
WHERE i."ID" = o."IntegrationID"
  AND i."Name" = 'totara'
  AND o."Name" = 'Groupings'
  AND (o."Configuration") IS JSON
  AND (o."Configuration")::jsonb ->> 'wsfunction' = 'core_group_get_groupings';

-- 3. Group Members: keeps its own read function, gains the two-hop chain that can name a group id.
UPDATE "__mj"."IntegrationObject" o
SET "Configuration" = jsonb_set(
        ("Configuration")::jsonb,
        '{parentScope}',
        '{"parentWsFunction":"core_group_get_course_groups","paramName":"groupids","paramStyle":"array","childIdField":"groupid","parentIdField":"id","budgetMs":20000,"parentScope":{"parentWsFunction":"core_course_get_courses","paramName":"courseid","paramStyle":"scalar","parentIdField":"id"}}'::jsonb,
        true)::text
FROM "__mj"."Integration" i
WHERE i."ID" = o."IntegrationID"
  AND i."Name" = 'totara'
  AND o."Name" = 'Group Members'
  AND (o."Configuration") IS JSON
  AND (o."Configuration")::jsonb ->> 'wsfunction' = 'core_group_get_group_members'
  AND (o."Configuration")::jsonb -> 'parentScope' IS NULL;
