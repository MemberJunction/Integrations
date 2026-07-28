-- ============================================================================
-- MemberJunction PostgreSQL Migration
-- Converted from SQL Server using TypeScript conversion pipeline
-- ============================================================================

-- Extensions
--
-- HAND-CORRECTED after conversion: @memberjunction/sql-converter's CORE_METADATA_BOOLEAN_COLUMNS
-- catalog lists IntegrationObject."SupportsWrite" but NOT "SupportsCreate"/"SupportsUpdate"/
-- "SupportsDelete", so the converter left those three as the SQL Server bit literals 0/1. PG rejects
-- them at APPLY time with 'column "SupportsCreate" is of type boolean but expression is of type
-- integer'. The 0s below are rewritten to FALSE by hand. Fixed upstream in MemberJunction/MJ #3294;
-- once that ships in a consumed release the converter emits FALSE itself and this note can go.

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

-- MagnetMail: the one writable object that carried no primary key.
--
-- A writable IntegrationObject with no IsPrimaryKey field yields a KEYLESS derived entity. On
-- Postgres, MJ's save audit-wrapper then emits an empty record identifier and every save fails with
--     syntax error at or near ","
-- while fetch keeps succeeding — so the object reads green and persists nothing.
--
-- RecipientSuppressionList -> WITHDRAW the write.
--    It is the uploadSuppressionList request PAYLOAD, not a record — and the catalog row says so
--    itself. Its own Configuration carries the observation, sourced from the WSDL:
--        "write-only-object: type of the uploadSuppressionList write payload (bulk suppress).
--         No read operation response contains a RecipientSuppressionList element."
--        (Provenance: scripts/wsdl.xml — WSDL response/request type analysis)
--    Its three fields (suppressby, type, recipients) are the bulk-suppress command arguments; there
--    is no identifier, and none may be invented. The recipient records themselves are unaffected —
--    the sibling Recipient object is keyed on `id` and keeps create/update.
--
-- DELTA migration, deliberately not a re-seed: the catalog rows already exist on installed tenants,
-- so the V202607051443 seed stays untouched and applied — no existing UUID is re-minted, no Flyway
-- checksum breaks, no UQ collision. Every statement is idempotent (keyed by the seeded row ID).

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "SupportsCreate" = FALSE,
    "Description"    = 'MagnetMail SOAP data record ''RecipientSuppressionList'' (3 fields), inherits Asset. Write payload, not a record — the object''s own recorded provenance says so: "write-only-object: type of the uploadSuppressionList write payload (bulk suppress). No read operation response contains a RecipientSuppressionList element." (scripts/wsdl.xml). Write withdrawn: a writable object with no primary key derives a keyless entity whose saves fail. Reads are unaffected.'
WHERE "ID" = 'ac960d2d-2ea1-4bae-856c-9962451ae95a';
