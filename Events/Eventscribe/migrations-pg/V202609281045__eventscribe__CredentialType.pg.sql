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

-- The credential-type block below was converted by hand, in the shape this repo's other guarded
-- credential-type creates carry (OpenWater V202606271423, Totara V202608062330): the pinned
-- `mj migrate convert` turns SQL Server's `IF NOT EXISTS (...) EXEC` into a dangling IF with no THEN.
-- Everything else in this file is the converter's own output for the SQL Server migration, unchanged.

-- Save MJ: Credential Types (core SP call only)
DO $mj$
DECLARE
  p_ID_175787c2 UUID;
  p_Name_175787c2 VARCHAR(100);
  p_Description_175787c2 TEXT;
  p_Category_175787c2 VARCHAR(50);
  p_FieldSchema_175787c2 TEXT;
  p_IconClass_175787c2 VARCHAR(100);
  p_ValidationEndpoint_175787c2 VARCHAR(500);
BEGIN
  p_ID_175787c2 := '81521198-EB2F-4691-87D0-FAD574914C0D';
  p_Name_175787c2 := 'Eventscribe API';
  p_Description_175787c2 := 'Cadmium (Eventscribe) API key authentication. The connector sends the key as the ''APIKey'' query parameter on every request (never a header) and adds ''eID'' only when the connection sets one. Cadmium issues one key per product (eventScribe website/app and Assets on mycadmium.com, Education and Expo Harvester on conferenceharvester.com, Scorecard on conferenceabstracts.com); the connection test passes when the key authenticates against any of them.';
  p_Category_175787c2 := 'Integration';
  p_FieldSchema_175787c2 := '{"$schema":"http://json-schema.org/draft-07/schema#","type":"object","properties":{"APIKey":{"type":"string","title":"API Key","description":"The Cadmium API key for ONE product - for example your eventScribe, Education Harvester or Scorecard key. Sent as the ''APIKey'' query parameter on every request (never a header). Cadmium issues one key per product, so create one connection per key.","isSecret":true,"order":0},"eID":{"type":"string","title":"Event ID (eID)","description":"Optional. Cadmium''s event id, needed only when this key is provisioned for more than one event: it is then sent as the ''eID'' query parameter and scopes every call to that event. Leave blank for a single-event key.","order":1}},"required":["APIKey"]}';
  p_IconClass_175787c2 := 'fa-solid fa-calendar-check';
  IF NOT EXISTS (SELECT 1 FROM __mj."CredentialType" WHERE "ID" = p_ID_175787c2) THEN PERFORM __mj."spCreateCredentialType"(p_ID := p_ID_175787c2, p_Name := p_Name_175787c2, p_Description := p_Description_175787c2, p_Category := p_Category_175787c2, p_FieldSchema := p_FieldSchema_175787c2, p_IconClass := p_IconClass_175787c2, p_ValidationEndpoint := p_ValidationEndpoint_175787c2, p_ValidationEndpoint_Clear := TRUE); END IF;
END $mj$;
