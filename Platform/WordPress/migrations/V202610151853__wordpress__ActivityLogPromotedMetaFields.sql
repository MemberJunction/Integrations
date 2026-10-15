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
DECLARE @ID_1341c9f3 UNIQUEIDENTIFIER,
@IntegrationObjectID_1341c9f3 UNIQUEIDENTIFIER,
@Name_1341c9f3 NVARCHAR(255),
@DisplayName_1341c9f3 NVARCHAR(255),
@Description_1341c9f3 NVARCHAR(MAX),
@Category_1341c9f3 NVARCHAR(100),
@Type_1341c9f3 NVARCHAR(100),
@Length_1341c9f3 INT,
@Precision_1341c9f3 INT,
@Scale_1341c9f3 INT,
@AllowsNull_1341c9f3 BIT,
@DefaultValue_1341c9f3 NVARCHAR(255),
@IsPrimaryKey_1341c9f3 BIT,
@IsUniqueKey_1341c9f3 BIT,
@IsReadOnly_1341c9f3 BIT,
@IsRequired_1341c9f3 BIT,
@RelatedIntegrationObjectID_1341c9f3 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_1341c9f3 NVARCHAR(255),
@Sequence_1341c9f3 INT,
@Configuration_1341c9f3 NVARCHAR(MAX),
@Status_1341c9f3 NVARCHAR(25),
@IsCustom_1341c9f3 BIT,
@MetadataSource_1341c9f3 NVARCHAR(20)
SET
  @ID_1341c9f3 = '94E6EEE2-852E-42DA-8D06-FC15D75AB562'
SET
  @IntegrationObjectID_1341c9f3 = '1B6AAA3C-002C-4E1A-8C82-0900D33FE02A'
SET
  @Name_1341c9f3 = N'ams_id'
SET
  @DisplayName_1341c9f3 = N'AMS ID'
SET
  @Description_1341c9f3 = N'The member''s ID in the association''s AMS (for example a NetForum customer key), promoted from meta.ams_id. Present only when the site''s WP Activity Log integration records it; null otherwise.'
SET
  @Type_1341c9f3 = N'String'
SET
  @Length_1341c9f3 = 100
SET
  @AllowsNull_1341c9f3 = 1
SET
  @IsPrimaryKey_1341c9f3 = 0
SET
  @IsUniqueKey_1341c9f3 = 0
SET
  @IsReadOnly_1341c9f3 = 1
SET
  @IsRequired_1341c9f3 = 0
SET
  @Sequence_1341c9f3 = 20
SET
  @Configuration_1341c9f3 = N'{
  "contexts": [
    "view"
  ],
  "promoteFrom": "meta.ams_id"
}'
SET
  @Status_1341c9f3 = N'Active'
SET
  @IsCustom_1341c9f3 = 0
SET
  @MetadataSource_1341c9f3 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_1341c9f3,
  @IntegrationObjectID = @IntegrationObjectID_1341c9f3,
  @Name = @Name_1341c9f3,
  @DisplayName = @DisplayName_1341c9f3,
  @Description = @Description_1341c9f3,
  @Category = @Category_1341c9f3,
  @Category_Clear = 1,
  @Type = @Type_1341c9f3,
  @Length = @Length_1341c9f3,
  @Precision = @Precision_1341c9f3,
  @Precision_Clear = 1,
  @Scale = @Scale_1341c9f3,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_1341c9f3,
  @DefaultValue = @DefaultValue_1341c9f3,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_1341c9f3,
  @IsUniqueKey = @IsUniqueKey_1341c9f3,
  @IsReadOnly = @IsReadOnly_1341c9f3,
  @IsRequired = @IsRequired_1341c9f3,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_1341c9f3,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_1341c9f3,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_1341c9f3,
  @Configuration = @Configuration_1341c9f3,
  @Status = @Status_1341c9f3,
  @IsCustom = @IsCustom_1341c9f3,
  @MetadataSource = @MetadataSource_1341c9f3;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_6a82f2af UNIQUEIDENTIFIER,
@IntegrationObjectID_6a82f2af UNIQUEIDENTIFIER,
@Name_6a82f2af NVARCHAR(255),
@DisplayName_6a82f2af NVARCHAR(255),
@Description_6a82f2af NVARCHAR(MAX),
@Category_6a82f2af NVARCHAR(100),
@Type_6a82f2af NVARCHAR(100),
@Length_6a82f2af INT,
@Precision_6a82f2af INT,
@Scale_6a82f2af INT,
@AllowsNull_6a82f2af BIT,
@DefaultValue_6a82f2af NVARCHAR(255),
@IsPrimaryKey_6a82f2af BIT,
@IsUniqueKey_6a82f2af BIT,
@IsReadOnly_6a82f2af BIT,
@IsRequired_6a82f2af BIT,
@RelatedIntegrationObjectID_6a82f2af UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_6a82f2af NVARCHAR(255),
@Sequence_6a82f2af INT,
@Configuration_6a82f2af NVARCHAR(MAX),
@Status_6a82f2af NVARCHAR(25),
@IsCustom_6a82f2af BIT,
@MetadataSource_6a82f2af NVARCHAR(20)
SET
  @ID_6a82f2af = 'CC8F8A7E-CACE-4C07-AE07-03E7E641FA98'
SET
  @IntegrationObjectID_6a82f2af = '1B6AAA3C-002C-4E1A-8C82-0900D33FE02A'
SET
  @Name_6a82f2af = N'post_url'
SET
  @DisplayName_6a82f2af = N'Post URL'
SET
  @Description_6a82f2af = N'Canonical URL of the post the event concerns: meta.PostUrl with HTML entities decoded and the query string and fragment removed, so it joins to a post''s link.'
SET
  @Type_6a82f2af = N'String'
SET
  @Length_6a82f2af = 2048
SET
  @AllowsNull_6a82f2af = 1
SET
  @IsPrimaryKey_6a82f2af = 0
SET
  @IsUniqueKey_6a82f2af = 0
SET
  @IsReadOnly_6a82f2af = 1
SET
  @IsRequired_6a82f2af = 0
SET
  @Sequence_6a82f2af = 21
SET
  @Configuration_6a82f2af = N'{
  "contexts": [
    "view"
  ],
  "promoteFrom": "meta.PostUrl",
  "stripQuery": true
}'
SET
  @Status_6a82f2af = N'Active'
SET
  @IsCustom_6a82f2af = 0
SET
  @MetadataSource_6a82f2af = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_6a82f2af,
  @IntegrationObjectID = @IntegrationObjectID_6a82f2af,
  @Name = @Name_6a82f2af,
  @DisplayName = @DisplayName_6a82f2af,
  @Description = @Description_6a82f2af,
  @Category = @Category_6a82f2af,
  @Category_Clear = 1,
  @Type = @Type_6a82f2af,
  @Length = @Length_6a82f2af,
  @Precision = @Precision_6a82f2af,
  @Precision_Clear = 1,
  @Scale = @Scale_6a82f2af,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_6a82f2af,
  @DefaultValue = @DefaultValue_6a82f2af,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_6a82f2af,
  @IsUniqueKey = @IsUniqueKey_6a82f2af,
  @IsReadOnly = @IsReadOnly_6a82f2af,
  @IsRequired = @IsRequired_6a82f2af,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_6a82f2af,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_6a82f2af,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_6a82f2af,
  @Configuration = @Configuration_6a82f2af,
  @Status = @Status_6a82f2af,
  @IsCustom = @IsCustom_6a82f2af,
  @MetadataSource = @MetadataSource_6a82f2af;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_b2df9e72 UNIQUEIDENTIFIER,
@IntegrationObjectID_b2df9e72 UNIQUEIDENTIFIER,
@Name_b2df9e72 NVARCHAR(255),
@DisplayName_b2df9e72 NVARCHAR(255),
@Description_b2df9e72 NVARCHAR(MAX),
@Category_b2df9e72 NVARCHAR(100),
@Type_b2df9e72 NVARCHAR(100),
@Length_b2df9e72 INT,
@Precision_b2df9e72 INT,
@Scale_b2df9e72 INT,
@AllowsNull_b2df9e72 BIT,
@DefaultValue_b2df9e72 NVARCHAR(255),
@IsPrimaryKey_b2df9e72 BIT,
@IsUniqueKey_b2df9e72 BIT,
@IsReadOnly_b2df9e72 BIT,
@IsRequired_b2df9e72 BIT,
@RelatedIntegrationObjectID_b2df9e72 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_b2df9e72 NVARCHAR(255),
@Sequence_b2df9e72 INT,
@Configuration_b2df9e72 NVARCHAR(MAX),
@Status_b2df9e72 NVARCHAR(25),
@IsCustom_b2df9e72 BIT,
@MetadataSource_b2df9e72 NVARCHAR(20)
SET
  @ID_b2df9e72 = 'B5BD2102-487D-45FD-AC6F-65E891EB76BE'
SET
  @IntegrationObjectID_b2df9e72 = '1B6AAA3C-002C-4E1A-8C82-0900D33FE02A'
SET
  @Name_b2df9e72 = N'post_url_full'
SET
  @DisplayName_b2df9e72 = N'Post URL (Full)'
SET
  @Description_b2df9e72 = N'meta.PostUrl exactly as visited, HTML entities decoded, with its query string kept (it carries campaign attribution such as utm_source).'
SET
  @Type_b2df9e72 = N'String'
SET
  @Length_b2df9e72 = 2048
SET
  @AllowsNull_b2df9e72 = 1
SET
  @IsPrimaryKey_b2df9e72 = 0
SET
  @IsUniqueKey_b2df9e72 = 0
SET
  @IsReadOnly_b2df9e72 = 1
SET
  @IsRequired_b2df9e72 = 0
SET
  @Sequence_b2df9e72 = 22
SET
  @Configuration_b2df9e72 = N'{
  "contexts": [
    "view"
  ],
  "promoteFrom": "meta.PostUrl"
}'
SET
  @Status_b2df9e72 = N'Active'
SET
  @IsCustom_b2df9e72 = 0
SET
  @MetadataSource_b2df9e72 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_b2df9e72,
  @IntegrationObjectID = @IntegrationObjectID_b2df9e72,
  @Name = @Name_b2df9e72,
  @DisplayName = @DisplayName_b2df9e72,
  @Description = @Description_b2df9e72,
  @Category = @Category_b2df9e72,
  @Category_Clear = 1,
  @Type = @Type_b2df9e72,
  @Length = @Length_b2df9e72,
  @Precision = @Precision_b2df9e72,
  @Precision_Clear = 1,
  @Scale = @Scale_b2df9e72,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_b2df9e72,
  @DefaultValue = @DefaultValue_b2df9e72,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_b2df9e72,
  @IsUniqueKey = @IsUniqueKey_b2df9e72,
  @IsReadOnly = @IsReadOnly_b2df9e72,
  @IsRequired = @IsRequired_b2df9e72,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_b2df9e72,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_b2df9e72,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_b2df9e72,
  @Configuration = @Configuration_b2df9e72,
  @Status = @Status_b2df9e72,
  @IsCustom = @IsCustom_b2df9e72,
  @MetadataSource = @MetadataSource_b2df9e72;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_e06b2c3a UNIQUEIDENTIFIER,
@IntegrationObjectID_e06b2c3a UNIQUEIDENTIFIER,
@Name_e06b2c3a NVARCHAR(255),
@DisplayName_e06b2c3a NVARCHAR(255),
@Description_e06b2c3a NVARCHAR(MAX),
@Category_e06b2c3a NVARCHAR(100),
@Type_e06b2c3a NVARCHAR(100),
@Length_e06b2c3a INT,
@Precision_e06b2c3a INT,
@Scale_e06b2c3a INT,
@AllowsNull_e06b2c3a BIT,
@DefaultValue_e06b2c3a NVARCHAR(255),
@IsPrimaryKey_e06b2c3a BIT,
@IsUniqueKey_e06b2c3a BIT,
@IsReadOnly_e06b2c3a BIT,
@IsRequired_e06b2c3a BIT,
@RelatedIntegrationObjectID_e06b2c3a UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_e06b2c3a NVARCHAR(255),
@Sequence_e06b2c3a INT,
@Configuration_e06b2c3a NVARCHAR(MAX),
@Status_e06b2c3a NVARCHAR(25),
@IsCustom_e06b2c3a BIT,
@MetadataSource_e06b2c3a NVARCHAR(20)
SET
  @ID_e06b2c3a = '8D0FDDCB-7BC3-4AA4-B0C6-A9AA74ABFB8A'
SET
  @IntegrationObjectID_e06b2c3a = '1B6AAA3C-002C-4E1A-8C82-0900D33FE02A'
SET
  @Name_e06b2c3a = N'post_title'
SET
  @DisplayName_e06b2c3a = N'Post Title'
SET
  @Description_e06b2c3a = N'Title of the post at the time of the event, promoted from meta.PostTitle with HTML entities decoded.'
SET
  @Type_e06b2c3a = N'String'
SET
  @Length_e06b2c3a = 1000
SET
  @AllowsNull_e06b2c3a = 1
SET
  @IsPrimaryKey_e06b2c3a = 0
SET
  @IsUniqueKey_e06b2c3a = 0
SET
  @IsReadOnly_e06b2c3a = 1
SET
  @IsRequired_e06b2c3a = 0
SET
  @Sequence_e06b2c3a = 23
SET
  @Configuration_e06b2c3a = N'{
  "contexts": [
    "view"
  ],
  "promoteFrom": "meta.PostTitle"
}'
SET
  @Status_e06b2c3a = N'Active'
SET
  @IsCustom_e06b2c3a = 0
SET
  @MetadataSource_e06b2c3a = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_e06b2c3a,
  @IntegrationObjectID = @IntegrationObjectID_e06b2c3a,
  @Name = @Name_e06b2c3a,
  @DisplayName = @DisplayName_e06b2c3a,
  @Description = @Description_e06b2c3a,
  @Category = @Category_e06b2c3a,
  @Category_Clear = 1,
  @Type = @Type_e06b2c3a,
  @Length = @Length_e06b2c3a,
  @Precision = @Precision_e06b2c3a,
  @Precision_Clear = 1,
  @Scale = @Scale_e06b2c3a,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_e06b2c3a,
  @DefaultValue = @DefaultValue_e06b2c3a,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_e06b2c3a,
  @IsUniqueKey = @IsUniqueKey_e06b2c3a,
  @IsReadOnly = @IsReadOnly_e06b2c3a,
  @IsRequired = @IsRequired_e06b2c3a,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_e06b2c3a,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_e06b2c3a,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_e06b2c3a,
  @Configuration = @Configuration_e06b2c3a,
  @Status = @Status_e06b2c3a,
  @IsCustom = @IsCustom_e06b2c3a,
  @MetadataSource = @MetadataSource_e06b2c3a;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_31c7b7b2 UNIQUEIDENTIFIER,
@IntegrationObjectID_31c7b7b2 UNIQUEIDENTIFIER,
@Name_31c7b7b2 NVARCHAR(255),
@DisplayName_31c7b7b2 NVARCHAR(255),
@Description_31c7b7b2 NVARCHAR(MAX),
@Category_31c7b7b2 NVARCHAR(100),
@Type_31c7b7b2 NVARCHAR(100),
@Length_31c7b7b2 INT,
@Precision_31c7b7b2 INT,
@Scale_31c7b7b2 INT,
@AllowsNull_31c7b7b2 BIT,
@DefaultValue_31c7b7b2 NVARCHAR(255),
@IsPrimaryKey_31c7b7b2 BIT,
@IsUniqueKey_31c7b7b2 BIT,
@IsReadOnly_31c7b7b2 BIT,
@IsRequired_31c7b7b2 BIT,
@RelatedIntegrationObjectID_31c7b7b2 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_31c7b7b2 NVARCHAR(255),
@Sequence_31c7b7b2 INT,
@Configuration_31c7b7b2 NVARCHAR(MAX),
@Status_31c7b7b2 NVARCHAR(25),
@IsCustom_31c7b7b2 BIT,
@MetadataSource_31c7b7b2 NVARCHAR(20)
SET
  @ID_31c7b7b2 = '6701EB96-C0A9-42FA-AF7F-A4E1C2EC500C'
SET
  @IntegrationObjectID_31c7b7b2 = '1B6AAA3C-002C-4E1A-8C82-0900D33FE02A'
SET
  @Name_31c7b7b2 = N'post_date'
SET
  @DisplayName_31c7b7b2 = N'Post Date'
SET
  @Description_31c7b7b2 = N'Publication date of the post, promoted from meta.PostDate as WP Activity Log records it (site-local time, ''YYYY-MM-DD HH:MM:SS'').'
SET
  @Type_31c7b7b2 = N'String'
SET
  @Length_31c7b7b2 = 30
SET
  @AllowsNull_31c7b7b2 = 1
SET
  @IsPrimaryKey_31c7b7b2 = 0
SET
  @IsUniqueKey_31c7b7b2 = 0
SET
  @IsReadOnly_31c7b7b2 = 1
SET
  @IsRequired_31c7b7b2 = 0
SET
  @Sequence_31c7b7b2 = 24
SET
  @Configuration_31c7b7b2 = N'{
  "contexts": [
    "view"
  ],
  "promoteFrom": "meta.PostDate"
}'
SET
  @Status_31c7b7b2 = N'Active'
SET
  @IsCustom_31c7b7b2 = 0
SET
  @MetadataSource_31c7b7b2 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_31c7b7b2,
  @IntegrationObjectID = @IntegrationObjectID_31c7b7b2,
  @Name = @Name_31c7b7b2,
  @DisplayName = @DisplayName_31c7b7b2,
  @Description = @Description_31c7b7b2,
  @Category = @Category_31c7b7b2,
  @Category_Clear = 1,
  @Type = @Type_31c7b7b2,
  @Length = @Length_31c7b7b2,
  @Precision = @Precision_31c7b7b2,
  @Precision_Clear = 1,
  @Scale = @Scale_31c7b7b2,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_31c7b7b2,
  @DefaultValue = @DefaultValue_31c7b7b2,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_31c7b7b2,
  @IsUniqueKey = @IsUniqueKey_31c7b7b2,
  @IsReadOnly = @IsReadOnly_31c7b7b2,
  @IsRequired = @IsRequired_31c7b7b2,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_31c7b7b2,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_31c7b7b2,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_31c7b7b2,
  @Configuration = @Configuration_31c7b7b2,
  @Status = @Status_31c7b7b2,
  @IsCustom = @IsCustom_31c7b7b2,
  @MetadataSource = @MetadataSource_31c7b7b2;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_e011db4e UNIQUEIDENTIFIER,
@IntegrationObjectID_e011db4e UNIQUEIDENTIFIER,
@Name_e011db4e NVARCHAR(255),
@DisplayName_e011db4e NVARCHAR(255),
@Description_e011db4e NVARCHAR(MAX),
@Category_e011db4e NVARCHAR(100),
@Type_e011db4e NVARCHAR(100),
@Length_e011db4e INT,
@Precision_e011db4e INT,
@Scale_e011db4e INT,
@AllowsNull_e011db4e BIT,
@DefaultValue_e011db4e NVARCHAR(255),
@IsPrimaryKey_e011db4e BIT,
@IsUniqueKey_e011db4e BIT,
@IsReadOnly_e011db4e BIT,
@IsRequired_e011db4e BIT,
@RelatedIntegrationObjectID_e011db4e UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_e011db4e NVARCHAR(255),
@Sequence_e011db4e INT,
@Configuration_e011db4e NVARCHAR(MAX),
@Status_e011db4e NVARCHAR(25),
@IsCustom_e011db4e BIT,
@MetadataSource_e011db4e NVARCHAR(20)
SET
  @ID_e011db4e = '5813E24E-EF72-4195-B8D6-D19D24307721'
SET
  @IntegrationObjectID_e011db4e = '1B6AAA3C-002C-4E1A-8C82-0900D33FE02A'
SET
  @Name_e011db4e = N'editor_link'
SET
  @DisplayName_e011db4e = N'Editor Link'
SET
  @Description_e011db4e = N'wp-admin edit link for the post, promoted from meta.EditorLinkPost with HTML entities decoded.'
SET
  @Type_e011db4e = N'String'
SET
  @Length_e011db4e = 2048
SET
  @AllowsNull_e011db4e = 1
SET
  @IsPrimaryKey_e011db4e = 0
SET
  @IsUniqueKey_e011db4e = 0
SET
  @IsReadOnly_e011db4e = 1
SET
  @IsRequired_e011db4e = 0
SET
  @Sequence_e011db4e = 25
SET
  @Configuration_e011db4e = N'{
  "contexts": [
    "view"
  ],
  "promoteFrom": "meta.EditorLinkPost"
}'
SET
  @Status_e011db4e = N'Active'
SET
  @IsCustom_e011db4e = 0
SET
  @MetadataSource_e011db4e = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_e011db4e,
  @IntegrationObjectID = @IntegrationObjectID_e011db4e,
  @Name = @Name_e011db4e,
  @DisplayName = @DisplayName_e011db4e,
  @Description = @Description_e011db4e,
  @Category = @Category_e011db4e,
  @Category_Clear = 1,
  @Type = @Type_e011db4e,
  @Length = @Length_e011db4e,
  @Precision = @Precision_e011db4e,
  @Precision_Clear = 1,
  @Scale = @Scale_e011db4e,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_e011db4e,
  @DefaultValue = @DefaultValue_e011db4e,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_e011db4e,
  @IsUniqueKey = @IsUniqueKey_e011db4e,
  @IsReadOnly = @IsReadOnly_e011db4e,
  @IsRequired = @IsRequired_e011db4e,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_e011db4e,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_e011db4e,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_e011db4e,
  @Configuration = @Configuration_e011db4e,
  @Status = @Status_e011db4e,
  @IsCustom = @IsCustom_e011db4e,
  @MetadataSource = @MetadataSource_e011db4e;

GO
