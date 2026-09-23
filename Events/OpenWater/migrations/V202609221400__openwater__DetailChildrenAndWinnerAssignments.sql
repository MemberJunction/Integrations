-- OpenWater: reach the data that lives only behind a per-record GET, and put winner assignments at the grain the client counts.
--
-- WHAT WAS UNREACHABLE (docs/REQUIRED-FIXES.md item 3 / register INT-29). The published swagger (read
-- 2026-09-22) shows three list objects whose per-record detail carries fields the list never does:
--   Evaluation  /v2/Evaluations/{id}  computedScore, rankScore, rankPosition, inlineScoreFieldValues[],
--                                     generalScoringAnswers[], judgeTeams[]
--   Session     /v2/Sessions/{id}     typeId, chairs[], items[], fieldValues[]
--   User        /v2/Users/{id}        isApplicant, isJudge, isSessionChair, isGuest, fieldValues[], subAccountUserIds[]
-- The scores and answers ARE the content of an evaluation; none of it could arrive. The judge rosters
-- were audited too and are NOT affected: the team and per-application rosters return the same item
-- model as AssignedToRound, so they are different scopings, not detail data.
--
-- WHAT WAS AT THE WRONG GRAIN (item 6 / register INT-32). ApplicationWinnerType reads the round-level
-- MENU of winner types from /v2/Programs. The client's target of 89 counts per-application AWARDS, which
-- live in /v2/Applications/{id} -> roundSubmissions[].winnerTypes[] as an array of type NAMES. The 1.3.6
-- change that added the round tag said so in its own body ("the missing rows are per-submission
-- winnerTypes, reachable only by adding a detail-walk alternate") and #364 then skipped that array on the
-- grounds that it duplicated ApplicationWinnerType. It does not: one is the menu, the other is the award.
--
-- HOW. No new extraction mode. The existing detail modes already fetch each door row's own detail, so
-- a 'detail-object' walk over the Evaluation door with entryPath /v2/Evaluations/{id} IS the per-record
-- GET, declared in metadata. Two small additions to the detail-embedded walk in the connector make the
-- children keyable: AccessPath.segmentTags copies an intermediate node's field (the round submission's
-- roundId) onto every element beneath it, and AccessPath.scalarLeafKey keeps scalar leaves (the walker
-- used to drop every string in winnerTypes[] silently). Every key below comes from the swagger's element
-- schemas, so nothing here relies on soft-PK inference and nothing enters the read-only PK baseline.
--
-- COST. One GET per door row per detail walk, shared across siblings by the per-batch detail cache and
-- bounded by #364's concurrent slices and remaining-budget slicing. Applications were already walked
-- this way, so the Application changes add no requests; Evaluation, Session and User are new walks.
--
-- THIS MIGRATION.
--   1. Twelve new objects (guarded INSERT ... SELECT by name; IDs hardcoded so every tenant carries the
--      same ID). Direct INSERT rather than spCreateIntegrationObject: the table's only NOT NULL columns
--      without defaults are IntegrationID, Name and APIPath, and a direct statement cannot fall into the
--      value-then-clear trap that emptied five AccessPaths in 1.3.10.
--   2. The four #364 children (ApplicationJudgeScorecard, ApplicationReceivedRecommendation,
--      ApplicationPendingRecommendation, ApplicationScoringQuestionScore) gain segmentTags in their
--      AccessPath, their applicationId becomes part of the key, and roundId plus their element fields
--      are declared. They leave scripts/readonly-pk-baseline.json in the same change.
--   3. Every declared field (guarded INSERT on absence). Injected ids are String, never Integer - see
--      V202608050910; vendor element ids that are keys but not relations stay Integer like Evaluation.id.
--
-- Integration rows are resolved with LOWER(Name) so the predicate does not depend on collation.
-- Re-running is a no-op. Audit columns are not set. The JSON is generated from the same spec as
-- metadata/integration/.openwater.integration.json.

-- ── 1. New objects ─────────────────────────────────────────────────────────────────────────────────────

INSERT INTO [__mj].[IntegrationObject]
    ([ID], [IntegrationID], [Name], [DisplayName], [Description], [APIPath], [SupportsPagination], [PaginationType],
     [SupportsIncrementalSync], [SupportsWrite], [Configuration], [Status], [MetadataSource])
SELECT v.ObjID, i.[ID], v.ObjName, v.DisplayName, v.Descr, v.APIPath, 0, N'None', 0, 0, v.Config, N'Active', N'Declared'
FROM (VALUES
    ('42990F2A-1DB5-4EDD-97E6-081B1664E8E3', N'ApplicationWinnerAssignment', N'Application Winner Assignments', N'(embedded in /v2/Applications/{applicationId} roundSubmissions[].winnerTypes[])',
     N'{"AccessPath":{"door":"Application","doorPath":"/v2/Applications","entryPath":"/v2/Applications/{applicationId}","parentParamName":"applicationId","nestingSegments":["roundSubmissions[]","winnerTypes[]"],"segmentTags":[{"segment":"roundSubmissions[]","sourceKey":"roundId","asKey":"roundId"}],"extractionMode":"detail-embedded","scalarLeafKey":"name"}}',
     N'OpenWater per-application winner assignments: which winner types an application was awarded in a round. Access: /v2/Applications/{applicationId} -> roundSubmissions[] -> winnerTypes[] (an array of type NAMES; each becomes one row). This is the application grain of winner data; ApplicationWinnerType is the round-level menu of available types.'),
    ('F7793104-5007-4B0D-8167-CD2AEDC6EC41', N'EvaluationDetail', N'Evaluation Details', N'/v2/Evaluations/{id}',
     N'{"AccessPath":{"door":"Evaluation","doorPath":"/v2/Evaluations","entryPath":"/v2/Evaluations/{id}","parentParamName":"id","extractionMode":"detail-object"}}',
     N'OpenWater evaluation detail: the scalar fields /v2/Evaluations/{id} carries that the /v2/Evaluations list does not (computed score, rank score, rank position). One row per Evaluation; join on id.'),
    ('080C8975-E01D-4024-AAAA-C590544885A5', N'EvaluationScoreFieldValue', N'Evaluation Score Field Values', N'(embedded in /v2/Evaluations/{evaluationId} inlineScoreFieldValues[])',
     N'{"AccessPath":{"door":"Evaluation","doorPath":"/v2/Evaluations","entryPath":"/v2/Evaluations/{evaluationId}","parentParamName":"evaluationId","nestingSegments":["inlineScoreFieldValues[]"],"extractionMode":"detail-embedded"}}',
     N'OpenWater per-field inline scores on an evaluation. Access: /v2/Evaluations/{evaluationId} -> inlineScoreFieldValues[]. rowScores is kept as JSON (rows of rowId/score).'),
    ('E2740862-3EEF-477E-956C-C9D123EAE9A6', N'EvaluationGeneralScoringAnswer', N'Evaluation General Scoring Answers', N'(embedded in /v2/Evaluations/{evaluationId} generalScoringAnswers[])',
     N'{"AccessPath":{"door":"Evaluation","doorPath":"/v2/Evaluations","entryPath":"/v2/Evaluations/{evaluationId}","parentParamName":"evaluationId","nestingSegments":["generalScoringAnswers[]"],"extractionMode":"detail-embedded"}}',
     N'OpenWater answers to the general scoring questions on an evaluation. Access: /v2/Evaluations/{evaluationId} -> generalScoringAnswers[].'),
    ('D45C57B6-6C08-43FC-8914-210D3541E1BE', N'EvaluationJudgeTeam', N'Evaluation Judge Teams', N'(embedded in /v2/Evaluations/{evaluationId} judgeTeams[])',
     N'{"AccessPath":{"door":"Evaluation","doorPath":"/v2/Evaluations","entryPath":"/v2/Evaluations/{evaluationId}","parentParamName":"evaluationId","nestingSegments":["judgeTeams[]"],"extractionMode":"detail-embedded"}}',
     N'OpenWater judge teams associated with an evaluation. Access: /v2/Evaluations/{evaluationId} -> judgeTeams[].'),
    ('18E055F6-C5DC-4EEB-AEFE-FE486B17F154', N'SessionDetail', N'Session Details', N'/v2/Sessions/{id}',
     N'{"AccessPath":{"door":"Session","doorPath":"/v2/Sessions","entryPath":"/v2/Sessions/{id}","parentParamName":"id","extractionMode":"detail-object"}}',
     N'OpenWater session detail: the scalar fields /v2/Sessions/{id} carries that the /v2/Sessions list does not (typeId). One row per Session; join on id.'),
    ('10AC1182-7159-4A4F-876A-5C3665AED70E', N'SessionChair', N'Session Chairs', N'(embedded in /v2/Sessions/{sessionId} chairs[])',
     N'{"AccessPath":{"door":"Session","doorPath":"/v2/Sessions","entryPath":"/v2/Sessions/{sessionId}","parentParamName":"sessionId","nestingSegments":["chairs[]"],"extractionMode":"detail-embedded"}}',
     N'OpenWater session chairs. Access: /v2/Sessions/{sessionId} -> chairs[].'),
    ('97B4B038-9EA9-4C5A-9D79-38DD414FDBA5', N'SessionItem', N'Session Items', N'(embedded in /v2/Sessions/{sessionId} items[])',
     N'{"AccessPath":{"door":"Session","doorPath":"/v2/Sessions","entryPath":"/v2/Sessions/{sessionId}","parentParamName":"sessionId","nestingSegments":["items[]"],"extractionMode":"detail-embedded"}}',
     N'OpenWater session agenda items (applications and other item types placed in a session). Access: /v2/Sessions/{sessionId} -> items[].'),
    ('C3B05F96-1EFE-4113-A4C8-993F00C9F544', N'SessionFieldValue', N'Session Field Values', N'(embedded in /v2/Sessions/{sessionId} fieldValues[])',
     N'{"AccessPath":{"door":"Session","doorPath":"/v2/Sessions","entryPath":"/v2/Sessions/{sessionId}","parentParamName":"sessionId","nestingSegments":["fieldValues[]"],"extractionMode":"detail-embedded"}}',
     N'OpenWater session form field values. Access: /v2/Sessions/{sessionId} -> fieldValues[]. The vendor model is polymorphic (FieldValueModelBase subtypes); alias and typeName are declared, the subtype-specific keys arrive as custom columns.'),
    ('27013659-F63D-4846-A345-6A6D73A14217', N'UserDetail', N'User Details', N'/v2/Users/{id}',
     N'{"AccessPath":{"door":"User","doorPath":"/v2/Users","entryPath":"/v2/Users/{id}","parentParamName":"id","extractionMode":"detail-object"}}',
     N'OpenWater user detail: the role flags /v2/Users/{id} carries that the /v2/Users list does not. One row per User; join on id.'),
    ('C98DDD6C-105F-4024-A47C-24D773AF77F7', N'UserFieldValue', N'User Field Values', N'(embedded in /v2/Users/{userId} fieldValues[])',
     N'{"AccessPath":{"door":"User","doorPath":"/v2/Users","entryPath":"/v2/Users/{userId}","parentParamName":"userId","nestingSegments":["fieldValues[]"],"extractionMode":"detail-embedded"}}',
     N'OpenWater user profile form field values. Access: /v2/Users/{userId} -> fieldValues[]. Polymorphic vendor model; alias and typeName declared, subtype keys arrive as custom columns.'),
    ('EEE573C3-1BEB-4725-A544-4E704CD00FA3', N'UserSubAccount', N'User Sub Accounts', N'(embedded in /v2/Users/{userId} subAccountUserIds[])',
     N'{"AccessPath":{"door":"User","doorPath":"/v2/Users","entryPath":"/v2/Users/{userId}","parentParamName":"userId","nestingSegments":["subAccountUserIds[]"],"extractionMode":"detail-embedded","scalarLeafKey":"subAccountUserId"}}',
     N'OpenWater sub-account links: the users that are sub-accounts of a user. Access: /v2/Users/{userId} -> subAccountUserIds[] (an array of user ids; each becomes one row).')
) AS v(ObjID, ObjName, DisplayName, APIPath, Config, Descr)
JOIN [__mj].[Integration] i ON LOWER(i.[Name]) = 'openwater'
WHERE NOT EXISTS (SELECT 1 FROM [__mj].[IntegrationObject] o WHERE o.[IntegrationID] = i.[ID] AND o.[Name] = v.ObjName);

-- ── 2. The four #364 children: segmentTags, and applicationId joins the key ────────────────────────────

UPDATE [__mj].[IntegrationObject]
SET [Configuration] = N'{"AccessPath":{"door":"Application","doorPath":"/v2/Applications","entryPath":"/v2/Applications/{applicationId}","parentParamName":"applicationId","nestingSegments":["roundSubmissions[]","judgeScorecardInfos[]"],"segmentTags":[{"segment":"roundSubmissions[]","sourceKey":"roundId","asKey":"roundId"}],"extractionMode":"detail-embedded"}}'
WHERE [ID] = '644DBEC0-A0A5-4CDC-B598-FF9F3E2AB413' AND ([Configuration] IS NULL OR [Configuration] NOT LIKE '%segmentTags%');

UPDATE [__mj].[IntegrationObject]
SET [Configuration] = N'{"AccessPath":{"door":"Application","doorPath":"/v2/Applications","entryPath":"/v2/Applications/{applicationId}","parentParamName":"applicationId","nestingSegments":["roundSubmissions[]","receivedRecommendations[]"],"segmentTags":[{"segment":"roundSubmissions[]","sourceKey":"roundId","asKey":"roundId"}],"extractionMode":"detail-embedded"}}'
WHERE [ID] = 'E2351748-76FA-490A-8E65-22BE8EF77FCC' AND ([Configuration] IS NULL OR [Configuration] NOT LIKE '%segmentTags%');

UPDATE [__mj].[IntegrationObject]
SET [Configuration] = N'{"AccessPath":{"door":"Application","doorPath":"/v2/Applications","entryPath":"/v2/Applications/{applicationId}","parentParamName":"applicationId","nestingSegments":["roundSubmissions[]","notReceivedRecommendations[]"],"segmentTags":[{"segment":"roundSubmissions[]","sourceKey":"roundId","asKey":"roundId"}],"extractionMode":"detail-embedded"}}'
WHERE [ID] = '4514D359-D1F5-40B6-84D2-36ED211D0E30' AND ([Configuration] IS NULL OR [Configuration] NOT LIKE '%segmentTags%');

UPDATE [__mj].[IntegrationObject]
SET [Configuration] = N'{"AccessPath":{"door":"Application","doorPath":"/v2/Applications","entryPath":"/v2/Applications/{applicationId}","parentParamName":"applicationId","nestingSegments":["roundSubmissions[]","generalScoringQuestionsAggregatedScoreInfos[]"],"segmentTags":[{"segment":"roundSubmissions[]","sourceKey":"roundId","asKey":"roundId"}],"extractionMode":"detail-embedded"}}'
WHERE [ID] = '7DD615DB-8E11-43A0-9A07-1E2912543C48' AND ([Configuration] IS NULL OR [Configuration] NOT LIKE '%segmentTags%');

UPDATE [__mj].[IntegrationObjectField]
SET [IsPrimaryKey] = 1, [IsRequired] = 1
WHERE [Name] = N'applicationId' AND [IsPrimaryKey] = 0
  AND [IntegrationObjectID] IN ('644DBEC0-A0A5-4CDC-B598-FF9F3E2AB413', 'E2351748-76FA-490A-8E65-22BE8EF77FCC', '4514D359-D1F5-40B6-84D2-36ED211D0E30', '7DD615DB-8E11-43A0-9A07-1E2912543C48');

-- ── 3. Declared fields (new objects and the four amended ones) ─────────────────────────────────────────

INSERT INTO [__mj].[IntegrationObjectField]
    ([ID], [IntegrationObjectID], [Name], [DisplayName], [Description], [Type], [Length], [AllowsNull], [IsPrimaryKey],
     [IsUniqueKey], [IsReadOnly], [IsRequired], [RelatedIntegrationObjectID], [Sequence], [Status], [IsCustom], [MetadataSource])
SELECT v.FieldID, o.[ID], v.FieldName, v.DisplayName, v.Descr, v.Type, v.Length, CASE WHEN v.IsReq = 1 THEN 0 ELSE 1 END, v.IsPK,
       0, 0, v.IsReq, p.[ID], 0, N'Active', 0, N'Declared'
FROM (VALUES
    ('0772E97E-38D9-4BC9-8E15-1C3B7B216FF0', N'ApplicationWinnerAssignment', N'applicationId', N'Application Id', N'String', 50, 1, 1, N'Application',
     N'The Application this row was walked under. Injected by the detail walk from the access path, not present in the element body, so declared String - see V202608050910 for the sizing rationale.'),
    ('2F13A679-9E0B-48DC-AE9D-F723DB8BAD79', N'ApplicationWinnerAssignment', N'roundId', N'Round Id', N'String', 50, 1, 1, N'Rounds',
     N'Round this row belongs to, copied from the enclosing roundSubmissions[] element by the detail walk (AccessPath.segmentTags). Declared String - see V202608050910 for the sizing rationale.'),
    ('53FC5539-9B26-4D26-BB88-3C56E200C943', N'ApplicationWinnerAssignment', N'name', N'Name', N'String', NULL, 1, 1, NULL,
     N'Winner type name as assigned to this application in this round (the vendor supplies names, not ids, at this grain).'),
    ('1121319A-37E9-42C8-BD1B-87523FDF7B5B', N'EvaluationDetail', N'id', N'Id', N'Integer', NULL, 1, 1, N'Evaluation',
     N'Evaluation id (same value as Evaluation.id).'),
    ('D3B54C6E-F117-4700-A639-ACC798BE243C', N'EvaluationDetail', N'programId', N'Program Id', N'Integer', NULL, 0, 0, NULL,
     N'Program id.'),
    ('1F4A729A-0F09-41EF-9F30-C7B90C56F755', N'EvaluationDetail', N'roundId', N'Round Id', N'Integer', NULL, 0, 0, NULL,
     N'Round id.'),
    ('43732C38-D641-48FE-BBA0-D9483939CB5E', N'EvaluationDetail', N'judgeUserId', N'Judge User Id', N'Integer', NULL, 0, 0, NULL,
     N'Judge user id.'),
    ('E8DA1770-50C6-4B3F-A1EA-C29972CE464A', N'EvaluationDetail', N'applicationId', N'Application Id', N'Integer', NULL, 0, 0, NULL,
     N'Application id.'),
    ('BC381626-37C4-41B4-BFDA-F50F7A41F1AC', N'EvaluationDetail', N'applicationCode', N'Application Code', N'String', NULL, 0, 0, NULL,
     N'Application code.'),
    ('047A1478-B91F-4C9F-8C9B-DC88F4644580', N'EvaluationDetail', N'computedScore', N'Computed Score', N'Decimal', NULL, 0, 0, NULL,
     N'Computed score for this evaluation.'),
    ('056126A0-3F96-4B54-A337-8430AA4215A9', N'EvaluationDetail', N'rankScore', N'Rank Score', N'Decimal', NULL, 0, 0, NULL,
     N'Rank score.'),
    ('A36252EB-AC2C-41DA-A162-976DE79E8385', N'EvaluationDetail', N'rankPosition', N'Rank Position', N'Integer', NULL, 0, 0, NULL,
     N'Rank position.'),
    ('17F3A6A3-528D-42F1-BF3D-EB087A098820', N'EvaluationDetail', N'evaluationDateUtc', N'Evaluation Date Utc', N'DateTime', NULL, 0, 0, NULL,
     N'Evaluation date (UTC).'),
    ('00053A18-8CA4-449C-A5CA-84833D5F5E3D', N'EvaluationScoreFieldValue', N'evaluationId', N'Evaluation Id', N'String', 50, 1, 1, N'Evaluation',
     N'The Evaluation this score belongs to. Injected by the detail walk from the access path, not present in the element body, so declared String - see V202608050910 for the sizing rationale.'),
    ('6A10FA66-1D05-4A71-B288-04FDB99898FA', N'EvaluationScoreFieldValue', N'alias', N'Alias', N'String', NULL, 1, 1, NULL,
     N'Scored field alias.'),
    ('F2EB5703-856A-4F82-A693-2A010E8FAFF6', N'EvaluationScoreFieldValue', N'rowScores', N'Row Scores', N'json', NULL, 0, 0, NULL,
     N'Per-row scores for this field (array of {rowId, ...}).'),
    ('DC1B2554-0F0D-4B49-8DE6-34DFEB257100', N'EvaluationGeneralScoringAnswer', N'evaluationId', N'Evaluation Id', N'String', 50, 1, 1, N'Evaluation',
     N'The Evaluation this answer belongs to. Injected by the detail walk from the access path, not present in the element body, so declared String - see V202608050910 for the sizing rationale.'),
    ('13084909-9BD6-4D6E-86E4-8DE2E9990C5D', N'EvaluationGeneralScoringAnswer', N'alias', N'Alias', N'String', NULL, 1, 1, NULL,
     N'Scoring question alias.'),
    ('8C3ACC84-EE25-4E44-A6E7-F8786D446631', N'EvaluationGeneralScoringAnswer', N'mediaId', N'Media Id', N'String', 50, 0, 0, N'Media',
     N'Media attached to the answer, when any. Declared String - see V202608050910 for the sizing rationale.'),
    ('78648668-DDF9-4454-A3F7-E1567C109D70', N'EvaluationGeneralScoringAnswer', N'score', N'Score', N'Decimal', NULL, 0, 0, NULL,
     N'Numeric score given.'),
    ('28089A7D-F589-4907-B387-394020EDC652', N'EvaluationGeneralScoringAnswer', N'text', N'Text', N'String', 4000, 0, 0, NULL,
     N'Free-text answer.'),
    ('35637F56-877B-4D02-8163-234A34A35A73', N'EvaluationJudgeTeam', N'evaluationId', N'Evaluation Id', N'String', 50, 1, 1, N'Evaluation',
     N'The Evaluation this team row belongs to. Injected by the detail walk from the access path, not present in the element body, so declared String - see V202608050910 for the sizing rationale.'),
    ('38085942-7F68-4F66-BAC9-F3A00F4F1F2E', N'EvaluationJudgeTeam', N'id', N'Id', N'String', 50, 1, 1, N'JudgeTeam',
     N'Judge team id. Declared String - see V202608050910 for the sizing rationale.'),
    ('F7526B3E-10DE-48C3-9A63-A9CDB1EB700D', N'EvaluationJudgeTeam', N'name', N'Name', N'String', NULL, 0, 0, NULL,
     N'Judge team name.'),
    ('70B95A9A-4125-4376-AEF9-CED619A1A055', N'SessionDetail', N'id', N'Id', N'Integer', NULL, 1, 1, N'Session',
     N'Session id (same value as Session.id).'),
    ('699C2AB7-106A-4C9B-A498-EC98A50AD5EC', N'SessionDetail', N'programId', N'Program Id', N'Integer', NULL, 0, 0, NULL,
     N'Program id.'),
    ('8005D745-7585-4BBA-8EFA-A8E3E9461577', N'SessionDetail', N'typeId', N'Type Id', N'Integer', NULL, 0, 0, NULL,
     N'Session type id.'),
    ('4E76689D-F3EF-4E76-9769-675B34C93D12', N'SessionDetail', N'typeName', N'Type Name', N'String', NULL, 0, 0, NULL,
     N'Session type name.'),
    ('95B9DF57-2A70-41C6-B29E-7AC761E39A1C', N'SessionDetail', N'name', N'Name', N'String', NULL, 0, 0, NULL,
     N'Session name.'),
    ('0B5644F9-5FF8-4AE4-BBCE-FA3CA0845ACB', N'SessionChair', N'sessionId', N'Session Id', N'String', 50, 1, 1, N'Session',
     N'The Session this chair belongs to. Injected by the detail walk from the access path, not present in the element body, so declared String - see V202608050910 for the sizing rationale.'),
    ('264F9EFA-C407-4B5C-869B-6367D32842AD', N'SessionChair', N'id', N'Id', N'Integer', NULL, 1, 1, NULL,
     N'Session chair id.'),
    ('599C4623-E25A-4810-AC9F-0F2E1A6B4D7D', N'SessionChair', N'email', N'Email', N'String', 320, 0, 0, NULL,
     N'Chair email address.'),
    ('DB86CF46-4BFF-4A22-B64C-C6FD645B3FEE', N'SessionChair', N'isPrimary', N'Is Primary', N'Boolean', NULL, 0, 0, NULL,
     N'Whether this is the primary chair.'),
    ('6E56A080-B3B2-4E35-AD21-A7B872A77094', N'SessionItem', N'sessionId', N'Session Id', N'String', 50, 1, 1, N'Session',
     N'The Session this item belongs to. Injected by the detail walk from the access path, not present in the element body, so declared String - see V202608050910 for the sizing rationale.'),
    ('32746917-4E5D-4F09-8264-00F4C096DBD0', N'SessionItem', N'id', N'Id', N'Integer', NULL, 1, 1, NULL,
     N'Session item id.'),
    ('6D74FA35-2F76-4767-8FEF-DEAEFE8B8F86', N'SessionItem', N'applicationId', N'Application Id', N'String', 50, 0, 0, N'Application',
     N'Application placed in this item, when any. Declared String - see V202608050910 for the sizing rationale.'),
    ('22673A54-ADA3-4F40-BDB7-F635303893CD', N'SessionItem', N'customSessionItemTypeId', N'Custom Session Item Type Id', N'Integer', NULL, 0, 0, NULL,
     N'Custom item type id, when not an application.'),
    ('00942635-9D5B-4533-859C-69CD61125F68', N'SessionItem', N'customSessionItemTypeDescription', N'Custom Session Item Type Description', N'String', NULL, 0, 0, NULL,
     N'Custom item type description.'),
    ('E4D4F333-D873-4991-8C31-8AFCAC0BB8B3', N'SessionItem', N'sortOrder', N'Sort Order', N'Integer', NULL, 0, 0, NULL,
     N'Position within the session.'),
    ('99F24FDF-9428-4196-B402-81545DAA0F70', N'SessionItem', N'durationInMinutes', N'Duration In Minutes', N'Integer', NULL, 0, 0, NULL,
     N'Duration in minutes.'),
    ('B951B62E-0565-47BA-A2BE-F536E5C37AC1', N'SessionFieldValue', N'sessionId', N'Session Id', N'String', 50, 1, 1, N'Session',
     N'The Session this value belongs to. Injected by the detail walk from the access path, not present in the element body, so declared String - see V202608050910 for the sizing rationale.'),
    ('A33AA545-E335-47A8-A136-2D22BB7F890D', N'SessionFieldValue', N'alias', N'Alias', N'String', NULL, 1, 1, NULL,
     N'Form field alias.'),
    ('548ABB78-EB61-417A-886B-FD54C8F1BB07', N'SessionFieldValue', N'typeName', N'Type Name', N'String', NULL, 0, 0, NULL,
     N'Field value type name (the polymorphic subtype).'),
    ('3D7FCAE4-E904-445E-9B41-A5877FE44913', N'UserDetail', N'id', N'Id', N'Integer', NULL, 1, 1, N'User',
     N'User id (same value as User.id).'),
    ('25A300B8-F86A-4192-8C75-3A51D8F5D870', N'UserDetail', N'isApplicant', N'Is Applicant', N'Boolean', NULL, 0, 0, NULL,
     N'Whether the user is an applicant.'),
    ('389295D5-FFAC-41D3-B901-401CD58DA089', N'UserDetail', N'isJudge', N'Is Judge', N'Boolean', NULL, 0, 0, NULL,
     N'Whether the user is a judge.'),
    ('980B7435-1B0E-4D5F-9ABD-BEEF41E04C98', N'UserDetail', N'isSessionChair', N'Is Session Chair', N'Boolean', NULL, 0, 0, NULL,
     N'Whether the user is a session chair.'),
    ('FDCF71E2-2EC4-4EA7-9ADD-88D1EA396B1A', N'UserDetail', N'isGuest', N'Is Guest', N'Boolean', NULL, 0, 0, NULL,
     N'Whether the user is a guest.'),
    ('DB45AFB2-AFE3-4EFB-AA6F-A5D76553434B', N'UserFieldValue', N'userId', N'User Id', N'String', 50, 1, 1, N'User',
     N'The User this value belongs to. Injected by the detail walk from the access path, not present in the element body, so declared String - see V202608050910 for the sizing rationale.'),
    ('23FE1CD2-D23A-4F03-96A2-C9BFDDE059EB', N'UserFieldValue', N'alias', N'Alias', N'String', NULL, 1, 1, NULL,
     N'Profile field alias.'),
    ('FC2FCB0D-8912-4ACC-87DC-090226C3658C', N'UserFieldValue', N'typeName', N'Type Name', N'String', NULL, 0, 0, NULL,
     N'Field value type name (the polymorphic subtype).'),
    ('5AFDD034-05E1-4683-B03C-FC04F8A189D8', N'UserSubAccount', N'userId', N'User Id', N'String', 50, 1, 1, N'User',
     N'The parent User. Injected by the detail walk from the access path, not present in the element body, so declared String - see V202608050910 for the sizing rationale.'),
    ('231E0A79-7A00-47EE-ADFD-1294A188CC52', N'UserSubAccount', N'subAccountUserId', N'Sub Account User Id', N'String', 50, 1, 1, N'User',
     N'The sub-account User. Declared String - see V202608050910 for the sizing rationale.'),
    ('37DC9A28-6B1B-46DA-ABF6-7EFB68F065E8', N'ApplicationJudgeScorecard', N'roundId', N'Round Id', N'String', 50, 1, 1, N'Rounds',
     N'Round this row belongs to, copied from the enclosing roundSubmissions[] element by the detail walk (AccessPath.segmentTags). Declared String - see V202608050910 for the sizing rationale.'),
    ('CB4F8F4A-B1E1-460A-9BDC-4121E65519A4', N'ApplicationJudgeScorecard', N'id', N'Id', N'Integer', NULL, 1, 1, NULL,
     N'Scorecard id.'),
    ('506E6939-220B-407D-8D1E-DE663A75F171', N'ApplicationJudgeScorecard', N'status', N'Status', N'String', 50, 0, 0, NULL,
     N'Scorecard status (NotScored, Started, Complete).'),
    ('A7BF843E-8CE1-4D51-81E3-EFB6FA6B19A7', N'ApplicationJudgeScorecard', N'totalScore', N'Total Score', N'Decimal', NULL, 0, 0, NULL,
     N'Total score on this scorecard.'),
    ('BD2FBEFD-F7F7-46EB-942E-F9CD3D30AB3E', N'ApplicationReceivedRecommendation', N'roundId', N'Round Id', N'String', 50, 1, 1, N'Rounds',
     N'Round this row belongs to, copied from the enclosing roundSubmissions[] element by the detail walk (AccessPath.segmentTags). Declared String - see V202608050910 for the sizing rationale.'),
    ('44B4BD37-CE2B-41C5-B588-25B182588057', N'ApplicationReceivedRecommendation', N'fieldAlias', N'Field Alias', N'String', NULL, 1, 1, NULL,
     N'Recommendation field alias.'),
    ('7D5C8737-8441-4AB6-A665-B936B5C6D682', N'ApplicationReceivedRecommendation', N'confirmationUrl', N'Confirmation Url', N'String', 2048, 0, 0, NULL,
     N'Confirmation URL for the received recommendation.'),
    ('36A20B28-D2BE-4A1F-9668-C2F473F5F5FC', N'ApplicationPendingRecommendation', N'roundId', N'Round Id', N'String', 50, 1, 1, N'Rounds',
     N'Round this row belongs to, copied from the enclosing roundSubmissions[] element by the detail walk (AccessPath.segmentTags). Declared String - see V202608050910 for the sizing rationale.'),
    ('5EE51024-1A29-4372-B5A1-6F5E3CF22438', N'ApplicationPendingRecommendation', N'fieldAlias', N'Field Alias', N'String', NULL, 1, 1, NULL,
     N'Recommendation field alias.'),
    ('D7B903B3-94CE-4221-9431-6A7DEF7F2B3E', N'ApplicationPendingRecommendation', N'recommendationUrl', N'Recommendation Url', N'String', 2048, 0, 0, NULL,
     N'URL the recommender was sent.'),
    ('D1905413-EE56-42FF-BAB5-7DF4A57171D0', N'ApplicationScoringQuestionScore', N'roundId', N'Round Id', N'String', 50, 1, 1, N'Rounds',
     N'Round this row belongs to, copied from the enclosing roundSubmissions[] element by the detail walk (AccessPath.segmentTags). Declared String - see V202608050910 for the sizing rationale.'),
    ('1CD96497-60EA-4E09-8CB9-A42431B2B593', N'ApplicationScoringQuestionScore', N'generalScoringQuestionId', N'General Scoring Question Id', N'Integer', NULL, 1, 1, NULL,
     N'General scoring question id.'),
    ('F4F03821-8068-4FFA-A463-FFC173727708', N'ApplicationScoringQuestionScore', N'score', N'Score', N'json', NULL, 0, 0, NULL,
     N'Aggregated score for the question ({averageScore}).')
) AS v(FieldID, ObjName, FieldName, DisplayName, Type, Length, IsPK, IsReq, RelatedObjName, Descr)
JOIN [__mj].[Integration] i ON LOWER(i.[Name]) = 'openwater'
JOIN [__mj].[IntegrationObject] o ON o.[IntegrationID] = i.[ID] AND o.[Name] = v.ObjName
LEFT JOIN [__mj].[IntegrationObject] p ON p.[IntegrationID] = i.[ID] AND p.[Name] = v.RelatedObjName
WHERE NOT EXISTS (SELECT 1 FROM [__mj].[IntegrationObjectField] f WHERE f.[IntegrationObjectID] = o.[ID] AND f.[Name] = v.FieldName);
