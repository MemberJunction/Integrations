-- ============================================================================

-- MemberJunction PostgreSQL Migration

-- AMS/Impexium: wire 1 declared foreign-key relationship(s) into IntegrationObjectField.

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
    ('62BBC75F-6CCB-4D80-9793-156FC43F390C', '55D39FBE-3B74-432C-AF5B-9050C196562B', 'id') -- CustomFieldValues.individualId -> Individuals.id
) AS v(field_id, target_id, target_field)
WHERE iof."ID" = v.field_id::uuid;

