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

UPDATE __mj."IntegrationObjectField"
SET "Configuration" = '{"sourceType":"xsd:INTEGER","docDataType":"ScheduleDefinition","evidence":"wsdl+docs"}'
WHERE "Name" = 'Sequence'
  AND "Configuration" LIKE '%ReferencedType%'
  AND "IntegrationObjectID" IN (
    SELECT o."ID"
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    WHERE LOWER(i."Name") = 'sfmc'
      AND o."Name" = 'AutomationActivity'
  );

UPDATE __mj."IntegrationObjectField"
SET "Configuration" = '{"sourceType":"xsd:string","docDataType":"AutomationInstance[]","evidence":"wsdl+docs"}'
WHERE "Name" = 'Address'
  AND "Configuration" LIKE '%ReferencedType%'
  AND "IntegrationObjectID" IN (
    SELECT o."ID"
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    WHERE LOWER(i."Name") = 'sfmc'
      AND o."Name" = 'AutomationNotification'
  );


-- ===================== Other =====================

-- Marketing/SFMC: remove invalid ReferencedType hints on two non-FK scalar fields.
--
-- During initial WSDL+docs extraction, two scalar fields picked up shifted docDataType values as
-- ReferencedType:
--   - AutomationActivity.Sequence (xsd:INTEGER — step sequence number, not a ScheduleDefinition FK)
--   - AutomationNotification.Address (xsd:string — notification email address, not an AutomationInstance FK)
--
-- Written with full JSON replacement (no JSON_MODIFY, which does not translate to PostgreSQL) and
-- matched by (LOWER(Integration.Name), IntegrationObject.Name, IntegrationObjectField.Name) so it
-- applies cleanly across both OpenApp-seeded and pre-existing tenants. Idempotent by WHERE guard.
