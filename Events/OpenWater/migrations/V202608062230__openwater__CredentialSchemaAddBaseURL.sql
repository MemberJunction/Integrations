-- OpenWater Connector — credential schema fix: add the missing required BaseURL field, and
-- correct both BaseURL's and ClientKey's descriptions.
--
-- GetAuth() in OpenWaterConnector.ts has always required Config.BaseURL, but the credential-
-- type's own FieldSchema never declared a BaseURL property. Every connection attempt through
-- the platform's connection form was therefore structurally unable to satisfy this requirement.
-- Live repro: "OpenWater connection failed: OpenWater requires a per-tenant BaseURL ...
-- Configuration.BaseURL on the connection." on every attempt, regardless of what the user
-- entered.
--
-- BaseURL and ClientKey were also both misdescribed. OpenWater's real API host is the SHARED
-- 'https://api.secure-platform.com' (same for every customer, confirmed live against its own
-- published swagger) — NOT a per-tenant subdomain as the original text claimed. The tenant's
-- own subdomain (e.g. 'your-org.secure-platform.com') is instead what ClientKey carries, sent
-- as the 'X-ClientKey' header to identify the account against the shared host. Corrected both
-- descriptions to match.

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
  @Description_ow8062230 = N'OpenWater (awards/abstracts/event-submission) REST API. Dual custom-header auth: X-ClientKey (your OpenWater domain) + X-ApiKey (admin secret), optional X-OrganizationCode. The API host (BaseURL) is the shared https://api.secure-platform.com for every customer, not a per-tenant subdomain.'
SET
  @Category_ow8062230 = N'Authentication'
SET
  @FieldSchema_ow8062230 = N'{"$schema":"http://json-schema.org/draft-07/schema#","type":"object","properties":{"BaseURL":{"type":"string","title":"OpenWater API Host","description":"The OpenWater API host this connector calls. This is almost always the SHARED host ''https://api.secure-platform.com'' (the same value for every OpenWater customer) - NOT your own OpenWater subdomain. The legacy ''api.getopenwater.com'' host does not resolve.","order":0},"ClientKey":{"type":"string","title":"Client Key (Your OpenWater Domain)","description":"Your OpenWater tenant''s own domain, sent as the ''X-ClientKey'' header - e.g. ''your-org.secure-platform.com'' (no ''https://''). This is how OpenWater''s shared API host identifies your account; it is a different value from the API Host above.","order":1},"ApiKey":{"type":"string","title":"API Key","description":"OpenWater admin API secret, sent as the ''X-ApiKey'' header.","isSecret":true,"order":2},"OrganizationCode":{"type":"string","title":"Organization Code","description":"Optional organization scope, sent as the ''X-OrganizationCode'' header when present.","order":3}},"required":["BaseURL","ClientKey","ApiKey"]}'
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
