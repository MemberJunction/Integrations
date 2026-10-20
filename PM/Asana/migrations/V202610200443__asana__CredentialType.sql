-- Asana Connector — ship the "Asana API" credential type and point the Integration at it.
--
-- The seed (V202608051247) pointed CredentialTypeID at MJ's generic "API Key" type, whose form has ONE
-- field. The connect wizard renders only the credential type's FieldSchema, so a connection could be
-- created with a token and no workspace — and every Asana listing is workspace-scoped, so it then
-- refused to run ("Asana workspace is not configured"). The connector already reads `workspace` from a
-- credential's Values (ParseCredentialJson); this gives the wizard a field to put it in.
--
-- Two steps, both guarded so the file is a no-op where it has already applied:
--   1. create the credential type (the block is in the exact form `mj sync push` emits for
--      ../metadata/credential-type, with the IF NOT EXISTS guard this repo adds to every credential-type
--      create — ID hardcoded, audit columns not set);
--   2. re-point the Asana Integration row (fixed ID from ../metadata/integration) at it. Existing
--      connections keep their "API Key" credential and keep working through ExternalSystemID /
--      Configuration; only NEW connections see the two-field form.

-- Save MJ: Credential Types (core SP call only)
DECLARE @ID_asana01 UNIQUEIDENTIFIER,
@Name_asana01 NVARCHAR(100),
@Description_asana01 NVARCHAR(MAX),
@Category_asana01 NVARCHAR(50),
@FieldSchema_asana01 NVARCHAR(MAX),
@IconClass_asana01 NVARCHAR(100),
@ValidationEndpoint_asana01 NVARCHAR(500)
SET
  @ID_asana01 = '65D812F7-5D1F-4CFF-BD48-D45D768EFCC0'
SET
  @Name_asana01 = N'Asana API'
SET
  @Description_asana01 = N'Asana personal access token plus the workspace it may read. Every Asana listing is workspace-scoped, so the workspace gid is part of the credential, not a separate setting: without it the connector has nothing to list.'
SET
  @Category_asana01 = N'Integration'
SET
  @FieldSchema_asana01 = N'{"$schema":"http://json-schema.org/draft-07/schema#","type":"object","properties":{"apiKey":{"type":"string","title":"Personal Access Token","description":"Asana personal access token (My Settings \u2192 Apps \u2192 Developer apps \u2192 Personal access tokens). Sent as a Bearer header.","isSecret":true,"order":0},"workspace":{"type":"string","title":"Workspace GID","description":"The gid of the workspace to sync (the number in https://app.asana.com/0/<gid>/\u2026 or from GET /workspaces). One connection reads one workspace.","isSecret":false,"order":1}},"required":["apiKey","workspace"]}'
SET
  @IconClass_asana01 = N'fa-solid fa-diagram-project' IF NOT EXISTS (SELECT 1 FROM [__mj].CredentialType WHERE ID = @ID_asana01) EXEC [__mj].spCreateCredentialType @ID = @ID_asana01,
  @Name = @Name_asana01,
  @Description = @Description_asana01,
  @Category = @Category_asana01,
  @FieldSchema = @FieldSchema_asana01,
  @IconClass = @IconClass_asana01,
  @ValidationEndpoint = @ValidationEndpoint_asana01,
  @ValidationEndpoint_Clear = 1;

GO

-- The Asana Integration row now requires its own credential type.
UPDATE [__mj].Integration
SET CredentialTypeID = '65D812F7-5D1F-4CFF-BD48-D45D768EFCC0'
WHERE ID = 'DD73DD85-93F1-4D6C-A642-E5D64CFEEA04'
  AND CredentialTypeID <> '65D812F7-5D1F-4CFF-BD48-D45D768EFCC0';

GO
