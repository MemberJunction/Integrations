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
DO $mj$
DECLARE
  p_ID_asana01 UUID;
  p_Name_asana01 VARCHAR(100);
  p_Description_asana01 TEXT;
  p_Category_asana01 VARCHAR(50);
  p_FieldSchema_asana01 TEXT;
  p_IconClass_asana01 VARCHAR(100);
  p_ValidationEndpoint_asana01 VARCHAR(500);
BEGIN
  p_ID_asana01 := '65D812F7-5D1F-4CFF-BD48-D45D768EFCC0';
  p_Name_asana01 := 'Asana API';
  p_Description_asana01 := 'Asana personal access token plus the workspace it may read. Every Asana listing is workspace-scoped, so the workspace gid is part of the credential, not a separate setting: without it the connector has nothing to list.';
  p_Category_asana01 := 'Integration';
  p_FieldSchema_asana01 := '{"$schema":"http://json-schema.org/draft-07/schema#","type":"object","properties":{"apiKey":{"type":"string","title":"Personal Access Token","description":"Asana personal access token (My Settings \u2192 Apps \u2192 Developer apps \u2192 Personal access tokens). Sent as a Bearer header.","isSecret":true,"order":0},"workspace":{"type":"string","title":"Workspace GID","description":"The gid of the workspace to sync (the number in https://app.asana.com/0/<gid>/\u2026 or from GET /workspaces). One connection reads one workspace.","isSecret":false,"order":1}},"required":["apiKey","workspace"]}';
  p_IconClass_asana01 := 'fa-solid fa-diagram-project';
  IF NOT EXISTS (SELECT 1 FROM __mj."CredentialType" WHERE "ID" = p_ID_asana01) THEN PERFORM __mj."spCreateCredentialType"(p_ID := p_ID_asana01, p_Name := p_Name_asana01, p_Description := p_Description_asana01, p_Category := p_Category_asana01, p_FieldSchema := p_FieldSchema_asana01, p_IconClass := p_IconClass_asana01, p_ValidationEndpoint := p_ValidationEndpoint_asana01, p_ValidationEndpoint_Clear := TRUE); END IF;
END $mj$;

-- The Asana Integration row now requires its own credential type.
UPDATE "__mj"."Integration"
SET "CredentialTypeID" = '65D812F7-5D1F-4CFF-BD48-D45D768EFCC0'
WHERE "ID" = 'DD73DD85-93F1-4D6C-A642-E5D64CFEEA04'
  AND "CredentialTypeID" <> '65D812F7-5D1F-4CFF-BD48-D45D768EFCC0';
