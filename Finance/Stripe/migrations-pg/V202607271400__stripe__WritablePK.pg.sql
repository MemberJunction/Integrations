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

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = TRUE,
    "IsUniqueKey" = TRUE,
    "IsRequired" = TRUE,
    "AllowsNull" = FALSE
WHERE "Name" = 'customer'
  AND "IntegrationObjectID" IN (
      SELECT o."ID"
      FROM "__mj"."IntegrationObject" o
      INNER JOIN "__mj"."Integration" i ON i."ID" = o."IntegrationID"
      WHERE i."Name" = 'stripe'
        AND o."Name" = 'cash_balance'
  );

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE
WHERE "Name" = 'balance_settings'
  AND "SupportsWrite" = TRUE
  AND "IntegrationID" IN (
      SELECT "ID" FROM "__mj"."Integration" WHERE "Name" = 'stripe'
  );


-- ===================== Other =====================

-- Stripe: the two writable objects that carried no primary key.
--
-- A writable IntegrationObject with no IsPrimaryKey field yields a KEYLESS derived entity. On
-- Postgres, MJ's save audit-wrapper then emits an empty record identifier and every save fails with
--     syntax error at or near ","
-- while fetch keeps succeeding — so the object reads green and persists nothing.
--
-- Two different problems, two different fixes:
--
-- 1. cash_balance -> key on `customer`.
--    Stripe's own CashBalance schema declares `customer` as a property of the object (spec3.json
--    components.schemas.cash_balance: available, customer, customer_account, livemode, object,
--    settings). The resource is a SINGLETON per customer — /v1/customers/{customer}/cash_balance
--    exposes only GET and POST, with no collection and no item id — so the customer IS the record
--    identity. Unlike a path-variable-only key it is returned in the payload, so the column is
--    actually populated rather than null.
--
-- 2. balance_settings -> withdraw the write capability.
--    No identifier exists to key on. Stripe's BalanceSettings schema declares exactly two
--    properties, `object` and `payments`. /v1/balance_settings takes no path variable — the account
--    is implied by the API key — so there is nothing to key on and nothing to create a key from. A
--    synthesised account id would sit on a field this endpoint never returns, i.e. a null primary
--    key: the same silent failure in a different disguise. The object declared no create/update/
--    delete operation either, so the write flag described a capability with no implementation
--    behind it. Reads are unaffected.
--
-- Delta migration (not a re-seed): the catalog rows already exist on installed tenants, so this
-- UPDATEs them in place. No IDs are minted and no rows are created, so nothing can collide with the
-- V202607071049 seed or re-mint an applied UUID. Idempotent by WHERE.
--
-- NOTE: the Integration row is named 'stripe' (lowercase) — matching the seeded identity exactly.
