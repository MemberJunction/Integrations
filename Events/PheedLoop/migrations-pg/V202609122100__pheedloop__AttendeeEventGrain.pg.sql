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
   SET "IsUniqueKey" = FALSE,
       "Description" = 'Attendee code. Part of the key, NOT unique on its own: this object is fetched once per event, so an attendee who attended more than one event is returned once per event with the same code. Unique only with eventCode.'
 WHERE "ID" = 'C63B7DD1-3CE6-483F-B7B1-7C4DA3A9242B'; -- Attendees.code;
-- ── 2. The event the row belongs to, as the second key column ────────────────────────────────

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."IntegrationObjectField"
        WHERE "IntegrationObjectID" = '7FF3BC5E-EC39-4869-B6E5-4AF1C398C362'
        AND "Name" = 'eventCode'
    ) THEN
        INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "Description", "Type", "Length",
        "IsPrimaryKey", "IsUniqueKey", "AllowsNull", "IsReadOnly", "Sequence", "Status", "IsCustom", "MetadataSource")
        VALUES ('9C1F4B0E-27A6-4D3B-8E5A-6F0B71C4D982', '7FF3BC5E-EC39-4869-B6E5-4AF1C398C362', 'eventCode',
        'The event this attendee row belongs to. APIPath is /events/{eventCode}/attendees/, so the engine tags every fetched record with the resolved parent id under the template var''s own name. Declared so the row can record WHICH event its is_checked_in and checkin_date describe.',
        'string', 100, TRUE, FALSE, FALSE, TRUE, 0, 'Active', FALSE, 'Declared');
    END IF;
END $$;


-- ===================== Other =====================

-- PheedLoop — Attendees is one row per attendee PER EVENT, and its key now says so.
--
-- WHAT WAS WRONG
--   Attendees is declared `Scope: event` with APIPath /events/{eventCode}/attendees/, so the engine
--   fetches it once per event. An attendee who attended more than one event is therefore returned
--   once per event, with the same `code` each time. The key was `code` alone, and `code` was also
--   marked unique, so those rows collapsed into one and the survivor kept only the last copy.
--
--   Measured live on 2026-09-12, the same PheedLoop account on two workspaces: 370 attendee records
--   fetched across 5 events, 124 of them collapsed as repeated identities, 246 rows stored. Both
--   workspaces, identical numbers.
--
--   Losing 124 rows is the visible half. The worse half is that two of the object's fields —
--   `is_checked_in` and `checkin_date` — are PER-EVENT facts, and with no event column on the row
--   the 246 survivors each carry a check-in state from whichever event happened to be fetched last,
--   with nothing recording which. That data cannot be trusted and nothing said so.
--
-- WHY eventCode NEEDS NO NEW FETCH WORK
--   `BaseRESTIntegrationConnector` tags every record fetched through an APIPath template var with
--   the resolved parent id, under a field name that defaults to the template var's own name
--   (`nextTags = { [top.fkFieldName]: parentID }`, and fkFieldName falls back to templateVar). So
--   `eventCode` has been arriving on every Attendees record all along and being discarded for want
--   of a declared field to land in.
--
-- WHY A DELTA AND NOT A RE-SEED
--   The catalog rows already exist on installed tenants. Re-running the V202606271400 seed would
--   re-mint UUIDs, break its Flyway checksum and collide on the unique key. Same shape as
--   V202607280900__pheedloop__WritablePK.sql and V202608240630__pheedloop__UnboundedText.sql:
--   keyed by the seeded row ID, idempotent on re-run, INSERT guarded on its own natural key.
--
-- WHAT THIS DOES NOT DO
--   An existing mirror table keeps its current primary key. The schema builder warns on a key
--   change and skips it rather than rebuilding a table under live data, which is correct and is
--   also why this alone does not repair an already-built connection — that needs a rebuild of the
--   object, and the update-tables view reports the key change as deliberately left alone.
--
-- EVERY IDENTIFIER IS BRACKETED, DELIBERATELY
--   scripts/build-pg-migrations.mjs translates [X] to "X". Written bare, mixed-case columns come
--   through unquoted and PostgreSQL folds them to lower case, which are not columns on this table.

-- ── 1. `code` is part of the key, and is no longer unique on its own ──────────────────────────
--
-- Guarded on the natural key, not on IsUniqueKey, so a re-run is a no-op rather than a no-match.
