-- HubSpot ClassName modernization: the catalog resolves installed connectors by
-- className == npm package name (build-connectors-catalog.mjs), but HubSpot
-- predates that convention and seeded 'HubSpotConnector'. Existing installs
-- therefore never matched instance discovery and the catalog card never
-- flipped to installed. Idempotent by WHERE; the driver registers BOTH keys.
UPDATE [__mj].Integration
SET ClassName = '@memberjunction/connector-hubspot'
WHERE Name = 'HubSpot' AND ClassName = 'HubSpotConnector';
