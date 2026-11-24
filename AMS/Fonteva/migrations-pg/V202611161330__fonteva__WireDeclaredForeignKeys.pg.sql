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

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '927AA313-825E-443A-ADA0-8A35917533CC',
    "RelatedIntegrationObjectFieldName" = 'id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'EB060262-8CBF-44B4-82F4-30A571502771' -- Assignment.assignmentRole
  );

-- Target: BadgeType.id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '2CA8405F-CAB3-4E03-B68F-2D9C105A4CD9',
    "RelatedIntegrationObjectFieldName" = 'id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '307AF408-7394-4939-AD82-414B81041365', -- Badge.badgeType
    '5E12E821-3842-4B6C-BD04-1E8E10B703E9' -- BadgeWorkflow.badgeType
  );

-- Target: BusinessGroup.id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'CC5E8E4F-FC6C-4BEF-9E1B-1765E536EDEA',
    "RelatedIntegrationObjectFieldName" = 'id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '41EE2DE5-CA4A-4FCB-A55C-7245AD7B325D', -- CreditMemo.businessGroup
    'C4AD7D4E-AD80-4D41-8807-5D832612D7F9', -- Invoice.businessGroup
    '3C18E245-F533-4E7A-BA43-1A4C55163A91', -- PaymentGateway.businessGroup
    'A3E9D2CA-BCE6-4E1B-AB71-965AA4DC19CF', -- Receipt.businessGroup
    'DB15D265-E708-4516-B9F8-8287DC57EDE4', -- SalesOrder.businessGroup
    '13A1AAFC-9AF2-46BE-B9AE-1DB8EBBC0EFC', -- SalesOrderLine.businessGroup
    '0DE7809C-27E8-4C3A-B1F7-1355E0F90DF3' -- ScheduledPaymentLine.businessGroup
  );

-- Target: Event.id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '9278419F-3CFC-467F-AA97-94545455DCD1',
    "RelatedIntegrationObjectFieldName" = 'id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '28666C31-95EF-44C6-8E02-8A64D1AB1CD0', -- EventChatterGroup.event
    'D9968FCF-B899-42AE-85B5-674F29624A24' -- SalesOrderLine.event
  );

-- Target: Invoice.id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '06AFD189-9045-407C-86B1-4A1F8EBD9488',
    "RelatedIntegrationObjectFieldName" = 'id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '37C5A399-1DBA-49C6-A236-EC82597B6E7A', -- CreditMemo.invoice
    '97D6CA16-32DC-464E-A58B-882A7DB1F23F', -- CreditNote.invoice
    '3C01D081-4391-4618-8AA3-B703F7D1DDD1', -- ReceiptLine.invoice
    'AA7DEBFD-105D-4308-8FBE-DDF3EBD1BFC0' -- ScheduledPayment.invoice
  );

-- Target: Item.id (8 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '0FDD9C18-5551-4B2B-A6F7-84F730F3725D',
    "RelatedIntegrationObjectFieldName" = 'id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'A265BC28-8749-41CC-A961-06DC57C676AE', -- Assignment.item
    'EFFF789F-947D-43B3-BE08-12F76380F515', -- BadgeWorkflow.item
    '21B76AC8-F5EB-4139-880C-9C09C85A62CC', -- ReceiptLine.item
    '2614C3A0-E8FE-4851-AF48-82CE0F88CF37', -- SalesOrderLine.item
    '6B5EBA99-E13F-441D-9526-9C42B8A9CB19', -- ScheduledPaymentLine.item
    '3FC4C56C-5F00-44EF-80F5-EA4A46F97C88', -- Subscription.item
    '307B3817-BB78-49AE-8F25-430AB44ED810', -- SubscriptionLine.item
    '6B33BEA2-65E0-4F98-B87F-EEA71BF60A2F' -- Term.item
  );

-- Target: PaymentGateway.id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'DD9471EE-499C-4978-9F70-4692D7C0AB96',
    "RelatedIntegrationObjectFieldName" = 'id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '87B7582B-22F0-4EA0-A9AB-B3B6C35F70B1', -- Receipt.paymentGateway
    '28E4EE88-723A-4724-B914-3CB0EE0A9B1A' -- ScheduledPayment.paymentGateway
  );

-- Target: PaymentMethod.id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'A2765979-B351-4CD0-9A9B-B5CAAEA1F733',
    "RelatedIntegrationObjectFieldName" = 'id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '968020CD-546F-40FE-81B6-74EAA22C747A', -- Receipt.paymentMethod
    'E4D8B3B7-7AD5-45C9-9841-6A91280F4128', -- SalesOrderLine.paymentMethod
    '6DF81F16-B8AB-49BC-B98E-E4D5DA4E88CD', -- ScheduledPayment.paymentMethod
    '970678DB-1339-4BD5-9B70-7CEB3A8DADFA' -- Subscription.paymentMethod
  );

-- Target: PriceRule.id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '05455BF0-36C4-4C2E-B9C0-FDBD3E4E045C',
    "RelatedIntegrationObjectFieldName" = 'id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'A48DB0F0-52AE-4C50-AEC9-6B686BC690C1', -- SalesOrderLine.priceRule
    '127ED20D-7448-4CC8-AAEF-CBFCFB29C9DD' -- ScheduledPaymentLine.priceRule
  );

-- Target: Receipt.id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '44639C90-C63C-4316-9C8C-BD7D13F99C51',
    "RelatedIntegrationObjectFieldName" = 'id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '97891A40-B1FC-495A-90C6-DC9168F4D2EF' -- ReceiptLine.receipt
  );

-- Target: SalesOrder.id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '1D1D26B2-BED6-4E5A-9F42-FBBD43439113',
    "RelatedIntegrationObjectFieldName" = 'id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'B43EED04-5911-42B9-9B29-29F03BA3B786', -- Invoice.salesOrder
    '40C2CE2B-5FDB-4A29-9274-AB49C8EC84D9', -- Receipt.salesOrder
    '3FBC4F0D-A414-438C-AED5-30CFA996C497', -- SalesOrderLine.salesOrder
    '0453C245-1E48-44BF-9BCE-54893C4E3933' -- ScheduledPayment.salesOrder
  );

-- Target: SalesOrderLine.id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '87CC22EF-3B9E-45C2-B65B-8180264BBD4A',
    "RelatedIntegrationObjectFieldName" = 'id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'BC0A0626-F0A4-4A93-B783-D95ABF90743E', -- Assignment.salesOrderLine
    '5C9E5E33-328F-4EA9-9AC1-A492F39A6BED', -- ScheduledPaymentLine.salesOrderLine
    '9DEE791D-D321-4CB9-ABEF-72126873E0D1' -- SubscriptionLine.salesOrderLine
  );

-- Target: ScheduledPayment.id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '6B39A9E8-924A-4F47-B2D2-8AE63F19E566',
    "RelatedIntegrationObjectFieldName" = 'id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'BD0ED606-09B8-40FA-A78C-C9690479FF0F' -- ScheduledPaymentLine.scheduledPayment
  );

-- Target: Subscription.id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '813A97C2-6E75-4F69-AEEC-FDCBB7518224',
    "RelatedIntegrationObjectFieldName" = 'id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '0F132B2B-15F2-40F9-93A0-01931C7B7D36', -- Assignment.subscription
    'A2CE6BFC-B9D4-4007-A9BA-C4218EA86C65', -- Invoice.subscription
    '2F7E18E1-3ED3-460B-A2C9-0C6F6E943DD4', -- SalesOrderLine.subscription
    '21E235E1-4AA7-41E0-A815-B97F1E3BEC83', -- ScheduledPayment.subscription
    '581260C0-3E46-468B-A8BE-76F92FA12598', -- ScheduledPaymentLine.subscription
    'E91225AD-6C3A-4FA5-BC2E-4E6F4B90C91B', -- SubscriptionLine.subscription
    'AEE0839E-8F85-4107-B50A-3FDEFC6C5AD2' -- Term.subscription
  );

-- Target: SubscriptionLine.id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '67567672-257A-43DB-B01D-42640617E78F',
    "RelatedIntegrationObjectFieldName" = 'id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'B8869925-BBD5-4D9C-BBAA-9BFC45A59148' -- Assignment.subscriptionLine
  );

-- Target: SubscriptionPlan.id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'DE561367-D9FD-479F-9204-5B651ECCCE19',
    "RelatedIntegrationObjectFieldName" = 'id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'B1989CD1-4649-409C-906D-1D64689FF72F', -- SalesOrderLine.subscriptionPlan
    '7984E27B-87F9-4D7F-98FF-C94810709E09', -- ScheduledPaymentLine.subscriptionPlan
    'E99BFAF3-9B31-4E9C-8238-F7E132BD421E' -- Term.subscriptionPlan
  );

-- Target: Term.id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '93D4B377-FA97-43D1-B343-E1DE3071AEAF',
    "RelatedIntegrationObjectFieldName" = 'id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '22E54917-F32B-4787-BE3F-8066972C3D3F', -- Assignment.term
    'B48AE2FF-17B8-46D6-A764-7595AC3DEF51', -- Invoice.term
    'D195DB64-2989-468A-B817-305D6137E36F', -- ScheduledPayment.term
    '362C1011-E93D-4145-8240-D72D2C589D04' -- SubscriptionLine.term
  );


-- ===================== Other =====================

-- AMS/Fonteva: wire 56 declared DAG-safe scalar foreign-key relationship(s) into IntegrationObjectField.
--
-- These fields carried Configuration.ReferencedType pointing to sibling IntegrationObjects
-- in the same connector, but RelatedIntegrationObjectID was left NULL when the catalog was
-- originally authored/seeded. System audit columns (CreatedById/LastModifiedById), self-references,
-- and cycle-forming back-edges are excluded so the sync DAG stays acyclic.
--
-- DELTA migration, deliberately not a re-seed: existing installed tenants keep their seeded row
-- IDs and Flyway checksums intact. Idempotent (guarded with RelatedIntegrationObjectID IS NULL).

-- Target: AssignmentRole.id (1 field(s))
