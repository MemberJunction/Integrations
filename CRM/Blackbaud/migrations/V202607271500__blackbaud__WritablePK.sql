-- Blackbaud: the six writable objects that carried no primary key.
--
-- A writable IntegrationObject with no IsPrimaryKey field yields a KEYLESS derived entity. On
-- Postgres, MJ's save audit-wrapper then emits an empty record identifier and every save fails with
--     syntax error at or near ","
-- while fetch keeps succeeding — so the object reads green and persists nothing.
--
-- Each of the six gets the disposition its own vendor surface supports, never an invented key:
--
-- 1. profile_picture -> STAMP `constituent_id`.
--    The SKY Constituent API exposes GET and PATCH on /constituents/{constituentId}/profilepicture.
--    One picture per constituent, no item id anywhere — the constituent IS the identity, and it is
--    already a declared, populated field.
--
-- 2. acknowledgement -> CREATE `acknowledgement_id` (String).
--    SKY Gift API, changelog 2019-01-24 "Gift Acknowledgement (Edit)":
--    PATCH /giftacknowledgements/{acknowledgement_id}. The path variable names the key; the catalog
--    only ever declared the editable body (date, letter, status). String matches the other SKY Gift
--    API keys (gift.id, note.id, constituent.id).
--
-- 3. receipt -> CREATE `receipt_id` (String).
--    SKY Gift API, changelog 2019-01-16 "Gift Receipt (Edit)": PATCH /giftreceipts/{receipt_id}.
--    Same story — the catalog declared only amount/date/number/status.
--
-- 4. gift_note -> CREATE `id` (Int).
--    Blackbaud publishes GetGiftNotes / CreateGiftNote / GetGiftNoteById / EditGiftNote /
--    DeleteGiftNote, and this connector already addresses the item as
--    /nxt-data-integration/v1/re/gifts/notes/{id}. Int matches the neighbouring NXT Data Integration
--    gift objects. Mirrors the sibling `note` object exactly: collection POST, item PATCH, keyed on id.
--
-- 5. new_tax_declaration -> WITHDRAW the write; MOVE its create onto `tax_declaration`.
--    `new_tax_declaration` is the POST request-BODY shape — its 12 fields are a strict subset of
--    `tax_declaration`'s 16 — not a record: no identifier, no GET. The real resource is
--    `tax_declaration`, already keyed on declaration_id and already owning
--    GetTaxDeclaration / EditTaxDeclaration / DeleteTaxDeclaration. Rather than drop the capability,
--    CreateTaxDeclaration moves onto the keyed object, which is the shape the sibling `note` object
--    already uses.
--
-- 6. non_constituent_conversion -> WITHDRAW the write.
--    The Constituent API's ConvertToConstituent operation (/convert/{contact_id}) converts an existing
--    non-constituent INTO a constituent. Nothing named "conversion" is stored or returned — the result
--    is a constituent, which this catalog already models and keys on `id`. There is no identifier to
--    key on and the catalog declared only the request body (constituent_codes). Reads are unaffected.
--
-- Created keys are IsReadOnly = 1, matching HubSpot's V202607271200 stamp of `hs_object_id` across 33
-- objects (functionally proven on Postgres). Read-only does not stop a KEY persisting; the
-- "@courseid is not a parameter for procedure spCreateCourse_Contents" failure that Totara's
-- V202607271200 fixed was an ordinary read-only column, not a key.
--
-- DELTA migration, deliberately not a re-seed: the catalog rows already exist on installed tenants,
-- so the V202607051240 seed stays untouched and applied — no existing UUID is re-minted, no Flyway
-- checksum breaks, no UQ_IntegrationObject_Name collision. The UPDATEs are idempotent by WHERE. The
-- three created fields carry UUID5 IDs derived from
--     uuid5(DNS, 'memberjunction.integrations/<integration>/<object>/<field>')
-- so regenerating this file yields byte-identical UUIDs rather than fresh random ones.
--
-- NOTE: the Integration row is named 'blackbaud' (lowercase) — matching the seeded identity exactly.

-- ── 1. profile_picture: the constituent is the identity ──────────────────────
UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 1,
    IsUniqueKey  = 1,
    IsRequired   = 1,
    AllowsNull   = 0
WHERE Name = 'constituent_id'
  AND IntegrationObjectID IN (
      SELECT o.ID
      FROM [__mj].IntegrationObject o
      INNER JOIN [__mj].Integration i ON i.ID = o.IntegrationID
      WHERE i.Name = 'blackbaud'
        AND o.Name = 'profile_picture'
  );

-- ── 2. acknowledgement.acknowledgement_id ────────────────────────────────────
DECLARE @ID_94137487 UNIQUEIDENTIFIER,
@IntegrationObjectID_94137487 UNIQUEIDENTIFIER,
@Name_94137487 NVARCHAR(255),
@DisplayName_94137487 NVARCHAR(255),
@Description_94137487 NVARCHAR(MAX),
@Category_94137487 NVARCHAR(100),
@Type_94137487 NVARCHAR(100),
@Length_94137487 INT,
@Precision_94137487 INT,
@Scale_94137487 INT,
@AllowsNull_94137487 BIT,
@DefaultValue_94137487 NVARCHAR(255),
@IsPrimaryKey_94137487 BIT,
@IsUniqueKey_94137487 BIT,
@IsReadOnly_94137487 BIT,
@IsRequired_94137487 BIT,
@RelatedIntegrationObjectID_94137487 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_94137487 NVARCHAR(255),
@Sequence_94137487 INT,
@Configuration_94137487 NVARCHAR(MAX),
@Status_94137487 NVARCHAR(25),
@IsCustom_94137487 BIT,
@MetadataSource_94137487 NVARCHAR(20)
SET
  @ID_94137487 = 'C5DA0A51-0A39-5FAB-916D-C0C107B4BAE1'
SET
  @IntegrationObjectID_94137487 = '44CA012B-15D2-46B1-B95B-FB2BF8724505'
SET
  @Name_94137487 = N'acknowledgement_id'
SET
  @DisplayName_94137487 = N'Acknowledgement Id'
SET
  @Description_94137487 = N'The gift acknowledgement''s identifier. Blackbaud''s SKY Gift API addresses the resource as PATCH /giftacknowledgements/{acknowledgement_id} (changelog 2019-01-24, "Gift Acknowledgement (Edit)"), so the path variable is the record key. The catalog previously declared only the editable body — date, letter, status — which carries no identifier.'
SET
  @Type_94137487 = N'String'
SET
  @AllowsNull_94137487 = 0
SET
  @IsPrimaryKey_94137487 = 1
SET
  @IsUniqueKey_94137487 = 1
SET
  @IsReadOnly_94137487 = 1
SET
  @IsRequired_94137487 = 1
SET
  @Sequence_94137487 = 4
SET
  @Status_94137487 = N'Active'
SET
  @IsCustom_94137487 = 0
SET
  @MetadataSource_94137487 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_94137487,
  @IntegrationObjectID = @IntegrationObjectID_94137487,
  @Name = @Name_94137487,
  @DisplayName = @DisplayName_94137487,
  @Description = @Description_94137487,
  @Category = @Category_94137487,
  @Category_Clear = 1,
  @Type = @Type_94137487,
  @Length = @Length_94137487,
  @Length_Clear = 1,
  @Precision = @Precision_94137487,
  @Precision_Clear = 1,
  @Scale = @Scale_94137487,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_94137487,
  @DefaultValue = @DefaultValue_94137487,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_94137487,
  @IsUniqueKey = @IsUniqueKey_94137487,
  @IsReadOnly = @IsReadOnly_94137487,
  @IsRequired = @IsRequired_94137487,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_94137487,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_94137487,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_94137487,
  @Configuration = @Configuration_94137487,
  @Configuration_Clear = 1,
  @Status = @Status_94137487,
  @IsCustom = @IsCustom_94137487,
  @MetadataSource = @MetadataSource_94137487;
GO

-- ── 3. receipt.receipt_id ────────────────────────────────────────────────────
DECLARE @ID_cbef5d09 UNIQUEIDENTIFIER,
@IntegrationObjectID_cbef5d09 UNIQUEIDENTIFIER,
@Name_cbef5d09 NVARCHAR(255),
@DisplayName_cbef5d09 NVARCHAR(255),
@Description_cbef5d09 NVARCHAR(MAX),
@Category_cbef5d09 NVARCHAR(100),
@Type_cbef5d09 NVARCHAR(100),
@Length_cbef5d09 INT,
@Precision_cbef5d09 INT,
@Scale_cbef5d09 INT,
@AllowsNull_cbef5d09 BIT,
@DefaultValue_cbef5d09 NVARCHAR(255),
@IsPrimaryKey_cbef5d09 BIT,
@IsUniqueKey_cbef5d09 BIT,
@IsReadOnly_cbef5d09 BIT,
@IsRequired_cbef5d09 BIT,
@RelatedIntegrationObjectID_cbef5d09 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_cbef5d09 NVARCHAR(255),
@Sequence_cbef5d09 INT,
@Configuration_cbef5d09 NVARCHAR(MAX),
@Status_cbef5d09 NVARCHAR(25),
@IsCustom_cbef5d09 BIT,
@MetadataSource_cbef5d09 NVARCHAR(20)
SET
  @ID_cbef5d09 = '448779BF-FC7C-5F61-AA92-5BFF4312930F'
SET
  @IntegrationObjectID_cbef5d09 = 'BCC9E0E6-7476-4E0B-B251-E4C92F3939D6'
SET
  @Name_cbef5d09 = N'receipt_id'
SET
  @DisplayName_cbef5d09 = N'Receipt Id'
SET
  @Description_cbef5d09 = N'The gift receipt''s identifier. Blackbaud''s SKY Gift API addresses the resource as PATCH /giftreceipts/{receipt_id} (changelog 2019-01-16, "Gift Receipt (Edit)"), so the path variable is the record key. The catalog previously declared only the editable body — amount, date, number, status — which carries no identifier.'
SET
  @Type_cbef5d09 = N'String'
SET
  @AllowsNull_cbef5d09 = 0
SET
  @IsPrimaryKey_cbef5d09 = 1
SET
  @IsUniqueKey_cbef5d09 = 1
SET
  @IsReadOnly_cbef5d09 = 1
SET
  @IsRequired_cbef5d09 = 1
SET
  @Sequence_cbef5d09 = 5
SET
  @Status_cbef5d09 = N'Active'
SET
  @IsCustom_cbef5d09 = 0
SET
  @MetadataSource_cbef5d09 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_cbef5d09,
  @IntegrationObjectID = @IntegrationObjectID_cbef5d09,
  @Name = @Name_cbef5d09,
  @DisplayName = @DisplayName_cbef5d09,
  @Description = @Description_cbef5d09,
  @Category = @Category_cbef5d09,
  @Category_Clear = 1,
  @Type = @Type_cbef5d09,
  @Length = @Length_cbef5d09,
  @Length_Clear = 1,
  @Precision = @Precision_cbef5d09,
  @Precision_Clear = 1,
  @Scale = @Scale_cbef5d09,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_cbef5d09,
  @DefaultValue = @DefaultValue_cbef5d09,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_cbef5d09,
  @IsUniqueKey = @IsUniqueKey_cbef5d09,
  @IsReadOnly = @IsReadOnly_cbef5d09,
  @IsRequired = @IsRequired_cbef5d09,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_cbef5d09,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_cbef5d09,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_cbef5d09,
  @Configuration = @Configuration_cbef5d09,
  @Configuration_Clear = 1,
  @Status = @Status_cbef5d09,
  @IsCustom = @IsCustom_cbef5d09,
  @MetadataSource = @MetadataSource_cbef5d09;
GO

-- ── 4. gift_note.id ──────────────────────────────────────────────────────────
DECLARE @ID_80c192e3 UNIQUEIDENTIFIER,
@IntegrationObjectID_80c192e3 UNIQUEIDENTIFIER,
@Name_80c192e3 NVARCHAR(255),
@DisplayName_80c192e3 NVARCHAR(255),
@Description_80c192e3 NVARCHAR(MAX),
@Category_80c192e3 NVARCHAR(100),
@Type_80c192e3 NVARCHAR(100),
@Length_80c192e3 INT,
@Precision_80c192e3 INT,
@Scale_80c192e3 INT,
@AllowsNull_80c192e3 BIT,
@DefaultValue_80c192e3 NVARCHAR(255),
@IsPrimaryKey_80c192e3 BIT,
@IsUniqueKey_80c192e3 BIT,
@IsReadOnly_80c192e3 BIT,
@IsRequired_80c192e3 BIT,
@RelatedIntegrationObjectID_80c192e3 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_80c192e3 NVARCHAR(255),
@Sequence_80c192e3 INT,
@Configuration_80c192e3 NVARCHAR(MAX),
@Status_80c192e3 NVARCHAR(25),
@IsCustom_80c192e3 BIT,
@MetadataSource_80c192e3 NVARCHAR(20)
SET
  @ID_80c192e3 = '35262A26-FAE5-53AF-AEE3-BB3F94BC9036'
SET
  @IntegrationObjectID_80c192e3 = 'CC55644D-C3C0-4062-836A-38CAB400907A'
SET
  @Name_80c192e3 = N'id'
SET
  @DisplayName_80c192e3 = N'Id'
SET
  @Description_80c192e3 = N'The gift note''s identifier. Blackbaud publishes GetGiftNoteById / EditGiftNote / DeleteGiftNote against the item resource, and this connector already addresses it as /nxt-data-integration/v1/re/gifts/notes/{id} — the path variable is the record key. Mirrors the sibling `note` object, which is keyed on `id` with the same collection-POST / item-PATCH shape.'
SET
  @Type_80c192e3 = N'Int'
SET
  @AllowsNull_80c192e3 = 0
SET
  @IsPrimaryKey_80c192e3 = 1
SET
  @IsUniqueKey_80c192e3 = 1
SET
  @IsReadOnly_80c192e3 = 1
SET
  @IsRequired_80c192e3 = 1
SET
  @Sequence_80c192e3 = 7
SET
  @Status_80c192e3 = N'Active'
SET
  @IsCustom_80c192e3 = 0
SET
  @MetadataSource_80c192e3 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_80c192e3,
  @IntegrationObjectID = @IntegrationObjectID_80c192e3,
  @Name = @Name_80c192e3,
  @DisplayName = @DisplayName_80c192e3,
  @Description = @Description_80c192e3,
  @Category = @Category_80c192e3,
  @Category_Clear = 1,
  @Type = @Type_80c192e3,
  @Length = @Length_80c192e3,
  @Length_Clear = 1,
  @Precision = @Precision_80c192e3,
  @Precision_Clear = 1,
  @Scale = @Scale_80c192e3,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_80c192e3,
  @DefaultValue = @DefaultValue_80c192e3,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_80c192e3,
  @IsUniqueKey = @IsUniqueKey_80c192e3,
  @IsReadOnly = @IsReadOnly_80c192e3,
  @IsRequired = @IsRequired_80c192e3,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_80c192e3,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_80c192e3,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_80c192e3,
  @Configuration = @Configuration_80c192e3,
  @Configuration_Clear = 1,
  @Status = @Status_80c192e3,
  @IsCustom = @IsCustom_80c192e3,
  @MetadataSource = @MetadataSource_80c192e3;
GO

-- ── 5. move CreateTaxDeclaration onto the keyed tax_declaration, withdraw the body shape ──
UPDATE [__mj].IntegrationObject
SET CreateAPIPath  = N'/nxt-data-integration/v1/re/giftaid/taxdeclarations',
    CreateMethod   = N'POST',
    SupportsCreate = 1
WHERE ID = 'E8D9A215-D5DD-4E90-A4C2-A016EBA12F8F';

UPDATE [__mj].IntegrationObject
SET SupportsWrite  = 0,
    SupportsCreate = 0,
    Description    = N'Blackbaud RENXT NXTDataIntegration — NewTaxDeclaration Request-body shape, not a record: this is the POST payload for the vendor''s CreateTaxDeclaration operation (v1/re/giftaid/taxdeclarations) and its fields are a strict subset of the tax_declaration resource. It has no identifier and no GET. The create capability now lives on tax_declaration, which is keyed on declaration_id and already owns the edit path.'
WHERE ID = '064BB861-0996-468A-A79D-D4D56A3831F3';

-- ── 6. non_constituent_conversion: an unkeyed command, not a record ──────────────
UPDATE [__mj].IntegrationObject
SET SupportsWrite  = 0,
    SupportsCreate = 0,
    Description    = N'The non-constituent conversion object holds constituent codes to apply during the conversion. Unkeyed command, not a record: the SKY Constituent API operation ConvertToConstituent (/convert/{contact_id}) converts an existing non-constituent into a constituent. No "conversion" resource is stored or returned and there is no GET — the result is a constituent, already modelled and keyed on `id` by this catalog. The object declared only the request body.'
WHERE ID = '6DDFFCD6-DE8F-4E6D-A27E-A58FE9F9EE27';
