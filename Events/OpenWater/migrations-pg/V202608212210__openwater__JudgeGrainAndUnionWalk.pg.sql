-- OpenWater: the judge pair - person-grain Judge object, JudgeAssignment regains its pair grain.
-- Postgres twin of V202608212210__openwater__JudgeGrainAndUnionWalk.sql - see that file for the full
-- rationale (the missing /v2/Judges endpoint, the two judge sources, the multi-door union walk, and the
-- userId-collapse defect in JudgeAssignment).
--
-- Idempotent: every statement is guarded on its own absence. IDs are hardcoded. Audit columns are not set.

-- 1. The Judge integration object (spCreateIntegrationObject, guarded on absence) ---------------------------

-- Judge
DO $mig$
BEGIN
IF NOT EXISTS (SELECT 1 FROM "__mj"."IntegrationObject"
               WHERE "IntegrationID" = 'F2209CE3-5BC2-4E5C-9661-F409BE8FF9AA'::uuid AND "Name" = 'Judge') THEN
  PERFORM __mj."spCreateIntegrationObject"(p_ID := '2B33BEA0-AC37-46EB-9190-3CE4B45571CC'::uuid, p_IntegrationID := 'F2209CE3-5BC2-4E5C-9661-F409BE8FF9AA'::uuid, p_Name := 'Judge', p_DisplayName := 'Judges', p_Description := 'OpenWater judges as persons - the userId-distinct union of judges assigned to rounds (/v2/JudgeAssignments/AssignedToRound walked from Program -> rounds[]) and judges or managers on judge teams (embedded in /v2/JudgeTeams rows). The API has no /v2/Judges list endpoint - this object exists only through the multi-door union walk.', p_Category := NULL, p_Category_Clear := TRUE, p_APIPath := '/v2/JudgeAssignments/AssignedToRound', p_ResponseDataKey := NULL, p_ResponseDataKey_Clear := TRUE, p_DefaultPageSize := 100, p_SupportsPagination := FALSE, p_PaginationType := 'None', p_SupportsIncrementalSync := FALSE, p_SupportsWrite := FALSE, p_DefaultQueryParams := NULL, p_DefaultQueryParams_Clear := TRUE, p_Configuration := '{
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
}', p_Configuration_Clear := TRUE, p_Sequence := 0, p_Status := 'Active', p_WriteAPIPath := NULL, p_WriteAPIPath_Clear := TRUE, p_WriteMethod := 'POST', p_DeleteMethod := 'DELETE', p_IsCustom := FALSE, p_CreateAPIPath := NULL, p_CreateAPIPath_Clear := TRUE, p_CreateMethod := NULL, p_CreateMethod_Clear := TRUE, p_CreateBodyShape := NULL, p_CreateBodyShape_Clear := TRUE, p_CreateBodyKey := NULL, p_CreateBodyKey_Clear := TRUE, p_CreateIDLocation := NULL, p_CreateIDLocation_Clear := TRUE, p_UpdateAPIPath := NULL, p_UpdateAPIPath_Clear := TRUE, p_UpdateMethod := NULL, p_UpdateMethod_Clear := TRUE, p_UpdateBodyShape := NULL, p_UpdateBodyShape_Clear := TRUE, p_UpdateBodyKey := NULL, p_UpdateBodyKey_Clear := TRUE, p_UpdateIDLocation := NULL, p_UpdateIDLocation_Clear := TRUE, p_DeleteAPIPath := NULL, p_DeleteAPIPath_Clear := TRUE, p_DeleteIDLocation := NULL, p_DeleteIDLocation_Clear := TRUE, p_IncrementalWatermarkField := NULL, p_MetadataSource := 'Declared', p_SupportsCreate := FALSE, p_SupportsUpdate := FALSE, p_SupportsDelete := FALSE, p_SyncStrategy := NULL, p_SyncStrategy_Clear := TRUE, p_ContentHashApplicable := TRUE, p_StableOrderingKey := NULL, p_StableOrderingKey_Clear := TRUE);
END IF;
END
$mig$;

-- 2. Declared fields: Judge x5 and JudgeAssignment.roundId (guarded direct INSERT) --------------------------

INSERT INTO "__mj"."IntegrationObjectField"
    ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length", "AllowsNull",
     "IsPrimaryKey", "IsUniqueKey", "IsReadOnly", "IsRequired", "Sequence", "RelatedIntegrationObjectID",
     "Status", "IsCustom", "MetadataSource")
SELECT v.field_id::uuid, o."ID", v.field_name, v.display_name, v.descr, v.type, v.length, v.allows_null,
       v.is_pk, v.is_unique, false, v.is_req, v.seq, p."ID", 'Active', false, 'Declared'
FROM (VALUES
    ('388A1FE5-3917-4542-BD63-56E1D79A7AB0', 'Judge', 'userId', 'User Id', 'String', NULL::int, false, true, true, true, 0, NULL,
     'Judge user id. Declared String rather than Integer - see V202608050910 for the sizing rationale.'),
    ('D397DDF0-2DC2-4375-A048-B1ECA72B10F0', 'Judge', 'firstName', 'First Name', 'String', NULL::int, true, false, false, false, 0, NULL,
     'Judge first name.'),
    ('4CA26EE1-A6C4-4475-9982-0ADF19760AF0', 'Judge', 'lastName', 'Last Name', 'String', NULL::int, true, false, false, false, 0, NULL,
     'Judge last name.'),
    ('51FFEDAB-DBED-41AB-8070-1F1C376E05AA', 'Judge', 'email', 'Email', 'String', 320, true, false, false, false, 0, NULL,
     'Judge email.'),
    ('38DCBFE4-BDFF-4432-AD2C-A5123E9A846E', 'Judge', 'roundId', 'Round Id', 'String', NULL::int, true, false, false, false, 0, 'Rounds',
     'The Round this judge was walked under. Present only on rows sourced from the AssignedToRound walk - team-sourced rows carry no round. Declared String - see V202608050910 for the sizing rationale.'),
    ('D0012814-B281-49DF-99B8-0B9618EB6DF4', 'JudgeAssignment', 'roundId', 'Round Id', 'String', NULL::int, false, true, false, true, 1, 'Rounds',
     'The Round this assignment was walked under (/v2/JudgeAssignments/AssignedToRound?roundId=). PRIMARY KEY together with userId: with userId alone, a judge assigned to several rounds collapsed to one row per person, so the object silently held distinct judges instead of assignments. Declared String - see V202608050910 for the sizing rationale.')
) AS v(field_id, object_name, field_name, display_name, type, length, allows_null, is_pk, is_unique, is_req, seq, related_object_name, descr)
JOIN "__mj"."Integration" i ON i."Name" = 'openwater'
JOIN "__mj"."IntegrationObject" o ON o."IntegrationID" = i."ID" AND o."Name" = v.object_name
LEFT JOIN "__mj"."IntegrationObject" p ON p."IntegrationID" = i."ID" AND p."Name" = v.related_object_name
WHERE NOT EXISTS (
    SELECT 1 FROM "__mj"."IntegrationObjectField" f
    WHERE f."IntegrationObjectID" = o."ID" AND f."Name" = v.field_name);

-- 3. Tenants where JudgeAssignment.roundId was already promoted: complete it into the pair-grain key --------

UPDATE "__mj"."IntegrationObjectField" f
SET "IsPrimaryKey" = true,
    "IsRequired" = true,
    "AllowsNull" = false,
    "RelatedIntegrationObjectID" = COALESCE(f."RelatedIntegrationObjectID", r."ID")
FROM "__mj"."IntegrationObject" o
JOIN "__mj"."Integration" i ON i."ID" = o."IntegrationID" AND i."Name" = 'openwater'
JOIN "__mj"."IntegrationObject" r ON r."IntegrationID" = i."ID" AND r."Name" = 'Rounds'
WHERE f."IntegrationObjectID" = o."ID"
  AND o."Name" = 'JudgeAssignment' AND f."Name" = 'roundId' AND f."IsPrimaryKey" = false;
