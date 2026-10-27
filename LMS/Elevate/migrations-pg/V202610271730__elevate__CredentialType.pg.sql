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
DO $mj$
DECLARE
  p_ID_elevate01 UUID;
  p_Name_elevate01 VARCHAR(100);
  p_Description_elevate01 TEXT;
  p_Category_elevate01 VARCHAR(50);
  p_FieldSchema_elevate01 TEXT;
  p_IconClass_elevate01 VARCHAR(100);
  p_ValidationEndpoint_elevate01 VARCHAR(500);
BEGIN
  p_ID_elevate01 := '3F7C1A62-9D45-4E88-B0A1-5C2E7B41D9A3';
  p_Name_elevate01 := 'Elevate Report API';
  p_Description_elevate01 := 'Elevate Report API authentication. Every read is a single POST to ''{SiteUrl}/api/reports'' with the api_key carried in the request BODY (never an Authorization header and never a URL parameter); the report is chosen by a body field and the columns by an explicit allow-list. SiteUrl is per-tenant - Elevate is hosted per organisation, so there is no shared default host.';
  p_Category_elevate01 := 'Integration';
  p_FieldSchema_elevate01 := '{"$schema":"http://json-schema.org/draft-07/schema#","type":"object","properties":{"SiteUrl":{"type":"string","title":"Elevate Site URL","description":"Your organisation''s own Elevate address, e.g. ''https://elevate.your-org.org''. The connector calls ''{SiteUrl}/api/reports'' - Elevate is hosted per organisation, so there is no shared default.","format":"uri","order":0},"ApiKey":{"type":"string","title":"Report API Key","description":"An Elevate Report API key, issued by your Elevate administrator. One key covers every report; the connector sends it in the request body as ''api_key'' and never logs it. The reports it can reach are the ones listed at ''{SiteUrl}/api/reports''.","isSecret":true,"order":1}},"required":["SiteUrl","ApiKey"]}';
  p_IconClass_elevate01 := 'fa-solid fa-chart-line' IF NOT EXISTS (SELECT 1 FROM [__mj].CredentialType WHERE ID = @ID_elevate01);
  PERFORM __mj."spCreateCredentialType"(p_ID := p_ID_elevate01, p_Name := p_Name_elevate01, p_Description := p_Description_elevate01, p_Category := p_Category_elevate01, p_FieldSchema := p_FieldSchema_elevate01, p_IconClass := p_IconClass_elevate01, p_ValidationEndpoint := p_ValidationEndpoint_elevate01, p_ValidationEndpoint_Clear := TRUE);
END $mj$;

-- The Elevate Integration row now requires its own credential type.
UPDATE "__mj"."Integration"
SET "CredentialTypeID" = '3F7C1A62-9D45-4E88-B0A1-5C2E7B41D9A3'
WHERE "ID" = '8E759602-0DB6-49F3-AB6A-E287A959A927'
  AND "CredentialTypeID" <> '3F7C1A62-9D45-4E88-B0A1-5C2E7B41D9A3';
