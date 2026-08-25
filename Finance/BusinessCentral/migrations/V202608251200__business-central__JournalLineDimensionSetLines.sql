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

DECLARE @ID_59a03914 UNIQUEIDENTIFIER,
@IntegrationID_59a03914 UNIQUEIDENTIFIER,
@Name_59a03914 NVARCHAR(255),
@DisplayName_59a03914 NVARCHAR(255),
@Description_59a03914 NVARCHAR(MAX),
@Category_59a03914 NVARCHAR(100),
@APIPath_59a03914 NVARCHAR(500),
@ResponseDataKey_59a03914 NVARCHAR(255),
@DefaultPageSize_59a03914 INT,
@SupportsPagination_59a03914 BIT,
@PaginationType_59a03914 NVARCHAR(20),
@SupportsIncrementalSync_59a03914 BIT,
@SupportsWrite_59a03914 BIT,
@DefaultQueryParams_59a03914 NVARCHAR(MAX),
@Configuration_59a03914 NVARCHAR(MAX),
@Sequence_59a03914 INT,
@Status_59a03914 NVARCHAR(25),
@WriteAPIPath_59a03914 NVARCHAR(500),
@WriteMethod_59a03914 NVARCHAR(10),
@DeleteMethod_59a03914 NVARCHAR(10),
@IsCustom_59a03914 BIT,
@CreateAPIPath_59a03914 NVARCHAR(MAX),
@CreateMethod_59a03914 NVARCHAR(20),
@CreateBodyShape_59a03914 NVARCHAR(50),
@CreateBodyKey_59a03914 NVARCHAR(100),
@CreateIDLocation_59a03914 NVARCHAR(20),
@UpdateAPIPath_59a03914 NVARCHAR(MAX),
@UpdateMethod_59a03914 NVARCHAR(20),
@UpdateBodyShape_59a03914 NVARCHAR(50),
@UpdateBodyKey_59a03914 NVARCHAR(100),
@UpdateIDLocation_59a03914 NVARCHAR(20),
@DeleteAPIPath_59a03914 NVARCHAR(MAX),
@DeleteIDLocation_59a03914 NVARCHAR(20),
@IncrementalWatermarkField_59a03914 NVARCHAR(255),
@MetadataSource_59a03914 NVARCHAR(20),
@SupportsCreate_59a03914 BIT,
@SupportsUpdate_59a03914 BIT,
@SupportsDelete_59a03914 BIT,
@SyncStrategy_59a03914 NVARCHAR(50),
@ContentHashApplicable_59a03914 BIT,
@StableOrderingKey_59a03914 NVARCHAR(255)
SET
  @ID_59a03914 = '59A03914-49FE-46D1-AD42-317E043F5F52'
SET
  @IntegrationID_59a03914 = '3FD08940-E11D-4926-8149-6115F3B8ABF3'
SET
  @Name_59a03914 = N'journalLineDimensionSetLines'
SET
  @DisplayName_59a03914 = N'Journal Line Dimension Set Lines'
SET
  @Description_59a03914 = N'Dimension set lines addressed under a JOURNAL LINE. Business Central navigates dimensionSetLines from 24 parent types; the sibling `dimensionSetLines` object covers the sales-order parent and this one covers the journal line, so dimensions can be written to a journal entry. Same resource, different access path — `parentType` distinguishes them on the wire.'
SET
  @Category_59a03914 = N'journalLine children'
SET
  @APIPath_59a03914 = N'/companies({id})/journals({id})/journalLines({id})/dimensionSetLines'
SET
  @ResponseDataKey_59a03914 = N'value'
SET
  @SupportsPagination_59a03914 = 1
SET
  @PaginationType_59a03914 = N'Cursor'
SET
  @SupportsIncrementalSync_59a03914 = 0
SET
  @SupportsWrite_59a03914 = 1
SET
  @Configuration_59a03914 = N'{
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
}'
SET
  @Sequence_59a03914 = 71
SET
  @Status_59a03914 = N'Active'
SET
  @WriteMethod_59a03914 = N'POST'
SET
  @DeleteMethod_59a03914 = N'DELETE'
SET
  @IsCustom_59a03914 = 0
SET
  @CreateAPIPath_59a03914 = N'/companies({id})/journals({id})/journalLines({id})/dimensionSetLines'
SET
  @CreateMethod_59a03914 = N'POST'
SET
  @CreateBodyShape_59a03914 = N'flat'
SET
  @CreateIDLocation_59a03914 = N'body'
SET
  @UpdateAPIPath_59a03914 = N'/companies({id})/journals({id})/journalLines({id})/dimensionSetLines({id})'
SET
  @UpdateMethod_59a03914 = N'PATCH'
SET
  @UpdateBodyShape_59a03914 = N'flat'
SET
  @UpdateIDLocation_59a03914 = N'path'
SET
  @DeleteAPIPath_59a03914 = N'/companies({id})/journals({id})/journalLines({id})/dimensionSetLines({id})'
SET
  @DeleteIDLocation_59a03914 = N'path'
SET
  @MetadataSource_59a03914 = N'Declared'
SET
  @SupportsCreate_59a03914 = 1
SET
  @SupportsUpdate_59a03914 = 1
SET
  @SupportsDelete_59a03914 = 1
SET
  @SyncStrategy_59a03914 = N'FullPullHashDiff'
SET
  @ContentHashApplicable_59a03914 = 1
SET
  @StableOrderingKey_59a03914 = N'id' EXEC [__mj].spCreateIntegrationObject @ID = @ID_59a03914,
  @IntegrationID = @IntegrationID_59a03914,
  @Name = @Name_59a03914,
  @DisplayName = @DisplayName_59a03914,
  @Description = @Description_59a03914,
  @Category = @Category_59a03914,
  @APIPath = @APIPath_59a03914,
  @ResponseDataKey = @ResponseDataKey_59a03914,
  @DefaultPageSize = @DefaultPageSize_59a03914,
  @SupportsPagination = @SupportsPagination_59a03914,
  @PaginationType = @PaginationType_59a03914,
  @SupportsIncrementalSync = @SupportsIncrementalSync_59a03914,
  @SupportsWrite = @SupportsWrite_59a03914,
  @DefaultQueryParams = @DefaultQueryParams_59a03914,
  @DefaultQueryParams_Clear = 1,
  @Configuration = @Configuration_59a03914,
  @Sequence = @Sequence_59a03914,
  @Status = @Status_59a03914,
  @WriteAPIPath = @WriteAPIPath_59a03914,
  @WriteAPIPath_Clear = 1,
  @WriteMethod = @WriteMethod_59a03914,
  @DeleteMethod = @DeleteMethod_59a03914,
  @IsCustom = @IsCustom_59a03914,
  @CreateAPIPath = @CreateAPIPath_59a03914,
  @CreateMethod = @CreateMethod_59a03914,
  @CreateBodyShape = @CreateBodyShape_59a03914,
  @CreateBodyKey = @CreateBodyKey_59a03914,
  @CreateBodyKey_Clear = 1,
  @CreateIDLocation = @CreateIDLocation_59a03914,
  @UpdateAPIPath = @UpdateAPIPath_59a03914,
  @UpdateMethod = @UpdateMethod_59a03914,
  @UpdateBodyShape = @UpdateBodyShape_59a03914,
  @UpdateBodyKey = @UpdateBodyKey_59a03914,
  @UpdateBodyKey_Clear = 1,
  @UpdateIDLocation = @UpdateIDLocation_59a03914,
  @DeleteAPIPath = @DeleteAPIPath_59a03914,
  @DeleteIDLocation = @DeleteIDLocation_59a03914,
  @IncrementalWatermarkField = @IncrementalWatermarkField_59a03914,
  @MetadataSource = @MetadataSource_59a03914,
  @SupportsCreate = @SupportsCreate_59a03914,
  @SupportsUpdate = @SupportsUpdate_59a03914,
  @SupportsDelete = @SupportsDelete_59a03914,
  @SyncStrategy = @SyncStrategy_59a03914,
  @ContentHashApplicable = @ContentHashApplicable_59a03914,
  @StableOrderingKey = @StableOrderingKey_59a03914;

DECLARE @ID_01ec715e UNIQUEIDENTIFIER,
@IntegrationObjectID_01ec715e UNIQUEIDENTIFIER,
@Name_01ec715e NVARCHAR(255),
@DisplayName_01ec715e NVARCHAR(255),
@Description_01ec715e NVARCHAR(MAX),
@Category_01ec715e NVARCHAR(100),
@Type_01ec715e NVARCHAR(100),
@Length_01ec715e INT,
@Precision_01ec715e INT,
@Scale_01ec715e INT,
@AllowsNull_01ec715e BIT,
@DefaultValue_01ec715e NVARCHAR(255),
@IsPrimaryKey_01ec715e BIT,
@IsUniqueKey_01ec715e BIT,
@IsReadOnly_01ec715e BIT,
@IsRequired_01ec715e BIT,
@RelatedIntegrationObjectID_01ec715e UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_01ec715e NVARCHAR(255),
@Sequence_01ec715e INT,
@Configuration_01ec715e NVARCHAR(MAX),
@Status_01ec715e NVARCHAR(25),
@IsCustom_01ec715e BIT,
@MetadataSource_01ec715e NVARCHAR(20)
SET
  @ID_01ec715e = '01EC715E-D97E-4A28-B23D-D98EB91090B6'
SET
  @IntegrationObjectID_01ec715e = '59A03914-49FE-46D1-AD42-317E043F5F52'
SET
  @Name_01ec715e = N'id'
SET
  @DisplayName_01ec715e = N'Id'
SET
  @Description_01ec715e = N'The unique ID of the dimension set line. Non-editable.'
SET
  @Type_01ec715e = N'uuid'
SET
  @AllowsNull_01ec715e = 0
SET
  @IsPrimaryKey_01ec715e = 1
SET
  @IsUniqueKey_01ec715e = 1
SET
  @IsReadOnly_01ec715e = 1
SET
  @IsRequired_01ec715e = 1
SET
  @Sequence_01ec715e = 1
SET
  @Configuration_01ec715e = N'{
  "edmType": "GUID"
}'
SET
  @Status_01ec715e = N'Active'
SET
  @IsCustom_01ec715e = 0
SET
  @MetadataSource_01ec715e = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_01ec715e,
  @IntegrationObjectID = @IntegrationObjectID_01ec715e,
  @Name = @Name_01ec715e,
  @DisplayName = @DisplayName_01ec715e,
  @Description = @Description_01ec715e,
  @Category = @Category_01ec715e,
  @Category_Clear = 1,
  @Type = @Type_01ec715e,
  @Length = @Length_01ec715e,
  @Length_Clear = 1,
  @Precision = @Precision_01ec715e,
  @Precision_Clear = 1,
  @Scale = @Scale_01ec715e,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_01ec715e,
  @DefaultValue = @DefaultValue_01ec715e,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_01ec715e,
  @IsUniqueKey = @IsUniqueKey_01ec715e,
  @IsReadOnly = @IsReadOnly_01ec715e,
  @IsRequired = @IsRequired_01ec715e,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_01ec715e,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_01ec715e,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_01ec715e,
  @Configuration = @Configuration_01ec715e,
  @Status = @Status_01ec715e,
  @IsCustom = @IsCustom_01ec715e,
  @MetadataSource = @MetadataSource_01ec715e;

DECLARE @ID_2de35971 UNIQUEIDENTIFIER,
@IntegrationObjectID_2de35971 UNIQUEIDENTIFIER,
@Name_2de35971 NVARCHAR(255),
@DisplayName_2de35971 NVARCHAR(255),
@Description_2de35971 NVARCHAR(MAX),
@Category_2de35971 NVARCHAR(100),
@Type_2de35971 NVARCHAR(100),
@Length_2de35971 INT,
@Precision_2de35971 INT,
@Scale_2de35971 INT,
@AllowsNull_2de35971 BIT,
@DefaultValue_2de35971 NVARCHAR(255),
@IsPrimaryKey_2de35971 BIT,
@IsUniqueKey_2de35971 BIT,
@IsReadOnly_2de35971 BIT,
@IsRequired_2de35971 BIT,
@RelatedIntegrationObjectID_2de35971 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_2de35971 NVARCHAR(255),
@Sequence_2de35971 INT,
@Configuration_2de35971 NVARCHAR(MAX),
@Status_2de35971 NVARCHAR(25),
@IsCustom_2de35971 BIT,
@MetadataSource_2de35971 NVARCHAR(20)
SET
  @ID_2de35971 = '2DE35971-C0D4-41DE-8A28-F23F30258C4B'
SET
  @IntegrationObjectID_2de35971 = '59A03914-49FE-46D1-AD42-317E043F5F52'
SET
  @Name_2de35971 = N'code'
SET
  @DisplayName_2de35971 = N'Code'
SET
  @Description_2de35971 = N'The code of the dimension set line.'
SET
  @Type_2de35971 = N'string'
SET
  @AllowsNull_2de35971 = 1
SET
  @IsPrimaryKey_2de35971 = 0
SET
  @IsUniqueKey_2de35971 = 0
SET
  @IsReadOnly_2de35971 = 0
SET
  @IsRequired_2de35971 = 0
SET
  @Sequence_2de35971 = 2
SET
  @Configuration_2de35971 = N'{
  "edmType": "string"
}'
SET
  @Status_2de35971 = N'Active'
SET
  @IsCustom_2de35971 = 0
SET
  @MetadataSource_2de35971 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_2de35971,
  @IntegrationObjectID = @IntegrationObjectID_2de35971,
  @Name = @Name_2de35971,
  @DisplayName = @DisplayName_2de35971,
  @Description = @Description_2de35971,
  @Category = @Category_2de35971,
  @Category_Clear = 1,
  @Type = @Type_2de35971,
  @Length = @Length_2de35971,
  @Length_Clear = 1,
  @Precision = @Precision_2de35971,
  @Precision_Clear = 1,
  @Scale = @Scale_2de35971,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_2de35971,
  @DefaultValue = @DefaultValue_2de35971,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_2de35971,
  @IsUniqueKey = @IsUniqueKey_2de35971,
  @IsReadOnly = @IsReadOnly_2de35971,
  @IsRequired = @IsRequired_2de35971,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_2de35971,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_2de35971,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_2de35971,
  @Configuration = @Configuration_2de35971,
  @Status = @Status_2de35971,
  @IsCustom = @IsCustom_2de35971,
  @MetadataSource = @MetadataSource_2de35971;

DECLARE @ID_a824d0fc UNIQUEIDENTIFIER,
@IntegrationObjectID_a824d0fc UNIQUEIDENTIFIER,
@Name_a824d0fc NVARCHAR(255),
@DisplayName_a824d0fc NVARCHAR(255),
@Description_a824d0fc NVARCHAR(MAX),
@Category_a824d0fc NVARCHAR(100),
@Type_a824d0fc NVARCHAR(100),
@Length_a824d0fc INT,
@Precision_a824d0fc INT,
@Scale_a824d0fc INT,
@AllowsNull_a824d0fc BIT,
@DefaultValue_a824d0fc NVARCHAR(255),
@IsPrimaryKey_a824d0fc BIT,
@IsUniqueKey_a824d0fc BIT,
@IsReadOnly_a824d0fc BIT,
@IsRequired_a824d0fc BIT,
@RelatedIntegrationObjectID_a824d0fc UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_a824d0fc NVARCHAR(255),
@Sequence_a824d0fc INT,
@Configuration_a824d0fc NVARCHAR(MAX),
@Status_a824d0fc NVARCHAR(25),
@IsCustom_a824d0fc BIT,
@MetadataSource_a824d0fc NVARCHAR(20)
SET
  @ID_a824d0fc = 'A824D0FC-AC99-4C63-AEED-9B81B8BE91AE'
SET
  @IntegrationObjectID_a824d0fc = '59A03914-49FE-46D1-AD42-317E043F5F52'
SET
  @Name_a824d0fc = N'consolidationCode'
SET
  @DisplayName_a824d0fc = N'Consolidation Code'
SET
  @Description_a824d0fc = N'consolidationCode (string) on the dimensionSetLine resource. Microsoft''s Properties table leaves the description cell blank.'
SET
  @Type_a824d0fc = N'string'
SET
  @AllowsNull_a824d0fc = 1
SET
  @IsPrimaryKey_a824d0fc = 0
SET
  @IsUniqueKey_a824d0fc = 0
SET
  @IsReadOnly_a824d0fc = 0
SET
  @IsRequired_a824d0fc = 0
SET
  @Sequence_a824d0fc = 3
SET
  @Configuration_a824d0fc = N'{
  "edmType": "string"
}'
SET
  @Status_a824d0fc = N'Active'
SET
  @IsCustom_a824d0fc = 0
SET
  @MetadataSource_a824d0fc = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_a824d0fc,
  @IntegrationObjectID = @IntegrationObjectID_a824d0fc,
  @Name = @Name_a824d0fc,
  @DisplayName = @DisplayName_a824d0fc,
  @Description = @Description_a824d0fc,
  @Category = @Category_a824d0fc,
  @Category_Clear = 1,
  @Type = @Type_a824d0fc,
  @Length = @Length_a824d0fc,
  @Length_Clear = 1,
  @Precision = @Precision_a824d0fc,
  @Precision_Clear = 1,
  @Scale = @Scale_a824d0fc,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_a824d0fc,
  @DefaultValue = @DefaultValue_a824d0fc,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_a824d0fc,
  @IsUniqueKey = @IsUniqueKey_a824d0fc,
  @IsReadOnly = @IsReadOnly_a824d0fc,
  @IsRequired = @IsRequired_a824d0fc,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_a824d0fc,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_a824d0fc,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_a824d0fc,
  @Configuration = @Configuration_a824d0fc,
  @Status = @Status_a824d0fc,
  @IsCustom = @IsCustom_a824d0fc,
  @MetadataSource = @MetadataSource_a824d0fc;

DECLARE @ID_37274f11 UNIQUEIDENTIFIER,
@IntegrationObjectID_37274f11 UNIQUEIDENTIFIER,
@Name_37274f11 NVARCHAR(255),
@DisplayName_37274f11 NVARCHAR(255),
@Description_37274f11 NVARCHAR(MAX),
@Category_37274f11 NVARCHAR(100),
@Type_37274f11 NVARCHAR(100),
@Length_37274f11 INT,
@Precision_37274f11 INT,
@Scale_37274f11 INT,
@AllowsNull_37274f11 BIT,
@DefaultValue_37274f11 NVARCHAR(255),
@IsPrimaryKey_37274f11 BIT,
@IsUniqueKey_37274f11 BIT,
@IsReadOnly_37274f11 BIT,
@IsRequired_37274f11 BIT,
@RelatedIntegrationObjectID_37274f11 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_37274f11 NVARCHAR(255),
@Sequence_37274f11 INT,
@Configuration_37274f11 NVARCHAR(MAX),
@Status_37274f11 NVARCHAR(25),
@IsCustom_37274f11 BIT,
@MetadataSource_37274f11 NVARCHAR(20)
SET
  @ID_37274f11 = '37274F11-4908-4122-81C0-781BEA60E4BC'
SET
  @IntegrationObjectID_37274f11 = '59A03914-49FE-46D1-AD42-317E043F5F52'
SET
  @Name_37274f11 = N'parentId'
SET
  @DisplayName_37274f11 = N'Parent Id'
SET
  @Description_37274f11 = N'The ID of the parent entity.'
SET
  @Type_37274f11 = N'uuid'
SET
  @AllowsNull_37274f11 = 1
SET
  @IsPrimaryKey_37274f11 = 0
SET
  @IsUniqueKey_37274f11 = 0
SET
  @IsReadOnly_37274f11 = 0
SET
  @IsRequired_37274f11 = 0
SET
  @Sequence_37274f11 = 4
SET
  @Configuration_37274f11 = N'{
  "edmType": "GUID"
}'
SET
  @Status_37274f11 = N'Active'
SET
  @IsCustom_37274f11 = 0
SET
  @MetadataSource_37274f11 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_37274f11,
  @IntegrationObjectID = @IntegrationObjectID_37274f11,
  @Name = @Name_37274f11,
  @DisplayName = @DisplayName_37274f11,
  @Description = @Description_37274f11,
  @Category = @Category_37274f11,
  @Category_Clear = 1,
  @Type = @Type_37274f11,
  @Length = @Length_37274f11,
  @Length_Clear = 1,
  @Precision = @Precision_37274f11,
  @Precision_Clear = 1,
  @Scale = @Scale_37274f11,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_37274f11,
  @DefaultValue = @DefaultValue_37274f11,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_37274f11,
  @IsUniqueKey = @IsUniqueKey_37274f11,
  @IsReadOnly = @IsReadOnly_37274f11,
  @IsRequired = @IsRequired_37274f11,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_37274f11,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_37274f11,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_37274f11,
  @Configuration = @Configuration_37274f11,
  @Status = @Status_37274f11,
  @IsCustom = @IsCustom_37274f11,
  @MetadataSource = @MetadataSource_37274f11;

DECLARE @ID_1ed30900 UNIQUEIDENTIFIER,
@IntegrationObjectID_1ed30900 UNIQUEIDENTIFIER,
@Name_1ed30900 NVARCHAR(255),
@DisplayName_1ed30900 NVARCHAR(255),
@Description_1ed30900 NVARCHAR(MAX),
@Category_1ed30900 NVARCHAR(100),
@Type_1ed30900 NVARCHAR(100),
@Length_1ed30900 INT,
@Precision_1ed30900 INT,
@Scale_1ed30900 INT,
@AllowsNull_1ed30900 BIT,
@DefaultValue_1ed30900 NVARCHAR(255),
@IsPrimaryKey_1ed30900 BIT,
@IsUniqueKey_1ed30900 BIT,
@IsReadOnly_1ed30900 BIT,
@IsRequired_1ed30900 BIT,
@RelatedIntegrationObjectID_1ed30900 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_1ed30900 NVARCHAR(255),
@Sequence_1ed30900 INT,
@Configuration_1ed30900 NVARCHAR(MAX),
@Status_1ed30900 NVARCHAR(25),
@IsCustom_1ed30900 BIT,
@MetadataSource_1ed30900 NVARCHAR(20)
SET
  @ID_1ed30900 = '1ED30900-446F-4C4C-AF88-E65943E5541B'
SET
  @IntegrationObjectID_1ed30900 = '59A03914-49FE-46D1-AD42-317E043F5F52'
SET
  @Name_1ed30900 = N'parentType'
SET
  @DisplayName_1ed30900 = N'Parent Type'
SET
  @Description_1ed30900 = N'The type of the parent document of the dimension set line. It can be " ", "Journal Line", "Sales Order", "Sales Order Line", "Sales Quote", "Sales Quote Line", "Sales Credit Memo", "Sales Credit Memo Line", "Sales Invoice", "Sales Invoice Line",...'
SET
  @Type_1ed30900 = N'string'
SET
  @AllowsNull_1ed30900 = 1
SET
  @IsPrimaryKey_1ed30900 = 0
SET
  @IsUniqueKey_1ed30900 = 0
SET
  @IsReadOnly_1ed30900 = 0
SET
  @IsRequired_1ed30900 = 0
SET
  @Sequence_1ed30900 = 5
SET
  @Configuration_1ed30900 = N'{
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
}'
SET
  @Status_1ed30900 = N'Active'
SET
  @IsCustom_1ed30900 = 0
SET
  @MetadataSource_1ed30900 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_1ed30900,
  @IntegrationObjectID = @IntegrationObjectID_1ed30900,
  @Name = @Name_1ed30900,
  @DisplayName = @DisplayName_1ed30900,
  @Description = @Description_1ed30900,
  @Category = @Category_1ed30900,
  @Category_Clear = 1,
  @Type = @Type_1ed30900,
  @Length = @Length_1ed30900,
  @Length_Clear = 1,
  @Precision = @Precision_1ed30900,
  @Precision_Clear = 1,
  @Scale = @Scale_1ed30900,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_1ed30900,
  @DefaultValue = @DefaultValue_1ed30900,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_1ed30900,
  @IsUniqueKey = @IsUniqueKey_1ed30900,
  @IsReadOnly = @IsReadOnly_1ed30900,
  @IsRequired = @IsRequired_1ed30900,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_1ed30900,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_1ed30900,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_1ed30900,
  @Configuration = @Configuration_1ed30900,
  @Status = @Status_1ed30900,
  @IsCustom = @IsCustom_1ed30900,
  @MetadataSource = @MetadataSource_1ed30900;

DECLARE @ID_c520a208 UNIQUEIDENTIFIER,
@IntegrationObjectID_c520a208 UNIQUEIDENTIFIER,
@Name_c520a208 NVARCHAR(255),
@DisplayName_c520a208 NVARCHAR(255),
@Description_c520a208 NVARCHAR(MAX),
@Category_c520a208 NVARCHAR(100),
@Type_c520a208 NVARCHAR(100),
@Length_c520a208 INT,
@Precision_c520a208 INT,
@Scale_c520a208 INT,
@AllowsNull_c520a208 BIT,
@DefaultValue_c520a208 NVARCHAR(255),
@IsPrimaryKey_c520a208 BIT,
@IsUniqueKey_c520a208 BIT,
@IsReadOnly_c520a208 BIT,
@IsRequired_c520a208 BIT,
@RelatedIntegrationObjectID_c520a208 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_c520a208 NVARCHAR(255),
@Sequence_c520a208 INT,
@Configuration_c520a208 NVARCHAR(MAX),
@Status_c520a208 NVARCHAR(25),
@IsCustom_c520a208 BIT,
@MetadataSource_c520a208 NVARCHAR(20)
SET
  @ID_c520a208 = 'C520A208-D3D0-46C2-B65F-BE9AE9F72B10'
SET
  @IntegrationObjectID_c520a208 = '59A03914-49FE-46D1-AD42-317E043F5F52'
SET
  @Name_c520a208 = N'displayName'
SET
  @DisplayName_c520a208 = N'Display Name'
SET
  @Description_c520a208 = N'Specifies the dimension set line''s name. This name will appear on all sales documents for the dimension set line.'
SET
  @Type_c520a208 = N'string'
SET
  @AllowsNull_c520a208 = 1
SET
  @IsPrimaryKey_c520a208 = 0
SET
  @IsUniqueKey_c520a208 = 0
SET
  @IsReadOnly_c520a208 = 0
SET
  @IsRequired_c520a208 = 0
SET
  @Sequence_c520a208 = 6
SET
  @Configuration_c520a208 = N'{
  "edmType": "string"
}'
SET
  @Status_c520a208 = N'Active'
SET
  @IsCustom_c520a208 = 0
SET
  @MetadataSource_c520a208 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_c520a208,
  @IntegrationObjectID = @IntegrationObjectID_c520a208,
  @Name = @Name_c520a208,
  @DisplayName = @DisplayName_c520a208,
  @Description = @Description_c520a208,
  @Category = @Category_c520a208,
  @Category_Clear = 1,
  @Type = @Type_c520a208,
  @Length = @Length_c520a208,
  @Length_Clear = 1,
  @Precision = @Precision_c520a208,
  @Precision_Clear = 1,
  @Scale = @Scale_c520a208,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_c520a208,
  @DefaultValue = @DefaultValue_c520a208,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_c520a208,
  @IsUniqueKey = @IsUniqueKey_c520a208,
  @IsReadOnly = @IsReadOnly_c520a208,
  @IsRequired = @IsRequired_c520a208,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_c520a208,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_c520a208,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_c520a208,
  @Configuration = @Configuration_c520a208,
  @Status = @Status_c520a208,
  @IsCustom = @IsCustom_c520a208,
  @MetadataSource = @MetadataSource_c520a208;

DECLARE @ID_7d173ad4 UNIQUEIDENTIFIER,
@IntegrationObjectID_7d173ad4 UNIQUEIDENTIFIER,
@Name_7d173ad4 NVARCHAR(255),
@DisplayName_7d173ad4 NVARCHAR(255),
@Description_7d173ad4 NVARCHAR(MAX),
@Category_7d173ad4 NVARCHAR(100),
@Type_7d173ad4 NVARCHAR(100),
@Length_7d173ad4 INT,
@Precision_7d173ad4 INT,
@Scale_7d173ad4 INT,
@AllowsNull_7d173ad4 BIT,
@DefaultValue_7d173ad4 NVARCHAR(255),
@IsPrimaryKey_7d173ad4 BIT,
@IsUniqueKey_7d173ad4 BIT,
@IsReadOnly_7d173ad4 BIT,
@IsRequired_7d173ad4 BIT,
@RelatedIntegrationObjectID_7d173ad4 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_7d173ad4 NVARCHAR(255),
@Sequence_7d173ad4 INT,
@Configuration_7d173ad4 NVARCHAR(MAX),
@Status_7d173ad4 NVARCHAR(25),
@IsCustom_7d173ad4 BIT,
@MetadataSource_7d173ad4 NVARCHAR(20)
SET
  @ID_7d173ad4 = '7D173AD4-CC0E-41F4-9341-B9C7457EB0F3'
SET
  @IntegrationObjectID_7d173ad4 = '59A03914-49FE-46D1-AD42-317E043F5F52'
SET
  @Name_7d173ad4 = N'valueId'
SET
  @DisplayName_7d173ad4 = N'Value Id'
SET
  @Description_7d173ad4 = N'The unique ID of the value of the dimension.'
SET
  @Type_7d173ad4 = N'uuid'
SET
  @AllowsNull_7d173ad4 = 1
SET
  @IsPrimaryKey_7d173ad4 = 0
SET
  @IsUniqueKey_7d173ad4 = 0
SET
  @IsReadOnly_7d173ad4 = 0
SET
  @IsRequired_7d173ad4 = 0
SET
  @Sequence_7d173ad4 = 7
SET
  @Configuration_7d173ad4 = N'{
  "edmType": "GUID"
}'
SET
  @Status_7d173ad4 = N'Active'
SET
  @IsCustom_7d173ad4 = 0
SET
  @MetadataSource_7d173ad4 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_7d173ad4,
  @IntegrationObjectID = @IntegrationObjectID_7d173ad4,
  @Name = @Name_7d173ad4,
  @DisplayName = @DisplayName_7d173ad4,
  @Description = @Description_7d173ad4,
  @Category = @Category_7d173ad4,
  @Category_Clear = 1,
  @Type = @Type_7d173ad4,
  @Length = @Length_7d173ad4,
  @Length_Clear = 1,
  @Precision = @Precision_7d173ad4,
  @Precision_Clear = 1,
  @Scale = @Scale_7d173ad4,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_7d173ad4,
  @DefaultValue = @DefaultValue_7d173ad4,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_7d173ad4,
  @IsUniqueKey = @IsUniqueKey_7d173ad4,
  @IsReadOnly = @IsReadOnly_7d173ad4,
  @IsRequired = @IsRequired_7d173ad4,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_7d173ad4,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_7d173ad4,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_7d173ad4,
  @Configuration = @Configuration_7d173ad4,
  @Status = @Status_7d173ad4,
  @IsCustom = @IsCustom_7d173ad4,
  @MetadataSource = @MetadataSource_7d173ad4;

DECLARE @ID_b5229146 UNIQUEIDENTIFIER,
@IntegrationObjectID_b5229146 UNIQUEIDENTIFIER,
@Name_b5229146 NVARCHAR(255),
@DisplayName_b5229146 NVARCHAR(255),
@Description_b5229146 NVARCHAR(MAX),
@Category_b5229146 NVARCHAR(100),
@Type_b5229146 NVARCHAR(100),
@Length_b5229146 INT,
@Precision_b5229146 INT,
@Scale_b5229146 INT,
@AllowsNull_b5229146 BIT,
@DefaultValue_b5229146 NVARCHAR(255),
@IsPrimaryKey_b5229146 BIT,
@IsUniqueKey_b5229146 BIT,
@IsReadOnly_b5229146 BIT,
@IsRequired_b5229146 BIT,
@RelatedIntegrationObjectID_b5229146 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_b5229146 NVARCHAR(255),
@Sequence_b5229146 INT,
@Configuration_b5229146 NVARCHAR(MAX),
@Status_b5229146 NVARCHAR(25),
@IsCustom_b5229146 BIT,
@MetadataSource_b5229146 NVARCHAR(20)
SET
  @ID_b5229146 = 'B5229146-D368-443A-90C4-F30486FF950A'
SET
  @IntegrationObjectID_b5229146 = '59A03914-49FE-46D1-AD42-317E043F5F52'
SET
  @Name_b5229146 = N'valueCode'
SET
  @DisplayName_b5229146 = N'Value Code'
SET
  @Description_b5229146 = N'The code of the value of the dimension.'
SET
  @Type_b5229146 = N'string'
SET
  @AllowsNull_b5229146 = 1
SET
  @IsPrimaryKey_b5229146 = 0
SET
  @IsUniqueKey_b5229146 = 0
SET
  @IsReadOnly_b5229146 = 0
SET
  @IsRequired_b5229146 = 0
SET
  @Sequence_b5229146 = 8
SET
  @Configuration_b5229146 = N'{
  "edmType": "string"
}'
SET
  @Status_b5229146 = N'Active'
SET
  @IsCustom_b5229146 = 0
SET
  @MetadataSource_b5229146 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_b5229146,
  @IntegrationObjectID = @IntegrationObjectID_b5229146,
  @Name = @Name_b5229146,
  @DisplayName = @DisplayName_b5229146,
  @Description = @Description_b5229146,
  @Category = @Category_b5229146,
  @Category_Clear = 1,
  @Type = @Type_b5229146,
  @Length = @Length_b5229146,
  @Length_Clear = 1,
  @Precision = @Precision_b5229146,
  @Precision_Clear = 1,
  @Scale = @Scale_b5229146,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_b5229146,
  @DefaultValue = @DefaultValue_b5229146,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_b5229146,
  @IsUniqueKey = @IsUniqueKey_b5229146,
  @IsReadOnly = @IsReadOnly_b5229146,
  @IsRequired = @IsRequired_b5229146,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_b5229146,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_b5229146,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_b5229146,
  @Configuration = @Configuration_b5229146,
  @Status = @Status_b5229146,
  @IsCustom = @IsCustom_b5229146,
  @MetadataSource = @MetadataSource_b5229146;

DECLARE @ID_dbf6db7f UNIQUEIDENTIFIER,
@IntegrationObjectID_dbf6db7f UNIQUEIDENTIFIER,
@Name_dbf6db7f NVARCHAR(255),
@DisplayName_dbf6db7f NVARCHAR(255),
@Description_dbf6db7f NVARCHAR(MAX),
@Category_dbf6db7f NVARCHAR(100),
@Type_dbf6db7f NVARCHAR(100),
@Length_dbf6db7f INT,
@Precision_dbf6db7f INT,
@Scale_dbf6db7f INT,
@AllowsNull_dbf6db7f BIT,
@DefaultValue_dbf6db7f NVARCHAR(255),
@IsPrimaryKey_dbf6db7f BIT,
@IsUniqueKey_dbf6db7f BIT,
@IsReadOnly_dbf6db7f BIT,
@IsRequired_dbf6db7f BIT,
@RelatedIntegrationObjectID_dbf6db7f UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_dbf6db7f NVARCHAR(255),
@Sequence_dbf6db7f INT,
@Configuration_dbf6db7f NVARCHAR(MAX),
@Status_dbf6db7f NVARCHAR(25),
@IsCustom_dbf6db7f BIT,
@MetadataSource_dbf6db7f NVARCHAR(20)
SET
  @ID_dbf6db7f = 'DBF6DB7F-E637-4A34-8E10-21628C84942B'
SET
  @IntegrationObjectID_dbf6db7f = '59A03914-49FE-46D1-AD42-317E043F5F52'
SET
  @Name_dbf6db7f = N'valueConsolidationCode'
SET
  @DisplayName_dbf6db7f = N'Value Consolidation Code'
SET
  @Description_dbf6db7f = N'valueConsolidationCode (string) on the dimensionSetLine resource. Microsoft''s Properties table leaves the description cell blank.'
SET
  @Type_dbf6db7f = N'string'
SET
  @AllowsNull_dbf6db7f = 1
SET
  @IsPrimaryKey_dbf6db7f = 0
SET
  @IsUniqueKey_dbf6db7f = 0
SET
  @IsReadOnly_dbf6db7f = 0
SET
  @IsRequired_dbf6db7f = 0
SET
  @Sequence_dbf6db7f = 9
SET
  @Configuration_dbf6db7f = N'{
  "edmType": "string"
}'
SET
  @Status_dbf6db7f = N'Active'
SET
  @IsCustom_dbf6db7f = 0
SET
  @MetadataSource_dbf6db7f = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_dbf6db7f,
  @IntegrationObjectID = @IntegrationObjectID_dbf6db7f,
  @Name = @Name_dbf6db7f,
  @DisplayName = @DisplayName_dbf6db7f,
  @Description = @Description_dbf6db7f,
  @Category = @Category_dbf6db7f,
  @Category_Clear = 1,
  @Type = @Type_dbf6db7f,
  @Length = @Length_dbf6db7f,
  @Length_Clear = 1,
  @Precision = @Precision_dbf6db7f,
  @Precision_Clear = 1,
  @Scale = @Scale_dbf6db7f,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_dbf6db7f,
  @DefaultValue = @DefaultValue_dbf6db7f,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_dbf6db7f,
  @IsUniqueKey = @IsUniqueKey_dbf6db7f,
  @IsReadOnly = @IsReadOnly_dbf6db7f,
  @IsRequired = @IsRequired_dbf6db7f,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_dbf6db7f,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_dbf6db7f,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_dbf6db7f,
  @Configuration = @Configuration_dbf6db7f,
  @Status = @Status_dbf6db7f,
  @IsCustom = @IsCustom_dbf6db7f,
  @MetadataSource = @MetadataSource_dbf6db7f;

DECLARE @ID_c8fbd2e9 UNIQUEIDENTIFIER,
@IntegrationObjectID_c8fbd2e9 UNIQUEIDENTIFIER,
@Name_c8fbd2e9 NVARCHAR(255),
@DisplayName_c8fbd2e9 NVARCHAR(255),
@Description_c8fbd2e9 NVARCHAR(MAX),
@Category_c8fbd2e9 NVARCHAR(100),
@Type_c8fbd2e9 NVARCHAR(100),
@Length_c8fbd2e9 INT,
@Precision_c8fbd2e9 INT,
@Scale_c8fbd2e9 INT,
@AllowsNull_c8fbd2e9 BIT,
@DefaultValue_c8fbd2e9 NVARCHAR(255),
@IsPrimaryKey_c8fbd2e9 BIT,
@IsUniqueKey_c8fbd2e9 BIT,
@IsReadOnly_c8fbd2e9 BIT,
@IsRequired_c8fbd2e9 BIT,
@RelatedIntegrationObjectID_c8fbd2e9 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_c8fbd2e9 NVARCHAR(255),
@Sequence_c8fbd2e9 INT,
@Configuration_c8fbd2e9 NVARCHAR(MAX),
@Status_c8fbd2e9 NVARCHAR(25),
@IsCustom_c8fbd2e9 BIT,
@MetadataSource_c8fbd2e9 NVARCHAR(20)
SET
  @ID_c8fbd2e9 = 'C8FBD2E9-E7FE-433C-9581-EF4291FAB2E0'
SET
  @IntegrationObjectID_c8fbd2e9 = '59A03914-49FE-46D1-AD42-317E043F5F52'
SET
  @Name_c8fbd2e9 = N'valueDisplayName'
SET
  @DisplayName_c8fbd2e9 = N'Value Display Name'
SET
  @Description_c8fbd2e9 = N'The display name of the value of the dimension. Read-Only.'
SET
  @Type_c8fbd2e9 = N'string'
SET
  @AllowsNull_c8fbd2e9 = 1
SET
  @IsPrimaryKey_c8fbd2e9 = 0
SET
  @IsUniqueKey_c8fbd2e9 = 0
SET
  @IsReadOnly_c8fbd2e9 = 1
SET
  @IsRequired_c8fbd2e9 = 0
SET
  @Sequence_c8fbd2e9 = 10
SET
  @Configuration_c8fbd2e9 = N'{
  "edmType": "string"
}'
SET
  @Status_c8fbd2e9 = N'Active'
SET
  @IsCustom_c8fbd2e9 = 0
SET
  @MetadataSource_c8fbd2e9 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_c8fbd2e9,
  @IntegrationObjectID = @IntegrationObjectID_c8fbd2e9,
  @Name = @Name_c8fbd2e9,
  @DisplayName = @DisplayName_c8fbd2e9,
  @Description = @Description_c8fbd2e9,
  @Category = @Category_c8fbd2e9,
  @Category_Clear = 1,
  @Type = @Type_c8fbd2e9,
  @Length = @Length_c8fbd2e9,
  @Length_Clear = 1,
  @Precision = @Precision_c8fbd2e9,
  @Precision_Clear = 1,
  @Scale = @Scale_c8fbd2e9,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_c8fbd2e9,
  @DefaultValue = @DefaultValue_c8fbd2e9,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_c8fbd2e9,
  @IsUniqueKey = @IsUniqueKey_c8fbd2e9,
  @IsReadOnly = @IsReadOnly_c8fbd2e9,
  @IsRequired = @IsRequired_c8fbd2e9,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_c8fbd2e9,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_c8fbd2e9,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_c8fbd2e9,
  @Configuration = @Configuration_c8fbd2e9,
  @Status = @Status_c8fbd2e9,
  @IsCustom = @IsCustom_c8fbd2e9,
  @MetadataSource = @MetadataSource_c8fbd2e9;
