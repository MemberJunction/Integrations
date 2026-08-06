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
  p_Description_ow8062230 := 'OpenWater (awards/abstracts/event-submission) REST API. Dual custom-header auth: X-ClientKey (your OpenWater domain) + X-ApiKey (admin secret), optional X-OrganizationCode. The API host (BaseURL) is the shared https://api.secure-platform.com for every customer, not a per-tenant subdomain.';
  p_Category_ow8062230 := 'Authentication';
  p_FieldSchema_ow8062230 := '{"$schema":"http://json-schema.org/draft-07/schema#","type":"object","properties":{"BaseURL":{"type":"string","title":"OpenWater API Host","description":"The OpenWater API host this connector calls. This is almost always the SHARED host ''https://api.secure-platform.com'' (the same value for every OpenWater customer) - NOT your own OpenWater subdomain. The legacy ''api.getopenwater.com'' host does not resolve.","order":0},"ClientKey":{"type":"string","title":"Client Key (Your OpenWater Domain)","description":"Your OpenWater tenant''s own domain, sent as the ''X-ClientKey'' header - e.g. ''your-org.secure-platform.com'' (no ''https://''). This is how OpenWater''s shared API host identifies your account; it is a different value from the API Host above.","order":1},"ApiKey":{"type":"string","title":"API Key","description":"OpenWater admin API secret, sent as the ''X-ApiKey'' header.","isSecret":true,"order":2},"OrganizationCode":{"type":"string","title":"Organization Code","description":"Optional organization scope, sent as the ''X-OrganizationCode'' header when present.","order":3}},"required":["BaseURL","ClientKey","ApiKey"]}';
  p_IconClass_ow8062230 := 'fa-solid fa-water';
  p_ID_ow8062230 := '0157AF2C-DC13-4BC9-B602-70FC2C4A6160';
  PERFORM __mj."spUpdateCredentialType"(p_Name := p_Name_ow8062230, p_Description := p_Description_ow8062230, p_Category := p_Category_ow8062230, p_FieldSchema := p_FieldSchema_ow8062230, p_IconClass := p_IconClass_ow8062230, p_ValidationEndpoint := p_ValidationEndpoint_ow8062230, p_ValidationEndpoint_Clear := TRUE, p_ID := p_ID_ow8062230);
END $mj$;
