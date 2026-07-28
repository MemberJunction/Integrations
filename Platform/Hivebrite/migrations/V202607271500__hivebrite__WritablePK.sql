-- Hivebrite: the three writable objects that carried no primary key.
--
-- A writable IntegrationObject with no IsPrimaryKey field yields a KEYLESS derived entity. On
-- Postgres, MJ's save audit-wrapper then emits an empty record identifier and every save fails with
--     syntax error at or near ","
-- while fetch keeps succeeding — so the object reads green and persists nothing.
--
-- 1. GroupUsers -> STAMP the composite `group_id` + `user_id`.
--    The vendor addresses group membership as POST/DELETE /admin/v2/topics/users with the PAIR in the
--    body. Both halves are already declared AND required — "Unique Group ID" / "Unique User ID" — and
--    the pair is the membership identity. Same composite-join shape as YourMembership's MembersGroups
--    (WebSiteMemberID + GroupID); the repo already carries 102 composite-key objects, so this is the
--    house pattern rather than a new one.
--
-- 2. FundConfigurationEntity -> STAMP the composite `campaign_id` + `fund_id`.
--    One configuration row per (campaign, fund). The vendor's own path template is
--    PUT /admin/v2/donations/campaigns/{campaign_id}/funds/{fund_id} and both path variables are
--    already declared fields ("Donation Campaign associated to this Configuration" / "Donation Fund
--    associated to this Configuration").
--
-- 3. NotificationSettings -> CREATE `user_id` (Int, FK to User.id).
--    A SINGLETON per user: PUT /admin/v1/users/{user_id}/notification_settings, no collection and no
--    item id, so the user is the record identity. The 15 declared fields are all preference toggles
--    and carry no identifier of their own. Int matches User.id and the dominant Hivebrite key type
--    (68 of 77 declared keys are Int).
--
-- On a composite key each member is IsPrimaryKey = 1 but IsUniqueKey = 0 — neither half is unique on
-- its own, which is exactly how the sibling composite-key objects in this catalog are declared.
--
-- The created key is IsReadOnly = 1, matching HubSpot's V202607271200 stamp of `hs_object_id` across
-- 33 objects (functionally proven on Postgres). Read-only does not stop a KEY persisting.
--
-- DELTA migration, deliberately not a re-seed: the catalog rows already exist on installed tenants,
-- so the V202606271415 seed stays untouched and applied — no existing UUID is re-minted, no Flyway
-- checksum breaks. The UPDATEs are idempotent by WHERE. The created field carries a UUID5 ID derived
-- from uuid5(DNS, 'memberjunction.integrations/<integration>/<object>/<field>'), so regenerating this
-- file yields a byte-identical UUID rather than a fresh random one.
--
-- NOTE: the Integration row is named 'hivebrite' (lowercase) — matching the seeded identity exactly.

-- ── 1. GroupUsers: composite (group_id, user_id) ─────────────────────────────
UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 1,
    IsUniqueKey  = 0,
    IsRequired   = 1,
    AllowsNull   = 0
WHERE Name = 'group_id'
  AND IntegrationObjectID IN (
      SELECT o.ID
      FROM [__mj].IntegrationObject o
      INNER JOIN [__mj].Integration i ON i.ID = o.IntegrationID
      WHERE i.Name = 'hivebrite'
        AND o.Name = 'GroupUsers'
  );

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 1,
    IsUniqueKey  = 0,
    IsRequired   = 1,
    AllowsNull   = 0
WHERE Name = 'user_id'
  AND IntegrationObjectID IN (
      SELECT o.ID
      FROM [__mj].IntegrationObject o
      INNER JOIN [__mj].Integration i ON i.ID = o.IntegrationID
      WHERE i.Name = 'hivebrite'
        AND o.Name = 'GroupUsers'
  );

-- ── 2. FundConfigurationEntity: composite (campaign_id, fund_id) ─────────────
UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 1,
    IsUniqueKey  = 0,
    IsRequired   = 1,
    AllowsNull   = 0
WHERE Name = 'campaign_id'
  AND IntegrationObjectID IN (
      SELECT o.ID
      FROM [__mj].IntegrationObject o
      INNER JOIN [__mj].Integration i ON i.ID = o.IntegrationID
      WHERE i.Name = 'hivebrite'
        AND o.Name = 'FundConfigurationEntity'
  );

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 1,
    IsUniqueKey  = 0,
    IsRequired   = 1,
    AllowsNull   = 0
WHERE Name = 'fund_id'
  AND IntegrationObjectID IN (
      SELECT o.ID
      FROM [__mj].IntegrationObject o
      INNER JOIN [__mj].Integration i ON i.ID = o.IntegrationID
      WHERE i.Name = 'hivebrite'
        AND o.Name = 'FundConfigurationEntity'
  );

-- ── 3. NotificationSettings.user_id ──────────────────────────────────────────
DECLARE @ID_77c88ca3 UNIQUEIDENTIFIER,
@IntegrationObjectID_77c88ca3 UNIQUEIDENTIFIER,
@Name_77c88ca3 NVARCHAR(255),
@DisplayName_77c88ca3 NVARCHAR(255),
@Description_77c88ca3 NVARCHAR(MAX),
@Category_77c88ca3 NVARCHAR(100),
@Type_77c88ca3 NVARCHAR(100),
@Length_77c88ca3 INT,
@Precision_77c88ca3 INT,
@Scale_77c88ca3 INT,
@AllowsNull_77c88ca3 BIT,
@DefaultValue_77c88ca3 NVARCHAR(255),
@IsPrimaryKey_77c88ca3 BIT,
@IsUniqueKey_77c88ca3 BIT,
@IsReadOnly_77c88ca3 BIT,
@IsRequired_77c88ca3 BIT,
@RelatedIntegrationObjectID_77c88ca3 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_77c88ca3 NVARCHAR(255),
@Sequence_77c88ca3 INT,
@Configuration_77c88ca3 NVARCHAR(MAX),
@Status_77c88ca3 NVARCHAR(25),
@IsCustom_77c88ca3 BIT,
@MetadataSource_77c88ca3 NVARCHAR(20)
SET
  @ID_77c88ca3 = 'F5048683-161A-5F8A-9918-3264EFEF7E21'
SET
  @IntegrationObjectID_77c88ca3 = 'aa4a5aa7-2085-4c86-be23-fc00ee1ac0eb'
SET
  @Name_77c88ca3 = N'user_id'
SET
  @DisplayName_77c88ca3 = N'user_id'
SET
  @Description_77c88ca3 = N'The user whose notification settings these are. Hivebrite exposes the settings as a SINGLETON per user — PUT /admin/v1/users/{user_id}/notification_settings, with no collection and no item id — so the user is the record identity. The 15 declared fields are preference toggles and carry no identifier of their own.'
SET
  @Type_77c88ca3 = N'Int'
SET
  @AllowsNull_77c88ca3 = 0
SET
  @IsPrimaryKey_77c88ca3 = 1
SET
  @IsUniqueKey_77c88ca3 = 1
SET
  @IsReadOnly_77c88ca3 = 1
SET
  @IsRequired_77c88ca3 = 1
SET
  @RelatedIntegrationObjectID_77c88ca3 = '3bfd1123-f728-4150-8a51-1e3b3a6e765c'
SET
  @RelatedIntegrationObjectFieldName_77c88ca3 = N'id'
SET
  @Sequence_77c88ca3 = 0
SET
  @Configuration_77c88ca3 = N'{"ReferencedType":"User"}'
SET
  @Status_77c88ca3 = N'Active'
SET
  @IsCustom_77c88ca3 = 0
SET
  @MetadataSource_77c88ca3 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_77c88ca3,
  @IntegrationObjectID = @IntegrationObjectID_77c88ca3,
  @Name = @Name_77c88ca3,
  @DisplayName = @DisplayName_77c88ca3,
  @Description = @Description_77c88ca3,
  @Category = @Category_77c88ca3,
  @Category_Clear = 1,
  @Type = @Type_77c88ca3,
  @Length = @Length_77c88ca3,
  @Length_Clear = 1,
  @Precision = @Precision_77c88ca3,
  @Precision_Clear = 1,
  @Scale = @Scale_77c88ca3,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_77c88ca3,
  @DefaultValue = @DefaultValue_77c88ca3,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_77c88ca3,
  @IsUniqueKey = @IsUniqueKey_77c88ca3,
  @IsReadOnly = @IsReadOnly_77c88ca3,
  @IsRequired = @IsRequired_77c88ca3,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_77c88ca3,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_77c88ca3,
  @Sequence = @Sequence_77c88ca3,
  @Configuration = @Configuration_77c88ca3,
  @Status = @Status_77c88ca3,
  @IsCustom = @IsCustom_77c88ca3,
  @MetadataSource = @MetadataSource_77c88ca3;
GO
