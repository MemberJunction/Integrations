-- OpenWater: four objects that live BEHIND the application detail rather than on a paginated list endpoint.
--
-- The Public API v2 exposes an application's per-round state only inside /v2/Applications/{applicationId}:
-- the detail carries roundSubmissions[] (one element per round the application entered), each element
-- carries fieldValues[], and the fieldValues that represent file uploads carry a mediaId resolvable at
-- /v2/Media/{mediaId}. Winner types are similarly embedded: /v2/Programs -> rounds[] -> winnerTypes[].
-- None of these are reachable by the existing paginated-leaf walker, so none of them could be declared
-- before the connector grew detail-walk extraction modes (detail-embedded / detail-object / detail-harvest,
-- shipped with this migration's connector version).
--
--   * ApplicationRoundSubmission - detail-embedded: /v2/Applications/{applicationId} -> roundSubmissions[],
--     tagged with the applicationId it was walked under. PK (applicationId, roundId).
--   * ApplicationFile            - detail-embedded: the same walk, descending roundSubmissions[].fieldValues[]
--     and keeping only elements that carry a mediaId (file-upload field values). PK mediaId.
--   * Media                      - detail-object via detail-harvest: mediaIds are harvested from the
--     application details, then /v2/Media/{mediaId} IS the record. PK mediaId.
--   * ApplicationWinnerType      - embedded-array: /v2/Programs -> rounds[] -> winnerTypes[]. PK id.
--
-- All id fields are declared unsized String, never Integer, for the reasons documented in
-- V202608050910__openwater__DeclareParentWalkTagFields.sql (a declared Integer with no Length maps to
-- NVARCHAR(MAX), which cannot be indexed, and injected walk tags are strings at the source).
--
-- Delta migration: guarded on absence so re-running is a no-op. IDs are hardcoded (never NEWID()) so the
-- same object carries the same ID on every tenant. Audit columns are not set.

-- 1. The four integration objects (spCreateIntegrationObject, guarded on absence) ----------------------------

-- ApplicationRoundSubmission
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObject
               WHERE IntegrationID = 'F2209CE3-5BC2-4E5C-9661-F409BE8FF9AA' AND Name = N'ApplicationRoundSubmission')
BEGIN
DECLARE @ID_1dffcea1 UNIQUEIDENTIFIER,
@IntegrationID_1dffcea1 UNIQUEIDENTIFIER,
@Name_1dffcea1 NVARCHAR(255),
@DisplayName_1dffcea1 NVARCHAR(255),
@Description_1dffcea1 NVARCHAR(MAX),
@Category_1dffcea1 NVARCHAR(100),
@APIPath_1dffcea1 NVARCHAR(500),
@ResponseDataKey_1dffcea1 NVARCHAR(255),
@DefaultPageSize_1dffcea1 INT,
@SupportsPagination_1dffcea1 BIT,
@PaginationType_1dffcea1 NVARCHAR(20),
@SupportsIncrementalSync_1dffcea1 BIT,
@SupportsWrite_1dffcea1 BIT,
@DefaultQueryParams_1dffcea1 NVARCHAR(MAX),
@Configuration_1dffcea1 NVARCHAR(MAX),
@Sequence_1dffcea1 INT,
@Status_1dffcea1 NVARCHAR(25),
@WriteAPIPath_1dffcea1 NVARCHAR(500),
@WriteMethod_1dffcea1 NVARCHAR(10),
@DeleteMethod_1dffcea1 NVARCHAR(10),
@IsCustom_1dffcea1 BIT,
@CreateAPIPath_1dffcea1 NVARCHAR(MAX),
@CreateMethod_1dffcea1 NVARCHAR(20),
@CreateBodyShape_1dffcea1 NVARCHAR(50),
@CreateBodyKey_1dffcea1 NVARCHAR(100),
@CreateIDLocation_1dffcea1 NVARCHAR(20),
@UpdateAPIPath_1dffcea1 NVARCHAR(MAX),
@UpdateMethod_1dffcea1 NVARCHAR(20),
@UpdateBodyShape_1dffcea1 NVARCHAR(50),
@UpdateBodyKey_1dffcea1 NVARCHAR(100),
@UpdateIDLocation_1dffcea1 NVARCHAR(20),
@DeleteAPIPath_1dffcea1 NVARCHAR(MAX),
@DeleteIDLocation_1dffcea1 NVARCHAR(20),
@IncrementalWatermarkField_1dffcea1 NVARCHAR(255),
@MetadataSource_1dffcea1 NVARCHAR(20),
@SupportsCreate_1dffcea1 BIT,
@SupportsUpdate_1dffcea1 BIT,
@SupportsDelete_1dffcea1 BIT,
@SyncStrategy_1dffcea1 NVARCHAR(50),
@ContentHashApplicable_1dffcea1 BIT,
@StableOrderingKey_1dffcea1 NVARCHAR(255)
SET @ID_1dffcea1 = '1DFFCEA1-1B6B-4AD6-ACEC-4649A5D35EB6'
SET @IntegrationID_1dffcea1 = 'F2209CE3-5BC2-4E5C-9661-F409BE8FF9AA'
SET @Name_1dffcea1 = N'ApplicationRoundSubmission'
SET @DisplayName_1dffcea1 = N'Application Round Submissions'
SET @Description_1dffcea1 = N'OpenWater per-round submission state of an Application (embedded in the application detail). Access: Applications -> /v2/Applications/{applicationId} -> roundSubmissions[].'
SET @APIPath_1dffcea1 = N'(embedded in /v2/Applications/{applicationId} roundSubmissions[])'
SET @DefaultPageSize_1dffcea1 = 100
SET @SupportsPagination_1dffcea1 = 0
SET @PaginationType_1dffcea1 = N'None'
SET @SupportsIncrementalSync_1dffcea1 = 0
SET @SupportsWrite_1dffcea1 = 0
SET @Configuration_1dffcea1 = N'{
  "AccessPath": {
    "door": "Application",
    "doorPath": "/v2/Applications",
    "entryPath": "/v2/Applications/{applicationId}",
    "parentParamName": "applicationId",
    "nestingSegments": [
      "roundSubmissions[]"
    ],
    "extractionMode": "detail-embedded"
  }
}'
SET @Sequence_1dffcea1 = 0
SET @Status_1dffcea1 = N'Active'
SET @WriteMethod_1dffcea1 = N'POST'
SET @DeleteMethod_1dffcea1 = N'DELETE'
SET @IsCustom_1dffcea1 = 0
SET @MetadataSource_1dffcea1 = N'Declared'
SET @SupportsCreate_1dffcea1 = 0
SET @SupportsUpdate_1dffcea1 = 0
SET @SupportsDelete_1dffcea1 = 0
SET @ContentHashApplicable_1dffcea1 = 1
EXEC [__mj].spCreateIntegrationObject @ID = @ID_1dffcea1,
  @IntegrationID = @IntegrationID_1dffcea1,
  @Name = @Name_1dffcea1,
  @DisplayName = @DisplayName_1dffcea1,
  @Description = @Description_1dffcea1,
  @Category = @Category_1dffcea1,
  @Category_Clear = 1,
  @APIPath = @APIPath_1dffcea1,
  @ResponseDataKey = @ResponseDataKey_1dffcea1,
  @ResponseDataKey_Clear = 1,
  @DefaultPageSize = @DefaultPageSize_1dffcea1,
  @SupportsPagination = @SupportsPagination_1dffcea1,
  @PaginationType = @PaginationType_1dffcea1,
  @SupportsIncrementalSync = @SupportsIncrementalSync_1dffcea1,
  @SupportsWrite = @SupportsWrite_1dffcea1,
  @DefaultQueryParams = @DefaultQueryParams_1dffcea1,
  @DefaultQueryParams_Clear = 1,
  @Configuration = @Configuration_1dffcea1,
  @Sequence = @Sequence_1dffcea1,
  @Status = @Status_1dffcea1,
  @WriteAPIPath = @WriteAPIPath_1dffcea1,
  @WriteAPIPath_Clear = 1,
  @WriteMethod = @WriteMethod_1dffcea1,
  @DeleteMethod = @DeleteMethod_1dffcea1,
  @IsCustom = @IsCustom_1dffcea1,
  @CreateAPIPath = @CreateAPIPath_1dffcea1,
  @CreateAPIPath_Clear = 1,
  @CreateMethod = @CreateMethod_1dffcea1,
  @CreateMethod_Clear = 1,
  @CreateBodyShape = @CreateBodyShape_1dffcea1,
  @CreateBodyShape_Clear = 1,
  @CreateBodyKey = @CreateBodyKey_1dffcea1,
  @CreateBodyKey_Clear = 1,
  @CreateIDLocation = @CreateIDLocation_1dffcea1,
  @CreateIDLocation_Clear = 1,
  @UpdateAPIPath = @UpdateAPIPath_1dffcea1,
  @UpdateAPIPath_Clear = 1,
  @UpdateMethod = @UpdateMethod_1dffcea1,
  @UpdateMethod_Clear = 1,
  @UpdateBodyShape = @UpdateBodyShape_1dffcea1,
  @UpdateBodyShape_Clear = 1,
  @UpdateBodyKey = @UpdateBodyKey_1dffcea1,
  @UpdateBodyKey_Clear = 1,
  @UpdateIDLocation = @UpdateIDLocation_1dffcea1,
  @UpdateIDLocation_Clear = 1,
  @DeleteAPIPath = @DeleteAPIPath_1dffcea1,
  @DeleteAPIPath_Clear = 1,
  @DeleteIDLocation = @DeleteIDLocation_1dffcea1,
  @DeleteIDLocation_Clear = 1,
  @IncrementalWatermarkField = @IncrementalWatermarkField_1dffcea1,
  @IncrementalWatermarkField_Clear = 1,
  @MetadataSource = @MetadataSource_1dffcea1,
  @SupportsCreate = @SupportsCreate_1dffcea1,
  @SupportsUpdate = @SupportsUpdate_1dffcea1,
  @SupportsDelete = @SupportsDelete_1dffcea1,
  @SyncStrategy = @SyncStrategy_1dffcea1,
  @SyncStrategy_Clear = 1,
  @ContentHashApplicable = @ContentHashApplicable_1dffcea1,
  @StableOrderingKey = @StableOrderingKey_1dffcea1,
  @StableOrderingKey_Clear = 1;
END
GO

-- ApplicationFile
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObject
               WHERE IntegrationID = 'F2209CE3-5BC2-4E5C-9661-F409BE8FF9AA' AND Name = N'ApplicationFile')
BEGIN
DECLARE @ID_f3aae390 UNIQUEIDENTIFIER,
@IntegrationID_f3aae390 UNIQUEIDENTIFIER,
@Name_f3aae390 NVARCHAR(255),
@DisplayName_f3aae390 NVARCHAR(255),
@Description_f3aae390 NVARCHAR(MAX),
@Category_f3aae390 NVARCHAR(100),
@APIPath_f3aae390 NVARCHAR(500),
@ResponseDataKey_f3aae390 NVARCHAR(255),
@DefaultPageSize_f3aae390 INT,
@SupportsPagination_f3aae390 BIT,
@PaginationType_f3aae390 NVARCHAR(20),
@SupportsIncrementalSync_f3aae390 BIT,
@SupportsWrite_f3aae390 BIT,
@DefaultQueryParams_f3aae390 NVARCHAR(MAX),
@Configuration_f3aae390 NVARCHAR(MAX),
@Sequence_f3aae390 INT,
@Status_f3aae390 NVARCHAR(25),
@WriteAPIPath_f3aae390 NVARCHAR(500),
@WriteMethod_f3aae390 NVARCHAR(10),
@DeleteMethod_f3aae390 NVARCHAR(10),
@IsCustom_f3aae390 BIT,
@CreateAPIPath_f3aae390 NVARCHAR(MAX),
@CreateMethod_f3aae390 NVARCHAR(20),
@CreateBodyShape_f3aae390 NVARCHAR(50),
@CreateBodyKey_f3aae390 NVARCHAR(100),
@CreateIDLocation_f3aae390 NVARCHAR(20),
@UpdateAPIPath_f3aae390 NVARCHAR(MAX),
@UpdateMethod_f3aae390 NVARCHAR(20),
@UpdateBodyShape_f3aae390 NVARCHAR(50),
@UpdateBodyKey_f3aae390 NVARCHAR(100),
@UpdateIDLocation_f3aae390 NVARCHAR(20),
@DeleteAPIPath_f3aae390 NVARCHAR(MAX),
@DeleteIDLocation_f3aae390 NVARCHAR(20),
@IncrementalWatermarkField_f3aae390 NVARCHAR(255),
@MetadataSource_f3aae390 NVARCHAR(20),
@SupportsCreate_f3aae390 BIT,
@SupportsUpdate_f3aae390 BIT,
@SupportsDelete_f3aae390 BIT,
@SyncStrategy_f3aae390 NVARCHAR(50),
@ContentHashApplicable_f3aae390 BIT,
@StableOrderingKey_f3aae390 NVARCHAR(255)
SET @ID_f3aae390 = 'F3AAE390-75DC-4D9F-BB59-6997378904B5'
SET @IntegrationID_f3aae390 = 'F2209CE3-5BC2-4E5C-9661-F409BE8FF9AA'
SET @Name_f3aae390 = N'ApplicationFile'
SET @DisplayName_f3aae390 = N'Application Files'
SET @Description_f3aae390 = N'OpenWater file-upload field values across an Application round submissions (embedded in the application detail). Access: Applications -> /v2/Applications/{applicationId} -> roundSubmissions[] -> fieldValues[] (elements carrying a mediaId).'
SET @APIPath_f3aae390 = N'(embedded in /v2/Applications/{applicationId} roundSubmissions[].fieldValues[])'
SET @DefaultPageSize_f3aae390 = 100
SET @SupportsPagination_f3aae390 = 0
SET @PaginationType_f3aae390 = N'None'
SET @SupportsIncrementalSync_f3aae390 = 0
SET @SupportsWrite_f3aae390 = 0
SET @Configuration_f3aae390 = N'{
  "AccessPath": {
    "door": "Application",
    "doorPath": "/v2/Applications",
    "entryPath": "/v2/Applications/{applicationId}",
    "parentParamName": "applicationId",
    "nestingSegments": [
      "roundSubmissions[]",
      "fieldValues[]"
    ],
    "elementFilter": {
      "key": "mediaId",
      "exists": true
    },
    "extractionMode": "detail-embedded"
  }
}'
SET @Sequence_f3aae390 = 0
SET @Status_f3aae390 = N'Active'
SET @WriteMethod_f3aae390 = N'POST'
SET @DeleteMethod_f3aae390 = N'DELETE'
SET @IsCustom_f3aae390 = 0
SET @MetadataSource_f3aae390 = N'Declared'
SET @SupportsCreate_f3aae390 = 0
SET @SupportsUpdate_f3aae390 = 0
SET @SupportsDelete_f3aae390 = 0
SET @ContentHashApplicable_f3aae390 = 1
EXEC [__mj].spCreateIntegrationObject @ID = @ID_f3aae390,
  @IntegrationID = @IntegrationID_f3aae390,
  @Name = @Name_f3aae390,
  @DisplayName = @DisplayName_f3aae390,
  @Description = @Description_f3aae390,
  @Category = @Category_f3aae390,
  @Category_Clear = 1,
  @APIPath = @APIPath_f3aae390,
  @ResponseDataKey = @ResponseDataKey_f3aae390,
  @ResponseDataKey_Clear = 1,
  @DefaultPageSize = @DefaultPageSize_f3aae390,
  @SupportsPagination = @SupportsPagination_f3aae390,
  @PaginationType = @PaginationType_f3aae390,
  @SupportsIncrementalSync = @SupportsIncrementalSync_f3aae390,
  @SupportsWrite = @SupportsWrite_f3aae390,
  @DefaultQueryParams = @DefaultQueryParams_f3aae390,
  @DefaultQueryParams_Clear = 1,
  @Configuration = @Configuration_f3aae390,
  @Sequence = @Sequence_f3aae390,
  @Status = @Status_f3aae390,
  @WriteAPIPath = @WriteAPIPath_f3aae390,
  @WriteAPIPath_Clear = 1,
  @WriteMethod = @WriteMethod_f3aae390,
  @DeleteMethod = @DeleteMethod_f3aae390,
  @IsCustom = @IsCustom_f3aae390,
  @CreateAPIPath = @CreateAPIPath_f3aae390,
  @CreateAPIPath_Clear = 1,
  @CreateMethod = @CreateMethod_f3aae390,
  @CreateMethod_Clear = 1,
  @CreateBodyShape = @CreateBodyShape_f3aae390,
  @CreateBodyShape_Clear = 1,
  @CreateBodyKey = @CreateBodyKey_f3aae390,
  @CreateBodyKey_Clear = 1,
  @CreateIDLocation = @CreateIDLocation_f3aae390,
  @CreateIDLocation_Clear = 1,
  @UpdateAPIPath = @UpdateAPIPath_f3aae390,
  @UpdateAPIPath_Clear = 1,
  @UpdateMethod = @UpdateMethod_f3aae390,
  @UpdateMethod_Clear = 1,
  @UpdateBodyShape = @UpdateBodyShape_f3aae390,
  @UpdateBodyShape_Clear = 1,
  @UpdateBodyKey = @UpdateBodyKey_f3aae390,
  @UpdateBodyKey_Clear = 1,
  @UpdateIDLocation = @UpdateIDLocation_f3aae390,
  @UpdateIDLocation_Clear = 1,
  @DeleteAPIPath = @DeleteAPIPath_f3aae390,
  @DeleteAPIPath_Clear = 1,
  @DeleteIDLocation = @DeleteIDLocation_f3aae390,
  @DeleteIDLocation_Clear = 1,
  @IncrementalWatermarkField = @IncrementalWatermarkField_f3aae390,
  @IncrementalWatermarkField_Clear = 1,
  @MetadataSource = @MetadataSource_f3aae390,
  @SupportsCreate = @SupportsCreate_f3aae390,
  @SupportsUpdate = @SupportsUpdate_f3aae390,
  @SupportsDelete = @SupportsDelete_f3aae390,
  @SyncStrategy = @SyncStrategy_f3aae390,
  @SyncStrategy_Clear = 1,
  @ContentHashApplicable = @ContentHashApplicable_f3aae390,
  @StableOrderingKey = @StableOrderingKey_f3aae390,
  @StableOrderingKey_Clear = 1;
END
GO

-- Media
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObject
               WHERE IntegrationID = 'F2209CE3-5BC2-4E5C-9661-F409BE8FF9AA' AND Name = N'Media')
BEGIN
DECLARE @ID_7ab4a0d8 UNIQUEIDENTIFIER,
@IntegrationID_7ab4a0d8 UNIQUEIDENTIFIER,
@Name_7ab4a0d8 NVARCHAR(255),
@DisplayName_7ab4a0d8 NVARCHAR(255),
@Description_7ab4a0d8 NVARCHAR(MAX),
@Category_7ab4a0d8 NVARCHAR(100),
@APIPath_7ab4a0d8 NVARCHAR(500),
@ResponseDataKey_7ab4a0d8 NVARCHAR(255),
@DefaultPageSize_7ab4a0d8 INT,
@SupportsPagination_7ab4a0d8 BIT,
@PaginationType_7ab4a0d8 NVARCHAR(20),
@SupportsIncrementalSync_7ab4a0d8 BIT,
@SupportsWrite_7ab4a0d8 BIT,
@DefaultQueryParams_7ab4a0d8 NVARCHAR(MAX),
@Configuration_7ab4a0d8 NVARCHAR(MAX),
@Sequence_7ab4a0d8 INT,
@Status_7ab4a0d8 NVARCHAR(25),
@WriteAPIPath_7ab4a0d8 NVARCHAR(500),
@WriteMethod_7ab4a0d8 NVARCHAR(10),
@DeleteMethod_7ab4a0d8 NVARCHAR(10),
@IsCustom_7ab4a0d8 BIT,
@CreateAPIPath_7ab4a0d8 NVARCHAR(MAX),
@CreateMethod_7ab4a0d8 NVARCHAR(20),
@CreateBodyShape_7ab4a0d8 NVARCHAR(50),
@CreateBodyKey_7ab4a0d8 NVARCHAR(100),
@CreateIDLocation_7ab4a0d8 NVARCHAR(20),
@UpdateAPIPath_7ab4a0d8 NVARCHAR(MAX),
@UpdateMethod_7ab4a0d8 NVARCHAR(20),
@UpdateBodyShape_7ab4a0d8 NVARCHAR(50),
@UpdateBodyKey_7ab4a0d8 NVARCHAR(100),
@UpdateIDLocation_7ab4a0d8 NVARCHAR(20),
@DeleteAPIPath_7ab4a0d8 NVARCHAR(MAX),
@DeleteIDLocation_7ab4a0d8 NVARCHAR(20),
@IncrementalWatermarkField_7ab4a0d8 NVARCHAR(255),
@MetadataSource_7ab4a0d8 NVARCHAR(20),
@SupportsCreate_7ab4a0d8 BIT,
@SupportsUpdate_7ab4a0d8 BIT,
@SupportsDelete_7ab4a0d8 BIT,
@SyncStrategy_7ab4a0d8 NVARCHAR(50),
@ContentHashApplicable_7ab4a0d8 BIT,
@StableOrderingKey_7ab4a0d8 NVARCHAR(255)
SET @ID_7ab4a0d8 = '7AB4A0D8-D990-4E71-A55D-5A3528D70611'
SET @IntegrationID_7ab4a0d8 = 'F2209CE3-5BC2-4E5C-9661-F409BE8FF9AA'
SET @Name_7ab4a0d8 = N'Media'
SET @DisplayName_7ab4a0d8 = N'Media'
SET @Description_7ab4a0d8 = N'OpenWater media descriptor for uploaded files. Access: mediaIds harvested from Application details -> /v2/Media/{mediaId} (the detail response is the record).'
SET @APIPath_7ab4a0d8 = N'/v2/Media/{mediaId}'
SET @DefaultPageSize_7ab4a0d8 = 100
SET @SupportsPagination_7ab4a0d8 = 0
SET @PaginationType_7ab4a0d8 = N'None'
SET @SupportsIncrementalSync_7ab4a0d8 = 0
SET @SupportsWrite_7ab4a0d8 = 0
SET @Configuration_7ab4a0d8 = N'{
  "AccessPath": {
    "door": "Application",
    "doorPath": "/v2/Applications",
    "parentSource": "detail-harvest",
    "harvestDetailPath": "/v2/Applications/{applicationId}",
    "harvestDetailParam": "applicationId",
    "harvestSegments": [
      "roundSubmissions[]",
      "fieldValues[]"
    ],
    "harvestIdKey": "mediaId",
    "entryPath": "/v2/Media/{mediaId}",
    "parentParamName": "mediaId",
    "extractionMode": "detail-object"
  }
}'
SET @Sequence_7ab4a0d8 = 0
SET @Status_7ab4a0d8 = N'Active'
SET @WriteMethod_7ab4a0d8 = N'POST'
SET @DeleteMethod_7ab4a0d8 = N'DELETE'
SET @IsCustom_7ab4a0d8 = 0
SET @MetadataSource_7ab4a0d8 = N'Declared'
SET @SupportsCreate_7ab4a0d8 = 0
SET @SupportsUpdate_7ab4a0d8 = 0
SET @SupportsDelete_7ab4a0d8 = 0
SET @ContentHashApplicable_7ab4a0d8 = 1
EXEC [__mj].spCreateIntegrationObject @ID = @ID_7ab4a0d8,
  @IntegrationID = @IntegrationID_7ab4a0d8,
  @Name = @Name_7ab4a0d8,
  @DisplayName = @DisplayName_7ab4a0d8,
  @Description = @Description_7ab4a0d8,
  @Category = @Category_7ab4a0d8,
  @Category_Clear = 1,
  @APIPath = @APIPath_7ab4a0d8,
  @ResponseDataKey = @ResponseDataKey_7ab4a0d8,
  @ResponseDataKey_Clear = 1,
  @DefaultPageSize = @DefaultPageSize_7ab4a0d8,
  @SupportsPagination = @SupportsPagination_7ab4a0d8,
  @PaginationType = @PaginationType_7ab4a0d8,
  @SupportsIncrementalSync = @SupportsIncrementalSync_7ab4a0d8,
  @SupportsWrite = @SupportsWrite_7ab4a0d8,
  @DefaultQueryParams = @DefaultQueryParams_7ab4a0d8,
  @DefaultQueryParams_Clear = 1,
  @Configuration = @Configuration_7ab4a0d8,
  @Sequence = @Sequence_7ab4a0d8,
  @Status = @Status_7ab4a0d8,
  @WriteAPIPath = @WriteAPIPath_7ab4a0d8,
  @WriteAPIPath_Clear = 1,
  @WriteMethod = @WriteMethod_7ab4a0d8,
  @DeleteMethod = @DeleteMethod_7ab4a0d8,
  @IsCustom = @IsCustom_7ab4a0d8,
  @CreateAPIPath = @CreateAPIPath_7ab4a0d8,
  @CreateAPIPath_Clear = 1,
  @CreateMethod = @CreateMethod_7ab4a0d8,
  @CreateMethod_Clear = 1,
  @CreateBodyShape = @CreateBodyShape_7ab4a0d8,
  @CreateBodyShape_Clear = 1,
  @CreateBodyKey = @CreateBodyKey_7ab4a0d8,
  @CreateBodyKey_Clear = 1,
  @CreateIDLocation = @CreateIDLocation_7ab4a0d8,
  @CreateIDLocation_Clear = 1,
  @UpdateAPIPath = @UpdateAPIPath_7ab4a0d8,
  @UpdateAPIPath_Clear = 1,
  @UpdateMethod = @UpdateMethod_7ab4a0d8,
  @UpdateMethod_Clear = 1,
  @UpdateBodyShape = @UpdateBodyShape_7ab4a0d8,
  @UpdateBodyShape_Clear = 1,
  @UpdateBodyKey = @UpdateBodyKey_7ab4a0d8,
  @UpdateBodyKey_Clear = 1,
  @UpdateIDLocation = @UpdateIDLocation_7ab4a0d8,
  @UpdateIDLocation_Clear = 1,
  @DeleteAPIPath = @DeleteAPIPath_7ab4a0d8,
  @DeleteAPIPath_Clear = 1,
  @DeleteIDLocation = @DeleteIDLocation_7ab4a0d8,
  @DeleteIDLocation_Clear = 1,
  @IncrementalWatermarkField = @IncrementalWatermarkField_7ab4a0d8,
  @IncrementalWatermarkField_Clear = 1,
  @MetadataSource = @MetadataSource_7ab4a0d8,
  @SupportsCreate = @SupportsCreate_7ab4a0d8,
  @SupportsUpdate = @SupportsUpdate_7ab4a0d8,
  @SupportsDelete = @SupportsDelete_7ab4a0d8,
  @SyncStrategy = @SyncStrategy_7ab4a0d8,
  @SyncStrategy_Clear = 1,
  @ContentHashApplicable = @ContentHashApplicable_7ab4a0d8,
  @StableOrderingKey = @StableOrderingKey_7ab4a0d8,
  @StableOrderingKey_Clear = 1;
END
GO

-- ApplicationWinnerType
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObject
               WHERE IntegrationID = 'F2209CE3-5BC2-4E5C-9661-F409BE8FF9AA' AND Name = N'ApplicationWinnerType')
BEGIN
DECLARE @ID_7d3f6794 UNIQUEIDENTIFIER,
@IntegrationID_7d3f6794 UNIQUEIDENTIFIER,
@Name_7d3f6794 NVARCHAR(255),
@DisplayName_7d3f6794 NVARCHAR(255),
@Description_7d3f6794 NVARCHAR(MAX),
@Category_7d3f6794 NVARCHAR(100),
@APIPath_7d3f6794 NVARCHAR(500),
@ResponseDataKey_7d3f6794 NVARCHAR(255),
@DefaultPageSize_7d3f6794 INT,
@SupportsPagination_7d3f6794 BIT,
@PaginationType_7d3f6794 NVARCHAR(20),
@SupportsIncrementalSync_7d3f6794 BIT,
@SupportsWrite_7d3f6794 BIT,
@DefaultQueryParams_7d3f6794 NVARCHAR(MAX),
@Configuration_7d3f6794 NVARCHAR(MAX),
@Sequence_7d3f6794 INT,
@Status_7d3f6794 NVARCHAR(25),
@WriteAPIPath_7d3f6794 NVARCHAR(500),
@WriteMethod_7d3f6794 NVARCHAR(10),
@DeleteMethod_7d3f6794 NVARCHAR(10),
@IsCustom_7d3f6794 BIT,
@CreateAPIPath_7d3f6794 NVARCHAR(MAX),
@CreateMethod_7d3f6794 NVARCHAR(20),
@CreateBodyShape_7d3f6794 NVARCHAR(50),
@CreateBodyKey_7d3f6794 NVARCHAR(100),
@CreateIDLocation_7d3f6794 NVARCHAR(20),
@UpdateAPIPath_7d3f6794 NVARCHAR(MAX),
@UpdateMethod_7d3f6794 NVARCHAR(20),
@UpdateBodyShape_7d3f6794 NVARCHAR(50),
@UpdateBodyKey_7d3f6794 NVARCHAR(100),
@UpdateIDLocation_7d3f6794 NVARCHAR(20),
@DeleteAPIPath_7d3f6794 NVARCHAR(MAX),
@DeleteIDLocation_7d3f6794 NVARCHAR(20),
@IncrementalWatermarkField_7d3f6794 NVARCHAR(255),
@MetadataSource_7d3f6794 NVARCHAR(20),
@SupportsCreate_7d3f6794 BIT,
@SupportsUpdate_7d3f6794 BIT,
@SupportsDelete_7d3f6794 BIT,
@SyncStrategy_7d3f6794 NVARCHAR(50),
@ContentHashApplicable_7d3f6794 BIT,
@StableOrderingKey_7d3f6794 NVARCHAR(255)
SET @ID_7d3f6794 = '7D3F6794-4A3A-4C2F-9255-A27448CB4B50'
SET @IntegrationID_7d3f6794 = 'F2209CE3-5BC2-4E5C-9661-F409BE8FF9AA'
SET @Name_7d3f6794 = N'ApplicationWinnerType'
SET @DisplayName_7d3f6794 = N'Application Winner Types'
SET @Description_7d3f6794 = N'OpenWater winner types configured on program rounds (embedded). Access: Programs -> rounds[] -> winnerTypes[].'
SET @APIPath_7d3f6794 = N'(embedded in /v2/Programs rounds[].winnerTypes[])'
SET @DefaultPageSize_7d3f6794 = 100
SET @SupportsPagination_7d3f6794 = 0
SET @PaginationType_7d3f6794 = N'None'
SET @SupportsIncrementalSync_7d3f6794 = 0
SET @SupportsWrite_7d3f6794 = 0
SET @Configuration_7d3f6794 = N'{
  "AccessPath": {
    "door": "Program",
    "doorPath": "/v2/Programs",
    "nestingSegments": [
      "rounds[]",
      "winnerTypes[]"
    ],
    "extractionMode": "embedded-array"
  }
}'
SET @Sequence_7d3f6794 = 0
SET @Status_7d3f6794 = N'Active'
SET @WriteMethod_7d3f6794 = N'POST'
SET @DeleteMethod_7d3f6794 = N'DELETE'
SET @IsCustom_7d3f6794 = 0
SET @MetadataSource_7d3f6794 = N'Declared'
SET @SupportsCreate_7d3f6794 = 0
SET @SupportsUpdate_7d3f6794 = 0
SET @SupportsDelete_7d3f6794 = 0
SET @ContentHashApplicable_7d3f6794 = 1
EXEC [__mj].spCreateIntegrationObject @ID = @ID_7d3f6794,
  @IntegrationID = @IntegrationID_7d3f6794,
  @Name = @Name_7d3f6794,
  @DisplayName = @DisplayName_7d3f6794,
  @Description = @Description_7d3f6794,
  @Category = @Category_7d3f6794,
  @Category_Clear = 1,
  @APIPath = @APIPath_7d3f6794,
  @ResponseDataKey = @ResponseDataKey_7d3f6794,
  @ResponseDataKey_Clear = 1,
  @DefaultPageSize = @DefaultPageSize_7d3f6794,
  @SupportsPagination = @SupportsPagination_7d3f6794,
  @PaginationType = @PaginationType_7d3f6794,
  @SupportsIncrementalSync = @SupportsIncrementalSync_7d3f6794,
  @SupportsWrite = @SupportsWrite_7d3f6794,
  @DefaultQueryParams = @DefaultQueryParams_7d3f6794,
  @DefaultQueryParams_Clear = 1,
  @Configuration = @Configuration_7d3f6794,
  @Sequence = @Sequence_7d3f6794,
  @Status = @Status_7d3f6794,
  @WriteAPIPath = @WriteAPIPath_7d3f6794,
  @WriteAPIPath_Clear = 1,
  @WriteMethod = @WriteMethod_7d3f6794,
  @DeleteMethod = @DeleteMethod_7d3f6794,
  @IsCustom = @IsCustom_7d3f6794,
  @CreateAPIPath = @CreateAPIPath_7d3f6794,
  @CreateAPIPath_Clear = 1,
  @CreateMethod = @CreateMethod_7d3f6794,
  @CreateMethod_Clear = 1,
  @CreateBodyShape = @CreateBodyShape_7d3f6794,
  @CreateBodyShape_Clear = 1,
  @CreateBodyKey = @CreateBodyKey_7d3f6794,
  @CreateBodyKey_Clear = 1,
  @CreateIDLocation = @CreateIDLocation_7d3f6794,
  @CreateIDLocation_Clear = 1,
  @UpdateAPIPath = @UpdateAPIPath_7d3f6794,
  @UpdateAPIPath_Clear = 1,
  @UpdateMethod = @UpdateMethod_7d3f6794,
  @UpdateMethod_Clear = 1,
  @UpdateBodyShape = @UpdateBodyShape_7d3f6794,
  @UpdateBodyShape_Clear = 1,
  @UpdateBodyKey = @UpdateBodyKey_7d3f6794,
  @UpdateBodyKey_Clear = 1,
  @UpdateIDLocation = @UpdateIDLocation_7d3f6794,
  @UpdateIDLocation_Clear = 1,
  @DeleteAPIPath = @DeleteAPIPath_7d3f6794,
  @DeleteAPIPath_Clear = 1,
  @DeleteIDLocation = @DeleteIDLocation_7d3f6794,
  @DeleteIDLocation_Clear = 1,
  @IncrementalWatermarkField = @IncrementalWatermarkField_7d3f6794,
  @IncrementalWatermarkField_Clear = 1,
  @MetadataSource = @MetadataSource_7d3f6794,
  @SupportsCreate = @SupportsCreate_7d3f6794,
  @SupportsUpdate = @SupportsUpdate_7d3f6794,
  @SupportsDelete = @SupportsDelete_7d3f6794,
  @SyncStrategy = @SyncStrategy_7d3f6794,
  @SyncStrategy_Clear = 1,
  @ContentHashApplicable = @ContentHashApplicable_7d3f6794,
  @StableOrderingKey = @StableOrderingKey_7d3f6794,
  @StableOrderingKey_Clear = 1;
END
GO

-- 2. Their declared fields (guarded direct INSERT, per the V202608050910 delta precedent) --------------------

INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length, AllowsNull, IsPrimaryKey,
     IsUniqueKey, IsReadOnly, IsRequired, RelatedIntegrationObjectID, Sequence, Status, IsCustom, MetadataSource)
SELECT v.FieldID, o.ID, v.FieldName, v.DisplayName, v.Descr, v.Type, v.Length, v.AllowsNull, v.IsPK,
       v.IsUnique, 0, v.IsReq, p.ID, 0, N'Active', 0, N'Declared'
FROM (VALUES
    ('9C281CA4-60CD-449F-8155-5CC7808B471D', N'ApplicationRoundSubmission', N'applicationId', N'Application Id', N'String', NULL, 0, 1, 0, 1, N'Application',
     N'The Application this submission belongs to. Injected by the connector from the access path (/v2/Applications/{applicationId} detail) rather than returned in the element body, so it is declared String - see V202608050910 for the sizing rationale.'),
    ('11581F42-B2CE-441A-B3D4-BDCEF0C31C12', N'ApplicationRoundSubmission', N'roundId', N'Round Id', N'String', NULL, 0, 1, 0, 1, N'Rounds',
     N'Round this submission belongs to. Declared String rather than Integer - see V202608050910 for the sizing rationale.'),
    ('A3B8ABD8-E494-40FA-8621-97A58E6E2030', N'ApplicationRoundSubmission', N'roundName', N'Round Name', N'String', NULL, 1, 0, 0, 0, NULL,
     N'Round name as denormalized on the submission.'),
    ('43E0A806-5C33-4DEE-861C-483C71343E4D', N'ApplicationRoundSubmission', N'status', N'Status', N'String', NULL, 1, 0, 0, 0, NULL,
     N'Submission status.'),
    ('65677BDB-30F3-4D8D-9236-B745FDF1E317', N'ApplicationRoundSubmission', N'startedAtUtc', N'Started At Utc', N'DateTime', NULL, 1, 0, 0, 0, NULL,
     N'When the applicant started this round submission (UTC).'),
    ('CC319DA2-36BD-46CB-BAF1-D33F510AAF64', N'ApplicationRoundSubmission', N'updatedAtUtc', N'Updated At Utc', N'DateTime', NULL, 1, 0, 0, 0, NULL,
     N'Last update to this round submission (UTC).'),
    ('D4223F1B-85EA-4B65-ABD9-AE4BA2F0A1B5', N'ApplicationRoundSubmission', N'updatedByUserAtUtc', N'Updated By User At Utc', N'DateTime', NULL, 1, 0, 0, 0, NULL,
     N'Last update made by the applicant (UTC).'),
    ('5B250646-C1FD-44AA-9663-4FAC882A6A67', N'ApplicationRoundSubmission', N'finalizedAtUtc', N'Finalized At Utc', N'DateTime', NULL, 1, 0, 0, 0, NULL,
     N'When the submission was finalized (UTC).'),
    ('3613D8EF-2D39-431E-9CE7-1DEB50748CAC', N'ApplicationRoundSubmission', N'allowUserToMakeEdits', N'Allow User To Make Edits', N'Boolean', NULL, 1, 0, 0, 0, NULL,
     N'Whether the applicant may still edit this submission.'),
    ('AE1DC9BD-DE4F-44C4-8D32-8ADBA02B2B73', N'ApplicationRoundSubmission', N'isPaid', N'Is Paid', N'Boolean', NULL, 1, 0, 0, 0, NULL,
     N'Whether payment for this submission is complete.'),
    ('600C17AB-7FE6-40E6-A133-B912086C825A', N'ApplicationRoundSubmission', N'isWinner', N'Is Winner', N'Boolean', NULL, 1, 0, 0, 0, NULL,
     N'Whether this submission was marked a winner.'),
    ('C0B7B305-A98B-41AE-902D-55F1B0908491', N'ApplicationRoundSubmission', N'invoiceId', N'Invoice Id', N'String', NULL, 1, 0, 0, 0, N'Invoice',
     N'Invoice attached to this submission, when any. Declared String - see V202608050910 for the sizing rationale.'),
    ('78A20156-801E-408A-95D9-C4A9B3ECD8B9', N'ApplicationFile', N'mediaId', N'Media Id', N'String', NULL, 0, 1, 1, 1, N'Media',
     N'Media id of the uploaded file (also this record identity). Declared String - see V202608050910 for the sizing rationale.'),
    ('0036DC50-6C4D-437D-9125-5D9E7A3AE9B9', N'ApplicationFile', N'applicationId', N'Application Id', N'String', NULL, 1, 0, 0, 0, N'Application',
     N'The Application this file belongs to. Injected by the connector from the access path (/v2/Applications/{applicationId} detail).'),
    ('E580B35C-C1E1-47C8-8B01-F45264A52AF7', N'ApplicationFile', N'alias', N'Alias', N'String', NULL, 1, 0, 0, 0, NULL,
     N'Field alias the file was uploaded under.'),
    ('6874A594-7919-489E-9C1D-CF3731138ACF', N'ApplicationFile', N'caption', N'Caption', N'String', NULL, 1, 0, 0, 0, NULL,
     N'Caption entered for the uploaded file.'),
    ('1FB33C79-4EE9-42AB-AA30-C02B0C9C146B', N'Media', N'mediaId', N'Media Id', N'String', NULL, 0, 1, 1, 1, NULL,
     N'Media id. Injected by the connector from the access path (/v2/Media/{mediaId}) - the ids are harvested from Application details.'),
    ('0F061F0D-9B9D-46F5-A9FF-1DDAA00105DC', N'Media', N'url', N'Url', N'String', 2048, 1, 0, 0, 0, NULL,
     N'Download URL of the file.'),
    ('FB8A6F19-DAC0-4E5B-A4A2-EE098A1B8983', N'Media', N'fileName', N'File Name', N'String', NULL, 1, 0, 0, 0, NULL,
     N'Original file name.'),
    ('CF825A2F-F232-4B8B-9506-27AEE250C1FA', N'ApplicationWinnerType', N'id', N'Id', N'String', NULL, 0, 1, 1, 1, NULL,
     N'Winner type id. Declared String - see V202608050910 for the sizing rationale.'),
    ('821BE41B-B855-49A0-BB88-E7AB661C13DD', N'ApplicationWinnerType', N'name', N'Name', N'String', NULL, 1, 0, 0, 0, NULL,
     N'Winner type name.')
) AS v(FieldID, ObjectName, FieldName, DisplayName, Type, Length, AllowsNull, IsPK, IsUnique, IsReq, RelatedObjectName, Descr)
JOIN [__mj].Integration i ON i.Name = 'openwater'
JOIN [__mj].IntegrationObject o ON o.IntegrationID = i.ID AND o.Name = v.ObjectName
LEFT JOIN [__mj].IntegrationObject p ON p.IntegrationID = i.ID AND p.Name = v.RelatedObjectName
WHERE NOT EXISTS (
    SELECT 1 FROM [__mj].IntegrationObjectField f
    WHERE f.IntegrationObjectID = o.ID AND f.Name = v.FieldName);
