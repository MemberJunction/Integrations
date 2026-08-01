-- Neon CRM: the six writable custom-object catalog rows that carried no primary key.
--
-- A writable IntegrationObject with no IsPrimaryKey field yields a KEYLESS derived entity. On
-- Postgres, MJ's save audit-wrapper then emits an empty record identifier and every save fails with
--     syntax error at or near ","
-- while fetch keeps succeeding — so the object reads green and persists nothing.
--
-- The Neon custom-object family models each resource TWICE: a request-BODY shape (Status=Disabled,
-- empty APIPath, Configuration.NoEnumerableEndpoint=true) and the readable record `<X>Response`
-- (Status=Active, enumerable through /customObjects, carrying the vendor's own DetailAPIPath). The
-- write capability was declared on the body shapes; the keys belong on the records.
--
-- 1-2. CustomObjectFormLayoutResponse / CustomObjectListLayoutResponse -> CREATE `id` (bigint).
--      Neon's API v2.10 release notes (2025-04-14) publish the full item surface:
--          GET | PUT/PATCH | DELETE /customObjects/{apiAlias}/formLayouts/{id}
--          GET | PUT/PATCH | DELETE /customObjects/{apiAlias}/listLayouts/{id}
--      `{id}` is the vendor's own addressing token and already appears in each object's declared
--      DetailAPIPath and DeleteAPIPath — the catalog simply never declared the field. bigint matches
--      the sibling keys in this family (CustomObjectValidatorRuleResponse.id, CustomObjectResponse
--      .objectId, CustomObjectLayoutPageItem.layoutId, CustomObjectRelation.relationId).
--
-- 3-5. CustomObjectFormLayout / CustomObjectListLayout / CustomObjectValidatorRule -> WITHDRAW write.
--      Request-body shapes, not records: Status=Disabled, no APIPath, NoEnumerableEndpoint. Each
--      one's field set is a strict SUBSET of its `<X>Response` sibling, which is the keyed record
--      the vendor addresses. Their create/update is NOT re-homed here: these rows are Disabled, so
--      the operation has never run against a tenant, and re-homing it would newly enable an
--      unverified write path — the opposite of what this migration is for. Re-homing belongs in a
--      change that can verify the request body live.
--
-- 6.   CustomObjectField -> WITHDRAW write.
--      Same request-body shape, and it has no identifier at all: the vendor addresses a field as
--      /customObjects/{idOrApiAlias}/fields/{fieldAlias}, and this shape declares no alias. Its
--      `<X>Response` sibling is NOT a faithful create target either — the Response collapses the 19
--      typed attribute variants (textAttribute, numberAttribute, dropdownAttribute, …) into a single
--      `attribute` object, so moving the create would silently change the request body.
--
-- DELTA migration, deliberately not a re-seed: the catalog rows already exist on installed tenants,
-- so the V202606271401 seed stays untouched and applied — no existing UUID is re-minted, no Flyway
-- checksum breaks, no UQ collision. Every statement is idempotent (keyed by the seeded row ID).
-- Created fields carry UUID5 IDs derived from
--     uuid5(DNS, 'memberjunction.integrations/<integration>/<object>/<field>')
-- so regenerating this file yields byte-identical UUIDs rather than fresh random ones.

-- ── 1. CustomObjectFormLayoutResponse.id ─────────────────────────────────────
DECLARE @ID_9f96c423 UNIQUEIDENTIFIER,
@IntegrationObjectID_9f96c423 UNIQUEIDENTIFIER,
@Name_9f96c423 NVARCHAR(255),
@DisplayName_9f96c423 NVARCHAR(255),
@Description_9f96c423 NVARCHAR(MAX),
@Category_9f96c423 NVARCHAR(100),
@Type_9f96c423 NVARCHAR(100),
@Length_9f96c423 INT,
@Precision_9f96c423 INT,
@Scale_9f96c423 INT,
@AllowsNull_9f96c423 BIT,
@DefaultValue_9f96c423 NVARCHAR(255),
@IsPrimaryKey_9f96c423 BIT,
@IsUniqueKey_9f96c423 BIT,
@IsReadOnly_9f96c423 BIT,
@IsRequired_9f96c423 BIT,
@RelatedIntegrationObjectID_9f96c423 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_9f96c423 NVARCHAR(255),
@Sequence_9f96c423 INT,
@Configuration_9f96c423 NVARCHAR(MAX),
@Status_9f96c423 NVARCHAR(25),
@IsCustom_9f96c423 BIT,
@MetadataSource_9f96c423 NVARCHAR(20)
SET
  @ID_9f96c423 = '0175F819-5419-5FC1-9896-DB6D5828BA15'
SET
  @IntegrationObjectID_9f96c423 = '28EEA466-FF9F-4E7F-8A28-A6C36F095DCF'
SET
  @Name_9f96c423 = N'id'
SET
  @Type_9f96c423 = N'bigint'
SET
  @AllowsNull_9f96c423 = 0
SET
  @IsPrimaryKey_9f96c423 = 1
SET
  @IsUniqueKey_9f96c423 = 1
SET
  @IsReadOnly_9f96c423 = 0
SET
  @IsRequired_9f96c423 = 0
SET
  @Sequence_9f96c423 = 0
SET
  @Status_9f96c423 = N'Active'
SET
  @IsCustom_9f96c423 = 0
SET
  @MetadataSource_9f96c423 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_9f96c423,
  @IntegrationObjectID = @IntegrationObjectID_9f96c423,
  @Name = @Name_9f96c423,
  @DisplayName = @DisplayName_9f96c423,
  @DisplayName_Clear = 1,
  @Description = @Description_9f96c423,
  @Description_Clear = 1,
  @Category = @Category_9f96c423,
  @Category_Clear = 1,
  @Type = @Type_9f96c423,
  @Length = @Length_9f96c423,
  @Length_Clear = 1,
  @Precision = @Precision_9f96c423,
  @Precision_Clear = 1,
  @Scale = @Scale_9f96c423,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_9f96c423,
  @DefaultValue = @DefaultValue_9f96c423,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_9f96c423,
  @IsUniqueKey = @IsUniqueKey_9f96c423,
  @IsReadOnly = @IsReadOnly_9f96c423,
  @IsRequired = @IsRequired_9f96c423,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_9f96c423,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_9f96c423,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_9f96c423,
  @Configuration = @Configuration_9f96c423,
  @Configuration_Clear = 1,
  @Status = @Status_9f96c423,
  @IsCustom = @IsCustom_9f96c423,
  @MetadataSource = @MetadataSource_9f96c423;
GO

-- ── 2. CustomObjectListLayoutResponse.id ─────────────────────────────────────
DECLARE @ID_786d5849 UNIQUEIDENTIFIER,
@IntegrationObjectID_786d5849 UNIQUEIDENTIFIER,
@Name_786d5849 NVARCHAR(255),
@DisplayName_786d5849 NVARCHAR(255),
@Description_786d5849 NVARCHAR(MAX),
@Category_786d5849 NVARCHAR(100),
@Type_786d5849 NVARCHAR(100),
@Length_786d5849 INT,
@Precision_786d5849 INT,
@Scale_786d5849 INT,
@AllowsNull_786d5849 BIT,
@DefaultValue_786d5849 NVARCHAR(255),
@IsPrimaryKey_786d5849 BIT,
@IsUniqueKey_786d5849 BIT,
@IsReadOnly_786d5849 BIT,
@IsRequired_786d5849 BIT,
@RelatedIntegrationObjectID_786d5849 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_786d5849 NVARCHAR(255),
@Sequence_786d5849 INT,
@Configuration_786d5849 NVARCHAR(MAX),
@Status_786d5849 NVARCHAR(25),
@IsCustom_786d5849 BIT,
@MetadataSource_786d5849 NVARCHAR(20)
SET
  @ID_786d5849 = '01B8BA30-E6B4-5536-8CCC-90BEAE099BFB'
SET
  @IntegrationObjectID_786d5849 = '44127914-BA0D-49FB-92BE-DAEE7008A901'
SET
  @Name_786d5849 = N'id'
SET
  @Type_786d5849 = N'bigint'
SET
  @AllowsNull_786d5849 = 0
SET
  @IsPrimaryKey_786d5849 = 1
SET
  @IsUniqueKey_786d5849 = 1
SET
  @IsReadOnly_786d5849 = 0
SET
  @IsRequired_786d5849 = 0
SET
  @Sequence_786d5849 = 0
SET
  @Status_786d5849 = N'Active'
SET
  @IsCustom_786d5849 = 0
SET
  @MetadataSource_786d5849 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_786d5849,
  @IntegrationObjectID = @IntegrationObjectID_786d5849,
  @Name = @Name_786d5849,
  @DisplayName = @DisplayName_786d5849,
  @DisplayName_Clear = 1,
  @Description = @Description_786d5849,
  @Description_Clear = 1,
  @Category = @Category_786d5849,
  @Category_Clear = 1,
  @Type = @Type_786d5849,
  @Length = @Length_786d5849,
  @Length_Clear = 1,
  @Precision = @Precision_786d5849,
  @Precision_Clear = 1,
  @Scale = @Scale_786d5849,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_786d5849,
  @DefaultValue = @DefaultValue_786d5849,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_786d5849,
  @IsUniqueKey = @IsUniqueKey_786d5849,
  @IsReadOnly = @IsReadOnly_786d5849,
  @IsRequired = @IsRequired_786d5849,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_786d5849,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_786d5849,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_786d5849,
  @Configuration = @Configuration_786d5849,
  @Configuration_Clear = 1,
  @Status = @Status_786d5849,
  @IsCustom = @IsCustom_786d5849,
  @MetadataSource = @MetadataSource_786d5849;
GO

-- ── 3-6. the four request-body shapes: withdraw the write ────────────────────

UPDATE [__mj].IntegrationObject
SET SupportsWrite  = 0,
    SupportsCreate = 0,
    SupportsUpdate = 0,
    Description    = N'Neon CRM CustomObjectFormLayout record (OpenAPI v2.11 schema CustomObjectFormLayout). Request-body shape, not a record: Status=Disabled, no APIPath, NoEnumerableEndpoint. The vendor''s layout record is CustomObjectFormLayoutResponse (keyed on id, addressed at /customObjects/{apiAlias}/formLayouts/{id}). Write withdrawn: a writable object with no primary key derives a keyless entity whose saves fail. Reads are unaffected.'
WHERE ID = 'EEB0E699-3CE4-4FE8-8B85-B773F0AC9BC1';

UPDATE [__mj].IntegrationObject
SET SupportsWrite  = 0,
    SupportsCreate = 0,
    SupportsUpdate = 0,
    Description    = N'Neon CRM CustomObjectListLayout record (OpenAPI v2.11 schema CustomObjectListLayout). Request-body shape, not a record: Status=Disabled, no APIPath, NoEnumerableEndpoint. The vendor''s layout record is CustomObjectListLayoutResponse (keyed on id, addressed at /customObjects/{apiAlias}/listLayouts/{id}). Write withdrawn: a writable object with no primary key derives a keyless entity whose saves fail. Reads are unaffected.'
WHERE ID = '4D80C446-DAEF-43AD-9AAA-359B7289885C';

UPDATE [__mj].IntegrationObject
SET SupportsWrite  = 0,
    SupportsCreate = 0,
    SupportsUpdate = 0,
    Description    = N'Neon CRM CustomObjectValidatorRule record (OpenAPI v2.11 schema CustomObjectValidatorRule). Request-body shape, not a record: Status=Disabled, no APIPath, NoEnumerableEndpoint. The vendor''s validator record is CustomObjectValidatorRuleResponse (already keyed on id, addressed at /customObjects/{idOrApiAlias}/validators/{id}). Write withdrawn: a writable object with no primary key derives a keyless entity whose saves fail. Reads are unaffected.'
WHERE ID = '6D8F2B41-8592-4B50-9DDD-79FD1A317408';

UPDATE [__mj].IntegrationObject
SET SupportsWrite  = 0,
    SupportsCreate = 0,
    Description    = N'Neon CRM CustomObjectField record (OpenAPI v2.11 schema CustomObjectField). Request-body shape, not a record: Status=Disabled, no APIPath, NoEnumerableEndpoint, and no identifier — the vendor addresses a field by {fieldAlias}, which this shape does not declare. The readable field record is CustomObjectFieldResponse (keyed on id). Write withdrawn: a writable object with no primary key derives a keyless entity whose saves fail. Reads are unaffected.'
WHERE ID = '9415F0FA-B5F3-4941-AF64-A9D187AA9B59';
