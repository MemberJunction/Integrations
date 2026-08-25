-- PheedLoop: free-text fields were declared with a 4000-character ceiling they do not have.
--
-- WHAT WAS WRONG
--   Fifteen prose fields were declared `Type: string, Length: 4000`. That width was never a
--   property of the source — it came from sampling, and sampling only ever sees the records it
--   sampled. PheedLoop returns unbounded prose in all fifteen: a session `about`, an exhibitor
--   `description`, a speaker bio. A declared ceiling becomes a physical column width, so a value
--   past it is truncated on the way in and the loss is silent.
--
--   `text` carries no Length, so the derived column is unbounded and the value arrives whole.
--
-- WHY A DELTA AND NOT A RE-SEED
--   The catalog rows already exist on installed tenants. Re-running the V202606271400 seed would
--   re-mint UUIDs, break its Flyway checksum and collide on the unique key. So that seed stays
--   untouched and applied, and this file carries only the difference — the same shape as
--   V202607280900__pheedloop__WritablePK.sql.
--
--   Every statement is keyed by the seeded row ID and is therefore idempotent: a re-run sets the
--   same values, and the INSERT is guarded on its own ID.
--
-- WHY Length BECOMES NULL, NOT -1 OR 0
--   NULL is what a fresh install of this metadata produces. The generator declares
--   `@Length_<hash> INT`, never assigns it, and passes `@Length_Clear = 1`. Verified against
--   Marketing/Rasa's seed, the only other connector currently declaring `text` fields. So an
--   upgraded tenant and a freshly installed one end up with identical catalog rows.
--
-- ONE NEW FIELD
--   Speakers.sessions_information — expanded per-session detail returned by
--   GET /events/{eventCode}/speakers/ alongside the `sessions` code list. Read-only, and
--   unbounded for the same reason as the fields above: one speaker with several sessions runs
--   well past any sampled width.
--
-- EVERY IDENTIFIER IS BRACKETED, DELIBERATELY
--   scripts/build-pg-migrations.mjs translates [X] to "X". Written bare, `Length` came through
--   unquoted and PostgreSQL folded it to `length`, which is not a column on this table — the
--   generated .pg.sql would have failed at run time. Bracketing is what makes the generated
--   PostgreSQL twin correct, so do not un-bracket these.

-- ── 1. Fifteen declared ceilings withdrawn ────────────────────────────────────────────────────

UPDATE [__mj].[IntegrationObjectField] SET [Type] = N'text', [Length] = NULL WHERE [ID] = '60733B81-31D0-438C-B55D-01A7CEDEE8AF'; -- Attendees.about
UPDATE [__mj].[IntegrationObjectField] SET [Type] = N'text', [Length] = NULL WHERE [ID] = 'EF90D75B-32D5-4BBE-BF61-656002FD7BB8'; -- EventAnnouncements.description
UPDATE [__mj].[IntegrationObjectField] SET [Type] = N'text', [Length] = NULL WHERE [ID] = 'B9EFA2E4-1FC6-4D89-9ED8-8C4D4E0CDDF5'; -- Events.description
UPDATE [__mj].[IntegrationObjectField] SET [Type] = N'text', [Length] = NULL WHERE [ID] = 'AFE195E1-D67F-4215-8AD8-95CDAAD8F1CC'; -- ExhibitorPromotion.description
UPDATE [__mj].[IntegrationObjectField] SET [Type] = N'text', [Length] = NULL WHERE [ID] = '02BBB68D-C516-4D90-B9D2-A9651F845DC9'; -- Exhibitors.description
UPDATE [__mj].[IntegrationObjectField] SET [Type] = N'text', [Length] = NULL WHERE [ID] = 'DCBF12AE-7F2C-48FA-8D93-CF9284A96DA4'; -- Members.about
UPDATE [__mj].[IntegrationObjectField] SET [Type] = N'text', [Length] = NULL WHERE [ID] = 'B8F95B30-9C7D-4169-AE81-B8DB2CFEF59E'; -- OrgAnnouncements.description
UPDATE [__mj].[IntegrationObjectField] SET [Type] = N'text', [Length] = NULL WHERE [ID] = 'F13417CE-51C8-4C81-85B1-2E3C34A3B111'; -- Sessions.about
UPDATE [__mj].[IntegrationObjectField] SET [Type] = N'text', [Length] = NULL WHERE [ID] = 'B6281EF3-5BD7-4D1F-88A5-49D302930652'; -- SpeakerTags.description
UPDATE [__mj].[IntegrationObjectField] SET [Type] = N'text', [Length] = NULL WHERE [ID] = '4EAAA47A-A40F-41DF-9AA6-C8973748F1FF'; -- Speakers.about
UPDATE [__mj].[IntegrationObjectField] SET [Type] = N'text', [Length] = NULL WHERE [ID] = 'DD2B41D7-7104-48FD-8DBB-86E9DE99BEDC'; -- SponsorPromotion.description
UPDATE [__mj].[IntegrationObjectField] SET [Type] = N'text', [Length] = NULL WHERE [ID] = '56F68D18-9A26-4E10-9CFB-91497EE89EDB'; -- SponsorTier.description
UPDATE [__mj].[IntegrationObjectField] SET [Type] = N'text', [Length] = NULL WHERE [ID] = '590D8BBA-59AC-4C38-8B00-5AFC26CDDEE6'; -- Sponsors.description
UPDATE [__mj].[IntegrationObjectField] SET [Type] = N'text', [Length] = NULL WHERE [ID] = 'F26F574C-63F4-4130-B82E-A62538C68142'; -- Tags.description
UPDATE [__mj].[IntegrationObjectField] SET [Type] = N'text', [Length] = NULL WHERE [ID] = '05A8A9AB-5418-4980-B11E-AF2EF94582C7'; -- Tickets.description

-- ── 2. Speakers.sessions_information ──────────────────────────────────────────────────────────
-- A plain guarded INSERT rather than spCreateIntegrationObjectField: every column this row does
-- not name has a table default (AllowsNull, IsPrimaryKey, IsUniqueKey, IsRequired, Sequence,
-- Status, IsCustom, MetadataSource, and both audit timestamps), so the sproc adds nothing here —
-- and the DECLARE/EXEC form it requires does not survive translation to PostgreSQL.

-- Guard on the UNIQUE CONSTRAINT, not on the ID. UQ_IntegrationObjectField_Name is on
-- (IntegrationObjectID, Name): where discovery reached this object first it already created
-- 'sessions_information' under a DIFFERENT ID, so an ID guard passes and the INSERT then
-- violates the constraint — failing this migration, and with it every LATER migration in the
-- chain, permanently. Guarding on the same columns the constraint covers makes the statement
-- idempotent regardless of which side created the row.
IF NOT EXISTS (SELECT 1 FROM [__mj].[IntegrationObjectField]
               WHERE [IntegrationObjectID] = 'E397FE85-9B83-40CE-A922-32525081EC4D'
                 AND [Name] = N'sessions_information')
  INSERT INTO [__mj].[IntegrationObjectField]
    ([ID], [IntegrationObjectID], [Name], [Description], [Type], [IsReadOnly], [Sequence], [Status], [IsCustom], [MetadataSource])
  VALUES ('62D7A579-90CC-48C2-9E30-C89FEC3B2D17', 'E397FE85-9B83-40CE-A922-32525081EC4D', N'sessions_information', N'Expanded detail for the sessions this speaker is attached to. Returned by GET /events/{eventCode}/speakers/ alongside the `sessions` code list. Unbounded prose — a single speaker with several sessions runs well past any sampled width.', N'text', 1, 0, N'Active', 0, N'Declared');
