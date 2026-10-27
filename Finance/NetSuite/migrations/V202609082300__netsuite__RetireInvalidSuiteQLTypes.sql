-- NetSuite Connector — retire the four declared objects whose suiteQLTable NetSuite rejects.
--
-- THE DEFECT. The Declared catalog was authored by camel-collapsing NetSuite's UI labels into
-- record-type slugs ('Weekly Timesheet' -> weeklytimesheet). For most of the 200+ standard types
-- the collapse lands on the real record-type id. For these four it does not — the UI label and the
-- record-type id diverge — and FetchChanges runs `SELECT * FROM <slug>` through SuiteQL, so the
-- read fails on EVERY account, on EVERY run, with
--     HTTP 400  Invalid search type: <slug>   (o:errorCode INVALID_PARAMETER)
-- The object can never sync, yet it ships Active, is auto-mapped, and spends a request, an error
-- and a retry ladder per run, forever. All four were confirmed live on a customer account.
--
--   declared object                        dead slug                          real record type
--   Requisition                            requisition                        purchaserequisition
--   Weekly Timesheet                       weeklytimesheet                    timesheet
--   Bin Putaway Worksheet                  binputawayworksheet                binworksheet
--   Advanced Intercompany Journal Entry    advancedintercompanyjournalentry   advintercompanyjournalentry
--
-- WHAT IS DELIBERATELY NOT TOUCHED. `Record 'x' was not found` is a DIFFERENT error: the record
-- type is real, just not provisioned for that account (the connector already reports it as
-- OBJECT_UNAVAILABLE). Every object failing that way stays Active — it syncs the moment the
-- account enables the feature. Only the four slugs NetSuite refuses to recognise at all are
-- retired here.
--
-- WHY DISABLE RATHER THAN DELETE OR REMAP. The rows exist on installed tenants, with derived
-- entities and possibly entity maps behind them, so nothing is deleted and no ID is re-minted;
-- Status='Disabled' takes them out of GetActiveIntegrationObjects and nothing else changes.
-- Remapping onto the real slug is wrong too: DiscoverObjects unions the Declared floor with the
-- account's live metadata-catalog and passes unknown slugs through verbatim, so every tenant
-- already surfaces the real record type as its own object — a remap would put two objects over
-- one table.
--
-- DELTA migration, not a re-seed: V202606271402 stays untouched and applied, so no Flyway checksum
-- breaks and no UQ_IntegrationObject_Name collision is possible. Every statement is keyed by the
-- seeded row ID, is idempotent, and is a no-op on a database that never had the row.

-- Advanced Intercompany Journal Entry (advancedintercompanyjournalentry)
UPDATE [__mj].[IntegrationObject]
SET [Status] = N'Disabled',
    [Description] = N'Disabled: ''advancedintercompanyjournalentry'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: advancedintercompanyjournalentry" (INVALID_PARAMETER) on every account, so this object could never sync. The real record type is ''advintercompanyjournalentry'' (NetSuite''s SuiteScript record.Type id), which DiscoverObjects surfaces from the account''s live metadata-catalog.'
WHERE [ID] = '2C37D3EE-DE6B-4867-A458-EF46086BD722';

-- Bin Putaway Worksheet (binputawayworksheet)
UPDATE [__mj].[IntegrationObject]
SET [Status] = N'Disabled',
    [Description] = N'Disabled: ''binputawayworksheet'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: binputawayworksheet" (INVALID_PARAMETER) on every account, so this object could never sync. The real record type is ''binworksheet'' (NetSuite''s SuiteScript record.Type id), which DiscoverObjects surfaces from the account''s live metadata-catalog.'
WHERE [ID] = '16308774-9E28-4CEB-B05C-8E26D50B8000';

-- Requisition (requisition)
UPDATE [__mj].[IntegrationObject]
SET [Status] = N'Disabled',
    [Description] = N'Disabled: ''requisition'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: requisition" (INVALID_PARAMETER) on every account, so this object could never sync. The real record type is ''purchaserequisition'' (NetSuite''s SuiteScript record.Type id), which DiscoverObjects surfaces from the account''s live metadata-catalog.'
WHERE [ID] = 'EF356318-5329-4F83-B580-E91D53E8C25E';

-- Weekly Timesheet (weeklytimesheet)
UPDATE [__mj].[IntegrationObject]
SET [Status] = N'Disabled',
    [Description] = N'Disabled: ''weeklytimesheet'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: weeklytimesheet" (INVALID_PARAMETER) on every account, so this object could never sync. The real record type is ''timesheet'' (NetSuite''s SuiteScript record.Type id), which DiscoverObjects surfaces from the account''s live metadata-catalog.'
WHERE [ID] = '95C81D86-54FE-4B58-A62D-AC10E74D845F';
