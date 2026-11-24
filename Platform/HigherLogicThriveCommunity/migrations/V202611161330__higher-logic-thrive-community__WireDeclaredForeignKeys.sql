-- Platform/HigherLogicThriveCommunity: wire 1 declared DAG-safe scalar foreign-key relationship(s) into IntegrationObjectField.
--
-- These fields carried Configuration.ReferencedType pointing to sibling IntegrationObjects
-- in the same connector, but RelatedIntegrationObjectID was left NULL when the catalog was
-- originally authored/seeded. System audit columns (CreatedById/LastModifiedById), self-references,
-- and cycle-forming back-edges are excluded so the sync DAG stays acyclic.
--
-- DELTA migration, deliberately not a re-seed: existing installed tenants keep their seeded row
-- IDs and Flyway checksums intact. Matches by (LOWER(Integration.Name), IntegrationObject.Name,
-- IntegrationObjectField.Name) and resolves target IDs within the same Integration so it applies
-- cleanly on fresh OpenApp installs, pre-v5.43 upgraded tenants with older UUIDs, and rows whose
-- RelatedIntegrationObjectID was already populated by discovery without RelatedIntegrationObjectFieldName.

-- Target: Ideas.IdeationKey (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Ideas'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'IdeationKey')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Ideas'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Ideas'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'higherlogic-thrive'
      AND (
        (o.[Name] = N'IdeaVoters' AND [__mj].[IntegrationObjectField].[Name] = N'IdeationKey')
      )
  );
