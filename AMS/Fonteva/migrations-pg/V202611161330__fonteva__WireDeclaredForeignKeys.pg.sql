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
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AssignmentRole'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AssignmentRole'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AssignmentRole'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'fonteva'
      AND (
        (o."Name" = 'Assignment' AND __mj."IntegrationObjectField"."Name" = 'assignmentRole')
      )
  );

-- Target: BadgeType.id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BadgeType'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BadgeType'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'BadgeType'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'fonteva'
      AND (
        (o."Name" = 'Badge' AND __mj."IntegrationObjectField"."Name" = 'badgeType')
        OR (o."Name" = 'BadgeWorkflow' AND __mj."IntegrationObjectField"."Name" = 'badgeType')
      )
  );

-- Target: BusinessGroup.id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BusinessGroup'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BusinessGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'BusinessGroup'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'fonteva'
      AND (
        (o."Name" = 'CreditMemo' AND __mj."IntegrationObjectField"."Name" = 'businessGroup')
        OR (o."Name" = 'Invoice' AND __mj."IntegrationObjectField"."Name" = 'businessGroup')
        OR (o."Name" = 'PaymentGateway' AND __mj."IntegrationObjectField"."Name" = 'businessGroup')
        OR (o."Name" = 'Receipt' AND __mj."IntegrationObjectField"."Name" = 'businessGroup')
        OR (o."Name" = 'SalesOrder' AND __mj."IntegrationObjectField"."Name" = 'businessGroup')
        OR (o."Name" = 'SalesOrderLine' AND __mj."IntegrationObjectField"."Name" = 'businessGroup')
        OR (o."Name" = 'ScheduledPaymentLine' AND __mj."IntegrationObjectField"."Name" = 'businessGroup')
      )
  );

-- Target: Event.id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Event'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Event'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Event'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'fonteva'
      AND (
        (o."Name" = 'EventChatterGroup' AND __mj."IntegrationObjectField"."Name" = 'event')
        OR (o."Name" = 'SalesOrderLine' AND __mj."IntegrationObjectField"."Name" = 'event')
      )
  );

-- Target: Invoice.id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Invoice'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Invoice'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Invoice'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'fonteva'
      AND (
        (o."Name" = 'CreditMemo' AND __mj."IntegrationObjectField"."Name" = 'invoice')
        OR (o."Name" = 'CreditNote' AND __mj."IntegrationObjectField"."Name" = 'invoice')
        OR (o."Name" = 'ReceiptLine' AND __mj."IntegrationObjectField"."Name" = 'invoice')
        OR (o."Name" = 'ScheduledPayment' AND __mj."IntegrationObjectField"."Name" = 'invoice')
      )
  );

-- Target: Item.id (8 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Item'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Item'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Item'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'fonteva'
      AND (
        (o."Name" = 'Assignment' AND __mj."IntegrationObjectField"."Name" = 'item')
        OR (o."Name" = 'BadgeWorkflow' AND __mj."IntegrationObjectField"."Name" = 'item')
        OR (o."Name" = 'ReceiptLine' AND __mj."IntegrationObjectField"."Name" = 'item')
        OR (o."Name" = 'SalesOrderLine' AND __mj."IntegrationObjectField"."Name" = 'item')
        OR (o."Name" = 'ScheduledPaymentLine' AND __mj."IntegrationObjectField"."Name" = 'item')
        OR (o."Name" = 'Subscription' AND __mj."IntegrationObjectField"."Name" = 'item')
        OR (o."Name" = 'SubscriptionLine' AND __mj."IntegrationObjectField"."Name" = 'item')
        OR (o."Name" = 'Term' AND __mj."IntegrationObjectField"."Name" = 'item')
      )
  );

-- Target: PaymentGateway.id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentGateway'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentGateway'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PaymentGateway'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'fonteva'
      AND (
        (o."Name" = 'Receipt' AND __mj."IntegrationObjectField"."Name" = 'paymentGateway')
        OR (o."Name" = 'ScheduledPayment' AND __mj."IntegrationObjectField"."Name" = 'paymentGateway')
      )
  );

-- Target: PaymentMethod.id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentMethod'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentMethod'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PaymentMethod'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'fonteva'
      AND (
        (o."Name" = 'Receipt' AND __mj."IntegrationObjectField"."Name" = 'paymentMethod')
        OR (o."Name" = 'SalesOrderLine' AND __mj."IntegrationObjectField"."Name" = 'paymentMethod')
        OR (o."Name" = 'ScheduledPayment' AND __mj."IntegrationObjectField"."Name" = 'paymentMethod')
        OR (o."Name" = 'Subscription' AND __mj."IntegrationObjectField"."Name" = 'paymentMethod')
      )
  );

-- Target: PriceRule.id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PriceRule'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PriceRule'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PriceRule'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'fonteva'
      AND (
        (o."Name" = 'SalesOrderLine' AND __mj."IntegrationObjectField"."Name" = 'priceRule')
        OR (o."Name" = 'ScheduledPaymentLine' AND __mj."IntegrationObjectField"."Name" = 'priceRule')
      )
  );

-- Target: Receipt.id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Receipt'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Receipt'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Receipt'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'fonteva'
      AND (
        (o."Name" = 'ReceiptLine' AND __mj."IntegrationObjectField"."Name" = 'receipt')
      )
  );

-- Target: SalesOrder.id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SalesOrder'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SalesOrder'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SalesOrder'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'fonteva'
      AND (
        (o."Name" = 'Invoice' AND __mj."IntegrationObjectField"."Name" = 'salesOrder')
        OR (o."Name" = 'Receipt' AND __mj."IntegrationObjectField"."Name" = 'salesOrder')
        OR (o."Name" = 'SalesOrderLine' AND __mj."IntegrationObjectField"."Name" = 'salesOrder')
        OR (o."Name" = 'ScheduledPayment' AND __mj."IntegrationObjectField"."Name" = 'salesOrder')
      )
  );

-- Target: SalesOrderLine.id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SalesOrderLine'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SalesOrderLine'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SalesOrderLine'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'fonteva'
      AND (
        (o."Name" = 'Assignment' AND __mj."IntegrationObjectField"."Name" = 'salesOrderLine')
        OR (o."Name" = 'ScheduledPaymentLine' AND __mj."IntegrationObjectField"."Name" = 'salesOrderLine')
        OR (o."Name" = 'SubscriptionLine' AND __mj."IntegrationObjectField"."Name" = 'salesOrderLine')
      )
  );

-- Target: ScheduledPayment.id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ScheduledPayment'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ScheduledPayment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ScheduledPayment'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'fonteva'
      AND (
        (o."Name" = 'ScheduledPaymentLine' AND __mj."IntegrationObjectField"."Name" = 'scheduledPayment')
      )
  );

-- Target: Subscription.id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Subscription'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Subscription'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Subscription'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'fonteva'
      AND (
        (o."Name" = 'Assignment' AND __mj."IntegrationObjectField"."Name" = 'subscription')
        OR (o."Name" = 'Invoice' AND __mj."IntegrationObjectField"."Name" = 'subscription')
        OR (o."Name" = 'SalesOrderLine' AND __mj."IntegrationObjectField"."Name" = 'subscription')
        OR (o."Name" = 'ScheduledPayment' AND __mj."IntegrationObjectField"."Name" = 'subscription')
        OR (o."Name" = 'ScheduledPaymentLine' AND __mj."IntegrationObjectField"."Name" = 'subscription')
        OR (o."Name" = 'SubscriptionLine' AND __mj."IntegrationObjectField"."Name" = 'subscription')
        OR (o."Name" = 'Term' AND __mj."IntegrationObjectField"."Name" = 'subscription')
      )
  );

-- Target: SubscriptionLine.id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SubscriptionLine'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SubscriptionLine'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SubscriptionLine'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'fonteva'
      AND (
        (o."Name" = 'Assignment' AND __mj."IntegrationObjectField"."Name" = 'subscriptionLine')
      )
  );

-- Target: SubscriptionPlan.id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SubscriptionPlan'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SubscriptionPlan'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SubscriptionPlan'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'fonteva'
      AND (
        (o."Name" = 'SalesOrderLine' AND __mj."IntegrationObjectField"."Name" = 'subscriptionPlan')
        OR (o."Name" = 'ScheduledPaymentLine' AND __mj."IntegrationObjectField"."Name" = 'subscriptionPlan')
        OR (o."Name" = 'Term' AND __mj."IntegrationObjectField"."Name" = 'subscriptionPlan')
      )
  );

-- Target: Term.id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Term'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Term'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Term'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'fonteva'
      AND (
        (o."Name" = 'Assignment' AND __mj."IntegrationObjectField"."Name" = 'term')
        OR (o."Name" = 'Invoice' AND __mj."IntegrationObjectField"."Name" = 'term')
        OR (o."Name" = 'ScheduledPayment' AND __mj."IntegrationObjectField"."Name" = 'term')
        OR (o."Name" = 'SubscriptionLine' AND __mj."IntegrationObjectField"."Name" = 'term')
      )
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
-- IDs and Flyway checksums intact. Matches by (LOWER(Integration.Name), IntegrationObject.Name,
-- IntegrationObjectField.Name) and resolves target IDs within the same Integration so it applies
-- cleanly on fresh OpenApp installs, pre-v5.43 upgraded tenants with older UUIDs, and rows whose
-- RelatedIntegrationObjectID was already populated by discovery without RelatedIntegrationObjectFieldName.

-- Target: AssignmentRole.id (1 field(s))
