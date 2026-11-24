-- Platform/HigherLogicThriveCommunity: wire 1 declared DAG-safe scalar foreign-key relationship(s) into IntegrationObjectField.
--
-- These fields carried Configuration.ReferencedType pointing to sibling IntegrationObjects
-- in the same connector, but RelatedIntegrationObjectID was left NULL when the catalog was
-- originally authored/seeded. System audit columns (CreatedById/LastModifiedById), self-references,
-- and cycle-forming back-edges are excluded so the sync DAG stays acyclic.
--
-- DELTA migration, deliberately not a re-seed: existing installed tenants keep their seeded row
-- IDs and Flyway checksums intact. Idempotent (guarded with RelatedIntegrationObjectID IS NULL).

-- Target: Ideas.IdeationKey (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = '59326488-93E3-4C3D-9AF7-150F77C1FB07',
    [RelatedIntegrationObjectFieldName] = N'IdeationKey'
WHERE [RelatedIntegrationObjectID] IS NULL
  AND [ID] IN (
    '0E10D779-09DD-48CB-8A9E-8683E166A609' -- IdeaVoters.IdeationKey
  );
