-- Events/OpenWater: wire 3 declared DAG-safe scalar foreign-key relationship(s) into IntegrationObjectField.
--
-- These fields carried Configuration.ReferencedType pointing to sibling IntegrationObjects
-- in the same connector, but RelatedIntegrationObjectID was left NULL when the catalog was
-- originally authored/seeded. System audit columns (CreatedById/LastModifiedById), self-references,
-- and cycle-forming back-edges are excluded so the sync DAG stays acyclic.
--
-- DELTA migration, deliberately not a re-seed: existing installed tenants keep their seeded row
-- IDs and Flyway checksums intact. Idempotent (guarded with RelatedIntegrationObjectID IS NULL).

-- Target: User.id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = '5E4FBD5E-2633-429D-9510-21E36CBC6FA7',
    [RelatedIntegrationObjectFieldName] = N'id'
WHERE [RelatedIntegrationObjectID] IS NULL
  AND [ID] IN (
    'DFAB0E15-DB98-4C6A-A512-D1B5FE7EA3FF', -- DeletedSession.deletedByUserId
    'A3B659D6-9359-411D-B597-9825999BA857', -- Evaluation.judgeUserId
    '8A5505CF-B48E-4BC4-9984-E7F35B5BD7C9' -- FundTransaction.approvedByUserId
  );
