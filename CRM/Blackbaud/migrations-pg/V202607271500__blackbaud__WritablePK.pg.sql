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

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = TRUE,
    "IsUniqueKey" = TRUE,
    "IsRequired" = TRUE,
    "AllowsNull" = FALSE
WHERE "Name" = 'constituent_id'
  AND "IntegrationObjectID" IN (
      SELECT o."ID"
      FROM "__mj"."IntegrationObject" o
      INNER JOIN "__mj"."Integration" i ON i."ID" = o."IntegrationID"
      WHERE i."Name" = 'blackbaud'
        AND o."Name" = 'profile_picture'
  );

-- ── 2. acknowledgement.acknowledgement_id ────────────────────────────────────

DO $mj$
DECLARE
  p_ID_94137487 UUID;
  p_IntegrationObjectID_94137487 UUID;
  p_Name_94137487 VARCHAR(255);
  p_DisplayName_94137487 VARCHAR(255);
  p_Description_94137487 TEXT;
  p_Category_94137487 VARCHAR(100);
  p_Type_94137487 VARCHAR(100);
  p_Length_94137487 INTEGER;
  p_Precision_94137487 INTEGER;
  p_Scale_94137487 INTEGER;
  p_AllowsNull_94137487 BOOLEAN;
  p_DefaultValue_94137487 VARCHAR(255);
  p_IsPrimaryKey_94137487 BOOLEAN;
  p_IsUniqueKey_94137487 BOOLEAN;
  p_IsReadOnly_94137487 BOOLEAN;
  p_IsRequired_94137487 BOOLEAN;
  p_RelatedIntegrationObjectID_94137487 UUID;
  p_RelatedIntegrationObjectFieldName_94137487 VARCHAR(255);
  p_Sequence_94137487 INTEGER;
  p_Configuration_94137487 TEXT;
  p_Status_94137487 VARCHAR(25);
  p_IsCustom_94137487 BOOLEAN;
  p_MetadataSource_94137487 VARCHAR(20);
BEGIN
  p_ID_94137487 := 'C5DA0A51-0A39-5FAB-916D-C0C107B4BAE1';
  p_IntegrationObjectID_94137487 := '44CA012B-15D2-46B1-B95B-FB2BF8724505';
  p_Name_94137487 := 'acknowledgement_id';
  p_DisplayName_94137487 := 'Acknowledgement Id';
  p_Description_94137487 := 'The gift acknowledgement''s identifier. Blackbaud''s SKY Gift API addresses the resource as PATCH /giftacknowledgements/{acknowledgement_id} (changelog 2019-01-24, "Gift Acknowledgement (Edit)"), so the path variable is the record key. The catalog previously declared only the editable body — date, letter, status — which carries no identifier.';
  p_Type_94137487 := 'String';
  p_AllowsNull_94137487 := FALSE;
  p_IsPrimaryKey_94137487 := TRUE;
  p_IsUniqueKey_94137487 := TRUE;
  p_IsReadOnly_94137487 := TRUE;
  p_IsRequired_94137487 := TRUE;
  p_Sequence_94137487 := 4;
  p_Status_94137487 := 'Active';
  p_IsCustom_94137487 := FALSE;
  p_MetadataSource_94137487 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_94137487, p_IntegrationObjectID := p_IntegrationObjectID_94137487, p_Name := p_Name_94137487, p_DisplayName := p_DisplayName_94137487, p_Description := p_Description_94137487, p_Category := p_Category_94137487, p_Category_Clear := TRUE, p_Type := p_Type_94137487, p_Length := p_Length_94137487, p_Length_Clear := TRUE, p_Precision := p_Precision_94137487, p_Precision_Clear := TRUE, p_Scale := p_Scale_94137487, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_94137487, p_DefaultValue := p_DefaultValue_94137487, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_94137487, p_IsUniqueKey := p_IsUniqueKey_94137487, p_IsReadOnly := p_IsReadOnly_94137487, p_IsRequired := p_IsRequired_94137487, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_94137487, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_94137487, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_94137487, p_Configuration := p_Configuration_94137487, p_Configuration_Clear := TRUE, p_Status := p_Status_94137487, p_IsCustom := p_IsCustom_94137487, p_MetadataSource := p_MetadataSource_94137487);
END $mj$;

-- ── 3. receipt.receipt_id ────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_cbef5d09 UUID;
  p_IntegrationObjectID_cbef5d09 UUID;
  p_Name_cbef5d09 VARCHAR(255);
  p_DisplayName_cbef5d09 VARCHAR(255);
  p_Description_cbef5d09 TEXT;
  p_Category_cbef5d09 VARCHAR(100);
  p_Type_cbef5d09 VARCHAR(100);
  p_Length_cbef5d09 INTEGER;
  p_Precision_cbef5d09 INTEGER;
  p_Scale_cbef5d09 INTEGER;
  p_AllowsNull_cbef5d09 BOOLEAN;
  p_DefaultValue_cbef5d09 VARCHAR(255);
  p_IsPrimaryKey_cbef5d09 BOOLEAN;
  p_IsUniqueKey_cbef5d09 BOOLEAN;
  p_IsReadOnly_cbef5d09 BOOLEAN;
  p_IsRequired_cbef5d09 BOOLEAN;
  p_RelatedIntegrationObjectID_cbef5d09 UUID;
  p_RelatedIntegrationObjectFieldName_cbef5d09 VARCHAR(255);
  p_Sequence_cbef5d09 INTEGER;
  p_Configuration_cbef5d09 TEXT;
  p_Status_cbef5d09 VARCHAR(25);
  p_IsCustom_cbef5d09 BOOLEAN;
  p_MetadataSource_cbef5d09 VARCHAR(20);
BEGIN
  p_ID_cbef5d09 := '448779BF-FC7C-5F61-AA92-5BFF4312930F';
  p_IntegrationObjectID_cbef5d09 := 'BCC9E0E6-7476-4E0B-B251-E4C92F3939D6';
  p_Name_cbef5d09 := 'receipt_id';
  p_DisplayName_cbef5d09 := 'Receipt Id';
  p_Description_cbef5d09 := 'The gift receipt''s identifier. Blackbaud''s SKY Gift API addresses the resource as PATCH /giftreceipts/{receipt_id} (changelog 2019-01-16, "Gift Receipt (Edit)"), so the path variable is the record key. The catalog previously declared only the editable body — amount, date, number, status — which carries no identifier.';
  p_Type_cbef5d09 := 'String';
  p_AllowsNull_cbef5d09 := FALSE;
  p_IsPrimaryKey_cbef5d09 := TRUE;
  p_IsUniqueKey_cbef5d09 := TRUE;
  p_IsReadOnly_cbef5d09 := TRUE;
  p_IsRequired_cbef5d09 := TRUE;
  p_Sequence_cbef5d09 := 5;
  p_Status_cbef5d09 := 'Active';
  p_IsCustom_cbef5d09 := FALSE;
  p_MetadataSource_cbef5d09 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_cbef5d09, p_IntegrationObjectID := p_IntegrationObjectID_cbef5d09, p_Name := p_Name_cbef5d09, p_DisplayName := p_DisplayName_cbef5d09, p_Description := p_Description_cbef5d09, p_Category := p_Category_cbef5d09, p_Category_Clear := TRUE, p_Type := p_Type_cbef5d09, p_Length := p_Length_cbef5d09, p_Length_Clear := TRUE, p_Precision := p_Precision_cbef5d09, p_Precision_Clear := TRUE, p_Scale := p_Scale_cbef5d09, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_cbef5d09, p_DefaultValue := p_DefaultValue_cbef5d09, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_cbef5d09, p_IsUniqueKey := p_IsUniqueKey_cbef5d09, p_IsReadOnly := p_IsReadOnly_cbef5d09, p_IsRequired := p_IsRequired_cbef5d09, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_cbef5d09, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_cbef5d09, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_cbef5d09, p_Configuration := p_Configuration_cbef5d09, p_Configuration_Clear := TRUE, p_Status := p_Status_cbef5d09, p_IsCustom := p_IsCustom_cbef5d09, p_MetadataSource := p_MetadataSource_cbef5d09);
END $mj$;

-- ── 4. gift_note.id ──────────────────────────────────────────────────────────
DO $mj$
DECLARE
  p_ID_80c192e3 UUID;
  p_IntegrationObjectID_80c192e3 UUID;
  p_Name_80c192e3 VARCHAR(255);
  p_DisplayName_80c192e3 VARCHAR(255);
  p_Description_80c192e3 TEXT;
  p_Category_80c192e3 VARCHAR(100);
  p_Type_80c192e3 VARCHAR(100);
  p_Length_80c192e3 INTEGER;
  p_Precision_80c192e3 INTEGER;
  p_Scale_80c192e3 INTEGER;
  p_AllowsNull_80c192e3 BOOLEAN;
  p_DefaultValue_80c192e3 VARCHAR(255);
  p_IsPrimaryKey_80c192e3 BOOLEAN;
  p_IsUniqueKey_80c192e3 BOOLEAN;
  p_IsReadOnly_80c192e3 BOOLEAN;
  p_IsRequired_80c192e3 BOOLEAN;
  p_RelatedIntegrationObjectID_80c192e3 UUID;
  p_RelatedIntegrationObjectFieldName_80c192e3 VARCHAR(255);
  p_Sequence_80c192e3 INTEGER;
  p_Configuration_80c192e3 TEXT;
  p_Status_80c192e3 VARCHAR(25);
  p_IsCustom_80c192e3 BOOLEAN;
  p_MetadataSource_80c192e3 VARCHAR(20);
BEGIN
  p_ID_80c192e3 := '35262A26-FAE5-53AF-AEE3-BB3F94BC9036';
  p_IntegrationObjectID_80c192e3 := 'CC55644D-C3C0-4062-836A-38CAB400907A';
  p_Name_80c192e3 := 'id';
  p_DisplayName_80c192e3 := 'Id';
  p_Description_80c192e3 := 'The gift note''s identifier. Blackbaud publishes GetGiftNoteById / EditGiftNote / DeleteGiftNote against the item resource, and this connector already addresses it as /nxt-data-integration/v1/re/gifts/notes/{id} — the path variable is the record key. Mirrors the sibling `note` object, which is keyed on `id` with the same collection-POST / item-PATCH shape.';
  p_Type_80c192e3 := 'INTEGER';
  p_AllowsNull_80c192e3 := FALSE;
  p_IsPrimaryKey_80c192e3 := TRUE;
  p_IsUniqueKey_80c192e3 := TRUE;
  p_IsReadOnly_80c192e3 := TRUE;
  p_IsRequired_80c192e3 := TRUE;
  p_Sequence_80c192e3 := 7;
  p_Status_80c192e3 := 'Active';
  p_IsCustom_80c192e3 := FALSE;
  p_MetadataSource_80c192e3 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_80c192e3, p_IntegrationObjectID := p_IntegrationObjectID_80c192e3, p_Name := p_Name_80c192e3, p_DisplayName := p_DisplayName_80c192e3, p_Description := p_Description_80c192e3, p_Category := p_Category_80c192e3, p_Category_Clear := TRUE, p_Type := p_Type_80c192e3, p_Length := p_Length_80c192e3, p_Length_Clear := TRUE, p_Precision := p_Precision_80c192e3, p_Precision_Clear := TRUE, p_Scale := p_Scale_80c192e3, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_80c192e3, p_DefaultValue := p_DefaultValue_80c192e3, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_80c192e3, p_IsUniqueKey := p_IsUniqueKey_80c192e3, p_IsReadOnly := p_IsReadOnly_80c192e3, p_IsRequired := p_IsRequired_80c192e3, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_80c192e3, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_80c192e3, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_80c192e3, p_Configuration := p_Configuration_80c192e3, p_Configuration_Clear := TRUE, p_Status := p_Status_80c192e3, p_IsCustom := p_IsCustom_80c192e3, p_MetadataSource := p_MetadataSource_80c192e3);
END $mj$;

-- MANUAL CORRECTION (do not "fix" by regenerating — the converter reintroduces the bug).
-- @memberjunction/sql-converter's CoreMetadataBooleanColumns declares
--     IntegrationObject: ['SupportsPagination', 'SupportsIncrementalSync', 'SupportsWrite', 'IsCustom']
-- The per-operation CRUD columns SupportsCreate / SupportsUpdate / SupportsDelete were added to the
-- table later and never added to that list, so a bare UPDATE on them converts to `= 1` / `= 0`
-- against a PG BOOLEAN column and fails with
--     column "SupportsCreate" is of type boolean but expression is of type integer
-- (SupportsWrite in the same statement converts correctly, which is why this is easy to miss.) The
-- three literals below were corrected to TRUE/FALSE by hand. build-pg-migrations.mjs only regenerates
-- a .pg.sql that is MISSING, so this file is stable; the converter gap is being fixed upstream.
UPDATE "__mj"."IntegrationObject"
SET "CreateAPIPath"  = '/nxt-data-integration/v1/re/giftaid/taxdeclarations',
    "CreateMethod"   = 'POST',
    "SupportsCreate" = TRUE
WHERE "ID" = 'E8D9A215-D5DD-4E90-A4C2-A016EBA12F8F';

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "SupportsCreate" = FALSE,
    "Description"    = 'Blackbaud RENXT NXTDataIntegration — NewTaxDeclaration Request-body shape, not a record: this is the POST payload for the vendor''s CreateTaxDeclaration operation (v1/re/giftaid/taxdeclarations) and its fields are a strict subset of the tax_declaration resource. It has no identifier and no GET. The create capability now lives on tax_declaration, which is keyed on declaration_id and already owns the edit path.'
WHERE "ID" = '064BB861-0996-468A-A79D-D4D56A3831F3';

-- ── 6. non_constituent_conversion: an unkeyed command, not a record ──────────────

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "SupportsCreate" = FALSE,
    "Description"    = 'The non-constituent conversion object holds constituent codes to apply during the conversion. Unkeyed command, not a record: the SKY Constituent API operation ConvertToConstituent (/convert/{contact_id}) converts an existing non-constituent into a constituent. No "conversion" resource is stored or returned and there is no GET — the result is a constituent, already modelled and keyed on `id` by this catalog. The object declared only the request body.'
WHERE "ID" = '6DDFFCD6-DE8F-4E6D-A27E-A58FE9F9EE27';


-- ===================== Other =====================

-- Blackbaud: the six writable objects that carried no primary key.
--
-- A writable IntegrationObject with no IsPrimaryKey field yields a KEYLESS derived entity. On
-- Postgres, MJ's save audit-wrapper then emits an empty record identifier and every save fails with
--     syntax error at or near ","
-- while fetch keeps succeeding — so the object reads green and persists nothing.
--
-- Each of the six gets the disposition its own vendor surface supports, never an invented key:
--
-- 1. profile_picture -> STAMP `constituent_id`.
--    The SKY Constituent API exposes GET and PATCH on /constituents/{constituentId}/profilepicture.
--    One picture per constituent, no item id anywhere — the constituent IS the identity, and it is
--    already a declared, populated field.
--
-- 2. acknowledgement -> CREATE `acknowledgement_id` (String).
--    SKY Gift API, changelog 2019-01-24 "Gift Acknowledgement (Edit)":
--    PATCH /giftacknowledgements/{acknowledgement_id}. The path variable names the key; the catalog
--    only ever declared the editable body (date, letter, status). String matches the other SKY Gift
--    API keys (gift.id, note.id, constituent.id).
--
-- 3. receipt -> CREATE `receipt_id` (String).
--    SKY Gift API, changelog 2019-01-16 "Gift Receipt (Edit)": PATCH /giftreceipts/{receipt_id}.
--    Same story — the catalog declared only amount/date/number/status.
--
-- 4. gift_note -> CREATE `id` (INTEGER).
--    Blackbaud publishes GetGiftNotes / CreateGiftNote / GetGiftNoteById / EditGiftNote /
--    DeleteGiftNote, and this connector already addresses the item as
--    /nxt-data-integration/v1/re/gifts/notes/{id}. INTEGER matches the neighbouring NXT Data Integration
--    gift objects. Mirrors the sibling `note` object exactly: collection POST, item PATCH, keyed on id.
--
-- 5. new_tax_declaration -> WITHDRAW the write; MOVE its create onto `tax_declaration`.
--    `new_tax_declaration` is the POST request-BODY shape — its 12 fields are a strict subset of
--    `tax_declaration`'s 16 — not a record: no identifier, no GET. The real resource is
--    `tax_declaration`, already keyed on declaration_id and already owning
--    GetTaxDeclaration / EditTaxDeclaration / DeleteTaxDeclaration. Rather than drop the capability,
--    CreateTaxDeclaration moves onto the keyed object, which is the shape the sibling `note` object
--    already uses.
--
-- 6. non_constituent_conversion -> WITHDRAW the write.
--    The Constituent API's ConvertToConstituent operation (/convert/{contact_id}) converts an existing
--    non-constituent INTO a constituent. Nothing named "conversion" is stored or returned — the result
--    is a constituent, which this catalog already models and keys on `id`. There is no identifier to
--    key on and the catalog declared only the request body (constituent_codes). Reads are unaffected.
--
-- Created keys are IsReadOnly = 1, matching HubSpot's V202607271200 stamp of `hs_object_id` across 33
-- objects (functionally proven on Postgres). Read-only does not stop a KEY persisting; the
-- "@courseid is not a parameter for procedure spCreateCourse_Contents" failure that Totara's
-- V202607271200 fixed was an ordinary read-only column, not a key.
--
-- DELTA migration, deliberately not a re-seed: the catalog rows already exist on installed tenants,
-- so the V202607051240 seed stays untouched and applied — no existing UUID is re-minted, no Flyway
-- checksum breaks, no UQ_IntegrationObject_Name collision. The UPDATEs are idempotent by WHERE. The
-- three created fields carry UUID5 IDs derived from
--     uuid5(DNS, 'memberjunction.integrations/<integration>/<object>/<field>')
-- so regenerating this file yields byte-identical UUIDs rather than fresh random ones.
--
-- NOTE: the Integration row is named 'blackbaud' (lowercase) — matching the seeded identity exactly.

-- ── 1. profile_picture: the constituent is the identity ──────────────────────

-- ── 5. move CreateTaxDeclaration onto the keyed tax_declaration, withdraw the body shape ──
