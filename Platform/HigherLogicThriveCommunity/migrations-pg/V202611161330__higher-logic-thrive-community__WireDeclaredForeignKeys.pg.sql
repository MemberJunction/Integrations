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
UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '59326488-93E3-4C3D-9AF7-150F77C1FB07',
    "RelatedIntegrationObjectFieldName" = 'IdeationKey'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '0E10D779-09DD-48CB-8A9E-8683E166A609' -- IdeaVoters.IdeationKey
  );
