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

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."IntegrationObject"
        WHERE "IntegrationID" = '3FD08940-E11D-4926-8149-6115F3B8ABF3' AND "Name" = 'journalLineDimensionSetLines'
    ) THEN
        INSERT INTO __mj."IntegrationObject"
        ("ID", "IntegrationID", "Name", "DisplayName", "Description", "Category", "APIPath", "ResponseDataKey",
        "SupportsPagination", "PaginationType", "SupportsIncrementalSync", "SupportsWrite", "Sequence", "Status",
        "IsCustom", "CreateAPIPath", "CreateMethod", "CreateBodyShape", "CreateIDLocation",
        "UpdateAPIPath", "UpdateMethod", "UpdateBodyShape", "UpdateIDLocation",
        "DeleteAPIPath", "DeleteMethod", "DeleteIDLocation",
        "MetadataSource", "SupportsCreate", "SupportsUpdate", "SupportsDelete",
        "SyncStrategy", "ContentHashApplicable", "StableOrderingKey", "WriteAPIPath", "WriteMethod")
        VALUES
        ('59A03914-49FE-46D1-AD42-317E043F5F52', '3FD08940-E11D-4926-8149-6115F3B8ABF3', 'journalLineDimensionSetLines', 'Journal Line Dimension Set Lines',
        'Dimension set lines addressed under a JOURNAL LINE. Business Central navigates dimensionSetLines from 24 parent types; the sibling `dimensionSetLines` object covers the sales-order parent and this one covers the journal line, so dimensions can be written to a journal entry. Same resource, different access path — `parentType` distinguishes them on the wire.',
        'journalLine children', '/companies({id})/journals({id})/journalLines({id})/dimensionSetLines', 'value',
        TRUE, 'Cursor', FALSE, TRUE, 71, 'Active',
        FALSE, '/companies({id})/journals({id})/journalLines({id})/dimensionSetLines', 'POST', 'flat', 'body',
        '/companies({id})/journals({id})/journalLines({id})/dimensionSetLines({id})', 'PATCH', 'flat', 'path',
        '/companies({id})/journals({id})/journalLines({id})/dimensionSetLines({id})', 'DELETE', 'path',
        'Declared', 1, 1, 1,
        'FullPullHashDiff', 1, 'id', '/companies({id})/journals({id})/journalLines({id})/dimensionSetLines', 'POST');
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."IntegrationObjectField"
        WHERE "IntegrationObjectID" = '59A03914-49FE-46D1-AD42-317E043F5F52' AND "Name" = 'id'
    ) THEN
        INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "Description", "Type", "Length", "IsPrimaryKey", "IsReadOnly",
        "Sequence", "Status", "IsCustom", "MetadataSource")
        VALUES
        ('01EC715E-D97E-4A28-B23D-D98EB91090B6', '59A03914-49FE-46D1-AD42-317E043F5F52', 'id', 'The unique ID of the dimension set line. Non-editable.', 'uuid',
        NULL,
        TRUE, TRUE,
        1, 'Active', FALSE, 'Declared');
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."IntegrationObjectField"
        WHERE "IntegrationObjectID" = '59A03914-49FE-46D1-AD42-317E043F5F52' AND "Name" = 'code'
    ) THEN
        INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "Description", "Type", "Length", "IsPrimaryKey", "IsReadOnly",
        "Sequence", "Status", "IsCustom", "MetadataSource")
        VALUES
        ('2DE35971-C0D4-41DE-8A28-F23F30258C4B', '59A03914-49FE-46D1-AD42-317E043F5F52', 'code', 'The code of the dimension set line.', 'string',
        NULL,
        FALSE, FALSE,
        2, 'Active', FALSE, 'Declared');
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."IntegrationObjectField"
        WHERE "IntegrationObjectID" = '59A03914-49FE-46D1-AD42-317E043F5F52' AND "Name" = 'consolidationCode'
    ) THEN
        INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "Description", "Type", "Length", "IsPrimaryKey", "IsReadOnly",
        "Sequence", "Status", "IsCustom", "MetadataSource")
        VALUES
        ('A824D0FC-AC99-4C63-AEED-9B81B8BE91AE', '59A03914-49FE-46D1-AD42-317E043F5F52', 'consolidationCode', 'consolidationCode (string) on the dimensionSetLine resource. Microsoft''s Properties table leaves the description cell blank.', 'string',
        NULL,
        FALSE, FALSE,
        3, 'Active', FALSE, 'Declared');
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."IntegrationObjectField"
        WHERE "IntegrationObjectID" = '59A03914-49FE-46D1-AD42-317E043F5F52' AND "Name" = 'parentId'
    ) THEN
        INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "Description", "Type", "Length", "IsPrimaryKey", "IsReadOnly",
        "Sequence", "Status", "IsCustom", "MetadataSource")
        VALUES
        ('37274F11-4908-4122-81C0-781BEA60E4BC', '59A03914-49FE-46D1-AD42-317E043F5F52', 'parentId', 'The ID of the parent entity.', 'uuid',
        NULL,
        FALSE, FALSE,
        4, 'Active', FALSE, 'Declared');
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."IntegrationObjectField"
        WHERE "IntegrationObjectID" = '59A03914-49FE-46D1-AD42-317E043F5F52' AND "Name" = 'parentType'
    ) THEN
        INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "Description", "Type", "Length", "IsPrimaryKey", "IsReadOnly",
        "Sequence", "Status", "IsCustom", "MetadataSource")
        VALUES
        ('1ED30900-446F-4C4C-AF88-E65943E5541B', '59A03914-49FE-46D1-AD42-317E043F5F52', 'parentType', 'The type of the parent document of the dimension set line. It can be " ", "Journal Line", "Sales Order", "Sales Order Line", "Sales Quote", "Sales Quote Line", "Sales Credit Memo", "Sales Credit Memo Line", "Sales Invoice", "Sales Invoice Line",...', 'string',
        NULL,
        FALSE, FALSE,
        5, 'Active', FALSE, 'Declared');
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."IntegrationObjectField"
        WHERE "IntegrationObjectID" = '59A03914-49FE-46D1-AD42-317E043F5F52' AND "Name" = 'displayName'
    ) THEN
        INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "Description", "Type", "Length", "IsPrimaryKey", "IsReadOnly",
        "Sequence", "Status", "IsCustom", "MetadataSource")
        VALUES
        ('C520A208-D3D0-46C2-B65F-BE9AE9F72B10', '59A03914-49FE-46D1-AD42-317E043F5F52', 'displayName', 'Specifies the dimension set line''s name. This name will appear on all sales documents for the dimension set line.', 'string',
        NULL,
        FALSE, FALSE,
        6, 'Active', FALSE, 'Declared');
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."IntegrationObjectField"
        WHERE "IntegrationObjectID" = '59A03914-49FE-46D1-AD42-317E043F5F52' AND "Name" = 'valueId'
    ) THEN
        INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "Description", "Type", "Length", "IsPrimaryKey", "IsReadOnly",
        "Sequence", "Status", "IsCustom", "MetadataSource")
        VALUES
        ('7D173AD4-CC0E-41F4-9341-B9C7457EB0F3', '59A03914-49FE-46D1-AD42-317E043F5F52', 'valueId', 'The unique ID of the value of the dimension.', 'uuid',
        NULL,
        FALSE, FALSE,
        7, 'Active', FALSE, 'Declared');
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."IntegrationObjectField"
        WHERE "IntegrationObjectID" = '59A03914-49FE-46D1-AD42-317E043F5F52' AND "Name" = 'valueCode'
    ) THEN
        INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "Description", "Type", "Length", "IsPrimaryKey", "IsReadOnly",
        "Sequence", "Status", "IsCustom", "MetadataSource")
        VALUES
        ('B5229146-D368-443A-90C4-F30486FF950A', '59A03914-49FE-46D1-AD42-317E043F5F52', 'valueCode', 'The code of the value of the dimension.', 'string',
        NULL,
        FALSE, FALSE,
        8, 'Active', FALSE, 'Declared');
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."IntegrationObjectField"
        WHERE "IntegrationObjectID" = '59A03914-49FE-46D1-AD42-317E043F5F52' AND "Name" = 'valueConsolidationCode'
    ) THEN
        INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "Description", "Type", "Length", "IsPrimaryKey", "IsReadOnly",
        "Sequence", "Status", "IsCustom", "MetadataSource")
        VALUES
        ('DBF6DB7F-E637-4A34-8E10-21628C84942B', '59A03914-49FE-46D1-AD42-317E043F5F52', 'valueConsolidationCode', 'valueConsolidationCode (string) on the dimensionSetLine resource. Microsoft''s Properties table leaves the description cell blank.', 'string',
        NULL,
        FALSE, FALSE,
        9, 'Active', FALSE, 'Declared');
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM __mj."IntegrationObjectField"
        WHERE "IntegrationObjectID" = '59A03914-49FE-46D1-AD42-317E043F5F52' AND "Name" = 'valueDisplayName'
    ) THEN
        INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "Description", "Type", "Length", "IsPrimaryKey", "IsReadOnly",
        "Sequence", "Status", "IsCustom", "MetadataSource")
        VALUES
        ('C8FBD2E9-E7FE-433C-9581-EF4291FAB2E0', '59A03914-49FE-46D1-AD42-317E043F5F52', 'valueDisplayName', 'The display name of the value of the dimension. Read-Only.', 'string',
        NULL,
        FALSE, TRUE,
        10, 'Active', FALSE, 'Declared');
    END IF;
END $$;


-- ===================== Other =====================

-- Business Central: address dimensionSetLines under a JOURNAL LINE as well as a sales order.
--
-- WHAT IS MISSING TODAY
--   `dimensionSetLines` is catalogued with a single parent:
--       /companies({id})/salesOrders({id})/dimensionSetLines
--   so dimensions can never be written to a journal line. Business Central supports it, the connector's
--   CreateRecord is fully generic (it resolves CreateAPIPath/CreateMethod off the IntegrationObject row),
--   and the resource's own `parentType` field description names "Journal Line" first among valid parents.
--   The catalog was the only thing in the way.
--
-- VERIFIED AGAINST A LIVE TENANT (Test environment, API v2.0, 2026-08-25)
--   BC's $metadata declares the navigation property on journalLine:
--       journalLine -> dimensionSetLines : Collection(dimensionSetLine)
--   and the path is live for both read and write:
--       GET  /companies({id})/journals({id})/journalLines({id})/dimensionSetLines  -> 200
--       POST (empty body)                                                            -> 400 BadRequest
--                                                                "Values must be provided in the body."
--   A 400 on payload validation, not a 405 on method. For contrast, the two objects that genuinely are
--   read-only answer differently and are correctly catalogued as such — they are NOT changed here:
--       POST /companies({id})/dimensions       -> 405 BadRequest_MethodNotAllowed
--       POST /companies({id})/dimensionValues  -> 405 BadRequest_MethodNotAllowed
--
-- WHY A SECOND OBJECT RATHER THAN A CHANGED PATH
--   UQ_IntegrationObject_Name is unique on (IntegrationID, Name), and the sales-order parent is in use, so
--   the journal-line access path needs its own row. `dimensionSetLine` is parent-polymorphic: BC navigates
--   to it from 24 EntityTypes, and `parentType` distinguishes them on the wire. This adds the one parent
--   that is blocking journal-entry export; the other 22 remain uncatalogued and are a modelling question
--   rather than a path correction — see the PR.
--
-- GUARDED ON THE CONSTRAINT'S OWN KEY, NOT ON ID
--   Every guard below keys on (IntegrationID, Name) for the object and (IntegrationObjectID, Name) for its
--   fields — the columns the unique constraints actually use. Guarding on ID is what broke
--   V202608240630__pheedloop__UnboundedText: the row already existed under an ID the migration never chose,
--   the guard matched nothing, the INSERT ran, and the unique constraint rejected it — taking the whole
--   transactional migration down with it. Same mistake is not repeated here.

-- ── 1. The IntegrationObject ──────────────────────────────────────────────────────────────────
