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
   SET "Type"           = 'text',
       "Length"         = NULL,
       "IsReadOnly" = TRUE,
       "MetadataSource" = 'Declared',
       "Description"    = 'Expanded detail for the sessions this speaker is attached to. Returned by GET /events/{eventCode}/speakers/ alongside the `sessions` code list. Unbounded prose — a single speaker with several sessions runs well past any sampled width.'
 WHERE "IntegrationObjectID" = 'E397FE85-9B83-40CE-A922-32525081EC4D'
   AND "Name" = 'sessions_information';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."IntegrationObjectField"
        WHERE "IntegrationObjectID" = 'E397FE85-9B83-40CE-A922-32525081EC4D'
        AND "Name" = 'sessions_information'
    ) THEN
        INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "Description", "Type", "IsReadOnly", "Sequence", "Status", "IsCustom", "MetadataSource")
        VALUES ('62D7A579-90CC-48C2-9E30-C89FEC3B2D17', 'E397FE85-9B83-40CE-A922-32525081EC4D', 'sessions_information', 'Expanded detail for the sessions this speaker is attached to. Returned by GET /events/{eventCode}/speakers/ alongside the `sessions` code list. Unbounded prose — a single speaker with several sessions runs well past any sampled width.', 'text', TRUE, 0, 'Active', FALSE, 'Declared');
    END IF;
END $$;

UPDATE __mj."IntegrationObjectField" SET "Type" = 'text', "Length" = NULL WHERE "ID" = '60733B81-31D0-438C-B55D-01A7CEDEE8AF'; -- Attendees.about;

UPDATE __mj."IntegrationObjectField" SET "Type" = 'text', "Length" = NULL WHERE "ID" = 'EF90D75B-32D5-4BBE-BF61-656002FD7BB8'; -- EventAnnouncements.description;

UPDATE __mj."IntegrationObjectField" SET "Type" = 'text', "Length" = NULL WHERE "ID" = 'B9EFA2E4-1FC6-4D89-9ED8-8C4D4E0CDDF5'; -- Events.description;

UPDATE __mj."IntegrationObjectField" SET "Type" = 'text', "Length" = NULL WHERE "ID" = 'AFE195E1-D67F-4215-8AD8-95CDAAD8F1CC'; -- ExhibitorPromotion.description;

UPDATE __mj."IntegrationObjectField" SET "Type" = 'text', "Length" = NULL WHERE "ID" = '02BBB68D-C516-4D90-B9D2-A9651F845DC9'; -- Exhibitors.description;

UPDATE __mj."IntegrationObjectField" SET "Type" = 'text', "Length" = NULL WHERE "ID" = 'DCBF12AE-7F2C-48FA-8D93-CF9284A96DA4'; -- Members.about;

UPDATE __mj."IntegrationObjectField" SET "Type" = 'text', "Length" = NULL WHERE "ID" = 'B8F95B30-9C7D-4169-AE81-B8DB2CFEF59E'; -- OrgAnnouncements.description;

UPDATE __mj."IntegrationObjectField" SET "Type" = 'text', "Length" = NULL WHERE "ID" = 'F13417CE-51C8-4C81-85B1-2E3C34A3B111'; -- Sessions.about;

UPDATE __mj."IntegrationObjectField" SET "Type" = 'text', "Length" = NULL WHERE "ID" = 'B6281EF3-5BD7-4D1F-88A5-49D302930652'; -- SpeakerTags.description;

UPDATE __mj."IntegrationObjectField" SET "Type" = 'text', "Length" = NULL WHERE "ID" = '4EAAA47A-A40F-41DF-9AA6-C8973748F1FF'; -- Speakers.about;

UPDATE __mj."IntegrationObjectField" SET "Type" = 'text', "Length" = NULL WHERE "ID" = 'DD2B41D7-7104-48FD-8DBB-86E9DE99BEDC'; -- SponsorPromotion.description;

UPDATE __mj."IntegrationObjectField" SET "Type" = 'text', "Length" = NULL WHERE "ID" = '56F68D18-9A26-4E10-9CFB-91497EE89EDB'; -- SponsorTier.description;

UPDATE __mj."IntegrationObjectField" SET "Type" = 'text', "Length" = NULL WHERE "ID" = '590D8BBA-59AC-4C38-8B00-5AFC26CDDEE6'; -- Sponsors.description;

UPDATE __mj."IntegrationObjectField" SET "Type" = 'text', "Length" = NULL WHERE "ID" = 'F26F574C-63F4-4130-B82E-A62538C68142'; -- Tags.description;

UPDATE __mj."IntegrationObjectField" SET "Type" = 'text', "Length" = NULL WHERE "ID" = '05A8A9AB-5418-4980-B11E-AF2EF94582C7'; -- Tickets.description;


-- ===================== Other =====================

-- PheedLoop: repair Speakers.sessions_information — guard on the key the constraint actually uses.
--
-- WHAT WENT WRONG IN V202608240630
--   That migration declared the field with a plain INSERT guarded on [ID]:
--
--       IF NOT EXISTS (SELECT 1 FROM [__mj].[IntegrationObjectField]
--                      WHERE [ID] = '62D7A579-90CC-48C2-9E30-C89FEC3B2D17')
--         INSERT ...
--
--   That is the wrong key. On any tenant whose discovery has already run, the field EXISTS —
--   created by discovery under an ID this migration never chose. The ID guard therefore matched
--   nothing, the INSERT ran anyway, and the database rejected it:
--
--       duplicate key value violates unique constraint "UQ_IntegrationObjectField_Name"
--
--   PostgreSQL runs each migration transactionally, so that failure rolled back the fifteen
--   width-widening UPDATEs alongside it. On those tenants V202608240630 achieved nothing.
--
-- WHY A NEW MIGRATION RATHER THAN AN EDIT
--   V202608240630 shipped in @memberjunction/connector-pheedloop@1.4.3. Tenants where discovery had
--   NOT run applied it successfully, and Flyway recorded its checksum. Rewriting that file in place
--   would change the checksum and fail validation on every one of those tenants — turning a fixable
--   gap into a broken migration history. The published file is therefore left byte-for-byte intact
--   and the correction lands here.
--
-- WHAT THIS DOES, ON EITHER TENANT
--   · discovery HAD run (V202608240630 rolled back): the UPDATE below declares the discovered row
--     and the fifteen widths are re-applied, so the tenant ends up where 1.4.3 intended.
--   · V202608240630 SUCCEEDED: the UPDATE is a no-op re-statement of the same values and the
--     fifteen UPDATEs re-set what they already set. Idempotent either way.
--
--   ID is deliberately NOT rewritten when a row already exists. IntegrationObjectField.ID is
--   referenced by field maps and, on a keyed object, by IsKeyField wiring; re-pointing it at this
--   migration's UUID would orphan those. The row's identity is its (object, name) pair — which is
--   what the unique constraint says too.
--
--   MetadataSource is set to 'Declared'. A discovered row carries 'Discovered' and whatever width
--   sampling inferred; declaring it means saying so, the same rule the OpenWater change follows.

-- ── 1. Speakers.sessions_information — upsert on (IntegrationObjectID, Name) ──────────────────
