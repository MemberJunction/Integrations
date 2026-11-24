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
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AbnExperiment'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AbnExperiment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AbnExperiment'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PersonalizationPoint' AND [__mj].[IntegrationObjectField].[Name] = N'AbnExperimentId')
      )
  );

-- Target: Account.Id (73 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Account'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Account'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Account'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AccountContactRole' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'AccountPartner' AND [__mj].[IntegrationObjectField].[Name] IN (N'AccountFromId', N'AccountToId'))
        OR (o.[Name] = N'AccountPlan' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'AccountShare' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'ActivityHistory' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'AlternativePaymentMethod' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'Asset' AND [__mj].[IntegrationObjectField].[Name] IN (N'AccountId', N'AssetProvidedById', N'AssetServicedById'))
        OR (o.[Name] = N'BillingSchedule' AND [__mj].[IntegrationObjectField].[Name] = N'BillingAccountId')
        OR (o.[Name] = N'BillingScheduleGroup' AND [__mj].[IntegrationObjectField].[Name] = N'BillingAccountId')
        OR (o.[Name] = N'BuyerAccount' AND [__mj].[IntegrationObjectField].[Name] IN (N'BuyerId', N'PayerId', N'SendToId'))
        OR (o.[Name] = N'CampaignMember' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'CardPaymentMethod' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'Case' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'Contact' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'Contract' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'CreditMemo' AND [__mj].[IntegrationObjectField].[Name] = N'BillingAccountId')
        OR (o.[Name] = N'DealIndirectPartner' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'DelegatedAccount' AND [__mj].[IntegrationObjectField].[Name] IN (N'ParentId', N'TargetId'))
        OR (o.[Name] = N'DigitalWallet' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'EmpUserProvisionProcessErr' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'Event' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'ExtlRecShrCnctAccnt' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'FulfillmentOrder' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'Invoice' AND [__mj].[IntegrationObjectField].[Name] = N'BillingAccountId')
        OR (o.[Name] = N'Lead' AND [__mj].[IntegrationObjectField].[Name] = N'ConvertedAccountId')
        OR (o.[Name] = N'LogoutEventStream' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'LookedUpFromActivity' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'MessagingEndUser' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'MessagingSession' AND [__mj].[IntegrationObjectField].[Name] = N'EndUserAccountId')
        OR (o.[Name] = N'OpenActivity' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'Opportunity' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'OpportunityPartner' AND [__mj].[IntegrationObjectField].[Name] = N'AccountToId')
        OR (o.[Name] = N'Order' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'OrderSummary' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'Partner' AND [__mj].[IntegrationObjectField].[Name] IN (N'AccountFromId', N'AccountToId'))
        OR (o.[Name] = N'Payment' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'PaymentAuthAdjustment' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'PaymentAuthorization' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'PaymentCredit' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'PaymentCreditLinePayment' AND [__mj].[IntegrationObjectField].[Name] = N'AssociatedAccountId')
        OR (o.[Name] = N'PaymentCreditTransaction' AND [__mj].[IntegrationObjectField].[Name] = N'AssociatedAccountId')
        OR (o.[Name] = N'PaymentInitiationSource' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'PaymentIntent' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'PaymentLineInvoice' AND [__mj].[IntegrationObjectField].[Name] = N'AssociatedAccountId')
        OR (o.[Name] = N'PaymentLink' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'PaymentMethod' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'PaymentSchedule' AND [__mj].[IntegrationObjectField].[Name] = N'DefaultPaymentAccountId')
        OR (o.[Name] = N'PaymentScheduleItem' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentAccountId')
        OR (o.[Name] = N'PendingOrderSummary' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'PriceProtectExecLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'ProductDetectedPriceChange' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'ProductRequest' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'ProductRequestLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'Prospect' AND [__mj].[IntegrationObjectField].[Name] = N'ConvertedAccountId')
        OR (o.[Name] = N'PublicComplaint' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'Quote' AND [__mj].[IntegrationObjectField].[Name] = N'QuoteAccountId')
        OR (o.[Name] = N'Refund' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'RefundLinePayment' AND [__mj].[IntegrationObjectField].[Name] = N'AssociatedAccountId')
        OR (o.[Name] = N'ReturnOrder' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'SalesTransactionShape' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'ServiceAppointment' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'SfdcCustomerForPartner' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'Task' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'Territory2ObjectExclusion' AND [__mj].[IntegrationObjectField].[Name] = N'ObjectId')
        OR (o.[Name] = N'WebCart' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
        OR (o.[Name] = N'WorkOrder' AND [__mj].[IntegrationObjectField].[Name] = N'AccountId')
      )
  );

-- Target: AccountPlan.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AccountPlan'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AccountPlan'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AccountPlan'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AccountPlanObjective' AND [__mj].[IntegrationObjectField].[Name] = N'AccountPlanId')
      )
  );

-- Target: AccountPlanObjective.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AccountPlanObjective'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AccountPlanObjective'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AccountPlanObjective'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AccountPlanObjectiveMeasure' AND [__mj].[IntegrationObjectField].[Name] = N'AccountPlanObjectiveId')
      )
  );

-- Target: AccountPlanObjMeasCalcDef.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AccountPlanObjMeasCalcDef'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AccountPlanObjMeasCalcDef'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AccountPlanObjMeasCalcDef'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AccountPlanObjectiveMeasure' AND [__mj].[IntegrationObjectField].[Name] = N'AccountPlanObjMeasCalcDefId')
        OR (o.[Name] = N'AccountPlanObjMeasCalcCond' AND [__mj].[IntegrationObjectField].[Name] = N'AccountPlanObjMeasCalcDefId')
      )
  );

-- Target: ActionCadence.Id (5 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ActionCadence'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ActionCadence'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ActionCadence'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'Account' AND [__mj].[IntegrationObjectField].[Name] = N'PersonActionCadenceId')
        OR (o.[Name] = N'ActionCadenceStep' AND [__mj].[IntegrationObjectField].[Name] IN (N'ActionCadenceId', N'ChainedCadenceId'))
        OR (o.[Name] = N'ActionCadenceStepTracker' AND [__mj].[IntegrationObjectField].[Name] = N'ActionCadenceId')
        OR (o.[Name] = N'ActionCadenceTracker' AND [__mj].[IntegrationObjectField].[Name] = N'ActionCadenceId')
      )
  );

-- Target: ActionCadenceRule.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ActionCadenceRule'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ActionCadenceRule'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ActionCadenceRule'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ActionCadenceTracker' AND [__mj].[IntegrationObjectField].[Name] = N'ExitGlobalRuleId')
      )
  );

-- Target: ActionCadenceStep.Id (5 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ActionCadenceStep'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ActionCadenceStep'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ActionCadenceStep'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ActionCadenceRule' AND [__mj].[IntegrationObjectField].[Name] = N'ActionCadenceStepId')
        OR (o.[Name] = N'ActionCadenceStepTracker' AND [__mj].[IntegrationObjectField].[Name] = N'ActionCadenceStepId')
        OR (o.[Name] = N'ActionCadenceStepVariant' AND [__mj].[IntegrationObjectField].[Name] = N'ActionCadenceStepId')
        OR (o.[Name] = N'ActionCdncStpMonthlyMetric' AND [__mj].[IntegrationObjectField].[Name] = N'ActionCadenceStepId')
        OR (o.[Name] = N'ListEmail' AND [__mj].[IntegrationObjectField].[Name] = N'ActionCadenceStepId')
      )
  );

-- Target: ActionCadenceStepTracker.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ActionCadenceStepTracker'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ActionCadenceStepTracker'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ActionCadenceStepTracker'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ListEmailIndividualRecipient' AND [__mj].[IntegrationObjectField].[Name] = N'ActionCadenceStepTrackerId')
        OR (o.[Name] = N'ListEmailSentResult' AND [__mj].[IntegrationObjectField].[Name] = N'ActionCadenceStepTrackerId')
      )
  );

-- Target: ActionCadenceTracker.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ActionCadenceTracker'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ActionCadenceTracker'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ActionCadenceTracker'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ActionCadenceStepTracker' AND [__mj].[IntegrationObjectField].[Name] = N'ActionCadenceTrackerId')
      )
  );

-- Target: ActionLinkGroupTemplate.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ActionLinkGroupTemplate'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ActionLinkGroupTemplate'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ActionLinkGroupTemplate'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ActionLinkTemplate' AND [__mj].[IntegrationObjectField].[Name] = N'ActionLinkGroupTemplateId')
      )
  );

-- Target: ActivityMetric.Id (5 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ActivityMetric'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ActivityMetric'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ActivityMetric'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'Account' AND [__mj].[IntegrationObjectField].[Name] = N'ActivityMetricId')
        OR (o.[Name] = N'Contact' AND [__mj].[IntegrationObjectField].[Name] = N'ActivityMetricId')
        OR (o.[Name] = N'Contract' AND [__mj].[IntegrationObjectField].[Name] = N'ActivityMetricId')
        OR (o.[Name] = N'Lead' AND [__mj].[IntegrationObjectField].[Name] = N'ActivityMetricId')
        OR (o.[Name] = N'Opportunity' AND [__mj].[IntegrationObjectField].[Name] = N'ActivityMetricId')
      )
  );

-- Target: AgentWork.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AgentWork'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AgentWork'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AgentWork'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AgentWorkConversationalData' AND [__mj].[IntegrationObjectField].[Name] = N'AgentWorkId')
      )
  );

-- Target: AIApplication.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AIApplication'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AIApplication'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AIApplication'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AIRecordInsight' AND [__mj].[IntegrationObjectField].[Name] = N'AiApplicationId')
      )
  );

-- Target: AiGenActionItem.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AiGenActionItem'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AiGenActionItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AiGenActionItem'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AIResearchPromptResult' AND [__mj].[IntegrationObjectField].[Name] = N'AiGenActionItemId')
      )
  );

-- Target: AIInsightAction.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AIInsightAction'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AIInsightAction'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AIInsightAction'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AIInsightValue' AND [__mj].[IntegrationObjectField].[Name] = N'AiInsightActionId')
      )
  );

-- Target: AIInsightValue.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AIInsightValue'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AIInsightValue'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AIInsightValue'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AIInsightReason' AND [__mj].[IntegrationObjectField].[Name] = N'AiInsightValueId')
      )
  );

-- Target: AiJobRun.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AiJobRun'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AiJobRun'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AiJobRun'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AiJobRunItem' AND [__mj].[IntegrationObjectField].[Name] = N'AiJobRunId')
      )
  );

-- Target: AIRecordInsight.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AIRecordInsight'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AIRecordInsight'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AIRecordInsight'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AIInsightAction' AND [__mj].[IntegrationObjectField].[Name] = N'AiRecordInsightId')
        OR (o.[Name] = N'AIInsightFeedback' AND [__mj].[IntegrationObjectField].[Name] = N'AiRecordInsightId')
        OR (o.[Name] = N'AIInsightValue' AND [__mj].[IntegrationObjectField].[Name] = N'AiRecordInsightId')
      )
  );

-- Target: AnalyticsDashboardWidget.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AnalyticsDashboardWidget'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AnalyticsDashboardWidget'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AnalyticsDashboardWidget'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AnalyticsContainerWidgetDef' AND [__mj].[IntegrationObjectField].[Name] = N'AnalyticsDashboardWidgetId')
      )
  );

-- Target: AnalyticsVisualization.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AnalyticsVisualization'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AnalyticsVisualization'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AnalyticsVisualization'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AnalyticsVizViewDef' AND [__mj].[IntegrationObjectField].[Name] = N'VisualizationId')
      )
  );

-- Target: AnalyticsWorkspace.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AnalyticsWorkspace'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AnalyticsWorkspace'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AnalyticsWorkspace'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AnalyticsDashboard' AND [__mj].[IntegrationObjectField].[Name] = N'AnalyticsWorkspaceId')
        OR (o.[Name] = N'AnalyticsVisualization' AND [__mj].[IntegrationObjectField].[Name] = N'AnalyticsWorkspaceId')
      )
  );

-- Target: ApexClass.Id (16 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ApexClass'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ApexClass'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ApexClass'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ApexTestQueueItem' AND [__mj].[IntegrationObjectField].[Name] = N'ApexClassId')
        OR (o.[Name] = N'ApexTestResult' AND [__mj].[IntegrationObjectField].[Name] = N'ApexClassId')
        OR (o.[Name] = N'ApexTypeImplementor' AND [__mj].[IntegrationObjectField].[Name] IN (N'ApexClassId', N'InterfaceApexClassId'))
        OR (o.[Name] = N'AppointmentSchedulingPolicy' AND [__mj].[IntegrationObjectField].[Name] = N'ExtCalEventHandlerId')
        OR (o.[Name] = N'AsyncApexJob' AND [__mj].[IntegrationObjectField].[Name] = N'ApexClassId')
        OR (o.[Name] = N'LearningItemType' AND [__mj].[IntegrationObjectField].[Name] IN (N'ApexEvaluationHandlerId', N'ApexSerializerDeserializerId'))
        OR (o.[Name] = N'MyDomainDiscoverableLogin' AND [__mj].[IntegrationObjectField].[Name] = N'ApexHandlerId')
        OR (o.[Name] = N'NetworkAuthApiSettings' AND [__mj].[IntegrationObjectField].[Name] IN (N'HeadlessDiscoveryHandlerId', N'RegistrationHandlerId'))
        OR (o.[Name] = N'OauthTokenExchangeHandler' AND [__mj].[IntegrationObjectField].[Name] = N'TokenHandlerApexId')
        OR (o.[Name] = N'PaymentGatewayProvider' AND [__mj].[IntegrationObjectField].[Name] = N'ApexAdapterId')
        OR (o.[Name] = N'SamlSsoConfig' AND [__mj].[IntegrationObjectField].[Name] = N'SamlJitHandlerId')
        OR (o.[Name] = N'TaxEngineProvider' AND [__mj].[IntegrationObjectField].[Name] = N'ApexAdapterId')
        OR (o.[Name] = N'TestSuiteMembership' AND [__mj].[IntegrationObjectField].[Name] = N'ApexClassId')
      )
  );

-- Target: ApexLog.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ApexLog'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ApexLog'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ApexLog'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ApexTestResult' AND [__mj].[IntegrationObjectField].[Name] = N'ApexLogId')
      )
  );

-- Target: ApexPage.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ApexPage'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ApexPage'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ApexPage'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'LiveChatButton' AND [__mj].[IntegrationObjectField].[Name] IN (N'ChatPageId', N'PostchatPageId', N'PrechatFormPageId'))
        OR (o.[Name] = N'VisualforceAccessMetrics' AND [__mj].[IntegrationObjectField].[Name] = N'ApexPageId')
      )
  );

GO

-- Target: ApexTestQueueItem.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ApexTestQueueItem'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ApexTestQueueItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ApexTestQueueItem'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ApexTestResult' AND [__mj].[IntegrationObjectField].[Name] = N'QueueItemId')
      )
  );

-- Target: ApexTestResult.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ApexTestResult'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ApexTestResult'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ApexTestResult'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ApexTestResultLimits' AND [__mj].[IntegrationObjectField].[Name] = N'ApexTestResultId')
      )
  );

-- Target: ApexTestRunResult.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ApexTestRunResult'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ApexTestRunResult'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ApexTestRunResult'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ApexTestResult' AND [__mj].[IntegrationObjectField].[Name] = N'ApexTestRunResultId')
      )
  );

-- Target: ApexTestSuite.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ApexTestSuite'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ApexTestSuite'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ApexTestSuite'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'TestSuiteMembership' AND [__mj].[IntegrationObjectField].[Name] = N'ApexTestSuiteId')
      )
  );

-- Target: AppDefinition.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AppDefinition'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AppDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AppDefinition'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'UserAppInfo' AND [__mj].[IntegrationObjectField].[Name] = N'AppDefinitionId')
      )
  );

-- Target: AppMenuItem.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AppMenuItem'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AppMenuItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AppMenuItem'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'OauthToken' AND [__mj].[IntegrationObjectField].[Name] = N'AppMenuItemId')
      )
  );

-- Target: AppointmentAssignmentPolicy.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AppointmentAssignmentPolicy'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AppointmentAssignmentPolicy'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AppointmentAssignmentPolicy'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AppointmentSchedulingPolicy' AND [__mj].[IntegrationObjectField].[Name] = N'AppointmentAssignmentPolicyId')
      )
  );

-- Target: AppointmentScheduleAggr.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AppointmentScheduleAggr'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AppointmentScheduleAggr'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AppointmentScheduleAggr'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AppointmentScheduleLog' AND [__mj].[IntegrationObjectField].[Name] = N'AppointmentScheduleAggrId')
      )
  );

-- Target: ApprovalWorkItem.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ApprovalWorkItem'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ApprovalWorkItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ApprovalWorkItem'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ApprovalSubmissionDetail' AND [__mj].[IntegrationObjectField].[Name] = N'ApprovalWorkItemId')
      )
  );

-- Target: ApptBundleAggrPolicy.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ApptBundleAggrPolicy'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ApptBundleAggrPolicy'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ApptBundleAggrPolicy'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ApptBundleAggrDurDnscale' AND [__mj].[IntegrationObjectField].[Name] = N'BundleAggregationPolicyId')
      )
  );

-- Target: ApptBundlePolicy.Id (6 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ApptBundlePolicy'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ApptBundlePolicy'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ApptBundlePolicy'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ApptBundleAggrPolicy' AND [__mj].[IntegrationObjectField].[Name] = N'BundlePolicyId')
        OR (o.[Name] = N'ApptBundlePolicySvcTerr' AND [__mj].[IntegrationObjectField].[Name] = N'BundlePolicyId')
        OR (o.[Name] = N'ApptBundlePropagatePolicy' AND [__mj].[IntegrationObjectField].[Name] = N'BundlePolicyId')
        OR (o.[Name] = N'ApptBundleRestrictPolicy' AND [__mj].[IntegrationObjectField].[Name] = N'BundlePolicyId')
        OR (o.[Name] = N'ApptBundleSortPolicy' AND [__mj].[IntegrationObjectField].[Name] = N'BundlePolicyId')
        OR (o.[Name] = N'ServiceAppointment' AND [__mj].[IntegrationObjectField].[Name] = N'BundlePolicyId')
      )
  );

-- Target: Asset.Id (20 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Asset'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Asset'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Asset'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AssetAction' AND [__mj].[IntegrationObjectField].[Name] = N'AssetId')
        OR (o.[Name] = N'AssetAttribute' AND [__mj].[IntegrationObjectField].[Name] = N'AssetId')
        OR (o.[Name] = N'AssetContractRelationship' AND [__mj].[IntegrationObjectField].[Name] = N'AssetId')
        OR (o.[Name] = N'AssetRateCardEntry' AND [__mj].[IntegrationObjectField].[Name] = N'BindingObjectId')
        OR (o.[Name] = N'AssetRelationship' AND [__mj].[IntegrationObjectField].[Name] IN (N'AssetId', N'RelatedAssetId'))
        OR (o.[Name] = N'AssetShare' AND [__mj].[IntegrationObjectField].[Name] = N'AssetId')
        OR (o.[Name] = N'AssetStatePeriod' AND [__mj].[IntegrationObjectField].[Name] = N'AssetId')
        OR (o.[Name] = N'BillingScheduleGroup' AND [__mj].[IntegrationObjectField].[Name] = N'ReferenceEntityId')
        OR (o.[Name] = N'ChangeRequestRelatedItem' AND [__mj].[IntegrationObjectField].[Name] = N'AssetId')
        OR (o.[Name] = N'IncidentRelatedItem' AND [__mj].[IntegrationObjectField].[Name] = N'AssetId')
        OR (o.[Name] = N'OrderAction' AND [__mj].[IntegrationObjectField].[Name] = N'SourceAssetId')
        OR (o.[Name] = N'OrderItemSummary' AND [__mj].[IntegrationObjectField].[Name] = N'AssetId')
        OR (o.[Name] = N'ProblemRelatedItem' AND [__mj].[IntegrationObjectField].[Name] = N'AssetId')
        OR (o.[Name] = N'QuoteAction' AND [__mj].[IntegrationObjectField].[Name] = N'SourceAssetId')
        OR (o.[Name] = N'QuoteLineWorkSource' AND [__mj].[IntegrationObjectField].[Name] = N'AssetId')
        OR (o.[Name] = N'RecordsetFltrCritMonitor' AND [__mj].[IntegrationObjectField].[Name] = N'AssetId')
        OR (o.[Name] = N'ReturnOrderLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'AssetId')
        OR (o.[Name] = N'WorkOrder' AND [__mj].[IntegrationObjectField].[Name] = N'AssetId')
        OR (o.[Name] = N'WorkOrderLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'AssetId')
      )
  );

-- Target: AssetAction.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AssetAction'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AssetAction'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AssetAction'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AssetActionSource' AND [__mj].[IntegrationObjectField].[Name] = N'AssetActionId')
      )
  );

-- Target: AsyncApexJob.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AsyncApexJob'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AsyncApexJob'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AsyncApexJob'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ApexTestResult' AND [__mj].[IntegrationObjectField].[Name] = N'AsyncApexJobId')
        OR (o.[Name] = N'ApexTestRunResult' AND [__mj].[IntegrationObjectField].[Name] = N'AsyncApexJobId')
        OR (o.[Name] = N'FlexQueueItem' AND [__mj].[IntegrationObjectField].[Name] = N'AsyncApexJobId')
      )
  );

-- Target: AsyncOperationLog.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AsyncOperationLog'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AsyncOperationLog'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AsyncOperationLog'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'OSAsyncChgCompletedEvent' AND [__mj].[IntegrationObjectField].[Name] = N'AsyncOperationLogId')
      )
  );

-- Target: AsyncOperationTracker.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AsyncOperationTracker'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AsyncOperationTracker'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AsyncOperationTracker'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AsyncOpSyndicationFeedFile' AND [__mj].[IntegrationObjectField].[Name] = N'AsyncOperationTrackerId')
        OR (o.[Name] = N'ProcessException' AND [__mj].[IntegrationObjectField].[Name] = N'GroupById')
        OR (o.[Name] = N'RevenueTransactionErrorLog' AND [__mj].[IntegrationObjectField].[Name] = N'AsyncOperationTrackerId')
      )
  );

-- Target: AttributeDefinition.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AttributeDefinition'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AttributeDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AttributeDefinition'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AssetAttribute' AND [__mj].[IntegrationObjectField].[Name] = N'AttributeDefinitionId')
        OR (o.[Name] = N'AssetStatePeriodAttribute' AND [__mj].[IntegrationObjectField].[Name] = N'AttributeDefinitionId')
        OR (o.[Name] = N'CartItemAttribute' AND [__mj].[IntegrationObjectField].[Name] = N'AttributeDefinitionId')
      )
  );

-- Target: AttributePicklist.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AttributePicklist'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AttributePicklist'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AttributePicklist'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AttributeDefinition' AND [__mj].[IntegrationObjectField].[Name] = N'PicklistId')
        OR (o.[Name] = N'AttributePicklistValue' AND [__mj].[IntegrationObjectField].[Name] = N'PicklistId')
      )
  );

-- Target: AttributePicklistValue.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AttributePicklistValue'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AttributePicklistValue'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AttributePicklistValue'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AssetAttribute' AND [__mj].[IntegrationObjectField].[Name] = N'AttributePicklistValueId')
        OR (o.[Name] = N'AssetStatePeriodAttribute' AND [__mj].[IntegrationObjectField].[Name] = N'AttributePicklistValueId')
        OR (o.[Name] = N'CartItemAttribute' AND [__mj].[IntegrationObjectField].[Name] = N'AttributePicklistValueId')
      )
  );

-- Target: AuraDefinitionBundle.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AuraDefinitionBundle'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AuraDefinitionBundle'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AuraDefinitionBundle'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AuraDefinition' AND [__mj].[IntegrationObjectField].[Name] = N'AuraDefinitionBundleId')
      )
  );

-- Target: AuthConfig.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AuthConfig'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AuthConfig'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AuthConfig'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AuthConfigProviders' AND [__mj].[IntegrationObjectField].[Name] = N'AuthConfigId')
      )
  );

-- Target: AuthorizationForm.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AuthorizationForm'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AuthorizationForm'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AuthorizationForm'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AuthorizationFormDataUse' AND [__mj].[IntegrationObjectField].[Name] = N'AuthorizationFormId')
        OR (o.[Name] = N'AuthorizationFormText' AND [__mj].[IntegrationObjectField].[Name] = N'AuthorizationFormId')
      )
  );

-- Target: AuthorizationFormText.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AuthorizationFormText'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AuthorizationFormText'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AuthorizationFormText'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AuthorizationFormConsent' AND [__mj].[IntegrationObjectField].[Name] = N'AuthorizationFormTextId')
      )
  );

-- Target: AuthProvider.Id (6 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AuthProvider'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AuthProvider'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AuthProvider'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AuthProvParamFwdAllowlist' AND [__mj].[IntegrationObjectField].[Name] = N'AuthProviderId')
        OR (o.[Name] = N'ExternalClientApplication' AND [__mj].[IntegrationObjectField].[Name] = N'AuthProviderId')
        OR (o.[Name] = N'ExternalDataSource' AND [__mj].[IntegrationObjectField].[Name] = N'AuthProviderId')
        OR (o.[Name] = N'ExternalDataUserAuth' AND [__mj].[IntegrationObjectField].[Name] = N'AuthProviderId')
        OR (o.[Name] = N'NamedCredential' AND [__mj].[IntegrationObjectField].[Name] = N'AuthProviderId')
        OR (o.[Name] = N'ThirdPartyAccountLink' AND [__mj].[IntegrationObjectField].[Name] = N'SsoProviderId')
      )
  );

-- Target: AuthSession.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AuthSession'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AuthSession'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AuthSession'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'SessionPermSetActivation' AND [__mj].[IntegrationObjectField].[Name] = N'AuthSessionId')
      )
  );

GO

-- Target: AutomatedAction.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AutomatedAction'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AutomatedAction'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AutomatedAction'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AutomatedActionCondition' AND [__mj].[IntegrationObjectField].[Name] = N'AutomatedActionId')
        OR (o.[Name] = N'AutomatedActionParameter' AND [__mj].[IntegrationObjectField].[Name] = N'AutomatedActionId')
        OR (o.[Name] = N'AutomatedActionReminder' AND [__mj].[IntegrationObjectField].[Name] = N'AutomatedActionId')
      )
  );

-- Target: BillingBatchScheduler.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BillingBatchScheduler'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BillingBatchScheduler'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'BillingBatchScheduler'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'InvoiceBatchRun' AND [__mj].[IntegrationObjectField].[Name] = N'BillingBatchSchedulerId')
      )
  );

-- Target: BillingPolicy.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BillingPolicy'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BillingPolicy'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'BillingPolicy'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'BillingTreatment' AND [__mj].[IntegrationObjectField].[Name] = N'BillingPolicyId')
        OR (o.[Name] = N'Product2' AND [__mj].[IntegrationObjectField].[Name] = N'BillingPolicyId')
      )
  );

-- Target: BillingSchedule.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BillingSchedule'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BillingSchedule'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'BillingSchedule'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'BillingPeriodItem' AND [__mj].[IntegrationObjectField].[Name] = N'BillingScheduleId')
        OR (o.[Name] = N'InvoiceLine' AND [__mj].[IntegrationObjectField].[Name] = N'BillingScheduleId')
      )
  );

-- Target: BillingScheduleGroup.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BillingScheduleGroup'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BillingScheduleGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'BillingScheduleGroup'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'BillingSchedule' AND [__mj].[IntegrationObjectField].[Name] = N'BillingScheduleGroupId')
        OR (o.[Name] = N'InvoiceLine' AND [__mj].[IntegrationObjectField].[Name] = N'BillingScheduleGroupId')
        OR (o.[Name] = N'RevenueTransactionErrorLog' AND [__mj].[IntegrationObjectField].[Name] = N'BillingScheduleGroupId')
      )
  );

-- Target: BillingTreatment.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BillingTreatment'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BillingTreatment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'BillingTreatment'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'BillingTreatmentItem' AND [__mj].[IntegrationObjectField].[Name] = N'BillingTreatmentId')
      )
  );

-- Target: BillingTreatmentItem.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BillingTreatmentItem'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BillingTreatmentItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'BillingTreatmentItem'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'BillingSchedule' AND [__mj].[IntegrationObjectField].[Name] = N'BillingTreatmentItemId')
      )
  );

-- Target: BotDefinition.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BotDefinition'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BotDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'BotDefinition'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AgentWork' AND [__mj].[IntegrationObjectField].[Name] = N'BotId')
        OR (o.[Name] = N'AiGenActionItem' AND [__mj].[IntegrationObjectField].[Name] = N'BotDefinitionId')
        OR (o.[Name] = N'BotVersion' AND [__mj].[IntegrationObjectField].[Name] = N'BotDefinitionId')
        OR (o.[Name] = N'PendingServiceRouting' AND [__mj].[IntegrationObjectField].[Name] = N'BotId')
      )
  );

-- Target: BotVersion.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BotVersion'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BotVersion'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'BotVersion'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AiGenActionItem' AND [__mj].[IntegrationObjectField].[Name] = N'BotVersionId')
      )
  );

-- Target: BrandingSet.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BrandingSet'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BrandingSet'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'BrandingSet'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'LightningExperienceTheme' AND [__mj].[IntegrationObjectField].[Name] = N'DefaultBrandingSetId')
      )
  );

-- Target: BriefcaseDefinition.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BriefcaseDefinition'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BriefcaseDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'BriefcaseDefinition'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'BriefcaseRule' AND [__mj].[IntegrationObjectField].[Name] = N'BriefcaseId')
      )
  );

-- Target: BroadcastCommunication.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BroadcastCommunication'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BroadcastCommunication'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'BroadcastCommunication'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'BroadcastCommAudience' AND [__mj].[IntegrationObjectField].[Name] = N'BroadcastCommunicationId')
      )
  );

-- Target: BroadcastTopic.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BroadcastTopic'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BroadcastTopic'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'BroadcastTopic'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'BroadcastTopicGroup' AND [__mj].[IntegrationObjectField].[Name] = N'BroadcastTopicId')
        OR (o.[Name] = N'BroadcastTopicNetwork' AND [__mj].[IntegrationObjectField].[Name] = N'BroadcastTopicId')
      )
  );

-- Target: BusinessAlert.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BusinessAlert'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BusinessAlert'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'BusinessAlert'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'BusinessAlertStatus' AND [__mj].[IntegrationObjectField].[Name] = N'BusinessAlertId')
      )
  );

-- Target: BusinessBrand.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BusinessBrand'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BusinessBrand'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'BusinessBrand'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CommSubscriptionConsent' AND [__mj].[IntegrationObjectField].[Name] = N'BusinessBrandId')
        OR (o.[Name] = N'ContactPointConsent' AND [__mj].[IntegrationObjectField].[Name] = N'BusinessBrandId')
        OR (o.[Name] = N'ContactPointTypeConsent' AND [__mj].[IntegrationObjectField].[Name] = N'BusinessBrandId')
      )
  );

-- Target: BusinessHours.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BusinessHours'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BusinessHours'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'BusinessHours'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'DeliveryEstimationSetup' AND [__mj].[IntegrationObjectField].[Name] = N'DefaultBusinessHoursId')
        OR (o.[Name] = N'MessagingChannel' AND [__mj].[IntegrationObjectField].[Name] = N'BusinessHoursId')
        OR (o.[Name] = N'ServiceRequest' AND [__mj].[IntegrationObjectField].[Name] = N'BusinessHoursId')
        OR (o.[Name] = N'WorkOrder' AND [__mj].[IntegrationObjectField].[Name] = N'BusinessHoursId')
      )
  );

-- Target: BuyerCriteria.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BuyerCriteria'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BuyerCriteria'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'BuyerCriteria'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'BuyerGroupBuyerCriteria' AND [__mj].[IntegrationObjectField].[Name] = N'BuyerCriteriaId')
      )
  );

-- Target: BuyerGroup.Id (5 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BuyerGroup'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BuyerGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'BuyerGroup'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'BuyerGroupBuyerCriteria' AND [__mj].[IntegrationObjectField].[Name] = N'BuyerGroupId')
        OR (o.[Name] = N'BuyerGroupMember' AND [__mj].[IntegrationObjectField].[Name] = N'BuyerGroupId')
        OR (o.[Name] = N'BuyerGroupRelatedObject' AND [__mj].[IntegrationObjectField].[Name] = N'BuyerGroupId')
        OR (o.[Name] = N'PromotionSegmentBuyerGroup' AND [__mj].[IntegrationObjectField].[Name] = N'BuyerGroupId')
        OR (o.[Name] = N'WebstoreBuyerGroup' AND [__mj].[IntegrationObjectField].[Name] = N'BuyerGroupId')
      )
  );

-- Target: CalculationMatrix.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CalculationMatrix'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CalculationMatrix'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CalculationMatrix'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CalculationMatrixColumn' AND [__mj].[IntegrationObjectField].[Name] = N'CalculationMatrixId')
        OR (o.[Name] = N'CalculationMatrixVersion' AND [__mj].[IntegrationObjectField].[Name] = N'CalculationMatrixId')
        OR (o.[Name] = N'CalculationProcedureStep' AND [__mj].[IntegrationObjectField].[Name] = N'CalculationMatrixId')
      )
  );

-- Target: CalculationMatrixVersion.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CalculationMatrixVersion'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CalculationMatrixVersion'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CalculationMatrixVersion'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CalculationMatrixRow' AND [__mj].[IntegrationObjectField].[Name] = N'CalculationMatrixVersionId')
      )
  );

-- Target: CalculationProcedure.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CalculationProcedure'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CalculationProcedure'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CalculationProcedure'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CalculationProcedureStep' AND [__mj].[IntegrationObjectField].[Name] = N'ReferenceProcedureId')
        OR (o.[Name] = N'CalculationProcedureVersion' AND [__mj].[IntegrationObjectField].[Name] = N'CalculationProcedureId')
      )
  );

-- Target: CalculationProcedureStep.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CalculationProcedureStep'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CalculationProcedureStep'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CalculationProcedureStep'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CalcProcStepRelationship' AND [__mj].[IntegrationObjectField].[Name] IN (N'CalcProcStepId', N'ParentCalcProcStepId'))
      )
  );

-- Target: CalculationProcedureVersion.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CalculationProcedureVersion'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CalculationProcedureVersion'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CalculationProcedureVersion'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CalcProcStepRelationship' AND [__mj].[IntegrationObjectField].[Name] = N'CalcProcVersionId')
        OR (o.[Name] = N'CalculationProcedureStep' AND [__mj].[IntegrationObjectField].[Name] = N'CalculationProcedureVersionId')
        OR (o.[Name] = N'CalculationProcedureVariable' AND [__mj].[IntegrationObjectField].[Name] = N'CalculationProcedureVersionId')
      )
  );

-- Target: CallCenter.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CallCenter'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CallCenter'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CallCenter'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CallCenterRoutingMap' AND [__mj].[IntegrationObjectField].[Name] = N'CallCenterId')
        OR (o.[Name] = N'CallCtrAgentFavTrfrDest' AND [__mj].[IntegrationObjectField].[Name] = N'CallCenterId')
        OR (o.[Name] = N'VendorCallCenterStatusMap' AND [__mj].[IntegrationObjectField].[Name] = N'CallCenterId')
      )
  );

-- Target: CallCoachingMediaProvider.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CallCoachingMediaProvider'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CallCoachingMediaProvider'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CallCoachingMediaProvider'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'VoiceCall' AND [__mj].[IntegrationObjectField].[Name] = N'MediaProviderId')
      )
  );

GO

-- Target: CallCtrAgentFavTrfrDest.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CallCtrAgentFavTrfrDest'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CallCtrAgentFavTrfrDest'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CallCtrAgentFavTrfrDest'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CallCtrAgentFavTrfrDestShare' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
      )
  );

-- Target: Campaign.Id (5 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Campaign'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Campaign'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Campaign'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CampaignMember' AND [__mj].[IntegrationObjectField].[Name] = N'CampaignId')
        OR (o.[Name] = N'CampaignShare' AND [__mj].[IntegrationObjectField].[Name] = N'CampaignId')
        OR (o.[Name] = N'FlowRecord' AND [__mj].[IntegrationObjectField].[Name] = N'AssociatedRecordId')
        OR (o.[Name] = N'ListEmail' AND [__mj].[IntegrationObjectField].[Name] = N'CampaignId')
        OR (o.[Name] = N'Opportunity' AND [__mj].[IntegrationObjectField].[Name] = N'CampaignId')
      )
  );

-- Target: CartDeliveryGroup.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CartDeliveryGroup'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CartDeliveryGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CartDeliveryGroup'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CartItem' AND [__mj].[IntegrationObjectField].[Name] = N'CartDeliveryGroupId')
      )
  );

-- Target: CartDeliveryGroupMethod.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CartDeliveryGroupMethod'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CartDeliveryGroupMethod'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CartDeliveryGroupMethod'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CartDeliveryGroup' AND [__mj].[IntegrationObjectField].[Name] = N'SelectedDeliveryMethodId')
        OR (o.[Name] = N'CartDeliveryGroupMethodAdj' AND [__mj].[IntegrationObjectField].[Name] = N'CartDeliveryGroupMethodId')
      )
  );

-- Target: CartItem.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CartItem'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CartItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CartItem'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CartItemPriceAdjustment' AND [__mj].[IntegrationObjectField].[Name] = N'CartItemId')
        OR (o.[Name] = N'InventoryItemReservation' AND [__mj].[IntegrationObjectField].[Name] = N'ItemReservationSourceId')
      )
  );

-- Target: CartItemPriceAdjustment.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CartItemPriceAdjustment'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CartItemPriceAdjustment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CartItemPriceAdjustment'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CartTax' AND [__mj].[IntegrationObjectField].[Name] = N'CartItemPriceAdjustmentId')
      )
  );

-- Target: Case.Id (17 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Case'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Case'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Case'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CaseContactRole' AND [__mj].[IntegrationObjectField].[Name] = N'CasesId')
        OR (o.[Name] = N'CaseHistory' AND [__mj].[IntegrationObjectField].[Name] = N'CaseId')
        OR (o.[Name] = N'CaseHistory2' AND [__mj].[IntegrationObjectField].[Name] = N'CaseId')
        OR (o.[Name] = N'CaseParticipant' AND [__mj].[IntegrationObjectField].[Name] = N'CaseId')
        OR (o.[Name] = N'CaseRelatedIssue' AND [__mj].[IntegrationObjectField].[Name] = N'CaseId')
        OR (o.[Name] = N'CaseShare' AND [__mj].[IntegrationObjectField].[Name] = N'CaseId')
        OR (o.[Name] = N'CaseSolution' AND [__mj].[IntegrationObjectField].[Name] = N'CaseId')
        OR (o.[Name] = N'CaseTeamMember' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
        OR (o.[Name] = N'CaseTeamTemplateRecord' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
        OR (o.[Name] = N'EmailMessage' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
        OR (o.[Name] = N'ProcessException' AND [__mj].[IntegrationObjectField].[Name] = N'CaseId')
        OR (o.[Name] = N'ProductRequest' AND [__mj].[IntegrationObjectField].[Name] = N'CaseId')
        OR (o.[Name] = N'ProductRequestLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'CaseId')
        OR (o.[Name] = N'PublicComplaint' AND [__mj].[IntegrationObjectField].[Name] = N'ComplaintCaseId')
        OR (o.[Name] = N'ReturnOrder' AND [__mj].[IntegrationObjectField].[Name] = N'CaseId')
        OR (o.[Name] = N'SocialPost' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
        OR (o.[Name] = N'WorkOrder' AND [__mj].[IntegrationObjectField].[Name] = N'CaseId')
      )
  );

-- Target: CaseTeamRole.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CaseTeamRole'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CaseTeamRole'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CaseTeamRole'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CaseTeamMember' AND [__mj].[IntegrationObjectField].[Name] = N'TeamRoleId')
      )
  );

-- Target: CaseTeamTemplate.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CaseTeamTemplate'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CaseTeamTemplate'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CaseTeamTemplate'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CaseTeamMember' AND [__mj].[IntegrationObjectField].[Name] = N'TeamTemplateId')
        OR (o.[Name] = N'CaseTeamTemplateRecord' AND [__mj].[IntegrationObjectField].[Name] = N'TeamTemplateId')
      )
  );

-- Target: CaseTeamTemplateMember.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CaseTeamTemplateMember'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CaseTeamTemplateMember'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CaseTeamTemplateMember'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CaseTeamMember' AND [__mj].[IntegrationObjectField].[Name] = N'TeamTemplateMemberId')
      )
  );

-- Target: ChangeRequest.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ChangeRequest'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ChangeRequest'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ChangeRequest'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ChangeRequestRelatedIssue' AND [__mj].[IntegrationObjectField].[Name] = N'ChangeRequestId')
        OR (o.[Name] = N'ChangeRequestRelatedItem' AND [__mj].[IntegrationObjectField].[Name] = N'ChangeRequestId')
      )
  );

-- Target: ChatterExtension.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ChatterExtension'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ChatterExtension'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ChatterExtension'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ChatterExtensionConfig' AND [__mj].[IntegrationObjectField].[Name] = N'ChatterExtensionId')
      )
  );

-- Target: CollaborationGroup.Id (5 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CollaborationGroup'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CollaborationGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CollaborationGroup'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'Announcement' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
        OR (o.[Name] = N'CollaborationGroupMember' AND [__mj].[IntegrationObjectField].[Name] = N'CollaborationGroupId')
        OR (o.[Name] = N'CollaborationGroupMemberRequest' AND [__mj].[IntegrationObjectField].[Name] = N'CollaborationGroupId')
        OR (o.[Name] = N'CollaborationGroupRecord' AND [__mj].[IntegrationObjectField].[Name] = N'CollaborationGroupId')
        OR (o.[Name] = N'LightningOnboardingConfig' AND [__mj].[IntegrationObjectField].[Name] = N'CollaborationGroupId')
      )
  );

-- Target: CollaborationRoom.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CollaborationRoom'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CollaborationRoom'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CollaborationRoom'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'Swarm' AND [__mj].[IntegrationObjectField].[Name] = N'CollaborationRoomId')
      )
  );

-- Target: CommissionSchedule.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CommissionSchedule'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CommissionSchedule'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CommissionSchedule'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CommissionScheduleAssignment' AND [__mj].[IntegrationObjectField].[Name] = N'CommissionScheduleId')
        OR (o.[Name] = N'ProducerCommission' AND [__mj].[IntegrationObjectField].[Name] = N'CommissionScheduleId')
      )
  );

-- Target: CommSubscription.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CommSubscription'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CommSubscription'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CommSubscription'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CommSubscriptionChannelType' AND [__mj].[IntegrationObjectField].[Name] = N'CommunicationSubscriptionId')
      )
  );

-- Target: CommSubscriptionChannelType.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CommSubscriptionChannelType'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CommSubscriptionChannelType'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CommSubscriptionChannelType'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CommSubscriptionConsent' AND [__mj].[IntegrationObjectField].[Name] = N'CommSubscriptionChannelTypeId')
      )
  );

-- Target: CommSubscriptionConsent.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CommSubscriptionConsent'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CommSubscriptionConsent'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CommSubscriptionConsent'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CommSubscriptionTiming' AND [__mj].[IntegrationObjectField].[Name] = N'CommSubscriptionConsentId')
      )
  );

-- Target: ConnectedApplication.Id (7 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ConnectedApplication'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ConnectedApplication'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ConnectedApplication'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'OauthTokenExchHandlerApp' AND [__mj].[IntegrationObjectField].[Name] = N'ConnectedApplicationId')
        OR (o.[Name] = N'UserAppMenuCustomization' AND [__mj].[IntegrationObjectField].[Name] = N'ApplicationId')
        OR (o.[Name] = N'UserProvAccount' AND [__mj].[IntegrationObjectField].[Name] = N'ConnectedAppId')
        OR (o.[Name] = N'UserProvAccountStaging' AND [__mj].[IntegrationObjectField].[Name] = N'ConnectedAppId')
        OR (o.[Name] = N'UserProvisioningConfig' AND [__mj].[IntegrationObjectField].[Name] = N'ConnectedAppId')
        OR (o.[Name] = N'UserProvisioningRequest' AND [__mj].[IntegrationObjectField].[Name] = N'ConnectedAppId')
        OR (o.[Name] = N'VerificationHistory' AND [__mj].[IntegrationObjectField].[Name] = N'ResourceId')
      )
  );

-- Target: Contact.Id (27 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Contact'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Contact'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Contact'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AccountContactRole' AND [__mj].[IntegrationObjectField].[Name] = N'ContactId')
        OR (o.[Name] = N'AccountPlanObjective' AND [__mj].[IntegrationObjectField].[Name] = N'ExternalStakeholderId')
        OR (o.[Name] = N'Asset' AND [__mj].[IntegrationObjectField].[Name] = N'ContactId')
        OR (o.[Name] = N'BillingScheduleGroup' AND [__mj].[IntegrationObjectField].[Name] = N'BillToContactId')
        OR (o.[Name] = N'CampaignMember' AND [__mj].[IntegrationObjectField].[Name] = N'ContactId')
        OR (o.[Name] = N'Case' AND [__mj].[IntegrationObjectField].[Name] = N'ContactId')
        OR (o.[Name] = N'CaseContactRole' AND [__mj].[IntegrationObjectField].[Name] = N'ContactId')
        OR (o.[Name] = N'ContactDailyMetric' AND [__mj].[IntegrationObjectField].[Name] = N'ContactId')
        OR (o.[Name] = N'ContactMonthlyMetric' AND [__mj].[IntegrationObjectField].[Name] = N'ContactId')
        OR (o.[Name] = N'ContactShare' AND [__mj].[IntegrationObjectField].[Name] = N'ContactId')
        OR (o.[Name] = N'Contract' AND [__mj].[IntegrationObjectField].[Name] = N'CustomerSignedId')
        OR (o.[Name] = N'ContractContactRole' AND [__mj].[IntegrationObjectField].[Name] = N'ContactId')
        OR (o.[Name] = N'CreditMemo' AND [__mj].[IntegrationObjectField].[Name] = N'BillToContactId')
        OR (o.[Name] = N'FulfillmentOrder' AND [__mj].[IntegrationObjectField].[Name] = N'BillToContactId')
        OR (o.[Name] = N'Invoice' AND [__mj].[IntegrationObjectField].[Name] = N'BillToContactId')
        OR (o.[Name] = N'Lead' AND [__mj].[IntegrationObjectField].[Name] = N'ConvertedContactId')
        OR (o.[Name] = N'MessagingEndUser' AND [__mj].[IntegrationObjectField].[Name] = N'ContactId')
        OR (o.[Name] = N'MessagingSession' AND [__mj].[IntegrationObjectField].[Name] = N'EndUserContactId')
        OR (o.[Name] = N'OpportunityContactRole' AND [__mj].[IntegrationObjectField].[Name] = N'ContactId')
        OR (o.[Name] = N'Order' AND [__mj].[IntegrationObjectField].[Name] = N'CustomerAuthorizedById')
        OR (o.[Name] = N'OrderSummary' AND [__mj].[IntegrationObjectField].[Name] = N'BillToContactId')
        OR (o.[Name] = N'PaymentInitiationSource' AND [__mj].[IntegrationObjectField].[Name] = N'ContactId')
        OR (o.[Name] = N'PendingOrderSummary' AND [__mj].[IntegrationObjectField].[Name] = N'BillToContactId')
        OR (o.[Name] = N'Prospect' AND [__mj].[IntegrationObjectField].[Name] = N'ConvertedContactId')
        OR (o.[Name] = N'ReturnOrder' AND [__mj].[IntegrationObjectField].[Name] = N'ContactId')
        OR (o.[Name] = N'ServiceAppointment' AND [__mj].[IntegrationObjectField].[Name] = N'ContactId')
        OR (o.[Name] = N'WorkOrder' AND [__mj].[IntegrationObjectField].[Name] = N'ContactId')
      )
  );

-- Target: ContactPointPhone.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ContactPointPhone'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ContactPointPhone'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ContactPointPhone'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ContactPointAddress' AND [__mj].[IntegrationObjectField].[Name] = N'ContactPointPhoneId')
      )
  );

-- Target: ContactRequest.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ContactRequest'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ContactRequest'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ContactRequest'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ContactRequestShare' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
      )
  );

-- Target: ContentAsset.Id (8 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ContentAsset'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ContentAsset'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ContentAsset'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AnalyticsContainerWidgetDef' AND [__mj].[IntegrationObjectField].[Name] = N'BackgroundSourceId')
        OR (o.[Name] = N'ChatterExtension' AND [__mj].[IntegrationObjectField].[Name] = N'IconId')
        OR (o.[Name] = N'ContentWorkspace' AND [__mj].[IntegrationObjectField].[Name] = N'WorkspaceImageId')
        OR (o.[Name] = N'Location' AND [__mj].[IntegrationObjectField].[Name] = N'LogoId')
        OR (o.[Name] = N'PromptVersion' AND [__mj].[IntegrationObjectField].[Name] = N'ImageId')
        OR (o.[Name] = N'Recommendation' AND [__mj].[IntegrationObjectField].[Name] = N'ImageId')
        OR (o.[Name] = N'SvcCatalogCategory' AND [__mj].[IntegrationObjectField].[Name] = N'ImageId')
        OR (o.[Name] = N'SvcCatalogItemDef' AND [__mj].[IntegrationObjectField].[Name] = N'ImageId')
      )
  );

-- Target: ContentBody.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ContentBody'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ContentBody'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ContentBody'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ContentNote' AND [__mj].[IntegrationObjectField].[Name] = N'LatestContentId')
        OR (o.[Name] = N'ContentVersion' AND [__mj].[IntegrationObjectField].[Name] = N'ContentBodyId')
      )
  );

-- Target: ContentDistribution.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ContentDistribution'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ContentDistribution'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ContentDistribution'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ContentDistributionView' AND [__mj].[IntegrationObjectField].[Name] = N'DistributionId')
      )
  );

GO

-- Target: ContentDocument.Id (17 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ContentDocument'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ContentDocument'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ContentDocument'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AttachedContentDocument' AND [__mj].[IntegrationObjectField].[Name] = N'ContentDocumentId')
        OR (o.[Name] = N'AuthorizationFormText' AND [__mj].[IntegrationObjectField].[Name] = N'ContentDocumentId')
        OR (o.[Name] = N'ContentAsset' AND [__mj].[IntegrationObjectField].[Name] = N'ContentDocumentId')
        OR (o.[Name] = N'ContentDocumentHistory' AND [__mj].[IntegrationObjectField].[Name] = N'ContentDocumentId')
        OR (o.[Name] = N'ContentDocumentLink' AND [__mj].[IntegrationObjectField].[Name] = N'ContentDocumentId')
        OR (o.[Name] = N'ContentDocumentSubscription' AND [__mj].[IntegrationObjectField].[Name] = N'ContentDocumentId')
        OR (o.[Name] = N'ContentFolderMember' AND [__mj].[IntegrationObjectField].[Name] = N'ChildRecordId')
        OR (o.[Name] = N'ContentVersion' AND [__mj].[IntegrationObjectField].[Name] = N'ContentDocumentId')
        OR (o.[Name] = N'ContentVersionComment' AND [__mj].[IntegrationObjectField].[Name] = N'ContentDocumentId')
        OR (o.[Name] = N'ContentWorkspaceDoc' AND [__mj].[IntegrationObjectField].[Name] = N'ContentDocumentId')
        OR (o.[Name] = N'FolderedContentDocument' AND [__mj].[IntegrationObjectField].[Name] = N'ContentDocumentId')
        OR (o.[Name] = N'Image' AND [__mj].[IntegrationObjectField].[Name] = N'ContentDocumentId')
        OR (o.[Name] = N'InvoiceDocument' AND [__mj].[IntegrationObjectField].[Name] = N'ContentDocumentId')
        OR (o.[Name] = N'OutgoingEmail' AND [__mj].[IntegrationObjectField].[Name] = N'ContentDocumentId')
        OR (o.[Name] = N'OutgoingEmailRelation' AND [__mj].[IntegrationObjectField].[Name] = N'ContentDocumentId')
        OR (o.[Name] = N'OwnedContentDocument' AND [__mj].[IntegrationObjectField].[Name] = N'ContentDocumentId')
        OR (o.[Name] = N'VoiceCallRecording' AND [__mj].[IntegrationObjectField].[Name] = N'MediaContentId')
      )
  );

-- Target: ContentFolder.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ContentFolder'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ContentFolder'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ContentFolder'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ContentFolderItem' AND [__mj].[IntegrationObjectField].[Name] = N'ParentContentFolderId')
        OR (o.[Name] = N'ContentFolderLink' AND [__mj].[IntegrationObjectField].[Name] = N'ContentFolderId')
        OR (o.[Name] = N'ContentFolderMember' AND [__mj].[IntegrationObjectField].[Name] = N'ParentContentFolderId')
        OR (o.[Name] = N'FolderedContentDocument' AND [__mj].[IntegrationObjectField].[Name] = N'ParentContentFolderId')
      )
  );

-- Target: ContentVersion.Id (6 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ContentVersion'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ContentVersion'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ContentVersion'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AuthorizationFormConsent' AND [__mj].[IntegrationObjectField].[Name] = N'DocumentVersionId')
        OR (o.[Name] = N'ContentDistribution' AND [__mj].[IntegrationObjectField].[Name] = N'ContentVersionId')
        OR (o.[Name] = N'ContentVersionComment' AND [__mj].[IntegrationObjectField].[Name] = N'ContentVersionId')
        OR (o.[Name] = N'ContentVersionHistory' AND [__mj].[IntegrationObjectField].[Name] = N'ContentVersionId')
        OR (o.[Name] = N'ContentVersionRating' AND [__mj].[IntegrationObjectField].[Name] = N'ContentVersionId')
        OR (o.[Name] = N'PaymentLink' AND [__mj].[IntegrationObjectField].[Name] = N'QrCodeImageId')
      )
  );

-- Target: ContentWorkspace.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ContentWorkspace'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ContentWorkspace'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ContentWorkspace'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ContentWorkspaceDoc' AND [__mj].[IntegrationObjectField].[Name] = N'ContentWorkspaceId')
        OR (o.[Name] = N'ContentWorkspaceMember' AND [__mj].[IntegrationObjectField].[Name] = N'ContentWorkspaceId')
        OR (o.[Name] = N'ContentWorkspaceSubscription' AND [__mj].[IntegrationObjectField].[Name] = N'ContentWorkspaceId')
      )
  );

-- Target: ContentWorkspacePermission.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ContentWorkspacePermission'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ContentWorkspacePermission'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ContentWorkspacePermission'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ContentWorkspaceMember' AND [__mj].[IntegrationObjectField].[Name] = N'ContentWorkspacePermissionId')
      )
  );

-- Target: Contract.Id (5 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Contract'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Contract'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Contract'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AssetContractRelationship' AND [__mj].[IntegrationObjectField].[Name] = N'ContractId')
        OR (o.[Name] = N'ContractContactRole' AND [__mj].[IntegrationObjectField].[Name] = N'ContractId')
        OR (o.[Name] = N'Opportunity' AND [__mj].[IntegrationObjectField].[Name] = N'ContractId')
        OR (o.[Name] = N'Order' AND [__mj].[IntegrationObjectField].[Name] = N'ContractId')
        OR (o.[Name] = N'QuoteLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'PricingContractId')
      )
  );

-- Target: ContractLineItem.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ContractLineItem'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ContractLineItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ContractLineItem'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ContractLineOutcome' AND [__mj].[IntegrationObjectField].[Name] = N'ContractLineItemId')
      )
  );

-- Target: ContractLineOutcome.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ContractLineOutcome'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ContractLineOutcome'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ContractLineOutcome'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ContractLineOutcomeData' AND [__mj].[IntegrationObjectField].[Name] = N'ContractLineOutcomeId')
      )
  );

-- Target: Conversation.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Conversation'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Conversation'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Conversation'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'MessagingSession' AND [__mj].[IntegrationObjectField].[Name] = N'ConversationId')
        OR (o.[Name] = N'VoiceCall' AND [__mj].[IntegrationObjectField].[Name] = N'ConversationId')
      )
  );

-- Target: ConversationChannelDefinition.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ConversationChannelDefinition'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ConversationChannelDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ConversationChannelDefinition'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CustomMsgChannel' AND [__mj].[IntegrationObjectField].[Name] = N'ChannelDefinitionId')
        OR (o.[Name] = N'MessagingChannel' AND [__mj].[IntegrationObjectField].[Name] = N'ChannelDefinitionId')
      )
  );

-- Target: ConversationParticipant.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ConversationParticipant'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ConversationParticipant'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ConversationParticipant'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'VoiceCall' AND [__mj].[IntegrationObjectField].[Name] = N'RecipientId')
      )
  );

-- Target: ConversationVendorInfo.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ConversationVendorInfo'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ConversationVendorInfo'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ConversationVendorInfo'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ConversationChannelDefinition' AND [__mj].[IntegrationObjectField].[Name] = N'ConversationVendorInfoId')
      )
  );

-- Target: Coupon.Id (7 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Coupon'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Coupon'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Coupon'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CartDeliveryGroupMethodAdj' AND [__mj].[IntegrationObjectField].[Name] = N'AdjustmentBasisReferenceId')
        OR (o.[Name] = N'CouponCodeRedemption' AND [__mj].[IntegrationObjectField].[Name] = N'CouponId')
        OR (o.[Name] = N'OrderAdjustmentGroup' AND [__mj].[IntegrationObjectField].[Name] = N'AdjustmentBasisReferenceId')
        OR (o.[Name] = N'OrderAdjustmentGroupSummary' AND [__mj].[IntegrationObjectField].[Name] = N'AdjustmentBasisReferenceId')
        OR (o.[Name] = N'OrderItemAdjustmentLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'AdjustmentBasisReferenceId')
        OR (o.[Name] = N'OrderItemAdjustmentLineSummary' AND [__mj].[IntegrationObjectField].[Name] = N'AdjustmentBasisReferenceId')
        OR (o.[Name] = N'WebCartAdjustmentBasis' AND [__mj].[IntegrationObjectField].[Name] = N'AdjustmentBasisReferenceId')
      )
  );

-- Target: CreditMemo.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CreditMemo'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CreditMemo'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CreditMemo'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CreditMemoAddressGroup' AND [__mj].[IntegrationObjectField].[Name] = N'CreditMemoId')
        OR (o.[Name] = N'CreditMemoInvApplication' AND [__mj].[IntegrationObjectField].[Name] = N'CreditMemoId')
        OR (o.[Name] = N'CreditMemoLine' AND [__mj].[IntegrationObjectField].[Name] = N'CreditMemoId')
        OR (o.[Name] = N'PaymentCredit' AND [__mj].[IntegrationObjectField].[Name] = N'CreditMemoId')
      )
  );

-- Target: CreditMemoAddressGroup.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CreditMemoAddressGroup'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CreditMemoAddressGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CreditMemoAddressGroup'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CreditMemoLine' AND [__mj].[IntegrationObjectField].[Name] IN (N'BillingAddressId', N'ShippingAddressId'))
      )
  );

-- Target: CronJobDetail.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CronJobDetail'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CronJobDetail'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CronJobDetail'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CronTrigger' AND [__mj].[IntegrationObjectField].[Name] = N'CronJobDetailId')
      )
  );

-- Target: CronTrigger.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CronTrigger'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CronTrigger'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CronTrigger'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AsyncApexJob' AND [__mj].[IntegrationObjectField].[Name] = N'CronTriggerId')
      )
  );

-- Target: CustomBrand.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CustomBrand'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CustomBrand'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CustomBrand'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CustomBrandAsset' AND [__mj].[IntegrationObjectField].[Name] = N'CustomBrandId')
      )
  );

-- Target: CustomHelpMenuSection.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CustomHelpMenuSection'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CustomHelpMenuSection'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CustomHelpMenuSection'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CustomHelpMenuItem' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
      )
  );

-- Target: CustomNotificationType.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CustomNotificationType'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CustomNotificationType'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CustomNotificationType'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'BroadcastCommunication' AND [__mj].[IntegrationObjectField].[Name] = N'CustomNotificationTypeId')
      )
  );

-- Target: CustomPermission.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CustomPermission'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'CustomPermission'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'CustomPermission'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CustomPermissionDependency' AND [__mj].[IntegrationObjectField].[Name] IN (N'CustomPermissionId', N'RequiredCustomPermissionId'))
      )
  );

-- Target: Dashboard.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Dashboard'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Dashboard'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Dashboard'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'DashboardComponent' AND [__mj].[IntegrationObjectField].[Name] = N'DashboardId')
      )
  );

-- Target: DataAssessmentFieldMetric.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DataAssessmentFieldMetric'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DataAssessmentFieldMetric'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'DataAssessmentFieldMetric'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'DataAssessmentValueMetric' AND [__mj].[IntegrationObjectField].[Name] = N'DataAssessmentFieldMetricId')
      )
  );

-- Target: DataAssessmentMetric.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DataAssessmentMetric'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DataAssessmentMetric'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'DataAssessmentMetric'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'DataAssessmentFieldMetric' AND [__mj].[IntegrationObjectField].[Name] = N'DataAssessmentMetricId')
      )
  );

-- Target: DataDetectJobSession.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DataDetectJobSession'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DataDetectJobSession'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'DataDetectJobSession'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'DataDetectScanResult' AND [__mj].[IntegrationObjectField].[Name] = N'DataDetectJobSessionId')
      )
  );

GO

-- Target: DataDetectPolicy.Id (7 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DataDetectPolicy'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DataDetectPolicy'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'DataDetectPolicy'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'DataDetectJobObjectSession' AND [__mj].[IntegrationObjectField].[Name] = N'DataDetectPolicyId')
        OR (o.[Name] = N'DataDetectJobSession' AND [__mj].[IntegrationObjectField].[Name] = N'DataDetectPolicyId')
        OR (o.[Name] = N'DataDetectPolicyObject' AND [__mj].[IntegrationObjectField].[Name] = N'DataDetectPolicyId')
        OR (o.[Name] = N'DataDetectPolicySnapshot' AND [__mj].[IntegrationObjectField].[Name] = N'DataDetectPolicyId')
        OR (o.[Name] = N'DataDetPlcyDataSrchExps' AND [__mj].[IntegrationObjectField].[Name] = N'DataDetectPolicyId')
        OR (o.[Name] = N'DataDetPlcyMdatScanCrit' AND [__mj].[IntegrationObjectField].[Name] = N'DataDetectPolicyId')
        OR (o.[Name] = N'DataDetPlcySstvDataCatg' AND [__mj].[IntegrationObjectField].[Name] = N'DataDetectPolicyId')
      )
  );

-- Target: DataDetectPolicyObject.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DataDetectPolicyObject'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DataDetectPolicyObject'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'DataDetectPolicyObject'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'DataDetectPolicyObjField' AND [__mj].[IntegrationObjectField].[Name] = N'DataDetectPolicyObjectId')
      )
  );

-- Target: DataDetectPolicySnapshot.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DataDetectPolicySnapshot'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DataDetectPolicySnapshot'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'DataDetectPolicySnapshot'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'DataDetectJobObjectSession' AND [__mj].[IntegrationObjectField].[Name] = N'DataDetectPolicySnapshotId')
        OR (o.[Name] = N'DataDetectJobSession' AND [__mj].[IntegrationObjectField].[Name] = N'DataDetectPolicySnapshotId')
      )
  );

-- Target: DataUseLegalBasis.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DataUseLegalBasis'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DataUseLegalBasis'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'DataUseLegalBasis'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'DataUsePurpose' AND [__mj].[IntegrationObjectField].[Name] = N'LegalBasisId')
      )
  );

-- Target: DataUsePurpose.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DataUsePurpose'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DataUsePurpose'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'DataUsePurpose'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AuthorizationFormDataUse' AND [__mj].[IntegrationObjectField].[Name] = N'DataUsePurposeId')
        OR (o.[Name] = N'CommSubscriptionConsent' AND [__mj].[IntegrationObjectField].[Name] = N'DataUsePurposeId')
        OR (o.[Name] = N'ContactPointConsent' AND [__mj].[IntegrationObjectField].[Name] = N'DataUsePurposeId')
        OR (o.[Name] = N'ContactPointTypeConsent' AND [__mj].[IntegrationObjectField].[Name] = N'DataUsePurposeId')
      )
  );

-- Target: DevopsEnvironment.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DevopsEnvironment'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DevopsEnvironment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'DevopsEnvironment'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'DevopsPipelineEnvironment' AND [__mj].[IntegrationObjectField].[Name] = N'DevopsEnvironmentId')
        OR (o.[Name] = N'DevopsPipelineStage' AND [__mj].[IntegrationObjectField].[Name] = N'DevOpsEnvironmentId')
        OR (o.[Name] = N'WorkItem' AND [__mj].[IntegrationObjectField].[Name] = N'DevelopmentEnvironmentId')
      )
  );

-- Target: DevopsPipeline.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DevopsPipeline'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DevopsPipeline'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'DevopsPipeline'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'DevopsActivityLog' AND [__mj].[IntegrationObjectField].[Name] = N'PipelineId')
        OR (o.[Name] = N'DevopsProjectPipeline' AND [__mj].[IntegrationObjectField].[Name] = N'DevopsPipelineId')
      )
  );

-- Target: DevopsPipelineStage.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DevopsPipelineStage'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DevopsPipelineStage'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'DevopsPipelineStage'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'DevopsActivityLog' AND [__mj].[IntegrationObjectField].[Name] = N'PipelineStageId')
        OR (o.[Name] = N'WorkItem' AND [__mj].[IntegrationObjectField].[Name] = N'DevopsPipelineStageId')
      )
  );

-- Target: DevopsProject.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DevopsProject'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DevopsProject'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'DevopsProject'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'DevopsActivityLog' AND [__mj].[IntegrationObjectField].[Name] = N'ProjectId')
        OR (o.[Name] = N'WorkItem' AND [__mj].[IntegrationObjectField].[Name] = N'DevopsProjectId')
      )
  );

-- Target: DevopsRequestInfo.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DevopsRequestInfo'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DevopsRequestInfo'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'DevopsRequestInfo'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'DevopsActivityLog' AND [__mj].[IntegrationObjectField].[Name] = N'DevopsRequestInfoId')
        OR (o.[Name] = N'DevopsPipelnStgProm' AND [__mj].[IntegrationObjectField].[Name] = N'RequestInfoId')
        OR (o.[Name] = N'WorkItem' AND [__mj].[IntegrationObjectField].[Name] = N'RebaseStatusId')
      )
  );

-- Target: DigitalSignature.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DigitalSignature'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DigitalSignature'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'DigitalSignature'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'DocumentRecipient' AND [__mj].[IntegrationObjectField].[Name] = N'DigitalSignatureId')
      )
  );

-- Target: Domain.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Domain'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Domain'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Domain'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'DomainSite' AND [__mj].[IntegrationObjectField].[Name] = N'DomainId')
      )
  );

-- Target: DuplicateRecordSet.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DuplicateRecordSet'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DuplicateRecordSet'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'DuplicateRecordSet'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'DuplicateRecordItem' AND [__mj].[IntegrationObjectField].[Name] = N'DuplicateRecordSetId')
      )
  );

-- Target: DuplicateRule.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DuplicateRule'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'DuplicateRule'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'DuplicateRule'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'DuplicateRecordSet' AND [__mj].[IntegrationObjectField].[Name] = N'DuplicateRuleId')
      )
  );

-- Target: ElectronicMediaGroup.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ElectronicMediaGroup'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ElectronicMediaGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ElectronicMediaGroup'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ProductMedia' AND [__mj].[IntegrationObjectField].[Name] = N'ElectronicMediaGroupId')
      )
  );

-- Target: EmailDomainKey.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EmailDomainKey'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EmailDomainKey'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'EmailDomainKey'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'SenderEmailAddress' AND [__mj].[IntegrationObjectField].[Name] = N'EmailDomainKeyId')
      )
  );

-- Target: EmailInsight.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EmailInsight'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EmailInsight'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'EmailInsight'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'EmailInsightAction' AND [__mj].[IntegrationObjectField].[Name] = N'EmailInsightId')
      )
  );

-- Target: EmailMessage.Id (6 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EmailMessage'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EmailMessage'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'EmailMessage'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ActivityHistory' AND [__mj].[IntegrationObjectField].[Name] = N'AlternateDetailId')
        OR (o.[Name] = N'EmailInsight' AND [__mj].[IntegrationObjectField].[Name] = N'EmailMessageId')
        OR (o.[Name] = N'EmailMessageMigration' AND [__mj].[IntegrationObjectField].[Name] = N'EmailMessageId')
        OR (o.[Name] = N'EmailMessageRelation' AND [__mj].[IntegrationObjectField].[Name] = N'EmailMessageId')
        OR (o.[Name] = N'OpenActivity' AND [__mj].[IntegrationObjectField].[Name] = N'AlternateDetailId')
        OR (o.[Name] = N'UnifiedEmail' AND [__mj].[IntegrationObjectField].[Name] = N'DetailId')
      )
  );

-- Target: EmailRelay.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EmailRelay'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EmailRelay'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'EmailRelay'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'EmailDomainFilter' AND [__mj].[IntegrationObjectField].[Name] = N'EmailRelayId')
      )
  );

-- Target: EmailRoutingAddress.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EmailRoutingAddress'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EmailRoutingAddress'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'EmailRoutingAddress'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'EmailMessage' AND [__mj].[IntegrationObjectField].[Name] = N'EmailRoutingAddressId')
      )
  );

-- Target: EmailServicesFunction.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EmailServicesFunction'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EmailServicesFunction'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'EmailServicesFunction'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'EmailServicesAddress' AND [__mj].[IntegrationObjectField].[Name] = N'FunctionId')
      )
  );

-- Target: EmailTemplate.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EmailTemplate'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EmailTemplate'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'EmailTemplate'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ApprovalAlertContentDef' AND [__mj].[IntegrationObjectField].[Name] = N'EmailTemplateId')
        OR (o.[Name] = N'EmailMessage' AND [__mj].[IntegrationObjectField].[Name] = N'EmailTemplateId')
        OR (o.[Name] = N'EmailTemplateMonthlyMetric' AND [__mj].[IntegrationObjectField].[Name] = N'EmailTemplateId')
        OR (o.[Name] = N'NetworkEmailTmplAllowlist' AND [__mj].[IntegrationObjectField].[Name] = N'EmailTemplateId')
      )
  );

-- Target: Employee.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Employee'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Employee'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Employee'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'EmpUserProvisionProcessErr' AND [__mj].[IntegrationObjectField].[Name] = N'EmployeeId')
      )
  );

-- Target: EmpUserProvisioningProcess.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EmpUserProvisioningProcess'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EmpUserProvisioningProcess'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'EmpUserProvisioningProcess'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'EmpUserProvisionProcessErr' AND [__mj].[IntegrationObjectField].[Name] = N'ProvisioningProcessId')
      )
  );

-- Target: EnablementMeasureDefinition.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EnablementMeasureDefinition'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EnablementMeasureDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'EnablementMeasureDefinition'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'EnblMeasureObjectDefinition' AND [__mj].[IntegrationObjectField].[Name] = N'EnablementMeasureDefinitionId')
        OR (o.[Name] = N'EnblProgramTaskMeasure' AND [__mj].[IntegrationObjectField].[Name] = N'EnablementMeasureDefinitionId')
      )
  );

GO

-- Target: EnablementProgram.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EnablementProgram'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EnablementProgram'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'EnablementProgram'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'EnablementProgramDefinition' AND [__mj].[IntegrationObjectField].[Name] = N'EnablementProgramId')
        OR (o.[Name] = N'EnblProgramSection' AND [__mj].[IntegrationObjectField].[Name] = N'EnablementProgramId')
        OR (o.[Name] = N'EnblProgramTaskDefinition' AND [__mj].[IntegrationObjectField].[Name] = N'EnablementProgramId')
        OR (o.[Name] = N'LearningItem' AND [__mj].[IntegrationObjectField].[Name] = N'EnablementProgramId')
      )
  );

-- Target: EnblProgramSection.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EnblProgramSection'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EnblProgramSection'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'EnblProgramSection'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'EnblProgramTaskDefinition' AND [__mj].[IntegrationObjectField].[Name] = N'EnblProgramSectionId')
      )
  );

-- Target: EnblProgramTaskDefinition.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EnblProgramTaskDefinition'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EnblProgramTaskDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'EnblProgramTaskDefinition'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'EnblProgramTaskProgress' AND [__mj].[IntegrationObjectField].[Name] = N'EnblProgramTaskDefinitionId')
      )
  );

-- Target: EnblProgramTaskMeasure.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EnblProgramTaskMeasure'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EnblProgramTaskMeasure'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'EnblProgramTaskMeasure'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'EnblPgmTaskMeasureProgress' AND [__mj].[IntegrationObjectField].[Name] = N'EnblProgramTaskMeasureId')
      )
  );

-- Target: EnblProgramTaskSubCategory.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EnblProgramTaskSubCategory'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EnblProgramTaskSubCategory'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'EnblProgramTaskSubCategory'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'EnblProgramTaskDefinition' AND [__mj].[IntegrationObjectField].[Name] = N'CustomEnblPgmTaskSubCategoryId')
      )
  );

-- Target: EngagementChannelType.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EngagementChannelType'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EngagementChannelType'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'EngagementChannelType'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CommSubscriptionChannelType' AND [__mj].[IntegrationObjectField].[Name] = N'EngagementChannelTypeId')
        OR (o.[Name] = N'CommSubscriptionConsent' AND [__mj].[IntegrationObjectField].[Name] = N'EngagementChannelTypeId')
      )
  );

-- Target: EngagementSignalMetric.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EngagementSignalMetric'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EngagementSignalMetric'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'EngagementSignalMetric'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AttribModelStageMetric' AND [__mj].[IntegrationObjectField].[Name] = N'EngagementSignalMetricId')
        OR (o.[Name] = N'EngagementSignalCmpndMetric' AND [__mj].[IntegrationObjectField].[Name] IN (N'DenomEngmtSignalMetricId', N'NumerEngmtSignalMetricId'))
      )
  );

-- Target: EnhancedLetterhead.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EnhancedLetterhead'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EnhancedLetterhead'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'EnhancedLetterhead'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'EmailTemplate' AND [__mj].[IntegrationObjectField].[Name] = N'EnhancedLetterheadId')
      )
  );

-- Target: Event.Id (8 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Event'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Event'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Event'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AcceptedEventRelation' AND [__mj].[IntegrationObjectField].[Name] = N'EventId')
        OR (o.[Name] = N'DeclinedEventRelation' AND [__mj].[IntegrationObjectField].[Name] = N'EventId')
        OR (o.[Name] = N'EventRelation' AND [__mj].[IntegrationObjectField].[Name] = N'EventId')
        OR (o.[Name] = N'EventStagedInviteeEmail' AND [__mj].[IntegrationObjectField].[Name] = N'EventId')
        OR (o.[Name] = N'ExternalEventMapping' AND [__mj].[IntegrationObjectField].[Name] = N'EventId')
        OR (o.[Name] = N'UndecidedEventRelation' AND [__mj].[IntegrationObjectField].[Name] = N'EventId')
        OR (o.[Name] = N'UnifiedMeeting' AND [__mj].[IntegrationObjectField].[Name] = N'DetailId')
        OR (o.[Name] = N'VideoCall' AND [__mj].[IntegrationObjectField].[Name] = N'EventId')
      )
  );

-- Target: EventRelayConfig.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EventRelayConfig'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'EventRelayConfig'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'EventRelayConfig'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'EventRelayFeedback' AND [__mj].[IntegrationObjectField].[Name] = N'EventRelayConfigId')
      )
  );

-- Target: ExternalClientApplication.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ExternalClientApplication'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ExternalClientApplication'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ExternalClientApplication'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ExtlRecShrCnct' AND [__mj].[IntegrationObjectField].[Name] = N'ExternalClientApplicationId')
      )
  );

-- Target: ExternalDataSource.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ExternalDataSource'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ExternalDataSource'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ExternalDataSource'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ContentVersion' AND [__mj].[IntegrationObjectField].[Name] = N'ExternalDataSourceId')
      )
  );

-- Target: ExternalEvent.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ExternalEvent'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ExternalEvent'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ExternalEvent'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ConferenceNumber' AND [__mj].[IntegrationObjectField].[Name] = N'ExternalEventId')
      )
  );

-- Target: ExternalSocialAccount.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ExternalSocialAccount'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ExternalSocialAccount'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ExternalSocialAccount'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'SocialPost' AND [__mj].[IntegrationObjectField].[Name] = N'OutboundSocialAccountId')
      )
  );

-- Target: ExtlRecShrCnct.Id (5 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ExtlRecShrCnct'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ExtlRecShrCnct'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ExtlRecShrCnct'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ExtlRecShrCnctAccnt' AND [__mj].[IntegrationObjectField].[Name] = N'ExtlRecShrCnctId')
        OR (o.[Name] = N'ExtlRecShrLead' AND [__mj].[IntegrationObjectField].[Name] = N'ExtlRecShrCnctId')
        OR (o.[Name] = N'ExtlRecShrObject' AND [__mj].[IntegrationObjectField].[Name] = N'ExtlRecShrCnctId')
        OR (o.[Name] = N'ExtlRecShrOpportunity' AND [__mj].[IntegrationObjectField].[Name] = N'ExtlRecShrCnctId')
        OR (o.[Name] = N'ExtlRecShrRecordMap' AND [__mj].[IntegrationObjectField].[Name] = N'ExtlRecShrCnctId')
      )
  );

-- Target: ExtlRecShrField.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ExtlRecShrField'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ExtlRecShrField'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ExtlRecShrField'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ExtlRecShrFieldMap' AND [__mj].[IntegrationObjectField].[Name] IN (N'ImportedFieldId', N'InternalFieldId'))
        OR (o.[Name] = N'ExtlRecShrPcklstOptn' AND [__mj].[IntegrationObjectField].[Name] = N'ExtlRecShrFieldId')
      )
  );

-- Target: ExtlRecShrObject.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ExtlRecShrObject'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ExtlRecShrObject'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ExtlRecShrObject'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ExtlRecShrField' AND [__mj].[IntegrationObjectField].[Name] = N'ExtlRecShrObjectId')
      )
  );

-- Target: ExtlRecShrPcklstOptn.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ExtlRecShrPcklstOptn'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ExtlRecShrPcklstOptn'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ExtlRecShrPcklstOptn'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ExtlRecShrPicklistMap' AND [__mj].[IntegrationObjectField].[Name] IN (N'ImportedPcklstOptionId', N'InternalPcklstOptionId'))
      )
  );

-- Target: FeedComment.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FeedComment'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FeedComment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'FeedComment'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'FeedItem' AND [__mj].[IntegrationObjectField].[Name] = N'BestCommentId')
      )
  );

-- Target: FeedItem.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FeedItem'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FeedItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'FeedItem'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'Announcement' AND [__mj].[IntegrationObjectField].[Name] = N'FeedItemId')
        OR (o.[Name] = N'WorkThanks' AND [__mj].[IntegrationObjectField].[Name] = N'FeedItemId')
      )
  );

-- Target: FeedPollChoice.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FeedPollChoice'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FeedPollChoice'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'FeedPollChoice'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'FeedPollVote' AND [__mj].[IntegrationObjectField].[Name] = N'ChoiceId')
      )
  );

-- Target: FiscalYearSettings.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FiscalYearSettings'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FiscalYearSettings'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'FiscalYearSettings'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'Period' AND [__mj].[IntegrationObjectField].[Name] = N'FiscalYearSettingsId')
      )
  );

-- Target: FldSvcObjChg.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FldSvcObjChg'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FldSvcObjChg'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'FldSvcObjChg'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'FldSvcObjChgDtl' AND [__mj].[IntegrationObjectField].[Name] = N'FldSvcObjChgId')
      )
  );

-- Target: FlowInterview.Id (6 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FlowInterview'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FlowInterview'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'FlowInterview'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'DynamicDataCapture' AND [__mj].[IntegrationObjectField].[Name] = N'PausedFlowInterviewId')
        OR (o.[Name] = N'FlowInterviewShare' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
        OR (o.[Name] = N'FlowOrchestrationInstance' AND [__mj].[IntegrationObjectField].[Name] = N'InterviewId')
        OR (o.[Name] = N'FlowRecordRelation' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
        OR (o.[Name] = N'FlowStageRelation' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
        OR (o.[Name] = N'RecordAction' AND [__mj].[IntegrationObjectField].[Name] = N'FlowInterviewId')
      )
  );

-- Target: FlowInterviewLog.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FlowInterviewLog'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FlowInterviewLog'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'FlowInterviewLog'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'FlowInterviewLogEntry' AND [__mj].[IntegrationObjectField].[Name] = N'FlowInterviewLogId')
      )
  );

GO

-- Target: FlowOrchestration.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FlowOrchestration'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FlowOrchestration'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'FlowOrchestration'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'FlowOrchestrationVersion' AND [__mj].[IntegrationObjectField].[Name] IN (N'FlowOrchestrationId', N'OverriddenById', N'OverriddenOrchestrationId', N'SourceTemplateId'))
      )
  );

-- Target: FlowOrchestrationInstance.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FlowOrchestrationInstance'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FlowOrchestrationInstance'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'FlowOrchestrationInstance'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ApprovalSubmission' AND [__mj].[IntegrationObjectField].[Name] = N'FlowOrchestrationInstanceId')
        OR (o.[Name] = N'FlowOrchestrationLog' AND [__mj].[IntegrationObjectField].[Name] = N'OrchestationInstanceId')
        OR (o.[Name] = N'FlowOrchestrationStageInstance' AND [__mj].[IntegrationObjectField].[Name] = N'OrchestrationInstanceId')
        OR (o.[Name] = N'FlowOrchestrationStepInstance' AND [__mj].[IntegrationObjectField].[Name] = N'OrchestrationInstanceId')
      )
  );

-- Target: FlowOrchestrationStageInstance.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FlowOrchestrationStageInstance'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FlowOrchestrationStageInstance'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'FlowOrchestrationStageInstance'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'FlowOrchestrationStepInstance' AND [__mj].[IntegrationObjectField].[Name] = N'StageInstanceId')
      )
  );

-- Target: FlowOrchestrationStepInstance.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FlowOrchestrationStepInstance'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FlowOrchestrationStepInstance'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'FlowOrchestrationStepInstance'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'FlowOrchestrationWorkItem' AND [__mj].[IntegrationObjectField].[Name] = N'StepInstanceId')
      )
  );

-- Target: FlowOrchestrationWorkItem.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FlowOrchestrationWorkItem'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FlowOrchestrationWorkItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'FlowOrchestrationWorkItem'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ApprovalWorkItem' AND [__mj].[IntegrationObjectField].[Name] = N'FlowOrchestrationWorkItemId')
      )
  );

-- Target: FlowRecord.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FlowRecord'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FlowRecord'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'FlowRecord'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'FlowRecordElementOccurrence' AND [__mj].[IntegrationObjectField].[Name] = N'FlowRecordId')
        OR (o.[Name] = N'FlowRecordVersion' AND [__mj].[IntegrationObjectField].[Name] IN (N'FlowRecordId', N'OverriddenById', N'SourceTemplateId'))
      )
  );

-- Target: FlowRecordElement.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FlowRecordElement'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FlowRecordElement'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'FlowRecordElement'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'FlowRecordElementOccurrence' AND [__mj].[IntegrationObjectField].[Name] = N'FlowRecordElementId')
      )
  );

-- Target: FlowRecordVersion.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FlowRecordVersion'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FlowRecordVersion'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'FlowRecordVersion'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'FlowRecordElementOccurrence' AND [__mj].[IntegrationObjectField].[Name] = N'FlowRecordVersionId')
      )
  );

-- Target: Folder.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Folder'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Folder'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Folder'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'QuickText' AND [__mj].[IntegrationObjectField].[Name] = N'FolderId')
        OR (o.[Name] = N'QuickTextUsage' AND [__mj].[IntegrationObjectField].[Name] = N'FolderId')
        OR (o.[Name] = N'WaveAutoInstallRequest' AND [__mj].[IntegrationObjectField].[Name] = N'FolderId')
      )
  );

-- Target: ForecastingColumnDefinition.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ForecastingColumnDefinition'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ForecastingColumnDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ForecastingColumnDefinition'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ForecastingColumnDefinitionLocalization' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
      )
  );

-- Target: ForecastingCustomCategory.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ForecastingCustomCategory'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ForecastingCustomCategory'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ForecastingCustomCategory'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'FrcstCustmCatgRampRateSrc' AND [__mj].[IntegrationObjectField].[Name] = N'ForecastingCustomCategoryId')
        OR (o.[Name] = N'FrcstCustmzAdjustment' AND [__mj].[IntegrationObjectField].[Name] = N'ForecastingCustomCategoryId')
        OR (o.[Name] = N'FrcstCustmzOwnerAdjustment' AND [__mj].[IntegrationObjectField].[Name] = N'ForecastingCustomCategoryId')
      )
  );

-- Target: ForecastingFilter.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ForecastingFilter'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ForecastingFilter'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ForecastingFilter'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ForecastingFilterCondition' AND [__mj].[IntegrationObjectField].[Name] = N'ForecastingFilterId')
      )
  );

-- Target: ForecastingGroup.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ForecastingGroup'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ForecastingGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ForecastingGroup'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ForecastingGroupItem' AND [__mj].[IntegrationObjectField].[Name] = N'ForecastingGroupId')
      )
  );

-- Target: ForecastingGroupItem.Id (6 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ForecastingGroupItem'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ForecastingGroupItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ForecastingGroupItem'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ForecastingAdjustment' AND [__mj].[IntegrationObjectField].[Name] = N'ForecastingGroupItemId')
        OR (o.[Name] = N'ForecastingCustomData' AND [__mj].[IntegrationObjectField].[Name] = N'ForecastingGroupItemId')
        OR (o.[Name] = N'ForecastingItem' AND [__mj].[IntegrationObjectField].[Name] = N'ForecastingGroupItemId')
        OR (o.[Name] = N'ForecastingOwnerAdjustment' AND [__mj].[IntegrationObjectField].[Name] = N'ForecastingGroupItemId')
        OR (o.[Name] = N'ForecastingQuota' AND [__mj].[IntegrationObjectField].[Name] = N'ForecastingGroupItemId')
        OR (o.[Name] = N'ForecastingSubmission' AND [__mj].[IntegrationObjectField].[Name] = N'ForecastingGroupItemId')
      )
  );

-- Target: ForecastingSourceDefinition.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ForecastingSourceDefinition'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ForecastingSourceDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ForecastingSourceDefinition'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ForecastingCustomCategory' AND [__mj].[IntegrationObjectField].[Name] = N'ForecastingSourceDefinitionId')
        OR (o.[Name] = N'ForecastingTypeSource' AND [__mj].[IntegrationObjectField].[Name] IN (N'ForecastingSourceDefinitionId', N'ParentSourceDefinitionId'))
        OR (o.[Name] = N'FrcstCustmCatgRampRateSrc' AND [__mj].[IntegrationObjectField].[Name] = N'BaseValueFrcstSrcDefinitionId')
      )
  );

-- Target: ForecastingType.Id (9 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ForecastingType'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ForecastingType'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ForecastingType'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ForecastingColumnDefinition' AND [__mj].[IntegrationObjectField].[Name] = N'ForecastingTypeId')
        OR (o.[Name] = N'ForecastingCustomCategory' AND [__mj].[IntegrationObjectField].[Name] = N'ForecastingTypeId')
        OR (o.[Name] = N'ForecastingCustomData' AND [__mj].[IntegrationObjectField].[Name] = N'ForecastingTypeId')
        OR (o.[Name] = N'ForecastingFilter' AND [__mj].[IntegrationObjectField].[Name] = N'ForecastingTypeId')
        OR (o.[Name] = N'ForecastingGroup' AND [__mj].[IntegrationObjectField].[Name] = N'ForecastingTypeId')
        OR (o.[Name] = N'ForecastingSubmission' AND [__mj].[IntegrationObjectField].[Name] = N'ForecastingTypeId')
        OR (o.[Name] = N'ForecastingTypeSource' AND [__mj].[IntegrationObjectField].[Name] = N'ForecastingTypeId')
        OR (o.[Name] = N'FrcstCustmzAdjustment' AND [__mj].[IntegrationObjectField].[Name] = N'ForecastingTypeId')
        OR (o.[Name] = N'FrcstCustmzOwnerAdjustment' AND [__mj].[IntegrationObjectField].[Name] = N'ForecastingTypeId')
      )
  );

-- Target: ForecastingTypeSource.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ForecastingTypeSource'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ForecastingTypeSource'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ForecastingTypeSource'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ForecastingFilter' AND [__mj].[IntegrationObjectField].[Name] = N'ForecastingTypeSourceId')
      )
  );

-- Target: FulfillmentOrder.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FulfillmentOrder'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'FulfillmentOrder'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'FulfillmentOrder'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'FulfillmentOrderLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'FulfillmentOrderId')
        OR (o.[Name] = N'PickTicketAssignment' AND [__mj].[IntegrationObjectField].[Name] = N'AttachedToId')
      )
  );

-- Target: GenAiPlannerDefinition.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'GenAiPlannerDefinition'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'GenAiPlannerDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'GenAiPlannerDefinition'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'GenAiFunctionDefinition' AND [__mj].[IntegrationObjectField].[Name] = N'PlannerId')
        OR (o.[Name] = N'GenAiPlannerFunctionDef' AND [__mj].[IntegrationObjectField].[Name] = N'PlannerId')
        OR (o.[Name] = N'GenAiPluginDefinition' AND [__mj].[IntegrationObjectField].[Name] = N'PlannerId')
        OR (o.[Name] = N'GenOpPlanRequest' AND [__mj].[IntegrationObjectField].[Name] = N'CopilotId')
      )
  );

-- Target: GenAiPlannerFunctionDef.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'GenAiPlannerFunctionDef'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'GenAiPlannerFunctionDef'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'GenAiPlannerFunctionDef'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'GenAiFunctionDefinition' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
      )
  );

-- Target: GenAiPluginDefinition.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'GenAiPluginDefinition'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'GenAiPluginDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'GenAiPluginDefinition'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'GenAiFunctionDefinition' AND [__mj].[IntegrationObjectField].[Name] = N'PluginId')
      )
  );

-- Target: GeoCountry.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'GeoCountry'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'GeoCountry'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'GeoCountry'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'GeoState' AND [__mj].[IntegrationObjectField].[Name] = N'GeoCountryId')
        OR (o.[Name] = N'TaxGeoConfig' AND [__mj].[IntegrationObjectField].[Name] = N'GeoCountryId')
        OR (o.[Name] = N'TaxRate' AND [__mj].[IntegrationObjectField].[Name] = N'GeoCountryId')
      )
  );

-- Target: GeoState.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'GeoState'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'GeoState'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'GeoState'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'TaxRate' AND [__mj].[IntegrationObjectField].[Name] = N'GeoStateId')
      )
  );

-- Target: Group.Id (12 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Group'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Group'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Group'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AgentWork' AND [__mj].[IntegrationObjectField].[Name] = N'OriginalGroupId')
        OR (o.[Name] = N'BroadcastTopicGroup' AND [__mj].[IntegrationObjectField].[Name] = N'GroupId')
        OR (o.[Name] = N'ContactCenterChannel' AND [__mj].[IntegrationObjectField].[Name] IN (N'OmniCallbackFallbackQueueId', N'VoicemailFallbackQueueId'))
        OR (o.[Name] = N'GroupMember' AND [__mj].[IntegrationObjectField].[Name] = N'GroupId')
        OR (o.[Name] = N'JobProfileQueueGroup' AND [__mj].[IntegrationObjectField].[Name] = N'GroupId')
        OR (o.[Name] = N'LiveChatButton' AND [__mj].[IntegrationObjectField].[Name] = N'QueueId')
        OR (o.[Name] = N'MessagingChannel' AND [__mj].[IntegrationObjectField].[Name] = N'TargetQueueId')
        OR (o.[Name] = N'OmniSupervisorConfigGroup' AND [__mj].[IntegrationObjectField].[Name] = N'GroupId')
        OR (o.[Name] = N'OmniSupervisorConfigQueue' AND [__mj].[IntegrationObjectField].[Name] = N'QueueId')
        OR (o.[Name] = N'QueueSobject' AND [__mj].[IntegrationObjectField].[Name] = N'QueueId')
        OR (o.[Name] = N'ServiceRequest' AND [__mj].[IntegrationObjectField].[Name] = N'AssignedGroupId')
      )
  );

-- Target: Holiday.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Holiday'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Holiday'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Holiday'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'OperatingHoursHoliday' AND [__mj].[IntegrationObjectField].[Name] = N'HolidayId')
      )
  );

GO

-- Target: Idea.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Idea'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Idea'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Idea'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'IdeaComment' AND [__mj].[IntegrationObjectField].[Name] = N'IdeaId')
      )
  );

-- Target: Incident.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Incident'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Incident'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Incident'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'BroadcastCommunication' AND [__mj].[IntegrationObjectField].[Name] = N'RelatedRecordId')
        OR (o.[Name] = N'IncidentRelatedItem' AND [__mj].[IntegrationObjectField].[Name] = N'IncidentId')
      )
  );

-- Target: Individual.Id (9 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Individual'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Individual'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Individual'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CommSubscriptionConsent' AND [__mj].[IntegrationObjectField].[Name] = N'PartyId')
        OR (o.[Name] = N'Contact' AND [__mj].[IntegrationObjectField].[Name] = N'IndividualId')
        OR (o.[Name] = N'ContactPointTypeConsent' AND [__mj].[IntegrationObjectField].[Name] = N'PartyId')
        OR (o.[Name] = N'Customer' AND [__mj].[IntegrationObjectField].[Name] = N'PartyId')
        OR (o.[Name] = N'IndividualHistory' AND [__mj].[IntegrationObjectField].[Name] = N'IndividualId')
        OR (o.[Name] = N'IndividualShare' AND [__mj].[IntegrationObjectField].[Name] = N'IndividualId')
        OR (o.[Name] = N'Lead' AND [__mj].[IntegrationObjectField].[Name] = N'IndividualId')
        OR (o.[Name] = N'PartyConsent' AND [__mj].[IntegrationObjectField].[Name] = N'PartyId')
        OR (o.[Name] = N'Seller' AND [__mj].[IntegrationObjectField].[Name] = N'PartyId')
      )
  );

-- Target: InternalOrganizationUnit.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'InternalOrganizationUnit'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'InternalOrganizationUnit'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'InternalOrganizationUnit'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'Employee2' AND [__mj].[IntegrationObjectField].[Name] = N'InternalOrganizationUnitId')
      )
  );

-- Target: InventoryReservation.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'InventoryReservation'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'InventoryReservation'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'InventoryReservation'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'InventoryItemReservation' AND [__mj].[IntegrationObjectField].[Name] = N'InventoryReservationId')
      )
  );

-- Target: Invoice.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Invoice'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Invoice'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Invoice'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'FulfillmentOrder' AND [__mj].[IntegrationObjectField].[Name] = N'InvoiceId')
        OR (o.[Name] = N'InvoiceAddressGroup' AND [__mj].[IntegrationObjectField].[Name] = N'InvoiceId')
        OR (o.[Name] = N'InvoiceLine' AND [__mj].[IntegrationObjectField].[Name] = N'InvoiceId')
        OR (o.[Name] = N'PaymentLineInvoice' AND [__mj].[IntegrationObjectField].[Name] = N'InvoiceId')
      )
  );

-- Target: InvoiceAddressGroup.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'InvoiceAddressGroup'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'InvoiceAddressGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'InvoiceAddressGroup'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'InvoiceLine' AND [__mj].[IntegrationObjectField].[Name] IN (N'BillingAddressId', N'ShippingAddressId'))
      )
  );

-- Target: InvoiceBatchRun.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'InvoiceBatchRun'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'InvoiceBatchRun'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'InvoiceBatchRun'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'BillingPeriodItem' AND [__mj].[IntegrationObjectField].[Name] = N'InvoiceBatchRunId')
        OR (o.[Name] = N'BillingSchedule' AND [__mj].[IntegrationObjectField].[Name] = N'InvoiceBatchRunId')
        OR (o.[Name] = N'Invoice' AND [__mj].[IntegrationObjectField].[Name] = N'InvoiceBatchRunId')
        OR (o.[Name] = N'InvoiceBatchRunRecovery' AND [__mj].[IntegrationObjectField].[Name] = N'InvoiceBatchRunId')
      )
  );

-- Target: InvoiceLine.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'InvoiceLine'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'InvoiceLine'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'InvoiceLine'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'BillingPeriodItem' AND [__mj].[IntegrationObjectField].[Name] = N'InvoiceLineId')
      )
  );

-- Target: JobProfile.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'JobProfile'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'JobProfile'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'JobProfile'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'JobProfileQueueGroup' AND [__mj].[IntegrationObjectField].[Name] = N'JobProfileId')
        OR (o.[Name] = N'SchedulingAdherenceSummary' AND [__mj].[IntegrationObjectField].[Name] = N'JobProfileId')
        OR (o.[Name] = N'ShiftTemplate' AND [__mj].[IntegrationObjectField].[Name] = N'JobProfileId')
        OR (o.[Name] = N'WorkDemographic' AND [__mj].[IntegrationObjectField].[Name] = N'JobProfileId')
      )
  );

-- Target: Knowledge__kav.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Knowledge__kav'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Knowledge__kav'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Knowledge__kav'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'SearchActivity' AND [__mj].[IntegrationObjectField].[Name] = N'ClickedRecordId')
      )
  );

-- Target: Lead.Id (8 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Lead'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Lead'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Lead'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CampaignMember' AND [__mj].[IntegrationObjectField].[Name] = N'LeadId')
        OR (o.[Name] = N'DealIndirectPartner' AND [__mj].[IntegrationObjectField].[Name] = N'LeadId')
        OR (o.[Name] = N'ExtlRecShrRecordMap' AND [__mj].[IntegrationObjectField].[Name] = N'InternalRecordId')
        OR (o.[Name] = N'LeadDailyMetric' AND [__mj].[IntegrationObjectField].[Name] = N'LeadId')
        OR (o.[Name] = N'LeadMonthlyMetric' AND [__mj].[IntegrationObjectField].[Name] = N'LeadId')
        OR (o.[Name] = N'LeadShare' AND [__mj].[IntegrationObjectField].[Name] = N'LeadId')
        OR (o.[Name] = N'MessagingEndUser' AND [__mj].[IntegrationObjectField].[Name] = N'LeadId')
        OR (o.[Name] = N'Prospect' AND [__mj].[IntegrationObjectField].[Name] = N'ConvertedLeadId')
      )
  );

-- Target: LearningItem.Id (5 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'LearningItem'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'LearningItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'LearningItem'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'EnblProgramTaskDefinition' AND [__mj].[IntegrationObjectField].[Name] = N'LearningItemId')
        OR (o.[Name] = N'LearningItemAssignment' AND [__mj].[IntegrationObjectField].[Name] = N'LearningItemId')
        OR (o.[Name] = N'LearningItemProgress' AND [__mj].[IntegrationObjectField].[Name] = N'LearningItemId')
        OR (o.[Name] = N'LearningItemSubmission' AND [__mj].[IntegrationObjectField].[Name] = N'LearningItemId')
        OR (o.[Name] = N'LearningPractice' AND [__mj].[IntegrationObjectField].[Name] = N'LearningItemId')
      )
  );

-- Target: LearningItemProgress.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'LearningItemProgress'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'LearningItemProgress'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'LearningItemProgress'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'EnblProgramTaskProgress' AND [__mj].[IntegrationObjectField].[Name] = N'LearningItemProgressId')
        OR (o.[Name] = N'LearningItemAssignment' AND [__mj].[IntegrationObjectField].[Name] = N'ProgressId')
      )
  );

-- Target: LearningItemType.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'LearningItemType'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'LearningItemType'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'LearningItemType'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'EnblProgramTaskSubCategory' AND [__mj].[IntegrationObjectField].[Name] = N'LearningItemTypeId')
        OR (o.[Name] = N'LearningItem' AND [__mj].[IntegrationObjectField].[Name] = N'CustomLearningItemTypeId')
      )
  );

-- Target: LegalEntity.Id (7 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'LegalEntity'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'LegalEntity'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'LegalEntity'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AssetActionSource' AND [__mj].[IntegrationObjectField].[Name] = N'LegalEntityId')
        OR (o.[Name] = N'AssetStatePeriod' AND [__mj].[IntegrationObjectField].[Name] = N'LegalEntityId')
        OR (o.[Name] = N'BillingTreatment' AND [__mj].[IntegrationObjectField].[Name] = N'LegalEntityId')
        OR (o.[Name] = N'InvoiceLine' AND [__mj].[IntegrationObjectField].[Name] = N'LegalEntityId')
        OR (o.[Name] = N'Payment' AND [__mj].[IntegrationObjectField].[Name] = N'LegalEntityId')
        OR (o.[Name] = N'QuoteLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'LegalEntityId')
        OR (o.[Name] = N'TaxRate' AND [__mj].[IntegrationObjectField].[Name] = N'LegalEntityId')
      )
  );

-- Target: LinkedArticle.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'LinkedArticle'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'LinkedArticle'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'LinkedArticle'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'KnowledgeArticleFeedback' AND [__mj].[IntegrationObjectField].[Name] = N'LinkedArticleEntityId')
      )
  );

-- Target: ListEmail.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ListEmail'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ListEmail'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ListEmail'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ListEmailIndividualRecipient' AND [__mj].[IntegrationObjectField].[Name] = N'ListEmailId')
        OR (o.[Name] = N'ListEmailMonthlyMetric' AND [__mj].[IntegrationObjectField].[Name] = N'ListEmailId')
        OR (o.[Name] = N'ListEmailRecipientSource' AND [__mj].[IntegrationObjectField].[Name] = N'ListEmailId')
      )
  );

-- Target: ListView.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ListView'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ListView'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ListView'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CalendarView' AND [__mj].[IntegrationObjectField].[Name] = N'ListViewFilterId')
        OR (o.[Name] = N'ListViewChartInstance' AND [__mj].[IntegrationObjectField].[Name] = N'ListViewContextId')
        OR (o.[Name] = N'PipelineInspectionListView' AND [__mj].[IntegrationObjectField].[Name] = N'ListViewId')
        OR (o.[Name] = N'UserListView' AND [__mj].[IntegrationObjectField].[Name] = N'ListViewId')
      )
  );

-- Target: ListViewChart.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ListViewChart'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ListViewChart'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ListViewChart'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ListViewChartInstance' AND [__mj].[IntegrationObjectField].[Name] = N'ListViewChartId')
      )
  );

-- Target: LiveChatObjectAccessDefinition.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'LiveChatObjectAccessDefinition'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'LiveChatObjectAccessDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'LiveChatObjectAccessDefinition'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'LiveChatObjectAccessConfig' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
      )
  );

-- Target: Location.Id (21 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Location'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Location'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Location'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'Address' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
        OR (o.[Name] = N'AssociatedLocation' AND [__mj].[IntegrationObjectField].[Name] = N'LocationId')
        OR (o.[Name] = N'FulfillmentOrder' AND [__mj].[IntegrationObjectField].[Name] = N'FulfilledFromLocationId')
        OR (o.[Name] = N'PickTicket' AND [__mj].[IntegrationObjectField].[Name] = N'LocationId')
        OR (o.[Name] = N'PriceProtectExecLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'LocationId')
        OR (o.[Name] = N'ProductItem' AND [__mj].[IntegrationObjectField].[Name] = N'LocationId')
        OR (o.[Name] = N'ProductRequest' AND [__mj].[IntegrationObjectField].[Name] IN (N'DestinationLocationId', N'SourceLocationId'))
        OR (o.[Name] = N'ProductRequestLineItem' AND [__mj].[IntegrationObjectField].[Name] IN (N'DestinationLocationId', N'SourceLocationId'))
        OR (o.[Name] = N'ProductTransfer' AND [__mj].[IntegrationObjectField].[Name] IN (N'DestinationLocationId', N'SourceLocationId'))
        OR (o.[Name] = N'ReturnOrder' AND [__mj].[IntegrationObjectField].[Name] IN (N'DestinationLocationId', N'SourceLocationId'))
        OR (o.[Name] = N'ReturnOrderLineItem' AND [__mj].[IntegrationObjectField].[Name] IN (N'DestinationLocationId', N'SourceLocationId'))
        OR (o.[Name] = N'ServiceResource' AND [__mj].[IntegrationObjectField].[Name] = N'LocationId')
        OR (o.[Name] = N'Shipment' AND [__mj].[IntegrationObjectField].[Name] IN (N'DestinationLocationId', N'SourceLocationId'))
        OR (o.[Name] = N'WorkOrder' AND [__mj].[IntegrationObjectField].[Name] = N'LocationId')
        OR (o.[Name] = N'WorkOrderLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'LocationId')
      )
  );

-- Target: LocationGroup.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'LocationGroup'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'LocationGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'LocationGroup'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'DeliveryEstimationSetup' AND [__mj].[IntegrationObjectField].[Name] = N'LocationGroupId')
      )
  );

-- Target: LoginGeo.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'LoginGeo'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'LoginGeo'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'LoginGeo'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AuthSession' AND [__mj].[IntegrationObjectField].[Name] = N'LoginGeoId')
        OR (o.[Name] = N'LoginHistory' AND [__mj].[IntegrationObjectField].[Name] = N'LoginGeoId')
        OR (o.[Name] = N'VerificationHistory' AND [__mj].[IntegrationObjectField].[Name] = N'LoginGeoId')
      )
  );

-- Target: LoginHistory.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'LoginHistory'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'LoginHistory'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'LoginHistory'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AuthSession' AND [__mj].[IntegrationObjectField].[Name] = N'LoginHistoryId')
        OR (o.[Name] = N'VerificationHistory' AND [__mj].[IntegrationObjectField].[Name] = N'LoginHistoryId')
      )
  );

GO

-- Target: ManagedContent.Id (5 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ManagedContent'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ManagedContent'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ManagedContent'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'Brief' AND [__mj].[IntegrationObjectField].[Name] = N'BrandId')
        OR (o.[Name] = N'ManagedContentVariant' AND [__mj].[IntegrationObjectField].[Name] = N'ManagedContentId')
        OR (o.[Name] = N'NetworkDataCategory' AND [__mj].[IntegrationObjectField].[Name] = N'ImageId')
        OR (o.[Name] = N'UserRelatedRecordContent' AND [__mj].[IntegrationObjectField].[Name] = N'ManagedContentId')
        OR (o.[Name] = N'WebStoreMessageContent' AND [__mj].[IntegrationObjectField].[Name] = N'ManagedContentId')
      )
  );

-- Target: ManagedContentSpace.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ManagedContentSpace'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ManagedContentSpace'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ManagedContentSpace'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ManagedContent' AND [__mj].[IntegrationObjectField].[Name] = N'AuthoredManagedContentSpaceId')
      )
  );

-- Target: MatchingRule.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'MatchingRule'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'MatchingRule'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'MatchingRule'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'MatchingRuleItem' AND [__mj].[IntegrationObjectField].[Name] = N'MatchingRuleId')
      )
  );

-- Target: MerchAccPaymentMethodSet.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'MerchAccPaymentMethodSet'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'MerchAccPaymentMethodSet'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'MerchAccPaymentMethodSet'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'MerchAccPaymentMethodType' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentMethodSetId')
        OR (o.[Name] = N'PaymentLink' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentMethodSetId')
      )
  );

-- Target: MerchantAccount.Id (5 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'MerchantAccount'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'MerchantAccount'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'MerchantAccount'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'MerchAccPaymentMethodSet' AND [__mj].[IntegrationObjectField].[Name] = N'MerchantAccountId')
        OR (o.[Name] = N'MerchantAccountEvent' AND [__mj].[IntegrationObjectField].[Name] = N'MerchantAccountId')
        OR (o.[Name] = N'PaymentGateway' AND [__mj].[IntegrationObjectField].[Name] = N'MerchantAccountId')
        OR (o.[Name] = N'PaymentIntent' AND [__mj].[IntegrationObjectField].[Name] = N'MerchantAccountId')
        OR (o.[Name] = N'SavedPaymentMethod' AND [__mj].[IntegrationObjectField].[Name] = N'MerchantAccountId')
      )
  );

-- Target: MessagingChannel.Id (9 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'MessagingChannel'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'MessagingChannel'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'MessagingChannel'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ContactCenterChannel' AND [__mj].[IntegrationObjectField].[Name] = N'ChannelId')
        OR (o.[Name] = N'CustomMsgChannel' AND [__mj].[IntegrationObjectField].[Name] = N'MessagingChannelId')
        OR (o.[Name] = N'MessagingChannelSkill' AND [__mj].[IntegrationObjectField].[Name] = N'MessagingChannelId')
        OR (o.[Name] = N'MessagingChannelUsage' AND [__mj].[IntegrationObjectField].[Name] = N'MessagingChannelId')
        OR (o.[Name] = N'MessagingDeliveryError' AND [__mj].[IntegrationObjectField].[Name] = N'MessagingChannelId')
        OR (o.[Name] = N'MessagingEndUser' AND [__mj].[IntegrationObjectField].[Name] = N'MessagingChannelId')
        OR (o.[Name] = N'MessagingLink' AND [__mj].[IntegrationObjectField].[Name] = N'MessagingChannelId')
        OR (o.[Name] = N'MessagingSession' AND [__mj].[IntegrationObjectField].[Name] = N'MessagingChannelId')
        OR (o.[Name] = N'MsgChannelLanguageKeyword' AND [__mj].[IntegrationObjectField].[Name] = N'MessagingChannelId')
      )
  );

-- Target: MessagingChannelUsage.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'MessagingChannelUsage'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'MessagingChannelUsage'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'MessagingChannelUsage'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CommSubscriptionChannelType' AND [__mj].[IntegrationObjectField].[Name] = N'MessagingChannelUsageId')
        OR (o.[Name] = N'MsgChannelLanguageKeyword' AND [__mj].[IntegrationObjectField].[Name] = N'MessagingChannelUsageId')
        OR (o.[Name] = N'MsgChannelUsageExternalOrg' AND [__mj].[IntegrationObjectField].[Name] = N'MessagingChannelUsageId')
      )
  );

-- Target: MessagingEndUser.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'MessagingEndUser'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'MessagingEndUser'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'MessagingEndUser'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'MessagingDeliveryError' AND [__mj].[IntegrationObjectField].[Name] = N'MessagingEndUserId')
        OR (o.[Name] = N'MessagingSession' AND [__mj].[IntegrationObjectField].[Name] = N'MessagingEndUserId')
        OR (o.[Name] = N'VoiceCall' AND [__mj].[IntegrationObjectField].[Name] = N'EndUserId')
      )
  );

-- Target: MessagingTemplate.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'MessagingTemplate'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'MessagingTemplate'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'MessagingTemplate'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'MessagingDeliveryError' AND [__mj].[IntegrationObjectField].[Name] = N'MessagingTemplateId')
      )
  );

-- Target: MLModel.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'MLModel'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'MLModel'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'MLModel'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AIRecordInsight' AND [__mj].[IntegrationObjectField].[Name] = N'ModelId')
        OR (o.[Name] = N'MLModelFactor' AND [__mj].[IntegrationObjectField].[Name] = N'ModelId')
        OR (o.[Name] = N'MLModelFactorComponent' AND [__mj].[IntegrationObjectField].[Name] = N'ModelId')
        OR (o.[Name] = N'MLModelMetric' AND [__mj].[IntegrationObjectField].[Name] = N'ModelId')
      )
  );

-- Target: MLModelFactor.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'MLModelFactor'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'MLModelFactor'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'MLModelFactor'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'MLModelFactorComponent' AND [__mj].[IntegrationObjectField].[Name] = N'ModelFactorId')
      )
  );

-- Target: MLPredictionDefinition.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'MLPredictionDefinition'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'MLPredictionDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'MLPredictionDefinition'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AIRecordInsight' AND [__mj].[IntegrationObjectField].[Name] = N'MlPredictionDefinitionId')
        OR (o.[Name] = N'MLModel' AND [__mj].[IntegrationObjectField].[Name] = N'PredictionDefinitionId')
      )
  );

-- Target: MLRecommendationDefinition.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'MLRecommendationDefinition'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'MLRecommendationDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'MLRecommendationDefinition'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'MLModel' AND [__mj].[IntegrationObjectField].[Name] = N'RecommendationDefinitionId')
      )
  );

-- Target: MobileSecurityAssignment.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'MobileSecurityAssignment'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'MobileSecurityAssignment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'MobileSecurityAssignment'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'MobileSecurityPolicy' AND [__mj].[IntegrationObjectField].[Name] = N'MobileSecurityAssignmentId')
        OR (o.[Name] = N'MobSecurityCertPinConfig' AND [__mj].[IntegrationObjectField].[Name] = N'MobileSecurityAssignmentId')
      )
  );

-- Target: NamedCredential.Id (7 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'NamedCredential'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'NamedCredential'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'NamedCredential'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ExternalClientApplication' AND [__mj].[IntegrationObjectField].[Name] = N'NamedCredentialId')
        OR (o.[Name] = N'ExternalDataSource' AND [__mj].[IntegrationObjectField].[Name] = N'NamedCredentialId')
        OR (o.[Name] = N'ExtKnowledgeConnector' AND [__mj].[IntegrationObjectField].[Name] = N'NamedCredentialId')
        OR (o.[Name] = N'ExtlRecShrCnct' AND [__mj].[IntegrationObjectField].[Name] = N'NamedCredentialId')
        OR (o.[Name] = N'PaymentGateway' AND [__mj].[IntegrationObjectField].[Name] = N'MerchantCredentialId')
        OR (o.[Name] = N'TaxEngine' AND [__mj].[IntegrationObjectField].[Name] = N'MerchantCredentialId')
        OR (o.[Name] = N'UserProvisioningConfig' AND [__mj].[IntegrationObjectField].[Name] = N'NamedCredentialId')
      )
  );

-- Target: Network.Id (7 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Network'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Network'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Network'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'BroadcastTopicNetwork' AND [__mj].[IntegrationObjectField].[Name] = N'NetworkId')
        OR (o.[Name] = N'EnablementProgram' AND [__mj].[IntegrationObjectField].[Name] = N'NetworkId')
        OR (o.[Name] = N'NetworkAuthApiSettings' AND [__mj].[IntegrationObjectField].[Name] = N'NetworkId')
        OR (o.[Name] = N'NetworkDataCategory' AND [__mj].[IntegrationObjectField].[Name] = N'NetworkId')
        OR (o.[Name] = N'NetworkEmailTmplAllowlist' AND [__mj].[IntegrationObjectField].[Name] = N'NetworkId')
        OR (o.[Name] = N'RecommendationResponse' AND [__mj].[IntegrationObjectField].[Name] = N'NetworkId')
        OR (o.[Name] = N'WebStoreNetwork' AND [__mj].[IntegrationObjectField].[Name] = N'NetworkId')
      )
  );

-- Target: OauthCustomScope.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OauthCustomScope'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OauthCustomScope'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'OauthCustomScope'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'OauthCustomScopeApp' AND [__mj].[IntegrationObjectField].[Name] = N'OauthCustomScopeId')
      )
  );

-- Target: OauthTokenExchangeHandler.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OauthTokenExchangeHandler'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OauthTokenExchangeHandler'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'OauthTokenExchangeHandler'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'OauthTokenExchHandlerApp' AND [__mj].[IntegrationObjectField].[Name] = N'OauthTokenExchangeHandlerId')
      )
  );

-- Target: ObjectDataImport.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ObjectDataImport'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ObjectDataImport'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ObjectDataImport'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ObjectDataImportReference' AND [__mj].[IntegrationObjectField].[Name] = N'ObjectDataImportId')
      )
  );

-- Target: OmniSupervisorConfig.Id (7 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OmniSupervisorConfig'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OmniSupervisorConfig'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'OmniSupervisorConfig'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'OmniSupervisorConfigAction' AND [__mj].[IntegrationObjectField].[Name] = N'OmniSupervisorConfigId')
        OR (o.[Name] = N'OmniSupervisorConfigGroup' AND [__mj].[IntegrationObjectField].[Name] = N'OmniSupervisorConfigId')
        OR (o.[Name] = N'OmniSupervisorConfigProfile' AND [__mj].[IntegrationObjectField].[Name] = N'OmniSupervisorConfigId')
        OR (o.[Name] = N'OmniSupervisorConfigQueue' AND [__mj].[IntegrationObjectField].[Name] = N'OmniSupervisorConfigId')
        OR (o.[Name] = N'OmniSupervisorConfigSkill' AND [__mj].[IntegrationObjectField].[Name] = N'OmniSupervisorConfigId')
        OR (o.[Name] = N'OmniSupervisorConfigTab' AND [__mj].[IntegrationObjectField].[Name] = N'OmniSupervisorConfigId')
        OR (o.[Name] = N'OmniSupervisorConfigUser' AND [__mj].[IntegrationObjectField].[Name] = N'OmniSupervisorConfigId')
      )
  );

-- Target: OperatingHours.Id (7 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OperatingHours'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OperatingHours'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'OperatingHours'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'Account' AND [__mj].[IntegrationObjectField].[Name] = N'OperatingHoursId')
        OR (o.[Name] = N'AppointmentTopicTimeSlot' AND [__mj].[IntegrationObjectField].[Name] = N'OperatingHoursId')
        OR (o.[Name] = N'OperatingHoursHoliday' AND [__mj].[IntegrationObjectField].[Name] = N'OperatingHoursId')
        OR (o.[Name] = N'ServiceResourcePreference' AND [__mj].[IntegrationObjectField].[Name] = N'OperatingHoursId')
        OR (o.[Name] = N'ServiceTerritory' AND [__mj].[IntegrationObjectField].[Name] = N'OperatingHoursId')
        OR (o.[Name] = N'ServiceTerritoryMember' AND [__mj].[IntegrationObjectField].[Name] = N'OperatingHoursId')
        OR (o.[Name] = N'TimeSlot' AND [__mj].[IntegrationObjectField].[Name] = N'OperatingHoursId')
      )
  );

-- Target: Opportunity.Id (19 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Opportunity'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Opportunity'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Opportunity'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AccountPartner' AND [__mj].[IntegrationObjectField].[Name] = N'OpportunityId')
        OR (o.[Name] = N'DealIndirectPartner' AND [__mj].[IntegrationObjectField].[Name] = N'OpportunityId')
        OR (o.[Name] = N'FieldChangeSnapshot' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
        OR (o.[Name] = N'ForecastingSrcRecJudgment' AND [__mj].[IntegrationObjectField].[Name] = N'ReferenceObjectId')
        OR (o.[Name] = N'Lead' AND [__mj].[IntegrationObjectField].[Name] = N'ConvertedOpportunityId')
        OR (o.[Name] = N'OpportunityCompetitor' AND [__mj].[IntegrationObjectField].[Name] = N'OpportunityId')
        OR (o.[Name] = N'OpportunityContactRole' AND [__mj].[IntegrationObjectField].[Name] = N'OpportunityId')
        OR (o.[Name] = N'OpportunityFieldHistory' AND [__mj].[IntegrationObjectField].[Name] = N'OpportunityId')
        OR (o.[Name] = N'OpportunityHistory' AND [__mj].[IntegrationObjectField].[Name] = N'OpportunityId')
        OR (o.[Name] = N'OpportunityLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'OpportunityId')
        OR (o.[Name] = N'OpportunityPartner' AND [__mj].[IntegrationObjectField].[Name] = N'OpportunityId')
        OR (o.[Name] = N'OpportunityRelatedDeleteLog' AND [__mj].[IntegrationObjectField].[Name] = N'OpportunityId')
        OR (o.[Name] = N'OpportunityShare' AND [__mj].[IntegrationObjectField].[Name] = N'OpportunityId')
        OR (o.[Name] = N'OpportunitySplit' AND [__mj].[IntegrationObjectField].[Name] = N'OpportunityId')
        OR (o.[Name] = N'Partner' AND [__mj].[IntegrationObjectField].[Name] = N'OpportunityId')
        OR (o.[Name] = N'PaymentInitiationSource' AND [__mj].[IntegrationObjectField].[Name] = N'OpportunityId')
        OR (o.[Name] = N'Prospect' AND [__mj].[IntegrationObjectField].[Name] = N'ConvertedOpportunityId')
        OR (o.[Name] = N'RecentFieldChange' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
        OR (o.[Name] = N'SfdcPartnerOffer' AND [__mj].[IntegrationObjectField].[Name] = N'OpportunityId')
      )
  );

-- Target: OpportunityLineItem.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OpportunityLineItem'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OpportunityLineItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'OpportunityLineItem'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'OpportunityLineItemSplit' AND [__mj].[IntegrationObjectField].[Name] = N'OpportunityLineItemId')
      )
  );

-- Target: OpportunitySplitType.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OpportunitySplitType'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OpportunitySplitType'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'OpportunitySplitType'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ForecastingType' AND [__mj].[IntegrationObjectField].[Name] = N'OpportunitySplitTypeId')
        OR (o.[Name] = N'OpportunitySplit' AND [__mj].[IntegrationObjectField].[Name] = N'SplitTypeId')
        OR (o.[Name] = N'OpptyLineItemSplitType' AND [__mj].[IntegrationObjectField].[Name] = N'OpportunitySplitTypeId')
      )
  );

-- Target: OpptyLineItemSplitType.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OpptyLineItemSplitType'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OpptyLineItemSplitType'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'OpptyLineItemSplitType'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ForecastingType' AND [__mj].[IntegrationObjectField].[Name] = N'OpptyLineItemSplitTypeId')
        OR (o.[Name] = N'OpportunityLineItemSplit' AND [__mj].[IntegrationObjectField].[Name] = N'SplitTypeId')
      )
  );

GO

-- Target: Order.Id (18 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Order'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Order'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Order'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'BillingSchedule' AND [__mj].[IntegrationObjectField].[Name] = N'ReferenceEntityId')
        OR (o.[Name] = N'FulfillmentOrder' AND [__mj].[IntegrationObjectField].[Name] = N'OrderId')
        OR (o.[Name] = N'OrderAction' AND [__mj].[IntegrationObjectField].[Name] = N'OrderId')
        OR (o.[Name] = N'OrderAdjustmentGroup' AND [__mj].[IntegrationObjectField].[Name] = N'OrderId')
        OR (o.[Name] = N'OrderChangeLog' AND [__mj].[IntegrationObjectField].[Name] = N'ChangeOrderId')
        OR (o.[Name] = N'OrderHistory' AND [__mj].[IntegrationObjectField].[Name] = N'OrderId')
        OR (o.[Name] = N'OrderItem' AND [__mj].[IntegrationObjectField].[Name] = N'OrderId')
        OR (o.[Name] = N'OrderItemRelationship' AND [__mj].[IntegrationObjectField].[Name] = N'OrderId')
        OR (o.[Name] = N'OrderShare' AND [__mj].[IntegrationObjectField].[Name] = N'OrderId')
        OR (o.[Name] = N'OrderSummary' AND [__mj].[IntegrationObjectField].[Name] = N'OriginalOrderId')
        OR (o.[Name] = N'OrderSummaryAdditionalInfo' AND [__mj].[IntegrationObjectField].[Name] = N'OrderId')
        OR (o.[Name] = N'OSAsyncChgCompletedEvent' AND [__mj].[IntegrationObjectField].[Name] IN (N'FeeChangeOrderId', N'InFulfillmentChangeOrderId', N'PostFulfillmentChangeOrderId', N'PreFulfillmentChangeOrderId'))
        OR (o.[Name] = N'PaymentGroup' AND [__mj].[IntegrationObjectField].[Name] = N'SourceObjectId')
        OR (o.[Name] = N'ReturnOrder' AND [__mj].[IntegrationObjectField].[Name] = N'OrderId')
        OR (o.[Name] = N'WorkOrderLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'OrderId')
      )
  );

-- Target: OrderDeliveryGroup.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OrderDeliveryGroup'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OrderDeliveryGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'OrderDeliveryGroup'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'OrderItem' AND [__mj].[IntegrationObjectField].[Name] = N'OrderDeliveryGroupId')
      )
  );

-- Target: OrderDeliveryGroupSummary.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OrderDeliveryGroupSummary'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OrderDeliveryGroupSummary'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'OrderDeliveryGroupSummary'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'OrderItemSummary' AND [__mj].[IntegrationObjectField].[Name] = N'SummaryId')
      )
  );

-- Target: OrderDeliveryMethod.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OrderDeliveryMethod'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OrderDeliveryMethod'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'OrderDeliveryMethod'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CartDeliveryGroup' AND [__mj].[IntegrationObjectField].[Name] = N'DeliveryMethodId')
        OR (o.[Name] = N'FulfillmentOrder' AND [__mj].[IntegrationObjectField].[Name] = N'DeliveryMethodId')
      )
  );

-- Target: OrderItem.Id (10 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OrderItem'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OrderItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'OrderItem'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'FulfillmentOrderLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'OrderItemId')
        OR (o.[Name] = N'OrderAction' AND [__mj].[IntegrationObjectField].[Name] = N'OffsetOrderItemId')
        OR (o.[Name] = N'OrderItemRelationship' AND [__mj].[IntegrationObjectField].[Name] IN (N'AssociatedOrderItemId', N'MainOrderItemId', N'RootOrderItemId'))
        OR (o.[Name] = N'OrderItemSummary' AND [__mj].[IntegrationObjectField].[Name] = N'OriginalOrderItemId')
        OR (o.[Name] = N'QuoteLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'RelatedQuoteLineItemId')
        OR (o.[Name] = N'QuoteLineWorkSource' AND [__mj].[IntegrationObjectField].[Name] = N'OrderItemId')
        OR (o.[Name] = N'ReturnOrderLineItem' AND [__mj].[IntegrationObjectField].[Name] IN (N'ChangeOrderItemId', N'OrderItemId'))
      )
  );

-- Target: OrderItemRelationship.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OrderItemRelationship'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OrderItemRelationship'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'OrderItemRelationship'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'OrderItemSummaryRelationship' AND [__mj].[IntegrationObjectField].[Name] = N'OrderItemRelationshipId')
      )
  );

-- Target: OrderItemSummary.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OrderItemSummary'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OrderItemSummary'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'OrderItemSummary'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'FulfillmentOrderLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'OrderItemSummaryId')
        OR (o.[Name] = N'OrderItemSummaryRelationship' AND [__mj].[IntegrationObjectField].[Name] = N'AssociatedOrderItemSummaryId')
      )
  );

-- Target: OrderPaymentSummary.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OrderPaymentSummary'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OrderPaymentSummary'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'OrderPaymentSummary'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'OrderPaymentSummaryReference' AND [__mj].[IntegrationObjectField].[Name] = N'OrderPaymentSummaryId')
        OR (o.[Name] = N'PaymentCredit' AND [__mj].[IntegrationObjectField].[Name] = N'OrderPaymentSummaryId')
      )
  );

-- Target: OrderSummary.Id (11 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OrderSummary'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OrderSummary'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'OrderSummary'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'FulfillmentOrder' AND [__mj].[IntegrationObjectField].[Name] = N'OrderSummaryId')
        OR (o.[Name] = N'OrderItemSummary' AND [__mj].[IntegrationObjectField].[Name] = N'OrderSummaryId')
        OR (o.[Name] = N'OrderItemSummaryRelationship' AND [__mj].[IntegrationObjectField].[Name] = N'MainOrderSummaryId')
        OR (o.[Name] = N'OrderPaymentSummaryReference' AND [__mj].[IntegrationObjectField].[Name] = N'OrderSummaryId')
        OR (o.[Name] = N'OrderSummaryAdditionalInfo' AND [__mj].[IntegrationObjectField].[Name] = N'OrderSummaryId')
        OR (o.[Name] = N'OrderSummaryRelationship' AND [__mj].[IntegrationObjectField].[Name] IN (N'AssociatedOrderSummaryId', N'MainOrderSummaryId', N'RootOrderSummaryId'))
        OR (o.[Name] = N'OSAsyncChgCompletedEvent' AND [__mj].[IntegrationObjectField].[Name] = N'OrderSummaryId')
        OR (o.[Name] = N'PaymentInitiationSource' AND [__mj].[IntegrationObjectField].[Name] = N'OrderSummaryId')
        OR (o.[Name] = N'ProcessException' AND [__mj].[IntegrationObjectField].[Name] = N'OrderSummaryId')
      )
  );

-- Target: Organization.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Organization'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Organization'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Organization'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'Stamp' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
      )
  );

-- Target: OrgWideEmailAddress.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OrgWideEmailAddress'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'OrgWideEmailAddress'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'OrgWideEmailAddress'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'OrgEmailAddressSecurity' AND [__mj].[IntegrationObjectField].[Name] = N'OrgWideEmailAddressId')
      )
  );

-- Target: PackageLicense.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PackageLicense'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PackageLicense'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PackageLicense'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'UserPackageLicense' AND [__mj].[IntegrationObjectField].[Name] = N'PackageLicenseId')
      )
  );

-- Target: Payment.Id (5 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Payment'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Payment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Payment'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PaymentCredit' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentId')
        OR (o.[Name] = N'PaymentLineInvoice' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentId')
        OR (o.[Name] = N'PaymentScheduleItem' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentId')
        OR (o.[Name] = N'Refund' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentID')
        OR (o.[Name] = N'RefundLinePayment' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentId')
      )
  );

-- Target: PaymentAuthorization.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentAuthorization'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentAuthorization'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PaymentAuthorization'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'Payment' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentAuthorizationId')
        OR (o.[Name] = N'PaymentAuthAdjustment' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentAuthorizationId')
      )
  );

-- Target: PaymentCredit.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentCredit'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentCredit'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PaymentCredit'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PaymentCreditLinePayment' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentCreditId')
      )
  );

-- Target: PaymentGateway.Id (9 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentGateway'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentGateway'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PaymentGateway'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AlternativePaymentMethod' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentGatewayId')
        OR (o.[Name] = N'CardPaymentMethod' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentGatewayId')
        OR (o.[Name] = N'DigitalWallet' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentGatewayId')
        OR (o.[Name] = N'Payment' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentGatewayId')
        OR (o.[Name] = N'PaymentAuthorization' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentGatewayId')
        OR (o.[Name] = N'PaymentGatewayLog' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentGatewayId')
        OR (o.[Name] = N'PaymentIntent' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentGatewayId')
        OR (o.[Name] = N'Refund' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentGatewayId')
        OR (o.[Name] = N'SavedPaymentMethod' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentGatewayId')
      )
  );

-- Target: PaymentGatewayLog.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentGatewayLog'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentGatewayLog'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PaymentGatewayLog'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PaymentScheduleItem' AND [__mj].[IntegrationObjectField].[Name] = N'LastPaymentGatewayLogId')
      )
  );

-- Target: PaymentGatewayProvider.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentGatewayProvider'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentGatewayProvider'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PaymentGatewayProvider'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'GtwyProvPaymentMethodType' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentGatewayProviderId')
        OR (o.[Name] = N'PaymentGateway' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentGatewayProviderId')
      )
  );

-- Target: PaymentGroup.Id (5 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentGroup'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PaymentGroup'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'Payment' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentGroupId')
        OR (o.[Name] = N'PaymentAuthorization' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentGroupId')
        OR (o.[Name] = N'PaymentIntent' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentGroupId')
        OR (o.[Name] = N'Refund' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentGroupId')
        OR (o.[Name] = N'WebCart' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentGroupId')
      )
  );

-- Target: PaymentInitiationSource.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentInitiationSource'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentInitiationSource'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PaymentInitiationSource'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PaymentIntentEvent' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentInitiationSource')
      )
  );

-- Target: PaymentIntent.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentIntent'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentIntent'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PaymentIntent'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PaymentAuthAdjustment' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentIntentId')
        OR (o.[Name] = N'PaymentIntentEvent' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentIntent')
        OR (o.[Name] = N'Refund' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentIntentID')
      )
  );

-- Target: PaymentLink.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentLink'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentLink'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PaymentLink'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PaymentIntent' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentLinkId')
        OR (o.[Name] = N'PaymentIntentEvent' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentLink')
        OR (o.[Name] = N'PaymentLinkEvent' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentLinkId')
      )
  );

-- Target: PaymentMethod.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentMethod'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentMethod'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PaymentMethod'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'Payment' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentMethodId')
        OR (o.[Name] = N'PaymentAuthorization' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentMethodId')
        OR (o.[Name] = N'PaymentIntent' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentMethodId')
        OR (o.[Name] = N'Refund' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentMethodId')
      )
  );

-- Target: PaymentSchedule.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentSchedule'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentSchedule'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PaymentSchedule'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PaymentScheduleItem' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentScheduleId')
      )
  );

-- Target: PaymentScheduleItem.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentScheduleItem'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentScheduleItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PaymentScheduleItem'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PaymentLink' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentScheduleItemId')
      )
  );

GO

-- Target: PaymentSchedulePolicy.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentSchedulePolicy'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentSchedulePolicy'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PaymentSchedulePolicy'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PaymentScheduleTreatment' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentSchedulePolicyId')
      )
  );

-- Target: PaymentScheduleTreatment.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentScheduleTreatment'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentScheduleTreatment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PaymentScheduleTreatment'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PaymentScheduleTreatmentDtl' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentScheduleTreatmentId')
      )
  );

-- Target: PaymentScheduleTreatmentDtl.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentScheduleTreatmentDtl'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentScheduleTreatmentDtl'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PaymentScheduleTreatmentDtl'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PaymentSchedule' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentScheduleTreatmentDtlId')
      )
  );

-- Target: PaymentTerm.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentTerm'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PaymentTerm'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PaymentTerm'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'BillingScheduleGroup' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentTermId')
        OR (o.[Name] = N'Invoice' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentTermId')
        OR (o.[Name] = N'Order' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentTermId')
        OR (o.[Name] = N'PaymentTermItem' AND [__mj].[IntegrationObjectField].[Name] = N'PaymentTermId')
      )
  );

-- Target: PendingServiceRouting.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PendingServiceRouting'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PendingServiceRouting'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PendingServiceRouting'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AgentWork' AND [__mj].[IntegrationObjectField].[Name] = N'PendingServiceRoutingId')
        OR (o.[Name] = N'PendingServiceRoutingInteractionInfo' AND [__mj].[IntegrationObjectField].[Name] = N'PendingServiceRoutingId')
      )
  );

-- Target: Period.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Period'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Period'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Period'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ForecastingCustomData' AND [__mj].[IntegrationObjectField].[Name] = N'PeriodId')
        OR (o.[Name] = N'ForecastingSubmission' AND [__mj].[IntegrationObjectField].[Name] = N'PeriodId')
        OR (o.[Name] = N'FrcstCustmzAdjustment' AND [__mj].[IntegrationObjectField].[Name] = N'PeriodId')
        OR (o.[Name] = N'FrcstCustmzOwnerAdjustment' AND [__mj].[IntegrationObjectField].[Name] = N'PeriodId')
      )
  );

-- Target: PermissionSet.Id (7 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PermissionSet'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PermissionSet'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PermissionSet'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'FieldPermissions' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
        OR (o.[Name] = N'ObjectPermissions' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
        OR (o.[Name] = N'PermissionSetAssignment' AND [__mj].[IntegrationObjectField].[Name] = N'PermissionSetId')
        OR (o.[Name] = N'PermissionSetGroupComponent' AND [__mj].[IntegrationObjectField].[Name] = N'PermissionSetId')
        OR (o.[Name] = N'PermissionSetTabSetting' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
        OR (o.[Name] = N'SessionPermSetActivation' AND [__mj].[IntegrationObjectField].[Name] = N'PermissionSetId')
        OR (o.[Name] = N'SetupEntityAccess' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
      )
  );

-- Target: PermissionSetGroup.Id (5 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PermissionSetGroup'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PermissionSetGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PermissionSetGroup'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'NetworkSelfRegistration' AND [__mj].[IntegrationObjectField].[Name] = N'PermissionSetGroupId')
        OR (o.[Name] = N'PermissionSet' AND [__mj].[IntegrationObjectField].[Name] = N'PermissionSetGroupId')
        OR (o.[Name] = N'PermissionSetAssignment' AND [__mj].[IntegrationObjectField].[Name] = N'PermissionSetGroupId')
        OR (o.[Name] = N'PermissionSetGroupComponent' AND [__mj].[IntegrationObjectField].[Name] = N'PermissionSetGroupId')
        OR (o.[Name] = N'SessionPermSetActivation' AND [__mj].[IntegrationObjectField].[Name] = N'PermissionSetGroupId')
      )
  );

-- Target: PermissionSetLicense.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PermissionSetLicense'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PermissionSetLicense'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PermissionSetLicense'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ActivePermSetLicenseMetric' AND [__mj].[IntegrationObjectField].[Name] = N'PermissionSetLicenseId')
        OR (o.[Name] = N'PermissionSetLicenseAssign' AND [__mj].[IntegrationObjectField].[Name] = N'PermissionSetLicenseId')
      )
  );

-- Target: PersonalizationSchema.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PersonalizationSchema'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PersonalizationSchema'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PersonalizationSchema'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AbnExperiment' AND [__mj].[IntegrationObjectField].[Name] = N'PersonalizationSchemaId')
        OR (o.[Name] = N'PersonalizationPoint' AND [__mj].[IntegrationObjectField].[Name] = N'PersonalizationSchemaId')
      )
  );

-- Target: PickTicket.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PickTicket'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PickTicket'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PickTicket'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PickTicketAssignment' AND [__mj].[IntegrationObjectField].[Name] = N'PickTicketId')
        OR (o.[Name] = N'PickTicketProduct' AND [__mj].[IntegrationObjectField].[Name] = N'PickTicketId')
      )
  );

-- Target: PipelineInspectionListView.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PipelineInspectionListView'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PipelineInspectionListView'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PipelineInspectionListView'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PplnInspListViewCalcClmn' AND [__mj].[IntegrationObjectField].[Name] = N'PipelineInspectionListViewId')
      )
  );

-- Target: PipelineInspMetricConfig.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PipelineInspMetricConfig'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PipelineInspMetricConfig'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PipelineInspMetricConfig'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PipelineInspMetricConfigLocalization' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
      )
  );

-- Target: PriceAdjustmentGroupShape.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PriceAdjustmentGroupShape'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PriceAdjustmentGroupShape'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PriceAdjustmentGroupShape'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PriceAdjustmentItemShape' AND [__mj].[IntegrationObjectField].[Name] = N'PriceAdjustmentGroupShapeId')
      )
  );

-- Target: PriceAdjustmentTier.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PriceAdjustmentTier'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PriceAdjustmentTier'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PriceAdjustmentTier'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PriceAdjustmentGroupShape' AND [__mj].[IntegrationObjectField].[Name] = N'PriceAdjustmentCauseId')
        OR (o.[Name] = N'PriceAdjustmentItemShape' AND [__mj].[IntegrationObjectField].[Name] = N'PriceAdjustmentCauseId')
        OR (o.[Name] = N'QuoteLinePriceAdjustment' AND [__mj].[IntegrationObjectField].[Name] = N'PriceAdjustmentCauseId')
      )
  );

-- Target: Pricebook2.Id (7 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Pricebook2'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Pricebook2'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Pricebook2'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'Opportunity' AND [__mj].[IntegrationObjectField].[Name] = N'Pricebook2Id')
        OR (o.[Name] = N'Order' AND [__mj].[IntegrationObjectField].[Name] = N'Pricebook2Id')
        OR (o.[Name] = N'OrderSummary' AND [__mj].[IntegrationObjectField].[Name] = N'Pricebook2Id')
        OR (o.[Name] = N'Pricebook2History' AND [__mj].[IntegrationObjectField].[Name] = N'Pricebook2Id')
        OR (o.[Name] = N'PricebookEntry' AND [__mj].[IntegrationObjectField].[Name] = N'Pricebook2Id')
        OR (o.[Name] = N'WebStore' AND [__mj].[IntegrationObjectField].[Name] = N'SortByPriceBookId')
        OR (o.[Name] = N'WorkOrder' AND [__mj].[IntegrationObjectField].[Name] = N'Pricebook2Id')
      )
  );

-- Target: PricebookEntry.Id (5 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PricebookEntry'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PricebookEntry'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PricebookEntry'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CartItem' AND [__mj].[IntegrationObjectField].[Name] = N'PriceBookEntryId')
        OR (o.[Name] = N'OpportunityLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'PricebookEntryId')
        OR (o.[Name] = N'OrderItem' AND [__mj].[IntegrationObjectField].[Name] = N'PricebookEntryId')
        OR (o.[Name] = N'OrderItemSummary' AND [__mj].[IntegrationObjectField].[Name] = N'PricebookEntryId')
        OR (o.[Name] = N'WorkOrderLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'PricebookEntryId')
      )
  );

-- Target: PriceProtectionTerm.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PriceProtectionTerm'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PriceProtectionTerm'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PriceProtectionTerm'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PriceProtectExecLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'PriceProtectionTermId')
      )
  );

-- Target: PrivacyHoldReason.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PrivacyHoldReason'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PrivacyHoldReason'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PrivacyHoldReason'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PrivacyHold' AND [__mj].[IntegrationObjectField].[Name] = N'PrivacyHoldReasonId')
      )
  );

-- Target: PrivacyJobSession.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PrivacyJobSession'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PrivacyJobSession'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PrivacyJobSession'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PrivacyObjectSession' AND [__mj].[IntegrationObjectField].[Name] = N'PrivacyJobSessionObjectId')
      )
  );

-- Target: PrivacyObjectSession.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PrivacyObjectSession'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PrivacyObjectSession'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PrivacyObjectSession'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PrivacySessionRecordFailure' AND [__mj].[IntegrationObjectField].[Name] = N'PrivacyObjectSessionId')
      )
  );

-- Target: PrivacyRTBFRequest.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PrivacyRTBFRequest'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PrivacyRTBFRequest'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PrivacyRTBFRequest'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PrivacyJobSession' AND [__mj].[IntegrationObjectField].[Name] = N'PrivacyRtbfRequestId')
      )
  );

-- Target: Problem.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Problem'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Problem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Problem'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ProblemRelatedItem' AND [__mj].[IntegrationObjectField].[Name] = N'ProblemId')
      )
  );

-- Target: ProcessDefinition.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProcessDefinition'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProcessDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ProcessDefinition'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ProcessInstance' AND [__mj].[IntegrationObjectField].[Name] = N'ProcessDefinitionId')
        OR (o.[Name] = N'ProcessNode' AND [__mj].[IntegrationObjectField].[Name] = N'ProcessDefinitionId')
      )
  );

-- Target: ProcessInstance.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProcessInstance'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProcessInstance'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ProcessInstance'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ProcessInstanceHistory' AND [__mj].[IntegrationObjectField].[Name] = N'ProcessInstanceId')
        OR (o.[Name] = N'ProcessInstanceNode' AND [__mj].[IntegrationObjectField].[Name] = N'ProcessInstanceId')
        OR (o.[Name] = N'ProcessInstanceStep' AND [__mj].[IntegrationObjectField].[Name] = N'ProcessInstanceId')
        OR (o.[Name] = N'ProcessInstanceWorkitem' AND [__mj].[IntegrationObjectField].[Name] = N'ProcessInstanceId')
      )
  );

GO

-- Target: ProcessNode.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProcessNode'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProcessNode'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ProcessNode'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ProcessInstanceHistory' AND [__mj].[IntegrationObjectField].[Name] = N'ProcessNodeId')
        OR (o.[Name] = N'ProcessInstanceNode' AND [__mj].[IntegrationObjectField].[Name] = N'ProcessNodeId')
      )
  );

-- Target: Product2.Id (36 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Product2'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Product2'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Product2'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'Asset' AND [__mj].[IntegrationObjectField].[Name] = N'Product2Id')
        OR (o.[Name] = N'BillingScheduleGroup' AND [__mj].[IntegrationObjectField].[Name] = N'Product2Id')
        OR (o.[Name] = N'CartItem' AND [__mj].[IntegrationObjectField].[Name] = N'Product2Id')
        OR (o.[Name] = N'CommissionScheduleAssignment' AND [__mj].[IntegrationObjectField].[Name] = N'Product2Id')
        OR (o.[Name] = N'CreditMemoLine' AND [__mj].[IntegrationObjectField].[Name] = N'Product2Id')
        OR (o.[Name] = N'FulfillmentOrderLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'Product2Id')
        OR (o.[Name] = N'IncidentRelatedItem' AND [__mj].[IntegrationObjectField].[Name] = N'Product2Id')
        OR (o.[Name] = N'InventoryItemReservation' AND [__mj].[IntegrationObjectField].[Name] = N'ProductId')
        OR (o.[Name] = N'InvoiceLine' AND [__mj].[IntegrationObjectField].[Name] = N'Product2Id')
        OR (o.[Name] = N'OpportunityLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'ProductId')
        OR (o.[Name] = N'OrderItem' AND [__mj].[IntegrationObjectField].[Name] = N'Product2Id')
        OR (o.[Name] = N'OrderItemSummary' AND [__mj].[IntegrationObjectField].[Name] = N'Product2Id')
        OR (o.[Name] = N'PickTicketProduct' AND [__mj].[IntegrationObjectField].[Name] = N'Product2Id')
        OR (o.[Name] = N'PricebookEntry' AND [__mj].[IntegrationObjectField].[Name] = N'Product2Id')
        OR (o.[Name] = N'PriceProtectExecLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'ProductId')
        OR (o.[Name] = N'ProductComponentGroup' AND [__mj].[IntegrationObjectField].[Name] = N'ParentProductId')
        OR (o.[Name] = N'ProductDetectedPriceChange' AND [__mj].[IntegrationObjectField].[Name] = N'ProductId')
        OR (o.[Name] = N'ProductFeaturedProduct' AND [__mj].[IntegrationObjectField].[Name] IN (N'FeaturedProductId', N'ProductId'))
        OR (o.[Name] = N'ProductItem' AND [__mj].[IntegrationObjectField].[Name] = N'Product2Id')
        OR (o.[Name] = N'ProductMedia' AND [__mj].[IntegrationObjectField].[Name] = N'ProductId')
        OR (o.[Name] = N'ProductQuantityRule' AND [__mj].[IntegrationObjectField].[Name] = N'ProductId')
        OR (o.[Name] = N'ProductRelatedComponent' AND [__mj].[IntegrationObjectField].[Name] IN (N'ChildProductId', N'ParentProductId'))
        OR (o.[Name] = N'ProductRequestLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'Product2Id')
        OR (o.[Name] = N'ProductRequired' AND [__mj].[IntegrationObjectField].[Name] = N'Product2Id')
        OR (o.[Name] = N'ProductSellingModelOption' AND [__mj].[IntegrationObjectField].[Name] = N'Product2Id')
        OR (o.[Name] = N'ProductTransfer' AND [__mj].[IntegrationObjectField].[Name] = N'Product2Id')
        OR (o.[Name] = N'ProgramProduct' AND [__mj].[IntegrationObjectField].[Name] = N'ProductId')
        OR (o.[Name] = N'ReturnOrderLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'Product2Id')
        OR (o.[Name] = N'SalesTransactionItemShape' AND [__mj].[IntegrationObjectField].[Name] = N'ProductId')
        OR (o.[Name] = N'ShipmentItem' AND [__mj].[IntegrationObjectField].[Name] = N'Product2Id')
        OR (o.[Name] = N'ShippingConfigSetProduct' AND [__mj].[IntegrationObjectField].[Name] = N'Product2Id')
        OR (o.[Name] = N'UsageImpactGroupPgmMeasure' AND [__mj].[IntegrationObjectField].[Name] = N'Product2Id')
        OR (o.[Name] = N'WebStoreSearchProdSettings' AND [__mj].[IntegrationObjectField].[Name] = N'ProductId')
        OR (o.[Name] = N'WorkOrderLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'Product2Id')
      )
  );

-- Target: ProductCategory.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProductCategory'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProductCategory'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ProductCategory'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CryptoProdCatgWalletGroup' AND [__mj].[IntegrationObjectField].[Name] = N'ProductCategoryId')
      )
  );

-- Target: ProductComponentGroup.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProductComponentGroup'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProductComponentGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ProductComponentGroup'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ProductRelatedComponent' AND [__mj].[IntegrationObjectField].[Name] = N'ProductComponentGroupId')
      )
  );

-- Target: ProductItem.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProductItem'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProductItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ProductItem'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ProductItemTransaction' AND [__mj].[IntegrationObjectField].[Name] = N'ProductItemId')
        OR (o.[Name] = N'ProductTransfer' AND [__mj].[IntegrationObjectField].[Name] = N'SourceProductItemId')
        OR (o.[Name] = N'ReturnOrderLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'ProductItemId')
      )
  );

-- Target: ProductRelatedComponent.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProductRelatedComponent'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProductRelatedComponent'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ProductRelatedComponent'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AssetRelationship' AND [__mj].[IntegrationObjectField].[Name] = N'ProductRelatedComponent')
        OR (o.[Name] = N'CartItem' AND [__mj].[IntegrationObjectField].[Name] = N'ComponentId')
        OR (o.[Name] = N'OrderItemSummaryRelationship' AND [__mj].[IntegrationObjectField].[Name] = N'ProductRelatedComponentId')
        OR (o.[Name] = N'QuoteLineRelationship' AND [__mj].[IntegrationObjectField].[Name] = N'ProductRelatedComponentId')
      )
  );

-- Target: ProductRelationshipType.Id (6 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProductRelationshipType'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProductRelationshipType'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ProductRelationshipType'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AssetRelationship' AND [__mj].[IntegrationObjectField].[Name] = N'ProductRelationshipTypeId')
        OR (o.[Name] = N'OrderItemRelationship' AND [__mj].[IntegrationObjectField].[Name] = N'ProductRelationshipTypeId')
        OR (o.[Name] = N'OrderItemSummaryRelationship' AND [__mj].[IntegrationObjectField].[Name] = N'ProductRelationshipTypeId')
        OR (o.[Name] = N'ProductRelatedComponent' AND [__mj].[IntegrationObjectField].[Name] = N'ProductRelationshipTypeId')
        OR (o.[Name] = N'QuoteLineRelationship' AND [__mj].[IntegrationObjectField].[Name] = N'ProductRelationshipTypeId')
        OR (o.[Name] = N'SalesTrxnItemRelationShape' AND [__mj].[IntegrationObjectField].[Name] = N'ProductRelationshipTypeId')
      )
  );

-- Target: ProductRequest.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProductRequest'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProductRequest'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ProductRequest'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ProductRequestLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
        OR (o.[Name] = N'ProductTransfer' AND [__mj].[IntegrationObjectField].[Name] = N'ProductRequestId')
        OR (o.[Name] = N'ReturnOrder' AND [__mj].[IntegrationObjectField].[Name] = N'ProductRequestId')
      )
  );

-- Target: ProductRequestLineItem.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProductRequestLineItem'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProductRequestLineItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ProductRequestLineItem'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ProductTransfer' AND [__mj].[IntegrationObjectField].[Name] = N'ProductRequestLineItemId')
        OR (o.[Name] = N'ReturnOrderLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'ProductRequestLineItemId')
      )
  );

-- Target: ProductSellingModel.Id (8 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProductSellingModel'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProductSellingModel'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ProductSellingModel'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CartItem' AND [__mj].[IntegrationObjectField].[Name] = N'ProductSellingModelId')
        OR (o.[Name] = N'OrderItem' AND [__mj].[IntegrationObjectField].[Name] = N'ProductSellingModelId')
        OR (o.[Name] = N'PricebookEntry' AND [__mj].[IntegrationObjectField].[Name] = N'ProductSellingModelId')
        OR (o.[Name] = N'ProductRelatedComponent' AND [__mj].[IntegrationObjectField].[Name] IN (N'ChildSellingModelId', N'ParentSellingModelId'))
        OR (o.[Name] = N'ProductSellingModelOption' AND [__mj].[IntegrationObjectField].[Name] = N'ProductSellingModelId')
        OR (o.[Name] = N'QuoteLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'ProductSellingModelId')
        OR (o.[Name] = N'SalesTransactionItemShape' AND [__mj].[IntegrationObjectField].[Name] = N'ProductSellingModelId')
      )
  );

-- Target: Profile.Id (9 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Profile'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Profile'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Profile'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ActiveProfileMetric' AND [__mj].[IntegrationObjectField].[Name] = N'ProfileId')
        OR (o.[Name] = N'MobileSecurityAssignment' AND [__mj].[IntegrationObjectField].[Name] = N'ProfileId')
        OR (o.[Name] = N'Name' AND [__mj].[IntegrationObjectField].[Name] = N'ProfileId')
        OR (o.[Name] = N'NetworkAuthApiSettings' AND [__mj].[IntegrationObjectField].[Name] = N'RegistrationUserDefaultProfileId')
        OR (o.[Name] = N'OmniSupervisorConfigProfile' AND [__mj].[IntegrationObjectField].[Name] = N'ProfileId')
        OR (o.[Name] = N'OrgEmailAddressSecurity' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
        OR (o.[Name] = N'RecentlyViewed' AND [__mj].[IntegrationObjectField].[Name] = N'ProfileId')
        OR (o.[Name] = N'User' AND [__mj].[IntegrationObjectField].[Name] = N'ProfileId')
        OR (o.[Name] = N'VisualforceAccessMetrics' AND [__mj].[IntegrationObjectField].[Name] = N'ProfileId')
      )
  );

-- Target: ProfileSkill.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProfileSkill'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProfileSkill'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ProfileSkill'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ProfileSkillShare' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
        OR (o.[Name] = N'ProfileSkillUser' AND [__mj].[IntegrationObjectField].[Name] = N'ProfileSkillId')
      )
  );

-- Target: ProfileSkillUser.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProfileSkillUser'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProfileSkillUser'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ProfileSkillUser'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ProfileSkillEndorsement' AND [__mj].[IntegrationObjectField].[Name] = N'ProfileSkillUserId')
      )
  );

-- Target: ProgramRebateType.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProgramRebateType'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProgramRebateType'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ProgramRebateType'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PriceProtectExecLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'CalculationReferenceRecordId')
        OR (o.[Name] = N'PriceProtectionTerm' AND [__mj].[IntegrationObjectField].[Name] = N'CalculationReferenceRecordId')
      )
  );

-- Target: Promotion.Id (11 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Promotion'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Promotion'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Promotion'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CartDeliveryGroupMethodAdj' AND [__mj].[IntegrationObjectField].[Name] = N'PriceAdjustmentCauseId')
        OR (o.[Name] = N'CartItemPriceAdjustment' AND [__mj].[IntegrationObjectField].[Name] = N'PriceAdjustmentCauseId')
        OR (o.[Name] = N'Coupon' AND [__mj].[IntegrationObjectField].[Name] = N'PromotionId')
        OR (o.[Name] = N'OrderAdjustmentGroupSummary' AND [__mj].[IntegrationObjectField].[Name] = N'AdjustmentCauseId')
        OR (o.[Name] = N'OrderItemAdjustmentLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'AdjustmentCauseId')
        OR (o.[Name] = N'OrderItemAdjustmentLineSummary' AND [__mj].[IntegrationObjectField].[Name] = N'AdjustmentCauseId')
        OR (o.[Name] = N'PromotionMarketSegment' AND [__mj].[IntegrationObjectField].[Name] = N'PromotionId')
        OR (o.[Name] = N'PromotionQualifier' AND [__mj].[IntegrationObjectField].[Name] = N'PromotionId')
        OR (o.[Name] = N'PromotionTarget' AND [__mj].[IntegrationObjectField].[Name] = N'PromotionId')
        OR (o.[Name] = N'PromotionTier' AND [__mj].[IntegrationObjectField].[Name] = N'PromotionId')
        OR (o.[Name] = N'WebCartAdjustmentGroup' AND [__mj].[IntegrationObjectField].[Name] = N'PriceAdjustmentCauseId')
      )
  );

-- Target: PromotionSegment.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PromotionSegment'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PromotionSegment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PromotionSegment'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PromotionMarketSegment' AND [__mj].[IntegrationObjectField].[Name] = N'PromotionSegmentId')
        OR (o.[Name] = N'PromotionSegmentBuyerGroup' AND [__mj].[IntegrationObjectField].[Name] = N'PromotionSegmentId')
        OR (o.[Name] = N'PromotionSegmentSalesStore' AND [__mj].[IntegrationObjectField].[Name] = N'PromotionSegmentId')
      )
  );

-- Target: PromotionTier.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PromotionTier'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PromotionTier'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PromotionTier'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PromotionQualifier' AND [__mj].[IntegrationObjectField].[Name] = N'PromotionTierId')
        OR (o.[Name] = N'PromotionTarget' AND [__mj].[IntegrationObjectField].[Name] = N'PromotionTierId')
      )
  );

-- Target: Prompt.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Prompt'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Prompt'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Prompt'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PromptVersion' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
      )
  );

-- Target: PromptVersion.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PromptVersion'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PromptVersion'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PromptVersion'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PromptAction' AND [__mj].[IntegrationObjectField].[Name] = N'PromptVersionId')
        OR (o.[Name] = N'UiFormulaRule' AND [__mj].[IntegrationObjectField].[Name] = N'AssociatedElementId')
      )
  );

-- Target: ProrationPolicy.Id (5 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProrationPolicy'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ProrationPolicy'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ProrationPolicy'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'BillingScheduleGroup' AND [__mj].[IntegrationObjectField].[Name] = N'ProrationPolicyId')
        OR (o.[Name] = N'OrderItem' AND [__mj].[IntegrationObjectField].[Name] = N'ProrationPolicyId')
        OR (o.[Name] = N'ProductSellingModelOption' AND [__mj].[IntegrationObjectField].[Name] = N'ProrationPolicyId')
        OR (o.[Name] = N'QuoteLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'ProrationPolicyId')
        OR (o.[Name] = N'SalesTransactionItemShape' AND [__mj].[IntegrationObjectField].[Name] = N'ProrationPolicyId')
      )
  );

-- Target: PurchaseQuantityRule.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PurchaseQuantityRule'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PurchaseQuantityRule'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PurchaseQuantityRule'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ProductQuantityRule' AND [__mj].[IntegrationObjectField].[Name] = N'PurchaseQuantityRuleId')
      )
  );

-- Target: PymtSchdDistributionMethod.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PymtSchdDistributionMethod'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PymtSchdDistributionMethod'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PymtSchdDistributionMethod'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PaymentScheduleTreatmentDtl' AND [__mj].[IntegrationObjectField].[Name] = N'PymtSchdDistributionMethodId')
      )
  );

-- Target: QueueRoutingConfig.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'QueueRoutingConfig'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'QueueRoutingConfig'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'QueueRoutingConfig'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'LiveChatButton' AND [__mj].[IntegrationObjectField].[Name] = N'RoutingConfigurationId')
        OR (o.[Name] = N'ServiceChannel' AND [__mj].[IntegrationObjectField].[Name] = N'RoutingConfigurationId')
      )
  );

-- Target: QuickText.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'QuickText'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'QuickText'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'QuickText'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'QuickTextUsage' AND [__mj].[IntegrationObjectField].[Name] = N'QuickTextID')
      )
  );

-- Target: Quote.Id (5 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Quote'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Quote'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Quote'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'Contract' AND [__mj].[IntegrationObjectField].[Name] = N'SourceQuoteId')
        OR (o.[Name] = N'PaymentInitiationSource' AND [__mj].[IntegrationObjectField].[Name] = N'QuoteId')
        OR (o.[Name] = N'QuoteAction' AND [__mj].[IntegrationObjectField].[Name] = N'QuoteId')
        OR (o.[Name] = N'QuoteAdjustmentGroup' AND [__mj].[IntegrationObjectField].[Name] = N'QuoteId')
        OR (o.[Name] = N'QuoteLineRelationship' AND [__mj].[IntegrationObjectField].[Name] = N'QuoteId')
      )
  );

GO

-- Target: QuoteAction.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'QuoteAction'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'QuoteAction'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'QuoteAction'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'QuoteLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'QuoteActionId')
      )
  );

-- Target: QuoteDocument.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'QuoteDocument'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'QuoteDocument'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'QuoteDocument'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'DocumentRecipient' AND [__mj].[IntegrationObjectField].[Name] = N'QuoteDocumentId')
      )
  );

-- Target: QuoteLineGroup.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'QuoteLineGroup'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'QuoteLineGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'QuoteLineGroup'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'QuoteLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'QuoteLineGroupId')
      )
  );

-- Target: QuoteLineItem.Id (6 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'QuoteLineItem'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'QuoteLineItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'QuoteLineItem'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'QuoteItemTaxItem' AND [__mj].[IntegrationObjectField].[Name] = N'QuoteLineItemId')
        OR (o.[Name] = N'QuoteLinePriceAdjustment' AND [__mj].[IntegrationObjectField].[Name] = N'QuoteLineItemId')
        OR (o.[Name] = N'QuoteLineRelationship' AND [__mj].[IntegrationObjectField].[Name] IN (N'AssociatedQuoteLineId', N'MainQuoteLineId', N'RootQuoteLineId'))
        OR (o.[Name] = N'QuoteLineWorkSource' AND [__mj].[IntegrationObjectField].[Name] = N'QuoteLineItemId')
      )
  );

-- Target: QuoteLineItemRecipient.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'QuoteLineItemRecipient'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'QuoteLineItemRecipient'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'QuoteLineItemRecipient'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'QuoteLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'QuoteLineItemRecipientId')
        OR (o.[Name] = N'QuoteRecipientGroupMember' AND [__mj].[IntegrationObjectField].[Name] = N'QuoteLineItemRecipientId')
      )
  );

-- Target: QuoteRecipientGroup.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'QuoteRecipientGroup'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'QuoteRecipientGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'QuoteRecipientGroup'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'QuoteRecipientGroupMember' AND [__mj].[IntegrationObjectField].[Name] = N'QuoteRecipientGroupId')
      )
  );

-- Target: RecordsetFilterCriteria.Id (8 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'RecordsetFilterCriteria'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'RecordsetFilterCriteria'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'RecordsetFilterCriteria'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ApptBundleAggrPolicy' AND [__mj].[IntegrationObjectField].[Name] = N'FilterCriteriaId')
        OR (o.[Name] = N'ApptBundleConfig' AND [__mj].[IntegrationObjectField].[Name] = N'CriteriaForAutoUnbundlingId')
        OR (o.[Name] = N'ApptBundlePolicy' AND [__mj].[IntegrationObjectField].[Name] = N'FilterCriteriaId')
        OR (o.[Name] = N'ContractLineOutcome' AND [__mj].[IntegrationObjectField].[Name] = N'RecordsetFilterCriteriaId')
        OR (o.[Name] = N'RecordsetFltrCritMonitor' AND [__mj].[IntegrationObjectField].[Name] = N'RecordsetFilterCriteriaId')
        OR (o.[Name] = N'Shift' AND [__mj].[IntegrationObjectField].[Name] = N'RecordsetFilterCriteriaId')
        OR (o.[Name] = N'ShiftTemplate' AND [__mj].[IntegrationObjectField].[Name] = N'RecordsetFilterCriteriaId')
        OR (o.[Name] = N'TimeSlot' AND [__mj].[IntegrationObjectField].[Name] = N'RecordSetFilterCriteriaId')
      )
  );

-- Target: RecordType.Id (8 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'RecordType'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'RecordType'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'RecordType'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'Asset' AND [__mj].[IntegrationObjectField].[Name] = N'RecordTypeId')
        OR (o.[Name] = N'BuyerGroup' AND [__mj].[IntegrationObjectField].[Name] = N'RecordTypeId')
        OR (o.[Name] = N'Campaign' AND [__mj].[IntegrationObjectField].[Name] = N'CampaignMemberRecordTypeId')
        OR (o.[Name] = N'GtwyProvPaymentMethodType' AND [__mj].[IntegrationObjectField].[Name] = N'RecordTypeId')
        OR (o.[Name] = N'Idea' AND [__mj].[IntegrationObjectField].[Name] = N'RecordTypeId')
        OR (o.[Name] = N'MessagingLink' AND [__mj].[IntegrationObjectField].[Name] = N'RecordTypeId')
        OR (o.[Name] = N'PromptVersion' AND [__mj].[IntegrationObjectField].[Name] = N'TargetRecordType')
        OR (o.[Name] = N'VoiceCall' AND [__mj].[IntegrationObjectField].[Name] = N'RecordTypeId')
      )
  );

-- Target: Refund.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Refund'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Refund'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Refund'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'RefundLinePayment' AND [__mj].[IntegrationObjectField].[Name] = N'RefundId')
      )
  );

-- Target: Report.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Report'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Report'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Report'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ScorecardMetric' AND [__mj].[IntegrationObjectField].[Name] = N'ReportId')
      )
  );

-- Target: ReturnOrder.Id (5 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ReturnOrder'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ReturnOrder'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ReturnOrder'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PaymentCredit' AND [__mj].[IntegrationObjectField].[Name] = N'ReturnOrderId')
        OR (o.[Name] = N'ProductTransfer' AND [__mj].[IntegrationObjectField].[Name] = N'ReturnOrderId')
        OR (o.[Name] = N'ReturnOrderItemAdjustment' AND [__mj].[IntegrationObjectField].[Name] = N'ReturnOrderId')
        OR (o.[Name] = N'ReturnOrderItemTax' AND [__mj].[IntegrationObjectField].[Name] = N'ReturnOrderId')
        OR (o.[Name] = N'ReturnOrderLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'ReturnOrderId')
      )
  );

-- Target: ReturnOrderItemAdjustment.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ReturnOrderItemAdjustment'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ReturnOrderItemAdjustment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ReturnOrderItemAdjustment'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ReturnOrderItemTax' AND [__mj].[IntegrationObjectField].[Name] = N'ReturnOrderItemAdjustmentId')
      )
  );

-- Target: ReturnOrderLineItem.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ReturnOrderLineItem'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ReturnOrderLineItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ReturnOrderLineItem'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ProductTransfer' AND [__mj].[IntegrationObjectField].[Name] = N'ReturnOrderLineItemId')
        OR (o.[Name] = N'ReturnOrderItemAdjustment' AND [__mj].[IntegrationObjectField].[Name] = N'ReturnOrderLineItemId')
        OR (o.[Name] = N'ReturnOrderItemTax' AND [__mj].[IntegrationObjectField].[Name] = N'ReturnOrderLineItemId')
      )
  );

-- Target: RevenueAsyncOperation.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'RevenueAsyncOperation'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'RevenueAsyncOperation'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'RevenueAsyncOperation'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'RevenueTransactionErrorLog' AND [__mj].[IntegrationObjectField].[Name] = N'RevenueAsyncOperationId')
      )
  );

-- Target: SalesChannel.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SalesChannel'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SalesChannel'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SalesChannel'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'OrderSummary' AND [__mj].[IntegrationObjectField].[Name] = N'SalesChannelId')
        OR (o.[Name] = N'PendingOrderSummary' AND [__mj].[IntegrationObjectField].[Name] = N'SalesChannelId')
      )
  );

-- Target: SalesforceContract.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SalesforceContract'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SalesforceContract'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SalesforceContract'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'SalesforceInvoice' AND [__mj].[IntegrationObjectField].[Name] = N'SalesforceContractId')
        OR (o.[Name] = N'SalesforceQuote' AND [__mj].[IntegrationObjectField].[Name] = N'SalesforceContractId')
      )
  );

-- Target: SalesTransactionItemShape.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SalesTransactionItemShape'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SalesTransactionItemShape'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SalesTransactionItemShape'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PriceAdjustmentItemShape' AND [__mj].[IntegrationObjectField].[Name] = N'SalesTransactionItemShapeId')
        OR (o.[Name] = N'SalesTrxnItemRelationShape' AND [__mj].[IntegrationObjectField].[Name] IN (N'AssocSalesTrxnItemShapeId', N'MainSalesTrxnItemShapeId'))
      )
  );

-- Target: SalesTransactionShape.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SalesTransactionShape'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SalesTransactionShape'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SalesTransactionShape'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PriceAdjustmentGroupShape' AND [__mj].[IntegrationObjectField].[Name] = N'SalesTransactionShapeId')
        OR (o.[Name] = N'SalesTransactionItemShape' AND [__mj].[IntegrationObjectField].[Name] = N'SalesTransactionShapeId')
        OR (o.[Name] = N'SalesTrxnItemRelationShape' AND [__mj].[IntegrationObjectField].[Name] = N'SalesTransactionShapeId')
      )
  );

-- Target: SavedPaymentMethod.Id (5 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SavedPaymentMethod'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SavedPaymentMethod'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SavedPaymentMethod'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AlternativePaymentMethod' AND [__mj].[IntegrationObjectField].[Name] = N'SavedPaymentMethodId')
        OR (o.[Name] = N'CardPaymentMethod' AND [__mj].[IntegrationObjectField].[Name] = N'SavedPaymentMethodId')
        OR (o.[Name] = N'DigitalWallet' AND [__mj].[IntegrationObjectField].[Name] = N'SavedPaymentMethodId')
        OR (o.[Name] = N'PaymentMethod' AND [__mj].[IntegrationObjectField].[Name] = N'SavedPaymentMethodId')
        OR (o.[Name] = N'SavedPaymentMethodEvent' AND [__mj].[IntegrationObjectField].[Name] = N'SavedPaymentMethodId')
      )
  );

-- Target: SchedulingAdherenceSummary.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SchedulingAdherenceSummary'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SchedulingAdherenceSummary'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SchedulingAdherenceSummary'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'SchedulingAdherenceDetail' AND [__mj].[IntegrationObjectField].[Name] = N'SchedulingAdherenceSummaryId')
      )
  );

-- Target: SchedulingRule.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SchedulingRule'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SchedulingRule'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SchedulingRule'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'SchedulingRuleParameter' AND [__mj].[IntegrationObjectField].[Name] = N'SchedulingRuleId')
      )
  );

-- Target: Scorecard.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Scorecard'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Scorecard'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Scorecard'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ScorecardAssociation' AND [__mj].[IntegrationObjectField].[Name] = N'ScorecardId')
        OR (o.[Name] = N'ScorecardMetric' AND [__mj].[IntegrationObjectField].[Name] = N'ScorecardId')
      )
  );

-- Target: ServiceAppointment.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ServiceAppointment'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ServiceAppointment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ServiceAppointment'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AssignedResource' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceAppointmentId')
        OR (o.[Name] = N'FldSvcObjChg' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceAppointmentId')
        OR (o.[Name] = N'GeolocationBasedAction' AND [__mj].[IntegrationObjectField].[Name] = N'ReferenceRecordId')
      )
  );

-- Target: ServiceChannel.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ServiceChannel'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ServiceChannel'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ServiceChannel'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AgentWork' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceChannelId')
        OR (o.[Name] = N'WorkDemographic' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceChannelId')
      )
  );

-- Target: ServiceContract.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ServiceContract'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ServiceContract'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ServiceContract'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ContractLineOutcome' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceContractId')
      )
  );

GO

-- Target: ServicePresenceStatus.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ServicePresenceStatus'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ServicePresenceStatus'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ServicePresenceStatus'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'SchedulingAdherenceDetail' AND [__mj].[IntegrationObjectField].[Name] = N'StatusId')
        OR (o.[Name] = N'ShiftSegmentType' AND [__mj].[IntegrationObjectField].[Name] = N'ServicePresenceStatusId')
        OR (o.[Name] = N'VendorCallCenterStatusMap' AND [__mj].[IntegrationObjectField].[Name] = N'ServicePresenceStatusId')
      )
  );

-- Target: ServiceResource.Id (11 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ServiceResource'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ServiceResource'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ServiceResource'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AppointmentScheduleAggr' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceResourceId')
        OR (o.[Name] = N'AppointmentScheduleLog' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceResourceId')
        OR (o.[Name] = N'AssignedResource' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceResourceId')
        OR (o.[Name] = N'ResourceAbsence' AND [__mj].[IntegrationObjectField].[Name] = N'ResourceId')
        OR (o.[Name] = N'ResourcePreference' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceResourceId')
        OR (o.[Name] = N'SchedulingAdherenceSummary' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceResourceId')
        OR (o.[Name] = N'ServiceResourcePreference' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceResourceId')
        OR (o.[Name] = N'ServiceResourceSkill' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceResourceId')
        OR (o.[Name] = N'ServiceTerritoryMember' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceResourceId')
        OR (o.[Name] = N'Shift' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceResourceId')
        OR (o.[Name] = N'SkillLevelProgress' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceResourceId')
      )
  );

-- Target: ServiceTerritory.Id (12 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ServiceTerritory'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ServiceTerritory'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ServiceTerritory'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ApptBundlePolicySvcTerr' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceTerritoryId')
        OR (o.[Name] = N'SchedulingAdherenceSummary' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceTerritoryId')
        OR (o.[Name] = N'ServiceAppointment' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceTerritoryId')
        OR (o.[Name] = N'ServiceTerritoryMember' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceTerritoryId')
        OR (o.[Name] = N'ServiceTerritoryWorkType' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceTerritoryId')
        OR (o.[Name] = N'Shift' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceTerritoryId')
        OR (o.[Name] = N'WorkCapacityAvailability' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceTerritoryId')
        OR (o.[Name] = N'WorkCapacityLimit' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceTerritoryId')
        OR (o.[Name] = N'WorkCapacityUsage' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceTerritoryId')
        OR (o.[Name] = N'WorkDemographic' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceTerritoryId')
        OR (o.[Name] = N'WorkOrder' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceTerritoryId')
        OR (o.[Name] = N'WorkOrderLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'ServiceTerritoryId')
      )
  );

-- Target: SfdcCustomerForPartner.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SfdcCustomerForPartner'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SfdcCustomerForPartner'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SfdcCustomerForPartner'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'SfdcPartnerOffer' AND [__mj].[IntegrationObjectField].[Name] = N'CustomerId')
        OR (o.[Name] = N'SfdcPartnerOrder' AND [__mj].[IntegrationObjectField].[Name] = N'SfdcCustomerForPartnerId')
        OR (o.[Name] = N'SfdcPartnerTenant' AND [__mj].[IntegrationObjectField].[Name] = N'CustomerId')
      )
  );

-- Target: SfdcPartnerOffer.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SfdcPartnerOffer'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SfdcPartnerOffer'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SfdcPartnerOffer'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'SfdcPartnerOfferItem' AND [__mj].[IntegrationObjectField].[Name] = N'PartnerOfferId')
        OR (o.[Name] = N'SfdcPartnerOrder' AND [__mj].[IntegrationObjectField].[Name] = N'OriginatingOfferId')
      )
  );

-- Target: SfdcPartnerPackage.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SfdcPartnerPackage'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SfdcPartnerPackage'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SfdcPartnerPackage'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'SfdcPartnerTenantPackage' AND [__mj].[IntegrationObjectField].[Name] = N'PartnerPackageId')
      )
  );

-- Target: SfdcPartnerPackageVersion.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SfdcPartnerPackageVersion'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SfdcPartnerPackageVersion'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SfdcPartnerPackageVersion'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'SfdcPartnerTenantPackage' AND [__mj].[IntegrationObjectField].[Name] = N'PartnerPackageVersion')
      )
  );

-- Target: SfdcPartnerProvisionProduct.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SfdcPartnerProvisionProduct'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SfdcPartnerProvisionProduct'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SfdcPartnerProvisionProduct'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'SfdcPartnerOfferItem' AND [__mj].[IntegrationObjectField].[Name] = N'PartnerProvisionProductId')
        OR (o.[Name] = N'SfdcPartnerOrderItem' AND [__mj].[IntegrationObjectField].[Name] = N'PartnerProvisionProductId')
        OR (o.[Name] = N'SfdcPartnerProductLicense' AND [__mj].[IntegrationObjectField].[Name] = N'PartnerProvisionProductId')
      )
  );

-- Target: SfdcPartnerTenant.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SfdcPartnerTenant'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SfdcPartnerTenant'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SfdcPartnerTenant'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'SfdcPartnerOrderItem' AND [__mj].[IntegrationObjectField].[Name] = N'PartnerTenantId')
        OR (o.[Name] = N'SfdcPartnerTenantPackage' AND [__mj].[IntegrationObjectField].[Name] = N'PartnerTenantId')
      )
  );

-- Target: SfdcPartnerTenantPackage.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SfdcPartnerTenantPackage'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SfdcPartnerTenantPackage'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SfdcPartnerTenantPackage'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'SfdcPartnerTntPermSetLic' AND [__mj].[IntegrationObjectField].[Name] = N'PartnerTenantPackageId')
        OR (o.[Name] = N'SfdcPartnerTntPkgLicense' AND [__mj].[IntegrationObjectField].[Name] = N'PartnerTenantPackageId')
      )
  );

-- Target: SfdcPartnerTermSet.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SfdcPartnerTermSet'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SfdcPartnerTermSet'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SfdcPartnerTermSet'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'SfdcPartnerOffer' AND [__mj].[IntegrationObjectField].[Name] = N'PartnerTermSetId')
        OR (o.[Name] = N'SfdcPartnerOrder' AND [__mj].[IntegrationObjectField].[Name] = N'SfdcPartnerTermSetId')
        OR (o.[Name] = N'SfdcPartnerTermSetProduct' AND [__mj].[IntegrationObjectField].[Name] = N'PartnerTermSetId')
      )
  );

-- Target: SfdcPartnerTermSetProduct.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SfdcPartnerTermSetProduct'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SfdcPartnerTermSetProduct'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SfdcPartnerTermSetProduct'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'SfdcPartnerProvisionProduct' AND [__mj].[IntegrationObjectField].[Name] = N'PartnerTermSetProductId')
      )
  );

-- Target: Shift.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Shift'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Shift'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Shift'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ShiftHistory' AND [__mj].[IntegrationObjectField].[Name] = N'ShiftId')
        OR (o.[Name] = N'ShiftSegment' AND [__mj].[IntegrationObjectField].[Name] = N'ShiftId')
        OR (o.[Name] = N'ShiftShare' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
      )
  );

-- Target: ShiftPattern.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ShiftPattern'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ShiftPattern'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ShiftPattern'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ShiftPatternEntry' AND [__mj].[IntegrationObjectField].[Name] = N'ShiftPatternId')
      )
  );

-- Target: ShiftSegmentType.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ShiftSegmentType'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ShiftSegmentType'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ShiftSegmentType'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ShiftSegment' AND [__mj].[IntegrationObjectField].[Name] = N'SegmentTypeId')
      )
  );

-- Target: ShiftTemplate.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ShiftTemplate'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ShiftTemplate'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ShiftTemplate'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'Shift' AND [__mj].[IntegrationObjectField].[Name] = N'ShiftTemplateId')
        OR (o.[Name] = N'ShiftPatternEntry' AND [__mj].[IntegrationObjectField].[Name] = N'ShiftTemplateId')
        OR (o.[Name] = N'WorkforceCapacityUnit' AND [__mj].[IntegrationObjectField].[Name] = N'ShiftTemplateId')
      )
  );

-- Target: Shipment.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Shipment'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Shipment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Shipment'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ProductTransfer' AND [__mj].[IntegrationObjectField].[Name] = N'ShipmentId')
        OR (o.[Name] = N'ShipmentItem' AND [__mj].[IntegrationObjectField].[Name] = N'ShipmentId')
      )
  );

-- Target: ShippingCarrier.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ShippingCarrier'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ShippingCarrier'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ShippingCarrier'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ShippingCarrierMethod' AND [__mj].[IntegrationObjectField].[Name] = N'ShippingCarrierId')
      )
  );

-- Target: ShippingCarrierMethod.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ShippingCarrierMethod'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ShippingCarrierMethod'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ShippingCarrierMethod'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'StandardShippingRate' AND [__mj].[IntegrationObjectField].[Name] = N'ShippingCarrierMethodId')
      )
  );

-- Target: ShippingConfigurationSet.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ShippingConfigurationSet'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ShippingConfigurationSet'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ShippingConfigurationSet'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ShippingRateGroup' AND [__mj].[IntegrationObjectField].[Name] = N'ShippingProfileId')
      )
  );

-- Target: ShippingRateGroup.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ShippingRateGroup'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ShippingRateGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ShippingRateGroup'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ShippingRateArea' AND [__mj].[IntegrationObjectField].[Name] = N'ShippingRateGroupId')
      )
  );

-- Target: Site.Id (7 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Site'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Site'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Site'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'DomainSite' AND [__mj].[IntegrationObjectField].[Name] = N'SiteId')
        OR (o.[Name] = N'LiveChatButton' AND [__mj].[IntegrationObjectField].[Name] = N'SiteId')
        OR (o.[Name] = N'PaymentInitiationSource' AND [__mj].[IntegrationObjectField].[Name] = N'SiteId')
        OR (o.[Name] = N'PromptVersion' AND [__mj].[IntegrationObjectField].[Name] = N'ExperienceContextId')
        OR (o.[Name] = N'SiteHistory' AND [__mj].[IntegrationObjectField].[Name] = N'SiteId')
        OR (o.[Name] = N'SiteIframeWhitelistUrl' AND [__mj].[IntegrationObjectField].[Name] = N'SiteId')
        OR (o.[Name] = N'SiteRedirectMapping' AND [__mj].[IntegrationObjectField].[Name] = N'SiteId')
      )
  );

-- Target: Skill.Id (6 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Skill'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Skill'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Skill'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'LiveChatButton' AND [__mj].[IntegrationObjectField].[Name] = N'SkillId')
        OR (o.[Name] = N'MessagingChannelSkill' AND [__mj].[IntegrationObjectField].[Name] = N'SkillId')
        OR (o.[Name] = N'OmniSupervisorConfigSkill' AND [__mj].[IntegrationObjectField].[Name] = N'SkillId')
        OR (o.[Name] = N'ServiceResourceSkill' AND [__mj].[IntegrationObjectField].[Name] = N'SkillId')
        OR (o.[Name] = N'SkillLevelDefinition' AND [__mj].[IntegrationObjectField].[Name] = N'SkillId')
        OR (o.[Name] = N'SkillRequirement' AND [__mj].[IntegrationObjectField].[Name] = N'SkillId')
      )
  );

-- Target: SkillLevelDefinition.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SkillLevelDefinition'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SkillLevelDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SkillLevelDefinition'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'SkillLevelProgress' AND [__mj].[IntegrationObjectField].[Name] = N'SkillLevelDefinitionId')
      )
  );

-- Target: SocialPersona.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SocialPersona'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SocialPersona'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SocialPersona'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'SocialPost' AND [__mj].[IntegrationObjectField].[Name] = N'PersonaId')
      )
  );

GO

-- Target: Solution.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Solution'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Solution'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Solution'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CaseSolution' AND [__mj].[IntegrationObjectField].[Name] = N'SolutionId')
      )
  );

-- Target: SourceCodeRepoProvider.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SourceCodeRepoProvider'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SourceCodeRepoProvider'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SourceCodeRepoProvider'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'SourceCodeRepository' AND [__mj].[IntegrationObjectField].[Name] = N'SourceCodeRepoProviderId')
      )
  );

-- Target: SourceCodeRepository.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SourceCodeRepository'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SourceCodeRepository'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SourceCodeRepository'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'DevopsPipeline' AND [__mj].[IntegrationObjectField].[Name] = N'SourceCodeRepositoryId')
      )
  );

-- Target: SourceCodeRepositoryBranch.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SourceCodeRepositoryBranch'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SourceCodeRepositoryBranch'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SourceCodeRepositoryBranch'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'DevopsPipelineStage' AND [__mj].[IntegrationObjectField].[Name] = N'SourceCodeRepositoryBranchId')
        OR (o.[Name] = N'DevopsPipelnStgPromWkItem' AND [__mj].[IntegrationObjectField].[Name] = N'MergeSourceBranchId')
        OR (o.[Name] = N'WorkItem' AND [__mj].[IntegrationObjectField].[Name] IN (N'RebaseBranchId', N'SourceCodeRepositoryBranchId'))
      )
  );

-- Target: StagedInviteeEmail.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'StagedInviteeEmail'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'StagedInviteeEmail'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'StagedInviteeEmail'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'EventStagedInviteeEmail' AND [__mj].[IntegrationObjectField].[Name] = N'StagedInviteeEmailId')
      )
  );

-- Target: StagedUnmtchdEmailAddr.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'StagedUnmtchdEmailAddr'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'StagedUnmtchdEmailAddr'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'StagedUnmtchdEmailAddr'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'StagedUnmtchdEmailAddrRela' AND [__mj].[IntegrationObjectField].[Name] = N'StagedUnmatchedEmailAddressId')
      )
  );

-- Target: Stamp.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Stamp'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Stamp'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Stamp'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'StampAssignment' AND [__mj].[IntegrationObjectField].[Name] = N'StampId')
      )
  );

-- Target: StaticResource.Id (7 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'StaticResource'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'StaticResource'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'StaticResource'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ConversationChannelDefinition' AND [__mj].[IntegrationObjectField].[Name] = N'CustomIconId')
        OR (o.[Name] = N'ConversationVendorInfo' AND [__mj].[IntegrationObjectField].[Name] = N'CustomIconId')
        OR (o.[Name] = N'LiveChatButton' AND [__mj].[IntegrationObjectField].[Name] IN (N'InviteImageId', N'OfflineImageId', N'OnlineImageId'))
        OR (o.[Name] = N'PresenceUserConfig' AND [__mj].[IntegrationObjectField].[Name] = N'CustomSoundId')
        OR (o.[Name] = N'ServiceChannel' AND [__mj].[IntegrationObjectField].[Name] = N'CustomSoundId')
      )
  );

-- Target: SurveyResponse.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SurveyResponse'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SurveyResponse'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SurveyResponse'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'KnowledgeArticleFeedback' AND [__mj].[IntegrationObjectField].[Name] = N'FeedbackResponseId')
      )
  );

-- Target: SvcCatalogCategory.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SvcCatalogCategory'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SvcCatalogCategory'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SvcCatalogCategory'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'SvcCatalogCategoryItem' AND [__mj].[IntegrationObjectField].[Name] = N'SvcCatalogCategoryId')
      )
  );

-- Target: SvcCatalogItemDef.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SvcCatalogItemDef'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SvcCatalogItemDef'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SvcCatalogItemDef'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'SvcCatalogCategoryItem' AND [__mj].[IntegrationObjectField].[Name] = N'SvcCatalogItemDefId')
        OR (o.[Name] = N'SvcCatalogRequest' AND [__mj].[IntegrationObjectField].[Name] = N'SvcCatalogItemDefinitionId')
      )
  );

-- Target: SvcCatalogRequest.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SvcCatalogRequest'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SvcCatalogRequest'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SvcCatalogRequest'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'SvcCatalogReqRelatedItem' AND [__mj].[IntegrationObjectField].[Name] = N'SvcCatalogRequestId')
      )
  );

-- Target: Swarm.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Swarm'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Swarm'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Swarm'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'SwarmMember' AND [__mj].[IntegrationObjectField].[Name] = N'SwarmId')
      )
  );

-- Target: Task.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Task'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Task'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Task'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'EmailStatus' AND [__mj].[IntegrationObjectField].[Name] = N'TaskId')
        OR (o.[Name] = N'ListEmailSentResult' AND [__mj].[IntegrationObjectField].[Name] = N'ActivityId')
        OR (o.[Name] = N'UnifiedTask' AND [__mj].[IntegrationObjectField].[Name] = N'DetailId')
        OR (o.[Name] = N'VoiceCall' AND [__mj].[IntegrationObjectField].[Name] = N'ActivityId')
      )
  );

-- Target: TaxEngine.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'TaxEngine'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'TaxEngine'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'TaxEngine'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'TaxEngineInteractionLog' AND [__mj].[IntegrationObjectField].[Name] = N'TaxEngineId')
        OR (o.[Name] = N'TaxTreatment' AND [__mj].[IntegrationObjectField].[Name] = N'TaxEngineId')
      )
  );

-- Target: TaxEngineProvider.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'TaxEngineProvider'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'TaxEngineProvider'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'TaxEngineProvider'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'TaxEngine' AND [__mj].[IntegrationObjectField].[Name] = N'TaxEngineProviderId')
      )
  );

-- Target: TaxPolicy.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'TaxPolicy'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'TaxPolicy'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'TaxPolicy'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'Product2' AND [__mj].[IntegrationObjectField].[Name] = N'TaxPolicyId')
        OR (o.[Name] = N'TaxTreatment' AND [__mj].[IntegrationObjectField].[Name] = N'TaxPolicyId')
        OR (o.[Name] = N'WebStore' AND [__mj].[IntegrationObjectField].[Name] = N'DefaultTaxPolicyId')
      )
  );

-- Target: TaxTreatment.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'TaxTreatment'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'TaxTreatment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'TaxTreatment'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'BillingSchedule' AND [__mj].[IntegrationObjectField].[Name] = N'TaxTreatmentId')
        OR (o.[Name] = N'CartItem' AND [__mj].[IntegrationObjectField].[Name] = N'TaxTreatmentId')
        OR (o.[Name] = N'OrderItem' AND [__mj].[IntegrationObjectField].[Name] = N'TaxTreatmentId')
        OR (o.[Name] = N'OrderItemSummary' AND [__mj].[IntegrationObjectField].[Name] = N'TaxTreatmentId')
      )
  );

-- Target: Territory2.Id (10 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Territory2'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Territory2'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Territory2'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ForecastingSrcRecJudgment' AND [__mj].[IntegrationObjectField].[Name] = N'Territory2Id')
        OR (o.[Name] = N'ForecastingSubmission' AND [__mj].[IntegrationObjectField].[Name] = N'Territory2Id')
        OR (o.[Name] = N'ObjectUserTerritory2View' AND [__mj].[IntegrationObjectField].[Name] = N'Territory2Id')
        OR (o.[Name] = N'OpportunityLineItemSplit' AND [__mj].[IntegrationObjectField].[Name] = N'Territory2Id')
        OR (o.[Name] = N'OpportunitySplit' AND [__mj].[IntegrationObjectField].[Name] = N'Territory2Id')
        OR (o.[Name] = N'Territory2AlignmentLog' AND [__mj].[IntegrationObjectField].[Name] = N'Territory2Id')
        OR (o.[Name] = N'Territory2ObjectExclusion' AND [__mj].[IntegrationObjectField].[Name] = N'Territory2Id')
        OR (o.[Name] = N'Territory2ObjSharingConfig' AND [__mj].[IntegrationObjectField].[Name] = N'Territory2Id')
        OR (o.[Name] = N'TerritoryAdminAssignment' AND [__mj].[IntegrationObjectField].[Name] = N'Territory2Id')
        OR (o.[Name] = N'UserTerritory2AssocLog' AND [__mj].[IntegrationObjectField].[Name] = N'Territory2Id')
      )
  );

-- Target: Territory2Model.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Territory2Model'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Territory2Model'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Territory2Model'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'Territory2AlignmentLog' AND [__mj].[IntegrationObjectField].[Name] = N'Territory2ModelId')
        OR (o.[Name] = N'TerritoryAdminAssignment' AND [__mj].[IntegrationObjectField].[Name] = N'Territory2ModelId')
        OR (o.[Name] = N'UserTerritory2AssocLog' AND [__mj].[IntegrationObjectField].[Name] = N'Territory2ModelId')
      )
  );

-- Target: TerritoryMgmtObjectConfig.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'TerritoryMgmtObjectConfig'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'TerritoryMgmtObjectConfig'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'TerritoryMgmtObjectConfig'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'Territory2ObjSharingConfig' AND [__mj].[IntegrationObjectField].[Name] = N'TerritoryMgmtObjectConfigId')
      )
  );

-- Target: TimeSlot.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'TimeSlot'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'TimeSlot'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'TimeSlot'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AppointmentTopicTimeSlot' AND [__mj].[IntegrationObjectField].[Name] = N'TimeSlotId')
      )
  );

-- Target: Topic.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Topic'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Topic'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Topic'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'TopicAssignment' AND [__mj].[IntegrationObjectField].[Name] = N'TopicId')
      )
  );

-- Target: TravelMode.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'TravelMode'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'TravelMode'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'TravelMode'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ServiceTerritory' AND [__mj].[IntegrationObjectField].[Name] = N'TravelModeId')
        OR (o.[Name] = N'ServiceTerritoryMember' AND [__mj].[IntegrationObjectField].[Name] = N'TravelModeId')
      )
  );

-- Target: UiFormulaRule.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UiFormulaRule'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UiFormulaRule'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'UiFormulaRule'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'UiFormulaCriterion' AND [__mj].[IntegrationObjectField].[Name] = N'RuleId')
      )
  );

GO

-- Target: UnifiedActivityInsight.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UnifiedActivityInsight'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UnifiedActivityInsight'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'UnifiedActivityInsight'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'UnifiedActvtyInsightKeyword' AND [__mj].[IntegrationObjectField].[Name] = N'InsightId')
      )
  );

-- Target: UnifiedEmail.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UnifiedEmail'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UnifiedEmail'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'UnifiedEmail'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'UnifiedEmailParticipant' AND [__mj].[IntegrationObjectField].[Name] = N'ActivityId')
      )
  );

-- Target: UnifiedMeeting.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UnifiedMeeting'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UnifiedMeeting'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'UnifiedMeeting'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'UnifiedMeetingParticipant' AND [__mj].[IntegrationObjectField].[Name] = N'ActivityId')
      )
  );

-- Target: UnifiedTask.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UnifiedTask'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UnifiedTask'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'UnifiedTask'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'UnifiedTaskParticipant' AND [__mj].[IntegrationObjectField].[Name] = N'ActivityId')
      )
  );

-- Target: UnifiedVideoCall.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UnifiedVideoCall'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UnifiedVideoCall'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'UnifiedVideoCall'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'UnifiedVideoCallParticipant' AND [__mj].[IntegrationObjectField].[Name] = N'ActivityId')
      )
  );

-- Target: UnifiedVoiceCall.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UnifiedVoiceCall'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UnifiedVoiceCall'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'UnifiedVoiceCall'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'UnifiedVoiceCallParticipant' AND [__mj].[IntegrationObjectField].[Name] = N'ActivityId')
      )
  );

-- Target: UnitOfMeasure.Id (8 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UnitOfMeasure'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UnitOfMeasure'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'UnitOfMeasure'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AssetRateCardEntry' AND [__mj].[IntegrationObjectField].[Name] = N'RateUnitOfMeasureId')
        OR (o.[Name] = N'AttributeDefinition' AND [__mj].[IntegrationObjectField].[Name] = N'UnitOfMeasureId')
        OR (o.[Name] = N'AttributePicklist' AND [__mj].[IntegrationObjectField].[Name] = N'UnitOfMeasureId')
        OR (o.[Name] = N'CartItemAttribute' AND [__mj].[IntegrationObjectField].[Name] = N'UnitOfMeasure')
        OR (o.[Name] = N'Product2' AND [__mj].[IntegrationObjectField].[Name] = N'UnitOfMeasureId')
        OR (o.[Name] = N'ProgramRebateType' AND [__mj].[IntegrationObjectField].[Name] = N'UnitOfMeasureId')
        OR (o.[Name] = N'QuoteLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'QuantityUnitOfMeasureId')
        OR (o.[Name] = N'UsageImpactGroupFactor' AND [__mj].[IntegrationObjectField].[Name] = N'UnitOfMeasureId')
      )
  );

-- Target: UsageImpactFactor.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UsageImpactFactor'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UsageImpactFactor'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'UsageImpactFactor'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'UsageImpactGroupFactor' AND [__mj].[IntegrationObjectField].[Name] = N'UsageImpactFactorId')
      )
  );

-- Target: UsageImpactGroup.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UsageImpactGroup'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UsageImpactGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'UsageImpactGroup'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'UsageImpactGroupVersion' AND [__mj].[IntegrationObjectField].[Name] = N'UsageImpactGroupId')
      )
  );

-- Target: UsageImpactGroupVersion.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UsageImpactGroupVersion'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UsageImpactGroupVersion'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'UsageImpactGroupVersion'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'UsageImpactGroupFactor' AND [__mj].[IntegrationObjectField].[Name] = N'UsageImpactGroupVersionId')
        OR (o.[Name] = N'UsageImpactGroupPgmMeasure' AND [__mj].[IntegrationObjectField].[Name] = N'UsageImpactGroupVersionId')
      )
  );

-- Target: User.Id (174 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'User'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'User'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'User'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'Account' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'AccountPlanObjective' AND [__mj].[IntegrationObjectField].[Name] = N'ObjectiveOwnerId')
        OR (o.[Name] = N'ActionCadence' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'ActionCadenceStepTracker' AND [__mj].[IntegrationObjectField].[Name] = N'CompletedById')
        OR (o.[Name] = N'ActivityFieldHistory' AND [__mj].[IntegrationObjectField].[Name] = N'ChangedById')
        OR (o.[Name] = N'AgentWork' AND [__mj].[IntegrationObjectField].[Name] IN (N'PreferredUserId', N'TransferRequesterId', N'UserId'))
        OR (o.[Name] = N'AnalyticsDashboard' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'AnalyticsVisualization' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'AnalyticsVizViewDef' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'ApexEmailNotification' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'ApexInlineEventLog' AND [__mj].[IntegrationObjectField].[Name] = N'LogUserId')
        OR (o.[Name] = N'ApexLog' AND [__mj].[IntegrationObjectField].[Name] = N'LogUserId')
        OR (o.[Name] = N'ApexTestRunResult' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'ApplicationFormTemplate' AND [__mj].[IntegrationObjectField].[Name] = N'ApproverId')
        OR (o.[Name] = N'ApprovalSubmission' AND [__mj].[IntegrationObjectField].[Name] IN (N'OwnerId', N'SubmittedById'))
        OR (o.[Name] = N'ApprovalSubmissionDetail' AND [__mj].[IntegrationObjectField].[Name] = N'ActionPerformedById')
        OR (o.[Name] = N'ApprovalWorkItem' AND [__mj].[IntegrationObjectField].[Name] IN (N'AssignedToId', N'ReviewedById'))
        OR (o.[Name] = N'Asset' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'AuthSession' AND [__mj].[IntegrationObjectField].[Name] = N'UsersId')
        OR (o.[Name] = N'BotDefinition' AND [__mj].[IntegrationObjectField].[Name] = N'BotUserId')
        OR (o.[Name] = N'BusinessAlertStatus' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'BuyerAccount' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'CallCtrAgentFavTrfrDest' AND [__mj].[IntegrationObjectField].[Name] = N'AgentId')
        OR (o.[Name] = N'Campaign' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'ChangeRequest' AND [__mj].[IntegrationObjectField].[Name] = N'ReviewerId')
        OR (o.[Name] = N'ClientBrowser' AND [__mj].[IntegrationObjectField].[Name] = N'UsersId')
        OR (o.[Name] = N'CollaborationGroup' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'CollaborationGroupMember' AND [__mj].[IntegrationObjectField].[Name] = N'MemberId')
        OR (o.[Name] = N'CollaborationGroupMemberRequest' AND [__mj].[IntegrationObjectField].[Name] = N'RequesterId')
        OR (o.[Name] = N'Contact' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'ContentDistribution' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'ContentDocument' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'ContentDocumentSubscription' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'ContentNotification' AND [__mj].[IntegrationObjectField].[Name] = N'UsersId')
        OR (o.[Name] = N'ContentTagSubscription' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'ContentUserSubscription' AND [__mj].[IntegrationObjectField].[Name] IN (N'SubscribedToUserId', N'SubscriberUserId'))
        OR (o.[Name] = N'ContentVersion' AND [__mj].[IntegrationObjectField].[Name] IN (N'ContentModifiedById', N'OwnerId'))
        OR (o.[Name] = N'ContentVersionRating' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'ContentWorkspaceSubscription' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'Contract' AND [__mj].[IntegrationObjectField].[Name] IN (N'ActivatedById', N'CompanySignedId', N'OwnerId'))
        OR (o.[Name] = N'ConversationApiLog' AND [__mj].[IntegrationObjectField].[Name] = N'RequestedById')
        OR (o.[Name] = N'Dashboard' AND [__mj].[IntegrationObjectField].[Name] = N'RunningUserId')
        OR (o.[Name] = N'DataIntegrationRecordPurchasePermission' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'DelegatedAccount' AND [__mj].[IntegrationObjectField].[Name] = N'ManagedById')
        OR (o.[Name] = N'DeleteEvent' AND [__mj].[IntegrationObjectField].[Name] = N'DeletedById')
        OR (o.[Name] = N'DeliveryEstimationSetup' AND [__mj].[IntegrationObjectField].[Name] = N'LastSyncedById')
        OR (o.[Name] = N'DevopsActivityLog' AND [__mj].[IntegrationObjectField].[Name] = N'PerformedById')
        OR (o.[Name] = N'DevopsEnvDeploymentMbr' AND [__mj].[IntegrationObjectField].[Name] = N'ChangedById')
        OR (o.[Name] = N'Document' AND [__mj].[IntegrationObjectField].[Name] = N'AuthorId')
        OR (o.[Name] = N'EmailTemplate' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'EntitySubscription' AND [__mj].[IntegrationObjectField].[Name] = N'SubscriberId')
        OR (o.[Name] = N'ExternalDataUserAuth' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'FeedComment' AND [__mj].[IntegrationObjectField].[Name] = N'InsertedById')
        OR (o.[Name] = N'FeedItem' AND [__mj].[IntegrationObjectField].[Name] = N'InsertedById')
        OR (o.[Name] = N'FeedLike' AND [__mj].[IntegrationObjectField].[Name] = N'InsertedById')
        OR (o.[Name] = N'feedSignal' AND [__mj].[IntegrationObjectField].[Name] = N'InsertedById')
        OR (o.[Name] = N'FldSvcObjChg' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'FlowOrchestrationInstance' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'FlowOrchestrationStepInstance' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'FlowOrchestrationVersion' AND [__mj].[IntegrationObjectField].[Name] = N'ActivatedById')
        OR (o.[Name] = N'FlowOrchestrationWorkItem' AND [__mj].[IntegrationObjectField].[Name] IN (N'AssigneeId', N'OwnerId'))
        OR (o.[Name] = N'FlowRecordVersion' AND [__mj].[IntegrationObjectField].[Name] IN (N'ActivatedById', N'PausingUserId', N'ResumingUserId'))
        OR (o.[Name] = N'ForecastingCustomData' AND [__mj].[IntegrationObjectField].[Name] = N'ForecastOwnerId')
        OR (o.[Name] = N'ForecastingSrcRecJudgment' AND [__mj].[IntegrationObjectField].[Name] = N'JudgmentOwnerId')
        OR (o.[Name] = N'ForecastingSubmission' AND [__mj].[IntegrationObjectField].[Name] = N'ForecastOwnerId')
        OR (o.[Name] = N'Incident' AND [__mj].[IntegrationObjectField].[Name] = N'ResolvedById')
        OR (o.[Name] = N'Individual' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'KnowledgeArticleFeedback' AND [__mj].[IntegrationObjectField].[Name] = N'FeedbackSubmitterId')
        OR (o.[Name] = N'LandingPage' AND [__mj].[IntegrationObjectField].[Name] IN (N'ContentLastSavedById', N'LastPublishedById'))
        OR (o.[Name] = N'LearningItemAssignment' AND [__mj].[IntegrationObjectField].[Name] = N'AssigneeId')
        OR (o.[Name] = N'LearningItemProgress' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'LightningExitByPageMetrics' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'LightningToggleMetrics' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'LightningUsageByAppTypeMetrics' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'LightningUsageByPageMetrics' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'ListViewChart' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'LoginIp' AND [__mj].[IntegrationObjectField].[Name] = N'UsersId')
        OR (o.[Name] = N'MessagingSession' AND [__mj].[IntegrationObjectField].[Name] = N'TargetUserId')
        OR (o.[Name] = N'MobSecurityCertPinEvent' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'MyDomainDiscoverableLogin' AND [__mj].[IntegrationObjectField].[Name] = N'ExecuteApexHandlerAsId')
        OR (o.[Name] = N'NetworkAuthApiSettings' AND [__mj].[IntegrationObjectField].[Name] IN (N'HeadlessDiscoveryExecutionUserId', N'RegistrationExecutionUserId'))
        OR (o.[Name] = N'Note' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'NoteAndAttachment' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'OauthToken' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'OauthTokenExchHandlerApp' AND [__mj].[IntegrationObjectField].[Name] = N'ApexExecutionUserId')
        OR (o.[Name] = N'ObjectUserTerritory2View' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'OmniSupervisorConfigUser' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'Opportunity' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'OpportunityLineItemSplit' AND [__mj].[IntegrationObjectField].[Name] = N'SplitOwnerId')
        OR (o.[Name] = N'OpportunitySplit' AND [__mj].[IntegrationObjectField].[Name] = N'SplitOwnerId')
        OR (o.[Name] = N'Order' AND [__mj].[IntegrationObjectField].[Name] IN (N'ActivatedById', N'CompanyAuthorizedById'))
        OR (o.[Name] = N'OutgoingEmail' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'OutgoingEmailRelation' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'OwnedContentDocument' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'PaymentIntent' AND [__mj].[IntegrationObjectField].[Name] = N'SubmittedById')
        OR (o.[Name] = N'PendingServiceRouting' AND [__mj].[IntegrationObjectField].[Name] = N'TransferRequesterId')
        OR (o.[Name] = N'PermissionSetAssignment' AND [__mj].[IntegrationObjectField].[Name] = N'AssigneeId')
        OR (o.[Name] = N'PermissionSetLicenseAssign' AND [__mj].[IntegrationObjectField].[Name] = N'AssigneeId')
        OR (o.[Name] = N'PersonAccountOwnerPowerUser' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'PersonTraining' AND [__mj].[IntegrationObjectField].[Name] = N'AssigneeId')
        OR (o.[Name] = N'PickTicket' AND [__mj].[IntegrationObjectField].[Name] = N'AssignedToId')
        OR (o.[Name] = N'PipelineInspectionListView' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'PlatformAction' AND [__mj].[IntegrationObjectField].[Name] = N'InvokedByUserId')
        OR (o.[Name] = N'Problem' AND [__mj].[IntegrationObjectField].[Name] = N'ResolvedById')
        OR (o.[Name] = N'ProcessInstance' AND [__mj].[IntegrationObjectField].[Name] IN (N'LastActorId', N'SubmittedById'))
        OR (o.[Name] = N'ProcessInstanceNode' AND [__mj].[IntegrationObjectField].[Name] = N'LastActorId')
        OR (o.[Name] = N'ProfileSkillEndorsement' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'ProfileSkillUser' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'PromptAction' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'PromptVersion' AND [__mj].[IntegrationObjectField].[Name] = N'PublishedByUserId')
        OR (o.[Name] = N'QuickTextUsage' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'RecentFieldChange' AND [__mj].[IntegrationObjectField].[Name] = N'ValueChangedById')
        OR (o.[Name] = N'RecordActionHistory' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'ReturnOrder' AND [__mj].[IntegrationObjectField].[Name] = N'ReturnedById')
        OR (o.[Name] = N'SamlSsoConfig' AND [__mj].[IntegrationObjectField].[Name] = N'ExecutionUserID')
        OR (o.[Name] = N'ServiceRequest' AND [__mj].[IntegrationObjectField].[Name] = N'AssignedUserId')
        OR (o.[Name] = N'ServiceResource' AND [__mj].[IntegrationObjectField].[Name] = N'RelatedRecordId')
        OR (o.[Name] = N'SessionPermSetActivation' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'SfdcPartnerOffer' AND [__mj].[IntegrationObjectField].[Name] = N'SentToCustomerById')
        OR (o.[Name] = N'SfdcPartnerOrder' AND [__mj].[IntegrationObjectField].[Name] = N'SentByUserId')
        OR (o.[Name] = N'SfdcPartnerSbscrOffer' AND [__mj].[IntegrationObjectField].[Name] = N'RespondingUserId')
        OR (o.[Name] = N'Site' AND [__mj].[IntegrationObjectField].[Name] IN (N'AdminId', N'GuestRecordDefaultOwnerId', N'GuestUserId'))
        OR (o.[Name] = N'SkillLevelProgress' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'SocialPost' AND [__mj].[IntegrationObjectField].[Name] IN (N'DeletedById', N'HiddenById'))
        OR (o.[Name] = N'Solution' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'StagedUnmtchdEmailAddr' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'StampAssignment' AND [__mj].[IntegrationObjectField].[Name] = N'SubjectId')
        OR (o.[Name] = N'SvcCatalogRequest' AND [__mj].[IntegrationObjectField].[Name] = N'SubmitterId')
        OR (o.[Name] = N'Territory2AlignmentLog' AND [__mj].[IntegrationObjectField].[Name] = N'RunAsId')
        OR (o.[Name] = N'ThirdPartyAccountLink' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'ThreatDetectionFeedback' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'TodayGoal' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'UnifiedActivityInsight' AND [__mj].[IntegrationObjectField].[Name] = N'OwnerId')
        OR (o.[Name] = N'UserAppInfo' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'UserDailyMetric' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'UserListView' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'UserMonthlyMetric' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'UserProvAccount' AND [__mj].[IntegrationObjectField].[Name] = N'SalesforceUserId')
        OR (o.[Name] = N'UserProvAccountStaging' AND [__mj].[IntegrationObjectField].[Name] = N'SalesforceUserId')
        OR (o.[Name] = N'UserProvisioningLog' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'UserProvisioningRequest' AND [__mj].[IntegrationObjectField].[Name] IN (N'ManagerId', N'SalesforceUserId'))
        OR (o.[Name] = N'UserRelatedRecordContent' AND [__mj].[IntegrationObjectField].[Name] = N'ContentOwnerId')
        OR (o.[Name] = N'UserShare' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'UserTerritory2AssocLog' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'VerificationHistory' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'VideoCall' AND [__mj].[IntegrationObjectField].[Name] IN (N'ConsentedUserId', N'HostId'))
        OR (o.[Name] = N'VoiceCall' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'VoiceMailGreeting2Rep' AND [__mj].[IntegrationObjectField].[Name] = N'RepId')
        OR (o.[Name] = N'VoiceVendorLine' AND [__mj].[IntegrationObjectField].[Name] = N'UserId')
        OR (o.[Name] = N'WorkBadge' AND [__mj].[IntegrationObjectField].[Name] IN (N'GiverId', N'RecipientId'))
        OR (o.[Name] = N'WorkItem' AND [__mj].[IntegrationObjectField].[Name] IN (N'AssignedToId', N'DevelopmentApprovedById'))
        OR (o.[Name] = N'WorkThanks' AND [__mj].[IntegrationObjectField].[Name] = N'GiverId')
      )
  );

-- Target: UserAccessChange.Id (6 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UserAccessChange'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UserAccessChange'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'UserAccessChange'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PermissionSetAssignment' AND [__mj].[IntegrationObjectField].[Name] IN (N'LastCreatedByChangeId', N'LastDeletedByChangeId'))
        OR (o.[Name] = N'PermissionSetLicenseAssign' AND [__mj].[IntegrationObjectField].[Name] IN (N'LastCreatedByChangeId', N'LastDeletedByChangeId'))
        OR (o.[Name] = N'UserPackageLicense' AND [__mj].[IntegrationObjectField].[Name] IN (N'LastCreatedByChangeId', N'LastDeletedByChangeId'))
      )
  );

-- Target: UserDefinedLabel.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UserDefinedLabel'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UserDefinedLabel'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'UserDefinedLabel'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'UserDefinedLabelAssignment' AND [__mj].[IntegrationObjectField].[Name] = N'LabelId')
      )
  );

-- Target: UserEmailPreferredPerson.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UserEmailPreferredPerson'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UserEmailPreferredPerson'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'UserEmailPreferredPerson'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'UserEmailPreferredPersonShare' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
      )
  );

-- Target: UserLicense.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UserLicense'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UserLicense'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'UserLicense'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'ActiveProfileMetric' AND [__mj].[IntegrationObjectField].[Name] = N'UserLicenseId')
        OR (o.[Name] = N'Profile' AND [__mj].[IntegrationObjectField].[Name] = N'UserLicenseId')
      )
  );

-- Target: UserListView.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UserListView'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UserListView'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'UserListView'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'UserListViewCriterion' AND [__mj].[IntegrationObjectField].[Name] = N'UserListViewId')
      )
  );

-- Target: UserProvAccount.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UserProvAccount'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UserProvAccount'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'UserProvAccount'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'UserProvisioningRequest' AND [__mj].[IntegrationObjectField].[Name] = N'UserProvAccountId')
      )
  );

-- Target: UserProvisioningConfig.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UserProvisioningConfig'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UserProvisioningConfig'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'UserProvisioningConfig'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'UserProvisioningRequest' AND [__mj].[IntegrationObjectField].[Name] = N'UserProvConfigId')
      )
  );

-- Target: UserProvisioningRequest.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UserProvisioningRequest'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UserProvisioningRequest'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'UserProvisioningRequest'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'UserProvisioningLog' AND [__mj].[IntegrationObjectField].[Name] = N'UserProvisioningRequestId')
      )
  );

-- Target: UserRole.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UserRole'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'UserRole'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'UserRole'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'Name' AND [__mj].[IntegrationObjectField].[Name] = N'UserRoleId')
        OR (o.[Name] = N'RecentlyViewed' AND [__mj].[IntegrationObjectField].[Name] = N'UserRoleId')
        OR (o.[Name] = N'User' AND [__mj].[IntegrationObjectField].[Name] = N'UserRoleId')
      )
  );

-- Target: VideoCall.Id (5 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'VideoCall'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'VideoCall'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'VideoCall'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'GenAIConversationSummary' AND [__mj].[IntegrationObjectField].[Name] = N'ConversationRecordId')
        OR (o.[Name] = N'LearningItemSubmission' AND [__mj].[IntegrationObjectField].[Name] = N'CallId')
        OR (o.[Name] = N'UnifiedVideoCall' AND [__mj].[IntegrationObjectField].[Name] = N'DetailId')
        OR (o.[Name] = N'VideoCallParticipant' AND [__mj].[IntegrationObjectField].[Name] = N'VideoCallId')
        OR (o.[Name] = N'VideoCallRecording' AND [__mj].[IntegrationObjectField].[Name] = N'VideoCallRecordId')
      )
  );

-- Target: VideoCallInsightReason.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'VideoCallInsightReason'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'VideoCallInsightReason'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'VideoCallInsightReason'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'VideoCallInsightAction' AND [__mj].[IntegrationObjectField].[Name] = N'ActionReferenceId')
      )
  );

-- Target: VideoCallParticipant.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'VideoCallParticipant'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'VideoCallParticipant'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'VideoCallParticipant'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'VideoCallRecordingStructure' AND [__mj].[IntegrationObjectField].[Name] = N'VideoCallParticipantId')
      )
  );

-- Target: VideoCallRecording.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'VideoCallRecording'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'VideoCallRecording'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'VideoCallRecording'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'VideoCallInsight' AND [__mj].[IntegrationObjectField].[Name] = N'VideoCallRecordingId')
        OR (o.[Name] = N'VideoCallRecordingStructure' AND [__mj].[IntegrationObjectField].[Name] = N'VideoCallRecordingId')
      )
  );

-- Target: VoiceCall.Id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'VoiceCall'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'VoiceCall'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'VoiceCall'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AgentWorkConversationalData' AND [__mj].[IntegrationObjectField].[Name] = N'ChannelSessionRecordId')
        OR (o.[Name] = N'UnifiedVoiceCall' AND [__mj].[IntegrationObjectField].[Name] = N'DetailId')
        OR (o.[Name] = N'VoiceCallRecording' AND [__mj].[IntegrationObjectField].[Name] = N'VoiceCallId')
      )
  );

GO

-- Target: VoiceCallInsightReason.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'VoiceCallInsightReason'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'VoiceCallInsightReason'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'VoiceCallInsightReason'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'VoiceCallInsightAction' AND [__mj].[IntegrationObjectField].[Name] = N'ActionReferenceId')
      )
  );

-- Target: VoiceCallRecording.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'VoiceCallRecording'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'VoiceCallRecording'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'VoiceCallRecording'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AgentWorkConversationalData' AND [__mj].[IntegrationObjectField].[Name] = N'AgentChannelRecordingId')
        OR (o.[Name] = N'VoiceCallInsight' AND [__mj].[IntegrationObjectField].[Name] = N'VoiceCallRecordingId')
      )
  );

-- Target: VoiceMailGreeting2.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'VoiceMailGreeting2'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'VoiceMailGreeting2'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'VoiceMailGreeting2'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'VoiceMailGreeting2Rep' AND [__mj].[IntegrationObjectField].[Name] = N'VoiceMailGreeting2Id')
      )
  );

-- Target: VoiceVendorInfo.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'VoiceVendorInfo'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'VoiceVendorInfo'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'VoiceVendorInfo'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'VoiceVendorLine' AND [__mj].[IntegrationObjectField].[Name] = N'VoiceVendorInfoId')
      )
  );

-- Target: VoiceVendorLine.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'VoiceVendorLine'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'VoiceVendorLine'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'VoiceVendorLine'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'VoiceCall' AND [__mj].[IntegrationObjectField].[Name] = N'VoiceVendorLineId')
      )
  );

-- Target: WebCart.Id (6 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WebCart'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WebCart'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'WebCart'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CartDeliveryGroup' AND [__mj].[IntegrationObjectField].[Name] = N'CartId')
        OR (o.[Name] = N'CartItem' AND [__mj].[IntegrationObjectField].[Name] = N'CartId')
        OR (o.[Name] = N'CartItemPriceAdjustment' AND [__mj].[IntegrationObjectField].[Name] = N'CartId')
        OR (o.[Name] = N'PaymentInitiationSource' AND [__mj].[IntegrationObjectField].[Name] = N'WebCartId')
        OR (o.[Name] = N'WebCartAdjustmentBasis' AND [__mj].[IntegrationObjectField].[Name] = N'WebCartId')
        OR (o.[Name] = N'WebCartAdjustmentGroup' AND [__mj].[IntegrationObjectField].[Name] = N'CartId')
      )
  );

-- Target: WebCartAdjustmentGroup.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WebCartAdjustmentGroup'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WebCartAdjustmentGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'WebCartAdjustmentGroup'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CartItemPriceAdjustment' AND [__mj].[IntegrationObjectField].[Name] = N'WebCartAdjustmentGroupId')
      )
  );

-- Target: WebStore.Id (13 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WebStore'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WebStore'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'WebStore'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'CalculatedInsightRangeBound' AND [__mj].[IntegrationObjectField].[Name] = N'SalesStoreId')
        OR (o.[Name] = N'Order' AND [__mj].[IntegrationObjectField].[Name] = N'SalesStoreId')
        OR (o.[Name] = N'OrderSummary' AND [__mj].[IntegrationObjectField].[Name] = N'SalesStoreId')
        OR (o.[Name] = N'PaymentInitiationSource' AND [__mj].[IntegrationObjectField].[Name] = N'WebStoreId')
        OR (o.[Name] = N'PendingOrderSummary' AND [__mj].[IntegrationObjectField].[Name] = N'SalesStoreId')
        OR (o.[Name] = N'PromotionSegmentSalesStore' AND [__mj].[IntegrationObjectField].[Name] = N'SalesStoreId')
        OR (o.[Name] = N'ShippingConfigurationSet' AND [__mj].[IntegrationObjectField].[Name] = N'TargetRecordId')
        OR (o.[Name] = N'WebCart' AND [__mj].[IntegrationObjectField].[Name] = N'WebStoreId')
        OR (o.[Name] = N'WebstoreBuyerGroup' AND [__mj].[IntegrationObjectField].[Name] = N'WebStoreId')
        OR (o.[Name] = N'WebStoreInventorySource' AND [__mj].[IntegrationObjectField].[Name] = N'WebStoreId')
        OR (o.[Name] = N'WebStoreNetwork' AND [__mj].[IntegrationObjectField].[Name] = N'WebStoreId')
        OR (o.[Name] = N'WebStoreSearchProdSettings' AND [__mj].[IntegrationObjectField].[Name] = N'WebStoreId')
        OR (o.[Name] = N'WebStoreShare' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
      )
  );

-- Target: WorkAccess.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WorkAccess'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WorkAccess'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'WorkAccess'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'WorkAccessShare' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
      )
  );

-- Target: WorkBadgeDefinition.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WorkBadgeDefinition'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WorkBadgeDefinition'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'WorkBadgeDefinition'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'WorkAccess' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
        OR (o.[Name] = N'WorkBadge' AND [__mj].[IntegrationObjectField].[Name] = N'DefinitionId')
      )
  );

-- Target: WorkDemographic.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WorkDemographic'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WorkDemographic'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'WorkDemographic'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'WorkforceCapacityUnit' AND [__mj].[IntegrationObjectField].[Name] = N'WorkDemographicId')
        OR (o.[Name] = N'WorkloadUnit' AND [__mj].[IntegrationObjectField].[Name] = N'WorkDemographicId')
      )
  );

-- Target: WorkforceCapacity.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WorkforceCapacity'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WorkforceCapacity'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'WorkforceCapacity'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'WorkforceCapacityUnit' AND [__mj].[IntegrationObjectField].[Name] = N'WorkforceCapacityId')
      )
  );

-- Target: WorkItem.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WorkItem'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WorkItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'WorkItem'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'DevopsActivityLog' AND [__mj].[IntegrationObjectField].[Name] = N'WorkItemId')
        OR (o.[Name] = N'DevopsPipelnStgPromWkItem' AND [__mj].[IntegrationObjectField].[Name] = N'WorkItemId')
      )
  );

-- Target: Workload.Id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Workload'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Workload'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Workload'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'WorkforceCapacity' AND [__mj].[IntegrationObjectField].[Name] = N'WorkloadId')
        OR (o.[Name] = N'WorkloadUnit' AND [__mj].[IntegrationObjectField].[Name] = N'WorkloadId')
      )
  );

-- Target: WorkOrder.Id (7 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WorkOrder'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WorkOrder'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'WorkOrder'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PaymentInitiationSource' AND [__mj].[IntegrationObjectField].[Name] = N'WorkOrderId')
        OR (o.[Name] = N'ProductRequest' AND [__mj].[IntegrationObjectField].[Name] = N'WorkOrderId')
        OR (o.[Name] = N'ProductRequestLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'WorkOrderId')
        OR (o.[Name] = N'WorkOrderHistory' AND [__mj].[IntegrationObjectField].[Name] = N'WorkOrderId')
        OR (o.[Name] = N'WorkOrderLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'WorkOrderId')
        OR (o.[Name] = N'WorkOrderShare' AND [__mj].[IntegrationObjectField].[Name] = N'ParentId')
        OR (o.[Name] = N'WorkPlan' AND [__mj].[IntegrationObjectField].[Name] = N'WorkOrderId')
      )
  );

-- Target: WorkOrderLineItem.Id (5 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WorkOrderLineItem'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WorkOrderLineItem'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'WorkOrderLineItem'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'PaymentInitiationSource' AND [__mj].[IntegrationObjectField].[Name] = N'WorkOrderLineItemId')
        OR (o.[Name] = N'ProductRequest' AND [__mj].[IntegrationObjectField].[Name] = N'WorkOrderLineItemId')
        OR (o.[Name] = N'ProductRequestLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'WorkOrderLineItemId')
        OR (o.[Name] = N'WorkOrderLineItemHistory' AND [__mj].[IntegrationObjectField].[Name] = N'WorkOrderLineItemId')
        OR (o.[Name] = N'WorkPlan' AND [__mj].[IntegrationObjectField].[Name] = N'WorkOrderLineItemId')
      )
  );

-- Target: WorkPlanTemplate.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WorkPlanTemplate'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WorkPlanTemplate'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'WorkPlanTemplate'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'WorkPlan' AND [__mj].[IntegrationObjectField].[Name] = N'WorkPlanTemplateId')
      )
  );

-- Target: WorkThanks.Id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WorkThanks'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WorkThanks'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'WorkThanks'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'WorkBadge' AND [__mj].[IntegrationObjectField].[Name] = N'SourceId')
      )
  );

-- Target: WorkType.Id (6 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WorkType'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WorkType'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'WorkType'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AppointmentTopicTimeSlot' AND [__mj].[IntegrationObjectField].[Name] = N'WorkTypeId')
        OR (o.[Name] = N'ServiceAppointment' AND [__mj].[IntegrationObjectField].[Name] = N'WorkTypeId')
        OR (o.[Name] = N'ServiceTerritoryWorkType' AND [__mj].[IntegrationObjectField].[Name] = N'WorkTypeId')
        OR (o.[Name] = N'WorkOrder' AND [__mj].[IntegrationObjectField].[Name] = N'WorkTypeId')
        OR (o.[Name] = N'WorkOrderLineItem' AND [__mj].[IntegrationObjectField].[Name] = N'WorkTypeId')
        OR (o.[Name] = N'WorkTypeGroupMember' AND [__mj].[IntegrationObjectField].[Name] = N'WorkTypeId')
      )
  );

-- Target: WorkTypeGroup.Id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WorkTypeGroup'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'Id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'WorkTypeGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'WorkTypeGroup'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'salesforce'
      AND (
        (o.[Name] = N'AppointmentTopicTimeSlot' AND [__mj].[IntegrationObjectField].[Name] = N'WorkTypeGroupId')
        OR (o.[Name] = N'QuoteLineWorkSource' AND [__mj].[IntegrationObjectField].[Name] = N'WorkTypeGroupId')
        OR (o.[Name] = N'TimeSlot' AND [__mj].[IntegrationObjectField].[Name] = N'WorkTypeGroupId')
        OR (o.[Name] = N'WorkTypeGroupMember' AND [__mj].[IntegrationObjectField].[Name] = N'WorkTypeGroupId')
      )
  );
