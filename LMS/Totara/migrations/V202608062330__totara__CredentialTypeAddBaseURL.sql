-- Totara Connector — give Totara its own credential type with a BaseURL field.
--
-- TotaraConnector.ts has always required both `base_url` and `wstoken` (zod: "Totara base_url
-- is required" / "Totara base_url must be an absolute http(s) URL"). But Totara's Integration
-- record pointed CredentialTypeID at the generic, shared "API Key" credential type — which
-- declares only a single API-key-shaped field, no BaseURL. Every connection attempt through the
-- platform's connection form was therefore structurally unable to satisfy the connector's own
-- runtime requirement, regardless of what the user entered — the same class of defect fixed for
-- OpenWater in a separate migration.
--
-- Fix: a new, Totara-specific credential type ("Totara Web Service") declaring BaseURL + Token,
-- and re-point Totara's Integration.CredentialTypeID at it.

-- Save MJ: Credential Types (core SP call only)
DECLARE @ID_totarawsct UNIQUEIDENTIFIER,
@Name_totarawsct NVARCHAR(100),
@Description_totarawsct NVARCHAR(MAX),
@Category_totarawsct NVARCHAR(50),
@FieldSchema_totarawsct NVARCHAR(MAX),
@IconClass_totarawsct NVARCHAR(100),
@ValidationEndpoint_totarawsct NVARCHAR(500)
SET
  @ID_totarawsct = 'D920FE14-B9EE-4D52-A58F-2EA963551C16'
SET
  @Name_totarawsct = N'Totara Web Service'
SET
  @Description_totarawsct = N'Totara (Moodle-based LMS) REST web service authentication. The connector POSTs to ''{BaseURL}/webservice/rest/server.php'' with wstoken injected as a request parameter (never an Authorization header). BaseURL is per-tenant - Totara is self-hosted, so there is no shared default host.'
SET
  @Category_totarawsct = N'Integration'
SET
  @FieldSchema_totarawsct = N'{"$schema":"http://json-schema.org/draft-07/schema#","type":"object","properties":{"BaseURL":{"type":"string","title":"Totara Site URL","description":"Your Totara site''s own base URL, e.g. ''https://learn.your-org.com''. The connector calls ''{BaseURL}/webservice/rest/server.php'' - Totara is self-hosted per customer, so there is no shared default.","format":"uri","order":0},"Token":{"type":"string","title":"Web Service Token (wstoken)","description":"A Totara/Moodle web service token (wstoken) for a user with the required REST function permissions. Generated in Totara under Site administration > Server > Web services > Manage tokens.","isSecret":true,"order":1}},"required":["BaseURL","Token"]}'
SET
  @IconClass_totarawsct = N'fa-solid fa-graduation-cap' IF NOT EXISTS (SELECT 1 FROM [__mj].CredentialType WHERE ID = @ID_totarawsct) EXEC [__mj].spCreateCredentialType @ID = @ID_totarawsct,
  @Name = @Name_totarawsct,
  @Description = @Description_totarawsct,
  @Category = @Category_totarawsct,
  @FieldSchema = @FieldSchema_totarawsct,
  @IconClass = @IconClass_totarawsct,
  @ValidationEndpoint = @ValidationEndpoint_totarawsct,
  @ValidationEndpoint_Clear = 1;

GO

-- Re-point Totara's Integration row at the new credential type. A raw, single-column UPDATE
-- (not the usual spUpdateIntegration call this repo's migrations otherwise use) is deliberate:
-- spUpdateIntegration takes the FULL record with no partial-update semantics, and Totara's own
-- Configuration field is a large hand-authored JSON document — reproducing it verbatim here to
-- change one unrelated column is exactly the kind of transcription risk not worth taking.
UPDATE [__mj].[Integration]
SET [CredentialTypeID] = 'D920FE14-B9EE-4D52-A58F-2EA963551C16'
WHERE [ID] = '05B89ACC-CAA1-46B0-A22C-E106A6F3F74D';

GO
