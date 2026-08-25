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

-- Business Central: address dimensionSetLines under a JOURNAL LINE as well as a sales order.
--
-- WHAT IS MISSING TODAY
--   `dimensionSetLines` is catalogued with a single parent:
--       /companies({id})/salesOrders({id})/dimensionSetLines
--   so dimensions can never be written to a journal line. Business Central supports it, the connector's
--   CreateRecord is fully generic (it resolves CreateAPIPath/CreateMethod off the IntegrationObject row),
--   and the resource's own `parentType` field description names "Journal Line" first among valid parents.
--   The catalog was the only thing in the way.
--
-- VERIFIED AGAINST A LIVE TENANT (Test environment, API v2.0, 2026-08-25)
--   BC's $metadata declares the navigation property on journalLine:
--       journalLine -> dimensionSetLines : Collection(dimensionSetLine)
--   and the path is live for both read and write:
--       GET  /companies({id})/journals({id})/journalLines({id})/dimensionSetLines  -> 200
--       POST (empty body)                                                            -> 400 BadRequest
--                                                                "Values must be provided in the body."
--   A 400 on payload validation, not a 405 on method. For contrast, the two objects that genuinely are
--   read-only answer differently and are correctly catalogued as such — they are NOT changed here:
--       POST /companies({id})/dimensions       -> 405 BadRequest_MethodNotAllowed
--       POST /companies({id})/dimensionValues  -> 405 BadRequest_MethodNotAllowed
--

-- WHY A SECOND OBJECT RATHER THAN A CHANGED PATH
--   UQ_IntegrationObject_Name is unique on (IntegrationID, Name), and the sales-order parent is in use, so
--   the journal-line access path needs its own row. `dimensionSetLine` is parent-polymorphic: BC navigates
--   to it from 24 EntityTypes, and `parentType` distinguishes them on the wire. This adds the one parent
--   that is blocking journal-entry export; the other 22 remain uncatalogued and are a modelling question
--   rather than a path correction — see the PR.
--
-- WRITTEN IN THE SEED MIGRATION'S OWN FORM, DELIBERATELY
--   This uses spCreateIntegrationObject / spCreateIntegrationObjectField, the same calls
--   V202608041723__business-central__Metadata emits, rather than raw INSERTs. Two reasons:
--     1. scripts/lint-catalog-completeness.mjs only recognises a seeded object through that sproc call, so
--        raw INSERTs read as "declared in the catalog but never shipped in a migration" and fail `validate`.
--     2. the sprocs apply the same defaulting and validation every other catalog row went through, so this
--        row cannot drift from the 83 around it.
--   The linter's own suggestion — regenerate the seed with scripts/build-seed-migrations.mjs — is NOT
--   applicable here: that script re-emits the whole catalog into a fresh Metadata migration, which would
--   supersede the published V202608041723 and change its Flyway checksum on every tenant that has already
--   run it. A delta migration is the only safe shape once a connector has shipped.
--
-- NO EXISTENCE GUARDS, AND THAT IS THE CORRECT CHOICE HERE
--   V202608240630__pheedloop__UnboundedText failed because it guarded on ID while the row it collided with
--   already existed under a different ID. The lesson was "guard on the constraint's real key", but the
--   prior condition is "only guard when a row can already be there". `journalLineDimensionSetLines` has
--   never been seeded by any migration or any catalog push, and its ten fields hang off an object ID that
--   does not yet exist, so nothing can collide and Flyway runs this exactly once per database.
--
-- IDS MATCH THE CATALOG
--   The object and field IDs below are the same GUIDs carried in
--   metadata/integration/.business-central.integration.json, so `mj sync` sees an already-current row
--   rather than a second copy of it.

DO $mj$
DECLARE
  p_ID_59a03914 UUID;
  p_IntegrationID_59a03914 UUID;
  p_Name_59a03914 VARCHAR(255);
  p_DisplayName_59a03914 VARCHAR(255);
  p_Description_59a03914 TEXT;
  p_Category_59a03914 VARCHAR(100);
  p_APIPath_59a03914 VARCHAR(500);
  p_ResponseDataKey_59a03914 VARCHAR(255);
  p_DefaultPageSize_59a03914 INTEGER;
  p_SupportsPagination_59a03914 BOOLEAN;
  p_PaginationType_59a03914 VARCHAR(20);
  p_SupportsIncrementalSync_59a03914 BOOLEAN;
  p_SupportsWrite_59a03914 BOOLEAN;
  p_DefaultQueryParams_59a03914 TEXT;
  p_Configuration_59a03914 TEXT;
  p_Sequence_59a03914 INTEGER;
  p_Status_59a03914 VARCHAR(25);
  p_WriteAPIPath_59a03914 VARCHAR(500);
  p_WriteMethod_59a03914 VARCHAR(10);
  p_DeleteMethod_59a03914 VARCHAR(10);
  p_IsCustom_59a03914 BOOLEAN;
  p_CreateAPIPath_59a03914 TEXT;
  p_CreateMethod_59a03914 VARCHAR(20);
  p_CreateBodyShape_59a03914 VARCHAR(50);
  p_CreateBodyKey_59a03914 VARCHAR(100);
  p_CreateIDLocation_59a03914 VARCHAR(20);
  p_UpdateAPIPath_59a03914 TEXT;
  p_UpdateMethod_59a03914 VARCHAR(20);
  p_UpdateBodyShape_59a03914 VARCHAR(50);
  p_UpdateBodyKey_59a03914 VARCHAR(100);
  p_UpdateIDLocation_59a03914 VARCHAR(20);
  p_DeleteAPIPath_59a03914 TEXT;
  p_DeleteIDLocation_59a03914 VARCHAR(20);
  p_IncrementalWatermarkField_59a03914 VARCHAR(255);
  p_MetadataSource_59a03914 VARCHAR(20);
  p_SupportsCreate_59a03914 BOOLEAN;
  p_SupportsUpdate_59a03914 BOOLEAN;
  p_SupportsDelete_59a03914 BOOLEAN;
  p_SyncStrategy_59a03914 VARCHAR(50);
  p_ContentHashApplicable_59a03914 BOOLEAN;
  p_StableOrderingKey_59a03914 VARCHAR(255);
BEGIN
  p_ID_59a03914 := '59A03914-49FE-46D1-AD42-317E043F5F52';
  p_IntegrationID_59a03914 := '3FD08940-E11D-4926-8149-6115F3B8ABF3';
  p_Name_59a03914 := 'journalLineDimensionSetLines';
  p_DisplayName_59a03914 := 'Journal Line Dimension Set Lines';
  p_Description_59a03914 := 'Dimension set lines addressed under a JOURNAL LINE. Business Central navigates dimensionSetLines from 24 parent types; the sibling `dimensionSetLines` object covers the sales-order parent and this one covers the journal line, so dimensions can be written to a journal entry. Same resource, different access path — `parentType` distinguishes them on the wire.';
  p_Category_59a03914 := 'journalLine children';
  p_APIPath_59a03914 := '/companies({id})/journals({id})/journalLines({id})/dimensionSetLines';
  p_ResponseDataKey_59a03914 := 'value';
  p_SupportsPagination_59a03914 := TRUE;
  p_PaginationType_59a03914 := 'Cursor';
  p_SupportsIncrementalSync_59a03914 := FALSE;
  p_SupportsWrite_59a03914 := TRUE;
  p_Configuration_59a03914 := '{
  "resourceType": "dimensionSetLine",
  "entitySet": "dimensionSetLines",
  "companyScoped": true,
  "accessPath": {
    "door": "companies",
    "nesting": "companies[] → journals[] → journalLines[] → dimensionSetLines[]",
    "doorArgs": [
      "companies({companyId}) path segment, or ?company=<companyGuid> query param"
    ],
    "depth": 3
  },
  "nestedAlternatePaths": [
    "/companies({id})/salesOrders({id})/dimensionSetLines({id})",
    "/companies({id})/journalLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesOrderLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesQuotes({id})/dimensionSetLines({id})",
    "/companies({id})/salesQuoteLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesCreditMemos({id})/dimensionSetLines({id})",
    "/companies({id})/salesCreditMemoLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesInvoices({id})/dimensionSetLines({id})",
    "/companies({id})/salesInvoiceLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesShipments({id})/dimensionSetLines({id})",
    "/companies({id})/salesShipmentLines({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseInvoices({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseInvoiceLines({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseReceipts({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseReceiptLines({id})/dimensionSetLines({id})",
    "/companies({id})/generalLedgerEntries({id})/dimensionSetLines({id})",
    "/companies({id})/timeRegistrationEntries({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseOrders({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseOrderLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesOrders({id})/dimensionSetLines({id})",
    "/companies({id})/journalLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesOrderLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesQuotes({id})/dimensionSetLines({id})",
    "/companies({id})/salesQuoteLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesCreditMemos({id})/dimensionSetLines({id})",
    "/companies({id})/salesCreditMemoLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesInvoices({id})/dimensionSetLines({id})",
    "/companies({id})/salesInvoiceLines({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseInvoices({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseInvoiceLines({id})/dimensionSetLines({id})",
    "/companies({id})/generalLedgerEntries({id})/dimensionSetLines({id})",
    "/companies({id})/timeRegistrationEntries({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseOrders({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseOrderLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesOrders({id})/dimensionSetLines({id})",
    "/companies({id})/journalLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesOrderLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesQuotes({id})/dimensionSetLines({id})",
    "/companies({id})/salesQuoteLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesCreditMemos({id})/dimensionSetLines({id})",
    "/companies({id})/salesCreditMemoLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesInvoices({id})/dimensionSetLines({id})",
    "/companies({id})/salesInvoiceLines({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseInvoices({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseInvoiceLines({id})/dimensionSetLines({id})",
    "/companies({id})/generalLedgerEntries({id})/dimensionSetLines({id})",
    "/companies({id})/timeRegistrationEntries({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseOrders({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseOrderLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesOrders({id})/dimensionSetLines({id})",
    "/companies({id})/journalLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesOrderLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesQuotes({id})/dimensionSetLines({id})",
    "/companies({id})/salesQuoteLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesCreditMemos({id})/dimensionSetLines({id})",
    "/companies({id})/salesCreditMemoLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesInvoices({id})/dimensionSetLines({id})",
    "/companies({id})/salesInvoiceLines({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseInvoices({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseInvoiceLines({id})/dimensionSetLines({id})",
    "/companies({id})/generalLedgerEntries({id})/dimensionSetLines({id})",
    "/companies({id})/timeRegistrationEntries({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseOrders({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseOrderLines({id})/dimensionSetLines({id})"
  ],
  "documentedPaths": [
    "/companies({id})/salesOrders({id})/dimensionSetLines({id})",
    "/companies({id})/journalLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesOrderLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesQuotes({id})/dimensionSetLines({id})",
    "/companies({id})/salesQuoteLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesCreditMemos({id})/dimensionSetLines({id})",
    "/companies({id})/salesCreditMemoLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesInvoices({id})/dimensionSetLines({id})",
    "/companies({id})/salesInvoiceLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesShipments({id})/dimensionSetLines({id})",
    "/companies({id})/salesShipmentLines({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseInvoices({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseInvoiceLines({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseReceipts({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseReceiptLines({id})/dimensionSetLines({id})",
    "/companies({id})/generalLedgerEntries({id})/dimensionSetLines({id})",
    "/companies({id})/timeRegistrationEntries({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseOrders({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseOrderLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesOrders({id})/dimensionSetLines({id})",
    "/companies({id})/journalLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesOrderLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesQuotes({id})/dimensionSetLines({id})",
    "/companies({id})/salesQuoteLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesCreditMemos({id})/dimensionSetLines({id})",
    "/companies({id})/salesCreditMemoLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesInvoices({id})/dimensionSetLines({id})",
    "/companies({id})/salesInvoiceLines({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseInvoices({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseInvoiceLines({id})/dimensionSetLines({id})",
    "/companies({id})/generalLedgerEntries({id})/dimensionSetLines({id})",
    "/companies({id})/timeRegistrationEntries({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseOrders({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseOrderLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesOrders({id})/dimensionSetLines({id})",
    "/companies({id})/journalLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesOrderLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesQuotes({id})/dimensionSetLines({id})",
    "/companies({id})/salesQuoteLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesCreditMemos({id})/dimensionSetLines({id})",
    "/companies({id})/salesCreditMemoLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesInvoices({id})/dimensionSetLines({id})",
    "/companies({id})/salesInvoiceLines({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseInvoices({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseInvoiceLines({id})/dimensionSetLines({id})",
    "/companies({id})/generalLedgerEntries({id})/dimensionSetLines({id})",
    "/companies({id})/timeRegistrationEntries({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseOrders({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseOrderLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesOrders({id})/dimensionSetLines({id})",
    "/companies({id})/journalLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesOrderLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesQuotes({id})/dimensionSetLines({id})",
    "/companies({id})/salesQuoteLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesCreditMemos({id})/dimensionSetLines({id})",
    "/companies({id})/salesCreditMemoLines({id})/dimensionSetLines({id})",
    "/companies({id})/salesInvoices({id})/dimensionSetLines({id})",
    "/companies({id})/salesInvoiceLines({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseInvoices({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseInvoiceLines({id})/dimensionSetLines({id})",
    "/companies({id})/generalLedgerEntries({id})/dimensionSetLines({id})",
    "/companies({id})/timeRegistrationEntries({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseOrders({id})/dimensionSetLines({id})",
    "/companies({id})/purchaseOrderLines({id})/dimensionSetLines({id})"
  ],
  "boundActions": [],
  "isMutable": true,
  "isAppendOnly": false,
  "paging": {
    "mechanism": "server-driven (continuation token)",
    "maxPageSizeOnline": 20000,
    "clientHint": "Prefer: odata.maxpagesize=<n>"
  },
  "watermarkFilterForm": null,
  "concurrencyHeader": "If-Match (ETag) required on PATCH/DELETE per OData concurrency; see resource operation pages",
  "sourceEvidence": {
    "resourcePage": "packages/Integration/connectors-registry/business-central/sources/ms-docs/bc-docs-repo/dev-itpro/api-reference/v2.0/resources/dynamics_dimensionSetLine.md",
    "operationPages": [
      "packages/Integration/connectors-registry/business-central/sources/ms-docs/bc-docs-repo/dev-itpro/api-reference/v2.0/api/dynamics_dimensionsetline_get.md",
      "packages/Integration/connectors-registry/business-central/sources/ms-docs/bc-docs-repo/dev-itpro/api-reference/v2.0/api/dynamics_dimensionsetline_delete.md",
      "packages/Integration/connectors-registry/business-central/sources/ms-docs/bc-docs-repo/dev-itpro/api-reference/v2.0/api/dynamics_dimensionsetline_create.md",
      "packages/Integration/connectors-registry/business-central/sources/ms-docs/bc-docs-repo/dev-itpro/api-reference/v2.0/api/dynamics_dimensionsetline_update.md"
    ]
  }
}';
  p_Sequence_59a03914 := 71;
  p_Status_59a03914 := 'Active';
  p_WriteMethod_59a03914 := 'POST';
  p_DeleteMethod_59a03914 := 'DELETE';
  p_IsCustom_59a03914 := FALSE;
  p_CreateAPIPath_59a03914 := '/companies({id})/journals({id})/journalLines({id})/dimensionSetLines';
  p_CreateMethod_59a03914 := 'POST';
  p_CreateBodyShape_59a03914 := 'flat';
  p_CreateIDLocation_59a03914 := 'body';
  p_UpdateAPIPath_59a03914 := '/companies({id})/journals({id})/journalLines({id})/dimensionSetLines({id})';
  p_UpdateMethod_59a03914 := 'PATCH';
  p_UpdateBodyShape_59a03914 := 'flat';
  p_UpdateIDLocation_59a03914 := 'path';
  p_DeleteAPIPath_59a03914 := '/companies({id})/journals({id})/journalLines({id})/dimensionSetLines({id})';
  p_DeleteIDLocation_59a03914 := 'path';
  p_MetadataSource_59a03914 := 'Declared';
  p_SupportsCreate_59a03914 := TRUE;
  p_SupportsUpdate_59a03914 := TRUE;
  p_SupportsDelete_59a03914 := TRUE;
  p_SyncStrategy_59a03914 := 'FullPullHashDiff';
  p_ContentHashApplicable_59a03914 := TRUE;
  p_StableOrderingKey_59a03914 := 'id';
  PERFORM __mj."spCreateIntegrationObject"(p_ID := p_ID_59a03914, p_IntegrationID := p_IntegrationID_59a03914, p_Name := p_Name_59a03914, p_DisplayName := p_DisplayName_59a03914, p_Description := p_Description_59a03914, p_Category := p_Category_59a03914, p_APIPath := p_APIPath_59a03914, p_ResponseDataKey := p_ResponseDataKey_59a03914, p_DefaultPageSize := p_DefaultPageSize_59a03914, p_SupportsPagination := p_SupportsPagination_59a03914, p_PaginationType := p_PaginationType_59a03914, p_SupportsIncrementalSync := p_SupportsIncrementalSync_59a03914, p_SupportsWrite := p_SupportsWrite_59a03914, p_DefaultQueryParams := p_DefaultQueryParams_59a03914, p_DefaultQueryParams_Clear := TRUE, p_Configuration := p_Configuration_59a03914, p_Sequence := p_Sequence_59a03914, p_Status := p_Status_59a03914, p_WriteAPIPath := p_WriteAPIPath_59a03914, p_WriteAPIPath_Clear := TRUE, p_WriteMethod := p_WriteMethod_59a03914, p_DeleteMethod := p_DeleteMethod_59a03914, p_IsCustom := p_IsCustom_59a03914, p_CreateAPIPath := p_CreateAPIPath_59a03914, p_CreateMethod := p_CreateMethod_59a03914, p_CreateBodyShape := p_CreateBodyShape_59a03914, p_CreateBodyKey := p_CreateBodyKey_59a03914, p_CreateBodyKey_Clear := TRUE, p_CreateIDLocation := p_CreateIDLocation_59a03914, p_UpdateAPIPath := p_UpdateAPIPath_59a03914, p_UpdateMethod := p_UpdateMethod_59a03914, p_UpdateBodyShape := p_UpdateBodyShape_59a03914, p_UpdateBodyKey := p_UpdateBodyKey_59a03914, p_UpdateBodyKey_Clear := TRUE, p_UpdateIDLocation := p_UpdateIDLocation_59a03914, p_DeleteAPIPath := p_DeleteAPIPath_59a03914, p_DeleteIDLocation := p_DeleteIDLocation_59a03914, p_IncrementalWatermarkField := p_IncrementalWatermarkField_59a03914, p_MetadataSource := p_MetadataSource_59a03914, p_SupportsCreate := p_SupportsCreate_59a03914, p_SupportsUpdate := p_SupportsUpdate_59a03914, p_SupportsDelete := p_SupportsDelete_59a03914, p_SyncStrategy := p_SyncStrategy_59a03914, p_ContentHashApplicable := p_ContentHashApplicable_59a03914, p_StableOrderingKey := p_StableOrderingKey_59a03914);
END $mj$;

DO $mj$
DECLARE
  p_ID_01ec715e UUID;
  p_IntegrationObjectID_01ec715e UUID;
  p_Name_01ec715e VARCHAR(255);
  p_DisplayName_01ec715e VARCHAR(255);
  p_Description_01ec715e TEXT;
  p_Category_01ec715e VARCHAR(100);
  p_Type_01ec715e VARCHAR(100);
  p_Length_01ec715e INTEGER;
  p_Precision_01ec715e INTEGER;
  p_Scale_01ec715e INTEGER;
  p_AllowsNull_01ec715e BOOLEAN;
  p_DefaultValue_01ec715e VARCHAR(255);
  p_IsPrimaryKey_01ec715e BOOLEAN;
  p_IsUniqueKey_01ec715e BOOLEAN;
  p_IsReadOnly_01ec715e BOOLEAN;
  p_IsRequired_01ec715e BOOLEAN;
  p_RelatedIntegrationObjectID_01ec715e UUID;
  p_RelatedIntegrationObjectFieldName_01ec715e VARCHAR(255);
  p_Sequence_01ec715e INTEGER;
  p_Configuration_01ec715e TEXT;
  p_Status_01ec715e VARCHAR(25);
  p_IsCustom_01ec715e BOOLEAN;
  p_MetadataSource_01ec715e VARCHAR(20);
BEGIN
  p_ID_01ec715e := '01EC715E-D97E-4A28-B23D-D98EB91090B6';
  p_IntegrationObjectID_01ec715e := '59A03914-49FE-46D1-AD42-317E043F5F52';
  p_Name_01ec715e := 'id';
  p_DisplayName_01ec715e := 'Id';
  p_Description_01ec715e := 'The unique ID of the dimension set line. Non-editable.';
  p_Type_01ec715e := 'uuid';
  p_AllowsNull_01ec715e := FALSE;
  p_IsPrimaryKey_01ec715e := TRUE;
  p_IsUniqueKey_01ec715e := TRUE;
  p_IsReadOnly_01ec715e := TRUE;
  p_IsRequired_01ec715e := TRUE;
  p_Sequence_01ec715e := 1;
  p_Configuration_01ec715e := '{
  "edmType": "GUID"
}';
  p_Status_01ec715e := 'Active';
  p_IsCustom_01ec715e := FALSE;
  p_MetadataSource_01ec715e := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_01ec715e, p_IntegrationObjectID := p_IntegrationObjectID_01ec715e, p_Name := p_Name_01ec715e, p_DisplayName := p_DisplayName_01ec715e, p_Description := p_Description_01ec715e, p_Category := p_Category_01ec715e, p_Category_Clear := TRUE, p_Type := p_Type_01ec715e, p_Length := p_Length_01ec715e, p_Length_Clear := TRUE, p_Precision := p_Precision_01ec715e, p_Precision_Clear := TRUE, p_Scale := p_Scale_01ec715e, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_01ec715e, p_DefaultValue := p_DefaultValue_01ec715e, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_01ec715e, p_IsUniqueKey := p_IsUniqueKey_01ec715e, p_IsReadOnly := p_IsReadOnly_01ec715e, p_IsRequired := p_IsRequired_01ec715e, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_01ec715e, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_01ec715e, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_01ec715e, p_Configuration := p_Configuration_01ec715e, p_Status := p_Status_01ec715e, p_IsCustom := p_IsCustom_01ec715e, p_MetadataSource := p_MetadataSource_01ec715e);
END $mj$;

DO $mj$
DECLARE
  p_ID_2de35971 UUID;
  p_IntegrationObjectID_2de35971 UUID;
  p_Name_2de35971 VARCHAR(255);
  p_DisplayName_2de35971 VARCHAR(255);
  p_Description_2de35971 TEXT;
  p_Category_2de35971 VARCHAR(100);
  p_Type_2de35971 VARCHAR(100);
  p_Length_2de35971 INTEGER;
  p_Precision_2de35971 INTEGER;
  p_Scale_2de35971 INTEGER;
  p_AllowsNull_2de35971 BOOLEAN;
  p_DefaultValue_2de35971 VARCHAR(255);
  p_IsPrimaryKey_2de35971 BOOLEAN;
  p_IsUniqueKey_2de35971 BOOLEAN;
  p_IsReadOnly_2de35971 BOOLEAN;
  p_IsRequired_2de35971 BOOLEAN;
  p_RelatedIntegrationObjectID_2de35971 UUID;
  p_RelatedIntegrationObjectFieldName_2de35971 VARCHAR(255);
  p_Sequence_2de35971 INTEGER;
  p_Configuration_2de35971 TEXT;
  p_Status_2de35971 VARCHAR(25);
  p_IsCustom_2de35971 BOOLEAN;
  p_MetadataSource_2de35971 VARCHAR(20);
BEGIN
  p_ID_2de35971 := '2DE35971-C0D4-41DE-8A28-F23F30258C4B';
  p_IntegrationObjectID_2de35971 := '59A03914-49FE-46D1-AD42-317E043F5F52';
  p_Name_2de35971 := 'code';
  p_DisplayName_2de35971 := 'Code';
  p_Description_2de35971 := 'The code of the dimension set line.';
  p_Type_2de35971 := 'string';
  p_AllowsNull_2de35971 := TRUE;
  p_IsPrimaryKey_2de35971 := FALSE;
  p_IsUniqueKey_2de35971 := FALSE;
  p_IsReadOnly_2de35971 := FALSE;
  p_IsRequired_2de35971 := FALSE;
  p_Sequence_2de35971 := 2;
  p_Configuration_2de35971 := '{
  "edmType": "string"
}';
  p_Status_2de35971 := 'Active';
  p_IsCustom_2de35971 := FALSE;
  p_MetadataSource_2de35971 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_2de35971, p_IntegrationObjectID := p_IntegrationObjectID_2de35971, p_Name := p_Name_2de35971, p_DisplayName := p_DisplayName_2de35971, p_Description := p_Description_2de35971, p_Category := p_Category_2de35971, p_Category_Clear := TRUE, p_Type := p_Type_2de35971, p_Length := p_Length_2de35971, p_Length_Clear := TRUE, p_Precision := p_Precision_2de35971, p_Precision_Clear := TRUE, p_Scale := p_Scale_2de35971, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_2de35971, p_DefaultValue := p_DefaultValue_2de35971, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_2de35971, p_IsUniqueKey := p_IsUniqueKey_2de35971, p_IsReadOnly := p_IsReadOnly_2de35971, p_IsRequired := p_IsRequired_2de35971, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_2de35971, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_2de35971, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_2de35971, p_Configuration := p_Configuration_2de35971, p_Status := p_Status_2de35971, p_IsCustom := p_IsCustom_2de35971, p_MetadataSource := p_MetadataSource_2de35971);
END $mj$;

DO $mj$
DECLARE
  p_ID_a824d0fc UUID;
  p_IntegrationObjectID_a824d0fc UUID;
  p_Name_a824d0fc VARCHAR(255);
  p_DisplayName_a824d0fc VARCHAR(255);
  p_Description_a824d0fc TEXT;
  p_Category_a824d0fc VARCHAR(100);
  p_Type_a824d0fc VARCHAR(100);
  p_Length_a824d0fc INTEGER;
  p_Precision_a824d0fc INTEGER;
  p_Scale_a824d0fc INTEGER;
  p_AllowsNull_a824d0fc BOOLEAN;
  p_DefaultValue_a824d0fc VARCHAR(255);
  p_IsPrimaryKey_a824d0fc BOOLEAN;
  p_IsUniqueKey_a824d0fc BOOLEAN;
  p_IsReadOnly_a824d0fc BOOLEAN;
  p_IsRequired_a824d0fc BOOLEAN;
  p_RelatedIntegrationObjectID_a824d0fc UUID;
  p_RelatedIntegrationObjectFieldName_a824d0fc VARCHAR(255);
  p_Sequence_a824d0fc INTEGER;
  p_Configuration_a824d0fc TEXT;
  p_Status_a824d0fc VARCHAR(25);
  p_IsCustom_a824d0fc BOOLEAN;
  p_MetadataSource_a824d0fc VARCHAR(20);
BEGIN
  p_ID_a824d0fc := 'A824D0FC-AC99-4C63-AEED-9B81B8BE91AE';
  p_IntegrationObjectID_a824d0fc := '59A03914-49FE-46D1-AD42-317E043F5F52';
  p_Name_a824d0fc := 'consolidationCode';
  p_DisplayName_a824d0fc := 'Consolidation Code';
  p_Description_a824d0fc := 'consolidationCode (string) on the dimensionSetLine resource. Microsoft''s Properties table leaves the description cell blank.';
  p_Type_a824d0fc := 'string';
  p_AllowsNull_a824d0fc := TRUE;
  p_IsPrimaryKey_a824d0fc := FALSE;
  p_IsUniqueKey_a824d0fc := FALSE;
  p_IsReadOnly_a824d0fc := FALSE;
  p_IsRequired_a824d0fc := FALSE;
  p_Sequence_a824d0fc := 3;
  p_Configuration_a824d0fc := '{
  "edmType": "string"
}';
  p_Status_a824d0fc := 'Active';
  p_IsCustom_a824d0fc := FALSE;
  p_MetadataSource_a824d0fc := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_a824d0fc, p_IntegrationObjectID := p_IntegrationObjectID_a824d0fc, p_Name := p_Name_a824d0fc, p_DisplayName := p_DisplayName_a824d0fc, p_Description := p_Description_a824d0fc, p_Category := p_Category_a824d0fc, p_Category_Clear := TRUE, p_Type := p_Type_a824d0fc, p_Length := p_Length_a824d0fc, p_Length_Clear := TRUE, p_Precision := p_Precision_a824d0fc, p_Precision_Clear := TRUE, p_Scale := p_Scale_a824d0fc, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_a824d0fc, p_DefaultValue := p_DefaultValue_a824d0fc, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_a824d0fc, p_IsUniqueKey := p_IsUniqueKey_a824d0fc, p_IsReadOnly := p_IsReadOnly_a824d0fc, p_IsRequired := p_IsRequired_a824d0fc, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_a824d0fc, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_a824d0fc, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_a824d0fc, p_Configuration := p_Configuration_a824d0fc, p_Status := p_Status_a824d0fc, p_IsCustom := p_IsCustom_a824d0fc, p_MetadataSource := p_MetadataSource_a824d0fc);
END $mj$;

DO $mj$
DECLARE
  p_ID_37274f11 UUID;
  p_IntegrationObjectID_37274f11 UUID;
  p_Name_37274f11 VARCHAR(255);
  p_DisplayName_37274f11 VARCHAR(255);
  p_Description_37274f11 TEXT;
  p_Category_37274f11 VARCHAR(100);
  p_Type_37274f11 VARCHAR(100);
  p_Length_37274f11 INTEGER;
  p_Precision_37274f11 INTEGER;
  p_Scale_37274f11 INTEGER;
  p_AllowsNull_37274f11 BOOLEAN;
  p_DefaultValue_37274f11 VARCHAR(255);
  p_IsPrimaryKey_37274f11 BOOLEAN;
  p_IsUniqueKey_37274f11 BOOLEAN;
  p_IsReadOnly_37274f11 BOOLEAN;
  p_IsRequired_37274f11 BOOLEAN;
  p_RelatedIntegrationObjectID_37274f11 UUID;
  p_RelatedIntegrationObjectFieldName_37274f11 VARCHAR(255);
  p_Sequence_37274f11 INTEGER;
  p_Configuration_37274f11 TEXT;
  p_Status_37274f11 VARCHAR(25);
  p_IsCustom_37274f11 BOOLEAN;
  p_MetadataSource_37274f11 VARCHAR(20);
BEGIN
  p_ID_37274f11 := '37274F11-4908-4122-81C0-781BEA60E4BC';
  p_IntegrationObjectID_37274f11 := '59A03914-49FE-46D1-AD42-317E043F5F52';
  p_Name_37274f11 := 'parentId';
  p_DisplayName_37274f11 := 'Parent Id';
  p_Description_37274f11 := 'The ID of the parent entity.';
  p_Type_37274f11 := 'uuid';
  p_AllowsNull_37274f11 := TRUE;
  p_IsPrimaryKey_37274f11 := FALSE;
  p_IsUniqueKey_37274f11 := FALSE;
  p_IsReadOnly_37274f11 := FALSE;
  p_IsRequired_37274f11 := FALSE;
  p_Sequence_37274f11 := 4;
  p_Configuration_37274f11 := '{
  "edmType": "GUID"
}';
  p_Status_37274f11 := 'Active';
  p_IsCustom_37274f11 := FALSE;
  p_MetadataSource_37274f11 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_37274f11, p_IntegrationObjectID := p_IntegrationObjectID_37274f11, p_Name := p_Name_37274f11, p_DisplayName := p_DisplayName_37274f11, p_Description := p_Description_37274f11, p_Category := p_Category_37274f11, p_Category_Clear := TRUE, p_Type := p_Type_37274f11, p_Length := p_Length_37274f11, p_Length_Clear := TRUE, p_Precision := p_Precision_37274f11, p_Precision_Clear := TRUE, p_Scale := p_Scale_37274f11, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_37274f11, p_DefaultValue := p_DefaultValue_37274f11, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_37274f11, p_IsUniqueKey := p_IsUniqueKey_37274f11, p_IsReadOnly := p_IsReadOnly_37274f11, p_IsRequired := p_IsRequired_37274f11, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_37274f11, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_37274f11, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_37274f11, p_Configuration := p_Configuration_37274f11, p_Status := p_Status_37274f11, p_IsCustom := p_IsCustom_37274f11, p_MetadataSource := p_MetadataSource_37274f11);
END $mj$;

DO $mj$
DECLARE
  p_ID_1ed30900 UUID;
  p_IntegrationObjectID_1ed30900 UUID;
  p_Name_1ed30900 VARCHAR(255);
  p_DisplayName_1ed30900 VARCHAR(255);
  p_Description_1ed30900 TEXT;
  p_Category_1ed30900 VARCHAR(100);
  p_Type_1ed30900 VARCHAR(100);
  p_Length_1ed30900 INTEGER;
  p_Precision_1ed30900 INTEGER;
  p_Scale_1ed30900 INTEGER;
  p_AllowsNull_1ed30900 BOOLEAN;
  p_DefaultValue_1ed30900 VARCHAR(255);
  p_IsPrimaryKey_1ed30900 BOOLEAN;
  p_IsUniqueKey_1ed30900 BOOLEAN;
  p_IsReadOnly_1ed30900 BOOLEAN;
  p_IsRequired_1ed30900 BOOLEAN;
  p_RelatedIntegrationObjectID_1ed30900 UUID;
  p_RelatedIntegrationObjectFieldName_1ed30900 VARCHAR(255);
  p_Sequence_1ed30900 INTEGER;
  p_Configuration_1ed30900 TEXT;
  p_Status_1ed30900 VARCHAR(25);
  p_IsCustom_1ed30900 BOOLEAN;
  p_MetadataSource_1ed30900 VARCHAR(20);
BEGIN
  p_ID_1ed30900 := '1ED30900-446F-4C4C-AF88-E65943E5541B';
  p_IntegrationObjectID_1ed30900 := '59A03914-49FE-46D1-AD42-317E043F5F52';
  p_Name_1ed30900 := 'parentType';
  p_DisplayName_1ed30900 := 'Parent Type';
  p_Description_1ed30900 := 'The type of the parent document of the dimension set line. It can be " ", "Journal Line", "Sales Order", "Sales Order Line", "Sales Quote", "Sales Quote Line", "Sales Credit Memo", "Sales Credit Memo Line", "Sales Invoice", "Sales Invoice Line",...';
  p_Type_1ed30900 := 'string';
  p_AllowsNull_1ed30900 := TRUE;
  p_IsPrimaryKey_1ed30900 := FALSE;
  p_IsUniqueKey_1ed30900 := FALSE;
  p_IsReadOnly_1ed30900 := FALSE;
  p_IsRequired_1ed30900 := FALSE;
  p_Sequence_1ed30900 := 5;
  p_Configuration_1ed30900 := '{
  "edmType": "NAV.dimensionSetEntryBufferParentType",
  "enumType": "NAV.dimensionSetEntryBufferParentType",
  "enumValues": [
    " ",
    "Journal Line",
    "Sales Order",
    "Sales Order Line",
    "Sales Quote",
    "Sales Quote Line",
    "Sales Credit Memo",
    "Sales Credit Memo Line",
    "Sales Invoice",
    "Sales Invoice Line",
    "Purchase Invoice",
    "Purchase Invoice Line",
    "General Ledger Entry",
    "Time Registration Entry"
  ]
}';
  p_Status_1ed30900 := 'Active';
  p_IsCustom_1ed30900 := FALSE;
  p_MetadataSource_1ed30900 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_1ed30900, p_IntegrationObjectID := p_IntegrationObjectID_1ed30900, p_Name := p_Name_1ed30900, p_DisplayName := p_DisplayName_1ed30900, p_Description := p_Description_1ed30900, p_Category := p_Category_1ed30900, p_Category_Clear := TRUE, p_Type := p_Type_1ed30900, p_Length := p_Length_1ed30900, p_Length_Clear := TRUE, p_Precision := p_Precision_1ed30900, p_Precision_Clear := TRUE, p_Scale := p_Scale_1ed30900, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_1ed30900, p_DefaultValue := p_DefaultValue_1ed30900, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_1ed30900, p_IsUniqueKey := p_IsUniqueKey_1ed30900, p_IsReadOnly := p_IsReadOnly_1ed30900, p_IsRequired := p_IsRequired_1ed30900, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_1ed30900, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_1ed30900, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_1ed30900, p_Configuration := p_Configuration_1ed30900, p_Status := p_Status_1ed30900, p_IsCustom := p_IsCustom_1ed30900, p_MetadataSource := p_MetadataSource_1ed30900);
END $mj$;

DO $mj$
DECLARE
  p_ID_c520a208 UUID;
  p_IntegrationObjectID_c520a208 UUID;
  p_Name_c520a208 VARCHAR(255);
  p_DisplayName_c520a208 VARCHAR(255);
  p_Description_c520a208 TEXT;
  p_Category_c520a208 VARCHAR(100);
  p_Type_c520a208 VARCHAR(100);
  p_Length_c520a208 INTEGER;
  p_Precision_c520a208 INTEGER;
  p_Scale_c520a208 INTEGER;
  p_AllowsNull_c520a208 BOOLEAN;
  p_DefaultValue_c520a208 VARCHAR(255);
  p_IsPrimaryKey_c520a208 BOOLEAN;
  p_IsUniqueKey_c520a208 BOOLEAN;
  p_IsReadOnly_c520a208 BOOLEAN;
  p_IsRequired_c520a208 BOOLEAN;
  p_RelatedIntegrationObjectID_c520a208 UUID;
  p_RelatedIntegrationObjectFieldName_c520a208 VARCHAR(255);
  p_Sequence_c520a208 INTEGER;
  p_Configuration_c520a208 TEXT;
  p_Status_c520a208 VARCHAR(25);
  p_IsCustom_c520a208 BOOLEAN;
  p_MetadataSource_c520a208 VARCHAR(20);
BEGIN
  p_ID_c520a208 := 'C520A208-D3D0-46C2-B65F-BE9AE9F72B10';
  p_IntegrationObjectID_c520a208 := '59A03914-49FE-46D1-AD42-317E043F5F52';
  p_Name_c520a208 := 'displayName';
  p_DisplayName_c520a208 := 'Display Name';
  p_Description_c520a208 := 'Specifies the dimension set line''s name. This name will appear on all sales documents for the dimension set line.';
  p_Type_c520a208 := 'string';
  p_AllowsNull_c520a208 := TRUE;
  p_IsPrimaryKey_c520a208 := FALSE;
  p_IsUniqueKey_c520a208 := FALSE;
  p_IsReadOnly_c520a208 := FALSE;
  p_IsRequired_c520a208 := FALSE;
  p_Sequence_c520a208 := 6;
  p_Configuration_c520a208 := '{
  "edmType": "string"
}';
  p_Status_c520a208 := 'Active';
  p_IsCustom_c520a208 := FALSE;
  p_MetadataSource_c520a208 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_c520a208, p_IntegrationObjectID := p_IntegrationObjectID_c520a208, p_Name := p_Name_c520a208, p_DisplayName := p_DisplayName_c520a208, p_Description := p_Description_c520a208, p_Category := p_Category_c520a208, p_Category_Clear := TRUE, p_Type := p_Type_c520a208, p_Length := p_Length_c520a208, p_Length_Clear := TRUE, p_Precision := p_Precision_c520a208, p_Precision_Clear := TRUE, p_Scale := p_Scale_c520a208, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_c520a208, p_DefaultValue := p_DefaultValue_c520a208, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_c520a208, p_IsUniqueKey := p_IsUniqueKey_c520a208, p_IsReadOnly := p_IsReadOnly_c520a208, p_IsRequired := p_IsRequired_c520a208, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_c520a208, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_c520a208, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_c520a208, p_Configuration := p_Configuration_c520a208, p_Status := p_Status_c520a208, p_IsCustom := p_IsCustom_c520a208, p_MetadataSource := p_MetadataSource_c520a208);
END $mj$;

DO $mj$
DECLARE
  p_ID_7d173ad4 UUID;
  p_IntegrationObjectID_7d173ad4 UUID;
  p_Name_7d173ad4 VARCHAR(255);
  p_DisplayName_7d173ad4 VARCHAR(255);
  p_Description_7d173ad4 TEXT;
  p_Category_7d173ad4 VARCHAR(100);
  p_Type_7d173ad4 VARCHAR(100);
  p_Length_7d173ad4 INTEGER;
  p_Precision_7d173ad4 INTEGER;
  p_Scale_7d173ad4 INTEGER;
  p_AllowsNull_7d173ad4 BOOLEAN;
  p_DefaultValue_7d173ad4 VARCHAR(255);
  p_IsPrimaryKey_7d173ad4 BOOLEAN;
  p_IsUniqueKey_7d173ad4 BOOLEAN;
  p_IsReadOnly_7d173ad4 BOOLEAN;
  p_IsRequired_7d173ad4 BOOLEAN;
  p_RelatedIntegrationObjectID_7d173ad4 UUID;
  p_RelatedIntegrationObjectFieldName_7d173ad4 VARCHAR(255);
  p_Sequence_7d173ad4 INTEGER;
  p_Configuration_7d173ad4 TEXT;
  p_Status_7d173ad4 VARCHAR(25);
  p_IsCustom_7d173ad4 BOOLEAN;
  p_MetadataSource_7d173ad4 VARCHAR(20);
BEGIN
  p_ID_7d173ad4 := '7D173AD4-CC0E-41F4-9341-B9C7457EB0F3';
  p_IntegrationObjectID_7d173ad4 := '59A03914-49FE-46D1-AD42-317E043F5F52';
  p_Name_7d173ad4 := 'valueId';
  p_DisplayName_7d173ad4 := 'Value Id';
  p_Description_7d173ad4 := 'The unique ID of the value of the dimension.';
  p_Type_7d173ad4 := 'uuid';
  p_AllowsNull_7d173ad4 := TRUE;
  p_IsPrimaryKey_7d173ad4 := FALSE;
  p_IsUniqueKey_7d173ad4 := FALSE;
  p_IsReadOnly_7d173ad4 := FALSE;
  p_IsRequired_7d173ad4 := FALSE;
  p_Sequence_7d173ad4 := 7;
  p_Configuration_7d173ad4 := '{
  "edmType": "GUID"
}';
  p_Status_7d173ad4 := 'Active';
  p_IsCustom_7d173ad4 := FALSE;
  p_MetadataSource_7d173ad4 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_7d173ad4, p_IntegrationObjectID := p_IntegrationObjectID_7d173ad4, p_Name := p_Name_7d173ad4, p_DisplayName := p_DisplayName_7d173ad4, p_Description := p_Description_7d173ad4, p_Category := p_Category_7d173ad4, p_Category_Clear := TRUE, p_Type := p_Type_7d173ad4, p_Length := p_Length_7d173ad4, p_Length_Clear := TRUE, p_Precision := p_Precision_7d173ad4, p_Precision_Clear := TRUE, p_Scale := p_Scale_7d173ad4, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_7d173ad4, p_DefaultValue := p_DefaultValue_7d173ad4, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_7d173ad4, p_IsUniqueKey := p_IsUniqueKey_7d173ad4, p_IsReadOnly := p_IsReadOnly_7d173ad4, p_IsRequired := p_IsRequired_7d173ad4, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_7d173ad4, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_7d173ad4, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_7d173ad4, p_Configuration := p_Configuration_7d173ad4, p_Status := p_Status_7d173ad4, p_IsCustom := p_IsCustom_7d173ad4, p_MetadataSource := p_MetadataSource_7d173ad4);
END $mj$;

DO $mj$
DECLARE
  p_ID_b5229146 UUID;
  p_IntegrationObjectID_b5229146 UUID;
  p_Name_b5229146 VARCHAR(255);
  p_DisplayName_b5229146 VARCHAR(255);
  p_Description_b5229146 TEXT;
  p_Category_b5229146 VARCHAR(100);
  p_Type_b5229146 VARCHAR(100);
  p_Length_b5229146 INTEGER;
  p_Precision_b5229146 INTEGER;
  p_Scale_b5229146 INTEGER;
  p_AllowsNull_b5229146 BOOLEAN;
  p_DefaultValue_b5229146 VARCHAR(255);
  p_IsPrimaryKey_b5229146 BOOLEAN;
  p_IsUniqueKey_b5229146 BOOLEAN;
  p_IsReadOnly_b5229146 BOOLEAN;
  p_IsRequired_b5229146 BOOLEAN;
  p_RelatedIntegrationObjectID_b5229146 UUID;
  p_RelatedIntegrationObjectFieldName_b5229146 VARCHAR(255);
  p_Sequence_b5229146 INTEGER;
  p_Configuration_b5229146 TEXT;
  p_Status_b5229146 VARCHAR(25);
  p_IsCustom_b5229146 BOOLEAN;
  p_MetadataSource_b5229146 VARCHAR(20);
BEGIN
  p_ID_b5229146 := 'B5229146-D368-443A-90C4-F30486FF950A';
  p_IntegrationObjectID_b5229146 := '59A03914-49FE-46D1-AD42-317E043F5F52';
  p_Name_b5229146 := 'valueCode';
  p_DisplayName_b5229146 := 'Value Code';
  p_Description_b5229146 := 'The code of the value of the dimension.';
  p_Type_b5229146 := 'string';
  p_AllowsNull_b5229146 := TRUE;
  p_IsPrimaryKey_b5229146 := FALSE;
  p_IsUniqueKey_b5229146 := FALSE;
  p_IsReadOnly_b5229146 := FALSE;
  p_IsRequired_b5229146 := FALSE;
  p_Sequence_b5229146 := 8;
  p_Configuration_b5229146 := '{
  "edmType": "string"
}';
  p_Status_b5229146 := 'Active';
  p_IsCustom_b5229146 := FALSE;
  p_MetadataSource_b5229146 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_b5229146, p_IntegrationObjectID := p_IntegrationObjectID_b5229146, p_Name := p_Name_b5229146, p_DisplayName := p_DisplayName_b5229146, p_Description := p_Description_b5229146, p_Category := p_Category_b5229146, p_Category_Clear := TRUE, p_Type := p_Type_b5229146, p_Length := p_Length_b5229146, p_Length_Clear := TRUE, p_Precision := p_Precision_b5229146, p_Precision_Clear := TRUE, p_Scale := p_Scale_b5229146, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_b5229146, p_DefaultValue := p_DefaultValue_b5229146, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_b5229146, p_IsUniqueKey := p_IsUniqueKey_b5229146, p_IsReadOnly := p_IsReadOnly_b5229146, p_IsRequired := p_IsRequired_b5229146, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_b5229146, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_b5229146, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_b5229146, p_Configuration := p_Configuration_b5229146, p_Status := p_Status_b5229146, p_IsCustom := p_IsCustom_b5229146, p_MetadataSource := p_MetadataSource_b5229146);
END $mj$;

DO $mj$
DECLARE
  p_ID_dbf6db7f UUID;
  p_IntegrationObjectID_dbf6db7f UUID;
  p_Name_dbf6db7f VARCHAR(255);
  p_DisplayName_dbf6db7f VARCHAR(255);
  p_Description_dbf6db7f TEXT;
  p_Category_dbf6db7f VARCHAR(100);
  p_Type_dbf6db7f VARCHAR(100);
  p_Length_dbf6db7f INTEGER;
  p_Precision_dbf6db7f INTEGER;
  p_Scale_dbf6db7f INTEGER;
  p_AllowsNull_dbf6db7f BOOLEAN;
  p_DefaultValue_dbf6db7f VARCHAR(255);
  p_IsPrimaryKey_dbf6db7f BOOLEAN;
  p_IsUniqueKey_dbf6db7f BOOLEAN;
  p_IsReadOnly_dbf6db7f BOOLEAN;
  p_IsRequired_dbf6db7f BOOLEAN;
  p_RelatedIntegrationObjectID_dbf6db7f UUID;
  p_RelatedIntegrationObjectFieldName_dbf6db7f VARCHAR(255);
  p_Sequence_dbf6db7f INTEGER;
  p_Configuration_dbf6db7f TEXT;
  p_Status_dbf6db7f VARCHAR(25);
  p_IsCustom_dbf6db7f BOOLEAN;
  p_MetadataSource_dbf6db7f VARCHAR(20);
BEGIN
  p_ID_dbf6db7f := 'DBF6DB7F-E637-4A34-8E10-21628C84942B';
  p_IntegrationObjectID_dbf6db7f := '59A03914-49FE-46D1-AD42-317E043F5F52';
  p_Name_dbf6db7f := 'valueConsolidationCode';
  p_DisplayName_dbf6db7f := 'Value Consolidation Code';
  p_Description_dbf6db7f := 'valueConsolidationCode (string) on the dimensionSetLine resource. Microsoft''s Properties table leaves the description cell blank.';
  p_Type_dbf6db7f := 'string';
  p_AllowsNull_dbf6db7f := TRUE;
  p_IsPrimaryKey_dbf6db7f := FALSE;
  p_IsUniqueKey_dbf6db7f := FALSE;
  p_IsReadOnly_dbf6db7f := FALSE;
  p_IsRequired_dbf6db7f := FALSE;
  p_Sequence_dbf6db7f := 9;
  p_Configuration_dbf6db7f := '{
  "edmType": "string"
}';
  p_Status_dbf6db7f := 'Active';
  p_IsCustom_dbf6db7f := FALSE;
  p_MetadataSource_dbf6db7f := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_dbf6db7f, p_IntegrationObjectID := p_IntegrationObjectID_dbf6db7f, p_Name := p_Name_dbf6db7f, p_DisplayName := p_DisplayName_dbf6db7f, p_Description := p_Description_dbf6db7f, p_Category := p_Category_dbf6db7f, p_Category_Clear := TRUE, p_Type := p_Type_dbf6db7f, p_Length := p_Length_dbf6db7f, p_Length_Clear := TRUE, p_Precision := p_Precision_dbf6db7f, p_Precision_Clear := TRUE, p_Scale := p_Scale_dbf6db7f, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_dbf6db7f, p_DefaultValue := p_DefaultValue_dbf6db7f, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_dbf6db7f, p_IsUniqueKey := p_IsUniqueKey_dbf6db7f, p_IsReadOnly := p_IsReadOnly_dbf6db7f, p_IsRequired := p_IsRequired_dbf6db7f, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_dbf6db7f, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_dbf6db7f, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_dbf6db7f, p_Configuration := p_Configuration_dbf6db7f, p_Status := p_Status_dbf6db7f, p_IsCustom := p_IsCustom_dbf6db7f, p_MetadataSource := p_MetadataSource_dbf6db7f);
END $mj$;

DO $mj$
DECLARE
  p_ID_c8fbd2e9 UUID;
  p_IntegrationObjectID_c8fbd2e9 UUID;
  p_Name_c8fbd2e9 VARCHAR(255);
  p_DisplayName_c8fbd2e9 VARCHAR(255);
  p_Description_c8fbd2e9 TEXT;
  p_Category_c8fbd2e9 VARCHAR(100);
  p_Type_c8fbd2e9 VARCHAR(100);
  p_Length_c8fbd2e9 INTEGER;
  p_Precision_c8fbd2e9 INTEGER;
  p_Scale_c8fbd2e9 INTEGER;
  p_AllowsNull_c8fbd2e9 BOOLEAN;
  p_DefaultValue_c8fbd2e9 VARCHAR(255);
  p_IsPrimaryKey_c8fbd2e9 BOOLEAN;
  p_IsUniqueKey_c8fbd2e9 BOOLEAN;
  p_IsReadOnly_c8fbd2e9 BOOLEAN;
  p_IsRequired_c8fbd2e9 BOOLEAN;
  p_RelatedIntegrationObjectID_c8fbd2e9 UUID;
  p_RelatedIntegrationObjectFieldName_c8fbd2e9 VARCHAR(255);
  p_Sequence_c8fbd2e9 INTEGER;
  p_Configuration_c8fbd2e9 TEXT;
  p_Status_c8fbd2e9 VARCHAR(25);
  p_IsCustom_c8fbd2e9 BOOLEAN;
  p_MetadataSource_c8fbd2e9 VARCHAR(20);
BEGIN
  p_ID_c8fbd2e9 := 'C8FBD2E9-E7FE-433C-9581-EF4291FAB2E0';
  p_IntegrationObjectID_c8fbd2e9 := '59A03914-49FE-46D1-AD42-317E043F5F52';
  p_Name_c8fbd2e9 := 'valueDisplayName';
  p_DisplayName_c8fbd2e9 := 'Value Display Name';
  p_Description_c8fbd2e9 := 'The display name of the value of the dimension. Read-Only.';
  p_Type_c8fbd2e9 := 'string';
  p_AllowsNull_c8fbd2e9 := TRUE;
  p_IsPrimaryKey_c8fbd2e9 := FALSE;
  p_IsUniqueKey_c8fbd2e9 := FALSE;
  p_IsReadOnly_c8fbd2e9 := TRUE;
  p_IsRequired_c8fbd2e9 := FALSE;
  p_Sequence_c8fbd2e9 := 10;
  p_Configuration_c8fbd2e9 := '{
  "edmType": "string"
}';
  p_Status_c8fbd2e9 := 'Active';
  p_IsCustom_c8fbd2e9 := FALSE;
  p_MetadataSource_c8fbd2e9 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_c8fbd2e9, p_IntegrationObjectID := p_IntegrationObjectID_c8fbd2e9, p_Name := p_Name_c8fbd2e9, p_DisplayName := p_DisplayName_c8fbd2e9, p_Description := p_Description_c8fbd2e9, p_Category := p_Category_c8fbd2e9, p_Category_Clear := TRUE, p_Type := p_Type_c8fbd2e9, p_Length := p_Length_c8fbd2e9, p_Length_Clear := TRUE, p_Precision := p_Precision_c8fbd2e9, p_Precision_Clear := TRUE, p_Scale := p_Scale_c8fbd2e9, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_c8fbd2e9, p_DefaultValue := p_DefaultValue_c8fbd2e9, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_c8fbd2e9, p_IsUniqueKey := p_IsUniqueKey_c8fbd2e9, p_IsReadOnly := p_IsReadOnly_c8fbd2e9, p_IsRequired := p_IsRequired_c8fbd2e9, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_c8fbd2e9, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_c8fbd2e9, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_c8fbd2e9, p_Configuration := p_Configuration_c8fbd2e9, p_Status := p_Status_c8fbd2e9, p_IsCustom := p_IsCustom_c8fbd2e9, p_MetadataSource := p_MetadataSource_c8fbd2e9);
END $mj$;
