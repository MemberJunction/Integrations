-- NetSuite Connector — retire the remaining twelve presupposed record types.
--
-- Follows V202609082300, which retired the four confirmed live on a customer account. These twelve
-- are the rest of the same set, identified by the same criterion rather than by a live failure —
-- see the PR and `catalog.test.ts` for the slug-to-record-type mapping and the evidence standard.
--
-- THE DEFECT. The Declared catalog was authored by camel-collapsing NetSuite's UI labels into
-- record-type slugs ('Unit of Measure' -> unitofmeasure). For most of the 200+ standard types the
-- collapse lands on the real record-type id. For these it does not, and FetchChanges runs
-- `SELECT * FROM <slug>` through SuiteQL, so the read fails on EVERY account, on EVERY run, with
--     HTTP 400  Invalid search type: <slug>   (o:errorCode INVALID_PARAMETER)
-- The object can never sync, yet it ships Active, is auto-mapped, and spends a request, an error
-- and a retry ladder per run, forever.
--
-- WHAT IS DELIBERATELY NOT TOUCHED. `Record 'x' was not found` is a DIFFERENT error: the record
-- type is real, just not provisioned for that account (the connector reports it as
-- OBJECT_UNAVAILABLE), and it syncs the moment the account enables the feature. costcategory,
-- department, expensereport, generaltoken and issue stay Active for exactly that reason.
--
-- WHY DISABLE RATHER THAN DELETE OR REMAP. The rows exist on installed tenants, with derived
-- entities and possibly entity maps behind them, so nothing is deleted and no ID is re-minted;
-- Status='Disabled' takes them out of GetActiveIntegrationObjects and nothing else changes.
-- Remapping onto the real slug is wrong too: DiscoverObjects unions the Declared floor with the
-- account's live metadata-catalog and passes unknown slugs through verbatim, so every tenant
-- already surfaces the real record type as its own object — a remap would put two objects over
-- one table.
--
-- DELTA migration, not a re-seed: the seed stays untouched and applied, so no Flyway checksum
-- breaks and no UQ_IntegrationObject_Name collision is possible. Every statement is keyed by the
-- seeded row ID, is idempotent, and is a no-op on a database that never had the row.


-- Change Order (changeorder)
UPDATE [__mj].[IntegrationObject]
SET [Status] = N'Disabled',
    [Description] = N'Disabled: ''changeorder'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: changeorder" (INVALID_PARAMETER) on every account, so this object could never sync. No standard NetSuite record carries this id, so there is nothing to remap to; DiscoverObjects surfaces whatever the account actually has.'
WHERE [ID] = 'FCA5654D-06CB-42ED-AD32-D07411F03341';

-- Class (class)
UPDATE [__mj].[IntegrationObject]
SET [Status] = N'Disabled',
    [Description] = N'Disabled: ''class'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: class" (INVALID_PARAMETER) on every account, so this object could never sync. The real record type is ''classification'' (NetSuite''s SuiteScript record.Type id), which DiscoverObjects surfaces from the account''s live metadata-catalog.'
WHERE [ID] = '04B84F2B-AF45-49C9-B63A-D00A715F1DCF';

-- Event (event)
UPDATE [__mj].[IntegrationObject]
SET [Status] = N'Disabled',
    [Description] = N'Disabled: ''event'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: event" (INVALID_PARAMETER) on every account, so this object could never sync. The real record type is ''calendarevent'' (NetSuite''s SuiteScript record.Type id), which DiscoverObjects surfaces from the account''s live metadata-catalog.'
WHERE [ID] = '7553A959-CE23-4790-BB08-0C39B689BADE';

-- GL Audit Numbering Sequence (glauditnumberingsequence)
UPDATE [__mj].[IntegrationObject]
SET [Status] = N'Disabled',
    [Description] = N'Disabled: ''glauditnumberingsequence'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: glauditnumberingsequence" (INVALID_PARAMETER) on every account, so this object could never sync. The real record type is ''glnumberingsequence'' (NetSuite''s SuiteScript record.Type id), which DiscoverObjects surfaces from the account''s live metadata-catalog.'
WHERE [ID] = '60E5D49C-ACA2-438C-B6E0-BA6C16381C4E';

-- Other Charge for Purchase Item (otherchargeforpurchaseitem)
UPDATE [__mj].[IntegrationObject]
SET [Status] = N'Disabled',
    [Description] = N'Disabled: ''otherchargeforpurchaseitem'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: otherchargeforpurchaseitem" (INVALID_PARAMETER) on every account, so this object could never sync. The real record type is ''otherchargepurchaseitem'' (NetSuite''s SuiteScript record.Type id), which DiscoverObjects surfaces from the account''s live metadata-catalog.'
WHERE [ID] = '82E4CBE8-2756-4E55-A429-D418111FA10D';

-- Other Charge for Resale Item (otherchargeforresaleitem)
UPDATE [__mj].[IntegrationObject]
SET [Status] = N'Disabled',
    [Description] = N'Disabled: ''otherchargeforresaleitem'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: otherchargeforresaleitem" (INVALID_PARAMETER) on every account, so this object could never sync. The real record type is ''otherchargeresaleitem'' (NetSuite''s SuiteScript record.Type id), which DiscoverObjects surfaces from the account''s live metadata-catalog.'
WHERE [ID] = '330C15CA-3568-48BD-BE6B-05AB6C356832';

-- Other Charge for Sale Item (otherchargeforsaleitem)
UPDATE [__mj].[IntegrationObject]
SET [Status] = N'Disabled',
    [Description] = N'Disabled: ''otherchargeforsaleitem'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: otherchargeforsaleitem" (INVALID_PARAMETER) on every account, so this object could never sync. The real record type is ''otherchargesaleitem'' (NetSuite''s SuiteScript record.Type id), which DiscoverObjects surfaces from the account''s live metadata-catalog.'
WHERE [ID] = 'CFE5A082-DA3E-4B55-BFAD-A0F746F49DD1';

-- Period End Journal Entry (periodendjournalentry)
UPDATE [__mj].[IntegrationObject]
SET [Status] = N'Disabled',
    [Description] = N'Disabled: ''periodendjournalentry'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: periodendjournalentry" (INVALID_PARAMETER) on every account, so this object could never sync. The real record type is ''periodendjournal'' (NetSuite''s SuiteScript record.Type id), which DiscoverObjects surfaces from the account''s live metadata-catalog.'
WHERE [ID] = '65217DB8-4221-4BEB-B876-3491A4A02EC3';

-- Revenue Recognition Schedule (revenuerecognitionschedule)
UPDATE [__mj].[IntegrationObject]
SET [Status] = N'Disabled',
    [Description] = N'Disabled: ''revenuerecognitionschedule'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: revenuerecognitionschedule" (INVALID_PARAMETER) on every account, so this object could never sync. The real record type is ''revrecschedule'' (NetSuite''s SuiteScript record.Type id), which DiscoverObjects surfaces from the account''s live metadata-catalog.'
WHERE [ID] = '974E0036-F32F-454F-98A1-B4157308AEE5';

-- Revenue Recognition Template (revenuerecognitiontemplate)
UPDATE [__mj].[IntegrationObject]
SET [Status] = N'Disabled',
    [Description] = N'Disabled: ''revenuerecognitiontemplate'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: revenuerecognitiontemplate" (INVALID_PARAMETER) on every account, so this object could never sync. The real record type is ''revrectemplate'' (NetSuite''s SuiteScript record.Type id), which DiscoverObjects surfaces from the account''s live metadata-catalog.'
WHERE [ID] = 'CC8E3F77-B258-4BC3-B9AF-450E5CB21493';

-- Tax Control Account (taxcontrolaccount)
UPDATE [__mj].[IntegrationObject]
SET [Status] = N'Disabled',
    [Description] = N'Disabled: ''taxcontrolaccount'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: taxcontrolaccount" (INVALID_PARAMETER) on every account, so this object could never sync. The real record type is ''taxacct'' (NetSuite''s SuiteScript record.Type id), which DiscoverObjects surfaces from the account''s live metadata-catalog.'
WHERE [ID] = '43147977-841B-44BB-996C-B52D16904C87';

-- Unit of Measure (unitofmeasure)
UPDATE [__mj].[IntegrationObject]
SET [Status] = N'Disabled',
    [Description] = N'Disabled: ''unitofmeasure'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: unitofmeasure" (INVALID_PARAMETER) on every account, so this object could never sync. The real record type is ''unitstype'' (NetSuite''s SuiteScript record.Type id), which DiscoverObjects surfaces from the account''s live metadata-catalog.'
WHERE [ID] = '558AF6E6-D31F-4FE8-AA8A-0BF53B8FB8A4';
