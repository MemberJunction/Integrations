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


UPDATE [__mj].IntegrationObject SET Configuration = N'{"endpoint": "/{iD}/record", "fetchModel": "per-iD full record (GET /{iD}/record), fetched concurrently per page; the only object that calls ORCID", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}' WHERE ID = '73AED6B8-468D-403B-B994-F3C786C98BC0';

GO

UPDATE [__mj].IntegrationObject SET Configuration = N'{"endpoint": "/{iD}/works", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}' WHERE ID = '1D853840-A875-41E9-AB35-940345EF1434';

GO

UPDATE [__mj].IntegrationObject SET Configuration = N'{"endpoint": "/{iD}/employments", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}' WHERE ID = '5F90FE9B-3498-4DC2-A188-6173B8EA842B';

GO

UPDATE [__mj].IntegrationObject SET Configuration = N'{"endpoint": "/{iD}/educations", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}' WHERE ID = '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF';

GO

UPDATE [__mj].IntegrationObject SET Configuration = N'{"endpoint": "/{iD}/qualifications", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}' WHERE ID = 'A28BB703-8E34-4725-AF07-CDE7E42EB046';

GO

UPDATE [__mj].IntegrationObject SET Configuration = N'{"endpoint": "/{iD}/distinctions", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}' WHERE ID = '2139B63E-5944-4542-BE5E-7213D64B9750';

GO

UPDATE [__mj].IntegrationObject SET Configuration = N'{"endpoint": "/{iD}/invited-positions", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}' WHERE ID = '5DD9CF05-1571-454E-BA40-D65E6B9C2131';

GO

UPDATE [__mj].IntegrationObject SET Configuration = N'{"endpoint": "/{iD}/memberships", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}' WHERE ID = 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05';

GO

UPDATE [__mj].IntegrationObject SET Configuration = N'{"endpoint": "/{iD}/services", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}' WHERE ID = '35593E67-CBB4-4C88-9438-80C1D7F4B2D0';

GO

UPDATE [__mj].IntegrationObject SET Configuration = N'{"endpoint": "/{iD}/fundings", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}' WHERE ID = 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD';

GO

UPDATE [__mj].IntegrationObject SET Configuration = N'{"endpoint": "/{iD}/peer-reviews", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}' WHERE ID = 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F';

GO

UPDATE [__mj].IntegrationObject SET Configuration = N'{"endpoint": "/{iD}/research-resources", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}' WHERE ID = 'E52B947C-796A-46F1-BD69-BD9CD92FA046';

GO

-- Save MJ: Integration Objects (core SP call only)
DECLARE @ID_14091de3 UNIQUEIDENTIFIER,
@IntegrationID_14091de3 UNIQUEIDENTIFIER,
@Name_14091de3 NVARCHAR(255),
@DisplayName_14091de3 NVARCHAR(255),
@Description_14091de3 NVARCHAR(MAX),
@Category_14091de3 NVARCHAR(100),
@APIPath_14091de3 NVARCHAR(500),
@ResponseDataKey_14091de3 NVARCHAR(255),
@DefaultPageSize_14091de3 INT,
@SupportsPagination_14091de3 BIT,
@PaginationType_14091de3 NVARCHAR(20),
@SupportsIncrementalSync_14091de3 BIT,
@SupportsWrite_14091de3 BIT,
@DefaultQueryParams_14091de3 NVARCHAR(MAX),
@Configuration_14091de3 NVARCHAR(MAX),
@Sequence_14091de3 INT,
@Status_14091de3 NVARCHAR(25),
@WriteAPIPath_14091de3 NVARCHAR(500),
@WriteMethod_14091de3 NVARCHAR(10),
@DeleteMethod_14091de3 NVARCHAR(10),
@IsCustom_14091de3 BIT,
@CreateAPIPath_14091de3 NVARCHAR(MAX),
@CreateMethod_14091de3 NVARCHAR(20),
@CreateBodyShape_14091de3 NVARCHAR(50),
@CreateBodyKey_14091de3 NVARCHAR(100),
@CreateIDLocation_14091de3 NVARCHAR(20),
@UpdateAPIPath_14091de3 NVARCHAR(MAX),
@UpdateMethod_14091de3 NVARCHAR(20),
@UpdateBodyShape_14091de3 NVARCHAR(50),
@UpdateBodyKey_14091de3 NVARCHAR(100),
@UpdateIDLocation_14091de3 NVARCHAR(20),
@DeleteAPIPath_14091de3 NVARCHAR(MAX),
@DeleteIDLocation_14091de3 NVARCHAR(20),
@IncrementalWatermarkField_14091de3 NVARCHAR(255),
@MetadataSource_14091de3 NVARCHAR(20),
@SupportsCreate_14091de3 BIT,
@SupportsUpdate_14091de3 BIT,
@SupportsDelete_14091de3 BIT,
@SyncStrategy_14091de3 NVARCHAR(50),
@ContentHashApplicable_14091de3 BIT,
@StableOrderingKey_14091de3 NVARCHAR(255)
SET
  @ID_14091de3 = 'D4B4DBBD-FF1E-5147-8602-A41DC2855CE5'
SET
  @IntegrationID_14091de3 = 'D2E0507F-6F7F-4C10-8493-21DAF94AE18E'
SET
  @Name_14091de3 = N'other-names'
SET
  @DisplayName_14091de3 = N'Other Names'
SET
  @Description_14091de3 = N'Alternate names the researcher is also known by (person section). Derived from the stored record; one row per other-name.'
SET
  @APIPath_14091de3 = N'/{iD}/other-names'
SET
  @DefaultPageSize_14091de3 = 100
SET
  @SupportsPagination_14091de3 = 0
SET
  @PaginationType_14091de3 = N'None'
SET
  @SupportsIncrementalSync_14091de3 = 1
SET
  @SupportsWrite_14091de3 = 0
SET
  @Configuration_14091de3 = N'{"endpoint": "/{iD}/other-names", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}'
SET
  @Sequence_14091de3 = 12
SET
  @Status_14091de3 = N'Active'
SET
  @WriteMethod_14091de3 = N'POST'
SET
  @DeleteMethod_14091de3 = N'DELETE'
SET
  @IsCustom_14091de3 = 0
SET
  @IncrementalWatermarkField_14091de3 = N'last-modified-date'
SET
  @MetadataSource_14091de3 = N'Declared'
SET
  @SupportsCreate_14091de3 = 0
SET
  @SupportsUpdate_14091de3 = 0
SET
  @SupportsDelete_14091de3 = 0
SET
  @ContentHashApplicable_14091de3 = 1
EXEC [__mj].spCreateIntegrationObject @ID = @ID_14091de3,
  @IntegrationID = @IntegrationID_14091de3,
  @Name = @Name_14091de3,
  @DisplayName = @DisplayName_14091de3,
  @Description = @Description_14091de3,
  @Category = @Category_14091de3,
  @Category_Clear = 1,
  @APIPath = @APIPath_14091de3,
  @ResponseDataKey = @ResponseDataKey_14091de3,
  @ResponseDataKey_Clear = 1,
  @DefaultPageSize = @DefaultPageSize_14091de3,
  @SupportsPagination = @SupportsPagination_14091de3,
  @PaginationType = @PaginationType_14091de3,
  @SupportsIncrementalSync = @SupportsIncrementalSync_14091de3,
  @SupportsWrite = @SupportsWrite_14091de3,
  @DefaultQueryParams = @DefaultQueryParams_14091de3,
  @DefaultQueryParams_Clear = 1,
  @Configuration = @Configuration_14091de3,
  @Sequence = @Sequence_14091de3,
  @Status = @Status_14091de3,
  @WriteAPIPath = @WriteAPIPath_14091de3,
  @WriteAPIPath_Clear = 1,
  @WriteMethod = @WriteMethod_14091de3,
  @DeleteMethod = @DeleteMethod_14091de3,
  @IsCustom = @IsCustom_14091de3,
  @CreateAPIPath = @CreateAPIPath_14091de3,
  @CreateAPIPath_Clear = 1,
  @CreateMethod = @CreateMethod_14091de3,
  @CreateMethod_Clear = 1,
  @CreateBodyShape = @CreateBodyShape_14091de3,
  @CreateBodyShape_Clear = 1,
  @CreateBodyKey = @CreateBodyKey_14091de3,
  @CreateBodyKey_Clear = 1,
  @CreateIDLocation = @CreateIDLocation_14091de3,
  @CreateIDLocation_Clear = 1,
  @UpdateAPIPath = @UpdateAPIPath_14091de3,
  @UpdateAPIPath_Clear = 1,
  @UpdateMethod = @UpdateMethod_14091de3,
  @UpdateMethod_Clear = 1,
  @UpdateBodyShape = @UpdateBodyShape_14091de3,
  @UpdateBodyShape_Clear = 1,
  @UpdateBodyKey = @UpdateBodyKey_14091de3,
  @UpdateBodyKey_Clear = 1,
  @UpdateIDLocation = @UpdateIDLocation_14091de3,
  @UpdateIDLocation_Clear = 1,
  @DeleteAPIPath = @DeleteAPIPath_14091de3,
  @DeleteAPIPath_Clear = 1,
  @DeleteIDLocation = @DeleteIDLocation_14091de3,
  @DeleteIDLocation_Clear = 1,
  @IncrementalWatermarkField = @IncrementalWatermarkField_14091de3,
  @MetadataSource = @MetadataSource_14091de3,
  @SupportsCreate = @SupportsCreate_14091de3,
  @SupportsUpdate = @SupportsUpdate_14091de3,
  @SupportsDelete = @SupportsDelete_14091de3,
  @SyncStrategy = @SyncStrategy_14091de3,
  @SyncStrategy_Clear = 1,
  @ContentHashApplicable = @ContentHashApplicable_14091de3,
  @StableOrderingKey = @StableOrderingKey_14091de3,
  @StableOrderingKey_Clear = 1;

GO

-- Save MJ: Integration Objects (core SP call only)
DECLARE @ID_d9b2774b UNIQUEIDENTIFIER,
@IntegrationID_d9b2774b UNIQUEIDENTIFIER,
@Name_d9b2774b NVARCHAR(255),
@DisplayName_d9b2774b NVARCHAR(255),
@Description_d9b2774b NVARCHAR(MAX),
@Category_d9b2774b NVARCHAR(100),
@APIPath_d9b2774b NVARCHAR(500),
@ResponseDataKey_d9b2774b NVARCHAR(255),
@DefaultPageSize_d9b2774b INT,
@SupportsPagination_d9b2774b BIT,
@PaginationType_d9b2774b NVARCHAR(20),
@SupportsIncrementalSync_d9b2774b BIT,
@SupportsWrite_d9b2774b BIT,
@DefaultQueryParams_d9b2774b NVARCHAR(MAX),
@Configuration_d9b2774b NVARCHAR(MAX),
@Sequence_d9b2774b INT,
@Status_d9b2774b NVARCHAR(25),
@WriteAPIPath_d9b2774b NVARCHAR(500),
@WriteMethod_d9b2774b NVARCHAR(10),
@DeleteMethod_d9b2774b NVARCHAR(10),
@IsCustom_d9b2774b BIT,
@CreateAPIPath_d9b2774b NVARCHAR(MAX),
@CreateMethod_d9b2774b NVARCHAR(20),
@CreateBodyShape_d9b2774b NVARCHAR(50),
@CreateBodyKey_d9b2774b NVARCHAR(100),
@CreateIDLocation_d9b2774b NVARCHAR(20),
@UpdateAPIPath_d9b2774b NVARCHAR(MAX),
@UpdateMethod_d9b2774b NVARCHAR(20),
@UpdateBodyShape_d9b2774b NVARCHAR(50),
@UpdateBodyKey_d9b2774b NVARCHAR(100),
@UpdateIDLocation_d9b2774b NVARCHAR(20),
@DeleteAPIPath_d9b2774b NVARCHAR(MAX),
@DeleteIDLocation_d9b2774b NVARCHAR(20),
@IncrementalWatermarkField_d9b2774b NVARCHAR(255),
@MetadataSource_d9b2774b NVARCHAR(20),
@SupportsCreate_d9b2774b BIT,
@SupportsUpdate_d9b2774b BIT,
@SupportsDelete_d9b2774b BIT,
@SyncStrategy_d9b2774b NVARCHAR(50),
@ContentHashApplicable_d9b2774b BIT,
@StableOrderingKey_d9b2774b NVARCHAR(255)
SET
  @ID_d9b2774b = 'C72BE662-43B8-5398-BE8F-FD2145295A4D'
SET
  @IntegrationID_d9b2774b = 'D2E0507F-6F7F-4C10-8493-21DAF94AE18E'
SET
  @Name_d9b2774b = N'keywords'
SET
  @DisplayName_d9b2774b = N'Keywords'
SET
  @Description_d9b2774b = N'Self-declared research keywords (person section). Derived from the stored record; one row per keyword.'
SET
  @APIPath_d9b2774b = N'/{iD}/keywords'
SET
  @DefaultPageSize_d9b2774b = 100
SET
  @SupportsPagination_d9b2774b = 0
SET
  @PaginationType_d9b2774b = N'None'
SET
  @SupportsIncrementalSync_d9b2774b = 1
SET
  @SupportsWrite_d9b2774b = 0
SET
  @Configuration_d9b2774b = N'{"endpoint": "/{iD}/keywords", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}'
SET
  @Sequence_d9b2774b = 13
SET
  @Status_d9b2774b = N'Active'
SET
  @WriteMethod_d9b2774b = N'POST'
SET
  @DeleteMethod_d9b2774b = N'DELETE'
SET
  @IsCustom_d9b2774b = 0
SET
  @IncrementalWatermarkField_d9b2774b = N'last-modified-date'
SET
  @MetadataSource_d9b2774b = N'Declared'
SET
  @SupportsCreate_d9b2774b = 0
SET
  @SupportsUpdate_d9b2774b = 0
SET
  @SupportsDelete_d9b2774b = 0
SET
  @ContentHashApplicable_d9b2774b = 1
EXEC [__mj].spCreateIntegrationObject @ID = @ID_d9b2774b,
  @IntegrationID = @IntegrationID_d9b2774b,
  @Name = @Name_d9b2774b,
  @DisplayName = @DisplayName_d9b2774b,
  @Description = @Description_d9b2774b,
  @Category = @Category_d9b2774b,
  @Category_Clear = 1,
  @APIPath = @APIPath_d9b2774b,
  @ResponseDataKey = @ResponseDataKey_d9b2774b,
  @ResponseDataKey_Clear = 1,
  @DefaultPageSize = @DefaultPageSize_d9b2774b,
  @SupportsPagination = @SupportsPagination_d9b2774b,
  @PaginationType = @PaginationType_d9b2774b,
  @SupportsIncrementalSync = @SupportsIncrementalSync_d9b2774b,
  @SupportsWrite = @SupportsWrite_d9b2774b,
  @DefaultQueryParams = @DefaultQueryParams_d9b2774b,
  @DefaultQueryParams_Clear = 1,
  @Configuration = @Configuration_d9b2774b,
  @Sequence = @Sequence_d9b2774b,
  @Status = @Status_d9b2774b,
  @WriteAPIPath = @WriteAPIPath_d9b2774b,
  @WriteAPIPath_Clear = 1,
  @WriteMethod = @WriteMethod_d9b2774b,
  @DeleteMethod = @DeleteMethod_d9b2774b,
  @IsCustom = @IsCustom_d9b2774b,
  @CreateAPIPath = @CreateAPIPath_d9b2774b,
  @CreateAPIPath_Clear = 1,
  @CreateMethod = @CreateMethod_d9b2774b,
  @CreateMethod_Clear = 1,
  @CreateBodyShape = @CreateBodyShape_d9b2774b,
  @CreateBodyShape_Clear = 1,
  @CreateBodyKey = @CreateBodyKey_d9b2774b,
  @CreateBodyKey_Clear = 1,
  @CreateIDLocation = @CreateIDLocation_d9b2774b,
  @CreateIDLocation_Clear = 1,
  @UpdateAPIPath = @UpdateAPIPath_d9b2774b,
  @UpdateAPIPath_Clear = 1,
  @UpdateMethod = @UpdateMethod_d9b2774b,
  @UpdateMethod_Clear = 1,
  @UpdateBodyShape = @UpdateBodyShape_d9b2774b,
  @UpdateBodyShape_Clear = 1,
  @UpdateBodyKey = @UpdateBodyKey_d9b2774b,
  @UpdateBodyKey_Clear = 1,
  @UpdateIDLocation = @UpdateIDLocation_d9b2774b,
  @UpdateIDLocation_Clear = 1,
  @DeleteAPIPath = @DeleteAPIPath_d9b2774b,
  @DeleteAPIPath_Clear = 1,
  @DeleteIDLocation = @DeleteIDLocation_d9b2774b,
  @DeleteIDLocation_Clear = 1,
  @IncrementalWatermarkField = @IncrementalWatermarkField_d9b2774b,
  @MetadataSource = @MetadataSource_d9b2774b,
  @SupportsCreate = @SupportsCreate_d9b2774b,
  @SupportsUpdate = @SupportsUpdate_d9b2774b,
  @SupportsDelete = @SupportsDelete_d9b2774b,
  @SyncStrategy = @SyncStrategy_d9b2774b,
  @SyncStrategy_Clear = 1,
  @ContentHashApplicable = @ContentHashApplicable_d9b2774b,
  @StableOrderingKey = @StableOrderingKey_d9b2774b,
  @StableOrderingKey_Clear = 1;

GO

-- Save MJ: Integration Objects (core SP call only)
DECLARE @ID_9fcd4f68 UNIQUEIDENTIFIER,
@IntegrationID_9fcd4f68 UNIQUEIDENTIFIER,
@Name_9fcd4f68 NVARCHAR(255),
@DisplayName_9fcd4f68 NVARCHAR(255),
@Description_9fcd4f68 NVARCHAR(MAX),
@Category_9fcd4f68 NVARCHAR(100),
@APIPath_9fcd4f68 NVARCHAR(500),
@ResponseDataKey_9fcd4f68 NVARCHAR(255),
@DefaultPageSize_9fcd4f68 INT,
@SupportsPagination_9fcd4f68 BIT,
@PaginationType_9fcd4f68 NVARCHAR(20),
@SupportsIncrementalSync_9fcd4f68 BIT,
@SupportsWrite_9fcd4f68 BIT,
@DefaultQueryParams_9fcd4f68 NVARCHAR(MAX),
@Configuration_9fcd4f68 NVARCHAR(MAX),
@Sequence_9fcd4f68 INT,
@Status_9fcd4f68 NVARCHAR(25),
@WriteAPIPath_9fcd4f68 NVARCHAR(500),
@WriteMethod_9fcd4f68 NVARCHAR(10),
@DeleteMethod_9fcd4f68 NVARCHAR(10),
@IsCustom_9fcd4f68 BIT,
@CreateAPIPath_9fcd4f68 NVARCHAR(MAX),
@CreateMethod_9fcd4f68 NVARCHAR(20),
@CreateBodyShape_9fcd4f68 NVARCHAR(50),
@CreateBodyKey_9fcd4f68 NVARCHAR(100),
@CreateIDLocation_9fcd4f68 NVARCHAR(20),
@UpdateAPIPath_9fcd4f68 NVARCHAR(MAX),
@UpdateMethod_9fcd4f68 NVARCHAR(20),
@UpdateBodyShape_9fcd4f68 NVARCHAR(50),
@UpdateBodyKey_9fcd4f68 NVARCHAR(100),
@UpdateIDLocation_9fcd4f68 NVARCHAR(20),
@DeleteAPIPath_9fcd4f68 NVARCHAR(MAX),
@DeleteIDLocation_9fcd4f68 NVARCHAR(20),
@IncrementalWatermarkField_9fcd4f68 NVARCHAR(255),
@MetadataSource_9fcd4f68 NVARCHAR(20),
@SupportsCreate_9fcd4f68 BIT,
@SupportsUpdate_9fcd4f68 BIT,
@SupportsDelete_9fcd4f68 BIT,
@SyncStrategy_9fcd4f68 NVARCHAR(50),
@ContentHashApplicable_9fcd4f68 BIT,
@StableOrderingKey_9fcd4f68 NVARCHAR(255)
SET
  @ID_9fcd4f68 = 'FB6D0904-DD1C-54A2-99AD-901CC4B56562'
SET
  @IntegrationID_9fcd4f68 = 'D2E0507F-6F7F-4C10-8493-21DAF94AE18E'
SET
  @Name_9fcd4f68 = N'email'
SET
  @DisplayName_9fcd4f68 = N'Email'
SET
  @Description_9fcd4f68 = N'Public email addresses (person section). Most ORCID emails are private, so this is usually empty. Derived from the stored record.'
SET
  @APIPath_9fcd4f68 = N'/{iD}/email'
SET
  @DefaultPageSize_9fcd4f68 = 100
SET
  @SupportsPagination_9fcd4f68 = 0
SET
  @PaginationType_9fcd4f68 = N'None'
SET
  @SupportsIncrementalSync_9fcd4f68 = 1
SET
  @SupportsWrite_9fcd4f68 = 0
SET
  @Configuration_9fcd4f68 = N'{"endpoint": "/{iD}/email", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}'
SET
  @Sequence_9fcd4f68 = 14
SET
  @Status_9fcd4f68 = N'Active'
SET
  @WriteMethod_9fcd4f68 = N'POST'
SET
  @DeleteMethod_9fcd4f68 = N'DELETE'
SET
  @IsCustom_9fcd4f68 = 0
SET
  @IncrementalWatermarkField_9fcd4f68 = N'last-modified-date'
SET
  @MetadataSource_9fcd4f68 = N'Declared'
SET
  @SupportsCreate_9fcd4f68 = 0
SET
  @SupportsUpdate_9fcd4f68 = 0
SET
  @SupportsDelete_9fcd4f68 = 0
SET
  @ContentHashApplicable_9fcd4f68 = 1
EXEC [__mj].spCreateIntegrationObject @ID = @ID_9fcd4f68,
  @IntegrationID = @IntegrationID_9fcd4f68,
  @Name = @Name_9fcd4f68,
  @DisplayName = @DisplayName_9fcd4f68,
  @Description = @Description_9fcd4f68,
  @Category = @Category_9fcd4f68,
  @Category_Clear = 1,
  @APIPath = @APIPath_9fcd4f68,
  @ResponseDataKey = @ResponseDataKey_9fcd4f68,
  @ResponseDataKey_Clear = 1,
  @DefaultPageSize = @DefaultPageSize_9fcd4f68,
  @SupportsPagination = @SupportsPagination_9fcd4f68,
  @PaginationType = @PaginationType_9fcd4f68,
  @SupportsIncrementalSync = @SupportsIncrementalSync_9fcd4f68,
  @SupportsWrite = @SupportsWrite_9fcd4f68,
  @DefaultQueryParams = @DefaultQueryParams_9fcd4f68,
  @DefaultQueryParams_Clear = 1,
  @Configuration = @Configuration_9fcd4f68,
  @Sequence = @Sequence_9fcd4f68,
  @Status = @Status_9fcd4f68,
  @WriteAPIPath = @WriteAPIPath_9fcd4f68,
  @WriteAPIPath_Clear = 1,
  @WriteMethod = @WriteMethod_9fcd4f68,
  @DeleteMethod = @DeleteMethod_9fcd4f68,
  @IsCustom = @IsCustom_9fcd4f68,
  @CreateAPIPath = @CreateAPIPath_9fcd4f68,
  @CreateAPIPath_Clear = 1,
  @CreateMethod = @CreateMethod_9fcd4f68,
  @CreateMethod_Clear = 1,
  @CreateBodyShape = @CreateBodyShape_9fcd4f68,
  @CreateBodyShape_Clear = 1,
  @CreateBodyKey = @CreateBodyKey_9fcd4f68,
  @CreateBodyKey_Clear = 1,
  @CreateIDLocation = @CreateIDLocation_9fcd4f68,
  @CreateIDLocation_Clear = 1,
  @UpdateAPIPath = @UpdateAPIPath_9fcd4f68,
  @UpdateAPIPath_Clear = 1,
  @UpdateMethod = @UpdateMethod_9fcd4f68,
  @UpdateMethod_Clear = 1,
  @UpdateBodyShape = @UpdateBodyShape_9fcd4f68,
  @UpdateBodyShape_Clear = 1,
  @UpdateBodyKey = @UpdateBodyKey_9fcd4f68,
  @UpdateBodyKey_Clear = 1,
  @UpdateIDLocation = @UpdateIDLocation_9fcd4f68,
  @UpdateIDLocation_Clear = 1,
  @DeleteAPIPath = @DeleteAPIPath_9fcd4f68,
  @DeleteAPIPath_Clear = 1,
  @DeleteIDLocation = @DeleteIDLocation_9fcd4f68,
  @DeleteIDLocation_Clear = 1,
  @IncrementalWatermarkField = @IncrementalWatermarkField_9fcd4f68,
  @MetadataSource = @MetadataSource_9fcd4f68,
  @SupportsCreate = @SupportsCreate_9fcd4f68,
  @SupportsUpdate = @SupportsUpdate_9fcd4f68,
  @SupportsDelete = @SupportsDelete_9fcd4f68,
  @SyncStrategy = @SyncStrategy_9fcd4f68,
  @SyncStrategy_Clear = 1,
  @ContentHashApplicable = @ContentHashApplicable_9fcd4f68,
  @StableOrderingKey = @StableOrderingKey_9fcd4f68,
  @StableOrderingKey_Clear = 1;

GO

-- Save MJ: Integration Objects (core SP call only)
DECLARE @ID_1b4ac07d UNIQUEIDENTIFIER,
@IntegrationID_1b4ac07d UNIQUEIDENTIFIER,
@Name_1b4ac07d NVARCHAR(255),
@DisplayName_1b4ac07d NVARCHAR(255),
@Description_1b4ac07d NVARCHAR(MAX),
@Category_1b4ac07d NVARCHAR(100),
@APIPath_1b4ac07d NVARCHAR(500),
@ResponseDataKey_1b4ac07d NVARCHAR(255),
@DefaultPageSize_1b4ac07d INT,
@SupportsPagination_1b4ac07d BIT,
@PaginationType_1b4ac07d NVARCHAR(20),
@SupportsIncrementalSync_1b4ac07d BIT,
@SupportsWrite_1b4ac07d BIT,
@DefaultQueryParams_1b4ac07d NVARCHAR(MAX),
@Configuration_1b4ac07d NVARCHAR(MAX),
@Sequence_1b4ac07d INT,
@Status_1b4ac07d NVARCHAR(25),
@WriteAPIPath_1b4ac07d NVARCHAR(500),
@WriteMethod_1b4ac07d NVARCHAR(10),
@DeleteMethod_1b4ac07d NVARCHAR(10),
@IsCustom_1b4ac07d BIT,
@CreateAPIPath_1b4ac07d NVARCHAR(MAX),
@CreateMethod_1b4ac07d NVARCHAR(20),
@CreateBodyShape_1b4ac07d NVARCHAR(50),
@CreateBodyKey_1b4ac07d NVARCHAR(100),
@CreateIDLocation_1b4ac07d NVARCHAR(20),
@UpdateAPIPath_1b4ac07d NVARCHAR(MAX),
@UpdateMethod_1b4ac07d NVARCHAR(20),
@UpdateBodyShape_1b4ac07d NVARCHAR(50),
@UpdateBodyKey_1b4ac07d NVARCHAR(100),
@UpdateIDLocation_1b4ac07d NVARCHAR(20),
@DeleteAPIPath_1b4ac07d NVARCHAR(MAX),
@DeleteIDLocation_1b4ac07d NVARCHAR(20),
@IncrementalWatermarkField_1b4ac07d NVARCHAR(255),
@MetadataSource_1b4ac07d NVARCHAR(20),
@SupportsCreate_1b4ac07d BIT,
@SupportsUpdate_1b4ac07d BIT,
@SupportsDelete_1b4ac07d BIT,
@SyncStrategy_1b4ac07d NVARCHAR(50),
@ContentHashApplicable_1b4ac07d BIT,
@StableOrderingKey_1b4ac07d NVARCHAR(255)
SET
  @ID_1b4ac07d = 'C4A09B88-C6CC-54DF-8D50-0782A34D0907'
SET
  @IntegrationID_1b4ac07d = 'D2E0507F-6F7F-4C10-8493-21DAF94AE18E'
SET
  @Name_1b4ac07d = N'address'
SET
  @DisplayName_1b4ac07d = N'Address'
SET
  @Description_1b4ac07d = N'Country entries (person section). Derived from the stored record; one row per address.'
SET
  @APIPath_1b4ac07d = N'/{iD}/address'
SET
  @DefaultPageSize_1b4ac07d = 100
SET
  @SupportsPagination_1b4ac07d = 0
SET
  @PaginationType_1b4ac07d = N'None'
SET
  @SupportsIncrementalSync_1b4ac07d = 1
SET
  @SupportsWrite_1b4ac07d = 0
SET
  @Configuration_1b4ac07d = N'{"endpoint": "/{iD}/address", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}'
SET
  @Sequence_1b4ac07d = 15
SET
  @Status_1b4ac07d = N'Active'
SET
  @WriteMethod_1b4ac07d = N'POST'
SET
  @DeleteMethod_1b4ac07d = N'DELETE'
SET
  @IsCustom_1b4ac07d = 0
SET
  @IncrementalWatermarkField_1b4ac07d = N'last-modified-date'
SET
  @MetadataSource_1b4ac07d = N'Declared'
SET
  @SupportsCreate_1b4ac07d = 0
SET
  @SupportsUpdate_1b4ac07d = 0
SET
  @SupportsDelete_1b4ac07d = 0
SET
  @ContentHashApplicable_1b4ac07d = 1
EXEC [__mj].spCreateIntegrationObject @ID = @ID_1b4ac07d,
  @IntegrationID = @IntegrationID_1b4ac07d,
  @Name = @Name_1b4ac07d,
  @DisplayName = @DisplayName_1b4ac07d,
  @Description = @Description_1b4ac07d,
  @Category = @Category_1b4ac07d,
  @Category_Clear = 1,
  @APIPath = @APIPath_1b4ac07d,
  @ResponseDataKey = @ResponseDataKey_1b4ac07d,
  @ResponseDataKey_Clear = 1,
  @DefaultPageSize = @DefaultPageSize_1b4ac07d,
  @SupportsPagination = @SupportsPagination_1b4ac07d,
  @PaginationType = @PaginationType_1b4ac07d,
  @SupportsIncrementalSync = @SupportsIncrementalSync_1b4ac07d,
  @SupportsWrite = @SupportsWrite_1b4ac07d,
  @DefaultQueryParams = @DefaultQueryParams_1b4ac07d,
  @DefaultQueryParams_Clear = 1,
  @Configuration = @Configuration_1b4ac07d,
  @Sequence = @Sequence_1b4ac07d,
  @Status = @Status_1b4ac07d,
  @WriteAPIPath = @WriteAPIPath_1b4ac07d,
  @WriteAPIPath_Clear = 1,
  @WriteMethod = @WriteMethod_1b4ac07d,
  @DeleteMethod = @DeleteMethod_1b4ac07d,
  @IsCustom = @IsCustom_1b4ac07d,
  @CreateAPIPath = @CreateAPIPath_1b4ac07d,
  @CreateAPIPath_Clear = 1,
  @CreateMethod = @CreateMethod_1b4ac07d,
  @CreateMethod_Clear = 1,
  @CreateBodyShape = @CreateBodyShape_1b4ac07d,
  @CreateBodyShape_Clear = 1,
  @CreateBodyKey = @CreateBodyKey_1b4ac07d,
  @CreateBodyKey_Clear = 1,
  @CreateIDLocation = @CreateIDLocation_1b4ac07d,
  @CreateIDLocation_Clear = 1,
  @UpdateAPIPath = @UpdateAPIPath_1b4ac07d,
  @UpdateAPIPath_Clear = 1,
  @UpdateMethod = @UpdateMethod_1b4ac07d,
  @UpdateMethod_Clear = 1,
  @UpdateBodyShape = @UpdateBodyShape_1b4ac07d,
  @UpdateBodyShape_Clear = 1,
  @UpdateBodyKey = @UpdateBodyKey_1b4ac07d,
  @UpdateBodyKey_Clear = 1,
  @UpdateIDLocation = @UpdateIDLocation_1b4ac07d,
  @UpdateIDLocation_Clear = 1,
  @DeleteAPIPath = @DeleteAPIPath_1b4ac07d,
  @DeleteAPIPath_Clear = 1,
  @DeleteIDLocation = @DeleteIDLocation_1b4ac07d,
  @DeleteIDLocation_Clear = 1,
  @IncrementalWatermarkField = @IncrementalWatermarkField_1b4ac07d,
  @MetadataSource = @MetadataSource_1b4ac07d,
  @SupportsCreate = @SupportsCreate_1b4ac07d,
  @SupportsUpdate = @SupportsUpdate_1b4ac07d,
  @SupportsDelete = @SupportsDelete_1b4ac07d,
  @SyncStrategy = @SyncStrategy_1b4ac07d,
  @SyncStrategy_Clear = 1,
  @ContentHashApplicable = @ContentHashApplicable_1b4ac07d,
  @StableOrderingKey = @StableOrderingKey_1b4ac07d,
  @StableOrderingKey_Clear = 1;

GO

-- Save MJ: Integration Objects (core SP call only)
DECLARE @ID_43cce9a4 UNIQUEIDENTIFIER,
@IntegrationID_43cce9a4 UNIQUEIDENTIFIER,
@Name_43cce9a4 NVARCHAR(255),
@DisplayName_43cce9a4 NVARCHAR(255),
@Description_43cce9a4 NVARCHAR(MAX),
@Category_43cce9a4 NVARCHAR(100),
@APIPath_43cce9a4 NVARCHAR(500),
@ResponseDataKey_43cce9a4 NVARCHAR(255),
@DefaultPageSize_43cce9a4 INT,
@SupportsPagination_43cce9a4 BIT,
@PaginationType_43cce9a4 NVARCHAR(20),
@SupportsIncrementalSync_43cce9a4 BIT,
@SupportsWrite_43cce9a4 BIT,
@DefaultQueryParams_43cce9a4 NVARCHAR(MAX),
@Configuration_43cce9a4 NVARCHAR(MAX),
@Sequence_43cce9a4 INT,
@Status_43cce9a4 NVARCHAR(25),
@WriteAPIPath_43cce9a4 NVARCHAR(500),
@WriteMethod_43cce9a4 NVARCHAR(10),
@DeleteMethod_43cce9a4 NVARCHAR(10),
@IsCustom_43cce9a4 BIT,
@CreateAPIPath_43cce9a4 NVARCHAR(MAX),
@CreateMethod_43cce9a4 NVARCHAR(20),
@CreateBodyShape_43cce9a4 NVARCHAR(50),
@CreateBodyKey_43cce9a4 NVARCHAR(100),
@CreateIDLocation_43cce9a4 NVARCHAR(20),
@UpdateAPIPath_43cce9a4 NVARCHAR(MAX),
@UpdateMethod_43cce9a4 NVARCHAR(20),
@UpdateBodyShape_43cce9a4 NVARCHAR(50),
@UpdateBodyKey_43cce9a4 NVARCHAR(100),
@UpdateIDLocation_43cce9a4 NVARCHAR(20),
@DeleteAPIPath_43cce9a4 NVARCHAR(MAX),
@DeleteIDLocation_43cce9a4 NVARCHAR(20),
@IncrementalWatermarkField_43cce9a4 NVARCHAR(255),
@MetadataSource_43cce9a4 NVARCHAR(20),
@SupportsCreate_43cce9a4 BIT,
@SupportsUpdate_43cce9a4 BIT,
@SupportsDelete_43cce9a4 BIT,
@SyncStrategy_43cce9a4 NVARCHAR(50),
@ContentHashApplicable_43cce9a4 BIT,
@StableOrderingKey_43cce9a4 NVARCHAR(255)
SET
  @ID_43cce9a4 = '3F2D9F80-F35B-501D-BC52-66AF079946E5'
SET
  @IntegrationID_43cce9a4 = 'D2E0507F-6F7F-4C10-8493-21DAF94AE18E'
SET
  @Name_43cce9a4 = N'researcher-urls'
SET
  @DisplayName_43cce9a4 = N'Researcher Urls'
SET
  @Description_43cce9a4 = N'Personal and professional links the researcher added (person section). Derived from the stored record.'
SET
  @APIPath_43cce9a4 = N'/{iD}/researcher-urls'
SET
  @DefaultPageSize_43cce9a4 = 100
SET
  @SupportsPagination_43cce9a4 = 0
SET
  @PaginationType_43cce9a4 = N'None'
SET
  @SupportsIncrementalSync_43cce9a4 = 1
SET
  @SupportsWrite_43cce9a4 = 0
SET
  @Configuration_43cce9a4 = N'{"endpoint": "/{iD}/researcher-urls", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}'
SET
  @Sequence_43cce9a4 = 16
SET
  @Status_43cce9a4 = N'Active'
SET
  @WriteMethod_43cce9a4 = N'POST'
SET
  @DeleteMethod_43cce9a4 = N'DELETE'
SET
  @IsCustom_43cce9a4 = 0
SET
  @IncrementalWatermarkField_43cce9a4 = N'last-modified-date'
SET
  @MetadataSource_43cce9a4 = N'Declared'
SET
  @SupportsCreate_43cce9a4 = 0
SET
  @SupportsUpdate_43cce9a4 = 0
SET
  @SupportsDelete_43cce9a4 = 0
SET
  @ContentHashApplicable_43cce9a4 = 1
EXEC [__mj].spCreateIntegrationObject @ID = @ID_43cce9a4,
  @IntegrationID = @IntegrationID_43cce9a4,
  @Name = @Name_43cce9a4,
  @DisplayName = @DisplayName_43cce9a4,
  @Description = @Description_43cce9a4,
  @Category = @Category_43cce9a4,
  @Category_Clear = 1,
  @APIPath = @APIPath_43cce9a4,
  @ResponseDataKey = @ResponseDataKey_43cce9a4,
  @ResponseDataKey_Clear = 1,
  @DefaultPageSize = @DefaultPageSize_43cce9a4,
  @SupportsPagination = @SupportsPagination_43cce9a4,
  @PaginationType = @PaginationType_43cce9a4,
  @SupportsIncrementalSync = @SupportsIncrementalSync_43cce9a4,
  @SupportsWrite = @SupportsWrite_43cce9a4,
  @DefaultQueryParams = @DefaultQueryParams_43cce9a4,
  @DefaultQueryParams_Clear = 1,
  @Configuration = @Configuration_43cce9a4,
  @Sequence = @Sequence_43cce9a4,
  @Status = @Status_43cce9a4,
  @WriteAPIPath = @WriteAPIPath_43cce9a4,
  @WriteAPIPath_Clear = 1,
  @WriteMethod = @WriteMethod_43cce9a4,
  @DeleteMethod = @DeleteMethod_43cce9a4,
  @IsCustom = @IsCustom_43cce9a4,
  @CreateAPIPath = @CreateAPIPath_43cce9a4,
  @CreateAPIPath_Clear = 1,
  @CreateMethod = @CreateMethod_43cce9a4,
  @CreateMethod_Clear = 1,
  @CreateBodyShape = @CreateBodyShape_43cce9a4,
  @CreateBodyShape_Clear = 1,
  @CreateBodyKey = @CreateBodyKey_43cce9a4,
  @CreateBodyKey_Clear = 1,
  @CreateIDLocation = @CreateIDLocation_43cce9a4,
  @CreateIDLocation_Clear = 1,
  @UpdateAPIPath = @UpdateAPIPath_43cce9a4,
  @UpdateAPIPath_Clear = 1,
  @UpdateMethod = @UpdateMethod_43cce9a4,
  @UpdateMethod_Clear = 1,
  @UpdateBodyShape = @UpdateBodyShape_43cce9a4,
  @UpdateBodyShape_Clear = 1,
  @UpdateBodyKey = @UpdateBodyKey_43cce9a4,
  @UpdateBodyKey_Clear = 1,
  @UpdateIDLocation = @UpdateIDLocation_43cce9a4,
  @UpdateIDLocation_Clear = 1,
  @DeleteAPIPath = @DeleteAPIPath_43cce9a4,
  @DeleteAPIPath_Clear = 1,
  @DeleteIDLocation = @DeleteIDLocation_43cce9a4,
  @DeleteIDLocation_Clear = 1,
  @IncrementalWatermarkField = @IncrementalWatermarkField_43cce9a4,
  @MetadataSource = @MetadataSource_43cce9a4,
  @SupportsCreate = @SupportsCreate_43cce9a4,
  @SupportsUpdate = @SupportsUpdate_43cce9a4,
  @SupportsDelete = @SupportsDelete_43cce9a4,
  @SyncStrategy = @SyncStrategy_43cce9a4,
  @SyncStrategy_Clear = 1,
  @ContentHashApplicable = @ContentHashApplicable_43cce9a4,
  @StableOrderingKey = @StableOrderingKey_43cce9a4,
  @StableOrderingKey_Clear = 1;

GO

-- Save MJ: Integration Objects (core SP call only)
DECLARE @ID_91de9608 UNIQUEIDENTIFIER,
@IntegrationID_91de9608 UNIQUEIDENTIFIER,
@Name_91de9608 NVARCHAR(255),
@DisplayName_91de9608 NVARCHAR(255),
@Description_91de9608 NVARCHAR(MAX),
@Category_91de9608 NVARCHAR(100),
@APIPath_91de9608 NVARCHAR(500),
@ResponseDataKey_91de9608 NVARCHAR(255),
@DefaultPageSize_91de9608 INT,
@SupportsPagination_91de9608 BIT,
@PaginationType_91de9608 NVARCHAR(20),
@SupportsIncrementalSync_91de9608 BIT,
@SupportsWrite_91de9608 BIT,
@DefaultQueryParams_91de9608 NVARCHAR(MAX),
@Configuration_91de9608 NVARCHAR(MAX),
@Sequence_91de9608 INT,
@Status_91de9608 NVARCHAR(25),
@WriteAPIPath_91de9608 NVARCHAR(500),
@WriteMethod_91de9608 NVARCHAR(10),
@DeleteMethod_91de9608 NVARCHAR(10),
@IsCustom_91de9608 BIT,
@CreateAPIPath_91de9608 NVARCHAR(MAX),
@CreateMethod_91de9608 NVARCHAR(20),
@CreateBodyShape_91de9608 NVARCHAR(50),
@CreateBodyKey_91de9608 NVARCHAR(100),
@CreateIDLocation_91de9608 NVARCHAR(20),
@UpdateAPIPath_91de9608 NVARCHAR(MAX),
@UpdateMethod_91de9608 NVARCHAR(20),
@UpdateBodyShape_91de9608 NVARCHAR(50),
@UpdateBodyKey_91de9608 NVARCHAR(100),
@UpdateIDLocation_91de9608 NVARCHAR(20),
@DeleteAPIPath_91de9608 NVARCHAR(MAX),
@DeleteIDLocation_91de9608 NVARCHAR(20),
@IncrementalWatermarkField_91de9608 NVARCHAR(255),
@MetadataSource_91de9608 NVARCHAR(20),
@SupportsCreate_91de9608 BIT,
@SupportsUpdate_91de9608 BIT,
@SupportsDelete_91de9608 BIT,
@SyncStrategy_91de9608 NVARCHAR(50),
@ContentHashApplicable_91de9608 BIT,
@StableOrderingKey_91de9608 NVARCHAR(255)
SET
  @ID_91de9608 = '224D74C1-460F-5612-BD7D-29027DF76792'
SET
  @IntegrationID_91de9608 = 'D2E0507F-6F7F-4C10-8493-21DAF94AE18E'
SET
  @Name_91de9608 = N'external-identifiers'
SET
  @DisplayName_91de9608 = N'External Identifiers'
SET
  @Description_91de9608 = N'Person-level identifiers on other systems: Scopus Author ID, ResearcherID, Loop, ... (person section). Derived from the stored record.'
SET
  @APIPath_91de9608 = N'/{iD}/external-identifiers'
SET
  @DefaultPageSize_91de9608 = 100
SET
  @SupportsPagination_91de9608 = 0
SET
  @PaginationType_91de9608 = N'None'
SET
  @SupportsIncrementalSync_91de9608 = 1
SET
  @SupportsWrite_91de9608 = 0
SET
  @Configuration_91de9608 = N'{"endpoint": "/{iD}/external-identifiers", "fetchModel": "derived from the stored /record (activities-summary / person); no per-section API call", "watermark": "last-modified-date", "nonEnumerable": true, "scopedBy": "CompanyIntegration.Configuration.searchQuery / orcidIds"}'
SET
  @Sequence_91de9608 = 17
SET
  @Status_91de9608 = N'Active'
SET
  @WriteMethod_91de9608 = N'POST'
SET
  @DeleteMethod_91de9608 = N'DELETE'
SET
  @IsCustom_91de9608 = 0
SET
  @IncrementalWatermarkField_91de9608 = N'last-modified-date'
SET
  @MetadataSource_91de9608 = N'Declared'
SET
  @SupportsCreate_91de9608 = 0
SET
  @SupportsUpdate_91de9608 = 0
SET
  @SupportsDelete_91de9608 = 0
SET
  @ContentHashApplicable_91de9608 = 1
EXEC [__mj].spCreateIntegrationObject @ID = @ID_91de9608,
  @IntegrationID = @IntegrationID_91de9608,
  @Name = @Name_91de9608,
  @DisplayName = @DisplayName_91de9608,
  @Description = @Description_91de9608,
  @Category = @Category_91de9608,
  @Category_Clear = 1,
  @APIPath = @APIPath_91de9608,
  @ResponseDataKey = @ResponseDataKey_91de9608,
  @ResponseDataKey_Clear = 1,
  @DefaultPageSize = @DefaultPageSize_91de9608,
  @SupportsPagination = @SupportsPagination_91de9608,
  @PaginationType = @PaginationType_91de9608,
  @SupportsIncrementalSync = @SupportsIncrementalSync_91de9608,
  @SupportsWrite = @SupportsWrite_91de9608,
  @DefaultQueryParams = @DefaultQueryParams_91de9608,
  @DefaultQueryParams_Clear = 1,
  @Configuration = @Configuration_91de9608,
  @Sequence = @Sequence_91de9608,
  @Status = @Status_91de9608,
  @WriteAPIPath = @WriteAPIPath_91de9608,
  @WriteAPIPath_Clear = 1,
  @WriteMethod = @WriteMethod_91de9608,
  @DeleteMethod = @DeleteMethod_91de9608,
  @IsCustom = @IsCustom_91de9608,
  @CreateAPIPath = @CreateAPIPath_91de9608,
  @CreateAPIPath_Clear = 1,
  @CreateMethod = @CreateMethod_91de9608,
  @CreateMethod_Clear = 1,
  @CreateBodyShape = @CreateBodyShape_91de9608,
  @CreateBodyShape_Clear = 1,
  @CreateBodyKey = @CreateBodyKey_91de9608,
  @CreateBodyKey_Clear = 1,
  @CreateIDLocation = @CreateIDLocation_91de9608,
  @CreateIDLocation_Clear = 1,
  @UpdateAPIPath = @UpdateAPIPath_91de9608,
  @UpdateAPIPath_Clear = 1,
  @UpdateMethod = @UpdateMethod_91de9608,
  @UpdateMethod_Clear = 1,
  @UpdateBodyShape = @UpdateBodyShape_91de9608,
  @UpdateBodyShape_Clear = 1,
  @UpdateBodyKey = @UpdateBodyKey_91de9608,
  @UpdateBodyKey_Clear = 1,
  @UpdateIDLocation = @UpdateIDLocation_91de9608,
  @UpdateIDLocation_Clear = 1,
  @DeleteAPIPath = @DeleteAPIPath_91de9608,
  @DeleteAPIPath_Clear = 1,
  @DeleteIDLocation = @DeleteIDLocation_91de9608,
  @DeleteIDLocation_Clear = 1,
  @IncrementalWatermarkField = @IncrementalWatermarkField_91de9608,
  @MetadataSource = @MetadataSource_91de9608,
  @SupportsCreate = @SupportsCreate_91de9608,
  @SupportsUpdate = @SupportsUpdate_91de9608,
  @SupportsDelete = @SupportsDelete_91de9608,
  @SyncStrategy = @SyncStrategy_91de9608,
  @SyncStrategy_Clear = 1,
  @ContentHashApplicable = @ContentHashApplicable_91de9608,
  @StableOrderingKey = @StableOrderingKey_91de9608,
  @StableOrderingKey_Clear = 1;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_82db57a4 UNIQUEIDENTIFIER,
@IntegrationObjectID_82db57a4 UNIQUEIDENTIFIER,
@Name_82db57a4 NVARCHAR(255),
@DisplayName_82db57a4 NVARCHAR(255),
@Description_82db57a4 NVARCHAR(MAX),
@Category_82db57a4 NVARCHAR(100),
@Type_82db57a4 NVARCHAR(100),
@Length_82db57a4 INT,
@Precision_82db57a4 INT,
@Scale_82db57a4 INT,
@AllowsNull_82db57a4 BIT,
@DefaultValue_82db57a4 NVARCHAR(255),
@IsPrimaryKey_82db57a4 BIT,
@IsUniqueKey_82db57a4 BIT,
@IsReadOnly_82db57a4 BIT,
@IsRequired_82db57a4 BIT,
@RelatedIntegrationObjectID_82db57a4 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_82db57a4 NVARCHAR(255),
@Sequence_82db57a4 INT,
@Configuration_82db57a4 NVARCHAR(MAX),
@Status_82db57a4 NVARCHAR(25),
@IsCustom_82db57a4 BIT,
@MetadataSource_82db57a4 NVARCHAR(20)
SET
  @ID_82db57a4 = '57E6E91A-EF2B-52AD-A425-6B3514804E52'
SET
  @IntegrationObjectID_82db57a4 = '73AED6B8-468D-403B-B994-F3C786C98BC0'
SET
  @Name_82db57a4 = N'activities-summary'
SET
  @DisplayName_82db57a4 = N'Activities Summary'
SET
  @Description_82db57a4 = N'The activities-summary block of the record: every activity section summary (works, employments, fundings, peer-reviews, ...). Stored so the section objects derive from it with no further API call.'
SET
  @Type_82db57a4 = N'json'
SET
  @AllowsNull_82db57a4 = 1
SET
  @IsPrimaryKey_82db57a4 = 0
SET
  @IsUniqueKey_82db57a4 = 0
SET
  @IsReadOnly_82db57a4 = 1
SET
  @IsRequired_82db57a4 = 0
SET
  @Sequence_82db57a4 = 19
SET
  @Status_82db57a4 = N'Active'
SET
  @IsCustom_82db57a4 = 0
SET
  @MetadataSource_82db57a4 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_82db57a4,
  @IntegrationObjectID = @IntegrationObjectID_82db57a4,
  @Name = @Name_82db57a4,
  @DisplayName = @DisplayName_82db57a4,
  @Description = @Description_82db57a4,
  @Category = @Category_82db57a4,
  @Category_Clear = 1,
  @Type = @Type_82db57a4,
  @Length = @Length_82db57a4,
  @Length_Clear = 1,
  @Precision = @Precision_82db57a4,
  @Precision_Clear = 1,
  @Scale = @Scale_82db57a4,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_82db57a4,
  @DefaultValue = @DefaultValue_82db57a4,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_82db57a4,
  @IsUniqueKey = @IsUniqueKey_82db57a4,
  @IsReadOnly = @IsReadOnly_82db57a4,
  @IsRequired = @IsRequired_82db57a4,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_82db57a4,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_82db57a4,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_82db57a4,
  @Configuration = @Configuration_82db57a4,
  @Configuration_Clear = 1,
  @Status = @Status_82db57a4,
  @IsCustom = @IsCustom_82db57a4,
  @MetadataSource = @MetadataSource_82db57a4;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_73558386 UNIQUEIDENTIFIER,
@IntegrationObjectID_73558386 UNIQUEIDENTIFIER,
@Name_73558386 NVARCHAR(255),
@DisplayName_73558386 NVARCHAR(255),
@Description_73558386 NVARCHAR(MAX),
@Category_73558386 NVARCHAR(100),
@Type_73558386 NVARCHAR(100),
@Length_73558386 INT,
@Precision_73558386 INT,
@Scale_73558386 INT,
@AllowsNull_73558386 BIT,
@DefaultValue_73558386 NVARCHAR(255),
@IsPrimaryKey_73558386 BIT,
@IsUniqueKey_73558386 BIT,
@IsReadOnly_73558386 BIT,
@IsRequired_73558386 BIT,
@RelatedIntegrationObjectID_73558386 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_73558386 NVARCHAR(255),
@Sequence_73558386 INT,
@Configuration_73558386 NVARCHAR(MAX),
@Status_73558386 NVARCHAR(25),
@IsCustom_73558386 BIT,
@MetadataSource_73558386 NVARCHAR(20)
SET
  @ID_73558386 = '2B780865-8166-5EDF-801A-CB7206C1C774'
SET
  @IntegrationObjectID_73558386 = '1D853840-A875-41E9-AB35-940345EF1434'
SET
  @Name_73558386 = N'work-title'
SET
  @DisplayName_73558386 = N'Work Title'
SET
  @Description_73558386 = N'Title of the work. Lifted from title.title.'
SET
  @Type_73558386 = N'String'
SET
  @Length_73558386 = 2000
SET
  @AllowsNull_73558386 = 1
SET
  @IsPrimaryKey_73558386 = 0
SET
  @IsUniqueKey_73558386 = 0
SET
  @IsReadOnly_73558386 = 1
SET
  @IsRequired_73558386 = 0
SET
  @Sequence_73558386 = 19
SET
  @Status_73558386 = N'Active'
SET
  @IsCustom_73558386 = 0
SET
  @MetadataSource_73558386 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_73558386,
  @IntegrationObjectID = @IntegrationObjectID_73558386,
  @Name = @Name_73558386,
  @DisplayName = @DisplayName_73558386,
  @Description = @Description_73558386,
  @Category = @Category_73558386,
  @Category_Clear = 1,
  @Type = @Type_73558386,
  @Length = @Length_73558386,
  @Precision = @Precision_73558386,
  @Precision_Clear = 1,
  @Scale = @Scale_73558386,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_73558386,
  @DefaultValue = @DefaultValue_73558386,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_73558386,
  @IsUniqueKey = @IsUniqueKey_73558386,
  @IsReadOnly = @IsReadOnly_73558386,
  @IsRequired = @IsRequired_73558386,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_73558386,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_73558386,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_73558386,
  @Configuration = @Configuration_73558386,
  @Configuration_Clear = 1,
  @Status = @Status_73558386,
  @IsCustom = @IsCustom_73558386,
  @MetadataSource = @MetadataSource_73558386;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_18ece38a UNIQUEIDENTIFIER,
@IntegrationObjectID_18ece38a UNIQUEIDENTIFIER,
@Name_18ece38a NVARCHAR(255),
@DisplayName_18ece38a NVARCHAR(255),
@Description_18ece38a NVARCHAR(MAX),
@Category_18ece38a NVARCHAR(100),
@Type_18ece38a NVARCHAR(100),
@Length_18ece38a INT,
@Precision_18ece38a INT,
@Scale_18ece38a INT,
@AllowsNull_18ece38a BIT,
@DefaultValue_18ece38a NVARCHAR(255),
@IsPrimaryKey_18ece38a BIT,
@IsUniqueKey_18ece38a BIT,
@IsReadOnly_18ece38a BIT,
@IsRequired_18ece38a BIT,
@RelatedIntegrationObjectID_18ece38a UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_18ece38a NVARCHAR(255),
@Sequence_18ece38a INT,
@Configuration_18ece38a NVARCHAR(MAX),
@Status_18ece38a NVARCHAR(25),
@IsCustom_18ece38a BIT,
@MetadataSource_18ece38a NVARCHAR(20)
SET
  @ID_18ece38a = '3D2EF4EF-2897-5880-A217-3A2EC3FDFF36'
SET
  @IntegrationObjectID_18ece38a = '1D853840-A875-41E9-AB35-940345EF1434'
SET
  @Name_18ece38a = N'work-subtitle'
SET
  @DisplayName_18ece38a = N'Work Subtitle'
SET
  @Description_18ece38a = N'Subtitle of the work. Lifted from title.subtitle.'
SET
  @Type_18ece38a = N'String'
SET
  @Length_18ece38a = 2000
SET
  @AllowsNull_18ece38a = 1
SET
  @IsPrimaryKey_18ece38a = 0
SET
  @IsUniqueKey_18ece38a = 0
SET
  @IsReadOnly_18ece38a = 1
SET
  @IsRequired_18ece38a = 0
SET
  @Sequence_18ece38a = 20
SET
  @Status_18ece38a = N'Active'
SET
  @IsCustom_18ece38a = 0
SET
  @MetadataSource_18ece38a = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_18ece38a,
  @IntegrationObjectID = @IntegrationObjectID_18ece38a,
  @Name = @Name_18ece38a,
  @DisplayName = @DisplayName_18ece38a,
  @Description = @Description_18ece38a,
  @Category = @Category_18ece38a,
  @Category_Clear = 1,
  @Type = @Type_18ece38a,
  @Length = @Length_18ece38a,
  @Precision = @Precision_18ece38a,
  @Precision_Clear = 1,
  @Scale = @Scale_18ece38a,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_18ece38a,
  @DefaultValue = @DefaultValue_18ece38a,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_18ece38a,
  @IsUniqueKey = @IsUniqueKey_18ece38a,
  @IsReadOnly = @IsReadOnly_18ece38a,
  @IsRequired = @IsRequired_18ece38a,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_18ece38a,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_18ece38a,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_18ece38a,
  @Configuration = @Configuration_18ece38a,
  @Configuration_Clear = 1,
  @Status = @Status_18ece38a,
  @IsCustom = @IsCustom_18ece38a,
  @MetadataSource = @MetadataSource_18ece38a;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_8b08683a UNIQUEIDENTIFIER,
@IntegrationObjectID_8b08683a UNIQUEIDENTIFIER,
@Name_8b08683a NVARCHAR(255),
@DisplayName_8b08683a NVARCHAR(255),
@Description_8b08683a NVARCHAR(MAX),
@Category_8b08683a NVARCHAR(100),
@Type_8b08683a NVARCHAR(100),
@Length_8b08683a INT,
@Precision_8b08683a INT,
@Scale_8b08683a INT,
@AllowsNull_8b08683a BIT,
@DefaultValue_8b08683a NVARCHAR(255),
@IsPrimaryKey_8b08683a BIT,
@IsUniqueKey_8b08683a BIT,
@IsReadOnly_8b08683a BIT,
@IsRequired_8b08683a BIT,
@RelatedIntegrationObjectID_8b08683a UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_8b08683a NVARCHAR(255),
@Sequence_8b08683a INT,
@Configuration_8b08683a NVARCHAR(MAX),
@Status_8b08683a NVARCHAR(25),
@IsCustom_8b08683a BIT,
@MetadataSource_8b08683a NVARCHAR(20)
SET
  @ID_8b08683a = '059C4CC3-53C1-5CFD-BB36-50AC18921C7B'
SET
  @IntegrationObjectID_8b08683a = '1D853840-A875-41E9-AB35-940345EF1434'
SET
  @Name_8b08683a = N'translated-title'
SET
  @DisplayName_8b08683a = N'Translated Title'
SET
  @Description_8b08683a = N'Translated title of the work. Lifted from title.translated-title.'
SET
  @Type_8b08683a = N'String'
SET
  @Length_8b08683a = 2000
SET
  @AllowsNull_8b08683a = 1
SET
  @IsPrimaryKey_8b08683a = 0
SET
  @IsUniqueKey_8b08683a = 0
SET
  @IsReadOnly_8b08683a = 1
SET
  @IsRequired_8b08683a = 0
SET
  @Sequence_8b08683a = 21
SET
  @Status_8b08683a = N'Active'
SET
  @IsCustom_8b08683a = 0
SET
  @MetadataSource_8b08683a = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_8b08683a,
  @IntegrationObjectID = @IntegrationObjectID_8b08683a,
  @Name = @Name_8b08683a,
  @DisplayName = @DisplayName_8b08683a,
  @Description = @Description_8b08683a,
  @Category = @Category_8b08683a,
  @Category_Clear = 1,
  @Type = @Type_8b08683a,
  @Length = @Length_8b08683a,
  @Precision = @Precision_8b08683a,
  @Precision_Clear = 1,
  @Scale = @Scale_8b08683a,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_8b08683a,
  @DefaultValue = @DefaultValue_8b08683a,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_8b08683a,
  @IsUniqueKey = @IsUniqueKey_8b08683a,
  @IsReadOnly = @IsReadOnly_8b08683a,
  @IsRequired = @IsRequired_8b08683a,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_8b08683a,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_8b08683a,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_8b08683a,
  @Configuration = @Configuration_8b08683a,
  @Configuration_Clear = 1,
  @Status = @Status_8b08683a,
  @IsCustom = @IsCustom_8b08683a,
  @MetadataSource = @MetadataSource_8b08683a;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_a20ede7e UNIQUEIDENTIFIER,
@IntegrationObjectID_a20ede7e UNIQUEIDENTIFIER,
@Name_a20ede7e NVARCHAR(255),
@DisplayName_a20ede7e NVARCHAR(255),
@Description_a20ede7e NVARCHAR(MAX),
@Category_a20ede7e NVARCHAR(100),
@Type_a20ede7e NVARCHAR(100),
@Length_a20ede7e INT,
@Precision_a20ede7e INT,
@Scale_a20ede7e INT,
@AllowsNull_a20ede7e BIT,
@DefaultValue_a20ede7e NVARCHAR(255),
@IsPrimaryKey_a20ede7e BIT,
@IsUniqueKey_a20ede7e BIT,
@IsReadOnly_a20ede7e BIT,
@IsRequired_a20ede7e BIT,
@RelatedIntegrationObjectID_a20ede7e UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_a20ede7e NVARCHAR(255),
@Sequence_a20ede7e INT,
@Configuration_a20ede7e NVARCHAR(MAX),
@Status_a20ede7e NVARCHAR(25),
@IsCustom_a20ede7e BIT,
@MetadataSource_a20ede7e NVARCHAR(20)
SET
  @ID_a20ede7e = '94482953-F3BC-51BF-B4FA-35F20C3C7A99'
SET
  @IntegrationObjectID_a20ede7e = '1D853840-A875-41E9-AB35-940345EF1434'
SET
  @Name_a20ede7e = N'publication-year'
SET
  @DisplayName_a20ede7e = N'Publication Year'
SET
  @Description_a20ede7e = N'Year of the publication date; ORCID dates are partial, so month/day may be absent.'
SET
  @Type_a20ede7e = N'Integer'
SET
  @AllowsNull_a20ede7e = 1
SET
  @IsPrimaryKey_a20ede7e = 0
SET
  @IsUniqueKey_a20ede7e = 0
SET
  @IsReadOnly_a20ede7e = 1
SET
  @IsRequired_a20ede7e = 0
SET
  @Sequence_a20ede7e = 22
SET
  @Status_a20ede7e = N'Active'
SET
  @IsCustom_a20ede7e = 0
SET
  @MetadataSource_a20ede7e = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_a20ede7e,
  @IntegrationObjectID = @IntegrationObjectID_a20ede7e,
  @Name = @Name_a20ede7e,
  @DisplayName = @DisplayName_a20ede7e,
  @Description = @Description_a20ede7e,
  @Category = @Category_a20ede7e,
  @Category_Clear = 1,
  @Type = @Type_a20ede7e,
  @Length = @Length_a20ede7e,
  @Length_Clear = 1,
  @Precision = @Precision_a20ede7e,
  @Precision_Clear = 1,
  @Scale = @Scale_a20ede7e,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_a20ede7e,
  @DefaultValue = @DefaultValue_a20ede7e,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_a20ede7e,
  @IsUniqueKey = @IsUniqueKey_a20ede7e,
  @IsReadOnly = @IsReadOnly_a20ede7e,
  @IsRequired = @IsRequired_a20ede7e,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_a20ede7e,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_a20ede7e,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_a20ede7e,
  @Configuration = @Configuration_a20ede7e,
  @Configuration_Clear = 1,
  @Status = @Status_a20ede7e,
  @IsCustom = @IsCustom_a20ede7e,
  @MetadataSource = @MetadataSource_a20ede7e;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_4144a853 UNIQUEIDENTIFIER,
@IntegrationObjectID_4144a853 UNIQUEIDENTIFIER,
@Name_4144a853 NVARCHAR(255),
@DisplayName_4144a853 NVARCHAR(255),
@Description_4144a853 NVARCHAR(MAX),
@Category_4144a853 NVARCHAR(100),
@Type_4144a853 NVARCHAR(100),
@Length_4144a853 INT,
@Precision_4144a853 INT,
@Scale_4144a853 INT,
@AllowsNull_4144a853 BIT,
@DefaultValue_4144a853 NVARCHAR(255),
@IsPrimaryKey_4144a853 BIT,
@IsUniqueKey_4144a853 BIT,
@IsReadOnly_4144a853 BIT,
@IsRequired_4144a853 BIT,
@RelatedIntegrationObjectID_4144a853 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_4144a853 NVARCHAR(255),
@Sequence_4144a853 INT,
@Configuration_4144a853 NVARCHAR(MAX),
@Status_4144a853 NVARCHAR(25),
@IsCustom_4144a853 BIT,
@MetadataSource_4144a853 NVARCHAR(20)
SET
  @ID_4144a853 = '149CA198-9C7D-5899-906B-0583B2348A05'
SET
  @IntegrationObjectID_4144a853 = '1D853840-A875-41E9-AB35-940345EF1434'
SET
  @Name_4144a853 = N'publication-month'
SET
  @DisplayName_4144a853 = N'Publication Month'
SET
  @Description_4144a853 = N'Month (1-12) of the publication date, when given.'
SET
  @Type_4144a853 = N'Integer'
SET
  @AllowsNull_4144a853 = 1
SET
  @IsPrimaryKey_4144a853 = 0
SET
  @IsUniqueKey_4144a853 = 0
SET
  @IsReadOnly_4144a853 = 1
SET
  @IsRequired_4144a853 = 0
SET
  @Sequence_4144a853 = 23
SET
  @Status_4144a853 = N'Active'
SET
  @IsCustom_4144a853 = 0
SET
  @MetadataSource_4144a853 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_4144a853,
  @IntegrationObjectID = @IntegrationObjectID_4144a853,
  @Name = @Name_4144a853,
  @DisplayName = @DisplayName_4144a853,
  @Description = @Description_4144a853,
  @Category = @Category_4144a853,
  @Category_Clear = 1,
  @Type = @Type_4144a853,
  @Length = @Length_4144a853,
  @Length_Clear = 1,
  @Precision = @Precision_4144a853,
  @Precision_Clear = 1,
  @Scale = @Scale_4144a853,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_4144a853,
  @DefaultValue = @DefaultValue_4144a853,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_4144a853,
  @IsUniqueKey = @IsUniqueKey_4144a853,
  @IsReadOnly = @IsReadOnly_4144a853,
  @IsRequired = @IsRequired_4144a853,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_4144a853,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_4144a853,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_4144a853,
  @Configuration = @Configuration_4144a853,
  @Configuration_Clear = 1,
  @Status = @Status_4144a853,
  @IsCustom = @IsCustom_4144a853,
  @MetadataSource = @MetadataSource_4144a853;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_a2c1513f UNIQUEIDENTIFIER,
@IntegrationObjectID_a2c1513f UNIQUEIDENTIFIER,
@Name_a2c1513f NVARCHAR(255),
@DisplayName_a2c1513f NVARCHAR(255),
@Description_a2c1513f NVARCHAR(MAX),
@Category_a2c1513f NVARCHAR(100),
@Type_a2c1513f NVARCHAR(100),
@Length_a2c1513f INT,
@Precision_a2c1513f INT,
@Scale_a2c1513f INT,
@AllowsNull_a2c1513f BIT,
@DefaultValue_a2c1513f NVARCHAR(255),
@IsPrimaryKey_a2c1513f BIT,
@IsUniqueKey_a2c1513f BIT,
@IsReadOnly_a2c1513f BIT,
@IsRequired_a2c1513f BIT,
@RelatedIntegrationObjectID_a2c1513f UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_a2c1513f NVARCHAR(255),
@Sequence_a2c1513f INT,
@Configuration_a2c1513f NVARCHAR(MAX),
@Status_a2c1513f NVARCHAR(25),
@IsCustom_a2c1513f BIT,
@MetadataSource_a2c1513f NVARCHAR(20)
SET
  @ID_a2c1513f = 'A0F30C05-D174-513C-8962-DA4E32BC8285'
SET
  @IntegrationObjectID_a2c1513f = '1D853840-A875-41E9-AB35-940345EF1434'
SET
  @Name_a2c1513f = N'publication-day'
SET
  @DisplayName_a2c1513f = N'Publication Day'
SET
  @Description_a2c1513f = N'Day of month of the publication date, when given.'
SET
  @Type_a2c1513f = N'Integer'
SET
  @AllowsNull_a2c1513f = 1
SET
  @IsPrimaryKey_a2c1513f = 0
SET
  @IsUniqueKey_a2c1513f = 0
SET
  @IsReadOnly_a2c1513f = 1
SET
  @IsRequired_a2c1513f = 0
SET
  @Sequence_a2c1513f = 24
SET
  @Status_a2c1513f = N'Active'
SET
  @IsCustom_a2c1513f = 0
SET
  @MetadataSource_a2c1513f = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_a2c1513f,
  @IntegrationObjectID = @IntegrationObjectID_a2c1513f,
  @Name = @Name_a2c1513f,
  @DisplayName = @DisplayName_a2c1513f,
  @Description = @Description_a2c1513f,
  @Category = @Category_a2c1513f,
  @Category_Clear = 1,
  @Type = @Type_a2c1513f,
  @Length = @Length_a2c1513f,
  @Length_Clear = 1,
  @Precision = @Precision_a2c1513f,
  @Precision_Clear = 1,
  @Scale = @Scale_a2c1513f,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_a2c1513f,
  @DefaultValue = @DefaultValue_a2c1513f,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_a2c1513f,
  @IsUniqueKey = @IsUniqueKey_a2c1513f,
  @IsReadOnly = @IsReadOnly_a2c1513f,
  @IsRequired = @IsRequired_a2c1513f,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_a2c1513f,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_a2c1513f,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_a2c1513f,
  @Configuration = @Configuration_a2c1513f,
  @Configuration_Clear = 1,
  @Status = @Status_a2c1513f,
  @IsCustom = @IsCustom_a2c1513f,
  @MetadataSource = @MetadataSource_a2c1513f;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_2bc11c41 UNIQUEIDENTIFIER,
@IntegrationObjectID_2bc11c41 UNIQUEIDENTIFIER,
@Name_2bc11c41 NVARCHAR(255),
@DisplayName_2bc11c41 NVARCHAR(255),
@Description_2bc11c41 NVARCHAR(MAX),
@Category_2bc11c41 NVARCHAR(100),
@Type_2bc11c41 NVARCHAR(100),
@Length_2bc11c41 INT,
@Precision_2bc11c41 INT,
@Scale_2bc11c41 INT,
@AllowsNull_2bc11c41 BIT,
@DefaultValue_2bc11c41 NVARCHAR(255),
@IsPrimaryKey_2bc11c41 BIT,
@IsUniqueKey_2bc11c41 BIT,
@IsReadOnly_2bc11c41 BIT,
@IsRequired_2bc11c41 BIT,
@RelatedIntegrationObjectID_2bc11c41 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_2bc11c41 NVARCHAR(255),
@Sequence_2bc11c41 INT,
@Configuration_2bc11c41 NVARCHAR(MAX),
@Status_2bc11c41 NVARCHAR(25),
@IsCustom_2bc11c41 BIT,
@MetadataSource_2bc11c41 NVARCHAR(20)
SET
  @ID_2bc11c41 = '1DA63CDC-78A2-5203-BE30-85BAA70FDAB9'
SET
  @IntegrationObjectID_2bc11c41 = '1D853840-A875-41E9-AB35-940345EF1434'
SET
  @Name_2bc11c41 = N'source-name'
SET
  @DisplayName_2bc11c41 = N'Source Name'
SET
  @Description_2bc11c41 = N'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.'
SET
  @Type_2bc11c41 = N'String'
SET
  @Length_2bc11c41 = 500
SET
  @AllowsNull_2bc11c41 = 1
SET
  @IsPrimaryKey_2bc11c41 = 0
SET
  @IsUniqueKey_2bc11c41 = 0
SET
  @IsReadOnly_2bc11c41 = 1
SET
  @IsRequired_2bc11c41 = 0
SET
  @Sequence_2bc11c41 = 25
SET
  @Status_2bc11c41 = N'Active'
SET
  @IsCustom_2bc11c41 = 0
SET
  @MetadataSource_2bc11c41 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_2bc11c41,
  @IntegrationObjectID = @IntegrationObjectID_2bc11c41,
  @Name = @Name_2bc11c41,
  @DisplayName = @DisplayName_2bc11c41,
  @Description = @Description_2bc11c41,
  @Category = @Category_2bc11c41,
  @Category_Clear = 1,
  @Type = @Type_2bc11c41,
  @Length = @Length_2bc11c41,
  @Precision = @Precision_2bc11c41,
  @Precision_Clear = 1,
  @Scale = @Scale_2bc11c41,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_2bc11c41,
  @DefaultValue = @DefaultValue_2bc11c41,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_2bc11c41,
  @IsUniqueKey = @IsUniqueKey_2bc11c41,
  @IsReadOnly = @IsReadOnly_2bc11c41,
  @IsRequired = @IsRequired_2bc11c41,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_2bc11c41,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_2bc11c41,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_2bc11c41,
  @Configuration = @Configuration_2bc11c41,
  @Configuration_Clear = 1,
  @Status = @Status_2bc11c41,
  @IsCustom = @IsCustom_2bc11c41,
  @MetadataSource = @MetadataSource_2bc11c41;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_1b6e9612 UNIQUEIDENTIFIER,
@IntegrationObjectID_1b6e9612 UNIQUEIDENTIFIER,
@Name_1b6e9612 NVARCHAR(255),
@DisplayName_1b6e9612 NVARCHAR(255),
@Description_1b6e9612 NVARCHAR(MAX),
@Category_1b6e9612 NVARCHAR(100),
@Type_1b6e9612 NVARCHAR(100),
@Length_1b6e9612 INT,
@Precision_1b6e9612 INT,
@Scale_1b6e9612 INT,
@AllowsNull_1b6e9612 BIT,
@DefaultValue_1b6e9612 NVARCHAR(255),
@IsPrimaryKey_1b6e9612 BIT,
@IsUniqueKey_1b6e9612 BIT,
@IsReadOnly_1b6e9612 BIT,
@IsRequired_1b6e9612 BIT,
@RelatedIntegrationObjectID_1b6e9612 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_1b6e9612 NVARCHAR(255),
@Sequence_1b6e9612 INT,
@Configuration_1b6e9612 NVARCHAR(MAX),
@Status_1b6e9612 NVARCHAR(25),
@IsCustom_1b6e9612 BIT,
@MetadataSource_1b6e9612 NVARCHAR(20)
SET
  @ID_1b6e9612 = '5AA4284D-D642-5C9A-B8E8-EBFFC76F5353'
SET
  @IntegrationObjectID_1b6e9612 = '1D853840-A875-41E9-AB35-940345EF1434'
SET
  @Name_1b6e9612 = N'source-orcid'
SET
  @DisplayName_1b6e9612 = N'Source Orcid'
SET
  @Description_1b6e9612 = N'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.'
SET
  @Type_1b6e9612 = N'String'
SET
  @Length_1b6e9612 = 19
SET
  @AllowsNull_1b6e9612 = 1
SET
  @IsPrimaryKey_1b6e9612 = 0
SET
  @IsUniqueKey_1b6e9612 = 0
SET
  @IsReadOnly_1b6e9612 = 1
SET
  @IsRequired_1b6e9612 = 0
SET
  @Sequence_1b6e9612 = 26
SET
  @Status_1b6e9612 = N'Active'
SET
  @IsCustom_1b6e9612 = 0
SET
  @MetadataSource_1b6e9612 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_1b6e9612,
  @IntegrationObjectID = @IntegrationObjectID_1b6e9612,
  @Name = @Name_1b6e9612,
  @DisplayName = @DisplayName_1b6e9612,
  @Description = @Description_1b6e9612,
  @Category = @Category_1b6e9612,
  @Category_Clear = 1,
  @Type = @Type_1b6e9612,
  @Length = @Length_1b6e9612,
  @Precision = @Precision_1b6e9612,
  @Precision_Clear = 1,
  @Scale = @Scale_1b6e9612,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_1b6e9612,
  @DefaultValue = @DefaultValue_1b6e9612,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_1b6e9612,
  @IsUniqueKey = @IsUniqueKey_1b6e9612,
  @IsReadOnly = @IsReadOnly_1b6e9612,
  @IsRequired = @IsRequired_1b6e9612,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_1b6e9612,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_1b6e9612,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_1b6e9612,
  @Configuration = @Configuration_1b6e9612,
  @Configuration_Clear = 1,
  @Status = @Status_1b6e9612,
  @IsCustom = @IsCustom_1b6e9612,
  @MetadataSource = @MetadataSource_1b6e9612;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_981a15ed UNIQUEIDENTIFIER,
@IntegrationObjectID_981a15ed UNIQUEIDENTIFIER,
@Name_981a15ed NVARCHAR(255),
@DisplayName_981a15ed NVARCHAR(255),
@Description_981a15ed NVARCHAR(MAX),
@Category_981a15ed NVARCHAR(100),
@Type_981a15ed NVARCHAR(100),
@Length_981a15ed INT,
@Precision_981a15ed INT,
@Scale_981a15ed INT,
@AllowsNull_981a15ed BIT,
@DefaultValue_981a15ed NVARCHAR(255),
@IsPrimaryKey_981a15ed BIT,
@IsUniqueKey_981a15ed BIT,
@IsReadOnly_981a15ed BIT,
@IsRequired_981a15ed BIT,
@RelatedIntegrationObjectID_981a15ed UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_981a15ed NVARCHAR(255),
@Sequence_981a15ed INT,
@Configuration_981a15ed NVARCHAR(MAX),
@Status_981a15ed NVARCHAR(25),
@IsCustom_981a15ed BIT,
@MetadataSource_981a15ed NVARCHAR(20)
SET
  @ID_981a15ed = '5CA9A20B-EC7B-52EF-A582-C8303250338C'
SET
  @IntegrationObjectID_981a15ed = '5F90FE9B-3498-4DC2-A188-6173B8EA842B'
SET
  @Name_981a15ed = N'start-year'
SET
  @DisplayName_981a15ed = N'Start Year'
SET
  @Description_981a15ed = N'Year of the affiliation start date; ORCID dates are partial, so month/day may be absent.'
SET
  @Type_981a15ed = N'Integer'
SET
  @AllowsNull_981a15ed = 1
SET
  @IsPrimaryKey_981a15ed = 0
SET
  @IsUniqueKey_981a15ed = 0
SET
  @IsReadOnly_981a15ed = 1
SET
  @IsRequired_981a15ed = 0
SET
  @Sequence_981a15ed = 15
SET
  @Status_981a15ed = N'Active'
SET
  @IsCustom_981a15ed = 0
SET
  @MetadataSource_981a15ed = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_981a15ed,
  @IntegrationObjectID = @IntegrationObjectID_981a15ed,
  @Name = @Name_981a15ed,
  @DisplayName = @DisplayName_981a15ed,
  @Description = @Description_981a15ed,
  @Category = @Category_981a15ed,
  @Category_Clear = 1,
  @Type = @Type_981a15ed,
  @Length = @Length_981a15ed,
  @Length_Clear = 1,
  @Precision = @Precision_981a15ed,
  @Precision_Clear = 1,
  @Scale = @Scale_981a15ed,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_981a15ed,
  @DefaultValue = @DefaultValue_981a15ed,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_981a15ed,
  @IsUniqueKey = @IsUniqueKey_981a15ed,
  @IsReadOnly = @IsReadOnly_981a15ed,
  @IsRequired = @IsRequired_981a15ed,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_981a15ed,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_981a15ed,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_981a15ed,
  @Configuration = @Configuration_981a15ed,
  @Configuration_Clear = 1,
  @Status = @Status_981a15ed,
  @IsCustom = @IsCustom_981a15ed,
  @MetadataSource = @MetadataSource_981a15ed;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_7c282a92 UNIQUEIDENTIFIER,
@IntegrationObjectID_7c282a92 UNIQUEIDENTIFIER,
@Name_7c282a92 NVARCHAR(255),
@DisplayName_7c282a92 NVARCHAR(255),
@Description_7c282a92 NVARCHAR(MAX),
@Category_7c282a92 NVARCHAR(100),
@Type_7c282a92 NVARCHAR(100),
@Length_7c282a92 INT,
@Precision_7c282a92 INT,
@Scale_7c282a92 INT,
@AllowsNull_7c282a92 BIT,
@DefaultValue_7c282a92 NVARCHAR(255),
@IsPrimaryKey_7c282a92 BIT,
@IsUniqueKey_7c282a92 BIT,
@IsReadOnly_7c282a92 BIT,
@IsRequired_7c282a92 BIT,
@RelatedIntegrationObjectID_7c282a92 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_7c282a92 NVARCHAR(255),
@Sequence_7c282a92 INT,
@Configuration_7c282a92 NVARCHAR(MAX),
@Status_7c282a92 NVARCHAR(25),
@IsCustom_7c282a92 BIT,
@MetadataSource_7c282a92 NVARCHAR(20)
SET
  @ID_7c282a92 = '9D3F5A9B-5AD3-5824-AFAA-6676ABF9AB10'
SET
  @IntegrationObjectID_7c282a92 = '5F90FE9B-3498-4DC2-A188-6173B8EA842B'
SET
  @Name_7c282a92 = N'start-month'
SET
  @DisplayName_7c282a92 = N'Start Month'
SET
  @Description_7c282a92 = N'Month (1-12) of the affiliation start date, when given.'
SET
  @Type_7c282a92 = N'Integer'
SET
  @AllowsNull_7c282a92 = 1
SET
  @IsPrimaryKey_7c282a92 = 0
SET
  @IsUniqueKey_7c282a92 = 0
SET
  @IsReadOnly_7c282a92 = 1
SET
  @IsRequired_7c282a92 = 0
SET
  @Sequence_7c282a92 = 16
SET
  @Status_7c282a92 = N'Active'
SET
  @IsCustom_7c282a92 = 0
SET
  @MetadataSource_7c282a92 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_7c282a92,
  @IntegrationObjectID = @IntegrationObjectID_7c282a92,
  @Name = @Name_7c282a92,
  @DisplayName = @DisplayName_7c282a92,
  @Description = @Description_7c282a92,
  @Category = @Category_7c282a92,
  @Category_Clear = 1,
  @Type = @Type_7c282a92,
  @Length = @Length_7c282a92,
  @Length_Clear = 1,
  @Precision = @Precision_7c282a92,
  @Precision_Clear = 1,
  @Scale = @Scale_7c282a92,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_7c282a92,
  @DefaultValue = @DefaultValue_7c282a92,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_7c282a92,
  @IsUniqueKey = @IsUniqueKey_7c282a92,
  @IsReadOnly = @IsReadOnly_7c282a92,
  @IsRequired = @IsRequired_7c282a92,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_7c282a92,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_7c282a92,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_7c282a92,
  @Configuration = @Configuration_7c282a92,
  @Configuration_Clear = 1,
  @Status = @Status_7c282a92,
  @IsCustom = @IsCustom_7c282a92,
  @MetadataSource = @MetadataSource_7c282a92;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_42dcb68c UNIQUEIDENTIFIER,
@IntegrationObjectID_42dcb68c UNIQUEIDENTIFIER,
@Name_42dcb68c NVARCHAR(255),
@DisplayName_42dcb68c NVARCHAR(255),
@Description_42dcb68c NVARCHAR(MAX),
@Category_42dcb68c NVARCHAR(100),
@Type_42dcb68c NVARCHAR(100),
@Length_42dcb68c INT,
@Precision_42dcb68c INT,
@Scale_42dcb68c INT,
@AllowsNull_42dcb68c BIT,
@DefaultValue_42dcb68c NVARCHAR(255),
@IsPrimaryKey_42dcb68c BIT,
@IsUniqueKey_42dcb68c BIT,
@IsReadOnly_42dcb68c BIT,
@IsRequired_42dcb68c BIT,
@RelatedIntegrationObjectID_42dcb68c UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_42dcb68c NVARCHAR(255),
@Sequence_42dcb68c INT,
@Configuration_42dcb68c NVARCHAR(MAX),
@Status_42dcb68c NVARCHAR(25),
@IsCustom_42dcb68c BIT,
@MetadataSource_42dcb68c NVARCHAR(20)
SET
  @ID_42dcb68c = '220B6AE6-1526-5083-A650-7F6DB6FE819A'
SET
  @IntegrationObjectID_42dcb68c = '5F90FE9B-3498-4DC2-A188-6173B8EA842B'
SET
  @Name_42dcb68c = N'start-day'
SET
  @DisplayName_42dcb68c = N'Start Day'
SET
  @Description_42dcb68c = N'Day of month of the affiliation start date, when given.'
SET
  @Type_42dcb68c = N'Integer'
SET
  @AllowsNull_42dcb68c = 1
SET
  @IsPrimaryKey_42dcb68c = 0
SET
  @IsUniqueKey_42dcb68c = 0
SET
  @IsReadOnly_42dcb68c = 1
SET
  @IsRequired_42dcb68c = 0
SET
  @Sequence_42dcb68c = 17
SET
  @Status_42dcb68c = N'Active'
SET
  @IsCustom_42dcb68c = 0
SET
  @MetadataSource_42dcb68c = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_42dcb68c,
  @IntegrationObjectID = @IntegrationObjectID_42dcb68c,
  @Name = @Name_42dcb68c,
  @DisplayName = @DisplayName_42dcb68c,
  @Description = @Description_42dcb68c,
  @Category = @Category_42dcb68c,
  @Category_Clear = 1,
  @Type = @Type_42dcb68c,
  @Length = @Length_42dcb68c,
  @Length_Clear = 1,
  @Precision = @Precision_42dcb68c,
  @Precision_Clear = 1,
  @Scale = @Scale_42dcb68c,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_42dcb68c,
  @DefaultValue = @DefaultValue_42dcb68c,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_42dcb68c,
  @IsUniqueKey = @IsUniqueKey_42dcb68c,
  @IsReadOnly = @IsReadOnly_42dcb68c,
  @IsRequired = @IsRequired_42dcb68c,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_42dcb68c,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_42dcb68c,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_42dcb68c,
  @Configuration = @Configuration_42dcb68c,
  @Configuration_Clear = 1,
  @Status = @Status_42dcb68c,
  @IsCustom = @IsCustom_42dcb68c,
  @MetadataSource = @MetadataSource_42dcb68c;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_03986e41 UNIQUEIDENTIFIER,
@IntegrationObjectID_03986e41 UNIQUEIDENTIFIER,
@Name_03986e41 NVARCHAR(255),
@DisplayName_03986e41 NVARCHAR(255),
@Description_03986e41 NVARCHAR(MAX),
@Category_03986e41 NVARCHAR(100),
@Type_03986e41 NVARCHAR(100),
@Length_03986e41 INT,
@Precision_03986e41 INT,
@Scale_03986e41 INT,
@AllowsNull_03986e41 BIT,
@DefaultValue_03986e41 NVARCHAR(255),
@IsPrimaryKey_03986e41 BIT,
@IsUniqueKey_03986e41 BIT,
@IsReadOnly_03986e41 BIT,
@IsRequired_03986e41 BIT,
@RelatedIntegrationObjectID_03986e41 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_03986e41 NVARCHAR(255),
@Sequence_03986e41 INT,
@Configuration_03986e41 NVARCHAR(MAX),
@Status_03986e41 NVARCHAR(25),
@IsCustom_03986e41 BIT,
@MetadataSource_03986e41 NVARCHAR(20)
SET
  @ID_03986e41 = 'B2C593F4-630B-5886-BEC9-C14FCDE604D3'
SET
  @IntegrationObjectID_03986e41 = '5F90FE9B-3498-4DC2-A188-6173B8EA842B'
SET
  @Name_03986e41 = N'end-year'
SET
  @DisplayName_03986e41 = N'End Year'
SET
  @Description_03986e41 = N'Year of the affiliation end date; empty for a current/ongoing role; ORCID dates are partial, so month/day may be absent.'
SET
  @Type_03986e41 = N'Integer'
SET
  @AllowsNull_03986e41 = 1
SET
  @IsPrimaryKey_03986e41 = 0
SET
  @IsUniqueKey_03986e41 = 0
SET
  @IsReadOnly_03986e41 = 1
SET
  @IsRequired_03986e41 = 0
SET
  @Sequence_03986e41 = 18
SET
  @Status_03986e41 = N'Active'
SET
  @IsCustom_03986e41 = 0
SET
  @MetadataSource_03986e41 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_03986e41,
  @IntegrationObjectID = @IntegrationObjectID_03986e41,
  @Name = @Name_03986e41,
  @DisplayName = @DisplayName_03986e41,
  @Description = @Description_03986e41,
  @Category = @Category_03986e41,
  @Category_Clear = 1,
  @Type = @Type_03986e41,
  @Length = @Length_03986e41,
  @Length_Clear = 1,
  @Precision = @Precision_03986e41,
  @Precision_Clear = 1,
  @Scale = @Scale_03986e41,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_03986e41,
  @DefaultValue = @DefaultValue_03986e41,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_03986e41,
  @IsUniqueKey = @IsUniqueKey_03986e41,
  @IsReadOnly = @IsReadOnly_03986e41,
  @IsRequired = @IsRequired_03986e41,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_03986e41,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_03986e41,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_03986e41,
  @Configuration = @Configuration_03986e41,
  @Configuration_Clear = 1,
  @Status = @Status_03986e41,
  @IsCustom = @IsCustom_03986e41,
  @MetadataSource = @MetadataSource_03986e41;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_bfd5380c UNIQUEIDENTIFIER,
@IntegrationObjectID_bfd5380c UNIQUEIDENTIFIER,
@Name_bfd5380c NVARCHAR(255),
@DisplayName_bfd5380c NVARCHAR(255),
@Description_bfd5380c NVARCHAR(MAX),
@Category_bfd5380c NVARCHAR(100),
@Type_bfd5380c NVARCHAR(100),
@Length_bfd5380c INT,
@Precision_bfd5380c INT,
@Scale_bfd5380c INT,
@AllowsNull_bfd5380c BIT,
@DefaultValue_bfd5380c NVARCHAR(255),
@IsPrimaryKey_bfd5380c BIT,
@IsUniqueKey_bfd5380c BIT,
@IsReadOnly_bfd5380c BIT,
@IsRequired_bfd5380c BIT,
@RelatedIntegrationObjectID_bfd5380c UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_bfd5380c NVARCHAR(255),
@Sequence_bfd5380c INT,
@Configuration_bfd5380c NVARCHAR(MAX),
@Status_bfd5380c NVARCHAR(25),
@IsCustom_bfd5380c BIT,
@MetadataSource_bfd5380c NVARCHAR(20)
SET
  @ID_bfd5380c = '0D4BEE76-39F9-5E66-A4D4-43FD04B81735'
SET
  @IntegrationObjectID_bfd5380c = '5F90FE9B-3498-4DC2-A188-6173B8EA842B'
SET
  @Name_bfd5380c = N'end-month'
SET
  @DisplayName_bfd5380c = N'End Month'
SET
  @Description_bfd5380c = N'Month (1-12) of the affiliation end date; empty for a current/ongoing role, when given.'
SET
  @Type_bfd5380c = N'Integer'
SET
  @AllowsNull_bfd5380c = 1
SET
  @IsPrimaryKey_bfd5380c = 0
SET
  @IsUniqueKey_bfd5380c = 0
SET
  @IsReadOnly_bfd5380c = 1
SET
  @IsRequired_bfd5380c = 0
SET
  @Sequence_bfd5380c = 19
SET
  @Status_bfd5380c = N'Active'
SET
  @IsCustom_bfd5380c = 0
SET
  @MetadataSource_bfd5380c = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_bfd5380c,
  @IntegrationObjectID = @IntegrationObjectID_bfd5380c,
  @Name = @Name_bfd5380c,
  @DisplayName = @DisplayName_bfd5380c,
  @Description = @Description_bfd5380c,
  @Category = @Category_bfd5380c,
  @Category_Clear = 1,
  @Type = @Type_bfd5380c,
  @Length = @Length_bfd5380c,
  @Length_Clear = 1,
  @Precision = @Precision_bfd5380c,
  @Precision_Clear = 1,
  @Scale = @Scale_bfd5380c,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_bfd5380c,
  @DefaultValue = @DefaultValue_bfd5380c,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_bfd5380c,
  @IsUniqueKey = @IsUniqueKey_bfd5380c,
  @IsReadOnly = @IsReadOnly_bfd5380c,
  @IsRequired = @IsRequired_bfd5380c,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_bfd5380c,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_bfd5380c,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_bfd5380c,
  @Configuration = @Configuration_bfd5380c,
  @Configuration_Clear = 1,
  @Status = @Status_bfd5380c,
  @IsCustom = @IsCustom_bfd5380c,
  @MetadataSource = @MetadataSource_bfd5380c;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_d4a27558 UNIQUEIDENTIFIER,
@IntegrationObjectID_d4a27558 UNIQUEIDENTIFIER,
@Name_d4a27558 NVARCHAR(255),
@DisplayName_d4a27558 NVARCHAR(255),
@Description_d4a27558 NVARCHAR(MAX),
@Category_d4a27558 NVARCHAR(100),
@Type_d4a27558 NVARCHAR(100),
@Length_d4a27558 INT,
@Precision_d4a27558 INT,
@Scale_d4a27558 INT,
@AllowsNull_d4a27558 BIT,
@DefaultValue_d4a27558 NVARCHAR(255),
@IsPrimaryKey_d4a27558 BIT,
@IsUniqueKey_d4a27558 BIT,
@IsReadOnly_d4a27558 BIT,
@IsRequired_d4a27558 BIT,
@RelatedIntegrationObjectID_d4a27558 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_d4a27558 NVARCHAR(255),
@Sequence_d4a27558 INT,
@Configuration_d4a27558 NVARCHAR(MAX),
@Status_d4a27558 NVARCHAR(25),
@IsCustom_d4a27558 BIT,
@MetadataSource_d4a27558 NVARCHAR(20)
SET
  @ID_d4a27558 = '865F1EFA-AB27-5628-9E43-0AE3267C61F0'
SET
  @IntegrationObjectID_d4a27558 = '5F90FE9B-3498-4DC2-A188-6173B8EA842B'
SET
  @Name_d4a27558 = N'end-day'
SET
  @DisplayName_d4a27558 = N'End Day'
SET
  @Description_d4a27558 = N'Day of month of the affiliation end date; empty for a current/ongoing role, when given.'
SET
  @Type_d4a27558 = N'Integer'
SET
  @AllowsNull_d4a27558 = 1
SET
  @IsPrimaryKey_d4a27558 = 0
SET
  @IsUniqueKey_d4a27558 = 0
SET
  @IsReadOnly_d4a27558 = 1
SET
  @IsRequired_d4a27558 = 0
SET
  @Sequence_d4a27558 = 20
SET
  @Status_d4a27558 = N'Active'
SET
  @IsCustom_d4a27558 = 0
SET
  @MetadataSource_d4a27558 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_d4a27558,
  @IntegrationObjectID = @IntegrationObjectID_d4a27558,
  @Name = @Name_d4a27558,
  @DisplayName = @DisplayName_d4a27558,
  @Description = @Description_d4a27558,
  @Category = @Category_d4a27558,
  @Category_Clear = 1,
  @Type = @Type_d4a27558,
  @Length = @Length_d4a27558,
  @Length_Clear = 1,
  @Precision = @Precision_d4a27558,
  @Precision_Clear = 1,
  @Scale = @Scale_d4a27558,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_d4a27558,
  @DefaultValue = @DefaultValue_d4a27558,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_d4a27558,
  @IsUniqueKey = @IsUniqueKey_d4a27558,
  @IsReadOnly = @IsReadOnly_d4a27558,
  @IsRequired = @IsRequired_d4a27558,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_d4a27558,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_d4a27558,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_d4a27558,
  @Configuration = @Configuration_d4a27558,
  @Configuration_Clear = 1,
  @Status = @Status_d4a27558,
  @IsCustom = @IsCustom_d4a27558,
  @MetadataSource = @MetadataSource_d4a27558;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_f608b136 UNIQUEIDENTIFIER,
@IntegrationObjectID_f608b136 UNIQUEIDENTIFIER,
@Name_f608b136 NVARCHAR(255),
@DisplayName_f608b136 NVARCHAR(255),
@Description_f608b136 NVARCHAR(MAX),
@Category_f608b136 NVARCHAR(100),
@Type_f608b136 NVARCHAR(100),
@Length_f608b136 INT,
@Precision_f608b136 INT,
@Scale_f608b136 INT,
@AllowsNull_f608b136 BIT,
@DefaultValue_f608b136 NVARCHAR(255),
@IsPrimaryKey_f608b136 BIT,
@IsUniqueKey_f608b136 BIT,
@IsReadOnly_f608b136 BIT,
@IsRequired_f608b136 BIT,
@RelatedIntegrationObjectID_f608b136 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_f608b136 NVARCHAR(255),
@Sequence_f608b136 INT,
@Configuration_f608b136 NVARCHAR(MAX),
@Status_f608b136 NVARCHAR(25),
@IsCustom_f608b136 BIT,
@MetadataSource_f608b136 NVARCHAR(20)
SET
  @ID_f608b136 = 'AF0EFA16-B004-5843-9A8C-7CE0D73802E3'
SET
  @IntegrationObjectID_f608b136 = '5F90FE9B-3498-4DC2-A188-6173B8EA842B'
SET
  @Name_f608b136 = N'organization-name'
SET
  @DisplayName_f608b136 = N'Organization Name'
SET
  @Description_f608b136 = N'Name of the organization. Lifted from organization.name.'
SET
  @Type_f608b136 = N'String'
SET
  @Length_f608b136 = 1000
SET
  @AllowsNull_f608b136 = 1
SET
  @IsPrimaryKey_f608b136 = 0
SET
  @IsUniqueKey_f608b136 = 0
SET
  @IsReadOnly_f608b136 = 1
SET
  @IsRequired_f608b136 = 0
SET
  @Sequence_f608b136 = 21
SET
  @Status_f608b136 = N'Active'
SET
  @IsCustom_f608b136 = 0
SET
  @MetadataSource_f608b136 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_f608b136,
  @IntegrationObjectID = @IntegrationObjectID_f608b136,
  @Name = @Name_f608b136,
  @DisplayName = @DisplayName_f608b136,
  @Description = @Description_f608b136,
  @Category = @Category_f608b136,
  @Category_Clear = 1,
  @Type = @Type_f608b136,
  @Length = @Length_f608b136,
  @Precision = @Precision_f608b136,
  @Precision_Clear = 1,
  @Scale = @Scale_f608b136,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_f608b136,
  @DefaultValue = @DefaultValue_f608b136,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_f608b136,
  @IsUniqueKey = @IsUniqueKey_f608b136,
  @IsReadOnly = @IsReadOnly_f608b136,
  @IsRequired = @IsRequired_f608b136,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_f608b136,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_f608b136,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_f608b136,
  @Configuration = @Configuration_f608b136,
  @Configuration_Clear = 1,
  @Status = @Status_f608b136,
  @IsCustom = @IsCustom_f608b136,
  @MetadataSource = @MetadataSource_f608b136;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_e04cfa4d UNIQUEIDENTIFIER,
@IntegrationObjectID_e04cfa4d UNIQUEIDENTIFIER,
@Name_e04cfa4d NVARCHAR(255),
@DisplayName_e04cfa4d NVARCHAR(255),
@Description_e04cfa4d NVARCHAR(MAX),
@Category_e04cfa4d NVARCHAR(100),
@Type_e04cfa4d NVARCHAR(100),
@Length_e04cfa4d INT,
@Precision_e04cfa4d INT,
@Scale_e04cfa4d INT,
@AllowsNull_e04cfa4d BIT,
@DefaultValue_e04cfa4d NVARCHAR(255),
@IsPrimaryKey_e04cfa4d BIT,
@IsUniqueKey_e04cfa4d BIT,
@IsReadOnly_e04cfa4d BIT,
@IsRequired_e04cfa4d BIT,
@RelatedIntegrationObjectID_e04cfa4d UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_e04cfa4d NVARCHAR(255),
@Sequence_e04cfa4d INT,
@Configuration_e04cfa4d NVARCHAR(MAX),
@Status_e04cfa4d NVARCHAR(25),
@IsCustom_e04cfa4d BIT,
@MetadataSource_e04cfa4d NVARCHAR(20)
SET
  @ID_e04cfa4d = 'BE1C90DB-1CF3-53A2-AD1F-7050FA6B8E78'
SET
  @IntegrationObjectID_e04cfa4d = '5F90FE9B-3498-4DC2-A188-6173B8EA842B'
SET
  @Name_e04cfa4d = N'organization-city'
SET
  @DisplayName_e04cfa4d = N'Organization City'
SET
  @Description_e04cfa4d = N'City of the organization. Lifted from organization.address.city.'
SET
  @Type_e04cfa4d = N'String'
SET
  @Length_e04cfa4d = 255
SET
  @AllowsNull_e04cfa4d = 1
SET
  @IsPrimaryKey_e04cfa4d = 0
SET
  @IsUniqueKey_e04cfa4d = 0
SET
  @IsReadOnly_e04cfa4d = 1
SET
  @IsRequired_e04cfa4d = 0
SET
  @Sequence_e04cfa4d = 22
SET
  @Status_e04cfa4d = N'Active'
SET
  @IsCustom_e04cfa4d = 0
SET
  @MetadataSource_e04cfa4d = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_e04cfa4d,
  @IntegrationObjectID = @IntegrationObjectID_e04cfa4d,
  @Name = @Name_e04cfa4d,
  @DisplayName = @DisplayName_e04cfa4d,
  @Description = @Description_e04cfa4d,
  @Category = @Category_e04cfa4d,
  @Category_Clear = 1,
  @Type = @Type_e04cfa4d,
  @Length = @Length_e04cfa4d,
  @Precision = @Precision_e04cfa4d,
  @Precision_Clear = 1,
  @Scale = @Scale_e04cfa4d,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_e04cfa4d,
  @DefaultValue = @DefaultValue_e04cfa4d,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_e04cfa4d,
  @IsUniqueKey = @IsUniqueKey_e04cfa4d,
  @IsReadOnly = @IsReadOnly_e04cfa4d,
  @IsRequired = @IsRequired_e04cfa4d,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_e04cfa4d,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_e04cfa4d,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_e04cfa4d,
  @Configuration = @Configuration_e04cfa4d,
  @Configuration_Clear = 1,
  @Status = @Status_e04cfa4d,
  @IsCustom = @IsCustom_e04cfa4d,
  @MetadataSource = @MetadataSource_e04cfa4d;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_d928aff5 UNIQUEIDENTIFIER,
@IntegrationObjectID_d928aff5 UNIQUEIDENTIFIER,
@Name_d928aff5 NVARCHAR(255),
@DisplayName_d928aff5 NVARCHAR(255),
@Description_d928aff5 NVARCHAR(MAX),
@Category_d928aff5 NVARCHAR(100),
@Type_d928aff5 NVARCHAR(100),
@Length_d928aff5 INT,
@Precision_d928aff5 INT,
@Scale_d928aff5 INT,
@AllowsNull_d928aff5 BIT,
@DefaultValue_d928aff5 NVARCHAR(255),
@IsPrimaryKey_d928aff5 BIT,
@IsUniqueKey_d928aff5 BIT,
@IsReadOnly_d928aff5 BIT,
@IsRequired_d928aff5 BIT,
@RelatedIntegrationObjectID_d928aff5 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_d928aff5 NVARCHAR(255),
@Sequence_d928aff5 INT,
@Configuration_d928aff5 NVARCHAR(MAX),
@Status_d928aff5 NVARCHAR(25),
@IsCustom_d928aff5 BIT,
@MetadataSource_d928aff5 NVARCHAR(20)
SET
  @ID_d928aff5 = '43208C62-3466-59D7-996C-237B9FAC47DE'
SET
  @IntegrationObjectID_d928aff5 = '5F90FE9B-3498-4DC2-A188-6173B8EA842B'
SET
  @Name_d928aff5 = N'organization-region'
SET
  @DisplayName_d928aff5 = N'Organization Region'
SET
  @Description_d928aff5 = N'Region/state of the organization. Lifted from organization.address.region.'
SET
  @Type_d928aff5 = N'String'
SET
  @Length_d928aff5 = 255
SET
  @AllowsNull_d928aff5 = 1
SET
  @IsPrimaryKey_d928aff5 = 0
SET
  @IsUniqueKey_d928aff5 = 0
SET
  @IsReadOnly_d928aff5 = 1
SET
  @IsRequired_d928aff5 = 0
SET
  @Sequence_d928aff5 = 23
SET
  @Status_d928aff5 = N'Active'
SET
  @IsCustom_d928aff5 = 0
SET
  @MetadataSource_d928aff5 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_d928aff5,
  @IntegrationObjectID = @IntegrationObjectID_d928aff5,
  @Name = @Name_d928aff5,
  @DisplayName = @DisplayName_d928aff5,
  @Description = @Description_d928aff5,
  @Category = @Category_d928aff5,
  @Category_Clear = 1,
  @Type = @Type_d928aff5,
  @Length = @Length_d928aff5,
  @Precision = @Precision_d928aff5,
  @Precision_Clear = 1,
  @Scale = @Scale_d928aff5,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_d928aff5,
  @DefaultValue = @DefaultValue_d928aff5,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_d928aff5,
  @IsUniqueKey = @IsUniqueKey_d928aff5,
  @IsReadOnly = @IsReadOnly_d928aff5,
  @IsRequired = @IsRequired_d928aff5,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_d928aff5,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_d928aff5,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_d928aff5,
  @Configuration = @Configuration_d928aff5,
  @Configuration_Clear = 1,
  @Status = @Status_d928aff5,
  @IsCustom = @IsCustom_d928aff5,
  @MetadataSource = @MetadataSource_d928aff5;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_eea78aa1 UNIQUEIDENTIFIER,
@IntegrationObjectID_eea78aa1 UNIQUEIDENTIFIER,
@Name_eea78aa1 NVARCHAR(255),
@DisplayName_eea78aa1 NVARCHAR(255),
@Description_eea78aa1 NVARCHAR(MAX),
@Category_eea78aa1 NVARCHAR(100),
@Type_eea78aa1 NVARCHAR(100),
@Length_eea78aa1 INT,
@Precision_eea78aa1 INT,
@Scale_eea78aa1 INT,
@AllowsNull_eea78aa1 BIT,
@DefaultValue_eea78aa1 NVARCHAR(255),
@IsPrimaryKey_eea78aa1 BIT,
@IsUniqueKey_eea78aa1 BIT,
@IsReadOnly_eea78aa1 BIT,
@IsRequired_eea78aa1 BIT,
@RelatedIntegrationObjectID_eea78aa1 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_eea78aa1 NVARCHAR(255),
@Sequence_eea78aa1 INT,
@Configuration_eea78aa1 NVARCHAR(MAX),
@Status_eea78aa1 NVARCHAR(25),
@IsCustom_eea78aa1 BIT,
@MetadataSource_eea78aa1 NVARCHAR(20)
SET
  @ID_eea78aa1 = 'ACDB4C8D-0B31-5556-9092-C92AEF24EF90'
SET
  @IntegrationObjectID_eea78aa1 = '5F90FE9B-3498-4DC2-A188-6173B8EA842B'
SET
  @Name_eea78aa1 = N'organization-country'
SET
  @DisplayName_eea78aa1 = N'Organization Country'
SET
  @Description_eea78aa1 = N'ISO country code of the organization. Lifted from organization.address.country.'
SET
  @Type_eea78aa1 = N'String'
SET
  @Length_eea78aa1 = 50
SET
  @AllowsNull_eea78aa1 = 1
SET
  @IsPrimaryKey_eea78aa1 = 0
SET
  @IsUniqueKey_eea78aa1 = 0
SET
  @IsReadOnly_eea78aa1 = 1
SET
  @IsRequired_eea78aa1 = 0
SET
  @Sequence_eea78aa1 = 24
SET
  @Status_eea78aa1 = N'Active'
SET
  @IsCustom_eea78aa1 = 0
SET
  @MetadataSource_eea78aa1 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_eea78aa1,
  @IntegrationObjectID = @IntegrationObjectID_eea78aa1,
  @Name = @Name_eea78aa1,
  @DisplayName = @DisplayName_eea78aa1,
  @Description = @Description_eea78aa1,
  @Category = @Category_eea78aa1,
  @Category_Clear = 1,
  @Type = @Type_eea78aa1,
  @Length = @Length_eea78aa1,
  @Precision = @Precision_eea78aa1,
  @Precision_Clear = 1,
  @Scale = @Scale_eea78aa1,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_eea78aa1,
  @DefaultValue = @DefaultValue_eea78aa1,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_eea78aa1,
  @IsUniqueKey = @IsUniqueKey_eea78aa1,
  @IsReadOnly = @IsReadOnly_eea78aa1,
  @IsRequired = @IsRequired_eea78aa1,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_eea78aa1,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_eea78aa1,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_eea78aa1,
  @Configuration = @Configuration_eea78aa1,
  @Configuration_Clear = 1,
  @Status = @Status_eea78aa1,
  @IsCustom = @IsCustom_eea78aa1,
  @MetadataSource = @MetadataSource_eea78aa1;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_927bf38a UNIQUEIDENTIFIER,
@IntegrationObjectID_927bf38a UNIQUEIDENTIFIER,
@Name_927bf38a NVARCHAR(255),
@DisplayName_927bf38a NVARCHAR(255),
@Description_927bf38a NVARCHAR(MAX),
@Category_927bf38a NVARCHAR(100),
@Type_927bf38a NVARCHAR(100),
@Length_927bf38a INT,
@Precision_927bf38a INT,
@Scale_927bf38a INT,
@AllowsNull_927bf38a BIT,
@DefaultValue_927bf38a NVARCHAR(255),
@IsPrimaryKey_927bf38a BIT,
@IsUniqueKey_927bf38a BIT,
@IsReadOnly_927bf38a BIT,
@IsRequired_927bf38a BIT,
@RelatedIntegrationObjectID_927bf38a UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_927bf38a NVARCHAR(255),
@Sequence_927bf38a INT,
@Configuration_927bf38a NVARCHAR(MAX),
@Status_927bf38a NVARCHAR(25),
@IsCustom_927bf38a BIT,
@MetadataSource_927bf38a NVARCHAR(20)
SET
  @ID_927bf38a = 'EBA1B12F-BBED-5F44-B6CD-421E0BF8254A'
SET
  @IntegrationObjectID_927bf38a = '5F90FE9B-3498-4DC2-A188-6173B8EA842B'
SET
  @Name_927bf38a = N'organization-disambiguated-id'
SET
  @DisplayName_927bf38a = N'Organization Disambiguated Id'
SET
  @Description_927bf38a = N'Canonical identifier of the organization in the disambiguation source (e.g. a RINGGOLD or ROR id), so the same institution matches across records.'
SET
  @Type_927bf38a = N'String'
SET
  @Length_927bf38a = 255
SET
  @AllowsNull_927bf38a = 1
SET
  @IsPrimaryKey_927bf38a = 0
SET
  @IsUniqueKey_927bf38a = 0
SET
  @IsReadOnly_927bf38a = 1
SET
  @IsRequired_927bf38a = 0
SET
  @Sequence_927bf38a = 25
SET
  @Status_927bf38a = N'Active'
SET
  @IsCustom_927bf38a = 0
SET
  @MetadataSource_927bf38a = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_927bf38a,
  @IntegrationObjectID = @IntegrationObjectID_927bf38a,
  @Name = @Name_927bf38a,
  @DisplayName = @DisplayName_927bf38a,
  @Description = @Description_927bf38a,
  @Category = @Category_927bf38a,
  @Category_Clear = 1,
  @Type = @Type_927bf38a,
  @Length = @Length_927bf38a,
  @Precision = @Precision_927bf38a,
  @Precision_Clear = 1,
  @Scale = @Scale_927bf38a,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_927bf38a,
  @DefaultValue = @DefaultValue_927bf38a,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_927bf38a,
  @IsUniqueKey = @IsUniqueKey_927bf38a,
  @IsReadOnly = @IsReadOnly_927bf38a,
  @IsRequired = @IsRequired_927bf38a,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_927bf38a,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_927bf38a,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_927bf38a,
  @Configuration = @Configuration_927bf38a,
  @Configuration_Clear = 1,
  @Status = @Status_927bf38a,
  @IsCustom = @IsCustom_927bf38a,
  @MetadataSource = @MetadataSource_927bf38a;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_9aa4cc75 UNIQUEIDENTIFIER,
@IntegrationObjectID_9aa4cc75 UNIQUEIDENTIFIER,
@Name_9aa4cc75 NVARCHAR(255),
@DisplayName_9aa4cc75 NVARCHAR(255),
@Description_9aa4cc75 NVARCHAR(MAX),
@Category_9aa4cc75 NVARCHAR(100),
@Type_9aa4cc75 NVARCHAR(100),
@Length_9aa4cc75 INT,
@Precision_9aa4cc75 INT,
@Scale_9aa4cc75 INT,
@AllowsNull_9aa4cc75 BIT,
@DefaultValue_9aa4cc75 NVARCHAR(255),
@IsPrimaryKey_9aa4cc75 BIT,
@IsUniqueKey_9aa4cc75 BIT,
@IsReadOnly_9aa4cc75 BIT,
@IsRequired_9aa4cc75 BIT,
@RelatedIntegrationObjectID_9aa4cc75 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_9aa4cc75 NVARCHAR(255),
@Sequence_9aa4cc75 INT,
@Configuration_9aa4cc75 NVARCHAR(MAX),
@Status_9aa4cc75 NVARCHAR(25),
@IsCustom_9aa4cc75 BIT,
@MetadataSource_9aa4cc75 NVARCHAR(20)
SET
  @ID_9aa4cc75 = '9C26EDFA-6304-5232-817F-BB3A10984AA4'
SET
  @IntegrationObjectID_9aa4cc75 = '5F90FE9B-3498-4DC2-A188-6173B8EA842B'
SET
  @Name_9aa4cc75 = N'organization-disambiguation-source'
SET
  @DisplayName_9aa4cc75 = N'Organization Disambiguation Source'
SET
  @Description_9aa4cc75 = N'Registry the disambiguated id comes from (RINGGOLD, ROR, FUNDREF, GRID, LEI).'
SET
  @Type_9aa4cc75 = N'String'
SET
  @Length_9aa4cc75 = 100
SET
  @AllowsNull_9aa4cc75 = 1
SET
  @IsPrimaryKey_9aa4cc75 = 0
SET
  @IsUniqueKey_9aa4cc75 = 0
SET
  @IsReadOnly_9aa4cc75 = 1
SET
  @IsRequired_9aa4cc75 = 0
SET
  @Sequence_9aa4cc75 = 26
SET
  @Status_9aa4cc75 = N'Active'
SET
  @IsCustom_9aa4cc75 = 0
SET
  @MetadataSource_9aa4cc75 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_9aa4cc75,
  @IntegrationObjectID = @IntegrationObjectID_9aa4cc75,
  @Name = @Name_9aa4cc75,
  @DisplayName = @DisplayName_9aa4cc75,
  @Description = @Description_9aa4cc75,
  @Category = @Category_9aa4cc75,
  @Category_Clear = 1,
  @Type = @Type_9aa4cc75,
  @Length = @Length_9aa4cc75,
  @Precision = @Precision_9aa4cc75,
  @Precision_Clear = 1,
  @Scale = @Scale_9aa4cc75,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_9aa4cc75,
  @DefaultValue = @DefaultValue_9aa4cc75,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_9aa4cc75,
  @IsUniqueKey = @IsUniqueKey_9aa4cc75,
  @IsReadOnly = @IsReadOnly_9aa4cc75,
  @IsRequired = @IsRequired_9aa4cc75,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_9aa4cc75,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_9aa4cc75,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_9aa4cc75,
  @Configuration = @Configuration_9aa4cc75,
  @Configuration_Clear = 1,
  @Status = @Status_9aa4cc75,
  @IsCustom = @IsCustom_9aa4cc75,
  @MetadataSource = @MetadataSource_9aa4cc75;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_8fc7176d UNIQUEIDENTIFIER,
@IntegrationObjectID_8fc7176d UNIQUEIDENTIFIER,
@Name_8fc7176d NVARCHAR(255),
@DisplayName_8fc7176d NVARCHAR(255),
@Description_8fc7176d NVARCHAR(MAX),
@Category_8fc7176d NVARCHAR(100),
@Type_8fc7176d NVARCHAR(100),
@Length_8fc7176d INT,
@Precision_8fc7176d INT,
@Scale_8fc7176d INT,
@AllowsNull_8fc7176d BIT,
@DefaultValue_8fc7176d NVARCHAR(255),
@IsPrimaryKey_8fc7176d BIT,
@IsUniqueKey_8fc7176d BIT,
@IsReadOnly_8fc7176d BIT,
@IsRequired_8fc7176d BIT,
@RelatedIntegrationObjectID_8fc7176d UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_8fc7176d NVARCHAR(255),
@Sequence_8fc7176d INT,
@Configuration_8fc7176d NVARCHAR(MAX),
@Status_8fc7176d NVARCHAR(25),
@IsCustom_8fc7176d BIT,
@MetadataSource_8fc7176d NVARCHAR(20)
SET
  @ID_8fc7176d = '7E0E532D-BD89-5DE7-BFF6-44A616245D80'
SET
  @IntegrationObjectID_8fc7176d = '5F90FE9B-3498-4DC2-A188-6173B8EA842B'
SET
  @Name_8fc7176d = N'source-name'
SET
  @DisplayName_8fc7176d = N'Source Name'
SET
  @Description_8fc7176d = N'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.'
SET
  @Type_8fc7176d = N'String'
SET
  @Length_8fc7176d = 500
SET
  @AllowsNull_8fc7176d = 1
SET
  @IsPrimaryKey_8fc7176d = 0
SET
  @IsUniqueKey_8fc7176d = 0
SET
  @IsReadOnly_8fc7176d = 1
SET
  @IsRequired_8fc7176d = 0
SET
  @Sequence_8fc7176d = 27
SET
  @Status_8fc7176d = N'Active'
SET
  @IsCustom_8fc7176d = 0
SET
  @MetadataSource_8fc7176d = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_8fc7176d,
  @IntegrationObjectID = @IntegrationObjectID_8fc7176d,
  @Name = @Name_8fc7176d,
  @DisplayName = @DisplayName_8fc7176d,
  @Description = @Description_8fc7176d,
  @Category = @Category_8fc7176d,
  @Category_Clear = 1,
  @Type = @Type_8fc7176d,
  @Length = @Length_8fc7176d,
  @Precision = @Precision_8fc7176d,
  @Precision_Clear = 1,
  @Scale = @Scale_8fc7176d,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_8fc7176d,
  @DefaultValue = @DefaultValue_8fc7176d,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_8fc7176d,
  @IsUniqueKey = @IsUniqueKey_8fc7176d,
  @IsReadOnly = @IsReadOnly_8fc7176d,
  @IsRequired = @IsRequired_8fc7176d,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_8fc7176d,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_8fc7176d,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_8fc7176d,
  @Configuration = @Configuration_8fc7176d,
  @Configuration_Clear = 1,
  @Status = @Status_8fc7176d,
  @IsCustom = @IsCustom_8fc7176d,
  @MetadataSource = @MetadataSource_8fc7176d;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_8ce7c087 UNIQUEIDENTIFIER,
@IntegrationObjectID_8ce7c087 UNIQUEIDENTIFIER,
@Name_8ce7c087 NVARCHAR(255),
@DisplayName_8ce7c087 NVARCHAR(255),
@Description_8ce7c087 NVARCHAR(MAX),
@Category_8ce7c087 NVARCHAR(100),
@Type_8ce7c087 NVARCHAR(100),
@Length_8ce7c087 INT,
@Precision_8ce7c087 INT,
@Scale_8ce7c087 INT,
@AllowsNull_8ce7c087 BIT,
@DefaultValue_8ce7c087 NVARCHAR(255),
@IsPrimaryKey_8ce7c087 BIT,
@IsUniqueKey_8ce7c087 BIT,
@IsReadOnly_8ce7c087 BIT,
@IsRequired_8ce7c087 BIT,
@RelatedIntegrationObjectID_8ce7c087 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_8ce7c087 NVARCHAR(255),
@Sequence_8ce7c087 INT,
@Configuration_8ce7c087 NVARCHAR(MAX),
@Status_8ce7c087 NVARCHAR(25),
@IsCustom_8ce7c087 BIT,
@MetadataSource_8ce7c087 NVARCHAR(20)
SET
  @ID_8ce7c087 = 'F0ABD08E-E231-5CBC-AE51-5BF7158F3EC0'
SET
  @IntegrationObjectID_8ce7c087 = '5F90FE9B-3498-4DC2-A188-6173B8EA842B'
SET
  @Name_8ce7c087 = N'source-orcid'
SET
  @DisplayName_8ce7c087 = N'Source Orcid'
SET
  @Description_8ce7c087 = N'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.'
SET
  @Type_8ce7c087 = N'String'
SET
  @Length_8ce7c087 = 19
SET
  @AllowsNull_8ce7c087 = 1
SET
  @IsPrimaryKey_8ce7c087 = 0
SET
  @IsUniqueKey_8ce7c087 = 0
SET
  @IsReadOnly_8ce7c087 = 1
SET
  @IsRequired_8ce7c087 = 0
SET
  @Sequence_8ce7c087 = 28
SET
  @Status_8ce7c087 = N'Active'
SET
  @IsCustom_8ce7c087 = 0
SET
  @MetadataSource_8ce7c087 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_8ce7c087,
  @IntegrationObjectID = @IntegrationObjectID_8ce7c087,
  @Name = @Name_8ce7c087,
  @DisplayName = @DisplayName_8ce7c087,
  @Description = @Description_8ce7c087,
  @Category = @Category_8ce7c087,
  @Category_Clear = 1,
  @Type = @Type_8ce7c087,
  @Length = @Length_8ce7c087,
  @Precision = @Precision_8ce7c087,
  @Precision_Clear = 1,
  @Scale = @Scale_8ce7c087,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_8ce7c087,
  @DefaultValue = @DefaultValue_8ce7c087,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_8ce7c087,
  @IsUniqueKey = @IsUniqueKey_8ce7c087,
  @IsReadOnly = @IsReadOnly_8ce7c087,
  @IsRequired = @IsRequired_8ce7c087,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_8ce7c087,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_8ce7c087,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_8ce7c087,
  @Configuration = @Configuration_8ce7c087,
  @Configuration_Clear = 1,
  @Status = @Status_8ce7c087,
  @IsCustom = @IsCustom_8ce7c087,
  @MetadataSource = @MetadataSource_8ce7c087;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_f98937e0 UNIQUEIDENTIFIER,
@IntegrationObjectID_f98937e0 UNIQUEIDENTIFIER,
@Name_f98937e0 NVARCHAR(255),
@DisplayName_f98937e0 NVARCHAR(255),
@Description_f98937e0 NVARCHAR(MAX),
@Category_f98937e0 NVARCHAR(100),
@Type_f98937e0 NVARCHAR(100),
@Length_f98937e0 INT,
@Precision_f98937e0 INT,
@Scale_f98937e0 INT,
@AllowsNull_f98937e0 BIT,
@DefaultValue_f98937e0 NVARCHAR(255),
@IsPrimaryKey_f98937e0 BIT,
@IsUniqueKey_f98937e0 BIT,
@IsReadOnly_f98937e0 BIT,
@IsRequired_f98937e0 BIT,
@RelatedIntegrationObjectID_f98937e0 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_f98937e0 NVARCHAR(255),
@Sequence_f98937e0 INT,
@Configuration_f98937e0 NVARCHAR(MAX),
@Status_f98937e0 NVARCHAR(25),
@IsCustom_f98937e0 BIT,
@MetadataSource_f98937e0 NVARCHAR(20)
SET
  @ID_f98937e0 = '790CB7A8-600B-5998-A600-622F1602FE73'
SET
  @IntegrationObjectID_f98937e0 = '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF'
SET
  @Name_f98937e0 = N'start-year'
SET
  @DisplayName_f98937e0 = N'Start Year'
SET
  @Description_f98937e0 = N'Year of the affiliation start date; ORCID dates are partial, so month/day may be absent.'
SET
  @Type_f98937e0 = N'Integer'
SET
  @AllowsNull_f98937e0 = 1
SET
  @IsPrimaryKey_f98937e0 = 0
SET
  @IsUniqueKey_f98937e0 = 0
SET
  @IsReadOnly_f98937e0 = 1
SET
  @IsRequired_f98937e0 = 0
SET
  @Sequence_f98937e0 = 15
SET
  @Status_f98937e0 = N'Active'
SET
  @IsCustom_f98937e0 = 0
SET
  @MetadataSource_f98937e0 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_f98937e0,
  @IntegrationObjectID = @IntegrationObjectID_f98937e0,
  @Name = @Name_f98937e0,
  @DisplayName = @DisplayName_f98937e0,
  @Description = @Description_f98937e0,
  @Category = @Category_f98937e0,
  @Category_Clear = 1,
  @Type = @Type_f98937e0,
  @Length = @Length_f98937e0,
  @Length_Clear = 1,
  @Precision = @Precision_f98937e0,
  @Precision_Clear = 1,
  @Scale = @Scale_f98937e0,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_f98937e0,
  @DefaultValue = @DefaultValue_f98937e0,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_f98937e0,
  @IsUniqueKey = @IsUniqueKey_f98937e0,
  @IsReadOnly = @IsReadOnly_f98937e0,
  @IsRequired = @IsRequired_f98937e0,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_f98937e0,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_f98937e0,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_f98937e0,
  @Configuration = @Configuration_f98937e0,
  @Configuration_Clear = 1,
  @Status = @Status_f98937e0,
  @IsCustom = @IsCustom_f98937e0,
  @MetadataSource = @MetadataSource_f98937e0;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_c085b5e4 UNIQUEIDENTIFIER,
@IntegrationObjectID_c085b5e4 UNIQUEIDENTIFIER,
@Name_c085b5e4 NVARCHAR(255),
@DisplayName_c085b5e4 NVARCHAR(255),
@Description_c085b5e4 NVARCHAR(MAX),
@Category_c085b5e4 NVARCHAR(100),
@Type_c085b5e4 NVARCHAR(100),
@Length_c085b5e4 INT,
@Precision_c085b5e4 INT,
@Scale_c085b5e4 INT,
@AllowsNull_c085b5e4 BIT,
@DefaultValue_c085b5e4 NVARCHAR(255),
@IsPrimaryKey_c085b5e4 BIT,
@IsUniqueKey_c085b5e4 BIT,
@IsReadOnly_c085b5e4 BIT,
@IsRequired_c085b5e4 BIT,
@RelatedIntegrationObjectID_c085b5e4 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_c085b5e4 NVARCHAR(255),
@Sequence_c085b5e4 INT,
@Configuration_c085b5e4 NVARCHAR(MAX),
@Status_c085b5e4 NVARCHAR(25),
@IsCustom_c085b5e4 BIT,
@MetadataSource_c085b5e4 NVARCHAR(20)
SET
  @ID_c085b5e4 = '6B7DB5A4-8252-5E8A-AC9D-8903F2FA93F4'
SET
  @IntegrationObjectID_c085b5e4 = '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF'
SET
  @Name_c085b5e4 = N'start-month'
SET
  @DisplayName_c085b5e4 = N'Start Month'
SET
  @Description_c085b5e4 = N'Month (1-12) of the affiliation start date, when given.'
SET
  @Type_c085b5e4 = N'Integer'
SET
  @AllowsNull_c085b5e4 = 1
SET
  @IsPrimaryKey_c085b5e4 = 0
SET
  @IsUniqueKey_c085b5e4 = 0
SET
  @IsReadOnly_c085b5e4 = 1
SET
  @IsRequired_c085b5e4 = 0
SET
  @Sequence_c085b5e4 = 16
SET
  @Status_c085b5e4 = N'Active'
SET
  @IsCustom_c085b5e4 = 0
SET
  @MetadataSource_c085b5e4 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_c085b5e4,
  @IntegrationObjectID = @IntegrationObjectID_c085b5e4,
  @Name = @Name_c085b5e4,
  @DisplayName = @DisplayName_c085b5e4,
  @Description = @Description_c085b5e4,
  @Category = @Category_c085b5e4,
  @Category_Clear = 1,
  @Type = @Type_c085b5e4,
  @Length = @Length_c085b5e4,
  @Length_Clear = 1,
  @Precision = @Precision_c085b5e4,
  @Precision_Clear = 1,
  @Scale = @Scale_c085b5e4,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_c085b5e4,
  @DefaultValue = @DefaultValue_c085b5e4,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_c085b5e4,
  @IsUniqueKey = @IsUniqueKey_c085b5e4,
  @IsReadOnly = @IsReadOnly_c085b5e4,
  @IsRequired = @IsRequired_c085b5e4,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_c085b5e4,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_c085b5e4,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_c085b5e4,
  @Configuration = @Configuration_c085b5e4,
  @Configuration_Clear = 1,
  @Status = @Status_c085b5e4,
  @IsCustom = @IsCustom_c085b5e4,
  @MetadataSource = @MetadataSource_c085b5e4;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_33c2979b UNIQUEIDENTIFIER,
@IntegrationObjectID_33c2979b UNIQUEIDENTIFIER,
@Name_33c2979b NVARCHAR(255),
@DisplayName_33c2979b NVARCHAR(255),
@Description_33c2979b NVARCHAR(MAX),
@Category_33c2979b NVARCHAR(100),
@Type_33c2979b NVARCHAR(100),
@Length_33c2979b INT,
@Precision_33c2979b INT,
@Scale_33c2979b INT,
@AllowsNull_33c2979b BIT,
@DefaultValue_33c2979b NVARCHAR(255),
@IsPrimaryKey_33c2979b BIT,
@IsUniqueKey_33c2979b BIT,
@IsReadOnly_33c2979b BIT,
@IsRequired_33c2979b BIT,
@RelatedIntegrationObjectID_33c2979b UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_33c2979b NVARCHAR(255),
@Sequence_33c2979b INT,
@Configuration_33c2979b NVARCHAR(MAX),
@Status_33c2979b NVARCHAR(25),
@IsCustom_33c2979b BIT,
@MetadataSource_33c2979b NVARCHAR(20)
SET
  @ID_33c2979b = '90108AC8-021D-50EE-B4A1-BAD18764DF9F'
SET
  @IntegrationObjectID_33c2979b = '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF'
SET
  @Name_33c2979b = N'start-day'
SET
  @DisplayName_33c2979b = N'Start Day'
SET
  @Description_33c2979b = N'Day of month of the affiliation start date, when given.'
SET
  @Type_33c2979b = N'Integer'
SET
  @AllowsNull_33c2979b = 1
SET
  @IsPrimaryKey_33c2979b = 0
SET
  @IsUniqueKey_33c2979b = 0
SET
  @IsReadOnly_33c2979b = 1
SET
  @IsRequired_33c2979b = 0
SET
  @Sequence_33c2979b = 17
SET
  @Status_33c2979b = N'Active'
SET
  @IsCustom_33c2979b = 0
SET
  @MetadataSource_33c2979b = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_33c2979b,
  @IntegrationObjectID = @IntegrationObjectID_33c2979b,
  @Name = @Name_33c2979b,
  @DisplayName = @DisplayName_33c2979b,
  @Description = @Description_33c2979b,
  @Category = @Category_33c2979b,
  @Category_Clear = 1,
  @Type = @Type_33c2979b,
  @Length = @Length_33c2979b,
  @Length_Clear = 1,
  @Precision = @Precision_33c2979b,
  @Precision_Clear = 1,
  @Scale = @Scale_33c2979b,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_33c2979b,
  @DefaultValue = @DefaultValue_33c2979b,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_33c2979b,
  @IsUniqueKey = @IsUniqueKey_33c2979b,
  @IsReadOnly = @IsReadOnly_33c2979b,
  @IsRequired = @IsRequired_33c2979b,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_33c2979b,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_33c2979b,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_33c2979b,
  @Configuration = @Configuration_33c2979b,
  @Configuration_Clear = 1,
  @Status = @Status_33c2979b,
  @IsCustom = @IsCustom_33c2979b,
  @MetadataSource = @MetadataSource_33c2979b;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_969211d0 UNIQUEIDENTIFIER,
@IntegrationObjectID_969211d0 UNIQUEIDENTIFIER,
@Name_969211d0 NVARCHAR(255),
@DisplayName_969211d0 NVARCHAR(255),
@Description_969211d0 NVARCHAR(MAX),
@Category_969211d0 NVARCHAR(100),
@Type_969211d0 NVARCHAR(100),
@Length_969211d0 INT,
@Precision_969211d0 INT,
@Scale_969211d0 INT,
@AllowsNull_969211d0 BIT,
@DefaultValue_969211d0 NVARCHAR(255),
@IsPrimaryKey_969211d0 BIT,
@IsUniqueKey_969211d0 BIT,
@IsReadOnly_969211d0 BIT,
@IsRequired_969211d0 BIT,
@RelatedIntegrationObjectID_969211d0 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_969211d0 NVARCHAR(255),
@Sequence_969211d0 INT,
@Configuration_969211d0 NVARCHAR(MAX),
@Status_969211d0 NVARCHAR(25),
@IsCustom_969211d0 BIT,
@MetadataSource_969211d0 NVARCHAR(20)
SET
  @ID_969211d0 = '300A921E-0166-5396-AB56-35658DE42540'
SET
  @IntegrationObjectID_969211d0 = '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF'
SET
  @Name_969211d0 = N'end-year'
SET
  @DisplayName_969211d0 = N'End Year'
SET
  @Description_969211d0 = N'Year of the affiliation end date; empty for a current/ongoing role; ORCID dates are partial, so month/day may be absent.'
SET
  @Type_969211d0 = N'Integer'
SET
  @AllowsNull_969211d0 = 1
SET
  @IsPrimaryKey_969211d0 = 0
SET
  @IsUniqueKey_969211d0 = 0
SET
  @IsReadOnly_969211d0 = 1
SET
  @IsRequired_969211d0 = 0
SET
  @Sequence_969211d0 = 18
SET
  @Status_969211d0 = N'Active'
SET
  @IsCustom_969211d0 = 0
SET
  @MetadataSource_969211d0 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_969211d0,
  @IntegrationObjectID = @IntegrationObjectID_969211d0,
  @Name = @Name_969211d0,
  @DisplayName = @DisplayName_969211d0,
  @Description = @Description_969211d0,
  @Category = @Category_969211d0,
  @Category_Clear = 1,
  @Type = @Type_969211d0,
  @Length = @Length_969211d0,
  @Length_Clear = 1,
  @Precision = @Precision_969211d0,
  @Precision_Clear = 1,
  @Scale = @Scale_969211d0,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_969211d0,
  @DefaultValue = @DefaultValue_969211d0,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_969211d0,
  @IsUniqueKey = @IsUniqueKey_969211d0,
  @IsReadOnly = @IsReadOnly_969211d0,
  @IsRequired = @IsRequired_969211d0,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_969211d0,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_969211d0,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_969211d0,
  @Configuration = @Configuration_969211d0,
  @Configuration_Clear = 1,
  @Status = @Status_969211d0,
  @IsCustom = @IsCustom_969211d0,
  @MetadataSource = @MetadataSource_969211d0;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_179ed48d UNIQUEIDENTIFIER,
@IntegrationObjectID_179ed48d UNIQUEIDENTIFIER,
@Name_179ed48d NVARCHAR(255),
@DisplayName_179ed48d NVARCHAR(255),
@Description_179ed48d NVARCHAR(MAX),
@Category_179ed48d NVARCHAR(100),
@Type_179ed48d NVARCHAR(100),
@Length_179ed48d INT,
@Precision_179ed48d INT,
@Scale_179ed48d INT,
@AllowsNull_179ed48d BIT,
@DefaultValue_179ed48d NVARCHAR(255),
@IsPrimaryKey_179ed48d BIT,
@IsUniqueKey_179ed48d BIT,
@IsReadOnly_179ed48d BIT,
@IsRequired_179ed48d BIT,
@RelatedIntegrationObjectID_179ed48d UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_179ed48d NVARCHAR(255),
@Sequence_179ed48d INT,
@Configuration_179ed48d NVARCHAR(MAX),
@Status_179ed48d NVARCHAR(25),
@IsCustom_179ed48d BIT,
@MetadataSource_179ed48d NVARCHAR(20)
SET
  @ID_179ed48d = 'C1D39A35-F49D-58A1-8295-6E6B131DFD78'
SET
  @IntegrationObjectID_179ed48d = '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF'
SET
  @Name_179ed48d = N'end-month'
SET
  @DisplayName_179ed48d = N'End Month'
SET
  @Description_179ed48d = N'Month (1-12) of the affiliation end date; empty for a current/ongoing role, when given.'
SET
  @Type_179ed48d = N'Integer'
SET
  @AllowsNull_179ed48d = 1
SET
  @IsPrimaryKey_179ed48d = 0
SET
  @IsUniqueKey_179ed48d = 0
SET
  @IsReadOnly_179ed48d = 1
SET
  @IsRequired_179ed48d = 0
SET
  @Sequence_179ed48d = 19
SET
  @Status_179ed48d = N'Active'
SET
  @IsCustom_179ed48d = 0
SET
  @MetadataSource_179ed48d = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_179ed48d,
  @IntegrationObjectID = @IntegrationObjectID_179ed48d,
  @Name = @Name_179ed48d,
  @DisplayName = @DisplayName_179ed48d,
  @Description = @Description_179ed48d,
  @Category = @Category_179ed48d,
  @Category_Clear = 1,
  @Type = @Type_179ed48d,
  @Length = @Length_179ed48d,
  @Length_Clear = 1,
  @Precision = @Precision_179ed48d,
  @Precision_Clear = 1,
  @Scale = @Scale_179ed48d,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_179ed48d,
  @DefaultValue = @DefaultValue_179ed48d,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_179ed48d,
  @IsUniqueKey = @IsUniqueKey_179ed48d,
  @IsReadOnly = @IsReadOnly_179ed48d,
  @IsRequired = @IsRequired_179ed48d,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_179ed48d,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_179ed48d,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_179ed48d,
  @Configuration = @Configuration_179ed48d,
  @Configuration_Clear = 1,
  @Status = @Status_179ed48d,
  @IsCustom = @IsCustom_179ed48d,
  @MetadataSource = @MetadataSource_179ed48d;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_51705d9b UNIQUEIDENTIFIER,
@IntegrationObjectID_51705d9b UNIQUEIDENTIFIER,
@Name_51705d9b NVARCHAR(255),
@DisplayName_51705d9b NVARCHAR(255),
@Description_51705d9b NVARCHAR(MAX),
@Category_51705d9b NVARCHAR(100),
@Type_51705d9b NVARCHAR(100),
@Length_51705d9b INT,
@Precision_51705d9b INT,
@Scale_51705d9b INT,
@AllowsNull_51705d9b BIT,
@DefaultValue_51705d9b NVARCHAR(255),
@IsPrimaryKey_51705d9b BIT,
@IsUniqueKey_51705d9b BIT,
@IsReadOnly_51705d9b BIT,
@IsRequired_51705d9b BIT,
@RelatedIntegrationObjectID_51705d9b UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_51705d9b NVARCHAR(255),
@Sequence_51705d9b INT,
@Configuration_51705d9b NVARCHAR(MAX),
@Status_51705d9b NVARCHAR(25),
@IsCustom_51705d9b BIT,
@MetadataSource_51705d9b NVARCHAR(20)
SET
  @ID_51705d9b = '23C9A5A5-49AF-5C69-926D-0F5B952F911F'
SET
  @IntegrationObjectID_51705d9b = '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF'
SET
  @Name_51705d9b = N'end-day'
SET
  @DisplayName_51705d9b = N'End Day'
SET
  @Description_51705d9b = N'Day of month of the affiliation end date; empty for a current/ongoing role, when given.'
SET
  @Type_51705d9b = N'Integer'
SET
  @AllowsNull_51705d9b = 1
SET
  @IsPrimaryKey_51705d9b = 0
SET
  @IsUniqueKey_51705d9b = 0
SET
  @IsReadOnly_51705d9b = 1
SET
  @IsRequired_51705d9b = 0
SET
  @Sequence_51705d9b = 20
SET
  @Status_51705d9b = N'Active'
SET
  @IsCustom_51705d9b = 0
SET
  @MetadataSource_51705d9b = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_51705d9b,
  @IntegrationObjectID = @IntegrationObjectID_51705d9b,
  @Name = @Name_51705d9b,
  @DisplayName = @DisplayName_51705d9b,
  @Description = @Description_51705d9b,
  @Category = @Category_51705d9b,
  @Category_Clear = 1,
  @Type = @Type_51705d9b,
  @Length = @Length_51705d9b,
  @Length_Clear = 1,
  @Precision = @Precision_51705d9b,
  @Precision_Clear = 1,
  @Scale = @Scale_51705d9b,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_51705d9b,
  @DefaultValue = @DefaultValue_51705d9b,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_51705d9b,
  @IsUniqueKey = @IsUniqueKey_51705d9b,
  @IsReadOnly = @IsReadOnly_51705d9b,
  @IsRequired = @IsRequired_51705d9b,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_51705d9b,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_51705d9b,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_51705d9b,
  @Configuration = @Configuration_51705d9b,
  @Configuration_Clear = 1,
  @Status = @Status_51705d9b,
  @IsCustom = @IsCustom_51705d9b,
  @MetadataSource = @MetadataSource_51705d9b;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_2bf8706c UNIQUEIDENTIFIER,
@IntegrationObjectID_2bf8706c UNIQUEIDENTIFIER,
@Name_2bf8706c NVARCHAR(255),
@DisplayName_2bf8706c NVARCHAR(255),
@Description_2bf8706c NVARCHAR(MAX),
@Category_2bf8706c NVARCHAR(100),
@Type_2bf8706c NVARCHAR(100),
@Length_2bf8706c INT,
@Precision_2bf8706c INT,
@Scale_2bf8706c INT,
@AllowsNull_2bf8706c BIT,
@DefaultValue_2bf8706c NVARCHAR(255),
@IsPrimaryKey_2bf8706c BIT,
@IsUniqueKey_2bf8706c BIT,
@IsReadOnly_2bf8706c BIT,
@IsRequired_2bf8706c BIT,
@RelatedIntegrationObjectID_2bf8706c UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_2bf8706c NVARCHAR(255),
@Sequence_2bf8706c INT,
@Configuration_2bf8706c NVARCHAR(MAX),
@Status_2bf8706c NVARCHAR(25),
@IsCustom_2bf8706c BIT,
@MetadataSource_2bf8706c NVARCHAR(20)
SET
  @ID_2bf8706c = '26E0B5B8-BD26-5A75-B8D8-A339002CCAFD'
SET
  @IntegrationObjectID_2bf8706c = '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF'
SET
  @Name_2bf8706c = N'organization-name'
SET
  @DisplayName_2bf8706c = N'Organization Name'
SET
  @Description_2bf8706c = N'Name of the organization. Lifted from organization.name.'
SET
  @Type_2bf8706c = N'String'
SET
  @Length_2bf8706c = 1000
SET
  @AllowsNull_2bf8706c = 1
SET
  @IsPrimaryKey_2bf8706c = 0
SET
  @IsUniqueKey_2bf8706c = 0
SET
  @IsReadOnly_2bf8706c = 1
SET
  @IsRequired_2bf8706c = 0
SET
  @Sequence_2bf8706c = 21
SET
  @Status_2bf8706c = N'Active'
SET
  @IsCustom_2bf8706c = 0
SET
  @MetadataSource_2bf8706c = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_2bf8706c,
  @IntegrationObjectID = @IntegrationObjectID_2bf8706c,
  @Name = @Name_2bf8706c,
  @DisplayName = @DisplayName_2bf8706c,
  @Description = @Description_2bf8706c,
  @Category = @Category_2bf8706c,
  @Category_Clear = 1,
  @Type = @Type_2bf8706c,
  @Length = @Length_2bf8706c,
  @Precision = @Precision_2bf8706c,
  @Precision_Clear = 1,
  @Scale = @Scale_2bf8706c,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_2bf8706c,
  @DefaultValue = @DefaultValue_2bf8706c,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_2bf8706c,
  @IsUniqueKey = @IsUniqueKey_2bf8706c,
  @IsReadOnly = @IsReadOnly_2bf8706c,
  @IsRequired = @IsRequired_2bf8706c,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_2bf8706c,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_2bf8706c,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_2bf8706c,
  @Configuration = @Configuration_2bf8706c,
  @Configuration_Clear = 1,
  @Status = @Status_2bf8706c,
  @IsCustom = @IsCustom_2bf8706c,
  @MetadataSource = @MetadataSource_2bf8706c;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_85efda60 UNIQUEIDENTIFIER,
@IntegrationObjectID_85efda60 UNIQUEIDENTIFIER,
@Name_85efda60 NVARCHAR(255),
@DisplayName_85efda60 NVARCHAR(255),
@Description_85efda60 NVARCHAR(MAX),
@Category_85efda60 NVARCHAR(100),
@Type_85efda60 NVARCHAR(100),
@Length_85efda60 INT,
@Precision_85efda60 INT,
@Scale_85efda60 INT,
@AllowsNull_85efda60 BIT,
@DefaultValue_85efda60 NVARCHAR(255),
@IsPrimaryKey_85efda60 BIT,
@IsUniqueKey_85efda60 BIT,
@IsReadOnly_85efda60 BIT,
@IsRequired_85efda60 BIT,
@RelatedIntegrationObjectID_85efda60 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_85efda60 NVARCHAR(255),
@Sequence_85efda60 INT,
@Configuration_85efda60 NVARCHAR(MAX),
@Status_85efda60 NVARCHAR(25),
@IsCustom_85efda60 BIT,
@MetadataSource_85efda60 NVARCHAR(20)
SET
  @ID_85efda60 = '1AC712C1-932B-5465-94A0-9FBECFAF740A'
SET
  @IntegrationObjectID_85efda60 = '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF'
SET
  @Name_85efda60 = N'organization-city'
SET
  @DisplayName_85efda60 = N'Organization City'
SET
  @Description_85efda60 = N'City of the organization. Lifted from organization.address.city.'
SET
  @Type_85efda60 = N'String'
SET
  @Length_85efda60 = 255
SET
  @AllowsNull_85efda60 = 1
SET
  @IsPrimaryKey_85efda60 = 0
SET
  @IsUniqueKey_85efda60 = 0
SET
  @IsReadOnly_85efda60 = 1
SET
  @IsRequired_85efda60 = 0
SET
  @Sequence_85efda60 = 22
SET
  @Status_85efda60 = N'Active'
SET
  @IsCustom_85efda60 = 0
SET
  @MetadataSource_85efda60 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_85efda60,
  @IntegrationObjectID = @IntegrationObjectID_85efda60,
  @Name = @Name_85efda60,
  @DisplayName = @DisplayName_85efda60,
  @Description = @Description_85efda60,
  @Category = @Category_85efda60,
  @Category_Clear = 1,
  @Type = @Type_85efda60,
  @Length = @Length_85efda60,
  @Precision = @Precision_85efda60,
  @Precision_Clear = 1,
  @Scale = @Scale_85efda60,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_85efda60,
  @DefaultValue = @DefaultValue_85efda60,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_85efda60,
  @IsUniqueKey = @IsUniqueKey_85efda60,
  @IsReadOnly = @IsReadOnly_85efda60,
  @IsRequired = @IsRequired_85efda60,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_85efda60,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_85efda60,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_85efda60,
  @Configuration = @Configuration_85efda60,
  @Configuration_Clear = 1,
  @Status = @Status_85efda60,
  @IsCustom = @IsCustom_85efda60,
  @MetadataSource = @MetadataSource_85efda60;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_3f59d65a UNIQUEIDENTIFIER,
@IntegrationObjectID_3f59d65a UNIQUEIDENTIFIER,
@Name_3f59d65a NVARCHAR(255),
@DisplayName_3f59d65a NVARCHAR(255),
@Description_3f59d65a NVARCHAR(MAX),
@Category_3f59d65a NVARCHAR(100),
@Type_3f59d65a NVARCHAR(100),
@Length_3f59d65a INT,
@Precision_3f59d65a INT,
@Scale_3f59d65a INT,
@AllowsNull_3f59d65a BIT,
@DefaultValue_3f59d65a NVARCHAR(255),
@IsPrimaryKey_3f59d65a BIT,
@IsUniqueKey_3f59d65a BIT,
@IsReadOnly_3f59d65a BIT,
@IsRequired_3f59d65a BIT,
@RelatedIntegrationObjectID_3f59d65a UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_3f59d65a NVARCHAR(255),
@Sequence_3f59d65a INT,
@Configuration_3f59d65a NVARCHAR(MAX),
@Status_3f59d65a NVARCHAR(25),
@IsCustom_3f59d65a BIT,
@MetadataSource_3f59d65a NVARCHAR(20)
SET
  @ID_3f59d65a = '8F3BFB6A-A40C-5E62-8214-355A52D8CEA7'
SET
  @IntegrationObjectID_3f59d65a = '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF'
SET
  @Name_3f59d65a = N'organization-region'
SET
  @DisplayName_3f59d65a = N'Organization Region'
SET
  @Description_3f59d65a = N'Region/state of the organization. Lifted from organization.address.region.'
SET
  @Type_3f59d65a = N'String'
SET
  @Length_3f59d65a = 255
SET
  @AllowsNull_3f59d65a = 1
SET
  @IsPrimaryKey_3f59d65a = 0
SET
  @IsUniqueKey_3f59d65a = 0
SET
  @IsReadOnly_3f59d65a = 1
SET
  @IsRequired_3f59d65a = 0
SET
  @Sequence_3f59d65a = 23
SET
  @Status_3f59d65a = N'Active'
SET
  @IsCustom_3f59d65a = 0
SET
  @MetadataSource_3f59d65a = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_3f59d65a,
  @IntegrationObjectID = @IntegrationObjectID_3f59d65a,
  @Name = @Name_3f59d65a,
  @DisplayName = @DisplayName_3f59d65a,
  @Description = @Description_3f59d65a,
  @Category = @Category_3f59d65a,
  @Category_Clear = 1,
  @Type = @Type_3f59d65a,
  @Length = @Length_3f59d65a,
  @Precision = @Precision_3f59d65a,
  @Precision_Clear = 1,
  @Scale = @Scale_3f59d65a,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_3f59d65a,
  @DefaultValue = @DefaultValue_3f59d65a,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_3f59d65a,
  @IsUniqueKey = @IsUniqueKey_3f59d65a,
  @IsReadOnly = @IsReadOnly_3f59d65a,
  @IsRequired = @IsRequired_3f59d65a,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_3f59d65a,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_3f59d65a,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_3f59d65a,
  @Configuration = @Configuration_3f59d65a,
  @Configuration_Clear = 1,
  @Status = @Status_3f59d65a,
  @IsCustom = @IsCustom_3f59d65a,
  @MetadataSource = @MetadataSource_3f59d65a;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_56322830 UNIQUEIDENTIFIER,
@IntegrationObjectID_56322830 UNIQUEIDENTIFIER,
@Name_56322830 NVARCHAR(255),
@DisplayName_56322830 NVARCHAR(255),
@Description_56322830 NVARCHAR(MAX),
@Category_56322830 NVARCHAR(100),
@Type_56322830 NVARCHAR(100),
@Length_56322830 INT,
@Precision_56322830 INT,
@Scale_56322830 INT,
@AllowsNull_56322830 BIT,
@DefaultValue_56322830 NVARCHAR(255),
@IsPrimaryKey_56322830 BIT,
@IsUniqueKey_56322830 BIT,
@IsReadOnly_56322830 BIT,
@IsRequired_56322830 BIT,
@RelatedIntegrationObjectID_56322830 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_56322830 NVARCHAR(255),
@Sequence_56322830 INT,
@Configuration_56322830 NVARCHAR(MAX),
@Status_56322830 NVARCHAR(25),
@IsCustom_56322830 BIT,
@MetadataSource_56322830 NVARCHAR(20)
SET
  @ID_56322830 = 'B71920C5-E3D2-5C44-BC0B-4FD2E2B6E8A5'
SET
  @IntegrationObjectID_56322830 = '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF'
SET
  @Name_56322830 = N'organization-country'
SET
  @DisplayName_56322830 = N'Organization Country'
SET
  @Description_56322830 = N'ISO country code of the organization. Lifted from organization.address.country.'
SET
  @Type_56322830 = N'String'
SET
  @Length_56322830 = 50
SET
  @AllowsNull_56322830 = 1
SET
  @IsPrimaryKey_56322830 = 0
SET
  @IsUniqueKey_56322830 = 0
SET
  @IsReadOnly_56322830 = 1
SET
  @IsRequired_56322830 = 0
SET
  @Sequence_56322830 = 24
SET
  @Status_56322830 = N'Active'
SET
  @IsCustom_56322830 = 0
SET
  @MetadataSource_56322830 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_56322830,
  @IntegrationObjectID = @IntegrationObjectID_56322830,
  @Name = @Name_56322830,
  @DisplayName = @DisplayName_56322830,
  @Description = @Description_56322830,
  @Category = @Category_56322830,
  @Category_Clear = 1,
  @Type = @Type_56322830,
  @Length = @Length_56322830,
  @Precision = @Precision_56322830,
  @Precision_Clear = 1,
  @Scale = @Scale_56322830,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_56322830,
  @DefaultValue = @DefaultValue_56322830,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_56322830,
  @IsUniqueKey = @IsUniqueKey_56322830,
  @IsReadOnly = @IsReadOnly_56322830,
  @IsRequired = @IsRequired_56322830,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_56322830,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_56322830,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_56322830,
  @Configuration = @Configuration_56322830,
  @Configuration_Clear = 1,
  @Status = @Status_56322830,
  @IsCustom = @IsCustom_56322830,
  @MetadataSource = @MetadataSource_56322830;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_cab557bd UNIQUEIDENTIFIER,
@IntegrationObjectID_cab557bd UNIQUEIDENTIFIER,
@Name_cab557bd NVARCHAR(255),
@DisplayName_cab557bd NVARCHAR(255),
@Description_cab557bd NVARCHAR(MAX),
@Category_cab557bd NVARCHAR(100),
@Type_cab557bd NVARCHAR(100),
@Length_cab557bd INT,
@Precision_cab557bd INT,
@Scale_cab557bd INT,
@AllowsNull_cab557bd BIT,
@DefaultValue_cab557bd NVARCHAR(255),
@IsPrimaryKey_cab557bd BIT,
@IsUniqueKey_cab557bd BIT,
@IsReadOnly_cab557bd BIT,
@IsRequired_cab557bd BIT,
@RelatedIntegrationObjectID_cab557bd UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_cab557bd NVARCHAR(255),
@Sequence_cab557bd INT,
@Configuration_cab557bd NVARCHAR(MAX),
@Status_cab557bd NVARCHAR(25),
@IsCustom_cab557bd BIT,
@MetadataSource_cab557bd NVARCHAR(20)
SET
  @ID_cab557bd = '2E80B705-8114-58D2-89C7-948217B0F123'
SET
  @IntegrationObjectID_cab557bd = '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF'
SET
  @Name_cab557bd = N'organization-disambiguated-id'
SET
  @DisplayName_cab557bd = N'Organization Disambiguated Id'
SET
  @Description_cab557bd = N'Canonical identifier of the organization in the disambiguation source (e.g. a RINGGOLD or ROR id), so the same institution matches across records.'
SET
  @Type_cab557bd = N'String'
SET
  @Length_cab557bd = 255
SET
  @AllowsNull_cab557bd = 1
SET
  @IsPrimaryKey_cab557bd = 0
SET
  @IsUniqueKey_cab557bd = 0
SET
  @IsReadOnly_cab557bd = 1
SET
  @IsRequired_cab557bd = 0
SET
  @Sequence_cab557bd = 25
SET
  @Status_cab557bd = N'Active'
SET
  @IsCustom_cab557bd = 0
SET
  @MetadataSource_cab557bd = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_cab557bd,
  @IntegrationObjectID = @IntegrationObjectID_cab557bd,
  @Name = @Name_cab557bd,
  @DisplayName = @DisplayName_cab557bd,
  @Description = @Description_cab557bd,
  @Category = @Category_cab557bd,
  @Category_Clear = 1,
  @Type = @Type_cab557bd,
  @Length = @Length_cab557bd,
  @Precision = @Precision_cab557bd,
  @Precision_Clear = 1,
  @Scale = @Scale_cab557bd,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_cab557bd,
  @DefaultValue = @DefaultValue_cab557bd,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_cab557bd,
  @IsUniqueKey = @IsUniqueKey_cab557bd,
  @IsReadOnly = @IsReadOnly_cab557bd,
  @IsRequired = @IsRequired_cab557bd,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_cab557bd,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_cab557bd,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_cab557bd,
  @Configuration = @Configuration_cab557bd,
  @Configuration_Clear = 1,
  @Status = @Status_cab557bd,
  @IsCustom = @IsCustom_cab557bd,
  @MetadataSource = @MetadataSource_cab557bd;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_c556404d UNIQUEIDENTIFIER,
@IntegrationObjectID_c556404d UNIQUEIDENTIFIER,
@Name_c556404d NVARCHAR(255),
@DisplayName_c556404d NVARCHAR(255),
@Description_c556404d NVARCHAR(MAX),
@Category_c556404d NVARCHAR(100),
@Type_c556404d NVARCHAR(100),
@Length_c556404d INT,
@Precision_c556404d INT,
@Scale_c556404d INT,
@AllowsNull_c556404d BIT,
@DefaultValue_c556404d NVARCHAR(255),
@IsPrimaryKey_c556404d BIT,
@IsUniqueKey_c556404d BIT,
@IsReadOnly_c556404d BIT,
@IsRequired_c556404d BIT,
@RelatedIntegrationObjectID_c556404d UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_c556404d NVARCHAR(255),
@Sequence_c556404d INT,
@Configuration_c556404d NVARCHAR(MAX),
@Status_c556404d NVARCHAR(25),
@IsCustom_c556404d BIT,
@MetadataSource_c556404d NVARCHAR(20)
SET
  @ID_c556404d = '75787A6A-A4F6-5CC3-A00F-6F1A66ED1538'
SET
  @IntegrationObjectID_c556404d = '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF'
SET
  @Name_c556404d = N'organization-disambiguation-source'
SET
  @DisplayName_c556404d = N'Organization Disambiguation Source'
SET
  @Description_c556404d = N'Registry the disambiguated id comes from (RINGGOLD, ROR, FUNDREF, GRID, LEI).'
SET
  @Type_c556404d = N'String'
SET
  @Length_c556404d = 100
SET
  @AllowsNull_c556404d = 1
SET
  @IsPrimaryKey_c556404d = 0
SET
  @IsUniqueKey_c556404d = 0
SET
  @IsReadOnly_c556404d = 1
SET
  @IsRequired_c556404d = 0
SET
  @Sequence_c556404d = 26
SET
  @Status_c556404d = N'Active'
SET
  @IsCustom_c556404d = 0
SET
  @MetadataSource_c556404d = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_c556404d,
  @IntegrationObjectID = @IntegrationObjectID_c556404d,
  @Name = @Name_c556404d,
  @DisplayName = @DisplayName_c556404d,
  @Description = @Description_c556404d,
  @Category = @Category_c556404d,
  @Category_Clear = 1,
  @Type = @Type_c556404d,
  @Length = @Length_c556404d,
  @Precision = @Precision_c556404d,
  @Precision_Clear = 1,
  @Scale = @Scale_c556404d,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_c556404d,
  @DefaultValue = @DefaultValue_c556404d,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_c556404d,
  @IsUniqueKey = @IsUniqueKey_c556404d,
  @IsReadOnly = @IsReadOnly_c556404d,
  @IsRequired = @IsRequired_c556404d,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_c556404d,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_c556404d,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_c556404d,
  @Configuration = @Configuration_c556404d,
  @Configuration_Clear = 1,
  @Status = @Status_c556404d,
  @IsCustom = @IsCustom_c556404d,
  @MetadataSource = @MetadataSource_c556404d;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_bb522409 UNIQUEIDENTIFIER,
@IntegrationObjectID_bb522409 UNIQUEIDENTIFIER,
@Name_bb522409 NVARCHAR(255),
@DisplayName_bb522409 NVARCHAR(255),
@Description_bb522409 NVARCHAR(MAX),
@Category_bb522409 NVARCHAR(100),
@Type_bb522409 NVARCHAR(100),
@Length_bb522409 INT,
@Precision_bb522409 INT,
@Scale_bb522409 INT,
@AllowsNull_bb522409 BIT,
@DefaultValue_bb522409 NVARCHAR(255),
@IsPrimaryKey_bb522409 BIT,
@IsUniqueKey_bb522409 BIT,
@IsReadOnly_bb522409 BIT,
@IsRequired_bb522409 BIT,
@RelatedIntegrationObjectID_bb522409 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_bb522409 NVARCHAR(255),
@Sequence_bb522409 INT,
@Configuration_bb522409 NVARCHAR(MAX),
@Status_bb522409 NVARCHAR(25),
@IsCustom_bb522409 BIT,
@MetadataSource_bb522409 NVARCHAR(20)
SET
  @ID_bb522409 = '4606D2EB-CC7D-53FF-B7E1-035378F47F35'
SET
  @IntegrationObjectID_bb522409 = '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF'
SET
  @Name_bb522409 = N'source-name'
SET
  @DisplayName_bb522409 = N'Source Name'
SET
  @Description_bb522409 = N'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.'
SET
  @Type_bb522409 = N'String'
SET
  @Length_bb522409 = 500
SET
  @AllowsNull_bb522409 = 1
SET
  @IsPrimaryKey_bb522409 = 0
SET
  @IsUniqueKey_bb522409 = 0
SET
  @IsReadOnly_bb522409 = 1
SET
  @IsRequired_bb522409 = 0
SET
  @Sequence_bb522409 = 27
SET
  @Status_bb522409 = N'Active'
SET
  @IsCustom_bb522409 = 0
SET
  @MetadataSource_bb522409 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_bb522409,
  @IntegrationObjectID = @IntegrationObjectID_bb522409,
  @Name = @Name_bb522409,
  @DisplayName = @DisplayName_bb522409,
  @Description = @Description_bb522409,
  @Category = @Category_bb522409,
  @Category_Clear = 1,
  @Type = @Type_bb522409,
  @Length = @Length_bb522409,
  @Precision = @Precision_bb522409,
  @Precision_Clear = 1,
  @Scale = @Scale_bb522409,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_bb522409,
  @DefaultValue = @DefaultValue_bb522409,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_bb522409,
  @IsUniqueKey = @IsUniqueKey_bb522409,
  @IsReadOnly = @IsReadOnly_bb522409,
  @IsRequired = @IsRequired_bb522409,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_bb522409,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_bb522409,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_bb522409,
  @Configuration = @Configuration_bb522409,
  @Configuration_Clear = 1,
  @Status = @Status_bb522409,
  @IsCustom = @IsCustom_bb522409,
  @MetadataSource = @MetadataSource_bb522409;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_8c095baa UNIQUEIDENTIFIER,
@IntegrationObjectID_8c095baa UNIQUEIDENTIFIER,
@Name_8c095baa NVARCHAR(255),
@DisplayName_8c095baa NVARCHAR(255),
@Description_8c095baa NVARCHAR(MAX),
@Category_8c095baa NVARCHAR(100),
@Type_8c095baa NVARCHAR(100),
@Length_8c095baa INT,
@Precision_8c095baa INT,
@Scale_8c095baa INT,
@AllowsNull_8c095baa BIT,
@DefaultValue_8c095baa NVARCHAR(255),
@IsPrimaryKey_8c095baa BIT,
@IsUniqueKey_8c095baa BIT,
@IsReadOnly_8c095baa BIT,
@IsRequired_8c095baa BIT,
@RelatedIntegrationObjectID_8c095baa UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_8c095baa NVARCHAR(255),
@Sequence_8c095baa INT,
@Configuration_8c095baa NVARCHAR(MAX),
@Status_8c095baa NVARCHAR(25),
@IsCustom_8c095baa BIT,
@MetadataSource_8c095baa NVARCHAR(20)
SET
  @ID_8c095baa = '9395F588-4BBE-5082-AF61-95E9AC2E4813'
SET
  @IntegrationObjectID_8c095baa = '16E0F29F-B9FF-4EED-97B7-47F355A0F9FF'
SET
  @Name_8c095baa = N'source-orcid'
SET
  @DisplayName_8c095baa = N'Source Orcid'
SET
  @Description_8c095baa = N'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.'
SET
  @Type_8c095baa = N'String'
SET
  @Length_8c095baa = 19
SET
  @AllowsNull_8c095baa = 1
SET
  @IsPrimaryKey_8c095baa = 0
SET
  @IsUniqueKey_8c095baa = 0
SET
  @IsReadOnly_8c095baa = 1
SET
  @IsRequired_8c095baa = 0
SET
  @Sequence_8c095baa = 28
SET
  @Status_8c095baa = N'Active'
SET
  @IsCustom_8c095baa = 0
SET
  @MetadataSource_8c095baa = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_8c095baa,
  @IntegrationObjectID = @IntegrationObjectID_8c095baa,
  @Name = @Name_8c095baa,
  @DisplayName = @DisplayName_8c095baa,
  @Description = @Description_8c095baa,
  @Category = @Category_8c095baa,
  @Category_Clear = 1,
  @Type = @Type_8c095baa,
  @Length = @Length_8c095baa,
  @Precision = @Precision_8c095baa,
  @Precision_Clear = 1,
  @Scale = @Scale_8c095baa,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_8c095baa,
  @DefaultValue = @DefaultValue_8c095baa,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_8c095baa,
  @IsUniqueKey = @IsUniqueKey_8c095baa,
  @IsReadOnly = @IsReadOnly_8c095baa,
  @IsRequired = @IsRequired_8c095baa,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_8c095baa,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_8c095baa,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_8c095baa,
  @Configuration = @Configuration_8c095baa,
  @Configuration_Clear = 1,
  @Status = @Status_8c095baa,
  @IsCustom = @IsCustom_8c095baa,
  @MetadataSource = @MetadataSource_8c095baa;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_7c8ff91b UNIQUEIDENTIFIER,
@IntegrationObjectID_7c8ff91b UNIQUEIDENTIFIER,
@Name_7c8ff91b NVARCHAR(255),
@DisplayName_7c8ff91b NVARCHAR(255),
@Description_7c8ff91b NVARCHAR(MAX),
@Category_7c8ff91b NVARCHAR(100),
@Type_7c8ff91b NVARCHAR(100),
@Length_7c8ff91b INT,
@Precision_7c8ff91b INT,
@Scale_7c8ff91b INT,
@AllowsNull_7c8ff91b BIT,
@DefaultValue_7c8ff91b NVARCHAR(255),
@IsPrimaryKey_7c8ff91b BIT,
@IsUniqueKey_7c8ff91b BIT,
@IsReadOnly_7c8ff91b BIT,
@IsRequired_7c8ff91b BIT,
@RelatedIntegrationObjectID_7c8ff91b UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_7c8ff91b NVARCHAR(255),
@Sequence_7c8ff91b INT,
@Configuration_7c8ff91b NVARCHAR(MAX),
@Status_7c8ff91b NVARCHAR(25),
@IsCustom_7c8ff91b BIT,
@MetadataSource_7c8ff91b NVARCHAR(20)
SET
  @ID_7c8ff91b = '86C43653-DDF5-5585-B1F8-B55369488588'
SET
  @IntegrationObjectID_7c8ff91b = 'A28BB703-8E34-4725-AF07-CDE7E42EB046'
SET
  @Name_7c8ff91b = N'start-year'
SET
  @DisplayName_7c8ff91b = N'Start Year'
SET
  @Description_7c8ff91b = N'Year of the affiliation start date; ORCID dates are partial, so month/day may be absent.'
SET
  @Type_7c8ff91b = N'Integer'
SET
  @AllowsNull_7c8ff91b = 1
SET
  @IsPrimaryKey_7c8ff91b = 0
SET
  @IsUniqueKey_7c8ff91b = 0
SET
  @IsReadOnly_7c8ff91b = 1
SET
  @IsRequired_7c8ff91b = 0
SET
  @Sequence_7c8ff91b = 15
SET
  @Status_7c8ff91b = N'Active'
SET
  @IsCustom_7c8ff91b = 0
SET
  @MetadataSource_7c8ff91b = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_7c8ff91b,
  @IntegrationObjectID = @IntegrationObjectID_7c8ff91b,
  @Name = @Name_7c8ff91b,
  @DisplayName = @DisplayName_7c8ff91b,
  @Description = @Description_7c8ff91b,
  @Category = @Category_7c8ff91b,
  @Category_Clear = 1,
  @Type = @Type_7c8ff91b,
  @Length = @Length_7c8ff91b,
  @Length_Clear = 1,
  @Precision = @Precision_7c8ff91b,
  @Precision_Clear = 1,
  @Scale = @Scale_7c8ff91b,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_7c8ff91b,
  @DefaultValue = @DefaultValue_7c8ff91b,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_7c8ff91b,
  @IsUniqueKey = @IsUniqueKey_7c8ff91b,
  @IsReadOnly = @IsReadOnly_7c8ff91b,
  @IsRequired = @IsRequired_7c8ff91b,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_7c8ff91b,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_7c8ff91b,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_7c8ff91b,
  @Configuration = @Configuration_7c8ff91b,
  @Configuration_Clear = 1,
  @Status = @Status_7c8ff91b,
  @IsCustom = @IsCustom_7c8ff91b,
  @MetadataSource = @MetadataSource_7c8ff91b;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_be806331 UNIQUEIDENTIFIER,
@IntegrationObjectID_be806331 UNIQUEIDENTIFIER,
@Name_be806331 NVARCHAR(255),
@DisplayName_be806331 NVARCHAR(255),
@Description_be806331 NVARCHAR(MAX),
@Category_be806331 NVARCHAR(100),
@Type_be806331 NVARCHAR(100),
@Length_be806331 INT,
@Precision_be806331 INT,
@Scale_be806331 INT,
@AllowsNull_be806331 BIT,
@DefaultValue_be806331 NVARCHAR(255),
@IsPrimaryKey_be806331 BIT,
@IsUniqueKey_be806331 BIT,
@IsReadOnly_be806331 BIT,
@IsRequired_be806331 BIT,
@RelatedIntegrationObjectID_be806331 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_be806331 NVARCHAR(255),
@Sequence_be806331 INT,
@Configuration_be806331 NVARCHAR(MAX),
@Status_be806331 NVARCHAR(25),
@IsCustom_be806331 BIT,
@MetadataSource_be806331 NVARCHAR(20)
SET
  @ID_be806331 = '09475DE3-0E97-561B-92A8-E17CB37FDCBA'
SET
  @IntegrationObjectID_be806331 = 'A28BB703-8E34-4725-AF07-CDE7E42EB046'
SET
  @Name_be806331 = N'start-month'
SET
  @DisplayName_be806331 = N'Start Month'
SET
  @Description_be806331 = N'Month (1-12) of the affiliation start date, when given.'
SET
  @Type_be806331 = N'Integer'
SET
  @AllowsNull_be806331 = 1
SET
  @IsPrimaryKey_be806331 = 0
SET
  @IsUniqueKey_be806331 = 0
SET
  @IsReadOnly_be806331 = 1
SET
  @IsRequired_be806331 = 0
SET
  @Sequence_be806331 = 16
SET
  @Status_be806331 = N'Active'
SET
  @IsCustom_be806331 = 0
SET
  @MetadataSource_be806331 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_be806331,
  @IntegrationObjectID = @IntegrationObjectID_be806331,
  @Name = @Name_be806331,
  @DisplayName = @DisplayName_be806331,
  @Description = @Description_be806331,
  @Category = @Category_be806331,
  @Category_Clear = 1,
  @Type = @Type_be806331,
  @Length = @Length_be806331,
  @Length_Clear = 1,
  @Precision = @Precision_be806331,
  @Precision_Clear = 1,
  @Scale = @Scale_be806331,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_be806331,
  @DefaultValue = @DefaultValue_be806331,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_be806331,
  @IsUniqueKey = @IsUniqueKey_be806331,
  @IsReadOnly = @IsReadOnly_be806331,
  @IsRequired = @IsRequired_be806331,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_be806331,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_be806331,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_be806331,
  @Configuration = @Configuration_be806331,
  @Configuration_Clear = 1,
  @Status = @Status_be806331,
  @IsCustom = @IsCustom_be806331,
  @MetadataSource = @MetadataSource_be806331;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_a2e1456a UNIQUEIDENTIFIER,
@IntegrationObjectID_a2e1456a UNIQUEIDENTIFIER,
@Name_a2e1456a NVARCHAR(255),
@DisplayName_a2e1456a NVARCHAR(255),
@Description_a2e1456a NVARCHAR(MAX),
@Category_a2e1456a NVARCHAR(100),
@Type_a2e1456a NVARCHAR(100),
@Length_a2e1456a INT,
@Precision_a2e1456a INT,
@Scale_a2e1456a INT,
@AllowsNull_a2e1456a BIT,
@DefaultValue_a2e1456a NVARCHAR(255),
@IsPrimaryKey_a2e1456a BIT,
@IsUniqueKey_a2e1456a BIT,
@IsReadOnly_a2e1456a BIT,
@IsRequired_a2e1456a BIT,
@RelatedIntegrationObjectID_a2e1456a UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_a2e1456a NVARCHAR(255),
@Sequence_a2e1456a INT,
@Configuration_a2e1456a NVARCHAR(MAX),
@Status_a2e1456a NVARCHAR(25),
@IsCustom_a2e1456a BIT,
@MetadataSource_a2e1456a NVARCHAR(20)
SET
  @ID_a2e1456a = 'EF682ADE-FDF2-5BDD-B71E-29984E5594FF'
SET
  @IntegrationObjectID_a2e1456a = 'A28BB703-8E34-4725-AF07-CDE7E42EB046'
SET
  @Name_a2e1456a = N'start-day'
SET
  @DisplayName_a2e1456a = N'Start Day'
SET
  @Description_a2e1456a = N'Day of month of the affiliation start date, when given.'
SET
  @Type_a2e1456a = N'Integer'
SET
  @AllowsNull_a2e1456a = 1
SET
  @IsPrimaryKey_a2e1456a = 0
SET
  @IsUniqueKey_a2e1456a = 0
SET
  @IsReadOnly_a2e1456a = 1
SET
  @IsRequired_a2e1456a = 0
SET
  @Sequence_a2e1456a = 17
SET
  @Status_a2e1456a = N'Active'
SET
  @IsCustom_a2e1456a = 0
SET
  @MetadataSource_a2e1456a = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_a2e1456a,
  @IntegrationObjectID = @IntegrationObjectID_a2e1456a,
  @Name = @Name_a2e1456a,
  @DisplayName = @DisplayName_a2e1456a,
  @Description = @Description_a2e1456a,
  @Category = @Category_a2e1456a,
  @Category_Clear = 1,
  @Type = @Type_a2e1456a,
  @Length = @Length_a2e1456a,
  @Length_Clear = 1,
  @Precision = @Precision_a2e1456a,
  @Precision_Clear = 1,
  @Scale = @Scale_a2e1456a,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_a2e1456a,
  @DefaultValue = @DefaultValue_a2e1456a,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_a2e1456a,
  @IsUniqueKey = @IsUniqueKey_a2e1456a,
  @IsReadOnly = @IsReadOnly_a2e1456a,
  @IsRequired = @IsRequired_a2e1456a,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_a2e1456a,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_a2e1456a,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_a2e1456a,
  @Configuration = @Configuration_a2e1456a,
  @Configuration_Clear = 1,
  @Status = @Status_a2e1456a,
  @IsCustom = @IsCustom_a2e1456a,
  @MetadataSource = @MetadataSource_a2e1456a;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_af941700 UNIQUEIDENTIFIER,
@IntegrationObjectID_af941700 UNIQUEIDENTIFIER,
@Name_af941700 NVARCHAR(255),
@DisplayName_af941700 NVARCHAR(255),
@Description_af941700 NVARCHAR(MAX),
@Category_af941700 NVARCHAR(100),
@Type_af941700 NVARCHAR(100),
@Length_af941700 INT,
@Precision_af941700 INT,
@Scale_af941700 INT,
@AllowsNull_af941700 BIT,
@DefaultValue_af941700 NVARCHAR(255),
@IsPrimaryKey_af941700 BIT,
@IsUniqueKey_af941700 BIT,
@IsReadOnly_af941700 BIT,
@IsRequired_af941700 BIT,
@RelatedIntegrationObjectID_af941700 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_af941700 NVARCHAR(255),
@Sequence_af941700 INT,
@Configuration_af941700 NVARCHAR(MAX),
@Status_af941700 NVARCHAR(25),
@IsCustom_af941700 BIT,
@MetadataSource_af941700 NVARCHAR(20)
SET
  @ID_af941700 = '1DEFF9AF-CDA3-5DF2-81AE-22E15968A501'
SET
  @IntegrationObjectID_af941700 = 'A28BB703-8E34-4725-AF07-CDE7E42EB046'
SET
  @Name_af941700 = N'end-year'
SET
  @DisplayName_af941700 = N'End Year'
SET
  @Description_af941700 = N'Year of the affiliation end date; empty for a current/ongoing role; ORCID dates are partial, so month/day may be absent.'
SET
  @Type_af941700 = N'Integer'
SET
  @AllowsNull_af941700 = 1
SET
  @IsPrimaryKey_af941700 = 0
SET
  @IsUniqueKey_af941700 = 0
SET
  @IsReadOnly_af941700 = 1
SET
  @IsRequired_af941700 = 0
SET
  @Sequence_af941700 = 18
SET
  @Status_af941700 = N'Active'
SET
  @IsCustom_af941700 = 0
SET
  @MetadataSource_af941700 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_af941700,
  @IntegrationObjectID = @IntegrationObjectID_af941700,
  @Name = @Name_af941700,
  @DisplayName = @DisplayName_af941700,
  @Description = @Description_af941700,
  @Category = @Category_af941700,
  @Category_Clear = 1,
  @Type = @Type_af941700,
  @Length = @Length_af941700,
  @Length_Clear = 1,
  @Precision = @Precision_af941700,
  @Precision_Clear = 1,
  @Scale = @Scale_af941700,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_af941700,
  @DefaultValue = @DefaultValue_af941700,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_af941700,
  @IsUniqueKey = @IsUniqueKey_af941700,
  @IsReadOnly = @IsReadOnly_af941700,
  @IsRequired = @IsRequired_af941700,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_af941700,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_af941700,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_af941700,
  @Configuration = @Configuration_af941700,
  @Configuration_Clear = 1,
  @Status = @Status_af941700,
  @IsCustom = @IsCustom_af941700,
  @MetadataSource = @MetadataSource_af941700;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_f72920c9 UNIQUEIDENTIFIER,
@IntegrationObjectID_f72920c9 UNIQUEIDENTIFIER,
@Name_f72920c9 NVARCHAR(255),
@DisplayName_f72920c9 NVARCHAR(255),
@Description_f72920c9 NVARCHAR(MAX),
@Category_f72920c9 NVARCHAR(100),
@Type_f72920c9 NVARCHAR(100),
@Length_f72920c9 INT,
@Precision_f72920c9 INT,
@Scale_f72920c9 INT,
@AllowsNull_f72920c9 BIT,
@DefaultValue_f72920c9 NVARCHAR(255),
@IsPrimaryKey_f72920c9 BIT,
@IsUniqueKey_f72920c9 BIT,
@IsReadOnly_f72920c9 BIT,
@IsRequired_f72920c9 BIT,
@RelatedIntegrationObjectID_f72920c9 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_f72920c9 NVARCHAR(255),
@Sequence_f72920c9 INT,
@Configuration_f72920c9 NVARCHAR(MAX),
@Status_f72920c9 NVARCHAR(25),
@IsCustom_f72920c9 BIT,
@MetadataSource_f72920c9 NVARCHAR(20)
SET
  @ID_f72920c9 = 'CA3DDEAE-AFA9-5510-8537-A2AE9C8C1471'
SET
  @IntegrationObjectID_f72920c9 = 'A28BB703-8E34-4725-AF07-CDE7E42EB046'
SET
  @Name_f72920c9 = N'end-month'
SET
  @DisplayName_f72920c9 = N'End Month'
SET
  @Description_f72920c9 = N'Month (1-12) of the affiliation end date; empty for a current/ongoing role, when given.'
SET
  @Type_f72920c9 = N'Integer'
SET
  @AllowsNull_f72920c9 = 1
SET
  @IsPrimaryKey_f72920c9 = 0
SET
  @IsUniqueKey_f72920c9 = 0
SET
  @IsReadOnly_f72920c9 = 1
SET
  @IsRequired_f72920c9 = 0
SET
  @Sequence_f72920c9 = 19
SET
  @Status_f72920c9 = N'Active'
SET
  @IsCustom_f72920c9 = 0
SET
  @MetadataSource_f72920c9 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_f72920c9,
  @IntegrationObjectID = @IntegrationObjectID_f72920c9,
  @Name = @Name_f72920c9,
  @DisplayName = @DisplayName_f72920c9,
  @Description = @Description_f72920c9,
  @Category = @Category_f72920c9,
  @Category_Clear = 1,
  @Type = @Type_f72920c9,
  @Length = @Length_f72920c9,
  @Length_Clear = 1,
  @Precision = @Precision_f72920c9,
  @Precision_Clear = 1,
  @Scale = @Scale_f72920c9,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_f72920c9,
  @DefaultValue = @DefaultValue_f72920c9,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_f72920c9,
  @IsUniqueKey = @IsUniqueKey_f72920c9,
  @IsReadOnly = @IsReadOnly_f72920c9,
  @IsRequired = @IsRequired_f72920c9,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_f72920c9,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_f72920c9,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_f72920c9,
  @Configuration = @Configuration_f72920c9,
  @Configuration_Clear = 1,
  @Status = @Status_f72920c9,
  @IsCustom = @IsCustom_f72920c9,
  @MetadataSource = @MetadataSource_f72920c9;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_7b351034 UNIQUEIDENTIFIER,
@IntegrationObjectID_7b351034 UNIQUEIDENTIFIER,
@Name_7b351034 NVARCHAR(255),
@DisplayName_7b351034 NVARCHAR(255),
@Description_7b351034 NVARCHAR(MAX),
@Category_7b351034 NVARCHAR(100),
@Type_7b351034 NVARCHAR(100),
@Length_7b351034 INT,
@Precision_7b351034 INT,
@Scale_7b351034 INT,
@AllowsNull_7b351034 BIT,
@DefaultValue_7b351034 NVARCHAR(255),
@IsPrimaryKey_7b351034 BIT,
@IsUniqueKey_7b351034 BIT,
@IsReadOnly_7b351034 BIT,
@IsRequired_7b351034 BIT,
@RelatedIntegrationObjectID_7b351034 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_7b351034 NVARCHAR(255),
@Sequence_7b351034 INT,
@Configuration_7b351034 NVARCHAR(MAX),
@Status_7b351034 NVARCHAR(25),
@IsCustom_7b351034 BIT,
@MetadataSource_7b351034 NVARCHAR(20)
SET
  @ID_7b351034 = '47BAC76E-3C87-55C7-AA74-76CE778DA7B6'
SET
  @IntegrationObjectID_7b351034 = 'A28BB703-8E34-4725-AF07-CDE7E42EB046'
SET
  @Name_7b351034 = N'end-day'
SET
  @DisplayName_7b351034 = N'End Day'
SET
  @Description_7b351034 = N'Day of month of the affiliation end date; empty for a current/ongoing role, when given.'
SET
  @Type_7b351034 = N'Integer'
SET
  @AllowsNull_7b351034 = 1
SET
  @IsPrimaryKey_7b351034 = 0
SET
  @IsUniqueKey_7b351034 = 0
SET
  @IsReadOnly_7b351034 = 1
SET
  @IsRequired_7b351034 = 0
SET
  @Sequence_7b351034 = 20
SET
  @Status_7b351034 = N'Active'
SET
  @IsCustom_7b351034 = 0
SET
  @MetadataSource_7b351034 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_7b351034,
  @IntegrationObjectID = @IntegrationObjectID_7b351034,
  @Name = @Name_7b351034,
  @DisplayName = @DisplayName_7b351034,
  @Description = @Description_7b351034,
  @Category = @Category_7b351034,
  @Category_Clear = 1,
  @Type = @Type_7b351034,
  @Length = @Length_7b351034,
  @Length_Clear = 1,
  @Precision = @Precision_7b351034,
  @Precision_Clear = 1,
  @Scale = @Scale_7b351034,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_7b351034,
  @DefaultValue = @DefaultValue_7b351034,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_7b351034,
  @IsUniqueKey = @IsUniqueKey_7b351034,
  @IsReadOnly = @IsReadOnly_7b351034,
  @IsRequired = @IsRequired_7b351034,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_7b351034,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_7b351034,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_7b351034,
  @Configuration = @Configuration_7b351034,
  @Configuration_Clear = 1,
  @Status = @Status_7b351034,
  @IsCustom = @IsCustom_7b351034,
  @MetadataSource = @MetadataSource_7b351034;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_501fc807 UNIQUEIDENTIFIER,
@IntegrationObjectID_501fc807 UNIQUEIDENTIFIER,
@Name_501fc807 NVARCHAR(255),
@DisplayName_501fc807 NVARCHAR(255),
@Description_501fc807 NVARCHAR(MAX),
@Category_501fc807 NVARCHAR(100),
@Type_501fc807 NVARCHAR(100),
@Length_501fc807 INT,
@Precision_501fc807 INT,
@Scale_501fc807 INT,
@AllowsNull_501fc807 BIT,
@DefaultValue_501fc807 NVARCHAR(255),
@IsPrimaryKey_501fc807 BIT,
@IsUniqueKey_501fc807 BIT,
@IsReadOnly_501fc807 BIT,
@IsRequired_501fc807 BIT,
@RelatedIntegrationObjectID_501fc807 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_501fc807 NVARCHAR(255),
@Sequence_501fc807 INT,
@Configuration_501fc807 NVARCHAR(MAX),
@Status_501fc807 NVARCHAR(25),
@IsCustom_501fc807 BIT,
@MetadataSource_501fc807 NVARCHAR(20)
SET
  @ID_501fc807 = '2E047456-4179-508E-A13F-C530EACF6E86'
SET
  @IntegrationObjectID_501fc807 = 'A28BB703-8E34-4725-AF07-CDE7E42EB046'
SET
  @Name_501fc807 = N'organization-name'
SET
  @DisplayName_501fc807 = N'Organization Name'
SET
  @Description_501fc807 = N'Name of the organization. Lifted from organization.name.'
SET
  @Type_501fc807 = N'String'
SET
  @Length_501fc807 = 1000
SET
  @AllowsNull_501fc807 = 1
SET
  @IsPrimaryKey_501fc807 = 0
SET
  @IsUniqueKey_501fc807 = 0
SET
  @IsReadOnly_501fc807 = 1
SET
  @IsRequired_501fc807 = 0
SET
  @Sequence_501fc807 = 21
SET
  @Status_501fc807 = N'Active'
SET
  @IsCustom_501fc807 = 0
SET
  @MetadataSource_501fc807 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_501fc807,
  @IntegrationObjectID = @IntegrationObjectID_501fc807,
  @Name = @Name_501fc807,
  @DisplayName = @DisplayName_501fc807,
  @Description = @Description_501fc807,
  @Category = @Category_501fc807,
  @Category_Clear = 1,
  @Type = @Type_501fc807,
  @Length = @Length_501fc807,
  @Precision = @Precision_501fc807,
  @Precision_Clear = 1,
  @Scale = @Scale_501fc807,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_501fc807,
  @DefaultValue = @DefaultValue_501fc807,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_501fc807,
  @IsUniqueKey = @IsUniqueKey_501fc807,
  @IsReadOnly = @IsReadOnly_501fc807,
  @IsRequired = @IsRequired_501fc807,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_501fc807,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_501fc807,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_501fc807,
  @Configuration = @Configuration_501fc807,
  @Configuration_Clear = 1,
  @Status = @Status_501fc807,
  @IsCustom = @IsCustom_501fc807,
  @MetadataSource = @MetadataSource_501fc807;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_39e57c49 UNIQUEIDENTIFIER,
@IntegrationObjectID_39e57c49 UNIQUEIDENTIFIER,
@Name_39e57c49 NVARCHAR(255),
@DisplayName_39e57c49 NVARCHAR(255),
@Description_39e57c49 NVARCHAR(MAX),
@Category_39e57c49 NVARCHAR(100),
@Type_39e57c49 NVARCHAR(100),
@Length_39e57c49 INT,
@Precision_39e57c49 INT,
@Scale_39e57c49 INT,
@AllowsNull_39e57c49 BIT,
@DefaultValue_39e57c49 NVARCHAR(255),
@IsPrimaryKey_39e57c49 BIT,
@IsUniqueKey_39e57c49 BIT,
@IsReadOnly_39e57c49 BIT,
@IsRequired_39e57c49 BIT,
@RelatedIntegrationObjectID_39e57c49 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_39e57c49 NVARCHAR(255),
@Sequence_39e57c49 INT,
@Configuration_39e57c49 NVARCHAR(MAX),
@Status_39e57c49 NVARCHAR(25),
@IsCustom_39e57c49 BIT,
@MetadataSource_39e57c49 NVARCHAR(20)
SET
  @ID_39e57c49 = '9B89B77A-CC33-5C26-969F-16ACB6591CB1'
SET
  @IntegrationObjectID_39e57c49 = 'A28BB703-8E34-4725-AF07-CDE7E42EB046'
SET
  @Name_39e57c49 = N'organization-city'
SET
  @DisplayName_39e57c49 = N'Organization City'
SET
  @Description_39e57c49 = N'City of the organization. Lifted from organization.address.city.'
SET
  @Type_39e57c49 = N'String'
SET
  @Length_39e57c49 = 255
SET
  @AllowsNull_39e57c49 = 1
SET
  @IsPrimaryKey_39e57c49 = 0
SET
  @IsUniqueKey_39e57c49 = 0
SET
  @IsReadOnly_39e57c49 = 1
SET
  @IsRequired_39e57c49 = 0
SET
  @Sequence_39e57c49 = 22
SET
  @Status_39e57c49 = N'Active'
SET
  @IsCustom_39e57c49 = 0
SET
  @MetadataSource_39e57c49 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_39e57c49,
  @IntegrationObjectID = @IntegrationObjectID_39e57c49,
  @Name = @Name_39e57c49,
  @DisplayName = @DisplayName_39e57c49,
  @Description = @Description_39e57c49,
  @Category = @Category_39e57c49,
  @Category_Clear = 1,
  @Type = @Type_39e57c49,
  @Length = @Length_39e57c49,
  @Precision = @Precision_39e57c49,
  @Precision_Clear = 1,
  @Scale = @Scale_39e57c49,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_39e57c49,
  @DefaultValue = @DefaultValue_39e57c49,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_39e57c49,
  @IsUniqueKey = @IsUniqueKey_39e57c49,
  @IsReadOnly = @IsReadOnly_39e57c49,
  @IsRequired = @IsRequired_39e57c49,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_39e57c49,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_39e57c49,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_39e57c49,
  @Configuration = @Configuration_39e57c49,
  @Configuration_Clear = 1,
  @Status = @Status_39e57c49,
  @IsCustom = @IsCustom_39e57c49,
  @MetadataSource = @MetadataSource_39e57c49;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_1991bc0e UNIQUEIDENTIFIER,
@IntegrationObjectID_1991bc0e UNIQUEIDENTIFIER,
@Name_1991bc0e NVARCHAR(255),
@DisplayName_1991bc0e NVARCHAR(255),
@Description_1991bc0e NVARCHAR(MAX),
@Category_1991bc0e NVARCHAR(100),
@Type_1991bc0e NVARCHAR(100),
@Length_1991bc0e INT,
@Precision_1991bc0e INT,
@Scale_1991bc0e INT,
@AllowsNull_1991bc0e BIT,
@DefaultValue_1991bc0e NVARCHAR(255),
@IsPrimaryKey_1991bc0e BIT,
@IsUniqueKey_1991bc0e BIT,
@IsReadOnly_1991bc0e BIT,
@IsRequired_1991bc0e BIT,
@RelatedIntegrationObjectID_1991bc0e UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_1991bc0e NVARCHAR(255),
@Sequence_1991bc0e INT,
@Configuration_1991bc0e NVARCHAR(MAX),
@Status_1991bc0e NVARCHAR(25),
@IsCustom_1991bc0e BIT,
@MetadataSource_1991bc0e NVARCHAR(20)
SET
  @ID_1991bc0e = '837D9AEA-7C25-5286-B1A0-48D72BEC4E27'
SET
  @IntegrationObjectID_1991bc0e = 'A28BB703-8E34-4725-AF07-CDE7E42EB046'
SET
  @Name_1991bc0e = N'organization-region'
SET
  @DisplayName_1991bc0e = N'Organization Region'
SET
  @Description_1991bc0e = N'Region/state of the organization. Lifted from organization.address.region.'
SET
  @Type_1991bc0e = N'String'
SET
  @Length_1991bc0e = 255
SET
  @AllowsNull_1991bc0e = 1
SET
  @IsPrimaryKey_1991bc0e = 0
SET
  @IsUniqueKey_1991bc0e = 0
SET
  @IsReadOnly_1991bc0e = 1
SET
  @IsRequired_1991bc0e = 0
SET
  @Sequence_1991bc0e = 23
SET
  @Status_1991bc0e = N'Active'
SET
  @IsCustom_1991bc0e = 0
SET
  @MetadataSource_1991bc0e = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_1991bc0e,
  @IntegrationObjectID = @IntegrationObjectID_1991bc0e,
  @Name = @Name_1991bc0e,
  @DisplayName = @DisplayName_1991bc0e,
  @Description = @Description_1991bc0e,
  @Category = @Category_1991bc0e,
  @Category_Clear = 1,
  @Type = @Type_1991bc0e,
  @Length = @Length_1991bc0e,
  @Precision = @Precision_1991bc0e,
  @Precision_Clear = 1,
  @Scale = @Scale_1991bc0e,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_1991bc0e,
  @DefaultValue = @DefaultValue_1991bc0e,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_1991bc0e,
  @IsUniqueKey = @IsUniqueKey_1991bc0e,
  @IsReadOnly = @IsReadOnly_1991bc0e,
  @IsRequired = @IsRequired_1991bc0e,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_1991bc0e,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_1991bc0e,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_1991bc0e,
  @Configuration = @Configuration_1991bc0e,
  @Configuration_Clear = 1,
  @Status = @Status_1991bc0e,
  @IsCustom = @IsCustom_1991bc0e,
  @MetadataSource = @MetadataSource_1991bc0e;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_c0e176bb UNIQUEIDENTIFIER,
@IntegrationObjectID_c0e176bb UNIQUEIDENTIFIER,
@Name_c0e176bb NVARCHAR(255),
@DisplayName_c0e176bb NVARCHAR(255),
@Description_c0e176bb NVARCHAR(MAX),
@Category_c0e176bb NVARCHAR(100),
@Type_c0e176bb NVARCHAR(100),
@Length_c0e176bb INT,
@Precision_c0e176bb INT,
@Scale_c0e176bb INT,
@AllowsNull_c0e176bb BIT,
@DefaultValue_c0e176bb NVARCHAR(255),
@IsPrimaryKey_c0e176bb BIT,
@IsUniqueKey_c0e176bb BIT,
@IsReadOnly_c0e176bb BIT,
@IsRequired_c0e176bb BIT,
@RelatedIntegrationObjectID_c0e176bb UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_c0e176bb NVARCHAR(255),
@Sequence_c0e176bb INT,
@Configuration_c0e176bb NVARCHAR(MAX),
@Status_c0e176bb NVARCHAR(25),
@IsCustom_c0e176bb BIT,
@MetadataSource_c0e176bb NVARCHAR(20)
SET
  @ID_c0e176bb = '4DE67A58-6DFA-5973-8776-D242F7AA6A39'
SET
  @IntegrationObjectID_c0e176bb = 'A28BB703-8E34-4725-AF07-CDE7E42EB046'
SET
  @Name_c0e176bb = N'organization-country'
SET
  @DisplayName_c0e176bb = N'Organization Country'
SET
  @Description_c0e176bb = N'ISO country code of the organization. Lifted from organization.address.country.'
SET
  @Type_c0e176bb = N'String'
SET
  @Length_c0e176bb = 50
SET
  @AllowsNull_c0e176bb = 1
SET
  @IsPrimaryKey_c0e176bb = 0
SET
  @IsUniqueKey_c0e176bb = 0
SET
  @IsReadOnly_c0e176bb = 1
SET
  @IsRequired_c0e176bb = 0
SET
  @Sequence_c0e176bb = 24
SET
  @Status_c0e176bb = N'Active'
SET
  @IsCustom_c0e176bb = 0
SET
  @MetadataSource_c0e176bb = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_c0e176bb,
  @IntegrationObjectID = @IntegrationObjectID_c0e176bb,
  @Name = @Name_c0e176bb,
  @DisplayName = @DisplayName_c0e176bb,
  @Description = @Description_c0e176bb,
  @Category = @Category_c0e176bb,
  @Category_Clear = 1,
  @Type = @Type_c0e176bb,
  @Length = @Length_c0e176bb,
  @Precision = @Precision_c0e176bb,
  @Precision_Clear = 1,
  @Scale = @Scale_c0e176bb,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_c0e176bb,
  @DefaultValue = @DefaultValue_c0e176bb,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_c0e176bb,
  @IsUniqueKey = @IsUniqueKey_c0e176bb,
  @IsReadOnly = @IsReadOnly_c0e176bb,
  @IsRequired = @IsRequired_c0e176bb,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_c0e176bb,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_c0e176bb,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_c0e176bb,
  @Configuration = @Configuration_c0e176bb,
  @Configuration_Clear = 1,
  @Status = @Status_c0e176bb,
  @IsCustom = @IsCustom_c0e176bb,
  @MetadataSource = @MetadataSource_c0e176bb;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_8593dd9f UNIQUEIDENTIFIER,
@IntegrationObjectID_8593dd9f UNIQUEIDENTIFIER,
@Name_8593dd9f NVARCHAR(255),
@DisplayName_8593dd9f NVARCHAR(255),
@Description_8593dd9f NVARCHAR(MAX),
@Category_8593dd9f NVARCHAR(100),
@Type_8593dd9f NVARCHAR(100),
@Length_8593dd9f INT,
@Precision_8593dd9f INT,
@Scale_8593dd9f INT,
@AllowsNull_8593dd9f BIT,
@DefaultValue_8593dd9f NVARCHAR(255),
@IsPrimaryKey_8593dd9f BIT,
@IsUniqueKey_8593dd9f BIT,
@IsReadOnly_8593dd9f BIT,
@IsRequired_8593dd9f BIT,
@RelatedIntegrationObjectID_8593dd9f UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_8593dd9f NVARCHAR(255),
@Sequence_8593dd9f INT,
@Configuration_8593dd9f NVARCHAR(MAX),
@Status_8593dd9f NVARCHAR(25),
@IsCustom_8593dd9f BIT,
@MetadataSource_8593dd9f NVARCHAR(20)
SET
  @ID_8593dd9f = '5AAE5894-FAA4-5A59-8F5F-FA03CE2A1120'
SET
  @IntegrationObjectID_8593dd9f = 'A28BB703-8E34-4725-AF07-CDE7E42EB046'
SET
  @Name_8593dd9f = N'organization-disambiguated-id'
SET
  @DisplayName_8593dd9f = N'Organization Disambiguated Id'
SET
  @Description_8593dd9f = N'Canonical identifier of the organization in the disambiguation source (e.g. a RINGGOLD or ROR id), so the same institution matches across records.'
SET
  @Type_8593dd9f = N'String'
SET
  @Length_8593dd9f = 255
SET
  @AllowsNull_8593dd9f = 1
SET
  @IsPrimaryKey_8593dd9f = 0
SET
  @IsUniqueKey_8593dd9f = 0
SET
  @IsReadOnly_8593dd9f = 1
SET
  @IsRequired_8593dd9f = 0
SET
  @Sequence_8593dd9f = 25
SET
  @Status_8593dd9f = N'Active'
SET
  @IsCustom_8593dd9f = 0
SET
  @MetadataSource_8593dd9f = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_8593dd9f,
  @IntegrationObjectID = @IntegrationObjectID_8593dd9f,
  @Name = @Name_8593dd9f,
  @DisplayName = @DisplayName_8593dd9f,
  @Description = @Description_8593dd9f,
  @Category = @Category_8593dd9f,
  @Category_Clear = 1,
  @Type = @Type_8593dd9f,
  @Length = @Length_8593dd9f,
  @Precision = @Precision_8593dd9f,
  @Precision_Clear = 1,
  @Scale = @Scale_8593dd9f,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_8593dd9f,
  @DefaultValue = @DefaultValue_8593dd9f,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_8593dd9f,
  @IsUniqueKey = @IsUniqueKey_8593dd9f,
  @IsReadOnly = @IsReadOnly_8593dd9f,
  @IsRequired = @IsRequired_8593dd9f,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_8593dd9f,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_8593dd9f,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_8593dd9f,
  @Configuration = @Configuration_8593dd9f,
  @Configuration_Clear = 1,
  @Status = @Status_8593dd9f,
  @IsCustom = @IsCustom_8593dd9f,
  @MetadataSource = @MetadataSource_8593dd9f;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_11317236 UNIQUEIDENTIFIER,
@IntegrationObjectID_11317236 UNIQUEIDENTIFIER,
@Name_11317236 NVARCHAR(255),
@DisplayName_11317236 NVARCHAR(255),
@Description_11317236 NVARCHAR(MAX),
@Category_11317236 NVARCHAR(100),
@Type_11317236 NVARCHAR(100),
@Length_11317236 INT,
@Precision_11317236 INT,
@Scale_11317236 INT,
@AllowsNull_11317236 BIT,
@DefaultValue_11317236 NVARCHAR(255),
@IsPrimaryKey_11317236 BIT,
@IsUniqueKey_11317236 BIT,
@IsReadOnly_11317236 BIT,
@IsRequired_11317236 BIT,
@RelatedIntegrationObjectID_11317236 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_11317236 NVARCHAR(255),
@Sequence_11317236 INT,
@Configuration_11317236 NVARCHAR(MAX),
@Status_11317236 NVARCHAR(25),
@IsCustom_11317236 BIT,
@MetadataSource_11317236 NVARCHAR(20)
SET
  @ID_11317236 = '2BB23DA0-72D0-58BF-8975-CDF5F4CE080F'
SET
  @IntegrationObjectID_11317236 = 'A28BB703-8E34-4725-AF07-CDE7E42EB046'
SET
  @Name_11317236 = N'organization-disambiguation-source'
SET
  @DisplayName_11317236 = N'Organization Disambiguation Source'
SET
  @Description_11317236 = N'Registry the disambiguated id comes from (RINGGOLD, ROR, FUNDREF, GRID, LEI).'
SET
  @Type_11317236 = N'String'
SET
  @Length_11317236 = 100
SET
  @AllowsNull_11317236 = 1
SET
  @IsPrimaryKey_11317236 = 0
SET
  @IsUniqueKey_11317236 = 0
SET
  @IsReadOnly_11317236 = 1
SET
  @IsRequired_11317236 = 0
SET
  @Sequence_11317236 = 26
SET
  @Status_11317236 = N'Active'
SET
  @IsCustom_11317236 = 0
SET
  @MetadataSource_11317236 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_11317236,
  @IntegrationObjectID = @IntegrationObjectID_11317236,
  @Name = @Name_11317236,
  @DisplayName = @DisplayName_11317236,
  @Description = @Description_11317236,
  @Category = @Category_11317236,
  @Category_Clear = 1,
  @Type = @Type_11317236,
  @Length = @Length_11317236,
  @Precision = @Precision_11317236,
  @Precision_Clear = 1,
  @Scale = @Scale_11317236,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_11317236,
  @DefaultValue = @DefaultValue_11317236,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_11317236,
  @IsUniqueKey = @IsUniqueKey_11317236,
  @IsReadOnly = @IsReadOnly_11317236,
  @IsRequired = @IsRequired_11317236,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_11317236,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_11317236,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_11317236,
  @Configuration = @Configuration_11317236,
  @Configuration_Clear = 1,
  @Status = @Status_11317236,
  @IsCustom = @IsCustom_11317236,
  @MetadataSource = @MetadataSource_11317236;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_7e7b427f UNIQUEIDENTIFIER,
@IntegrationObjectID_7e7b427f UNIQUEIDENTIFIER,
@Name_7e7b427f NVARCHAR(255),
@DisplayName_7e7b427f NVARCHAR(255),
@Description_7e7b427f NVARCHAR(MAX),
@Category_7e7b427f NVARCHAR(100),
@Type_7e7b427f NVARCHAR(100),
@Length_7e7b427f INT,
@Precision_7e7b427f INT,
@Scale_7e7b427f INT,
@AllowsNull_7e7b427f BIT,
@DefaultValue_7e7b427f NVARCHAR(255),
@IsPrimaryKey_7e7b427f BIT,
@IsUniqueKey_7e7b427f BIT,
@IsReadOnly_7e7b427f BIT,
@IsRequired_7e7b427f BIT,
@RelatedIntegrationObjectID_7e7b427f UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_7e7b427f NVARCHAR(255),
@Sequence_7e7b427f INT,
@Configuration_7e7b427f NVARCHAR(MAX),
@Status_7e7b427f NVARCHAR(25),
@IsCustom_7e7b427f BIT,
@MetadataSource_7e7b427f NVARCHAR(20)
SET
  @ID_7e7b427f = '1FDA019D-BE9D-5250-8C60-8DC2D7379AA9'
SET
  @IntegrationObjectID_7e7b427f = 'A28BB703-8E34-4725-AF07-CDE7E42EB046'
SET
  @Name_7e7b427f = N'source-name'
SET
  @DisplayName_7e7b427f = N'Source Name'
SET
  @Description_7e7b427f = N'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.'
SET
  @Type_7e7b427f = N'String'
SET
  @Length_7e7b427f = 500
SET
  @AllowsNull_7e7b427f = 1
SET
  @IsPrimaryKey_7e7b427f = 0
SET
  @IsUniqueKey_7e7b427f = 0
SET
  @IsReadOnly_7e7b427f = 1
SET
  @IsRequired_7e7b427f = 0
SET
  @Sequence_7e7b427f = 27
SET
  @Status_7e7b427f = N'Active'
SET
  @IsCustom_7e7b427f = 0
SET
  @MetadataSource_7e7b427f = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_7e7b427f,
  @IntegrationObjectID = @IntegrationObjectID_7e7b427f,
  @Name = @Name_7e7b427f,
  @DisplayName = @DisplayName_7e7b427f,
  @Description = @Description_7e7b427f,
  @Category = @Category_7e7b427f,
  @Category_Clear = 1,
  @Type = @Type_7e7b427f,
  @Length = @Length_7e7b427f,
  @Precision = @Precision_7e7b427f,
  @Precision_Clear = 1,
  @Scale = @Scale_7e7b427f,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_7e7b427f,
  @DefaultValue = @DefaultValue_7e7b427f,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_7e7b427f,
  @IsUniqueKey = @IsUniqueKey_7e7b427f,
  @IsReadOnly = @IsReadOnly_7e7b427f,
  @IsRequired = @IsRequired_7e7b427f,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_7e7b427f,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_7e7b427f,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_7e7b427f,
  @Configuration = @Configuration_7e7b427f,
  @Configuration_Clear = 1,
  @Status = @Status_7e7b427f,
  @IsCustom = @IsCustom_7e7b427f,
  @MetadataSource = @MetadataSource_7e7b427f;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_b66b265f UNIQUEIDENTIFIER,
@IntegrationObjectID_b66b265f UNIQUEIDENTIFIER,
@Name_b66b265f NVARCHAR(255),
@DisplayName_b66b265f NVARCHAR(255),
@Description_b66b265f NVARCHAR(MAX),
@Category_b66b265f NVARCHAR(100),
@Type_b66b265f NVARCHAR(100),
@Length_b66b265f INT,
@Precision_b66b265f INT,
@Scale_b66b265f INT,
@AllowsNull_b66b265f BIT,
@DefaultValue_b66b265f NVARCHAR(255),
@IsPrimaryKey_b66b265f BIT,
@IsUniqueKey_b66b265f BIT,
@IsReadOnly_b66b265f BIT,
@IsRequired_b66b265f BIT,
@RelatedIntegrationObjectID_b66b265f UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_b66b265f NVARCHAR(255),
@Sequence_b66b265f INT,
@Configuration_b66b265f NVARCHAR(MAX),
@Status_b66b265f NVARCHAR(25),
@IsCustom_b66b265f BIT,
@MetadataSource_b66b265f NVARCHAR(20)
SET
  @ID_b66b265f = '3E84687E-286F-5D7C-8DCE-0C212F628852'
SET
  @IntegrationObjectID_b66b265f = 'A28BB703-8E34-4725-AF07-CDE7E42EB046'
SET
  @Name_b66b265f = N'source-orcid'
SET
  @DisplayName_b66b265f = N'Source Orcid'
SET
  @Description_b66b265f = N'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.'
SET
  @Type_b66b265f = N'String'
SET
  @Length_b66b265f = 19
SET
  @AllowsNull_b66b265f = 1
SET
  @IsPrimaryKey_b66b265f = 0
SET
  @IsUniqueKey_b66b265f = 0
SET
  @IsReadOnly_b66b265f = 1
SET
  @IsRequired_b66b265f = 0
SET
  @Sequence_b66b265f = 28
SET
  @Status_b66b265f = N'Active'
SET
  @IsCustom_b66b265f = 0
SET
  @MetadataSource_b66b265f = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_b66b265f,
  @IntegrationObjectID = @IntegrationObjectID_b66b265f,
  @Name = @Name_b66b265f,
  @DisplayName = @DisplayName_b66b265f,
  @Description = @Description_b66b265f,
  @Category = @Category_b66b265f,
  @Category_Clear = 1,
  @Type = @Type_b66b265f,
  @Length = @Length_b66b265f,
  @Precision = @Precision_b66b265f,
  @Precision_Clear = 1,
  @Scale = @Scale_b66b265f,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_b66b265f,
  @DefaultValue = @DefaultValue_b66b265f,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_b66b265f,
  @IsUniqueKey = @IsUniqueKey_b66b265f,
  @IsReadOnly = @IsReadOnly_b66b265f,
  @IsRequired = @IsRequired_b66b265f,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_b66b265f,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_b66b265f,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_b66b265f,
  @Configuration = @Configuration_b66b265f,
  @Configuration_Clear = 1,
  @Status = @Status_b66b265f,
  @IsCustom = @IsCustom_b66b265f,
  @MetadataSource = @MetadataSource_b66b265f;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_65ef13ed UNIQUEIDENTIFIER,
@IntegrationObjectID_65ef13ed UNIQUEIDENTIFIER,
@Name_65ef13ed NVARCHAR(255),
@DisplayName_65ef13ed NVARCHAR(255),
@Description_65ef13ed NVARCHAR(MAX),
@Category_65ef13ed NVARCHAR(100),
@Type_65ef13ed NVARCHAR(100),
@Length_65ef13ed INT,
@Precision_65ef13ed INT,
@Scale_65ef13ed INT,
@AllowsNull_65ef13ed BIT,
@DefaultValue_65ef13ed NVARCHAR(255),
@IsPrimaryKey_65ef13ed BIT,
@IsUniqueKey_65ef13ed BIT,
@IsReadOnly_65ef13ed BIT,
@IsRequired_65ef13ed BIT,
@RelatedIntegrationObjectID_65ef13ed UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_65ef13ed NVARCHAR(255),
@Sequence_65ef13ed INT,
@Configuration_65ef13ed NVARCHAR(MAX),
@Status_65ef13ed NVARCHAR(25),
@IsCustom_65ef13ed BIT,
@MetadataSource_65ef13ed NVARCHAR(20)
SET
  @ID_65ef13ed = '1CC6C9DE-4489-5810-B952-473AB5B0CBC4'
SET
  @IntegrationObjectID_65ef13ed = '2139B63E-5944-4542-BE5E-7213D64B9750'
SET
  @Name_65ef13ed = N'start-year'
SET
  @DisplayName_65ef13ed = N'Start Year'
SET
  @Description_65ef13ed = N'Year of the affiliation start date; ORCID dates are partial, so month/day may be absent.'
SET
  @Type_65ef13ed = N'Integer'
SET
  @AllowsNull_65ef13ed = 1
SET
  @IsPrimaryKey_65ef13ed = 0
SET
  @IsUniqueKey_65ef13ed = 0
SET
  @IsReadOnly_65ef13ed = 1
SET
  @IsRequired_65ef13ed = 0
SET
  @Sequence_65ef13ed = 15
SET
  @Status_65ef13ed = N'Active'
SET
  @IsCustom_65ef13ed = 0
SET
  @MetadataSource_65ef13ed = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_65ef13ed,
  @IntegrationObjectID = @IntegrationObjectID_65ef13ed,
  @Name = @Name_65ef13ed,
  @DisplayName = @DisplayName_65ef13ed,
  @Description = @Description_65ef13ed,
  @Category = @Category_65ef13ed,
  @Category_Clear = 1,
  @Type = @Type_65ef13ed,
  @Length = @Length_65ef13ed,
  @Length_Clear = 1,
  @Precision = @Precision_65ef13ed,
  @Precision_Clear = 1,
  @Scale = @Scale_65ef13ed,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_65ef13ed,
  @DefaultValue = @DefaultValue_65ef13ed,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_65ef13ed,
  @IsUniqueKey = @IsUniqueKey_65ef13ed,
  @IsReadOnly = @IsReadOnly_65ef13ed,
  @IsRequired = @IsRequired_65ef13ed,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_65ef13ed,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_65ef13ed,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_65ef13ed,
  @Configuration = @Configuration_65ef13ed,
  @Configuration_Clear = 1,
  @Status = @Status_65ef13ed,
  @IsCustom = @IsCustom_65ef13ed,
  @MetadataSource = @MetadataSource_65ef13ed;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_129e7269 UNIQUEIDENTIFIER,
@IntegrationObjectID_129e7269 UNIQUEIDENTIFIER,
@Name_129e7269 NVARCHAR(255),
@DisplayName_129e7269 NVARCHAR(255),
@Description_129e7269 NVARCHAR(MAX),
@Category_129e7269 NVARCHAR(100),
@Type_129e7269 NVARCHAR(100),
@Length_129e7269 INT,
@Precision_129e7269 INT,
@Scale_129e7269 INT,
@AllowsNull_129e7269 BIT,
@DefaultValue_129e7269 NVARCHAR(255),
@IsPrimaryKey_129e7269 BIT,
@IsUniqueKey_129e7269 BIT,
@IsReadOnly_129e7269 BIT,
@IsRequired_129e7269 BIT,
@RelatedIntegrationObjectID_129e7269 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_129e7269 NVARCHAR(255),
@Sequence_129e7269 INT,
@Configuration_129e7269 NVARCHAR(MAX),
@Status_129e7269 NVARCHAR(25),
@IsCustom_129e7269 BIT,
@MetadataSource_129e7269 NVARCHAR(20)
SET
  @ID_129e7269 = '766B30A6-3353-56A0-B327-98DC4889CFC8'
SET
  @IntegrationObjectID_129e7269 = '2139B63E-5944-4542-BE5E-7213D64B9750'
SET
  @Name_129e7269 = N'start-month'
SET
  @DisplayName_129e7269 = N'Start Month'
SET
  @Description_129e7269 = N'Month (1-12) of the affiliation start date, when given.'
SET
  @Type_129e7269 = N'Integer'
SET
  @AllowsNull_129e7269 = 1
SET
  @IsPrimaryKey_129e7269 = 0
SET
  @IsUniqueKey_129e7269 = 0
SET
  @IsReadOnly_129e7269 = 1
SET
  @IsRequired_129e7269 = 0
SET
  @Sequence_129e7269 = 16
SET
  @Status_129e7269 = N'Active'
SET
  @IsCustom_129e7269 = 0
SET
  @MetadataSource_129e7269 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_129e7269,
  @IntegrationObjectID = @IntegrationObjectID_129e7269,
  @Name = @Name_129e7269,
  @DisplayName = @DisplayName_129e7269,
  @Description = @Description_129e7269,
  @Category = @Category_129e7269,
  @Category_Clear = 1,
  @Type = @Type_129e7269,
  @Length = @Length_129e7269,
  @Length_Clear = 1,
  @Precision = @Precision_129e7269,
  @Precision_Clear = 1,
  @Scale = @Scale_129e7269,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_129e7269,
  @DefaultValue = @DefaultValue_129e7269,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_129e7269,
  @IsUniqueKey = @IsUniqueKey_129e7269,
  @IsReadOnly = @IsReadOnly_129e7269,
  @IsRequired = @IsRequired_129e7269,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_129e7269,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_129e7269,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_129e7269,
  @Configuration = @Configuration_129e7269,
  @Configuration_Clear = 1,
  @Status = @Status_129e7269,
  @IsCustom = @IsCustom_129e7269,
  @MetadataSource = @MetadataSource_129e7269;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_6bf0b94d UNIQUEIDENTIFIER,
@IntegrationObjectID_6bf0b94d UNIQUEIDENTIFIER,
@Name_6bf0b94d NVARCHAR(255),
@DisplayName_6bf0b94d NVARCHAR(255),
@Description_6bf0b94d NVARCHAR(MAX),
@Category_6bf0b94d NVARCHAR(100),
@Type_6bf0b94d NVARCHAR(100),
@Length_6bf0b94d INT,
@Precision_6bf0b94d INT,
@Scale_6bf0b94d INT,
@AllowsNull_6bf0b94d BIT,
@DefaultValue_6bf0b94d NVARCHAR(255),
@IsPrimaryKey_6bf0b94d BIT,
@IsUniqueKey_6bf0b94d BIT,
@IsReadOnly_6bf0b94d BIT,
@IsRequired_6bf0b94d BIT,
@RelatedIntegrationObjectID_6bf0b94d UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_6bf0b94d NVARCHAR(255),
@Sequence_6bf0b94d INT,
@Configuration_6bf0b94d NVARCHAR(MAX),
@Status_6bf0b94d NVARCHAR(25),
@IsCustom_6bf0b94d BIT,
@MetadataSource_6bf0b94d NVARCHAR(20)
SET
  @ID_6bf0b94d = 'C09522F2-E3D2-5F87-AE38-CB9696D9AC43'
SET
  @IntegrationObjectID_6bf0b94d = '2139B63E-5944-4542-BE5E-7213D64B9750'
SET
  @Name_6bf0b94d = N'start-day'
SET
  @DisplayName_6bf0b94d = N'Start Day'
SET
  @Description_6bf0b94d = N'Day of month of the affiliation start date, when given.'
SET
  @Type_6bf0b94d = N'Integer'
SET
  @AllowsNull_6bf0b94d = 1
SET
  @IsPrimaryKey_6bf0b94d = 0
SET
  @IsUniqueKey_6bf0b94d = 0
SET
  @IsReadOnly_6bf0b94d = 1
SET
  @IsRequired_6bf0b94d = 0
SET
  @Sequence_6bf0b94d = 17
SET
  @Status_6bf0b94d = N'Active'
SET
  @IsCustom_6bf0b94d = 0
SET
  @MetadataSource_6bf0b94d = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_6bf0b94d,
  @IntegrationObjectID = @IntegrationObjectID_6bf0b94d,
  @Name = @Name_6bf0b94d,
  @DisplayName = @DisplayName_6bf0b94d,
  @Description = @Description_6bf0b94d,
  @Category = @Category_6bf0b94d,
  @Category_Clear = 1,
  @Type = @Type_6bf0b94d,
  @Length = @Length_6bf0b94d,
  @Length_Clear = 1,
  @Precision = @Precision_6bf0b94d,
  @Precision_Clear = 1,
  @Scale = @Scale_6bf0b94d,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_6bf0b94d,
  @DefaultValue = @DefaultValue_6bf0b94d,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_6bf0b94d,
  @IsUniqueKey = @IsUniqueKey_6bf0b94d,
  @IsReadOnly = @IsReadOnly_6bf0b94d,
  @IsRequired = @IsRequired_6bf0b94d,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_6bf0b94d,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_6bf0b94d,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_6bf0b94d,
  @Configuration = @Configuration_6bf0b94d,
  @Configuration_Clear = 1,
  @Status = @Status_6bf0b94d,
  @IsCustom = @IsCustom_6bf0b94d,
  @MetadataSource = @MetadataSource_6bf0b94d;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_bf7ae71a UNIQUEIDENTIFIER,
@IntegrationObjectID_bf7ae71a UNIQUEIDENTIFIER,
@Name_bf7ae71a NVARCHAR(255),
@DisplayName_bf7ae71a NVARCHAR(255),
@Description_bf7ae71a NVARCHAR(MAX),
@Category_bf7ae71a NVARCHAR(100),
@Type_bf7ae71a NVARCHAR(100),
@Length_bf7ae71a INT,
@Precision_bf7ae71a INT,
@Scale_bf7ae71a INT,
@AllowsNull_bf7ae71a BIT,
@DefaultValue_bf7ae71a NVARCHAR(255),
@IsPrimaryKey_bf7ae71a BIT,
@IsUniqueKey_bf7ae71a BIT,
@IsReadOnly_bf7ae71a BIT,
@IsRequired_bf7ae71a BIT,
@RelatedIntegrationObjectID_bf7ae71a UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_bf7ae71a NVARCHAR(255),
@Sequence_bf7ae71a INT,
@Configuration_bf7ae71a NVARCHAR(MAX),
@Status_bf7ae71a NVARCHAR(25),
@IsCustom_bf7ae71a BIT,
@MetadataSource_bf7ae71a NVARCHAR(20)
SET
  @ID_bf7ae71a = '2BD175D8-3CE8-5BD4-8842-725578BB84C4'
SET
  @IntegrationObjectID_bf7ae71a = '2139B63E-5944-4542-BE5E-7213D64B9750'
SET
  @Name_bf7ae71a = N'end-year'
SET
  @DisplayName_bf7ae71a = N'End Year'
SET
  @Description_bf7ae71a = N'Year of the affiliation end date; empty for a current/ongoing role; ORCID dates are partial, so month/day may be absent.'
SET
  @Type_bf7ae71a = N'Integer'
SET
  @AllowsNull_bf7ae71a = 1
SET
  @IsPrimaryKey_bf7ae71a = 0
SET
  @IsUniqueKey_bf7ae71a = 0
SET
  @IsReadOnly_bf7ae71a = 1
SET
  @IsRequired_bf7ae71a = 0
SET
  @Sequence_bf7ae71a = 18
SET
  @Status_bf7ae71a = N'Active'
SET
  @IsCustom_bf7ae71a = 0
SET
  @MetadataSource_bf7ae71a = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_bf7ae71a,
  @IntegrationObjectID = @IntegrationObjectID_bf7ae71a,
  @Name = @Name_bf7ae71a,
  @DisplayName = @DisplayName_bf7ae71a,
  @Description = @Description_bf7ae71a,
  @Category = @Category_bf7ae71a,
  @Category_Clear = 1,
  @Type = @Type_bf7ae71a,
  @Length = @Length_bf7ae71a,
  @Length_Clear = 1,
  @Precision = @Precision_bf7ae71a,
  @Precision_Clear = 1,
  @Scale = @Scale_bf7ae71a,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_bf7ae71a,
  @DefaultValue = @DefaultValue_bf7ae71a,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_bf7ae71a,
  @IsUniqueKey = @IsUniqueKey_bf7ae71a,
  @IsReadOnly = @IsReadOnly_bf7ae71a,
  @IsRequired = @IsRequired_bf7ae71a,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_bf7ae71a,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_bf7ae71a,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_bf7ae71a,
  @Configuration = @Configuration_bf7ae71a,
  @Configuration_Clear = 1,
  @Status = @Status_bf7ae71a,
  @IsCustom = @IsCustom_bf7ae71a,
  @MetadataSource = @MetadataSource_bf7ae71a;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_a0f6db3c UNIQUEIDENTIFIER,
@IntegrationObjectID_a0f6db3c UNIQUEIDENTIFIER,
@Name_a0f6db3c NVARCHAR(255),
@DisplayName_a0f6db3c NVARCHAR(255),
@Description_a0f6db3c NVARCHAR(MAX),
@Category_a0f6db3c NVARCHAR(100),
@Type_a0f6db3c NVARCHAR(100),
@Length_a0f6db3c INT,
@Precision_a0f6db3c INT,
@Scale_a0f6db3c INT,
@AllowsNull_a0f6db3c BIT,
@DefaultValue_a0f6db3c NVARCHAR(255),
@IsPrimaryKey_a0f6db3c BIT,
@IsUniqueKey_a0f6db3c BIT,
@IsReadOnly_a0f6db3c BIT,
@IsRequired_a0f6db3c BIT,
@RelatedIntegrationObjectID_a0f6db3c UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_a0f6db3c NVARCHAR(255),
@Sequence_a0f6db3c INT,
@Configuration_a0f6db3c NVARCHAR(MAX),
@Status_a0f6db3c NVARCHAR(25),
@IsCustom_a0f6db3c BIT,
@MetadataSource_a0f6db3c NVARCHAR(20)
SET
  @ID_a0f6db3c = '93BB7103-4431-5ECA-BE01-B15F416A8474'
SET
  @IntegrationObjectID_a0f6db3c = '2139B63E-5944-4542-BE5E-7213D64B9750'
SET
  @Name_a0f6db3c = N'end-month'
SET
  @DisplayName_a0f6db3c = N'End Month'
SET
  @Description_a0f6db3c = N'Month (1-12) of the affiliation end date; empty for a current/ongoing role, when given.'
SET
  @Type_a0f6db3c = N'Integer'
SET
  @AllowsNull_a0f6db3c = 1
SET
  @IsPrimaryKey_a0f6db3c = 0
SET
  @IsUniqueKey_a0f6db3c = 0
SET
  @IsReadOnly_a0f6db3c = 1
SET
  @IsRequired_a0f6db3c = 0
SET
  @Sequence_a0f6db3c = 19
SET
  @Status_a0f6db3c = N'Active'
SET
  @IsCustom_a0f6db3c = 0
SET
  @MetadataSource_a0f6db3c = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_a0f6db3c,
  @IntegrationObjectID = @IntegrationObjectID_a0f6db3c,
  @Name = @Name_a0f6db3c,
  @DisplayName = @DisplayName_a0f6db3c,
  @Description = @Description_a0f6db3c,
  @Category = @Category_a0f6db3c,
  @Category_Clear = 1,
  @Type = @Type_a0f6db3c,
  @Length = @Length_a0f6db3c,
  @Length_Clear = 1,
  @Precision = @Precision_a0f6db3c,
  @Precision_Clear = 1,
  @Scale = @Scale_a0f6db3c,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_a0f6db3c,
  @DefaultValue = @DefaultValue_a0f6db3c,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_a0f6db3c,
  @IsUniqueKey = @IsUniqueKey_a0f6db3c,
  @IsReadOnly = @IsReadOnly_a0f6db3c,
  @IsRequired = @IsRequired_a0f6db3c,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_a0f6db3c,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_a0f6db3c,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_a0f6db3c,
  @Configuration = @Configuration_a0f6db3c,
  @Configuration_Clear = 1,
  @Status = @Status_a0f6db3c,
  @IsCustom = @IsCustom_a0f6db3c,
  @MetadataSource = @MetadataSource_a0f6db3c;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_aa6f7a28 UNIQUEIDENTIFIER,
@IntegrationObjectID_aa6f7a28 UNIQUEIDENTIFIER,
@Name_aa6f7a28 NVARCHAR(255),
@DisplayName_aa6f7a28 NVARCHAR(255),
@Description_aa6f7a28 NVARCHAR(MAX),
@Category_aa6f7a28 NVARCHAR(100),
@Type_aa6f7a28 NVARCHAR(100),
@Length_aa6f7a28 INT,
@Precision_aa6f7a28 INT,
@Scale_aa6f7a28 INT,
@AllowsNull_aa6f7a28 BIT,
@DefaultValue_aa6f7a28 NVARCHAR(255),
@IsPrimaryKey_aa6f7a28 BIT,
@IsUniqueKey_aa6f7a28 BIT,
@IsReadOnly_aa6f7a28 BIT,
@IsRequired_aa6f7a28 BIT,
@RelatedIntegrationObjectID_aa6f7a28 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_aa6f7a28 NVARCHAR(255),
@Sequence_aa6f7a28 INT,
@Configuration_aa6f7a28 NVARCHAR(MAX),
@Status_aa6f7a28 NVARCHAR(25),
@IsCustom_aa6f7a28 BIT,
@MetadataSource_aa6f7a28 NVARCHAR(20)
SET
  @ID_aa6f7a28 = '90750C5B-9BD9-533F-B6E5-ACA94DFF1572'
SET
  @IntegrationObjectID_aa6f7a28 = '2139B63E-5944-4542-BE5E-7213D64B9750'
SET
  @Name_aa6f7a28 = N'end-day'
SET
  @DisplayName_aa6f7a28 = N'End Day'
SET
  @Description_aa6f7a28 = N'Day of month of the affiliation end date; empty for a current/ongoing role, when given.'
SET
  @Type_aa6f7a28 = N'Integer'
SET
  @AllowsNull_aa6f7a28 = 1
SET
  @IsPrimaryKey_aa6f7a28 = 0
SET
  @IsUniqueKey_aa6f7a28 = 0
SET
  @IsReadOnly_aa6f7a28 = 1
SET
  @IsRequired_aa6f7a28 = 0
SET
  @Sequence_aa6f7a28 = 20
SET
  @Status_aa6f7a28 = N'Active'
SET
  @IsCustom_aa6f7a28 = 0
SET
  @MetadataSource_aa6f7a28 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_aa6f7a28,
  @IntegrationObjectID = @IntegrationObjectID_aa6f7a28,
  @Name = @Name_aa6f7a28,
  @DisplayName = @DisplayName_aa6f7a28,
  @Description = @Description_aa6f7a28,
  @Category = @Category_aa6f7a28,
  @Category_Clear = 1,
  @Type = @Type_aa6f7a28,
  @Length = @Length_aa6f7a28,
  @Length_Clear = 1,
  @Precision = @Precision_aa6f7a28,
  @Precision_Clear = 1,
  @Scale = @Scale_aa6f7a28,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_aa6f7a28,
  @DefaultValue = @DefaultValue_aa6f7a28,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_aa6f7a28,
  @IsUniqueKey = @IsUniqueKey_aa6f7a28,
  @IsReadOnly = @IsReadOnly_aa6f7a28,
  @IsRequired = @IsRequired_aa6f7a28,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_aa6f7a28,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_aa6f7a28,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_aa6f7a28,
  @Configuration = @Configuration_aa6f7a28,
  @Configuration_Clear = 1,
  @Status = @Status_aa6f7a28,
  @IsCustom = @IsCustom_aa6f7a28,
  @MetadataSource = @MetadataSource_aa6f7a28;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_5f4b8d67 UNIQUEIDENTIFIER,
@IntegrationObjectID_5f4b8d67 UNIQUEIDENTIFIER,
@Name_5f4b8d67 NVARCHAR(255),
@DisplayName_5f4b8d67 NVARCHAR(255),
@Description_5f4b8d67 NVARCHAR(MAX),
@Category_5f4b8d67 NVARCHAR(100),
@Type_5f4b8d67 NVARCHAR(100),
@Length_5f4b8d67 INT,
@Precision_5f4b8d67 INT,
@Scale_5f4b8d67 INT,
@AllowsNull_5f4b8d67 BIT,
@DefaultValue_5f4b8d67 NVARCHAR(255),
@IsPrimaryKey_5f4b8d67 BIT,
@IsUniqueKey_5f4b8d67 BIT,
@IsReadOnly_5f4b8d67 BIT,
@IsRequired_5f4b8d67 BIT,
@RelatedIntegrationObjectID_5f4b8d67 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_5f4b8d67 NVARCHAR(255),
@Sequence_5f4b8d67 INT,
@Configuration_5f4b8d67 NVARCHAR(MAX),
@Status_5f4b8d67 NVARCHAR(25),
@IsCustom_5f4b8d67 BIT,
@MetadataSource_5f4b8d67 NVARCHAR(20)
SET
  @ID_5f4b8d67 = '2AEA4CA3-6303-570D-AF1C-277F162C99D7'
SET
  @IntegrationObjectID_5f4b8d67 = '2139B63E-5944-4542-BE5E-7213D64B9750'
SET
  @Name_5f4b8d67 = N'organization-name'
SET
  @DisplayName_5f4b8d67 = N'Organization Name'
SET
  @Description_5f4b8d67 = N'Name of the organization. Lifted from organization.name.'
SET
  @Type_5f4b8d67 = N'String'
SET
  @Length_5f4b8d67 = 1000
SET
  @AllowsNull_5f4b8d67 = 1
SET
  @IsPrimaryKey_5f4b8d67 = 0
SET
  @IsUniqueKey_5f4b8d67 = 0
SET
  @IsReadOnly_5f4b8d67 = 1
SET
  @IsRequired_5f4b8d67 = 0
SET
  @Sequence_5f4b8d67 = 21
SET
  @Status_5f4b8d67 = N'Active'
SET
  @IsCustom_5f4b8d67 = 0
SET
  @MetadataSource_5f4b8d67 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_5f4b8d67,
  @IntegrationObjectID = @IntegrationObjectID_5f4b8d67,
  @Name = @Name_5f4b8d67,
  @DisplayName = @DisplayName_5f4b8d67,
  @Description = @Description_5f4b8d67,
  @Category = @Category_5f4b8d67,
  @Category_Clear = 1,
  @Type = @Type_5f4b8d67,
  @Length = @Length_5f4b8d67,
  @Precision = @Precision_5f4b8d67,
  @Precision_Clear = 1,
  @Scale = @Scale_5f4b8d67,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_5f4b8d67,
  @DefaultValue = @DefaultValue_5f4b8d67,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_5f4b8d67,
  @IsUniqueKey = @IsUniqueKey_5f4b8d67,
  @IsReadOnly = @IsReadOnly_5f4b8d67,
  @IsRequired = @IsRequired_5f4b8d67,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_5f4b8d67,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_5f4b8d67,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_5f4b8d67,
  @Configuration = @Configuration_5f4b8d67,
  @Configuration_Clear = 1,
  @Status = @Status_5f4b8d67,
  @IsCustom = @IsCustom_5f4b8d67,
  @MetadataSource = @MetadataSource_5f4b8d67;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_25873ed9 UNIQUEIDENTIFIER,
@IntegrationObjectID_25873ed9 UNIQUEIDENTIFIER,
@Name_25873ed9 NVARCHAR(255),
@DisplayName_25873ed9 NVARCHAR(255),
@Description_25873ed9 NVARCHAR(MAX),
@Category_25873ed9 NVARCHAR(100),
@Type_25873ed9 NVARCHAR(100),
@Length_25873ed9 INT,
@Precision_25873ed9 INT,
@Scale_25873ed9 INT,
@AllowsNull_25873ed9 BIT,
@DefaultValue_25873ed9 NVARCHAR(255),
@IsPrimaryKey_25873ed9 BIT,
@IsUniqueKey_25873ed9 BIT,
@IsReadOnly_25873ed9 BIT,
@IsRequired_25873ed9 BIT,
@RelatedIntegrationObjectID_25873ed9 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_25873ed9 NVARCHAR(255),
@Sequence_25873ed9 INT,
@Configuration_25873ed9 NVARCHAR(MAX),
@Status_25873ed9 NVARCHAR(25),
@IsCustom_25873ed9 BIT,
@MetadataSource_25873ed9 NVARCHAR(20)
SET
  @ID_25873ed9 = 'FF397CAE-0710-5834-A7AD-3B5341B4FCD3'
SET
  @IntegrationObjectID_25873ed9 = '2139B63E-5944-4542-BE5E-7213D64B9750'
SET
  @Name_25873ed9 = N'organization-city'
SET
  @DisplayName_25873ed9 = N'Organization City'
SET
  @Description_25873ed9 = N'City of the organization. Lifted from organization.address.city.'
SET
  @Type_25873ed9 = N'String'
SET
  @Length_25873ed9 = 255
SET
  @AllowsNull_25873ed9 = 1
SET
  @IsPrimaryKey_25873ed9 = 0
SET
  @IsUniqueKey_25873ed9 = 0
SET
  @IsReadOnly_25873ed9 = 1
SET
  @IsRequired_25873ed9 = 0
SET
  @Sequence_25873ed9 = 22
SET
  @Status_25873ed9 = N'Active'
SET
  @IsCustom_25873ed9 = 0
SET
  @MetadataSource_25873ed9 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_25873ed9,
  @IntegrationObjectID = @IntegrationObjectID_25873ed9,
  @Name = @Name_25873ed9,
  @DisplayName = @DisplayName_25873ed9,
  @Description = @Description_25873ed9,
  @Category = @Category_25873ed9,
  @Category_Clear = 1,
  @Type = @Type_25873ed9,
  @Length = @Length_25873ed9,
  @Precision = @Precision_25873ed9,
  @Precision_Clear = 1,
  @Scale = @Scale_25873ed9,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_25873ed9,
  @DefaultValue = @DefaultValue_25873ed9,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_25873ed9,
  @IsUniqueKey = @IsUniqueKey_25873ed9,
  @IsReadOnly = @IsReadOnly_25873ed9,
  @IsRequired = @IsRequired_25873ed9,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_25873ed9,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_25873ed9,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_25873ed9,
  @Configuration = @Configuration_25873ed9,
  @Configuration_Clear = 1,
  @Status = @Status_25873ed9,
  @IsCustom = @IsCustom_25873ed9,
  @MetadataSource = @MetadataSource_25873ed9;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_1abf2e83 UNIQUEIDENTIFIER,
@IntegrationObjectID_1abf2e83 UNIQUEIDENTIFIER,
@Name_1abf2e83 NVARCHAR(255),
@DisplayName_1abf2e83 NVARCHAR(255),
@Description_1abf2e83 NVARCHAR(MAX),
@Category_1abf2e83 NVARCHAR(100),
@Type_1abf2e83 NVARCHAR(100),
@Length_1abf2e83 INT,
@Precision_1abf2e83 INT,
@Scale_1abf2e83 INT,
@AllowsNull_1abf2e83 BIT,
@DefaultValue_1abf2e83 NVARCHAR(255),
@IsPrimaryKey_1abf2e83 BIT,
@IsUniqueKey_1abf2e83 BIT,
@IsReadOnly_1abf2e83 BIT,
@IsRequired_1abf2e83 BIT,
@RelatedIntegrationObjectID_1abf2e83 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_1abf2e83 NVARCHAR(255),
@Sequence_1abf2e83 INT,
@Configuration_1abf2e83 NVARCHAR(MAX),
@Status_1abf2e83 NVARCHAR(25),
@IsCustom_1abf2e83 BIT,
@MetadataSource_1abf2e83 NVARCHAR(20)
SET
  @ID_1abf2e83 = 'C8C75BBB-B473-535E-863C-E03C224564B8'
SET
  @IntegrationObjectID_1abf2e83 = '2139B63E-5944-4542-BE5E-7213D64B9750'
SET
  @Name_1abf2e83 = N'organization-region'
SET
  @DisplayName_1abf2e83 = N'Organization Region'
SET
  @Description_1abf2e83 = N'Region/state of the organization. Lifted from organization.address.region.'
SET
  @Type_1abf2e83 = N'String'
SET
  @Length_1abf2e83 = 255
SET
  @AllowsNull_1abf2e83 = 1
SET
  @IsPrimaryKey_1abf2e83 = 0
SET
  @IsUniqueKey_1abf2e83 = 0
SET
  @IsReadOnly_1abf2e83 = 1
SET
  @IsRequired_1abf2e83 = 0
SET
  @Sequence_1abf2e83 = 23
SET
  @Status_1abf2e83 = N'Active'
SET
  @IsCustom_1abf2e83 = 0
SET
  @MetadataSource_1abf2e83 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_1abf2e83,
  @IntegrationObjectID = @IntegrationObjectID_1abf2e83,
  @Name = @Name_1abf2e83,
  @DisplayName = @DisplayName_1abf2e83,
  @Description = @Description_1abf2e83,
  @Category = @Category_1abf2e83,
  @Category_Clear = 1,
  @Type = @Type_1abf2e83,
  @Length = @Length_1abf2e83,
  @Precision = @Precision_1abf2e83,
  @Precision_Clear = 1,
  @Scale = @Scale_1abf2e83,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_1abf2e83,
  @DefaultValue = @DefaultValue_1abf2e83,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_1abf2e83,
  @IsUniqueKey = @IsUniqueKey_1abf2e83,
  @IsReadOnly = @IsReadOnly_1abf2e83,
  @IsRequired = @IsRequired_1abf2e83,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_1abf2e83,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_1abf2e83,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_1abf2e83,
  @Configuration = @Configuration_1abf2e83,
  @Configuration_Clear = 1,
  @Status = @Status_1abf2e83,
  @IsCustom = @IsCustom_1abf2e83,
  @MetadataSource = @MetadataSource_1abf2e83;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_dd3d1b43 UNIQUEIDENTIFIER,
@IntegrationObjectID_dd3d1b43 UNIQUEIDENTIFIER,
@Name_dd3d1b43 NVARCHAR(255),
@DisplayName_dd3d1b43 NVARCHAR(255),
@Description_dd3d1b43 NVARCHAR(MAX),
@Category_dd3d1b43 NVARCHAR(100),
@Type_dd3d1b43 NVARCHAR(100),
@Length_dd3d1b43 INT,
@Precision_dd3d1b43 INT,
@Scale_dd3d1b43 INT,
@AllowsNull_dd3d1b43 BIT,
@DefaultValue_dd3d1b43 NVARCHAR(255),
@IsPrimaryKey_dd3d1b43 BIT,
@IsUniqueKey_dd3d1b43 BIT,
@IsReadOnly_dd3d1b43 BIT,
@IsRequired_dd3d1b43 BIT,
@RelatedIntegrationObjectID_dd3d1b43 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_dd3d1b43 NVARCHAR(255),
@Sequence_dd3d1b43 INT,
@Configuration_dd3d1b43 NVARCHAR(MAX),
@Status_dd3d1b43 NVARCHAR(25),
@IsCustom_dd3d1b43 BIT,
@MetadataSource_dd3d1b43 NVARCHAR(20)
SET
  @ID_dd3d1b43 = '1FF0C5F2-38C4-5FB1-BF64-F9B01E5F2407'
SET
  @IntegrationObjectID_dd3d1b43 = '2139B63E-5944-4542-BE5E-7213D64B9750'
SET
  @Name_dd3d1b43 = N'organization-country'
SET
  @DisplayName_dd3d1b43 = N'Organization Country'
SET
  @Description_dd3d1b43 = N'ISO country code of the organization. Lifted from organization.address.country.'
SET
  @Type_dd3d1b43 = N'String'
SET
  @Length_dd3d1b43 = 50
SET
  @AllowsNull_dd3d1b43 = 1
SET
  @IsPrimaryKey_dd3d1b43 = 0
SET
  @IsUniqueKey_dd3d1b43 = 0
SET
  @IsReadOnly_dd3d1b43 = 1
SET
  @IsRequired_dd3d1b43 = 0
SET
  @Sequence_dd3d1b43 = 24
SET
  @Status_dd3d1b43 = N'Active'
SET
  @IsCustom_dd3d1b43 = 0
SET
  @MetadataSource_dd3d1b43 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_dd3d1b43,
  @IntegrationObjectID = @IntegrationObjectID_dd3d1b43,
  @Name = @Name_dd3d1b43,
  @DisplayName = @DisplayName_dd3d1b43,
  @Description = @Description_dd3d1b43,
  @Category = @Category_dd3d1b43,
  @Category_Clear = 1,
  @Type = @Type_dd3d1b43,
  @Length = @Length_dd3d1b43,
  @Precision = @Precision_dd3d1b43,
  @Precision_Clear = 1,
  @Scale = @Scale_dd3d1b43,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_dd3d1b43,
  @DefaultValue = @DefaultValue_dd3d1b43,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_dd3d1b43,
  @IsUniqueKey = @IsUniqueKey_dd3d1b43,
  @IsReadOnly = @IsReadOnly_dd3d1b43,
  @IsRequired = @IsRequired_dd3d1b43,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_dd3d1b43,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_dd3d1b43,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_dd3d1b43,
  @Configuration = @Configuration_dd3d1b43,
  @Configuration_Clear = 1,
  @Status = @Status_dd3d1b43,
  @IsCustom = @IsCustom_dd3d1b43,
  @MetadataSource = @MetadataSource_dd3d1b43;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_48fd00e1 UNIQUEIDENTIFIER,
@IntegrationObjectID_48fd00e1 UNIQUEIDENTIFIER,
@Name_48fd00e1 NVARCHAR(255),
@DisplayName_48fd00e1 NVARCHAR(255),
@Description_48fd00e1 NVARCHAR(MAX),
@Category_48fd00e1 NVARCHAR(100),
@Type_48fd00e1 NVARCHAR(100),
@Length_48fd00e1 INT,
@Precision_48fd00e1 INT,
@Scale_48fd00e1 INT,
@AllowsNull_48fd00e1 BIT,
@DefaultValue_48fd00e1 NVARCHAR(255),
@IsPrimaryKey_48fd00e1 BIT,
@IsUniqueKey_48fd00e1 BIT,
@IsReadOnly_48fd00e1 BIT,
@IsRequired_48fd00e1 BIT,
@RelatedIntegrationObjectID_48fd00e1 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_48fd00e1 NVARCHAR(255),
@Sequence_48fd00e1 INT,
@Configuration_48fd00e1 NVARCHAR(MAX),
@Status_48fd00e1 NVARCHAR(25),
@IsCustom_48fd00e1 BIT,
@MetadataSource_48fd00e1 NVARCHAR(20)
SET
  @ID_48fd00e1 = '529E36C0-E40F-5DEF-BE25-1C16AF08FD68'
SET
  @IntegrationObjectID_48fd00e1 = '2139B63E-5944-4542-BE5E-7213D64B9750'
SET
  @Name_48fd00e1 = N'organization-disambiguated-id'
SET
  @DisplayName_48fd00e1 = N'Organization Disambiguated Id'
SET
  @Description_48fd00e1 = N'Canonical identifier of the organization in the disambiguation source (e.g. a RINGGOLD or ROR id), so the same institution matches across records.'
SET
  @Type_48fd00e1 = N'String'
SET
  @Length_48fd00e1 = 255
SET
  @AllowsNull_48fd00e1 = 1
SET
  @IsPrimaryKey_48fd00e1 = 0
SET
  @IsUniqueKey_48fd00e1 = 0
SET
  @IsReadOnly_48fd00e1 = 1
SET
  @IsRequired_48fd00e1 = 0
SET
  @Sequence_48fd00e1 = 25
SET
  @Status_48fd00e1 = N'Active'
SET
  @IsCustom_48fd00e1 = 0
SET
  @MetadataSource_48fd00e1 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_48fd00e1,
  @IntegrationObjectID = @IntegrationObjectID_48fd00e1,
  @Name = @Name_48fd00e1,
  @DisplayName = @DisplayName_48fd00e1,
  @Description = @Description_48fd00e1,
  @Category = @Category_48fd00e1,
  @Category_Clear = 1,
  @Type = @Type_48fd00e1,
  @Length = @Length_48fd00e1,
  @Precision = @Precision_48fd00e1,
  @Precision_Clear = 1,
  @Scale = @Scale_48fd00e1,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_48fd00e1,
  @DefaultValue = @DefaultValue_48fd00e1,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_48fd00e1,
  @IsUniqueKey = @IsUniqueKey_48fd00e1,
  @IsReadOnly = @IsReadOnly_48fd00e1,
  @IsRequired = @IsRequired_48fd00e1,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_48fd00e1,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_48fd00e1,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_48fd00e1,
  @Configuration = @Configuration_48fd00e1,
  @Configuration_Clear = 1,
  @Status = @Status_48fd00e1,
  @IsCustom = @IsCustom_48fd00e1,
  @MetadataSource = @MetadataSource_48fd00e1;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_5253e79c UNIQUEIDENTIFIER,
@IntegrationObjectID_5253e79c UNIQUEIDENTIFIER,
@Name_5253e79c NVARCHAR(255),
@DisplayName_5253e79c NVARCHAR(255),
@Description_5253e79c NVARCHAR(MAX),
@Category_5253e79c NVARCHAR(100),
@Type_5253e79c NVARCHAR(100),
@Length_5253e79c INT,
@Precision_5253e79c INT,
@Scale_5253e79c INT,
@AllowsNull_5253e79c BIT,
@DefaultValue_5253e79c NVARCHAR(255),
@IsPrimaryKey_5253e79c BIT,
@IsUniqueKey_5253e79c BIT,
@IsReadOnly_5253e79c BIT,
@IsRequired_5253e79c BIT,
@RelatedIntegrationObjectID_5253e79c UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_5253e79c NVARCHAR(255),
@Sequence_5253e79c INT,
@Configuration_5253e79c NVARCHAR(MAX),
@Status_5253e79c NVARCHAR(25),
@IsCustom_5253e79c BIT,
@MetadataSource_5253e79c NVARCHAR(20)
SET
  @ID_5253e79c = '82425058-1EEF-53C5-85DA-56D668903918'
SET
  @IntegrationObjectID_5253e79c = '2139B63E-5944-4542-BE5E-7213D64B9750'
SET
  @Name_5253e79c = N'organization-disambiguation-source'
SET
  @DisplayName_5253e79c = N'Organization Disambiguation Source'
SET
  @Description_5253e79c = N'Registry the disambiguated id comes from (RINGGOLD, ROR, FUNDREF, GRID, LEI).'
SET
  @Type_5253e79c = N'String'
SET
  @Length_5253e79c = 100
SET
  @AllowsNull_5253e79c = 1
SET
  @IsPrimaryKey_5253e79c = 0
SET
  @IsUniqueKey_5253e79c = 0
SET
  @IsReadOnly_5253e79c = 1
SET
  @IsRequired_5253e79c = 0
SET
  @Sequence_5253e79c = 26
SET
  @Status_5253e79c = N'Active'
SET
  @IsCustom_5253e79c = 0
SET
  @MetadataSource_5253e79c = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_5253e79c,
  @IntegrationObjectID = @IntegrationObjectID_5253e79c,
  @Name = @Name_5253e79c,
  @DisplayName = @DisplayName_5253e79c,
  @Description = @Description_5253e79c,
  @Category = @Category_5253e79c,
  @Category_Clear = 1,
  @Type = @Type_5253e79c,
  @Length = @Length_5253e79c,
  @Precision = @Precision_5253e79c,
  @Precision_Clear = 1,
  @Scale = @Scale_5253e79c,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_5253e79c,
  @DefaultValue = @DefaultValue_5253e79c,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_5253e79c,
  @IsUniqueKey = @IsUniqueKey_5253e79c,
  @IsReadOnly = @IsReadOnly_5253e79c,
  @IsRequired = @IsRequired_5253e79c,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_5253e79c,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_5253e79c,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_5253e79c,
  @Configuration = @Configuration_5253e79c,
  @Configuration_Clear = 1,
  @Status = @Status_5253e79c,
  @IsCustom = @IsCustom_5253e79c,
  @MetadataSource = @MetadataSource_5253e79c;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_573ab27d UNIQUEIDENTIFIER,
@IntegrationObjectID_573ab27d UNIQUEIDENTIFIER,
@Name_573ab27d NVARCHAR(255),
@DisplayName_573ab27d NVARCHAR(255),
@Description_573ab27d NVARCHAR(MAX),
@Category_573ab27d NVARCHAR(100),
@Type_573ab27d NVARCHAR(100),
@Length_573ab27d INT,
@Precision_573ab27d INT,
@Scale_573ab27d INT,
@AllowsNull_573ab27d BIT,
@DefaultValue_573ab27d NVARCHAR(255),
@IsPrimaryKey_573ab27d BIT,
@IsUniqueKey_573ab27d BIT,
@IsReadOnly_573ab27d BIT,
@IsRequired_573ab27d BIT,
@RelatedIntegrationObjectID_573ab27d UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_573ab27d NVARCHAR(255),
@Sequence_573ab27d INT,
@Configuration_573ab27d NVARCHAR(MAX),
@Status_573ab27d NVARCHAR(25),
@IsCustom_573ab27d BIT,
@MetadataSource_573ab27d NVARCHAR(20)
SET
  @ID_573ab27d = 'EE8D98DD-272D-505C-A75E-305D27640B37'
SET
  @IntegrationObjectID_573ab27d = '2139B63E-5944-4542-BE5E-7213D64B9750'
SET
  @Name_573ab27d = N'source-name'
SET
  @DisplayName_573ab27d = N'Source Name'
SET
  @Description_573ab27d = N'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.'
SET
  @Type_573ab27d = N'String'
SET
  @Length_573ab27d = 500
SET
  @AllowsNull_573ab27d = 1
SET
  @IsPrimaryKey_573ab27d = 0
SET
  @IsUniqueKey_573ab27d = 0
SET
  @IsReadOnly_573ab27d = 1
SET
  @IsRequired_573ab27d = 0
SET
  @Sequence_573ab27d = 27
SET
  @Status_573ab27d = N'Active'
SET
  @IsCustom_573ab27d = 0
SET
  @MetadataSource_573ab27d = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_573ab27d,
  @IntegrationObjectID = @IntegrationObjectID_573ab27d,
  @Name = @Name_573ab27d,
  @DisplayName = @DisplayName_573ab27d,
  @Description = @Description_573ab27d,
  @Category = @Category_573ab27d,
  @Category_Clear = 1,
  @Type = @Type_573ab27d,
  @Length = @Length_573ab27d,
  @Precision = @Precision_573ab27d,
  @Precision_Clear = 1,
  @Scale = @Scale_573ab27d,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_573ab27d,
  @DefaultValue = @DefaultValue_573ab27d,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_573ab27d,
  @IsUniqueKey = @IsUniqueKey_573ab27d,
  @IsReadOnly = @IsReadOnly_573ab27d,
  @IsRequired = @IsRequired_573ab27d,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_573ab27d,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_573ab27d,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_573ab27d,
  @Configuration = @Configuration_573ab27d,
  @Configuration_Clear = 1,
  @Status = @Status_573ab27d,
  @IsCustom = @IsCustom_573ab27d,
  @MetadataSource = @MetadataSource_573ab27d;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_00dfed58 UNIQUEIDENTIFIER,
@IntegrationObjectID_00dfed58 UNIQUEIDENTIFIER,
@Name_00dfed58 NVARCHAR(255),
@DisplayName_00dfed58 NVARCHAR(255),
@Description_00dfed58 NVARCHAR(MAX),
@Category_00dfed58 NVARCHAR(100),
@Type_00dfed58 NVARCHAR(100),
@Length_00dfed58 INT,
@Precision_00dfed58 INT,
@Scale_00dfed58 INT,
@AllowsNull_00dfed58 BIT,
@DefaultValue_00dfed58 NVARCHAR(255),
@IsPrimaryKey_00dfed58 BIT,
@IsUniqueKey_00dfed58 BIT,
@IsReadOnly_00dfed58 BIT,
@IsRequired_00dfed58 BIT,
@RelatedIntegrationObjectID_00dfed58 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_00dfed58 NVARCHAR(255),
@Sequence_00dfed58 INT,
@Configuration_00dfed58 NVARCHAR(MAX),
@Status_00dfed58 NVARCHAR(25),
@IsCustom_00dfed58 BIT,
@MetadataSource_00dfed58 NVARCHAR(20)
SET
  @ID_00dfed58 = '6A1B2BC9-537D-5BAC-944A-BCCE23C1C675'
SET
  @IntegrationObjectID_00dfed58 = '2139B63E-5944-4542-BE5E-7213D64B9750'
SET
  @Name_00dfed58 = N'source-orcid'
SET
  @DisplayName_00dfed58 = N'Source Orcid'
SET
  @Description_00dfed58 = N'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.'
SET
  @Type_00dfed58 = N'String'
SET
  @Length_00dfed58 = 19
SET
  @AllowsNull_00dfed58 = 1
SET
  @IsPrimaryKey_00dfed58 = 0
SET
  @IsUniqueKey_00dfed58 = 0
SET
  @IsReadOnly_00dfed58 = 1
SET
  @IsRequired_00dfed58 = 0
SET
  @Sequence_00dfed58 = 28
SET
  @Status_00dfed58 = N'Active'
SET
  @IsCustom_00dfed58 = 0
SET
  @MetadataSource_00dfed58 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_00dfed58,
  @IntegrationObjectID = @IntegrationObjectID_00dfed58,
  @Name = @Name_00dfed58,
  @DisplayName = @DisplayName_00dfed58,
  @Description = @Description_00dfed58,
  @Category = @Category_00dfed58,
  @Category_Clear = 1,
  @Type = @Type_00dfed58,
  @Length = @Length_00dfed58,
  @Precision = @Precision_00dfed58,
  @Precision_Clear = 1,
  @Scale = @Scale_00dfed58,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_00dfed58,
  @DefaultValue = @DefaultValue_00dfed58,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_00dfed58,
  @IsUniqueKey = @IsUniqueKey_00dfed58,
  @IsReadOnly = @IsReadOnly_00dfed58,
  @IsRequired = @IsRequired_00dfed58,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_00dfed58,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_00dfed58,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_00dfed58,
  @Configuration = @Configuration_00dfed58,
  @Configuration_Clear = 1,
  @Status = @Status_00dfed58,
  @IsCustom = @IsCustom_00dfed58,
  @MetadataSource = @MetadataSource_00dfed58;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_3938e41e UNIQUEIDENTIFIER,
@IntegrationObjectID_3938e41e UNIQUEIDENTIFIER,
@Name_3938e41e NVARCHAR(255),
@DisplayName_3938e41e NVARCHAR(255),
@Description_3938e41e NVARCHAR(MAX),
@Category_3938e41e NVARCHAR(100),
@Type_3938e41e NVARCHAR(100),
@Length_3938e41e INT,
@Precision_3938e41e INT,
@Scale_3938e41e INT,
@AllowsNull_3938e41e BIT,
@DefaultValue_3938e41e NVARCHAR(255),
@IsPrimaryKey_3938e41e BIT,
@IsUniqueKey_3938e41e BIT,
@IsReadOnly_3938e41e BIT,
@IsRequired_3938e41e BIT,
@RelatedIntegrationObjectID_3938e41e UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_3938e41e NVARCHAR(255),
@Sequence_3938e41e INT,
@Configuration_3938e41e NVARCHAR(MAX),
@Status_3938e41e NVARCHAR(25),
@IsCustom_3938e41e BIT,
@MetadataSource_3938e41e NVARCHAR(20)
SET
  @ID_3938e41e = 'CBCC26E7-008B-5E7B-A5D3-717651705852'
SET
  @IntegrationObjectID_3938e41e = '5DD9CF05-1571-454E-BA40-D65E6B9C2131'
SET
  @Name_3938e41e = N'start-year'
SET
  @DisplayName_3938e41e = N'Start Year'
SET
  @Description_3938e41e = N'Year of the affiliation start date; ORCID dates are partial, so month/day may be absent.'
SET
  @Type_3938e41e = N'Integer'
SET
  @AllowsNull_3938e41e = 1
SET
  @IsPrimaryKey_3938e41e = 0
SET
  @IsUniqueKey_3938e41e = 0
SET
  @IsReadOnly_3938e41e = 1
SET
  @IsRequired_3938e41e = 0
SET
  @Sequence_3938e41e = 15
SET
  @Status_3938e41e = N'Active'
SET
  @IsCustom_3938e41e = 0
SET
  @MetadataSource_3938e41e = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_3938e41e,
  @IntegrationObjectID = @IntegrationObjectID_3938e41e,
  @Name = @Name_3938e41e,
  @DisplayName = @DisplayName_3938e41e,
  @Description = @Description_3938e41e,
  @Category = @Category_3938e41e,
  @Category_Clear = 1,
  @Type = @Type_3938e41e,
  @Length = @Length_3938e41e,
  @Length_Clear = 1,
  @Precision = @Precision_3938e41e,
  @Precision_Clear = 1,
  @Scale = @Scale_3938e41e,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_3938e41e,
  @DefaultValue = @DefaultValue_3938e41e,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_3938e41e,
  @IsUniqueKey = @IsUniqueKey_3938e41e,
  @IsReadOnly = @IsReadOnly_3938e41e,
  @IsRequired = @IsRequired_3938e41e,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_3938e41e,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_3938e41e,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_3938e41e,
  @Configuration = @Configuration_3938e41e,
  @Configuration_Clear = 1,
  @Status = @Status_3938e41e,
  @IsCustom = @IsCustom_3938e41e,
  @MetadataSource = @MetadataSource_3938e41e;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_a5732338 UNIQUEIDENTIFIER,
@IntegrationObjectID_a5732338 UNIQUEIDENTIFIER,
@Name_a5732338 NVARCHAR(255),
@DisplayName_a5732338 NVARCHAR(255),
@Description_a5732338 NVARCHAR(MAX),
@Category_a5732338 NVARCHAR(100),
@Type_a5732338 NVARCHAR(100),
@Length_a5732338 INT,
@Precision_a5732338 INT,
@Scale_a5732338 INT,
@AllowsNull_a5732338 BIT,
@DefaultValue_a5732338 NVARCHAR(255),
@IsPrimaryKey_a5732338 BIT,
@IsUniqueKey_a5732338 BIT,
@IsReadOnly_a5732338 BIT,
@IsRequired_a5732338 BIT,
@RelatedIntegrationObjectID_a5732338 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_a5732338 NVARCHAR(255),
@Sequence_a5732338 INT,
@Configuration_a5732338 NVARCHAR(MAX),
@Status_a5732338 NVARCHAR(25),
@IsCustom_a5732338 BIT,
@MetadataSource_a5732338 NVARCHAR(20)
SET
  @ID_a5732338 = 'D0966733-A52A-5137-A446-3F91A37B1299'
SET
  @IntegrationObjectID_a5732338 = '5DD9CF05-1571-454E-BA40-D65E6B9C2131'
SET
  @Name_a5732338 = N'start-month'
SET
  @DisplayName_a5732338 = N'Start Month'
SET
  @Description_a5732338 = N'Month (1-12) of the affiliation start date, when given.'
SET
  @Type_a5732338 = N'Integer'
SET
  @AllowsNull_a5732338 = 1
SET
  @IsPrimaryKey_a5732338 = 0
SET
  @IsUniqueKey_a5732338 = 0
SET
  @IsReadOnly_a5732338 = 1
SET
  @IsRequired_a5732338 = 0
SET
  @Sequence_a5732338 = 16
SET
  @Status_a5732338 = N'Active'
SET
  @IsCustom_a5732338 = 0
SET
  @MetadataSource_a5732338 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_a5732338,
  @IntegrationObjectID = @IntegrationObjectID_a5732338,
  @Name = @Name_a5732338,
  @DisplayName = @DisplayName_a5732338,
  @Description = @Description_a5732338,
  @Category = @Category_a5732338,
  @Category_Clear = 1,
  @Type = @Type_a5732338,
  @Length = @Length_a5732338,
  @Length_Clear = 1,
  @Precision = @Precision_a5732338,
  @Precision_Clear = 1,
  @Scale = @Scale_a5732338,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_a5732338,
  @DefaultValue = @DefaultValue_a5732338,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_a5732338,
  @IsUniqueKey = @IsUniqueKey_a5732338,
  @IsReadOnly = @IsReadOnly_a5732338,
  @IsRequired = @IsRequired_a5732338,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_a5732338,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_a5732338,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_a5732338,
  @Configuration = @Configuration_a5732338,
  @Configuration_Clear = 1,
  @Status = @Status_a5732338,
  @IsCustom = @IsCustom_a5732338,
  @MetadataSource = @MetadataSource_a5732338;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_e4c377ac UNIQUEIDENTIFIER,
@IntegrationObjectID_e4c377ac UNIQUEIDENTIFIER,
@Name_e4c377ac NVARCHAR(255),
@DisplayName_e4c377ac NVARCHAR(255),
@Description_e4c377ac NVARCHAR(MAX),
@Category_e4c377ac NVARCHAR(100),
@Type_e4c377ac NVARCHAR(100),
@Length_e4c377ac INT,
@Precision_e4c377ac INT,
@Scale_e4c377ac INT,
@AllowsNull_e4c377ac BIT,
@DefaultValue_e4c377ac NVARCHAR(255),
@IsPrimaryKey_e4c377ac BIT,
@IsUniqueKey_e4c377ac BIT,
@IsReadOnly_e4c377ac BIT,
@IsRequired_e4c377ac BIT,
@RelatedIntegrationObjectID_e4c377ac UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_e4c377ac NVARCHAR(255),
@Sequence_e4c377ac INT,
@Configuration_e4c377ac NVARCHAR(MAX),
@Status_e4c377ac NVARCHAR(25),
@IsCustom_e4c377ac BIT,
@MetadataSource_e4c377ac NVARCHAR(20)
SET
  @ID_e4c377ac = '39D1FFA1-5E0F-5D16-9EE2-4810C6D8E001'
SET
  @IntegrationObjectID_e4c377ac = '5DD9CF05-1571-454E-BA40-D65E6B9C2131'
SET
  @Name_e4c377ac = N'start-day'
SET
  @DisplayName_e4c377ac = N'Start Day'
SET
  @Description_e4c377ac = N'Day of month of the affiliation start date, when given.'
SET
  @Type_e4c377ac = N'Integer'
SET
  @AllowsNull_e4c377ac = 1
SET
  @IsPrimaryKey_e4c377ac = 0
SET
  @IsUniqueKey_e4c377ac = 0
SET
  @IsReadOnly_e4c377ac = 1
SET
  @IsRequired_e4c377ac = 0
SET
  @Sequence_e4c377ac = 17
SET
  @Status_e4c377ac = N'Active'
SET
  @IsCustom_e4c377ac = 0
SET
  @MetadataSource_e4c377ac = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_e4c377ac,
  @IntegrationObjectID = @IntegrationObjectID_e4c377ac,
  @Name = @Name_e4c377ac,
  @DisplayName = @DisplayName_e4c377ac,
  @Description = @Description_e4c377ac,
  @Category = @Category_e4c377ac,
  @Category_Clear = 1,
  @Type = @Type_e4c377ac,
  @Length = @Length_e4c377ac,
  @Length_Clear = 1,
  @Precision = @Precision_e4c377ac,
  @Precision_Clear = 1,
  @Scale = @Scale_e4c377ac,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_e4c377ac,
  @DefaultValue = @DefaultValue_e4c377ac,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_e4c377ac,
  @IsUniqueKey = @IsUniqueKey_e4c377ac,
  @IsReadOnly = @IsReadOnly_e4c377ac,
  @IsRequired = @IsRequired_e4c377ac,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_e4c377ac,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_e4c377ac,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_e4c377ac,
  @Configuration = @Configuration_e4c377ac,
  @Configuration_Clear = 1,
  @Status = @Status_e4c377ac,
  @IsCustom = @IsCustom_e4c377ac,
  @MetadataSource = @MetadataSource_e4c377ac;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_2d428f74 UNIQUEIDENTIFIER,
@IntegrationObjectID_2d428f74 UNIQUEIDENTIFIER,
@Name_2d428f74 NVARCHAR(255),
@DisplayName_2d428f74 NVARCHAR(255),
@Description_2d428f74 NVARCHAR(MAX),
@Category_2d428f74 NVARCHAR(100),
@Type_2d428f74 NVARCHAR(100),
@Length_2d428f74 INT,
@Precision_2d428f74 INT,
@Scale_2d428f74 INT,
@AllowsNull_2d428f74 BIT,
@DefaultValue_2d428f74 NVARCHAR(255),
@IsPrimaryKey_2d428f74 BIT,
@IsUniqueKey_2d428f74 BIT,
@IsReadOnly_2d428f74 BIT,
@IsRequired_2d428f74 BIT,
@RelatedIntegrationObjectID_2d428f74 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_2d428f74 NVARCHAR(255),
@Sequence_2d428f74 INT,
@Configuration_2d428f74 NVARCHAR(MAX),
@Status_2d428f74 NVARCHAR(25),
@IsCustom_2d428f74 BIT,
@MetadataSource_2d428f74 NVARCHAR(20)
SET
  @ID_2d428f74 = '806C2EB8-7F31-5B52-B9BF-AD312F17E9E7'
SET
  @IntegrationObjectID_2d428f74 = '5DD9CF05-1571-454E-BA40-D65E6B9C2131'
SET
  @Name_2d428f74 = N'end-year'
SET
  @DisplayName_2d428f74 = N'End Year'
SET
  @Description_2d428f74 = N'Year of the affiliation end date; empty for a current/ongoing role; ORCID dates are partial, so month/day may be absent.'
SET
  @Type_2d428f74 = N'Integer'
SET
  @AllowsNull_2d428f74 = 1
SET
  @IsPrimaryKey_2d428f74 = 0
SET
  @IsUniqueKey_2d428f74 = 0
SET
  @IsReadOnly_2d428f74 = 1
SET
  @IsRequired_2d428f74 = 0
SET
  @Sequence_2d428f74 = 18
SET
  @Status_2d428f74 = N'Active'
SET
  @IsCustom_2d428f74 = 0
SET
  @MetadataSource_2d428f74 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_2d428f74,
  @IntegrationObjectID = @IntegrationObjectID_2d428f74,
  @Name = @Name_2d428f74,
  @DisplayName = @DisplayName_2d428f74,
  @Description = @Description_2d428f74,
  @Category = @Category_2d428f74,
  @Category_Clear = 1,
  @Type = @Type_2d428f74,
  @Length = @Length_2d428f74,
  @Length_Clear = 1,
  @Precision = @Precision_2d428f74,
  @Precision_Clear = 1,
  @Scale = @Scale_2d428f74,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_2d428f74,
  @DefaultValue = @DefaultValue_2d428f74,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_2d428f74,
  @IsUniqueKey = @IsUniqueKey_2d428f74,
  @IsReadOnly = @IsReadOnly_2d428f74,
  @IsRequired = @IsRequired_2d428f74,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_2d428f74,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_2d428f74,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_2d428f74,
  @Configuration = @Configuration_2d428f74,
  @Configuration_Clear = 1,
  @Status = @Status_2d428f74,
  @IsCustom = @IsCustom_2d428f74,
  @MetadataSource = @MetadataSource_2d428f74;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_50d91ade UNIQUEIDENTIFIER,
@IntegrationObjectID_50d91ade UNIQUEIDENTIFIER,
@Name_50d91ade NVARCHAR(255),
@DisplayName_50d91ade NVARCHAR(255),
@Description_50d91ade NVARCHAR(MAX),
@Category_50d91ade NVARCHAR(100),
@Type_50d91ade NVARCHAR(100),
@Length_50d91ade INT,
@Precision_50d91ade INT,
@Scale_50d91ade INT,
@AllowsNull_50d91ade BIT,
@DefaultValue_50d91ade NVARCHAR(255),
@IsPrimaryKey_50d91ade BIT,
@IsUniqueKey_50d91ade BIT,
@IsReadOnly_50d91ade BIT,
@IsRequired_50d91ade BIT,
@RelatedIntegrationObjectID_50d91ade UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_50d91ade NVARCHAR(255),
@Sequence_50d91ade INT,
@Configuration_50d91ade NVARCHAR(MAX),
@Status_50d91ade NVARCHAR(25),
@IsCustom_50d91ade BIT,
@MetadataSource_50d91ade NVARCHAR(20)
SET
  @ID_50d91ade = '40B42903-AF02-5EA1-B32A-3365B4E4AC4B'
SET
  @IntegrationObjectID_50d91ade = '5DD9CF05-1571-454E-BA40-D65E6B9C2131'
SET
  @Name_50d91ade = N'end-month'
SET
  @DisplayName_50d91ade = N'End Month'
SET
  @Description_50d91ade = N'Month (1-12) of the affiliation end date; empty for a current/ongoing role, when given.'
SET
  @Type_50d91ade = N'Integer'
SET
  @AllowsNull_50d91ade = 1
SET
  @IsPrimaryKey_50d91ade = 0
SET
  @IsUniqueKey_50d91ade = 0
SET
  @IsReadOnly_50d91ade = 1
SET
  @IsRequired_50d91ade = 0
SET
  @Sequence_50d91ade = 19
SET
  @Status_50d91ade = N'Active'
SET
  @IsCustom_50d91ade = 0
SET
  @MetadataSource_50d91ade = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_50d91ade,
  @IntegrationObjectID = @IntegrationObjectID_50d91ade,
  @Name = @Name_50d91ade,
  @DisplayName = @DisplayName_50d91ade,
  @Description = @Description_50d91ade,
  @Category = @Category_50d91ade,
  @Category_Clear = 1,
  @Type = @Type_50d91ade,
  @Length = @Length_50d91ade,
  @Length_Clear = 1,
  @Precision = @Precision_50d91ade,
  @Precision_Clear = 1,
  @Scale = @Scale_50d91ade,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_50d91ade,
  @DefaultValue = @DefaultValue_50d91ade,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_50d91ade,
  @IsUniqueKey = @IsUniqueKey_50d91ade,
  @IsReadOnly = @IsReadOnly_50d91ade,
  @IsRequired = @IsRequired_50d91ade,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_50d91ade,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_50d91ade,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_50d91ade,
  @Configuration = @Configuration_50d91ade,
  @Configuration_Clear = 1,
  @Status = @Status_50d91ade,
  @IsCustom = @IsCustom_50d91ade,
  @MetadataSource = @MetadataSource_50d91ade;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_69effdca UNIQUEIDENTIFIER,
@IntegrationObjectID_69effdca UNIQUEIDENTIFIER,
@Name_69effdca NVARCHAR(255),
@DisplayName_69effdca NVARCHAR(255),
@Description_69effdca NVARCHAR(MAX),
@Category_69effdca NVARCHAR(100),
@Type_69effdca NVARCHAR(100),
@Length_69effdca INT,
@Precision_69effdca INT,
@Scale_69effdca INT,
@AllowsNull_69effdca BIT,
@DefaultValue_69effdca NVARCHAR(255),
@IsPrimaryKey_69effdca BIT,
@IsUniqueKey_69effdca BIT,
@IsReadOnly_69effdca BIT,
@IsRequired_69effdca BIT,
@RelatedIntegrationObjectID_69effdca UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_69effdca NVARCHAR(255),
@Sequence_69effdca INT,
@Configuration_69effdca NVARCHAR(MAX),
@Status_69effdca NVARCHAR(25),
@IsCustom_69effdca BIT,
@MetadataSource_69effdca NVARCHAR(20)
SET
  @ID_69effdca = '352EA5ED-6C6C-5CCC-ACAA-EBE0A1EBE877'
SET
  @IntegrationObjectID_69effdca = '5DD9CF05-1571-454E-BA40-D65E6B9C2131'
SET
  @Name_69effdca = N'end-day'
SET
  @DisplayName_69effdca = N'End Day'
SET
  @Description_69effdca = N'Day of month of the affiliation end date; empty for a current/ongoing role, when given.'
SET
  @Type_69effdca = N'Integer'
SET
  @AllowsNull_69effdca = 1
SET
  @IsPrimaryKey_69effdca = 0
SET
  @IsUniqueKey_69effdca = 0
SET
  @IsReadOnly_69effdca = 1
SET
  @IsRequired_69effdca = 0
SET
  @Sequence_69effdca = 20
SET
  @Status_69effdca = N'Active'
SET
  @IsCustom_69effdca = 0
SET
  @MetadataSource_69effdca = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_69effdca,
  @IntegrationObjectID = @IntegrationObjectID_69effdca,
  @Name = @Name_69effdca,
  @DisplayName = @DisplayName_69effdca,
  @Description = @Description_69effdca,
  @Category = @Category_69effdca,
  @Category_Clear = 1,
  @Type = @Type_69effdca,
  @Length = @Length_69effdca,
  @Length_Clear = 1,
  @Precision = @Precision_69effdca,
  @Precision_Clear = 1,
  @Scale = @Scale_69effdca,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_69effdca,
  @DefaultValue = @DefaultValue_69effdca,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_69effdca,
  @IsUniqueKey = @IsUniqueKey_69effdca,
  @IsReadOnly = @IsReadOnly_69effdca,
  @IsRequired = @IsRequired_69effdca,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_69effdca,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_69effdca,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_69effdca,
  @Configuration = @Configuration_69effdca,
  @Configuration_Clear = 1,
  @Status = @Status_69effdca,
  @IsCustom = @IsCustom_69effdca,
  @MetadataSource = @MetadataSource_69effdca;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_6f1867b0 UNIQUEIDENTIFIER,
@IntegrationObjectID_6f1867b0 UNIQUEIDENTIFIER,
@Name_6f1867b0 NVARCHAR(255),
@DisplayName_6f1867b0 NVARCHAR(255),
@Description_6f1867b0 NVARCHAR(MAX),
@Category_6f1867b0 NVARCHAR(100),
@Type_6f1867b0 NVARCHAR(100),
@Length_6f1867b0 INT,
@Precision_6f1867b0 INT,
@Scale_6f1867b0 INT,
@AllowsNull_6f1867b0 BIT,
@DefaultValue_6f1867b0 NVARCHAR(255),
@IsPrimaryKey_6f1867b0 BIT,
@IsUniqueKey_6f1867b0 BIT,
@IsReadOnly_6f1867b0 BIT,
@IsRequired_6f1867b0 BIT,
@RelatedIntegrationObjectID_6f1867b0 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_6f1867b0 NVARCHAR(255),
@Sequence_6f1867b0 INT,
@Configuration_6f1867b0 NVARCHAR(MAX),
@Status_6f1867b0 NVARCHAR(25),
@IsCustom_6f1867b0 BIT,
@MetadataSource_6f1867b0 NVARCHAR(20)
SET
  @ID_6f1867b0 = '017EF05F-9FBE-50B9-90F4-C2C443147BC7'
SET
  @IntegrationObjectID_6f1867b0 = '5DD9CF05-1571-454E-BA40-D65E6B9C2131'
SET
  @Name_6f1867b0 = N'organization-name'
SET
  @DisplayName_6f1867b0 = N'Organization Name'
SET
  @Description_6f1867b0 = N'Name of the organization. Lifted from organization.name.'
SET
  @Type_6f1867b0 = N'String'
SET
  @Length_6f1867b0 = 1000
SET
  @AllowsNull_6f1867b0 = 1
SET
  @IsPrimaryKey_6f1867b0 = 0
SET
  @IsUniqueKey_6f1867b0 = 0
SET
  @IsReadOnly_6f1867b0 = 1
SET
  @IsRequired_6f1867b0 = 0
SET
  @Sequence_6f1867b0 = 21
SET
  @Status_6f1867b0 = N'Active'
SET
  @IsCustom_6f1867b0 = 0
SET
  @MetadataSource_6f1867b0 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_6f1867b0,
  @IntegrationObjectID = @IntegrationObjectID_6f1867b0,
  @Name = @Name_6f1867b0,
  @DisplayName = @DisplayName_6f1867b0,
  @Description = @Description_6f1867b0,
  @Category = @Category_6f1867b0,
  @Category_Clear = 1,
  @Type = @Type_6f1867b0,
  @Length = @Length_6f1867b0,
  @Precision = @Precision_6f1867b0,
  @Precision_Clear = 1,
  @Scale = @Scale_6f1867b0,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_6f1867b0,
  @DefaultValue = @DefaultValue_6f1867b0,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_6f1867b0,
  @IsUniqueKey = @IsUniqueKey_6f1867b0,
  @IsReadOnly = @IsReadOnly_6f1867b0,
  @IsRequired = @IsRequired_6f1867b0,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_6f1867b0,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_6f1867b0,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_6f1867b0,
  @Configuration = @Configuration_6f1867b0,
  @Configuration_Clear = 1,
  @Status = @Status_6f1867b0,
  @IsCustom = @IsCustom_6f1867b0,
  @MetadataSource = @MetadataSource_6f1867b0;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_200f90fb UNIQUEIDENTIFIER,
@IntegrationObjectID_200f90fb UNIQUEIDENTIFIER,
@Name_200f90fb NVARCHAR(255),
@DisplayName_200f90fb NVARCHAR(255),
@Description_200f90fb NVARCHAR(MAX),
@Category_200f90fb NVARCHAR(100),
@Type_200f90fb NVARCHAR(100),
@Length_200f90fb INT,
@Precision_200f90fb INT,
@Scale_200f90fb INT,
@AllowsNull_200f90fb BIT,
@DefaultValue_200f90fb NVARCHAR(255),
@IsPrimaryKey_200f90fb BIT,
@IsUniqueKey_200f90fb BIT,
@IsReadOnly_200f90fb BIT,
@IsRequired_200f90fb BIT,
@RelatedIntegrationObjectID_200f90fb UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_200f90fb NVARCHAR(255),
@Sequence_200f90fb INT,
@Configuration_200f90fb NVARCHAR(MAX),
@Status_200f90fb NVARCHAR(25),
@IsCustom_200f90fb BIT,
@MetadataSource_200f90fb NVARCHAR(20)
SET
  @ID_200f90fb = '7D58D030-EE2F-5C1B-B03B-778BF49BA030'
SET
  @IntegrationObjectID_200f90fb = '5DD9CF05-1571-454E-BA40-D65E6B9C2131'
SET
  @Name_200f90fb = N'organization-city'
SET
  @DisplayName_200f90fb = N'Organization City'
SET
  @Description_200f90fb = N'City of the organization. Lifted from organization.address.city.'
SET
  @Type_200f90fb = N'String'
SET
  @Length_200f90fb = 255
SET
  @AllowsNull_200f90fb = 1
SET
  @IsPrimaryKey_200f90fb = 0
SET
  @IsUniqueKey_200f90fb = 0
SET
  @IsReadOnly_200f90fb = 1
SET
  @IsRequired_200f90fb = 0
SET
  @Sequence_200f90fb = 22
SET
  @Status_200f90fb = N'Active'
SET
  @IsCustom_200f90fb = 0
SET
  @MetadataSource_200f90fb = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_200f90fb,
  @IntegrationObjectID = @IntegrationObjectID_200f90fb,
  @Name = @Name_200f90fb,
  @DisplayName = @DisplayName_200f90fb,
  @Description = @Description_200f90fb,
  @Category = @Category_200f90fb,
  @Category_Clear = 1,
  @Type = @Type_200f90fb,
  @Length = @Length_200f90fb,
  @Precision = @Precision_200f90fb,
  @Precision_Clear = 1,
  @Scale = @Scale_200f90fb,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_200f90fb,
  @DefaultValue = @DefaultValue_200f90fb,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_200f90fb,
  @IsUniqueKey = @IsUniqueKey_200f90fb,
  @IsReadOnly = @IsReadOnly_200f90fb,
  @IsRequired = @IsRequired_200f90fb,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_200f90fb,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_200f90fb,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_200f90fb,
  @Configuration = @Configuration_200f90fb,
  @Configuration_Clear = 1,
  @Status = @Status_200f90fb,
  @IsCustom = @IsCustom_200f90fb,
  @MetadataSource = @MetadataSource_200f90fb;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_31082ea3 UNIQUEIDENTIFIER,
@IntegrationObjectID_31082ea3 UNIQUEIDENTIFIER,
@Name_31082ea3 NVARCHAR(255),
@DisplayName_31082ea3 NVARCHAR(255),
@Description_31082ea3 NVARCHAR(MAX),
@Category_31082ea3 NVARCHAR(100),
@Type_31082ea3 NVARCHAR(100),
@Length_31082ea3 INT,
@Precision_31082ea3 INT,
@Scale_31082ea3 INT,
@AllowsNull_31082ea3 BIT,
@DefaultValue_31082ea3 NVARCHAR(255),
@IsPrimaryKey_31082ea3 BIT,
@IsUniqueKey_31082ea3 BIT,
@IsReadOnly_31082ea3 BIT,
@IsRequired_31082ea3 BIT,
@RelatedIntegrationObjectID_31082ea3 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_31082ea3 NVARCHAR(255),
@Sequence_31082ea3 INT,
@Configuration_31082ea3 NVARCHAR(MAX),
@Status_31082ea3 NVARCHAR(25),
@IsCustom_31082ea3 BIT,
@MetadataSource_31082ea3 NVARCHAR(20)
SET
  @ID_31082ea3 = 'AE844B1B-9F7B-5103-A52F-64B2B4653F49'
SET
  @IntegrationObjectID_31082ea3 = '5DD9CF05-1571-454E-BA40-D65E6B9C2131'
SET
  @Name_31082ea3 = N'organization-region'
SET
  @DisplayName_31082ea3 = N'Organization Region'
SET
  @Description_31082ea3 = N'Region/state of the organization. Lifted from organization.address.region.'
SET
  @Type_31082ea3 = N'String'
SET
  @Length_31082ea3 = 255
SET
  @AllowsNull_31082ea3 = 1
SET
  @IsPrimaryKey_31082ea3 = 0
SET
  @IsUniqueKey_31082ea3 = 0
SET
  @IsReadOnly_31082ea3 = 1
SET
  @IsRequired_31082ea3 = 0
SET
  @Sequence_31082ea3 = 23
SET
  @Status_31082ea3 = N'Active'
SET
  @IsCustom_31082ea3 = 0
SET
  @MetadataSource_31082ea3 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_31082ea3,
  @IntegrationObjectID = @IntegrationObjectID_31082ea3,
  @Name = @Name_31082ea3,
  @DisplayName = @DisplayName_31082ea3,
  @Description = @Description_31082ea3,
  @Category = @Category_31082ea3,
  @Category_Clear = 1,
  @Type = @Type_31082ea3,
  @Length = @Length_31082ea3,
  @Precision = @Precision_31082ea3,
  @Precision_Clear = 1,
  @Scale = @Scale_31082ea3,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_31082ea3,
  @DefaultValue = @DefaultValue_31082ea3,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_31082ea3,
  @IsUniqueKey = @IsUniqueKey_31082ea3,
  @IsReadOnly = @IsReadOnly_31082ea3,
  @IsRequired = @IsRequired_31082ea3,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_31082ea3,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_31082ea3,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_31082ea3,
  @Configuration = @Configuration_31082ea3,
  @Configuration_Clear = 1,
  @Status = @Status_31082ea3,
  @IsCustom = @IsCustom_31082ea3,
  @MetadataSource = @MetadataSource_31082ea3;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_6a6e7be2 UNIQUEIDENTIFIER,
@IntegrationObjectID_6a6e7be2 UNIQUEIDENTIFIER,
@Name_6a6e7be2 NVARCHAR(255),
@DisplayName_6a6e7be2 NVARCHAR(255),
@Description_6a6e7be2 NVARCHAR(MAX),
@Category_6a6e7be2 NVARCHAR(100),
@Type_6a6e7be2 NVARCHAR(100),
@Length_6a6e7be2 INT,
@Precision_6a6e7be2 INT,
@Scale_6a6e7be2 INT,
@AllowsNull_6a6e7be2 BIT,
@DefaultValue_6a6e7be2 NVARCHAR(255),
@IsPrimaryKey_6a6e7be2 BIT,
@IsUniqueKey_6a6e7be2 BIT,
@IsReadOnly_6a6e7be2 BIT,
@IsRequired_6a6e7be2 BIT,
@RelatedIntegrationObjectID_6a6e7be2 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_6a6e7be2 NVARCHAR(255),
@Sequence_6a6e7be2 INT,
@Configuration_6a6e7be2 NVARCHAR(MAX),
@Status_6a6e7be2 NVARCHAR(25),
@IsCustom_6a6e7be2 BIT,
@MetadataSource_6a6e7be2 NVARCHAR(20)
SET
  @ID_6a6e7be2 = 'DD2F4D8E-AE98-56E8-9475-DDC1B34CE279'
SET
  @IntegrationObjectID_6a6e7be2 = '5DD9CF05-1571-454E-BA40-D65E6B9C2131'
SET
  @Name_6a6e7be2 = N'organization-country'
SET
  @DisplayName_6a6e7be2 = N'Organization Country'
SET
  @Description_6a6e7be2 = N'ISO country code of the organization. Lifted from organization.address.country.'
SET
  @Type_6a6e7be2 = N'String'
SET
  @Length_6a6e7be2 = 50
SET
  @AllowsNull_6a6e7be2 = 1
SET
  @IsPrimaryKey_6a6e7be2 = 0
SET
  @IsUniqueKey_6a6e7be2 = 0
SET
  @IsReadOnly_6a6e7be2 = 1
SET
  @IsRequired_6a6e7be2 = 0
SET
  @Sequence_6a6e7be2 = 24
SET
  @Status_6a6e7be2 = N'Active'
SET
  @IsCustom_6a6e7be2 = 0
SET
  @MetadataSource_6a6e7be2 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_6a6e7be2,
  @IntegrationObjectID = @IntegrationObjectID_6a6e7be2,
  @Name = @Name_6a6e7be2,
  @DisplayName = @DisplayName_6a6e7be2,
  @Description = @Description_6a6e7be2,
  @Category = @Category_6a6e7be2,
  @Category_Clear = 1,
  @Type = @Type_6a6e7be2,
  @Length = @Length_6a6e7be2,
  @Precision = @Precision_6a6e7be2,
  @Precision_Clear = 1,
  @Scale = @Scale_6a6e7be2,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_6a6e7be2,
  @DefaultValue = @DefaultValue_6a6e7be2,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_6a6e7be2,
  @IsUniqueKey = @IsUniqueKey_6a6e7be2,
  @IsReadOnly = @IsReadOnly_6a6e7be2,
  @IsRequired = @IsRequired_6a6e7be2,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_6a6e7be2,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_6a6e7be2,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_6a6e7be2,
  @Configuration = @Configuration_6a6e7be2,
  @Configuration_Clear = 1,
  @Status = @Status_6a6e7be2,
  @IsCustom = @IsCustom_6a6e7be2,
  @MetadataSource = @MetadataSource_6a6e7be2;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_b2c158fd UNIQUEIDENTIFIER,
@IntegrationObjectID_b2c158fd UNIQUEIDENTIFIER,
@Name_b2c158fd NVARCHAR(255),
@DisplayName_b2c158fd NVARCHAR(255),
@Description_b2c158fd NVARCHAR(MAX),
@Category_b2c158fd NVARCHAR(100),
@Type_b2c158fd NVARCHAR(100),
@Length_b2c158fd INT,
@Precision_b2c158fd INT,
@Scale_b2c158fd INT,
@AllowsNull_b2c158fd BIT,
@DefaultValue_b2c158fd NVARCHAR(255),
@IsPrimaryKey_b2c158fd BIT,
@IsUniqueKey_b2c158fd BIT,
@IsReadOnly_b2c158fd BIT,
@IsRequired_b2c158fd BIT,
@RelatedIntegrationObjectID_b2c158fd UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_b2c158fd NVARCHAR(255),
@Sequence_b2c158fd INT,
@Configuration_b2c158fd NVARCHAR(MAX),
@Status_b2c158fd NVARCHAR(25),
@IsCustom_b2c158fd BIT,
@MetadataSource_b2c158fd NVARCHAR(20)
SET
  @ID_b2c158fd = '7310CFC9-9020-5C81-BA07-288C05F176F7'
SET
  @IntegrationObjectID_b2c158fd = '5DD9CF05-1571-454E-BA40-D65E6B9C2131'
SET
  @Name_b2c158fd = N'organization-disambiguated-id'
SET
  @DisplayName_b2c158fd = N'Organization Disambiguated Id'
SET
  @Description_b2c158fd = N'Canonical identifier of the organization in the disambiguation source (e.g. a RINGGOLD or ROR id), so the same institution matches across records.'
SET
  @Type_b2c158fd = N'String'
SET
  @Length_b2c158fd = 255
SET
  @AllowsNull_b2c158fd = 1
SET
  @IsPrimaryKey_b2c158fd = 0
SET
  @IsUniqueKey_b2c158fd = 0
SET
  @IsReadOnly_b2c158fd = 1
SET
  @IsRequired_b2c158fd = 0
SET
  @Sequence_b2c158fd = 25
SET
  @Status_b2c158fd = N'Active'
SET
  @IsCustom_b2c158fd = 0
SET
  @MetadataSource_b2c158fd = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_b2c158fd,
  @IntegrationObjectID = @IntegrationObjectID_b2c158fd,
  @Name = @Name_b2c158fd,
  @DisplayName = @DisplayName_b2c158fd,
  @Description = @Description_b2c158fd,
  @Category = @Category_b2c158fd,
  @Category_Clear = 1,
  @Type = @Type_b2c158fd,
  @Length = @Length_b2c158fd,
  @Precision = @Precision_b2c158fd,
  @Precision_Clear = 1,
  @Scale = @Scale_b2c158fd,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_b2c158fd,
  @DefaultValue = @DefaultValue_b2c158fd,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_b2c158fd,
  @IsUniqueKey = @IsUniqueKey_b2c158fd,
  @IsReadOnly = @IsReadOnly_b2c158fd,
  @IsRequired = @IsRequired_b2c158fd,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_b2c158fd,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_b2c158fd,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_b2c158fd,
  @Configuration = @Configuration_b2c158fd,
  @Configuration_Clear = 1,
  @Status = @Status_b2c158fd,
  @IsCustom = @IsCustom_b2c158fd,
  @MetadataSource = @MetadataSource_b2c158fd;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_5570b8df UNIQUEIDENTIFIER,
@IntegrationObjectID_5570b8df UNIQUEIDENTIFIER,
@Name_5570b8df NVARCHAR(255),
@DisplayName_5570b8df NVARCHAR(255),
@Description_5570b8df NVARCHAR(MAX),
@Category_5570b8df NVARCHAR(100),
@Type_5570b8df NVARCHAR(100),
@Length_5570b8df INT,
@Precision_5570b8df INT,
@Scale_5570b8df INT,
@AllowsNull_5570b8df BIT,
@DefaultValue_5570b8df NVARCHAR(255),
@IsPrimaryKey_5570b8df BIT,
@IsUniqueKey_5570b8df BIT,
@IsReadOnly_5570b8df BIT,
@IsRequired_5570b8df BIT,
@RelatedIntegrationObjectID_5570b8df UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_5570b8df NVARCHAR(255),
@Sequence_5570b8df INT,
@Configuration_5570b8df NVARCHAR(MAX),
@Status_5570b8df NVARCHAR(25),
@IsCustom_5570b8df BIT,
@MetadataSource_5570b8df NVARCHAR(20)
SET
  @ID_5570b8df = '51F8A1B7-147D-5AC2-A164-BC1DB4BD30F8'
SET
  @IntegrationObjectID_5570b8df = '5DD9CF05-1571-454E-BA40-D65E6B9C2131'
SET
  @Name_5570b8df = N'organization-disambiguation-source'
SET
  @DisplayName_5570b8df = N'Organization Disambiguation Source'
SET
  @Description_5570b8df = N'Registry the disambiguated id comes from (RINGGOLD, ROR, FUNDREF, GRID, LEI).'
SET
  @Type_5570b8df = N'String'
SET
  @Length_5570b8df = 100
SET
  @AllowsNull_5570b8df = 1
SET
  @IsPrimaryKey_5570b8df = 0
SET
  @IsUniqueKey_5570b8df = 0
SET
  @IsReadOnly_5570b8df = 1
SET
  @IsRequired_5570b8df = 0
SET
  @Sequence_5570b8df = 26
SET
  @Status_5570b8df = N'Active'
SET
  @IsCustom_5570b8df = 0
SET
  @MetadataSource_5570b8df = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_5570b8df,
  @IntegrationObjectID = @IntegrationObjectID_5570b8df,
  @Name = @Name_5570b8df,
  @DisplayName = @DisplayName_5570b8df,
  @Description = @Description_5570b8df,
  @Category = @Category_5570b8df,
  @Category_Clear = 1,
  @Type = @Type_5570b8df,
  @Length = @Length_5570b8df,
  @Precision = @Precision_5570b8df,
  @Precision_Clear = 1,
  @Scale = @Scale_5570b8df,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_5570b8df,
  @DefaultValue = @DefaultValue_5570b8df,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_5570b8df,
  @IsUniqueKey = @IsUniqueKey_5570b8df,
  @IsReadOnly = @IsReadOnly_5570b8df,
  @IsRequired = @IsRequired_5570b8df,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_5570b8df,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_5570b8df,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_5570b8df,
  @Configuration = @Configuration_5570b8df,
  @Configuration_Clear = 1,
  @Status = @Status_5570b8df,
  @IsCustom = @IsCustom_5570b8df,
  @MetadataSource = @MetadataSource_5570b8df;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_896ed3d8 UNIQUEIDENTIFIER,
@IntegrationObjectID_896ed3d8 UNIQUEIDENTIFIER,
@Name_896ed3d8 NVARCHAR(255),
@DisplayName_896ed3d8 NVARCHAR(255),
@Description_896ed3d8 NVARCHAR(MAX),
@Category_896ed3d8 NVARCHAR(100),
@Type_896ed3d8 NVARCHAR(100),
@Length_896ed3d8 INT,
@Precision_896ed3d8 INT,
@Scale_896ed3d8 INT,
@AllowsNull_896ed3d8 BIT,
@DefaultValue_896ed3d8 NVARCHAR(255),
@IsPrimaryKey_896ed3d8 BIT,
@IsUniqueKey_896ed3d8 BIT,
@IsReadOnly_896ed3d8 BIT,
@IsRequired_896ed3d8 BIT,
@RelatedIntegrationObjectID_896ed3d8 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_896ed3d8 NVARCHAR(255),
@Sequence_896ed3d8 INT,
@Configuration_896ed3d8 NVARCHAR(MAX),
@Status_896ed3d8 NVARCHAR(25),
@IsCustom_896ed3d8 BIT,
@MetadataSource_896ed3d8 NVARCHAR(20)
SET
  @ID_896ed3d8 = '114B670D-8D6B-5BB6-BED6-EA991C5F2DA4'
SET
  @IntegrationObjectID_896ed3d8 = '5DD9CF05-1571-454E-BA40-D65E6B9C2131'
SET
  @Name_896ed3d8 = N'source-name'
SET
  @DisplayName_896ed3d8 = N'Source Name'
SET
  @Description_896ed3d8 = N'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.'
SET
  @Type_896ed3d8 = N'String'
SET
  @Length_896ed3d8 = 500
SET
  @AllowsNull_896ed3d8 = 1
SET
  @IsPrimaryKey_896ed3d8 = 0
SET
  @IsUniqueKey_896ed3d8 = 0
SET
  @IsReadOnly_896ed3d8 = 1
SET
  @IsRequired_896ed3d8 = 0
SET
  @Sequence_896ed3d8 = 27
SET
  @Status_896ed3d8 = N'Active'
SET
  @IsCustom_896ed3d8 = 0
SET
  @MetadataSource_896ed3d8 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_896ed3d8,
  @IntegrationObjectID = @IntegrationObjectID_896ed3d8,
  @Name = @Name_896ed3d8,
  @DisplayName = @DisplayName_896ed3d8,
  @Description = @Description_896ed3d8,
  @Category = @Category_896ed3d8,
  @Category_Clear = 1,
  @Type = @Type_896ed3d8,
  @Length = @Length_896ed3d8,
  @Precision = @Precision_896ed3d8,
  @Precision_Clear = 1,
  @Scale = @Scale_896ed3d8,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_896ed3d8,
  @DefaultValue = @DefaultValue_896ed3d8,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_896ed3d8,
  @IsUniqueKey = @IsUniqueKey_896ed3d8,
  @IsReadOnly = @IsReadOnly_896ed3d8,
  @IsRequired = @IsRequired_896ed3d8,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_896ed3d8,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_896ed3d8,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_896ed3d8,
  @Configuration = @Configuration_896ed3d8,
  @Configuration_Clear = 1,
  @Status = @Status_896ed3d8,
  @IsCustom = @IsCustom_896ed3d8,
  @MetadataSource = @MetadataSource_896ed3d8;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_4e31f852 UNIQUEIDENTIFIER,
@IntegrationObjectID_4e31f852 UNIQUEIDENTIFIER,
@Name_4e31f852 NVARCHAR(255),
@DisplayName_4e31f852 NVARCHAR(255),
@Description_4e31f852 NVARCHAR(MAX),
@Category_4e31f852 NVARCHAR(100),
@Type_4e31f852 NVARCHAR(100),
@Length_4e31f852 INT,
@Precision_4e31f852 INT,
@Scale_4e31f852 INT,
@AllowsNull_4e31f852 BIT,
@DefaultValue_4e31f852 NVARCHAR(255),
@IsPrimaryKey_4e31f852 BIT,
@IsUniqueKey_4e31f852 BIT,
@IsReadOnly_4e31f852 BIT,
@IsRequired_4e31f852 BIT,
@RelatedIntegrationObjectID_4e31f852 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_4e31f852 NVARCHAR(255),
@Sequence_4e31f852 INT,
@Configuration_4e31f852 NVARCHAR(MAX),
@Status_4e31f852 NVARCHAR(25),
@IsCustom_4e31f852 BIT,
@MetadataSource_4e31f852 NVARCHAR(20)
SET
  @ID_4e31f852 = 'DEC2BB95-DEFB-578F-820B-E55D7EF8FD2C'
SET
  @IntegrationObjectID_4e31f852 = '5DD9CF05-1571-454E-BA40-D65E6B9C2131'
SET
  @Name_4e31f852 = N'source-orcid'
SET
  @DisplayName_4e31f852 = N'Source Orcid'
SET
  @Description_4e31f852 = N'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.'
SET
  @Type_4e31f852 = N'String'
SET
  @Length_4e31f852 = 19
SET
  @AllowsNull_4e31f852 = 1
SET
  @IsPrimaryKey_4e31f852 = 0
SET
  @IsUniqueKey_4e31f852 = 0
SET
  @IsReadOnly_4e31f852 = 1
SET
  @IsRequired_4e31f852 = 0
SET
  @Sequence_4e31f852 = 28
SET
  @Status_4e31f852 = N'Active'
SET
  @IsCustom_4e31f852 = 0
SET
  @MetadataSource_4e31f852 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_4e31f852,
  @IntegrationObjectID = @IntegrationObjectID_4e31f852,
  @Name = @Name_4e31f852,
  @DisplayName = @DisplayName_4e31f852,
  @Description = @Description_4e31f852,
  @Category = @Category_4e31f852,
  @Category_Clear = 1,
  @Type = @Type_4e31f852,
  @Length = @Length_4e31f852,
  @Precision = @Precision_4e31f852,
  @Precision_Clear = 1,
  @Scale = @Scale_4e31f852,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_4e31f852,
  @DefaultValue = @DefaultValue_4e31f852,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_4e31f852,
  @IsUniqueKey = @IsUniqueKey_4e31f852,
  @IsReadOnly = @IsReadOnly_4e31f852,
  @IsRequired = @IsRequired_4e31f852,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_4e31f852,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_4e31f852,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_4e31f852,
  @Configuration = @Configuration_4e31f852,
  @Configuration_Clear = 1,
  @Status = @Status_4e31f852,
  @IsCustom = @IsCustom_4e31f852,
  @MetadataSource = @MetadataSource_4e31f852;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_39bca174 UNIQUEIDENTIFIER,
@IntegrationObjectID_39bca174 UNIQUEIDENTIFIER,
@Name_39bca174 NVARCHAR(255),
@DisplayName_39bca174 NVARCHAR(255),
@Description_39bca174 NVARCHAR(MAX),
@Category_39bca174 NVARCHAR(100),
@Type_39bca174 NVARCHAR(100),
@Length_39bca174 INT,
@Precision_39bca174 INT,
@Scale_39bca174 INT,
@AllowsNull_39bca174 BIT,
@DefaultValue_39bca174 NVARCHAR(255),
@IsPrimaryKey_39bca174 BIT,
@IsUniqueKey_39bca174 BIT,
@IsReadOnly_39bca174 BIT,
@IsRequired_39bca174 BIT,
@RelatedIntegrationObjectID_39bca174 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_39bca174 NVARCHAR(255),
@Sequence_39bca174 INT,
@Configuration_39bca174 NVARCHAR(MAX),
@Status_39bca174 NVARCHAR(25),
@IsCustom_39bca174 BIT,
@MetadataSource_39bca174 NVARCHAR(20)
SET
  @ID_39bca174 = '7180D16D-66F8-510B-8807-AE5F55E553A9'
SET
  @IntegrationObjectID_39bca174 = 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05'
SET
  @Name_39bca174 = N'start-year'
SET
  @DisplayName_39bca174 = N'Start Year'
SET
  @Description_39bca174 = N'Year of the affiliation start date; ORCID dates are partial, so month/day may be absent.'
SET
  @Type_39bca174 = N'Integer'
SET
  @AllowsNull_39bca174 = 1
SET
  @IsPrimaryKey_39bca174 = 0
SET
  @IsUniqueKey_39bca174 = 0
SET
  @IsReadOnly_39bca174 = 1
SET
  @IsRequired_39bca174 = 0
SET
  @Sequence_39bca174 = 15
SET
  @Status_39bca174 = N'Active'
SET
  @IsCustom_39bca174 = 0
SET
  @MetadataSource_39bca174 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_39bca174,
  @IntegrationObjectID = @IntegrationObjectID_39bca174,
  @Name = @Name_39bca174,
  @DisplayName = @DisplayName_39bca174,
  @Description = @Description_39bca174,
  @Category = @Category_39bca174,
  @Category_Clear = 1,
  @Type = @Type_39bca174,
  @Length = @Length_39bca174,
  @Length_Clear = 1,
  @Precision = @Precision_39bca174,
  @Precision_Clear = 1,
  @Scale = @Scale_39bca174,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_39bca174,
  @DefaultValue = @DefaultValue_39bca174,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_39bca174,
  @IsUniqueKey = @IsUniqueKey_39bca174,
  @IsReadOnly = @IsReadOnly_39bca174,
  @IsRequired = @IsRequired_39bca174,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_39bca174,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_39bca174,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_39bca174,
  @Configuration = @Configuration_39bca174,
  @Configuration_Clear = 1,
  @Status = @Status_39bca174,
  @IsCustom = @IsCustom_39bca174,
  @MetadataSource = @MetadataSource_39bca174;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_7dee4a41 UNIQUEIDENTIFIER,
@IntegrationObjectID_7dee4a41 UNIQUEIDENTIFIER,
@Name_7dee4a41 NVARCHAR(255),
@DisplayName_7dee4a41 NVARCHAR(255),
@Description_7dee4a41 NVARCHAR(MAX),
@Category_7dee4a41 NVARCHAR(100),
@Type_7dee4a41 NVARCHAR(100),
@Length_7dee4a41 INT,
@Precision_7dee4a41 INT,
@Scale_7dee4a41 INT,
@AllowsNull_7dee4a41 BIT,
@DefaultValue_7dee4a41 NVARCHAR(255),
@IsPrimaryKey_7dee4a41 BIT,
@IsUniqueKey_7dee4a41 BIT,
@IsReadOnly_7dee4a41 BIT,
@IsRequired_7dee4a41 BIT,
@RelatedIntegrationObjectID_7dee4a41 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_7dee4a41 NVARCHAR(255),
@Sequence_7dee4a41 INT,
@Configuration_7dee4a41 NVARCHAR(MAX),
@Status_7dee4a41 NVARCHAR(25),
@IsCustom_7dee4a41 BIT,
@MetadataSource_7dee4a41 NVARCHAR(20)
SET
  @ID_7dee4a41 = 'B6F7E123-DFB9-5903-9375-26C5603A9ADB'
SET
  @IntegrationObjectID_7dee4a41 = 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05'
SET
  @Name_7dee4a41 = N'start-month'
SET
  @DisplayName_7dee4a41 = N'Start Month'
SET
  @Description_7dee4a41 = N'Month (1-12) of the affiliation start date, when given.'
SET
  @Type_7dee4a41 = N'Integer'
SET
  @AllowsNull_7dee4a41 = 1
SET
  @IsPrimaryKey_7dee4a41 = 0
SET
  @IsUniqueKey_7dee4a41 = 0
SET
  @IsReadOnly_7dee4a41 = 1
SET
  @IsRequired_7dee4a41 = 0
SET
  @Sequence_7dee4a41 = 16
SET
  @Status_7dee4a41 = N'Active'
SET
  @IsCustom_7dee4a41 = 0
SET
  @MetadataSource_7dee4a41 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_7dee4a41,
  @IntegrationObjectID = @IntegrationObjectID_7dee4a41,
  @Name = @Name_7dee4a41,
  @DisplayName = @DisplayName_7dee4a41,
  @Description = @Description_7dee4a41,
  @Category = @Category_7dee4a41,
  @Category_Clear = 1,
  @Type = @Type_7dee4a41,
  @Length = @Length_7dee4a41,
  @Length_Clear = 1,
  @Precision = @Precision_7dee4a41,
  @Precision_Clear = 1,
  @Scale = @Scale_7dee4a41,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_7dee4a41,
  @DefaultValue = @DefaultValue_7dee4a41,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_7dee4a41,
  @IsUniqueKey = @IsUniqueKey_7dee4a41,
  @IsReadOnly = @IsReadOnly_7dee4a41,
  @IsRequired = @IsRequired_7dee4a41,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_7dee4a41,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_7dee4a41,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_7dee4a41,
  @Configuration = @Configuration_7dee4a41,
  @Configuration_Clear = 1,
  @Status = @Status_7dee4a41,
  @IsCustom = @IsCustom_7dee4a41,
  @MetadataSource = @MetadataSource_7dee4a41;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_a652f960 UNIQUEIDENTIFIER,
@IntegrationObjectID_a652f960 UNIQUEIDENTIFIER,
@Name_a652f960 NVARCHAR(255),
@DisplayName_a652f960 NVARCHAR(255),
@Description_a652f960 NVARCHAR(MAX),
@Category_a652f960 NVARCHAR(100),
@Type_a652f960 NVARCHAR(100),
@Length_a652f960 INT,
@Precision_a652f960 INT,
@Scale_a652f960 INT,
@AllowsNull_a652f960 BIT,
@DefaultValue_a652f960 NVARCHAR(255),
@IsPrimaryKey_a652f960 BIT,
@IsUniqueKey_a652f960 BIT,
@IsReadOnly_a652f960 BIT,
@IsRequired_a652f960 BIT,
@RelatedIntegrationObjectID_a652f960 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_a652f960 NVARCHAR(255),
@Sequence_a652f960 INT,
@Configuration_a652f960 NVARCHAR(MAX),
@Status_a652f960 NVARCHAR(25),
@IsCustom_a652f960 BIT,
@MetadataSource_a652f960 NVARCHAR(20)
SET
  @ID_a652f960 = '393CDB89-18CB-593E-BC9F-9F493F2A35F5'
SET
  @IntegrationObjectID_a652f960 = 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05'
SET
  @Name_a652f960 = N'start-day'
SET
  @DisplayName_a652f960 = N'Start Day'
SET
  @Description_a652f960 = N'Day of month of the affiliation start date, when given.'
SET
  @Type_a652f960 = N'Integer'
SET
  @AllowsNull_a652f960 = 1
SET
  @IsPrimaryKey_a652f960 = 0
SET
  @IsUniqueKey_a652f960 = 0
SET
  @IsReadOnly_a652f960 = 1
SET
  @IsRequired_a652f960 = 0
SET
  @Sequence_a652f960 = 17
SET
  @Status_a652f960 = N'Active'
SET
  @IsCustom_a652f960 = 0
SET
  @MetadataSource_a652f960 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_a652f960,
  @IntegrationObjectID = @IntegrationObjectID_a652f960,
  @Name = @Name_a652f960,
  @DisplayName = @DisplayName_a652f960,
  @Description = @Description_a652f960,
  @Category = @Category_a652f960,
  @Category_Clear = 1,
  @Type = @Type_a652f960,
  @Length = @Length_a652f960,
  @Length_Clear = 1,
  @Precision = @Precision_a652f960,
  @Precision_Clear = 1,
  @Scale = @Scale_a652f960,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_a652f960,
  @DefaultValue = @DefaultValue_a652f960,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_a652f960,
  @IsUniqueKey = @IsUniqueKey_a652f960,
  @IsReadOnly = @IsReadOnly_a652f960,
  @IsRequired = @IsRequired_a652f960,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_a652f960,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_a652f960,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_a652f960,
  @Configuration = @Configuration_a652f960,
  @Configuration_Clear = 1,
  @Status = @Status_a652f960,
  @IsCustom = @IsCustom_a652f960,
  @MetadataSource = @MetadataSource_a652f960;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_39dec340 UNIQUEIDENTIFIER,
@IntegrationObjectID_39dec340 UNIQUEIDENTIFIER,
@Name_39dec340 NVARCHAR(255),
@DisplayName_39dec340 NVARCHAR(255),
@Description_39dec340 NVARCHAR(MAX),
@Category_39dec340 NVARCHAR(100),
@Type_39dec340 NVARCHAR(100),
@Length_39dec340 INT,
@Precision_39dec340 INT,
@Scale_39dec340 INT,
@AllowsNull_39dec340 BIT,
@DefaultValue_39dec340 NVARCHAR(255),
@IsPrimaryKey_39dec340 BIT,
@IsUniqueKey_39dec340 BIT,
@IsReadOnly_39dec340 BIT,
@IsRequired_39dec340 BIT,
@RelatedIntegrationObjectID_39dec340 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_39dec340 NVARCHAR(255),
@Sequence_39dec340 INT,
@Configuration_39dec340 NVARCHAR(MAX),
@Status_39dec340 NVARCHAR(25),
@IsCustom_39dec340 BIT,
@MetadataSource_39dec340 NVARCHAR(20)
SET
  @ID_39dec340 = 'AC91F183-E78B-5733-8FF8-C3AA039FE01C'
SET
  @IntegrationObjectID_39dec340 = 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05'
SET
  @Name_39dec340 = N'end-year'
SET
  @DisplayName_39dec340 = N'End Year'
SET
  @Description_39dec340 = N'Year of the affiliation end date; empty for a current/ongoing role; ORCID dates are partial, so month/day may be absent.'
SET
  @Type_39dec340 = N'Integer'
SET
  @AllowsNull_39dec340 = 1
SET
  @IsPrimaryKey_39dec340 = 0
SET
  @IsUniqueKey_39dec340 = 0
SET
  @IsReadOnly_39dec340 = 1
SET
  @IsRequired_39dec340 = 0
SET
  @Sequence_39dec340 = 18
SET
  @Status_39dec340 = N'Active'
SET
  @IsCustom_39dec340 = 0
SET
  @MetadataSource_39dec340 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_39dec340,
  @IntegrationObjectID = @IntegrationObjectID_39dec340,
  @Name = @Name_39dec340,
  @DisplayName = @DisplayName_39dec340,
  @Description = @Description_39dec340,
  @Category = @Category_39dec340,
  @Category_Clear = 1,
  @Type = @Type_39dec340,
  @Length = @Length_39dec340,
  @Length_Clear = 1,
  @Precision = @Precision_39dec340,
  @Precision_Clear = 1,
  @Scale = @Scale_39dec340,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_39dec340,
  @DefaultValue = @DefaultValue_39dec340,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_39dec340,
  @IsUniqueKey = @IsUniqueKey_39dec340,
  @IsReadOnly = @IsReadOnly_39dec340,
  @IsRequired = @IsRequired_39dec340,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_39dec340,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_39dec340,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_39dec340,
  @Configuration = @Configuration_39dec340,
  @Configuration_Clear = 1,
  @Status = @Status_39dec340,
  @IsCustom = @IsCustom_39dec340,
  @MetadataSource = @MetadataSource_39dec340;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_821b0509 UNIQUEIDENTIFIER,
@IntegrationObjectID_821b0509 UNIQUEIDENTIFIER,
@Name_821b0509 NVARCHAR(255),
@DisplayName_821b0509 NVARCHAR(255),
@Description_821b0509 NVARCHAR(MAX),
@Category_821b0509 NVARCHAR(100),
@Type_821b0509 NVARCHAR(100),
@Length_821b0509 INT,
@Precision_821b0509 INT,
@Scale_821b0509 INT,
@AllowsNull_821b0509 BIT,
@DefaultValue_821b0509 NVARCHAR(255),
@IsPrimaryKey_821b0509 BIT,
@IsUniqueKey_821b0509 BIT,
@IsReadOnly_821b0509 BIT,
@IsRequired_821b0509 BIT,
@RelatedIntegrationObjectID_821b0509 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_821b0509 NVARCHAR(255),
@Sequence_821b0509 INT,
@Configuration_821b0509 NVARCHAR(MAX),
@Status_821b0509 NVARCHAR(25),
@IsCustom_821b0509 BIT,
@MetadataSource_821b0509 NVARCHAR(20)
SET
  @ID_821b0509 = '1C624B62-5275-516D-A89D-CF11D5C7630D'
SET
  @IntegrationObjectID_821b0509 = 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05'
SET
  @Name_821b0509 = N'end-month'
SET
  @DisplayName_821b0509 = N'End Month'
SET
  @Description_821b0509 = N'Month (1-12) of the affiliation end date; empty for a current/ongoing role, when given.'
SET
  @Type_821b0509 = N'Integer'
SET
  @AllowsNull_821b0509 = 1
SET
  @IsPrimaryKey_821b0509 = 0
SET
  @IsUniqueKey_821b0509 = 0
SET
  @IsReadOnly_821b0509 = 1
SET
  @IsRequired_821b0509 = 0
SET
  @Sequence_821b0509 = 19
SET
  @Status_821b0509 = N'Active'
SET
  @IsCustom_821b0509 = 0
SET
  @MetadataSource_821b0509 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_821b0509,
  @IntegrationObjectID = @IntegrationObjectID_821b0509,
  @Name = @Name_821b0509,
  @DisplayName = @DisplayName_821b0509,
  @Description = @Description_821b0509,
  @Category = @Category_821b0509,
  @Category_Clear = 1,
  @Type = @Type_821b0509,
  @Length = @Length_821b0509,
  @Length_Clear = 1,
  @Precision = @Precision_821b0509,
  @Precision_Clear = 1,
  @Scale = @Scale_821b0509,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_821b0509,
  @DefaultValue = @DefaultValue_821b0509,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_821b0509,
  @IsUniqueKey = @IsUniqueKey_821b0509,
  @IsReadOnly = @IsReadOnly_821b0509,
  @IsRequired = @IsRequired_821b0509,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_821b0509,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_821b0509,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_821b0509,
  @Configuration = @Configuration_821b0509,
  @Configuration_Clear = 1,
  @Status = @Status_821b0509,
  @IsCustom = @IsCustom_821b0509,
  @MetadataSource = @MetadataSource_821b0509;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_55c03965 UNIQUEIDENTIFIER,
@IntegrationObjectID_55c03965 UNIQUEIDENTIFIER,
@Name_55c03965 NVARCHAR(255),
@DisplayName_55c03965 NVARCHAR(255),
@Description_55c03965 NVARCHAR(MAX),
@Category_55c03965 NVARCHAR(100),
@Type_55c03965 NVARCHAR(100),
@Length_55c03965 INT,
@Precision_55c03965 INT,
@Scale_55c03965 INT,
@AllowsNull_55c03965 BIT,
@DefaultValue_55c03965 NVARCHAR(255),
@IsPrimaryKey_55c03965 BIT,
@IsUniqueKey_55c03965 BIT,
@IsReadOnly_55c03965 BIT,
@IsRequired_55c03965 BIT,
@RelatedIntegrationObjectID_55c03965 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_55c03965 NVARCHAR(255),
@Sequence_55c03965 INT,
@Configuration_55c03965 NVARCHAR(MAX),
@Status_55c03965 NVARCHAR(25),
@IsCustom_55c03965 BIT,
@MetadataSource_55c03965 NVARCHAR(20)
SET
  @ID_55c03965 = '6E02E532-688C-5A06-A7E3-A1C563F324FE'
SET
  @IntegrationObjectID_55c03965 = 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05'
SET
  @Name_55c03965 = N'end-day'
SET
  @DisplayName_55c03965 = N'End Day'
SET
  @Description_55c03965 = N'Day of month of the affiliation end date; empty for a current/ongoing role, when given.'
SET
  @Type_55c03965 = N'Integer'
SET
  @AllowsNull_55c03965 = 1
SET
  @IsPrimaryKey_55c03965 = 0
SET
  @IsUniqueKey_55c03965 = 0
SET
  @IsReadOnly_55c03965 = 1
SET
  @IsRequired_55c03965 = 0
SET
  @Sequence_55c03965 = 20
SET
  @Status_55c03965 = N'Active'
SET
  @IsCustom_55c03965 = 0
SET
  @MetadataSource_55c03965 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_55c03965,
  @IntegrationObjectID = @IntegrationObjectID_55c03965,
  @Name = @Name_55c03965,
  @DisplayName = @DisplayName_55c03965,
  @Description = @Description_55c03965,
  @Category = @Category_55c03965,
  @Category_Clear = 1,
  @Type = @Type_55c03965,
  @Length = @Length_55c03965,
  @Length_Clear = 1,
  @Precision = @Precision_55c03965,
  @Precision_Clear = 1,
  @Scale = @Scale_55c03965,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_55c03965,
  @DefaultValue = @DefaultValue_55c03965,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_55c03965,
  @IsUniqueKey = @IsUniqueKey_55c03965,
  @IsReadOnly = @IsReadOnly_55c03965,
  @IsRequired = @IsRequired_55c03965,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_55c03965,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_55c03965,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_55c03965,
  @Configuration = @Configuration_55c03965,
  @Configuration_Clear = 1,
  @Status = @Status_55c03965,
  @IsCustom = @IsCustom_55c03965,
  @MetadataSource = @MetadataSource_55c03965;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_d106c948 UNIQUEIDENTIFIER,
@IntegrationObjectID_d106c948 UNIQUEIDENTIFIER,
@Name_d106c948 NVARCHAR(255),
@DisplayName_d106c948 NVARCHAR(255),
@Description_d106c948 NVARCHAR(MAX),
@Category_d106c948 NVARCHAR(100),
@Type_d106c948 NVARCHAR(100),
@Length_d106c948 INT,
@Precision_d106c948 INT,
@Scale_d106c948 INT,
@AllowsNull_d106c948 BIT,
@DefaultValue_d106c948 NVARCHAR(255),
@IsPrimaryKey_d106c948 BIT,
@IsUniqueKey_d106c948 BIT,
@IsReadOnly_d106c948 BIT,
@IsRequired_d106c948 BIT,
@RelatedIntegrationObjectID_d106c948 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_d106c948 NVARCHAR(255),
@Sequence_d106c948 INT,
@Configuration_d106c948 NVARCHAR(MAX),
@Status_d106c948 NVARCHAR(25),
@IsCustom_d106c948 BIT,
@MetadataSource_d106c948 NVARCHAR(20)
SET
  @ID_d106c948 = '4BEE4CD2-5BA2-5642-BB38-FBB111001EA8'
SET
  @IntegrationObjectID_d106c948 = 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05'
SET
  @Name_d106c948 = N'organization-name'
SET
  @DisplayName_d106c948 = N'Organization Name'
SET
  @Description_d106c948 = N'Name of the organization. Lifted from organization.name.'
SET
  @Type_d106c948 = N'String'
SET
  @Length_d106c948 = 1000
SET
  @AllowsNull_d106c948 = 1
SET
  @IsPrimaryKey_d106c948 = 0
SET
  @IsUniqueKey_d106c948 = 0
SET
  @IsReadOnly_d106c948 = 1
SET
  @IsRequired_d106c948 = 0
SET
  @Sequence_d106c948 = 21
SET
  @Status_d106c948 = N'Active'
SET
  @IsCustom_d106c948 = 0
SET
  @MetadataSource_d106c948 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_d106c948,
  @IntegrationObjectID = @IntegrationObjectID_d106c948,
  @Name = @Name_d106c948,
  @DisplayName = @DisplayName_d106c948,
  @Description = @Description_d106c948,
  @Category = @Category_d106c948,
  @Category_Clear = 1,
  @Type = @Type_d106c948,
  @Length = @Length_d106c948,
  @Precision = @Precision_d106c948,
  @Precision_Clear = 1,
  @Scale = @Scale_d106c948,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_d106c948,
  @DefaultValue = @DefaultValue_d106c948,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_d106c948,
  @IsUniqueKey = @IsUniqueKey_d106c948,
  @IsReadOnly = @IsReadOnly_d106c948,
  @IsRequired = @IsRequired_d106c948,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_d106c948,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_d106c948,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_d106c948,
  @Configuration = @Configuration_d106c948,
  @Configuration_Clear = 1,
  @Status = @Status_d106c948,
  @IsCustom = @IsCustom_d106c948,
  @MetadataSource = @MetadataSource_d106c948;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_97c55941 UNIQUEIDENTIFIER,
@IntegrationObjectID_97c55941 UNIQUEIDENTIFIER,
@Name_97c55941 NVARCHAR(255),
@DisplayName_97c55941 NVARCHAR(255),
@Description_97c55941 NVARCHAR(MAX),
@Category_97c55941 NVARCHAR(100),
@Type_97c55941 NVARCHAR(100),
@Length_97c55941 INT,
@Precision_97c55941 INT,
@Scale_97c55941 INT,
@AllowsNull_97c55941 BIT,
@DefaultValue_97c55941 NVARCHAR(255),
@IsPrimaryKey_97c55941 BIT,
@IsUniqueKey_97c55941 BIT,
@IsReadOnly_97c55941 BIT,
@IsRequired_97c55941 BIT,
@RelatedIntegrationObjectID_97c55941 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_97c55941 NVARCHAR(255),
@Sequence_97c55941 INT,
@Configuration_97c55941 NVARCHAR(MAX),
@Status_97c55941 NVARCHAR(25),
@IsCustom_97c55941 BIT,
@MetadataSource_97c55941 NVARCHAR(20)
SET
  @ID_97c55941 = '33FCD70A-FB16-5B95-B166-82717FBF15AA'
SET
  @IntegrationObjectID_97c55941 = 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05'
SET
  @Name_97c55941 = N'organization-city'
SET
  @DisplayName_97c55941 = N'Organization City'
SET
  @Description_97c55941 = N'City of the organization. Lifted from organization.address.city.'
SET
  @Type_97c55941 = N'String'
SET
  @Length_97c55941 = 255
SET
  @AllowsNull_97c55941 = 1
SET
  @IsPrimaryKey_97c55941 = 0
SET
  @IsUniqueKey_97c55941 = 0
SET
  @IsReadOnly_97c55941 = 1
SET
  @IsRequired_97c55941 = 0
SET
  @Sequence_97c55941 = 22
SET
  @Status_97c55941 = N'Active'
SET
  @IsCustom_97c55941 = 0
SET
  @MetadataSource_97c55941 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_97c55941,
  @IntegrationObjectID = @IntegrationObjectID_97c55941,
  @Name = @Name_97c55941,
  @DisplayName = @DisplayName_97c55941,
  @Description = @Description_97c55941,
  @Category = @Category_97c55941,
  @Category_Clear = 1,
  @Type = @Type_97c55941,
  @Length = @Length_97c55941,
  @Precision = @Precision_97c55941,
  @Precision_Clear = 1,
  @Scale = @Scale_97c55941,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_97c55941,
  @DefaultValue = @DefaultValue_97c55941,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_97c55941,
  @IsUniqueKey = @IsUniqueKey_97c55941,
  @IsReadOnly = @IsReadOnly_97c55941,
  @IsRequired = @IsRequired_97c55941,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_97c55941,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_97c55941,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_97c55941,
  @Configuration = @Configuration_97c55941,
  @Configuration_Clear = 1,
  @Status = @Status_97c55941,
  @IsCustom = @IsCustom_97c55941,
  @MetadataSource = @MetadataSource_97c55941;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_30429f37 UNIQUEIDENTIFIER,
@IntegrationObjectID_30429f37 UNIQUEIDENTIFIER,
@Name_30429f37 NVARCHAR(255),
@DisplayName_30429f37 NVARCHAR(255),
@Description_30429f37 NVARCHAR(MAX),
@Category_30429f37 NVARCHAR(100),
@Type_30429f37 NVARCHAR(100),
@Length_30429f37 INT,
@Precision_30429f37 INT,
@Scale_30429f37 INT,
@AllowsNull_30429f37 BIT,
@DefaultValue_30429f37 NVARCHAR(255),
@IsPrimaryKey_30429f37 BIT,
@IsUniqueKey_30429f37 BIT,
@IsReadOnly_30429f37 BIT,
@IsRequired_30429f37 BIT,
@RelatedIntegrationObjectID_30429f37 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_30429f37 NVARCHAR(255),
@Sequence_30429f37 INT,
@Configuration_30429f37 NVARCHAR(MAX),
@Status_30429f37 NVARCHAR(25),
@IsCustom_30429f37 BIT,
@MetadataSource_30429f37 NVARCHAR(20)
SET
  @ID_30429f37 = 'E6DFA9E7-3283-5468-AB81-39EB0467B7AE'
SET
  @IntegrationObjectID_30429f37 = 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05'
SET
  @Name_30429f37 = N'organization-region'
SET
  @DisplayName_30429f37 = N'Organization Region'
SET
  @Description_30429f37 = N'Region/state of the organization. Lifted from organization.address.region.'
SET
  @Type_30429f37 = N'String'
SET
  @Length_30429f37 = 255
SET
  @AllowsNull_30429f37 = 1
SET
  @IsPrimaryKey_30429f37 = 0
SET
  @IsUniqueKey_30429f37 = 0
SET
  @IsReadOnly_30429f37 = 1
SET
  @IsRequired_30429f37 = 0
SET
  @Sequence_30429f37 = 23
SET
  @Status_30429f37 = N'Active'
SET
  @IsCustom_30429f37 = 0
SET
  @MetadataSource_30429f37 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_30429f37,
  @IntegrationObjectID = @IntegrationObjectID_30429f37,
  @Name = @Name_30429f37,
  @DisplayName = @DisplayName_30429f37,
  @Description = @Description_30429f37,
  @Category = @Category_30429f37,
  @Category_Clear = 1,
  @Type = @Type_30429f37,
  @Length = @Length_30429f37,
  @Precision = @Precision_30429f37,
  @Precision_Clear = 1,
  @Scale = @Scale_30429f37,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_30429f37,
  @DefaultValue = @DefaultValue_30429f37,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_30429f37,
  @IsUniqueKey = @IsUniqueKey_30429f37,
  @IsReadOnly = @IsReadOnly_30429f37,
  @IsRequired = @IsRequired_30429f37,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_30429f37,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_30429f37,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_30429f37,
  @Configuration = @Configuration_30429f37,
  @Configuration_Clear = 1,
  @Status = @Status_30429f37,
  @IsCustom = @IsCustom_30429f37,
  @MetadataSource = @MetadataSource_30429f37;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_370f9eb0 UNIQUEIDENTIFIER,
@IntegrationObjectID_370f9eb0 UNIQUEIDENTIFIER,
@Name_370f9eb0 NVARCHAR(255),
@DisplayName_370f9eb0 NVARCHAR(255),
@Description_370f9eb0 NVARCHAR(MAX),
@Category_370f9eb0 NVARCHAR(100),
@Type_370f9eb0 NVARCHAR(100),
@Length_370f9eb0 INT,
@Precision_370f9eb0 INT,
@Scale_370f9eb0 INT,
@AllowsNull_370f9eb0 BIT,
@DefaultValue_370f9eb0 NVARCHAR(255),
@IsPrimaryKey_370f9eb0 BIT,
@IsUniqueKey_370f9eb0 BIT,
@IsReadOnly_370f9eb0 BIT,
@IsRequired_370f9eb0 BIT,
@RelatedIntegrationObjectID_370f9eb0 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_370f9eb0 NVARCHAR(255),
@Sequence_370f9eb0 INT,
@Configuration_370f9eb0 NVARCHAR(MAX),
@Status_370f9eb0 NVARCHAR(25),
@IsCustom_370f9eb0 BIT,
@MetadataSource_370f9eb0 NVARCHAR(20)
SET
  @ID_370f9eb0 = 'F29B8F09-6C37-5791-96FE-27E4BDA5F8A6'
SET
  @IntegrationObjectID_370f9eb0 = 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05'
SET
  @Name_370f9eb0 = N'organization-country'
SET
  @DisplayName_370f9eb0 = N'Organization Country'
SET
  @Description_370f9eb0 = N'ISO country code of the organization. Lifted from organization.address.country.'
SET
  @Type_370f9eb0 = N'String'
SET
  @Length_370f9eb0 = 50
SET
  @AllowsNull_370f9eb0 = 1
SET
  @IsPrimaryKey_370f9eb0 = 0
SET
  @IsUniqueKey_370f9eb0 = 0
SET
  @IsReadOnly_370f9eb0 = 1
SET
  @IsRequired_370f9eb0 = 0
SET
  @Sequence_370f9eb0 = 24
SET
  @Status_370f9eb0 = N'Active'
SET
  @IsCustom_370f9eb0 = 0
SET
  @MetadataSource_370f9eb0 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_370f9eb0,
  @IntegrationObjectID = @IntegrationObjectID_370f9eb0,
  @Name = @Name_370f9eb0,
  @DisplayName = @DisplayName_370f9eb0,
  @Description = @Description_370f9eb0,
  @Category = @Category_370f9eb0,
  @Category_Clear = 1,
  @Type = @Type_370f9eb0,
  @Length = @Length_370f9eb0,
  @Precision = @Precision_370f9eb0,
  @Precision_Clear = 1,
  @Scale = @Scale_370f9eb0,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_370f9eb0,
  @DefaultValue = @DefaultValue_370f9eb0,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_370f9eb0,
  @IsUniqueKey = @IsUniqueKey_370f9eb0,
  @IsReadOnly = @IsReadOnly_370f9eb0,
  @IsRequired = @IsRequired_370f9eb0,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_370f9eb0,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_370f9eb0,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_370f9eb0,
  @Configuration = @Configuration_370f9eb0,
  @Configuration_Clear = 1,
  @Status = @Status_370f9eb0,
  @IsCustom = @IsCustom_370f9eb0,
  @MetadataSource = @MetadataSource_370f9eb0;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_cd2c3757 UNIQUEIDENTIFIER,
@IntegrationObjectID_cd2c3757 UNIQUEIDENTIFIER,
@Name_cd2c3757 NVARCHAR(255),
@DisplayName_cd2c3757 NVARCHAR(255),
@Description_cd2c3757 NVARCHAR(MAX),
@Category_cd2c3757 NVARCHAR(100),
@Type_cd2c3757 NVARCHAR(100),
@Length_cd2c3757 INT,
@Precision_cd2c3757 INT,
@Scale_cd2c3757 INT,
@AllowsNull_cd2c3757 BIT,
@DefaultValue_cd2c3757 NVARCHAR(255),
@IsPrimaryKey_cd2c3757 BIT,
@IsUniqueKey_cd2c3757 BIT,
@IsReadOnly_cd2c3757 BIT,
@IsRequired_cd2c3757 BIT,
@RelatedIntegrationObjectID_cd2c3757 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_cd2c3757 NVARCHAR(255),
@Sequence_cd2c3757 INT,
@Configuration_cd2c3757 NVARCHAR(MAX),
@Status_cd2c3757 NVARCHAR(25),
@IsCustom_cd2c3757 BIT,
@MetadataSource_cd2c3757 NVARCHAR(20)
SET
  @ID_cd2c3757 = '5281D835-9B52-58A6-8B67-4B44564F8CD8'
SET
  @IntegrationObjectID_cd2c3757 = 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05'
SET
  @Name_cd2c3757 = N'organization-disambiguated-id'
SET
  @DisplayName_cd2c3757 = N'Organization Disambiguated Id'
SET
  @Description_cd2c3757 = N'Canonical identifier of the organization in the disambiguation source (e.g. a RINGGOLD or ROR id), so the same institution matches across records.'
SET
  @Type_cd2c3757 = N'String'
SET
  @Length_cd2c3757 = 255
SET
  @AllowsNull_cd2c3757 = 1
SET
  @IsPrimaryKey_cd2c3757 = 0
SET
  @IsUniqueKey_cd2c3757 = 0
SET
  @IsReadOnly_cd2c3757 = 1
SET
  @IsRequired_cd2c3757 = 0
SET
  @Sequence_cd2c3757 = 25
SET
  @Status_cd2c3757 = N'Active'
SET
  @IsCustom_cd2c3757 = 0
SET
  @MetadataSource_cd2c3757 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_cd2c3757,
  @IntegrationObjectID = @IntegrationObjectID_cd2c3757,
  @Name = @Name_cd2c3757,
  @DisplayName = @DisplayName_cd2c3757,
  @Description = @Description_cd2c3757,
  @Category = @Category_cd2c3757,
  @Category_Clear = 1,
  @Type = @Type_cd2c3757,
  @Length = @Length_cd2c3757,
  @Precision = @Precision_cd2c3757,
  @Precision_Clear = 1,
  @Scale = @Scale_cd2c3757,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_cd2c3757,
  @DefaultValue = @DefaultValue_cd2c3757,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_cd2c3757,
  @IsUniqueKey = @IsUniqueKey_cd2c3757,
  @IsReadOnly = @IsReadOnly_cd2c3757,
  @IsRequired = @IsRequired_cd2c3757,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_cd2c3757,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_cd2c3757,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_cd2c3757,
  @Configuration = @Configuration_cd2c3757,
  @Configuration_Clear = 1,
  @Status = @Status_cd2c3757,
  @IsCustom = @IsCustom_cd2c3757,
  @MetadataSource = @MetadataSource_cd2c3757;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_5783a021 UNIQUEIDENTIFIER,
@IntegrationObjectID_5783a021 UNIQUEIDENTIFIER,
@Name_5783a021 NVARCHAR(255),
@DisplayName_5783a021 NVARCHAR(255),
@Description_5783a021 NVARCHAR(MAX),
@Category_5783a021 NVARCHAR(100),
@Type_5783a021 NVARCHAR(100),
@Length_5783a021 INT,
@Precision_5783a021 INT,
@Scale_5783a021 INT,
@AllowsNull_5783a021 BIT,
@DefaultValue_5783a021 NVARCHAR(255),
@IsPrimaryKey_5783a021 BIT,
@IsUniqueKey_5783a021 BIT,
@IsReadOnly_5783a021 BIT,
@IsRequired_5783a021 BIT,
@RelatedIntegrationObjectID_5783a021 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_5783a021 NVARCHAR(255),
@Sequence_5783a021 INT,
@Configuration_5783a021 NVARCHAR(MAX),
@Status_5783a021 NVARCHAR(25),
@IsCustom_5783a021 BIT,
@MetadataSource_5783a021 NVARCHAR(20)
SET
  @ID_5783a021 = '6D655C2C-830B-5857-A312-8369693B7094'
SET
  @IntegrationObjectID_5783a021 = 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05'
SET
  @Name_5783a021 = N'organization-disambiguation-source'
SET
  @DisplayName_5783a021 = N'Organization Disambiguation Source'
SET
  @Description_5783a021 = N'Registry the disambiguated id comes from (RINGGOLD, ROR, FUNDREF, GRID, LEI).'
SET
  @Type_5783a021 = N'String'
SET
  @Length_5783a021 = 100
SET
  @AllowsNull_5783a021 = 1
SET
  @IsPrimaryKey_5783a021 = 0
SET
  @IsUniqueKey_5783a021 = 0
SET
  @IsReadOnly_5783a021 = 1
SET
  @IsRequired_5783a021 = 0
SET
  @Sequence_5783a021 = 26
SET
  @Status_5783a021 = N'Active'
SET
  @IsCustom_5783a021 = 0
SET
  @MetadataSource_5783a021 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_5783a021,
  @IntegrationObjectID = @IntegrationObjectID_5783a021,
  @Name = @Name_5783a021,
  @DisplayName = @DisplayName_5783a021,
  @Description = @Description_5783a021,
  @Category = @Category_5783a021,
  @Category_Clear = 1,
  @Type = @Type_5783a021,
  @Length = @Length_5783a021,
  @Precision = @Precision_5783a021,
  @Precision_Clear = 1,
  @Scale = @Scale_5783a021,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_5783a021,
  @DefaultValue = @DefaultValue_5783a021,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_5783a021,
  @IsUniqueKey = @IsUniqueKey_5783a021,
  @IsReadOnly = @IsReadOnly_5783a021,
  @IsRequired = @IsRequired_5783a021,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_5783a021,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_5783a021,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_5783a021,
  @Configuration = @Configuration_5783a021,
  @Configuration_Clear = 1,
  @Status = @Status_5783a021,
  @IsCustom = @IsCustom_5783a021,
  @MetadataSource = @MetadataSource_5783a021;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_0d331a3c UNIQUEIDENTIFIER,
@IntegrationObjectID_0d331a3c UNIQUEIDENTIFIER,
@Name_0d331a3c NVARCHAR(255),
@DisplayName_0d331a3c NVARCHAR(255),
@Description_0d331a3c NVARCHAR(MAX),
@Category_0d331a3c NVARCHAR(100),
@Type_0d331a3c NVARCHAR(100),
@Length_0d331a3c INT,
@Precision_0d331a3c INT,
@Scale_0d331a3c INT,
@AllowsNull_0d331a3c BIT,
@DefaultValue_0d331a3c NVARCHAR(255),
@IsPrimaryKey_0d331a3c BIT,
@IsUniqueKey_0d331a3c BIT,
@IsReadOnly_0d331a3c BIT,
@IsRequired_0d331a3c BIT,
@RelatedIntegrationObjectID_0d331a3c UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_0d331a3c NVARCHAR(255),
@Sequence_0d331a3c INT,
@Configuration_0d331a3c NVARCHAR(MAX),
@Status_0d331a3c NVARCHAR(25),
@IsCustom_0d331a3c BIT,
@MetadataSource_0d331a3c NVARCHAR(20)
SET
  @ID_0d331a3c = '724C306B-01D4-5BA7-9BCB-1BF576FFADDD'
SET
  @IntegrationObjectID_0d331a3c = 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05'
SET
  @Name_0d331a3c = N'source-name'
SET
  @DisplayName_0d331a3c = N'Source Name'
SET
  @Description_0d331a3c = N'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.'
SET
  @Type_0d331a3c = N'String'
SET
  @Length_0d331a3c = 500
SET
  @AllowsNull_0d331a3c = 1
SET
  @IsPrimaryKey_0d331a3c = 0
SET
  @IsUniqueKey_0d331a3c = 0
SET
  @IsReadOnly_0d331a3c = 1
SET
  @IsRequired_0d331a3c = 0
SET
  @Sequence_0d331a3c = 27
SET
  @Status_0d331a3c = N'Active'
SET
  @IsCustom_0d331a3c = 0
SET
  @MetadataSource_0d331a3c = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_0d331a3c,
  @IntegrationObjectID = @IntegrationObjectID_0d331a3c,
  @Name = @Name_0d331a3c,
  @DisplayName = @DisplayName_0d331a3c,
  @Description = @Description_0d331a3c,
  @Category = @Category_0d331a3c,
  @Category_Clear = 1,
  @Type = @Type_0d331a3c,
  @Length = @Length_0d331a3c,
  @Precision = @Precision_0d331a3c,
  @Precision_Clear = 1,
  @Scale = @Scale_0d331a3c,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_0d331a3c,
  @DefaultValue = @DefaultValue_0d331a3c,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_0d331a3c,
  @IsUniqueKey = @IsUniqueKey_0d331a3c,
  @IsReadOnly = @IsReadOnly_0d331a3c,
  @IsRequired = @IsRequired_0d331a3c,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_0d331a3c,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_0d331a3c,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_0d331a3c,
  @Configuration = @Configuration_0d331a3c,
  @Configuration_Clear = 1,
  @Status = @Status_0d331a3c,
  @IsCustom = @IsCustom_0d331a3c,
  @MetadataSource = @MetadataSource_0d331a3c;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_fa4a3a48 UNIQUEIDENTIFIER,
@IntegrationObjectID_fa4a3a48 UNIQUEIDENTIFIER,
@Name_fa4a3a48 NVARCHAR(255),
@DisplayName_fa4a3a48 NVARCHAR(255),
@Description_fa4a3a48 NVARCHAR(MAX),
@Category_fa4a3a48 NVARCHAR(100),
@Type_fa4a3a48 NVARCHAR(100),
@Length_fa4a3a48 INT,
@Precision_fa4a3a48 INT,
@Scale_fa4a3a48 INT,
@AllowsNull_fa4a3a48 BIT,
@DefaultValue_fa4a3a48 NVARCHAR(255),
@IsPrimaryKey_fa4a3a48 BIT,
@IsUniqueKey_fa4a3a48 BIT,
@IsReadOnly_fa4a3a48 BIT,
@IsRequired_fa4a3a48 BIT,
@RelatedIntegrationObjectID_fa4a3a48 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_fa4a3a48 NVARCHAR(255),
@Sequence_fa4a3a48 INT,
@Configuration_fa4a3a48 NVARCHAR(MAX),
@Status_fa4a3a48 NVARCHAR(25),
@IsCustom_fa4a3a48 BIT,
@MetadataSource_fa4a3a48 NVARCHAR(20)
SET
  @ID_fa4a3a48 = 'F9711D4B-FF96-5F2F-ADEA-40777E56FF63'
SET
  @IntegrationObjectID_fa4a3a48 = 'B696CEFA-C2D9-4441-AA6C-D11506F8EA05'
SET
  @Name_fa4a3a48 = N'source-orcid'
SET
  @DisplayName_fa4a3a48 = N'Source Orcid'
SET
  @Description_fa4a3a48 = N'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.'
SET
  @Type_fa4a3a48 = N'String'
SET
  @Length_fa4a3a48 = 19
SET
  @AllowsNull_fa4a3a48 = 1
SET
  @IsPrimaryKey_fa4a3a48 = 0
SET
  @IsUniqueKey_fa4a3a48 = 0
SET
  @IsReadOnly_fa4a3a48 = 1
SET
  @IsRequired_fa4a3a48 = 0
SET
  @Sequence_fa4a3a48 = 28
SET
  @Status_fa4a3a48 = N'Active'
SET
  @IsCustom_fa4a3a48 = 0
SET
  @MetadataSource_fa4a3a48 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_fa4a3a48,
  @IntegrationObjectID = @IntegrationObjectID_fa4a3a48,
  @Name = @Name_fa4a3a48,
  @DisplayName = @DisplayName_fa4a3a48,
  @Description = @Description_fa4a3a48,
  @Category = @Category_fa4a3a48,
  @Category_Clear = 1,
  @Type = @Type_fa4a3a48,
  @Length = @Length_fa4a3a48,
  @Precision = @Precision_fa4a3a48,
  @Precision_Clear = 1,
  @Scale = @Scale_fa4a3a48,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_fa4a3a48,
  @DefaultValue = @DefaultValue_fa4a3a48,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_fa4a3a48,
  @IsUniqueKey = @IsUniqueKey_fa4a3a48,
  @IsReadOnly = @IsReadOnly_fa4a3a48,
  @IsRequired = @IsRequired_fa4a3a48,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_fa4a3a48,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_fa4a3a48,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_fa4a3a48,
  @Configuration = @Configuration_fa4a3a48,
  @Configuration_Clear = 1,
  @Status = @Status_fa4a3a48,
  @IsCustom = @IsCustom_fa4a3a48,
  @MetadataSource = @MetadataSource_fa4a3a48;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_6a78e18b UNIQUEIDENTIFIER,
@IntegrationObjectID_6a78e18b UNIQUEIDENTIFIER,
@Name_6a78e18b NVARCHAR(255),
@DisplayName_6a78e18b NVARCHAR(255),
@Description_6a78e18b NVARCHAR(MAX),
@Category_6a78e18b NVARCHAR(100),
@Type_6a78e18b NVARCHAR(100),
@Length_6a78e18b INT,
@Precision_6a78e18b INT,
@Scale_6a78e18b INT,
@AllowsNull_6a78e18b BIT,
@DefaultValue_6a78e18b NVARCHAR(255),
@IsPrimaryKey_6a78e18b BIT,
@IsUniqueKey_6a78e18b BIT,
@IsReadOnly_6a78e18b BIT,
@IsRequired_6a78e18b BIT,
@RelatedIntegrationObjectID_6a78e18b UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_6a78e18b NVARCHAR(255),
@Sequence_6a78e18b INT,
@Configuration_6a78e18b NVARCHAR(MAX),
@Status_6a78e18b NVARCHAR(25),
@IsCustom_6a78e18b BIT,
@MetadataSource_6a78e18b NVARCHAR(20)
SET
  @ID_6a78e18b = '1ED201EF-9831-542B-BB69-988A49F7D516'
SET
  @IntegrationObjectID_6a78e18b = '35593E67-CBB4-4C88-9438-80C1D7F4B2D0'
SET
  @Name_6a78e18b = N'start-year'
SET
  @DisplayName_6a78e18b = N'Start Year'
SET
  @Description_6a78e18b = N'Year of the affiliation start date; ORCID dates are partial, so month/day may be absent.'
SET
  @Type_6a78e18b = N'Integer'
SET
  @AllowsNull_6a78e18b = 1
SET
  @IsPrimaryKey_6a78e18b = 0
SET
  @IsUniqueKey_6a78e18b = 0
SET
  @IsReadOnly_6a78e18b = 1
SET
  @IsRequired_6a78e18b = 0
SET
  @Sequence_6a78e18b = 15
SET
  @Status_6a78e18b = N'Active'
SET
  @IsCustom_6a78e18b = 0
SET
  @MetadataSource_6a78e18b = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_6a78e18b,
  @IntegrationObjectID = @IntegrationObjectID_6a78e18b,
  @Name = @Name_6a78e18b,
  @DisplayName = @DisplayName_6a78e18b,
  @Description = @Description_6a78e18b,
  @Category = @Category_6a78e18b,
  @Category_Clear = 1,
  @Type = @Type_6a78e18b,
  @Length = @Length_6a78e18b,
  @Length_Clear = 1,
  @Precision = @Precision_6a78e18b,
  @Precision_Clear = 1,
  @Scale = @Scale_6a78e18b,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_6a78e18b,
  @DefaultValue = @DefaultValue_6a78e18b,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_6a78e18b,
  @IsUniqueKey = @IsUniqueKey_6a78e18b,
  @IsReadOnly = @IsReadOnly_6a78e18b,
  @IsRequired = @IsRequired_6a78e18b,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_6a78e18b,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_6a78e18b,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_6a78e18b,
  @Configuration = @Configuration_6a78e18b,
  @Configuration_Clear = 1,
  @Status = @Status_6a78e18b,
  @IsCustom = @IsCustom_6a78e18b,
  @MetadataSource = @MetadataSource_6a78e18b;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_09bcb71c UNIQUEIDENTIFIER,
@IntegrationObjectID_09bcb71c UNIQUEIDENTIFIER,
@Name_09bcb71c NVARCHAR(255),
@DisplayName_09bcb71c NVARCHAR(255),
@Description_09bcb71c NVARCHAR(MAX),
@Category_09bcb71c NVARCHAR(100),
@Type_09bcb71c NVARCHAR(100),
@Length_09bcb71c INT,
@Precision_09bcb71c INT,
@Scale_09bcb71c INT,
@AllowsNull_09bcb71c BIT,
@DefaultValue_09bcb71c NVARCHAR(255),
@IsPrimaryKey_09bcb71c BIT,
@IsUniqueKey_09bcb71c BIT,
@IsReadOnly_09bcb71c BIT,
@IsRequired_09bcb71c BIT,
@RelatedIntegrationObjectID_09bcb71c UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_09bcb71c NVARCHAR(255),
@Sequence_09bcb71c INT,
@Configuration_09bcb71c NVARCHAR(MAX),
@Status_09bcb71c NVARCHAR(25),
@IsCustom_09bcb71c BIT,
@MetadataSource_09bcb71c NVARCHAR(20)
SET
  @ID_09bcb71c = 'B5E97EE6-8A57-5673-85FB-E07A7F23EECD'
SET
  @IntegrationObjectID_09bcb71c = '35593E67-CBB4-4C88-9438-80C1D7F4B2D0'
SET
  @Name_09bcb71c = N'start-month'
SET
  @DisplayName_09bcb71c = N'Start Month'
SET
  @Description_09bcb71c = N'Month (1-12) of the affiliation start date, when given.'
SET
  @Type_09bcb71c = N'Integer'
SET
  @AllowsNull_09bcb71c = 1
SET
  @IsPrimaryKey_09bcb71c = 0
SET
  @IsUniqueKey_09bcb71c = 0
SET
  @IsReadOnly_09bcb71c = 1
SET
  @IsRequired_09bcb71c = 0
SET
  @Sequence_09bcb71c = 16
SET
  @Status_09bcb71c = N'Active'
SET
  @IsCustom_09bcb71c = 0
SET
  @MetadataSource_09bcb71c = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_09bcb71c,
  @IntegrationObjectID = @IntegrationObjectID_09bcb71c,
  @Name = @Name_09bcb71c,
  @DisplayName = @DisplayName_09bcb71c,
  @Description = @Description_09bcb71c,
  @Category = @Category_09bcb71c,
  @Category_Clear = 1,
  @Type = @Type_09bcb71c,
  @Length = @Length_09bcb71c,
  @Length_Clear = 1,
  @Precision = @Precision_09bcb71c,
  @Precision_Clear = 1,
  @Scale = @Scale_09bcb71c,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_09bcb71c,
  @DefaultValue = @DefaultValue_09bcb71c,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_09bcb71c,
  @IsUniqueKey = @IsUniqueKey_09bcb71c,
  @IsReadOnly = @IsReadOnly_09bcb71c,
  @IsRequired = @IsRequired_09bcb71c,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_09bcb71c,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_09bcb71c,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_09bcb71c,
  @Configuration = @Configuration_09bcb71c,
  @Configuration_Clear = 1,
  @Status = @Status_09bcb71c,
  @IsCustom = @IsCustom_09bcb71c,
  @MetadataSource = @MetadataSource_09bcb71c;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_d8f500a8 UNIQUEIDENTIFIER,
@IntegrationObjectID_d8f500a8 UNIQUEIDENTIFIER,
@Name_d8f500a8 NVARCHAR(255),
@DisplayName_d8f500a8 NVARCHAR(255),
@Description_d8f500a8 NVARCHAR(MAX),
@Category_d8f500a8 NVARCHAR(100),
@Type_d8f500a8 NVARCHAR(100),
@Length_d8f500a8 INT,
@Precision_d8f500a8 INT,
@Scale_d8f500a8 INT,
@AllowsNull_d8f500a8 BIT,
@DefaultValue_d8f500a8 NVARCHAR(255),
@IsPrimaryKey_d8f500a8 BIT,
@IsUniqueKey_d8f500a8 BIT,
@IsReadOnly_d8f500a8 BIT,
@IsRequired_d8f500a8 BIT,
@RelatedIntegrationObjectID_d8f500a8 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_d8f500a8 NVARCHAR(255),
@Sequence_d8f500a8 INT,
@Configuration_d8f500a8 NVARCHAR(MAX),
@Status_d8f500a8 NVARCHAR(25),
@IsCustom_d8f500a8 BIT,
@MetadataSource_d8f500a8 NVARCHAR(20)
SET
  @ID_d8f500a8 = '991114B8-3ED9-59D4-89DD-E42A8A36D3B0'
SET
  @IntegrationObjectID_d8f500a8 = '35593E67-CBB4-4C88-9438-80C1D7F4B2D0'
SET
  @Name_d8f500a8 = N'start-day'
SET
  @DisplayName_d8f500a8 = N'Start Day'
SET
  @Description_d8f500a8 = N'Day of month of the affiliation start date, when given.'
SET
  @Type_d8f500a8 = N'Integer'
SET
  @AllowsNull_d8f500a8 = 1
SET
  @IsPrimaryKey_d8f500a8 = 0
SET
  @IsUniqueKey_d8f500a8 = 0
SET
  @IsReadOnly_d8f500a8 = 1
SET
  @IsRequired_d8f500a8 = 0
SET
  @Sequence_d8f500a8 = 17
SET
  @Status_d8f500a8 = N'Active'
SET
  @IsCustom_d8f500a8 = 0
SET
  @MetadataSource_d8f500a8 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_d8f500a8,
  @IntegrationObjectID = @IntegrationObjectID_d8f500a8,
  @Name = @Name_d8f500a8,
  @DisplayName = @DisplayName_d8f500a8,
  @Description = @Description_d8f500a8,
  @Category = @Category_d8f500a8,
  @Category_Clear = 1,
  @Type = @Type_d8f500a8,
  @Length = @Length_d8f500a8,
  @Length_Clear = 1,
  @Precision = @Precision_d8f500a8,
  @Precision_Clear = 1,
  @Scale = @Scale_d8f500a8,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_d8f500a8,
  @DefaultValue = @DefaultValue_d8f500a8,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_d8f500a8,
  @IsUniqueKey = @IsUniqueKey_d8f500a8,
  @IsReadOnly = @IsReadOnly_d8f500a8,
  @IsRequired = @IsRequired_d8f500a8,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_d8f500a8,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_d8f500a8,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_d8f500a8,
  @Configuration = @Configuration_d8f500a8,
  @Configuration_Clear = 1,
  @Status = @Status_d8f500a8,
  @IsCustom = @IsCustom_d8f500a8,
  @MetadataSource = @MetadataSource_d8f500a8;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_c09892c6 UNIQUEIDENTIFIER,
@IntegrationObjectID_c09892c6 UNIQUEIDENTIFIER,
@Name_c09892c6 NVARCHAR(255),
@DisplayName_c09892c6 NVARCHAR(255),
@Description_c09892c6 NVARCHAR(MAX),
@Category_c09892c6 NVARCHAR(100),
@Type_c09892c6 NVARCHAR(100),
@Length_c09892c6 INT,
@Precision_c09892c6 INT,
@Scale_c09892c6 INT,
@AllowsNull_c09892c6 BIT,
@DefaultValue_c09892c6 NVARCHAR(255),
@IsPrimaryKey_c09892c6 BIT,
@IsUniqueKey_c09892c6 BIT,
@IsReadOnly_c09892c6 BIT,
@IsRequired_c09892c6 BIT,
@RelatedIntegrationObjectID_c09892c6 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_c09892c6 NVARCHAR(255),
@Sequence_c09892c6 INT,
@Configuration_c09892c6 NVARCHAR(MAX),
@Status_c09892c6 NVARCHAR(25),
@IsCustom_c09892c6 BIT,
@MetadataSource_c09892c6 NVARCHAR(20)
SET
  @ID_c09892c6 = 'D0A6050D-4679-5E99-B5AA-D63C55C6B470'
SET
  @IntegrationObjectID_c09892c6 = '35593E67-CBB4-4C88-9438-80C1D7F4B2D0'
SET
  @Name_c09892c6 = N'end-year'
SET
  @DisplayName_c09892c6 = N'End Year'
SET
  @Description_c09892c6 = N'Year of the affiliation end date; empty for a current/ongoing role; ORCID dates are partial, so month/day may be absent.'
SET
  @Type_c09892c6 = N'Integer'
SET
  @AllowsNull_c09892c6 = 1
SET
  @IsPrimaryKey_c09892c6 = 0
SET
  @IsUniqueKey_c09892c6 = 0
SET
  @IsReadOnly_c09892c6 = 1
SET
  @IsRequired_c09892c6 = 0
SET
  @Sequence_c09892c6 = 18
SET
  @Status_c09892c6 = N'Active'
SET
  @IsCustom_c09892c6 = 0
SET
  @MetadataSource_c09892c6 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_c09892c6,
  @IntegrationObjectID = @IntegrationObjectID_c09892c6,
  @Name = @Name_c09892c6,
  @DisplayName = @DisplayName_c09892c6,
  @Description = @Description_c09892c6,
  @Category = @Category_c09892c6,
  @Category_Clear = 1,
  @Type = @Type_c09892c6,
  @Length = @Length_c09892c6,
  @Length_Clear = 1,
  @Precision = @Precision_c09892c6,
  @Precision_Clear = 1,
  @Scale = @Scale_c09892c6,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_c09892c6,
  @DefaultValue = @DefaultValue_c09892c6,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_c09892c6,
  @IsUniqueKey = @IsUniqueKey_c09892c6,
  @IsReadOnly = @IsReadOnly_c09892c6,
  @IsRequired = @IsRequired_c09892c6,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_c09892c6,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_c09892c6,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_c09892c6,
  @Configuration = @Configuration_c09892c6,
  @Configuration_Clear = 1,
  @Status = @Status_c09892c6,
  @IsCustom = @IsCustom_c09892c6,
  @MetadataSource = @MetadataSource_c09892c6;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_52359736 UNIQUEIDENTIFIER,
@IntegrationObjectID_52359736 UNIQUEIDENTIFIER,
@Name_52359736 NVARCHAR(255),
@DisplayName_52359736 NVARCHAR(255),
@Description_52359736 NVARCHAR(MAX),
@Category_52359736 NVARCHAR(100),
@Type_52359736 NVARCHAR(100),
@Length_52359736 INT,
@Precision_52359736 INT,
@Scale_52359736 INT,
@AllowsNull_52359736 BIT,
@DefaultValue_52359736 NVARCHAR(255),
@IsPrimaryKey_52359736 BIT,
@IsUniqueKey_52359736 BIT,
@IsReadOnly_52359736 BIT,
@IsRequired_52359736 BIT,
@RelatedIntegrationObjectID_52359736 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_52359736 NVARCHAR(255),
@Sequence_52359736 INT,
@Configuration_52359736 NVARCHAR(MAX),
@Status_52359736 NVARCHAR(25),
@IsCustom_52359736 BIT,
@MetadataSource_52359736 NVARCHAR(20)
SET
  @ID_52359736 = 'E8DC2990-8DCA-518E-B859-E2BF7A74DF0E'
SET
  @IntegrationObjectID_52359736 = '35593E67-CBB4-4C88-9438-80C1D7F4B2D0'
SET
  @Name_52359736 = N'end-month'
SET
  @DisplayName_52359736 = N'End Month'
SET
  @Description_52359736 = N'Month (1-12) of the affiliation end date; empty for a current/ongoing role, when given.'
SET
  @Type_52359736 = N'Integer'
SET
  @AllowsNull_52359736 = 1
SET
  @IsPrimaryKey_52359736 = 0
SET
  @IsUniqueKey_52359736 = 0
SET
  @IsReadOnly_52359736 = 1
SET
  @IsRequired_52359736 = 0
SET
  @Sequence_52359736 = 19
SET
  @Status_52359736 = N'Active'
SET
  @IsCustom_52359736 = 0
SET
  @MetadataSource_52359736 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_52359736,
  @IntegrationObjectID = @IntegrationObjectID_52359736,
  @Name = @Name_52359736,
  @DisplayName = @DisplayName_52359736,
  @Description = @Description_52359736,
  @Category = @Category_52359736,
  @Category_Clear = 1,
  @Type = @Type_52359736,
  @Length = @Length_52359736,
  @Length_Clear = 1,
  @Precision = @Precision_52359736,
  @Precision_Clear = 1,
  @Scale = @Scale_52359736,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_52359736,
  @DefaultValue = @DefaultValue_52359736,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_52359736,
  @IsUniqueKey = @IsUniqueKey_52359736,
  @IsReadOnly = @IsReadOnly_52359736,
  @IsRequired = @IsRequired_52359736,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_52359736,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_52359736,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_52359736,
  @Configuration = @Configuration_52359736,
  @Configuration_Clear = 1,
  @Status = @Status_52359736,
  @IsCustom = @IsCustom_52359736,
  @MetadataSource = @MetadataSource_52359736;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_acd0d67d UNIQUEIDENTIFIER,
@IntegrationObjectID_acd0d67d UNIQUEIDENTIFIER,
@Name_acd0d67d NVARCHAR(255),
@DisplayName_acd0d67d NVARCHAR(255),
@Description_acd0d67d NVARCHAR(MAX),
@Category_acd0d67d NVARCHAR(100),
@Type_acd0d67d NVARCHAR(100),
@Length_acd0d67d INT,
@Precision_acd0d67d INT,
@Scale_acd0d67d INT,
@AllowsNull_acd0d67d BIT,
@DefaultValue_acd0d67d NVARCHAR(255),
@IsPrimaryKey_acd0d67d BIT,
@IsUniqueKey_acd0d67d BIT,
@IsReadOnly_acd0d67d BIT,
@IsRequired_acd0d67d BIT,
@RelatedIntegrationObjectID_acd0d67d UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_acd0d67d NVARCHAR(255),
@Sequence_acd0d67d INT,
@Configuration_acd0d67d NVARCHAR(MAX),
@Status_acd0d67d NVARCHAR(25),
@IsCustom_acd0d67d BIT,
@MetadataSource_acd0d67d NVARCHAR(20)
SET
  @ID_acd0d67d = '7FD4DCE0-8EAB-58EE-8311-63A843D8D059'
SET
  @IntegrationObjectID_acd0d67d = '35593E67-CBB4-4C88-9438-80C1D7F4B2D0'
SET
  @Name_acd0d67d = N'end-day'
SET
  @DisplayName_acd0d67d = N'End Day'
SET
  @Description_acd0d67d = N'Day of month of the affiliation end date; empty for a current/ongoing role, when given.'
SET
  @Type_acd0d67d = N'Integer'
SET
  @AllowsNull_acd0d67d = 1
SET
  @IsPrimaryKey_acd0d67d = 0
SET
  @IsUniqueKey_acd0d67d = 0
SET
  @IsReadOnly_acd0d67d = 1
SET
  @IsRequired_acd0d67d = 0
SET
  @Sequence_acd0d67d = 20
SET
  @Status_acd0d67d = N'Active'
SET
  @IsCustom_acd0d67d = 0
SET
  @MetadataSource_acd0d67d = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_acd0d67d,
  @IntegrationObjectID = @IntegrationObjectID_acd0d67d,
  @Name = @Name_acd0d67d,
  @DisplayName = @DisplayName_acd0d67d,
  @Description = @Description_acd0d67d,
  @Category = @Category_acd0d67d,
  @Category_Clear = 1,
  @Type = @Type_acd0d67d,
  @Length = @Length_acd0d67d,
  @Length_Clear = 1,
  @Precision = @Precision_acd0d67d,
  @Precision_Clear = 1,
  @Scale = @Scale_acd0d67d,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_acd0d67d,
  @DefaultValue = @DefaultValue_acd0d67d,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_acd0d67d,
  @IsUniqueKey = @IsUniqueKey_acd0d67d,
  @IsReadOnly = @IsReadOnly_acd0d67d,
  @IsRequired = @IsRequired_acd0d67d,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_acd0d67d,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_acd0d67d,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_acd0d67d,
  @Configuration = @Configuration_acd0d67d,
  @Configuration_Clear = 1,
  @Status = @Status_acd0d67d,
  @IsCustom = @IsCustom_acd0d67d,
  @MetadataSource = @MetadataSource_acd0d67d;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_837d59b4 UNIQUEIDENTIFIER,
@IntegrationObjectID_837d59b4 UNIQUEIDENTIFIER,
@Name_837d59b4 NVARCHAR(255),
@DisplayName_837d59b4 NVARCHAR(255),
@Description_837d59b4 NVARCHAR(MAX),
@Category_837d59b4 NVARCHAR(100),
@Type_837d59b4 NVARCHAR(100),
@Length_837d59b4 INT,
@Precision_837d59b4 INT,
@Scale_837d59b4 INT,
@AllowsNull_837d59b4 BIT,
@DefaultValue_837d59b4 NVARCHAR(255),
@IsPrimaryKey_837d59b4 BIT,
@IsUniqueKey_837d59b4 BIT,
@IsReadOnly_837d59b4 BIT,
@IsRequired_837d59b4 BIT,
@RelatedIntegrationObjectID_837d59b4 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_837d59b4 NVARCHAR(255),
@Sequence_837d59b4 INT,
@Configuration_837d59b4 NVARCHAR(MAX),
@Status_837d59b4 NVARCHAR(25),
@IsCustom_837d59b4 BIT,
@MetadataSource_837d59b4 NVARCHAR(20)
SET
  @ID_837d59b4 = 'EC494265-A034-5F71-AD92-D51BD46C0334'
SET
  @IntegrationObjectID_837d59b4 = '35593E67-CBB4-4C88-9438-80C1D7F4B2D0'
SET
  @Name_837d59b4 = N'organization-name'
SET
  @DisplayName_837d59b4 = N'Organization Name'
SET
  @Description_837d59b4 = N'Name of the organization. Lifted from organization.name.'
SET
  @Type_837d59b4 = N'String'
SET
  @Length_837d59b4 = 1000
SET
  @AllowsNull_837d59b4 = 1
SET
  @IsPrimaryKey_837d59b4 = 0
SET
  @IsUniqueKey_837d59b4 = 0
SET
  @IsReadOnly_837d59b4 = 1
SET
  @IsRequired_837d59b4 = 0
SET
  @Sequence_837d59b4 = 21
SET
  @Status_837d59b4 = N'Active'
SET
  @IsCustom_837d59b4 = 0
SET
  @MetadataSource_837d59b4 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_837d59b4,
  @IntegrationObjectID = @IntegrationObjectID_837d59b4,
  @Name = @Name_837d59b4,
  @DisplayName = @DisplayName_837d59b4,
  @Description = @Description_837d59b4,
  @Category = @Category_837d59b4,
  @Category_Clear = 1,
  @Type = @Type_837d59b4,
  @Length = @Length_837d59b4,
  @Precision = @Precision_837d59b4,
  @Precision_Clear = 1,
  @Scale = @Scale_837d59b4,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_837d59b4,
  @DefaultValue = @DefaultValue_837d59b4,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_837d59b4,
  @IsUniqueKey = @IsUniqueKey_837d59b4,
  @IsReadOnly = @IsReadOnly_837d59b4,
  @IsRequired = @IsRequired_837d59b4,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_837d59b4,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_837d59b4,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_837d59b4,
  @Configuration = @Configuration_837d59b4,
  @Configuration_Clear = 1,
  @Status = @Status_837d59b4,
  @IsCustom = @IsCustom_837d59b4,
  @MetadataSource = @MetadataSource_837d59b4;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_308fbe18 UNIQUEIDENTIFIER,
@IntegrationObjectID_308fbe18 UNIQUEIDENTIFIER,
@Name_308fbe18 NVARCHAR(255),
@DisplayName_308fbe18 NVARCHAR(255),
@Description_308fbe18 NVARCHAR(MAX),
@Category_308fbe18 NVARCHAR(100),
@Type_308fbe18 NVARCHAR(100),
@Length_308fbe18 INT,
@Precision_308fbe18 INT,
@Scale_308fbe18 INT,
@AllowsNull_308fbe18 BIT,
@DefaultValue_308fbe18 NVARCHAR(255),
@IsPrimaryKey_308fbe18 BIT,
@IsUniqueKey_308fbe18 BIT,
@IsReadOnly_308fbe18 BIT,
@IsRequired_308fbe18 BIT,
@RelatedIntegrationObjectID_308fbe18 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_308fbe18 NVARCHAR(255),
@Sequence_308fbe18 INT,
@Configuration_308fbe18 NVARCHAR(MAX),
@Status_308fbe18 NVARCHAR(25),
@IsCustom_308fbe18 BIT,
@MetadataSource_308fbe18 NVARCHAR(20)
SET
  @ID_308fbe18 = '7B04E234-870C-5800-AEB5-C40899002F23'
SET
  @IntegrationObjectID_308fbe18 = '35593E67-CBB4-4C88-9438-80C1D7F4B2D0'
SET
  @Name_308fbe18 = N'organization-city'
SET
  @DisplayName_308fbe18 = N'Organization City'
SET
  @Description_308fbe18 = N'City of the organization. Lifted from organization.address.city.'
SET
  @Type_308fbe18 = N'String'
SET
  @Length_308fbe18 = 255
SET
  @AllowsNull_308fbe18 = 1
SET
  @IsPrimaryKey_308fbe18 = 0
SET
  @IsUniqueKey_308fbe18 = 0
SET
  @IsReadOnly_308fbe18 = 1
SET
  @IsRequired_308fbe18 = 0
SET
  @Sequence_308fbe18 = 22
SET
  @Status_308fbe18 = N'Active'
SET
  @IsCustom_308fbe18 = 0
SET
  @MetadataSource_308fbe18 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_308fbe18,
  @IntegrationObjectID = @IntegrationObjectID_308fbe18,
  @Name = @Name_308fbe18,
  @DisplayName = @DisplayName_308fbe18,
  @Description = @Description_308fbe18,
  @Category = @Category_308fbe18,
  @Category_Clear = 1,
  @Type = @Type_308fbe18,
  @Length = @Length_308fbe18,
  @Precision = @Precision_308fbe18,
  @Precision_Clear = 1,
  @Scale = @Scale_308fbe18,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_308fbe18,
  @DefaultValue = @DefaultValue_308fbe18,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_308fbe18,
  @IsUniqueKey = @IsUniqueKey_308fbe18,
  @IsReadOnly = @IsReadOnly_308fbe18,
  @IsRequired = @IsRequired_308fbe18,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_308fbe18,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_308fbe18,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_308fbe18,
  @Configuration = @Configuration_308fbe18,
  @Configuration_Clear = 1,
  @Status = @Status_308fbe18,
  @IsCustom = @IsCustom_308fbe18,
  @MetadataSource = @MetadataSource_308fbe18;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_e3ffd2a3 UNIQUEIDENTIFIER,
@IntegrationObjectID_e3ffd2a3 UNIQUEIDENTIFIER,
@Name_e3ffd2a3 NVARCHAR(255),
@DisplayName_e3ffd2a3 NVARCHAR(255),
@Description_e3ffd2a3 NVARCHAR(MAX),
@Category_e3ffd2a3 NVARCHAR(100),
@Type_e3ffd2a3 NVARCHAR(100),
@Length_e3ffd2a3 INT,
@Precision_e3ffd2a3 INT,
@Scale_e3ffd2a3 INT,
@AllowsNull_e3ffd2a3 BIT,
@DefaultValue_e3ffd2a3 NVARCHAR(255),
@IsPrimaryKey_e3ffd2a3 BIT,
@IsUniqueKey_e3ffd2a3 BIT,
@IsReadOnly_e3ffd2a3 BIT,
@IsRequired_e3ffd2a3 BIT,
@RelatedIntegrationObjectID_e3ffd2a3 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_e3ffd2a3 NVARCHAR(255),
@Sequence_e3ffd2a3 INT,
@Configuration_e3ffd2a3 NVARCHAR(MAX),
@Status_e3ffd2a3 NVARCHAR(25),
@IsCustom_e3ffd2a3 BIT,
@MetadataSource_e3ffd2a3 NVARCHAR(20)
SET
  @ID_e3ffd2a3 = '4FF4E3EE-C785-5B57-9B49-EDD5A56F28FF'
SET
  @IntegrationObjectID_e3ffd2a3 = '35593E67-CBB4-4C88-9438-80C1D7F4B2D0'
SET
  @Name_e3ffd2a3 = N'organization-region'
SET
  @DisplayName_e3ffd2a3 = N'Organization Region'
SET
  @Description_e3ffd2a3 = N'Region/state of the organization. Lifted from organization.address.region.'
SET
  @Type_e3ffd2a3 = N'String'
SET
  @Length_e3ffd2a3 = 255
SET
  @AllowsNull_e3ffd2a3 = 1
SET
  @IsPrimaryKey_e3ffd2a3 = 0
SET
  @IsUniqueKey_e3ffd2a3 = 0
SET
  @IsReadOnly_e3ffd2a3 = 1
SET
  @IsRequired_e3ffd2a3 = 0
SET
  @Sequence_e3ffd2a3 = 23
SET
  @Status_e3ffd2a3 = N'Active'
SET
  @IsCustom_e3ffd2a3 = 0
SET
  @MetadataSource_e3ffd2a3 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_e3ffd2a3,
  @IntegrationObjectID = @IntegrationObjectID_e3ffd2a3,
  @Name = @Name_e3ffd2a3,
  @DisplayName = @DisplayName_e3ffd2a3,
  @Description = @Description_e3ffd2a3,
  @Category = @Category_e3ffd2a3,
  @Category_Clear = 1,
  @Type = @Type_e3ffd2a3,
  @Length = @Length_e3ffd2a3,
  @Precision = @Precision_e3ffd2a3,
  @Precision_Clear = 1,
  @Scale = @Scale_e3ffd2a3,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_e3ffd2a3,
  @DefaultValue = @DefaultValue_e3ffd2a3,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_e3ffd2a3,
  @IsUniqueKey = @IsUniqueKey_e3ffd2a3,
  @IsReadOnly = @IsReadOnly_e3ffd2a3,
  @IsRequired = @IsRequired_e3ffd2a3,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_e3ffd2a3,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_e3ffd2a3,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_e3ffd2a3,
  @Configuration = @Configuration_e3ffd2a3,
  @Configuration_Clear = 1,
  @Status = @Status_e3ffd2a3,
  @IsCustom = @IsCustom_e3ffd2a3,
  @MetadataSource = @MetadataSource_e3ffd2a3;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_959fbcdf UNIQUEIDENTIFIER,
@IntegrationObjectID_959fbcdf UNIQUEIDENTIFIER,
@Name_959fbcdf NVARCHAR(255),
@DisplayName_959fbcdf NVARCHAR(255),
@Description_959fbcdf NVARCHAR(MAX),
@Category_959fbcdf NVARCHAR(100),
@Type_959fbcdf NVARCHAR(100),
@Length_959fbcdf INT,
@Precision_959fbcdf INT,
@Scale_959fbcdf INT,
@AllowsNull_959fbcdf BIT,
@DefaultValue_959fbcdf NVARCHAR(255),
@IsPrimaryKey_959fbcdf BIT,
@IsUniqueKey_959fbcdf BIT,
@IsReadOnly_959fbcdf BIT,
@IsRequired_959fbcdf BIT,
@RelatedIntegrationObjectID_959fbcdf UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_959fbcdf NVARCHAR(255),
@Sequence_959fbcdf INT,
@Configuration_959fbcdf NVARCHAR(MAX),
@Status_959fbcdf NVARCHAR(25),
@IsCustom_959fbcdf BIT,
@MetadataSource_959fbcdf NVARCHAR(20)
SET
  @ID_959fbcdf = '1CAD3DA1-0AF9-5D28-87C0-1117D64B4A6B'
SET
  @IntegrationObjectID_959fbcdf = '35593E67-CBB4-4C88-9438-80C1D7F4B2D0'
SET
  @Name_959fbcdf = N'organization-country'
SET
  @DisplayName_959fbcdf = N'Organization Country'
SET
  @Description_959fbcdf = N'ISO country code of the organization. Lifted from organization.address.country.'
SET
  @Type_959fbcdf = N'String'
SET
  @Length_959fbcdf = 50
SET
  @AllowsNull_959fbcdf = 1
SET
  @IsPrimaryKey_959fbcdf = 0
SET
  @IsUniqueKey_959fbcdf = 0
SET
  @IsReadOnly_959fbcdf = 1
SET
  @IsRequired_959fbcdf = 0
SET
  @Sequence_959fbcdf = 24
SET
  @Status_959fbcdf = N'Active'
SET
  @IsCustom_959fbcdf = 0
SET
  @MetadataSource_959fbcdf = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_959fbcdf,
  @IntegrationObjectID = @IntegrationObjectID_959fbcdf,
  @Name = @Name_959fbcdf,
  @DisplayName = @DisplayName_959fbcdf,
  @Description = @Description_959fbcdf,
  @Category = @Category_959fbcdf,
  @Category_Clear = 1,
  @Type = @Type_959fbcdf,
  @Length = @Length_959fbcdf,
  @Precision = @Precision_959fbcdf,
  @Precision_Clear = 1,
  @Scale = @Scale_959fbcdf,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_959fbcdf,
  @DefaultValue = @DefaultValue_959fbcdf,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_959fbcdf,
  @IsUniqueKey = @IsUniqueKey_959fbcdf,
  @IsReadOnly = @IsReadOnly_959fbcdf,
  @IsRequired = @IsRequired_959fbcdf,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_959fbcdf,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_959fbcdf,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_959fbcdf,
  @Configuration = @Configuration_959fbcdf,
  @Configuration_Clear = 1,
  @Status = @Status_959fbcdf,
  @IsCustom = @IsCustom_959fbcdf,
  @MetadataSource = @MetadataSource_959fbcdf;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_243ba4eb UNIQUEIDENTIFIER,
@IntegrationObjectID_243ba4eb UNIQUEIDENTIFIER,
@Name_243ba4eb NVARCHAR(255),
@DisplayName_243ba4eb NVARCHAR(255),
@Description_243ba4eb NVARCHAR(MAX),
@Category_243ba4eb NVARCHAR(100),
@Type_243ba4eb NVARCHAR(100),
@Length_243ba4eb INT,
@Precision_243ba4eb INT,
@Scale_243ba4eb INT,
@AllowsNull_243ba4eb BIT,
@DefaultValue_243ba4eb NVARCHAR(255),
@IsPrimaryKey_243ba4eb BIT,
@IsUniqueKey_243ba4eb BIT,
@IsReadOnly_243ba4eb BIT,
@IsRequired_243ba4eb BIT,
@RelatedIntegrationObjectID_243ba4eb UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_243ba4eb NVARCHAR(255),
@Sequence_243ba4eb INT,
@Configuration_243ba4eb NVARCHAR(MAX),
@Status_243ba4eb NVARCHAR(25),
@IsCustom_243ba4eb BIT,
@MetadataSource_243ba4eb NVARCHAR(20)
SET
  @ID_243ba4eb = '7961553B-BD63-51B3-A9F2-940BCF104101'
SET
  @IntegrationObjectID_243ba4eb = '35593E67-CBB4-4C88-9438-80C1D7F4B2D0'
SET
  @Name_243ba4eb = N'organization-disambiguated-id'
SET
  @DisplayName_243ba4eb = N'Organization Disambiguated Id'
SET
  @Description_243ba4eb = N'Canonical identifier of the organization in the disambiguation source (e.g. a RINGGOLD or ROR id), so the same institution matches across records.'
SET
  @Type_243ba4eb = N'String'
SET
  @Length_243ba4eb = 255
SET
  @AllowsNull_243ba4eb = 1
SET
  @IsPrimaryKey_243ba4eb = 0
SET
  @IsUniqueKey_243ba4eb = 0
SET
  @IsReadOnly_243ba4eb = 1
SET
  @IsRequired_243ba4eb = 0
SET
  @Sequence_243ba4eb = 25
SET
  @Status_243ba4eb = N'Active'
SET
  @IsCustom_243ba4eb = 0
SET
  @MetadataSource_243ba4eb = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_243ba4eb,
  @IntegrationObjectID = @IntegrationObjectID_243ba4eb,
  @Name = @Name_243ba4eb,
  @DisplayName = @DisplayName_243ba4eb,
  @Description = @Description_243ba4eb,
  @Category = @Category_243ba4eb,
  @Category_Clear = 1,
  @Type = @Type_243ba4eb,
  @Length = @Length_243ba4eb,
  @Precision = @Precision_243ba4eb,
  @Precision_Clear = 1,
  @Scale = @Scale_243ba4eb,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_243ba4eb,
  @DefaultValue = @DefaultValue_243ba4eb,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_243ba4eb,
  @IsUniqueKey = @IsUniqueKey_243ba4eb,
  @IsReadOnly = @IsReadOnly_243ba4eb,
  @IsRequired = @IsRequired_243ba4eb,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_243ba4eb,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_243ba4eb,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_243ba4eb,
  @Configuration = @Configuration_243ba4eb,
  @Configuration_Clear = 1,
  @Status = @Status_243ba4eb,
  @IsCustom = @IsCustom_243ba4eb,
  @MetadataSource = @MetadataSource_243ba4eb;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_c419b42a UNIQUEIDENTIFIER,
@IntegrationObjectID_c419b42a UNIQUEIDENTIFIER,
@Name_c419b42a NVARCHAR(255),
@DisplayName_c419b42a NVARCHAR(255),
@Description_c419b42a NVARCHAR(MAX),
@Category_c419b42a NVARCHAR(100),
@Type_c419b42a NVARCHAR(100),
@Length_c419b42a INT,
@Precision_c419b42a INT,
@Scale_c419b42a INT,
@AllowsNull_c419b42a BIT,
@DefaultValue_c419b42a NVARCHAR(255),
@IsPrimaryKey_c419b42a BIT,
@IsUniqueKey_c419b42a BIT,
@IsReadOnly_c419b42a BIT,
@IsRequired_c419b42a BIT,
@RelatedIntegrationObjectID_c419b42a UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_c419b42a NVARCHAR(255),
@Sequence_c419b42a INT,
@Configuration_c419b42a NVARCHAR(MAX),
@Status_c419b42a NVARCHAR(25),
@IsCustom_c419b42a BIT,
@MetadataSource_c419b42a NVARCHAR(20)
SET
  @ID_c419b42a = '120B4B37-2547-5123-949E-1AB331541A34'
SET
  @IntegrationObjectID_c419b42a = '35593E67-CBB4-4C88-9438-80C1D7F4B2D0'
SET
  @Name_c419b42a = N'organization-disambiguation-source'
SET
  @DisplayName_c419b42a = N'Organization Disambiguation Source'
SET
  @Description_c419b42a = N'Registry the disambiguated id comes from (RINGGOLD, ROR, FUNDREF, GRID, LEI).'
SET
  @Type_c419b42a = N'String'
SET
  @Length_c419b42a = 100
SET
  @AllowsNull_c419b42a = 1
SET
  @IsPrimaryKey_c419b42a = 0
SET
  @IsUniqueKey_c419b42a = 0
SET
  @IsReadOnly_c419b42a = 1
SET
  @IsRequired_c419b42a = 0
SET
  @Sequence_c419b42a = 26
SET
  @Status_c419b42a = N'Active'
SET
  @IsCustom_c419b42a = 0
SET
  @MetadataSource_c419b42a = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_c419b42a,
  @IntegrationObjectID = @IntegrationObjectID_c419b42a,
  @Name = @Name_c419b42a,
  @DisplayName = @DisplayName_c419b42a,
  @Description = @Description_c419b42a,
  @Category = @Category_c419b42a,
  @Category_Clear = 1,
  @Type = @Type_c419b42a,
  @Length = @Length_c419b42a,
  @Precision = @Precision_c419b42a,
  @Precision_Clear = 1,
  @Scale = @Scale_c419b42a,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_c419b42a,
  @DefaultValue = @DefaultValue_c419b42a,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_c419b42a,
  @IsUniqueKey = @IsUniqueKey_c419b42a,
  @IsReadOnly = @IsReadOnly_c419b42a,
  @IsRequired = @IsRequired_c419b42a,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_c419b42a,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_c419b42a,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_c419b42a,
  @Configuration = @Configuration_c419b42a,
  @Configuration_Clear = 1,
  @Status = @Status_c419b42a,
  @IsCustom = @IsCustom_c419b42a,
  @MetadataSource = @MetadataSource_c419b42a;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_8dd82c87 UNIQUEIDENTIFIER,
@IntegrationObjectID_8dd82c87 UNIQUEIDENTIFIER,
@Name_8dd82c87 NVARCHAR(255),
@DisplayName_8dd82c87 NVARCHAR(255),
@Description_8dd82c87 NVARCHAR(MAX),
@Category_8dd82c87 NVARCHAR(100),
@Type_8dd82c87 NVARCHAR(100),
@Length_8dd82c87 INT,
@Precision_8dd82c87 INT,
@Scale_8dd82c87 INT,
@AllowsNull_8dd82c87 BIT,
@DefaultValue_8dd82c87 NVARCHAR(255),
@IsPrimaryKey_8dd82c87 BIT,
@IsUniqueKey_8dd82c87 BIT,
@IsReadOnly_8dd82c87 BIT,
@IsRequired_8dd82c87 BIT,
@RelatedIntegrationObjectID_8dd82c87 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_8dd82c87 NVARCHAR(255),
@Sequence_8dd82c87 INT,
@Configuration_8dd82c87 NVARCHAR(MAX),
@Status_8dd82c87 NVARCHAR(25),
@IsCustom_8dd82c87 BIT,
@MetadataSource_8dd82c87 NVARCHAR(20)
SET
  @ID_8dd82c87 = '810D7395-2D37-5FED-A50F-F3EE38029691'
SET
  @IntegrationObjectID_8dd82c87 = '35593E67-CBB4-4C88-9438-80C1D7F4B2D0'
SET
  @Name_8dd82c87 = N'source-name'
SET
  @DisplayName_8dd82c87 = N'Source Name'
SET
  @Description_8dd82c87 = N'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.'
SET
  @Type_8dd82c87 = N'String'
SET
  @Length_8dd82c87 = 500
SET
  @AllowsNull_8dd82c87 = 1
SET
  @IsPrimaryKey_8dd82c87 = 0
SET
  @IsUniqueKey_8dd82c87 = 0
SET
  @IsReadOnly_8dd82c87 = 1
SET
  @IsRequired_8dd82c87 = 0
SET
  @Sequence_8dd82c87 = 27
SET
  @Status_8dd82c87 = N'Active'
SET
  @IsCustom_8dd82c87 = 0
SET
  @MetadataSource_8dd82c87 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_8dd82c87,
  @IntegrationObjectID = @IntegrationObjectID_8dd82c87,
  @Name = @Name_8dd82c87,
  @DisplayName = @DisplayName_8dd82c87,
  @Description = @Description_8dd82c87,
  @Category = @Category_8dd82c87,
  @Category_Clear = 1,
  @Type = @Type_8dd82c87,
  @Length = @Length_8dd82c87,
  @Precision = @Precision_8dd82c87,
  @Precision_Clear = 1,
  @Scale = @Scale_8dd82c87,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_8dd82c87,
  @DefaultValue = @DefaultValue_8dd82c87,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_8dd82c87,
  @IsUniqueKey = @IsUniqueKey_8dd82c87,
  @IsReadOnly = @IsReadOnly_8dd82c87,
  @IsRequired = @IsRequired_8dd82c87,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_8dd82c87,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_8dd82c87,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_8dd82c87,
  @Configuration = @Configuration_8dd82c87,
  @Configuration_Clear = 1,
  @Status = @Status_8dd82c87,
  @IsCustom = @IsCustom_8dd82c87,
  @MetadataSource = @MetadataSource_8dd82c87;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_82794b2d UNIQUEIDENTIFIER,
@IntegrationObjectID_82794b2d UNIQUEIDENTIFIER,
@Name_82794b2d NVARCHAR(255),
@DisplayName_82794b2d NVARCHAR(255),
@Description_82794b2d NVARCHAR(MAX),
@Category_82794b2d NVARCHAR(100),
@Type_82794b2d NVARCHAR(100),
@Length_82794b2d INT,
@Precision_82794b2d INT,
@Scale_82794b2d INT,
@AllowsNull_82794b2d BIT,
@DefaultValue_82794b2d NVARCHAR(255),
@IsPrimaryKey_82794b2d BIT,
@IsUniqueKey_82794b2d BIT,
@IsReadOnly_82794b2d BIT,
@IsRequired_82794b2d BIT,
@RelatedIntegrationObjectID_82794b2d UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_82794b2d NVARCHAR(255),
@Sequence_82794b2d INT,
@Configuration_82794b2d NVARCHAR(MAX),
@Status_82794b2d NVARCHAR(25),
@IsCustom_82794b2d BIT,
@MetadataSource_82794b2d NVARCHAR(20)
SET
  @ID_82794b2d = 'D8D8A111-2978-57EF-BACD-733EE23C850F'
SET
  @IntegrationObjectID_82794b2d = '35593E67-CBB4-4C88-9438-80C1D7F4B2D0'
SET
  @Name_82794b2d = N'source-orcid'
SET
  @DisplayName_82794b2d = N'Source Orcid'
SET
  @Description_82794b2d = N'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.'
SET
  @Type_82794b2d = N'String'
SET
  @Length_82794b2d = 19
SET
  @AllowsNull_82794b2d = 1
SET
  @IsPrimaryKey_82794b2d = 0
SET
  @IsUniqueKey_82794b2d = 0
SET
  @IsReadOnly_82794b2d = 1
SET
  @IsRequired_82794b2d = 0
SET
  @Sequence_82794b2d = 28
SET
  @Status_82794b2d = N'Active'
SET
  @IsCustom_82794b2d = 0
SET
  @MetadataSource_82794b2d = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_82794b2d,
  @IntegrationObjectID = @IntegrationObjectID_82794b2d,
  @Name = @Name_82794b2d,
  @DisplayName = @DisplayName_82794b2d,
  @Description = @Description_82794b2d,
  @Category = @Category_82794b2d,
  @Category_Clear = 1,
  @Type = @Type_82794b2d,
  @Length = @Length_82794b2d,
  @Precision = @Precision_82794b2d,
  @Precision_Clear = 1,
  @Scale = @Scale_82794b2d,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_82794b2d,
  @DefaultValue = @DefaultValue_82794b2d,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_82794b2d,
  @IsUniqueKey = @IsUniqueKey_82794b2d,
  @IsReadOnly = @IsReadOnly_82794b2d,
  @IsRequired = @IsRequired_82794b2d,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_82794b2d,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_82794b2d,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_82794b2d,
  @Configuration = @Configuration_82794b2d,
  @Configuration_Clear = 1,
  @Status = @Status_82794b2d,
  @IsCustom = @IsCustom_82794b2d,
  @MetadataSource = @MetadataSource_82794b2d;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_b1584103 UNIQUEIDENTIFIER,
@IntegrationObjectID_b1584103 UNIQUEIDENTIFIER,
@Name_b1584103 NVARCHAR(255),
@DisplayName_b1584103 NVARCHAR(255),
@Description_b1584103 NVARCHAR(MAX),
@Category_b1584103 NVARCHAR(100),
@Type_b1584103 NVARCHAR(100),
@Length_b1584103 INT,
@Precision_b1584103 INT,
@Scale_b1584103 INT,
@AllowsNull_b1584103 BIT,
@DefaultValue_b1584103 NVARCHAR(255),
@IsPrimaryKey_b1584103 BIT,
@IsUniqueKey_b1584103 BIT,
@IsReadOnly_b1584103 BIT,
@IsRequired_b1584103 BIT,
@RelatedIntegrationObjectID_b1584103 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_b1584103 NVARCHAR(255),
@Sequence_b1584103 INT,
@Configuration_b1584103 NVARCHAR(MAX),
@Status_b1584103 NVARCHAR(25),
@IsCustom_b1584103 BIT,
@MetadataSource_b1584103 NVARCHAR(20)
SET
  @ID_b1584103 = '7B9F77B5-7EB6-5DA8-8D3A-F51082EC56CE'
SET
  @IntegrationObjectID_b1584103 = 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD'
SET
  @Name_b1584103 = N'funding-title'
SET
  @DisplayName_b1584103 = N'Funding Title'
SET
  @Description_b1584103 = N'Title of the grant or award. Lifted from title.title.'
SET
  @Type_b1584103 = N'String'
SET
  @Length_b1584103 = 2000
SET
  @AllowsNull_b1584103 = 1
SET
  @IsPrimaryKey_b1584103 = 0
SET
  @IsUniqueKey_b1584103 = 0
SET
  @IsReadOnly_b1584103 = 1
SET
  @IsRequired_b1584103 = 0
SET
  @Sequence_b1584103 = 19
SET
  @Status_b1584103 = N'Active'
SET
  @IsCustom_b1584103 = 0
SET
  @MetadataSource_b1584103 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_b1584103,
  @IntegrationObjectID = @IntegrationObjectID_b1584103,
  @Name = @Name_b1584103,
  @DisplayName = @DisplayName_b1584103,
  @Description = @Description_b1584103,
  @Category = @Category_b1584103,
  @Category_Clear = 1,
  @Type = @Type_b1584103,
  @Length = @Length_b1584103,
  @Precision = @Precision_b1584103,
  @Precision_Clear = 1,
  @Scale = @Scale_b1584103,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_b1584103,
  @DefaultValue = @DefaultValue_b1584103,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_b1584103,
  @IsUniqueKey = @IsUniqueKey_b1584103,
  @IsReadOnly = @IsReadOnly_b1584103,
  @IsRequired = @IsRequired_b1584103,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_b1584103,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_b1584103,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_b1584103,
  @Configuration = @Configuration_b1584103,
  @Configuration_Clear = 1,
  @Status = @Status_b1584103,
  @IsCustom = @IsCustom_b1584103,
  @MetadataSource = @MetadataSource_b1584103;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_d3f977fd UNIQUEIDENTIFIER,
@IntegrationObjectID_d3f977fd UNIQUEIDENTIFIER,
@Name_d3f977fd NVARCHAR(255),
@DisplayName_d3f977fd NVARCHAR(255),
@Description_d3f977fd NVARCHAR(MAX),
@Category_d3f977fd NVARCHAR(100),
@Type_d3f977fd NVARCHAR(100),
@Length_d3f977fd INT,
@Precision_d3f977fd INT,
@Scale_d3f977fd INT,
@AllowsNull_d3f977fd BIT,
@DefaultValue_d3f977fd NVARCHAR(255),
@IsPrimaryKey_d3f977fd BIT,
@IsUniqueKey_d3f977fd BIT,
@IsReadOnly_d3f977fd BIT,
@IsRequired_d3f977fd BIT,
@RelatedIntegrationObjectID_d3f977fd UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_d3f977fd NVARCHAR(255),
@Sequence_d3f977fd INT,
@Configuration_d3f977fd NVARCHAR(MAX),
@Status_d3f977fd NVARCHAR(25),
@IsCustom_d3f977fd BIT,
@MetadataSource_d3f977fd NVARCHAR(20)
SET
  @ID_d3f977fd = 'ECC386F3-9962-5AEE-80F9-036B18946A37'
SET
  @IntegrationObjectID_d3f977fd = 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD'
SET
  @Name_d3f977fd = N'translated-title'
SET
  @DisplayName_d3f977fd = N'Translated Title'
SET
  @Description_d3f977fd = N'Translated title. Lifted from title.translated-title.'
SET
  @Type_d3f977fd = N'String'
SET
  @Length_d3f977fd = 2000
SET
  @AllowsNull_d3f977fd = 1
SET
  @IsPrimaryKey_d3f977fd = 0
SET
  @IsUniqueKey_d3f977fd = 0
SET
  @IsReadOnly_d3f977fd = 1
SET
  @IsRequired_d3f977fd = 0
SET
  @Sequence_d3f977fd = 20
SET
  @Status_d3f977fd = N'Active'
SET
  @IsCustom_d3f977fd = 0
SET
  @MetadataSource_d3f977fd = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_d3f977fd,
  @IntegrationObjectID = @IntegrationObjectID_d3f977fd,
  @Name = @Name_d3f977fd,
  @DisplayName = @DisplayName_d3f977fd,
  @Description = @Description_d3f977fd,
  @Category = @Category_d3f977fd,
  @Category_Clear = 1,
  @Type = @Type_d3f977fd,
  @Length = @Length_d3f977fd,
  @Precision = @Precision_d3f977fd,
  @Precision_Clear = 1,
  @Scale = @Scale_d3f977fd,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_d3f977fd,
  @DefaultValue = @DefaultValue_d3f977fd,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_d3f977fd,
  @IsUniqueKey = @IsUniqueKey_d3f977fd,
  @IsReadOnly = @IsReadOnly_d3f977fd,
  @IsRequired = @IsRequired_d3f977fd,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_d3f977fd,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_d3f977fd,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_d3f977fd,
  @Configuration = @Configuration_d3f977fd,
  @Configuration_Clear = 1,
  @Status = @Status_d3f977fd,
  @IsCustom = @IsCustom_d3f977fd,
  @MetadataSource = @MetadataSource_d3f977fd;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_cbae4f7e UNIQUEIDENTIFIER,
@IntegrationObjectID_cbae4f7e UNIQUEIDENTIFIER,
@Name_cbae4f7e NVARCHAR(255),
@DisplayName_cbae4f7e NVARCHAR(255),
@Description_cbae4f7e NVARCHAR(MAX),
@Category_cbae4f7e NVARCHAR(100),
@Type_cbae4f7e NVARCHAR(100),
@Length_cbae4f7e INT,
@Precision_cbae4f7e INT,
@Scale_cbae4f7e INT,
@AllowsNull_cbae4f7e BIT,
@DefaultValue_cbae4f7e NVARCHAR(255),
@IsPrimaryKey_cbae4f7e BIT,
@IsUniqueKey_cbae4f7e BIT,
@IsReadOnly_cbae4f7e BIT,
@IsRequired_cbae4f7e BIT,
@RelatedIntegrationObjectID_cbae4f7e UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_cbae4f7e NVARCHAR(255),
@Sequence_cbae4f7e INT,
@Configuration_cbae4f7e NVARCHAR(MAX),
@Status_cbae4f7e NVARCHAR(25),
@IsCustom_cbae4f7e BIT,
@MetadataSource_cbae4f7e NVARCHAR(20)
SET
  @ID_cbae4f7e = 'DECDD1BC-8A00-5B86-8830-39FD44A7CB70'
SET
  @IntegrationObjectID_cbae4f7e = 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD'
SET
  @Name_cbae4f7e = N'amount-value'
SET
  @DisplayName_cbae4f7e = N'Amount Value'
SET
  @Description_cbae4f7e = N'Award amount. Only the funding detail endpoint carries it; null when derived from the record summary.'
SET
  @Type_cbae4f7e = N'String'
SET
  @Length_cbae4f7e = 50
SET
  @AllowsNull_cbae4f7e = 1
SET
  @IsPrimaryKey_cbae4f7e = 0
SET
  @IsUniqueKey_cbae4f7e = 0
SET
  @IsReadOnly_cbae4f7e = 1
SET
  @IsRequired_cbae4f7e = 0
SET
  @Sequence_cbae4f7e = 21
SET
  @Status_cbae4f7e = N'Active'
SET
  @IsCustom_cbae4f7e = 0
SET
  @MetadataSource_cbae4f7e = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_cbae4f7e,
  @IntegrationObjectID = @IntegrationObjectID_cbae4f7e,
  @Name = @Name_cbae4f7e,
  @DisplayName = @DisplayName_cbae4f7e,
  @Description = @Description_cbae4f7e,
  @Category = @Category_cbae4f7e,
  @Category_Clear = 1,
  @Type = @Type_cbae4f7e,
  @Length = @Length_cbae4f7e,
  @Precision = @Precision_cbae4f7e,
  @Precision_Clear = 1,
  @Scale = @Scale_cbae4f7e,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_cbae4f7e,
  @DefaultValue = @DefaultValue_cbae4f7e,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_cbae4f7e,
  @IsUniqueKey = @IsUniqueKey_cbae4f7e,
  @IsReadOnly = @IsReadOnly_cbae4f7e,
  @IsRequired = @IsRequired_cbae4f7e,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_cbae4f7e,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_cbae4f7e,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_cbae4f7e,
  @Configuration = @Configuration_cbae4f7e,
  @Configuration_Clear = 1,
  @Status = @Status_cbae4f7e,
  @IsCustom = @IsCustom_cbae4f7e,
  @MetadataSource = @MetadataSource_cbae4f7e;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_822cc547 UNIQUEIDENTIFIER,
@IntegrationObjectID_822cc547 UNIQUEIDENTIFIER,
@Name_822cc547 NVARCHAR(255),
@DisplayName_822cc547 NVARCHAR(255),
@Description_822cc547 NVARCHAR(MAX),
@Category_822cc547 NVARCHAR(100),
@Type_822cc547 NVARCHAR(100),
@Length_822cc547 INT,
@Precision_822cc547 INT,
@Scale_822cc547 INT,
@AllowsNull_822cc547 BIT,
@DefaultValue_822cc547 NVARCHAR(255),
@IsPrimaryKey_822cc547 BIT,
@IsUniqueKey_822cc547 BIT,
@IsReadOnly_822cc547 BIT,
@IsRequired_822cc547 BIT,
@RelatedIntegrationObjectID_822cc547 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_822cc547 NVARCHAR(255),
@Sequence_822cc547 INT,
@Configuration_822cc547 NVARCHAR(MAX),
@Status_822cc547 NVARCHAR(25),
@IsCustom_822cc547 BIT,
@MetadataSource_822cc547 NVARCHAR(20)
SET
  @ID_822cc547 = 'DEA5033C-9955-5F01-B51C-E1942A888C76'
SET
  @IntegrationObjectID_822cc547 = 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD'
SET
  @Name_822cc547 = N'amount-currency'
SET
  @DisplayName_822cc547 = N'Amount Currency'
SET
  @Description_822cc547 = N'ISO currency code of the award amount; null when derived from the record summary.'
SET
  @Type_822cc547 = N'String'
SET
  @Length_822cc547 = 10
SET
  @AllowsNull_822cc547 = 1
SET
  @IsPrimaryKey_822cc547 = 0
SET
  @IsUniqueKey_822cc547 = 0
SET
  @IsReadOnly_822cc547 = 1
SET
  @IsRequired_822cc547 = 0
SET
  @Sequence_822cc547 = 22
SET
  @Status_822cc547 = N'Active'
SET
  @IsCustom_822cc547 = 0
SET
  @MetadataSource_822cc547 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_822cc547,
  @IntegrationObjectID = @IntegrationObjectID_822cc547,
  @Name = @Name_822cc547,
  @DisplayName = @DisplayName_822cc547,
  @Description = @Description_822cc547,
  @Category = @Category_822cc547,
  @Category_Clear = 1,
  @Type = @Type_822cc547,
  @Length = @Length_822cc547,
  @Precision = @Precision_822cc547,
  @Precision_Clear = 1,
  @Scale = @Scale_822cc547,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_822cc547,
  @DefaultValue = @DefaultValue_822cc547,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_822cc547,
  @IsUniqueKey = @IsUniqueKey_822cc547,
  @IsReadOnly = @IsReadOnly_822cc547,
  @IsRequired = @IsRequired_822cc547,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_822cc547,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_822cc547,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_822cc547,
  @Configuration = @Configuration_822cc547,
  @Configuration_Clear = 1,
  @Status = @Status_822cc547,
  @IsCustom = @IsCustom_822cc547,
  @MetadataSource = @MetadataSource_822cc547;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_9be77790 UNIQUEIDENTIFIER,
@IntegrationObjectID_9be77790 UNIQUEIDENTIFIER,
@Name_9be77790 NVARCHAR(255),
@DisplayName_9be77790 NVARCHAR(255),
@Description_9be77790 NVARCHAR(MAX),
@Category_9be77790 NVARCHAR(100),
@Type_9be77790 NVARCHAR(100),
@Length_9be77790 INT,
@Precision_9be77790 INT,
@Scale_9be77790 INT,
@AllowsNull_9be77790 BIT,
@DefaultValue_9be77790 NVARCHAR(255),
@IsPrimaryKey_9be77790 BIT,
@IsUniqueKey_9be77790 BIT,
@IsReadOnly_9be77790 BIT,
@IsRequired_9be77790 BIT,
@RelatedIntegrationObjectID_9be77790 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_9be77790 NVARCHAR(255),
@Sequence_9be77790 INT,
@Configuration_9be77790 NVARCHAR(MAX),
@Status_9be77790 NVARCHAR(25),
@IsCustom_9be77790 BIT,
@MetadataSource_9be77790 NVARCHAR(20)
SET
  @ID_9be77790 = '9605F469-E896-5943-B42C-14CA5E1E7712'
SET
  @IntegrationObjectID_9be77790 = 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD'
SET
  @Name_9be77790 = N'start-year'
SET
  @DisplayName_9be77790 = N'Start Year'
SET
  @Description_9be77790 = N'Year of the grant start date; ORCID dates are partial, so month/day may be absent.'
SET
  @Type_9be77790 = N'Integer'
SET
  @AllowsNull_9be77790 = 1
SET
  @IsPrimaryKey_9be77790 = 0
SET
  @IsUniqueKey_9be77790 = 0
SET
  @IsReadOnly_9be77790 = 1
SET
  @IsRequired_9be77790 = 0
SET
  @Sequence_9be77790 = 23
SET
  @Status_9be77790 = N'Active'
SET
  @IsCustom_9be77790 = 0
SET
  @MetadataSource_9be77790 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_9be77790,
  @IntegrationObjectID = @IntegrationObjectID_9be77790,
  @Name = @Name_9be77790,
  @DisplayName = @DisplayName_9be77790,
  @Description = @Description_9be77790,
  @Category = @Category_9be77790,
  @Category_Clear = 1,
  @Type = @Type_9be77790,
  @Length = @Length_9be77790,
  @Length_Clear = 1,
  @Precision = @Precision_9be77790,
  @Precision_Clear = 1,
  @Scale = @Scale_9be77790,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_9be77790,
  @DefaultValue = @DefaultValue_9be77790,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_9be77790,
  @IsUniqueKey = @IsUniqueKey_9be77790,
  @IsReadOnly = @IsReadOnly_9be77790,
  @IsRequired = @IsRequired_9be77790,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_9be77790,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_9be77790,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_9be77790,
  @Configuration = @Configuration_9be77790,
  @Configuration_Clear = 1,
  @Status = @Status_9be77790,
  @IsCustom = @IsCustom_9be77790,
  @MetadataSource = @MetadataSource_9be77790;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_9e190446 UNIQUEIDENTIFIER,
@IntegrationObjectID_9e190446 UNIQUEIDENTIFIER,
@Name_9e190446 NVARCHAR(255),
@DisplayName_9e190446 NVARCHAR(255),
@Description_9e190446 NVARCHAR(MAX),
@Category_9e190446 NVARCHAR(100),
@Type_9e190446 NVARCHAR(100),
@Length_9e190446 INT,
@Precision_9e190446 INT,
@Scale_9e190446 INT,
@AllowsNull_9e190446 BIT,
@DefaultValue_9e190446 NVARCHAR(255),
@IsPrimaryKey_9e190446 BIT,
@IsUniqueKey_9e190446 BIT,
@IsReadOnly_9e190446 BIT,
@IsRequired_9e190446 BIT,
@RelatedIntegrationObjectID_9e190446 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_9e190446 NVARCHAR(255),
@Sequence_9e190446 INT,
@Configuration_9e190446 NVARCHAR(MAX),
@Status_9e190446 NVARCHAR(25),
@IsCustom_9e190446 BIT,
@MetadataSource_9e190446 NVARCHAR(20)
SET
  @ID_9e190446 = '62A86041-51F0-52B1-BF32-1E5C1DBFA7E1'
SET
  @IntegrationObjectID_9e190446 = 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD'
SET
  @Name_9e190446 = N'start-month'
SET
  @DisplayName_9e190446 = N'Start Month'
SET
  @Description_9e190446 = N'Month (1-12) of the grant start date, when given.'
SET
  @Type_9e190446 = N'Integer'
SET
  @AllowsNull_9e190446 = 1
SET
  @IsPrimaryKey_9e190446 = 0
SET
  @IsUniqueKey_9e190446 = 0
SET
  @IsReadOnly_9e190446 = 1
SET
  @IsRequired_9e190446 = 0
SET
  @Sequence_9e190446 = 24
SET
  @Status_9e190446 = N'Active'
SET
  @IsCustom_9e190446 = 0
SET
  @MetadataSource_9e190446 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_9e190446,
  @IntegrationObjectID = @IntegrationObjectID_9e190446,
  @Name = @Name_9e190446,
  @DisplayName = @DisplayName_9e190446,
  @Description = @Description_9e190446,
  @Category = @Category_9e190446,
  @Category_Clear = 1,
  @Type = @Type_9e190446,
  @Length = @Length_9e190446,
  @Length_Clear = 1,
  @Precision = @Precision_9e190446,
  @Precision_Clear = 1,
  @Scale = @Scale_9e190446,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_9e190446,
  @DefaultValue = @DefaultValue_9e190446,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_9e190446,
  @IsUniqueKey = @IsUniqueKey_9e190446,
  @IsReadOnly = @IsReadOnly_9e190446,
  @IsRequired = @IsRequired_9e190446,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_9e190446,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_9e190446,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_9e190446,
  @Configuration = @Configuration_9e190446,
  @Configuration_Clear = 1,
  @Status = @Status_9e190446,
  @IsCustom = @IsCustom_9e190446,
  @MetadataSource = @MetadataSource_9e190446;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_52eef396 UNIQUEIDENTIFIER,
@IntegrationObjectID_52eef396 UNIQUEIDENTIFIER,
@Name_52eef396 NVARCHAR(255),
@DisplayName_52eef396 NVARCHAR(255),
@Description_52eef396 NVARCHAR(MAX),
@Category_52eef396 NVARCHAR(100),
@Type_52eef396 NVARCHAR(100),
@Length_52eef396 INT,
@Precision_52eef396 INT,
@Scale_52eef396 INT,
@AllowsNull_52eef396 BIT,
@DefaultValue_52eef396 NVARCHAR(255),
@IsPrimaryKey_52eef396 BIT,
@IsUniqueKey_52eef396 BIT,
@IsReadOnly_52eef396 BIT,
@IsRequired_52eef396 BIT,
@RelatedIntegrationObjectID_52eef396 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_52eef396 NVARCHAR(255),
@Sequence_52eef396 INT,
@Configuration_52eef396 NVARCHAR(MAX),
@Status_52eef396 NVARCHAR(25),
@IsCustom_52eef396 BIT,
@MetadataSource_52eef396 NVARCHAR(20)
SET
  @ID_52eef396 = '0DADC8E5-5763-5541-A3F4-37EDB8613DED'
SET
  @IntegrationObjectID_52eef396 = 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD'
SET
  @Name_52eef396 = N'start-day'
SET
  @DisplayName_52eef396 = N'Start Day'
SET
  @Description_52eef396 = N'Day of month of the grant start date, when given.'
SET
  @Type_52eef396 = N'Integer'
SET
  @AllowsNull_52eef396 = 1
SET
  @IsPrimaryKey_52eef396 = 0
SET
  @IsUniqueKey_52eef396 = 0
SET
  @IsReadOnly_52eef396 = 1
SET
  @IsRequired_52eef396 = 0
SET
  @Sequence_52eef396 = 25
SET
  @Status_52eef396 = N'Active'
SET
  @IsCustom_52eef396 = 0
SET
  @MetadataSource_52eef396 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_52eef396,
  @IntegrationObjectID = @IntegrationObjectID_52eef396,
  @Name = @Name_52eef396,
  @DisplayName = @DisplayName_52eef396,
  @Description = @Description_52eef396,
  @Category = @Category_52eef396,
  @Category_Clear = 1,
  @Type = @Type_52eef396,
  @Length = @Length_52eef396,
  @Length_Clear = 1,
  @Precision = @Precision_52eef396,
  @Precision_Clear = 1,
  @Scale = @Scale_52eef396,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_52eef396,
  @DefaultValue = @DefaultValue_52eef396,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_52eef396,
  @IsUniqueKey = @IsUniqueKey_52eef396,
  @IsReadOnly = @IsReadOnly_52eef396,
  @IsRequired = @IsRequired_52eef396,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_52eef396,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_52eef396,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_52eef396,
  @Configuration = @Configuration_52eef396,
  @Configuration_Clear = 1,
  @Status = @Status_52eef396,
  @IsCustom = @IsCustom_52eef396,
  @MetadataSource = @MetadataSource_52eef396;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_b11afb2e UNIQUEIDENTIFIER,
@IntegrationObjectID_b11afb2e UNIQUEIDENTIFIER,
@Name_b11afb2e NVARCHAR(255),
@DisplayName_b11afb2e NVARCHAR(255),
@Description_b11afb2e NVARCHAR(MAX),
@Category_b11afb2e NVARCHAR(100),
@Type_b11afb2e NVARCHAR(100),
@Length_b11afb2e INT,
@Precision_b11afb2e INT,
@Scale_b11afb2e INT,
@AllowsNull_b11afb2e BIT,
@DefaultValue_b11afb2e NVARCHAR(255),
@IsPrimaryKey_b11afb2e BIT,
@IsUniqueKey_b11afb2e BIT,
@IsReadOnly_b11afb2e BIT,
@IsRequired_b11afb2e BIT,
@RelatedIntegrationObjectID_b11afb2e UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_b11afb2e NVARCHAR(255),
@Sequence_b11afb2e INT,
@Configuration_b11afb2e NVARCHAR(MAX),
@Status_b11afb2e NVARCHAR(25),
@IsCustom_b11afb2e BIT,
@MetadataSource_b11afb2e NVARCHAR(20)
SET
  @ID_b11afb2e = '693AD5B3-1169-57C9-B2D7-2493AF9E0341'
SET
  @IntegrationObjectID_b11afb2e = 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD'
SET
  @Name_b11afb2e = N'end-year'
SET
  @DisplayName_b11afb2e = N'End Year'
SET
  @Description_b11afb2e = N'Year of the grant end date; ORCID dates are partial, so month/day may be absent.'
SET
  @Type_b11afb2e = N'Integer'
SET
  @AllowsNull_b11afb2e = 1
SET
  @IsPrimaryKey_b11afb2e = 0
SET
  @IsUniqueKey_b11afb2e = 0
SET
  @IsReadOnly_b11afb2e = 1
SET
  @IsRequired_b11afb2e = 0
SET
  @Sequence_b11afb2e = 26
SET
  @Status_b11afb2e = N'Active'
SET
  @IsCustom_b11afb2e = 0
SET
  @MetadataSource_b11afb2e = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_b11afb2e,
  @IntegrationObjectID = @IntegrationObjectID_b11afb2e,
  @Name = @Name_b11afb2e,
  @DisplayName = @DisplayName_b11afb2e,
  @Description = @Description_b11afb2e,
  @Category = @Category_b11afb2e,
  @Category_Clear = 1,
  @Type = @Type_b11afb2e,
  @Length = @Length_b11afb2e,
  @Length_Clear = 1,
  @Precision = @Precision_b11afb2e,
  @Precision_Clear = 1,
  @Scale = @Scale_b11afb2e,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_b11afb2e,
  @DefaultValue = @DefaultValue_b11afb2e,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_b11afb2e,
  @IsUniqueKey = @IsUniqueKey_b11afb2e,
  @IsReadOnly = @IsReadOnly_b11afb2e,
  @IsRequired = @IsRequired_b11afb2e,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_b11afb2e,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_b11afb2e,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_b11afb2e,
  @Configuration = @Configuration_b11afb2e,
  @Configuration_Clear = 1,
  @Status = @Status_b11afb2e,
  @IsCustom = @IsCustom_b11afb2e,
  @MetadataSource = @MetadataSource_b11afb2e;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_dc3d9883 UNIQUEIDENTIFIER,
@IntegrationObjectID_dc3d9883 UNIQUEIDENTIFIER,
@Name_dc3d9883 NVARCHAR(255),
@DisplayName_dc3d9883 NVARCHAR(255),
@Description_dc3d9883 NVARCHAR(MAX),
@Category_dc3d9883 NVARCHAR(100),
@Type_dc3d9883 NVARCHAR(100),
@Length_dc3d9883 INT,
@Precision_dc3d9883 INT,
@Scale_dc3d9883 INT,
@AllowsNull_dc3d9883 BIT,
@DefaultValue_dc3d9883 NVARCHAR(255),
@IsPrimaryKey_dc3d9883 BIT,
@IsUniqueKey_dc3d9883 BIT,
@IsReadOnly_dc3d9883 BIT,
@IsRequired_dc3d9883 BIT,
@RelatedIntegrationObjectID_dc3d9883 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_dc3d9883 NVARCHAR(255),
@Sequence_dc3d9883 INT,
@Configuration_dc3d9883 NVARCHAR(MAX),
@Status_dc3d9883 NVARCHAR(25),
@IsCustom_dc3d9883 BIT,
@MetadataSource_dc3d9883 NVARCHAR(20)
SET
  @ID_dc3d9883 = '0478C91B-8B23-5BF0-9631-403F90EFF0A0'
SET
  @IntegrationObjectID_dc3d9883 = 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD'
SET
  @Name_dc3d9883 = N'end-month'
SET
  @DisplayName_dc3d9883 = N'End Month'
SET
  @Description_dc3d9883 = N'Month (1-12) of the grant end date, when given.'
SET
  @Type_dc3d9883 = N'Integer'
SET
  @AllowsNull_dc3d9883 = 1
SET
  @IsPrimaryKey_dc3d9883 = 0
SET
  @IsUniqueKey_dc3d9883 = 0
SET
  @IsReadOnly_dc3d9883 = 1
SET
  @IsRequired_dc3d9883 = 0
SET
  @Sequence_dc3d9883 = 27
SET
  @Status_dc3d9883 = N'Active'
SET
  @IsCustom_dc3d9883 = 0
SET
  @MetadataSource_dc3d9883 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_dc3d9883,
  @IntegrationObjectID = @IntegrationObjectID_dc3d9883,
  @Name = @Name_dc3d9883,
  @DisplayName = @DisplayName_dc3d9883,
  @Description = @Description_dc3d9883,
  @Category = @Category_dc3d9883,
  @Category_Clear = 1,
  @Type = @Type_dc3d9883,
  @Length = @Length_dc3d9883,
  @Length_Clear = 1,
  @Precision = @Precision_dc3d9883,
  @Precision_Clear = 1,
  @Scale = @Scale_dc3d9883,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_dc3d9883,
  @DefaultValue = @DefaultValue_dc3d9883,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_dc3d9883,
  @IsUniqueKey = @IsUniqueKey_dc3d9883,
  @IsReadOnly = @IsReadOnly_dc3d9883,
  @IsRequired = @IsRequired_dc3d9883,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_dc3d9883,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_dc3d9883,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_dc3d9883,
  @Configuration = @Configuration_dc3d9883,
  @Configuration_Clear = 1,
  @Status = @Status_dc3d9883,
  @IsCustom = @IsCustom_dc3d9883,
  @MetadataSource = @MetadataSource_dc3d9883;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_100e4090 UNIQUEIDENTIFIER,
@IntegrationObjectID_100e4090 UNIQUEIDENTIFIER,
@Name_100e4090 NVARCHAR(255),
@DisplayName_100e4090 NVARCHAR(255),
@Description_100e4090 NVARCHAR(MAX),
@Category_100e4090 NVARCHAR(100),
@Type_100e4090 NVARCHAR(100),
@Length_100e4090 INT,
@Precision_100e4090 INT,
@Scale_100e4090 INT,
@AllowsNull_100e4090 BIT,
@DefaultValue_100e4090 NVARCHAR(255),
@IsPrimaryKey_100e4090 BIT,
@IsUniqueKey_100e4090 BIT,
@IsReadOnly_100e4090 BIT,
@IsRequired_100e4090 BIT,
@RelatedIntegrationObjectID_100e4090 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_100e4090 NVARCHAR(255),
@Sequence_100e4090 INT,
@Configuration_100e4090 NVARCHAR(MAX),
@Status_100e4090 NVARCHAR(25),
@IsCustom_100e4090 BIT,
@MetadataSource_100e4090 NVARCHAR(20)
SET
  @ID_100e4090 = 'EC8A5B52-D9E8-5637-B469-EE24B5B483AD'
SET
  @IntegrationObjectID_100e4090 = 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD'
SET
  @Name_100e4090 = N'end-day'
SET
  @DisplayName_100e4090 = N'End Day'
SET
  @Description_100e4090 = N'Day of month of the grant end date, when given.'
SET
  @Type_100e4090 = N'Integer'
SET
  @AllowsNull_100e4090 = 1
SET
  @IsPrimaryKey_100e4090 = 0
SET
  @IsUniqueKey_100e4090 = 0
SET
  @IsReadOnly_100e4090 = 1
SET
  @IsRequired_100e4090 = 0
SET
  @Sequence_100e4090 = 28
SET
  @Status_100e4090 = N'Active'
SET
  @IsCustom_100e4090 = 0
SET
  @MetadataSource_100e4090 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_100e4090,
  @IntegrationObjectID = @IntegrationObjectID_100e4090,
  @Name = @Name_100e4090,
  @DisplayName = @DisplayName_100e4090,
  @Description = @Description_100e4090,
  @Category = @Category_100e4090,
  @Category_Clear = 1,
  @Type = @Type_100e4090,
  @Length = @Length_100e4090,
  @Length_Clear = 1,
  @Precision = @Precision_100e4090,
  @Precision_Clear = 1,
  @Scale = @Scale_100e4090,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_100e4090,
  @DefaultValue = @DefaultValue_100e4090,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_100e4090,
  @IsUniqueKey = @IsUniqueKey_100e4090,
  @IsReadOnly = @IsReadOnly_100e4090,
  @IsRequired = @IsRequired_100e4090,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_100e4090,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_100e4090,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_100e4090,
  @Configuration = @Configuration_100e4090,
  @Configuration_Clear = 1,
  @Status = @Status_100e4090,
  @IsCustom = @IsCustom_100e4090,
  @MetadataSource = @MetadataSource_100e4090;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_8c62342e UNIQUEIDENTIFIER,
@IntegrationObjectID_8c62342e UNIQUEIDENTIFIER,
@Name_8c62342e NVARCHAR(255),
@DisplayName_8c62342e NVARCHAR(255),
@Description_8c62342e NVARCHAR(MAX),
@Category_8c62342e NVARCHAR(100),
@Type_8c62342e NVARCHAR(100),
@Length_8c62342e INT,
@Precision_8c62342e INT,
@Scale_8c62342e INT,
@AllowsNull_8c62342e BIT,
@DefaultValue_8c62342e NVARCHAR(255),
@IsPrimaryKey_8c62342e BIT,
@IsUniqueKey_8c62342e BIT,
@IsReadOnly_8c62342e BIT,
@IsRequired_8c62342e BIT,
@RelatedIntegrationObjectID_8c62342e UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_8c62342e NVARCHAR(255),
@Sequence_8c62342e INT,
@Configuration_8c62342e NVARCHAR(MAX),
@Status_8c62342e NVARCHAR(25),
@IsCustom_8c62342e BIT,
@MetadataSource_8c62342e NVARCHAR(20)
SET
  @ID_8c62342e = '17416E35-8C4D-5BA9-92C1-F8A4E49CCDBD'
SET
  @IntegrationObjectID_8c62342e = 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD'
SET
  @Name_8c62342e = N'organization-name'
SET
  @DisplayName_8c62342e = N'Organization Name'
SET
  @Description_8c62342e = N'Name of the funding organization. Lifted from organization.name.'
SET
  @Type_8c62342e = N'String'
SET
  @Length_8c62342e = 1000
SET
  @AllowsNull_8c62342e = 1
SET
  @IsPrimaryKey_8c62342e = 0
SET
  @IsUniqueKey_8c62342e = 0
SET
  @IsReadOnly_8c62342e = 1
SET
  @IsRequired_8c62342e = 0
SET
  @Sequence_8c62342e = 29
SET
  @Status_8c62342e = N'Active'
SET
  @IsCustom_8c62342e = 0
SET
  @MetadataSource_8c62342e = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_8c62342e,
  @IntegrationObjectID = @IntegrationObjectID_8c62342e,
  @Name = @Name_8c62342e,
  @DisplayName = @DisplayName_8c62342e,
  @Description = @Description_8c62342e,
  @Category = @Category_8c62342e,
  @Category_Clear = 1,
  @Type = @Type_8c62342e,
  @Length = @Length_8c62342e,
  @Precision = @Precision_8c62342e,
  @Precision_Clear = 1,
  @Scale = @Scale_8c62342e,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_8c62342e,
  @DefaultValue = @DefaultValue_8c62342e,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_8c62342e,
  @IsUniqueKey = @IsUniqueKey_8c62342e,
  @IsReadOnly = @IsReadOnly_8c62342e,
  @IsRequired = @IsRequired_8c62342e,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_8c62342e,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_8c62342e,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_8c62342e,
  @Configuration = @Configuration_8c62342e,
  @Configuration_Clear = 1,
  @Status = @Status_8c62342e,
  @IsCustom = @IsCustom_8c62342e,
  @MetadataSource = @MetadataSource_8c62342e;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_2c686319 UNIQUEIDENTIFIER,
@IntegrationObjectID_2c686319 UNIQUEIDENTIFIER,
@Name_2c686319 NVARCHAR(255),
@DisplayName_2c686319 NVARCHAR(255),
@Description_2c686319 NVARCHAR(MAX),
@Category_2c686319 NVARCHAR(100),
@Type_2c686319 NVARCHAR(100),
@Length_2c686319 INT,
@Precision_2c686319 INT,
@Scale_2c686319 INT,
@AllowsNull_2c686319 BIT,
@DefaultValue_2c686319 NVARCHAR(255),
@IsPrimaryKey_2c686319 BIT,
@IsUniqueKey_2c686319 BIT,
@IsReadOnly_2c686319 BIT,
@IsRequired_2c686319 BIT,
@RelatedIntegrationObjectID_2c686319 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_2c686319 NVARCHAR(255),
@Sequence_2c686319 INT,
@Configuration_2c686319 NVARCHAR(MAX),
@Status_2c686319 NVARCHAR(25),
@IsCustom_2c686319 BIT,
@MetadataSource_2c686319 NVARCHAR(20)
SET
  @ID_2c686319 = '4ECB1C98-9AFB-5C2B-9DC4-CBF6C9348625'
SET
  @IntegrationObjectID_2c686319 = 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD'
SET
  @Name_2c686319 = N'organization-city'
SET
  @DisplayName_2c686319 = N'Organization City'
SET
  @Description_2c686319 = N'City of the funding organization. Lifted from organization.address.city.'
SET
  @Type_2c686319 = N'String'
SET
  @Length_2c686319 = 255
SET
  @AllowsNull_2c686319 = 1
SET
  @IsPrimaryKey_2c686319 = 0
SET
  @IsUniqueKey_2c686319 = 0
SET
  @IsReadOnly_2c686319 = 1
SET
  @IsRequired_2c686319 = 0
SET
  @Sequence_2c686319 = 30
SET
  @Status_2c686319 = N'Active'
SET
  @IsCustom_2c686319 = 0
SET
  @MetadataSource_2c686319 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_2c686319,
  @IntegrationObjectID = @IntegrationObjectID_2c686319,
  @Name = @Name_2c686319,
  @DisplayName = @DisplayName_2c686319,
  @Description = @Description_2c686319,
  @Category = @Category_2c686319,
  @Category_Clear = 1,
  @Type = @Type_2c686319,
  @Length = @Length_2c686319,
  @Precision = @Precision_2c686319,
  @Precision_Clear = 1,
  @Scale = @Scale_2c686319,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_2c686319,
  @DefaultValue = @DefaultValue_2c686319,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_2c686319,
  @IsUniqueKey = @IsUniqueKey_2c686319,
  @IsReadOnly = @IsReadOnly_2c686319,
  @IsRequired = @IsRequired_2c686319,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_2c686319,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_2c686319,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_2c686319,
  @Configuration = @Configuration_2c686319,
  @Configuration_Clear = 1,
  @Status = @Status_2c686319,
  @IsCustom = @IsCustom_2c686319,
  @MetadataSource = @MetadataSource_2c686319;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_551abeda UNIQUEIDENTIFIER,
@IntegrationObjectID_551abeda UNIQUEIDENTIFIER,
@Name_551abeda NVARCHAR(255),
@DisplayName_551abeda NVARCHAR(255),
@Description_551abeda NVARCHAR(MAX),
@Category_551abeda NVARCHAR(100),
@Type_551abeda NVARCHAR(100),
@Length_551abeda INT,
@Precision_551abeda INT,
@Scale_551abeda INT,
@AllowsNull_551abeda BIT,
@DefaultValue_551abeda NVARCHAR(255),
@IsPrimaryKey_551abeda BIT,
@IsUniqueKey_551abeda BIT,
@IsReadOnly_551abeda BIT,
@IsRequired_551abeda BIT,
@RelatedIntegrationObjectID_551abeda UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_551abeda NVARCHAR(255),
@Sequence_551abeda INT,
@Configuration_551abeda NVARCHAR(MAX),
@Status_551abeda NVARCHAR(25),
@IsCustom_551abeda BIT,
@MetadataSource_551abeda NVARCHAR(20)
SET
  @ID_551abeda = 'AAC12F96-9AEA-5C8D-80A5-FF50ECBC642F'
SET
  @IntegrationObjectID_551abeda = 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD'
SET
  @Name_551abeda = N'organization-region'
SET
  @DisplayName_551abeda = N'Organization Region'
SET
  @Description_551abeda = N'Region/state of the funding organization. Lifted from organization.address.region.'
SET
  @Type_551abeda = N'String'
SET
  @Length_551abeda = 255
SET
  @AllowsNull_551abeda = 1
SET
  @IsPrimaryKey_551abeda = 0
SET
  @IsUniqueKey_551abeda = 0
SET
  @IsReadOnly_551abeda = 1
SET
  @IsRequired_551abeda = 0
SET
  @Sequence_551abeda = 31
SET
  @Status_551abeda = N'Active'
SET
  @IsCustom_551abeda = 0
SET
  @MetadataSource_551abeda = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_551abeda,
  @IntegrationObjectID = @IntegrationObjectID_551abeda,
  @Name = @Name_551abeda,
  @DisplayName = @DisplayName_551abeda,
  @Description = @Description_551abeda,
  @Category = @Category_551abeda,
  @Category_Clear = 1,
  @Type = @Type_551abeda,
  @Length = @Length_551abeda,
  @Precision = @Precision_551abeda,
  @Precision_Clear = 1,
  @Scale = @Scale_551abeda,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_551abeda,
  @DefaultValue = @DefaultValue_551abeda,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_551abeda,
  @IsUniqueKey = @IsUniqueKey_551abeda,
  @IsReadOnly = @IsReadOnly_551abeda,
  @IsRequired = @IsRequired_551abeda,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_551abeda,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_551abeda,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_551abeda,
  @Configuration = @Configuration_551abeda,
  @Configuration_Clear = 1,
  @Status = @Status_551abeda,
  @IsCustom = @IsCustom_551abeda,
  @MetadataSource = @MetadataSource_551abeda;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_0f04f2ac UNIQUEIDENTIFIER,
@IntegrationObjectID_0f04f2ac UNIQUEIDENTIFIER,
@Name_0f04f2ac NVARCHAR(255),
@DisplayName_0f04f2ac NVARCHAR(255),
@Description_0f04f2ac NVARCHAR(MAX),
@Category_0f04f2ac NVARCHAR(100),
@Type_0f04f2ac NVARCHAR(100),
@Length_0f04f2ac INT,
@Precision_0f04f2ac INT,
@Scale_0f04f2ac INT,
@AllowsNull_0f04f2ac BIT,
@DefaultValue_0f04f2ac NVARCHAR(255),
@IsPrimaryKey_0f04f2ac BIT,
@IsUniqueKey_0f04f2ac BIT,
@IsReadOnly_0f04f2ac BIT,
@IsRequired_0f04f2ac BIT,
@RelatedIntegrationObjectID_0f04f2ac UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_0f04f2ac NVARCHAR(255),
@Sequence_0f04f2ac INT,
@Configuration_0f04f2ac NVARCHAR(MAX),
@Status_0f04f2ac NVARCHAR(25),
@IsCustom_0f04f2ac BIT,
@MetadataSource_0f04f2ac NVARCHAR(20)
SET
  @ID_0f04f2ac = '3D0FC80D-14D8-5B7D-A145-FCB1795980DD'
SET
  @IntegrationObjectID_0f04f2ac = 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD'
SET
  @Name_0f04f2ac = N'organization-country'
SET
  @DisplayName_0f04f2ac = N'Organization Country'
SET
  @Description_0f04f2ac = N'ISO country code of the funding organization. Lifted from organization.address.country.'
SET
  @Type_0f04f2ac = N'String'
SET
  @Length_0f04f2ac = 50
SET
  @AllowsNull_0f04f2ac = 1
SET
  @IsPrimaryKey_0f04f2ac = 0
SET
  @IsUniqueKey_0f04f2ac = 0
SET
  @IsReadOnly_0f04f2ac = 1
SET
  @IsRequired_0f04f2ac = 0
SET
  @Sequence_0f04f2ac = 32
SET
  @Status_0f04f2ac = N'Active'
SET
  @IsCustom_0f04f2ac = 0
SET
  @MetadataSource_0f04f2ac = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_0f04f2ac,
  @IntegrationObjectID = @IntegrationObjectID_0f04f2ac,
  @Name = @Name_0f04f2ac,
  @DisplayName = @DisplayName_0f04f2ac,
  @Description = @Description_0f04f2ac,
  @Category = @Category_0f04f2ac,
  @Category_Clear = 1,
  @Type = @Type_0f04f2ac,
  @Length = @Length_0f04f2ac,
  @Precision = @Precision_0f04f2ac,
  @Precision_Clear = 1,
  @Scale = @Scale_0f04f2ac,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_0f04f2ac,
  @DefaultValue = @DefaultValue_0f04f2ac,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_0f04f2ac,
  @IsUniqueKey = @IsUniqueKey_0f04f2ac,
  @IsReadOnly = @IsReadOnly_0f04f2ac,
  @IsRequired = @IsRequired_0f04f2ac,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_0f04f2ac,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_0f04f2ac,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_0f04f2ac,
  @Configuration = @Configuration_0f04f2ac,
  @Configuration_Clear = 1,
  @Status = @Status_0f04f2ac,
  @IsCustom = @IsCustom_0f04f2ac,
  @MetadataSource = @MetadataSource_0f04f2ac;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_91f9aa01 UNIQUEIDENTIFIER,
@IntegrationObjectID_91f9aa01 UNIQUEIDENTIFIER,
@Name_91f9aa01 NVARCHAR(255),
@DisplayName_91f9aa01 NVARCHAR(255),
@Description_91f9aa01 NVARCHAR(MAX),
@Category_91f9aa01 NVARCHAR(100),
@Type_91f9aa01 NVARCHAR(100),
@Length_91f9aa01 INT,
@Precision_91f9aa01 INT,
@Scale_91f9aa01 INT,
@AllowsNull_91f9aa01 BIT,
@DefaultValue_91f9aa01 NVARCHAR(255),
@IsPrimaryKey_91f9aa01 BIT,
@IsUniqueKey_91f9aa01 BIT,
@IsReadOnly_91f9aa01 BIT,
@IsRequired_91f9aa01 BIT,
@RelatedIntegrationObjectID_91f9aa01 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_91f9aa01 NVARCHAR(255),
@Sequence_91f9aa01 INT,
@Configuration_91f9aa01 NVARCHAR(MAX),
@Status_91f9aa01 NVARCHAR(25),
@IsCustom_91f9aa01 BIT,
@MetadataSource_91f9aa01 NVARCHAR(20)
SET
  @ID_91f9aa01 = 'C7C0B84E-0E70-5591-A82B-0C64B70F21C1'
SET
  @IntegrationObjectID_91f9aa01 = 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD'
SET
  @Name_91f9aa01 = N'organization-disambiguated-id'
SET
  @DisplayName_91f9aa01 = N'Organization Disambiguated Id'
SET
  @Description_91f9aa01 = N'Canonical identifier of the funding organization in the disambiguation source (e.g. a RINGGOLD or ROR id), so the same institution matches across records.'
SET
  @Type_91f9aa01 = N'String'
SET
  @Length_91f9aa01 = 255
SET
  @AllowsNull_91f9aa01 = 1
SET
  @IsPrimaryKey_91f9aa01 = 0
SET
  @IsUniqueKey_91f9aa01 = 0
SET
  @IsReadOnly_91f9aa01 = 1
SET
  @IsRequired_91f9aa01 = 0
SET
  @Sequence_91f9aa01 = 33
SET
  @Status_91f9aa01 = N'Active'
SET
  @IsCustom_91f9aa01 = 0
SET
  @MetadataSource_91f9aa01 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_91f9aa01,
  @IntegrationObjectID = @IntegrationObjectID_91f9aa01,
  @Name = @Name_91f9aa01,
  @DisplayName = @DisplayName_91f9aa01,
  @Description = @Description_91f9aa01,
  @Category = @Category_91f9aa01,
  @Category_Clear = 1,
  @Type = @Type_91f9aa01,
  @Length = @Length_91f9aa01,
  @Precision = @Precision_91f9aa01,
  @Precision_Clear = 1,
  @Scale = @Scale_91f9aa01,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_91f9aa01,
  @DefaultValue = @DefaultValue_91f9aa01,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_91f9aa01,
  @IsUniqueKey = @IsUniqueKey_91f9aa01,
  @IsReadOnly = @IsReadOnly_91f9aa01,
  @IsRequired = @IsRequired_91f9aa01,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_91f9aa01,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_91f9aa01,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_91f9aa01,
  @Configuration = @Configuration_91f9aa01,
  @Configuration_Clear = 1,
  @Status = @Status_91f9aa01,
  @IsCustom = @IsCustom_91f9aa01,
  @MetadataSource = @MetadataSource_91f9aa01;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_0050cd99 UNIQUEIDENTIFIER,
@IntegrationObjectID_0050cd99 UNIQUEIDENTIFIER,
@Name_0050cd99 NVARCHAR(255),
@DisplayName_0050cd99 NVARCHAR(255),
@Description_0050cd99 NVARCHAR(MAX),
@Category_0050cd99 NVARCHAR(100),
@Type_0050cd99 NVARCHAR(100),
@Length_0050cd99 INT,
@Precision_0050cd99 INT,
@Scale_0050cd99 INT,
@AllowsNull_0050cd99 BIT,
@DefaultValue_0050cd99 NVARCHAR(255),
@IsPrimaryKey_0050cd99 BIT,
@IsUniqueKey_0050cd99 BIT,
@IsReadOnly_0050cd99 BIT,
@IsRequired_0050cd99 BIT,
@RelatedIntegrationObjectID_0050cd99 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_0050cd99 NVARCHAR(255),
@Sequence_0050cd99 INT,
@Configuration_0050cd99 NVARCHAR(MAX),
@Status_0050cd99 NVARCHAR(25),
@IsCustom_0050cd99 BIT,
@MetadataSource_0050cd99 NVARCHAR(20)
SET
  @ID_0050cd99 = 'A5C7DA43-BA72-59FE-92B8-60620FC7D437'
SET
  @IntegrationObjectID_0050cd99 = 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD'
SET
  @Name_0050cd99 = N'organization-disambiguation-source'
SET
  @DisplayName_0050cd99 = N'Organization Disambiguation Source'
SET
  @Description_0050cd99 = N'Registry the disambiguated id comes from (RINGGOLD, ROR, FUNDREF, GRID, LEI).'
SET
  @Type_0050cd99 = N'String'
SET
  @Length_0050cd99 = 100
SET
  @AllowsNull_0050cd99 = 1
SET
  @IsPrimaryKey_0050cd99 = 0
SET
  @IsUniqueKey_0050cd99 = 0
SET
  @IsReadOnly_0050cd99 = 1
SET
  @IsRequired_0050cd99 = 0
SET
  @Sequence_0050cd99 = 34
SET
  @Status_0050cd99 = N'Active'
SET
  @IsCustom_0050cd99 = 0
SET
  @MetadataSource_0050cd99 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_0050cd99,
  @IntegrationObjectID = @IntegrationObjectID_0050cd99,
  @Name = @Name_0050cd99,
  @DisplayName = @DisplayName_0050cd99,
  @Description = @Description_0050cd99,
  @Category = @Category_0050cd99,
  @Category_Clear = 1,
  @Type = @Type_0050cd99,
  @Length = @Length_0050cd99,
  @Precision = @Precision_0050cd99,
  @Precision_Clear = 1,
  @Scale = @Scale_0050cd99,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_0050cd99,
  @DefaultValue = @DefaultValue_0050cd99,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_0050cd99,
  @IsUniqueKey = @IsUniqueKey_0050cd99,
  @IsReadOnly = @IsReadOnly_0050cd99,
  @IsRequired = @IsRequired_0050cd99,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_0050cd99,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_0050cd99,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_0050cd99,
  @Configuration = @Configuration_0050cd99,
  @Configuration_Clear = 1,
  @Status = @Status_0050cd99,
  @IsCustom = @IsCustom_0050cd99,
  @MetadataSource = @MetadataSource_0050cd99;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_6ec8f0af UNIQUEIDENTIFIER,
@IntegrationObjectID_6ec8f0af UNIQUEIDENTIFIER,
@Name_6ec8f0af NVARCHAR(255),
@DisplayName_6ec8f0af NVARCHAR(255),
@Description_6ec8f0af NVARCHAR(MAX),
@Category_6ec8f0af NVARCHAR(100),
@Type_6ec8f0af NVARCHAR(100),
@Length_6ec8f0af INT,
@Precision_6ec8f0af INT,
@Scale_6ec8f0af INT,
@AllowsNull_6ec8f0af BIT,
@DefaultValue_6ec8f0af NVARCHAR(255),
@IsPrimaryKey_6ec8f0af BIT,
@IsUniqueKey_6ec8f0af BIT,
@IsReadOnly_6ec8f0af BIT,
@IsRequired_6ec8f0af BIT,
@RelatedIntegrationObjectID_6ec8f0af UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_6ec8f0af NVARCHAR(255),
@Sequence_6ec8f0af INT,
@Configuration_6ec8f0af NVARCHAR(MAX),
@Status_6ec8f0af NVARCHAR(25),
@IsCustom_6ec8f0af BIT,
@MetadataSource_6ec8f0af NVARCHAR(20)
SET
  @ID_6ec8f0af = 'A3CC5D35-A91B-5C8F-8377-0FC30FCDC20E'
SET
  @IntegrationObjectID_6ec8f0af = 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD'
SET
  @Name_6ec8f0af = N'source-name'
SET
  @DisplayName_6ec8f0af = N'Source Name'
SET
  @Description_6ec8f0af = N'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.'
SET
  @Type_6ec8f0af = N'String'
SET
  @Length_6ec8f0af = 500
SET
  @AllowsNull_6ec8f0af = 1
SET
  @IsPrimaryKey_6ec8f0af = 0
SET
  @IsUniqueKey_6ec8f0af = 0
SET
  @IsReadOnly_6ec8f0af = 1
SET
  @IsRequired_6ec8f0af = 0
SET
  @Sequence_6ec8f0af = 35
SET
  @Status_6ec8f0af = N'Active'
SET
  @IsCustom_6ec8f0af = 0
SET
  @MetadataSource_6ec8f0af = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_6ec8f0af,
  @IntegrationObjectID = @IntegrationObjectID_6ec8f0af,
  @Name = @Name_6ec8f0af,
  @DisplayName = @DisplayName_6ec8f0af,
  @Description = @Description_6ec8f0af,
  @Category = @Category_6ec8f0af,
  @Category_Clear = 1,
  @Type = @Type_6ec8f0af,
  @Length = @Length_6ec8f0af,
  @Precision = @Precision_6ec8f0af,
  @Precision_Clear = 1,
  @Scale = @Scale_6ec8f0af,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_6ec8f0af,
  @DefaultValue = @DefaultValue_6ec8f0af,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_6ec8f0af,
  @IsUniqueKey = @IsUniqueKey_6ec8f0af,
  @IsReadOnly = @IsReadOnly_6ec8f0af,
  @IsRequired = @IsRequired_6ec8f0af,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_6ec8f0af,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_6ec8f0af,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_6ec8f0af,
  @Configuration = @Configuration_6ec8f0af,
  @Configuration_Clear = 1,
  @Status = @Status_6ec8f0af,
  @IsCustom = @IsCustom_6ec8f0af,
  @MetadataSource = @MetadataSource_6ec8f0af;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_118e2781 UNIQUEIDENTIFIER,
@IntegrationObjectID_118e2781 UNIQUEIDENTIFIER,
@Name_118e2781 NVARCHAR(255),
@DisplayName_118e2781 NVARCHAR(255),
@Description_118e2781 NVARCHAR(MAX),
@Category_118e2781 NVARCHAR(100),
@Type_118e2781 NVARCHAR(100),
@Length_118e2781 INT,
@Precision_118e2781 INT,
@Scale_118e2781 INT,
@AllowsNull_118e2781 BIT,
@DefaultValue_118e2781 NVARCHAR(255),
@IsPrimaryKey_118e2781 BIT,
@IsUniqueKey_118e2781 BIT,
@IsReadOnly_118e2781 BIT,
@IsRequired_118e2781 BIT,
@RelatedIntegrationObjectID_118e2781 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_118e2781 NVARCHAR(255),
@Sequence_118e2781 INT,
@Configuration_118e2781 NVARCHAR(MAX),
@Status_118e2781 NVARCHAR(25),
@IsCustom_118e2781 BIT,
@MetadataSource_118e2781 NVARCHAR(20)
SET
  @ID_118e2781 = 'B36FBBC7-9E85-5BE5-884D-44D801322EEF'
SET
  @IntegrationObjectID_118e2781 = 'BEF82B0E-3D8F-4E5E-BB7B-671D6B0E31AD'
SET
  @Name_118e2781 = N'source-orcid'
SET
  @DisplayName_118e2781 = N'Source Orcid'
SET
  @Description_118e2781 = N'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.'
SET
  @Type_118e2781 = N'String'
SET
  @Length_118e2781 = 19
SET
  @AllowsNull_118e2781 = 1
SET
  @IsPrimaryKey_118e2781 = 0
SET
  @IsUniqueKey_118e2781 = 0
SET
  @IsReadOnly_118e2781 = 1
SET
  @IsRequired_118e2781 = 0
SET
  @Sequence_118e2781 = 36
SET
  @Status_118e2781 = N'Active'
SET
  @IsCustom_118e2781 = 0
SET
  @MetadataSource_118e2781 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_118e2781,
  @IntegrationObjectID = @IntegrationObjectID_118e2781,
  @Name = @Name_118e2781,
  @DisplayName = @DisplayName_118e2781,
  @Description = @Description_118e2781,
  @Category = @Category_118e2781,
  @Category_Clear = 1,
  @Type = @Type_118e2781,
  @Length = @Length_118e2781,
  @Precision = @Precision_118e2781,
  @Precision_Clear = 1,
  @Scale = @Scale_118e2781,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_118e2781,
  @DefaultValue = @DefaultValue_118e2781,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_118e2781,
  @IsUniqueKey = @IsUniqueKey_118e2781,
  @IsReadOnly = @IsReadOnly_118e2781,
  @IsRequired = @IsRequired_118e2781,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_118e2781,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_118e2781,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_118e2781,
  @Configuration = @Configuration_118e2781,
  @Configuration_Clear = 1,
  @Status = @Status_118e2781,
  @IsCustom = @IsCustom_118e2781,
  @MetadataSource = @MetadataSource_118e2781;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_510fd1cd UNIQUEIDENTIFIER,
@IntegrationObjectID_510fd1cd UNIQUEIDENTIFIER,
@Name_510fd1cd NVARCHAR(255),
@DisplayName_510fd1cd NVARCHAR(255),
@Description_510fd1cd NVARCHAR(MAX),
@Category_510fd1cd NVARCHAR(100),
@Type_510fd1cd NVARCHAR(100),
@Length_510fd1cd INT,
@Precision_510fd1cd INT,
@Scale_510fd1cd INT,
@AllowsNull_510fd1cd BIT,
@DefaultValue_510fd1cd NVARCHAR(255),
@IsPrimaryKey_510fd1cd BIT,
@IsUniqueKey_510fd1cd BIT,
@IsReadOnly_510fd1cd BIT,
@IsRequired_510fd1cd BIT,
@RelatedIntegrationObjectID_510fd1cd UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_510fd1cd NVARCHAR(255),
@Sequence_510fd1cd INT,
@Configuration_510fd1cd NVARCHAR(MAX),
@Status_510fd1cd NVARCHAR(25),
@IsCustom_510fd1cd BIT,
@MetadataSource_510fd1cd NVARCHAR(20)
SET
  @ID_510fd1cd = '8B001C89-FF8E-5117-869B-7755BD9B5B2A'
SET
  @IntegrationObjectID_510fd1cd = 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F'
SET
  @Name_510fd1cd = N'completion-year'
SET
  @DisplayName_510fd1cd = N'Completion Year'
SET
  @Description_510fd1cd = N'Year of the review completion date; ORCID dates are partial, so month/day may be absent.'
SET
  @Type_510fd1cd = N'Integer'
SET
  @AllowsNull_510fd1cd = 1
SET
  @IsPrimaryKey_510fd1cd = 0
SET
  @IsUniqueKey_510fd1cd = 0
SET
  @IsReadOnly_510fd1cd = 1
SET
  @IsRequired_510fd1cd = 0
SET
  @Sequence_510fd1cd = 20
SET
  @Status_510fd1cd = N'Active'
SET
  @IsCustom_510fd1cd = 0
SET
  @MetadataSource_510fd1cd = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_510fd1cd,
  @IntegrationObjectID = @IntegrationObjectID_510fd1cd,
  @Name = @Name_510fd1cd,
  @DisplayName = @DisplayName_510fd1cd,
  @Description = @Description_510fd1cd,
  @Category = @Category_510fd1cd,
  @Category_Clear = 1,
  @Type = @Type_510fd1cd,
  @Length = @Length_510fd1cd,
  @Length_Clear = 1,
  @Precision = @Precision_510fd1cd,
  @Precision_Clear = 1,
  @Scale = @Scale_510fd1cd,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_510fd1cd,
  @DefaultValue = @DefaultValue_510fd1cd,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_510fd1cd,
  @IsUniqueKey = @IsUniqueKey_510fd1cd,
  @IsReadOnly = @IsReadOnly_510fd1cd,
  @IsRequired = @IsRequired_510fd1cd,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_510fd1cd,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_510fd1cd,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_510fd1cd,
  @Configuration = @Configuration_510fd1cd,
  @Configuration_Clear = 1,
  @Status = @Status_510fd1cd,
  @IsCustom = @IsCustom_510fd1cd,
  @MetadataSource = @MetadataSource_510fd1cd;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_ee28e9cc UNIQUEIDENTIFIER,
@IntegrationObjectID_ee28e9cc UNIQUEIDENTIFIER,
@Name_ee28e9cc NVARCHAR(255),
@DisplayName_ee28e9cc NVARCHAR(255),
@Description_ee28e9cc NVARCHAR(MAX),
@Category_ee28e9cc NVARCHAR(100),
@Type_ee28e9cc NVARCHAR(100),
@Length_ee28e9cc INT,
@Precision_ee28e9cc INT,
@Scale_ee28e9cc INT,
@AllowsNull_ee28e9cc BIT,
@DefaultValue_ee28e9cc NVARCHAR(255),
@IsPrimaryKey_ee28e9cc BIT,
@IsUniqueKey_ee28e9cc BIT,
@IsReadOnly_ee28e9cc BIT,
@IsRequired_ee28e9cc BIT,
@RelatedIntegrationObjectID_ee28e9cc UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_ee28e9cc NVARCHAR(255),
@Sequence_ee28e9cc INT,
@Configuration_ee28e9cc NVARCHAR(MAX),
@Status_ee28e9cc NVARCHAR(25),
@IsCustom_ee28e9cc BIT,
@MetadataSource_ee28e9cc NVARCHAR(20)
SET
  @ID_ee28e9cc = '77AA2C8F-72DE-5E33-B378-6BD7F0CF4B78'
SET
  @IntegrationObjectID_ee28e9cc = 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F'
SET
  @Name_ee28e9cc = N'completion-month'
SET
  @DisplayName_ee28e9cc = N'Completion Month'
SET
  @Description_ee28e9cc = N'Month (1-12) of the review completion date, when given.'
SET
  @Type_ee28e9cc = N'Integer'
SET
  @AllowsNull_ee28e9cc = 1
SET
  @IsPrimaryKey_ee28e9cc = 0
SET
  @IsUniqueKey_ee28e9cc = 0
SET
  @IsReadOnly_ee28e9cc = 1
SET
  @IsRequired_ee28e9cc = 0
SET
  @Sequence_ee28e9cc = 21
SET
  @Status_ee28e9cc = N'Active'
SET
  @IsCustom_ee28e9cc = 0
SET
  @MetadataSource_ee28e9cc = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_ee28e9cc,
  @IntegrationObjectID = @IntegrationObjectID_ee28e9cc,
  @Name = @Name_ee28e9cc,
  @DisplayName = @DisplayName_ee28e9cc,
  @Description = @Description_ee28e9cc,
  @Category = @Category_ee28e9cc,
  @Category_Clear = 1,
  @Type = @Type_ee28e9cc,
  @Length = @Length_ee28e9cc,
  @Length_Clear = 1,
  @Precision = @Precision_ee28e9cc,
  @Precision_Clear = 1,
  @Scale = @Scale_ee28e9cc,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_ee28e9cc,
  @DefaultValue = @DefaultValue_ee28e9cc,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_ee28e9cc,
  @IsUniqueKey = @IsUniqueKey_ee28e9cc,
  @IsReadOnly = @IsReadOnly_ee28e9cc,
  @IsRequired = @IsRequired_ee28e9cc,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_ee28e9cc,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_ee28e9cc,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_ee28e9cc,
  @Configuration = @Configuration_ee28e9cc,
  @Configuration_Clear = 1,
  @Status = @Status_ee28e9cc,
  @IsCustom = @IsCustom_ee28e9cc,
  @MetadataSource = @MetadataSource_ee28e9cc;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_c41e5687 UNIQUEIDENTIFIER,
@IntegrationObjectID_c41e5687 UNIQUEIDENTIFIER,
@Name_c41e5687 NVARCHAR(255),
@DisplayName_c41e5687 NVARCHAR(255),
@Description_c41e5687 NVARCHAR(MAX),
@Category_c41e5687 NVARCHAR(100),
@Type_c41e5687 NVARCHAR(100),
@Length_c41e5687 INT,
@Precision_c41e5687 INT,
@Scale_c41e5687 INT,
@AllowsNull_c41e5687 BIT,
@DefaultValue_c41e5687 NVARCHAR(255),
@IsPrimaryKey_c41e5687 BIT,
@IsUniqueKey_c41e5687 BIT,
@IsReadOnly_c41e5687 BIT,
@IsRequired_c41e5687 BIT,
@RelatedIntegrationObjectID_c41e5687 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_c41e5687 NVARCHAR(255),
@Sequence_c41e5687 INT,
@Configuration_c41e5687 NVARCHAR(MAX),
@Status_c41e5687 NVARCHAR(25),
@IsCustom_c41e5687 BIT,
@MetadataSource_c41e5687 NVARCHAR(20)
SET
  @ID_c41e5687 = '4B9F5E93-66F9-5839-8A5D-B0D768301EDD'
SET
  @IntegrationObjectID_c41e5687 = 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F'
SET
  @Name_c41e5687 = N'completion-day'
SET
  @DisplayName_c41e5687 = N'Completion Day'
SET
  @Description_c41e5687 = N'Day of month of the review completion date, when given.'
SET
  @Type_c41e5687 = N'Integer'
SET
  @AllowsNull_c41e5687 = 1
SET
  @IsPrimaryKey_c41e5687 = 0
SET
  @IsUniqueKey_c41e5687 = 0
SET
  @IsReadOnly_c41e5687 = 1
SET
  @IsRequired_c41e5687 = 0
SET
  @Sequence_c41e5687 = 22
SET
  @Status_c41e5687 = N'Active'
SET
  @IsCustom_c41e5687 = 0
SET
  @MetadataSource_c41e5687 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_c41e5687,
  @IntegrationObjectID = @IntegrationObjectID_c41e5687,
  @Name = @Name_c41e5687,
  @DisplayName = @DisplayName_c41e5687,
  @Description = @Description_c41e5687,
  @Category = @Category_c41e5687,
  @Category_Clear = 1,
  @Type = @Type_c41e5687,
  @Length = @Length_c41e5687,
  @Length_Clear = 1,
  @Precision = @Precision_c41e5687,
  @Precision_Clear = 1,
  @Scale = @Scale_c41e5687,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_c41e5687,
  @DefaultValue = @DefaultValue_c41e5687,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_c41e5687,
  @IsUniqueKey = @IsUniqueKey_c41e5687,
  @IsReadOnly = @IsReadOnly_c41e5687,
  @IsRequired = @IsRequired_c41e5687,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_c41e5687,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_c41e5687,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_c41e5687,
  @Configuration = @Configuration_c41e5687,
  @Configuration_Clear = 1,
  @Status = @Status_c41e5687,
  @IsCustom = @IsCustom_c41e5687,
  @MetadataSource = @MetadataSource_c41e5687;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_a56c1e5c UNIQUEIDENTIFIER,
@IntegrationObjectID_a56c1e5c UNIQUEIDENTIFIER,
@Name_a56c1e5c NVARCHAR(255),
@DisplayName_a56c1e5c NVARCHAR(255),
@Description_a56c1e5c NVARCHAR(MAX),
@Category_a56c1e5c NVARCHAR(100),
@Type_a56c1e5c NVARCHAR(100),
@Length_a56c1e5c INT,
@Precision_a56c1e5c INT,
@Scale_a56c1e5c INT,
@AllowsNull_a56c1e5c BIT,
@DefaultValue_a56c1e5c NVARCHAR(255),
@IsPrimaryKey_a56c1e5c BIT,
@IsUniqueKey_a56c1e5c BIT,
@IsReadOnly_a56c1e5c BIT,
@IsRequired_a56c1e5c BIT,
@RelatedIntegrationObjectID_a56c1e5c UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_a56c1e5c NVARCHAR(255),
@Sequence_a56c1e5c INT,
@Configuration_a56c1e5c NVARCHAR(MAX),
@Status_a56c1e5c NVARCHAR(25),
@IsCustom_a56c1e5c BIT,
@MetadataSource_a56c1e5c NVARCHAR(20)
SET
  @ID_a56c1e5c = 'C0E8F032-5D9A-5171-8125-1D240ED0D18B'
SET
  @IntegrationObjectID_a56c1e5c = 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F'
SET
  @Name_a56c1e5c = N'convening-organization-name'
SET
  @DisplayName_a56c1e5c = N'Convening Organization Name'
SET
  @Description_a56c1e5c = N'Name of the convening organization (journal, conference). Lifted from convening-organization.name.'
SET
  @Type_a56c1e5c = N'String'
SET
  @Length_a56c1e5c = 1000
SET
  @AllowsNull_a56c1e5c = 1
SET
  @IsPrimaryKey_a56c1e5c = 0
SET
  @IsUniqueKey_a56c1e5c = 0
SET
  @IsReadOnly_a56c1e5c = 1
SET
  @IsRequired_a56c1e5c = 0
SET
  @Sequence_a56c1e5c = 23
SET
  @Status_a56c1e5c = N'Active'
SET
  @IsCustom_a56c1e5c = 0
SET
  @MetadataSource_a56c1e5c = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_a56c1e5c,
  @IntegrationObjectID = @IntegrationObjectID_a56c1e5c,
  @Name = @Name_a56c1e5c,
  @DisplayName = @DisplayName_a56c1e5c,
  @Description = @Description_a56c1e5c,
  @Category = @Category_a56c1e5c,
  @Category_Clear = 1,
  @Type = @Type_a56c1e5c,
  @Length = @Length_a56c1e5c,
  @Precision = @Precision_a56c1e5c,
  @Precision_Clear = 1,
  @Scale = @Scale_a56c1e5c,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_a56c1e5c,
  @DefaultValue = @DefaultValue_a56c1e5c,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_a56c1e5c,
  @IsUniqueKey = @IsUniqueKey_a56c1e5c,
  @IsReadOnly = @IsReadOnly_a56c1e5c,
  @IsRequired = @IsRequired_a56c1e5c,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_a56c1e5c,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_a56c1e5c,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_a56c1e5c,
  @Configuration = @Configuration_a56c1e5c,
  @Configuration_Clear = 1,
  @Status = @Status_a56c1e5c,
  @IsCustom = @IsCustom_a56c1e5c,
  @MetadataSource = @MetadataSource_a56c1e5c;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_452ba948 UNIQUEIDENTIFIER,
@IntegrationObjectID_452ba948 UNIQUEIDENTIFIER,
@Name_452ba948 NVARCHAR(255),
@DisplayName_452ba948 NVARCHAR(255),
@Description_452ba948 NVARCHAR(MAX),
@Category_452ba948 NVARCHAR(100),
@Type_452ba948 NVARCHAR(100),
@Length_452ba948 INT,
@Precision_452ba948 INT,
@Scale_452ba948 INT,
@AllowsNull_452ba948 BIT,
@DefaultValue_452ba948 NVARCHAR(255),
@IsPrimaryKey_452ba948 BIT,
@IsUniqueKey_452ba948 BIT,
@IsReadOnly_452ba948 BIT,
@IsRequired_452ba948 BIT,
@RelatedIntegrationObjectID_452ba948 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_452ba948 NVARCHAR(255),
@Sequence_452ba948 INT,
@Configuration_452ba948 NVARCHAR(MAX),
@Status_452ba948 NVARCHAR(25),
@IsCustom_452ba948 BIT,
@MetadataSource_452ba948 NVARCHAR(20)
SET
  @ID_452ba948 = '5F5BACEB-FA92-5A3C-87BA-837889064F7E'
SET
  @IntegrationObjectID_452ba948 = 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F'
SET
  @Name_452ba948 = N'convening-organization-city'
SET
  @DisplayName_452ba948 = N'Convening Organization City'
SET
  @Description_452ba948 = N'City of the convening organization (journal, conference). Lifted from convening-organization.address.city.'
SET
  @Type_452ba948 = N'String'
SET
  @Length_452ba948 = 255
SET
  @AllowsNull_452ba948 = 1
SET
  @IsPrimaryKey_452ba948 = 0
SET
  @IsUniqueKey_452ba948 = 0
SET
  @IsReadOnly_452ba948 = 1
SET
  @IsRequired_452ba948 = 0
SET
  @Sequence_452ba948 = 24
SET
  @Status_452ba948 = N'Active'
SET
  @IsCustom_452ba948 = 0
SET
  @MetadataSource_452ba948 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_452ba948,
  @IntegrationObjectID = @IntegrationObjectID_452ba948,
  @Name = @Name_452ba948,
  @DisplayName = @DisplayName_452ba948,
  @Description = @Description_452ba948,
  @Category = @Category_452ba948,
  @Category_Clear = 1,
  @Type = @Type_452ba948,
  @Length = @Length_452ba948,
  @Precision = @Precision_452ba948,
  @Precision_Clear = 1,
  @Scale = @Scale_452ba948,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_452ba948,
  @DefaultValue = @DefaultValue_452ba948,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_452ba948,
  @IsUniqueKey = @IsUniqueKey_452ba948,
  @IsReadOnly = @IsReadOnly_452ba948,
  @IsRequired = @IsRequired_452ba948,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_452ba948,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_452ba948,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_452ba948,
  @Configuration = @Configuration_452ba948,
  @Configuration_Clear = 1,
  @Status = @Status_452ba948,
  @IsCustom = @IsCustom_452ba948,
  @MetadataSource = @MetadataSource_452ba948;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_0808d0a4 UNIQUEIDENTIFIER,
@IntegrationObjectID_0808d0a4 UNIQUEIDENTIFIER,
@Name_0808d0a4 NVARCHAR(255),
@DisplayName_0808d0a4 NVARCHAR(255),
@Description_0808d0a4 NVARCHAR(MAX),
@Category_0808d0a4 NVARCHAR(100),
@Type_0808d0a4 NVARCHAR(100),
@Length_0808d0a4 INT,
@Precision_0808d0a4 INT,
@Scale_0808d0a4 INT,
@AllowsNull_0808d0a4 BIT,
@DefaultValue_0808d0a4 NVARCHAR(255),
@IsPrimaryKey_0808d0a4 BIT,
@IsUniqueKey_0808d0a4 BIT,
@IsReadOnly_0808d0a4 BIT,
@IsRequired_0808d0a4 BIT,
@RelatedIntegrationObjectID_0808d0a4 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_0808d0a4 NVARCHAR(255),
@Sequence_0808d0a4 INT,
@Configuration_0808d0a4 NVARCHAR(MAX),
@Status_0808d0a4 NVARCHAR(25),
@IsCustom_0808d0a4 BIT,
@MetadataSource_0808d0a4 NVARCHAR(20)
SET
  @ID_0808d0a4 = '4B6DF283-5064-5EEF-8AD5-69A89F47351A'
SET
  @IntegrationObjectID_0808d0a4 = 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F'
SET
  @Name_0808d0a4 = N'convening-organization-region'
SET
  @DisplayName_0808d0a4 = N'Convening Organization Region'
SET
  @Description_0808d0a4 = N'Region/state of the convening organization (journal, conference). Lifted from convening-organization.address.region.'
SET
  @Type_0808d0a4 = N'String'
SET
  @Length_0808d0a4 = 255
SET
  @AllowsNull_0808d0a4 = 1
SET
  @IsPrimaryKey_0808d0a4 = 0
SET
  @IsUniqueKey_0808d0a4 = 0
SET
  @IsReadOnly_0808d0a4 = 1
SET
  @IsRequired_0808d0a4 = 0
SET
  @Sequence_0808d0a4 = 25
SET
  @Status_0808d0a4 = N'Active'
SET
  @IsCustom_0808d0a4 = 0
SET
  @MetadataSource_0808d0a4 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_0808d0a4,
  @IntegrationObjectID = @IntegrationObjectID_0808d0a4,
  @Name = @Name_0808d0a4,
  @DisplayName = @DisplayName_0808d0a4,
  @Description = @Description_0808d0a4,
  @Category = @Category_0808d0a4,
  @Category_Clear = 1,
  @Type = @Type_0808d0a4,
  @Length = @Length_0808d0a4,
  @Precision = @Precision_0808d0a4,
  @Precision_Clear = 1,
  @Scale = @Scale_0808d0a4,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_0808d0a4,
  @DefaultValue = @DefaultValue_0808d0a4,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_0808d0a4,
  @IsUniqueKey = @IsUniqueKey_0808d0a4,
  @IsReadOnly = @IsReadOnly_0808d0a4,
  @IsRequired = @IsRequired_0808d0a4,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_0808d0a4,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_0808d0a4,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_0808d0a4,
  @Configuration = @Configuration_0808d0a4,
  @Configuration_Clear = 1,
  @Status = @Status_0808d0a4,
  @IsCustom = @IsCustom_0808d0a4,
  @MetadataSource = @MetadataSource_0808d0a4;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_18b9523d UNIQUEIDENTIFIER,
@IntegrationObjectID_18b9523d UNIQUEIDENTIFIER,
@Name_18b9523d NVARCHAR(255),
@DisplayName_18b9523d NVARCHAR(255),
@Description_18b9523d NVARCHAR(MAX),
@Category_18b9523d NVARCHAR(100),
@Type_18b9523d NVARCHAR(100),
@Length_18b9523d INT,
@Precision_18b9523d INT,
@Scale_18b9523d INT,
@AllowsNull_18b9523d BIT,
@DefaultValue_18b9523d NVARCHAR(255),
@IsPrimaryKey_18b9523d BIT,
@IsUniqueKey_18b9523d BIT,
@IsReadOnly_18b9523d BIT,
@IsRequired_18b9523d BIT,
@RelatedIntegrationObjectID_18b9523d UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_18b9523d NVARCHAR(255),
@Sequence_18b9523d INT,
@Configuration_18b9523d NVARCHAR(MAX),
@Status_18b9523d NVARCHAR(25),
@IsCustom_18b9523d BIT,
@MetadataSource_18b9523d NVARCHAR(20)
SET
  @ID_18b9523d = '52DF410A-F371-580E-981F-6D74EE6EB807'
SET
  @IntegrationObjectID_18b9523d = 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F'
SET
  @Name_18b9523d = N'convening-organization-country'
SET
  @DisplayName_18b9523d = N'Convening Organization Country'
SET
  @Description_18b9523d = N'ISO country code of the convening organization (journal, conference). Lifted from convening-organization.address.country.'
SET
  @Type_18b9523d = N'String'
SET
  @Length_18b9523d = 50
SET
  @AllowsNull_18b9523d = 1
SET
  @IsPrimaryKey_18b9523d = 0
SET
  @IsUniqueKey_18b9523d = 0
SET
  @IsReadOnly_18b9523d = 1
SET
  @IsRequired_18b9523d = 0
SET
  @Sequence_18b9523d = 26
SET
  @Status_18b9523d = N'Active'
SET
  @IsCustom_18b9523d = 0
SET
  @MetadataSource_18b9523d = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_18b9523d,
  @IntegrationObjectID = @IntegrationObjectID_18b9523d,
  @Name = @Name_18b9523d,
  @DisplayName = @DisplayName_18b9523d,
  @Description = @Description_18b9523d,
  @Category = @Category_18b9523d,
  @Category_Clear = 1,
  @Type = @Type_18b9523d,
  @Length = @Length_18b9523d,
  @Precision = @Precision_18b9523d,
  @Precision_Clear = 1,
  @Scale = @Scale_18b9523d,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_18b9523d,
  @DefaultValue = @DefaultValue_18b9523d,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_18b9523d,
  @IsUniqueKey = @IsUniqueKey_18b9523d,
  @IsReadOnly = @IsReadOnly_18b9523d,
  @IsRequired = @IsRequired_18b9523d,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_18b9523d,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_18b9523d,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_18b9523d,
  @Configuration = @Configuration_18b9523d,
  @Configuration_Clear = 1,
  @Status = @Status_18b9523d,
  @IsCustom = @IsCustom_18b9523d,
  @MetadataSource = @MetadataSource_18b9523d;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_0f2e6b97 UNIQUEIDENTIFIER,
@IntegrationObjectID_0f2e6b97 UNIQUEIDENTIFIER,
@Name_0f2e6b97 NVARCHAR(255),
@DisplayName_0f2e6b97 NVARCHAR(255),
@Description_0f2e6b97 NVARCHAR(MAX),
@Category_0f2e6b97 NVARCHAR(100),
@Type_0f2e6b97 NVARCHAR(100),
@Length_0f2e6b97 INT,
@Precision_0f2e6b97 INT,
@Scale_0f2e6b97 INT,
@AllowsNull_0f2e6b97 BIT,
@DefaultValue_0f2e6b97 NVARCHAR(255),
@IsPrimaryKey_0f2e6b97 BIT,
@IsUniqueKey_0f2e6b97 BIT,
@IsReadOnly_0f2e6b97 BIT,
@IsRequired_0f2e6b97 BIT,
@RelatedIntegrationObjectID_0f2e6b97 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_0f2e6b97 NVARCHAR(255),
@Sequence_0f2e6b97 INT,
@Configuration_0f2e6b97 NVARCHAR(MAX),
@Status_0f2e6b97 NVARCHAR(25),
@IsCustom_0f2e6b97 BIT,
@MetadataSource_0f2e6b97 NVARCHAR(20)
SET
  @ID_0f2e6b97 = 'B76AB8AC-4674-5700-A966-46AA4A9AC511'
SET
  @IntegrationObjectID_0f2e6b97 = 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F'
SET
  @Name_0f2e6b97 = N'convening-organization-disambiguated-id'
SET
  @DisplayName_0f2e6b97 = N'Convening Organization Disambiguated Id'
SET
  @Description_0f2e6b97 = N'Canonical identifier of the convening organization (journal, conference) in the disambiguation source (e.g. a RINGGOLD or ROR id), so the same institution matches across records.'
SET
  @Type_0f2e6b97 = N'String'
SET
  @Length_0f2e6b97 = 255
SET
  @AllowsNull_0f2e6b97 = 1
SET
  @IsPrimaryKey_0f2e6b97 = 0
SET
  @IsUniqueKey_0f2e6b97 = 0
SET
  @IsReadOnly_0f2e6b97 = 1
SET
  @IsRequired_0f2e6b97 = 0
SET
  @Sequence_0f2e6b97 = 27
SET
  @Status_0f2e6b97 = N'Active'
SET
  @IsCustom_0f2e6b97 = 0
SET
  @MetadataSource_0f2e6b97 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_0f2e6b97,
  @IntegrationObjectID = @IntegrationObjectID_0f2e6b97,
  @Name = @Name_0f2e6b97,
  @DisplayName = @DisplayName_0f2e6b97,
  @Description = @Description_0f2e6b97,
  @Category = @Category_0f2e6b97,
  @Category_Clear = 1,
  @Type = @Type_0f2e6b97,
  @Length = @Length_0f2e6b97,
  @Precision = @Precision_0f2e6b97,
  @Precision_Clear = 1,
  @Scale = @Scale_0f2e6b97,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_0f2e6b97,
  @DefaultValue = @DefaultValue_0f2e6b97,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_0f2e6b97,
  @IsUniqueKey = @IsUniqueKey_0f2e6b97,
  @IsReadOnly = @IsReadOnly_0f2e6b97,
  @IsRequired = @IsRequired_0f2e6b97,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_0f2e6b97,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_0f2e6b97,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_0f2e6b97,
  @Configuration = @Configuration_0f2e6b97,
  @Configuration_Clear = 1,
  @Status = @Status_0f2e6b97,
  @IsCustom = @IsCustom_0f2e6b97,
  @MetadataSource = @MetadataSource_0f2e6b97;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_0da1f6ef UNIQUEIDENTIFIER,
@IntegrationObjectID_0da1f6ef UNIQUEIDENTIFIER,
@Name_0da1f6ef NVARCHAR(255),
@DisplayName_0da1f6ef NVARCHAR(255),
@Description_0da1f6ef NVARCHAR(MAX),
@Category_0da1f6ef NVARCHAR(100),
@Type_0da1f6ef NVARCHAR(100),
@Length_0da1f6ef INT,
@Precision_0da1f6ef INT,
@Scale_0da1f6ef INT,
@AllowsNull_0da1f6ef BIT,
@DefaultValue_0da1f6ef NVARCHAR(255),
@IsPrimaryKey_0da1f6ef BIT,
@IsUniqueKey_0da1f6ef BIT,
@IsReadOnly_0da1f6ef BIT,
@IsRequired_0da1f6ef BIT,
@RelatedIntegrationObjectID_0da1f6ef UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_0da1f6ef NVARCHAR(255),
@Sequence_0da1f6ef INT,
@Configuration_0da1f6ef NVARCHAR(MAX),
@Status_0da1f6ef NVARCHAR(25),
@IsCustom_0da1f6ef BIT,
@MetadataSource_0da1f6ef NVARCHAR(20)
SET
  @ID_0da1f6ef = 'FC80A75C-7065-58CC-A41C-811FE0A68530'
SET
  @IntegrationObjectID_0da1f6ef = 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F'
SET
  @Name_0da1f6ef = N'convening-organization-disambiguation-source'
SET
  @DisplayName_0da1f6ef = N'Convening Organization Disambiguation Source'
SET
  @Description_0da1f6ef = N'Registry the disambiguated id comes from (RINGGOLD, ROR, FUNDREF, GRID, LEI).'
SET
  @Type_0da1f6ef = N'String'
SET
  @Length_0da1f6ef = 100
SET
  @AllowsNull_0da1f6ef = 1
SET
  @IsPrimaryKey_0da1f6ef = 0
SET
  @IsUniqueKey_0da1f6ef = 0
SET
  @IsReadOnly_0da1f6ef = 1
SET
  @IsRequired_0da1f6ef = 0
SET
  @Sequence_0da1f6ef = 28
SET
  @Status_0da1f6ef = N'Active'
SET
  @IsCustom_0da1f6ef = 0
SET
  @MetadataSource_0da1f6ef = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_0da1f6ef,
  @IntegrationObjectID = @IntegrationObjectID_0da1f6ef,
  @Name = @Name_0da1f6ef,
  @DisplayName = @DisplayName_0da1f6ef,
  @Description = @Description_0da1f6ef,
  @Category = @Category_0da1f6ef,
  @Category_Clear = 1,
  @Type = @Type_0da1f6ef,
  @Length = @Length_0da1f6ef,
  @Precision = @Precision_0da1f6ef,
  @Precision_Clear = 1,
  @Scale = @Scale_0da1f6ef,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_0da1f6ef,
  @DefaultValue = @DefaultValue_0da1f6ef,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_0da1f6ef,
  @IsUniqueKey = @IsUniqueKey_0da1f6ef,
  @IsReadOnly = @IsReadOnly_0da1f6ef,
  @IsRequired = @IsRequired_0da1f6ef,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_0da1f6ef,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_0da1f6ef,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_0da1f6ef,
  @Configuration = @Configuration_0da1f6ef,
  @Configuration_Clear = 1,
  @Status = @Status_0da1f6ef,
  @IsCustom = @IsCustom_0da1f6ef,
  @MetadataSource = @MetadataSource_0da1f6ef;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_fd878f8d UNIQUEIDENTIFIER,
@IntegrationObjectID_fd878f8d UNIQUEIDENTIFIER,
@Name_fd878f8d NVARCHAR(255),
@DisplayName_fd878f8d NVARCHAR(255),
@Description_fd878f8d NVARCHAR(MAX),
@Category_fd878f8d NVARCHAR(100),
@Type_fd878f8d NVARCHAR(100),
@Length_fd878f8d INT,
@Precision_fd878f8d INT,
@Scale_fd878f8d INT,
@AllowsNull_fd878f8d BIT,
@DefaultValue_fd878f8d NVARCHAR(255),
@IsPrimaryKey_fd878f8d BIT,
@IsUniqueKey_fd878f8d BIT,
@IsReadOnly_fd878f8d BIT,
@IsRequired_fd878f8d BIT,
@RelatedIntegrationObjectID_fd878f8d UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_fd878f8d NVARCHAR(255),
@Sequence_fd878f8d INT,
@Configuration_fd878f8d NVARCHAR(MAX),
@Status_fd878f8d NVARCHAR(25),
@IsCustom_fd878f8d BIT,
@MetadataSource_fd878f8d NVARCHAR(20)
SET
  @ID_fd878f8d = 'C2CEAA75-B036-5BEA-B5DA-B47812F1FC9C'
SET
  @IntegrationObjectID_fd878f8d = 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F'
SET
  @Name_fd878f8d = N'subject-name-title'
SET
  @DisplayName_fd878f8d = N'Subject Name Title'
SET
  @Description_fd878f8d = N'Title of the reviewed item. Lifted from subject-name.title.'
SET
  @Type_fd878f8d = N'String'
SET
  @Length_fd878f8d = 2000
SET
  @AllowsNull_fd878f8d = 1
SET
  @IsPrimaryKey_fd878f8d = 0
SET
  @IsUniqueKey_fd878f8d = 0
SET
  @IsReadOnly_fd878f8d = 1
SET
  @IsRequired_fd878f8d = 0
SET
  @Sequence_fd878f8d = 29
SET
  @Status_fd878f8d = N'Active'
SET
  @IsCustom_fd878f8d = 0
SET
  @MetadataSource_fd878f8d = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_fd878f8d,
  @IntegrationObjectID = @IntegrationObjectID_fd878f8d,
  @Name = @Name_fd878f8d,
  @DisplayName = @DisplayName_fd878f8d,
  @Description = @Description_fd878f8d,
  @Category = @Category_fd878f8d,
  @Category_Clear = 1,
  @Type = @Type_fd878f8d,
  @Length = @Length_fd878f8d,
  @Precision = @Precision_fd878f8d,
  @Precision_Clear = 1,
  @Scale = @Scale_fd878f8d,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_fd878f8d,
  @DefaultValue = @DefaultValue_fd878f8d,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_fd878f8d,
  @IsUniqueKey = @IsUniqueKey_fd878f8d,
  @IsReadOnly = @IsReadOnly_fd878f8d,
  @IsRequired = @IsRequired_fd878f8d,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_fd878f8d,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_fd878f8d,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_fd878f8d,
  @Configuration = @Configuration_fd878f8d,
  @Configuration_Clear = 1,
  @Status = @Status_fd878f8d,
  @IsCustom = @IsCustom_fd878f8d,
  @MetadataSource = @MetadataSource_fd878f8d;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_67ccf45b UNIQUEIDENTIFIER,
@IntegrationObjectID_67ccf45b UNIQUEIDENTIFIER,
@Name_67ccf45b NVARCHAR(255),
@DisplayName_67ccf45b NVARCHAR(255),
@Description_67ccf45b NVARCHAR(MAX),
@Category_67ccf45b NVARCHAR(100),
@Type_67ccf45b NVARCHAR(100),
@Length_67ccf45b INT,
@Precision_67ccf45b INT,
@Scale_67ccf45b INT,
@AllowsNull_67ccf45b BIT,
@DefaultValue_67ccf45b NVARCHAR(255),
@IsPrimaryKey_67ccf45b BIT,
@IsUniqueKey_67ccf45b BIT,
@IsReadOnly_67ccf45b BIT,
@IsRequired_67ccf45b BIT,
@RelatedIntegrationObjectID_67ccf45b UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_67ccf45b NVARCHAR(255),
@Sequence_67ccf45b INT,
@Configuration_67ccf45b NVARCHAR(MAX),
@Status_67ccf45b NVARCHAR(25),
@IsCustom_67ccf45b BIT,
@MetadataSource_67ccf45b NVARCHAR(20)
SET
  @ID_67ccf45b = '7484D2DC-F882-50DA-996B-55BF12BA7369'
SET
  @IntegrationObjectID_67ccf45b = 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F'
SET
  @Name_67ccf45b = N'subject-external-id-type'
SET
  @DisplayName_67ccf45b = N'Subject External Id Type'
SET
  @Description_67ccf45b = N'Identifier type of the reviewed item (e.g. doi). Lifted from subject-external-identifier.external-id-type.'
SET
  @Type_67ccf45b = N'String'
SET
  @Length_67ccf45b = 100
SET
  @AllowsNull_67ccf45b = 1
SET
  @IsPrimaryKey_67ccf45b = 0
SET
  @IsUniqueKey_67ccf45b = 0
SET
  @IsReadOnly_67ccf45b = 1
SET
  @IsRequired_67ccf45b = 0
SET
  @Sequence_67ccf45b = 30
SET
  @Status_67ccf45b = N'Active'
SET
  @IsCustom_67ccf45b = 0
SET
  @MetadataSource_67ccf45b = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_67ccf45b,
  @IntegrationObjectID = @IntegrationObjectID_67ccf45b,
  @Name = @Name_67ccf45b,
  @DisplayName = @DisplayName_67ccf45b,
  @Description = @Description_67ccf45b,
  @Category = @Category_67ccf45b,
  @Category_Clear = 1,
  @Type = @Type_67ccf45b,
  @Length = @Length_67ccf45b,
  @Precision = @Precision_67ccf45b,
  @Precision_Clear = 1,
  @Scale = @Scale_67ccf45b,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_67ccf45b,
  @DefaultValue = @DefaultValue_67ccf45b,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_67ccf45b,
  @IsUniqueKey = @IsUniqueKey_67ccf45b,
  @IsReadOnly = @IsReadOnly_67ccf45b,
  @IsRequired = @IsRequired_67ccf45b,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_67ccf45b,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_67ccf45b,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_67ccf45b,
  @Configuration = @Configuration_67ccf45b,
  @Configuration_Clear = 1,
  @Status = @Status_67ccf45b,
  @IsCustom = @IsCustom_67ccf45b,
  @MetadataSource = @MetadataSource_67ccf45b;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_a8e72b57 UNIQUEIDENTIFIER,
@IntegrationObjectID_a8e72b57 UNIQUEIDENTIFIER,
@Name_a8e72b57 NVARCHAR(255),
@DisplayName_a8e72b57 NVARCHAR(255),
@Description_a8e72b57 NVARCHAR(MAX),
@Category_a8e72b57 NVARCHAR(100),
@Type_a8e72b57 NVARCHAR(100),
@Length_a8e72b57 INT,
@Precision_a8e72b57 INT,
@Scale_a8e72b57 INT,
@AllowsNull_a8e72b57 BIT,
@DefaultValue_a8e72b57 NVARCHAR(255),
@IsPrimaryKey_a8e72b57 BIT,
@IsUniqueKey_a8e72b57 BIT,
@IsReadOnly_a8e72b57 BIT,
@IsRequired_a8e72b57 BIT,
@RelatedIntegrationObjectID_a8e72b57 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_a8e72b57 NVARCHAR(255),
@Sequence_a8e72b57 INT,
@Configuration_a8e72b57 NVARCHAR(MAX),
@Status_a8e72b57 NVARCHAR(25),
@IsCustom_a8e72b57 BIT,
@MetadataSource_a8e72b57 NVARCHAR(20)
SET
  @ID_a8e72b57 = '35055E21-8A44-5003-91B2-66778EDC1B04'
SET
  @IntegrationObjectID_a8e72b57 = 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F'
SET
  @Name_a8e72b57 = N'subject-external-id-value'
SET
  @DisplayName_a8e72b57 = N'Subject External Id Value'
SET
  @Description_a8e72b57 = N'Identifier value of the reviewed item. Lifted from subject-external-identifier.external-id-value.'
SET
  @Type_a8e72b57 = N'String'
SET
  @Length_a8e72b57 = 500
SET
  @AllowsNull_a8e72b57 = 1
SET
  @IsPrimaryKey_a8e72b57 = 0
SET
  @IsUniqueKey_a8e72b57 = 0
SET
  @IsReadOnly_a8e72b57 = 1
SET
  @IsRequired_a8e72b57 = 0
SET
  @Sequence_a8e72b57 = 31
SET
  @Status_a8e72b57 = N'Active'
SET
  @IsCustom_a8e72b57 = 0
SET
  @MetadataSource_a8e72b57 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_a8e72b57,
  @IntegrationObjectID = @IntegrationObjectID_a8e72b57,
  @Name = @Name_a8e72b57,
  @DisplayName = @DisplayName_a8e72b57,
  @Description = @Description_a8e72b57,
  @Category = @Category_a8e72b57,
  @Category_Clear = 1,
  @Type = @Type_a8e72b57,
  @Length = @Length_a8e72b57,
  @Precision = @Precision_a8e72b57,
  @Precision_Clear = 1,
  @Scale = @Scale_a8e72b57,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_a8e72b57,
  @DefaultValue = @DefaultValue_a8e72b57,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_a8e72b57,
  @IsUniqueKey = @IsUniqueKey_a8e72b57,
  @IsReadOnly = @IsReadOnly_a8e72b57,
  @IsRequired = @IsRequired_a8e72b57,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_a8e72b57,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_a8e72b57,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_a8e72b57,
  @Configuration = @Configuration_a8e72b57,
  @Configuration_Clear = 1,
  @Status = @Status_a8e72b57,
  @IsCustom = @IsCustom_a8e72b57,
  @MetadataSource = @MetadataSource_a8e72b57;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_af6d5a99 UNIQUEIDENTIFIER,
@IntegrationObjectID_af6d5a99 UNIQUEIDENTIFIER,
@Name_af6d5a99 NVARCHAR(255),
@DisplayName_af6d5a99 NVARCHAR(255),
@Description_af6d5a99 NVARCHAR(MAX),
@Category_af6d5a99 NVARCHAR(100),
@Type_af6d5a99 NVARCHAR(100),
@Length_af6d5a99 INT,
@Precision_af6d5a99 INT,
@Scale_af6d5a99 INT,
@AllowsNull_af6d5a99 BIT,
@DefaultValue_af6d5a99 NVARCHAR(255),
@IsPrimaryKey_af6d5a99 BIT,
@IsUniqueKey_af6d5a99 BIT,
@IsReadOnly_af6d5a99 BIT,
@IsRequired_af6d5a99 BIT,
@RelatedIntegrationObjectID_af6d5a99 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_af6d5a99 NVARCHAR(255),
@Sequence_af6d5a99 INT,
@Configuration_af6d5a99 NVARCHAR(MAX),
@Status_af6d5a99 NVARCHAR(25),
@IsCustom_af6d5a99 BIT,
@MetadataSource_af6d5a99 NVARCHAR(20)
SET
  @ID_af6d5a99 = '0242FB01-8E58-54CC-8E12-FE56A7006D7E'
SET
  @IntegrationObjectID_af6d5a99 = 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F'
SET
  @Name_af6d5a99 = N'source-name'
SET
  @DisplayName_af6d5a99 = N'Source Name'
SET
  @Description_af6d5a99 = N'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.'
SET
  @Type_af6d5a99 = N'String'
SET
  @Length_af6d5a99 = 500
SET
  @AllowsNull_af6d5a99 = 1
SET
  @IsPrimaryKey_af6d5a99 = 0
SET
  @IsUniqueKey_af6d5a99 = 0
SET
  @IsReadOnly_af6d5a99 = 1
SET
  @IsRequired_af6d5a99 = 0
SET
  @Sequence_af6d5a99 = 32
SET
  @Status_af6d5a99 = N'Active'
SET
  @IsCustom_af6d5a99 = 0
SET
  @MetadataSource_af6d5a99 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_af6d5a99,
  @IntegrationObjectID = @IntegrationObjectID_af6d5a99,
  @Name = @Name_af6d5a99,
  @DisplayName = @DisplayName_af6d5a99,
  @Description = @Description_af6d5a99,
  @Category = @Category_af6d5a99,
  @Category_Clear = 1,
  @Type = @Type_af6d5a99,
  @Length = @Length_af6d5a99,
  @Precision = @Precision_af6d5a99,
  @Precision_Clear = 1,
  @Scale = @Scale_af6d5a99,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_af6d5a99,
  @DefaultValue = @DefaultValue_af6d5a99,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_af6d5a99,
  @IsUniqueKey = @IsUniqueKey_af6d5a99,
  @IsReadOnly = @IsReadOnly_af6d5a99,
  @IsRequired = @IsRequired_af6d5a99,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_af6d5a99,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_af6d5a99,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_af6d5a99,
  @Configuration = @Configuration_af6d5a99,
  @Configuration_Clear = 1,
  @Status = @Status_af6d5a99,
  @IsCustom = @IsCustom_af6d5a99,
  @MetadataSource = @MetadataSource_af6d5a99;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_c88d0b88 UNIQUEIDENTIFIER,
@IntegrationObjectID_c88d0b88 UNIQUEIDENTIFIER,
@Name_c88d0b88 NVARCHAR(255),
@DisplayName_c88d0b88 NVARCHAR(255),
@Description_c88d0b88 NVARCHAR(MAX),
@Category_c88d0b88 NVARCHAR(100),
@Type_c88d0b88 NVARCHAR(100),
@Length_c88d0b88 INT,
@Precision_c88d0b88 INT,
@Scale_c88d0b88 INT,
@AllowsNull_c88d0b88 BIT,
@DefaultValue_c88d0b88 NVARCHAR(255),
@IsPrimaryKey_c88d0b88 BIT,
@IsUniqueKey_c88d0b88 BIT,
@IsReadOnly_c88d0b88 BIT,
@IsRequired_c88d0b88 BIT,
@RelatedIntegrationObjectID_c88d0b88 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_c88d0b88 NVARCHAR(255),
@Sequence_c88d0b88 INT,
@Configuration_c88d0b88 NVARCHAR(MAX),
@Status_c88d0b88 NVARCHAR(25),
@IsCustom_c88d0b88 BIT,
@MetadataSource_c88d0b88 NVARCHAR(20)
SET
  @ID_c88d0b88 = '1D008B82-38DE-572D-944D-D8AFF273CA2F'
SET
  @IntegrationObjectID_c88d0b88 = 'BE77C4D0-3FEA-477B-84AB-5D02012EFF8F'
SET
  @Name_c88d0b88 = N'source-orcid'
SET
  @DisplayName_c88d0b88 = N'Source Orcid'
SET
  @Description_c88d0b88 = N'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.'
SET
  @Type_c88d0b88 = N'String'
SET
  @Length_c88d0b88 = 19
SET
  @AllowsNull_c88d0b88 = 1
SET
  @IsPrimaryKey_c88d0b88 = 0
SET
  @IsUniqueKey_c88d0b88 = 0
SET
  @IsReadOnly_c88d0b88 = 1
SET
  @IsRequired_c88d0b88 = 0
SET
  @Sequence_c88d0b88 = 33
SET
  @Status_c88d0b88 = N'Active'
SET
  @IsCustom_c88d0b88 = 0
SET
  @MetadataSource_c88d0b88 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_c88d0b88,
  @IntegrationObjectID = @IntegrationObjectID_c88d0b88,
  @Name = @Name_c88d0b88,
  @DisplayName = @DisplayName_c88d0b88,
  @Description = @Description_c88d0b88,
  @Category = @Category_c88d0b88,
  @Category_Clear = 1,
  @Type = @Type_c88d0b88,
  @Length = @Length_c88d0b88,
  @Precision = @Precision_c88d0b88,
  @Precision_Clear = 1,
  @Scale = @Scale_c88d0b88,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_c88d0b88,
  @DefaultValue = @DefaultValue_c88d0b88,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_c88d0b88,
  @IsUniqueKey = @IsUniqueKey_c88d0b88,
  @IsReadOnly = @IsReadOnly_c88d0b88,
  @IsRequired = @IsRequired_c88d0b88,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_c88d0b88,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_c88d0b88,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_c88d0b88,
  @Configuration = @Configuration_c88d0b88,
  @Configuration_Clear = 1,
  @Status = @Status_c88d0b88,
  @IsCustom = @IsCustom_c88d0b88,
  @MetadataSource = @MetadataSource_c88d0b88;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_c0b27ad3 UNIQUEIDENTIFIER,
@IntegrationObjectID_c0b27ad3 UNIQUEIDENTIFIER,
@Name_c0b27ad3 NVARCHAR(255),
@DisplayName_c0b27ad3 NVARCHAR(255),
@Description_c0b27ad3 NVARCHAR(MAX),
@Category_c0b27ad3 NVARCHAR(100),
@Type_c0b27ad3 NVARCHAR(100),
@Length_c0b27ad3 INT,
@Precision_c0b27ad3 INT,
@Scale_c0b27ad3 INT,
@AllowsNull_c0b27ad3 BIT,
@DefaultValue_c0b27ad3 NVARCHAR(255),
@IsPrimaryKey_c0b27ad3 BIT,
@IsUniqueKey_c0b27ad3 BIT,
@IsReadOnly_c0b27ad3 BIT,
@IsRequired_c0b27ad3 BIT,
@RelatedIntegrationObjectID_c0b27ad3 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_c0b27ad3 NVARCHAR(255),
@Sequence_c0b27ad3 INT,
@Configuration_c0b27ad3 NVARCHAR(MAX),
@Status_c0b27ad3 NVARCHAR(25),
@IsCustom_c0b27ad3 BIT,
@MetadataSource_c0b27ad3 NVARCHAR(20)
SET
  @ID_c0b27ad3 = '86D9204D-3B0F-512A-A920-98258D862CB9'
SET
  @IntegrationObjectID_c0b27ad3 = 'E52B947C-796A-46F1-BD69-BD9CD92FA046'
SET
  @Name_c0b27ad3 = N'resource-title'
SET
  @DisplayName_c0b27ad3 = N'Resource Title'
SET
  @Description_c0b27ad3 = N'Title of the research resource proposal. Lifted from proposal.title.title.'
SET
  @Type_c0b27ad3 = N'String'
SET
  @Length_c0b27ad3 = 2000
SET
  @AllowsNull_c0b27ad3 = 1
SET
  @IsPrimaryKey_c0b27ad3 = 0
SET
  @IsUniqueKey_c0b27ad3 = 0
SET
  @IsReadOnly_c0b27ad3 = 1
SET
  @IsRequired_c0b27ad3 = 0
SET
  @Sequence_c0b27ad3 = 10
SET
  @Status_c0b27ad3 = N'Active'
SET
  @IsCustom_c0b27ad3 = 0
SET
  @MetadataSource_c0b27ad3 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_c0b27ad3,
  @IntegrationObjectID = @IntegrationObjectID_c0b27ad3,
  @Name = @Name_c0b27ad3,
  @DisplayName = @DisplayName_c0b27ad3,
  @Description = @Description_c0b27ad3,
  @Category = @Category_c0b27ad3,
  @Category_Clear = 1,
  @Type = @Type_c0b27ad3,
  @Length = @Length_c0b27ad3,
  @Precision = @Precision_c0b27ad3,
  @Precision_Clear = 1,
  @Scale = @Scale_c0b27ad3,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_c0b27ad3,
  @DefaultValue = @DefaultValue_c0b27ad3,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_c0b27ad3,
  @IsUniqueKey = @IsUniqueKey_c0b27ad3,
  @IsReadOnly = @IsReadOnly_c0b27ad3,
  @IsRequired = @IsRequired_c0b27ad3,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_c0b27ad3,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_c0b27ad3,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_c0b27ad3,
  @Configuration = @Configuration_c0b27ad3,
  @Configuration_Clear = 1,
  @Status = @Status_c0b27ad3,
  @IsCustom = @IsCustom_c0b27ad3,
  @MetadataSource = @MetadataSource_c0b27ad3;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_fcf0c49a UNIQUEIDENTIFIER,
@IntegrationObjectID_fcf0c49a UNIQUEIDENTIFIER,
@Name_fcf0c49a NVARCHAR(255),
@DisplayName_fcf0c49a NVARCHAR(255),
@Description_fcf0c49a NVARCHAR(MAX),
@Category_fcf0c49a NVARCHAR(100),
@Type_fcf0c49a NVARCHAR(100),
@Length_fcf0c49a INT,
@Precision_fcf0c49a INT,
@Scale_fcf0c49a INT,
@AllowsNull_fcf0c49a BIT,
@DefaultValue_fcf0c49a NVARCHAR(255),
@IsPrimaryKey_fcf0c49a BIT,
@IsUniqueKey_fcf0c49a BIT,
@IsReadOnly_fcf0c49a BIT,
@IsRequired_fcf0c49a BIT,
@RelatedIntegrationObjectID_fcf0c49a UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_fcf0c49a NVARCHAR(255),
@Sequence_fcf0c49a INT,
@Configuration_fcf0c49a NVARCHAR(MAX),
@Status_fcf0c49a NVARCHAR(25),
@IsCustom_fcf0c49a BIT,
@MetadataSource_fcf0c49a NVARCHAR(20)
SET
  @ID_fcf0c49a = 'EE974AAD-533B-5241-98D7-4F16AC881A44'
SET
  @IntegrationObjectID_fcf0c49a = 'E52B947C-796A-46F1-BD69-BD9CD92FA046'
SET
  @Name_fcf0c49a = N'url'
SET
  @DisplayName_fcf0c49a = N'Url'
SET
  @Description_fcf0c49a = N'URL of the proposal. Lifted from proposal.url.'
SET
  @Type_fcf0c49a = N'String'
SET
  @Length_fcf0c49a = 2048
SET
  @AllowsNull_fcf0c49a = 1
SET
  @IsPrimaryKey_fcf0c49a = 0
SET
  @IsUniqueKey_fcf0c49a = 0
SET
  @IsReadOnly_fcf0c49a = 1
SET
  @IsRequired_fcf0c49a = 0
SET
  @Sequence_fcf0c49a = 11
SET
  @Status_fcf0c49a = N'Active'
SET
  @IsCustom_fcf0c49a = 0
SET
  @MetadataSource_fcf0c49a = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_fcf0c49a,
  @IntegrationObjectID = @IntegrationObjectID_fcf0c49a,
  @Name = @Name_fcf0c49a,
  @DisplayName = @DisplayName_fcf0c49a,
  @Description = @Description_fcf0c49a,
  @Category = @Category_fcf0c49a,
  @Category_Clear = 1,
  @Type = @Type_fcf0c49a,
  @Length = @Length_fcf0c49a,
  @Precision = @Precision_fcf0c49a,
  @Precision_Clear = 1,
  @Scale = @Scale_fcf0c49a,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_fcf0c49a,
  @DefaultValue = @DefaultValue_fcf0c49a,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_fcf0c49a,
  @IsUniqueKey = @IsUniqueKey_fcf0c49a,
  @IsReadOnly = @IsReadOnly_fcf0c49a,
  @IsRequired = @IsRequired_fcf0c49a,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_fcf0c49a,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_fcf0c49a,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_fcf0c49a,
  @Configuration = @Configuration_fcf0c49a,
  @Configuration_Clear = 1,
  @Status = @Status_fcf0c49a,
  @IsCustom = @IsCustom_fcf0c49a,
  @MetadataSource = @MetadataSource_fcf0c49a;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_d3a2005f UNIQUEIDENTIFIER,
@IntegrationObjectID_d3a2005f UNIQUEIDENTIFIER,
@Name_d3a2005f NVARCHAR(255),
@DisplayName_d3a2005f NVARCHAR(255),
@Description_d3a2005f NVARCHAR(MAX),
@Category_d3a2005f NVARCHAR(100),
@Type_d3a2005f NVARCHAR(100),
@Length_d3a2005f INT,
@Precision_d3a2005f INT,
@Scale_d3a2005f INT,
@AllowsNull_d3a2005f BIT,
@DefaultValue_d3a2005f NVARCHAR(255),
@IsPrimaryKey_d3a2005f BIT,
@IsUniqueKey_d3a2005f BIT,
@IsReadOnly_d3a2005f BIT,
@IsRequired_d3a2005f BIT,
@RelatedIntegrationObjectID_d3a2005f UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_d3a2005f NVARCHAR(255),
@Sequence_d3a2005f INT,
@Configuration_d3a2005f NVARCHAR(MAX),
@Status_d3a2005f NVARCHAR(25),
@IsCustom_d3a2005f BIT,
@MetadataSource_d3a2005f NVARCHAR(20)
SET
  @ID_d3a2005f = '5B33A300-02B7-5CC7-9398-B847B02AF9B0'
SET
  @IntegrationObjectID_d3a2005f = 'E52B947C-796A-46F1-BD69-BD9CD92FA046'
SET
  @Name_d3a2005f = N'start-year'
SET
  @DisplayName_d3a2005f = N'Start Year'
SET
  @Description_d3a2005f = N'Year of the proposal start date; ORCID dates are partial, so month/day may be absent.'
SET
  @Type_d3a2005f = N'Integer'
SET
  @AllowsNull_d3a2005f = 1
SET
  @IsPrimaryKey_d3a2005f = 0
SET
  @IsUniqueKey_d3a2005f = 0
SET
  @IsReadOnly_d3a2005f = 1
SET
  @IsRequired_d3a2005f = 0
SET
  @Sequence_d3a2005f = 12
SET
  @Status_d3a2005f = N'Active'
SET
  @IsCustom_d3a2005f = 0
SET
  @MetadataSource_d3a2005f = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_d3a2005f,
  @IntegrationObjectID = @IntegrationObjectID_d3a2005f,
  @Name = @Name_d3a2005f,
  @DisplayName = @DisplayName_d3a2005f,
  @Description = @Description_d3a2005f,
  @Category = @Category_d3a2005f,
  @Category_Clear = 1,
  @Type = @Type_d3a2005f,
  @Length = @Length_d3a2005f,
  @Length_Clear = 1,
  @Precision = @Precision_d3a2005f,
  @Precision_Clear = 1,
  @Scale = @Scale_d3a2005f,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_d3a2005f,
  @DefaultValue = @DefaultValue_d3a2005f,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_d3a2005f,
  @IsUniqueKey = @IsUniqueKey_d3a2005f,
  @IsReadOnly = @IsReadOnly_d3a2005f,
  @IsRequired = @IsRequired_d3a2005f,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_d3a2005f,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_d3a2005f,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_d3a2005f,
  @Configuration = @Configuration_d3a2005f,
  @Configuration_Clear = 1,
  @Status = @Status_d3a2005f,
  @IsCustom = @IsCustom_d3a2005f,
  @MetadataSource = @MetadataSource_d3a2005f;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_99150aba UNIQUEIDENTIFIER,
@IntegrationObjectID_99150aba UNIQUEIDENTIFIER,
@Name_99150aba NVARCHAR(255),
@DisplayName_99150aba NVARCHAR(255),
@Description_99150aba NVARCHAR(MAX),
@Category_99150aba NVARCHAR(100),
@Type_99150aba NVARCHAR(100),
@Length_99150aba INT,
@Precision_99150aba INT,
@Scale_99150aba INT,
@AllowsNull_99150aba BIT,
@DefaultValue_99150aba NVARCHAR(255),
@IsPrimaryKey_99150aba BIT,
@IsUniqueKey_99150aba BIT,
@IsReadOnly_99150aba BIT,
@IsRequired_99150aba BIT,
@RelatedIntegrationObjectID_99150aba UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_99150aba NVARCHAR(255),
@Sequence_99150aba INT,
@Configuration_99150aba NVARCHAR(MAX),
@Status_99150aba NVARCHAR(25),
@IsCustom_99150aba BIT,
@MetadataSource_99150aba NVARCHAR(20)
SET
  @ID_99150aba = '250ED149-786A-57B7-BE06-CE9DEC3052BA'
SET
  @IntegrationObjectID_99150aba = 'E52B947C-796A-46F1-BD69-BD9CD92FA046'
SET
  @Name_99150aba = N'start-month'
SET
  @DisplayName_99150aba = N'Start Month'
SET
  @Description_99150aba = N'Month (1-12) of the proposal start date, when given.'
SET
  @Type_99150aba = N'Integer'
SET
  @AllowsNull_99150aba = 1
SET
  @IsPrimaryKey_99150aba = 0
SET
  @IsUniqueKey_99150aba = 0
SET
  @IsReadOnly_99150aba = 1
SET
  @IsRequired_99150aba = 0
SET
  @Sequence_99150aba = 13
SET
  @Status_99150aba = N'Active'
SET
  @IsCustom_99150aba = 0
SET
  @MetadataSource_99150aba = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_99150aba,
  @IntegrationObjectID = @IntegrationObjectID_99150aba,
  @Name = @Name_99150aba,
  @DisplayName = @DisplayName_99150aba,
  @Description = @Description_99150aba,
  @Category = @Category_99150aba,
  @Category_Clear = 1,
  @Type = @Type_99150aba,
  @Length = @Length_99150aba,
  @Length_Clear = 1,
  @Precision = @Precision_99150aba,
  @Precision_Clear = 1,
  @Scale = @Scale_99150aba,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_99150aba,
  @DefaultValue = @DefaultValue_99150aba,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_99150aba,
  @IsUniqueKey = @IsUniqueKey_99150aba,
  @IsReadOnly = @IsReadOnly_99150aba,
  @IsRequired = @IsRequired_99150aba,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_99150aba,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_99150aba,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_99150aba,
  @Configuration = @Configuration_99150aba,
  @Configuration_Clear = 1,
  @Status = @Status_99150aba,
  @IsCustom = @IsCustom_99150aba,
  @MetadataSource = @MetadataSource_99150aba;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_71cc496d UNIQUEIDENTIFIER,
@IntegrationObjectID_71cc496d UNIQUEIDENTIFIER,
@Name_71cc496d NVARCHAR(255),
@DisplayName_71cc496d NVARCHAR(255),
@Description_71cc496d NVARCHAR(MAX),
@Category_71cc496d NVARCHAR(100),
@Type_71cc496d NVARCHAR(100),
@Length_71cc496d INT,
@Precision_71cc496d INT,
@Scale_71cc496d INT,
@AllowsNull_71cc496d BIT,
@DefaultValue_71cc496d NVARCHAR(255),
@IsPrimaryKey_71cc496d BIT,
@IsUniqueKey_71cc496d BIT,
@IsReadOnly_71cc496d BIT,
@IsRequired_71cc496d BIT,
@RelatedIntegrationObjectID_71cc496d UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_71cc496d NVARCHAR(255),
@Sequence_71cc496d INT,
@Configuration_71cc496d NVARCHAR(MAX),
@Status_71cc496d NVARCHAR(25),
@IsCustom_71cc496d BIT,
@MetadataSource_71cc496d NVARCHAR(20)
SET
  @ID_71cc496d = 'ED354A92-1457-569D-B3E8-6E4F290EC949'
SET
  @IntegrationObjectID_71cc496d = 'E52B947C-796A-46F1-BD69-BD9CD92FA046'
SET
  @Name_71cc496d = N'start-day'
SET
  @DisplayName_71cc496d = N'Start Day'
SET
  @Description_71cc496d = N'Day of month of the proposal start date, when given.'
SET
  @Type_71cc496d = N'Integer'
SET
  @AllowsNull_71cc496d = 1
SET
  @IsPrimaryKey_71cc496d = 0
SET
  @IsUniqueKey_71cc496d = 0
SET
  @IsReadOnly_71cc496d = 1
SET
  @IsRequired_71cc496d = 0
SET
  @Sequence_71cc496d = 14
SET
  @Status_71cc496d = N'Active'
SET
  @IsCustom_71cc496d = 0
SET
  @MetadataSource_71cc496d = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_71cc496d,
  @IntegrationObjectID = @IntegrationObjectID_71cc496d,
  @Name = @Name_71cc496d,
  @DisplayName = @DisplayName_71cc496d,
  @Description = @Description_71cc496d,
  @Category = @Category_71cc496d,
  @Category_Clear = 1,
  @Type = @Type_71cc496d,
  @Length = @Length_71cc496d,
  @Length_Clear = 1,
  @Precision = @Precision_71cc496d,
  @Precision_Clear = 1,
  @Scale = @Scale_71cc496d,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_71cc496d,
  @DefaultValue = @DefaultValue_71cc496d,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_71cc496d,
  @IsUniqueKey = @IsUniqueKey_71cc496d,
  @IsReadOnly = @IsReadOnly_71cc496d,
  @IsRequired = @IsRequired_71cc496d,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_71cc496d,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_71cc496d,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_71cc496d,
  @Configuration = @Configuration_71cc496d,
  @Configuration_Clear = 1,
  @Status = @Status_71cc496d,
  @IsCustom = @IsCustom_71cc496d,
  @MetadataSource = @MetadataSource_71cc496d;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_e5382c9a UNIQUEIDENTIFIER,
@IntegrationObjectID_e5382c9a UNIQUEIDENTIFIER,
@Name_e5382c9a NVARCHAR(255),
@DisplayName_e5382c9a NVARCHAR(255),
@Description_e5382c9a NVARCHAR(MAX),
@Category_e5382c9a NVARCHAR(100),
@Type_e5382c9a NVARCHAR(100),
@Length_e5382c9a INT,
@Precision_e5382c9a INT,
@Scale_e5382c9a INT,
@AllowsNull_e5382c9a BIT,
@DefaultValue_e5382c9a NVARCHAR(255),
@IsPrimaryKey_e5382c9a BIT,
@IsUniqueKey_e5382c9a BIT,
@IsReadOnly_e5382c9a BIT,
@IsRequired_e5382c9a BIT,
@RelatedIntegrationObjectID_e5382c9a UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_e5382c9a NVARCHAR(255),
@Sequence_e5382c9a INT,
@Configuration_e5382c9a NVARCHAR(MAX),
@Status_e5382c9a NVARCHAR(25),
@IsCustom_e5382c9a BIT,
@MetadataSource_e5382c9a NVARCHAR(20)
SET
  @ID_e5382c9a = '0FF94BE2-B88A-52F0-93FA-207005177D21'
SET
  @IntegrationObjectID_e5382c9a = 'E52B947C-796A-46F1-BD69-BD9CD92FA046'
SET
  @Name_e5382c9a = N'end-year'
SET
  @DisplayName_e5382c9a = N'End Year'
SET
  @Description_e5382c9a = N'Year of the proposal end date; ORCID dates are partial, so month/day may be absent.'
SET
  @Type_e5382c9a = N'Integer'
SET
  @AllowsNull_e5382c9a = 1
SET
  @IsPrimaryKey_e5382c9a = 0
SET
  @IsUniqueKey_e5382c9a = 0
SET
  @IsReadOnly_e5382c9a = 1
SET
  @IsRequired_e5382c9a = 0
SET
  @Sequence_e5382c9a = 15
SET
  @Status_e5382c9a = N'Active'
SET
  @IsCustom_e5382c9a = 0
SET
  @MetadataSource_e5382c9a = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_e5382c9a,
  @IntegrationObjectID = @IntegrationObjectID_e5382c9a,
  @Name = @Name_e5382c9a,
  @DisplayName = @DisplayName_e5382c9a,
  @Description = @Description_e5382c9a,
  @Category = @Category_e5382c9a,
  @Category_Clear = 1,
  @Type = @Type_e5382c9a,
  @Length = @Length_e5382c9a,
  @Length_Clear = 1,
  @Precision = @Precision_e5382c9a,
  @Precision_Clear = 1,
  @Scale = @Scale_e5382c9a,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_e5382c9a,
  @DefaultValue = @DefaultValue_e5382c9a,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_e5382c9a,
  @IsUniqueKey = @IsUniqueKey_e5382c9a,
  @IsReadOnly = @IsReadOnly_e5382c9a,
  @IsRequired = @IsRequired_e5382c9a,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_e5382c9a,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_e5382c9a,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_e5382c9a,
  @Configuration = @Configuration_e5382c9a,
  @Configuration_Clear = 1,
  @Status = @Status_e5382c9a,
  @IsCustom = @IsCustom_e5382c9a,
  @MetadataSource = @MetadataSource_e5382c9a;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_91651b40 UNIQUEIDENTIFIER,
@IntegrationObjectID_91651b40 UNIQUEIDENTIFIER,
@Name_91651b40 NVARCHAR(255),
@DisplayName_91651b40 NVARCHAR(255),
@Description_91651b40 NVARCHAR(MAX),
@Category_91651b40 NVARCHAR(100),
@Type_91651b40 NVARCHAR(100),
@Length_91651b40 INT,
@Precision_91651b40 INT,
@Scale_91651b40 INT,
@AllowsNull_91651b40 BIT,
@DefaultValue_91651b40 NVARCHAR(255),
@IsPrimaryKey_91651b40 BIT,
@IsUniqueKey_91651b40 BIT,
@IsReadOnly_91651b40 BIT,
@IsRequired_91651b40 BIT,
@RelatedIntegrationObjectID_91651b40 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_91651b40 NVARCHAR(255),
@Sequence_91651b40 INT,
@Configuration_91651b40 NVARCHAR(MAX),
@Status_91651b40 NVARCHAR(25),
@IsCustom_91651b40 BIT,
@MetadataSource_91651b40 NVARCHAR(20)
SET
  @ID_91651b40 = 'BBD57D1A-B48C-5C67-A43C-BD6EF9E1302D'
SET
  @IntegrationObjectID_91651b40 = 'E52B947C-796A-46F1-BD69-BD9CD92FA046'
SET
  @Name_91651b40 = N'end-month'
SET
  @DisplayName_91651b40 = N'End Month'
SET
  @Description_91651b40 = N'Month (1-12) of the proposal end date, when given.'
SET
  @Type_91651b40 = N'Integer'
SET
  @AllowsNull_91651b40 = 1
SET
  @IsPrimaryKey_91651b40 = 0
SET
  @IsUniqueKey_91651b40 = 0
SET
  @IsReadOnly_91651b40 = 1
SET
  @IsRequired_91651b40 = 0
SET
  @Sequence_91651b40 = 16
SET
  @Status_91651b40 = N'Active'
SET
  @IsCustom_91651b40 = 0
SET
  @MetadataSource_91651b40 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_91651b40,
  @IntegrationObjectID = @IntegrationObjectID_91651b40,
  @Name = @Name_91651b40,
  @DisplayName = @DisplayName_91651b40,
  @Description = @Description_91651b40,
  @Category = @Category_91651b40,
  @Category_Clear = 1,
  @Type = @Type_91651b40,
  @Length = @Length_91651b40,
  @Length_Clear = 1,
  @Precision = @Precision_91651b40,
  @Precision_Clear = 1,
  @Scale = @Scale_91651b40,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_91651b40,
  @DefaultValue = @DefaultValue_91651b40,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_91651b40,
  @IsUniqueKey = @IsUniqueKey_91651b40,
  @IsReadOnly = @IsReadOnly_91651b40,
  @IsRequired = @IsRequired_91651b40,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_91651b40,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_91651b40,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_91651b40,
  @Configuration = @Configuration_91651b40,
  @Configuration_Clear = 1,
  @Status = @Status_91651b40,
  @IsCustom = @IsCustom_91651b40,
  @MetadataSource = @MetadataSource_91651b40;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_700a6b9f UNIQUEIDENTIFIER,
@IntegrationObjectID_700a6b9f UNIQUEIDENTIFIER,
@Name_700a6b9f NVARCHAR(255),
@DisplayName_700a6b9f NVARCHAR(255),
@Description_700a6b9f NVARCHAR(MAX),
@Category_700a6b9f NVARCHAR(100),
@Type_700a6b9f NVARCHAR(100),
@Length_700a6b9f INT,
@Precision_700a6b9f INT,
@Scale_700a6b9f INT,
@AllowsNull_700a6b9f BIT,
@DefaultValue_700a6b9f NVARCHAR(255),
@IsPrimaryKey_700a6b9f BIT,
@IsUniqueKey_700a6b9f BIT,
@IsReadOnly_700a6b9f BIT,
@IsRequired_700a6b9f BIT,
@RelatedIntegrationObjectID_700a6b9f UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_700a6b9f NVARCHAR(255),
@Sequence_700a6b9f INT,
@Configuration_700a6b9f NVARCHAR(MAX),
@Status_700a6b9f NVARCHAR(25),
@IsCustom_700a6b9f BIT,
@MetadataSource_700a6b9f NVARCHAR(20)
SET
  @ID_700a6b9f = '5E5AF098-28E7-5858-B690-0D9D3045E209'
SET
  @IntegrationObjectID_700a6b9f = 'E52B947C-796A-46F1-BD69-BD9CD92FA046'
SET
  @Name_700a6b9f = N'end-day'
SET
  @DisplayName_700a6b9f = N'End Day'
SET
  @Description_700a6b9f = N'Day of month of the proposal end date, when given.'
SET
  @Type_700a6b9f = N'Integer'
SET
  @AllowsNull_700a6b9f = 1
SET
  @IsPrimaryKey_700a6b9f = 0
SET
  @IsUniqueKey_700a6b9f = 0
SET
  @IsReadOnly_700a6b9f = 1
SET
  @IsRequired_700a6b9f = 0
SET
  @Sequence_700a6b9f = 17
SET
  @Status_700a6b9f = N'Active'
SET
  @IsCustom_700a6b9f = 0
SET
  @MetadataSource_700a6b9f = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_700a6b9f,
  @IntegrationObjectID = @IntegrationObjectID_700a6b9f,
  @Name = @Name_700a6b9f,
  @DisplayName = @DisplayName_700a6b9f,
  @Description = @Description_700a6b9f,
  @Category = @Category_700a6b9f,
  @Category_Clear = 1,
  @Type = @Type_700a6b9f,
  @Length = @Length_700a6b9f,
  @Length_Clear = 1,
  @Precision = @Precision_700a6b9f,
  @Precision_Clear = 1,
  @Scale = @Scale_700a6b9f,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_700a6b9f,
  @DefaultValue = @DefaultValue_700a6b9f,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_700a6b9f,
  @IsUniqueKey = @IsUniqueKey_700a6b9f,
  @IsReadOnly = @IsReadOnly_700a6b9f,
  @IsRequired = @IsRequired_700a6b9f,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_700a6b9f,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_700a6b9f,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_700a6b9f,
  @Configuration = @Configuration_700a6b9f,
  @Configuration_Clear = 1,
  @Status = @Status_700a6b9f,
  @IsCustom = @IsCustom_700a6b9f,
  @MetadataSource = @MetadataSource_700a6b9f;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_6ffebd1e UNIQUEIDENTIFIER,
@IntegrationObjectID_6ffebd1e UNIQUEIDENTIFIER,
@Name_6ffebd1e NVARCHAR(255),
@DisplayName_6ffebd1e NVARCHAR(255),
@Description_6ffebd1e NVARCHAR(MAX),
@Category_6ffebd1e NVARCHAR(100),
@Type_6ffebd1e NVARCHAR(100),
@Length_6ffebd1e INT,
@Precision_6ffebd1e INT,
@Scale_6ffebd1e INT,
@AllowsNull_6ffebd1e BIT,
@DefaultValue_6ffebd1e NVARCHAR(255),
@IsPrimaryKey_6ffebd1e BIT,
@IsUniqueKey_6ffebd1e BIT,
@IsReadOnly_6ffebd1e BIT,
@IsRequired_6ffebd1e BIT,
@RelatedIntegrationObjectID_6ffebd1e UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_6ffebd1e NVARCHAR(255),
@Sequence_6ffebd1e INT,
@Configuration_6ffebd1e NVARCHAR(MAX),
@Status_6ffebd1e NVARCHAR(25),
@IsCustom_6ffebd1e BIT,
@MetadataSource_6ffebd1e NVARCHAR(20)
SET
  @ID_6ffebd1e = 'E4C3DA8B-2D1D-5C1F-8B58-E796EB85FF02'
SET
  @IntegrationObjectID_6ffebd1e = 'E52B947C-796A-46F1-BD69-BD9CD92FA046'
SET
  @Name_6ffebd1e = N'source-name'
SET
  @DisplayName_6ffebd1e = N'Source Name'
SET
  @Description_6ffebd1e = N'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.'
SET
  @Type_6ffebd1e = N'String'
SET
  @Length_6ffebd1e = 500
SET
  @AllowsNull_6ffebd1e = 1
SET
  @IsPrimaryKey_6ffebd1e = 0
SET
  @IsUniqueKey_6ffebd1e = 0
SET
  @IsReadOnly_6ffebd1e = 1
SET
  @IsRequired_6ffebd1e = 0
SET
  @Sequence_6ffebd1e = 18
SET
  @Status_6ffebd1e = N'Active'
SET
  @IsCustom_6ffebd1e = 0
SET
  @MetadataSource_6ffebd1e = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_6ffebd1e,
  @IntegrationObjectID = @IntegrationObjectID_6ffebd1e,
  @Name = @Name_6ffebd1e,
  @DisplayName = @DisplayName_6ffebd1e,
  @Description = @Description_6ffebd1e,
  @Category = @Category_6ffebd1e,
  @Category_Clear = 1,
  @Type = @Type_6ffebd1e,
  @Length = @Length_6ffebd1e,
  @Precision = @Precision_6ffebd1e,
  @Precision_Clear = 1,
  @Scale = @Scale_6ffebd1e,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_6ffebd1e,
  @DefaultValue = @DefaultValue_6ffebd1e,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_6ffebd1e,
  @IsUniqueKey = @IsUniqueKey_6ffebd1e,
  @IsReadOnly = @IsReadOnly_6ffebd1e,
  @IsRequired = @IsRequired_6ffebd1e,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_6ffebd1e,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_6ffebd1e,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_6ffebd1e,
  @Configuration = @Configuration_6ffebd1e,
  @Configuration_Clear = 1,
  @Status = @Status_6ffebd1e,
  @IsCustom = @IsCustom_6ffebd1e,
  @MetadataSource = @MetadataSource_6ffebd1e;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_784a4b32 UNIQUEIDENTIFIER,
@IntegrationObjectID_784a4b32 UNIQUEIDENTIFIER,
@Name_784a4b32 NVARCHAR(255),
@DisplayName_784a4b32 NVARCHAR(255),
@Description_784a4b32 NVARCHAR(MAX),
@Category_784a4b32 NVARCHAR(100),
@Type_784a4b32 NVARCHAR(100),
@Length_784a4b32 INT,
@Precision_784a4b32 INT,
@Scale_784a4b32 INT,
@AllowsNull_784a4b32 BIT,
@DefaultValue_784a4b32 NVARCHAR(255),
@IsPrimaryKey_784a4b32 BIT,
@IsUniqueKey_784a4b32 BIT,
@IsReadOnly_784a4b32 BIT,
@IsRequired_784a4b32 BIT,
@RelatedIntegrationObjectID_784a4b32 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_784a4b32 NVARCHAR(255),
@Sequence_784a4b32 INT,
@Configuration_784a4b32 NVARCHAR(MAX),
@Status_784a4b32 NVARCHAR(25),
@IsCustom_784a4b32 BIT,
@MetadataSource_784a4b32 NVARCHAR(20)
SET
  @ID_784a4b32 = 'D8F92718-61FC-5669-B79C-39DC922AFB07'
SET
  @IntegrationObjectID_784a4b32 = 'E52B947C-796A-46F1-BD69-BD9CD92FA046'
SET
  @Name_784a4b32 = N'source-orcid'
SET
  @DisplayName_784a4b32 = N'Source Orcid'
SET
  @Description_784a4b32 = N'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.'
SET
  @Type_784a4b32 = N'String'
SET
  @Length_784a4b32 = 19
SET
  @AllowsNull_784a4b32 = 1
SET
  @IsPrimaryKey_784a4b32 = 0
SET
  @IsUniqueKey_784a4b32 = 0
SET
  @IsReadOnly_784a4b32 = 1
SET
  @IsRequired_784a4b32 = 0
SET
  @Sequence_784a4b32 = 19
SET
  @Status_784a4b32 = N'Active'
SET
  @IsCustom_784a4b32 = 0
SET
  @MetadataSource_784a4b32 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_784a4b32,
  @IntegrationObjectID = @IntegrationObjectID_784a4b32,
  @Name = @Name_784a4b32,
  @DisplayName = @DisplayName_784a4b32,
  @Description = @Description_784a4b32,
  @Category = @Category_784a4b32,
  @Category_Clear = 1,
  @Type = @Type_784a4b32,
  @Length = @Length_784a4b32,
  @Precision = @Precision_784a4b32,
  @Precision_Clear = 1,
  @Scale = @Scale_784a4b32,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_784a4b32,
  @DefaultValue = @DefaultValue_784a4b32,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_784a4b32,
  @IsUniqueKey = @IsUniqueKey_784a4b32,
  @IsReadOnly = @IsReadOnly_784a4b32,
  @IsRequired = @IsRequired_784a4b32,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_784a4b32,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_784a4b32,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_784a4b32,
  @Configuration = @Configuration_784a4b32,
  @Configuration_Clear = 1,
  @Status = @Status_784a4b32,
  @IsCustom = @IsCustom_784a4b32,
  @MetadataSource = @MetadataSource_784a4b32;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_0e04bfe4 UNIQUEIDENTIFIER,
@IntegrationObjectID_0e04bfe4 UNIQUEIDENTIFIER,
@Name_0e04bfe4 NVARCHAR(255),
@DisplayName_0e04bfe4 NVARCHAR(255),
@Description_0e04bfe4 NVARCHAR(MAX),
@Category_0e04bfe4 NVARCHAR(100),
@Type_0e04bfe4 NVARCHAR(100),
@Length_0e04bfe4 INT,
@Precision_0e04bfe4 INT,
@Scale_0e04bfe4 INT,
@AllowsNull_0e04bfe4 BIT,
@DefaultValue_0e04bfe4 NVARCHAR(255),
@IsPrimaryKey_0e04bfe4 BIT,
@IsUniqueKey_0e04bfe4 BIT,
@IsReadOnly_0e04bfe4 BIT,
@IsRequired_0e04bfe4 BIT,
@RelatedIntegrationObjectID_0e04bfe4 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_0e04bfe4 NVARCHAR(255),
@Sequence_0e04bfe4 INT,
@Configuration_0e04bfe4 NVARCHAR(MAX),
@Status_0e04bfe4 NVARCHAR(25),
@IsCustom_0e04bfe4 BIT,
@MetadataSource_0e04bfe4 NVARCHAR(20)
SET
  @ID_0e04bfe4 = '84A2062C-C5CA-5059-9EF9-FE8A49A17237'
SET
  @IntegrationObjectID_0e04bfe4 = 'D4B4DBBD-FF1E-5147-8602-A41DC2855CE5'
SET
  @Name_0e04bfe4 = N'orcid-id'
SET
  @DisplayName_0e04bfe4 = N'Orcid Id'
SET
  @Description_0e04bfe4 = N'The ORCID iD of the researcher this item belongs to. Foreign key to the record object.'
SET
  @Type_0e04bfe4 = N'String'
SET
  @Length_0e04bfe4 = 19
SET
  @AllowsNull_0e04bfe4 = 1
SET
  @IsPrimaryKey_0e04bfe4 = 0
SET
  @IsUniqueKey_0e04bfe4 = 0
SET
  @IsReadOnly_0e04bfe4 = 1
SET
  @IsRequired_0e04bfe4 = 1
SET
  @RelatedIntegrationObjectID_0e04bfe4 = '73AED6B8-468D-403B-B994-F3C786C98BC0'
SET
  @RelatedIntegrationObjectFieldName_0e04bfe4 = N'orcid-id'
SET
  @Sequence_0e04bfe4 = 0
SET
  @Status_0e04bfe4 = N'Active'
SET
  @IsCustom_0e04bfe4 = 0
SET
  @MetadataSource_0e04bfe4 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_0e04bfe4,
  @IntegrationObjectID = @IntegrationObjectID_0e04bfe4,
  @Name = @Name_0e04bfe4,
  @DisplayName = @DisplayName_0e04bfe4,
  @Description = @Description_0e04bfe4,
  @Category = @Category_0e04bfe4,
  @Category_Clear = 1,
  @Type = @Type_0e04bfe4,
  @Length = @Length_0e04bfe4,
  @Precision = @Precision_0e04bfe4,
  @Precision_Clear = 1,
  @Scale = @Scale_0e04bfe4,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_0e04bfe4,
  @DefaultValue = @DefaultValue_0e04bfe4,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_0e04bfe4,
  @IsUniqueKey = @IsUniqueKey_0e04bfe4,
  @IsReadOnly = @IsReadOnly_0e04bfe4,
  @IsRequired = @IsRequired_0e04bfe4,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_0e04bfe4,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_0e04bfe4,
  @Sequence = @Sequence_0e04bfe4,
  @Configuration = @Configuration_0e04bfe4,
  @Configuration_Clear = 1,
  @Status = @Status_0e04bfe4,
  @IsCustom = @IsCustom_0e04bfe4,
  @MetadataSource = @MetadataSource_0e04bfe4;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_5b18ad61 UNIQUEIDENTIFIER,
@IntegrationObjectID_5b18ad61 UNIQUEIDENTIFIER,
@Name_5b18ad61 NVARCHAR(255),
@DisplayName_5b18ad61 NVARCHAR(255),
@Description_5b18ad61 NVARCHAR(MAX),
@Category_5b18ad61 NVARCHAR(100),
@Type_5b18ad61 NVARCHAR(100),
@Length_5b18ad61 INT,
@Precision_5b18ad61 INT,
@Scale_5b18ad61 INT,
@AllowsNull_5b18ad61 BIT,
@DefaultValue_5b18ad61 NVARCHAR(255),
@IsPrimaryKey_5b18ad61 BIT,
@IsUniqueKey_5b18ad61 BIT,
@IsReadOnly_5b18ad61 BIT,
@IsRequired_5b18ad61 BIT,
@RelatedIntegrationObjectID_5b18ad61 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_5b18ad61 NVARCHAR(255),
@Sequence_5b18ad61 INT,
@Configuration_5b18ad61 NVARCHAR(MAX),
@Status_5b18ad61 NVARCHAR(25),
@IsCustom_5b18ad61 BIT,
@MetadataSource_5b18ad61 NVARCHAR(20)
SET
  @ID_5b18ad61 = 'E65C4AD7-3ADD-5458-83CA-39598F732061'
SET
  @IntegrationObjectID_5b18ad61 = 'D4B4DBBD-FF1E-5147-8602-A41DC2855CE5'
SET
  @Name_5b18ad61 = N'put-code'
SET
  @DisplayName_5b18ad61 = N'Put Code'
SET
  @Description_5b18ad61 = N'ORCID''s stable identifier for this item within the record. Primary key.'
SET
  @Type_5b18ad61 = N'Integer'
SET
  @AllowsNull_5b18ad61 = 0
SET
  @IsPrimaryKey_5b18ad61 = 1
SET
  @IsUniqueKey_5b18ad61 = 1
SET
  @IsReadOnly_5b18ad61 = 1
SET
  @IsRequired_5b18ad61 = 1
SET
  @Sequence_5b18ad61 = 1
SET
  @Status_5b18ad61 = N'Active'
SET
  @IsCustom_5b18ad61 = 0
SET
  @MetadataSource_5b18ad61 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_5b18ad61,
  @IntegrationObjectID = @IntegrationObjectID_5b18ad61,
  @Name = @Name_5b18ad61,
  @DisplayName = @DisplayName_5b18ad61,
  @Description = @Description_5b18ad61,
  @Category = @Category_5b18ad61,
  @Category_Clear = 1,
  @Type = @Type_5b18ad61,
  @Length = @Length_5b18ad61,
  @Length_Clear = 1,
  @Precision = @Precision_5b18ad61,
  @Precision_Clear = 1,
  @Scale = @Scale_5b18ad61,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_5b18ad61,
  @DefaultValue = @DefaultValue_5b18ad61,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_5b18ad61,
  @IsUniqueKey = @IsUniqueKey_5b18ad61,
  @IsReadOnly = @IsReadOnly_5b18ad61,
  @IsRequired = @IsRequired_5b18ad61,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_5b18ad61,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_5b18ad61,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_5b18ad61,
  @Configuration = @Configuration_5b18ad61,
  @Configuration_Clear = 1,
  @Status = @Status_5b18ad61,
  @IsCustom = @IsCustom_5b18ad61,
  @MetadataSource = @MetadataSource_5b18ad61;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_8ee5a09b UNIQUEIDENTIFIER,
@IntegrationObjectID_8ee5a09b UNIQUEIDENTIFIER,
@Name_8ee5a09b NVARCHAR(255),
@DisplayName_8ee5a09b NVARCHAR(255),
@Description_8ee5a09b NVARCHAR(MAX),
@Category_8ee5a09b NVARCHAR(100),
@Type_8ee5a09b NVARCHAR(100),
@Length_8ee5a09b INT,
@Precision_8ee5a09b INT,
@Scale_8ee5a09b INT,
@AllowsNull_8ee5a09b BIT,
@DefaultValue_8ee5a09b NVARCHAR(255),
@IsPrimaryKey_8ee5a09b BIT,
@IsUniqueKey_8ee5a09b BIT,
@IsReadOnly_8ee5a09b BIT,
@IsRequired_8ee5a09b BIT,
@RelatedIntegrationObjectID_8ee5a09b UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_8ee5a09b NVARCHAR(255),
@Sequence_8ee5a09b INT,
@Configuration_8ee5a09b NVARCHAR(MAX),
@Status_8ee5a09b NVARCHAR(25),
@IsCustom_8ee5a09b BIT,
@MetadataSource_8ee5a09b NVARCHAR(20)
SET
  @ID_8ee5a09b = 'B382A22B-E3FA-529B-9104-7B1E0F4E3801'
SET
  @IntegrationObjectID_8ee5a09b = 'D4B4DBBD-FF1E-5147-8602-A41DC2855CE5'
SET
  @Name_8ee5a09b = N'path'
SET
  @DisplayName_8ee5a09b = N'Path'
SET
  @Description_8ee5a09b = N'Element path /{orcid}/{section}/{put-code}.'
SET
  @Type_8ee5a09b = N'String'
SET
  @Length_8ee5a09b = 500
SET
  @AllowsNull_8ee5a09b = 1
SET
  @IsPrimaryKey_8ee5a09b = 0
SET
  @IsUniqueKey_8ee5a09b = 0
SET
  @IsReadOnly_8ee5a09b = 1
SET
  @IsRequired_8ee5a09b = 0
SET
  @Sequence_8ee5a09b = 2
SET
  @Status_8ee5a09b = N'Active'
SET
  @IsCustom_8ee5a09b = 0
SET
  @MetadataSource_8ee5a09b = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_8ee5a09b,
  @IntegrationObjectID = @IntegrationObjectID_8ee5a09b,
  @Name = @Name_8ee5a09b,
  @DisplayName = @DisplayName_8ee5a09b,
  @Description = @Description_8ee5a09b,
  @Category = @Category_8ee5a09b,
  @Category_Clear = 1,
  @Type = @Type_8ee5a09b,
  @Length = @Length_8ee5a09b,
  @Precision = @Precision_8ee5a09b,
  @Precision_Clear = 1,
  @Scale = @Scale_8ee5a09b,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_8ee5a09b,
  @DefaultValue = @DefaultValue_8ee5a09b,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_8ee5a09b,
  @IsUniqueKey = @IsUniqueKey_8ee5a09b,
  @IsReadOnly = @IsReadOnly_8ee5a09b,
  @IsRequired = @IsRequired_8ee5a09b,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_8ee5a09b,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_8ee5a09b,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_8ee5a09b,
  @Configuration = @Configuration_8ee5a09b,
  @Configuration_Clear = 1,
  @Status = @Status_8ee5a09b,
  @IsCustom = @IsCustom_8ee5a09b,
  @MetadataSource = @MetadataSource_8ee5a09b;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_51cc8b15 UNIQUEIDENTIFIER,
@IntegrationObjectID_51cc8b15 UNIQUEIDENTIFIER,
@Name_51cc8b15 NVARCHAR(255),
@DisplayName_51cc8b15 NVARCHAR(255),
@Description_51cc8b15 NVARCHAR(MAX),
@Category_51cc8b15 NVARCHAR(100),
@Type_51cc8b15 NVARCHAR(100),
@Length_51cc8b15 INT,
@Precision_51cc8b15 INT,
@Scale_51cc8b15 INT,
@AllowsNull_51cc8b15 BIT,
@DefaultValue_51cc8b15 NVARCHAR(255),
@IsPrimaryKey_51cc8b15 BIT,
@IsUniqueKey_51cc8b15 BIT,
@IsReadOnly_51cc8b15 BIT,
@IsRequired_51cc8b15 BIT,
@RelatedIntegrationObjectID_51cc8b15 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_51cc8b15 NVARCHAR(255),
@Sequence_51cc8b15 INT,
@Configuration_51cc8b15 NVARCHAR(MAX),
@Status_51cc8b15 NVARCHAR(25),
@IsCustom_51cc8b15 BIT,
@MetadataSource_51cc8b15 NVARCHAR(20)
SET
  @ID_51cc8b15 = '63E2C4CD-8665-5B02-9706-77395A483E01'
SET
  @IntegrationObjectID_51cc8b15 = 'D4B4DBBD-FF1E-5147-8602-A41DC2855CE5'
SET
  @Name_51cc8b15 = N'visibility'
SET
  @DisplayName_51cc8b15 = N'Visibility'
SET
  @Description_51cc8b15 = N'ORCID visibility of the item (public, limited, private). The Public API only serves public.'
SET
  @Type_51cc8b15 = N'String'
SET
  @AllowsNull_51cc8b15 = 1
SET
  @IsPrimaryKey_51cc8b15 = 0
SET
  @IsUniqueKey_51cc8b15 = 0
SET
  @IsReadOnly_51cc8b15 = 1
SET
  @IsRequired_51cc8b15 = 0
SET
  @Sequence_51cc8b15 = 3
SET
  @Status_51cc8b15 = N'Active'
SET
  @IsCustom_51cc8b15 = 0
SET
  @MetadataSource_51cc8b15 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_51cc8b15,
  @IntegrationObjectID = @IntegrationObjectID_51cc8b15,
  @Name = @Name_51cc8b15,
  @DisplayName = @DisplayName_51cc8b15,
  @Description = @Description_51cc8b15,
  @Category = @Category_51cc8b15,
  @Category_Clear = 1,
  @Type = @Type_51cc8b15,
  @Length = @Length_51cc8b15,
  @Length_Clear = 1,
  @Precision = @Precision_51cc8b15,
  @Precision_Clear = 1,
  @Scale = @Scale_51cc8b15,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_51cc8b15,
  @DefaultValue = @DefaultValue_51cc8b15,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_51cc8b15,
  @IsUniqueKey = @IsUniqueKey_51cc8b15,
  @IsReadOnly = @IsReadOnly_51cc8b15,
  @IsRequired = @IsRequired_51cc8b15,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_51cc8b15,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_51cc8b15,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_51cc8b15,
  @Configuration = @Configuration_51cc8b15,
  @Configuration_Clear = 1,
  @Status = @Status_51cc8b15,
  @IsCustom = @IsCustom_51cc8b15,
  @MetadataSource = @MetadataSource_51cc8b15;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_6951d60b UNIQUEIDENTIFIER,
@IntegrationObjectID_6951d60b UNIQUEIDENTIFIER,
@Name_6951d60b NVARCHAR(255),
@DisplayName_6951d60b NVARCHAR(255),
@Description_6951d60b NVARCHAR(MAX),
@Category_6951d60b NVARCHAR(100),
@Type_6951d60b NVARCHAR(100),
@Length_6951d60b INT,
@Precision_6951d60b INT,
@Scale_6951d60b INT,
@AllowsNull_6951d60b BIT,
@DefaultValue_6951d60b NVARCHAR(255),
@IsPrimaryKey_6951d60b BIT,
@IsUniqueKey_6951d60b BIT,
@IsReadOnly_6951d60b BIT,
@IsRequired_6951d60b BIT,
@RelatedIntegrationObjectID_6951d60b UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_6951d60b NVARCHAR(255),
@Sequence_6951d60b INT,
@Configuration_6951d60b NVARCHAR(MAX),
@Status_6951d60b NVARCHAR(25),
@IsCustom_6951d60b BIT,
@MetadataSource_6951d60b NVARCHAR(20)
SET
  @ID_6951d60b = 'A2B2483B-4D1E-5A4F-A1CE-5A67838AA36A'
SET
  @IntegrationObjectID_6951d60b = 'D4B4DBBD-FF1E-5147-8602-A41DC2855CE5'
SET
  @Name_6951d60b = N'display-index'
SET
  @DisplayName_6951d60b = N'Display Index'
SET
  @Description_6951d60b = N'Display order the researcher chose for the item.'
SET
  @Type_6951d60b = N'String'
SET
  @AllowsNull_6951d60b = 1
SET
  @IsPrimaryKey_6951d60b = 0
SET
  @IsUniqueKey_6951d60b = 0
SET
  @IsReadOnly_6951d60b = 1
SET
  @IsRequired_6951d60b = 0
SET
  @Sequence_6951d60b = 4
SET
  @Status_6951d60b = N'Active'
SET
  @IsCustom_6951d60b = 0
SET
  @MetadataSource_6951d60b = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_6951d60b,
  @IntegrationObjectID = @IntegrationObjectID_6951d60b,
  @Name = @Name_6951d60b,
  @DisplayName = @DisplayName_6951d60b,
  @Description = @Description_6951d60b,
  @Category = @Category_6951d60b,
  @Category_Clear = 1,
  @Type = @Type_6951d60b,
  @Length = @Length_6951d60b,
  @Length_Clear = 1,
  @Precision = @Precision_6951d60b,
  @Precision_Clear = 1,
  @Scale = @Scale_6951d60b,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_6951d60b,
  @DefaultValue = @DefaultValue_6951d60b,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_6951d60b,
  @IsUniqueKey = @IsUniqueKey_6951d60b,
  @IsReadOnly = @IsReadOnly_6951d60b,
  @IsRequired = @IsRequired_6951d60b,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_6951d60b,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_6951d60b,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_6951d60b,
  @Configuration = @Configuration_6951d60b,
  @Configuration_Clear = 1,
  @Status = @Status_6951d60b,
  @IsCustom = @IsCustom_6951d60b,
  @MetadataSource = @MetadataSource_6951d60b;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_b1a9f55d UNIQUEIDENTIFIER,
@IntegrationObjectID_b1a9f55d UNIQUEIDENTIFIER,
@Name_b1a9f55d NVARCHAR(255),
@DisplayName_b1a9f55d NVARCHAR(255),
@Description_b1a9f55d NVARCHAR(MAX),
@Category_b1a9f55d NVARCHAR(100),
@Type_b1a9f55d NVARCHAR(100),
@Length_b1a9f55d INT,
@Precision_b1a9f55d INT,
@Scale_b1a9f55d INT,
@AllowsNull_b1a9f55d BIT,
@DefaultValue_b1a9f55d NVARCHAR(255),
@IsPrimaryKey_b1a9f55d BIT,
@IsUniqueKey_b1a9f55d BIT,
@IsReadOnly_b1a9f55d BIT,
@IsRequired_b1a9f55d BIT,
@RelatedIntegrationObjectID_b1a9f55d UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_b1a9f55d NVARCHAR(255),
@Sequence_b1a9f55d INT,
@Configuration_b1a9f55d NVARCHAR(MAX),
@Status_b1a9f55d NVARCHAR(25),
@IsCustom_b1a9f55d BIT,
@MetadataSource_b1a9f55d NVARCHAR(20)
SET
  @ID_b1a9f55d = 'D6720B63-C523-5BDE-BB9C-E10F48E0DC12'
SET
  @IntegrationObjectID_b1a9f55d = 'D4B4DBBD-FF1E-5147-8602-A41DC2855CE5'
SET
  @Name_b1a9f55d = N'created-date'
SET
  @DisplayName_b1a9f55d = N'Created Date'
SET
  @Description_b1a9f55d = N'When ORCID created the item.'
SET
  @Type_b1a9f55d = N'DateTime'
SET
  @AllowsNull_b1a9f55d = 1
SET
  @IsPrimaryKey_b1a9f55d = 0
SET
  @IsUniqueKey_b1a9f55d = 0
SET
  @IsReadOnly_b1a9f55d = 1
SET
  @IsRequired_b1a9f55d = 0
SET
  @Sequence_b1a9f55d = 5
SET
  @Status_b1a9f55d = N'Active'
SET
  @IsCustom_b1a9f55d = 0
SET
  @MetadataSource_b1a9f55d = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_b1a9f55d,
  @IntegrationObjectID = @IntegrationObjectID_b1a9f55d,
  @Name = @Name_b1a9f55d,
  @DisplayName = @DisplayName_b1a9f55d,
  @Description = @Description_b1a9f55d,
  @Category = @Category_b1a9f55d,
  @Category_Clear = 1,
  @Type = @Type_b1a9f55d,
  @Length = @Length_b1a9f55d,
  @Length_Clear = 1,
  @Precision = @Precision_b1a9f55d,
  @Precision_Clear = 1,
  @Scale = @Scale_b1a9f55d,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_b1a9f55d,
  @DefaultValue = @DefaultValue_b1a9f55d,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_b1a9f55d,
  @IsUniqueKey = @IsUniqueKey_b1a9f55d,
  @IsReadOnly = @IsReadOnly_b1a9f55d,
  @IsRequired = @IsRequired_b1a9f55d,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_b1a9f55d,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_b1a9f55d,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_b1a9f55d,
  @Configuration = @Configuration_b1a9f55d,
  @Configuration_Clear = 1,
  @Status = @Status_b1a9f55d,
  @IsCustom = @IsCustom_b1a9f55d,
  @MetadataSource = @MetadataSource_b1a9f55d;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_c480091b UNIQUEIDENTIFIER,
@IntegrationObjectID_c480091b UNIQUEIDENTIFIER,
@Name_c480091b NVARCHAR(255),
@DisplayName_c480091b NVARCHAR(255),
@Description_c480091b NVARCHAR(MAX),
@Category_c480091b NVARCHAR(100),
@Type_c480091b NVARCHAR(100),
@Length_c480091b INT,
@Precision_c480091b INT,
@Scale_c480091b INT,
@AllowsNull_c480091b BIT,
@DefaultValue_c480091b NVARCHAR(255),
@IsPrimaryKey_c480091b BIT,
@IsUniqueKey_c480091b BIT,
@IsReadOnly_c480091b BIT,
@IsRequired_c480091b BIT,
@RelatedIntegrationObjectID_c480091b UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_c480091b NVARCHAR(255),
@Sequence_c480091b INT,
@Configuration_c480091b NVARCHAR(MAX),
@Status_c480091b NVARCHAR(25),
@IsCustom_c480091b BIT,
@MetadataSource_c480091b NVARCHAR(20)
SET
  @ID_c480091b = '90B7858F-0700-57A8-8E65-9E1FAACCB91D'
SET
  @IntegrationObjectID_c480091b = 'D4B4DBBD-FF1E-5147-8602-A41DC2855CE5'
SET
  @Name_c480091b = N'last-modified-date'
SET
  @DisplayName_c480091b = N'Last Modified Date'
SET
  @Description_c480091b = N'When ORCID last changed the item. Incremental watermark.'
SET
  @Type_c480091b = N'DateTime'
SET
  @AllowsNull_c480091b = 1
SET
  @IsPrimaryKey_c480091b = 0
SET
  @IsUniqueKey_c480091b = 0
SET
  @IsReadOnly_c480091b = 1
SET
  @IsRequired_c480091b = 0
SET
  @Sequence_c480091b = 6
SET
  @Status_c480091b = N'Active'
SET
  @IsCustom_c480091b = 0
SET
  @MetadataSource_c480091b = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_c480091b,
  @IntegrationObjectID = @IntegrationObjectID_c480091b,
  @Name = @Name_c480091b,
  @DisplayName = @DisplayName_c480091b,
  @Description = @Description_c480091b,
  @Category = @Category_c480091b,
  @Category_Clear = 1,
  @Type = @Type_c480091b,
  @Length = @Length_c480091b,
  @Length_Clear = 1,
  @Precision = @Precision_c480091b,
  @Precision_Clear = 1,
  @Scale = @Scale_c480091b,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_c480091b,
  @DefaultValue = @DefaultValue_c480091b,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_c480091b,
  @IsUniqueKey = @IsUniqueKey_c480091b,
  @IsReadOnly = @IsReadOnly_c480091b,
  @IsRequired = @IsRequired_c480091b,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_c480091b,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_c480091b,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_c480091b,
  @Configuration = @Configuration_c480091b,
  @Configuration_Clear = 1,
  @Status = @Status_c480091b,
  @IsCustom = @IsCustom_c480091b,
  @MetadataSource = @MetadataSource_c480091b;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_43459fb8 UNIQUEIDENTIFIER,
@IntegrationObjectID_43459fb8 UNIQUEIDENTIFIER,
@Name_43459fb8 NVARCHAR(255),
@DisplayName_43459fb8 NVARCHAR(255),
@Description_43459fb8 NVARCHAR(MAX),
@Category_43459fb8 NVARCHAR(100),
@Type_43459fb8 NVARCHAR(100),
@Length_43459fb8 INT,
@Precision_43459fb8 INT,
@Scale_43459fb8 INT,
@AllowsNull_43459fb8 BIT,
@DefaultValue_43459fb8 NVARCHAR(255),
@IsPrimaryKey_43459fb8 BIT,
@IsUniqueKey_43459fb8 BIT,
@IsReadOnly_43459fb8 BIT,
@IsRequired_43459fb8 BIT,
@RelatedIntegrationObjectID_43459fb8 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_43459fb8 NVARCHAR(255),
@Sequence_43459fb8 INT,
@Configuration_43459fb8 NVARCHAR(MAX),
@Status_43459fb8 NVARCHAR(25),
@IsCustom_43459fb8 BIT,
@MetadataSource_43459fb8 NVARCHAR(20)
SET
  @ID_43459fb8 = '00942387-5D59-5FC3-80E5-3AA7F909763D'
SET
  @IntegrationObjectID_43459fb8 = 'D4B4DBBD-FF1E-5147-8602-A41DC2855CE5'
SET
  @Name_43459fb8 = N'source'
SET
  @DisplayName_43459fb8 = N'Source'
SET
  @Description_43459fb8 = N'Full source block: who asserted the item.'
SET
  @Type_43459fb8 = N'json'
SET
  @AllowsNull_43459fb8 = 1
SET
  @IsPrimaryKey_43459fb8 = 0
SET
  @IsUniqueKey_43459fb8 = 0
SET
  @IsReadOnly_43459fb8 = 1
SET
  @IsRequired_43459fb8 = 0
SET
  @Sequence_43459fb8 = 7
SET
  @Status_43459fb8 = N'Active'
SET
  @IsCustom_43459fb8 = 0
SET
  @MetadataSource_43459fb8 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_43459fb8,
  @IntegrationObjectID = @IntegrationObjectID_43459fb8,
  @Name = @Name_43459fb8,
  @DisplayName = @DisplayName_43459fb8,
  @Description = @Description_43459fb8,
  @Category = @Category_43459fb8,
  @Category_Clear = 1,
  @Type = @Type_43459fb8,
  @Length = @Length_43459fb8,
  @Length_Clear = 1,
  @Precision = @Precision_43459fb8,
  @Precision_Clear = 1,
  @Scale = @Scale_43459fb8,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_43459fb8,
  @DefaultValue = @DefaultValue_43459fb8,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_43459fb8,
  @IsUniqueKey = @IsUniqueKey_43459fb8,
  @IsReadOnly = @IsReadOnly_43459fb8,
  @IsRequired = @IsRequired_43459fb8,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_43459fb8,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_43459fb8,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_43459fb8,
  @Configuration = @Configuration_43459fb8,
  @Configuration_Clear = 1,
  @Status = @Status_43459fb8,
  @IsCustom = @IsCustom_43459fb8,
  @MetadataSource = @MetadataSource_43459fb8;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_e7092020 UNIQUEIDENTIFIER,
@IntegrationObjectID_e7092020 UNIQUEIDENTIFIER,
@Name_e7092020 NVARCHAR(255),
@DisplayName_e7092020 NVARCHAR(255),
@Description_e7092020 NVARCHAR(MAX),
@Category_e7092020 NVARCHAR(100),
@Type_e7092020 NVARCHAR(100),
@Length_e7092020 INT,
@Precision_e7092020 INT,
@Scale_e7092020 INT,
@AllowsNull_e7092020 BIT,
@DefaultValue_e7092020 NVARCHAR(255),
@IsPrimaryKey_e7092020 BIT,
@IsUniqueKey_e7092020 BIT,
@IsReadOnly_e7092020 BIT,
@IsRequired_e7092020 BIT,
@RelatedIntegrationObjectID_e7092020 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_e7092020 NVARCHAR(255),
@Sequence_e7092020 INT,
@Configuration_e7092020 NVARCHAR(MAX),
@Status_e7092020 NVARCHAR(25),
@IsCustom_e7092020 BIT,
@MetadataSource_e7092020 NVARCHAR(20)
SET
  @ID_e7092020 = 'DBED6559-5347-5CF7-B015-2BC681288715'
SET
  @IntegrationObjectID_e7092020 = 'D4B4DBBD-FF1E-5147-8602-A41DC2855CE5'
SET
  @Name_e7092020 = N'source-name'
SET
  @DisplayName_e7092020 = N'Source Name'
SET
  @Description_e7092020 = N'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.'
SET
  @Type_e7092020 = N'String'
SET
  @Length_e7092020 = 500
SET
  @AllowsNull_e7092020 = 1
SET
  @IsPrimaryKey_e7092020 = 0
SET
  @IsUniqueKey_e7092020 = 0
SET
  @IsReadOnly_e7092020 = 1
SET
  @IsRequired_e7092020 = 0
SET
  @Sequence_e7092020 = 8
SET
  @Status_e7092020 = N'Active'
SET
  @IsCustom_e7092020 = 0
SET
  @MetadataSource_e7092020 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_e7092020,
  @IntegrationObjectID = @IntegrationObjectID_e7092020,
  @Name = @Name_e7092020,
  @DisplayName = @DisplayName_e7092020,
  @Description = @Description_e7092020,
  @Category = @Category_e7092020,
  @Category_Clear = 1,
  @Type = @Type_e7092020,
  @Length = @Length_e7092020,
  @Precision = @Precision_e7092020,
  @Precision_Clear = 1,
  @Scale = @Scale_e7092020,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_e7092020,
  @DefaultValue = @DefaultValue_e7092020,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_e7092020,
  @IsUniqueKey = @IsUniqueKey_e7092020,
  @IsReadOnly = @IsReadOnly_e7092020,
  @IsRequired = @IsRequired_e7092020,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_e7092020,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_e7092020,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_e7092020,
  @Configuration = @Configuration_e7092020,
  @Configuration_Clear = 1,
  @Status = @Status_e7092020,
  @IsCustom = @IsCustom_e7092020,
  @MetadataSource = @MetadataSource_e7092020;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_63f5e414 UNIQUEIDENTIFIER,
@IntegrationObjectID_63f5e414 UNIQUEIDENTIFIER,
@Name_63f5e414 NVARCHAR(255),
@DisplayName_63f5e414 NVARCHAR(255),
@Description_63f5e414 NVARCHAR(MAX),
@Category_63f5e414 NVARCHAR(100),
@Type_63f5e414 NVARCHAR(100),
@Length_63f5e414 INT,
@Precision_63f5e414 INT,
@Scale_63f5e414 INT,
@AllowsNull_63f5e414 BIT,
@DefaultValue_63f5e414 NVARCHAR(255),
@IsPrimaryKey_63f5e414 BIT,
@IsUniqueKey_63f5e414 BIT,
@IsReadOnly_63f5e414 BIT,
@IsRequired_63f5e414 BIT,
@RelatedIntegrationObjectID_63f5e414 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_63f5e414 NVARCHAR(255),
@Sequence_63f5e414 INT,
@Configuration_63f5e414 NVARCHAR(MAX),
@Status_63f5e414 NVARCHAR(25),
@IsCustom_63f5e414 BIT,
@MetadataSource_63f5e414 NVARCHAR(20)
SET
  @ID_63f5e414 = '88E8778D-242D-5083-A302-3C902017C65D'
SET
  @IntegrationObjectID_63f5e414 = 'D4B4DBBD-FF1E-5147-8602-A41DC2855CE5'
SET
  @Name_63f5e414 = N'source-orcid'
SET
  @DisplayName_63f5e414 = N'Source Orcid'
SET
  @Description_63f5e414 = N'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.'
SET
  @Type_63f5e414 = N'String'
SET
  @Length_63f5e414 = 19
SET
  @AllowsNull_63f5e414 = 1
SET
  @IsPrimaryKey_63f5e414 = 0
SET
  @IsUniqueKey_63f5e414 = 0
SET
  @IsReadOnly_63f5e414 = 1
SET
  @IsRequired_63f5e414 = 0
SET
  @Sequence_63f5e414 = 9
SET
  @Status_63f5e414 = N'Active'
SET
  @IsCustom_63f5e414 = 0
SET
  @MetadataSource_63f5e414 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_63f5e414,
  @IntegrationObjectID = @IntegrationObjectID_63f5e414,
  @Name = @Name_63f5e414,
  @DisplayName = @DisplayName_63f5e414,
  @Description = @Description_63f5e414,
  @Category = @Category_63f5e414,
  @Category_Clear = 1,
  @Type = @Type_63f5e414,
  @Length = @Length_63f5e414,
  @Precision = @Precision_63f5e414,
  @Precision_Clear = 1,
  @Scale = @Scale_63f5e414,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_63f5e414,
  @DefaultValue = @DefaultValue_63f5e414,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_63f5e414,
  @IsUniqueKey = @IsUniqueKey_63f5e414,
  @IsReadOnly = @IsReadOnly_63f5e414,
  @IsRequired = @IsRequired_63f5e414,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_63f5e414,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_63f5e414,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_63f5e414,
  @Configuration = @Configuration_63f5e414,
  @Configuration_Clear = 1,
  @Status = @Status_63f5e414,
  @IsCustom = @IsCustom_63f5e414,
  @MetadataSource = @MetadataSource_63f5e414;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_d167a195 UNIQUEIDENTIFIER,
@IntegrationObjectID_d167a195 UNIQUEIDENTIFIER,
@Name_d167a195 NVARCHAR(255),
@DisplayName_d167a195 NVARCHAR(255),
@Description_d167a195 NVARCHAR(MAX),
@Category_d167a195 NVARCHAR(100),
@Type_d167a195 NVARCHAR(100),
@Length_d167a195 INT,
@Precision_d167a195 INT,
@Scale_d167a195 INT,
@AllowsNull_d167a195 BIT,
@DefaultValue_d167a195 NVARCHAR(255),
@IsPrimaryKey_d167a195 BIT,
@IsUniqueKey_d167a195 BIT,
@IsReadOnly_d167a195 BIT,
@IsRequired_d167a195 BIT,
@RelatedIntegrationObjectID_d167a195 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_d167a195 NVARCHAR(255),
@Sequence_d167a195 INT,
@Configuration_d167a195 NVARCHAR(MAX),
@Status_d167a195 NVARCHAR(25),
@IsCustom_d167a195 BIT,
@MetadataSource_d167a195 NVARCHAR(20)
SET
  @ID_d167a195 = '0DD22C59-7AE4-57EE-8651-1CFFCD746308'
SET
  @IntegrationObjectID_d167a195 = 'D4B4DBBD-FF1E-5147-8602-A41DC2855CE5'
SET
  @Name_d167a195 = N'content'
SET
  @DisplayName_d167a195 = N'Content'
SET
  @Description_d167a195 = N'The alternate name.'
SET
  @Type_d167a195 = N'String'
SET
  @Length_d167a195 = 1000
SET
  @AllowsNull_d167a195 = 1
SET
  @IsPrimaryKey_d167a195 = 0
SET
  @IsUniqueKey_d167a195 = 0
SET
  @IsReadOnly_d167a195 = 1
SET
  @IsRequired_d167a195 = 0
SET
  @Sequence_d167a195 = 10
SET
  @Status_d167a195 = N'Active'
SET
  @IsCustom_d167a195 = 0
SET
  @MetadataSource_d167a195 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_d167a195,
  @IntegrationObjectID = @IntegrationObjectID_d167a195,
  @Name = @Name_d167a195,
  @DisplayName = @DisplayName_d167a195,
  @Description = @Description_d167a195,
  @Category = @Category_d167a195,
  @Category_Clear = 1,
  @Type = @Type_d167a195,
  @Length = @Length_d167a195,
  @Precision = @Precision_d167a195,
  @Precision_Clear = 1,
  @Scale = @Scale_d167a195,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_d167a195,
  @DefaultValue = @DefaultValue_d167a195,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_d167a195,
  @IsUniqueKey = @IsUniqueKey_d167a195,
  @IsReadOnly = @IsReadOnly_d167a195,
  @IsRequired = @IsRequired_d167a195,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_d167a195,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_d167a195,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_d167a195,
  @Configuration = @Configuration_d167a195,
  @Configuration_Clear = 1,
  @Status = @Status_d167a195,
  @IsCustom = @IsCustom_d167a195,
  @MetadataSource = @MetadataSource_d167a195;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_8d851460 UNIQUEIDENTIFIER,
@IntegrationObjectID_8d851460 UNIQUEIDENTIFIER,
@Name_8d851460 NVARCHAR(255),
@DisplayName_8d851460 NVARCHAR(255),
@Description_8d851460 NVARCHAR(MAX),
@Category_8d851460 NVARCHAR(100),
@Type_8d851460 NVARCHAR(100),
@Length_8d851460 INT,
@Precision_8d851460 INT,
@Scale_8d851460 INT,
@AllowsNull_8d851460 BIT,
@DefaultValue_8d851460 NVARCHAR(255),
@IsPrimaryKey_8d851460 BIT,
@IsUniqueKey_8d851460 BIT,
@IsReadOnly_8d851460 BIT,
@IsRequired_8d851460 BIT,
@RelatedIntegrationObjectID_8d851460 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_8d851460 NVARCHAR(255),
@Sequence_8d851460 INT,
@Configuration_8d851460 NVARCHAR(MAX),
@Status_8d851460 NVARCHAR(25),
@IsCustom_8d851460 BIT,
@MetadataSource_8d851460 NVARCHAR(20)
SET
  @ID_8d851460 = '113B4117-B4A7-54C5-A828-85D19F6213F1'
SET
  @IntegrationObjectID_8d851460 = 'C72BE662-43B8-5398-BE8F-FD2145295A4D'
SET
  @Name_8d851460 = N'orcid-id'
SET
  @DisplayName_8d851460 = N'Orcid Id'
SET
  @Description_8d851460 = N'The ORCID iD of the researcher this item belongs to. Foreign key to the record object.'
SET
  @Type_8d851460 = N'String'
SET
  @Length_8d851460 = 19
SET
  @AllowsNull_8d851460 = 1
SET
  @IsPrimaryKey_8d851460 = 0
SET
  @IsUniqueKey_8d851460 = 0
SET
  @IsReadOnly_8d851460 = 1
SET
  @IsRequired_8d851460 = 1
SET
  @RelatedIntegrationObjectID_8d851460 = '73AED6B8-468D-403B-B994-F3C786C98BC0'
SET
  @RelatedIntegrationObjectFieldName_8d851460 = N'orcid-id'
SET
  @Sequence_8d851460 = 0
SET
  @Status_8d851460 = N'Active'
SET
  @IsCustom_8d851460 = 0
SET
  @MetadataSource_8d851460 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_8d851460,
  @IntegrationObjectID = @IntegrationObjectID_8d851460,
  @Name = @Name_8d851460,
  @DisplayName = @DisplayName_8d851460,
  @Description = @Description_8d851460,
  @Category = @Category_8d851460,
  @Category_Clear = 1,
  @Type = @Type_8d851460,
  @Length = @Length_8d851460,
  @Precision = @Precision_8d851460,
  @Precision_Clear = 1,
  @Scale = @Scale_8d851460,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_8d851460,
  @DefaultValue = @DefaultValue_8d851460,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_8d851460,
  @IsUniqueKey = @IsUniqueKey_8d851460,
  @IsReadOnly = @IsReadOnly_8d851460,
  @IsRequired = @IsRequired_8d851460,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_8d851460,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_8d851460,
  @Sequence = @Sequence_8d851460,
  @Configuration = @Configuration_8d851460,
  @Configuration_Clear = 1,
  @Status = @Status_8d851460,
  @IsCustom = @IsCustom_8d851460,
  @MetadataSource = @MetadataSource_8d851460;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_e40a22ac UNIQUEIDENTIFIER,
@IntegrationObjectID_e40a22ac UNIQUEIDENTIFIER,
@Name_e40a22ac NVARCHAR(255),
@DisplayName_e40a22ac NVARCHAR(255),
@Description_e40a22ac NVARCHAR(MAX),
@Category_e40a22ac NVARCHAR(100),
@Type_e40a22ac NVARCHAR(100),
@Length_e40a22ac INT,
@Precision_e40a22ac INT,
@Scale_e40a22ac INT,
@AllowsNull_e40a22ac BIT,
@DefaultValue_e40a22ac NVARCHAR(255),
@IsPrimaryKey_e40a22ac BIT,
@IsUniqueKey_e40a22ac BIT,
@IsReadOnly_e40a22ac BIT,
@IsRequired_e40a22ac BIT,
@RelatedIntegrationObjectID_e40a22ac UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_e40a22ac NVARCHAR(255),
@Sequence_e40a22ac INT,
@Configuration_e40a22ac NVARCHAR(MAX),
@Status_e40a22ac NVARCHAR(25),
@IsCustom_e40a22ac BIT,
@MetadataSource_e40a22ac NVARCHAR(20)
SET
  @ID_e40a22ac = '480C9B5A-6F28-5946-9F52-FA7093B870AB'
SET
  @IntegrationObjectID_e40a22ac = 'C72BE662-43B8-5398-BE8F-FD2145295A4D'
SET
  @Name_e40a22ac = N'put-code'
SET
  @DisplayName_e40a22ac = N'Put Code'
SET
  @Description_e40a22ac = N'ORCID''s stable identifier for this item within the record. Primary key.'
SET
  @Type_e40a22ac = N'Integer'
SET
  @AllowsNull_e40a22ac = 0
SET
  @IsPrimaryKey_e40a22ac = 1
SET
  @IsUniqueKey_e40a22ac = 1
SET
  @IsReadOnly_e40a22ac = 1
SET
  @IsRequired_e40a22ac = 1
SET
  @Sequence_e40a22ac = 1
SET
  @Status_e40a22ac = N'Active'
SET
  @IsCustom_e40a22ac = 0
SET
  @MetadataSource_e40a22ac = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_e40a22ac,
  @IntegrationObjectID = @IntegrationObjectID_e40a22ac,
  @Name = @Name_e40a22ac,
  @DisplayName = @DisplayName_e40a22ac,
  @Description = @Description_e40a22ac,
  @Category = @Category_e40a22ac,
  @Category_Clear = 1,
  @Type = @Type_e40a22ac,
  @Length = @Length_e40a22ac,
  @Length_Clear = 1,
  @Precision = @Precision_e40a22ac,
  @Precision_Clear = 1,
  @Scale = @Scale_e40a22ac,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_e40a22ac,
  @DefaultValue = @DefaultValue_e40a22ac,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_e40a22ac,
  @IsUniqueKey = @IsUniqueKey_e40a22ac,
  @IsReadOnly = @IsReadOnly_e40a22ac,
  @IsRequired = @IsRequired_e40a22ac,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_e40a22ac,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_e40a22ac,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_e40a22ac,
  @Configuration = @Configuration_e40a22ac,
  @Configuration_Clear = 1,
  @Status = @Status_e40a22ac,
  @IsCustom = @IsCustom_e40a22ac,
  @MetadataSource = @MetadataSource_e40a22ac;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_887cb136 UNIQUEIDENTIFIER,
@IntegrationObjectID_887cb136 UNIQUEIDENTIFIER,
@Name_887cb136 NVARCHAR(255),
@DisplayName_887cb136 NVARCHAR(255),
@Description_887cb136 NVARCHAR(MAX),
@Category_887cb136 NVARCHAR(100),
@Type_887cb136 NVARCHAR(100),
@Length_887cb136 INT,
@Precision_887cb136 INT,
@Scale_887cb136 INT,
@AllowsNull_887cb136 BIT,
@DefaultValue_887cb136 NVARCHAR(255),
@IsPrimaryKey_887cb136 BIT,
@IsUniqueKey_887cb136 BIT,
@IsReadOnly_887cb136 BIT,
@IsRequired_887cb136 BIT,
@RelatedIntegrationObjectID_887cb136 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_887cb136 NVARCHAR(255),
@Sequence_887cb136 INT,
@Configuration_887cb136 NVARCHAR(MAX),
@Status_887cb136 NVARCHAR(25),
@IsCustom_887cb136 BIT,
@MetadataSource_887cb136 NVARCHAR(20)
SET
  @ID_887cb136 = 'DB2F48C5-959C-52FC-BA5F-EA16A2C7D5D4'
SET
  @IntegrationObjectID_887cb136 = 'C72BE662-43B8-5398-BE8F-FD2145295A4D'
SET
  @Name_887cb136 = N'path'
SET
  @DisplayName_887cb136 = N'Path'
SET
  @Description_887cb136 = N'Element path /{orcid}/{section}/{put-code}.'
SET
  @Type_887cb136 = N'String'
SET
  @Length_887cb136 = 500
SET
  @AllowsNull_887cb136 = 1
SET
  @IsPrimaryKey_887cb136 = 0
SET
  @IsUniqueKey_887cb136 = 0
SET
  @IsReadOnly_887cb136 = 1
SET
  @IsRequired_887cb136 = 0
SET
  @Sequence_887cb136 = 2
SET
  @Status_887cb136 = N'Active'
SET
  @IsCustom_887cb136 = 0
SET
  @MetadataSource_887cb136 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_887cb136,
  @IntegrationObjectID = @IntegrationObjectID_887cb136,
  @Name = @Name_887cb136,
  @DisplayName = @DisplayName_887cb136,
  @Description = @Description_887cb136,
  @Category = @Category_887cb136,
  @Category_Clear = 1,
  @Type = @Type_887cb136,
  @Length = @Length_887cb136,
  @Precision = @Precision_887cb136,
  @Precision_Clear = 1,
  @Scale = @Scale_887cb136,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_887cb136,
  @DefaultValue = @DefaultValue_887cb136,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_887cb136,
  @IsUniqueKey = @IsUniqueKey_887cb136,
  @IsReadOnly = @IsReadOnly_887cb136,
  @IsRequired = @IsRequired_887cb136,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_887cb136,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_887cb136,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_887cb136,
  @Configuration = @Configuration_887cb136,
  @Configuration_Clear = 1,
  @Status = @Status_887cb136,
  @IsCustom = @IsCustom_887cb136,
  @MetadataSource = @MetadataSource_887cb136;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_41654e4d UNIQUEIDENTIFIER,
@IntegrationObjectID_41654e4d UNIQUEIDENTIFIER,
@Name_41654e4d NVARCHAR(255),
@DisplayName_41654e4d NVARCHAR(255),
@Description_41654e4d NVARCHAR(MAX),
@Category_41654e4d NVARCHAR(100),
@Type_41654e4d NVARCHAR(100),
@Length_41654e4d INT,
@Precision_41654e4d INT,
@Scale_41654e4d INT,
@AllowsNull_41654e4d BIT,
@DefaultValue_41654e4d NVARCHAR(255),
@IsPrimaryKey_41654e4d BIT,
@IsUniqueKey_41654e4d BIT,
@IsReadOnly_41654e4d BIT,
@IsRequired_41654e4d BIT,
@RelatedIntegrationObjectID_41654e4d UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_41654e4d NVARCHAR(255),
@Sequence_41654e4d INT,
@Configuration_41654e4d NVARCHAR(MAX),
@Status_41654e4d NVARCHAR(25),
@IsCustom_41654e4d BIT,
@MetadataSource_41654e4d NVARCHAR(20)
SET
  @ID_41654e4d = 'E9296858-A339-5062-8FC5-199304BFB860'
SET
  @IntegrationObjectID_41654e4d = 'C72BE662-43B8-5398-BE8F-FD2145295A4D'
SET
  @Name_41654e4d = N'visibility'
SET
  @DisplayName_41654e4d = N'Visibility'
SET
  @Description_41654e4d = N'ORCID visibility of the item (public, limited, private). The Public API only serves public.'
SET
  @Type_41654e4d = N'String'
SET
  @AllowsNull_41654e4d = 1
SET
  @IsPrimaryKey_41654e4d = 0
SET
  @IsUniqueKey_41654e4d = 0
SET
  @IsReadOnly_41654e4d = 1
SET
  @IsRequired_41654e4d = 0
SET
  @Sequence_41654e4d = 3
SET
  @Status_41654e4d = N'Active'
SET
  @IsCustom_41654e4d = 0
SET
  @MetadataSource_41654e4d = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_41654e4d,
  @IntegrationObjectID = @IntegrationObjectID_41654e4d,
  @Name = @Name_41654e4d,
  @DisplayName = @DisplayName_41654e4d,
  @Description = @Description_41654e4d,
  @Category = @Category_41654e4d,
  @Category_Clear = 1,
  @Type = @Type_41654e4d,
  @Length = @Length_41654e4d,
  @Length_Clear = 1,
  @Precision = @Precision_41654e4d,
  @Precision_Clear = 1,
  @Scale = @Scale_41654e4d,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_41654e4d,
  @DefaultValue = @DefaultValue_41654e4d,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_41654e4d,
  @IsUniqueKey = @IsUniqueKey_41654e4d,
  @IsReadOnly = @IsReadOnly_41654e4d,
  @IsRequired = @IsRequired_41654e4d,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_41654e4d,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_41654e4d,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_41654e4d,
  @Configuration = @Configuration_41654e4d,
  @Configuration_Clear = 1,
  @Status = @Status_41654e4d,
  @IsCustom = @IsCustom_41654e4d,
  @MetadataSource = @MetadataSource_41654e4d;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_5c8851c7 UNIQUEIDENTIFIER,
@IntegrationObjectID_5c8851c7 UNIQUEIDENTIFIER,
@Name_5c8851c7 NVARCHAR(255),
@DisplayName_5c8851c7 NVARCHAR(255),
@Description_5c8851c7 NVARCHAR(MAX),
@Category_5c8851c7 NVARCHAR(100),
@Type_5c8851c7 NVARCHAR(100),
@Length_5c8851c7 INT,
@Precision_5c8851c7 INT,
@Scale_5c8851c7 INT,
@AllowsNull_5c8851c7 BIT,
@DefaultValue_5c8851c7 NVARCHAR(255),
@IsPrimaryKey_5c8851c7 BIT,
@IsUniqueKey_5c8851c7 BIT,
@IsReadOnly_5c8851c7 BIT,
@IsRequired_5c8851c7 BIT,
@RelatedIntegrationObjectID_5c8851c7 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_5c8851c7 NVARCHAR(255),
@Sequence_5c8851c7 INT,
@Configuration_5c8851c7 NVARCHAR(MAX),
@Status_5c8851c7 NVARCHAR(25),
@IsCustom_5c8851c7 BIT,
@MetadataSource_5c8851c7 NVARCHAR(20)
SET
  @ID_5c8851c7 = '6A436E71-9977-5420-B4AC-A9F34AE9E447'
SET
  @IntegrationObjectID_5c8851c7 = 'C72BE662-43B8-5398-BE8F-FD2145295A4D'
SET
  @Name_5c8851c7 = N'display-index'
SET
  @DisplayName_5c8851c7 = N'Display Index'
SET
  @Description_5c8851c7 = N'Display order the researcher chose for the item.'
SET
  @Type_5c8851c7 = N'String'
SET
  @AllowsNull_5c8851c7 = 1
SET
  @IsPrimaryKey_5c8851c7 = 0
SET
  @IsUniqueKey_5c8851c7 = 0
SET
  @IsReadOnly_5c8851c7 = 1
SET
  @IsRequired_5c8851c7 = 0
SET
  @Sequence_5c8851c7 = 4
SET
  @Status_5c8851c7 = N'Active'
SET
  @IsCustom_5c8851c7 = 0
SET
  @MetadataSource_5c8851c7 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_5c8851c7,
  @IntegrationObjectID = @IntegrationObjectID_5c8851c7,
  @Name = @Name_5c8851c7,
  @DisplayName = @DisplayName_5c8851c7,
  @Description = @Description_5c8851c7,
  @Category = @Category_5c8851c7,
  @Category_Clear = 1,
  @Type = @Type_5c8851c7,
  @Length = @Length_5c8851c7,
  @Length_Clear = 1,
  @Precision = @Precision_5c8851c7,
  @Precision_Clear = 1,
  @Scale = @Scale_5c8851c7,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_5c8851c7,
  @DefaultValue = @DefaultValue_5c8851c7,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_5c8851c7,
  @IsUniqueKey = @IsUniqueKey_5c8851c7,
  @IsReadOnly = @IsReadOnly_5c8851c7,
  @IsRequired = @IsRequired_5c8851c7,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_5c8851c7,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_5c8851c7,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_5c8851c7,
  @Configuration = @Configuration_5c8851c7,
  @Configuration_Clear = 1,
  @Status = @Status_5c8851c7,
  @IsCustom = @IsCustom_5c8851c7,
  @MetadataSource = @MetadataSource_5c8851c7;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_974c8fb2 UNIQUEIDENTIFIER,
@IntegrationObjectID_974c8fb2 UNIQUEIDENTIFIER,
@Name_974c8fb2 NVARCHAR(255),
@DisplayName_974c8fb2 NVARCHAR(255),
@Description_974c8fb2 NVARCHAR(MAX),
@Category_974c8fb2 NVARCHAR(100),
@Type_974c8fb2 NVARCHAR(100),
@Length_974c8fb2 INT,
@Precision_974c8fb2 INT,
@Scale_974c8fb2 INT,
@AllowsNull_974c8fb2 BIT,
@DefaultValue_974c8fb2 NVARCHAR(255),
@IsPrimaryKey_974c8fb2 BIT,
@IsUniqueKey_974c8fb2 BIT,
@IsReadOnly_974c8fb2 BIT,
@IsRequired_974c8fb2 BIT,
@RelatedIntegrationObjectID_974c8fb2 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_974c8fb2 NVARCHAR(255),
@Sequence_974c8fb2 INT,
@Configuration_974c8fb2 NVARCHAR(MAX),
@Status_974c8fb2 NVARCHAR(25),
@IsCustom_974c8fb2 BIT,
@MetadataSource_974c8fb2 NVARCHAR(20)
SET
  @ID_974c8fb2 = '0A7C5E5C-9357-58D7-8C4A-3B2A7A57B918'
SET
  @IntegrationObjectID_974c8fb2 = 'C72BE662-43B8-5398-BE8F-FD2145295A4D'
SET
  @Name_974c8fb2 = N'created-date'
SET
  @DisplayName_974c8fb2 = N'Created Date'
SET
  @Description_974c8fb2 = N'When ORCID created the item.'
SET
  @Type_974c8fb2 = N'DateTime'
SET
  @AllowsNull_974c8fb2 = 1
SET
  @IsPrimaryKey_974c8fb2 = 0
SET
  @IsUniqueKey_974c8fb2 = 0
SET
  @IsReadOnly_974c8fb2 = 1
SET
  @IsRequired_974c8fb2 = 0
SET
  @Sequence_974c8fb2 = 5
SET
  @Status_974c8fb2 = N'Active'
SET
  @IsCustom_974c8fb2 = 0
SET
  @MetadataSource_974c8fb2 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_974c8fb2,
  @IntegrationObjectID = @IntegrationObjectID_974c8fb2,
  @Name = @Name_974c8fb2,
  @DisplayName = @DisplayName_974c8fb2,
  @Description = @Description_974c8fb2,
  @Category = @Category_974c8fb2,
  @Category_Clear = 1,
  @Type = @Type_974c8fb2,
  @Length = @Length_974c8fb2,
  @Length_Clear = 1,
  @Precision = @Precision_974c8fb2,
  @Precision_Clear = 1,
  @Scale = @Scale_974c8fb2,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_974c8fb2,
  @DefaultValue = @DefaultValue_974c8fb2,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_974c8fb2,
  @IsUniqueKey = @IsUniqueKey_974c8fb2,
  @IsReadOnly = @IsReadOnly_974c8fb2,
  @IsRequired = @IsRequired_974c8fb2,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_974c8fb2,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_974c8fb2,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_974c8fb2,
  @Configuration = @Configuration_974c8fb2,
  @Configuration_Clear = 1,
  @Status = @Status_974c8fb2,
  @IsCustom = @IsCustom_974c8fb2,
  @MetadataSource = @MetadataSource_974c8fb2;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_a999acdd UNIQUEIDENTIFIER,
@IntegrationObjectID_a999acdd UNIQUEIDENTIFIER,
@Name_a999acdd NVARCHAR(255),
@DisplayName_a999acdd NVARCHAR(255),
@Description_a999acdd NVARCHAR(MAX),
@Category_a999acdd NVARCHAR(100),
@Type_a999acdd NVARCHAR(100),
@Length_a999acdd INT,
@Precision_a999acdd INT,
@Scale_a999acdd INT,
@AllowsNull_a999acdd BIT,
@DefaultValue_a999acdd NVARCHAR(255),
@IsPrimaryKey_a999acdd BIT,
@IsUniqueKey_a999acdd BIT,
@IsReadOnly_a999acdd BIT,
@IsRequired_a999acdd BIT,
@RelatedIntegrationObjectID_a999acdd UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_a999acdd NVARCHAR(255),
@Sequence_a999acdd INT,
@Configuration_a999acdd NVARCHAR(MAX),
@Status_a999acdd NVARCHAR(25),
@IsCustom_a999acdd BIT,
@MetadataSource_a999acdd NVARCHAR(20)
SET
  @ID_a999acdd = 'A2791AAC-1C9C-5C42-94D1-51BA488C9128'
SET
  @IntegrationObjectID_a999acdd = 'C72BE662-43B8-5398-BE8F-FD2145295A4D'
SET
  @Name_a999acdd = N'last-modified-date'
SET
  @DisplayName_a999acdd = N'Last Modified Date'
SET
  @Description_a999acdd = N'When ORCID last changed the item. Incremental watermark.'
SET
  @Type_a999acdd = N'DateTime'
SET
  @AllowsNull_a999acdd = 1
SET
  @IsPrimaryKey_a999acdd = 0
SET
  @IsUniqueKey_a999acdd = 0
SET
  @IsReadOnly_a999acdd = 1
SET
  @IsRequired_a999acdd = 0
SET
  @Sequence_a999acdd = 6
SET
  @Status_a999acdd = N'Active'
SET
  @IsCustom_a999acdd = 0
SET
  @MetadataSource_a999acdd = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_a999acdd,
  @IntegrationObjectID = @IntegrationObjectID_a999acdd,
  @Name = @Name_a999acdd,
  @DisplayName = @DisplayName_a999acdd,
  @Description = @Description_a999acdd,
  @Category = @Category_a999acdd,
  @Category_Clear = 1,
  @Type = @Type_a999acdd,
  @Length = @Length_a999acdd,
  @Length_Clear = 1,
  @Precision = @Precision_a999acdd,
  @Precision_Clear = 1,
  @Scale = @Scale_a999acdd,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_a999acdd,
  @DefaultValue = @DefaultValue_a999acdd,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_a999acdd,
  @IsUniqueKey = @IsUniqueKey_a999acdd,
  @IsReadOnly = @IsReadOnly_a999acdd,
  @IsRequired = @IsRequired_a999acdd,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_a999acdd,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_a999acdd,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_a999acdd,
  @Configuration = @Configuration_a999acdd,
  @Configuration_Clear = 1,
  @Status = @Status_a999acdd,
  @IsCustom = @IsCustom_a999acdd,
  @MetadataSource = @MetadataSource_a999acdd;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_9c1914ac UNIQUEIDENTIFIER,
@IntegrationObjectID_9c1914ac UNIQUEIDENTIFIER,
@Name_9c1914ac NVARCHAR(255),
@DisplayName_9c1914ac NVARCHAR(255),
@Description_9c1914ac NVARCHAR(MAX),
@Category_9c1914ac NVARCHAR(100),
@Type_9c1914ac NVARCHAR(100),
@Length_9c1914ac INT,
@Precision_9c1914ac INT,
@Scale_9c1914ac INT,
@AllowsNull_9c1914ac BIT,
@DefaultValue_9c1914ac NVARCHAR(255),
@IsPrimaryKey_9c1914ac BIT,
@IsUniqueKey_9c1914ac BIT,
@IsReadOnly_9c1914ac BIT,
@IsRequired_9c1914ac BIT,
@RelatedIntegrationObjectID_9c1914ac UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_9c1914ac NVARCHAR(255),
@Sequence_9c1914ac INT,
@Configuration_9c1914ac NVARCHAR(MAX),
@Status_9c1914ac NVARCHAR(25),
@IsCustom_9c1914ac BIT,
@MetadataSource_9c1914ac NVARCHAR(20)
SET
  @ID_9c1914ac = '6BD36248-BFDA-549F-8AF9-4FE03D122050'
SET
  @IntegrationObjectID_9c1914ac = 'C72BE662-43B8-5398-BE8F-FD2145295A4D'
SET
  @Name_9c1914ac = N'source'
SET
  @DisplayName_9c1914ac = N'Source'
SET
  @Description_9c1914ac = N'Full source block: who asserted the item.'
SET
  @Type_9c1914ac = N'json'
SET
  @AllowsNull_9c1914ac = 1
SET
  @IsPrimaryKey_9c1914ac = 0
SET
  @IsUniqueKey_9c1914ac = 0
SET
  @IsReadOnly_9c1914ac = 1
SET
  @IsRequired_9c1914ac = 0
SET
  @Sequence_9c1914ac = 7
SET
  @Status_9c1914ac = N'Active'
SET
  @IsCustom_9c1914ac = 0
SET
  @MetadataSource_9c1914ac = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_9c1914ac,
  @IntegrationObjectID = @IntegrationObjectID_9c1914ac,
  @Name = @Name_9c1914ac,
  @DisplayName = @DisplayName_9c1914ac,
  @Description = @Description_9c1914ac,
  @Category = @Category_9c1914ac,
  @Category_Clear = 1,
  @Type = @Type_9c1914ac,
  @Length = @Length_9c1914ac,
  @Length_Clear = 1,
  @Precision = @Precision_9c1914ac,
  @Precision_Clear = 1,
  @Scale = @Scale_9c1914ac,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_9c1914ac,
  @DefaultValue = @DefaultValue_9c1914ac,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_9c1914ac,
  @IsUniqueKey = @IsUniqueKey_9c1914ac,
  @IsReadOnly = @IsReadOnly_9c1914ac,
  @IsRequired = @IsRequired_9c1914ac,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_9c1914ac,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_9c1914ac,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_9c1914ac,
  @Configuration = @Configuration_9c1914ac,
  @Configuration_Clear = 1,
  @Status = @Status_9c1914ac,
  @IsCustom = @IsCustom_9c1914ac,
  @MetadataSource = @MetadataSource_9c1914ac;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_b192f120 UNIQUEIDENTIFIER,
@IntegrationObjectID_b192f120 UNIQUEIDENTIFIER,
@Name_b192f120 NVARCHAR(255),
@DisplayName_b192f120 NVARCHAR(255),
@Description_b192f120 NVARCHAR(MAX),
@Category_b192f120 NVARCHAR(100),
@Type_b192f120 NVARCHAR(100),
@Length_b192f120 INT,
@Precision_b192f120 INT,
@Scale_b192f120 INT,
@AllowsNull_b192f120 BIT,
@DefaultValue_b192f120 NVARCHAR(255),
@IsPrimaryKey_b192f120 BIT,
@IsUniqueKey_b192f120 BIT,
@IsReadOnly_b192f120 BIT,
@IsRequired_b192f120 BIT,
@RelatedIntegrationObjectID_b192f120 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_b192f120 NVARCHAR(255),
@Sequence_b192f120 INT,
@Configuration_b192f120 NVARCHAR(MAX),
@Status_b192f120 NVARCHAR(25),
@IsCustom_b192f120 BIT,
@MetadataSource_b192f120 NVARCHAR(20)
SET
  @ID_b192f120 = 'FCFBE228-988A-595C-B65B-FE135B65CA6D'
SET
  @IntegrationObjectID_b192f120 = 'C72BE662-43B8-5398-BE8F-FD2145295A4D'
SET
  @Name_b192f120 = N'source-name'
SET
  @DisplayName_b192f120 = N'Source Name'
SET
  @Description_b192f120 = N'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.'
SET
  @Type_b192f120 = N'String'
SET
  @Length_b192f120 = 500
SET
  @AllowsNull_b192f120 = 1
SET
  @IsPrimaryKey_b192f120 = 0
SET
  @IsUniqueKey_b192f120 = 0
SET
  @IsReadOnly_b192f120 = 1
SET
  @IsRequired_b192f120 = 0
SET
  @Sequence_b192f120 = 8
SET
  @Status_b192f120 = N'Active'
SET
  @IsCustom_b192f120 = 0
SET
  @MetadataSource_b192f120 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_b192f120,
  @IntegrationObjectID = @IntegrationObjectID_b192f120,
  @Name = @Name_b192f120,
  @DisplayName = @DisplayName_b192f120,
  @Description = @Description_b192f120,
  @Category = @Category_b192f120,
  @Category_Clear = 1,
  @Type = @Type_b192f120,
  @Length = @Length_b192f120,
  @Precision = @Precision_b192f120,
  @Precision_Clear = 1,
  @Scale = @Scale_b192f120,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_b192f120,
  @DefaultValue = @DefaultValue_b192f120,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_b192f120,
  @IsUniqueKey = @IsUniqueKey_b192f120,
  @IsReadOnly = @IsReadOnly_b192f120,
  @IsRequired = @IsRequired_b192f120,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_b192f120,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_b192f120,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_b192f120,
  @Configuration = @Configuration_b192f120,
  @Configuration_Clear = 1,
  @Status = @Status_b192f120,
  @IsCustom = @IsCustom_b192f120,
  @MetadataSource = @MetadataSource_b192f120;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_cdb49a50 UNIQUEIDENTIFIER,
@IntegrationObjectID_cdb49a50 UNIQUEIDENTIFIER,
@Name_cdb49a50 NVARCHAR(255),
@DisplayName_cdb49a50 NVARCHAR(255),
@Description_cdb49a50 NVARCHAR(MAX),
@Category_cdb49a50 NVARCHAR(100),
@Type_cdb49a50 NVARCHAR(100),
@Length_cdb49a50 INT,
@Precision_cdb49a50 INT,
@Scale_cdb49a50 INT,
@AllowsNull_cdb49a50 BIT,
@DefaultValue_cdb49a50 NVARCHAR(255),
@IsPrimaryKey_cdb49a50 BIT,
@IsUniqueKey_cdb49a50 BIT,
@IsReadOnly_cdb49a50 BIT,
@IsRequired_cdb49a50 BIT,
@RelatedIntegrationObjectID_cdb49a50 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_cdb49a50 NVARCHAR(255),
@Sequence_cdb49a50 INT,
@Configuration_cdb49a50 NVARCHAR(MAX),
@Status_cdb49a50 NVARCHAR(25),
@IsCustom_cdb49a50 BIT,
@MetadataSource_cdb49a50 NVARCHAR(20)
SET
  @ID_cdb49a50 = '2FDFBC5A-D551-5FF9-B9F9-32504BAA53B7'
SET
  @IntegrationObjectID_cdb49a50 = 'C72BE662-43B8-5398-BE8F-FD2145295A4D'
SET
  @Name_cdb49a50 = N'source-orcid'
SET
  @DisplayName_cdb49a50 = N'Source Orcid'
SET
  @Description_cdb49a50 = N'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.'
SET
  @Type_cdb49a50 = N'String'
SET
  @Length_cdb49a50 = 19
SET
  @AllowsNull_cdb49a50 = 1
SET
  @IsPrimaryKey_cdb49a50 = 0
SET
  @IsUniqueKey_cdb49a50 = 0
SET
  @IsReadOnly_cdb49a50 = 1
SET
  @IsRequired_cdb49a50 = 0
SET
  @Sequence_cdb49a50 = 9
SET
  @Status_cdb49a50 = N'Active'
SET
  @IsCustom_cdb49a50 = 0
SET
  @MetadataSource_cdb49a50 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_cdb49a50,
  @IntegrationObjectID = @IntegrationObjectID_cdb49a50,
  @Name = @Name_cdb49a50,
  @DisplayName = @DisplayName_cdb49a50,
  @Description = @Description_cdb49a50,
  @Category = @Category_cdb49a50,
  @Category_Clear = 1,
  @Type = @Type_cdb49a50,
  @Length = @Length_cdb49a50,
  @Precision = @Precision_cdb49a50,
  @Precision_Clear = 1,
  @Scale = @Scale_cdb49a50,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_cdb49a50,
  @DefaultValue = @DefaultValue_cdb49a50,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_cdb49a50,
  @IsUniqueKey = @IsUniqueKey_cdb49a50,
  @IsReadOnly = @IsReadOnly_cdb49a50,
  @IsRequired = @IsRequired_cdb49a50,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_cdb49a50,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_cdb49a50,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_cdb49a50,
  @Configuration = @Configuration_cdb49a50,
  @Configuration_Clear = 1,
  @Status = @Status_cdb49a50,
  @IsCustom = @IsCustom_cdb49a50,
  @MetadataSource = @MetadataSource_cdb49a50;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_839496f9 UNIQUEIDENTIFIER,
@IntegrationObjectID_839496f9 UNIQUEIDENTIFIER,
@Name_839496f9 NVARCHAR(255),
@DisplayName_839496f9 NVARCHAR(255),
@Description_839496f9 NVARCHAR(MAX),
@Category_839496f9 NVARCHAR(100),
@Type_839496f9 NVARCHAR(100),
@Length_839496f9 INT,
@Precision_839496f9 INT,
@Scale_839496f9 INT,
@AllowsNull_839496f9 BIT,
@DefaultValue_839496f9 NVARCHAR(255),
@IsPrimaryKey_839496f9 BIT,
@IsUniqueKey_839496f9 BIT,
@IsReadOnly_839496f9 BIT,
@IsRequired_839496f9 BIT,
@RelatedIntegrationObjectID_839496f9 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_839496f9 NVARCHAR(255),
@Sequence_839496f9 INT,
@Configuration_839496f9 NVARCHAR(MAX),
@Status_839496f9 NVARCHAR(25),
@IsCustom_839496f9 BIT,
@MetadataSource_839496f9 NVARCHAR(20)
SET
  @ID_839496f9 = '3F49FD1C-BD4E-57D6-BB0B-4EB3BCB34B6F'
SET
  @IntegrationObjectID_839496f9 = 'C72BE662-43B8-5398-BE8F-FD2145295A4D'
SET
  @Name_839496f9 = N'content'
SET
  @DisplayName_839496f9 = N'Content'
SET
  @Description_839496f9 = N'The keyword.'
SET
  @Type_839496f9 = N'String'
SET
  @Length_839496f9 = 1000
SET
  @AllowsNull_839496f9 = 1
SET
  @IsPrimaryKey_839496f9 = 0
SET
  @IsUniqueKey_839496f9 = 0
SET
  @IsReadOnly_839496f9 = 1
SET
  @IsRequired_839496f9 = 0
SET
  @Sequence_839496f9 = 10
SET
  @Status_839496f9 = N'Active'
SET
  @IsCustom_839496f9 = 0
SET
  @MetadataSource_839496f9 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_839496f9,
  @IntegrationObjectID = @IntegrationObjectID_839496f9,
  @Name = @Name_839496f9,
  @DisplayName = @DisplayName_839496f9,
  @Description = @Description_839496f9,
  @Category = @Category_839496f9,
  @Category_Clear = 1,
  @Type = @Type_839496f9,
  @Length = @Length_839496f9,
  @Precision = @Precision_839496f9,
  @Precision_Clear = 1,
  @Scale = @Scale_839496f9,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_839496f9,
  @DefaultValue = @DefaultValue_839496f9,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_839496f9,
  @IsUniqueKey = @IsUniqueKey_839496f9,
  @IsReadOnly = @IsReadOnly_839496f9,
  @IsRequired = @IsRequired_839496f9,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_839496f9,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_839496f9,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_839496f9,
  @Configuration = @Configuration_839496f9,
  @Configuration_Clear = 1,
  @Status = @Status_839496f9,
  @IsCustom = @IsCustom_839496f9,
  @MetadataSource = @MetadataSource_839496f9;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_8e008328 UNIQUEIDENTIFIER,
@IntegrationObjectID_8e008328 UNIQUEIDENTIFIER,
@Name_8e008328 NVARCHAR(255),
@DisplayName_8e008328 NVARCHAR(255),
@Description_8e008328 NVARCHAR(MAX),
@Category_8e008328 NVARCHAR(100),
@Type_8e008328 NVARCHAR(100),
@Length_8e008328 INT,
@Precision_8e008328 INT,
@Scale_8e008328 INT,
@AllowsNull_8e008328 BIT,
@DefaultValue_8e008328 NVARCHAR(255),
@IsPrimaryKey_8e008328 BIT,
@IsUniqueKey_8e008328 BIT,
@IsReadOnly_8e008328 BIT,
@IsRequired_8e008328 BIT,
@RelatedIntegrationObjectID_8e008328 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_8e008328 NVARCHAR(255),
@Sequence_8e008328 INT,
@Configuration_8e008328 NVARCHAR(MAX),
@Status_8e008328 NVARCHAR(25),
@IsCustom_8e008328 BIT,
@MetadataSource_8e008328 NVARCHAR(20)
SET
  @ID_8e008328 = '7A52B43E-0880-532E-894E-CCC38CC88AED'
SET
  @IntegrationObjectID_8e008328 = 'FB6D0904-DD1C-54A2-99AD-901CC4B56562'
SET
  @Name_8e008328 = N'orcid-id'
SET
  @DisplayName_8e008328 = N'Orcid Id'
SET
  @Description_8e008328 = N'The ORCID iD of the researcher this item belongs to. Foreign key to the record object.'
SET
  @Type_8e008328 = N'String'
SET
  @Length_8e008328 = 19
SET
  @AllowsNull_8e008328 = 1
SET
  @IsPrimaryKey_8e008328 = 0
SET
  @IsUniqueKey_8e008328 = 0
SET
  @IsReadOnly_8e008328 = 1
SET
  @IsRequired_8e008328 = 1
SET
  @RelatedIntegrationObjectID_8e008328 = '73AED6B8-468D-403B-B994-F3C786C98BC0'
SET
  @RelatedIntegrationObjectFieldName_8e008328 = N'orcid-id'
SET
  @Sequence_8e008328 = 0
SET
  @Status_8e008328 = N'Active'
SET
  @IsCustom_8e008328 = 0
SET
  @MetadataSource_8e008328 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_8e008328,
  @IntegrationObjectID = @IntegrationObjectID_8e008328,
  @Name = @Name_8e008328,
  @DisplayName = @DisplayName_8e008328,
  @Description = @Description_8e008328,
  @Category = @Category_8e008328,
  @Category_Clear = 1,
  @Type = @Type_8e008328,
  @Length = @Length_8e008328,
  @Precision = @Precision_8e008328,
  @Precision_Clear = 1,
  @Scale = @Scale_8e008328,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_8e008328,
  @DefaultValue = @DefaultValue_8e008328,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_8e008328,
  @IsUniqueKey = @IsUniqueKey_8e008328,
  @IsReadOnly = @IsReadOnly_8e008328,
  @IsRequired = @IsRequired_8e008328,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_8e008328,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_8e008328,
  @Sequence = @Sequence_8e008328,
  @Configuration = @Configuration_8e008328,
  @Configuration_Clear = 1,
  @Status = @Status_8e008328,
  @IsCustom = @IsCustom_8e008328,
  @MetadataSource = @MetadataSource_8e008328;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_e94509e0 UNIQUEIDENTIFIER,
@IntegrationObjectID_e94509e0 UNIQUEIDENTIFIER,
@Name_e94509e0 NVARCHAR(255),
@DisplayName_e94509e0 NVARCHAR(255),
@Description_e94509e0 NVARCHAR(MAX),
@Category_e94509e0 NVARCHAR(100),
@Type_e94509e0 NVARCHAR(100),
@Length_e94509e0 INT,
@Precision_e94509e0 INT,
@Scale_e94509e0 INT,
@AllowsNull_e94509e0 BIT,
@DefaultValue_e94509e0 NVARCHAR(255),
@IsPrimaryKey_e94509e0 BIT,
@IsUniqueKey_e94509e0 BIT,
@IsReadOnly_e94509e0 BIT,
@IsRequired_e94509e0 BIT,
@RelatedIntegrationObjectID_e94509e0 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_e94509e0 NVARCHAR(255),
@Sequence_e94509e0 INT,
@Configuration_e94509e0 NVARCHAR(MAX),
@Status_e94509e0 NVARCHAR(25),
@IsCustom_e94509e0 BIT,
@MetadataSource_e94509e0 NVARCHAR(20)
SET
  @ID_e94509e0 = 'AA06F2EC-04A3-50C8-91E8-AFB5F97BD540'
SET
  @IntegrationObjectID_e94509e0 = 'FB6D0904-DD1C-54A2-99AD-901CC4B56562'
SET
  @Name_e94509e0 = N'put-code'
SET
  @DisplayName_e94509e0 = N'Put Code'
SET
  @Description_e94509e0 = N'ORCID''s stable identifier for this item within the record. Primary key.'
SET
  @Type_e94509e0 = N'Integer'
SET
  @AllowsNull_e94509e0 = 0
SET
  @IsPrimaryKey_e94509e0 = 1
SET
  @IsUniqueKey_e94509e0 = 1
SET
  @IsReadOnly_e94509e0 = 1
SET
  @IsRequired_e94509e0 = 1
SET
  @Sequence_e94509e0 = 1
SET
  @Status_e94509e0 = N'Active'
SET
  @IsCustom_e94509e0 = 0
SET
  @MetadataSource_e94509e0 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_e94509e0,
  @IntegrationObjectID = @IntegrationObjectID_e94509e0,
  @Name = @Name_e94509e0,
  @DisplayName = @DisplayName_e94509e0,
  @Description = @Description_e94509e0,
  @Category = @Category_e94509e0,
  @Category_Clear = 1,
  @Type = @Type_e94509e0,
  @Length = @Length_e94509e0,
  @Length_Clear = 1,
  @Precision = @Precision_e94509e0,
  @Precision_Clear = 1,
  @Scale = @Scale_e94509e0,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_e94509e0,
  @DefaultValue = @DefaultValue_e94509e0,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_e94509e0,
  @IsUniqueKey = @IsUniqueKey_e94509e0,
  @IsReadOnly = @IsReadOnly_e94509e0,
  @IsRequired = @IsRequired_e94509e0,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_e94509e0,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_e94509e0,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_e94509e0,
  @Configuration = @Configuration_e94509e0,
  @Configuration_Clear = 1,
  @Status = @Status_e94509e0,
  @IsCustom = @IsCustom_e94509e0,
  @MetadataSource = @MetadataSource_e94509e0;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_adaab283 UNIQUEIDENTIFIER,
@IntegrationObjectID_adaab283 UNIQUEIDENTIFIER,
@Name_adaab283 NVARCHAR(255),
@DisplayName_adaab283 NVARCHAR(255),
@Description_adaab283 NVARCHAR(MAX),
@Category_adaab283 NVARCHAR(100),
@Type_adaab283 NVARCHAR(100),
@Length_adaab283 INT,
@Precision_adaab283 INT,
@Scale_adaab283 INT,
@AllowsNull_adaab283 BIT,
@DefaultValue_adaab283 NVARCHAR(255),
@IsPrimaryKey_adaab283 BIT,
@IsUniqueKey_adaab283 BIT,
@IsReadOnly_adaab283 BIT,
@IsRequired_adaab283 BIT,
@RelatedIntegrationObjectID_adaab283 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_adaab283 NVARCHAR(255),
@Sequence_adaab283 INT,
@Configuration_adaab283 NVARCHAR(MAX),
@Status_adaab283 NVARCHAR(25),
@IsCustom_adaab283 BIT,
@MetadataSource_adaab283 NVARCHAR(20)
SET
  @ID_adaab283 = '1D53B1A1-3714-524F-BE19-4440B45C0F68'
SET
  @IntegrationObjectID_adaab283 = 'FB6D0904-DD1C-54A2-99AD-901CC4B56562'
SET
  @Name_adaab283 = N'path'
SET
  @DisplayName_adaab283 = N'Path'
SET
  @Description_adaab283 = N'Element path /{orcid}/{section}/{put-code}.'
SET
  @Type_adaab283 = N'String'
SET
  @Length_adaab283 = 500
SET
  @AllowsNull_adaab283 = 1
SET
  @IsPrimaryKey_adaab283 = 0
SET
  @IsUniqueKey_adaab283 = 0
SET
  @IsReadOnly_adaab283 = 1
SET
  @IsRequired_adaab283 = 0
SET
  @Sequence_adaab283 = 2
SET
  @Status_adaab283 = N'Active'
SET
  @IsCustom_adaab283 = 0
SET
  @MetadataSource_adaab283 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_adaab283,
  @IntegrationObjectID = @IntegrationObjectID_adaab283,
  @Name = @Name_adaab283,
  @DisplayName = @DisplayName_adaab283,
  @Description = @Description_adaab283,
  @Category = @Category_adaab283,
  @Category_Clear = 1,
  @Type = @Type_adaab283,
  @Length = @Length_adaab283,
  @Precision = @Precision_adaab283,
  @Precision_Clear = 1,
  @Scale = @Scale_adaab283,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_adaab283,
  @DefaultValue = @DefaultValue_adaab283,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_adaab283,
  @IsUniqueKey = @IsUniqueKey_adaab283,
  @IsReadOnly = @IsReadOnly_adaab283,
  @IsRequired = @IsRequired_adaab283,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_adaab283,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_adaab283,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_adaab283,
  @Configuration = @Configuration_adaab283,
  @Configuration_Clear = 1,
  @Status = @Status_adaab283,
  @IsCustom = @IsCustom_adaab283,
  @MetadataSource = @MetadataSource_adaab283;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_41ee17af UNIQUEIDENTIFIER,
@IntegrationObjectID_41ee17af UNIQUEIDENTIFIER,
@Name_41ee17af NVARCHAR(255),
@DisplayName_41ee17af NVARCHAR(255),
@Description_41ee17af NVARCHAR(MAX),
@Category_41ee17af NVARCHAR(100),
@Type_41ee17af NVARCHAR(100),
@Length_41ee17af INT,
@Precision_41ee17af INT,
@Scale_41ee17af INT,
@AllowsNull_41ee17af BIT,
@DefaultValue_41ee17af NVARCHAR(255),
@IsPrimaryKey_41ee17af BIT,
@IsUniqueKey_41ee17af BIT,
@IsReadOnly_41ee17af BIT,
@IsRequired_41ee17af BIT,
@RelatedIntegrationObjectID_41ee17af UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_41ee17af NVARCHAR(255),
@Sequence_41ee17af INT,
@Configuration_41ee17af NVARCHAR(MAX),
@Status_41ee17af NVARCHAR(25),
@IsCustom_41ee17af BIT,
@MetadataSource_41ee17af NVARCHAR(20)
SET
  @ID_41ee17af = '337BBF35-C60C-5870-B463-09A8614A316E'
SET
  @IntegrationObjectID_41ee17af = 'FB6D0904-DD1C-54A2-99AD-901CC4B56562'
SET
  @Name_41ee17af = N'visibility'
SET
  @DisplayName_41ee17af = N'Visibility'
SET
  @Description_41ee17af = N'ORCID visibility of the item (public, limited, private). The Public API only serves public.'
SET
  @Type_41ee17af = N'String'
SET
  @AllowsNull_41ee17af = 1
SET
  @IsPrimaryKey_41ee17af = 0
SET
  @IsUniqueKey_41ee17af = 0
SET
  @IsReadOnly_41ee17af = 1
SET
  @IsRequired_41ee17af = 0
SET
  @Sequence_41ee17af = 3
SET
  @Status_41ee17af = N'Active'
SET
  @IsCustom_41ee17af = 0
SET
  @MetadataSource_41ee17af = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_41ee17af,
  @IntegrationObjectID = @IntegrationObjectID_41ee17af,
  @Name = @Name_41ee17af,
  @DisplayName = @DisplayName_41ee17af,
  @Description = @Description_41ee17af,
  @Category = @Category_41ee17af,
  @Category_Clear = 1,
  @Type = @Type_41ee17af,
  @Length = @Length_41ee17af,
  @Length_Clear = 1,
  @Precision = @Precision_41ee17af,
  @Precision_Clear = 1,
  @Scale = @Scale_41ee17af,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_41ee17af,
  @DefaultValue = @DefaultValue_41ee17af,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_41ee17af,
  @IsUniqueKey = @IsUniqueKey_41ee17af,
  @IsReadOnly = @IsReadOnly_41ee17af,
  @IsRequired = @IsRequired_41ee17af,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_41ee17af,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_41ee17af,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_41ee17af,
  @Configuration = @Configuration_41ee17af,
  @Configuration_Clear = 1,
  @Status = @Status_41ee17af,
  @IsCustom = @IsCustom_41ee17af,
  @MetadataSource = @MetadataSource_41ee17af;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_952f1197 UNIQUEIDENTIFIER,
@IntegrationObjectID_952f1197 UNIQUEIDENTIFIER,
@Name_952f1197 NVARCHAR(255),
@DisplayName_952f1197 NVARCHAR(255),
@Description_952f1197 NVARCHAR(MAX),
@Category_952f1197 NVARCHAR(100),
@Type_952f1197 NVARCHAR(100),
@Length_952f1197 INT,
@Precision_952f1197 INT,
@Scale_952f1197 INT,
@AllowsNull_952f1197 BIT,
@DefaultValue_952f1197 NVARCHAR(255),
@IsPrimaryKey_952f1197 BIT,
@IsUniqueKey_952f1197 BIT,
@IsReadOnly_952f1197 BIT,
@IsRequired_952f1197 BIT,
@RelatedIntegrationObjectID_952f1197 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_952f1197 NVARCHAR(255),
@Sequence_952f1197 INT,
@Configuration_952f1197 NVARCHAR(MAX),
@Status_952f1197 NVARCHAR(25),
@IsCustom_952f1197 BIT,
@MetadataSource_952f1197 NVARCHAR(20)
SET
  @ID_952f1197 = '68385D55-06E8-53B0-B5E8-E53BFBACEBEB'
SET
  @IntegrationObjectID_952f1197 = 'FB6D0904-DD1C-54A2-99AD-901CC4B56562'
SET
  @Name_952f1197 = N'display-index'
SET
  @DisplayName_952f1197 = N'Display Index'
SET
  @Description_952f1197 = N'Display order the researcher chose for the item.'
SET
  @Type_952f1197 = N'String'
SET
  @AllowsNull_952f1197 = 1
SET
  @IsPrimaryKey_952f1197 = 0
SET
  @IsUniqueKey_952f1197 = 0
SET
  @IsReadOnly_952f1197 = 1
SET
  @IsRequired_952f1197 = 0
SET
  @Sequence_952f1197 = 4
SET
  @Status_952f1197 = N'Active'
SET
  @IsCustom_952f1197 = 0
SET
  @MetadataSource_952f1197 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_952f1197,
  @IntegrationObjectID = @IntegrationObjectID_952f1197,
  @Name = @Name_952f1197,
  @DisplayName = @DisplayName_952f1197,
  @Description = @Description_952f1197,
  @Category = @Category_952f1197,
  @Category_Clear = 1,
  @Type = @Type_952f1197,
  @Length = @Length_952f1197,
  @Length_Clear = 1,
  @Precision = @Precision_952f1197,
  @Precision_Clear = 1,
  @Scale = @Scale_952f1197,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_952f1197,
  @DefaultValue = @DefaultValue_952f1197,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_952f1197,
  @IsUniqueKey = @IsUniqueKey_952f1197,
  @IsReadOnly = @IsReadOnly_952f1197,
  @IsRequired = @IsRequired_952f1197,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_952f1197,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_952f1197,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_952f1197,
  @Configuration = @Configuration_952f1197,
  @Configuration_Clear = 1,
  @Status = @Status_952f1197,
  @IsCustom = @IsCustom_952f1197,
  @MetadataSource = @MetadataSource_952f1197;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_00468658 UNIQUEIDENTIFIER,
@IntegrationObjectID_00468658 UNIQUEIDENTIFIER,
@Name_00468658 NVARCHAR(255),
@DisplayName_00468658 NVARCHAR(255),
@Description_00468658 NVARCHAR(MAX),
@Category_00468658 NVARCHAR(100),
@Type_00468658 NVARCHAR(100),
@Length_00468658 INT,
@Precision_00468658 INT,
@Scale_00468658 INT,
@AllowsNull_00468658 BIT,
@DefaultValue_00468658 NVARCHAR(255),
@IsPrimaryKey_00468658 BIT,
@IsUniqueKey_00468658 BIT,
@IsReadOnly_00468658 BIT,
@IsRequired_00468658 BIT,
@RelatedIntegrationObjectID_00468658 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_00468658 NVARCHAR(255),
@Sequence_00468658 INT,
@Configuration_00468658 NVARCHAR(MAX),
@Status_00468658 NVARCHAR(25),
@IsCustom_00468658 BIT,
@MetadataSource_00468658 NVARCHAR(20)
SET
  @ID_00468658 = '2C91E9CD-2902-5B31-A66B-C1E358C07D41'
SET
  @IntegrationObjectID_00468658 = 'FB6D0904-DD1C-54A2-99AD-901CC4B56562'
SET
  @Name_00468658 = N'created-date'
SET
  @DisplayName_00468658 = N'Created Date'
SET
  @Description_00468658 = N'When ORCID created the item.'
SET
  @Type_00468658 = N'DateTime'
SET
  @AllowsNull_00468658 = 1
SET
  @IsPrimaryKey_00468658 = 0
SET
  @IsUniqueKey_00468658 = 0
SET
  @IsReadOnly_00468658 = 1
SET
  @IsRequired_00468658 = 0
SET
  @Sequence_00468658 = 5
SET
  @Status_00468658 = N'Active'
SET
  @IsCustom_00468658 = 0
SET
  @MetadataSource_00468658 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_00468658,
  @IntegrationObjectID = @IntegrationObjectID_00468658,
  @Name = @Name_00468658,
  @DisplayName = @DisplayName_00468658,
  @Description = @Description_00468658,
  @Category = @Category_00468658,
  @Category_Clear = 1,
  @Type = @Type_00468658,
  @Length = @Length_00468658,
  @Length_Clear = 1,
  @Precision = @Precision_00468658,
  @Precision_Clear = 1,
  @Scale = @Scale_00468658,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_00468658,
  @DefaultValue = @DefaultValue_00468658,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_00468658,
  @IsUniqueKey = @IsUniqueKey_00468658,
  @IsReadOnly = @IsReadOnly_00468658,
  @IsRequired = @IsRequired_00468658,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_00468658,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_00468658,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_00468658,
  @Configuration = @Configuration_00468658,
  @Configuration_Clear = 1,
  @Status = @Status_00468658,
  @IsCustom = @IsCustom_00468658,
  @MetadataSource = @MetadataSource_00468658;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_895a05fd UNIQUEIDENTIFIER,
@IntegrationObjectID_895a05fd UNIQUEIDENTIFIER,
@Name_895a05fd NVARCHAR(255),
@DisplayName_895a05fd NVARCHAR(255),
@Description_895a05fd NVARCHAR(MAX),
@Category_895a05fd NVARCHAR(100),
@Type_895a05fd NVARCHAR(100),
@Length_895a05fd INT,
@Precision_895a05fd INT,
@Scale_895a05fd INT,
@AllowsNull_895a05fd BIT,
@DefaultValue_895a05fd NVARCHAR(255),
@IsPrimaryKey_895a05fd BIT,
@IsUniqueKey_895a05fd BIT,
@IsReadOnly_895a05fd BIT,
@IsRequired_895a05fd BIT,
@RelatedIntegrationObjectID_895a05fd UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_895a05fd NVARCHAR(255),
@Sequence_895a05fd INT,
@Configuration_895a05fd NVARCHAR(MAX),
@Status_895a05fd NVARCHAR(25),
@IsCustom_895a05fd BIT,
@MetadataSource_895a05fd NVARCHAR(20)
SET
  @ID_895a05fd = '102187F1-E6D8-599B-96A5-E56E98692977'
SET
  @IntegrationObjectID_895a05fd = 'FB6D0904-DD1C-54A2-99AD-901CC4B56562'
SET
  @Name_895a05fd = N'last-modified-date'
SET
  @DisplayName_895a05fd = N'Last Modified Date'
SET
  @Description_895a05fd = N'When ORCID last changed the item. Incremental watermark.'
SET
  @Type_895a05fd = N'DateTime'
SET
  @AllowsNull_895a05fd = 1
SET
  @IsPrimaryKey_895a05fd = 0
SET
  @IsUniqueKey_895a05fd = 0
SET
  @IsReadOnly_895a05fd = 1
SET
  @IsRequired_895a05fd = 0
SET
  @Sequence_895a05fd = 6
SET
  @Status_895a05fd = N'Active'
SET
  @IsCustom_895a05fd = 0
SET
  @MetadataSource_895a05fd = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_895a05fd,
  @IntegrationObjectID = @IntegrationObjectID_895a05fd,
  @Name = @Name_895a05fd,
  @DisplayName = @DisplayName_895a05fd,
  @Description = @Description_895a05fd,
  @Category = @Category_895a05fd,
  @Category_Clear = 1,
  @Type = @Type_895a05fd,
  @Length = @Length_895a05fd,
  @Length_Clear = 1,
  @Precision = @Precision_895a05fd,
  @Precision_Clear = 1,
  @Scale = @Scale_895a05fd,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_895a05fd,
  @DefaultValue = @DefaultValue_895a05fd,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_895a05fd,
  @IsUniqueKey = @IsUniqueKey_895a05fd,
  @IsReadOnly = @IsReadOnly_895a05fd,
  @IsRequired = @IsRequired_895a05fd,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_895a05fd,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_895a05fd,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_895a05fd,
  @Configuration = @Configuration_895a05fd,
  @Configuration_Clear = 1,
  @Status = @Status_895a05fd,
  @IsCustom = @IsCustom_895a05fd,
  @MetadataSource = @MetadataSource_895a05fd;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_27802afe UNIQUEIDENTIFIER,
@IntegrationObjectID_27802afe UNIQUEIDENTIFIER,
@Name_27802afe NVARCHAR(255),
@DisplayName_27802afe NVARCHAR(255),
@Description_27802afe NVARCHAR(MAX),
@Category_27802afe NVARCHAR(100),
@Type_27802afe NVARCHAR(100),
@Length_27802afe INT,
@Precision_27802afe INT,
@Scale_27802afe INT,
@AllowsNull_27802afe BIT,
@DefaultValue_27802afe NVARCHAR(255),
@IsPrimaryKey_27802afe BIT,
@IsUniqueKey_27802afe BIT,
@IsReadOnly_27802afe BIT,
@IsRequired_27802afe BIT,
@RelatedIntegrationObjectID_27802afe UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_27802afe NVARCHAR(255),
@Sequence_27802afe INT,
@Configuration_27802afe NVARCHAR(MAX),
@Status_27802afe NVARCHAR(25),
@IsCustom_27802afe BIT,
@MetadataSource_27802afe NVARCHAR(20)
SET
  @ID_27802afe = '80946956-2C57-504E-AE9A-31E1CABFD749'
SET
  @IntegrationObjectID_27802afe = 'FB6D0904-DD1C-54A2-99AD-901CC4B56562'
SET
  @Name_27802afe = N'source'
SET
  @DisplayName_27802afe = N'Source'
SET
  @Description_27802afe = N'Full source block: who asserted the item.'
SET
  @Type_27802afe = N'json'
SET
  @AllowsNull_27802afe = 1
SET
  @IsPrimaryKey_27802afe = 0
SET
  @IsUniqueKey_27802afe = 0
SET
  @IsReadOnly_27802afe = 1
SET
  @IsRequired_27802afe = 0
SET
  @Sequence_27802afe = 7
SET
  @Status_27802afe = N'Active'
SET
  @IsCustom_27802afe = 0
SET
  @MetadataSource_27802afe = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_27802afe,
  @IntegrationObjectID = @IntegrationObjectID_27802afe,
  @Name = @Name_27802afe,
  @DisplayName = @DisplayName_27802afe,
  @Description = @Description_27802afe,
  @Category = @Category_27802afe,
  @Category_Clear = 1,
  @Type = @Type_27802afe,
  @Length = @Length_27802afe,
  @Length_Clear = 1,
  @Precision = @Precision_27802afe,
  @Precision_Clear = 1,
  @Scale = @Scale_27802afe,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_27802afe,
  @DefaultValue = @DefaultValue_27802afe,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_27802afe,
  @IsUniqueKey = @IsUniqueKey_27802afe,
  @IsReadOnly = @IsReadOnly_27802afe,
  @IsRequired = @IsRequired_27802afe,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_27802afe,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_27802afe,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_27802afe,
  @Configuration = @Configuration_27802afe,
  @Configuration_Clear = 1,
  @Status = @Status_27802afe,
  @IsCustom = @IsCustom_27802afe,
  @MetadataSource = @MetadataSource_27802afe;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_ea283fa9 UNIQUEIDENTIFIER,
@IntegrationObjectID_ea283fa9 UNIQUEIDENTIFIER,
@Name_ea283fa9 NVARCHAR(255),
@DisplayName_ea283fa9 NVARCHAR(255),
@Description_ea283fa9 NVARCHAR(MAX),
@Category_ea283fa9 NVARCHAR(100),
@Type_ea283fa9 NVARCHAR(100),
@Length_ea283fa9 INT,
@Precision_ea283fa9 INT,
@Scale_ea283fa9 INT,
@AllowsNull_ea283fa9 BIT,
@DefaultValue_ea283fa9 NVARCHAR(255),
@IsPrimaryKey_ea283fa9 BIT,
@IsUniqueKey_ea283fa9 BIT,
@IsReadOnly_ea283fa9 BIT,
@IsRequired_ea283fa9 BIT,
@RelatedIntegrationObjectID_ea283fa9 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_ea283fa9 NVARCHAR(255),
@Sequence_ea283fa9 INT,
@Configuration_ea283fa9 NVARCHAR(MAX),
@Status_ea283fa9 NVARCHAR(25),
@IsCustom_ea283fa9 BIT,
@MetadataSource_ea283fa9 NVARCHAR(20)
SET
  @ID_ea283fa9 = 'C4076D7B-A9A3-5AA5-AD71-2A58303A9367'
SET
  @IntegrationObjectID_ea283fa9 = 'FB6D0904-DD1C-54A2-99AD-901CC4B56562'
SET
  @Name_ea283fa9 = N'source-name'
SET
  @DisplayName_ea283fa9 = N'Source Name'
SET
  @Description_ea283fa9 = N'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.'
SET
  @Type_ea283fa9 = N'String'
SET
  @Length_ea283fa9 = 500
SET
  @AllowsNull_ea283fa9 = 1
SET
  @IsPrimaryKey_ea283fa9 = 0
SET
  @IsUniqueKey_ea283fa9 = 0
SET
  @IsReadOnly_ea283fa9 = 1
SET
  @IsRequired_ea283fa9 = 0
SET
  @Sequence_ea283fa9 = 8
SET
  @Status_ea283fa9 = N'Active'
SET
  @IsCustom_ea283fa9 = 0
SET
  @MetadataSource_ea283fa9 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_ea283fa9,
  @IntegrationObjectID = @IntegrationObjectID_ea283fa9,
  @Name = @Name_ea283fa9,
  @DisplayName = @DisplayName_ea283fa9,
  @Description = @Description_ea283fa9,
  @Category = @Category_ea283fa9,
  @Category_Clear = 1,
  @Type = @Type_ea283fa9,
  @Length = @Length_ea283fa9,
  @Precision = @Precision_ea283fa9,
  @Precision_Clear = 1,
  @Scale = @Scale_ea283fa9,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_ea283fa9,
  @DefaultValue = @DefaultValue_ea283fa9,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_ea283fa9,
  @IsUniqueKey = @IsUniqueKey_ea283fa9,
  @IsReadOnly = @IsReadOnly_ea283fa9,
  @IsRequired = @IsRequired_ea283fa9,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_ea283fa9,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_ea283fa9,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_ea283fa9,
  @Configuration = @Configuration_ea283fa9,
  @Configuration_Clear = 1,
  @Status = @Status_ea283fa9,
  @IsCustom = @IsCustom_ea283fa9,
  @MetadataSource = @MetadataSource_ea283fa9;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_3f513b53 UNIQUEIDENTIFIER,
@IntegrationObjectID_3f513b53 UNIQUEIDENTIFIER,
@Name_3f513b53 NVARCHAR(255),
@DisplayName_3f513b53 NVARCHAR(255),
@Description_3f513b53 NVARCHAR(MAX),
@Category_3f513b53 NVARCHAR(100),
@Type_3f513b53 NVARCHAR(100),
@Length_3f513b53 INT,
@Precision_3f513b53 INT,
@Scale_3f513b53 INT,
@AllowsNull_3f513b53 BIT,
@DefaultValue_3f513b53 NVARCHAR(255),
@IsPrimaryKey_3f513b53 BIT,
@IsUniqueKey_3f513b53 BIT,
@IsReadOnly_3f513b53 BIT,
@IsRequired_3f513b53 BIT,
@RelatedIntegrationObjectID_3f513b53 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_3f513b53 NVARCHAR(255),
@Sequence_3f513b53 INT,
@Configuration_3f513b53 NVARCHAR(MAX),
@Status_3f513b53 NVARCHAR(25),
@IsCustom_3f513b53 BIT,
@MetadataSource_3f513b53 NVARCHAR(20)
SET
  @ID_3f513b53 = 'B521A565-AEF8-5A44-BB4D-9D928A9A982A'
SET
  @IntegrationObjectID_3f513b53 = 'FB6D0904-DD1C-54A2-99AD-901CC4B56562'
SET
  @Name_3f513b53 = N'source-orcid'
SET
  @DisplayName_3f513b53 = N'Source Orcid'
SET
  @Description_3f513b53 = N'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.'
SET
  @Type_3f513b53 = N'String'
SET
  @Length_3f513b53 = 19
SET
  @AllowsNull_3f513b53 = 1
SET
  @IsPrimaryKey_3f513b53 = 0
SET
  @IsUniqueKey_3f513b53 = 0
SET
  @IsReadOnly_3f513b53 = 1
SET
  @IsRequired_3f513b53 = 0
SET
  @Sequence_3f513b53 = 9
SET
  @Status_3f513b53 = N'Active'
SET
  @IsCustom_3f513b53 = 0
SET
  @MetadataSource_3f513b53 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_3f513b53,
  @IntegrationObjectID = @IntegrationObjectID_3f513b53,
  @Name = @Name_3f513b53,
  @DisplayName = @DisplayName_3f513b53,
  @Description = @Description_3f513b53,
  @Category = @Category_3f513b53,
  @Category_Clear = 1,
  @Type = @Type_3f513b53,
  @Length = @Length_3f513b53,
  @Precision = @Precision_3f513b53,
  @Precision_Clear = 1,
  @Scale = @Scale_3f513b53,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_3f513b53,
  @DefaultValue = @DefaultValue_3f513b53,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_3f513b53,
  @IsUniqueKey = @IsUniqueKey_3f513b53,
  @IsReadOnly = @IsReadOnly_3f513b53,
  @IsRequired = @IsRequired_3f513b53,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_3f513b53,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_3f513b53,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_3f513b53,
  @Configuration = @Configuration_3f513b53,
  @Configuration_Clear = 1,
  @Status = @Status_3f513b53,
  @IsCustom = @IsCustom_3f513b53,
  @MetadataSource = @MetadataSource_3f513b53;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_3ff2ad0e UNIQUEIDENTIFIER,
@IntegrationObjectID_3ff2ad0e UNIQUEIDENTIFIER,
@Name_3ff2ad0e NVARCHAR(255),
@DisplayName_3ff2ad0e NVARCHAR(255),
@Description_3ff2ad0e NVARCHAR(MAX),
@Category_3ff2ad0e NVARCHAR(100),
@Type_3ff2ad0e NVARCHAR(100),
@Length_3ff2ad0e INT,
@Precision_3ff2ad0e INT,
@Scale_3ff2ad0e INT,
@AllowsNull_3ff2ad0e BIT,
@DefaultValue_3ff2ad0e NVARCHAR(255),
@IsPrimaryKey_3ff2ad0e BIT,
@IsUniqueKey_3ff2ad0e BIT,
@IsReadOnly_3ff2ad0e BIT,
@IsRequired_3ff2ad0e BIT,
@RelatedIntegrationObjectID_3ff2ad0e UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_3ff2ad0e NVARCHAR(255),
@Sequence_3ff2ad0e INT,
@Configuration_3ff2ad0e NVARCHAR(MAX),
@Status_3ff2ad0e NVARCHAR(25),
@IsCustom_3ff2ad0e BIT,
@MetadataSource_3ff2ad0e NVARCHAR(20)
SET
  @ID_3ff2ad0e = '8FA8A100-30F3-5E61-8019-AB1224626A8F'
SET
  @IntegrationObjectID_3ff2ad0e = 'FB6D0904-DD1C-54A2-99AD-901CC4B56562'
SET
  @Name_3ff2ad0e = N'email'
SET
  @DisplayName_3ff2ad0e = N'Email'
SET
  @Description_3ff2ad0e = N'The email address.'
SET
  @Type_3ff2ad0e = N'String'
SET
  @Length_3ff2ad0e = 320
SET
  @AllowsNull_3ff2ad0e = 1
SET
  @IsPrimaryKey_3ff2ad0e = 0
SET
  @IsUniqueKey_3ff2ad0e = 0
SET
  @IsReadOnly_3ff2ad0e = 1
SET
  @IsRequired_3ff2ad0e = 0
SET
  @Sequence_3ff2ad0e = 10
SET
  @Status_3ff2ad0e = N'Active'
SET
  @IsCustom_3ff2ad0e = 0
SET
  @MetadataSource_3ff2ad0e = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_3ff2ad0e,
  @IntegrationObjectID = @IntegrationObjectID_3ff2ad0e,
  @Name = @Name_3ff2ad0e,
  @DisplayName = @DisplayName_3ff2ad0e,
  @Description = @Description_3ff2ad0e,
  @Category = @Category_3ff2ad0e,
  @Category_Clear = 1,
  @Type = @Type_3ff2ad0e,
  @Length = @Length_3ff2ad0e,
  @Precision = @Precision_3ff2ad0e,
  @Precision_Clear = 1,
  @Scale = @Scale_3ff2ad0e,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_3ff2ad0e,
  @DefaultValue = @DefaultValue_3ff2ad0e,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_3ff2ad0e,
  @IsUniqueKey = @IsUniqueKey_3ff2ad0e,
  @IsReadOnly = @IsReadOnly_3ff2ad0e,
  @IsRequired = @IsRequired_3ff2ad0e,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_3ff2ad0e,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_3ff2ad0e,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_3ff2ad0e,
  @Configuration = @Configuration_3ff2ad0e,
  @Configuration_Clear = 1,
  @Status = @Status_3ff2ad0e,
  @IsCustom = @IsCustom_3ff2ad0e,
  @MetadataSource = @MetadataSource_3ff2ad0e;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_59186376 UNIQUEIDENTIFIER,
@IntegrationObjectID_59186376 UNIQUEIDENTIFIER,
@Name_59186376 NVARCHAR(255),
@DisplayName_59186376 NVARCHAR(255),
@Description_59186376 NVARCHAR(MAX),
@Category_59186376 NVARCHAR(100),
@Type_59186376 NVARCHAR(100),
@Length_59186376 INT,
@Precision_59186376 INT,
@Scale_59186376 INT,
@AllowsNull_59186376 BIT,
@DefaultValue_59186376 NVARCHAR(255),
@IsPrimaryKey_59186376 BIT,
@IsUniqueKey_59186376 BIT,
@IsReadOnly_59186376 BIT,
@IsRequired_59186376 BIT,
@RelatedIntegrationObjectID_59186376 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_59186376 NVARCHAR(255),
@Sequence_59186376 INT,
@Configuration_59186376 NVARCHAR(MAX),
@Status_59186376 NVARCHAR(25),
@IsCustom_59186376 BIT,
@MetadataSource_59186376 NVARCHAR(20)
SET
  @ID_59186376 = '5A21652F-0D67-54CA-BAC4-71657BE99FFF'
SET
  @IntegrationObjectID_59186376 = 'FB6D0904-DD1C-54A2-99AD-901CC4B56562'
SET
  @Name_59186376 = N'primary'
SET
  @DisplayName_59186376 = N'Primary'
SET
  @Description_59186376 = N'Whether this is the researcher''s primary email.'
SET
  @Type_59186376 = N'Boolean'
SET
  @AllowsNull_59186376 = 1
SET
  @IsPrimaryKey_59186376 = 0
SET
  @IsUniqueKey_59186376 = 0
SET
  @IsReadOnly_59186376 = 1
SET
  @IsRequired_59186376 = 0
SET
  @Sequence_59186376 = 11
SET
  @Status_59186376 = N'Active'
SET
  @IsCustom_59186376 = 0
SET
  @MetadataSource_59186376 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_59186376,
  @IntegrationObjectID = @IntegrationObjectID_59186376,
  @Name = @Name_59186376,
  @DisplayName = @DisplayName_59186376,
  @Description = @Description_59186376,
  @Category = @Category_59186376,
  @Category_Clear = 1,
  @Type = @Type_59186376,
  @Length = @Length_59186376,
  @Length_Clear = 1,
  @Precision = @Precision_59186376,
  @Precision_Clear = 1,
  @Scale = @Scale_59186376,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_59186376,
  @DefaultValue = @DefaultValue_59186376,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_59186376,
  @IsUniqueKey = @IsUniqueKey_59186376,
  @IsReadOnly = @IsReadOnly_59186376,
  @IsRequired = @IsRequired_59186376,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_59186376,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_59186376,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_59186376,
  @Configuration = @Configuration_59186376,
  @Configuration_Clear = 1,
  @Status = @Status_59186376,
  @IsCustom = @IsCustom_59186376,
  @MetadataSource = @MetadataSource_59186376;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_634c0c30 UNIQUEIDENTIFIER,
@IntegrationObjectID_634c0c30 UNIQUEIDENTIFIER,
@Name_634c0c30 NVARCHAR(255),
@DisplayName_634c0c30 NVARCHAR(255),
@Description_634c0c30 NVARCHAR(MAX),
@Category_634c0c30 NVARCHAR(100),
@Type_634c0c30 NVARCHAR(100),
@Length_634c0c30 INT,
@Precision_634c0c30 INT,
@Scale_634c0c30 INT,
@AllowsNull_634c0c30 BIT,
@DefaultValue_634c0c30 NVARCHAR(255),
@IsPrimaryKey_634c0c30 BIT,
@IsUniqueKey_634c0c30 BIT,
@IsReadOnly_634c0c30 BIT,
@IsRequired_634c0c30 BIT,
@RelatedIntegrationObjectID_634c0c30 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_634c0c30 NVARCHAR(255),
@Sequence_634c0c30 INT,
@Configuration_634c0c30 NVARCHAR(MAX),
@Status_634c0c30 NVARCHAR(25),
@IsCustom_634c0c30 BIT,
@MetadataSource_634c0c30 NVARCHAR(20)
SET
  @ID_634c0c30 = '9EFAF38F-340F-5F30-8766-5828F007E547'
SET
  @IntegrationObjectID_634c0c30 = 'FB6D0904-DD1C-54A2-99AD-901CC4B56562'
SET
  @Name_634c0c30 = N'verified'
SET
  @DisplayName_634c0c30 = N'Verified'
SET
  @Description_634c0c30 = N'Whether ORCID verified the address.'
SET
  @Type_634c0c30 = N'Boolean'
SET
  @AllowsNull_634c0c30 = 1
SET
  @IsPrimaryKey_634c0c30 = 0
SET
  @IsUniqueKey_634c0c30 = 0
SET
  @IsReadOnly_634c0c30 = 1
SET
  @IsRequired_634c0c30 = 0
SET
  @Sequence_634c0c30 = 12
SET
  @Status_634c0c30 = N'Active'
SET
  @IsCustom_634c0c30 = 0
SET
  @MetadataSource_634c0c30 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_634c0c30,
  @IntegrationObjectID = @IntegrationObjectID_634c0c30,
  @Name = @Name_634c0c30,
  @DisplayName = @DisplayName_634c0c30,
  @Description = @Description_634c0c30,
  @Category = @Category_634c0c30,
  @Category_Clear = 1,
  @Type = @Type_634c0c30,
  @Length = @Length_634c0c30,
  @Length_Clear = 1,
  @Precision = @Precision_634c0c30,
  @Precision_Clear = 1,
  @Scale = @Scale_634c0c30,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_634c0c30,
  @DefaultValue = @DefaultValue_634c0c30,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_634c0c30,
  @IsUniqueKey = @IsUniqueKey_634c0c30,
  @IsReadOnly = @IsReadOnly_634c0c30,
  @IsRequired = @IsRequired_634c0c30,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_634c0c30,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_634c0c30,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_634c0c30,
  @Configuration = @Configuration_634c0c30,
  @Configuration_Clear = 1,
  @Status = @Status_634c0c30,
  @IsCustom = @IsCustom_634c0c30,
  @MetadataSource = @MetadataSource_634c0c30;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_fe308582 UNIQUEIDENTIFIER,
@IntegrationObjectID_fe308582 UNIQUEIDENTIFIER,
@Name_fe308582 NVARCHAR(255),
@DisplayName_fe308582 NVARCHAR(255),
@Description_fe308582 NVARCHAR(MAX),
@Category_fe308582 NVARCHAR(100),
@Type_fe308582 NVARCHAR(100),
@Length_fe308582 INT,
@Precision_fe308582 INT,
@Scale_fe308582 INT,
@AllowsNull_fe308582 BIT,
@DefaultValue_fe308582 NVARCHAR(255),
@IsPrimaryKey_fe308582 BIT,
@IsUniqueKey_fe308582 BIT,
@IsReadOnly_fe308582 BIT,
@IsRequired_fe308582 BIT,
@RelatedIntegrationObjectID_fe308582 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_fe308582 NVARCHAR(255),
@Sequence_fe308582 INT,
@Configuration_fe308582 NVARCHAR(MAX),
@Status_fe308582 NVARCHAR(25),
@IsCustom_fe308582 BIT,
@MetadataSource_fe308582 NVARCHAR(20)
SET
  @ID_fe308582 = '4E7FC58C-6A5E-5F28-B822-EE0D81BEF665'
SET
  @IntegrationObjectID_fe308582 = 'C4A09B88-C6CC-54DF-8D50-0782A34D0907'
SET
  @Name_fe308582 = N'orcid-id'
SET
  @DisplayName_fe308582 = N'Orcid Id'
SET
  @Description_fe308582 = N'The ORCID iD of the researcher this item belongs to. Foreign key to the record object.'
SET
  @Type_fe308582 = N'String'
SET
  @Length_fe308582 = 19
SET
  @AllowsNull_fe308582 = 1
SET
  @IsPrimaryKey_fe308582 = 0
SET
  @IsUniqueKey_fe308582 = 0
SET
  @IsReadOnly_fe308582 = 1
SET
  @IsRequired_fe308582 = 1
SET
  @RelatedIntegrationObjectID_fe308582 = '73AED6B8-468D-403B-B994-F3C786C98BC0'
SET
  @RelatedIntegrationObjectFieldName_fe308582 = N'orcid-id'
SET
  @Sequence_fe308582 = 0
SET
  @Status_fe308582 = N'Active'
SET
  @IsCustom_fe308582 = 0
SET
  @MetadataSource_fe308582 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_fe308582,
  @IntegrationObjectID = @IntegrationObjectID_fe308582,
  @Name = @Name_fe308582,
  @DisplayName = @DisplayName_fe308582,
  @Description = @Description_fe308582,
  @Category = @Category_fe308582,
  @Category_Clear = 1,
  @Type = @Type_fe308582,
  @Length = @Length_fe308582,
  @Precision = @Precision_fe308582,
  @Precision_Clear = 1,
  @Scale = @Scale_fe308582,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_fe308582,
  @DefaultValue = @DefaultValue_fe308582,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_fe308582,
  @IsUniqueKey = @IsUniqueKey_fe308582,
  @IsReadOnly = @IsReadOnly_fe308582,
  @IsRequired = @IsRequired_fe308582,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_fe308582,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_fe308582,
  @Sequence = @Sequence_fe308582,
  @Configuration = @Configuration_fe308582,
  @Configuration_Clear = 1,
  @Status = @Status_fe308582,
  @IsCustom = @IsCustom_fe308582,
  @MetadataSource = @MetadataSource_fe308582;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_1fcfda48 UNIQUEIDENTIFIER,
@IntegrationObjectID_1fcfda48 UNIQUEIDENTIFIER,
@Name_1fcfda48 NVARCHAR(255),
@DisplayName_1fcfda48 NVARCHAR(255),
@Description_1fcfda48 NVARCHAR(MAX),
@Category_1fcfda48 NVARCHAR(100),
@Type_1fcfda48 NVARCHAR(100),
@Length_1fcfda48 INT,
@Precision_1fcfda48 INT,
@Scale_1fcfda48 INT,
@AllowsNull_1fcfda48 BIT,
@DefaultValue_1fcfda48 NVARCHAR(255),
@IsPrimaryKey_1fcfda48 BIT,
@IsUniqueKey_1fcfda48 BIT,
@IsReadOnly_1fcfda48 BIT,
@IsRequired_1fcfda48 BIT,
@RelatedIntegrationObjectID_1fcfda48 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_1fcfda48 NVARCHAR(255),
@Sequence_1fcfda48 INT,
@Configuration_1fcfda48 NVARCHAR(MAX),
@Status_1fcfda48 NVARCHAR(25),
@IsCustom_1fcfda48 BIT,
@MetadataSource_1fcfda48 NVARCHAR(20)
SET
  @ID_1fcfda48 = '15913FB5-E557-5209-B0D6-83D8036CC4A6'
SET
  @IntegrationObjectID_1fcfda48 = 'C4A09B88-C6CC-54DF-8D50-0782A34D0907'
SET
  @Name_1fcfda48 = N'put-code'
SET
  @DisplayName_1fcfda48 = N'Put Code'
SET
  @Description_1fcfda48 = N'ORCID''s stable identifier for this item within the record. Primary key.'
SET
  @Type_1fcfda48 = N'Integer'
SET
  @AllowsNull_1fcfda48 = 0
SET
  @IsPrimaryKey_1fcfda48 = 1
SET
  @IsUniqueKey_1fcfda48 = 1
SET
  @IsReadOnly_1fcfda48 = 1
SET
  @IsRequired_1fcfda48 = 1
SET
  @Sequence_1fcfda48 = 1
SET
  @Status_1fcfda48 = N'Active'
SET
  @IsCustom_1fcfda48 = 0
SET
  @MetadataSource_1fcfda48 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_1fcfda48,
  @IntegrationObjectID = @IntegrationObjectID_1fcfda48,
  @Name = @Name_1fcfda48,
  @DisplayName = @DisplayName_1fcfda48,
  @Description = @Description_1fcfda48,
  @Category = @Category_1fcfda48,
  @Category_Clear = 1,
  @Type = @Type_1fcfda48,
  @Length = @Length_1fcfda48,
  @Length_Clear = 1,
  @Precision = @Precision_1fcfda48,
  @Precision_Clear = 1,
  @Scale = @Scale_1fcfda48,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_1fcfda48,
  @DefaultValue = @DefaultValue_1fcfda48,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_1fcfda48,
  @IsUniqueKey = @IsUniqueKey_1fcfda48,
  @IsReadOnly = @IsReadOnly_1fcfda48,
  @IsRequired = @IsRequired_1fcfda48,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_1fcfda48,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_1fcfda48,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_1fcfda48,
  @Configuration = @Configuration_1fcfda48,
  @Configuration_Clear = 1,
  @Status = @Status_1fcfda48,
  @IsCustom = @IsCustom_1fcfda48,
  @MetadataSource = @MetadataSource_1fcfda48;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_5568603d UNIQUEIDENTIFIER,
@IntegrationObjectID_5568603d UNIQUEIDENTIFIER,
@Name_5568603d NVARCHAR(255),
@DisplayName_5568603d NVARCHAR(255),
@Description_5568603d NVARCHAR(MAX),
@Category_5568603d NVARCHAR(100),
@Type_5568603d NVARCHAR(100),
@Length_5568603d INT,
@Precision_5568603d INT,
@Scale_5568603d INT,
@AllowsNull_5568603d BIT,
@DefaultValue_5568603d NVARCHAR(255),
@IsPrimaryKey_5568603d BIT,
@IsUniqueKey_5568603d BIT,
@IsReadOnly_5568603d BIT,
@IsRequired_5568603d BIT,
@RelatedIntegrationObjectID_5568603d UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_5568603d NVARCHAR(255),
@Sequence_5568603d INT,
@Configuration_5568603d NVARCHAR(MAX),
@Status_5568603d NVARCHAR(25),
@IsCustom_5568603d BIT,
@MetadataSource_5568603d NVARCHAR(20)
SET
  @ID_5568603d = 'D5952296-3903-52E0-BC44-260A412D5A43'
SET
  @IntegrationObjectID_5568603d = 'C4A09B88-C6CC-54DF-8D50-0782A34D0907'
SET
  @Name_5568603d = N'path'
SET
  @DisplayName_5568603d = N'Path'
SET
  @Description_5568603d = N'Element path /{orcid}/{section}/{put-code}.'
SET
  @Type_5568603d = N'String'
SET
  @Length_5568603d = 500
SET
  @AllowsNull_5568603d = 1
SET
  @IsPrimaryKey_5568603d = 0
SET
  @IsUniqueKey_5568603d = 0
SET
  @IsReadOnly_5568603d = 1
SET
  @IsRequired_5568603d = 0
SET
  @Sequence_5568603d = 2
SET
  @Status_5568603d = N'Active'
SET
  @IsCustom_5568603d = 0
SET
  @MetadataSource_5568603d = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_5568603d,
  @IntegrationObjectID = @IntegrationObjectID_5568603d,
  @Name = @Name_5568603d,
  @DisplayName = @DisplayName_5568603d,
  @Description = @Description_5568603d,
  @Category = @Category_5568603d,
  @Category_Clear = 1,
  @Type = @Type_5568603d,
  @Length = @Length_5568603d,
  @Precision = @Precision_5568603d,
  @Precision_Clear = 1,
  @Scale = @Scale_5568603d,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_5568603d,
  @DefaultValue = @DefaultValue_5568603d,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_5568603d,
  @IsUniqueKey = @IsUniqueKey_5568603d,
  @IsReadOnly = @IsReadOnly_5568603d,
  @IsRequired = @IsRequired_5568603d,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_5568603d,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_5568603d,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_5568603d,
  @Configuration = @Configuration_5568603d,
  @Configuration_Clear = 1,
  @Status = @Status_5568603d,
  @IsCustom = @IsCustom_5568603d,
  @MetadataSource = @MetadataSource_5568603d;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_e1ca2aa5 UNIQUEIDENTIFIER,
@IntegrationObjectID_e1ca2aa5 UNIQUEIDENTIFIER,
@Name_e1ca2aa5 NVARCHAR(255),
@DisplayName_e1ca2aa5 NVARCHAR(255),
@Description_e1ca2aa5 NVARCHAR(MAX),
@Category_e1ca2aa5 NVARCHAR(100),
@Type_e1ca2aa5 NVARCHAR(100),
@Length_e1ca2aa5 INT,
@Precision_e1ca2aa5 INT,
@Scale_e1ca2aa5 INT,
@AllowsNull_e1ca2aa5 BIT,
@DefaultValue_e1ca2aa5 NVARCHAR(255),
@IsPrimaryKey_e1ca2aa5 BIT,
@IsUniqueKey_e1ca2aa5 BIT,
@IsReadOnly_e1ca2aa5 BIT,
@IsRequired_e1ca2aa5 BIT,
@RelatedIntegrationObjectID_e1ca2aa5 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_e1ca2aa5 NVARCHAR(255),
@Sequence_e1ca2aa5 INT,
@Configuration_e1ca2aa5 NVARCHAR(MAX),
@Status_e1ca2aa5 NVARCHAR(25),
@IsCustom_e1ca2aa5 BIT,
@MetadataSource_e1ca2aa5 NVARCHAR(20)
SET
  @ID_e1ca2aa5 = '63528B19-C942-5145-82AD-329C5504064A'
SET
  @IntegrationObjectID_e1ca2aa5 = 'C4A09B88-C6CC-54DF-8D50-0782A34D0907'
SET
  @Name_e1ca2aa5 = N'visibility'
SET
  @DisplayName_e1ca2aa5 = N'Visibility'
SET
  @Description_e1ca2aa5 = N'ORCID visibility of the item (public, limited, private). The Public API only serves public.'
SET
  @Type_e1ca2aa5 = N'String'
SET
  @AllowsNull_e1ca2aa5 = 1
SET
  @IsPrimaryKey_e1ca2aa5 = 0
SET
  @IsUniqueKey_e1ca2aa5 = 0
SET
  @IsReadOnly_e1ca2aa5 = 1
SET
  @IsRequired_e1ca2aa5 = 0
SET
  @Sequence_e1ca2aa5 = 3
SET
  @Status_e1ca2aa5 = N'Active'
SET
  @IsCustom_e1ca2aa5 = 0
SET
  @MetadataSource_e1ca2aa5 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_e1ca2aa5,
  @IntegrationObjectID = @IntegrationObjectID_e1ca2aa5,
  @Name = @Name_e1ca2aa5,
  @DisplayName = @DisplayName_e1ca2aa5,
  @Description = @Description_e1ca2aa5,
  @Category = @Category_e1ca2aa5,
  @Category_Clear = 1,
  @Type = @Type_e1ca2aa5,
  @Length = @Length_e1ca2aa5,
  @Length_Clear = 1,
  @Precision = @Precision_e1ca2aa5,
  @Precision_Clear = 1,
  @Scale = @Scale_e1ca2aa5,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_e1ca2aa5,
  @DefaultValue = @DefaultValue_e1ca2aa5,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_e1ca2aa5,
  @IsUniqueKey = @IsUniqueKey_e1ca2aa5,
  @IsReadOnly = @IsReadOnly_e1ca2aa5,
  @IsRequired = @IsRequired_e1ca2aa5,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_e1ca2aa5,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_e1ca2aa5,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_e1ca2aa5,
  @Configuration = @Configuration_e1ca2aa5,
  @Configuration_Clear = 1,
  @Status = @Status_e1ca2aa5,
  @IsCustom = @IsCustom_e1ca2aa5,
  @MetadataSource = @MetadataSource_e1ca2aa5;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_a6f44a39 UNIQUEIDENTIFIER,
@IntegrationObjectID_a6f44a39 UNIQUEIDENTIFIER,
@Name_a6f44a39 NVARCHAR(255),
@DisplayName_a6f44a39 NVARCHAR(255),
@Description_a6f44a39 NVARCHAR(MAX),
@Category_a6f44a39 NVARCHAR(100),
@Type_a6f44a39 NVARCHAR(100),
@Length_a6f44a39 INT,
@Precision_a6f44a39 INT,
@Scale_a6f44a39 INT,
@AllowsNull_a6f44a39 BIT,
@DefaultValue_a6f44a39 NVARCHAR(255),
@IsPrimaryKey_a6f44a39 BIT,
@IsUniqueKey_a6f44a39 BIT,
@IsReadOnly_a6f44a39 BIT,
@IsRequired_a6f44a39 BIT,
@RelatedIntegrationObjectID_a6f44a39 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_a6f44a39 NVARCHAR(255),
@Sequence_a6f44a39 INT,
@Configuration_a6f44a39 NVARCHAR(MAX),
@Status_a6f44a39 NVARCHAR(25),
@IsCustom_a6f44a39 BIT,
@MetadataSource_a6f44a39 NVARCHAR(20)
SET
  @ID_a6f44a39 = '240636A2-ED77-5127-B734-3F1CF44A4EF2'
SET
  @IntegrationObjectID_a6f44a39 = 'C4A09B88-C6CC-54DF-8D50-0782A34D0907'
SET
  @Name_a6f44a39 = N'display-index'
SET
  @DisplayName_a6f44a39 = N'Display Index'
SET
  @Description_a6f44a39 = N'Display order the researcher chose for the item.'
SET
  @Type_a6f44a39 = N'String'
SET
  @AllowsNull_a6f44a39 = 1
SET
  @IsPrimaryKey_a6f44a39 = 0
SET
  @IsUniqueKey_a6f44a39 = 0
SET
  @IsReadOnly_a6f44a39 = 1
SET
  @IsRequired_a6f44a39 = 0
SET
  @Sequence_a6f44a39 = 4
SET
  @Status_a6f44a39 = N'Active'
SET
  @IsCustom_a6f44a39 = 0
SET
  @MetadataSource_a6f44a39 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_a6f44a39,
  @IntegrationObjectID = @IntegrationObjectID_a6f44a39,
  @Name = @Name_a6f44a39,
  @DisplayName = @DisplayName_a6f44a39,
  @Description = @Description_a6f44a39,
  @Category = @Category_a6f44a39,
  @Category_Clear = 1,
  @Type = @Type_a6f44a39,
  @Length = @Length_a6f44a39,
  @Length_Clear = 1,
  @Precision = @Precision_a6f44a39,
  @Precision_Clear = 1,
  @Scale = @Scale_a6f44a39,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_a6f44a39,
  @DefaultValue = @DefaultValue_a6f44a39,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_a6f44a39,
  @IsUniqueKey = @IsUniqueKey_a6f44a39,
  @IsReadOnly = @IsReadOnly_a6f44a39,
  @IsRequired = @IsRequired_a6f44a39,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_a6f44a39,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_a6f44a39,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_a6f44a39,
  @Configuration = @Configuration_a6f44a39,
  @Configuration_Clear = 1,
  @Status = @Status_a6f44a39,
  @IsCustom = @IsCustom_a6f44a39,
  @MetadataSource = @MetadataSource_a6f44a39;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_c30a557c UNIQUEIDENTIFIER,
@IntegrationObjectID_c30a557c UNIQUEIDENTIFIER,
@Name_c30a557c NVARCHAR(255),
@DisplayName_c30a557c NVARCHAR(255),
@Description_c30a557c NVARCHAR(MAX),
@Category_c30a557c NVARCHAR(100),
@Type_c30a557c NVARCHAR(100),
@Length_c30a557c INT,
@Precision_c30a557c INT,
@Scale_c30a557c INT,
@AllowsNull_c30a557c BIT,
@DefaultValue_c30a557c NVARCHAR(255),
@IsPrimaryKey_c30a557c BIT,
@IsUniqueKey_c30a557c BIT,
@IsReadOnly_c30a557c BIT,
@IsRequired_c30a557c BIT,
@RelatedIntegrationObjectID_c30a557c UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_c30a557c NVARCHAR(255),
@Sequence_c30a557c INT,
@Configuration_c30a557c NVARCHAR(MAX),
@Status_c30a557c NVARCHAR(25),
@IsCustom_c30a557c BIT,
@MetadataSource_c30a557c NVARCHAR(20)
SET
  @ID_c30a557c = '82C2A76F-C3A2-545E-92EA-C24978DF267B'
SET
  @IntegrationObjectID_c30a557c = 'C4A09B88-C6CC-54DF-8D50-0782A34D0907'
SET
  @Name_c30a557c = N'created-date'
SET
  @DisplayName_c30a557c = N'Created Date'
SET
  @Description_c30a557c = N'When ORCID created the item.'
SET
  @Type_c30a557c = N'DateTime'
SET
  @AllowsNull_c30a557c = 1
SET
  @IsPrimaryKey_c30a557c = 0
SET
  @IsUniqueKey_c30a557c = 0
SET
  @IsReadOnly_c30a557c = 1
SET
  @IsRequired_c30a557c = 0
SET
  @Sequence_c30a557c = 5
SET
  @Status_c30a557c = N'Active'
SET
  @IsCustom_c30a557c = 0
SET
  @MetadataSource_c30a557c = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_c30a557c,
  @IntegrationObjectID = @IntegrationObjectID_c30a557c,
  @Name = @Name_c30a557c,
  @DisplayName = @DisplayName_c30a557c,
  @Description = @Description_c30a557c,
  @Category = @Category_c30a557c,
  @Category_Clear = 1,
  @Type = @Type_c30a557c,
  @Length = @Length_c30a557c,
  @Length_Clear = 1,
  @Precision = @Precision_c30a557c,
  @Precision_Clear = 1,
  @Scale = @Scale_c30a557c,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_c30a557c,
  @DefaultValue = @DefaultValue_c30a557c,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_c30a557c,
  @IsUniqueKey = @IsUniqueKey_c30a557c,
  @IsReadOnly = @IsReadOnly_c30a557c,
  @IsRequired = @IsRequired_c30a557c,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_c30a557c,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_c30a557c,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_c30a557c,
  @Configuration = @Configuration_c30a557c,
  @Configuration_Clear = 1,
  @Status = @Status_c30a557c,
  @IsCustom = @IsCustom_c30a557c,
  @MetadataSource = @MetadataSource_c30a557c;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_65fec8f8 UNIQUEIDENTIFIER,
@IntegrationObjectID_65fec8f8 UNIQUEIDENTIFIER,
@Name_65fec8f8 NVARCHAR(255),
@DisplayName_65fec8f8 NVARCHAR(255),
@Description_65fec8f8 NVARCHAR(MAX),
@Category_65fec8f8 NVARCHAR(100),
@Type_65fec8f8 NVARCHAR(100),
@Length_65fec8f8 INT,
@Precision_65fec8f8 INT,
@Scale_65fec8f8 INT,
@AllowsNull_65fec8f8 BIT,
@DefaultValue_65fec8f8 NVARCHAR(255),
@IsPrimaryKey_65fec8f8 BIT,
@IsUniqueKey_65fec8f8 BIT,
@IsReadOnly_65fec8f8 BIT,
@IsRequired_65fec8f8 BIT,
@RelatedIntegrationObjectID_65fec8f8 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_65fec8f8 NVARCHAR(255),
@Sequence_65fec8f8 INT,
@Configuration_65fec8f8 NVARCHAR(MAX),
@Status_65fec8f8 NVARCHAR(25),
@IsCustom_65fec8f8 BIT,
@MetadataSource_65fec8f8 NVARCHAR(20)
SET
  @ID_65fec8f8 = 'C4B30432-522F-5927-ACA5-3C3D709BE166'
SET
  @IntegrationObjectID_65fec8f8 = 'C4A09B88-C6CC-54DF-8D50-0782A34D0907'
SET
  @Name_65fec8f8 = N'last-modified-date'
SET
  @DisplayName_65fec8f8 = N'Last Modified Date'
SET
  @Description_65fec8f8 = N'When ORCID last changed the item. Incremental watermark.'
SET
  @Type_65fec8f8 = N'DateTime'
SET
  @AllowsNull_65fec8f8 = 1
SET
  @IsPrimaryKey_65fec8f8 = 0
SET
  @IsUniqueKey_65fec8f8 = 0
SET
  @IsReadOnly_65fec8f8 = 1
SET
  @IsRequired_65fec8f8 = 0
SET
  @Sequence_65fec8f8 = 6
SET
  @Status_65fec8f8 = N'Active'
SET
  @IsCustom_65fec8f8 = 0
SET
  @MetadataSource_65fec8f8 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_65fec8f8,
  @IntegrationObjectID = @IntegrationObjectID_65fec8f8,
  @Name = @Name_65fec8f8,
  @DisplayName = @DisplayName_65fec8f8,
  @Description = @Description_65fec8f8,
  @Category = @Category_65fec8f8,
  @Category_Clear = 1,
  @Type = @Type_65fec8f8,
  @Length = @Length_65fec8f8,
  @Length_Clear = 1,
  @Precision = @Precision_65fec8f8,
  @Precision_Clear = 1,
  @Scale = @Scale_65fec8f8,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_65fec8f8,
  @DefaultValue = @DefaultValue_65fec8f8,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_65fec8f8,
  @IsUniqueKey = @IsUniqueKey_65fec8f8,
  @IsReadOnly = @IsReadOnly_65fec8f8,
  @IsRequired = @IsRequired_65fec8f8,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_65fec8f8,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_65fec8f8,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_65fec8f8,
  @Configuration = @Configuration_65fec8f8,
  @Configuration_Clear = 1,
  @Status = @Status_65fec8f8,
  @IsCustom = @IsCustom_65fec8f8,
  @MetadataSource = @MetadataSource_65fec8f8;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_f8e09f2d UNIQUEIDENTIFIER,
@IntegrationObjectID_f8e09f2d UNIQUEIDENTIFIER,
@Name_f8e09f2d NVARCHAR(255),
@DisplayName_f8e09f2d NVARCHAR(255),
@Description_f8e09f2d NVARCHAR(MAX),
@Category_f8e09f2d NVARCHAR(100),
@Type_f8e09f2d NVARCHAR(100),
@Length_f8e09f2d INT,
@Precision_f8e09f2d INT,
@Scale_f8e09f2d INT,
@AllowsNull_f8e09f2d BIT,
@DefaultValue_f8e09f2d NVARCHAR(255),
@IsPrimaryKey_f8e09f2d BIT,
@IsUniqueKey_f8e09f2d BIT,
@IsReadOnly_f8e09f2d BIT,
@IsRequired_f8e09f2d BIT,
@RelatedIntegrationObjectID_f8e09f2d UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_f8e09f2d NVARCHAR(255),
@Sequence_f8e09f2d INT,
@Configuration_f8e09f2d NVARCHAR(MAX),
@Status_f8e09f2d NVARCHAR(25),
@IsCustom_f8e09f2d BIT,
@MetadataSource_f8e09f2d NVARCHAR(20)
SET
  @ID_f8e09f2d = 'F9480FE9-ED74-5481-91B8-BD209C65ACFF'
SET
  @IntegrationObjectID_f8e09f2d = 'C4A09B88-C6CC-54DF-8D50-0782A34D0907'
SET
  @Name_f8e09f2d = N'source'
SET
  @DisplayName_f8e09f2d = N'Source'
SET
  @Description_f8e09f2d = N'Full source block: who asserted the item.'
SET
  @Type_f8e09f2d = N'json'
SET
  @AllowsNull_f8e09f2d = 1
SET
  @IsPrimaryKey_f8e09f2d = 0
SET
  @IsUniqueKey_f8e09f2d = 0
SET
  @IsReadOnly_f8e09f2d = 1
SET
  @IsRequired_f8e09f2d = 0
SET
  @Sequence_f8e09f2d = 7
SET
  @Status_f8e09f2d = N'Active'
SET
  @IsCustom_f8e09f2d = 0
SET
  @MetadataSource_f8e09f2d = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_f8e09f2d,
  @IntegrationObjectID = @IntegrationObjectID_f8e09f2d,
  @Name = @Name_f8e09f2d,
  @DisplayName = @DisplayName_f8e09f2d,
  @Description = @Description_f8e09f2d,
  @Category = @Category_f8e09f2d,
  @Category_Clear = 1,
  @Type = @Type_f8e09f2d,
  @Length = @Length_f8e09f2d,
  @Length_Clear = 1,
  @Precision = @Precision_f8e09f2d,
  @Precision_Clear = 1,
  @Scale = @Scale_f8e09f2d,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_f8e09f2d,
  @DefaultValue = @DefaultValue_f8e09f2d,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_f8e09f2d,
  @IsUniqueKey = @IsUniqueKey_f8e09f2d,
  @IsReadOnly = @IsReadOnly_f8e09f2d,
  @IsRequired = @IsRequired_f8e09f2d,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_f8e09f2d,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_f8e09f2d,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_f8e09f2d,
  @Configuration = @Configuration_f8e09f2d,
  @Configuration_Clear = 1,
  @Status = @Status_f8e09f2d,
  @IsCustom = @IsCustom_f8e09f2d,
  @MetadataSource = @MetadataSource_f8e09f2d;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_e3c8f91f UNIQUEIDENTIFIER,
@IntegrationObjectID_e3c8f91f UNIQUEIDENTIFIER,
@Name_e3c8f91f NVARCHAR(255),
@DisplayName_e3c8f91f NVARCHAR(255),
@Description_e3c8f91f NVARCHAR(MAX),
@Category_e3c8f91f NVARCHAR(100),
@Type_e3c8f91f NVARCHAR(100),
@Length_e3c8f91f INT,
@Precision_e3c8f91f INT,
@Scale_e3c8f91f INT,
@AllowsNull_e3c8f91f BIT,
@DefaultValue_e3c8f91f NVARCHAR(255),
@IsPrimaryKey_e3c8f91f BIT,
@IsUniqueKey_e3c8f91f BIT,
@IsReadOnly_e3c8f91f BIT,
@IsRequired_e3c8f91f BIT,
@RelatedIntegrationObjectID_e3c8f91f UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_e3c8f91f NVARCHAR(255),
@Sequence_e3c8f91f INT,
@Configuration_e3c8f91f NVARCHAR(MAX),
@Status_e3c8f91f NVARCHAR(25),
@IsCustom_e3c8f91f BIT,
@MetadataSource_e3c8f91f NVARCHAR(20)
SET
  @ID_e3c8f91f = '6750F3AC-228F-55E6-A936-C2EDD1995B5D'
SET
  @IntegrationObjectID_e3c8f91f = 'C4A09B88-C6CC-54DF-8D50-0782A34D0907'
SET
  @Name_e3c8f91f = N'source-name'
SET
  @DisplayName_e3c8f91f = N'Source Name'
SET
  @Description_e3c8f91f = N'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.'
SET
  @Type_e3c8f91f = N'String'
SET
  @Length_e3c8f91f = 500
SET
  @AllowsNull_e3c8f91f = 1
SET
  @IsPrimaryKey_e3c8f91f = 0
SET
  @IsUniqueKey_e3c8f91f = 0
SET
  @IsReadOnly_e3c8f91f = 1
SET
  @IsRequired_e3c8f91f = 0
SET
  @Sequence_e3c8f91f = 8
SET
  @Status_e3c8f91f = N'Active'
SET
  @IsCustom_e3c8f91f = 0
SET
  @MetadataSource_e3c8f91f = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_e3c8f91f,
  @IntegrationObjectID = @IntegrationObjectID_e3c8f91f,
  @Name = @Name_e3c8f91f,
  @DisplayName = @DisplayName_e3c8f91f,
  @Description = @Description_e3c8f91f,
  @Category = @Category_e3c8f91f,
  @Category_Clear = 1,
  @Type = @Type_e3c8f91f,
  @Length = @Length_e3c8f91f,
  @Precision = @Precision_e3c8f91f,
  @Precision_Clear = 1,
  @Scale = @Scale_e3c8f91f,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_e3c8f91f,
  @DefaultValue = @DefaultValue_e3c8f91f,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_e3c8f91f,
  @IsUniqueKey = @IsUniqueKey_e3c8f91f,
  @IsReadOnly = @IsReadOnly_e3c8f91f,
  @IsRequired = @IsRequired_e3c8f91f,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_e3c8f91f,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_e3c8f91f,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_e3c8f91f,
  @Configuration = @Configuration_e3c8f91f,
  @Configuration_Clear = 1,
  @Status = @Status_e3c8f91f,
  @IsCustom = @IsCustom_e3c8f91f,
  @MetadataSource = @MetadataSource_e3c8f91f;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_2a374d61 UNIQUEIDENTIFIER,
@IntegrationObjectID_2a374d61 UNIQUEIDENTIFIER,
@Name_2a374d61 NVARCHAR(255),
@DisplayName_2a374d61 NVARCHAR(255),
@Description_2a374d61 NVARCHAR(MAX),
@Category_2a374d61 NVARCHAR(100),
@Type_2a374d61 NVARCHAR(100),
@Length_2a374d61 INT,
@Precision_2a374d61 INT,
@Scale_2a374d61 INT,
@AllowsNull_2a374d61 BIT,
@DefaultValue_2a374d61 NVARCHAR(255),
@IsPrimaryKey_2a374d61 BIT,
@IsUniqueKey_2a374d61 BIT,
@IsReadOnly_2a374d61 BIT,
@IsRequired_2a374d61 BIT,
@RelatedIntegrationObjectID_2a374d61 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_2a374d61 NVARCHAR(255),
@Sequence_2a374d61 INT,
@Configuration_2a374d61 NVARCHAR(MAX),
@Status_2a374d61 NVARCHAR(25),
@IsCustom_2a374d61 BIT,
@MetadataSource_2a374d61 NVARCHAR(20)
SET
  @ID_2a374d61 = '1638BE8C-91A4-5C4C-98C2-64388509C0A9'
SET
  @IntegrationObjectID_2a374d61 = 'C4A09B88-C6CC-54DF-8D50-0782A34D0907'
SET
  @Name_2a374d61 = N'source-orcid'
SET
  @DisplayName_2a374d61 = N'Source Orcid'
SET
  @Description_2a374d61 = N'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.'
SET
  @Type_2a374d61 = N'String'
SET
  @Length_2a374d61 = 19
SET
  @AllowsNull_2a374d61 = 1
SET
  @IsPrimaryKey_2a374d61 = 0
SET
  @IsUniqueKey_2a374d61 = 0
SET
  @IsReadOnly_2a374d61 = 1
SET
  @IsRequired_2a374d61 = 0
SET
  @Sequence_2a374d61 = 9
SET
  @Status_2a374d61 = N'Active'
SET
  @IsCustom_2a374d61 = 0
SET
  @MetadataSource_2a374d61 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_2a374d61,
  @IntegrationObjectID = @IntegrationObjectID_2a374d61,
  @Name = @Name_2a374d61,
  @DisplayName = @DisplayName_2a374d61,
  @Description = @Description_2a374d61,
  @Category = @Category_2a374d61,
  @Category_Clear = 1,
  @Type = @Type_2a374d61,
  @Length = @Length_2a374d61,
  @Precision = @Precision_2a374d61,
  @Precision_Clear = 1,
  @Scale = @Scale_2a374d61,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_2a374d61,
  @DefaultValue = @DefaultValue_2a374d61,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_2a374d61,
  @IsUniqueKey = @IsUniqueKey_2a374d61,
  @IsReadOnly = @IsReadOnly_2a374d61,
  @IsRequired = @IsRequired_2a374d61,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_2a374d61,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_2a374d61,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_2a374d61,
  @Configuration = @Configuration_2a374d61,
  @Configuration_Clear = 1,
  @Status = @Status_2a374d61,
  @IsCustom = @IsCustom_2a374d61,
  @MetadataSource = @MetadataSource_2a374d61;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_59f302cf UNIQUEIDENTIFIER,
@IntegrationObjectID_59f302cf UNIQUEIDENTIFIER,
@Name_59f302cf NVARCHAR(255),
@DisplayName_59f302cf NVARCHAR(255),
@Description_59f302cf NVARCHAR(MAX),
@Category_59f302cf NVARCHAR(100),
@Type_59f302cf NVARCHAR(100),
@Length_59f302cf INT,
@Precision_59f302cf INT,
@Scale_59f302cf INT,
@AllowsNull_59f302cf BIT,
@DefaultValue_59f302cf NVARCHAR(255),
@IsPrimaryKey_59f302cf BIT,
@IsUniqueKey_59f302cf BIT,
@IsReadOnly_59f302cf BIT,
@IsRequired_59f302cf BIT,
@RelatedIntegrationObjectID_59f302cf UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_59f302cf NVARCHAR(255),
@Sequence_59f302cf INT,
@Configuration_59f302cf NVARCHAR(MAX),
@Status_59f302cf NVARCHAR(25),
@IsCustom_59f302cf BIT,
@MetadataSource_59f302cf NVARCHAR(20)
SET
  @ID_59f302cf = '37B280EC-2E2C-5B5E-956E-5BBD0F3D6939'
SET
  @IntegrationObjectID_59f302cf = 'C4A09B88-C6CC-54DF-8D50-0782A34D0907'
SET
  @Name_59f302cf = N'country'
SET
  @DisplayName_59f302cf = N'Country'
SET
  @Description_59f302cf = N'ISO country code.'
SET
  @Type_59f302cf = N'String'
SET
  @Length_59f302cf = 50
SET
  @AllowsNull_59f302cf = 1
SET
  @IsPrimaryKey_59f302cf = 0
SET
  @IsUniqueKey_59f302cf = 0
SET
  @IsReadOnly_59f302cf = 1
SET
  @IsRequired_59f302cf = 0
SET
  @Sequence_59f302cf = 10
SET
  @Status_59f302cf = N'Active'
SET
  @IsCustom_59f302cf = 0
SET
  @MetadataSource_59f302cf = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_59f302cf,
  @IntegrationObjectID = @IntegrationObjectID_59f302cf,
  @Name = @Name_59f302cf,
  @DisplayName = @DisplayName_59f302cf,
  @Description = @Description_59f302cf,
  @Category = @Category_59f302cf,
  @Category_Clear = 1,
  @Type = @Type_59f302cf,
  @Length = @Length_59f302cf,
  @Precision = @Precision_59f302cf,
  @Precision_Clear = 1,
  @Scale = @Scale_59f302cf,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_59f302cf,
  @DefaultValue = @DefaultValue_59f302cf,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_59f302cf,
  @IsUniqueKey = @IsUniqueKey_59f302cf,
  @IsReadOnly = @IsReadOnly_59f302cf,
  @IsRequired = @IsRequired_59f302cf,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_59f302cf,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_59f302cf,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_59f302cf,
  @Configuration = @Configuration_59f302cf,
  @Configuration_Clear = 1,
  @Status = @Status_59f302cf,
  @IsCustom = @IsCustom_59f302cf,
  @MetadataSource = @MetadataSource_59f302cf;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_f54ad43a UNIQUEIDENTIFIER,
@IntegrationObjectID_f54ad43a UNIQUEIDENTIFIER,
@Name_f54ad43a NVARCHAR(255),
@DisplayName_f54ad43a NVARCHAR(255),
@Description_f54ad43a NVARCHAR(MAX),
@Category_f54ad43a NVARCHAR(100),
@Type_f54ad43a NVARCHAR(100),
@Length_f54ad43a INT,
@Precision_f54ad43a INT,
@Scale_f54ad43a INT,
@AllowsNull_f54ad43a BIT,
@DefaultValue_f54ad43a NVARCHAR(255),
@IsPrimaryKey_f54ad43a BIT,
@IsUniqueKey_f54ad43a BIT,
@IsReadOnly_f54ad43a BIT,
@IsRequired_f54ad43a BIT,
@RelatedIntegrationObjectID_f54ad43a UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_f54ad43a NVARCHAR(255),
@Sequence_f54ad43a INT,
@Configuration_f54ad43a NVARCHAR(MAX),
@Status_f54ad43a NVARCHAR(25),
@IsCustom_f54ad43a BIT,
@MetadataSource_f54ad43a NVARCHAR(20)
SET
  @ID_f54ad43a = '8C8D7124-AAEC-517F-931B-7854B4B7F3F6'
SET
  @IntegrationObjectID_f54ad43a = '3F2D9F80-F35B-501D-BC52-66AF079946E5'
SET
  @Name_f54ad43a = N'orcid-id'
SET
  @DisplayName_f54ad43a = N'Orcid Id'
SET
  @Description_f54ad43a = N'The ORCID iD of the researcher this item belongs to. Foreign key to the record object.'
SET
  @Type_f54ad43a = N'String'
SET
  @Length_f54ad43a = 19
SET
  @AllowsNull_f54ad43a = 1
SET
  @IsPrimaryKey_f54ad43a = 0
SET
  @IsUniqueKey_f54ad43a = 0
SET
  @IsReadOnly_f54ad43a = 1
SET
  @IsRequired_f54ad43a = 1
SET
  @RelatedIntegrationObjectID_f54ad43a = '73AED6B8-468D-403B-B994-F3C786C98BC0'
SET
  @RelatedIntegrationObjectFieldName_f54ad43a = N'orcid-id'
SET
  @Sequence_f54ad43a = 0
SET
  @Status_f54ad43a = N'Active'
SET
  @IsCustom_f54ad43a = 0
SET
  @MetadataSource_f54ad43a = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_f54ad43a,
  @IntegrationObjectID = @IntegrationObjectID_f54ad43a,
  @Name = @Name_f54ad43a,
  @DisplayName = @DisplayName_f54ad43a,
  @Description = @Description_f54ad43a,
  @Category = @Category_f54ad43a,
  @Category_Clear = 1,
  @Type = @Type_f54ad43a,
  @Length = @Length_f54ad43a,
  @Precision = @Precision_f54ad43a,
  @Precision_Clear = 1,
  @Scale = @Scale_f54ad43a,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_f54ad43a,
  @DefaultValue = @DefaultValue_f54ad43a,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_f54ad43a,
  @IsUniqueKey = @IsUniqueKey_f54ad43a,
  @IsReadOnly = @IsReadOnly_f54ad43a,
  @IsRequired = @IsRequired_f54ad43a,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_f54ad43a,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_f54ad43a,
  @Sequence = @Sequence_f54ad43a,
  @Configuration = @Configuration_f54ad43a,
  @Configuration_Clear = 1,
  @Status = @Status_f54ad43a,
  @IsCustom = @IsCustom_f54ad43a,
  @MetadataSource = @MetadataSource_f54ad43a;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_58ac27cb UNIQUEIDENTIFIER,
@IntegrationObjectID_58ac27cb UNIQUEIDENTIFIER,
@Name_58ac27cb NVARCHAR(255),
@DisplayName_58ac27cb NVARCHAR(255),
@Description_58ac27cb NVARCHAR(MAX),
@Category_58ac27cb NVARCHAR(100),
@Type_58ac27cb NVARCHAR(100),
@Length_58ac27cb INT,
@Precision_58ac27cb INT,
@Scale_58ac27cb INT,
@AllowsNull_58ac27cb BIT,
@DefaultValue_58ac27cb NVARCHAR(255),
@IsPrimaryKey_58ac27cb BIT,
@IsUniqueKey_58ac27cb BIT,
@IsReadOnly_58ac27cb BIT,
@IsRequired_58ac27cb BIT,
@RelatedIntegrationObjectID_58ac27cb UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_58ac27cb NVARCHAR(255),
@Sequence_58ac27cb INT,
@Configuration_58ac27cb NVARCHAR(MAX),
@Status_58ac27cb NVARCHAR(25),
@IsCustom_58ac27cb BIT,
@MetadataSource_58ac27cb NVARCHAR(20)
SET
  @ID_58ac27cb = 'F61EB884-52A0-5AE5-A8CC-1F5F5106FA77'
SET
  @IntegrationObjectID_58ac27cb = '3F2D9F80-F35B-501D-BC52-66AF079946E5'
SET
  @Name_58ac27cb = N'put-code'
SET
  @DisplayName_58ac27cb = N'Put Code'
SET
  @Description_58ac27cb = N'ORCID''s stable identifier for this item within the record. Primary key.'
SET
  @Type_58ac27cb = N'Integer'
SET
  @AllowsNull_58ac27cb = 0
SET
  @IsPrimaryKey_58ac27cb = 1
SET
  @IsUniqueKey_58ac27cb = 1
SET
  @IsReadOnly_58ac27cb = 1
SET
  @IsRequired_58ac27cb = 1
SET
  @Sequence_58ac27cb = 1
SET
  @Status_58ac27cb = N'Active'
SET
  @IsCustom_58ac27cb = 0
SET
  @MetadataSource_58ac27cb = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_58ac27cb,
  @IntegrationObjectID = @IntegrationObjectID_58ac27cb,
  @Name = @Name_58ac27cb,
  @DisplayName = @DisplayName_58ac27cb,
  @Description = @Description_58ac27cb,
  @Category = @Category_58ac27cb,
  @Category_Clear = 1,
  @Type = @Type_58ac27cb,
  @Length = @Length_58ac27cb,
  @Length_Clear = 1,
  @Precision = @Precision_58ac27cb,
  @Precision_Clear = 1,
  @Scale = @Scale_58ac27cb,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_58ac27cb,
  @DefaultValue = @DefaultValue_58ac27cb,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_58ac27cb,
  @IsUniqueKey = @IsUniqueKey_58ac27cb,
  @IsReadOnly = @IsReadOnly_58ac27cb,
  @IsRequired = @IsRequired_58ac27cb,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_58ac27cb,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_58ac27cb,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_58ac27cb,
  @Configuration = @Configuration_58ac27cb,
  @Configuration_Clear = 1,
  @Status = @Status_58ac27cb,
  @IsCustom = @IsCustom_58ac27cb,
  @MetadataSource = @MetadataSource_58ac27cb;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_b2218280 UNIQUEIDENTIFIER,
@IntegrationObjectID_b2218280 UNIQUEIDENTIFIER,
@Name_b2218280 NVARCHAR(255),
@DisplayName_b2218280 NVARCHAR(255),
@Description_b2218280 NVARCHAR(MAX),
@Category_b2218280 NVARCHAR(100),
@Type_b2218280 NVARCHAR(100),
@Length_b2218280 INT,
@Precision_b2218280 INT,
@Scale_b2218280 INT,
@AllowsNull_b2218280 BIT,
@DefaultValue_b2218280 NVARCHAR(255),
@IsPrimaryKey_b2218280 BIT,
@IsUniqueKey_b2218280 BIT,
@IsReadOnly_b2218280 BIT,
@IsRequired_b2218280 BIT,
@RelatedIntegrationObjectID_b2218280 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_b2218280 NVARCHAR(255),
@Sequence_b2218280 INT,
@Configuration_b2218280 NVARCHAR(MAX),
@Status_b2218280 NVARCHAR(25),
@IsCustom_b2218280 BIT,
@MetadataSource_b2218280 NVARCHAR(20)
SET
  @ID_b2218280 = '075259DF-EC48-5A99-AAB2-D3B9C71BC775'
SET
  @IntegrationObjectID_b2218280 = '3F2D9F80-F35B-501D-BC52-66AF079946E5'
SET
  @Name_b2218280 = N'path'
SET
  @DisplayName_b2218280 = N'Path'
SET
  @Description_b2218280 = N'Element path /{orcid}/{section}/{put-code}.'
SET
  @Type_b2218280 = N'String'
SET
  @Length_b2218280 = 500
SET
  @AllowsNull_b2218280 = 1
SET
  @IsPrimaryKey_b2218280 = 0
SET
  @IsUniqueKey_b2218280 = 0
SET
  @IsReadOnly_b2218280 = 1
SET
  @IsRequired_b2218280 = 0
SET
  @Sequence_b2218280 = 2
SET
  @Status_b2218280 = N'Active'
SET
  @IsCustom_b2218280 = 0
SET
  @MetadataSource_b2218280 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_b2218280,
  @IntegrationObjectID = @IntegrationObjectID_b2218280,
  @Name = @Name_b2218280,
  @DisplayName = @DisplayName_b2218280,
  @Description = @Description_b2218280,
  @Category = @Category_b2218280,
  @Category_Clear = 1,
  @Type = @Type_b2218280,
  @Length = @Length_b2218280,
  @Precision = @Precision_b2218280,
  @Precision_Clear = 1,
  @Scale = @Scale_b2218280,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_b2218280,
  @DefaultValue = @DefaultValue_b2218280,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_b2218280,
  @IsUniqueKey = @IsUniqueKey_b2218280,
  @IsReadOnly = @IsReadOnly_b2218280,
  @IsRequired = @IsRequired_b2218280,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_b2218280,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_b2218280,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_b2218280,
  @Configuration = @Configuration_b2218280,
  @Configuration_Clear = 1,
  @Status = @Status_b2218280,
  @IsCustom = @IsCustom_b2218280,
  @MetadataSource = @MetadataSource_b2218280;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_854e28f1 UNIQUEIDENTIFIER,
@IntegrationObjectID_854e28f1 UNIQUEIDENTIFIER,
@Name_854e28f1 NVARCHAR(255),
@DisplayName_854e28f1 NVARCHAR(255),
@Description_854e28f1 NVARCHAR(MAX),
@Category_854e28f1 NVARCHAR(100),
@Type_854e28f1 NVARCHAR(100),
@Length_854e28f1 INT,
@Precision_854e28f1 INT,
@Scale_854e28f1 INT,
@AllowsNull_854e28f1 BIT,
@DefaultValue_854e28f1 NVARCHAR(255),
@IsPrimaryKey_854e28f1 BIT,
@IsUniqueKey_854e28f1 BIT,
@IsReadOnly_854e28f1 BIT,
@IsRequired_854e28f1 BIT,
@RelatedIntegrationObjectID_854e28f1 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_854e28f1 NVARCHAR(255),
@Sequence_854e28f1 INT,
@Configuration_854e28f1 NVARCHAR(MAX),
@Status_854e28f1 NVARCHAR(25),
@IsCustom_854e28f1 BIT,
@MetadataSource_854e28f1 NVARCHAR(20)
SET
  @ID_854e28f1 = '396BE273-F78E-5899-A4FF-EFE7163D6DED'
SET
  @IntegrationObjectID_854e28f1 = '3F2D9F80-F35B-501D-BC52-66AF079946E5'
SET
  @Name_854e28f1 = N'visibility'
SET
  @DisplayName_854e28f1 = N'Visibility'
SET
  @Description_854e28f1 = N'ORCID visibility of the item (public, limited, private). The Public API only serves public.'
SET
  @Type_854e28f1 = N'String'
SET
  @AllowsNull_854e28f1 = 1
SET
  @IsPrimaryKey_854e28f1 = 0
SET
  @IsUniqueKey_854e28f1 = 0
SET
  @IsReadOnly_854e28f1 = 1
SET
  @IsRequired_854e28f1 = 0
SET
  @Sequence_854e28f1 = 3
SET
  @Status_854e28f1 = N'Active'
SET
  @IsCustom_854e28f1 = 0
SET
  @MetadataSource_854e28f1 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_854e28f1,
  @IntegrationObjectID = @IntegrationObjectID_854e28f1,
  @Name = @Name_854e28f1,
  @DisplayName = @DisplayName_854e28f1,
  @Description = @Description_854e28f1,
  @Category = @Category_854e28f1,
  @Category_Clear = 1,
  @Type = @Type_854e28f1,
  @Length = @Length_854e28f1,
  @Length_Clear = 1,
  @Precision = @Precision_854e28f1,
  @Precision_Clear = 1,
  @Scale = @Scale_854e28f1,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_854e28f1,
  @DefaultValue = @DefaultValue_854e28f1,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_854e28f1,
  @IsUniqueKey = @IsUniqueKey_854e28f1,
  @IsReadOnly = @IsReadOnly_854e28f1,
  @IsRequired = @IsRequired_854e28f1,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_854e28f1,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_854e28f1,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_854e28f1,
  @Configuration = @Configuration_854e28f1,
  @Configuration_Clear = 1,
  @Status = @Status_854e28f1,
  @IsCustom = @IsCustom_854e28f1,
  @MetadataSource = @MetadataSource_854e28f1;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_4d5985f6 UNIQUEIDENTIFIER,
@IntegrationObjectID_4d5985f6 UNIQUEIDENTIFIER,
@Name_4d5985f6 NVARCHAR(255),
@DisplayName_4d5985f6 NVARCHAR(255),
@Description_4d5985f6 NVARCHAR(MAX),
@Category_4d5985f6 NVARCHAR(100),
@Type_4d5985f6 NVARCHAR(100),
@Length_4d5985f6 INT,
@Precision_4d5985f6 INT,
@Scale_4d5985f6 INT,
@AllowsNull_4d5985f6 BIT,
@DefaultValue_4d5985f6 NVARCHAR(255),
@IsPrimaryKey_4d5985f6 BIT,
@IsUniqueKey_4d5985f6 BIT,
@IsReadOnly_4d5985f6 BIT,
@IsRequired_4d5985f6 BIT,
@RelatedIntegrationObjectID_4d5985f6 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_4d5985f6 NVARCHAR(255),
@Sequence_4d5985f6 INT,
@Configuration_4d5985f6 NVARCHAR(MAX),
@Status_4d5985f6 NVARCHAR(25),
@IsCustom_4d5985f6 BIT,
@MetadataSource_4d5985f6 NVARCHAR(20)
SET
  @ID_4d5985f6 = '4E4CA86C-011D-5C91-8577-5B7AE4A4B1FC'
SET
  @IntegrationObjectID_4d5985f6 = '3F2D9F80-F35B-501D-BC52-66AF079946E5'
SET
  @Name_4d5985f6 = N'display-index'
SET
  @DisplayName_4d5985f6 = N'Display Index'
SET
  @Description_4d5985f6 = N'Display order the researcher chose for the item.'
SET
  @Type_4d5985f6 = N'String'
SET
  @AllowsNull_4d5985f6 = 1
SET
  @IsPrimaryKey_4d5985f6 = 0
SET
  @IsUniqueKey_4d5985f6 = 0
SET
  @IsReadOnly_4d5985f6 = 1
SET
  @IsRequired_4d5985f6 = 0
SET
  @Sequence_4d5985f6 = 4
SET
  @Status_4d5985f6 = N'Active'
SET
  @IsCustom_4d5985f6 = 0
SET
  @MetadataSource_4d5985f6 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_4d5985f6,
  @IntegrationObjectID = @IntegrationObjectID_4d5985f6,
  @Name = @Name_4d5985f6,
  @DisplayName = @DisplayName_4d5985f6,
  @Description = @Description_4d5985f6,
  @Category = @Category_4d5985f6,
  @Category_Clear = 1,
  @Type = @Type_4d5985f6,
  @Length = @Length_4d5985f6,
  @Length_Clear = 1,
  @Precision = @Precision_4d5985f6,
  @Precision_Clear = 1,
  @Scale = @Scale_4d5985f6,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_4d5985f6,
  @DefaultValue = @DefaultValue_4d5985f6,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_4d5985f6,
  @IsUniqueKey = @IsUniqueKey_4d5985f6,
  @IsReadOnly = @IsReadOnly_4d5985f6,
  @IsRequired = @IsRequired_4d5985f6,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_4d5985f6,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_4d5985f6,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_4d5985f6,
  @Configuration = @Configuration_4d5985f6,
  @Configuration_Clear = 1,
  @Status = @Status_4d5985f6,
  @IsCustom = @IsCustom_4d5985f6,
  @MetadataSource = @MetadataSource_4d5985f6;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_0d14d249 UNIQUEIDENTIFIER,
@IntegrationObjectID_0d14d249 UNIQUEIDENTIFIER,
@Name_0d14d249 NVARCHAR(255),
@DisplayName_0d14d249 NVARCHAR(255),
@Description_0d14d249 NVARCHAR(MAX),
@Category_0d14d249 NVARCHAR(100),
@Type_0d14d249 NVARCHAR(100),
@Length_0d14d249 INT,
@Precision_0d14d249 INT,
@Scale_0d14d249 INT,
@AllowsNull_0d14d249 BIT,
@DefaultValue_0d14d249 NVARCHAR(255),
@IsPrimaryKey_0d14d249 BIT,
@IsUniqueKey_0d14d249 BIT,
@IsReadOnly_0d14d249 BIT,
@IsRequired_0d14d249 BIT,
@RelatedIntegrationObjectID_0d14d249 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_0d14d249 NVARCHAR(255),
@Sequence_0d14d249 INT,
@Configuration_0d14d249 NVARCHAR(MAX),
@Status_0d14d249 NVARCHAR(25),
@IsCustom_0d14d249 BIT,
@MetadataSource_0d14d249 NVARCHAR(20)
SET
  @ID_0d14d249 = '07BC821A-02B0-5CD1-B829-8702A8DBEF37'
SET
  @IntegrationObjectID_0d14d249 = '3F2D9F80-F35B-501D-BC52-66AF079946E5'
SET
  @Name_0d14d249 = N'created-date'
SET
  @DisplayName_0d14d249 = N'Created Date'
SET
  @Description_0d14d249 = N'When ORCID created the item.'
SET
  @Type_0d14d249 = N'DateTime'
SET
  @AllowsNull_0d14d249 = 1
SET
  @IsPrimaryKey_0d14d249 = 0
SET
  @IsUniqueKey_0d14d249 = 0
SET
  @IsReadOnly_0d14d249 = 1
SET
  @IsRequired_0d14d249 = 0
SET
  @Sequence_0d14d249 = 5
SET
  @Status_0d14d249 = N'Active'
SET
  @IsCustom_0d14d249 = 0
SET
  @MetadataSource_0d14d249 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_0d14d249,
  @IntegrationObjectID = @IntegrationObjectID_0d14d249,
  @Name = @Name_0d14d249,
  @DisplayName = @DisplayName_0d14d249,
  @Description = @Description_0d14d249,
  @Category = @Category_0d14d249,
  @Category_Clear = 1,
  @Type = @Type_0d14d249,
  @Length = @Length_0d14d249,
  @Length_Clear = 1,
  @Precision = @Precision_0d14d249,
  @Precision_Clear = 1,
  @Scale = @Scale_0d14d249,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_0d14d249,
  @DefaultValue = @DefaultValue_0d14d249,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_0d14d249,
  @IsUniqueKey = @IsUniqueKey_0d14d249,
  @IsReadOnly = @IsReadOnly_0d14d249,
  @IsRequired = @IsRequired_0d14d249,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_0d14d249,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_0d14d249,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_0d14d249,
  @Configuration = @Configuration_0d14d249,
  @Configuration_Clear = 1,
  @Status = @Status_0d14d249,
  @IsCustom = @IsCustom_0d14d249,
  @MetadataSource = @MetadataSource_0d14d249;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_051e9512 UNIQUEIDENTIFIER,
@IntegrationObjectID_051e9512 UNIQUEIDENTIFIER,
@Name_051e9512 NVARCHAR(255),
@DisplayName_051e9512 NVARCHAR(255),
@Description_051e9512 NVARCHAR(MAX),
@Category_051e9512 NVARCHAR(100),
@Type_051e9512 NVARCHAR(100),
@Length_051e9512 INT,
@Precision_051e9512 INT,
@Scale_051e9512 INT,
@AllowsNull_051e9512 BIT,
@DefaultValue_051e9512 NVARCHAR(255),
@IsPrimaryKey_051e9512 BIT,
@IsUniqueKey_051e9512 BIT,
@IsReadOnly_051e9512 BIT,
@IsRequired_051e9512 BIT,
@RelatedIntegrationObjectID_051e9512 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_051e9512 NVARCHAR(255),
@Sequence_051e9512 INT,
@Configuration_051e9512 NVARCHAR(MAX),
@Status_051e9512 NVARCHAR(25),
@IsCustom_051e9512 BIT,
@MetadataSource_051e9512 NVARCHAR(20)
SET
  @ID_051e9512 = '05D31C15-3F6D-5546-B5E3-66B24651F2A6'
SET
  @IntegrationObjectID_051e9512 = '3F2D9F80-F35B-501D-BC52-66AF079946E5'
SET
  @Name_051e9512 = N'last-modified-date'
SET
  @DisplayName_051e9512 = N'Last Modified Date'
SET
  @Description_051e9512 = N'When ORCID last changed the item. Incremental watermark.'
SET
  @Type_051e9512 = N'DateTime'
SET
  @AllowsNull_051e9512 = 1
SET
  @IsPrimaryKey_051e9512 = 0
SET
  @IsUniqueKey_051e9512 = 0
SET
  @IsReadOnly_051e9512 = 1
SET
  @IsRequired_051e9512 = 0
SET
  @Sequence_051e9512 = 6
SET
  @Status_051e9512 = N'Active'
SET
  @IsCustom_051e9512 = 0
SET
  @MetadataSource_051e9512 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_051e9512,
  @IntegrationObjectID = @IntegrationObjectID_051e9512,
  @Name = @Name_051e9512,
  @DisplayName = @DisplayName_051e9512,
  @Description = @Description_051e9512,
  @Category = @Category_051e9512,
  @Category_Clear = 1,
  @Type = @Type_051e9512,
  @Length = @Length_051e9512,
  @Length_Clear = 1,
  @Precision = @Precision_051e9512,
  @Precision_Clear = 1,
  @Scale = @Scale_051e9512,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_051e9512,
  @DefaultValue = @DefaultValue_051e9512,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_051e9512,
  @IsUniqueKey = @IsUniqueKey_051e9512,
  @IsReadOnly = @IsReadOnly_051e9512,
  @IsRequired = @IsRequired_051e9512,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_051e9512,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_051e9512,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_051e9512,
  @Configuration = @Configuration_051e9512,
  @Configuration_Clear = 1,
  @Status = @Status_051e9512,
  @IsCustom = @IsCustom_051e9512,
  @MetadataSource = @MetadataSource_051e9512;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_a95e1c11 UNIQUEIDENTIFIER,
@IntegrationObjectID_a95e1c11 UNIQUEIDENTIFIER,
@Name_a95e1c11 NVARCHAR(255),
@DisplayName_a95e1c11 NVARCHAR(255),
@Description_a95e1c11 NVARCHAR(MAX),
@Category_a95e1c11 NVARCHAR(100),
@Type_a95e1c11 NVARCHAR(100),
@Length_a95e1c11 INT,
@Precision_a95e1c11 INT,
@Scale_a95e1c11 INT,
@AllowsNull_a95e1c11 BIT,
@DefaultValue_a95e1c11 NVARCHAR(255),
@IsPrimaryKey_a95e1c11 BIT,
@IsUniqueKey_a95e1c11 BIT,
@IsReadOnly_a95e1c11 BIT,
@IsRequired_a95e1c11 BIT,
@RelatedIntegrationObjectID_a95e1c11 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_a95e1c11 NVARCHAR(255),
@Sequence_a95e1c11 INT,
@Configuration_a95e1c11 NVARCHAR(MAX),
@Status_a95e1c11 NVARCHAR(25),
@IsCustom_a95e1c11 BIT,
@MetadataSource_a95e1c11 NVARCHAR(20)
SET
  @ID_a95e1c11 = 'EE4F782C-D27E-5F3E-B5E5-E4DDB5C84D62'
SET
  @IntegrationObjectID_a95e1c11 = '3F2D9F80-F35B-501D-BC52-66AF079946E5'
SET
  @Name_a95e1c11 = N'source'
SET
  @DisplayName_a95e1c11 = N'Source'
SET
  @Description_a95e1c11 = N'Full source block: who asserted the item.'
SET
  @Type_a95e1c11 = N'json'
SET
  @AllowsNull_a95e1c11 = 1
SET
  @IsPrimaryKey_a95e1c11 = 0
SET
  @IsUniqueKey_a95e1c11 = 0
SET
  @IsReadOnly_a95e1c11 = 1
SET
  @IsRequired_a95e1c11 = 0
SET
  @Sequence_a95e1c11 = 7
SET
  @Status_a95e1c11 = N'Active'
SET
  @IsCustom_a95e1c11 = 0
SET
  @MetadataSource_a95e1c11 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_a95e1c11,
  @IntegrationObjectID = @IntegrationObjectID_a95e1c11,
  @Name = @Name_a95e1c11,
  @DisplayName = @DisplayName_a95e1c11,
  @Description = @Description_a95e1c11,
  @Category = @Category_a95e1c11,
  @Category_Clear = 1,
  @Type = @Type_a95e1c11,
  @Length = @Length_a95e1c11,
  @Length_Clear = 1,
  @Precision = @Precision_a95e1c11,
  @Precision_Clear = 1,
  @Scale = @Scale_a95e1c11,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_a95e1c11,
  @DefaultValue = @DefaultValue_a95e1c11,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_a95e1c11,
  @IsUniqueKey = @IsUniqueKey_a95e1c11,
  @IsReadOnly = @IsReadOnly_a95e1c11,
  @IsRequired = @IsRequired_a95e1c11,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_a95e1c11,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_a95e1c11,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_a95e1c11,
  @Configuration = @Configuration_a95e1c11,
  @Configuration_Clear = 1,
  @Status = @Status_a95e1c11,
  @IsCustom = @IsCustom_a95e1c11,
  @MetadataSource = @MetadataSource_a95e1c11;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_53ff5a3b UNIQUEIDENTIFIER,
@IntegrationObjectID_53ff5a3b UNIQUEIDENTIFIER,
@Name_53ff5a3b NVARCHAR(255),
@DisplayName_53ff5a3b NVARCHAR(255),
@Description_53ff5a3b NVARCHAR(MAX),
@Category_53ff5a3b NVARCHAR(100),
@Type_53ff5a3b NVARCHAR(100),
@Length_53ff5a3b INT,
@Precision_53ff5a3b INT,
@Scale_53ff5a3b INT,
@AllowsNull_53ff5a3b BIT,
@DefaultValue_53ff5a3b NVARCHAR(255),
@IsPrimaryKey_53ff5a3b BIT,
@IsUniqueKey_53ff5a3b BIT,
@IsReadOnly_53ff5a3b BIT,
@IsRequired_53ff5a3b BIT,
@RelatedIntegrationObjectID_53ff5a3b UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_53ff5a3b NVARCHAR(255),
@Sequence_53ff5a3b INT,
@Configuration_53ff5a3b NVARCHAR(MAX),
@Status_53ff5a3b NVARCHAR(25),
@IsCustom_53ff5a3b BIT,
@MetadataSource_53ff5a3b NVARCHAR(20)
SET
  @ID_53ff5a3b = '3DBF9F49-CF57-5EB4-B7F0-47DF51965970'
SET
  @IntegrationObjectID_53ff5a3b = '3F2D9F80-F35B-501D-BC52-66AF079946E5'
SET
  @Name_53ff5a3b = N'source-name'
SET
  @DisplayName_53ff5a3b = N'Source Name'
SET
  @Description_53ff5a3b = N'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.'
SET
  @Type_53ff5a3b = N'String'
SET
  @Length_53ff5a3b = 500
SET
  @AllowsNull_53ff5a3b = 1
SET
  @IsPrimaryKey_53ff5a3b = 0
SET
  @IsUniqueKey_53ff5a3b = 0
SET
  @IsReadOnly_53ff5a3b = 1
SET
  @IsRequired_53ff5a3b = 0
SET
  @Sequence_53ff5a3b = 8
SET
  @Status_53ff5a3b = N'Active'
SET
  @IsCustom_53ff5a3b = 0
SET
  @MetadataSource_53ff5a3b = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_53ff5a3b,
  @IntegrationObjectID = @IntegrationObjectID_53ff5a3b,
  @Name = @Name_53ff5a3b,
  @DisplayName = @DisplayName_53ff5a3b,
  @Description = @Description_53ff5a3b,
  @Category = @Category_53ff5a3b,
  @Category_Clear = 1,
  @Type = @Type_53ff5a3b,
  @Length = @Length_53ff5a3b,
  @Precision = @Precision_53ff5a3b,
  @Precision_Clear = 1,
  @Scale = @Scale_53ff5a3b,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_53ff5a3b,
  @DefaultValue = @DefaultValue_53ff5a3b,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_53ff5a3b,
  @IsUniqueKey = @IsUniqueKey_53ff5a3b,
  @IsReadOnly = @IsReadOnly_53ff5a3b,
  @IsRequired = @IsRequired_53ff5a3b,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_53ff5a3b,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_53ff5a3b,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_53ff5a3b,
  @Configuration = @Configuration_53ff5a3b,
  @Configuration_Clear = 1,
  @Status = @Status_53ff5a3b,
  @IsCustom = @IsCustom_53ff5a3b,
  @MetadataSource = @MetadataSource_53ff5a3b;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_2f310673 UNIQUEIDENTIFIER,
@IntegrationObjectID_2f310673 UNIQUEIDENTIFIER,
@Name_2f310673 NVARCHAR(255),
@DisplayName_2f310673 NVARCHAR(255),
@Description_2f310673 NVARCHAR(MAX),
@Category_2f310673 NVARCHAR(100),
@Type_2f310673 NVARCHAR(100),
@Length_2f310673 INT,
@Precision_2f310673 INT,
@Scale_2f310673 INT,
@AllowsNull_2f310673 BIT,
@DefaultValue_2f310673 NVARCHAR(255),
@IsPrimaryKey_2f310673 BIT,
@IsUniqueKey_2f310673 BIT,
@IsReadOnly_2f310673 BIT,
@IsRequired_2f310673 BIT,
@RelatedIntegrationObjectID_2f310673 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_2f310673 NVARCHAR(255),
@Sequence_2f310673 INT,
@Configuration_2f310673 NVARCHAR(MAX),
@Status_2f310673 NVARCHAR(25),
@IsCustom_2f310673 BIT,
@MetadataSource_2f310673 NVARCHAR(20)
SET
  @ID_2f310673 = '701D706C-70FA-5BCE-937F-D6849AD39187'
SET
  @IntegrationObjectID_2f310673 = '3F2D9F80-F35B-501D-BC52-66AF079946E5'
SET
  @Name_2f310673 = N'source-orcid'
SET
  @DisplayName_2f310673 = N'Source Orcid'
SET
  @Description_2f310673 = N'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.'
SET
  @Type_2f310673 = N'String'
SET
  @Length_2f310673 = 19
SET
  @AllowsNull_2f310673 = 1
SET
  @IsPrimaryKey_2f310673 = 0
SET
  @IsUniqueKey_2f310673 = 0
SET
  @IsReadOnly_2f310673 = 1
SET
  @IsRequired_2f310673 = 0
SET
  @Sequence_2f310673 = 9
SET
  @Status_2f310673 = N'Active'
SET
  @IsCustom_2f310673 = 0
SET
  @MetadataSource_2f310673 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_2f310673,
  @IntegrationObjectID = @IntegrationObjectID_2f310673,
  @Name = @Name_2f310673,
  @DisplayName = @DisplayName_2f310673,
  @Description = @Description_2f310673,
  @Category = @Category_2f310673,
  @Category_Clear = 1,
  @Type = @Type_2f310673,
  @Length = @Length_2f310673,
  @Precision = @Precision_2f310673,
  @Precision_Clear = 1,
  @Scale = @Scale_2f310673,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_2f310673,
  @DefaultValue = @DefaultValue_2f310673,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_2f310673,
  @IsUniqueKey = @IsUniqueKey_2f310673,
  @IsReadOnly = @IsReadOnly_2f310673,
  @IsRequired = @IsRequired_2f310673,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_2f310673,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_2f310673,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_2f310673,
  @Configuration = @Configuration_2f310673,
  @Configuration_Clear = 1,
  @Status = @Status_2f310673,
  @IsCustom = @IsCustom_2f310673,
  @MetadataSource = @MetadataSource_2f310673;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_b15ea615 UNIQUEIDENTIFIER,
@IntegrationObjectID_b15ea615 UNIQUEIDENTIFIER,
@Name_b15ea615 NVARCHAR(255),
@DisplayName_b15ea615 NVARCHAR(255),
@Description_b15ea615 NVARCHAR(MAX),
@Category_b15ea615 NVARCHAR(100),
@Type_b15ea615 NVARCHAR(100),
@Length_b15ea615 INT,
@Precision_b15ea615 INT,
@Scale_b15ea615 INT,
@AllowsNull_b15ea615 BIT,
@DefaultValue_b15ea615 NVARCHAR(255),
@IsPrimaryKey_b15ea615 BIT,
@IsUniqueKey_b15ea615 BIT,
@IsReadOnly_b15ea615 BIT,
@IsRequired_b15ea615 BIT,
@RelatedIntegrationObjectID_b15ea615 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_b15ea615 NVARCHAR(255),
@Sequence_b15ea615 INT,
@Configuration_b15ea615 NVARCHAR(MAX),
@Status_b15ea615 NVARCHAR(25),
@IsCustom_b15ea615 BIT,
@MetadataSource_b15ea615 NVARCHAR(20)
SET
  @ID_b15ea615 = '325CCA41-3F69-5F14-AC9B-28D6BEBDC6CB'
SET
  @IntegrationObjectID_b15ea615 = '3F2D9F80-F35B-501D-BC52-66AF079946E5'
SET
  @Name_b15ea615 = N'url-name'
SET
  @DisplayName_b15ea615 = N'Url Name'
SET
  @Description_b15ea615 = N'Label of the link (e.g. Lab Website).'
SET
  @Type_b15ea615 = N'String'
SET
  @Length_b15ea615 = 500
SET
  @AllowsNull_b15ea615 = 1
SET
  @IsPrimaryKey_b15ea615 = 0
SET
  @IsUniqueKey_b15ea615 = 0
SET
  @IsReadOnly_b15ea615 = 1
SET
  @IsRequired_b15ea615 = 0
SET
  @Sequence_b15ea615 = 10
SET
  @Status_b15ea615 = N'Active'
SET
  @IsCustom_b15ea615 = 0
SET
  @MetadataSource_b15ea615 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_b15ea615,
  @IntegrationObjectID = @IntegrationObjectID_b15ea615,
  @Name = @Name_b15ea615,
  @DisplayName = @DisplayName_b15ea615,
  @Description = @Description_b15ea615,
  @Category = @Category_b15ea615,
  @Category_Clear = 1,
  @Type = @Type_b15ea615,
  @Length = @Length_b15ea615,
  @Precision = @Precision_b15ea615,
  @Precision_Clear = 1,
  @Scale = @Scale_b15ea615,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_b15ea615,
  @DefaultValue = @DefaultValue_b15ea615,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_b15ea615,
  @IsUniqueKey = @IsUniqueKey_b15ea615,
  @IsReadOnly = @IsReadOnly_b15ea615,
  @IsRequired = @IsRequired_b15ea615,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_b15ea615,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_b15ea615,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_b15ea615,
  @Configuration = @Configuration_b15ea615,
  @Configuration_Clear = 1,
  @Status = @Status_b15ea615,
  @IsCustom = @IsCustom_b15ea615,
  @MetadataSource = @MetadataSource_b15ea615;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_78a345c3 UNIQUEIDENTIFIER,
@IntegrationObjectID_78a345c3 UNIQUEIDENTIFIER,
@Name_78a345c3 NVARCHAR(255),
@DisplayName_78a345c3 NVARCHAR(255),
@Description_78a345c3 NVARCHAR(MAX),
@Category_78a345c3 NVARCHAR(100),
@Type_78a345c3 NVARCHAR(100),
@Length_78a345c3 INT,
@Precision_78a345c3 INT,
@Scale_78a345c3 INT,
@AllowsNull_78a345c3 BIT,
@DefaultValue_78a345c3 NVARCHAR(255),
@IsPrimaryKey_78a345c3 BIT,
@IsUniqueKey_78a345c3 BIT,
@IsReadOnly_78a345c3 BIT,
@IsRequired_78a345c3 BIT,
@RelatedIntegrationObjectID_78a345c3 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_78a345c3 NVARCHAR(255),
@Sequence_78a345c3 INT,
@Configuration_78a345c3 NVARCHAR(MAX),
@Status_78a345c3 NVARCHAR(25),
@IsCustom_78a345c3 BIT,
@MetadataSource_78a345c3 NVARCHAR(20)
SET
  @ID_78a345c3 = '00266154-4906-5F63-813C-F935D4824E8A'
SET
  @IntegrationObjectID_78a345c3 = '3F2D9F80-F35B-501D-BC52-66AF079946E5'
SET
  @Name_78a345c3 = N'url'
SET
  @DisplayName_78a345c3 = N'Url'
SET
  @Description_78a345c3 = N'The URL.'
SET
  @Type_78a345c3 = N'String'
SET
  @Length_78a345c3 = 2048
SET
  @AllowsNull_78a345c3 = 1
SET
  @IsPrimaryKey_78a345c3 = 0
SET
  @IsUniqueKey_78a345c3 = 0
SET
  @IsReadOnly_78a345c3 = 1
SET
  @IsRequired_78a345c3 = 0
SET
  @Sequence_78a345c3 = 11
SET
  @Status_78a345c3 = N'Active'
SET
  @IsCustom_78a345c3 = 0
SET
  @MetadataSource_78a345c3 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_78a345c3,
  @IntegrationObjectID = @IntegrationObjectID_78a345c3,
  @Name = @Name_78a345c3,
  @DisplayName = @DisplayName_78a345c3,
  @Description = @Description_78a345c3,
  @Category = @Category_78a345c3,
  @Category_Clear = 1,
  @Type = @Type_78a345c3,
  @Length = @Length_78a345c3,
  @Precision = @Precision_78a345c3,
  @Precision_Clear = 1,
  @Scale = @Scale_78a345c3,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_78a345c3,
  @DefaultValue = @DefaultValue_78a345c3,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_78a345c3,
  @IsUniqueKey = @IsUniqueKey_78a345c3,
  @IsReadOnly = @IsReadOnly_78a345c3,
  @IsRequired = @IsRequired_78a345c3,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_78a345c3,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_78a345c3,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_78a345c3,
  @Configuration = @Configuration_78a345c3,
  @Configuration_Clear = 1,
  @Status = @Status_78a345c3,
  @IsCustom = @IsCustom_78a345c3,
  @MetadataSource = @MetadataSource_78a345c3;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_5ff1c0c5 UNIQUEIDENTIFIER,
@IntegrationObjectID_5ff1c0c5 UNIQUEIDENTIFIER,
@Name_5ff1c0c5 NVARCHAR(255),
@DisplayName_5ff1c0c5 NVARCHAR(255),
@Description_5ff1c0c5 NVARCHAR(MAX),
@Category_5ff1c0c5 NVARCHAR(100),
@Type_5ff1c0c5 NVARCHAR(100),
@Length_5ff1c0c5 INT,
@Precision_5ff1c0c5 INT,
@Scale_5ff1c0c5 INT,
@AllowsNull_5ff1c0c5 BIT,
@DefaultValue_5ff1c0c5 NVARCHAR(255),
@IsPrimaryKey_5ff1c0c5 BIT,
@IsUniqueKey_5ff1c0c5 BIT,
@IsReadOnly_5ff1c0c5 BIT,
@IsRequired_5ff1c0c5 BIT,
@RelatedIntegrationObjectID_5ff1c0c5 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_5ff1c0c5 NVARCHAR(255),
@Sequence_5ff1c0c5 INT,
@Configuration_5ff1c0c5 NVARCHAR(MAX),
@Status_5ff1c0c5 NVARCHAR(25),
@IsCustom_5ff1c0c5 BIT,
@MetadataSource_5ff1c0c5 NVARCHAR(20)
SET
  @ID_5ff1c0c5 = '5C294C8F-6D4E-5ACE-99E4-F188340607D2'
SET
  @IntegrationObjectID_5ff1c0c5 = '224D74C1-460F-5612-BD7D-29027DF76792'
SET
  @Name_5ff1c0c5 = N'orcid-id'
SET
  @DisplayName_5ff1c0c5 = N'Orcid Id'
SET
  @Description_5ff1c0c5 = N'The ORCID iD of the researcher this item belongs to. Foreign key to the record object.'
SET
  @Type_5ff1c0c5 = N'String'
SET
  @Length_5ff1c0c5 = 19
SET
  @AllowsNull_5ff1c0c5 = 1
SET
  @IsPrimaryKey_5ff1c0c5 = 0
SET
  @IsUniqueKey_5ff1c0c5 = 0
SET
  @IsReadOnly_5ff1c0c5 = 1
SET
  @IsRequired_5ff1c0c5 = 1
SET
  @RelatedIntegrationObjectID_5ff1c0c5 = '73AED6B8-468D-403B-B994-F3C786C98BC0'
SET
  @RelatedIntegrationObjectFieldName_5ff1c0c5 = N'orcid-id'
SET
  @Sequence_5ff1c0c5 = 0
SET
  @Status_5ff1c0c5 = N'Active'
SET
  @IsCustom_5ff1c0c5 = 0
SET
  @MetadataSource_5ff1c0c5 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_5ff1c0c5,
  @IntegrationObjectID = @IntegrationObjectID_5ff1c0c5,
  @Name = @Name_5ff1c0c5,
  @DisplayName = @DisplayName_5ff1c0c5,
  @Description = @Description_5ff1c0c5,
  @Category = @Category_5ff1c0c5,
  @Category_Clear = 1,
  @Type = @Type_5ff1c0c5,
  @Length = @Length_5ff1c0c5,
  @Precision = @Precision_5ff1c0c5,
  @Precision_Clear = 1,
  @Scale = @Scale_5ff1c0c5,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_5ff1c0c5,
  @DefaultValue = @DefaultValue_5ff1c0c5,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_5ff1c0c5,
  @IsUniqueKey = @IsUniqueKey_5ff1c0c5,
  @IsReadOnly = @IsReadOnly_5ff1c0c5,
  @IsRequired = @IsRequired_5ff1c0c5,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_5ff1c0c5,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_5ff1c0c5,
  @Sequence = @Sequence_5ff1c0c5,
  @Configuration = @Configuration_5ff1c0c5,
  @Configuration_Clear = 1,
  @Status = @Status_5ff1c0c5,
  @IsCustom = @IsCustom_5ff1c0c5,
  @MetadataSource = @MetadataSource_5ff1c0c5;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_e0536f5d UNIQUEIDENTIFIER,
@IntegrationObjectID_e0536f5d UNIQUEIDENTIFIER,
@Name_e0536f5d NVARCHAR(255),
@DisplayName_e0536f5d NVARCHAR(255),
@Description_e0536f5d NVARCHAR(MAX),
@Category_e0536f5d NVARCHAR(100),
@Type_e0536f5d NVARCHAR(100),
@Length_e0536f5d INT,
@Precision_e0536f5d INT,
@Scale_e0536f5d INT,
@AllowsNull_e0536f5d BIT,
@DefaultValue_e0536f5d NVARCHAR(255),
@IsPrimaryKey_e0536f5d BIT,
@IsUniqueKey_e0536f5d BIT,
@IsReadOnly_e0536f5d BIT,
@IsRequired_e0536f5d BIT,
@RelatedIntegrationObjectID_e0536f5d UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_e0536f5d NVARCHAR(255),
@Sequence_e0536f5d INT,
@Configuration_e0536f5d NVARCHAR(MAX),
@Status_e0536f5d NVARCHAR(25),
@IsCustom_e0536f5d BIT,
@MetadataSource_e0536f5d NVARCHAR(20)
SET
  @ID_e0536f5d = 'EB3EDA0E-C8B9-5D19-AFEB-2A49317A9BE1'
SET
  @IntegrationObjectID_e0536f5d = '224D74C1-460F-5612-BD7D-29027DF76792'
SET
  @Name_e0536f5d = N'put-code'
SET
  @DisplayName_e0536f5d = N'Put Code'
SET
  @Description_e0536f5d = N'ORCID''s stable identifier for this item within the record. Primary key.'
SET
  @Type_e0536f5d = N'Integer'
SET
  @AllowsNull_e0536f5d = 0
SET
  @IsPrimaryKey_e0536f5d = 1
SET
  @IsUniqueKey_e0536f5d = 1
SET
  @IsReadOnly_e0536f5d = 1
SET
  @IsRequired_e0536f5d = 1
SET
  @Sequence_e0536f5d = 1
SET
  @Status_e0536f5d = N'Active'
SET
  @IsCustom_e0536f5d = 0
SET
  @MetadataSource_e0536f5d = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_e0536f5d,
  @IntegrationObjectID = @IntegrationObjectID_e0536f5d,
  @Name = @Name_e0536f5d,
  @DisplayName = @DisplayName_e0536f5d,
  @Description = @Description_e0536f5d,
  @Category = @Category_e0536f5d,
  @Category_Clear = 1,
  @Type = @Type_e0536f5d,
  @Length = @Length_e0536f5d,
  @Length_Clear = 1,
  @Precision = @Precision_e0536f5d,
  @Precision_Clear = 1,
  @Scale = @Scale_e0536f5d,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_e0536f5d,
  @DefaultValue = @DefaultValue_e0536f5d,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_e0536f5d,
  @IsUniqueKey = @IsUniqueKey_e0536f5d,
  @IsReadOnly = @IsReadOnly_e0536f5d,
  @IsRequired = @IsRequired_e0536f5d,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_e0536f5d,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_e0536f5d,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_e0536f5d,
  @Configuration = @Configuration_e0536f5d,
  @Configuration_Clear = 1,
  @Status = @Status_e0536f5d,
  @IsCustom = @IsCustom_e0536f5d,
  @MetadataSource = @MetadataSource_e0536f5d;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_68fa326d UNIQUEIDENTIFIER,
@IntegrationObjectID_68fa326d UNIQUEIDENTIFIER,
@Name_68fa326d NVARCHAR(255),
@DisplayName_68fa326d NVARCHAR(255),
@Description_68fa326d NVARCHAR(MAX),
@Category_68fa326d NVARCHAR(100),
@Type_68fa326d NVARCHAR(100),
@Length_68fa326d INT,
@Precision_68fa326d INT,
@Scale_68fa326d INT,
@AllowsNull_68fa326d BIT,
@DefaultValue_68fa326d NVARCHAR(255),
@IsPrimaryKey_68fa326d BIT,
@IsUniqueKey_68fa326d BIT,
@IsReadOnly_68fa326d BIT,
@IsRequired_68fa326d BIT,
@RelatedIntegrationObjectID_68fa326d UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_68fa326d NVARCHAR(255),
@Sequence_68fa326d INT,
@Configuration_68fa326d NVARCHAR(MAX),
@Status_68fa326d NVARCHAR(25),
@IsCustom_68fa326d BIT,
@MetadataSource_68fa326d NVARCHAR(20)
SET
  @ID_68fa326d = '35CE4EC2-D2BF-599F-A77C-FCC453D3BEFE'
SET
  @IntegrationObjectID_68fa326d = '224D74C1-460F-5612-BD7D-29027DF76792'
SET
  @Name_68fa326d = N'path'
SET
  @DisplayName_68fa326d = N'Path'
SET
  @Description_68fa326d = N'Element path /{orcid}/{section}/{put-code}.'
SET
  @Type_68fa326d = N'String'
SET
  @Length_68fa326d = 500
SET
  @AllowsNull_68fa326d = 1
SET
  @IsPrimaryKey_68fa326d = 0
SET
  @IsUniqueKey_68fa326d = 0
SET
  @IsReadOnly_68fa326d = 1
SET
  @IsRequired_68fa326d = 0
SET
  @Sequence_68fa326d = 2
SET
  @Status_68fa326d = N'Active'
SET
  @IsCustom_68fa326d = 0
SET
  @MetadataSource_68fa326d = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_68fa326d,
  @IntegrationObjectID = @IntegrationObjectID_68fa326d,
  @Name = @Name_68fa326d,
  @DisplayName = @DisplayName_68fa326d,
  @Description = @Description_68fa326d,
  @Category = @Category_68fa326d,
  @Category_Clear = 1,
  @Type = @Type_68fa326d,
  @Length = @Length_68fa326d,
  @Precision = @Precision_68fa326d,
  @Precision_Clear = 1,
  @Scale = @Scale_68fa326d,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_68fa326d,
  @DefaultValue = @DefaultValue_68fa326d,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_68fa326d,
  @IsUniqueKey = @IsUniqueKey_68fa326d,
  @IsReadOnly = @IsReadOnly_68fa326d,
  @IsRequired = @IsRequired_68fa326d,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_68fa326d,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_68fa326d,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_68fa326d,
  @Configuration = @Configuration_68fa326d,
  @Configuration_Clear = 1,
  @Status = @Status_68fa326d,
  @IsCustom = @IsCustom_68fa326d,
  @MetadataSource = @MetadataSource_68fa326d;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_bad9a426 UNIQUEIDENTIFIER,
@IntegrationObjectID_bad9a426 UNIQUEIDENTIFIER,
@Name_bad9a426 NVARCHAR(255),
@DisplayName_bad9a426 NVARCHAR(255),
@Description_bad9a426 NVARCHAR(MAX),
@Category_bad9a426 NVARCHAR(100),
@Type_bad9a426 NVARCHAR(100),
@Length_bad9a426 INT,
@Precision_bad9a426 INT,
@Scale_bad9a426 INT,
@AllowsNull_bad9a426 BIT,
@DefaultValue_bad9a426 NVARCHAR(255),
@IsPrimaryKey_bad9a426 BIT,
@IsUniqueKey_bad9a426 BIT,
@IsReadOnly_bad9a426 BIT,
@IsRequired_bad9a426 BIT,
@RelatedIntegrationObjectID_bad9a426 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_bad9a426 NVARCHAR(255),
@Sequence_bad9a426 INT,
@Configuration_bad9a426 NVARCHAR(MAX),
@Status_bad9a426 NVARCHAR(25),
@IsCustom_bad9a426 BIT,
@MetadataSource_bad9a426 NVARCHAR(20)
SET
  @ID_bad9a426 = '42A99AD8-E850-55C5-86EA-714A4FE6C990'
SET
  @IntegrationObjectID_bad9a426 = '224D74C1-460F-5612-BD7D-29027DF76792'
SET
  @Name_bad9a426 = N'visibility'
SET
  @DisplayName_bad9a426 = N'Visibility'
SET
  @Description_bad9a426 = N'ORCID visibility of the item (public, limited, private). The Public API only serves public.'
SET
  @Type_bad9a426 = N'String'
SET
  @AllowsNull_bad9a426 = 1
SET
  @IsPrimaryKey_bad9a426 = 0
SET
  @IsUniqueKey_bad9a426 = 0
SET
  @IsReadOnly_bad9a426 = 1
SET
  @IsRequired_bad9a426 = 0
SET
  @Sequence_bad9a426 = 3
SET
  @Status_bad9a426 = N'Active'
SET
  @IsCustom_bad9a426 = 0
SET
  @MetadataSource_bad9a426 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_bad9a426,
  @IntegrationObjectID = @IntegrationObjectID_bad9a426,
  @Name = @Name_bad9a426,
  @DisplayName = @DisplayName_bad9a426,
  @Description = @Description_bad9a426,
  @Category = @Category_bad9a426,
  @Category_Clear = 1,
  @Type = @Type_bad9a426,
  @Length = @Length_bad9a426,
  @Length_Clear = 1,
  @Precision = @Precision_bad9a426,
  @Precision_Clear = 1,
  @Scale = @Scale_bad9a426,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_bad9a426,
  @DefaultValue = @DefaultValue_bad9a426,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_bad9a426,
  @IsUniqueKey = @IsUniqueKey_bad9a426,
  @IsReadOnly = @IsReadOnly_bad9a426,
  @IsRequired = @IsRequired_bad9a426,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_bad9a426,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_bad9a426,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_bad9a426,
  @Configuration = @Configuration_bad9a426,
  @Configuration_Clear = 1,
  @Status = @Status_bad9a426,
  @IsCustom = @IsCustom_bad9a426,
  @MetadataSource = @MetadataSource_bad9a426;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_27927602 UNIQUEIDENTIFIER,
@IntegrationObjectID_27927602 UNIQUEIDENTIFIER,
@Name_27927602 NVARCHAR(255),
@DisplayName_27927602 NVARCHAR(255),
@Description_27927602 NVARCHAR(MAX),
@Category_27927602 NVARCHAR(100),
@Type_27927602 NVARCHAR(100),
@Length_27927602 INT,
@Precision_27927602 INT,
@Scale_27927602 INT,
@AllowsNull_27927602 BIT,
@DefaultValue_27927602 NVARCHAR(255),
@IsPrimaryKey_27927602 BIT,
@IsUniqueKey_27927602 BIT,
@IsReadOnly_27927602 BIT,
@IsRequired_27927602 BIT,
@RelatedIntegrationObjectID_27927602 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_27927602 NVARCHAR(255),
@Sequence_27927602 INT,
@Configuration_27927602 NVARCHAR(MAX),
@Status_27927602 NVARCHAR(25),
@IsCustom_27927602 BIT,
@MetadataSource_27927602 NVARCHAR(20)
SET
  @ID_27927602 = '1C86C30D-09A2-579E-978C-36B935202D39'
SET
  @IntegrationObjectID_27927602 = '224D74C1-460F-5612-BD7D-29027DF76792'
SET
  @Name_27927602 = N'display-index'
SET
  @DisplayName_27927602 = N'Display Index'
SET
  @Description_27927602 = N'Display order the researcher chose for the item.'
SET
  @Type_27927602 = N'String'
SET
  @AllowsNull_27927602 = 1
SET
  @IsPrimaryKey_27927602 = 0
SET
  @IsUniqueKey_27927602 = 0
SET
  @IsReadOnly_27927602 = 1
SET
  @IsRequired_27927602 = 0
SET
  @Sequence_27927602 = 4
SET
  @Status_27927602 = N'Active'
SET
  @IsCustom_27927602 = 0
SET
  @MetadataSource_27927602 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_27927602,
  @IntegrationObjectID = @IntegrationObjectID_27927602,
  @Name = @Name_27927602,
  @DisplayName = @DisplayName_27927602,
  @Description = @Description_27927602,
  @Category = @Category_27927602,
  @Category_Clear = 1,
  @Type = @Type_27927602,
  @Length = @Length_27927602,
  @Length_Clear = 1,
  @Precision = @Precision_27927602,
  @Precision_Clear = 1,
  @Scale = @Scale_27927602,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_27927602,
  @DefaultValue = @DefaultValue_27927602,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_27927602,
  @IsUniqueKey = @IsUniqueKey_27927602,
  @IsReadOnly = @IsReadOnly_27927602,
  @IsRequired = @IsRequired_27927602,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_27927602,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_27927602,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_27927602,
  @Configuration = @Configuration_27927602,
  @Configuration_Clear = 1,
  @Status = @Status_27927602,
  @IsCustom = @IsCustom_27927602,
  @MetadataSource = @MetadataSource_27927602;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_02e0c827 UNIQUEIDENTIFIER,
@IntegrationObjectID_02e0c827 UNIQUEIDENTIFIER,
@Name_02e0c827 NVARCHAR(255),
@DisplayName_02e0c827 NVARCHAR(255),
@Description_02e0c827 NVARCHAR(MAX),
@Category_02e0c827 NVARCHAR(100),
@Type_02e0c827 NVARCHAR(100),
@Length_02e0c827 INT,
@Precision_02e0c827 INT,
@Scale_02e0c827 INT,
@AllowsNull_02e0c827 BIT,
@DefaultValue_02e0c827 NVARCHAR(255),
@IsPrimaryKey_02e0c827 BIT,
@IsUniqueKey_02e0c827 BIT,
@IsReadOnly_02e0c827 BIT,
@IsRequired_02e0c827 BIT,
@RelatedIntegrationObjectID_02e0c827 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_02e0c827 NVARCHAR(255),
@Sequence_02e0c827 INT,
@Configuration_02e0c827 NVARCHAR(MAX),
@Status_02e0c827 NVARCHAR(25),
@IsCustom_02e0c827 BIT,
@MetadataSource_02e0c827 NVARCHAR(20)
SET
  @ID_02e0c827 = '173A1B20-21FE-5431-9578-D7A599DF552C'
SET
  @IntegrationObjectID_02e0c827 = '224D74C1-460F-5612-BD7D-29027DF76792'
SET
  @Name_02e0c827 = N'created-date'
SET
  @DisplayName_02e0c827 = N'Created Date'
SET
  @Description_02e0c827 = N'When ORCID created the item.'
SET
  @Type_02e0c827 = N'DateTime'
SET
  @AllowsNull_02e0c827 = 1
SET
  @IsPrimaryKey_02e0c827 = 0
SET
  @IsUniqueKey_02e0c827 = 0
SET
  @IsReadOnly_02e0c827 = 1
SET
  @IsRequired_02e0c827 = 0
SET
  @Sequence_02e0c827 = 5
SET
  @Status_02e0c827 = N'Active'
SET
  @IsCustom_02e0c827 = 0
SET
  @MetadataSource_02e0c827 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_02e0c827,
  @IntegrationObjectID = @IntegrationObjectID_02e0c827,
  @Name = @Name_02e0c827,
  @DisplayName = @DisplayName_02e0c827,
  @Description = @Description_02e0c827,
  @Category = @Category_02e0c827,
  @Category_Clear = 1,
  @Type = @Type_02e0c827,
  @Length = @Length_02e0c827,
  @Length_Clear = 1,
  @Precision = @Precision_02e0c827,
  @Precision_Clear = 1,
  @Scale = @Scale_02e0c827,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_02e0c827,
  @DefaultValue = @DefaultValue_02e0c827,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_02e0c827,
  @IsUniqueKey = @IsUniqueKey_02e0c827,
  @IsReadOnly = @IsReadOnly_02e0c827,
  @IsRequired = @IsRequired_02e0c827,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_02e0c827,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_02e0c827,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_02e0c827,
  @Configuration = @Configuration_02e0c827,
  @Configuration_Clear = 1,
  @Status = @Status_02e0c827,
  @IsCustom = @IsCustom_02e0c827,
  @MetadataSource = @MetadataSource_02e0c827;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_6847a9d8 UNIQUEIDENTIFIER,
@IntegrationObjectID_6847a9d8 UNIQUEIDENTIFIER,
@Name_6847a9d8 NVARCHAR(255),
@DisplayName_6847a9d8 NVARCHAR(255),
@Description_6847a9d8 NVARCHAR(MAX),
@Category_6847a9d8 NVARCHAR(100),
@Type_6847a9d8 NVARCHAR(100),
@Length_6847a9d8 INT,
@Precision_6847a9d8 INT,
@Scale_6847a9d8 INT,
@AllowsNull_6847a9d8 BIT,
@DefaultValue_6847a9d8 NVARCHAR(255),
@IsPrimaryKey_6847a9d8 BIT,
@IsUniqueKey_6847a9d8 BIT,
@IsReadOnly_6847a9d8 BIT,
@IsRequired_6847a9d8 BIT,
@RelatedIntegrationObjectID_6847a9d8 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_6847a9d8 NVARCHAR(255),
@Sequence_6847a9d8 INT,
@Configuration_6847a9d8 NVARCHAR(MAX),
@Status_6847a9d8 NVARCHAR(25),
@IsCustom_6847a9d8 BIT,
@MetadataSource_6847a9d8 NVARCHAR(20)
SET
  @ID_6847a9d8 = '1DA5926F-63B5-56C2-9220-DB90D910F8DC'
SET
  @IntegrationObjectID_6847a9d8 = '224D74C1-460F-5612-BD7D-29027DF76792'
SET
  @Name_6847a9d8 = N'last-modified-date'
SET
  @DisplayName_6847a9d8 = N'Last Modified Date'
SET
  @Description_6847a9d8 = N'When ORCID last changed the item. Incremental watermark.'
SET
  @Type_6847a9d8 = N'DateTime'
SET
  @AllowsNull_6847a9d8 = 1
SET
  @IsPrimaryKey_6847a9d8 = 0
SET
  @IsUniqueKey_6847a9d8 = 0
SET
  @IsReadOnly_6847a9d8 = 1
SET
  @IsRequired_6847a9d8 = 0
SET
  @Sequence_6847a9d8 = 6
SET
  @Status_6847a9d8 = N'Active'
SET
  @IsCustom_6847a9d8 = 0
SET
  @MetadataSource_6847a9d8 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_6847a9d8,
  @IntegrationObjectID = @IntegrationObjectID_6847a9d8,
  @Name = @Name_6847a9d8,
  @DisplayName = @DisplayName_6847a9d8,
  @Description = @Description_6847a9d8,
  @Category = @Category_6847a9d8,
  @Category_Clear = 1,
  @Type = @Type_6847a9d8,
  @Length = @Length_6847a9d8,
  @Length_Clear = 1,
  @Precision = @Precision_6847a9d8,
  @Precision_Clear = 1,
  @Scale = @Scale_6847a9d8,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_6847a9d8,
  @DefaultValue = @DefaultValue_6847a9d8,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_6847a9d8,
  @IsUniqueKey = @IsUniqueKey_6847a9d8,
  @IsReadOnly = @IsReadOnly_6847a9d8,
  @IsRequired = @IsRequired_6847a9d8,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_6847a9d8,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_6847a9d8,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_6847a9d8,
  @Configuration = @Configuration_6847a9d8,
  @Configuration_Clear = 1,
  @Status = @Status_6847a9d8,
  @IsCustom = @IsCustom_6847a9d8,
  @MetadataSource = @MetadataSource_6847a9d8;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_f4d60da2 UNIQUEIDENTIFIER,
@IntegrationObjectID_f4d60da2 UNIQUEIDENTIFIER,
@Name_f4d60da2 NVARCHAR(255),
@DisplayName_f4d60da2 NVARCHAR(255),
@Description_f4d60da2 NVARCHAR(MAX),
@Category_f4d60da2 NVARCHAR(100),
@Type_f4d60da2 NVARCHAR(100),
@Length_f4d60da2 INT,
@Precision_f4d60da2 INT,
@Scale_f4d60da2 INT,
@AllowsNull_f4d60da2 BIT,
@DefaultValue_f4d60da2 NVARCHAR(255),
@IsPrimaryKey_f4d60da2 BIT,
@IsUniqueKey_f4d60da2 BIT,
@IsReadOnly_f4d60da2 BIT,
@IsRequired_f4d60da2 BIT,
@RelatedIntegrationObjectID_f4d60da2 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_f4d60da2 NVARCHAR(255),
@Sequence_f4d60da2 INT,
@Configuration_f4d60da2 NVARCHAR(MAX),
@Status_f4d60da2 NVARCHAR(25),
@IsCustom_f4d60da2 BIT,
@MetadataSource_f4d60da2 NVARCHAR(20)
SET
  @ID_f4d60da2 = '83DF2608-2DF6-5DAF-B5C1-A7BFF3C04B5D'
SET
  @IntegrationObjectID_f4d60da2 = '224D74C1-460F-5612-BD7D-29027DF76792'
SET
  @Name_f4d60da2 = N'source'
SET
  @DisplayName_f4d60da2 = N'Source'
SET
  @Description_f4d60da2 = N'Full source block: who asserted the item.'
SET
  @Type_f4d60da2 = N'json'
SET
  @AllowsNull_f4d60da2 = 1
SET
  @IsPrimaryKey_f4d60da2 = 0
SET
  @IsUniqueKey_f4d60da2 = 0
SET
  @IsReadOnly_f4d60da2 = 1
SET
  @IsRequired_f4d60da2 = 0
SET
  @Sequence_f4d60da2 = 7
SET
  @Status_f4d60da2 = N'Active'
SET
  @IsCustom_f4d60da2 = 0
SET
  @MetadataSource_f4d60da2 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_f4d60da2,
  @IntegrationObjectID = @IntegrationObjectID_f4d60da2,
  @Name = @Name_f4d60da2,
  @DisplayName = @DisplayName_f4d60da2,
  @Description = @Description_f4d60da2,
  @Category = @Category_f4d60da2,
  @Category_Clear = 1,
  @Type = @Type_f4d60da2,
  @Length = @Length_f4d60da2,
  @Length_Clear = 1,
  @Precision = @Precision_f4d60da2,
  @Precision_Clear = 1,
  @Scale = @Scale_f4d60da2,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_f4d60da2,
  @DefaultValue = @DefaultValue_f4d60da2,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_f4d60da2,
  @IsUniqueKey = @IsUniqueKey_f4d60da2,
  @IsReadOnly = @IsReadOnly_f4d60da2,
  @IsRequired = @IsRequired_f4d60da2,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_f4d60da2,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_f4d60da2,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_f4d60da2,
  @Configuration = @Configuration_f4d60da2,
  @Configuration_Clear = 1,
  @Status = @Status_f4d60da2,
  @IsCustom = @IsCustom_f4d60da2,
  @MetadataSource = @MetadataSource_f4d60da2;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_5e5901c2 UNIQUEIDENTIFIER,
@IntegrationObjectID_5e5901c2 UNIQUEIDENTIFIER,
@Name_5e5901c2 NVARCHAR(255),
@DisplayName_5e5901c2 NVARCHAR(255),
@Description_5e5901c2 NVARCHAR(MAX),
@Category_5e5901c2 NVARCHAR(100),
@Type_5e5901c2 NVARCHAR(100),
@Length_5e5901c2 INT,
@Precision_5e5901c2 INT,
@Scale_5e5901c2 INT,
@AllowsNull_5e5901c2 BIT,
@DefaultValue_5e5901c2 NVARCHAR(255),
@IsPrimaryKey_5e5901c2 BIT,
@IsUniqueKey_5e5901c2 BIT,
@IsReadOnly_5e5901c2 BIT,
@IsRequired_5e5901c2 BIT,
@RelatedIntegrationObjectID_5e5901c2 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_5e5901c2 NVARCHAR(255),
@Sequence_5e5901c2 INT,
@Configuration_5e5901c2 NVARCHAR(MAX),
@Status_5e5901c2 NVARCHAR(25),
@IsCustom_5e5901c2 BIT,
@MetadataSource_5e5901c2 NVARCHAR(20)
SET
  @ID_5e5901c2 = 'ACD345D8-841E-512A-8BCA-ADB8D6983AA3'
SET
  @IntegrationObjectID_5e5901c2 = '224D74C1-460F-5612-BD7D-29027DF76792'
SET
  @Name_5e5901c2 = N'source-name'
SET
  @DisplayName_5e5901c2 = N'Source Name'
SET
  @Description_5e5901c2 = N'Who asserted this item: the researcher or a system such as Crossref. Lifted from source.source-name.'
SET
  @Type_5e5901c2 = N'String'
SET
  @Length_5e5901c2 = 500
SET
  @AllowsNull_5e5901c2 = 1
SET
  @IsPrimaryKey_5e5901c2 = 0
SET
  @IsUniqueKey_5e5901c2 = 0
SET
  @IsReadOnly_5e5901c2 = 1
SET
  @IsRequired_5e5901c2 = 0
SET
  @Sequence_5e5901c2 = 8
SET
  @Status_5e5901c2 = N'Active'
SET
  @IsCustom_5e5901c2 = 0
SET
  @MetadataSource_5e5901c2 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_5e5901c2,
  @IntegrationObjectID = @IntegrationObjectID_5e5901c2,
  @Name = @Name_5e5901c2,
  @DisplayName = @DisplayName_5e5901c2,
  @Description = @Description_5e5901c2,
  @Category = @Category_5e5901c2,
  @Category_Clear = 1,
  @Type = @Type_5e5901c2,
  @Length = @Length_5e5901c2,
  @Precision = @Precision_5e5901c2,
  @Precision_Clear = 1,
  @Scale = @Scale_5e5901c2,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_5e5901c2,
  @DefaultValue = @DefaultValue_5e5901c2,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_5e5901c2,
  @IsUniqueKey = @IsUniqueKey_5e5901c2,
  @IsReadOnly = @IsReadOnly_5e5901c2,
  @IsRequired = @IsRequired_5e5901c2,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_5e5901c2,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_5e5901c2,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_5e5901c2,
  @Configuration = @Configuration_5e5901c2,
  @Configuration_Clear = 1,
  @Status = @Status_5e5901c2,
  @IsCustom = @IsCustom_5e5901c2,
  @MetadataSource = @MetadataSource_5e5901c2;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_c78c5cce UNIQUEIDENTIFIER,
@IntegrationObjectID_c78c5cce UNIQUEIDENTIFIER,
@Name_c78c5cce NVARCHAR(255),
@DisplayName_c78c5cce NVARCHAR(255),
@Description_c78c5cce NVARCHAR(MAX),
@Category_c78c5cce NVARCHAR(100),
@Type_c78c5cce NVARCHAR(100),
@Length_c78c5cce INT,
@Precision_c78c5cce INT,
@Scale_c78c5cce INT,
@AllowsNull_c78c5cce BIT,
@DefaultValue_c78c5cce NVARCHAR(255),
@IsPrimaryKey_c78c5cce BIT,
@IsUniqueKey_c78c5cce BIT,
@IsReadOnly_c78c5cce BIT,
@IsRequired_c78c5cce BIT,
@RelatedIntegrationObjectID_c78c5cce UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_c78c5cce NVARCHAR(255),
@Sequence_c78c5cce INT,
@Configuration_c78c5cce NVARCHAR(MAX),
@Status_c78c5cce NVARCHAR(25),
@IsCustom_c78c5cce BIT,
@MetadataSource_c78c5cce NVARCHAR(20)
SET
  @ID_c78c5cce = 'D0994D38-E245-5619-A036-E0A903D9A408'
SET
  @IntegrationObjectID_c78c5cce = '224D74C1-460F-5612-BD7D-29027DF76792'
SET
  @Name_c78c5cce = N'source-orcid'
SET
  @DisplayName_c78c5cce = N'Source Orcid'
SET
  @Description_c78c5cce = N'ORCID iD of the asserting source when a person asserted it. Lifted from source.source-orcid.path.'
SET
  @Type_c78c5cce = N'String'
SET
  @Length_c78c5cce = 19
SET
  @AllowsNull_c78c5cce = 1
SET
  @IsPrimaryKey_c78c5cce = 0
SET
  @IsUniqueKey_c78c5cce = 0
SET
  @IsReadOnly_c78c5cce = 1
SET
  @IsRequired_c78c5cce = 0
SET
  @Sequence_c78c5cce = 9
SET
  @Status_c78c5cce = N'Active'
SET
  @IsCustom_c78c5cce = 0
SET
  @MetadataSource_c78c5cce = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_c78c5cce,
  @IntegrationObjectID = @IntegrationObjectID_c78c5cce,
  @Name = @Name_c78c5cce,
  @DisplayName = @DisplayName_c78c5cce,
  @Description = @Description_c78c5cce,
  @Category = @Category_c78c5cce,
  @Category_Clear = 1,
  @Type = @Type_c78c5cce,
  @Length = @Length_c78c5cce,
  @Precision = @Precision_c78c5cce,
  @Precision_Clear = 1,
  @Scale = @Scale_c78c5cce,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_c78c5cce,
  @DefaultValue = @DefaultValue_c78c5cce,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_c78c5cce,
  @IsUniqueKey = @IsUniqueKey_c78c5cce,
  @IsReadOnly = @IsReadOnly_c78c5cce,
  @IsRequired = @IsRequired_c78c5cce,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_c78c5cce,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_c78c5cce,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_c78c5cce,
  @Configuration = @Configuration_c78c5cce,
  @Configuration_Clear = 1,
  @Status = @Status_c78c5cce,
  @IsCustom = @IsCustom_c78c5cce,
  @MetadataSource = @MetadataSource_c78c5cce;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_b93eac66 UNIQUEIDENTIFIER,
@IntegrationObjectID_b93eac66 UNIQUEIDENTIFIER,
@Name_b93eac66 NVARCHAR(255),
@DisplayName_b93eac66 NVARCHAR(255),
@Description_b93eac66 NVARCHAR(MAX),
@Category_b93eac66 NVARCHAR(100),
@Type_b93eac66 NVARCHAR(100),
@Length_b93eac66 INT,
@Precision_b93eac66 INT,
@Scale_b93eac66 INT,
@AllowsNull_b93eac66 BIT,
@DefaultValue_b93eac66 NVARCHAR(255),
@IsPrimaryKey_b93eac66 BIT,
@IsUniqueKey_b93eac66 BIT,
@IsReadOnly_b93eac66 BIT,
@IsRequired_b93eac66 BIT,
@RelatedIntegrationObjectID_b93eac66 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_b93eac66 NVARCHAR(255),
@Sequence_b93eac66 INT,
@Configuration_b93eac66 NVARCHAR(MAX),
@Status_b93eac66 NVARCHAR(25),
@IsCustom_b93eac66 BIT,
@MetadataSource_b93eac66 NVARCHAR(20)
SET
  @ID_b93eac66 = '31E00E1E-0FDF-5D23-8BF0-2A428704FF41'
SET
  @IntegrationObjectID_b93eac66 = '224D74C1-460F-5612-BD7D-29027DF76792'
SET
  @Name_b93eac66 = N'external-id-type'
SET
  @DisplayName_b93eac66 = N'External Id Type'
SET
  @Description_b93eac66 = N'The identifying system (e.g. Scopus Author ID).'
SET
  @Type_b93eac66 = N'String'
SET
  @Length_b93eac66 = 255
SET
  @AllowsNull_b93eac66 = 1
SET
  @IsPrimaryKey_b93eac66 = 0
SET
  @IsUniqueKey_b93eac66 = 0
SET
  @IsReadOnly_b93eac66 = 1
SET
  @IsRequired_b93eac66 = 0
SET
  @Sequence_b93eac66 = 10
SET
  @Status_b93eac66 = N'Active'
SET
  @IsCustom_b93eac66 = 0
SET
  @MetadataSource_b93eac66 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_b93eac66,
  @IntegrationObjectID = @IntegrationObjectID_b93eac66,
  @Name = @Name_b93eac66,
  @DisplayName = @DisplayName_b93eac66,
  @Description = @Description_b93eac66,
  @Category = @Category_b93eac66,
  @Category_Clear = 1,
  @Type = @Type_b93eac66,
  @Length = @Length_b93eac66,
  @Precision = @Precision_b93eac66,
  @Precision_Clear = 1,
  @Scale = @Scale_b93eac66,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_b93eac66,
  @DefaultValue = @DefaultValue_b93eac66,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_b93eac66,
  @IsUniqueKey = @IsUniqueKey_b93eac66,
  @IsReadOnly = @IsReadOnly_b93eac66,
  @IsRequired = @IsRequired_b93eac66,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_b93eac66,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_b93eac66,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_b93eac66,
  @Configuration = @Configuration_b93eac66,
  @Configuration_Clear = 1,
  @Status = @Status_b93eac66,
  @IsCustom = @IsCustom_b93eac66,
  @MetadataSource = @MetadataSource_b93eac66;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_afd978a7 UNIQUEIDENTIFIER,
@IntegrationObjectID_afd978a7 UNIQUEIDENTIFIER,
@Name_afd978a7 NVARCHAR(255),
@DisplayName_afd978a7 NVARCHAR(255),
@Description_afd978a7 NVARCHAR(MAX),
@Category_afd978a7 NVARCHAR(100),
@Type_afd978a7 NVARCHAR(100),
@Length_afd978a7 INT,
@Precision_afd978a7 INT,
@Scale_afd978a7 INT,
@AllowsNull_afd978a7 BIT,
@DefaultValue_afd978a7 NVARCHAR(255),
@IsPrimaryKey_afd978a7 BIT,
@IsUniqueKey_afd978a7 BIT,
@IsReadOnly_afd978a7 BIT,
@IsRequired_afd978a7 BIT,
@RelatedIntegrationObjectID_afd978a7 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_afd978a7 NVARCHAR(255),
@Sequence_afd978a7 INT,
@Configuration_afd978a7 NVARCHAR(MAX),
@Status_afd978a7 NVARCHAR(25),
@IsCustom_afd978a7 BIT,
@MetadataSource_afd978a7 NVARCHAR(20)
SET
  @ID_afd978a7 = '41EF3A81-3CD5-517D-B8E1-98FD38DEA160'
SET
  @IntegrationObjectID_afd978a7 = '224D74C1-460F-5612-BD7D-29027DF76792'
SET
  @Name_afd978a7 = N'external-id-value'
SET
  @DisplayName_afd978a7 = N'External Id Value'
SET
  @Description_afd978a7 = N'The identifier value.'
SET
  @Type_afd978a7 = N'String'
SET
  @Length_afd978a7 = 500
SET
  @AllowsNull_afd978a7 = 1
SET
  @IsPrimaryKey_afd978a7 = 0
SET
  @IsUniqueKey_afd978a7 = 0
SET
  @IsReadOnly_afd978a7 = 1
SET
  @IsRequired_afd978a7 = 0
SET
  @Sequence_afd978a7 = 11
SET
  @Status_afd978a7 = N'Active'
SET
  @IsCustom_afd978a7 = 0
SET
  @MetadataSource_afd978a7 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_afd978a7,
  @IntegrationObjectID = @IntegrationObjectID_afd978a7,
  @Name = @Name_afd978a7,
  @DisplayName = @DisplayName_afd978a7,
  @Description = @Description_afd978a7,
  @Category = @Category_afd978a7,
  @Category_Clear = 1,
  @Type = @Type_afd978a7,
  @Length = @Length_afd978a7,
  @Precision = @Precision_afd978a7,
  @Precision_Clear = 1,
  @Scale = @Scale_afd978a7,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_afd978a7,
  @DefaultValue = @DefaultValue_afd978a7,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_afd978a7,
  @IsUniqueKey = @IsUniqueKey_afd978a7,
  @IsReadOnly = @IsReadOnly_afd978a7,
  @IsRequired = @IsRequired_afd978a7,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_afd978a7,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_afd978a7,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_afd978a7,
  @Configuration = @Configuration_afd978a7,
  @Configuration_Clear = 1,
  @Status = @Status_afd978a7,
  @IsCustom = @IsCustom_afd978a7,
  @MetadataSource = @MetadataSource_afd978a7;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_7a033b4b UNIQUEIDENTIFIER,
@IntegrationObjectID_7a033b4b UNIQUEIDENTIFIER,
@Name_7a033b4b NVARCHAR(255),
@DisplayName_7a033b4b NVARCHAR(255),
@Description_7a033b4b NVARCHAR(MAX),
@Category_7a033b4b NVARCHAR(100),
@Type_7a033b4b NVARCHAR(100),
@Length_7a033b4b INT,
@Precision_7a033b4b INT,
@Scale_7a033b4b INT,
@AllowsNull_7a033b4b BIT,
@DefaultValue_7a033b4b NVARCHAR(255),
@IsPrimaryKey_7a033b4b BIT,
@IsUniqueKey_7a033b4b BIT,
@IsReadOnly_7a033b4b BIT,
@IsRequired_7a033b4b BIT,
@RelatedIntegrationObjectID_7a033b4b UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_7a033b4b NVARCHAR(255),
@Sequence_7a033b4b INT,
@Configuration_7a033b4b NVARCHAR(MAX),
@Status_7a033b4b NVARCHAR(25),
@IsCustom_7a033b4b BIT,
@MetadataSource_7a033b4b NVARCHAR(20)
SET
  @ID_7a033b4b = '6551DDA2-C1A2-5EF4-B31A-457BE84DC68D'
SET
  @IntegrationObjectID_7a033b4b = '224D74C1-460F-5612-BD7D-29027DF76792'
SET
  @Name_7a033b4b = N'external-id-url'
SET
  @DisplayName_7a033b4b = N'External Id Url'
SET
  @Description_7a033b4b = N'Link to the profile on that system.'
SET
  @Type_7a033b4b = N'String'
SET
  @Length_7a033b4b = 2048
SET
  @AllowsNull_7a033b4b = 1
SET
  @IsPrimaryKey_7a033b4b = 0
SET
  @IsUniqueKey_7a033b4b = 0
SET
  @IsReadOnly_7a033b4b = 1
SET
  @IsRequired_7a033b4b = 0
SET
  @Sequence_7a033b4b = 12
SET
  @Status_7a033b4b = N'Active'
SET
  @IsCustom_7a033b4b = 0
SET
  @MetadataSource_7a033b4b = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_7a033b4b,
  @IntegrationObjectID = @IntegrationObjectID_7a033b4b,
  @Name = @Name_7a033b4b,
  @DisplayName = @DisplayName_7a033b4b,
  @Description = @Description_7a033b4b,
  @Category = @Category_7a033b4b,
  @Category_Clear = 1,
  @Type = @Type_7a033b4b,
  @Length = @Length_7a033b4b,
  @Precision = @Precision_7a033b4b,
  @Precision_Clear = 1,
  @Scale = @Scale_7a033b4b,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_7a033b4b,
  @DefaultValue = @DefaultValue_7a033b4b,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_7a033b4b,
  @IsUniqueKey = @IsUniqueKey_7a033b4b,
  @IsReadOnly = @IsReadOnly_7a033b4b,
  @IsRequired = @IsRequired_7a033b4b,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_7a033b4b,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_7a033b4b,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_7a033b4b,
  @Configuration = @Configuration_7a033b4b,
  @Configuration_Clear = 1,
  @Status = @Status_7a033b4b,
  @IsCustom = @IsCustom_7a033b4b,
  @MetadataSource = @MetadataSource_7a033b4b;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_8adcaf33 UNIQUEIDENTIFIER,
@IntegrationObjectID_8adcaf33 UNIQUEIDENTIFIER,
@Name_8adcaf33 NVARCHAR(255),
@DisplayName_8adcaf33 NVARCHAR(255),
@Description_8adcaf33 NVARCHAR(MAX),
@Category_8adcaf33 NVARCHAR(100),
@Type_8adcaf33 NVARCHAR(100),
@Length_8adcaf33 INT,
@Precision_8adcaf33 INT,
@Scale_8adcaf33 INT,
@AllowsNull_8adcaf33 BIT,
@DefaultValue_8adcaf33 NVARCHAR(255),
@IsPrimaryKey_8adcaf33 BIT,
@IsUniqueKey_8adcaf33 BIT,
@IsReadOnly_8adcaf33 BIT,
@IsRequired_8adcaf33 BIT,
@RelatedIntegrationObjectID_8adcaf33 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_8adcaf33 NVARCHAR(255),
@Sequence_8adcaf33 INT,
@Configuration_8adcaf33 NVARCHAR(MAX),
@Status_8adcaf33 NVARCHAR(25),
@IsCustom_8adcaf33 BIT,
@MetadataSource_8adcaf33 NVARCHAR(20)
SET
  @ID_8adcaf33 = 'E0D65254-061E-583D-B5C5-A38A1EA938EC'
SET
  @IntegrationObjectID_8adcaf33 = '224D74C1-460F-5612-BD7D-29027DF76792'
SET
  @Name_8adcaf33 = N'external-id-relationship'
SET
  @DisplayName_8adcaf33 = N'External Id Relationship'
SET
  @Description_8adcaf33 = N'Whether the id identifies this person (self) or a related record.'
SET
  @Type_8adcaf33 = N'String'
SET
  @Length_8adcaf33 = 50
SET
  @AllowsNull_8adcaf33 = 1
SET
  @IsPrimaryKey_8adcaf33 = 0
SET
  @IsUniqueKey_8adcaf33 = 0
SET
  @IsReadOnly_8adcaf33 = 1
SET
  @IsRequired_8adcaf33 = 0
SET
  @Sequence_8adcaf33 = 13
SET
  @Status_8adcaf33 = N'Active'
SET
  @IsCustom_8adcaf33 = 0
SET
  @MetadataSource_8adcaf33 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_8adcaf33,
  @IntegrationObjectID = @IntegrationObjectID_8adcaf33,
  @Name = @Name_8adcaf33,
  @DisplayName = @DisplayName_8adcaf33,
  @Description = @Description_8adcaf33,
  @Category = @Category_8adcaf33,
  @Category_Clear = 1,
  @Type = @Type_8adcaf33,
  @Length = @Length_8adcaf33,
  @Precision = @Precision_8adcaf33,
  @Precision_Clear = 1,
  @Scale = @Scale_8adcaf33,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_8adcaf33,
  @DefaultValue = @DefaultValue_8adcaf33,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_8adcaf33,
  @IsUniqueKey = @IsUniqueKey_8adcaf33,
  @IsReadOnly = @IsReadOnly_8adcaf33,
  @IsRequired = @IsRequired_8adcaf33,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_8adcaf33,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_8adcaf33,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_8adcaf33,
  @Configuration = @Configuration_8adcaf33,
  @Configuration_Clear = 1,
  @Status = @Status_8adcaf33,
  @IsCustom = @IsCustom_8adcaf33,
  @MetadataSource = @MetadataSource_8adcaf33;

GO
