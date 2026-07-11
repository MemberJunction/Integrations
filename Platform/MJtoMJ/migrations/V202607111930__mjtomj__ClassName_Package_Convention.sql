-- ClassName modernization: catalog resolves installed connectors by
-- className == npm package name (build-connectors-catalog.mjs); this
-- connector predates the convention. Idempotent by WHERE (no-op when no
-- legacy row was ever seeded). See CRM/HubSpot V202607111920.
UPDATE [__mj].Integration
SET ClassName = '@memberjunction/connector-mj-to-mj'
WHERE Name = 'MJ to MJ' AND ClassName = 'MJToMJConnector';
