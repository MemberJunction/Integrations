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

-- WordPress Connector — ActivityLogEvent: promote the meta keys that matter to their own fields (additive delta)
--
-- Adds six IntegrationObjectField rows to the ActivityLogEvent object seeded by V202608300005:
-- ams_id, post_url, post_url_full, post_title, post_date and editor_link. Additive ONLY — it creates
-- 6 rows and touches nothing an earlier migration seeded, so a tenant on 1.2.x upgrades without a
-- catalog reset. The meta field itself is unchanged and still carries every key.
--
-- Each field's Configuration.promoteFrom names the meta key it is filled from; the connector reads that
-- declaration at fetch time, so the mapping lives here in metadata rather than in connector code.
--
-- Written in the exact statement shape `mj sync push` emits for these records (see V202608300005).

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_1341c9f3 UUID;
  p_IntegrationObjectID_1341c9f3 UUID;
  p_Name_1341c9f3 VARCHAR(255);
  p_DisplayName_1341c9f3 VARCHAR(255);
  p_Description_1341c9f3 TEXT;
  p_Category_1341c9f3 VARCHAR(100);
  p_Type_1341c9f3 VARCHAR(100);
  p_Length_1341c9f3 INTEGER;
  p_Precision_1341c9f3 INTEGER;
  p_Scale_1341c9f3 INTEGER;
  p_AllowsNull_1341c9f3 BOOLEAN;
  p_DefaultValue_1341c9f3 VARCHAR(255);
  p_IsPrimaryKey_1341c9f3 BOOLEAN;
  p_IsUniqueKey_1341c9f3 BOOLEAN;
  p_IsReadOnly_1341c9f3 BOOLEAN;
  p_IsRequired_1341c9f3 BOOLEAN;
  p_RelatedIntegrationObjectID_1341c9f3 UUID;
  p_RelatedIntegrationObjectFieldName_1341c9f3 VARCHAR(255);
  p_Sequence_1341c9f3 INTEGER;
  p_Configuration_1341c9f3 TEXT;
  p_Status_1341c9f3 VARCHAR(25);
  p_IsCustom_1341c9f3 BOOLEAN;
  p_MetadataSource_1341c9f3 VARCHAR(20);
BEGIN
  p_ID_1341c9f3 := '94E6EEE2-852E-42DA-8D06-FC15D75AB562';
  p_IntegrationObjectID_1341c9f3 := '1B6AAA3C-002C-4E1A-8C82-0900D33FE02A';
  p_Name_1341c9f3 := 'ams_id';
  p_DisplayName_1341c9f3 := 'AMS ID';
  p_Description_1341c9f3 := 'The member''s ID in the association''s AMS (for example a NetForum customer key), promoted from meta.ams_id. Present only when the site''s WP Activity Log integration records it; null otherwise.';
  p_Type_1341c9f3 := 'String';
  p_Length_1341c9f3 := 100;
  p_AllowsNull_1341c9f3 := TRUE;
  p_IsPrimaryKey_1341c9f3 := FALSE;
  p_IsUniqueKey_1341c9f3 := FALSE;
  p_IsReadOnly_1341c9f3 := TRUE;
  p_IsRequired_1341c9f3 := FALSE;
  p_Sequence_1341c9f3 := 20;
  p_Configuration_1341c9f3 := '{
  "contexts": [
    "view"
  ],
  "promoteFrom": "meta.ams_id"
}';
  p_Status_1341c9f3 := 'Active';
  p_IsCustom_1341c9f3 := FALSE;
  p_MetadataSource_1341c9f3 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_1341c9f3, p_IntegrationObjectID := p_IntegrationObjectID_1341c9f3, p_Name := p_Name_1341c9f3, p_DisplayName := p_DisplayName_1341c9f3, p_Description := p_Description_1341c9f3, p_Category := p_Category_1341c9f3, p_Category_Clear := TRUE, p_Type := p_Type_1341c9f3, p_Length := p_Length_1341c9f3, p_Precision := p_Precision_1341c9f3, p_Precision_Clear := TRUE, p_Scale := p_Scale_1341c9f3, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_1341c9f3, p_DefaultValue := p_DefaultValue_1341c9f3, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_1341c9f3, p_IsUniqueKey := p_IsUniqueKey_1341c9f3, p_IsReadOnly := p_IsReadOnly_1341c9f3, p_IsRequired := p_IsRequired_1341c9f3, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_1341c9f3, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_1341c9f3, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_1341c9f3, p_Configuration := p_Configuration_1341c9f3, p_Status := p_Status_1341c9f3, p_IsCustom := p_IsCustom_1341c9f3, p_MetadataSource := p_MetadataSource_1341c9f3);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_6a82f2af UUID;
  p_IntegrationObjectID_6a82f2af UUID;
  p_Name_6a82f2af VARCHAR(255);
  p_DisplayName_6a82f2af VARCHAR(255);
  p_Description_6a82f2af TEXT;
  p_Category_6a82f2af VARCHAR(100);
  p_Type_6a82f2af VARCHAR(100);
  p_Length_6a82f2af INTEGER;
  p_Precision_6a82f2af INTEGER;
  p_Scale_6a82f2af INTEGER;
  p_AllowsNull_6a82f2af BOOLEAN;
  p_DefaultValue_6a82f2af VARCHAR(255);
  p_IsPrimaryKey_6a82f2af BOOLEAN;
  p_IsUniqueKey_6a82f2af BOOLEAN;
  p_IsReadOnly_6a82f2af BOOLEAN;
  p_IsRequired_6a82f2af BOOLEAN;
  p_RelatedIntegrationObjectID_6a82f2af UUID;
  p_RelatedIntegrationObjectFieldName_6a82f2af VARCHAR(255);
  p_Sequence_6a82f2af INTEGER;
  p_Configuration_6a82f2af TEXT;
  p_Status_6a82f2af VARCHAR(25);
  p_IsCustom_6a82f2af BOOLEAN;
  p_MetadataSource_6a82f2af VARCHAR(20);
BEGIN
  p_ID_6a82f2af := 'CC8F8A7E-CACE-4C07-AE07-03E7E641FA98';
  p_IntegrationObjectID_6a82f2af := '1B6AAA3C-002C-4E1A-8C82-0900D33FE02A';
  p_Name_6a82f2af := 'post_url';
  p_DisplayName_6a82f2af := 'Post URL';
  p_Description_6a82f2af := 'Canonical URL of the post the event concerns: meta.PostUrl with HTML entities decoded and the query string and fragment removed, so it joins to a post''s link.';
  p_Type_6a82f2af := 'String';
  p_Length_6a82f2af := 2048;
  p_AllowsNull_6a82f2af := TRUE;
  p_IsPrimaryKey_6a82f2af := FALSE;
  p_IsUniqueKey_6a82f2af := FALSE;
  p_IsReadOnly_6a82f2af := TRUE;
  p_IsRequired_6a82f2af := FALSE;
  p_Sequence_6a82f2af := 21;
  p_Configuration_6a82f2af := '{
  "contexts": [
    "view"
  ],
  "promoteFrom": "meta.PostUrl",
  "stripQuery": true
}';
  p_Status_6a82f2af := 'Active';
  p_IsCustom_6a82f2af := FALSE;
  p_MetadataSource_6a82f2af := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_6a82f2af, p_IntegrationObjectID := p_IntegrationObjectID_6a82f2af, p_Name := p_Name_6a82f2af, p_DisplayName := p_DisplayName_6a82f2af, p_Description := p_Description_6a82f2af, p_Category := p_Category_6a82f2af, p_Category_Clear := TRUE, p_Type := p_Type_6a82f2af, p_Length := p_Length_6a82f2af, p_Precision := p_Precision_6a82f2af, p_Precision_Clear := TRUE, p_Scale := p_Scale_6a82f2af, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_6a82f2af, p_DefaultValue := p_DefaultValue_6a82f2af, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_6a82f2af, p_IsUniqueKey := p_IsUniqueKey_6a82f2af, p_IsReadOnly := p_IsReadOnly_6a82f2af, p_IsRequired := p_IsRequired_6a82f2af, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_6a82f2af, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_6a82f2af, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_6a82f2af, p_Configuration := p_Configuration_6a82f2af, p_Status := p_Status_6a82f2af, p_IsCustom := p_IsCustom_6a82f2af, p_MetadataSource := p_MetadataSource_6a82f2af);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_b2df9e72 UUID;
  p_IntegrationObjectID_b2df9e72 UUID;
  p_Name_b2df9e72 VARCHAR(255);
  p_DisplayName_b2df9e72 VARCHAR(255);
  p_Description_b2df9e72 TEXT;
  p_Category_b2df9e72 VARCHAR(100);
  p_Type_b2df9e72 VARCHAR(100);
  p_Length_b2df9e72 INTEGER;
  p_Precision_b2df9e72 INTEGER;
  p_Scale_b2df9e72 INTEGER;
  p_AllowsNull_b2df9e72 BOOLEAN;
  p_DefaultValue_b2df9e72 VARCHAR(255);
  p_IsPrimaryKey_b2df9e72 BOOLEAN;
  p_IsUniqueKey_b2df9e72 BOOLEAN;
  p_IsReadOnly_b2df9e72 BOOLEAN;
  p_IsRequired_b2df9e72 BOOLEAN;
  p_RelatedIntegrationObjectID_b2df9e72 UUID;
  p_RelatedIntegrationObjectFieldName_b2df9e72 VARCHAR(255);
  p_Sequence_b2df9e72 INTEGER;
  p_Configuration_b2df9e72 TEXT;
  p_Status_b2df9e72 VARCHAR(25);
  p_IsCustom_b2df9e72 BOOLEAN;
  p_MetadataSource_b2df9e72 VARCHAR(20);
BEGIN
  p_ID_b2df9e72 := 'B5BD2102-487D-45FD-AC6F-65E891EB76BE';
  p_IntegrationObjectID_b2df9e72 := '1B6AAA3C-002C-4E1A-8C82-0900D33FE02A';
  p_Name_b2df9e72 := 'post_url_full';
  p_DisplayName_b2df9e72 := 'Post URL (Full)';
  p_Description_b2df9e72 := 'meta.PostUrl exactly as visited, HTML entities decoded, with its query string kept (it carries campaign attribution such as utm_source).';
  p_Type_b2df9e72 := 'String';
  p_Length_b2df9e72 := 2048;
  p_AllowsNull_b2df9e72 := TRUE;
  p_IsPrimaryKey_b2df9e72 := FALSE;
  p_IsUniqueKey_b2df9e72 := FALSE;
  p_IsReadOnly_b2df9e72 := TRUE;
  p_IsRequired_b2df9e72 := FALSE;
  p_Sequence_b2df9e72 := 22;
  p_Configuration_b2df9e72 := '{
  "contexts": [
    "view"
  ],
  "promoteFrom": "meta.PostUrl"
}';
  p_Status_b2df9e72 := 'Active';
  p_IsCustom_b2df9e72 := FALSE;
  p_MetadataSource_b2df9e72 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_b2df9e72, p_IntegrationObjectID := p_IntegrationObjectID_b2df9e72, p_Name := p_Name_b2df9e72, p_DisplayName := p_DisplayName_b2df9e72, p_Description := p_Description_b2df9e72, p_Category := p_Category_b2df9e72, p_Category_Clear := TRUE, p_Type := p_Type_b2df9e72, p_Length := p_Length_b2df9e72, p_Precision := p_Precision_b2df9e72, p_Precision_Clear := TRUE, p_Scale := p_Scale_b2df9e72, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_b2df9e72, p_DefaultValue := p_DefaultValue_b2df9e72, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_b2df9e72, p_IsUniqueKey := p_IsUniqueKey_b2df9e72, p_IsReadOnly := p_IsReadOnly_b2df9e72, p_IsRequired := p_IsRequired_b2df9e72, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_b2df9e72, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_b2df9e72, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_b2df9e72, p_Configuration := p_Configuration_b2df9e72, p_Status := p_Status_b2df9e72, p_IsCustom := p_IsCustom_b2df9e72, p_MetadataSource := p_MetadataSource_b2df9e72);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_e06b2c3a UUID;
  p_IntegrationObjectID_e06b2c3a UUID;
  p_Name_e06b2c3a VARCHAR(255);
  p_DisplayName_e06b2c3a VARCHAR(255);
  p_Description_e06b2c3a TEXT;
  p_Category_e06b2c3a VARCHAR(100);
  p_Type_e06b2c3a VARCHAR(100);
  p_Length_e06b2c3a INTEGER;
  p_Precision_e06b2c3a INTEGER;
  p_Scale_e06b2c3a INTEGER;
  p_AllowsNull_e06b2c3a BOOLEAN;
  p_DefaultValue_e06b2c3a VARCHAR(255);
  p_IsPrimaryKey_e06b2c3a BOOLEAN;
  p_IsUniqueKey_e06b2c3a BOOLEAN;
  p_IsReadOnly_e06b2c3a BOOLEAN;
  p_IsRequired_e06b2c3a BOOLEAN;
  p_RelatedIntegrationObjectID_e06b2c3a UUID;
  p_RelatedIntegrationObjectFieldName_e06b2c3a VARCHAR(255);
  p_Sequence_e06b2c3a INTEGER;
  p_Configuration_e06b2c3a TEXT;
  p_Status_e06b2c3a VARCHAR(25);
  p_IsCustom_e06b2c3a BOOLEAN;
  p_MetadataSource_e06b2c3a VARCHAR(20);
BEGIN
  p_ID_e06b2c3a := '8D0FDDCB-7BC3-4AA4-B0C6-A9AA74ABFB8A';
  p_IntegrationObjectID_e06b2c3a := '1B6AAA3C-002C-4E1A-8C82-0900D33FE02A';
  p_Name_e06b2c3a := 'post_title';
  p_DisplayName_e06b2c3a := 'Post Title';
  p_Description_e06b2c3a := 'Title of the post at the time of the event, promoted from meta.PostTitle with HTML entities decoded.';
  p_Type_e06b2c3a := 'String';
  p_Length_e06b2c3a := 1000;
  p_AllowsNull_e06b2c3a := TRUE;
  p_IsPrimaryKey_e06b2c3a := FALSE;
  p_IsUniqueKey_e06b2c3a := FALSE;
  p_IsReadOnly_e06b2c3a := TRUE;
  p_IsRequired_e06b2c3a := FALSE;
  p_Sequence_e06b2c3a := 23;
  p_Configuration_e06b2c3a := '{
  "contexts": [
    "view"
  ],
  "promoteFrom": "meta.PostTitle"
}';
  p_Status_e06b2c3a := 'Active';
  p_IsCustom_e06b2c3a := FALSE;
  p_MetadataSource_e06b2c3a := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_e06b2c3a, p_IntegrationObjectID := p_IntegrationObjectID_e06b2c3a, p_Name := p_Name_e06b2c3a, p_DisplayName := p_DisplayName_e06b2c3a, p_Description := p_Description_e06b2c3a, p_Category := p_Category_e06b2c3a, p_Category_Clear := TRUE, p_Type := p_Type_e06b2c3a, p_Length := p_Length_e06b2c3a, p_Precision := p_Precision_e06b2c3a, p_Precision_Clear := TRUE, p_Scale := p_Scale_e06b2c3a, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_e06b2c3a, p_DefaultValue := p_DefaultValue_e06b2c3a, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_e06b2c3a, p_IsUniqueKey := p_IsUniqueKey_e06b2c3a, p_IsReadOnly := p_IsReadOnly_e06b2c3a, p_IsRequired := p_IsRequired_e06b2c3a, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_e06b2c3a, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_e06b2c3a, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_e06b2c3a, p_Configuration := p_Configuration_e06b2c3a, p_Status := p_Status_e06b2c3a, p_IsCustom := p_IsCustom_e06b2c3a, p_MetadataSource := p_MetadataSource_e06b2c3a);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_31c7b7b2 UUID;
  p_IntegrationObjectID_31c7b7b2 UUID;
  p_Name_31c7b7b2 VARCHAR(255);
  p_DisplayName_31c7b7b2 VARCHAR(255);
  p_Description_31c7b7b2 TEXT;
  p_Category_31c7b7b2 VARCHAR(100);
  p_Type_31c7b7b2 VARCHAR(100);
  p_Length_31c7b7b2 INTEGER;
  p_Precision_31c7b7b2 INTEGER;
  p_Scale_31c7b7b2 INTEGER;
  p_AllowsNull_31c7b7b2 BOOLEAN;
  p_DefaultValue_31c7b7b2 VARCHAR(255);
  p_IsPrimaryKey_31c7b7b2 BOOLEAN;
  p_IsUniqueKey_31c7b7b2 BOOLEAN;
  p_IsReadOnly_31c7b7b2 BOOLEAN;
  p_IsRequired_31c7b7b2 BOOLEAN;
  p_RelatedIntegrationObjectID_31c7b7b2 UUID;
  p_RelatedIntegrationObjectFieldName_31c7b7b2 VARCHAR(255);
  p_Sequence_31c7b7b2 INTEGER;
  p_Configuration_31c7b7b2 TEXT;
  p_Status_31c7b7b2 VARCHAR(25);
  p_IsCustom_31c7b7b2 BOOLEAN;
  p_MetadataSource_31c7b7b2 VARCHAR(20);
BEGIN
  p_ID_31c7b7b2 := '6701EB96-C0A9-42FA-AF7F-A4E1C2EC500C';
  p_IntegrationObjectID_31c7b7b2 := '1B6AAA3C-002C-4E1A-8C82-0900D33FE02A';
  p_Name_31c7b7b2 := 'post_date';
  p_DisplayName_31c7b7b2 := 'Post Date';
  p_Description_31c7b7b2 := 'Publication date of the post, promoted from meta.PostDate as WP Activity Log records it (site-local time, ''YYYY-MM-DD HH:MM:SS'').';
  p_Type_31c7b7b2 := 'String';
  p_Length_31c7b7b2 := 30;
  p_AllowsNull_31c7b7b2 := TRUE;
  p_IsPrimaryKey_31c7b7b2 := FALSE;
  p_IsUniqueKey_31c7b7b2 := FALSE;
  p_IsReadOnly_31c7b7b2 := TRUE;
  p_IsRequired_31c7b7b2 := FALSE;
  p_Sequence_31c7b7b2 := 24;
  p_Configuration_31c7b7b2 := '{
  "contexts": [
    "view"
  ],
  "promoteFrom": "meta.PostDate"
}';
  p_Status_31c7b7b2 := 'Active';
  p_IsCustom_31c7b7b2 := FALSE;
  p_MetadataSource_31c7b7b2 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_31c7b7b2, p_IntegrationObjectID := p_IntegrationObjectID_31c7b7b2, p_Name := p_Name_31c7b7b2, p_DisplayName := p_DisplayName_31c7b7b2, p_Description := p_Description_31c7b7b2, p_Category := p_Category_31c7b7b2, p_Category_Clear := TRUE, p_Type := p_Type_31c7b7b2, p_Length := p_Length_31c7b7b2, p_Precision := p_Precision_31c7b7b2, p_Precision_Clear := TRUE, p_Scale := p_Scale_31c7b7b2, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_31c7b7b2, p_DefaultValue := p_DefaultValue_31c7b7b2, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_31c7b7b2, p_IsUniqueKey := p_IsUniqueKey_31c7b7b2, p_IsReadOnly := p_IsReadOnly_31c7b7b2, p_IsRequired := p_IsRequired_31c7b7b2, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_31c7b7b2, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_31c7b7b2, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_31c7b7b2, p_Configuration := p_Configuration_31c7b7b2, p_Status := p_Status_31c7b7b2, p_IsCustom := p_IsCustom_31c7b7b2, p_MetadataSource := p_MetadataSource_31c7b7b2);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_e011db4e UUID;
  p_IntegrationObjectID_e011db4e UUID;
  p_Name_e011db4e VARCHAR(255);
  p_DisplayName_e011db4e VARCHAR(255);
  p_Description_e011db4e TEXT;
  p_Category_e011db4e VARCHAR(100);
  p_Type_e011db4e VARCHAR(100);
  p_Length_e011db4e INTEGER;
  p_Precision_e011db4e INTEGER;
  p_Scale_e011db4e INTEGER;
  p_AllowsNull_e011db4e BOOLEAN;
  p_DefaultValue_e011db4e VARCHAR(255);
  p_IsPrimaryKey_e011db4e BOOLEAN;
  p_IsUniqueKey_e011db4e BOOLEAN;
  p_IsReadOnly_e011db4e BOOLEAN;
  p_IsRequired_e011db4e BOOLEAN;
  p_RelatedIntegrationObjectID_e011db4e UUID;
  p_RelatedIntegrationObjectFieldName_e011db4e VARCHAR(255);
  p_Sequence_e011db4e INTEGER;
  p_Configuration_e011db4e TEXT;
  p_Status_e011db4e VARCHAR(25);
  p_IsCustom_e011db4e BOOLEAN;
  p_MetadataSource_e011db4e VARCHAR(20);
BEGIN
  p_ID_e011db4e := '5813E24E-EF72-4195-B8D6-D19D24307721';
  p_IntegrationObjectID_e011db4e := '1B6AAA3C-002C-4E1A-8C82-0900D33FE02A';
  p_Name_e011db4e := 'editor_link';
  p_DisplayName_e011db4e := 'Editor Link';
  p_Description_e011db4e := 'wp-admin edit link for the post, promoted from meta.EditorLinkPost with HTML entities decoded.';
  p_Type_e011db4e := 'String';
  p_Length_e011db4e := 2048;
  p_AllowsNull_e011db4e := TRUE;
  p_IsPrimaryKey_e011db4e := FALSE;
  p_IsUniqueKey_e011db4e := FALSE;
  p_IsReadOnly_e011db4e := TRUE;
  p_IsRequired_e011db4e := FALSE;
  p_Sequence_e011db4e := 25;
  p_Configuration_e011db4e := '{
  "contexts": [
    "view"
  ],
  "promoteFrom": "meta.EditorLinkPost"
}';
  p_Status_e011db4e := 'Active';
  p_IsCustom_e011db4e := FALSE;
  p_MetadataSource_e011db4e := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_e011db4e, p_IntegrationObjectID := p_IntegrationObjectID_e011db4e, p_Name := p_Name_e011db4e, p_DisplayName := p_DisplayName_e011db4e, p_Description := p_Description_e011db4e, p_Category := p_Category_e011db4e, p_Category_Clear := TRUE, p_Type := p_Type_e011db4e, p_Length := p_Length_e011db4e, p_Precision := p_Precision_e011db4e, p_Precision_Clear := TRUE, p_Scale := p_Scale_e011db4e, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_e011db4e, p_DefaultValue := p_DefaultValue_e011db4e, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_e011db4e, p_IsUniqueKey := p_IsUniqueKey_e011db4e, p_IsReadOnly := p_IsReadOnly_e011db4e, p_IsRequired := p_IsRequired_e011db4e, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_e011db4e, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_e011db4e, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_e011db4e, p_Configuration := p_Configuration_e011db4e, p_Status := p_Status_e011db4e, p_IsCustom := p_IsCustom_e011db4e, p_MetadataSource := p_MetadataSource_e011db4e);
END $mj$;
