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
SET "IsPrimaryKey" = TRUE
WHERE "ID" = 'B04F8364-7CB2-4BED-B863-1CF0323521F8';

UPDATE "__mj"."IntegrationObject"
SET "Description" = 'Dataverse standard table ''appmoduleroles'' (EntitySet ''appmodulerolescollection''). 11 columns, PK appmoduleroleid (GUID). Accessed via OData v4 at /api/data/v9.2/appmodulerolescollection. Messages: Create=false Update=false Delete=false (from the page #... Primary key: `appmoduleroleid` — the table''s PrimaryIdAttribute per Microsoft''s published Dataverse table reference, and the column the Web API addresses a single record by. Without it MJ built no entity for this object at all.'
WHERE "ID" = '7782E452-9835-4E08-AC7B-DA45AD174235';

-- ── 2. entityindex -> indexid ──

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = TRUE
WHERE "ID" = 'FAF177D5-C316-4A1D-98FE-D6C3A7626681';

UPDATE "__mj"."IntegrationObject"
SET "Description" = 'Dataverse standard table ''entityindex'' (EntitySet ''entityindexes''). 8 columns, PK indexid (GUID). Accessed via OData v4 at /api/data/v9.2/entityindexes. Messages: Create=false Update=false Delete=false (from the page #messages section). No modifiedon c... Primary key: `indexid` — the table''s PrimaryIdAttribute per Microsoft''s published Dataverse table reference, and the column the Web API addresses a single record by. Without it MJ built no entity for this object at all.'
WHERE "ID" = 'BC22C52E-8220-4B88-B3CF-B0921D6C841B';

-- ── 3. indexattributes -> indexattributeid ──

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = TRUE
WHERE "ID" = 'CB9DE470-39A2-4800-AD5B-280EC9E48DB3';

UPDATE "__mj"."IntegrationObject"
SET "Description" = 'Dataverse standard table ''indexattributes'' (EntitySet ''indexattributes''). 4 columns, PK indexattributeid (GUID). Accessed via OData v4 at /api/data/v9.2/indexattributes. Messages: Create=false Update=false Delete=false (from the page #messages section)... Primary key: `indexattributeid` — the table''s PrimaryIdAttribute per Microsoft''s published Dataverse table reference, and the column the Web API addresses a single record by. Without it MJ built no entity for this object at all.'
WHERE "ID" = '6553CAEA-B087-44BA-BE27-64B7BF58C51E';

-- ── 4. ribbonmetadatatoprocess -> ribbonmetadatarowid ──

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = TRUE
WHERE "ID" = '45D18BDE-2D24-4E07-934A-A6899DC66FB1';

UPDATE "__mj"."IntegrationObject"
SET "Description" = 'Dataverse standard table ''ribbonmetadatatoprocess'' (EntitySet ''RibbonMetadataSetToProcess''). 11 columns, PK ribbonmetadatarowid (GUID). Accessed via OData v4 at /api/data/v9.2/RibbonMetadataSetToProcess. Messages: Create=false Update=false Delete=false... Primary key: `ribbonmetadatarowid` — the table''s PrimaryIdAttribute per Microsoft''s published Dataverse table reference, and the column the Web API addresses a single record by. Without it MJ built no entity for this object at all.'
WHERE "ID" = '5B1DAC52-4683-4622-B3CC-355B3BA1C491';

-- ── 5. roletemplateprivileges -> roletemplateprivilegeid ──

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = TRUE
WHERE "ID" = '4FFBAEBD-65E0-4E3E-8A48-956C02B2E2F7';

UPDATE "__mj"."IntegrationObject"
SET "Description" = 'Dataverse standard table ''roletemplateprivileges'' (EntitySet ''roletemplateprivilegescollection''). 8 columns, PK roletemplateprivilegeid (GUID). Accessed via OData v4 at /api/data/v9.2/roletemplateprivilegescollection. Messages: Create=false Update=fals... Primary key: `roletemplateprivilegeid` — the table''s PrimaryIdAttribute per Microsoft''s published Dataverse table reference, and the column the Web API addresses a single record by. Without it MJ built no entity for this object at all.'
WHERE "ID" = '40362CCD-62B2-4655-A730-89AE8E004D8B';

-- ── 6. runtimedependency -> dependencyid ──

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = TRUE
WHERE "ID" = '8A4958A9-0413-44F1-A506-8AD972563943';

UPDATE "__mj"."IntegrationObject"
SET "Description" = 'Dataverse standard table ''runtimedependency'' (EntitySet ''runtimedependencies''). 8 columns, PK dependencyid (GUID). Accessed via OData v4 at /api/data/v9.2/runtimedependencies. Messages: Create=false Update=false Delete=false (from the page #messages se... Primary key: `dependencyid` — the table''s PrimaryIdAttribute per Microsoft''s published Dataverse table reference, and the column the Web API addresses a single record by. Without it MJ built no entity for this object at all.'
WHERE "ID" = 'B586482F-433C-4D52-BDCE-31F8A82F283C';


-- ===================== Other =====================

-- Microsoft Dynamics 365 Dataverse: give the six keyless read-only catalog objects their
-- documented primary key.
--
-- WHY THESE ROWS ARE INERT TODAY.
--   A catalog object with no IsPrimaryKey field never becomes an MJ entity at all. SoftPKClassifier
--   runs a cascade at tenant setup — universal-convention, then a naming heuristic, then statistical
--   and composite inference over sample rows, then a one-shot LLM — and only then a synthetic
--   identity-hash fallback that is OFF by default. None of those tiers fires here: there is no
--   universal convention configured, and the naming heuristic matches only
--       <object>Id | <objectSingular>Id | id | uuid | guid
--   so `appmoduleroleid`, `indexid`, `indexattributeid`, `ribbonmetadatarowid`,
--   `roletemplateprivilegeid` and `dependencyid` all miss. The verdict is Confident=false, and per
--   the classifier's own contract the pipeline then "leaves the IO row PK-less; no __mj.Entity is
--   created for it until a PK resolves (the runtime D7 rule)". So an operator who selects "all
--   objects" during setup gets six rows that silently never materialize — a quieter failure than the
--   writable keyless case, which at least reads green before failing to save.
--
-- WHY EACH KEY IS THE VENDOR'S OWN, NOT AN INVENTION.
--   Every Dataverse table publishes a PrimaryIdAttribute in Microsoft's table/entity reference; it is
--   the column the Web API addresses a single record by. For all six objects below that attribute is
--   ALREADY a declared field on the catalog row, so this migration only sets IsPrimaryKey on a column
--   that exists — it creates nothing and infers nothing.
--
--   Each one is corroborated from inside this repository, without consulting the docs at all: the
--   catalog row's own Description — written by the connector's live, credentialed EntityDefinitions
--   discovery run against a real org — already spells out "PK <column> (GUID)", naming exactly the
--   column stamped below in all six cases. The catalog has therefore recorded the right key since it
--   was seeded; only the IsPrimaryKey flag that MJ actually reads was never set.
--
--   appmoduleroles -> appmoduleroleid
--     Microsoft documents PrimaryIdAttribute = `appmoduleroleid` (a GUID column, SystemRequired).
--     The sibling `appmoduleroleidunique` is the solution-sync identifier used when synchronizing
--     customizations, not the record key — the same pairing Dataverse uses across every
--     solution-component table.
--
--
--   entityindex -> indexid
--     Microsoft documents PrimaryIdAttribute = `indexid` (a GUID column, SystemRequired), described
--     as "Unique identifier of the index id".
--
--
--   indexattributes -> indexattributeid
--     Microsoft documents PrimaryIdAttribute = `indexattributeid` (a GUID column, SystemRequired),
--     described as "Unique identifier of the index attribute". The declared `indexid` is the parent
--     entity-index FK, not this row’s identity.
--
--
--   ribbonmetadatatoprocess -> ribbonmetadatarowid
--     Microsoft documents PrimaryIdAttribute = `ribbonmetadatarowid` (UUID,
--     SystemRequired), described as "Unique identifier for Ribbon Metadata Instance To Process".
--
--
--   roletemplateprivileges -> roletemplateprivilegeid
--     Microsoft documents PrimaryIdAttribute = `roletemplateprivilegeid` (UUID,
--     SystemRequired), described as "Unique identifier of the role template privileges". The declared
--     `roletemplateid` and `privilegeid` are the two FKs this intersect row joins.
--
--
--   runtimedependency -> dependencyid
--     Microsoft documents PrimaryIdAttribute = `dependencyid` (a GUID column, SystemRequired),
--     described as "Unique identifier of a dependency".
--
--
-- WHY FOUR SIBLING OBJECTS ARE DELIBERATELY LEFT ALONE.
--   subscriptionstatisticsoffline, subscriptionstatisticsoutlook, subscriptionsyncentryoffline and
--   subscriptionsyncentryoutlook each document PrimaryIdAttribute = `subscriptionid`, which IS a
--   declared field — but their own column sets show a finer row grain than one row per subscription:
--   the statistics tables declare `objecttypecode` SystemRequired alongside it, and the sync-entry
--   tables declare `objectid` and `objecttypecode` SystemRequired. Dataverse requires every table to
--   name a PrimaryIdAttribute, and for these internal offline/Outlook-sync bookkeeping tables it names
--   the leading column of a composite key. Stamping `subscriptionid` would hand MJ a key that repeats
--   across rows, collapsing many records into one on every sync — a silent data loss strictly worse
--   than the current "no entity". They stay keyless until a live round-trip settles the real grain.
--
-- WHY THE DISPOSITION IS A STAMP AND NOT A DEPRECATION.
--   DynamicsDataverseConnector.DiscoverObjects has no baked object list: it parses the credentialed
--   EntityDefinitions describe endpoint at runtime and enumerates "the COMPLETE credentialed gamut
--   (standard + custom + solution-installed)". IntegrationSchemaSync implements REACTIVATE-on-
--   rediscover, so any Status change away from 'Active' on a table the org still exposes would be
--   flipped straight back on the next discovery. For this connector a stamp is the only disposition
--   that holds.
--
-- Nothing else in the 592-object catalog moves, and no object ends up with more than one primary key
-- (both asserted by the generator that produced this file and the metadata edit together).
--
-- DELTA migration, deliberately not a re-seed: the catalog rows already exist on installed tenants,
-- so the V202606271409 seed stays untouched and applied — no existing UUID is re-minted, no Flyway
-- checksum breaks, no UQ collision. Every statement is idempotent (keyed by the seeded row ID).

-- ── 1. appmoduleroles -> appmoduleroleid ──
