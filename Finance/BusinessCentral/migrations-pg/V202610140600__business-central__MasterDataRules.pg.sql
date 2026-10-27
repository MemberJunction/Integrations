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

UPDATE "__mj"."IntegrationObject"
SET "Configuration" = REPLACE("Configuration", '"resourceType": "account",', '"recordFilter": {"field": "accountType", "in": ["Posting"]}, "resourceType": "account",')
WHERE "ID" = '341328C6-098D-400D-B6E4-A7FDE73676D6';

UPDATE "__mj"."IntegrationObject"
SET "Configuration" = REPLACE("Configuration", '"resourceType": "dimensionValue",', '"parentCode": {"object": "dimensions", "idField": "dimensionId", "codeField": "code", "as": "dimensionCode"}, "resourceType": "dimensionValue",')
WHERE "ID" = 'DE0BF041-9003-4BDC-854B-941AC9F427CA';

DO $mj$
DECLARE
  p_ID_mdr1 UUID;
  p_IntegrationObjectID_mdr1 UUID;
  p_Name_mdr1 VARCHAR(255);
  p_DisplayName_mdr1 VARCHAR(255);
  p_Description_mdr1 TEXT;
  p_Category_mdr1 VARCHAR(100);
  p_Type_mdr1 VARCHAR(100);
  p_Length_mdr1 INTEGER;
  p_Precision_mdr1 INTEGER;
  p_Scale_mdr1 INTEGER;
  p_AllowsNull_mdr1 BOOLEAN;
  p_DefaultValue_mdr1 VARCHAR(255);
  p_IsPrimaryKey_mdr1 BOOLEAN;
  p_IsUniqueKey_mdr1 BOOLEAN;
  p_IsReadOnly_mdr1 BOOLEAN;
  p_IsRequired_mdr1 BOOLEAN;
  p_RelatedIntegrationObjectID_mdr1 UUID;
  p_RelatedIntegrationObjectFieldName_mdr1 VARCHAR(255);
  p_Sequence_mdr1 INTEGER;
  p_Configuration_mdr1 TEXT;
  p_Status_mdr1 VARCHAR(25);
  p_IsCustom_mdr1 BOOLEAN;
  p_MetadataSource_mdr1 VARCHAR(20);
BEGIN
  p_ID_mdr1 := '14AF8F23-4512-483C-A23B-E562236028C4';
  p_IntegrationObjectID_mdr1 := 'DE0BF041-9003-4BDC-854B-941AC9F427CA';
  p_Name_mdr1 := 'dimensionCode';
  p_DisplayName_mdr1 := 'Dimension Code';
  p_Description_mdr1 := 'The parent dimension''s code, added by the connector from dimensionId (Configuration.parentCode). Business Central dimension IDs are per company; the code is what a shared Dimension matches on.';
  p_Type_mdr1 := 'string';
  p_Length_mdr1 := 20;
  p_AllowsNull_mdr1 := TRUE;
  p_IsPrimaryKey_mdr1 := FALSE;
  p_IsUniqueKey_mdr1 := FALSE;
  p_IsReadOnly_mdr1 := TRUE;
  p_IsRequired_mdr1 := FALSE;
  p_Sequence_mdr1 := 7;
  p_Configuration_mdr1 := '{"edmType":"string","derived":"connector parentCode (dimensions.code via dimensionId)"}';
  p_Status_mdr1 := 'Active';
  p_IsCustom_mdr1 := FALSE;
  p_MetadataSource_mdr1 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_mdr1, p_IntegrationObjectID := p_IntegrationObjectID_mdr1, p_Name := p_Name_mdr1, p_DisplayName := p_DisplayName_mdr1, p_Description := p_Description_mdr1, p_Category := p_Category_mdr1, p_Category_Clear := TRUE, p_Type := p_Type_mdr1, p_Length := p_Length_mdr1, p_Length_Clear := TRUE, p_Precision := p_Precision_mdr1, p_Precision_Clear := TRUE, p_Scale := p_Scale_mdr1, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_mdr1, p_DefaultValue := p_DefaultValue_mdr1, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_mdr1, p_IsUniqueKey := p_IsUniqueKey_mdr1, p_IsReadOnly := p_IsReadOnly_mdr1, p_IsRequired := p_IsRequired_mdr1, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_mdr1, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_mdr1, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_mdr1, p_Configuration := p_Configuration_mdr1, p_Status := p_Status_mdr1, p_IsCustom := p_IsCustom_mdr1, p_MetadataSource := p_MetadataSource_mdr1);
END $mj$;


-- ===================== Other =====================

-- Business Central: record rules for ERP master-data sync (accounts, dimension values).
--
-- WHAT THIS ENABLES
--   bizapps-accounting's ERP master-data contract (docs/ARCHITECTURE.md 2.1, bizapps-accounting#268) needs two
--   things the integration engine cannot do yet (MemberJunction/MJ#5254), and which the contract assigns to the
--   connector until it can:
--   1. accounts: only real G/L accounts reach the GL Accounts entity. Heading, Total, Begin-Total and End-Total
--      rows are presentation structure; the connector now drops them when the object's Configuration carries
--      recordFilter = { field: accountType, in: [Posting] }. Skipped rows still advance the watermark.
--   2. dimensionValues: Business Central gives a value only its parent's per-company GUID (dimensionId). AIDP's
--      Dimension is shared across companies and keyed on Code, so the connector now adds dimensionCode,
--      read once per company from /dimensions, when Configuration carries parentCode.
--   Both rules live in each object's Configuration (connector code reads them generically), so this migration
--   only sets them, plus the new dimensionCode field.
--
-- SHAPE
--   A delta on the shipped catalog (V202608041723). The two rules are inserted into each row's Configuration
--   with REPLACE on its unique "resourceType" key (as V202609132100__openwater does; REPLACE converts to
--   Postgres as is, JSON_MODIFY does not). The new field uses spCreateIntegrationObjectField, in the same form
--   as V202608251200. Matching metadata/ change in the same PR.
