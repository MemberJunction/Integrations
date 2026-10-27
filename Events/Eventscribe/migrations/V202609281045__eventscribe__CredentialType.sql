-- Eventscribe Connector — ship the "Eventscribe API" credential type.
--
-- The Integration row has always pointed CredentialTypeID at 81521198-EB2F-4691-87D0-FAD574914C0D
-- ("Eventscribe API"), but no migration created that credential type: the connector shipped no
-- credential-type metadata, and the seed's lookup resolved against a row that existed only in the
-- generation database. On a database without it, FK_Integration_CredentialType rejected the
-- Integration insert and the whole install failed.
--
-- The fix that reaches a FRESH install is in V202608271153 itself (the create now runs before the
-- Integration row that needs it). That seed never applied anywhere the row was missing: a failed
-- migration is rolled back and not recorded, so the next install runs the corrected file.
--
-- So this delta is a guarded no-op on every database it can reach: a fresh or previously-failed install
-- gets the row from the corrected seed, and a database that applied the old seed already had the row
-- (that is the only way the old seed could apply). It exists so the credential type ships with its own
-- migration, as the metadata-migration gate requires, and it never changes an existing row. The block
-- is in the exact form `mj sync push` emits for ../metadata/credential-type, with the IF NOT EXISTS
-- guard this repo adds to every credential-type create. ID is hardcoded; audit columns are not set.

-- Save MJ: Credential Types (core SP call only)
DECLARE @ID_175787c2 UNIQUEIDENTIFIER,
@Name_175787c2 NVARCHAR(100),
@Description_175787c2 NVARCHAR(MAX),
@Category_175787c2 NVARCHAR(50),
@FieldSchema_175787c2 NVARCHAR(MAX),
@IconClass_175787c2 NVARCHAR(100),
@ValidationEndpoint_175787c2 NVARCHAR(500)
SET
  @ID_175787c2 = '81521198-EB2F-4691-87D0-FAD574914C0D'
SET
  @Name_175787c2 = N'Eventscribe API'
SET
  @Description_175787c2 = N'Cadmium (Eventscribe) API key authentication. The connector sends the key as the ''APIKey'' query parameter on every request (never a header) and adds ''eID'' only when the connection sets one. Cadmium issues one key per product (eventScribe website/app and Assets on mycadmium.com, Education and Expo Harvester on conferenceharvester.com, Scorecard on conferenceabstracts.com); the connection test passes when the key authenticates against any of them.'
SET
  @Category_175787c2 = N'Integration'
SET
  @FieldSchema_175787c2 = N'{"$schema":"http://json-schema.org/draft-07/schema#","type":"object","properties":{"APIKey":{"type":"string","title":"API Key","description":"The Cadmium API key for ONE product - for example your eventScribe, Education Harvester or Scorecard key. Sent as the ''APIKey'' query parameter on every request (never a header). Cadmium issues one key per product, so create one connection per key.","isSecret":true,"order":0},"eID":{"type":"string","title":"Event ID (eID)","description":"Optional. Cadmium''s event id, needed only when this key is provisioned for more than one event: it is then sent as the ''eID'' query parameter and scopes every call to that event. Leave blank for a single-event key.","order":1}},"required":["APIKey"]}'
SET
  @IconClass_175787c2 = N'fa-solid fa-calendar-check' IF NOT EXISTS (SELECT 1 FROM [__mj].CredentialType WHERE ID = @ID_175787c2) EXEC [__mj].spCreateCredentialType @ID = @ID_175787c2,
  @Name = @Name_175787c2,
  @Description = @Description_175787c2,
  @Category = @Category_175787c2,
  @FieldSchema = @FieldSchema_175787c2,
  @IconClass = @IconClass_175787c2,
  @ValidationEndpoint = @ValidationEndpoint_175787c2,
  @ValidationEndpoint_Clear = 1;

GO
