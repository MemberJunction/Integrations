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
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AssignmentRole'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'AssignmentRole'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'AssignmentRole'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'fonteva'
      AND (
        (o.[Name] = N'Assignment' AND [__mj].[IntegrationObjectField].[Name] = N'assignmentRole')
      )
  );

-- Target: BadgeType.id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BadgeType'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BadgeType'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'BadgeType'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'fonteva'
      AND (
        (o.[Name] = N'Badge' AND [__mj].[IntegrationObjectField].[Name] = N'badgeType')
        OR (o.[Name] = N'BadgeWorkflow' AND [__mj].[IntegrationObjectField].[Name] = N'badgeType')
      )
  );

-- Target: BusinessGroup.id (7 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BusinessGroup'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'BusinessGroup'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'BusinessGroup'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'fonteva'
      AND (
        (o.[Name] = N'CreditMemo' AND [__mj].[IntegrationObjectField].[Name] = N'businessGroup')
        OR (o.[Name] = N'Invoice' AND [__mj].[IntegrationObjectField].[Name] = N'businessGroup')
        OR (o.[Name] = N'PaymentGateway' AND [__mj].[IntegrationObjectField].[Name] = N'businessGroup')
        OR (o.[Name] = N'Receipt' AND [__mj].[IntegrationObjectField].[Name] = N'businessGroup')
        OR (o.[Name] = N'SalesOrder' AND [__mj].[IntegrationObjectField].[Name] = N'businessGroup')
        OR (o.[Name] = N'SalesOrderLine' AND [__mj].[IntegrationObjectField].[Name] = N'businessGroup')
        OR (o.[Name] = N'ScheduledPaymentLine' AND [__mj].[IntegrationObjectField].[Name] = N'businessGroup')
      )
  );

-- Target: Event.id (2 field(s))
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
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'id')
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
      AND LOWER(i.[Name]) = N'fonteva'
      AND (
        (o.[Name] = N'EventChatterGroup' AND [__mj].[IntegrationObjectField].[Name] = N'event')
        OR (o.[Name] = N'SalesOrderLine' AND [__mj].[IntegrationObjectField].[Name] = N'event')
      )
  );

-- Target: Invoice.id (4 field(s))
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
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'id')
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
      AND LOWER(i.[Name]) = N'fonteva'
      AND (
        (o.[Name] = N'CreditMemo' AND [__mj].[IntegrationObjectField].[Name] = N'invoice')
        OR (o.[Name] = N'CreditNote' AND [__mj].[IntegrationObjectField].[Name] = N'invoice')
        OR (o.[Name] = N'ReceiptLine' AND [__mj].[IntegrationObjectField].[Name] = N'invoice')
        OR (o.[Name] = N'ScheduledPayment' AND [__mj].[IntegrationObjectField].[Name] = N'invoice')
      )
  );

-- Target: Item.id (8 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Item'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Item'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Item'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'fonteva'
      AND (
        (o.[Name] = N'Assignment' AND [__mj].[IntegrationObjectField].[Name] = N'item')
        OR (o.[Name] = N'BadgeWorkflow' AND [__mj].[IntegrationObjectField].[Name] = N'item')
        OR (o.[Name] = N'ReceiptLine' AND [__mj].[IntegrationObjectField].[Name] = N'item')
        OR (o.[Name] = N'SalesOrderLine' AND [__mj].[IntegrationObjectField].[Name] = N'item')
        OR (o.[Name] = N'ScheduledPaymentLine' AND [__mj].[IntegrationObjectField].[Name] = N'item')
        OR (o.[Name] = N'Subscription' AND [__mj].[IntegrationObjectField].[Name] = N'item')
        OR (o.[Name] = N'SubscriptionLine' AND [__mj].[IntegrationObjectField].[Name] = N'item')
        OR (o.[Name] = N'Term' AND [__mj].[IntegrationObjectField].[Name] = N'item')
      )
  );

-- Target: PaymentGateway.id (2 field(s))
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
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'id')
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
      AND LOWER(i.[Name]) = N'fonteva'
      AND (
        (o.[Name] = N'Receipt' AND [__mj].[IntegrationObjectField].[Name] = N'paymentGateway')
        OR (o.[Name] = N'ScheduledPayment' AND [__mj].[IntegrationObjectField].[Name] = N'paymentGateway')
      )
  );

-- Target: PaymentMethod.id (4 field(s))
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
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'id')
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
      AND LOWER(i.[Name]) = N'fonteva'
      AND (
        (o.[Name] = N'Receipt' AND [__mj].[IntegrationObjectField].[Name] = N'paymentMethod')
        OR (o.[Name] = N'SalesOrderLine' AND [__mj].[IntegrationObjectField].[Name] = N'paymentMethod')
        OR (o.[Name] = N'ScheduledPayment' AND [__mj].[IntegrationObjectField].[Name] = N'paymentMethod')
        OR (o.[Name] = N'Subscription' AND [__mj].[IntegrationObjectField].[Name] = N'paymentMethod')
      )
  );

-- Target: PriceRule.id (2 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PriceRule'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'PriceRule'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'PriceRule'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'fonteva'
      AND (
        (o.[Name] = N'SalesOrderLine' AND [__mj].[IntegrationObjectField].[Name] = N'priceRule')
        OR (o.[Name] = N'ScheduledPaymentLine' AND [__mj].[IntegrationObjectField].[Name] = N'priceRule')
      )
  );

-- Target: Receipt.id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Receipt'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Receipt'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Receipt'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'fonteva'
      AND (
        (o.[Name] = N'ReceiptLine' AND [__mj].[IntegrationObjectField].[Name] = N'receipt')
      )
  );

-- Target: SalesOrder.id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SalesOrder'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SalesOrder'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SalesOrder'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'fonteva'
      AND (
        (o.[Name] = N'Invoice' AND [__mj].[IntegrationObjectField].[Name] = N'salesOrder')
        OR (o.[Name] = N'Receipt' AND [__mj].[IntegrationObjectField].[Name] = N'salesOrder')
        OR (o.[Name] = N'SalesOrderLine' AND [__mj].[IntegrationObjectField].[Name] = N'salesOrder')
        OR (o.[Name] = N'ScheduledPayment' AND [__mj].[IntegrationObjectField].[Name] = N'salesOrder')
      )
  );

-- Target: SalesOrderLine.id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SalesOrderLine'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SalesOrderLine'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SalesOrderLine'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'fonteva'
      AND (
        (o.[Name] = N'Assignment' AND [__mj].[IntegrationObjectField].[Name] = N'salesOrderLine')
        OR (o.[Name] = N'ScheduledPaymentLine' AND [__mj].[IntegrationObjectField].[Name] = N'salesOrderLine')
        OR (o.[Name] = N'SubscriptionLine' AND [__mj].[IntegrationObjectField].[Name] = N'salesOrderLine')
      )
  );

-- Target: ScheduledPayment.id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ScheduledPayment'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'ScheduledPayment'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'ScheduledPayment'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'fonteva'
      AND (
        (o.[Name] = N'ScheduledPaymentLine' AND [__mj].[IntegrationObjectField].[Name] = N'scheduledPayment')
      )
  );

-- Target: Subscription.id (7 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Subscription'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Subscription'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Subscription'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'fonteva'
      AND (
        (o.[Name] = N'Assignment' AND [__mj].[IntegrationObjectField].[Name] = N'subscription')
        OR (o.[Name] = N'Invoice' AND [__mj].[IntegrationObjectField].[Name] = N'subscription')
        OR (o.[Name] = N'SalesOrderLine' AND [__mj].[IntegrationObjectField].[Name] = N'subscription')
        OR (o.[Name] = N'ScheduledPayment' AND [__mj].[IntegrationObjectField].[Name] = N'subscription')
        OR (o.[Name] = N'ScheduledPaymentLine' AND [__mj].[IntegrationObjectField].[Name] = N'subscription')
        OR (o.[Name] = N'SubscriptionLine' AND [__mj].[IntegrationObjectField].[Name] = N'subscription')
        OR (o.[Name] = N'Term' AND [__mj].[IntegrationObjectField].[Name] = N'subscription')
      )
  );

-- Target: SubscriptionLine.id (1 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SubscriptionLine'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SubscriptionLine'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SubscriptionLine'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'fonteva'
      AND (
        (o.[Name] = N'Assignment' AND [__mj].[IntegrationObjectField].[Name] = N'subscriptionLine')
      )
  );

-- Target: SubscriptionPlan.id (3 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SubscriptionPlan'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'SubscriptionPlan'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'SubscriptionPlan'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'fonteva'
      AND (
        (o.[Name] = N'SalesOrderLine' AND [__mj].[IntegrationObjectField].[Name] = N'subscriptionPlan')
        OR (o.[Name] = N'ScheduledPaymentLine' AND [__mj].[IntegrationObjectField].[Name] = N'subscriptionPlan')
        OR (o.[Name] = N'Term' AND [__mj].[IntegrationObjectField].[Name] = N'subscriptionPlan')
      )
  );

-- Target: Term.id (4 field(s))
UPDATE [__mj].[IntegrationObjectField]
SET [RelatedIntegrationObjectID] = COALESCE(
      [RelatedIntegrationObjectID],
      (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Term'
      )
    ),
    [RelatedIntegrationObjectFieldName] = COALESCE([RelatedIntegrationObjectFieldName], N'id')
WHERE (
    [RelatedIntegrationObjectID] IS NULL
    OR (
      [RelatedIntegrationObjectFieldName] IS NULL
      AND [RelatedIntegrationObjectID] = (
        SELECT t.[ID]
        FROM [__mj].[IntegrationObject] t
        INNER JOIN [__mj].[IntegrationObject] s ON s.[IntegrationID] = t.[IntegrationID]
        WHERE s.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
          AND t.[Name] = N'Term'
      )
    )
  )
  AND EXISTS (
    SELECT 1
    FROM [__mj].[IntegrationObject] o
    INNER JOIN [__mj].[Integration] i ON i.[ID] = o.[IntegrationID]
    INNER JOIN [__mj].[IntegrationObject] t ON t.[IntegrationID] = i.[ID] AND t.[Name] = N'Term'
    WHERE o.[ID] = [__mj].[IntegrationObjectField].[IntegrationObjectID]
      AND LOWER(i.[Name]) = N'fonteva'
      AND (
        (o.[Name] = N'Assignment' AND [__mj].[IntegrationObjectField].[Name] = N'term')
        OR (o.[Name] = N'Invoice' AND [__mj].[IntegrationObjectField].[Name] = N'term')
        OR (o.[Name] = N'ScheduledPayment' AND [__mj].[IntegrationObjectField].[Name] = N'term')
        OR (o.[Name] = N'SubscriptionLine' AND [__mj].[IntegrationObjectField].[Name] = N'term')
      )
  );
