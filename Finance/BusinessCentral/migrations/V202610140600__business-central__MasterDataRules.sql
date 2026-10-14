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

UPDATE [__mj].IntegrationObject
SET Configuration = REPLACE(Configuration, N'"resourceType": "account",', N'"recordFilter": {"field": "accountType", "in": ["Posting"]}, "resourceType": "account",')
WHERE ID = '341328C6-098D-400D-B6E4-A7FDE73676D6';

UPDATE [__mj].IntegrationObject
SET Configuration = REPLACE(Configuration, N'"resourceType": "dimensionValue",', N'"parentCode": {"object": "dimensions", "idField": "dimensionId", "codeField": "code", "as": "dimensionCode"}, "resourceType": "dimensionValue",')
WHERE ID = 'DE0BF041-9003-4BDC-854B-941AC9F427CA';

DECLARE @ID_mdr1 UNIQUEIDENTIFIER,
@IntegrationObjectID_mdr1 UNIQUEIDENTIFIER,
@Name_mdr1 NVARCHAR(255),
@DisplayName_mdr1 NVARCHAR(255),
@Description_mdr1 NVARCHAR(MAX),
@Category_mdr1 NVARCHAR(100),
@Type_mdr1 NVARCHAR(100),
@Length_mdr1 INT,
@Precision_mdr1 INT,
@Scale_mdr1 INT,
@AllowsNull_mdr1 BIT,
@DefaultValue_mdr1 NVARCHAR(255),
@IsPrimaryKey_mdr1 BIT,
@IsUniqueKey_mdr1 BIT,
@IsReadOnly_mdr1 BIT,
@IsRequired_mdr1 BIT,
@RelatedIntegrationObjectID_mdr1 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_mdr1 NVARCHAR(255),
@Sequence_mdr1 INT,
@Configuration_mdr1 NVARCHAR(MAX),
@Status_mdr1 NVARCHAR(25),
@IsCustom_mdr1 BIT,
@MetadataSource_mdr1 NVARCHAR(20)
SET
  @ID_mdr1 = '14AF8F23-4512-483C-A23B-E562236028C4'
SET
  @IntegrationObjectID_mdr1 = 'DE0BF041-9003-4BDC-854B-941AC9F427CA'
SET
  @Name_mdr1 = N'dimensionCode'
SET
  @DisplayName_mdr1 = N'Dimension Code'
SET
  @Description_mdr1 = N'The parent dimension''s code, added by the connector from dimensionId (Configuration.parentCode). Business Central dimension IDs are per company; the code is what a shared Dimension matches on.'
SET
  @Type_mdr1 = N'string'
SET
  @Length_mdr1 = 20
SET
  @AllowsNull_mdr1 = 1
SET
  @IsPrimaryKey_mdr1 = 0
SET
  @IsUniqueKey_mdr1 = 0
SET
  @IsReadOnly_mdr1 = 1
SET
  @IsRequired_mdr1 = 0
SET
  @Sequence_mdr1 = 7
SET
  @Configuration_mdr1 = N'{"edmType":"string","derived":"connector parentCode (dimensions.code via dimensionId)"}'
SET
  @Status_mdr1 = N'Active'
SET
  @IsCustom_mdr1 = 0
SET
  @MetadataSource_mdr1 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_mdr1,
  @IntegrationObjectID = @IntegrationObjectID_mdr1,
  @Name = @Name_mdr1,
  @DisplayName = @DisplayName_mdr1,
  @Description = @Description_mdr1,
  @Category = @Category_mdr1,
  @Category_Clear = 1,
  @Type = @Type_mdr1,
  @Length = @Length_mdr1,
  @Length_Clear = 1,
  @Precision = @Precision_mdr1,
  @Precision_Clear = 1,
  @Scale = @Scale_mdr1,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_mdr1,
  @DefaultValue = @DefaultValue_mdr1,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_mdr1,
  @IsUniqueKey = @IsUniqueKey_mdr1,
  @IsReadOnly = @IsReadOnly_mdr1,
  @IsRequired = @IsRequired_mdr1,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_mdr1,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_mdr1,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_mdr1,
  @Configuration = @Configuration_mdr1,
  @Status = @Status_mdr1,
  @IsCustom = @IsCustom_mdr1,
  @MetadataSource = @MetadataSource_mdr1;
