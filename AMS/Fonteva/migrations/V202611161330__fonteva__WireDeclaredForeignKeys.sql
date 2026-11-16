-- AMS/Fonteva: wire 63 declared foreign-key relationship(s) into IntegrationObjectField.

--

-- These fields carried Configuration.ReferencedType (and IsForeignKey metadata) pointing to

-- sibling IntegrationObjects in the same connector, but RelatedIntegrationObjectID was left NULL

-- when the catalog was originally authored/seeded.

--

-- DELTA migration, deliberately not a re-seed: existing installed tenants keep their seeded row

-- IDs and Flyway checksums intact. Idempotent (updates directly by seeded IntegrationObjectField.ID).

UPDATE iof
SET RelatedIntegrationObjectID = CAST(v.TargetObjectID AS UNIQUEIDENTIFIER),
    RelatedIntegrationObjectFieldName = v.TargetFieldName
FROM [__mj].[IntegrationObjectField] AS iof
INNER JOIN (VALUES
    ('22E54917-F32B-4787-BE3F-8066972C3D3F', '93D4B377-FA97-43D1-B343-E1DE3071AEAF', N'id'), -- Assignment.term -> Term.id
    ('A265BC28-8749-41CC-A961-06DC57C676AE', '0FDD9C18-5551-4B2B-A6F7-84F730F3725D', N'id'), -- Assignment.item -> Item.id
    ('0F132B2B-15F2-40F9-93A0-01931C7B7D36', '813A97C2-6E75-4F69-AEEC-FDCBB7518224', N'id'), -- Assignment.subscription -> Subscription.id
    ('B8869925-BBD5-4D9C-BBAA-9BFC45A59148', '67567672-257A-43DB-B01D-42640617E78F', N'id'), -- Assignment.subscriptionLine -> SubscriptionLine.id
    ('BC0A0626-F0A4-4A93-B783-D95ABF90743E', '87CC22EF-3B9E-45C2-B65B-8180264BBD4A', N'id'), -- Assignment.salesOrderLine -> SalesOrderLine.id
    ('EB060262-8CBF-44B4-82F4-30A571502771', '927AA313-825E-443A-ADA0-8A35917533CC', N'id'), -- Assignment.assignmentRole -> AssignmentRole.id
    ('307AF408-7394-4939-AD82-414B81041365', '2CA8405F-CAB3-4E03-B68F-2D9C105A4CD9', N'id'), -- Badge.badgeType -> BadgeType.id
    ('5E12E821-3842-4B6C-BD04-1E8E10B703E9', '2CA8405F-CAB3-4E03-B68F-2D9C105A4CD9', N'id'), -- BadgeWorkflow.badgeType -> BadgeType.id
    ('EFFF789F-947D-43B3-BE08-12F76380F515', '0FDD9C18-5551-4B2B-A6F7-84F730F3725D', N'id'), -- BadgeWorkflow.item -> Item.id
    ('41EE2DE5-CA4A-4FCB-A55C-7245AD7B325D', 'CC5E8E4F-FC6C-4BEF-9E1B-1765E536EDEA', N'id'), -- CreditMemo.businessGroup -> BusinessGroup.id
    ('37C5A399-1DBA-49C6-A236-EC82597B6E7A', '06AFD189-9045-407C-86B1-4A1F8EBD9488', N'id'), -- CreditMemo.invoice -> Invoice.id
    ('97D6CA16-32DC-464E-A58B-882A7DB1F23F', '06AFD189-9045-407C-86B1-4A1F8EBD9488', N'id'), -- CreditNote.invoice -> Invoice.id
    ('28666C31-95EF-44C6-8E02-8A64D1AB1CD0', '9278419F-3CFC-467F-AA97-94545455DCD1', N'id'), -- EventChatterGroup.event -> Event.id
    ('B48AE2FF-17B8-46D6-A764-7595AC3DEF51', '93D4B377-FA97-43D1-B343-E1DE3071AEAF', N'id'), -- Invoice.term -> Term.id
    ('A2CE6BFC-B9D4-4007-A9BA-C4218EA86C65', '813A97C2-6E75-4F69-AEEC-FDCBB7518224', N'id'), -- Invoice.subscription -> Subscription.id
    ('B43EED04-5911-42B9-9B29-29F03BA3B786', '1D1D26B2-BED6-4E5A-9F42-FBBD43439113', N'id'), -- Invoice.salesOrder -> SalesOrder.id
    ('0ADA4BF4-B32B-4D1B-96E1-F2FFE9FCE747', '6B39A9E8-924A-4F47-B2D2-8AE63F19E566', N'id'), -- Invoice.scheduledPayment -> ScheduledPayment.id
    ('C4AD7D4E-AD80-4D41-8807-5D832612D7F9', 'CC5E8E4F-FC6C-4BEF-9E1B-1765E536EDEA', N'id'), -- Invoice.businessGroup -> BusinessGroup.id
    ('3C18E245-F533-4E7A-BA43-1A4C55163A91', 'CC5E8E4F-FC6C-4BEF-9E1B-1765E536EDEA', N'id'), -- PaymentGateway.businessGroup -> BusinessGroup.id
    ('A3E9D2CA-BCE6-4E1B-AB71-965AA4DC19CF', 'CC5E8E4F-FC6C-4BEF-9E1B-1765E536EDEA', N'id'), -- Receipt.businessGroup -> BusinessGroup.id
    ('40C2CE2B-5FDB-4A29-9274-AB49C8EC84D9', '1D1D26B2-BED6-4E5A-9F42-FBBD43439113', N'id'), -- Receipt.salesOrder -> SalesOrder.id
    ('968020CD-546F-40FE-81B6-74EAA22C747A', 'A2765979-B351-4CD0-9A9B-B5CAAEA1F733', N'id'), -- Receipt.paymentMethod -> PaymentMethod.id
    ('87B7582B-22F0-4EA0-A9AB-B3B6C35F70B1', 'DD9471EE-499C-4978-9F70-4692D7C0AB96', N'id'), -- Receipt.paymentGateway -> PaymentGateway.id
    ('1D86CB44-3CBA-4373-A096-C15FBB92727B', '44639C90-C63C-4316-9C8C-BD7D13F99C51', N'id'), -- Receipt.receipt -> Receipt.id
    ('97891A40-B1FC-495A-90C6-DC9168F4D2EF', '44639C90-C63C-4316-9C8C-BD7D13F99C51', N'id'), -- ReceiptLine.receipt -> Receipt.id
    ('3C01D081-4391-4618-8AA3-B703F7D1DDD1', '06AFD189-9045-407C-86B1-4A1F8EBD9488', N'id'), -- ReceiptLine.invoice -> Invoice.id
    ('21B76AC8-F5EB-4139-880C-9C09C85A62CC', '0FDD9C18-5551-4B2B-A6F7-84F730F3725D', N'id'), -- ReceiptLine.item -> Item.id
    ('DB15D265-E708-4516-B9F8-8287DC57EDE4', 'CC5E8E4F-FC6C-4BEF-9E1B-1765E536EDEA', N'id'), -- SalesOrder.businessGroup -> BusinessGroup.id
    ('82E7C8B9-583F-4801-B94A-08A069F3CCA8', '44639C90-C63C-4316-9C8C-BD7D13F99C51', N'id'), -- SalesOrder.receipt -> Receipt.id
    ('362DA49A-E42F-4305-A15A-C2569AE8ACFA', '87CC22EF-3B9E-45C2-B65B-8180264BBD4A', N'id'), -- SalesOrderLine.salesOrderLine -> SalesOrderLine.id
    ('2614C3A0-E8FE-4851-AF48-82CE0F88CF37', '0FDD9C18-5551-4B2B-A6F7-84F730F3725D', N'id'), -- SalesOrderLine.item -> Item.id
    ('A48DB0F0-52AE-4C50-AEC9-6B686BC690C1', '05455BF0-36C4-4C2E-B9C0-FDBD3E4E045C', N'id'), -- SalesOrderLine.priceRule -> PriceRule.id
    ('3FBC4F0D-A414-438C-AED5-30CFA996C497', '1D1D26B2-BED6-4E5A-9F42-FBBD43439113', N'id'), -- SalesOrderLine.salesOrder -> SalesOrder.id
    ('2F7E18E1-3ED3-460B-A2C9-0C6F6E943DD4', '813A97C2-6E75-4F69-AEEC-FDCBB7518224', N'id'), -- SalesOrderLine.subscription -> Subscription.id
    ('B1989CD1-4649-409C-906D-1D64689FF72F', 'DE561367-D9FD-479F-9204-5B651ECCCE19', N'id'), -- SalesOrderLine.subscriptionPlan -> SubscriptionPlan.id
    ('D9968FCF-B899-42AE-85B5-674F29624A24', '9278419F-3CFC-467F-AA97-94545455DCD1', N'id'), -- SalesOrderLine.event -> Event.id
    ('13A1AAFC-9AF2-46BE-B9AE-1DB8EBBC0EFC', 'CC5E8E4F-FC6C-4BEF-9E1B-1765E536EDEA', N'id'), -- SalesOrderLine.businessGroup -> BusinessGroup.id
    ('E4D8B3B7-7AD5-45C9-9841-6A91280F4128', 'A2765979-B351-4CD0-9A9B-B5CAAEA1F733', N'id'), -- SalesOrderLine.paymentMethod -> PaymentMethod.id
    ('AA7DEBFD-105D-4308-8FBE-DDF3EBD1BFC0', '06AFD189-9045-407C-86B1-4A1F8EBD9488', N'id'), -- ScheduledPayment.invoice -> Invoice.id
    ('D195DB64-2989-468A-B817-305D6137E36F', '93D4B377-FA97-43D1-B343-E1DE3071AEAF', N'id'), -- ScheduledPayment.term -> Term.id
    ('21E235E1-4AA7-41E0-A815-B97F1E3BEC83', '813A97C2-6E75-4F69-AEEC-FDCBB7518224', N'id'), -- ScheduledPayment.subscription -> Subscription.id
    ('6DF81F16-B8AB-49BC-B98E-E4D5DA4E88CD', 'A2765979-B351-4CD0-9A9B-B5CAAEA1F733', N'id'), -- ScheduledPayment.paymentMethod -> PaymentMethod.id
    ('28E4EE88-723A-4724-B914-3CB0EE0A9B1A', 'DD9471EE-499C-4978-9F70-4692D7C0AB96', N'id'), -- ScheduledPayment.paymentGateway -> PaymentGateway.id
    ('0453C245-1E48-44BF-9BCE-54893C4E3933', '1D1D26B2-BED6-4E5A-9F42-FBBD43439113', N'id'), -- ScheduledPayment.salesOrder -> SalesOrder.id
    ('BD0ED606-09B8-40FA-A78C-C9690479FF0F', '6B39A9E8-924A-4F47-B2D2-8AE63F19E566', N'id'), -- ScheduledPaymentLine.scheduledPayment -> ScheduledPayment.id
    ('0DE7809C-27E8-4C3A-B1F7-1355E0F90DF3', 'CC5E8E4F-FC6C-4BEF-9E1B-1765E536EDEA', N'id'), -- ScheduledPaymentLine.businessGroup -> BusinessGroup.id
    ('6B5EBA99-E13F-441D-9526-9C42B8A9CB19', '0FDD9C18-5551-4B2B-A6F7-84F730F3725D', N'id'), -- ScheduledPaymentLine.item -> Item.id
    ('127ED20D-7448-4CC8-AAEF-CBFCFB29C9DD', '05455BF0-36C4-4C2E-B9C0-FDBD3E4E045C', N'id'), -- ScheduledPaymentLine.priceRule -> PriceRule.id
    ('5C9E5E33-328F-4EA9-9AC1-A492F39A6BED', '87CC22EF-3B9E-45C2-B65B-8180264BBD4A', N'id'), -- ScheduledPaymentLine.salesOrderLine -> SalesOrderLine.id
    ('B4ED1268-E556-49BA-A4FA-4B89914ACF81', '8F0C2E71-AE22-4C29-A38D-766D13336595', N'id'), -- ScheduledPaymentLine.scheduledPaymentLine -> ScheduledPaymentLine.id
    ('7984E27B-87F9-4D7F-98FF-C94810709E09', 'DE561367-D9FD-479F-9204-5B651ECCCE19', N'id'), -- ScheduledPaymentLine.subscriptionPlan -> SubscriptionPlan.id
    ('581260C0-3E46-468B-A8BE-76F92FA12598', '813A97C2-6E75-4F69-AEEC-FDCBB7518224', N'id'), -- ScheduledPaymentLine.subscription -> Subscription.id
    ('3FC4C56C-5F00-44EF-80F5-EA4A46F97C88', '0FDD9C18-5551-4B2B-A6F7-84F730F3725D', N'id'), -- Subscription.item -> Item.id
    ('A116493C-AE71-4918-BCF8-8A866903740F', '87CC22EF-3B9E-45C2-B65B-8180264BBD4A', N'id'), -- Subscription.salesOrderLine -> SalesOrderLine.id
    ('970678DB-1339-4BD5-9B70-7CEB3A8DADFA', 'A2765979-B351-4CD0-9A9B-B5CAAEA1F733', N'id'), -- Subscription.paymentMethod -> PaymentMethod.id
    ('E91225AD-6C3A-4FA5-BC2E-4E6F4B90C91B', '813A97C2-6E75-4F69-AEEC-FDCBB7518224', N'id'), -- SubscriptionLine.subscription -> Subscription.id
    ('412D899A-4299-413C-935B-94050601CB1A', '67567672-257A-43DB-B01D-42640617E78F', N'id'), -- SubscriptionLine.subscriptionLine -> SubscriptionLine.id
    ('9DEE791D-D321-4CB9-ABEF-72126873E0D1', '87CC22EF-3B9E-45C2-B65B-8180264BBD4A', N'id'), -- SubscriptionLine.salesOrderLine -> SalesOrderLine.id
    ('307B3817-BB78-49AE-8F25-430AB44ED810', '0FDD9C18-5551-4B2B-A6F7-84F730F3725D', N'id'), -- SubscriptionLine.item -> Item.id
    ('362C1011-E93D-4145-8240-D72D2C589D04', '93D4B377-FA97-43D1-B343-E1DE3071AEAF', N'id'), -- SubscriptionLine.term -> Term.id
    ('AEE0839E-8F85-4107-B50A-3FDEFC6C5AD2', '813A97C2-6E75-4F69-AEEC-FDCBB7518224', N'id'), -- Term.subscription -> Subscription.id
    ('E99BFAF3-9B31-4E9C-8238-F7E132BD421E', 'DE561367-D9FD-479F-9204-5B651ECCCE19', N'id'), -- Term.subscriptionPlan -> SubscriptionPlan.id
    ('6B33BEA2-65E0-4F98-B87F-EEA71BF60A2F', '0FDD9C18-5551-4B2B-A6F7-84F730F3725D', N'id') -- Term.item -> Item.id
) AS v(FieldID, TargetObjectID, TargetFieldName)
    ON iof.ID = CAST(v.FieldID AS UNIQUEIDENTIFIER);

