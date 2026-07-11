-- ClassName modernization: catalog resolves installed connectors by
-- className == npm package name (build-connectors-catalog.mjs); this
-- connector predates the convention. Idempotent by WHERE; the driver
-- registers BOTH keys. See CRM/HubSpot V202607111920 (same defect).
UPDATE [__mj].Integration
SET ClassName = '@memberjunction/connector-mysql'
WHERE Name = 'MySQL' AND ClassName = 'MySQLConnector';
