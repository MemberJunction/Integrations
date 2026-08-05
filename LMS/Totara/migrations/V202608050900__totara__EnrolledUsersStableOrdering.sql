-- Totara: `Enrolled Users` paged with `limitfrom`/`limitnumber` and NO `ORDER BY`.
--
-- limitfrom/limitnumber is SQL OFFSET/LIMIT. An offset over a result set with no ORDER BY has no defined page
-- boundary: consecutive pages may repeat rows and, worse, may never return others at all. Overlap costs time;
-- the gaps are silent data loss behind a run that reports success.
--
-- MEASURED, not inferred. Live read-only run 9200B480 against the client site fetched 50,608 `Enrolled Users`
-- records and produced 29,002 distinct keyed rows — a 1.74x re-read — with only 3 INSERT and 18 UPDATE run
-- details logged; the remainder were content-hash skips of rows already present. (Part of that 1.74x was a
-- second, separate defect in the connector's concurrent resume, fixed in the same change as this migration.)
--
-- Both halves of the fix already existed and nothing joined them:
--   * the catalog has declared `stableOrderingKey: "id"` on this object since it shipped, and
--   * Totara/Moodle documents `sortby` (id|firstname|lastname|siteorder) and `sortdirection` (ASC|DESC) as
--     options on core_enrol_get_enrolled_users, listed beside limitfrom/limitnumber.
--     Citation: packages/Integration/connectors-registry/totara/sources/totara-webservices-api-documentation.html#core_enrol_get_enrolled_users
--
-- `orderingParams` names the two option params so the connector can send them. The names are per-wsfunction and
-- are read from the catalog, never guessed — an object that declares no `orderingParams` is unchanged, which is
-- why this migration touches exactly one object. (`Messages` is the only other Offset-paged object here and it
-- orders by its own documented `newestfirst`, not sortby.)
--
-- Delta migration: the catalog row exists on installed tenants, so this UPDATEs Configuration in place.
-- Idempotent — guarded on the key being absent; re-running is a no-op.

UPDATE o
SET o.Configuration = JSON_MODIFY(o.Configuration, '$.orderingParams',
        JSON_QUERY(N'["options.sortby","options.sortdirection"]'))
FROM [__mj].IntegrationObject o
JOIN [__mj].Integration i ON i.ID = o.IntegrationID
WHERE i.Name = 'totara'
  AND o.Name = 'Enrolled Users'
  AND ISJSON(o.Configuration) = 1
  AND JSON_VALUE(o.Configuration, '$.wsfunction') = 'core_enrol_get_enrolled_users'
  AND JSON_QUERY(o.Configuration, '$.orderingParams') IS NULL;
