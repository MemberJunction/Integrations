-- Eventscribe Connector — key each event's records apart: an EventScope field on every active object.
--
-- All connections of one connector write into the same tables, and the engine matches an incoming row to
-- an existing one by the entity's primary key across the WHOLE table. Every key here was a Cadmium id
-- alone, so a client with one connection per product per event (SCORECARD 2025, SCORECARD 2026, ...)
-- got one row per id: the same author, presenter or exhibitor in two events became a single row holding
-- whichever event synced last.
--
-- This adds `EventScope` to each of the 22 active objects. The connector stamps it on every record it
-- reads: the connection's configured eID, or, when the connection sets none, the connection's own ID, so
-- two connections can never share a value unless they name the same event. On the 17 keyed objects it
-- joins the declared primary key, which becomes (Cadmium id, EventScope); on the five keyless objects it
-- is a plain column that enters the record's content hash. The field's Configuration carries the
-- `connectorStamped: "event-scope"` marker the connector keys on. The 16 disabled EdgeReg objects are
-- untouched.
--
-- Only new rows: no existing field changes, so nothing here can conflict with a tenant's edits. Each
-- block is in the exact form `mj sync push` emits for ../metadata (the renderer that wrote them
-- reproduces all 658 field blocks of V202608271153 byte for byte from the same metadata). IDs are
-- hardcoded; audit columns are not set.

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_c4be2d1d UNIQUEIDENTIFIER,
@IntegrationObjectID_c4be2d1d UNIQUEIDENTIFIER,
@Name_c4be2d1d NVARCHAR(255),
@DisplayName_c4be2d1d NVARCHAR(255),
@Description_c4be2d1d NVARCHAR(MAX),
@Category_c4be2d1d NVARCHAR(100),
@Type_c4be2d1d NVARCHAR(100),
@Length_c4be2d1d INT,
@Precision_c4be2d1d INT,
@Scale_c4be2d1d INT,
@AllowsNull_c4be2d1d BIT,
@DefaultValue_c4be2d1d NVARCHAR(255),
@IsPrimaryKey_c4be2d1d BIT,
@IsUniqueKey_c4be2d1d BIT,
@IsReadOnly_c4be2d1d BIT,
@IsRequired_c4be2d1d BIT,
@RelatedIntegrationObjectID_c4be2d1d UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_c4be2d1d NVARCHAR(255),
@Sequence_c4be2d1d INT,
@Configuration_c4be2d1d NVARCHAR(MAX),
@Status_c4be2d1d NVARCHAR(25),
@IsCustom_c4be2d1d BIT,
@MetadataSource_c4be2d1d NVARCHAR(20)
SET
  @ID_c4be2d1d = 'E3C185CD-EC7D-4BE6-A498-FE16FCD03B0C'
SET
  @IntegrationObjectID_c4be2d1d = '5C5C0615-17CD-4AF0-9ED0-5EC68CA5B3E5'
SET
  @Name_c4be2d1d = N'EventScope'
SET
  @DisplayName_c4be2d1d = N'Event Scope'
SET
  @Description_c4be2d1d = N'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.'
SET
  @Category_c4be2d1d = N'Identity'
SET
  @Type_c4be2d1d = N'nvarchar'
SET
  @Length_c4be2d1d = 100
SET
  @AllowsNull_c4be2d1d = 0
SET
  @IsPrimaryKey_c4be2d1d = 1
SET
  @IsUniqueKey_c4be2d1d = 0
SET
  @IsReadOnly_c4be2d1d = 1
SET
  @IsRequired_c4be2d1d = 0
SET
  @Sequence_c4be2d1d = 62
SET
  @Configuration_c4be2d1d = N'{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}'
SET
  @Status_c4be2d1d = N'Active'
SET
  @IsCustom_c4be2d1d = 0
SET
  @MetadataSource_c4be2d1d = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_c4be2d1d,
  @IntegrationObjectID = @IntegrationObjectID_c4be2d1d,
  @Name = @Name_c4be2d1d,
  @DisplayName = @DisplayName_c4be2d1d,
  @Description = @Description_c4be2d1d,
  @Category = @Category_c4be2d1d,
  @Type = @Type_c4be2d1d,
  @Length = @Length_c4be2d1d,
  @Precision = @Precision_c4be2d1d,
  @Precision_Clear = 1,
  @Scale = @Scale_c4be2d1d,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_c4be2d1d,
  @DefaultValue = @DefaultValue_c4be2d1d,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_c4be2d1d,
  @IsUniqueKey = @IsUniqueKey_c4be2d1d,
  @IsReadOnly = @IsReadOnly_c4be2d1d,
  @IsRequired = @IsRequired_c4be2d1d,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_c4be2d1d,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_c4be2d1d,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_c4be2d1d,
  @Configuration = @Configuration_c4be2d1d,
  @Status = @Status_c4be2d1d,
  @IsCustom = @IsCustom_c4be2d1d,
  @MetadataSource = @MetadataSource_c4be2d1d;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_ebc5a6a0 UNIQUEIDENTIFIER,
@IntegrationObjectID_ebc5a6a0 UNIQUEIDENTIFIER,
@Name_ebc5a6a0 NVARCHAR(255),
@DisplayName_ebc5a6a0 NVARCHAR(255),
@Description_ebc5a6a0 NVARCHAR(MAX),
@Category_ebc5a6a0 NVARCHAR(100),
@Type_ebc5a6a0 NVARCHAR(100),
@Length_ebc5a6a0 INT,
@Precision_ebc5a6a0 INT,
@Scale_ebc5a6a0 INT,
@AllowsNull_ebc5a6a0 BIT,
@DefaultValue_ebc5a6a0 NVARCHAR(255),
@IsPrimaryKey_ebc5a6a0 BIT,
@IsUniqueKey_ebc5a6a0 BIT,
@IsReadOnly_ebc5a6a0 BIT,
@IsRequired_ebc5a6a0 BIT,
@RelatedIntegrationObjectID_ebc5a6a0 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_ebc5a6a0 NVARCHAR(255),
@Sequence_ebc5a6a0 INT,
@Configuration_ebc5a6a0 NVARCHAR(MAX),
@Status_ebc5a6a0 NVARCHAR(25),
@IsCustom_ebc5a6a0 BIT,
@MetadataSource_ebc5a6a0 NVARCHAR(20)
SET
  @ID_ebc5a6a0 = '917726C7-E9CB-4FED-BB24-3BEB83EFF8C1'
SET
  @IntegrationObjectID_ebc5a6a0 = 'B55EDFE8-86D5-4BC2-BA51-2D584CA98D3A'
SET
  @Name_ebc5a6a0 = N'EventScope'
SET
  @DisplayName_ebc5a6a0 = N'Event Scope'
SET
  @Description_ebc5a6a0 = N'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.'
SET
  @Category_ebc5a6a0 = N'Identity'
SET
  @Type_ebc5a6a0 = N'nvarchar'
SET
  @Length_ebc5a6a0 = 100
SET
  @AllowsNull_ebc5a6a0 = 0
SET
  @IsPrimaryKey_ebc5a6a0 = 1
SET
  @IsUniqueKey_ebc5a6a0 = 0
SET
  @IsReadOnly_ebc5a6a0 = 1
SET
  @IsRequired_ebc5a6a0 = 0
SET
  @Sequence_ebc5a6a0 = 63
SET
  @Configuration_ebc5a6a0 = N'{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}'
SET
  @Status_ebc5a6a0 = N'Active'
SET
  @IsCustom_ebc5a6a0 = 0
SET
  @MetadataSource_ebc5a6a0 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_ebc5a6a0,
  @IntegrationObjectID = @IntegrationObjectID_ebc5a6a0,
  @Name = @Name_ebc5a6a0,
  @DisplayName = @DisplayName_ebc5a6a0,
  @Description = @Description_ebc5a6a0,
  @Category = @Category_ebc5a6a0,
  @Type = @Type_ebc5a6a0,
  @Length = @Length_ebc5a6a0,
  @Precision = @Precision_ebc5a6a0,
  @Precision_Clear = 1,
  @Scale = @Scale_ebc5a6a0,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_ebc5a6a0,
  @DefaultValue = @DefaultValue_ebc5a6a0,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_ebc5a6a0,
  @IsUniqueKey = @IsUniqueKey_ebc5a6a0,
  @IsReadOnly = @IsReadOnly_ebc5a6a0,
  @IsRequired = @IsRequired_ebc5a6a0,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_ebc5a6a0,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_ebc5a6a0,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_ebc5a6a0,
  @Configuration = @Configuration_ebc5a6a0,
  @Status = @Status_ebc5a6a0,
  @IsCustom = @IsCustom_ebc5a6a0,
  @MetadataSource = @MetadataSource_ebc5a6a0;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_877da73c UNIQUEIDENTIFIER,
@IntegrationObjectID_877da73c UNIQUEIDENTIFIER,
@Name_877da73c NVARCHAR(255),
@DisplayName_877da73c NVARCHAR(255),
@Description_877da73c NVARCHAR(MAX),
@Category_877da73c NVARCHAR(100),
@Type_877da73c NVARCHAR(100),
@Length_877da73c INT,
@Precision_877da73c INT,
@Scale_877da73c INT,
@AllowsNull_877da73c BIT,
@DefaultValue_877da73c NVARCHAR(255),
@IsPrimaryKey_877da73c BIT,
@IsUniqueKey_877da73c BIT,
@IsReadOnly_877da73c BIT,
@IsRequired_877da73c BIT,
@RelatedIntegrationObjectID_877da73c UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_877da73c NVARCHAR(255),
@Sequence_877da73c INT,
@Configuration_877da73c NVARCHAR(MAX),
@Status_877da73c NVARCHAR(25),
@IsCustom_877da73c BIT,
@MetadataSource_877da73c NVARCHAR(20)
SET
  @ID_877da73c = 'C1AAACBE-4215-4CD8-951A-A13FF8C00C8E'
SET
  @IntegrationObjectID_877da73c = '43358E6F-55C1-4D24-99B9-CCE3C79835FD'
SET
  @Name_877da73c = N'EventScope'
SET
  @DisplayName_877da73c = N'Event Scope'
SET
  @Description_877da73c = N'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.'
SET
  @Category_877da73c = N'Identity'
SET
  @Type_877da73c = N'nvarchar'
SET
  @Length_877da73c = 100
SET
  @AllowsNull_877da73c = 0
SET
  @IsPrimaryKey_877da73c = 1
SET
  @IsUniqueKey_877da73c = 0
SET
  @IsReadOnly_877da73c = 1
SET
  @IsRequired_877da73c = 0
SET
  @Sequence_877da73c = 61
SET
  @Configuration_877da73c = N'{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}'
SET
  @Status_877da73c = N'Active'
SET
  @IsCustom_877da73c = 0
SET
  @MetadataSource_877da73c = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_877da73c,
  @IntegrationObjectID = @IntegrationObjectID_877da73c,
  @Name = @Name_877da73c,
  @DisplayName = @DisplayName_877da73c,
  @Description = @Description_877da73c,
  @Category = @Category_877da73c,
  @Type = @Type_877da73c,
  @Length = @Length_877da73c,
  @Precision = @Precision_877da73c,
  @Precision_Clear = 1,
  @Scale = @Scale_877da73c,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_877da73c,
  @DefaultValue = @DefaultValue_877da73c,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_877da73c,
  @IsUniqueKey = @IsUniqueKey_877da73c,
  @IsReadOnly = @IsReadOnly_877da73c,
  @IsRequired = @IsRequired_877da73c,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_877da73c,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_877da73c,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_877da73c,
  @Configuration = @Configuration_877da73c,
  @Status = @Status_877da73c,
  @IsCustom = @IsCustom_877da73c,
  @MetadataSource = @MetadataSource_877da73c;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_65cd3c43 UNIQUEIDENTIFIER,
@IntegrationObjectID_65cd3c43 UNIQUEIDENTIFIER,
@Name_65cd3c43 NVARCHAR(255),
@DisplayName_65cd3c43 NVARCHAR(255),
@Description_65cd3c43 NVARCHAR(MAX),
@Category_65cd3c43 NVARCHAR(100),
@Type_65cd3c43 NVARCHAR(100),
@Length_65cd3c43 INT,
@Precision_65cd3c43 INT,
@Scale_65cd3c43 INT,
@AllowsNull_65cd3c43 BIT,
@DefaultValue_65cd3c43 NVARCHAR(255),
@IsPrimaryKey_65cd3c43 BIT,
@IsUniqueKey_65cd3c43 BIT,
@IsReadOnly_65cd3c43 BIT,
@IsRequired_65cd3c43 BIT,
@RelatedIntegrationObjectID_65cd3c43 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_65cd3c43 NVARCHAR(255),
@Sequence_65cd3c43 INT,
@Configuration_65cd3c43 NVARCHAR(MAX),
@Status_65cd3c43 NVARCHAR(25),
@IsCustom_65cd3c43 BIT,
@MetadataSource_65cd3c43 NVARCHAR(20)
SET
  @ID_65cd3c43 = '2F1D8C20-4300-4CBF-9E99-541945464BE2'
SET
  @IntegrationObjectID_65cd3c43 = 'AFE04BC5-FAE1-42F6-822E-90A414B2C568'
SET
  @Name_65cd3c43 = N'EventScope'
SET
  @DisplayName_65cd3c43 = N'Event Scope'
SET
  @Description_65cd3c43 = N'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.'
SET
  @Category_65cd3c43 = N'Identity'
SET
  @Type_65cd3c43 = N'nvarchar'
SET
  @Length_65cd3c43 = 100
SET
  @AllowsNull_65cd3c43 = 0
SET
  @IsPrimaryKey_65cd3c43 = 1
SET
  @IsUniqueKey_65cd3c43 = 0
SET
  @IsReadOnly_65cd3c43 = 1
SET
  @IsRequired_65cd3c43 = 0
SET
  @Sequence_65cd3c43 = 14
SET
  @Configuration_65cd3c43 = N'{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}'
SET
  @Status_65cd3c43 = N'Active'
SET
  @IsCustom_65cd3c43 = 0
SET
  @MetadataSource_65cd3c43 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_65cd3c43,
  @IntegrationObjectID = @IntegrationObjectID_65cd3c43,
  @Name = @Name_65cd3c43,
  @DisplayName = @DisplayName_65cd3c43,
  @Description = @Description_65cd3c43,
  @Category = @Category_65cd3c43,
  @Type = @Type_65cd3c43,
  @Length = @Length_65cd3c43,
  @Precision = @Precision_65cd3c43,
  @Precision_Clear = 1,
  @Scale = @Scale_65cd3c43,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_65cd3c43,
  @DefaultValue = @DefaultValue_65cd3c43,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_65cd3c43,
  @IsUniqueKey = @IsUniqueKey_65cd3c43,
  @IsReadOnly = @IsReadOnly_65cd3c43,
  @IsRequired = @IsRequired_65cd3c43,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_65cd3c43,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_65cd3c43,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_65cd3c43,
  @Configuration = @Configuration_65cd3c43,
  @Status = @Status_65cd3c43,
  @IsCustom = @IsCustom_65cd3c43,
  @MetadataSource = @MetadataSource_65cd3c43;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_5f9159a9 UNIQUEIDENTIFIER,
@IntegrationObjectID_5f9159a9 UNIQUEIDENTIFIER,
@Name_5f9159a9 NVARCHAR(255),
@DisplayName_5f9159a9 NVARCHAR(255),
@Description_5f9159a9 NVARCHAR(MAX),
@Category_5f9159a9 NVARCHAR(100),
@Type_5f9159a9 NVARCHAR(100),
@Length_5f9159a9 INT,
@Precision_5f9159a9 INT,
@Scale_5f9159a9 INT,
@AllowsNull_5f9159a9 BIT,
@DefaultValue_5f9159a9 NVARCHAR(255),
@IsPrimaryKey_5f9159a9 BIT,
@IsUniqueKey_5f9159a9 BIT,
@IsReadOnly_5f9159a9 BIT,
@IsRequired_5f9159a9 BIT,
@RelatedIntegrationObjectID_5f9159a9 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_5f9159a9 NVARCHAR(255),
@Sequence_5f9159a9 INT,
@Configuration_5f9159a9 NVARCHAR(MAX),
@Status_5f9159a9 NVARCHAR(25),
@IsCustom_5f9159a9 BIT,
@MetadataSource_5f9159a9 NVARCHAR(20)
SET
  @ID_5f9159a9 = 'AE8A0B39-84CA-4EB0-A8D7-5CD964621870'
SET
  @IntegrationObjectID_5f9159a9 = '06730837-4799-4309-8327-9C4CE283BD16'
SET
  @Name_5f9159a9 = N'EventScope'
SET
  @DisplayName_5f9159a9 = N'Event Scope'
SET
  @Description_5f9159a9 = N'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.'
SET
  @Category_5f9159a9 = N'Identity'
SET
  @Type_5f9159a9 = N'nvarchar'
SET
  @Length_5f9159a9 = 100
SET
  @AllowsNull_5f9159a9 = 0
SET
  @IsPrimaryKey_5f9159a9 = 1
SET
  @IsUniqueKey_5f9159a9 = 0
SET
  @IsReadOnly_5f9159a9 = 1
SET
  @IsRequired_5f9159a9 = 0
SET
  @Sequence_5f9159a9 = 50
SET
  @Configuration_5f9159a9 = N'{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}'
SET
  @Status_5f9159a9 = N'Active'
SET
  @IsCustom_5f9159a9 = 0
SET
  @MetadataSource_5f9159a9 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_5f9159a9,
  @IntegrationObjectID = @IntegrationObjectID_5f9159a9,
  @Name = @Name_5f9159a9,
  @DisplayName = @DisplayName_5f9159a9,
  @Description = @Description_5f9159a9,
  @Category = @Category_5f9159a9,
  @Type = @Type_5f9159a9,
  @Length = @Length_5f9159a9,
  @Precision = @Precision_5f9159a9,
  @Precision_Clear = 1,
  @Scale = @Scale_5f9159a9,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_5f9159a9,
  @DefaultValue = @DefaultValue_5f9159a9,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_5f9159a9,
  @IsUniqueKey = @IsUniqueKey_5f9159a9,
  @IsReadOnly = @IsReadOnly_5f9159a9,
  @IsRequired = @IsRequired_5f9159a9,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_5f9159a9,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_5f9159a9,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_5f9159a9,
  @Configuration = @Configuration_5f9159a9,
  @Status = @Status_5f9159a9,
  @IsCustom = @IsCustom_5f9159a9,
  @MetadataSource = @MetadataSource_5f9159a9;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_e3c316e7 UNIQUEIDENTIFIER,
@IntegrationObjectID_e3c316e7 UNIQUEIDENTIFIER,
@Name_e3c316e7 NVARCHAR(255),
@DisplayName_e3c316e7 NVARCHAR(255),
@Description_e3c316e7 NVARCHAR(MAX),
@Category_e3c316e7 NVARCHAR(100),
@Type_e3c316e7 NVARCHAR(100),
@Length_e3c316e7 INT,
@Precision_e3c316e7 INT,
@Scale_e3c316e7 INT,
@AllowsNull_e3c316e7 BIT,
@DefaultValue_e3c316e7 NVARCHAR(255),
@IsPrimaryKey_e3c316e7 BIT,
@IsUniqueKey_e3c316e7 BIT,
@IsReadOnly_e3c316e7 BIT,
@IsRequired_e3c316e7 BIT,
@RelatedIntegrationObjectID_e3c316e7 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_e3c316e7 NVARCHAR(255),
@Sequence_e3c316e7 INT,
@Configuration_e3c316e7 NVARCHAR(MAX),
@Status_e3c316e7 NVARCHAR(25),
@IsCustom_e3c316e7 BIT,
@MetadataSource_e3c316e7 NVARCHAR(20)
SET
  @ID_e3c316e7 = '0F99F63E-1695-4B35-A6A2-3EDF338D16DF'
SET
  @IntegrationObjectID_e3c316e7 = '916F3AC7-10B1-4C89-B686-09CC39130DA1'
SET
  @Name_e3c316e7 = N'EventScope'
SET
  @DisplayName_e3c316e7 = N'Event Scope'
SET
  @Description_e3c316e7 = N'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.'
SET
  @Category_e3c316e7 = N'Identity'
SET
  @Type_e3c316e7 = N'nvarchar'
SET
  @Length_e3c316e7 = 100
SET
  @AllowsNull_e3c316e7 = 0
SET
  @IsPrimaryKey_e3c316e7 = 1
SET
  @IsUniqueKey_e3c316e7 = 0
SET
  @IsReadOnly_e3c316e7 = 1
SET
  @IsRequired_e3c316e7 = 0
SET
  @Sequence_e3c316e7 = 3
SET
  @Configuration_e3c316e7 = N'{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}'
SET
  @Status_e3c316e7 = N'Active'
SET
  @IsCustom_e3c316e7 = 0
SET
  @MetadataSource_e3c316e7 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_e3c316e7,
  @IntegrationObjectID = @IntegrationObjectID_e3c316e7,
  @Name = @Name_e3c316e7,
  @DisplayName = @DisplayName_e3c316e7,
  @Description = @Description_e3c316e7,
  @Category = @Category_e3c316e7,
  @Type = @Type_e3c316e7,
  @Length = @Length_e3c316e7,
  @Precision = @Precision_e3c316e7,
  @Precision_Clear = 1,
  @Scale = @Scale_e3c316e7,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_e3c316e7,
  @DefaultValue = @DefaultValue_e3c316e7,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_e3c316e7,
  @IsUniqueKey = @IsUniqueKey_e3c316e7,
  @IsReadOnly = @IsReadOnly_e3c316e7,
  @IsRequired = @IsRequired_e3c316e7,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_e3c316e7,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_e3c316e7,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_e3c316e7,
  @Configuration = @Configuration_e3c316e7,
  @Status = @Status_e3c316e7,
  @IsCustom = @IsCustom_e3c316e7,
  @MetadataSource = @MetadataSource_e3c316e7;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_101b095a UNIQUEIDENTIFIER,
@IntegrationObjectID_101b095a UNIQUEIDENTIFIER,
@Name_101b095a NVARCHAR(255),
@DisplayName_101b095a NVARCHAR(255),
@Description_101b095a NVARCHAR(MAX),
@Category_101b095a NVARCHAR(100),
@Type_101b095a NVARCHAR(100),
@Length_101b095a INT,
@Precision_101b095a INT,
@Scale_101b095a INT,
@AllowsNull_101b095a BIT,
@DefaultValue_101b095a NVARCHAR(255),
@IsPrimaryKey_101b095a BIT,
@IsUniqueKey_101b095a BIT,
@IsReadOnly_101b095a BIT,
@IsRequired_101b095a BIT,
@RelatedIntegrationObjectID_101b095a UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_101b095a NVARCHAR(255),
@Sequence_101b095a INT,
@Configuration_101b095a NVARCHAR(MAX),
@Status_101b095a NVARCHAR(25),
@IsCustom_101b095a BIT,
@MetadataSource_101b095a NVARCHAR(20)
SET
  @ID_101b095a = '38C5477F-0D1F-4265-BB8D-840F3EA7A845'
SET
  @IntegrationObjectID_101b095a = '03357576-7ECA-438C-BF11-781F7BDE0B5C'
SET
  @Name_101b095a = N'EventScope'
SET
  @DisplayName_101b095a = N'Event Scope'
SET
  @Description_101b095a = N'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.'
SET
  @Category_101b095a = N'Identity'
SET
  @Type_101b095a = N'nvarchar'
SET
  @Length_101b095a = 100
SET
  @AllowsNull_101b095a = 0
SET
  @IsPrimaryKey_101b095a = 1
SET
  @IsUniqueKey_101b095a = 0
SET
  @IsReadOnly_101b095a = 1
SET
  @IsRequired_101b095a = 0
SET
  @Sequence_101b095a = 12
SET
  @Configuration_101b095a = N'{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}'
SET
  @Status_101b095a = N'Active'
SET
  @IsCustom_101b095a = 0
SET
  @MetadataSource_101b095a = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_101b095a,
  @IntegrationObjectID = @IntegrationObjectID_101b095a,
  @Name = @Name_101b095a,
  @DisplayName = @DisplayName_101b095a,
  @Description = @Description_101b095a,
  @Category = @Category_101b095a,
  @Type = @Type_101b095a,
  @Length = @Length_101b095a,
  @Precision = @Precision_101b095a,
  @Precision_Clear = 1,
  @Scale = @Scale_101b095a,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_101b095a,
  @DefaultValue = @DefaultValue_101b095a,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_101b095a,
  @IsUniqueKey = @IsUniqueKey_101b095a,
  @IsReadOnly = @IsReadOnly_101b095a,
  @IsRequired = @IsRequired_101b095a,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_101b095a,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_101b095a,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_101b095a,
  @Configuration = @Configuration_101b095a,
  @Status = @Status_101b095a,
  @IsCustom = @IsCustom_101b095a,
  @MetadataSource = @MetadataSource_101b095a;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_ddbda8ac UNIQUEIDENTIFIER,
@IntegrationObjectID_ddbda8ac UNIQUEIDENTIFIER,
@Name_ddbda8ac NVARCHAR(255),
@DisplayName_ddbda8ac NVARCHAR(255),
@Description_ddbda8ac NVARCHAR(MAX),
@Category_ddbda8ac NVARCHAR(100),
@Type_ddbda8ac NVARCHAR(100),
@Length_ddbda8ac INT,
@Precision_ddbda8ac INT,
@Scale_ddbda8ac INT,
@AllowsNull_ddbda8ac BIT,
@DefaultValue_ddbda8ac NVARCHAR(255),
@IsPrimaryKey_ddbda8ac BIT,
@IsUniqueKey_ddbda8ac BIT,
@IsReadOnly_ddbda8ac BIT,
@IsRequired_ddbda8ac BIT,
@RelatedIntegrationObjectID_ddbda8ac UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_ddbda8ac NVARCHAR(255),
@Sequence_ddbda8ac INT,
@Configuration_ddbda8ac NVARCHAR(MAX),
@Status_ddbda8ac NVARCHAR(25),
@IsCustom_ddbda8ac BIT,
@MetadataSource_ddbda8ac NVARCHAR(20)
SET
  @ID_ddbda8ac = '04AE6C45-D9EE-4633-AC2D-C5A70F5C0740'
SET
  @IntegrationObjectID_ddbda8ac = 'C22F436E-5B95-4CCB-A8B5-413D34F212E6'
SET
  @Name_ddbda8ac = N'EventScope'
SET
  @DisplayName_ddbda8ac = N'Event Scope'
SET
  @Description_ddbda8ac = N'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.'
SET
  @Category_ddbda8ac = N'Identity'
SET
  @Type_ddbda8ac = N'nvarchar'
SET
  @Length_ddbda8ac = 100
SET
  @AllowsNull_ddbda8ac = 0
SET
  @IsPrimaryKey_ddbda8ac = 1
SET
  @IsUniqueKey_ddbda8ac = 0
SET
  @IsReadOnly_ddbda8ac = 1
SET
  @IsRequired_ddbda8ac = 0
SET
  @Sequence_ddbda8ac = 58
SET
  @Configuration_ddbda8ac = N'{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}'
SET
  @Status_ddbda8ac = N'Active'
SET
  @IsCustom_ddbda8ac = 0
SET
  @MetadataSource_ddbda8ac = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_ddbda8ac,
  @IntegrationObjectID = @IntegrationObjectID_ddbda8ac,
  @Name = @Name_ddbda8ac,
  @DisplayName = @DisplayName_ddbda8ac,
  @Description = @Description_ddbda8ac,
  @Category = @Category_ddbda8ac,
  @Type = @Type_ddbda8ac,
  @Length = @Length_ddbda8ac,
  @Precision = @Precision_ddbda8ac,
  @Precision_Clear = 1,
  @Scale = @Scale_ddbda8ac,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_ddbda8ac,
  @DefaultValue = @DefaultValue_ddbda8ac,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_ddbda8ac,
  @IsUniqueKey = @IsUniqueKey_ddbda8ac,
  @IsReadOnly = @IsReadOnly_ddbda8ac,
  @IsRequired = @IsRequired_ddbda8ac,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_ddbda8ac,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_ddbda8ac,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_ddbda8ac,
  @Configuration = @Configuration_ddbda8ac,
  @Status = @Status_ddbda8ac,
  @IsCustom = @IsCustom_ddbda8ac,
  @MetadataSource = @MetadataSource_ddbda8ac;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_18ef1be4 UNIQUEIDENTIFIER,
@IntegrationObjectID_18ef1be4 UNIQUEIDENTIFIER,
@Name_18ef1be4 NVARCHAR(255),
@DisplayName_18ef1be4 NVARCHAR(255),
@Description_18ef1be4 NVARCHAR(MAX),
@Category_18ef1be4 NVARCHAR(100),
@Type_18ef1be4 NVARCHAR(100),
@Length_18ef1be4 INT,
@Precision_18ef1be4 INT,
@Scale_18ef1be4 INT,
@AllowsNull_18ef1be4 BIT,
@DefaultValue_18ef1be4 NVARCHAR(255),
@IsPrimaryKey_18ef1be4 BIT,
@IsUniqueKey_18ef1be4 BIT,
@IsReadOnly_18ef1be4 BIT,
@IsRequired_18ef1be4 BIT,
@RelatedIntegrationObjectID_18ef1be4 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_18ef1be4 NVARCHAR(255),
@Sequence_18ef1be4 INT,
@Configuration_18ef1be4 NVARCHAR(MAX),
@Status_18ef1be4 NVARCHAR(25),
@IsCustom_18ef1be4 BIT,
@MetadataSource_18ef1be4 NVARCHAR(20)
SET
  @ID_18ef1be4 = 'B29FE39C-91A3-48C9-B88C-3F55563317B3'
SET
  @IntegrationObjectID_18ef1be4 = '8FF8DBC7-B78A-4836-8D8E-567C30170321'
SET
  @Name_18ef1be4 = N'EventScope'
SET
  @DisplayName_18ef1be4 = N'Event Scope'
SET
  @Description_18ef1be4 = N'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.'
SET
  @Category_18ef1be4 = N'Identity'
SET
  @Type_18ef1be4 = N'nvarchar'
SET
  @Length_18ef1be4 = 100
SET
  @AllowsNull_18ef1be4 = 0
SET
  @IsPrimaryKey_18ef1be4 = 1
SET
  @IsUniqueKey_18ef1be4 = 0
SET
  @IsReadOnly_18ef1be4 = 1
SET
  @IsRequired_18ef1be4 = 0
SET
  @Sequence_18ef1be4 = 40
SET
  @Configuration_18ef1be4 = N'{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}'
SET
  @Status_18ef1be4 = N'Active'
SET
  @IsCustom_18ef1be4 = 0
SET
  @MetadataSource_18ef1be4 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_18ef1be4,
  @IntegrationObjectID = @IntegrationObjectID_18ef1be4,
  @Name = @Name_18ef1be4,
  @DisplayName = @DisplayName_18ef1be4,
  @Description = @Description_18ef1be4,
  @Category = @Category_18ef1be4,
  @Type = @Type_18ef1be4,
  @Length = @Length_18ef1be4,
  @Precision = @Precision_18ef1be4,
  @Precision_Clear = 1,
  @Scale = @Scale_18ef1be4,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_18ef1be4,
  @DefaultValue = @DefaultValue_18ef1be4,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_18ef1be4,
  @IsUniqueKey = @IsUniqueKey_18ef1be4,
  @IsReadOnly = @IsReadOnly_18ef1be4,
  @IsRequired = @IsRequired_18ef1be4,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_18ef1be4,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_18ef1be4,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_18ef1be4,
  @Configuration = @Configuration_18ef1be4,
  @Status = @Status_18ef1be4,
  @IsCustom = @IsCustom_18ef1be4,
  @MetadataSource = @MetadataSource_18ef1be4;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_c744cf90 UNIQUEIDENTIFIER,
@IntegrationObjectID_c744cf90 UNIQUEIDENTIFIER,
@Name_c744cf90 NVARCHAR(255),
@DisplayName_c744cf90 NVARCHAR(255),
@Description_c744cf90 NVARCHAR(MAX),
@Category_c744cf90 NVARCHAR(100),
@Type_c744cf90 NVARCHAR(100),
@Length_c744cf90 INT,
@Precision_c744cf90 INT,
@Scale_c744cf90 INT,
@AllowsNull_c744cf90 BIT,
@DefaultValue_c744cf90 NVARCHAR(255),
@IsPrimaryKey_c744cf90 BIT,
@IsUniqueKey_c744cf90 BIT,
@IsReadOnly_c744cf90 BIT,
@IsRequired_c744cf90 BIT,
@RelatedIntegrationObjectID_c744cf90 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_c744cf90 NVARCHAR(255),
@Sequence_c744cf90 INT,
@Configuration_c744cf90 NVARCHAR(MAX),
@Status_c744cf90 NVARCHAR(25),
@IsCustom_c744cf90 BIT,
@MetadataSource_c744cf90 NVARCHAR(20)
SET
  @ID_c744cf90 = 'EAACFA3C-0E90-406D-B66F-4433C0F13F94'
SET
  @IntegrationObjectID_c744cf90 = '6353021A-F7AA-4BF9-B406-2620EBEB517D'
SET
  @Name_c744cf90 = N'EventScope'
SET
  @DisplayName_c744cf90 = N'Event Scope'
SET
  @Description_c744cf90 = N'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.'
SET
  @Category_c744cf90 = N'Identity'
SET
  @Type_c744cf90 = N'nvarchar'
SET
  @Length_c744cf90 = 100
SET
  @AllowsNull_c744cf90 = 0
SET
  @IsPrimaryKey_c744cf90 = 1
SET
  @IsUniqueKey_c744cf90 = 0
SET
  @IsReadOnly_c744cf90 = 1
SET
  @IsRequired_c744cf90 = 0
SET
  @Sequence_c744cf90 = 37
SET
  @Configuration_c744cf90 = N'{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}'
SET
  @Status_c744cf90 = N'Active'
SET
  @IsCustom_c744cf90 = 0
SET
  @MetadataSource_c744cf90 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_c744cf90,
  @IntegrationObjectID = @IntegrationObjectID_c744cf90,
  @Name = @Name_c744cf90,
  @DisplayName = @DisplayName_c744cf90,
  @Description = @Description_c744cf90,
  @Category = @Category_c744cf90,
  @Type = @Type_c744cf90,
  @Length = @Length_c744cf90,
  @Precision = @Precision_c744cf90,
  @Precision_Clear = 1,
  @Scale = @Scale_c744cf90,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_c744cf90,
  @DefaultValue = @DefaultValue_c744cf90,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_c744cf90,
  @IsUniqueKey = @IsUniqueKey_c744cf90,
  @IsReadOnly = @IsReadOnly_c744cf90,
  @IsRequired = @IsRequired_c744cf90,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_c744cf90,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_c744cf90,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_c744cf90,
  @Configuration = @Configuration_c744cf90,
  @Status = @Status_c744cf90,
  @IsCustom = @IsCustom_c744cf90,
  @MetadataSource = @MetadataSource_c744cf90;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_ce295ae5 UNIQUEIDENTIFIER,
@IntegrationObjectID_ce295ae5 UNIQUEIDENTIFIER,
@Name_ce295ae5 NVARCHAR(255),
@DisplayName_ce295ae5 NVARCHAR(255),
@Description_ce295ae5 NVARCHAR(MAX),
@Category_ce295ae5 NVARCHAR(100),
@Type_ce295ae5 NVARCHAR(100),
@Length_ce295ae5 INT,
@Precision_ce295ae5 INT,
@Scale_ce295ae5 INT,
@AllowsNull_ce295ae5 BIT,
@DefaultValue_ce295ae5 NVARCHAR(255),
@IsPrimaryKey_ce295ae5 BIT,
@IsUniqueKey_ce295ae5 BIT,
@IsReadOnly_ce295ae5 BIT,
@IsRequired_ce295ae5 BIT,
@RelatedIntegrationObjectID_ce295ae5 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_ce295ae5 NVARCHAR(255),
@Sequence_ce295ae5 INT,
@Configuration_ce295ae5 NVARCHAR(MAX),
@Status_ce295ae5 NVARCHAR(25),
@IsCustom_ce295ae5 BIT,
@MetadataSource_ce295ae5 NVARCHAR(20)
SET
  @ID_ce295ae5 = '9FC9C447-5406-46CF-B521-4FB1CBC7CF25'
SET
  @IntegrationObjectID_ce295ae5 = '1AEF00BF-D9ED-4801-907F-CA25A3BE9FF4'
SET
  @Name_ce295ae5 = N'EventScope'
SET
  @DisplayName_ce295ae5 = N'Event Scope'
SET
  @Description_ce295ae5 = N'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.'
SET
  @Category_ce295ae5 = N'Identity'
SET
  @Type_ce295ae5 = N'nvarchar'
SET
  @Length_ce295ae5 = 100
SET
  @AllowsNull_ce295ae5 = 0
SET
  @IsPrimaryKey_ce295ae5 = 1
SET
  @IsUniqueKey_ce295ae5 = 0
SET
  @IsReadOnly_ce295ae5 = 1
SET
  @IsRequired_ce295ae5 = 0
SET
  @Sequence_ce295ae5 = 7
SET
  @Configuration_ce295ae5 = N'{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}'
SET
  @Status_ce295ae5 = N'Active'
SET
  @IsCustom_ce295ae5 = 0
SET
  @MetadataSource_ce295ae5 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_ce295ae5,
  @IntegrationObjectID = @IntegrationObjectID_ce295ae5,
  @Name = @Name_ce295ae5,
  @DisplayName = @DisplayName_ce295ae5,
  @Description = @Description_ce295ae5,
  @Category = @Category_ce295ae5,
  @Type = @Type_ce295ae5,
  @Length = @Length_ce295ae5,
  @Precision = @Precision_ce295ae5,
  @Precision_Clear = 1,
  @Scale = @Scale_ce295ae5,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_ce295ae5,
  @DefaultValue = @DefaultValue_ce295ae5,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_ce295ae5,
  @IsUniqueKey = @IsUniqueKey_ce295ae5,
  @IsReadOnly = @IsReadOnly_ce295ae5,
  @IsRequired = @IsRequired_ce295ae5,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_ce295ae5,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_ce295ae5,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_ce295ae5,
  @Configuration = @Configuration_ce295ae5,
  @Status = @Status_ce295ae5,
  @IsCustom = @IsCustom_ce295ae5,
  @MetadataSource = @MetadataSource_ce295ae5;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_b7f17f97 UNIQUEIDENTIFIER,
@IntegrationObjectID_b7f17f97 UNIQUEIDENTIFIER,
@Name_b7f17f97 NVARCHAR(255),
@DisplayName_b7f17f97 NVARCHAR(255),
@Description_b7f17f97 NVARCHAR(MAX),
@Category_b7f17f97 NVARCHAR(100),
@Type_b7f17f97 NVARCHAR(100),
@Length_b7f17f97 INT,
@Precision_b7f17f97 INT,
@Scale_b7f17f97 INT,
@AllowsNull_b7f17f97 BIT,
@DefaultValue_b7f17f97 NVARCHAR(255),
@IsPrimaryKey_b7f17f97 BIT,
@IsUniqueKey_b7f17f97 BIT,
@IsReadOnly_b7f17f97 BIT,
@IsRequired_b7f17f97 BIT,
@RelatedIntegrationObjectID_b7f17f97 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_b7f17f97 NVARCHAR(255),
@Sequence_b7f17f97 INT,
@Configuration_b7f17f97 NVARCHAR(MAX),
@Status_b7f17f97 NVARCHAR(25),
@IsCustom_b7f17f97 BIT,
@MetadataSource_b7f17f97 NVARCHAR(20)
SET
  @ID_b7f17f97 = '5CFB84AC-A638-4860-BA5F-47EC837B278F'
SET
  @IntegrationObjectID_b7f17f97 = '3BA04441-803D-4322-8082-E8B6AD04A66B'
SET
  @Name_b7f17f97 = N'EventScope'
SET
  @DisplayName_b7f17f97 = N'Event Scope'
SET
  @Description_b7f17f97 = N'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.'
SET
  @Category_b7f17f97 = N'Identity'
SET
  @Type_b7f17f97 = N'nvarchar'
SET
  @Length_b7f17f97 = 100
SET
  @AllowsNull_b7f17f97 = 0
SET
  @IsPrimaryKey_b7f17f97 = 1
SET
  @IsUniqueKey_b7f17f97 = 0
SET
  @IsReadOnly_b7f17f97 = 1
SET
  @IsRequired_b7f17f97 = 0
SET
  @Sequence_b7f17f97 = 4
SET
  @Configuration_b7f17f97 = N'{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}'
SET
  @Status_b7f17f97 = N'Active'
SET
  @IsCustom_b7f17f97 = 0
SET
  @MetadataSource_b7f17f97 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_b7f17f97,
  @IntegrationObjectID = @IntegrationObjectID_b7f17f97,
  @Name = @Name_b7f17f97,
  @DisplayName = @DisplayName_b7f17f97,
  @Description = @Description_b7f17f97,
  @Category = @Category_b7f17f97,
  @Type = @Type_b7f17f97,
  @Length = @Length_b7f17f97,
  @Precision = @Precision_b7f17f97,
  @Precision_Clear = 1,
  @Scale = @Scale_b7f17f97,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_b7f17f97,
  @DefaultValue = @DefaultValue_b7f17f97,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_b7f17f97,
  @IsUniqueKey = @IsUniqueKey_b7f17f97,
  @IsReadOnly = @IsReadOnly_b7f17f97,
  @IsRequired = @IsRequired_b7f17f97,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_b7f17f97,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_b7f17f97,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_b7f17f97,
  @Configuration = @Configuration_b7f17f97,
  @Status = @Status_b7f17f97,
  @IsCustom = @IsCustom_b7f17f97,
  @MetadataSource = @MetadataSource_b7f17f97;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_cd58aaea UNIQUEIDENTIFIER,
@IntegrationObjectID_cd58aaea UNIQUEIDENTIFIER,
@Name_cd58aaea NVARCHAR(255),
@DisplayName_cd58aaea NVARCHAR(255),
@Description_cd58aaea NVARCHAR(MAX),
@Category_cd58aaea NVARCHAR(100),
@Type_cd58aaea NVARCHAR(100),
@Length_cd58aaea INT,
@Precision_cd58aaea INT,
@Scale_cd58aaea INT,
@AllowsNull_cd58aaea BIT,
@DefaultValue_cd58aaea NVARCHAR(255),
@IsPrimaryKey_cd58aaea BIT,
@IsUniqueKey_cd58aaea BIT,
@IsReadOnly_cd58aaea BIT,
@IsRequired_cd58aaea BIT,
@RelatedIntegrationObjectID_cd58aaea UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_cd58aaea NVARCHAR(255),
@Sequence_cd58aaea INT,
@Configuration_cd58aaea NVARCHAR(MAX),
@Status_cd58aaea NVARCHAR(25),
@IsCustom_cd58aaea BIT,
@MetadataSource_cd58aaea NVARCHAR(20)
SET
  @ID_cd58aaea = 'B033CC98-1D0A-49BE-865A-8CB04F7B6D49'
SET
  @IntegrationObjectID_cd58aaea = 'BB9667F0-36BB-4519-97CE-71AE5BF5463B'
SET
  @Name_cd58aaea = N'EventScope'
SET
  @DisplayName_cd58aaea = N'Event Scope'
SET
  @Description_cd58aaea = N'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. This object declares no key, so its identity is a hash of the whole record, which includes this value.'
SET
  @Category_cd58aaea = N'Attribute'
SET
  @Type_cd58aaea = N'nvarchar'
SET
  @Length_cd58aaea = 100
SET
  @AllowsNull_cd58aaea = 0
SET
  @IsPrimaryKey_cd58aaea = 0
SET
  @IsUniqueKey_cd58aaea = 0
SET
  @IsReadOnly_cd58aaea = 1
SET
  @IsRequired_cd58aaea = 0
SET
  @Sequence_cd58aaea = 5
SET
  @Configuration_cd58aaea = N'{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}'
SET
  @Status_cd58aaea = N'Active'
SET
  @IsCustom_cd58aaea = 0
SET
  @MetadataSource_cd58aaea = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_cd58aaea,
  @IntegrationObjectID = @IntegrationObjectID_cd58aaea,
  @Name = @Name_cd58aaea,
  @DisplayName = @DisplayName_cd58aaea,
  @Description = @Description_cd58aaea,
  @Category = @Category_cd58aaea,
  @Type = @Type_cd58aaea,
  @Length = @Length_cd58aaea,
  @Precision = @Precision_cd58aaea,
  @Precision_Clear = 1,
  @Scale = @Scale_cd58aaea,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_cd58aaea,
  @DefaultValue = @DefaultValue_cd58aaea,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_cd58aaea,
  @IsUniqueKey = @IsUniqueKey_cd58aaea,
  @IsReadOnly = @IsReadOnly_cd58aaea,
  @IsRequired = @IsRequired_cd58aaea,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_cd58aaea,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_cd58aaea,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_cd58aaea,
  @Configuration = @Configuration_cd58aaea,
  @Status = @Status_cd58aaea,
  @IsCustom = @IsCustom_cd58aaea,
  @MetadataSource = @MetadataSource_cd58aaea;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_4536977e UNIQUEIDENTIFIER,
@IntegrationObjectID_4536977e UNIQUEIDENTIFIER,
@Name_4536977e NVARCHAR(255),
@DisplayName_4536977e NVARCHAR(255),
@Description_4536977e NVARCHAR(MAX),
@Category_4536977e NVARCHAR(100),
@Type_4536977e NVARCHAR(100),
@Length_4536977e INT,
@Precision_4536977e INT,
@Scale_4536977e INT,
@AllowsNull_4536977e BIT,
@DefaultValue_4536977e NVARCHAR(255),
@IsPrimaryKey_4536977e BIT,
@IsUniqueKey_4536977e BIT,
@IsReadOnly_4536977e BIT,
@IsRequired_4536977e BIT,
@RelatedIntegrationObjectID_4536977e UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_4536977e NVARCHAR(255),
@Sequence_4536977e INT,
@Configuration_4536977e NVARCHAR(MAX),
@Status_4536977e NVARCHAR(25),
@IsCustom_4536977e BIT,
@MetadataSource_4536977e NVARCHAR(20)
SET
  @ID_4536977e = 'E9D0A6DC-09E5-4279-A997-A77AC171C0A3'
SET
  @IntegrationObjectID_4536977e = 'C66CF1AA-8317-4EE8-BE27-E2987748C566'
SET
  @Name_4536977e = N'EventScope'
SET
  @DisplayName_4536977e = N'Event Scope'
SET
  @Description_4536977e = N'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. This object declares no key, so its identity is a hash of the whole record, which includes this value.'
SET
  @Category_4536977e = N'Attribute'
SET
  @Type_4536977e = N'nvarchar'
SET
  @Length_4536977e = 100
SET
  @AllowsNull_4536977e = 0
SET
  @IsPrimaryKey_4536977e = 0
SET
  @IsUniqueKey_4536977e = 0
SET
  @IsReadOnly_4536977e = 1
SET
  @IsRequired_4536977e = 0
SET
  @Sequence_4536977e = 2
SET
  @Configuration_4536977e = N'{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}'
SET
  @Status_4536977e = N'Active'
SET
  @IsCustom_4536977e = 0
SET
  @MetadataSource_4536977e = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_4536977e,
  @IntegrationObjectID = @IntegrationObjectID_4536977e,
  @Name = @Name_4536977e,
  @DisplayName = @DisplayName_4536977e,
  @Description = @Description_4536977e,
  @Category = @Category_4536977e,
  @Type = @Type_4536977e,
  @Length = @Length_4536977e,
  @Precision = @Precision_4536977e,
  @Precision_Clear = 1,
  @Scale = @Scale_4536977e,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_4536977e,
  @DefaultValue = @DefaultValue_4536977e,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_4536977e,
  @IsUniqueKey = @IsUniqueKey_4536977e,
  @IsReadOnly = @IsReadOnly_4536977e,
  @IsRequired = @IsRequired_4536977e,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_4536977e,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_4536977e,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_4536977e,
  @Configuration = @Configuration_4536977e,
  @Status = @Status_4536977e,
  @IsCustom = @IsCustom_4536977e,
  @MetadataSource = @MetadataSource_4536977e;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_447651d9 UNIQUEIDENTIFIER,
@IntegrationObjectID_447651d9 UNIQUEIDENTIFIER,
@Name_447651d9 NVARCHAR(255),
@DisplayName_447651d9 NVARCHAR(255),
@Description_447651d9 NVARCHAR(MAX),
@Category_447651d9 NVARCHAR(100),
@Type_447651d9 NVARCHAR(100),
@Length_447651d9 INT,
@Precision_447651d9 INT,
@Scale_447651d9 INT,
@AllowsNull_447651d9 BIT,
@DefaultValue_447651d9 NVARCHAR(255),
@IsPrimaryKey_447651d9 BIT,
@IsUniqueKey_447651d9 BIT,
@IsReadOnly_447651d9 BIT,
@IsRequired_447651d9 BIT,
@RelatedIntegrationObjectID_447651d9 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_447651d9 NVARCHAR(255),
@Sequence_447651d9 INT,
@Configuration_447651d9 NVARCHAR(MAX),
@Status_447651d9 NVARCHAR(25),
@IsCustom_447651d9 BIT,
@MetadataSource_447651d9 NVARCHAR(20)
SET
  @ID_447651d9 = '4115FC24-54CC-4089-914D-49FB75FFD7AE'
SET
  @IntegrationObjectID_447651d9 = '4F04433A-E002-4250-8B5D-AD0B5C91DF0D'
SET
  @Name_447651d9 = N'EventScope'
SET
  @DisplayName_447651d9 = N'Event Scope'
SET
  @Description_447651d9 = N'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.'
SET
  @Category_447651d9 = N'Identity'
SET
  @Type_447651d9 = N'nvarchar'
SET
  @Length_447651d9 = 100
SET
  @AllowsNull_447651d9 = 0
SET
  @IsPrimaryKey_447651d9 = 1
SET
  @IsUniqueKey_447651d9 = 0
SET
  @IsReadOnly_447651d9 = 1
SET
  @IsRequired_447651d9 = 0
SET
  @Sequence_447651d9 = 12
SET
  @Configuration_447651d9 = N'{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}'
SET
  @Status_447651d9 = N'Active'
SET
  @IsCustom_447651d9 = 0
SET
  @MetadataSource_447651d9 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_447651d9,
  @IntegrationObjectID = @IntegrationObjectID_447651d9,
  @Name = @Name_447651d9,
  @DisplayName = @DisplayName_447651d9,
  @Description = @Description_447651d9,
  @Category = @Category_447651d9,
  @Type = @Type_447651d9,
  @Length = @Length_447651d9,
  @Precision = @Precision_447651d9,
  @Precision_Clear = 1,
  @Scale = @Scale_447651d9,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_447651d9,
  @DefaultValue = @DefaultValue_447651d9,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_447651d9,
  @IsUniqueKey = @IsUniqueKey_447651d9,
  @IsReadOnly = @IsReadOnly_447651d9,
  @IsRequired = @IsRequired_447651d9,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_447651d9,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_447651d9,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_447651d9,
  @Configuration = @Configuration_447651d9,
  @Status = @Status_447651d9,
  @IsCustom = @IsCustom_447651d9,
  @MetadataSource = @MetadataSource_447651d9;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_ddd2623b UNIQUEIDENTIFIER,
@IntegrationObjectID_ddd2623b UNIQUEIDENTIFIER,
@Name_ddd2623b NVARCHAR(255),
@DisplayName_ddd2623b NVARCHAR(255),
@Description_ddd2623b NVARCHAR(MAX),
@Category_ddd2623b NVARCHAR(100),
@Type_ddd2623b NVARCHAR(100),
@Length_ddd2623b INT,
@Precision_ddd2623b INT,
@Scale_ddd2623b INT,
@AllowsNull_ddd2623b BIT,
@DefaultValue_ddd2623b NVARCHAR(255),
@IsPrimaryKey_ddd2623b BIT,
@IsUniqueKey_ddd2623b BIT,
@IsReadOnly_ddd2623b BIT,
@IsRequired_ddd2623b BIT,
@RelatedIntegrationObjectID_ddd2623b UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_ddd2623b NVARCHAR(255),
@Sequence_ddd2623b INT,
@Configuration_ddd2623b NVARCHAR(MAX),
@Status_ddd2623b NVARCHAR(25),
@IsCustom_ddd2623b BIT,
@MetadataSource_ddd2623b NVARCHAR(20)
SET
  @ID_ddd2623b = 'C3238A9A-94C7-42C6-8408-0DFBC5990311'
SET
  @IntegrationObjectID_ddd2623b = '6CCC8434-6A8B-402C-8543-D4F3B2A4618E'
SET
  @Name_ddd2623b = N'EventScope'
SET
  @DisplayName_ddd2623b = N'Event Scope'
SET
  @Description_ddd2623b = N'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. This object declares no key, so its identity is a hash of the whole record, which includes this value.'
SET
  @Category_ddd2623b = N'Attribute'
SET
  @Type_ddd2623b = N'nvarchar'
SET
  @Length_ddd2623b = 100
SET
  @AllowsNull_ddd2623b = 0
SET
  @IsPrimaryKey_ddd2623b = 0
SET
  @IsUniqueKey_ddd2623b = 0
SET
  @IsReadOnly_ddd2623b = 1
SET
  @IsRequired_ddd2623b = 0
SET
  @Sequence_ddd2623b = 3
SET
  @Configuration_ddd2623b = N'{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}'
SET
  @Status_ddd2623b = N'Active'
SET
  @IsCustom_ddd2623b = 0
SET
  @MetadataSource_ddd2623b = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_ddd2623b,
  @IntegrationObjectID = @IntegrationObjectID_ddd2623b,
  @Name = @Name_ddd2623b,
  @DisplayName = @DisplayName_ddd2623b,
  @Description = @Description_ddd2623b,
  @Category = @Category_ddd2623b,
  @Type = @Type_ddd2623b,
  @Length = @Length_ddd2623b,
  @Precision = @Precision_ddd2623b,
  @Precision_Clear = 1,
  @Scale = @Scale_ddd2623b,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_ddd2623b,
  @DefaultValue = @DefaultValue_ddd2623b,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_ddd2623b,
  @IsUniqueKey = @IsUniqueKey_ddd2623b,
  @IsReadOnly = @IsReadOnly_ddd2623b,
  @IsRequired = @IsRequired_ddd2623b,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_ddd2623b,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_ddd2623b,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_ddd2623b,
  @Configuration = @Configuration_ddd2623b,
  @Status = @Status_ddd2623b,
  @IsCustom = @IsCustom_ddd2623b,
  @MetadataSource = @MetadataSource_ddd2623b;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_ee6f192e UNIQUEIDENTIFIER,
@IntegrationObjectID_ee6f192e UNIQUEIDENTIFIER,
@Name_ee6f192e NVARCHAR(255),
@DisplayName_ee6f192e NVARCHAR(255),
@Description_ee6f192e NVARCHAR(MAX),
@Category_ee6f192e NVARCHAR(100),
@Type_ee6f192e NVARCHAR(100),
@Length_ee6f192e INT,
@Precision_ee6f192e INT,
@Scale_ee6f192e INT,
@AllowsNull_ee6f192e BIT,
@DefaultValue_ee6f192e NVARCHAR(255),
@IsPrimaryKey_ee6f192e BIT,
@IsUniqueKey_ee6f192e BIT,
@IsReadOnly_ee6f192e BIT,
@IsRequired_ee6f192e BIT,
@RelatedIntegrationObjectID_ee6f192e UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_ee6f192e NVARCHAR(255),
@Sequence_ee6f192e INT,
@Configuration_ee6f192e NVARCHAR(MAX),
@Status_ee6f192e NVARCHAR(25),
@IsCustom_ee6f192e BIT,
@MetadataSource_ee6f192e NVARCHAR(20)
SET
  @ID_ee6f192e = 'A6F79472-3242-4DAA-80B3-0C67A853CFED'
SET
  @IntegrationObjectID_ee6f192e = '223ADBC1-3C24-466F-BBAA-1AE56707D918'
SET
  @Name_ee6f192e = N'EventScope'
SET
  @DisplayName_ee6f192e = N'Event Scope'
SET
  @Description_ee6f192e = N'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.'
SET
  @Category_ee6f192e = N'Identity'
SET
  @Type_ee6f192e = N'nvarchar'
SET
  @Length_ee6f192e = 100
SET
  @AllowsNull_ee6f192e = 0
SET
  @IsPrimaryKey_ee6f192e = 1
SET
  @IsUniqueKey_ee6f192e = 0
SET
  @IsReadOnly_ee6f192e = 1
SET
  @IsRequired_ee6f192e = 0
SET
  @Sequence_ee6f192e = 10
SET
  @Configuration_ee6f192e = N'{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}'
SET
  @Status_ee6f192e = N'Active'
SET
  @IsCustom_ee6f192e = 0
SET
  @MetadataSource_ee6f192e = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_ee6f192e,
  @IntegrationObjectID = @IntegrationObjectID_ee6f192e,
  @Name = @Name_ee6f192e,
  @DisplayName = @DisplayName_ee6f192e,
  @Description = @Description_ee6f192e,
  @Category = @Category_ee6f192e,
  @Type = @Type_ee6f192e,
  @Length = @Length_ee6f192e,
  @Precision = @Precision_ee6f192e,
  @Precision_Clear = 1,
  @Scale = @Scale_ee6f192e,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_ee6f192e,
  @DefaultValue = @DefaultValue_ee6f192e,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_ee6f192e,
  @IsUniqueKey = @IsUniqueKey_ee6f192e,
  @IsReadOnly = @IsReadOnly_ee6f192e,
  @IsRequired = @IsRequired_ee6f192e,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_ee6f192e,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_ee6f192e,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_ee6f192e,
  @Configuration = @Configuration_ee6f192e,
  @Status = @Status_ee6f192e,
  @IsCustom = @IsCustom_ee6f192e,
  @MetadataSource = @MetadataSource_ee6f192e;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_cdb617d9 UNIQUEIDENTIFIER,
@IntegrationObjectID_cdb617d9 UNIQUEIDENTIFIER,
@Name_cdb617d9 NVARCHAR(255),
@DisplayName_cdb617d9 NVARCHAR(255),
@Description_cdb617d9 NVARCHAR(MAX),
@Category_cdb617d9 NVARCHAR(100),
@Type_cdb617d9 NVARCHAR(100),
@Length_cdb617d9 INT,
@Precision_cdb617d9 INT,
@Scale_cdb617d9 INT,
@AllowsNull_cdb617d9 BIT,
@DefaultValue_cdb617d9 NVARCHAR(255),
@IsPrimaryKey_cdb617d9 BIT,
@IsUniqueKey_cdb617d9 BIT,
@IsReadOnly_cdb617d9 BIT,
@IsRequired_cdb617d9 BIT,
@RelatedIntegrationObjectID_cdb617d9 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_cdb617d9 NVARCHAR(255),
@Sequence_cdb617d9 INT,
@Configuration_cdb617d9 NVARCHAR(MAX),
@Status_cdb617d9 NVARCHAR(25),
@IsCustom_cdb617d9 BIT,
@MetadataSource_cdb617d9 NVARCHAR(20)
SET
  @ID_cdb617d9 = '12B37D48-50F0-4ECE-A0D9-3A41EBF91716'
SET
  @IntegrationObjectID_cdb617d9 = '3B5A0CD3-AFBE-49F3-8C24-8E2603245AD5'
SET
  @Name_cdb617d9 = N'EventScope'
SET
  @DisplayName_cdb617d9 = N'Event Scope'
SET
  @Description_cdb617d9 = N'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.'
SET
  @Category_cdb617d9 = N'Identity'
SET
  @Type_cdb617d9 = N'nvarchar'
SET
  @Length_cdb617d9 = 100
SET
  @AllowsNull_cdb617d9 = 0
SET
  @IsPrimaryKey_cdb617d9 = 1
SET
  @IsUniqueKey_cdb617d9 = 0
SET
  @IsReadOnly_cdb617d9 = 1
SET
  @IsRequired_cdb617d9 = 0
SET
  @Sequence_cdb617d9 = 62
SET
  @Configuration_cdb617d9 = N'{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}'
SET
  @Status_cdb617d9 = N'Active'
SET
  @IsCustom_cdb617d9 = 0
SET
  @MetadataSource_cdb617d9 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_cdb617d9,
  @IntegrationObjectID = @IntegrationObjectID_cdb617d9,
  @Name = @Name_cdb617d9,
  @DisplayName = @DisplayName_cdb617d9,
  @Description = @Description_cdb617d9,
  @Category = @Category_cdb617d9,
  @Type = @Type_cdb617d9,
  @Length = @Length_cdb617d9,
  @Precision = @Precision_cdb617d9,
  @Precision_Clear = 1,
  @Scale = @Scale_cdb617d9,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_cdb617d9,
  @DefaultValue = @DefaultValue_cdb617d9,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_cdb617d9,
  @IsUniqueKey = @IsUniqueKey_cdb617d9,
  @IsReadOnly = @IsReadOnly_cdb617d9,
  @IsRequired = @IsRequired_cdb617d9,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_cdb617d9,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_cdb617d9,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_cdb617d9,
  @Configuration = @Configuration_cdb617d9,
  @Status = @Status_cdb617d9,
  @IsCustom = @IsCustom_cdb617d9,
  @MetadataSource = @MetadataSource_cdb617d9;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_93b9c71b UNIQUEIDENTIFIER,
@IntegrationObjectID_93b9c71b UNIQUEIDENTIFIER,
@Name_93b9c71b NVARCHAR(255),
@DisplayName_93b9c71b NVARCHAR(255),
@Description_93b9c71b NVARCHAR(MAX),
@Category_93b9c71b NVARCHAR(100),
@Type_93b9c71b NVARCHAR(100),
@Length_93b9c71b INT,
@Precision_93b9c71b INT,
@Scale_93b9c71b INT,
@AllowsNull_93b9c71b BIT,
@DefaultValue_93b9c71b NVARCHAR(255),
@IsPrimaryKey_93b9c71b BIT,
@IsUniqueKey_93b9c71b BIT,
@IsReadOnly_93b9c71b BIT,
@IsRequired_93b9c71b BIT,
@RelatedIntegrationObjectID_93b9c71b UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_93b9c71b NVARCHAR(255),
@Sequence_93b9c71b INT,
@Configuration_93b9c71b NVARCHAR(MAX),
@Status_93b9c71b NVARCHAR(25),
@IsCustom_93b9c71b BIT,
@MetadataSource_93b9c71b NVARCHAR(20)
SET
  @ID_93b9c71b = '6407BE1D-0404-42B1-8A00-378174D01F0D'
SET
  @IntegrationObjectID_93b9c71b = 'BBC39A58-D20C-4ED3-A5FB-5F8243ED71B9'
SET
  @Name_93b9c71b = N'EventScope'
SET
  @DisplayName_93b9c71b = N'Event Scope'
SET
  @Description_93b9c71b = N'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. This object declares no key, so its identity is a hash of the whole record, which includes this value.'
SET
  @Category_93b9c71b = N'Attribute'
SET
  @Type_93b9c71b = N'nvarchar'
SET
  @Length_93b9c71b = 100
SET
  @AllowsNull_93b9c71b = 0
SET
  @IsPrimaryKey_93b9c71b = 0
SET
  @IsUniqueKey_93b9c71b = 0
SET
  @IsReadOnly_93b9c71b = 1
SET
  @IsRequired_93b9c71b = 0
SET
  @Sequence_93b9c71b = 5
SET
  @Configuration_93b9c71b = N'{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}'
SET
  @Status_93b9c71b = N'Active'
SET
  @IsCustom_93b9c71b = 0
SET
  @MetadataSource_93b9c71b = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_93b9c71b,
  @IntegrationObjectID = @IntegrationObjectID_93b9c71b,
  @Name = @Name_93b9c71b,
  @DisplayName = @DisplayName_93b9c71b,
  @Description = @Description_93b9c71b,
  @Category = @Category_93b9c71b,
  @Type = @Type_93b9c71b,
  @Length = @Length_93b9c71b,
  @Precision = @Precision_93b9c71b,
  @Precision_Clear = 1,
  @Scale = @Scale_93b9c71b,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_93b9c71b,
  @DefaultValue = @DefaultValue_93b9c71b,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_93b9c71b,
  @IsUniqueKey = @IsUniqueKey_93b9c71b,
  @IsReadOnly = @IsReadOnly_93b9c71b,
  @IsRequired = @IsRequired_93b9c71b,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_93b9c71b,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_93b9c71b,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_93b9c71b,
  @Configuration = @Configuration_93b9c71b,
  @Status = @Status_93b9c71b,
  @IsCustom = @IsCustom_93b9c71b,
  @MetadataSource = @MetadataSource_93b9c71b;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_4b58b27a UNIQUEIDENTIFIER,
@IntegrationObjectID_4b58b27a UNIQUEIDENTIFIER,
@Name_4b58b27a NVARCHAR(255),
@DisplayName_4b58b27a NVARCHAR(255),
@Description_4b58b27a NVARCHAR(MAX),
@Category_4b58b27a NVARCHAR(100),
@Type_4b58b27a NVARCHAR(100),
@Length_4b58b27a INT,
@Precision_4b58b27a INT,
@Scale_4b58b27a INT,
@AllowsNull_4b58b27a BIT,
@DefaultValue_4b58b27a NVARCHAR(255),
@IsPrimaryKey_4b58b27a BIT,
@IsUniqueKey_4b58b27a BIT,
@IsReadOnly_4b58b27a BIT,
@IsRequired_4b58b27a BIT,
@RelatedIntegrationObjectID_4b58b27a UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_4b58b27a NVARCHAR(255),
@Sequence_4b58b27a INT,
@Configuration_4b58b27a NVARCHAR(MAX),
@Status_4b58b27a NVARCHAR(25),
@IsCustom_4b58b27a BIT,
@MetadataSource_4b58b27a NVARCHAR(20)
SET
  @ID_4b58b27a = '8A622AC3-974A-47F5-B0A2-3ADF28F16E63'
SET
  @IntegrationObjectID_4b58b27a = '06DC1C76-19F0-429A-977D-858A88685289'
SET
  @Name_4b58b27a = N'EventScope'
SET
  @DisplayName_4b58b27a = N'Event Scope'
SET
  @Description_4b58b27a = N'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. This object declares no key, so its identity is a hash of the whole record, which includes this value.'
SET
  @Category_4b58b27a = N'Attribute'
SET
  @Type_4b58b27a = N'nvarchar'
SET
  @Length_4b58b27a = 100
SET
  @AllowsNull_4b58b27a = 0
SET
  @IsPrimaryKey_4b58b27a = 0
SET
  @IsUniqueKey_4b58b27a = 0
SET
  @IsReadOnly_4b58b27a = 1
SET
  @IsRequired_4b58b27a = 0
SET
  @Sequence_4b58b27a = 5
SET
  @Configuration_4b58b27a = N'{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}'
SET
  @Status_4b58b27a = N'Active'
SET
  @IsCustom_4b58b27a = 0
SET
  @MetadataSource_4b58b27a = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_4b58b27a,
  @IntegrationObjectID = @IntegrationObjectID_4b58b27a,
  @Name = @Name_4b58b27a,
  @DisplayName = @DisplayName_4b58b27a,
  @Description = @Description_4b58b27a,
  @Category = @Category_4b58b27a,
  @Type = @Type_4b58b27a,
  @Length = @Length_4b58b27a,
  @Precision = @Precision_4b58b27a,
  @Precision_Clear = 1,
  @Scale = @Scale_4b58b27a,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_4b58b27a,
  @DefaultValue = @DefaultValue_4b58b27a,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_4b58b27a,
  @IsUniqueKey = @IsUniqueKey_4b58b27a,
  @IsReadOnly = @IsReadOnly_4b58b27a,
  @IsRequired = @IsRequired_4b58b27a,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_4b58b27a,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_4b58b27a,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_4b58b27a,
  @Configuration = @Configuration_4b58b27a,
  @Status = @Status_4b58b27a,
  @IsCustom = @IsCustom_4b58b27a,
  @MetadataSource = @MetadataSource_4b58b27a;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_d4037dc9 UNIQUEIDENTIFIER,
@IntegrationObjectID_d4037dc9 UNIQUEIDENTIFIER,
@Name_d4037dc9 NVARCHAR(255),
@DisplayName_d4037dc9 NVARCHAR(255),
@Description_d4037dc9 NVARCHAR(MAX),
@Category_d4037dc9 NVARCHAR(100),
@Type_d4037dc9 NVARCHAR(100),
@Length_d4037dc9 INT,
@Precision_d4037dc9 INT,
@Scale_d4037dc9 INT,
@AllowsNull_d4037dc9 BIT,
@DefaultValue_d4037dc9 NVARCHAR(255),
@IsPrimaryKey_d4037dc9 BIT,
@IsUniqueKey_d4037dc9 BIT,
@IsReadOnly_d4037dc9 BIT,
@IsRequired_d4037dc9 BIT,
@RelatedIntegrationObjectID_d4037dc9 UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_d4037dc9 NVARCHAR(255),
@Sequence_d4037dc9 INT,
@Configuration_d4037dc9 NVARCHAR(MAX),
@Status_d4037dc9 NVARCHAR(25),
@IsCustom_d4037dc9 BIT,
@MetadataSource_d4037dc9 NVARCHAR(20)
SET
  @ID_d4037dc9 = 'CCDE7666-EA93-420F-84FD-91D9FB0C4E35'
SET
  @IntegrationObjectID_d4037dc9 = '45974C8B-B879-44D4-96F9-C38F78D0AC69'
SET
  @Name_d4037dc9 = N'EventScope'
SET
  @DisplayName_d4037dc9 = N'Event Scope'
SET
  @Description_d4037dc9 = N'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.'
SET
  @Category_d4037dc9 = N'Identity'
SET
  @Type_d4037dc9 = N'nvarchar'
SET
  @Length_d4037dc9 = 100
SET
  @AllowsNull_d4037dc9 = 0
SET
  @IsPrimaryKey_d4037dc9 = 1
SET
  @IsUniqueKey_d4037dc9 = 0
SET
  @IsReadOnly_d4037dc9 = 1
SET
  @IsRequired_d4037dc9 = 0
SET
  @Sequence_d4037dc9 = 4
SET
  @Configuration_d4037dc9 = N'{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}'
SET
  @Status_d4037dc9 = N'Active'
SET
  @IsCustom_d4037dc9 = 0
SET
  @MetadataSource_d4037dc9 = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_d4037dc9,
  @IntegrationObjectID = @IntegrationObjectID_d4037dc9,
  @Name = @Name_d4037dc9,
  @DisplayName = @DisplayName_d4037dc9,
  @Description = @Description_d4037dc9,
  @Category = @Category_d4037dc9,
  @Type = @Type_d4037dc9,
  @Length = @Length_d4037dc9,
  @Precision = @Precision_d4037dc9,
  @Precision_Clear = 1,
  @Scale = @Scale_d4037dc9,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_d4037dc9,
  @DefaultValue = @DefaultValue_d4037dc9,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_d4037dc9,
  @IsUniqueKey = @IsUniqueKey_d4037dc9,
  @IsReadOnly = @IsReadOnly_d4037dc9,
  @IsRequired = @IsRequired_d4037dc9,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_d4037dc9,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_d4037dc9,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_d4037dc9,
  @Configuration = @Configuration_d4037dc9,
  @Status = @Status_d4037dc9,
  @IsCustom = @IsCustom_d4037dc9,
  @MetadataSource = @MetadataSource_d4037dc9;

GO

-- Save MJ: Integration Object Fields (core SP call only)
DECLARE @ID_be845e0b UNIQUEIDENTIFIER,
@IntegrationObjectID_be845e0b UNIQUEIDENTIFIER,
@Name_be845e0b NVARCHAR(255),
@DisplayName_be845e0b NVARCHAR(255),
@Description_be845e0b NVARCHAR(MAX),
@Category_be845e0b NVARCHAR(100),
@Type_be845e0b NVARCHAR(100),
@Length_be845e0b INT,
@Precision_be845e0b INT,
@Scale_be845e0b INT,
@AllowsNull_be845e0b BIT,
@DefaultValue_be845e0b NVARCHAR(255),
@IsPrimaryKey_be845e0b BIT,
@IsUniqueKey_be845e0b BIT,
@IsReadOnly_be845e0b BIT,
@IsRequired_be845e0b BIT,
@RelatedIntegrationObjectID_be845e0b UNIQUEIDENTIFIER,
@RelatedIntegrationObjectFieldName_be845e0b NVARCHAR(255),
@Sequence_be845e0b INT,
@Configuration_be845e0b NVARCHAR(MAX),
@Status_be845e0b NVARCHAR(25),
@IsCustom_be845e0b BIT,
@MetadataSource_be845e0b NVARCHAR(20)
SET
  @ID_be845e0b = '50B33B1B-68F3-4669-8E22-17F72B636868'
SET
  @IntegrationObjectID_be845e0b = '0ACD467E-BE5C-43CF-994B-44C211B12C08'
SET
  @Name_be845e0b = N'EventScope'
SET
  @DisplayName_be845e0b = N'Event Scope'
SET
  @Description_be845e0b = N'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.'
SET
  @Category_be845e0b = N'Identity'
SET
  @Type_be845e0b = N'nvarchar'
SET
  @Length_be845e0b = 100
SET
  @AllowsNull_be845e0b = 0
SET
  @IsPrimaryKey_be845e0b = 1
SET
  @IsUniqueKey_be845e0b = 0
SET
  @IsReadOnly_be845e0b = 1
SET
  @IsRequired_be845e0b = 0
SET
  @Sequence_be845e0b = 4
SET
  @Configuration_be845e0b = N'{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}'
SET
  @Status_be845e0b = N'Active'
SET
  @IsCustom_be845e0b = 0
SET
  @MetadataSource_be845e0b = N'Declared' EXEC [__mj].spCreateIntegrationObjectField @ID = @ID_be845e0b,
  @IntegrationObjectID = @IntegrationObjectID_be845e0b,
  @Name = @Name_be845e0b,
  @DisplayName = @DisplayName_be845e0b,
  @Description = @Description_be845e0b,
  @Category = @Category_be845e0b,
  @Type = @Type_be845e0b,
  @Length = @Length_be845e0b,
  @Precision = @Precision_be845e0b,
  @Precision_Clear = 1,
  @Scale = @Scale_be845e0b,
  @Scale_Clear = 1,
  @AllowsNull = @AllowsNull_be845e0b,
  @DefaultValue = @DefaultValue_be845e0b,
  @DefaultValue_Clear = 1,
  @IsPrimaryKey = @IsPrimaryKey_be845e0b,
  @IsUniqueKey = @IsUniqueKey_be845e0b,
  @IsReadOnly = @IsReadOnly_be845e0b,
  @IsRequired = @IsRequired_be845e0b,
  @RelatedIntegrationObjectID = @RelatedIntegrationObjectID_be845e0b,
  @RelatedIntegrationObjectID_Clear = 1,
  @RelatedIntegrationObjectFieldName = @RelatedIntegrationObjectFieldName_be845e0b,
  @RelatedIntegrationObjectFieldName_Clear = 1,
  @Sequence = @Sequence_be845e0b,
  @Configuration = @Configuration_be845e0b,
  @Status = @Status_be845e0b,
  @IsCustom = @IsCustom_be845e0b,
  @MetadataSource = @MetadataSource_be845e0b;

GO
