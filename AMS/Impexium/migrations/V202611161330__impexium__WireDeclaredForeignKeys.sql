-- AMS/Impexium: wire 1 declared DAG-safe scalar foreign-key relationship(s) into IntegrationObjectField.
--
-- These fields carried Configuration.ReferencedType pointing to sibling IntegrationObjects
-- in the same connector, but RelatedIntegrationObjectID was left NULL when the catalog was
-- originally authored/seeded. System audit columns (CreatedById/LastModifiedById), self-references,
-- and cycle-forming back-edges are excluded so the sync DAG stays acyclic.
--
-- DELTA migration, deliberately not a re-seed: existing installed tenants keep their seeded row
-- IDs and Flyway checksums intact. Idempotent (guarded with RelatedIntegrationObjectID IS NULL).

-- Target: Individuals.id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = '55D39FBE-3B74-432C-AF5B-9050C196562B',
    [RelatedIntegrationObjectFieldName] = N'id'
WHERE [RelatedIntegrationObjectID] IS NULL
  AND [ID] IN (
    '62BBC75F-6CCB-4D80-9793-156FC43F390C' -- CustomFieldValues.individualId
  );
