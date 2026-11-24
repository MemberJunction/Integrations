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
          AND t."Name" = 'AbnExperiment'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AbnExperiment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AbnExperiment'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PersonalizationPoint' AND __mj."IntegrationObjectField"."Name" = 'AbnExperimentId')
      )
  );

-- Target: Account.Id (73 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Account'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Account'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Account'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AccountContactRole' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'AccountPartner' AND __mj."IntegrationObjectField"."Name" IN ('AccountFromId', 'AccountToId'))
        OR (o."Name" = 'AccountPlan' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'AccountShare' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'ActivityHistory' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'AlternativePaymentMethod' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'Asset' AND __mj."IntegrationObjectField"."Name" IN ('AccountId', 'AssetProvidedById', 'AssetServicedById'))
        OR (o."Name" = 'BillingSchedule' AND __mj."IntegrationObjectField"."Name" = 'BillingAccountId')
        OR (o."Name" = 'BillingScheduleGroup' AND __mj."IntegrationObjectField"."Name" = 'BillingAccountId')
        OR (o."Name" = 'BuyerAccount' AND __mj."IntegrationObjectField"."Name" IN ('BuyerId', 'PayerId', 'SendToId'))
        OR (o."Name" = 'CampaignMember' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'CardPaymentMethod' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'Case' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'Contact' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'Contract' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'CreditMemo' AND __mj."IntegrationObjectField"."Name" = 'BillingAccountId')
        OR (o."Name" = 'DealIndirectPartner' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'DelegatedAccount' AND __mj."IntegrationObjectField"."Name" IN ('ParentId', 'TargetId'))
        OR (o."Name" = 'DigitalWallet' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'EmpUserProvisionProcessErr' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'Event' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'ExtlRecShrCnctAccnt' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'FulfillmentOrder' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'Invoice' AND __mj."IntegrationObjectField"."Name" = 'BillingAccountId')
        OR (o."Name" = 'Lead' AND __mj."IntegrationObjectField"."Name" = 'ConvertedAccountId')
        OR (o."Name" = 'LogoutEventStream' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'LookedUpFromActivity' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'MessagingEndUser' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'MessagingSession' AND __mj."IntegrationObjectField"."Name" = 'EndUserAccountId')
        OR (o."Name" = 'OpenActivity' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'Opportunity' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'OpportunityPartner' AND __mj."IntegrationObjectField"."Name" = 'AccountToId')
        OR (o."Name" = 'Order' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'OrderSummary' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'Partner' AND __mj."IntegrationObjectField"."Name" IN ('AccountFromId', 'AccountToId'))
        OR (o."Name" = 'Payment' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'PaymentAuthAdjustment' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'PaymentAuthorization' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'PaymentCredit' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'PaymentCreditLinePayment' AND __mj."IntegrationObjectField"."Name" = 'AssociatedAccountId')
        OR (o."Name" = 'PaymentCreditTransaction' AND __mj."IntegrationObjectField"."Name" = 'AssociatedAccountId')
        OR (o."Name" = 'PaymentInitiationSource' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'PaymentIntent' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'PaymentLineInvoice' AND __mj."IntegrationObjectField"."Name" = 'AssociatedAccountId')
        OR (o."Name" = 'PaymentLink' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'PaymentMethod' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'PaymentSchedule' AND __mj."IntegrationObjectField"."Name" = 'DefaultPaymentAccountId')
        OR (o."Name" = 'PaymentScheduleItem' AND __mj."IntegrationObjectField"."Name" = 'PaymentAccountId')
        OR (o."Name" = 'PendingOrderSummary' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'PriceProtectExecLineItem' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'ProductDetectedPriceChange' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'ProductRequest' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'ProductRequestLineItem' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'Prospect' AND __mj."IntegrationObjectField"."Name" = 'ConvertedAccountId')
        OR (o."Name" = 'PublicComplaint' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'Quote' AND __mj."IntegrationObjectField"."Name" = 'QuoteAccountId')
        OR (o."Name" = 'Refund' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'RefundLinePayment' AND __mj."IntegrationObjectField"."Name" = 'AssociatedAccountId')
        OR (o."Name" = 'ReturnOrder' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'SalesTransactionShape' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'ServiceAppointment' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'SfdcCustomerForPartner' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'Task' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'Territory2ObjectExclusion' AND __mj."IntegrationObjectField"."Name" = 'ObjectId')
        OR (o."Name" = 'WebCart' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
        OR (o."Name" = 'WorkOrder' AND __mj."IntegrationObjectField"."Name" = 'AccountId')
      )
  );

-- Target: AccountPlan.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AccountPlan'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AccountPlan'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AccountPlan'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AccountPlanObjective' AND __mj."IntegrationObjectField"."Name" = 'AccountPlanId')
      )
  );

-- Target: AccountPlanObjective.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AccountPlanObjective'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AccountPlanObjective'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AccountPlanObjective'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AccountPlanObjectiveMeasure' AND __mj."IntegrationObjectField"."Name" = 'AccountPlanObjectiveId')
      )
  );

-- Target: AccountPlanObjMeasCalcDef.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AccountPlanObjMeasCalcDef'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AccountPlanObjMeasCalcDef'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AccountPlanObjMeasCalcDef'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AccountPlanObjectiveMeasure' AND __mj."IntegrationObjectField"."Name" = 'AccountPlanObjMeasCalcDefId')
        OR (o."Name" = 'AccountPlanObjMeasCalcCond' AND __mj."IntegrationObjectField"."Name" = 'AccountPlanObjMeasCalcDefId')
      )
  );

-- Target: ActionCadence.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ActionCadence'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ActionCadence'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ActionCadence'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'Account' AND __mj."IntegrationObjectField"."Name" = 'PersonActionCadenceId')
        OR (o."Name" = 'ActionCadenceStep' AND __mj."IntegrationObjectField"."Name" IN ('ActionCadenceId', 'ChainedCadenceId'))
        OR (o."Name" = 'ActionCadenceStepTracker' AND __mj."IntegrationObjectField"."Name" = 'ActionCadenceId')
        OR (o."Name" = 'ActionCadenceTracker' AND __mj."IntegrationObjectField"."Name" = 'ActionCadenceId')
      )
  );

-- Target: ActionCadenceRule.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ActionCadenceRule'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ActionCadenceRule'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ActionCadenceRule'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ActionCadenceTracker' AND __mj."IntegrationObjectField"."Name" = 'ExitGlobalRuleId')
      )
  );

-- Target: ActionCadenceStep.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ActionCadenceStep'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ActionCadenceStep'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ActionCadenceStep'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ActionCadenceRule' AND __mj."IntegrationObjectField"."Name" = 'ActionCadenceStepId')
        OR (o."Name" = 'ActionCadenceStepTracker' AND __mj."IntegrationObjectField"."Name" = 'ActionCadenceStepId')
        OR (o."Name" = 'ActionCadenceStepVariant' AND __mj."IntegrationObjectField"."Name" = 'ActionCadenceStepId')
        OR (o."Name" = 'ActionCdncStpMonthlyMetric' AND __mj."IntegrationObjectField"."Name" = 'ActionCadenceStepId')
        OR (o."Name" = 'ListEmail' AND __mj."IntegrationObjectField"."Name" = 'ActionCadenceStepId')
      )
  );

-- Target: ActionCadenceStepTracker.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ActionCadenceStepTracker'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ActionCadenceStepTracker'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ActionCadenceStepTracker'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ListEmailIndividualRecipient' AND __mj."IntegrationObjectField"."Name" = 'ActionCadenceStepTrackerId')
        OR (o."Name" = 'ListEmailSentResult' AND __mj."IntegrationObjectField"."Name" = 'ActionCadenceStepTrackerId')
      )
  );

-- Target: ActionCadenceTracker.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ActionCadenceTracker'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ActionCadenceTracker'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ActionCadenceTracker'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ActionCadenceStepTracker' AND __mj."IntegrationObjectField"."Name" = 'ActionCadenceTrackerId')
      )
  );

-- Target: ActionLinkGroupTemplate.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ActionLinkGroupTemplate'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ActionLinkGroupTemplate'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ActionLinkGroupTemplate'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ActionLinkTemplate' AND __mj."IntegrationObjectField"."Name" = 'ActionLinkGroupTemplateId')
      )
  );

-- Target: ActivityMetric.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ActivityMetric'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ActivityMetric'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ActivityMetric'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'Account' AND __mj."IntegrationObjectField"."Name" = 'ActivityMetricId')
        OR (o."Name" = 'Contact' AND __mj."IntegrationObjectField"."Name" = 'ActivityMetricId')
        OR (o."Name" = 'Contract' AND __mj."IntegrationObjectField"."Name" = 'ActivityMetricId')
        OR (o."Name" = 'Lead' AND __mj."IntegrationObjectField"."Name" = 'ActivityMetricId')
        OR (o."Name" = 'Opportunity' AND __mj."IntegrationObjectField"."Name" = 'ActivityMetricId')
      )
  );

-- Target: AgentWork.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AgentWork'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AgentWork'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AgentWork'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AgentWorkConversationalData' AND __mj."IntegrationObjectField"."Name" = 'AgentWorkId')
      )
  );

-- Target: AIApplication.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AIApplication'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AIApplication'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AIApplication'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AIRecordInsight' AND __mj."IntegrationObjectField"."Name" = 'AiApplicationId')
      )
  );

-- Target: AiGenActionItem.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AiGenActionItem'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AiGenActionItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AiGenActionItem'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AIResearchPromptResult' AND __mj."IntegrationObjectField"."Name" = 'AiGenActionItemId')
      )
  );

-- Target: AIInsightAction.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AIInsightAction'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AIInsightAction'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AIInsightAction'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AIInsightValue' AND __mj."IntegrationObjectField"."Name" = 'AiInsightActionId')
      )
  );

-- Target: AIInsightValue.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AIInsightValue'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AIInsightValue'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AIInsightValue'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AIInsightReason' AND __mj."IntegrationObjectField"."Name" = 'AiInsightValueId')
      )
  );

-- Target: AiJobRun.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AiJobRun'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AiJobRun'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AiJobRun'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AiJobRunItem' AND __mj."IntegrationObjectField"."Name" = 'AiJobRunId')
      )
  );

-- Target: AIRecordInsight.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AIRecordInsight'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AIRecordInsight'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AIRecordInsight'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AIInsightAction' AND __mj."IntegrationObjectField"."Name" = 'AiRecordInsightId')
        OR (o."Name" = 'AIInsightFeedback' AND __mj."IntegrationObjectField"."Name" = 'AiRecordInsightId')
        OR (o."Name" = 'AIInsightValue' AND __mj."IntegrationObjectField"."Name" = 'AiRecordInsightId')
      )
  );

-- Target: AnalyticsDashboardWidget.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AnalyticsDashboardWidget'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AnalyticsDashboardWidget'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AnalyticsDashboardWidget'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AnalyticsContainerWidgetDef' AND __mj."IntegrationObjectField"."Name" = 'AnalyticsDashboardWidgetId')
      )
  );

-- Target: AnalyticsVisualization.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AnalyticsVisualization'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AnalyticsVisualization'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AnalyticsVisualization'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AnalyticsVizViewDef' AND __mj."IntegrationObjectField"."Name" = 'VisualizationId')
      )
  );

-- Target: AnalyticsWorkspace.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AnalyticsWorkspace'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AnalyticsWorkspace'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AnalyticsWorkspace'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AnalyticsDashboard' AND __mj."IntegrationObjectField"."Name" = 'AnalyticsWorkspaceId')
        OR (o."Name" = 'AnalyticsVisualization' AND __mj."IntegrationObjectField"."Name" = 'AnalyticsWorkspaceId')
      )
  );

-- Target: ApexClass.Id (16 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ApexClass'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ApexClass'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ApexClass'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ApexTestQueueItem' AND __mj."IntegrationObjectField"."Name" = 'ApexClassId')
        OR (o."Name" = 'ApexTestResult' AND __mj."IntegrationObjectField"."Name" = 'ApexClassId')
        OR (o."Name" = 'ApexTypeImplementor' AND __mj."IntegrationObjectField"."Name" IN ('ApexClassId', 'InterfaceApexClassId'))
        OR (o."Name" = 'AppointmentSchedulingPolicy' AND __mj."IntegrationObjectField"."Name" = 'ExtCalEventHandlerId')
        OR (o."Name" = 'AsyncApexJob' AND __mj."IntegrationObjectField"."Name" = 'ApexClassId')
        OR (o."Name" = 'LearningItemType' AND __mj."IntegrationObjectField"."Name" IN ('ApexEvaluationHandlerId', 'ApexSerializerDeserializerId'))
        OR (o."Name" = 'MyDomainDiscoverableLogin' AND __mj."IntegrationObjectField"."Name" = 'ApexHandlerId')
        OR (o."Name" = 'NetworkAuthApiSettings' AND __mj."IntegrationObjectField"."Name" IN ('HeadlessDiscoveryHandlerId', 'RegistrationHandlerId'))
        OR (o."Name" = 'OauthTokenExchangeHandler' AND __mj."IntegrationObjectField"."Name" = 'TokenHandlerApexId')
        OR (o."Name" = 'PaymentGatewayProvider' AND __mj."IntegrationObjectField"."Name" = 'ApexAdapterId')
        OR (o."Name" = 'SamlSsoConfig' AND __mj."IntegrationObjectField"."Name" = 'SamlJitHandlerId')
        OR (o."Name" = 'TaxEngineProvider' AND __mj."IntegrationObjectField"."Name" = 'ApexAdapterId')
        OR (o."Name" = 'TestSuiteMembership' AND __mj."IntegrationObjectField"."Name" = 'ApexClassId')
      )
  );

-- Target: ApexLog.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ApexLog'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ApexLog'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ApexLog'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ApexTestResult' AND __mj."IntegrationObjectField"."Name" = 'ApexLogId')
      )
  );

-- Target: ApexPage.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ApexPage'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ApexPage'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ApexPage'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'LiveChatButton' AND __mj."IntegrationObjectField"."Name" IN ('ChatPageId', 'PostchatPageId', 'PrechatFormPageId'))
        OR (o."Name" = 'VisualforceAccessMetrics' AND __mj."IntegrationObjectField"."Name" = 'ApexPageId')
      )
  );

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ApexTestQueueItem'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ApexTestQueueItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ApexTestQueueItem'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ApexTestResult' AND __mj."IntegrationObjectField"."Name" = 'QueueItemId')
      )
  );

-- Target: ApexTestResult.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ApexTestResult'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ApexTestResult'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ApexTestResult'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ApexTestResultLimits' AND __mj."IntegrationObjectField"."Name" = 'ApexTestResultId')
      )
  );

-- Target: ApexTestRunResult.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ApexTestRunResult'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ApexTestRunResult'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ApexTestRunResult'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ApexTestResult' AND __mj."IntegrationObjectField"."Name" = 'ApexTestRunResultId')
      )
  );

-- Target: ApexTestSuite.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ApexTestSuite'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ApexTestSuite'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ApexTestSuite'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'TestSuiteMembership' AND __mj."IntegrationObjectField"."Name" = 'ApexTestSuiteId')
      )
  );

-- Target: AppDefinition.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AppDefinition'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AppDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AppDefinition'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'UserAppInfo' AND __mj."IntegrationObjectField"."Name" = 'AppDefinitionId')
      )
  );

-- Target: AppMenuItem.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AppMenuItem'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AppMenuItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AppMenuItem'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'OauthToken' AND __mj."IntegrationObjectField"."Name" = 'AppMenuItemId')
      )
  );

-- Target: AppointmentAssignmentPolicy.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AppointmentAssignmentPolicy'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AppointmentAssignmentPolicy'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AppointmentAssignmentPolicy'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AppointmentSchedulingPolicy' AND __mj."IntegrationObjectField"."Name" = 'AppointmentAssignmentPolicyId')
      )
  );

-- Target: AppointmentScheduleAggr.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AppointmentScheduleAggr'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AppointmentScheduleAggr'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AppointmentScheduleAggr'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AppointmentScheduleLog' AND __mj."IntegrationObjectField"."Name" = 'AppointmentScheduleAggrId')
      )
  );

-- Target: ApprovalWorkItem.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ApprovalWorkItem'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ApprovalWorkItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ApprovalWorkItem'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ApprovalSubmissionDetail' AND __mj."IntegrationObjectField"."Name" = 'ApprovalWorkItemId')
      )
  );

-- Target: ApptBundleAggrPolicy.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ApptBundleAggrPolicy'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ApptBundleAggrPolicy'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ApptBundleAggrPolicy'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ApptBundleAggrDurDnscale' AND __mj."IntegrationObjectField"."Name" = 'BundleAggregationPolicyId')
      )
  );

-- Target: ApptBundlePolicy.Id (6 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ApptBundlePolicy'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ApptBundlePolicy'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ApptBundlePolicy'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ApptBundleAggrPolicy' AND __mj."IntegrationObjectField"."Name" = 'BundlePolicyId')
        OR (o."Name" = 'ApptBundlePolicySvcTerr' AND __mj."IntegrationObjectField"."Name" = 'BundlePolicyId')
        OR (o."Name" = 'ApptBundlePropagatePolicy' AND __mj."IntegrationObjectField"."Name" = 'BundlePolicyId')
        OR (o."Name" = 'ApptBundleRestrictPolicy' AND __mj."IntegrationObjectField"."Name" = 'BundlePolicyId')
        OR (o."Name" = 'ApptBundleSortPolicy' AND __mj."IntegrationObjectField"."Name" = 'BundlePolicyId')
        OR (o."Name" = 'ServiceAppointment' AND __mj."IntegrationObjectField"."Name" = 'BundlePolicyId')
      )
  );

-- Target: Asset.Id (20 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Asset'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Asset'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Asset'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AssetAction' AND __mj."IntegrationObjectField"."Name" = 'AssetId')
        OR (o."Name" = 'AssetAttribute' AND __mj."IntegrationObjectField"."Name" = 'AssetId')
        OR (o."Name" = 'AssetContractRelationship' AND __mj."IntegrationObjectField"."Name" = 'AssetId')
        OR (o."Name" = 'AssetRateCardEntry' AND __mj."IntegrationObjectField"."Name" = 'BindingObjectId')
        OR (o."Name" = 'AssetRelationship' AND __mj."IntegrationObjectField"."Name" IN ('AssetId', 'RelatedAssetId'))
        OR (o."Name" = 'AssetShare' AND __mj."IntegrationObjectField"."Name" = 'AssetId')
        OR (o."Name" = 'AssetStatePeriod' AND __mj."IntegrationObjectField"."Name" = 'AssetId')
        OR (o."Name" = 'BillingScheduleGroup' AND __mj."IntegrationObjectField"."Name" = 'ReferenceEntityId')
        OR (o."Name" = 'ChangeRequestRelatedItem' AND __mj."IntegrationObjectField"."Name" = 'AssetId')
        OR (o."Name" = 'IncidentRelatedItem' AND __mj."IntegrationObjectField"."Name" = 'AssetId')
        OR (o."Name" = 'OrderAction' AND __mj."IntegrationObjectField"."Name" = 'SourceAssetId')
        OR (o."Name" = 'OrderItemSummary' AND __mj."IntegrationObjectField"."Name" = 'AssetId')
        OR (o."Name" = 'ProblemRelatedItem' AND __mj."IntegrationObjectField"."Name" = 'AssetId')
        OR (o."Name" = 'QuoteAction' AND __mj."IntegrationObjectField"."Name" = 'SourceAssetId')
        OR (o."Name" = 'QuoteLineWorkSource' AND __mj."IntegrationObjectField"."Name" = 'AssetId')
        OR (o."Name" = 'RecordsetFltrCritMonitor' AND __mj."IntegrationObjectField"."Name" = 'AssetId')
        OR (o."Name" = 'ReturnOrderLineItem' AND __mj."IntegrationObjectField"."Name" = 'AssetId')
        OR (o."Name" = 'WorkOrder' AND __mj."IntegrationObjectField"."Name" = 'AssetId')
        OR (o."Name" = 'WorkOrderLineItem' AND __mj."IntegrationObjectField"."Name" = 'AssetId')
      )
  );

-- Target: AssetAction.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AssetAction'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AssetAction'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AssetAction'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AssetActionSource' AND __mj."IntegrationObjectField"."Name" = 'AssetActionId')
      )
  );

-- Target: AsyncApexJob.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AsyncApexJob'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AsyncApexJob'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AsyncApexJob'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ApexTestResult' AND __mj."IntegrationObjectField"."Name" = 'AsyncApexJobId')
        OR (o."Name" = 'ApexTestRunResult' AND __mj."IntegrationObjectField"."Name" = 'AsyncApexJobId')
        OR (o."Name" = 'FlexQueueItem' AND __mj."IntegrationObjectField"."Name" = 'AsyncApexJobId')
      )
  );

-- Target: AsyncOperationLog.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AsyncOperationLog'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AsyncOperationLog'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AsyncOperationLog'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'OSAsyncChgCompletedEvent' AND __mj."IntegrationObjectField"."Name" = 'AsyncOperationLogId')
      )
  );

-- Target: AsyncOperationTracker.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AsyncOperationTracker'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AsyncOperationTracker'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AsyncOperationTracker'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AsyncOpSyndicationFeedFile' AND __mj."IntegrationObjectField"."Name" = 'AsyncOperationTrackerId')
        OR (o."Name" = 'ProcessException' AND __mj."IntegrationObjectField"."Name" = 'GroupById')
        OR (o."Name" = 'RevenueTransactionErrorLog' AND __mj."IntegrationObjectField"."Name" = 'AsyncOperationTrackerId')
      )
  );

-- Target: AttributeDefinition.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AttributeDefinition'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AttributeDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AttributeDefinition'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AssetAttribute' AND __mj."IntegrationObjectField"."Name" = 'AttributeDefinitionId')
        OR (o."Name" = 'AssetStatePeriodAttribute' AND __mj."IntegrationObjectField"."Name" = 'AttributeDefinitionId')
        OR (o."Name" = 'CartItemAttribute' AND __mj."IntegrationObjectField"."Name" = 'AttributeDefinitionId')
      )
  );

-- Target: AttributePicklist.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AttributePicklist'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AttributePicklist'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AttributePicklist'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AttributeDefinition' AND __mj."IntegrationObjectField"."Name" = 'PicklistId')
        OR (o."Name" = 'AttributePicklistValue' AND __mj."IntegrationObjectField"."Name" = 'PicklistId')
      )
  );

-- Target: AttributePicklistValue.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AttributePicklistValue'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AttributePicklistValue'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AttributePicklistValue'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AssetAttribute' AND __mj."IntegrationObjectField"."Name" = 'AttributePicklistValueId')
        OR (o."Name" = 'AssetStatePeriodAttribute' AND __mj."IntegrationObjectField"."Name" = 'AttributePicklistValueId')
        OR (o."Name" = 'CartItemAttribute' AND __mj."IntegrationObjectField"."Name" = 'AttributePicklistValueId')
      )
  );

-- Target: AuraDefinitionBundle.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AuraDefinitionBundle'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AuraDefinitionBundle'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AuraDefinitionBundle'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AuraDefinition' AND __mj."IntegrationObjectField"."Name" = 'AuraDefinitionBundleId')
      )
  );

-- Target: AuthConfig.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AuthConfig'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AuthConfig'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AuthConfig'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AuthConfigProviders' AND __mj."IntegrationObjectField"."Name" = 'AuthConfigId')
      )
  );

-- Target: AuthorizationForm.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AuthorizationForm'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AuthorizationForm'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AuthorizationForm'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AuthorizationFormDataUse' AND __mj."IntegrationObjectField"."Name" = 'AuthorizationFormId')
        OR (o."Name" = 'AuthorizationFormText' AND __mj."IntegrationObjectField"."Name" = 'AuthorizationFormId')
      )
  );

-- Target: AuthorizationFormText.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AuthorizationFormText'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AuthorizationFormText'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AuthorizationFormText'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AuthorizationFormConsent' AND __mj."IntegrationObjectField"."Name" = 'AuthorizationFormTextId')
      )
  );

-- Target: AuthProvider.Id (6 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AuthProvider'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AuthProvider'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AuthProvider'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AuthProvParamFwdAllowlist' AND __mj."IntegrationObjectField"."Name" = 'AuthProviderId')
        OR (o."Name" = 'ExternalClientApplication' AND __mj."IntegrationObjectField"."Name" = 'AuthProviderId')
        OR (o."Name" = 'ExternalDataSource' AND __mj."IntegrationObjectField"."Name" = 'AuthProviderId')
        OR (o."Name" = 'ExternalDataUserAuth' AND __mj."IntegrationObjectField"."Name" = 'AuthProviderId')
        OR (o."Name" = 'NamedCredential' AND __mj."IntegrationObjectField"."Name" = 'AuthProviderId')
        OR (o."Name" = 'ThirdPartyAccountLink' AND __mj."IntegrationObjectField"."Name" = 'SsoProviderId')
      )
  );

-- Target: AuthSession.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AuthSession'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AuthSession'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AuthSession'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'SessionPermSetActivation' AND __mj."IntegrationObjectField"."Name" = 'AuthSessionId')
      )
  );

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AutomatedAction'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'AutomatedAction'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'AutomatedAction'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AutomatedActionCondition' AND __mj."IntegrationObjectField"."Name" = 'AutomatedActionId')
        OR (o."Name" = 'AutomatedActionParameter' AND __mj."IntegrationObjectField"."Name" = 'AutomatedActionId')
        OR (o."Name" = 'AutomatedActionReminder' AND __mj."IntegrationObjectField"."Name" = 'AutomatedActionId')
      )
  );

-- Target: BillingBatchScheduler.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BillingBatchScheduler'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BillingBatchScheduler'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'BillingBatchScheduler'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'InvoiceBatchRun' AND __mj."IntegrationObjectField"."Name" = 'BillingBatchSchedulerId')
      )
  );

-- Target: BillingPolicy.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BillingPolicy'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BillingPolicy'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'BillingPolicy'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'BillingTreatment' AND __mj."IntegrationObjectField"."Name" = 'BillingPolicyId')
        OR (o."Name" = 'Product2' AND __mj."IntegrationObjectField"."Name" = 'BillingPolicyId')
      )
  );

-- Target: BillingSchedule.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BillingSchedule'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BillingSchedule'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'BillingSchedule'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'BillingPeriodItem' AND __mj."IntegrationObjectField"."Name" = 'BillingScheduleId')
        OR (o."Name" = 'InvoiceLine' AND __mj."IntegrationObjectField"."Name" = 'BillingScheduleId')
      )
  );

-- Target: BillingScheduleGroup.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BillingScheduleGroup'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BillingScheduleGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'BillingScheduleGroup'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'BillingSchedule' AND __mj."IntegrationObjectField"."Name" = 'BillingScheduleGroupId')
        OR (o."Name" = 'InvoiceLine' AND __mj."IntegrationObjectField"."Name" = 'BillingScheduleGroupId')
        OR (o."Name" = 'RevenueTransactionErrorLog' AND __mj."IntegrationObjectField"."Name" = 'BillingScheduleGroupId')
      )
  );

-- Target: BillingTreatment.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BillingTreatment'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BillingTreatment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'BillingTreatment'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'BillingTreatmentItem' AND __mj."IntegrationObjectField"."Name" = 'BillingTreatmentId')
      )
  );

-- Target: BillingTreatmentItem.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BillingTreatmentItem'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BillingTreatmentItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'BillingTreatmentItem'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'BillingSchedule' AND __mj."IntegrationObjectField"."Name" = 'BillingTreatmentItemId')
      )
  );

-- Target: BotDefinition.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BotDefinition'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BotDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'BotDefinition'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AgentWork' AND __mj."IntegrationObjectField"."Name" = 'BotId')
        OR (o."Name" = 'AiGenActionItem' AND __mj."IntegrationObjectField"."Name" = 'BotDefinitionId')
        OR (o."Name" = 'BotVersion' AND __mj."IntegrationObjectField"."Name" = 'BotDefinitionId')
        OR (o."Name" = 'PendingServiceRouting' AND __mj."IntegrationObjectField"."Name" = 'BotId')
      )
  );

-- Target: BotVersion.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BotVersion'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BotVersion'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'BotVersion'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AiGenActionItem' AND __mj."IntegrationObjectField"."Name" = 'BotVersionId')
      )
  );

-- Target: BrandingSet.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BrandingSet'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BrandingSet'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'BrandingSet'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'LightningExperienceTheme' AND __mj."IntegrationObjectField"."Name" = 'DefaultBrandingSetId')
      )
  );

-- Target: BriefcaseDefinition.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BriefcaseDefinition'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BriefcaseDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'BriefcaseDefinition'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'BriefcaseRule' AND __mj."IntegrationObjectField"."Name" = 'BriefcaseId')
      )
  );

-- Target: BroadcastCommunication.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BroadcastCommunication'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BroadcastCommunication'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'BroadcastCommunication'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'BroadcastCommAudience' AND __mj."IntegrationObjectField"."Name" = 'BroadcastCommunicationId')
      )
  );

-- Target: BroadcastTopic.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BroadcastTopic'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BroadcastTopic'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'BroadcastTopic'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'BroadcastTopicGroup' AND __mj."IntegrationObjectField"."Name" = 'BroadcastTopicId')
        OR (o."Name" = 'BroadcastTopicNetwork' AND __mj."IntegrationObjectField"."Name" = 'BroadcastTopicId')
      )
  );

-- Target: BusinessAlert.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BusinessAlert'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BusinessAlert'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'BusinessAlert'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'BusinessAlertStatus' AND __mj."IntegrationObjectField"."Name" = 'BusinessAlertId')
      )
  );

-- Target: BusinessBrand.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BusinessBrand'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BusinessBrand'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'BusinessBrand'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CommSubscriptionConsent' AND __mj."IntegrationObjectField"."Name" = 'BusinessBrandId')
        OR (o."Name" = 'ContactPointConsent' AND __mj."IntegrationObjectField"."Name" = 'BusinessBrandId')
        OR (o."Name" = 'ContactPointTypeConsent' AND __mj."IntegrationObjectField"."Name" = 'BusinessBrandId')
      )
  );

-- Target: BusinessHours.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BusinessHours'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BusinessHours'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'BusinessHours'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'DeliveryEstimationSetup' AND __mj."IntegrationObjectField"."Name" = 'DefaultBusinessHoursId')
        OR (o."Name" = 'MessagingChannel' AND __mj."IntegrationObjectField"."Name" = 'BusinessHoursId')
        OR (o."Name" = 'ServiceRequest' AND __mj."IntegrationObjectField"."Name" = 'BusinessHoursId')
        OR (o."Name" = 'WorkOrder' AND __mj."IntegrationObjectField"."Name" = 'BusinessHoursId')
      )
  );

-- Target: BuyerCriteria.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BuyerCriteria'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BuyerCriteria'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'BuyerCriteria'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'BuyerGroupBuyerCriteria' AND __mj."IntegrationObjectField"."Name" = 'BuyerCriteriaId')
      )
  );

-- Target: BuyerGroup.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BuyerGroup'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'BuyerGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'BuyerGroup'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'BuyerGroupBuyerCriteria' AND __mj."IntegrationObjectField"."Name" = 'BuyerGroupId')
        OR (o."Name" = 'BuyerGroupMember' AND __mj."IntegrationObjectField"."Name" = 'BuyerGroupId')
        OR (o."Name" = 'BuyerGroupRelatedObject' AND __mj."IntegrationObjectField"."Name" = 'BuyerGroupId')
        OR (o."Name" = 'PromotionSegmentBuyerGroup' AND __mj."IntegrationObjectField"."Name" = 'BuyerGroupId')
        OR (o."Name" = 'WebstoreBuyerGroup' AND __mj."IntegrationObjectField"."Name" = 'BuyerGroupId')
      )
  );

-- Target: CalculationMatrix.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CalculationMatrix'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CalculationMatrix'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CalculationMatrix'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CalculationMatrixColumn' AND __mj."IntegrationObjectField"."Name" = 'CalculationMatrixId')
        OR (o."Name" = 'CalculationMatrixVersion' AND __mj."IntegrationObjectField"."Name" = 'CalculationMatrixId')
        OR (o."Name" = 'CalculationProcedureStep' AND __mj."IntegrationObjectField"."Name" = 'CalculationMatrixId')
      )
  );

-- Target: CalculationMatrixVersion.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CalculationMatrixVersion'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CalculationMatrixVersion'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CalculationMatrixVersion'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CalculationMatrixRow' AND __mj."IntegrationObjectField"."Name" = 'CalculationMatrixVersionId')
      )
  );

-- Target: CalculationProcedure.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CalculationProcedure'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CalculationProcedure'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CalculationProcedure'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CalculationProcedureStep' AND __mj."IntegrationObjectField"."Name" = 'ReferenceProcedureId')
        OR (o."Name" = 'CalculationProcedureVersion' AND __mj."IntegrationObjectField"."Name" = 'CalculationProcedureId')
      )
  );

-- Target: CalculationProcedureStep.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CalculationProcedureStep'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CalculationProcedureStep'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CalculationProcedureStep'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CalcProcStepRelationship' AND __mj."IntegrationObjectField"."Name" IN ('CalcProcStepId', 'ParentCalcProcStepId'))
      )
  );

-- Target: CalculationProcedureVersion.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CalculationProcedureVersion'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CalculationProcedureVersion'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CalculationProcedureVersion'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CalcProcStepRelationship' AND __mj."IntegrationObjectField"."Name" = 'CalcProcVersionId')
        OR (o."Name" = 'CalculationProcedureStep' AND __mj."IntegrationObjectField"."Name" = 'CalculationProcedureVersionId')
        OR (o."Name" = 'CalculationProcedureVariable' AND __mj."IntegrationObjectField"."Name" = 'CalculationProcedureVersionId')
      )
  );

-- Target: CallCenter.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CallCenter'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CallCenter'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CallCenter'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CallCenterRoutingMap' AND __mj."IntegrationObjectField"."Name" = 'CallCenterId')
        OR (o."Name" = 'CallCtrAgentFavTrfrDest' AND __mj."IntegrationObjectField"."Name" = 'CallCenterId')
        OR (o."Name" = 'VendorCallCenterStatusMap' AND __mj."IntegrationObjectField"."Name" = 'CallCenterId')
      )
  );

-- Target: CallCoachingMediaProvider.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CallCoachingMediaProvider'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CallCoachingMediaProvider'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CallCoachingMediaProvider'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'VoiceCall' AND __mj."IntegrationObjectField"."Name" = 'MediaProviderId')
      )
  );

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CallCtrAgentFavTrfrDest'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CallCtrAgentFavTrfrDest'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CallCtrAgentFavTrfrDest'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CallCtrAgentFavTrfrDestShare' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
      )
  );

-- Target: Campaign.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Campaign'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Campaign'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Campaign'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CampaignMember' AND __mj."IntegrationObjectField"."Name" = 'CampaignId')
        OR (o."Name" = 'CampaignShare' AND __mj."IntegrationObjectField"."Name" = 'CampaignId')
        OR (o."Name" = 'FlowRecord' AND __mj."IntegrationObjectField"."Name" = 'AssociatedRecordId')
        OR (o."Name" = 'ListEmail' AND __mj."IntegrationObjectField"."Name" = 'CampaignId')
        OR (o."Name" = 'Opportunity' AND __mj."IntegrationObjectField"."Name" = 'CampaignId')
      )
  );

-- Target: CartDeliveryGroup.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CartDeliveryGroup'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CartDeliveryGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CartDeliveryGroup'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CartItem' AND __mj."IntegrationObjectField"."Name" = 'CartDeliveryGroupId')
      )
  );

-- Target: CartDeliveryGroupMethod.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CartDeliveryGroupMethod'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CartDeliveryGroupMethod'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CartDeliveryGroupMethod'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CartDeliveryGroup' AND __mj."IntegrationObjectField"."Name" = 'SelectedDeliveryMethodId')
        OR (o."Name" = 'CartDeliveryGroupMethodAdj' AND __mj."IntegrationObjectField"."Name" = 'CartDeliveryGroupMethodId')
      )
  );

-- Target: CartItem.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CartItem'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CartItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CartItem'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CartItemPriceAdjustment' AND __mj."IntegrationObjectField"."Name" = 'CartItemId')
        OR (o."Name" = 'InventoryItemReservation' AND __mj."IntegrationObjectField"."Name" = 'ItemReservationSourceId')
      )
  );

-- Target: CartItemPriceAdjustment.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CartItemPriceAdjustment'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CartItemPriceAdjustment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CartItemPriceAdjustment'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CartTax' AND __mj."IntegrationObjectField"."Name" = 'CartItemPriceAdjustmentId')
      )
  );

-- Target: Case.Id (17 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Case'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Case'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Case'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CaseContactRole' AND __mj."IntegrationObjectField"."Name" = 'CasesId')
        OR (o."Name" = 'CaseHistory' AND __mj."IntegrationObjectField"."Name" = 'CaseId')
        OR (o."Name" = 'CaseHistory2' AND __mj."IntegrationObjectField"."Name" = 'CaseId')
        OR (o."Name" = 'CaseParticipant' AND __mj."IntegrationObjectField"."Name" = 'CaseId')
        OR (o."Name" = 'CaseRelatedIssue' AND __mj."IntegrationObjectField"."Name" = 'CaseId')
        OR (o."Name" = 'CaseShare' AND __mj."IntegrationObjectField"."Name" = 'CaseId')
        OR (o."Name" = 'CaseSolution' AND __mj."IntegrationObjectField"."Name" = 'CaseId')
        OR (o."Name" = 'CaseTeamMember' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
        OR (o."Name" = 'CaseTeamTemplateRecord' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
        OR (o."Name" = 'EmailMessage' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
        OR (o."Name" = 'ProcessException' AND __mj."IntegrationObjectField"."Name" = 'CaseId')
        OR (o."Name" = 'ProductRequest' AND __mj."IntegrationObjectField"."Name" = 'CaseId')
        OR (o."Name" = 'ProductRequestLineItem' AND __mj."IntegrationObjectField"."Name" = 'CaseId')
        OR (o."Name" = 'PublicComplaint' AND __mj."IntegrationObjectField"."Name" = 'ComplaintCaseId')
        OR (o."Name" = 'ReturnOrder' AND __mj."IntegrationObjectField"."Name" = 'CaseId')
        OR (o."Name" = 'SocialPost' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
        OR (o."Name" = 'WorkOrder' AND __mj."IntegrationObjectField"."Name" = 'CaseId')
      )
  );

-- Target: CaseTeamRole.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CaseTeamRole'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CaseTeamRole'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CaseTeamRole'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CaseTeamMember' AND __mj."IntegrationObjectField"."Name" = 'TeamRoleId')
      )
  );

-- Target: CaseTeamTemplate.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CaseTeamTemplate'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CaseTeamTemplate'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CaseTeamTemplate'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CaseTeamMember' AND __mj."IntegrationObjectField"."Name" = 'TeamTemplateId')
        OR (o."Name" = 'CaseTeamTemplateRecord' AND __mj."IntegrationObjectField"."Name" = 'TeamTemplateId')
      )
  );

-- Target: CaseTeamTemplateMember.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CaseTeamTemplateMember'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CaseTeamTemplateMember'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CaseTeamTemplateMember'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CaseTeamMember' AND __mj."IntegrationObjectField"."Name" = 'TeamTemplateMemberId')
      )
  );

-- Target: ChangeRequest.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ChangeRequest'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ChangeRequest'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ChangeRequest'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ChangeRequestRelatedIssue' AND __mj."IntegrationObjectField"."Name" = 'ChangeRequestId')
        OR (o."Name" = 'ChangeRequestRelatedItem' AND __mj."IntegrationObjectField"."Name" = 'ChangeRequestId')
      )
  );

-- Target: ChatterExtension.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ChatterExtension'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ChatterExtension'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ChatterExtension'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ChatterExtensionConfig' AND __mj."IntegrationObjectField"."Name" = 'ChatterExtensionId')
      )
  );

-- Target: CollaborationGroup.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CollaborationGroup'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CollaborationGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CollaborationGroup'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'Announcement' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
        OR (o."Name" = 'CollaborationGroupMember' AND __mj."IntegrationObjectField"."Name" = 'CollaborationGroupId')
        OR (o."Name" = 'CollaborationGroupMemberRequest' AND __mj."IntegrationObjectField"."Name" = 'CollaborationGroupId')
        OR (o."Name" = 'CollaborationGroupRecord' AND __mj."IntegrationObjectField"."Name" = 'CollaborationGroupId')
        OR (o."Name" = 'LightningOnboardingConfig' AND __mj."IntegrationObjectField"."Name" = 'CollaborationGroupId')
      )
  );

-- Target: CollaborationRoom.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CollaborationRoom'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CollaborationRoom'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CollaborationRoom'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'Swarm' AND __mj."IntegrationObjectField"."Name" = 'CollaborationRoomId')
      )
  );

-- Target: CommissionSchedule.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CommissionSchedule'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CommissionSchedule'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CommissionSchedule'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CommissionScheduleAssignment' AND __mj."IntegrationObjectField"."Name" = 'CommissionScheduleId')
        OR (o."Name" = 'ProducerCommission' AND __mj."IntegrationObjectField"."Name" = 'CommissionScheduleId')
      )
  );

-- Target: CommSubscription.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CommSubscription'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CommSubscription'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CommSubscription'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CommSubscriptionChannelType' AND __mj."IntegrationObjectField"."Name" = 'CommunicationSubscriptionId')
      )
  );

-- Target: CommSubscriptionChannelType.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CommSubscriptionChannelType'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CommSubscriptionChannelType'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CommSubscriptionChannelType'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CommSubscriptionConsent' AND __mj."IntegrationObjectField"."Name" = 'CommSubscriptionChannelTypeId')
      )
  );

-- Target: CommSubscriptionConsent.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CommSubscriptionConsent'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CommSubscriptionConsent'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CommSubscriptionConsent'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CommSubscriptionTiming' AND __mj."IntegrationObjectField"."Name" = 'CommSubscriptionConsentId')
      )
  );

-- Target: ConnectedApplication.Id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ConnectedApplication'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ConnectedApplication'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ConnectedApplication'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'OauthTokenExchHandlerApp' AND __mj."IntegrationObjectField"."Name" = 'ConnectedApplicationId')
        OR (o."Name" = 'UserAppMenuCustomization' AND __mj."IntegrationObjectField"."Name" = 'ApplicationId')
        OR (o."Name" = 'UserProvAccount' AND __mj."IntegrationObjectField"."Name" = 'ConnectedAppId')
        OR (o."Name" = 'UserProvAccountStaging' AND __mj."IntegrationObjectField"."Name" = 'ConnectedAppId')
        OR (o."Name" = 'UserProvisioningConfig' AND __mj."IntegrationObjectField"."Name" = 'ConnectedAppId')
        OR (o."Name" = 'UserProvisioningRequest' AND __mj."IntegrationObjectField"."Name" = 'ConnectedAppId')
        OR (o."Name" = 'VerificationHistory' AND __mj."IntegrationObjectField"."Name" = 'ResourceId')
      )
  );

-- Target: Contact.Id (27 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Contact'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Contact'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Contact'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AccountContactRole' AND __mj."IntegrationObjectField"."Name" = 'ContactId')
        OR (o."Name" = 'AccountPlanObjective' AND __mj."IntegrationObjectField"."Name" = 'ExternalStakeholderId')
        OR (o."Name" = 'Asset' AND __mj."IntegrationObjectField"."Name" = 'ContactId')
        OR (o."Name" = 'BillingScheduleGroup' AND __mj."IntegrationObjectField"."Name" = 'BillToContactId')
        OR (o."Name" = 'CampaignMember' AND __mj."IntegrationObjectField"."Name" = 'ContactId')
        OR (o."Name" = 'Case' AND __mj."IntegrationObjectField"."Name" = 'ContactId')
        OR (o."Name" = 'CaseContactRole' AND __mj."IntegrationObjectField"."Name" = 'ContactId')
        OR (o."Name" = 'ContactDailyMetric' AND __mj."IntegrationObjectField"."Name" = 'ContactId')
        OR (o."Name" = 'ContactMonthlyMetric' AND __mj."IntegrationObjectField"."Name" = 'ContactId')
        OR (o."Name" = 'ContactShare' AND __mj."IntegrationObjectField"."Name" = 'ContactId')
        OR (o."Name" = 'Contract' AND __mj."IntegrationObjectField"."Name" = 'CustomerSignedId')
        OR (o."Name" = 'ContractContactRole' AND __mj."IntegrationObjectField"."Name" = 'ContactId')
        OR (o."Name" = 'CreditMemo' AND __mj."IntegrationObjectField"."Name" = 'BillToContactId')
        OR (o."Name" = 'FulfillmentOrder' AND __mj."IntegrationObjectField"."Name" = 'BillToContactId')
        OR (o."Name" = 'Invoice' AND __mj."IntegrationObjectField"."Name" = 'BillToContactId')
        OR (o."Name" = 'Lead' AND __mj."IntegrationObjectField"."Name" = 'ConvertedContactId')
        OR (o."Name" = 'MessagingEndUser' AND __mj."IntegrationObjectField"."Name" = 'ContactId')
        OR (o."Name" = 'MessagingSession' AND __mj."IntegrationObjectField"."Name" = 'EndUserContactId')
        OR (o."Name" = 'OpportunityContactRole' AND __mj."IntegrationObjectField"."Name" = 'ContactId')
        OR (o."Name" = 'Order' AND __mj."IntegrationObjectField"."Name" = 'CustomerAuthorizedById')
        OR (o."Name" = 'OrderSummary' AND __mj."IntegrationObjectField"."Name" = 'BillToContactId')
        OR (o."Name" = 'PaymentInitiationSource' AND __mj."IntegrationObjectField"."Name" = 'ContactId')
        OR (o."Name" = 'PendingOrderSummary' AND __mj."IntegrationObjectField"."Name" = 'BillToContactId')
        OR (o."Name" = 'Prospect' AND __mj."IntegrationObjectField"."Name" = 'ConvertedContactId')
        OR (o."Name" = 'ReturnOrder' AND __mj."IntegrationObjectField"."Name" = 'ContactId')
        OR (o."Name" = 'ServiceAppointment' AND __mj."IntegrationObjectField"."Name" = 'ContactId')
        OR (o."Name" = 'WorkOrder' AND __mj."IntegrationObjectField"."Name" = 'ContactId')
      )
  );

-- Target: ContactPointPhone.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ContactPointPhone'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ContactPointPhone'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ContactPointPhone'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ContactPointAddress' AND __mj."IntegrationObjectField"."Name" = 'ContactPointPhoneId')
      )
  );

-- Target: ContactRequest.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ContactRequest'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ContactRequest'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ContactRequest'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ContactRequestShare' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
      )
  );

-- Target: ContentAsset.Id (8 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ContentAsset'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ContentAsset'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ContentAsset'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AnalyticsContainerWidgetDef' AND __mj."IntegrationObjectField"."Name" = 'BackgroundSourceId')
        OR (o."Name" = 'ChatterExtension' AND __mj."IntegrationObjectField"."Name" = 'IconId')
        OR (o."Name" = 'ContentWorkspace' AND __mj."IntegrationObjectField"."Name" = 'WorkspaceImageId')
        OR (o."Name" = 'Location' AND __mj."IntegrationObjectField"."Name" = 'LogoId')
        OR (o."Name" = 'PromptVersion' AND __mj."IntegrationObjectField"."Name" = 'ImageId')
        OR (o."Name" = 'Recommendation' AND __mj."IntegrationObjectField"."Name" = 'ImageId')
        OR (o."Name" = 'SvcCatalogCategory' AND __mj."IntegrationObjectField"."Name" = 'ImageId')
        OR (o."Name" = 'SvcCatalogItemDef' AND __mj."IntegrationObjectField"."Name" = 'ImageId')
      )
  );

-- Target: ContentBody.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ContentBody'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ContentBody'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ContentBody'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ContentNote' AND __mj."IntegrationObjectField"."Name" = 'LatestContentId')
        OR (o."Name" = 'ContentVersion' AND __mj."IntegrationObjectField"."Name" = 'ContentBodyId')
      )
  );

-- Target: ContentDistribution.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ContentDistribution'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ContentDistribution'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ContentDistribution'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ContentDistributionView' AND __mj."IntegrationObjectField"."Name" = 'DistributionId')
      )
  );

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ContentDocument'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ContentDocument'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ContentDocument'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AttachedContentDocument' AND __mj."IntegrationObjectField"."Name" = 'ContentDocumentId')
        OR (o."Name" = 'AuthorizationFormText' AND __mj."IntegrationObjectField"."Name" = 'ContentDocumentId')
        OR (o."Name" = 'ContentAsset' AND __mj."IntegrationObjectField"."Name" = 'ContentDocumentId')
        OR (o."Name" = 'ContentDocumentHistory' AND __mj."IntegrationObjectField"."Name" = 'ContentDocumentId')
        OR (o."Name" = 'ContentDocumentLink' AND __mj."IntegrationObjectField"."Name" = 'ContentDocumentId')
        OR (o."Name" = 'ContentDocumentSubscription' AND __mj."IntegrationObjectField"."Name" = 'ContentDocumentId')
        OR (o."Name" = 'ContentFolderMember' AND __mj."IntegrationObjectField"."Name" = 'ChildRecordId')
        OR (o."Name" = 'ContentVersion' AND __mj."IntegrationObjectField"."Name" = 'ContentDocumentId')
        OR (o."Name" = 'ContentVersionComment' AND __mj."IntegrationObjectField"."Name" = 'ContentDocumentId')
        OR (o."Name" = 'ContentWorkspaceDoc' AND __mj."IntegrationObjectField"."Name" = 'ContentDocumentId')
        OR (o."Name" = 'FolderedContentDocument' AND __mj."IntegrationObjectField"."Name" = 'ContentDocumentId')
        OR (o."Name" = 'Image' AND __mj."IntegrationObjectField"."Name" = 'ContentDocumentId')
        OR (o."Name" = 'InvoiceDocument' AND __mj."IntegrationObjectField"."Name" = 'ContentDocumentId')
        OR (o."Name" = 'OutgoingEmail' AND __mj."IntegrationObjectField"."Name" = 'ContentDocumentId')
        OR (o."Name" = 'OutgoingEmailRelation' AND __mj."IntegrationObjectField"."Name" = 'ContentDocumentId')
        OR (o."Name" = 'OwnedContentDocument' AND __mj."IntegrationObjectField"."Name" = 'ContentDocumentId')
        OR (o."Name" = 'VoiceCallRecording' AND __mj."IntegrationObjectField"."Name" = 'MediaContentId')
      )
  );

-- Target: ContentFolder.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ContentFolder'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ContentFolder'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ContentFolder'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ContentFolderItem' AND __mj."IntegrationObjectField"."Name" = 'ParentContentFolderId')
        OR (o."Name" = 'ContentFolderLink' AND __mj."IntegrationObjectField"."Name" = 'ContentFolderId')
        OR (o."Name" = 'ContentFolderMember' AND __mj."IntegrationObjectField"."Name" = 'ParentContentFolderId')
        OR (o."Name" = 'FolderedContentDocument' AND __mj."IntegrationObjectField"."Name" = 'ParentContentFolderId')
      )
  );

-- Target: ContentVersion.Id (6 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ContentVersion'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ContentVersion'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ContentVersion'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AuthorizationFormConsent' AND __mj."IntegrationObjectField"."Name" = 'DocumentVersionId')
        OR (o."Name" = 'ContentDistribution' AND __mj."IntegrationObjectField"."Name" = 'ContentVersionId')
        OR (o."Name" = 'ContentVersionComment' AND __mj."IntegrationObjectField"."Name" = 'ContentVersionId')
        OR (o."Name" = 'ContentVersionHistory' AND __mj."IntegrationObjectField"."Name" = 'ContentVersionId')
        OR (o."Name" = 'ContentVersionRating' AND __mj."IntegrationObjectField"."Name" = 'ContentVersionId')
        OR (o."Name" = 'PaymentLink' AND __mj."IntegrationObjectField"."Name" = 'QrCodeImageId')
      )
  );

-- Target: ContentWorkspace.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ContentWorkspace'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ContentWorkspace'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ContentWorkspace'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ContentWorkspaceDoc' AND __mj."IntegrationObjectField"."Name" = 'ContentWorkspaceId')
        OR (o."Name" = 'ContentWorkspaceMember' AND __mj."IntegrationObjectField"."Name" = 'ContentWorkspaceId')
        OR (o."Name" = 'ContentWorkspaceSubscription' AND __mj."IntegrationObjectField"."Name" = 'ContentWorkspaceId')
      )
  );

-- Target: ContentWorkspacePermission.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ContentWorkspacePermission'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ContentWorkspacePermission'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ContentWorkspacePermission'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ContentWorkspaceMember' AND __mj."IntegrationObjectField"."Name" = 'ContentWorkspacePermissionId')
      )
  );

-- Target: Contract.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Contract'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Contract'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Contract'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AssetContractRelationship' AND __mj."IntegrationObjectField"."Name" = 'ContractId')
        OR (o."Name" = 'ContractContactRole' AND __mj."IntegrationObjectField"."Name" = 'ContractId')
        OR (o."Name" = 'Opportunity' AND __mj."IntegrationObjectField"."Name" = 'ContractId')
        OR (o."Name" = 'Order' AND __mj."IntegrationObjectField"."Name" = 'ContractId')
        OR (o."Name" = 'QuoteLineItem' AND __mj."IntegrationObjectField"."Name" = 'PricingContractId')
      )
  );

-- Target: ContractLineItem.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ContractLineItem'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ContractLineItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ContractLineItem'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ContractLineOutcome' AND __mj."IntegrationObjectField"."Name" = 'ContractLineItemId')
      )
  );

-- Target: ContractLineOutcome.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ContractLineOutcome'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ContractLineOutcome'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ContractLineOutcome'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ContractLineOutcomeData' AND __mj."IntegrationObjectField"."Name" = 'ContractLineOutcomeId')
      )
  );

-- Target: Conversation.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Conversation'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Conversation'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Conversation'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'MessagingSession' AND __mj."IntegrationObjectField"."Name" = 'ConversationId')
        OR (o."Name" = 'VoiceCall' AND __mj."IntegrationObjectField"."Name" = 'ConversationId')
      )
  );

-- Target: ConversationChannelDefinition.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ConversationChannelDefinition'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ConversationChannelDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ConversationChannelDefinition'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CustomMsgChannel' AND __mj."IntegrationObjectField"."Name" = 'ChannelDefinitionId')
        OR (o."Name" = 'MessagingChannel' AND __mj."IntegrationObjectField"."Name" = 'ChannelDefinitionId')
      )
  );

-- Target: ConversationParticipant.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ConversationParticipant'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ConversationParticipant'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ConversationParticipant'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'VoiceCall' AND __mj."IntegrationObjectField"."Name" = 'RecipientId')
      )
  );

-- Target: ConversationVendorInfo.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ConversationVendorInfo'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ConversationVendorInfo'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ConversationVendorInfo'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ConversationChannelDefinition' AND __mj."IntegrationObjectField"."Name" = 'ConversationVendorInfoId')
      )
  );

-- Target: Coupon.Id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Coupon'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Coupon'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Coupon'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CartDeliveryGroupMethodAdj' AND __mj."IntegrationObjectField"."Name" = 'AdjustmentBasisReferenceId')
        OR (o."Name" = 'CouponCodeRedemption' AND __mj."IntegrationObjectField"."Name" = 'CouponId')
        OR (o."Name" = 'OrderAdjustmentGroup' AND __mj."IntegrationObjectField"."Name" = 'AdjustmentBasisReferenceId')
        OR (o."Name" = 'OrderAdjustmentGroupSummary' AND __mj."IntegrationObjectField"."Name" = 'AdjustmentBasisReferenceId')
        OR (o."Name" = 'OrderItemAdjustmentLineItem' AND __mj."IntegrationObjectField"."Name" = 'AdjustmentBasisReferenceId')
        OR (o."Name" = 'OrderItemAdjustmentLineSummary' AND __mj."IntegrationObjectField"."Name" = 'AdjustmentBasisReferenceId')
        OR (o."Name" = 'WebCartAdjustmentBasis' AND __mj."IntegrationObjectField"."Name" = 'AdjustmentBasisReferenceId')
      )
  );

-- Target: CreditMemo.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CreditMemo'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CreditMemo'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CreditMemo'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CreditMemoAddressGroup' AND __mj."IntegrationObjectField"."Name" = 'CreditMemoId')
        OR (o."Name" = 'CreditMemoInvApplication' AND __mj."IntegrationObjectField"."Name" = 'CreditMemoId')
        OR (o."Name" = 'CreditMemoLine' AND __mj."IntegrationObjectField"."Name" = 'CreditMemoId')
        OR (o."Name" = 'PaymentCredit' AND __mj."IntegrationObjectField"."Name" = 'CreditMemoId')
      )
  );

-- Target: CreditMemoAddressGroup.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CreditMemoAddressGroup'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CreditMemoAddressGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CreditMemoAddressGroup'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CreditMemoLine' AND __mj."IntegrationObjectField"."Name" IN ('BillingAddressId', 'ShippingAddressId'))
      )
  );

-- Target: CronJobDetail.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CronJobDetail'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CronJobDetail'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CronJobDetail'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CronTrigger' AND __mj."IntegrationObjectField"."Name" = 'CronJobDetailId')
      )
  );

-- Target: CronTrigger.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CronTrigger'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CronTrigger'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CronTrigger'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AsyncApexJob' AND __mj."IntegrationObjectField"."Name" = 'CronTriggerId')
      )
  );

-- Target: CustomBrand.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CustomBrand'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CustomBrand'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CustomBrand'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CustomBrandAsset' AND __mj."IntegrationObjectField"."Name" = 'CustomBrandId')
      )
  );

-- Target: CustomHelpMenuSection.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CustomHelpMenuSection'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CustomHelpMenuSection'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CustomHelpMenuSection'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CustomHelpMenuItem' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
      )
  );

-- Target: CustomNotificationType.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CustomNotificationType'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CustomNotificationType'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CustomNotificationType'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'BroadcastCommunication' AND __mj."IntegrationObjectField"."Name" = 'CustomNotificationTypeId')
      )
  );

-- Target: CustomPermission.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CustomPermission'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'CustomPermission'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'CustomPermission'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CustomPermissionDependency' AND __mj."IntegrationObjectField"."Name" IN ('CustomPermissionId', 'RequiredCustomPermissionId'))
      )
  );

-- Target: Dashboard.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Dashboard'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Dashboard'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Dashboard'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'DashboardComponent' AND __mj."IntegrationObjectField"."Name" = 'DashboardId')
      )
  );

-- Target: DataAssessmentFieldMetric.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DataAssessmentFieldMetric'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DataAssessmentFieldMetric'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'DataAssessmentFieldMetric'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'DataAssessmentValueMetric' AND __mj."IntegrationObjectField"."Name" = 'DataAssessmentFieldMetricId')
      )
  );

-- Target: DataAssessmentMetric.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DataAssessmentMetric'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DataAssessmentMetric'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'DataAssessmentMetric'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'DataAssessmentFieldMetric' AND __mj."IntegrationObjectField"."Name" = 'DataAssessmentMetricId')
      )
  );

-- Target: DataDetectJobSession.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DataDetectJobSession'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DataDetectJobSession'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'DataDetectJobSession'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'DataDetectScanResult' AND __mj."IntegrationObjectField"."Name" = 'DataDetectJobSessionId')
      )
  );

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DataDetectPolicy'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DataDetectPolicy'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'DataDetectPolicy'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'DataDetectJobObjectSession' AND __mj."IntegrationObjectField"."Name" = 'DataDetectPolicyId')
        OR (o."Name" = 'DataDetectJobSession' AND __mj."IntegrationObjectField"."Name" = 'DataDetectPolicyId')
        OR (o."Name" = 'DataDetectPolicyObject' AND __mj."IntegrationObjectField"."Name" = 'DataDetectPolicyId')
        OR (o."Name" = 'DataDetectPolicySnapshot' AND __mj."IntegrationObjectField"."Name" = 'DataDetectPolicyId')
        OR (o."Name" = 'DataDetPlcyDataSrchExps' AND __mj."IntegrationObjectField"."Name" = 'DataDetectPolicyId')
        OR (o."Name" = 'DataDetPlcyMdatScanCrit' AND __mj."IntegrationObjectField"."Name" = 'DataDetectPolicyId')
        OR (o."Name" = 'DataDetPlcySstvDataCatg' AND __mj."IntegrationObjectField"."Name" = 'DataDetectPolicyId')
      )
  );

-- Target: DataDetectPolicyObject.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DataDetectPolicyObject'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DataDetectPolicyObject'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'DataDetectPolicyObject'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'DataDetectPolicyObjField' AND __mj."IntegrationObjectField"."Name" = 'DataDetectPolicyObjectId')
      )
  );

-- Target: DataDetectPolicySnapshot.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DataDetectPolicySnapshot'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DataDetectPolicySnapshot'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'DataDetectPolicySnapshot'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'DataDetectJobObjectSession' AND __mj."IntegrationObjectField"."Name" = 'DataDetectPolicySnapshotId')
        OR (o."Name" = 'DataDetectJobSession' AND __mj."IntegrationObjectField"."Name" = 'DataDetectPolicySnapshotId')
      )
  );

-- Target: DataUseLegalBasis.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DataUseLegalBasis'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DataUseLegalBasis'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'DataUseLegalBasis'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'DataUsePurpose' AND __mj."IntegrationObjectField"."Name" = 'LegalBasisId')
      )
  );

-- Target: DataUsePurpose.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DataUsePurpose'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DataUsePurpose'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'DataUsePurpose'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AuthorizationFormDataUse' AND __mj."IntegrationObjectField"."Name" = 'DataUsePurposeId')
        OR (o."Name" = 'CommSubscriptionConsent' AND __mj."IntegrationObjectField"."Name" = 'DataUsePurposeId')
        OR (o."Name" = 'ContactPointConsent' AND __mj."IntegrationObjectField"."Name" = 'DataUsePurposeId')
        OR (o."Name" = 'ContactPointTypeConsent' AND __mj."IntegrationObjectField"."Name" = 'DataUsePurposeId')
      )
  );

-- Target: DevopsEnvironment.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DevopsEnvironment'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DevopsEnvironment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'DevopsEnvironment'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'DevopsPipelineEnvironment' AND __mj."IntegrationObjectField"."Name" = 'DevopsEnvironmentId')
        OR (o."Name" = 'DevopsPipelineStage' AND __mj."IntegrationObjectField"."Name" = 'DevOpsEnvironmentId')
        OR (o."Name" = 'WorkItem' AND __mj."IntegrationObjectField"."Name" = 'DevelopmentEnvironmentId')
      )
  );

-- Target: DevopsPipeline.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DevopsPipeline'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DevopsPipeline'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'DevopsPipeline'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'DevopsActivityLog' AND __mj."IntegrationObjectField"."Name" = 'PipelineId')
        OR (o."Name" = 'DevopsProjectPipeline' AND __mj."IntegrationObjectField"."Name" = 'DevopsPipelineId')
      )
  );

-- Target: DevopsPipelineStage.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DevopsPipelineStage'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DevopsPipelineStage'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'DevopsPipelineStage'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'DevopsActivityLog' AND __mj."IntegrationObjectField"."Name" = 'PipelineStageId')
        OR (o."Name" = 'WorkItem' AND __mj."IntegrationObjectField"."Name" = 'DevopsPipelineStageId')
      )
  );

-- Target: DevopsProject.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DevopsProject'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DevopsProject'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'DevopsProject'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'DevopsActivityLog' AND __mj."IntegrationObjectField"."Name" = 'ProjectId')
        OR (o."Name" = 'WorkItem' AND __mj."IntegrationObjectField"."Name" = 'DevopsProjectId')
      )
  );

-- Target: DevopsRequestInfo.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DevopsRequestInfo'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DevopsRequestInfo'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'DevopsRequestInfo'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'DevopsActivityLog' AND __mj."IntegrationObjectField"."Name" = 'DevopsRequestInfoId')
        OR (o."Name" = 'DevopsPipelnStgProm' AND __mj."IntegrationObjectField"."Name" = 'RequestInfoId')
        OR (o."Name" = 'WorkItem' AND __mj."IntegrationObjectField"."Name" = 'RebaseStatusId')
      )
  );

-- Target: DigitalSignature.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DigitalSignature'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DigitalSignature'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'DigitalSignature'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'DocumentRecipient' AND __mj."IntegrationObjectField"."Name" = 'DigitalSignatureId')
      )
  );

-- Target: Domain.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Domain'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Domain'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Domain'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'DomainSite' AND __mj."IntegrationObjectField"."Name" = 'DomainId')
      )
  );

-- Target: DuplicateRecordSet.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DuplicateRecordSet'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DuplicateRecordSet'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'DuplicateRecordSet'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'DuplicateRecordItem' AND __mj."IntegrationObjectField"."Name" = 'DuplicateRecordSetId')
      )
  );

-- Target: DuplicateRule.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DuplicateRule'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'DuplicateRule'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'DuplicateRule'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'DuplicateRecordSet' AND __mj."IntegrationObjectField"."Name" = 'DuplicateRuleId')
      )
  );

-- Target: ElectronicMediaGroup.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ElectronicMediaGroup'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ElectronicMediaGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ElectronicMediaGroup'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ProductMedia' AND __mj."IntegrationObjectField"."Name" = 'ElectronicMediaGroupId')
      )
  );

-- Target: EmailDomainKey.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EmailDomainKey'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EmailDomainKey'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'EmailDomainKey'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'SenderEmailAddress' AND __mj."IntegrationObjectField"."Name" = 'EmailDomainKeyId')
      )
  );

-- Target: EmailInsight.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EmailInsight'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EmailInsight'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'EmailInsight'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'EmailInsightAction' AND __mj."IntegrationObjectField"."Name" = 'EmailInsightId')
      )
  );

-- Target: EmailMessage.Id (6 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EmailMessage'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EmailMessage'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'EmailMessage'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ActivityHistory' AND __mj."IntegrationObjectField"."Name" = 'AlternateDetailId')
        OR (o."Name" = 'EmailInsight' AND __mj."IntegrationObjectField"."Name" = 'EmailMessageId')
        OR (o."Name" = 'EmailMessageMigration' AND __mj."IntegrationObjectField"."Name" = 'EmailMessageId')
        OR (o."Name" = 'EmailMessageRelation' AND __mj."IntegrationObjectField"."Name" = 'EmailMessageId')
        OR (o."Name" = 'OpenActivity' AND __mj."IntegrationObjectField"."Name" = 'AlternateDetailId')
        OR (o."Name" = 'UnifiedEmail' AND __mj."IntegrationObjectField"."Name" = 'DetailId')
      )
  );

-- Target: EmailRelay.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EmailRelay'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EmailRelay'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'EmailRelay'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'EmailDomainFilter' AND __mj."IntegrationObjectField"."Name" = 'EmailRelayId')
      )
  );

-- Target: EmailRoutingAddress.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EmailRoutingAddress'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EmailRoutingAddress'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'EmailRoutingAddress'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'EmailMessage' AND __mj."IntegrationObjectField"."Name" = 'EmailRoutingAddressId')
      )
  );

-- Target: EmailServicesFunction.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EmailServicesFunction'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EmailServicesFunction'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'EmailServicesFunction'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'EmailServicesAddress' AND __mj."IntegrationObjectField"."Name" = 'FunctionId')
      )
  );

-- Target: EmailTemplate.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EmailTemplate'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EmailTemplate'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'EmailTemplate'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ApprovalAlertContentDef' AND __mj."IntegrationObjectField"."Name" = 'EmailTemplateId')
        OR (o."Name" = 'EmailMessage' AND __mj."IntegrationObjectField"."Name" = 'EmailTemplateId')
        OR (o."Name" = 'EmailTemplateMonthlyMetric' AND __mj."IntegrationObjectField"."Name" = 'EmailTemplateId')
        OR (o."Name" = 'NetworkEmailTmplAllowlist' AND __mj."IntegrationObjectField"."Name" = 'EmailTemplateId')
      )
  );

-- Target: Employee.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Employee'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Employee'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Employee'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'EmpUserProvisionProcessErr' AND __mj."IntegrationObjectField"."Name" = 'EmployeeId')
      )
  );

-- Target: EmpUserProvisioningProcess.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EmpUserProvisioningProcess'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EmpUserProvisioningProcess'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'EmpUserProvisioningProcess'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'EmpUserProvisionProcessErr' AND __mj."IntegrationObjectField"."Name" = 'ProvisioningProcessId')
      )
  );

-- Target: EnablementMeasureDefinition.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EnablementMeasureDefinition'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EnablementMeasureDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'EnablementMeasureDefinition'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'EnblMeasureObjectDefinition' AND __mj."IntegrationObjectField"."Name" = 'EnablementMeasureDefinitionId')
        OR (o."Name" = 'EnblProgramTaskMeasure' AND __mj."IntegrationObjectField"."Name" = 'EnablementMeasureDefinitionId')
      )
  );

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EnablementProgram'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EnablementProgram'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'EnablementProgram'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'EnablementProgramDefinition' AND __mj."IntegrationObjectField"."Name" = 'EnablementProgramId')
        OR (o."Name" = 'EnblProgramSection' AND __mj."IntegrationObjectField"."Name" = 'EnablementProgramId')
        OR (o."Name" = 'EnblProgramTaskDefinition' AND __mj."IntegrationObjectField"."Name" = 'EnablementProgramId')
        OR (o."Name" = 'LearningItem' AND __mj."IntegrationObjectField"."Name" = 'EnablementProgramId')
      )
  );

-- Target: EnblProgramSection.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EnblProgramSection'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EnblProgramSection'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'EnblProgramSection'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'EnblProgramTaskDefinition' AND __mj."IntegrationObjectField"."Name" = 'EnblProgramSectionId')
      )
  );

-- Target: EnblProgramTaskDefinition.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EnblProgramTaskDefinition'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EnblProgramTaskDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'EnblProgramTaskDefinition'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'EnblProgramTaskProgress' AND __mj."IntegrationObjectField"."Name" = 'EnblProgramTaskDefinitionId')
      )
  );

-- Target: EnblProgramTaskMeasure.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EnblProgramTaskMeasure'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EnblProgramTaskMeasure'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'EnblProgramTaskMeasure'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'EnblPgmTaskMeasureProgress' AND __mj."IntegrationObjectField"."Name" = 'EnblProgramTaskMeasureId')
      )
  );

-- Target: EnblProgramTaskSubCategory.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EnblProgramTaskSubCategory'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EnblProgramTaskSubCategory'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'EnblProgramTaskSubCategory'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'EnblProgramTaskDefinition' AND __mj."IntegrationObjectField"."Name" = 'CustomEnblPgmTaskSubCategoryId')
      )
  );

-- Target: EngagementChannelType.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EngagementChannelType'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EngagementChannelType'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'EngagementChannelType'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CommSubscriptionChannelType' AND __mj."IntegrationObjectField"."Name" = 'EngagementChannelTypeId')
        OR (o."Name" = 'CommSubscriptionConsent' AND __mj."IntegrationObjectField"."Name" = 'EngagementChannelTypeId')
      )
  );

-- Target: EngagementSignalMetric.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EngagementSignalMetric'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EngagementSignalMetric'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'EngagementSignalMetric'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AttribModelStageMetric' AND __mj."IntegrationObjectField"."Name" = 'EngagementSignalMetricId')
        OR (o."Name" = 'EngagementSignalCmpndMetric' AND __mj."IntegrationObjectField"."Name" IN ('DenomEngmtSignalMetricId', 'NumerEngmtSignalMetricId'))
      )
  );

-- Target: EnhancedLetterhead.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EnhancedLetterhead'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EnhancedLetterhead'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'EnhancedLetterhead'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'EmailTemplate' AND __mj."IntegrationObjectField"."Name" = 'EnhancedLetterheadId')
      )
  );

-- Target: Event.Id (8 field(s))

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
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
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
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AcceptedEventRelation' AND __mj."IntegrationObjectField"."Name" = 'EventId')
        OR (o."Name" = 'DeclinedEventRelation' AND __mj."IntegrationObjectField"."Name" = 'EventId')
        OR (o."Name" = 'EventRelation' AND __mj."IntegrationObjectField"."Name" = 'EventId')
        OR (o."Name" = 'EventStagedInviteeEmail' AND __mj."IntegrationObjectField"."Name" = 'EventId')
        OR (o."Name" = 'ExternalEventMapping' AND __mj."IntegrationObjectField"."Name" = 'EventId')
        OR (o."Name" = 'UndecidedEventRelation' AND __mj."IntegrationObjectField"."Name" = 'EventId')
        OR (o."Name" = 'UnifiedMeeting' AND __mj."IntegrationObjectField"."Name" = 'DetailId')
        OR (o."Name" = 'VideoCall' AND __mj."IntegrationObjectField"."Name" = 'EventId')
      )
  );

-- Target: EventRelayConfig.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EventRelayConfig'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'EventRelayConfig'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'EventRelayConfig'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'EventRelayFeedback' AND __mj."IntegrationObjectField"."Name" = 'EventRelayConfigId')
      )
  );

-- Target: ExternalClientApplication.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ExternalClientApplication'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ExternalClientApplication'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ExternalClientApplication'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ExtlRecShrCnct' AND __mj."IntegrationObjectField"."Name" = 'ExternalClientApplicationId')
      )
  );

-- Target: ExternalDataSource.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ExternalDataSource'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ExternalDataSource'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ExternalDataSource'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ContentVersion' AND __mj."IntegrationObjectField"."Name" = 'ExternalDataSourceId')
      )
  );

-- Target: ExternalEvent.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ExternalEvent'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ExternalEvent'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ExternalEvent'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ConferenceNumber' AND __mj."IntegrationObjectField"."Name" = 'ExternalEventId')
      )
  );

-- Target: ExternalSocialAccount.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ExternalSocialAccount'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ExternalSocialAccount'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ExternalSocialAccount'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'SocialPost' AND __mj."IntegrationObjectField"."Name" = 'OutboundSocialAccountId')
      )
  );

-- Target: ExtlRecShrCnct.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ExtlRecShrCnct'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ExtlRecShrCnct'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ExtlRecShrCnct'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ExtlRecShrCnctAccnt' AND __mj."IntegrationObjectField"."Name" = 'ExtlRecShrCnctId')
        OR (o."Name" = 'ExtlRecShrLead' AND __mj."IntegrationObjectField"."Name" = 'ExtlRecShrCnctId')
        OR (o."Name" = 'ExtlRecShrObject' AND __mj."IntegrationObjectField"."Name" = 'ExtlRecShrCnctId')
        OR (o."Name" = 'ExtlRecShrOpportunity' AND __mj."IntegrationObjectField"."Name" = 'ExtlRecShrCnctId')
        OR (o."Name" = 'ExtlRecShrRecordMap' AND __mj."IntegrationObjectField"."Name" = 'ExtlRecShrCnctId')
      )
  );

-- Target: ExtlRecShrField.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ExtlRecShrField'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ExtlRecShrField'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ExtlRecShrField'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ExtlRecShrFieldMap' AND __mj."IntegrationObjectField"."Name" IN ('ImportedFieldId', 'InternalFieldId'))
        OR (o."Name" = 'ExtlRecShrPcklstOptn' AND __mj."IntegrationObjectField"."Name" = 'ExtlRecShrFieldId')
      )
  );

-- Target: ExtlRecShrObject.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ExtlRecShrObject'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ExtlRecShrObject'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ExtlRecShrObject'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ExtlRecShrField' AND __mj."IntegrationObjectField"."Name" = 'ExtlRecShrObjectId')
      )
  );

-- Target: ExtlRecShrPcklstOptn.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ExtlRecShrPcklstOptn'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ExtlRecShrPcklstOptn'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ExtlRecShrPcklstOptn'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ExtlRecShrPicklistMap' AND __mj."IntegrationObjectField"."Name" IN ('ImportedPcklstOptionId', 'InternalPcklstOptionId'))
      )
  );

-- Target: FeedComment.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FeedComment'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FeedComment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'FeedComment'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'FeedItem' AND __mj."IntegrationObjectField"."Name" = 'BestCommentId')
      )
  );

-- Target: FeedItem.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FeedItem'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FeedItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'FeedItem'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'Announcement' AND __mj."IntegrationObjectField"."Name" = 'FeedItemId')
        OR (o."Name" = 'WorkThanks' AND __mj."IntegrationObjectField"."Name" = 'FeedItemId')
      )
  );

-- Target: FeedPollChoice.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FeedPollChoice'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FeedPollChoice'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'FeedPollChoice'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'FeedPollVote' AND __mj."IntegrationObjectField"."Name" = 'ChoiceId')
      )
  );

-- Target: FiscalYearSettings.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FiscalYearSettings'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FiscalYearSettings'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'FiscalYearSettings'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'Period' AND __mj."IntegrationObjectField"."Name" = 'FiscalYearSettingsId')
      )
  );

-- Target: FldSvcObjChg.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FldSvcObjChg'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FldSvcObjChg'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'FldSvcObjChg'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'FldSvcObjChgDtl' AND __mj."IntegrationObjectField"."Name" = 'FldSvcObjChgId')
      )
  );

-- Target: FlowInterview.Id (6 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FlowInterview'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FlowInterview'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'FlowInterview'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'DynamicDataCapture' AND __mj."IntegrationObjectField"."Name" = 'PausedFlowInterviewId')
        OR (o."Name" = 'FlowInterviewShare' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
        OR (o."Name" = 'FlowOrchestrationInstance' AND __mj."IntegrationObjectField"."Name" = 'InterviewId')
        OR (o."Name" = 'FlowRecordRelation' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
        OR (o."Name" = 'FlowStageRelation' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
        OR (o."Name" = 'RecordAction' AND __mj."IntegrationObjectField"."Name" = 'FlowInterviewId')
      )
  );

-- Target: FlowInterviewLog.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FlowInterviewLog'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FlowInterviewLog'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'FlowInterviewLog'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'FlowInterviewLogEntry' AND __mj."IntegrationObjectField"."Name" = 'FlowInterviewLogId')
      )
  );

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FlowOrchestration'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FlowOrchestration'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'FlowOrchestration'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'FlowOrchestrationVersion' AND __mj."IntegrationObjectField"."Name" IN ('FlowOrchestrationId', 'OverriddenById', 'OverriddenOrchestrationId', 'SourceTemplateId'))
      )
  );

-- Target: FlowOrchestrationInstance.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FlowOrchestrationInstance'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FlowOrchestrationInstance'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'FlowOrchestrationInstance'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ApprovalSubmission' AND __mj."IntegrationObjectField"."Name" = 'FlowOrchestrationInstanceId')
        OR (o."Name" = 'FlowOrchestrationLog' AND __mj."IntegrationObjectField"."Name" = 'OrchestationInstanceId')
        OR (o."Name" = 'FlowOrchestrationStageInstance' AND __mj."IntegrationObjectField"."Name" = 'OrchestrationInstanceId')
        OR (o."Name" = 'FlowOrchestrationStepInstance' AND __mj."IntegrationObjectField"."Name" = 'OrchestrationInstanceId')
      )
  );

-- Target: FlowOrchestrationStageInstance.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FlowOrchestrationStageInstance'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FlowOrchestrationStageInstance'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'FlowOrchestrationStageInstance'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'FlowOrchestrationStepInstance' AND __mj."IntegrationObjectField"."Name" = 'StageInstanceId')
      )
  );

-- Target: FlowOrchestrationStepInstance.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FlowOrchestrationStepInstance'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FlowOrchestrationStepInstance'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'FlowOrchestrationStepInstance'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'FlowOrchestrationWorkItem' AND __mj."IntegrationObjectField"."Name" = 'StepInstanceId')
      )
  );

-- Target: FlowOrchestrationWorkItem.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FlowOrchestrationWorkItem'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FlowOrchestrationWorkItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'FlowOrchestrationWorkItem'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ApprovalWorkItem' AND __mj."IntegrationObjectField"."Name" = 'FlowOrchestrationWorkItemId')
      )
  );

-- Target: FlowRecord.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FlowRecord'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FlowRecord'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'FlowRecord'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'FlowRecordElementOccurrence' AND __mj."IntegrationObjectField"."Name" = 'FlowRecordId')
        OR (o."Name" = 'FlowRecordVersion' AND __mj."IntegrationObjectField"."Name" IN ('FlowRecordId', 'OverriddenById', 'SourceTemplateId'))
      )
  );

-- Target: FlowRecordElement.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FlowRecordElement'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FlowRecordElement'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'FlowRecordElement'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'FlowRecordElementOccurrence' AND __mj."IntegrationObjectField"."Name" = 'FlowRecordElementId')
      )
  );

-- Target: FlowRecordVersion.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FlowRecordVersion'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FlowRecordVersion'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'FlowRecordVersion'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'FlowRecordElementOccurrence' AND __mj."IntegrationObjectField"."Name" = 'FlowRecordVersionId')
      )
  );

-- Target: Folder.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Folder'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Folder'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Folder'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'QuickText' AND __mj."IntegrationObjectField"."Name" = 'FolderId')
        OR (o."Name" = 'QuickTextUsage' AND __mj."IntegrationObjectField"."Name" = 'FolderId')
        OR (o."Name" = 'WaveAutoInstallRequest' AND __mj."IntegrationObjectField"."Name" = 'FolderId')
      )
  );

-- Target: ForecastingColumnDefinition.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ForecastingColumnDefinition'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ForecastingColumnDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ForecastingColumnDefinition'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ForecastingColumnDefinitionLocalization' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
      )
  );

-- Target: ForecastingCustomCategory.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ForecastingCustomCategory'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ForecastingCustomCategory'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ForecastingCustomCategory'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'FrcstCustmCatgRampRateSrc' AND __mj."IntegrationObjectField"."Name" = 'ForecastingCustomCategoryId')
        OR (o."Name" = 'FrcstCustmzAdjustment' AND __mj."IntegrationObjectField"."Name" = 'ForecastingCustomCategoryId')
        OR (o."Name" = 'FrcstCustmzOwnerAdjustment' AND __mj."IntegrationObjectField"."Name" = 'ForecastingCustomCategoryId')
      )
  );

-- Target: ForecastingFilter.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ForecastingFilter'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ForecastingFilter'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ForecastingFilter'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ForecastingFilterCondition' AND __mj."IntegrationObjectField"."Name" = 'ForecastingFilterId')
      )
  );

-- Target: ForecastingGroup.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ForecastingGroup'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ForecastingGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ForecastingGroup'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ForecastingGroupItem' AND __mj."IntegrationObjectField"."Name" = 'ForecastingGroupId')
      )
  );

-- Target: ForecastingGroupItem.Id (6 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ForecastingGroupItem'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ForecastingGroupItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ForecastingGroupItem'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ForecastingAdjustment' AND __mj."IntegrationObjectField"."Name" = 'ForecastingGroupItemId')
        OR (o."Name" = 'ForecastingCustomData' AND __mj."IntegrationObjectField"."Name" = 'ForecastingGroupItemId')
        OR (o."Name" = 'ForecastingItem' AND __mj."IntegrationObjectField"."Name" = 'ForecastingGroupItemId')
        OR (o."Name" = 'ForecastingOwnerAdjustment' AND __mj."IntegrationObjectField"."Name" = 'ForecastingGroupItemId')
        OR (o."Name" = 'ForecastingQuota' AND __mj."IntegrationObjectField"."Name" = 'ForecastingGroupItemId')
        OR (o."Name" = 'ForecastingSubmission' AND __mj."IntegrationObjectField"."Name" = 'ForecastingGroupItemId')
      )
  );

-- Target: ForecastingSourceDefinition.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ForecastingSourceDefinition'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ForecastingSourceDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ForecastingSourceDefinition'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ForecastingCustomCategory' AND __mj."IntegrationObjectField"."Name" = 'ForecastingSourceDefinitionId')
        OR (o."Name" = 'ForecastingTypeSource' AND __mj."IntegrationObjectField"."Name" IN ('ForecastingSourceDefinitionId', 'ParentSourceDefinitionId'))
        OR (o."Name" = 'FrcstCustmCatgRampRateSrc' AND __mj."IntegrationObjectField"."Name" = 'BaseValueFrcstSrcDefinitionId')
      )
  );

-- Target: ForecastingType.Id (9 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ForecastingType'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ForecastingType'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ForecastingType'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ForecastingColumnDefinition' AND __mj."IntegrationObjectField"."Name" = 'ForecastingTypeId')
        OR (o."Name" = 'ForecastingCustomCategory' AND __mj."IntegrationObjectField"."Name" = 'ForecastingTypeId')
        OR (o."Name" = 'ForecastingCustomData' AND __mj."IntegrationObjectField"."Name" = 'ForecastingTypeId')
        OR (o."Name" = 'ForecastingFilter' AND __mj."IntegrationObjectField"."Name" = 'ForecastingTypeId')
        OR (o."Name" = 'ForecastingGroup' AND __mj."IntegrationObjectField"."Name" = 'ForecastingTypeId')
        OR (o."Name" = 'ForecastingSubmission' AND __mj."IntegrationObjectField"."Name" = 'ForecastingTypeId')
        OR (o."Name" = 'ForecastingTypeSource' AND __mj."IntegrationObjectField"."Name" = 'ForecastingTypeId')
        OR (o."Name" = 'FrcstCustmzAdjustment' AND __mj."IntegrationObjectField"."Name" = 'ForecastingTypeId')
        OR (o."Name" = 'FrcstCustmzOwnerAdjustment' AND __mj."IntegrationObjectField"."Name" = 'ForecastingTypeId')
      )
  );

-- Target: ForecastingTypeSource.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ForecastingTypeSource'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ForecastingTypeSource'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ForecastingTypeSource'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ForecastingFilter' AND __mj."IntegrationObjectField"."Name" = 'ForecastingTypeSourceId')
      )
  );

-- Target: FulfillmentOrder.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FulfillmentOrder'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'FulfillmentOrder'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'FulfillmentOrder'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'FulfillmentOrderLineItem' AND __mj."IntegrationObjectField"."Name" = 'FulfillmentOrderId')
        OR (o."Name" = 'PickTicketAssignment' AND __mj."IntegrationObjectField"."Name" = 'AttachedToId')
      )
  );

-- Target: GenAiPlannerDefinition.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'GenAiPlannerDefinition'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'GenAiPlannerDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'GenAiPlannerDefinition'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'GenAiFunctionDefinition' AND __mj."IntegrationObjectField"."Name" = 'PlannerId')
        OR (o."Name" = 'GenAiPlannerFunctionDef' AND __mj."IntegrationObjectField"."Name" = 'PlannerId')
        OR (o."Name" = 'GenAiPluginDefinition' AND __mj."IntegrationObjectField"."Name" = 'PlannerId')
        OR (o."Name" = 'GenOpPlanRequest' AND __mj."IntegrationObjectField"."Name" = 'CopilotId')
      )
  );

-- Target: GenAiPlannerFunctionDef.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'GenAiPlannerFunctionDef'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'GenAiPlannerFunctionDef'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'GenAiPlannerFunctionDef'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'GenAiFunctionDefinition' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
      )
  );

-- Target: GenAiPluginDefinition.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'GenAiPluginDefinition'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'GenAiPluginDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'GenAiPluginDefinition'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'GenAiFunctionDefinition' AND __mj."IntegrationObjectField"."Name" = 'PluginId')
      )
  );

-- Target: GeoCountry.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'GeoCountry'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'GeoCountry'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'GeoCountry'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'GeoState' AND __mj."IntegrationObjectField"."Name" = 'GeoCountryId')
        OR (o."Name" = 'TaxGeoConfig' AND __mj."IntegrationObjectField"."Name" = 'GeoCountryId')
        OR (o."Name" = 'TaxRate' AND __mj."IntegrationObjectField"."Name" = 'GeoCountryId')
      )
  );

-- Target: GeoState.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'GeoState'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'GeoState'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'GeoState'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'TaxRate' AND __mj."IntegrationObjectField"."Name" = 'GeoStateId')
      )
  );

-- Target: Group.Id (12 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Group'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Group'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Group'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AgentWork' AND __mj."IntegrationObjectField"."Name" = 'OriginalGroupId')
        OR (o."Name" = 'BroadcastTopicGroup' AND __mj."IntegrationObjectField"."Name" = 'GroupId')
        OR (o."Name" = 'ContactCenterChannel' AND __mj."IntegrationObjectField"."Name" IN ('OmniCallbackFallbackQueueId', 'VoicemailFallbackQueueId'))
        OR (o."Name" = 'GroupMember' AND __mj."IntegrationObjectField"."Name" = 'GroupId')
        OR (o."Name" = 'JobProfileQueueGroup' AND __mj."IntegrationObjectField"."Name" = 'GroupId')
        OR (o."Name" = 'LiveChatButton' AND __mj."IntegrationObjectField"."Name" = 'QueueId')
        OR (o."Name" = 'MessagingChannel' AND __mj."IntegrationObjectField"."Name" = 'TargetQueueId')
        OR (o."Name" = 'OmniSupervisorConfigGroup' AND __mj."IntegrationObjectField"."Name" = 'GroupId')
        OR (o."Name" = 'OmniSupervisorConfigQueue' AND __mj."IntegrationObjectField"."Name" = 'QueueId')
        OR (o."Name" = 'QueueSobject' AND __mj."IntegrationObjectField"."Name" = 'QueueId')
        OR (o."Name" = 'ServiceRequest' AND __mj."IntegrationObjectField"."Name" = 'AssignedGroupId')
      )
  );

-- Target: Holiday.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Holiday'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Holiday'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Holiday'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'OperatingHoursHoliday' AND __mj."IntegrationObjectField"."Name" = 'HolidayId')
      )
  );

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Idea'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Idea'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Idea'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'IdeaComment' AND __mj."IntegrationObjectField"."Name" = 'IdeaId')
      )
  );

-- Target: Incident.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Incident'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Incident'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Incident'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'BroadcastCommunication' AND __mj."IntegrationObjectField"."Name" = 'RelatedRecordId')
        OR (o."Name" = 'IncidentRelatedItem' AND __mj."IntegrationObjectField"."Name" = 'IncidentId')
      )
  );

-- Target: Individual.Id (9 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Individual'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Individual'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Individual'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CommSubscriptionConsent' AND __mj."IntegrationObjectField"."Name" = 'PartyId')
        OR (o."Name" = 'Contact' AND __mj."IntegrationObjectField"."Name" = 'IndividualId')
        OR (o."Name" = 'ContactPointTypeConsent' AND __mj."IntegrationObjectField"."Name" = 'PartyId')
        OR (o."Name" = 'Customer' AND __mj."IntegrationObjectField"."Name" = 'PartyId')
        OR (o."Name" = 'IndividualHistory' AND __mj."IntegrationObjectField"."Name" = 'IndividualId')
        OR (o."Name" = 'IndividualShare' AND __mj."IntegrationObjectField"."Name" = 'IndividualId')
        OR (o."Name" = 'Lead' AND __mj."IntegrationObjectField"."Name" = 'IndividualId')
        OR (o."Name" = 'PartyConsent' AND __mj."IntegrationObjectField"."Name" = 'PartyId')
        OR (o."Name" = 'Seller' AND __mj."IntegrationObjectField"."Name" = 'PartyId')
      )
  );

-- Target: InternalOrganizationUnit.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'InternalOrganizationUnit'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'InternalOrganizationUnit'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'InternalOrganizationUnit'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'Employee2' AND __mj."IntegrationObjectField"."Name" = 'InternalOrganizationUnitId')
      )
  );

-- Target: InventoryReservation.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'InventoryReservation'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'InventoryReservation'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'InventoryReservation'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'InventoryItemReservation' AND __mj."IntegrationObjectField"."Name" = 'InventoryReservationId')
      )
  );

-- Target: Invoice.Id (4 field(s))

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
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
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
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'FulfillmentOrder' AND __mj."IntegrationObjectField"."Name" = 'InvoiceId')
        OR (o."Name" = 'InvoiceAddressGroup' AND __mj."IntegrationObjectField"."Name" = 'InvoiceId')
        OR (o."Name" = 'InvoiceLine' AND __mj."IntegrationObjectField"."Name" = 'InvoiceId')
        OR (o."Name" = 'PaymentLineInvoice' AND __mj."IntegrationObjectField"."Name" = 'InvoiceId')
      )
  );

-- Target: InvoiceAddressGroup.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'InvoiceAddressGroup'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'InvoiceAddressGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'InvoiceAddressGroup'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'InvoiceLine' AND __mj."IntegrationObjectField"."Name" IN ('BillingAddressId', 'ShippingAddressId'))
      )
  );

-- Target: InvoiceBatchRun.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'InvoiceBatchRun'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'InvoiceBatchRun'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'InvoiceBatchRun'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'BillingPeriodItem' AND __mj."IntegrationObjectField"."Name" = 'InvoiceBatchRunId')
        OR (o."Name" = 'BillingSchedule' AND __mj."IntegrationObjectField"."Name" = 'InvoiceBatchRunId')
        OR (o."Name" = 'Invoice' AND __mj."IntegrationObjectField"."Name" = 'InvoiceBatchRunId')
        OR (o."Name" = 'InvoiceBatchRunRecovery' AND __mj."IntegrationObjectField"."Name" = 'InvoiceBatchRunId')
      )
  );

-- Target: InvoiceLine.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'InvoiceLine'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'InvoiceLine'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'InvoiceLine'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'BillingPeriodItem' AND __mj."IntegrationObjectField"."Name" = 'InvoiceLineId')
      )
  );

-- Target: JobProfile.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'JobProfile'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'JobProfile'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'JobProfile'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'JobProfileQueueGroup' AND __mj."IntegrationObjectField"."Name" = 'JobProfileId')
        OR (o."Name" = 'SchedulingAdherenceSummary' AND __mj."IntegrationObjectField"."Name" = 'JobProfileId')
        OR (o."Name" = 'ShiftTemplate' AND __mj."IntegrationObjectField"."Name" = 'JobProfileId')
        OR (o."Name" = 'WorkDemographic' AND __mj."IntegrationObjectField"."Name" = 'JobProfileId')
      )
  );

-- Target: Knowledge__kav.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Knowledge__kav'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Knowledge__kav'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Knowledge__kav'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'SearchActivity' AND __mj."IntegrationObjectField"."Name" = 'ClickedRecordId')
      )
  );

-- Target: Lead.Id (8 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Lead'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Lead'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Lead'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CampaignMember' AND __mj."IntegrationObjectField"."Name" = 'LeadId')
        OR (o."Name" = 'DealIndirectPartner' AND __mj."IntegrationObjectField"."Name" = 'LeadId')
        OR (o."Name" = 'ExtlRecShrRecordMap' AND __mj."IntegrationObjectField"."Name" = 'InternalRecordId')
        OR (o."Name" = 'LeadDailyMetric' AND __mj."IntegrationObjectField"."Name" = 'LeadId')
        OR (o."Name" = 'LeadMonthlyMetric' AND __mj."IntegrationObjectField"."Name" = 'LeadId')
        OR (o."Name" = 'LeadShare' AND __mj."IntegrationObjectField"."Name" = 'LeadId')
        OR (o."Name" = 'MessagingEndUser' AND __mj."IntegrationObjectField"."Name" = 'LeadId')
        OR (o."Name" = 'Prospect' AND __mj."IntegrationObjectField"."Name" = 'ConvertedLeadId')
      )
  );

-- Target: LearningItem.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'LearningItem'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'LearningItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'LearningItem'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'EnblProgramTaskDefinition' AND __mj."IntegrationObjectField"."Name" = 'LearningItemId')
        OR (o."Name" = 'LearningItemAssignment' AND __mj."IntegrationObjectField"."Name" = 'LearningItemId')
        OR (o."Name" = 'LearningItemProgress' AND __mj."IntegrationObjectField"."Name" = 'LearningItemId')
        OR (o."Name" = 'LearningItemSubmission' AND __mj."IntegrationObjectField"."Name" = 'LearningItemId')
        OR (o."Name" = 'LearningPractice' AND __mj."IntegrationObjectField"."Name" = 'LearningItemId')
      )
  );

-- Target: LearningItemProgress.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'LearningItemProgress'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'LearningItemProgress'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'LearningItemProgress'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'EnblProgramTaskProgress' AND __mj."IntegrationObjectField"."Name" = 'LearningItemProgressId')
        OR (o."Name" = 'LearningItemAssignment' AND __mj."IntegrationObjectField"."Name" = 'ProgressId')
      )
  );

-- Target: LearningItemType.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'LearningItemType'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'LearningItemType'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'LearningItemType'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'EnblProgramTaskSubCategory' AND __mj."IntegrationObjectField"."Name" = 'LearningItemTypeId')
        OR (o."Name" = 'LearningItem' AND __mj."IntegrationObjectField"."Name" = 'CustomLearningItemTypeId')
      )
  );

-- Target: LegalEntity.Id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'LegalEntity'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'LegalEntity'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'LegalEntity'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AssetActionSource' AND __mj."IntegrationObjectField"."Name" = 'LegalEntityId')
        OR (o."Name" = 'AssetStatePeriod' AND __mj."IntegrationObjectField"."Name" = 'LegalEntityId')
        OR (o."Name" = 'BillingTreatment' AND __mj."IntegrationObjectField"."Name" = 'LegalEntityId')
        OR (o."Name" = 'InvoiceLine' AND __mj."IntegrationObjectField"."Name" = 'LegalEntityId')
        OR (o."Name" = 'Payment' AND __mj."IntegrationObjectField"."Name" = 'LegalEntityId')
        OR (o."Name" = 'QuoteLineItem' AND __mj."IntegrationObjectField"."Name" = 'LegalEntityId')
        OR (o."Name" = 'TaxRate' AND __mj."IntegrationObjectField"."Name" = 'LegalEntityId')
      )
  );

-- Target: LinkedArticle.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'LinkedArticle'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'LinkedArticle'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'LinkedArticle'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'KnowledgeArticleFeedback' AND __mj."IntegrationObjectField"."Name" = 'LinkedArticleEntityId')
      )
  );

-- Target: ListEmail.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ListEmail'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ListEmail'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ListEmail'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ListEmailIndividualRecipient' AND __mj."IntegrationObjectField"."Name" = 'ListEmailId')
        OR (o."Name" = 'ListEmailMonthlyMetric' AND __mj."IntegrationObjectField"."Name" = 'ListEmailId')
        OR (o."Name" = 'ListEmailRecipientSource' AND __mj."IntegrationObjectField"."Name" = 'ListEmailId')
      )
  );

-- Target: ListView.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ListView'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ListView'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ListView'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CalendarView' AND __mj."IntegrationObjectField"."Name" = 'ListViewFilterId')
        OR (o."Name" = 'ListViewChartInstance' AND __mj."IntegrationObjectField"."Name" = 'ListViewContextId')
        OR (o."Name" = 'PipelineInspectionListView' AND __mj."IntegrationObjectField"."Name" = 'ListViewId')
        OR (o."Name" = 'UserListView' AND __mj."IntegrationObjectField"."Name" = 'ListViewId')
      )
  );

-- Target: ListViewChart.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ListViewChart'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ListViewChart'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ListViewChart'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ListViewChartInstance' AND __mj."IntegrationObjectField"."Name" = 'ListViewChartId')
      )
  );

-- Target: LiveChatObjectAccessDefinition.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'LiveChatObjectAccessDefinition'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'LiveChatObjectAccessDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'LiveChatObjectAccessDefinition'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'LiveChatObjectAccessConfig' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
      )
  );

-- Target: Location.Id (21 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Location'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Location'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Location'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'Address' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
        OR (o."Name" = 'AssociatedLocation' AND __mj."IntegrationObjectField"."Name" = 'LocationId')
        OR (o."Name" = 'FulfillmentOrder' AND __mj."IntegrationObjectField"."Name" = 'FulfilledFromLocationId')
        OR (o."Name" = 'PickTicket' AND __mj."IntegrationObjectField"."Name" = 'LocationId')
        OR (o."Name" = 'PriceProtectExecLineItem' AND __mj."IntegrationObjectField"."Name" = 'LocationId')
        OR (o."Name" = 'ProductItem' AND __mj."IntegrationObjectField"."Name" = 'LocationId')
        OR (o."Name" = 'ProductRequest' AND __mj."IntegrationObjectField"."Name" IN ('DestinationLocationId', 'SourceLocationId'))
        OR (o."Name" = 'ProductRequestLineItem' AND __mj."IntegrationObjectField"."Name" IN ('DestinationLocationId', 'SourceLocationId'))
        OR (o."Name" = 'ProductTransfer' AND __mj."IntegrationObjectField"."Name" IN ('DestinationLocationId', 'SourceLocationId'))
        OR (o."Name" = 'ReturnOrder' AND __mj."IntegrationObjectField"."Name" IN ('DestinationLocationId', 'SourceLocationId'))
        OR (o."Name" = 'ReturnOrderLineItem' AND __mj."IntegrationObjectField"."Name" IN ('DestinationLocationId', 'SourceLocationId'))
        OR (o."Name" = 'ServiceResource' AND __mj."IntegrationObjectField"."Name" = 'LocationId')
        OR (o."Name" = 'Shipment' AND __mj."IntegrationObjectField"."Name" IN ('DestinationLocationId', 'SourceLocationId'))
        OR (o."Name" = 'WorkOrder' AND __mj."IntegrationObjectField"."Name" = 'LocationId')
        OR (o."Name" = 'WorkOrderLineItem' AND __mj."IntegrationObjectField"."Name" = 'LocationId')
      )
  );

-- Target: LocationGroup.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'LocationGroup'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'LocationGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'LocationGroup'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'DeliveryEstimationSetup' AND __mj."IntegrationObjectField"."Name" = 'LocationGroupId')
      )
  );

-- Target: LoginGeo.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'LoginGeo'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'LoginGeo'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'LoginGeo'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AuthSession' AND __mj."IntegrationObjectField"."Name" = 'LoginGeoId')
        OR (o."Name" = 'LoginHistory' AND __mj."IntegrationObjectField"."Name" = 'LoginGeoId')
        OR (o."Name" = 'VerificationHistory' AND __mj."IntegrationObjectField"."Name" = 'LoginGeoId')
      )
  );

-- Target: LoginHistory.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'LoginHistory'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'LoginHistory'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'LoginHistory'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AuthSession' AND __mj."IntegrationObjectField"."Name" = 'LoginHistoryId')
        OR (o."Name" = 'VerificationHistory' AND __mj."IntegrationObjectField"."Name" = 'LoginHistoryId')
      )
  );

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ManagedContent'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ManagedContent'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ManagedContent'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'Brief' AND __mj."IntegrationObjectField"."Name" = 'BrandId')
        OR (o."Name" = 'ManagedContentVariant' AND __mj."IntegrationObjectField"."Name" = 'ManagedContentId')
        OR (o."Name" = 'NetworkDataCategory' AND __mj."IntegrationObjectField"."Name" = 'ImageId')
        OR (o."Name" = 'UserRelatedRecordContent' AND __mj."IntegrationObjectField"."Name" = 'ManagedContentId')
        OR (o."Name" = 'WebStoreMessageContent' AND __mj."IntegrationObjectField"."Name" = 'ManagedContentId')
      )
  );

-- Target: ManagedContentSpace.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ManagedContentSpace'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ManagedContentSpace'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ManagedContentSpace'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ManagedContent' AND __mj."IntegrationObjectField"."Name" = 'AuthoredManagedContentSpaceId')
      )
  );

-- Target: MatchingRule.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'MatchingRule'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'MatchingRule'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'MatchingRule'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'MatchingRuleItem' AND __mj."IntegrationObjectField"."Name" = 'MatchingRuleId')
      )
  );

-- Target: MerchAccPaymentMethodSet.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'MerchAccPaymentMethodSet'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'MerchAccPaymentMethodSet'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'MerchAccPaymentMethodSet'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'MerchAccPaymentMethodType' AND __mj."IntegrationObjectField"."Name" = 'PaymentMethodSetId')
        OR (o."Name" = 'PaymentLink' AND __mj."IntegrationObjectField"."Name" = 'PaymentMethodSetId')
      )
  );

-- Target: MerchantAccount.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'MerchantAccount'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'MerchantAccount'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'MerchantAccount'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'MerchAccPaymentMethodSet' AND __mj."IntegrationObjectField"."Name" = 'MerchantAccountId')
        OR (o."Name" = 'MerchantAccountEvent' AND __mj."IntegrationObjectField"."Name" = 'MerchantAccountId')
        OR (o."Name" = 'PaymentGateway' AND __mj."IntegrationObjectField"."Name" = 'MerchantAccountId')
        OR (o."Name" = 'PaymentIntent' AND __mj."IntegrationObjectField"."Name" = 'MerchantAccountId')
        OR (o."Name" = 'SavedPaymentMethod' AND __mj."IntegrationObjectField"."Name" = 'MerchantAccountId')
      )
  );

-- Target: MessagingChannel.Id (9 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'MessagingChannel'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'MessagingChannel'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'MessagingChannel'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ContactCenterChannel' AND __mj."IntegrationObjectField"."Name" = 'ChannelId')
        OR (o."Name" = 'CustomMsgChannel' AND __mj."IntegrationObjectField"."Name" = 'MessagingChannelId')
        OR (o."Name" = 'MessagingChannelSkill' AND __mj."IntegrationObjectField"."Name" = 'MessagingChannelId')
        OR (o."Name" = 'MessagingChannelUsage' AND __mj."IntegrationObjectField"."Name" = 'MessagingChannelId')
        OR (o."Name" = 'MessagingDeliveryError' AND __mj."IntegrationObjectField"."Name" = 'MessagingChannelId')
        OR (o."Name" = 'MessagingEndUser' AND __mj."IntegrationObjectField"."Name" = 'MessagingChannelId')
        OR (o."Name" = 'MessagingLink' AND __mj."IntegrationObjectField"."Name" = 'MessagingChannelId')
        OR (o."Name" = 'MessagingSession' AND __mj."IntegrationObjectField"."Name" = 'MessagingChannelId')
        OR (o."Name" = 'MsgChannelLanguageKeyword' AND __mj."IntegrationObjectField"."Name" = 'MessagingChannelId')
      )
  );

-- Target: MessagingChannelUsage.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'MessagingChannelUsage'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'MessagingChannelUsage'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'MessagingChannelUsage'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CommSubscriptionChannelType' AND __mj."IntegrationObjectField"."Name" = 'MessagingChannelUsageId')
        OR (o."Name" = 'MsgChannelLanguageKeyword' AND __mj."IntegrationObjectField"."Name" = 'MessagingChannelUsageId')
        OR (o."Name" = 'MsgChannelUsageExternalOrg' AND __mj."IntegrationObjectField"."Name" = 'MessagingChannelUsageId')
      )
  );

-- Target: MessagingEndUser.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'MessagingEndUser'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'MessagingEndUser'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'MessagingEndUser'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'MessagingDeliveryError' AND __mj."IntegrationObjectField"."Name" = 'MessagingEndUserId')
        OR (o."Name" = 'MessagingSession' AND __mj."IntegrationObjectField"."Name" = 'MessagingEndUserId')
        OR (o."Name" = 'VoiceCall' AND __mj."IntegrationObjectField"."Name" = 'EndUserId')
      )
  );

-- Target: MessagingTemplate.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'MessagingTemplate'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'MessagingTemplate'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'MessagingTemplate'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'MessagingDeliveryError' AND __mj."IntegrationObjectField"."Name" = 'MessagingTemplateId')
      )
  );

-- Target: MLModel.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'MLModel'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'MLModel'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'MLModel'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AIRecordInsight' AND __mj."IntegrationObjectField"."Name" = 'ModelId')
        OR (o."Name" = 'MLModelFactor' AND __mj."IntegrationObjectField"."Name" = 'ModelId')
        OR (o."Name" = 'MLModelFactorComponent' AND __mj."IntegrationObjectField"."Name" = 'ModelId')
        OR (o."Name" = 'MLModelMetric' AND __mj."IntegrationObjectField"."Name" = 'ModelId')
      )
  );

-- Target: MLModelFactor.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'MLModelFactor'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'MLModelFactor'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'MLModelFactor'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'MLModelFactorComponent' AND __mj."IntegrationObjectField"."Name" = 'ModelFactorId')
      )
  );

-- Target: MLPredictionDefinition.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'MLPredictionDefinition'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'MLPredictionDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'MLPredictionDefinition'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AIRecordInsight' AND __mj."IntegrationObjectField"."Name" = 'MlPredictionDefinitionId')
        OR (o."Name" = 'MLModel' AND __mj."IntegrationObjectField"."Name" = 'PredictionDefinitionId')
      )
  );

-- Target: MLRecommendationDefinition.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'MLRecommendationDefinition'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'MLRecommendationDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'MLRecommendationDefinition'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'MLModel' AND __mj."IntegrationObjectField"."Name" = 'RecommendationDefinitionId')
      )
  );

-- Target: MobileSecurityAssignment.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'MobileSecurityAssignment'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'MobileSecurityAssignment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'MobileSecurityAssignment'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'MobileSecurityPolicy' AND __mj."IntegrationObjectField"."Name" = 'MobileSecurityAssignmentId')
        OR (o."Name" = 'MobSecurityCertPinConfig' AND __mj."IntegrationObjectField"."Name" = 'MobileSecurityAssignmentId')
      )
  );

-- Target: NamedCredential.Id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'NamedCredential'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'NamedCredential'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'NamedCredential'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ExternalClientApplication' AND __mj."IntegrationObjectField"."Name" = 'NamedCredentialId')
        OR (o."Name" = 'ExternalDataSource' AND __mj."IntegrationObjectField"."Name" = 'NamedCredentialId')
        OR (o."Name" = 'ExtKnowledgeConnector' AND __mj."IntegrationObjectField"."Name" = 'NamedCredentialId')
        OR (o."Name" = 'ExtlRecShrCnct' AND __mj."IntegrationObjectField"."Name" = 'NamedCredentialId')
        OR (o."Name" = 'PaymentGateway' AND __mj."IntegrationObjectField"."Name" = 'MerchantCredentialId')
        OR (o."Name" = 'TaxEngine' AND __mj."IntegrationObjectField"."Name" = 'MerchantCredentialId')
        OR (o."Name" = 'UserProvisioningConfig' AND __mj."IntegrationObjectField"."Name" = 'NamedCredentialId')
      )
  );

-- Target: Network.Id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Network'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Network'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Network'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'BroadcastTopicNetwork' AND __mj."IntegrationObjectField"."Name" = 'NetworkId')
        OR (o."Name" = 'EnablementProgram' AND __mj."IntegrationObjectField"."Name" = 'NetworkId')
        OR (o."Name" = 'NetworkAuthApiSettings' AND __mj."IntegrationObjectField"."Name" = 'NetworkId')
        OR (o."Name" = 'NetworkDataCategory' AND __mj."IntegrationObjectField"."Name" = 'NetworkId')
        OR (o."Name" = 'NetworkEmailTmplAllowlist' AND __mj."IntegrationObjectField"."Name" = 'NetworkId')
        OR (o."Name" = 'RecommendationResponse' AND __mj."IntegrationObjectField"."Name" = 'NetworkId')
        OR (o."Name" = 'WebStoreNetwork' AND __mj."IntegrationObjectField"."Name" = 'NetworkId')
      )
  );

-- Target: OauthCustomScope.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OauthCustomScope'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OauthCustomScope'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'OauthCustomScope'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'OauthCustomScopeApp' AND __mj."IntegrationObjectField"."Name" = 'OauthCustomScopeId')
      )
  );

-- Target: OauthTokenExchangeHandler.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OauthTokenExchangeHandler'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OauthTokenExchangeHandler'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'OauthTokenExchangeHandler'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'OauthTokenExchHandlerApp' AND __mj."IntegrationObjectField"."Name" = 'OauthTokenExchangeHandlerId')
      )
  );

-- Target: ObjectDataImport.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ObjectDataImport'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ObjectDataImport'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ObjectDataImport'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ObjectDataImportReference' AND __mj."IntegrationObjectField"."Name" = 'ObjectDataImportId')
      )
  );

-- Target: OmniSupervisorConfig.Id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OmniSupervisorConfig'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OmniSupervisorConfig'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'OmniSupervisorConfig'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'OmniSupervisorConfigAction' AND __mj."IntegrationObjectField"."Name" = 'OmniSupervisorConfigId')
        OR (o."Name" = 'OmniSupervisorConfigGroup' AND __mj."IntegrationObjectField"."Name" = 'OmniSupervisorConfigId')
        OR (o."Name" = 'OmniSupervisorConfigProfile' AND __mj."IntegrationObjectField"."Name" = 'OmniSupervisorConfigId')
        OR (o."Name" = 'OmniSupervisorConfigQueue' AND __mj."IntegrationObjectField"."Name" = 'OmniSupervisorConfigId')
        OR (o."Name" = 'OmniSupervisorConfigSkill' AND __mj."IntegrationObjectField"."Name" = 'OmniSupervisorConfigId')
        OR (o."Name" = 'OmniSupervisorConfigTab' AND __mj."IntegrationObjectField"."Name" = 'OmniSupervisorConfigId')
        OR (o."Name" = 'OmniSupervisorConfigUser' AND __mj."IntegrationObjectField"."Name" = 'OmniSupervisorConfigId')
      )
  );

-- Target: OperatingHours.Id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OperatingHours'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OperatingHours'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'OperatingHours'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'Account' AND __mj."IntegrationObjectField"."Name" = 'OperatingHoursId')
        OR (o."Name" = 'AppointmentTopicTimeSlot' AND __mj."IntegrationObjectField"."Name" = 'OperatingHoursId')
        OR (o."Name" = 'OperatingHoursHoliday' AND __mj."IntegrationObjectField"."Name" = 'OperatingHoursId')
        OR (o."Name" = 'ServiceResourcePreference' AND __mj."IntegrationObjectField"."Name" = 'OperatingHoursId')
        OR (o."Name" = 'ServiceTerritory' AND __mj."IntegrationObjectField"."Name" = 'OperatingHoursId')
        OR (o."Name" = 'ServiceTerritoryMember' AND __mj."IntegrationObjectField"."Name" = 'OperatingHoursId')
        OR (o."Name" = 'TimeSlot' AND __mj."IntegrationObjectField"."Name" = 'OperatingHoursId')
      )
  );

-- Target: Opportunity.Id (19 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Opportunity'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Opportunity'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Opportunity'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AccountPartner' AND __mj."IntegrationObjectField"."Name" = 'OpportunityId')
        OR (o."Name" = 'DealIndirectPartner' AND __mj."IntegrationObjectField"."Name" = 'OpportunityId')
        OR (o."Name" = 'FieldChangeSnapshot' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
        OR (o."Name" = 'ForecastingSrcRecJudgment' AND __mj."IntegrationObjectField"."Name" = 'ReferenceObjectId')
        OR (o."Name" = 'Lead' AND __mj."IntegrationObjectField"."Name" = 'ConvertedOpportunityId')
        OR (o."Name" = 'OpportunityCompetitor' AND __mj."IntegrationObjectField"."Name" = 'OpportunityId')
        OR (o."Name" = 'OpportunityContactRole' AND __mj."IntegrationObjectField"."Name" = 'OpportunityId')
        OR (o."Name" = 'OpportunityFieldHistory' AND __mj."IntegrationObjectField"."Name" = 'OpportunityId')
        OR (o."Name" = 'OpportunityHistory' AND __mj."IntegrationObjectField"."Name" = 'OpportunityId')
        OR (o."Name" = 'OpportunityLineItem' AND __mj."IntegrationObjectField"."Name" = 'OpportunityId')
        OR (o."Name" = 'OpportunityPartner' AND __mj."IntegrationObjectField"."Name" = 'OpportunityId')
        OR (o."Name" = 'OpportunityRelatedDeleteLog' AND __mj."IntegrationObjectField"."Name" = 'OpportunityId')
        OR (o."Name" = 'OpportunityShare' AND __mj."IntegrationObjectField"."Name" = 'OpportunityId')
        OR (o."Name" = 'OpportunitySplit' AND __mj."IntegrationObjectField"."Name" = 'OpportunityId')
        OR (o."Name" = 'Partner' AND __mj."IntegrationObjectField"."Name" = 'OpportunityId')
        OR (o."Name" = 'PaymentInitiationSource' AND __mj."IntegrationObjectField"."Name" = 'OpportunityId')
        OR (o."Name" = 'Prospect' AND __mj."IntegrationObjectField"."Name" = 'ConvertedOpportunityId')
        OR (o."Name" = 'RecentFieldChange' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
        OR (o."Name" = 'SfdcPartnerOffer' AND __mj."IntegrationObjectField"."Name" = 'OpportunityId')
      )
  );

-- Target: OpportunityLineItem.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OpportunityLineItem'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OpportunityLineItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'OpportunityLineItem'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'OpportunityLineItemSplit' AND __mj."IntegrationObjectField"."Name" = 'OpportunityLineItemId')
      )
  );

-- Target: OpportunitySplitType.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OpportunitySplitType'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OpportunitySplitType'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'OpportunitySplitType'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ForecastingType' AND __mj."IntegrationObjectField"."Name" = 'OpportunitySplitTypeId')
        OR (o."Name" = 'OpportunitySplit' AND __mj."IntegrationObjectField"."Name" = 'SplitTypeId')
        OR (o."Name" = 'OpptyLineItemSplitType' AND __mj."IntegrationObjectField"."Name" = 'OpportunitySplitTypeId')
      )
  );

-- Target: OpptyLineItemSplitType.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OpptyLineItemSplitType'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OpptyLineItemSplitType'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'OpptyLineItemSplitType'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ForecastingType' AND __mj."IntegrationObjectField"."Name" = 'OpptyLineItemSplitTypeId')
        OR (o."Name" = 'OpportunityLineItemSplit' AND __mj."IntegrationObjectField"."Name" = 'SplitTypeId')
      )
  );

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Order'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Order'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Order'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'BillingSchedule' AND __mj."IntegrationObjectField"."Name" = 'ReferenceEntityId')
        OR (o."Name" = 'FulfillmentOrder' AND __mj."IntegrationObjectField"."Name" = 'OrderId')
        OR (o."Name" = 'OrderAction' AND __mj."IntegrationObjectField"."Name" = 'OrderId')
        OR (o."Name" = 'OrderAdjustmentGroup' AND __mj."IntegrationObjectField"."Name" = 'OrderId')
        OR (o."Name" = 'OrderChangeLog' AND __mj."IntegrationObjectField"."Name" = 'ChangeOrderId')
        OR (o."Name" = 'OrderHistory' AND __mj."IntegrationObjectField"."Name" = 'OrderId')
        OR (o."Name" = 'OrderItem' AND __mj."IntegrationObjectField"."Name" = 'OrderId')
        OR (o."Name" = 'OrderItemRelationship' AND __mj."IntegrationObjectField"."Name" = 'OrderId')
        OR (o."Name" = 'OrderShare' AND __mj."IntegrationObjectField"."Name" = 'OrderId')
        OR (o."Name" = 'OrderSummary' AND __mj."IntegrationObjectField"."Name" = 'OriginalOrderId')
        OR (o."Name" = 'OrderSummaryAdditionalInfo' AND __mj."IntegrationObjectField"."Name" = 'OrderId')
        OR (o."Name" = 'OSAsyncChgCompletedEvent' AND __mj."IntegrationObjectField"."Name" IN ('FeeChangeOrderId', 'InFulfillmentChangeOrderId', 'PostFulfillmentChangeOrderId', 'PreFulfillmentChangeOrderId'))
        OR (o."Name" = 'PaymentGroup' AND __mj."IntegrationObjectField"."Name" = 'SourceObjectId')
        OR (o."Name" = 'ReturnOrder' AND __mj."IntegrationObjectField"."Name" = 'OrderId')
        OR (o."Name" = 'WorkOrderLineItem' AND __mj."IntegrationObjectField"."Name" = 'OrderId')
      )
  );

-- Target: OrderDeliveryGroup.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OrderDeliveryGroup'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OrderDeliveryGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'OrderDeliveryGroup'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'OrderItem' AND __mj."IntegrationObjectField"."Name" = 'OrderDeliveryGroupId')
      )
  );

-- Target: OrderDeliveryGroupSummary.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OrderDeliveryGroupSummary'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OrderDeliveryGroupSummary'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'OrderDeliveryGroupSummary'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'OrderItemSummary' AND __mj."IntegrationObjectField"."Name" = 'SummaryId')
      )
  );

-- Target: OrderDeliveryMethod.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OrderDeliveryMethod'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OrderDeliveryMethod'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'OrderDeliveryMethod'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CartDeliveryGroup' AND __mj."IntegrationObjectField"."Name" = 'DeliveryMethodId')
        OR (o."Name" = 'FulfillmentOrder' AND __mj."IntegrationObjectField"."Name" = 'DeliveryMethodId')
      )
  );

-- Target: OrderItem.Id (10 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OrderItem'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OrderItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'OrderItem'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'FulfillmentOrderLineItem' AND __mj."IntegrationObjectField"."Name" = 'OrderItemId')
        OR (o."Name" = 'OrderAction' AND __mj."IntegrationObjectField"."Name" = 'OffsetOrderItemId')
        OR (o."Name" = 'OrderItemRelationship' AND __mj."IntegrationObjectField"."Name" IN ('AssociatedOrderItemId', 'MainOrderItemId', 'RootOrderItemId'))
        OR (o."Name" = 'OrderItemSummary' AND __mj."IntegrationObjectField"."Name" = 'OriginalOrderItemId')
        OR (o."Name" = 'QuoteLineItem' AND __mj."IntegrationObjectField"."Name" = 'RelatedQuoteLineItemId')
        OR (o."Name" = 'QuoteLineWorkSource' AND __mj."IntegrationObjectField"."Name" = 'OrderItemId')
        OR (o."Name" = 'ReturnOrderLineItem' AND __mj."IntegrationObjectField"."Name" IN ('ChangeOrderItemId', 'OrderItemId'))
      )
  );

-- Target: OrderItemRelationship.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OrderItemRelationship'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OrderItemRelationship'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'OrderItemRelationship'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'OrderItemSummaryRelationship' AND __mj."IntegrationObjectField"."Name" = 'OrderItemRelationshipId')
      )
  );

-- Target: OrderItemSummary.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OrderItemSummary'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OrderItemSummary'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'OrderItemSummary'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'FulfillmentOrderLineItem' AND __mj."IntegrationObjectField"."Name" = 'OrderItemSummaryId')
        OR (o."Name" = 'OrderItemSummaryRelationship' AND __mj."IntegrationObjectField"."Name" = 'AssociatedOrderItemSummaryId')
      )
  );

-- Target: OrderPaymentSummary.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OrderPaymentSummary'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OrderPaymentSummary'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'OrderPaymentSummary'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'OrderPaymentSummaryReference' AND __mj."IntegrationObjectField"."Name" = 'OrderPaymentSummaryId')
        OR (o."Name" = 'PaymentCredit' AND __mj."IntegrationObjectField"."Name" = 'OrderPaymentSummaryId')
      )
  );

-- Target: OrderSummary.Id (11 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OrderSummary'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OrderSummary'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'OrderSummary'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'FulfillmentOrder' AND __mj."IntegrationObjectField"."Name" = 'OrderSummaryId')
        OR (o."Name" = 'OrderItemSummary' AND __mj."IntegrationObjectField"."Name" = 'OrderSummaryId')
        OR (o."Name" = 'OrderItemSummaryRelationship' AND __mj."IntegrationObjectField"."Name" = 'MainOrderSummaryId')
        OR (o."Name" = 'OrderPaymentSummaryReference' AND __mj."IntegrationObjectField"."Name" = 'OrderSummaryId')
        OR (o."Name" = 'OrderSummaryAdditionalInfo' AND __mj."IntegrationObjectField"."Name" = 'OrderSummaryId')
        OR (o."Name" = 'OrderSummaryRelationship' AND __mj."IntegrationObjectField"."Name" IN ('AssociatedOrderSummaryId', 'MainOrderSummaryId', 'RootOrderSummaryId'))
        OR (o."Name" = 'OSAsyncChgCompletedEvent' AND __mj."IntegrationObjectField"."Name" = 'OrderSummaryId')
        OR (o."Name" = 'PaymentInitiationSource' AND __mj."IntegrationObjectField"."Name" = 'OrderSummaryId')
        OR (o."Name" = 'ProcessException' AND __mj."IntegrationObjectField"."Name" = 'OrderSummaryId')
      )
  );

-- Target: Organization.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Organization'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Organization'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Organization'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'Stamp' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
      )
  );

-- Target: OrgWideEmailAddress.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OrgWideEmailAddress'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'OrgWideEmailAddress'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'OrgWideEmailAddress'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'OrgEmailAddressSecurity' AND __mj."IntegrationObjectField"."Name" = 'OrgWideEmailAddressId')
      )
  );

-- Target: PackageLicense.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PackageLicense'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PackageLicense'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PackageLicense'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'UserPackageLicense' AND __mj."IntegrationObjectField"."Name" = 'PackageLicenseId')
      )
  );

-- Target: Payment.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Payment'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Payment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Payment'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PaymentCredit' AND __mj."IntegrationObjectField"."Name" = 'PaymentId')
        OR (o."Name" = 'PaymentLineInvoice' AND __mj."IntegrationObjectField"."Name" = 'PaymentId')
        OR (o."Name" = 'PaymentScheduleItem' AND __mj."IntegrationObjectField"."Name" = 'PaymentId')
        OR (o."Name" = 'Refund' AND __mj."IntegrationObjectField"."Name" = 'PaymentID')
        OR (o."Name" = 'RefundLinePayment' AND __mj."IntegrationObjectField"."Name" = 'PaymentId')
      )
  );

-- Target: PaymentAuthorization.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentAuthorization'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentAuthorization'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PaymentAuthorization'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'Payment' AND __mj."IntegrationObjectField"."Name" = 'PaymentAuthorizationId')
        OR (o."Name" = 'PaymentAuthAdjustment' AND __mj."IntegrationObjectField"."Name" = 'PaymentAuthorizationId')
      )
  );

-- Target: PaymentCredit.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentCredit'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentCredit'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PaymentCredit'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PaymentCreditLinePayment' AND __mj."IntegrationObjectField"."Name" = 'PaymentCreditId')
      )
  );

-- Target: PaymentGateway.Id (9 field(s))

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
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
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
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AlternativePaymentMethod' AND __mj."IntegrationObjectField"."Name" = 'PaymentGatewayId')
        OR (o."Name" = 'CardPaymentMethod' AND __mj."IntegrationObjectField"."Name" = 'PaymentGatewayId')
        OR (o."Name" = 'DigitalWallet' AND __mj."IntegrationObjectField"."Name" = 'PaymentGatewayId')
        OR (o."Name" = 'Payment' AND __mj."IntegrationObjectField"."Name" = 'PaymentGatewayId')
        OR (o."Name" = 'PaymentAuthorization' AND __mj."IntegrationObjectField"."Name" = 'PaymentGatewayId')
        OR (o."Name" = 'PaymentGatewayLog' AND __mj."IntegrationObjectField"."Name" = 'PaymentGatewayId')
        OR (o."Name" = 'PaymentIntent' AND __mj."IntegrationObjectField"."Name" = 'PaymentGatewayId')
        OR (o."Name" = 'Refund' AND __mj."IntegrationObjectField"."Name" = 'PaymentGatewayId')
        OR (o."Name" = 'SavedPaymentMethod' AND __mj."IntegrationObjectField"."Name" = 'PaymentGatewayId')
      )
  );

-- Target: PaymentGatewayLog.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentGatewayLog'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentGatewayLog'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PaymentGatewayLog'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PaymentScheduleItem' AND __mj."IntegrationObjectField"."Name" = 'LastPaymentGatewayLogId')
      )
  );

-- Target: PaymentGatewayProvider.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentGatewayProvider'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentGatewayProvider'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PaymentGatewayProvider'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'GtwyProvPaymentMethodType' AND __mj."IntegrationObjectField"."Name" = 'PaymentGatewayProviderId')
        OR (o."Name" = 'PaymentGateway' AND __mj."IntegrationObjectField"."Name" = 'PaymentGatewayProviderId')
      )
  );

-- Target: PaymentGroup.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentGroup'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PaymentGroup'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'Payment' AND __mj."IntegrationObjectField"."Name" = 'PaymentGroupId')
        OR (o."Name" = 'PaymentAuthorization' AND __mj."IntegrationObjectField"."Name" = 'PaymentGroupId')
        OR (o."Name" = 'PaymentIntent' AND __mj."IntegrationObjectField"."Name" = 'PaymentGroupId')
        OR (o."Name" = 'Refund' AND __mj."IntegrationObjectField"."Name" = 'PaymentGroupId')
        OR (o."Name" = 'WebCart' AND __mj."IntegrationObjectField"."Name" = 'PaymentGroupId')
      )
  );

-- Target: PaymentInitiationSource.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentInitiationSource'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentInitiationSource'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PaymentInitiationSource'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PaymentIntentEvent' AND __mj."IntegrationObjectField"."Name" = 'PaymentInitiationSource')
      )
  );

-- Target: PaymentIntent.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentIntent'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentIntent'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PaymentIntent'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PaymentAuthAdjustment' AND __mj."IntegrationObjectField"."Name" = 'PaymentIntentId')
        OR (o."Name" = 'PaymentIntentEvent' AND __mj."IntegrationObjectField"."Name" = 'PaymentIntent')
        OR (o."Name" = 'Refund' AND __mj."IntegrationObjectField"."Name" = 'PaymentIntentID')
      )
  );

-- Target: PaymentLink.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentLink'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentLink'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PaymentLink'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PaymentIntent' AND __mj."IntegrationObjectField"."Name" = 'PaymentLinkId')
        OR (o."Name" = 'PaymentIntentEvent' AND __mj."IntegrationObjectField"."Name" = 'PaymentLink')
        OR (o."Name" = 'PaymentLinkEvent' AND __mj."IntegrationObjectField"."Name" = 'PaymentLinkId')
      )
  );

-- Target: PaymentMethod.Id (4 field(s))

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
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
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
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'Payment' AND __mj."IntegrationObjectField"."Name" = 'PaymentMethodId')
        OR (o."Name" = 'PaymentAuthorization' AND __mj."IntegrationObjectField"."Name" = 'PaymentMethodId')
        OR (o."Name" = 'PaymentIntent' AND __mj."IntegrationObjectField"."Name" = 'PaymentMethodId')
        OR (o."Name" = 'Refund' AND __mj."IntegrationObjectField"."Name" = 'PaymentMethodId')
      )
  );

-- Target: PaymentSchedule.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentSchedule'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentSchedule'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PaymentSchedule'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PaymentScheduleItem' AND __mj."IntegrationObjectField"."Name" = 'PaymentScheduleId')
      )
  );

-- Target: PaymentScheduleItem.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentScheduleItem'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentScheduleItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PaymentScheduleItem'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PaymentLink' AND __mj."IntegrationObjectField"."Name" = 'PaymentScheduleItemId')
      )
  );

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentSchedulePolicy'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentSchedulePolicy'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PaymentSchedulePolicy'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PaymentScheduleTreatment' AND __mj."IntegrationObjectField"."Name" = 'PaymentSchedulePolicyId')
      )
  );

-- Target: PaymentScheduleTreatment.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentScheduleTreatment'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentScheduleTreatment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PaymentScheduleTreatment'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PaymentScheduleTreatmentDtl' AND __mj."IntegrationObjectField"."Name" = 'PaymentScheduleTreatmentId')
      )
  );

-- Target: PaymentScheduleTreatmentDtl.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentScheduleTreatmentDtl'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentScheduleTreatmentDtl'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PaymentScheduleTreatmentDtl'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PaymentSchedule' AND __mj."IntegrationObjectField"."Name" = 'PaymentScheduleTreatmentDtlId')
      )
  );

-- Target: PaymentTerm.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentTerm'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PaymentTerm'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PaymentTerm'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'BillingScheduleGroup' AND __mj."IntegrationObjectField"."Name" = 'PaymentTermId')
        OR (o."Name" = 'Invoice' AND __mj."IntegrationObjectField"."Name" = 'PaymentTermId')
        OR (o."Name" = 'Order' AND __mj."IntegrationObjectField"."Name" = 'PaymentTermId')
        OR (o."Name" = 'PaymentTermItem' AND __mj."IntegrationObjectField"."Name" = 'PaymentTermId')
      )
  );

-- Target: PendingServiceRouting.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PendingServiceRouting'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PendingServiceRouting'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PendingServiceRouting'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AgentWork' AND __mj."IntegrationObjectField"."Name" = 'PendingServiceRoutingId')
        OR (o."Name" = 'PendingServiceRoutingInteractionInfo' AND __mj."IntegrationObjectField"."Name" = 'PendingServiceRoutingId')
      )
  );

-- Target: Period.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Period'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Period'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Period'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ForecastingCustomData' AND __mj."IntegrationObjectField"."Name" = 'PeriodId')
        OR (o."Name" = 'ForecastingSubmission' AND __mj."IntegrationObjectField"."Name" = 'PeriodId')
        OR (o."Name" = 'FrcstCustmzAdjustment' AND __mj."IntegrationObjectField"."Name" = 'PeriodId')
        OR (o."Name" = 'FrcstCustmzOwnerAdjustment' AND __mj."IntegrationObjectField"."Name" = 'PeriodId')
      )
  );

-- Target: PermissionSet.Id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PermissionSet'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PermissionSet'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PermissionSet'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'FieldPermissions' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
        OR (o."Name" = 'ObjectPermissions' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
        OR (o."Name" = 'PermissionSetAssignment' AND __mj."IntegrationObjectField"."Name" = 'PermissionSetId')
        OR (o."Name" = 'PermissionSetGroupComponent' AND __mj."IntegrationObjectField"."Name" = 'PermissionSetId')
        OR (o."Name" = 'PermissionSetTabSetting' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
        OR (o."Name" = 'SessionPermSetActivation' AND __mj."IntegrationObjectField"."Name" = 'PermissionSetId')
        OR (o."Name" = 'SetupEntityAccess' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
      )
  );

-- Target: PermissionSetGroup.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PermissionSetGroup'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PermissionSetGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PermissionSetGroup'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'NetworkSelfRegistration' AND __mj."IntegrationObjectField"."Name" = 'PermissionSetGroupId')
        OR (o."Name" = 'PermissionSet' AND __mj."IntegrationObjectField"."Name" = 'PermissionSetGroupId')
        OR (o."Name" = 'PermissionSetAssignment' AND __mj."IntegrationObjectField"."Name" = 'PermissionSetGroupId')
        OR (o."Name" = 'PermissionSetGroupComponent' AND __mj."IntegrationObjectField"."Name" = 'PermissionSetGroupId')
        OR (o."Name" = 'SessionPermSetActivation' AND __mj."IntegrationObjectField"."Name" = 'PermissionSetGroupId')
      )
  );

-- Target: PermissionSetLicense.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PermissionSetLicense'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PermissionSetLicense'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PermissionSetLicense'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ActivePermSetLicenseMetric' AND __mj."IntegrationObjectField"."Name" = 'PermissionSetLicenseId')
        OR (o."Name" = 'PermissionSetLicenseAssign' AND __mj."IntegrationObjectField"."Name" = 'PermissionSetLicenseId')
      )
  );

-- Target: PersonalizationSchema.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PersonalizationSchema'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PersonalizationSchema'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PersonalizationSchema'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AbnExperiment' AND __mj."IntegrationObjectField"."Name" = 'PersonalizationSchemaId')
        OR (o."Name" = 'PersonalizationPoint' AND __mj."IntegrationObjectField"."Name" = 'PersonalizationSchemaId')
      )
  );

-- Target: PickTicket.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PickTicket'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PickTicket'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PickTicket'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PickTicketAssignment' AND __mj."IntegrationObjectField"."Name" = 'PickTicketId')
        OR (o."Name" = 'PickTicketProduct' AND __mj."IntegrationObjectField"."Name" = 'PickTicketId')
      )
  );

-- Target: PipelineInspectionListView.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PipelineInspectionListView'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PipelineInspectionListView'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PipelineInspectionListView'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PplnInspListViewCalcClmn' AND __mj."IntegrationObjectField"."Name" = 'PipelineInspectionListViewId')
      )
  );

-- Target: PipelineInspMetricConfig.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PipelineInspMetricConfig'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PipelineInspMetricConfig'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PipelineInspMetricConfig'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PipelineInspMetricConfigLocalization' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
      )
  );

-- Target: PriceAdjustmentGroupShape.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PriceAdjustmentGroupShape'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PriceAdjustmentGroupShape'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PriceAdjustmentGroupShape'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PriceAdjustmentItemShape' AND __mj."IntegrationObjectField"."Name" = 'PriceAdjustmentGroupShapeId')
      )
  );

-- Target: PriceAdjustmentTier.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PriceAdjustmentTier'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PriceAdjustmentTier'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PriceAdjustmentTier'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PriceAdjustmentGroupShape' AND __mj."IntegrationObjectField"."Name" = 'PriceAdjustmentCauseId')
        OR (o."Name" = 'PriceAdjustmentItemShape' AND __mj."IntegrationObjectField"."Name" = 'PriceAdjustmentCauseId')
        OR (o."Name" = 'QuoteLinePriceAdjustment' AND __mj."IntegrationObjectField"."Name" = 'PriceAdjustmentCauseId')
      )
  );

-- Target: Pricebook2.Id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Pricebook2'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Pricebook2'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Pricebook2'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'Opportunity' AND __mj."IntegrationObjectField"."Name" = 'Pricebook2Id')
        OR (o."Name" = 'Order' AND __mj."IntegrationObjectField"."Name" = 'Pricebook2Id')
        OR (o."Name" = 'OrderSummary' AND __mj."IntegrationObjectField"."Name" = 'Pricebook2Id')
        OR (o."Name" = 'Pricebook2History' AND __mj."IntegrationObjectField"."Name" = 'Pricebook2Id')
        OR (o."Name" = 'PricebookEntry' AND __mj."IntegrationObjectField"."Name" = 'Pricebook2Id')
        OR (o."Name" = 'WebStore' AND __mj."IntegrationObjectField"."Name" = 'SortByPriceBookId')
        OR (o."Name" = 'WorkOrder' AND __mj."IntegrationObjectField"."Name" = 'Pricebook2Id')
      )
  );

-- Target: PricebookEntry.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PricebookEntry'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PricebookEntry'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PricebookEntry'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CartItem' AND __mj."IntegrationObjectField"."Name" = 'PriceBookEntryId')
        OR (o."Name" = 'OpportunityLineItem' AND __mj."IntegrationObjectField"."Name" = 'PricebookEntryId')
        OR (o."Name" = 'OrderItem' AND __mj."IntegrationObjectField"."Name" = 'PricebookEntryId')
        OR (o."Name" = 'OrderItemSummary' AND __mj."IntegrationObjectField"."Name" = 'PricebookEntryId')
        OR (o."Name" = 'WorkOrderLineItem' AND __mj."IntegrationObjectField"."Name" = 'PricebookEntryId')
      )
  );

-- Target: PriceProtectionTerm.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PriceProtectionTerm'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PriceProtectionTerm'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PriceProtectionTerm'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PriceProtectExecLineItem' AND __mj."IntegrationObjectField"."Name" = 'PriceProtectionTermId')
      )
  );

-- Target: PrivacyHoldReason.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PrivacyHoldReason'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PrivacyHoldReason'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PrivacyHoldReason'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PrivacyHold' AND __mj."IntegrationObjectField"."Name" = 'PrivacyHoldReasonId')
      )
  );

-- Target: PrivacyJobSession.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PrivacyJobSession'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PrivacyJobSession'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PrivacyJobSession'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PrivacyObjectSession' AND __mj."IntegrationObjectField"."Name" = 'PrivacyJobSessionObjectId')
      )
  );

-- Target: PrivacyObjectSession.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PrivacyObjectSession'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PrivacyObjectSession'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PrivacyObjectSession'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PrivacySessionRecordFailure' AND __mj."IntegrationObjectField"."Name" = 'PrivacyObjectSessionId')
      )
  );

-- Target: PrivacyRTBFRequest.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PrivacyRTBFRequest'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PrivacyRTBFRequest'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PrivacyRTBFRequest'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PrivacyJobSession' AND __mj."IntegrationObjectField"."Name" = 'PrivacyRtbfRequestId')
      )
  );

-- Target: Problem.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Problem'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Problem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Problem'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ProblemRelatedItem' AND __mj."IntegrationObjectField"."Name" = 'ProblemId')
      )
  );

-- Target: ProcessDefinition.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProcessDefinition'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProcessDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ProcessDefinition'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ProcessInstance' AND __mj."IntegrationObjectField"."Name" = 'ProcessDefinitionId')
        OR (o."Name" = 'ProcessNode' AND __mj."IntegrationObjectField"."Name" = 'ProcessDefinitionId')
      )
  );

-- Target: ProcessInstance.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProcessInstance'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProcessInstance'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ProcessInstance'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ProcessInstanceHistory' AND __mj."IntegrationObjectField"."Name" = 'ProcessInstanceId')
        OR (o."Name" = 'ProcessInstanceNode' AND __mj."IntegrationObjectField"."Name" = 'ProcessInstanceId')
        OR (o."Name" = 'ProcessInstanceStep' AND __mj."IntegrationObjectField"."Name" = 'ProcessInstanceId')
        OR (o."Name" = 'ProcessInstanceWorkitem' AND __mj."IntegrationObjectField"."Name" = 'ProcessInstanceId')
      )
  );

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProcessNode'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProcessNode'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ProcessNode'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ProcessInstanceHistory' AND __mj."IntegrationObjectField"."Name" = 'ProcessNodeId')
        OR (o."Name" = 'ProcessInstanceNode' AND __mj."IntegrationObjectField"."Name" = 'ProcessNodeId')
      )
  );

-- Target: Product2.Id (36 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Product2'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Product2'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Product2'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'Asset' AND __mj."IntegrationObjectField"."Name" = 'Product2Id')
        OR (o."Name" = 'BillingScheduleGroup' AND __mj."IntegrationObjectField"."Name" = 'Product2Id')
        OR (o."Name" = 'CartItem' AND __mj."IntegrationObjectField"."Name" = 'Product2Id')
        OR (o."Name" = 'CommissionScheduleAssignment' AND __mj."IntegrationObjectField"."Name" = 'Product2Id')
        OR (o."Name" = 'CreditMemoLine' AND __mj."IntegrationObjectField"."Name" = 'Product2Id')
        OR (o."Name" = 'FulfillmentOrderLineItem' AND __mj."IntegrationObjectField"."Name" = 'Product2Id')
        OR (o."Name" = 'IncidentRelatedItem' AND __mj."IntegrationObjectField"."Name" = 'Product2Id')
        OR (o."Name" = 'InventoryItemReservation' AND __mj."IntegrationObjectField"."Name" = 'ProductId')
        OR (o."Name" = 'InvoiceLine' AND __mj."IntegrationObjectField"."Name" = 'Product2Id')
        OR (o."Name" = 'OpportunityLineItem' AND __mj."IntegrationObjectField"."Name" = 'ProductId')
        OR (o."Name" = 'OrderItem' AND __mj."IntegrationObjectField"."Name" = 'Product2Id')
        OR (o."Name" = 'OrderItemSummary' AND __mj."IntegrationObjectField"."Name" = 'Product2Id')
        OR (o."Name" = 'PickTicketProduct' AND __mj."IntegrationObjectField"."Name" = 'Product2Id')
        OR (o."Name" = 'PricebookEntry' AND __mj."IntegrationObjectField"."Name" = 'Product2Id')
        OR (o."Name" = 'PriceProtectExecLineItem' AND __mj."IntegrationObjectField"."Name" = 'ProductId')
        OR (o."Name" = 'ProductComponentGroup' AND __mj."IntegrationObjectField"."Name" = 'ParentProductId')
        OR (o."Name" = 'ProductDetectedPriceChange' AND __mj."IntegrationObjectField"."Name" = 'ProductId')
        OR (o."Name" = 'ProductFeaturedProduct' AND __mj."IntegrationObjectField"."Name" IN ('FeaturedProductId', 'ProductId'))
        OR (o."Name" = 'ProductItem' AND __mj."IntegrationObjectField"."Name" = 'Product2Id')
        OR (o."Name" = 'ProductMedia' AND __mj."IntegrationObjectField"."Name" = 'ProductId')
        OR (o."Name" = 'ProductQuantityRule' AND __mj."IntegrationObjectField"."Name" = 'ProductId')
        OR (o."Name" = 'ProductRelatedComponent' AND __mj."IntegrationObjectField"."Name" IN ('ChildProductId', 'ParentProductId'))
        OR (o."Name" = 'ProductRequestLineItem' AND __mj."IntegrationObjectField"."Name" = 'Product2Id')
        OR (o."Name" = 'ProductRequired' AND __mj."IntegrationObjectField"."Name" = 'Product2Id')
        OR (o."Name" = 'ProductSellingModelOption' AND __mj."IntegrationObjectField"."Name" = 'Product2Id')
        OR (o."Name" = 'ProductTransfer' AND __mj."IntegrationObjectField"."Name" = 'Product2Id')
        OR (o."Name" = 'ProgramProduct' AND __mj."IntegrationObjectField"."Name" = 'ProductId')
        OR (o."Name" = 'ReturnOrderLineItem' AND __mj."IntegrationObjectField"."Name" = 'Product2Id')
        OR (o."Name" = 'SalesTransactionItemShape' AND __mj."IntegrationObjectField"."Name" = 'ProductId')
        OR (o."Name" = 'ShipmentItem' AND __mj."IntegrationObjectField"."Name" = 'Product2Id')
        OR (o."Name" = 'ShippingConfigSetProduct' AND __mj."IntegrationObjectField"."Name" = 'Product2Id')
        OR (o."Name" = 'UsageImpactGroupPgmMeasure' AND __mj."IntegrationObjectField"."Name" = 'Product2Id')
        OR (o."Name" = 'WebStoreSearchProdSettings' AND __mj."IntegrationObjectField"."Name" = 'ProductId')
        OR (o."Name" = 'WorkOrderLineItem' AND __mj."IntegrationObjectField"."Name" = 'Product2Id')
      )
  );

-- Target: ProductCategory.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProductCategory'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProductCategory'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ProductCategory'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CryptoProdCatgWalletGroup' AND __mj."IntegrationObjectField"."Name" = 'ProductCategoryId')
      )
  );

-- Target: ProductComponentGroup.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProductComponentGroup'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProductComponentGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ProductComponentGroup'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ProductRelatedComponent' AND __mj."IntegrationObjectField"."Name" = 'ProductComponentGroupId')
      )
  );

-- Target: ProductItem.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProductItem'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProductItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ProductItem'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ProductItemTransaction' AND __mj."IntegrationObjectField"."Name" = 'ProductItemId')
        OR (o."Name" = 'ProductTransfer' AND __mj."IntegrationObjectField"."Name" = 'SourceProductItemId')
        OR (o."Name" = 'ReturnOrderLineItem' AND __mj."IntegrationObjectField"."Name" = 'ProductItemId')
      )
  );

-- Target: ProductRelatedComponent.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProductRelatedComponent'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProductRelatedComponent'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ProductRelatedComponent'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AssetRelationship' AND __mj."IntegrationObjectField"."Name" = 'ProductRelatedComponent')
        OR (o."Name" = 'CartItem' AND __mj."IntegrationObjectField"."Name" = 'ComponentId')
        OR (o."Name" = 'OrderItemSummaryRelationship' AND __mj."IntegrationObjectField"."Name" = 'ProductRelatedComponentId')
        OR (o."Name" = 'QuoteLineRelationship' AND __mj."IntegrationObjectField"."Name" = 'ProductRelatedComponentId')
      )
  );

-- Target: ProductRelationshipType.Id (6 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProductRelationshipType'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProductRelationshipType'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ProductRelationshipType'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AssetRelationship' AND __mj."IntegrationObjectField"."Name" = 'ProductRelationshipTypeId')
        OR (o."Name" = 'OrderItemRelationship' AND __mj."IntegrationObjectField"."Name" = 'ProductRelationshipTypeId')
        OR (o."Name" = 'OrderItemSummaryRelationship' AND __mj."IntegrationObjectField"."Name" = 'ProductRelationshipTypeId')
        OR (o."Name" = 'ProductRelatedComponent' AND __mj."IntegrationObjectField"."Name" = 'ProductRelationshipTypeId')
        OR (o."Name" = 'QuoteLineRelationship' AND __mj."IntegrationObjectField"."Name" = 'ProductRelationshipTypeId')
        OR (o."Name" = 'SalesTrxnItemRelationShape' AND __mj."IntegrationObjectField"."Name" = 'ProductRelationshipTypeId')
      )
  );

-- Target: ProductRequest.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProductRequest'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProductRequest'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ProductRequest'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ProductRequestLineItem' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
        OR (o."Name" = 'ProductTransfer' AND __mj."IntegrationObjectField"."Name" = 'ProductRequestId')
        OR (o."Name" = 'ReturnOrder' AND __mj."IntegrationObjectField"."Name" = 'ProductRequestId')
      )
  );

-- Target: ProductRequestLineItem.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProductRequestLineItem'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProductRequestLineItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ProductRequestLineItem'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ProductTransfer' AND __mj."IntegrationObjectField"."Name" = 'ProductRequestLineItemId')
        OR (o."Name" = 'ReturnOrderLineItem' AND __mj."IntegrationObjectField"."Name" = 'ProductRequestLineItemId')
      )
  );

-- Target: ProductSellingModel.Id (8 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProductSellingModel'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProductSellingModel'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ProductSellingModel'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CartItem' AND __mj."IntegrationObjectField"."Name" = 'ProductSellingModelId')
        OR (o."Name" = 'OrderItem' AND __mj."IntegrationObjectField"."Name" = 'ProductSellingModelId')
        OR (o."Name" = 'PricebookEntry' AND __mj."IntegrationObjectField"."Name" = 'ProductSellingModelId')
        OR (o."Name" = 'ProductRelatedComponent' AND __mj."IntegrationObjectField"."Name" IN ('ChildSellingModelId', 'ParentSellingModelId'))
        OR (o."Name" = 'ProductSellingModelOption' AND __mj."IntegrationObjectField"."Name" = 'ProductSellingModelId')
        OR (o."Name" = 'QuoteLineItem' AND __mj."IntegrationObjectField"."Name" = 'ProductSellingModelId')
        OR (o."Name" = 'SalesTransactionItemShape' AND __mj."IntegrationObjectField"."Name" = 'ProductSellingModelId')
      )
  );

-- Target: Profile.Id (9 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Profile'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Profile'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Profile'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ActiveProfileMetric' AND __mj."IntegrationObjectField"."Name" = 'ProfileId')
        OR (o."Name" = 'MobileSecurityAssignment' AND __mj."IntegrationObjectField"."Name" = 'ProfileId')
        OR (o."Name" = 'Name' AND __mj."IntegrationObjectField"."Name" = 'ProfileId')
        OR (o."Name" = 'NetworkAuthApiSettings' AND __mj."IntegrationObjectField"."Name" = 'RegistrationUserDefaultProfileId')
        OR (o."Name" = 'OmniSupervisorConfigProfile' AND __mj."IntegrationObjectField"."Name" = 'ProfileId')
        OR (o."Name" = 'OrgEmailAddressSecurity' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
        OR (o."Name" = 'RecentlyViewed' AND __mj."IntegrationObjectField"."Name" = 'ProfileId')
        OR (o."Name" = 'User' AND __mj."IntegrationObjectField"."Name" = 'ProfileId')
        OR (o."Name" = 'VisualforceAccessMetrics' AND __mj."IntegrationObjectField"."Name" = 'ProfileId')
      )
  );

-- Target: ProfileSkill.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProfileSkill'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProfileSkill'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ProfileSkill'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ProfileSkillShare' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
        OR (o."Name" = 'ProfileSkillUser' AND __mj."IntegrationObjectField"."Name" = 'ProfileSkillId')
      )
  );

-- Target: ProfileSkillUser.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProfileSkillUser'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProfileSkillUser'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ProfileSkillUser'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ProfileSkillEndorsement' AND __mj."IntegrationObjectField"."Name" = 'ProfileSkillUserId')
      )
  );

-- Target: ProgramRebateType.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProgramRebateType'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProgramRebateType'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ProgramRebateType'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PriceProtectExecLineItem' AND __mj."IntegrationObjectField"."Name" = 'CalculationReferenceRecordId')
        OR (o."Name" = 'PriceProtectionTerm' AND __mj."IntegrationObjectField"."Name" = 'CalculationReferenceRecordId')
      )
  );

-- Target: Promotion.Id (11 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Promotion'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Promotion'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Promotion'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CartDeliveryGroupMethodAdj' AND __mj."IntegrationObjectField"."Name" = 'PriceAdjustmentCauseId')
        OR (o."Name" = 'CartItemPriceAdjustment' AND __mj."IntegrationObjectField"."Name" = 'PriceAdjustmentCauseId')
        OR (o."Name" = 'Coupon' AND __mj."IntegrationObjectField"."Name" = 'PromotionId')
        OR (o."Name" = 'OrderAdjustmentGroupSummary' AND __mj."IntegrationObjectField"."Name" = 'AdjustmentCauseId')
        OR (o."Name" = 'OrderItemAdjustmentLineItem' AND __mj."IntegrationObjectField"."Name" = 'AdjustmentCauseId')
        OR (o."Name" = 'OrderItemAdjustmentLineSummary' AND __mj."IntegrationObjectField"."Name" = 'AdjustmentCauseId')
        OR (o."Name" = 'PromotionMarketSegment' AND __mj."IntegrationObjectField"."Name" = 'PromotionId')
        OR (o."Name" = 'PromotionQualifier' AND __mj."IntegrationObjectField"."Name" = 'PromotionId')
        OR (o."Name" = 'PromotionTarget' AND __mj."IntegrationObjectField"."Name" = 'PromotionId')
        OR (o."Name" = 'PromotionTier' AND __mj."IntegrationObjectField"."Name" = 'PromotionId')
        OR (o."Name" = 'WebCartAdjustmentGroup' AND __mj."IntegrationObjectField"."Name" = 'PriceAdjustmentCauseId')
      )
  );

-- Target: PromotionSegment.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PromotionSegment'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PromotionSegment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PromotionSegment'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PromotionMarketSegment' AND __mj."IntegrationObjectField"."Name" = 'PromotionSegmentId')
        OR (o."Name" = 'PromotionSegmentBuyerGroup' AND __mj."IntegrationObjectField"."Name" = 'PromotionSegmentId')
        OR (o."Name" = 'PromotionSegmentSalesStore' AND __mj."IntegrationObjectField"."Name" = 'PromotionSegmentId')
      )
  );

-- Target: PromotionTier.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PromotionTier'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PromotionTier'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PromotionTier'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PromotionQualifier' AND __mj."IntegrationObjectField"."Name" = 'PromotionTierId')
        OR (o."Name" = 'PromotionTarget' AND __mj."IntegrationObjectField"."Name" = 'PromotionTierId')
      )
  );

-- Target: Prompt.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Prompt'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Prompt'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Prompt'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PromptVersion' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
      )
  );

-- Target: PromptVersion.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PromptVersion'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PromptVersion'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PromptVersion'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PromptAction' AND __mj."IntegrationObjectField"."Name" = 'PromptVersionId')
        OR (o."Name" = 'UiFormulaRule' AND __mj."IntegrationObjectField"."Name" = 'AssociatedElementId')
      )
  );

-- Target: ProrationPolicy.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProrationPolicy'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ProrationPolicy'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ProrationPolicy'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'BillingScheduleGroup' AND __mj."IntegrationObjectField"."Name" = 'ProrationPolicyId')
        OR (o."Name" = 'OrderItem' AND __mj."IntegrationObjectField"."Name" = 'ProrationPolicyId')
        OR (o."Name" = 'ProductSellingModelOption' AND __mj."IntegrationObjectField"."Name" = 'ProrationPolicyId')
        OR (o."Name" = 'QuoteLineItem' AND __mj."IntegrationObjectField"."Name" = 'ProrationPolicyId')
        OR (o."Name" = 'SalesTransactionItemShape' AND __mj."IntegrationObjectField"."Name" = 'ProrationPolicyId')
      )
  );

-- Target: PurchaseQuantityRule.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PurchaseQuantityRule'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PurchaseQuantityRule'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PurchaseQuantityRule'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ProductQuantityRule' AND __mj."IntegrationObjectField"."Name" = 'PurchaseQuantityRuleId')
      )
  );

-- Target: PymtSchdDistributionMethod.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PymtSchdDistributionMethod'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'PymtSchdDistributionMethod'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'PymtSchdDistributionMethod'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PaymentScheduleTreatmentDtl' AND __mj."IntegrationObjectField"."Name" = 'PymtSchdDistributionMethodId')
      )
  );

-- Target: QueueRoutingConfig.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'QueueRoutingConfig'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'QueueRoutingConfig'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'QueueRoutingConfig'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'LiveChatButton' AND __mj."IntegrationObjectField"."Name" = 'RoutingConfigurationId')
        OR (o."Name" = 'ServiceChannel' AND __mj."IntegrationObjectField"."Name" = 'RoutingConfigurationId')
      )
  );

-- Target: QuickText.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'QuickText'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'QuickText'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'QuickText'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'QuickTextUsage' AND __mj."IntegrationObjectField"."Name" = 'QuickTextID')
      )
  );

-- Target: Quote.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Quote'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Quote'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Quote'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'Contract' AND __mj."IntegrationObjectField"."Name" = 'SourceQuoteId')
        OR (o."Name" = 'PaymentInitiationSource' AND __mj."IntegrationObjectField"."Name" = 'QuoteId')
        OR (o."Name" = 'QuoteAction' AND __mj."IntegrationObjectField"."Name" = 'QuoteId')
        OR (o."Name" = 'QuoteAdjustmentGroup' AND __mj."IntegrationObjectField"."Name" = 'QuoteId')
        OR (o."Name" = 'QuoteLineRelationship' AND __mj."IntegrationObjectField"."Name" = 'QuoteId')
      )
  );

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'QuoteAction'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'QuoteAction'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'QuoteAction'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'QuoteLineItem' AND __mj."IntegrationObjectField"."Name" = 'QuoteActionId')
      )
  );

-- Target: QuoteDocument.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'QuoteDocument'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'QuoteDocument'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'QuoteDocument'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'DocumentRecipient' AND __mj."IntegrationObjectField"."Name" = 'QuoteDocumentId')
      )
  );

-- Target: QuoteLineGroup.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'QuoteLineGroup'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'QuoteLineGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'QuoteLineGroup'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'QuoteLineItem' AND __mj."IntegrationObjectField"."Name" = 'QuoteLineGroupId')
      )
  );

-- Target: QuoteLineItem.Id (6 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'QuoteLineItem'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'QuoteLineItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'QuoteLineItem'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'QuoteItemTaxItem' AND __mj."IntegrationObjectField"."Name" = 'QuoteLineItemId')
        OR (o."Name" = 'QuoteLinePriceAdjustment' AND __mj."IntegrationObjectField"."Name" = 'QuoteLineItemId')
        OR (o."Name" = 'QuoteLineRelationship' AND __mj."IntegrationObjectField"."Name" IN ('AssociatedQuoteLineId', 'MainQuoteLineId', 'RootQuoteLineId'))
        OR (o."Name" = 'QuoteLineWorkSource' AND __mj."IntegrationObjectField"."Name" = 'QuoteLineItemId')
      )
  );

-- Target: QuoteLineItemRecipient.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'QuoteLineItemRecipient'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'QuoteLineItemRecipient'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'QuoteLineItemRecipient'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'QuoteLineItem' AND __mj."IntegrationObjectField"."Name" = 'QuoteLineItemRecipientId')
        OR (o."Name" = 'QuoteRecipientGroupMember' AND __mj."IntegrationObjectField"."Name" = 'QuoteLineItemRecipientId')
      )
  );

-- Target: QuoteRecipientGroup.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'QuoteRecipientGroup'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'QuoteRecipientGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'QuoteRecipientGroup'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'QuoteRecipientGroupMember' AND __mj."IntegrationObjectField"."Name" = 'QuoteRecipientGroupId')
      )
  );

-- Target: RecordsetFilterCriteria.Id (8 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'RecordsetFilterCriteria'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'RecordsetFilterCriteria'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'RecordsetFilterCriteria'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ApptBundleAggrPolicy' AND __mj."IntegrationObjectField"."Name" = 'FilterCriteriaId')
        OR (o."Name" = 'ApptBundleConfig' AND __mj."IntegrationObjectField"."Name" = 'CriteriaForAutoUnbundlingId')
        OR (o."Name" = 'ApptBundlePolicy' AND __mj."IntegrationObjectField"."Name" = 'FilterCriteriaId')
        OR (o."Name" = 'ContractLineOutcome' AND __mj."IntegrationObjectField"."Name" = 'RecordsetFilterCriteriaId')
        OR (o."Name" = 'RecordsetFltrCritMonitor' AND __mj."IntegrationObjectField"."Name" = 'RecordsetFilterCriteriaId')
        OR (o."Name" = 'Shift' AND __mj."IntegrationObjectField"."Name" = 'RecordsetFilterCriteriaId')
        OR (o."Name" = 'ShiftTemplate' AND __mj."IntegrationObjectField"."Name" = 'RecordsetFilterCriteriaId')
        OR (o."Name" = 'TimeSlot' AND __mj."IntegrationObjectField"."Name" = 'RecordSetFilterCriteriaId')
      )
  );

-- Target: RecordType.Id (8 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'RecordType'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'RecordType'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'RecordType'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'Asset' AND __mj."IntegrationObjectField"."Name" = 'RecordTypeId')
        OR (o."Name" = 'BuyerGroup' AND __mj."IntegrationObjectField"."Name" = 'RecordTypeId')
        OR (o."Name" = 'Campaign' AND __mj."IntegrationObjectField"."Name" = 'CampaignMemberRecordTypeId')
        OR (o."Name" = 'GtwyProvPaymentMethodType' AND __mj."IntegrationObjectField"."Name" = 'RecordTypeId')
        OR (o."Name" = 'Idea' AND __mj."IntegrationObjectField"."Name" = 'RecordTypeId')
        OR (o."Name" = 'MessagingLink' AND __mj."IntegrationObjectField"."Name" = 'RecordTypeId')
        OR (o."Name" = 'PromptVersion' AND __mj."IntegrationObjectField"."Name" = 'TargetRecordType')
        OR (o."Name" = 'VoiceCall' AND __mj."IntegrationObjectField"."Name" = 'RecordTypeId')
      )
  );

-- Target: Refund.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Refund'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Refund'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Refund'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'RefundLinePayment' AND __mj."IntegrationObjectField"."Name" = 'RefundId')
      )
  );

-- Target: Report.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Report'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Report'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Report'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ScorecardMetric' AND __mj."IntegrationObjectField"."Name" = 'ReportId')
      )
  );

-- Target: ReturnOrder.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ReturnOrder'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ReturnOrder'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ReturnOrder'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PaymentCredit' AND __mj."IntegrationObjectField"."Name" = 'ReturnOrderId')
        OR (o."Name" = 'ProductTransfer' AND __mj."IntegrationObjectField"."Name" = 'ReturnOrderId')
        OR (o."Name" = 'ReturnOrderItemAdjustment' AND __mj."IntegrationObjectField"."Name" = 'ReturnOrderId')
        OR (o."Name" = 'ReturnOrderItemTax' AND __mj."IntegrationObjectField"."Name" = 'ReturnOrderId')
        OR (o."Name" = 'ReturnOrderLineItem' AND __mj."IntegrationObjectField"."Name" = 'ReturnOrderId')
      )
  );

-- Target: ReturnOrderItemAdjustment.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ReturnOrderItemAdjustment'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ReturnOrderItemAdjustment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ReturnOrderItemAdjustment'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ReturnOrderItemTax' AND __mj."IntegrationObjectField"."Name" = 'ReturnOrderItemAdjustmentId')
      )
  );

-- Target: ReturnOrderLineItem.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ReturnOrderLineItem'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ReturnOrderLineItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ReturnOrderLineItem'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ProductTransfer' AND __mj."IntegrationObjectField"."Name" = 'ReturnOrderLineItemId')
        OR (o."Name" = 'ReturnOrderItemAdjustment' AND __mj."IntegrationObjectField"."Name" = 'ReturnOrderLineItemId')
        OR (o."Name" = 'ReturnOrderItemTax' AND __mj."IntegrationObjectField"."Name" = 'ReturnOrderLineItemId')
      )
  );

-- Target: RevenueAsyncOperation.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'RevenueAsyncOperation'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'RevenueAsyncOperation'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'RevenueAsyncOperation'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'RevenueTransactionErrorLog' AND __mj."IntegrationObjectField"."Name" = 'RevenueAsyncOperationId')
      )
  );

-- Target: SalesChannel.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SalesChannel'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SalesChannel'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SalesChannel'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'OrderSummary' AND __mj."IntegrationObjectField"."Name" = 'SalesChannelId')
        OR (o."Name" = 'PendingOrderSummary' AND __mj."IntegrationObjectField"."Name" = 'SalesChannelId')
      )
  );

-- Target: SalesforceContract.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SalesforceContract'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SalesforceContract'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SalesforceContract'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'SalesforceInvoice' AND __mj."IntegrationObjectField"."Name" = 'SalesforceContractId')
        OR (o."Name" = 'SalesforceQuote' AND __mj."IntegrationObjectField"."Name" = 'SalesforceContractId')
      )
  );

-- Target: SalesTransactionItemShape.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SalesTransactionItemShape'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SalesTransactionItemShape'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SalesTransactionItemShape'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PriceAdjustmentItemShape' AND __mj."IntegrationObjectField"."Name" = 'SalesTransactionItemShapeId')
        OR (o."Name" = 'SalesTrxnItemRelationShape' AND __mj."IntegrationObjectField"."Name" IN ('AssocSalesTrxnItemShapeId', 'MainSalesTrxnItemShapeId'))
      )
  );

-- Target: SalesTransactionShape.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SalesTransactionShape'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SalesTransactionShape'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SalesTransactionShape'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PriceAdjustmentGroupShape' AND __mj."IntegrationObjectField"."Name" = 'SalesTransactionShapeId')
        OR (o."Name" = 'SalesTransactionItemShape' AND __mj."IntegrationObjectField"."Name" = 'SalesTransactionShapeId')
        OR (o."Name" = 'SalesTrxnItemRelationShape' AND __mj."IntegrationObjectField"."Name" = 'SalesTransactionShapeId')
      )
  );

-- Target: SavedPaymentMethod.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SavedPaymentMethod'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SavedPaymentMethod'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SavedPaymentMethod'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AlternativePaymentMethod' AND __mj."IntegrationObjectField"."Name" = 'SavedPaymentMethodId')
        OR (o."Name" = 'CardPaymentMethod' AND __mj."IntegrationObjectField"."Name" = 'SavedPaymentMethodId')
        OR (o."Name" = 'DigitalWallet' AND __mj."IntegrationObjectField"."Name" = 'SavedPaymentMethodId')
        OR (o."Name" = 'PaymentMethod' AND __mj."IntegrationObjectField"."Name" = 'SavedPaymentMethodId')
        OR (o."Name" = 'SavedPaymentMethodEvent' AND __mj."IntegrationObjectField"."Name" = 'SavedPaymentMethodId')
      )
  );

-- Target: SchedulingAdherenceSummary.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SchedulingAdherenceSummary'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SchedulingAdherenceSummary'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SchedulingAdherenceSummary'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'SchedulingAdherenceDetail' AND __mj."IntegrationObjectField"."Name" = 'SchedulingAdherenceSummaryId')
      )
  );

-- Target: SchedulingRule.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SchedulingRule'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SchedulingRule'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SchedulingRule'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'SchedulingRuleParameter' AND __mj."IntegrationObjectField"."Name" = 'SchedulingRuleId')
      )
  );

-- Target: Scorecard.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Scorecard'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Scorecard'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Scorecard'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ScorecardAssociation' AND __mj."IntegrationObjectField"."Name" = 'ScorecardId')
        OR (o."Name" = 'ScorecardMetric' AND __mj."IntegrationObjectField"."Name" = 'ScorecardId')
      )
  );

-- Target: ServiceAppointment.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ServiceAppointment'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ServiceAppointment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ServiceAppointment'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AssignedResource' AND __mj."IntegrationObjectField"."Name" = 'ServiceAppointmentId')
        OR (o."Name" = 'FldSvcObjChg' AND __mj."IntegrationObjectField"."Name" = 'ServiceAppointmentId')
        OR (o."Name" = 'GeolocationBasedAction' AND __mj."IntegrationObjectField"."Name" = 'ReferenceRecordId')
      )
  );

-- Target: ServiceChannel.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ServiceChannel'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ServiceChannel'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ServiceChannel'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AgentWork' AND __mj."IntegrationObjectField"."Name" = 'ServiceChannelId')
        OR (o."Name" = 'WorkDemographic' AND __mj."IntegrationObjectField"."Name" = 'ServiceChannelId')
      )
  );

-- Target: ServiceContract.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ServiceContract'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ServiceContract'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ServiceContract'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ContractLineOutcome' AND __mj."IntegrationObjectField"."Name" = 'ServiceContractId')
      )
  );

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ServicePresenceStatus'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ServicePresenceStatus'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ServicePresenceStatus'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'SchedulingAdherenceDetail' AND __mj."IntegrationObjectField"."Name" = 'StatusId')
        OR (o."Name" = 'ShiftSegmentType' AND __mj."IntegrationObjectField"."Name" = 'ServicePresenceStatusId')
        OR (o."Name" = 'VendorCallCenterStatusMap' AND __mj."IntegrationObjectField"."Name" = 'ServicePresenceStatusId')
      )
  );

-- Target: ServiceResource.Id (11 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ServiceResource'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ServiceResource'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ServiceResource'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AppointmentScheduleAggr' AND __mj."IntegrationObjectField"."Name" = 'ServiceResourceId')
        OR (o."Name" = 'AppointmentScheduleLog' AND __mj."IntegrationObjectField"."Name" = 'ServiceResourceId')
        OR (o."Name" = 'AssignedResource' AND __mj."IntegrationObjectField"."Name" = 'ServiceResourceId')
        OR (o."Name" = 'ResourceAbsence' AND __mj."IntegrationObjectField"."Name" = 'ResourceId')
        OR (o."Name" = 'ResourcePreference' AND __mj."IntegrationObjectField"."Name" = 'ServiceResourceId')
        OR (o."Name" = 'SchedulingAdherenceSummary' AND __mj."IntegrationObjectField"."Name" = 'ServiceResourceId')
        OR (o."Name" = 'ServiceResourcePreference' AND __mj."IntegrationObjectField"."Name" = 'ServiceResourceId')
        OR (o."Name" = 'ServiceResourceSkill' AND __mj."IntegrationObjectField"."Name" = 'ServiceResourceId')
        OR (o."Name" = 'ServiceTerritoryMember' AND __mj."IntegrationObjectField"."Name" = 'ServiceResourceId')
        OR (o."Name" = 'Shift' AND __mj."IntegrationObjectField"."Name" = 'ServiceResourceId')
        OR (o."Name" = 'SkillLevelProgress' AND __mj."IntegrationObjectField"."Name" = 'ServiceResourceId')
      )
  );

-- Target: ServiceTerritory.Id (12 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ServiceTerritory'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ServiceTerritory'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ServiceTerritory'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ApptBundlePolicySvcTerr' AND __mj."IntegrationObjectField"."Name" = 'ServiceTerritoryId')
        OR (o."Name" = 'SchedulingAdherenceSummary' AND __mj."IntegrationObjectField"."Name" = 'ServiceTerritoryId')
        OR (o."Name" = 'ServiceAppointment' AND __mj."IntegrationObjectField"."Name" = 'ServiceTerritoryId')
        OR (o."Name" = 'ServiceTerritoryMember' AND __mj."IntegrationObjectField"."Name" = 'ServiceTerritoryId')
        OR (o."Name" = 'ServiceTerritoryWorkType' AND __mj."IntegrationObjectField"."Name" = 'ServiceTerritoryId')
        OR (o."Name" = 'Shift' AND __mj."IntegrationObjectField"."Name" = 'ServiceTerritoryId')
        OR (o."Name" = 'WorkCapacityAvailability' AND __mj."IntegrationObjectField"."Name" = 'ServiceTerritoryId')
        OR (o."Name" = 'WorkCapacityLimit' AND __mj."IntegrationObjectField"."Name" = 'ServiceTerritoryId')
        OR (o."Name" = 'WorkCapacityUsage' AND __mj."IntegrationObjectField"."Name" = 'ServiceTerritoryId')
        OR (o."Name" = 'WorkDemographic' AND __mj."IntegrationObjectField"."Name" = 'ServiceTerritoryId')
        OR (o."Name" = 'WorkOrder' AND __mj."IntegrationObjectField"."Name" = 'ServiceTerritoryId')
        OR (o."Name" = 'WorkOrderLineItem' AND __mj."IntegrationObjectField"."Name" = 'ServiceTerritoryId')
      )
  );

-- Target: SfdcCustomerForPartner.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SfdcCustomerForPartner'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SfdcCustomerForPartner'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SfdcCustomerForPartner'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'SfdcPartnerOffer' AND __mj."IntegrationObjectField"."Name" = 'CustomerId')
        OR (o."Name" = 'SfdcPartnerOrder' AND __mj."IntegrationObjectField"."Name" = 'SfdcCustomerForPartnerId')
        OR (o."Name" = 'SfdcPartnerTenant' AND __mj."IntegrationObjectField"."Name" = 'CustomerId')
      )
  );

-- Target: SfdcPartnerOffer.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SfdcPartnerOffer'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SfdcPartnerOffer'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SfdcPartnerOffer'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'SfdcPartnerOfferItem' AND __mj."IntegrationObjectField"."Name" = 'PartnerOfferId')
        OR (o."Name" = 'SfdcPartnerOrder' AND __mj."IntegrationObjectField"."Name" = 'OriginatingOfferId')
      )
  );

-- Target: SfdcPartnerPackage.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SfdcPartnerPackage'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SfdcPartnerPackage'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SfdcPartnerPackage'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'SfdcPartnerTenantPackage' AND __mj."IntegrationObjectField"."Name" = 'PartnerPackageId')
      )
  );

-- Target: SfdcPartnerPackageVersion.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SfdcPartnerPackageVersion'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SfdcPartnerPackageVersion'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SfdcPartnerPackageVersion'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'SfdcPartnerTenantPackage' AND __mj."IntegrationObjectField"."Name" = 'PartnerPackageVersion')
      )
  );

-- Target: SfdcPartnerProvisionProduct.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SfdcPartnerProvisionProduct'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SfdcPartnerProvisionProduct'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SfdcPartnerProvisionProduct'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'SfdcPartnerOfferItem' AND __mj."IntegrationObjectField"."Name" = 'PartnerProvisionProductId')
        OR (o."Name" = 'SfdcPartnerOrderItem' AND __mj."IntegrationObjectField"."Name" = 'PartnerProvisionProductId')
        OR (o."Name" = 'SfdcPartnerProductLicense' AND __mj."IntegrationObjectField"."Name" = 'PartnerProvisionProductId')
      )
  );

-- Target: SfdcPartnerTenant.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SfdcPartnerTenant'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SfdcPartnerTenant'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SfdcPartnerTenant'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'SfdcPartnerOrderItem' AND __mj."IntegrationObjectField"."Name" = 'PartnerTenantId')
        OR (o."Name" = 'SfdcPartnerTenantPackage' AND __mj."IntegrationObjectField"."Name" = 'PartnerTenantId')
      )
  );

-- Target: SfdcPartnerTenantPackage.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SfdcPartnerTenantPackage'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SfdcPartnerTenantPackage'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SfdcPartnerTenantPackage'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'SfdcPartnerTntPermSetLic' AND __mj."IntegrationObjectField"."Name" = 'PartnerTenantPackageId')
        OR (o."Name" = 'SfdcPartnerTntPkgLicense' AND __mj."IntegrationObjectField"."Name" = 'PartnerTenantPackageId')
      )
  );

-- Target: SfdcPartnerTermSet.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SfdcPartnerTermSet'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SfdcPartnerTermSet'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SfdcPartnerTermSet'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'SfdcPartnerOffer' AND __mj."IntegrationObjectField"."Name" = 'PartnerTermSetId')
        OR (o."Name" = 'SfdcPartnerOrder' AND __mj."IntegrationObjectField"."Name" = 'SfdcPartnerTermSetId')
        OR (o."Name" = 'SfdcPartnerTermSetProduct' AND __mj."IntegrationObjectField"."Name" = 'PartnerTermSetId')
      )
  );

-- Target: SfdcPartnerTermSetProduct.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SfdcPartnerTermSetProduct'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SfdcPartnerTermSetProduct'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SfdcPartnerTermSetProduct'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'SfdcPartnerProvisionProduct' AND __mj."IntegrationObjectField"."Name" = 'PartnerTermSetProductId')
      )
  );

-- Target: Shift.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Shift'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Shift'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Shift'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ShiftHistory' AND __mj."IntegrationObjectField"."Name" = 'ShiftId')
        OR (o."Name" = 'ShiftSegment' AND __mj."IntegrationObjectField"."Name" = 'ShiftId')
        OR (o."Name" = 'ShiftShare' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
      )
  );

-- Target: ShiftPattern.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ShiftPattern'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ShiftPattern'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ShiftPattern'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ShiftPatternEntry' AND __mj."IntegrationObjectField"."Name" = 'ShiftPatternId')
      )
  );

-- Target: ShiftSegmentType.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ShiftSegmentType'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ShiftSegmentType'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ShiftSegmentType'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ShiftSegment' AND __mj."IntegrationObjectField"."Name" = 'SegmentTypeId')
      )
  );

-- Target: ShiftTemplate.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ShiftTemplate'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ShiftTemplate'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ShiftTemplate'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'Shift' AND __mj."IntegrationObjectField"."Name" = 'ShiftTemplateId')
        OR (o."Name" = 'ShiftPatternEntry' AND __mj."IntegrationObjectField"."Name" = 'ShiftTemplateId')
        OR (o."Name" = 'WorkforceCapacityUnit' AND __mj."IntegrationObjectField"."Name" = 'ShiftTemplateId')
      )
  );

-- Target: Shipment.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Shipment'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Shipment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Shipment'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ProductTransfer' AND __mj."IntegrationObjectField"."Name" = 'ShipmentId')
        OR (o."Name" = 'ShipmentItem' AND __mj."IntegrationObjectField"."Name" = 'ShipmentId')
      )
  );

-- Target: ShippingCarrier.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ShippingCarrier'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ShippingCarrier'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ShippingCarrier'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ShippingCarrierMethod' AND __mj."IntegrationObjectField"."Name" = 'ShippingCarrierId')
      )
  );

-- Target: ShippingCarrierMethod.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ShippingCarrierMethod'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ShippingCarrierMethod'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ShippingCarrierMethod'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'StandardShippingRate' AND __mj."IntegrationObjectField"."Name" = 'ShippingCarrierMethodId')
      )
  );

-- Target: ShippingConfigurationSet.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ShippingConfigurationSet'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ShippingConfigurationSet'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ShippingConfigurationSet'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ShippingRateGroup' AND __mj."IntegrationObjectField"."Name" = 'ShippingProfileId')
      )
  );

-- Target: ShippingRateGroup.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ShippingRateGroup'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'ShippingRateGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'ShippingRateGroup'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ShippingRateArea' AND __mj."IntegrationObjectField"."Name" = 'ShippingRateGroupId')
      )
  );

-- Target: Site.Id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Site'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Site'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Site'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'DomainSite' AND __mj."IntegrationObjectField"."Name" = 'SiteId')
        OR (o."Name" = 'LiveChatButton' AND __mj."IntegrationObjectField"."Name" = 'SiteId')
        OR (o."Name" = 'PaymentInitiationSource' AND __mj."IntegrationObjectField"."Name" = 'SiteId')
        OR (o."Name" = 'PromptVersion' AND __mj."IntegrationObjectField"."Name" = 'ExperienceContextId')
        OR (o."Name" = 'SiteHistory' AND __mj."IntegrationObjectField"."Name" = 'SiteId')
        OR (o."Name" = 'SiteIframeWhitelistUrl' AND __mj."IntegrationObjectField"."Name" = 'SiteId')
        OR (o."Name" = 'SiteRedirectMapping' AND __mj."IntegrationObjectField"."Name" = 'SiteId')
      )
  );

-- Target: Skill.Id (6 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Skill'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Skill'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Skill'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'LiveChatButton' AND __mj."IntegrationObjectField"."Name" = 'SkillId')
        OR (o."Name" = 'MessagingChannelSkill' AND __mj."IntegrationObjectField"."Name" = 'SkillId')
        OR (o."Name" = 'OmniSupervisorConfigSkill' AND __mj."IntegrationObjectField"."Name" = 'SkillId')
        OR (o."Name" = 'ServiceResourceSkill' AND __mj."IntegrationObjectField"."Name" = 'SkillId')
        OR (o."Name" = 'SkillLevelDefinition' AND __mj."IntegrationObjectField"."Name" = 'SkillId')
        OR (o."Name" = 'SkillRequirement' AND __mj."IntegrationObjectField"."Name" = 'SkillId')
      )
  );

-- Target: SkillLevelDefinition.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SkillLevelDefinition'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SkillLevelDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SkillLevelDefinition'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'SkillLevelProgress' AND __mj."IntegrationObjectField"."Name" = 'SkillLevelDefinitionId')
      )
  );

-- Target: SocialPersona.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SocialPersona'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SocialPersona'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SocialPersona'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'SocialPost' AND __mj."IntegrationObjectField"."Name" = 'PersonaId')
      )
  );

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Solution'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Solution'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Solution'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CaseSolution' AND __mj."IntegrationObjectField"."Name" = 'SolutionId')
      )
  );

-- Target: SourceCodeRepoProvider.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SourceCodeRepoProvider'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SourceCodeRepoProvider'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SourceCodeRepoProvider'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'SourceCodeRepository' AND __mj."IntegrationObjectField"."Name" = 'SourceCodeRepoProviderId')
      )
  );

-- Target: SourceCodeRepository.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SourceCodeRepository'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SourceCodeRepository'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SourceCodeRepository'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'DevopsPipeline' AND __mj."IntegrationObjectField"."Name" = 'SourceCodeRepositoryId')
      )
  );

-- Target: SourceCodeRepositoryBranch.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SourceCodeRepositoryBranch'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SourceCodeRepositoryBranch'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SourceCodeRepositoryBranch'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'DevopsPipelineStage' AND __mj."IntegrationObjectField"."Name" = 'SourceCodeRepositoryBranchId')
        OR (o."Name" = 'DevopsPipelnStgPromWkItem' AND __mj."IntegrationObjectField"."Name" = 'MergeSourceBranchId')
        OR (o."Name" = 'WorkItem' AND __mj."IntegrationObjectField"."Name" IN ('RebaseBranchId', 'SourceCodeRepositoryBranchId'))
      )
  );

-- Target: StagedInviteeEmail.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'StagedInviteeEmail'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'StagedInviteeEmail'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'StagedInviteeEmail'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'EventStagedInviteeEmail' AND __mj."IntegrationObjectField"."Name" = 'StagedInviteeEmailId')
      )
  );

-- Target: StagedUnmtchdEmailAddr.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'StagedUnmtchdEmailAddr'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'StagedUnmtchdEmailAddr'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'StagedUnmtchdEmailAddr'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'StagedUnmtchdEmailAddrRela' AND __mj."IntegrationObjectField"."Name" = 'StagedUnmatchedEmailAddressId')
      )
  );

-- Target: Stamp.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Stamp'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Stamp'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Stamp'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'StampAssignment' AND __mj."IntegrationObjectField"."Name" = 'StampId')
      )
  );

-- Target: StaticResource.Id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'StaticResource'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'StaticResource'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'StaticResource'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ConversationChannelDefinition' AND __mj."IntegrationObjectField"."Name" = 'CustomIconId')
        OR (o."Name" = 'ConversationVendorInfo' AND __mj."IntegrationObjectField"."Name" = 'CustomIconId')
        OR (o."Name" = 'LiveChatButton' AND __mj."IntegrationObjectField"."Name" IN ('InviteImageId', 'OfflineImageId', 'OnlineImageId'))
        OR (o."Name" = 'PresenceUserConfig' AND __mj."IntegrationObjectField"."Name" = 'CustomSoundId')
        OR (o."Name" = 'ServiceChannel' AND __mj."IntegrationObjectField"."Name" = 'CustomSoundId')
      )
  );

-- Target: SurveyResponse.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SurveyResponse'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SurveyResponse'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SurveyResponse'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'KnowledgeArticleFeedback' AND __mj."IntegrationObjectField"."Name" = 'FeedbackResponseId')
      )
  );

-- Target: SvcCatalogCategory.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SvcCatalogCategory'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SvcCatalogCategory'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SvcCatalogCategory'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'SvcCatalogCategoryItem' AND __mj."IntegrationObjectField"."Name" = 'SvcCatalogCategoryId')
      )
  );

-- Target: SvcCatalogItemDef.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SvcCatalogItemDef'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SvcCatalogItemDef'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SvcCatalogItemDef'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'SvcCatalogCategoryItem' AND __mj."IntegrationObjectField"."Name" = 'SvcCatalogItemDefId')
        OR (o."Name" = 'SvcCatalogRequest' AND __mj."IntegrationObjectField"."Name" = 'SvcCatalogItemDefinitionId')
      )
  );

-- Target: SvcCatalogRequest.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SvcCatalogRequest'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'SvcCatalogRequest'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'SvcCatalogRequest'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'SvcCatalogReqRelatedItem' AND __mj."IntegrationObjectField"."Name" = 'SvcCatalogRequestId')
      )
  );

-- Target: Swarm.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Swarm'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Swarm'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Swarm'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'SwarmMember' AND __mj."IntegrationObjectField"."Name" = 'SwarmId')
      )
  );

-- Target: Task.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Task'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Task'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Task'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'EmailStatus' AND __mj."IntegrationObjectField"."Name" = 'TaskId')
        OR (o."Name" = 'ListEmailSentResult' AND __mj."IntegrationObjectField"."Name" = 'ActivityId')
        OR (o."Name" = 'UnifiedTask' AND __mj."IntegrationObjectField"."Name" = 'DetailId')
        OR (o."Name" = 'VoiceCall' AND __mj."IntegrationObjectField"."Name" = 'ActivityId')
      )
  );

-- Target: TaxEngine.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'TaxEngine'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'TaxEngine'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'TaxEngine'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'TaxEngineInteractionLog' AND __mj."IntegrationObjectField"."Name" = 'TaxEngineId')
        OR (o."Name" = 'TaxTreatment' AND __mj."IntegrationObjectField"."Name" = 'TaxEngineId')
      )
  );

-- Target: TaxEngineProvider.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'TaxEngineProvider'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'TaxEngineProvider'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'TaxEngineProvider'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'TaxEngine' AND __mj."IntegrationObjectField"."Name" = 'TaxEngineProviderId')
      )
  );

-- Target: TaxPolicy.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'TaxPolicy'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'TaxPolicy'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'TaxPolicy'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'Product2' AND __mj."IntegrationObjectField"."Name" = 'TaxPolicyId')
        OR (o."Name" = 'TaxTreatment' AND __mj."IntegrationObjectField"."Name" = 'TaxPolicyId')
        OR (o."Name" = 'WebStore' AND __mj."IntegrationObjectField"."Name" = 'DefaultTaxPolicyId')
      )
  );

-- Target: TaxTreatment.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'TaxTreatment'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'TaxTreatment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'TaxTreatment'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'BillingSchedule' AND __mj."IntegrationObjectField"."Name" = 'TaxTreatmentId')
        OR (o."Name" = 'CartItem' AND __mj."IntegrationObjectField"."Name" = 'TaxTreatmentId')
        OR (o."Name" = 'OrderItem' AND __mj."IntegrationObjectField"."Name" = 'TaxTreatmentId')
        OR (o."Name" = 'OrderItemSummary' AND __mj."IntegrationObjectField"."Name" = 'TaxTreatmentId')
      )
  );

-- Target: Territory2.Id (10 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Territory2'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Territory2'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Territory2'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ForecastingSrcRecJudgment' AND __mj."IntegrationObjectField"."Name" = 'Territory2Id')
        OR (o."Name" = 'ForecastingSubmission' AND __mj."IntegrationObjectField"."Name" = 'Territory2Id')
        OR (o."Name" = 'ObjectUserTerritory2View' AND __mj."IntegrationObjectField"."Name" = 'Territory2Id')
        OR (o."Name" = 'OpportunityLineItemSplit' AND __mj."IntegrationObjectField"."Name" = 'Territory2Id')
        OR (o."Name" = 'OpportunitySplit' AND __mj."IntegrationObjectField"."Name" = 'Territory2Id')
        OR (o."Name" = 'Territory2AlignmentLog' AND __mj."IntegrationObjectField"."Name" = 'Territory2Id')
        OR (o."Name" = 'Territory2ObjectExclusion' AND __mj."IntegrationObjectField"."Name" = 'Territory2Id')
        OR (o."Name" = 'Territory2ObjSharingConfig' AND __mj."IntegrationObjectField"."Name" = 'Territory2Id')
        OR (o."Name" = 'TerritoryAdminAssignment' AND __mj."IntegrationObjectField"."Name" = 'Territory2Id')
        OR (o."Name" = 'UserTerritory2AssocLog' AND __mj."IntegrationObjectField"."Name" = 'Territory2Id')
      )
  );

-- Target: Territory2Model.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Territory2Model'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Territory2Model'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Territory2Model'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'Territory2AlignmentLog' AND __mj."IntegrationObjectField"."Name" = 'Territory2ModelId')
        OR (o."Name" = 'TerritoryAdminAssignment' AND __mj."IntegrationObjectField"."Name" = 'Territory2ModelId')
        OR (o."Name" = 'UserTerritory2AssocLog' AND __mj."IntegrationObjectField"."Name" = 'Territory2ModelId')
      )
  );

-- Target: TerritoryMgmtObjectConfig.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'TerritoryMgmtObjectConfig'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'TerritoryMgmtObjectConfig'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'TerritoryMgmtObjectConfig'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'Territory2ObjSharingConfig' AND __mj."IntegrationObjectField"."Name" = 'TerritoryMgmtObjectConfigId')
      )
  );

-- Target: TimeSlot.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'TimeSlot'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'TimeSlot'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'TimeSlot'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AppointmentTopicTimeSlot' AND __mj."IntegrationObjectField"."Name" = 'TimeSlotId')
      )
  );

-- Target: Topic.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Topic'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Topic'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Topic'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'TopicAssignment' AND __mj."IntegrationObjectField"."Name" = 'TopicId')
      )
  );

-- Target: TravelMode.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'TravelMode'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'TravelMode'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'TravelMode'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ServiceTerritory' AND __mj."IntegrationObjectField"."Name" = 'TravelModeId')
        OR (o."Name" = 'ServiceTerritoryMember' AND __mj."IntegrationObjectField"."Name" = 'TravelModeId')
      )
  );

-- Target: UiFormulaRule.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UiFormulaRule'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UiFormulaRule'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'UiFormulaRule'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'UiFormulaCriterion' AND __mj."IntegrationObjectField"."Name" = 'RuleId')
      )
  );

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UnifiedActivityInsight'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UnifiedActivityInsight'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'UnifiedActivityInsight'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'UnifiedActvtyInsightKeyword' AND __mj."IntegrationObjectField"."Name" = 'InsightId')
      )
  );

-- Target: UnifiedEmail.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UnifiedEmail'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UnifiedEmail'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'UnifiedEmail'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'UnifiedEmailParticipant' AND __mj."IntegrationObjectField"."Name" = 'ActivityId')
      )
  );

-- Target: UnifiedMeeting.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UnifiedMeeting'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UnifiedMeeting'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'UnifiedMeeting'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'UnifiedMeetingParticipant' AND __mj."IntegrationObjectField"."Name" = 'ActivityId')
      )
  );

-- Target: UnifiedTask.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UnifiedTask'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UnifiedTask'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'UnifiedTask'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'UnifiedTaskParticipant' AND __mj."IntegrationObjectField"."Name" = 'ActivityId')
      )
  );

-- Target: UnifiedVideoCall.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UnifiedVideoCall'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UnifiedVideoCall'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'UnifiedVideoCall'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'UnifiedVideoCallParticipant' AND __mj."IntegrationObjectField"."Name" = 'ActivityId')
      )
  );

-- Target: UnifiedVoiceCall.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UnifiedVoiceCall'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UnifiedVoiceCall'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'UnifiedVoiceCall'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'UnifiedVoiceCallParticipant' AND __mj."IntegrationObjectField"."Name" = 'ActivityId')
      )
  );

-- Target: UnitOfMeasure.Id (8 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UnitOfMeasure'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UnitOfMeasure'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'UnitOfMeasure'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AssetRateCardEntry' AND __mj."IntegrationObjectField"."Name" = 'RateUnitOfMeasureId')
        OR (o."Name" = 'AttributeDefinition' AND __mj."IntegrationObjectField"."Name" = 'UnitOfMeasureId')
        OR (o."Name" = 'AttributePicklist' AND __mj."IntegrationObjectField"."Name" = 'UnitOfMeasureId')
        OR (o."Name" = 'CartItemAttribute' AND __mj."IntegrationObjectField"."Name" = 'UnitOfMeasure')
        OR (o."Name" = 'Product2' AND __mj."IntegrationObjectField"."Name" = 'UnitOfMeasureId')
        OR (o."Name" = 'ProgramRebateType' AND __mj."IntegrationObjectField"."Name" = 'UnitOfMeasureId')
        OR (o."Name" = 'QuoteLineItem' AND __mj."IntegrationObjectField"."Name" = 'QuantityUnitOfMeasureId')
        OR (o."Name" = 'UsageImpactGroupFactor' AND __mj."IntegrationObjectField"."Name" = 'UnitOfMeasureId')
      )
  );

-- Target: UsageImpactFactor.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UsageImpactFactor'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UsageImpactFactor'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'UsageImpactFactor'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'UsageImpactGroupFactor' AND __mj."IntegrationObjectField"."Name" = 'UsageImpactFactorId')
      )
  );

-- Target: UsageImpactGroup.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UsageImpactGroup'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UsageImpactGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'UsageImpactGroup'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'UsageImpactGroupVersion' AND __mj."IntegrationObjectField"."Name" = 'UsageImpactGroupId')
      )
  );

-- Target: UsageImpactGroupVersion.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UsageImpactGroupVersion'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UsageImpactGroupVersion'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'UsageImpactGroupVersion'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'UsageImpactGroupFactor' AND __mj."IntegrationObjectField"."Name" = 'UsageImpactGroupVersionId')
        OR (o."Name" = 'UsageImpactGroupPgmMeasure' AND __mj."IntegrationObjectField"."Name" = 'UsageImpactGroupVersionId')
      )
  );

-- Target: User.Id (174 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'User'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'User'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'User'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'Account' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'AccountPlanObjective' AND __mj."IntegrationObjectField"."Name" = 'ObjectiveOwnerId')
        OR (o."Name" = 'ActionCadence' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'ActionCadenceStepTracker' AND __mj."IntegrationObjectField"."Name" = 'CompletedById')
        OR (o."Name" = 'ActivityFieldHistory' AND __mj."IntegrationObjectField"."Name" = 'ChangedById')
        OR (o."Name" = 'AgentWork' AND __mj."IntegrationObjectField"."Name" IN ('PreferredUserId', 'TransferRequesterId', 'UserId'))
        OR (o."Name" = 'AnalyticsDashboard' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'AnalyticsVisualization' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'AnalyticsVizViewDef' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'ApexEmailNotification' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'ApexInlineEventLog' AND __mj."IntegrationObjectField"."Name" = 'LogUserId')
        OR (o."Name" = 'ApexLog' AND __mj."IntegrationObjectField"."Name" = 'LogUserId')
        OR (o."Name" = 'ApexTestRunResult' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'ApplicationFormTemplate' AND __mj."IntegrationObjectField"."Name" = 'ApproverId')
        OR (o."Name" = 'ApprovalSubmission' AND __mj."IntegrationObjectField"."Name" IN ('OwnerId', 'SubmittedById'))
        OR (o."Name" = 'ApprovalSubmissionDetail' AND __mj."IntegrationObjectField"."Name" = 'ActionPerformedById')
        OR (o."Name" = 'ApprovalWorkItem' AND __mj."IntegrationObjectField"."Name" IN ('AssignedToId', 'ReviewedById'))
        OR (o."Name" = 'Asset' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'AuthSession' AND __mj."IntegrationObjectField"."Name" = 'UsersId')
        OR (o."Name" = 'BotDefinition' AND __mj."IntegrationObjectField"."Name" = 'BotUserId')
        OR (o."Name" = 'BusinessAlertStatus' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'BuyerAccount' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'CallCtrAgentFavTrfrDest' AND __mj."IntegrationObjectField"."Name" = 'AgentId')
        OR (o."Name" = 'Campaign' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'ChangeRequest' AND __mj."IntegrationObjectField"."Name" = 'ReviewerId')
        OR (o."Name" = 'ClientBrowser' AND __mj."IntegrationObjectField"."Name" = 'UsersId')
        OR (o."Name" = 'CollaborationGroup' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'CollaborationGroupMember' AND __mj."IntegrationObjectField"."Name" = 'MemberId')
        OR (o."Name" = 'CollaborationGroupMemberRequest' AND __mj."IntegrationObjectField"."Name" = 'RequesterId')
        OR (o."Name" = 'Contact' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'ContentDistribution' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'ContentDocument' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'ContentDocumentSubscription' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'ContentNotification' AND __mj."IntegrationObjectField"."Name" = 'UsersId')
        OR (o."Name" = 'ContentTagSubscription' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'ContentUserSubscription' AND __mj."IntegrationObjectField"."Name" IN ('SubscribedToUserId', 'SubscriberUserId'))
        OR (o."Name" = 'ContentVersion' AND __mj."IntegrationObjectField"."Name" IN ('ContentModifiedById', 'OwnerId'))
        OR (o."Name" = 'ContentVersionRating' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'ContentWorkspaceSubscription' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'Contract' AND __mj."IntegrationObjectField"."Name" IN ('ActivatedById', 'CompanySignedId', 'OwnerId'))
        OR (o."Name" = 'ConversationApiLog' AND __mj."IntegrationObjectField"."Name" = 'RequestedById')
        OR (o."Name" = 'Dashboard' AND __mj."IntegrationObjectField"."Name" = 'RunningUserId')
        OR (o."Name" = 'DataIntegrationRecordPurchasePermission' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'DelegatedAccount' AND __mj."IntegrationObjectField"."Name" = 'ManagedById')
        OR (o."Name" = 'DeleteEvent' AND __mj."IntegrationObjectField"."Name" = 'DeletedById')
        OR (o."Name" = 'DeliveryEstimationSetup' AND __mj."IntegrationObjectField"."Name" = 'LastSyncedById')
        OR (o."Name" = 'DevopsActivityLog' AND __mj."IntegrationObjectField"."Name" = 'PerformedById')
        OR (o."Name" = 'DevopsEnvDeploymentMbr' AND __mj."IntegrationObjectField"."Name" = 'ChangedById')
        OR (o."Name" = 'Document' AND __mj."IntegrationObjectField"."Name" = 'AuthorId')
        OR (o."Name" = 'EmailTemplate' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'EntitySubscription' AND __mj."IntegrationObjectField"."Name" = 'SubscriberId')
        OR (o."Name" = 'ExternalDataUserAuth' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'FeedComment' AND __mj."IntegrationObjectField"."Name" = 'InsertedById')
        OR (o."Name" = 'FeedItem' AND __mj."IntegrationObjectField"."Name" = 'InsertedById')
        OR (o."Name" = 'FeedLike' AND __mj."IntegrationObjectField"."Name" = 'InsertedById')
        OR (o."Name" = 'feedSignal' AND __mj."IntegrationObjectField"."Name" = 'InsertedById')
        OR (o."Name" = 'FldSvcObjChg' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'FlowOrchestrationInstance' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'FlowOrchestrationStepInstance' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'FlowOrchestrationVersion' AND __mj."IntegrationObjectField"."Name" = 'ActivatedById')
        OR (o."Name" = 'FlowOrchestrationWorkItem' AND __mj."IntegrationObjectField"."Name" IN ('AssigneeId', 'OwnerId'))
        OR (o."Name" = 'FlowRecordVersion' AND __mj."IntegrationObjectField"."Name" IN ('ActivatedById', 'PausingUserId', 'ResumingUserId'))
        OR (o."Name" = 'ForecastingCustomData' AND __mj."IntegrationObjectField"."Name" = 'ForecastOwnerId')
        OR (o."Name" = 'ForecastingSrcRecJudgment' AND __mj."IntegrationObjectField"."Name" = 'JudgmentOwnerId')
        OR (o."Name" = 'ForecastingSubmission' AND __mj."IntegrationObjectField"."Name" = 'ForecastOwnerId')
        OR (o."Name" = 'Incident' AND __mj."IntegrationObjectField"."Name" = 'ResolvedById')
        OR (o."Name" = 'Individual' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'KnowledgeArticleFeedback' AND __mj."IntegrationObjectField"."Name" = 'FeedbackSubmitterId')
        OR (o."Name" = 'LandingPage' AND __mj."IntegrationObjectField"."Name" IN ('ContentLastSavedById', 'LastPublishedById'))
        OR (o."Name" = 'LearningItemAssignment' AND __mj."IntegrationObjectField"."Name" = 'AssigneeId')
        OR (o."Name" = 'LearningItemProgress' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'LightningExitByPageMetrics' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'LightningToggleMetrics' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'LightningUsageByAppTypeMetrics' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'LightningUsageByPageMetrics' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'ListViewChart' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'LoginIp' AND __mj."IntegrationObjectField"."Name" = 'UsersId')
        OR (o."Name" = 'MessagingSession' AND __mj."IntegrationObjectField"."Name" = 'TargetUserId')
        OR (o."Name" = 'MobSecurityCertPinEvent' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'MyDomainDiscoverableLogin' AND __mj."IntegrationObjectField"."Name" = 'ExecuteApexHandlerAsId')
        OR (o."Name" = 'NetworkAuthApiSettings' AND __mj."IntegrationObjectField"."Name" IN ('HeadlessDiscoveryExecutionUserId', 'RegistrationExecutionUserId'))
        OR (o."Name" = 'Note' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'NoteAndAttachment' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'OauthToken' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'OauthTokenExchHandlerApp' AND __mj."IntegrationObjectField"."Name" = 'ApexExecutionUserId')
        OR (o."Name" = 'ObjectUserTerritory2View' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'OmniSupervisorConfigUser' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'Opportunity' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'OpportunityLineItemSplit' AND __mj."IntegrationObjectField"."Name" = 'SplitOwnerId')
        OR (o."Name" = 'OpportunitySplit' AND __mj."IntegrationObjectField"."Name" = 'SplitOwnerId')
        OR (o."Name" = 'Order' AND __mj."IntegrationObjectField"."Name" IN ('ActivatedById', 'CompanyAuthorizedById'))
        OR (o."Name" = 'OutgoingEmail' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'OutgoingEmailRelation' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'OwnedContentDocument' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'PaymentIntent' AND __mj."IntegrationObjectField"."Name" = 'SubmittedById')
        OR (o."Name" = 'PendingServiceRouting' AND __mj."IntegrationObjectField"."Name" = 'TransferRequesterId')
        OR (o."Name" = 'PermissionSetAssignment' AND __mj."IntegrationObjectField"."Name" = 'AssigneeId')
        OR (o."Name" = 'PermissionSetLicenseAssign' AND __mj."IntegrationObjectField"."Name" = 'AssigneeId')
        OR (o."Name" = 'PersonAccountOwnerPowerUser' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'PersonTraining' AND __mj."IntegrationObjectField"."Name" = 'AssigneeId')
        OR (o."Name" = 'PickTicket' AND __mj."IntegrationObjectField"."Name" = 'AssignedToId')
        OR (o."Name" = 'PipelineInspectionListView' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'PlatformAction' AND __mj."IntegrationObjectField"."Name" = 'InvokedByUserId')
        OR (o."Name" = 'Problem' AND __mj."IntegrationObjectField"."Name" = 'ResolvedById')
        OR (o."Name" = 'ProcessInstance' AND __mj."IntegrationObjectField"."Name" IN ('LastActorId', 'SubmittedById'))
        OR (o."Name" = 'ProcessInstanceNode' AND __mj."IntegrationObjectField"."Name" = 'LastActorId')
        OR (o."Name" = 'ProfileSkillEndorsement' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'ProfileSkillUser' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'PromptAction' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'PromptVersion' AND __mj."IntegrationObjectField"."Name" = 'PublishedByUserId')
        OR (o."Name" = 'QuickTextUsage' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'RecentFieldChange' AND __mj."IntegrationObjectField"."Name" = 'ValueChangedById')
        OR (o."Name" = 'RecordActionHistory' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'ReturnOrder' AND __mj."IntegrationObjectField"."Name" = 'ReturnedById')
        OR (o."Name" = 'SamlSsoConfig' AND __mj."IntegrationObjectField"."Name" = 'ExecutionUserID')
        OR (o."Name" = 'ServiceRequest' AND __mj."IntegrationObjectField"."Name" = 'AssignedUserId')
        OR (o."Name" = 'ServiceResource' AND __mj."IntegrationObjectField"."Name" = 'RelatedRecordId')
        OR (o."Name" = 'SessionPermSetActivation' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'SfdcPartnerOffer' AND __mj."IntegrationObjectField"."Name" = 'SentToCustomerById')
        OR (o."Name" = 'SfdcPartnerOrder' AND __mj."IntegrationObjectField"."Name" = 'SentByUserId')
        OR (o."Name" = 'SfdcPartnerSbscrOffer' AND __mj."IntegrationObjectField"."Name" = 'RespondingUserId')
        OR (o."Name" = 'Site' AND __mj."IntegrationObjectField"."Name" IN ('AdminId', 'GuestRecordDefaultOwnerId', 'GuestUserId'))
        OR (o."Name" = 'SkillLevelProgress' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'SocialPost' AND __mj."IntegrationObjectField"."Name" IN ('DeletedById', 'HiddenById'))
        OR (o."Name" = 'Solution' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'StagedUnmtchdEmailAddr' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'StampAssignment' AND __mj."IntegrationObjectField"."Name" = 'SubjectId')
        OR (o."Name" = 'SvcCatalogRequest' AND __mj."IntegrationObjectField"."Name" = 'SubmitterId')
        OR (o."Name" = 'Territory2AlignmentLog' AND __mj."IntegrationObjectField"."Name" = 'RunAsId')
        OR (o."Name" = 'ThirdPartyAccountLink' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'ThreatDetectionFeedback' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'TodayGoal' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'UnifiedActivityInsight' AND __mj."IntegrationObjectField"."Name" = 'OwnerId')
        OR (o."Name" = 'UserAppInfo' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'UserDailyMetric' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'UserListView' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'UserMonthlyMetric' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'UserProvAccount' AND __mj."IntegrationObjectField"."Name" = 'SalesforceUserId')
        OR (o."Name" = 'UserProvAccountStaging' AND __mj."IntegrationObjectField"."Name" = 'SalesforceUserId')
        OR (o."Name" = 'UserProvisioningLog' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'UserProvisioningRequest' AND __mj."IntegrationObjectField"."Name" IN ('ManagerId', 'SalesforceUserId'))
        OR (o."Name" = 'UserRelatedRecordContent' AND __mj."IntegrationObjectField"."Name" = 'ContentOwnerId')
        OR (o."Name" = 'UserShare' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'UserTerritory2AssocLog' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'VerificationHistory' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'VideoCall' AND __mj."IntegrationObjectField"."Name" IN ('ConsentedUserId', 'HostId'))
        OR (o."Name" = 'VoiceCall' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'VoiceMailGreeting2Rep' AND __mj."IntegrationObjectField"."Name" = 'RepId')
        OR (o."Name" = 'VoiceVendorLine' AND __mj."IntegrationObjectField"."Name" = 'UserId')
        OR (o."Name" = 'WorkBadge' AND __mj."IntegrationObjectField"."Name" IN ('GiverId', 'RecipientId'))
        OR (o."Name" = 'WorkItem' AND __mj."IntegrationObjectField"."Name" IN ('AssignedToId', 'DevelopmentApprovedById'))
        OR (o."Name" = 'WorkThanks' AND __mj."IntegrationObjectField"."Name" = 'GiverId')
      )
  );

-- Target: UserAccessChange.Id (6 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UserAccessChange'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UserAccessChange'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'UserAccessChange'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PermissionSetAssignment' AND __mj."IntegrationObjectField"."Name" IN ('LastCreatedByChangeId', 'LastDeletedByChangeId'))
        OR (o."Name" = 'PermissionSetLicenseAssign' AND __mj."IntegrationObjectField"."Name" IN ('LastCreatedByChangeId', 'LastDeletedByChangeId'))
        OR (o."Name" = 'UserPackageLicense' AND __mj."IntegrationObjectField"."Name" IN ('LastCreatedByChangeId', 'LastDeletedByChangeId'))
      )
  );

-- Target: UserDefinedLabel.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UserDefinedLabel'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UserDefinedLabel'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'UserDefinedLabel'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'UserDefinedLabelAssignment' AND __mj."IntegrationObjectField"."Name" = 'LabelId')
      )
  );

-- Target: UserEmailPreferredPerson.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UserEmailPreferredPerson'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UserEmailPreferredPerson'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'UserEmailPreferredPerson'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'UserEmailPreferredPersonShare' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
      )
  );

-- Target: UserLicense.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UserLicense'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UserLicense'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'UserLicense'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'ActiveProfileMetric' AND __mj."IntegrationObjectField"."Name" = 'UserLicenseId')
        OR (o."Name" = 'Profile' AND __mj."IntegrationObjectField"."Name" = 'UserLicenseId')
      )
  );

-- Target: UserListView.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UserListView'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UserListView'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'UserListView'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'UserListViewCriterion' AND __mj."IntegrationObjectField"."Name" = 'UserListViewId')
      )
  );

-- Target: UserProvAccount.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UserProvAccount'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UserProvAccount'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'UserProvAccount'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'UserProvisioningRequest' AND __mj."IntegrationObjectField"."Name" = 'UserProvAccountId')
      )
  );

-- Target: UserProvisioningConfig.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UserProvisioningConfig'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UserProvisioningConfig'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'UserProvisioningConfig'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'UserProvisioningRequest' AND __mj."IntegrationObjectField"."Name" = 'UserProvConfigId')
      )
  );

-- Target: UserProvisioningRequest.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UserProvisioningRequest'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UserProvisioningRequest'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'UserProvisioningRequest'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'UserProvisioningLog' AND __mj."IntegrationObjectField"."Name" = 'UserProvisioningRequestId')
      )
  );

-- Target: UserRole.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UserRole'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'UserRole'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'UserRole'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'Name' AND __mj."IntegrationObjectField"."Name" = 'UserRoleId')
        OR (o."Name" = 'RecentlyViewed' AND __mj."IntegrationObjectField"."Name" = 'UserRoleId')
        OR (o."Name" = 'User' AND __mj."IntegrationObjectField"."Name" = 'UserRoleId')
      )
  );

-- Target: VideoCall.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'VideoCall'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'VideoCall'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'VideoCall'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'GenAIConversationSummary' AND __mj."IntegrationObjectField"."Name" = 'ConversationRecordId')
        OR (o."Name" = 'LearningItemSubmission' AND __mj."IntegrationObjectField"."Name" = 'CallId')
        OR (o."Name" = 'UnifiedVideoCall' AND __mj."IntegrationObjectField"."Name" = 'DetailId')
        OR (o."Name" = 'VideoCallParticipant' AND __mj."IntegrationObjectField"."Name" = 'VideoCallId')
        OR (o."Name" = 'VideoCallRecording' AND __mj."IntegrationObjectField"."Name" = 'VideoCallRecordId')
      )
  );

-- Target: VideoCallInsightReason.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'VideoCallInsightReason'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'VideoCallInsightReason'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'VideoCallInsightReason'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'VideoCallInsightAction' AND __mj."IntegrationObjectField"."Name" = 'ActionReferenceId')
      )
  );

-- Target: VideoCallParticipant.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'VideoCallParticipant'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'VideoCallParticipant'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'VideoCallParticipant'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'VideoCallRecordingStructure' AND __mj."IntegrationObjectField"."Name" = 'VideoCallParticipantId')
      )
  );

-- Target: VideoCallRecording.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'VideoCallRecording'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'VideoCallRecording'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'VideoCallRecording'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'VideoCallInsight' AND __mj."IntegrationObjectField"."Name" = 'VideoCallRecordingId')
        OR (o."Name" = 'VideoCallRecordingStructure' AND __mj."IntegrationObjectField"."Name" = 'VideoCallRecordingId')
      )
  );

-- Target: VoiceCall.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'VoiceCall'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'VoiceCall'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'VoiceCall'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AgentWorkConversationalData' AND __mj."IntegrationObjectField"."Name" = 'ChannelSessionRecordId')
        OR (o."Name" = 'UnifiedVoiceCall' AND __mj."IntegrationObjectField"."Name" = 'DetailId')
        OR (o."Name" = 'VoiceCallRecording' AND __mj."IntegrationObjectField"."Name" = 'VoiceCallId')
      )
  );

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'VoiceCallInsightReason'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'VoiceCallInsightReason'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'VoiceCallInsightReason'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'VoiceCallInsightAction' AND __mj."IntegrationObjectField"."Name" = 'ActionReferenceId')
      )
  );

-- Target: VoiceCallRecording.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'VoiceCallRecording'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'VoiceCallRecording'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'VoiceCallRecording'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AgentWorkConversationalData' AND __mj."IntegrationObjectField"."Name" = 'AgentChannelRecordingId')
        OR (o."Name" = 'VoiceCallInsight' AND __mj."IntegrationObjectField"."Name" = 'VoiceCallRecordingId')
      )
  );

-- Target: VoiceMailGreeting2.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'VoiceMailGreeting2'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'VoiceMailGreeting2'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'VoiceMailGreeting2'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'VoiceMailGreeting2Rep' AND __mj."IntegrationObjectField"."Name" = 'VoiceMailGreeting2Id')
      )
  );

-- Target: VoiceVendorInfo.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'VoiceVendorInfo'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'VoiceVendorInfo'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'VoiceVendorInfo'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'VoiceVendorLine' AND __mj."IntegrationObjectField"."Name" = 'VoiceVendorInfoId')
      )
  );

-- Target: VoiceVendorLine.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'VoiceVendorLine'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'VoiceVendorLine'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'VoiceVendorLine'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'VoiceCall' AND __mj."IntegrationObjectField"."Name" = 'VoiceVendorLineId')
      )
  );

-- Target: WebCart.Id (6 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WebCart'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WebCart'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'WebCart'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CartDeliveryGroup' AND __mj."IntegrationObjectField"."Name" = 'CartId')
        OR (o."Name" = 'CartItem' AND __mj."IntegrationObjectField"."Name" = 'CartId')
        OR (o."Name" = 'CartItemPriceAdjustment' AND __mj."IntegrationObjectField"."Name" = 'CartId')
        OR (o."Name" = 'PaymentInitiationSource' AND __mj."IntegrationObjectField"."Name" = 'WebCartId')
        OR (o."Name" = 'WebCartAdjustmentBasis' AND __mj."IntegrationObjectField"."Name" = 'WebCartId')
        OR (o."Name" = 'WebCartAdjustmentGroup' AND __mj."IntegrationObjectField"."Name" = 'CartId')
      )
  );

-- Target: WebCartAdjustmentGroup.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WebCartAdjustmentGroup'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WebCartAdjustmentGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'WebCartAdjustmentGroup'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CartItemPriceAdjustment' AND __mj."IntegrationObjectField"."Name" = 'WebCartAdjustmentGroupId')
      )
  );

-- Target: WebStore.Id (13 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WebStore'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WebStore'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'WebStore'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'CalculatedInsightRangeBound' AND __mj."IntegrationObjectField"."Name" = 'SalesStoreId')
        OR (o."Name" = 'Order' AND __mj."IntegrationObjectField"."Name" = 'SalesStoreId')
        OR (o."Name" = 'OrderSummary' AND __mj."IntegrationObjectField"."Name" = 'SalesStoreId')
        OR (o."Name" = 'PaymentInitiationSource' AND __mj."IntegrationObjectField"."Name" = 'WebStoreId')
        OR (o."Name" = 'PendingOrderSummary' AND __mj."IntegrationObjectField"."Name" = 'SalesStoreId')
        OR (o."Name" = 'PromotionSegmentSalesStore' AND __mj."IntegrationObjectField"."Name" = 'SalesStoreId')
        OR (o."Name" = 'ShippingConfigurationSet' AND __mj."IntegrationObjectField"."Name" = 'TargetRecordId')
        OR (o."Name" = 'WebCart' AND __mj."IntegrationObjectField"."Name" = 'WebStoreId')
        OR (o."Name" = 'WebstoreBuyerGroup' AND __mj."IntegrationObjectField"."Name" = 'WebStoreId')
        OR (o."Name" = 'WebStoreInventorySource' AND __mj."IntegrationObjectField"."Name" = 'WebStoreId')
        OR (o."Name" = 'WebStoreNetwork' AND __mj."IntegrationObjectField"."Name" = 'WebStoreId')
        OR (o."Name" = 'WebStoreSearchProdSettings' AND __mj."IntegrationObjectField"."Name" = 'WebStoreId')
        OR (o."Name" = 'WebStoreShare' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
      )
  );

-- Target: WorkAccess.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WorkAccess'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WorkAccess'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'WorkAccess'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'WorkAccessShare' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
      )
  );

-- Target: WorkBadgeDefinition.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WorkBadgeDefinition'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WorkBadgeDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'WorkBadgeDefinition'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'WorkAccess' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
        OR (o."Name" = 'WorkBadge' AND __mj."IntegrationObjectField"."Name" = 'DefinitionId')
      )
  );

-- Target: WorkDemographic.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WorkDemographic'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WorkDemographic'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'WorkDemographic'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'WorkforceCapacityUnit' AND __mj."IntegrationObjectField"."Name" = 'WorkDemographicId')
        OR (o."Name" = 'WorkloadUnit' AND __mj."IntegrationObjectField"."Name" = 'WorkDemographicId')
      )
  );

-- Target: WorkforceCapacity.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WorkforceCapacity'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WorkforceCapacity'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'WorkforceCapacity'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'WorkforceCapacityUnit' AND __mj."IntegrationObjectField"."Name" = 'WorkforceCapacityId')
      )
  );

-- Target: WorkItem.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WorkItem'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WorkItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'WorkItem'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'DevopsActivityLog' AND __mj."IntegrationObjectField"."Name" = 'WorkItemId')
        OR (o."Name" = 'DevopsPipelnStgPromWkItem' AND __mj."IntegrationObjectField"."Name" = 'WorkItemId')
      )
  );

-- Target: Workload.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Workload'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'Workload'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'Workload'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'WorkforceCapacity' AND __mj."IntegrationObjectField"."Name" = 'WorkloadId')
        OR (o."Name" = 'WorkloadUnit' AND __mj."IntegrationObjectField"."Name" = 'WorkloadId')
      )
  );

-- Target: WorkOrder.Id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WorkOrder'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WorkOrder'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'WorkOrder'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PaymentInitiationSource' AND __mj."IntegrationObjectField"."Name" = 'WorkOrderId')
        OR (o."Name" = 'ProductRequest' AND __mj."IntegrationObjectField"."Name" = 'WorkOrderId')
        OR (o."Name" = 'ProductRequestLineItem' AND __mj."IntegrationObjectField"."Name" = 'WorkOrderId')
        OR (o."Name" = 'WorkOrderHistory' AND __mj."IntegrationObjectField"."Name" = 'WorkOrderId')
        OR (o."Name" = 'WorkOrderLineItem' AND __mj."IntegrationObjectField"."Name" = 'WorkOrderId')
        OR (o."Name" = 'WorkOrderShare' AND __mj."IntegrationObjectField"."Name" = 'ParentId')
        OR (o."Name" = 'WorkPlan' AND __mj."IntegrationObjectField"."Name" = 'WorkOrderId')
      )
  );

-- Target: WorkOrderLineItem.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WorkOrderLineItem'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WorkOrderLineItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'WorkOrderLineItem'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'PaymentInitiationSource' AND __mj."IntegrationObjectField"."Name" = 'WorkOrderLineItemId')
        OR (o."Name" = 'ProductRequest' AND __mj."IntegrationObjectField"."Name" = 'WorkOrderLineItemId')
        OR (o."Name" = 'ProductRequestLineItem' AND __mj."IntegrationObjectField"."Name" = 'WorkOrderLineItemId')
        OR (o."Name" = 'WorkOrderLineItemHistory' AND __mj."IntegrationObjectField"."Name" = 'WorkOrderLineItemId')
        OR (o."Name" = 'WorkPlan' AND __mj."IntegrationObjectField"."Name" = 'WorkOrderLineItemId')
      )
  );

-- Target: WorkPlanTemplate.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WorkPlanTemplate'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WorkPlanTemplate'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'WorkPlanTemplate'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'WorkPlan' AND __mj."IntegrationObjectField"."Name" = 'WorkPlanTemplateId')
      )
  );

-- Target: WorkThanks.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WorkThanks'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WorkThanks'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'WorkThanks'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'WorkBadge' AND __mj."IntegrationObjectField"."Name" = 'SourceId')
      )
  );

-- Target: WorkType.Id (6 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WorkType'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WorkType'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'WorkType'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AppointmentTopicTimeSlot' AND __mj."IntegrationObjectField"."Name" = 'WorkTypeId')
        OR (o."Name" = 'ServiceAppointment' AND __mj."IntegrationObjectField"."Name" = 'WorkTypeId')
        OR (o."Name" = 'ServiceTerritoryWorkType' AND __mj."IntegrationObjectField"."Name" = 'WorkTypeId')
        OR (o."Name" = 'WorkOrder' AND __mj."IntegrationObjectField"."Name" = 'WorkTypeId')
        OR (o."Name" = 'WorkOrderLineItem' AND __mj."IntegrationObjectField"."Name" = 'WorkTypeId')
        OR (o."Name" = 'WorkTypeGroupMember' AND __mj."IntegrationObjectField"."Name" = 'WorkTypeId')
      )
  );

-- Target: WorkTypeGroup.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = COALESCE(
      "RelatedIntegrationObjectID",
      (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WorkTypeGroup'
      )
    ),
    "RelatedIntegrationObjectFieldName" = COALESCE("RelatedIntegrationObjectFieldName", 'Id')
WHERE (
    "RelatedIntegrationObjectID" IS NULL
    OR (
      "RelatedIntegrationObjectFieldName" IS NULL
      AND "RelatedIntegrationObjectID" = (
        SELECT t."ID"
        FROM __mj."IntegrationObject" t
        INNER JOIN __mj."IntegrationObject" s ON s."IntegrationID" = t."IntegrationID"
        WHERE s."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
          AND t."Name" = 'WorkTypeGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM __mj."IntegrationObject" o
    INNER JOIN __mj."Integration" i ON i."ID" = o."IntegrationID"
    INNER JOIN __mj."IntegrationObject" t ON t."IntegrationID" = i."ID" AND t."Name" = 'WorkTypeGroup'
    WHERE o."ID" = __mj."IntegrationObjectField"."IntegrationObjectID"
      AND LOWER(i."Name") = 'salesforce'
      AND (
        (o."Name" = 'AppointmentTopicTimeSlot' AND __mj."IntegrationObjectField"."Name" = 'WorkTypeGroupId')
        OR (o."Name" = 'QuoteLineWorkSource' AND __mj."IntegrationObjectField"."Name" = 'WorkTypeGroupId')
        OR (o."Name" = 'TimeSlot' AND __mj."IntegrationObjectField"."Name" = 'WorkTypeGroupId')
        OR (o."Name" = 'WorkTypeGroupMember' AND __mj."IntegrationObjectField"."Name" = 'WorkTypeGroupId')
      )
  );


-- ===================== Other =====================

-- CRM/Salesforce: wire 1509 declared DAG-safe scalar foreign-key relationship(s) into IntegrationObjectField.
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

-- Target: AbnExperiment.Id (1 field(s))

-- Target: ApexTestQueueItem.Id (1 field(s))

-- Target: AutomatedAction.Id (3 field(s))

-- Target: CallCtrAgentFavTrfrDest.Id (1 field(s))

-- Target: ContentDocument.Id (17 field(s))

-- Target: DataDetectPolicy.Id (7 field(s))

-- Target: EnablementProgram.Id (4 field(s))

-- Target: FlowOrchestration.Id (4 field(s))

-- Target: Idea.Id (1 field(s))

-- Target: ManagedContent.Id (5 field(s))

-- Target: Order.Id (18 field(s))

-- Target: PaymentSchedulePolicy.Id (1 field(s))

-- Target: ProcessNode.Id (2 field(s))

-- Target: QuoteAction.Id (1 field(s))

-- Target: ServicePresenceStatus.Id (3 field(s))

-- Target: Solution.Id (1 field(s))

-- Target: UnifiedActivityInsight.Id (1 field(s))

-- Target: VoiceCallInsightReason.Id (1 field(s))
