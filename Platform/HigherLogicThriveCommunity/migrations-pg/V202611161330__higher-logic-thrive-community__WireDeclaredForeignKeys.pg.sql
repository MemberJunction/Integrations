-- ============================================================================

-- MemberJunction PostgreSQL Migration

-- Platform/HigherLogicThriveCommunity: wire 1 declared foreign-key relationship(s) into IntegrationObjectField.

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
    ('0E10D779-09DD-48CB-8A9E-8683E166A609', '59326488-93E3-4C3D-9AF7-150F77C1FB07', 'IdeationKey') -- IdeaVoters.IdeationKey -> Ideas.IdeationKey
) AS v(field_id, target_id, target_field)
WHERE iof."ID" = v.field_id::uuid;

