-- Eventbrite: the one writable object that carried no primary key.
--
-- A writable IntegrationObject with no IsPrimaryKey field yields a KEYLESS derived entity. On
-- Postgres, MJ's save audit-wrapper then emits an empty record identifier and every save fails with
--     syntax error at or near ","
-- while fetch keeps succeeding — so the object reads green and persists nothing.
--
-- Media Upload -> key on `upload_token`.
--   Eventbrite's media workflow is two-step: GET /media/upload/ issues an `upload_token`, and that
--   token identifies the upload for the subsequent POST. It is the only identifier in the Media
--   Upload MSON type (type, upload_token, crop_mask), and it is vendor-issued and returned in the
--   payload — so it is a real key rather than a synthesised one, and the column is actually
--   populated rather than null.
--
-- Delta migration (not a re-seed): the catalog rows already exist on installed tenants, so this
-- UPDATEs them in place. No IDs are minted and no rows are created, so nothing can collide with the
-- V202607051229 seed or re-mint an applied UUID. Idempotent by WHERE.
--
-- NOTE: the Integration row is named 'eventbrite' (lowercase) — matching the seeded identity exactly.

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 1,
    IsUniqueKey  = 1,
    IsRequired   = 1,
    AllowsNull   = 0
WHERE Name = 'upload_token'
  AND IntegrationObjectID IN (
      SELECT o.ID
      FROM [__mj].IntegrationObject o
      INNER JOIN [__mj].Integration i ON i.ID = o.IntegrationID
      WHERE i.Name = 'eventbrite'
        AND o.Name = 'Media Upload'
  );
