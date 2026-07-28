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
    "IsUniqueKey" = FALSE,
    "IsRequired" = TRUE,
    "AllowsNull" = FALSE
WHERE "Name" = 'group_id'
  AND "IntegrationObjectID" IN (
      SELECT o."ID"
      FROM "__mj"."IntegrationObject" o
      INNER JOIN "__mj"."Integration" i ON i."ID" = o."IntegrationID"
      WHERE i."Name" = 'hivebrite'
        AND o."Name" = 'GroupUsers'
  );

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = TRUE,
    "IsUniqueKey" = FALSE,
    "IsRequired" = TRUE,
    "AllowsNull" = FALSE
WHERE "Name" = 'user_id'
  AND "IntegrationObjectID" IN (
      SELECT o."ID"
      FROM "__mj"."IntegrationObject" o
      INNER JOIN "__mj"."Integration" i ON i."ID" = o."IntegrationID"
      WHERE i."Name" = 'hivebrite'
        AND o."Name" = 'GroupUsers'
  );

-- ── 2. FundConfigurationEntity: composite (campaign_id, fund_id) ─────────────

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = TRUE,
    "IsUniqueKey" = FALSE,
    "IsRequired" = TRUE,
    "AllowsNull" = FALSE
WHERE "Name" = 'campaign_id'
  AND "IntegrationObjectID" IN (
      SELECT o."ID"
      FROM "__mj"."IntegrationObject" o
      INNER JOIN "__mj"."Integration" i ON i."ID" = o."IntegrationID"
      WHERE i."Name" = 'hivebrite'
        AND o."Name" = 'FundConfigurationEntity'
  );

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = TRUE,
    "IsUniqueKey" = FALSE,
    "IsRequired" = TRUE,
    "AllowsNull" = FALSE
WHERE "Name" = 'fund_id'
  AND "IntegrationObjectID" IN (
      SELECT o."ID"
      FROM "__mj"."IntegrationObject" o
      INNER JOIN "__mj"."Integration" i ON i."ID" = o."IntegrationID"
      WHERE i."Name" = 'hivebrite'
        AND o."Name" = 'FundConfigurationEntity'
  );

-- ── 3. NotificationSettings.user_id ──────────────────────────────────────────

DO $mj$
DECLARE
  p_ID_77c88ca3 UUID;
  p_IntegrationObjectID_77c88ca3 UUID;
  p_Name_77c88ca3 VARCHAR(255);
  p_DisplayName_77c88ca3 VARCHAR(255);
  p_Description_77c88ca3 TEXT;
  p_Category_77c88ca3 VARCHAR(100);
  p_Type_77c88ca3 VARCHAR(100);
  p_Length_77c88ca3 INTEGER;
  p_Precision_77c88ca3 INTEGER;
  p_Scale_77c88ca3 INTEGER;
  p_AllowsNull_77c88ca3 BOOLEAN;
  p_DefaultValue_77c88ca3 VARCHAR(255);
  p_IsPrimaryKey_77c88ca3 BOOLEAN;
  p_IsUniqueKey_77c88ca3 BOOLEAN;
  p_IsReadOnly_77c88ca3 BOOLEAN;
  p_IsRequired_77c88ca3 BOOLEAN;
  p_RelatedIntegrationObjectID_77c88ca3 UUID;
  p_RelatedIntegrationObjectFieldName_77c88ca3 VARCHAR(255);
  p_Sequence_77c88ca3 INTEGER;
  p_Configuration_77c88ca3 TEXT;
  p_Status_77c88ca3 VARCHAR(25);
  p_IsCustom_77c88ca3 BOOLEAN;
  p_MetadataSource_77c88ca3 VARCHAR(20);
BEGIN
  p_ID_77c88ca3 := 'F5048683-161A-5F8A-9918-3264EFEF7E21';
  p_IntegrationObjectID_77c88ca3 := 'aa4a5aa7-2085-4c86-be23-fc00ee1ac0eb';
  p_Name_77c88ca3 := 'user_id';
  p_DisplayName_77c88ca3 := 'user_id';
  p_Description_77c88ca3 := 'The user whose notification settings these are. Hivebrite exposes the settings as a SINGLETON per user — PUT /admin/v1/users/{user_id}/notification_settings, with no collection and no item id — so the user is the record identity. The 15 declared fields are preference toggles and carry no identifier of their own.';
  p_Type_77c88ca3 := 'INTEGER';
  p_AllowsNull_77c88ca3 := FALSE;
  p_IsPrimaryKey_77c88ca3 := TRUE;
  p_IsUniqueKey_77c88ca3 := TRUE;
  p_IsReadOnly_77c88ca3 := TRUE;
  p_IsRequired_77c88ca3 := TRUE;
  p_RelatedIntegrationObjectID_77c88ca3 := '3bfd1123-f728-4150-8a51-1e3b3a6e765c';
  p_RelatedIntegrationObjectFieldName_77c88ca3 := 'id';
  p_Sequence_77c88ca3 := 0;
  p_Configuration_77c88ca3 := '{"ReferencedType":"User"}';
  p_Status_77c88ca3 := 'Active';
  p_IsCustom_77c88ca3 := FALSE;
  p_MetadataSource_77c88ca3 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_77c88ca3, p_IntegrationObjectID := p_IntegrationObjectID_77c88ca3, p_Name := p_Name_77c88ca3, p_DisplayName := p_DisplayName_77c88ca3, p_Description := p_Description_77c88ca3, p_Category := p_Category_77c88ca3, p_Category_Clear := TRUE, p_Type := p_Type_77c88ca3, p_Length := p_Length_77c88ca3, p_Length_Clear := TRUE, p_Precision := p_Precision_77c88ca3, p_Precision_Clear := TRUE, p_Scale := p_Scale_77c88ca3, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_77c88ca3, p_DefaultValue := p_DefaultValue_77c88ca3, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_77c88ca3, p_IsUniqueKey := p_IsUniqueKey_77c88ca3, p_IsReadOnly := p_IsReadOnly_77c88ca3, p_IsRequired := p_IsRequired_77c88ca3, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_77c88ca3, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_77c88ca3, p_Sequence := p_Sequence_77c88ca3, p_Configuration := p_Configuration_77c88ca3, p_Status := p_Status_77c88ca3, p_IsCustom := p_IsCustom_77c88ca3, p_MetadataSource := p_MetadataSource_77c88ca3);
END $mj$;


-- ===================== Other =====================

-- Hivebrite: the three writable objects that carried no primary key.
--
-- A writable IntegrationObject with no IsPrimaryKey field yields a KEYLESS derived entity. On
-- Postgres, MJ's save audit-wrapper then emits an empty record identifier and every save fails with
--     syntax error at or near ","
-- while fetch keeps succeeding — so the object reads green and persists nothing.
--
-- 1. GroupUsers -> STAMP the composite `group_id` + `user_id`.
--    The vendor addresses group membership as POST/DELETE /admin/v2/topics/users with the PAIR in the
--    body. Both halves are already declared AND required — "Unique Group ID" / "Unique User ID" — and
--    the pair is the membership identity. Same composite-join shape as YourMembership's MembersGroups
--    (WebSiteMemberID + GroupID); the repo already carries 102 composite-key objects, so this is the
--    house pattern rather than a new one.
--
-- 2. FundConfigurationEntity -> STAMP the composite `campaign_id` + `fund_id`.
--    One configuration row per (campaign, fund). The vendor's own path template is
--    PUT /admin/v2/donations/campaigns/{campaign_id}/funds/{fund_id} and both path variables are
--    already declared fields ("Donation Campaign associated to this Configuration" / "Donation Fund
--    associated to this Configuration").
--
-- 3. NotificationSettings -> CREATE `user_id` (INTEGER, FK to User.id).
--    A SINGLETON per user: PUT /admin/v1/users/{user_id}/notification_settings, no collection and no
--    item id, so the user is the record identity. The 15 declared fields are all preference toggles
--    and carry no identifier of their own. INTEGER matches User.id and the dominant Hivebrite key type
--    (68 of 77 declared keys are INTEGER).
--
-- On a composite key each member is IsPrimaryKey = 1 but IsUniqueKey = 0 — neither half is unique on
-- its own, which is exactly how the sibling composite-key objects in this catalog are declared.
--
-- The created key is IsReadOnly = 1, matching HubSpot's V202607271200 stamp of `hs_object_id` across
-- 33 objects (functionally proven on Postgres). Read-only does not stop a KEY persisting.
--
-- DELTA migration, deliberately not a re-seed: the catalog rows already exist on installed tenants,
-- so the V202606271415 seed stays untouched and applied — no existing UUID is re-minted, no Flyway
-- checksum breaks. The UPDATEs are idempotent by WHERE. The created field carries a UUID5 ID derived
-- from uuid5(DNS, 'memberjunction.integrations/<integration>/<object>/<field>'), so regenerating this
-- file yields a byte-identical UUID rather than a fresh random one.
--
-- NOTE: the Integration row is named 'hivebrite' (lowercase) — matching the seeded identity exactly.

-- ── 1. GroupUsers: composite (group_id, user_id) ─────────────────────────────
