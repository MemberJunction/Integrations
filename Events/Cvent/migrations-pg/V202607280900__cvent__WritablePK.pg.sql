-- ============================================================================
-- MemberJunction PostgreSQL Migration
-- Converted from SQL Server using TypeScript conversion pipeline
-- ============================================================================

-- Extensions
--
-- HAND-CORRECTED after conversion: @memberjunction/sql-converter's CORE_METADATA_BOOLEAN_COLUMNS
-- catalog lists IntegrationObject."SupportsWrite" but NOT "SupportsCreate"/"SupportsUpdate"/
-- "SupportsDelete", so the converter left those three as the SQL Server bit literals 0/1. PG rejects
-- them at APPLY time with 'column "SupportsCreate" is of type boolean but expression is of type
-- integer'. The 0s below are rewritten to FALSE by hand. Fixed upstream in MemberJunction/MJ #3294;
-- once that ships in a consumed release the converter emits FALSE itself and this note can go.

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

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = TRUE,
    "IsUniqueKey" = TRUE,
    "IsRequired" = TRUE,
    "AllowsNull" = FALSE
WHERE "Name" = 'type'
  AND "IntegrationObjectID" = '92A89974-7241-47F8-A395-08D01088820C';

-- ── 2. session-file.id ───────────────────────────────────────────────────────

DO $mj$
DECLARE
  p_ID_246f7f69 UUID;
  p_IntegrationObjectID_246f7f69 UUID;
  p_Name_246f7f69 VARCHAR(255);
  p_DisplayName_246f7f69 VARCHAR(255);
  p_Description_246f7f69 TEXT;
  p_Category_246f7f69 VARCHAR(100);
  p_Type_246f7f69 VARCHAR(100);
  p_Length_246f7f69 INTEGER;
  p_Precision_246f7f69 INTEGER;
  p_Scale_246f7f69 INTEGER;
  p_AllowsNull_246f7f69 BOOLEAN;
  p_DefaultValue_246f7f69 VARCHAR(255);
  p_IsPrimaryKey_246f7f69 BOOLEAN;
  p_IsUniqueKey_246f7f69 BOOLEAN;
  p_IsReadOnly_246f7f69 BOOLEAN;
  p_IsRequired_246f7f69 BOOLEAN;
  p_RelatedIntegrationObjectID_246f7f69 UUID;
  p_RelatedIntegrationObjectFieldName_246f7f69 VARCHAR(255);
  p_Sequence_246f7f69 INTEGER;
  p_Configuration_246f7f69 TEXT;
  p_Status_246f7f69 VARCHAR(25);
  p_IsCustom_246f7f69 BOOLEAN;
  p_MetadataSource_246f7f69 VARCHAR(20);
BEGIN
  p_ID_246f7f69 := '2D77A962-E6C1-5E19-AAC0-C1EE2A273037';
  p_IntegrationObjectID_246f7f69 := 'FE29F846-599E-49EB-99F0-54FA71722F68';
  p_Name_246f7f69 := 'id';
  p_Description_246f7f69 := 'Unique ID of the file. Fills the {fileId} path variable on update/delete.';
  p_Type_246f7f69 := 'String';
  p_AllowsNull_246f7f69 := FALSE;
  p_IsPrimaryKey_246f7f69 := TRUE;
  p_IsUniqueKey_246f7f69 := TRUE;
  p_IsReadOnly_246f7f69 := TRUE;
  p_IsRequired_246f7f69 := FALSE;
  p_Sequence_246f7f69 := 0;
  p_Status_246f7f69 := 'Active';
  p_IsCustom_246f7f69 := FALSE;
  p_MetadataSource_246f7f69 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_246f7f69, p_IntegrationObjectID := p_IntegrationObjectID_246f7f69, p_Name := p_Name_246f7f69, p_DisplayName := p_DisplayName_246f7f69, p_DisplayName_Clear := TRUE, p_Description := p_Description_246f7f69, p_Category := p_Category_246f7f69, p_Category_Clear := TRUE, p_Type := p_Type_246f7f69, p_Length := p_Length_246f7f69, p_Length_Clear := TRUE, p_Precision := p_Precision_246f7f69, p_Precision_Clear := TRUE, p_Scale := p_Scale_246f7f69, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_246f7f69, p_DefaultValue := p_DefaultValue_246f7f69, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_246f7f69, p_IsUniqueKey := p_IsUniqueKey_246f7f69, p_IsReadOnly := p_IsReadOnly_246f7f69, p_IsRequired := p_IsRequired_246f7f69, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_246f7f69, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_246f7f69, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_246f7f69, p_Configuration := p_Configuration_246f7f69, p_Configuration_Clear := TRUE, p_Status := p_Status_246f7f69, p_IsCustom := p_IsCustom_246f7f69, p_MetadataSource := p_MetadataSource_246f7f69);
END $mj$;

-- ── 3. speaker-file.id ───────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_f4d367fd UUID;
  p_IntegrationObjectID_f4d367fd UUID;
  p_Name_f4d367fd VARCHAR(255);
  p_DisplayName_f4d367fd VARCHAR(255);
  p_Description_f4d367fd TEXT;
  p_Category_f4d367fd VARCHAR(100);
  p_Type_f4d367fd VARCHAR(100);
  p_Length_f4d367fd INTEGER;
  p_Precision_f4d367fd INTEGER;
  p_Scale_f4d367fd INTEGER;
  p_AllowsNull_f4d367fd BOOLEAN;
  p_DefaultValue_f4d367fd VARCHAR(255);
  p_IsPrimaryKey_f4d367fd BOOLEAN;
  p_IsUniqueKey_f4d367fd BOOLEAN;
  p_IsReadOnly_f4d367fd BOOLEAN;
  p_IsRequired_f4d367fd BOOLEAN;
  p_RelatedIntegrationObjectID_f4d367fd UUID;
  p_RelatedIntegrationObjectFieldName_f4d367fd VARCHAR(255);
  p_Sequence_f4d367fd INTEGER;
  p_Configuration_f4d367fd TEXT;
  p_Status_f4d367fd VARCHAR(25);
  p_IsCustom_f4d367fd BOOLEAN;
  p_MetadataSource_f4d367fd VARCHAR(20);
BEGIN
  p_ID_f4d367fd := '8557A9B8-13DC-51F1-A49F-D2C2F79623B6';
  p_IntegrationObjectID_f4d367fd := 'B0E59299-939E-407F-B302-546356E63888';
  p_Name_f4d367fd := 'id';
  p_Description_f4d367fd := 'Unique ID of the file. Fills the {fileId} path variable on update/delete.';
  p_Type_f4d367fd := 'String';
  p_AllowsNull_f4d367fd := FALSE;
  p_IsPrimaryKey_f4d367fd := TRUE;
  p_IsUniqueKey_f4d367fd := TRUE;
  p_IsReadOnly_f4d367fd := TRUE;
  p_IsRequired_f4d367fd := FALSE;
  p_Sequence_f4d367fd := 0;
  p_Status_f4d367fd := 'Active';
  p_IsCustom_f4d367fd := FALSE;
  p_MetadataSource_f4d367fd := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_f4d367fd, p_IntegrationObjectID := p_IntegrationObjectID_f4d367fd, p_Name := p_Name_f4d367fd, p_DisplayName := p_DisplayName_f4d367fd, p_DisplayName_Clear := TRUE, p_Description := p_Description_f4d367fd, p_Category := p_Category_f4d367fd, p_Category_Clear := TRUE, p_Type := p_Type_f4d367fd, p_Length := p_Length_f4d367fd, p_Length_Clear := TRUE, p_Precision := p_Precision_f4d367fd, p_Precision_Clear := TRUE, p_Scale := p_Scale_f4d367fd, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_f4d367fd, p_DefaultValue := p_DefaultValue_f4d367fd, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_f4d367fd, p_IsUniqueKey := p_IsUniqueKey_f4d367fd, p_IsReadOnly := p_IsReadOnly_f4d367fd, p_IsRequired := p_IsRequired_f4d367fd, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_f4d367fd, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_f4d367fd, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_f4d367fd, p_Configuration := p_Configuration_f4d367fd, p_Configuration_Clear := TRUE, p_Status := p_Status_f4d367fd, p_IsCustom := p_IsCustom_f4d367fd, p_MetadataSource := p_MetadataSource_f4d367fd);
END $mj$;

-- ── 4. CommunicationConfiguration: an account singleton, not a record ────────

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "SupportsCreate" = FALSE,
    "Description"    = 'Communication compliance settings e.g. Configure which communication types will be tracked and logged for this account. Account-level singleton with no identifier: PUT /logs/communications/configuration addresses the account''s one configuration, and there is no collection or item id to key on. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves fail. Reads are unaffected.'
WHERE "ID" = 'B319ECCD-5044-49BF-B337-E134F5B710CE';


-- ===================== Other =====================

-- Cvent: the four writable objects that carried no primary key.
--
-- A writable IntegrationObject with no IsPrimaryKey field yields a KEYLESS derived entity. On
-- Postgres, MJ's save audit-wrapper then emits an empty record identifier and every save fails with
--     syntax error at or near ","
-- while fetch keeps succeeding — so the object reads green and persists nothing.
--
-- 1. event-feature -> STAMP `type`.
--    The vendor addresses one feature as PUT /events/{id}/features/{type}. `type` is that path
--    variable, already declared and already required. Cvent's house pattern throughout this catalog
--    is that a parent-scoped child keys on its OWN item token, never on the parent — e.g.
--    existing-seat under /events/{id}/seatings/{seatingId}/tables/{tableId}/seats keys on `id`
--    alone. This follows it.
--
-- 2-3. session-file / speaker-file -> CREATE `id` (String, read-only).
--    Both are addressed as .../docs/{fileId} on update and delete, and neither declared the field.
--    The identical sibling shape settles what {fileId} is: program-item-session-document
--    (/program-items/{programItemId}/docs, item /docs/{fileId}) declares `id` — "ID of the session
--    document" — String, read-only, primary key; so does existing-file
--    (/events/{id}/exhibitors/{exhibitorId}/files, item /files/{fileId}), "Unique ID of the file".
--    Cvent's /docs collections return an id and {fileId} is filled from it.
--
-- 4. CommunicationConfiguration -> WITHDRAW the write.
--    An account-level SINGLETON: PUT /logs/communications/configuration addresses the account's one
--    communication-compliance configuration. There is no collection, no item id, and the object
--    declares exactly one field (enabledMessageTypes) — nothing to key on, and nothing may be
--    invented. Reads are unaffected.
--
-- Created keys are IsReadOnly = 1, matching HubSpot's V202607271200 stamp of `hs_object_id` across
-- 33 objects (functionally proven on Postgres). Read-only does not stop a KEY persisting.
--
-- DELTA migration, deliberately not a re-seed: the catalog rows already exist on installed tenants,
-- so the V202606280836 seed stays untouched and applied — no existing UUID is re-minted, no Flyway
-- checksum breaks, no UQ collision. Every statement is idempotent (keyed by the seeded row ID).
-- Created fields carry UUID5 IDs derived from
--     uuid5(DNS, 'memberjunction.integrations/<integration>/<object>/<field>')
-- so regenerating this file yields byte-identical UUIDs rather than fresh random ones.

-- ── 1. event-feature: the feature type is the item token ─────────────────────
