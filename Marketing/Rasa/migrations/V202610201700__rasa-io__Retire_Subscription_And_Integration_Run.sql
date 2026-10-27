-- rasa.io Connector v3.0.1 — remove two v2 objects that a sync cannot use.
--
--   8C8BF540-10F8-40F4-A6A5-13F5D829FDE0  Subscription     /v2/subscriptions
--       GET /v2/subscriptions requires contact_id (HTTP 400 "contact_id query parameter is required", verified
--       2026-10-20), so a bulk sync would make one request per contact. Its create/update writes go with it.
--       Seeded by V202608011359.
--   05A9DD11-DC88-4C0C-9D5F-6EDA34188877  Integration Run  /v2/integration-runs
--       An internal rasa.io endpoint, not meant for integrations (per the vendor, 2026-10-20). Seeded by
--       V202610161602.
--
-- Deleting by hardcoded ID, so this is a no-op on a database that never had them. IntegrationObjectField is
-- deleted first: it is the only table with an FK to IntegrationObject (IntegrationObjectID and
-- RelatedIntegrationObjectID). Destination tables created by these objects are NOT dropped, and no synced
-- data is deleted.

DELETE FROM [__mj].[IntegrationObjectField]
WHERE IntegrationObjectID IN (
        '8C8BF540-10F8-40F4-A6A5-13F5D829FDE0',
        '05A9DD11-DC88-4C0C-9D5F-6EDA34188877')
   OR RelatedIntegrationObjectID IN (
        '8C8BF540-10F8-40F4-A6A5-13F5D829FDE0',
        '05A9DD11-DC88-4C0C-9D5F-6EDA34188877');

DELETE FROM [__mj].[IntegrationObject]
WHERE ID IN (
        '8C8BF540-10F8-40F4-A6A5-13F5D829FDE0',
        '05A9DD11-DC88-4C0C-9D5F-6EDA34188877');
