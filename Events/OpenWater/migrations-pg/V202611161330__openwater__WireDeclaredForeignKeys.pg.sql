-- ============================================================================
-- MemberJunction PostgreSQL Migration
-- Converted from SQL Server using TypeScript conversion pipeline
-- ============================================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Schema
CREATE SCHEMA IF NOT EXISTS __mj;
SET search_path TO __mj, public;

-- Ensure backslashes in string literals are treated literally (not as escape sequences)
SET standard_conforming_strings = on;

-- NOTE: Earlier converter versions made INTEGER to BOOLEAN cast implicit by
-- modifying the system catalog so SS-style INSERT INTO bool_col VALUES (1)
-- would work. That modification required pg_catalog write privileges, which
-- managed PG (RDS, Aurora, Cloud SQL, Azure) does not grant. As of v5.30 all
-- bulk INSERTs are emitted with native TRUE/FALSE values directly, so the
-- cast modification is no longer needed. Removed to support managed-PG
-- installs out of the box.


-- ===================== Data (INSERT/UPDATE/DELETE) =====================

-- Events/OpenWater: wire 3 declared DAG-safe scalar foreign-key relationship(s) into IntegrationObjectField.
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

-- Target: User.id (3 field(s))
UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'User'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'User'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'User'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'openwater'
      AND (
        (o."Name" = 'DeletedSession' AND __mj."IntegrationObjectField"."Name" = 'deletedByUserId')
        OR (o."Name" = 'Evaluation' AND __mj."IntegrationObjectField"."Name" = 'judgeUserId')
        OR (o."Name" = 'FundTransaction' AND __mj."IntegrationObjectField"."Name" = 'approvedByUserId')
      )
  );
