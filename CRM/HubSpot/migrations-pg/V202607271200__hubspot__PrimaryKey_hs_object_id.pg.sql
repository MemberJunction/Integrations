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

-- HubSpot: correct the primary key to `hs_object_id` on 33 CRM objects (was `id`).
--
-- The static catalog declared `id` as the PK, but the connector's DiscoverFields declares — and the
-- sync path populates — `hs_object_id` (read out of the properties bag). The top-level `id` column is
-- never written. With `id` as the PK the generated spCreate ends with a read-back
--     SELECT ... WHERE [id] = @id
-- and `@id` is NULL. In SQL `x = NULL` is never true, so the read-back matched ZERO rows, the create
-- was treated as failed ("Error creating new record, no rows returned from SQL"), and the object
-- synced 0 rows — silently, with no meaningful error surfaced.
--
-- This is a DELTA migration, deliberately NOT a re-seed. The V202607092028 seed stays untouched and
-- applied: no existing UUID is re-minted, no applied migration is deleted, so there is no Flyway
-- checksum break and no UQ_IntegrationObject_Name collision on tenants already running HubSpot.
--
-- It does two things per object:
--   1. CREATE the `hs_object_id` catalog field (it does not exist on installed tenants) — guarded by
--      NOT EXISTS, so re-application is a no-op.
--   2. Clear IsPrimaryKey on the object's `id` field.
--
-- The new field IDs are UUID5-derived from a fixed namespace, so this file is reproducible:
-- regenerating it yields byte-identical UUIDs rather than fresh random ones.

-- ── appointments ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_9ffcda32 UUID;
  p_IntegrationObjectID_9ffcda32 UUID;
  p_Name_9ffcda32 VARCHAR(255);
  p_DisplayName_9ffcda32 VARCHAR(255);
  p_Description_9ffcda32 TEXT;
  p_Category_9ffcda32 VARCHAR(100);
  p_Type_9ffcda32 VARCHAR(100);
  p_Length_9ffcda32 INTEGER;
  p_Precision_9ffcda32 INTEGER;
  p_Scale_9ffcda32 INTEGER;
  p_AllowsNull_9ffcda32 BOOLEAN;
  p_DefaultValue_9ffcda32 VARCHAR(255);
  p_IsPrimaryKey_9ffcda32 BOOLEAN;
  p_IsUniqueKey_9ffcda32 BOOLEAN;
  p_IsReadOnly_9ffcda32 BOOLEAN;
  p_IsRequired_9ffcda32 BOOLEAN;
  p_RelatedIntegrationObjectID_9ffcda32 UUID;
  p_RelatedIntegrationObjectFieldName_9ffcda32 VARCHAR(255);
  p_Sequence_9ffcda32 INTEGER;
  p_Configuration_9ffcda32 TEXT;
  p_Status_9ffcda32 VARCHAR(25);
  p_IsCustom_9ffcda32 BOOLEAN;
  p_MetadataSource_9ffcda32 VARCHAR(20);
BEGIN
  p_ID_9ffcda32 := '9FFCDA32-B51A-5AE8-9B9F-681987C33703';
  p_IntegrationObjectID_9ffcda32 := '8E0BC677-A3CA-4D46-B5AD-5FB561F4EAB6';
  p_Name_9ffcda32 := 'hs_object_id';
  p_Description_9ffcda32 := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_9ffcda32 := 'string';
  p_AllowsNull_9ffcda32 := FALSE;
  p_IsPrimaryKey_9ffcda32 := TRUE;
  p_IsUniqueKey_9ffcda32 := TRUE;
  p_IsReadOnly_9ffcda32 := TRUE;
  p_IsRequired_9ffcda32 := FALSE;
  p_Sequence_9ffcda32 := 0;
  p_Status_9ffcda32 := 'Active';
  p_IsCustom_9ffcda32 := FALSE;
  p_MetadataSource_9ffcda32 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_9ffcda32, p_IntegrationObjectID := p_IntegrationObjectID_9ffcda32, p_Name := p_Name_9ffcda32, p_DisplayName := p_DisplayName_9ffcda32, p_DisplayName_Clear := TRUE, p_Description := p_Description_9ffcda32, p_Category := p_Category_9ffcda32, p_Category_Clear := TRUE, p_Type := p_Type_9ffcda32, p_Length := p_Length_9ffcda32, p_Length_Clear := TRUE, p_Precision := p_Precision_9ffcda32, p_Precision_Clear := TRUE, p_Scale := p_Scale_9ffcda32, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_9ffcda32, p_DefaultValue := p_DefaultValue_9ffcda32, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_9ffcda32, p_IsUniqueKey := p_IsUniqueKey_9ffcda32, p_IsReadOnly := p_IsReadOnly_9ffcda32, p_IsRequired := p_IsRequired_9ffcda32, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_9ffcda32, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_9ffcda32, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_9ffcda32, p_Configuration := p_Configuration_9ffcda32, p_Configuration_Clear := TRUE, p_Status := p_Status_9ffcda32, p_IsCustom := p_IsCustom_9ffcda32, p_MetadataSource := p_MetadataSource_9ffcda32);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = '8E0BC677-A3CA-4D46-B5AD-5FB561F4EAB6' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── calls ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_97a79994 UUID;
  p_IntegrationObjectID_97a79994 UUID;
  p_Name_97a79994 VARCHAR(255);
  p_DisplayName_97a79994 VARCHAR(255);
  p_Description_97a79994 TEXT;
  p_Category_97a79994 VARCHAR(100);
  p_Type_97a79994 VARCHAR(100);
  p_Length_97a79994 INTEGER;
  p_Precision_97a79994 INTEGER;
  p_Scale_97a79994 INTEGER;
  p_AllowsNull_97a79994 BOOLEAN;
  p_DefaultValue_97a79994 VARCHAR(255);
  p_IsPrimaryKey_97a79994 BOOLEAN;
  p_IsUniqueKey_97a79994 BOOLEAN;
  p_IsReadOnly_97a79994 BOOLEAN;
  p_IsRequired_97a79994 BOOLEAN;
  p_RelatedIntegrationObjectID_97a79994 UUID;
  p_RelatedIntegrationObjectFieldName_97a79994 VARCHAR(255);
  p_Sequence_97a79994 INTEGER;
  p_Configuration_97a79994 TEXT;
  p_Status_97a79994 VARCHAR(25);
  p_IsCustom_97a79994 BOOLEAN;
  p_MetadataSource_97a79994 VARCHAR(20);
BEGIN
  p_ID_97a79994 := '97A79994-6780-519A-A622-7FB2687C132F';
  p_IntegrationObjectID_97a79994 := '197AE7F2-4DFC-4F8F-91EA-E6D72B2BD535';
  p_Name_97a79994 := 'hs_object_id';
  p_Description_97a79994 := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_97a79994 := 'string';
  p_AllowsNull_97a79994 := FALSE;
  p_IsPrimaryKey_97a79994 := TRUE;
  p_IsUniqueKey_97a79994 := TRUE;
  p_IsReadOnly_97a79994 := TRUE;
  p_IsRequired_97a79994 := FALSE;
  p_Sequence_97a79994 := 0;
  p_Status_97a79994 := 'Active';
  p_IsCustom_97a79994 := FALSE;
  p_MetadataSource_97a79994 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_97a79994, p_IntegrationObjectID := p_IntegrationObjectID_97a79994, p_Name := p_Name_97a79994, p_DisplayName := p_DisplayName_97a79994, p_DisplayName_Clear := TRUE, p_Description := p_Description_97a79994, p_Category := p_Category_97a79994, p_Category_Clear := TRUE, p_Type := p_Type_97a79994, p_Length := p_Length_97a79994, p_Length_Clear := TRUE, p_Precision := p_Precision_97a79994, p_Precision_Clear := TRUE, p_Scale := p_Scale_97a79994, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_97a79994, p_DefaultValue := p_DefaultValue_97a79994, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_97a79994, p_IsUniqueKey := p_IsUniqueKey_97a79994, p_IsReadOnly := p_IsReadOnly_97a79994, p_IsRequired := p_IsRequired_97a79994, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_97a79994, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_97a79994, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_97a79994, p_Configuration := p_Configuration_97a79994, p_Configuration_Clear := TRUE, p_Status := p_Status_97a79994, p_IsCustom := p_IsCustom_97a79994, p_MetadataSource := p_MetadataSource_97a79994);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = '197AE7F2-4DFC-4F8F-91EA-E6D72B2BD535' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── carts ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_f6bf0361 UUID;
  p_IntegrationObjectID_f6bf0361 UUID;
  p_Name_f6bf0361 VARCHAR(255);
  p_DisplayName_f6bf0361 VARCHAR(255);
  p_Description_f6bf0361 TEXT;
  p_Category_f6bf0361 VARCHAR(100);
  p_Type_f6bf0361 VARCHAR(100);
  p_Length_f6bf0361 INTEGER;
  p_Precision_f6bf0361 INTEGER;
  p_Scale_f6bf0361 INTEGER;
  p_AllowsNull_f6bf0361 BOOLEAN;
  p_DefaultValue_f6bf0361 VARCHAR(255);
  p_IsPrimaryKey_f6bf0361 BOOLEAN;
  p_IsUniqueKey_f6bf0361 BOOLEAN;
  p_IsReadOnly_f6bf0361 BOOLEAN;
  p_IsRequired_f6bf0361 BOOLEAN;
  p_RelatedIntegrationObjectID_f6bf0361 UUID;
  p_RelatedIntegrationObjectFieldName_f6bf0361 VARCHAR(255);
  p_Sequence_f6bf0361 INTEGER;
  p_Configuration_f6bf0361 TEXT;
  p_Status_f6bf0361 VARCHAR(25);
  p_IsCustom_f6bf0361 BOOLEAN;
  p_MetadataSource_f6bf0361 VARCHAR(20);
BEGIN
  p_ID_f6bf0361 := 'F6BF0361-7376-5C2A-A923-D0F96081534A';
  p_IntegrationObjectID_f6bf0361 := '393074F2-5F47-42EF-9148-E60C0302995D';
  p_Name_f6bf0361 := 'hs_object_id';
  p_Description_f6bf0361 := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_f6bf0361 := 'string';
  p_AllowsNull_f6bf0361 := FALSE;
  p_IsPrimaryKey_f6bf0361 := TRUE;
  p_IsUniqueKey_f6bf0361 := TRUE;
  p_IsReadOnly_f6bf0361 := TRUE;
  p_IsRequired_f6bf0361 := FALSE;
  p_Sequence_f6bf0361 := 0;
  p_Status_f6bf0361 := 'Active';
  p_IsCustom_f6bf0361 := FALSE;
  p_MetadataSource_f6bf0361 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_f6bf0361, p_IntegrationObjectID := p_IntegrationObjectID_f6bf0361, p_Name := p_Name_f6bf0361, p_DisplayName := p_DisplayName_f6bf0361, p_DisplayName_Clear := TRUE, p_Description := p_Description_f6bf0361, p_Category := p_Category_f6bf0361, p_Category_Clear := TRUE, p_Type := p_Type_f6bf0361, p_Length := p_Length_f6bf0361, p_Length_Clear := TRUE, p_Precision := p_Precision_f6bf0361, p_Precision_Clear := TRUE, p_Scale := p_Scale_f6bf0361, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_f6bf0361, p_DefaultValue := p_DefaultValue_f6bf0361, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_f6bf0361, p_IsUniqueKey := p_IsUniqueKey_f6bf0361, p_IsReadOnly := p_IsReadOnly_f6bf0361, p_IsRequired := p_IsRequired_f6bf0361, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_f6bf0361, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_f6bf0361, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_f6bf0361, p_Configuration := p_Configuration_f6bf0361, p_Configuration_Clear := TRUE, p_Status := p_Status_f6bf0361, p_IsCustom := p_IsCustom_f6bf0361, p_MetadataSource := p_MetadataSource_f6bf0361);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = '393074F2-5F47-42EF-9148-E60C0302995D' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── commerce_payments ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_09f97be0 UUID;
  p_IntegrationObjectID_09f97be0 UUID;
  p_Name_09f97be0 VARCHAR(255);
  p_DisplayName_09f97be0 VARCHAR(255);
  p_Description_09f97be0 TEXT;
  p_Category_09f97be0 VARCHAR(100);
  p_Type_09f97be0 VARCHAR(100);
  p_Length_09f97be0 INTEGER;
  p_Precision_09f97be0 INTEGER;
  p_Scale_09f97be0 INTEGER;
  p_AllowsNull_09f97be0 BOOLEAN;
  p_DefaultValue_09f97be0 VARCHAR(255);
  p_IsPrimaryKey_09f97be0 BOOLEAN;
  p_IsUniqueKey_09f97be0 BOOLEAN;
  p_IsReadOnly_09f97be0 BOOLEAN;
  p_IsRequired_09f97be0 BOOLEAN;
  p_RelatedIntegrationObjectID_09f97be0 UUID;
  p_RelatedIntegrationObjectFieldName_09f97be0 VARCHAR(255);
  p_Sequence_09f97be0 INTEGER;
  p_Configuration_09f97be0 TEXT;
  p_Status_09f97be0 VARCHAR(25);
  p_IsCustom_09f97be0 BOOLEAN;
  p_MetadataSource_09f97be0 VARCHAR(20);
BEGIN
  p_ID_09f97be0 := '09F97BE0-507D-5F38-83AC-5B9719C74898';
  p_IntegrationObjectID_09f97be0 := '564C02F4-321B-4FF0-966A-F8A270D88664';
  p_Name_09f97be0 := 'hs_object_id';
  p_Description_09f97be0 := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_09f97be0 := 'string';
  p_AllowsNull_09f97be0 := FALSE;
  p_IsPrimaryKey_09f97be0 := TRUE;
  p_IsUniqueKey_09f97be0 := TRUE;
  p_IsReadOnly_09f97be0 := TRUE;
  p_IsRequired_09f97be0 := FALSE;
  p_Sequence_09f97be0 := 0;
  p_Status_09f97be0 := 'Active';
  p_IsCustom_09f97be0 := FALSE;
  p_MetadataSource_09f97be0 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_09f97be0, p_IntegrationObjectID := p_IntegrationObjectID_09f97be0, p_Name := p_Name_09f97be0, p_DisplayName := p_DisplayName_09f97be0, p_DisplayName_Clear := TRUE, p_Description := p_Description_09f97be0, p_Category := p_Category_09f97be0, p_Category_Clear := TRUE, p_Type := p_Type_09f97be0, p_Length := p_Length_09f97be0, p_Length_Clear := TRUE, p_Precision := p_Precision_09f97be0, p_Precision_Clear := TRUE, p_Scale := p_Scale_09f97be0, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_09f97be0, p_DefaultValue := p_DefaultValue_09f97be0, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_09f97be0, p_IsUniqueKey := p_IsUniqueKey_09f97be0, p_IsReadOnly := p_IsReadOnly_09f97be0, p_IsRequired := p_IsRequired_09f97be0, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_09f97be0, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_09f97be0, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_09f97be0, p_Configuration := p_Configuration_09f97be0, p_Configuration_Clear := TRUE, p_Status := p_Status_09f97be0, p_IsCustom := p_IsCustom_09f97be0, p_MetadataSource := p_MetadataSource_09f97be0);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = '564C02F4-321B-4FF0-966A-F8A270D88664' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── communications ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_1f8a168a UUID;
  p_IntegrationObjectID_1f8a168a UUID;
  p_Name_1f8a168a VARCHAR(255);
  p_DisplayName_1f8a168a VARCHAR(255);
  p_Description_1f8a168a TEXT;
  p_Category_1f8a168a VARCHAR(100);
  p_Type_1f8a168a VARCHAR(100);
  p_Length_1f8a168a INTEGER;
  p_Precision_1f8a168a INTEGER;
  p_Scale_1f8a168a INTEGER;
  p_AllowsNull_1f8a168a BOOLEAN;
  p_DefaultValue_1f8a168a VARCHAR(255);
  p_IsPrimaryKey_1f8a168a BOOLEAN;
  p_IsUniqueKey_1f8a168a BOOLEAN;
  p_IsReadOnly_1f8a168a BOOLEAN;
  p_IsRequired_1f8a168a BOOLEAN;
  p_RelatedIntegrationObjectID_1f8a168a UUID;
  p_RelatedIntegrationObjectFieldName_1f8a168a VARCHAR(255);
  p_Sequence_1f8a168a INTEGER;
  p_Configuration_1f8a168a TEXT;
  p_Status_1f8a168a VARCHAR(25);
  p_IsCustom_1f8a168a BOOLEAN;
  p_MetadataSource_1f8a168a VARCHAR(20);
BEGIN
  p_ID_1f8a168a := '1F8A168A-C857-5DEA-8B26-CB626EC87E4F';
  p_IntegrationObjectID_1f8a168a := 'AE2E1687-9FB2-4A5C-8F15-3435AE3A06D2';
  p_Name_1f8a168a := 'hs_object_id';
  p_Description_1f8a168a := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_1f8a168a := 'string';
  p_AllowsNull_1f8a168a := FALSE;
  p_IsPrimaryKey_1f8a168a := TRUE;
  p_IsUniqueKey_1f8a168a := TRUE;
  p_IsReadOnly_1f8a168a := TRUE;
  p_IsRequired_1f8a168a := FALSE;
  p_Sequence_1f8a168a := 0;
  p_Status_1f8a168a := 'Active';
  p_IsCustom_1f8a168a := FALSE;
  p_MetadataSource_1f8a168a := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_1f8a168a, p_IntegrationObjectID := p_IntegrationObjectID_1f8a168a, p_Name := p_Name_1f8a168a, p_DisplayName := p_DisplayName_1f8a168a, p_DisplayName_Clear := TRUE, p_Description := p_Description_1f8a168a, p_Category := p_Category_1f8a168a, p_Category_Clear := TRUE, p_Type := p_Type_1f8a168a, p_Length := p_Length_1f8a168a, p_Length_Clear := TRUE, p_Precision := p_Precision_1f8a168a, p_Precision_Clear := TRUE, p_Scale := p_Scale_1f8a168a, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_1f8a168a, p_DefaultValue := p_DefaultValue_1f8a168a, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_1f8a168a, p_IsUniqueKey := p_IsUniqueKey_1f8a168a, p_IsReadOnly := p_IsReadOnly_1f8a168a, p_IsRequired := p_IsRequired_1f8a168a, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_1f8a168a, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_1f8a168a, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_1f8a168a, p_Configuration := p_Configuration_1f8a168a, p_Configuration_Clear := TRUE, p_Status := p_Status_1f8a168a, p_IsCustom := p_IsCustom_1f8a168a, p_MetadataSource := p_MetadataSource_1f8a168a);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = 'AE2E1687-9FB2-4A5C-8F15-3435AE3A06D2' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── companies ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_f82d05b6 UUID;
  p_IntegrationObjectID_f82d05b6 UUID;
  p_Name_f82d05b6 VARCHAR(255);
  p_DisplayName_f82d05b6 VARCHAR(255);
  p_Description_f82d05b6 TEXT;
  p_Category_f82d05b6 VARCHAR(100);
  p_Type_f82d05b6 VARCHAR(100);
  p_Length_f82d05b6 INTEGER;
  p_Precision_f82d05b6 INTEGER;
  p_Scale_f82d05b6 INTEGER;
  p_AllowsNull_f82d05b6 BOOLEAN;
  p_DefaultValue_f82d05b6 VARCHAR(255);
  p_IsPrimaryKey_f82d05b6 BOOLEAN;
  p_IsUniqueKey_f82d05b6 BOOLEAN;
  p_IsReadOnly_f82d05b6 BOOLEAN;
  p_IsRequired_f82d05b6 BOOLEAN;
  p_RelatedIntegrationObjectID_f82d05b6 UUID;
  p_RelatedIntegrationObjectFieldName_f82d05b6 VARCHAR(255);
  p_Sequence_f82d05b6 INTEGER;
  p_Configuration_f82d05b6 TEXT;
  p_Status_f82d05b6 VARCHAR(25);
  p_IsCustom_f82d05b6 BOOLEAN;
  p_MetadataSource_f82d05b6 VARCHAR(20);
BEGIN
  p_ID_f82d05b6 := 'F82D05B6-9433-545F-931A-3EB9080C3A82';
  p_IntegrationObjectID_f82d05b6 := '27E3A334-0926-4D0E-B0B2-CD4F66289A2B';
  p_Name_f82d05b6 := 'hs_object_id';
  p_Description_f82d05b6 := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_f82d05b6 := 'string';
  p_AllowsNull_f82d05b6 := FALSE;
  p_IsPrimaryKey_f82d05b6 := TRUE;
  p_IsUniqueKey_f82d05b6 := TRUE;
  p_IsReadOnly_f82d05b6 := TRUE;
  p_IsRequired_f82d05b6 := FALSE;
  p_Sequence_f82d05b6 := 0;
  p_Status_f82d05b6 := 'Active';
  p_IsCustom_f82d05b6 := FALSE;
  p_MetadataSource_f82d05b6 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_f82d05b6, p_IntegrationObjectID := p_IntegrationObjectID_f82d05b6, p_Name := p_Name_f82d05b6, p_DisplayName := p_DisplayName_f82d05b6, p_DisplayName_Clear := TRUE, p_Description := p_Description_f82d05b6, p_Category := p_Category_f82d05b6, p_Category_Clear := TRUE, p_Type := p_Type_f82d05b6, p_Length := p_Length_f82d05b6, p_Length_Clear := TRUE, p_Precision := p_Precision_f82d05b6, p_Precision_Clear := TRUE, p_Scale := p_Scale_f82d05b6, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_f82d05b6, p_DefaultValue := p_DefaultValue_f82d05b6, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_f82d05b6, p_IsUniqueKey := p_IsUniqueKey_f82d05b6, p_IsReadOnly := p_IsReadOnly_f82d05b6, p_IsRequired := p_IsRequired_f82d05b6, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_f82d05b6, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_f82d05b6, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_f82d05b6, p_Configuration := p_Configuration_f82d05b6, p_Configuration_Clear := TRUE, p_Status := p_Status_f82d05b6, p_IsCustom := p_IsCustom_f82d05b6, p_MetadataSource := p_MetadataSource_f82d05b6);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = '27E3A334-0926-4D0E-B0B2-CD4F66289A2B' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── contacts ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_5de65e9c UUID;
  p_IntegrationObjectID_5de65e9c UUID;
  p_Name_5de65e9c VARCHAR(255);
  p_DisplayName_5de65e9c VARCHAR(255);
  p_Description_5de65e9c TEXT;
  p_Category_5de65e9c VARCHAR(100);
  p_Type_5de65e9c VARCHAR(100);
  p_Length_5de65e9c INTEGER;
  p_Precision_5de65e9c INTEGER;
  p_Scale_5de65e9c INTEGER;
  p_AllowsNull_5de65e9c BOOLEAN;
  p_DefaultValue_5de65e9c VARCHAR(255);
  p_IsPrimaryKey_5de65e9c BOOLEAN;
  p_IsUniqueKey_5de65e9c BOOLEAN;
  p_IsReadOnly_5de65e9c BOOLEAN;
  p_IsRequired_5de65e9c BOOLEAN;
  p_RelatedIntegrationObjectID_5de65e9c UUID;
  p_RelatedIntegrationObjectFieldName_5de65e9c VARCHAR(255);
  p_Sequence_5de65e9c INTEGER;
  p_Configuration_5de65e9c TEXT;
  p_Status_5de65e9c VARCHAR(25);
  p_IsCustom_5de65e9c BOOLEAN;
  p_MetadataSource_5de65e9c VARCHAR(20);
BEGIN
  p_ID_5de65e9c := '5DE65E9C-C135-5692-A945-7BFC85471808';
  p_IntegrationObjectID_5de65e9c := 'C4FD9983-11FA-47AA-B42D-A6509640B98C';
  p_Name_5de65e9c := 'hs_object_id';
  p_Description_5de65e9c := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_5de65e9c := 'string';
  p_AllowsNull_5de65e9c := FALSE;
  p_IsPrimaryKey_5de65e9c := TRUE;
  p_IsUniqueKey_5de65e9c := TRUE;
  p_IsReadOnly_5de65e9c := TRUE;
  p_IsRequired_5de65e9c := FALSE;
  p_Sequence_5de65e9c := 0;
  p_Status_5de65e9c := 'Active';
  p_IsCustom_5de65e9c := FALSE;
  p_MetadataSource_5de65e9c := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_5de65e9c, p_IntegrationObjectID := p_IntegrationObjectID_5de65e9c, p_Name := p_Name_5de65e9c, p_DisplayName := p_DisplayName_5de65e9c, p_DisplayName_Clear := TRUE, p_Description := p_Description_5de65e9c, p_Category := p_Category_5de65e9c, p_Category_Clear := TRUE, p_Type := p_Type_5de65e9c, p_Length := p_Length_5de65e9c, p_Length_Clear := TRUE, p_Precision := p_Precision_5de65e9c, p_Precision_Clear := TRUE, p_Scale := p_Scale_5de65e9c, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_5de65e9c, p_DefaultValue := p_DefaultValue_5de65e9c, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_5de65e9c, p_IsUniqueKey := p_IsUniqueKey_5de65e9c, p_IsReadOnly := p_IsReadOnly_5de65e9c, p_IsRequired := p_IsRequired_5de65e9c, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_5de65e9c, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_5de65e9c, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_5de65e9c, p_Configuration := p_Configuration_5de65e9c, p_Configuration_Clear := TRUE, p_Status := p_Status_5de65e9c, p_IsCustom := p_IsCustom_5de65e9c, p_MetadataSource := p_MetadataSource_5de65e9c);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = 'C4FD9983-11FA-47AA-B42D-A6509640B98C' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── contracts ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_2a68c3f1 UUID;
  p_IntegrationObjectID_2a68c3f1 UUID;
  p_Name_2a68c3f1 VARCHAR(255);
  p_DisplayName_2a68c3f1 VARCHAR(255);
  p_Description_2a68c3f1 TEXT;
  p_Category_2a68c3f1 VARCHAR(100);
  p_Type_2a68c3f1 VARCHAR(100);
  p_Length_2a68c3f1 INTEGER;
  p_Precision_2a68c3f1 INTEGER;
  p_Scale_2a68c3f1 INTEGER;
  p_AllowsNull_2a68c3f1 BOOLEAN;
  p_DefaultValue_2a68c3f1 VARCHAR(255);
  p_IsPrimaryKey_2a68c3f1 BOOLEAN;
  p_IsUniqueKey_2a68c3f1 BOOLEAN;
  p_IsReadOnly_2a68c3f1 BOOLEAN;
  p_IsRequired_2a68c3f1 BOOLEAN;
  p_RelatedIntegrationObjectID_2a68c3f1 UUID;
  p_RelatedIntegrationObjectFieldName_2a68c3f1 VARCHAR(255);
  p_Sequence_2a68c3f1 INTEGER;
  p_Configuration_2a68c3f1 TEXT;
  p_Status_2a68c3f1 VARCHAR(25);
  p_IsCustom_2a68c3f1 BOOLEAN;
  p_MetadataSource_2a68c3f1 VARCHAR(20);
BEGIN
  p_ID_2a68c3f1 := '2A68C3F1-2B76-5EF8-8176-9D88599719E5';
  p_IntegrationObjectID_2a68c3f1 := '6F19B7DB-D08A-4760-B231-5EB00EB68305';
  p_Name_2a68c3f1 := 'hs_object_id';
  p_Description_2a68c3f1 := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_2a68c3f1 := 'string';
  p_AllowsNull_2a68c3f1 := FALSE;
  p_IsPrimaryKey_2a68c3f1 := TRUE;
  p_IsUniqueKey_2a68c3f1 := TRUE;
  p_IsReadOnly_2a68c3f1 := TRUE;
  p_IsRequired_2a68c3f1 := FALSE;
  p_Sequence_2a68c3f1 := 0;
  p_Status_2a68c3f1 := 'Active';
  p_IsCustom_2a68c3f1 := FALSE;
  p_MetadataSource_2a68c3f1 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_2a68c3f1, p_IntegrationObjectID := p_IntegrationObjectID_2a68c3f1, p_Name := p_Name_2a68c3f1, p_DisplayName := p_DisplayName_2a68c3f1, p_DisplayName_Clear := TRUE, p_Description := p_Description_2a68c3f1, p_Category := p_Category_2a68c3f1, p_Category_Clear := TRUE, p_Type := p_Type_2a68c3f1, p_Length := p_Length_2a68c3f1, p_Length_Clear := TRUE, p_Precision := p_Precision_2a68c3f1, p_Precision_Clear := TRUE, p_Scale := p_Scale_2a68c3f1, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_2a68c3f1, p_DefaultValue := p_DefaultValue_2a68c3f1, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_2a68c3f1, p_IsUniqueKey := p_IsUniqueKey_2a68c3f1, p_IsReadOnly := p_IsReadOnly_2a68c3f1, p_IsRequired := p_IsRequired_2a68c3f1, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_2a68c3f1, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_2a68c3f1, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_2a68c3f1, p_Configuration := p_Configuration_2a68c3f1, p_Configuration_Clear := TRUE, p_Status := p_Status_2a68c3f1, p_IsCustom := p_IsCustom_2a68c3f1, p_MetadataSource := p_MetadataSource_2a68c3f1);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = '6F19B7DB-D08A-4760-B231-5EB00EB68305' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── courses ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_14df8def UUID;
  p_IntegrationObjectID_14df8def UUID;
  p_Name_14df8def VARCHAR(255);
  p_DisplayName_14df8def VARCHAR(255);
  p_Description_14df8def TEXT;
  p_Category_14df8def VARCHAR(100);
  p_Type_14df8def VARCHAR(100);
  p_Length_14df8def INTEGER;
  p_Precision_14df8def INTEGER;
  p_Scale_14df8def INTEGER;
  p_AllowsNull_14df8def BOOLEAN;
  p_DefaultValue_14df8def VARCHAR(255);
  p_IsPrimaryKey_14df8def BOOLEAN;
  p_IsUniqueKey_14df8def BOOLEAN;
  p_IsReadOnly_14df8def BOOLEAN;
  p_IsRequired_14df8def BOOLEAN;
  p_RelatedIntegrationObjectID_14df8def UUID;
  p_RelatedIntegrationObjectFieldName_14df8def VARCHAR(255);
  p_Sequence_14df8def INTEGER;
  p_Configuration_14df8def TEXT;
  p_Status_14df8def VARCHAR(25);
  p_IsCustom_14df8def BOOLEAN;
  p_MetadataSource_14df8def VARCHAR(20);
BEGIN
  p_ID_14df8def := '14DF8DEF-A186-557C-BEA0-BCB193A4FBA9';
  p_IntegrationObjectID_14df8def := '9533CB43-4B30-4D61-899A-CB3CBFF5068A';
  p_Name_14df8def := 'hs_object_id';
  p_Description_14df8def := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_14df8def := 'string';
  p_AllowsNull_14df8def := FALSE;
  p_IsPrimaryKey_14df8def := TRUE;
  p_IsUniqueKey_14df8def := TRUE;
  p_IsReadOnly_14df8def := TRUE;
  p_IsRequired_14df8def := FALSE;
  p_Sequence_14df8def := 0;
  p_Status_14df8def := 'Active';
  p_IsCustom_14df8def := FALSE;
  p_MetadataSource_14df8def := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_14df8def, p_IntegrationObjectID := p_IntegrationObjectID_14df8def, p_Name := p_Name_14df8def, p_DisplayName := p_DisplayName_14df8def, p_DisplayName_Clear := TRUE, p_Description := p_Description_14df8def, p_Category := p_Category_14df8def, p_Category_Clear := TRUE, p_Type := p_Type_14df8def, p_Length := p_Length_14df8def, p_Length_Clear := TRUE, p_Precision := p_Precision_14df8def, p_Precision_Clear := TRUE, p_Scale := p_Scale_14df8def, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_14df8def, p_DefaultValue := p_DefaultValue_14df8def, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_14df8def, p_IsUniqueKey := p_IsUniqueKey_14df8def, p_IsReadOnly := p_IsReadOnly_14df8def, p_IsRequired := p_IsRequired_14df8def, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_14df8def, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_14df8def, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_14df8def, p_Configuration := p_Configuration_14df8def, p_Configuration_Clear := TRUE, p_Status := p_Status_14df8def, p_IsCustom := p_IsCustom_14df8def, p_MetadataSource := p_MetadataSource_14df8def);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = '9533CB43-4B30-4D61-899A-CB3CBFF5068A' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── deal_splits ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_caeca571 UUID;
  p_IntegrationObjectID_caeca571 UUID;
  p_Name_caeca571 VARCHAR(255);
  p_DisplayName_caeca571 VARCHAR(255);
  p_Description_caeca571 TEXT;
  p_Category_caeca571 VARCHAR(100);
  p_Type_caeca571 VARCHAR(100);
  p_Length_caeca571 INTEGER;
  p_Precision_caeca571 INTEGER;
  p_Scale_caeca571 INTEGER;
  p_AllowsNull_caeca571 BOOLEAN;
  p_DefaultValue_caeca571 VARCHAR(255);
  p_IsPrimaryKey_caeca571 BOOLEAN;
  p_IsUniqueKey_caeca571 BOOLEAN;
  p_IsReadOnly_caeca571 BOOLEAN;
  p_IsRequired_caeca571 BOOLEAN;
  p_RelatedIntegrationObjectID_caeca571 UUID;
  p_RelatedIntegrationObjectFieldName_caeca571 VARCHAR(255);
  p_Sequence_caeca571 INTEGER;
  p_Configuration_caeca571 TEXT;
  p_Status_caeca571 VARCHAR(25);
  p_IsCustom_caeca571 BOOLEAN;
  p_MetadataSource_caeca571 VARCHAR(20);
BEGIN
  p_ID_caeca571 := 'CAECA571-50B0-50D6-BFC5-90986DC8671E';
  p_IntegrationObjectID_caeca571 := 'AEBB321F-84A1-4D11-8FCB-2BA63E0B975E';
  p_Name_caeca571 := 'hs_object_id';
  p_Description_caeca571 := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_caeca571 := 'string';
  p_AllowsNull_caeca571 := FALSE;
  p_IsPrimaryKey_caeca571 := TRUE;
  p_IsUniqueKey_caeca571 := TRUE;
  p_IsReadOnly_caeca571 := TRUE;
  p_IsRequired_caeca571 := FALSE;
  p_Sequence_caeca571 := 0;
  p_Status_caeca571 := 'Active';
  p_IsCustom_caeca571 := FALSE;
  p_MetadataSource_caeca571 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_caeca571, p_IntegrationObjectID := p_IntegrationObjectID_caeca571, p_Name := p_Name_caeca571, p_DisplayName := p_DisplayName_caeca571, p_DisplayName_Clear := TRUE, p_Description := p_Description_caeca571, p_Category := p_Category_caeca571, p_Category_Clear := TRUE, p_Type := p_Type_caeca571, p_Length := p_Length_caeca571, p_Length_Clear := TRUE, p_Precision := p_Precision_caeca571, p_Precision_Clear := TRUE, p_Scale := p_Scale_caeca571, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_caeca571, p_DefaultValue := p_DefaultValue_caeca571, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_caeca571, p_IsUniqueKey := p_IsUniqueKey_caeca571, p_IsReadOnly := p_IsReadOnly_caeca571, p_IsRequired := p_IsRequired_caeca571, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_caeca571, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_caeca571, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_caeca571, p_Configuration := p_Configuration_caeca571, p_Configuration_Clear := TRUE, p_Status := p_Status_caeca571, p_IsCustom := p_IsCustom_caeca571, p_MetadataSource := p_MetadataSource_caeca571);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = 'AEBB321F-84A1-4D11-8FCB-2BA63E0B975E' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── deals ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_665f0cd0 UUID;
  p_IntegrationObjectID_665f0cd0 UUID;
  p_Name_665f0cd0 VARCHAR(255);
  p_DisplayName_665f0cd0 VARCHAR(255);
  p_Description_665f0cd0 TEXT;
  p_Category_665f0cd0 VARCHAR(100);
  p_Type_665f0cd0 VARCHAR(100);
  p_Length_665f0cd0 INTEGER;
  p_Precision_665f0cd0 INTEGER;
  p_Scale_665f0cd0 INTEGER;
  p_AllowsNull_665f0cd0 BOOLEAN;
  p_DefaultValue_665f0cd0 VARCHAR(255);
  p_IsPrimaryKey_665f0cd0 BOOLEAN;
  p_IsUniqueKey_665f0cd0 BOOLEAN;
  p_IsReadOnly_665f0cd0 BOOLEAN;
  p_IsRequired_665f0cd0 BOOLEAN;
  p_RelatedIntegrationObjectID_665f0cd0 UUID;
  p_RelatedIntegrationObjectFieldName_665f0cd0 VARCHAR(255);
  p_Sequence_665f0cd0 INTEGER;
  p_Configuration_665f0cd0 TEXT;
  p_Status_665f0cd0 VARCHAR(25);
  p_IsCustom_665f0cd0 BOOLEAN;
  p_MetadataSource_665f0cd0 VARCHAR(20);
BEGIN
  p_ID_665f0cd0 := '665F0CD0-029E-5E3A-9DF4-D097BF8FA67F';
  p_IntegrationObjectID_665f0cd0 := 'D34F26F5-C854-4C9A-834F-B8AD0245C2EF';
  p_Name_665f0cd0 := 'hs_object_id';
  p_Description_665f0cd0 := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_665f0cd0 := 'string';
  p_AllowsNull_665f0cd0 := FALSE;
  p_IsPrimaryKey_665f0cd0 := TRUE;
  p_IsUniqueKey_665f0cd0 := TRUE;
  p_IsReadOnly_665f0cd0 := TRUE;
  p_IsRequired_665f0cd0 := FALSE;
  p_Sequence_665f0cd0 := 0;
  p_Status_665f0cd0 := 'Active';
  p_IsCustom_665f0cd0 := FALSE;
  p_MetadataSource_665f0cd0 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_665f0cd0, p_IntegrationObjectID := p_IntegrationObjectID_665f0cd0, p_Name := p_Name_665f0cd0, p_DisplayName := p_DisplayName_665f0cd0, p_DisplayName_Clear := TRUE, p_Description := p_Description_665f0cd0, p_Category := p_Category_665f0cd0, p_Category_Clear := TRUE, p_Type := p_Type_665f0cd0, p_Length := p_Length_665f0cd0, p_Length_Clear := TRUE, p_Precision := p_Precision_665f0cd0, p_Precision_Clear := TRUE, p_Scale := p_Scale_665f0cd0, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_665f0cd0, p_DefaultValue := p_DefaultValue_665f0cd0, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_665f0cd0, p_IsUniqueKey := p_IsUniqueKey_665f0cd0, p_IsReadOnly := p_IsReadOnly_665f0cd0, p_IsRequired := p_IsRequired_665f0cd0, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_665f0cd0, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_665f0cd0, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_665f0cd0, p_Configuration := p_Configuration_665f0cd0, p_Configuration_Clear := TRUE, p_Status := p_Status_665f0cd0, p_IsCustom := p_IsCustom_665f0cd0, p_MetadataSource := p_MetadataSource_665f0cd0);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = 'D34F26F5-C854-4C9A-834F-B8AD0245C2EF' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── discounts ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_70b01684 UUID;
  p_IntegrationObjectID_70b01684 UUID;
  p_Name_70b01684 VARCHAR(255);
  p_DisplayName_70b01684 VARCHAR(255);
  p_Description_70b01684 TEXT;
  p_Category_70b01684 VARCHAR(100);
  p_Type_70b01684 VARCHAR(100);
  p_Length_70b01684 INTEGER;
  p_Precision_70b01684 INTEGER;
  p_Scale_70b01684 INTEGER;
  p_AllowsNull_70b01684 BOOLEAN;
  p_DefaultValue_70b01684 VARCHAR(255);
  p_IsPrimaryKey_70b01684 BOOLEAN;
  p_IsUniqueKey_70b01684 BOOLEAN;
  p_IsReadOnly_70b01684 BOOLEAN;
  p_IsRequired_70b01684 BOOLEAN;
  p_RelatedIntegrationObjectID_70b01684 UUID;
  p_RelatedIntegrationObjectFieldName_70b01684 VARCHAR(255);
  p_Sequence_70b01684 INTEGER;
  p_Configuration_70b01684 TEXT;
  p_Status_70b01684 VARCHAR(25);
  p_IsCustom_70b01684 BOOLEAN;
  p_MetadataSource_70b01684 VARCHAR(20);
BEGIN
  p_ID_70b01684 := '70B01684-2D26-522B-A765-D017263F228F';
  p_IntegrationObjectID_70b01684 := '7F546789-4921-401D-A43A-47C369499D13';
  p_Name_70b01684 := 'hs_object_id';
  p_Description_70b01684 := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_70b01684 := 'string';
  p_AllowsNull_70b01684 := FALSE;
  p_IsPrimaryKey_70b01684 := TRUE;
  p_IsUniqueKey_70b01684 := TRUE;
  p_IsReadOnly_70b01684 := TRUE;
  p_IsRequired_70b01684 := FALSE;
  p_Sequence_70b01684 := 0;
  p_Status_70b01684 := 'Active';
  p_IsCustom_70b01684 := FALSE;
  p_MetadataSource_70b01684 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_70b01684, p_IntegrationObjectID := p_IntegrationObjectID_70b01684, p_Name := p_Name_70b01684, p_DisplayName := p_DisplayName_70b01684, p_DisplayName_Clear := TRUE, p_Description := p_Description_70b01684, p_Category := p_Category_70b01684, p_Category_Clear := TRUE, p_Type := p_Type_70b01684, p_Length := p_Length_70b01684, p_Length_Clear := TRUE, p_Precision := p_Precision_70b01684, p_Precision_Clear := TRUE, p_Scale := p_Scale_70b01684, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_70b01684, p_DefaultValue := p_DefaultValue_70b01684, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_70b01684, p_IsUniqueKey := p_IsUniqueKey_70b01684, p_IsReadOnly := p_IsReadOnly_70b01684, p_IsRequired := p_IsRequired_70b01684, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_70b01684, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_70b01684, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_70b01684, p_Configuration := p_Configuration_70b01684, p_Configuration_Clear := TRUE, p_Status := p_Status_70b01684, p_IsCustom := p_IsCustom_70b01684, p_MetadataSource := p_MetadataSource_70b01684);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = '7F546789-4921-401D-A43A-47C369499D13' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── emails ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_764c0b1f UUID;
  p_IntegrationObjectID_764c0b1f UUID;
  p_Name_764c0b1f VARCHAR(255);
  p_DisplayName_764c0b1f VARCHAR(255);
  p_Description_764c0b1f TEXT;
  p_Category_764c0b1f VARCHAR(100);
  p_Type_764c0b1f VARCHAR(100);
  p_Length_764c0b1f INTEGER;
  p_Precision_764c0b1f INTEGER;
  p_Scale_764c0b1f INTEGER;
  p_AllowsNull_764c0b1f BOOLEAN;
  p_DefaultValue_764c0b1f VARCHAR(255);
  p_IsPrimaryKey_764c0b1f BOOLEAN;
  p_IsUniqueKey_764c0b1f BOOLEAN;
  p_IsReadOnly_764c0b1f BOOLEAN;
  p_IsRequired_764c0b1f BOOLEAN;
  p_RelatedIntegrationObjectID_764c0b1f UUID;
  p_RelatedIntegrationObjectFieldName_764c0b1f VARCHAR(255);
  p_Sequence_764c0b1f INTEGER;
  p_Configuration_764c0b1f TEXT;
  p_Status_764c0b1f VARCHAR(25);
  p_IsCustom_764c0b1f BOOLEAN;
  p_MetadataSource_764c0b1f VARCHAR(20);
BEGIN
  p_ID_764c0b1f := '764C0B1F-3F2A-5237-A3BD-61D5974D757A';
  p_IntegrationObjectID_764c0b1f := 'E010E287-85DB-49C9-B273-71E46A68C83A';
  p_Name_764c0b1f := 'hs_object_id';
  p_Description_764c0b1f := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_764c0b1f := 'string';
  p_AllowsNull_764c0b1f := FALSE;
  p_IsPrimaryKey_764c0b1f := TRUE;
  p_IsUniqueKey_764c0b1f := TRUE;
  p_IsReadOnly_764c0b1f := TRUE;
  p_IsRequired_764c0b1f := FALSE;
  p_Sequence_764c0b1f := 0;
  p_Status_764c0b1f := 'Active';
  p_IsCustom_764c0b1f := FALSE;
  p_MetadataSource_764c0b1f := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_764c0b1f, p_IntegrationObjectID := p_IntegrationObjectID_764c0b1f, p_Name := p_Name_764c0b1f, p_DisplayName := p_DisplayName_764c0b1f, p_DisplayName_Clear := TRUE, p_Description := p_Description_764c0b1f, p_Category := p_Category_764c0b1f, p_Category_Clear := TRUE, p_Type := p_Type_764c0b1f, p_Length := p_Length_764c0b1f, p_Length_Clear := TRUE, p_Precision := p_Precision_764c0b1f, p_Precision_Clear := TRUE, p_Scale := p_Scale_764c0b1f, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_764c0b1f, p_DefaultValue := p_DefaultValue_764c0b1f, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_764c0b1f, p_IsUniqueKey := p_IsUniqueKey_764c0b1f, p_IsReadOnly := p_IsReadOnly_764c0b1f, p_IsRequired := p_IsRequired_764c0b1f, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_764c0b1f, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_764c0b1f, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_764c0b1f, p_Configuration := p_Configuration_764c0b1f, p_Configuration_Clear := TRUE, p_Status := p_Status_764c0b1f, p_IsCustom := p_IsCustom_764c0b1f, p_MetadataSource := p_MetadataSource_764c0b1f);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = 'E010E287-85DB-49C9-B273-71E46A68C83A' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── feedback_submissions ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_aeb13184 UUID;
  p_IntegrationObjectID_aeb13184 UUID;
  p_Name_aeb13184 VARCHAR(255);
  p_DisplayName_aeb13184 VARCHAR(255);
  p_Description_aeb13184 TEXT;
  p_Category_aeb13184 VARCHAR(100);
  p_Type_aeb13184 VARCHAR(100);
  p_Length_aeb13184 INTEGER;
  p_Precision_aeb13184 INTEGER;
  p_Scale_aeb13184 INTEGER;
  p_AllowsNull_aeb13184 BOOLEAN;
  p_DefaultValue_aeb13184 VARCHAR(255);
  p_IsPrimaryKey_aeb13184 BOOLEAN;
  p_IsUniqueKey_aeb13184 BOOLEAN;
  p_IsReadOnly_aeb13184 BOOLEAN;
  p_IsRequired_aeb13184 BOOLEAN;
  p_RelatedIntegrationObjectID_aeb13184 UUID;
  p_RelatedIntegrationObjectFieldName_aeb13184 VARCHAR(255);
  p_Sequence_aeb13184 INTEGER;
  p_Configuration_aeb13184 TEXT;
  p_Status_aeb13184 VARCHAR(25);
  p_IsCustom_aeb13184 BOOLEAN;
  p_MetadataSource_aeb13184 VARCHAR(20);
BEGIN
  p_ID_aeb13184 := 'AEB13184-6163-51C7-B903-A07996133E7E';
  p_IntegrationObjectID_aeb13184 := 'DC8361F8-8C7A-4974-B2A9-A83614CBC59B';
  p_Name_aeb13184 := 'hs_object_id';
  p_Description_aeb13184 := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_aeb13184 := 'string';
  p_AllowsNull_aeb13184 := FALSE;
  p_IsPrimaryKey_aeb13184 := TRUE;
  p_IsUniqueKey_aeb13184 := TRUE;
  p_IsReadOnly_aeb13184 := TRUE;
  p_IsRequired_aeb13184 := FALSE;
  p_Sequence_aeb13184 := 0;
  p_Status_aeb13184 := 'Active';
  p_IsCustom_aeb13184 := FALSE;
  p_MetadataSource_aeb13184 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_aeb13184, p_IntegrationObjectID := p_IntegrationObjectID_aeb13184, p_Name := p_Name_aeb13184, p_DisplayName := p_DisplayName_aeb13184, p_DisplayName_Clear := TRUE, p_Description := p_Description_aeb13184, p_Category := p_Category_aeb13184, p_Category_Clear := TRUE, p_Type := p_Type_aeb13184, p_Length := p_Length_aeb13184, p_Length_Clear := TRUE, p_Precision := p_Precision_aeb13184, p_Precision_Clear := TRUE, p_Scale := p_Scale_aeb13184, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_aeb13184, p_DefaultValue := p_DefaultValue_aeb13184, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_aeb13184, p_IsUniqueKey := p_IsUniqueKey_aeb13184, p_IsReadOnly := p_IsReadOnly_aeb13184, p_IsRequired := p_IsRequired_aeb13184, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_aeb13184, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_aeb13184, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_aeb13184, p_Configuration := p_Configuration_aeb13184, p_Configuration_Clear := TRUE, p_Status := p_Status_aeb13184, p_IsCustom := p_IsCustom_aeb13184, p_MetadataSource := p_MetadataSource_aeb13184);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = 'DC8361F8-8C7A-4974-B2A9-A83614CBC59B' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── fees ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_b02ee733 UUID;
  p_IntegrationObjectID_b02ee733 UUID;
  p_Name_b02ee733 VARCHAR(255);
  p_DisplayName_b02ee733 VARCHAR(255);
  p_Description_b02ee733 TEXT;
  p_Category_b02ee733 VARCHAR(100);
  p_Type_b02ee733 VARCHAR(100);
  p_Length_b02ee733 INTEGER;
  p_Precision_b02ee733 INTEGER;
  p_Scale_b02ee733 INTEGER;
  p_AllowsNull_b02ee733 BOOLEAN;
  p_DefaultValue_b02ee733 VARCHAR(255);
  p_IsPrimaryKey_b02ee733 BOOLEAN;
  p_IsUniqueKey_b02ee733 BOOLEAN;
  p_IsReadOnly_b02ee733 BOOLEAN;
  p_IsRequired_b02ee733 BOOLEAN;
  p_RelatedIntegrationObjectID_b02ee733 UUID;
  p_RelatedIntegrationObjectFieldName_b02ee733 VARCHAR(255);
  p_Sequence_b02ee733 INTEGER;
  p_Configuration_b02ee733 TEXT;
  p_Status_b02ee733 VARCHAR(25);
  p_IsCustom_b02ee733 BOOLEAN;
  p_MetadataSource_b02ee733 VARCHAR(20);
BEGIN
  p_ID_b02ee733 := 'B02EE733-5A85-52E9-A3BC-B45FA520FEFA';
  p_IntegrationObjectID_b02ee733 := 'F6008CB2-874C-4AC7-9DA5-3D7C22209876';
  p_Name_b02ee733 := 'hs_object_id';
  p_Description_b02ee733 := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_b02ee733 := 'string';
  p_AllowsNull_b02ee733 := FALSE;
  p_IsPrimaryKey_b02ee733 := TRUE;
  p_IsUniqueKey_b02ee733 := TRUE;
  p_IsReadOnly_b02ee733 := TRUE;
  p_IsRequired_b02ee733 := FALSE;
  p_Sequence_b02ee733 := 0;
  p_Status_b02ee733 := 'Active';
  p_IsCustom_b02ee733 := FALSE;
  p_MetadataSource_b02ee733 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_b02ee733, p_IntegrationObjectID := p_IntegrationObjectID_b02ee733, p_Name := p_Name_b02ee733, p_DisplayName := p_DisplayName_b02ee733, p_DisplayName_Clear := TRUE, p_Description := p_Description_b02ee733, p_Category := p_Category_b02ee733, p_Category_Clear := TRUE, p_Type := p_Type_b02ee733, p_Length := p_Length_b02ee733, p_Length_Clear := TRUE, p_Precision := p_Precision_b02ee733, p_Precision_Clear := TRUE, p_Scale := p_Scale_b02ee733, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_b02ee733, p_DefaultValue := p_DefaultValue_b02ee733, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_b02ee733, p_IsUniqueKey := p_IsUniqueKey_b02ee733, p_IsReadOnly := p_IsReadOnly_b02ee733, p_IsRequired := p_IsRequired_b02ee733, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_b02ee733, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_b02ee733, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_b02ee733, p_Configuration := p_Configuration_b02ee733, p_Configuration_Clear := TRUE, p_Status := p_Status_b02ee733, p_IsCustom := p_IsCustom_b02ee733, p_MetadataSource := p_MetadataSource_b02ee733);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = 'F6008CB2-874C-4AC7-9DA5-3D7C22209876' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── goal_targets ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_6e74c2de UUID;
  p_IntegrationObjectID_6e74c2de UUID;
  p_Name_6e74c2de VARCHAR(255);
  p_DisplayName_6e74c2de VARCHAR(255);
  p_Description_6e74c2de TEXT;
  p_Category_6e74c2de VARCHAR(100);
  p_Type_6e74c2de VARCHAR(100);
  p_Length_6e74c2de INTEGER;
  p_Precision_6e74c2de INTEGER;
  p_Scale_6e74c2de INTEGER;
  p_AllowsNull_6e74c2de BOOLEAN;
  p_DefaultValue_6e74c2de VARCHAR(255);
  p_IsPrimaryKey_6e74c2de BOOLEAN;
  p_IsUniqueKey_6e74c2de BOOLEAN;
  p_IsReadOnly_6e74c2de BOOLEAN;
  p_IsRequired_6e74c2de BOOLEAN;
  p_RelatedIntegrationObjectID_6e74c2de UUID;
  p_RelatedIntegrationObjectFieldName_6e74c2de VARCHAR(255);
  p_Sequence_6e74c2de INTEGER;
  p_Configuration_6e74c2de TEXT;
  p_Status_6e74c2de VARCHAR(25);
  p_IsCustom_6e74c2de BOOLEAN;
  p_MetadataSource_6e74c2de VARCHAR(20);
BEGIN
  p_ID_6e74c2de := '6E74C2DE-CB6F-52FB-AAC3-A6D4A06423E4';
  p_IntegrationObjectID_6e74c2de := '431F36F5-210B-4CDA-876D-4DD1E2B8B0EC';
  p_Name_6e74c2de := 'hs_object_id';
  p_Description_6e74c2de := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_6e74c2de := 'string';
  p_AllowsNull_6e74c2de := FALSE;
  p_IsPrimaryKey_6e74c2de := TRUE;
  p_IsUniqueKey_6e74c2de := TRUE;
  p_IsReadOnly_6e74c2de := TRUE;
  p_IsRequired_6e74c2de := FALSE;
  p_Sequence_6e74c2de := 0;
  p_Status_6e74c2de := 'Active';
  p_IsCustom_6e74c2de := FALSE;
  p_MetadataSource_6e74c2de := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_6e74c2de, p_IntegrationObjectID := p_IntegrationObjectID_6e74c2de, p_Name := p_Name_6e74c2de, p_DisplayName := p_DisplayName_6e74c2de, p_DisplayName_Clear := TRUE, p_Description := p_Description_6e74c2de, p_Category := p_Category_6e74c2de, p_Category_Clear := TRUE, p_Type := p_Type_6e74c2de, p_Length := p_Length_6e74c2de, p_Length_Clear := TRUE, p_Precision := p_Precision_6e74c2de, p_Precision_Clear := TRUE, p_Scale := p_Scale_6e74c2de, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_6e74c2de, p_DefaultValue := p_DefaultValue_6e74c2de, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_6e74c2de, p_IsUniqueKey := p_IsUniqueKey_6e74c2de, p_IsReadOnly := p_IsReadOnly_6e74c2de, p_IsRequired := p_IsRequired_6e74c2de, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_6e74c2de, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_6e74c2de, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_6e74c2de, p_Configuration := p_Configuration_6e74c2de, p_Configuration_Clear := TRUE, p_Status := p_Status_6e74c2de, p_IsCustom := p_IsCustom_6e74c2de, p_MetadataSource := p_MetadataSource_6e74c2de);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = '431F36F5-210B-4CDA-876D-4DD1E2B8B0EC' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── invoices ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_8187ef3e UUID;
  p_IntegrationObjectID_8187ef3e UUID;
  p_Name_8187ef3e VARCHAR(255);
  p_DisplayName_8187ef3e VARCHAR(255);
  p_Description_8187ef3e TEXT;
  p_Category_8187ef3e VARCHAR(100);
  p_Type_8187ef3e VARCHAR(100);
  p_Length_8187ef3e INTEGER;
  p_Precision_8187ef3e INTEGER;
  p_Scale_8187ef3e INTEGER;
  p_AllowsNull_8187ef3e BOOLEAN;
  p_DefaultValue_8187ef3e VARCHAR(255);
  p_IsPrimaryKey_8187ef3e BOOLEAN;
  p_IsUniqueKey_8187ef3e BOOLEAN;
  p_IsReadOnly_8187ef3e BOOLEAN;
  p_IsRequired_8187ef3e BOOLEAN;
  p_RelatedIntegrationObjectID_8187ef3e UUID;
  p_RelatedIntegrationObjectFieldName_8187ef3e VARCHAR(255);
  p_Sequence_8187ef3e INTEGER;
  p_Configuration_8187ef3e TEXT;
  p_Status_8187ef3e VARCHAR(25);
  p_IsCustom_8187ef3e BOOLEAN;
  p_MetadataSource_8187ef3e VARCHAR(20);
BEGIN
  p_ID_8187ef3e := '8187EF3E-4A51-53E8-99F6-60D57F625067';
  p_IntegrationObjectID_8187ef3e := '3F99724E-A4E1-42FD-8BDF-534C1109B5DA';
  p_Name_8187ef3e := 'hs_object_id';
  p_Description_8187ef3e := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_8187ef3e := 'string';
  p_AllowsNull_8187ef3e := FALSE;
  p_IsPrimaryKey_8187ef3e := TRUE;
  p_IsUniqueKey_8187ef3e := TRUE;
  p_IsReadOnly_8187ef3e := TRUE;
  p_IsRequired_8187ef3e := FALSE;
  p_Sequence_8187ef3e := 0;
  p_Status_8187ef3e := 'Active';
  p_IsCustom_8187ef3e := FALSE;
  p_MetadataSource_8187ef3e := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_8187ef3e, p_IntegrationObjectID := p_IntegrationObjectID_8187ef3e, p_Name := p_Name_8187ef3e, p_DisplayName := p_DisplayName_8187ef3e, p_DisplayName_Clear := TRUE, p_Description := p_Description_8187ef3e, p_Category := p_Category_8187ef3e, p_Category_Clear := TRUE, p_Type := p_Type_8187ef3e, p_Length := p_Length_8187ef3e, p_Length_Clear := TRUE, p_Precision := p_Precision_8187ef3e, p_Precision_Clear := TRUE, p_Scale := p_Scale_8187ef3e, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_8187ef3e, p_DefaultValue := p_DefaultValue_8187ef3e, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_8187ef3e, p_IsUniqueKey := p_IsUniqueKey_8187ef3e, p_IsReadOnly := p_IsReadOnly_8187ef3e, p_IsRequired := p_IsRequired_8187ef3e, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_8187ef3e, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_8187ef3e, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_8187ef3e, p_Configuration := p_Configuration_8187ef3e, p_Configuration_Clear := TRUE, p_Status := p_Status_8187ef3e, p_IsCustom := p_IsCustom_8187ef3e, p_MetadataSource := p_MetadataSource_8187ef3e);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = '3F99724E-A4E1-42FD-8BDF-534C1109B5DA' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── leads ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_5e0ee4fd UUID;
  p_IntegrationObjectID_5e0ee4fd UUID;
  p_Name_5e0ee4fd VARCHAR(255);
  p_DisplayName_5e0ee4fd VARCHAR(255);
  p_Description_5e0ee4fd TEXT;
  p_Category_5e0ee4fd VARCHAR(100);
  p_Type_5e0ee4fd VARCHAR(100);
  p_Length_5e0ee4fd INTEGER;
  p_Precision_5e0ee4fd INTEGER;
  p_Scale_5e0ee4fd INTEGER;
  p_AllowsNull_5e0ee4fd BOOLEAN;
  p_DefaultValue_5e0ee4fd VARCHAR(255);
  p_IsPrimaryKey_5e0ee4fd BOOLEAN;
  p_IsUniqueKey_5e0ee4fd BOOLEAN;
  p_IsReadOnly_5e0ee4fd BOOLEAN;
  p_IsRequired_5e0ee4fd BOOLEAN;
  p_RelatedIntegrationObjectID_5e0ee4fd UUID;
  p_RelatedIntegrationObjectFieldName_5e0ee4fd VARCHAR(255);
  p_Sequence_5e0ee4fd INTEGER;
  p_Configuration_5e0ee4fd TEXT;
  p_Status_5e0ee4fd VARCHAR(25);
  p_IsCustom_5e0ee4fd BOOLEAN;
  p_MetadataSource_5e0ee4fd VARCHAR(20);
BEGIN
  p_ID_5e0ee4fd := '5E0EE4FD-02E5-53A5-B6C0-9F3821B72864';
  p_IntegrationObjectID_5e0ee4fd := 'EE848395-E9FA-4AA0-B445-0AFA2F3E63FA';
  p_Name_5e0ee4fd := 'hs_object_id';
  p_Description_5e0ee4fd := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_5e0ee4fd := 'string';
  p_AllowsNull_5e0ee4fd := FALSE;
  p_IsPrimaryKey_5e0ee4fd := TRUE;
  p_IsUniqueKey_5e0ee4fd := TRUE;
  p_IsReadOnly_5e0ee4fd := TRUE;
  p_IsRequired_5e0ee4fd := FALSE;
  p_Sequence_5e0ee4fd := 0;
  p_Status_5e0ee4fd := 'Active';
  p_IsCustom_5e0ee4fd := FALSE;
  p_MetadataSource_5e0ee4fd := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_5e0ee4fd, p_IntegrationObjectID := p_IntegrationObjectID_5e0ee4fd, p_Name := p_Name_5e0ee4fd, p_DisplayName := p_DisplayName_5e0ee4fd, p_DisplayName_Clear := TRUE, p_Description := p_Description_5e0ee4fd, p_Category := p_Category_5e0ee4fd, p_Category_Clear := TRUE, p_Type := p_Type_5e0ee4fd, p_Length := p_Length_5e0ee4fd, p_Length_Clear := TRUE, p_Precision := p_Precision_5e0ee4fd, p_Precision_Clear := TRUE, p_Scale := p_Scale_5e0ee4fd, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_5e0ee4fd, p_DefaultValue := p_DefaultValue_5e0ee4fd, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_5e0ee4fd, p_IsUniqueKey := p_IsUniqueKey_5e0ee4fd, p_IsReadOnly := p_IsReadOnly_5e0ee4fd, p_IsRequired := p_IsRequired_5e0ee4fd, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_5e0ee4fd, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_5e0ee4fd, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_5e0ee4fd, p_Configuration := p_Configuration_5e0ee4fd, p_Configuration_Clear := TRUE, p_Status := p_Status_5e0ee4fd, p_IsCustom := p_IsCustom_5e0ee4fd, p_MetadataSource := p_MetadataSource_5e0ee4fd);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = 'EE848395-E9FA-4AA0-B445-0AFA2F3E63FA' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── line_items ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_b0ba6f03 UUID;
  p_IntegrationObjectID_b0ba6f03 UUID;
  p_Name_b0ba6f03 VARCHAR(255);
  p_DisplayName_b0ba6f03 VARCHAR(255);
  p_Description_b0ba6f03 TEXT;
  p_Category_b0ba6f03 VARCHAR(100);
  p_Type_b0ba6f03 VARCHAR(100);
  p_Length_b0ba6f03 INTEGER;
  p_Precision_b0ba6f03 INTEGER;
  p_Scale_b0ba6f03 INTEGER;
  p_AllowsNull_b0ba6f03 BOOLEAN;
  p_DefaultValue_b0ba6f03 VARCHAR(255);
  p_IsPrimaryKey_b0ba6f03 BOOLEAN;
  p_IsUniqueKey_b0ba6f03 BOOLEAN;
  p_IsReadOnly_b0ba6f03 BOOLEAN;
  p_IsRequired_b0ba6f03 BOOLEAN;
  p_RelatedIntegrationObjectID_b0ba6f03 UUID;
  p_RelatedIntegrationObjectFieldName_b0ba6f03 VARCHAR(255);
  p_Sequence_b0ba6f03 INTEGER;
  p_Configuration_b0ba6f03 TEXT;
  p_Status_b0ba6f03 VARCHAR(25);
  p_IsCustom_b0ba6f03 BOOLEAN;
  p_MetadataSource_b0ba6f03 VARCHAR(20);
BEGIN
  p_ID_b0ba6f03 := 'B0BA6F03-AEA3-5545-8A0B-99F83DFB0D7B';
  p_IntegrationObjectID_b0ba6f03 := '10E3F4D3-ACAB-4FB5-B903-D9A7BBD52965';
  p_Name_b0ba6f03 := 'hs_object_id';
  p_Description_b0ba6f03 := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_b0ba6f03 := 'string';
  p_AllowsNull_b0ba6f03 := FALSE;
  p_IsPrimaryKey_b0ba6f03 := TRUE;
  p_IsUniqueKey_b0ba6f03 := TRUE;
  p_IsReadOnly_b0ba6f03 := TRUE;
  p_IsRequired_b0ba6f03 := FALSE;
  p_Sequence_b0ba6f03 := 0;
  p_Status_b0ba6f03 := 'Active';
  p_IsCustom_b0ba6f03 := FALSE;
  p_MetadataSource_b0ba6f03 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_b0ba6f03, p_IntegrationObjectID := p_IntegrationObjectID_b0ba6f03, p_Name := p_Name_b0ba6f03, p_DisplayName := p_DisplayName_b0ba6f03, p_DisplayName_Clear := TRUE, p_Description := p_Description_b0ba6f03, p_Category := p_Category_b0ba6f03, p_Category_Clear := TRUE, p_Type := p_Type_b0ba6f03, p_Length := p_Length_b0ba6f03, p_Length_Clear := TRUE, p_Precision := p_Precision_b0ba6f03, p_Precision_Clear := TRUE, p_Scale := p_Scale_b0ba6f03, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_b0ba6f03, p_DefaultValue := p_DefaultValue_b0ba6f03, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_b0ba6f03, p_IsUniqueKey := p_IsUniqueKey_b0ba6f03, p_IsReadOnly := p_IsReadOnly_b0ba6f03, p_IsRequired := p_IsRequired_b0ba6f03, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_b0ba6f03, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_b0ba6f03, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_b0ba6f03, p_Configuration := p_Configuration_b0ba6f03, p_Configuration_Clear := TRUE, p_Status := p_Status_b0ba6f03, p_IsCustom := p_IsCustom_b0ba6f03, p_MetadataSource := p_MetadataSource_b0ba6f03);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = '10E3F4D3-ACAB-4FB5-B903-D9A7BBD52965' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── listings ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_0363da2a UUID;
  p_IntegrationObjectID_0363da2a UUID;
  p_Name_0363da2a VARCHAR(255);
  p_DisplayName_0363da2a VARCHAR(255);
  p_Description_0363da2a TEXT;
  p_Category_0363da2a VARCHAR(100);
  p_Type_0363da2a VARCHAR(100);
  p_Length_0363da2a INTEGER;
  p_Precision_0363da2a INTEGER;
  p_Scale_0363da2a INTEGER;
  p_AllowsNull_0363da2a BOOLEAN;
  p_DefaultValue_0363da2a VARCHAR(255);
  p_IsPrimaryKey_0363da2a BOOLEAN;
  p_IsUniqueKey_0363da2a BOOLEAN;
  p_IsReadOnly_0363da2a BOOLEAN;
  p_IsRequired_0363da2a BOOLEAN;
  p_RelatedIntegrationObjectID_0363da2a UUID;
  p_RelatedIntegrationObjectFieldName_0363da2a VARCHAR(255);
  p_Sequence_0363da2a INTEGER;
  p_Configuration_0363da2a TEXT;
  p_Status_0363da2a VARCHAR(25);
  p_IsCustom_0363da2a BOOLEAN;
  p_MetadataSource_0363da2a VARCHAR(20);
BEGIN
  p_ID_0363da2a := '0363DA2A-F201-5351-8889-34FBADF9034C';
  p_IntegrationObjectID_0363da2a := '12750595-5CB5-4947-9A93-5FA609636907';
  p_Name_0363da2a := 'hs_object_id';
  p_Description_0363da2a := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_0363da2a := 'string';
  p_AllowsNull_0363da2a := FALSE;
  p_IsPrimaryKey_0363da2a := TRUE;
  p_IsUniqueKey_0363da2a := TRUE;
  p_IsReadOnly_0363da2a := TRUE;
  p_IsRequired_0363da2a := FALSE;
  p_Sequence_0363da2a := 0;
  p_Status_0363da2a := 'Active';
  p_IsCustom_0363da2a := FALSE;
  p_MetadataSource_0363da2a := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_0363da2a, p_IntegrationObjectID := p_IntegrationObjectID_0363da2a, p_Name := p_Name_0363da2a, p_DisplayName := p_DisplayName_0363da2a, p_DisplayName_Clear := TRUE, p_Description := p_Description_0363da2a, p_Category := p_Category_0363da2a, p_Category_Clear := TRUE, p_Type := p_Type_0363da2a, p_Length := p_Length_0363da2a, p_Length_Clear := TRUE, p_Precision := p_Precision_0363da2a, p_Precision_Clear := TRUE, p_Scale := p_Scale_0363da2a, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_0363da2a, p_DefaultValue := p_DefaultValue_0363da2a, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_0363da2a, p_IsUniqueKey := p_IsUniqueKey_0363da2a, p_IsReadOnly := p_IsReadOnly_0363da2a, p_IsRequired := p_IsRequired_0363da2a, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_0363da2a, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_0363da2a, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_0363da2a, p_Configuration := p_Configuration_0363da2a, p_Configuration_Clear := TRUE, p_Status := p_Status_0363da2a, p_IsCustom := p_IsCustom_0363da2a, p_MetadataSource := p_MetadataSource_0363da2a);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = '12750595-5CB5-4947-9A93-5FA609636907' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── meetings ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_ce54e423 UUID;
  p_IntegrationObjectID_ce54e423 UUID;
  p_Name_ce54e423 VARCHAR(255);
  p_DisplayName_ce54e423 VARCHAR(255);
  p_Description_ce54e423 TEXT;
  p_Category_ce54e423 VARCHAR(100);
  p_Type_ce54e423 VARCHAR(100);
  p_Length_ce54e423 INTEGER;
  p_Precision_ce54e423 INTEGER;
  p_Scale_ce54e423 INTEGER;
  p_AllowsNull_ce54e423 BOOLEAN;
  p_DefaultValue_ce54e423 VARCHAR(255);
  p_IsPrimaryKey_ce54e423 BOOLEAN;
  p_IsUniqueKey_ce54e423 BOOLEAN;
  p_IsReadOnly_ce54e423 BOOLEAN;
  p_IsRequired_ce54e423 BOOLEAN;
  p_RelatedIntegrationObjectID_ce54e423 UUID;
  p_RelatedIntegrationObjectFieldName_ce54e423 VARCHAR(255);
  p_Sequence_ce54e423 INTEGER;
  p_Configuration_ce54e423 TEXT;
  p_Status_ce54e423 VARCHAR(25);
  p_IsCustom_ce54e423 BOOLEAN;
  p_MetadataSource_ce54e423 VARCHAR(20);
BEGIN
  p_ID_ce54e423 := 'CE54E423-5A9A-5796-9387-97D3E790A343';
  p_IntegrationObjectID_ce54e423 := '2E6F9A38-671F-44A8-A1AD-2273202F56EF';
  p_Name_ce54e423 := 'hs_object_id';
  p_Description_ce54e423 := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_ce54e423 := 'string';
  p_AllowsNull_ce54e423 := FALSE;
  p_IsPrimaryKey_ce54e423 := TRUE;
  p_IsUniqueKey_ce54e423 := TRUE;
  p_IsReadOnly_ce54e423 := TRUE;
  p_IsRequired_ce54e423 := FALSE;
  p_Sequence_ce54e423 := 0;
  p_Status_ce54e423 := 'Active';
  p_IsCustom_ce54e423 := FALSE;
  p_MetadataSource_ce54e423 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_ce54e423, p_IntegrationObjectID := p_IntegrationObjectID_ce54e423, p_Name := p_Name_ce54e423, p_DisplayName := p_DisplayName_ce54e423, p_DisplayName_Clear := TRUE, p_Description := p_Description_ce54e423, p_Category := p_Category_ce54e423, p_Category_Clear := TRUE, p_Type := p_Type_ce54e423, p_Length := p_Length_ce54e423, p_Length_Clear := TRUE, p_Precision := p_Precision_ce54e423, p_Precision_Clear := TRUE, p_Scale := p_Scale_ce54e423, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_ce54e423, p_DefaultValue := p_DefaultValue_ce54e423, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_ce54e423, p_IsUniqueKey := p_IsUniqueKey_ce54e423, p_IsReadOnly := p_IsReadOnly_ce54e423, p_IsRequired := p_IsRequired_ce54e423, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_ce54e423, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_ce54e423, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_ce54e423, p_Configuration := p_Configuration_ce54e423, p_Configuration_Clear := TRUE, p_Status := p_Status_ce54e423, p_IsCustom := p_IsCustom_ce54e423, p_MetadataSource := p_MetadataSource_ce54e423);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = '2E6F9A38-671F-44A8-A1AD-2273202F56EF' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── notes ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_68a8deaa UUID;
  p_IntegrationObjectID_68a8deaa UUID;
  p_Name_68a8deaa VARCHAR(255);
  p_DisplayName_68a8deaa VARCHAR(255);
  p_Description_68a8deaa TEXT;
  p_Category_68a8deaa VARCHAR(100);
  p_Type_68a8deaa VARCHAR(100);
  p_Length_68a8deaa INTEGER;
  p_Precision_68a8deaa INTEGER;
  p_Scale_68a8deaa INTEGER;
  p_AllowsNull_68a8deaa BOOLEAN;
  p_DefaultValue_68a8deaa VARCHAR(255);
  p_IsPrimaryKey_68a8deaa BOOLEAN;
  p_IsUniqueKey_68a8deaa BOOLEAN;
  p_IsReadOnly_68a8deaa BOOLEAN;
  p_IsRequired_68a8deaa BOOLEAN;
  p_RelatedIntegrationObjectID_68a8deaa UUID;
  p_RelatedIntegrationObjectFieldName_68a8deaa VARCHAR(255);
  p_Sequence_68a8deaa INTEGER;
  p_Configuration_68a8deaa TEXT;
  p_Status_68a8deaa VARCHAR(25);
  p_IsCustom_68a8deaa BOOLEAN;
  p_MetadataSource_68a8deaa VARCHAR(20);
BEGIN
  p_ID_68a8deaa := '68A8DEAA-878F-542C-A802-095EF1DEDE13';
  p_IntegrationObjectID_68a8deaa := '53CD3DE3-77A7-4AAE-98B0-A50211705D24';
  p_Name_68a8deaa := 'hs_object_id';
  p_Description_68a8deaa := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_68a8deaa := 'string';
  p_AllowsNull_68a8deaa := FALSE;
  p_IsPrimaryKey_68a8deaa := TRUE;
  p_IsUniqueKey_68a8deaa := TRUE;
  p_IsReadOnly_68a8deaa := TRUE;
  p_IsRequired_68a8deaa := FALSE;
  p_Sequence_68a8deaa := 0;
  p_Status_68a8deaa := 'Active';
  p_IsCustom_68a8deaa := FALSE;
  p_MetadataSource_68a8deaa := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_68a8deaa, p_IntegrationObjectID := p_IntegrationObjectID_68a8deaa, p_Name := p_Name_68a8deaa, p_DisplayName := p_DisplayName_68a8deaa, p_DisplayName_Clear := TRUE, p_Description := p_Description_68a8deaa, p_Category := p_Category_68a8deaa, p_Category_Clear := TRUE, p_Type := p_Type_68a8deaa, p_Length := p_Length_68a8deaa, p_Length_Clear := TRUE, p_Precision := p_Precision_68a8deaa, p_Precision_Clear := TRUE, p_Scale := p_Scale_68a8deaa, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_68a8deaa, p_DefaultValue := p_DefaultValue_68a8deaa, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_68a8deaa, p_IsUniqueKey := p_IsUniqueKey_68a8deaa, p_IsReadOnly := p_IsReadOnly_68a8deaa, p_IsRequired := p_IsRequired_68a8deaa, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_68a8deaa, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_68a8deaa, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_68a8deaa, p_Configuration := p_Configuration_68a8deaa, p_Configuration_Clear := TRUE, p_Status := p_Status_68a8deaa, p_IsCustom := p_IsCustom_68a8deaa, p_MetadataSource := p_MetadataSource_68a8deaa);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = '53CD3DE3-77A7-4AAE-98B0-A50211705D24' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── orders ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_fdaec289 UUID;
  p_IntegrationObjectID_fdaec289 UUID;
  p_Name_fdaec289 VARCHAR(255);
  p_DisplayName_fdaec289 VARCHAR(255);
  p_Description_fdaec289 TEXT;
  p_Category_fdaec289 VARCHAR(100);
  p_Type_fdaec289 VARCHAR(100);
  p_Length_fdaec289 INTEGER;
  p_Precision_fdaec289 INTEGER;
  p_Scale_fdaec289 INTEGER;
  p_AllowsNull_fdaec289 BOOLEAN;
  p_DefaultValue_fdaec289 VARCHAR(255);
  p_IsPrimaryKey_fdaec289 BOOLEAN;
  p_IsUniqueKey_fdaec289 BOOLEAN;
  p_IsReadOnly_fdaec289 BOOLEAN;
  p_IsRequired_fdaec289 BOOLEAN;
  p_RelatedIntegrationObjectID_fdaec289 UUID;
  p_RelatedIntegrationObjectFieldName_fdaec289 VARCHAR(255);
  p_Sequence_fdaec289 INTEGER;
  p_Configuration_fdaec289 TEXT;
  p_Status_fdaec289 VARCHAR(25);
  p_IsCustom_fdaec289 BOOLEAN;
  p_MetadataSource_fdaec289 VARCHAR(20);
BEGIN
  p_ID_fdaec289 := 'FDAEC289-113C-5B22-B83F-0C36C0C35CFE';
  p_IntegrationObjectID_fdaec289 := '1A0024CB-35BF-4779-81BD-451DC511E550';
  p_Name_fdaec289 := 'hs_object_id';
  p_Description_fdaec289 := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_fdaec289 := 'string';
  p_AllowsNull_fdaec289 := FALSE;
  p_IsPrimaryKey_fdaec289 := TRUE;
  p_IsUniqueKey_fdaec289 := TRUE;
  p_IsReadOnly_fdaec289 := TRUE;
  p_IsRequired_fdaec289 := FALSE;
  p_Sequence_fdaec289 := 0;
  p_Status_fdaec289 := 'Active';
  p_IsCustom_fdaec289 := FALSE;
  p_MetadataSource_fdaec289 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_fdaec289, p_IntegrationObjectID := p_IntegrationObjectID_fdaec289, p_Name := p_Name_fdaec289, p_DisplayName := p_DisplayName_fdaec289, p_DisplayName_Clear := TRUE, p_Description := p_Description_fdaec289, p_Category := p_Category_fdaec289, p_Category_Clear := TRUE, p_Type := p_Type_fdaec289, p_Length := p_Length_fdaec289, p_Length_Clear := TRUE, p_Precision := p_Precision_fdaec289, p_Precision_Clear := TRUE, p_Scale := p_Scale_fdaec289, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_fdaec289, p_DefaultValue := p_DefaultValue_fdaec289, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_fdaec289, p_IsUniqueKey := p_IsUniqueKey_fdaec289, p_IsReadOnly := p_IsReadOnly_fdaec289, p_IsRequired := p_IsRequired_fdaec289, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_fdaec289, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_fdaec289, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_fdaec289, p_Configuration := p_Configuration_fdaec289, p_Configuration_Clear := TRUE, p_Status := p_Status_fdaec289, p_IsCustom := p_IsCustom_fdaec289, p_MetadataSource := p_MetadataSource_fdaec289);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = '1A0024CB-35BF-4779-81BD-451DC511E550' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── postal_mail ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_cf1b1b8f UUID;
  p_IntegrationObjectID_cf1b1b8f UUID;
  p_Name_cf1b1b8f VARCHAR(255);
  p_DisplayName_cf1b1b8f VARCHAR(255);
  p_Description_cf1b1b8f TEXT;
  p_Category_cf1b1b8f VARCHAR(100);
  p_Type_cf1b1b8f VARCHAR(100);
  p_Length_cf1b1b8f INTEGER;
  p_Precision_cf1b1b8f INTEGER;
  p_Scale_cf1b1b8f INTEGER;
  p_AllowsNull_cf1b1b8f BOOLEAN;
  p_DefaultValue_cf1b1b8f VARCHAR(255);
  p_IsPrimaryKey_cf1b1b8f BOOLEAN;
  p_IsUniqueKey_cf1b1b8f BOOLEAN;
  p_IsReadOnly_cf1b1b8f BOOLEAN;
  p_IsRequired_cf1b1b8f BOOLEAN;
  p_RelatedIntegrationObjectID_cf1b1b8f UUID;
  p_RelatedIntegrationObjectFieldName_cf1b1b8f VARCHAR(255);
  p_Sequence_cf1b1b8f INTEGER;
  p_Configuration_cf1b1b8f TEXT;
  p_Status_cf1b1b8f VARCHAR(25);
  p_IsCustom_cf1b1b8f BOOLEAN;
  p_MetadataSource_cf1b1b8f VARCHAR(20);
BEGIN
  p_ID_cf1b1b8f := 'CF1B1B8F-005B-566A-A22A-C495535B718B';
  p_IntegrationObjectID_cf1b1b8f := 'C08F328E-9E0C-4BBB-A479-0F8E7B18C43F';
  p_Name_cf1b1b8f := 'hs_object_id';
  p_Description_cf1b1b8f := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_cf1b1b8f := 'string';
  p_AllowsNull_cf1b1b8f := FALSE;
  p_IsPrimaryKey_cf1b1b8f := TRUE;
  p_IsUniqueKey_cf1b1b8f := TRUE;
  p_IsReadOnly_cf1b1b8f := TRUE;
  p_IsRequired_cf1b1b8f := FALSE;
  p_Sequence_cf1b1b8f := 0;
  p_Status_cf1b1b8f := 'Active';
  p_IsCustom_cf1b1b8f := FALSE;
  p_MetadataSource_cf1b1b8f := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_cf1b1b8f, p_IntegrationObjectID := p_IntegrationObjectID_cf1b1b8f, p_Name := p_Name_cf1b1b8f, p_DisplayName := p_DisplayName_cf1b1b8f, p_DisplayName_Clear := TRUE, p_Description := p_Description_cf1b1b8f, p_Category := p_Category_cf1b1b8f, p_Category_Clear := TRUE, p_Type := p_Type_cf1b1b8f, p_Length := p_Length_cf1b1b8f, p_Length_Clear := TRUE, p_Precision := p_Precision_cf1b1b8f, p_Precision_Clear := TRUE, p_Scale := p_Scale_cf1b1b8f, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_cf1b1b8f, p_DefaultValue := p_DefaultValue_cf1b1b8f, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_cf1b1b8f, p_IsUniqueKey := p_IsUniqueKey_cf1b1b8f, p_IsReadOnly := p_IsReadOnly_cf1b1b8f, p_IsRequired := p_IsRequired_cf1b1b8f, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_cf1b1b8f, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_cf1b1b8f, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_cf1b1b8f, p_Configuration := p_Configuration_cf1b1b8f, p_Configuration_Clear := TRUE, p_Status := p_Status_cf1b1b8f, p_IsCustom := p_IsCustom_cf1b1b8f, p_MetadataSource := p_MetadataSource_cf1b1b8f);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = 'C08F328E-9E0C-4BBB-A479-0F8E7B18C43F' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── products ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_fc57b9a8 UUID;
  p_IntegrationObjectID_fc57b9a8 UUID;
  p_Name_fc57b9a8 VARCHAR(255);
  p_DisplayName_fc57b9a8 VARCHAR(255);
  p_Description_fc57b9a8 TEXT;
  p_Category_fc57b9a8 VARCHAR(100);
  p_Type_fc57b9a8 VARCHAR(100);
  p_Length_fc57b9a8 INTEGER;
  p_Precision_fc57b9a8 INTEGER;
  p_Scale_fc57b9a8 INTEGER;
  p_AllowsNull_fc57b9a8 BOOLEAN;
  p_DefaultValue_fc57b9a8 VARCHAR(255);
  p_IsPrimaryKey_fc57b9a8 BOOLEAN;
  p_IsUniqueKey_fc57b9a8 BOOLEAN;
  p_IsReadOnly_fc57b9a8 BOOLEAN;
  p_IsRequired_fc57b9a8 BOOLEAN;
  p_RelatedIntegrationObjectID_fc57b9a8 UUID;
  p_RelatedIntegrationObjectFieldName_fc57b9a8 VARCHAR(255);
  p_Sequence_fc57b9a8 INTEGER;
  p_Configuration_fc57b9a8 TEXT;
  p_Status_fc57b9a8 VARCHAR(25);
  p_IsCustom_fc57b9a8 BOOLEAN;
  p_MetadataSource_fc57b9a8 VARCHAR(20);
BEGIN
  p_ID_fc57b9a8 := 'FC57B9A8-21B8-5907-B331-8EA322D7AE60';
  p_IntegrationObjectID_fc57b9a8 := '45AE9111-95F7-4C1C-8722-119E10D3BB8D';
  p_Name_fc57b9a8 := 'hs_object_id';
  p_Description_fc57b9a8 := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_fc57b9a8 := 'string';
  p_AllowsNull_fc57b9a8 := FALSE;
  p_IsPrimaryKey_fc57b9a8 := TRUE;
  p_IsUniqueKey_fc57b9a8 := TRUE;
  p_IsReadOnly_fc57b9a8 := TRUE;
  p_IsRequired_fc57b9a8 := FALSE;
  p_Sequence_fc57b9a8 := 0;
  p_Status_fc57b9a8 := 'Active';
  p_IsCustom_fc57b9a8 := FALSE;
  p_MetadataSource_fc57b9a8 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_fc57b9a8, p_IntegrationObjectID := p_IntegrationObjectID_fc57b9a8, p_Name := p_Name_fc57b9a8, p_DisplayName := p_DisplayName_fc57b9a8, p_DisplayName_Clear := TRUE, p_Description := p_Description_fc57b9a8, p_Category := p_Category_fc57b9a8, p_Category_Clear := TRUE, p_Type := p_Type_fc57b9a8, p_Length := p_Length_fc57b9a8, p_Length_Clear := TRUE, p_Precision := p_Precision_fc57b9a8, p_Precision_Clear := TRUE, p_Scale := p_Scale_fc57b9a8, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_fc57b9a8, p_DefaultValue := p_DefaultValue_fc57b9a8, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_fc57b9a8, p_IsUniqueKey := p_IsUniqueKey_fc57b9a8, p_IsReadOnly := p_IsReadOnly_fc57b9a8, p_IsRequired := p_IsRequired_fc57b9a8, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_fc57b9a8, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_fc57b9a8, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_fc57b9a8, p_Configuration := p_Configuration_fc57b9a8, p_Configuration_Clear := TRUE, p_Status := p_Status_fc57b9a8, p_IsCustom := p_IsCustom_fc57b9a8, p_MetadataSource := p_MetadataSource_fc57b9a8);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = '45AE9111-95F7-4C1C-8722-119E10D3BB8D' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── projects ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_a0492ec6 UUID;
  p_IntegrationObjectID_a0492ec6 UUID;
  p_Name_a0492ec6 VARCHAR(255);
  p_DisplayName_a0492ec6 VARCHAR(255);
  p_Description_a0492ec6 TEXT;
  p_Category_a0492ec6 VARCHAR(100);
  p_Type_a0492ec6 VARCHAR(100);
  p_Length_a0492ec6 INTEGER;
  p_Precision_a0492ec6 INTEGER;
  p_Scale_a0492ec6 INTEGER;
  p_AllowsNull_a0492ec6 BOOLEAN;
  p_DefaultValue_a0492ec6 VARCHAR(255);
  p_IsPrimaryKey_a0492ec6 BOOLEAN;
  p_IsUniqueKey_a0492ec6 BOOLEAN;
  p_IsReadOnly_a0492ec6 BOOLEAN;
  p_IsRequired_a0492ec6 BOOLEAN;
  p_RelatedIntegrationObjectID_a0492ec6 UUID;
  p_RelatedIntegrationObjectFieldName_a0492ec6 VARCHAR(255);
  p_Sequence_a0492ec6 INTEGER;
  p_Configuration_a0492ec6 TEXT;
  p_Status_a0492ec6 VARCHAR(25);
  p_IsCustom_a0492ec6 BOOLEAN;
  p_MetadataSource_a0492ec6 VARCHAR(20);
BEGIN
  p_ID_a0492ec6 := 'A0492EC6-1C3C-5B74-B3F6-7699A72D869C';
  p_IntegrationObjectID_a0492ec6 := 'BA2ED838-9A80-4522-8737-55F6A5F71921';
  p_Name_a0492ec6 := 'hs_object_id';
  p_Description_a0492ec6 := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_a0492ec6 := 'string';
  p_AllowsNull_a0492ec6 := FALSE;
  p_IsPrimaryKey_a0492ec6 := TRUE;
  p_IsUniqueKey_a0492ec6 := TRUE;
  p_IsReadOnly_a0492ec6 := TRUE;
  p_IsRequired_a0492ec6 := FALSE;
  p_Sequence_a0492ec6 := 0;
  p_Status_a0492ec6 := 'Active';
  p_IsCustom_a0492ec6 := FALSE;
  p_MetadataSource_a0492ec6 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_a0492ec6, p_IntegrationObjectID := p_IntegrationObjectID_a0492ec6, p_Name := p_Name_a0492ec6, p_DisplayName := p_DisplayName_a0492ec6, p_DisplayName_Clear := TRUE, p_Description := p_Description_a0492ec6, p_Category := p_Category_a0492ec6, p_Category_Clear := TRUE, p_Type := p_Type_a0492ec6, p_Length := p_Length_a0492ec6, p_Length_Clear := TRUE, p_Precision := p_Precision_a0492ec6, p_Precision_Clear := TRUE, p_Scale := p_Scale_a0492ec6, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_a0492ec6, p_DefaultValue := p_DefaultValue_a0492ec6, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_a0492ec6, p_IsUniqueKey := p_IsUniqueKey_a0492ec6, p_IsReadOnly := p_IsReadOnly_a0492ec6, p_IsRequired := p_IsRequired_a0492ec6, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_a0492ec6, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_a0492ec6, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_a0492ec6, p_Configuration := p_Configuration_a0492ec6, p_Configuration_Clear := TRUE, p_Status := p_Status_a0492ec6, p_IsCustom := p_IsCustom_a0492ec6, p_MetadataSource := p_MetadataSource_a0492ec6);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = 'BA2ED838-9A80-4522-8737-55F6A5F71921' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── quotes ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_079b4e6f UUID;
  p_IntegrationObjectID_079b4e6f UUID;
  p_Name_079b4e6f VARCHAR(255);
  p_DisplayName_079b4e6f VARCHAR(255);
  p_Description_079b4e6f TEXT;
  p_Category_079b4e6f VARCHAR(100);
  p_Type_079b4e6f VARCHAR(100);
  p_Length_079b4e6f INTEGER;
  p_Precision_079b4e6f INTEGER;
  p_Scale_079b4e6f INTEGER;
  p_AllowsNull_079b4e6f BOOLEAN;
  p_DefaultValue_079b4e6f VARCHAR(255);
  p_IsPrimaryKey_079b4e6f BOOLEAN;
  p_IsUniqueKey_079b4e6f BOOLEAN;
  p_IsReadOnly_079b4e6f BOOLEAN;
  p_IsRequired_079b4e6f BOOLEAN;
  p_RelatedIntegrationObjectID_079b4e6f UUID;
  p_RelatedIntegrationObjectFieldName_079b4e6f VARCHAR(255);
  p_Sequence_079b4e6f INTEGER;
  p_Configuration_079b4e6f TEXT;
  p_Status_079b4e6f VARCHAR(25);
  p_IsCustom_079b4e6f BOOLEAN;
  p_MetadataSource_079b4e6f VARCHAR(20);
BEGIN
  p_ID_079b4e6f := '079B4E6F-2085-576C-8BDC-A4B30652D92F';
  p_IntegrationObjectID_079b4e6f := '1E976648-625B-4955-9074-575C7E1B3BDA';
  p_Name_079b4e6f := 'hs_object_id';
  p_Description_079b4e6f := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_079b4e6f := 'string';
  p_AllowsNull_079b4e6f := FALSE;
  p_IsPrimaryKey_079b4e6f := TRUE;
  p_IsUniqueKey_079b4e6f := TRUE;
  p_IsReadOnly_079b4e6f := TRUE;
  p_IsRequired_079b4e6f := FALSE;
  p_Sequence_079b4e6f := 0;
  p_Status_079b4e6f := 'Active';
  p_IsCustom_079b4e6f := FALSE;
  p_MetadataSource_079b4e6f := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_079b4e6f, p_IntegrationObjectID := p_IntegrationObjectID_079b4e6f, p_Name := p_Name_079b4e6f, p_DisplayName := p_DisplayName_079b4e6f, p_DisplayName_Clear := TRUE, p_Description := p_Description_079b4e6f, p_Category := p_Category_079b4e6f, p_Category_Clear := TRUE, p_Type := p_Type_079b4e6f, p_Length := p_Length_079b4e6f, p_Length_Clear := TRUE, p_Precision := p_Precision_079b4e6f, p_Precision_Clear := TRUE, p_Scale := p_Scale_079b4e6f, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_079b4e6f, p_DefaultValue := p_DefaultValue_079b4e6f, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_079b4e6f, p_IsUniqueKey := p_IsUniqueKey_079b4e6f, p_IsReadOnly := p_IsReadOnly_079b4e6f, p_IsRequired := p_IsRequired_079b4e6f, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_079b4e6f, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_079b4e6f, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_079b4e6f, p_Configuration := p_Configuration_079b4e6f, p_Configuration_Clear := TRUE, p_Status := p_Status_079b4e6f, p_IsCustom := p_IsCustom_079b4e6f, p_MetadataSource := p_MetadataSource_079b4e6f);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = '1E976648-625B-4955-9074-575C7E1B3BDA' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── services ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_d2663254 UUID;
  p_IntegrationObjectID_d2663254 UUID;
  p_Name_d2663254 VARCHAR(255);
  p_DisplayName_d2663254 VARCHAR(255);
  p_Description_d2663254 TEXT;
  p_Category_d2663254 VARCHAR(100);
  p_Type_d2663254 VARCHAR(100);
  p_Length_d2663254 INTEGER;
  p_Precision_d2663254 INTEGER;
  p_Scale_d2663254 INTEGER;
  p_AllowsNull_d2663254 BOOLEAN;
  p_DefaultValue_d2663254 VARCHAR(255);
  p_IsPrimaryKey_d2663254 BOOLEAN;
  p_IsUniqueKey_d2663254 BOOLEAN;
  p_IsReadOnly_d2663254 BOOLEAN;
  p_IsRequired_d2663254 BOOLEAN;
  p_RelatedIntegrationObjectID_d2663254 UUID;
  p_RelatedIntegrationObjectFieldName_d2663254 VARCHAR(255);
  p_Sequence_d2663254 INTEGER;
  p_Configuration_d2663254 TEXT;
  p_Status_d2663254 VARCHAR(25);
  p_IsCustom_d2663254 BOOLEAN;
  p_MetadataSource_d2663254 VARCHAR(20);
BEGIN
  p_ID_d2663254 := 'D2663254-282C-5D76-90EE-2CEF960E45F8';
  p_IntegrationObjectID_d2663254 := '8413DEB6-719C-4155-A0E7-F4D0366E1C0C';
  p_Name_d2663254 := 'hs_object_id';
  p_Description_d2663254 := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_d2663254 := 'string';
  p_AllowsNull_d2663254 := FALSE;
  p_IsPrimaryKey_d2663254 := TRUE;
  p_IsUniqueKey_d2663254 := TRUE;
  p_IsReadOnly_d2663254 := TRUE;
  p_IsRequired_d2663254 := FALSE;
  p_Sequence_d2663254 := 0;
  p_Status_d2663254 := 'Active';
  p_IsCustom_d2663254 := FALSE;
  p_MetadataSource_d2663254 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_d2663254, p_IntegrationObjectID := p_IntegrationObjectID_d2663254, p_Name := p_Name_d2663254, p_DisplayName := p_DisplayName_d2663254, p_DisplayName_Clear := TRUE, p_Description := p_Description_d2663254, p_Category := p_Category_d2663254, p_Category_Clear := TRUE, p_Type := p_Type_d2663254, p_Length := p_Length_d2663254, p_Length_Clear := TRUE, p_Precision := p_Precision_d2663254, p_Precision_Clear := TRUE, p_Scale := p_Scale_d2663254, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_d2663254, p_DefaultValue := p_DefaultValue_d2663254, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_d2663254, p_IsUniqueKey := p_IsUniqueKey_d2663254, p_IsReadOnly := p_IsReadOnly_d2663254, p_IsRequired := p_IsRequired_d2663254, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_d2663254, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_d2663254, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_d2663254, p_Configuration := p_Configuration_d2663254, p_Configuration_Clear := TRUE, p_Status := p_Status_d2663254, p_IsCustom := p_IsCustom_d2663254, p_MetadataSource := p_MetadataSource_d2663254);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = '8413DEB6-719C-4155-A0E7-F4D0366E1C0C' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── subscriptions ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_58bb01de UUID;
  p_IntegrationObjectID_58bb01de UUID;
  p_Name_58bb01de VARCHAR(255);
  p_DisplayName_58bb01de VARCHAR(255);
  p_Description_58bb01de TEXT;
  p_Category_58bb01de VARCHAR(100);
  p_Type_58bb01de VARCHAR(100);
  p_Length_58bb01de INTEGER;
  p_Precision_58bb01de INTEGER;
  p_Scale_58bb01de INTEGER;
  p_AllowsNull_58bb01de BOOLEAN;
  p_DefaultValue_58bb01de VARCHAR(255);
  p_IsPrimaryKey_58bb01de BOOLEAN;
  p_IsUniqueKey_58bb01de BOOLEAN;
  p_IsReadOnly_58bb01de BOOLEAN;
  p_IsRequired_58bb01de BOOLEAN;
  p_RelatedIntegrationObjectID_58bb01de UUID;
  p_RelatedIntegrationObjectFieldName_58bb01de VARCHAR(255);
  p_Sequence_58bb01de INTEGER;
  p_Configuration_58bb01de TEXT;
  p_Status_58bb01de VARCHAR(25);
  p_IsCustom_58bb01de BOOLEAN;
  p_MetadataSource_58bb01de VARCHAR(20);
BEGIN
  p_ID_58bb01de := '58BB01DE-7BFB-57B9-AF58-0C06B75424EB';
  p_IntegrationObjectID_58bb01de := '1ED82C55-E9AF-4D39-96A6-79B1A23F7CCF';
  p_Name_58bb01de := 'hs_object_id';
  p_Description_58bb01de := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_58bb01de := 'string';
  p_AllowsNull_58bb01de := FALSE;
  p_IsPrimaryKey_58bb01de := TRUE;
  p_IsUniqueKey_58bb01de := TRUE;
  p_IsReadOnly_58bb01de := TRUE;
  p_IsRequired_58bb01de := FALSE;
  p_Sequence_58bb01de := 0;
  p_Status_58bb01de := 'Active';
  p_IsCustom_58bb01de := FALSE;
  p_MetadataSource_58bb01de := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_58bb01de, p_IntegrationObjectID := p_IntegrationObjectID_58bb01de, p_Name := p_Name_58bb01de, p_DisplayName := p_DisplayName_58bb01de, p_DisplayName_Clear := TRUE, p_Description := p_Description_58bb01de, p_Category := p_Category_58bb01de, p_Category_Clear := TRUE, p_Type := p_Type_58bb01de, p_Length := p_Length_58bb01de, p_Length_Clear := TRUE, p_Precision := p_Precision_58bb01de, p_Precision_Clear := TRUE, p_Scale := p_Scale_58bb01de, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_58bb01de, p_DefaultValue := p_DefaultValue_58bb01de, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_58bb01de, p_IsUniqueKey := p_IsUniqueKey_58bb01de, p_IsReadOnly := p_IsReadOnly_58bb01de, p_IsRequired := p_IsRequired_58bb01de, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_58bb01de, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_58bb01de, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_58bb01de, p_Configuration := p_Configuration_58bb01de, p_Configuration_Clear := TRUE, p_Status := p_Status_58bb01de, p_IsCustom := p_IsCustom_58bb01de, p_MetadataSource := p_MetadataSource_58bb01de);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = '1ED82C55-E9AF-4D39-96A6-79B1A23F7CCF' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── tasks ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_92e54acc UUID;
  p_IntegrationObjectID_92e54acc UUID;
  p_Name_92e54acc VARCHAR(255);
  p_DisplayName_92e54acc VARCHAR(255);
  p_Description_92e54acc TEXT;
  p_Category_92e54acc VARCHAR(100);
  p_Type_92e54acc VARCHAR(100);
  p_Length_92e54acc INTEGER;
  p_Precision_92e54acc INTEGER;
  p_Scale_92e54acc INTEGER;
  p_AllowsNull_92e54acc BOOLEAN;
  p_DefaultValue_92e54acc VARCHAR(255);
  p_IsPrimaryKey_92e54acc BOOLEAN;
  p_IsUniqueKey_92e54acc BOOLEAN;
  p_IsReadOnly_92e54acc BOOLEAN;
  p_IsRequired_92e54acc BOOLEAN;
  p_RelatedIntegrationObjectID_92e54acc UUID;
  p_RelatedIntegrationObjectFieldName_92e54acc VARCHAR(255);
  p_Sequence_92e54acc INTEGER;
  p_Configuration_92e54acc TEXT;
  p_Status_92e54acc VARCHAR(25);
  p_IsCustom_92e54acc BOOLEAN;
  p_MetadataSource_92e54acc VARCHAR(20);
BEGIN
  p_ID_92e54acc := '92E54ACC-E94B-5160-98CE-034B581B9446';
  p_IntegrationObjectID_92e54acc := '1E9F77D7-478D-4646-A7A4-2F6D5E1C5891';
  p_Name_92e54acc := 'hs_object_id';
  p_Description_92e54acc := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_92e54acc := 'string';
  p_AllowsNull_92e54acc := FALSE;
  p_IsPrimaryKey_92e54acc := TRUE;
  p_IsUniqueKey_92e54acc := TRUE;
  p_IsReadOnly_92e54acc := TRUE;
  p_IsRequired_92e54acc := FALSE;
  p_Sequence_92e54acc := 0;
  p_Status_92e54acc := 'Active';
  p_IsCustom_92e54acc := FALSE;
  p_MetadataSource_92e54acc := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_92e54acc, p_IntegrationObjectID := p_IntegrationObjectID_92e54acc, p_Name := p_Name_92e54acc, p_DisplayName := p_DisplayName_92e54acc, p_DisplayName_Clear := TRUE, p_Description := p_Description_92e54acc, p_Category := p_Category_92e54acc, p_Category_Clear := TRUE, p_Type := p_Type_92e54acc, p_Length := p_Length_92e54acc, p_Length_Clear := TRUE, p_Precision := p_Precision_92e54acc, p_Precision_Clear := TRUE, p_Scale := p_Scale_92e54acc, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_92e54acc, p_DefaultValue := p_DefaultValue_92e54acc, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_92e54acc, p_IsUniqueKey := p_IsUniqueKey_92e54acc, p_IsReadOnly := p_IsReadOnly_92e54acc, p_IsRequired := p_IsRequired_92e54acc, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_92e54acc, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_92e54acc, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_92e54acc, p_Configuration := p_Configuration_92e54acc, p_Configuration_Clear := TRUE, p_Status := p_Status_92e54acc, p_IsCustom := p_IsCustom_92e54acc, p_MetadataSource := p_MetadataSource_92e54acc);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = '1E9F77D7-478D-4646-A7A4-2F6D5E1C5891' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── taxes ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_993a3ac9 UUID;
  p_IntegrationObjectID_993a3ac9 UUID;
  p_Name_993a3ac9 VARCHAR(255);
  p_DisplayName_993a3ac9 VARCHAR(255);
  p_Description_993a3ac9 TEXT;
  p_Category_993a3ac9 VARCHAR(100);
  p_Type_993a3ac9 VARCHAR(100);
  p_Length_993a3ac9 INTEGER;
  p_Precision_993a3ac9 INTEGER;
  p_Scale_993a3ac9 INTEGER;
  p_AllowsNull_993a3ac9 BOOLEAN;
  p_DefaultValue_993a3ac9 VARCHAR(255);
  p_IsPrimaryKey_993a3ac9 BOOLEAN;
  p_IsUniqueKey_993a3ac9 BOOLEAN;
  p_IsReadOnly_993a3ac9 BOOLEAN;
  p_IsRequired_993a3ac9 BOOLEAN;
  p_RelatedIntegrationObjectID_993a3ac9 UUID;
  p_RelatedIntegrationObjectFieldName_993a3ac9 VARCHAR(255);
  p_Sequence_993a3ac9 INTEGER;
  p_Configuration_993a3ac9 TEXT;
  p_Status_993a3ac9 VARCHAR(25);
  p_IsCustom_993a3ac9 BOOLEAN;
  p_MetadataSource_993a3ac9 VARCHAR(20);
BEGIN
  p_ID_993a3ac9 := '993A3AC9-F891-5911-B884-C3E81126FBC1';
  p_IntegrationObjectID_993a3ac9 := 'E5BF150E-D089-4993-90E8-2E5FC057B9A7';
  p_Name_993a3ac9 := 'hs_object_id';
  p_Description_993a3ac9 := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_993a3ac9 := 'string';
  p_AllowsNull_993a3ac9 := FALSE;
  p_IsPrimaryKey_993a3ac9 := TRUE;
  p_IsUniqueKey_993a3ac9 := TRUE;
  p_IsReadOnly_993a3ac9 := TRUE;
  p_IsRequired_993a3ac9 := FALSE;
  p_Sequence_993a3ac9 := 0;
  p_Status_993a3ac9 := 'Active';
  p_IsCustom_993a3ac9 := FALSE;
  p_MetadataSource_993a3ac9 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_993a3ac9, p_IntegrationObjectID := p_IntegrationObjectID_993a3ac9, p_Name := p_Name_993a3ac9, p_DisplayName := p_DisplayName_993a3ac9, p_DisplayName_Clear := TRUE, p_Description := p_Description_993a3ac9, p_Category := p_Category_993a3ac9, p_Category_Clear := TRUE, p_Type := p_Type_993a3ac9, p_Length := p_Length_993a3ac9, p_Length_Clear := TRUE, p_Precision := p_Precision_993a3ac9, p_Precision_Clear := TRUE, p_Scale := p_Scale_993a3ac9, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_993a3ac9, p_DefaultValue := p_DefaultValue_993a3ac9, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_993a3ac9, p_IsUniqueKey := p_IsUniqueKey_993a3ac9, p_IsReadOnly := p_IsReadOnly_993a3ac9, p_IsRequired := p_IsRequired_993a3ac9, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_993a3ac9, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_993a3ac9, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_993a3ac9, p_Configuration := p_Configuration_993a3ac9, p_Configuration_Clear := TRUE, p_Status := p_Status_993a3ac9, p_IsCustom := p_IsCustom_993a3ac9, p_MetadataSource := p_MetadataSource_993a3ac9);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = 'E5BF150E-D089-4993-90E8-2E5FC057B9A7' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── tickets ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_df1cbb08 UUID;
  p_IntegrationObjectID_df1cbb08 UUID;
  p_Name_df1cbb08 VARCHAR(255);
  p_DisplayName_df1cbb08 VARCHAR(255);
  p_Description_df1cbb08 TEXT;
  p_Category_df1cbb08 VARCHAR(100);
  p_Type_df1cbb08 VARCHAR(100);
  p_Length_df1cbb08 INTEGER;
  p_Precision_df1cbb08 INTEGER;
  p_Scale_df1cbb08 INTEGER;
  p_AllowsNull_df1cbb08 BOOLEAN;
  p_DefaultValue_df1cbb08 VARCHAR(255);
  p_IsPrimaryKey_df1cbb08 BOOLEAN;
  p_IsUniqueKey_df1cbb08 BOOLEAN;
  p_IsReadOnly_df1cbb08 BOOLEAN;
  p_IsRequired_df1cbb08 BOOLEAN;
  p_RelatedIntegrationObjectID_df1cbb08 UUID;
  p_RelatedIntegrationObjectFieldName_df1cbb08 VARCHAR(255);
  p_Sequence_df1cbb08 INTEGER;
  p_Configuration_df1cbb08 TEXT;
  p_Status_df1cbb08 VARCHAR(25);
  p_IsCustom_df1cbb08 BOOLEAN;
  p_MetadataSource_df1cbb08 VARCHAR(20);
BEGIN
  p_ID_df1cbb08 := 'DF1CBB08-F466-556E-97CE-E4EF98D50C3C';
  p_IntegrationObjectID_df1cbb08 := '47E8CF5F-9009-4253-9E4E-482527C28D92';
  p_Name_df1cbb08 := 'hs_object_id';
  p_Description_df1cbb08 := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_df1cbb08 := 'string';
  p_AllowsNull_df1cbb08 := FALSE;
  p_IsPrimaryKey_df1cbb08 := TRUE;
  p_IsUniqueKey_df1cbb08 := TRUE;
  p_IsReadOnly_df1cbb08 := TRUE;
  p_IsRequired_df1cbb08 := FALSE;
  p_Sequence_df1cbb08 := 0;
  p_Status_df1cbb08 := 'Active';
  p_IsCustom_df1cbb08 := FALSE;
  p_MetadataSource_df1cbb08 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_df1cbb08, p_IntegrationObjectID := p_IntegrationObjectID_df1cbb08, p_Name := p_Name_df1cbb08, p_DisplayName := p_DisplayName_df1cbb08, p_DisplayName_Clear := TRUE, p_Description := p_Description_df1cbb08, p_Category := p_Category_df1cbb08, p_Category_Clear := TRUE, p_Type := p_Type_df1cbb08, p_Length := p_Length_df1cbb08, p_Length_Clear := TRUE, p_Precision := p_Precision_df1cbb08, p_Precision_Clear := TRUE, p_Scale := p_Scale_df1cbb08, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_df1cbb08, p_DefaultValue := p_DefaultValue_df1cbb08, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_df1cbb08, p_IsUniqueKey := p_IsUniqueKey_df1cbb08, p_IsReadOnly := p_IsReadOnly_df1cbb08, p_IsRequired := p_IsRequired_df1cbb08, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_df1cbb08, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_df1cbb08, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_df1cbb08, p_Configuration := p_Configuration_df1cbb08, p_Configuration_Clear := TRUE, p_Status := p_Status_df1cbb08, p_IsCustom := p_IsCustom_df1cbb08, p_MetadataSource := p_MetadataSource_df1cbb08);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = '47E8CF5F-9009-4253-9E4E-482527C28D92' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;

-- ── users ──────────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_c10125d5 UUID;
  p_IntegrationObjectID_c10125d5 UUID;
  p_Name_c10125d5 VARCHAR(255);
  p_DisplayName_c10125d5 VARCHAR(255);
  p_Description_c10125d5 TEXT;
  p_Category_c10125d5 VARCHAR(100);
  p_Type_c10125d5 VARCHAR(100);
  p_Length_c10125d5 INTEGER;
  p_Precision_c10125d5 INTEGER;
  p_Scale_c10125d5 INTEGER;
  p_AllowsNull_c10125d5 BOOLEAN;
  p_DefaultValue_c10125d5 VARCHAR(255);
  p_IsPrimaryKey_c10125d5 BOOLEAN;
  p_IsUniqueKey_c10125d5 BOOLEAN;
  p_IsReadOnly_c10125d5 BOOLEAN;
  p_IsRequired_c10125d5 BOOLEAN;
  p_RelatedIntegrationObjectID_c10125d5 UUID;
  p_RelatedIntegrationObjectFieldName_c10125d5 VARCHAR(255);
  p_Sequence_c10125d5 INTEGER;
  p_Configuration_c10125d5 TEXT;
  p_Status_c10125d5 VARCHAR(25);
  p_IsCustom_c10125d5 BOOLEAN;
  p_MetadataSource_c10125d5 VARCHAR(20);
BEGIN
  p_ID_c10125d5 := 'C10125D5-33E1-5BEC-9831-B391ACE08DD1';
  p_IntegrationObjectID_c10125d5 := 'F45AB26D-09A1-4F8F-B185-2F567C0DD9ED';
  p_Name_c10125d5 := 'hs_object_id';
  p_Description_c10125d5 := 'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)';
  p_Type_c10125d5 := 'string';
  p_AllowsNull_c10125d5 := FALSE;
  p_IsPrimaryKey_c10125d5 := TRUE;
  p_IsUniqueKey_c10125d5 := TRUE;
  p_IsReadOnly_c10125d5 := TRUE;
  p_IsRequired_c10125d5 := FALSE;
  p_Sequence_c10125d5 := 0;
  p_Status_c10125d5 := 'Active';
  p_IsCustom_c10125d5 := FALSE;
  p_MetadataSource_c10125d5 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_c10125d5, p_IntegrationObjectID := p_IntegrationObjectID_c10125d5, p_Name := p_Name_c10125d5, p_DisplayName := p_DisplayName_c10125d5, p_DisplayName_Clear := TRUE, p_Description := p_Description_c10125d5, p_Category := p_Category_c10125d5, p_Category_Clear := TRUE, p_Type := p_Type_c10125d5, p_Length := p_Length_c10125d5, p_Length_Clear := TRUE, p_Precision := p_Precision_c10125d5, p_Precision_Clear := TRUE, p_Scale := p_Scale_c10125d5, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_c10125d5, p_DefaultValue := p_DefaultValue_c10125d5, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_c10125d5, p_IsUniqueKey := p_IsUniqueKey_c10125d5, p_IsReadOnly := p_IsReadOnly_c10125d5, p_IsRequired := p_IsRequired_c10125d5, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_c10125d5, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_c10125d5, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_c10125d5, p_Configuration := p_Configuration_c10125d5, p_Configuration_Clear := TRUE, p_Status := p_Status_c10125d5, p_IsCustom := p_IsCustom_c10125d5, p_MetadataSource := p_MetadataSource_c10125d5);
END $mj$;

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = FALSE
WHERE "IntegrationObjectID" = 'F45AB26D-09A1-4F8F-B185-2F567C0DD9ED' AND "Name" = 'id' AND "IsPrimaryKey" = TRUE;
