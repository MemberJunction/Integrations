-- OpenWater -- restore the AccessPath the create calls threw away
--
-- REPAIR. Five objects were created with their AccessPath supplied AND cleared in the same call:
--
--     p_Configuration := '{ "AccessPath": { ... } }', p_Configuration_Clear := TRUE
--
-- `_Clear := TRUE` sets the column to NULL. It is emitted for every nullable parameter, correctly
-- for `p_Category := NULL, p_Category_Clear := TRUE` -- but here it was emitted alongside a real
-- value, and the clear wins. Every one of these objects has had Configuration NULL since creation,
-- on EVERY dialect: the T-SQL twins pass the same flag. That is why these five appear in no
-- proving table on any environment.
--
-- What it costs: FetchChanges calls ParseAccessPath(obj), which reads Configuration. NULL means no
-- access path, so the walk is never entered and the fetch falls through to FetchDoor, which
-- requests obj.APIPath literally. For these objects APIPath is a DESCRIPTION, not a URL. Observed
-- live 2026-09-13 on run f00743e7:
--   ApplicationWinnerType      Failed to parse URL from https://api.secure-platform.com(embedded in ...)
--   ApplicationRoundSubmission Failed to parse URL from https://api.secure-platform.com(embedded in ...)
--   ApplicationFile            Failed to parse URL from https://api.secure-platform.com(embedded in ...)
--   Media                      HTTP 404 at /v2/Media/{mediaId}          -- template never filled
--   Judge                      HTTP 500 at /v2/JudgeAssignments/AssignedToRound -- roundId never attached
-- All five held their watermark and retried, so they could never advance. The connector code is
-- correct: FetchViaAccessPath implements embedded-array, detail-embedded and detail-object. It was
-- never reached.
--
-- The values below are the ones the original calls passed, with the refinements later migrations
-- intended: fieldValues[] -> submissionFieldValues[] (V202608230150) for ApplicationFile and Media,
-- and the embeddedParentTag form (V202608230600) for ApplicationWinnerType. Those later statements
-- were no-ops twice over -- REPLACE() on a NULL returns NULL, and `Configuration NOT LIKE '%...%'`
-- is NULL rather than true when Configuration is NULL, so the row never matched.
--
-- Idempotent: only touches a row whose Configuration lacks an AccessPath. Applied migrations are
-- not edited -- Flyway validates their checksums.

UPDATE [__mj].[IntegrationObject]
SET [Configuration] = N'{
  "AccessPath": {
    "door": "Application",
    "doorPath": "/v2/Applications",
    "entryPath": "/v2/Applications/{applicationId}",
    "parentParamName": "applicationId",
    "nestingSegments": [
      "roundSubmissions[]",
      "submissionFieldValues[]"
    ],
    "elementFilter": {
      "key": "mediaId",
      "exists": true
    },
    "extractionMode": "detail-embedded"
  }
}'
WHERE [Name] = 'ApplicationFile'
  AND ([Configuration] IS NULL OR [Configuration] NOT LIKE '%AccessPath%')
  AND [IntegrationID] IN (SELECT [ID] FROM [__mj].[Integration] WHERE LOWER([Name]) = 'openwater');

UPDATE [__mj].[IntegrationObject]
SET [Configuration] = N'{
  "AccessPath": {
    "door": "Application",
    "doorPath": "/v2/Applications",
    "entryPath": "/v2/Applications/{applicationId}",
    "parentParamName": "applicationId",
    "nestingSegments": [
      "roundSubmissions[]"
    ],
    "extractionMode": "detail-embedded"
  }
}'
WHERE [Name] = 'ApplicationRoundSubmission'
  AND ([Configuration] IS NULL OR [Configuration] NOT LIKE '%AccessPath%')
  AND [IntegrationID] IN (SELECT [ID] FROM [__mj].[Integration] WHERE LOWER([Name]) = 'openwater');

UPDATE [__mj].[IntegrationObject]
SET [Configuration] = N'{"AccessPath":{"door":"Program","doorPath":"/v2/Programs","nestingSegments":["rounds[]","winnerTypes[]"],"embeddedParentTag":{"sourceKey":"id","asKey":"roundId"},"extractionMode":"embedded-array"}}'
WHERE [Name] = 'ApplicationWinnerType'
  AND ([Configuration] IS NULL OR [Configuration] NOT LIKE '%AccessPath%')
  AND [IntegrationID] IN (SELECT [ID] FROM [__mj].[Integration] WHERE LOWER([Name]) = 'openwater');

UPDATE [__mj].[IntegrationObject]
SET [Configuration] = N'{
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
WHERE [Name] = 'Judge'
  AND ([Configuration] IS NULL OR [Configuration] NOT LIKE '%AccessPath%')
  AND [IntegrationID] IN (SELECT [ID] FROM [__mj].[Integration] WHERE LOWER([Name]) = 'openwater');

UPDATE [__mj].[IntegrationObject]
SET [Configuration] = N'{
  "AccessPath": {
    "door": "Application",
    "doorPath": "/v2/Applications",
    "parentSource": "detail-harvest",
    "harvestDetailPath": "/v2/Applications/{applicationId}",
    "harvestDetailParam": "applicationId",
    "harvestSegments": [
      "roundSubmissions[]",
      "submissionFieldValues[]"
    ],
    "harvestIdKey": "mediaId",
    "entryPath": "/v2/Media/{mediaId}",
    "parentParamName": "mediaId",
    "extractionMode": "detail-object"
  }
}'
WHERE [Name] = 'Media'
  AND ([Configuration] IS NULL OR [Configuration] NOT LIKE '%AccessPath%')
  AND [IntegrationID] IN (SELECT [ID] FROM [__mj].[Integration] WHERE LOWER([Name]) = 'openwater');
