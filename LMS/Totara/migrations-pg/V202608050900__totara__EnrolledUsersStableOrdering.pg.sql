-- Totara: `Enrolled Users` paged with `limitfrom`/`limitnumber` and NO `ORDER BY`.
-- Postgres twin of V202608050900__totara__EnrolledUsersStableOrdering.sql — see that file for the full
-- rationale, the measured 1.74x re-read on live run 9200B480, and the vendor citation for sortby/sortdirection.
--
-- Idempotent — guarded on the key being absent; re-running is a no-op.

UPDATE "__mj"."IntegrationObject" o
SET "Configuration" = jsonb_set(
        ("Configuration")::jsonb,
        '{orderingParams}',
        '["options.sortby","options.sortdirection"]'::jsonb,
        true)::text
FROM "__mj"."Integration" i
WHERE i."ID" = o."IntegrationID"
  AND i."Name" = 'totara'
  AND o."Name" = 'Enrolled Users'
  AND (o."Configuration") IS JSON
  AND (o."Configuration")::jsonb ->> 'wsfunction' = 'core_enrol_get_enrolled_users'
  AND (o."Configuration")::jsonb -> 'orderingParams' IS NULL;
