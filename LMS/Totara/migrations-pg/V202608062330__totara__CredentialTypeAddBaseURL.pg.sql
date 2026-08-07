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
--
-- NOTE: this file was HAND-WRITTEN, not tool-generated. scripts/build-pg-migrations.mjs
-- currently mis-converts the `IF NOT EXISTS (...) EXEC spCreateX ...` shape (regression
-- confirmed by regenerating an existing, already-shipped, previously-correct twin with the
-- current tool and getting the same broken output) — it emits an invalid dangling IF with no
-- THEN/END IF. This file matches the shape the tool correctly produced before that regression
-- (verified against NetForum's committed twin), substituting only the Totara-specific values.

-- Save MJ: Credential Types (core SP call only)
DO $mj$
DECLARE
  p_ID_totarawsct UUID;
  p_Name_totarawsct VARCHAR(100);
  p_Description_totarawsct TEXT;
  p_Category_totarawsct VARCHAR(50);
  p_FieldSchema_totarawsct TEXT;
  p_IconClass_totarawsct VARCHAR(100);
  p_ValidationEndpoint_totarawsct VARCHAR(500);
BEGIN
  p_ID_totarawsct := 'D920FE14-B9EE-4D52-A58F-2EA963551C16';
  p_Name_totarawsct := 'Totara Web Service';
  p_Description_totarawsct := 'Totara (Moodle-based LMS) REST web service authentication. The connector POSTs to ''{BaseURL}/webservice/rest/server.php'' with wstoken injected as a request parameter (never an Authorization header). BaseURL is per-tenant - Totara is self-hosted, so there is no shared default host.';
  p_Category_totarawsct := 'Integration';
  p_FieldSchema_totarawsct := '{"$schema":"http://json-schema.org/draft-07/schema#","type":"object","properties":{"BaseURL":{"type":"string","title":"Totara Site URL","description":"Your Totara site''s own base URL, e.g. ''https://learn.your-org.com''. The connector calls ''{BaseURL}/webservice/rest/server.php'' - Totara is self-hosted per customer, so there is no shared default.","format":"uri","order":0},"Token":{"type":"string","title":"Web Service Token (wstoken)","description":"A Totara/Moodle web service token (wstoken) for a user with the required REST function permissions. Generated in Totara under Site administration > Server > Web services > Manage tokens.","isSecret":true,"order":1}},"required":["BaseURL","Token"]}';
  p_IconClass_totarawsct := 'fa-solid fa-graduation-cap';
  IF NOT EXISTS (SELECT 1 FROM __mj."CredentialType" WHERE "ID" = p_ID_totarawsct) THEN PERFORM __mj."spCreateCredentialType"(p_ID := p_ID_totarawsct, p_Name := p_Name_totarawsct, p_Description := p_Description_totarawsct, p_Category := p_Category_totarawsct, p_FieldSchema := p_FieldSchema_totarawsct, p_IconClass := p_IconClass_totarawsct, p_ValidationEndpoint := p_ValidationEndpoint_totarawsct, p_ValidationEndpoint_Clear := TRUE); END IF;
END $mj$;

-- Re-point Totara's Integration row at the new credential type. A raw, single-column UPDATE
-- (not the usual spUpdateIntegration call this repo's migrations otherwise use) is deliberate:
-- spUpdateIntegration takes the FULL record with no partial-update semantics, and Totara's own
-- Configuration field is a large hand-authored JSON document — reproducing it verbatim here to
-- change one unrelated column is exactly the kind of transcription risk not worth taking.
UPDATE __mj."Integration"
SET "CredentialTypeID" = 'D920FE14-B9EE-4D52-A58F-2EA963551C16'
WHERE "ID" = '05B89ACC-CAA1-46B0-A22C-E106A6F3F74D';
