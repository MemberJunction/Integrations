-- ============================================================================
-- MemberJunction PostgreSQL Migration
-- Converted from SQL Server using TypeScript conversion pipeline
-- ============================================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Schema
CREATE SCHEMA IF NOT EXISTS __mj;
SET search_path TO __mj, public;

-- Ensure backslashes in string literals are treated literally (not as escape sequences)
SET standard_conforming_strings = on;

-- NOTE: Earlier converter versions made INTEGER to BOOLEAN cast implicit by
-- modifying the system catalog so SS-style INSERT INTO bool_col VALUES (1)
-- would work. That modification required pg_catalog write privileges, which
-- managed PG (RDS, Aurora, Cloud SQL, Azure) does not grant. As of v5.30 all
-- bulk INSERTs are emitted with native TRUE/FALSE values directly, so the
-- cast modification is no longer needed. Removed to support managed-PG
-- installs out of the box.


-- ===================== Data (INSERT/UPDATE/DELETE) =====================

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
DO $mj$
DECLARE
  p_Name_ow8062230 VARCHAR(100);
  p_Description_ow8062230 TEXT;
  p_Category_ow8062230 VARCHAR(50);
  p_FieldSchema_ow8062230 TEXT;
  p_IconClass_ow8062230 VARCHAR(100);
  p_ValidationEndpoint_ow8062230 VARCHAR(500);
  p_ID_ow8062230 UUID;
BEGIN
  p_Name_ow8062230 := 'OpenWater API';
  p_Description_ow8062230 := 'OpenWater (awards/abstracts/event-submission) REST API. Dual custom-header auth: X-ClientKey + X-ApiKey (a secret pair issued together by OpenWater support), optional X-OrganizationCode. Requires the tenant''s per-tenant API host (BaseURL) — OpenWater has no shared default host.';
  p_Category_ow8062230 := 'Authentication';
  p_FieldSchema_ow8062230 := '{"$schema":"http://json-schema.org/draft-07/schema#","type":"object","properties":{"BaseURL":{"type":"string","title":"OpenWater API Host","description":"Your OpenWater tenant''s API host, used for every request this connector makes - e.g. ''https://your-org.secure-platform.com''. OpenWater is white-labeled per tenant; there is no shared default host.","order":0},"ClientKey":{"type":"string","title":"Client Key","description":"OpenWater API secret, sent as the ''X-ClientKey'' header. OpenWater issues this alongside the API Key from your account manager or support, as a genuinely separate value from both the API Key and the API Host above - requests to OpenWater often come back with only one of the two keys, so ask explicitly for both.","isSecret":true,"order":1},"ApiKey":{"type":"string","title":"API Key","description":"OpenWater API secret, sent as the ''X-ApiKey'' header. Issued together with the Client Key above.","isSecret":true,"order":2},"OrganizationCode":{"type":"string","title":"Organization Code","description":"Optional organization scope, sent as the ''X-OrganizationCode'' header when present.","order":3}},"required":["BaseURL","ClientKey","ApiKey"]}';
  p_IconClass_ow8062230 := 'fa-solid fa-water';
  p_ID_ow8062230 := '0157AF2C-DC13-4BC9-B602-70FC2C4A6160';
  PERFORM __mj."spUpdateCredentialType"(p_Name := p_Name_ow8062230, p_Description := p_Description_ow8062230, p_Category := p_Category_ow8062230, p_FieldSchema := p_FieldSchema_ow8062230, p_IconClass := p_IconClass_ow8062230, p_ValidationEndpoint := p_ValidationEndpoint_ow8062230, p_ValidationEndpoint_Clear := TRUE, p_ID := p_ID_ow8062230);
END $mj$;
