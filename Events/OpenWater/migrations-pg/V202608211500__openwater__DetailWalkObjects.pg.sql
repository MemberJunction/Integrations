-- OpenWater: four objects that live behind the application detail.
-- Postgres twin of V202608211500__openwater__DetailWalkObjects.sql - see that file for the full rationale
-- (the detail-walk extraction modes, each object access path, and why every id is an unsized String).
--
-- Idempotent: every statement is guarded on its own absence. IDs are hardcoded so the same object carries
-- the same ID on every tenant. Audit columns are not set.

-- 1. The four integration objects (spCreateIntegrationObject, guarded on absence) ----------------------------

-- ApplicationRoundSubmission
DO $mig$
BEGIN
IF NOT EXISTS (SELECT 1 FROM "__mj"."IntegrationObject"
               WHERE "IntegrationID" = 'F2209CE3-5BC2-4E5C-9661-F409BE8FF9AA'::uuid AND "Name" = 'ApplicationRoundSubmission') THEN
  PERFORM __mj."spCreateIntegrationObject"(p_ID := '1DFFCEA1-1B6B-4AD6-ACEC-4649A5D35EB6'::uuid, p_IntegrationID := 'F2209CE3-5BC2-4E5C-9661-F409BE8FF9AA'::uuid, p_Name := 'ApplicationRoundSubmission', p_DisplayName := 'Application Round Submissions', p_Description := 'OpenWater per-round submission state of an Application (embedded in the application detail). Access: Applications -> /v2/Applications/{applicationId} -> roundSubmissions[].', p_Category := NULL, p_Category_Clear := TRUE, p_APIPath := '(embedded in /v2/Applications/{applicationId} roundSubmissions[])', p_ResponseDataKey := NULL, p_ResponseDataKey_Clear := TRUE, p_DefaultPageSize := 100, p_SupportsPagination := FALSE, p_PaginationType := 'None', p_SupportsIncrementalSync := FALSE, p_SupportsWrite := FALSE, p_DefaultQueryParams := NULL, p_DefaultQueryParams_Clear := TRUE, p_Configuration := '{
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
}', p_Configuration_Clear := TRUE, p_Sequence := 0, p_Status := 'Active', p_WriteAPIPath := NULL, p_WriteAPIPath_Clear := TRUE, p_WriteMethod := 'POST', p_DeleteMethod := 'DELETE', p_IsCustom := FALSE, p_CreateAPIPath := NULL, p_CreateAPIPath_Clear := TRUE, p_CreateMethod := NULL, p_CreateMethod_Clear := TRUE, p_CreateBodyShape := NULL, p_CreateBodyShape_Clear := TRUE, p_CreateBodyKey := NULL, p_CreateBodyKey_Clear := TRUE, p_CreateIDLocation := NULL, p_CreateIDLocation_Clear := TRUE, p_UpdateAPIPath := NULL, p_UpdateAPIPath_Clear := TRUE, p_UpdateMethod := NULL, p_UpdateMethod_Clear := TRUE, p_UpdateBodyShape := NULL, p_UpdateBodyShape_Clear := TRUE, p_UpdateBodyKey := NULL, p_UpdateBodyKey_Clear := TRUE, p_UpdateIDLocation := NULL, p_UpdateIDLocation_Clear := TRUE, p_DeleteAPIPath := NULL, p_DeleteAPIPath_Clear := TRUE, p_DeleteIDLocation := NULL, p_DeleteIDLocation_Clear := TRUE, p_IncrementalWatermarkField := NULL, p_MetadataSource := 'Declared', p_SupportsCreate := FALSE, p_SupportsUpdate := FALSE, p_SupportsDelete := FALSE, p_SyncStrategy := NULL, p_SyncStrategy_Clear := TRUE, p_ContentHashApplicable := TRUE, p_StableOrderingKey := NULL, p_StableOrderingKey_Clear := TRUE);
END IF;
END
$mig$;

-- ApplicationFile
DO $mig$
BEGIN
IF NOT EXISTS (SELECT 1 FROM "__mj"."IntegrationObject"
               WHERE "IntegrationID" = 'F2209CE3-5BC2-4E5C-9661-F409BE8FF9AA'::uuid AND "Name" = 'ApplicationFile') THEN
  PERFORM __mj."spCreateIntegrationObject"(p_ID := 'F3AAE390-75DC-4D9F-BB59-6997378904B5'::uuid, p_IntegrationID := 'F2209CE3-5BC2-4E5C-9661-F409BE8FF9AA'::uuid, p_Name := 'ApplicationFile', p_DisplayName := 'Application Files', p_Description := 'OpenWater file-upload field values across an Application round submissions (embedded in the application detail). Access: Applications -> /v2/Applications/{applicationId} -> roundSubmissions[] -> fieldValues[] (elements carrying a mediaId).', p_Category := NULL, p_Category_Clear := TRUE, p_APIPath := '(embedded in /v2/Applications/{applicationId} roundSubmissions[].fieldValues[])', p_ResponseDataKey := NULL, p_ResponseDataKey_Clear := TRUE, p_DefaultPageSize := 100, p_SupportsPagination := FALSE, p_PaginationType := 'None', p_SupportsIncrementalSync := FALSE, p_SupportsWrite := FALSE, p_DefaultQueryParams := NULL, p_DefaultQueryParams_Clear := TRUE, p_Configuration := '{
  "AccessPath": {
    "door": "Application",
    "doorPath": "/v2/Applications",
    "entryPath": "/v2/Applications/{applicationId}",
    "parentParamName": "applicationId",
    "nestingSegments": [
      "roundSubmissions[]",
      "fieldValues[]"
    ],
    "elementFilter": {
      "key": "mediaId",
      "exists": true
    },
    "extractionMode": "detail-embedded"
  }
}', p_Configuration_Clear := TRUE, p_Sequence := 0, p_Status := 'Active', p_WriteAPIPath := NULL, p_WriteAPIPath_Clear := TRUE, p_WriteMethod := 'POST', p_DeleteMethod := 'DELETE', p_IsCustom := FALSE, p_CreateAPIPath := NULL, p_CreateAPIPath_Clear := TRUE, p_CreateMethod := NULL, p_CreateMethod_Clear := TRUE, p_CreateBodyShape := NULL, p_CreateBodyShape_Clear := TRUE, p_CreateBodyKey := NULL, p_CreateBodyKey_Clear := TRUE, p_CreateIDLocation := NULL, p_CreateIDLocation_Clear := TRUE, p_UpdateAPIPath := NULL, p_UpdateAPIPath_Clear := TRUE, p_UpdateMethod := NULL, p_UpdateMethod_Clear := TRUE, p_UpdateBodyShape := NULL, p_UpdateBodyShape_Clear := TRUE, p_UpdateBodyKey := NULL, p_UpdateBodyKey_Clear := TRUE, p_UpdateIDLocation := NULL, p_UpdateIDLocation_Clear := TRUE, p_DeleteAPIPath := NULL, p_DeleteAPIPath_Clear := TRUE, p_DeleteIDLocation := NULL, p_DeleteIDLocation_Clear := TRUE, p_IncrementalWatermarkField := NULL, p_MetadataSource := 'Declared', p_SupportsCreate := FALSE, p_SupportsUpdate := FALSE, p_SupportsDelete := FALSE, p_SyncStrategy := NULL, p_SyncStrategy_Clear := TRUE, p_ContentHashApplicable := TRUE, p_StableOrderingKey := NULL, p_StableOrderingKey_Clear := TRUE);
END IF;
END
$mig$;

-- Media
DO $mig$
BEGIN
IF NOT EXISTS (SELECT 1 FROM "__mj"."IntegrationObject"
               WHERE "IntegrationID" = 'F2209CE3-5BC2-4E5C-9661-F409BE8FF9AA'::uuid AND "Name" = 'Media') THEN
  PERFORM __mj."spCreateIntegrationObject"(p_ID := '7AB4A0D8-D990-4E71-A55D-5A3528D70611'::uuid, p_IntegrationID := 'F2209CE3-5BC2-4E5C-9661-F409BE8FF9AA'::uuid, p_Name := 'Media', p_DisplayName := 'Media', p_Description := 'OpenWater media descriptor for uploaded files. Access: mediaIds harvested from Application details -> /v2/Media/{mediaId} (the detail response is the record).', p_Category := NULL, p_Category_Clear := TRUE, p_APIPath := '/v2/Media/{mediaId}', p_ResponseDataKey := NULL, p_ResponseDataKey_Clear := TRUE, p_DefaultPageSize := 100, p_SupportsPagination := FALSE, p_PaginationType := 'None', p_SupportsIncrementalSync := FALSE, p_SupportsWrite := FALSE, p_DefaultQueryParams := NULL, p_DefaultQueryParams_Clear := TRUE, p_Configuration := '{
  "AccessPath": {
    "door": "Application",
    "doorPath": "/v2/Applications",
    "parentSource": "detail-harvest",
    "harvestDetailPath": "/v2/Applications/{applicationId}",
    "harvestDetailParam": "applicationId",
    "harvestSegments": [
      "roundSubmissions[]",
      "fieldValues[]"
    ],
    "harvestIdKey": "mediaId",
    "entryPath": "/v2/Media/{mediaId}",
    "parentParamName": "mediaId",
    "extractionMode": "detail-object"
  }
}', p_Configuration_Clear := TRUE, p_Sequence := 0, p_Status := 'Active', p_WriteAPIPath := NULL, p_WriteAPIPath_Clear := TRUE, p_WriteMethod := 'POST', p_DeleteMethod := 'DELETE', p_IsCustom := FALSE, p_CreateAPIPath := NULL, p_CreateAPIPath_Clear := TRUE, p_CreateMethod := NULL, p_CreateMethod_Clear := TRUE, p_CreateBodyShape := NULL, p_CreateBodyShape_Clear := TRUE, p_CreateBodyKey := NULL, p_CreateBodyKey_Clear := TRUE, p_CreateIDLocation := NULL, p_CreateIDLocation_Clear := TRUE, p_UpdateAPIPath := NULL, p_UpdateAPIPath_Clear := TRUE, p_UpdateMethod := NULL, p_UpdateMethod_Clear := TRUE, p_UpdateBodyShape := NULL, p_UpdateBodyShape_Clear := TRUE, p_UpdateBodyKey := NULL, p_UpdateBodyKey_Clear := TRUE, p_UpdateIDLocation := NULL, p_UpdateIDLocation_Clear := TRUE, p_DeleteAPIPath := NULL, p_DeleteAPIPath_Clear := TRUE, p_DeleteIDLocation := NULL, p_DeleteIDLocation_Clear := TRUE, p_IncrementalWatermarkField := NULL, p_MetadataSource := 'Declared', p_SupportsCreate := FALSE, p_SupportsUpdate := FALSE, p_SupportsDelete := FALSE, p_SyncStrategy := NULL, p_SyncStrategy_Clear := TRUE, p_ContentHashApplicable := TRUE, p_StableOrderingKey := NULL, p_StableOrderingKey_Clear := TRUE);
END IF;
END
$mig$;

-- ApplicationWinnerType
DO $mig$
BEGIN
IF NOT EXISTS (SELECT 1 FROM "__mj"."IntegrationObject"
               WHERE "IntegrationID" = 'F2209CE3-5BC2-4E5C-9661-F409BE8FF9AA'::uuid AND "Name" = 'ApplicationWinnerType') THEN
  PERFORM __mj."spCreateIntegrationObject"(p_ID := '7D3F6794-4A3A-4C2F-9255-A27448CB4B50'::uuid, p_IntegrationID := 'F2209CE3-5BC2-4E5C-9661-F409BE8FF9AA'::uuid, p_Name := 'ApplicationWinnerType', p_DisplayName := 'Application Winner Types', p_Description := 'OpenWater winner types configured on program rounds (embedded). Access: Programs -> rounds[] -> winnerTypes[].', p_Category := NULL, p_Category_Clear := TRUE, p_APIPath := '(embedded in /v2/Programs rounds[].winnerTypes[])', p_ResponseDataKey := NULL, p_ResponseDataKey_Clear := TRUE, p_DefaultPageSize := 100, p_SupportsPagination := FALSE, p_PaginationType := 'None', p_SupportsIncrementalSync := FALSE, p_SupportsWrite := FALSE, p_DefaultQueryParams := NULL, p_DefaultQueryParams_Clear := TRUE, p_Configuration := '{
  "AccessPath": {
    "door": "Program",
    "doorPath": "/v2/Programs",
    "nestingSegments": [
      "rounds[]",
      "winnerTypes[]"
    ],
    "extractionMode": "embedded-array"
  }
}', p_Configuration_Clear := TRUE, p_Sequence := 0, p_Status := 'Active', p_WriteAPIPath := NULL, p_WriteAPIPath_Clear := TRUE, p_WriteMethod := 'POST', p_DeleteMethod := 'DELETE', p_IsCustom := FALSE, p_CreateAPIPath := NULL, p_CreateAPIPath_Clear := TRUE, p_CreateMethod := NULL, p_CreateMethod_Clear := TRUE, p_CreateBodyShape := NULL, p_CreateBodyShape_Clear := TRUE, p_CreateBodyKey := NULL, p_CreateBodyKey_Clear := TRUE, p_CreateIDLocation := NULL, p_CreateIDLocation_Clear := TRUE, p_UpdateAPIPath := NULL, p_UpdateAPIPath_Clear := TRUE, p_UpdateMethod := NULL, p_UpdateMethod_Clear := TRUE, p_UpdateBodyShape := NULL, p_UpdateBodyShape_Clear := TRUE, p_UpdateBodyKey := NULL, p_UpdateBodyKey_Clear := TRUE, p_UpdateIDLocation := NULL, p_UpdateIDLocation_Clear := TRUE, p_DeleteAPIPath := NULL, p_DeleteAPIPath_Clear := TRUE, p_DeleteIDLocation := NULL, p_DeleteIDLocation_Clear := TRUE, p_IncrementalWatermarkField := NULL, p_MetadataSource := 'Declared', p_SupportsCreate := FALSE, p_SupportsUpdate := FALSE, p_SupportsDelete := FALSE, p_SyncStrategy := NULL, p_SyncStrategy_Clear := TRUE, p_ContentHashApplicable := TRUE, p_StableOrderingKey := NULL, p_StableOrderingKey_Clear := TRUE);
END IF;
END
$mig$;

-- 2. Their declared fields (guarded direct INSERT, per the V202608050910 delta precedent) --------------------

INSERT INTO "__mj"."IntegrationObjectField"
    ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length", "AllowsNull",
     "IsPrimaryKey", "IsUniqueKey", "IsReadOnly", "IsRequired", "RelatedIntegrationObjectID", "Sequence",
     "Status", "IsCustom", "MetadataSource")
SELECT v.field_id::uuid, o."ID", v.field_name, v.display_name, v.descr, v.type, v.length, v.allows_null,
       v.is_pk, v.is_unique, false, v.is_req, p."ID", 0, 'Active', false, 'Declared'
FROM (VALUES
    ('9C281CA4-60CD-449F-8155-5CC7808B471D', 'ApplicationRoundSubmission', 'applicationId', 'Application Id', 'String', NULL::int, false, true, false, true, 'Application',
     'The Application this submission belongs to. Injected by the connector from the access path (/v2/Applications/{applicationId} detail) rather than returned in the element body, so it is declared String - see V202608050910 for the sizing rationale.'),
    ('11581F42-B2CE-441A-B3D4-BDCEF0C31C12', 'ApplicationRoundSubmission', 'roundId', 'Round Id', 'String', NULL::int, false, true, false, true, 'Rounds',
     'Round this submission belongs to. Declared String rather than Integer - see V202608050910 for the sizing rationale.'),
    ('A3B8ABD8-E494-40FA-8621-97A58E6E2030', 'ApplicationRoundSubmission', 'roundName', 'Round Name', 'String', NULL::int, true, false, false, false, NULL,
     'Round name as denormalized on the submission.'),
    ('43E0A806-5C33-4DEE-861C-483C71343E4D', 'ApplicationRoundSubmission', 'status', 'Status', 'String', NULL::int, true, false, false, false, NULL,
     'Submission status.'),
    ('65677BDB-30F3-4D8D-9236-B745FDF1E317', 'ApplicationRoundSubmission', 'startedAtUtc', 'Started At Utc', 'DateTime', NULL::int, true, false, false, false, NULL,
     'When the applicant started this round submission (UTC).'),
    ('CC319DA2-36BD-46CB-BAF1-D33F510AAF64', 'ApplicationRoundSubmission', 'updatedAtUtc', 'Updated At Utc', 'DateTime', NULL::int, true, false, false, false, NULL,
     'Last update to this round submission (UTC).'),
    ('D4223F1B-85EA-4B65-ABD9-AE4BA2F0A1B5', 'ApplicationRoundSubmission', 'updatedByUserAtUtc', 'Updated By User At Utc', 'DateTime', NULL::int, true, false, false, false, NULL,
     'Last update made by the applicant (UTC).'),
    ('5B250646-C1FD-44AA-9663-4FAC882A6A67', 'ApplicationRoundSubmission', 'finalizedAtUtc', 'Finalized At Utc', 'DateTime', NULL::int, true, false, false, false, NULL,
     'When the submission was finalized (UTC).'),
    ('3613D8EF-2D39-431E-9CE7-1DEB50748CAC', 'ApplicationRoundSubmission', 'allowUserToMakeEdits', 'Allow User To Make Edits', 'Boolean', NULL::int, true, false, false, false, NULL,
     'Whether the applicant may still edit this submission.'),
    ('AE1DC9BD-DE4F-44C4-8D32-8ADBA02B2B73', 'ApplicationRoundSubmission', 'isPaid', 'Is Paid', 'Boolean', NULL::int, true, false, false, false, NULL,
     'Whether payment for this submission is complete.'),
    ('600C17AB-7FE6-40E6-A133-B912086C825A', 'ApplicationRoundSubmission', 'isWinner', 'Is Winner', 'Boolean', NULL::int, true, false, false, false, NULL,
     'Whether this submission was marked a winner.'),
    ('C0B7B305-A98B-41AE-902D-55F1B0908491', 'ApplicationRoundSubmission', 'invoiceId', 'Invoice Id', 'String', NULL::int, true, false, false, false, 'Invoice',
     'Invoice attached to this submission, when any. Declared String - see V202608050910 for the sizing rationale.'),
    ('78A20156-801E-408A-95D9-C4A9B3ECD8B9', 'ApplicationFile', 'mediaId', 'Media Id', 'String', NULL::int, false, true, true, true, 'Media',
     'Media id of the uploaded file (also this record identity). Declared String - see V202608050910 for the sizing rationale.'),
    ('0036DC50-6C4D-437D-9125-5D9E7A3AE9B9', 'ApplicationFile', 'applicationId', 'Application Id', 'String', NULL::int, true, false, false, false, 'Application',
     'The Application this file belongs to. Injected by the connector from the access path (/v2/Applications/{applicationId} detail).'),
    ('E580B35C-C1E1-47C8-8B01-F45264A52AF7', 'ApplicationFile', 'alias', 'Alias', 'String', NULL::int, true, false, false, false, NULL,
     'Field alias the file was uploaded under.'),
    ('6874A594-7919-489E-9C1D-CF3731138ACF', 'ApplicationFile', 'caption', 'Caption', 'String', NULL::int, true, false, false, false, NULL,
     'Caption entered for the uploaded file.'),
    ('1FB33C79-4EE9-42AB-AA30-C02B0C9C146B', 'Media', 'mediaId', 'Media Id', 'String', NULL::int, false, true, true, true, NULL,
     'Media id. Injected by the connector from the access path (/v2/Media/{mediaId}) - the ids are harvested from Application details.'),
    ('0F061F0D-9B9D-46F5-A9FF-1DDAA00105DC', 'Media', 'url', 'Url', 'String', 2048, true, false, false, false, NULL,
     'Download URL of the file.'),
    ('FB8A6F19-DAC0-4E5B-A4A2-EE098A1B8983', 'Media', 'fileName', 'File Name', 'String', NULL::int, true, false, false, false, NULL,
     'Original file name.'),
    ('CF825A2F-F232-4B8B-9506-27AEE250C1FA', 'ApplicationWinnerType', 'id', 'Id', 'String', NULL::int, false, true, true, true, NULL,
     'Winner type id. Declared String - see V202608050910 for the sizing rationale.'),
    ('821BE41B-B855-49A0-BB88-E7AB661C13DD', 'ApplicationWinnerType', 'name', 'Name', 'String', NULL::int, true, false, false, false, NULL,
     'Winner type name.')
) AS v(field_id, object_name, field_name, display_name, type, length, allows_null, is_pk, is_unique, is_req, related_object_name, descr)
JOIN "__mj"."Integration" i ON i."Name" = 'openwater'
JOIN "__mj"."IntegrationObject" o ON o."IntegrationID" = i."ID" AND o."Name" = v.object_name
LEFT JOIN "__mj"."IntegrationObject" p ON p."IntegrationID" = i."ID" AND p."Name" = v.related_object_name
WHERE NOT EXISTS (
    SELECT 1 FROM "__mj"."IntegrationObjectField" f
    WHERE f."IntegrationObjectID" = o."ID" AND f."Name" = v.field_name);
