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

-- ORCID Connector — one /record call per person, sections derived and flattened (additive delta)
--
-- Companion to the connector change of the same name. Three things, all additive on top of the
-- catalog seeded by V202606271401 (nothing an earlier migration created is removed or renamed):
--
--   1. record gains `activities-summary` (json): the activity-section summaries the API already
--      returns inside /record. The connector stores it so every section object is DERIVED from the
--      stored record instead of issuing its own GET /{iD}/<section> per person.
--   2. Every existing section object gains flattened fields for the shapes ORCID nests: the asserting
--      source (`source-name`/`source-orcid`), organization (`organization-name`, `-city`, `-region`,
--      `-country`, `-disambiguated-id`, `-disambiguation-source`), partial dates (`start-year`/`-month`/
--      `-day`, `end-*`, `publication-*`, `completion-*`), titles (`work-title`, `funding-title`, ...),
--      funding amount and peer-review subject. The nested json fields are unchanged, so nothing is lost.
--   3. Six person-section objects: other-names, keywords, email, address, researcher-urls,
--      external-identifiers. Each is keyed by put-code with an orcid-id FK to record, exactly like the
--      activity sections, and is derived from the stored record's `person` block.
--
-- The objects' Configuration notes are updated to describe the derived fetch model (documentation
-- only; the connector does not read them).
--
-- Written in the exact statement shape `mj sync push` emits for these records (see V202606271401),
-- generated from the metadata JSON so the two cannot drift.


UPDATE "__mj"."IntegrationObject" SET "Configuration" = '{"endpoint": "/{iD}/record", "fetchModel": "per-iD full record (GET /{iD}/record), fetched concurrently per page; the only object that calls ORCID", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}' WHERE "ID" = '73AED6B8-468D-403B-B994-F3C786C98BC0';

UPDATE "__mj"."IntegrationObject" SET "Configuration" = '{"endpoint": "/{iD}/works", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}' WHERE "ID" = '1D853840-A875-41E9-AB35-940345EF1434';

UPDATE "__mj"."IntegrationObject" SET "Configuration" = '{"endpoint": "/{iD}/employments", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}' WHERE "ID" = '5F90FE9B-3498-4DC2-A188-6173B8EA842B';

UPDATE "__mj"."IntegrationObject" SET "Configuration" = '{"endpoint": "/{iD}/educations", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}' WHERE "ID" = '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF';

UPDATE "__mj"."IntegrationObject" SET "Configuration" = '{"endpoint": "/{iD}/qualifications", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}' WHERE "ID" = 'A28BB703-8E34-4725-AF07-CDE7E42EB046';

UPDATE "__mj"."IntegrationObject" SET "Configuration" = '{"endpoint": "/{iD}/distinctions", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}' WHERE "ID" = '2139B63E-5944-4542-BE5E-7213D64B9750';

UPDATE "__mj"."IntegrationObject" SET "Configuration" = '{"endpoint": "/{iD}/invited-positions", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}' WHERE "ID" = '5DD9CF05-1571-454E-BA40-D65E6B9C2131';

UPDATE "__mj"."IntegrationObject" SET "Configuration" = '{"endpoint": "/{iD}/memberships", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}' WHERE "ID" = 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05';

UPDATE "__mj"."IntegrationObject" SET "Configuration" = '{"endpoint": "/{iD}/services", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}' WHERE "ID" = '35593E67-CBB4-4C88-9438-80C1D7F4B2D0';

UPDATE "__mj"."IntegrationObject" SET "Configuration" = '{"endpoint": "/{iD}/fundings", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}' WHERE "ID" = 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD';

UPDATE "__mj"."IntegrationObject" SET "Configuration" = '{"endpoint": "/{iD}/peer-reviews", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}' WHERE "ID" = 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F';

UPDATE "__mj"."IntegrationObject" SET "Configuration" = '{"endpoint": "/{iD}/research-resources", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}' WHERE "ID" = 'E52B947C-796A-46F1-BD69-BD9CD92FA046';

-- Save MJ: Integration Objects (core SP call only)
DO $mj$
DECLARE
  p_ID_14091de3 UUID;
  p_IntegrationID_14091de3 UUID;
  p_Name_14091de3 VARCHAR(255);
  p_DisplayName_14091de3 VARCHAR(255);
  p_Description_14091de3 TEXT;
  p_Category_14091de3 VARCHAR(100);
  p_APIPath_14091de3 VARCHAR(500);
  p_ResponseDataKey_14091de3 VARCHAR(255);
  p_DefaultPageSize_14091de3 INTEGER;
  p_SupportsPagination_14091de3 BOOLEAN;
  p_PaginationType_14091de3 VARCHAR(20);
  p_SupportsIncrementalSync_14091de3 BOOLEAN;
  p_SupportsWrite_14091de3 BOOLEAN;
  p_DefaultQueryParams_14091de3 TEXT;
  p_Configuration_14091de3 TEXT;
  p_Sequence_14091de3 INTEGER;
  p_Status_14091de3 VARCHAR(25);
  p_WriteAPIPath_14091de3 VARCHAR(500);
  p_WriteMethod_14091de3 VARCHAR(10);
  p_DeleteMethod_14091de3 VARCHAR(10);
  p_IsCustom_14091de3 BOOLEAN;
  p_CreateAPIPath_14091de3 TEXT;
  p_CreateMethod_14091de3 VARCHAR(20);
  p_CreateBodyShape_14091de3 VARCHAR(50);
  p_CreateBodyKey_14091de3 VARCHAR(100);
  p_CreateIDLocation_14091de3 VARCHAR(20);
  p_UpdateAPIPath_14091de3 TEXT;
  p_UpdateMethod_14091de3 VARCHAR(20);
  p_UpdateBodyShape_14091de3 VARCHAR(50);
  p_UpdateBodyKey_14091de3 VARCHAR(100);
  p_UpdateIDLocation_14091de3 VARCHAR(20);
  p_DeleteAPIPath_14091de3 TEXT;
  p_DeleteIDLocation_14091de3 VARCHAR(20);
  p_IncrementalWatermarkField_14091de3 VARCHAR(255);
  p_MetadataSource_14091de3 VARCHAR(20);
  p_SupportsCreate_14091de3 BOOLEAN;
  p_SupportsUpdate_14091de3 BOOLEAN;
  p_SupportsDelete_14091de3 BOOLEAN;
  p_SyncStrategy_14091de3 VARCHAR(50);
  p_ContentHashApplicable_14091de3 BOOLEAN;
  p_StableOrderingKey_14091de3 VARCHAR(255);
BEGIN
  p_ID_14091de3 := 'D4B4DBBD-FF1E-5147-8602-A41DC2855CE5';
  p_IntegrationID_14091de3 := 'D2E0507F-6F7F-4C10-8493-21DAF94AE18E';
  p_Name_14091de3 := 'other-names';
  p_DisplayName_14091de3 := 'Other Names';
  p_Description_14091de3 := 'Alternate names the researcher is also known by (person section). Derived from the stored record; one row per other-name.';
  p_APIPath_14091de3 := '/{iD}/other-names';
  p_DefaultPageSize_14091de3 := 100;
  p_SupportsPagination_14091de3 := FALSE;
  p_PaginationType_14091de3 := 'None';
  p_SupportsIncrementalSync_14091de3 := TRUE;
  p_SupportsWrite_14091de3 := FALSE;
  p_Configuration_14091de3 := '{"endpoint": "/{iD}/other-names", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}';
  p_Sequence_14091de3 := 12;
  p_Status_14091de3 := 'Active';
  p_WriteMethod_14091de3 := 'POST';
  p_DeleteMethod_14091de3 := 'DELETE';
  p_IsCustom_14091de3 := FALSE;
  p_IncrementalWatermarkField_14091de3 := 'last-modified-date';
  p_MetadataSource_14091de3 := 'Declared';
  p_SupportsCreate_14091de3 := FALSE;
  p_SupportsUpdate_14091de3 := FALSE;
  p_SupportsDelete_14091de3 := FALSE;
  p_ContentHashApplicable_14091de3 := TRUE;
  PERFORM __mj."spCreateIntegrationObject"(p_ID := p_ID_14091de3, p_IntegrationID := p_IntegrationID_14091de3, p_Name := p_Name_14091de3, p_DisplayName := p_DisplayName_14091de3, p_Description := p_Description_14091de3, p_Category := p_Category_14091de3, p_Category_Clear := TRUE, p_APIPath := p_APIPath_14091de3, p_ResponseDataKey := p_ResponseDataKey_14091de3, p_ResponseDataKey_Clear := TRUE, p_DefaultPageSize := p_DefaultPageSize_14091de3, p_SupportsPagination := p_SupportsPagination_14091de3, p_PaginationType := p_PaginationType_14091de3, p_SupportsIncrementalSync := p_SupportsIncrementalSync_14091de3, p_SupportsWrite := p_SupportsWrite_14091de3, p_DefaultQueryParams := p_DefaultQueryParams_14091de3, p_DefaultQueryParams_Clear := TRUE, p_Configuration := p_Configuration_14091de3, p_Sequence := p_Sequence_14091de3, p_Status := p_Status_14091de3, p_WriteAPIPath := p_WriteAPIPath_14091de3, p_WriteAPIPath_Clear := TRUE, p_WriteMethod := p_WriteMethod_14091de3, p_DeleteMethod := p_DeleteMethod_14091de3, p_IsCustom := p_IsCustom_14091de3, p_CreateAPIPath := p_CreateAPIPath_14091de3, p_CreateAPIPath_Clear := TRUE, p_CreateMethod := p_CreateMethod_14091de3, p_CreateMethod_Clear := TRUE, p_CreateBodyShape := p_CreateBodyShape_14091de3, p_CreateBodyShape_Clear := TRUE, p_CreateBodyKey := p_CreateBodyKey_14091de3, p_CreateBodyKey_Clear := TRUE, p_CreateIDLocation := p_CreateIDLocation_14091de3, p_CreateIDLocation_Clear := TRUE, p_UpdateAPIPath := p_UpdateAPIPath_14091de3, p_UpdateAPIPath_Clear := TRUE, p_UpdateMethod := p_UpdateMethod_14091de3, p_UpdateMethod_Clear := TRUE, p_UpdateBodyShape := p_UpdateBodyShape_14091de3, p_UpdateBodyShape_Clear := TRUE, p_UpdateBodyKey := p_UpdateBodyKey_14091de3, p_UpdateBodyKey_Clear := TRUE, p_UpdateIDLocation := p_UpdateIDLocation_14091de3, p_UpdateIDLocation_Clear := TRUE, p_DeleteAPIPath := p_DeleteAPIPath_14091de3, p_DeleteAPIPath_Clear := TRUE, p_DeleteIDLocation := p_DeleteIDLocation_14091de3, p_DeleteIDLocation_Clear := TRUE, p_IncrementalWatermarkField := p_IncrementalWatermarkField_14091de3, p_MetadataSource := p_MetadataSource_14091de3, p_SupportsCreate := p_SupportsCreate_14091de3, p_SupportsUpdate := p_SupportsUpdate_14091de3, p_SupportsDelete := p_SupportsDelete_14091de3, p_SyncStrategy := p_SyncStrategy_14091de3, p_SyncStrategy_Clear := TRUE, p_ContentHashApplicable := p_ContentHashApplicable_14091de3, p_StableOrderingKey := p_StableOrderingKey_14091de3, p_StableOrderingKey_Clear := TRUE);
END $mj$;

-- Save MJ: Integration Objects (core SP call only)
DO $mj$
DECLARE
  p_ID_d9b2774b UUID;
  p_IntegrationID_d9b2774b UUID;
  p_Name_d9b2774b VARCHAR(255);
  p_DisplayName_d9b2774b VARCHAR(255);
  p_Description_d9b2774b TEXT;
  p_Category_d9b2774b VARCHAR(100);
  p_APIPath_d9b2774b VARCHAR(500);
  p_ResponseDataKey_d9b2774b VARCHAR(255);
  p_DefaultPageSize_d9b2774b INTEGER;
  p_SupportsPagination_d9b2774b BOOLEAN;
  p_PaginationType_d9b2774b VARCHAR(20);
  p_SupportsIncrementalSync_d9b2774b BOOLEAN;
  p_SupportsWrite_d9b2774b BOOLEAN;
  p_DefaultQueryParams_d9b2774b TEXT;
  p_Configuration_d9b2774b TEXT;
  p_Sequence_d9b2774b INTEGER;
  p_Status_d9b2774b VARCHAR(25);
  p_WriteAPIPath_d9b2774b VARCHAR(500);
  p_WriteMethod_d9b2774b VARCHAR(10);
  p_DeleteMethod_d9b2774b VARCHAR(10);
  p_IsCustom_d9b2774b BOOLEAN;
  p_CreateAPIPath_d9b2774b TEXT;
  p_CreateMethod_d9b2774b VARCHAR(20);
  p_CreateBodyShape_d9b2774b VARCHAR(50);
  p_CreateBodyKey_d9b2774b VARCHAR(100);
  p_CreateIDLocation_d9b2774b VARCHAR(20);
  p_UpdateAPIPath_d9b2774b TEXT;
  p_UpdateMethod_d9b2774b VARCHAR(20);
  p_UpdateBodyShape_d9b2774b VARCHAR(50);
  p_UpdateBodyKey_d9b2774b VARCHAR(100);
  p_UpdateIDLocation_d9b2774b VARCHAR(20);
  p_DeleteAPIPath_d9b2774b TEXT;
  p_DeleteIDLocation_d9b2774b VARCHAR(20);
  p_IncrementalWatermarkField_d9b2774b VARCHAR(255);
  p_MetadataSource_d9b2774b VARCHAR(20);
  p_SupportsCreate_d9b2774b BOOLEAN;
  p_SupportsUpdate_d9b2774b BOOLEAN;
  p_SupportsDelete_d9b2774b BOOLEAN;
  p_SyncStrategy_d9b2774b VARCHAR(50);
  p_ContentHashApplicable_d9b2774b BOOLEAN;
  p_StableOrderingKey_d9b2774b VARCHAR(255);
BEGIN
  p_ID_d9b2774b := 'C72BE662-43B8-5398-BE8F-FD2145295A4D';
  p_IntegrationID_d9b2774b := 'D2E0507F-6F7F-4C10-8493-21DAF94AE18E';
  p_Name_d9b2774b := 'keywords';
  p_DisplayName_d9b2774b := 'Keywords';
  p_Description_d9b2774b := 'Self-declared research keywords (person section). Derived from the stored record; one row per keyword.';
  p_APIPath_d9b2774b := '/{iD}/keywords';
  p_DefaultPageSize_d9b2774b := 100;
  p_SupportsPagination_d9b2774b := FALSE;
  p_PaginationType_d9b2774b := 'None';
  p_SupportsIncrementalSync_d9b2774b := TRUE;
  p_SupportsWrite_d9b2774b := FALSE;
  p_Configuration_d9b2774b := '{"endpoint": "/{iD}/keywords", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}';
  p_Sequence_d9b2774b := 13;
  p_Status_d9b2774b := 'Active';
  p_WriteMethod_d9b2774b := 'POST';
  p_DeleteMethod_d9b2774b := 'DELETE';
  p_IsCustom_d9b2774b := FALSE;
  p_IncrementalWatermarkField_d9b2774b := 'last-modified-date';
  p_MetadataSource_d9b2774b := 'Declared';
  p_SupportsCreate_d9b2774b := FALSE;
  p_SupportsUpdate_d9b2774b := FALSE;
  p_SupportsDelete_d9b2774b := FALSE;
  p_ContentHashApplicable_d9b2774b := TRUE;
  PERFORM __mj."spCreateIntegrationObject"(p_ID := p_ID_d9b2774b, p_IntegrationID := p_IntegrationID_d9b2774b, p_Name := p_Name_d9b2774b, p_DisplayName := p_DisplayName_d9b2774b, p_Description := p_Description_d9b2774b, p_Category := p_Category_d9b2774b, p_Category_Clear := TRUE, p_APIPath := p_APIPath_d9b2774b, p_ResponseDataKey := p_ResponseDataKey_d9b2774b, p_ResponseDataKey_Clear := TRUE, p_DefaultPageSize := p_DefaultPageSize_d9b2774b, p_SupportsPagination := p_SupportsPagination_d9b2774b, p_PaginationType := p_PaginationType_d9b2774b, p_SupportsIncrementalSync := p_SupportsIncrementalSync_d9b2774b, p_SupportsWrite := p_SupportsWrite_d9b2774b, p_DefaultQueryParams := p_DefaultQueryParams_d9b2774b, p_DefaultQueryParams_Clear := TRUE, p_Configuration := p_Configuration_d9b2774b, p_Sequence := p_Sequence_d9b2774b, p_Status := p_Status_d9b2774b, p_WriteAPIPath := p_WriteAPIPath_d9b2774b, p_WriteAPIPath_Clear := TRUE, p_WriteMethod := p_WriteMethod_d9b2774b, p_DeleteMethod := p_DeleteMethod_d9b2774b, p_IsCustom := p_IsCustom_d9b2774b, p_CreateAPIPath := p_CreateAPIPath_d9b2774b, p_CreateAPIPath_Clear := TRUE, p_CreateMethod := p_CreateMethod_d9b2774b, p_CreateMethod_Clear := TRUE, p_CreateBodyShape := p_CreateBodyShape_d9b2774b, p_CreateBodyShape_Clear := TRUE, p_CreateBodyKey := p_CreateBodyKey_d9b2774b, p_CreateBodyKey_Clear := TRUE, p_CreateIDLocation := p_CreateIDLocation_d9b2774b, p_CreateIDLocation_Clear := TRUE, p_UpdateAPIPath := p_UpdateAPIPath_d9b2774b, p_UpdateAPIPath_Clear := TRUE, p_UpdateMethod := p_UpdateMethod_d9b2774b, p_UpdateMethod_Clear := TRUE, p_UpdateBodyShape := p_UpdateBodyShape_d9b2774b, p_UpdateBodyShape_Clear := TRUE, p_UpdateBodyKey := p_UpdateBodyKey_d9b2774b, p_UpdateBodyKey_Clear := TRUE, p_UpdateIDLocation := p_UpdateIDLocation_d9b2774b, p_UpdateIDLocation_Clear := TRUE, p_DeleteAPIPath := p_DeleteAPIPath_d9b2774b, p_DeleteAPIPath_Clear := TRUE, p_DeleteIDLocation := p_DeleteIDLocation_d9b2774b, p_DeleteIDLocation_Clear := TRUE, p_IncrementalWatermarkField := p_IncrementalWatermarkField_d9b2774b, p_MetadataSource := p_MetadataSource_d9b2774b, p_SupportsCreate := p_SupportsCreate_d9b2774b, p_SupportsUpdate := p_SupportsUpdate_d9b2774b, p_SupportsDelete := p_SupportsDelete_d9b2774b, p_SyncStrategy := p_SyncStrategy_d9b2774b, p_SyncStrategy_Clear := TRUE, p_ContentHashApplicable := p_ContentHashApplicable_d9b2774b, p_StableOrderingKey := p_StableOrderingKey_d9b2774b, p_StableOrderingKey_Clear := TRUE);
END $mj$;

-- Save MJ: Integration Objects (core SP call only)
DO $mj$
DECLARE
  p_ID_9fcd4f68 UUID;
  p_IntegrationID_9fcd4f68 UUID;
  p_Name_9fcd4f68 VARCHAR(255);
  p_DisplayName_9fcd4f68 VARCHAR(255);
  p_Description_9fcd4f68 TEXT;
  p_Category_9fcd4f68 VARCHAR(100);
  p_APIPath_9fcd4f68 VARCHAR(500);
  p_ResponseDataKey_9fcd4f68 VARCHAR(255);
  p_DefaultPageSize_9fcd4f68 INTEGER;
  p_SupportsPagination_9fcd4f68 BOOLEAN;
  p_PaginationType_9fcd4f68 VARCHAR(20);
  p_SupportsIncrementalSync_9fcd4f68 BOOLEAN;
  p_SupportsWrite_9fcd4f68 BOOLEAN;
  p_DefaultQueryParams_9fcd4f68 TEXT;
  p_Configuration_9fcd4f68 TEXT;
  p_Sequence_9fcd4f68 INTEGER;
  p_Status_9fcd4f68 VARCHAR(25);
  p_WriteAPIPath_9fcd4f68 VARCHAR(500);
  p_WriteMethod_9fcd4f68 VARCHAR(10);
  p_DeleteMethod_9fcd4f68 VARCHAR(10);
  p_IsCustom_9fcd4f68 BOOLEAN;
  p_CreateAPIPath_9fcd4f68 TEXT;
  p_CreateMethod_9fcd4f68 VARCHAR(20);
  p_CreateBodyShape_9fcd4f68 VARCHAR(50);
  p_CreateBodyKey_9fcd4f68 VARCHAR(100);
  p_CreateIDLocation_9fcd4f68 VARCHAR(20);
  p_UpdateAPIPath_9fcd4f68 TEXT;
  p_UpdateMethod_9fcd4f68 VARCHAR(20);
  p_UpdateBodyShape_9fcd4f68 VARCHAR(50);
  p_UpdateBodyKey_9fcd4f68 VARCHAR(100);
  p_UpdateIDLocation_9fcd4f68 VARCHAR(20);
  p_DeleteAPIPath_9fcd4f68 TEXT;
  p_DeleteIDLocation_9fcd4f68 VARCHAR(20);
  p_IncrementalWatermarkField_9fcd4f68 VARCHAR(255);
  p_MetadataSource_9fcd4f68 VARCHAR(20);
  p_SupportsCreate_9fcd4f68 BOOLEAN;
  p_SupportsUpdate_9fcd4f68 BOOLEAN;
  p_SupportsDelete_9fcd4f68 BOOLEAN;
  p_SyncStrategy_9fcd4f68 VARCHAR(50);
  p_ContentHashApplicable_9fcd4f68 BOOLEAN;
  p_StableOrderingKey_9fcd4f68 VARCHAR(255);
BEGIN
  p_ID_9fcd4f68 := 'FB6D0904-DD1C-54A2-99AD-901CC4B56562';
  p_IntegrationID_9fcd4f68 := 'D2E0507F-6F7F-4C10-8493-21DAF94AE18E';
  p_Name_9fcd4f68 := 'email';
  p_DisplayName_9fcd4f68 := 'Email';
  p_Description_9fcd4f68 := 'Public email addresses (person section). Most ORCID emails are private, so this is usually empty. Derived from the stored record.';
  p_APIPath_9fcd4f68 := '/{iD}/email';
  p_DefaultPageSize_9fcd4f68 := 100;
  p_SupportsPagination_9fcd4f68 := FALSE;
  p_PaginationType_9fcd4f68 := 'None';
  p_SupportsIncrementalSync_9fcd4f68 := TRUE;
  p_SupportsWrite_9fcd4f68 := FALSE;
  p_Configuration_9fcd4f68 := '{"endpoint": "/{iD}/email", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}';
  p_Sequence_9fcd4f68 := 14;
  p_Status_9fcd4f68 := 'Active';
  p_WriteMethod_9fcd4f68 := 'POST';
  p_DeleteMethod_9fcd4f68 := 'DELETE';
  p_IsCustom_9fcd4f68 := FALSE;
  p_IncrementalWatermarkField_9fcd4f68 := 'last-modified-date';
  p_MetadataSource_9fcd4f68 := 'Declared';
  p_SupportsCreate_9fcd4f68 := FALSE;
  p_SupportsUpdate_9fcd4f68 := FALSE;
  p_SupportsDelete_9fcd4f68 := FALSE;
  p_ContentHashApplicable_9fcd4f68 := TRUE;
  PERFORM __mj."spCreateIntegrationObject"(p_ID := p_ID_9fcd4f68, p_IntegrationID := p_IntegrationID_9fcd4f68, p_Name := p_Name_9fcd4f68, p_DisplayName := p_DisplayName_9fcd4f68, p_Description := p_Description_9fcd4f68, p_Category := p_Category_9fcd4f68, p_Category_Clear := TRUE, p_APIPath := p_APIPath_9fcd4f68, p_ResponseDataKey := p_ResponseDataKey_9fcd4f68, p_ResponseDataKey_Clear := TRUE, p_DefaultPageSize := p_DefaultPageSize_9fcd4f68, p_SupportsPagination := p_SupportsPagination_9fcd4f68, p_PaginationType := p_PaginationType_9fcd4f68, p_SupportsIncrementalSync := p_SupportsIncrementalSync_9fcd4f68, p_SupportsWrite := p_SupportsWrite_9fcd4f68, p_DefaultQueryParams := p_DefaultQueryParams_9fcd4f68, p_DefaultQueryParams_Clear := TRUE, p_Configuration := p_Configuration_9fcd4f68, p_Sequence := p_Sequence_9fcd4f68, p_Status := p_Status_9fcd4f68, p_WriteAPIPath := p_WriteAPIPath_9fcd4f68, p_WriteAPIPath_Clear := TRUE, p_WriteMethod := p_WriteMethod_9fcd4f68, p_DeleteMethod := p_DeleteMethod_9fcd4f68, p_IsCustom := p_IsCustom_9fcd4f68, p_CreateAPIPath := p_CreateAPIPath_9fcd4f68, p_CreateAPIPath_Clear := TRUE, p_CreateMethod := p_CreateMethod_9fcd4f68, p_CreateMethod_Clear := TRUE, p_CreateBodyShape := p_CreateBodyShape_9fcd4f68, p_CreateBodyShape_Clear := TRUE, p_CreateBodyKey := p_CreateBodyKey_9fcd4f68, p_CreateBodyKey_Clear := TRUE, p_CreateIDLocation := p_CreateIDLocation_9fcd4f68, p_CreateIDLocation_Clear := TRUE, p_UpdateAPIPath := p_UpdateAPIPath_9fcd4f68, p_UpdateAPIPath_Clear := TRUE, p_UpdateMethod := p_UpdateMethod_9fcd4f68, p_UpdateMethod_Clear := TRUE, p_UpdateBodyShape := p_UpdateBodyShape_9fcd4f68, p_UpdateBodyShape_Clear := TRUE, p_UpdateBodyKey := p_UpdateBodyKey_9fcd4f68, p_UpdateBodyKey_Clear := TRUE, p_UpdateIDLocation := p_UpdateIDLocation_9fcd4f68, p_UpdateIDLocation_Clear := TRUE, p_DeleteAPIPath := p_DeleteAPIPath_9fcd4f68, p_DeleteAPIPath_Clear := TRUE, p_DeleteIDLocation := p_DeleteIDLocation_9fcd4f68, p_DeleteIDLocation_Clear := TRUE, p_IncrementalWatermarkField := p_IncrementalWatermarkField_9fcd4f68, p_MetadataSource := p_MetadataSource_9fcd4f68, p_SupportsCreate := p_SupportsCreate_9fcd4f68, p_SupportsUpdate := p_SupportsUpdate_9fcd4f68, p_SupportsDelete := p_SupportsDelete_9fcd4f68, p_SyncStrategy := p_SyncStrategy_9fcd4f68, p_SyncStrategy_Clear := TRUE, p_ContentHashApplicable := p_ContentHashApplicable_9fcd4f68, p_StableOrderingKey := p_StableOrderingKey_9fcd4f68, p_StableOrderingKey_Clear := TRUE);
END $mj$;

-- Save MJ: Integration Objects (core SP call only)
DO $mj$
DECLARE
  p_ID_1b4ac07d UUID;
  p_IntegrationID_1b4ac07d UUID;
  p_Name_1b4ac07d VARCHAR(255);
  p_DisplayName_1b4ac07d VARCHAR(255);
  p_Description_1b4ac07d TEXT;
  p_Category_1b4ac07d VARCHAR(100);
  p_APIPath_1b4ac07d VARCHAR(500);
  p_ResponseDataKey_1b4ac07d VARCHAR(255);
  p_DefaultPageSize_1b4ac07d INTEGER;
  p_SupportsPagination_1b4ac07d BOOLEAN;
  p_PaginationType_1b4ac07d VARCHAR(20);
  p_SupportsIncrementalSync_1b4ac07d BOOLEAN;
  p_SupportsWrite_1b4ac07d BOOLEAN;
  p_DefaultQueryParams_1b4ac07d TEXT;
  p_Configuration_1b4ac07d TEXT;
  p_Sequence_1b4ac07d INTEGER;
  p_Status_1b4ac07d VARCHAR(25);
  p_WriteAPIPath_1b4ac07d VARCHAR(500);
  p_WriteMethod_1b4ac07d VARCHAR(10);
  p_DeleteMethod_1b4ac07d VARCHAR(10);
  p_IsCustom_1b4ac07d BOOLEAN;
  p_CreateAPIPath_1b4ac07d TEXT;
  p_CreateMethod_1b4ac07d VARCHAR(20);
  p_CreateBodyShape_1b4ac07d VARCHAR(50);
  p_CreateBodyKey_1b4ac07d VARCHAR(100);
  p_CreateIDLocation_1b4ac07d VARCHAR(20);
  p_UpdateAPIPath_1b4ac07d TEXT;
  p_UpdateMethod_1b4ac07d VARCHAR(20);
  p_UpdateBodyShape_1b4ac07d VARCHAR(50);
  p_UpdateBodyKey_1b4ac07d VARCHAR(100);
  p_UpdateIDLocation_1b4ac07d VARCHAR(20);
  p_DeleteAPIPath_1b4ac07d TEXT;
  p_DeleteIDLocation_1b4ac07d VARCHAR(20);
  p_IncrementalWatermarkField_1b4ac07d VARCHAR(255);
  p_MetadataSource_1b4ac07d VARCHAR(20);
  p_SupportsCreate_1b4ac07d BOOLEAN;
  p_SupportsUpdate_1b4ac07d BOOLEAN;
  p_SupportsDelete_1b4ac07d BOOLEAN;
  p_SyncStrategy_1b4ac07d VARCHAR(50);
  p_ContentHashApplicable_1b4ac07d BOOLEAN;
  p_StableOrderingKey_1b4ac07d VARCHAR(255);
BEGIN
  p_ID_1b4ac07d := 'C4A09B88-C6CC-54DF-8D50-0782A34D0907';
  p_IntegrationID_1b4ac07d := 'D2E0507F-6F7F-4C10-8493-21DAF94AE18E';
  p_Name_1b4ac07d := 'address';
  p_DisplayName_1b4ac07d := 'Address';
  p_Description_1b4ac07d := 'Country entries (person section). Derived from the stored record; one row per address.';
  p_APIPath_1b4ac07d := '/{iD}/address';
  p_DefaultPageSize_1b4ac07d := 100;
  p_SupportsPagination_1b4ac07d := FALSE;
  p_PaginationType_1b4ac07d := 'None';
  p_SupportsIncrementalSync_1b4ac07d := TRUE;
  p_SupportsWrite_1b4ac07d := FALSE;
  p_Configuration_1b4ac07d := '{"endpoint": "/{iD}/address", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}';
  p_Sequence_1b4ac07d := 15;
  p_Status_1b4ac07d := 'Active';
  p_WriteMethod_1b4ac07d := 'POST';
  p_DeleteMethod_1b4ac07d := 'DELETE';
  p_IsCustom_1b4ac07d := FALSE;
  p_IncrementalWatermarkField_1b4ac07d := 'last-modified-date';
  p_MetadataSource_1b4ac07d := 'Declared';
  p_SupportsCreate_1b4ac07d := FALSE;
  p_SupportsUpdate_1b4ac07d := FALSE;
  p_SupportsDelete_1b4ac07d := FALSE;
  p_ContentHashApplicable_1b4ac07d := TRUE;
  PERFORM __mj."spCreateIntegrationObject"(p_ID := p_ID_1b4ac07d, p_IntegrationID := p_IntegrationID_1b4ac07d, p_Name := p_Name_1b4ac07d, p_DisplayName := p_DisplayName_1b4ac07d, p_Description := p_Description_1b4ac07d, p_Category := p_Category_1b4ac07d, p_Category_Clear := TRUE, p_APIPath := p_APIPath_1b4ac07d, p_ResponseDataKey := p_ResponseDataKey_1b4ac07d, p_ResponseDataKey_Clear := TRUE, p_DefaultPageSize := p_DefaultPageSize_1b4ac07d, p_SupportsPagination := p_SupportsPagination_1b4ac07d, p_PaginationType := p_PaginationType_1b4ac07d, p_SupportsIncrementalSync := p_SupportsIncrementalSync_1b4ac07d, p_SupportsWrite := p_SupportsWrite_1b4ac07d, p_DefaultQueryParams := p_DefaultQueryParams_1b4ac07d, p_DefaultQueryParams_Clear := TRUE, p_Configuration := p_Configuration_1b4ac07d, p_Sequence := p_Sequence_1b4ac07d, p_Status := p_Status_1b4ac07d, p_WriteAPIPath := p_WriteAPIPath_1b4ac07d, p_WriteAPIPath_Clear := TRUE, p_WriteMethod := p_WriteMethod_1b4ac07d, p_DeleteMethod := p_DeleteMethod_1b4ac07d, p_IsCustom := p_IsCustom_1b4ac07d, p_CreateAPIPath := p_CreateAPIPath_1b4ac07d, p_CreateAPIPath_Clear := TRUE, p_CreateMethod := p_CreateMethod_1b4ac07d, p_CreateMethod_Clear := TRUE, p_CreateBodyShape := p_CreateBodyShape_1b4ac07d, p_CreateBodyShape_Clear := TRUE, p_CreateBodyKey := p_CreateBodyKey_1b4ac07d, p_CreateBodyKey_Clear := TRUE, p_CreateIDLocation := p_CreateIDLocation_1b4ac07d, p_CreateIDLocation_Clear := TRUE, p_UpdateAPIPath := p_UpdateAPIPath_1b4ac07d, p_UpdateAPIPath_Clear := TRUE, p_UpdateMethod := p_UpdateMethod_1b4ac07d, p_UpdateMethod_Clear := TRUE, p_UpdateBodyShape := p_UpdateBodyShape_1b4ac07d, p_UpdateBodyShape_Clear := TRUE, p_UpdateBodyKey := p_UpdateBodyKey_1b4ac07d, p_UpdateBodyKey_Clear := TRUE, p_UpdateIDLocation := p_UpdateIDLocation_1b4ac07d, p_UpdateIDLocation_Clear := TRUE, p_DeleteAPIPath := p_DeleteAPIPath_1b4ac07d, p_DeleteAPIPath_Clear := TRUE, p_DeleteIDLocation := p_DeleteIDLocation_1b4ac07d, p_DeleteIDLocation_Clear := TRUE, p_IncrementalWatermarkField := p_IncrementalWatermarkField_1b4ac07d, p_MetadataSource := p_MetadataSource_1b4ac07d, p_SupportsCreate := p_SupportsCreate_1b4ac07d, p_SupportsUpdate := p_SupportsUpdate_1b4ac07d, p_SupportsDelete := p_SupportsDelete_1b4ac07d, p_SyncStrategy := p_SyncStrategy_1b4ac07d, p_SyncStrategy_Clear := TRUE, p_ContentHashApplicable := p_ContentHashApplicable_1b4ac07d, p_StableOrderingKey := p_StableOrderingKey_1b4ac07d, p_StableOrderingKey_Clear := TRUE);
END $mj$;

-- Save MJ: Integration Objects (core SP call only)
DO $mj$
DECLARE
  p_ID_43cce9a4 UUID;
  p_IntegrationID_43cce9a4 UUID;
  p_Name_43cce9a4 VARCHAR(255);
  p_DisplayName_43cce9a4 VARCHAR(255);
  p_Description_43cce9a4 TEXT;
  p_Category_43cce9a4 VARCHAR(100);
  p_APIPath_43cce9a4 VARCHAR(500);
  p_ResponseDataKey_43cce9a4 VARCHAR(255);
  p_DefaultPageSize_43cce9a4 INTEGER;
  p_SupportsPagination_43cce9a4 BOOLEAN;
  p_PaginationType_43cce9a4 VARCHAR(20);
  p_SupportsIncrementalSync_43cce9a4 BOOLEAN;
  p_SupportsWrite_43cce9a4 BOOLEAN;
  p_DefaultQueryParams_43cce9a4 TEXT;
  p_Configuration_43cce9a4 TEXT;
  p_Sequence_43cce9a4 INTEGER;
  p_Status_43cce9a4 VARCHAR(25);
  p_WriteAPIPath_43cce9a4 VARCHAR(500);
  p_WriteMethod_43cce9a4 VARCHAR(10);
  p_DeleteMethod_43cce9a4 VARCHAR(10);
  p_IsCustom_43cce9a4 BOOLEAN;
  p_CreateAPIPath_43cce9a4 TEXT;
  p_CreateMethod_43cce9a4 VARCHAR(20);
  p_CreateBodyShape_43cce9a4 VARCHAR(50);
  p_CreateBodyKey_43cce9a4 VARCHAR(100);
  p_CreateIDLocation_43cce9a4 VARCHAR(20);
  p_UpdateAPIPath_43cce9a4 TEXT;
  p_UpdateMethod_43cce9a4 VARCHAR(20);
  p_UpdateBodyShape_43cce9a4 VARCHAR(50);
  p_UpdateBodyKey_43cce9a4 VARCHAR(100);
  p_UpdateIDLocation_43cce9a4 VARCHAR(20);
  p_DeleteAPIPath_43cce9a4 TEXT;
  p_DeleteIDLocation_43cce9a4 VARCHAR(20);
  p_IncrementalWatermarkField_43cce9a4 VARCHAR(255);
  p_MetadataSource_43cce9a4 VARCHAR(20);
  p_SupportsCreate_43cce9a4 BOOLEAN;
  p_SupportsUpdate_43cce9a4 BOOLEAN;
  p_SupportsDelete_43cce9a4 BOOLEAN;
  p_SyncStrategy_43cce9a4 VARCHAR(50);
  p_ContentHashApplicable_43cce9a4 BOOLEAN;
  p_StableOrderingKey_43cce9a4 VARCHAR(255);
BEGIN
  p_ID_43cce9a4 := '3F2D9F80-F35B-501D-BC52-66AF079946E5';
  p_IntegrationID_43cce9a4 := 'D2E0507F-6F7F-4C10-8493-21DAF94AE18E';
  p_Name_43cce9a4 := 'researcher-urls';
  p_DisplayName_43cce9a4 := 'Researcher Urls';
  p_Description_43cce9a4 := 'Personal and professional links the researcher added (person section). Derived from the stored record.';
  p_APIPath_43cce9a4 := '/{iD}/researcher-urls';
  p_DefaultPageSize_43cce9a4 := 100;
  p_SupportsPagination_43cce9a4 := FALSE;
  p_PaginationType_43cce9a4 := 'None';
  p_SupportsIncrementalSync_43cce9a4 := TRUE;
  p_SupportsWrite_43cce9a4 := FALSE;
  p_Configuration_43cce9a4 := '{"endpoint": "/{iD}/researcher-urls", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}';
  p_Sequence_43cce9a4 := 16;
  p_Status_43cce9a4 := 'Active';
  p_WriteMethod_43cce9a4 := 'POST';
  p_DeleteMethod_43cce9a4 := 'DELETE';
  p_IsCustom_43cce9a4 := FALSE;
  p_IncrementalWatermarkField_43cce9a4 := 'last-modified-date';
  p_MetadataSource_43cce9a4 := 'Declared';
  p_SupportsCreate_43cce9a4 := FALSE;
  p_SupportsUpdate_43cce9a4 := FALSE;
  p_SupportsDelete_43cce9a4 := FALSE;
  p_ContentHashApplicable_43cce9a4 := TRUE;
  PERFORM __mj."spCreateIntegrationObject"(p_ID := p_ID_43cce9a4, p_IntegrationID := p_IntegrationID_43cce9a4, p_Name := p_Name_43cce9a4, p_DisplayName := p_DisplayName_43cce9a4, p_Description := p_Description_43cce9a4, p_Category := p_Category_43cce9a4, p_Category_Clear := TRUE, p_APIPath := p_APIPath_43cce9a4, p_ResponseDataKey := p_ResponseDataKey_43cce9a4, p_ResponseDataKey_Clear := TRUE, p_DefaultPageSize := p_DefaultPageSize_43cce9a4, p_SupportsPagination := p_SupportsPagination_43cce9a4, p_PaginationType := p_PaginationType_43cce9a4, p_SupportsIncrementalSync := p_SupportsIncrementalSync_43cce9a4, p_SupportsWrite := p_SupportsWrite_43cce9a4, p_DefaultQueryParams := p_DefaultQueryParams_43cce9a4, p_DefaultQueryParams_Clear := TRUE, p_Configuration := p_Configuration_43cce9a4, p_Sequence := p_Sequence_43cce9a4, p_Status := p_Status_43cce9a4, p_WriteAPIPath := p_WriteAPIPath_43cce9a4, p_WriteAPIPath_Clear := TRUE, p_WriteMethod := p_WriteMethod_43cce9a4, p_DeleteMethod := p_DeleteMethod_43cce9a4, p_IsCustom := p_IsCustom_43cce9a4, p_CreateAPIPath := p_CreateAPIPath_43cce9a4, p_CreateAPIPath_Clear := TRUE, p_CreateMethod := p_CreateMethod_43cce9a4, p_CreateMethod_Clear := TRUE, p_CreateBodyShape := p_CreateBodyShape_43cce9a4, p_CreateBodyShape_Clear := TRUE, p_CreateBodyKey := p_CreateBodyKey_43cce9a4, p_CreateBodyKey_Clear := TRUE, p_CreateIDLocation := p_CreateIDLocation_43cce9a4, p_CreateIDLocation_Clear := TRUE, p_UpdateAPIPath := p_UpdateAPIPath_43cce9a4, p_UpdateAPIPath_Clear := TRUE, p_UpdateMethod := p_UpdateMethod_43cce9a4, p_UpdateMethod_Clear := TRUE, p_UpdateBodyShape := p_UpdateBodyShape_43cce9a4, p_UpdateBodyShape_Clear := TRUE, p_UpdateBodyKey := p_UpdateBodyKey_43cce9a4, p_UpdateBodyKey_Clear := TRUE, p_UpdateIDLocation := p_UpdateIDLocation_43cce9a4, p_UpdateIDLocation_Clear := TRUE, p_DeleteAPIPath := p_DeleteAPIPath_43cce9a4, p_DeleteAPIPath_Clear := TRUE, p_DeleteIDLocation := p_DeleteIDLocation_43cce9a4, p_DeleteIDLocation_Clear := TRUE, p_IncrementalWatermarkField := p_IncrementalWatermarkField_43cce9a4, p_MetadataSource := p_MetadataSource_43cce9a4, p_SupportsCreate := p_SupportsCreate_43cce9a4, p_SupportsUpdate := p_SupportsUpdate_43cce9a4, p_SupportsDelete := p_SupportsDelete_43cce9a4, p_SyncStrategy := p_SyncStrategy_43cce9a4, p_SyncStrategy_Clear := TRUE, p_ContentHashApplicable := p_ContentHashApplicable_43cce9a4, p_StableOrderingKey := p_StableOrderingKey_43cce9a4, p_StableOrderingKey_Clear := TRUE);
END $mj$;

-- Save MJ: Integration Objects (core SP call only)
DO $mj$
DECLARE
  p_ID_91de9608 UUID;
  p_IntegrationID_91de9608 UUID;
  p_Name_91de9608 VARCHAR(255);
  p_DisplayName_91de9608 VARCHAR(255);
  p_Description_91de9608 TEXT;
  p_Category_91de9608 VARCHAR(100);
  p_APIPath_91de9608 VARCHAR(500);
  p_ResponseDataKey_91de9608 VARCHAR(255);
  p_DefaultPageSize_91de9608 INTEGER;
  p_SupportsPagination_91de9608 BOOLEAN;
  p_PaginationType_91de9608 VARCHAR(20);
  p_SupportsIncrementalSync_91de9608 BOOLEAN;
  p_SupportsWrite_91de9608 BOOLEAN;
  p_DefaultQueryParams_91de9608 TEXT;
  p_Configuration_91de9608 TEXT;
  p_Sequence_91de9608 INTEGER;
  p_Status_91de9608 VARCHAR(25);
  p_WriteAPIPath_91de9608 VARCHAR(500);
  p_WriteMethod_91de9608 VARCHAR(10);
  p_DeleteMethod_91de9608 VARCHAR(10);
  p_IsCustom_91de9608 BOOLEAN;
  p_CreateAPIPath_91de9608 TEXT;
  p_CreateMethod_91de9608 VARCHAR(20);
  p_CreateBodyShape_91de9608 VARCHAR(50);
  p_CreateBodyKey_91de9608 VARCHAR(100);
  p_CreateIDLocation_91de9608 VARCHAR(20);
  p_UpdateAPIPath_91de9608 TEXT;
  p_UpdateMethod_91de9608 VARCHAR(20);
  p_UpdateBodyShape_91de9608 VARCHAR(50);
  p_UpdateBodyKey_91de9608 VARCHAR(100);
  p_UpdateIDLocation_91de9608 VARCHAR(20);
  p_DeleteAPIPath_91de9608 TEXT;
  p_DeleteIDLocation_91de9608 VARCHAR(20);
  p_IncrementalWatermarkField_91de9608 VARCHAR(255);
  p_MetadataSource_91de9608 VARCHAR(20);
  p_SupportsCreate_91de9608 BOOLEAN;
  p_SupportsUpdate_91de9608 BOOLEAN;
  p_SupportsDelete_91de9608 BOOLEAN;
  p_SyncStrategy_91de9608 VARCHAR(50);
  p_ContentHashApplicable_91de9608 BOOLEAN;
  p_StableOrderingKey_91de9608 VARCHAR(255);
BEGIN
  p_ID_91de9608 := '224D74C1-460F-5612-BD7D-29027DF76792';
  p_IntegrationID_91de9608 := 'D2E0507F-6F7F-4C10-8493-21DAF94AE18E';
  p_Name_91de9608 := 'external-identifiers';
  p_DisplayName_91de9608 := 'External Identifiers';
  p_Description_91de9608 := 'Person-level identifiers on other systems: Scopus Author ID, ResearcherID, Loop, ... (person section). Derived from the stored record.';
  p_APIPath_91de9608 := '/{iD}/external-identifiers';
  p_DefaultPageSize_91de9608 := 100;
  p_SupportsPagination_91de9608 := FALSE;
  p_PaginationType_91de9608 := 'None';
  p_SupportsIncrementalSync_91de9608 := TRUE;
  p_SupportsWrite_91de9608 := FALSE;
  p_Configuration_91de9608 := '{"endpoint": "/{iD}/external-identifiers", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}';
  p_Sequence_91de9608 := 17;
  p_Status_91de9608 := 'Active';
  p_WriteMethod_91de9608 := 'POST';
  p_DeleteMethod_91de9608 := 'DELETE';
  p_IsCustom_91de9608 := FALSE;
  p_IncrementalWatermarkField_91de9608 := 'last-modified-date';
  p_MetadataSource_91de9608 := 'Declared';
  p_SupportsCreate_91de9608 := FALSE;
  p_SupportsUpdate_91de9608 := FALSE;
  p_SupportsDelete_91de9608 := FALSE;
  p_ContentHashApplicable_91de9608 := TRUE;
  PERFORM __mj."spCreateIntegrationObject"(p_ID := p_ID_91de9608, p_IntegrationID := p_IntegrationID_91de9608, p_Name := p_Name_91de9608, p_DisplayName := p_DisplayName_91de9608, p_Description := p_Description_91de9608, p_Category := p_Category_91de9608, p_Category_Clear := TRUE, p_APIPath := p_APIPath_91de9608, p_ResponseDataKey := p_ResponseDataKey_91de9608, p_ResponseDataKey_Clear := TRUE, p_DefaultPageSize := p_DefaultPageSize_91de9608, p_SupportsPagination := p_SupportsPagination_91de9608, p_PaginationType := p_PaginationType_91de9608, p_SupportsIncrementalSync := p_SupportsIncrementalSync_91de9608, p_SupportsWrite := p_SupportsWrite_91de9608, p_DefaultQueryParams := p_DefaultQueryParams_91de9608, p_DefaultQueryParams_Clear := TRUE, p_Configuration := p_Configuration_91de9608, p_Sequence := p_Sequence_91de9608, p_Status := p_Status_91de9608, p_WriteAPIPath := p_WriteAPIPath_91de9608, p_WriteAPIPath_Clear := TRUE, p_WriteMethod := p_WriteMethod_91de9608, p_DeleteMethod := p_DeleteMethod_91de9608, p_IsCustom := p_IsCustom_91de9608, p_CreateAPIPath := p_CreateAPIPath_91de9608, p_CreateAPIPath_Clear := TRUE, p_CreateMethod := p_CreateMethod_91de9608, p_CreateMethod_Clear := TRUE, p_CreateBodyShape := p_CreateBodyShape_91de9608, p_CreateBodyShape_Clear := TRUE, p_CreateBodyKey := p_CreateBodyKey_91de9608, p_CreateBodyKey_Clear := TRUE, p_CreateIDLocation := p_CreateIDLocation_91de9608, p_CreateIDLocation_Clear := TRUE, p_UpdateAPIPath := p_UpdateAPIPath_91de9608, p_UpdateAPIPath_Clear := TRUE, p_UpdateMethod := p_UpdateMethod_91de9608, p_UpdateMethod_Clear := TRUE, p_UpdateBodyShape := p_UpdateBodyShape_91de9608, p_UpdateBodyShape_Clear := TRUE, p_UpdateBodyKey := p_UpdateBodyKey_91de9608, p_UpdateBodyKey_Clear := TRUE, p_UpdateIDLocation := p_UpdateIDLocation_91de9608, p_UpdateIDLocation_Clear := TRUE, p_DeleteAPIPath := p_DeleteAPIPath_91de9608, p_DeleteAPIPath_Clear := TRUE, p_DeleteIDLocation := p_DeleteIDLocation_91de9608, p_DeleteIDLocation_Clear := TRUE, p_IncrementalWatermarkField := p_IncrementalWatermarkField_91de9608, p_MetadataSource := p_MetadataSource_91de9608, p_SupportsCreate := p_SupportsCreate_91de9608, p_SupportsUpdate := p_SupportsUpdate_91de9608, p_SupportsDelete := p_SupportsDelete_91de9608, p_SyncStrategy := p_SyncStrategy_91de9608, p_SyncStrategy_Clear := TRUE, p_ContentHashApplicable := p_ContentHashApplicable_91de9608, p_StableOrderingKey := p_StableOrderingKey_91de9608, p_StableOrderingKey_Clear := TRUE);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_82db57a4 UUID;
  p_IntegrationObjectID_82db57a4 UUID;
  p_Name_82db57a4 VARCHAR(255);
  p_DisplayName_82db57a4 VARCHAR(255);
  p_Description_82db57a4 TEXT;
  p_Category_82db57a4 VARCHAR(100);
  p_Type_82db57a4 VARCHAR(100);
  p_Length_82db57a4 INTEGER;
  p_Precision_82db57a4 INTEGER;
  p_Scale_82db57a4 INTEGER;
  p_AllowsNull_82db57a4 BOOLEAN;
  p_DefaultValue_82db57a4 VARCHAR(255);
  p_IsPrimaryKey_82db57a4 BOOLEAN;
  p_IsUniqueKey_82db57a4 BOOLEAN;
  p_IsReadOnly_82db57a4 BOOLEAN;
  p_IsRequired_82db57a4 BOOLEAN;
  p_RelatedIntegrationObjectID_82db57a4 UUID;
  p_RelatedIntegrationObjectFieldName_82db57a4 VARCHAR(255);
  p_Sequence_82db57a4 INTEGER;
  p_Configuration_82db57a4 TEXT;
  p_Status_82db57a4 VARCHAR(25);
  p_IsCustom_82db57a4 BOOLEAN;
  p_MetadataSource_82db57a4 VARCHAR(20);
BEGIN
  p_ID_82db57a4 := '57E6E91A-EF2B-52AD-A425-6B3514804E52';
  p_IntegrationObjectID_82db57a4 := '73AED6B8-468D-403B-B994-F3C786C98BC0';
  p_Name_82db57a4 := 'activities-summary';
  p_DisplayName_82db57a4 := 'Activities Summary';
  p_Description_82db57a4 := 'The activities-summary block of the record: every activity section summary (works, employments, fundings, peer-reviews, ...). Stored so the section objects derive from it with no further API call.';
  p_Type_82db57a4 := 'json';
  p_AllowsNull_82db57a4 := TRUE;
  p_IsPrimaryKey_82db57a4 := FALSE;
  p_IsUniqueKey_82db57a4 := FALSE;
  p_IsReadOnly_82db57a4 := TRUE;
  p_IsRequired_82db57a4 := FALSE;
  p_Sequence_82db57a4 := 19;
  p_Status_82db57a4 := 'Active';
  p_IsCustom_82db57a4 := FALSE;
  p_MetadataSource_82db57a4 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_82db57a4, p_IntegrationObjectID := p_IntegrationObjectID_82db57a4, p_Name := p_Name_82db57a4, p_DisplayName := p_DisplayName_82db57a4, p_Description := p_Description_82db57a4, p_Category := p_Category_82db57a4, p_Category_Clear := TRUE, p_Type := p_Type_82db57a4, p_Length := p_Length_82db57a4, p_Length_Clear := TRUE, p_Precision := p_Precision_82db57a4, p_Precision_Clear := TRUE, p_Scale := p_Scale_82db57a4, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_82db57a4, p_DefaultValue := p_DefaultValue_82db57a4, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_82db57a4, p_IsUniqueKey := p_IsUniqueKey_82db57a4, p_IsReadOnly := p_IsReadOnly_82db57a4, p_IsRequired := p_IsRequired_82db57a4, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_82db57a4, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_82db57a4, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_82db57a4, p_Configuration := p_Configuration_82db57a4, p_Configuration_Clear := TRUE, p_Status := p_Status_82db57a4, p_IsCustom := p_IsCustom_82db57a4, p_MetadataSource := p_MetadataSource_82db57a4);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_73558386 UUID;
  p_IntegrationObjectID_73558386 UUID;
  p_Name_73558386 VARCHAR(255);
  p_DisplayName_73558386 VARCHAR(255);
  p_Description_73558386 TEXT;
  p_Category_73558386 VARCHAR(100);
  p_Type_73558386 VARCHAR(100);
  p_Length_73558386 INTEGER;
  p_Precision_73558386 INTEGER;
  p_Scale_73558386 INTEGER;
  p_AllowsNull_73558386 BOOLEAN;
  p_DefaultValue_73558386 VARCHAR(255);
  p_IsPrimaryKey_73558386 BOOLEAN;
  p_IsUniqueKey_73558386 BOOLEAN;
  p_IsReadOnly_73558386 BOOLEAN;
  p_IsRequired_73558386 BOOLEAN;
  p_RelatedIntegrationObjectID_73558386 UUID;
  p_RelatedIntegrationObjectFieldName_73558386 VARCHAR(255);
  p_Sequence_73558386 INTEGER;
  p_Configuration_73558386 TEXT;
  p_Status_73558386 VARCHAR(25);
  p_IsCustom_73558386 BOOLEAN;
  p_MetadataSource_73558386 VARCHAR(20);
BEGIN
  p_ID_73558386 := '2B780865-8166-5EDF-801A-CB7206C1C774';
  p_IntegrationObjectID_73558386 := '1D853840-A875-41E9-AB35-940345EF1434';
  p_Name_73558386 := 'work-title';
  p_DisplayName_73558386 := 'Work Title';
  p_Description_73558386 := 'Title of the work. Lifted from title.title.';
  p_Type_73558386 := 'String';
  p_Length_73558386 := 2000;
  p_AllowsNull_73558386 := TRUE;
  p_IsPrimaryKey_73558386 := FALSE;
  p_IsUniqueKey_73558386 := FALSE;
  p_IsReadOnly_73558386 := TRUE;
  p_IsRequired_73558386 := FALSE;
  p_Sequence_73558386 := 19;
  p_Status_73558386 := 'Active';
  p_IsCustom_73558386 := FALSE;
  p_MetadataSource_73558386 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_73558386, p_IntegrationObjectID := p_IntegrationObjectID_73558386, p_Name := p_Name_73558386, p_DisplayName := p_DisplayName_73558386, p_Description := p_Description_73558386, p_Category := p_Category_73558386, p_Category_Clear := TRUE, p_Type := p_Type_73558386, p_Length := p_Length_73558386, p_Precision := p_Precision_73558386, p_Precision_Clear := TRUE, p_Scale := p_Scale_73558386, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_73558386, p_DefaultValue := p_DefaultValue_73558386, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_73558386, p_IsUniqueKey := p_IsUniqueKey_73558386, p_IsReadOnly := p_IsReadOnly_73558386, p_IsRequired := p_IsRequired_73558386, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_73558386, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_73558386, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_73558386, p_Configuration := p_Configuration_73558386, p_Configuration_Clear := TRUE, p_Status := p_Status_73558386, p_IsCustom := p_IsCustom_73558386, p_MetadataSource := p_MetadataSource_73558386);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_18ece38a UUID;
  p_IntegrationObjectID_18ece38a UUID;
  p_Name_18ece38a VARCHAR(255);
  p_DisplayName_18ece38a VARCHAR(255);
  p_Description_18ece38a TEXT;
  p_Category_18ece38a VARCHAR(100);
  p_Type_18ece38a VARCHAR(100);
  p_Length_18ece38a INTEGER;
  p_Precision_18ece38a INTEGER;
  p_Scale_18ece38a INTEGER;
  p_AllowsNull_18ece38a BOOLEAN;
  p_DefaultValue_18ece38a VARCHAR(255);
  p_IsPrimaryKey_18ece38a BOOLEAN;
  p_IsUniqueKey_18ece38a BOOLEAN;
  p_IsReadOnly_18ece38a BOOLEAN;
  p_IsRequired_18ece38a BOOLEAN;
  p_RelatedIntegrationObjectID_18ece38a UUID;
  p_RelatedIntegrationObjectFieldName_18ece38a VARCHAR(255);
  p_Sequence_18ece38a INTEGER;
  p_Configuration_18ece38a TEXT;
  p_Status_18ece38a VARCHAR(25);
  p_IsCustom_18ece38a BOOLEAN;
  p_MetadataSource_18ece38a VARCHAR(20);
BEGIN
  p_ID_18ece38a := '3D2EF4EF-2897-5880-A217-3A2EC3FDFF36';
  p_IntegrationObjectID_18ece38a := '1D853840-A875-41E9-AB35-940345EF1434';
  p_Name_18ece38a := 'work-subtitle';
  p_DisplayName_18ece38a := 'Work Subtitle';
  p_Description_18ece38a := 'Subtitle of the work. Lifted from title.subtitle.';
  p_Type_18ece38a := 'String';
  p_Length_18ece38a := 2000;
  p_AllowsNull_18ece38a := TRUE;
  p_IsPrimaryKey_18ece38a := FALSE;
  p_IsUniqueKey_18ece38a := FALSE;
  p_IsReadOnly_18ece38a := TRUE;
  p_IsRequired_18ece38a := FALSE;
  p_Sequence_18ece38a := 20;
  p_Status_18ece38a := 'Active';
  p_IsCustom_18ece38a := FALSE;
  p_MetadataSource_18ece38a := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_18ece38a, p_IntegrationObjectID := p_IntegrationObjectID_18ece38a, p_Name := p_Name_18ece38a, p_DisplayName := p_DisplayName_18ece38a, p_Description := p_Description_18ece38a, p_Category := p_Category_18ece38a, p_Category_Clear := TRUE, p_Type := p_Type_18ece38a, p_Length := p_Length_18ece38a, p_Precision := p_Precision_18ece38a, p_Precision_Clear := TRUE, p_Scale := p_Scale_18ece38a, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_18ece38a, p_DefaultValue := p_DefaultValue_18ece38a, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_18ece38a, p_IsUniqueKey := p_IsUniqueKey_18ece38a, p_IsReadOnly := p_IsReadOnly_18ece38a, p_IsRequired := p_IsRequired_18ece38a, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_18ece38a, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_18ece38a, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_18ece38a, p_Configuration := p_Configuration_18ece38a, p_Configuration_Clear := TRUE, p_Status := p_Status_18ece38a, p_IsCustom := p_IsCustom_18ece38a, p_MetadataSource := p_MetadataSource_18ece38a);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_8b08683a UUID;
  p_IntegrationObjectID_8b08683a UUID;
  p_Name_8b08683a VARCHAR(255);
  p_DisplayName_8b08683a VARCHAR(255);
  p_Description_8b08683a TEXT;
  p_Category_8b08683a VARCHAR(100);
  p_Type_8b08683a VARCHAR(100);
  p_Length_8b08683a INTEGER;
  p_Precision_8b08683a INTEGER;
  p_Scale_8b08683a INTEGER;
  p_AllowsNull_8b08683a BOOLEAN;
  p_DefaultValue_8b08683a VARCHAR(255);
  p_IsPrimaryKey_8b08683a BOOLEAN;
  p_IsUniqueKey_8b08683a BOOLEAN;
  p_IsReadOnly_8b08683a BOOLEAN;
  p_IsRequired_8b08683a BOOLEAN;
  p_RelatedIntegrationObjectID_8b08683a UUID;
  p_RelatedIntegrationObjectFieldName_8b08683a VARCHAR(255);
  p_Sequence_8b08683a INTEGER;
  p_Configuration_8b08683a TEXT;
  p_Status_8b08683a VARCHAR(25);
  p_IsCustom_8b08683a BOOLEAN;
  p_MetadataSource_8b08683a VARCHAR(20);
BEGIN
  p_ID_8b08683a := '059C4CC3-53C1-5CFD-BB36-50AC18921C7B';
  p_IntegrationObjectID_8b08683a := '1D853840-A875-41E9-AB35-940345EF1434';
  p_Name_8b08683a := 'translated-title';
  p_DisplayName_8b08683a := 'Translated Title';
  p_Description_8b08683a := 'Translated title of the work. Lifted from title.translated-title.';
  p_Type_8b08683a := 'String';
  p_Length_8b08683a := 2000;
  p_AllowsNull_8b08683a := TRUE;
  p_IsPrimaryKey_8b08683a := FALSE;
  p_IsUniqueKey_8b08683a := FALSE;
  p_IsReadOnly_8b08683a := TRUE;
  p_IsRequired_8b08683a := FALSE;
  p_Sequence_8b08683a := 21;
  p_Status_8b08683a := 'Active';
  p_IsCustom_8b08683a := FALSE;
  p_MetadataSource_8b08683a := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_8b08683a, p_IntegrationObjectID := p_IntegrationObjectID_8b08683a, p_Name := p_Name_8b08683a, p_DisplayName := p_DisplayName_8b08683a, p_Description := p_Description_8b08683a, p_Category := p_Category_8b08683a, p_Category_Clear := TRUE, p_Type := p_Type_8b08683a, p_Length := p_Length_8b08683a, p_Precision := p_Precision_8b08683a, p_Precision_Clear := TRUE, p_Scale := p_Scale_8b08683a, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_8b08683a, p_DefaultValue := p_DefaultValue_8b08683a, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_8b08683a, p_IsUniqueKey := p_IsUniqueKey_8b08683a, p_IsReadOnly := p_IsReadOnly_8b08683a, p_IsRequired := p_IsRequired_8b08683a, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_8b08683a, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_8b08683a, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_8b08683a, p_Configuration := p_Configuration_8b08683a, p_Configuration_Clear := TRUE, p_Status := p_Status_8b08683a, p_IsCustom := p_IsCustom_8b08683a, p_MetadataSource := p_MetadataSource_8b08683a);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_a20ede7e UUID;
  p_IntegrationObjectID_a20ede7e UUID;
  p_Name_a20ede7e VARCHAR(255);
  p_DisplayName_a20ede7e VARCHAR(255);
  p_Description_a20ede7e TEXT;
  p_Category_a20ede7e VARCHAR(100);
  p_Type_a20ede7e VARCHAR(100);
  p_Length_a20ede7e INTEGER;
  p_Precision_a20ede7e INTEGER;
  p_Scale_a20ede7e INTEGER;
  p_AllowsNull_a20ede7e BOOLEAN;
  p_DefaultValue_a20ede7e VARCHAR(255);
  p_IsPrimaryKey_a20ede7e BOOLEAN;
  p_IsUniqueKey_a20ede7e BOOLEAN;
  p_IsReadOnly_a20ede7e BOOLEAN;
  p_IsRequired_a20ede7e BOOLEAN;
  p_RelatedIntegrationObjectID_a20ede7e UUID;
  p_RelatedIntegrationObjectFieldName_a20ede7e VARCHAR(255);
  p_Sequence_a20ede7e INTEGER;
  p_Configuration_a20ede7e TEXT;
  p_Status_a20ede7e VARCHAR(25);
  p_IsCustom_a20ede7e BOOLEAN;
  p_MetadataSource_a20ede7e VARCHAR(20);
BEGIN
  p_ID_a20ede7e := '94482953-F3BC-51BF-B4FA-35F20C3C7A99';
  p_IntegrationObjectID_a20ede7e := '1D853840-A875-41E9-AB35-940345EF1434';
  p_Name_a20ede7e := 'publication-year';
  p_DisplayName_a20ede7e := 'Publication Year';
  p_Description_a20ede7e := 'Year of the publication date; ORCID dates are partial, so month/day may be absent.';
  p_Type_a20ede7e := 'Integer';
  p_AllowsNull_a20ede7e := TRUE;
  p_IsPrimaryKey_a20ede7e := FALSE;
  p_IsUniqueKey_a20ede7e := FALSE;
  p_IsReadOnly_a20ede7e := TRUE;
  p_IsRequired_a20ede7e := FALSE;
  p_Sequence_a20ede7e := 22;
  p_Status_a20ede7e := 'Active';
  p_IsCustom_a20ede7e := FALSE;
  p_MetadataSource_a20ede7e := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_a20ede7e, p_IntegrationObjectID := p_IntegrationObjectID_a20ede7e, p_Name := p_Name_a20ede7e, p_DisplayName := p_DisplayName_a20ede7e, p_Description := p_Description_a20ede7e, p_Category := p_Category_a20ede7e, p_Category_Clear := TRUE, p_Type := p_Type_a20ede7e, p_Length := p_Length_a20ede7e, p_Length_Clear := TRUE, p_Precision := p_Precision_a20ede7e, p_Precision_Clear := TRUE, p_Scale := p_Scale_a20ede7e, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_a20ede7e, p_DefaultValue := p_DefaultValue_a20ede7e, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_a20ede7e, p_IsUniqueKey := p_IsUniqueKey_a20ede7e, p_IsReadOnly := p_IsReadOnly_a20ede7e, p_IsRequired := p_IsRequired_a20ede7e, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_a20ede7e, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_a20ede7e, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_a20ede7e, p_Configuration := p_Configuration_a20ede7e, p_Configuration_Clear := TRUE, p_Status := p_Status_a20ede7e, p_IsCustom := p_IsCustom_a20ede7e, p_MetadataSource := p_MetadataSource_a20ede7e);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_4144a853 UUID;
  p_IntegrationObjectID_4144a853 UUID;
  p_Name_4144a853 VARCHAR(255);
  p_DisplayName_4144a853 VARCHAR(255);
  p_Description_4144a853 TEXT;
  p_Category_4144a853 VARCHAR(100);
  p_Type_4144a853 VARCHAR(100);
  p_Length_4144a853 INTEGER;
  p_Precision_4144a853 INTEGER;
  p_Scale_4144a853 INTEGER;
  p_AllowsNull_4144a853 BOOLEAN;
  p_DefaultValue_4144a853 VARCHAR(255);
  p_IsPrimaryKey_4144a853 BOOLEAN;
  p_IsUniqueKey_4144a853 BOOLEAN;
  p_IsReadOnly_4144a853 BOOLEAN;
  p_IsRequired_4144a853 BOOLEAN;
  p_RelatedIntegrationObjectID_4144a853 UUID;
  p_RelatedIntegrationObjectFieldName_4144a853 VARCHAR(255);
  p_Sequence_4144a853 INTEGER;
  p_Configuration_4144a853 TEXT;
  p_Status_4144a853 VARCHAR(25);
  p_IsCustom_4144a853 BOOLEAN;
  p_MetadataSource_4144a853 VARCHAR(20);
BEGIN
  p_ID_4144a853 := '149CA198-9C7D-5899-906B-0583B2348A05';
  p_IntegrationObjectID_4144a853 := '1D853840-A875-41E9-AB35-940345EF1434';
  p_Name_4144a853 := 'publication-month';
  p_DisplayName_4144a853 := 'Publication Month';
  p_Description_4144a853 := 'Month (1-12) of the publication date, when given.';
  p_Type_4144a853 := 'Integer';
  p_AllowsNull_4144a853 := TRUE;
  p_IsPrimaryKey_4144a853 := FALSE;
  p_IsUniqueKey_4144a853 := FALSE;
  p_IsReadOnly_4144a853 := TRUE;
  p_IsRequired_4144a853 := FALSE;
  p_Sequence_4144a853 := 23;
  p_Status_4144a853 := 'Active';
  p_IsCustom_4144a853 := FALSE;
  p_MetadataSource_4144a853 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_4144a853, p_IntegrationObjectID := p_IntegrationObjectID_4144a853, p_Name := p_Name_4144a853, p_DisplayName := p_DisplayName_4144a853, p_Description := p_Description_4144a853, p_Category := p_Category_4144a853, p_Category_Clear := TRUE, p_Type := p_Type_4144a853, p_Length := p_Length_4144a853, p_Length_Clear := TRUE, p_Precision := p_Precision_4144a853, p_Precision_Clear := TRUE, p_Scale := p_Scale_4144a853, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_4144a853, p_DefaultValue := p_DefaultValue_4144a853, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_4144a853, p_IsUniqueKey := p_IsUniqueKey_4144a853, p_IsReadOnly := p_IsReadOnly_4144a853, p_IsRequired := p_IsRequired_4144a853, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_4144a853, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_4144a853, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_4144a853, p_Configuration := p_Configuration_4144a853, p_Configuration_Clear := TRUE, p_Status := p_Status_4144a853, p_IsCustom := p_IsCustom_4144a853, p_MetadataSource := p_MetadataSource_4144a853);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_a2c1513f UUID;
  p_IntegrationObjectID_a2c1513f UUID;
  p_Name_a2c1513f VARCHAR(255);
  p_DisplayName_a2c1513f VARCHAR(255);
  p_Description_a2c1513f TEXT;
  p_Category_a2c1513f VARCHAR(100);
  p_Type_a2c1513f VARCHAR(100);
  p_Length_a2c1513f INTEGER;
  p_Precision_a2c1513f INTEGER;
  p_Scale_a2c1513f INTEGER;
  p_AllowsNull_a2c1513f BOOLEAN;
  p_DefaultValue_a2c1513f VARCHAR(255);
  p_IsPrimaryKey_a2c1513f BOOLEAN;
  p_IsUniqueKey_a2c1513f BOOLEAN;
  p_IsReadOnly_a2c1513f BOOLEAN;
  p_IsRequired_a2c1513f BOOLEAN;
  p_RelatedIntegrationObjectID_a2c1513f UUID;
  p_RelatedIntegrationObjectFieldName_a2c1513f VARCHAR(255);
  p_Sequence_a2c1513f INTEGER;
  p_Configuration_a2c1513f TEXT;
  p_Status_a2c1513f VARCHAR(25);
  p_IsCustom_a2c1513f BOOLEAN;
  p_MetadataSource_a2c1513f VARCHAR(20);
BEGIN
  p_ID_a2c1513f := 'A0F30C05-D174-513C-8962-DA4E32BC8285';
  p_IntegrationObjectID_a2c1513f := '1D853840-A875-41E9-AB35-940345EF1434';
  p_Name_a2c1513f := 'publication-day';
  p_DisplayName_a2c1513f := 'Publication Day';
  p_Description_a2c1513f := 'Day of month of the publication date, when given.';
  p_Type_a2c1513f := 'Integer';
  p_AllowsNull_a2c1513f := TRUE;
  p_IsPrimaryKey_a2c1513f := FALSE;
  p_IsUniqueKey_a2c1513f := FALSE;
  p_IsReadOnly_a2c1513f := TRUE;
  p_IsRequired_a2c1513f := FALSE;
  p_Sequence_a2c1513f := 24;
  p_Status_a2c1513f := 'Active';
  p_IsCustom_a2c1513f := FALSE;
  p_MetadataSource_a2c1513f := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_a2c1513f, p_IntegrationObjectID := p_IntegrationObjectID_a2c1513f, p_Name := p_Name_a2c1513f, p_DisplayName := p_DisplayName_a2c1513f, p_Description := p_Description_a2c1513f, p_Category := p_Category_a2c1513f, p_Category_Clear := TRUE, p_Type := p_Type_a2c1513f, p_Length := p_Length_a2c1513f, p_Length_Clear := TRUE, p_Precision := p_Precision_a2c1513f, p_Precision_Clear := TRUE, p_Scale := p_Scale_a2c1513f, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_a2c1513f, p_DefaultValue := p_DefaultValue_a2c1513f, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_a2c1513f, p_IsUniqueKey := p_IsUniqueKey_a2c1513f, p_IsReadOnly := p_IsReadOnly_a2c1513f, p_IsRequired := p_IsRequired_a2c1513f, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_a2c1513f, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_a2c1513f, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_a2c1513f, p_Configuration := p_Configuration_a2c1513f, p_Configuration_Clear := TRUE, p_Status := p_Status_a2c1513f, p_IsCustom := p_IsCustom_a2c1513f, p_MetadataSource := p_MetadataSource_a2c1513f);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_2bc11c41 UUID;
  p_IntegrationObjectID_2bc11c41 UUID;
  p_Name_2bc11c41 VARCHAR(255);
  p_DisplayName_2bc11c41 VARCHAR(255);
  p_Description_2bc11c41 TEXT;
  p_Category_2bc11c41 VARCHAR(100);
  p_Type_2bc11c41 VARCHAR(100);
  p_Length_2bc11c41 INTEGER;
  p_Precision_2bc11c41 INTEGER;
  p_Scale_2bc11c41 INTEGER;
  p_AllowsNull_2bc11c41 BOOLEAN;
  p_DefaultValue_2bc11c41 VARCHAR(255);
  p_IsPrimaryKey_2bc11c41 BOOLEAN;
  p_IsUniqueKey_2bc11c41 BOOLEAN;
  p_IsReadOnly_2bc11c41 BOOLEAN;
  p_IsRequired_2bc11c41 BOOLEAN;
  p_RelatedIntegrationObjectID_2bc11c41 UUID;
  p_RelatedIntegrationObjectFieldName_2bc11c41 VARCHAR(255);
  p_Sequence_2bc11c41 INTEGER;
  p_Configuration_2bc11c41 TEXT;
  p_Status_2bc11c41 VARCHAR(25);
  p_IsCustom_2bc11c41 BOOLEAN;
  p_MetadataSource_2bc11c41 VARCHAR(20);
BEGIN
  p_ID_2bc11c41 := '1DA63CDC-78A2-5203-BE30-85BAA70FDAB9';
  p_IntegrationObjectID_2bc11c41 := '1D853840-A875-41E9-AB35-940345EF1434';
  p_Name_2bc11c41 := 'source-name';
  p_DisplayName_2bc11c41 := 'Source Name';
  p_Description_2bc11c41 := 'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.';
  p_Type_2bc11c41 := 'String';
  p_Length_2bc11c41 := 500;
  p_AllowsNull_2bc11c41 := TRUE;
  p_IsPrimaryKey_2bc11c41 := FALSE;
  p_IsUniqueKey_2bc11c41 := FALSE;
  p_IsReadOnly_2bc11c41 := TRUE;
  p_IsRequired_2bc11c41 := FALSE;
  p_Sequence_2bc11c41 := 25;
  p_Status_2bc11c41 := 'Active';
  p_IsCustom_2bc11c41 := FALSE;
  p_MetadataSource_2bc11c41 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_2bc11c41, p_IntegrationObjectID := p_IntegrationObjectID_2bc11c41, p_Name := p_Name_2bc11c41, p_DisplayName := p_DisplayName_2bc11c41, p_Description := p_Description_2bc11c41, p_Category := p_Category_2bc11c41, p_Category_Clear := TRUE, p_Type := p_Type_2bc11c41, p_Length := p_Length_2bc11c41, p_Precision := p_Precision_2bc11c41, p_Precision_Clear := TRUE, p_Scale := p_Scale_2bc11c41, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_2bc11c41, p_DefaultValue := p_DefaultValue_2bc11c41, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_2bc11c41, p_IsUniqueKey := p_IsUniqueKey_2bc11c41, p_IsReadOnly := p_IsReadOnly_2bc11c41, p_IsRequired := p_IsRequired_2bc11c41, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_2bc11c41, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_2bc11c41, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_2bc11c41, p_Configuration := p_Configuration_2bc11c41, p_Configuration_Clear := TRUE, p_Status := p_Status_2bc11c41, p_IsCustom := p_IsCustom_2bc11c41, p_MetadataSource := p_MetadataSource_2bc11c41);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_1b6e9612 UUID;
  p_IntegrationObjectID_1b6e9612 UUID;
  p_Name_1b6e9612 VARCHAR(255);
  p_DisplayName_1b6e9612 VARCHAR(255);
  p_Description_1b6e9612 TEXT;
  p_Category_1b6e9612 VARCHAR(100);
  p_Type_1b6e9612 VARCHAR(100);
  p_Length_1b6e9612 INTEGER;
  p_Precision_1b6e9612 INTEGER;
  p_Scale_1b6e9612 INTEGER;
  p_AllowsNull_1b6e9612 BOOLEAN;
  p_DefaultValue_1b6e9612 VARCHAR(255);
  p_IsPrimaryKey_1b6e9612 BOOLEAN;
  p_IsUniqueKey_1b6e9612 BOOLEAN;
  p_IsReadOnly_1b6e9612 BOOLEAN;
  p_IsRequired_1b6e9612 BOOLEAN;
  p_RelatedIntegrationObjectID_1b6e9612 UUID;
  p_RelatedIntegrationObjectFieldName_1b6e9612 VARCHAR(255);
  p_Sequence_1b6e9612 INTEGER;
  p_Configuration_1b6e9612 TEXT;
  p_Status_1b6e9612 VARCHAR(25);
  p_IsCustom_1b6e9612 BOOLEAN;
  p_MetadataSource_1b6e9612 VARCHAR(20);
BEGIN
  p_ID_1b6e9612 := '5AA4284D-D642-5C9A-B8E8-EBFFC76F5353';
  p_IntegrationObjectID_1b6e9612 := '1D853840-A875-41E9-AB35-940345EF1434';
  p_Name_1b6e9612 := 'source-orcid';
  p_DisplayName_1b6e9612 := 'Source Orcid';
  p_Description_1b6e9612 := 'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.';
  p_Type_1b6e9612 := 'String';
  p_Length_1b6e9612 := 19;
  p_AllowsNull_1b6e9612 := TRUE;
  p_IsPrimaryKey_1b6e9612 := FALSE;
  p_IsUniqueKey_1b6e9612 := FALSE;
  p_IsReadOnly_1b6e9612 := TRUE;
  p_IsRequired_1b6e9612 := FALSE;
  p_Sequence_1b6e9612 := 26;
  p_Status_1b6e9612 := 'Active';
  p_IsCustom_1b6e9612 := FALSE;
  p_MetadataSource_1b6e9612 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_1b6e9612, p_IntegrationObjectID := p_IntegrationObjectID_1b6e9612, p_Name := p_Name_1b6e9612, p_DisplayName := p_DisplayName_1b6e9612, p_Description := p_Description_1b6e9612, p_Category := p_Category_1b6e9612, p_Category_Clear := TRUE, p_Type := p_Type_1b6e9612, p_Length := p_Length_1b6e9612, p_Precision := p_Precision_1b6e9612, p_Precision_Clear := TRUE, p_Scale := p_Scale_1b6e9612, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_1b6e9612, p_DefaultValue := p_DefaultValue_1b6e9612, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_1b6e9612, p_IsUniqueKey := p_IsUniqueKey_1b6e9612, p_IsReadOnly := p_IsReadOnly_1b6e9612, p_IsRequired := p_IsRequired_1b6e9612, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_1b6e9612, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_1b6e9612, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_1b6e9612, p_Configuration := p_Configuration_1b6e9612, p_Configuration_Clear := TRUE, p_Status := p_Status_1b6e9612, p_IsCustom := p_IsCustom_1b6e9612, p_MetadataSource := p_MetadataSource_1b6e9612);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_981a15ed UUID;
  p_IntegrationObjectID_981a15ed UUID;
  p_Name_981a15ed VARCHAR(255);
  p_DisplayName_981a15ed VARCHAR(255);
  p_Description_981a15ed TEXT;
  p_Category_981a15ed VARCHAR(100);
  p_Type_981a15ed VARCHAR(100);
  p_Length_981a15ed INTEGER;
  p_Precision_981a15ed INTEGER;
  p_Scale_981a15ed INTEGER;
  p_AllowsNull_981a15ed BOOLEAN;
  p_DefaultValue_981a15ed VARCHAR(255);
  p_IsPrimaryKey_981a15ed BOOLEAN;
  p_IsUniqueKey_981a15ed BOOLEAN;
  p_IsReadOnly_981a15ed BOOLEAN;
  p_IsRequired_981a15ed BOOLEAN;
  p_RelatedIntegrationObjectID_981a15ed UUID;
  p_RelatedIntegrationObjectFieldName_981a15ed VARCHAR(255);
  p_Sequence_981a15ed INTEGER;
  p_Configuration_981a15ed TEXT;
  p_Status_981a15ed VARCHAR(25);
  p_IsCustom_981a15ed BOOLEAN;
  p_MetadataSource_981a15ed VARCHAR(20);
BEGIN
  p_ID_981a15ed := '5CA9A20B-EC7B-52EF-A582-C8303250338C';
  p_IntegrationObjectID_981a15ed := '5F90FE9B-3498-4DC2-A188-6173B8EA842B';
  p_Name_981a15ed := 'start-year';
  p_DisplayName_981a15ed := 'Start Year';
  p_Description_981a15ed := 'Year of the affiliation start date; ORCID dates are partial, so month/day may be absent.';
  p_Type_981a15ed := 'Integer';
  p_AllowsNull_981a15ed := TRUE;
  p_IsPrimaryKey_981a15ed := FALSE;
  p_IsUniqueKey_981a15ed := FALSE;
  p_IsReadOnly_981a15ed := TRUE;
  p_IsRequired_981a15ed := FALSE;
  p_Sequence_981a15ed := 15;
  p_Status_981a15ed := 'Active';
  p_IsCustom_981a15ed := FALSE;
  p_MetadataSource_981a15ed := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_981a15ed, p_IntegrationObjectID := p_IntegrationObjectID_981a15ed, p_Name := p_Name_981a15ed, p_DisplayName := p_DisplayName_981a15ed, p_Description := p_Description_981a15ed, p_Category := p_Category_981a15ed, p_Category_Clear := TRUE, p_Type := p_Type_981a15ed, p_Length := p_Length_981a15ed, p_Length_Clear := TRUE, p_Precision := p_Precision_981a15ed, p_Precision_Clear := TRUE, p_Scale := p_Scale_981a15ed, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_981a15ed, p_DefaultValue := p_DefaultValue_981a15ed, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_981a15ed, p_IsUniqueKey := p_IsUniqueKey_981a15ed, p_IsReadOnly := p_IsReadOnly_981a15ed, p_IsRequired := p_IsRequired_981a15ed, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_981a15ed, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_981a15ed, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_981a15ed, p_Configuration := p_Configuration_981a15ed, p_Configuration_Clear := TRUE, p_Status := p_Status_981a15ed, p_IsCustom := p_IsCustom_981a15ed, p_MetadataSource := p_MetadataSource_981a15ed);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_7c282a92 UUID;
  p_IntegrationObjectID_7c282a92 UUID;
  p_Name_7c282a92 VARCHAR(255);
  p_DisplayName_7c282a92 VARCHAR(255);
  p_Description_7c282a92 TEXT;
  p_Category_7c282a92 VARCHAR(100);
  p_Type_7c282a92 VARCHAR(100);
  p_Length_7c282a92 INTEGER;
  p_Precision_7c282a92 INTEGER;
  p_Scale_7c282a92 INTEGER;
  p_AllowsNull_7c282a92 BOOLEAN;
  p_DefaultValue_7c282a92 VARCHAR(255);
  p_IsPrimaryKey_7c282a92 BOOLEAN;
  p_IsUniqueKey_7c282a92 BOOLEAN;
  p_IsReadOnly_7c282a92 BOOLEAN;
  p_IsRequired_7c282a92 BOOLEAN;
  p_RelatedIntegrationObjectID_7c282a92 UUID;
  p_RelatedIntegrationObjectFieldName_7c282a92 VARCHAR(255);
  p_Sequence_7c282a92 INTEGER;
  p_Configuration_7c282a92 TEXT;
  p_Status_7c282a92 VARCHAR(25);
  p_IsCustom_7c282a92 BOOLEAN;
  p_MetadataSource_7c282a92 VARCHAR(20);
BEGIN
  p_ID_7c282a92 := '9D3F5A9B-5AD3-5824-AFAA-6676ABF9AB10';
  p_IntegrationObjectID_7c282a92 := '5F90FE9B-3498-4DC2-A188-6173B8EA842B';
  p_Name_7c282a92 := 'start-month';
  p_DisplayName_7c282a92 := 'Start Month';
  p_Description_7c282a92 := 'Month (1-12) of the affiliation start date, when given.';
  p_Type_7c282a92 := 'Integer';
  p_AllowsNull_7c282a92 := TRUE;
  p_IsPrimaryKey_7c282a92 := FALSE;
  p_IsUniqueKey_7c282a92 := FALSE;
  p_IsReadOnly_7c282a92 := TRUE;
  p_IsRequired_7c282a92 := FALSE;
  p_Sequence_7c282a92 := 16;
  p_Status_7c282a92 := 'Active';
  p_IsCustom_7c282a92 := FALSE;
  p_MetadataSource_7c282a92 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_7c282a92, p_IntegrationObjectID := p_IntegrationObjectID_7c282a92, p_Name := p_Name_7c282a92, p_DisplayName := p_DisplayName_7c282a92, p_Description := p_Description_7c282a92, p_Category := p_Category_7c282a92, p_Category_Clear := TRUE, p_Type := p_Type_7c282a92, p_Length := p_Length_7c282a92, p_Length_Clear := TRUE, p_Precision := p_Precision_7c282a92, p_Precision_Clear := TRUE, p_Scale := p_Scale_7c282a92, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_7c282a92, p_DefaultValue := p_DefaultValue_7c282a92, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_7c282a92, p_IsUniqueKey := p_IsUniqueKey_7c282a92, p_IsReadOnly := p_IsReadOnly_7c282a92, p_IsRequired := p_IsRequired_7c282a92, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_7c282a92, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_7c282a92, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_7c282a92, p_Configuration := p_Configuration_7c282a92, p_Configuration_Clear := TRUE, p_Status := p_Status_7c282a92, p_IsCustom := p_IsCustom_7c282a92, p_MetadataSource := p_MetadataSource_7c282a92);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_42dcb68c UUID;
  p_IntegrationObjectID_42dcb68c UUID;
  p_Name_42dcb68c VARCHAR(255);
  p_DisplayName_42dcb68c VARCHAR(255);
  p_Description_42dcb68c TEXT;
  p_Category_42dcb68c VARCHAR(100);
  p_Type_42dcb68c VARCHAR(100);
  p_Length_42dcb68c INTEGER;
  p_Precision_42dcb68c INTEGER;
  p_Scale_42dcb68c INTEGER;
  p_AllowsNull_42dcb68c BOOLEAN;
  p_DefaultValue_42dcb68c VARCHAR(255);
  p_IsPrimaryKey_42dcb68c BOOLEAN;
  p_IsUniqueKey_42dcb68c BOOLEAN;
  p_IsReadOnly_42dcb68c BOOLEAN;
  p_IsRequired_42dcb68c BOOLEAN;
  p_RelatedIntegrationObjectID_42dcb68c UUID;
  p_RelatedIntegrationObjectFieldName_42dcb68c VARCHAR(255);
  p_Sequence_42dcb68c INTEGER;
  p_Configuration_42dcb68c TEXT;
  p_Status_42dcb68c VARCHAR(25);
  p_IsCustom_42dcb68c BOOLEAN;
  p_MetadataSource_42dcb68c VARCHAR(20);
BEGIN
  p_ID_42dcb68c := '220B6AE6-1526-5083-A650-7F6DB6FE819A';
  p_IntegrationObjectID_42dcb68c := '5F90FE9B-3498-4DC2-A188-6173B8EA842B';
  p_Name_42dcb68c := 'start-day';
  p_DisplayName_42dcb68c := 'Start Day';
  p_Description_42dcb68c := 'Day of month of the affiliation start date, when given.';
  p_Type_42dcb68c := 'Integer';
  p_AllowsNull_42dcb68c := TRUE;
  p_IsPrimaryKey_42dcb68c := FALSE;
  p_IsUniqueKey_42dcb68c := FALSE;
  p_IsReadOnly_42dcb68c := TRUE;
  p_IsRequired_42dcb68c := FALSE;
  p_Sequence_42dcb68c := 17;
  p_Status_42dcb68c := 'Active';
  p_IsCustom_42dcb68c := FALSE;
  p_MetadataSource_42dcb68c := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_42dcb68c, p_IntegrationObjectID := p_IntegrationObjectID_42dcb68c, p_Name := p_Name_42dcb68c, p_DisplayName := p_DisplayName_42dcb68c, p_Description := p_Description_42dcb68c, p_Category := p_Category_42dcb68c, p_Category_Clear := TRUE, p_Type := p_Type_42dcb68c, p_Length := p_Length_42dcb68c, p_Length_Clear := TRUE, p_Precision := p_Precision_42dcb68c, p_Precision_Clear := TRUE, p_Scale := p_Scale_42dcb68c, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_42dcb68c, p_DefaultValue := p_DefaultValue_42dcb68c, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_42dcb68c, p_IsUniqueKey := p_IsUniqueKey_42dcb68c, p_IsReadOnly := p_IsReadOnly_42dcb68c, p_IsRequired := p_IsRequired_42dcb68c, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_42dcb68c, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_42dcb68c, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_42dcb68c, p_Configuration := p_Configuration_42dcb68c, p_Configuration_Clear := TRUE, p_Status := p_Status_42dcb68c, p_IsCustom := p_IsCustom_42dcb68c, p_MetadataSource := p_MetadataSource_42dcb68c);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_03986e41 UUID;
  p_IntegrationObjectID_03986e41 UUID;
  p_Name_03986e41 VARCHAR(255);
  p_DisplayName_03986e41 VARCHAR(255);
  p_Description_03986e41 TEXT;
  p_Category_03986e41 VARCHAR(100);
  p_Type_03986e41 VARCHAR(100);
  p_Length_03986e41 INTEGER;
  p_Precision_03986e41 INTEGER;
  p_Scale_03986e41 INTEGER;
  p_AllowsNull_03986e41 BOOLEAN;
  p_DefaultValue_03986e41 VARCHAR(255);
  p_IsPrimaryKey_03986e41 BOOLEAN;
  p_IsUniqueKey_03986e41 BOOLEAN;
  p_IsReadOnly_03986e41 BOOLEAN;
  p_IsRequired_03986e41 BOOLEAN;
  p_RelatedIntegrationObjectID_03986e41 UUID;
  p_RelatedIntegrationObjectFieldName_03986e41 VARCHAR(255);
  p_Sequence_03986e41 INTEGER;
  p_Configuration_03986e41 TEXT;
  p_Status_03986e41 VARCHAR(25);
  p_IsCustom_03986e41 BOOLEAN;
  p_MetadataSource_03986e41 VARCHAR(20);
BEGIN
  p_ID_03986e41 := 'B2C593F4-630B-5886-BEC9-C14FCDE604D3';
  p_IntegrationObjectID_03986e41 := '5F90FE9B-3498-4DC2-A188-6173B8EA842B';
  p_Name_03986e41 := 'end-year';
  p_DisplayName_03986e41 := 'End Year';
  p_Description_03986e41 := 'Year of the affiliation end date; empty for a current/ongoing role; ORCID dates are partial, so month/day may be absent.';
  p_Type_03986e41 := 'Integer';
  p_AllowsNull_03986e41 := TRUE;
  p_IsPrimaryKey_03986e41 := FALSE;
  p_IsUniqueKey_03986e41 := FALSE;
  p_IsReadOnly_03986e41 := TRUE;
  p_IsRequired_03986e41 := FALSE;
  p_Sequence_03986e41 := 18;
  p_Status_03986e41 := 'Active';
  p_IsCustom_03986e41 := FALSE;
  p_MetadataSource_03986e41 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_03986e41, p_IntegrationObjectID := p_IntegrationObjectID_03986e41, p_Name := p_Name_03986e41, p_DisplayName := p_DisplayName_03986e41, p_Description := p_Description_03986e41, p_Category := p_Category_03986e41, p_Category_Clear := TRUE, p_Type := p_Type_03986e41, p_Length := p_Length_03986e41, p_Length_Clear := TRUE, p_Precision := p_Precision_03986e41, p_Precision_Clear := TRUE, p_Scale := p_Scale_03986e41, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_03986e41, p_DefaultValue := p_DefaultValue_03986e41, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_03986e41, p_IsUniqueKey := p_IsUniqueKey_03986e41, p_IsReadOnly := p_IsReadOnly_03986e41, p_IsRequired := p_IsRequired_03986e41, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_03986e41, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_03986e41, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_03986e41, p_Configuration := p_Configuration_03986e41, p_Configuration_Clear := TRUE, p_Status := p_Status_03986e41, p_IsCustom := p_IsCustom_03986e41, p_MetadataSource := p_MetadataSource_03986e41);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_bfd5380c UUID;
  p_IntegrationObjectID_bfd5380c UUID;
  p_Name_bfd5380c VARCHAR(255);
  p_DisplayName_bfd5380c VARCHAR(255);
  p_Description_bfd5380c TEXT;
  p_Category_bfd5380c VARCHAR(100);
  p_Type_bfd5380c VARCHAR(100);
  p_Length_bfd5380c INTEGER;
  p_Precision_bfd5380c INTEGER;
  p_Scale_bfd5380c INTEGER;
  p_AllowsNull_bfd5380c BOOLEAN;
  p_DefaultValue_bfd5380c VARCHAR(255);
  p_IsPrimaryKey_bfd5380c BOOLEAN;
  p_IsUniqueKey_bfd5380c BOOLEAN;
  p_IsReadOnly_bfd5380c BOOLEAN;
  p_IsRequired_bfd5380c BOOLEAN;
  p_RelatedIntegrationObjectID_bfd5380c UUID;
  p_RelatedIntegrationObjectFieldName_bfd5380c VARCHAR(255);
  p_Sequence_bfd5380c INTEGER;
  p_Configuration_bfd5380c TEXT;
  p_Status_bfd5380c VARCHAR(25);
  p_IsCustom_bfd5380c BOOLEAN;
  p_MetadataSource_bfd5380c VARCHAR(20);
BEGIN
  p_ID_bfd5380c := '0D4BEE76-39F9-5E66-A4D4-43FD04B81735';
  p_IntegrationObjectID_bfd5380c := '5F90FE9B-3498-4DC2-A188-6173B8EA842B';
  p_Name_bfd5380c := 'end-month';
  p_DisplayName_bfd5380c := 'End Month';
  p_Description_bfd5380c := 'Month (1-12) of the affiliation end date; empty for a current/ongoing role, when given.';
  p_Type_bfd5380c := 'Integer';
  p_AllowsNull_bfd5380c := TRUE;
  p_IsPrimaryKey_bfd5380c := FALSE;
  p_IsUniqueKey_bfd5380c := FALSE;
  p_IsReadOnly_bfd5380c := TRUE;
  p_IsRequired_bfd5380c := FALSE;
  p_Sequence_bfd5380c := 19;
  p_Status_bfd5380c := 'Active';
  p_IsCustom_bfd5380c := FALSE;
  p_MetadataSource_bfd5380c := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_bfd5380c, p_IntegrationObjectID := p_IntegrationObjectID_bfd5380c, p_Name := p_Name_bfd5380c, p_DisplayName := p_DisplayName_bfd5380c, p_Description := p_Description_bfd5380c, p_Category := p_Category_bfd5380c, p_Category_Clear := TRUE, p_Type := p_Type_bfd5380c, p_Length := p_Length_bfd5380c, p_Length_Clear := TRUE, p_Precision := p_Precision_bfd5380c, p_Precision_Clear := TRUE, p_Scale := p_Scale_bfd5380c, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_bfd5380c, p_DefaultValue := p_DefaultValue_bfd5380c, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_bfd5380c, p_IsUniqueKey := p_IsUniqueKey_bfd5380c, p_IsReadOnly := p_IsReadOnly_bfd5380c, p_IsRequired := p_IsRequired_bfd5380c, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_bfd5380c, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_bfd5380c, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_bfd5380c, p_Configuration := p_Configuration_bfd5380c, p_Configuration_Clear := TRUE, p_Status := p_Status_bfd5380c, p_IsCustom := p_IsCustom_bfd5380c, p_MetadataSource := p_MetadataSource_bfd5380c);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_d4a27558 UUID;
  p_IntegrationObjectID_d4a27558 UUID;
  p_Name_d4a27558 VARCHAR(255);
  p_DisplayName_d4a27558 VARCHAR(255);
  p_Description_d4a27558 TEXT;
  p_Category_d4a27558 VARCHAR(100);
  p_Type_d4a27558 VARCHAR(100);
  p_Length_d4a27558 INTEGER;
  p_Precision_d4a27558 INTEGER;
  p_Scale_d4a27558 INTEGER;
  p_AllowsNull_d4a27558 BOOLEAN;
  p_DefaultValue_d4a27558 VARCHAR(255);
  p_IsPrimaryKey_d4a27558 BOOLEAN;
  p_IsUniqueKey_d4a27558 BOOLEAN;
  p_IsReadOnly_d4a27558 BOOLEAN;
  p_IsRequired_d4a27558 BOOLEAN;
  p_RelatedIntegrationObjectID_d4a27558 UUID;
  p_RelatedIntegrationObjectFieldName_d4a27558 VARCHAR(255);
  p_Sequence_d4a27558 INTEGER;
  p_Configuration_d4a27558 TEXT;
  p_Status_d4a27558 VARCHAR(25);
  p_IsCustom_d4a27558 BOOLEAN;
  p_MetadataSource_d4a27558 VARCHAR(20);
BEGIN
  p_ID_d4a27558 := '865F1EFA-AB27-5628-9E43-0AE3267C61F0';
  p_IntegrationObjectID_d4a27558 := '5F90FE9B-3498-4DC2-A188-6173B8EA842B';
  p_Name_d4a27558 := 'end-day';
  p_DisplayName_d4a27558 := 'End Day';
  p_Description_d4a27558 := 'Day of month of the affiliation end date; empty for a current/ongoing role, when given.';
  p_Type_d4a27558 := 'Integer';
  p_AllowsNull_d4a27558 := TRUE;
  p_IsPrimaryKey_d4a27558 := FALSE;
  p_IsUniqueKey_d4a27558 := FALSE;
  p_IsReadOnly_d4a27558 := TRUE;
  p_IsRequired_d4a27558 := FALSE;
  p_Sequence_d4a27558 := 20;
  p_Status_d4a27558 := 'Active';
  p_IsCustom_d4a27558 := FALSE;
  p_MetadataSource_d4a27558 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_d4a27558, p_IntegrationObjectID := p_IntegrationObjectID_d4a27558, p_Name := p_Name_d4a27558, p_DisplayName := p_DisplayName_d4a27558, p_Description := p_Description_d4a27558, p_Category := p_Category_d4a27558, p_Category_Clear := TRUE, p_Type := p_Type_d4a27558, p_Length := p_Length_d4a27558, p_Length_Clear := TRUE, p_Precision := p_Precision_d4a27558, p_Precision_Clear := TRUE, p_Scale := p_Scale_d4a27558, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_d4a27558, p_DefaultValue := p_DefaultValue_d4a27558, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_d4a27558, p_IsUniqueKey := p_IsUniqueKey_d4a27558, p_IsReadOnly := p_IsReadOnly_d4a27558, p_IsRequired := p_IsRequired_d4a27558, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_d4a27558, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_d4a27558, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_d4a27558, p_Configuration := p_Configuration_d4a27558, p_Configuration_Clear := TRUE, p_Status := p_Status_d4a27558, p_IsCustom := p_IsCustom_d4a27558, p_MetadataSource := p_MetadataSource_d4a27558);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_f608b136 UUID;
  p_IntegrationObjectID_f608b136 UUID;
  p_Name_f608b136 VARCHAR(255);
  p_DisplayName_f608b136 VARCHAR(255);
  p_Description_f608b136 TEXT;
  p_Category_f608b136 VARCHAR(100);
  p_Type_f608b136 VARCHAR(100);
  p_Length_f608b136 INTEGER;
  p_Precision_f608b136 INTEGER;
  p_Scale_f608b136 INTEGER;
  p_AllowsNull_f608b136 BOOLEAN;
  p_DefaultValue_f608b136 VARCHAR(255);
  p_IsPrimaryKey_f608b136 BOOLEAN;
  p_IsUniqueKey_f608b136 BOOLEAN;
  p_IsReadOnly_f608b136 BOOLEAN;
  p_IsRequired_f608b136 BOOLEAN;
  p_RelatedIntegrationObjectID_f608b136 UUID;
  p_RelatedIntegrationObjectFieldName_f608b136 VARCHAR(255);
  p_Sequence_f608b136 INTEGER;
  p_Configuration_f608b136 TEXT;
  p_Status_f608b136 VARCHAR(25);
  p_IsCustom_f608b136 BOOLEAN;
  p_MetadataSource_f608b136 VARCHAR(20);
BEGIN
  p_ID_f608b136 := 'AF0EFA16-B004-5843-9A8C-7CE0D73802E3';
  p_IntegrationObjectID_f608b136 := '5F90FE9B-3498-4DC2-A188-6173B8EA842B';
  p_Name_f608b136 := 'organization-name';
  p_DisplayName_f608b136 := 'Organization Name';
  p_Description_f608b136 := 'Name of the organization. Lifted from organization.name.';
  p_Type_f608b136 := 'String';
  p_Length_f608b136 := 1000;
  p_AllowsNull_f608b136 := TRUE;
  p_IsPrimaryKey_f608b136 := FALSE;
  p_IsUniqueKey_f608b136 := FALSE;
  p_IsReadOnly_f608b136 := TRUE;
  p_IsRequired_f608b136 := FALSE;
  p_Sequence_f608b136 := 21;
  p_Status_f608b136 := 'Active';
  p_IsCustom_f608b136 := FALSE;
  p_MetadataSource_f608b136 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_f608b136, p_IntegrationObjectID := p_IntegrationObjectID_f608b136, p_Name := p_Name_f608b136, p_DisplayName := p_DisplayName_f608b136, p_Description := p_Description_f608b136, p_Category := p_Category_f608b136, p_Category_Clear := TRUE, p_Type := p_Type_f608b136, p_Length := p_Length_f608b136, p_Precision := p_Precision_f608b136, p_Precision_Clear := TRUE, p_Scale := p_Scale_f608b136, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_f608b136, p_DefaultValue := p_DefaultValue_f608b136, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_f608b136, p_IsUniqueKey := p_IsUniqueKey_f608b136, p_IsReadOnly := p_IsReadOnly_f608b136, p_IsRequired := p_IsRequired_f608b136, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_f608b136, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_f608b136, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_f608b136, p_Configuration := p_Configuration_f608b136, p_Configuration_Clear := TRUE, p_Status := p_Status_f608b136, p_IsCustom := p_IsCustom_f608b136, p_MetadataSource := p_MetadataSource_f608b136);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_e04cfa4d UUID;
  p_IntegrationObjectID_e04cfa4d UUID;
  p_Name_e04cfa4d VARCHAR(255);
  p_DisplayName_e04cfa4d VARCHAR(255);
  p_Description_e04cfa4d TEXT;
  p_Category_e04cfa4d VARCHAR(100);
  p_Type_e04cfa4d VARCHAR(100);
  p_Length_e04cfa4d INTEGER;
  p_Precision_e04cfa4d INTEGER;
  p_Scale_e04cfa4d INTEGER;
  p_AllowsNull_e04cfa4d BOOLEAN;
  p_DefaultValue_e04cfa4d VARCHAR(255);
  p_IsPrimaryKey_e04cfa4d BOOLEAN;
  p_IsUniqueKey_e04cfa4d BOOLEAN;
  p_IsReadOnly_e04cfa4d BOOLEAN;
  p_IsRequired_e04cfa4d BOOLEAN;
  p_RelatedIntegrationObjectID_e04cfa4d UUID;
  p_RelatedIntegrationObjectFieldName_e04cfa4d VARCHAR(255);
  p_Sequence_e04cfa4d INTEGER;
  p_Configuration_e04cfa4d TEXT;
  p_Status_e04cfa4d VARCHAR(25);
  p_IsCustom_e04cfa4d BOOLEAN;
  p_MetadataSource_e04cfa4d VARCHAR(20);
BEGIN
  p_ID_e04cfa4d := 'BE1C90DB-1CF3-53A2-AD1F-7050FA6B8E78';
  p_IntegrationObjectID_e04cfa4d := '5F90FE9B-3498-4DC2-A188-6173B8EA842B';
  p_Name_e04cfa4d := 'organization-city';
  p_DisplayName_e04cfa4d := 'Organization City';
  p_Description_e04cfa4d := 'City of the organization. Lifted from organization.address.city.';
  p_Type_e04cfa4d := 'String';
  p_Length_e04cfa4d := 255;
  p_AllowsNull_e04cfa4d := TRUE;
  p_IsPrimaryKey_e04cfa4d := FALSE;
  p_IsUniqueKey_e04cfa4d := FALSE;
  p_IsReadOnly_e04cfa4d := TRUE;
  p_IsRequired_e04cfa4d := FALSE;
  p_Sequence_e04cfa4d := 22;
  p_Status_e04cfa4d := 'Active';
  p_IsCustom_e04cfa4d := FALSE;
  p_MetadataSource_e04cfa4d := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_e04cfa4d, p_IntegrationObjectID := p_IntegrationObjectID_e04cfa4d, p_Name := p_Name_e04cfa4d, p_DisplayName := p_DisplayName_e04cfa4d, p_Description := p_Description_e04cfa4d, p_Category := p_Category_e04cfa4d, p_Category_Clear := TRUE, p_Type := p_Type_e04cfa4d, p_Length := p_Length_e04cfa4d, p_Precision := p_Precision_e04cfa4d, p_Precision_Clear := TRUE, p_Scale := p_Scale_e04cfa4d, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_e04cfa4d, p_DefaultValue := p_DefaultValue_e04cfa4d, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_e04cfa4d, p_IsUniqueKey := p_IsUniqueKey_e04cfa4d, p_IsReadOnly := p_IsReadOnly_e04cfa4d, p_IsRequired := p_IsRequired_e04cfa4d, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_e04cfa4d, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_e04cfa4d, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_e04cfa4d, p_Configuration := p_Configuration_e04cfa4d, p_Configuration_Clear := TRUE, p_Status := p_Status_e04cfa4d, p_IsCustom := p_IsCustom_e04cfa4d, p_MetadataSource := p_MetadataSource_e04cfa4d);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_d928aff5 UUID;
  p_IntegrationObjectID_d928aff5 UUID;
  p_Name_d928aff5 VARCHAR(255);
  p_DisplayName_d928aff5 VARCHAR(255);
  p_Description_d928aff5 TEXT;
  p_Category_d928aff5 VARCHAR(100);
  p_Type_d928aff5 VARCHAR(100);
  p_Length_d928aff5 INTEGER;
  p_Precision_d928aff5 INTEGER;
  p_Scale_d928aff5 INTEGER;
  p_AllowsNull_d928aff5 BOOLEAN;
  p_DefaultValue_d928aff5 VARCHAR(255);
  p_IsPrimaryKey_d928aff5 BOOLEAN;
  p_IsUniqueKey_d928aff5 BOOLEAN;
  p_IsReadOnly_d928aff5 BOOLEAN;
  p_IsRequired_d928aff5 BOOLEAN;
  p_RelatedIntegrationObjectID_d928aff5 UUID;
  p_RelatedIntegrationObjectFieldName_d928aff5 VARCHAR(255);
  p_Sequence_d928aff5 INTEGER;
  p_Configuration_d928aff5 TEXT;
  p_Status_d928aff5 VARCHAR(25);
  p_IsCustom_d928aff5 BOOLEAN;
  p_MetadataSource_d928aff5 VARCHAR(20);
BEGIN
  p_ID_d928aff5 := '43208C62-3466-59D7-996C-237B9FAC47DE';
  p_IntegrationObjectID_d928aff5 := '5F90FE9B-3498-4DC2-A188-6173B8EA842B';
  p_Name_d928aff5 := 'organization-region';
  p_DisplayName_d928aff5 := 'Organization Region';
  p_Description_d928aff5 := 'Region/state of the organization. Lifted from organization.address.region.';
  p_Type_d928aff5 := 'String';
  p_Length_d928aff5 := 255;
  p_AllowsNull_d928aff5 := TRUE;
  p_IsPrimaryKey_d928aff5 := FALSE;
  p_IsUniqueKey_d928aff5 := FALSE;
  p_IsReadOnly_d928aff5 := TRUE;
  p_IsRequired_d928aff5 := FALSE;
  p_Sequence_d928aff5 := 23;
  p_Status_d928aff5 := 'Active';
  p_IsCustom_d928aff5 := FALSE;
  p_MetadataSource_d928aff5 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_d928aff5, p_IntegrationObjectID := p_IntegrationObjectID_d928aff5, p_Name := p_Name_d928aff5, p_DisplayName := p_DisplayName_d928aff5, p_Description := p_Description_d928aff5, p_Category := p_Category_d928aff5, p_Category_Clear := TRUE, p_Type := p_Type_d928aff5, p_Length := p_Length_d928aff5, p_Precision := p_Precision_d928aff5, p_Precision_Clear := TRUE, p_Scale := p_Scale_d928aff5, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_d928aff5, p_DefaultValue := p_DefaultValue_d928aff5, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_d928aff5, p_IsUniqueKey := p_IsUniqueKey_d928aff5, p_IsReadOnly := p_IsReadOnly_d928aff5, p_IsRequired := p_IsRequired_d928aff5, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_d928aff5, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_d928aff5, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_d928aff5, p_Configuration := p_Configuration_d928aff5, p_Configuration_Clear := TRUE, p_Status := p_Status_d928aff5, p_IsCustom := p_IsCustom_d928aff5, p_MetadataSource := p_MetadataSource_d928aff5);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_eea78aa1 UUID;
  p_IntegrationObjectID_eea78aa1 UUID;
  p_Name_eea78aa1 VARCHAR(255);
  p_DisplayName_eea78aa1 VARCHAR(255);
  p_Description_eea78aa1 TEXT;
  p_Category_eea78aa1 VARCHAR(100);
  p_Type_eea78aa1 VARCHAR(100);
  p_Length_eea78aa1 INTEGER;
  p_Precision_eea78aa1 INTEGER;
  p_Scale_eea78aa1 INTEGER;
  p_AllowsNull_eea78aa1 BOOLEAN;
  p_DefaultValue_eea78aa1 VARCHAR(255);
  p_IsPrimaryKey_eea78aa1 BOOLEAN;
  p_IsUniqueKey_eea78aa1 BOOLEAN;
  p_IsReadOnly_eea78aa1 BOOLEAN;
  p_IsRequired_eea78aa1 BOOLEAN;
  p_RelatedIntegrationObjectID_eea78aa1 UUID;
  p_RelatedIntegrationObjectFieldName_eea78aa1 VARCHAR(255);
  p_Sequence_eea78aa1 INTEGER;
  p_Configuration_eea78aa1 TEXT;
  p_Status_eea78aa1 VARCHAR(25);
  p_IsCustom_eea78aa1 BOOLEAN;
  p_MetadataSource_eea78aa1 VARCHAR(20);
BEGIN
  p_ID_eea78aa1 := 'ACDB4C8D-0B31-5556-9092-C92AEF24EF90';
  p_IntegrationObjectID_eea78aa1 := '5F90FE9B-3498-4DC2-A188-6173B8EA842B';
  p_Name_eea78aa1 := 'organization-country';
  p_DisplayName_eea78aa1 := 'Organization Country';
  p_Description_eea78aa1 := 'ISO country code of the organization. Lifted from organization.address.country.';
  p_Type_eea78aa1 := 'String';
  p_Length_eea78aa1 := 50;
  p_AllowsNull_eea78aa1 := TRUE;
  p_IsPrimaryKey_eea78aa1 := FALSE;
  p_IsUniqueKey_eea78aa1 := FALSE;
  p_IsReadOnly_eea78aa1 := TRUE;
  p_IsRequired_eea78aa1 := FALSE;
  p_Sequence_eea78aa1 := 24;
  p_Status_eea78aa1 := 'Active';
  p_IsCustom_eea78aa1 := FALSE;
  p_MetadataSource_eea78aa1 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_eea78aa1, p_IntegrationObjectID := p_IntegrationObjectID_eea78aa1, p_Name := p_Name_eea78aa1, p_DisplayName := p_DisplayName_eea78aa1, p_Description := p_Description_eea78aa1, p_Category := p_Category_eea78aa1, p_Category_Clear := TRUE, p_Type := p_Type_eea78aa1, p_Length := p_Length_eea78aa1, p_Precision := p_Precision_eea78aa1, p_Precision_Clear := TRUE, p_Scale := p_Scale_eea78aa1, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_eea78aa1, p_DefaultValue := p_DefaultValue_eea78aa1, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_eea78aa1, p_IsUniqueKey := p_IsUniqueKey_eea78aa1, p_IsReadOnly := p_IsReadOnly_eea78aa1, p_IsRequired := p_IsRequired_eea78aa1, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_eea78aa1, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_eea78aa1, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_eea78aa1, p_Configuration := p_Configuration_eea78aa1, p_Configuration_Clear := TRUE, p_Status := p_Status_eea78aa1, p_IsCustom := p_IsCustom_eea78aa1, p_MetadataSource := p_MetadataSource_eea78aa1);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_927bf38a UUID;
  p_IntegrationObjectID_927bf38a UUID;
  p_Name_927bf38a VARCHAR(255);
  p_DisplayName_927bf38a VARCHAR(255);
  p_Description_927bf38a TEXT;
  p_Category_927bf38a VARCHAR(100);
  p_Type_927bf38a VARCHAR(100);
  p_Length_927bf38a INTEGER;
  p_Precision_927bf38a INTEGER;
  p_Scale_927bf38a INTEGER;
  p_AllowsNull_927bf38a BOOLEAN;
  p_DefaultValue_927bf38a VARCHAR(255);
  p_IsPrimaryKey_927bf38a BOOLEAN;
  p_IsUniqueKey_927bf38a BOOLEAN;
  p_IsReadOnly_927bf38a BOOLEAN;
  p_IsRequired_927bf38a BOOLEAN;
  p_RelatedIntegrationObjectID_927bf38a UUID;
  p_RelatedIntegrationObjectFieldName_927bf38a VARCHAR(255);
  p_Sequence_927bf38a INTEGER;
  p_Configuration_927bf38a TEXT;
  p_Status_927bf38a VARCHAR(25);
  p_IsCustom_927bf38a BOOLEAN;
  p_MetadataSource_927bf38a VARCHAR(20);
BEGIN
  p_ID_927bf38a := 'EBA1B12F-BBED-5F44-B6CD-421E0BF8254A';
  p_IntegrationObjectID_927bf38a := '5F90FE9B-3498-4DC2-A188-6173B8EA842B';
  p_Name_927bf38a := 'organization-disambiguated-id';
  p_DisplayName_927bf38a := 'Organization Disambiguated Id';
  p_Description_927bf38a := 'Canonical identifier of the organization in the disambiguation source (e.g. a RINGGOLD or ROR id), so the same institution matches across records.';
  p_Type_927bf38a := 'String';
  p_Length_927bf38a := 255;
  p_AllowsNull_927bf38a := TRUE;
  p_IsPrimaryKey_927bf38a := FALSE;
  p_IsUniqueKey_927bf38a := FALSE;
  p_IsReadOnly_927bf38a := TRUE;
  p_IsRequired_927bf38a := FALSE;
  p_Sequence_927bf38a := 25;
  p_Status_927bf38a := 'Active';
  p_IsCustom_927bf38a := FALSE;
  p_MetadataSource_927bf38a := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_927bf38a, p_IntegrationObjectID := p_IntegrationObjectID_927bf38a, p_Name := p_Name_927bf38a, p_DisplayName := p_DisplayName_927bf38a, p_Description := p_Description_927bf38a, p_Category := p_Category_927bf38a, p_Category_Clear := TRUE, p_Type := p_Type_927bf38a, p_Length := p_Length_927bf38a, p_Precision := p_Precision_927bf38a, p_Precision_Clear := TRUE, p_Scale := p_Scale_927bf38a, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_927bf38a, p_DefaultValue := p_DefaultValue_927bf38a, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_927bf38a, p_IsUniqueKey := p_IsUniqueKey_927bf38a, p_IsReadOnly := p_IsReadOnly_927bf38a, p_IsRequired := p_IsRequired_927bf38a, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_927bf38a, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_927bf38a, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_927bf38a, p_Configuration := p_Configuration_927bf38a, p_Configuration_Clear := TRUE, p_Status := p_Status_927bf38a, p_IsCustom := p_IsCustom_927bf38a, p_MetadataSource := p_MetadataSource_927bf38a);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_9aa4cc75 UUID;
  p_IntegrationObjectID_9aa4cc75 UUID;
  p_Name_9aa4cc75 VARCHAR(255);
  p_DisplayName_9aa4cc75 VARCHAR(255);
  p_Description_9aa4cc75 TEXT;
  p_Category_9aa4cc75 VARCHAR(100);
  p_Type_9aa4cc75 VARCHAR(100);
  p_Length_9aa4cc75 INTEGER;
  p_Precision_9aa4cc75 INTEGER;
  p_Scale_9aa4cc75 INTEGER;
  p_AllowsNull_9aa4cc75 BOOLEAN;
  p_DefaultValue_9aa4cc75 VARCHAR(255);
  p_IsPrimaryKey_9aa4cc75 BOOLEAN;
  p_IsUniqueKey_9aa4cc75 BOOLEAN;
  p_IsReadOnly_9aa4cc75 BOOLEAN;
  p_IsRequired_9aa4cc75 BOOLEAN;
  p_RelatedIntegrationObjectID_9aa4cc75 UUID;
  p_RelatedIntegrationObjectFieldName_9aa4cc75 VARCHAR(255);
  p_Sequence_9aa4cc75 INTEGER;
  p_Configuration_9aa4cc75 TEXT;
  p_Status_9aa4cc75 VARCHAR(25);
  p_IsCustom_9aa4cc75 BOOLEAN;
  p_MetadataSource_9aa4cc75 VARCHAR(20);
BEGIN
  p_ID_9aa4cc75 := '9C26EDFA-6304-5232-817F-BB3A10984AA4';
  p_IntegrationObjectID_9aa4cc75 := '5F90FE9B-3498-4DC2-A188-6173B8EA842B';
  p_Name_9aa4cc75 := 'organization-disambiguation-source';
  p_DisplayName_9aa4cc75 := 'Organization Disambiguation Source';
  p_Description_9aa4cc75 := 'Registry the disambiguated id comes from (RINGGOLD, ROR, FUNDREF, GRID, LEI).';
  p_Type_9aa4cc75 := 'String';
  p_Length_9aa4cc75 := 100;
  p_AllowsNull_9aa4cc75 := TRUE;
  p_IsPrimaryKey_9aa4cc75 := FALSE;
  p_IsUniqueKey_9aa4cc75 := FALSE;
  p_IsReadOnly_9aa4cc75 := TRUE;
  p_IsRequired_9aa4cc75 := FALSE;
  p_Sequence_9aa4cc75 := 26;
  p_Status_9aa4cc75 := 'Active';
  p_IsCustom_9aa4cc75 := FALSE;
  p_MetadataSource_9aa4cc75 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_9aa4cc75, p_IntegrationObjectID := p_IntegrationObjectID_9aa4cc75, p_Name := p_Name_9aa4cc75, p_DisplayName := p_DisplayName_9aa4cc75, p_Description := p_Description_9aa4cc75, p_Category := p_Category_9aa4cc75, p_Category_Clear := TRUE, p_Type := p_Type_9aa4cc75, p_Length := p_Length_9aa4cc75, p_Precision := p_Precision_9aa4cc75, p_Precision_Clear := TRUE, p_Scale := p_Scale_9aa4cc75, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_9aa4cc75, p_DefaultValue := p_DefaultValue_9aa4cc75, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_9aa4cc75, p_IsUniqueKey := p_IsUniqueKey_9aa4cc75, p_IsReadOnly := p_IsReadOnly_9aa4cc75, p_IsRequired := p_IsRequired_9aa4cc75, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_9aa4cc75, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_9aa4cc75, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_9aa4cc75, p_Configuration := p_Configuration_9aa4cc75, p_Configuration_Clear := TRUE, p_Status := p_Status_9aa4cc75, p_IsCustom := p_IsCustom_9aa4cc75, p_MetadataSource := p_MetadataSource_9aa4cc75);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_8fc7176d UUID;
  p_IntegrationObjectID_8fc7176d UUID;
  p_Name_8fc7176d VARCHAR(255);
  p_DisplayName_8fc7176d VARCHAR(255);
  p_Description_8fc7176d TEXT;
  p_Category_8fc7176d VARCHAR(100);
  p_Type_8fc7176d VARCHAR(100);
  p_Length_8fc7176d INTEGER;
  p_Precision_8fc7176d INTEGER;
  p_Scale_8fc7176d INTEGER;
  p_AllowsNull_8fc7176d BOOLEAN;
  p_DefaultValue_8fc7176d VARCHAR(255);
  p_IsPrimaryKey_8fc7176d BOOLEAN;
  p_IsUniqueKey_8fc7176d BOOLEAN;
  p_IsReadOnly_8fc7176d BOOLEAN;
  p_IsRequired_8fc7176d BOOLEAN;
  p_RelatedIntegrationObjectID_8fc7176d UUID;
  p_RelatedIntegrationObjectFieldName_8fc7176d VARCHAR(255);
  p_Sequence_8fc7176d INTEGER;
  p_Configuration_8fc7176d TEXT;
  p_Status_8fc7176d VARCHAR(25);
  p_IsCustom_8fc7176d BOOLEAN;
  p_MetadataSource_8fc7176d VARCHAR(20);
BEGIN
  p_ID_8fc7176d := '7E0E532D-BD89-5DE7-BFF6-44A616245D80';
  p_IntegrationObjectID_8fc7176d := '5F90FE9B-3498-4DC2-A188-6173B8EA842B';
  p_Name_8fc7176d := 'source-name';
  p_DisplayName_8fc7176d := 'Source Name';
  p_Description_8fc7176d := 'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.';
  p_Type_8fc7176d := 'String';
  p_Length_8fc7176d := 500;
  p_AllowsNull_8fc7176d := TRUE;
  p_IsPrimaryKey_8fc7176d := FALSE;
  p_IsUniqueKey_8fc7176d := FALSE;
  p_IsReadOnly_8fc7176d := TRUE;
  p_IsRequired_8fc7176d := FALSE;
  p_Sequence_8fc7176d := 27;
  p_Status_8fc7176d := 'Active';
  p_IsCustom_8fc7176d := FALSE;
  p_MetadataSource_8fc7176d := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_8fc7176d, p_IntegrationObjectID := p_IntegrationObjectID_8fc7176d, p_Name := p_Name_8fc7176d, p_DisplayName := p_DisplayName_8fc7176d, p_Description := p_Description_8fc7176d, p_Category := p_Category_8fc7176d, p_Category_Clear := TRUE, p_Type := p_Type_8fc7176d, p_Length := p_Length_8fc7176d, p_Precision := p_Precision_8fc7176d, p_Precision_Clear := TRUE, p_Scale := p_Scale_8fc7176d, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_8fc7176d, p_DefaultValue := p_DefaultValue_8fc7176d, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_8fc7176d, p_IsUniqueKey := p_IsUniqueKey_8fc7176d, p_IsReadOnly := p_IsReadOnly_8fc7176d, p_IsRequired := p_IsRequired_8fc7176d, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_8fc7176d, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_8fc7176d, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_8fc7176d, p_Configuration := p_Configuration_8fc7176d, p_Configuration_Clear := TRUE, p_Status := p_Status_8fc7176d, p_IsCustom := p_IsCustom_8fc7176d, p_MetadataSource := p_MetadataSource_8fc7176d);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_8ce7c087 UUID;
  p_IntegrationObjectID_8ce7c087 UUID;
  p_Name_8ce7c087 VARCHAR(255);
  p_DisplayName_8ce7c087 VARCHAR(255);
  p_Description_8ce7c087 TEXT;
  p_Category_8ce7c087 VARCHAR(100);
  p_Type_8ce7c087 VARCHAR(100);
  p_Length_8ce7c087 INTEGER;
  p_Precision_8ce7c087 INTEGER;
  p_Scale_8ce7c087 INTEGER;
  p_AllowsNull_8ce7c087 BOOLEAN;
  p_DefaultValue_8ce7c087 VARCHAR(255);
  p_IsPrimaryKey_8ce7c087 BOOLEAN;
  p_IsUniqueKey_8ce7c087 BOOLEAN;
  p_IsReadOnly_8ce7c087 BOOLEAN;
  p_IsRequired_8ce7c087 BOOLEAN;
  p_RelatedIntegrationObjectID_8ce7c087 UUID;
  p_RelatedIntegrationObjectFieldName_8ce7c087 VARCHAR(255);
  p_Sequence_8ce7c087 INTEGER;
  p_Configuration_8ce7c087 TEXT;
  p_Status_8ce7c087 VARCHAR(25);
  p_IsCustom_8ce7c087 BOOLEAN;
  p_MetadataSource_8ce7c087 VARCHAR(20);
BEGIN
  p_ID_8ce7c087 := 'F0ABD08E-E231-5CBC-AE51-5BF7158F3EC0';
  p_IntegrationObjectID_8ce7c087 := '5F90FE9B-3498-4DC2-A188-6173B8EA842B';
  p_Name_8ce7c087 := 'source-orcid';
  p_DisplayName_8ce7c087 := 'Source Orcid';
  p_Description_8ce7c087 := 'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.';
  p_Type_8ce7c087 := 'String';
  p_Length_8ce7c087 := 19;
  p_AllowsNull_8ce7c087 := TRUE;
  p_IsPrimaryKey_8ce7c087 := FALSE;
  p_IsUniqueKey_8ce7c087 := FALSE;
  p_IsReadOnly_8ce7c087 := TRUE;
  p_IsRequired_8ce7c087 := FALSE;
  p_Sequence_8ce7c087 := 28;
  p_Status_8ce7c087 := 'Active';
  p_IsCustom_8ce7c087 := FALSE;
  p_MetadataSource_8ce7c087 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_8ce7c087, p_IntegrationObjectID := p_IntegrationObjectID_8ce7c087, p_Name := p_Name_8ce7c087, p_DisplayName := p_DisplayName_8ce7c087, p_Description := p_Description_8ce7c087, p_Category := p_Category_8ce7c087, p_Category_Clear := TRUE, p_Type := p_Type_8ce7c087, p_Length := p_Length_8ce7c087, p_Precision := p_Precision_8ce7c087, p_Precision_Clear := TRUE, p_Scale := p_Scale_8ce7c087, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_8ce7c087, p_DefaultValue := p_DefaultValue_8ce7c087, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_8ce7c087, p_IsUniqueKey := p_IsUniqueKey_8ce7c087, p_IsReadOnly := p_IsReadOnly_8ce7c087, p_IsRequired := p_IsRequired_8ce7c087, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_8ce7c087, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_8ce7c087, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_8ce7c087, p_Configuration := p_Configuration_8ce7c087, p_Configuration_Clear := TRUE, p_Status := p_Status_8ce7c087, p_IsCustom := p_IsCustom_8ce7c087, p_MetadataSource := p_MetadataSource_8ce7c087);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_f98937e0 UUID;
  p_IntegrationObjectID_f98937e0 UUID;
  p_Name_f98937e0 VARCHAR(255);
  p_DisplayName_f98937e0 VARCHAR(255);
  p_Description_f98937e0 TEXT;
  p_Category_f98937e0 VARCHAR(100);
  p_Type_f98937e0 VARCHAR(100);
  p_Length_f98937e0 INTEGER;
  p_Precision_f98937e0 INTEGER;
  p_Scale_f98937e0 INTEGER;
  p_AllowsNull_f98937e0 BOOLEAN;
  p_DefaultValue_f98937e0 VARCHAR(255);
  p_IsPrimaryKey_f98937e0 BOOLEAN;
  p_IsUniqueKey_f98937e0 BOOLEAN;
  p_IsReadOnly_f98937e0 BOOLEAN;
  p_IsRequired_f98937e0 BOOLEAN;
  p_RelatedIntegrationObjectID_f98937e0 UUID;
  p_RelatedIntegrationObjectFieldName_f98937e0 VARCHAR(255);
  p_Sequence_f98937e0 INTEGER;
  p_Configuration_f98937e0 TEXT;
  p_Status_f98937e0 VARCHAR(25);
  p_IsCustom_f98937e0 BOOLEAN;
  p_MetadataSource_f98937e0 VARCHAR(20);
BEGIN
  p_ID_f98937e0 := '790CB7A8-600B-5998-A600-622F1602FE73';
  p_IntegrationObjectID_f98937e0 := '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF';
  p_Name_f98937e0 := 'start-year';
  p_DisplayName_f98937e0 := 'Start Year';
  p_Description_f98937e0 := 'Year of the affiliation start date; ORCID dates are partial, so month/day may be absent.';
  p_Type_f98937e0 := 'Integer';
  p_AllowsNull_f98937e0 := TRUE;
  p_IsPrimaryKey_f98937e0 := FALSE;
  p_IsUniqueKey_f98937e0 := FALSE;
  p_IsReadOnly_f98937e0 := TRUE;
  p_IsRequired_f98937e0 := FALSE;
  p_Sequence_f98937e0 := 15;
  p_Status_f98937e0 := 'Active';
  p_IsCustom_f98937e0 := FALSE;
  p_MetadataSource_f98937e0 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_f98937e0, p_IntegrationObjectID := p_IntegrationObjectID_f98937e0, p_Name := p_Name_f98937e0, p_DisplayName := p_DisplayName_f98937e0, p_Description := p_Description_f98937e0, p_Category := p_Category_f98937e0, p_Category_Clear := TRUE, p_Type := p_Type_f98937e0, p_Length := p_Length_f98937e0, p_Length_Clear := TRUE, p_Precision := p_Precision_f98937e0, p_Precision_Clear := TRUE, p_Scale := p_Scale_f98937e0, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_f98937e0, p_DefaultValue := p_DefaultValue_f98937e0, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_f98937e0, p_IsUniqueKey := p_IsUniqueKey_f98937e0, p_IsReadOnly := p_IsReadOnly_f98937e0, p_IsRequired := p_IsRequired_f98937e0, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_f98937e0, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_f98937e0, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_f98937e0, p_Configuration := p_Configuration_f98937e0, p_Configuration_Clear := TRUE, p_Status := p_Status_f98937e0, p_IsCustom := p_IsCustom_f98937e0, p_MetadataSource := p_MetadataSource_f98937e0);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_c085b5e4 UUID;
  p_IntegrationObjectID_c085b5e4 UUID;
  p_Name_c085b5e4 VARCHAR(255);
  p_DisplayName_c085b5e4 VARCHAR(255);
  p_Description_c085b5e4 TEXT;
  p_Category_c085b5e4 VARCHAR(100);
  p_Type_c085b5e4 VARCHAR(100);
  p_Length_c085b5e4 INTEGER;
  p_Precision_c085b5e4 INTEGER;
  p_Scale_c085b5e4 INTEGER;
  p_AllowsNull_c085b5e4 BOOLEAN;
  p_DefaultValue_c085b5e4 VARCHAR(255);
  p_IsPrimaryKey_c085b5e4 BOOLEAN;
  p_IsUniqueKey_c085b5e4 BOOLEAN;
  p_IsReadOnly_c085b5e4 BOOLEAN;
  p_IsRequired_c085b5e4 BOOLEAN;
  p_RelatedIntegrationObjectID_c085b5e4 UUID;
  p_RelatedIntegrationObjectFieldName_c085b5e4 VARCHAR(255);
  p_Sequence_c085b5e4 INTEGER;
  p_Configuration_c085b5e4 TEXT;
  p_Status_c085b5e4 VARCHAR(25);
  p_IsCustom_c085b5e4 BOOLEAN;
  p_MetadataSource_c085b5e4 VARCHAR(20);
BEGIN
  p_ID_c085b5e4 := '6B7DB5A4-8252-5E8A-AC9D-8903F2FA93F4';
  p_IntegrationObjectID_c085b5e4 := '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF';
  p_Name_c085b5e4 := 'start-month';
  p_DisplayName_c085b5e4 := 'Start Month';
  p_Description_c085b5e4 := 'Month (1-12) of the affiliation start date, when given.';
  p_Type_c085b5e4 := 'Integer';
  p_AllowsNull_c085b5e4 := TRUE;
  p_IsPrimaryKey_c085b5e4 := FALSE;
  p_IsUniqueKey_c085b5e4 := FALSE;
  p_IsReadOnly_c085b5e4 := TRUE;
  p_IsRequired_c085b5e4 := FALSE;
  p_Sequence_c085b5e4 := 16;
  p_Status_c085b5e4 := 'Active';
  p_IsCustom_c085b5e4 := FALSE;
  p_MetadataSource_c085b5e4 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_c085b5e4, p_IntegrationObjectID := p_IntegrationObjectID_c085b5e4, p_Name := p_Name_c085b5e4, p_DisplayName := p_DisplayName_c085b5e4, p_Description := p_Description_c085b5e4, p_Category := p_Category_c085b5e4, p_Category_Clear := TRUE, p_Type := p_Type_c085b5e4, p_Length := p_Length_c085b5e4, p_Length_Clear := TRUE, p_Precision := p_Precision_c085b5e4, p_Precision_Clear := TRUE, p_Scale := p_Scale_c085b5e4, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_c085b5e4, p_DefaultValue := p_DefaultValue_c085b5e4, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_c085b5e4, p_IsUniqueKey := p_IsUniqueKey_c085b5e4, p_IsReadOnly := p_IsReadOnly_c085b5e4, p_IsRequired := p_IsRequired_c085b5e4, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_c085b5e4, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_c085b5e4, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_c085b5e4, p_Configuration := p_Configuration_c085b5e4, p_Configuration_Clear := TRUE, p_Status := p_Status_c085b5e4, p_IsCustom := p_IsCustom_c085b5e4, p_MetadataSource := p_MetadataSource_c085b5e4);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_33c2979b UUID;
  p_IntegrationObjectID_33c2979b UUID;
  p_Name_33c2979b VARCHAR(255);
  p_DisplayName_33c2979b VARCHAR(255);
  p_Description_33c2979b TEXT;
  p_Category_33c2979b VARCHAR(100);
  p_Type_33c2979b VARCHAR(100);
  p_Length_33c2979b INTEGER;
  p_Precision_33c2979b INTEGER;
  p_Scale_33c2979b INTEGER;
  p_AllowsNull_33c2979b BOOLEAN;
  p_DefaultValue_33c2979b VARCHAR(255);
  p_IsPrimaryKey_33c2979b BOOLEAN;
  p_IsUniqueKey_33c2979b BOOLEAN;
  p_IsReadOnly_33c2979b BOOLEAN;
  p_IsRequired_33c2979b BOOLEAN;
  p_RelatedIntegrationObjectID_33c2979b UUID;
  p_RelatedIntegrationObjectFieldName_33c2979b VARCHAR(255);
  p_Sequence_33c2979b INTEGER;
  p_Configuration_33c2979b TEXT;
  p_Status_33c2979b VARCHAR(25);
  p_IsCustom_33c2979b BOOLEAN;
  p_MetadataSource_33c2979b VARCHAR(20);
BEGIN
  p_ID_33c2979b := '90108AC8-021D-50EE-B4A1-BAD18764DF9F';
  p_IntegrationObjectID_33c2979b := '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF';
  p_Name_33c2979b := 'start-day';
  p_DisplayName_33c2979b := 'Start Day';
  p_Description_33c2979b := 'Day of month of the affiliation start date, when given.';
  p_Type_33c2979b := 'Integer';
  p_AllowsNull_33c2979b := TRUE;
  p_IsPrimaryKey_33c2979b := FALSE;
  p_IsUniqueKey_33c2979b := FALSE;
  p_IsReadOnly_33c2979b := TRUE;
  p_IsRequired_33c2979b := FALSE;
  p_Sequence_33c2979b := 17;
  p_Status_33c2979b := 'Active';
  p_IsCustom_33c2979b := FALSE;
  p_MetadataSource_33c2979b := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_33c2979b, p_IntegrationObjectID := p_IntegrationObjectID_33c2979b, p_Name := p_Name_33c2979b, p_DisplayName := p_DisplayName_33c2979b, p_Description := p_Description_33c2979b, p_Category := p_Category_33c2979b, p_Category_Clear := TRUE, p_Type := p_Type_33c2979b, p_Length := p_Length_33c2979b, p_Length_Clear := TRUE, p_Precision := p_Precision_33c2979b, p_Precision_Clear := TRUE, p_Scale := p_Scale_33c2979b, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_33c2979b, p_DefaultValue := p_DefaultValue_33c2979b, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_33c2979b, p_IsUniqueKey := p_IsUniqueKey_33c2979b, p_IsReadOnly := p_IsReadOnly_33c2979b, p_IsRequired := p_IsRequired_33c2979b, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_33c2979b, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_33c2979b, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_33c2979b, p_Configuration := p_Configuration_33c2979b, p_Configuration_Clear := TRUE, p_Status := p_Status_33c2979b, p_IsCustom := p_IsCustom_33c2979b, p_MetadataSource := p_MetadataSource_33c2979b);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_969211d0 UUID;
  p_IntegrationObjectID_969211d0 UUID;
  p_Name_969211d0 VARCHAR(255);
  p_DisplayName_969211d0 VARCHAR(255);
  p_Description_969211d0 TEXT;
  p_Category_969211d0 VARCHAR(100);
  p_Type_969211d0 VARCHAR(100);
  p_Length_969211d0 INTEGER;
  p_Precision_969211d0 INTEGER;
  p_Scale_969211d0 INTEGER;
  p_AllowsNull_969211d0 BOOLEAN;
  p_DefaultValue_969211d0 VARCHAR(255);
  p_IsPrimaryKey_969211d0 BOOLEAN;
  p_IsUniqueKey_969211d0 BOOLEAN;
  p_IsReadOnly_969211d0 BOOLEAN;
  p_IsRequired_969211d0 BOOLEAN;
  p_RelatedIntegrationObjectID_969211d0 UUID;
  p_RelatedIntegrationObjectFieldName_969211d0 VARCHAR(255);
  p_Sequence_969211d0 INTEGER;
  p_Configuration_969211d0 TEXT;
  p_Status_969211d0 VARCHAR(25);
  p_IsCustom_969211d0 BOOLEAN;
  p_MetadataSource_969211d0 VARCHAR(20);
BEGIN
  p_ID_969211d0 := '300A921E-0166-5396-AB56-35658DE42540';
  p_IntegrationObjectID_969211d0 := '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF';
  p_Name_969211d0 := 'end-year';
  p_DisplayName_969211d0 := 'End Year';
  p_Description_969211d0 := 'Year of the affiliation end date; empty for a current/ongoing role; ORCID dates are partial, so month/day may be absent.';
  p_Type_969211d0 := 'Integer';
  p_AllowsNull_969211d0 := TRUE;
  p_IsPrimaryKey_969211d0 := FALSE;
  p_IsUniqueKey_969211d0 := FALSE;
  p_IsReadOnly_969211d0 := TRUE;
  p_IsRequired_969211d0 := FALSE;
  p_Sequence_969211d0 := 18;
  p_Status_969211d0 := 'Active';
  p_IsCustom_969211d0 := FALSE;
  p_MetadataSource_969211d0 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_969211d0, p_IntegrationObjectID := p_IntegrationObjectID_969211d0, p_Name := p_Name_969211d0, p_DisplayName := p_DisplayName_969211d0, p_Description := p_Description_969211d0, p_Category := p_Category_969211d0, p_Category_Clear := TRUE, p_Type := p_Type_969211d0, p_Length := p_Length_969211d0, p_Length_Clear := TRUE, p_Precision := p_Precision_969211d0, p_Precision_Clear := TRUE, p_Scale := p_Scale_969211d0, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_969211d0, p_DefaultValue := p_DefaultValue_969211d0, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_969211d0, p_IsUniqueKey := p_IsUniqueKey_969211d0, p_IsReadOnly := p_IsReadOnly_969211d0, p_IsRequired := p_IsRequired_969211d0, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_969211d0, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_969211d0, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_969211d0, p_Configuration := p_Configuration_969211d0, p_Configuration_Clear := TRUE, p_Status := p_Status_969211d0, p_IsCustom := p_IsCustom_969211d0, p_MetadataSource := p_MetadataSource_969211d0);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_179ed48d UUID;
  p_IntegrationObjectID_179ed48d UUID;
  p_Name_179ed48d VARCHAR(255);
  p_DisplayName_179ed48d VARCHAR(255);
  p_Description_179ed48d TEXT;
  p_Category_179ed48d VARCHAR(100);
  p_Type_179ed48d VARCHAR(100);
  p_Length_179ed48d INTEGER;
  p_Precision_179ed48d INTEGER;
  p_Scale_179ed48d INTEGER;
  p_AllowsNull_179ed48d BOOLEAN;
  p_DefaultValue_179ed48d VARCHAR(255);
  p_IsPrimaryKey_179ed48d BOOLEAN;
  p_IsUniqueKey_179ed48d BOOLEAN;
  p_IsReadOnly_179ed48d BOOLEAN;
  p_IsRequired_179ed48d BOOLEAN;
  p_RelatedIntegrationObjectID_179ed48d UUID;
  p_RelatedIntegrationObjectFieldName_179ed48d VARCHAR(255);
  p_Sequence_179ed48d INTEGER;
  p_Configuration_179ed48d TEXT;
  p_Status_179ed48d VARCHAR(25);
  p_IsCustom_179ed48d BOOLEAN;
  p_MetadataSource_179ed48d VARCHAR(20);
BEGIN
  p_ID_179ed48d := 'C1D39A35-F49D-58A1-8295-6E6B131DFD78';
  p_IntegrationObjectID_179ed48d := '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF';
  p_Name_179ed48d := 'end-month';
  p_DisplayName_179ed48d := 'End Month';
  p_Description_179ed48d := 'Month (1-12) of the affiliation end date; empty for a current/ongoing role, when given.';
  p_Type_179ed48d := 'Integer';
  p_AllowsNull_179ed48d := TRUE;
  p_IsPrimaryKey_179ed48d := FALSE;
  p_IsUniqueKey_179ed48d := FALSE;
  p_IsReadOnly_179ed48d := TRUE;
  p_IsRequired_179ed48d := FALSE;
  p_Sequence_179ed48d := 19;
  p_Status_179ed48d := 'Active';
  p_IsCustom_179ed48d := FALSE;
  p_MetadataSource_179ed48d := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_179ed48d, p_IntegrationObjectID := p_IntegrationObjectID_179ed48d, p_Name := p_Name_179ed48d, p_DisplayName := p_DisplayName_179ed48d, p_Description := p_Description_179ed48d, p_Category := p_Category_179ed48d, p_Category_Clear := TRUE, p_Type := p_Type_179ed48d, p_Length := p_Length_179ed48d, p_Length_Clear := TRUE, p_Precision := p_Precision_179ed48d, p_Precision_Clear := TRUE, p_Scale := p_Scale_179ed48d, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_179ed48d, p_DefaultValue := p_DefaultValue_179ed48d, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_179ed48d, p_IsUniqueKey := p_IsUniqueKey_179ed48d, p_IsReadOnly := p_IsReadOnly_179ed48d, p_IsRequired := p_IsRequired_179ed48d, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_179ed48d, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_179ed48d, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_179ed48d, p_Configuration := p_Configuration_179ed48d, p_Configuration_Clear := TRUE, p_Status := p_Status_179ed48d, p_IsCustom := p_IsCustom_179ed48d, p_MetadataSource := p_MetadataSource_179ed48d);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_51705d9b UUID;
  p_IntegrationObjectID_51705d9b UUID;
  p_Name_51705d9b VARCHAR(255);
  p_DisplayName_51705d9b VARCHAR(255);
  p_Description_51705d9b TEXT;
  p_Category_51705d9b VARCHAR(100);
  p_Type_51705d9b VARCHAR(100);
  p_Length_51705d9b INTEGER;
  p_Precision_51705d9b INTEGER;
  p_Scale_51705d9b INTEGER;
  p_AllowsNull_51705d9b BOOLEAN;
  p_DefaultValue_51705d9b VARCHAR(255);
  p_IsPrimaryKey_51705d9b BOOLEAN;
  p_IsUniqueKey_51705d9b BOOLEAN;
  p_IsReadOnly_51705d9b BOOLEAN;
  p_IsRequired_51705d9b BOOLEAN;
  p_RelatedIntegrationObjectID_51705d9b UUID;
  p_RelatedIntegrationObjectFieldName_51705d9b VARCHAR(255);
  p_Sequence_51705d9b INTEGER;
  p_Configuration_51705d9b TEXT;
  p_Status_51705d9b VARCHAR(25);
  p_IsCustom_51705d9b BOOLEAN;
  p_MetadataSource_51705d9b VARCHAR(20);
BEGIN
  p_ID_51705d9b := '23C9A5A5-49AF-5C69-926D-0F5B952F911F';
  p_IntegrationObjectID_51705d9b := '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF';
  p_Name_51705d9b := 'end-day';
  p_DisplayName_51705d9b := 'End Day';
  p_Description_51705d9b := 'Day of month of the affiliation end date; empty for a current/ongoing role, when given.';
  p_Type_51705d9b := 'Integer';
  p_AllowsNull_51705d9b := TRUE;
  p_IsPrimaryKey_51705d9b := FALSE;
  p_IsUniqueKey_51705d9b := FALSE;
  p_IsReadOnly_51705d9b := TRUE;
  p_IsRequired_51705d9b := FALSE;
  p_Sequence_51705d9b := 20;
  p_Status_51705d9b := 'Active';
  p_IsCustom_51705d9b := FALSE;
  p_MetadataSource_51705d9b := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_51705d9b, p_IntegrationObjectID := p_IntegrationObjectID_51705d9b, p_Name := p_Name_51705d9b, p_DisplayName := p_DisplayName_51705d9b, p_Description := p_Description_51705d9b, p_Category := p_Category_51705d9b, p_Category_Clear := TRUE, p_Type := p_Type_51705d9b, p_Length := p_Length_51705d9b, p_Length_Clear := TRUE, p_Precision := p_Precision_51705d9b, p_Precision_Clear := TRUE, p_Scale := p_Scale_51705d9b, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_51705d9b, p_DefaultValue := p_DefaultValue_51705d9b, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_51705d9b, p_IsUniqueKey := p_IsUniqueKey_51705d9b, p_IsReadOnly := p_IsReadOnly_51705d9b, p_IsRequired := p_IsRequired_51705d9b, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_51705d9b, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_51705d9b, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_51705d9b, p_Configuration := p_Configuration_51705d9b, p_Configuration_Clear := TRUE, p_Status := p_Status_51705d9b, p_IsCustom := p_IsCustom_51705d9b, p_MetadataSource := p_MetadataSource_51705d9b);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_2bf8706c UUID;
  p_IntegrationObjectID_2bf8706c UUID;
  p_Name_2bf8706c VARCHAR(255);
  p_DisplayName_2bf8706c VARCHAR(255);
  p_Description_2bf8706c TEXT;
  p_Category_2bf8706c VARCHAR(100);
  p_Type_2bf8706c VARCHAR(100);
  p_Length_2bf8706c INTEGER;
  p_Precision_2bf8706c INTEGER;
  p_Scale_2bf8706c INTEGER;
  p_AllowsNull_2bf8706c BOOLEAN;
  p_DefaultValue_2bf8706c VARCHAR(255);
  p_IsPrimaryKey_2bf8706c BOOLEAN;
  p_IsUniqueKey_2bf8706c BOOLEAN;
  p_IsReadOnly_2bf8706c BOOLEAN;
  p_IsRequired_2bf8706c BOOLEAN;
  p_RelatedIntegrationObjectID_2bf8706c UUID;
  p_RelatedIntegrationObjectFieldName_2bf8706c VARCHAR(255);
  p_Sequence_2bf8706c INTEGER;
  p_Configuration_2bf8706c TEXT;
  p_Status_2bf8706c VARCHAR(25);
  p_IsCustom_2bf8706c BOOLEAN;
  p_MetadataSource_2bf8706c VARCHAR(20);
BEGIN
  p_ID_2bf8706c := '26E0B5B8-BD26-5A75-B8D8-A339002CCAFD';
  p_IntegrationObjectID_2bf8706c := '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF';
  p_Name_2bf8706c := 'organization-name';
  p_DisplayName_2bf8706c := 'Organization Name';
  p_Description_2bf8706c := 'Name of the organization. Lifted from organization.name.';
  p_Type_2bf8706c := 'String';
  p_Length_2bf8706c := 1000;
  p_AllowsNull_2bf8706c := TRUE;
  p_IsPrimaryKey_2bf8706c := FALSE;
  p_IsUniqueKey_2bf8706c := FALSE;
  p_IsReadOnly_2bf8706c := TRUE;
  p_IsRequired_2bf8706c := FALSE;
  p_Sequence_2bf8706c := 21;
  p_Status_2bf8706c := 'Active';
  p_IsCustom_2bf8706c := FALSE;
  p_MetadataSource_2bf8706c := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_2bf8706c, p_IntegrationObjectID := p_IntegrationObjectID_2bf8706c, p_Name := p_Name_2bf8706c, p_DisplayName := p_DisplayName_2bf8706c, p_Description := p_Description_2bf8706c, p_Category := p_Category_2bf8706c, p_Category_Clear := TRUE, p_Type := p_Type_2bf8706c, p_Length := p_Length_2bf8706c, p_Precision := p_Precision_2bf8706c, p_Precision_Clear := TRUE, p_Scale := p_Scale_2bf8706c, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_2bf8706c, p_DefaultValue := p_DefaultValue_2bf8706c, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_2bf8706c, p_IsUniqueKey := p_IsUniqueKey_2bf8706c, p_IsReadOnly := p_IsReadOnly_2bf8706c, p_IsRequired := p_IsRequired_2bf8706c, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_2bf8706c, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_2bf8706c, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_2bf8706c, p_Configuration := p_Configuration_2bf8706c, p_Configuration_Clear := TRUE, p_Status := p_Status_2bf8706c, p_IsCustom := p_IsCustom_2bf8706c, p_MetadataSource := p_MetadataSource_2bf8706c);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_85efda60 UUID;
  p_IntegrationObjectID_85efda60 UUID;
  p_Name_85efda60 VARCHAR(255);
  p_DisplayName_85efda60 VARCHAR(255);
  p_Description_85efda60 TEXT;
  p_Category_85efda60 VARCHAR(100);
  p_Type_85efda60 VARCHAR(100);
  p_Length_85efda60 INTEGER;
  p_Precision_85efda60 INTEGER;
  p_Scale_85efda60 INTEGER;
  p_AllowsNull_85efda60 BOOLEAN;
  p_DefaultValue_85efda60 VARCHAR(255);
  p_IsPrimaryKey_85efda60 BOOLEAN;
  p_IsUniqueKey_85efda60 BOOLEAN;
  p_IsReadOnly_85efda60 BOOLEAN;
  p_IsRequired_85efda60 BOOLEAN;
  p_RelatedIntegrationObjectID_85efda60 UUID;
  p_RelatedIntegrationObjectFieldName_85efda60 VARCHAR(255);
  p_Sequence_85efda60 INTEGER;
  p_Configuration_85efda60 TEXT;
  p_Status_85efda60 VARCHAR(25);
  p_IsCustom_85efda60 BOOLEAN;
  p_MetadataSource_85efda60 VARCHAR(20);
BEGIN
  p_ID_85efda60 := '1AC712C1-932B-5465-94A0-9FBECFAF740A';
  p_IntegrationObjectID_85efda60 := '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF';
  p_Name_85efda60 := 'organization-city';
  p_DisplayName_85efda60 := 'Organization City';
  p_Description_85efda60 := 'City of the organization. Lifted from organization.address.city.';
  p_Type_85efda60 := 'String';
  p_Length_85efda60 := 255;
  p_AllowsNull_85efda60 := TRUE;
  p_IsPrimaryKey_85efda60 := FALSE;
  p_IsUniqueKey_85efda60 := FALSE;
  p_IsReadOnly_85efda60 := TRUE;
  p_IsRequired_85efda60 := FALSE;
  p_Sequence_85efda60 := 22;
  p_Status_85efda60 := 'Active';
  p_IsCustom_85efda60 := FALSE;
  p_MetadataSource_85efda60 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_85efda60, p_IntegrationObjectID := p_IntegrationObjectID_85efda60, p_Name := p_Name_85efda60, p_DisplayName := p_DisplayName_85efda60, p_Description := p_Description_85efda60, p_Category := p_Category_85efda60, p_Category_Clear := TRUE, p_Type := p_Type_85efda60, p_Length := p_Length_85efda60, p_Precision := p_Precision_85efda60, p_Precision_Clear := TRUE, p_Scale := p_Scale_85efda60, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_85efda60, p_DefaultValue := p_DefaultValue_85efda60, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_85efda60, p_IsUniqueKey := p_IsUniqueKey_85efda60, p_IsReadOnly := p_IsReadOnly_85efda60, p_IsRequired := p_IsRequired_85efda60, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_85efda60, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_85efda60, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_85efda60, p_Configuration := p_Configuration_85efda60, p_Configuration_Clear := TRUE, p_Status := p_Status_85efda60, p_IsCustom := p_IsCustom_85efda60, p_MetadataSource := p_MetadataSource_85efda60);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_3f59d65a UUID;
  p_IntegrationObjectID_3f59d65a UUID;
  p_Name_3f59d65a VARCHAR(255);
  p_DisplayName_3f59d65a VARCHAR(255);
  p_Description_3f59d65a TEXT;
  p_Category_3f59d65a VARCHAR(100);
  p_Type_3f59d65a VARCHAR(100);
  p_Length_3f59d65a INTEGER;
  p_Precision_3f59d65a INTEGER;
  p_Scale_3f59d65a INTEGER;
  p_AllowsNull_3f59d65a BOOLEAN;
  p_DefaultValue_3f59d65a VARCHAR(255);
  p_IsPrimaryKey_3f59d65a BOOLEAN;
  p_IsUniqueKey_3f59d65a BOOLEAN;
  p_IsReadOnly_3f59d65a BOOLEAN;
  p_IsRequired_3f59d65a BOOLEAN;
  p_RelatedIntegrationObjectID_3f59d65a UUID;
  p_RelatedIntegrationObjectFieldName_3f59d65a VARCHAR(255);
  p_Sequence_3f59d65a INTEGER;
  p_Configuration_3f59d65a TEXT;
  p_Status_3f59d65a VARCHAR(25);
  p_IsCustom_3f59d65a BOOLEAN;
  p_MetadataSource_3f59d65a VARCHAR(20);
BEGIN
  p_ID_3f59d65a := '8F3BFB6A-A40C-5E62-8214-355A52D8CEA7';
  p_IntegrationObjectID_3f59d65a := '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF';
  p_Name_3f59d65a := 'organization-region';
  p_DisplayName_3f59d65a := 'Organization Region';
  p_Description_3f59d65a := 'Region/state of the organization. Lifted from organization.address.region.';
  p_Type_3f59d65a := 'String';
  p_Length_3f59d65a := 255;
  p_AllowsNull_3f59d65a := TRUE;
  p_IsPrimaryKey_3f59d65a := FALSE;
  p_IsUniqueKey_3f59d65a := FALSE;
  p_IsReadOnly_3f59d65a := TRUE;
  p_IsRequired_3f59d65a := FALSE;
  p_Sequence_3f59d65a := 23;
  p_Status_3f59d65a := 'Active';
  p_IsCustom_3f59d65a := FALSE;
  p_MetadataSource_3f59d65a := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_3f59d65a, p_IntegrationObjectID := p_IntegrationObjectID_3f59d65a, p_Name := p_Name_3f59d65a, p_DisplayName := p_DisplayName_3f59d65a, p_Description := p_Description_3f59d65a, p_Category := p_Category_3f59d65a, p_Category_Clear := TRUE, p_Type := p_Type_3f59d65a, p_Length := p_Length_3f59d65a, p_Precision := p_Precision_3f59d65a, p_Precision_Clear := TRUE, p_Scale := p_Scale_3f59d65a, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_3f59d65a, p_DefaultValue := p_DefaultValue_3f59d65a, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_3f59d65a, p_IsUniqueKey := p_IsUniqueKey_3f59d65a, p_IsReadOnly := p_IsReadOnly_3f59d65a, p_IsRequired := p_IsRequired_3f59d65a, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_3f59d65a, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_3f59d65a, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_3f59d65a, p_Configuration := p_Configuration_3f59d65a, p_Configuration_Clear := TRUE, p_Status := p_Status_3f59d65a, p_IsCustom := p_IsCustom_3f59d65a, p_MetadataSource := p_MetadataSource_3f59d65a);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_56322830 UUID;
  p_IntegrationObjectID_56322830 UUID;
  p_Name_56322830 VARCHAR(255);
  p_DisplayName_56322830 VARCHAR(255);
  p_Description_56322830 TEXT;
  p_Category_56322830 VARCHAR(100);
  p_Type_56322830 VARCHAR(100);
  p_Length_56322830 INTEGER;
  p_Precision_56322830 INTEGER;
  p_Scale_56322830 INTEGER;
  p_AllowsNull_56322830 BOOLEAN;
  p_DefaultValue_56322830 VARCHAR(255);
  p_IsPrimaryKey_56322830 BOOLEAN;
  p_IsUniqueKey_56322830 BOOLEAN;
  p_IsReadOnly_56322830 BOOLEAN;
  p_IsRequired_56322830 BOOLEAN;
  p_RelatedIntegrationObjectID_56322830 UUID;
  p_RelatedIntegrationObjectFieldName_56322830 VARCHAR(255);
  p_Sequence_56322830 INTEGER;
  p_Configuration_56322830 TEXT;
  p_Status_56322830 VARCHAR(25);
  p_IsCustom_56322830 BOOLEAN;
  p_MetadataSource_56322830 VARCHAR(20);
BEGIN
  p_ID_56322830 := 'B71920C5-E3D2-5C44-BC0B-4FD2E2B6E8A5';
  p_IntegrationObjectID_56322830 := '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF';
  p_Name_56322830 := 'organization-country';
  p_DisplayName_56322830 := 'Organization Country';
  p_Description_56322830 := 'ISO country code of the organization. Lifted from organization.address.country.';
  p_Type_56322830 := 'String';
  p_Length_56322830 := 50;
  p_AllowsNull_56322830 := TRUE;
  p_IsPrimaryKey_56322830 := FALSE;
  p_IsUniqueKey_56322830 := FALSE;
  p_IsReadOnly_56322830 := TRUE;
  p_IsRequired_56322830 := FALSE;
  p_Sequence_56322830 := 24;
  p_Status_56322830 := 'Active';
  p_IsCustom_56322830 := FALSE;
  p_MetadataSource_56322830 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_56322830, p_IntegrationObjectID := p_IntegrationObjectID_56322830, p_Name := p_Name_56322830, p_DisplayName := p_DisplayName_56322830, p_Description := p_Description_56322830, p_Category := p_Category_56322830, p_Category_Clear := TRUE, p_Type := p_Type_56322830, p_Length := p_Length_56322830, p_Precision := p_Precision_56322830, p_Precision_Clear := TRUE, p_Scale := p_Scale_56322830, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_56322830, p_DefaultValue := p_DefaultValue_56322830, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_56322830, p_IsUniqueKey := p_IsUniqueKey_56322830, p_IsReadOnly := p_IsReadOnly_56322830, p_IsRequired := p_IsRequired_56322830, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_56322830, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_56322830, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_56322830, p_Configuration := p_Configuration_56322830, p_Configuration_Clear := TRUE, p_Status := p_Status_56322830, p_IsCustom := p_IsCustom_56322830, p_MetadataSource := p_MetadataSource_56322830);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_cab557bd UUID;
  p_IntegrationObjectID_cab557bd UUID;
  p_Name_cab557bd VARCHAR(255);
  p_DisplayName_cab557bd VARCHAR(255);
  p_Description_cab557bd TEXT;
  p_Category_cab557bd VARCHAR(100);
  p_Type_cab557bd VARCHAR(100);
  p_Length_cab557bd INTEGER;
  p_Precision_cab557bd INTEGER;
  p_Scale_cab557bd INTEGER;
  p_AllowsNull_cab557bd BOOLEAN;
  p_DefaultValue_cab557bd VARCHAR(255);
  p_IsPrimaryKey_cab557bd BOOLEAN;
  p_IsUniqueKey_cab557bd BOOLEAN;
  p_IsReadOnly_cab557bd BOOLEAN;
  p_IsRequired_cab557bd BOOLEAN;
  p_RelatedIntegrationObjectID_cab557bd UUID;
  p_RelatedIntegrationObjectFieldName_cab557bd VARCHAR(255);
  p_Sequence_cab557bd INTEGER;
  p_Configuration_cab557bd TEXT;
  p_Status_cab557bd VARCHAR(25);
  p_IsCustom_cab557bd BOOLEAN;
  p_MetadataSource_cab557bd VARCHAR(20);
BEGIN
  p_ID_cab557bd := '2E80B705-8114-58D2-89C7-948217B0F123';
  p_IntegrationObjectID_cab557bd := '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF';
  p_Name_cab557bd := 'organization-disambiguated-id';
  p_DisplayName_cab557bd := 'Organization Disambiguated Id';
  p_Description_cab557bd := 'Canonical identifier of the organization in the disambiguation source (e.g. a RINGGOLD or ROR id), so the same institution matches across records.';
  p_Type_cab557bd := 'String';
  p_Length_cab557bd := 255;
  p_AllowsNull_cab557bd := TRUE;
  p_IsPrimaryKey_cab557bd := FALSE;
  p_IsUniqueKey_cab557bd := FALSE;
  p_IsReadOnly_cab557bd := TRUE;
  p_IsRequired_cab557bd := FALSE;
  p_Sequence_cab557bd := 25;
  p_Status_cab557bd := 'Active';
  p_IsCustom_cab557bd := FALSE;
  p_MetadataSource_cab557bd := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_cab557bd, p_IntegrationObjectID := p_IntegrationObjectID_cab557bd, p_Name := p_Name_cab557bd, p_DisplayName := p_DisplayName_cab557bd, p_Description := p_Description_cab557bd, p_Category := p_Category_cab557bd, p_Category_Clear := TRUE, p_Type := p_Type_cab557bd, p_Length := p_Length_cab557bd, p_Precision := p_Precision_cab557bd, p_Precision_Clear := TRUE, p_Scale := p_Scale_cab557bd, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_cab557bd, p_DefaultValue := p_DefaultValue_cab557bd, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_cab557bd, p_IsUniqueKey := p_IsUniqueKey_cab557bd, p_IsReadOnly := p_IsReadOnly_cab557bd, p_IsRequired := p_IsRequired_cab557bd, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_cab557bd, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_cab557bd, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_cab557bd, p_Configuration := p_Configuration_cab557bd, p_Configuration_Clear := TRUE, p_Status := p_Status_cab557bd, p_IsCustom := p_IsCustom_cab557bd, p_MetadataSource := p_MetadataSource_cab557bd);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_c556404d UUID;
  p_IntegrationObjectID_c556404d UUID;
  p_Name_c556404d VARCHAR(255);
  p_DisplayName_c556404d VARCHAR(255);
  p_Description_c556404d TEXT;
  p_Category_c556404d VARCHAR(100);
  p_Type_c556404d VARCHAR(100);
  p_Length_c556404d INTEGER;
  p_Precision_c556404d INTEGER;
  p_Scale_c556404d INTEGER;
  p_AllowsNull_c556404d BOOLEAN;
  p_DefaultValue_c556404d VARCHAR(255);
  p_IsPrimaryKey_c556404d BOOLEAN;
  p_IsUniqueKey_c556404d BOOLEAN;
  p_IsReadOnly_c556404d BOOLEAN;
  p_IsRequired_c556404d BOOLEAN;
  p_RelatedIntegrationObjectID_c556404d UUID;
  p_RelatedIntegrationObjectFieldName_c556404d VARCHAR(255);
  p_Sequence_c556404d INTEGER;
  p_Configuration_c556404d TEXT;
  p_Status_c556404d VARCHAR(25);
  p_IsCustom_c556404d BOOLEAN;
  p_MetadataSource_c556404d VARCHAR(20);
BEGIN
  p_ID_c556404d := '75787A6A-A4F6-5CC3-A00F-6F1A66ED1538';
  p_IntegrationObjectID_c556404d := '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF';
  p_Name_c556404d := 'organization-disambiguation-source';
  p_DisplayName_c556404d := 'Organization Disambiguation Source';
  p_Description_c556404d := 'Registry the disambiguated id comes from (RINGGOLD, ROR, FUNDREF, GRID, LEI).';
  p_Type_c556404d := 'String';
  p_Length_c556404d := 100;
  p_AllowsNull_c556404d := TRUE;
  p_IsPrimaryKey_c556404d := FALSE;
  p_IsUniqueKey_c556404d := FALSE;
  p_IsReadOnly_c556404d := TRUE;
  p_IsRequired_c556404d := FALSE;
  p_Sequence_c556404d := 26;
  p_Status_c556404d := 'Active';
  p_IsCustom_c556404d := FALSE;
  p_MetadataSource_c556404d := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_c556404d, p_IntegrationObjectID := p_IntegrationObjectID_c556404d, p_Name := p_Name_c556404d, p_DisplayName := p_DisplayName_c556404d, p_Description := p_Description_c556404d, p_Category := p_Category_c556404d, p_Category_Clear := TRUE, p_Type := p_Type_c556404d, p_Length := p_Length_c556404d, p_Precision := p_Precision_c556404d, p_Precision_Clear := TRUE, p_Scale := p_Scale_c556404d, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_c556404d, p_DefaultValue := p_DefaultValue_c556404d, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_c556404d, p_IsUniqueKey := p_IsUniqueKey_c556404d, p_IsReadOnly := p_IsReadOnly_c556404d, p_IsRequired := p_IsRequired_c556404d, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_c556404d, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_c556404d, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_c556404d, p_Configuration := p_Configuration_c556404d, p_Configuration_Clear := TRUE, p_Status := p_Status_c556404d, p_IsCustom := p_IsCustom_c556404d, p_MetadataSource := p_MetadataSource_c556404d);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_bb522409 UUID;
  p_IntegrationObjectID_bb522409 UUID;
  p_Name_bb522409 VARCHAR(255);
  p_DisplayName_bb522409 VARCHAR(255);
  p_Description_bb522409 TEXT;
  p_Category_bb522409 VARCHAR(100);
  p_Type_bb522409 VARCHAR(100);
  p_Length_bb522409 INTEGER;
  p_Precision_bb522409 INTEGER;
  p_Scale_bb522409 INTEGER;
  p_AllowsNull_bb522409 BOOLEAN;
  p_DefaultValue_bb522409 VARCHAR(255);
  p_IsPrimaryKey_bb522409 BOOLEAN;
  p_IsUniqueKey_bb522409 BOOLEAN;
  p_IsReadOnly_bb522409 BOOLEAN;
  p_IsRequired_bb522409 BOOLEAN;
  p_RelatedIntegrationObjectID_bb522409 UUID;
  p_RelatedIntegrationObjectFieldName_bb522409 VARCHAR(255);
  p_Sequence_bb522409 INTEGER;
  p_Configuration_bb522409 TEXT;
  p_Status_bb522409 VARCHAR(25);
  p_IsCustom_bb522409 BOOLEAN;
  p_MetadataSource_bb522409 VARCHAR(20);
BEGIN
  p_ID_bb522409 := '4606D2EB-CC7D-53FF-B7E1-035378F47F35';
  p_IntegrationObjectID_bb522409 := '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF';
  p_Name_bb522409 := 'source-name';
  p_DisplayName_bb522409 := 'Source Name';
  p_Description_bb522409 := 'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.';
  p_Type_bb522409 := 'String';
  p_Length_bb522409 := 500;
  p_AllowsNull_bb522409 := TRUE;
  p_IsPrimaryKey_bb522409 := FALSE;
  p_IsUniqueKey_bb522409 := FALSE;
  p_IsReadOnly_bb522409 := TRUE;
  p_IsRequired_bb522409 := FALSE;
  p_Sequence_bb522409 := 27;
  p_Status_bb522409 := 'Active';
  p_IsCustom_bb522409 := FALSE;
  p_MetadataSource_bb522409 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_bb522409, p_IntegrationObjectID := p_IntegrationObjectID_bb522409, p_Name := p_Name_bb522409, p_DisplayName := p_DisplayName_bb522409, p_Description := p_Description_bb522409, p_Category := p_Category_bb522409, p_Category_Clear := TRUE, p_Type := p_Type_bb522409, p_Length := p_Length_bb522409, p_Precision := p_Precision_bb522409, p_Precision_Clear := TRUE, p_Scale := p_Scale_bb522409, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_bb522409, p_DefaultValue := p_DefaultValue_bb522409, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_bb522409, p_IsUniqueKey := p_IsUniqueKey_bb522409, p_IsReadOnly := p_IsReadOnly_bb522409, p_IsRequired := p_IsRequired_bb522409, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_bb522409, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_bb522409, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_bb522409, p_Configuration := p_Configuration_bb522409, p_Configuration_Clear := TRUE, p_Status := p_Status_bb522409, p_IsCustom := p_IsCustom_bb522409, p_MetadataSource := p_MetadataSource_bb522409);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_8c095baa UUID;
  p_IntegrationObjectID_8c095baa UUID;
  p_Name_8c095baa VARCHAR(255);
  p_DisplayName_8c095baa VARCHAR(255);
  p_Description_8c095baa TEXT;
  p_Category_8c095baa VARCHAR(100);
  p_Type_8c095baa VARCHAR(100);
  p_Length_8c095baa INTEGER;
  p_Precision_8c095baa INTEGER;
  p_Scale_8c095baa INTEGER;
  p_AllowsNull_8c095baa BOOLEAN;
  p_DefaultValue_8c095baa VARCHAR(255);
  p_IsPrimaryKey_8c095baa BOOLEAN;
  p_IsUniqueKey_8c095baa BOOLEAN;
  p_IsReadOnly_8c095baa BOOLEAN;
  p_IsRequired_8c095baa BOOLEAN;
  p_RelatedIntegrationObjectID_8c095baa UUID;
  p_RelatedIntegrationObjectFieldName_8c095baa VARCHAR(255);
  p_Sequence_8c095baa INTEGER;
  p_Configuration_8c095baa TEXT;
  p_Status_8c095baa VARCHAR(25);
  p_IsCustom_8c095baa BOOLEAN;
  p_MetadataSource_8c095baa VARCHAR(20);
BEGIN
  p_ID_8c095baa := '9395F588-4BBE-5082-AF61-95E9AC2E4813';
  p_IntegrationObjectID_8c095baa := '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF';
  p_Name_8c095baa := 'source-orcid';
  p_DisplayName_8c095baa := 'Source Orcid';
  p_Description_8c095baa := 'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.';
  p_Type_8c095baa := 'String';
  p_Length_8c095baa := 19;
  p_AllowsNull_8c095baa := TRUE;
  p_IsPrimaryKey_8c095baa := FALSE;
  p_IsUniqueKey_8c095baa := FALSE;
  p_IsReadOnly_8c095baa := TRUE;
  p_IsRequired_8c095baa := FALSE;
  p_Sequence_8c095baa := 28;
  p_Status_8c095baa := 'Active';
  p_IsCustom_8c095baa := FALSE;
  p_MetadataSource_8c095baa := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_8c095baa, p_IntegrationObjectID := p_IntegrationObjectID_8c095baa, p_Name := p_Name_8c095baa, p_DisplayName := p_DisplayName_8c095baa, p_Description := p_Description_8c095baa, p_Category := p_Category_8c095baa, p_Category_Clear := TRUE, p_Type := p_Type_8c095baa, p_Length := p_Length_8c095baa, p_Precision := p_Precision_8c095baa, p_Precision_Clear := TRUE, p_Scale := p_Scale_8c095baa, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_8c095baa, p_DefaultValue := p_DefaultValue_8c095baa, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_8c095baa, p_IsUniqueKey := p_IsUniqueKey_8c095baa, p_IsReadOnly := p_IsReadOnly_8c095baa, p_IsRequired := p_IsRequired_8c095baa, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_8c095baa, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_8c095baa, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_8c095baa, p_Configuration := p_Configuration_8c095baa, p_Configuration_Clear := TRUE, p_Status := p_Status_8c095baa, p_IsCustom := p_IsCustom_8c095baa, p_MetadataSource := p_MetadataSource_8c095baa);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_7c8ff91b UUID;
  p_IntegrationObjectID_7c8ff91b UUID;
  p_Name_7c8ff91b VARCHAR(255);
  p_DisplayName_7c8ff91b VARCHAR(255);
  p_Description_7c8ff91b TEXT;
  p_Category_7c8ff91b VARCHAR(100);
  p_Type_7c8ff91b VARCHAR(100);
  p_Length_7c8ff91b INTEGER;
  p_Precision_7c8ff91b INTEGER;
  p_Scale_7c8ff91b INTEGER;
  p_AllowsNull_7c8ff91b BOOLEAN;
  p_DefaultValue_7c8ff91b VARCHAR(255);
  p_IsPrimaryKey_7c8ff91b BOOLEAN;
  p_IsUniqueKey_7c8ff91b BOOLEAN;
  p_IsReadOnly_7c8ff91b BOOLEAN;
  p_IsRequired_7c8ff91b BOOLEAN;
  p_RelatedIntegrationObjectID_7c8ff91b UUID;
  p_RelatedIntegrationObjectFieldName_7c8ff91b VARCHAR(255);
  p_Sequence_7c8ff91b INTEGER;
  p_Configuration_7c8ff91b TEXT;
  p_Status_7c8ff91b VARCHAR(25);
  p_IsCustom_7c8ff91b BOOLEAN;
  p_MetadataSource_7c8ff91b VARCHAR(20);
BEGIN
  p_ID_7c8ff91b := '86C43653-DDF5-5585-B1F8-B55369488588';
  p_IntegrationObjectID_7c8ff91b := 'A28BB703-8E34-4725-AF07-CDE7E42EB046';
  p_Name_7c8ff91b := 'start-year';
  p_DisplayName_7c8ff91b := 'Start Year';
  p_Description_7c8ff91b := 'Year of the affiliation start date; ORCID dates are partial, so month/day may be absent.';
  p_Type_7c8ff91b := 'Integer';
  p_AllowsNull_7c8ff91b := TRUE;
  p_IsPrimaryKey_7c8ff91b := FALSE;
  p_IsUniqueKey_7c8ff91b := FALSE;
  p_IsReadOnly_7c8ff91b := TRUE;
  p_IsRequired_7c8ff91b := FALSE;
  p_Sequence_7c8ff91b := 15;
  p_Status_7c8ff91b := 'Active';
  p_IsCustom_7c8ff91b := FALSE;
  p_MetadataSource_7c8ff91b := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_7c8ff91b, p_IntegrationObjectID := p_IntegrationObjectID_7c8ff91b, p_Name := p_Name_7c8ff91b, p_DisplayName := p_DisplayName_7c8ff91b, p_Description := p_Description_7c8ff91b, p_Category := p_Category_7c8ff91b, p_Category_Clear := TRUE, p_Type := p_Type_7c8ff91b, p_Length := p_Length_7c8ff91b, p_Length_Clear := TRUE, p_Precision := p_Precision_7c8ff91b, p_Precision_Clear := TRUE, p_Scale := p_Scale_7c8ff91b, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_7c8ff91b, p_DefaultValue := p_DefaultValue_7c8ff91b, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_7c8ff91b, p_IsUniqueKey := p_IsUniqueKey_7c8ff91b, p_IsReadOnly := p_IsReadOnly_7c8ff91b, p_IsRequired := p_IsRequired_7c8ff91b, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_7c8ff91b, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_7c8ff91b, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_7c8ff91b, p_Configuration := p_Configuration_7c8ff91b, p_Configuration_Clear := TRUE, p_Status := p_Status_7c8ff91b, p_IsCustom := p_IsCustom_7c8ff91b, p_MetadataSource := p_MetadataSource_7c8ff91b);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_be806331 UUID;
  p_IntegrationObjectID_be806331 UUID;
  p_Name_be806331 VARCHAR(255);
  p_DisplayName_be806331 VARCHAR(255);
  p_Description_be806331 TEXT;
  p_Category_be806331 VARCHAR(100);
  p_Type_be806331 VARCHAR(100);
  p_Length_be806331 INTEGER;
  p_Precision_be806331 INTEGER;
  p_Scale_be806331 INTEGER;
  p_AllowsNull_be806331 BOOLEAN;
  p_DefaultValue_be806331 VARCHAR(255);
  p_IsPrimaryKey_be806331 BOOLEAN;
  p_IsUniqueKey_be806331 BOOLEAN;
  p_IsReadOnly_be806331 BOOLEAN;
  p_IsRequired_be806331 BOOLEAN;
  p_RelatedIntegrationObjectID_be806331 UUID;
  p_RelatedIntegrationObjectFieldName_be806331 VARCHAR(255);
  p_Sequence_be806331 INTEGER;
  p_Configuration_be806331 TEXT;
  p_Status_be806331 VARCHAR(25);
  p_IsCustom_be806331 BOOLEAN;
  p_MetadataSource_be806331 VARCHAR(20);
BEGIN
  p_ID_be806331 := '09475DE3-0E97-561B-92A8-E17CB37FDCBA';
  p_IntegrationObjectID_be806331 := 'A28BB703-8E34-4725-AF07-CDE7E42EB046';
  p_Name_be806331 := 'start-month';
  p_DisplayName_be806331 := 'Start Month';
  p_Description_be806331 := 'Month (1-12) of the affiliation start date, when given.';
  p_Type_be806331 := 'Integer';
  p_AllowsNull_be806331 := TRUE;
  p_IsPrimaryKey_be806331 := FALSE;
  p_IsUniqueKey_be806331 := FALSE;
  p_IsReadOnly_be806331 := TRUE;
  p_IsRequired_be806331 := FALSE;
  p_Sequence_be806331 := 16;
  p_Status_be806331 := 'Active';
  p_IsCustom_be806331 := FALSE;
  p_MetadataSource_be806331 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_be806331, p_IntegrationObjectID := p_IntegrationObjectID_be806331, p_Name := p_Name_be806331, p_DisplayName := p_DisplayName_be806331, p_Description := p_Description_be806331, p_Category := p_Category_be806331, p_Category_Clear := TRUE, p_Type := p_Type_be806331, p_Length := p_Length_be806331, p_Length_Clear := TRUE, p_Precision := p_Precision_be806331, p_Precision_Clear := TRUE, p_Scale := p_Scale_be806331, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_be806331, p_DefaultValue := p_DefaultValue_be806331, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_be806331, p_IsUniqueKey := p_IsUniqueKey_be806331, p_IsReadOnly := p_IsReadOnly_be806331, p_IsRequired := p_IsRequired_be806331, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_be806331, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_be806331, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_be806331, p_Configuration := p_Configuration_be806331, p_Configuration_Clear := TRUE, p_Status := p_Status_be806331, p_IsCustom := p_IsCustom_be806331, p_MetadataSource := p_MetadataSource_be806331);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_a2e1456a UUID;
  p_IntegrationObjectID_a2e1456a UUID;
  p_Name_a2e1456a VARCHAR(255);
  p_DisplayName_a2e1456a VARCHAR(255);
  p_Description_a2e1456a TEXT;
  p_Category_a2e1456a VARCHAR(100);
  p_Type_a2e1456a VARCHAR(100);
  p_Length_a2e1456a INTEGER;
  p_Precision_a2e1456a INTEGER;
  p_Scale_a2e1456a INTEGER;
  p_AllowsNull_a2e1456a BOOLEAN;
  p_DefaultValue_a2e1456a VARCHAR(255);
  p_IsPrimaryKey_a2e1456a BOOLEAN;
  p_IsUniqueKey_a2e1456a BOOLEAN;
  p_IsReadOnly_a2e1456a BOOLEAN;
  p_IsRequired_a2e1456a BOOLEAN;
  p_RelatedIntegrationObjectID_a2e1456a UUID;
  p_RelatedIntegrationObjectFieldName_a2e1456a VARCHAR(255);
  p_Sequence_a2e1456a INTEGER;
  p_Configuration_a2e1456a TEXT;
  p_Status_a2e1456a VARCHAR(25);
  p_IsCustom_a2e1456a BOOLEAN;
  p_MetadataSource_a2e1456a VARCHAR(20);
BEGIN
  p_ID_a2e1456a := 'EF682ADE-FDF2-5BDD-B71E-29984E5594FF';
  p_IntegrationObjectID_a2e1456a := 'A28BB703-8E34-4725-AF07-CDE7E42EB046';
  p_Name_a2e1456a := 'start-day';
  p_DisplayName_a2e1456a := 'Start Day';
  p_Description_a2e1456a := 'Day of month of the affiliation start date, when given.';
  p_Type_a2e1456a := 'Integer';
  p_AllowsNull_a2e1456a := TRUE;
  p_IsPrimaryKey_a2e1456a := FALSE;
  p_IsUniqueKey_a2e1456a := FALSE;
  p_IsReadOnly_a2e1456a := TRUE;
  p_IsRequired_a2e1456a := FALSE;
  p_Sequence_a2e1456a := 17;
  p_Status_a2e1456a := 'Active';
  p_IsCustom_a2e1456a := FALSE;
  p_MetadataSource_a2e1456a := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_a2e1456a, p_IntegrationObjectID := p_IntegrationObjectID_a2e1456a, p_Name := p_Name_a2e1456a, p_DisplayName := p_DisplayName_a2e1456a, p_Description := p_Description_a2e1456a, p_Category := p_Category_a2e1456a, p_Category_Clear := TRUE, p_Type := p_Type_a2e1456a, p_Length := p_Length_a2e1456a, p_Length_Clear := TRUE, p_Precision := p_Precision_a2e1456a, p_Precision_Clear := TRUE, p_Scale := p_Scale_a2e1456a, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_a2e1456a, p_DefaultValue := p_DefaultValue_a2e1456a, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_a2e1456a, p_IsUniqueKey := p_IsUniqueKey_a2e1456a, p_IsReadOnly := p_IsReadOnly_a2e1456a, p_IsRequired := p_IsRequired_a2e1456a, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_a2e1456a, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_a2e1456a, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_a2e1456a, p_Configuration := p_Configuration_a2e1456a, p_Configuration_Clear := TRUE, p_Status := p_Status_a2e1456a, p_IsCustom := p_IsCustom_a2e1456a, p_MetadataSource := p_MetadataSource_a2e1456a);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_af941700 UUID;
  p_IntegrationObjectID_af941700 UUID;
  p_Name_af941700 VARCHAR(255);
  p_DisplayName_af941700 VARCHAR(255);
  p_Description_af941700 TEXT;
  p_Category_af941700 VARCHAR(100);
  p_Type_af941700 VARCHAR(100);
  p_Length_af941700 INTEGER;
  p_Precision_af941700 INTEGER;
  p_Scale_af941700 INTEGER;
  p_AllowsNull_af941700 BOOLEAN;
  p_DefaultValue_af941700 VARCHAR(255);
  p_IsPrimaryKey_af941700 BOOLEAN;
  p_IsUniqueKey_af941700 BOOLEAN;
  p_IsReadOnly_af941700 BOOLEAN;
  p_IsRequired_af941700 BOOLEAN;
  p_RelatedIntegrationObjectID_af941700 UUID;
  p_RelatedIntegrationObjectFieldName_af941700 VARCHAR(255);
  p_Sequence_af941700 INTEGER;
  p_Configuration_af941700 TEXT;
  p_Status_af941700 VARCHAR(25);
  p_IsCustom_af941700 BOOLEAN;
  p_MetadataSource_af941700 VARCHAR(20);
BEGIN
  p_ID_af941700 := '1DEFF9AF-CDA3-5DF2-81AE-22E15968A501';
  p_IntegrationObjectID_af941700 := 'A28BB703-8E34-4725-AF07-CDE7E42EB046';
  p_Name_af941700 := 'end-year';
  p_DisplayName_af941700 := 'End Year';
  p_Description_af941700 := 'Year of the affiliation end date; empty for a current/ongoing role; ORCID dates are partial, so month/day may be absent.';
  p_Type_af941700 := 'Integer';
  p_AllowsNull_af941700 := TRUE;
  p_IsPrimaryKey_af941700 := FALSE;
  p_IsUniqueKey_af941700 := FALSE;
  p_IsReadOnly_af941700 := TRUE;
  p_IsRequired_af941700 := FALSE;
  p_Sequence_af941700 := 18;
  p_Status_af941700 := 'Active';
  p_IsCustom_af941700 := FALSE;
  p_MetadataSource_af941700 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_af941700, p_IntegrationObjectID := p_IntegrationObjectID_af941700, p_Name := p_Name_af941700, p_DisplayName := p_DisplayName_af941700, p_Description := p_Description_af941700, p_Category := p_Category_af941700, p_Category_Clear := TRUE, p_Type := p_Type_af941700, p_Length := p_Length_af941700, p_Length_Clear := TRUE, p_Precision := p_Precision_af941700, p_Precision_Clear := TRUE, p_Scale := p_Scale_af941700, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_af941700, p_DefaultValue := p_DefaultValue_af941700, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_af941700, p_IsUniqueKey := p_IsUniqueKey_af941700, p_IsReadOnly := p_IsReadOnly_af941700, p_IsRequired := p_IsRequired_af941700, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_af941700, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_af941700, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_af941700, p_Configuration := p_Configuration_af941700, p_Configuration_Clear := TRUE, p_Status := p_Status_af941700, p_IsCustom := p_IsCustom_af941700, p_MetadataSource := p_MetadataSource_af941700);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_f72920c9 UUID;
  p_IntegrationObjectID_f72920c9 UUID;
  p_Name_f72920c9 VARCHAR(255);
  p_DisplayName_f72920c9 VARCHAR(255);
  p_Description_f72920c9 TEXT;
  p_Category_f72920c9 VARCHAR(100);
  p_Type_f72920c9 VARCHAR(100);
  p_Length_f72920c9 INTEGER;
  p_Precision_f72920c9 INTEGER;
  p_Scale_f72920c9 INTEGER;
  p_AllowsNull_f72920c9 BOOLEAN;
  p_DefaultValue_f72920c9 VARCHAR(255);
  p_IsPrimaryKey_f72920c9 BOOLEAN;
  p_IsUniqueKey_f72920c9 BOOLEAN;
  p_IsReadOnly_f72920c9 BOOLEAN;
  p_IsRequired_f72920c9 BOOLEAN;
  p_RelatedIntegrationObjectID_f72920c9 UUID;
  p_RelatedIntegrationObjectFieldName_f72920c9 VARCHAR(255);
  p_Sequence_f72920c9 INTEGER;
  p_Configuration_f72920c9 TEXT;
  p_Status_f72920c9 VARCHAR(25);
  p_IsCustom_f72920c9 BOOLEAN;
  p_MetadataSource_f72920c9 VARCHAR(20);
BEGIN
  p_ID_f72920c9 := 'CA3DDEAE-AFA9-5510-8537-A2AE9C8C1471';
  p_IntegrationObjectID_f72920c9 := 'A28BB703-8E34-4725-AF07-CDE7E42EB046';
  p_Name_f72920c9 := 'end-month';
  p_DisplayName_f72920c9 := 'End Month';
  p_Description_f72920c9 := 'Month (1-12) of the affiliation end date; empty for a current/ongoing role, when given.';
  p_Type_f72920c9 := 'Integer';
  p_AllowsNull_f72920c9 := TRUE;
  p_IsPrimaryKey_f72920c9 := FALSE;
  p_IsUniqueKey_f72920c9 := FALSE;
  p_IsReadOnly_f72920c9 := TRUE;
  p_IsRequired_f72920c9 := FALSE;
  p_Sequence_f72920c9 := 19;
  p_Status_f72920c9 := 'Active';
  p_IsCustom_f72920c9 := FALSE;
  p_MetadataSource_f72920c9 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_f72920c9, p_IntegrationObjectID := p_IntegrationObjectID_f72920c9, p_Name := p_Name_f72920c9, p_DisplayName := p_DisplayName_f72920c9, p_Description := p_Description_f72920c9, p_Category := p_Category_f72920c9, p_Category_Clear := TRUE, p_Type := p_Type_f72920c9, p_Length := p_Length_f72920c9, p_Length_Clear := TRUE, p_Precision := p_Precision_f72920c9, p_Precision_Clear := TRUE, p_Scale := p_Scale_f72920c9, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_f72920c9, p_DefaultValue := p_DefaultValue_f72920c9, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_f72920c9, p_IsUniqueKey := p_IsUniqueKey_f72920c9, p_IsReadOnly := p_IsReadOnly_f72920c9, p_IsRequired := p_IsRequired_f72920c9, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_f72920c9, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_f72920c9, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_f72920c9, p_Configuration := p_Configuration_f72920c9, p_Configuration_Clear := TRUE, p_Status := p_Status_f72920c9, p_IsCustom := p_IsCustom_f72920c9, p_MetadataSource := p_MetadataSource_f72920c9);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_7b351034 UUID;
  p_IntegrationObjectID_7b351034 UUID;
  p_Name_7b351034 VARCHAR(255);
  p_DisplayName_7b351034 VARCHAR(255);
  p_Description_7b351034 TEXT;
  p_Category_7b351034 VARCHAR(100);
  p_Type_7b351034 VARCHAR(100);
  p_Length_7b351034 INTEGER;
  p_Precision_7b351034 INTEGER;
  p_Scale_7b351034 INTEGER;
  p_AllowsNull_7b351034 BOOLEAN;
  p_DefaultValue_7b351034 VARCHAR(255);
  p_IsPrimaryKey_7b351034 BOOLEAN;
  p_IsUniqueKey_7b351034 BOOLEAN;
  p_IsReadOnly_7b351034 BOOLEAN;
  p_IsRequired_7b351034 BOOLEAN;
  p_RelatedIntegrationObjectID_7b351034 UUID;
  p_RelatedIntegrationObjectFieldName_7b351034 VARCHAR(255);
  p_Sequence_7b351034 INTEGER;
  p_Configuration_7b351034 TEXT;
  p_Status_7b351034 VARCHAR(25);
  p_IsCustom_7b351034 BOOLEAN;
  p_MetadataSource_7b351034 VARCHAR(20);
BEGIN
  p_ID_7b351034 := '47BAC76E-3C87-55C7-AA74-76CE778DA7B6';
  p_IntegrationObjectID_7b351034 := 'A28BB703-8E34-4725-AF07-CDE7E42EB046';
  p_Name_7b351034 := 'end-day';
  p_DisplayName_7b351034 := 'End Day';
  p_Description_7b351034 := 'Day of month of the affiliation end date; empty for a current/ongoing role, when given.';
  p_Type_7b351034 := 'Integer';
  p_AllowsNull_7b351034 := TRUE;
  p_IsPrimaryKey_7b351034 := FALSE;
  p_IsUniqueKey_7b351034 := FALSE;
  p_IsReadOnly_7b351034 := TRUE;
  p_IsRequired_7b351034 := FALSE;
  p_Sequence_7b351034 := 20;
  p_Status_7b351034 := 'Active';
  p_IsCustom_7b351034 := FALSE;
  p_MetadataSource_7b351034 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_7b351034, p_IntegrationObjectID := p_IntegrationObjectID_7b351034, p_Name := p_Name_7b351034, p_DisplayName := p_DisplayName_7b351034, p_Description := p_Description_7b351034, p_Category := p_Category_7b351034, p_Category_Clear := TRUE, p_Type := p_Type_7b351034, p_Length := p_Length_7b351034, p_Length_Clear := TRUE, p_Precision := p_Precision_7b351034, p_Precision_Clear := TRUE, p_Scale := p_Scale_7b351034, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_7b351034, p_DefaultValue := p_DefaultValue_7b351034, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_7b351034, p_IsUniqueKey := p_IsUniqueKey_7b351034, p_IsReadOnly := p_IsReadOnly_7b351034, p_IsRequired := p_IsRequired_7b351034, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_7b351034, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_7b351034, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_7b351034, p_Configuration := p_Configuration_7b351034, p_Configuration_Clear := TRUE, p_Status := p_Status_7b351034, p_IsCustom := p_IsCustom_7b351034, p_MetadataSource := p_MetadataSource_7b351034);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_501fc807 UUID;
  p_IntegrationObjectID_501fc807 UUID;
  p_Name_501fc807 VARCHAR(255);
  p_DisplayName_501fc807 VARCHAR(255);
  p_Description_501fc807 TEXT;
  p_Category_501fc807 VARCHAR(100);
  p_Type_501fc807 VARCHAR(100);
  p_Length_501fc807 INTEGER;
  p_Precision_501fc807 INTEGER;
  p_Scale_501fc807 INTEGER;
  p_AllowsNull_501fc807 BOOLEAN;
  p_DefaultValue_501fc807 VARCHAR(255);
  p_IsPrimaryKey_501fc807 BOOLEAN;
  p_IsUniqueKey_501fc807 BOOLEAN;
  p_IsReadOnly_501fc807 BOOLEAN;
  p_IsRequired_501fc807 BOOLEAN;
  p_RelatedIntegrationObjectID_501fc807 UUID;
  p_RelatedIntegrationObjectFieldName_501fc807 VARCHAR(255);
  p_Sequence_501fc807 INTEGER;
  p_Configuration_501fc807 TEXT;
  p_Status_501fc807 VARCHAR(25);
  p_IsCustom_501fc807 BOOLEAN;
  p_MetadataSource_501fc807 VARCHAR(20);
BEGIN
  p_ID_501fc807 := '2E047456-4179-508E-A13F-C530EACF6E86';
  p_IntegrationObjectID_501fc807 := 'A28BB703-8E34-4725-AF07-CDE7E42EB046';
  p_Name_501fc807 := 'organization-name';
  p_DisplayName_501fc807 := 'Organization Name';
  p_Description_501fc807 := 'Name of the organization. Lifted from organization.name.';
  p_Type_501fc807 := 'String';
  p_Length_501fc807 := 1000;
  p_AllowsNull_501fc807 := TRUE;
  p_IsPrimaryKey_501fc807 := FALSE;
  p_IsUniqueKey_501fc807 := FALSE;
  p_IsReadOnly_501fc807 := TRUE;
  p_IsRequired_501fc807 := FALSE;
  p_Sequence_501fc807 := 21;
  p_Status_501fc807 := 'Active';
  p_IsCustom_501fc807 := FALSE;
  p_MetadataSource_501fc807 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_501fc807, p_IntegrationObjectID := p_IntegrationObjectID_501fc807, p_Name := p_Name_501fc807, p_DisplayName := p_DisplayName_501fc807, p_Description := p_Description_501fc807, p_Category := p_Category_501fc807, p_Category_Clear := TRUE, p_Type := p_Type_501fc807, p_Length := p_Length_501fc807, p_Precision := p_Precision_501fc807, p_Precision_Clear := TRUE, p_Scale := p_Scale_501fc807, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_501fc807, p_DefaultValue := p_DefaultValue_501fc807, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_501fc807, p_IsUniqueKey := p_IsUniqueKey_501fc807, p_IsReadOnly := p_IsReadOnly_501fc807, p_IsRequired := p_IsRequired_501fc807, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_501fc807, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_501fc807, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_501fc807, p_Configuration := p_Configuration_501fc807, p_Configuration_Clear := TRUE, p_Status := p_Status_501fc807, p_IsCustom := p_IsCustom_501fc807, p_MetadataSource := p_MetadataSource_501fc807);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_39e57c49 UUID;
  p_IntegrationObjectID_39e57c49 UUID;
  p_Name_39e57c49 VARCHAR(255);
  p_DisplayName_39e57c49 VARCHAR(255);
  p_Description_39e57c49 TEXT;
  p_Category_39e57c49 VARCHAR(100);
  p_Type_39e57c49 VARCHAR(100);
  p_Length_39e57c49 INTEGER;
  p_Precision_39e57c49 INTEGER;
  p_Scale_39e57c49 INTEGER;
  p_AllowsNull_39e57c49 BOOLEAN;
  p_DefaultValue_39e57c49 VARCHAR(255);
  p_IsPrimaryKey_39e57c49 BOOLEAN;
  p_IsUniqueKey_39e57c49 BOOLEAN;
  p_IsReadOnly_39e57c49 BOOLEAN;
  p_IsRequired_39e57c49 BOOLEAN;
  p_RelatedIntegrationObjectID_39e57c49 UUID;
  p_RelatedIntegrationObjectFieldName_39e57c49 VARCHAR(255);
  p_Sequence_39e57c49 INTEGER;
  p_Configuration_39e57c49 TEXT;
  p_Status_39e57c49 VARCHAR(25);
  p_IsCustom_39e57c49 BOOLEAN;
  p_MetadataSource_39e57c49 VARCHAR(20);
BEGIN
  p_ID_39e57c49 := '9B89B77A-CC33-5C26-969F-16ACB6591CB1';
  p_IntegrationObjectID_39e57c49 := 'A28BB703-8E34-4725-AF07-CDE7E42EB046';
  p_Name_39e57c49 := 'organization-city';
  p_DisplayName_39e57c49 := 'Organization City';
  p_Description_39e57c49 := 'City of the organization. Lifted from organization.address.city.';
  p_Type_39e57c49 := 'String';
  p_Length_39e57c49 := 255;
  p_AllowsNull_39e57c49 := TRUE;
  p_IsPrimaryKey_39e57c49 := FALSE;
  p_IsUniqueKey_39e57c49 := FALSE;
  p_IsReadOnly_39e57c49 := TRUE;
  p_IsRequired_39e57c49 := FALSE;
  p_Sequence_39e57c49 := 22;
  p_Status_39e57c49 := 'Active';
  p_IsCustom_39e57c49 := FALSE;
  p_MetadataSource_39e57c49 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_39e57c49, p_IntegrationObjectID := p_IntegrationObjectID_39e57c49, p_Name := p_Name_39e57c49, p_DisplayName := p_DisplayName_39e57c49, p_Description := p_Description_39e57c49, p_Category := p_Category_39e57c49, p_Category_Clear := TRUE, p_Type := p_Type_39e57c49, p_Length := p_Length_39e57c49, p_Precision := p_Precision_39e57c49, p_Precision_Clear := TRUE, p_Scale := p_Scale_39e57c49, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_39e57c49, p_DefaultValue := p_DefaultValue_39e57c49, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_39e57c49, p_IsUniqueKey := p_IsUniqueKey_39e57c49, p_IsReadOnly := p_IsReadOnly_39e57c49, p_IsRequired := p_IsRequired_39e57c49, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_39e57c49, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_39e57c49, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_39e57c49, p_Configuration := p_Configuration_39e57c49, p_Configuration_Clear := TRUE, p_Status := p_Status_39e57c49, p_IsCustom := p_IsCustom_39e57c49, p_MetadataSource := p_MetadataSource_39e57c49);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_1991bc0e UUID;
  p_IntegrationObjectID_1991bc0e UUID;
  p_Name_1991bc0e VARCHAR(255);
  p_DisplayName_1991bc0e VARCHAR(255);
  p_Description_1991bc0e TEXT;
  p_Category_1991bc0e VARCHAR(100);
  p_Type_1991bc0e VARCHAR(100);
  p_Length_1991bc0e INTEGER;
  p_Precision_1991bc0e INTEGER;
  p_Scale_1991bc0e INTEGER;
  p_AllowsNull_1991bc0e BOOLEAN;
  p_DefaultValue_1991bc0e VARCHAR(255);
  p_IsPrimaryKey_1991bc0e BOOLEAN;
  p_IsUniqueKey_1991bc0e BOOLEAN;
  p_IsReadOnly_1991bc0e BOOLEAN;
  p_IsRequired_1991bc0e BOOLEAN;
  p_RelatedIntegrationObjectID_1991bc0e UUID;
  p_RelatedIntegrationObjectFieldName_1991bc0e VARCHAR(255);
  p_Sequence_1991bc0e INTEGER;
  p_Configuration_1991bc0e TEXT;
  p_Status_1991bc0e VARCHAR(25);
  p_IsCustom_1991bc0e BOOLEAN;
  p_MetadataSource_1991bc0e VARCHAR(20);
BEGIN
  p_ID_1991bc0e := '837D9AEA-7C25-5286-B1A0-48D72BEC4E27';
  p_IntegrationObjectID_1991bc0e := 'A28BB703-8E34-4725-AF07-CDE7E42EB046';
  p_Name_1991bc0e := 'organization-region';
  p_DisplayName_1991bc0e := 'Organization Region';
  p_Description_1991bc0e := 'Region/state of the organization. Lifted from organization.address.region.';
  p_Type_1991bc0e := 'String';
  p_Length_1991bc0e := 255;
  p_AllowsNull_1991bc0e := TRUE;
  p_IsPrimaryKey_1991bc0e := FALSE;
  p_IsUniqueKey_1991bc0e := FALSE;
  p_IsReadOnly_1991bc0e := TRUE;
  p_IsRequired_1991bc0e := FALSE;
  p_Sequence_1991bc0e := 23;
  p_Status_1991bc0e := 'Active';
  p_IsCustom_1991bc0e := FALSE;
  p_MetadataSource_1991bc0e := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_1991bc0e, p_IntegrationObjectID := p_IntegrationObjectID_1991bc0e, p_Name := p_Name_1991bc0e, p_DisplayName := p_DisplayName_1991bc0e, p_Description := p_Description_1991bc0e, p_Category := p_Category_1991bc0e, p_Category_Clear := TRUE, p_Type := p_Type_1991bc0e, p_Length := p_Length_1991bc0e, p_Precision := p_Precision_1991bc0e, p_Precision_Clear := TRUE, p_Scale := p_Scale_1991bc0e, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_1991bc0e, p_DefaultValue := p_DefaultValue_1991bc0e, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_1991bc0e, p_IsUniqueKey := p_IsUniqueKey_1991bc0e, p_IsReadOnly := p_IsReadOnly_1991bc0e, p_IsRequired := p_IsRequired_1991bc0e, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_1991bc0e, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_1991bc0e, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_1991bc0e, p_Configuration := p_Configuration_1991bc0e, p_Configuration_Clear := TRUE, p_Status := p_Status_1991bc0e, p_IsCustom := p_IsCustom_1991bc0e, p_MetadataSource := p_MetadataSource_1991bc0e);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_c0e176bb UUID;
  p_IntegrationObjectID_c0e176bb UUID;
  p_Name_c0e176bb VARCHAR(255);
  p_DisplayName_c0e176bb VARCHAR(255);
  p_Description_c0e176bb TEXT;
  p_Category_c0e176bb VARCHAR(100);
  p_Type_c0e176bb VARCHAR(100);
  p_Length_c0e176bb INTEGER;
  p_Precision_c0e176bb INTEGER;
  p_Scale_c0e176bb INTEGER;
  p_AllowsNull_c0e176bb BOOLEAN;
  p_DefaultValue_c0e176bb VARCHAR(255);
  p_IsPrimaryKey_c0e176bb BOOLEAN;
  p_IsUniqueKey_c0e176bb BOOLEAN;
  p_IsReadOnly_c0e176bb BOOLEAN;
  p_IsRequired_c0e176bb BOOLEAN;
  p_RelatedIntegrationObjectID_c0e176bb UUID;
  p_RelatedIntegrationObjectFieldName_c0e176bb VARCHAR(255);
  p_Sequence_c0e176bb INTEGER;
  p_Configuration_c0e176bb TEXT;
  p_Status_c0e176bb VARCHAR(25);
  p_IsCustom_c0e176bb BOOLEAN;
  p_MetadataSource_c0e176bb VARCHAR(20);
BEGIN
  p_ID_c0e176bb := '4DE67A58-6DFA-5973-8776-D242F7AA6A39';
  p_IntegrationObjectID_c0e176bb := 'A28BB703-8E34-4725-AF07-CDE7E42EB046';
  p_Name_c0e176bb := 'organization-country';
  p_DisplayName_c0e176bb := 'Organization Country';
  p_Description_c0e176bb := 'ISO country code of the organization. Lifted from organization.address.country.';
  p_Type_c0e176bb := 'String';
  p_Length_c0e176bb := 50;
  p_AllowsNull_c0e176bb := TRUE;
  p_IsPrimaryKey_c0e176bb := FALSE;
  p_IsUniqueKey_c0e176bb := FALSE;
  p_IsReadOnly_c0e176bb := TRUE;
  p_IsRequired_c0e176bb := FALSE;
  p_Sequence_c0e176bb := 24;
  p_Status_c0e176bb := 'Active';
  p_IsCustom_c0e176bb := FALSE;
  p_MetadataSource_c0e176bb := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_c0e176bb, p_IntegrationObjectID := p_IntegrationObjectID_c0e176bb, p_Name := p_Name_c0e176bb, p_DisplayName := p_DisplayName_c0e176bb, p_Description := p_Description_c0e176bb, p_Category := p_Category_c0e176bb, p_Category_Clear := TRUE, p_Type := p_Type_c0e176bb, p_Length := p_Length_c0e176bb, p_Precision := p_Precision_c0e176bb, p_Precision_Clear := TRUE, p_Scale := p_Scale_c0e176bb, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_c0e176bb, p_DefaultValue := p_DefaultValue_c0e176bb, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_c0e176bb, p_IsUniqueKey := p_IsUniqueKey_c0e176bb, p_IsReadOnly := p_IsReadOnly_c0e176bb, p_IsRequired := p_IsRequired_c0e176bb, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_c0e176bb, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_c0e176bb, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_c0e176bb, p_Configuration := p_Configuration_c0e176bb, p_Configuration_Clear := TRUE, p_Status := p_Status_c0e176bb, p_IsCustom := p_IsCustom_c0e176bb, p_MetadataSource := p_MetadataSource_c0e176bb);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_8593dd9f UUID;
  p_IntegrationObjectID_8593dd9f UUID;
  p_Name_8593dd9f VARCHAR(255);
  p_DisplayName_8593dd9f VARCHAR(255);
  p_Description_8593dd9f TEXT;
  p_Category_8593dd9f VARCHAR(100);
  p_Type_8593dd9f VARCHAR(100);
  p_Length_8593dd9f INTEGER;
  p_Precision_8593dd9f INTEGER;
  p_Scale_8593dd9f INTEGER;
  p_AllowsNull_8593dd9f BOOLEAN;
  p_DefaultValue_8593dd9f VARCHAR(255);
  p_IsPrimaryKey_8593dd9f BOOLEAN;
  p_IsUniqueKey_8593dd9f BOOLEAN;
  p_IsReadOnly_8593dd9f BOOLEAN;
  p_IsRequired_8593dd9f BOOLEAN;
  p_RelatedIntegrationObjectID_8593dd9f UUID;
  p_RelatedIntegrationObjectFieldName_8593dd9f VARCHAR(255);
  p_Sequence_8593dd9f INTEGER;
  p_Configuration_8593dd9f TEXT;
  p_Status_8593dd9f VARCHAR(25);
  p_IsCustom_8593dd9f BOOLEAN;
  p_MetadataSource_8593dd9f VARCHAR(20);
BEGIN
  p_ID_8593dd9f := '5AAE5894-FAA4-5A59-8F5F-FA03CE2A1120';
  p_IntegrationObjectID_8593dd9f := 'A28BB703-8E34-4725-AF07-CDE7E42EB046';
  p_Name_8593dd9f := 'organization-disambiguated-id';
  p_DisplayName_8593dd9f := 'Organization Disambiguated Id';
  p_Description_8593dd9f := 'Canonical identifier of the organization in the disambiguation source (e.g. a RINGGOLD or ROR id), so the same institution matches across records.';
  p_Type_8593dd9f := 'String';
  p_Length_8593dd9f := 255;
  p_AllowsNull_8593dd9f := TRUE;
  p_IsPrimaryKey_8593dd9f := FALSE;
  p_IsUniqueKey_8593dd9f := FALSE;
  p_IsReadOnly_8593dd9f := TRUE;
  p_IsRequired_8593dd9f := FALSE;
  p_Sequence_8593dd9f := 25;
  p_Status_8593dd9f := 'Active';
  p_IsCustom_8593dd9f := FALSE;
  p_MetadataSource_8593dd9f := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_8593dd9f, p_IntegrationObjectID := p_IntegrationObjectID_8593dd9f, p_Name := p_Name_8593dd9f, p_DisplayName := p_DisplayName_8593dd9f, p_Description := p_Description_8593dd9f, p_Category := p_Category_8593dd9f, p_Category_Clear := TRUE, p_Type := p_Type_8593dd9f, p_Length := p_Length_8593dd9f, p_Precision := p_Precision_8593dd9f, p_Precision_Clear := TRUE, p_Scale := p_Scale_8593dd9f, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_8593dd9f, p_DefaultValue := p_DefaultValue_8593dd9f, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_8593dd9f, p_IsUniqueKey := p_IsUniqueKey_8593dd9f, p_IsReadOnly := p_IsReadOnly_8593dd9f, p_IsRequired := p_IsRequired_8593dd9f, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_8593dd9f, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_8593dd9f, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_8593dd9f, p_Configuration := p_Configuration_8593dd9f, p_Configuration_Clear := TRUE, p_Status := p_Status_8593dd9f, p_IsCustom := p_IsCustom_8593dd9f, p_MetadataSource := p_MetadataSource_8593dd9f);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_11317236 UUID;
  p_IntegrationObjectID_11317236 UUID;
  p_Name_11317236 VARCHAR(255);
  p_DisplayName_11317236 VARCHAR(255);
  p_Description_11317236 TEXT;
  p_Category_11317236 VARCHAR(100);
  p_Type_11317236 VARCHAR(100);
  p_Length_11317236 INTEGER;
  p_Precision_11317236 INTEGER;
  p_Scale_11317236 INTEGER;
  p_AllowsNull_11317236 BOOLEAN;
  p_DefaultValue_11317236 VARCHAR(255);
  p_IsPrimaryKey_11317236 BOOLEAN;
  p_IsUniqueKey_11317236 BOOLEAN;
  p_IsReadOnly_11317236 BOOLEAN;
  p_IsRequired_11317236 BOOLEAN;
  p_RelatedIntegrationObjectID_11317236 UUID;
  p_RelatedIntegrationObjectFieldName_11317236 VARCHAR(255);
  p_Sequence_11317236 INTEGER;
  p_Configuration_11317236 TEXT;
  p_Status_11317236 VARCHAR(25);
  p_IsCustom_11317236 BOOLEAN;
  p_MetadataSource_11317236 VARCHAR(20);
BEGIN
  p_ID_11317236 := '2BB23DA0-72D0-58BF-8975-CDF5F4CE080F';
  p_IntegrationObjectID_11317236 := 'A28BB703-8E34-4725-AF07-CDE7E42EB046';
  p_Name_11317236 := 'organization-disambiguation-source';
  p_DisplayName_11317236 := 'Organization Disambiguation Source';
  p_Description_11317236 := 'Registry the disambiguated id comes from (RINGGOLD, ROR, FUNDREF, GRID, LEI).';
  p_Type_11317236 := 'String';
  p_Length_11317236 := 100;
  p_AllowsNull_11317236 := TRUE;
  p_IsPrimaryKey_11317236 := FALSE;
  p_IsUniqueKey_11317236 := FALSE;
  p_IsReadOnly_11317236 := TRUE;
  p_IsRequired_11317236 := FALSE;
  p_Sequence_11317236 := 26;
  p_Status_11317236 := 'Active';
  p_IsCustom_11317236 := FALSE;
  p_MetadataSource_11317236 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_11317236, p_IntegrationObjectID := p_IntegrationObjectID_11317236, p_Name := p_Name_11317236, p_DisplayName := p_DisplayName_11317236, p_Description := p_Description_11317236, p_Category := p_Category_11317236, p_Category_Clear := TRUE, p_Type := p_Type_11317236, p_Length := p_Length_11317236, p_Precision := p_Precision_11317236, p_Precision_Clear := TRUE, p_Scale := p_Scale_11317236, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_11317236, p_DefaultValue := p_DefaultValue_11317236, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_11317236, p_IsUniqueKey := p_IsUniqueKey_11317236, p_IsReadOnly := p_IsReadOnly_11317236, p_IsRequired := p_IsRequired_11317236, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_11317236, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_11317236, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_11317236, p_Configuration := p_Configuration_11317236, p_Configuration_Clear := TRUE, p_Status := p_Status_11317236, p_IsCustom := p_IsCustom_11317236, p_MetadataSource := p_MetadataSource_11317236);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_7e7b427f UUID;
  p_IntegrationObjectID_7e7b427f UUID;
  p_Name_7e7b427f VARCHAR(255);
  p_DisplayName_7e7b427f VARCHAR(255);
  p_Description_7e7b427f TEXT;
  p_Category_7e7b427f VARCHAR(100);
  p_Type_7e7b427f VARCHAR(100);
  p_Length_7e7b427f INTEGER;
  p_Precision_7e7b427f INTEGER;
  p_Scale_7e7b427f INTEGER;
  p_AllowsNull_7e7b427f BOOLEAN;
  p_DefaultValue_7e7b427f VARCHAR(255);
  p_IsPrimaryKey_7e7b427f BOOLEAN;
  p_IsUniqueKey_7e7b427f BOOLEAN;
  p_IsReadOnly_7e7b427f BOOLEAN;
  p_IsRequired_7e7b427f BOOLEAN;
  p_RelatedIntegrationObjectID_7e7b427f UUID;
  p_RelatedIntegrationObjectFieldName_7e7b427f VARCHAR(255);
  p_Sequence_7e7b427f INTEGER;
  p_Configuration_7e7b427f TEXT;
  p_Status_7e7b427f VARCHAR(25);
  p_IsCustom_7e7b427f BOOLEAN;
  p_MetadataSource_7e7b427f VARCHAR(20);
BEGIN
  p_ID_7e7b427f := '1FDA019D-BE9D-5250-8C60-8DC2D7379AA9';
  p_IntegrationObjectID_7e7b427f := 'A28BB703-8E34-4725-AF07-CDE7E42EB046';
  p_Name_7e7b427f := 'source-name';
  p_DisplayName_7e7b427f := 'Source Name';
  p_Description_7e7b427f := 'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.';
  p_Type_7e7b427f := 'String';
  p_Length_7e7b427f := 500;
  p_AllowsNull_7e7b427f := TRUE;
  p_IsPrimaryKey_7e7b427f := FALSE;
  p_IsUniqueKey_7e7b427f := FALSE;
  p_IsReadOnly_7e7b427f := TRUE;
  p_IsRequired_7e7b427f := FALSE;
  p_Sequence_7e7b427f := 27;
  p_Status_7e7b427f := 'Active';
  p_IsCustom_7e7b427f := FALSE;
  p_MetadataSource_7e7b427f := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_7e7b427f, p_IntegrationObjectID := p_IntegrationObjectID_7e7b427f, p_Name := p_Name_7e7b427f, p_DisplayName := p_DisplayName_7e7b427f, p_Description := p_Description_7e7b427f, p_Category := p_Category_7e7b427f, p_Category_Clear := TRUE, p_Type := p_Type_7e7b427f, p_Length := p_Length_7e7b427f, p_Precision := p_Precision_7e7b427f, p_Precision_Clear := TRUE, p_Scale := p_Scale_7e7b427f, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_7e7b427f, p_DefaultValue := p_DefaultValue_7e7b427f, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_7e7b427f, p_IsUniqueKey := p_IsUniqueKey_7e7b427f, p_IsReadOnly := p_IsReadOnly_7e7b427f, p_IsRequired := p_IsRequired_7e7b427f, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_7e7b427f, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_7e7b427f, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_7e7b427f, p_Configuration := p_Configuration_7e7b427f, p_Configuration_Clear := TRUE, p_Status := p_Status_7e7b427f, p_IsCustom := p_IsCustom_7e7b427f, p_MetadataSource := p_MetadataSource_7e7b427f);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_b66b265f UUID;
  p_IntegrationObjectID_b66b265f UUID;
  p_Name_b66b265f VARCHAR(255);
  p_DisplayName_b66b265f VARCHAR(255);
  p_Description_b66b265f TEXT;
  p_Category_b66b265f VARCHAR(100);
  p_Type_b66b265f VARCHAR(100);
  p_Length_b66b265f INTEGER;
  p_Precision_b66b265f INTEGER;
  p_Scale_b66b265f INTEGER;
  p_AllowsNull_b66b265f BOOLEAN;
  p_DefaultValue_b66b265f VARCHAR(255);
  p_IsPrimaryKey_b66b265f BOOLEAN;
  p_IsUniqueKey_b66b265f BOOLEAN;
  p_IsReadOnly_b66b265f BOOLEAN;
  p_IsRequired_b66b265f BOOLEAN;
  p_RelatedIntegrationObjectID_b66b265f UUID;
  p_RelatedIntegrationObjectFieldName_b66b265f VARCHAR(255);
  p_Sequence_b66b265f INTEGER;
  p_Configuration_b66b265f TEXT;
  p_Status_b66b265f VARCHAR(25);
  p_IsCustom_b66b265f BOOLEAN;
  p_MetadataSource_b66b265f VARCHAR(20);
BEGIN
  p_ID_b66b265f := '3E84687E-286F-5D7C-8DCE-0C212F628852';
  p_IntegrationObjectID_b66b265f := 'A28BB703-8E34-4725-AF07-CDE7E42EB046';
  p_Name_b66b265f := 'source-orcid';
  p_DisplayName_b66b265f := 'Source Orcid';
  p_Description_b66b265f := 'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.';
  p_Type_b66b265f := 'String';
  p_Length_b66b265f := 19;
  p_AllowsNull_b66b265f := TRUE;
  p_IsPrimaryKey_b66b265f := FALSE;
  p_IsUniqueKey_b66b265f := FALSE;
  p_IsReadOnly_b66b265f := TRUE;
  p_IsRequired_b66b265f := FALSE;
  p_Sequence_b66b265f := 28;
  p_Status_b66b265f := 'Active';
  p_IsCustom_b66b265f := FALSE;
  p_MetadataSource_b66b265f := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_b66b265f, p_IntegrationObjectID := p_IntegrationObjectID_b66b265f, p_Name := p_Name_b66b265f, p_DisplayName := p_DisplayName_b66b265f, p_Description := p_Description_b66b265f, p_Category := p_Category_b66b265f, p_Category_Clear := TRUE, p_Type := p_Type_b66b265f, p_Length := p_Length_b66b265f, p_Precision := p_Precision_b66b265f, p_Precision_Clear := TRUE, p_Scale := p_Scale_b66b265f, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_b66b265f, p_DefaultValue := p_DefaultValue_b66b265f, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_b66b265f, p_IsUniqueKey := p_IsUniqueKey_b66b265f, p_IsReadOnly := p_IsReadOnly_b66b265f, p_IsRequired := p_IsRequired_b66b265f, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_b66b265f, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_b66b265f, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_b66b265f, p_Configuration := p_Configuration_b66b265f, p_Configuration_Clear := TRUE, p_Status := p_Status_b66b265f, p_IsCustom := p_IsCustom_b66b265f, p_MetadataSource := p_MetadataSource_b66b265f);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_65ef13ed UUID;
  p_IntegrationObjectID_65ef13ed UUID;
  p_Name_65ef13ed VARCHAR(255);
  p_DisplayName_65ef13ed VARCHAR(255);
  p_Description_65ef13ed TEXT;
  p_Category_65ef13ed VARCHAR(100);
  p_Type_65ef13ed VARCHAR(100);
  p_Length_65ef13ed INTEGER;
  p_Precision_65ef13ed INTEGER;
  p_Scale_65ef13ed INTEGER;
  p_AllowsNull_65ef13ed BOOLEAN;
  p_DefaultValue_65ef13ed VARCHAR(255);
  p_IsPrimaryKey_65ef13ed BOOLEAN;
  p_IsUniqueKey_65ef13ed BOOLEAN;
  p_IsReadOnly_65ef13ed BOOLEAN;
  p_IsRequired_65ef13ed BOOLEAN;
  p_RelatedIntegrationObjectID_65ef13ed UUID;
  p_RelatedIntegrationObjectFieldName_65ef13ed VARCHAR(255);
  p_Sequence_65ef13ed INTEGER;
  p_Configuration_65ef13ed TEXT;
  p_Status_65ef13ed VARCHAR(25);
  p_IsCustom_65ef13ed BOOLEAN;
  p_MetadataSource_65ef13ed VARCHAR(20);
BEGIN
  p_ID_65ef13ed := '1CC6C9DE-4489-5810-B952-473AB5B0CBC4';
  p_IntegrationObjectID_65ef13ed := '2139B63E-5944-4542-BE5E-7213D64B9750';
  p_Name_65ef13ed := 'start-year';
  p_DisplayName_65ef13ed := 'Start Year';
  p_Description_65ef13ed := 'Year of the affiliation start date; ORCID dates are partial, so month/day may be absent.';
  p_Type_65ef13ed := 'Integer';
  p_AllowsNull_65ef13ed := TRUE;
  p_IsPrimaryKey_65ef13ed := FALSE;
  p_IsUniqueKey_65ef13ed := FALSE;
  p_IsReadOnly_65ef13ed := TRUE;
  p_IsRequired_65ef13ed := FALSE;
  p_Sequence_65ef13ed := 15;
  p_Status_65ef13ed := 'Active';
  p_IsCustom_65ef13ed := FALSE;
  p_MetadataSource_65ef13ed := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_65ef13ed, p_IntegrationObjectID := p_IntegrationObjectID_65ef13ed, p_Name := p_Name_65ef13ed, p_DisplayName := p_DisplayName_65ef13ed, p_Description := p_Description_65ef13ed, p_Category := p_Category_65ef13ed, p_Category_Clear := TRUE, p_Type := p_Type_65ef13ed, p_Length := p_Length_65ef13ed, p_Length_Clear := TRUE, p_Precision := p_Precision_65ef13ed, p_Precision_Clear := TRUE, p_Scale := p_Scale_65ef13ed, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_65ef13ed, p_DefaultValue := p_DefaultValue_65ef13ed, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_65ef13ed, p_IsUniqueKey := p_IsUniqueKey_65ef13ed, p_IsReadOnly := p_IsReadOnly_65ef13ed, p_IsRequired := p_IsRequired_65ef13ed, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_65ef13ed, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_65ef13ed, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_65ef13ed, p_Configuration := p_Configuration_65ef13ed, p_Configuration_Clear := TRUE, p_Status := p_Status_65ef13ed, p_IsCustom := p_IsCustom_65ef13ed, p_MetadataSource := p_MetadataSource_65ef13ed);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_129e7269 UUID;
  p_IntegrationObjectID_129e7269 UUID;
  p_Name_129e7269 VARCHAR(255);
  p_DisplayName_129e7269 VARCHAR(255);
  p_Description_129e7269 TEXT;
  p_Category_129e7269 VARCHAR(100);
  p_Type_129e7269 VARCHAR(100);
  p_Length_129e7269 INTEGER;
  p_Precision_129e7269 INTEGER;
  p_Scale_129e7269 INTEGER;
  p_AllowsNull_129e7269 BOOLEAN;
  p_DefaultValue_129e7269 VARCHAR(255);
  p_IsPrimaryKey_129e7269 BOOLEAN;
  p_IsUniqueKey_129e7269 BOOLEAN;
  p_IsReadOnly_129e7269 BOOLEAN;
  p_IsRequired_129e7269 BOOLEAN;
  p_RelatedIntegrationObjectID_129e7269 UUID;
  p_RelatedIntegrationObjectFieldName_129e7269 VARCHAR(255);
  p_Sequence_129e7269 INTEGER;
  p_Configuration_129e7269 TEXT;
  p_Status_129e7269 VARCHAR(25);
  p_IsCustom_129e7269 BOOLEAN;
  p_MetadataSource_129e7269 VARCHAR(20);
BEGIN
  p_ID_129e7269 := '766B30A6-3353-56A0-B327-98DC4889CFC8';
  p_IntegrationObjectID_129e7269 := '2139B63E-5944-4542-BE5E-7213D64B9750';
  p_Name_129e7269 := 'start-month';
  p_DisplayName_129e7269 := 'Start Month';
  p_Description_129e7269 := 'Month (1-12) of the affiliation start date, when given.';
  p_Type_129e7269 := 'Integer';
  p_AllowsNull_129e7269 := TRUE;
  p_IsPrimaryKey_129e7269 := FALSE;
  p_IsUniqueKey_129e7269 := FALSE;
  p_IsReadOnly_129e7269 := TRUE;
  p_IsRequired_129e7269 := FALSE;
  p_Sequence_129e7269 := 16;
  p_Status_129e7269 := 'Active';
  p_IsCustom_129e7269 := FALSE;
  p_MetadataSource_129e7269 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_129e7269, p_IntegrationObjectID := p_IntegrationObjectID_129e7269, p_Name := p_Name_129e7269, p_DisplayName := p_DisplayName_129e7269, p_Description := p_Description_129e7269, p_Category := p_Category_129e7269, p_Category_Clear := TRUE, p_Type := p_Type_129e7269, p_Length := p_Length_129e7269, p_Length_Clear := TRUE, p_Precision := p_Precision_129e7269, p_Precision_Clear := TRUE, p_Scale := p_Scale_129e7269, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_129e7269, p_DefaultValue := p_DefaultValue_129e7269, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_129e7269, p_IsUniqueKey := p_IsUniqueKey_129e7269, p_IsReadOnly := p_IsReadOnly_129e7269, p_IsRequired := p_IsRequired_129e7269, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_129e7269, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_129e7269, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_129e7269, p_Configuration := p_Configuration_129e7269, p_Configuration_Clear := TRUE, p_Status := p_Status_129e7269, p_IsCustom := p_IsCustom_129e7269, p_MetadataSource := p_MetadataSource_129e7269);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_6bf0b94d UUID;
  p_IntegrationObjectID_6bf0b94d UUID;
  p_Name_6bf0b94d VARCHAR(255);
  p_DisplayName_6bf0b94d VARCHAR(255);
  p_Description_6bf0b94d TEXT;
  p_Category_6bf0b94d VARCHAR(100);
  p_Type_6bf0b94d VARCHAR(100);
  p_Length_6bf0b94d INTEGER;
  p_Precision_6bf0b94d INTEGER;
  p_Scale_6bf0b94d INTEGER;
  p_AllowsNull_6bf0b94d BOOLEAN;
  p_DefaultValue_6bf0b94d VARCHAR(255);
  p_IsPrimaryKey_6bf0b94d BOOLEAN;
  p_IsUniqueKey_6bf0b94d BOOLEAN;
  p_IsReadOnly_6bf0b94d BOOLEAN;
  p_IsRequired_6bf0b94d BOOLEAN;
  p_RelatedIntegrationObjectID_6bf0b94d UUID;
  p_RelatedIntegrationObjectFieldName_6bf0b94d VARCHAR(255);
  p_Sequence_6bf0b94d INTEGER;
  p_Configuration_6bf0b94d TEXT;
  p_Status_6bf0b94d VARCHAR(25);
  p_IsCustom_6bf0b94d BOOLEAN;
  p_MetadataSource_6bf0b94d VARCHAR(20);
BEGIN
  p_ID_6bf0b94d := 'C09522F2-E3D2-5F87-AE38-CB9696D9AC43';
  p_IntegrationObjectID_6bf0b94d := '2139B63E-5944-4542-BE5E-7213D64B9750';
  p_Name_6bf0b94d := 'start-day';
  p_DisplayName_6bf0b94d := 'Start Day';
  p_Description_6bf0b94d := 'Day of month of the affiliation start date, when given.';
  p_Type_6bf0b94d := 'Integer';
  p_AllowsNull_6bf0b94d := TRUE;
  p_IsPrimaryKey_6bf0b94d := FALSE;
  p_IsUniqueKey_6bf0b94d := FALSE;
  p_IsReadOnly_6bf0b94d := TRUE;
  p_IsRequired_6bf0b94d := FALSE;
  p_Sequence_6bf0b94d := 17;
  p_Status_6bf0b94d := 'Active';
  p_IsCustom_6bf0b94d := FALSE;
  p_MetadataSource_6bf0b94d := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_6bf0b94d, p_IntegrationObjectID := p_IntegrationObjectID_6bf0b94d, p_Name := p_Name_6bf0b94d, p_DisplayName := p_DisplayName_6bf0b94d, p_Description := p_Description_6bf0b94d, p_Category := p_Category_6bf0b94d, p_Category_Clear := TRUE, p_Type := p_Type_6bf0b94d, p_Length := p_Length_6bf0b94d, p_Length_Clear := TRUE, p_Precision := p_Precision_6bf0b94d, p_Precision_Clear := TRUE, p_Scale := p_Scale_6bf0b94d, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_6bf0b94d, p_DefaultValue := p_DefaultValue_6bf0b94d, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_6bf0b94d, p_IsUniqueKey := p_IsUniqueKey_6bf0b94d, p_IsReadOnly := p_IsReadOnly_6bf0b94d, p_IsRequired := p_IsRequired_6bf0b94d, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_6bf0b94d, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_6bf0b94d, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_6bf0b94d, p_Configuration := p_Configuration_6bf0b94d, p_Configuration_Clear := TRUE, p_Status := p_Status_6bf0b94d, p_IsCustom := p_IsCustom_6bf0b94d, p_MetadataSource := p_MetadataSource_6bf0b94d);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_bf7ae71a UUID;
  p_IntegrationObjectID_bf7ae71a UUID;
  p_Name_bf7ae71a VARCHAR(255);
  p_DisplayName_bf7ae71a VARCHAR(255);
  p_Description_bf7ae71a TEXT;
  p_Category_bf7ae71a VARCHAR(100);
  p_Type_bf7ae71a VARCHAR(100);
  p_Length_bf7ae71a INTEGER;
  p_Precision_bf7ae71a INTEGER;
  p_Scale_bf7ae71a INTEGER;
  p_AllowsNull_bf7ae71a BOOLEAN;
  p_DefaultValue_bf7ae71a VARCHAR(255);
  p_IsPrimaryKey_bf7ae71a BOOLEAN;
  p_IsUniqueKey_bf7ae71a BOOLEAN;
  p_IsReadOnly_bf7ae71a BOOLEAN;
  p_IsRequired_bf7ae71a BOOLEAN;
  p_RelatedIntegrationObjectID_bf7ae71a UUID;
  p_RelatedIntegrationObjectFieldName_bf7ae71a VARCHAR(255);
  p_Sequence_bf7ae71a INTEGER;
  p_Configuration_bf7ae71a TEXT;
  p_Status_bf7ae71a VARCHAR(25);
  p_IsCustom_bf7ae71a BOOLEAN;
  p_MetadataSource_bf7ae71a VARCHAR(20);
BEGIN
  p_ID_bf7ae71a := '2BD175D8-3CE8-5BD4-8842-725578BB84C4';
  p_IntegrationObjectID_bf7ae71a := '2139B63E-5944-4542-BE5E-7213D64B9750';
  p_Name_bf7ae71a := 'end-year';
  p_DisplayName_bf7ae71a := 'End Year';
  p_Description_bf7ae71a := 'Year of the affiliation end date; empty for a current/ongoing role; ORCID dates are partial, so month/day may be absent.';
  p_Type_bf7ae71a := 'Integer';
  p_AllowsNull_bf7ae71a := TRUE;
  p_IsPrimaryKey_bf7ae71a := FALSE;
  p_IsUniqueKey_bf7ae71a := FALSE;
  p_IsReadOnly_bf7ae71a := TRUE;
  p_IsRequired_bf7ae71a := FALSE;
  p_Sequence_bf7ae71a := 18;
  p_Status_bf7ae71a := 'Active';
  p_IsCustom_bf7ae71a := FALSE;
  p_MetadataSource_bf7ae71a := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_bf7ae71a, p_IntegrationObjectID := p_IntegrationObjectID_bf7ae71a, p_Name := p_Name_bf7ae71a, p_DisplayName := p_DisplayName_bf7ae71a, p_Description := p_Description_bf7ae71a, p_Category := p_Category_bf7ae71a, p_Category_Clear := TRUE, p_Type := p_Type_bf7ae71a, p_Length := p_Length_bf7ae71a, p_Length_Clear := TRUE, p_Precision := p_Precision_bf7ae71a, p_Precision_Clear := TRUE, p_Scale := p_Scale_bf7ae71a, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_bf7ae71a, p_DefaultValue := p_DefaultValue_bf7ae71a, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_bf7ae71a, p_IsUniqueKey := p_IsUniqueKey_bf7ae71a, p_IsReadOnly := p_IsReadOnly_bf7ae71a, p_IsRequired := p_IsRequired_bf7ae71a, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_bf7ae71a, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_bf7ae71a, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_bf7ae71a, p_Configuration := p_Configuration_bf7ae71a, p_Configuration_Clear := TRUE, p_Status := p_Status_bf7ae71a, p_IsCustom := p_IsCustom_bf7ae71a, p_MetadataSource := p_MetadataSource_bf7ae71a);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_a0f6db3c UUID;
  p_IntegrationObjectID_a0f6db3c UUID;
  p_Name_a0f6db3c VARCHAR(255);
  p_DisplayName_a0f6db3c VARCHAR(255);
  p_Description_a0f6db3c TEXT;
  p_Category_a0f6db3c VARCHAR(100);
  p_Type_a0f6db3c VARCHAR(100);
  p_Length_a0f6db3c INTEGER;
  p_Precision_a0f6db3c INTEGER;
  p_Scale_a0f6db3c INTEGER;
  p_AllowsNull_a0f6db3c BOOLEAN;
  p_DefaultValue_a0f6db3c VARCHAR(255);
  p_IsPrimaryKey_a0f6db3c BOOLEAN;
  p_IsUniqueKey_a0f6db3c BOOLEAN;
  p_IsReadOnly_a0f6db3c BOOLEAN;
  p_IsRequired_a0f6db3c BOOLEAN;
  p_RelatedIntegrationObjectID_a0f6db3c UUID;
  p_RelatedIntegrationObjectFieldName_a0f6db3c VARCHAR(255);
  p_Sequence_a0f6db3c INTEGER;
  p_Configuration_a0f6db3c TEXT;
  p_Status_a0f6db3c VARCHAR(25);
  p_IsCustom_a0f6db3c BOOLEAN;
  p_MetadataSource_a0f6db3c VARCHAR(20);
BEGIN
  p_ID_a0f6db3c := '93BB7103-4431-5ECA-BE01-B15F416A8474';
  p_IntegrationObjectID_a0f6db3c := '2139B63E-5944-4542-BE5E-7213D64B9750';
  p_Name_a0f6db3c := 'end-month';
  p_DisplayName_a0f6db3c := 'End Month';
  p_Description_a0f6db3c := 'Month (1-12) of the affiliation end date; empty for a current/ongoing role, when given.';
  p_Type_a0f6db3c := 'Integer';
  p_AllowsNull_a0f6db3c := TRUE;
  p_IsPrimaryKey_a0f6db3c := FALSE;
  p_IsUniqueKey_a0f6db3c := FALSE;
  p_IsReadOnly_a0f6db3c := TRUE;
  p_IsRequired_a0f6db3c := FALSE;
  p_Sequence_a0f6db3c := 19;
  p_Status_a0f6db3c := 'Active';
  p_IsCustom_a0f6db3c := FALSE;
  p_MetadataSource_a0f6db3c := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_a0f6db3c, p_IntegrationObjectID := p_IntegrationObjectID_a0f6db3c, p_Name := p_Name_a0f6db3c, p_DisplayName := p_DisplayName_a0f6db3c, p_Description := p_Description_a0f6db3c, p_Category := p_Category_a0f6db3c, p_Category_Clear := TRUE, p_Type := p_Type_a0f6db3c, p_Length := p_Length_a0f6db3c, p_Length_Clear := TRUE, p_Precision := p_Precision_a0f6db3c, p_Precision_Clear := TRUE, p_Scale := p_Scale_a0f6db3c, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_a0f6db3c, p_DefaultValue := p_DefaultValue_a0f6db3c, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_a0f6db3c, p_IsUniqueKey := p_IsUniqueKey_a0f6db3c, p_IsReadOnly := p_IsReadOnly_a0f6db3c, p_IsRequired := p_IsRequired_a0f6db3c, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_a0f6db3c, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_a0f6db3c, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_a0f6db3c, p_Configuration := p_Configuration_a0f6db3c, p_Configuration_Clear := TRUE, p_Status := p_Status_a0f6db3c, p_IsCustom := p_IsCustom_a0f6db3c, p_MetadataSource := p_MetadataSource_a0f6db3c);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_aa6f7a28 UUID;
  p_IntegrationObjectID_aa6f7a28 UUID;
  p_Name_aa6f7a28 VARCHAR(255);
  p_DisplayName_aa6f7a28 VARCHAR(255);
  p_Description_aa6f7a28 TEXT;
  p_Category_aa6f7a28 VARCHAR(100);
  p_Type_aa6f7a28 VARCHAR(100);
  p_Length_aa6f7a28 INTEGER;
  p_Precision_aa6f7a28 INTEGER;
  p_Scale_aa6f7a28 INTEGER;
  p_AllowsNull_aa6f7a28 BOOLEAN;
  p_DefaultValue_aa6f7a28 VARCHAR(255);
  p_IsPrimaryKey_aa6f7a28 BOOLEAN;
  p_IsUniqueKey_aa6f7a28 BOOLEAN;
  p_IsReadOnly_aa6f7a28 BOOLEAN;
  p_IsRequired_aa6f7a28 BOOLEAN;
  p_RelatedIntegrationObjectID_aa6f7a28 UUID;
  p_RelatedIntegrationObjectFieldName_aa6f7a28 VARCHAR(255);
  p_Sequence_aa6f7a28 INTEGER;
  p_Configuration_aa6f7a28 TEXT;
  p_Status_aa6f7a28 VARCHAR(25);
  p_IsCustom_aa6f7a28 BOOLEAN;
  p_MetadataSource_aa6f7a28 VARCHAR(20);
BEGIN
  p_ID_aa6f7a28 := '90750C5B-9BD9-533F-B6E5-ACA94DFF1572';
  p_IntegrationObjectID_aa6f7a28 := '2139B63E-5944-4542-BE5E-7213D64B9750';
  p_Name_aa6f7a28 := 'end-day';
  p_DisplayName_aa6f7a28 := 'End Day';
  p_Description_aa6f7a28 := 'Day of month of the affiliation end date; empty for a current/ongoing role, when given.';
  p_Type_aa6f7a28 := 'Integer';
  p_AllowsNull_aa6f7a28 := TRUE;
  p_IsPrimaryKey_aa6f7a28 := FALSE;
  p_IsUniqueKey_aa6f7a28 := FALSE;
  p_IsReadOnly_aa6f7a28 := TRUE;
  p_IsRequired_aa6f7a28 := FALSE;
  p_Sequence_aa6f7a28 := 20;
  p_Status_aa6f7a28 := 'Active';
  p_IsCustom_aa6f7a28 := FALSE;
  p_MetadataSource_aa6f7a28 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_aa6f7a28, p_IntegrationObjectID := p_IntegrationObjectID_aa6f7a28, p_Name := p_Name_aa6f7a28, p_DisplayName := p_DisplayName_aa6f7a28, p_Description := p_Description_aa6f7a28, p_Category := p_Category_aa6f7a28, p_Category_Clear := TRUE, p_Type := p_Type_aa6f7a28, p_Length := p_Length_aa6f7a28, p_Length_Clear := TRUE, p_Precision := p_Precision_aa6f7a28, p_Precision_Clear := TRUE, p_Scale := p_Scale_aa6f7a28, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_aa6f7a28, p_DefaultValue := p_DefaultValue_aa6f7a28, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_aa6f7a28, p_IsUniqueKey := p_IsUniqueKey_aa6f7a28, p_IsReadOnly := p_IsReadOnly_aa6f7a28, p_IsRequired := p_IsRequired_aa6f7a28, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_aa6f7a28, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_aa6f7a28, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_aa6f7a28, p_Configuration := p_Configuration_aa6f7a28, p_Configuration_Clear := TRUE, p_Status := p_Status_aa6f7a28, p_IsCustom := p_IsCustom_aa6f7a28, p_MetadataSource := p_MetadataSource_aa6f7a28);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_5f4b8d67 UUID;
  p_IntegrationObjectID_5f4b8d67 UUID;
  p_Name_5f4b8d67 VARCHAR(255);
  p_DisplayName_5f4b8d67 VARCHAR(255);
  p_Description_5f4b8d67 TEXT;
  p_Category_5f4b8d67 VARCHAR(100);
  p_Type_5f4b8d67 VARCHAR(100);
  p_Length_5f4b8d67 INTEGER;
  p_Precision_5f4b8d67 INTEGER;
  p_Scale_5f4b8d67 INTEGER;
  p_AllowsNull_5f4b8d67 BOOLEAN;
  p_DefaultValue_5f4b8d67 VARCHAR(255);
  p_IsPrimaryKey_5f4b8d67 BOOLEAN;
  p_IsUniqueKey_5f4b8d67 BOOLEAN;
  p_IsReadOnly_5f4b8d67 BOOLEAN;
  p_IsRequired_5f4b8d67 BOOLEAN;
  p_RelatedIntegrationObjectID_5f4b8d67 UUID;
  p_RelatedIntegrationObjectFieldName_5f4b8d67 VARCHAR(255);
  p_Sequence_5f4b8d67 INTEGER;
  p_Configuration_5f4b8d67 TEXT;
  p_Status_5f4b8d67 VARCHAR(25);
  p_IsCustom_5f4b8d67 BOOLEAN;
  p_MetadataSource_5f4b8d67 VARCHAR(20);
BEGIN
  p_ID_5f4b8d67 := '2AEA4CA3-6303-570D-AF1C-277F162C99D7';
  p_IntegrationObjectID_5f4b8d67 := '2139B63E-5944-4542-BE5E-7213D64B9750';
  p_Name_5f4b8d67 := 'organization-name';
  p_DisplayName_5f4b8d67 := 'Organization Name';
  p_Description_5f4b8d67 := 'Name of the organization. Lifted from organization.name.';
  p_Type_5f4b8d67 := 'String';
  p_Length_5f4b8d67 := 1000;
  p_AllowsNull_5f4b8d67 := TRUE;
  p_IsPrimaryKey_5f4b8d67 := FALSE;
  p_IsUniqueKey_5f4b8d67 := FALSE;
  p_IsReadOnly_5f4b8d67 := TRUE;
  p_IsRequired_5f4b8d67 := FALSE;
  p_Sequence_5f4b8d67 := 21;
  p_Status_5f4b8d67 := 'Active';
  p_IsCustom_5f4b8d67 := FALSE;
  p_MetadataSource_5f4b8d67 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_5f4b8d67, p_IntegrationObjectID := p_IntegrationObjectID_5f4b8d67, p_Name := p_Name_5f4b8d67, p_DisplayName := p_DisplayName_5f4b8d67, p_Description := p_Description_5f4b8d67, p_Category := p_Category_5f4b8d67, p_Category_Clear := TRUE, p_Type := p_Type_5f4b8d67, p_Length := p_Length_5f4b8d67, p_Precision := p_Precision_5f4b8d67, p_Precision_Clear := TRUE, p_Scale := p_Scale_5f4b8d67, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_5f4b8d67, p_DefaultValue := p_DefaultValue_5f4b8d67, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_5f4b8d67, p_IsUniqueKey := p_IsUniqueKey_5f4b8d67, p_IsReadOnly := p_IsReadOnly_5f4b8d67, p_IsRequired := p_IsRequired_5f4b8d67, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_5f4b8d67, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_5f4b8d67, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_5f4b8d67, p_Configuration := p_Configuration_5f4b8d67, p_Configuration_Clear := TRUE, p_Status := p_Status_5f4b8d67, p_IsCustom := p_IsCustom_5f4b8d67, p_MetadataSource := p_MetadataSource_5f4b8d67);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_25873ed9 UUID;
  p_IntegrationObjectID_25873ed9 UUID;
  p_Name_25873ed9 VARCHAR(255);
  p_DisplayName_25873ed9 VARCHAR(255);
  p_Description_25873ed9 TEXT;
  p_Category_25873ed9 VARCHAR(100);
  p_Type_25873ed9 VARCHAR(100);
  p_Length_25873ed9 INTEGER;
  p_Precision_25873ed9 INTEGER;
  p_Scale_25873ed9 INTEGER;
  p_AllowsNull_25873ed9 BOOLEAN;
  p_DefaultValue_25873ed9 VARCHAR(255);
  p_IsPrimaryKey_25873ed9 BOOLEAN;
  p_IsUniqueKey_25873ed9 BOOLEAN;
  p_IsReadOnly_25873ed9 BOOLEAN;
  p_IsRequired_25873ed9 BOOLEAN;
  p_RelatedIntegrationObjectID_25873ed9 UUID;
  p_RelatedIntegrationObjectFieldName_25873ed9 VARCHAR(255);
  p_Sequence_25873ed9 INTEGER;
  p_Configuration_25873ed9 TEXT;
  p_Status_25873ed9 VARCHAR(25);
  p_IsCustom_25873ed9 BOOLEAN;
  p_MetadataSource_25873ed9 VARCHAR(20);
BEGIN
  p_ID_25873ed9 := 'FF397CAE-0710-5834-A7AD-3B5341B4FCD3';
  p_IntegrationObjectID_25873ed9 := '2139B63E-5944-4542-BE5E-7213D64B9750';
  p_Name_25873ed9 := 'organization-city';
  p_DisplayName_25873ed9 := 'Organization City';
  p_Description_25873ed9 := 'City of the organization. Lifted from organization.address.city.';
  p_Type_25873ed9 := 'String';
  p_Length_25873ed9 := 255;
  p_AllowsNull_25873ed9 := TRUE;
  p_IsPrimaryKey_25873ed9 := FALSE;
  p_IsUniqueKey_25873ed9 := FALSE;
  p_IsReadOnly_25873ed9 := TRUE;
  p_IsRequired_25873ed9 := FALSE;
  p_Sequence_25873ed9 := 22;
  p_Status_25873ed9 := 'Active';
  p_IsCustom_25873ed9 := FALSE;
  p_MetadataSource_25873ed9 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_25873ed9, p_IntegrationObjectID := p_IntegrationObjectID_25873ed9, p_Name := p_Name_25873ed9, p_DisplayName := p_DisplayName_25873ed9, p_Description := p_Description_25873ed9, p_Category := p_Category_25873ed9, p_Category_Clear := TRUE, p_Type := p_Type_25873ed9, p_Length := p_Length_25873ed9, p_Precision := p_Precision_25873ed9, p_Precision_Clear := TRUE, p_Scale := p_Scale_25873ed9, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_25873ed9, p_DefaultValue := p_DefaultValue_25873ed9, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_25873ed9, p_IsUniqueKey := p_IsUniqueKey_25873ed9, p_IsReadOnly := p_IsReadOnly_25873ed9, p_IsRequired := p_IsRequired_25873ed9, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_25873ed9, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_25873ed9, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_25873ed9, p_Configuration := p_Configuration_25873ed9, p_Configuration_Clear := TRUE, p_Status := p_Status_25873ed9, p_IsCustom := p_IsCustom_25873ed9, p_MetadataSource := p_MetadataSource_25873ed9);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_1abf2e83 UUID;
  p_IntegrationObjectID_1abf2e83 UUID;
  p_Name_1abf2e83 VARCHAR(255);
  p_DisplayName_1abf2e83 VARCHAR(255);
  p_Description_1abf2e83 TEXT;
  p_Category_1abf2e83 VARCHAR(100);
  p_Type_1abf2e83 VARCHAR(100);
  p_Length_1abf2e83 INTEGER;
  p_Precision_1abf2e83 INTEGER;
  p_Scale_1abf2e83 INTEGER;
  p_AllowsNull_1abf2e83 BOOLEAN;
  p_DefaultValue_1abf2e83 VARCHAR(255);
  p_IsPrimaryKey_1abf2e83 BOOLEAN;
  p_IsUniqueKey_1abf2e83 BOOLEAN;
  p_IsReadOnly_1abf2e83 BOOLEAN;
  p_IsRequired_1abf2e83 BOOLEAN;
  p_RelatedIntegrationObjectID_1abf2e83 UUID;
  p_RelatedIntegrationObjectFieldName_1abf2e83 VARCHAR(255);
  p_Sequence_1abf2e83 INTEGER;
  p_Configuration_1abf2e83 TEXT;
  p_Status_1abf2e83 VARCHAR(25);
  p_IsCustom_1abf2e83 BOOLEAN;
  p_MetadataSource_1abf2e83 VARCHAR(20);
BEGIN
  p_ID_1abf2e83 := 'C8C75BBB-B473-535E-863C-E03C224564B8';
  p_IntegrationObjectID_1abf2e83 := '2139B63E-5944-4542-BE5E-7213D64B9750';
  p_Name_1abf2e83 := 'organization-region';
  p_DisplayName_1abf2e83 := 'Organization Region';
  p_Description_1abf2e83 := 'Region/state of the organization. Lifted from organization.address.region.';
  p_Type_1abf2e83 := 'String';
  p_Length_1abf2e83 := 255;
  p_AllowsNull_1abf2e83 := TRUE;
  p_IsPrimaryKey_1abf2e83 := FALSE;
  p_IsUniqueKey_1abf2e83 := FALSE;
  p_IsReadOnly_1abf2e83 := TRUE;
  p_IsRequired_1abf2e83 := FALSE;
  p_Sequence_1abf2e83 := 23;
  p_Status_1abf2e83 := 'Active';
  p_IsCustom_1abf2e83 := FALSE;
  p_MetadataSource_1abf2e83 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_1abf2e83, p_IntegrationObjectID := p_IntegrationObjectID_1abf2e83, p_Name := p_Name_1abf2e83, p_DisplayName := p_DisplayName_1abf2e83, p_Description := p_Description_1abf2e83, p_Category := p_Category_1abf2e83, p_Category_Clear := TRUE, p_Type := p_Type_1abf2e83, p_Length := p_Length_1abf2e83, p_Precision := p_Precision_1abf2e83, p_Precision_Clear := TRUE, p_Scale := p_Scale_1abf2e83, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_1abf2e83, p_DefaultValue := p_DefaultValue_1abf2e83, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_1abf2e83, p_IsUniqueKey := p_IsUniqueKey_1abf2e83, p_IsReadOnly := p_IsReadOnly_1abf2e83, p_IsRequired := p_IsRequired_1abf2e83, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_1abf2e83, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_1abf2e83, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_1abf2e83, p_Configuration := p_Configuration_1abf2e83, p_Configuration_Clear := TRUE, p_Status := p_Status_1abf2e83, p_IsCustom := p_IsCustom_1abf2e83, p_MetadataSource := p_MetadataSource_1abf2e83);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_dd3d1b43 UUID;
  p_IntegrationObjectID_dd3d1b43 UUID;
  p_Name_dd3d1b43 VARCHAR(255);
  p_DisplayName_dd3d1b43 VARCHAR(255);
  p_Description_dd3d1b43 TEXT;
  p_Category_dd3d1b43 VARCHAR(100);
  p_Type_dd3d1b43 VARCHAR(100);
  p_Length_dd3d1b43 INTEGER;
  p_Precision_dd3d1b43 INTEGER;
  p_Scale_dd3d1b43 INTEGER;
  p_AllowsNull_dd3d1b43 BOOLEAN;
  p_DefaultValue_dd3d1b43 VARCHAR(255);
  p_IsPrimaryKey_dd3d1b43 BOOLEAN;
  p_IsUniqueKey_dd3d1b43 BOOLEAN;
  p_IsReadOnly_dd3d1b43 BOOLEAN;
  p_IsRequired_dd3d1b43 BOOLEAN;
  p_RelatedIntegrationObjectID_dd3d1b43 UUID;
  p_RelatedIntegrationObjectFieldName_dd3d1b43 VARCHAR(255);
  p_Sequence_dd3d1b43 INTEGER;
  p_Configuration_dd3d1b43 TEXT;
  p_Status_dd3d1b43 VARCHAR(25);
  p_IsCustom_dd3d1b43 BOOLEAN;
  p_MetadataSource_dd3d1b43 VARCHAR(20);
BEGIN
  p_ID_dd3d1b43 := '1FF0C5F2-38C4-5FB1-BF64-F9B01E5F2407';
  p_IntegrationObjectID_dd3d1b43 := '2139B63E-5944-4542-BE5E-7213D64B9750';
  p_Name_dd3d1b43 := 'organization-country';
  p_DisplayName_dd3d1b43 := 'Organization Country';
  p_Description_dd3d1b43 := 'ISO country code of the organization. Lifted from organization.address.country.';
  p_Type_dd3d1b43 := 'String';
  p_Length_dd3d1b43 := 50;
  p_AllowsNull_dd3d1b43 := TRUE;
  p_IsPrimaryKey_dd3d1b43 := FALSE;
  p_IsUniqueKey_dd3d1b43 := FALSE;
  p_IsReadOnly_dd3d1b43 := TRUE;
  p_IsRequired_dd3d1b43 := FALSE;
  p_Sequence_dd3d1b43 := 24;
  p_Status_dd3d1b43 := 'Active';
  p_IsCustom_dd3d1b43 := FALSE;
  p_MetadataSource_dd3d1b43 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_dd3d1b43, p_IntegrationObjectID := p_IntegrationObjectID_dd3d1b43, p_Name := p_Name_dd3d1b43, p_DisplayName := p_DisplayName_dd3d1b43, p_Description := p_Description_dd3d1b43, p_Category := p_Category_dd3d1b43, p_Category_Clear := TRUE, p_Type := p_Type_dd3d1b43, p_Length := p_Length_dd3d1b43, p_Precision := p_Precision_dd3d1b43, p_Precision_Clear := TRUE, p_Scale := p_Scale_dd3d1b43, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_dd3d1b43, p_DefaultValue := p_DefaultValue_dd3d1b43, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_dd3d1b43, p_IsUniqueKey := p_IsUniqueKey_dd3d1b43, p_IsReadOnly := p_IsReadOnly_dd3d1b43, p_IsRequired := p_IsRequired_dd3d1b43, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_dd3d1b43, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_dd3d1b43, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_dd3d1b43, p_Configuration := p_Configuration_dd3d1b43, p_Configuration_Clear := TRUE, p_Status := p_Status_dd3d1b43, p_IsCustom := p_IsCustom_dd3d1b43, p_MetadataSource := p_MetadataSource_dd3d1b43);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_48fd00e1 UUID;
  p_IntegrationObjectID_48fd00e1 UUID;
  p_Name_48fd00e1 VARCHAR(255);
  p_DisplayName_48fd00e1 VARCHAR(255);
  p_Description_48fd00e1 TEXT;
  p_Category_48fd00e1 VARCHAR(100);
  p_Type_48fd00e1 VARCHAR(100);
  p_Length_48fd00e1 INTEGER;
  p_Precision_48fd00e1 INTEGER;
  p_Scale_48fd00e1 INTEGER;
  p_AllowsNull_48fd00e1 BOOLEAN;
  p_DefaultValue_48fd00e1 VARCHAR(255);
  p_IsPrimaryKey_48fd00e1 BOOLEAN;
  p_IsUniqueKey_48fd00e1 BOOLEAN;
  p_IsReadOnly_48fd00e1 BOOLEAN;
  p_IsRequired_48fd00e1 BOOLEAN;
  p_RelatedIntegrationObjectID_48fd00e1 UUID;
  p_RelatedIntegrationObjectFieldName_48fd00e1 VARCHAR(255);
  p_Sequence_48fd00e1 INTEGER;
  p_Configuration_48fd00e1 TEXT;
  p_Status_48fd00e1 VARCHAR(25);
  p_IsCustom_48fd00e1 BOOLEAN;
  p_MetadataSource_48fd00e1 VARCHAR(20);
BEGIN
  p_ID_48fd00e1 := '529E36C0-E40F-5DEF-BE25-1C16AF08FD68';
  p_IntegrationObjectID_48fd00e1 := '2139B63E-5944-4542-BE5E-7213D64B9750';
  p_Name_48fd00e1 := 'organization-disambiguated-id';
  p_DisplayName_48fd00e1 := 'Organization Disambiguated Id';
  p_Description_48fd00e1 := 'Canonical identifier of the organization in the disambiguation source (e.g. a RINGGOLD or ROR id), so the same institution matches across records.';
  p_Type_48fd00e1 := 'String';
  p_Length_48fd00e1 := 255;
  p_AllowsNull_48fd00e1 := TRUE;
  p_IsPrimaryKey_48fd00e1 := FALSE;
  p_IsUniqueKey_48fd00e1 := FALSE;
  p_IsReadOnly_48fd00e1 := TRUE;
  p_IsRequired_48fd00e1 := FALSE;
  p_Sequence_48fd00e1 := 25;
  p_Status_48fd00e1 := 'Active';
  p_IsCustom_48fd00e1 := FALSE;
  p_MetadataSource_48fd00e1 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_48fd00e1, p_IntegrationObjectID := p_IntegrationObjectID_48fd00e1, p_Name := p_Name_48fd00e1, p_DisplayName := p_DisplayName_48fd00e1, p_Description := p_Description_48fd00e1, p_Category := p_Category_48fd00e1, p_Category_Clear := TRUE, p_Type := p_Type_48fd00e1, p_Length := p_Length_48fd00e1, p_Precision := p_Precision_48fd00e1, p_Precision_Clear := TRUE, p_Scale := p_Scale_48fd00e1, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_48fd00e1, p_DefaultValue := p_DefaultValue_48fd00e1, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_48fd00e1, p_IsUniqueKey := p_IsUniqueKey_48fd00e1, p_IsReadOnly := p_IsReadOnly_48fd00e1, p_IsRequired := p_IsRequired_48fd00e1, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_48fd00e1, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_48fd00e1, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_48fd00e1, p_Configuration := p_Configuration_48fd00e1, p_Configuration_Clear := TRUE, p_Status := p_Status_48fd00e1, p_IsCustom := p_IsCustom_48fd00e1, p_MetadataSource := p_MetadataSource_48fd00e1);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_5253e79c UUID;
  p_IntegrationObjectID_5253e79c UUID;
  p_Name_5253e79c VARCHAR(255);
  p_DisplayName_5253e79c VARCHAR(255);
  p_Description_5253e79c TEXT;
  p_Category_5253e79c VARCHAR(100);
  p_Type_5253e79c VARCHAR(100);
  p_Length_5253e79c INTEGER;
  p_Precision_5253e79c INTEGER;
  p_Scale_5253e79c INTEGER;
  p_AllowsNull_5253e79c BOOLEAN;
  p_DefaultValue_5253e79c VARCHAR(255);
  p_IsPrimaryKey_5253e79c BOOLEAN;
  p_IsUniqueKey_5253e79c BOOLEAN;
  p_IsReadOnly_5253e79c BOOLEAN;
  p_IsRequired_5253e79c BOOLEAN;
  p_RelatedIntegrationObjectID_5253e79c UUID;
  p_RelatedIntegrationObjectFieldName_5253e79c VARCHAR(255);
  p_Sequence_5253e79c INTEGER;
  p_Configuration_5253e79c TEXT;
  p_Status_5253e79c VARCHAR(25);
  p_IsCustom_5253e79c BOOLEAN;
  p_MetadataSource_5253e79c VARCHAR(20);
BEGIN
  p_ID_5253e79c := '82425058-1EEF-53C5-85DA-56D668903918';
  p_IntegrationObjectID_5253e79c := '2139B63E-5944-4542-BE5E-7213D64B9750';
  p_Name_5253e79c := 'organization-disambiguation-source';
  p_DisplayName_5253e79c := 'Organization Disambiguation Source';
  p_Description_5253e79c := 'Registry the disambiguated id comes from (RINGGOLD, ROR, FUNDREF, GRID, LEI).';
  p_Type_5253e79c := 'String';
  p_Length_5253e79c := 100;
  p_AllowsNull_5253e79c := TRUE;
  p_IsPrimaryKey_5253e79c := FALSE;
  p_IsUniqueKey_5253e79c := FALSE;
  p_IsReadOnly_5253e79c := TRUE;
  p_IsRequired_5253e79c := FALSE;
  p_Sequence_5253e79c := 26;
  p_Status_5253e79c := 'Active';
  p_IsCustom_5253e79c := FALSE;
  p_MetadataSource_5253e79c := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_5253e79c, p_IntegrationObjectID := p_IntegrationObjectID_5253e79c, p_Name := p_Name_5253e79c, p_DisplayName := p_DisplayName_5253e79c, p_Description := p_Description_5253e79c, p_Category := p_Category_5253e79c, p_Category_Clear := TRUE, p_Type := p_Type_5253e79c, p_Length := p_Length_5253e79c, p_Precision := p_Precision_5253e79c, p_Precision_Clear := TRUE, p_Scale := p_Scale_5253e79c, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_5253e79c, p_DefaultValue := p_DefaultValue_5253e79c, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_5253e79c, p_IsUniqueKey := p_IsUniqueKey_5253e79c, p_IsReadOnly := p_IsReadOnly_5253e79c, p_IsRequired := p_IsRequired_5253e79c, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_5253e79c, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_5253e79c, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_5253e79c, p_Configuration := p_Configuration_5253e79c, p_Configuration_Clear := TRUE, p_Status := p_Status_5253e79c, p_IsCustom := p_IsCustom_5253e79c, p_MetadataSource := p_MetadataSource_5253e79c);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_573ab27d UUID;
  p_IntegrationObjectID_573ab27d UUID;
  p_Name_573ab27d VARCHAR(255);
  p_DisplayName_573ab27d VARCHAR(255);
  p_Description_573ab27d TEXT;
  p_Category_573ab27d VARCHAR(100);
  p_Type_573ab27d VARCHAR(100);
  p_Length_573ab27d INTEGER;
  p_Precision_573ab27d INTEGER;
  p_Scale_573ab27d INTEGER;
  p_AllowsNull_573ab27d BOOLEAN;
  p_DefaultValue_573ab27d VARCHAR(255);
  p_IsPrimaryKey_573ab27d BOOLEAN;
  p_IsUniqueKey_573ab27d BOOLEAN;
  p_IsReadOnly_573ab27d BOOLEAN;
  p_IsRequired_573ab27d BOOLEAN;
  p_RelatedIntegrationObjectID_573ab27d UUID;
  p_RelatedIntegrationObjectFieldName_573ab27d VARCHAR(255);
  p_Sequence_573ab27d INTEGER;
  p_Configuration_573ab27d TEXT;
  p_Status_573ab27d VARCHAR(25);
  p_IsCustom_573ab27d BOOLEAN;
  p_MetadataSource_573ab27d VARCHAR(20);
BEGIN
  p_ID_573ab27d := 'EE8D98DD-272D-505C-A75E-305D27640B37';
  p_IntegrationObjectID_573ab27d := '2139B63E-5944-4542-BE5E-7213D64B9750';
  p_Name_573ab27d := 'source-name';
  p_DisplayName_573ab27d := 'Source Name';
  p_Description_573ab27d := 'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.';
  p_Type_573ab27d := 'String';
  p_Length_573ab27d := 500;
  p_AllowsNull_573ab27d := TRUE;
  p_IsPrimaryKey_573ab27d := FALSE;
  p_IsUniqueKey_573ab27d := FALSE;
  p_IsReadOnly_573ab27d := TRUE;
  p_IsRequired_573ab27d := FALSE;
  p_Sequence_573ab27d := 27;
  p_Status_573ab27d := 'Active';
  p_IsCustom_573ab27d := FALSE;
  p_MetadataSource_573ab27d := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_573ab27d, p_IntegrationObjectID := p_IntegrationObjectID_573ab27d, p_Name := p_Name_573ab27d, p_DisplayName := p_DisplayName_573ab27d, p_Description := p_Description_573ab27d, p_Category := p_Category_573ab27d, p_Category_Clear := TRUE, p_Type := p_Type_573ab27d, p_Length := p_Length_573ab27d, p_Precision := p_Precision_573ab27d, p_Precision_Clear := TRUE, p_Scale := p_Scale_573ab27d, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_573ab27d, p_DefaultValue := p_DefaultValue_573ab27d, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_573ab27d, p_IsUniqueKey := p_IsUniqueKey_573ab27d, p_IsReadOnly := p_IsReadOnly_573ab27d, p_IsRequired := p_IsRequired_573ab27d, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_573ab27d, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_573ab27d, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_573ab27d, p_Configuration := p_Configuration_573ab27d, p_Configuration_Clear := TRUE, p_Status := p_Status_573ab27d, p_IsCustom := p_IsCustom_573ab27d, p_MetadataSource := p_MetadataSource_573ab27d);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_00dfed58 UUID;
  p_IntegrationObjectID_00dfed58 UUID;
  p_Name_00dfed58 VARCHAR(255);
  p_DisplayName_00dfed58 VARCHAR(255);
  p_Description_00dfed58 TEXT;
  p_Category_00dfed58 VARCHAR(100);
  p_Type_00dfed58 VARCHAR(100);
  p_Length_00dfed58 INTEGER;
  p_Precision_00dfed58 INTEGER;
  p_Scale_00dfed58 INTEGER;
  p_AllowsNull_00dfed58 BOOLEAN;
  p_DefaultValue_00dfed58 VARCHAR(255);
  p_IsPrimaryKey_00dfed58 BOOLEAN;
  p_IsUniqueKey_00dfed58 BOOLEAN;
  p_IsReadOnly_00dfed58 BOOLEAN;
  p_IsRequired_00dfed58 BOOLEAN;
  p_RelatedIntegrationObjectID_00dfed58 UUID;
  p_RelatedIntegrationObjectFieldName_00dfed58 VARCHAR(255);
  p_Sequence_00dfed58 INTEGER;
  p_Configuration_00dfed58 TEXT;
  p_Status_00dfed58 VARCHAR(25);
  p_IsCustom_00dfed58 BOOLEAN;
  p_MetadataSource_00dfed58 VARCHAR(20);
BEGIN
  p_ID_00dfed58 := '6A1B2BC9-537D-5BAC-944A-BCCE23C1C675';
  p_IntegrationObjectID_00dfed58 := '2139B63E-5944-4542-BE5E-7213D64B9750';
  p_Name_00dfed58 := 'source-orcid';
  p_DisplayName_00dfed58 := 'Source Orcid';
  p_Description_00dfed58 := 'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.';
  p_Type_00dfed58 := 'String';
  p_Length_00dfed58 := 19;
  p_AllowsNull_00dfed58 := TRUE;
  p_IsPrimaryKey_00dfed58 := FALSE;
  p_IsUniqueKey_00dfed58 := FALSE;
  p_IsReadOnly_00dfed58 := TRUE;
  p_IsRequired_00dfed58 := FALSE;
  p_Sequence_00dfed58 := 28;
  p_Status_00dfed58 := 'Active';
  p_IsCustom_00dfed58 := FALSE;
  p_MetadataSource_00dfed58 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_00dfed58, p_IntegrationObjectID := p_IntegrationObjectID_00dfed58, p_Name := p_Name_00dfed58, p_DisplayName := p_DisplayName_00dfed58, p_Description := p_Description_00dfed58, p_Category := p_Category_00dfed58, p_Category_Clear := TRUE, p_Type := p_Type_00dfed58, p_Length := p_Length_00dfed58, p_Precision := p_Precision_00dfed58, p_Precision_Clear := TRUE, p_Scale := p_Scale_00dfed58, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_00dfed58, p_DefaultValue := p_DefaultValue_00dfed58, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_00dfed58, p_IsUniqueKey := p_IsUniqueKey_00dfed58, p_IsReadOnly := p_IsReadOnly_00dfed58, p_IsRequired := p_IsRequired_00dfed58, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_00dfed58, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_00dfed58, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_00dfed58, p_Configuration := p_Configuration_00dfed58, p_Configuration_Clear := TRUE, p_Status := p_Status_00dfed58, p_IsCustom := p_IsCustom_00dfed58, p_MetadataSource := p_MetadataSource_00dfed58);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_3938e41e UUID;
  p_IntegrationObjectID_3938e41e UUID;
  p_Name_3938e41e VARCHAR(255);
  p_DisplayName_3938e41e VARCHAR(255);
  p_Description_3938e41e TEXT;
  p_Category_3938e41e VARCHAR(100);
  p_Type_3938e41e VARCHAR(100);
  p_Length_3938e41e INTEGER;
  p_Precision_3938e41e INTEGER;
  p_Scale_3938e41e INTEGER;
  p_AllowsNull_3938e41e BOOLEAN;
  p_DefaultValue_3938e41e VARCHAR(255);
  p_IsPrimaryKey_3938e41e BOOLEAN;
  p_IsUniqueKey_3938e41e BOOLEAN;
  p_IsReadOnly_3938e41e BOOLEAN;
  p_IsRequired_3938e41e BOOLEAN;
  p_RelatedIntegrationObjectID_3938e41e UUID;
  p_RelatedIntegrationObjectFieldName_3938e41e VARCHAR(255);
  p_Sequence_3938e41e INTEGER;
  p_Configuration_3938e41e TEXT;
  p_Status_3938e41e VARCHAR(25);
  p_IsCustom_3938e41e BOOLEAN;
  p_MetadataSource_3938e41e VARCHAR(20);
BEGIN
  p_ID_3938e41e := 'CBCC26E7-008B-5E7B-A5D3-717651705852';
  p_IntegrationObjectID_3938e41e := '5DD9CF05-1571-454E-BA40-D65E6B9C2131';
  p_Name_3938e41e := 'start-year';
  p_DisplayName_3938e41e := 'Start Year';
  p_Description_3938e41e := 'Year of the affiliation start date; ORCID dates are partial, so month/day may be absent.';
  p_Type_3938e41e := 'Integer';
  p_AllowsNull_3938e41e := TRUE;
  p_IsPrimaryKey_3938e41e := FALSE;
  p_IsUniqueKey_3938e41e := FALSE;
  p_IsReadOnly_3938e41e := TRUE;
  p_IsRequired_3938e41e := FALSE;
  p_Sequence_3938e41e := 15;
  p_Status_3938e41e := 'Active';
  p_IsCustom_3938e41e := FALSE;
  p_MetadataSource_3938e41e := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_3938e41e, p_IntegrationObjectID := p_IntegrationObjectID_3938e41e, p_Name := p_Name_3938e41e, p_DisplayName := p_DisplayName_3938e41e, p_Description := p_Description_3938e41e, p_Category := p_Category_3938e41e, p_Category_Clear := TRUE, p_Type := p_Type_3938e41e, p_Length := p_Length_3938e41e, p_Length_Clear := TRUE, p_Precision := p_Precision_3938e41e, p_Precision_Clear := TRUE, p_Scale := p_Scale_3938e41e, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_3938e41e, p_DefaultValue := p_DefaultValue_3938e41e, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_3938e41e, p_IsUniqueKey := p_IsUniqueKey_3938e41e, p_IsReadOnly := p_IsReadOnly_3938e41e, p_IsRequired := p_IsRequired_3938e41e, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_3938e41e, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_3938e41e, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_3938e41e, p_Configuration := p_Configuration_3938e41e, p_Configuration_Clear := TRUE, p_Status := p_Status_3938e41e, p_IsCustom := p_IsCustom_3938e41e, p_MetadataSource := p_MetadataSource_3938e41e);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_a5732338 UUID;
  p_IntegrationObjectID_a5732338 UUID;
  p_Name_a5732338 VARCHAR(255);
  p_DisplayName_a5732338 VARCHAR(255);
  p_Description_a5732338 TEXT;
  p_Category_a5732338 VARCHAR(100);
  p_Type_a5732338 VARCHAR(100);
  p_Length_a5732338 INTEGER;
  p_Precision_a5732338 INTEGER;
  p_Scale_a5732338 INTEGER;
  p_AllowsNull_a5732338 BOOLEAN;
  p_DefaultValue_a5732338 VARCHAR(255);
  p_IsPrimaryKey_a5732338 BOOLEAN;
  p_IsUniqueKey_a5732338 BOOLEAN;
  p_IsReadOnly_a5732338 BOOLEAN;
  p_IsRequired_a5732338 BOOLEAN;
  p_RelatedIntegrationObjectID_a5732338 UUID;
  p_RelatedIntegrationObjectFieldName_a5732338 VARCHAR(255);
  p_Sequence_a5732338 INTEGER;
  p_Configuration_a5732338 TEXT;
  p_Status_a5732338 VARCHAR(25);
  p_IsCustom_a5732338 BOOLEAN;
  p_MetadataSource_a5732338 VARCHAR(20);
BEGIN
  p_ID_a5732338 := 'D0966733-A52A-5137-A446-3F91A37B1299';
  p_IntegrationObjectID_a5732338 := '5DD9CF05-1571-454E-BA40-D65E6B9C2131';
  p_Name_a5732338 := 'start-month';
  p_DisplayName_a5732338 := 'Start Month';
  p_Description_a5732338 := 'Month (1-12) of the affiliation start date, when given.';
  p_Type_a5732338 := 'Integer';
  p_AllowsNull_a5732338 := TRUE;
  p_IsPrimaryKey_a5732338 := FALSE;
  p_IsUniqueKey_a5732338 := FALSE;
  p_IsReadOnly_a5732338 := TRUE;
  p_IsRequired_a5732338 := FALSE;
  p_Sequence_a5732338 := 16;
  p_Status_a5732338 := 'Active';
  p_IsCustom_a5732338 := FALSE;
  p_MetadataSource_a5732338 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_a5732338, p_IntegrationObjectID := p_IntegrationObjectID_a5732338, p_Name := p_Name_a5732338, p_DisplayName := p_DisplayName_a5732338, p_Description := p_Description_a5732338, p_Category := p_Category_a5732338, p_Category_Clear := TRUE, p_Type := p_Type_a5732338, p_Length := p_Length_a5732338, p_Length_Clear := TRUE, p_Precision := p_Precision_a5732338, p_Precision_Clear := TRUE, p_Scale := p_Scale_a5732338, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_a5732338, p_DefaultValue := p_DefaultValue_a5732338, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_a5732338, p_IsUniqueKey := p_IsUniqueKey_a5732338, p_IsReadOnly := p_IsReadOnly_a5732338, p_IsRequired := p_IsRequired_a5732338, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_a5732338, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_a5732338, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_a5732338, p_Configuration := p_Configuration_a5732338, p_Configuration_Clear := TRUE, p_Status := p_Status_a5732338, p_IsCustom := p_IsCustom_a5732338, p_MetadataSource := p_MetadataSource_a5732338);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_e4c377ac UUID;
  p_IntegrationObjectID_e4c377ac UUID;
  p_Name_e4c377ac VARCHAR(255);
  p_DisplayName_e4c377ac VARCHAR(255);
  p_Description_e4c377ac TEXT;
  p_Category_e4c377ac VARCHAR(100);
  p_Type_e4c377ac VARCHAR(100);
  p_Length_e4c377ac INTEGER;
  p_Precision_e4c377ac INTEGER;
  p_Scale_e4c377ac INTEGER;
  p_AllowsNull_e4c377ac BOOLEAN;
  p_DefaultValue_e4c377ac VARCHAR(255);
  p_IsPrimaryKey_e4c377ac BOOLEAN;
  p_IsUniqueKey_e4c377ac BOOLEAN;
  p_IsReadOnly_e4c377ac BOOLEAN;
  p_IsRequired_e4c377ac BOOLEAN;
  p_RelatedIntegrationObjectID_e4c377ac UUID;
  p_RelatedIntegrationObjectFieldName_e4c377ac VARCHAR(255);
  p_Sequence_e4c377ac INTEGER;
  p_Configuration_e4c377ac TEXT;
  p_Status_e4c377ac VARCHAR(25);
  p_IsCustom_e4c377ac BOOLEAN;
  p_MetadataSource_e4c377ac VARCHAR(20);
BEGIN
  p_ID_e4c377ac := '39D1FFA1-5E0F-5D16-9EE2-4810C6D8E001';
  p_IntegrationObjectID_e4c377ac := '5DD9CF05-1571-454E-BA40-D65E6B9C2131';
  p_Name_e4c377ac := 'start-day';
  p_DisplayName_e4c377ac := 'Start Day';
  p_Description_e4c377ac := 'Day of month of the affiliation start date, when given.';
  p_Type_e4c377ac := 'Integer';
  p_AllowsNull_e4c377ac := TRUE;
  p_IsPrimaryKey_e4c377ac := FALSE;
  p_IsUniqueKey_e4c377ac := FALSE;
  p_IsReadOnly_e4c377ac := TRUE;
  p_IsRequired_e4c377ac := FALSE;
  p_Sequence_e4c377ac := 17;
  p_Status_e4c377ac := 'Active';
  p_IsCustom_e4c377ac := FALSE;
  p_MetadataSource_e4c377ac := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_e4c377ac, p_IntegrationObjectID := p_IntegrationObjectID_e4c377ac, p_Name := p_Name_e4c377ac, p_DisplayName := p_DisplayName_e4c377ac, p_Description := p_Description_e4c377ac, p_Category := p_Category_e4c377ac, p_Category_Clear := TRUE, p_Type := p_Type_e4c377ac, p_Length := p_Length_e4c377ac, p_Length_Clear := TRUE, p_Precision := p_Precision_e4c377ac, p_Precision_Clear := TRUE, p_Scale := p_Scale_e4c377ac, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_e4c377ac, p_DefaultValue := p_DefaultValue_e4c377ac, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_e4c377ac, p_IsUniqueKey := p_IsUniqueKey_e4c377ac, p_IsReadOnly := p_IsReadOnly_e4c377ac, p_IsRequired := p_IsRequired_e4c377ac, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_e4c377ac, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_e4c377ac, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_e4c377ac, p_Configuration := p_Configuration_e4c377ac, p_Configuration_Clear := TRUE, p_Status := p_Status_e4c377ac, p_IsCustom := p_IsCustom_e4c377ac, p_MetadataSource := p_MetadataSource_e4c377ac);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_2d428f74 UUID;
  p_IntegrationObjectID_2d428f74 UUID;
  p_Name_2d428f74 VARCHAR(255);
  p_DisplayName_2d428f74 VARCHAR(255);
  p_Description_2d428f74 TEXT;
  p_Category_2d428f74 VARCHAR(100);
  p_Type_2d428f74 VARCHAR(100);
  p_Length_2d428f74 INTEGER;
  p_Precision_2d428f74 INTEGER;
  p_Scale_2d428f74 INTEGER;
  p_AllowsNull_2d428f74 BOOLEAN;
  p_DefaultValue_2d428f74 VARCHAR(255);
  p_IsPrimaryKey_2d428f74 BOOLEAN;
  p_IsUniqueKey_2d428f74 BOOLEAN;
  p_IsReadOnly_2d428f74 BOOLEAN;
  p_IsRequired_2d428f74 BOOLEAN;
  p_RelatedIntegrationObjectID_2d428f74 UUID;
  p_RelatedIntegrationObjectFieldName_2d428f74 VARCHAR(255);
  p_Sequence_2d428f74 INTEGER;
  p_Configuration_2d428f74 TEXT;
  p_Status_2d428f74 VARCHAR(25);
  p_IsCustom_2d428f74 BOOLEAN;
  p_MetadataSource_2d428f74 VARCHAR(20);
BEGIN
  p_ID_2d428f74 := '806C2EB8-7F31-5B52-B9BF-AD312F17E9E7';
  p_IntegrationObjectID_2d428f74 := '5DD9CF05-1571-454E-BA40-D65E6B9C2131';
  p_Name_2d428f74 := 'end-year';
  p_DisplayName_2d428f74 := 'End Year';
  p_Description_2d428f74 := 'Year of the affiliation end date; empty for a current/ongoing role; ORCID dates are partial, so month/day may be absent.';
  p_Type_2d428f74 := 'Integer';
  p_AllowsNull_2d428f74 := TRUE;
  p_IsPrimaryKey_2d428f74 := FALSE;
  p_IsUniqueKey_2d428f74 := FALSE;
  p_IsReadOnly_2d428f74 := TRUE;
  p_IsRequired_2d428f74 := FALSE;
  p_Sequence_2d428f74 := 18;
  p_Status_2d428f74 := 'Active';
  p_IsCustom_2d428f74 := FALSE;
  p_MetadataSource_2d428f74 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_2d428f74, p_IntegrationObjectID := p_IntegrationObjectID_2d428f74, p_Name := p_Name_2d428f74, p_DisplayName := p_DisplayName_2d428f74, p_Description := p_Description_2d428f74, p_Category := p_Category_2d428f74, p_Category_Clear := TRUE, p_Type := p_Type_2d428f74, p_Length := p_Length_2d428f74, p_Length_Clear := TRUE, p_Precision := p_Precision_2d428f74, p_Precision_Clear := TRUE, p_Scale := p_Scale_2d428f74, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_2d428f74, p_DefaultValue := p_DefaultValue_2d428f74, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_2d428f74, p_IsUniqueKey := p_IsUniqueKey_2d428f74, p_IsReadOnly := p_IsReadOnly_2d428f74, p_IsRequired := p_IsRequired_2d428f74, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_2d428f74, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_2d428f74, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_2d428f74, p_Configuration := p_Configuration_2d428f74, p_Configuration_Clear := TRUE, p_Status := p_Status_2d428f74, p_IsCustom := p_IsCustom_2d428f74, p_MetadataSource := p_MetadataSource_2d428f74);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_50d91ade UUID;
  p_IntegrationObjectID_50d91ade UUID;
  p_Name_50d91ade VARCHAR(255);
  p_DisplayName_50d91ade VARCHAR(255);
  p_Description_50d91ade TEXT;
  p_Category_50d91ade VARCHAR(100);
  p_Type_50d91ade VARCHAR(100);
  p_Length_50d91ade INTEGER;
  p_Precision_50d91ade INTEGER;
  p_Scale_50d91ade INTEGER;
  p_AllowsNull_50d91ade BOOLEAN;
  p_DefaultValue_50d91ade VARCHAR(255);
  p_IsPrimaryKey_50d91ade BOOLEAN;
  p_IsUniqueKey_50d91ade BOOLEAN;
  p_IsReadOnly_50d91ade BOOLEAN;
  p_IsRequired_50d91ade BOOLEAN;
  p_RelatedIntegrationObjectID_50d91ade UUID;
  p_RelatedIntegrationObjectFieldName_50d91ade VARCHAR(255);
  p_Sequence_50d91ade INTEGER;
  p_Configuration_50d91ade TEXT;
  p_Status_50d91ade VARCHAR(25);
  p_IsCustom_50d91ade BOOLEAN;
  p_MetadataSource_50d91ade VARCHAR(20);
BEGIN
  p_ID_50d91ade := '40B42903-AF02-5EA1-B32A-3365B4E4AC4B';
  p_IntegrationObjectID_50d91ade := '5DD9CF05-1571-454E-BA40-D65E6B9C2131';
  p_Name_50d91ade := 'end-month';
  p_DisplayName_50d91ade := 'End Month';
  p_Description_50d91ade := 'Month (1-12) of the affiliation end date; empty for a current/ongoing role, when given.';
  p_Type_50d91ade := 'Integer';
  p_AllowsNull_50d91ade := TRUE;
  p_IsPrimaryKey_50d91ade := FALSE;
  p_IsUniqueKey_50d91ade := FALSE;
  p_IsReadOnly_50d91ade := TRUE;
  p_IsRequired_50d91ade := FALSE;
  p_Sequence_50d91ade := 19;
  p_Status_50d91ade := 'Active';
  p_IsCustom_50d91ade := FALSE;
  p_MetadataSource_50d91ade := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_50d91ade, p_IntegrationObjectID := p_IntegrationObjectID_50d91ade, p_Name := p_Name_50d91ade, p_DisplayName := p_DisplayName_50d91ade, p_Description := p_Description_50d91ade, p_Category := p_Category_50d91ade, p_Category_Clear := TRUE, p_Type := p_Type_50d91ade, p_Length := p_Length_50d91ade, p_Length_Clear := TRUE, p_Precision := p_Precision_50d91ade, p_Precision_Clear := TRUE, p_Scale := p_Scale_50d91ade, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_50d91ade, p_DefaultValue := p_DefaultValue_50d91ade, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_50d91ade, p_IsUniqueKey := p_IsUniqueKey_50d91ade, p_IsReadOnly := p_IsReadOnly_50d91ade, p_IsRequired := p_IsRequired_50d91ade, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_50d91ade, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_50d91ade, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_50d91ade, p_Configuration := p_Configuration_50d91ade, p_Configuration_Clear := TRUE, p_Status := p_Status_50d91ade, p_IsCustom := p_IsCustom_50d91ade, p_MetadataSource := p_MetadataSource_50d91ade);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_69effdca UUID;
  p_IntegrationObjectID_69effdca UUID;
  p_Name_69effdca VARCHAR(255);
  p_DisplayName_69effdca VARCHAR(255);
  p_Description_69effdca TEXT;
  p_Category_69effdca VARCHAR(100);
  p_Type_69effdca VARCHAR(100);
  p_Length_69effdca INTEGER;
  p_Precision_69effdca INTEGER;
  p_Scale_69effdca INTEGER;
  p_AllowsNull_69effdca BOOLEAN;
  p_DefaultValue_69effdca VARCHAR(255);
  p_IsPrimaryKey_69effdca BOOLEAN;
  p_IsUniqueKey_69effdca BOOLEAN;
  p_IsReadOnly_69effdca BOOLEAN;
  p_IsRequired_69effdca BOOLEAN;
  p_RelatedIntegrationObjectID_69effdca UUID;
  p_RelatedIntegrationObjectFieldName_69effdca VARCHAR(255);
  p_Sequence_69effdca INTEGER;
  p_Configuration_69effdca TEXT;
  p_Status_69effdca VARCHAR(25);
  p_IsCustom_69effdca BOOLEAN;
  p_MetadataSource_69effdca VARCHAR(20);
BEGIN
  p_ID_69effdca := '352EA5ED-6C6C-5CCC-ACAA-EBE0A1EBE877';
  p_IntegrationObjectID_69effdca := '5DD9CF05-1571-454E-BA40-D65E6B9C2131';
  p_Name_69effdca := 'end-day';
  p_DisplayName_69effdca := 'End Day';
  p_Description_69effdca := 'Day of month of the affiliation end date; empty for a current/ongoing role, when given.';
  p_Type_69effdca := 'Integer';
  p_AllowsNull_69effdca := TRUE;
  p_IsPrimaryKey_69effdca := FALSE;
  p_IsUniqueKey_69effdca := FALSE;
  p_IsReadOnly_69effdca := TRUE;
  p_IsRequired_69effdca := FALSE;
  p_Sequence_69effdca := 20;
  p_Status_69effdca := 'Active';
  p_IsCustom_69effdca := FALSE;
  p_MetadataSource_69effdca := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_69effdca, p_IntegrationObjectID := p_IntegrationObjectID_69effdca, p_Name := p_Name_69effdca, p_DisplayName := p_DisplayName_69effdca, p_Description := p_Description_69effdca, p_Category := p_Category_69effdca, p_Category_Clear := TRUE, p_Type := p_Type_69effdca, p_Length := p_Length_69effdca, p_Length_Clear := TRUE, p_Precision := p_Precision_69effdca, p_Precision_Clear := TRUE, p_Scale := p_Scale_69effdca, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_69effdca, p_DefaultValue := p_DefaultValue_69effdca, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_69effdca, p_IsUniqueKey := p_IsUniqueKey_69effdca, p_IsReadOnly := p_IsReadOnly_69effdca, p_IsRequired := p_IsRequired_69effdca, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_69effdca, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_69effdca, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_69effdca, p_Configuration := p_Configuration_69effdca, p_Configuration_Clear := TRUE, p_Status := p_Status_69effdca, p_IsCustom := p_IsCustom_69effdca, p_MetadataSource := p_MetadataSource_69effdca);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_6f1867b0 UUID;
  p_IntegrationObjectID_6f1867b0 UUID;
  p_Name_6f1867b0 VARCHAR(255);
  p_DisplayName_6f1867b0 VARCHAR(255);
  p_Description_6f1867b0 TEXT;
  p_Category_6f1867b0 VARCHAR(100);
  p_Type_6f1867b0 VARCHAR(100);
  p_Length_6f1867b0 INTEGER;
  p_Precision_6f1867b0 INTEGER;
  p_Scale_6f1867b0 INTEGER;
  p_AllowsNull_6f1867b0 BOOLEAN;
  p_DefaultValue_6f1867b0 VARCHAR(255);
  p_IsPrimaryKey_6f1867b0 BOOLEAN;
  p_IsUniqueKey_6f1867b0 BOOLEAN;
  p_IsReadOnly_6f1867b0 BOOLEAN;
  p_IsRequired_6f1867b0 BOOLEAN;
  p_RelatedIntegrationObjectID_6f1867b0 UUID;
  p_RelatedIntegrationObjectFieldName_6f1867b0 VARCHAR(255);
  p_Sequence_6f1867b0 INTEGER;
  p_Configuration_6f1867b0 TEXT;
  p_Status_6f1867b0 VARCHAR(25);
  p_IsCustom_6f1867b0 BOOLEAN;
  p_MetadataSource_6f1867b0 VARCHAR(20);
BEGIN
  p_ID_6f1867b0 := '017EF05F-9FBE-50B9-90F4-C2C443147BC7';
  p_IntegrationObjectID_6f1867b0 := '5DD9CF05-1571-454E-BA40-D65E6B9C2131';
  p_Name_6f1867b0 := 'organization-name';
  p_DisplayName_6f1867b0 := 'Organization Name';
  p_Description_6f1867b0 := 'Name of the organization. Lifted from organization.name.';
  p_Type_6f1867b0 := 'String';
  p_Length_6f1867b0 := 1000;
  p_AllowsNull_6f1867b0 := TRUE;
  p_IsPrimaryKey_6f1867b0 := FALSE;
  p_IsUniqueKey_6f1867b0 := FALSE;
  p_IsReadOnly_6f1867b0 := TRUE;
  p_IsRequired_6f1867b0 := FALSE;
  p_Sequence_6f1867b0 := 21;
  p_Status_6f1867b0 := 'Active';
  p_IsCustom_6f1867b0 := FALSE;
  p_MetadataSource_6f1867b0 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_6f1867b0, p_IntegrationObjectID := p_IntegrationObjectID_6f1867b0, p_Name := p_Name_6f1867b0, p_DisplayName := p_DisplayName_6f1867b0, p_Description := p_Description_6f1867b0, p_Category := p_Category_6f1867b0, p_Category_Clear := TRUE, p_Type := p_Type_6f1867b0, p_Length := p_Length_6f1867b0, p_Precision := p_Precision_6f1867b0, p_Precision_Clear := TRUE, p_Scale := p_Scale_6f1867b0, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_6f1867b0, p_DefaultValue := p_DefaultValue_6f1867b0, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_6f1867b0, p_IsUniqueKey := p_IsUniqueKey_6f1867b0, p_IsReadOnly := p_IsReadOnly_6f1867b0, p_IsRequired := p_IsRequired_6f1867b0, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_6f1867b0, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_6f1867b0, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_6f1867b0, p_Configuration := p_Configuration_6f1867b0, p_Configuration_Clear := TRUE, p_Status := p_Status_6f1867b0, p_IsCustom := p_IsCustom_6f1867b0, p_MetadataSource := p_MetadataSource_6f1867b0);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_200f90fb UUID;
  p_IntegrationObjectID_200f90fb UUID;
  p_Name_200f90fb VARCHAR(255);
  p_DisplayName_200f90fb VARCHAR(255);
  p_Description_200f90fb TEXT;
  p_Category_200f90fb VARCHAR(100);
  p_Type_200f90fb VARCHAR(100);
  p_Length_200f90fb INTEGER;
  p_Precision_200f90fb INTEGER;
  p_Scale_200f90fb INTEGER;
  p_AllowsNull_200f90fb BOOLEAN;
  p_DefaultValue_200f90fb VARCHAR(255);
  p_IsPrimaryKey_200f90fb BOOLEAN;
  p_IsUniqueKey_200f90fb BOOLEAN;
  p_IsReadOnly_200f90fb BOOLEAN;
  p_IsRequired_200f90fb BOOLEAN;
  p_RelatedIntegrationObjectID_200f90fb UUID;
  p_RelatedIntegrationObjectFieldName_200f90fb VARCHAR(255);
  p_Sequence_200f90fb INTEGER;
  p_Configuration_200f90fb TEXT;
  p_Status_200f90fb VARCHAR(25);
  p_IsCustom_200f90fb BOOLEAN;
  p_MetadataSource_200f90fb VARCHAR(20);
BEGIN
  p_ID_200f90fb := '7D58D030-EE2F-5C1B-B03B-778BF49BA030';
  p_IntegrationObjectID_200f90fb := '5DD9CF05-1571-454E-BA40-D65E6B9C2131';
  p_Name_200f90fb := 'organization-city';
  p_DisplayName_200f90fb := 'Organization City';
  p_Description_200f90fb := 'City of the organization. Lifted from organization.address.city.';
  p_Type_200f90fb := 'String';
  p_Length_200f90fb := 255;
  p_AllowsNull_200f90fb := TRUE;
  p_IsPrimaryKey_200f90fb := FALSE;
  p_IsUniqueKey_200f90fb := FALSE;
  p_IsReadOnly_200f90fb := TRUE;
  p_IsRequired_200f90fb := FALSE;
  p_Sequence_200f90fb := 22;
  p_Status_200f90fb := 'Active';
  p_IsCustom_200f90fb := FALSE;
  p_MetadataSource_200f90fb := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_200f90fb, p_IntegrationObjectID := p_IntegrationObjectID_200f90fb, p_Name := p_Name_200f90fb, p_DisplayName := p_DisplayName_200f90fb, p_Description := p_Description_200f90fb, p_Category := p_Category_200f90fb, p_Category_Clear := TRUE, p_Type := p_Type_200f90fb, p_Length := p_Length_200f90fb, p_Precision := p_Precision_200f90fb, p_Precision_Clear := TRUE, p_Scale := p_Scale_200f90fb, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_200f90fb, p_DefaultValue := p_DefaultValue_200f90fb, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_200f90fb, p_IsUniqueKey := p_IsUniqueKey_200f90fb, p_IsReadOnly := p_IsReadOnly_200f90fb, p_IsRequired := p_IsRequired_200f90fb, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_200f90fb, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_200f90fb, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_200f90fb, p_Configuration := p_Configuration_200f90fb, p_Configuration_Clear := TRUE, p_Status := p_Status_200f90fb, p_IsCustom := p_IsCustom_200f90fb, p_MetadataSource := p_MetadataSource_200f90fb);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_31082ea3 UUID;
  p_IntegrationObjectID_31082ea3 UUID;
  p_Name_31082ea3 VARCHAR(255);
  p_DisplayName_31082ea3 VARCHAR(255);
  p_Description_31082ea3 TEXT;
  p_Category_31082ea3 VARCHAR(100);
  p_Type_31082ea3 VARCHAR(100);
  p_Length_31082ea3 INTEGER;
  p_Precision_31082ea3 INTEGER;
  p_Scale_31082ea3 INTEGER;
  p_AllowsNull_31082ea3 BOOLEAN;
  p_DefaultValue_31082ea3 VARCHAR(255);
  p_IsPrimaryKey_31082ea3 BOOLEAN;
  p_IsUniqueKey_31082ea3 BOOLEAN;
  p_IsReadOnly_31082ea3 BOOLEAN;
  p_IsRequired_31082ea3 BOOLEAN;
  p_RelatedIntegrationObjectID_31082ea3 UUID;
  p_RelatedIntegrationObjectFieldName_31082ea3 VARCHAR(255);
  p_Sequence_31082ea3 INTEGER;
  p_Configuration_31082ea3 TEXT;
  p_Status_31082ea3 VARCHAR(25);
  p_IsCustom_31082ea3 BOOLEAN;
  p_MetadataSource_31082ea3 VARCHAR(20);
BEGIN
  p_ID_31082ea3 := 'AE844B1B-9F7B-5103-A52F-64B2B4653F49';
  p_IntegrationObjectID_31082ea3 := '5DD9CF05-1571-454E-BA40-D65E6B9C2131';
  p_Name_31082ea3 := 'organization-region';
  p_DisplayName_31082ea3 := 'Organization Region';
  p_Description_31082ea3 := 'Region/state of the organization. Lifted from organization.address.region.';
  p_Type_31082ea3 := 'String';
  p_Length_31082ea3 := 255;
  p_AllowsNull_31082ea3 := TRUE;
  p_IsPrimaryKey_31082ea3 := FALSE;
  p_IsUniqueKey_31082ea3 := FALSE;
  p_IsReadOnly_31082ea3 := TRUE;
  p_IsRequired_31082ea3 := FALSE;
  p_Sequence_31082ea3 := 23;
  p_Status_31082ea3 := 'Active';
  p_IsCustom_31082ea3 := FALSE;
  p_MetadataSource_31082ea3 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_31082ea3, p_IntegrationObjectID := p_IntegrationObjectID_31082ea3, p_Name := p_Name_31082ea3, p_DisplayName := p_DisplayName_31082ea3, p_Description := p_Description_31082ea3, p_Category := p_Category_31082ea3, p_Category_Clear := TRUE, p_Type := p_Type_31082ea3, p_Length := p_Length_31082ea3, p_Precision := p_Precision_31082ea3, p_Precision_Clear := TRUE, p_Scale := p_Scale_31082ea3, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_31082ea3, p_DefaultValue := p_DefaultValue_31082ea3, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_31082ea3, p_IsUniqueKey := p_IsUniqueKey_31082ea3, p_IsReadOnly := p_IsReadOnly_31082ea3, p_IsRequired := p_IsRequired_31082ea3, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_31082ea3, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_31082ea3, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_31082ea3, p_Configuration := p_Configuration_31082ea3, p_Configuration_Clear := TRUE, p_Status := p_Status_31082ea3, p_IsCustom := p_IsCustom_31082ea3, p_MetadataSource := p_MetadataSource_31082ea3);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_6a6e7be2 UUID;
  p_IntegrationObjectID_6a6e7be2 UUID;
  p_Name_6a6e7be2 VARCHAR(255);
  p_DisplayName_6a6e7be2 VARCHAR(255);
  p_Description_6a6e7be2 TEXT;
  p_Category_6a6e7be2 VARCHAR(100);
  p_Type_6a6e7be2 VARCHAR(100);
  p_Length_6a6e7be2 INTEGER;
  p_Precision_6a6e7be2 INTEGER;
  p_Scale_6a6e7be2 INTEGER;
  p_AllowsNull_6a6e7be2 BOOLEAN;
  p_DefaultValue_6a6e7be2 VARCHAR(255);
  p_IsPrimaryKey_6a6e7be2 BOOLEAN;
  p_IsUniqueKey_6a6e7be2 BOOLEAN;
  p_IsReadOnly_6a6e7be2 BOOLEAN;
  p_IsRequired_6a6e7be2 BOOLEAN;
  p_RelatedIntegrationObjectID_6a6e7be2 UUID;
  p_RelatedIntegrationObjectFieldName_6a6e7be2 VARCHAR(255);
  p_Sequence_6a6e7be2 INTEGER;
  p_Configuration_6a6e7be2 TEXT;
  p_Status_6a6e7be2 VARCHAR(25);
  p_IsCustom_6a6e7be2 BOOLEAN;
  p_MetadataSource_6a6e7be2 VARCHAR(20);
BEGIN
  p_ID_6a6e7be2 := 'DD2F4D8E-AE98-56E8-9475-DDC1B34CE279';
  p_IntegrationObjectID_6a6e7be2 := '5DD9CF05-1571-454E-BA40-D65E6B9C2131';
  p_Name_6a6e7be2 := 'organization-country';
  p_DisplayName_6a6e7be2 := 'Organization Country';
  p_Description_6a6e7be2 := 'ISO country code of the organization. Lifted from organization.address.country.';
  p_Type_6a6e7be2 := 'String';
  p_Length_6a6e7be2 := 50;
  p_AllowsNull_6a6e7be2 := TRUE;
  p_IsPrimaryKey_6a6e7be2 := FALSE;
  p_IsUniqueKey_6a6e7be2 := FALSE;
  p_IsReadOnly_6a6e7be2 := TRUE;
  p_IsRequired_6a6e7be2 := FALSE;
  p_Sequence_6a6e7be2 := 24;
  p_Status_6a6e7be2 := 'Active';
  p_IsCustom_6a6e7be2 := FALSE;
  p_MetadataSource_6a6e7be2 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_6a6e7be2, p_IntegrationObjectID := p_IntegrationObjectID_6a6e7be2, p_Name := p_Name_6a6e7be2, p_DisplayName := p_DisplayName_6a6e7be2, p_Description := p_Description_6a6e7be2, p_Category := p_Category_6a6e7be2, p_Category_Clear := TRUE, p_Type := p_Type_6a6e7be2, p_Length := p_Length_6a6e7be2, p_Precision := p_Precision_6a6e7be2, p_Precision_Clear := TRUE, p_Scale := p_Scale_6a6e7be2, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_6a6e7be2, p_DefaultValue := p_DefaultValue_6a6e7be2, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_6a6e7be2, p_IsUniqueKey := p_IsUniqueKey_6a6e7be2, p_IsReadOnly := p_IsReadOnly_6a6e7be2, p_IsRequired := p_IsRequired_6a6e7be2, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_6a6e7be2, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_6a6e7be2, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_6a6e7be2, p_Configuration := p_Configuration_6a6e7be2, p_Configuration_Clear := TRUE, p_Status := p_Status_6a6e7be2, p_IsCustom := p_IsCustom_6a6e7be2, p_MetadataSource := p_MetadataSource_6a6e7be2);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_b2c158fd UUID;
  p_IntegrationObjectID_b2c158fd UUID;
  p_Name_b2c158fd VARCHAR(255);
  p_DisplayName_b2c158fd VARCHAR(255);
  p_Description_b2c158fd TEXT;
  p_Category_b2c158fd VARCHAR(100);
  p_Type_b2c158fd VARCHAR(100);
  p_Length_b2c158fd INTEGER;
  p_Precision_b2c158fd INTEGER;
  p_Scale_b2c158fd INTEGER;
  p_AllowsNull_b2c158fd BOOLEAN;
  p_DefaultValue_b2c158fd VARCHAR(255);
  p_IsPrimaryKey_b2c158fd BOOLEAN;
  p_IsUniqueKey_b2c158fd BOOLEAN;
  p_IsReadOnly_b2c158fd BOOLEAN;
  p_IsRequired_b2c158fd BOOLEAN;
  p_RelatedIntegrationObjectID_b2c158fd UUID;
  p_RelatedIntegrationObjectFieldName_b2c158fd VARCHAR(255);
  p_Sequence_b2c158fd INTEGER;
  p_Configuration_b2c158fd TEXT;
  p_Status_b2c158fd VARCHAR(25);
  p_IsCustom_b2c158fd BOOLEAN;
  p_MetadataSource_b2c158fd VARCHAR(20);
BEGIN
  p_ID_b2c158fd := '7310CFC9-9020-5C81-BA07-288C05F176F7';
  p_IntegrationObjectID_b2c158fd := '5DD9CF05-1571-454E-BA40-D65E6B9C2131';
  p_Name_b2c158fd := 'organization-disambiguated-id';
  p_DisplayName_b2c158fd := 'Organization Disambiguated Id';
  p_Description_b2c158fd := 'Canonical identifier of the organization in the disambiguation source (e.g. a RINGGOLD or ROR id), so the same institution matches across records.';
  p_Type_b2c158fd := 'String';
  p_Length_b2c158fd := 255;
  p_AllowsNull_b2c158fd := TRUE;
  p_IsPrimaryKey_b2c158fd := FALSE;
  p_IsUniqueKey_b2c158fd := FALSE;
  p_IsReadOnly_b2c158fd := TRUE;
  p_IsRequired_b2c158fd := FALSE;
  p_Sequence_b2c158fd := 25;
  p_Status_b2c158fd := 'Active';
  p_IsCustom_b2c158fd := FALSE;
  p_MetadataSource_b2c158fd := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_b2c158fd, p_IntegrationObjectID := p_IntegrationObjectID_b2c158fd, p_Name := p_Name_b2c158fd, p_DisplayName := p_DisplayName_b2c158fd, p_Description := p_Description_b2c158fd, p_Category := p_Category_b2c158fd, p_Category_Clear := TRUE, p_Type := p_Type_b2c158fd, p_Length := p_Length_b2c158fd, p_Precision := p_Precision_b2c158fd, p_Precision_Clear := TRUE, p_Scale := p_Scale_b2c158fd, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_b2c158fd, p_DefaultValue := p_DefaultValue_b2c158fd, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_b2c158fd, p_IsUniqueKey := p_IsUniqueKey_b2c158fd, p_IsReadOnly := p_IsReadOnly_b2c158fd, p_IsRequired := p_IsRequired_b2c158fd, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_b2c158fd, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_b2c158fd, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_b2c158fd, p_Configuration := p_Configuration_b2c158fd, p_Configuration_Clear := TRUE, p_Status := p_Status_b2c158fd, p_IsCustom := p_IsCustom_b2c158fd, p_MetadataSource := p_MetadataSource_b2c158fd);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_5570b8df UUID;
  p_IntegrationObjectID_5570b8df UUID;
  p_Name_5570b8df VARCHAR(255);
  p_DisplayName_5570b8df VARCHAR(255);
  p_Description_5570b8df TEXT;
  p_Category_5570b8df VARCHAR(100);
  p_Type_5570b8df VARCHAR(100);
  p_Length_5570b8df INTEGER;
  p_Precision_5570b8df INTEGER;
  p_Scale_5570b8df INTEGER;
  p_AllowsNull_5570b8df BOOLEAN;
  p_DefaultValue_5570b8df VARCHAR(255);
  p_IsPrimaryKey_5570b8df BOOLEAN;
  p_IsUniqueKey_5570b8df BOOLEAN;
  p_IsReadOnly_5570b8df BOOLEAN;
  p_IsRequired_5570b8df BOOLEAN;
  p_RelatedIntegrationObjectID_5570b8df UUID;
  p_RelatedIntegrationObjectFieldName_5570b8df VARCHAR(255);
  p_Sequence_5570b8df INTEGER;
  p_Configuration_5570b8df TEXT;
  p_Status_5570b8df VARCHAR(25);
  p_IsCustom_5570b8df BOOLEAN;
  p_MetadataSource_5570b8df VARCHAR(20);
BEGIN
  p_ID_5570b8df := '51F8A1B7-147D-5AC2-A164-BC1DB4BD30F8';
  p_IntegrationObjectID_5570b8df := '5DD9CF05-1571-454E-BA40-D65E6B9C2131';
  p_Name_5570b8df := 'organization-disambiguation-source';
  p_DisplayName_5570b8df := 'Organization Disambiguation Source';
  p_Description_5570b8df := 'Registry the disambiguated id comes from (RINGGOLD, ROR, FUNDREF, GRID, LEI).';
  p_Type_5570b8df := 'String';
  p_Length_5570b8df := 100;
  p_AllowsNull_5570b8df := TRUE;
  p_IsPrimaryKey_5570b8df := FALSE;
  p_IsUniqueKey_5570b8df := FALSE;
  p_IsReadOnly_5570b8df := TRUE;
  p_IsRequired_5570b8df := FALSE;
  p_Sequence_5570b8df := 26;
  p_Status_5570b8df := 'Active';
  p_IsCustom_5570b8df := FALSE;
  p_MetadataSource_5570b8df := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_5570b8df, p_IntegrationObjectID := p_IntegrationObjectID_5570b8df, p_Name := p_Name_5570b8df, p_DisplayName := p_DisplayName_5570b8df, p_Description := p_Description_5570b8df, p_Category := p_Category_5570b8df, p_Category_Clear := TRUE, p_Type := p_Type_5570b8df, p_Length := p_Length_5570b8df, p_Precision := p_Precision_5570b8df, p_Precision_Clear := TRUE, p_Scale := p_Scale_5570b8df, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_5570b8df, p_DefaultValue := p_DefaultValue_5570b8df, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_5570b8df, p_IsUniqueKey := p_IsUniqueKey_5570b8df, p_IsReadOnly := p_IsReadOnly_5570b8df, p_IsRequired := p_IsRequired_5570b8df, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_5570b8df, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_5570b8df, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_5570b8df, p_Configuration := p_Configuration_5570b8df, p_Configuration_Clear := TRUE, p_Status := p_Status_5570b8df, p_IsCustom := p_IsCustom_5570b8df, p_MetadataSource := p_MetadataSource_5570b8df);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_896ed3d8 UUID;
  p_IntegrationObjectID_896ed3d8 UUID;
  p_Name_896ed3d8 VARCHAR(255);
  p_DisplayName_896ed3d8 VARCHAR(255);
  p_Description_896ed3d8 TEXT;
  p_Category_896ed3d8 VARCHAR(100);
  p_Type_896ed3d8 VARCHAR(100);
  p_Length_896ed3d8 INTEGER;
  p_Precision_896ed3d8 INTEGER;
  p_Scale_896ed3d8 INTEGER;
  p_AllowsNull_896ed3d8 BOOLEAN;
  p_DefaultValue_896ed3d8 VARCHAR(255);
  p_IsPrimaryKey_896ed3d8 BOOLEAN;
  p_IsUniqueKey_896ed3d8 BOOLEAN;
  p_IsReadOnly_896ed3d8 BOOLEAN;
  p_IsRequired_896ed3d8 BOOLEAN;
  p_RelatedIntegrationObjectID_896ed3d8 UUID;
  p_RelatedIntegrationObjectFieldName_896ed3d8 VARCHAR(255);
  p_Sequence_896ed3d8 INTEGER;
  p_Configuration_896ed3d8 TEXT;
  p_Status_896ed3d8 VARCHAR(25);
  p_IsCustom_896ed3d8 BOOLEAN;
  p_MetadataSource_896ed3d8 VARCHAR(20);
BEGIN
  p_ID_896ed3d8 := '114B670D-8D6B-5BB6-BED6-EA991C5F2DA4';
  p_IntegrationObjectID_896ed3d8 := '5DD9CF05-1571-454E-BA40-D65E6B9C2131';
  p_Name_896ed3d8 := 'source-name';
  p_DisplayName_896ed3d8 := 'Source Name';
  p_Description_896ed3d8 := 'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.';
  p_Type_896ed3d8 := 'String';
  p_Length_896ed3d8 := 500;
  p_AllowsNull_896ed3d8 := TRUE;
  p_IsPrimaryKey_896ed3d8 := FALSE;
  p_IsUniqueKey_896ed3d8 := FALSE;
  p_IsReadOnly_896ed3d8 := TRUE;
  p_IsRequired_896ed3d8 := FALSE;
  p_Sequence_896ed3d8 := 27;
  p_Status_896ed3d8 := 'Active';
  p_IsCustom_896ed3d8 := FALSE;
  p_MetadataSource_896ed3d8 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_896ed3d8, p_IntegrationObjectID := p_IntegrationObjectID_896ed3d8, p_Name := p_Name_896ed3d8, p_DisplayName := p_DisplayName_896ed3d8, p_Description := p_Description_896ed3d8, p_Category := p_Category_896ed3d8, p_Category_Clear := TRUE, p_Type := p_Type_896ed3d8, p_Length := p_Length_896ed3d8, p_Precision := p_Precision_896ed3d8, p_Precision_Clear := TRUE, p_Scale := p_Scale_896ed3d8, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_896ed3d8, p_DefaultValue := p_DefaultValue_896ed3d8, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_896ed3d8, p_IsUniqueKey := p_IsUniqueKey_896ed3d8, p_IsReadOnly := p_IsReadOnly_896ed3d8, p_IsRequired := p_IsRequired_896ed3d8, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_896ed3d8, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_896ed3d8, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_896ed3d8, p_Configuration := p_Configuration_896ed3d8, p_Configuration_Clear := TRUE, p_Status := p_Status_896ed3d8, p_IsCustom := p_IsCustom_896ed3d8, p_MetadataSource := p_MetadataSource_896ed3d8);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_4e31f852 UUID;
  p_IntegrationObjectID_4e31f852 UUID;
  p_Name_4e31f852 VARCHAR(255);
  p_DisplayName_4e31f852 VARCHAR(255);
  p_Description_4e31f852 TEXT;
  p_Category_4e31f852 VARCHAR(100);
  p_Type_4e31f852 VARCHAR(100);
  p_Length_4e31f852 INTEGER;
  p_Precision_4e31f852 INTEGER;
  p_Scale_4e31f852 INTEGER;
  p_AllowsNull_4e31f852 BOOLEAN;
  p_DefaultValue_4e31f852 VARCHAR(255);
  p_IsPrimaryKey_4e31f852 BOOLEAN;
  p_IsUniqueKey_4e31f852 BOOLEAN;
  p_IsReadOnly_4e31f852 BOOLEAN;
  p_IsRequired_4e31f852 BOOLEAN;
  p_RelatedIntegrationObjectID_4e31f852 UUID;
  p_RelatedIntegrationObjectFieldName_4e31f852 VARCHAR(255);
  p_Sequence_4e31f852 INTEGER;
  p_Configuration_4e31f852 TEXT;
  p_Status_4e31f852 VARCHAR(25);
  p_IsCustom_4e31f852 BOOLEAN;
  p_MetadataSource_4e31f852 VARCHAR(20);
BEGIN
  p_ID_4e31f852 := 'DEC2BB95-DEFB-578F-820B-E55D7EF8FD2C';
  p_IntegrationObjectID_4e31f852 := '5DD9CF05-1571-454E-BA40-D65E6B9C2131';
  p_Name_4e31f852 := 'source-orcid';
  p_DisplayName_4e31f852 := 'Source Orcid';
  p_Description_4e31f852 := 'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.';
  p_Type_4e31f852 := 'String';
  p_Length_4e31f852 := 19;
  p_AllowsNull_4e31f852 := TRUE;
  p_IsPrimaryKey_4e31f852 := FALSE;
  p_IsUniqueKey_4e31f852 := FALSE;
  p_IsReadOnly_4e31f852 := TRUE;
  p_IsRequired_4e31f852 := FALSE;
  p_Sequence_4e31f852 := 28;
  p_Status_4e31f852 := 'Active';
  p_IsCustom_4e31f852 := FALSE;
  p_MetadataSource_4e31f852 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_4e31f852, p_IntegrationObjectID := p_IntegrationObjectID_4e31f852, p_Name := p_Name_4e31f852, p_DisplayName := p_DisplayName_4e31f852, p_Description := p_Description_4e31f852, p_Category := p_Category_4e31f852, p_Category_Clear := TRUE, p_Type := p_Type_4e31f852, p_Length := p_Length_4e31f852, p_Precision := p_Precision_4e31f852, p_Precision_Clear := TRUE, p_Scale := p_Scale_4e31f852, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_4e31f852, p_DefaultValue := p_DefaultValue_4e31f852, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_4e31f852, p_IsUniqueKey := p_IsUniqueKey_4e31f852, p_IsReadOnly := p_IsReadOnly_4e31f852, p_IsRequired := p_IsRequired_4e31f852, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_4e31f852, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_4e31f852, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_4e31f852, p_Configuration := p_Configuration_4e31f852, p_Configuration_Clear := TRUE, p_Status := p_Status_4e31f852, p_IsCustom := p_IsCustom_4e31f852, p_MetadataSource := p_MetadataSource_4e31f852);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_39bca174 UUID;
  p_IntegrationObjectID_39bca174 UUID;
  p_Name_39bca174 VARCHAR(255);
  p_DisplayName_39bca174 VARCHAR(255);
  p_Description_39bca174 TEXT;
  p_Category_39bca174 VARCHAR(100);
  p_Type_39bca174 VARCHAR(100);
  p_Length_39bca174 INTEGER;
  p_Precision_39bca174 INTEGER;
  p_Scale_39bca174 INTEGER;
  p_AllowsNull_39bca174 BOOLEAN;
  p_DefaultValue_39bca174 VARCHAR(255);
  p_IsPrimaryKey_39bca174 BOOLEAN;
  p_IsUniqueKey_39bca174 BOOLEAN;
  p_IsReadOnly_39bca174 BOOLEAN;
  p_IsRequired_39bca174 BOOLEAN;
  p_RelatedIntegrationObjectID_39bca174 UUID;
  p_RelatedIntegrationObjectFieldName_39bca174 VARCHAR(255);
  p_Sequence_39bca174 INTEGER;
  p_Configuration_39bca174 TEXT;
  p_Status_39bca174 VARCHAR(25);
  p_IsCustom_39bca174 BOOLEAN;
  p_MetadataSource_39bca174 VARCHAR(20);
BEGIN
  p_ID_39bca174 := '7180D16D-66F8-510B-8807-AE5F55E553A9';
  p_IntegrationObjectID_39bca174 := 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05';
  p_Name_39bca174 := 'start-year';
  p_DisplayName_39bca174 := 'Start Year';
  p_Description_39bca174 := 'Year of the affiliation start date; ORCID dates are partial, so month/day may be absent.';
  p_Type_39bca174 := 'Integer';
  p_AllowsNull_39bca174 := TRUE;
  p_IsPrimaryKey_39bca174 := FALSE;
  p_IsUniqueKey_39bca174 := FALSE;
  p_IsReadOnly_39bca174 := TRUE;
  p_IsRequired_39bca174 := FALSE;
  p_Sequence_39bca174 := 15;
  p_Status_39bca174 := 'Active';
  p_IsCustom_39bca174 := FALSE;
  p_MetadataSource_39bca174 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_39bca174, p_IntegrationObjectID := p_IntegrationObjectID_39bca174, p_Name := p_Name_39bca174, p_DisplayName := p_DisplayName_39bca174, p_Description := p_Description_39bca174, p_Category := p_Category_39bca174, p_Category_Clear := TRUE, p_Type := p_Type_39bca174, p_Length := p_Length_39bca174, p_Length_Clear := TRUE, p_Precision := p_Precision_39bca174, p_Precision_Clear := TRUE, p_Scale := p_Scale_39bca174, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_39bca174, p_DefaultValue := p_DefaultValue_39bca174, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_39bca174, p_IsUniqueKey := p_IsUniqueKey_39bca174, p_IsReadOnly := p_IsReadOnly_39bca174, p_IsRequired := p_IsRequired_39bca174, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_39bca174, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_39bca174, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_39bca174, p_Configuration := p_Configuration_39bca174, p_Configuration_Clear := TRUE, p_Status := p_Status_39bca174, p_IsCustom := p_IsCustom_39bca174, p_MetadataSource := p_MetadataSource_39bca174);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_7dee4a41 UUID;
  p_IntegrationObjectID_7dee4a41 UUID;
  p_Name_7dee4a41 VARCHAR(255);
  p_DisplayName_7dee4a41 VARCHAR(255);
  p_Description_7dee4a41 TEXT;
  p_Category_7dee4a41 VARCHAR(100);
  p_Type_7dee4a41 VARCHAR(100);
  p_Length_7dee4a41 INTEGER;
  p_Precision_7dee4a41 INTEGER;
  p_Scale_7dee4a41 INTEGER;
  p_AllowsNull_7dee4a41 BOOLEAN;
  p_DefaultValue_7dee4a41 VARCHAR(255);
  p_IsPrimaryKey_7dee4a41 BOOLEAN;
  p_IsUniqueKey_7dee4a41 BOOLEAN;
  p_IsReadOnly_7dee4a41 BOOLEAN;
  p_IsRequired_7dee4a41 BOOLEAN;
  p_RelatedIntegrationObjectID_7dee4a41 UUID;
  p_RelatedIntegrationObjectFieldName_7dee4a41 VARCHAR(255);
  p_Sequence_7dee4a41 INTEGER;
  p_Configuration_7dee4a41 TEXT;
  p_Status_7dee4a41 VARCHAR(25);
  p_IsCustom_7dee4a41 BOOLEAN;
  p_MetadataSource_7dee4a41 VARCHAR(20);
BEGIN
  p_ID_7dee4a41 := 'B6F7E123-DFB9-5903-9375-26C5603A9ADB';
  p_IntegrationObjectID_7dee4a41 := 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05';
  p_Name_7dee4a41 := 'start-month';
  p_DisplayName_7dee4a41 := 'Start Month';
  p_Description_7dee4a41 := 'Month (1-12) of the affiliation start date, when given.';
  p_Type_7dee4a41 := 'Integer';
  p_AllowsNull_7dee4a41 := TRUE;
  p_IsPrimaryKey_7dee4a41 := FALSE;
  p_IsUniqueKey_7dee4a41 := FALSE;
  p_IsReadOnly_7dee4a41 := TRUE;
  p_IsRequired_7dee4a41 := FALSE;
  p_Sequence_7dee4a41 := 16;
  p_Status_7dee4a41 := 'Active';
  p_IsCustom_7dee4a41 := FALSE;
  p_MetadataSource_7dee4a41 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_7dee4a41, p_IntegrationObjectID := p_IntegrationObjectID_7dee4a41, p_Name := p_Name_7dee4a41, p_DisplayName := p_DisplayName_7dee4a41, p_Description := p_Description_7dee4a41, p_Category := p_Category_7dee4a41, p_Category_Clear := TRUE, p_Type := p_Type_7dee4a41, p_Length := p_Length_7dee4a41, p_Length_Clear := TRUE, p_Precision := p_Precision_7dee4a41, p_Precision_Clear := TRUE, p_Scale := p_Scale_7dee4a41, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_7dee4a41, p_DefaultValue := p_DefaultValue_7dee4a41, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_7dee4a41, p_IsUniqueKey := p_IsUniqueKey_7dee4a41, p_IsReadOnly := p_IsReadOnly_7dee4a41, p_IsRequired := p_IsRequired_7dee4a41, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_7dee4a41, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_7dee4a41, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_7dee4a41, p_Configuration := p_Configuration_7dee4a41, p_Configuration_Clear := TRUE, p_Status := p_Status_7dee4a41, p_IsCustom := p_IsCustom_7dee4a41, p_MetadataSource := p_MetadataSource_7dee4a41);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_a652f960 UUID;
  p_IntegrationObjectID_a652f960 UUID;
  p_Name_a652f960 VARCHAR(255);
  p_DisplayName_a652f960 VARCHAR(255);
  p_Description_a652f960 TEXT;
  p_Category_a652f960 VARCHAR(100);
  p_Type_a652f960 VARCHAR(100);
  p_Length_a652f960 INTEGER;
  p_Precision_a652f960 INTEGER;
  p_Scale_a652f960 INTEGER;
  p_AllowsNull_a652f960 BOOLEAN;
  p_DefaultValue_a652f960 VARCHAR(255);
  p_IsPrimaryKey_a652f960 BOOLEAN;
  p_IsUniqueKey_a652f960 BOOLEAN;
  p_IsReadOnly_a652f960 BOOLEAN;
  p_IsRequired_a652f960 BOOLEAN;
  p_RelatedIntegrationObjectID_a652f960 UUID;
  p_RelatedIntegrationObjectFieldName_a652f960 VARCHAR(255);
  p_Sequence_a652f960 INTEGER;
  p_Configuration_a652f960 TEXT;
  p_Status_a652f960 VARCHAR(25);
  p_IsCustom_a652f960 BOOLEAN;
  p_MetadataSource_a652f960 VARCHAR(20);
BEGIN
  p_ID_a652f960 := '393CDB89-18CB-593E-BC9F-9F493F2A35F5';
  p_IntegrationObjectID_a652f960 := 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05';
  p_Name_a652f960 := 'start-day';
  p_DisplayName_a652f960 := 'Start Day';
  p_Description_a652f960 := 'Day of month of the affiliation start date, when given.';
  p_Type_a652f960 := 'Integer';
  p_AllowsNull_a652f960 := TRUE;
  p_IsPrimaryKey_a652f960 := FALSE;
  p_IsUniqueKey_a652f960 := FALSE;
  p_IsReadOnly_a652f960 := TRUE;
  p_IsRequired_a652f960 := FALSE;
  p_Sequence_a652f960 := 17;
  p_Status_a652f960 := 'Active';
  p_IsCustom_a652f960 := FALSE;
  p_MetadataSource_a652f960 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_a652f960, p_IntegrationObjectID := p_IntegrationObjectID_a652f960, p_Name := p_Name_a652f960, p_DisplayName := p_DisplayName_a652f960, p_Description := p_Description_a652f960, p_Category := p_Category_a652f960, p_Category_Clear := TRUE, p_Type := p_Type_a652f960, p_Length := p_Length_a652f960, p_Length_Clear := TRUE, p_Precision := p_Precision_a652f960, p_Precision_Clear := TRUE, p_Scale := p_Scale_a652f960, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_a652f960, p_DefaultValue := p_DefaultValue_a652f960, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_a652f960, p_IsUniqueKey := p_IsUniqueKey_a652f960, p_IsReadOnly := p_IsReadOnly_a652f960, p_IsRequired := p_IsRequired_a652f960, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_a652f960, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_a652f960, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_a652f960, p_Configuration := p_Configuration_a652f960, p_Configuration_Clear := TRUE, p_Status := p_Status_a652f960, p_IsCustom := p_IsCustom_a652f960, p_MetadataSource := p_MetadataSource_a652f960);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_39dec340 UUID;
  p_IntegrationObjectID_39dec340 UUID;
  p_Name_39dec340 VARCHAR(255);
  p_DisplayName_39dec340 VARCHAR(255);
  p_Description_39dec340 TEXT;
  p_Category_39dec340 VARCHAR(100);
  p_Type_39dec340 VARCHAR(100);
  p_Length_39dec340 INTEGER;
  p_Precision_39dec340 INTEGER;
  p_Scale_39dec340 INTEGER;
  p_AllowsNull_39dec340 BOOLEAN;
  p_DefaultValue_39dec340 VARCHAR(255);
  p_IsPrimaryKey_39dec340 BOOLEAN;
  p_IsUniqueKey_39dec340 BOOLEAN;
  p_IsReadOnly_39dec340 BOOLEAN;
  p_IsRequired_39dec340 BOOLEAN;
  p_RelatedIntegrationObjectID_39dec340 UUID;
  p_RelatedIntegrationObjectFieldName_39dec340 VARCHAR(255);
  p_Sequence_39dec340 INTEGER;
  p_Configuration_39dec340 TEXT;
  p_Status_39dec340 VARCHAR(25);
  p_IsCustom_39dec340 BOOLEAN;
  p_MetadataSource_39dec340 VARCHAR(20);
BEGIN
  p_ID_39dec340 := 'AC91F183-E78B-5733-8FF8-C3AA039FE01C';
  p_IntegrationObjectID_39dec340 := 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05';
  p_Name_39dec340 := 'end-year';
  p_DisplayName_39dec340 := 'End Year';
  p_Description_39dec340 := 'Year of the affiliation end date; empty for a current/ongoing role; ORCID dates are partial, so month/day may be absent.';
  p_Type_39dec340 := 'Integer';
  p_AllowsNull_39dec340 := TRUE;
  p_IsPrimaryKey_39dec340 := FALSE;
  p_IsUniqueKey_39dec340 := FALSE;
  p_IsReadOnly_39dec340 := TRUE;
  p_IsRequired_39dec340 := FALSE;
  p_Sequence_39dec340 := 18;
  p_Status_39dec340 := 'Active';
  p_IsCustom_39dec340 := FALSE;
  p_MetadataSource_39dec340 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_39dec340, p_IntegrationObjectID := p_IntegrationObjectID_39dec340, p_Name := p_Name_39dec340, p_DisplayName := p_DisplayName_39dec340, p_Description := p_Description_39dec340, p_Category := p_Category_39dec340, p_Category_Clear := TRUE, p_Type := p_Type_39dec340, p_Length := p_Length_39dec340, p_Length_Clear := TRUE, p_Precision := p_Precision_39dec340, p_Precision_Clear := TRUE, p_Scale := p_Scale_39dec340, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_39dec340, p_DefaultValue := p_DefaultValue_39dec340, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_39dec340, p_IsUniqueKey := p_IsUniqueKey_39dec340, p_IsReadOnly := p_IsReadOnly_39dec340, p_IsRequired := p_IsRequired_39dec340, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_39dec340, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_39dec340, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_39dec340, p_Configuration := p_Configuration_39dec340, p_Configuration_Clear := TRUE, p_Status := p_Status_39dec340, p_IsCustom := p_IsCustom_39dec340, p_MetadataSource := p_MetadataSource_39dec340);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_821b0509 UUID;
  p_IntegrationObjectID_821b0509 UUID;
  p_Name_821b0509 VARCHAR(255);
  p_DisplayName_821b0509 VARCHAR(255);
  p_Description_821b0509 TEXT;
  p_Category_821b0509 VARCHAR(100);
  p_Type_821b0509 VARCHAR(100);
  p_Length_821b0509 INTEGER;
  p_Precision_821b0509 INTEGER;
  p_Scale_821b0509 INTEGER;
  p_AllowsNull_821b0509 BOOLEAN;
  p_DefaultValue_821b0509 VARCHAR(255);
  p_IsPrimaryKey_821b0509 BOOLEAN;
  p_IsUniqueKey_821b0509 BOOLEAN;
  p_IsReadOnly_821b0509 BOOLEAN;
  p_IsRequired_821b0509 BOOLEAN;
  p_RelatedIntegrationObjectID_821b0509 UUID;
  p_RelatedIntegrationObjectFieldName_821b0509 VARCHAR(255);
  p_Sequence_821b0509 INTEGER;
  p_Configuration_821b0509 TEXT;
  p_Status_821b0509 VARCHAR(25);
  p_IsCustom_821b0509 BOOLEAN;
  p_MetadataSource_821b0509 VARCHAR(20);
BEGIN
  p_ID_821b0509 := '1C624B62-5275-516D-A89D-CF11D5C7630D';
  p_IntegrationObjectID_821b0509 := 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05';
  p_Name_821b0509 := 'end-month';
  p_DisplayName_821b0509 := 'End Month';
  p_Description_821b0509 := 'Month (1-12) of the affiliation end date; empty for a current/ongoing role, when given.';
  p_Type_821b0509 := 'Integer';
  p_AllowsNull_821b0509 := TRUE;
  p_IsPrimaryKey_821b0509 := FALSE;
  p_IsUniqueKey_821b0509 := FALSE;
  p_IsReadOnly_821b0509 := TRUE;
  p_IsRequired_821b0509 := FALSE;
  p_Sequence_821b0509 := 19;
  p_Status_821b0509 := 'Active';
  p_IsCustom_821b0509 := FALSE;
  p_MetadataSource_821b0509 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_821b0509, p_IntegrationObjectID := p_IntegrationObjectID_821b0509, p_Name := p_Name_821b0509, p_DisplayName := p_DisplayName_821b0509, p_Description := p_Description_821b0509, p_Category := p_Category_821b0509, p_Category_Clear := TRUE, p_Type := p_Type_821b0509, p_Length := p_Length_821b0509, p_Length_Clear := TRUE, p_Precision := p_Precision_821b0509, p_Precision_Clear := TRUE, p_Scale := p_Scale_821b0509, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_821b0509, p_DefaultValue := p_DefaultValue_821b0509, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_821b0509, p_IsUniqueKey := p_IsUniqueKey_821b0509, p_IsReadOnly := p_IsReadOnly_821b0509, p_IsRequired := p_IsRequired_821b0509, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_821b0509, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_821b0509, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_821b0509, p_Configuration := p_Configuration_821b0509, p_Configuration_Clear := TRUE, p_Status := p_Status_821b0509, p_IsCustom := p_IsCustom_821b0509, p_MetadataSource := p_MetadataSource_821b0509);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_55c03965 UUID;
  p_IntegrationObjectID_55c03965 UUID;
  p_Name_55c03965 VARCHAR(255);
  p_DisplayName_55c03965 VARCHAR(255);
  p_Description_55c03965 TEXT;
  p_Category_55c03965 VARCHAR(100);
  p_Type_55c03965 VARCHAR(100);
  p_Length_55c03965 INTEGER;
  p_Precision_55c03965 INTEGER;
  p_Scale_55c03965 INTEGER;
  p_AllowsNull_55c03965 BOOLEAN;
  p_DefaultValue_55c03965 VARCHAR(255);
  p_IsPrimaryKey_55c03965 BOOLEAN;
  p_IsUniqueKey_55c03965 BOOLEAN;
  p_IsReadOnly_55c03965 BOOLEAN;
  p_IsRequired_55c03965 BOOLEAN;
  p_RelatedIntegrationObjectID_55c03965 UUID;
  p_RelatedIntegrationObjectFieldName_55c03965 VARCHAR(255);
  p_Sequence_55c03965 INTEGER;
  p_Configuration_55c03965 TEXT;
  p_Status_55c03965 VARCHAR(25);
  p_IsCustom_55c03965 BOOLEAN;
  p_MetadataSource_55c03965 VARCHAR(20);
BEGIN
  p_ID_55c03965 := '6E02E532-688C-5A06-A7E3-A1C563F324FE';
  p_IntegrationObjectID_55c03965 := 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05';
  p_Name_55c03965 := 'end-day';
  p_DisplayName_55c03965 := 'End Day';
  p_Description_55c03965 := 'Day of month of the affiliation end date; empty for a current/ongoing role, when given.';
  p_Type_55c03965 := 'Integer';
  p_AllowsNull_55c03965 := TRUE;
  p_IsPrimaryKey_55c03965 := FALSE;
  p_IsUniqueKey_55c03965 := FALSE;
  p_IsReadOnly_55c03965 := TRUE;
  p_IsRequired_55c03965 := FALSE;
  p_Sequence_55c03965 := 20;
  p_Status_55c03965 := 'Active';
  p_IsCustom_55c03965 := FALSE;
  p_MetadataSource_55c03965 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_55c03965, p_IntegrationObjectID := p_IntegrationObjectID_55c03965, p_Name := p_Name_55c03965, p_DisplayName := p_DisplayName_55c03965, p_Description := p_Description_55c03965, p_Category := p_Category_55c03965, p_Category_Clear := TRUE, p_Type := p_Type_55c03965, p_Length := p_Length_55c03965, p_Length_Clear := TRUE, p_Precision := p_Precision_55c03965, p_Precision_Clear := TRUE, p_Scale := p_Scale_55c03965, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_55c03965, p_DefaultValue := p_DefaultValue_55c03965, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_55c03965, p_IsUniqueKey := p_IsUniqueKey_55c03965, p_IsReadOnly := p_IsReadOnly_55c03965, p_IsRequired := p_IsRequired_55c03965, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_55c03965, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_55c03965, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_55c03965, p_Configuration := p_Configuration_55c03965, p_Configuration_Clear := TRUE, p_Status := p_Status_55c03965, p_IsCustom := p_IsCustom_55c03965, p_MetadataSource := p_MetadataSource_55c03965);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_d106c948 UUID;
  p_IntegrationObjectID_d106c948 UUID;
  p_Name_d106c948 VARCHAR(255);
  p_DisplayName_d106c948 VARCHAR(255);
  p_Description_d106c948 TEXT;
  p_Category_d106c948 VARCHAR(100);
  p_Type_d106c948 VARCHAR(100);
  p_Length_d106c948 INTEGER;
  p_Precision_d106c948 INTEGER;
  p_Scale_d106c948 INTEGER;
  p_AllowsNull_d106c948 BOOLEAN;
  p_DefaultValue_d106c948 VARCHAR(255);
  p_IsPrimaryKey_d106c948 BOOLEAN;
  p_IsUniqueKey_d106c948 BOOLEAN;
  p_IsReadOnly_d106c948 BOOLEAN;
  p_IsRequired_d106c948 BOOLEAN;
  p_RelatedIntegrationObjectID_d106c948 UUID;
  p_RelatedIntegrationObjectFieldName_d106c948 VARCHAR(255);
  p_Sequence_d106c948 INTEGER;
  p_Configuration_d106c948 TEXT;
  p_Status_d106c948 VARCHAR(25);
  p_IsCustom_d106c948 BOOLEAN;
  p_MetadataSource_d106c948 VARCHAR(20);
BEGIN
  p_ID_d106c948 := '4BEE4CD2-5BA2-5642-BB38-FBB111001EA8';
  p_IntegrationObjectID_d106c948 := 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05';
  p_Name_d106c948 := 'organization-name';
  p_DisplayName_d106c948 := 'Organization Name';
  p_Description_d106c948 := 'Name of the organization. Lifted from organization.name.';
  p_Type_d106c948 := 'String';
  p_Length_d106c948 := 1000;
  p_AllowsNull_d106c948 := TRUE;
  p_IsPrimaryKey_d106c948 := FALSE;
  p_IsUniqueKey_d106c948 := FALSE;
  p_IsReadOnly_d106c948 := TRUE;
  p_IsRequired_d106c948 := FALSE;
  p_Sequence_d106c948 := 21;
  p_Status_d106c948 := 'Active';
  p_IsCustom_d106c948 := FALSE;
  p_MetadataSource_d106c948 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_d106c948, p_IntegrationObjectID := p_IntegrationObjectID_d106c948, p_Name := p_Name_d106c948, p_DisplayName := p_DisplayName_d106c948, p_Description := p_Description_d106c948, p_Category := p_Category_d106c948, p_Category_Clear := TRUE, p_Type := p_Type_d106c948, p_Length := p_Length_d106c948, p_Precision := p_Precision_d106c948, p_Precision_Clear := TRUE, p_Scale := p_Scale_d106c948, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_d106c948, p_DefaultValue := p_DefaultValue_d106c948, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_d106c948, p_IsUniqueKey := p_IsUniqueKey_d106c948, p_IsReadOnly := p_IsReadOnly_d106c948, p_IsRequired := p_IsRequired_d106c948, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_d106c948, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_d106c948, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_d106c948, p_Configuration := p_Configuration_d106c948, p_Configuration_Clear := TRUE, p_Status := p_Status_d106c948, p_IsCustom := p_IsCustom_d106c948, p_MetadataSource := p_MetadataSource_d106c948);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_97c55941 UUID;
  p_IntegrationObjectID_97c55941 UUID;
  p_Name_97c55941 VARCHAR(255);
  p_DisplayName_97c55941 VARCHAR(255);
  p_Description_97c55941 TEXT;
  p_Category_97c55941 VARCHAR(100);
  p_Type_97c55941 VARCHAR(100);
  p_Length_97c55941 INTEGER;
  p_Precision_97c55941 INTEGER;
  p_Scale_97c55941 INTEGER;
  p_AllowsNull_97c55941 BOOLEAN;
  p_DefaultValue_97c55941 VARCHAR(255);
  p_IsPrimaryKey_97c55941 BOOLEAN;
  p_IsUniqueKey_97c55941 BOOLEAN;
  p_IsReadOnly_97c55941 BOOLEAN;
  p_IsRequired_97c55941 BOOLEAN;
  p_RelatedIntegrationObjectID_97c55941 UUID;
  p_RelatedIntegrationObjectFieldName_97c55941 VARCHAR(255);
  p_Sequence_97c55941 INTEGER;
  p_Configuration_97c55941 TEXT;
  p_Status_97c55941 VARCHAR(25);
  p_IsCustom_97c55941 BOOLEAN;
  p_MetadataSource_97c55941 VARCHAR(20);
BEGIN
  p_ID_97c55941 := '33FCD70A-FB16-5B95-B166-82717FBF15AA';
  p_IntegrationObjectID_97c55941 := 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05';
  p_Name_97c55941 := 'organization-city';
  p_DisplayName_97c55941 := 'Organization City';
  p_Description_97c55941 := 'City of the organization. Lifted from organization.address.city.';
  p_Type_97c55941 := 'String';
  p_Length_97c55941 := 255;
  p_AllowsNull_97c55941 := TRUE;
  p_IsPrimaryKey_97c55941 := FALSE;
  p_IsUniqueKey_97c55941 := FALSE;
  p_IsReadOnly_97c55941 := TRUE;
  p_IsRequired_97c55941 := FALSE;
  p_Sequence_97c55941 := 22;
  p_Status_97c55941 := 'Active';
  p_IsCustom_97c55941 := FALSE;
  p_MetadataSource_97c55941 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_97c55941, p_IntegrationObjectID := p_IntegrationObjectID_97c55941, p_Name := p_Name_97c55941, p_DisplayName := p_DisplayName_97c55941, p_Description := p_Description_97c55941, p_Category := p_Category_97c55941, p_Category_Clear := TRUE, p_Type := p_Type_97c55941, p_Length := p_Length_97c55941, p_Precision := p_Precision_97c55941, p_Precision_Clear := TRUE, p_Scale := p_Scale_97c55941, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_97c55941, p_DefaultValue := p_DefaultValue_97c55941, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_97c55941, p_IsUniqueKey := p_IsUniqueKey_97c55941, p_IsReadOnly := p_IsReadOnly_97c55941, p_IsRequired := p_IsRequired_97c55941, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_97c55941, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_97c55941, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_97c55941, p_Configuration := p_Configuration_97c55941, p_Configuration_Clear := TRUE, p_Status := p_Status_97c55941, p_IsCustom := p_IsCustom_97c55941, p_MetadataSource := p_MetadataSource_97c55941);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_30429f37 UUID;
  p_IntegrationObjectID_30429f37 UUID;
  p_Name_30429f37 VARCHAR(255);
  p_DisplayName_30429f37 VARCHAR(255);
  p_Description_30429f37 TEXT;
  p_Category_30429f37 VARCHAR(100);
  p_Type_30429f37 VARCHAR(100);
  p_Length_30429f37 INTEGER;
  p_Precision_30429f37 INTEGER;
  p_Scale_30429f37 INTEGER;
  p_AllowsNull_30429f37 BOOLEAN;
  p_DefaultValue_30429f37 VARCHAR(255);
  p_IsPrimaryKey_30429f37 BOOLEAN;
  p_IsUniqueKey_30429f37 BOOLEAN;
  p_IsReadOnly_30429f37 BOOLEAN;
  p_IsRequired_30429f37 BOOLEAN;
  p_RelatedIntegrationObjectID_30429f37 UUID;
  p_RelatedIntegrationObjectFieldName_30429f37 VARCHAR(255);
  p_Sequence_30429f37 INTEGER;
  p_Configuration_30429f37 TEXT;
  p_Status_30429f37 VARCHAR(25);
  p_IsCustom_30429f37 BOOLEAN;
  p_MetadataSource_30429f37 VARCHAR(20);
BEGIN
  p_ID_30429f37 := 'E6DFA9E7-3283-5468-AB81-39EB0467B7AE';
  p_IntegrationObjectID_30429f37 := 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05';
  p_Name_30429f37 := 'organization-region';
  p_DisplayName_30429f37 := 'Organization Region';
  p_Description_30429f37 := 'Region/state of the organization. Lifted from organization.address.region.';
  p_Type_30429f37 := 'String';
  p_Length_30429f37 := 255;
  p_AllowsNull_30429f37 := TRUE;
  p_IsPrimaryKey_30429f37 := FALSE;
  p_IsUniqueKey_30429f37 := FALSE;
  p_IsReadOnly_30429f37 := TRUE;
  p_IsRequired_30429f37 := FALSE;
  p_Sequence_30429f37 := 23;
  p_Status_30429f37 := 'Active';
  p_IsCustom_30429f37 := FALSE;
  p_MetadataSource_30429f37 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_30429f37, p_IntegrationObjectID := p_IntegrationObjectID_30429f37, p_Name := p_Name_30429f37, p_DisplayName := p_DisplayName_30429f37, p_Description := p_Description_30429f37, p_Category := p_Category_30429f37, p_Category_Clear := TRUE, p_Type := p_Type_30429f37, p_Length := p_Length_30429f37, p_Precision := p_Precision_30429f37, p_Precision_Clear := TRUE, p_Scale := p_Scale_30429f37, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_30429f37, p_DefaultValue := p_DefaultValue_30429f37, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_30429f37, p_IsUniqueKey := p_IsUniqueKey_30429f37, p_IsReadOnly := p_IsReadOnly_30429f37, p_IsRequired := p_IsRequired_30429f37, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_30429f37, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_30429f37, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_30429f37, p_Configuration := p_Configuration_30429f37, p_Configuration_Clear := TRUE, p_Status := p_Status_30429f37, p_IsCustom := p_IsCustom_30429f37, p_MetadataSource := p_MetadataSource_30429f37);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_370f9eb0 UUID;
  p_IntegrationObjectID_370f9eb0 UUID;
  p_Name_370f9eb0 VARCHAR(255);
  p_DisplayName_370f9eb0 VARCHAR(255);
  p_Description_370f9eb0 TEXT;
  p_Category_370f9eb0 VARCHAR(100);
  p_Type_370f9eb0 VARCHAR(100);
  p_Length_370f9eb0 INTEGER;
  p_Precision_370f9eb0 INTEGER;
  p_Scale_370f9eb0 INTEGER;
  p_AllowsNull_370f9eb0 BOOLEAN;
  p_DefaultValue_370f9eb0 VARCHAR(255);
  p_IsPrimaryKey_370f9eb0 BOOLEAN;
  p_IsUniqueKey_370f9eb0 BOOLEAN;
  p_IsReadOnly_370f9eb0 BOOLEAN;
  p_IsRequired_370f9eb0 BOOLEAN;
  p_RelatedIntegrationObjectID_370f9eb0 UUID;
  p_RelatedIntegrationObjectFieldName_370f9eb0 VARCHAR(255);
  p_Sequence_370f9eb0 INTEGER;
  p_Configuration_370f9eb0 TEXT;
  p_Status_370f9eb0 VARCHAR(25);
  p_IsCustom_370f9eb0 BOOLEAN;
  p_MetadataSource_370f9eb0 VARCHAR(20);
BEGIN
  p_ID_370f9eb0 := 'F29B8F09-6C37-5791-96FE-27E4BDA5F8A6';
  p_IntegrationObjectID_370f9eb0 := 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05';
  p_Name_370f9eb0 := 'organization-country';
  p_DisplayName_370f9eb0 := 'Organization Country';
  p_Description_370f9eb0 := 'ISO country code of the organization. Lifted from organization.address.country.';
  p_Type_370f9eb0 := 'String';
  p_Length_370f9eb0 := 50;
  p_AllowsNull_370f9eb0 := TRUE;
  p_IsPrimaryKey_370f9eb0 := FALSE;
  p_IsUniqueKey_370f9eb0 := FALSE;
  p_IsReadOnly_370f9eb0 := TRUE;
  p_IsRequired_370f9eb0 := FALSE;
  p_Sequence_370f9eb0 := 24;
  p_Status_370f9eb0 := 'Active';
  p_IsCustom_370f9eb0 := FALSE;
  p_MetadataSource_370f9eb0 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_370f9eb0, p_IntegrationObjectID := p_IntegrationObjectID_370f9eb0, p_Name := p_Name_370f9eb0, p_DisplayName := p_DisplayName_370f9eb0, p_Description := p_Description_370f9eb0, p_Category := p_Category_370f9eb0, p_Category_Clear := TRUE, p_Type := p_Type_370f9eb0, p_Length := p_Length_370f9eb0, p_Precision := p_Precision_370f9eb0, p_Precision_Clear := TRUE, p_Scale := p_Scale_370f9eb0, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_370f9eb0, p_DefaultValue := p_DefaultValue_370f9eb0, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_370f9eb0, p_IsUniqueKey := p_IsUniqueKey_370f9eb0, p_IsReadOnly := p_IsReadOnly_370f9eb0, p_IsRequired := p_IsRequired_370f9eb0, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_370f9eb0, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_370f9eb0, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_370f9eb0, p_Configuration := p_Configuration_370f9eb0, p_Configuration_Clear := TRUE, p_Status := p_Status_370f9eb0, p_IsCustom := p_IsCustom_370f9eb0, p_MetadataSource := p_MetadataSource_370f9eb0);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_cd2c3757 UUID;
  p_IntegrationObjectID_cd2c3757 UUID;
  p_Name_cd2c3757 VARCHAR(255);
  p_DisplayName_cd2c3757 VARCHAR(255);
  p_Description_cd2c3757 TEXT;
  p_Category_cd2c3757 VARCHAR(100);
  p_Type_cd2c3757 VARCHAR(100);
  p_Length_cd2c3757 INTEGER;
  p_Precision_cd2c3757 INTEGER;
  p_Scale_cd2c3757 INTEGER;
  p_AllowsNull_cd2c3757 BOOLEAN;
  p_DefaultValue_cd2c3757 VARCHAR(255);
  p_IsPrimaryKey_cd2c3757 BOOLEAN;
  p_IsUniqueKey_cd2c3757 BOOLEAN;
  p_IsReadOnly_cd2c3757 BOOLEAN;
  p_IsRequired_cd2c3757 BOOLEAN;
  p_RelatedIntegrationObjectID_cd2c3757 UUID;
  p_RelatedIntegrationObjectFieldName_cd2c3757 VARCHAR(255);
  p_Sequence_cd2c3757 INTEGER;
  p_Configuration_cd2c3757 TEXT;
  p_Status_cd2c3757 VARCHAR(25);
  p_IsCustom_cd2c3757 BOOLEAN;
  p_MetadataSource_cd2c3757 VARCHAR(20);
BEGIN
  p_ID_cd2c3757 := '5281D835-9B52-58A6-8B67-4B44564F8CD8';
  p_IntegrationObjectID_cd2c3757 := 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05';
  p_Name_cd2c3757 := 'organization-disambiguated-id';
  p_DisplayName_cd2c3757 := 'Organization Disambiguated Id';
  p_Description_cd2c3757 := 'Canonical identifier of the organization in the disambiguation source (e.g. a RINGGOLD or ROR id), so the same institution matches across records.';
  p_Type_cd2c3757 := 'String';
  p_Length_cd2c3757 := 255;
  p_AllowsNull_cd2c3757 := TRUE;
  p_IsPrimaryKey_cd2c3757 := FALSE;
  p_IsUniqueKey_cd2c3757 := FALSE;
  p_IsReadOnly_cd2c3757 := TRUE;
  p_IsRequired_cd2c3757 := FALSE;
  p_Sequence_cd2c3757 := 25;
  p_Status_cd2c3757 := 'Active';
  p_IsCustom_cd2c3757 := FALSE;
  p_MetadataSource_cd2c3757 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_cd2c3757, p_IntegrationObjectID := p_IntegrationObjectID_cd2c3757, p_Name := p_Name_cd2c3757, p_DisplayName := p_DisplayName_cd2c3757, p_Description := p_Description_cd2c3757, p_Category := p_Category_cd2c3757, p_Category_Clear := TRUE, p_Type := p_Type_cd2c3757, p_Length := p_Length_cd2c3757, p_Precision := p_Precision_cd2c3757, p_Precision_Clear := TRUE, p_Scale := p_Scale_cd2c3757, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_cd2c3757, p_DefaultValue := p_DefaultValue_cd2c3757, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_cd2c3757, p_IsUniqueKey := p_IsUniqueKey_cd2c3757, p_IsReadOnly := p_IsReadOnly_cd2c3757, p_IsRequired := p_IsRequired_cd2c3757, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_cd2c3757, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_cd2c3757, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_cd2c3757, p_Configuration := p_Configuration_cd2c3757, p_Configuration_Clear := TRUE, p_Status := p_Status_cd2c3757, p_IsCustom := p_IsCustom_cd2c3757, p_MetadataSource := p_MetadataSource_cd2c3757);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_5783a021 UUID;
  p_IntegrationObjectID_5783a021 UUID;
  p_Name_5783a021 VARCHAR(255);
  p_DisplayName_5783a021 VARCHAR(255);
  p_Description_5783a021 TEXT;
  p_Category_5783a021 VARCHAR(100);
  p_Type_5783a021 VARCHAR(100);
  p_Length_5783a021 INTEGER;
  p_Precision_5783a021 INTEGER;
  p_Scale_5783a021 INTEGER;
  p_AllowsNull_5783a021 BOOLEAN;
  p_DefaultValue_5783a021 VARCHAR(255);
  p_IsPrimaryKey_5783a021 BOOLEAN;
  p_IsUniqueKey_5783a021 BOOLEAN;
  p_IsReadOnly_5783a021 BOOLEAN;
  p_IsRequired_5783a021 BOOLEAN;
  p_RelatedIntegrationObjectID_5783a021 UUID;
  p_RelatedIntegrationObjectFieldName_5783a021 VARCHAR(255);
  p_Sequence_5783a021 INTEGER;
  p_Configuration_5783a021 TEXT;
  p_Status_5783a021 VARCHAR(25);
  p_IsCustom_5783a021 BOOLEAN;
  p_MetadataSource_5783a021 VARCHAR(20);
BEGIN
  p_ID_5783a021 := '6D655C2C-830B-5857-A312-8369693B7094';
  p_IntegrationObjectID_5783a021 := 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05';
  p_Name_5783a021 := 'organization-disambiguation-source';
  p_DisplayName_5783a021 := 'Organization Disambiguation Source';
  p_Description_5783a021 := 'Registry the disambiguated id comes from (RINGGOLD, ROR, FUNDREF, GRID, LEI).';
  p_Type_5783a021 := 'String';
  p_Length_5783a021 := 100;
  p_AllowsNull_5783a021 := TRUE;
  p_IsPrimaryKey_5783a021 := FALSE;
  p_IsUniqueKey_5783a021 := FALSE;
  p_IsReadOnly_5783a021 := TRUE;
  p_IsRequired_5783a021 := FALSE;
  p_Sequence_5783a021 := 26;
  p_Status_5783a021 := 'Active';
  p_IsCustom_5783a021 := FALSE;
  p_MetadataSource_5783a021 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_5783a021, p_IntegrationObjectID := p_IntegrationObjectID_5783a021, p_Name := p_Name_5783a021, p_DisplayName := p_DisplayName_5783a021, p_Description := p_Description_5783a021, p_Category := p_Category_5783a021, p_Category_Clear := TRUE, p_Type := p_Type_5783a021, p_Length := p_Length_5783a021, p_Precision := p_Precision_5783a021, p_Precision_Clear := TRUE, p_Scale := p_Scale_5783a021, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_5783a021, p_DefaultValue := p_DefaultValue_5783a021, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_5783a021, p_IsUniqueKey := p_IsUniqueKey_5783a021, p_IsReadOnly := p_IsReadOnly_5783a021, p_IsRequired := p_IsRequired_5783a021, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_5783a021, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_5783a021, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_5783a021, p_Configuration := p_Configuration_5783a021, p_Configuration_Clear := TRUE, p_Status := p_Status_5783a021, p_IsCustom := p_IsCustom_5783a021, p_MetadataSource := p_MetadataSource_5783a021);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_0d331a3c UUID;
  p_IntegrationObjectID_0d331a3c UUID;
  p_Name_0d331a3c VARCHAR(255);
  p_DisplayName_0d331a3c VARCHAR(255);
  p_Description_0d331a3c TEXT;
  p_Category_0d331a3c VARCHAR(100);
  p_Type_0d331a3c VARCHAR(100);
  p_Length_0d331a3c INTEGER;
  p_Precision_0d331a3c INTEGER;
  p_Scale_0d331a3c INTEGER;
  p_AllowsNull_0d331a3c BOOLEAN;
  p_DefaultValue_0d331a3c VARCHAR(255);
  p_IsPrimaryKey_0d331a3c BOOLEAN;
  p_IsUniqueKey_0d331a3c BOOLEAN;
  p_IsReadOnly_0d331a3c BOOLEAN;
  p_IsRequired_0d331a3c BOOLEAN;
  p_RelatedIntegrationObjectID_0d331a3c UUID;
  p_RelatedIntegrationObjectFieldName_0d331a3c VARCHAR(255);
  p_Sequence_0d331a3c INTEGER;
  p_Configuration_0d331a3c TEXT;
  p_Status_0d331a3c VARCHAR(25);
  p_IsCustom_0d331a3c BOOLEAN;
  p_MetadataSource_0d331a3c VARCHAR(20);
BEGIN
  p_ID_0d331a3c := '724C306B-01D4-5BA7-9BCB-1BF576FFADDD';
  p_IntegrationObjectID_0d331a3c := 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05';
  p_Name_0d331a3c := 'source-name';
  p_DisplayName_0d331a3c := 'Source Name';
  p_Description_0d331a3c := 'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.';
  p_Type_0d331a3c := 'String';
  p_Length_0d331a3c := 500;
  p_AllowsNull_0d331a3c := TRUE;
  p_IsPrimaryKey_0d331a3c := FALSE;
  p_IsUniqueKey_0d331a3c := FALSE;
  p_IsReadOnly_0d331a3c := TRUE;
  p_IsRequired_0d331a3c := FALSE;
  p_Sequence_0d331a3c := 27;
  p_Status_0d331a3c := 'Active';
  p_IsCustom_0d331a3c := FALSE;
  p_MetadataSource_0d331a3c := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_0d331a3c, p_IntegrationObjectID := p_IntegrationObjectID_0d331a3c, p_Name := p_Name_0d331a3c, p_DisplayName := p_DisplayName_0d331a3c, p_Description := p_Description_0d331a3c, p_Category := p_Category_0d331a3c, p_Category_Clear := TRUE, p_Type := p_Type_0d331a3c, p_Length := p_Length_0d331a3c, p_Precision := p_Precision_0d331a3c, p_Precision_Clear := TRUE, p_Scale := p_Scale_0d331a3c, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_0d331a3c, p_DefaultValue := p_DefaultValue_0d331a3c, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_0d331a3c, p_IsUniqueKey := p_IsUniqueKey_0d331a3c, p_IsReadOnly := p_IsReadOnly_0d331a3c, p_IsRequired := p_IsRequired_0d331a3c, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_0d331a3c, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_0d331a3c, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_0d331a3c, p_Configuration := p_Configuration_0d331a3c, p_Configuration_Clear := TRUE, p_Status := p_Status_0d331a3c, p_IsCustom := p_IsCustom_0d331a3c, p_MetadataSource := p_MetadataSource_0d331a3c);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_fa4a3a48 UUID;
  p_IntegrationObjectID_fa4a3a48 UUID;
  p_Name_fa4a3a48 VARCHAR(255);
  p_DisplayName_fa4a3a48 VARCHAR(255);
  p_Description_fa4a3a48 TEXT;
  p_Category_fa4a3a48 VARCHAR(100);
  p_Type_fa4a3a48 VARCHAR(100);
  p_Length_fa4a3a48 INTEGER;
  p_Precision_fa4a3a48 INTEGER;
  p_Scale_fa4a3a48 INTEGER;
  p_AllowsNull_fa4a3a48 BOOLEAN;
  p_DefaultValue_fa4a3a48 VARCHAR(255);
  p_IsPrimaryKey_fa4a3a48 BOOLEAN;
  p_IsUniqueKey_fa4a3a48 BOOLEAN;
  p_IsReadOnly_fa4a3a48 BOOLEAN;
  p_IsRequired_fa4a3a48 BOOLEAN;
  p_RelatedIntegrationObjectID_fa4a3a48 UUID;
  p_RelatedIntegrationObjectFieldName_fa4a3a48 VARCHAR(255);
  p_Sequence_fa4a3a48 INTEGER;
  p_Configuration_fa4a3a48 TEXT;
  p_Status_fa4a3a48 VARCHAR(25);
  p_IsCustom_fa4a3a48 BOOLEAN;
  p_MetadataSource_fa4a3a48 VARCHAR(20);
BEGIN
  p_ID_fa4a3a48 := 'F9711D4B-FF96-5F2F-ADEA-40777E56FF63';
  p_IntegrationObjectID_fa4a3a48 := 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05';
  p_Name_fa4a3a48 := 'source-orcid';
  p_DisplayName_fa4a3a48 := 'Source Orcid';
  p_Description_fa4a3a48 := 'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.';
  p_Type_fa4a3a48 := 'String';
  p_Length_fa4a3a48 := 19;
  p_AllowsNull_fa4a3a48 := TRUE;
  p_IsPrimaryKey_fa4a3a48 := FALSE;
  p_IsUniqueKey_fa4a3a48 := FALSE;
  p_IsReadOnly_fa4a3a48 := TRUE;
  p_IsRequired_fa4a3a48 := FALSE;
  p_Sequence_fa4a3a48 := 28;
  p_Status_fa4a3a48 := 'Active';
  p_IsCustom_fa4a3a48 := FALSE;
  p_MetadataSource_fa4a3a48 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_fa4a3a48, p_IntegrationObjectID := p_IntegrationObjectID_fa4a3a48, p_Name := p_Name_fa4a3a48, p_DisplayName := p_DisplayName_fa4a3a48, p_Description := p_Description_fa4a3a48, p_Category := p_Category_fa4a3a48, p_Category_Clear := TRUE, p_Type := p_Type_fa4a3a48, p_Length := p_Length_fa4a3a48, p_Precision := p_Precision_fa4a3a48, p_Precision_Clear := TRUE, p_Scale := p_Scale_fa4a3a48, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_fa4a3a48, p_DefaultValue := p_DefaultValue_fa4a3a48, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_fa4a3a48, p_IsUniqueKey := p_IsUniqueKey_fa4a3a48, p_IsReadOnly := p_IsReadOnly_fa4a3a48, p_IsRequired := p_IsRequired_fa4a3a48, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_fa4a3a48, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_fa4a3a48, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_fa4a3a48, p_Configuration := p_Configuration_fa4a3a48, p_Configuration_Clear := TRUE, p_Status := p_Status_fa4a3a48, p_IsCustom := p_IsCustom_fa4a3a48, p_MetadataSource := p_MetadataSource_fa4a3a48);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_6a78e18b UUID;
  p_IntegrationObjectID_6a78e18b UUID;
  p_Name_6a78e18b VARCHAR(255);
  p_DisplayName_6a78e18b VARCHAR(255);
  p_Description_6a78e18b TEXT;
  p_Category_6a78e18b VARCHAR(100);
  p_Type_6a78e18b VARCHAR(100);
  p_Length_6a78e18b INTEGER;
  p_Precision_6a78e18b INTEGER;
  p_Scale_6a78e18b INTEGER;
  p_AllowsNull_6a78e18b BOOLEAN;
  p_DefaultValue_6a78e18b VARCHAR(255);
  p_IsPrimaryKey_6a78e18b BOOLEAN;
  p_IsUniqueKey_6a78e18b BOOLEAN;
  p_IsReadOnly_6a78e18b BOOLEAN;
  p_IsRequired_6a78e18b BOOLEAN;
  p_RelatedIntegrationObjectID_6a78e18b UUID;
  p_RelatedIntegrationObjectFieldName_6a78e18b VARCHAR(255);
  p_Sequence_6a78e18b INTEGER;
  p_Configuration_6a78e18b TEXT;
  p_Status_6a78e18b VARCHAR(25);
  p_IsCustom_6a78e18b BOOLEAN;
  p_MetadataSource_6a78e18b VARCHAR(20);
BEGIN
  p_ID_6a78e18b := '1ED201EF-9831-542B-BB69-988A49F7D516';
  p_IntegrationObjectID_6a78e18b := '35593E67-CBB4-4C88-9438-80C1D7F4B2D0';
  p_Name_6a78e18b := 'start-year';
  p_DisplayName_6a78e18b := 'Start Year';
  p_Description_6a78e18b := 'Year of the affiliation start date; ORCID dates are partial, so month/day may be absent.';
  p_Type_6a78e18b := 'Integer';
  p_AllowsNull_6a78e18b := TRUE;
  p_IsPrimaryKey_6a78e18b := FALSE;
  p_IsUniqueKey_6a78e18b := FALSE;
  p_IsReadOnly_6a78e18b := TRUE;
  p_IsRequired_6a78e18b := FALSE;
  p_Sequence_6a78e18b := 15;
  p_Status_6a78e18b := 'Active';
  p_IsCustom_6a78e18b := FALSE;
  p_MetadataSource_6a78e18b := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_6a78e18b, p_IntegrationObjectID := p_IntegrationObjectID_6a78e18b, p_Name := p_Name_6a78e18b, p_DisplayName := p_DisplayName_6a78e18b, p_Description := p_Description_6a78e18b, p_Category := p_Category_6a78e18b, p_Category_Clear := TRUE, p_Type := p_Type_6a78e18b, p_Length := p_Length_6a78e18b, p_Length_Clear := TRUE, p_Precision := p_Precision_6a78e18b, p_Precision_Clear := TRUE, p_Scale := p_Scale_6a78e18b, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_6a78e18b, p_DefaultValue := p_DefaultValue_6a78e18b, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_6a78e18b, p_IsUniqueKey := p_IsUniqueKey_6a78e18b, p_IsReadOnly := p_IsReadOnly_6a78e18b, p_IsRequired := p_IsRequired_6a78e18b, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_6a78e18b, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_6a78e18b, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_6a78e18b, p_Configuration := p_Configuration_6a78e18b, p_Configuration_Clear := TRUE, p_Status := p_Status_6a78e18b, p_IsCustom := p_IsCustom_6a78e18b, p_MetadataSource := p_MetadataSource_6a78e18b);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_09bcb71c UUID;
  p_IntegrationObjectID_09bcb71c UUID;
  p_Name_09bcb71c VARCHAR(255);
  p_DisplayName_09bcb71c VARCHAR(255);
  p_Description_09bcb71c TEXT;
  p_Category_09bcb71c VARCHAR(100);
  p_Type_09bcb71c VARCHAR(100);
  p_Length_09bcb71c INTEGER;
  p_Precision_09bcb71c INTEGER;
  p_Scale_09bcb71c INTEGER;
  p_AllowsNull_09bcb71c BOOLEAN;
  p_DefaultValue_09bcb71c VARCHAR(255);
  p_IsPrimaryKey_09bcb71c BOOLEAN;
  p_IsUniqueKey_09bcb71c BOOLEAN;
  p_IsReadOnly_09bcb71c BOOLEAN;
  p_IsRequired_09bcb71c BOOLEAN;
  p_RelatedIntegrationObjectID_09bcb71c UUID;
  p_RelatedIntegrationObjectFieldName_09bcb71c VARCHAR(255);
  p_Sequence_09bcb71c INTEGER;
  p_Configuration_09bcb71c TEXT;
  p_Status_09bcb71c VARCHAR(25);
  p_IsCustom_09bcb71c BOOLEAN;
  p_MetadataSource_09bcb71c VARCHAR(20);
BEGIN
  p_ID_09bcb71c := 'B5E97EE6-8A57-5673-85FB-E07A7F23EECD';
  p_IntegrationObjectID_09bcb71c := '35593E67-CBB4-4C88-9438-80C1D7F4B2D0';
  p_Name_09bcb71c := 'start-month';
  p_DisplayName_09bcb71c := 'Start Month';
  p_Description_09bcb71c := 'Month (1-12) of the affiliation start date, when given.';
  p_Type_09bcb71c := 'Integer';
  p_AllowsNull_09bcb71c := TRUE;
  p_IsPrimaryKey_09bcb71c := FALSE;
  p_IsUniqueKey_09bcb71c := FALSE;
  p_IsReadOnly_09bcb71c := TRUE;
  p_IsRequired_09bcb71c := FALSE;
  p_Sequence_09bcb71c := 16;
  p_Status_09bcb71c := 'Active';
  p_IsCustom_09bcb71c := FALSE;
  p_MetadataSource_09bcb71c := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_09bcb71c, p_IntegrationObjectID := p_IntegrationObjectID_09bcb71c, p_Name := p_Name_09bcb71c, p_DisplayName := p_DisplayName_09bcb71c, p_Description := p_Description_09bcb71c, p_Category := p_Category_09bcb71c, p_Category_Clear := TRUE, p_Type := p_Type_09bcb71c, p_Length := p_Length_09bcb71c, p_Length_Clear := TRUE, p_Precision := p_Precision_09bcb71c, p_Precision_Clear := TRUE, p_Scale := p_Scale_09bcb71c, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_09bcb71c, p_DefaultValue := p_DefaultValue_09bcb71c, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_09bcb71c, p_IsUniqueKey := p_IsUniqueKey_09bcb71c, p_IsReadOnly := p_IsReadOnly_09bcb71c, p_IsRequired := p_IsRequired_09bcb71c, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_09bcb71c, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_09bcb71c, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_09bcb71c, p_Configuration := p_Configuration_09bcb71c, p_Configuration_Clear := TRUE, p_Status := p_Status_09bcb71c, p_IsCustom := p_IsCustom_09bcb71c, p_MetadataSource := p_MetadataSource_09bcb71c);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_d8f500a8 UUID;
  p_IntegrationObjectID_d8f500a8 UUID;
  p_Name_d8f500a8 VARCHAR(255);
  p_DisplayName_d8f500a8 VARCHAR(255);
  p_Description_d8f500a8 TEXT;
  p_Category_d8f500a8 VARCHAR(100);
  p_Type_d8f500a8 VARCHAR(100);
  p_Length_d8f500a8 INTEGER;
  p_Precision_d8f500a8 INTEGER;
  p_Scale_d8f500a8 INTEGER;
  p_AllowsNull_d8f500a8 BOOLEAN;
  p_DefaultValue_d8f500a8 VARCHAR(255);
  p_IsPrimaryKey_d8f500a8 BOOLEAN;
  p_IsUniqueKey_d8f500a8 BOOLEAN;
  p_IsReadOnly_d8f500a8 BOOLEAN;
  p_IsRequired_d8f500a8 BOOLEAN;
  p_RelatedIntegrationObjectID_d8f500a8 UUID;
  p_RelatedIntegrationObjectFieldName_d8f500a8 VARCHAR(255);
  p_Sequence_d8f500a8 INTEGER;
  p_Configuration_d8f500a8 TEXT;
  p_Status_d8f500a8 VARCHAR(25);
  p_IsCustom_d8f500a8 BOOLEAN;
  p_MetadataSource_d8f500a8 VARCHAR(20);
BEGIN
  p_ID_d8f500a8 := '991114B8-3ED9-59D4-89DD-E42A8A36D3B0';
  p_IntegrationObjectID_d8f500a8 := '35593E67-CBB4-4C88-9438-80C1D7F4B2D0';
  p_Name_d8f500a8 := 'start-day';
  p_DisplayName_d8f500a8 := 'Start Day';
  p_Description_d8f500a8 := 'Day of month of the affiliation start date, when given.';
  p_Type_d8f500a8 := 'Integer';
  p_AllowsNull_d8f500a8 := TRUE;
  p_IsPrimaryKey_d8f500a8 := FALSE;
  p_IsUniqueKey_d8f500a8 := FALSE;
  p_IsReadOnly_d8f500a8 := TRUE;
  p_IsRequired_d8f500a8 := FALSE;
  p_Sequence_d8f500a8 := 17;
  p_Status_d8f500a8 := 'Active';
  p_IsCustom_d8f500a8 := FALSE;
  p_MetadataSource_d8f500a8 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_d8f500a8, p_IntegrationObjectID := p_IntegrationObjectID_d8f500a8, p_Name := p_Name_d8f500a8, p_DisplayName := p_DisplayName_d8f500a8, p_Description := p_Description_d8f500a8, p_Category := p_Category_d8f500a8, p_Category_Clear := TRUE, p_Type := p_Type_d8f500a8, p_Length := p_Length_d8f500a8, p_Length_Clear := TRUE, p_Precision := p_Precision_d8f500a8, p_Precision_Clear := TRUE, p_Scale := p_Scale_d8f500a8, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_d8f500a8, p_DefaultValue := p_DefaultValue_d8f500a8, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_d8f500a8, p_IsUniqueKey := p_IsUniqueKey_d8f500a8, p_IsReadOnly := p_IsReadOnly_d8f500a8, p_IsRequired := p_IsRequired_d8f500a8, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_d8f500a8, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_d8f500a8, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_d8f500a8, p_Configuration := p_Configuration_d8f500a8, p_Configuration_Clear := TRUE, p_Status := p_Status_d8f500a8, p_IsCustom := p_IsCustom_d8f500a8, p_MetadataSource := p_MetadataSource_d8f500a8);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_c09892c6 UUID;
  p_IntegrationObjectID_c09892c6 UUID;
  p_Name_c09892c6 VARCHAR(255);
  p_DisplayName_c09892c6 VARCHAR(255);
  p_Description_c09892c6 TEXT;
  p_Category_c09892c6 VARCHAR(100);
  p_Type_c09892c6 VARCHAR(100);
  p_Length_c09892c6 INTEGER;
  p_Precision_c09892c6 INTEGER;
  p_Scale_c09892c6 INTEGER;
  p_AllowsNull_c09892c6 BOOLEAN;
  p_DefaultValue_c09892c6 VARCHAR(255);
  p_IsPrimaryKey_c09892c6 BOOLEAN;
  p_IsUniqueKey_c09892c6 BOOLEAN;
  p_IsReadOnly_c09892c6 BOOLEAN;
  p_IsRequired_c09892c6 BOOLEAN;
  p_RelatedIntegrationObjectID_c09892c6 UUID;
  p_RelatedIntegrationObjectFieldName_c09892c6 VARCHAR(255);
  p_Sequence_c09892c6 INTEGER;
  p_Configuration_c09892c6 TEXT;
  p_Status_c09892c6 VARCHAR(25);
  p_IsCustom_c09892c6 BOOLEAN;
  p_MetadataSource_c09892c6 VARCHAR(20);
BEGIN
  p_ID_c09892c6 := 'D0A6050D-4679-5E99-B5AA-D63C55C6B470';
  p_IntegrationObjectID_c09892c6 := '35593E67-CBB4-4C88-9438-80C1D7F4B2D0';
  p_Name_c09892c6 := 'end-year';
  p_DisplayName_c09892c6 := 'End Year';
  p_Description_c09892c6 := 'Year of the affiliation end date; empty for a current/ongoing role; ORCID dates are partial, so month/day may be absent.';
  p_Type_c09892c6 := 'Integer';
  p_AllowsNull_c09892c6 := TRUE;
  p_IsPrimaryKey_c09892c6 := FALSE;
  p_IsUniqueKey_c09892c6 := FALSE;
  p_IsReadOnly_c09892c6 := TRUE;
  p_IsRequired_c09892c6 := FALSE;
  p_Sequence_c09892c6 := 18;
  p_Status_c09892c6 := 'Active';
  p_IsCustom_c09892c6 := FALSE;
  p_MetadataSource_c09892c6 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_c09892c6, p_IntegrationObjectID := p_IntegrationObjectID_c09892c6, p_Name := p_Name_c09892c6, p_DisplayName := p_DisplayName_c09892c6, p_Description := p_Description_c09892c6, p_Category := p_Category_c09892c6, p_Category_Clear := TRUE, p_Type := p_Type_c09892c6, p_Length := p_Length_c09892c6, p_Length_Clear := TRUE, p_Precision := p_Precision_c09892c6, p_Precision_Clear := TRUE, p_Scale := p_Scale_c09892c6, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_c09892c6, p_DefaultValue := p_DefaultValue_c09892c6, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_c09892c6, p_IsUniqueKey := p_IsUniqueKey_c09892c6, p_IsReadOnly := p_IsReadOnly_c09892c6, p_IsRequired := p_IsRequired_c09892c6, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_c09892c6, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_c09892c6, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_c09892c6, p_Configuration := p_Configuration_c09892c6, p_Configuration_Clear := TRUE, p_Status := p_Status_c09892c6, p_IsCustom := p_IsCustom_c09892c6, p_MetadataSource := p_MetadataSource_c09892c6);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_52359736 UUID;
  p_IntegrationObjectID_52359736 UUID;
  p_Name_52359736 VARCHAR(255);
  p_DisplayName_52359736 VARCHAR(255);
  p_Description_52359736 TEXT;
  p_Category_52359736 VARCHAR(100);
  p_Type_52359736 VARCHAR(100);
  p_Length_52359736 INTEGER;
  p_Precision_52359736 INTEGER;
  p_Scale_52359736 INTEGER;
  p_AllowsNull_52359736 BOOLEAN;
  p_DefaultValue_52359736 VARCHAR(255);
  p_IsPrimaryKey_52359736 BOOLEAN;
  p_IsUniqueKey_52359736 BOOLEAN;
  p_IsReadOnly_52359736 BOOLEAN;
  p_IsRequired_52359736 BOOLEAN;
  p_RelatedIntegrationObjectID_52359736 UUID;
  p_RelatedIntegrationObjectFieldName_52359736 VARCHAR(255);
  p_Sequence_52359736 INTEGER;
  p_Configuration_52359736 TEXT;
  p_Status_52359736 VARCHAR(25);
  p_IsCustom_52359736 BOOLEAN;
  p_MetadataSource_52359736 VARCHAR(20);
BEGIN
  p_ID_52359736 := 'E8DC2990-8DCA-518E-B859-E2BF7A74DF0E';
  p_IntegrationObjectID_52359736 := '35593E67-CBB4-4C88-9438-80C1D7F4B2D0';
  p_Name_52359736 := 'end-month';
  p_DisplayName_52359736 := 'End Month';
  p_Description_52359736 := 'Month (1-12) of the affiliation end date; empty for a current/ongoing role, when given.';
  p_Type_52359736 := 'Integer';
  p_AllowsNull_52359736 := TRUE;
  p_IsPrimaryKey_52359736 := FALSE;
  p_IsUniqueKey_52359736 := FALSE;
  p_IsReadOnly_52359736 := TRUE;
  p_IsRequired_52359736 := FALSE;
  p_Sequence_52359736 := 19;
  p_Status_52359736 := 'Active';
  p_IsCustom_52359736 := FALSE;
  p_MetadataSource_52359736 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_52359736, p_IntegrationObjectID := p_IntegrationObjectID_52359736, p_Name := p_Name_52359736, p_DisplayName := p_DisplayName_52359736, p_Description := p_Description_52359736, p_Category := p_Category_52359736, p_Category_Clear := TRUE, p_Type := p_Type_52359736, p_Length := p_Length_52359736, p_Length_Clear := TRUE, p_Precision := p_Precision_52359736, p_Precision_Clear := TRUE, p_Scale := p_Scale_52359736, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_52359736, p_DefaultValue := p_DefaultValue_52359736, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_52359736, p_IsUniqueKey := p_IsUniqueKey_52359736, p_IsReadOnly := p_IsReadOnly_52359736, p_IsRequired := p_IsRequired_52359736, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_52359736, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_52359736, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_52359736, p_Configuration := p_Configuration_52359736, p_Configuration_Clear := TRUE, p_Status := p_Status_52359736, p_IsCustom := p_IsCustom_52359736, p_MetadataSource := p_MetadataSource_52359736);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_acd0d67d UUID;
  p_IntegrationObjectID_acd0d67d UUID;
  p_Name_acd0d67d VARCHAR(255);
  p_DisplayName_acd0d67d VARCHAR(255);
  p_Description_acd0d67d TEXT;
  p_Category_acd0d67d VARCHAR(100);
  p_Type_acd0d67d VARCHAR(100);
  p_Length_acd0d67d INTEGER;
  p_Precision_acd0d67d INTEGER;
  p_Scale_acd0d67d INTEGER;
  p_AllowsNull_acd0d67d BOOLEAN;
  p_DefaultValue_acd0d67d VARCHAR(255);
  p_IsPrimaryKey_acd0d67d BOOLEAN;
  p_IsUniqueKey_acd0d67d BOOLEAN;
  p_IsReadOnly_acd0d67d BOOLEAN;
  p_IsRequired_acd0d67d BOOLEAN;
  p_RelatedIntegrationObjectID_acd0d67d UUID;
  p_RelatedIntegrationObjectFieldName_acd0d67d VARCHAR(255);
  p_Sequence_acd0d67d INTEGER;
  p_Configuration_acd0d67d TEXT;
  p_Status_acd0d67d VARCHAR(25);
  p_IsCustom_acd0d67d BOOLEAN;
  p_MetadataSource_acd0d67d VARCHAR(20);
BEGIN
  p_ID_acd0d67d := '7FD4DCE0-8EAB-58EE-8311-63A843D8D059';
  p_IntegrationObjectID_acd0d67d := '35593E67-CBB4-4C88-9438-80C1D7F4B2D0';
  p_Name_acd0d67d := 'end-day';
  p_DisplayName_acd0d67d := 'End Day';
  p_Description_acd0d67d := 'Day of month of the affiliation end date; empty for a current/ongoing role, when given.';
  p_Type_acd0d67d := 'Integer';
  p_AllowsNull_acd0d67d := TRUE;
  p_IsPrimaryKey_acd0d67d := FALSE;
  p_IsUniqueKey_acd0d67d := FALSE;
  p_IsReadOnly_acd0d67d := TRUE;
  p_IsRequired_acd0d67d := FALSE;
  p_Sequence_acd0d67d := 20;
  p_Status_acd0d67d := 'Active';
  p_IsCustom_acd0d67d := FALSE;
  p_MetadataSource_acd0d67d := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_acd0d67d, p_IntegrationObjectID := p_IntegrationObjectID_acd0d67d, p_Name := p_Name_acd0d67d, p_DisplayName := p_DisplayName_acd0d67d, p_Description := p_Description_acd0d67d, p_Category := p_Category_acd0d67d, p_Category_Clear := TRUE, p_Type := p_Type_acd0d67d, p_Length := p_Length_acd0d67d, p_Length_Clear := TRUE, p_Precision := p_Precision_acd0d67d, p_Precision_Clear := TRUE, p_Scale := p_Scale_acd0d67d, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_acd0d67d, p_DefaultValue := p_DefaultValue_acd0d67d, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_acd0d67d, p_IsUniqueKey := p_IsUniqueKey_acd0d67d, p_IsReadOnly := p_IsReadOnly_acd0d67d, p_IsRequired := p_IsRequired_acd0d67d, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_acd0d67d, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_acd0d67d, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_acd0d67d, p_Configuration := p_Configuration_acd0d67d, p_Configuration_Clear := TRUE, p_Status := p_Status_acd0d67d, p_IsCustom := p_IsCustom_acd0d67d, p_MetadataSource := p_MetadataSource_acd0d67d);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_837d59b4 UUID;
  p_IntegrationObjectID_837d59b4 UUID;
  p_Name_837d59b4 VARCHAR(255);
  p_DisplayName_837d59b4 VARCHAR(255);
  p_Description_837d59b4 TEXT;
  p_Category_837d59b4 VARCHAR(100);
  p_Type_837d59b4 VARCHAR(100);
  p_Length_837d59b4 INTEGER;
  p_Precision_837d59b4 INTEGER;
  p_Scale_837d59b4 INTEGER;
  p_AllowsNull_837d59b4 BOOLEAN;
  p_DefaultValue_837d59b4 VARCHAR(255);
  p_IsPrimaryKey_837d59b4 BOOLEAN;
  p_IsUniqueKey_837d59b4 BOOLEAN;
  p_IsReadOnly_837d59b4 BOOLEAN;
  p_IsRequired_837d59b4 BOOLEAN;
  p_RelatedIntegrationObjectID_837d59b4 UUID;
  p_RelatedIntegrationObjectFieldName_837d59b4 VARCHAR(255);
  p_Sequence_837d59b4 INTEGER;
  p_Configuration_837d59b4 TEXT;
  p_Status_837d59b4 VARCHAR(25);
  p_IsCustom_837d59b4 BOOLEAN;
  p_MetadataSource_837d59b4 VARCHAR(20);
BEGIN
  p_ID_837d59b4 := 'EC494265-A034-5F71-AD92-D51BD46C0334';
  p_IntegrationObjectID_837d59b4 := '35593E67-CBB4-4C88-9438-80C1D7F4B2D0';
  p_Name_837d59b4 := 'organization-name';
  p_DisplayName_837d59b4 := 'Organization Name';
  p_Description_837d59b4 := 'Name of the organization. Lifted from organization.name.';
  p_Type_837d59b4 := 'String';
  p_Length_837d59b4 := 1000;
  p_AllowsNull_837d59b4 := TRUE;
  p_IsPrimaryKey_837d59b4 := FALSE;
  p_IsUniqueKey_837d59b4 := FALSE;
  p_IsReadOnly_837d59b4 := TRUE;
  p_IsRequired_837d59b4 := FALSE;
  p_Sequence_837d59b4 := 21;
  p_Status_837d59b4 := 'Active';
  p_IsCustom_837d59b4 := FALSE;
  p_MetadataSource_837d59b4 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_837d59b4, p_IntegrationObjectID := p_IntegrationObjectID_837d59b4, p_Name := p_Name_837d59b4, p_DisplayName := p_DisplayName_837d59b4, p_Description := p_Description_837d59b4, p_Category := p_Category_837d59b4, p_Category_Clear := TRUE, p_Type := p_Type_837d59b4, p_Length := p_Length_837d59b4, p_Precision := p_Precision_837d59b4, p_Precision_Clear := TRUE, p_Scale := p_Scale_837d59b4, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_837d59b4, p_DefaultValue := p_DefaultValue_837d59b4, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_837d59b4, p_IsUniqueKey := p_IsUniqueKey_837d59b4, p_IsReadOnly := p_IsReadOnly_837d59b4, p_IsRequired := p_IsRequired_837d59b4, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_837d59b4, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_837d59b4, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_837d59b4, p_Configuration := p_Configuration_837d59b4, p_Configuration_Clear := TRUE, p_Status := p_Status_837d59b4, p_IsCustom := p_IsCustom_837d59b4, p_MetadataSource := p_MetadataSource_837d59b4);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_308fbe18 UUID;
  p_IntegrationObjectID_308fbe18 UUID;
  p_Name_308fbe18 VARCHAR(255);
  p_DisplayName_308fbe18 VARCHAR(255);
  p_Description_308fbe18 TEXT;
  p_Category_308fbe18 VARCHAR(100);
  p_Type_308fbe18 VARCHAR(100);
  p_Length_308fbe18 INTEGER;
  p_Precision_308fbe18 INTEGER;
  p_Scale_308fbe18 INTEGER;
  p_AllowsNull_308fbe18 BOOLEAN;
  p_DefaultValue_308fbe18 VARCHAR(255);
  p_IsPrimaryKey_308fbe18 BOOLEAN;
  p_IsUniqueKey_308fbe18 BOOLEAN;
  p_IsReadOnly_308fbe18 BOOLEAN;
  p_IsRequired_308fbe18 BOOLEAN;
  p_RelatedIntegrationObjectID_308fbe18 UUID;
  p_RelatedIntegrationObjectFieldName_308fbe18 VARCHAR(255);
  p_Sequence_308fbe18 INTEGER;
  p_Configuration_308fbe18 TEXT;
  p_Status_308fbe18 VARCHAR(25);
  p_IsCustom_308fbe18 BOOLEAN;
  p_MetadataSource_308fbe18 VARCHAR(20);
BEGIN
  p_ID_308fbe18 := '7B04E234-870C-5800-AEB5-C40899002F23';
  p_IntegrationObjectID_308fbe18 := '35593E67-CBB4-4C88-9438-80C1D7F4B2D0';
  p_Name_308fbe18 := 'organization-city';
  p_DisplayName_308fbe18 := 'Organization City';
  p_Description_308fbe18 := 'City of the organization. Lifted from organization.address.city.';
  p_Type_308fbe18 := 'String';
  p_Length_308fbe18 := 255;
  p_AllowsNull_308fbe18 := TRUE;
  p_IsPrimaryKey_308fbe18 := FALSE;
  p_IsUniqueKey_308fbe18 := FALSE;
  p_IsReadOnly_308fbe18 := TRUE;
  p_IsRequired_308fbe18 := FALSE;
  p_Sequence_308fbe18 := 22;
  p_Status_308fbe18 := 'Active';
  p_IsCustom_308fbe18 := FALSE;
  p_MetadataSource_308fbe18 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_308fbe18, p_IntegrationObjectID := p_IntegrationObjectID_308fbe18, p_Name := p_Name_308fbe18, p_DisplayName := p_DisplayName_308fbe18, p_Description := p_Description_308fbe18, p_Category := p_Category_308fbe18, p_Category_Clear := TRUE, p_Type := p_Type_308fbe18, p_Length := p_Length_308fbe18, p_Precision := p_Precision_308fbe18, p_Precision_Clear := TRUE, p_Scale := p_Scale_308fbe18, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_308fbe18, p_DefaultValue := p_DefaultValue_308fbe18, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_308fbe18, p_IsUniqueKey := p_IsUniqueKey_308fbe18, p_IsReadOnly := p_IsReadOnly_308fbe18, p_IsRequired := p_IsRequired_308fbe18, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_308fbe18, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_308fbe18, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_308fbe18, p_Configuration := p_Configuration_308fbe18, p_Configuration_Clear := TRUE, p_Status := p_Status_308fbe18, p_IsCustom := p_IsCustom_308fbe18, p_MetadataSource := p_MetadataSource_308fbe18);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_e3ffd2a3 UUID;
  p_IntegrationObjectID_e3ffd2a3 UUID;
  p_Name_e3ffd2a3 VARCHAR(255);
  p_DisplayName_e3ffd2a3 VARCHAR(255);
  p_Description_e3ffd2a3 TEXT;
  p_Category_e3ffd2a3 VARCHAR(100);
  p_Type_e3ffd2a3 VARCHAR(100);
  p_Length_e3ffd2a3 INTEGER;
  p_Precision_e3ffd2a3 INTEGER;
  p_Scale_e3ffd2a3 INTEGER;
  p_AllowsNull_e3ffd2a3 BOOLEAN;
  p_DefaultValue_e3ffd2a3 VARCHAR(255);
  p_IsPrimaryKey_e3ffd2a3 BOOLEAN;
  p_IsUniqueKey_e3ffd2a3 BOOLEAN;
  p_IsReadOnly_e3ffd2a3 BOOLEAN;
  p_IsRequired_e3ffd2a3 BOOLEAN;
  p_RelatedIntegrationObjectID_e3ffd2a3 UUID;
  p_RelatedIntegrationObjectFieldName_e3ffd2a3 VARCHAR(255);
  p_Sequence_e3ffd2a3 INTEGER;
  p_Configuration_e3ffd2a3 TEXT;
  p_Status_e3ffd2a3 VARCHAR(25);
  p_IsCustom_e3ffd2a3 BOOLEAN;
  p_MetadataSource_e3ffd2a3 VARCHAR(20);
BEGIN
  p_ID_e3ffd2a3 := '4FF4E3EE-C785-5B57-9B49-EDD5A56F28FF';
  p_IntegrationObjectID_e3ffd2a3 := '35593E67-CBB4-4C88-9438-80C1D7F4B2D0';
  p_Name_e3ffd2a3 := 'organization-region';
  p_DisplayName_e3ffd2a3 := 'Organization Region';
  p_Description_e3ffd2a3 := 'Region/state of the organization. Lifted from organization.address.region.';
  p_Type_e3ffd2a3 := 'String';
  p_Length_e3ffd2a3 := 255;
  p_AllowsNull_e3ffd2a3 := TRUE;
  p_IsPrimaryKey_e3ffd2a3 := FALSE;
  p_IsUniqueKey_e3ffd2a3 := FALSE;
  p_IsReadOnly_e3ffd2a3 := TRUE;
  p_IsRequired_e3ffd2a3 := FALSE;
  p_Sequence_e3ffd2a3 := 23;
  p_Status_e3ffd2a3 := 'Active';
  p_IsCustom_e3ffd2a3 := FALSE;
  p_MetadataSource_e3ffd2a3 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_e3ffd2a3, p_IntegrationObjectID := p_IntegrationObjectID_e3ffd2a3, p_Name := p_Name_e3ffd2a3, p_DisplayName := p_DisplayName_e3ffd2a3, p_Description := p_Description_e3ffd2a3, p_Category := p_Category_e3ffd2a3, p_Category_Clear := TRUE, p_Type := p_Type_e3ffd2a3, p_Length := p_Length_e3ffd2a3, p_Precision := p_Precision_e3ffd2a3, p_Precision_Clear := TRUE, p_Scale := p_Scale_e3ffd2a3, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_e3ffd2a3, p_DefaultValue := p_DefaultValue_e3ffd2a3, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_e3ffd2a3, p_IsUniqueKey := p_IsUniqueKey_e3ffd2a3, p_IsReadOnly := p_IsReadOnly_e3ffd2a3, p_IsRequired := p_IsRequired_e3ffd2a3, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_e3ffd2a3, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_e3ffd2a3, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_e3ffd2a3, p_Configuration := p_Configuration_e3ffd2a3, p_Configuration_Clear := TRUE, p_Status := p_Status_e3ffd2a3, p_IsCustom := p_IsCustom_e3ffd2a3, p_MetadataSource := p_MetadataSource_e3ffd2a3);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_959fbcdf UUID;
  p_IntegrationObjectID_959fbcdf UUID;
  p_Name_959fbcdf VARCHAR(255);
  p_DisplayName_959fbcdf VARCHAR(255);
  p_Description_959fbcdf TEXT;
  p_Category_959fbcdf VARCHAR(100);
  p_Type_959fbcdf VARCHAR(100);
  p_Length_959fbcdf INTEGER;
  p_Precision_959fbcdf INTEGER;
  p_Scale_959fbcdf INTEGER;
  p_AllowsNull_959fbcdf BOOLEAN;
  p_DefaultValue_959fbcdf VARCHAR(255);
  p_IsPrimaryKey_959fbcdf BOOLEAN;
  p_IsUniqueKey_959fbcdf BOOLEAN;
  p_IsReadOnly_959fbcdf BOOLEAN;
  p_IsRequired_959fbcdf BOOLEAN;
  p_RelatedIntegrationObjectID_959fbcdf UUID;
  p_RelatedIntegrationObjectFieldName_959fbcdf VARCHAR(255);
  p_Sequence_959fbcdf INTEGER;
  p_Configuration_959fbcdf TEXT;
  p_Status_959fbcdf VARCHAR(25);
  p_IsCustom_959fbcdf BOOLEAN;
  p_MetadataSource_959fbcdf VARCHAR(20);
BEGIN
  p_ID_959fbcdf := '1CAD3DA1-0AF9-5D28-87C0-1117D64B4A6B';
  p_IntegrationObjectID_959fbcdf := '35593E67-CBB4-4C88-9438-80C1D7F4B2D0';
  p_Name_959fbcdf := 'organization-country';
  p_DisplayName_959fbcdf := 'Organization Country';
  p_Description_959fbcdf := 'ISO country code of the organization. Lifted from organization.address.country.';
  p_Type_959fbcdf := 'String';
  p_Length_959fbcdf := 50;
  p_AllowsNull_959fbcdf := TRUE;
  p_IsPrimaryKey_959fbcdf := FALSE;
  p_IsUniqueKey_959fbcdf := FALSE;
  p_IsReadOnly_959fbcdf := TRUE;
  p_IsRequired_959fbcdf := FALSE;
  p_Sequence_959fbcdf := 24;
  p_Status_959fbcdf := 'Active';
  p_IsCustom_959fbcdf := FALSE;
  p_MetadataSource_959fbcdf := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_959fbcdf, p_IntegrationObjectID := p_IntegrationObjectID_959fbcdf, p_Name := p_Name_959fbcdf, p_DisplayName := p_DisplayName_959fbcdf, p_Description := p_Description_959fbcdf, p_Category := p_Category_959fbcdf, p_Category_Clear := TRUE, p_Type := p_Type_959fbcdf, p_Length := p_Length_959fbcdf, p_Precision := p_Precision_959fbcdf, p_Precision_Clear := TRUE, p_Scale := p_Scale_959fbcdf, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_959fbcdf, p_DefaultValue := p_DefaultValue_959fbcdf, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_959fbcdf, p_IsUniqueKey := p_IsUniqueKey_959fbcdf, p_IsReadOnly := p_IsReadOnly_959fbcdf, p_IsRequired := p_IsRequired_959fbcdf, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_959fbcdf, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_959fbcdf, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_959fbcdf, p_Configuration := p_Configuration_959fbcdf, p_Configuration_Clear := TRUE, p_Status := p_Status_959fbcdf, p_IsCustom := p_IsCustom_959fbcdf, p_MetadataSource := p_MetadataSource_959fbcdf);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_243ba4eb UUID;
  p_IntegrationObjectID_243ba4eb UUID;
  p_Name_243ba4eb VARCHAR(255);
  p_DisplayName_243ba4eb VARCHAR(255);
  p_Description_243ba4eb TEXT;
  p_Category_243ba4eb VARCHAR(100);
  p_Type_243ba4eb VARCHAR(100);
  p_Length_243ba4eb INTEGER;
  p_Precision_243ba4eb INTEGER;
  p_Scale_243ba4eb INTEGER;
  p_AllowsNull_243ba4eb BOOLEAN;
  p_DefaultValue_243ba4eb VARCHAR(255);
  p_IsPrimaryKey_243ba4eb BOOLEAN;
  p_IsUniqueKey_243ba4eb BOOLEAN;
  p_IsReadOnly_243ba4eb BOOLEAN;
  p_IsRequired_243ba4eb BOOLEAN;
  p_RelatedIntegrationObjectID_243ba4eb UUID;
  p_RelatedIntegrationObjectFieldName_243ba4eb VARCHAR(255);
  p_Sequence_243ba4eb INTEGER;
  p_Configuration_243ba4eb TEXT;
  p_Status_243ba4eb VARCHAR(25);
  p_IsCustom_243ba4eb BOOLEAN;
  p_MetadataSource_243ba4eb VARCHAR(20);
BEGIN
  p_ID_243ba4eb := '7961553B-BD63-51B3-A9F2-940BCF104101';
  p_IntegrationObjectID_243ba4eb := '35593E67-CBB4-4C88-9438-80C1D7F4B2D0';
  p_Name_243ba4eb := 'organization-disambiguated-id';
  p_DisplayName_243ba4eb := 'Organization Disambiguated Id';
  p_Description_243ba4eb := 'Canonical identifier of the organization in the disambiguation source (e.g. a RINGGOLD or ROR id), so the same institution matches across records.';
  p_Type_243ba4eb := 'String';
  p_Length_243ba4eb := 255;
  p_AllowsNull_243ba4eb := TRUE;
  p_IsPrimaryKey_243ba4eb := FALSE;
  p_IsUniqueKey_243ba4eb := FALSE;
  p_IsReadOnly_243ba4eb := TRUE;
  p_IsRequired_243ba4eb := FALSE;
  p_Sequence_243ba4eb := 25;
  p_Status_243ba4eb := 'Active';
  p_IsCustom_243ba4eb := FALSE;
  p_MetadataSource_243ba4eb := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_243ba4eb, p_IntegrationObjectID := p_IntegrationObjectID_243ba4eb, p_Name := p_Name_243ba4eb, p_DisplayName := p_DisplayName_243ba4eb, p_Description := p_Description_243ba4eb, p_Category := p_Category_243ba4eb, p_Category_Clear := TRUE, p_Type := p_Type_243ba4eb, p_Length := p_Length_243ba4eb, p_Precision := p_Precision_243ba4eb, p_Precision_Clear := TRUE, p_Scale := p_Scale_243ba4eb, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_243ba4eb, p_DefaultValue := p_DefaultValue_243ba4eb, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_243ba4eb, p_IsUniqueKey := p_IsUniqueKey_243ba4eb, p_IsReadOnly := p_IsReadOnly_243ba4eb, p_IsRequired := p_IsRequired_243ba4eb, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_243ba4eb, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_243ba4eb, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_243ba4eb, p_Configuration := p_Configuration_243ba4eb, p_Configuration_Clear := TRUE, p_Status := p_Status_243ba4eb, p_IsCustom := p_IsCustom_243ba4eb, p_MetadataSource := p_MetadataSource_243ba4eb);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_c419b42a UUID;
  p_IntegrationObjectID_c419b42a UUID;
  p_Name_c419b42a VARCHAR(255);
  p_DisplayName_c419b42a VARCHAR(255);
  p_Description_c419b42a TEXT;
  p_Category_c419b42a VARCHAR(100);
  p_Type_c419b42a VARCHAR(100);
  p_Length_c419b42a INTEGER;
  p_Precision_c419b42a INTEGER;
  p_Scale_c419b42a INTEGER;
  p_AllowsNull_c419b42a BOOLEAN;
  p_DefaultValue_c419b42a VARCHAR(255);
  p_IsPrimaryKey_c419b42a BOOLEAN;
  p_IsUniqueKey_c419b42a BOOLEAN;
  p_IsReadOnly_c419b42a BOOLEAN;
  p_IsRequired_c419b42a BOOLEAN;
  p_RelatedIntegrationObjectID_c419b42a UUID;
  p_RelatedIntegrationObjectFieldName_c419b42a VARCHAR(255);
  p_Sequence_c419b42a INTEGER;
  p_Configuration_c419b42a TEXT;
  p_Status_c419b42a VARCHAR(25);
  p_IsCustom_c419b42a BOOLEAN;
  p_MetadataSource_c419b42a VARCHAR(20);
BEGIN
  p_ID_c419b42a := '120B4B37-2547-5123-949E-1AB331541A34';
  p_IntegrationObjectID_c419b42a := '35593E67-CBB4-4C88-9438-80C1D7F4B2D0';
  p_Name_c419b42a := 'organization-disambiguation-source';
  p_DisplayName_c419b42a := 'Organization Disambiguation Source';
  p_Description_c419b42a := 'Registry the disambiguated id comes from (RINGGOLD, ROR, FUNDREF, GRID, LEI).';
  p_Type_c419b42a := 'String';
  p_Length_c419b42a := 100;
  p_AllowsNull_c419b42a := TRUE;
  p_IsPrimaryKey_c419b42a := FALSE;
  p_IsUniqueKey_c419b42a := FALSE;
  p_IsReadOnly_c419b42a := TRUE;
  p_IsRequired_c419b42a := FALSE;
  p_Sequence_c419b42a := 26;
  p_Status_c419b42a := 'Active';
  p_IsCustom_c419b42a := FALSE;
  p_MetadataSource_c419b42a := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_c419b42a, p_IntegrationObjectID := p_IntegrationObjectID_c419b42a, p_Name := p_Name_c419b42a, p_DisplayName := p_DisplayName_c419b42a, p_Description := p_Description_c419b42a, p_Category := p_Category_c419b42a, p_Category_Clear := TRUE, p_Type := p_Type_c419b42a, p_Length := p_Length_c419b42a, p_Precision := p_Precision_c419b42a, p_Precision_Clear := TRUE, p_Scale := p_Scale_c419b42a, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_c419b42a, p_DefaultValue := p_DefaultValue_c419b42a, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_c419b42a, p_IsUniqueKey := p_IsUniqueKey_c419b42a, p_IsReadOnly := p_IsReadOnly_c419b42a, p_IsRequired := p_IsRequired_c419b42a, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_c419b42a, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_c419b42a, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_c419b42a, p_Configuration := p_Configuration_c419b42a, p_Configuration_Clear := TRUE, p_Status := p_Status_c419b42a, p_IsCustom := p_IsCustom_c419b42a, p_MetadataSource := p_MetadataSource_c419b42a);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_8dd82c87 UUID;
  p_IntegrationObjectID_8dd82c87 UUID;
  p_Name_8dd82c87 VARCHAR(255);
  p_DisplayName_8dd82c87 VARCHAR(255);
  p_Description_8dd82c87 TEXT;
  p_Category_8dd82c87 VARCHAR(100);
  p_Type_8dd82c87 VARCHAR(100);
  p_Length_8dd82c87 INTEGER;
  p_Precision_8dd82c87 INTEGER;
  p_Scale_8dd82c87 INTEGER;
  p_AllowsNull_8dd82c87 BOOLEAN;
  p_DefaultValue_8dd82c87 VARCHAR(255);
  p_IsPrimaryKey_8dd82c87 BOOLEAN;
  p_IsUniqueKey_8dd82c87 BOOLEAN;
  p_IsReadOnly_8dd82c87 BOOLEAN;
  p_IsRequired_8dd82c87 BOOLEAN;
  p_RelatedIntegrationObjectID_8dd82c87 UUID;
  p_RelatedIntegrationObjectFieldName_8dd82c87 VARCHAR(255);
  p_Sequence_8dd82c87 INTEGER;
  p_Configuration_8dd82c87 TEXT;
  p_Status_8dd82c87 VARCHAR(25);
  p_IsCustom_8dd82c87 BOOLEAN;
  p_MetadataSource_8dd82c87 VARCHAR(20);
BEGIN
  p_ID_8dd82c87 := '810D7395-2D37-5FED-A50F-F3EE38029691';
  p_IntegrationObjectID_8dd82c87 := '35593E67-CBB4-4C88-9438-80C1D7F4B2D0';
  p_Name_8dd82c87 := 'source-name';
  p_DisplayName_8dd82c87 := 'Source Name';
  p_Description_8dd82c87 := 'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.';
  p_Type_8dd82c87 := 'String';
  p_Length_8dd82c87 := 500;
  p_AllowsNull_8dd82c87 := TRUE;
  p_IsPrimaryKey_8dd82c87 := FALSE;
  p_IsUniqueKey_8dd82c87 := FALSE;
  p_IsReadOnly_8dd82c87 := TRUE;
  p_IsRequired_8dd82c87 := FALSE;
  p_Sequence_8dd82c87 := 27;
  p_Status_8dd82c87 := 'Active';
  p_IsCustom_8dd82c87 := FALSE;
  p_MetadataSource_8dd82c87 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_8dd82c87, p_IntegrationObjectID := p_IntegrationObjectID_8dd82c87, p_Name := p_Name_8dd82c87, p_DisplayName := p_DisplayName_8dd82c87, p_Description := p_Description_8dd82c87, p_Category := p_Category_8dd82c87, p_Category_Clear := TRUE, p_Type := p_Type_8dd82c87, p_Length := p_Length_8dd82c87, p_Precision := p_Precision_8dd82c87, p_Precision_Clear := TRUE, p_Scale := p_Scale_8dd82c87, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_8dd82c87, p_DefaultValue := p_DefaultValue_8dd82c87, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_8dd82c87, p_IsUniqueKey := p_IsUniqueKey_8dd82c87, p_IsReadOnly := p_IsReadOnly_8dd82c87, p_IsRequired := p_IsRequired_8dd82c87, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_8dd82c87, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_8dd82c87, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_8dd82c87, p_Configuration := p_Configuration_8dd82c87, p_Configuration_Clear := TRUE, p_Status := p_Status_8dd82c87, p_IsCustom := p_IsCustom_8dd82c87, p_MetadataSource := p_MetadataSource_8dd82c87);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_82794b2d UUID;
  p_IntegrationObjectID_82794b2d UUID;
  p_Name_82794b2d VARCHAR(255);
  p_DisplayName_82794b2d VARCHAR(255);
  p_Description_82794b2d TEXT;
  p_Category_82794b2d VARCHAR(100);
  p_Type_82794b2d VARCHAR(100);
  p_Length_82794b2d INTEGER;
  p_Precision_82794b2d INTEGER;
  p_Scale_82794b2d INTEGER;
  p_AllowsNull_82794b2d BOOLEAN;
  p_DefaultValue_82794b2d VARCHAR(255);
  p_IsPrimaryKey_82794b2d BOOLEAN;
  p_IsUniqueKey_82794b2d BOOLEAN;
  p_IsReadOnly_82794b2d BOOLEAN;
  p_IsRequired_82794b2d BOOLEAN;
  p_RelatedIntegrationObjectID_82794b2d UUID;
  p_RelatedIntegrationObjectFieldName_82794b2d VARCHAR(255);
  p_Sequence_82794b2d INTEGER;
  p_Configuration_82794b2d TEXT;
  p_Status_82794b2d VARCHAR(25);
  p_IsCustom_82794b2d BOOLEAN;
  p_MetadataSource_82794b2d VARCHAR(20);
BEGIN
  p_ID_82794b2d := 'D8D8A111-2978-57EF-BACD-733EE23C850F';
  p_IntegrationObjectID_82794b2d := '35593E67-CBB4-4C88-9438-80C1D7F4B2D0';
  p_Name_82794b2d := 'source-orcid';
  p_DisplayName_82794b2d := 'Source Orcid';
  p_Description_82794b2d := 'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.';
  p_Type_82794b2d := 'String';
  p_Length_82794b2d := 19;
  p_AllowsNull_82794b2d := TRUE;
  p_IsPrimaryKey_82794b2d := FALSE;
  p_IsUniqueKey_82794b2d := FALSE;
  p_IsReadOnly_82794b2d := TRUE;
  p_IsRequired_82794b2d := FALSE;
  p_Sequence_82794b2d := 28;
  p_Status_82794b2d := 'Active';
  p_IsCustom_82794b2d := FALSE;
  p_MetadataSource_82794b2d := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_82794b2d, p_IntegrationObjectID := p_IntegrationObjectID_82794b2d, p_Name := p_Name_82794b2d, p_DisplayName := p_DisplayName_82794b2d, p_Description := p_Description_82794b2d, p_Category := p_Category_82794b2d, p_Category_Clear := TRUE, p_Type := p_Type_82794b2d, p_Length := p_Length_82794b2d, p_Precision := p_Precision_82794b2d, p_Precision_Clear := TRUE, p_Scale := p_Scale_82794b2d, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_82794b2d, p_DefaultValue := p_DefaultValue_82794b2d, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_82794b2d, p_IsUniqueKey := p_IsUniqueKey_82794b2d, p_IsReadOnly := p_IsReadOnly_82794b2d, p_IsRequired := p_IsRequired_82794b2d, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_82794b2d, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_82794b2d, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_82794b2d, p_Configuration := p_Configuration_82794b2d, p_Configuration_Clear := TRUE, p_Status := p_Status_82794b2d, p_IsCustom := p_IsCustom_82794b2d, p_MetadataSource := p_MetadataSource_82794b2d);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_b1584103 UUID;
  p_IntegrationObjectID_b1584103 UUID;
  p_Name_b1584103 VARCHAR(255);
  p_DisplayName_b1584103 VARCHAR(255);
  p_Description_b1584103 TEXT;
  p_Category_b1584103 VARCHAR(100);
  p_Type_b1584103 VARCHAR(100);
  p_Length_b1584103 INTEGER;
  p_Precision_b1584103 INTEGER;
  p_Scale_b1584103 INTEGER;
  p_AllowsNull_b1584103 BOOLEAN;
  p_DefaultValue_b1584103 VARCHAR(255);
  p_IsPrimaryKey_b1584103 BOOLEAN;
  p_IsUniqueKey_b1584103 BOOLEAN;
  p_IsReadOnly_b1584103 BOOLEAN;
  p_IsRequired_b1584103 BOOLEAN;
  p_RelatedIntegrationObjectID_b1584103 UUID;
  p_RelatedIntegrationObjectFieldName_b1584103 VARCHAR(255);
  p_Sequence_b1584103 INTEGER;
  p_Configuration_b1584103 TEXT;
  p_Status_b1584103 VARCHAR(25);
  p_IsCustom_b1584103 BOOLEAN;
  p_MetadataSource_b1584103 VARCHAR(20);
BEGIN
  p_ID_b1584103 := '7B9F77B5-7EB6-5DA8-8D3A-F51082EC56CE';
  p_IntegrationObjectID_b1584103 := 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD';
  p_Name_b1584103 := 'funding-title';
  p_DisplayName_b1584103 := 'Funding Title';
  p_Description_b1584103 := 'Title of the grant or award. Lifted from title.title.';
  p_Type_b1584103 := 'String';
  p_Length_b1584103 := 2000;
  p_AllowsNull_b1584103 := TRUE;
  p_IsPrimaryKey_b1584103 := FALSE;
  p_IsUniqueKey_b1584103 := FALSE;
  p_IsReadOnly_b1584103 := TRUE;
  p_IsRequired_b1584103 := FALSE;
  p_Sequence_b1584103 := 19;
  p_Status_b1584103 := 'Active';
  p_IsCustom_b1584103 := FALSE;
  p_MetadataSource_b1584103 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_b1584103, p_IntegrationObjectID := p_IntegrationObjectID_b1584103, p_Name := p_Name_b1584103, p_DisplayName := p_DisplayName_b1584103, p_Description := p_Description_b1584103, p_Category := p_Category_b1584103, p_Category_Clear := TRUE, p_Type := p_Type_b1584103, p_Length := p_Length_b1584103, p_Precision := p_Precision_b1584103, p_Precision_Clear := TRUE, p_Scale := p_Scale_b1584103, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_b1584103, p_DefaultValue := p_DefaultValue_b1584103, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_b1584103, p_IsUniqueKey := p_IsUniqueKey_b1584103, p_IsReadOnly := p_IsReadOnly_b1584103, p_IsRequired := p_IsRequired_b1584103, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_b1584103, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_b1584103, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_b1584103, p_Configuration := p_Configuration_b1584103, p_Configuration_Clear := TRUE, p_Status := p_Status_b1584103, p_IsCustom := p_IsCustom_b1584103, p_MetadataSource := p_MetadataSource_b1584103);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_d3f977fd UUID;
  p_IntegrationObjectID_d3f977fd UUID;
  p_Name_d3f977fd VARCHAR(255);
  p_DisplayName_d3f977fd VARCHAR(255);
  p_Description_d3f977fd TEXT;
  p_Category_d3f977fd VARCHAR(100);
  p_Type_d3f977fd VARCHAR(100);
  p_Length_d3f977fd INTEGER;
  p_Precision_d3f977fd INTEGER;
  p_Scale_d3f977fd INTEGER;
  p_AllowsNull_d3f977fd BOOLEAN;
  p_DefaultValue_d3f977fd VARCHAR(255);
  p_IsPrimaryKey_d3f977fd BOOLEAN;
  p_IsUniqueKey_d3f977fd BOOLEAN;
  p_IsReadOnly_d3f977fd BOOLEAN;
  p_IsRequired_d3f977fd BOOLEAN;
  p_RelatedIntegrationObjectID_d3f977fd UUID;
  p_RelatedIntegrationObjectFieldName_d3f977fd VARCHAR(255);
  p_Sequence_d3f977fd INTEGER;
  p_Configuration_d3f977fd TEXT;
  p_Status_d3f977fd VARCHAR(25);
  p_IsCustom_d3f977fd BOOLEAN;
  p_MetadataSource_d3f977fd VARCHAR(20);
BEGIN
  p_ID_d3f977fd := 'ECC386F3-9962-5AEE-80F9-036B18946A37';
  p_IntegrationObjectID_d3f977fd := 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD';
  p_Name_d3f977fd := 'translated-title';
  p_DisplayName_d3f977fd := 'Translated Title';
  p_Description_d3f977fd := 'Translated title. Lifted from title.translated-title.';
  p_Type_d3f977fd := 'String';
  p_Length_d3f977fd := 2000;
  p_AllowsNull_d3f977fd := TRUE;
  p_IsPrimaryKey_d3f977fd := FALSE;
  p_IsUniqueKey_d3f977fd := FALSE;
  p_IsReadOnly_d3f977fd := TRUE;
  p_IsRequired_d3f977fd := FALSE;
  p_Sequence_d3f977fd := 20;
  p_Status_d3f977fd := 'Active';
  p_IsCustom_d3f977fd := FALSE;
  p_MetadataSource_d3f977fd := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_d3f977fd, p_IntegrationObjectID := p_IntegrationObjectID_d3f977fd, p_Name := p_Name_d3f977fd, p_DisplayName := p_DisplayName_d3f977fd, p_Description := p_Description_d3f977fd, p_Category := p_Category_d3f977fd, p_Category_Clear := TRUE, p_Type := p_Type_d3f977fd, p_Length := p_Length_d3f977fd, p_Precision := p_Precision_d3f977fd, p_Precision_Clear := TRUE, p_Scale := p_Scale_d3f977fd, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_d3f977fd, p_DefaultValue := p_DefaultValue_d3f977fd, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_d3f977fd, p_IsUniqueKey := p_IsUniqueKey_d3f977fd, p_IsReadOnly := p_IsReadOnly_d3f977fd, p_IsRequired := p_IsRequired_d3f977fd, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_d3f977fd, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_d3f977fd, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_d3f977fd, p_Configuration := p_Configuration_d3f977fd, p_Configuration_Clear := TRUE, p_Status := p_Status_d3f977fd, p_IsCustom := p_IsCustom_d3f977fd, p_MetadataSource := p_MetadataSource_d3f977fd);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_cbae4f7e UUID;
  p_IntegrationObjectID_cbae4f7e UUID;
  p_Name_cbae4f7e VARCHAR(255);
  p_DisplayName_cbae4f7e VARCHAR(255);
  p_Description_cbae4f7e TEXT;
  p_Category_cbae4f7e VARCHAR(100);
  p_Type_cbae4f7e VARCHAR(100);
  p_Length_cbae4f7e INTEGER;
  p_Precision_cbae4f7e INTEGER;
  p_Scale_cbae4f7e INTEGER;
  p_AllowsNull_cbae4f7e BOOLEAN;
  p_DefaultValue_cbae4f7e VARCHAR(255);
  p_IsPrimaryKey_cbae4f7e BOOLEAN;
  p_IsUniqueKey_cbae4f7e BOOLEAN;
  p_IsReadOnly_cbae4f7e BOOLEAN;
  p_IsRequired_cbae4f7e BOOLEAN;
  p_RelatedIntegrationObjectID_cbae4f7e UUID;
  p_RelatedIntegrationObjectFieldName_cbae4f7e VARCHAR(255);
  p_Sequence_cbae4f7e INTEGER;
  p_Configuration_cbae4f7e TEXT;
  p_Status_cbae4f7e VARCHAR(25);
  p_IsCustom_cbae4f7e BOOLEAN;
  p_MetadataSource_cbae4f7e VARCHAR(20);
BEGIN
  p_ID_cbae4f7e := 'DECDD1BC-8A00-5B86-8830-39FD44A7CB70';
  p_IntegrationObjectID_cbae4f7e := 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD';
  p_Name_cbae4f7e := 'amount-value';
  p_DisplayName_cbae4f7e := 'Amount Value';
  p_Description_cbae4f7e := 'Award amount. Only the funding detail endpoint carries it; null when derived from the record summary.';
  p_Type_cbae4f7e := 'String';
  p_Length_cbae4f7e := 50;
  p_AllowsNull_cbae4f7e := TRUE;
  p_IsPrimaryKey_cbae4f7e := FALSE;
  p_IsUniqueKey_cbae4f7e := FALSE;
  p_IsReadOnly_cbae4f7e := TRUE;
  p_IsRequired_cbae4f7e := FALSE;
  p_Sequence_cbae4f7e := 21;
  p_Status_cbae4f7e := 'Active';
  p_IsCustom_cbae4f7e := FALSE;
  p_MetadataSource_cbae4f7e := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_cbae4f7e, p_IntegrationObjectID := p_IntegrationObjectID_cbae4f7e, p_Name := p_Name_cbae4f7e, p_DisplayName := p_DisplayName_cbae4f7e, p_Description := p_Description_cbae4f7e, p_Category := p_Category_cbae4f7e, p_Category_Clear := TRUE, p_Type := p_Type_cbae4f7e, p_Length := p_Length_cbae4f7e, p_Precision := p_Precision_cbae4f7e, p_Precision_Clear := TRUE, p_Scale := p_Scale_cbae4f7e, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_cbae4f7e, p_DefaultValue := p_DefaultValue_cbae4f7e, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_cbae4f7e, p_IsUniqueKey := p_IsUniqueKey_cbae4f7e, p_IsReadOnly := p_IsReadOnly_cbae4f7e, p_IsRequired := p_IsRequired_cbae4f7e, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_cbae4f7e, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_cbae4f7e, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_cbae4f7e, p_Configuration := p_Configuration_cbae4f7e, p_Configuration_Clear := TRUE, p_Status := p_Status_cbae4f7e, p_IsCustom := p_IsCustom_cbae4f7e, p_MetadataSource := p_MetadataSource_cbae4f7e);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_822cc547 UUID;
  p_IntegrationObjectID_822cc547 UUID;
  p_Name_822cc547 VARCHAR(255);
  p_DisplayName_822cc547 VARCHAR(255);
  p_Description_822cc547 TEXT;
  p_Category_822cc547 VARCHAR(100);
  p_Type_822cc547 VARCHAR(100);
  p_Length_822cc547 INTEGER;
  p_Precision_822cc547 INTEGER;
  p_Scale_822cc547 INTEGER;
  p_AllowsNull_822cc547 BOOLEAN;
  p_DefaultValue_822cc547 VARCHAR(255);
  p_IsPrimaryKey_822cc547 BOOLEAN;
  p_IsUniqueKey_822cc547 BOOLEAN;
  p_IsReadOnly_822cc547 BOOLEAN;
  p_IsRequired_822cc547 BOOLEAN;
  p_RelatedIntegrationObjectID_822cc547 UUID;
  p_RelatedIntegrationObjectFieldName_822cc547 VARCHAR(255);
  p_Sequence_822cc547 INTEGER;
  p_Configuration_822cc547 TEXT;
  p_Status_822cc547 VARCHAR(25);
  p_IsCustom_822cc547 BOOLEAN;
  p_MetadataSource_822cc547 VARCHAR(20);
BEGIN
  p_ID_822cc547 := 'DEA5033C-9955-5F01-B51C-E1942A888C76';
  p_IntegrationObjectID_822cc547 := 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD';
  p_Name_822cc547 := 'amount-currency';
  p_DisplayName_822cc547 := 'Amount Currency';
  p_Description_822cc547 := 'ISO currency code of the award amount; null when derived from the record summary.';
  p_Type_822cc547 := 'String';
  p_Length_822cc547 := 10;
  p_AllowsNull_822cc547 := TRUE;
  p_IsPrimaryKey_822cc547 := FALSE;
  p_IsUniqueKey_822cc547 := FALSE;
  p_IsReadOnly_822cc547 := TRUE;
  p_IsRequired_822cc547 := FALSE;
  p_Sequence_822cc547 := 22;
  p_Status_822cc547 := 'Active';
  p_IsCustom_822cc547 := FALSE;
  p_MetadataSource_822cc547 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_822cc547, p_IntegrationObjectID := p_IntegrationObjectID_822cc547, p_Name := p_Name_822cc547, p_DisplayName := p_DisplayName_822cc547, p_Description := p_Description_822cc547, p_Category := p_Category_822cc547, p_Category_Clear := TRUE, p_Type := p_Type_822cc547, p_Length := p_Length_822cc547, p_Precision := p_Precision_822cc547, p_Precision_Clear := TRUE, p_Scale := p_Scale_822cc547, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_822cc547, p_DefaultValue := p_DefaultValue_822cc547, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_822cc547, p_IsUniqueKey := p_IsUniqueKey_822cc547, p_IsReadOnly := p_IsReadOnly_822cc547, p_IsRequired := p_IsRequired_822cc547, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_822cc547, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_822cc547, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_822cc547, p_Configuration := p_Configuration_822cc547, p_Configuration_Clear := TRUE, p_Status := p_Status_822cc547, p_IsCustom := p_IsCustom_822cc547, p_MetadataSource := p_MetadataSource_822cc547);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_9be77790 UUID;
  p_IntegrationObjectID_9be77790 UUID;
  p_Name_9be77790 VARCHAR(255);
  p_DisplayName_9be77790 VARCHAR(255);
  p_Description_9be77790 TEXT;
  p_Category_9be77790 VARCHAR(100);
  p_Type_9be77790 VARCHAR(100);
  p_Length_9be77790 INTEGER;
  p_Precision_9be77790 INTEGER;
  p_Scale_9be77790 INTEGER;
  p_AllowsNull_9be77790 BOOLEAN;
  p_DefaultValue_9be77790 VARCHAR(255);
  p_IsPrimaryKey_9be77790 BOOLEAN;
  p_IsUniqueKey_9be77790 BOOLEAN;
  p_IsReadOnly_9be77790 BOOLEAN;
  p_IsRequired_9be77790 BOOLEAN;
  p_RelatedIntegrationObjectID_9be77790 UUID;
  p_RelatedIntegrationObjectFieldName_9be77790 VARCHAR(255);
  p_Sequence_9be77790 INTEGER;
  p_Configuration_9be77790 TEXT;
  p_Status_9be77790 VARCHAR(25);
  p_IsCustom_9be77790 BOOLEAN;
  p_MetadataSource_9be77790 VARCHAR(20);
BEGIN
  p_ID_9be77790 := '9605F469-E896-5943-B42C-14CA5E1E7712';
  p_IntegrationObjectID_9be77790 := 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD';
  p_Name_9be77790 := 'start-year';
  p_DisplayName_9be77790 := 'Start Year';
  p_Description_9be77790 := 'Year of the grant start date; ORCID dates are partial, so month/day may be absent.';
  p_Type_9be77790 := 'Integer';
  p_AllowsNull_9be77790 := TRUE;
  p_IsPrimaryKey_9be77790 := FALSE;
  p_IsUniqueKey_9be77790 := FALSE;
  p_IsReadOnly_9be77790 := TRUE;
  p_IsRequired_9be77790 := FALSE;
  p_Sequence_9be77790 := 23;
  p_Status_9be77790 := 'Active';
  p_IsCustom_9be77790 := FALSE;
  p_MetadataSource_9be77790 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_9be77790, p_IntegrationObjectID := p_IntegrationObjectID_9be77790, p_Name := p_Name_9be77790, p_DisplayName := p_DisplayName_9be77790, p_Description := p_Description_9be77790, p_Category := p_Category_9be77790, p_Category_Clear := TRUE, p_Type := p_Type_9be77790, p_Length := p_Length_9be77790, p_Length_Clear := TRUE, p_Precision := p_Precision_9be77790, p_Precision_Clear := TRUE, p_Scale := p_Scale_9be77790, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_9be77790, p_DefaultValue := p_DefaultValue_9be77790, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_9be77790, p_IsUniqueKey := p_IsUniqueKey_9be77790, p_IsReadOnly := p_IsReadOnly_9be77790, p_IsRequired := p_IsRequired_9be77790, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_9be77790, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_9be77790, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_9be77790, p_Configuration := p_Configuration_9be77790, p_Configuration_Clear := TRUE, p_Status := p_Status_9be77790, p_IsCustom := p_IsCustom_9be77790, p_MetadataSource := p_MetadataSource_9be77790);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_9e190446 UUID;
  p_IntegrationObjectID_9e190446 UUID;
  p_Name_9e190446 VARCHAR(255);
  p_DisplayName_9e190446 VARCHAR(255);
  p_Description_9e190446 TEXT;
  p_Category_9e190446 VARCHAR(100);
  p_Type_9e190446 VARCHAR(100);
  p_Length_9e190446 INTEGER;
  p_Precision_9e190446 INTEGER;
  p_Scale_9e190446 INTEGER;
  p_AllowsNull_9e190446 BOOLEAN;
  p_DefaultValue_9e190446 VARCHAR(255);
  p_IsPrimaryKey_9e190446 BOOLEAN;
  p_IsUniqueKey_9e190446 BOOLEAN;
  p_IsReadOnly_9e190446 BOOLEAN;
  p_IsRequired_9e190446 BOOLEAN;
  p_RelatedIntegrationObjectID_9e190446 UUID;
  p_RelatedIntegrationObjectFieldName_9e190446 VARCHAR(255);
  p_Sequence_9e190446 INTEGER;
  p_Configuration_9e190446 TEXT;
  p_Status_9e190446 VARCHAR(25);
  p_IsCustom_9e190446 BOOLEAN;
  p_MetadataSource_9e190446 VARCHAR(20);
BEGIN
  p_ID_9e190446 := '62A86041-51F0-52B1-BF32-1E5C1DBFA7E1';
  p_IntegrationObjectID_9e190446 := 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD';
  p_Name_9e190446 := 'start-month';
  p_DisplayName_9e190446 := 'Start Month';
  p_Description_9e190446 := 'Month (1-12) of the grant start date, when given.';
  p_Type_9e190446 := 'Integer';
  p_AllowsNull_9e190446 := TRUE;
  p_IsPrimaryKey_9e190446 := FALSE;
  p_IsUniqueKey_9e190446 := FALSE;
  p_IsReadOnly_9e190446 := TRUE;
  p_IsRequired_9e190446 := FALSE;
  p_Sequence_9e190446 := 24;
  p_Status_9e190446 := 'Active';
  p_IsCustom_9e190446 := FALSE;
  p_MetadataSource_9e190446 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_9e190446, p_IntegrationObjectID := p_IntegrationObjectID_9e190446, p_Name := p_Name_9e190446, p_DisplayName := p_DisplayName_9e190446, p_Description := p_Description_9e190446, p_Category := p_Category_9e190446, p_Category_Clear := TRUE, p_Type := p_Type_9e190446, p_Length := p_Length_9e190446, p_Length_Clear := TRUE, p_Precision := p_Precision_9e190446, p_Precision_Clear := TRUE, p_Scale := p_Scale_9e190446, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_9e190446, p_DefaultValue := p_DefaultValue_9e190446, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_9e190446, p_IsUniqueKey := p_IsUniqueKey_9e190446, p_IsReadOnly := p_IsReadOnly_9e190446, p_IsRequired := p_IsRequired_9e190446, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_9e190446, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_9e190446, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_9e190446, p_Configuration := p_Configuration_9e190446, p_Configuration_Clear := TRUE, p_Status := p_Status_9e190446, p_IsCustom := p_IsCustom_9e190446, p_MetadataSource := p_MetadataSource_9e190446);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_52eef396 UUID;
  p_IntegrationObjectID_52eef396 UUID;
  p_Name_52eef396 VARCHAR(255);
  p_DisplayName_52eef396 VARCHAR(255);
  p_Description_52eef396 TEXT;
  p_Category_52eef396 VARCHAR(100);
  p_Type_52eef396 VARCHAR(100);
  p_Length_52eef396 INTEGER;
  p_Precision_52eef396 INTEGER;
  p_Scale_52eef396 INTEGER;
  p_AllowsNull_52eef396 BOOLEAN;
  p_DefaultValue_52eef396 VARCHAR(255);
  p_IsPrimaryKey_52eef396 BOOLEAN;
  p_IsUniqueKey_52eef396 BOOLEAN;
  p_IsReadOnly_52eef396 BOOLEAN;
  p_IsRequired_52eef396 BOOLEAN;
  p_RelatedIntegrationObjectID_52eef396 UUID;
  p_RelatedIntegrationObjectFieldName_52eef396 VARCHAR(255);
  p_Sequence_52eef396 INTEGER;
  p_Configuration_52eef396 TEXT;
  p_Status_52eef396 VARCHAR(25);
  p_IsCustom_52eef396 BOOLEAN;
  p_MetadataSource_52eef396 VARCHAR(20);
BEGIN
  p_ID_52eef396 := '0DADC8E5-5763-5541-A3F4-37EDB8613DED';
  p_IntegrationObjectID_52eef396 := 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD';
  p_Name_52eef396 := 'start-day';
  p_DisplayName_52eef396 := 'Start Day';
  p_Description_52eef396 := 'Day of month of the grant start date, when given.';
  p_Type_52eef396 := 'Integer';
  p_AllowsNull_52eef396 := TRUE;
  p_IsPrimaryKey_52eef396 := FALSE;
  p_IsUniqueKey_52eef396 := FALSE;
  p_IsReadOnly_52eef396 := TRUE;
  p_IsRequired_52eef396 := FALSE;
  p_Sequence_52eef396 := 25;
  p_Status_52eef396 := 'Active';
  p_IsCustom_52eef396 := FALSE;
  p_MetadataSource_52eef396 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_52eef396, p_IntegrationObjectID := p_IntegrationObjectID_52eef396, p_Name := p_Name_52eef396, p_DisplayName := p_DisplayName_52eef396, p_Description := p_Description_52eef396, p_Category := p_Category_52eef396, p_Category_Clear := TRUE, p_Type := p_Type_52eef396, p_Length := p_Length_52eef396, p_Length_Clear := TRUE, p_Precision := p_Precision_52eef396, p_Precision_Clear := TRUE, p_Scale := p_Scale_52eef396, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_52eef396, p_DefaultValue := p_DefaultValue_52eef396, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_52eef396, p_IsUniqueKey := p_IsUniqueKey_52eef396, p_IsReadOnly := p_IsReadOnly_52eef396, p_IsRequired := p_IsRequired_52eef396, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_52eef396, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_52eef396, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_52eef396, p_Configuration := p_Configuration_52eef396, p_Configuration_Clear := TRUE, p_Status := p_Status_52eef396, p_IsCustom := p_IsCustom_52eef396, p_MetadataSource := p_MetadataSource_52eef396);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_b11afb2e UUID;
  p_IntegrationObjectID_b11afb2e UUID;
  p_Name_b11afb2e VARCHAR(255);
  p_DisplayName_b11afb2e VARCHAR(255);
  p_Description_b11afb2e TEXT;
  p_Category_b11afb2e VARCHAR(100);
  p_Type_b11afb2e VARCHAR(100);
  p_Length_b11afb2e INTEGER;
  p_Precision_b11afb2e INTEGER;
  p_Scale_b11afb2e INTEGER;
  p_AllowsNull_b11afb2e BOOLEAN;
  p_DefaultValue_b11afb2e VARCHAR(255);
  p_IsPrimaryKey_b11afb2e BOOLEAN;
  p_IsUniqueKey_b11afb2e BOOLEAN;
  p_IsReadOnly_b11afb2e BOOLEAN;
  p_IsRequired_b11afb2e BOOLEAN;
  p_RelatedIntegrationObjectID_b11afb2e UUID;
  p_RelatedIntegrationObjectFieldName_b11afb2e VARCHAR(255);
  p_Sequence_b11afb2e INTEGER;
  p_Configuration_b11afb2e TEXT;
  p_Status_b11afb2e VARCHAR(25);
  p_IsCustom_b11afb2e BOOLEAN;
  p_MetadataSource_b11afb2e VARCHAR(20);
BEGIN
  p_ID_b11afb2e := '693AD5B3-1169-57C9-B2D7-2493AF9E0341';
  p_IntegrationObjectID_b11afb2e := 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD';
  p_Name_b11afb2e := 'end-year';
  p_DisplayName_b11afb2e := 'End Year';
  p_Description_b11afb2e := 'Year of the grant end date; ORCID dates are partial, so month/day may be absent.';
  p_Type_b11afb2e := 'Integer';
  p_AllowsNull_b11afb2e := TRUE;
  p_IsPrimaryKey_b11afb2e := FALSE;
  p_IsUniqueKey_b11afb2e := FALSE;
  p_IsReadOnly_b11afb2e := TRUE;
  p_IsRequired_b11afb2e := FALSE;
  p_Sequence_b11afb2e := 26;
  p_Status_b11afb2e := 'Active';
  p_IsCustom_b11afb2e := FALSE;
  p_MetadataSource_b11afb2e := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_b11afb2e, p_IntegrationObjectID := p_IntegrationObjectID_b11afb2e, p_Name := p_Name_b11afb2e, p_DisplayName := p_DisplayName_b11afb2e, p_Description := p_Description_b11afb2e, p_Category := p_Category_b11afb2e, p_Category_Clear := TRUE, p_Type := p_Type_b11afb2e, p_Length := p_Length_b11afb2e, p_Length_Clear := TRUE, p_Precision := p_Precision_b11afb2e, p_Precision_Clear := TRUE, p_Scale := p_Scale_b11afb2e, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_b11afb2e, p_DefaultValue := p_DefaultValue_b11afb2e, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_b11afb2e, p_IsUniqueKey := p_IsUniqueKey_b11afb2e, p_IsReadOnly := p_IsReadOnly_b11afb2e, p_IsRequired := p_IsRequired_b11afb2e, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_b11afb2e, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_b11afb2e, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_b11afb2e, p_Configuration := p_Configuration_b11afb2e, p_Configuration_Clear := TRUE, p_Status := p_Status_b11afb2e, p_IsCustom := p_IsCustom_b11afb2e, p_MetadataSource := p_MetadataSource_b11afb2e);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_dc3d9883 UUID;
  p_IntegrationObjectID_dc3d9883 UUID;
  p_Name_dc3d9883 VARCHAR(255);
  p_DisplayName_dc3d9883 VARCHAR(255);
  p_Description_dc3d9883 TEXT;
  p_Category_dc3d9883 VARCHAR(100);
  p_Type_dc3d9883 VARCHAR(100);
  p_Length_dc3d9883 INTEGER;
  p_Precision_dc3d9883 INTEGER;
  p_Scale_dc3d9883 INTEGER;
  p_AllowsNull_dc3d9883 BOOLEAN;
  p_DefaultValue_dc3d9883 VARCHAR(255);
  p_IsPrimaryKey_dc3d9883 BOOLEAN;
  p_IsUniqueKey_dc3d9883 BOOLEAN;
  p_IsReadOnly_dc3d9883 BOOLEAN;
  p_IsRequired_dc3d9883 BOOLEAN;
  p_RelatedIntegrationObjectID_dc3d9883 UUID;
  p_RelatedIntegrationObjectFieldName_dc3d9883 VARCHAR(255);
  p_Sequence_dc3d9883 INTEGER;
  p_Configuration_dc3d9883 TEXT;
  p_Status_dc3d9883 VARCHAR(25);
  p_IsCustom_dc3d9883 BOOLEAN;
  p_MetadataSource_dc3d9883 VARCHAR(20);
BEGIN
  p_ID_dc3d9883 := '0478C91B-8B23-5BF0-9631-403F90EFF0A0';
  p_IntegrationObjectID_dc3d9883 := 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD';
  p_Name_dc3d9883 := 'end-month';
  p_DisplayName_dc3d9883 := 'End Month';
  p_Description_dc3d9883 := 'Month (1-12) of the grant end date, when given.';
  p_Type_dc3d9883 := 'Integer';
  p_AllowsNull_dc3d9883 := TRUE;
  p_IsPrimaryKey_dc3d9883 := FALSE;
  p_IsUniqueKey_dc3d9883 := FALSE;
  p_IsReadOnly_dc3d9883 := TRUE;
  p_IsRequired_dc3d9883 := FALSE;
  p_Sequence_dc3d9883 := 27;
  p_Status_dc3d9883 := 'Active';
  p_IsCustom_dc3d9883 := FALSE;
  p_MetadataSource_dc3d9883 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_dc3d9883, p_IntegrationObjectID := p_IntegrationObjectID_dc3d9883, p_Name := p_Name_dc3d9883, p_DisplayName := p_DisplayName_dc3d9883, p_Description := p_Description_dc3d9883, p_Category := p_Category_dc3d9883, p_Category_Clear := TRUE, p_Type := p_Type_dc3d9883, p_Length := p_Length_dc3d9883, p_Length_Clear := TRUE, p_Precision := p_Precision_dc3d9883, p_Precision_Clear := TRUE, p_Scale := p_Scale_dc3d9883, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_dc3d9883, p_DefaultValue := p_DefaultValue_dc3d9883, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_dc3d9883, p_IsUniqueKey := p_IsUniqueKey_dc3d9883, p_IsReadOnly := p_IsReadOnly_dc3d9883, p_IsRequired := p_IsRequired_dc3d9883, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_dc3d9883, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_dc3d9883, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_dc3d9883, p_Configuration := p_Configuration_dc3d9883, p_Configuration_Clear := TRUE, p_Status := p_Status_dc3d9883, p_IsCustom := p_IsCustom_dc3d9883, p_MetadataSource := p_MetadataSource_dc3d9883);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_100e4090 UUID;
  p_IntegrationObjectID_100e4090 UUID;
  p_Name_100e4090 VARCHAR(255);
  p_DisplayName_100e4090 VARCHAR(255);
  p_Description_100e4090 TEXT;
  p_Category_100e4090 VARCHAR(100);
  p_Type_100e4090 VARCHAR(100);
  p_Length_100e4090 INTEGER;
  p_Precision_100e4090 INTEGER;
  p_Scale_100e4090 INTEGER;
  p_AllowsNull_100e4090 BOOLEAN;
  p_DefaultValue_100e4090 VARCHAR(255);
  p_IsPrimaryKey_100e4090 BOOLEAN;
  p_IsUniqueKey_100e4090 BOOLEAN;
  p_IsReadOnly_100e4090 BOOLEAN;
  p_IsRequired_100e4090 BOOLEAN;
  p_RelatedIntegrationObjectID_100e4090 UUID;
  p_RelatedIntegrationObjectFieldName_100e4090 VARCHAR(255);
  p_Sequence_100e4090 INTEGER;
  p_Configuration_100e4090 TEXT;
  p_Status_100e4090 VARCHAR(25);
  p_IsCustom_100e4090 BOOLEAN;
  p_MetadataSource_100e4090 VARCHAR(20);
BEGIN
  p_ID_100e4090 := 'EC8A5B52-D9E8-5637-B469-EE24B5B483AD';
  p_IntegrationObjectID_100e4090 := 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD';
  p_Name_100e4090 := 'end-day';
  p_DisplayName_100e4090 := 'End Day';
  p_Description_100e4090 := 'Day of month of the grant end date, when given.';
  p_Type_100e4090 := 'Integer';
  p_AllowsNull_100e4090 := TRUE;
  p_IsPrimaryKey_100e4090 := FALSE;
  p_IsUniqueKey_100e4090 := FALSE;
  p_IsReadOnly_100e4090 := TRUE;
  p_IsRequired_100e4090 := FALSE;
  p_Sequence_100e4090 := 28;
  p_Status_100e4090 := 'Active';
  p_IsCustom_100e4090 := FALSE;
  p_MetadataSource_100e4090 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_100e4090, p_IntegrationObjectID := p_IntegrationObjectID_100e4090, p_Name := p_Name_100e4090, p_DisplayName := p_DisplayName_100e4090, p_Description := p_Description_100e4090, p_Category := p_Category_100e4090, p_Category_Clear := TRUE, p_Type := p_Type_100e4090, p_Length := p_Length_100e4090, p_Length_Clear := TRUE, p_Precision := p_Precision_100e4090, p_Precision_Clear := TRUE, p_Scale := p_Scale_100e4090, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_100e4090, p_DefaultValue := p_DefaultValue_100e4090, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_100e4090, p_IsUniqueKey := p_IsUniqueKey_100e4090, p_IsReadOnly := p_IsReadOnly_100e4090, p_IsRequired := p_IsRequired_100e4090, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_100e4090, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_100e4090, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_100e4090, p_Configuration := p_Configuration_100e4090, p_Configuration_Clear := TRUE, p_Status := p_Status_100e4090, p_IsCustom := p_IsCustom_100e4090, p_MetadataSource := p_MetadataSource_100e4090);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_8c62342e UUID;
  p_IntegrationObjectID_8c62342e UUID;
  p_Name_8c62342e VARCHAR(255);
  p_DisplayName_8c62342e VARCHAR(255);
  p_Description_8c62342e TEXT;
  p_Category_8c62342e VARCHAR(100);
  p_Type_8c62342e VARCHAR(100);
  p_Length_8c62342e INTEGER;
  p_Precision_8c62342e INTEGER;
  p_Scale_8c62342e INTEGER;
  p_AllowsNull_8c62342e BOOLEAN;
  p_DefaultValue_8c62342e VARCHAR(255);
  p_IsPrimaryKey_8c62342e BOOLEAN;
  p_IsUniqueKey_8c62342e BOOLEAN;
  p_IsReadOnly_8c62342e BOOLEAN;
  p_IsRequired_8c62342e BOOLEAN;
  p_RelatedIntegrationObjectID_8c62342e UUID;
  p_RelatedIntegrationObjectFieldName_8c62342e VARCHAR(255);
  p_Sequence_8c62342e INTEGER;
  p_Configuration_8c62342e TEXT;
  p_Status_8c62342e VARCHAR(25);
  p_IsCustom_8c62342e BOOLEAN;
  p_MetadataSource_8c62342e VARCHAR(20);
BEGIN
  p_ID_8c62342e := '17416E35-8C4D-5BA9-92C1-F8A4E49CCDBD';
  p_IntegrationObjectID_8c62342e := 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD';
  p_Name_8c62342e := 'organization-name';
  p_DisplayName_8c62342e := 'Organization Name';
  p_Description_8c62342e := 'Name of the funding organization. Lifted from organization.name.';
  p_Type_8c62342e := 'String';
  p_Length_8c62342e := 1000;
  p_AllowsNull_8c62342e := TRUE;
  p_IsPrimaryKey_8c62342e := FALSE;
  p_IsUniqueKey_8c62342e := FALSE;
  p_IsReadOnly_8c62342e := TRUE;
  p_IsRequired_8c62342e := FALSE;
  p_Sequence_8c62342e := 29;
  p_Status_8c62342e := 'Active';
  p_IsCustom_8c62342e := FALSE;
  p_MetadataSource_8c62342e := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_8c62342e, p_IntegrationObjectID := p_IntegrationObjectID_8c62342e, p_Name := p_Name_8c62342e, p_DisplayName := p_DisplayName_8c62342e, p_Description := p_Description_8c62342e, p_Category := p_Category_8c62342e, p_Category_Clear := TRUE, p_Type := p_Type_8c62342e, p_Length := p_Length_8c62342e, p_Precision := p_Precision_8c62342e, p_Precision_Clear := TRUE, p_Scale := p_Scale_8c62342e, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_8c62342e, p_DefaultValue := p_DefaultValue_8c62342e, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_8c62342e, p_IsUniqueKey := p_IsUniqueKey_8c62342e, p_IsReadOnly := p_IsReadOnly_8c62342e, p_IsRequired := p_IsRequired_8c62342e, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_8c62342e, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_8c62342e, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_8c62342e, p_Configuration := p_Configuration_8c62342e, p_Configuration_Clear := TRUE, p_Status := p_Status_8c62342e, p_IsCustom := p_IsCustom_8c62342e, p_MetadataSource := p_MetadataSource_8c62342e);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_2c686319 UUID;
  p_IntegrationObjectID_2c686319 UUID;
  p_Name_2c686319 VARCHAR(255);
  p_DisplayName_2c686319 VARCHAR(255);
  p_Description_2c686319 TEXT;
  p_Category_2c686319 VARCHAR(100);
  p_Type_2c686319 VARCHAR(100);
  p_Length_2c686319 INTEGER;
  p_Precision_2c686319 INTEGER;
  p_Scale_2c686319 INTEGER;
  p_AllowsNull_2c686319 BOOLEAN;
  p_DefaultValue_2c686319 VARCHAR(255);
  p_IsPrimaryKey_2c686319 BOOLEAN;
  p_IsUniqueKey_2c686319 BOOLEAN;
  p_IsReadOnly_2c686319 BOOLEAN;
  p_IsRequired_2c686319 BOOLEAN;
  p_RelatedIntegrationObjectID_2c686319 UUID;
  p_RelatedIntegrationObjectFieldName_2c686319 VARCHAR(255);
  p_Sequence_2c686319 INTEGER;
  p_Configuration_2c686319 TEXT;
  p_Status_2c686319 VARCHAR(25);
  p_IsCustom_2c686319 BOOLEAN;
  p_MetadataSource_2c686319 VARCHAR(20);
BEGIN
  p_ID_2c686319 := '4ECB1C98-9AFB-5C2B-9DC4-CBF6C9348625';
  p_IntegrationObjectID_2c686319 := 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD';
  p_Name_2c686319 := 'organization-city';
  p_DisplayName_2c686319 := 'Organization City';
  p_Description_2c686319 := 'City of the funding organization. Lifted from organization.address.city.';
  p_Type_2c686319 := 'String';
  p_Length_2c686319 := 255;
  p_AllowsNull_2c686319 := TRUE;
  p_IsPrimaryKey_2c686319 := FALSE;
  p_IsUniqueKey_2c686319 := FALSE;
  p_IsReadOnly_2c686319 := TRUE;
  p_IsRequired_2c686319 := FALSE;
  p_Sequence_2c686319 := 30;
  p_Status_2c686319 := 'Active';
  p_IsCustom_2c686319 := FALSE;
  p_MetadataSource_2c686319 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_2c686319, p_IntegrationObjectID := p_IntegrationObjectID_2c686319, p_Name := p_Name_2c686319, p_DisplayName := p_DisplayName_2c686319, p_Description := p_Description_2c686319, p_Category := p_Category_2c686319, p_Category_Clear := TRUE, p_Type := p_Type_2c686319, p_Length := p_Length_2c686319, p_Precision := p_Precision_2c686319, p_Precision_Clear := TRUE, p_Scale := p_Scale_2c686319, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_2c686319, p_DefaultValue := p_DefaultValue_2c686319, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_2c686319, p_IsUniqueKey := p_IsUniqueKey_2c686319, p_IsReadOnly := p_IsReadOnly_2c686319, p_IsRequired := p_IsRequired_2c686319, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_2c686319, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_2c686319, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_2c686319, p_Configuration := p_Configuration_2c686319, p_Configuration_Clear := TRUE, p_Status := p_Status_2c686319, p_IsCustom := p_IsCustom_2c686319, p_MetadataSource := p_MetadataSource_2c686319);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_551abeda UUID;
  p_IntegrationObjectID_551abeda UUID;
  p_Name_551abeda VARCHAR(255);
  p_DisplayName_551abeda VARCHAR(255);
  p_Description_551abeda TEXT;
  p_Category_551abeda VARCHAR(100);
  p_Type_551abeda VARCHAR(100);
  p_Length_551abeda INTEGER;
  p_Precision_551abeda INTEGER;
  p_Scale_551abeda INTEGER;
  p_AllowsNull_551abeda BOOLEAN;
  p_DefaultValue_551abeda VARCHAR(255);
  p_IsPrimaryKey_551abeda BOOLEAN;
  p_IsUniqueKey_551abeda BOOLEAN;
  p_IsReadOnly_551abeda BOOLEAN;
  p_IsRequired_551abeda BOOLEAN;
  p_RelatedIntegrationObjectID_551abeda UUID;
  p_RelatedIntegrationObjectFieldName_551abeda VARCHAR(255);
  p_Sequence_551abeda INTEGER;
  p_Configuration_551abeda TEXT;
  p_Status_551abeda VARCHAR(25);
  p_IsCustom_551abeda BOOLEAN;
  p_MetadataSource_551abeda VARCHAR(20);
BEGIN
  p_ID_551abeda := 'AAC12F96-9AEA-5C8D-80A5-FF50ECBC642F';
  p_IntegrationObjectID_551abeda := 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD';
  p_Name_551abeda := 'organization-region';
  p_DisplayName_551abeda := 'Organization Region';
  p_Description_551abeda := 'Region/state of the funding organization. Lifted from organization.address.region.';
  p_Type_551abeda := 'String';
  p_Length_551abeda := 255;
  p_AllowsNull_551abeda := TRUE;
  p_IsPrimaryKey_551abeda := FALSE;
  p_IsUniqueKey_551abeda := FALSE;
  p_IsReadOnly_551abeda := TRUE;
  p_IsRequired_551abeda := FALSE;
  p_Sequence_551abeda := 31;
  p_Status_551abeda := 'Active';
  p_IsCustom_551abeda := FALSE;
  p_MetadataSource_551abeda := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_551abeda, p_IntegrationObjectID := p_IntegrationObjectID_551abeda, p_Name := p_Name_551abeda, p_DisplayName := p_DisplayName_551abeda, p_Description := p_Description_551abeda, p_Category := p_Category_551abeda, p_Category_Clear := TRUE, p_Type := p_Type_551abeda, p_Length := p_Length_551abeda, p_Precision := p_Precision_551abeda, p_Precision_Clear := TRUE, p_Scale := p_Scale_551abeda, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_551abeda, p_DefaultValue := p_DefaultValue_551abeda, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_551abeda, p_IsUniqueKey := p_IsUniqueKey_551abeda, p_IsReadOnly := p_IsReadOnly_551abeda, p_IsRequired := p_IsRequired_551abeda, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_551abeda, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_551abeda, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_551abeda, p_Configuration := p_Configuration_551abeda, p_Configuration_Clear := TRUE, p_Status := p_Status_551abeda, p_IsCustom := p_IsCustom_551abeda, p_MetadataSource := p_MetadataSource_551abeda);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_0f04f2ac UUID;
  p_IntegrationObjectID_0f04f2ac UUID;
  p_Name_0f04f2ac VARCHAR(255);
  p_DisplayName_0f04f2ac VARCHAR(255);
  p_Description_0f04f2ac TEXT;
  p_Category_0f04f2ac VARCHAR(100);
  p_Type_0f04f2ac VARCHAR(100);
  p_Length_0f04f2ac INTEGER;
  p_Precision_0f04f2ac INTEGER;
  p_Scale_0f04f2ac INTEGER;
  p_AllowsNull_0f04f2ac BOOLEAN;
  p_DefaultValue_0f04f2ac VARCHAR(255);
  p_IsPrimaryKey_0f04f2ac BOOLEAN;
  p_IsUniqueKey_0f04f2ac BOOLEAN;
  p_IsReadOnly_0f04f2ac BOOLEAN;
  p_IsRequired_0f04f2ac BOOLEAN;
  p_RelatedIntegrationObjectID_0f04f2ac UUID;
  p_RelatedIntegrationObjectFieldName_0f04f2ac VARCHAR(255);
  p_Sequence_0f04f2ac INTEGER;
  p_Configuration_0f04f2ac TEXT;
  p_Status_0f04f2ac VARCHAR(25);
  p_IsCustom_0f04f2ac BOOLEAN;
  p_MetadataSource_0f04f2ac VARCHAR(20);
BEGIN
  p_ID_0f04f2ac := '3D0FC80D-14D8-5B7D-A145-FCB1795980DD';
  p_IntegrationObjectID_0f04f2ac := 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD';
  p_Name_0f04f2ac := 'organization-country';
  p_DisplayName_0f04f2ac := 'Organization Country';
  p_Description_0f04f2ac := 'ISO country code of the funding organization. Lifted from organization.address.country.';
  p_Type_0f04f2ac := 'String';
  p_Length_0f04f2ac := 50;
  p_AllowsNull_0f04f2ac := TRUE;
  p_IsPrimaryKey_0f04f2ac := FALSE;
  p_IsUniqueKey_0f04f2ac := FALSE;
  p_IsReadOnly_0f04f2ac := TRUE;
  p_IsRequired_0f04f2ac := FALSE;
  p_Sequence_0f04f2ac := 32;
  p_Status_0f04f2ac := 'Active';
  p_IsCustom_0f04f2ac := FALSE;
  p_MetadataSource_0f04f2ac := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_0f04f2ac, p_IntegrationObjectID := p_IntegrationObjectID_0f04f2ac, p_Name := p_Name_0f04f2ac, p_DisplayName := p_DisplayName_0f04f2ac, p_Description := p_Description_0f04f2ac, p_Category := p_Category_0f04f2ac, p_Category_Clear := TRUE, p_Type := p_Type_0f04f2ac, p_Length := p_Length_0f04f2ac, p_Precision := p_Precision_0f04f2ac, p_Precision_Clear := TRUE, p_Scale := p_Scale_0f04f2ac, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_0f04f2ac, p_DefaultValue := p_DefaultValue_0f04f2ac, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_0f04f2ac, p_IsUniqueKey := p_IsUniqueKey_0f04f2ac, p_IsReadOnly := p_IsReadOnly_0f04f2ac, p_IsRequired := p_IsRequired_0f04f2ac, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_0f04f2ac, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_0f04f2ac, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_0f04f2ac, p_Configuration := p_Configuration_0f04f2ac, p_Configuration_Clear := TRUE, p_Status := p_Status_0f04f2ac, p_IsCustom := p_IsCustom_0f04f2ac, p_MetadataSource := p_MetadataSource_0f04f2ac);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_91f9aa01 UUID;
  p_IntegrationObjectID_91f9aa01 UUID;
  p_Name_91f9aa01 VARCHAR(255);
  p_DisplayName_91f9aa01 VARCHAR(255);
  p_Description_91f9aa01 TEXT;
  p_Category_91f9aa01 VARCHAR(100);
  p_Type_91f9aa01 VARCHAR(100);
  p_Length_91f9aa01 INTEGER;
  p_Precision_91f9aa01 INTEGER;
  p_Scale_91f9aa01 INTEGER;
  p_AllowsNull_91f9aa01 BOOLEAN;
  p_DefaultValue_91f9aa01 VARCHAR(255);
  p_IsPrimaryKey_91f9aa01 BOOLEAN;
  p_IsUniqueKey_91f9aa01 BOOLEAN;
  p_IsReadOnly_91f9aa01 BOOLEAN;
  p_IsRequired_91f9aa01 BOOLEAN;
  p_RelatedIntegrationObjectID_91f9aa01 UUID;
  p_RelatedIntegrationObjectFieldName_91f9aa01 VARCHAR(255);
  p_Sequence_91f9aa01 INTEGER;
  p_Configuration_91f9aa01 TEXT;
  p_Status_91f9aa01 VARCHAR(25);
  p_IsCustom_91f9aa01 BOOLEAN;
  p_MetadataSource_91f9aa01 VARCHAR(20);
BEGIN
  p_ID_91f9aa01 := 'C7C0B84E-0E70-5591-A82B-0C64B70F21C1';
  p_IntegrationObjectID_91f9aa01 := 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD';
  p_Name_91f9aa01 := 'organization-disambiguated-id';
  p_DisplayName_91f9aa01 := 'Organization Disambiguated Id';
  p_Description_91f9aa01 := 'Canonical identifier of the funding organization in the disambiguation source (e.g. a RINGGOLD or ROR id), so the same institution matches across records.';
  p_Type_91f9aa01 := 'String';
  p_Length_91f9aa01 := 255;
  p_AllowsNull_91f9aa01 := TRUE;
  p_IsPrimaryKey_91f9aa01 := FALSE;
  p_IsUniqueKey_91f9aa01 := FALSE;
  p_IsReadOnly_91f9aa01 := TRUE;
  p_IsRequired_91f9aa01 := FALSE;
  p_Sequence_91f9aa01 := 33;
  p_Status_91f9aa01 := 'Active';
  p_IsCustom_91f9aa01 := FALSE;
  p_MetadataSource_91f9aa01 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_91f9aa01, p_IntegrationObjectID := p_IntegrationObjectID_91f9aa01, p_Name := p_Name_91f9aa01, p_DisplayName := p_DisplayName_91f9aa01, p_Description := p_Description_91f9aa01, p_Category := p_Category_91f9aa01, p_Category_Clear := TRUE, p_Type := p_Type_91f9aa01, p_Length := p_Length_91f9aa01, p_Precision := p_Precision_91f9aa01, p_Precision_Clear := TRUE, p_Scale := p_Scale_91f9aa01, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_91f9aa01, p_DefaultValue := p_DefaultValue_91f9aa01, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_91f9aa01, p_IsUniqueKey := p_IsUniqueKey_91f9aa01, p_IsReadOnly := p_IsReadOnly_91f9aa01, p_IsRequired := p_IsRequired_91f9aa01, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_91f9aa01, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_91f9aa01, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_91f9aa01, p_Configuration := p_Configuration_91f9aa01, p_Configuration_Clear := TRUE, p_Status := p_Status_91f9aa01, p_IsCustom := p_IsCustom_91f9aa01, p_MetadataSource := p_MetadataSource_91f9aa01);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_0050cd99 UUID;
  p_IntegrationObjectID_0050cd99 UUID;
  p_Name_0050cd99 VARCHAR(255);
  p_DisplayName_0050cd99 VARCHAR(255);
  p_Description_0050cd99 TEXT;
  p_Category_0050cd99 VARCHAR(100);
  p_Type_0050cd99 VARCHAR(100);
  p_Length_0050cd99 INTEGER;
  p_Precision_0050cd99 INTEGER;
  p_Scale_0050cd99 INTEGER;
  p_AllowsNull_0050cd99 BOOLEAN;
  p_DefaultValue_0050cd99 VARCHAR(255);
  p_IsPrimaryKey_0050cd99 BOOLEAN;
  p_IsUniqueKey_0050cd99 BOOLEAN;
  p_IsReadOnly_0050cd99 BOOLEAN;
  p_IsRequired_0050cd99 BOOLEAN;
  p_RelatedIntegrationObjectID_0050cd99 UUID;
  p_RelatedIntegrationObjectFieldName_0050cd99 VARCHAR(255);
  p_Sequence_0050cd99 INTEGER;
  p_Configuration_0050cd99 TEXT;
  p_Status_0050cd99 VARCHAR(25);
  p_IsCustom_0050cd99 BOOLEAN;
  p_MetadataSource_0050cd99 VARCHAR(20);
BEGIN
  p_ID_0050cd99 := 'A5C7DA43-BA72-59FE-92B8-60620FC7D437';
  p_IntegrationObjectID_0050cd99 := 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD';
  p_Name_0050cd99 := 'organization-disambiguation-source';
  p_DisplayName_0050cd99 := 'Organization Disambiguation Source';
  p_Description_0050cd99 := 'Registry the disambiguated id comes from (RINGGOLD, ROR, FUNDREF, GRID, LEI).';
  p_Type_0050cd99 := 'String';
  p_Length_0050cd99 := 100;
  p_AllowsNull_0050cd99 := TRUE;
  p_IsPrimaryKey_0050cd99 := FALSE;
  p_IsUniqueKey_0050cd99 := FALSE;
  p_IsReadOnly_0050cd99 := TRUE;
  p_IsRequired_0050cd99 := FALSE;
  p_Sequence_0050cd99 := 34;
  p_Status_0050cd99 := 'Active';
  p_IsCustom_0050cd99 := FALSE;
  p_MetadataSource_0050cd99 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_0050cd99, p_IntegrationObjectID := p_IntegrationObjectID_0050cd99, p_Name := p_Name_0050cd99, p_DisplayName := p_DisplayName_0050cd99, p_Description := p_Description_0050cd99, p_Category := p_Category_0050cd99, p_Category_Clear := TRUE, p_Type := p_Type_0050cd99, p_Length := p_Length_0050cd99, p_Precision := p_Precision_0050cd99, p_Precision_Clear := TRUE, p_Scale := p_Scale_0050cd99, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_0050cd99, p_DefaultValue := p_DefaultValue_0050cd99, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_0050cd99, p_IsUniqueKey := p_IsUniqueKey_0050cd99, p_IsReadOnly := p_IsReadOnly_0050cd99, p_IsRequired := p_IsRequired_0050cd99, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_0050cd99, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_0050cd99, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_0050cd99, p_Configuration := p_Configuration_0050cd99, p_Configuration_Clear := TRUE, p_Status := p_Status_0050cd99, p_IsCustom := p_IsCustom_0050cd99, p_MetadataSource := p_MetadataSource_0050cd99);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_6ec8f0af UUID;
  p_IntegrationObjectID_6ec8f0af UUID;
  p_Name_6ec8f0af VARCHAR(255);
  p_DisplayName_6ec8f0af VARCHAR(255);
  p_Description_6ec8f0af TEXT;
  p_Category_6ec8f0af VARCHAR(100);
  p_Type_6ec8f0af VARCHAR(100);
  p_Length_6ec8f0af INTEGER;
  p_Precision_6ec8f0af INTEGER;
  p_Scale_6ec8f0af INTEGER;
  p_AllowsNull_6ec8f0af BOOLEAN;
  p_DefaultValue_6ec8f0af VARCHAR(255);
  p_IsPrimaryKey_6ec8f0af BOOLEAN;
  p_IsUniqueKey_6ec8f0af BOOLEAN;
  p_IsReadOnly_6ec8f0af BOOLEAN;
  p_IsRequired_6ec8f0af BOOLEAN;
  p_RelatedIntegrationObjectID_6ec8f0af UUID;
  p_RelatedIntegrationObjectFieldName_6ec8f0af VARCHAR(255);
  p_Sequence_6ec8f0af INTEGER;
  p_Configuration_6ec8f0af TEXT;
  p_Status_6ec8f0af VARCHAR(25);
  p_IsCustom_6ec8f0af BOOLEAN;
  p_MetadataSource_6ec8f0af VARCHAR(20);
BEGIN
  p_ID_6ec8f0af := 'A3CC5D35-A91B-5C8F-8377-0FC30FCDC20E';
  p_IntegrationObjectID_6ec8f0af := 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD';
  p_Name_6ec8f0af := 'source-name';
  p_DisplayName_6ec8f0af := 'Source Name';
  p_Description_6ec8f0af := 'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.';
  p_Type_6ec8f0af := 'String';
  p_Length_6ec8f0af := 500;
  p_AllowsNull_6ec8f0af := TRUE;
  p_IsPrimaryKey_6ec8f0af := FALSE;
  p_IsUniqueKey_6ec8f0af := FALSE;
  p_IsReadOnly_6ec8f0af := TRUE;
  p_IsRequired_6ec8f0af := FALSE;
  p_Sequence_6ec8f0af := 35;
  p_Status_6ec8f0af := 'Active';
  p_IsCustom_6ec8f0af := FALSE;
  p_MetadataSource_6ec8f0af := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_6ec8f0af, p_IntegrationObjectID := p_IntegrationObjectID_6ec8f0af, p_Name := p_Name_6ec8f0af, p_DisplayName := p_DisplayName_6ec8f0af, p_Description := p_Description_6ec8f0af, p_Category := p_Category_6ec8f0af, p_Category_Clear := TRUE, p_Type := p_Type_6ec8f0af, p_Length := p_Length_6ec8f0af, p_Precision := p_Precision_6ec8f0af, p_Precision_Clear := TRUE, p_Scale := p_Scale_6ec8f0af, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_6ec8f0af, p_DefaultValue := p_DefaultValue_6ec8f0af, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_6ec8f0af, p_IsUniqueKey := p_IsUniqueKey_6ec8f0af, p_IsReadOnly := p_IsReadOnly_6ec8f0af, p_IsRequired := p_IsRequired_6ec8f0af, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_6ec8f0af, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_6ec8f0af, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_6ec8f0af, p_Configuration := p_Configuration_6ec8f0af, p_Configuration_Clear := TRUE, p_Status := p_Status_6ec8f0af, p_IsCustom := p_IsCustom_6ec8f0af, p_MetadataSource := p_MetadataSource_6ec8f0af);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_118e2781 UUID;
  p_IntegrationObjectID_118e2781 UUID;
  p_Name_118e2781 VARCHAR(255);
  p_DisplayName_118e2781 VARCHAR(255);
  p_Description_118e2781 TEXT;
  p_Category_118e2781 VARCHAR(100);
  p_Type_118e2781 VARCHAR(100);
  p_Length_118e2781 INTEGER;
  p_Precision_118e2781 INTEGER;
  p_Scale_118e2781 INTEGER;
  p_AllowsNull_118e2781 BOOLEAN;
  p_DefaultValue_118e2781 VARCHAR(255);
  p_IsPrimaryKey_118e2781 BOOLEAN;
  p_IsUniqueKey_118e2781 BOOLEAN;
  p_IsReadOnly_118e2781 BOOLEAN;
  p_IsRequired_118e2781 BOOLEAN;
  p_RelatedIntegrationObjectID_118e2781 UUID;
  p_RelatedIntegrationObjectFieldName_118e2781 VARCHAR(255);
  p_Sequence_118e2781 INTEGER;
  p_Configuration_118e2781 TEXT;
  p_Status_118e2781 VARCHAR(25);
  p_IsCustom_118e2781 BOOLEAN;
  p_MetadataSource_118e2781 VARCHAR(20);
BEGIN
  p_ID_118e2781 := 'B36FBBC7-9E85-5BE5-884D-44D801322EEF';
  p_IntegrationObjectID_118e2781 := 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD';
  p_Name_118e2781 := 'source-orcid';
  p_DisplayName_118e2781 := 'Source Orcid';
  p_Description_118e2781 := 'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.';
  p_Type_118e2781 := 'String';
  p_Length_118e2781 := 19;
  p_AllowsNull_118e2781 := TRUE;
  p_IsPrimaryKey_118e2781 := FALSE;
  p_IsUniqueKey_118e2781 := FALSE;
  p_IsReadOnly_118e2781 := TRUE;
  p_IsRequired_118e2781 := FALSE;
  p_Sequence_118e2781 := 36;
  p_Status_118e2781 := 'Active';
  p_IsCustom_118e2781 := FALSE;
  p_MetadataSource_118e2781 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_118e2781, p_IntegrationObjectID := p_IntegrationObjectID_118e2781, p_Name := p_Name_118e2781, p_DisplayName := p_DisplayName_118e2781, p_Description := p_Description_118e2781, p_Category := p_Category_118e2781, p_Category_Clear := TRUE, p_Type := p_Type_118e2781, p_Length := p_Length_118e2781, p_Precision := p_Precision_118e2781, p_Precision_Clear := TRUE, p_Scale := p_Scale_118e2781, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_118e2781, p_DefaultValue := p_DefaultValue_118e2781, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_118e2781, p_IsUniqueKey := p_IsUniqueKey_118e2781, p_IsReadOnly := p_IsReadOnly_118e2781, p_IsRequired := p_IsRequired_118e2781, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_118e2781, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_118e2781, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_118e2781, p_Configuration := p_Configuration_118e2781, p_Configuration_Clear := TRUE, p_Status := p_Status_118e2781, p_IsCustom := p_IsCustom_118e2781, p_MetadataSource := p_MetadataSource_118e2781);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_510fd1cd UUID;
  p_IntegrationObjectID_510fd1cd UUID;
  p_Name_510fd1cd VARCHAR(255);
  p_DisplayName_510fd1cd VARCHAR(255);
  p_Description_510fd1cd TEXT;
  p_Category_510fd1cd VARCHAR(100);
  p_Type_510fd1cd VARCHAR(100);
  p_Length_510fd1cd INTEGER;
  p_Precision_510fd1cd INTEGER;
  p_Scale_510fd1cd INTEGER;
  p_AllowsNull_510fd1cd BOOLEAN;
  p_DefaultValue_510fd1cd VARCHAR(255);
  p_IsPrimaryKey_510fd1cd BOOLEAN;
  p_IsUniqueKey_510fd1cd BOOLEAN;
  p_IsReadOnly_510fd1cd BOOLEAN;
  p_IsRequired_510fd1cd BOOLEAN;
  p_RelatedIntegrationObjectID_510fd1cd UUID;
  p_RelatedIntegrationObjectFieldName_510fd1cd VARCHAR(255);
  p_Sequence_510fd1cd INTEGER;
  p_Configuration_510fd1cd TEXT;
  p_Status_510fd1cd VARCHAR(25);
  p_IsCustom_510fd1cd BOOLEAN;
  p_MetadataSource_510fd1cd VARCHAR(20);
BEGIN
  p_ID_510fd1cd := '8B001C89-FF8E-5117-869B-7755BD9B5B2A';
  p_IntegrationObjectID_510fd1cd := 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F';
  p_Name_510fd1cd := 'completion-year';
  p_DisplayName_510fd1cd := 'Completion Year';
  p_Description_510fd1cd := 'Year of the review completion date; ORCID dates are partial, so month/day may be absent.';
  p_Type_510fd1cd := 'Integer';
  p_AllowsNull_510fd1cd := TRUE;
  p_IsPrimaryKey_510fd1cd := FALSE;
  p_IsUniqueKey_510fd1cd := FALSE;
  p_IsReadOnly_510fd1cd := TRUE;
  p_IsRequired_510fd1cd := FALSE;
  p_Sequence_510fd1cd := 20;
  p_Status_510fd1cd := 'Active';
  p_IsCustom_510fd1cd := FALSE;
  p_MetadataSource_510fd1cd := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_510fd1cd, p_IntegrationObjectID := p_IntegrationObjectID_510fd1cd, p_Name := p_Name_510fd1cd, p_DisplayName := p_DisplayName_510fd1cd, p_Description := p_Description_510fd1cd, p_Category := p_Category_510fd1cd, p_Category_Clear := TRUE, p_Type := p_Type_510fd1cd, p_Length := p_Length_510fd1cd, p_Length_Clear := TRUE, p_Precision := p_Precision_510fd1cd, p_Precision_Clear := TRUE, p_Scale := p_Scale_510fd1cd, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_510fd1cd, p_DefaultValue := p_DefaultValue_510fd1cd, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_510fd1cd, p_IsUniqueKey := p_IsUniqueKey_510fd1cd, p_IsReadOnly := p_IsReadOnly_510fd1cd, p_IsRequired := p_IsRequired_510fd1cd, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_510fd1cd, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_510fd1cd, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_510fd1cd, p_Configuration := p_Configuration_510fd1cd, p_Configuration_Clear := TRUE, p_Status := p_Status_510fd1cd, p_IsCustom := p_IsCustom_510fd1cd, p_MetadataSource := p_MetadataSource_510fd1cd);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_ee28e9cc UUID;
  p_IntegrationObjectID_ee28e9cc UUID;
  p_Name_ee28e9cc VARCHAR(255);
  p_DisplayName_ee28e9cc VARCHAR(255);
  p_Description_ee28e9cc TEXT;
  p_Category_ee28e9cc VARCHAR(100);
  p_Type_ee28e9cc VARCHAR(100);
  p_Length_ee28e9cc INTEGER;
  p_Precision_ee28e9cc INTEGER;
  p_Scale_ee28e9cc INTEGER;
  p_AllowsNull_ee28e9cc BOOLEAN;
  p_DefaultValue_ee28e9cc VARCHAR(255);
  p_IsPrimaryKey_ee28e9cc BOOLEAN;
  p_IsUniqueKey_ee28e9cc BOOLEAN;
  p_IsReadOnly_ee28e9cc BOOLEAN;
  p_IsRequired_ee28e9cc BOOLEAN;
  p_RelatedIntegrationObjectID_ee28e9cc UUID;
  p_RelatedIntegrationObjectFieldName_ee28e9cc VARCHAR(255);
  p_Sequence_ee28e9cc INTEGER;
  p_Configuration_ee28e9cc TEXT;
  p_Status_ee28e9cc VARCHAR(25);
  p_IsCustom_ee28e9cc BOOLEAN;
  p_MetadataSource_ee28e9cc VARCHAR(20);
BEGIN
  p_ID_ee28e9cc := '77AA2C8F-72DE-5E33-B378-6BD7F0CF4B78';
  p_IntegrationObjectID_ee28e9cc := 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F';
  p_Name_ee28e9cc := 'completion-month';
  p_DisplayName_ee28e9cc := 'Completion Month';
  p_Description_ee28e9cc := 'Month (1-12) of the review completion date, when given.';
  p_Type_ee28e9cc := 'Integer';
  p_AllowsNull_ee28e9cc := TRUE;
  p_IsPrimaryKey_ee28e9cc := FALSE;
  p_IsUniqueKey_ee28e9cc := FALSE;
  p_IsReadOnly_ee28e9cc := TRUE;
  p_IsRequired_ee28e9cc := FALSE;
  p_Sequence_ee28e9cc := 21;
  p_Status_ee28e9cc := 'Active';
  p_IsCustom_ee28e9cc := FALSE;
  p_MetadataSource_ee28e9cc := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_ee28e9cc, p_IntegrationObjectID := p_IntegrationObjectID_ee28e9cc, p_Name := p_Name_ee28e9cc, p_DisplayName := p_DisplayName_ee28e9cc, p_Description := p_Description_ee28e9cc, p_Category := p_Category_ee28e9cc, p_Category_Clear := TRUE, p_Type := p_Type_ee28e9cc, p_Length := p_Length_ee28e9cc, p_Length_Clear := TRUE, p_Precision := p_Precision_ee28e9cc, p_Precision_Clear := TRUE, p_Scale := p_Scale_ee28e9cc, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_ee28e9cc, p_DefaultValue := p_DefaultValue_ee28e9cc, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_ee28e9cc, p_IsUniqueKey := p_IsUniqueKey_ee28e9cc, p_IsReadOnly := p_IsReadOnly_ee28e9cc, p_IsRequired := p_IsRequired_ee28e9cc, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_ee28e9cc, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_ee28e9cc, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_ee28e9cc, p_Configuration := p_Configuration_ee28e9cc, p_Configuration_Clear := TRUE, p_Status := p_Status_ee28e9cc, p_IsCustom := p_IsCustom_ee28e9cc, p_MetadataSource := p_MetadataSource_ee28e9cc);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_c41e5687 UUID;
  p_IntegrationObjectID_c41e5687 UUID;
  p_Name_c41e5687 VARCHAR(255);
  p_DisplayName_c41e5687 VARCHAR(255);
  p_Description_c41e5687 TEXT;
  p_Category_c41e5687 VARCHAR(100);
  p_Type_c41e5687 VARCHAR(100);
  p_Length_c41e5687 INTEGER;
  p_Precision_c41e5687 INTEGER;
  p_Scale_c41e5687 INTEGER;
  p_AllowsNull_c41e5687 BOOLEAN;
  p_DefaultValue_c41e5687 VARCHAR(255);
  p_IsPrimaryKey_c41e5687 BOOLEAN;
  p_IsUniqueKey_c41e5687 BOOLEAN;
  p_IsReadOnly_c41e5687 BOOLEAN;
  p_IsRequired_c41e5687 BOOLEAN;
  p_RelatedIntegrationObjectID_c41e5687 UUID;
  p_RelatedIntegrationObjectFieldName_c41e5687 VARCHAR(255);
  p_Sequence_c41e5687 INTEGER;
  p_Configuration_c41e5687 TEXT;
  p_Status_c41e5687 VARCHAR(25);
  p_IsCustom_c41e5687 BOOLEAN;
  p_MetadataSource_c41e5687 VARCHAR(20);
BEGIN
  p_ID_c41e5687 := '4B9F5E93-66F9-5839-8A5D-B0D768301EDD';
  p_IntegrationObjectID_c41e5687 := 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F';
  p_Name_c41e5687 := 'completion-day';
  p_DisplayName_c41e5687 := 'Completion Day';
  p_Description_c41e5687 := 'Day of month of the review completion date, when given.';
  p_Type_c41e5687 := 'Integer';
  p_AllowsNull_c41e5687 := TRUE;
  p_IsPrimaryKey_c41e5687 := FALSE;
  p_IsUniqueKey_c41e5687 := FALSE;
  p_IsReadOnly_c41e5687 := TRUE;
  p_IsRequired_c41e5687 := FALSE;
  p_Sequence_c41e5687 := 22;
  p_Status_c41e5687 := 'Active';
  p_IsCustom_c41e5687 := FALSE;
  p_MetadataSource_c41e5687 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_c41e5687, p_IntegrationObjectID := p_IntegrationObjectID_c41e5687, p_Name := p_Name_c41e5687, p_DisplayName := p_DisplayName_c41e5687, p_Description := p_Description_c41e5687, p_Category := p_Category_c41e5687, p_Category_Clear := TRUE, p_Type := p_Type_c41e5687, p_Length := p_Length_c41e5687, p_Length_Clear := TRUE, p_Precision := p_Precision_c41e5687, p_Precision_Clear := TRUE, p_Scale := p_Scale_c41e5687, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_c41e5687, p_DefaultValue := p_DefaultValue_c41e5687, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_c41e5687, p_IsUniqueKey := p_IsUniqueKey_c41e5687, p_IsReadOnly := p_IsReadOnly_c41e5687, p_IsRequired := p_IsRequired_c41e5687, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_c41e5687, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_c41e5687, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_c41e5687, p_Configuration := p_Configuration_c41e5687, p_Configuration_Clear := TRUE, p_Status := p_Status_c41e5687, p_IsCustom := p_IsCustom_c41e5687, p_MetadataSource := p_MetadataSource_c41e5687);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_a56c1e5c UUID;
  p_IntegrationObjectID_a56c1e5c UUID;
  p_Name_a56c1e5c VARCHAR(255);
  p_DisplayName_a56c1e5c VARCHAR(255);
  p_Description_a56c1e5c TEXT;
  p_Category_a56c1e5c VARCHAR(100);
  p_Type_a56c1e5c VARCHAR(100);
  p_Length_a56c1e5c INTEGER;
  p_Precision_a56c1e5c INTEGER;
  p_Scale_a56c1e5c INTEGER;
  p_AllowsNull_a56c1e5c BOOLEAN;
  p_DefaultValue_a56c1e5c VARCHAR(255);
  p_IsPrimaryKey_a56c1e5c BOOLEAN;
  p_IsUniqueKey_a56c1e5c BOOLEAN;
  p_IsReadOnly_a56c1e5c BOOLEAN;
  p_IsRequired_a56c1e5c BOOLEAN;
  p_RelatedIntegrationObjectID_a56c1e5c UUID;
  p_RelatedIntegrationObjectFieldName_a56c1e5c VARCHAR(255);
  p_Sequence_a56c1e5c INTEGER;
  p_Configuration_a56c1e5c TEXT;
  p_Status_a56c1e5c VARCHAR(25);
  p_IsCustom_a56c1e5c BOOLEAN;
  p_MetadataSource_a56c1e5c VARCHAR(20);
BEGIN
  p_ID_a56c1e5c := 'C0E8F032-5D9A-5171-8125-1D240ED0D18B';
  p_IntegrationObjectID_a56c1e5c := 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F';
  p_Name_a56c1e5c := 'convening-organization-name';
  p_DisplayName_a56c1e5c := 'Convening Organization Name';
  p_Description_a56c1e5c := 'Name of the convening organization (journal, conference). Lifted from convening-organization.name.';
  p_Type_a56c1e5c := 'String';
  p_Length_a56c1e5c := 1000;
  p_AllowsNull_a56c1e5c := TRUE;
  p_IsPrimaryKey_a56c1e5c := FALSE;
  p_IsUniqueKey_a56c1e5c := FALSE;
  p_IsReadOnly_a56c1e5c := TRUE;
  p_IsRequired_a56c1e5c := FALSE;
  p_Sequence_a56c1e5c := 23;
  p_Status_a56c1e5c := 'Active';
  p_IsCustom_a56c1e5c := FALSE;
  p_MetadataSource_a56c1e5c := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_a56c1e5c, p_IntegrationObjectID := p_IntegrationObjectID_a56c1e5c, p_Name := p_Name_a56c1e5c, p_DisplayName := p_DisplayName_a56c1e5c, p_Description := p_Description_a56c1e5c, p_Category := p_Category_a56c1e5c, p_Category_Clear := TRUE, p_Type := p_Type_a56c1e5c, p_Length := p_Length_a56c1e5c, p_Precision := p_Precision_a56c1e5c, p_Precision_Clear := TRUE, p_Scale := p_Scale_a56c1e5c, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_a56c1e5c, p_DefaultValue := p_DefaultValue_a56c1e5c, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_a56c1e5c, p_IsUniqueKey := p_IsUniqueKey_a56c1e5c, p_IsReadOnly := p_IsReadOnly_a56c1e5c, p_IsRequired := p_IsRequired_a56c1e5c, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_a56c1e5c, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_a56c1e5c, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_a56c1e5c, p_Configuration := p_Configuration_a56c1e5c, p_Configuration_Clear := TRUE, p_Status := p_Status_a56c1e5c, p_IsCustom := p_IsCustom_a56c1e5c, p_MetadataSource := p_MetadataSource_a56c1e5c);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_452ba948 UUID;
  p_IntegrationObjectID_452ba948 UUID;
  p_Name_452ba948 VARCHAR(255);
  p_DisplayName_452ba948 VARCHAR(255);
  p_Description_452ba948 TEXT;
  p_Category_452ba948 VARCHAR(100);
  p_Type_452ba948 VARCHAR(100);
  p_Length_452ba948 INTEGER;
  p_Precision_452ba948 INTEGER;
  p_Scale_452ba948 INTEGER;
  p_AllowsNull_452ba948 BOOLEAN;
  p_DefaultValue_452ba948 VARCHAR(255);
  p_IsPrimaryKey_452ba948 BOOLEAN;
  p_IsUniqueKey_452ba948 BOOLEAN;
  p_IsReadOnly_452ba948 BOOLEAN;
  p_IsRequired_452ba948 BOOLEAN;
  p_RelatedIntegrationObjectID_452ba948 UUID;
  p_RelatedIntegrationObjectFieldName_452ba948 VARCHAR(255);
  p_Sequence_452ba948 INTEGER;
  p_Configuration_452ba948 TEXT;
  p_Status_452ba948 VARCHAR(25);
  p_IsCustom_452ba948 BOOLEAN;
  p_MetadataSource_452ba948 VARCHAR(20);
BEGIN
  p_ID_452ba948 := '5F5BACEB-FA92-5A3C-87BA-837889064F7E';
  p_IntegrationObjectID_452ba948 := 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F';
  p_Name_452ba948 := 'convening-organization-city';
  p_DisplayName_452ba948 := 'Convening Organization City';
  p_Description_452ba948 := 'City of the convening organization (journal, conference). Lifted from convening-organization.address.city.';
  p_Type_452ba948 := 'String';
  p_Length_452ba948 := 255;
  p_AllowsNull_452ba948 := TRUE;
  p_IsPrimaryKey_452ba948 := FALSE;
  p_IsUniqueKey_452ba948 := FALSE;
  p_IsReadOnly_452ba948 := TRUE;
  p_IsRequired_452ba948 := FALSE;
  p_Sequence_452ba948 := 24;
  p_Status_452ba948 := 'Active';
  p_IsCustom_452ba948 := FALSE;
  p_MetadataSource_452ba948 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_452ba948, p_IntegrationObjectID := p_IntegrationObjectID_452ba948, p_Name := p_Name_452ba948, p_DisplayName := p_DisplayName_452ba948, p_Description := p_Description_452ba948, p_Category := p_Category_452ba948, p_Category_Clear := TRUE, p_Type := p_Type_452ba948, p_Length := p_Length_452ba948, p_Precision := p_Precision_452ba948, p_Precision_Clear := TRUE, p_Scale := p_Scale_452ba948, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_452ba948, p_DefaultValue := p_DefaultValue_452ba948, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_452ba948, p_IsUniqueKey := p_IsUniqueKey_452ba948, p_IsReadOnly := p_IsReadOnly_452ba948, p_IsRequired := p_IsRequired_452ba948, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_452ba948, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_452ba948, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_452ba948, p_Configuration := p_Configuration_452ba948, p_Configuration_Clear := TRUE, p_Status := p_Status_452ba948, p_IsCustom := p_IsCustom_452ba948, p_MetadataSource := p_MetadataSource_452ba948);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_0808d0a4 UUID;
  p_IntegrationObjectID_0808d0a4 UUID;
  p_Name_0808d0a4 VARCHAR(255);
  p_DisplayName_0808d0a4 VARCHAR(255);
  p_Description_0808d0a4 TEXT;
  p_Category_0808d0a4 VARCHAR(100);
  p_Type_0808d0a4 VARCHAR(100);
  p_Length_0808d0a4 INTEGER;
  p_Precision_0808d0a4 INTEGER;
  p_Scale_0808d0a4 INTEGER;
  p_AllowsNull_0808d0a4 BOOLEAN;
  p_DefaultValue_0808d0a4 VARCHAR(255);
  p_IsPrimaryKey_0808d0a4 BOOLEAN;
  p_IsUniqueKey_0808d0a4 BOOLEAN;
  p_IsReadOnly_0808d0a4 BOOLEAN;
  p_IsRequired_0808d0a4 BOOLEAN;
  p_RelatedIntegrationObjectID_0808d0a4 UUID;
  p_RelatedIntegrationObjectFieldName_0808d0a4 VARCHAR(255);
  p_Sequence_0808d0a4 INTEGER;
  p_Configuration_0808d0a4 TEXT;
  p_Status_0808d0a4 VARCHAR(25);
  p_IsCustom_0808d0a4 BOOLEAN;
  p_MetadataSource_0808d0a4 VARCHAR(20);
BEGIN
  p_ID_0808d0a4 := '4B6DF283-5064-5EEF-8AD5-69A89F47351A';
  p_IntegrationObjectID_0808d0a4 := 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F';
  p_Name_0808d0a4 := 'convening-organization-region';
  p_DisplayName_0808d0a4 := 'Convening Organization Region';
  p_Description_0808d0a4 := 'Region/state of the convening organization (journal, conference). Lifted from convening-organization.address.region.';
  p_Type_0808d0a4 := 'String';
  p_Length_0808d0a4 := 255;
  p_AllowsNull_0808d0a4 := TRUE;
  p_IsPrimaryKey_0808d0a4 := FALSE;
  p_IsUniqueKey_0808d0a4 := FALSE;
  p_IsReadOnly_0808d0a4 := TRUE;
  p_IsRequired_0808d0a4 := FALSE;
  p_Sequence_0808d0a4 := 25;
  p_Status_0808d0a4 := 'Active';
  p_IsCustom_0808d0a4 := FALSE;
  p_MetadataSource_0808d0a4 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_0808d0a4, p_IntegrationObjectID := p_IntegrationObjectID_0808d0a4, p_Name := p_Name_0808d0a4, p_DisplayName := p_DisplayName_0808d0a4, p_Description := p_Description_0808d0a4, p_Category := p_Category_0808d0a4, p_Category_Clear := TRUE, p_Type := p_Type_0808d0a4, p_Length := p_Length_0808d0a4, p_Precision := p_Precision_0808d0a4, p_Precision_Clear := TRUE, p_Scale := p_Scale_0808d0a4, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_0808d0a4, p_DefaultValue := p_DefaultValue_0808d0a4, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_0808d0a4, p_IsUniqueKey := p_IsUniqueKey_0808d0a4, p_IsReadOnly := p_IsReadOnly_0808d0a4, p_IsRequired := p_IsRequired_0808d0a4, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_0808d0a4, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_0808d0a4, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_0808d0a4, p_Configuration := p_Configuration_0808d0a4, p_Configuration_Clear := TRUE, p_Status := p_Status_0808d0a4, p_IsCustom := p_IsCustom_0808d0a4, p_MetadataSource := p_MetadataSource_0808d0a4);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_18b9523d UUID;
  p_IntegrationObjectID_18b9523d UUID;
  p_Name_18b9523d VARCHAR(255);
  p_DisplayName_18b9523d VARCHAR(255);
  p_Description_18b9523d TEXT;
  p_Category_18b9523d VARCHAR(100);
  p_Type_18b9523d VARCHAR(100);
  p_Length_18b9523d INTEGER;
  p_Precision_18b9523d INTEGER;
  p_Scale_18b9523d INTEGER;
  p_AllowsNull_18b9523d BOOLEAN;
  p_DefaultValue_18b9523d VARCHAR(255);
  p_IsPrimaryKey_18b9523d BOOLEAN;
  p_IsUniqueKey_18b9523d BOOLEAN;
  p_IsReadOnly_18b9523d BOOLEAN;
  p_IsRequired_18b9523d BOOLEAN;
  p_RelatedIntegrationObjectID_18b9523d UUID;
  p_RelatedIntegrationObjectFieldName_18b9523d VARCHAR(255);
  p_Sequence_18b9523d INTEGER;
  p_Configuration_18b9523d TEXT;
  p_Status_18b9523d VARCHAR(25);
  p_IsCustom_18b9523d BOOLEAN;
  p_MetadataSource_18b9523d VARCHAR(20);
BEGIN
  p_ID_18b9523d := '52DF410A-F371-580E-981F-6D74EE6EB807';
  p_IntegrationObjectID_18b9523d := 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F';
  p_Name_18b9523d := 'convening-organization-country';
  p_DisplayName_18b9523d := 'Convening Organization Country';
  p_Description_18b9523d := 'ISO country code of the convening organization (journal, conference). Lifted from convening-organization.address.country.';
  p_Type_18b9523d := 'String';
  p_Length_18b9523d := 50;
  p_AllowsNull_18b9523d := TRUE;
  p_IsPrimaryKey_18b9523d := FALSE;
  p_IsUniqueKey_18b9523d := FALSE;
  p_IsReadOnly_18b9523d := TRUE;
  p_IsRequired_18b9523d := FALSE;
  p_Sequence_18b9523d := 26;
  p_Status_18b9523d := 'Active';
  p_IsCustom_18b9523d := FALSE;
  p_MetadataSource_18b9523d := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_18b9523d, p_IntegrationObjectID := p_IntegrationObjectID_18b9523d, p_Name := p_Name_18b9523d, p_DisplayName := p_DisplayName_18b9523d, p_Description := p_Description_18b9523d, p_Category := p_Category_18b9523d, p_Category_Clear := TRUE, p_Type := p_Type_18b9523d, p_Length := p_Length_18b9523d, p_Precision := p_Precision_18b9523d, p_Precision_Clear := TRUE, p_Scale := p_Scale_18b9523d, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_18b9523d, p_DefaultValue := p_DefaultValue_18b9523d, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_18b9523d, p_IsUniqueKey := p_IsUniqueKey_18b9523d, p_IsReadOnly := p_IsReadOnly_18b9523d, p_IsRequired := p_IsRequired_18b9523d, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_18b9523d, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_18b9523d, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_18b9523d, p_Configuration := p_Configuration_18b9523d, p_Configuration_Clear := TRUE, p_Status := p_Status_18b9523d, p_IsCustom := p_IsCustom_18b9523d, p_MetadataSource := p_MetadataSource_18b9523d);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_0f2e6b97 UUID;
  p_IntegrationObjectID_0f2e6b97 UUID;
  p_Name_0f2e6b97 VARCHAR(255);
  p_DisplayName_0f2e6b97 VARCHAR(255);
  p_Description_0f2e6b97 TEXT;
  p_Category_0f2e6b97 VARCHAR(100);
  p_Type_0f2e6b97 VARCHAR(100);
  p_Length_0f2e6b97 INTEGER;
  p_Precision_0f2e6b97 INTEGER;
  p_Scale_0f2e6b97 INTEGER;
  p_AllowsNull_0f2e6b97 BOOLEAN;
  p_DefaultValue_0f2e6b97 VARCHAR(255);
  p_IsPrimaryKey_0f2e6b97 BOOLEAN;
  p_IsUniqueKey_0f2e6b97 BOOLEAN;
  p_IsReadOnly_0f2e6b97 BOOLEAN;
  p_IsRequired_0f2e6b97 BOOLEAN;
  p_RelatedIntegrationObjectID_0f2e6b97 UUID;
  p_RelatedIntegrationObjectFieldName_0f2e6b97 VARCHAR(255);
  p_Sequence_0f2e6b97 INTEGER;
  p_Configuration_0f2e6b97 TEXT;
  p_Status_0f2e6b97 VARCHAR(25);
  p_IsCustom_0f2e6b97 BOOLEAN;
  p_MetadataSource_0f2e6b97 VARCHAR(20);
BEGIN
  p_ID_0f2e6b97 := 'B76AB8AC-4674-5700-A966-46AA4A9AC511';
  p_IntegrationObjectID_0f2e6b97 := 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F';
  p_Name_0f2e6b97 := 'convening-organization-disambiguated-id';
  p_DisplayName_0f2e6b97 := 'Convening Organization Disambiguated Id';
  p_Description_0f2e6b97 := 'Canonical identifier of the convening organization (journal, conference) in the disambiguation source (e.g. a RINGGOLD or ROR id), so the same institution matches across records.';
  p_Type_0f2e6b97 := 'String';
  p_Length_0f2e6b97 := 255;
  p_AllowsNull_0f2e6b97 := TRUE;
  p_IsPrimaryKey_0f2e6b97 := FALSE;
  p_IsUniqueKey_0f2e6b97 := FALSE;
  p_IsReadOnly_0f2e6b97 := TRUE;
  p_IsRequired_0f2e6b97 := FALSE;
  p_Sequence_0f2e6b97 := 27;
  p_Status_0f2e6b97 := 'Active';
  p_IsCustom_0f2e6b97 := FALSE;
  p_MetadataSource_0f2e6b97 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_0f2e6b97, p_IntegrationObjectID := p_IntegrationObjectID_0f2e6b97, p_Name := p_Name_0f2e6b97, p_DisplayName := p_DisplayName_0f2e6b97, p_Description := p_Description_0f2e6b97, p_Category := p_Category_0f2e6b97, p_Category_Clear := TRUE, p_Type := p_Type_0f2e6b97, p_Length := p_Length_0f2e6b97, p_Precision := p_Precision_0f2e6b97, p_Precision_Clear := TRUE, p_Scale := p_Scale_0f2e6b97, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_0f2e6b97, p_DefaultValue := p_DefaultValue_0f2e6b97, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_0f2e6b97, p_IsUniqueKey := p_IsUniqueKey_0f2e6b97, p_IsReadOnly := p_IsReadOnly_0f2e6b97, p_IsRequired := p_IsRequired_0f2e6b97, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_0f2e6b97, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_0f2e6b97, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_0f2e6b97, p_Configuration := p_Configuration_0f2e6b97, p_Configuration_Clear := TRUE, p_Status := p_Status_0f2e6b97, p_IsCustom := p_IsCustom_0f2e6b97, p_MetadataSource := p_MetadataSource_0f2e6b97);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_0da1f6ef UUID;
  p_IntegrationObjectID_0da1f6ef UUID;
  p_Name_0da1f6ef VARCHAR(255);
  p_DisplayName_0da1f6ef VARCHAR(255);
  p_Description_0da1f6ef TEXT;
  p_Category_0da1f6ef VARCHAR(100);
  p_Type_0da1f6ef VARCHAR(100);
  p_Length_0da1f6ef INTEGER;
  p_Precision_0da1f6ef INTEGER;
  p_Scale_0da1f6ef INTEGER;
  p_AllowsNull_0da1f6ef BOOLEAN;
  p_DefaultValue_0da1f6ef VARCHAR(255);
  p_IsPrimaryKey_0da1f6ef BOOLEAN;
  p_IsUniqueKey_0da1f6ef BOOLEAN;
  p_IsReadOnly_0da1f6ef BOOLEAN;
  p_IsRequired_0da1f6ef BOOLEAN;
  p_RelatedIntegrationObjectID_0da1f6ef UUID;
  p_RelatedIntegrationObjectFieldName_0da1f6ef VARCHAR(255);
  p_Sequence_0da1f6ef INTEGER;
  p_Configuration_0da1f6ef TEXT;
  p_Status_0da1f6ef VARCHAR(25);
  p_IsCustom_0da1f6ef BOOLEAN;
  p_MetadataSource_0da1f6ef VARCHAR(20);
BEGIN
  p_ID_0da1f6ef := 'FC80A75C-7065-58CC-A41C-811FE0A68530';
  p_IntegrationObjectID_0da1f6ef := 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F';
  p_Name_0da1f6ef := 'convening-organization-disambiguation-source';
  p_DisplayName_0da1f6ef := 'Convening Organization Disambiguation Source';
  p_Description_0da1f6ef := 'Registry the disambiguated id comes from (RINGGOLD, ROR, FUNDREF, GRID, LEI).';
  p_Type_0da1f6ef := 'String';
  p_Length_0da1f6ef := 100;
  p_AllowsNull_0da1f6ef := TRUE;
  p_IsPrimaryKey_0da1f6ef := FALSE;
  p_IsUniqueKey_0da1f6ef := FALSE;
  p_IsReadOnly_0da1f6ef := TRUE;
  p_IsRequired_0da1f6ef := FALSE;
  p_Sequence_0da1f6ef := 28;
  p_Status_0da1f6ef := 'Active';
  p_IsCustom_0da1f6ef := FALSE;
  p_MetadataSource_0da1f6ef := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_0da1f6ef, p_IntegrationObjectID := p_IntegrationObjectID_0da1f6ef, p_Name := p_Name_0da1f6ef, p_DisplayName := p_DisplayName_0da1f6ef, p_Description := p_Description_0da1f6ef, p_Category := p_Category_0da1f6ef, p_Category_Clear := TRUE, p_Type := p_Type_0da1f6ef, p_Length := p_Length_0da1f6ef, p_Precision := p_Precision_0da1f6ef, p_Precision_Clear := TRUE, p_Scale := p_Scale_0da1f6ef, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_0da1f6ef, p_DefaultValue := p_DefaultValue_0da1f6ef, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_0da1f6ef, p_IsUniqueKey := p_IsUniqueKey_0da1f6ef, p_IsReadOnly := p_IsReadOnly_0da1f6ef, p_IsRequired := p_IsRequired_0da1f6ef, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_0da1f6ef, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_0da1f6ef, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_0da1f6ef, p_Configuration := p_Configuration_0da1f6ef, p_Configuration_Clear := TRUE, p_Status := p_Status_0da1f6ef, p_IsCustom := p_IsCustom_0da1f6ef, p_MetadataSource := p_MetadataSource_0da1f6ef);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_fd878f8d UUID;
  p_IntegrationObjectID_fd878f8d UUID;
  p_Name_fd878f8d VARCHAR(255);
  p_DisplayName_fd878f8d VARCHAR(255);
  p_Description_fd878f8d TEXT;
  p_Category_fd878f8d VARCHAR(100);
  p_Type_fd878f8d VARCHAR(100);
  p_Length_fd878f8d INTEGER;
  p_Precision_fd878f8d INTEGER;
  p_Scale_fd878f8d INTEGER;
  p_AllowsNull_fd878f8d BOOLEAN;
  p_DefaultValue_fd878f8d VARCHAR(255);
  p_IsPrimaryKey_fd878f8d BOOLEAN;
  p_IsUniqueKey_fd878f8d BOOLEAN;
  p_IsReadOnly_fd878f8d BOOLEAN;
  p_IsRequired_fd878f8d BOOLEAN;
  p_RelatedIntegrationObjectID_fd878f8d UUID;
  p_RelatedIntegrationObjectFieldName_fd878f8d VARCHAR(255);
  p_Sequence_fd878f8d INTEGER;
  p_Configuration_fd878f8d TEXT;
  p_Status_fd878f8d VARCHAR(25);
  p_IsCustom_fd878f8d BOOLEAN;
  p_MetadataSource_fd878f8d VARCHAR(20);
BEGIN
  p_ID_fd878f8d := 'C2CEAA75-B036-5BEA-B5DA-B47812F1FC9C';
  p_IntegrationObjectID_fd878f8d := 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F';
  p_Name_fd878f8d := 'subject-name-title';
  p_DisplayName_fd878f8d := 'Subject Name Title';
  p_Description_fd878f8d := 'Title of the reviewed item. Lifted from subject-name.title.';
  p_Type_fd878f8d := 'String';
  p_Length_fd878f8d := 2000;
  p_AllowsNull_fd878f8d := TRUE;
  p_IsPrimaryKey_fd878f8d := FALSE;
  p_IsUniqueKey_fd878f8d := FALSE;
  p_IsReadOnly_fd878f8d := TRUE;
  p_IsRequired_fd878f8d := FALSE;
  p_Sequence_fd878f8d := 29;
  p_Status_fd878f8d := 'Active';
  p_IsCustom_fd878f8d := FALSE;
  p_MetadataSource_fd878f8d := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_fd878f8d, p_IntegrationObjectID := p_IntegrationObjectID_fd878f8d, p_Name := p_Name_fd878f8d, p_DisplayName := p_DisplayName_fd878f8d, p_Description := p_Description_fd878f8d, p_Category := p_Category_fd878f8d, p_Category_Clear := TRUE, p_Type := p_Type_fd878f8d, p_Length := p_Length_fd878f8d, p_Precision := p_Precision_fd878f8d, p_Precision_Clear := TRUE, p_Scale := p_Scale_fd878f8d, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_fd878f8d, p_DefaultValue := p_DefaultValue_fd878f8d, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_fd878f8d, p_IsUniqueKey := p_IsUniqueKey_fd878f8d, p_IsReadOnly := p_IsReadOnly_fd878f8d, p_IsRequired := p_IsRequired_fd878f8d, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_fd878f8d, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_fd878f8d, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_fd878f8d, p_Configuration := p_Configuration_fd878f8d, p_Configuration_Clear := TRUE, p_Status := p_Status_fd878f8d, p_IsCustom := p_IsCustom_fd878f8d, p_MetadataSource := p_MetadataSource_fd878f8d);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_67ccf45b UUID;
  p_IntegrationObjectID_67ccf45b UUID;
  p_Name_67ccf45b VARCHAR(255);
  p_DisplayName_67ccf45b VARCHAR(255);
  p_Description_67ccf45b TEXT;
  p_Category_67ccf45b VARCHAR(100);
  p_Type_67ccf45b VARCHAR(100);
  p_Length_67ccf45b INTEGER;
  p_Precision_67ccf45b INTEGER;
  p_Scale_67ccf45b INTEGER;
  p_AllowsNull_67ccf45b BOOLEAN;
  p_DefaultValue_67ccf45b VARCHAR(255);
  p_IsPrimaryKey_67ccf45b BOOLEAN;
  p_IsUniqueKey_67ccf45b BOOLEAN;
  p_IsReadOnly_67ccf45b BOOLEAN;
  p_IsRequired_67ccf45b BOOLEAN;
  p_RelatedIntegrationObjectID_67ccf45b UUID;
  p_RelatedIntegrationObjectFieldName_67ccf45b VARCHAR(255);
  p_Sequence_67ccf45b INTEGER;
  p_Configuration_67ccf45b TEXT;
  p_Status_67ccf45b VARCHAR(25);
  p_IsCustom_67ccf45b BOOLEAN;
  p_MetadataSource_67ccf45b VARCHAR(20);
BEGIN
  p_ID_67ccf45b := '7484D2DC-F882-50DA-996B-55BF12BA7369';
  p_IntegrationObjectID_67ccf45b := 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F';
  p_Name_67ccf45b := 'subject-external-id-type';
  p_DisplayName_67ccf45b := 'Subject External Id Type';
  p_Description_67ccf45b := 'Identifier type of the reviewed item (e.g. doi). Lifted from subject-external-identifier.external-id-type.';
  p_Type_67ccf45b := 'String';
  p_Length_67ccf45b := 100;
  p_AllowsNull_67ccf45b := TRUE;
  p_IsPrimaryKey_67ccf45b := FALSE;
  p_IsUniqueKey_67ccf45b := FALSE;
  p_IsReadOnly_67ccf45b := TRUE;
  p_IsRequired_67ccf45b := FALSE;
  p_Sequence_67ccf45b := 30;
  p_Status_67ccf45b := 'Active';
  p_IsCustom_67ccf45b := FALSE;
  p_MetadataSource_67ccf45b := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_67ccf45b, p_IntegrationObjectID := p_IntegrationObjectID_67ccf45b, p_Name := p_Name_67ccf45b, p_DisplayName := p_DisplayName_67ccf45b, p_Description := p_Description_67ccf45b, p_Category := p_Category_67ccf45b, p_Category_Clear := TRUE, p_Type := p_Type_67ccf45b, p_Length := p_Length_67ccf45b, p_Precision := p_Precision_67ccf45b, p_Precision_Clear := TRUE, p_Scale := p_Scale_67ccf45b, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_67ccf45b, p_DefaultValue := p_DefaultValue_67ccf45b, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_67ccf45b, p_IsUniqueKey := p_IsUniqueKey_67ccf45b, p_IsReadOnly := p_IsReadOnly_67ccf45b, p_IsRequired := p_IsRequired_67ccf45b, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_67ccf45b, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_67ccf45b, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_67ccf45b, p_Configuration := p_Configuration_67ccf45b, p_Configuration_Clear := TRUE, p_Status := p_Status_67ccf45b, p_IsCustom := p_IsCustom_67ccf45b, p_MetadataSource := p_MetadataSource_67ccf45b);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_a8e72b57 UUID;
  p_IntegrationObjectID_a8e72b57 UUID;
  p_Name_a8e72b57 VARCHAR(255);
  p_DisplayName_a8e72b57 VARCHAR(255);
  p_Description_a8e72b57 TEXT;
  p_Category_a8e72b57 VARCHAR(100);
  p_Type_a8e72b57 VARCHAR(100);
  p_Length_a8e72b57 INTEGER;
  p_Precision_a8e72b57 INTEGER;
  p_Scale_a8e72b57 INTEGER;
  p_AllowsNull_a8e72b57 BOOLEAN;
  p_DefaultValue_a8e72b57 VARCHAR(255);
  p_IsPrimaryKey_a8e72b57 BOOLEAN;
  p_IsUniqueKey_a8e72b57 BOOLEAN;
  p_IsReadOnly_a8e72b57 BOOLEAN;
  p_IsRequired_a8e72b57 BOOLEAN;
  p_RelatedIntegrationObjectID_a8e72b57 UUID;
  p_RelatedIntegrationObjectFieldName_a8e72b57 VARCHAR(255);
  p_Sequence_a8e72b57 INTEGER;
  p_Configuration_a8e72b57 TEXT;
  p_Status_a8e72b57 VARCHAR(25);
  p_IsCustom_a8e72b57 BOOLEAN;
  p_MetadataSource_a8e72b57 VARCHAR(20);
BEGIN
  p_ID_a8e72b57 := '35055E21-8A44-5003-91B2-66778EDC1B04';
  p_IntegrationObjectID_a8e72b57 := 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F';
  p_Name_a8e72b57 := 'subject-external-id-value';
  p_DisplayName_a8e72b57 := 'Subject External Id Value';
  p_Description_a8e72b57 := 'Identifier value of the reviewed item. Lifted from subject-external-identifier.external-id-value.';
  p_Type_a8e72b57 := 'String';
  p_Length_a8e72b57 := 500;
  p_AllowsNull_a8e72b57 := TRUE;
  p_IsPrimaryKey_a8e72b57 := FALSE;
  p_IsUniqueKey_a8e72b57 := FALSE;
  p_IsReadOnly_a8e72b57 := TRUE;
  p_IsRequired_a8e72b57 := FALSE;
  p_Sequence_a8e72b57 := 31;
  p_Status_a8e72b57 := 'Active';
  p_IsCustom_a8e72b57 := FALSE;
  p_MetadataSource_a8e72b57 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_a8e72b57, p_IntegrationObjectID := p_IntegrationObjectID_a8e72b57, p_Name := p_Name_a8e72b57, p_DisplayName := p_DisplayName_a8e72b57, p_Description := p_Description_a8e72b57, p_Category := p_Category_a8e72b57, p_Category_Clear := TRUE, p_Type := p_Type_a8e72b57, p_Length := p_Length_a8e72b57, p_Precision := p_Precision_a8e72b57, p_Precision_Clear := TRUE, p_Scale := p_Scale_a8e72b57, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_a8e72b57, p_DefaultValue := p_DefaultValue_a8e72b57, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_a8e72b57, p_IsUniqueKey := p_IsUniqueKey_a8e72b57, p_IsReadOnly := p_IsReadOnly_a8e72b57, p_IsRequired := p_IsRequired_a8e72b57, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_a8e72b57, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_a8e72b57, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_a8e72b57, p_Configuration := p_Configuration_a8e72b57, p_Configuration_Clear := TRUE, p_Status := p_Status_a8e72b57, p_IsCustom := p_IsCustom_a8e72b57, p_MetadataSource := p_MetadataSource_a8e72b57);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_af6d5a99 UUID;
  p_IntegrationObjectID_af6d5a99 UUID;
  p_Name_af6d5a99 VARCHAR(255);
  p_DisplayName_af6d5a99 VARCHAR(255);
  p_Description_af6d5a99 TEXT;
  p_Category_af6d5a99 VARCHAR(100);
  p_Type_af6d5a99 VARCHAR(100);
  p_Length_af6d5a99 INTEGER;
  p_Precision_af6d5a99 INTEGER;
  p_Scale_af6d5a99 INTEGER;
  p_AllowsNull_af6d5a99 BOOLEAN;
  p_DefaultValue_af6d5a99 VARCHAR(255);
  p_IsPrimaryKey_af6d5a99 BOOLEAN;
  p_IsUniqueKey_af6d5a99 BOOLEAN;
  p_IsReadOnly_af6d5a99 BOOLEAN;
  p_IsRequired_af6d5a99 BOOLEAN;
  p_RelatedIntegrationObjectID_af6d5a99 UUID;
  p_RelatedIntegrationObjectFieldName_af6d5a99 VARCHAR(255);
  p_Sequence_af6d5a99 INTEGER;
  p_Configuration_af6d5a99 TEXT;
  p_Status_af6d5a99 VARCHAR(25);
  p_IsCustom_af6d5a99 BOOLEAN;
  p_MetadataSource_af6d5a99 VARCHAR(20);
BEGIN
  p_ID_af6d5a99 := '0242FB01-8E58-54CC-8E12-FE56A7006D7E';
  p_IntegrationObjectID_af6d5a99 := 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F';
  p_Name_af6d5a99 := 'source-name';
  p_DisplayName_af6d5a99 := 'Source Name';
  p_Description_af6d5a99 := 'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.';
  p_Type_af6d5a99 := 'String';
  p_Length_af6d5a99 := 500;
  p_AllowsNull_af6d5a99 := TRUE;
  p_IsPrimaryKey_af6d5a99 := FALSE;
  p_IsUniqueKey_af6d5a99 := FALSE;
  p_IsReadOnly_af6d5a99 := TRUE;
  p_IsRequired_af6d5a99 := FALSE;
  p_Sequence_af6d5a99 := 32;
  p_Status_af6d5a99 := 'Active';
  p_IsCustom_af6d5a99 := FALSE;
  p_MetadataSource_af6d5a99 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_af6d5a99, p_IntegrationObjectID := p_IntegrationObjectID_af6d5a99, p_Name := p_Name_af6d5a99, p_DisplayName := p_DisplayName_af6d5a99, p_Description := p_Description_af6d5a99, p_Category := p_Category_af6d5a99, p_Category_Clear := TRUE, p_Type := p_Type_af6d5a99, p_Length := p_Length_af6d5a99, p_Precision := p_Precision_af6d5a99, p_Precision_Clear := TRUE, p_Scale := p_Scale_af6d5a99, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_af6d5a99, p_DefaultValue := p_DefaultValue_af6d5a99, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_af6d5a99, p_IsUniqueKey := p_IsUniqueKey_af6d5a99, p_IsReadOnly := p_IsReadOnly_af6d5a99, p_IsRequired := p_IsRequired_af6d5a99, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_af6d5a99, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_af6d5a99, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_af6d5a99, p_Configuration := p_Configuration_af6d5a99, p_Configuration_Clear := TRUE, p_Status := p_Status_af6d5a99, p_IsCustom := p_IsCustom_af6d5a99, p_MetadataSource := p_MetadataSource_af6d5a99);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_c88d0b88 UUID;
  p_IntegrationObjectID_c88d0b88 UUID;
  p_Name_c88d0b88 VARCHAR(255);
  p_DisplayName_c88d0b88 VARCHAR(255);
  p_Description_c88d0b88 TEXT;
  p_Category_c88d0b88 VARCHAR(100);
  p_Type_c88d0b88 VARCHAR(100);
  p_Length_c88d0b88 INTEGER;
  p_Precision_c88d0b88 INTEGER;
  p_Scale_c88d0b88 INTEGER;
  p_AllowsNull_c88d0b88 BOOLEAN;
  p_DefaultValue_c88d0b88 VARCHAR(255);
  p_IsPrimaryKey_c88d0b88 BOOLEAN;
  p_IsUniqueKey_c88d0b88 BOOLEAN;
  p_IsReadOnly_c88d0b88 BOOLEAN;
  p_IsRequired_c88d0b88 BOOLEAN;
  p_RelatedIntegrationObjectID_c88d0b88 UUID;
  p_RelatedIntegrationObjectFieldName_c88d0b88 VARCHAR(255);
  p_Sequence_c88d0b88 INTEGER;
  p_Configuration_c88d0b88 TEXT;
  p_Status_c88d0b88 VARCHAR(25);
  p_IsCustom_c88d0b88 BOOLEAN;
  p_MetadataSource_c88d0b88 VARCHAR(20);
BEGIN
  p_ID_c88d0b88 := '1D008B82-38DE-572D-944D-D8AFF273CA2F';
  p_IntegrationObjectID_c88d0b88 := 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F';
  p_Name_c88d0b88 := 'source-orcid';
  p_DisplayName_c88d0b88 := 'Source Orcid';
  p_Description_c88d0b88 := 'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.';
  p_Type_c88d0b88 := 'String';
  p_Length_c88d0b88 := 19;
  p_AllowsNull_c88d0b88 := TRUE;
  p_IsPrimaryKey_c88d0b88 := FALSE;
  p_IsUniqueKey_c88d0b88 := FALSE;
  p_IsReadOnly_c88d0b88 := TRUE;
  p_IsRequired_c88d0b88 := FALSE;
  p_Sequence_c88d0b88 := 33;
  p_Status_c88d0b88 := 'Active';
  p_IsCustom_c88d0b88 := FALSE;
  p_MetadataSource_c88d0b88 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_c88d0b88, p_IntegrationObjectID := p_IntegrationObjectID_c88d0b88, p_Name := p_Name_c88d0b88, p_DisplayName := p_DisplayName_c88d0b88, p_Description := p_Description_c88d0b88, p_Category := p_Category_c88d0b88, p_Category_Clear := TRUE, p_Type := p_Type_c88d0b88, p_Length := p_Length_c88d0b88, p_Precision := p_Precision_c88d0b88, p_Precision_Clear := TRUE, p_Scale := p_Scale_c88d0b88, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_c88d0b88, p_DefaultValue := p_DefaultValue_c88d0b88, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_c88d0b88, p_IsUniqueKey := p_IsUniqueKey_c88d0b88, p_IsReadOnly := p_IsReadOnly_c88d0b88, p_IsRequired := p_IsRequired_c88d0b88, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_c88d0b88, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_c88d0b88, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_c88d0b88, p_Configuration := p_Configuration_c88d0b88, p_Configuration_Clear := TRUE, p_Status := p_Status_c88d0b88, p_IsCustom := p_IsCustom_c88d0b88, p_MetadataSource := p_MetadataSource_c88d0b88);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_c0b27ad3 UUID;
  p_IntegrationObjectID_c0b27ad3 UUID;
  p_Name_c0b27ad3 VARCHAR(255);
  p_DisplayName_c0b27ad3 VARCHAR(255);
  p_Description_c0b27ad3 TEXT;
  p_Category_c0b27ad3 VARCHAR(100);
  p_Type_c0b27ad3 VARCHAR(100);
  p_Length_c0b27ad3 INTEGER;
  p_Precision_c0b27ad3 INTEGER;
  p_Scale_c0b27ad3 INTEGER;
  p_AllowsNull_c0b27ad3 BOOLEAN;
  p_DefaultValue_c0b27ad3 VARCHAR(255);
  p_IsPrimaryKey_c0b27ad3 BOOLEAN;
  p_IsUniqueKey_c0b27ad3 BOOLEAN;
  p_IsReadOnly_c0b27ad3 BOOLEAN;
  p_IsRequired_c0b27ad3 BOOLEAN;
  p_RelatedIntegrationObjectID_c0b27ad3 UUID;
  p_RelatedIntegrationObjectFieldName_c0b27ad3 VARCHAR(255);
  p_Sequence_c0b27ad3 INTEGER;
  p_Configuration_c0b27ad3 TEXT;
  p_Status_c0b27ad3 VARCHAR(25);
  p_IsCustom_c0b27ad3 BOOLEAN;
  p_MetadataSource_c0b27ad3 VARCHAR(20);
BEGIN
  p_ID_c0b27ad3 := '86D9204D-3B0F-512A-A920-98258D862CB9';
  p_IntegrationObjectID_c0b27ad3 := 'E52B947C-796A-46F1-BD69-BD9CD92FA046';
  p_Name_c0b27ad3 := 'resource-title';
  p_DisplayName_c0b27ad3 := 'Resource Title';
  p_Description_c0b27ad3 := 'Title of the research resource proposal. Lifted from proposal.title.title.';
  p_Type_c0b27ad3 := 'String';
  p_Length_c0b27ad3 := 2000;
  p_AllowsNull_c0b27ad3 := TRUE;
  p_IsPrimaryKey_c0b27ad3 := FALSE;
  p_IsUniqueKey_c0b27ad3 := FALSE;
  p_IsReadOnly_c0b27ad3 := TRUE;
  p_IsRequired_c0b27ad3 := FALSE;
  p_Sequence_c0b27ad3 := 10;
  p_Status_c0b27ad3 := 'Active';
  p_IsCustom_c0b27ad3 := FALSE;
  p_MetadataSource_c0b27ad3 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_c0b27ad3, p_IntegrationObjectID := p_IntegrationObjectID_c0b27ad3, p_Name := p_Name_c0b27ad3, p_DisplayName := p_DisplayName_c0b27ad3, p_Description := p_Description_c0b27ad3, p_Category := p_Category_c0b27ad3, p_Category_Clear := TRUE, p_Type := p_Type_c0b27ad3, p_Length := p_Length_c0b27ad3, p_Precision := p_Precision_c0b27ad3, p_Precision_Clear := TRUE, p_Scale := p_Scale_c0b27ad3, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_c0b27ad3, p_DefaultValue := p_DefaultValue_c0b27ad3, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_c0b27ad3, p_IsUniqueKey := p_IsUniqueKey_c0b27ad3, p_IsReadOnly := p_IsReadOnly_c0b27ad3, p_IsRequired := p_IsRequired_c0b27ad3, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_c0b27ad3, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_c0b27ad3, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_c0b27ad3, p_Configuration := p_Configuration_c0b27ad3, p_Configuration_Clear := TRUE, p_Status := p_Status_c0b27ad3, p_IsCustom := p_IsCustom_c0b27ad3, p_MetadataSource := p_MetadataSource_c0b27ad3);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_fcf0c49a UUID;
  p_IntegrationObjectID_fcf0c49a UUID;
  p_Name_fcf0c49a VARCHAR(255);
  p_DisplayName_fcf0c49a VARCHAR(255);
  p_Description_fcf0c49a TEXT;
  p_Category_fcf0c49a VARCHAR(100);
  p_Type_fcf0c49a VARCHAR(100);
  p_Length_fcf0c49a INTEGER;
  p_Precision_fcf0c49a INTEGER;
  p_Scale_fcf0c49a INTEGER;
  p_AllowsNull_fcf0c49a BOOLEAN;
  p_DefaultValue_fcf0c49a VARCHAR(255);
  p_IsPrimaryKey_fcf0c49a BOOLEAN;
  p_IsUniqueKey_fcf0c49a BOOLEAN;
  p_IsReadOnly_fcf0c49a BOOLEAN;
  p_IsRequired_fcf0c49a BOOLEAN;
  p_RelatedIntegrationObjectID_fcf0c49a UUID;
  p_RelatedIntegrationObjectFieldName_fcf0c49a VARCHAR(255);
  p_Sequence_fcf0c49a INTEGER;
  p_Configuration_fcf0c49a TEXT;
  p_Status_fcf0c49a VARCHAR(25);
  p_IsCustom_fcf0c49a BOOLEAN;
  p_MetadataSource_fcf0c49a VARCHAR(20);
BEGIN
  p_ID_fcf0c49a := 'EE974AAD-533B-5241-98D7-4F16AC881A44';
  p_IntegrationObjectID_fcf0c49a := 'E52B947C-796A-46F1-BD69-BD9CD92FA046';
  p_Name_fcf0c49a := 'url';
  p_DisplayName_fcf0c49a := 'Url';
  p_Description_fcf0c49a := 'URL of the proposal. Lifted from proposal.url.';
  p_Type_fcf0c49a := 'String';
  p_Length_fcf0c49a := 2048;
  p_AllowsNull_fcf0c49a := TRUE;
  p_IsPrimaryKey_fcf0c49a := FALSE;
  p_IsUniqueKey_fcf0c49a := FALSE;
  p_IsReadOnly_fcf0c49a := TRUE;
  p_IsRequired_fcf0c49a := FALSE;
  p_Sequence_fcf0c49a := 11;
  p_Status_fcf0c49a := 'Active';
  p_IsCustom_fcf0c49a := FALSE;
  p_MetadataSource_fcf0c49a := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_fcf0c49a, p_IntegrationObjectID := p_IntegrationObjectID_fcf0c49a, p_Name := p_Name_fcf0c49a, p_DisplayName := p_DisplayName_fcf0c49a, p_Description := p_Description_fcf0c49a, p_Category := p_Category_fcf0c49a, p_Category_Clear := TRUE, p_Type := p_Type_fcf0c49a, p_Length := p_Length_fcf0c49a, p_Precision := p_Precision_fcf0c49a, p_Precision_Clear := TRUE, p_Scale := p_Scale_fcf0c49a, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_fcf0c49a, p_DefaultValue := p_DefaultValue_fcf0c49a, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_fcf0c49a, p_IsUniqueKey := p_IsUniqueKey_fcf0c49a, p_IsReadOnly := p_IsReadOnly_fcf0c49a, p_IsRequired := p_IsRequired_fcf0c49a, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_fcf0c49a, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_fcf0c49a, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_fcf0c49a, p_Configuration := p_Configuration_fcf0c49a, p_Configuration_Clear := TRUE, p_Status := p_Status_fcf0c49a, p_IsCustom := p_IsCustom_fcf0c49a, p_MetadataSource := p_MetadataSource_fcf0c49a);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_d3a2005f UUID;
  p_IntegrationObjectID_d3a2005f UUID;
  p_Name_d3a2005f VARCHAR(255);
  p_DisplayName_d3a2005f VARCHAR(255);
  p_Description_d3a2005f TEXT;
  p_Category_d3a2005f VARCHAR(100);
  p_Type_d3a2005f VARCHAR(100);
  p_Length_d3a2005f INTEGER;
  p_Precision_d3a2005f INTEGER;
  p_Scale_d3a2005f INTEGER;
  p_AllowsNull_d3a2005f BOOLEAN;
  p_DefaultValue_d3a2005f VARCHAR(255);
  p_IsPrimaryKey_d3a2005f BOOLEAN;
  p_IsUniqueKey_d3a2005f BOOLEAN;
  p_IsReadOnly_d3a2005f BOOLEAN;
  p_IsRequired_d3a2005f BOOLEAN;
  p_RelatedIntegrationObjectID_d3a2005f UUID;
  p_RelatedIntegrationObjectFieldName_d3a2005f VARCHAR(255);
  p_Sequence_d3a2005f INTEGER;
  p_Configuration_d3a2005f TEXT;
  p_Status_d3a2005f VARCHAR(25);
  p_IsCustom_d3a2005f BOOLEAN;
  p_MetadataSource_d3a2005f VARCHAR(20);
BEGIN
  p_ID_d3a2005f := '5B33A300-02B7-5CC7-9398-B847B02AF9B0';
  p_IntegrationObjectID_d3a2005f := 'E52B947C-796A-46F1-BD69-BD9CD92FA046';
  p_Name_d3a2005f := 'start-year';
  p_DisplayName_d3a2005f := 'Start Year';
  p_Description_d3a2005f := 'Year of the proposal start date; ORCID dates are partial, so month/day may be absent.';
  p_Type_d3a2005f := 'Integer';
  p_AllowsNull_d3a2005f := TRUE;
  p_IsPrimaryKey_d3a2005f := FALSE;
  p_IsUniqueKey_d3a2005f := FALSE;
  p_IsReadOnly_d3a2005f := TRUE;
  p_IsRequired_d3a2005f := FALSE;
  p_Sequence_d3a2005f := 12;
  p_Status_d3a2005f := 'Active';
  p_IsCustom_d3a2005f := FALSE;
  p_MetadataSource_d3a2005f := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_d3a2005f, p_IntegrationObjectID := p_IntegrationObjectID_d3a2005f, p_Name := p_Name_d3a2005f, p_DisplayName := p_DisplayName_d3a2005f, p_Description := p_Description_d3a2005f, p_Category := p_Category_d3a2005f, p_Category_Clear := TRUE, p_Type := p_Type_d3a2005f, p_Length := p_Length_d3a2005f, p_Length_Clear := TRUE, p_Precision := p_Precision_d3a2005f, p_Precision_Clear := TRUE, p_Scale := p_Scale_d3a2005f, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_d3a2005f, p_DefaultValue := p_DefaultValue_d3a2005f, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_d3a2005f, p_IsUniqueKey := p_IsUniqueKey_d3a2005f, p_IsReadOnly := p_IsReadOnly_d3a2005f, p_IsRequired := p_IsRequired_d3a2005f, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_d3a2005f, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_d3a2005f, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_d3a2005f, p_Configuration := p_Configuration_d3a2005f, p_Configuration_Clear := TRUE, p_Status := p_Status_d3a2005f, p_IsCustom := p_IsCustom_d3a2005f, p_MetadataSource := p_MetadataSource_d3a2005f);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_99150aba UUID;
  p_IntegrationObjectID_99150aba UUID;
  p_Name_99150aba VARCHAR(255);
  p_DisplayName_99150aba VARCHAR(255);
  p_Description_99150aba TEXT;
  p_Category_99150aba VARCHAR(100);
  p_Type_99150aba VARCHAR(100);
  p_Length_99150aba INTEGER;
  p_Precision_99150aba INTEGER;
  p_Scale_99150aba INTEGER;
  p_AllowsNull_99150aba BOOLEAN;
  p_DefaultValue_99150aba VARCHAR(255);
  p_IsPrimaryKey_99150aba BOOLEAN;
  p_IsUniqueKey_99150aba BOOLEAN;
  p_IsReadOnly_99150aba BOOLEAN;
  p_IsRequired_99150aba BOOLEAN;
  p_RelatedIntegrationObjectID_99150aba UUID;
  p_RelatedIntegrationObjectFieldName_99150aba VARCHAR(255);
  p_Sequence_99150aba INTEGER;
  p_Configuration_99150aba TEXT;
  p_Status_99150aba VARCHAR(25);
  p_IsCustom_99150aba BOOLEAN;
  p_MetadataSource_99150aba VARCHAR(20);
BEGIN
  p_ID_99150aba := '250ED149-786A-57B7-BE06-CE9DEC3052BA';
  p_IntegrationObjectID_99150aba := 'E52B947C-796A-46F1-BD69-BD9CD92FA046';
  p_Name_99150aba := 'start-month';
  p_DisplayName_99150aba := 'Start Month';
  p_Description_99150aba := 'Month (1-12) of the proposal start date, when given.';
  p_Type_99150aba := 'Integer';
  p_AllowsNull_99150aba := TRUE;
  p_IsPrimaryKey_99150aba := FALSE;
  p_IsUniqueKey_99150aba := FALSE;
  p_IsReadOnly_99150aba := TRUE;
  p_IsRequired_99150aba := FALSE;
  p_Sequence_99150aba := 13;
  p_Status_99150aba := 'Active';
  p_IsCustom_99150aba := FALSE;
  p_MetadataSource_99150aba := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_99150aba, p_IntegrationObjectID := p_IntegrationObjectID_99150aba, p_Name := p_Name_99150aba, p_DisplayName := p_DisplayName_99150aba, p_Description := p_Description_99150aba, p_Category := p_Category_99150aba, p_Category_Clear := TRUE, p_Type := p_Type_99150aba, p_Length := p_Length_99150aba, p_Length_Clear := TRUE, p_Precision := p_Precision_99150aba, p_Precision_Clear := TRUE, p_Scale := p_Scale_99150aba, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_99150aba, p_DefaultValue := p_DefaultValue_99150aba, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_99150aba, p_IsUniqueKey := p_IsUniqueKey_99150aba, p_IsReadOnly := p_IsReadOnly_99150aba, p_IsRequired := p_IsRequired_99150aba, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_99150aba, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_99150aba, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_99150aba, p_Configuration := p_Configuration_99150aba, p_Configuration_Clear := TRUE, p_Status := p_Status_99150aba, p_IsCustom := p_IsCustom_99150aba, p_MetadataSource := p_MetadataSource_99150aba);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_71cc496d UUID;
  p_IntegrationObjectID_71cc496d UUID;
  p_Name_71cc496d VARCHAR(255);
  p_DisplayName_71cc496d VARCHAR(255);
  p_Description_71cc496d TEXT;
  p_Category_71cc496d VARCHAR(100);
  p_Type_71cc496d VARCHAR(100);
  p_Length_71cc496d INTEGER;
  p_Precision_71cc496d INTEGER;
  p_Scale_71cc496d INTEGER;
  p_AllowsNull_71cc496d BOOLEAN;
  p_DefaultValue_71cc496d VARCHAR(255);
  p_IsPrimaryKey_71cc496d BOOLEAN;
  p_IsUniqueKey_71cc496d BOOLEAN;
  p_IsReadOnly_71cc496d BOOLEAN;
  p_IsRequired_71cc496d BOOLEAN;
  p_RelatedIntegrationObjectID_71cc496d UUID;
  p_RelatedIntegrationObjectFieldName_71cc496d VARCHAR(255);
  p_Sequence_71cc496d INTEGER;
  p_Configuration_71cc496d TEXT;
  p_Status_71cc496d VARCHAR(25);
  p_IsCustom_71cc496d BOOLEAN;
  p_MetadataSource_71cc496d VARCHAR(20);
BEGIN
  p_ID_71cc496d := 'ED354A92-1457-569D-B3E8-6E4F290EC949';
  p_IntegrationObjectID_71cc496d := 'E52B947C-796A-46F1-BD69-BD9CD92FA046';
  p_Name_71cc496d := 'start-day';
  p_DisplayName_71cc496d := 'Start Day';
  p_Description_71cc496d := 'Day of month of the proposal start date, when given.';
  p_Type_71cc496d := 'Integer';
  p_AllowsNull_71cc496d := TRUE;
  p_IsPrimaryKey_71cc496d := FALSE;
  p_IsUniqueKey_71cc496d := FALSE;
  p_IsReadOnly_71cc496d := TRUE;
  p_IsRequired_71cc496d := FALSE;
  p_Sequence_71cc496d := 14;
  p_Status_71cc496d := 'Active';
  p_IsCustom_71cc496d := FALSE;
  p_MetadataSource_71cc496d := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_71cc496d, p_IntegrationObjectID := p_IntegrationObjectID_71cc496d, p_Name := p_Name_71cc496d, p_DisplayName := p_DisplayName_71cc496d, p_Description := p_Description_71cc496d, p_Category := p_Category_71cc496d, p_Category_Clear := TRUE, p_Type := p_Type_71cc496d, p_Length := p_Length_71cc496d, p_Length_Clear := TRUE, p_Precision := p_Precision_71cc496d, p_Precision_Clear := TRUE, p_Scale := p_Scale_71cc496d, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_71cc496d, p_DefaultValue := p_DefaultValue_71cc496d, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_71cc496d, p_IsUniqueKey := p_IsUniqueKey_71cc496d, p_IsReadOnly := p_IsReadOnly_71cc496d, p_IsRequired := p_IsRequired_71cc496d, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_71cc496d, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_71cc496d, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_71cc496d, p_Configuration := p_Configuration_71cc496d, p_Configuration_Clear := TRUE, p_Status := p_Status_71cc496d, p_IsCustom := p_IsCustom_71cc496d, p_MetadataSource := p_MetadataSource_71cc496d);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_e5382c9a UUID;
  p_IntegrationObjectID_e5382c9a UUID;
  p_Name_e5382c9a VARCHAR(255);
  p_DisplayName_e5382c9a VARCHAR(255);
  p_Description_e5382c9a TEXT;
  p_Category_e5382c9a VARCHAR(100);
  p_Type_e5382c9a VARCHAR(100);
  p_Length_e5382c9a INTEGER;
  p_Precision_e5382c9a INTEGER;
  p_Scale_e5382c9a INTEGER;
  p_AllowsNull_e5382c9a BOOLEAN;
  p_DefaultValue_e5382c9a VARCHAR(255);
  p_IsPrimaryKey_e5382c9a BOOLEAN;
  p_IsUniqueKey_e5382c9a BOOLEAN;
  p_IsReadOnly_e5382c9a BOOLEAN;
  p_IsRequired_e5382c9a BOOLEAN;
  p_RelatedIntegrationObjectID_e5382c9a UUID;
  p_RelatedIntegrationObjectFieldName_e5382c9a VARCHAR(255);
  p_Sequence_e5382c9a INTEGER;
  p_Configuration_e5382c9a TEXT;
  p_Status_e5382c9a VARCHAR(25);
  p_IsCustom_e5382c9a BOOLEAN;
  p_MetadataSource_e5382c9a VARCHAR(20);
BEGIN
  p_ID_e5382c9a := '0FF94BE2-B88A-52F0-93FA-207005177D21';
  p_IntegrationObjectID_e5382c9a := 'E52B947C-796A-46F1-BD69-BD9CD92FA046';
  p_Name_e5382c9a := 'end-year';
  p_DisplayName_e5382c9a := 'End Year';
  p_Description_e5382c9a := 'Year of the proposal end date; ORCID dates are partial, so month/day may be absent.';
  p_Type_e5382c9a := 'Integer';
  p_AllowsNull_e5382c9a := TRUE;
  p_IsPrimaryKey_e5382c9a := FALSE;
  p_IsUniqueKey_e5382c9a := FALSE;
  p_IsReadOnly_e5382c9a := TRUE;
  p_IsRequired_e5382c9a := FALSE;
  p_Sequence_e5382c9a := 15;
  p_Status_e5382c9a := 'Active';
  p_IsCustom_e5382c9a := FALSE;
  p_MetadataSource_e5382c9a := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_e5382c9a, p_IntegrationObjectID := p_IntegrationObjectID_e5382c9a, p_Name := p_Name_e5382c9a, p_DisplayName := p_DisplayName_e5382c9a, p_Description := p_Description_e5382c9a, p_Category := p_Category_e5382c9a, p_Category_Clear := TRUE, p_Type := p_Type_e5382c9a, p_Length := p_Length_e5382c9a, p_Length_Clear := TRUE, p_Precision := p_Precision_e5382c9a, p_Precision_Clear := TRUE, p_Scale := p_Scale_e5382c9a, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_e5382c9a, p_DefaultValue := p_DefaultValue_e5382c9a, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_e5382c9a, p_IsUniqueKey := p_IsUniqueKey_e5382c9a, p_IsReadOnly := p_IsReadOnly_e5382c9a, p_IsRequired := p_IsRequired_e5382c9a, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_e5382c9a, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_e5382c9a, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_e5382c9a, p_Configuration := p_Configuration_e5382c9a, p_Configuration_Clear := TRUE, p_Status := p_Status_e5382c9a, p_IsCustom := p_IsCustom_e5382c9a, p_MetadataSource := p_MetadataSource_e5382c9a);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_91651b40 UUID;
  p_IntegrationObjectID_91651b40 UUID;
  p_Name_91651b40 VARCHAR(255);
  p_DisplayName_91651b40 VARCHAR(255);
  p_Description_91651b40 TEXT;
  p_Category_91651b40 VARCHAR(100);
  p_Type_91651b40 VARCHAR(100);
  p_Length_91651b40 INTEGER;
  p_Precision_91651b40 INTEGER;
  p_Scale_91651b40 INTEGER;
  p_AllowsNull_91651b40 BOOLEAN;
  p_DefaultValue_91651b40 VARCHAR(255);
  p_IsPrimaryKey_91651b40 BOOLEAN;
  p_IsUniqueKey_91651b40 BOOLEAN;
  p_IsReadOnly_91651b40 BOOLEAN;
  p_IsRequired_91651b40 BOOLEAN;
  p_RelatedIntegrationObjectID_91651b40 UUID;
  p_RelatedIntegrationObjectFieldName_91651b40 VARCHAR(255);
  p_Sequence_91651b40 INTEGER;
  p_Configuration_91651b40 TEXT;
  p_Status_91651b40 VARCHAR(25);
  p_IsCustom_91651b40 BOOLEAN;
  p_MetadataSource_91651b40 VARCHAR(20);
BEGIN
  p_ID_91651b40 := 'BBD57D1A-B48C-5C67-A43C-BD6EF9E1302D';
  p_IntegrationObjectID_91651b40 := 'E52B947C-796A-46F1-BD69-BD9CD92FA046';
  p_Name_91651b40 := 'end-month';
  p_DisplayName_91651b40 := 'End Month';
  p_Description_91651b40 := 'Month (1-12) of the proposal end date, when given.';
  p_Type_91651b40 := 'Integer';
  p_AllowsNull_91651b40 := TRUE;
  p_IsPrimaryKey_91651b40 := FALSE;
  p_IsUniqueKey_91651b40 := FALSE;
  p_IsReadOnly_91651b40 := TRUE;
  p_IsRequired_91651b40 := FALSE;
  p_Sequence_91651b40 := 16;
  p_Status_91651b40 := 'Active';
  p_IsCustom_91651b40 := FALSE;
  p_MetadataSource_91651b40 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_91651b40, p_IntegrationObjectID := p_IntegrationObjectID_91651b40, p_Name := p_Name_91651b40, p_DisplayName := p_DisplayName_91651b40, p_Description := p_Description_91651b40, p_Category := p_Category_91651b40, p_Category_Clear := TRUE, p_Type := p_Type_91651b40, p_Length := p_Length_91651b40, p_Length_Clear := TRUE, p_Precision := p_Precision_91651b40, p_Precision_Clear := TRUE, p_Scale := p_Scale_91651b40, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_91651b40, p_DefaultValue := p_DefaultValue_91651b40, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_91651b40, p_IsUniqueKey := p_IsUniqueKey_91651b40, p_IsReadOnly := p_IsReadOnly_91651b40, p_IsRequired := p_IsRequired_91651b40, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_91651b40, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_91651b40, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_91651b40, p_Configuration := p_Configuration_91651b40, p_Configuration_Clear := TRUE, p_Status := p_Status_91651b40, p_IsCustom := p_IsCustom_91651b40, p_MetadataSource := p_MetadataSource_91651b40);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_700a6b9f UUID;
  p_IntegrationObjectID_700a6b9f UUID;
  p_Name_700a6b9f VARCHAR(255);
  p_DisplayName_700a6b9f VARCHAR(255);
  p_Description_700a6b9f TEXT;
  p_Category_700a6b9f VARCHAR(100);
  p_Type_700a6b9f VARCHAR(100);
  p_Length_700a6b9f INTEGER;
  p_Precision_700a6b9f INTEGER;
  p_Scale_700a6b9f INTEGER;
  p_AllowsNull_700a6b9f BOOLEAN;
  p_DefaultValue_700a6b9f VARCHAR(255);
  p_IsPrimaryKey_700a6b9f BOOLEAN;
  p_IsUniqueKey_700a6b9f BOOLEAN;
  p_IsReadOnly_700a6b9f BOOLEAN;
  p_IsRequired_700a6b9f BOOLEAN;
  p_RelatedIntegrationObjectID_700a6b9f UUID;
  p_RelatedIntegrationObjectFieldName_700a6b9f VARCHAR(255);
  p_Sequence_700a6b9f INTEGER;
  p_Configuration_700a6b9f TEXT;
  p_Status_700a6b9f VARCHAR(25);
  p_IsCustom_700a6b9f BOOLEAN;
  p_MetadataSource_700a6b9f VARCHAR(20);
BEGIN
  p_ID_700a6b9f := '5E5AF098-28E7-5858-B690-0D9D3045E209';
  p_IntegrationObjectID_700a6b9f := 'E52B947C-796A-46F1-BD69-BD9CD92FA046';
  p_Name_700a6b9f := 'end-day';
  p_DisplayName_700a6b9f := 'End Day';
  p_Description_700a6b9f := 'Day of month of the proposal end date, when given.';
  p_Type_700a6b9f := 'Integer';
  p_AllowsNull_700a6b9f := TRUE;
  p_IsPrimaryKey_700a6b9f := FALSE;
  p_IsUniqueKey_700a6b9f := FALSE;
  p_IsReadOnly_700a6b9f := TRUE;
  p_IsRequired_700a6b9f := FALSE;
  p_Sequence_700a6b9f := 17;
  p_Status_700a6b9f := 'Active';
  p_IsCustom_700a6b9f := FALSE;
  p_MetadataSource_700a6b9f := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_700a6b9f, p_IntegrationObjectID := p_IntegrationObjectID_700a6b9f, p_Name := p_Name_700a6b9f, p_DisplayName := p_DisplayName_700a6b9f, p_Description := p_Description_700a6b9f, p_Category := p_Category_700a6b9f, p_Category_Clear := TRUE, p_Type := p_Type_700a6b9f, p_Length := p_Length_700a6b9f, p_Length_Clear := TRUE, p_Precision := p_Precision_700a6b9f, p_Precision_Clear := TRUE, p_Scale := p_Scale_700a6b9f, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_700a6b9f, p_DefaultValue := p_DefaultValue_700a6b9f, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_700a6b9f, p_IsUniqueKey := p_IsUniqueKey_700a6b9f, p_IsReadOnly := p_IsReadOnly_700a6b9f, p_IsRequired := p_IsRequired_700a6b9f, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_700a6b9f, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_700a6b9f, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_700a6b9f, p_Configuration := p_Configuration_700a6b9f, p_Configuration_Clear := TRUE, p_Status := p_Status_700a6b9f, p_IsCustom := p_IsCustom_700a6b9f, p_MetadataSource := p_MetadataSource_700a6b9f);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_6ffebd1e UUID;
  p_IntegrationObjectID_6ffebd1e UUID;
  p_Name_6ffebd1e VARCHAR(255);
  p_DisplayName_6ffebd1e VARCHAR(255);
  p_Description_6ffebd1e TEXT;
  p_Category_6ffebd1e VARCHAR(100);
  p_Type_6ffebd1e VARCHAR(100);
  p_Length_6ffebd1e INTEGER;
  p_Precision_6ffebd1e INTEGER;
  p_Scale_6ffebd1e INTEGER;
  p_AllowsNull_6ffebd1e BOOLEAN;
  p_DefaultValue_6ffebd1e VARCHAR(255);
  p_IsPrimaryKey_6ffebd1e BOOLEAN;
  p_IsUniqueKey_6ffebd1e BOOLEAN;
  p_IsReadOnly_6ffebd1e BOOLEAN;
  p_IsRequired_6ffebd1e BOOLEAN;
  p_RelatedIntegrationObjectID_6ffebd1e UUID;
  p_RelatedIntegrationObjectFieldName_6ffebd1e VARCHAR(255);
  p_Sequence_6ffebd1e INTEGER;
  p_Configuration_6ffebd1e TEXT;
  p_Status_6ffebd1e VARCHAR(25);
  p_IsCustom_6ffebd1e BOOLEAN;
  p_MetadataSource_6ffebd1e VARCHAR(20);
BEGIN
  p_ID_6ffebd1e := 'E4C3DA8B-2D1D-5C1F-8B58-E796EB85FF02';
  p_IntegrationObjectID_6ffebd1e := 'E52B947C-796A-46F1-BD69-BD9CD92FA046';
  p_Name_6ffebd1e := 'source-name';
  p_DisplayName_6ffebd1e := 'Source Name';
  p_Description_6ffebd1e := 'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.';
  p_Type_6ffebd1e := 'String';
  p_Length_6ffebd1e := 500;
  p_AllowsNull_6ffebd1e := TRUE;
  p_IsPrimaryKey_6ffebd1e := FALSE;
  p_IsUniqueKey_6ffebd1e := FALSE;
  p_IsReadOnly_6ffebd1e := TRUE;
  p_IsRequired_6ffebd1e := FALSE;
  p_Sequence_6ffebd1e := 18;
  p_Status_6ffebd1e := 'Active';
  p_IsCustom_6ffebd1e := FALSE;
  p_MetadataSource_6ffebd1e := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_6ffebd1e, p_IntegrationObjectID := p_IntegrationObjectID_6ffebd1e, p_Name := p_Name_6ffebd1e, p_DisplayName := p_DisplayName_6ffebd1e, p_Description := p_Description_6ffebd1e, p_Category := p_Category_6ffebd1e, p_Category_Clear := TRUE, p_Type := p_Type_6ffebd1e, p_Length := p_Length_6ffebd1e, p_Precision := p_Precision_6ffebd1e, p_Precision_Clear := TRUE, p_Scale := p_Scale_6ffebd1e, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_6ffebd1e, p_DefaultValue := p_DefaultValue_6ffebd1e, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_6ffebd1e, p_IsUniqueKey := p_IsUniqueKey_6ffebd1e, p_IsReadOnly := p_IsReadOnly_6ffebd1e, p_IsRequired := p_IsRequired_6ffebd1e, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_6ffebd1e, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_6ffebd1e, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_6ffebd1e, p_Configuration := p_Configuration_6ffebd1e, p_Configuration_Clear := TRUE, p_Status := p_Status_6ffebd1e, p_IsCustom := p_IsCustom_6ffebd1e, p_MetadataSource := p_MetadataSource_6ffebd1e);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_784a4b32 UUID;
  p_IntegrationObjectID_784a4b32 UUID;
  p_Name_784a4b32 VARCHAR(255);
  p_DisplayName_784a4b32 VARCHAR(255);
  p_Description_784a4b32 TEXT;
  p_Category_784a4b32 VARCHAR(100);
  p_Type_784a4b32 VARCHAR(100);
  p_Length_784a4b32 INTEGER;
  p_Precision_784a4b32 INTEGER;
  p_Scale_784a4b32 INTEGER;
  p_AllowsNull_784a4b32 BOOLEAN;
  p_DefaultValue_784a4b32 VARCHAR(255);
  p_IsPrimaryKey_784a4b32 BOOLEAN;
  p_IsUniqueKey_784a4b32 BOOLEAN;
  p_IsReadOnly_784a4b32 BOOLEAN;
  p_IsRequired_784a4b32 BOOLEAN;
  p_RelatedIntegrationObjectID_784a4b32 UUID;
  p_RelatedIntegrationObjectFieldName_784a4b32 VARCHAR(255);
  p_Sequence_784a4b32 INTEGER;
  p_Configuration_784a4b32 TEXT;
  p_Status_784a4b32 VARCHAR(25);
  p_IsCustom_784a4b32 BOOLEAN;
  p_MetadataSource_784a4b32 VARCHAR(20);
BEGIN
  p_ID_784a4b32 := 'D8F92718-61FC-5669-B79C-39DC922AFB07';
  p_IntegrationObjectID_784a4b32 := 'E52B947C-796A-46F1-BD69-BD9CD92FA046';
  p_Name_784a4b32 := 'source-orcid';
  p_DisplayName_784a4b32 := 'Source Orcid';
  p_Description_784a4b32 := 'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.';
  p_Type_784a4b32 := 'String';
  p_Length_784a4b32 := 19;
  p_AllowsNull_784a4b32 := TRUE;
  p_IsPrimaryKey_784a4b32 := FALSE;
  p_IsUniqueKey_784a4b32 := FALSE;
  p_IsReadOnly_784a4b32 := TRUE;
  p_IsRequired_784a4b32 := FALSE;
  p_Sequence_784a4b32 := 19;
  p_Status_784a4b32 := 'Active';
  p_IsCustom_784a4b32 := FALSE;
  p_MetadataSource_784a4b32 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_784a4b32, p_IntegrationObjectID := p_IntegrationObjectID_784a4b32, p_Name := p_Name_784a4b32, p_DisplayName := p_DisplayName_784a4b32, p_Description := p_Description_784a4b32, p_Category := p_Category_784a4b32, p_Category_Clear := TRUE, p_Type := p_Type_784a4b32, p_Length := p_Length_784a4b32, p_Precision := p_Precision_784a4b32, p_Precision_Clear := TRUE, p_Scale := p_Scale_784a4b32, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_784a4b32, p_DefaultValue := p_DefaultValue_784a4b32, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_784a4b32, p_IsUniqueKey := p_IsUniqueKey_784a4b32, p_IsReadOnly := p_IsReadOnly_784a4b32, p_IsRequired := p_IsRequired_784a4b32, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_784a4b32, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_784a4b32, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_784a4b32, p_Configuration := p_Configuration_784a4b32, p_Configuration_Clear := TRUE, p_Status := p_Status_784a4b32, p_IsCustom := p_IsCustom_784a4b32, p_MetadataSource := p_MetadataSource_784a4b32);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_0e04bfe4 UUID;
  p_IntegrationObjectID_0e04bfe4 UUID;
  p_Name_0e04bfe4 VARCHAR(255);
  p_DisplayName_0e04bfe4 VARCHAR(255);
  p_Description_0e04bfe4 TEXT;
  p_Category_0e04bfe4 VARCHAR(100);
  p_Type_0e04bfe4 VARCHAR(100);
  p_Length_0e04bfe4 INTEGER;
  p_Precision_0e04bfe4 INTEGER;
  p_Scale_0e04bfe4 INTEGER;
  p_AllowsNull_0e04bfe4 BOOLEAN;
  p_DefaultValue_0e04bfe4 VARCHAR(255);
  p_IsPrimaryKey_0e04bfe4 BOOLEAN;
  p_IsUniqueKey_0e04bfe4 BOOLEAN;
  p_IsReadOnly_0e04bfe4 BOOLEAN;
  p_IsRequired_0e04bfe4 BOOLEAN;
  p_RelatedIntegrationObjectID_0e04bfe4 UUID;
  p_RelatedIntegrationObjectFieldName_0e04bfe4 VARCHAR(255);
  p_Sequence_0e04bfe4 INTEGER;
  p_Configuration_0e04bfe4 TEXT;
  p_Status_0e04bfe4 VARCHAR(25);
  p_IsCustom_0e04bfe4 BOOLEAN;
  p_MetadataSource_0e04bfe4 VARCHAR(20);
BEGIN
  p_ID_0e04bfe4 := '84A2062C-C5CA-5059-9EF9-FE8A49A17237';
  p_IntegrationObjectID_0e04bfe4 := 'D4B4DBBD-FF1E-5147-8602-A41DC2855CE5';
  p_Name_0e04bfe4 := 'orcid-id';
  p_DisplayName_0e04bfe4 := 'Orcid Id';
  p_Description_0e04bfe4 := 'The ORCID iD of the researcher this item belongs to. Foreign key to the record object.';
  p_Type_0e04bfe4 := 'String';
  p_Length_0e04bfe4 := 19;
  p_AllowsNull_0e04bfe4 := TRUE;
  p_IsPrimaryKey_0e04bfe4 := FALSE;
  p_IsUniqueKey_0e04bfe4 := FALSE;
  p_IsReadOnly_0e04bfe4 := TRUE;
  p_IsRequired_0e04bfe4 := TRUE;
  p_RelatedIntegrationObjectID_0e04bfe4 := '73AED6B8-468D-403B-B994-F3C786C98BC0';
  p_RelatedIntegrationObjectFieldName_0e04bfe4 := 'orcid-id';
  p_Sequence_0e04bfe4 := 0;
  p_Status_0e04bfe4 := 'Active';
  p_IsCustom_0e04bfe4 := FALSE;
  p_MetadataSource_0e04bfe4 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_0e04bfe4, p_IntegrationObjectID := p_IntegrationObjectID_0e04bfe4, p_Name := p_Name_0e04bfe4, p_DisplayName := p_DisplayName_0e04bfe4, p_Description := p_Description_0e04bfe4, p_Category := p_Category_0e04bfe4, p_Category_Clear := TRUE, p_Type := p_Type_0e04bfe4, p_Length := p_Length_0e04bfe4, p_Precision := p_Precision_0e04bfe4, p_Precision_Clear := TRUE, p_Scale := p_Scale_0e04bfe4, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_0e04bfe4, p_DefaultValue := p_DefaultValue_0e04bfe4, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_0e04bfe4, p_IsUniqueKey := p_IsUniqueKey_0e04bfe4, p_IsReadOnly := p_IsReadOnly_0e04bfe4, p_IsRequired := p_IsRequired_0e04bfe4, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_0e04bfe4, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_0e04bfe4, p_Sequence := p_Sequence_0e04bfe4, p_Configuration := p_Configuration_0e04bfe4, p_Configuration_Clear := TRUE, p_Status := p_Status_0e04bfe4, p_IsCustom := p_IsCustom_0e04bfe4, p_MetadataSource := p_MetadataSource_0e04bfe4);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_5b18ad61 UUID;
  p_IntegrationObjectID_5b18ad61 UUID;
  p_Name_5b18ad61 VARCHAR(255);
  p_DisplayName_5b18ad61 VARCHAR(255);
  p_Description_5b18ad61 TEXT;
  p_Category_5b18ad61 VARCHAR(100);
  p_Type_5b18ad61 VARCHAR(100);
  p_Length_5b18ad61 INTEGER;
  p_Precision_5b18ad61 INTEGER;
  p_Scale_5b18ad61 INTEGER;
  p_AllowsNull_5b18ad61 BOOLEAN;
  p_DefaultValue_5b18ad61 VARCHAR(255);
  p_IsPrimaryKey_5b18ad61 BOOLEAN;
  p_IsUniqueKey_5b18ad61 BOOLEAN;
  p_IsReadOnly_5b18ad61 BOOLEAN;
  p_IsRequired_5b18ad61 BOOLEAN;
  p_RelatedIntegrationObjectID_5b18ad61 UUID;
  p_RelatedIntegrationObjectFieldName_5b18ad61 VARCHAR(255);
  p_Sequence_5b18ad61 INTEGER;
  p_Configuration_5b18ad61 TEXT;
  p_Status_5b18ad61 VARCHAR(25);
  p_IsCustom_5b18ad61 BOOLEAN;
  p_MetadataSource_5b18ad61 VARCHAR(20);
BEGIN
  p_ID_5b18ad61 := 'E65C4AD7-3ADD-5458-83CA-39598F732061';
  p_IntegrationObjectID_5b18ad61 := 'D4B4DBBD-FF1E-5147-8602-A41DC2855CE5';
  p_Name_5b18ad61 := 'put-code';
  p_DisplayName_5b18ad61 := 'Put Code';
  p_Description_5b18ad61 := 'ORCID''s stable identifier for this item within the record. Primary key.';
  p_Type_5b18ad61 := 'Integer';
  p_AllowsNull_5b18ad61 := FALSE;
  p_IsPrimaryKey_5b18ad61 := TRUE;
  p_IsUniqueKey_5b18ad61 := TRUE;
  p_IsReadOnly_5b18ad61 := TRUE;
  p_IsRequired_5b18ad61 := TRUE;
  p_Sequence_5b18ad61 := 1;
  p_Status_5b18ad61 := 'Active';
  p_IsCustom_5b18ad61 := FALSE;
  p_MetadataSource_5b18ad61 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_5b18ad61, p_IntegrationObjectID := p_IntegrationObjectID_5b18ad61, p_Name := p_Name_5b18ad61, p_DisplayName := p_DisplayName_5b18ad61, p_Description := p_Description_5b18ad61, p_Category := p_Category_5b18ad61, p_Category_Clear := TRUE, p_Type := p_Type_5b18ad61, p_Length := p_Length_5b18ad61, p_Length_Clear := TRUE, p_Precision := p_Precision_5b18ad61, p_Precision_Clear := TRUE, p_Scale := p_Scale_5b18ad61, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_5b18ad61, p_DefaultValue := p_DefaultValue_5b18ad61, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_5b18ad61, p_IsUniqueKey := p_IsUniqueKey_5b18ad61, p_IsReadOnly := p_IsReadOnly_5b18ad61, p_IsRequired := p_IsRequired_5b18ad61, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_5b18ad61, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_5b18ad61, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_5b18ad61, p_Configuration := p_Configuration_5b18ad61, p_Configuration_Clear := TRUE, p_Status := p_Status_5b18ad61, p_IsCustom := p_IsCustom_5b18ad61, p_MetadataSource := p_MetadataSource_5b18ad61);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_8ee5a09b UUID;
  p_IntegrationObjectID_8ee5a09b UUID;
  p_Name_8ee5a09b VARCHAR(255);
  p_DisplayName_8ee5a09b VARCHAR(255);
  p_Description_8ee5a09b TEXT;
  p_Category_8ee5a09b VARCHAR(100);
  p_Type_8ee5a09b VARCHAR(100);
  p_Length_8ee5a09b INTEGER;
  p_Precision_8ee5a09b INTEGER;
  p_Scale_8ee5a09b INTEGER;
  p_AllowsNull_8ee5a09b BOOLEAN;
  p_DefaultValue_8ee5a09b VARCHAR(255);
  p_IsPrimaryKey_8ee5a09b BOOLEAN;
  p_IsUniqueKey_8ee5a09b BOOLEAN;
  p_IsReadOnly_8ee5a09b BOOLEAN;
  p_IsRequired_8ee5a09b BOOLEAN;
  p_RelatedIntegrationObjectID_8ee5a09b UUID;
  p_RelatedIntegrationObjectFieldName_8ee5a09b VARCHAR(255);
  p_Sequence_8ee5a09b INTEGER;
  p_Configuration_8ee5a09b TEXT;
  p_Status_8ee5a09b VARCHAR(25);
  p_IsCustom_8ee5a09b BOOLEAN;
  p_MetadataSource_8ee5a09b VARCHAR(20);
BEGIN
  p_ID_8ee5a09b := 'B382A22B-E3FA-529B-9104-7B1E0F4E3801';
  p_IntegrationObjectID_8ee5a09b := 'D4B4DBBD-FF1E-5147-8602-A41DC2855CE5';
  p_Name_8ee5a09b := 'path';
  p_DisplayName_8ee5a09b := 'Path';
  p_Description_8ee5a09b := 'Element path /{orcid}/{section}/{put-code}.';
  p_Type_8ee5a09b := 'String';
  p_Length_8ee5a09b := 500;
  p_AllowsNull_8ee5a09b := TRUE;
  p_IsPrimaryKey_8ee5a09b := FALSE;
  p_IsUniqueKey_8ee5a09b := FALSE;
  p_IsReadOnly_8ee5a09b := TRUE;
  p_IsRequired_8ee5a09b := FALSE;
  p_Sequence_8ee5a09b := 2;
  p_Status_8ee5a09b := 'Active';
  p_IsCustom_8ee5a09b := FALSE;
  p_MetadataSource_8ee5a09b := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_8ee5a09b, p_IntegrationObjectID := p_IntegrationObjectID_8ee5a09b, p_Name := p_Name_8ee5a09b, p_DisplayName := p_DisplayName_8ee5a09b, p_Description := p_Description_8ee5a09b, p_Category := p_Category_8ee5a09b, p_Category_Clear := TRUE, p_Type := p_Type_8ee5a09b, p_Length := p_Length_8ee5a09b, p_Precision := p_Precision_8ee5a09b, p_Precision_Clear := TRUE, p_Scale := p_Scale_8ee5a09b, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_8ee5a09b, p_DefaultValue := p_DefaultValue_8ee5a09b, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_8ee5a09b, p_IsUniqueKey := p_IsUniqueKey_8ee5a09b, p_IsReadOnly := p_IsReadOnly_8ee5a09b, p_IsRequired := p_IsRequired_8ee5a09b, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_8ee5a09b, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_8ee5a09b, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_8ee5a09b, p_Configuration := p_Configuration_8ee5a09b, p_Configuration_Clear := TRUE, p_Status := p_Status_8ee5a09b, p_IsCustom := p_IsCustom_8ee5a09b, p_MetadataSource := p_MetadataSource_8ee5a09b);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_51cc8b15 UUID;
  p_IntegrationObjectID_51cc8b15 UUID;
  p_Name_51cc8b15 VARCHAR(255);
  p_DisplayName_51cc8b15 VARCHAR(255);
  p_Description_51cc8b15 TEXT;
  p_Category_51cc8b15 VARCHAR(100);
  p_Type_51cc8b15 VARCHAR(100);
  p_Length_51cc8b15 INTEGER;
  p_Precision_51cc8b15 INTEGER;
  p_Scale_51cc8b15 INTEGER;
  p_AllowsNull_51cc8b15 BOOLEAN;
  p_DefaultValue_51cc8b15 VARCHAR(255);
  p_IsPrimaryKey_51cc8b15 BOOLEAN;
  p_IsUniqueKey_51cc8b15 BOOLEAN;
  p_IsReadOnly_51cc8b15 BOOLEAN;
  p_IsRequired_51cc8b15 BOOLEAN;
  p_RelatedIntegrationObjectID_51cc8b15 UUID;
  p_RelatedIntegrationObjectFieldName_51cc8b15 VARCHAR(255);
  p_Sequence_51cc8b15 INTEGER;
  p_Configuration_51cc8b15 TEXT;
  p_Status_51cc8b15 VARCHAR(25);
  p_IsCustom_51cc8b15 BOOLEAN;
  p_MetadataSource_51cc8b15 VARCHAR(20);
BEGIN
  p_ID_51cc8b15 := '63E2C4CD-8665-5B02-9706-77395A483E01';
  p_IntegrationObjectID_51cc8b15 := 'D4B4DBBD-FF1E-5147-8602-A41DC2855CE5';
  p_Name_51cc8b15 := 'visibility';
  p_DisplayName_51cc8b15 := 'Visibility';
  p_Description_51cc8b15 := 'ORCID visibility of the item (public, limited, private). The Public API only serves public.';
  p_Type_51cc8b15 := 'String';
  p_AllowsNull_51cc8b15 := TRUE;
  p_IsPrimaryKey_51cc8b15 := FALSE;
  p_IsUniqueKey_51cc8b15 := FALSE;
  p_IsReadOnly_51cc8b15 := TRUE;
  p_IsRequired_51cc8b15 := FALSE;
  p_Sequence_51cc8b15 := 3;
  p_Status_51cc8b15 := 'Active';
  p_IsCustom_51cc8b15 := FALSE;
  p_MetadataSource_51cc8b15 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_51cc8b15, p_IntegrationObjectID := p_IntegrationObjectID_51cc8b15, p_Name := p_Name_51cc8b15, p_DisplayName := p_DisplayName_51cc8b15, p_Description := p_Description_51cc8b15, p_Category := p_Category_51cc8b15, p_Category_Clear := TRUE, p_Type := p_Type_51cc8b15, p_Length := p_Length_51cc8b15, p_Length_Clear := TRUE, p_Precision := p_Precision_51cc8b15, p_Precision_Clear := TRUE, p_Scale := p_Scale_51cc8b15, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_51cc8b15, p_DefaultValue := p_DefaultValue_51cc8b15, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_51cc8b15, p_IsUniqueKey := p_IsUniqueKey_51cc8b15, p_IsReadOnly := p_IsReadOnly_51cc8b15, p_IsRequired := p_IsRequired_51cc8b15, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_51cc8b15, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_51cc8b15, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_51cc8b15, p_Configuration := p_Configuration_51cc8b15, p_Configuration_Clear := TRUE, p_Status := p_Status_51cc8b15, p_IsCustom := p_IsCustom_51cc8b15, p_MetadataSource := p_MetadataSource_51cc8b15);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_6951d60b UUID;
  p_IntegrationObjectID_6951d60b UUID;
  p_Name_6951d60b VARCHAR(255);
  p_DisplayName_6951d60b VARCHAR(255);
  p_Description_6951d60b TEXT;
  p_Category_6951d60b VARCHAR(100);
  p_Type_6951d60b VARCHAR(100);
  p_Length_6951d60b INTEGER;
  p_Precision_6951d60b INTEGER;
  p_Scale_6951d60b INTEGER;
  p_AllowsNull_6951d60b BOOLEAN;
  p_DefaultValue_6951d60b VARCHAR(255);
  p_IsPrimaryKey_6951d60b BOOLEAN;
  p_IsUniqueKey_6951d60b BOOLEAN;
  p_IsReadOnly_6951d60b BOOLEAN;
  p_IsRequired_6951d60b BOOLEAN;
  p_RelatedIntegrationObjectID_6951d60b UUID;
  p_RelatedIntegrationObjectFieldName_6951d60b VARCHAR(255);
  p_Sequence_6951d60b INTEGER;
  p_Configuration_6951d60b TEXT;
  p_Status_6951d60b VARCHAR(25);
  p_IsCustom_6951d60b BOOLEAN;
  p_MetadataSource_6951d60b VARCHAR(20);
BEGIN
  p_ID_6951d60b := 'A2B2483B-4D1E-5A4F-A1CE-5A67838AA36A';
  p_IntegrationObjectID_6951d60b := 'D4B4DBBD-FF1E-5147-8602-A41DC2855CE5';
  p_Name_6951d60b := 'display-index';
  p_DisplayName_6951d60b := 'Display Index';
  p_Description_6951d60b := 'Display order the researcher chose for the item.';
  p_Type_6951d60b := 'String';
  p_AllowsNull_6951d60b := TRUE;
  p_IsPrimaryKey_6951d60b := FALSE;
  p_IsUniqueKey_6951d60b := FALSE;
  p_IsReadOnly_6951d60b := TRUE;
  p_IsRequired_6951d60b := FALSE;
  p_Sequence_6951d60b := 4;
  p_Status_6951d60b := 'Active';
  p_IsCustom_6951d60b := FALSE;
  p_MetadataSource_6951d60b := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_6951d60b, p_IntegrationObjectID := p_IntegrationObjectID_6951d60b, p_Name := p_Name_6951d60b, p_DisplayName := p_DisplayName_6951d60b, p_Description := p_Description_6951d60b, p_Category := p_Category_6951d60b, p_Category_Clear := TRUE, p_Type := p_Type_6951d60b, p_Length := p_Length_6951d60b, p_Length_Clear := TRUE, p_Precision := p_Precision_6951d60b, p_Precision_Clear := TRUE, p_Scale := p_Scale_6951d60b, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_6951d60b, p_DefaultValue := p_DefaultValue_6951d60b, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_6951d60b, p_IsUniqueKey := p_IsUniqueKey_6951d60b, p_IsReadOnly := p_IsReadOnly_6951d60b, p_IsRequired := p_IsRequired_6951d60b, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_6951d60b, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_6951d60b, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_6951d60b, p_Configuration := p_Configuration_6951d60b, p_Configuration_Clear := TRUE, p_Status := p_Status_6951d60b, p_IsCustom := p_IsCustom_6951d60b, p_MetadataSource := p_MetadataSource_6951d60b);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_b1a9f55d UUID;
  p_IntegrationObjectID_b1a9f55d UUID;
  p_Name_b1a9f55d VARCHAR(255);
  p_DisplayName_b1a9f55d VARCHAR(255);
  p_Description_b1a9f55d TEXT;
  p_Category_b1a9f55d VARCHAR(100);
  p_Type_b1a9f55d VARCHAR(100);
  p_Length_b1a9f55d INTEGER;
  p_Precision_b1a9f55d INTEGER;
  p_Scale_b1a9f55d INTEGER;
  p_AllowsNull_b1a9f55d BOOLEAN;
  p_DefaultValue_b1a9f55d VARCHAR(255);
  p_IsPrimaryKey_b1a9f55d BOOLEAN;
  p_IsUniqueKey_b1a9f55d BOOLEAN;
  p_IsReadOnly_b1a9f55d BOOLEAN;
  p_IsRequired_b1a9f55d BOOLEAN;
  p_RelatedIntegrationObjectID_b1a9f55d UUID;
  p_RelatedIntegrationObjectFieldName_b1a9f55d VARCHAR(255);
  p_Sequence_b1a9f55d INTEGER;
  p_Configuration_b1a9f55d TEXT;
  p_Status_b1a9f55d VARCHAR(25);
  p_IsCustom_b1a9f55d BOOLEAN;
  p_MetadataSource_b1a9f55d VARCHAR(20);
BEGIN
  p_ID_b1a9f55d := 'D6720B63-C523-5BDE-BB9C-E10F48E0DC12';
  p_IntegrationObjectID_b1a9f55d := 'D4B4DBBD-FF1E-5147-8602-A41DC2855CE5';
  p_Name_b1a9f55d := 'created-date';
  p_DisplayName_b1a9f55d := 'Created Date';
  p_Description_b1a9f55d := 'When ORCID created the item.';
  p_Type_b1a9f55d := 'DateTime';
  p_AllowsNull_b1a9f55d := TRUE;
  p_IsPrimaryKey_b1a9f55d := FALSE;
  p_IsUniqueKey_b1a9f55d := FALSE;
  p_IsReadOnly_b1a9f55d := TRUE;
  p_IsRequired_b1a9f55d := FALSE;
  p_Sequence_b1a9f55d := 5;
  p_Status_b1a9f55d := 'Active';
  p_IsCustom_b1a9f55d := FALSE;
  p_MetadataSource_b1a9f55d := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_b1a9f55d, p_IntegrationObjectID := p_IntegrationObjectID_b1a9f55d, p_Name := p_Name_b1a9f55d, p_DisplayName := p_DisplayName_b1a9f55d, p_Description := p_Description_b1a9f55d, p_Category := p_Category_b1a9f55d, p_Category_Clear := TRUE, p_Type := p_Type_b1a9f55d, p_Length := p_Length_b1a9f55d, p_Length_Clear := TRUE, p_Precision := p_Precision_b1a9f55d, p_Precision_Clear := TRUE, p_Scale := p_Scale_b1a9f55d, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_b1a9f55d, p_DefaultValue := p_DefaultValue_b1a9f55d, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_b1a9f55d, p_IsUniqueKey := p_IsUniqueKey_b1a9f55d, p_IsReadOnly := p_IsReadOnly_b1a9f55d, p_IsRequired := p_IsRequired_b1a9f55d, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_b1a9f55d, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_b1a9f55d, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_b1a9f55d, p_Configuration := p_Configuration_b1a9f55d, p_Configuration_Clear := TRUE, p_Status := p_Status_b1a9f55d, p_IsCustom := p_IsCustom_b1a9f55d, p_MetadataSource := p_MetadataSource_b1a9f55d);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_c480091b UUID;
  p_IntegrationObjectID_c480091b UUID;
  p_Name_c480091b VARCHAR(255);
  p_DisplayName_c480091b VARCHAR(255);
  p_Description_c480091b TEXT;
  p_Category_c480091b VARCHAR(100);
  p_Type_c480091b VARCHAR(100);
  p_Length_c480091b INTEGER;
  p_Precision_c480091b INTEGER;
  p_Scale_c480091b INTEGER;
  p_AllowsNull_c480091b BOOLEAN;
  p_DefaultValue_c480091b VARCHAR(255);
  p_IsPrimaryKey_c480091b BOOLEAN;
  p_IsUniqueKey_c480091b BOOLEAN;
  p_IsReadOnly_c480091b BOOLEAN;
  p_IsRequired_c480091b BOOLEAN;
  p_RelatedIntegrationObjectID_c480091b UUID;
  p_RelatedIntegrationObjectFieldName_c480091b VARCHAR(255);
  p_Sequence_c480091b INTEGER;
  p_Configuration_c480091b TEXT;
  p_Status_c480091b VARCHAR(25);
  p_IsCustom_c480091b BOOLEAN;
  p_MetadataSource_c480091b VARCHAR(20);
BEGIN
  p_ID_c480091b := '90B7858F-0700-57A8-8E65-9E1FAACCB91D';
  p_IntegrationObjectID_c480091b := 'D4B4DBBD-FF1E-5147-8602-A41DC2855CE5';
  p_Name_c480091b := 'last-modified-date';
  p_DisplayName_c480091b := 'Last Modified Date';
  p_Description_c480091b := 'When ORCID last changed the item. Incremental watermark.';
  p_Type_c480091b := 'DateTime';
  p_AllowsNull_c480091b := TRUE;
  p_IsPrimaryKey_c480091b := FALSE;
  p_IsUniqueKey_c480091b := FALSE;
  p_IsReadOnly_c480091b := TRUE;
  p_IsRequired_c480091b := FALSE;
  p_Sequence_c480091b := 6;
  p_Status_c480091b := 'Active';
  p_IsCustom_c480091b := FALSE;
  p_MetadataSource_c480091b := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_c480091b, p_IntegrationObjectID := p_IntegrationObjectID_c480091b, p_Name := p_Name_c480091b, p_DisplayName := p_DisplayName_c480091b, p_Description := p_Description_c480091b, p_Category := p_Category_c480091b, p_Category_Clear := TRUE, p_Type := p_Type_c480091b, p_Length := p_Length_c480091b, p_Length_Clear := TRUE, p_Precision := p_Precision_c480091b, p_Precision_Clear := TRUE, p_Scale := p_Scale_c480091b, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_c480091b, p_DefaultValue := p_DefaultValue_c480091b, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_c480091b, p_IsUniqueKey := p_IsUniqueKey_c480091b, p_IsReadOnly := p_IsReadOnly_c480091b, p_IsRequired := p_IsRequired_c480091b, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_c480091b, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_c480091b, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_c480091b, p_Configuration := p_Configuration_c480091b, p_Configuration_Clear := TRUE, p_Status := p_Status_c480091b, p_IsCustom := p_IsCustom_c480091b, p_MetadataSource := p_MetadataSource_c480091b);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_43459fb8 UUID;
  p_IntegrationObjectID_43459fb8 UUID;
  p_Name_43459fb8 VARCHAR(255);
  p_DisplayName_43459fb8 VARCHAR(255);
  p_Description_43459fb8 TEXT;
  p_Category_43459fb8 VARCHAR(100);
  p_Type_43459fb8 VARCHAR(100);
  p_Length_43459fb8 INTEGER;
  p_Precision_43459fb8 INTEGER;
  p_Scale_43459fb8 INTEGER;
  p_AllowsNull_43459fb8 BOOLEAN;
  p_DefaultValue_43459fb8 VARCHAR(255);
  p_IsPrimaryKey_43459fb8 BOOLEAN;
  p_IsUniqueKey_43459fb8 BOOLEAN;
  p_IsReadOnly_43459fb8 BOOLEAN;
  p_IsRequired_43459fb8 BOOLEAN;
  p_RelatedIntegrationObjectID_43459fb8 UUID;
  p_RelatedIntegrationObjectFieldName_43459fb8 VARCHAR(255);
  p_Sequence_43459fb8 INTEGER;
  p_Configuration_43459fb8 TEXT;
  p_Status_43459fb8 VARCHAR(25);
  p_IsCustom_43459fb8 BOOLEAN;
  p_MetadataSource_43459fb8 VARCHAR(20);
BEGIN
  p_ID_43459fb8 := '00942387-5D59-5FC3-80E5-3AA7F909763D';
  p_IntegrationObjectID_43459fb8 := 'D4B4DBBD-FF1E-5147-8602-A41DC2855CE5';
  p_Name_43459fb8 := 'source';
  p_DisplayName_43459fb8 := 'Source';
  p_Description_43459fb8 := 'Full source block: who asserted the item.';
  p_Type_43459fb8 := 'json';
  p_AllowsNull_43459fb8 := TRUE;
  p_IsPrimaryKey_43459fb8 := FALSE;
  p_IsUniqueKey_43459fb8 := FALSE;
  p_IsReadOnly_43459fb8 := TRUE;
  p_IsRequired_43459fb8 := FALSE;
  p_Sequence_43459fb8 := 7;
  p_Status_43459fb8 := 'Active';
  p_IsCustom_43459fb8 := FALSE;
  p_MetadataSource_43459fb8 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_43459fb8, p_IntegrationObjectID := p_IntegrationObjectID_43459fb8, p_Name := p_Name_43459fb8, p_DisplayName := p_DisplayName_43459fb8, p_Description := p_Description_43459fb8, p_Category := p_Category_43459fb8, p_Category_Clear := TRUE, p_Type := p_Type_43459fb8, p_Length := p_Length_43459fb8, p_Length_Clear := TRUE, p_Precision := p_Precision_43459fb8, p_Precision_Clear := TRUE, p_Scale := p_Scale_43459fb8, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_43459fb8, p_DefaultValue := p_DefaultValue_43459fb8, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_43459fb8, p_IsUniqueKey := p_IsUniqueKey_43459fb8, p_IsReadOnly := p_IsReadOnly_43459fb8, p_IsRequired := p_IsRequired_43459fb8, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_43459fb8, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_43459fb8, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_43459fb8, p_Configuration := p_Configuration_43459fb8, p_Configuration_Clear := TRUE, p_Status := p_Status_43459fb8, p_IsCustom := p_IsCustom_43459fb8, p_MetadataSource := p_MetadataSource_43459fb8);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_e7092020 UUID;
  p_IntegrationObjectID_e7092020 UUID;
  p_Name_e7092020 VARCHAR(255);
  p_DisplayName_e7092020 VARCHAR(255);
  p_Description_e7092020 TEXT;
  p_Category_e7092020 VARCHAR(100);
  p_Type_e7092020 VARCHAR(100);
  p_Length_e7092020 INTEGER;
  p_Precision_e7092020 INTEGER;
  p_Scale_e7092020 INTEGER;
  p_AllowsNull_e7092020 BOOLEAN;
  p_DefaultValue_e7092020 VARCHAR(255);
  p_IsPrimaryKey_e7092020 BOOLEAN;
  p_IsUniqueKey_e7092020 BOOLEAN;
  p_IsReadOnly_e7092020 BOOLEAN;
  p_IsRequired_e7092020 BOOLEAN;
  p_RelatedIntegrationObjectID_e7092020 UUID;
  p_RelatedIntegrationObjectFieldName_e7092020 VARCHAR(255);
  p_Sequence_e7092020 INTEGER;
  p_Configuration_e7092020 TEXT;
  p_Status_e7092020 VARCHAR(25);
  p_IsCustom_e7092020 BOOLEAN;
  p_MetadataSource_e7092020 VARCHAR(20);
BEGIN
  p_ID_e7092020 := 'DBED6559-5347-5CF7-B015-2BC681288715';
  p_IntegrationObjectID_e7092020 := 'D4B4DBBD-FF1E-5147-8602-A41DC2855CE5';
  p_Name_e7092020 := 'source-name';
  p_DisplayName_e7092020 := 'Source Name';
  p_Description_e7092020 := 'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.';
  p_Type_e7092020 := 'String';
  p_Length_e7092020 := 500;
  p_AllowsNull_e7092020 := TRUE;
  p_IsPrimaryKey_e7092020 := FALSE;
  p_IsUniqueKey_e7092020 := FALSE;
  p_IsReadOnly_e7092020 := TRUE;
  p_IsRequired_e7092020 := FALSE;
  p_Sequence_e7092020 := 8;
  p_Status_e7092020 := 'Active';
  p_IsCustom_e7092020 := FALSE;
  p_MetadataSource_e7092020 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_e7092020, p_IntegrationObjectID := p_IntegrationObjectID_e7092020, p_Name := p_Name_e7092020, p_DisplayName := p_DisplayName_e7092020, p_Description := p_Description_e7092020, p_Category := p_Category_e7092020, p_Category_Clear := TRUE, p_Type := p_Type_e7092020, p_Length := p_Length_e7092020, p_Precision := p_Precision_e7092020, p_Precision_Clear := TRUE, p_Scale := p_Scale_e7092020, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_e7092020, p_DefaultValue := p_DefaultValue_e7092020, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_e7092020, p_IsUniqueKey := p_IsUniqueKey_e7092020, p_IsReadOnly := p_IsReadOnly_e7092020, p_IsRequired := p_IsRequired_e7092020, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_e7092020, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_e7092020, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_e7092020, p_Configuration := p_Configuration_e7092020, p_Configuration_Clear := TRUE, p_Status := p_Status_e7092020, p_IsCustom := p_IsCustom_e7092020, p_MetadataSource := p_MetadataSource_e7092020);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_63f5e414 UUID;
  p_IntegrationObjectID_63f5e414 UUID;
  p_Name_63f5e414 VARCHAR(255);
  p_DisplayName_63f5e414 VARCHAR(255);
  p_Description_63f5e414 TEXT;
  p_Category_63f5e414 VARCHAR(100);
  p_Type_63f5e414 VARCHAR(100);
  p_Length_63f5e414 INTEGER;
  p_Precision_63f5e414 INTEGER;
  p_Scale_63f5e414 INTEGER;
  p_AllowsNull_63f5e414 BOOLEAN;
  p_DefaultValue_63f5e414 VARCHAR(255);
  p_IsPrimaryKey_63f5e414 BOOLEAN;
  p_IsUniqueKey_63f5e414 BOOLEAN;
  p_IsReadOnly_63f5e414 BOOLEAN;
  p_IsRequired_63f5e414 BOOLEAN;
  p_RelatedIntegrationObjectID_63f5e414 UUID;
  p_RelatedIntegrationObjectFieldName_63f5e414 VARCHAR(255);
  p_Sequence_63f5e414 INTEGER;
  p_Configuration_63f5e414 TEXT;
  p_Status_63f5e414 VARCHAR(25);
  p_IsCustom_63f5e414 BOOLEAN;
  p_MetadataSource_63f5e414 VARCHAR(20);
BEGIN
  p_ID_63f5e414 := '88E8778D-242D-5083-A302-3C902017C65D';
  p_IntegrationObjectID_63f5e414 := 'D4B4DBBD-FF1E-5147-8602-A41DC2855CE5';
  p_Name_63f5e414 := 'source-orcid';
  p_DisplayName_63f5e414 := 'Source Orcid';
  p_Description_63f5e414 := 'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.';
  p_Type_63f5e414 := 'String';
  p_Length_63f5e414 := 19;
  p_AllowsNull_63f5e414 := TRUE;
  p_IsPrimaryKey_63f5e414 := FALSE;
  p_IsUniqueKey_63f5e414 := FALSE;
  p_IsReadOnly_63f5e414 := TRUE;
  p_IsRequired_63f5e414 := FALSE;
  p_Sequence_63f5e414 := 9;
  p_Status_63f5e414 := 'Active';
  p_IsCustom_63f5e414 := FALSE;
  p_MetadataSource_63f5e414 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_63f5e414, p_IntegrationObjectID := p_IntegrationObjectID_63f5e414, p_Name := p_Name_63f5e414, p_DisplayName := p_DisplayName_63f5e414, p_Description := p_Description_63f5e414, p_Category := p_Category_63f5e414, p_Category_Clear := TRUE, p_Type := p_Type_63f5e414, p_Length := p_Length_63f5e414, p_Precision := p_Precision_63f5e414, p_Precision_Clear := TRUE, p_Scale := p_Scale_63f5e414, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_63f5e414, p_DefaultValue := p_DefaultValue_63f5e414, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_63f5e414, p_IsUniqueKey := p_IsUniqueKey_63f5e414, p_IsReadOnly := p_IsReadOnly_63f5e414, p_IsRequired := p_IsRequired_63f5e414, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_63f5e414, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_63f5e414, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_63f5e414, p_Configuration := p_Configuration_63f5e414, p_Configuration_Clear := TRUE, p_Status := p_Status_63f5e414, p_IsCustom := p_IsCustom_63f5e414, p_MetadataSource := p_MetadataSource_63f5e414);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_d167a195 UUID;
  p_IntegrationObjectID_d167a195 UUID;
  p_Name_d167a195 VARCHAR(255);
  p_DisplayName_d167a195 VARCHAR(255);
  p_Description_d167a195 TEXT;
  p_Category_d167a195 VARCHAR(100);
  p_Type_d167a195 VARCHAR(100);
  p_Length_d167a195 INTEGER;
  p_Precision_d167a195 INTEGER;
  p_Scale_d167a195 INTEGER;
  p_AllowsNull_d167a195 BOOLEAN;
  p_DefaultValue_d167a195 VARCHAR(255);
  p_IsPrimaryKey_d167a195 BOOLEAN;
  p_IsUniqueKey_d167a195 BOOLEAN;
  p_IsReadOnly_d167a195 BOOLEAN;
  p_IsRequired_d167a195 BOOLEAN;
  p_RelatedIntegrationObjectID_d167a195 UUID;
  p_RelatedIntegrationObjectFieldName_d167a195 VARCHAR(255);
  p_Sequence_d167a195 INTEGER;
  p_Configuration_d167a195 TEXT;
  p_Status_d167a195 VARCHAR(25);
  p_IsCustom_d167a195 BOOLEAN;
  p_MetadataSource_d167a195 VARCHAR(20);
BEGIN
  p_ID_d167a195 := '0DD22C59-7AE4-57EE-8651-1CFFCD746308';
  p_IntegrationObjectID_d167a195 := 'D4B4DBBD-FF1E-5147-8602-A41DC2855CE5';
  p_Name_d167a195 := 'content';
  p_DisplayName_d167a195 := 'Content';
  p_Description_d167a195 := 'The alternate name.';
  p_Type_d167a195 := 'String';
  p_Length_d167a195 := 1000;
  p_AllowsNull_d167a195 := TRUE;
  p_IsPrimaryKey_d167a195 := FALSE;
  p_IsUniqueKey_d167a195 := FALSE;
  p_IsReadOnly_d167a195 := TRUE;
  p_IsRequired_d167a195 := FALSE;
  p_Sequence_d167a195 := 10;
  p_Status_d167a195 := 'Active';
  p_IsCustom_d167a195 := FALSE;
  p_MetadataSource_d167a195 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_d167a195, p_IntegrationObjectID := p_IntegrationObjectID_d167a195, p_Name := p_Name_d167a195, p_DisplayName := p_DisplayName_d167a195, p_Description := p_Description_d167a195, p_Category := p_Category_d167a195, p_Category_Clear := TRUE, p_Type := p_Type_d167a195, p_Length := p_Length_d167a195, p_Precision := p_Precision_d167a195, p_Precision_Clear := TRUE, p_Scale := p_Scale_d167a195, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_d167a195, p_DefaultValue := p_DefaultValue_d167a195, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_d167a195, p_IsUniqueKey := p_IsUniqueKey_d167a195, p_IsReadOnly := p_IsReadOnly_d167a195, p_IsRequired := p_IsRequired_d167a195, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_d167a195, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_d167a195, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_d167a195, p_Configuration := p_Configuration_d167a195, p_Configuration_Clear := TRUE, p_Status := p_Status_d167a195, p_IsCustom := p_IsCustom_d167a195, p_MetadataSource := p_MetadataSource_d167a195);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_8d851460 UUID;
  p_IntegrationObjectID_8d851460 UUID;
  p_Name_8d851460 VARCHAR(255);
  p_DisplayName_8d851460 VARCHAR(255);
  p_Description_8d851460 TEXT;
  p_Category_8d851460 VARCHAR(100);
  p_Type_8d851460 VARCHAR(100);
  p_Length_8d851460 INTEGER;
  p_Precision_8d851460 INTEGER;
  p_Scale_8d851460 INTEGER;
  p_AllowsNull_8d851460 BOOLEAN;
  p_DefaultValue_8d851460 VARCHAR(255);
  p_IsPrimaryKey_8d851460 BOOLEAN;
  p_IsUniqueKey_8d851460 BOOLEAN;
  p_IsReadOnly_8d851460 BOOLEAN;
  p_IsRequired_8d851460 BOOLEAN;
  p_RelatedIntegrationObjectID_8d851460 UUID;
  p_RelatedIntegrationObjectFieldName_8d851460 VARCHAR(255);
  p_Sequence_8d851460 INTEGER;
  p_Configuration_8d851460 TEXT;
  p_Status_8d851460 VARCHAR(25);
  p_IsCustom_8d851460 BOOLEAN;
  p_MetadataSource_8d851460 VARCHAR(20);
BEGIN
  p_ID_8d851460 := '113B4117-B4A7-54C5-A828-85D19F6213F1';
  p_IntegrationObjectID_8d851460 := 'C72BE662-43B8-5398-BE8F-FD2145295A4D';
  p_Name_8d851460 := 'orcid-id';
  p_DisplayName_8d851460 := 'Orcid Id';
  p_Description_8d851460 := 'The ORCID iD of the researcher this item belongs to. Foreign key to the record object.';
  p_Type_8d851460 := 'String';
  p_Length_8d851460 := 19;
  p_AllowsNull_8d851460 := TRUE;
  p_IsPrimaryKey_8d851460 := FALSE;
  p_IsUniqueKey_8d851460 := FALSE;
  p_IsReadOnly_8d851460 := TRUE;
  p_IsRequired_8d851460 := TRUE;
  p_RelatedIntegrationObjectID_8d851460 := '73AED6B8-468D-403B-B994-F3C786C98BC0';
  p_RelatedIntegrationObjectFieldName_8d851460 := 'orcid-id';
  p_Sequence_8d851460 := 0;
  p_Status_8d851460 := 'Active';
  p_IsCustom_8d851460 := FALSE;
  p_MetadataSource_8d851460 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_8d851460, p_IntegrationObjectID := p_IntegrationObjectID_8d851460, p_Name := p_Name_8d851460, p_DisplayName := p_DisplayName_8d851460, p_Description := p_Description_8d851460, p_Category := p_Category_8d851460, p_Category_Clear := TRUE, p_Type := p_Type_8d851460, p_Length := p_Length_8d851460, p_Precision := p_Precision_8d851460, p_Precision_Clear := TRUE, p_Scale := p_Scale_8d851460, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_8d851460, p_DefaultValue := p_DefaultValue_8d851460, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_8d851460, p_IsUniqueKey := p_IsUniqueKey_8d851460, p_IsReadOnly := p_IsReadOnly_8d851460, p_IsRequired := p_IsRequired_8d851460, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_8d851460, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_8d851460, p_Sequence := p_Sequence_8d851460, p_Configuration := p_Configuration_8d851460, p_Configuration_Clear := TRUE, p_Status := p_Status_8d851460, p_IsCustom := p_IsCustom_8d851460, p_MetadataSource := p_MetadataSource_8d851460);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_e40a22ac UUID;
  p_IntegrationObjectID_e40a22ac UUID;
  p_Name_e40a22ac VARCHAR(255);
  p_DisplayName_e40a22ac VARCHAR(255);
  p_Description_e40a22ac TEXT;
  p_Category_e40a22ac VARCHAR(100);
  p_Type_e40a22ac VARCHAR(100);
  p_Length_e40a22ac INTEGER;
  p_Precision_e40a22ac INTEGER;
  p_Scale_e40a22ac INTEGER;
  p_AllowsNull_e40a22ac BOOLEAN;
  p_DefaultValue_e40a22ac VARCHAR(255);
  p_IsPrimaryKey_e40a22ac BOOLEAN;
  p_IsUniqueKey_e40a22ac BOOLEAN;
  p_IsReadOnly_e40a22ac BOOLEAN;
  p_IsRequired_e40a22ac BOOLEAN;
  p_RelatedIntegrationObjectID_e40a22ac UUID;
  p_RelatedIntegrationObjectFieldName_e40a22ac VARCHAR(255);
  p_Sequence_e40a22ac INTEGER;
  p_Configuration_e40a22ac TEXT;
  p_Status_e40a22ac VARCHAR(25);
  p_IsCustom_e40a22ac BOOLEAN;
  p_MetadataSource_e40a22ac VARCHAR(20);
BEGIN
  p_ID_e40a22ac := '480C9B5A-6F28-5946-9F52-FA7093B870AB';
  p_IntegrationObjectID_e40a22ac := 'C72BE662-43B8-5398-BE8F-FD2145295A4D';
  p_Name_e40a22ac := 'put-code';
  p_DisplayName_e40a22ac := 'Put Code';
  p_Description_e40a22ac := 'ORCID''s stable identifier for this item within the record. Primary key.';
  p_Type_e40a22ac := 'Integer';
  p_AllowsNull_e40a22ac := FALSE;
  p_IsPrimaryKey_e40a22ac := TRUE;
  p_IsUniqueKey_e40a22ac := TRUE;
  p_IsReadOnly_e40a22ac := TRUE;
  p_IsRequired_e40a22ac := TRUE;
  p_Sequence_e40a22ac := 1;
  p_Status_e40a22ac := 'Active';
  p_IsCustom_e40a22ac := FALSE;
  p_MetadataSource_e40a22ac := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_e40a22ac, p_IntegrationObjectID := p_IntegrationObjectID_e40a22ac, p_Name := p_Name_e40a22ac, p_DisplayName := p_DisplayName_e40a22ac, p_Description := p_Description_e40a22ac, p_Category := p_Category_e40a22ac, p_Category_Clear := TRUE, p_Type := p_Type_e40a22ac, p_Length := p_Length_e40a22ac, p_Length_Clear := TRUE, p_Precision := p_Precision_e40a22ac, p_Precision_Clear := TRUE, p_Scale := p_Scale_e40a22ac, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_e40a22ac, p_DefaultValue := p_DefaultValue_e40a22ac, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_e40a22ac, p_IsUniqueKey := p_IsUniqueKey_e40a22ac, p_IsReadOnly := p_IsReadOnly_e40a22ac, p_IsRequired := p_IsRequired_e40a22ac, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_e40a22ac, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_e40a22ac, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_e40a22ac, p_Configuration := p_Configuration_e40a22ac, p_Configuration_Clear := TRUE, p_Status := p_Status_e40a22ac, p_IsCustom := p_IsCustom_e40a22ac, p_MetadataSource := p_MetadataSource_e40a22ac);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_887cb136 UUID;
  p_IntegrationObjectID_887cb136 UUID;
  p_Name_887cb136 VARCHAR(255);
  p_DisplayName_887cb136 VARCHAR(255);
  p_Description_887cb136 TEXT;
  p_Category_887cb136 VARCHAR(100);
  p_Type_887cb136 VARCHAR(100);
  p_Length_887cb136 INTEGER;
  p_Precision_887cb136 INTEGER;
  p_Scale_887cb136 INTEGER;
  p_AllowsNull_887cb136 BOOLEAN;
  p_DefaultValue_887cb136 VARCHAR(255);
  p_IsPrimaryKey_887cb136 BOOLEAN;
  p_IsUniqueKey_887cb136 BOOLEAN;
  p_IsReadOnly_887cb136 BOOLEAN;
  p_IsRequired_887cb136 BOOLEAN;
  p_RelatedIntegrationObjectID_887cb136 UUID;
  p_RelatedIntegrationObjectFieldName_887cb136 VARCHAR(255);
  p_Sequence_887cb136 INTEGER;
  p_Configuration_887cb136 TEXT;
  p_Status_887cb136 VARCHAR(25);
  p_IsCustom_887cb136 BOOLEAN;
  p_MetadataSource_887cb136 VARCHAR(20);
BEGIN
  p_ID_887cb136 := 'DB2F48C5-959C-52FC-BA5F-EA16A2C7D5D4';
  p_IntegrationObjectID_887cb136 := 'C72BE662-43B8-5398-BE8F-FD2145295A4D';
  p_Name_887cb136 := 'path';
  p_DisplayName_887cb136 := 'Path';
  p_Description_887cb136 := 'Element path /{orcid}/{section}/{put-code}.';
  p_Type_887cb136 := 'String';
  p_Length_887cb136 := 500;
  p_AllowsNull_887cb136 := TRUE;
  p_IsPrimaryKey_887cb136 := FALSE;
  p_IsUniqueKey_887cb136 := FALSE;
  p_IsReadOnly_887cb136 := TRUE;
  p_IsRequired_887cb136 := FALSE;
  p_Sequence_887cb136 := 2;
  p_Status_887cb136 := 'Active';
  p_IsCustom_887cb136 := FALSE;
  p_MetadataSource_887cb136 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_887cb136, p_IntegrationObjectID := p_IntegrationObjectID_887cb136, p_Name := p_Name_887cb136, p_DisplayName := p_DisplayName_887cb136, p_Description := p_Description_887cb136, p_Category := p_Category_887cb136, p_Category_Clear := TRUE, p_Type := p_Type_887cb136, p_Length := p_Length_887cb136, p_Precision := p_Precision_887cb136, p_Precision_Clear := TRUE, p_Scale := p_Scale_887cb136, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_887cb136, p_DefaultValue := p_DefaultValue_887cb136, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_887cb136, p_IsUniqueKey := p_IsUniqueKey_887cb136, p_IsReadOnly := p_IsReadOnly_887cb136, p_IsRequired := p_IsRequired_887cb136, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_887cb136, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_887cb136, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_887cb136, p_Configuration := p_Configuration_887cb136, p_Configuration_Clear := TRUE, p_Status := p_Status_887cb136, p_IsCustom := p_IsCustom_887cb136, p_MetadataSource := p_MetadataSource_887cb136);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_41654e4d UUID;
  p_IntegrationObjectID_41654e4d UUID;
  p_Name_41654e4d VARCHAR(255);
  p_DisplayName_41654e4d VARCHAR(255);
  p_Description_41654e4d TEXT;
  p_Category_41654e4d VARCHAR(100);
  p_Type_41654e4d VARCHAR(100);
  p_Length_41654e4d INTEGER;
  p_Precision_41654e4d INTEGER;
  p_Scale_41654e4d INTEGER;
  p_AllowsNull_41654e4d BOOLEAN;
  p_DefaultValue_41654e4d VARCHAR(255);
  p_IsPrimaryKey_41654e4d BOOLEAN;
  p_IsUniqueKey_41654e4d BOOLEAN;
  p_IsReadOnly_41654e4d BOOLEAN;
  p_IsRequired_41654e4d BOOLEAN;
  p_RelatedIntegrationObjectID_41654e4d UUID;
  p_RelatedIntegrationObjectFieldName_41654e4d VARCHAR(255);
  p_Sequence_41654e4d INTEGER;
  p_Configuration_41654e4d TEXT;
  p_Status_41654e4d VARCHAR(25);
  p_IsCustom_41654e4d BOOLEAN;
  p_MetadataSource_41654e4d VARCHAR(20);
BEGIN
  p_ID_41654e4d := 'E9296858-A339-5062-8FC5-199304BFB860';
  p_IntegrationObjectID_41654e4d := 'C72BE662-43B8-5398-BE8F-FD2145295A4D';
  p_Name_41654e4d := 'visibility';
  p_DisplayName_41654e4d := 'Visibility';
  p_Description_41654e4d := 'ORCID visibility of the item (public, limited, private). The Public API only serves public.';
  p_Type_41654e4d := 'String';
  p_AllowsNull_41654e4d := TRUE;
  p_IsPrimaryKey_41654e4d := FALSE;
  p_IsUniqueKey_41654e4d := FALSE;
  p_IsReadOnly_41654e4d := TRUE;
  p_IsRequired_41654e4d := FALSE;
  p_Sequence_41654e4d := 3;
  p_Status_41654e4d := 'Active';
  p_IsCustom_41654e4d := FALSE;
  p_MetadataSource_41654e4d := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_41654e4d, p_IntegrationObjectID := p_IntegrationObjectID_41654e4d, p_Name := p_Name_41654e4d, p_DisplayName := p_DisplayName_41654e4d, p_Description := p_Description_41654e4d, p_Category := p_Category_41654e4d, p_Category_Clear := TRUE, p_Type := p_Type_41654e4d, p_Length := p_Length_41654e4d, p_Length_Clear := TRUE, p_Precision := p_Precision_41654e4d, p_Precision_Clear := TRUE, p_Scale := p_Scale_41654e4d, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_41654e4d, p_DefaultValue := p_DefaultValue_41654e4d, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_41654e4d, p_IsUniqueKey := p_IsUniqueKey_41654e4d, p_IsReadOnly := p_IsReadOnly_41654e4d, p_IsRequired := p_IsRequired_41654e4d, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_41654e4d, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_41654e4d, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_41654e4d, p_Configuration := p_Configuration_41654e4d, p_Configuration_Clear := TRUE, p_Status := p_Status_41654e4d, p_IsCustom := p_IsCustom_41654e4d, p_MetadataSource := p_MetadataSource_41654e4d);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_5c8851c7 UUID;
  p_IntegrationObjectID_5c8851c7 UUID;
  p_Name_5c8851c7 VARCHAR(255);
  p_DisplayName_5c8851c7 VARCHAR(255);
  p_Description_5c8851c7 TEXT;
  p_Category_5c8851c7 VARCHAR(100);
  p_Type_5c8851c7 VARCHAR(100);
  p_Length_5c8851c7 INTEGER;
  p_Precision_5c8851c7 INTEGER;
  p_Scale_5c8851c7 INTEGER;
  p_AllowsNull_5c8851c7 BOOLEAN;
  p_DefaultValue_5c8851c7 VARCHAR(255);
  p_IsPrimaryKey_5c8851c7 BOOLEAN;
  p_IsUniqueKey_5c8851c7 BOOLEAN;
  p_IsReadOnly_5c8851c7 BOOLEAN;
  p_IsRequired_5c8851c7 BOOLEAN;
  p_RelatedIntegrationObjectID_5c8851c7 UUID;
  p_RelatedIntegrationObjectFieldName_5c8851c7 VARCHAR(255);
  p_Sequence_5c8851c7 INTEGER;
  p_Configuration_5c8851c7 TEXT;
  p_Status_5c8851c7 VARCHAR(25);
  p_IsCustom_5c8851c7 BOOLEAN;
  p_MetadataSource_5c8851c7 VARCHAR(20);
BEGIN
  p_ID_5c8851c7 := '6A436E71-9977-5420-B4AC-A9F34AE9E447';
  p_IntegrationObjectID_5c8851c7 := 'C72BE662-43B8-5398-BE8F-FD2145295A4D';
  p_Name_5c8851c7 := 'display-index';
  p_DisplayName_5c8851c7 := 'Display Index';
  p_Description_5c8851c7 := 'Display order the researcher chose for the item.';
  p_Type_5c8851c7 := 'String';
  p_AllowsNull_5c8851c7 := TRUE;
  p_IsPrimaryKey_5c8851c7 := FALSE;
  p_IsUniqueKey_5c8851c7 := FALSE;
  p_IsReadOnly_5c8851c7 := TRUE;
  p_IsRequired_5c8851c7 := FALSE;
  p_Sequence_5c8851c7 := 4;
  p_Status_5c8851c7 := 'Active';
  p_IsCustom_5c8851c7 := FALSE;
  p_MetadataSource_5c8851c7 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_5c8851c7, p_IntegrationObjectID := p_IntegrationObjectID_5c8851c7, p_Name := p_Name_5c8851c7, p_DisplayName := p_DisplayName_5c8851c7, p_Description := p_Description_5c8851c7, p_Category := p_Category_5c8851c7, p_Category_Clear := TRUE, p_Type := p_Type_5c8851c7, p_Length := p_Length_5c8851c7, p_Length_Clear := TRUE, p_Precision := p_Precision_5c8851c7, p_Precision_Clear := TRUE, p_Scale := p_Scale_5c8851c7, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_5c8851c7, p_DefaultValue := p_DefaultValue_5c8851c7, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_5c8851c7, p_IsUniqueKey := p_IsUniqueKey_5c8851c7, p_IsReadOnly := p_IsReadOnly_5c8851c7, p_IsRequired := p_IsRequired_5c8851c7, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_5c8851c7, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_5c8851c7, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_5c8851c7, p_Configuration := p_Configuration_5c8851c7, p_Configuration_Clear := TRUE, p_Status := p_Status_5c8851c7, p_IsCustom := p_IsCustom_5c8851c7, p_MetadataSource := p_MetadataSource_5c8851c7);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_974c8fb2 UUID;
  p_IntegrationObjectID_974c8fb2 UUID;
  p_Name_974c8fb2 VARCHAR(255);
  p_DisplayName_974c8fb2 VARCHAR(255);
  p_Description_974c8fb2 TEXT;
  p_Category_974c8fb2 VARCHAR(100);
  p_Type_974c8fb2 VARCHAR(100);
  p_Length_974c8fb2 INTEGER;
  p_Precision_974c8fb2 INTEGER;
  p_Scale_974c8fb2 INTEGER;
  p_AllowsNull_974c8fb2 BOOLEAN;
  p_DefaultValue_974c8fb2 VARCHAR(255);
  p_IsPrimaryKey_974c8fb2 BOOLEAN;
  p_IsUniqueKey_974c8fb2 BOOLEAN;
  p_IsReadOnly_974c8fb2 BOOLEAN;
  p_IsRequired_974c8fb2 BOOLEAN;
  p_RelatedIntegrationObjectID_974c8fb2 UUID;
  p_RelatedIntegrationObjectFieldName_974c8fb2 VARCHAR(255);
  p_Sequence_974c8fb2 INTEGER;
  p_Configuration_974c8fb2 TEXT;
  p_Status_974c8fb2 VARCHAR(25);
  p_IsCustom_974c8fb2 BOOLEAN;
  p_MetadataSource_974c8fb2 VARCHAR(20);
BEGIN
  p_ID_974c8fb2 := '0A7C5E5C-9357-58D7-8C4A-3B2A7A57B918';
  p_IntegrationObjectID_974c8fb2 := 'C72BE662-43B8-5398-BE8F-FD2145295A4D';
  p_Name_974c8fb2 := 'created-date';
  p_DisplayName_974c8fb2 := 'Created Date';
  p_Description_974c8fb2 := 'When ORCID created the item.';
  p_Type_974c8fb2 := 'DateTime';
  p_AllowsNull_974c8fb2 := TRUE;
  p_IsPrimaryKey_974c8fb2 := FALSE;
  p_IsUniqueKey_974c8fb2 := FALSE;
  p_IsReadOnly_974c8fb2 := TRUE;
  p_IsRequired_974c8fb2 := FALSE;
  p_Sequence_974c8fb2 := 5;
  p_Status_974c8fb2 := 'Active';
  p_IsCustom_974c8fb2 := FALSE;
  p_MetadataSource_974c8fb2 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_974c8fb2, p_IntegrationObjectID := p_IntegrationObjectID_974c8fb2, p_Name := p_Name_974c8fb2, p_DisplayName := p_DisplayName_974c8fb2, p_Description := p_Description_974c8fb2, p_Category := p_Category_974c8fb2, p_Category_Clear := TRUE, p_Type := p_Type_974c8fb2, p_Length := p_Length_974c8fb2, p_Length_Clear := TRUE, p_Precision := p_Precision_974c8fb2, p_Precision_Clear := TRUE, p_Scale := p_Scale_974c8fb2, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_974c8fb2, p_DefaultValue := p_DefaultValue_974c8fb2, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_974c8fb2, p_IsUniqueKey := p_IsUniqueKey_974c8fb2, p_IsReadOnly := p_IsReadOnly_974c8fb2, p_IsRequired := p_IsRequired_974c8fb2, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_974c8fb2, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_974c8fb2, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_974c8fb2, p_Configuration := p_Configuration_974c8fb2, p_Configuration_Clear := TRUE, p_Status := p_Status_974c8fb2, p_IsCustom := p_IsCustom_974c8fb2, p_MetadataSource := p_MetadataSource_974c8fb2);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_a999acdd UUID;
  p_IntegrationObjectID_a999acdd UUID;
  p_Name_a999acdd VARCHAR(255);
  p_DisplayName_a999acdd VARCHAR(255);
  p_Description_a999acdd TEXT;
  p_Category_a999acdd VARCHAR(100);
  p_Type_a999acdd VARCHAR(100);
  p_Length_a999acdd INTEGER;
  p_Precision_a999acdd INTEGER;
  p_Scale_a999acdd INTEGER;
  p_AllowsNull_a999acdd BOOLEAN;
  p_DefaultValue_a999acdd VARCHAR(255);
  p_IsPrimaryKey_a999acdd BOOLEAN;
  p_IsUniqueKey_a999acdd BOOLEAN;
  p_IsReadOnly_a999acdd BOOLEAN;
  p_IsRequired_a999acdd BOOLEAN;
  p_RelatedIntegrationObjectID_a999acdd UUID;
  p_RelatedIntegrationObjectFieldName_a999acdd VARCHAR(255);
  p_Sequence_a999acdd INTEGER;
  p_Configuration_a999acdd TEXT;
  p_Status_a999acdd VARCHAR(25);
  p_IsCustom_a999acdd BOOLEAN;
  p_MetadataSource_a999acdd VARCHAR(20);
BEGIN
  p_ID_a999acdd := 'A2791AAC-1C9C-5C42-94D1-51BA488C9128';
  p_IntegrationObjectID_a999acdd := 'C72BE662-43B8-5398-BE8F-FD2145295A4D';
  p_Name_a999acdd := 'last-modified-date';
  p_DisplayName_a999acdd := 'Last Modified Date';
  p_Description_a999acdd := 'When ORCID last changed the item. Incremental watermark.';
  p_Type_a999acdd := 'DateTime';
  p_AllowsNull_a999acdd := TRUE;
  p_IsPrimaryKey_a999acdd := FALSE;
  p_IsUniqueKey_a999acdd := FALSE;
  p_IsReadOnly_a999acdd := TRUE;
  p_IsRequired_a999acdd := FALSE;
  p_Sequence_a999acdd := 6;
  p_Status_a999acdd := 'Active';
  p_IsCustom_a999acdd := FALSE;
  p_MetadataSource_a999acdd := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_a999acdd, p_IntegrationObjectID := p_IntegrationObjectID_a999acdd, p_Name := p_Name_a999acdd, p_DisplayName := p_DisplayName_a999acdd, p_Description := p_Description_a999acdd, p_Category := p_Category_a999acdd, p_Category_Clear := TRUE, p_Type := p_Type_a999acdd, p_Length := p_Length_a999acdd, p_Length_Clear := TRUE, p_Precision := p_Precision_a999acdd, p_Precision_Clear := TRUE, p_Scale := p_Scale_a999acdd, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_a999acdd, p_DefaultValue := p_DefaultValue_a999acdd, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_a999acdd, p_IsUniqueKey := p_IsUniqueKey_a999acdd, p_IsReadOnly := p_IsReadOnly_a999acdd, p_IsRequired := p_IsRequired_a999acdd, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_a999acdd, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_a999acdd, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_a999acdd, p_Configuration := p_Configuration_a999acdd, p_Configuration_Clear := TRUE, p_Status := p_Status_a999acdd, p_IsCustom := p_IsCustom_a999acdd, p_MetadataSource := p_MetadataSource_a999acdd);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_9c1914ac UUID;
  p_IntegrationObjectID_9c1914ac UUID;
  p_Name_9c1914ac VARCHAR(255);
  p_DisplayName_9c1914ac VARCHAR(255);
  p_Description_9c1914ac TEXT;
  p_Category_9c1914ac VARCHAR(100);
  p_Type_9c1914ac VARCHAR(100);
  p_Length_9c1914ac INTEGER;
  p_Precision_9c1914ac INTEGER;
  p_Scale_9c1914ac INTEGER;
  p_AllowsNull_9c1914ac BOOLEAN;
  p_DefaultValue_9c1914ac VARCHAR(255);
  p_IsPrimaryKey_9c1914ac BOOLEAN;
  p_IsUniqueKey_9c1914ac BOOLEAN;
  p_IsReadOnly_9c1914ac BOOLEAN;
  p_IsRequired_9c1914ac BOOLEAN;
  p_RelatedIntegrationObjectID_9c1914ac UUID;
  p_RelatedIntegrationObjectFieldName_9c1914ac VARCHAR(255);
  p_Sequence_9c1914ac INTEGER;
  p_Configuration_9c1914ac TEXT;
  p_Status_9c1914ac VARCHAR(25);
  p_IsCustom_9c1914ac BOOLEAN;
  p_MetadataSource_9c1914ac VARCHAR(20);
BEGIN
  p_ID_9c1914ac := '6BD36248-BFDA-549F-8AF9-4FE03D122050';
  p_IntegrationObjectID_9c1914ac := 'C72BE662-43B8-5398-BE8F-FD2145295A4D';
  p_Name_9c1914ac := 'source';
  p_DisplayName_9c1914ac := 'Source';
  p_Description_9c1914ac := 'Full source block: who asserted the item.';
  p_Type_9c1914ac := 'json';
  p_AllowsNull_9c1914ac := TRUE;
  p_IsPrimaryKey_9c1914ac := FALSE;
  p_IsUniqueKey_9c1914ac := FALSE;
  p_IsReadOnly_9c1914ac := TRUE;
  p_IsRequired_9c1914ac := FALSE;
  p_Sequence_9c1914ac := 7;
  p_Status_9c1914ac := 'Active';
  p_IsCustom_9c1914ac := FALSE;
  p_MetadataSource_9c1914ac := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_9c1914ac, p_IntegrationObjectID := p_IntegrationObjectID_9c1914ac, p_Name := p_Name_9c1914ac, p_DisplayName := p_DisplayName_9c1914ac, p_Description := p_Description_9c1914ac, p_Category := p_Category_9c1914ac, p_Category_Clear := TRUE, p_Type := p_Type_9c1914ac, p_Length := p_Length_9c1914ac, p_Length_Clear := TRUE, p_Precision := p_Precision_9c1914ac, p_Precision_Clear := TRUE, p_Scale := p_Scale_9c1914ac, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_9c1914ac, p_DefaultValue := p_DefaultValue_9c1914ac, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_9c1914ac, p_IsUniqueKey := p_IsUniqueKey_9c1914ac, p_IsReadOnly := p_IsReadOnly_9c1914ac, p_IsRequired := p_IsRequired_9c1914ac, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_9c1914ac, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_9c1914ac, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_9c1914ac, p_Configuration := p_Configuration_9c1914ac, p_Configuration_Clear := TRUE, p_Status := p_Status_9c1914ac, p_IsCustom := p_IsCustom_9c1914ac, p_MetadataSource := p_MetadataSource_9c1914ac);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_b192f120 UUID;
  p_IntegrationObjectID_b192f120 UUID;
  p_Name_b192f120 VARCHAR(255);
  p_DisplayName_b192f120 VARCHAR(255);
  p_Description_b192f120 TEXT;
  p_Category_b192f120 VARCHAR(100);
  p_Type_b192f120 VARCHAR(100);
  p_Length_b192f120 INTEGER;
  p_Precision_b192f120 INTEGER;
  p_Scale_b192f120 INTEGER;
  p_AllowsNull_b192f120 BOOLEAN;
  p_DefaultValue_b192f120 VARCHAR(255);
  p_IsPrimaryKey_b192f120 BOOLEAN;
  p_IsUniqueKey_b192f120 BOOLEAN;
  p_IsReadOnly_b192f120 BOOLEAN;
  p_IsRequired_b192f120 BOOLEAN;
  p_RelatedIntegrationObjectID_b192f120 UUID;
  p_RelatedIntegrationObjectFieldName_b192f120 VARCHAR(255);
  p_Sequence_b192f120 INTEGER;
  p_Configuration_b192f120 TEXT;
  p_Status_b192f120 VARCHAR(25);
  p_IsCustom_b192f120 BOOLEAN;
  p_MetadataSource_b192f120 VARCHAR(20);
BEGIN
  p_ID_b192f120 := 'FCFBE228-988A-595C-B65B-FE135B65CA6D';
  p_IntegrationObjectID_b192f120 := 'C72BE662-43B8-5398-BE8F-FD2145295A4D';
  p_Name_b192f120 := 'source-name';
  p_DisplayName_b192f120 := 'Source Name';
  p_Description_b192f120 := 'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.';
  p_Type_b192f120 := 'String';
  p_Length_b192f120 := 500;
  p_AllowsNull_b192f120 := TRUE;
  p_IsPrimaryKey_b192f120 := FALSE;
  p_IsUniqueKey_b192f120 := FALSE;
  p_IsReadOnly_b192f120 := TRUE;
  p_IsRequired_b192f120 := FALSE;
  p_Sequence_b192f120 := 8;
  p_Status_b192f120 := 'Active';
  p_IsCustom_b192f120 := FALSE;
  p_MetadataSource_b192f120 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_b192f120, p_IntegrationObjectID := p_IntegrationObjectID_b192f120, p_Name := p_Name_b192f120, p_DisplayName := p_DisplayName_b192f120, p_Description := p_Description_b192f120, p_Category := p_Category_b192f120, p_Category_Clear := TRUE, p_Type := p_Type_b192f120, p_Length := p_Length_b192f120, p_Precision := p_Precision_b192f120, p_Precision_Clear := TRUE, p_Scale := p_Scale_b192f120, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_b192f120, p_DefaultValue := p_DefaultValue_b192f120, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_b192f120, p_IsUniqueKey := p_IsUniqueKey_b192f120, p_IsReadOnly := p_IsReadOnly_b192f120, p_IsRequired := p_IsRequired_b192f120, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_b192f120, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_b192f120, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_b192f120, p_Configuration := p_Configuration_b192f120, p_Configuration_Clear := TRUE, p_Status := p_Status_b192f120, p_IsCustom := p_IsCustom_b192f120, p_MetadataSource := p_MetadataSource_b192f120);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_cdb49a50 UUID;
  p_IntegrationObjectID_cdb49a50 UUID;
  p_Name_cdb49a50 VARCHAR(255);
  p_DisplayName_cdb49a50 VARCHAR(255);
  p_Description_cdb49a50 TEXT;
  p_Category_cdb49a50 VARCHAR(100);
  p_Type_cdb49a50 VARCHAR(100);
  p_Length_cdb49a50 INTEGER;
  p_Precision_cdb49a50 INTEGER;
  p_Scale_cdb49a50 INTEGER;
  p_AllowsNull_cdb49a50 BOOLEAN;
  p_DefaultValue_cdb49a50 VARCHAR(255);
  p_IsPrimaryKey_cdb49a50 BOOLEAN;
  p_IsUniqueKey_cdb49a50 BOOLEAN;
  p_IsReadOnly_cdb49a50 BOOLEAN;
  p_IsRequired_cdb49a50 BOOLEAN;
  p_RelatedIntegrationObjectID_cdb49a50 UUID;
  p_RelatedIntegrationObjectFieldName_cdb49a50 VARCHAR(255);
  p_Sequence_cdb49a50 INTEGER;
  p_Configuration_cdb49a50 TEXT;
  p_Status_cdb49a50 VARCHAR(25);
  p_IsCustom_cdb49a50 BOOLEAN;
  p_MetadataSource_cdb49a50 VARCHAR(20);
BEGIN
  p_ID_cdb49a50 := '2FDFBC5A-D551-5FF9-B9F9-32504BAA53B7';
  p_IntegrationObjectID_cdb49a50 := 'C72BE662-43B8-5398-BE8F-FD2145295A4D';
  p_Name_cdb49a50 := 'source-orcid';
  p_DisplayName_cdb49a50 := 'Source Orcid';
  p_Description_cdb49a50 := 'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.';
  p_Type_cdb49a50 := 'String';
  p_Length_cdb49a50 := 19;
  p_AllowsNull_cdb49a50 := TRUE;
  p_IsPrimaryKey_cdb49a50 := FALSE;
  p_IsUniqueKey_cdb49a50 := FALSE;
  p_IsReadOnly_cdb49a50 := TRUE;
  p_IsRequired_cdb49a50 := FALSE;
  p_Sequence_cdb49a50 := 9;
  p_Status_cdb49a50 := 'Active';
  p_IsCustom_cdb49a50 := FALSE;
  p_MetadataSource_cdb49a50 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_cdb49a50, p_IntegrationObjectID := p_IntegrationObjectID_cdb49a50, p_Name := p_Name_cdb49a50, p_DisplayName := p_DisplayName_cdb49a50, p_Description := p_Description_cdb49a50, p_Category := p_Category_cdb49a50, p_Category_Clear := TRUE, p_Type := p_Type_cdb49a50, p_Length := p_Length_cdb49a50, p_Precision := p_Precision_cdb49a50, p_Precision_Clear := TRUE, p_Scale := p_Scale_cdb49a50, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_cdb49a50, p_DefaultValue := p_DefaultValue_cdb49a50, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_cdb49a50, p_IsUniqueKey := p_IsUniqueKey_cdb49a50, p_IsReadOnly := p_IsReadOnly_cdb49a50, p_IsRequired := p_IsRequired_cdb49a50, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_cdb49a50, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_cdb49a50, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_cdb49a50, p_Configuration := p_Configuration_cdb49a50, p_Configuration_Clear := TRUE, p_Status := p_Status_cdb49a50, p_IsCustom := p_IsCustom_cdb49a50, p_MetadataSource := p_MetadataSource_cdb49a50);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_839496f9 UUID;
  p_IntegrationObjectID_839496f9 UUID;
  p_Name_839496f9 VARCHAR(255);
  p_DisplayName_839496f9 VARCHAR(255);
  p_Description_839496f9 TEXT;
  p_Category_839496f9 VARCHAR(100);
  p_Type_839496f9 VARCHAR(100);
  p_Length_839496f9 INTEGER;
  p_Precision_839496f9 INTEGER;
  p_Scale_839496f9 INTEGER;
  p_AllowsNull_839496f9 BOOLEAN;
  p_DefaultValue_839496f9 VARCHAR(255);
  p_IsPrimaryKey_839496f9 BOOLEAN;
  p_IsUniqueKey_839496f9 BOOLEAN;
  p_IsReadOnly_839496f9 BOOLEAN;
  p_IsRequired_839496f9 BOOLEAN;
  p_RelatedIntegrationObjectID_839496f9 UUID;
  p_RelatedIntegrationObjectFieldName_839496f9 VARCHAR(255);
  p_Sequence_839496f9 INTEGER;
  p_Configuration_839496f9 TEXT;
  p_Status_839496f9 VARCHAR(25);
  p_IsCustom_839496f9 BOOLEAN;
  p_MetadataSource_839496f9 VARCHAR(20);
BEGIN
  p_ID_839496f9 := '3F49FD1C-BD4E-57D6-BB0B-4EB3BCB34B6F';
  p_IntegrationObjectID_839496f9 := 'C72BE662-43B8-5398-BE8F-FD2145295A4D';
  p_Name_839496f9 := 'content';
  p_DisplayName_839496f9 := 'Content';
  p_Description_839496f9 := 'The keyword.';
  p_Type_839496f9 := 'String';
  p_Length_839496f9 := 1000;
  p_AllowsNull_839496f9 := TRUE;
  p_IsPrimaryKey_839496f9 := FALSE;
  p_IsUniqueKey_839496f9 := FALSE;
  p_IsReadOnly_839496f9 := TRUE;
  p_IsRequired_839496f9 := FALSE;
  p_Sequence_839496f9 := 10;
  p_Status_839496f9 := 'Active';
  p_IsCustom_839496f9 := FALSE;
  p_MetadataSource_839496f9 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_839496f9, p_IntegrationObjectID := p_IntegrationObjectID_839496f9, p_Name := p_Name_839496f9, p_DisplayName := p_DisplayName_839496f9, p_Description := p_Description_839496f9, p_Category := p_Category_839496f9, p_Category_Clear := TRUE, p_Type := p_Type_839496f9, p_Length := p_Length_839496f9, p_Precision := p_Precision_839496f9, p_Precision_Clear := TRUE, p_Scale := p_Scale_839496f9, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_839496f9, p_DefaultValue := p_DefaultValue_839496f9, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_839496f9, p_IsUniqueKey := p_IsUniqueKey_839496f9, p_IsReadOnly := p_IsReadOnly_839496f9, p_IsRequired := p_IsRequired_839496f9, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_839496f9, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_839496f9, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_839496f9, p_Configuration := p_Configuration_839496f9, p_Configuration_Clear := TRUE, p_Status := p_Status_839496f9, p_IsCustom := p_IsCustom_839496f9, p_MetadataSource := p_MetadataSource_839496f9);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_8e008328 UUID;
  p_IntegrationObjectID_8e008328 UUID;
  p_Name_8e008328 VARCHAR(255);
  p_DisplayName_8e008328 VARCHAR(255);
  p_Description_8e008328 TEXT;
  p_Category_8e008328 VARCHAR(100);
  p_Type_8e008328 VARCHAR(100);
  p_Length_8e008328 INTEGER;
  p_Precision_8e008328 INTEGER;
  p_Scale_8e008328 INTEGER;
  p_AllowsNull_8e008328 BOOLEAN;
  p_DefaultValue_8e008328 VARCHAR(255);
  p_IsPrimaryKey_8e008328 BOOLEAN;
  p_IsUniqueKey_8e008328 BOOLEAN;
  p_IsReadOnly_8e008328 BOOLEAN;
  p_IsRequired_8e008328 BOOLEAN;
  p_RelatedIntegrationObjectID_8e008328 UUID;
  p_RelatedIntegrationObjectFieldName_8e008328 VARCHAR(255);
  p_Sequence_8e008328 INTEGER;
  p_Configuration_8e008328 TEXT;
  p_Status_8e008328 VARCHAR(25);
  p_IsCustom_8e008328 BOOLEAN;
  p_MetadataSource_8e008328 VARCHAR(20);
BEGIN
  p_ID_8e008328 := '7A52B43E-0880-532E-894E-CCC38CC88AED';
  p_IntegrationObjectID_8e008328 := 'FB6D0904-DD1C-54A2-99AD-901CC4B56562';
  p_Name_8e008328 := 'orcid-id';
  p_DisplayName_8e008328 := 'Orcid Id';
  p_Description_8e008328 := 'The ORCID iD of the researcher this item belongs to. Foreign key to the record object.';
  p_Type_8e008328 := 'String';
  p_Length_8e008328 := 19;
  p_AllowsNull_8e008328 := TRUE;
  p_IsPrimaryKey_8e008328 := FALSE;
  p_IsUniqueKey_8e008328 := FALSE;
  p_IsReadOnly_8e008328 := TRUE;
  p_IsRequired_8e008328 := TRUE;
  p_RelatedIntegrationObjectID_8e008328 := '73AED6B8-468D-403B-B994-F3C786C98BC0';
  p_RelatedIntegrationObjectFieldName_8e008328 := 'orcid-id';
  p_Sequence_8e008328 := 0;
  p_Status_8e008328 := 'Active';
  p_IsCustom_8e008328 := FALSE;
  p_MetadataSource_8e008328 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_8e008328, p_IntegrationObjectID := p_IntegrationObjectID_8e008328, p_Name := p_Name_8e008328, p_DisplayName := p_DisplayName_8e008328, p_Description := p_Description_8e008328, p_Category := p_Category_8e008328, p_Category_Clear := TRUE, p_Type := p_Type_8e008328, p_Length := p_Length_8e008328, p_Precision := p_Precision_8e008328, p_Precision_Clear := TRUE, p_Scale := p_Scale_8e008328, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_8e008328, p_DefaultValue := p_DefaultValue_8e008328, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_8e008328, p_IsUniqueKey := p_IsUniqueKey_8e008328, p_IsReadOnly := p_IsReadOnly_8e008328, p_IsRequired := p_IsRequired_8e008328, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_8e008328, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_8e008328, p_Sequence := p_Sequence_8e008328, p_Configuration := p_Configuration_8e008328, p_Configuration_Clear := TRUE, p_Status := p_Status_8e008328, p_IsCustom := p_IsCustom_8e008328, p_MetadataSource := p_MetadataSource_8e008328);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_e94509e0 UUID;
  p_IntegrationObjectID_e94509e0 UUID;
  p_Name_e94509e0 VARCHAR(255);
  p_DisplayName_e94509e0 VARCHAR(255);
  p_Description_e94509e0 TEXT;
  p_Category_e94509e0 VARCHAR(100);
  p_Type_e94509e0 VARCHAR(100);
  p_Length_e94509e0 INTEGER;
  p_Precision_e94509e0 INTEGER;
  p_Scale_e94509e0 INTEGER;
  p_AllowsNull_e94509e0 BOOLEAN;
  p_DefaultValue_e94509e0 VARCHAR(255);
  p_IsPrimaryKey_e94509e0 BOOLEAN;
  p_IsUniqueKey_e94509e0 BOOLEAN;
  p_IsReadOnly_e94509e0 BOOLEAN;
  p_IsRequired_e94509e0 BOOLEAN;
  p_RelatedIntegrationObjectID_e94509e0 UUID;
  p_RelatedIntegrationObjectFieldName_e94509e0 VARCHAR(255);
  p_Sequence_e94509e0 INTEGER;
  p_Configuration_e94509e0 TEXT;
  p_Status_e94509e0 VARCHAR(25);
  p_IsCustom_e94509e0 BOOLEAN;
  p_MetadataSource_e94509e0 VARCHAR(20);
BEGIN
  p_ID_e94509e0 := 'AA06F2EC-04A3-50C8-91E8-AFB5F97BD540';
  p_IntegrationObjectID_e94509e0 := 'FB6D0904-DD1C-54A2-99AD-901CC4B56562';
  p_Name_e94509e0 := 'put-code';
  p_DisplayName_e94509e0 := 'Put Code';
  p_Description_e94509e0 := 'ORCID''s stable identifier for this item within the record. Primary key.';
  p_Type_e94509e0 := 'Integer';
  p_AllowsNull_e94509e0 := FALSE;
  p_IsPrimaryKey_e94509e0 := TRUE;
  p_IsUniqueKey_e94509e0 := TRUE;
  p_IsReadOnly_e94509e0 := TRUE;
  p_IsRequired_e94509e0 := TRUE;
  p_Sequence_e94509e0 := 1;
  p_Status_e94509e0 := 'Active';
  p_IsCustom_e94509e0 := FALSE;
  p_MetadataSource_e94509e0 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_e94509e0, p_IntegrationObjectID := p_IntegrationObjectID_e94509e0, p_Name := p_Name_e94509e0, p_DisplayName := p_DisplayName_e94509e0, p_Description := p_Description_e94509e0, p_Category := p_Category_e94509e0, p_Category_Clear := TRUE, p_Type := p_Type_e94509e0, p_Length := p_Length_e94509e0, p_Length_Clear := TRUE, p_Precision := p_Precision_e94509e0, p_Precision_Clear := TRUE, p_Scale := p_Scale_e94509e0, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_e94509e0, p_DefaultValue := p_DefaultValue_e94509e0, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_e94509e0, p_IsUniqueKey := p_IsUniqueKey_e94509e0, p_IsReadOnly := p_IsReadOnly_e94509e0, p_IsRequired := p_IsRequired_e94509e0, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_e94509e0, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_e94509e0, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_e94509e0, p_Configuration := p_Configuration_e94509e0, p_Configuration_Clear := TRUE, p_Status := p_Status_e94509e0, p_IsCustom := p_IsCustom_e94509e0, p_MetadataSource := p_MetadataSource_e94509e0);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_adaab283 UUID;
  p_IntegrationObjectID_adaab283 UUID;
  p_Name_adaab283 VARCHAR(255);
  p_DisplayName_adaab283 VARCHAR(255);
  p_Description_adaab283 TEXT;
  p_Category_adaab283 VARCHAR(100);
  p_Type_adaab283 VARCHAR(100);
  p_Length_adaab283 INTEGER;
  p_Precision_adaab283 INTEGER;
  p_Scale_adaab283 INTEGER;
  p_AllowsNull_adaab283 BOOLEAN;
  p_DefaultValue_adaab283 VARCHAR(255);
  p_IsPrimaryKey_adaab283 BOOLEAN;
  p_IsUniqueKey_adaab283 BOOLEAN;
  p_IsReadOnly_adaab283 BOOLEAN;
  p_IsRequired_adaab283 BOOLEAN;
  p_RelatedIntegrationObjectID_adaab283 UUID;
  p_RelatedIntegrationObjectFieldName_adaab283 VARCHAR(255);
  p_Sequence_adaab283 INTEGER;
  p_Configuration_adaab283 TEXT;
  p_Status_adaab283 VARCHAR(25);
  p_IsCustom_adaab283 BOOLEAN;
  p_MetadataSource_adaab283 VARCHAR(20);
BEGIN
  p_ID_adaab283 := '1D53B1A1-3714-524F-BE19-4440B45C0F68';
  p_IntegrationObjectID_adaab283 := 'FB6D0904-DD1C-54A2-99AD-901CC4B56562';
  p_Name_adaab283 := 'path';
  p_DisplayName_adaab283 := 'Path';
  p_Description_adaab283 := 'Element path /{orcid}/{section}/{put-code}.';
  p_Type_adaab283 := 'String';
  p_Length_adaab283 := 500;
  p_AllowsNull_adaab283 := TRUE;
  p_IsPrimaryKey_adaab283 := FALSE;
  p_IsUniqueKey_adaab283 := FALSE;
  p_IsReadOnly_adaab283 := TRUE;
  p_IsRequired_adaab283 := FALSE;
  p_Sequence_adaab283 := 2;
  p_Status_adaab283 := 'Active';
  p_IsCustom_adaab283 := FALSE;
  p_MetadataSource_adaab283 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_adaab283, p_IntegrationObjectID := p_IntegrationObjectID_adaab283, p_Name := p_Name_adaab283, p_DisplayName := p_DisplayName_adaab283, p_Description := p_Description_adaab283, p_Category := p_Category_adaab283, p_Category_Clear := TRUE, p_Type := p_Type_adaab283, p_Length := p_Length_adaab283, p_Precision := p_Precision_adaab283, p_Precision_Clear := TRUE, p_Scale := p_Scale_adaab283, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_adaab283, p_DefaultValue := p_DefaultValue_adaab283, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_adaab283, p_IsUniqueKey := p_IsUniqueKey_adaab283, p_IsReadOnly := p_IsReadOnly_adaab283, p_IsRequired := p_IsRequired_adaab283, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_adaab283, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_adaab283, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_adaab283, p_Configuration := p_Configuration_adaab283, p_Configuration_Clear := TRUE, p_Status := p_Status_adaab283, p_IsCustom := p_IsCustom_adaab283, p_MetadataSource := p_MetadataSource_adaab283);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_41ee17af UUID;
  p_IntegrationObjectID_41ee17af UUID;
  p_Name_41ee17af VARCHAR(255);
  p_DisplayName_41ee17af VARCHAR(255);
  p_Description_41ee17af TEXT;
  p_Category_41ee17af VARCHAR(100);
  p_Type_41ee17af VARCHAR(100);
  p_Length_41ee17af INTEGER;
  p_Precision_41ee17af INTEGER;
  p_Scale_41ee17af INTEGER;
  p_AllowsNull_41ee17af BOOLEAN;
  p_DefaultValue_41ee17af VARCHAR(255);
  p_IsPrimaryKey_41ee17af BOOLEAN;
  p_IsUniqueKey_41ee17af BOOLEAN;
  p_IsReadOnly_41ee17af BOOLEAN;
  p_IsRequired_41ee17af BOOLEAN;
  p_RelatedIntegrationObjectID_41ee17af UUID;
  p_RelatedIntegrationObjectFieldName_41ee17af VARCHAR(255);
  p_Sequence_41ee17af INTEGER;
  p_Configuration_41ee17af TEXT;
  p_Status_41ee17af VARCHAR(25);
  p_IsCustom_41ee17af BOOLEAN;
  p_MetadataSource_41ee17af VARCHAR(20);
BEGIN
  p_ID_41ee17af := '337BBF35-C60C-5870-B463-09A8614A316E';
  p_IntegrationObjectID_41ee17af := 'FB6D0904-DD1C-54A2-99AD-901CC4B56562';
  p_Name_41ee17af := 'visibility';
  p_DisplayName_41ee17af := 'Visibility';
  p_Description_41ee17af := 'ORCID visibility of the item (public, limited, private). The Public API only serves public.';
  p_Type_41ee17af := 'String';
  p_AllowsNull_41ee17af := TRUE;
  p_IsPrimaryKey_41ee17af := FALSE;
  p_IsUniqueKey_41ee17af := FALSE;
  p_IsReadOnly_41ee17af := TRUE;
  p_IsRequired_41ee17af := FALSE;
  p_Sequence_41ee17af := 3;
  p_Status_41ee17af := 'Active';
  p_IsCustom_41ee17af := FALSE;
  p_MetadataSource_41ee17af := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_41ee17af, p_IntegrationObjectID := p_IntegrationObjectID_41ee17af, p_Name := p_Name_41ee17af, p_DisplayName := p_DisplayName_41ee17af, p_Description := p_Description_41ee17af, p_Category := p_Category_41ee17af, p_Category_Clear := TRUE, p_Type := p_Type_41ee17af, p_Length := p_Length_41ee17af, p_Length_Clear := TRUE, p_Precision := p_Precision_41ee17af, p_Precision_Clear := TRUE, p_Scale := p_Scale_41ee17af, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_41ee17af, p_DefaultValue := p_DefaultValue_41ee17af, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_41ee17af, p_IsUniqueKey := p_IsUniqueKey_41ee17af, p_IsReadOnly := p_IsReadOnly_41ee17af, p_IsRequired := p_IsRequired_41ee17af, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_41ee17af, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_41ee17af, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_41ee17af, p_Configuration := p_Configuration_41ee17af, p_Configuration_Clear := TRUE, p_Status := p_Status_41ee17af, p_IsCustom := p_IsCustom_41ee17af, p_MetadataSource := p_MetadataSource_41ee17af);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_952f1197 UUID;
  p_IntegrationObjectID_952f1197 UUID;
  p_Name_952f1197 VARCHAR(255);
  p_DisplayName_952f1197 VARCHAR(255);
  p_Description_952f1197 TEXT;
  p_Category_952f1197 VARCHAR(100);
  p_Type_952f1197 VARCHAR(100);
  p_Length_952f1197 INTEGER;
  p_Precision_952f1197 INTEGER;
  p_Scale_952f1197 INTEGER;
  p_AllowsNull_952f1197 BOOLEAN;
  p_DefaultValue_952f1197 VARCHAR(255);
  p_IsPrimaryKey_952f1197 BOOLEAN;
  p_IsUniqueKey_952f1197 BOOLEAN;
  p_IsReadOnly_952f1197 BOOLEAN;
  p_IsRequired_952f1197 BOOLEAN;
  p_RelatedIntegrationObjectID_952f1197 UUID;
  p_RelatedIntegrationObjectFieldName_952f1197 VARCHAR(255);
  p_Sequence_952f1197 INTEGER;
  p_Configuration_952f1197 TEXT;
  p_Status_952f1197 VARCHAR(25);
  p_IsCustom_952f1197 BOOLEAN;
  p_MetadataSource_952f1197 VARCHAR(20);
BEGIN
  p_ID_952f1197 := '68385D55-06E8-53B0-B5E8-E53BFBACEBEB';
  p_IntegrationObjectID_952f1197 := 'FB6D0904-DD1C-54A2-99AD-901CC4B56562';
  p_Name_952f1197 := 'display-index';
  p_DisplayName_952f1197 := 'Display Index';
  p_Description_952f1197 := 'Display order the researcher chose for the item.';
  p_Type_952f1197 := 'String';
  p_AllowsNull_952f1197 := TRUE;
  p_IsPrimaryKey_952f1197 := FALSE;
  p_IsUniqueKey_952f1197 := FALSE;
  p_IsReadOnly_952f1197 := TRUE;
  p_IsRequired_952f1197 := FALSE;
  p_Sequence_952f1197 := 4;
  p_Status_952f1197 := 'Active';
  p_IsCustom_952f1197 := FALSE;
  p_MetadataSource_952f1197 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_952f1197, p_IntegrationObjectID := p_IntegrationObjectID_952f1197, p_Name := p_Name_952f1197, p_DisplayName := p_DisplayName_952f1197, p_Description := p_Description_952f1197, p_Category := p_Category_952f1197, p_Category_Clear := TRUE, p_Type := p_Type_952f1197, p_Length := p_Length_952f1197, p_Length_Clear := TRUE, p_Precision := p_Precision_952f1197, p_Precision_Clear := TRUE, p_Scale := p_Scale_952f1197, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_952f1197, p_DefaultValue := p_DefaultValue_952f1197, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_952f1197, p_IsUniqueKey := p_IsUniqueKey_952f1197, p_IsReadOnly := p_IsReadOnly_952f1197, p_IsRequired := p_IsRequired_952f1197, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_952f1197, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_952f1197, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_952f1197, p_Configuration := p_Configuration_952f1197, p_Configuration_Clear := TRUE, p_Status := p_Status_952f1197, p_IsCustom := p_IsCustom_952f1197, p_MetadataSource := p_MetadataSource_952f1197);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_00468658 UUID;
  p_IntegrationObjectID_00468658 UUID;
  p_Name_00468658 VARCHAR(255);
  p_DisplayName_00468658 VARCHAR(255);
  p_Description_00468658 TEXT;
  p_Category_00468658 VARCHAR(100);
  p_Type_00468658 VARCHAR(100);
  p_Length_00468658 INTEGER;
  p_Precision_00468658 INTEGER;
  p_Scale_00468658 INTEGER;
  p_AllowsNull_00468658 BOOLEAN;
  p_DefaultValue_00468658 VARCHAR(255);
  p_IsPrimaryKey_00468658 BOOLEAN;
  p_IsUniqueKey_00468658 BOOLEAN;
  p_IsReadOnly_00468658 BOOLEAN;
  p_IsRequired_00468658 BOOLEAN;
  p_RelatedIntegrationObjectID_00468658 UUID;
  p_RelatedIntegrationObjectFieldName_00468658 VARCHAR(255);
  p_Sequence_00468658 INTEGER;
  p_Configuration_00468658 TEXT;
  p_Status_00468658 VARCHAR(25);
  p_IsCustom_00468658 BOOLEAN;
  p_MetadataSource_00468658 VARCHAR(20);
BEGIN
  p_ID_00468658 := '2C91E9CD-2902-5B31-A66B-C1E358C07D41';
  p_IntegrationObjectID_00468658 := 'FB6D0904-DD1C-54A2-99AD-901CC4B56562';
  p_Name_00468658 := 'created-date';
  p_DisplayName_00468658 := 'Created Date';
  p_Description_00468658 := 'When ORCID created the item.';
  p_Type_00468658 := 'DateTime';
  p_AllowsNull_00468658 := TRUE;
  p_IsPrimaryKey_00468658 := FALSE;
  p_IsUniqueKey_00468658 := FALSE;
  p_IsReadOnly_00468658 := TRUE;
  p_IsRequired_00468658 := FALSE;
  p_Sequence_00468658 := 5;
  p_Status_00468658 := 'Active';
  p_IsCustom_00468658 := FALSE;
  p_MetadataSource_00468658 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_00468658, p_IntegrationObjectID := p_IntegrationObjectID_00468658, p_Name := p_Name_00468658, p_DisplayName := p_DisplayName_00468658, p_Description := p_Description_00468658, p_Category := p_Category_00468658, p_Category_Clear := TRUE, p_Type := p_Type_00468658, p_Length := p_Length_00468658, p_Length_Clear := TRUE, p_Precision := p_Precision_00468658, p_Precision_Clear := TRUE, p_Scale := p_Scale_00468658, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_00468658, p_DefaultValue := p_DefaultValue_00468658, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_00468658, p_IsUniqueKey := p_IsUniqueKey_00468658, p_IsReadOnly := p_IsReadOnly_00468658, p_IsRequired := p_IsRequired_00468658, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_00468658, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_00468658, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_00468658, p_Configuration := p_Configuration_00468658, p_Configuration_Clear := TRUE, p_Status := p_Status_00468658, p_IsCustom := p_IsCustom_00468658, p_MetadataSource := p_MetadataSource_00468658);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_895a05fd UUID;
  p_IntegrationObjectID_895a05fd UUID;
  p_Name_895a05fd VARCHAR(255);
  p_DisplayName_895a05fd VARCHAR(255);
  p_Description_895a05fd TEXT;
  p_Category_895a05fd VARCHAR(100);
  p_Type_895a05fd VARCHAR(100);
  p_Length_895a05fd INTEGER;
  p_Precision_895a05fd INTEGER;
  p_Scale_895a05fd INTEGER;
  p_AllowsNull_895a05fd BOOLEAN;
  p_DefaultValue_895a05fd VARCHAR(255);
  p_IsPrimaryKey_895a05fd BOOLEAN;
  p_IsUniqueKey_895a05fd BOOLEAN;
  p_IsReadOnly_895a05fd BOOLEAN;
  p_IsRequired_895a05fd BOOLEAN;
  p_RelatedIntegrationObjectID_895a05fd UUID;
  p_RelatedIntegrationObjectFieldName_895a05fd VARCHAR(255);
  p_Sequence_895a05fd INTEGER;
  p_Configuration_895a05fd TEXT;
  p_Status_895a05fd VARCHAR(25);
  p_IsCustom_895a05fd BOOLEAN;
  p_MetadataSource_895a05fd VARCHAR(20);
BEGIN
  p_ID_895a05fd := '102187F1-E6D8-599B-96A5-E56E98692977';
  p_IntegrationObjectID_895a05fd := 'FB6D0904-DD1C-54A2-99AD-901CC4B56562';
  p_Name_895a05fd := 'last-modified-date';
  p_DisplayName_895a05fd := 'Last Modified Date';
  p_Description_895a05fd := 'When ORCID last changed the item. Incremental watermark.';
  p_Type_895a05fd := 'DateTime';
  p_AllowsNull_895a05fd := TRUE;
  p_IsPrimaryKey_895a05fd := FALSE;
  p_IsUniqueKey_895a05fd := FALSE;
  p_IsReadOnly_895a05fd := TRUE;
  p_IsRequired_895a05fd := FALSE;
  p_Sequence_895a05fd := 6;
  p_Status_895a05fd := 'Active';
  p_IsCustom_895a05fd := FALSE;
  p_MetadataSource_895a05fd := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_895a05fd, p_IntegrationObjectID := p_IntegrationObjectID_895a05fd, p_Name := p_Name_895a05fd, p_DisplayName := p_DisplayName_895a05fd, p_Description := p_Description_895a05fd, p_Category := p_Category_895a05fd, p_Category_Clear := TRUE, p_Type := p_Type_895a05fd, p_Length := p_Length_895a05fd, p_Length_Clear := TRUE, p_Precision := p_Precision_895a05fd, p_Precision_Clear := TRUE, p_Scale := p_Scale_895a05fd, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_895a05fd, p_DefaultValue := p_DefaultValue_895a05fd, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_895a05fd, p_IsUniqueKey := p_IsUniqueKey_895a05fd, p_IsReadOnly := p_IsReadOnly_895a05fd, p_IsRequired := p_IsRequired_895a05fd, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_895a05fd, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_895a05fd, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_895a05fd, p_Configuration := p_Configuration_895a05fd, p_Configuration_Clear := TRUE, p_Status := p_Status_895a05fd, p_IsCustom := p_IsCustom_895a05fd, p_MetadataSource := p_MetadataSource_895a05fd);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_27802afe UUID;
  p_IntegrationObjectID_27802afe UUID;
  p_Name_27802afe VARCHAR(255);
  p_DisplayName_27802afe VARCHAR(255);
  p_Description_27802afe TEXT;
  p_Category_27802afe VARCHAR(100);
  p_Type_27802afe VARCHAR(100);
  p_Length_27802afe INTEGER;
  p_Precision_27802afe INTEGER;
  p_Scale_27802afe INTEGER;
  p_AllowsNull_27802afe BOOLEAN;
  p_DefaultValue_27802afe VARCHAR(255);
  p_IsPrimaryKey_27802afe BOOLEAN;
  p_IsUniqueKey_27802afe BOOLEAN;
  p_IsReadOnly_27802afe BOOLEAN;
  p_IsRequired_27802afe BOOLEAN;
  p_RelatedIntegrationObjectID_27802afe UUID;
  p_RelatedIntegrationObjectFieldName_27802afe VARCHAR(255);
  p_Sequence_27802afe INTEGER;
  p_Configuration_27802afe TEXT;
  p_Status_27802afe VARCHAR(25);
  p_IsCustom_27802afe BOOLEAN;
  p_MetadataSource_27802afe VARCHAR(20);
BEGIN
  p_ID_27802afe := '80946956-2C57-504E-AE9A-31E1CABFD749';
  p_IntegrationObjectID_27802afe := 'FB6D0904-DD1C-54A2-99AD-901CC4B56562';
  p_Name_27802afe := 'source';
  p_DisplayName_27802afe := 'Source';
  p_Description_27802afe := 'Full source block: who asserted the item.';
  p_Type_27802afe := 'json';
  p_AllowsNull_27802afe := TRUE;
  p_IsPrimaryKey_27802afe := FALSE;
  p_IsUniqueKey_27802afe := FALSE;
  p_IsReadOnly_27802afe := TRUE;
  p_IsRequired_27802afe := FALSE;
  p_Sequence_27802afe := 7;
  p_Status_27802afe := 'Active';
  p_IsCustom_27802afe := FALSE;
  p_MetadataSource_27802afe := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_27802afe, p_IntegrationObjectID := p_IntegrationObjectID_27802afe, p_Name := p_Name_27802afe, p_DisplayName := p_DisplayName_27802afe, p_Description := p_Description_27802afe, p_Category := p_Category_27802afe, p_Category_Clear := TRUE, p_Type := p_Type_27802afe, p_Length := p_Length_27802afe, p_Length_Clear := TRUE, p_Precision := p_Precision_27802afe, p_Precision_Clear := TRUE, p_Scale := p_Scale_27802afe, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_27802afe, p_DefaultValue := p_DefaultValue_27802afe, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_27802afe, p_IsUniqueKey := p_IsUniqueKey_27802afe, p_IsReadOnly := p_IsReadOnly_27802afe, p_IsRequired := p_IsRequired_27802afe, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_27802afe, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_27802afe, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_27802afe, p_Configuration := p_Configuration_27802afe, p_Configuration_Clear := TRUE, p_Status := p_Status_27802afe, p_IsCustom := p_IsCustom_27802afe, p_MetadataSource := p_MetadataSource_27802afe);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_ea283fa9 UUID;
  p_IntegrationObjectID_ea283fa9 UUID;
  p_Name_ea283fa9 VARCHAR(255);
  p_DisplayName_ea283fa9 VARCHAR(255);
  p_Description_ea283fa9 TEXT;
  p_Category_ea283fa9 VARCHAR(100);
  p_Type_ea283fa9 VARCHAR(100);
  p_Length_ea283fa9 INTEGER;
  p_Precision_ea283fa9 INTEGER;
  p_Scale_ea283fa9 INTEGER;
  p_AllowsNull_ea283fa9 BOOLEAN;
  p_DefaultValue_ea283fa9 VARCHAR(255);
  p_IsPrimaryKey_ea283fa9 BOOLEAN;
  p_IsUniqueKey_ea283fa9 BOOLEAN;
  p_IsReadOnly_ea283fa9 BOOLEAN;
  p_IsRequired_ea283fa9 BOOLEAN;
  p_RelatedIntegrationObjectID_ea283fa9 UUID;
  p_RelatedIntegrationObjectFieldName_ea283fa9 VARCHAR(255);
  p_Sequence_ea283fa9 INTEGER;
  p_Configuration_ea283fa9 TEXT;
  p_Status_ea283fa9 VARCHAR(25);
  p_IsCustom_ea283fa9 BOOLEAN;
  p_MetadataSource_ea283fa9 VARCHAR(20);
BEGIN
  p_ID_ea283fa9 := 'C4076D7B-A9A3-5AA5-AD71-2A58303A9367';
  p_IntegrationObjectID_ea283fa9 := 'FB6D0904-DD1C-54A2-99AD-901CC4B56562';
  p_Name_ea283fa9 := 'source-name';
  p_DisplayName_ea283fa9 := 'Source Name';
  p_Description_ea283fa9 := 'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.';
  p_Type_ea283fa9 := 'String';
  p_Length_ea283fa9 := 500;
  p_AllowsNull_ea283fa9 := TRUE;
  p_IsPrimaryKey_ea283fa9 := FALSE;
  p_IsUniqueKey_ea283fa9 := FALSE;
  p_IsReadOnly_ea283fa9 := TRUE;
  p_IsRequired_ea283fa9 := FALSE;
  p_Sequence_ea283fa9 := 8;
  p_Status_ea283fa9 := 'Active';
  p_IsCustom_ea283fa9 := FALSE;
  p_MetadataSource_ea283fa9 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_ea283fa9, p_IntegrationObjectID := p_IntegrationObjectID_ea283fa9, p_Name := p_Name_ea283fa9, p_DisplayName := p_DisplayName_ea283fa9, p_Description := p_Description_ea283fa9, p_Category := p_Category_ea283fa9, p_Category_Clear := TRUE, p_Type := p_Type_ea283fa9, p_Length := p_Length_ea283fa9, p_Precision := p_Precision_ea283fa9, p_Precision_Clear := TRUE, p_Scale := p_Scale_ea283fa9, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_ea283fa9, p_DefaultValue := p_DefaultValue_ea283fa9, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_ea283fa9, p_IsUniqueKey := p_IsUniqueKey_ea283fa9, p_IsReadOnly := p_IsReadOnly_ea283fa9, p_IsRequired := p_IsRequired_ea283fa9, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_ea283fa9, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_ea283fa9, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_ea283fa9, p_Configuration := p_Configuration_ea283fa9, p_Configuration_Clear := TRUE, p_Status := p_Status_ea283fa9, p_IsCustom := p_IsCustom_ea283fa9, p_MetadataSource := p_MetadataSource_ea283fa9);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_3f513b53 UUID;
  p_IntegrationObjectID_3f513b53 UUID;
  p_Name_3f513b53 VARCHAR(255);
  p_DisplayName_3f513b53 VARCHAR(255);
  p_Description_3f513b53 TEXT;
  p_Category_3f513b53 VARCHAR(100);
  p_Type_3f513b53 VARCHAR(100);
  p_Length_3f513b53 INTEGER;
  p_Precision_3f513b53 INTEGER;
  p_Scale_3f513b53 INTEGER;
  p_AllowsNull_3f513b53 BOOLEAN;
  p_DefaultValue_3f513b53 VARCHAR(255);
  p_IsPrimaryKey_3f513b53 BOOLEAN;
  p_IsUniqueKey_3f513b53 BOOLEAN;
  p_IsReadOnly_3f513b53 BOOLEAN;
  p_IsRequired_3f513b53 BOOLEAN;
  p_RelatedIntegrationObjectID_3f513b53 UUID;
  p_RelatedIntegrationObjectFieldName_3f513b53 VARCHAR(255);
  p_Sequence_3f513b53 INTEGER;
  p_Configuration_3f513b53 TEXT;
  p_Status_3f513b53 VARCHAR(25);
  p_IsCustom_3f513b53 BOOLEAN;
  p_MetadataSource_3f513b53 VARCHAR(20);
BEGIN
  p_ID_3f513b53 := 'B521A565-AEF8-5A44-BB4D-9D928A9A982A';
  p_IntegrationObjectID_3f513b53 := 'FB6D0904-DD1C-54A2-99AD-901CC4B56562';
  p_Name_3f513b53 := 'source-orcid';
  p_DisplayName_3f513b53 := 'Source Orcid';
  p_Description_3f513b53 := 'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.';
  p_Type_3f513b53 := 'String';
  p_Length_3f513b53 := 19;
  p_AllowsNull_3f513b53 := TRUE;
  p_IsPrimaryKey_3f513b53 := FALSE;
  p_IsUniqueKey_3f513b53 := FALSE;
  p_IsReadOnly_3f513b53 := TRUE;
  p_IsRequired_3f513b53 := FALSE;
  p_Sequence_3f513b53 := 9;
  p_Status_3f513b53 := 'Active';
  p_IsCustom_3f513b53 := FALSE;
  p_MetadataSource_3f513b53 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_3f513b53, p_IntegrationObjectID := p_IntegrationObjectID_3f513b53, p_Name := p_Name_3f513b53, p_DisplayName := p_DisplayName_3f513b53, p_Description := p_Description_3f513b53, p_Category := p_Category_3f513b53, p_Category_Clear := TRUE, p_Type := p_Type_3f513b53, p_Length := p_Length_3f513b53, p_Precision := p_Precision_3f513b53, p_Precision_Clear := TRUE, p_Scale := p_Scale_3f513b53, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_3f513b53, p_DefaultValue := p_DefaultValue_3f513b53, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_3f513b53, p_IsUniqueKey := p_IsUniqueKey_3f513b53, p_IsReadOnly := p_IsReadOnly_3f513b53, p_IsRequired := p_IsRequired_3f513b53, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_3f513b53, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_3f513b53, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_3f513b53, p_Configuration := p_Configuration_3f513b53, p_Configuration_Clear := TRUE, p_Status := p_Status_3f513b53, p_IsCustom := p_IsCustom_3f513b53, p_MetadataSource := p_MetadataSource_3f513b53);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_3ff2ad0e UUID;
  p_IntegrationObjectID_3ff2ad0e UUID;
  p_Name_3ff2ad0e VARCHAR(255);
  p_DisplayName_3ff2ad0e VARCHAR(255);
  p_Description_3ff2ad0e TEXT;
  p_Category_3ff2ad0e VARCHAR(100);
  p_Type_3ff2ad0e VARCHAR(100);
  p_Length_3ff2ad0e INTEGER;
  p_Precision_3ff2ad0e INTEGER;
  p_Scale_3ff2ad0e INTEGER;
  p_AllowsNull_3ff2ad0e BOOLEAN;
  p_DefaultValue_3ff2ad0e VARCHAR(255);
  p_IsPrimaryKey_3ff2ad0e BOOLEAN;
  p_IsUniqueKey_3ff2ad0e BOOLEAN;
  p_IsReadOnly_3ff2ad0e BOOLEAN;
  p_IsRequired_3ff2ad0e BOOLEAN;
  p_RelatedIntegrationObjectID_3ff2ad0e UUID;
  p_RelatedIntegrationObjectFieldName_3ff2ad0e VARCHAR(255);
  p_Sequence_3ff2ad0e INTEGER;
  p_Configuration_3ff2ad0e TEXT;
  p_Status_3ff2ad0e VARCHAR(25);
  p_IsCustom_3ff2ad0e BOOLEAN;
  p_MetadataSource_3ff2ad0e VARCHAR(20);
BEGIN
  p_ID_3ff2ad0e := '8FA8A100-30F3-5E61-8019-AB1224626A8F';
  p_IntegrationObjectID_3ff2ad0e := 'FB6D0904-DD1C-54A2-99AD-901CC4B56562';
  p_Name_3ff2ad0e := 'email';
  p_DisplayName_3ff2ad0e := 'Email';
  p_Description_3ff2ad0e := 'The email address.';
  p_Type_3ff2ad0e := 'String';
  p_Length_3ff2ad0e := 320;
  p_AllowsNull_3ff2ad0e := TRUE;
  p_IsPrimaryKey_3ff2ad0e := FALSE;
  p_IsUniqueKey_3ff2ad0e := FALSE;
  p_IsReadOnly_3ff2ad0e := TRUE;
  p_IsRequired_3ff2ad0e := FALSE;
  p_Sequence_3ff2ad0e := 10;
  p_Status_3ff2ad0e := 'Active';
  p_IsCustom_3ff2ad0e := FALSE;
  p_MetadataSource_3ff2ad0e := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_3ff2ad0e, p_IntegrationObjectID := p_IntegrationObjectID_3ff2ad0e, p_Name := p_Name_3ff2ad0e, p_DisplayName := p_DisplayName_3ff2ad0e, p_Description := p_Description_3ff2ad0e, p_Category := p_Category_3ff2ad0e, p_Category_Clear := TRUE, p_Type := p_Type_3ff2ad0e, p_Length := p_Length_3ff2ad0e, p_Precision := p_Precision_3ff2ad0e, p_Precision_Clear := TRUE, p_Scale := p_Scale_3ff2ad0e, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_3ff2ad0e, p_DefaultValue := p_DefaultValue_3ff2ad0e, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_3ff2ad0e, p_IsUniqueKey := p_IsUniqueKey_3ff2ad0e, p_IsReadOnly := p_IsReadOnly_3ff2ad0e, p_IsRequired := p_IsRequired_3ff2ad0e, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_3ff2ad0e, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_3ff2ad0e, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_3ff2ad0e, p_Configuration := p_Configuration_3ff2ad0e, p_Configuration_Clear := TRUE, p_Status := p_Status_3ff2ad0e, p_IsCustom := p_IsCustom_3ff2ad0e, p_MetadataSource := p_MetadataSource_3ff2ad0e);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_59186376 UUID;
  p_IntegrationObjectID_59186376 UUID;
  p_Name_59186376 VARCHAR(255);
  p_DisplayName_59186376 VARCHAR(255);
  p_Description_59186376 TEXT;
  p_Category_59186376 VARCHAR(100);
  p_Type_59186376 VARCHAR(100);
  p_Length_59186376 INTEGER;
  p_Precision_59186376 INTEGER;
  p_Scale_59186376 INTEGER;
  p_AllowsNull_59186376 BOOLEAN;
  p_DefaultValue_59186376 VARCHAR(255);
  p_IsPrimaryKey_59186376 BOOLEAN;
  p_IsUniqueKey_59186376 BOOLEAN;
  p_IsReadOnly_59186376 BOOLEAN;
  p_IsRequired_59186376 BOOLEAN;
  p_RelatedIntegrationObjectID_59186376 UUID;
  p_RelatedIntegrationObjectFieldName_59186376 VARCHAR(255);
  p_Sequence_59186376 INTEGER;
  p_Configuration_59186376 TEXT;
  p_Status_59186376 VARCHAR(25);
  p_IsCustom_59186376 BOOLEAN;
  p_MetadataSource_59186376 VARCHAR(20);
BEGIN
  p_ID_59186376 := '5A21652F-0D67-54CA-BAC4-71657BE99FFF';
  p_IntegrationObjectID_59186376 := 'FB6D0904-DD1C-54A2-99AD-901CC4B56562';
  p_Name_59186376 := 'primary';
  p_DisplayName_59186376 := 'Primary';
  p_Description_59186376 := 'Whether this is the researcher''s primary email.';
  p_Type_59186376 := 'Boolean';
  p_AllowsNull_59186376 := TRUE;
  p_IsPrimaryKey_59186376 := FALSE;
  p_IsUniqueKey_59186376 := FALSE;
  p_IsReadOnly_59186376 := TRUE;
  p_IsRequired_59186376 := FALSE;
  p_Sequence_59186376 := 11;
  p_Status_59186376 := 'Active';
  p_IsCustom_59186376 := FALSE;
  p_MetadataSource_59186376 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_59186376, p_IntegrationObjectID := p_IntegrationObjectID_59186376, p_Name := p_Name_59186376, p_DisplayName := p_DisplayName_59186376, p_Description := p_Description_59186376, p_Category := p_Category_59186376, p_Category_Clear := TRUE, p_Type := p_Type_59186376, p_Length := p_Length_59186376, p_Length_Clear := TRUE, p_Precision := p_Precision_59186376, p_Precision_Clear := TRUE, p_Scale := p_Scale_59186376, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_59186376, p_DefaultValue := p_DefaultValue_59186376, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_59186376, p_IsUniqueKey := p_IsUniqueKey_59186376, p_IsReadOnly := p_IsReadOnly_59186376, p_IsRequired := p_IsRequired_59186376, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_59186376, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_59186376, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_59186376, p_Configuration := p_Configuration_59186376, p_Configuration_Clear := TRUE, p_Status := p_Status_59186376, p_IsCustom := p_IsCustom_59186376, p_MetadataSource := p_MetadataSource_59186376);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_634c0c30 UUID;
  p_IntegrationObjectID_634c0c30 UUID;
  p_Name_634c0c30 VARCHAR(255);
  p_DisplayName_634c0c30 VARCHAR(255);
  p_Description_634c0c30 TEXT;
  p_Category_634c0c30 VARCHAR(100);
  p_Type_634c0c30 VARCHAR(100);
  p_Length_634c0c30 INTEGER;
  p_Precision_634c0c30 INTEGER;
  p_Scale_634c0c30 INTEGER;
  p_AllowsNull_634c0c30 BOOLEAN;
  p_DefaultValue_634c0c30 VARCHAR(255);
  p_IsPrimaryKey_634c0c30 BOOLEAN;
  p_IsUniqueKey_634c0c30 BOOLEAN;
  p_IsReadOnly_634c0c30 BOOLEAN;
  p_IsRequired_634c0c30 BOOLEAN;
  p_RelatedIntegrationObjectID_634c0c30 UUID;
  p_RelatedIntegrationObjectFieldName_634c0c30 VARCHAR(255);
  p_Sequence_634c0c30 INTEGER;
  p_Configuration_634c0c30 TEXT;
  p_Status_634c0c30 VARCHAR(25);
  p_IsCustom_634c0c30 BOOLEAN;
  p_MetadataSource_634c0c30 VARCHAR(20);
BEGIN
  p_ID_634c0c30 := '9EFAF38F-340F-5F30-8766-5828F007E547';
  p_IntegrationObjectID_634c0c30 := 'FB6D0904-DD1C-54A2-99AD-901CC4B56562';
  p_Name_634c0c30 := 'verified';
  p_DisplayName_634c0c30 := 'Verified';
  p_Description_634c0c30 := 'Whether ORCID verified the address.';
  p_Type_634c0c30 := 'Boolean';
  p_AllowsNull_634c0c30 := TRUE;
  p_IsPrimaryKey_634c0c30 := FALSE;
  p_IsUniqueKey_634c0c30 := FALSE;
  p_IsReadOnly_634c0c30 := TRUE;
  p_IsRequired_634c0c30 := FALSE;
  p_Sequence_634c0c30 := 12;
  p_Status_634c0c30 := 'Active';
  p_IsCustom_634c0c30 := FALSE;
  p_MetadataSource_634c0c30 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_634c0c30, p_IntegrationObjectID := p_IntegrationObjectID_634c0c30, p_Name := p_Name_634c0c30, p_DisplayName := p_DisplayName_634c0c30, p_Description := p_Description_634c0c30, p_Category := p_Category_634c0c30, p_Category_Clear := TRUE, p_Type := p_Type_634c0c30, p_Length := p_Length_634c0c30, p_Length_Clear := TRUE, p_Precision := p_Precision_634c0c30, p_Precision_Clear := TRUE, p_Scale := p_Scale_634c0c30, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_634c0c30, p_DefaultValue := p_DefaultValue_634c0c30, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_634c0c30, p_IsUniqueKey := p_IsUniqueKey_634c0c30, p_IsReadOnly := p_IsReadOnly_634c0c30, p_IsRequired := p_IsRequired_634c0c30, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_634c0c30, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_634c0c30, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_634c0c30, p_Configuration := p_Configuration_634c0c30, p_Configuration_Clear := TRUE, p_Status := p_Status_634c0c30, p_IsCustom := p_IsCustom_634c0c30, p_MetadataSource := p_MetadataSource_634c0c30);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_fe308582 UUID;
  p_IntegrationObjectID_fe308582 UUID;
  p_Name_fe308582 VARCHAR(255);
  p_DisplayName_fe308582 VARCHAR(255);
  p_Description_fe308582 TEXT;
  p_Category_fe308582 VARCHAR(100);
  p_Type_fe308582 VARCHAR(100);
  p_Length_fe308582 INTEGER;
  p_Precision_fe308582 INTEGER;
  p_Scale_fe308582 INTEGER;
  p_AllowsNull_fe308582 BOOLEAN;
  p_DefaultValue_fe308582 VARCHAR(255);
  p_IsPrimaryKey_fe308582 BOOLEAN;
  p_IsUniqueKey_fe308582 BOOLEAN;
  p_IsReadOnly_fe308582 BOOLEAN;
  p_IsRequired_fe308582 BOOLEAN;
  p_RelatedIntegrationObjectID_fe308582 UUID;
  p_RelatedIntegrationObjectFieldName_fe308582 VARCHAR(255);
  p_Sequence_fe308582 INTEGER;
  p_Configuration_fe308582 TEXT;
  p_Status_fe308582 VARCHAR(25);
  p_IsCustom_fe308582 BOOLEAN;
  p_MetadataSource_fe308582 VARCHAR(20);
BEGIN
  p_ID_fe308582 := '4E7FC58C-6A5E-5F28-B822-EE0D81BEF665';
  p_IntegrationObjectID_fe308582 := 'C4A09B88-C6CC-54DF-8D50-0782A34D0907';
  p_Name_fe308582 := 'orcid-id';
  p_DisplayName_fe308582 := 'Orcid Id';
  p_Description_fe308582 := 'The ORCID iD of the researcher this item belongs to. Foreign key to the record object.';
  p_Type_fe308582 := 'String';
  p_Length_fe308582 := 19;
  p_AllowsNull_fe308582 := TRUE;
  p_IsPrimaryKey_fe308582 := FALSE;
  p_IsUniqueKey_fe308582 := FALSE;
  p_IsReadOnly_fe308582 := TRUE;
  p_IsRequired_fe308582 := TRUE;
  p_RelatedIntegrationObjectID_fe308582 := '73AED6B8-468D-403B-B994-F3C786C98BC0';
  p_RelatedIntegrationObjectFieldName_fe308582 := 'orcid-id';
  p_Sequence_fe308582 := 0;
  p_Status_fe308582 := 'Active';
  p_IsCustom_fe308582 := FALSE;
  p_MetadataSource_fe308582 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_fe308582, p_IntegrationObjectID := p_IntegrationObjectID_fe308582, p_Name := p_Name_fe308582, p_DisplayName := p_DisplayName_fe308582, p_Description := p_Description_fe308582, p_Category := p_Category_fe308582, p_Category_Clear := TRUE, p_Type := p_Type_fe308582, p_Length := p_Length_fe308582, p_Precision := p_Precision_fe308582, p_Precision_Clear := TRUE, p_Scale := p_Scale_fe308582, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_fe308582, p_DefaultValue := p_DefaultValue_fe308582, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_fe308582, p_IsUniqueKey := p_IsUniqueKey_fe308582, p_IsReadOnly := p_IsReadOnly_fe308582, p_IsRequired := p_IsRequired_fe308582, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_fe308582, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_fe308582, p_Sequence := p_Sequence_fe308582, p_Configuration := p_Configuration_fe308582, p_Configuration_Clear := TRUE, p_Status := p_Status_fe308582, p_IsCustom := p_IsCustom_fe308582, p_MetadataSource := p_MetadataSource_fe308582);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_1fcfda48 UUID;
  p_IntegrationObjectID_1fcfda48 UUID;
  p_Name_1fcfda48 VARCHAR(255);
  p_DisplayName_1fcfda48 VARCHAR(255);
  p_Description_1fcfda48 TEXT;
  p_Category_1fcfda48 VARCHAR(100);
  p_Type_1fcfda48 VARCHAR(100);
  p_Length_1fcfda48 INTEGER;
  p_Precision_1fcfda48 INTEGER;
  p_Scale_1fcfda48 INTEGER;
  p_AllowsNull_1fcfda48 BOOLEAN;
  p_DefaultValue_1fcfda48 VARCHAR(255);
  p_IsPrimaryKey_1fcfda48 BOOLEAN;
  p_IsUniqueKey_1fcfda48 BOOLEAN;
  p_IsReadOnly_1fcfda48 BOOLEAN;
  p_IsRequired_1fcfda48 BOOLEAN;
  p_RelatedIntegrationObjectID_1fcfda48 UUID;
  p_RelatedIntegrationObjectFieldName_1fcfda48 VARCHAR(255);
  p_Sequence_1fcfda48 INTEGER;
  p_Configuration_1fcfda48 TEXT;
  p_Status_1fcfda48 VARCHAR(25);
  p_IsCustom_1fcfda48 BOOLEAN;
  p_MetadataSource_1fcfda48 VARCHAR(20);
BEGIN
  p_ID_1fcfda48 := '15913FB5-E557-5209-B0D6-83D8036CC4A6';
  p_IntegrationObjectID_1fcfda48 := 'C4A09B88-C6CC-54DF-8D50-0782A34D0907';
  p_Name_1fcfda48 := 'put-code';
  p_DisplayName_1fcfda48 := 'Put Code';
  p_Description_1fcfda48 := 'ORCID''s stable identifier for this item within the record. Primary key.';
  p_Type_1fcfda48 := 'Integer';
  p_AllowsNull_1fcfda48 := FALSE;
  p_IsPrimaryKey_1fcfda48 := TRUE;
  p_IsUniqueKey_1fcfda48 := TRUE;
  p_IsReadOnly_1fcfda48 := TRUE;
  p_IsRequired_1fcfda48 := TRUE;
  p_Sequence_1fcfda48 := 1;
  p_Status_1fcfda48 := 'Active';
  p_IsCustom_1fcfda48 := FALSE;
  p_MetadataSource_1fcfda48 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_1fcfda48, p_IntegrationObjectID := p_IntegrationObjectID_1fcfda48, p_Name := p_Name_1fcfda48, p_DisplayName := p_DisplayName_1fcfda48, p_Description := p_Description_1fcfda48, p_Category := p_Category_1fcfda48, p_Category_Clear := TRUE, p_Type := p_Type_1fcfda48, p_Length := p_Length_1fcfda48, p_Length_Clear := TRUE, p_Precision := p_Precision_1fcfda48, p_Precision_Clear := TRUE, p_Scale := p_Scale_1fcfda48, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_1fcfda48, p_DefaultValue := p_DefaultValue_1fcfda48, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_1fcfda48, p_IsUniqueKey := p_IsUniqueKey_1fcfda48, p_IsReadOnly := p_IsReadOnly_1fcfda48, p_IsRequired := p_IsRequired_1fcfda48, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_1fcfda48, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_1fcfda48, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_1fcfda48, p_Configuration := p_Configuration_1fcfda48, p_Configuration_Clear := TRUE, p_Status := p_Status_1fcfda48, p_IsCustom := p_IsCustom_1fcfda48, p_MetadataSource := p_MetadataSource_1fcfda48);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_5568603d UUID;
  p_IntegrationObjectID_5568603d UUID;
  p_Name_5568603d VARCHAR(255);
  p_DisplayName_5568603d VARCHAR(255);
  p_Description_5568603d TEXT;
  p_Category_5568603d VARCHAR(100);
  p_Type_5568603d VARCHAR(100);
  p_Length_5568603d INTEGER;
  p_Precision_5568603d INTEGER;
  p_Scale_5568603d INTEGER;
  p_AllowsNull_5568603d BOOLEAN;
  p_DefaultValue_5568603d VARCHAR(255);
  p_IsPrimaryKey_5568603d BOOLEAN;
  p_IsUniqueKey_5568603d BOOLEAN;
  p_IsReadOnly_5568603d BOOLEAN;
  p_IsRequired_5568603d BOOLEAN;
  p_RelatedIntegrationObjectID_5568603d UUID;
  p_RelatedIntegrationObjectFieldName_5568603d VARCHAR(255);
  p_Sequence_5568603d INTEGER;
  p_Configuration_5568603d TEXT;
  p_Status_5568603d VARCHAR(25);
  p_IsCustom_5568603d BOOLEAN;
  p_MetadataSource_5568603d VARCHAR(20);
BEGIN
  p_ID_5568603d := 'D5952296-3903-52E0-BC44-260A412D5A43';
  p_IntegrationObjectID_5568603d := 'C4A09B88-C6CC-54DF-8D50-0782A34D0907';
  p_Name_5568603d := 'path';
  p_DisplayName_5568603d := 'Path';
  p_Description_5568603d := 'Element path /{orcid}/{section}/{put-code}.';
  p_Type_5568603d := 'String';
  p_Length_5568603d := 500;
  p_AllowsNull_5568603d := TRUE;
  p_IsPrimaryKey_5568603d := FALSE;
  p_IsUniqueKey_5568603d := FALSE;
  p_IsReadOnly_5568603d := TRUE;
  p_IsRequired_5568603d := FALSE;
  p_Sequence_5568603d := 2;
  p_Status_5568603d := 'Active';
  p_IsCustom_5568603d := FALSE;
  p_MetadataSource_5568603d := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_5568603d, p_IntegrationObjectID := p_IntegrationObjectID_5568603d, p_Name := p_Name_5568603d, p_DisplayName := p_DisplayName_5568603d, p_Description := p_Description_5568603d, p_Category := p_Category_5568603d, p_Category_Clear := TRUE, p_Type := p_Type_5568603d, p_Length := p_Length_5568603d, p_Precision := p_Precision_5568603d, p_Precision_Clear := TRUE, p_Scale := p_Scale_5568603d, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_5568603d, p_DefaultValue := p_DefaultValue_5568603d, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_5568603d, p_IsUniqueKey := p_IsUniqueKey_5568603d, p_IsReadOnly := p_IsReadOnly_5568603d, p_IsRequired := p_IsRequired_5568603d, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_5568603d, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_5568603d, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_5568603d, p_Configuration := p_Configuration_5568603d, p_Configuration_Clear := TRUE, p_Status := p_Status_5568603d, p_IsCustom := p_IsCustom_5568603d, p_MetadataSource := p_MetadataSource_5568603d);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_e1ca2aa5 UUID;
  p_IntegrationObjectID_e1ca2aa5 UUID;
  p_Name_e1ca2aa5 VARCHAR(255);
  p_DisplayName_e1ca2aa5 VARCHAR(255);
  p_Description_e1ca2aa5 TEXT;
  p_Category_e1ca2aa5 VARCHAR(100);
  p_Type_e1ca2aa5 VARCHAR(100);
  p_Length_e1ca2aa5 INTEGER;
  p_Precision_e1ca2aa5 INTEGER;
  p_Scale_e1ca2aa5 INTEGER;
  p_AllowsNull_e1ca2aa5 BOOLEAN;
  p_DefaultValue_e1ca2aa5 VARCHAR(255);
  p_IsPrimaryKey_e1ca2aa5 BOOLEAN;
  p_IsUniqueKey_e1ca2aa5 BOOLEAN;
  p_IsReadOnly_e1ca2aa5 BOOLEAN;
  p_IsRequired_e1ca2aa5 BOOLEAN;
  p_RelatedIntegrationObjectID_e1ca2aa5 UUID;
  p_RelatedIntegrationObjectFieldName_e1ca2aa5 VARCHAR(255);
  p_Sequence_e1ca2aa5 INTEGER;
  p_Configuration_e1ca2aa5 TEXT;
  p_Status_e1ca2aa5 VARCHAR(25);
  p_IsCustom_e1ca2aa5 BOOLEAN;
  p_MetadataSource_e1ca2aa5 VARCHAR(20);
BEGIN
  p_ID_e1ca2aa5 := '63528B19-C942-5145-82AD-329C5504064A';
  p_IntegrationObjectID_e1ca2aa5 := 'C4A09B88-C6CC-54DF-8D50-0782A34D0907';
  p_Name_e1ca2aa5 := 'visibility';
  p_DisplayName_e1ca2aa5 := 'Visibility';
  p_Description_e1ca2aa5 := 'ORCID visibility of the item (public, limited, private). The Public API only serves public.';
  p_Type_e1ca2aa5 := 'String';
  p_AllowsNull_e1ca2aa5 := TRUE;
  p_IsPrimaryKey_e1ca2aa5 := FALSE;
  p_IsUniqueKey_e1ca2aa5 := FALSE;
  p_IsReadOnly_e1ca2aa5 := TRUE;
  p_IsRequired_e1ca2aa5 := FALSE;
  p_Sequence_e1ca2aa5 := 3;
  p_Status_e1ca2aa5 := 'Active';
  p_IsCustom_e1ca2aa5 := FALSE;
  p_MetadataSource_e1ca2aa5 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_e1ca2aa5, p_IntegrationObjectID := p_IntegrationObjectID_e1ca2aa5, p_Name := p_Name_e1ca2aa5, p_DisplayName := p_DisplayName_e1ca2aa5, p_Description := p_Description_e1ca2aa5, p_Category := p_Category_e1ca2aa5, p_Category_Clear := TRUE, p_Type := p_Type_e1ca2aa5, p_Length := p_Length_e1ca2aa5, p_Length_Clear := TRUE, p_Precision := p_Precision_e1ca2aa5, p_Precision_Clear := TRUE, p_Scale := p_Scale_e1ca2aa5, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_e1ca2aa5, p_DefaultValue := p_DefaultValue_e1ca2aa5, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_e1ca2aa5, p_IsUniqueKey := p_IsUniqueKey_e1ca2aa5, p_IsReadOnly := p_IsReadOnly_e1ca2aa5, p_IsRequired := p_IsRequired_e1ca2aa5, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_e1ca2aa5, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_e1ca2aa5, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_e1ca2aa5, p_Configuration := p_Configuration_e1ca2aa5, p_Configuration_Clear := TRUE, p_Status := p_Status_e1ca2aa5, p_IsCustom := p_IsCustom_e1ca2aa5, p_MetadataSource := p_MetadataSource_e1ca2aa5);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_a6f44a39 UUID;
  p_IntegrationObjectID_a6f44a39 UUID;
  p_Name_a6f44a39 VARCHAR(255);
  p_DisplayName_a6f44a39 VARCHAR(255);
  p_Description_a6f44a39 TEXT;
  p_Category_a6f44a39 VARCHAR(100);
  p_Type_a6f44a39 VARCHAR(100);
  p_Length_a6f44a39 INTEGER;
  p_Precision_a6f44a39 INTEGER;
  p_Scale_a6f44a39 INTEGER;
  p_AllowsNull_a6f44a39 BOOLEAN;
  p_DefaultValue_a6f44a39 VARCHAR(255);
  p_IsPrimaryKey_a6f44a39 BOOLEAN;
  p_IsUniqueKey_a6f44a39 BOOLEAN;
  p_IsReadOnly_a6f44a39 BOOLEAN;
  p_IsRequired_a6f44a39 BOOLEAN;
  p_RelatedIntegrationObjectID_a6f44a39 UUID;
  p_RelatedIntegrationObjectFieldName_a6f44a39 VARCHAR(255);
  p_Sequence_a6f44a39 INTEGER;
  p_Configuration_a6f44a39 TEXT;
  p_Status_a6f44a39 VARCHAR(25);
  p_IsCustom_a6f44a39 BOOLEAN;
  p_MetadataSource_a6f44a39 VARCHAR(20);
BEGIN
  p_ID_a6f44a39 := '240636A2-ED77-5127-B734-3F1CF44A4EF2';
  p_IntegrationObjectID_a6f44a39 := 'C4A09B88-C6CC-54DF-8D50-0782A34D0907';
  p_Name_a6f44a39 := 'display-index';
  p_DisplayName_a6f44a39 := 'Display Index';
  p_Description_a6f44a39 := 'Display order the researcher chose for the item.';
  p_Type_a6f44a39 := 'String';
  p_AllowsNull_a6f44a39 := TRUE;
  p_IsPrimaryKey_a6f44a39 := FALSE;
  p_IsUniqueKey_a6f44a39 := FALSE;
  p_IsReadOnly_a6f44a39 := TRUE;
  p_IsRequired_a6f44a39 := FALSE;
  p_Sequence_a6f44a39 := 4;
  p_Status_a6f44a39 := 'Active';
  p_IsCustom_a6f44a39 := FALSE;
  p_MetadataSource_a6f44a39 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_a6f44a39, p_IntegrationObjectID := p_IntegrationObjectID_a6f44a39, p_Name := p_Name_a6f44a39, p_DisplayName := p_DisplayName_a6f44a39, p_Description := p_Description_a6f44a39, p_Category := p_Category_a6f44a39, p_Category_Clear := TRUE, p_Type := p_Type_a6f44a39, p_Length := p_Length_a6f44a39, p_Length_Clear := TRUE, p_Precision := p_Precision_a6f44a39, p_Precision_Clear := TRUE, p_Scale := p_Scale_a6f44a39, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_a6f44a39, p_DefaultValue := p_DefaultValue_a6f44a39, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_a6f44a39, p_IsUniqueKey := p_IsUniqueKey_a6f44a39, p_IsReadOnly := p_IsReadOnly_a6f44a39, p_IsRequired := p_IsRequired_a6f44a39, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_a6f44a39, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_a6f44a39, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_a6f44a39, p_Configuration := p_Configuration_a6f44a39, p_Configuration_Clear := TRUE, p_Status := p_Status_a6f44a39, p_IsCustom := p_IsCustom_a6f44a39, p_MetadataSource := p_MetadataSource_a6f44a39);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_c30a557c UUID;
  p_IntegrationObjectID_c30a557c UUID;
  p_Name_c30a557c VARCHAR(255);
  p_DisplayName_c30a557c VARCHAR(255);
  p_Description_c30a557c TEXT;
  p_Category_c30a557c VARCHAR(100);
  p_Type_c30a557c VARCHAR(100);
  p_Length_c30a557c INTEGER;
  p_Precision_c30a557c INTEGER;
  p_Scale_c30a557c INTEGER;
  p_AllowsNull_c30a557c BOOLEAN;
  p_DefaultValue_c30a557c VARCHAR(255);
  p_IsPrimaryKey_c30a557c BOOLEAN;
  p_IsUniqueKey_c30a557c BOOLEAN;
  p_IsReadOnly_c30a557c BOOLEAN;
  p_IsRequired_c30a557c BOOLEAN;
  p_RelatedIntegrationObjectID_c30a557c UUID;
  p_RelatedIntegrationObjectFieldName_c30a557c VARCHAR(255);
  p_Sequence_c30a557c INTEGER;
  p_Configuration_c30a557c TEXT;
  p_Status_c30a557c VARCHAR(25);
  p_IsCustom_c30a557c BOOLEAN;
  p_MetadataSource_c30a557c VARCHAR(20);
BEGIN
  p_ID_c30a557c := '82C2A76F-C3A2-545E-92EA-C24978DF267B';
  p_IntegrationObjectID_c30a557c := 'C4A09B88-C6CC-54DF-8D50-0782A34D0907';
  p_Name_c30a557c := 'created-date';
  p_DisplayName_c30a557c := 'Created Date';
  p_Description_c30a557c := 'When ORCID created the item.';
  p_Type_c30a557c := 'DateTime';
  p_AllowsNull_c30a557c := TRUE;
  p_IsPrimaryKey_c30a557c := FALSE;
  p_IsUniqueKey_c30a557c := FALSE;
  p_IsReadOnly_c30a557c := TRUE;
  p_IsRequired_c30a557c := FALSE;
  p_Sequence_c30a557c := 5;
  p_Status_c30a557c := 'Active';
  p_IsCustom_c30a557c := FALSE;
  p_MetadataSource_c30a557c := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_c30a557c, p_IntegrationObjectID := p_IntegrationObjectID_c30a557c, p_Name := p_Name_c30a557c, p_DisplayName := p_DisplayName_c30a557c, p_Description := p_Description_c30a557c, p_Category := p_Category_c30a557c, p_Category_Clear := TRUE, p_Type := p_Type_c30a557c, p_Length := p_Length_c30a557c, p_Length_Clear := TRUE, p_Precision := p_Precision_c30a557c, p_Precision_Clear := TRUE, p_Scale := p_Scale_c30a557c, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_c30a557c, p_DefaultValue := p_DefaultValue_c30a557c, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_c30a557c, p_IsUniqueKey := p_IsUniqueKey_c30a557c, p_IsReadOnly := p_IsReadOnly_c30a557c, p_IsRequired := p_IsRequired_c30a557c, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_c30a557c, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_c30a557c, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_c30a557c, p_Configuration := p_Configuration_c30a557c, p_Configuration_Clear := TRUE, p_Status := p_Status_c30a557c, p_IsCustom := p_IsCustom_c30a557c, p_MetadataSource := p_MetadataSource_c30a557c);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_65fec8f8 UUID;
  p_IntegrationObjectID_65fec8f8 UUID;
  p_Name_65fec8f8 VARCHAR(255);
  p_DisplayName_65fec8f8 VARCHAR(255);
  p_Description_65fec8f8 TEXT;
  p_Category_65fec8f8 VARCHAR(100);
  p_Type_65fec8f8 VARCHAR(100);
  p_Length_65fec8f8 INTEGER;
  p_Precision_65fec8f8 INTEGER;
  p_Scale_65fec8f8 INTEGER;
  p_AllowsNull_65fec8f8 BOOLEAN;
  p_DefaultValue_65fec8f8 VARCHAR(255);
  p_IsPrimaryKey_65fec8f8 BOOLEAN;
  p_IsUniqueKey_65fec8f8 BOOLEAN;
  p_IsReadOnly_65fec8f8 BOOLEAN;
  p_IsRequired_65fec8f8 BOOLEAN;
  p_RelatedIntegrationObjectID_65fec8f8 UUID;
  p_RelatedIntegrationObjectFieldName_65fec8f8 VARCHAR(255);
  p_Sequence_65fec8f8 INTEGER;
  p_Configuration_65fec8f8 TEXT;
  p_Status_65fec8f8 VARCHAR(25);
  p_IsCustom_65fec8f8 BOOLEAN;
  p_MetadataSource_65fec8f8 VARCHAR(20);
BEGIN
  p_ID_65fec8f8 := 'C4B30432-522F-5927-ACA5-3C3D709BE166';
  p_IntegrationObjectID_65fec8f8 := 'C4A09B88-C6CC-54DF-8D50-0782A34D0907';
  p_Name_65fec8f8 := 'last-modified-date';
  p_DisplayName_65fec8f8 := 'Last Modified Date';
  p_Description_65fec8f8 := 'When ORCID last changed the item. Incremental watermark.';
  p_Type_65fec8f8 := 'DateTime';
  p_AllowsNull_65fec8f8 := TRUE;
  p_IsPrimaryKey_65fec8f8 := FALSE;
  p_IsUniqueKey_65fec8f8 := FALSE;
  p_IsReadOnly_65fec8f8 := TRUE;
  p_IsRequired_65fec8f8 := FALSE;
  p_Sequence_65fec8f8 := 6;
  p_Status_65fec8f8 := 'Active';
  p_IsCustom_65fec8f8 := FALSE;
  p_MetadataSource_65fec8f8 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_65fec8f8, p_IntegrationObjectID := p_IntegrationObjectID_65fec8f8, p_Name := p_Name_65fec8f8, p_DisplayName := p_DisplayName_65fec8f8, p_Description := p_Description_65fec8f8, p_Category := p_Category_65fec8f8, p_Category_Clear := TRUE, p_Type := p_Type_65fec8f8, p_Length := p_Length_65fec8f8, p_Length_Clear := TRUE, p_Precision := p_Precision_65fec8f8, p_Precision_Clear := TRUE, p_Scale := p_Scale_65fec8f8, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_65fec8f8, p_DefaultValue := p_DefaultValue_65fec8f8, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_65fec8f8, p_IsUniqueKey := p_IsUniqueKey_65fec8f8, p_IsReadOnly := p_IsReadOnly_65fec8f8, p_IsRequired := p_IsRequired_65fec8f8, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_65fec8f8, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_65fec8f8, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_65fec8f8, p_Configuration := p_Configuration_65fec8f8, p_Configuration_Clear := TRUE, p_Status := p_Status_65fec8f8, p_IsCustom := p_IsCustom_65fec8f8, p_MetadataSource := p_MetadataSource_65fec8f8);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_f8e09f2d UUID;
  p_IntegrationObjectID_f8e09f2d UUID;
  p_Name_f8e09f2d VARCHAR(255);
  p_DisplayName_f8e09f2d VARCHAR(255);
  p_Description_f8e09f2d TEXT;
  p_Category_f8e09f2d VARCHAR(100);
  p_Type_f8e09f2d VARCHAR(100);
  p_Length_f8e09f2d INTEGER;
  p_Precision_f8e09f2d INTEGER;
  p_Scale_f8e09f2d INTEGER;
  p_AllowsNull_f8e09f2d BOOLEAN;
  p_DefaultValue_f8e09f2d VARCHAR(255);
  p_IsPrimaryKey_f8e09f2d BOOLEAN;
  p_IsUniqueKey_f8e09f2d BOOLEAN;
  p_IsReadOnly_f8e09f2d BOOLEAN;
  p_IsRequired_f8e09f2d BOOLEAN;
  p_RelatedIntegrationObjectID_f8e09f2d UUID;
  p_RelatedIntegrationObjectFieldName_f8e09f2d VARCHAR(255);
  p_Sequence_f8e09f2d INTEGER;
  p_Configuration_f8e09f2d TEXT;
  p_Status_f8e09f2d VARCHAR(25);
  p_IsCustom_f8e09f2d BOOLEAN;
  p_MetadataSource_f8e09f2d VARCHAR(20);
BEGIN
  p_ID_f8e09f2d := 'F9480FE9-ED74-5481-91B8-BD209C65ACFF';
  p_IntegrationObjectID_f8e09f2d := 'C4A09B88-C6CC-54DF-8D50-0782A34D0907';
  p_Name_f8e09f2d := 'source';
  p_DisplayName_f8e09f2d := 'Source';
  p_Description_f8e09f2d := 'Full source block: who asserted the item.';
  p_Type_f8e09f2d := 'json';
  p_AllowsNull_f8e09f2d := TRUE;
  p_IsPrimaryKey_f8e09f2d := FALSE;
  p_IsUniqueKey_f8e09f2d := FALSE;
  p_IsReadOnly_f8e09f2d := TRUE;
  p_IsRequired_f8e09f2d := FALSE;
  p_Sequence_f8e09f2d := 7;
  p_Status_f8e09f2d := 'Active';
  p_IsCustom_f8e09f2d := FALSE;
  p_MetadataSource_f8e09f2d := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_f8e09f2d, p_IntegrationObjectID := p_IntegrationObjectID_f8e09f2d, p_Name := p_Name_f8e09f2d, p_DisplayName := p_DisplayName_f8e09f2d, p_Description := p_Description_f8e09f2d, p_Category := p_Category_f8e09f2d, p_Category_Clear := TRUE, p_Type := p_Type_f8e09f2d, p_Length := p_Length_f8e09f2d, p_Length_Clear := TRUE, p_Precision := p_Precision_f8e09f2d, p_Precision_Clear := TRUE, p_Scale := p_Scale_f8e09f2d, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_f8e09f2d, p_DefaultValue := p_DefaultValue_f8e09f2d, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_f8e09f2d, p_IsUniqueKey := p_IsUniqueKey_f8e09f2d, p_IsReadOnly := p_IsReadOnly_f8e09f2d, p_IsRequired := p_IsRequired_f8e09f2d, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_f8e09f2d, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_f8e09f2d, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_f8e09f2d, p_Configuration := p_Configuration_f8e09f2d, p_Configuration_Clear := TRUE, p_Status := p_Status_f8e09f2d, p_IsCustom := p_IsCustom_f8e09f2d, p_MetadataSource := p_MetadataSource_f8e09f2d);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_e3c8f91f UUID;
  p_IntegrationObjectID_e3c8f91f UUID;
  p_Name_e3c8f91f VARCHAR(255);
  p_DisplayName_e3c8f91f VARCHAR(255);
  p_Description_e3c8f91f TEXT;
  p_Category_e3c8f91f VARCHAR(100);
  p_Type_e3c8f91f VARCHAR(100);
  p_Length_e3c8f91f INTEGER;
  p_Precision_e3c8f91f INTEGER;
  p_Scale_e3c8f91f INTEGER;
  p_AllowsNull_e3c8f91f BOOLEAN;
  p_DefaultValue_e3c8f91f VARCHAR(255);
  p_IsPrimaryKey_e3c8f91f BOOLEAN;
  p_IsUniqueKey_e3c8f91f BOOLEAN;
  p_IsReadOnly_e3c8f91f BOOLEAN;
  p_IsRequired_e3c8f91f BOOLEAN;
  p_RelatedIntegrationObjectID_e3c8f91f UUID;
  p_RelatedIntegrationObjectFieldName_e3c8f91f VARCHAR(255);
  p_Sequence_e3c8f91f INTEGER;
  p_Configuration_e3c8f91f TEXT;
  p_Status_e3c8f91f VARCHAR(25);
  p_IsCustom_e3c8f91f BOOLEAN;
  p_MetadataSource_e3c8f91f VARCHAR(20);
BEGIN
  p_ID_e3c8f91f := '6750F3AC-228F-55E6-A936-C2EDD1995B5D';
  p_IntegrationObjectID_e3c8f91f := 'C4A09B88-C6CC-54DF-8D50-0782A34D0907';
  p_Name_e3c8f91f := 'source-name';
  p_DisplayName_e3c8f91f := 'Source Name';
  p_Description_e3c8f91f := 'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.';
  p_Type_e3c8f91f := 'String';
  p_Length_e3c8f91f := 500;
  p_AllowsNull_e3c8f91f := TRUE;
  p_IsPrimaryKey_e3c8f91f := FALSE;
  p_IsUniqueKey_e3c8f91f := FALSE;
  p_IsReadOnly_e3c8f91f := TRUE;
  p_IsRequired_e3c8f91f := FALSE;
  p_Sequence_e3c8f91f := 8;
  p_Status_e3c8f91f := 'Active';
  p_IsCustom_e3c8f91f := FALSE;
  p_MetadataSource_e3c8f91f := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_e3c8f91f, p_IntegrationObjectID := p_IntegrationObjectID_e3c8f91f, p_Name := p_Name_e3c8f91f, p_DisplayName := p_DisplayName_e3c8f91f, p_Description := p_Description_e3c8f91f, p_Category := p_Category_e3c8f91f, p_Category_Clear := TRUE, p_Type := p_Type_e3c8f91f, p_Length := p_Length_e3c8f91f, p_Precision := p_Precision_e3c8f91f, p_Precision_Clear := TRUE, p_Scale := p_Scale_e3c8f91f, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_e3c8f91f, p_DefaultValue := p_DefaultValue_e3c8f91f, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_e3c8f91f, p_IsUniqueKey := p_IsUniqueKey_e3c8f91f, p_IsReadOnly := p_IsReadOnly_e3c8f91f, p_IsRequired := p_IsRequired_e3c8f91f, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_e3c8f91f, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_e3c8f91f, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_e3c8f91f, p_Configuration := p_Configuration_e3c8f91f, p_Configuration_Clear := TRUE, p_Status := p_Status_e3c8f91f, p_IsCustom := p_IsCustom_e3c8f91f, p_MetadataSource := p_MetadataSource_e3c8f91f);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_2a374d61 UUID;
  p_IntegrationObjectID_2a374d61 UUID;
  p_Name_2a374d61 VARCHAR(255);
  p_DisplayName_2a374d61 VARCHAR(255);
  p_Description_2a374d61 TEXT;
  p_Category_2a374d61 VARCHAR(100);
  p_Type_2a374d61 VARCHAR(100);
  p_Length_2a374d61 INTEGER;
  p_Precision_2a374d61 INTEGER;
  p_Scale_2a374d61 INTEGER;
  p_AllowsNull_2a374d61 BOOLEAN;
  p_DefaultValue_2a374d61 VARCHAR(255);
  p_IsPrimaryKey_2a374d61 BOOLEAN;
  p_IsUniqueKey_2a374d61 BOOLEAN;
  p_IsReadOnly_2a374d61 BOOLEAN;
  p_IsRequired_2a374d61 BOOLEAN;
  p_RelatedIntegrationObjectID_2a374d61 UUID;
  p_RelatedIntegrationObjectFieldName_2a374d61 VARCHAR(255);
  p_Sequence_2a374d61 INTEGER;
  p_Configuration_2a374d61 TEXT;
  p_Status_2a374d61 VARCHAR(25);
  p_IsCustom_2a374d61 BOOLEAN;
  p_MetadataSource_2a374d61 VARCHAR(20);
BEGIN
  p_ID_2a374d61 := '1638BE8C-91A4-5C4C-98C2-64388509C0A9';
  p_IntegrationObjectID_2a374d61 := 'C4A09B88-C6CC-54DF-8D50-0782A34D0907';
  p_Name_2a374d61 := 'source-orcid';
  p_DisplayName_2a374d61 := 'Source Orcid';
  p_Description_2a374d61 := 'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.';
  p_Type_2a374d61 := 'String';
  p_Length_2a374d61 := 19;
  p_AllowsNull_2a374d61 := TRUE;
  p_IsPrimaryKey_2a374d61 := FALSE;
  p_IsUniqueKey_2a374d61 := FALSE;
  p_IsReadOnly_2a374d61 := TRUE;
  p_IsRequired_2a374d61 := FALSE;
  p_Sequence_2a374d61 := 9;
  p_Status_2a374d61 := 'Active';
  p_IsCustom_2a374d61 := FALSE;
  p_MetadataSource_2a374d61 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_2a374d61, p_IntegrationObjectID := p_IntegrationObjectID_2a374d61, p_Name := p_Name_2a374d61, p_DisplayName := p_DisplayName_2a374d61, p_Description := p_Description_2a374d61, p_Category := p_Category_2a374d61, p_Category_Clear := TRUE, p_Type := p_Type_2a374d61, p_Length := p_Length_2a374d61, p_Precision := p_Precision_2a374d61, p_Precision_Clear := TRUE, p_Scale := p_Scale_2a374d61, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_2a374d61, p_DefaultValue := p_DefaultValue_2a374d61, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_2a374d61, p_IsUniqueKey := p_IsUniqueKey_2a374d61, p_IsReadOnly := p_IsReadOnly_2a374d61, p_IsRequired := p_IsRequired_2a374d61, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_2a374d61, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_2a374d61, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_2a374d61, p_Configuration := p_Configuration_2a374d61, p_Configuration_Clear := TRUE, p_Status := p_Status_2a374d61, p_IsCustom := p_IsCustom_2a374d61, p_MetadataSource := p_MetadataSource_2a374d61);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_59f302cf UUID;
  p_IntegrationObjectID_59f302cf UUID;
  p_Name_59f302cf VARCHAR(255);
  p_DisplayName_59f302cf VARCHAR(255);
  p_Description_59f302cf TEXT;
  p_Category_59f302cf VARCHAR(100);
  p_Type_59f302cf VARCHAR(100);
  p_Length_59f302cf INTEGER;
  p_Precision_59f302cf INTEGER;
  p_Scale_59f302cf INTEGER;
  p_AllowsNull_59f302cf BOOLEAN;
  p_DefaultValue_59f302cf VARCHAR(255);
  p_IsPrimaryKey_59f302cf BOOLEAN;
  p_IsUniqueKey_59f302cf BOOLEAN;
  p_IsReadOnly_59f302cf BOOLEAN;
  p_IsRequired_59f302cf BOOLEAN;
  p_RelatedIntegrationObjectID_59f302cf UUID;
  p_RelatedIntegrationObjectFieldName_59f302cf VARCHAR(255);
  p_Sequence_59f302cf INTEGER;
  p_Configuration_59f302cf TEXT;
  p_Status_59f302cf VARCHAR(25);
  p_IsCustom_59f302cf BOOLEAN;
  p_MetadataSource_59f302cf VARCHAR(20);
BEGIN
  p_ID_59f302cf := '37B280EC-2E2C-5B5E-956E-5BBD0F3D6939';
  p_IntegrationObjectID_59f302cf := 'C4A09B88-C6CC-54DF-8D50-0782A34D0907';
  p_Name_59f302cf := 'country';
  p_DisplayName_59f302cf := 'Country';
  p_Description_59f302cf := 'ISO country code.';
  p_Type_59f302cf := 'String';
  p_Length_59f302cf := 50;
  p_AllowsNull_59f302cf := TRUE;
  p_IsPrimaryKey_59f302cf := FALSE;
  p_IsUniqueKey_59f302cf := FALSE;
  p_IsReadOnly_59f302cf := TRUE;
  p_IsRequired_59f302cf := FALSE;
  p_Sequence_59f302cf := 10;
  p_Status_59f302cf := 'Active';
  p_IsCustom_59f302cf := FALSE;
  p_MetadataSource_59f302cf := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_59f302cf, p_IntegrationObjectID := p_IntegrationObjectID_59f302cf, p_Name := p_Name_59f302cf, p_DisplayName := p_DisplayName_59f302cf, p_Description := p_Description_59f302cf, p_Category := p_Category_59f302cf, p_Category_Clear := TRUE, p_Type := p_Type_59f302cf, p_Length := p_Length_59f302cf, p_Precision := p_Precision_59f302cf, p_Precision_Clear := TRUE, p_Scale := p_Scale_59f302cf, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_59f302cf, p_DefaultValue := p_DefaultValue_59f302cf, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_59f302cf, p_IsUniqueKey := p_IsUniqueKey_59f302cf, p_IsReadOnly := p_IsReadOnly_59f302cf, p_IsRequired := p_IsRequired_59f302cf, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_59f302cf, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_59f302cf, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_59f302cf, p_Configuration := p_Configuration_59f302cf, p_Configuration_Clear := TRUE, p_Status := p_Status_59f302cf, p_IsCustom := p_IsCustom_59f302cf, p_MetadataSource := p_MetadataSource_59f302cf);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_f54ad43a UUID;
  p_IntegrationObjectID_f54ad43a UUID;
  p_Name_f54ad43a VARCHAR(255);
  p_DisplayName_f54ad43a VARCHAR(255);
  p_Description_f54ad43a TEXT;
  p_Category_f54ad43a VARCHAR(100);
  p_Type_f54ad43a VARCHAR(100);
  p_Length_f54ad43a INTEGER;
  p_Precision_f54ad43a INTEGER;
  p_Scale_f54ad43a INTEGER;
  p_AllowsNull_f54ad43a BOOLEAN;
  p_DefaultValue_f54ad43a VARCHAR(255);
  p_IsPrimaryKey_f54ad43a BOOLEAN;
  p_IsUniqueKey_f54ad43a BOOLEAN;
  p_IsReadOnly_f54ad43a BOOLEAN;
  p_IsRequired_f54ad43a BOOLEAN;
  p_RelatedIntegrationObjectID_f54ad43a UUID;
  p_RelatedIntegrationObjectFieldName_f54ad43a VARCHAR(255);
  p_Sequence_f54ad43a INTEGER;
  p_Configuration_f54ad43a TEXT;
  p_Status_f54ad43a VARCHAR(25);
  p_IsCustom_f54ad43a BOOLEAN;
  p_MetadataSource_f54ad43a VARCHAR(20);
BEGIN
  p_ID_f54ad43a := '8C8D7124-AAEC-517F-931B-7854B4B7F3F6';
  p_IntegrationObjectID_f54ad43a := '3F2D9F80-F35B-501D-BC52-66AF079946E5';
  p_Name_f54ad43a := 'orcid-id';
  p_DisplayName_f54ad43a := 'Orcid Id';
  p_Description_f54ad43a := 'The ORCID iD of the researcher this item belongs to. Foreign key to the record object.';
  p_Type_f54ad43a := 'String';
  p_Length_f54ad43a := 19;
  p_AllowsNull_f54ad43a := TRUE;
  p_IsPrimaryKey_f54ad43a := FALSE;
  p_IsUniqueKey_f54ad43a := FALSE;
  p_IsReadOnly_f54ad43a := TRUE;
  p_IsRequired_f54ad43a := TRUE;
  p_RelatedIntegrationObjectID_f54ad43a := '73AED6B8-468D-403B-B994-F3C786C98BC0';
  p_RelatedIntegrationObjectFieldName_f54ad43a := 'orcid-id';
  p_Sequence_f54ad43a := 0;
  p_Status_f54ad43a := 'Active';
  p_IsCustom_f54ad43a := FALSE;
  p_MetadataSource_f54ad43a := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_f54ad43a, p_IntegrationObjectID := p_IntegrationObjectID_f54ad43a, p_Name := p_Name_f54ad43a, p_DisplayName := p_DisplayName_f54ad43a, p_Description := p_Description_f54ad43a, p_Category := p_Category_f54ad43a, p_Category_Clear := TRUE, p_Type := p_Type_f54ad43a, p_Length := p_Length_f54ad43a, p_Precision := p_Precision_f54ad43a, p_Precision_Clear := TRUE, p_Scale := p_Scale_f54ad43a, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_f54ad43a, p_DefaultValue := p_DefaultValue_f54ad43a, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_f54ad43a, p_IsUniqueKey := p_IsUniqueKey_f54ad43a, p_IsReadOnly := p_IsReadOnly_f54ad43a, p_IsRequired := p_IsRequired_f54ad43a, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_f54ad43a, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_f54ad43a, p_Sequence := p_Sequence_f54ad43a, p_Configuration := p_Configuration_f54ad43a, p_Configuration_Clear := TRUE, p_Status := p_Status_f54ad43a, p_IsCustom := p_IsCustom_f54ad43a, p_MetadataSource := p_MetadataSource_f54ad43a);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_58ac27cb UUID;
  p_IntegrationObjectID_58ac27cb UUID;
  p_Name_58ac27cb VARCHAR(255);
  p_DisplayName_58ac27cb VARCHAR(255);
  p_Description_58ac27cb TEXT;
  p_Category_58ac27cb VARCHAR(100);
  p_Type_58ac27cb VARCHAR(100);
  p_Length_58ac27cb INTEGER;
  p_Precision_58ac27cb INTEGER;
  p_Scale_58ac27cb INTEGER;
  p_AllowsNull_58ac27cb BOOLEAN;
  p_DefaultValue_58ac27cb VARCHAR(255);
  p_IsPrimaryKey_58ac27cb BOOLEAN;
  p_IsUniqueKey_58ac27cb BOOLEAN;
  p_IsReadOnly_58ac27cb BOOLEAN;
  p_IsRequired_58ac27cb BOOLEAN;
  p_RelatedIntegrationObjectID_58ac27cb UUID;
  p_RelatedIntegrationObjectFieldName_58ac27cb VARCHAR(255);
  p_Sequence_58ac27cb INTEGER;
  p_Configuration_58ac27cb TEXT;
  p_Status_58ac27cb VARCHAR(25);
  p_IsCustom_58ac27cb BOOLEAN;
  p_MetadataSource_58ac27cb VARCHAR(20);
BEGIN
  p_ID_58ac27cb := 'F61EB884-52A0-5AE5-A8CC-1F5F5106FA77';
  p_IntegrationObjectID_58ac27cb := '3F2D9F80-F35B-501D-BC52-66AF079946E5';
  p_Name_58ac27cb := 'put-code';
  p_DisplayName_58ac27cb := 'Put Code';
  p_Description_58ac27cb := 'ORCID''s stable identifier for this item within the record. Primary key.';
  p_Type_58ac27cb := 'Integer';
  p_AllowsNull_58ac27cb := FALSE;
  p_IsPrimaryKey_58ac27cb := TRUE;
  p_IsUniqueKey_58ac27cb := TRUE;
  p_IsReadOnly_58ac27cb := TRUE;
  p_IsRequired_58ac27cb := TRUE;
  p_Sequence_58ac27cb := 1;
  p_Status_58ac27cb := 'Active';
  p_IsCustom_58ac27cb := FALSE;
  p_MetadataSource_58ac27cb := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_58ac27cb, p_IntegrationObjectID := p_IntegrationObjectID_58ac27cb, p_Name := p_Name_58ac27cb, p_DisplayName := p_DisplayName_58ac27cb, p_Description := p_Description_58ac27cb, p_Category := p_Category_58ac27cb, p_Category_Clear := TRUE, p_Type := p_Type_58ac27cb, p_Length := p_Length_58ac27cb, p_Length_Clear := TRUE, p_Precision := p_Precision_58ac27cb, p_Precision_Clear := TRUE, p_Scale := p_Scale_58ac27cb, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_58ac27cb, p_DefaultValue := p_DefaultValue_58ac27cb, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_58ac27cb, p_IsUniqueKey := p_IsUniqueKey_58ac27cb, p_IsReadOnly := p_IsReadOnly_58ac27cb, p_IsRequired := p_IsRequired_58ac27cb, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_58ac27cb, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_58ac27cb, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_58ac27cb, p_Configuration := p_Configuration_58ac27cb, p_Configuration_Clear := TRUE, p_Status := p_Status_58ac27cb, p_IsCustom := p_IsCustom_58ac27cb, p_MetadataSource := p_MetadataSource_58ac27cb);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_b2218280 UUID;
  p_IntegrationObjectID_b2218280 UUID;
  p_Name_b2218280 VARCHAR(255);
  p_DisplayName_b2218280 VARCHAR(255);
  p_Description_b2218280 TEXT;
  p_Category_b2218280 VARCHAR(100);
  p_Type_b2218280 VARCHAR(100);
  p_Length_b2218280 INTEGER;
  p_Precision_b2218280 INTEGER;
  p_Scale_b2218280 INTEGER;
  p_AllowsNull_b2218280 BOOLEAN;
  p_DefaultValue_b2218280 VARCHAR(255);
  p_IsPrimaryKey_b2218280 BOOLEAN;
  p_IsUniqueKey_b2218280 BOOLEAN;
  p_IsReadOnly_b2218280 BOOLEAN;
  p_IsRequired_b2218280 BOOLEAN;
  p_RelatedIntegrationObjectID_b2218280 UUID;
  p_RelatedIntegrationObjectFieldName_b2218280 VARCHAR(255);
  p_Sequence_b2218280 INTEGER;
  p_Configuration_b2218280 TEXT;
  p_Status_b2218280 VARCHAR(25);
  p_IsCustom_b2218280 BOOLEAN;
  p_MetadataSource_b2218280 VARCHAR(20);
BEGIN
  p_ID_b2218280 := '075259DF-EC48-5A99-AAB2-D3B9C71BC775';
  p_IntegrationObjectID_b2218280 := '3F2D9F80-F35B-501D-BC52-66AF079946E5';
  p_Name_b2218280 := 'path';
  p_DisplayName_b2218280 := 'Path';
  p_Description_b2218280 := 'Element path /{orcid}/{section}/{put-code}.';
  p_Type_b2218280 := 'String';
  p_Length_b2218280 := 500;
  p_AllowsNull_b2218280 := TRUE;
  p_IsPrimaryKey_b2218280 := FALSE;
  p_IsUniqueKey_b2218280 := FALSE;
  p_IsReadOnly_b2218280 := TRUE;
  p_IsRequired_b2218280 := FALSE;
  p_Sequence_b2218280 := 2;
  p_Status_b2218280 := 'Active';
  p_IsCustom_b2218280 := FALSE;
  p_MetadataSource_b2218280 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_b2218280, p_IntegrationObjectID := p_IntegrationObjectID_b2218280, p_Name := p_Name_b2218280, p_DisplayName := p_DisplayName_b2218280, p_Description := p_Description_b2218280, p_Category := p_Category_b2218280, p_Category_Clear := TRUE, p_Type := p_Type_b2218280, p_Length := p_Length_b2218280, p_Precision := p_Precision_b2218280, p_Precision_Clear := TRUE, p_Scale := p_Scale_b2218280, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_b2218280, p_DefaultValue := p_DefaultValue_b2218280, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_b2218280, p_IsUniqueKey := p_IsUniqueKey_b2218280, p_IsReadOnly := p_IsReadOnly_b2218280, p_IsRequired := p_IsRequired_b2218280, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_b2218280, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_b2218280, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_b2218280, p_Configuration := p_Configuration_b2218280, p_Configuration_Clear := TRUE, p_Status := p_Status_b2218280, p_IsCustom := p_IsCustom_b2218280, p_MetadataSource := p_MetadataSource_b2218280);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_854e28f1 UUID;
  p_IntegrationObjectID_854e28f1 UUID;
  p_Name_854e28f1 VARCHAR(255);
  p_DisplayName_854e28f1 VARCHAR(255);
  p_Description_854e28f1 TEXT;
  p_Category_854e28f1 VARCHAR(100);
  p_Type_854e28f1 VARCHAR(100);
  p_Length_854e28f1 INTEGER;
  p_Precision_854e28f1 INTEGER;
  p_Scale_854e28f1 INTEGER;
  p_AllowsNull_854e28f1 BOOLEAN;
  p_DefaultValue_854e28f1 VARCHAR(255);
  p_IsPrimaryKey_854e28f1 BOOLEAN;
  p_IsUniqueKey_854e28f1 BOOLEAN;
  p_IsReadOnly_854e28f1 BOOLEAN;
  p_IsRequired_854e28f1 BOOLEAN;
  p_RelatedIntegrationObjectID_854e28f1 UUID;
  p_RelatedIntegrationObjectFieldName_854e28f1 VARCHAR(255);
  p_Sequence_854e28f1 INTEGER;
  p_Configuration_854e28f1 TEXT;
  p_Status_854e28f1 VARCHAR(25);
  p_IsCustom_854e28f1 BOOLEAN;
  p_MetadataSource_854e28f1 VARCHAR(20);
BEGIN
  p_ID_854e28f1 := '396BE273-F78E-5899-A4FF-EFE7163D6DED';
  p_IntegrationObjectID_854e28f1 := '3F2D9F80-F35B-501D-BC52-66AF079946E5';
  p_Name_854e28f1 := 'visibility';
  p_DisplayName_854e28f1 := 'Visibility';
  p_Description_854e28f1 := 'ORCID visibility of the item (public, limited, private). The Public API only serves public.';
  p_Type_854e28f1 := 'String';
  p_AllowsNull_854e28f1 := TRUE;
  p_IsPrimaryKey_854e28f1 := FALSE;
  p_IsUniqueKey_854e28f1 := FALSE;
  p_IsReadOnly_854e28f1 := TRUE;
  p_IsRequired_854e28f1 := FALSE;
  p_Sequence_854e28f1 := 3;
  p_Status_854e28f1 := 'Active';
  p_IsCustom_854e28f1 := FALSE;
  p_MetadataSource_854e28f1 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_854e28f1, p_IntegrationObjectID := p_IntegrationObjectID_854e28f1, p_Name := p_Name_854e28f1, p_DisplayName := p_DisplayName_854e28f1, p_Description := p_Description_854e28f1, p_Category := p_Category_854e28f1, p_Category_Clear := TRUE, p_Type := p_Type_854e28f1, p_Length := p_Length_854e28f1, p_Length_Clear := TRUE, p_Precision := p_Precision_854e28f1, p_Precision_Clear := TRUE, p_Scale := p_Scale_854e28f1, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_854e28f1, p_DefaultValue := p_DefaultValue_854e28f1, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_854e28f1, p_IsUniqueKey := p_IsUniqueKey_854e28f1, p_IsReadOnly := p_IsReadOnly_854e28f1, p_IsRequired := p_IsRequired_854e28f1, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_854e28f1, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_854e28f1, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_854e28f1, p_Configuration := p_Configuration_854e28f1, p_Configuration_Clear := TRUE, p_Status := p_Status_854e28f1, p_IsCustom := p_IsCustom_854e28f1, p_MetadataSource := p_MetadataSource_854e28f1);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_4d5985f6 UUID;
  p_IntegrationObjectID_4d5985f6 UUID;
  p_Name_4d5985f6 VARCHAR(255);
  p_DisplayName_4d5985f6 VARCHAR(255);
  p_Description_4d5985f6 TEXT;
  p_Category_4d5985f6 VARCHAR(100);
  p_Type_4d5985f6 VARCHAR(100);
  p_Length_4d5985f6 INTEGER;
  p_Precision_4d5985f6 INTEGER;
  p_Scale_4d5985f6 INTEGER;
  p_AllowsNull_4d5985f6 BOOLEAN;
  p_DefaultValue_4d5985f6 VARCHAR(255);
  p_IsPrimaryKey_4d5985f6 BOOLEAN;
  p_IsUniqueKey_4d5985f6 BOOLEAN;
  p_IsReadOnly_4d5985f6 BOOLEAN;
  p_IsRequired_4d5985f6 BOOLEAN;
  p_RelatedIntegrationObjectID_4d5985f6 UUID;
  p_RelatedIntegrationObjectFieldName_4d5985f6 VARCHAR(255);
  p_Sequence_4d5985f6 INTEGER;
  p_Configuration_4d5985f6 TEXT;
  p_Status_4d5985f6 VARCHAR(25);
  p_IsCustom_4d5985f6 BOOLEAN;
  p_MetadataSource_4d5985f6 VARCHAR(20);
BEGIN
  p_ID_4d5985f6 := '4E4CA86C-011D-5C91-8577-5B7AE4A4B1FC';
  p_IntegrationObjectID_4d5985f6 := '3F2D9F80-F35B-501D-BC52-66AF079946E5';
  p_Name_4d5985f6 := 'display-index';
  p_DisplayName_4d5985f6 := 'Display Index';
  p_Description_4d5985f6 := 'Display order the researcher chose for the item.';
  p_Type_4d5985f6 := 'String';
  p_AllowsNull_4d5985f6 := TRUE;
  p_IsPrimaryKey_4d5985f6 := FALSE;
  p_IsUniqueKey_4d5985f6 := FALSE;
  p_IsReadOnly_4d5985f6 := TRUE;
  p_IsRequired_4d5985f6 := FALSE;
  p_Sequence_4d5985f6 := 4;
  p_Status_4d5985f6 := 'Active';
  p_IsCustom_4d5985f6 := FALSE;
  p_MetadataSource_4d5985f6 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_4d5985f6, p_IntegrationObjectID := p_IntegrationObjectID_4d5985f6, p_Name := p_Name_4d5985f6, p_DisplayName := p_DisplayName_4d5985f6, p_Description := p_Description_4d5985f6, p_Category := p_Category_4d5985f6, p_Category_Clear := TRUE, p_Type := p_Type_4d5985f6, p_Length := p_Length_4d5985f6, p_Length_Clear := TRUE, p_Precision := p_Precision_4d5985f6, p_Precision_Clear := TRUE, p_Scale := p_Scale_4d5985f6, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_4d5985f6, p_DefaultValue := p_DefaultValue_4d5985f6, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_4d5985f6, p_IsUniqueKey := p_IsUniqueKey_4d5985f6, p_IsReadOnly := p_IsReadOnly_4d5985f6, p_IsRequired := p_IsRequired_4d5985f6, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_4d5985f6, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_4d5985f6, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_4d5985f6, p_Configuration := p_Configuration_4d5985f6, p_Configuration_Clear := TRUE, p_Status := p_Status_4d5985f6, p_IsCustom := p_IsCustom_4d5985f6, p_MetadataSource := p_MetadataSource_4d5985f6);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_0d14d249 UUID;
  p_IntegrationObjectID_0d14d249 UUID;
  p_Name_0d14d249 VARCHAR(255);
  p_DisplayName_0d14d249 VARCHAR(255);
  p_Description_0d14d249 TEXT;
  p_Category_0d14d249 VARCHAR(100);
  p_Type_0d14d249 VARCHAR(100);
  p_Length_0d14d249 INTEGER;
  p_Precision_0d14d249 INTEGER;
  p_Scale_0d14d249 INTEGER;
  p_AllowsNull_0d14d249 BOOLEAN;
  p_DefaultValue_0d14d249 VARCHAR(255);
  p_IsPrimaryKey_0d14d249 BOOLEAN;
  p_IsUniqueKey_0d14d249 BOOLEAN;
  p_IsReadOnly_0d14d249 BOOLEAN;
  p_IsRequired_0d14d249 BOOLEAN;
  p_RelatedIntegrationObjectID_0d14d249 UUID;
  p_RelatedIntegrationObjectFieldName_0d14d249 VARCHAR(255);
  p_Sequence_0d14d249 INTEGER;
  p_Configuration_0d14d249 TEXT;
  p_Status_0d14d249 VARCHAR(25);
  p_IsCustom_0d14d249 BOOLEAN;
  p_MetadataSource_0d14d249 VARCHAR(20);
BEGIN
  p_ID_0d14d249 := '07BC821A-02B0-5CD1-B829-8702A8DBEF37';
  p_IntegrationObjectID_0d14d249 := '3F2D9F80-F35B-501D-BC52-66AF079946E5';
  p_Name_0d14d249 := 'created-date';
  p_DisplayName_0d14d249 := 'Created Date';
  p_Description_0d14d249 := 'When ORCID created the item.';
  p_Type_0d14d249 := 'DateTime';
  p_AllowsNull_0d14d249 := TRUE;
  p_IsPrimaryKey_0d14d249 := FALSE;
  p_IsUniqueKey_0d14d249 := FALSE;
  p_IsReadOnly_0d14d249 := TRUE;
  p_IsRequired_0d14d249 := FALSE;
  p_Sequence_0d14d249 := 5;
  p_Status_0d14d249 := 'Active';
  p_IsCustom_0d14d249 := FALSE;
  p_MetadataSource_0d14d249 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_0d14d249, p_IntegrationObjectID := p_IntegrationObjectID_0d14d249, p_Name := p_Name_0d14d249, p_DisplayName := p_DisplayName_0d14d249, p_Description := p_Description_0d14d249, p_Category := p_Category_0d14d249, p_Category_Clear := TRUE, p_Type := p_Type_0d14d249, p_Length := p_Length_0d14d249, p_Length_Clear := TRUE, p_Precision := p_Precision_0d14d249, p_Precision_Clear := TRUE, p_Scale := p_Scale_0d14d249, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_0d14d249, p_DefaultValue := p_DefaultValue_0d14d249, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_0d14d249, p_IsUniqueKey := p_IsUniqueKey_0d14d249, p_IsReadOnly := p_IsReadOnly_0d14d249, p_IsRequired := p_IsRequired_0d14d249, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_0d14d249, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_0d14d249, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_0d14d249, p_Configuration := p_Configuration_0d14d249, p_Configuration_Clear := TRUE, p_Status := p_Status_0d14d249, p_IsCustom := p_IsCustom_0d14d249, p_MetadataSource := p_MetadataSource_0d14d249);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_051e9512 UUID;
  p_IntegrationObjectID_051e9512 UUID;
  p_Name_051e9512 VARCHAR(255);
  p_DisplayName_051e9512 VARCHAR(255);
  p_Description_051e9512 TEXT;
  p_Category_051e9512 VARCHAR(100);
  p_Type_051e9512 VARCHAR(100);
  p_Length_051e9512 INTEGER;
  p_Precision_051e9512 INTEGER;
  p_Scale_051e9512 INTEGER;
  p_AllowsNull_051e9512 BOOLEAN;
  p_DefaultValue_051e9512 VARCHAR(255);
  p_IsPrimaryKey_051e9512 BOOLEAN;
  p_IsUniqueKey_051e9512 BOOLEAN;
  p_IsReadOnly_051e9512 BOOLEAN;
  p_IsRequired_051e9512 BOOLEAN;
  p_RelatedIntegrationObjectID_051e9512 UUID;
  p_RelatedIntegrationObjectFieldName_051e9512 VARCHAR(255);
  p_Sequence_051e9512 INTEGER;
  p_Configuration_051e9512 TEXT;
  p_Status_051e9512 VARCHAR(25);
  p_IsCustom_051e9512 BOOLEAN;
  p_MetadataSource_051e9512 VARCHAR(20);
BEGIN
  p_ID_051e9512 := '05D31C15-3F6D-5546-B5E3-66B24651F2A6';
  p_IntegrationObjectID_051e9512 := '3F2D9F80-F35B-501D-BC52-66AF079946E5';
  p_Name_051e9512 := 'last-modified-date';
  p_DisplayName_051e9512 := 'Last Modified Date';
  p_Description_051e9512 := 'When ORCID last changed the item. Incremental watermark.';
  p_Type_051e9512 := 'DateTime';
  p_AllowsNull_051e9512 := TRUE;
  p_IsPrimaryKey_051e9512 := FALSE;
  p_IsUniqueKey_051e9512 := FALSE;
  p_IsReadOnly_051e9512 := TRUE;
  p_IsRequired_051e9512 := FALSE;
  p_Sequence_051e9512 := 6;
  p_Status_051e9512 := 'Active';
  p_IsCustom_051e9512 := FALSE;
  p_MetadataSource_051e9512 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_051e9512, p_IntegrationObjectID := p_IntegrationObjectID_051e9512, p_Name := p_Name_051e9512, p_DisplayName := p_DisplayName_051e9512, p_Description := p_Description_051e9512, p_Category := p_Category_051e9512, p_Category_Clear := TRUE, p_Type := p_Type_051e9512, p_Length := p_Length_051e9512, p_Length_Clear := TRUE, p_Precision := p_Precision_051e9512, p_Precision_Clear := TRUE, p_Scale := p_Scale_051e9512, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_051e9512, p_DefaultValue := p_DefaultValue_051e9512, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_051e9512, p_IsUniqueKey := p_IsUniqueKey_051e9512, p_IsReadOnly := p_IsReadOnly_051e9512, p_IsRequired := p_IsRequired_051e9512, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_051e9512, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_051e9512, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_051e9512, p_Configuration := p_Configuration_051e9512, p_Configuration_Clear := TRUE, p_Status := p_Status_051e9512, p_IsCustom := p_IsCustom_051e9512, p_MetadataSource := p_MetadataSource_051e9512);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_a95e1c11 UUID;
  p_IntegrationObjectID_a95e1c11 UUID;
  p_Name_a95e1c11 VARCHAR(255);
  p_DisplayName_a95e1c11 VARCHAR(255);
  p_Description_a95e1c11 TEXT;
  p_Category_a95e1c11 VARCHAR(100);
  p_Type_a95e1c11 VARCHAR(100);
  p_Length_a95e1c11 INTEGER;
  p_Precision_a95e1c11 INTEGER;
  p_Scale_a95e1c11 INTEGER;
  p_AllowsNull_a95e1c11 BOOLEAN;
  p_DefaultValue_a95e1c11 VARCHAR(255);
  p_IsPrimaryKey_a95e1c11 BOOLEAN;
  p_IsUniqueKey_a95e1c11 BOOLEAN;
  p_IsReadOnly_a95e1c11 BOOLEAN;
  p_IsRequired_a95e1c11 BOOLEAN;
  p_RelatedIntegrationObjectID_a95e1c11 UUID;
  p_RelatedIntegrationObjectFieldName_a95e1c11 VARCHAR(255);
  p_Sequence_a95e1c11 INTEGER;
  p_Configuration_a95e1c11 TEXT;
  p_Status_a95e1c11 VARCHAR(25);
  p_IsCustom_a95e1c11 BOOLEAN;
  p_MetadataSource_a95e1c11 VARCHAR(20);
BEGIN
  p_ID_a95e1c11 := 'EE4F782C-D27E-5F3E-B5E5-E4DDB5C84D62';
  p_IntegrationObjectID_a95e1c11 := '3F2D9F80-F35B-501D-BC52-66AF079946E5';
  p_Name_a95e1c11 := 'source';
  p_DisplayName_a95e1c11 := 'Source';
  p_Description_a95e1c11 := 'Full source block: who asserted the item.';
  p_Type_a95e1c11 := 'json';
  p_AllowsNull_a95e1c11 := TRUE;
  p_IsPrimaryKey_a95e1c11 := FALSE;
  p_IsUniqueKey_a95e1c11 := FALSE;
  p_IsReadOnly_a95e1c11 := TRUE;
  p_IsRequired_a95e1c11 := FALSE;
  p_Sequence_a95e1c11 := 7;
  p_Status_a95e1c11 := 'Active';
  p_IsCustom_a95e1c11 := FALSE;
  p_MetadataSource_a95e1c11 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_a95e1c11, p_IntegrationObjectID := p_IntegrationObjectID_a95e1c11, p_Name := p_Name_a95e1c11, p_DisplayName := p_DisplayName_a95e1c11, p_Description := p_Description_a95e1c11, p_Category := p_Category_a95e1c11, p_Category_Clear := TRUE, p_Type := p_Type_a95e1c11, p_Length := p_Length_a95e1c11, p_Length_Clear := TRUE, p_Precision := p_Precision_a95e1c11, p_Precision_Clear := TRUE, p_Scale := p_Scale_a95e1c11, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_a95e1c11, p_DefaultValue := p_DefaultValue_a95e1c11, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_a95e1c11, p_IsUniqueKey := p_IsUniqueKey_a95e1c11, p_IsReadOnly := p_IsReadOnly_a95e1c11, p_IsRequired := p_IsRequired_a95e1c11, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_a95e1c11, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_a95e1c11, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_a95e1c11, p_Configuration := p_Configuration_a95e1c11, p_Configuration_Clear := TRUE, p_Status := p_Status_a95e1c11, p_IsCustom := p_IsCustom_a95e1c11, p_MetadataSource := p_MetadataSource_a95e1c11);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_53ff5a3b UUID;
  p_IntegrationObjectID_53ff5a3b UUID;
  p_Name_53ff5a3b VARCHAR(255);
  p_DisplayName_53ff5a3b VARCHAR(255);
  p_Description_53ff5a3b TEXT;
  p_Category_53ff5a3b VARCHAR(100);
  p_Type_53ff5a3b VARCHAR(100);
  p_Length_53ff5a3b INTEGER;
  p_Precision_53ff5a3b INTEGER;
  p_Scale_53ff5a3b INTEGER;
  p_AllowsNull_53ff5a3b BOOLEAN;
  p_DefaultValue_53ff5a3b VARCHAR(255);
  p_IsPrimaryKey_53ff5a3b BOOLEAN;
  p_IsUniqueKey_53ff5a3b BOOLEAN;
  p_IsReadOnly_53ff5a3b BOOLEAN;
  p_IsRequired_53ff5a3b BOOLEAN;
  p_RelatedIntegrationObjectID_53ff5a3b UUID;
  p_RelatedIntegrationObjectFieldName_53ff5a3b VARCHAR(255);
  p_Sequence_53ff5a3b INTEGER;
  p_Configuration_53ff5a3b TEXT;
  p_Status_53ff5a3b VARCHAR(25);
  p_IsCustom_53ff5a3b BOOLEAN;
  p_MetadataSource_53ff5a3b VARCHAR(20);
BEGIN
  p_ID_53ff5a3b := '3DBF9F49-CF57-5EB4-B7F0-47DF51965970';
  p_IntegrationObjectID_53ff5a3b := '3F2D9F80-F35B-501D-BC52-66AF079946E5';
  p_Name_53ff5a3b := 'source-name';
  p_DisplayName_53ff5a3b := 'Source Name';
  p_Description_53ff5a3b := 'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.';
  p_Type_53ff5a3b := 'String';
  p_Length_53ff5a3b := 500;
  p_AllowsNull_53ff5a3b := TRUE;
  p_IsPrimaryKey_53ff5a3b := FALSE;
  p_IsUniqueKey_53ff5a3b := FALSE;
  p_IsReadOnly_53ff5a3b := TRUE;
  p_IsRequired_53ff5a3b := FALSE;
  p_Sequence_53ff5a3b := 8;
  p_Status_53ff5a3b := 'Active';
  p_IsCustom_53ff5a3b := FALSE;
  p_MetadataSource_53ff5a3b := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_53ff5a3b, p_IntegrationObjectID := p_IntegrationObjectID_53ff5a3b, p_Name := p_Name_53ff5a3b, p_DisplayName := p_DisplayName_53ff5a3b, p_Description := p_Description_53ff5a3b, p_Category := p_Category_53ff5a3b, p_Category_Clear := TRUE, p_Type := p_Type_53ff5a3b, p_Length := p_Length_53ff5a3b, p_Precision := p_Precision_53ff5a3b, p_Precision_Clear := TRUE, p_Scale := p_Scale_53ff5a3b, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_53ff5a3b, p_DefaultValue := p_DefaultValue_53ff5a3b, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_53ff5a3b, p_IsUniqueKey := p_IsUniqueKey_53ff5a3b, p_IsReadOnly := p_IsReadOnly_53ff5a3b, p_IsRequired := p_IsRequired_53ff5a3b, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_53ff5a3b, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_53ff5a3b, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_53ff5a3b, p_Configuration := p_Configuration_53ff5a3b, p_Configuration_Clear := TRUE, p_Status := p_Status_53ff5a3b, p_IsCustom := p_IsCustom_53ff5a3b, p_MetadataSource := p_MetadataSource_53ff5a3b);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_2f310673 UUID;
  p_IntegrationObjectID_2f310673 UUID;
  p_Name_2f310673 VARCHAR(255);
  p_DisplayName_2f310673 VARCHAR(255);
  p_Description_2f310673 TEXT;
  p_Category_2f310673 VARCHAR(100);
  p_Type_2f310673 VARCHAR(100);
  p_Length_2f310673 INTEGER;
  p_Precision_2f310673 INTEGER;
  p_Scale_2f310673 INTEGER;
  p_AllowsNull_2f310673 BOOLEAN;
  p_DefaultValue_2f310673 VARCHAR(255);
  p_IsPrimaryKey_2f310673 BOOLEAN;
  p_IsUniqueKey_2f310673 BOOLEAN;
  p_IsReadOnly_2f310673 BOOLEAN;
  p_IsRequired_2f310673 BOOLEAN;
  p_RelatedIntegrationObjectID_2f310673 UUID;
  p_RelatedIntegrationObjectFieldName_2f310673 VARCHAR(255);
  p_Sequence_2f310673 INTEGER;
  p_Configuration_2f310673 TEXT;
  p_Status_2f310673 VARCHAR(25);
  p_IsCustom_2f310673 BOOLEAN;
  p_MetadataSource_2f310673 VARCHAR(20);
BEGIN
  p_ID_2f310673 := '701D706C-70FA-5BCE-937F-D6849AD39187';
  p_IntegrationObjectID_2f310673 := '3F2D9F80-F35B-501D-BC52-66AF079946E5';
  p_Name_2f310673 := 'source-orcid';
  p_DisplayName_2f310673 := 'Source Orcid';
  p_Description_2f310673 := 'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.';
  p_Type_2f310673 := 'String';
  p_Length_2f310673 := 19;
  p_AllowsNull_2f310673 := TRUE;
  p_IsPrimaryKey_2f310673 := FALSE;
  p_IsUniqueKey_2f310673 := FALSE;
  p_IsReadOnly_2f310673 := TRUE;
  p_IsRequired_2f310673 := FALSE;
  p_Sequence_2f310673 := 9;
  p_Status_2f310673 := 'Active';
  p_IsCustom_2f310673 := FALSE;
  p_MetadataSource_2f310673 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_2f310673, p_IntegrationObjectID := p_IntegrationObjectID_2f310673, p_Name := p_Name_2f310673, p_DisplayName := p_DisplayName_2f310673, p_Description := p_Description_2f310673, p_Category := p_Category_2f310673, p_Category_Clear := TRUE, p_Type := p_Type_2f310673, p_Length := p_Length_2f310673, p_Precision := p_Precision_2f310673, p_Precision_Clear := TRUE, p_Scale := p_Scale_2f310673, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_2f310673, p_DefaultValue := p_DefaultValue_2f310673, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_2f310673, p_IsUniqueKey := p_IsUniqueKey_2f310673, p_IsReadOnly := p_IsReadOnly_2f310673, p_IsRequired := p_IsRequired_2f310673, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_2f310673, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_2f310673, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_2f310673, p_Configuration := p_Configuration_2f310673, p_Configuration_Clear := TRUE, p_Status := p_Status_2f310673, p_IsCustom := p_IsCustom_2f310673, p_MetadataSource := p_MetadataSource_2f310673);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_b15ea615 UUID;
  p_IntegrationObjectID_b15ea615 UUID;
  p_Name_b15ea615 VARCHAR(255);
  p_DisplayName_b15ea615 VARCHAR(255);
  p_Description_b15ea615 TEXT;
  p_Category_b15ea615 VARCHAR(100);
  p_Type_b15ea615 VARCHAR(100);
  p_Length_b15ea615 INTEGER;
  p_Precision_b15ea615 INTEGER;
  p_Scale_b15ea615 INTEGER;
  p_AllowsNull_b15ea615 BOOLEAN;
  p_DefaultValue_b15ea615 VARCHAR(255);
  p_IsPrimaryKey_b15ea615 BOOLEAN;
  p_IsUniqueKey_b15ea615 BOOLEAN;
  p_IsReadOnly_b15ea615 BOOLEAN;
  p_IsRequired_b15ea615 BOOLEAN;
  p_RelatedIntegrationObjectID_b15ea615 UUID;
  p_RelatedIntegrationObjectFieldName_b15ea615 VARCHAR(255);
  p_Sequence_b15ea615 INTEGER;
  p_Configuration_b15ea615 TEXT;
  p_Status_b15ea615 VARCHAR(25);
  p_IsCustom_b15ea615 BOOLEAN;
  p_MetadataSource_b15ea615 VARCHAR(20);
BEGIN
  p_ID_b15ea615 := '325CCA41-3F69-5F14-AC9B-28D6BEBDC6CB';
  p_IntegrationObjectID_b15ea615 := '3F2D9F80-F35B-501D-BC52-66AF079946E5';
  p_Name_b15ea615 := 'url-name';
  p_DisplayName_b15ea615 := 'Url Name';
  p_Description_b15ea615 := 'Label of the link (e.g. Lab Website).';
  p_Type_b15ea615 := 'String';
  p_Length_b15ea615 := 500;
  p_AllowsNull_b15ea615 := TRUE;
  p_IsPrimaryKey_b15ea615 := FALSE;
  p_IsUniqueKey_b15ea615 := FALSE;
  p_IsReadOnly_b15ea615 := TRUE;
  p_IsRequired_b15ea615 := FALSE;
  p_Sequence_b15ea615 := 10;
  p_Status_b15ea615 := 'Active';
  p_IsCustom_b15ea615 := FALSE;
  p_MetadataSource_b15ea615 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_b15ea615, p_IntegrationObjectID := p_IntegrationObjectID_b15ea615, p_Name := p_Name_b15ea615, p_DisplayName := p_DisplayName_b15ea615, p_Description := p_Description_b15ea615, p_Category := p_Category_b15ea615, p_Category_Clear := TRUE, p_Type := p_Type_b15ea615, p_Length := p_Length_b15ea615, p_Precision := p_Precision_b15ea615, p_Precision_Clear := TRUE, p_Scale := p_Scale_b15ea615, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_b15ea615, p_DefaultValue := p_DefaultValue_b15ea615, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_b15ea615, p_IsUniqueKey := p_IsUniqueKey_b15ea615, p_IsReadOnly := p_IsReadOnly_b15ea615, p_IsRequired := p_IsRequired_b15ea615, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_b15ea615, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_b15ea615, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_b15ea615, p_Configuration := p_Configuration_b15ea615, p_Configuration_Clear := TRUE, p_Status := p_Status_b15ea615, p_IsCustom := p_IsCustom_b15ea615, p_MetadataSource := p_MetadataSource_b15ea615);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_78a345c3 UUID;
  p_IntegrationObjectID_78a345c3 UUID;
  p_Name_78a345c3 VARCHAR(255);
  p_DisplayName_78a345c3 VARCHAR(255);
  p_Description_78a345c3 TEXT;
  p_Category_78a345c3 VARCHAR(100);
  p_Type_78a345c3 VARCHAR(100);
  p_Length_78a345c3 INTEGER;
  p_Precision_78a345c3 INTEGER;
  p_Scale_78a345c3 INTEGER;
  p_AllowsNull_78a345c3 BOOLEAN;
  p_DefaultValue_78a345c3 VARCHAR(255);
  p_IsPrimaryKey_78a345c3 BOOLEAN;
  p_IsUniqueKey_78a345c3 BOOLEAN;
  p_IsReadOnly_78a345c3 BOOLEAN;
  p_IsRequired_78a345c3 BOOLEAN;
  p_RelatedIntegrationObjectID_78a345c3 UUID;
  p_RelatedIntegrationObjectFieldName_78a345c3 VARCHAR(255);
  p_Sequence_78a345c3 INTEGER;
  p_Configuration_78a345c3 TEXT;
  p_Status_78a345c3 VARCHAR(25);
  p_IsCustom_78a345c3 BOOLEAN;
  p_MetadataSource_78a345c3 VARCHAR(20);
BEGIN
  p_ID_78a345c3 := '00266154-4906-5F63-813C-F935D4824E8A';
  p_IntegrationObjectID_78a345c3 := '3F2D9F80-F35B-501D-BC52-66AF079946E5';
  p_Name_78a345c3 := 'url';
  p_DisplayName_78a345c3 := 'Url';
  p_Description_78a345c3 := 'The URL.';
  p_Type_78a345c3 := 'String';
  p_Length_78a345c3 := 2048;
  p_AllowsNull_78a345c3 := TRUE;
  p_IsPrimaryKey_78a345c3 := FALSE;
  p_IsUniqueKey_78a345c3 := FALSE;
  p_IsReadOnly_78a345c3 := TRUE;
  p_IsRequired_78a345c3 := FALSE;
  p_Sequence_78a345c3 := 11;
  p_Status_78a345c3 := 'Active';
  p_IsCustom_78a345c3 := FALSE;
  p_MetadataSource_78a345c3 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_78a345c3, p_IntegrationObjectID := p_IntegrationObjectID_78a345c3, p_Name := p_Name_78a345c3, p_DisplayName := p_DisplayName_78a345c3, p_Description := p_Description_78a345c3, p_Category := p_Category_78a345c3, p_Category_Clear := TRUE, p_Type := p_Type_78a345c3, p_Length := p_Length_78a345c3, p_Precision := p_Precision_78a345c3, p_Precision_Clear := TRUE, p_Scale := p_Scale_78a345c3, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_78a345c3, p_DefaultValue := p_DefaultValue_78a345c3, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_78a345c3, p_IsUniqueKey := p_IsUniqueKey_78a345c3, p_IsReadOnly := p_IsReadOnly_78a345c3, p_IsRequired := p_IsRequired_78a345c3, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_78a345c3, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_78a345c3, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_78a345c3, p_Configuration := p_Configuration_78a345c3, p_Configuration_Clear := TRUE, p_Status := p_Status_78a345c3, p_IsCustom := p_IsCustom_78a345c3, p_MetadataSource := p_MetadataSource_78a345c3);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_5ff1c0c5 UUID;
  p_IntegrationObjectID_5ff1c0c5 UUID;
  p_Name_5ff1c0c5 VARCHAR(255);
  p_DisplayName_5ff1c0c5 VARCHAR(255);
  p_Description_5ff1c0c5 TEXT;
  p_Category_5ff1c0c5 VARCHAR(100);
  p_Type_5ff1c0c5 VARCHAR(100);
  p_Length_5ff1c0c5 INTEGER;
  p_Precision_5ff1c0c5 INTEGER;
  p_Scale_5ff1c0c5 INTEGER;
  p_AllowsNull_5ff1c0c5 BOOLEAN;
  p_DefaultValue_5ff1c0c5 VARCHAR(255);
  p_IsPrimaryKey_5ff1c0c5 BOOLEAN;
  p_IsUniqueKey_5ff1c0c5 BOOLEAN;
  p_IsReadOnly_5ff1c0c5 BOOLEAN;
  p_IsRequired_5ff1c0c5 BOOLEAN;
  p_RelatedIntegrationObjectID_5ff1c0c5 UUID;
  p_RelatedIntegrationObjectFieldName_5ff1c0c5 VARCHAR(255);
  p_Sequence_5ff1c0c5 INTEGER;
  p_Configuration_5ff1c0c5 TEXT;
  p_Status_5ff1c0c5 VARCHAR(25);
  p_IsCustom_5ff1c0c5 BOOLEAN;
  p_MetadataSource_5ff1c0c5 VARCHAR(20);
BEGIN
  p_ID_5ff1c0c5 := '5C294C8F-6D4E-5ACE-99E4-F188340607D2';
  p_IntegrationObjectID_5ff1c0c5 := '224D74C1-460F-5612-BD7D-29027DF76792';
  p_Name_5ff1c0c5 := 'orcid-id';
  p_DisplayName_5ff1c0c5 := 'Orcid Id';
  p_Description_5ff1c0c5 := 'The ORCID iD of the researcher this item belongs to. Foreign key to the record object.';
  p_Type_5ff1c0c5 := 'String';
  p_Length_5ff1c0c5 := 19;
  p_AllowsNull_5ff1c0c5 := TRUE;
  p_IsPrimaryKey_5ff1c0c5 := FALSE;
  p_IsUniqueKey_5ff1c0c5 := FALSE;
  p_IsReadOnly_5ff1c0c5 := TRUE;
  p_IsRequired_5ff1c0c5 := TRUE;
  p_RelatedIntegrationObjectID_5ff1c0c5 := '73AED6B8-468D-403B-B994-F3C786C98BC0';
  p_RelatedIntegrationObjectFieldName_5ff1c0c5 := 'orcid-id';
  p_Sequence_5ff1c0c5 := 0;
  p_Status_5ff1c0c5 := 'Active';
  p_IsCustom_5ff1c0c5 := FALSE;
  p_MetadataSource_5ff1c0c5 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_5ff1c0c5, p_IntegrationObjectID := p_IntegrationObjectID_5ff1c0c5, p_Name := p_Name_5ff1c0c5, p_DisplayName := p_DisplayName_5ff1c0c5, p_Description := p_Description_5ff1c0c5, p_Category := p_Category_5ff1c0c5, p_Category_Clear := TRUE, p_Type := p_Type_5ff1c0c5, p_Length := p_Length_5ff1c0c5, p_Precision := p_Precision_5ff1c0c5, p_Precision_Clear := TRUE, p_Scale := p_Scale_5ff1c0c5, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_5ff1c0c5, p_DefaultValue := p_DefaultValue_5ff1c0c5, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_5ff1c0c5, p_IsUniqueKey := p_IsUniqueKey_5ff1c0c5, p_IsReadOnly := p_IsReadOnly_5ff1c0c5, p_IsRequired := p_IsRequired_5ff1c0c5, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_5ff1c0c5, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_5ff1c0c5, p_Sequence := p_Sequence_5ff1c0c5, p_Configuration := p_Configuration_5ff1c0c5, p_Configuration_Clear := TRUE, p_Status := p_Status_5ff1c0c5, p_IsCustom := p_IsCustom_5ff1c0c5, p_MetadataSource := p_MetadataSource_5ff1c0c5);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_e0536f5d UUID;
  p_IntegrationObjectID_e0536f5d UUID;
  p_Name_e0536f5d VARCHAR(255);
  p_DisplayName_e0536f5d VARCHAR(255);
  p_Description_e0536f5d TEXT;
  p_Category_e0536f5d VARCHAR(100);
  p_Type_e0536f5d VARCHAR(100);
  p_Length_e0536f5d INTEGER;
  p_Precision_e0536f5d INTEGER;
  p_Scale_e0536f5d INTEGER;
  p_AllowsNull_e0536f5d BOOLEAN;
  p_DefaultValue_e0536f5d VARCHAR(255);
  p_IsPrimaryKey_e0536f5d BOOLEAN;
  p_IsUniqueKey_e0536f5d BOOLEAN;
  p_IsReadOnly_e0536f5d BOOLEAN;
  p_IsRequired_e0536f5d BOOLEAN;
  p_RelatedIntegrationObjectID_e0536f5d UUID;
  p_RelatedIntegrationObjectFieldName_e0536f5d VARCHAR(255);
  p_Sequence_e0536f5d INTEGER;
  p_Configuration_e0536f5d TEXT;
  p_Status_e0536f5d VARCHAR(25);
  p_IsCustom_e0536f5d BOOLEAN;
  p_MetadataSource_e0536f5d VARCHAR(20);
BEGIN
  p_ID_e0536f5d := 'EB3EDA0E-C8B9-5D19-AFEB-2A49317A9BE1';
  p_IntegrationObjectID_e0536f5d := '224D74C1-460F-5612-BD7D-29027DF76792';
  p_Name_e0536f5d := 'put-code';
  p_DisplayName_e0536f5d := 'Put Code';
  p_Description_e0536f5d := 'ORCID''s stable identifier for this item within the record. Primary key.';
  p_Type_e0536f5d := 'Integer';
  p_AllowsNull_e0536f5d := FALSE;
  p_IsPrimaryKey_e0536f5d := TRUE;
  p_IsUniqueKey_e0536f5d := TRUE;
  p_IsReadOnly_e0536f5d := TRUE;
  p_IsRequired_e0536f5d := TRUE;
  p_Sequence_e0536f5d := 1;
  p_Status_e0536f5d := 'Active';
  p_IsCustom_e0536f5d := FALSE;
  p_MetadataSource_e0536f5d := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_e0536f5d, p_IntegrationObjectID := p_IntegrationObjectID_e0536f5d, p_Name := p_Name_e0536f5d, p_DisplayName := p_DisplayName_e0536f5d, p_Description := p_Description_e0536f5d, p_Category := p_Category_e0536f5d, p_Category_Clear := TRUE, p_Type := p_Type_e0536f5d, p_Length := p_Length_e0536f5d, p_Length_Clear := TRUE, p_Precision := p_Precision_e0536f5d, p_Precision_Clear := TRUE, p_Scale := p_Scale_e0536f5d, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_e0536f5d, p_DefaultValue := p_DefaultValue_e0536f5d, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_e0536f5d, p_IsUniqueKey := p_IsUniqueKey_e0536f5d, p_IsReadOnly := p_IsReadOnly_e0536f5d, p_IsRequired := p_IsRequired_e0536f5d, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_e0536f5d, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_e0536f5d, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_e0536f5d, p_Configuration := p_Configuration_e0536f5d, p_Configuration_Clear := TRUE, p_Status := p_Status_e0536f5d, p_IsCustom := p_IsCustom_e0536f5d, p_MetadataSource := p_MetadataSource_e0536f5d);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_68fa326d UUID;
  p_IntegrationObjectID_68fa326d UUID;
  p_Name_68fa326d VARCHAR(255);
  p_DisplayName_68fa326d VARCHAR(255);
  p_Description_68fa326d TEXT;
  p_Category_68fa326d VARCHAR(100);
  p_Type_68fa326d VARCHAR(100);
  p_Length_68fa326d INTEGER;
  p_Precision_68fa326d INTEGER;
  p_Scale_68fa326d INTEGER;
  p_AllowsNull_68fa326d BOOLEAN;
  p_DefaultValue_68fa326d VARCHAR(255);
  p_IsPrimaryKey_68fa326d BOOLEAN;
  p_IsUniqueKey_68fa326d BOOLEAN;
  p_IsReadOnly_68fa326d BOOLEAN;
  p_IsRequired_68fa326d BOOLEAN;
  p_RelatedIntegrationObjectID_68fa326d UUID;
  p_RelatedIntegrationObjectFieldName_68fa326d VARCHAR(255);
  p_Sequence_68fa326d INTEGER;
  p_Configuration_68fa326d TEXT;
  p_Status_68fa326d VARCHAR(25);
  p_IsCustom_68fa326d BOOLEAN;
  p_MetadataSource_68fa326d VARCHAR(20);
BEGIN
  p_ID_68fa326d := '35CE4EC2-D2BF-599F-A77C-FCC453D3BEFE';
  p_IntegrationObjectID_68fa326d := '224D74C1-460F-5612-BD7D-29027DF76792';
  p_Name_68fa326d := 'path';
  p_DisplayName_68fa326d := 'Path';
  p_Description_68fa326d := 'Element path /{orcid}/{section}/{put-code}.';
  p_Type_68fa326d := 'String';
  p_Length_68fa326d := 500;
  p_AllowsNull_68fa326d := TRUE;
  p_IsPrimaryKey_68fa326d := FALSE;
  p_IsUniqueKey_68fa326d := FALSE;
  p_IsReadOnly_68fa326d := TRUE;
  p_IsRequired_68fa326d := FALSE;
  p_Sequence_68fa326d := 2;
  p_Status_68fa326d := 'Active';
  p_IsCustom_68fa326d := FALSE;
  p_MetadataSource_68fa326d := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_68fa326d, p_IntegrationObjectID := p_IntegrationObjectID_68fa326d, p_Name := p_Name_68fa326d, p_DisplayName := p_DisplayName_68fa326d, p_Description := p_Description_68fa326d, p_Category := p_Category_68fa326d, p_Category_Clear := TRUE, p_Type := p_Type_68fa326d, p_Length := p_Length_68fa326d, p_Precision := p_Precision_68fa326d, p_Precision_Clear := TRUE, p_Scale := p_Scale_68fa326d, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_68fa326d, p_DefaultValue := p_DefaultValue_68fa326d, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_68fa326d, p_IsUniqueKey := p_IsUniqueKey_68fa326d, p_IsReadOnly := p_IsReadOnly_68fa326d, p_IsRequired := p_IsRequired_68fa326d, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_68fa326d, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_68fa326d, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_68fa326d, p_Configuration := p_Configuration_68fa326d, p_Configuration_Clear := TRUE, p_Status := p_Status_68fa326d, p_IsCustom := p_IsCustom_68fa326d, p_MetadataSource := p_MetadataSource_68fa326d);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_bad9a426 UUID;
  p_IntegrationObjectID_bad9a426 UUID;
  p_Name_bad9a426 VARCHAR(255);
  p_DisplayName_bad9a426 VARCHAR(255);
  p_Description_bad9a426 TEXT;
  p_Category_bad9a426 VARCHAR(100);
  p_Type_bad9a426 VARCHAR(100);
  p_Length_bad9a426 INTEGER;
  p_Precision_bad9a426 INTEGER;
  p_Scale_bad9a426 INTEGER;
  p_AllowsNull_bad9a426 BOOLEAN;
  p_DefaultValue_bad9a426 VARCHAR(255);
  p_IsPrimaryKey_bad9a426 BOOLEAN;
  p_IsUniqueKey_bad9a426 BOOLEAN;
  p_IsReadOnly_bad9a426 BOOLEAN;
  p_IsRequired_bad9a426 BOOLEAN;
  p_RelatedIntegrationObjectID_bad9a426 UUID;
  p_RelatedIntegrationObjectFieldName_bad9a426 VARCHAR(255);
  p_Sequence_bad9a426 INTEGER;
  p_Configuration_bad9a426 TEXT;
  p_Status_bad9a426 VARCHAR(25);
  p_IsCustom_bad9a426 BOOLEAN;
  p_MetadataSource_bad9a426 VARCHAR(20);
BEGIN
  p_ID_bad9a426 := '42A99AD8-E850-55C5-86EA-714A4FE6C990';
  p_IntegrationObjectID_bad9a426 := '224D74C1-460F-5612-BD7D-29027DF76792';
  p_Name_bad9a426 := 'visibility';
  p_DisplayName_bad9a426 := 'Visibility';
  p_Description_bad9a426 := 'ORCID visibility of the item (public, limited, private). The Public API only serves public.';
  p_Type_bad9a426 := 'String';
  p_AllowsNull_bad9a426 := TRUE;
  p_IsPrimaryKey_bad9a426 := FALSE;
  p_IsUniqueKey_bad9a426 := FALSE;
  p_IsReadOnly_bad9a426 := TRUE;
  p_IsRequired_bad9a426 := FALSE;
  p_Sequence_bad9a426 := 3;
  p_Status_bad9a426 := 'Active';
  p_IsCustom_bad9a426 := FALSE;
  p_MetadataSource_bad9a426 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_bad9a426, p_IntegrationObjectID := p_IntegrationObjectID_bad9a426, p_Name := p_Name_bad9a426, p_DisplayName := p_DisplayName_bad9a426, p_Description := p_Description_bad9a426, p_Category := p_Category_bad9a426, p_Category_Clear := TRUE, p_Type := p_Type_bad9a426, p_Length := p_Length_bad9a426, p_Length_Clear := TRUE, p_Precision := p_Precision_bad9a426, p_Precision_Clear := TRUE, p_Scale := p_Scale_bad9a426, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_bad9a426, p_DefaultValue := p_DefaultValue_bad9a426, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_bad9a426, p_IsUniqueKey := p_IsUniqueKey_bad9a426, p_IsReadOnly := p_IsReadOnly_bad9a426, p_IsRequired := p_IsRequired_bad9a426, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_bad9a426, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_bad9a426, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_bad9a426, p_Configuration := p_Configuration_bad9a426, p_Configuration_Clear := TRUE, p_Status := p_Status_bad9a426, p_IsCustom := p_IsCustom_bad9a426, p_MetadataSource := p_MetadataSource_bad9a426);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_27927602 UUID;
  p_IntegrationObjectID_27927602 UUID;
  p_Name_27927602 VARCHAR(255);
  p_DisplayName_27927602 VARCHAR(255);
  p_Description_27927602 TEXT;
  p_Category_27927602 VARCHAR(100);
  p_Type_27927602 VARCHAR(100);
  p_Length_27927602 INTEGER;
  p_Precision_27927602 INTEGER;
  p_Scale_27927602 INTEGER;
  p_AllowsNull_27927602 BOOLEAN;
  p_DefaultValue_27927602 VARCHAR(255);
  p_IsPrimaryKey_27927602 BOOLEAN;
  p_IsUniqueKey_27927602 BOOLEAN;
  p_IsReadOnly_27927602 BOOLEAN;
  p_IsRequired_27927602 BOOLEAN;
  p_RelatedIntegrationObjectID_27927602 UUID;
  p_RelatedIntegrationObjectFieldName_27927602 VARCHAR(255);
  p_Sequence_27927602 INTEGER;
  p_Configuration_27927602 TEXT;
  p_Status_27927602 VARCHAR(25);
  p_IsCustom_27927602 BOOLEAN;
  p_MetadataSource_27927602 VARCHAR(20);
BEGIN
  p_ID_27927602 := '1C86C30D-09A2-579E-978C-36B935202D39';
  p_IntegrationObjectID_27927602 := '224D74C1-460F-5612-BD7D-29027DF76792';
  p_Name_27927602 := 'display-index';
  p_DisplayName_27927602 := 'Display Index';
  p_Description_27927602 := 'Display order the researcher chose for the item.';
  p_Type_27927602 := 'String';
  p_AllowsNull_27927602 := TRUE;
  p_IsPrimaryKey_27927602 := FALSE;
  p_IsUniqueKey_27927602 := FALSE;
  p_IsReadOnly_27927602 := TRUE;
  p_IsRequired_27927602 := FALSE;
  p_Sequence_27927602 := 4;
  p_Status_27927602 := 'Active';
  p_IsCustom_27927602 := FALSE;
  p_MetadataSource_27927602 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_27927602, p_IntegrationObjectID := p_IntegrationObjectID_27927602, p_Name := p_Name_27927602, p_DisplayName := p_DisplayName_27927602, p_Description := p_Description_27927602, p_Category := p_Category_27927602, p_Category_Clear := TRUE, p_Type := p_Type_27927602, p_Length := p_Length_27927602, p_Length_Clear := TRUE, p_Precision := p_Precision_27927602, p_Precision_Clear := TRUE, p_Scale := p_Scale_27927602, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_27927602, p_DefaultValue := p_DefaultValue_27927602, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_27927602, p_IsUniqueKey := p_IsUniqueKey_27927602, p_IsReadOnly := p_IsReadOnly_27927602, p_IsRequired := p_IsRequired_27927602, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_27927602, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_27927602, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_27927602, p_Configuration := p_Configuration_27927602, p_Configuration_Clear := TRUE, p_Status := p_Status_27927602, p_IsCustom := p_IsCustom_27927602, p_MetadataSource := p_MetadataSource_27927602);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_02e0c827 UUID;
  p_IntegrationObjectID_02e0c827 UUID;
  p_Name_02e0c827 VARCHAR(255);
  p_DisplayName_02e0c827 VARCHAR(255);
  p_Description_02e0c827 TEXT;
  p_Category_02e0c827 VARCHAR(100);
  p_Type_02e0c827 VARCHAR(100);
  p_Length_02e0c827 INTEGER;
  p_Precision_02e0c827 INTEGER;
  p_Scale_02e0c827 INTEGER;
  p_AllowsNull_02e0c827 BOOLEAN;
  p_DefaultValue_02e0c827 VARCHAR(255);
  p_IsPrimaryKey_02e0c827 BOOLEAN;
  p_IsUniqueKey_02e0c827 BOOLEAN;
  p_IsReadOnly_02e0c827 BOOLEAN;
  p_IsRequired_02e0c827 BOOLEAN;
  p_RelatedIntegrationObjectID_02e0c827 UUID;
  p_RelatedIntegrationObjectFieldName_02e0c827 VARCHAR(255);
  p_Sequence_02e0c827 INTEGER;
  p_Configuration_02e0c827 TEXT;
  p_Status_02e0c827 VARCHAR(25);
  p_IsCustom_02e0c827 BOOLEAN;
  p_MetadataSource_02e0c827 VARCHAR(20);
BEGIN
  p_ID_02e0c827 := '173A1B20-21FE-5431-9578-D7A599DF552C';
  p_IntegrationObjectID_02e0c827 := '224D74C1-460F-5612-BD7D-29027DF76792';
  p_Name_02e0c827 := 'created-date';
  p_DisplayName_02e0c827 := 'Created Date';
  p_Description_02e0c827 := 'When ORCID created the item.';
  p_Type_02e0c827 := 'DateTime';
  p_AllowsNull_02e0c827 := TRUE;
  p_IsPrimaryKey_02e0c827 := FALSE;
  p_IsUniqueKey_02e0c827 := FALSE;
  p_IsReadOnly_02e0c827 := TRUE;
  p_IsRequired_02e0c827 := FALSE;
  p_Sequence_02e0c827 := 5;
  p_Status_02e0c827 := 'Active';
  p_IsCustom_02e0c827 := FALSE;
  p_MetadataSource_02e0c827 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_02e0c827, p_IntegrationObjectID := p_IntegrationObjectID_02e0c827, p_Name := p_Name_02e0c827, p_DisplayName := p_DisplayName_02e0c827, p_Description := p_Description_02e0c827, p_Category := p_Category_02e0c827, p_Category_Clear := TRUE, p_Type := p_Type_02e0c827, p_Length := p_Length_02e0c827, p_Length_Clear := TRUE, p_Precision := p_Precision_02e0c827, p_Precision_Clear := TRUE, p_Scale := p_Scale_02e0c827, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_02e0c827, p_DefaultValue := p_DefaultValue_02e0c827, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_02e0c827, p_IsUniqueKey := p_IsUniqueKey_02e0c827, p_IsReadOnly := p_IsReadOnly_02e0c827, p_IsRequired := p_IsRequired_02e0c827, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_02e0c827, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_02e0c827, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_02e0c827, p_Configuration := p_Configuration_02e0c827, p_Configuration_Clear := TRUE, p_Status := p_Status_02e0c827, p_IsCustom := p_IsCustom_02e0c827, p_MetadataSource := p_MetadataSource_02e0c827);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_6847a9d8 UUID;
  p_IntegrationObjectID_6847a9d8 UUID;
  p_Name_6847a9d8 VARCHAR(255);
  p_DisplayName_6847a9d8 VARCHAR(255);
  p_Description_6847a9d8 TEXT;
  p_Category_6847a9d8 VARCHAR(100);
  p_Type_6847a9d8 VARCHAR(100);
  p_Length_6847a9d8 INTEGER;
  p_Precision_6847a9d8 INTEGER;
  p_Scale_6847a9d8 INTEGER;
  p_AllowsNull_6847a9d8 BOOLEAN;
  p_DefaultValue_6847a9d8 VARCHAR(255);
  p_IsPrimaryKey_6847a9d8 BOOLEAN;
  p_IsUniqueKey_6847a9d8 BOOLEAN;
  p_IsReadOnly_6847a9d8 BOOLEAN;
  p_IsRequired_6847a9d8 BOOLEAN;
  p_RelatedIntegrationObjectID_6847a9d8 UUID;
  p_RelatedIntegrationObjectFieldName_6847a9d8 VARCHAR(255);
  p_Sequence_6847a9d8 INTEGER;
  p_Configuration_6847a9d8 TEXT;
  p_Status_6847a9d8 VARCHAR(25);
  p_IsCustom_6847a9d8 BOOLEAN;
  p_MetadataSource_6847a9d8 VARCHAR(20);
BEGIN
  p_ID_6847a9d8 := '1DA5926F-63B5-56C2-9220-DB90D910F8DC';
  p_IntegrationObjectID_6847a9d8 := '224D74C1-460F-5612-BD7D-29027DF76792';
  p_Name_6847a9d8 := 'last-modified-date';
  p_DisplayName_6847a9d8 := 'Last Modified Date';
  p_Description_6847a9d8 := 'When ORCID last changed the item. Incremental watermark.';
  p_Type_6847a9d8 := 'DateTime';
  p_AllowsNull_6847a9d8 := TRUE;
  p_IsPrimaryKey_6847a9d8 := FALSE;
  p_IsUniqueKey_6847a9d8 := FALSE;
  p_IsReadOnly_6847a9d8 := TRUE;
  p_IsRequired_6847a9d8 := FALSE;
  p_Sequence_6847a9d8 := 6;
  p_Status_6847a9d8 := 'Active';
  p_IsCustom_6847a9d8 := FALSE;
  p_MetadataSource_6847a9d8 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_6847a9d8, p_IntegrationObjectID := p_IntegrationObjectID_6847a9d8, p_Name := p_Name_6847a9d8, p_DisplayName := p_DisplayName_6847a9d8, p_Description := p_Description_6847a9d8, p_Category := p_Category_6847a9d8, p_Category_Clear := TRUE, p_Type := p_Type_6847a9d8, p_Length := p_Length_6847a9d8, p_Length_Clear := TRUE, p_Precision := p_Precision_6847a9d8, p_Precision_Clear := TRUE, p_Scale := p_Scale_6847a9d8, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_6847a9d8, p_DefaultValue := p_DefaultValue_6847a9d8, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_6847a9d8, p_IsUniqueKey := p_IsUniqueKey_6847a9d8, p_IsReadOnly := p_IsReadOnly_6847a9d8, p_IsRequired := p_IsRequired_6847a9d8, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_6847a9d8, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_6847a9d8, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_6847a9d8, p_Configuration := p_Configuration_6847a9d8, p_Configuration_Clear := TRUE, p_Status := p_Status_6847a9d8, p_IsCustom := p_IsCustom_6847a9d8, p_MetadataSource := p_MetadataSource_6847a9d8);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_f4d60da2 UUID;
  p_IntegrationObjectID_f4d60da2 UUID;
  p_Name_f4d60da2 VARCHAR(255);
  p_DisplayName_f4d60da2 VARCHAR(255);
  p_Description_f4d60da2 TEXT;
  p_Category_f4d60da2 VARCHAR(100);
  p_Type_f4d60da2 VARCHAR(100);
  p_Length_f4d60da2 INTEGER;
  p_Precision_f4d60da2 INTEGER;
  p_Scale_f4d60da2 INTEGER;
  p_AllowsNull_f4d60da2 BOOLEAN;
  p_DefaultValue_f4d60da2 VARCHAR(255);
  p_IsPrimaryKey_f4d60da2 BOOLEAN;
  p_IsUniqueKey_f4d60da2 BOOLEAN;
  p_IsReadOnly_f4d60da2 BOOLEAN;
  p_IsRequired_f4d60da2 BOOLEAN;
  p_RelatedIntegrationObjectID_f4d60da2 UUID;
  p_RelatedIntegrationObjectFieldName_f4d60da2 VARCHAR(255);
  p_Sequence_f4d60da2 INTEGER;
  p_Configuration_f4d60da2 TEXT;
  p_Status_f4d60da2 VARCHAR(25);
  p_IsCustom_f4d60da2 BOOLEAN;
  p_MetadataSource_f4d60da2 VARCHAR(20);
BEGIN
  p_ID_f4d60da2 := '83DF2608-2DF6-5DAF-B5C1-A7BFF3C04B5D';
  p_IntegrationObjectID_f4d60da2 := '224D74C1-460F-5612-BD7D-29027DF76792';
  p_Name_f4d60da2 := 'source';
  p_DisplayName_f4d60da2 := 'Source';
  p_Description_f4d60da2 := 'Full source block: who asserted the item.';
  p_Type_f4d60da2 := 'json';
  p_AllowsNull_f4d60da2 := TRUE;
  p_IsPrimaryKey_f4d60da2 := FALSE;
  p_IsUniqueKey_f4d60da2 := FALSE;
  p_IsReadOnly_f4d60da2 := TRUE;
  p_IsRequired_f4d60da2 := FALSE;
  p_Sequence_f4d60da2 := 7;
  p_Status_f4d60da2 := 'Active';
  p_IsCustom_f4d60da2 := FALSE;
  p_MetadataSource_f4d60da2 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_f4d60da2, p_IntegrationObjectID := p_IntegrationObjectID_f4d60da2, p_Name := p_Name_f4d60da2, p_DisplayName := p_DisplayName_f4d60da2, p_Description := p_Description_f4d60da2, p_Category := p_Category_f4d60da2, p_Category_Clear := TRUE, p_Type := p_Type_f4d60da2, p_Length := p_Length_f4d60da2, p_Length_Clear := TRUE, p_Precision := p_Precision_f4d60da2, p_Precision_Clear := TRUE, p_Scale := p_Scale_f4d60da2, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_f4d60da2, p_DefaultValue := p_DefaultValue_f4d60da2, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_f4d60da2, p_IsUniqueKey := p_IsUniqueKey_f4d60da2, p_IsReadOnly := p_IsReadOnly_f4d60da2, p_IsRequired := p_IsRequired_f4d60da2, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_f4d60da2, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_f4d60da2, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_f4d60da2, p_Configuration := p_Configuration_f4d60da2, p_Configuration_Clear := TRUE, p_Status := p_Status_f4d60da2, p_IsCustom := p_IsCustom_f4d60da2, p_MetadataSource := p_MetadataSource_f4d60da2);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_5e5901c2 UUID;
  p_IntegrationObjectID_5e5901c2 UUID;
  p_Name_5e5901c2 VARCHAR(255);
  p_DisplayName_5e5901c2 VARCHAR(255);
  p_Description_5e5901c2 TEXT;
  p_Category_5e5901c2 VARCHAR(100);
  p_Type_5e5901c2 VARCHAR(100);
  p_Length_5e5901c2 INTEGER;
  p_Precision_5e5901c2 INTEGER;
  p_Scale_5e5901c2 INTEGER;
  p_AllowsNull_5e5901c2 BOOLEAN;
  p_DefaultValue_5e5901c2 VARCHAR(255);
  p_IsPrimaryKey_5e5901c2 BOOLEAN;
  p_IsUniqueKey_5e5901c2 BOOLEAN;
  p_IsReadOnly_5e5901c2 BOOLEAN;
  p_IsRequired_5e5901c2 BOOLEAN;
  p_RelatedIntegrationObjectID_5e5901c2 UUID;
  p_RelatedIntegrationObjectFieldName_5e5901c2 VARCHAR(255);
  p_Sequence_5e5901c2 INTEGER;
  p_Configuration_5e5901c2 TEXT;
  p_Status_5e5901c2 VARCHAR(25);
  p_IsCustom_5e5901c2 BOOLEAN;
  p_MetadataSource_5e5901c2 VARCHAR(20);
BEGIN
  p_ID_5e5901c2 := 'ACD345D8-841E-512A-8BCA-ADB8D6983AA3';
  p_IntegrationObjectID_5e5901c2 := '224D74C1-460F-5612-BD7D-29027DF76792';
  p_Name_5e5901c2 := 'source-name';
  p_DisplayName_5e5901c2 := 'Source Name';
  p_Description_5e5901c2 := 'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.';
  p_Type_5e5901c2 := 'String';
  p_Length_5e5901c2 := 500;
  p_AllowsNull_5e5901c2 := TRUE;
  p_IsPrimaryKey_5e5901c2 := FALSE;
  p_IsUniqueKey_5e5901c2 := FALSE;
  p_IsReadOnly_5e5901c2 := TRUE;
  p_IsRequired_5e5901c2 := FALSE;
  p_Sequence_5e5901c2 := 8;
  p_Status_5e5901c2 := 'Active';
  p_IsCustom_5e5901c2 := FALSE;
  p_MetadataSource_5e5901c2 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_5e5901c2, p_IntegrationObjectID := p_IntegrationObjectID_5e5901c2, p_Name := p_Name_5e5901c2, p_DisplayName := p_DisplayName_5e5901c2, p_Description := p_Description_5e5901c2, p_Category := p_Category_5e5901c2, p_Category_Clear := TRUE, p_Type := p_Type_5e5901c2, p_Length := p_Length_5e5901c2, p_Precision := p_Precision_5e5901c2, p_Precision_Clear := TRUE, p_Scale := p_Scale_5e5901c2, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_5e5901c2, p_DefaultValue := p_DefaultValue_5e5901c2, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_5e5901c2, p_IsUniqueKey := p_IsUniqueKey_5e5901c2, p_IsReadOnly := p_IsReadOnly_5e5901c2, p_IsRequired := p_IsRequired_5e5901c2, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_5e5901c2, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_5e5901c2, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_5e5901c2, p_Configuration := p_Configuration_5e5901c2, p_Configuration_Clear := TRUE, p_Status := p_Status_5e5901c2, p_IsCustom := p_IsCustom_5e5901c2, p_MetadataSource := p_MetadataSource_5e5901c2);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_c78c5cce UUID;
  p_IntegrationObjectID_c78c5cce UUID;
  p_Name_c78c5cce VARCHAR(255);
  p_DisplayName_c78c5cce VARCHAR(255);
  p_Description_c78c5cce TEXT;
  p_Category_c78c5cce VARCHAR(100);
  p_Type_c78c5cce VARCHAR(100);
  p_Length_c78c5cce INTEGER;
  p_Precision_c78c5cce INTEGER;
  p_Scale_c78c5cce INTEGER;
  p_AllowsNull_c78c5cce BOOLEAN;
  p_DefaultValue_c78c5cce VARCHAR(255);
  p_IsPrimaryKey_c78c5cce BOOLEAN;
  p_IsUniqueKey_c78c5cce BOOLEAN;
  p_IsReadOnly_c78c5cce BOOLEAN;
  p_IsRequired_c78c5cce BOOLEAN;
  p_RelatedIntegrationObjectID_c78c5cce UUID;
  p_RelatedIntegrationObjectFieldName_c78c5cce VARCHAR(255);
  p_Sequence_c78c5cce INTEGER;
  p_Configuration_c78c5cce TEXT;
  p_Status_c78c5cce VARCHAR(25);
  p_IsCustom_c78c5cce BOOLEAN;
  p_MetadataSource_c78c5cce VARCHAR(20);
BEGIN
  p_ID_c78c5cce := 'D0994D38-E245-5619-A036-E0A903D9A408';
  p_IntegrationObjectID_c78c5cce := '224D74C1-460F-5612-BD7D-29027DF76792';
  p_Name_c78c5cce := 'source-orcid';
  p_DisplayName_c78c5cce := 'Source Orcid';
  p_Description_c78c5cce := 'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.';
  p_Type_c78c5cce := 'String';
  p_Length_c78c5cce := 19;
  p_AllowsNull_c78c5cce := TRUE;
  p_IsPrimaryKey_c78c5cce := FALSE;
  p_IsUniqueKey_c78c5cce := FALSE;
  p_IsReadOnly_c78c5cce := TRUE;
  p_IsRequired_c78c5cce := FALSE;
  p_Sequence_c78c5cce := 9;
  p_Status_c78c5cce := 'Active';
  p_IsCustom_c78c5cce := FALSE;
  p_MetadataSource_c78c5cce := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_c78c5cce, p_IntegrationObjectID := p_IntegrationObjectID_c78c5cce, p_Name := p_Name_c78c5cce, p_DisplayName := p_DisplayName_c78c5cce, p_Description := p_Description_c78c5cce, p_Category := p_Category_c78c5cce, p_Category_Clear := TRUE, p_Type := p_Type_c78c5cce, p_Length := p_Length_c78c5cce, p_Precision := p_Precision_c78c5cce, p_Precision_Clear := TRUE, p_Scale := p_Scale_c78c5cce, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_c78c5cce, p_DefaultValue := p_DefaultValue_c78c5cce, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_c78c5cce, p_IsUniqueKey := p_IsUniqueKey_c78c5cce, p_IsReadOnly := p_IsReadOnly_c78c5cce, p_IsRequired := p_IsRequired_c78c5cce, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_c78c5cce, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_c78c5cce, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_c78c5cce, p_Configuration := p_Configuration_c78c5cce, p_Configuration_Clear := TRUE, p_Status := p_Status_c78c5cce, p_IsCustom := p_IsCustom_c78c5cce, p_MetadataSource := p_MetadataSource_c78c5cce);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_b93eac66 UUID;
  p_IntegrationObjectID_b93eac66 UUID;
  p_Name_b93eac66 VARCHAR(255);
  p_DisplayName_b93eac66 VARCHAR(255);
  p_Description_b93eac66 TEXT;
  p_Category_b93eac66 VARCHAR(100);
  p_Type_b93eac66 VARCHAR(100);
  p_Length_b93eac66 INTEGER;
  p_Precision_b93eac66 INTEGER;
  p_Scale_b93eac66 INTEGER;
  p_AllowsNull_b93eac66 BOOLEAN;
  p_DefaultValue_b93eac66 VARCHAR(255);
  p_IsPrimaryKey_b93eac66 BOOLEAN;
  p_IsUniqueKey_b93eac66 BOOLEAN;
  p_IsReadOnly_b93eac66 BOOLEAN;
  p_IsRequired_b93eac66 BOOLEAN;
  p_RelatedIntegrationObjectID_b93eac66 UUID;
  p_RelatedIntegrationObjectFieldName_b93eac66 VARCHAR(255);
  p_Sequence_b93eac66 INTEGER;
  p_Configuration_b93eac66 TEXT;
  p_Status_b93eac66 VARCHAR(25);
  p_IsCustom_b93eac66 BOOLEAN;
  p_MetadataSource_b93eac66 VARCHAR(20);
BEGIN
  p_ID_b93eac66 := '31E00E1E-0FDF-5D23-8BF0-2A428704FF41';
  p_IntegrationObjectID_b93eac66 := '224D74C1-460F-5612-BD7D-29027DF76792';
  p_Name_b93eac66 := 'external-id-type';
  p_DisplayName_b93eac66 := 'External Id Type';
  p_Description_b93eac66 := 'The identifying system (e.g. Scopus Author ID).';
  p_Type_b93eac66 := 'String';
  p_Length_b93eac66 := 255;
  p_AllowsNull_b93eac66 := TRUE;
  p_IsPrimaryKey_b93eac66 := FALSE;
  p_IsUniqueKey_b93eac66 := FALSE;
  p_IsReadOnly_b93eac66 := TRUE;
  p_IsRequired_b93eac66 := FALSE;
  p_Sequence_b93eac66 := 10;
  p_Status_b93eac66 := 'Active';
  p_IsCustom_b93eac66 := FALSE;
  p_MetadataSource_b93eac66 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_b93eac66, p_IntegrationObjectID := p_IntegrationObjectID_b93eac66, p_Name := p_Name_b93eac66, p_DisplayName := p_DisplayName_b93eac66, p_Description := p_Description_b93eac66, p_Category := p_Category_b93eac66, p_Category_Clear := TRUE, p_Type := p_Type_b93eac66, p_Length := p_Length_b93eac66, p_Precision := p_Precision_b93eac66, p_Precision_Clear := TRUE, p_Scale := p_Scale_b93eac66, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_b93eac66, p_DefaultValue := p_DefaultValue_b93eac66, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_b93eac66, p_IsUniqueKey := p_IsUniqueKey_b93eac66, p_IsReadOnly := p_IsReadOnly_b93eac66, p_IsRequired := p_IsRequired_b93eac66, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_b93eac66, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_b93eac66, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_b93eac66, p_Configuration := p_Configuration_b93eac66, p_Configuration_Clear := TRUE, p_Status := p_Status_b93eac66, p_IsCustom := p_IsCustom_b93eac66, p_MetadataSource := p_MetadataSource_b93eac66);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_afd978a7 UUID;
  p_IntegrationObjectID_afd978a7 UUID;
  p_Name_afd978a7 VARCHAR(255);
  p_DisplayName_afd978a7 VARCHAR(255);
  p_Description_afd978a7 TEXT;
  p_Category_afd978a7 VARCHAR(100);
  p_Type_afd978a7 VARCHAR(100);
  p_Length_afd978a7 INTEGER;
  p_Precision_afd978a7 INTEGER;
  p_Scale_afd978a7 INTEGER;
  p_AllowsNull_afd978a7 BOOLEAN;
  p_DefaultValue_afd978a7 VARCHAR(255);
  p_IsPrimaryKey_afd978a7 BOOLEAN;
  p_IsUniqueKey_afd978a7 BOOLEAN;
  p_IsReadOnly_afd978a7 BOOLEAN;
  p_IsRequired_afd978a7 BOOLEAN;
  p_RelatedIntegrationObjectID_afd978a7 UUID;
  p_RelatedIntegrationObjectFieldName_afd978a7 VARCHAR(255);
  p_Sequence_afd978a7 INTEGER;
  p_Configuration_afd978a7 TEXT;
  p_Status_afd978a7 VARCHAR(25);
  p_IsCustom_afd978a7 BOOLEAN;
  p_MetadataSource_afd978a7 VARCHAR(20);
BEGIN
  p_ID_afd978a7 := '41EF3A81-3CD5-517D-B8E1-98FD38DEA160';
  p_IntegrationObjectID_afd978a7 := '224D74C1-460F-5612-BD7D-29027DF76792';
  p_Name_afd978a7 := 'external-id-value';
  p_DisplayName_afd978a7 := 'External Id Value';
  p_Description_afd978a7 := 'The identifier value.';
  p_Type_afd978a7 := 'String';
  p_Length_afd978a7 := 500;
  p_AllowsNull_afd978a7 := TRUE;
  p_IsPrimaryKey_afd978a7 := FALSE;
  p_IsUniqueKey_afd978a7 := FALSE;
  p_IsReadOnly_afd978a7 := TRUE;
  p_IsRequired_afd978a7 := FALSE;
  p_Sequence_afd978a7 := 11;
  p_Status_afd978a7 := 'Active';
  p_IsCustom_afd978a7 := FALSE;
  p_MetadataSource_afd978a7 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_afd978a7, p_IntegrationObjectID := p_IntegrationObjectID_afd978a7, p_Name := p_Name_afd978a7, p_DisplayName := p_DisplayName_afd978a7, p_Description := p_Description_afd978a7, p_Category := p_Category_afd978a7, p_Category_Clear := TRUE, p_Type := p_Type_afd978a7, p_Length := p_Length_afd978a7, p_Precision := p_Precision_afd978a7, p_Precision_Clear := TRUE, p_Scale := p_Scale_afd978a7, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_afd978a7, p_DefaultValue := p_DefaultValue_afd978a7, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_afd978a7, p_IsUniqueKey := p_IsUniqueKey_afd978a7, p_IsReadOnly := p_IsReadOnly_afd978a7, p_IsRequired := p_IsRequired_afd978a7, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_afd978a7, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_afd978a7, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_afd978a7, p_Configuration := p_Configuration_afd978a7, p_Configuration_Clear := TRUE, p_Status := p_Status_afd978a7, p_IsCustom := p_IsCustom_afd978a7, p_MetadataSource := p_MetadataSource_afd978a7);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_7a033b4b UUID;
  p_IntegrationObjectID_7a033b4b UUID;
  p_Name_7a033b4b VARCHAR(255);
  p_DisplayName_7a033b4b VARCHAR(255);
  p_Description_7a033b4b TEXT;
  p_Category_7a033b4b VARCHAR(100);
  p_Type_7a033b4b VARCHAR(100);
  p_Length_7a033b4b INTEGER;
  p_Precision_7a033b4b INTEGER;
  p_Scale_7a033b4b INTEGER;
  p_AllowsNull_7a033b4b BOOLEAN;
  p_DefaultValue_7a033b4b VARCHAR(255);
  p_IsPrimaryKey_7a033b4b BOOLEAN;
  p_IsUniqueKey_7a033b4b BOOLEAN;
  p_IsReadOnly_7a033b4b BOOLEAN;
  p_IsRequired_7a033b4b BOOLEAN;
  p_RelatedIntegrationObjectID_7a033b4b UUID;
  p_RelatedIntegrationObjectFieldName_7a033b4b VARCHAR(255);
  p_Sequence_7a033b4b INTEGER;
  p_Configuration_7a033b4b TEXT;
  p_Status_7a033b4b VARCHAR(25);
  p_IsCustom_7a033b4b BOOLEAN;
  p_MetadataSource_7a033b4b VARCHAR(20);
BEGIN
  p_ID_7a033b4b := '6551DDA2-C1A2-5EF4-B31A-457BE84DC68D';
  p_IntegrationObjectID_7a033b4b := '224D74C1-460F-5612-BD7D-29027DF76792';
  p_Name_7a033b4b := 'external-id-url';
  p_DisplayName_7a033b4b := 'External Id Url';
  p_Description_7a033b4b := 'Link to the profile on that system.';
  p_Type_7a033b4b := 'String';
  p_Length_7a033b4b := 2048;
  p_AllowsNull_7a033b4b := TRUE;
  p_IsPrimaryKey_7a033b4b := FALSE;
  p_IsUniqueKey_7a033b4b := FALSE;
  p_IsReadOnly_7a033b4b := TRUE;
  p_IsRequired_7a033b4b := FALSE;
  p_Sequence_7a033b4b := 12;
  p_Status_7a033b4b := 'Active';
  p_IsCustom_7a033b4b := FALSE;
  p_MetadataSource_7a033b4b := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_7a033b4b, p_IntegrationObjectID := p_IntegrationObjectID_7a033b4b, p_Name := p_Name_7a033b4b, p_DisplayName := p_DisplayName_7a033b4b, p_Description := p_Description_7a033b4b, p_Category := p_Category_7a033b4b, p_Category_Clear := TRUE, p_Type := p_Type_7a033b4b, p_Length := p_Length_7a033b4b, p_Precision := p_Precision_7a033b4b, p_Precision_Clear := TRUE, p_Scale := p_Scale_7a033b4b, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_7a033b4b, p_DefaultValue := p_DefaultValue_7a033b4b, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_7a033b4b, p_IsUniqueKey := p_IsUniqueKey_7a033b4b, p_IsReadOnly := p_IsReadOnly_7a033b4b, p_IsRequired := p_IsRequired_7a033b4b, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_7a033b4b, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_7a033b4b, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_7a033b4b, p_Configuration := p_Configuration_7a033b4b, p_Configuration_Clear := TRUE, p_Status := p_Status_7a033b4b, p_IsCustom := p_IsCustom_7a033b4b, p_MetadataSource := p_MetadataSource_7a033b4b);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_8adcaf33 UUID;
  p_IntegrationObjectID_8adcaf33 UUID;
  p_Name_8adcaf33 VARCHAR(255);
  p_DisplayName_8adcaf33 VARCHAR(255);
  p_Description_8adcaf33 TEXT;
  p_Category_8adcaf33 VARCHAR(100);
  p_Type_8adcaf33 VARCHAR(100);
  p_Length_8adcaf33 INTEGER;
  p_Precision_8adcaf33 INTEGER;
  p_Scale_8adcaf33 INTEGER;
  p_AllowsNull_8adcaf33 BOOLEAN;
  p_DefaultValue_8adcaf33 VARCHAR(255);
  p_IsPrimaryKey_8adcaf33 BOOLEAN;
  p_IsUniqueKey_8adcaf33 BOOLEAN;
  p_IsReadOnly_8adcaf33 BOOLEAN;
  p_IsRequired_8adcaf33 BOOLEAN;
  p_RelatedIntegrationObjectID_8adcaf33 UUID;
  p_RelatedIntegrationObjectFieldName_8adcaf33 VARCHAR(255);
  p_Sequence_8adcaf33 INTEGER;
  p_Configuration_8adcaf33 TEXT;
  p_Status_8adcaf33 VARCHAR(25);
  p_IsCustom_8adcaf33 BOOLEAN;
  p_MetadataSource_8adcaf33 VARCHAR(20);
BEGIN
  p_ID_8adcaf33 := 'E0D65254-061E-583D-B5C5-A38A1EA938EC';
  p_IntegrationObjectID_8adcaf33 := '224D74C1-460F-5612-BD7D-29027DF76792';
  p_Name_8adcaf33 := 'external-id-relationship';
  p_DisplayName_8adcaf33 := 'External Id Relationship';
  p_Description_8adcaf33 := 'Whether the id identifies this person (self) or a related record.';
  p_Type_8adcaf33 := 'String';
  p_Length_8adcaf33 := 50;
  p_AllowsNull_8adcaf33 := TRUE;
  p_IsPrimaryKey_8adcaf33 := FALSE;
  p_IsUniqueKey_8adcaf33 := FALSE;
  p_IsReadOnly_8adcaf33 := TRUE;
  p_IsRequired_8adcaf33 := FALSE;
  p_Sequence_8adcaf33 := 13;
  p_Status_8adcaf33 := 'Active';
  p_IsCustom_8adcaf33 := FALSE;
  p_MetadataSource_8adcaf33 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_8adcaf33, p_IntegrationObjectID := p_IntegrationObjectID_8adcaf33, p_Name := p_Name_8adcaf33, p_DisplayName := p_DisplayName_8adcaf33, p_Description := p_Description_8adcaf33, p_Category := p_Category_8adcaf33, p_Category_Clear := TRUE, p_Type := p_Type_8adcaf33, p_Length := p_Length_8adcaf33, p_Precision := p_Precision_8adcaf33, p_Precision_Clear := TRUE, p_Scale := p_Scale_8adcaf33, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_8adcaf33, p_DefaultValue := p_DefaultValue_8adcaf33, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_8adcaf33, p_IsUniqueKey := p_IsUniqueKey_8adcaf33, p_IsReadOnly := p_IsReadOnly_8adcaf33, p_IsRequired := p_IsRequired_8adcaf33, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_8adcaf33, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_8adcaf33, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_8adcaf33, p_Configuration := p_Configuration_8adcaf33, p_Configuration_Clear := TRUE, p_Status := p_Status_8adcaf33, p_IsCustom := p_IsCustom_8adcaf33, p_MetadataSource := p_MetadataSource_8adcaf33);
END $mj$;
