-- ============================================================================

-- MemberJunction PostgreSQL Migration

-- Events/OpenWater: wire 3 declared foreign-key relationship(s) into IntegrationObjectField.

-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA IF NOT EXISTS __mj;

SET search_path TO __mj, public;

SET standard_conforming_strings = on;

-- ===================== Data (UPDATE) =====================

UPDATE "__mj"."IntegrationObjectField" AS iof
SET "RelatedIntegrationObjectID" = v.target_id::uuid,
    "RelatedIntegrationObjectFieldName" = v.target_field
FROM (VALUES
    ('DFAB0E15-DB98-4C6A-A512-D1B5FE7EA3FF', '5E4FBD5E-2633-429D-9510-21E36CBC6FA7', 'id'), -- DeletedSession.deletedByUserId -> User.id
    ('A3B659D6-9359-411D-B597-9825999BA857', '5E4FBD5E-2633-429D-9510-21E36CBC6FA7', 'id'), -- Evaluation.judgeUserId -> User.id
    ('8A5505CF-B48E-4BC4-9984-E7F35B5BD7C9', '5E4FBD5E-2633-429D-9510-21E36CBC6FA7', 'id') -- FundTransaction.approvedByUserId -> User.id
) AS v(field_id, target_id, target_field)
WHERE iof."ID" = v.field_id::uuid;

