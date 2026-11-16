-- AMS/Impexium: wire 1 declared foreign-key relationship(s) into IntegrationObjectField.

--

-- These fields carried Configuration.ReferencedType (and IsForeignKey metadata) pointing to

-- sibling IntegrationObjects in the same connector, but RelatedIntegrationObjectID was left NULL

-- when the catalog was originally authored/seeded.

--

-- DELTA migration, deliberately not a re-seed: existing installed tenants keep their seeded row

-- IDs and Flyway checksums intact. Idempotent (updates directly by seeded IntegrationObjectField.ID).

UPDATE iof
SET RelatedIntegrationObjectID = CAST(v.TargetObjectID AS UNIQUEIDENTIFIER),
    RelatedIntegrationObjectFieldName = v.TargetFieldName
FROM [__mj].[IntegrationObjectField] AS iof
INNER JOIN (VALUES
    ('62BBC75F-6CCB-4D80-9793-156FC43F390C', '55D39FBE-3B74-432C-AF5B-9050C196562B', N'id') -- CustomFieldValues.individualId -> Individuals.id
) AS v(FieldID, TargetObjectID, TargetFieldName)
    ON iof.ID = CAST(v.FieldID AS UNIQUEIDENTIFIER);

