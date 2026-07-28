-- Cvent: the four writable objects that carried no primary key.
--
-- A writable IntegrationObject with no IsPrimaryKey field yields a KEYLESS derived entity. On
-- Postgres, MJ's save audit-wrapper then emits an empty record identifier and every save fails with
--     syntax error at or near ","
-- while fetch keeps succeeding — so the object reads green and persists nothing.
--
-- 1. event-feature -> STAMP `type`.
--    The vendor addresses one feature as PUT /events/{id}/features/{type}. `type` is that path
--    variable, already declared and already required. Cvent's house pattern throughout this catalog
--    is that a parent-scoped child keys on its OWN item token, never on the parent — e.g.
--    existing-seat under /events/{id}/seatings/{seatingId}/tables/{tableId}/seats keys on `id`
--    alone. This follows it.
--
-- 2-3. session-file / speaker-file -> CREATE `id` (String, read-only).
--    Both are addressed as .../docs/{fileId} on update and delete, and neither declared the field.
--    The identical sibling shape settles what {fileId} is: program-item-session-document
--    (/program-items/{programItemId}/docs, item /docs/{fileId}) declares `id` — "ID of the session
--    document" — String, read-only, primary key; so does existing-file
--    (/events/{id}/exhibitors/{exhibitorId}/files, item /files/{fileId}), "Unique ID of the file".
--    Cvent's /docs collections return an id and {fileId} is filled from it.
--
-- 4. CommunicationConfiguration -> WITHDRAW the write.
--    An account-level SINGLETON: PUT /logs/communications/configuration addresses the account's one
--    communication-compliance configuration. There is no collection, no item id, and the object
--    declares exactly one field (enabledMessageTypes) — nothing to key on, and nothing may be
--    invented. Reads are unaffected.
--
-- Created keys are IsReadOnly = 1, matching HubSpot's V202607271200 stamp of `hs_object_id` across
-- 33 objects (functionally proven on Postgres). Read-only does not stop a KEY persisting.
--
-- DELTA migration, deliberately not a re-seed: the catalog rows already exist on installed tenants,
-- so the V202606280836 seed stays untouched and applied — no existing UUID is re-minted, no Flyway
-- checksum breaks, no UQ collision. Every statement is idempotent (keyed by the seeded row ID).
-- Created fields carry UUID5 IDs derived from
--     uuid5(DNS, 'memberjunction.integrations/<integration>/<object>/<field>')
-- so regenerating this file yields byte-identical UUIDs rather than fresh random ones.

-- ── 1. event-feature: the feature type is the item token ─────────────────────
UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 1,
    IsUniqueKey  = 1,
    IsRequired   = 1,
    AllowsNull   = 0
WHERE Name = 'type'
  AND IntegrationObjectID = '92A89974-7241-47F8-A395-08D01088820C';

-- ── 2. session-file.id ───────────────────────────────────────────────────────
DECLARE @ID_246f7f69 UNIQUEIDENTIFIER,
@IntegrationObjectID_246f7f69 UNIQUEIDENTIFIER,
@Name_246f7f69 NVARCHAR(255),
@DisplayName_246f7f69 NVARCHAR(255),
@Description_246f7f69 NVARCHAR(MAX),
@Category_246f7f69 NVARCHAR(100),
@Type_246f7f69 NVARCHAR(100),
@Length_246f7f69 INT,
@Precision_246f7f69 INT,
@Scale_246f7f69 INT,
@AllowsNull_246f7f69 BIT,
@DefaultValue_246f7f69 NVARCHAR(255),
@IsPrimaryKey_246f7f69 BIT,
@IsUniqueKey_246f7f69 BIT,
@IsReadOnly_246f7f69 BIT,
@IsRequired_246f7f69 BIT,
@RelatedIntegrationObjectID_246f7f69 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_246f7f69 NVARCHAR(255),
@Sequence_246f7f69 INT,
@Configuration_246f7f69 NVARCHAR(MAX),
@Status_246f7f69 NVARCHAR(25),
@IsCustom_246f7f69 BIT,
@MetadataSource_246f7f69 NVARCHAR(20)
SET
  @ID_246f7f69 = '2D77A962-E6C1-5E19-AAC0-C1EE2A273037'
SET
  @IntegrationObjectID_246f7f69 = 'FE29F846-599E-49EB-99F0-54FA71722F68'
SET
  @Name_246f7f69 = N'id'
SET
  @Description_246f7f69 = N'Unique ID of the file. Fills the {fileId} path variable on update/delete.'
SET
  @Type_246f7f69 = N'String'
SET
  @AllowsNull_246f7f69 = 0
SET
  @IsPrimaryKey_246f7f69 = 1
SET
  @IsUniqueKey_246f7f69 = 1
SET
  @IsReadOnly_246f7f69 = 1
SET
  @IsRequired_246f7f69 = 0
SET
  @Sequence_246f7f69 = 0
SET
  @Status_246f7f69 = N'Active'
SET
  @IsCustom_246f7f69 = 0
SET
  @MetadataSource_246f7f69 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_246f7f69,
  @IntegrationObjectID = @IntegrationObjectID_246f7f69,
  @Name = @Name_246f7f69,
  @DisplayName = @DisplayName_246f7f69,
  @DisplayName_Clear = 1,
  @Description = @Description_246f7f69,
  @Category = @Category_246f7f69,
  @Category_Clear = 1,
  @Type = @Type_246f7f69,
  @Length = @Length_246f7f69,
  @Length_Clear = 1,
  @Precision = @Precision_246f7f69,
  @Precision_Clear = 1,
  @Scale = @Scale_246f7f69,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_246f7f69,
  @DefaultValue = @DefaultValue_246f7f69,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_246f7f69,
  @IsUniqueKey = @IsUniqueKey_246f7f69,
  @IsReadOnly = @IsReadOnly_246f7f69,
  @IsRequired = @IsRequired_246f7f69,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_246f7f69,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_246f7f69,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_246f7f69,
  @Configuration = @Configuration_246f7f69,
  @Configuration_Clear = 1,
  @Status = @Status_246f7f69,
  @IsCustom = @IsCustom_246f7f69,
  @MetadataSource = @MetadataSource_246f7f69;
GO

-- ── 3. speaker-file.id ───────────────────────────────────────────────────────
DECLARE @ID_f4d367fd UNIQUEIDENTIFIER,
@IntegrationObjectID_f4d367fd UNIQUEIDENTIFIER,
@Name_f4d367fd NVARCHAR(255),
@DisplayName_f4d367fd NVARCHAR(255),
@Description_f4d367fd NVARCHAR(MAX),
@Category_f4d367fd NVARCHAR(100),
@Type_f4d367fd NVARCHAR(100),
@Length_f4d367fd INT,
@Precision_f4d367fd INT,
@Scale_f4d367fd INT,
@AllowsNull_f4d367fd BIT,
@DefaultValue_f4d367fd NVARCHAR(255),
@IsPrimaryKey_f4d367fd BIT,
@IsUniqueKey_f4d367fd BIT,
@IsReadOnly_f4d367fd BIT,
@IsRequired_f4d367fd BIT,
@RelatedIntegrationObjectID_f4d367fd UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_f4d367fd NVARCHAR(255),
@Sequence_f4d367fd INT,
@Configuration_f4d367fd NVARCHAR(MAX),
@Status_f4d367fd NVARCHAR(25),
@IsCustom_f4d367fd BIT,
@MetadataSource_f4d367fd NVARCHAR(20)
SET
  @ID_f4d367fd = '8557A9B8-13DC-51F1-A49F-D2C2F79623B6'
SET
  @IntegrationObjectID_f4d367fd = 'B0E59299-939E-407F-B302-546356E63888'
SET
  @Name_f4d367fd = N'id'
SET
  @Description_f4d367fd = N'Unique ID of the file. Fills the {fileId} path variable on update/delete.'
SET
  @Type_f4d367fd = N'String'
SET
  @AllowsNull_f4d367fd = 0
SET
  @IsPrimaryKey_f4d367fd = 1
SET
  @IsUniqueKey_f4d367fd = 1
SET
  @IsReadOnly_f4d367fd = 1
SET
  @IsRequired_f4d367fd = 0
SET
  @Sequence_f4d367fd = 0
SET
  @Status_f4d367fd = N'Active'
SET
  @IsCustom_f4d367fd = 0
SET
  @MetadataSource_f4d367fd = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_f4d367fd,
  @IntegrationObjectID = @IntegrationObjectID_f4d367fd,
  @Name = @Name_f4d367fd,
  @DisplayName = @DisplayName_f4d367fd,
  @DisplayName_Clear = 1,
  @Description = @Description_f4d367fd,
  @Category = @Category_f4d367fd,
  @Category_Clear = 1,
  @Type = @Type_f4d367fd,
  @Length = @Length_f4d367fd,
  @Length_Clear = 1,
  @Precision = @Precision_f4d367fd,
  @Precision_Clear = 1,
  @Scale = @Scale_f4d367fd,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_f4d367fd,
  @DefaultValue = @DefaultValue_f4d367fd,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_f4d367fd,
  @IsUniqueKey = @IsUniqueKey_f4d367fd,
  @IsReadOnly = @IsReadOnly_f4d367fd,
  @IsRequired = @IsRequired_f4d367fd,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_f4d367fd,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_f4d367fd,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_f4d367fd,
  @Configuration = @Configuration_f4d367fd,
  @Configuration_Clear = 1,
  @Status = @Status_f4d367fd,
  @IsCustom = @IsCustom_f4d367fd,
  @MetadataSource = @MetadataSource_f4d367fd;
GO

-- ── 4. CommunicationConfiguration: an account singleton, not a record ────────

UPDATE [__mj].IntegrationObject
SET SupportsWrite  = 0,
    SupportsCreate = 0,
    Description    = N'Communication compliance settings e.g. Configure which communication types will be tracked and logged for this account. Account-level singleton with no identifier: PUT /logs/communications/configuration addresses the account''s one configuration, and there is no collection or item id to key on. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves fail. Reads are unaffected.'
WHERE ID = 'B319ECCD-5044-49BF-B337-E134F5B710CE';
