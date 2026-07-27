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

-- PheedLoop: the one writable object that carried no primary key.
--
-- A writable IntegrationObject with no IsPrimaryKey field yields a KEYLESS derived entity. On
-- Postgres, MJ's save audit-wrapper then emits an empty record identifier and every save fails with
--     syntax error at or near ","
-- while fetch keeps succeeding — so the object reads green and persists nothing.
--
-- EventAttendance -> WITHDRAW the write.
--    It is the event-scoped check-in ENVELOPE, not a record. All four declared fields are read-only
--    ARRAYS of attendee codes — checked_in / not_checked_in from GET /events/{eventCode}/attendance/,
--    attendees / errored_attendees from POST /events/{eventCode}/checkin/ — so a row is a whole
--    event's aggregate, with no per-record identity to key on. Turning it into one row per attendee
--    is a connector change, not a key stamp, so it is deliberately out of scope here.
--
--    Per-attendee check-in is unaffected and already modelled: the sibling SessionRegistration
--    (/events/{eventCode}/sessions/{sessionCode}/attendance/) is keyed on the attendee `code` and
--    keeps full create/update/delete. Reads on EventAttendance are unaffected.
--
-- DELTA migration, deliberately not a re-seed: the catalog rows already exist on installed tenants,
-- so the V202606271400 seed stays untouched and applied — no existing UUID is re-minted, no Flyway
-- checksum breaks, no UQ collision. Every statement is idempotent (keyed by the seeded row ID).

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "SupportsCreate" = FALSE,
    "SupportsDelete" = FALSE,
    "Description"    = 'PheedLoop Event Attendance (event-scoped check-in/check-out state). GET .../attendance/ returns checked_in / not_checked_in attendee-code lists; POST .../checkin/ checks attendees in; DELETE .../checkout/ checks them out. Source: Postman collection v3.... Event-scoped aggregate, not a record: all four declared fields are read-only arrays of attendee codes (the check-in/check-out envelope), so there is no per-record identity to key on. Per-attendee check-in remains available on SessionRegistration, which is keyed on the attendee code. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves fail. Reads are unaffected.'
WHERE "ID" = '56517D7D-E5AE-42BF-9EF5-05740515A0A1';
