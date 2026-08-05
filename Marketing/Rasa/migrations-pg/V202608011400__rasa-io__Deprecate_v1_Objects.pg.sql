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

DELETE FROM __mj."IntegrationObjectField"
WHERE "IntegrationObjectID" IN (
        'A684795C-86A3-4B41-9C24-C6A6AC9DB211',
        'F98715AE-390B-4E59-9B2E-9DEF709CEF32',
        'B4F1A9E2-7DE9-4A02-B409-10AD8DD46F52',
        'AAB4EED3-97FF-47B8-9C37-F3176F9ADF16',
        'C08330B0-A063-4406-AFF7-393A894EF736',
        '1FF3A542-3B5F-44A0-A187-0E2805E07D55',
        '3745CF57-56D1-4D6F-B186-946ED08A5367',
        '1865C7EF-85E0-49FA-9678-421656A9B211')
   OR "RelatedIntegrationObjectID" IN (
        'A684795C-86A3-4B41-9C24-C6A6AC9DB211',
        'F98715AE-390B-4E59-9B2E-9DEF709CEF32',
        'B4F1A9E2-7DE9-4A02-B409-10AD8DD46F52',
        'AAB4EED3-97FF-47B8-9C37-F3176F9ADF16',
        'C08330B0-A063-4406-AFF7-393A894EF736',
        '1FF3A542-3B5F-44A0-A187-0E2805E07D55',
        '3745CF57-56D1-4D6F-B186-946ED08A5367',
        '1865C7EF-85E0-49FA-9678-421656A9B211');

DELETE FROM __mj."IntegrationObject"
WHERE "ID" IN (
        'A684795C-86A3-4B41-9C24-C6A6AC9DB211',
        'F98715AE-390B-4E59-9B2E-9DEF709CEF32',
        'B4F1A9E2-7DE9-4A02-B409-10AD8DD46F52',
        'AAB4EED3-97FF-47B8-9C37-F3176F9ADF16',
        'C08330B0-A063-4406-AFF7-393A894EF736',
        '1FF3A542-3B5F-44A0-A187-0E2805E07D55',
        '3745CF57-56D1-4D6F-B186-946ED08A5367',
        '1865C7EF-85E0-49FA-9678-421656A9B211');


-- ===================== Other =====================

-- rasa.io Connector v2.0.0 — retire the eight v1 IntegrationObject rows.
--
-- v2 is a `redo`: every v1 object was renamed from the vendor's URL slug to MJ's singular
-- PascalCase convention (`persons`->`Person`, `posts`->`Post`, ...), each mapping 1:1. The v2 seed
-- (V202608011359) CREATES the 34 new rows but does not remove the 8 prior ones, because the
-- generator only emits what `mj sync push` changed. Left in place they stay Status='Active' and
-- would sync the same vendor endpoints a second time into the old slug-named tables.
--
-- Deleting by hardcoded ID (the IDs seeded by V202607111617) rather than by name, so this is a
-- no-op on a database that never had v1 and cannot collide with the v2 rows. IntegrationObjectField
-- is deleted first -- it is the only table with an FK to IntegrationObject
-- (IntegrationObjectID and RelatedIntegrationObjectID).
--
-- Destination tables created by v1 are NOT dropped. Data is never destroyed here; see MIGRATION-v2.md.
--
-- v1 ID -> v2 object:
--   A684795C-86A3-4B41-9C24-C6A6AC9DB211  analytics-activities -> Analytics Activity
--   F98715AE-390B-4E59-9B2E-9DEF709CEF32  analytics-articles   -> Analytics Article
--   B4F1A9E2-7DE9-4A02-B409-10AD8DD46F52  analytics-topics     -> Analytics Topic
--   AAB4EED3-97FF-47B8-9C37-F3176F9ADF16  insights-actions     -> Insight Action
--   C08330B0-A063-4406-AFF7-393A894EF736  insights-topics      -> Insight Topic
--   1FF3A542-3B5F-44A0-A187-0E2805E07D55  person-attributes    -> Person Attribute
--   3745CF57-56D1-4D6F-B186-946ED08A5367  persons              -> Person
--   1865C7EF-85E0-49FA-9678-421656A9B211  posts                -> Post
