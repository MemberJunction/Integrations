-- Marketing/SFMC: remove invalid ReferencedType hints on two non-FK scalar fields.
--
-- During initial WSDL+docs extraction, two scalar fields picked up shifted docDataType values as
-- ReferencedType:
--   - AutomationActivity.Sequence (xsd:int — step sequence number, not a ScheduleDefinition FK)
--   - AutomationNotification.Address (xsd:string — notification email address, not an AutomationInstance FK)
--
-- Written with full JSON replacement (no JSON_MODIFY, which does not translate to PostgreSQL) and
-- matched by (LOWER(Integration.Name), IntegrationObject.Name, IntegrationObjectField.Name) so it
-- applies cleanly across both OpenApp-seeded and pre-existing tenants. Idempotent by WHERE guard.

UPDATE [__mj].[IntegrationObjectField]
SET [Configuration] = N'{"sourceType":"xsd:int","docDataType":"ScheduleDefinition","evidence":"wsdl+docs"}'
WHERE [Name] = N'Sequence'
  AND [Configuration] LIKE '%ReferencedType%'
  AND [IntegrationObjectID] IN (
    SELECT o.[ID]
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    WHERE LOWER(i.[Name]) = N'sfmc'
      AND o.[Name] = N'AutomationActivity'
  );

UPDATE [__mj].[IntegrationObjectField]
SET [Configuration] = N'{"sourceType":"xsd:string","docDataType":"AutomationInstance[]","evidence":"wsdl+docs"}'
WHERE [Name] = N'Address'
  AND [Configuration] LIKE '%ReferencedType%'
  AND [IntegrationObjectID] IN (
    SELECT o.[ID]
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    WHERE LOWER(i.[Name]) = N'sfmc'
      AND o.[Name] = N'AutomationNotification'
  );
