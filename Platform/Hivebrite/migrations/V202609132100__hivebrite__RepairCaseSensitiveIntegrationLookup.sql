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
-- 3. NotificationSettings -> CREATE `user_id` (Int, FK to User.id).
--    A SINGLETON per user: PUT /admin/v1/users/{user_id}/notification_settings, no collection and no
--    item id, so the user is the record identity. The 15 declared fields are all preference toggles
--    and carry no identifier of their own. Int matches User.id and the dominant Hivebrite key type
--    (68 of 77 declared keys are Int).
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
UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 1,
    IsUniqueKey  = 0,
    IsRequired   = 1,
    AllowsNull   = 0
WHERE Name = 'group_id'
  AND IntegrationObjectID IN (
      SELECT o.ID
      FROM [__mj].IntegrationObject o
      INNER JOIN [__mj].Integration i ON i.ID = o.IntegrationID
      WHERE LOWER(i.Name) = 'hivebrite'
        AND o.Name = 'GroupUsers'
  );

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 1,
    IsUniqueKey  = 0,
    IsRequired   = 1,
    AllowsNull   = 0
WHERE Name = 'user_id'
  AND IntegrationObjectID IN (
      SELECT o.ID
      FROM [__mj].IntegrationObject o
      INNER JOIN [__mj].Integration i ON i.ID = o.IntegrationID
      WHERE LOWER(i.Name) = 'hivebrite'
        AND o.Name = 'GroupUsers'
  );

-- ── 2. FundConfigurationEntity: composite (campaign_id, fund_id) ─────────────
UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 1,
    IsUniqueKey  = 0,
    IsRequired   = 1,
    AllowsNull   = 0
WHERE Name = 'campaign_id'
  AND IntegrationObjectID IN (
      SELECT o.ID
      FROM [__mj].IntegrationObject o
      INNER JOIN [__mj].Integration i ON i.ID = o.IntegrationID
      WHERE LOWER(i.Name) = 'hivebrite'
        AND o.Name = 'FundConfigurationEntity'
  );

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 1,
    IsUniqueKey  = 0,
    IsRequired   = 1,
    AllowsNull   = 0
WHERE Name = 'fund_id'
  AND IntegrationObjectID IN (
      SELECT o.ID
      FROM [__mj].IntegrationObject o
      INNER JOIN [__mj].Integration i ON i.ID = o.IntegrationID
      WHERE LOWER(i.Name) = 'hivebrite'
        AND o.Name = 'FundConfigurationEntity'
  );
