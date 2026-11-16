-- Events/OpenWater: wire 3 declared foreign-key relationship(s) into IntegrationObjectField.

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
    ('DFAB0E15-DB98-4C6A-A512-D1B5FE7EA3FF', '5E4FBD5E-2633-429D-9510-21E36CBC6FA7', N'id'), -- DeletedSession.deletedByUserId -> User.id
    ('A3B659D6-9359-411D-B597-9825999BA857', '5E4FBD5E-2633-429D-9510-21E36CBC6FA7', N'id'), -- Evaluation.judgeUserId -> User.id
    ('8A5505CF-B48E-4BC4-9984-E7F35B5BD7C9', '5E4FBD5E-2633-429D-9510-21E36CBC6FA7', N'id') -- FundTransaction.approvedByUserId -> User.id
) AS v(FieldID, TargetObjectID, TargetFieldName)
    ON iof.ID = CAST(v.FieldID AS UNIQUEIDENTIFIER);

