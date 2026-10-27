-- Elevate Connector — ship the "Elevate Report API" credential type and point the Integration at it.
--
-- The seed (V202608251849) pointed CredentialTypeID at MJ's generic "API Key with Endpoint" type. The
-- connect wizard renders only the credential type's FieldSchema, so nothing described the two values
-- the connector actually reads: `SiteUrl` (Elevate is hosted per organisation — there is no shared
-- vendor host, so the connection cannot fall back to one) and `ApiKey` (carried in the BODY of every
-- Report API call as `api_key`, never a header). Both are read in ElevateConnector's auth path, which
-- throws by name when either is absent.
--
-- Two steps, both guarded so the file is a no-op where it has already applied:
--   1. create the credential type (the block is in the exact form `mj sync push` emits for
--      ../metadata/credential-type, with the IF NOT EXISTS guard this repo adds to every credential-type
--      create — ID hardcoded, audit columns not set);
--   2. re-point the Elevate Integration row (fixed ID from ../metadata/integration) at it. Existing
--      connections keep their "API Key with Endpoint" credential and keep working; only NEW connections
--      see the two-field form.

-- Save MJ: Credential Types (core SP call only)
DECLARE @ID_elevate01 UNIQUEIDENTIFIER,
@Name_elevate01 NVARCHAR(100),
@Description_elevate01 NVARCHAR(MAX),
@Category_elevate01 NVARCHAR(50),
@FieldSchema_elevate01 NVARCHAR(MAX),
@IconClass_elevate01 NVARCHAR(100),
@ValidationEndpoint_elevate01 NVARCHAR(500)
SET
  @ID_elevate01 = '3F7C1A62-9D45-4E88-B0A1-5C2E7B41D9A3'
SET
  @Name_elevate01 = N'Elevate Report API'
SET
  @Description_elevate01 = N'Elevate Report API authentication. Every read is a single POST to ''{SiteUrl}/api/reports'' with the api_key carried in the request BODY (never an Authorization header and never a URL parameter); the report is chosen by a body field and the columns by an explicit allow-list. SiteUrl is per-tenant - Elevate is hosted per organisation, so there is no shared default host.'
SET
  @Category_elevate01 = N'Integration'
SET
  @FieldSchema_elevate01 = N'{"$schema":"http://json-schema.org/draft-07/schema#","type":"object","properties":{"SiteUrl":{"type":"string","title":"Elevate Site URL","description":"Your organisation''s own Elevate address, e.g. ''https://elevate.your-org.org''. The connector calls ''{SiteUrl}/api/reports'' - Elevate is hosted per organisation, so there is no shared default.","format":"uri","order":0},"ApiKey":{"type":"string","title":"Report API Key","description":"An Elevate Report API key, issued by your Elevate administrator. One key covers every report; the connector sends it in the request body as ''api_key'' and never logs it. The reports it can reach are the ones listed at ''{SiteUrl}/api/reports''.","isSecret":true,"order":1}},"required":["SiteUrl","ApiKey"]}'
SET
  @IconClass_elevate01 = N'fa-solid fa-chart-line' IF NOT EXISTS (SELECT 1 FROM [__mj].CredentialType WHERE ID = @ID_elevate01) EXEC [__mj].spCreateCredentialType @ID = @ID_elevate01,
  @Name = @Name_elevate01,
  @Description = @Description_elevate01,
  @Category = @Category_elevate01,
  @FieldSchema = @FieldSchema_elevate01,
  @IconClass = @IconClass_elevate01,
  @ValidationEndpoint = @ValidationEndpoint_elevate01,
  @ValidationEndpoint_Clear = 1;

GO

-- The Elevate Integration row now requires its own credential type.
UPDATE [__mj].Integration
SET CredentialTypeID = '3F7C1A62-9D45-4E88-B0A1-5C2E7B41D9A3'
WHERE ID = '8E759602-0DB6-49F3-AB6A-E287A959A927'
  AND CredentialTypeID <> '3F7C1A62-9D45-4E88-B0A1-5C2E7B41D9A3';

GO
