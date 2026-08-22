-- OpenWater: the judge pair - a person-grain Judge object, and JudgeAssignment regains its pair grain.
--
-- The API has no /v2/Judges list endpoint. Person-grain judge data is reachable two ways: judges assigned
-- to rounds come from /v2/JudgeAssignments/AssignedToRound (walked Program -> rounds[]), and judges or
-- managers on judge teams come EMBEDDED in /v2/JudgeTeams rows (judges[] / managers[] - JudgeInfo shape
-- {userId, firstName, lastName, email}, identical to the round walk). A judge assigned only to a team never
-- appears in the round walk, so neither source alone is the judge population. The connector (this version)
-- gains `alternativeAccessPaths`: additional full walks unioned with the main AccessPath and deduplicated
-- by primary key - the Judge object is its first user.
--
-- JudgeAssignment: PK was userId ALONE, so a judge assigned to several rounds collapsed to one row per
-- person - the object silently held distinct judges instead of assignments. roundId (the walk tag the
-- connector always injects) becomes part of the primary key. Two populations, per the V202608050910
-- precedent: tenants where the tag was promoted out of custom overflow get the UPDATE; fresh tenants get
-- the INSERT.
--
-- All id fields are declared unsized String, never Integer - see V202608050910 for the rationale.
-- Delta migration: guarded on absence so re-running is a no-op. IDs are hardcoded (never NEWID()) so the
-- same row carries the same ID on every tenant. Audit columns are not set.

-- 1. The Judge integration object (spCreateIntegrationObject, guarded on absence) ---------------------------

-- Judge
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObject
               WHERE IntegrationID = 'F2209CE3-5BC2-4E5C-9661-F409BE8FF9AA' AND Name = N'Judge')
BEGIN
DECLARE @ID_2b33bea0 UNIQUEIDENTIFIER,
@IntegrationID_2b33bea0 UNIQUEIDENTIFIER,
@Name_2b33bea0 NVARCHAR(255),
@DisplayName_2b33bea0 NVARCHAR(255),
@Description_2b33bea0 NVARCHAR(MAX),
@Category_2b33bea0 NVARCHAR(100),
@APIPath_2b33bea0 NVARCHAR(500),
@ResponseDataKey_2b33bea0 NVARCHAR(255),
@DefaultPageSize_2b33bea0 INT,
@SupportsPagination_2b33bea0 BIT,
@PaginationType_2b33bea0 NVARCHAR(20),
@SupportsIncrementalSync_2b33bea0 BIT,
@SupportsWrite_2b33bea0 BIT,
@DefaultQueryParams_2b33bea0 NVARCHAR(MAX),
@Configuration_2b33bea0 NVARCHAR(MAX),
@Sequence_2b33bea0 INT,
@Status_2b33bea0 NVARCHAR(25),
@WriteAPIPath_2b33bea0 NVARCHAR(500),
@WriteMethod_2b33bea0 NVARCHAR(10),
@DeleteMethod_2b33bea0 NVARCHAR(10),
@IsCustom_2b33bea0 BIT,
@CreateAPIPath_2b33bea0 NVARCHAR(MAX),
@CreateMethod_2b33bea0 NVARCHAR(20),
@CreateBodyShape_2b33bea0 NVARCHAR(50),
@CreateBodyKey_2b33bea0 NVARCHAR(100),
@CreateIDLocation_2b33bea0 NVARCHAR(20),
@UpdateAPIPath_2b33bea0 NVARCHAR(MAX),
@UpdateMethod_2b33bea0 NVARCHAR(20),
@UpdateBodyShape_2b33bea0 NVARCHAR(50),
@UpdateBodyKey_2b33bea0 NVARCHAR(100),
@UpdateIDLocation_2b33bea0 NVARCHAR(20),
@DeleteAPIPath_2b33bea0 NVARCHAR(MAX),
@DeleteIDLocation_2b33bea0 NVARCHAR(20),
@IncrementalWatermarkField_2b33bea0 NVARCHAR(255),
@MetadataSource_2b33bea0 NVARCHAR(20),
@SupportsCreate_2b33bea0 BIT,
@SupportsUpdate_2b33bea0 BIT,
@SupportsDelete_2b33bea0 BIT,
@SyncStrategy_2b33bea0 NVARCHAR(50),
@ContentHashApplicable_2b33bea0 BIT,
@StableOrderingKey_2b33bea0 NVARCHAR(255)
SET @ID_2b33bea0 = '2B33BEA0-AC37-46EB-9190-3CE4B45571CC'
SET @IntegrationID_2b33bea0 = 'F2209CE3-5BC2-4E5C-9661-F409BE8FF9AA'
SET @Name_2b33bea0 = N'Judge'
SET @DisplayName_2b33bea0 = N'Judges'
SET @Description_2b33bea0 = N'OpenWater judges as persons - the userId-distinct union of judges assigned to rounds (/v2/JudgeAssignments/AssignedToRound walked from Program -> rounds[]) and judges or managers on judge teams (embedded in /v2/JudgeTeams rows). The API has no /v2/Judges list endpoint - this object exists only through the multi-door union walk.'
SET @APIPath_2b33bea0 = N'/v2/JudgeAssignments/AssignedToRound'
SET @DefaultPageSize_2b33bea0 = 100
SET @SupportsPagination_2b33bea0 = 0
SET @PaginationType_2b33bea0 = N'None'
SET @SupportsIncrementalSync_2b33bea0 = 0
SET @SupportsWrite_2b33bea0 = 0
SET @Configuration_2b33bea0 = N'{
  "AccessPath": {
    "door": "Program",
    "doorPath": "/v2/Programs",
    "nestingSegments": [
      "rounds[]"
    ],
    "parentParamName": "roundId",
    "entryPath": "/v2/JudgeAssignments/AssignedToRound",
    "parentParamIn": "query"
  },
  "alternativeAccessPaths": [
    {
      "door": "JudgeTeam",
      "doorPath": "/v2/JudgeTeams",
      "nestingSegments": [
        "judges[]"
      ],
      "extractionMode": "embedded-array"
    },
    {
      "door": "JudgeTeam",
      "doorPath": "/v2/JudgeTeams",
      "nestingSegments": [
        "managers[]"
      ],
      "extractionMode": "embedded-array"
    }
  ]
}'
SET @Sequence_2b33bea0 = 0
SET @Status_2b33bea0 = N'Active'
SET @WriteMethod_2b33bea0 = N'POST'
SET @DeleteMethod_2b33bea0 = N'DELETE'
SET @IsCustom_2b33bea0 = 0
SET @MetadataSource_2b33bea0 = N'Declared'
SET @SupportsCreate_2b33bea0 = 0
SET @SupportsUpdate_2b33bea0 = 0
SET @SupportsDelete_2b33bea0 = 0
SET @ContentHashApplicable_2b33bea0 = 1
EXEC [__mj].spCreateIntegrationObject @ID = @ID_2b33bea0,
  @IntegrationID = @IntegrationID_2b33bea0,
  @Name = @Name_2b33bea0,
  @DisplayName = @DisplayName_2b33bea0,
  @Description = @Description_2b33bea0,
  @Category = @Category_2b33bea0,
  @Category_Clear = 1,
  @APIPath = @APIPath_2b33bea0,
  @ResponseDataKey = @ResponseDataKey_2b33bea0,
  @ResponseDataKey_Clear = 1,
  @DefaultPageSize = @DefaultPageSize_2b33bea0,
  @SupportsPagination = @SupportsPagination_2b33bea0,
  @PaginationType = @PaginationType_2b33bea0,
  @SupportsIncrementalSync = @SupportsIncrementalSync_2b33bea0,
  @SupportsWrite = @SupportsWrite_2b33bea0,
  @DefaultQueryParams = @DefaultQueryParams_2b33bea0,
  @DefaultQueryParams_Clear = 1,
  @Configuration = @Configuration_2b33bea0,
  @Sequence = @Sequence_2b33bea0,
  @Status = @Status_2b33bea0,
  @WriteAPIPath = @WriteAPIPath_2b33bea0,
  @WriteAPIPath_Clear = 1,
  @WriteMethod = @WriteMethod_2b33bea0,
  @DeleteMethod = @DeleteMethod_2b33bea0,
  @IsCustom = @IsCustom_2b33bea0,
  @CreateAPIPath = @CreateAPIPath_2b33bea0,
  @CreateAPIPath_Clear = 1,
  @CreateMethod = @CreateMethod_2b33bea0,
  @CreateMethod_Clear = 1,
  @CreateBodyShape = @CreateBodyShape_2b33bea0,
  @CreateBodyShape_Clear = 1,
  @CreateBodyKey = @CreateBodyKey_2b33bea0,
  @CreateBodyKey_Clear = 1,
  @CreateIDLocation = @CreateIDLocation_2b33bea0,
  @CreateIDLocation_Clear = 1,
  @UpdateAPIPath = @UpdateAPIPath_2b33bea0,
  @UpdateAPIPath_Clear = 1,
  @UpdateMethod = @UpdateMethod_2b33bea0,
  @UpdateMethod_Clear = 1,
  @UpdateBodyShape = @UpdateBodyShape_2b33bea0,
  @UpdateBodyShape_Clear = 1,
  @UpdateBodyKey = @UpdateBodyKey_2b33bea0,
  @UpdateBodyKey_Clear = 1,
  @UpdateIDLocation = @UpdateIDLocation_2b33bea0,
  @UpdateIDLocation_Clear = 1,
  @DeleteAPIPath = @DeleteAPIPath_2b33bea0,
  @DeleteAPIPath_Clear = 1,
  @DeleteIDLocation = @DeleteIDLocation_2b33bea0,
  @DeleteIDLocation_Clear = 1,
  @IncrementalWatermarkField = @IncrementalWatermarkField_2b33bea0,
  @IncrementalWatermarkField_Clear = 1,
  @MetadataSource = @MetadataSource_2b33bea0,
  @SupportsCreate = @SupportsCreate_2b33bea0,
  @SupportsUpdate = @SupportsUpdate_2b33bea0,
  @SupportsDelete = @SupportsDelete_2b33bea0,
  @SyncStrategy = @SyncStrategy_2b33bea0,
  @SyncStrategy_Clear = 1,
  @ContentHashApplicable = @ContentHashApplicable_2b33bea0,
  @StableOrderingKey = @StableOrderingKey_2b33bea0,
  @StableOrderingKey_Clear = 1;
END
GO

-- 2. Declared fields: Judge x5 and JudgeAssignment.roundId (guarded direct INSERT) --------------------------

INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length, AllowsNull, IsPrimaryKey,
     IsUniqueKey, IsReadOnly, IsRequired, Sequence, RelatedIntegrationObjectID, Status, IsCustom, MetadataSource)
SELECT v.FieldID, o.ID, v.FieldName, v.DisplayName, v.Descr, v.Type, v.Length, v.AllowsNull, v.IsPK,
       v.IsUnique, 0, v.IsReq, v.Seq, p.ID, N'Active', 0, N'Declared'
FROM (VALUES
    ('388A1FE5-3917-4542-BD63-56E1D79A7AB0', N'Judge', N'userId', N'User Id', N'String', NULL, 0, 1, 1, 1, 0, NULL,
     N'Judge user id. Declared String rather than Integer - see V202608050910 for the sizing rationale.'),
    ('D397DDF0-2DC2-4375-A048-B1ECA72B10F0', N'Judge', N'firstName', N'First Name', N'String', NULL, 1, 0, 0, 0, 0, NULL,
     N'Judge first name.'),
    ('4CA26EE1-A6C4-4475-9982-0ADF19760AF0', N'Judge', N'lastName', N'Last Name', N'String', NULL, 1, 0, 0, 0, 0, NULL,
     N'Judge last name.'),
    ('51FFEDAB-DBED-41AB-8070-1F1C376E05AA', N'Judge', N'email', N'Email', N'String', 320, 1, 0, 0, 0, 0, NULL,
     N'Judge email.'),
    ('38DCBFE4-BDFF-4432-AD2C-A5123E9A846E', N'Judge', N'roundId', N'Round Id', N'String', NULL, 1, 0, 0, 0, 0, N'Rounds',
     N'The Round this judge was walked under. Present only on rows sourced from the AssignedToRound walk - team-sourced rows carry no round. Declared String - see V202608050910 for the sizing rationale.'),
    ('D0012814-B281-49DF-99B8-0B9618EB6DF4', N'JudgeAssignment', N'roundId', N'Round Id', N'String', NULL, 0, 1, 0, 1, 1, N'Rounds',
     N'The Round this assignment was walked under (/v2/JudgeAssignments/AssignedToRound?roundId=). PRIMARY KEY together with userId: with userId alone, a judge assigned to several rounds collapsed to one row per person, so the object silently held distinct judges instead of assignments. Declared String - see V202608050910 for the sizing rationale.')
) AS v(FieldID, ObjectName, FieldName, DisplayName, Type, Length, AllowsNull, IsPK, IsUnique, IsReq, Seq, RelatedObjectName, Descr)
JOIN [__mj].Integration i ON i.Name = 'openwater'
JOIN [__mj].IntegrationObject o ON o.IntegrationID = i.ID AND o.Name = v.ObjectName
LEFT JOIN [__mj].IntegrationObject p ON p.IntegrationID = i.ID AND p.Name = v.RelatedObjectName
WHERE NOT EXISTS (
    SELECT 1 FROM [__mj].IntegrationObjectField f
    WHERE f.IntegrationObjectID = o.ID AND f.Name = v.FieldName);

-- 3. Tenants where JudgeAssignment.roundId was already PROMOTED out of custom overflow: the INSERT above
--    correctly skipped it (it exists) - this is what completes it into the pair-grain key. --------------------

UPDATE f
SET f.IsPrimaryKey = 1,
    f.IsRequired = 1,
    f.AllowsNull = 0,
    f.RelatedIntegrationObjectID = COALESCE(f.RelatedIntegrationObjectID, r.ID)
FROM [__mj].IntegrationObjectField f
JOIN [__mj].IntegrationObject o ON o.ID = f.IntegrationObjectID
JOIN [__mj].Integration i ON i.ID = o.IntegrationID AND i.Name = 'openwater'
JOIN [__mj].IntegrationObject r ON r.IntegrationID = i.ID AND r.Name = N'Rounds'
WHERE o.Name = N'JudgeAssignment' AND f.Name = N'roundId' AND f.IsPrimaryKey = 0;
