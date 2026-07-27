-- HubSpot: correct the primary key to `hs_object_id` on 33 CRM objects (was `id`).
--
-- The static catalog declared `id` as the PK, but the connector's DiscoverFields declares — and the
-- sync path populates — `hs_object_id` (read out of the properties bag). The top-level `id` column is
-- never written. With `id` as the PK the generated spCreate ends with a read-back
--     SELECT ... WHERE [id] = @id
-- and `@id` is NULL. In SQL `x = NULL` is never true, so the read-back matched ZERO rows, the create
-- was treated as failed ("Error creating new record, no rows returned from SQL"), and the object
-- synced 0 rows — silently, with no meaningful error surfaced.
--
-- This is a DELTA migration, deliberately NOT a re-seed. The V202607092028 seed stays untouched and
-- applied: no existing UUID is re-minted, no applied migration is deleted, so there is no Flyway
-- checksum break and no UQ_IntegrationObject_Name collision on tenants already running HubSpot.
--
-- It does two things per object:
--   1. CREATE the `hs_object_id` catalog field (it does not exist on installed tenants) — guarded by
--      NOT EXISTS, so re-application is a no-op.
--   2. Clear IsPrimaryKey on the object's `id` field.
--
-- The new field IDs are UUID5-derived from a fixed namespace, so this file is reproducible:
-- regenerating it yields byte-identical UUIDs rather than fresh random ones.

-- ── appointments ──────────────────────────────────────────────────────────────
DECLARE @ID_9ffcda32 UNIQUEIDENTIFIER,
@IntegrationObjectID_9ffcda32 UNIQUEIDENTIFIER,
@Name_9ffcda32 NVARCHAR(255),
@DisplayName_9ffcda32 NVARCHAR(255),
@Description_9ffcda32 NVARCHAR(MAX),
@Category_9ffcda32 NVARCHAR(100),
@Type_9ffcda32 NVARCHAR(100),
@Length_9ffcda32 INT,
@Precision_9ffcda32 INT,
@Scale_9ffcda32 INT,
@AllowsNull_9ffcda32 BIT,
@DefaultValue_9ffcda32 NVARCHAR(255),
@IsPrimaryKey_9ffcda32 BIT,
@IsUniqueKey_9ffcda32 BIT,
@IsReadOnly_9ffcda32 BIT,
@IsRequired_9ffcda32 BIT,
@RelatedIntegrationObjectID_9ffcda32 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_9ffcda32 NVARCHAR(255),
@Sequence_9ffcda32 INT,
@Configuration_9ffcda32 NVARCHAR(MAX),
@Status_9ffcda32 NVARCHAR(25),
@IsCustom_9ffcda32 BIT,
@MetadataSource_9ffcda32 NVARCHAR(20)
SET
  @ID_9ffcda32 = '9FFCDA32-B51A-5AE8-9B9F-681987C33703'
SET
  @IntegrationObjectID_9ffcda32 = '8E0BC677-A3CA-4D46-B5AD-5FB561F4EAB6'
SET
  @Name_9ffcda32 = N'hs_object_id'
SET
  @Description_9ffcda32 = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_9ffcda32 = N'string'
SET
  @AllowsNull_9ffcda32 = 0
SET
  @IsPrimaryKey_9ffcda32 = 1
SET
  @IsUniqueKey_9ffcda32 = 1
SET
  @IsReadOnly_9ffcda32 = 1
SET
  @IsRequired_9ffcda32 = 0
SET
  @Sequence_9ffcda32 = 0
SET
  @Status_9ffcda32 = N'Active'
SET
  @IsCustom_9ffcda32 = 0
SET
  @MetadataSource_9ffcda32 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_9ffcda32,
  @IntegrationObjectID = @IntegrationObjectID_9ffcda32,
  @Name = @Name_9ffcda32,
  @DisplayName = @DisplayName_9ffcda32,
  @DisplayName_Clear = 1,
  @Description = @Description_9ffcda32,
  @Category = @Category_9ffcda32,
  @Category_Clear = 1,
  @Type = @Type_9ffcda32,
  @Length = @Length_9ffcda32,
  @Length_Clear = 1,
  @Precision = @Precision_9ffcda32,
  @Precision_Clear = 1,
  @Scale = @Scale_9ffcda32,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_9ffcda32,
  @DefaultValue = @DefaultValue_9ffcda32,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_9ffcda32,
  @IsUniqueKey = @IsUniqueKey_9ffcda32,
  @IsReadOnly = @IsReadOnly_9ffcda32,
  @IsRequired = @IsRequired_9ffcda32,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_9ffcda32,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_9ffcda32,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_9ffcda32,
  @Configuration = @Configuration_9ffcda32,
  @Configuration_Clear = 1,
  @Status = @Status_9ffcda32,
  @IsCustom = @IsCustom_9ffcda32,
  @MetadataSource = @MetadataSource_9ffcda32;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = '8E0BC677-A3CA-4D46-B5AD-5FB561F4EAB6' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── calls ──────────────────────────────────────────────────────────────
DECLARE @ID_97a79994 UNIQUEIDENTIFIER,
@IntegrationObjectID_97a79994 UNIQUEIDENTIFIER,
@Name_97a79994 NVARCHAR(255),
@DisplayName_97a79994 NVARCHAR(255),
@Description_97a79994 NVARCHAR(MAX),
@Category_97a79994 NVARCHAR(100),
@Type_97a79994 NVARCHAR(100),
@Length_97a79994 INT,
@Precision_97a79994 INT,
@Scale_97a79994 INT,
@AllowsNull_97a79994 BIT,
@DefaultValue_97a79994 NVARCHAR(255),
@IsPrimaryKey_97a79994 BIT,
@IsUniqueKey_97a79994 BIT,
@IsReadOnly_97a79994 BIT,
@IsRequired_97a79994 BIT,
@RelatedIntegrationObjectID_97a79994 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_97a79994 NVARCHAR(255),
@Sequence_97a79994 INT,
@Configuration_97a79994 NVARCHAR(MAX),
@Status_97a79994 NVARCHAR(25),
@IsCustom_97a79994 BIT,
@MetadataSource_97a79994 NVARCHAR(20)
SET
  @ID_97a79994 = '97A79994-6780-519A-A622-7FB2687C132F'
SET
  @IntegrationObjectID_97a79994 = '197AE7F2-4DFC-4F8F-91EA-E6D72B2BD535'
SET
  @Name_97a79994 = N'hs_object_id'
SET
  @Description_97a79994 = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_97a79994 = N'string'
SET
  @AllowsNull_97a79994 = 0
SET
  @IsPrimaryKey_97a79994 = 1
SET
  @IsUniqueKey_97a79994 = 1
SET
  @IsReadOnly_97a79994 = 1
SET
  @IsRequired_97a79994 = 0
SET
  @Sequence_97a79994 = 0
SET
  @Status_97a79994 = N'Active'
SET
  @IsCustom_97a79994 = 0
SET
  @MetadataSource_97a79994 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_97a79994,
  @IntegrationObjectID = @IntegrationObjectID_97a79994,
  @Name = @Name_97a79994,
  @DisplayName = @DisplayName_97a79994,
  @DisplayName_Clear = 1,
  @Description = @Description_97a79994,
  @Category = @Category_97a79994,
  @Category_Clear = 1,
  @Type = @Type_97a79994,
  @Length = @Length_97a79994,
  @Length_Clear = 1,
  @Precision = @Precision_97a79994,
  @Precision_Clear = 1,
  @Scale = @Scale_97a79994,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_97a79994,
  @DefaultValue = @DefaultValue_97a79994,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_97a79994,
  @IsUniqueKey = @IsUniqueKey_97a79994,
  @IsReadOnly = @IsReadOnly_97a79994,
  @IsRequired = @IsRequired_97a79994,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_97a79994,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_97a79994,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_97a79994,
  @Configuration = @Configuration_97a79994,
  @Configuration_Clear = 1,
  @Status = @Status_97a79994,
  @IsCustom = @IsCustom_97a79994,
  @MetadataSource = @MetadataSource_97a79994;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = '197AE7F2-4DFC-4F8F-91EA-E6D72B2BD535' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── carts ──────────────────────────────────────────────────────────────
DECLARE @ID_f6bf0361 UNIQUEIDENTIFIER,
@IntegrationObjectID_f6bf0361 UNIQUEIDENTIFIER,
@Name_f6bf0361 NVARCHAR(255),
@DisplayName_f6bf0361 NVARCHAR(255),
@Description_f6bf0361 NVARCHAR(MAX),
@Category_f6bf0361 NVARCHAR(100),
@Type_f6bf0361 NVARCHAR(100),
@Length_f6bf0361 INT,
@Precision_f6bf0361 INT,
@Scale_f6bf0361 INT,
@AllowsNull_f6bf0361 BIT,
@DefaultValue_f6bf0361 NVARCHAR(255),
@IsPrimaryKey_f6bf0361 BIT,
@IsUniqueKey_f6bf0361 BIT,
@IsReadOnly_f6bf0361 BIT,
@IsRequired_f6bf0361 BIT,
@RelatedIntegrationObjectID_f6bf0361 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_f6bf0361 NVARCHAR(255),
@Sequence_f6bf0361 INT,
@Configuration_f6bf0361 NVARCHAR(MAX),
@Status_f6bf0361 NVARCHAR(25),
@IsCustom_f6bf0361 BIT,
@MetadataSource_f6bf0361 NVARCHAR(20)
SET
  @ID_f6bf0361 = 'F6BF0361-7376-5C2A-A923-D0F96081534A'
SET
  @IntegrationObjectID_f6bf0361 = '393074F2-5F47-42EF-9148-E60C0302995D'
SET
  @Name_f6bf0361 = N'hs_object_id'
SET
  @Description_f6bf0361 = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_f6bf0361 = N'string'
SET
  @AllowsNull_f6bf0361 = 0
SET
  @IsPrimaryKey_f6bf0361 = 1
SET
  @IsUniqueKey_f6bf0361 = 1
SET
  @IsReadOnly_f6bf0361 = 1
SET
  @IsRequired_f6bf0361 = 0
SET
  @Sequence_f6bf0361 = 0
SET
  @Status_f6bf0361 = N'Active'
SET
  @IsCustom_f6bf0361 = 0
SET
  @MetadataSource_f6bf0361 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_f6bf0361,
  @IntegrationObjectID = @IntegrationObjectID_f6bf0361,
  @Name = @Name_f6bf0361,
  @DisplayName = @DisplayName_f6bf0361,
  @DisplayName_Clear = 1,
  @Description = @Description_f6bf0361,
  @Category = @Category_f6bf0361,
  @Category_Clear = 1,
  @Type = @Type_f6bf0361,
  @Length = @Length_f6bf0361,
  @Length_Clear = 1,
  @Precision = @Precision_f6bf0361,
  @Precision_Clear = 1,
  @Scale = @Scale_f6bf0361,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_f6bf0361,
  @DefaultValue = @DefaultValue_f6bf0361,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_f6bf0361,
  @IsUniqueKey = @IsUniqueKey_f6bf0361,
  @IsReadOnly = @IsReadOnly_f6bf0361,
  @IsRequired = @IsRequired_f6bf0361,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_f6bf0361,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_f6bf0361,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_f6bf0361,
  @Configuration = @Configuration_f6bf0361,
  @Configuration_Clear = 1,
  @Status = @Status_f6bf0361,
  @IsCustom = @IsCustom_f6bf0361,
  @MetadataSource = @MetadataSource_f6bf0361;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = '393074F2-5F47-42EF-9148-E60C0302995D' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── commerce_payments ──────────────────────────────────────────────────────────────
DECLARE @ID_09f97be0 UNIQUEIDENTIFIER,
@IntegrationObjectID_09f97be0 UNIQUEIDENTIFIER,
@Name_09f97be0 NVARCHAR(255),
@DisplayName_09f97be0 NVARCHAR(255),
@Description_09f97be0 NVARCHAR(MAX),
@Category_09f97be0 NVARCHAR(100),
@Type_09f97be0 NVARCHAR(100),
@Length_09f97be0 INT,
@Precision_09f97be0 INT,
@Scale_09f97be0 INT,
@AllowsNull_09f97be0 BIT,
@DefaultValue_09f97be0 NVARCHAR(255),
@IsPrimaryKey_09f97be0 BIT,
@IsUniqueKey_09f97be0 BIT,
@IsReadOnly_09f97be0 BIT,
@IsRequired_09f97be0 BIT,
@RelatedIntegrationObjectID_09f97be0 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_09f97be0 NVARCHAR(255),
@Sequence_09f97be0 INT,
@Configuration_09f97be0 NVARCHAR(MAX),
@Status_09f97be0 NVARCHAR(25),
@IsCustom_09f97be0 BIT,
@MetadataSource_09f97be0 NVARCHAR(20)
SET
  @ID_09f97be0 = '09F97BE0-507D-5F38-83AC-5B9719C74898'
SET
  @IntegrationObjectID_09f97be0 = '564C02F4-321B-4FF0-966A-F8A270D88664'
SET
  @Name_09f97be0 = N'hs_object_id'
SET
  @Description_09f97be0 = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_09f97be0 = N'string'
SET
  @AllowsNull_09f97be0 = 0
SET
  @IsPrimaryKey_09f97be0 = 1
SET
  @IsUniqueKey_09f97be0 = 1
SET
  @IsReadOnly_09f97be0 = 1
SET
  @IsRequired_09f97be0 = 0
SET
  @Sequence_09f97be0 = 0
SET
  @Status_09f97be0 = N'Active'
SET
  @IsCustom_09f97be0 = 0
SET
  @MetadataSource_09f97be0 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_09f97be0,
  @IntegrationObjectID = @IntegrationObjectID_09f97be0,
  @Name = @Name_09f97be0,
  @DisplayName = @DisplayName_09f97be0,
  @DisplayName_Clear = 1,
  @Description = @Description_09f97be0,
  @Category = @Category_09f97be0,
  @Category_Clear = 1,
  @Type = @Type_09f97be0,
  @Length = @Length_09f97be0,
  @Length_Clear = 1,
  @Precision = @Precision_09f97be0,
  @Precision_Clear = 1,
  @Scale = @Scale_09f97be0,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_09f97be0,
  @DefaultValue = @DefaultValue_09f97be0,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_09f97be0,
  @IsUniqueKey = @IsUniqueKey_09f97be0,
  @IsReadOnly = @IsReadOnly_09f97be0,
  @IsRequired = @IsRequired_09f97be0,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_09f97be0,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_09f97be0,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_09f97be0,
  @Configuration = @Configuration_09f97be0,
  @Configuration_Clear = 1,
  @Status = @Status_09f97be0,
  @IsCustom = @IsCustom_09f97be0,
  @MetadataSource = @MetadataSource_09f97be0;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = '564C02F4-321B-4FF0-966A-F8A270D88664' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── communications ──────────────────────────────────────────────────────────────
DECLARE @ID_1f8a168a UNIQUEIDENTIFIER,
@IntegrationObjectID_1f8a168a UNIQUEIDENTIFIER,
@Name_1f8a168a NVARCHAR(255),
@DisplayName_1f8a168a NVARCHAR(255),
@Description_1f8a168a NVARCHAR(MAX),
@Category_1f8a168a NVARCHAR(100),
@Type_1f8a168a NVARCHAR(100),
@Length_1f8a168a INT,
@Precision_1f8a168a INT,
@Scale_1f8a168a INT,
@AllowsNull_1f8a168a BIT,
@DefaultValue_1f8a168a NVARCHAR(255),
@IsPrimaryKey_1f8a168a BIT,
@IsUniqueKey_1f8a168a BIT,
@IsReadOnly_1f8a168a BIT,
@IsRequired_1f8a168a BIT,
@RelatedIntegrationObjectID_1f8a168a UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_1f8a168a NVARCHAR(255),
@Sequence_1f8a168a INT,
@Configuration_1f8a168a NVARCHAR(MAX),
@Status_1f8a168a NVARCHAR(25),
@IsCustom_1f8a168a BIT,
@MetadataSource_1f8a168a NVARCHAR(20)
SET
  @ID_1f8a168a = '1F8A168A-C857-5DEA-8B26-CB626EC87E4F'
SET
  @IntegrationObjectID_1f8a168a = 'AE2E1687-9FB2-4A5C-8F15-3435AE3A06D2'
SET
  @Name_1f8a168a = N'hs_object_id'
SET
  @Description_1f8a168a = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_1f8a168a = N'string'
SET
  @AllowsNull_1f8a168a = 0
SET
  @IsPrimaryKey_1f8a168a = 1
SET
  @IsUniqueKey_1f8a168a = 1
SET
  @IsReadOnly_1f8a168a = 1
SET
  @IsRequired_1f8a168a = 0
SET
  @Sequence_1f8a168a = 0
SET
  @Status_1f8a168a = N'Active'
SET
  @IsCustom_1f8a168a = 0
SET
  @MetadataSource_1f8a168a = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_1f8a168a,
  @IntegrationObjectID = @IntegrationObjectID_1f8a168a,
  @Name = @Name_1f8a168a,
  @DisplayName = @DisplayName_1f8a168a,
  @DisplayName_Clear = 1,
  @Description = @Description_1f8a168a,
  @Category = @Category_1f8a168a,
  @Category_Clear = 1,
  @Type = @Type_1f8a168a,
  @Length = @Length_1f8a168a,
  @Length_Clear = 1,
  @Precision = @Precision_1f8a168a,
  @Precision_Clear = 1,
  @Scale = @Scale_1f8a168a,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_1f8a168a,
  @DefaultValue = @DefaultValue_1f8a168a,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_1f8a168a,
  @IsUniqueKey = @IsUniqueKey_1f8a168a,
  @IsReadOnly = @IsReadOnly_1f8a168a,
  @IsRequired = @IsRequired_1f8a168a,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_1f8a168a,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_1f8a168a,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_1f8a168a,
  @Configuration = @Configuration_1f8a168a,
  @Configuration_Clear = 1,
  @Status = @Status_1f8a168a,
  @IsCustom = @IsCustom_1f8a168a,
  @MetadataSource = @MetadataSource_1f8a168a;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = 'AE2E1687-9FB2-4A5C-8F15-3435AE3A06D2' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── companies ──────────────────────────────────────────────────────────────
DECLARE @ID_f82d05b6 UNIQUEIDENTIFIER,
@IntegrationObjectID_f82d05b6 UNIQUEIDENTIFIER,
@Name_f82d05b6 NVARCHAR(255),
@DisplayName_f82d05b6 NVARCHAR(255),
@Description_f82d05b6 NVARCHAR(MAX),
@Category_f82d05b6 NVARCHAR(100),
@Type_f82d05b6 NVARCHAR(100),
@Length_f82d05b6 INT,
@Precision_f82d05b6 INT,
@Scale_f82d05b6 INT,
@AllowsNull_f82d05b6 BIT,
@DefaultValue_f82d05b6 NVARCHAR(255),
@IsPrimaryKey_f82d05b6 BIT,
@IsUniqueKey_f82d05b6 BIT,
@IsReadOnly_f82d05b6 BIT,
@IsRequired_f82d05b6 BIT,
@RelatedIntegrationObjectID_f82d05b6 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_f82d05b6 NVARCHAR(255),
@Sequence_f82d05b6 INT,
@Configuration_f82d05b6 NVARCHAR(MAX),
@Status_f82d05b6 NVARCHAR(25),
@IsCustom_f82d05b6 BIT,
@MetadataSource_f82d05b6 NVARCHAR(20)
SET
  @ID_f82d05b6 = 'F82D05B6-9433-545F-931A-3EB9080C3A82'
SET
  @IntegrationObjectID_f82d05b6 = '27E3A334-0926-4D0E-B0B2-CD4F66289A2B'
SET
  @Name_f82d05b6 = N'hs_object_id'
SET
  @Description_f82d05b6 = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_f82d05b6 = N'string'
SET
  @AllowsNull_f82d05b6 = 0
SET
  @IsPrimaryKey_f82d05b6 = 1
SET
  @IsUniqueKey_f82d05b6 = 1
SET
  @IsReadOnly_f82d05b6 = 1
SET
  @IsRequired_f82d05b6 = 0
SET
  @Sequence_f82d05b6 = 0
SET
  @Status_f82d05b6 = N'Active'
SET
  @IsCustom_f82d05b6 = 0
SET
  @MetadataSource_f82d05b6 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_f82d05b6,
  @IntegrationObjectID = @IntegrationObjectID_f82d05b6,
  @Name = @Name_f82d05b6,
  @DisplayName = @DisplayName_f82d05b6,
  @DisplayName_Clear = 1,
  @Description = @Description_f82d05b6,
  @Category = @Category_f82d05b6,
  @Category_Clear = 1,
  @Type = @Type_f82d05b6,
  @Length = @Length_f82d05b6,
  @Length_Clear = 1,
  @Precision = @Precision_f82d05b6,
  @Precision_Clear = 1,
  @Scale = @Scale_f82d05b6,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_f82d05b6,
  @DefaultValue = @DefaultValue_f82d05b6,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_f82d05b6,
  @IsUniqueKey = @IsUniqueKey_f82d05b6,
  @IsReadOnly = @IsReadOnly_f82d05b6,
  @IsRequired = @IsRequired_f82d05b6,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_f82d05b6,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_f82d05b6,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_f82d05b6,
  @Configuration = @Configuration_f82d05b6,
  @Configuration_Clear = 1,
  @Status = @Status_f82d05b6,
  @IsCustom = @IsCustom_f82d05b6,
  @MetadataSource = @MetadataSource_f82d05b6;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = '27E3A334-0926-4D0E-B0B2-CD4F66289A2B' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── contacts ──────────────────────────────────────────────────────────────
DECLARE @ID_5de65e9c UNIQUEIDENTIFIER,
@IntegrationObjectID_5de65e9c UNIQUEIDENTIFIER,
@Name_5de65e9c NVARCHAR(255),
@DisplayName_5de65e9c NVARCHAR(255),
@Description_5de65e9c NVARCHAR(MAX),
@Category_5de65e9c NVARCHAR(100),
@Type_5de65e9c NVARCHAR(100),
@Length_5de65e9c INT,
@Precision_5de65e9c INT,
@Scale_5de65e9c INT,
@AllowsNull_5de65e9c BIT,
@DefaultValue_5de65e9c NVARCHAR(255),
@IsPrimaryKey_5de65e9c BIT,
@IsUniqueKey_5de65e9c BIT,
@IsReadOnly_5de65e9c BIT,
@IsRequired_5de65e9c BIT,
@RelatedIntegrationObjectID_5de65e9c UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_5de65e9c NVARCHAR(255),
@Sequence_5de65e9c INT,
@Configuration_5de65e9c NVARCHAR(MAX),
@Status_5de65e9c NVARCHAR(25),
@IsCustom_5de65e9c BIT,
@MetadataSource_5de65e9c NVARCHAR(20)
SET
  @ID_5de65e9c = '5DE65E9C-C135-5692-A945-7BFC85471808'
SET
  @IntegrationObjectID_5de65e9c = 'C4FD9983-11FA-47AA-B42D-A6509640B98C'
SET
  @Name_5de65e9c = N'hs_object_id'
SET
  @Description_5de65e9c = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_5de65e9c = N'string'
SET
  @AllowsNull_5de65e9c = 0
SET
  @IsPrimaryKey_5de65e9c = 1
SET
  @IsUniqueKey_5de65e9c = 1
SET
  @IsReadOnly_5de65e9c = 1
SET
  @IsRequired_5de65e9c = 0
SET
  @Sequence_5de65e9c = 0
SET
  @Status_5de65e9c = N'Active'
SET
  @IsCustom_5de65e9c = 0
SET
  @MetadataSource_5de65e9c = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_5de65e9c,
  @IntegrationObjectID = @IntegrationObjectID_5de65e9c,
  @Name = @Name_5de65e9c,
  @DisplayName = @DisplayName_5de65e9c,
  @DisplayName_Clear = 1,
  @Description = @Description_5de65e9c,
  @Category = @Category_5de65e9c,
  @Category_Clear = 1,
  @Type = @Type_5de65e9c,
  @Length = @Length_5de65e9c,
  @Length_Clear = 1,
  @Precision = @Precision_5de65e9c,
  @Precision_Clear = 1,
  @Scale = @Scale_5de65e9c,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_5de65e9c,
  @DefaultValue = @DefaultValue_5de65e9c,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_5de65e9c,
  @IsUniqueKey = @IsUniqueKey_5de65e9c,
  @IsReadOnly = @IsReadOnly_5de65e9c,
  @IsRequired = @IsRequired_5de65e9c,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_5de65e9c,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_5de65e9c,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_5de65e9c,
  @Configuration = @Configuration_5de65e9c,
  @Configuration_Clear = 1,
  @Status = @Status_5de65e9c,
  @IsCustom = @IsCustom_5de65e9c,
  @MetadataSource = @MetadataSource_5de65e9c;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = 'C4FD9983-11FA-47AA-B42D-A6509640B98C' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── contracts ──────────────────────────────────────────────────────────────
DECLARE @ID_2a68c3f1 UNIQUEIDENTIFIER,
@IntegrationObjectID_2a68c3f1 UNIQUEIDENTIFIER,
@Name_2a68c3f1 NVARCHAR(255),
@DisplayName_2a68c3f1 NVARCHAR(255),
@Description_2a68c3f1 NVARCHAR(MAX),
@Category_2a68c3f1 NVARCHAR(100),
@Type_2a68c3f1 NVARCHAR(100),
@Length_2a68c3f1 INT,
@Precision_2a68c3f1 INT,
@Scale_2a68c3f1 INT,
@AllowsNull_2a68c3f1 BIT,
@DefaultValue_2a68c3f1 NVARCHAR(255),
@IsPrimaryKey_2a68c3f1 BIT,
@IsUniqueKey_2a68c3f1 BIT,
@IsReadOnly_2a68c3f1 BIT,
@IsRequired_2a68c3f1 BIT,
@RelatedIntegrationObjectID_2a68c3f1 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_2a68c3f1 NVARCHAR(255),
@Sequence_2a68c3f1 INT,
@Configuration_2a68c3f1 NVARCHAR(MAX),
@Status_2a68c3f1 NVARCHAR(25),
@IsCustom_2a68c3f1 BIT,
@MetadataSource_2a68c3f1 NVARCHAR(20)
SET
  @ID_2a68c3f1 = '2A68C3F1-2B76-5EF8-8176-9D88599719E5'
SET
  @IntegrationObjectID_2a68c3f1 = '6F19B7DB-D08A-4760-B231-5EB00EB68305'
SET
  @Name_2a68c3f1 = N'hs_object_id'
SET
  @Description_2a68c3f1 = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_2a68c3f1 = N'string'
SET
  @AllowsNull_2a68c3f1 = 0
SET
  @IsPrimaryKey_2a68c3f1 = 1
SET
  @IsUniqueKey_2a68c3f1 = 1
SET
  @IsReadOnly_2a68c3f1 = 1
SET
  @IsRequired_2a68c3f1 = 0
SET
  @Sequence_2a68c3f1 = 0
SET
  @Status_2a68c3f1 = N'Active'
SET
  @IsCustom_2a68c3f1 = 0
SET
  @MetadataSource_2a68c3f1 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_2a68c3f1,
  @IntegrationObjectID = @IntegrationObjectID_2a68c3f1,
  @Name = @Name_2a68c3f1,
  @DisplayName = @DisplayName_2a68c3f1,
  @DisplayName_Clear = 1,
  @Description = @Description_2a68c3f1,
  @Category = @Category_2a68c3f1,
  @Category_Clear = 1,
  @Type = @Type_2a68c3f1,
  @Length = @Length_2a68c3f1,
  @Length_Clear = 1,
  @Precision = @Precision_2a68c3f1,
  @Precision_Clear = 1,
  @Scale = @Scale_2a68c3f1,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_2a68c3f1,
  @DefaultValue = @DefaultValue_2a68c3f1,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_2a68c3f1,
  @IsUniqueKey = @IsUniqueKey_2a68c3f1,
  @IsReadOnly = @IsReadOnly_2a68c3f1,
  @IsRequired = @IsRequired_2a68c3f1,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_2a68c3f1,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_2a68c3f1,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_2a68c3f1,
  @Configuration = @Configuration_2a68c3f1,
  @Configuration_Clear = 1,
  @Status = @Status_2a68c3f1,
  @IsCustom = @IsCustom_2a68c3f1,
  @MetadataSource = @MetadataSource_2a68c3f1;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = '6F19B7DB-D08A-4760-B231-5EB00EB68305' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── courses ──────────────────────────────────────────────────────────────
DECLARE @ID_14df8def UNIQUEIDENTIFIER,
@IntegrationObjectID_14df8def UNIQUEIDENTIFIER,
@Name_14df8def NVARCHAR(255),
@DisplayName_14df8def NVARCHAR(255),
@Description_14df8def NVARCHAR(MAX),
@Category_14df8def NVARCHAR(100),
@Type_14df8def NVARCHAR(100),
@Length_14df8def INT,
@Precision_14df8def INT,
@Scale_14df8def INT,
@AllowsNull_14df8def BIT,
@DefaultValue_14df8def NVARCHAR(255),
@IsPrimaryKey_14df8def BIT,
@IsUniqueKey_14df8def BIT,
@IsReadOnly_14df8def BIT,
@IsRequired_14df8def BIT,
@RelatedIntegrationObjectID_14df8def UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_14df8def NVARCHAR(255),
@Sequence_14df8def INT,
@Configuration_14df8def NVARCHAR(MAX),
@Status_14df8def NVARCHAR(25),
@IsCustom_14df8def BIT,
@MetadataSource_14df8def NVARCHAR(20)
SET
  @ID_14df8def = '14DF8DEF-A186-557C-BEA0-BCB193A4FBA9'
SET
  @IntegrationObjectID_14df8def = '9533CB43-4B30-4D61-899A-CB3CBFF5068A'
SET
  @Name_14df8def = N'hs_object_id'
SET
  @Description_14df8def = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_14df8def = N'string'
SET
  @AllowsNull_14df8def = 0
SET
  @IsPrimaryKey_14df8def = 1
SET
  @IsUniqueKey_14df8def = 1
SET
  @IsReadOnly_14df8def = 1
SET
  @IsRequired_14df8def = 0
SET
  @Sequence_14df8def = 0
SET
  @Status_14df8def = N'Active'
SET
  @IsCustom_14df8def = 0
SET
  @MetadataSource_14df8def = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_14df8def,
  @IntegrationObjectID = @IntegrationObjectID_14df8def,
  @Name = @Name_14df8def,
  @DisplayName = @DisplayName_14df8def,
  @DisplayName_Clear = 1,
  @Description = @Description_14df8def,
  @Category = @Category_14df8def,
  @Category_Clear = 1,
  @Type = @Type_14df8def,
  @Length = @Length_14df8def,
  @Length_Clear = 1,
  @Precision = @Precision_14df8def,
  @Precision_Clear = 1,
  @Scale = @Scale_14df8def,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_14df8def,
  @DefaultValue = @DefaultValue_14df8def,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_14df8def,
  @IsUniqueKey = @IsUniqueKey_14df8def,
  @IsReadOnly = @IsReadOnly_14df8def,
  @IsRequired = @IsRequired_14df8def,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_14df8def,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_14df8def,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_14df8def,
  @Configuration = @Configuration_14df8def,
  @Configuration_Clear = 1,
  @Status = @Status_14df8def,
  @IsCustom = @IsCustom_14df8def,
  @MetadataSource = @MetadataSource_14df8def;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = '9533CB43-4B30-4D61-899A-CB3CBFF5068A' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── deal_splits ──────────────────────────────────────────────────────────────
DECLARE @ID_caeca571 UNIQUEIDENTIFIER,
@IntegrationObjectID_caeca571 UNIQUEIDENTIFIER,
@Name_caeca571 NVARCHAR(255),
@DisplayName_caeca571 NVARCHAR(255),
@Description_caeca571 NVARCHAR(MAX),
@Category_caeca571 NVARCHAR(100),
@Type_caeca571 NVARCHAR(100),
@Length_caeca571 INT,
@Precision_caeca571 INT,
@Scale_caeca571 INT,
@AllowsNull_caeca571 BIT,
@DefaultValue_caeca571 NVARCHAR(255),
@IsPrimaryKey_caeca571 BIT,
@IsUniqueKey_caeca571 BIT,
@IsReadOnly_caeca571 BIT,
@IsRequired_caeca571 BIT,
@RelatedIntegrationObjectID_caeca571 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_caeca571 NVARCHAR(255),
@Sequence_caeca571 INT,
@Configuration_caeca571 NVARCHAR(MAX),
@Status_caeca571 NVARCHAR(25),
@IsCustom_caeca571 BIT,
@MetadataSource_caeca571 NVARCHAR(20)
SET
  @ID_caeca571 = 'CAECA571-50B0-50D6-BFC5-90986DC8671E'
SET
  @IntegrationObjectID_caeca571 = 'AEBB321F-84A1-4D11-8FCB-2BA63E0B975E'
SET
  @Name_caeca571 = N'hs_object_id'
SET
  @Description_caeca571 = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_caeca571 = N'string'
SET
  @AllowsNull_caeca571 = 0
SET
  @IsPrimaryKey_caeca571 = 1
SET
  @IsUniqueKey_caeca571 = 1
SET
  @IsReadOnly_caeca571 = 1
SET
  @IsRequired_caeca571 = 0
SET
  @Sequence_caeca571 = 0
SET
  @Status_caeca571 = N'Active'
SET
  @IsCustom_caeca571 = 0
SET
  @MetadataSource_caeca571 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_caeca571,
  @IntegrationObjectID = @IntegrationObjectID_caeca571,
  @Name = @Name_caeca571,
  @DisplayName = @DisplayName_caeca571,
  @DisplayName_Clear = 1,
  @Description = @Description_caeca571,
  @Category = @Category_caeca571,
  @Category_Clear = 1,
  @Type = @Type_caeca571,
  @Length = @Length_caeca571,
  @Length_Clear = 1,
  @Precision = @Precision_caeca571,
  @Precision_Clear = 1,
  @Scale = @Scale_caeca571,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_caeca571,
  @DefaultValue = @DefaultValue_caeca571,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_caeca571,
  @IsUniqueKey = @IsUniqueKey_caeca571,
  @IsReadOnly = @IsReadOnly_caeca571,
  @IsRequired = @IsRequired_caeca571,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_caeca571,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_caeca571,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_caeca571,
  @Configuration = @Configuration_caeca571,
  @Configuration_Clear = 1,
  @Status = @Status_caeca571,
  @IsCustom = @IsCustom_caeca571,
  @MetadataSource = @MetadataSource_caeca571;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = 'AEBB321F-84A1-4D11-8FCB-2BA63E0B975E' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── deals ──────────────────────────────────────────────────────────────
DECLARE @ID_665f0cd0 UNIQUEIDENTIFIER,
@IntegrationObjectID_665f0cd0 UNIQUEIDENTIFIER,
@Name_665f0cd0 NVARCHAR(255),
@DisplayName_665f0cd0 NVARCHAR(255),
@Description_665f0cd0 NVARCHAR(MAX),
@Category_665f0cd0 NVARCHAR(100),
@Type_665f0cd0 NVARCHAR(100),
@Length_665f0cd0 INT,
@Precision_665f0cd0 INT,
@Scale_665f0cd0 INT,
@AllowsNull_665f0cd0 BIT,
@DefaultValue_665f0cd0 NVARCHAR(255),
@IsPrimaryKey_665f0cd0 BIT,
@IsUniqueKey_665f0cd0 BIT,
@IsReadOnly_665f0cd0 BIT,
@IsRequired_665f0cd0 BIT,
@RelatedIntegrationObjectID_665f0cd0 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_665f0cd0 NVARCHAR(255),
@Sequence_665f0cd0 INT,
@Configuration_665f0cd0 NVARCHAR(MAX),
@Status_665f0cd0 NVARCHAR(25),
@IsCustom_665f0cd0 BIT,
@MetadataSource_665f0cd0 NVARCHAR(20)
SET
  @ID_665f0cd0 = '665F0CD0-029E-5E3A-9DF4-D097BF8FA67F'
SET
  @IntegrationObjectID_665f0cd0 = 'D34F26F5-C854-4C9A-834F-B8AD0245C2EF'
SET
  @Name_665f0cd0 = N'hs_object_id'
SET
  @Description_665f0cd0 = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_665f0cd0 = N'string'
SET
  @AllowsNull_665f0cd0 = 0
SET
  @IsPrimaryKey_665f0cd0 = 1
SET
  @IsUniqueKey_665f0cd0 = 1
SET
  @IsReadOnly_665f0cd0 = 1
SET
  @IsRequired_665f0cd0 = 0
SET
  @Sequence_665f0cd0 = 0
SET
  @Status_665f0cd0 = N'Active'
SET
  @IsCustom_665f0cd0 = 0
SET
  @MetadataSource_665f0cd0 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_665f0cd0,
  @IntegrationObjectID = @IntegrationObjectID_665f0cd0,
  @Name = @Name_665f0cd0,
  @DisplayName = @DisplayName_665f0cd0,
  @DisplayName_Clear = 1,
  @Description = @Description_665f0cd0,
  @Category = @Category_665f0cd0,
  @Category_Clear = 1,
  @Type = @Type_665f0cd0,
  @Length = @Length_665f0cd0,
  @Length_Clear = 1,
  @Precision = @Precision_665f0cd0,
  @Precision_Clear = 1,
  @Scale = @Scale_665f0cd0,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_665f0cd0,
  @DefaultValue = @DefaultValue_665f0cd0,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_665f0cd0,
  @IsUniqueKey = @IsUniqueKey_665f0cd0,
  @IsReadOnly = @IsReadOnly_665f0cd0,
  @IsRequired = @IsRequired_665f0cd0,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_665f0cd0,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_665f0cd0,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_665f0cd0,
  @Configuration = @Configuration_665f0cd0,
  @Configuration_Clear = 1,
  @Status = @Status_665f0cd0,
  @IsCustom = @IsCustom_665f0cd0,
  @MetadataSource = @MetadataSource_665f0cd0;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = 'D34F26F5-C854-4C9A-834F-B8AD0245C2EF' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── discounts ──────────────────────────────────────────────────────────────
DECLARE @ID_70b01684 UNIQUEIDENTIFIER,
@IntegrationObjectID_70b01684 UNIQUEIDENTIFIER,
@Name_70b01684 NVARCHAR(255),
@DisplayName_70b01684 NVARCHAR(255),
@Description_70b01684 NVARCHAR(MAX),
@Category_70b01684 NVARCHAR(100),
@Type_70b01684 NVARCHAR(100),
@Length_70b01684 INT,
@Precision_70b01684 INT,
@Scale_70b01684 INT,
@AllowsNull_70b01684 BIT,
@DefaultValue_70b01684 NVARCHAR(255),
@IsPrimaryKey_70b01684 BIT,
@IsUniqueKey_70b01684 BIT,
@IsReadOnly_70b01684 BIT,
@IsRequired_70b01684 BIT,
@RelatedIntegrationObjectID_70b01684 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_70b01684 NVARCHAR(255),
@Sequence_70b01684 INT,
@Configuration_70b01684 NVARCHAR(MAX),
@Status_70b01684 NVARCHAR(25),
@IsCustom_70b01684 BIT,
@MetadataSource_70b01684 NVARCHAR(20)
SET
  @ID_70b01684 = '70B01684-2D26-522B-A765-D017263F228F'
SET
  @IntegrationObjectID_70b01684 = '7F546789-4921-401D-A43A-47C369499D13'
SET
  @Name_70b01684 = N'hs_object_id'
SET
  @Description_70b01684 = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_70b01684 = N'string'
SET
  @AllowsNull_70b01684 = 0
SET
  @IsPrimaryKey_70b01684 = 1
SET
  @IsUniqueKey_70b01684 = 1
SET
  @IsReadOnly_70b01684 = 1
SET
  @IsRequired_70b01684 = 0
SET
  @Sequence_70b01684 = 0
SET
  @Status_70b01684 = N'Active'
SET
  @IsCustom_70b01684 = 0
SET
  @MetadataSource_70b01684 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_70b01684,
  @IntegrationObjectID = @IntegrationObjectID_70b01684,
  @Name = @Name_70b01684,
  @DisplayName = @DisplayName_70b01684,
  @DisplayName_Clear = 1,
  @Description = @Description_70b01684,
  @Category = @Category_70b01684,
  @Category_Clear = 1,
  @Type = @Type_70b01684,
  @Length = @Length_70b01684,
  @Length_Clear = 1,
  @Precision = @Precision_70b01684,
  @Precision_Clear = 1,
  @Scale = @Scale_70b01684,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_70b01684,
  @DefaultValue = @DefaultValue_70b01684,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_70b01684,
  @IsUniqueKey = @IsUniqueKey_70b01684,
  @IsReadOnly = @IsReadOnly_70b01684,
  @IsRequired = @IsRequired_70b01684,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_70b01684,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_70b01684,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_70b01684,
  @Configuration = @Configuration_70b01684,
  @Configuration_Clear = 1,
  @Status = @Status_70b01684,
  @IsCustom = @IsCustom_70b01684,
  @MetadataSource = @MetadataSource_70b01684;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = '7F546789-4921-401D-A43A-47C369499D13' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── emails ──────────────────────────────────────────────────────────────
DECLARE @ID_764c0b1f UNIQUEIDENTIFIER,
@IntegrationObjectID_764c0b1f UNIQUEIDENTIFIER,
@Name_764c0b1f NVARCHAR(255),
@DisplayName_764c0b1f NVARCHAR(255),
@Description_764c0b1f NVARCHAR(MAX),
@Category_764c0b1f NVARCHAR(100),
@Type_764c0b1f NVARCHAR(100),
@Length_764c0b1f INT,
@Precision_764c0b1f INT,
@Scale_764c0b1f INT,
@AllowsNull_764c0b1f BIT,
@DefaultValue_764c0b1f NVARCHAR(255),
@IsPrimaryKey_764c0b1f BIT,
@IsUniqueKey_764c0b1f BIT,
@IsReadOnly_764c0b1f BIT,
@IsRequired_764c0b1f BIT,
@RelatedIntegrationObjectID_764c0b1f UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_764c0b1f NVARCHAR(255),
@Sequence_764c0b1f INT,
@Configuration_764c0b1f NVARCHAR(MAX),
@Status_764c0b1f NVARCHAR(25),
@IsCustom_764c0b1f BIT,
@MetadataSource_764c0b1f NVARCHAR(20)
SET
  @ID_764c0b1f = '764C0B1F-3F2A-5237-A3BD-61D5974D757A'
SET
  @IntegrationObjectID_764c0b1f = 'E010E287-85DB-49C9-B273-71E46A68C83A'
SET
  @Name_764c0b1f = N'hs_object_id'
SET
  @Description_764c0b1f = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_764c0b1f = N'string'
SET
  @AllowsNull_764c0b1f = 0
SET
  @IsPrimaryKey_764c0b1f = 1
SET
  @IsUniqueKey_764c0b1f = 1
SET
  @IsReadOnly_764c0b1f = 1
SET
  @IsRequired_764c0b1f = 0
SET
  @Sequence_764c0b1f = 0
SET
  @Status_764c0b1f = N'Active'
SET
  @IsCustom_764c0b1f = 0
SET
  @MetadataSource_764c0b1f = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_764c0b1f,
  @IntegrationObjectID = @IntegrationObjectID_764c0b1f,
  @Name = @Name_764c0b1f,
  @DisplayName = @DisplayName_764c0b1f,
  @DisplayName_Clear = 1,
  @Description = @Description_764c0b1f,
  @Category = @Category_764c0b1f,
  @Category_Clear = 1,
  @Type = @Type_764c0b1f,
  @Length = @Length_764c0b1f,
  @Length_Clear = 1,
  @Precision = @Precision_764c0b1f,
  @Precision_Clear = 1,
  @Scale = @Scale_764c0b1f,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_764c0b1f,
  @DefaultValue = @DefaultValue_764c0b1f,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_764c0b1f,
  @IsUniqueKey = @IsUniqueKey_764c0b1f,
  @IsReadOnly = @IsReadOnly_764c0b1f,
  @IsRequired = @IsRequired_764c0b1f,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_764c0b1f,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_764c0b1f,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_764c0b1f,
  @Configuration = @Configuration_764c0b1f,
  @Configuration_Clear = 1,
  @Status = @Status_764c0b1f,
  @IsCustom = @IsCustom_764c0b1f,
  @MetadataSource = @MetadataSource_764c0b1f;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = 'E010E287-85DB-49C9-B273-71E46A68C83A' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── feedback_submissions ──────────────────────────────────────────────────────────────
DECLARE @ID_aeb13184 UNIQUEIDENTIFIER,
@IntegrationObjectID_aeb13184 UNIQUEIDENTIFIER,
@Name_aeb13184 NVARCHAR(255),
@DisplayName_aeb13184 NVARCHAR(255),
@Description_aeb13184 NVARCHAR(MAX),
@Category_aeb13184 NVARCHAR(100),
@Type_aeb13184 NVARCHAR(100),
@Length_aeb13184 INT,
@Precision_aeb13184 INT,
@Scale_aeb13184 INT,
@AllowsNull_aeb13184 BIT,
@DefaultValue_aeb13184 NVARCHAR(255),
@IsPrimaryKey_aeb13184 BIT,
@IsUniqueKey_aeb13184 BIT,
@IsReadOnly_aeb13184 BIT,
@IsRequired_aeb13184 BIT,
@RelatedIntegrationObjectID_aeb13184 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_aeb13184 NVARCHAR(255),
@Sequence_aeb13184 INT,
@Configuration_aeb13184 NVARCHAR(MAX),
@Status_aeb13184 NVARCHAR(25),
@IsCustom_aeb13184 BIT,
@MetadataSource_aeb13184 NVARCHAR(20)
SET
  @ID_aeb13184 = 'AEB13184-6163-51C7-B903-A07996133E7E'
SET
  @IntegrationObjectID_aeb13184 = 'DC8361F8-8C7A-4974-B2A9-A83614CBC59B'
SET
  @Name_aeb13184 = N'hs_object_id'
SET
  @Description_aeb13184 = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_aeb13184 = N'string'
SET
  @AllowsNull_aeb13184 = 0
SET
  @IsPrimaryKey_aeb13184 = 1
SET
  @IsUniqueKey_aeb13184 = 1
SET
  @IsReadOnly_aeb13184 = 1
SET
  @IsRequired_aeb13184 = 0
SET
  @Sequence_aeb13184 = 0
SET
  @Status_aeb13184 = N'Active'
SET
  @IsCustom_aeb13184 = 0
SET
  @MetadataSource_aeb13184 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_aeb13184,
  @IntegrationObjectID = @IntegrationObjectID_aeb13184,
  @Name = @Name_aeb13184,
  @DisplayName = @DisplayName_aeb13184,
  @DisplayName_Clear = 1,
  @Description = @Description_aeb13184,
  @Category = @Category_aeb13184,
  @Category_Clear = 1,
  @Type = @Type_aeb13184,
  @Length = @Length_aeb13184,
  @Length_Clear = 1,
  @Precision = @Precision_aeb13184,
  @Precision_Clear = 1,
  @Scale = @Scale_aeb13184,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_aeb13184,
  @DefaultValue = @DefaultValue_aeb13184,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_aeb13184,
  @IsUniqueKey = @IsUniqueKey_aeb13184,
  @IsReadOnly = @IsReadOnly_aeb13184,
  @IsRequired = @IsRequired_aeb13184,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_aeb13184,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_aeb13184,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_aeb13184,
  @Configuration = @Configuration_aeb13184,
  @Configuration_Clear = 1,
  @Status = @Status_aeb13184,
  @IsCustom = @IsCustom_aeb13184,
  @MetadataSource = @MetadataSource_aeb13184;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = 'DC8361F8-8C7A-4974-B2A9-A83614CBC59B' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── fees ──────────────────────────────────────────────────────────────
DECLARE @ID_b02ee733 UNIQUEIDENTIFIER,
@IntegrationObjectID_b02ee733 UNIQUEIDENTIFIER,
@Name_b02ee733 NVARCHAR(255),
@DisplayName_b02ee733 NVARCHAR(255),
@Description_b02ee733 NVARCHAR(MAX),
@Category_b02ee733 NVARCHAR(100),
@Type_b02ee733 NVARCHAR(100),
@Length_b02ee733 INT,
@Precision_b02ee733 INT,
@Scale_b02ee733 INT,
@AllowsNull_b02ee733 BIT,
@DefaultValue_b02ee733 NVARCHAR(255),
@IsPrimaryKey_b02ee733 BIT,
@IsUniqueKey_b02ee733 BIT,
@IsReadOnly_b02ee733 BIT,
@IsRequired_b02ee733 BIT,
@RelatedIntegrationObjectID_b02ee733 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_b02ee733 NVARCHAR(255),
@Sequence_b02ee733 INT,
@Configuration_b02ee733 NVARCHAR(MAX),
@Status_b02ee733 NVARCHAR(25),
@IsCustom_b02ee733 BIT,
@MetadataSource_b02ee733 NVARCHAR(20)
SET
  @ID_b02ee733 = 'B02EE733-5A85-52E9-A3BC-B45FA520FEFA'
SET
  @IntegrationObjectID_b02ee733 = 'F6008CB2-874C-4AC7-9DA5-3D7C22209876'
SET
  @Name_b02ee733 = N'hs_object_id'
SET
  @Description_b02ee733 = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_b02ee733 = N'string'
SET
  @AllowsNull_b02ee733 = 0
SET
  @IsPrimaryKey_b02ee733 = 1
SET
  @IsUniqueKey_b02ee733 = 1
SET
  @IsReadOnly_b02ee733 = 1
SET
  @IsRequired_b02ee733 = 0
SET
  @Sequence_b02ee733 = 0
SET
  @Status_b02ee733 = N'Active'
SET
  @IsCustom_b02ee733 = 0
SET
  @MetadataSource_b02ee733 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_b02ee733,
  @IntegrationObjectID = @IntegrationObjectID_b02ee733,
  @Name = @Name_b02ee733,
  @DisplayName = @DisplayName_b02ee733,
  @DisplayName_Clear = 1,
  @Description = @Description_b02ee733,
  @Category = @Category_b02ee733,
  @Category_Clear = 1,
  @Type = @Type_b02ee733,
  @Length = @Length_b02ee733,
  @Length_Clear = 1,
  @Precision = @Precision_b02ee733,
  @Precision_Clear = 1,
  @Scale = @Scale_b02ee733,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_b02ee733,
  @DefaultValue = @DefaultValue_b02ee733,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_b02ee733,
  @IsUniqueKey = @IsUniqueKey_b02ee733,
  @IsReadOnly = @IsReadOnly_b02ee733,
  @IsRequired = @IsRequired_b02ee733,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_b02ee733,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_b02ee733,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_b02ee733,
  @Configuration = @Configuration_b02ee733,
  @Configuration_Clear = 1,
  @Status = @Status_b02ee733,
  @IsCustom = @IsCustom_b02ee733,
  @MetadataSource = @MetadataSource_b02ee733;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = 'F6008CB2-874C-4AC7-9DA5-3D7C22209876' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── goal_targets ──────────────────────────────────────────────────────────────
DECLARE @ID_6e74c2de UNIQUEIDENTIFIER,
@IntegrationObjectID_6e74c2de UNIQUEIDENTIFIER,
@Name_6e74c2de NVARCHAR(255),
@DisplayName_6e74c2de NVARCHAR(255),
@Description_6e74c2de NVARCHAR(MAX),
@Category_6e74c2de NVARCHAR(100),
@Type_6e74c2de NVARCHAR(100),
@Length_6e74c2de INT,
@Precision_6e74c2de INT,
@Scale_6e74c2de INT,
@AllowsNull_6e74c2de BIT,
@DefaultValue_6e74c2de NVARCHAR(255),
@IsPrimaryKey_6e74c2de BIT,
@IsUniqueKey_6e74c2de BIT,
@IsReadOnly_6e74c2de BIT,
@IsRequired_6e74c2de BIT,
@RelatedIntegrationObjectID_6e74c2de UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_6e74c2de NVARCHAR(255),
@Sequence_6e74c2de INT,
@Configuration_6e74c2de NVARCHAR(MAX),
@Status_6e74c2de NVARCHAR(25),
@IsCustom_6e74c2de BIT,
@MetadataSource_6e74c2de NVARCHAR(20)
SET
  @ID_6e74c2de = '6E74C2DE-CB6F-52FB-AAC3-A6D4A06423E4'
SET
  @IntegrationObjectID_6e74c2de = '431F36F5-210B-4CDA-876D-4DD1E2B8B0EC'
SET
  @Name_6e74c2de = N'hs_object_id'
SET
  @Description_6e74c2de = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_6e74c2de = N'string'
SET
  @AllowsNull_6e74c2de = 0
SET
  @IsPrimaryKey_6e74c2de = 1
SET
  @IsUniqueKey_6e74c2de = 1
SET
  @IsReadOnly_6e74c2de = 1
SET
  @IsRequired_6e74c2de = 0
SET
  @Sequence_6e74c2de = 0
SET
  @Status_6e74c2de = N'Active'
SET
  @IsCustom_6e74c2de = 0
SET
  @MetadataSource_6e74c2de = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_6e74c2de,
  @IntegrationObjectID = @IntegrationObjectID_6e74c2de,
  @Name = @Name_6e74c2de,
  @DisplayName = @DisplayName_6e74c2de,
  @DisplayName_Clear = 1,
  @Description = @Description_6e74c2de,
  @Category = @Category_6e74c2de,
  @Category_Clear = 1,
  @Type = @Type_6e74c2de,
  @Length = @Length_6e74c2de,
  @Length_Clear = 1,
  @Precision = @Precision_6e74c2de,
  @Precision_Clear = 1,
  @Scale = @Scale_6e74c2de,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_6e74c2de,
  @DefaultValue = @DefaultValue_6e74c2de,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_6e74c2de,
  @IsUniqueKey = @IsUniqueKey_6e74c2de,
  @IsReadOnly = @IsReadOnly_6e74c2de,
  @IsRequired = @IsRequired_6e74c2de,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_6e74c2de,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_6e74c2de,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_6e74c2de,
  @Configuration = @Configuration_6e74c2de,
  @Configuration_Clear = 1,
  @Status = @Status_6e74c2de,
  @IsCustom = @IsCustom_6e74c2de,
  @MetadataSource = @MetadataSource_6e74c2de;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = '431F36F5-210B-4CDA-876D-4DD1E2B8B0EC' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── invoices ──────────────────────────────────────────────────────────────
DECLARE @ID_8187ef3e UNIQUEIDENTIFIER,
@IntegrationObjectID_8187ef3e UNIQUEIDENTIFIER,
@Name_8187ef3e NVARCHAR(255),
@DisplayName_8187ef3e NVARCHAR(255),
@Description_8187ef3e NVARCHAR(MAX),
@Category_8187ef3e NVARCHAR(100),
@Type_8187ef3e NVARCHAR(100),
@Length_8187ef3e INT,
@Precision_8187ef3e INT,
@Scale_8187ef3e INT,
@AllowsNull_8187ef3e BIT,
@DefaultValue_8187ef3e NVARCHAR(255),
@IsPrimaryKey_8187ef3e BIT,
@IsUniqueKey_8187ef3e BIT,
@IsReadOnly_8187ef3e BIT,
@IsRequired_8187ef3e BIT,
@RelatedIntegrationObjectID_8187ef3e UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_8187ef3e NVARCHAR(255),
@Sequence_8187ef3e INT,
@Configuration_8187ef3e NVARCHAR(MAX),
@Status_8187ef3e NVARCHAR(25),
@IsCustom_8187ef3e BIT,
@MetadataSource_8187ef3e NVARCHAR(20)
SET
  @ID_8187ef3e = '8187EF3E-4A51-53E8-99F6-60D57F625067'
SET
  @IntegrationObjectID_8187ef3e = '3F99724E-A4E1-42FD-8BDF-534C1109B5DA'
SET
  @Name_8187ef3e = N'hs_object_id'
SET
  @Description_8187ef3e = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_8187ef3e = N'string'
SET
  @AllowsNull_8187ef3e = 0
SET
  @IsPrimaryKey_8187ef3e = 1
SET
  @IsUniqueKey_8187ef3e = 1
SET
  @IsReadOnly_8187ef3e = 1
SET
  @IsRequired_8187ef3e = 0
SET
  @Sequence_8187ef3e = 0
SET
  @Status_8187ef3e = N'Active'
SET
  @IsCustom_8187ef3e = 0
SET
  @MetadataSource_8187ef3e = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_8187ef3e,
  @IntegrationObjectID = @IntegrationObjectID_8187ef3e,
  @Name = @Name_8187ef3e,
  @DisplayName = @DisplayName_8187ef3e,
  @DisplayName_Clear = 1,
  @Description = @Description_8187ef3e,
  @Category = @Category_8187ef3e,
  @Category_Clear = 1,
  @Type = @Type_8187ef3e,
  @Length = @Length_8187ef3e,
  @Length_Clear = 1,
  @Precision = @Precision_8187ef3e,
  @Precision_Clear = 1,
  @Scale = @Scale_8187ef3e,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_8187ef3e,
  @DefaultValue = @DefaultValue_8187ef3e,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_8187ef3e,
  @IsUniqueKey = @IsUniqueKey_8187ef3e,
  @IsReadOnly = @IsReadOnly_8187ef3e,
  @IsRequired = @IsRequired_8187ef3e,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_8187ef3e,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_8187ef3e,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_8187ef3e,
  @Configuration = @Configuration_8187ef3e,
  @Configuration_Clear = 1,
  @Status = @Status_8187ef3e,
  @IsCustom = @IsCustom_8187ef3e,
  @MetadataSource = @MetadataSource_8187ef3e;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = '3F99724E-A4E1-42FD-8BDF-534C1109B5DA' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── leads ──────────────────────────────────────────────────────────────
DECLARE @ID_5e0ee4fd UNIQUEIDENTIFIER,
@IntegrationObjectID_5e0ee4fd UNIQUEIDENTIFIER,
@Name_5e0ee4fd NVARCHAR(255),
@DisplayName_5e0ee4fd NVARCHAR(255),
@Description_5e0ee4fd NVARCHAR(MAX),
@Category_5e0ee4fd NVARCHAR(100),
@Type_5e0ee4fd NVARCHAR(100),
@Length_5e0ee4fd INT,
@Precision_5e0ee4fd INT,
@Scale_5e0ee4fd INT,
@AllowsNull_5e0ee4fd BIT,
@DefaultValue_5e0ee4fd NVARCHAR(255),
@IsPrimaryKey_5e0ee4fd BIT,
@IsUniqueKey_5e0ee4fd BIT,
@IsReadOnly_5e0ee4fd BIT,
@IsRequired_5e0ee4fd BIT,
@RelatedIntegrationObjectID_5e0ee4fd UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_5e0ee4fd NVARCHAR(255),
@Sequence_5e0ee4fd INT,
@Configuration_5e0ee4fd NVARCHAR(MAX),
@Status_5e0ee4fd NVARCHAR(25),
@IsCustom_5e0ee4fd BIT,
@MetadataSource_5e0ee4fd NVARCHAR(20)
SET
  @ID_5e0ee4fd = '5E0EE4FD-02E5-53A5-B6C0-9F3821B72864'
SET
  @IntegrationObjectID_5e0ee4fd = 'EE848395-E9FA-4AA0-B445-0AFA2F3E63FA'
SET
  @Name_5e0ee4fd = N'hs_object_id'
SET
  @Description_5e0ee4fd = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_5e0ee4fd = N'string'
SET
  @AllowsNull_5e0ee4fd = 0
SET
  @IsPrimaryKey_5e0ee4fd = 1
SET
  @IsUniqueKey_5e0ee4fd = 1
SET
  @IsReadOnly_5e0ee4fd = 1
SET
  @IsRequired_5e0ee4fd = 0
SET
  @Sequence_5e0ee4fd = 0
SET
  @Status_5e0ee4fd = N'Active'
SET
  @IsCustom_5e0ee4fd = 0
SET
  @MetadataSource_5e0ee4fd = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_5e0ee4fd,
  @IntegrationObjectID = @IntegrationObjectID_5e0ee4fd,
  @Name = @Name_5e0ee4fd,
  @DisplayName = @DisplayName_5e0ee4fd,
  @DisplayName_Clear = 1,
  @Description = @Description_5e0ee4fd,
  @Category = @Category_5e0ee4fd,
  @Category_Clear = 1,
  @Type = @Type_5e0ee4fd,
  @Length = @Length_5e0ee4fd,
  @Length_Clear = 1,
  @Precision = @Precision_5e0ee4fd,
  @Precision_Clear = 1,
  @Scale = @Scale_5e0ee4fd,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_5e0ee4fd,
  @DefaultValue = @DefaultValue_5e0ee4fd,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_5e0ee4fd,
  @IsUniqueKey = @IsUniqueKey_5e0ee4fd,
  @IsReadOnly = @IsReadOnly_5e0ee4fd,
  @IsRequired = @IsRequired_5e0ee4fd,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_5e0ee4fd,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_5e0ee4fd,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_5e0ee4fd,
  @Configuration = @Configuration_5e0ee4fd,
  @Configuration_Clear = 1,
  @Status = @Status_5e0ee4fd,
  @IsCustom = @IsCustom_5e0ee4fd,
  @MetadataSource = @MetadataSource_5e0ee4fd;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = 'EE848395-E9FA-4AA0-B445-0AFA2F3E63FA' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── line_items ──────────────────────────────────────────────────────────────
DECLARE @ID_b0ba6f03 UNIQUEIDENTIFIER,
@IntegrationObjectID_b0ba6f03 UNIQUEIDENTIFIER,
@Name_b0ba6f03 NVARCHAR(255),
@DisplayName_b0ba6f03 NVARCHAR(255),
@Description_b0ba6f03 NVARCHAR(MAX),
@Category_b0ba6f03 NVARCHAR(100),
@Type_b0ba6f03 NVARCHAR(100),
@Length_b0ba6f03 INT,
@Precision_b0ba6f03 INT,
@Scale_b0ba6f03 INT,
@AllowsNull_b0ba6f03 BIT,
@DefaultValue_b0ba6f03 NVARCHAR(255),
@IsPrimaryKey_b0ba6f03 BIT,
@IsUniqueKey_b0ba6f03 BIT,
@IsReadOnly_b0ba6f03 BIT,
@IsRequired_b0ba6f03 BIT,
@RelatedIntegrationObjectID_b0ba6f03 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_b0ba6f03 NVARCHAR(255),
@Sequence_b0ba6f03 INT,
@Configuration_b0ba6f03 NVARCHAR(MAX),
@Status_b0ba6f03 NVARCHAR(25),
@IsCustom_b0ba6f03 BIT,
@MetadataSource_b0ba6f03 NVARCHAR(20)
SET
  @ID_b0ba6f03 = 'B0BA6F03-AEA3-5545-8A0B-99F83DFB0D7B'
SET
  @IntegrationObjectID_b0ba6f03 = '10E3F4D3-ACAB-4FB5-B903-D9A7BBD52965'
SET
  @Name_b0ba6f03 = N'hs_object_id'
SET
  @Description_b0ba6f03 = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_b0ba6f03 = N'string'
SET
  @AllowsNull_b0ba6f03 = 0
SET
  @IsPrimaryKey_b0ba6f03 = 1
SET
  @IsUniqueKey_b0ba6f03 = 1
SET
  @IsReadOnly_b0ba6f03 = 1
SET
  @IsRequired_b0ba6f03 = 0
SET
  @Sequence_b0ba6f03 = 0
SET
  @Status_b0ba6f03 = N'Active'
SET
  @IsCustom_b0ba6f03 = 0
SET
  @MetadataSource_b0ba6f03 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_b0ba6f03,
  @IntegrationObjectID = @IntegrationObjectID_b0ba6f03,
  @Name = @Name_b0ba6f03,
  @DisplayName = @DisplayName_b0ba6f03,
  @DisplayName_Clear = 1,
  @Description = @Description_b0ba6f03,
  @Category = @Category_b0ba6f03,
  @Category_Clear = 1,
  @Type = @Type_b0ba6f03,
  @Length = @Length_b0ba6f03,
  @Length_Clear = 1,
  @Precision = @Precision_b0ba6f03,
  @Precision_Clear = 1,
  @Scale = @Scale_b0ba6f03,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_b0ba6f03,
  @DefaultValue = @DefaultValue_b0ba6f03,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_b0ba6f03,
  @IsUniqueKey = @IsUniqueKey_b0ba6f03,
  @IsReadOnly = @IsReadOnly_b0ba6f03,
  @IsRequired = @IsRequired_b0ba6f03,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_b0ba6f03,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_b0ba6f03,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_b0ba6f03,
  @Configuration = @Configuration_b0ba6f03,
  @Configuration_Clear = 1,
  @Status = @Status_b0ba6f03,
  @IsCustom = @IsCustom_b0ba6f03,
  @MetadataSource = @MetadataSource_b0ba6f03;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = '10E3F4D3-ACAB-4FB5-B903-D9A7BBD52965' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── listings ──────────────────────────────────────────────────────────────
DECLARE @ID_0363da2a UNIQUEIDENTIFIER,
@IntegrationObjectID_0363da2a UNIQUEIDENTIFIER,
@Name_0363da2a NVARCHAR(255),
@DisplayName_0363da2a NVARCHAR(255),
@Description_0363da2a NVARCHAR(MAX),
@Category_0363da2a NVARCHAR(100),
@Type_0363da2a NVARCHAR(100),
@Length_0363da2a INT,
@Precision_0363da2a INT,
@Scale_0363da2a INT,
@AllowsNull_0363da2a BIT,
@DefaultValue_0363da2a NVARCHAR(255),
@IsPrimaryKey_0363da2a BIT,
@IsUniqueKey_0363da2a BIT,
@IsReadOnly_0363da2a BIT,
@IsRequired_0363da2a BIT,
@RelatedIntegrationObjectID_0363da2a UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_0363da2a NVARCHAR(255),
@Sequence_0363da2a INT,
@Configuration_0363da2a NVARCHAR(MAX),
@Status_0363da2a NVARCHAR(25),
@IsCustom_0363da2a BIT,
@MetadataSource_0363da2a NVARCHAR(20)
SET
  @ID_0363da2a = '0363DA2A-F201-5351-8889-34FBADF9034C'
SET
  @IntegrationObjectID_0363da2a = '12750595-5CB5-4947-9A93-5FA609636907'
SET
  @Name_0363da2a = N'hs_object_id'
SET
  @Description_0363da2a = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_0363da2a = N'string'
SET
  @AllowsNull_0363da2a = 0
SET
  @IsPrimaryKey_0363da2a = 1
SET
  @IsUniqueKey_0363da2a = 1
SET
  @IsReadOnly_0363da2a = 1
SET
  @IsRequired_0363da2a = 0
SET
  @Sequence_0363da2a = 0
SET
  @Status_0363da2a = N'Active'
SET
  @IsCustom_0363da2a = 0
SET
  @MetadataSource_0363da2a = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_0363da2a,
  @IntegrationObjectID = @IntegrationObjectID_0363da2a,
  @Name = @Name_0363da2a,
  @DisplayName = @DisplayName_0363da2a,
  @DisplayName_Clear = 1,
  @Description = @Description_0363da2a,
  @Category = @Category_0363da2a,
  @Category_Clear = 1,
  @Type = @Type_0363da2a,
  @Length = @Length_0363da2a,
  @Length_Clear = 1,
  @Precision = @Precision_0363da2a,
  @Precision_Clear = 1,
  @Scale = @Scale_0363da2a,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_0363da2a,
  @DefaultValue = @DefaultValue_0363da2a,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_0363da2a,
  @IsUniqueKey = @IsUniqueKey_0363da2a,
  @IsReadOnly = @IsReadOnly_0363da2a,
  @IsRequired = @IsRequired_0363da2a,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_0363da2a,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_0363da2a,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_0363da2a,
  @Configuration = @Configuration_0363da2a,
  @Configuration_Clear = 1,
  @Status = @Status_0363da2a,
  @IsCustom = @IsCustom_0363da2a,
  @MetadataSource = @MetadataSource_0363da2a;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = '12750595-5CB5-4947-9A93-5FA609636907' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── meetings ──────────────────────────────────────────────────────────────
DECLARE @ID_ce54e423 UNIQUEIDENTIFIER,
@IntegrationObjectID_ce54e423 UNIQUEIDENTIFIER,
@Name_ce54e423 NVARCHAR(255),
@DisplayName_ce54e423 NVARCHAR(255),
@Description_ce54e423 NVARCHAR(MAX),
@Category_ce54e423 NVARCHAR(100),
@Type_ce54e423 NVARCHAR(100),
@Length_ce54e423 INT,
@Precision_ce54e423 INT,
@Scale_ce54e423 INT,
@AllowsNull_ce54e423 BIT,
@DefaultValue_ce54e423 NVARCHAR(255),
@IsPrimaryKey_ce54e423 BIT,
@IsUniqueKey_ce54e423 BIT,
@IsReadOnly_ce54e423 BIT,
@IsRequired_ce54e423 BIT,
@RelatedIntegrationObjectID_ce54e423 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_ce54e423 NVARCHAR(255),
@Sequence_ce54e423 INT,
@Configuration_ce54e423 NVARCHAR(MAX),
@Status_ce54e423 NVARCHAR(25),
@IsCustom_ce54e423 BIT,
@MetadataSource_ce54e423 NVARCHAR(20)
SET
  @ID_ce54e423 = 'CE54E423-5A9A-5796-9387-97D3E790A343'
SET
  @IntegrationObjectID_ce54e423 = '2E6F9A38-671F-44A8-A1AD-2273202F56EF'
SET
  @Name_ce54e423 = N'hs_object_id'
SET
  @Description_ce54e423 = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_ce54e423 = N'string'
SET
  @AllowsNull_ce54e423 = 0
SET
  @IsPrimaryKey_ce54e423 = 1
SET
  @IsUniqueKey_ce54e423 = 1
SET
  @IsReadOnly_ce54e423 = 1
SET
  @IsRequired_ce54e423 = 0
SET
  @Sequence_ce54e423 = 0
SET
  @Status_ce54e423 = N'Active'
SET
  @IsCustom_ce54e423 = 0
SET
  @MetadataSource_ce54e423 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_ce54e423,
  @IntegrationObjectID = @IntegrationObjectID_ce54e423,
  @Name = @Name_ce54e423,
  @DisplayName = @DisplayName_ce54e423,
  @DisplayName_Clear = 1,
  @Description = @Description_ce54e423,
  @Category = @Category_ce54e423,
  @Category_Clear = 1,
  @Type = @Type_ce54e423,
  @Length = @Length_ce54e423,
  @Length_Clear = 1,
  @Precision = @Precision_ce54e423,
  @Precision_Clear = 1,
  @Scale = @Scale_ce54e423,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_ce54e423,
  @DefaultValue = @DefaultValue_ce54e423,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_ce54e423,
  @IsUniqueKey = @IsUniqueKey_ce54e423,
  @IsReadOnly = @IsReadOnly_ce54e423,
  @IsRequired = @IsRequired_ce54e423,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_ce54e423,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_ce54e423,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_ce54e423,
  @Configuration = @Configuration_ce54e423,
  @Configuration_Clear = 1,
  @Status = @Status_ce54e423,
  @IsCustom = @IsCustom_ce54e423,
  @MetadataSource = @MetadataSource_ce54e423;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = '2E6F9A38-671F-44A8-A1AD-2273202F56EF' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── notes ──────────────────────────────────────────────────────────────
DECLARE @ID_68a8deaa UNIQUEIDENTIFIER,
@IntegrationObjectID_68a8deaa UNIQUEIDENTIFIER,
@Name_68a8deaa NVARCHAR(255),
@DisplayName_68a8deaa NVARCHAR(255),
@Description_68a8deaa NVARCHAR(MAX),
@Category_68a8deaa NVARCHAR(100),
@Type_68a8deaa NVARCHAR(100),
@Length_68a8deaa INT,
@Precision_68a8deaa INT,
@Scale_68a8deaa INT,
@AllowsNull_68a8deaa BIT,
@DefaultValue_68a8deaa NVARCHAR(255),
@IsPrimaryKey_68a8deaa BIT,
@IsUniqueKey_68a8deaa BIT,
@IsReadOnly_68a8deaa BIT,
@IsRequired_68a8deaa BIT,
@RelatedIntegrationObjectID_68a8deaa UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_68a8deaa NVARCHAR(255),
@Sequence_68a8deaa INT,
@Configuration_68a8deaa NVARCHAR(MAX),
@Status_68a8deaa NVARCHAR(25),
@IsCustom_68a8deaa BIT,
@MetadataSource_68a8deaa NVARCHAR(20)
SET
  @ID_68a8deaa = '68A8DEAA-878F-542C-A802-095EF1DEDE13'
SET
  @IntegrationObjectID_68a8deaa = '53CD3DE3-77A7-4AAE-98B0-A50211705D24'
SET
  @Name_68a8deaa = N'hs_object_id'
SET
  @Description_68a8deaa = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_68a8deaa = N'string'
SET
  @AllowsNull_68a8deaa = 0
SET
  @IsPrimaryKey_68a8deaa = 1
SET
  @IsUniqueKey_68a8deaa = 1
SET
  @IsReadOnly_68a8deaa = 1
SET
  @IsRequired_68a8deaa = 0
SET
  @Sequence_68a8deaa = 0
SET
  @Status_68a8deaa = N'Active'
SET
  @IsCustom_68a8deaa = 0
SET
  @MetadataSource_68a8deaa = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_68a8deaa,
  @IntegrationObjectID = @IntegrationObjectID_68a8deaa,
  @Name = @Name_68a8deaa,
  @DisplayName = @DisplayName_68a8deaa,
  @DisplayName_Clear = 1,
  @Description = @Description_68a8deaa,
  @Category = @Category_68a8deaa,
  @Category_Clear = 1,
  @Type = @Type_68a8deaa,
  @Length = @Length_68a8deaa,
  @Length_Clear = 1,
  @Precision = @Precision_68a8deaa,
  @Precision_Clear = 1,
  @Scale = @Scale_68a8deaa,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_68a8deaa,
  @DefaultValue = @DefaultValue_68a8deaa,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_68a8deaa,
  @IsUniqueKey = @IsUniqueKey_68a8deaa,
  @IsReadOnly = @IsReadOnly_68a8deaa,
  @IsRequired = @IsRequired_68a8deaa,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_68a8deaa,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_68a8deaa,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_68a8deaa,
  @Configuration = @Configuration_68a8deaa,
  @Configuration_Clear = 1,
  @Status = @Status_68a8deaa,
  @IsCustom = @IsCustom_68a8deaa,
  @MetadataSource = @MetadataSource_68a8deaa;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = '53CD3DE3-77A7-4AAE-98B0-A50211705D24' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── orders ──────────────────────────────────────────────────────────────
DECLARE @ID_fdaec289 UNIQUEIDENTIFIER,
@IntegrationObjectID_fdaec289 UNIQUEIDENTIFIER,
@Name_fdaec289 NVARCHAR(255),
@DisplayName_fdaec289 NVARCHAR(255),
@Description_fdaec289 NVARCHAR(MAX),
@Category_fdaec289 NVARCHAR(100),
@Type_fdaec289 NVARCHAR(100),
@Length_fdaec289 INT,
@Precision_fdaec289 INT,
@Scale_fdaec289 INT,
@AllowsNull_fdaec289 BIT,
@DefaultValue_fdaec289 NVARCHAR(255),
@IsPrimaryKey_fdaec289 BIT,
@IsUniqueKey_fdaec289 BIT,
@IsReadOnly_fdaec289 BIT,
@IsRequired_fdaec289 BIT,
@RelatedIntegrationObjectID_fdaec289 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_fdaec289 NVARCHAR(255),
@Sequence_fdaec289 INT,
@Configuration_fdaec289 NVARCHAR(MAX),
@Status_fdaec289 NVARCHAR(25),
@IsCustom_fdaec289 BIT,
@MetadataSource_fdaec289 NVARCHAR(20)
SET
  @ID_fdaec289 = 'FDAEC289-113C-5B22-B83F-0C36C0C35CFE'
SET
  @IntegrationObjectID_fdaec289 = '1A0024CB-35BF-4779-81BD-451DC511E550'
SET
  @Name_fdaec289 = N'hs_object_id'
SET
  @Description_fdaec289 = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_fdaec289 = N'string'
SET
  @AllowsNull_fdaec289 = 0
SET
  @IsPrimaryKey_fdaec289 = 1
SET
  @IsUniqueKey_fdaec289 = 1
SET
  @IsReadOnly_fdaec289 = 1
SET
  @IsRequired_fdaec289 = 0
SET
  @Sequence_fdaec289 = 0
SET
  @Status_fdaec289 = N'Active'
SET
  @IsCustom_fdaec289 = 0
SET
  @MetadataSource_fdaec289 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_fdaec289,
  @IntegrationObjectID = @IntegrationObjectID_fdaec289,
  @Name = @Name_fdaec289,
  @DisplayName = @DisplayName_fdaec289,
  @DisplayName_Clear = 1,
  @Description = @Description_fdaec289,
  @Category = @Category_fdaec289,
  @Category_Clear = 1,
  @Type = @Type_fdaec289,
  @Length = @Length_fdaec289,
  @Length_Clear = 1,
  @Precision = @Precision_fdaec289,
  @Precision_Clear = 1,
  @Scale = @Scale_fdaec289,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_fdaec289,
  @DefaultValue = @DefaultValue_fdaec289,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_fdaec289,
  @IsUniqueKey = @IsUniqueKey_fdaec289,
  @IsReadOnly = @IsReadOnly_fdaec289,
  @IsRequired = @IsRequired_fdaec289,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_fdaec289,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_fdaec289,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_fdaec289,
  @Configuration = @Configuration_fdaec289,
  @Configuration_Clear = 1,
  @Status = @Status_fdaec289,
  @IsCustom = @IsCustom_fdaec289,
  @MetadataSource = @MetadataSource_fdaec289;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = '1A0024CB-35BF-4779-81BD-451DC511E550' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── postal_mail ──────────────────────────────────────────────────────────────
DECLARE @ID_cf1b1b8f UNIQUEIDENTIFIER,
@IntegrationObjectID_cf1b1b8f UNIQUEIDENTIFIER,
@Name_cf1b1b8f NVARCHAR(255),
@DisplayName_cf1b1b8f NVARCHAR(255),
@Description_cf1b1b8f NVARCHAR(MAX),
@Category_cf1b1b8f NVARCHAR(100),
@Type_cf1b1b8f NVARCHAR(100),
@Length_cf1b1b8f INT,
@Precision_cf1b1b8f INT,
@Scale_cf1b1b8f INT,
@AllowsNull_cf1b1b8f BIT,
@DefaultValue_cf1b1b8f NVARCHAR(255),
@IsPrimaryKey_cf1b1b8f BIT,
@IsUniqueKey_cf1b1b8f BIT,
@IsReadOnly_cf1b1b8f BIT,
@IsRequired_cf1b1b8f BIT,
@RelatedIntegrationObjectID_cf1b1b8f UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_cf1b1b8f NVARCHAR(255),
@Sequence_cf1b1b8f INT,
@Configuration_cf1b1b8f NVARCHAR(MAX),
@Status_cf1b1b8f NVARCHAR(25),
@IsCustom_cf1b1b8f BIT,
@MetadataSource_cf1b1b8f NVARCHAR(20)
SET
  @ID_cf1b1b8f = 'CF1B1B8F-005B-566A-A22A-C495535B718B'
SET
  @IntegrationObjectID_cf1b1b8f = 'C08F328E-9E0C-4BBB-A479-0F8E7B18C43F'
SET
  @Name_cf1b1b8f = N'hs_object_id'
SET
  @Description_cf1b1b8f = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_cf1b1b8f = N'string'
SET
  @AllowsNull_cf1b1b8f = 0
SET
  @IsPrimaryKey_cf1b1b8f = 1
SET
  @IsUniqueKey_cf1b1b8f = 1
SET
  @IsReadOnly_cf1b1b8f = 1
SET
  @IsRequired_cf1b1b8f = 0
SET
  @Sequence_cf1b1b8f = 0
SET
  @Status_cf1b1b8f = N'Active'
SET
  @IsCustom_cf1b1b8f = 0
SET
  @MetadataSource_cf1b1b8f = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_cf1b1b8f,
  @IntegrationObjectID = @IntegrationObjectID_cf1b1b8f,
  @Name = @Name_cf1b1b8f,
  @DisplayName = @DisplayName_cf1b1b8f,
  @DisplayName_Clear = 1,
  @Description = @Description_cf1b1b8f,
  @Category = @Category_cf1b1b8f,
  @Category_Clear = 1,
  @Type = @Type_cf1b1b8f,
  @Length = @Length_cf1b1b8f,
  @Length_Clear = 1,
  @Precision = @Precision_cf1b1b8f,
  @Precision_Clear = 1,
  @Scale = @Scale_cf1b1b8f,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_cf1b1b8f,
  @DefaultValue = @DefaultValue_cf1b1b8f,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_cf1b1b8f,
  @IsUniqueKey = @IsUniqueKey_cf1b1b8f,
  @IsReadOnly = @IsReadOnly_cf1b1b8f,
  @IsRequired = @IsRequired_cf1b1b8f,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_cf1b1b8f,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_cf1b1b8f,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_cf1b1b8f,
  @Configuration = @Configuration_cf1b1b8f,
  @Configuration_Clear = 1,
  @Status = @Status_cf1b1b8f,
  @IsCustom = @IsCustom_cf1b1b8f,
  @MetadataSource = @MetadataSource_cf1b1b8f;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = 'C08F328E-9E0C-4BBB-A479-0F8E7B18C43F' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── products ──────────────────────────────────────────────────────────────
DECLARE @ID_fc57b9a8 UNIQUEIDENTIFIER,
@IntegrationObjectID_fc57b9a8 UNIQUEIDENTIFIER,
@Name_fc57b9a8 NVARCHAR(255),
@DisplayName_fc57b9a8 NVARCHAR(255),
@Description_fc57b9a8 NVARCHAR(MAX),
@Category_fc57b9a8 NVARCHAR(100),
@Type_fc57b9a8 NVARCHAR(100),
@Length_fc57b9a8 INT,
@Precision_fc57b9a8 INT,
@Scale_fc57b9a8 INT,
@AllowsNull_fc57b9a8 BIT,
@DefaultValue_fc57b9a8 NVARCHAR(255),
@IsPrimaryKey_fc57b9a8 BIT,
@IsUniqueKey_fc57b9a8 BIT,
@IsReadOnly_fc57b9a8 BIT,
@IsRequired_fc57b9a8 BIT,
@RelatedIntegrationObjectID_fc57b9a8 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_fc57b9a8 NVARCHAR(255),
@Sequence_fc57b9a8 INT,
@Configuration_fc57b9a8 NVARCHAR(MAX),
@Status_fc57b9a8 NVARCHAR(25),
@IsCustom_fc57b9a8 BIT,
@MetadataSource_fc57b9a8 NVARCHAR(20)
SET
  @ID_fc57b9a8 = 'FC57B9A8-21B8-5907-B331-8EA322D7AE60'
SET
  @IntegrationObjectID_fc57b9a8 = '45AE9111-95F7-4C1C-8722-119E10D3BB8D'
SET
  @Name_fc57b9a8 = N'hs_object_id'
SET
  @Description_fc57b9a8 = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_fc57b9a8 = N'string'
SET
  @AllowsNull_fc57b9a8 = 0
SET
  @IsPrimaryKey_fc57b9a8 = 1
SET
  @IsUniqueKey_fc57b9a8 = 1
SET
  @IsReadOnly_fc57b9a8 = 1
SET
  @IsRequired_fc57b9a8 = 0
SET
  @Sequence_fc57b9a8 = 0
SET
  @Status_fc57b9a8 = N'Active'
SET
  @IsCustom_fc57b9a8 = 0
SET
  @MetadataSource_fc57b9a8 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_fc57b9a8,
  @IntegrationObjectID = @IntegrationObjectID_fc57b9a8,
  @Name = @Name_fc57b9a8,
  @DisplayName = @DisplayName_fc57b9a8,
  @DisplayName_Clear = 1,
  @Description = @Description_fc57b9a8,
  @Category = @Category_fc57b9a8,
  @Category_Clear = 1,
  @Type = @Type_fc57b9a8,
  @Length = @Length_fc57b9a8,
  @Length_Clear = 1,
  @Precision = @Precision_fc57b9a8,
  @Precision_Clear = 1,
  @Scale = @Scale_fc57b9a8,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_fc57b9a8,
  @DefaultValue = @DefaultValue_fc57b9a8,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_fc57b9a8,
  @IsUniqueKey = @IsUniqueKey_fc57b9a8,
  @IsReadOnly = @IsReadOnly_fc57b9a8,
  @IsRequired = @IsRequired_fc57b9a8,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_fc57b9a8,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_fc57b9a8,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_fc57b9a8,
  @Configuration = @Configuration_fc57b9a8,
  @Configuration_Clear = 1,
  @Status = @Status_fc57b9a8,
  @IsCustom = @IsCustom_fc57b9a8,
  @MetadataSource = @MetadataSource_fc57b9a8;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = '45AE9111-95F7-4C1C-8722-119E10D3BB8D' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── projects ──────────────────────────────────────────────────────────────
DECLARE @ID_a0492ec6 UNIQUEIDENTIFIER,
@IntegrationObjectID_a0492ec6 UNIQUEIDENTIFIER,
@Name_a0492ec6 NVARCHAR(255),
@DisplayName_a0492ec6 NVARCHAR(255),
@Description_a0492ec6 NVARCHAR(MAX),
@Category_a0492ec6 NVARCHAR(100),
@Type_a0492ec6 NVARCHAR(100),
@Length_a0492ec6 INT,
@Precision_a0492ec6 INT,
@Scale_a0492ec6 INT,
@AllowsNull_a0492ec6 BIT,
@DefaultValue_a0492ec6 NVARCHAR(255),
@IsPrimaryKey_a0492ec6 BIT,
@IsUniqueKey_a0492ec6 BIT,
@IsReadOnly_a0492ec6 BIT,
@IsRequired_a0492ec6 BIT,
@RelatedIntegrationObjectID_a0492ec6 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_a0492ec6 NVARCHAR(255),
@Sequence_a0492ec6 INT,
@Configuration_a0492ec6 NVARCHAR(MAX),
@Status_a0492ec6 NVARCHAR(25),
@IsCustom_a0492ec6 BIT,
@MetadataSource_a0492ec6 NVARCHAR(20)
SET
  @ID_a0492ec6 = 'A0492EC6-1C3C-5B74-B3F6-7699A72D869C'
SET
  @IntegrationObjectID_a0492ec6 = 'BA2ED838-9A80-4522-8737-55F6A5F71921'
SET
  @Name_a0492ec6 = N'hs_object_id'
SET
  @Description_a0492ec6 = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_a0492ec6 = N'string'
SET
  @AllowsNull_a0492ec6 = 0
SET
  @IsPrimaryKey_a0492ec6 = 1
SET
  @IsUniqueKey_a0492ec6 = 1
SET
  @IsReadOnly_a0492ec6 = 1
SET
  @IsRequired_a0492ec6 = 0
SET
  @Sequence_a0492ec6 = 0
SET
  @Status_a0492ec6 = N'Active'
SET
  @IsCustom_a0492ec6 = 0
SET
  @MetadataSource_a0492ec6 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_a0492ec6,
  @IntegrationObjectID = @IntegrationObjectID_a0492ec6,
  @Name = @Name_a0492ec6,
  @DisplayName = @DisplayName_a0492ec6,
  @DisplayName_Clear = 1,
  @Description = @Description_a0492ec6,
  @Category = @Category_a0492ec6,
  @Category_Clear = 1,
  @Type = @Type_a0492ec6,
  @Length = @Length_a0492ec6,
  @Length_Clear = 1,
  @Precision = @Precision_a0492ec6,
  @Precision_Clear = 1,
  @Scale = @Scale_a0492ec6,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_a0492ec6,
  @DefaultValue = @DefaultValue_a0492ec6,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_a0492ec6,
  @IsUniqueKey = @IsUniqueKey_a0492ec6,
  @IsReadOnly = @IsReadOnly_a0492ec6,
  @IsRequired = @IsRequired_a0492ec6,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_a0492ec6,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_a0492ec6,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_a0492ec6,
  @Configuration = @Configuration_a0492ec6,
  @Configuration_Clear = 1,
  @Status = @Status_a0492ec6,
  @IsCustom = @IsCustom_a0492ec6,
  @MetadataSource = @MetadataSource_a0492ec6;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = 'BA2ED838-9A80-4522-8737-55F6A5F71921' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── quotes ──────────────────────────────────────────────────────────────
DECLARE @ID_079b4e6f UNIQUEIDENTIFIER,
@IntegrationObjectID_079b4e6f UNIQUEIDENTIFIER,
@Name_079b4e6f NVARCHAR(255),
@DisplayName_079b4e6f NVARCHAR(255),
@Description_079b4e6f NVARCHAR(MAX),
@Category_079b4e6f NVARCHAR(100),
@Type_079b4e6f NVARCHAR(100),
@Length_079b4e6f INT,
@Precision_079b4e6f INT,
@Scale_079b4e6f INT,
@AllowsNull_079b4e6f BIT,
@DefaultValue_079b4e6f NVARCHAR(255),
@IsPrimaryKey_079b4e6f BIT,
@IsUniqueKey_079b4e6f BIT,
@IsReadOnly_079b4e6f BIT,
@IsRequired_079b4e6f BIT,
@RelatedIntegrationObjectID_079b4e6f UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_079b4e6f NVARCHAR(255),
@Sequence_079b4e6f INT,
@Configuration_079b4e6f NVARCHAR(MAX),
@Status_079b4e6f NVARCHAR(25),
@IsCustom_079b4e6f BIT,
@MetadataSource_079b4e6f NVARCHAR(20)
SET
  @ID_079b4e6f = '079B4E6F-2085-576C-8BDC-A4B30652D92F'
SET
  @IntegrationObjectID_079b4e6f = '1E976648-625B-4955-9074-575C7E1B3BDA'
SET
  @Name_079b4e6f = N'hs_object_id'
SET
  @Description_079b4e6f = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_079b4e6f = N'string'
SET
  @AllowsNull_079b4e6f = 0
SET
  @IsPrimaryKey_079b4e6f = 1
SET
  @IsUniqueKey_079b4e6f = 1
SET
  @IsReadOnly_079b4e6f = 1
SET
  @IsRequired_079b4e6f = 0
SET
  @Sequence_079b4e6f = 0
SET
  @Status_079b4e6f = N'Active'
SET
  @IsCustom_079b4e6f = 0
SET
  @MetadataSource_079b4e6f = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_079b4e6f,
  @IntegrationObjectID = @IntegrationObjectID_079b4e6f,
  @Name = @Name_079b4e6f,
  @DisplayName = @DisplayName_079b4e6f,
  @DisplayName_Clear = 1,
  @Description = @Description_079b4e6f,
  @Category = @Category_079b4e6f,
  @Category_Clear = 1,
  @Type = @Type_079b4e6f,
  @Length = @Length_079b4e6f,
  @Length_Clear = 1,
  @Precision = @Precision_079b4e6f,
  @Precision_Clear = 1,
  @Scale = @Scale_079b4e6f,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_079b4e6f,
  @DefaultValue = @DefaultValue_079b4e6f,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_079b4e6f,
  @IsUniqueKey = @IsUniqueKey_079b4e6f,
  @IsReadOnly = @IsReadOnly_079b4e6f,
  @IsRequired = @IsRequired_079b4e6f,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_079b4e6f,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_079b4e6f,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_079b4e6f,
  @Configuration = @Configuration_079b4e6f,
  @Configuration_Clear = 1,
  @Status = @Status_079b4e6f,
  @IsCustom = @IsCustom_079b4e6f,
  @MetadataSource = @MetadataSource_079b4e6f;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = '1E976648-625B-4955-9074-575C7E1B3BDA' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── services ──────────────────────────────────────────────────────────────
DECLARE @ID_d2663254 UNIQUEIDENTIFIER,
@IntegrationObjectID_d2663254 UNIQUEIDENTIFIER,
@Name_d2663254 NVARCHAR(255),
@DisplayName_d2663254 NVARCHAR(255),
@Description_d2663254 NVARCHAR(MAX),
@Category_d2663254 NVARCHAR(100),
@Type_d2663254 NVARCHAR(100),
@Length_d2663254 INT,
@Precision_d2663254 INT,
@Scale_d2663254 INT,
@AllowsNull_d2663254 BIT,
@DefaultValue_d2663254 NVARCHAR(255),
@IsPrimaryKey_d2663254 BIT,
@IsUniqueKey_d2663254 BIT,
@IsReadOnly_d2663254 BIT,
@IsRequired_d2663254 BIT,
@RelatedIntegrationObjectID_d2663254 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_d2663254 NVARCHAR(255),
@Sequence_d2663254 INT,
@Configuration_d2663254 NVARCHAR(MAX),
@Status_d2663254 NVARCHAR(25),
@IsCustom_d2663254 BIT,
@MetadataSource_d2663254 NVARCHAR(20)
SET
  @ID_d2663254 = 'D2663254-282C-5D76-90EE-2CEF960E45F8'
SET
  @IntegrationObjectID_d2663254 = '8413DEB6-719C-4155-A0E7-F4D0366E1C0C'
SET
  @Name_d2663254 = N'hs_object_id'
SET
  @Description_d2663254 = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_d2663254 = N'string'
SET
  @AllowsNull_d2663254 = 0
SET
  @IsPrimaryKey_d2663254 = 1
SET
  @IsUniqueKey_d2663254 = 1
SET
  @IsReadOnly_d2663254 = 1
SET
  @IsRequired_d2663254 = 0
SET
  @Sequence_d2663254 = 0
SET
  @Status_d2663254 = N'Active'
SET
  @IsCustom_d2663254 = 0
SET
  @MetadataSource_d2663254 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_d2663254,
  @IntegrationObjectID = @IntegrationObjectID_d2663254,
  @Name = @Name_d2663254,
  @DisplayName = @DisplayName_d2663254,
  @DisplayName_Clear = 1,
  @Description = @Description_d2663254,
  @Category = @Category_d2663254,
  @Category_Clear = 1,
  @Type = @Type_d2663254,
  @Length = @Length_d2663254,
  @Length_Clear = 1,
  @Precision = @Precision_d2663254,
  @Precision_Clear = 1,
  @Scale = @Scale_d2663254,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_d2663254,
  @DefaultValue = @DefaultValue_d2663254,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_d2663254,
  @IsUniqueKey = @IsUniqueKey_d2663254,
  @IsReadOnly = @IsReadOnly_d2663254,
  @IsRequired = @IsRequired_d2663254,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_d2663254,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_d2663254,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_d2663254,
  @Configuration = @Configuration_d2663254,
  @Configuration_Clear = 1,
  @Status = @Status_d2663254,
  @IsCustom = @IsCustom_d2663254,
  @MetadataSource = @MetadataSource_d2663254;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = '8413DEB6-719C-4155-A0E7-F4D0366E1C0C' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── subscriptions ──────────────────────────────────────────────────────────────
DECLARE @ID_58bb01de UNIQUEIDENTIFIER,
@IntegrationObjectID_58bb01de UNIQUEIDENTIFIER,
@Name_58bb01de NVARCHAR(255),
@DisplayName_58bb01de NVARCHAR(255),
@Description_58bb01de NVARCHAR(MAX),
@Category_58bb01de NVARCHAR(100),
@Type_58bb01de NVARCHAR(100),
@Length_58bb01de INT,
@Precision_58bb01de INT,
@Scale_58bb01de INT,
@AllowsNull_58bb01de BIT,
@DefaultValue_58bb01de NVARCHAR(255),
@IsPrimaryKey_58bb01de BIT,
@IsUniqueKey_58bb01de BIT,
@IsReadOnly_58bb01de BIT,
@IsRequired_58bb01de BIT,
@RelatedIntegrationObjectID_58bb01de UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_58bb01de NVARCHAR(255),
@Sequence_58bb01de INT,
@Configuration_58bb01de NVARCHAR(MAX),
@Status_58bb01de NVARCHAR(25),
@IsCustom_58bb01de BIT,
@MetadataSource_58bb01de NVARCHAR(20)
SET
  @ID_58bb01de = '58BB01DE-7BFB-57B9-AF58-0C06B75424EB'
SET
  @IntegrationObjectID_58bb01de = '1ED82C55-E9AF-4D39-96A6-79B1A23F7CCF'
SET
  @Name_58bb01de = N'hs_object_id'
SET
  @Description_58bb01de = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_58bb01de = N'string'
SET
  @AllowsNull_58bb01de = 0
SET
  @IsPrimaryKey_58bb01de = 1
SET
  @IsUniqueKey_58bb01de = 1
SET
  @IsReadOnly_58bb01de = 1
SET
  @IsRequired_58bb01de = 0
SET
  @Sequence_58bb01de = 0
SET
  @Status_58bb01de = N'Active'
SET
  @IsCustom_58bb01de = 0
SET
  @MetadataSource_58bb01de = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_58bb01de,
  @IntegrationObjectID = @IntegrationObjectID_58bb01de,
  @Name = @Name_58bb01de,
  @DisplayName = @DisplayName_58bb01de,
  @DisplayName_Clear = 1,
  @Description = @Description_58bb01de,
  @Category = @Category_58bb01de,
  @Category_Clear = 1,
  @Type = @Type_58bb01de,
  @Length = @Length_58bb01de,
  @Length_Clear = 1,
  @Precision = @Precision_58bb01de,
  @Precision_Clear = 1,
  @Scale = @Scale_58bb01de,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_58bb01de,
  @DefaultValue = @DefaultValue_58bb01de,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_58bb01de,
  @IsUniqueKey = @IsUniqueKey_58bb01de,
  @IsReadOnly = @IsReadOnly_58bb01de,
  @IsRequired = @IsRequired_58bb01de,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_58bb01de,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_58bb01de,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_58bb01de,
  @Configuration = @Configuration_58bb01de,
  @Configuration_Clear = 1,
  @Status = @Status_58bb01de,
  @IsCustom = @IsCustom_58bb01de,
  @MetadataSource = @MetadataSource_58bb01de;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = '1ED82C55-E9AF-4D39-96A6-79B1A23F7CCF' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── tasks ──────────────────────────────────────────────────────────────
DECLARE @ID_92e54acc UNIQUEIDENTIFIER,
@IntegrationObjectID_92e54acc UNIQUEIDENTIFIER,
@Name_92e54acc NVARCHAR(255),
@DisplayName_92e54acc NVARCHAR(255),
@Description_92e54acc NVARCHAR(MAX),
@Category_92e54acc NVARCHAR(100),
@Type_92e54acc NVARCHAR(100),
@Length_92e54acc INT,
@Precision_92e54acc INT,
@Scale_92e54acc INT,
@AllowsNull_92e54acc BIT,
@DefaultValue_92e54acc NVARCHAR(255),
@IsPrimaryKey_92e54acc BIT,
@IsUniqueKey_92e54acc BIT,
@IsReadOnly_92e54acc BIT,
@IsRequired_92e54acc BIT,
@RelatedIntegrationObjectID_92e54acc UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_92e54acc NVARCHAR(255),
@Sequence_92e54acc INT,
@Configuration_92e54acc NVARCHAR(MAX),
@Status_92e54acc NVARCHAR(25),
@IsCustom_92e54acc BIT,
@MetadataSource_92e54acc NVARCHAR(20)
SET
  @ID_92e54acc = '92E54ACC-E94B-5160-98CE-034B581B9446'
SET
  @IntegrationObjectID_92e54acc = '1E9F77D7-478D-4646-A7A4-2F6D5E1C5891'
SET
  @Name_92e54acc = N'hs_object_id'
SET
  @Description_92e54acc = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_92e54acc = N'string'
SET
  @AllowsNull_92e54acc = 0
SET
  @IsPrimaryKey_92e54acc = 1
SET
  @IsUniqueKey_92e54acc = 1
SET
  @IsReadOnly_92e54acc = 1
SET
  @IsRequired_92e54acc = 0
SET
  @Sequence_92e54acc = 0
SET
  @Status_92e54acc = N'Active'
SET
  @IsCustom_92e54acc = 0
SET
  @MetadataSource_92e54acc = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_92e54acc,
  @IntegrationObjectID = @IntegrationObjectID_92e54acc,
  @Name = @Name_92e54acc,
  @DisplayName = @DisplayName_92e54acc,
  @DisplayName_Clear = 1,
  @Description = @Description_92e54acc,
  @Category = @Category_92e54acc,
  @Category_Clear = 1,
  @Type = @Type_92e54acc,
  @Length = @Length_92e54acc,
  @Length_Clear = 1,
  @Precision = @Precision_92e54acc,
  @Precision_Clear = 1,
  @Scale = @Scale_92e54acc,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_92e54acc,
  @DefaultValue = @DefaultValue_92e54acc,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_92e54acc,
  @IsUniqueKey = @IsUniqueKey_92e54acc,
  @IsReadOnly = @IsReadOnly_92e54acc,
  @IsRequired = @IsRequired_92e54acc,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_92e54acc,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_92e54acc,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_92e54acc,
  @Configuration = @Configuration_92e54acc,
  @Configuration_Clear = 1,
  @Status = @Status_92e54acc,
  @IsCustom = @IsCustom_92e54acc,
  @MetadataSource = @MetadataSource_92e54acc;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = '1E9F77D7-478D-4646-A7A4-2F6D5E1C5891' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── taxes ──────────────────────────────────────────────────────────────
DECLARE @ID_993a3ac9 UNIQUEIDENTIFIER,
@IntegrationObjectID_993a3ac9 UNIQUEIDENTIFIER,
@Name_993a3ac9 NVARCHAR(255),
@DisplayName_993a3ac9 NVARCHAR(255),
@Description_993a3ac9 NVARCHAR(MAX),
@Category_993a3ac9 NVARCHAR(100),
@Type_993a3ac9 NVARCHAR(100),
@Length_993a3ac9 INT,
@Precision_993a3ac9 INT,
@Scale_993a3ac9 INT,
@AllowsNull_993a3ac9 BIT,
@DefaultValue_993a3ac9 NVARCHAR(255),
@IsPrimaryKey_993a3ac9 BIT,
@IsUniqueKey_993a3ac9 BIT,
@IsReadOnly_993a3ac9 BIT,
@IsRequired_993a3ac9 BIT,
@RelatedIntegrationObjectID_993a3ac9 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_993a3ac9 NVARCHAR(255),
@Sequence_993a3ac9 INT,
@Configuration_993a3ac9 NVARCHAR(MAX),
@Status_993a3ac9 NVARCHAR(25),
@IsCustom_993a3ac9 BIT,
@MetadataSource_993a3ac9 NVARCHAR(20)
SET
  @ID_993a3ac9 = '993A3AC9-F891-5911-B884-C3E81126FBC1'
SET
  @IntegrationObjectID_993a3ac9 = 'E5BF150E-D089-4993-90E8-2E5FC057B9A7'
SET
  @Name_993a3ac9 = N'hs_object_id'
SET
  @Description_993a3ac9 = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_993a3ac9 = N'string'
SET
  @AllowsNull_993a3ac9 = 0
SET
  @IsPrimaryKey_993a3ac9 = 1
SET
  @IsUniqueKey_993a3ac9 = 1
SET
  @IsReadOnly_993a3ac9 = 1
SET
  @IsRequired_993a3ac9 = 0
SET
  @Sequence_993a3ac9 = 0
SET
  @Status_993a3ac9 = N'Active'
SET
  @IsCustom_993a3ac9 = 0
SET
  @MetadataSource_993a3ac9 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_993a3ac9,
  @IntegrationObjectID = @IntegrationObjectID_993a3ac9,
  @Name = @Name_993a3ac9,
  @DisplayName = @DisplayName_993a3ac9,
  @DisplayName_Clear = 1,
  @Description = @Description_993a3ac9,
  @Category = @Category_993a3ac9,
  @Category_Clear = 1,
  @Type = @Type_993a3ac9,
  @Length = @Length_993a3ac9,
  @Length_Clear = 1,
  @Precision = @Precision_993a3ac9,
  @Precision_Clear = 1,
  @Scale = @Scale_993a3ac9,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_993a3ac9,
  @DefaultValue = @DefaultValue_993a3ac9,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_993a3ac9,
  @IsUniqueKey = @IsUniqueKey_993a3ac9,
  @IsReadOnly = @IsReadOnly_993a3ac9,
  @IsRequired = @IsRequired_993a3ac9,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_993a3ac9,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_993a3ac9,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_993a3ac9,
  @Configuration = @Configuration_993a3ac9,
  @Configuration_Clear = 1,
  @Status = @Status_993a3ac9,
  @IsCustom = @IsCustom_993a3ac9,
  @MetadataSource = @MetadataSource_993a3ac9;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = 'E5BF150E-D089-4993-90E8-2E5FC057B9A7' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── tickets ──────────────────────────────────────────────────────────────
DECLARE @ID_df1cbb08 UNIQUEIDENTIFIER,
@IntegrationObjectID_df1cbb08 UNIQUEIDENTIFIER,
@Name_df1cbb08 NVARCHAR(255),
@DisplayName_df1cbb08 NVARCHAR(255),
@Description_df1cbb08 NVARCHAR(MAX),
@Category_df1cbb08 NVARCHAR(100),
@Type_df1cbb08 NVARCHAR(100),
@Length_df1cbb08 INT,
@Precision_df1cbb08 INT,
@Scale_df1cbb08 INT,
@AllowsNull_df1cbb08 BIT,
@DefaultValue_df1cbb08 NVARCHAR(255),
@IsPrimaryKey_df1cbb08 BIT,
@IsUniqueKey_df1cbb08 BIT,
@IsReadOnly_df1cbb08 BIT,
@IsRequired_df1cbb08 BIT,
@RelatedIntegrationObjectID_df1cbb08 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_df1cbb08 NVARCHAR(255),
@Sequence_df1cbb08 INT,
@Configuration_df1cbb08 NVARCHAR(MAX),
@Status_df1cbb08 NVARCHAR(25),
@IsCustom_df1cbb08 BIT,
@MetadataSource_df1cbb08 NVARCHAR(20)
SET
  @ID_df1cbb08 = 'DF1CBB08-F466-556E-97CE-E4EF98D50C3C'
SET
  @IntegrationObjectID_df1cbb08 = '47E8CF5F-9009-4253-9E4E-482527C28D92'
SET
  @Name_df1cbb08 = N'hs_object_id'
SET
  @Description_df1cbb08 = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_df1cbb08 = N'string'
SET
  @AllowsNull_df1cbb08 = 0
SET
  @IsPrimaryKey_df1cbb08 = 1
SET
  @IsUniqueKey_df1cbb08 = 1
SET
  @IsReadOnly_df1cbb08 = 1
SET
  @IsRequired_df1cbb08 = 0
SET
  @Sequence_df1cbb08 = 0
SET
  @Status_df1cbb08 = N'Active'
SET
  @IsCustom_df1cbb08 = 0
SET
  @MetadataSource_df1cbb08 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_df1cbb08,
  @IntegrationObjectID = @IntegrationObjectID_df1cbb08,
  @Name = @Name_df1cbb08,
  @DisplayName = @DisplayName_df1cbb08,
  @DisplayName_Clear = 1,
  @Description = @Description_df1cbb08,
  @Category = @Category_df1cbb08,
  @Category_Clear = 1,
  @Type = @Type_df1cbb08,
  @Length = @Length_df1cbb08,
  @Length_Clear = 1,
  @Precision = @Precision_df1cbb08,
  @Precision_Clear = 1,
  @Scale = @Scale_df1cbb08,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_df1cbb08,
  @DefaultValue = @DefaultValue_df1cbb08,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_df1cbb08,
  @IsUniqueKey = @IsUniqueKey_df1cbb08,
  @IsReadOnly = @IsReadOnly_df1cbb08,
  @IsRequired = @IsRequired_df1cbb08,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_df1cbb08,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_df1cbb08,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_df1cbb08,
  @Configuration = @Configuration_df1cbb08,
  @Configuration_Clear = 1,
  @Status = @Status_df1cbb08,
  @IsCustom = @IsCustom_df1cbb08,
  @MetadataSource = @MetadataSource_df1cbb08;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = '47E8CF5F-9009-4253-9E4E-482527C28D92' AND Name = N'id' AND IsPrimaryKey = 1;

GO

-- ── users ──────────────────────────────────────────────────────────────
DECLARE @ID_c10125d5 UNIQUEIDENTIFIER,
@IntegrationObjectID_c10125d5 UNIQUEIDENTIFIER,
@Name_c10125d5 NVARCHAR(255),
@DisplayName_c10125d5 NVARCHAR(255),
@Description_c10125d5 NVARCHAR(MAX),
@Category_c10125d5 NVARCHAR(100),
@Type_c10125d5 NVARCHAR(100),
@Length_c10125d5 INT,
@Precision_c10125d5 INT,
@Scale_c10125d5 INT,
@AllowsNull_c10125d5 BIT,
@DefaultValue_c10125d5 NVARCHAR(255),
@IsPrimaryKey_c10125d5 BIT,
@IsUniqueKey_c10125d5 BIT,
@IsReadOnly_c10125d5 BIT,
@IsRequired_c10125d5 BIT,
@RelatedIntegrationObjectID_c10125d5 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_c10125d5 NVARCHAR(255),
@Sequence_c10125d5 INT,
@Configuration_c10125d5 NVARCHAR(MAX),
@Status_c10125d5 NVARCHAR(25),
@IsCustom_c10125d5 BIT,
@MetadataSource_c10125d5 NVARCHAR(20)
SET
  @ID_c10125d5 = 'C10125D5-33E1-5BEC-9831-B391ACE08DD1'
SET
  @IntegrationObjectID_c10125d5 = 'F45AB26D-09A1-4F8F-B185-2F567C0DD9ED'
SET
  @Name_c10125d5 = N'hs_object_id'
SET
  @Description_c10125d5 = N'HubSpot internal object ID — the system primary key, populated from the properties bag. (The top-level `id` column is not written on the connector’s sync path, so `hs_object_id` is the effective key.)'
SET
  @Type_c10125d5 = N'string'
SET
  @AllowsNull_c10125d5 = 0
SET
  @IsPrimaryKey_c10125d5 = 1
SET
  @IsUniqueKey_c10125d5 = 1
SET
  @IsReadOnly_c10125d5 = 1
SET
  @IsRequired_c10125d5 = 0
SET
  @Sequence_c10125d5 = 0
SET
  @Status_c10125d5 = N'Active'
SET
  @IsCustom_c10125d5 = 0
SET
  @MetadataSource_c10125d5 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_c10125d5,
  @IntegrationObjectID = @IntegrationObjectID_c10125d5,
  @Name = @Name_c10125d5,
  @DisplayName = @DisplayName_c10125d5,
  @DisplayName_Clear = 1,
  @Description = @Description_c10125d5,
  @Category = @Category_c10125d5,
  @Category_Clear = 1,
  @Type = @Type_c10125d5,
  @Length = @Length_c10125d5,
  @Length_Clear = 1,
  @Precision = @Precision_c10125d5,
  @Precision_Clear = 1,
  @Scale = @Scale_c10125d5,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_c10125d5,
  @DefaultValue = @DefaultValue_c10125d5,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_c10125d5,
  @IsUniqueKey = @IsUniqueKey_c10125d5,
  @IsReadOnly = @IsReadOnly_c10125d5,
  @IsRequired = @IsRequired_c10125d5,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_c10125d5,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_c10125d5,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_c10125d5,
  @Configuration = @Configuration_c10125d5,
  @Configuration_Clear = 1,
  @Status = @Status_c10125d5,
  @IsCustom = @IsCustom_c10125d5,
  @MetadataSource = @MetadataSource_c10125d5;

GO

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 0
WHERE IntegrationObjectID = 'F45AB26D-09A1-4F8F-B185-2F567C0DD9ED' AND Name = N'id' AND IsPrimaryKey = 1;

GO
