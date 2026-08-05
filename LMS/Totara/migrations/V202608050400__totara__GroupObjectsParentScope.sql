-- Totara: `Groups`, `Groupings` and `Group Members` were dispatched with no parent scope at all.
--
-- All three declared a BY-ID reader as their list function:
--   core_group_get_groups(groupids[]) / core_group_get_groupings(groupingids[]) / core_group_get_group_members(groupids[])
-- A by-id reader answers with the records you already name. Dispatched bare, as these shipped, Moodle replies
-- [invalidparameter] and the object lands 0 rows on every run — the identical defect `Cohort Members` had
-- (V202608041720), which is now fixed and proven live at 97 rows.
--
-- The fix is not the same for all three, because Moodle does not offer the same escape from each:
--
--   * Groups / Groupings — nothing in Moodle lists a site's groups or groupings. The only enumerators are
--     per-course (core_group_get_course_groups / core_group_get_course_groupings), and they return the FULL
--     record, not just an id. So the read function itself is switched to the per-course enumerator and the
--     object is parent-scoped over `core_course_get_courses` — one hop, the same shape as `Course Contents`.
--     Write functions are untouched (core_group_create_groups etc. remain as declared).
--
--   * Group Members — core_group_get_group_members takes group ids, and per the above nothing enumerates
--     them site-wide, so reaching a single id takes TWO hops:
--         core_course_get_courses -> core_group_get_course_groups(courseid) -> group ids -> members
--     Expressed as a parentScope nested inside a parentScope; the connector resolves the chain recursively
--     (added in the same change as this migration) under the same wall-clock budget as the walk, and reports
--     PARENT_CHAIN_TRUNCATED rather than silently walking a short list.
--
-- HONEST LIMIT, stated because it is the whole reason this sat open: all three objects are [accessexception]
-- on the only live Totara site available (ACR), so this ships CORRECT BY THE VENDOR'S DOCUMENTED CONTRACT and
-- covered by unit tests, but it is NOT proven live. It is not a guess at a parent chain — the chain is the one
-- Moodle documents — but the first site whose token can read these objects should confirm row counts before
-- this is described as working.
--
-- Delta migration: the catalog rows exist on installed tenants, so this UPDATEs Configuration in place.
-- Idempotent (each statement guards on the value it is replacing); re-running is a no-op.

-- 1. Groups: read via the per-course enumerator, scoped over Courses.
UPDATE o
SET o.Configuration = JSON_MODIFY(
        JSON_MODIFY(o.Configuration, '$.wsfunction', 'core_group_get_course_groups'),
        '$.parentScope',
        JSON_QUERY(N'{"parentWsFunction":"core_course_get_courses","paramName":"courseid","paramStyle":"scalar","childIdField":"courseid","parentIdField":"id","budgetMs":20000}')),
    o.DefaultQueryParams = N'wsfunction=core_group_get_course_groups&moodlewsrestformat=json'
FROM [__mj].IntegrationObject o
JOIN [__mj].Integration i ON i.ID = o.IntegrationID
WHERE i.Name = 'totara'
  AND o.Name = 'Groups'
  AND ISJSON(o.Configuration) = 1
  AND JSON_VALUE(o.Configuration, '$.wsfunction') = 'core_group_get_groups';

-- 2. Groupings: same shape.
UPDATE o
SET o.Configuration = JSON_MODIFY(
        JSON_MODIFY(o.Configuration, '$.wsfunction', 'core_group_get_course_groupings'),
        '$.parentScope',
        JSON_QUERY(N'{"parentWsFunction":"core_course_get_courses","paramName":"courseid","paramStyle":"scalar","childIdField":"courseid","parentIdField":"id","budgetMs":20000}')),
    o.DefaultQueryParams = N'wsfunction=core_group_get_course_groupings&moodlewsrestformat=json'
FROM [__mj].IntegrationObject o
JOIN [__mj].Integration i ON i.ID = o.IntegrationID
WHERE i.Name = 'totara'
  AND o.Name = 'Groupings'
  AND ISJSON(o.Configuration) = 1
  AND JSON_VALUE(o.Configuration, '$.wsfunction') = 'core_group_get_groupings';

-- 3. Group Members: keeps its own read function, gains the two-hop chain that can name a group id.
UPDATE o
SET o.Configuration = JSON_MODIFY(o.Configuration, '$.parentScope',
        JSON_QUERY(N'{"parentWsFunction":"core_group_get_course_groups","paramName":"groupids","paramStyle":"array","childIdField":"groupid","parentIdField":"id","budgetMs":20000,"parentScope":{"parentWsFunction":"core_course_get_courses","paramName":"courseid","paramStyle":"scalar","parentIdField":"id"}}'))
FROM [__mj].IntegrationObject o
JOIN [__mj].Integration i ON i.ID = o.IntegrationID
WHERE i.Name = 'totara'
  AND o.Name = 'Group Members'
  AND ISJSON(o.Configuration) = 1
  AND JSON_VALUE(o.Configuration, '$.wsfunction') = 'core_group_get_group_members'
  AND JSON_QUERY(o.Configuration, '$.parentScope') IS NULL;
