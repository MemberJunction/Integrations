-- Marketing/SFMC: remove invalid ReferencedType hints on two non-FK scalar fields.
--
-- During initial WSDL+docs extraction, two scalar fields picked up shifted docDataType values as
-- ReferencedType:
--   - AutomationActivity.Sequence (xsd:int — step sequence number, not a ScheduleDefinition FK)
--   - AutomationNotification.Address (xsd:string — notification email address, not an AutomationInstance FK)
--
-- Uses JSON_MODIFY(..., '$.ReferencedType', NULL) so only the invalid ReferencedType key is
-- removed and any other tenant-added keys in Configuration (e.g. SyncDirective) are preserved.
-- Matched by (LOWER(Integration.Name), IntegrationObject.Name, IntegrationObjectField.Name) so it
-- applies cleanly across both OpenApp-seeded and pre-existing tenants. Idempotent by WHERE guard.
-- Paired with a hand-authored jsonb .pg.sql counterpart (mj migrate convert does not translate
-- JSON_MODIFY and also rewrote "xsd:int" inside string literals to "xsd:INTEGER").

UPDATE [__mj].[IntegrationObjectField]
SET [Configuration] = JSON_MODIFY([Configuration], '$.ReferencedType', NULL)
WHERE [Name] = N'Sequence'
  AND ISJSON([Configuration]) = 1
  AND JSON_VALUE([Configuration], '$.ReferencedType') IS NOT NULL
  AND [IntegrationObjectID] IN (
    SELECT o.[ID]
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    WHERE LOWER(i.[Name]) = N'sfmc'
      AND o.[Name] = N'AutomationActivity'
  );

UPDATE [__mj].[IntegrationObjectField]
SET [Configuration] = JSON_MODIFY([Configuration], '$.ReferencedType', NULL)
WHERE [Name] = N'Address'
  AND ISJSON([Configuration]) = 1
  AND JSON_VALUE([Configuration], '$.ReferencedType') IS NOT NULL
  AND [IntegrationObjectID] IN (
    SELECT o.[ID]
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    WHERE LOWER(i.[Name]) = N'sfmc'
      AND o.[Name] = N'AutomationNotification'
  );
