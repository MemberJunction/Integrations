-- Hivebrite -- replay the declarations PostgreSQL silently skipped
--
-- REPAIR. Every statement replayed here already exists in an earlier migration and was a silent
-- no-op on PostgreSQL. They resolved the integration with
--
--     JOIN "__mj"."Integration" i ON i."Name" = 'hivebrite'
--
-- The Integration row is named 'Hivebrite'. SQL Server's default collation is case-INSENSITIVE, so
-- the predicate matched there and the rows landed; PostgreSQL compares strings case-SENSITIVELY, so
-- it matched nothing, the INSERT ... SELECT inserted zero rows, and the migration reported success.
--
-- Observed live on a PostgreSQL workspace 2026-09-13: Hivebrite installed 30 objects and
-- 0 of them had ZERO fields -- (no workspace observed yet -- found by the same audit).
-- No fields means no primary key, so discovery skipped all 0 with `entity.skipped-no-pk` and an
-- empty message. The same connector on a SQL Server workspace has every field.
--
-- The earlier migrations are NOT edited: they are already applied and Flyway validates their
-- checksums. This replays their statements with a case-insensitive lookup instead. Every one is
-- either guarded by NOT EXISTS or an idempotent UPDATE, so on a workspace that already has the rows
-- this migration changes nothing.
--
-- Source statements replayed: V202607271500__hivebrite__WritablePK

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
      WHERE lower(i."Name") = 'hivebrite'
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
      WHERE lower(i."Name") = 'hivebrite'
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
      WHERE lower(i."Name") = 'hivebrite'
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
      WHERE lower(i."Name") = 'hivebrite'
        AND o."Name" = 'FundConfigurationEntity'
  );
