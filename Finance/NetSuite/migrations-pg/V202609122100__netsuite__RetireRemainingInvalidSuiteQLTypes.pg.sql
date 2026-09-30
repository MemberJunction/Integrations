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

-- ===================== Data (INSERT/UPDATE/DELETE) =====================


-- Change Order (changeorder)
UPDATE __mj."IntegrationObject"
SET "Status" = 'Disabled',
    "Description" = 'Disabled: ''changeorder'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: changeorder" (INVALID_PARAMETER) on every account, so this object could never sync. No standard NetSuite record carries this id, so there is nothing to remap to; DiscoverObjects surfaces whatever the account actually has.'
WHERE "ID" = 'FCA5654D-06CB-42ED-AD32-D07411F03341';

-- Class (class)
UPDATE __mj."IntegrationObject"
SET "Status" = 'Disabled',
    "Description" = 'Disabled: ''class'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: class" (INVALID_PARAMETER) on every account, so this object could never sync. The real record type is ''classification'' (NetSuite''s SuiteScript record.Type id), which DiscoverObjects surfaces from the account''s live metadata-catalog.'
WHERE "ID" = '04B84F2B-AF45-49C9-B63A-D00A715F1DCF';

-- Event (event)
UPDATE __mj."IntegrationObject"
SET "Status" = 'Disabled',
    "Description" = 'Disabled: ''event'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: event" (INVALID_PARAMETER) on every account, so this object could never sync. The real record type is ''calendarevent'' (NetSuite''s SuiteScript record.Type id), which DiscoverObjects surfaces from the account''s live metadata-catalog.'
WHERE "ID" = '7553A959-CE23-4790-BB08-0C39B689BADE';

-- GL Audit Numbering Sequence (glauditnumberingsequence)
UPDATE __mj."IntegrationObject"
SET "Status" = 'Disabled',
    "Description" = 'Disabled: ''glauditnumberingsequence'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: glauditnumberingsequence" (INVALID_PARAMETER) on every account, so this object could never sync. The real record type is ''glnumberingsequence'' (NetSuite''s SuiteScript record.Type id), which DiscoverObjects surfaces from the account''s live metadata-catalog.'
WHERE "ID" = '60E5D49C-ACA2-438C-B6E0-BA6C16381C4E';

-- Other Charge for Purchase Item (otherchargeforpurchaseitem)
UPDATE __mj."IntegrationObject"
SET "Status" = 'Disabled',
    "Description" = 'Disabled: ''otherchargeforpurchaseitem'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: otherchargeforpurchaseitem" (INVALID_PARAMETER) on every account, so this object could never sync. The real record type is ''otherchargepurchaseitem'' (NetSuite''s SuiteScript record.Type id), which DiscoverObjects surfaces from the account''s live metadata-catalog.'
WHERE "ID" = '82E4CBE8-2756-4E55-A429-D418111FA10D';

-- Other Charge for Resale Item (otherchargeforresaleitem)
UPDATE __mj."IntegrationObject"
SET "Status" = 'Disabled',
    "Description" = 'Disabled: ''otherchargeforresaleitem'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: otherchargeforresaleitem" (INVALID_PARAMETER) on every account, so this object could never sync. The real record type is ''otherchargeresaleitem'' (NetSuite''s SuiteScript record.Type id), which DiscoverObjects surfaces from the account''s live metadata-catalog.'
WHERE "ID" = '330C15CA-3568-48BD-BE6B-05AB6C356832';

-- Other Charge for Sale Item (otherchargeforsaleitem)
UPDATE __mj."IntegrationObject"
SET "Status" = 'Disabled',
    "Description" = 'Disabled: ''otherchargeforsaleitem'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: otherchargeforsaleitem" (INVALID_PARAMETER) on every account, so this object could never sync. The real record type is ''otherchargesaleitem'' (NetSuite''s SuiteScript record.Type id), which DiscoverObjects surfaces from the account''s live metadata-catalog.'
WHERE "ID" = 'CFE5A082-DA3E-4B55-BFAD-A0F746F49DD1';

-- Period End Journal Entry (periodendjournalentry)
UPDATE __mj."IntegrationObject"
SET "Status" = 'Disabled',
    "Description" = 'Disabled: ''periodendjournalentry'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: periodendjournalentry" (INVALID_PARAMETER) on every account, so this object could never sync. The real record type is ''periodendjournal'' (NetSuite''s SuiteScript record.Type id), which DiscoverObjects surfaces from the account''s live metadata-catalog.'
WHERE "ID" = '65217DB8-4221-4BEB-B876-3491A4A02EC3';

-- Revenue Recognition Schedule (revenuerecognitionschedule)
UPDATE __mj."IntegrationObject"
SET "Status" = 'Disabled',
    "Description" = 'Disabled: ''revenuerecognitionschedule'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: revenuerecognitionschedule" (INVALID_PARAMETER) on every account, so this object could never sync. The real record type is ''revrecschedule'' (NetSuite''s SuiteScript record.Type id), which DiscoverObjects surfaces from the account''s live metadata-catalog.'
WHERE "ID" = '974E0036-F32F-454F-98A1-B4157308AEE5';

-- Revenue Recognition Template (revenuerecognitiontemplate)
UPDATE __mj."IntegrationObject"
SET "Status" = 'Disabled',
    "Description" = 'Disabled: ''revenuerecognitiontemplate'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: revenuerecognitiontemplate" (INVALID_PARAMETER) on every account, so this object could never sync. The real record type is ''revrectemplate'' (NetSuite''s SuiteScript record.Type id), which DiscoverObjects surfaces from the account''s live metadata-catalog.'
WHERE "ID" = 'CC8E3F77-B258-4BC3-B9AF-450E5CB21493';

-- Tax Control Account (taxcontrolaccount)
UPDATE __mj."IntegrationObject"
SET "Status" = 'Disabled',
    "Description" = 'Disabled: ''taxcontrolaccount'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: taxcontrolaccount" (INVALID_PARAMETER) on every account, so this object could never sync. The real record type is ''taxacct'' (NetSuite''s SuiteScript record.Type id), which DiscoverObjects surfaces from the account''s live metadata-catalog.'
WHERE "ID" = '43147977-841B-44BB-996C-B52D16904C87';

-- Unit of Measure (unitofmeasure)
UPDATE __mj."IntegrationObject"
SET "Status" = 'Disabled',
    "Description" = 'Disabled: ''unitofmeasure'' is not a NetSuite record type — SuiteQL rejects it with HTTP 400 "Invalid search type: unitofmeasure" (INVALID_PARAMETER) on every account, so this object could never sync. The real record type is ''unitstype'' (NetSuite''s SuiteScript record.Type id), which DiscoverObjects surfaces from the account''s live metadata-catalog.'
WHERE "ID" = '558AF6E6-D31F-4FE8-AA8A-0BF53B8FB8A4';
