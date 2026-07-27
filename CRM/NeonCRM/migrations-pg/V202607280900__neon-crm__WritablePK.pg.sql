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

-- Neon CRM: the six writable custom-object catalog rows that carried no primary key.
--
-- A writable IntegrationObject with no IsPrimaryKey field yields a KEYLESS derived entity. On
-- Postgres, MJ's save audit-wrapper then emits an empty record identifier and every save fails with
--     syntax error at or near ","
-- while fetch keeps succeeding — so the object reads green and persists nothing.
--
-- The Neon custom-object family models each resource TWICE: a request-BODY shape (Status=Disabled,
-- empty APIPath, Configuration.NoEnumerableEndpoint=true) and the readable record `<X>Response`
-- (Status=Active, enumerable through /customObjects, carrying the vendor's own DetailAPIPath). The
-- write capability was declared on the body shapes; the keys belong on the records.
--
-- 1-2. CustomObjectFormLayoutResponse / CustomObjectListLayoutResponse -> CREATE `id` (bigint).
--      Neon's API v2.10 release notes (2025-04-14) publish the full item surface:
--          GET | PUT/PATCH | DELETE /customObjects/{apiAlias}/formLayouts/{id}
--          GET | PUT/PATCH | DELETE /customObjects/{apiAlias}/listLayouts/{id}
--      `{id}` is the vendor's own addressing token and already appears in each object's declared
--      DetailAPIPath and DeleteAPIPath — the catalog simply never declared the field. bigint matches
--      the sibling keys in this family (CustomObjectValidatorRuleResponse.id, CustomObjectResponse
--      .objectId, CustomObjectLayoutPageItem.layoutId, CustomObjectRelation.relationId).
--
-- 3-5. CustomObjectFormLayout / CustomObjectListLayout / CustomObjectValidatorRule -> WITHDRAW write.
--      Request-body shapes, not records: Status=Disabled, no APIPath, NoEnumerableEndpoint. Each
--      one's field set is a strict SUBSET of its `<X>Response` sibling, which is the keyed record
--      the vendor addresses. Their create/update is NOT re-homed here: these rows are Disabled, so
--      the operation has never run against a tenant, and re-homing it would newly enable an
--      unverified write path — the opposite of what this migration is for. Re-homing belongs in a
--      change that can verify the request body live.
--
-- 6.   CustomObjectField -> WITHDRAW write.
--      Same request-body shape, and it has no identifier at all: the vendor addresses a field as
--      /customObjects/{idOrApiAlias}/fields/{fieldAlias}, and this shape declares no alias. Its
--      `<X>Response` sibling is NOT a faithful create target either — the Response collapses the 19
--      typed attribute variants (textAttribute, numberAttribute, dropdownAttribute, …) into a single
--      `attribute` object, so moving the create would silently change the request body.
--
-- DELTA migration, deliberately not a re-seed: the catalog rows already exist on installed tenants,
-- so the V202606271401 seed stays untouched and applied — no existing UUID is re-minted, no Flyway
-- checksum breaks, no UQ collision. Every statement is idempotent (keyed by the seeded row ID).
-- Created fields carry UUID5 IDs derived from
--     uuid5(DNS, 'memberjunction.integrations/<integration>/<object>/<field>')
-- so regenerating this file yields byte-identical UUIDs rather than fresh random ones.

-- ── 1. CustomObjectFormLayoutResponse.id ─────────────────────────────────────
DO $mj$
DECLARE
  p_ID_9f96c423 UUID;
  p_IntegrationObjectID_9f96c423 UUID;
  p_Name_9f96c423 VARCHAR(255);
  p_DisplayName_9f96c423 VARCHAR(255);
  p_Description_9f96c423 TEXT;
  p_Category_9f96c423 VARCHAR(100);
  p_Type_9f96c423 VARCHAR(100);
  p_Length_9f96c423 INTEGER;
  p_Precision_9f96c423 INTEGER;
  p_Scale_9f96c423 INTEGER;
  p_AllowsNull_9f96c423 BOOLEAN;
  p_DefaultValue_9f96c423 VARCHAR(255);
  p_IsPrimaryKey_9f96c423 BOOLEAN;
  p_IsUniqueKey_9f96c423 BOOLEAN;
  p_IsReadOnly_9f96c423 BOOLEAN;
  p_IsRequired_9f96c423 BOOLEAN;
  p_RelatedIntegrationObjectID_9f96c423 UUID;
  p_RelatedIntegrationObjectFieldName_9f96c423 VARCHAR(255);
  p_Sequence_9f96c423 INTEGER;
  p_Configuration_9f96c423 TEXT;
  p_Status_9f96c423 VARCHAR(25);
  p_IsCustom_9f96c423 BOOLEAN;
  p_MetadataSource_9f96c423 VARCHAR(20);
BEGIN
  p_ID_9f96c423 := '0175F819-5419-5FC1-9896-DB6D5828BA15';
  p_IntegrationObjectID_9f96c423 := '28EEA466-FF9F-4E7F-8A28-A6C36F095DCF';
  p_Name_9f96c423 := 'id';
  p_Type_9f96c423 := 'bigint';
  p_AllowsNull_9f96c423 := FALSE;
  p_IsPrimaryKey_9f96c423 := TRUE;
  p_IsUniqueKey_9f96c423 := TRUE;
  p_IsReadOnly_9f96c423 := FALSE;
  p_IsRequired_9f96c423 := FALSE;
  p_Sequence_9f96c423 := 0;
  p_Status_9f96c423 := 'Active';
  p_IsCustom_9f96c423 := FALSE;
  p_MetadataSource_9f96c423 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_9f96c423, p_IntegrationObjectID := p_IntegrationObjectID_9f96c423, p_Name := p_Name_9f96c423, p_DisplayName := p_DisplayName_9f96c423, p_DisplayName_Clear := TRUE, p_Description := p_Description_9f96c423, p_Description_Clear := TRUE, p_Category := p_Category_9f96c423, p_Category_Clear := TRUE, p_Type := p_Type_9f96c423, p_Length := p_Length_9f96c423, p_Length_Clear := TRUE, p_Precision := p_Precision_9f96c423, p_Precision_Clear := TRUE, p_Scale := p_Scale_9f96c423, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_9f96c423, p_DefaultValue := p_DefaultValue_9f96c423, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_9f96c423, p_IsUniqueKey := p_IsUniqueKey_9f96c423, p_IsReadOnly := p_IsReadOnly_9f96c423, p_IsRequired := p_IsRequired_9f96c423, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_9f96c423, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_9f96c423, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_9f96c423, p_Configuration := p_Configuration_9f96c423, p_Configuration_Clear := TRUE, p_Status := p_Status_9f96c423, p_IsCustom := p_IsCustom_9f96c423, p_MetadataSource := p_MetadataSource_9f96c423);
END $mj$;

-- ── 2. CustomObjectListLayoutResponse.id ─────────────────────────────────────
DO $mj$
DECLARE
  p_ID_786d5849 UUID;
  p_IntegrationObjectID_786d5849 UUID;
  p_Name_786d5849 VARCHAR(255);
  p_DisplayName_786d5849 VARCHAR(255);
  p_Description_786d5849 TEXT;
  p_Category_786d5849 VARCHAR(100);
  p_Type_786d5849 VARCHAR(100);
  p_Length_786d5849 INTEGER;
  p_Precision_786d5849 INTEGER;
  p_Scale_786d5849 INTEGER;
  p_AllowsNull_786d5849 BOOLEAN;
  p_DefaultValue_786d5849 VARCHAR(255);
  p_IsPrimaryKey_786d5849 BOOLEAN;
  p_IsUniqueKey_786d5849 BOOLEAN;
  p_IsReadOnly_786d5849 BOOLEAN;
  p_IsRequired_786d5849 BOOLEAN;
  p_RelatedIntegrationObjectID_786d5849 UUID;
  p_RelatedIntegrationObjectFieldName_786d5849 VARCHAR(255);
  p_Sequence_786d5849 INTEGER;
  p_Configuration_786d5849 TEXT;
  p_Status_786d5849 VARCHAR(25);
  p_IsCustom_786d5849 BOOLEAN;
  p_MetadataSource_786d5849 VARCHAR(20);
BEGIN
  p_ID_786d5849 := '01B8BA30-E6B4-5536-8CCC-90BEAE099BFB';
  p_IntegrationObjectID_786d5849 := '44127914-BA0D-49FB-92BE-DAEE7008A901';
  p_Name_786d5849 := 'id';
  p_Type_786d5849 := 'bigint';
  p_AllowsNull_786d5849 := FALSE;
  p_IsPrimaryKey_786d5849 := TRUE;
  p_IsUniqueKey_786d5849 := TRUE;
  p_IsReadOnly_786d5849 := FALSE;
  p_IsRequired_786d5849 := FALSE;
  p_Sequence_786d5849 := 0;
  p_Status_786d5849 := 'Active';
  p_IsCustom_786d5849 := FALSE;
  p_MetadataSource_786d5849 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_786d5849, p_IntegrationObjectID := p_IntegrationObjectID_786d5849, p_Name := p_Name_786d5849, p_DisplayName := p_DisplayName_786d5849, p_DisplayName_Clear := TRUE, p_Description := p_Description_786d5849, p_Description_Clear := TRUE, p_Category := p_Category_786d5849, p_Category_Clear := TRUE, p_Type := p_Type_786d5849, p_Length := p_Length_786d5849, p_Length_Clear := TRUE, p_Precision := p_Precision_786d5849, p_Precision_Clear := TRUE, p_Scale := p_Scale_786d5849, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_786d5849, p_DefaultValue := p_DefaultValue_786d5849, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_786d5849, p_IsUniqueKey := p_IsUniqueKey_786d5849, p_IsReadOnly := p_IsReadOnly_786d5849, p_IsRequired := p_IsRequired_786d5849, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_786d5849, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_786d5849, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_786d5849, p_Configuration := p_Configuration_786d5849, p_Configuration_Clear := TRUE, p_Status := p_Status_786d5849, p_IsCustom := p_IsCustom_786d5849, p_MetadataSource := p_MetadataSource_786d5849);
END $mj$;

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "SupportsCreate" = FALSE,
    "SupportsUpdate" = FALSE,
    "Description"    = 'Neon CRM CustomObjectFormLayout record (OpenAPI v2.11 schema CustomObjectFormLayout). Request-body shape, not a record: Status=Disabled, no APIPath, NoEnumerableEndpoint. The vendor''s layout record is CustomObjectFormLayoutResponse (keyed on id, addressed at /customObjects/{apiAlias}/formLayouts/{id}). Write withdrawn: a writable object with no primary key derives a keyless entity whose saves fail. Reads are unaffected.'
WHERE "ID" = 'EEB0E699-3CE4-4FE8-8B85-B773F0AC9BC1';

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "SupportsCreate" = FALSE,
    "SupportsUpdate" = FALSE,
    "Description"    = 'Neon CRM CustomObjectListLayout record (OpenAPI v2.11 schema CustomObjectListLayout). Request-body shape, not a record: Status=Disabled, no APIPath, NoEnumerableEndpoint. The vendor''s layout record is CustomObjectListLayoutResponse (keyed on id, addressed at /customObjects/{apiAlias}/listLayouts/{id}). Write withdrawn: a writable object with no primary key derives a keyless entity whose saves fail. Reads are unaffected.'
WHERE "ID" = '4D80C446-DAEF-43AD-9AAA-359B7289885C';

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "SupportsCreate" = FALSE,
    "SupportsUpdate" = FALSE,
    "Description"    = 'Neon CRM CustomObjectValidatorRule record (OpenAPI v2.11 schema CustomObjectValidatorRule). Request-body shape, not a record: Status=Disabled, no APIPath, NoEnumerableEndpoint. The vendor''s validator record is CustomObjectValidatorRuleResponse (already keyed on id, addressed at /customObjects/{idOrApiAlias}/validators/{id}). Write withdrawn: a writable object with no primary key derives a keyless entity whose saves fail. Reads are unaffected.'
WHERE "ID" = '6D8F2B41-8592-4B50-9DDD-79FD1A317408';

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "SupportsCreate" = FALSE,
    "Description"    = 'Neon CRM CustomObjectField record (OpenAPI v2.11 schema CustomObjectField). Request-body shape, not a record: Status=Disabled, no APIPath, NoEnumerableEndpoint, and no identifier — the vendor addresses a field by {fieldAlias}, which this shape does not declare. The readable field record is CustomObjectFieldResponse (keyed on id). Write withdrawn: a writable object with no primary key derives a keyless entity whose saves fail. Reads are unaffected.'
WHERE "ID" = '9415F0FA-B5F3-4941-AF64-A9D187AA9B59';


-- ===================== Other =====================

-- ── 3-6. the four request-body shapes: withdraw the write ────────────────────
