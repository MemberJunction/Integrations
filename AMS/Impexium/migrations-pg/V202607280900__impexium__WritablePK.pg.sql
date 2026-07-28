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

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = TRUE,
    "IsUniqueKey" = TRUE,
    "IsRequired" = TRUE,
    "AllowsNull" = FALSE
WHERE "Name" = 'url'
  AND "IntegrationObjectID" = '6ACB63D2-3639-4D83-96DC-6C24C798DF25';

-- ── 2. SessionRegistrations: the session code inside the path scope ──────────

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = TRUE,
    "IsUniqueKey" = TRUE,
    "IsRequired" = TRUE,
    "AllowsNull" = FALSE
WHERE "Name" = 'sessionCode'
  AND "IntegrationObjectID" = '3C9442A5-F892-4CD0-B19D-86B4DEF8DA35';

-- ── 3-8. the six add-command shapes: withdraw the write ──────────────────────

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "SupportsCreate" = FALSE,
    "Description"    = 'Add-command request body, not a record: every declared field is a writable body field, no identifier of any kind is returned (CreateIDLocation=n/a), so BuildCreatedResult already fails every create. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves fail. Reads are unaffected.'
WHERE "ID" = '780983D8-E81B-4852-8D1E-6CD89F2B2803';

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "SupportsCreate" = FALSE,
    "Description"    = 'Add-command request body, not a record: every declared field is a writable body field, no identifier of any kind is returned (CreateIDLocation=n/a), so BuildCreatedResult already fails every create. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves fail. Reads are unaffected.'
WHERE "ID" = 'A51B24F2-BA0C-493F-B500-E88DF7BACD5A';

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "SupportsCreate" = FALSE,
    "Description"    = 'Add-command request body, not a record: every declared field is a writable body field, no identifier of any kind is returned (CreateIDLocation=n/a), so BuildCreatedResult already fails every create. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves fail. Reads are unaffected.'
WHERE "ID" = '124603B1-E2F1-4A3A-B696-16E9915AFB80';

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "SupportsCreate" = FALSE,
    "Description"    = 'Add-command request body, not a record: every declared field is a writable body field, no identifier of any kind is returned (CreateIDLocation=n/a), so BuildCreatedResult already fails every create. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves fail. Reads are unaffected.'
WHERE "ID" = 'B682AA03-A53C-4A8D-B345-0FED98BA5BC0';

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "SupportsCreate" = FALSE,
    "Description"    = 'In-app notifications delivered to an individual. Write-only action: POST /Individuals/{ID}/Notifications (Add-Notification-to-Individual). Backed by NotificationData. No GET-list / no update / no delete documented. Add-command request body, not a record: every declared field is a writable body field, no identifier of any kind is returned (CreateIDLocation=n/a), so BuildCreatedResult already fails every create. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves fail. Reads are unaffected.'
WHERE "ID" = '311656B8-D89F-4FFB-8EA4-09920F693ED6';

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "SupportsUpdate" = FALSE,
    "Description"    = 'Marks an event registrant as attended for one or more events/sessions. Write-only update action: PUT /Events/Registrants/{recordNumber}/Attended (Mark-Registrant-Attended). Body is an array of {eventOrSessionCode}. Command, not a record: PUT /api/v1/Events/Registrants/{recordNumber}/Attended marks a registrant attended. UpdateIDLocation=path fills {recordNumber} from the external ID, and the only declared field is the event/session code — there is no registrant identifier to key on. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves fail. Reads are unaffected.'
WHERE "ID" = 'FBC6D8E9-4BDA-4478-9E66-E3427AA2D2ED';


-- ===================== Other =====================

-- Impexium (re:Members AMS): the eight writable objects that carried no primary key.
--
-- A writable IntegrationObject with no IsPrimaryKey field yields a KEYLESS derived entity. On
-- Postgres, MJ's save audit-wrapper then emits an empty record identifier and every save fails with
--     syntax error at or near ","
-- while fetch keeps succeeding — so the object reads green and persists nothing.
--
-- Impexium's keyed Individual sub-resources key EITHER on a server id (Addresses.id, Phones.id) OR
-- on a NATURAL key when the vendor assigns none (Emails.address, Categories.code,
-- CustomFieldValues.name, Memberships.code). The eight below split cleanly along that line.
--
-- 1. Links -> STAMP `url`.
--    A web link on an individual is identified by its URL: `url` is the only required field, and
--    the connector's delete carries DeleteIDLocation='body' — its own source note reads "Links
--    additionally identifies the target via the request BODY". MJ fills that body id from the
--    external id, i.e. from the key. Same natural-key shape as the sibling Emails object, which
--    keys on `address`.
--
-- 2. SessionRegistrations -> STAMP `sessionCode`.
--    POST /api/v1/Events/{Event Code}/Sessions/Register/{Customer ID or Record Number} already
--    scopes the event and the customer in the path; `sessionCode` is the single required body
--    field and names WHICH session inside that scope. Same shape as the sibling Categories object
--    (path-scoped to an individual, keyed on `code`).
--
-- 3-7. EducationCredits, Activities, Notes, Relationships, Notifications -> WITHDRAW the write.
--    Add-command request bodies, not records. Every declared field on all five is a writable body
--    field — not one read-only or server-assigned field between them — and each carries
--    CreateIDLocation='n/a', meaning the create response yields no record id. That is already a
--    hard runtime failure today, not a latent one: BaseIntegrationConnector.BuildCreatedResult
--    returns Success:false on an empty id ("returned HTTP 2xx but the response contained no record
--    ID — treating as a failure to avoid silently losing the record"). Microsoft's own published
--    Impexium connector documents the same operations (Add Note to Individual, Add Activity, Add
--    Notification to Individual, Add Education Credits to Individual, Add Relationship to
--    Individual) as add-only, with no return schema. Reads are unaffected.
--
-- 8. EventAttendance -> WITHDRAW the write.
--    A command, not a record: PUT /api/v1/Events/Registrants/{recordNumber}/Attended marks a
--    registrant attended. UpdateIDLocation='path' fills {recordNumber} from the external id, so
--    keying on the object's single declared field (eventOrSessionCode) would send the event code
--    where the registrant record number belongs — actively wrong, not merely unhelpful. No
--    registrant identifier is declared, and none may be invented.
--
-- DELTA migration, deliberately not a re-seed: the catalog rows already exist on installed tenants,
-- so the V202607131715 seed stays untouched and applied — no existing UUID is re-minted, no Flyway
-- checksum breaks, no UQ collision. Every statement is idempotent (keyed by the seeded row ID).

-- ── 1. Links: the URL is the web link's identity ─────────────────────────────
