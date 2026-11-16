-- Platform/HigherLogicThriveCommunity: wire 1 declared foreign-key relationship(s) into IntegrationObjectField.

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
    ('0E10D779-09DD-48CB-8A9E-8683E166A609', '59326488-93E3-4C3D-9AF7-150F77C1FB07', N'IdeationKey') -- IdeaVoters.IdeationKey -> Ideas.IdeationKey
) AS v(FieldID, TargetObjectID, TargetFieldName)
    ON iof.ID = CAST(v.FieldID AS UNIQUEIDENTIFIER);

