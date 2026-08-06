-- OpenWater Connector — credential schema fix: add the missing required BaseURL field, and
-- correct ClientKey's description.
--
-- GetAuth() in OpenWaterConnector.ts has always required Config.BaseURL (the per-tenant API
-- host, e.g. https://<org>.secure-platform.com — OpenWater has no shared default host), but
-- the credential-type's own FieldSchema never declared a BaseURL property. Every connection
-- attempt through the platform's connection form was therefore structurally unable to satisfy
-- this requirement. Live repro: "OpenWater connection failed: OpenWater requires a per-tenant
-- BaseURL ... Configuration.BaseURL on the connection." on every attempt, regardless of what
-- the user entered.
--
-- ClientKey's description also claimed it was "the tenant domain" — wrong per the connector's
-- own credential-setup.html, which documents ClientKey and ApiKey as a genuinely separate
-- secret PAIR that OpenWater issues together from account-manager/support (and warns support
-- often sends only one of the two). Corrected to match that doc, which is the one users
-- actually follow to obtain these values.

-- Save MJ: Credential Types (core SP call only)
DECLARE @Name_ow8062230 NVARCHAR(100),
@Description_ow8062230 NVARCHAR(MAX),
@Category_ow8062230 NVARCHAR(50),
@FieldSchema_ow8062230 NVARCHAR(MAX),
@IconClass_ow8062230 NVARCHAR(100),
@ValidationEndpoint_ow8062230 NVARCHAR(500),
@ID_ow8062230 UNIQUEIDENTIFIER
SET
  @Name_ow8062230 = N'OpenWater API'
SET
  @Description_ow8062230 = N'OpenWater (awards/abstracts/event-submission) REST API. Dual custom-header auth: X-ClientKey + X-ApiKey (a secret pair issued together by OpenWater support), optional X-OrganizationCode. Requires the tenant''s per-tenant API host (BaseURL) — OpenWater has no shared default host.'
SET
  @Category_ow8062230 = N'Authentication'
SET
  @FieldSchema_ow8062230 = N'{"$schema":"http://json-schema.org/draft-07/schema#","type":"object","properties":{"BaseURL":{"type":"string","title":"OpenWater API Host","description":"Your OpenWater tenant''s API host, used for every request this connector makes - e.g. ''https://your-org.secure-platform.com''. OpenWater is white-labeled per tenant; there is no shared default host.","order":0},"ClientKey":{"type":"string","title":"Client Key","description":"OpenWater API secret, sent as the ''X-ClientKey'' header. OpenWater issues this alongside the API Key from your account manager or support, as a genuinely separate value from both the API Key and the API Host above - requests to OpenWater often come back with only one of the two keys, so ask explicitly for both.","isSecret":true,"order":1},"ApiKey":{"type":"string","title":"API Key","description":"OpenWater API secret, sent as the ''X-ApiKey'' header. Issued together with the Client Key above.","isSecret":true,"order":2},"OrganizationCode":{"type":"string","title":"Organization Code","description":"Optional organization scope, sent as the ''X-OrganizationCode'' header when present.","order":3}},"required":["BaseURL","ClientKey","ApiKey"]}'
SET
  @IconClass_ow8062230 = N'fa-solid fa-water'
SET
  @ID_ow8062230 = '0157AF2C-DC13-4BC9-B602-70FC2C4A6160' EXEC [__mj].spUpdateCredentialType @Name = @Name_ow8062230,
  @Description = @Description_ow8062230,
  @Category = @Category_ow8062230,
  @FieldSchema = @FieldSchema_ow8062230,
  @IconClass = @IconClass_ow8062230,
  @ValidationEndpoint = @ValidationEndpoint_ow8062230,
  @ValidationEndpoint_Clear = 1,
  @ID = @ID_ow8062230;

GO
