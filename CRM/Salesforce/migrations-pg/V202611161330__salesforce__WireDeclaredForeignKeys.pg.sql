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
SET "RelatedIntegrationObjectID" = 'AB088847-83CD-4EFA-8C8C-CFC80763BE60',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '314557D3-1F27-40CE-A9EE-2A4586D19B00' -- PersonalizationPoint.AbnExperimentId
  );

-- Target: Account.Id (73 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '9ED16491-3832-414F-856A-EBAFE44F6AB8',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '82A14BEB-19F1-4328-B386-D2FB437F6223', -- AccountContactRole.AccountId
    '20601E81-3AD9-493E-A846-EB2E07DBCB4F', -- AccountPartner.AccountFromId
    'C619E7F2-F420-4BA1-8143-AFFB24E962B4', -- AccountPartner.AccountToId
    '5FEF4F10-F238-4311-96DB-47355E429494', -- AccountPlan.AccountId
    '0AD45830-505E-4EB8-9877-CC5FEFF171CF', -- AccountShare.AccountId
    'EA4ED415-D026-4BFE-AD95-6CF558ABB586', -- ActivityHistory.AccountId
    '2003F5F0-98AA-441E-A4DA-B7EF5DF24D69', -- AlternativePaymentMethod.AccountId
    '3A2FD159-DF1B-40B9-8FEF-89C07007B0AA', -- Asset.AccountId
    'F6C6CAF3-C271-4991-90C4-749554C34AF9', -- Asset.AssetProvidedById
    'AC7A3822-547D-43C7-BB39-341F4017AD5E', -- Asset.AssetServicedById
    '58FF3652-075A-4999-A543-29563190BFB6', -- BillingSchedule.BillingAccountId
    '9ED82887-C858-4A63-8368-2D9DD4C3F243', -- BillingScheduleGroup.BillingAccountId
    '1498E22D-0544-40DD-B080-FD0B1FF59258', -- BuyerAccount.BuyerId
    '5CB5B483-DF34-49EE-A6C3-503374F9CABE', -- BuyerAccount.PayerId
    '2B707A5C-4E30-4DE0-9547-8A290EEEA1BD', -- BuyerAccount.SendToId
    '7A0A60F1-9E57-4914-98E7-2846ECBACB0E', -- CampaignMember.AccountId
    'FE3EECEB-4D97-4AB0-B2E9-64E6B3994B6D', -- CardPaymentMethod.AccountId
    '8311D418-E9E9-4BE0-8D8F-C69E26E58E26', -- Case.AccountId
    '61DCC1E9-C980-40D5-BF14-E83EE5F6172E', -- Contact.AccountId
    '8A56E123-95BA-4C1E-BE13-51102E11018A', -- Contract.AccountId
    'D85AC35E-D1F6-422C-9F89-529E6CBA072E', -- CreditMemo.BillingAccountId
    'A813CB3A-9F9E-4FC7-864D-5D18BB4721AC', -- DealIndirectPartner.AccountId
    '3A1783EF-8436-4669-A0FA-1BC2EDD36618', -- DelegatedAccount.ParentId
    'B9E13823-6016-4FD2-93F4-36CBC5DE024A', -- DelegatedAccount.TargetId
    '3801166A-DE84-4B73-A777-D5FB48F0CE27', -- DigitalWallet.AccountId
    'B611AC93-C8D0-4C30-919B-C94457C9C240', -- EmpUserProvisionProcessErr.AccountId
    '750E87CC-91AA-4B4B-BAA9-602CC9292C0B', -- Event.AccountId
    '374B9043-0B7E-4FA2-8823-B497C06558FF', -- ExtlRecShrCnctAccnt.AccountId
    '69E21066-F85D-426F-B51C-BC3574CA925D', -- FulfillmentOrder.AccountId
    '773C6E9B-A9CF-4C5A-B9F7-73E39C6081F5', -- Invoice.BillingAccountId
    '7A7DBB0B-0B36-4C5A-B3AC-ABDD41B5601A', -- Lead.ConvertedAccountId
    '62B66997-4619-4D78-81CD-07280D50B1D7', -- LogoutEventStream.AccountId
    '4E2B3349-0781-48F0-9C15-E6E03791D1D1', -- LookedUpFromActivity.AccountId
    'D988856C-0AB1-41ED-B5AA-16F4124FD695', -- MessagingEndUser.AccountId
    '7DE23C5A-6EAA-4BDF-B042-916EF60D8E16', -- MessagingSession.EndUserAccountId
    '333884A9-5884-4E0F-B28B-53B2FD7D3C97', -- OpenActivity.AccountId
    '90037838-EFF2-4737-A5FE-5F99A0BE70FC', -- Opportunity.AccountId
    'A08492D4-1EA1-4C87-92B0-E622CE6014F8', -- OpportunityPartner.AccountToId
    '8931B00A-1C81-443E-9DDD-8F0EC4C915DB', -- Order.AccountId
    '540DC6AE-27F0-4FDD-910C-53C3DD032FE0', -- OrderSummary.AccountId
    'E8AF917D-27B8-479A-8F5A-51F22B06FA28', -- Partner.AccountFromId
    '0061B9CE-AC6C-4FDE-9A5A-9D7097F2CF87', -- Partner.AccountToId
    '466589B8-A628-4A6C-B79B-2357BD9E8B30', -- Payment.AccountId
    '0F249001-B325-4130-840A-406C35ACF65B', -- PaymentAuthAdjustment.AccountId
    '90247006-169E-4DCB-9D54-80EB84DF9E4B', -- PaymentAuthorization.AccountId
    '6A89D21F-E937-43E9-BBCD-7FB8EE76A9A9', -- PaymentCredit.AccountId
    '89E7A5DC-28F4-4A84-B9D8-67FD1217582A', -- PaymentCreditLinePayment.AssociatedAccountId
    'A1DADFDC-58AE-4C47-887E-EFC5E585565F', -- PaymentCreditTransaction.AssociatedAccountId
    '8100252A-AE09-4E68-ABAA-60355300F4F5', -- PaymentInitiationSource.AccountId
    '012A082A-F61A-4A0F-A77E-F6680E921EFA', -- PaymentIntent.AccountId
    '24AEE7EB-B766-4069-B7BB-251E5C874F33', -- PaymentLineInvoice.AssociatedAccountId
    'DB30A834-CE0A-44F0-8D2B-CBC3602317D0', -- PaymentLink.AccountId
    '75E50549-3ED1-4DB6-BA59-AE0765232B7C', -- PaymentMethod.AccountId
    '2979A934-D486-4555-9DCE-9A56E67ED976', -- PaymentSchedule.DefaultPaymentAccountId
    'A0C03C55-C760-42B2-9E93-B6F4054808D4', -- PaymentScheduleItem.PaymentAccountId
    'F43BD161-453E-41C0-B18F-717A65916292', -- PendingOrderSummary.AccountId
    '5BE59CBB-8470-4316-A29D-CFF6099B151B', -- PriceProtectExecLineItem.AccountId
    '7CE31000-CA91-4006-B80B-97012094F41F', -- ProductDetectedPriceChange.AccountId
    'D936E47F-D8A6-4244-B805-785AD0F9469C', -- ProductRequest.AccountId
    '4321D6F9-1F94-469B-8BD1-4BECCA13A8BB', -- ProductRequestLineItem.AccountId
    '9C3487C8-9176-4AB7-B535-D7A45E8492CD', -- Prospect.ConvertedAccountId
    '1A081C6C-25BF-4F0F-9675-1FBBDA6CE4D8', -- PublicComplaint.AccountId
    'FDD63B93-F10C-4729-A2E4-727CD8C43683', -- Quote.QuoteAccountId
    '6DCF2C46-D4ED-40FB-AD8E-212B651F7843', -- Refund.AccountId
    '9840DCCC-78C0-467A-8ECB-16A6509A2F2F', -- RefundLinePayment.AssociatedAccountId
    '5C78800A-2B32-4267-90B3-4F810168536B', -- ReturnOrder.AccountId
    'B8FE9FC7-23A0-410D-9370-EAF9B9BC7466', -- SalesTransactionShape.AccountId
    '23997CE9-0A5E-4BA2-A867-3C4A14D98E07', -- ServiceAppointment.AccountId
    '3135408A-473A-422A-ADE1-3259AFADCE26', -- SfdcCustomerForPartner.AccountId
    '4FC4311E-0484-489B-A8DA-8F05039C4145', -- Task.AccountId
    'F229FD24-02F0-4AC9-A2E4-BC1F99F56A2E', -- Territory2ObjectExclusion.ObjectId
    '24134FAB-F8CC-4E43-98F1-735CC7C64824', -- WebCart.AccountId
    '5BA87F9C-5C18-40BE-A9B4-C8860C69236E' -- WorkOrder.AccountId
  );

-- Target: AccountPlan.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '48E02BE5-71C5-4DF8-B605-81CA6702B62D',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'B07C72E8-12BD-4285-AAAD-A0E793967656' -- AccountPlanObjective.AccountPlanId
  );

-- Target: AccountPlanObjective.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '4E865024-A285-4C3E-BEC6-37FF531F5F4B',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '9E37589F-9EB5-46F4-B2F6-7F01BB02429E' -- AccountPlanObjectiveMeasure.AccountPlanObjectiveId
  );

-- Target: AccountPlanObjMeasCalcDef.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '794F3B18-5832-41DA-8B32-F68069679376',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '3A94450F-988F-41CD-94BE-F2CFC6B6F8C1', -- AccountPlanObjectiveMeasure.AccountPlanObjMeasCalcDefId
    '785333CB-EEC3-48E7-8135-E1EC8C548007' -- AccountPlanObjMeasCalcCond.AccountPlanObjMeasCalcDefId
  );

-- Target: ActionCadence.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'CFACD7D7-7C3B-494C-9F48-F251FB9B8031',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'EA270AE2-179E-476F-B2BD-843EA25F474A', -- Account.PersonActionCadenceId
    'B9A98966-F852-4457-A6E1-2EAE42CCA385', -- ActionCadenceStep.ActionCadenceId
    'F2DF8C23-7FB0-42CD-8622-950A2B015B7E', -- ActionCadenceStep.ChainedCadenceId
    '5F027F8D-58F0-4688-BA46-BF8EA5162765', -- ActionCadenceStepTracker.ActionCadenceId
    'EE0F51ED-6133-4387-9223-37173D6BA3E3' -- ActionCadenceTracker.ActionCadenceId
  );

-- Target: ActionCadenceRule.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '58A05DE9-B611-4A42-ABE4-EB8D43D71513',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'E42CC360-8EA5-443D-B1DA-291D585EE635' -- ActionCadenceTracker.ExitGlobalRuleId
  );

-- Target: ActionCadenceStep.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'E7C6B750-A269-4DA1-AFD2-D57375B57ED3',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '0DBEE8B5-5829-4E61-836A-F396F86B518E', -- ActionCadenceRule.ActionCadenceStepId
    'FC4B838C-D431-4810-9764-ACF13763588F', -- ActionCadenceStepTracker.ActionCadenceStepId
    'E51A9092-6BDC-4864-BC20-ED891D5315B7', -- ActionCadenceStepVariant.ActionCadenceStepId
    '6F59DFB8-A04F-47BA-AC4B-4E03DCD0F1B8', -- ActionCdncStpMonthlyMetric.ActionCadenceStepId
    '8606CF93-FA0B-49F5-9B1C-30F7698A5472' -- ListEmail.ActionCadenceStepId
  );

-- Target: ActionCadenceStepTracker.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'BADC329A-49C4-427A-B5E1-02328AC69104',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '35D6DD2F-908D-4AFF-BAA8-388636F881EC', -- ListEmailIndividualRecipient.ActionCadenceStepTrackerId
    '5F2578D9-9ABE-4594-B123-AE67BFFB9D12' -- ListEmailSentResult.ActionCadenceStepTrackerId
  );

-- Target: ActionCadenceTracker.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '4F15BBDB-F0C1-4938-B571-A301E90E6ECD',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '4C4842A7-E7C4-46BF-8FE6-72C178BBA15D' -- ActionCadenceStepTracker.ActionCadenceTrackerId
  );

-- Target: ActionLinkGroupTemplate.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '6C010AEC-2BDC-46C4-849D-6CEA91363AAF',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'F3B36D2A-3AD2-4DEF-A38A-4B4B296BE10C' -- ActionLinkTemplate.ActionLinkGroupTemplateId
  );

-- Target: ActivityMetric.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '003A2E5A-A1AB-4834-BE0B-4DEE24B39381',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '9F4FEF3F-1CA0-4393-8626-F32E24919FB6', -- Account.ActivityMetricId
    'F47F6F2C-0D26-4432-A34D-756F0056BB76', -- Contact.ActivityMetricId
    '725369EE-8047-4633-A836-F82EFAB37DF1', -- Contract.ActivityMetricId
    '7ADE8CCF-E74C-449A-A643-5F2024D015A1', -- Lead.ActivityMetricId
    'CAE31A2E-89BC-4A08-BC83-E8861848A402' -- Opportunity.ActivityMetricId
  );

-- Target: AgentWork.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '3206034D-DC09-4A1D-A311-25D104020000',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '5E754D63-4C7D-4E4D-84DA-FD394B760B19' -- AgentWorkConversationalData.AgentWorkId
  );

-- Target: AIApplication.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '5180F79A-099B-4A94-83D9-7439F6939E95',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'D5F97212-073A-4C10-9828-D422C1FA1D1F' -- AIRecordInsight.AiApplicationId
  );

-- Target: AiGenActionItem.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '83F83E40-9CD9-49BA-B675-39D1E7F0009A',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'C9208388-D3B1-4630-BB28-8C1F75B51F32' -- AIResearchPromptResult.AiGenActionItemId
  );

-- Target: AIInsightAction.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'D401BBFD-DB40-47BC-950A-D76CD8B87485',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '643A5701-BFE2-42C3-B43A-05105C7756B4' -- AIInsightValue.AiInsightActionId
  );

-- Target: AIInsightValue.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'D0C7C068-8436-4432-8AE7-BE4673E19132',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '0BE4D943-4163-4313-BCEB-63CE6BFA0F5D' -- AIInsightReason.AiInsightValueId
  );

-- Target: AiJobRun.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'B75F0AE6-BF0D-465A-B93D-4B718FD84FA6',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '2615119A-76DD-40AD-A444-66AEE14E5826' -- AiJobRunItem.AiJobRunId
  );

-- Target: AIRecordInsight.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'F656EBEF-2598-4153-AA15-E1A5E3BFEC18',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '4894A0A4-FDD8-40DE-A0CE-5DE74C94A2B4', -- AIInsightAction.AiRecordInsightId
    '31C0B33E-A31C-43CD-9201-F0BBCFBA2C89', -- AIInsightFeedback.AiRecordInsightId
    '1C7EC2A3-DEBB-4912-9A0A-41FF33345F00' -- AIInsightValue.AiRecordInsightId
  );

-- Target: AnalyticsDashboardWidget.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '6ED47E46-7389-42DA-A739-45D1FF6BE4D8',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '3C9B1B4F-AA68-41B4-A396-904FAD7C1173' -- AnalyticsContainerWidgetDef.AnalyticsDashboardWidgetId
  );

-- Target: AnalyticsVisualization.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'E37A4CF3-96AA-489C-8E95-44FD6199BB85',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '51B1D2A3-DD73-4CC0-BE5E-3C2B7E57382E' -- AnalyticsVizViewDef.VisualizationId
  );

-- Target: AnalyticsWorkspace.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '6A570A3B-571C-4165-8A87-EB66F2405CB2',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '69EA0C3B-F2C2-48A2-B690-E7E7B03B26B8', -- AnalyticsDashboard.AnalyticsWorkspaceId
    '8E082C4B-8FC8-4260-8F12-F60399A1D8A9' -- AnalyticsVisualization.AnalyticsWorkspaceId
  );

-- Target: ApexClass.Id (16 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'FB884315-1AF8-4773-8EE5-2ABE2913297B',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '7F62874D-5227-471B-AD29-A87AFF1957A5', -- ApexTestQueueItem.ApexClassId
    '3A3B8B84-1D9B-4516-8768-83FE4A179104', -- ApexTestResult.ApexClassId
    '35414AA0-1094-410D-ACAE-9F745079D2A7', -- ApexTypeImplementor.ApexClassId
    '2B431F66-642D-4E6F-B0CE-020B431BD6CD', -- ApexTypeImplementor.InterfaceApexClassId
    '98CB70E7-2714-4CEE-86E5-6C4601FF9E7E', -- AppointmentSchedulingPolicy.ExtCalEventHandlerId
    '4E3D1E36-6594-426F-AFF4-EE18938E1CA0', -- AsyncApexJob.ApexClassId
    '3E3F8EDA-F55A-43FC-8D28-39C34A44DA81', -- LearningItemType.ApexEvaluationHandlerId
    '25356A22-21C9-44BD-84AA-F7964ABD0075', -- LearningItemType.ApexSerializerDeserializerId
    'D70F152B-3FCC-4274-BB05-54ECE8E348E8', -- MyDomainDiscoverableLogin.ApexHandlerId
    'C37ACC3C-1961-4C41-8A77-8CC150590F52', -- NetworkAuthApiSettings.HeadlessDiscoveryHandlerId
    'C5D5315D-07F9-428D-AECB-D881ECAC286E', -- NetworkAuthApiSettings.RegistrationHandlerId
    '566CF752-CBA4-45A0-BEDE-B5D27575553B', -- OauthTokenExchangeHandler.TokenHandlerApexId
    '6BB43280-1E08-4599-81FE-969843B6BC33', -- PaymentGatewayProvider.ApexAdapterId
    'AA3232AD-84BE-4362-B6B3-F11FE1538752', -- SamlSsoConfig.SamlJitHandlerId
    'A0BE0B48-F746-4D07-BB31-E5AED0227183', -- TaxEngineProvider.ApexAdapterId
    'AD33937F-C6E6-450A-B265-D69DA94CC663' -- TestSuiteMembership.ApexClassId
  );

-- Target: ApexLog.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '9EF2AA4E-DC9A-4B97-9CCD-95B91F53E9B8',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '785B0C2E-5DC9-4922-86D6-2A896C8BAD67' -- ApexTestResult.ApexLogId
  );

-- Target: ApexPage.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '45BE079A-C880-4A8F-BAEB-E20A07C66B4E',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'F34DF7D0-9715-44A0-8736-B17E01525EA0', -- LiveChatButton.ChatPageId
    'FE3FFAA2-2F48-4E81-B0C6-1EB97A5D7EB5', -- LiveChatButton.PostchatPageId
    '209893E2-438A-4B48-860E-FF70F14CBD4A', -- LiveChatButton.PrechatFormPageId
    'D1D4E466-06E5-4383-BA69-7996CF4EAB9B' -- VisualforceAccessMetrics.ApexPageId
  );

-- Target: ApexTestQueueItem.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'E8D216F3-68EF-404F-AD7A-9B10122641AE',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '5C5EF235-748E-460D-B42F-9C51C95B9EE0' -- ApexTestResult.QueueItemId
  );

-- Target: ApexTestResult.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '3B362DF9-A02A-4A93-8E62-BA20BDDFCA79',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'ED69FC33-B54E-46FE-88E9-E9308E566C96' -- ApexTestResultLimits.ApexTestResultId
  );

-- Target: ApexTestRunResult.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '63E1C15F-DCB2-421F-93AF-99F04C71577F',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'AB54C3A1-D2CE-4F33-AE31-D71BF5B1FC98' -- ApexTestResult.ApexTestRunResultId
  );

-- Target: ApexTestSuite.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '1D0C21F2-230F-44DF-A245-5BD9AE94C459',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '39341676-74B3-44A7-B826-E6B7064435A4' -- TestSuiteMembership.ApexTestSuiteId
  );

-- Target: AppDefinition.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'AF842A45-7FCD-4A99-9BD5-3D297960E4B6',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '28B1D30A-2B0C-4578-9B0C-9635170966AB' -- UserAppInfo.AppDefinitionId
  );

-- Target: AppMenuItem.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '140B23E2-4B1F-4111-A0D6-8D544E6F21CF',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'DEBEF779-DDDE-45BA-B4B8-ADFF2BC7BB0B' -- OauthToken.AppMenuItemId
  );

-- Target: AppointmentAssignmentPolicy.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'F263695F-E1B4-4197-A25E-D8D299081D95',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'A237FCD1-9D12-4B5B-8A61-583ED9A1D487' -- AppointmentSchedulingPolicy.AppointmentAssignmentPolicyId
  );

-- Target: AppointmentScheduleAggr.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '04720F6B-DB11-4068-A25F-F3FC5E1B14BE',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'AD9B1748-38F1-4445-92FF-8DEB9AA9CF80' -- AppointmentScheduleLog.AppointmentScheduleAggrId
  );

-- Target: ApprovalWorkItem.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '85953BF2-D9CC-4884-BE3D-8A5C1782421E',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'B31FFC64-9B33-437A-A37E-2BBDC8C31AEF' -- ApprovalSubmissionDetail.ApprovalWorkItemId
  );

-- Target: ApptBundleAggrPolicy.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '3B733FE2-5DAD-4505-942A-7FE5BAAB3792',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '8DF70B1A-AAA1-444B-85E8-148B562E8C4E' -- ApptBundleAggrDurDnscale.BundleAggregationPolicyId
  );

-- Target: ApptBundlePolicy.Id (6 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '8F3B0D64-2EAD-47F3-A8E8-134F20FD94CF',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '6D1FA9A8-C011-47D8-9DF4-EDAF56006D55', -- ApptBundleAggrPolicy.BundlePolicyId
    'C879D841-44AA-4132-B810-496A8D617AA7', -- ApptBundlePolicySvcTerr.BundlePolicyId
    'B2874C95-FA27-43EC-A9C7-2F30E338F457', -- ApptBundlePropagatePolicy.BundlePolicyId
    'F63DBFC5-F925-43F5-BB25-EB501894F7B0', -- ApptBundleRestrictPolicy.BundlePolicyId
    '3D55E648-37A6-4054-95FD-A2631669BC32', -- ApptBundleSortPolicy.BundlePolicyId
    'E2B268E3-DC3D-4995-ACD2-3380437430F6' -- ServiceAppointment.BundlePolicyId
  );

-- Target: Asset.Id (20 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '600F6022-74C4-4B6D-9E9D-1B9775B3AD87',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '8AFE13BA-2CB0-4544-8CF5-5435E233E138', -- AssetAction.AssetId
    '39870C2A-D820-4B35-8ABC-AADD47D93B4C', -- AssetAttribute.AssetId
    'B798B095-AFFB-4198-8AAC-64425133DD3D', -- AssetContractRelationship.AssetId
    'BA3141F0-2891-47C0-91C4-6DF72270C92C', -- AssetRateCardEntry.BindingObjectId
    '02838E19-C9B0-444D-8130-D66D7AA41E50', -- AssetRelationship.AssetId
    '1D3D9E53-7E00-450F-A1E9-AE64C0EAE8D0', -- AssetRelationship.RelatedAssetId
    '347C0C51-CB3A-4854-800A-A7871107DF03', -- AssetShare.AssetId
    '68A81DAB-C4AD-4D3B-B0D5-A5A085CB571F', -- AssetStatePeriod.AssetId
    '4451D9E1-9918-44A3-B3B0-A54009617B98', -- BillingScheduleGroup.ReferenceEntityId
    '4FC35D35-DCF2-46A7-93C9-176276E94850', -- ChangeRequestRelatedItem.AssetId
    '608AEB40-7A92-4607-9AB5-FB6D09F43952', -- IncidentRelatedItem.AssetId
    '6CC6352B-A971-43FD-8DEB-CAE86E71C2D9', -- OrderAction.SourceAssetId
    '87E50459-CA95-4F09-BC8C-F865689EB2B6', -- OrderItemSummary.AssetId
    'E572C7F0-CBA0-4CD1-8A09-08769B9769CE', -- ProblemRelatedItem.AssetId
    '87041737-BC06-4940-BF86-AFA7008F2929', -- QuoteAction.SourceAssetId
    '75590700-3091-4424-8C52-B39E80F881A8', -- QuoteLineWorkSource.AssetId
    'B68C689F-EB72-46C8-948E-E31EC7564D2D', -- RecordsetFltrCritMonitor.AssetId
    '38F3949F-8255-44B1-A1F1-8CDB09A34C33', -- ReturnOrderLineItem.AssetId
    '2C45905A-751F-4A71-9648-B5AD9040C92B', -- WorkOrder.AssetId
    'FF052CEA-502A-463F-9117-68676FF0F6FE' -- WorkOrderLineItem.AssetId
  );

-- Target: AssetAction.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'C0F77F06-B77D-4E15-9482-DB9E68E28F4E',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '84E5895F-1887-42CA-84EE-00C4A12BC9AA' -- AssetActionSource.AssetActionId
  );

-- Target: AsyncApexJob.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '17FDC4DA-5819-43CF-B64D-CBD71394DD58',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'F9B3BFD4-C6C0-4792-8D55-0210AC48EDFE', -- ApexTestResult.AsyncApexJobId
    'C11CA5EB-AB4D-4D23-9CE8-A56207AA0D98', -- ApexTestRunResult.AsyncApexJobId
    '976DFA1F-A1E9-45A8-98D4-0AB9EA74AA16' -- FlexQueueItem.AsyncApexJobId
  );

-- Target: AsyncOperationLog.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'D802C335-1B37-4743-8C0D-F8C936E7DB68',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '43658E3A-523F-4E69-8DD0-D33A172902D4' -- OSAsyncChgCompletedEvent.AsyncOperationLogId
  );

-- Target: AsyncOperationTracker.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'A94CB542-1214-40C0-8EE0-5820465F9EA6',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '38C9B7BF-F5D6-4C13-B6E1-2178EC3B8ABA', -- AsyncOpSyndicationFeedFile.AsyncOperationTrackerId
    '0A94D71D-C005-463C-B47D-16E44F2ADB41', -- ProcessException.GroupById
    'A9CA7420-8F91-478A-8692-1B3384B18BD8' -- RevenueTransactionErrorLog.AsyncOperationTrackerId
  );

-- Target: AttributeDefinition.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '2A84FAF3-1D82-4F0C-8BCB-5AC976EA7C8A',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '066E1204-F3EA-47C9-9EEB-566D3B30D905', -- AssetAttribute.AttributeDefinitionId
    '6308DCE1-7FBB-40CF-BACF-58C78AF573FE', -- AssetStatePeriodAttribute.AttributeDefinitionId
    '7984DDF5-F575-46DD-9DBE-7EFF7E6AE804' -- CartItemAttribute.AttributeDefinitionId
  );

-- Target: AttributePicklist.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '1D7B79CF-194D-4327-9BE9-3B179D776B77',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'EB012641-6414-4288-9F46-0BFD00132BD8', -- AttributeDefinition.PicklistId
    'FFAE4F48-05B8-4186-A3D8-2CED62B15AB9' -- AttributePicklistValue.PicklistId
  );

-- Target: AttributePicklistValue.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '3CD7FE02-F6CB-4E3B-8E6C-0A26652FA333',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '11DC03EC-673C-4B26-9FB4-A34ED7F7CA89', -- AssetAttribute.AttributePicklistValueId
    'CC50B007-0EA3-4DDE-BC2C-A5F448D1AECE', -- AssetStatePeriodAttribute.AttributePicklistValueId
    'FD6A9E4D-EAF4-4FF7-AAB7-B4487091C8E0' -- CartItemAttribute.AttributePicklistValueId
  );

-- Target: AuraDefinitionBundle.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'C450FF3F-FE48-4637-8D6A-8CB4ADA6BD81',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'C3C5B256-E04D-4014-A456-46D4E8CFC941' -- AuraDefinition.AuraDefinitionBundleId
  );

-- Target: AuthConfig.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '1A365C90-DCCB-4D1C-811C-AFCEEB2E3D01',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'DDDF7C9B-A0FA-48F3-9788-80B5A06FFF28' -- AuthConfigProviders.AuthConfigId
  );

-- Target: AuthorizationForm.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'FD1454D7-406C-45F0-8B4E-34B4C7635CF2',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '87981715-7750-4670-A606-7C4EC2D4DD58', -- AuthorizationFormDataUse.AuthorizationFormId
    '4F48193D-3BAA-4645-920B-0C029A19D7F3' -- AuthorizationFormText.AuthorizationFormId
  );

-- Target: AuthorizationFormText.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'C595D9E9-B56C-46F3-8ABE-685E06C3EFD6',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'FCA6FC01-585D-464D-B355-CED8A4478B84' -- AuthorizationFormConsent.AuthorizationFormTextId
  );

-- Target: AuthProvider.Id (6 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '010FEAB8-97C1-4D90-9306-0B8D51B73BF6',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '77D0A187-F922-48E9-B78E-1AA65ED0EEFD', -- AuthProvParamFwdAllowlist.AuthProviderId
    'B9E7FDC1-92CC-408A-A9EA-BB1256698E79', -- ExternalClientApplication.AuthProviderId
    'CE72006D-6B79-478A-9B39-154978506D3D', -- ExternalDataSource.AuthProviderId
    '8ED4E1FB-53A7-4091-B87E-A266A1063606', -- ExternalDataUserAuth.AuthProviderId
    '205653EE-8527-4A42-91FE-2574EEA36BB4', -- NamedCredential.AuthProviderId
    '5C7BE81F-B0FD-4DDF-929E-7E90D308A90F' -- ThirdPartyAccountLink.SsoProviderId
  );

-- Target: AuthSession.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '86365C95-093D-4358-8A4B-7625CCFADB13',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '4EF5EC02-A3E9-4249-9263-4CD16E5CE6B9' -- SessionPermSetActivation.AuthSessionId
  );

-- Target: AutomatedAction.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '70605C76-601F-40A9-8BEC-339F7F5EE920',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '79E6021B-39E3-48BA-8229-2FC531584A48', -- AutomatedActionCondition.AutomatedActionId
    '1F97366C-BF10-4DF3-BD0C-3006B759B2A8', -- AutomatedActionParameter.AutomatedActionId
    '42CF42E3-6B9B-47CF-8B7D-EB9E3902C1FE' -- AutomatedActionReminder.AutomatedActionId
  );

-- Target: BillingBatchScheduler.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '1B7506E8-ED35-4253-9212-0BAFF22F0E99',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '543E24A1-D64D-4693-A608-F9814910797C' -- InvoiceBatchRun.BillingBatchSchedulerId
  );

-- Target: BillingPolicy.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'A7C3C767-9E5E-493A-80AA-92E5D3D22674',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '67C84EB8-645C-49F4-AAA9-D518243B534A', -- BillingTreatment.BillingPolicyId
    'D02DF99C-8C98-47EB-9632-C3440E7DCB65' -- Product2.BillingPolicyId
  );

-- Target: BillingSchedule.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '30CEE210-8C14-4413-84CC-B4C7D678A721',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'BFDB78D5-4BD3-4BC4-9F4E-2593D79D38AA', -- BillingPeriodItem.BillingScheduleId
    '814DE1F3-C9BD-4E30-8924-452500A6BD28' -- InvoiceLine.BillingScheduleId
  );

-- Target: BillingScheduleGroup.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '17697CA1-56D0-413C-A84A-5D5A34D5C098',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '4B5900B3-A788-4B80-924C-634B07103BFC', -- BillingSchedule.BillingScheduleGroupId
    '13AE7322-5B82-4A72-9856-1486FB6D04C2', -- InvoiceLine.BillingScheduleGroupId
    'FF9282D8-BA7C-4D22-81D8-EE81CD8CEC1E' -- RevenueTransactionErrorLog.BillingScheduleGroupId
  );

-- Target: BillingTreatment.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '361A616E-4ECC-4B9E-9B51-66757D841AC3',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '54CB86B7-9E9A-4704-892E-4753DDC60904' -- BillingTreatmentItem.BillingTreatmentId
  );

-- Target: BillingTreatmentItem.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '2873C283-EC76-4013-94C0-957D7E4FA525',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '82534A8A-F7C8-454A-81AE-F158EB28FF3A' -- BillingSchedule.BillingTreatmentItemId
  );

-- Target: BotDefinition.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'C6207439-943F-4314-9ECD-E7344B2BDF5B',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '07EE8707-46D7-45AF-8E48-231AAF65542B', -- AgentWork.BotId
    'D8C29A79-F9F9-4C30-8F44-60337DB8FEA8', -- AiGenActionItem.BotDefinitionId
    '1B834E18-BAA4-4CC7-A515-BE39A0A5BF09', -- BotVersion.BotDefinitionId
    '7739DDE0-97F8-477C-AE8F-8410705EF07D' -- PendingServiceRouting.BotId
  );

-- Target: BotVersion.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '4FE51BDE-1F09-4DFE-91E3-7E3B39928DD5',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '43CF2784-A8BD-4156-A528-EF49C84DE91E' -- AiGenActionItem.BotVersionId
  );

-- Target: BrandingSet.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'FA7CBF16-DA3E-45D6-8228-5183CB896666',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '5E60448D-5E97-481F-840A-DB05FB8D046E' -- LightningExperienceTheme.DefaultBrandingSetId
  );

-- Target: BriefcaseDefinition.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '0B090765-F17D-47D7-B2CB-9890D7139F74',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '40CD072E-2733-4FA1-993E-CE6EB1FCBA85' -- BriefcaseRule.BriefcaseId
  );

-- Target: BroadcastCommunication.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'E5DEB589-CC76-44B4-9255-D81068F935B5',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '2332E8EB-541A-4F74-BBC7-8C1F5CD08D3C' -- BroadcastCommAudience.BroadcastCommunicationId
  );

-- Target: BroadcastTopic.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'CBD3A392-F2B9-4E1C-9C56-CC3C5E7F4445',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '56477558-AD89-49B3-BED1-B2673CE6FEB5', -- BroadcastTopicGroup.BroadcastTopicId
    'CE443AF1-3A84-49F7-9DF6-53C953808170' -- BroadcastTopicNetwork.BroadcastTopicId
  );

-- Target: BusinessAlert.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '5895C5DA-68F7-46E5-A32F-AD98045A452D',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'DBD9BDE3-1B32-462E-9E4C-5E6605FE84FE' -- BusinessAlertStatus.BusinessAlertId
  );

-- Target: BusinessBrand.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '2256B560-234F-48DD-8E07-F682B7D7DFB0',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'A5420C5B-8737-4394-95F6-BDCC1405C2A8', -- CommSubscriptionConsent.BusinessBrandId
    '4AEB89D7-FD3E-418B-8C9C-D0E8198FACEE', -- ContactPointConsent.BusinessBrandId
    '8674453C-6206-4E30-A86F-E471DCF95CA6' -- ContactPointTypeConsent.BusinessBrandId
  );

-- Target: BusinessHours.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'D3C5D483-BCDA-42D9-AAD0-430F043B2C2B',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '36A38B72-4A43-4DD5-9DF4-325713630B5B', -- DeliveryEstimationSetup.DefaultBusinessHoursId
    '8B52301A-0F3F-495D-B195-4910A9362269', -- MessagingChannel.BusinessHoursId
    '967628F3-C1ED-4511-B92F-9C2B7BEED6EF', -- ServiceRequest.BusinessHoursId
    '00ED463E-9A85-4CC2-BDE9-8F4AA1A68A7E' -- WorkOrder.BusinessHoursId
  );

-- Target: BuyerCriteria.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '8E9CE6F7-FAD2-49B5-A8C2-39B746A59AE1',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '11EF693C-9AEB-4256-A323-9287C7114F8D' -- BuyerGroupBuyerCriteria.BuyerCriteriaId
  );

-- Target: BuyerGroup.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'A413B987-1307-496E-A284-BF13227822EE',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'B3008080-4628-4F2E-9103-B7D73B902770', -- BuyerGroupBuyerCriteria.BuyerGroupId
    '45E80E20-1A08-4D6F-B055-D83A378980ED', -- BuyerGroupMember.BuyerGroupId
    '89F71D58-6182-4790-B16C-F694F04B6B30', -- BuyerGroupRelatedObject.BuyerGroupId
    'FC5A2D57-6240-43A4-ADF9-B694BCF78F6C', -- PromotionSegmentBuyerGroup.BuyerGroupId
    'FF040FE6-578E-45D7-B925-83A85EE9BF2D' -- WebstoreBuyerGroup.BuyerGroupId
  );

-- Target: CalculationMatrix.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '8513C1A6-C48C-4EE8-A530-271C265D6E22',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '43F899EA-4611-4D6F-AFD7-BF8153F92646', -- CalculationMatrixColumn.CalculationMatrixId
    'CE16ED6C-49F2-4C20-8274-7B25C5C385FB', -- CalculationMatrixVersion.CalculationMatrixId
    '8514E280-161B-4542-A06B-662DAE979A18' -- CalculationProcedureStep.CalculationMatrixId
  );

-- Target: CalculationMatrixVersion.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '22928513-5FDB-4CD8-8E9F-0D976BAB555E',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '41F36E7A-6913-4DC7-976A-1987F587EF60' -- CalculationMatrixRow.CalculationMatrixVersionId
  );

-- Target: CalculationProcedure.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'DCE6B75C-AA96-4692-A2A5-6D143151A2C1',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'ED545873-EB5E-4F5B-A774-9ED06D054580', -- CalculationProcedureStep.ReferenceProcedureId
    'ED699AC9-ACBB-41AB-9355-9DEC62CCEE7F' -- CalculationProcedureVersion.CalculationProcedureId
  );

-- Target: CalculationProcedureStep.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '6B9AA3A3-7839-4099-BA42-4DDFB61AADCF',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '364A4E65-6425-4FB7-A4DE-D7966EF88047', -- CalcProcStepRelationship.CalcProcStepId
    '3E65785E-5AC1-4041-9A4E-8050BDAD8133' -- CalcProcStepRelationship.ParentCalcProcStepId
  );

-- Target: CalculationProcedureVersion.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'E83D6E1C-193F-4653-8AEA-7E510EDA4EDF',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '9E30D6F8-BDE7-4E87-AEF1-04A322E42144', -- CalcProcStepRelationship.CalcProcVersionId
    'CA2B86F7-13A6-488B-8B75-7EC4EFF09715', -- CalculationProcedureStep.CalculationProcedureVersionId
    '7179AA40-FD12-48FE-B6BC-35361262607E' -- CalculationProcedureVariable.CalculationProcedureVersionId
  );

-- Target: CallCenter.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '7A6AA7EF-E166-4C4A-BF8A-1A66230DA152',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '3D1D58B9-C9F9-4198-8266-F4B85E800511', -- CallCenterRoutingMap.CallCenterId
    '41FB3135-3962-4F24-89BC-99670F8338D4', -- CallCtrAgentFavTrfrDest.CallCenterId
    '73C9F7AF-947D-44ED-8C0E-422006C9DE80' -- VendorCallCenterStatusMap.CallCenterId
  );

-- Target: CallCoachingMediaProvider.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'A1ED3034-48BE-4703-8FA0-C8ED2A036F2A',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'A3063CC9-14BF-456B-8321-478386766F94' -- VoiceCall.MediaProviderId
  );

-- Target: CallCtrAgentFavTrfrDest.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '7A8F8B33-C4FE-4C04-A72D-BA7D0E0BFDFD',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '2EFEDF8B-64AB-4215-A1D3-C210A36364D8' -- CallCtrAgentFavTrfrDestShare.ParentId
  );

-- Target: Campaign.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'EF0EA377-CEC3-4D3F-8C28-C7C09BE0B69E',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'DCFA9334-9988-4BB5-89C0-93A9E1F894D2', -- CampaignMember.CampaignId
    'EDD76716-B498-49B9-9DF9-E4500EC67F1B', -- CampaignShare.CampaignId
    '81830C21-8F78-475E-A099-0272F713C6BF', -- FlowRecord.AssociatedRecordId
    '2B4CF941-C11B-4707-9F49-AE1A0587B87F', -- ListEmail.CampaignId
    '58EE542B-BC3C-4E74-A2FB-503C73C0ED9B' -- Opportunity.CampaignId
  );

-- Target: CartDeliveryGroup.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'DCFB7BE5-5114-4F16-A7F0-07BD2935347F',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '55CBA555-C82C-4E96-9A33-38A553DE8DD7' -- CartItem.CartDeliveryGroupId
  );

-- Target: CartDeliveryGroupMethod.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'EC777F74-0D4E-45EF-861A-A1932E61CAB1',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'B244E639-7901-4E13-A1D2-4C5304ACA0A5', -- CartDeliveryGroup.SelectedDeliveryMethodId
    '15AFAAB1-289A-4A15-931B-13968944958E' -- CartDeliveryGroupMethodAdj.CartDeliveryGroupMethodId
  );

-- Target: CartItem.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '34C6A4F0-2905-41A1-9674-0227D6F47843',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '39DCE70C-59ED-4BB1-A171-04F8080D9A46', -- CartItemPriceAdjustment.CartItemId
    'E42B959B-F702-4661-9CBE-9E6F49892BBD' -- InventoryItemReservation.ItemReservationSourceId
  );

-- Target: CartItemPriceAdjustment.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'D61B4D31-DAA1-4267-BD48-98E470F9496B',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'ED8254AD-B0B1-4F5C-A4CF-BA5CF2DB8CA0' -- CartTax.CartItemPriceAdjustmentId
  );

-- Target: Case.Id (17 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '775BA90D-BE57-4D3A-99DD-16F2DEDA17F8',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '58020BAB-F22E-4880-8F92-45E399C50F05', -- CaseContactRole.CasesId
    '3607F2A4-4B14-48CE-B940-6B1EFC8164F8', -- CaseHistory.CaseId
    '731FB2C3-0051-4590-BBAE-EEDE7BB18113', -- CaseHistory2.CaseId
    '73CDE8C1-6034-480E-9270-3C602AA3D25B', -- CaseParticipant.CaseId
    '45FF1AB7-DF9B-41F3-97D2-FC573A259DAF', -- CaseRelatedIssue.CaseId
    '888CA837-DAEA-41BC-8222-CE2D80D6A998', -- CaseShare.CaseId
    'E63029BF-72B1-4E40-8FBC-ACDA2C5493BE', -- CaseSolution.CaseId
    '79FC73BD-E5EB-400E-B4D1-2B884D7E87B1', -- CaseTeamMember.ParentId
    'EFA24852-00BA-4ED9-A772-BB51079257F3', -- CaseTeamTemplateRecord.ParentId
    'EAEC01FA-FEFF-481F-A6A5-4880D8D40D02', -- EmailMessage.ParentId
    '8021CB86-F6A3-4A9D-AF98-C64558F3A16E', -- ProcessException.CaseId
    'BE68C84F-4C96-470B-AA66-B7AF14BB0726', -- ProductRequest.CaseId
    '6788FB84-50FE-42F0-9F1F-BDFE7C4F48E3', -- ProductRequestLineItem.CaseId
    '65909ADF-D273-423A-86A7-6BAA3AC73530', -- PublicComplaint.ComplaintCaseId
    '463E154F-4C67-4009-8D29-66FEFCB1A166', -- ReturnOrder.CaseId
    'E77E32EB-863A-477F-B54B-C462C6B9624B', -- SocialPost.ParentId
    'F875C4F5-9804-4B80-858D-096311670787' -- WorkOrder.CaseId
  );

-- Target: CaseTeamRole.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'DB579281-1DF2-4C5E-AC72-D098A92541CA',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '7CB6ED6A-F1CB-47C9-9E59-303300EF3261' -- CaseTeamMember.TeamRoleId
  );

-- Target: CaseTeamTemplate.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'EACE31A8-11ED-4E00-A759-29864187BEEF',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '4BFAA1BD-E0DC-4535-AD58-90BF0831CE20', -- CaseTeamMember.TeamTemplateId
    '33C8FA41-23C7-4294-B128-2A6A47E9B1C5' -- CaseTeamTemplateRecord.TeamTemplateId
  );

-- Target: CaseTeamTemplateMember.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'CD630F13-7CCE-4BA5-91C7-F6A2EA3C2ADE',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '28DF2051-ACF4-40E1-A2F2-B01EC7DB933F' -- CaseTeamMember.TeamTemplateMemberId
  );

-- Target: ChangeRequest.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '74AA86D1-F299-4FC2-80CB-F93150E01230',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '75DF7C7B-F95D-4FCF-9F03-35196C71BE76', -- ChangeRequestRelatedIssue.ChangeRequestId
    '1ED10966-76FA-4D0D-9045-50D98717447E' -- ChangeRequestRelatedItem.ChangeRequestId
  );

-- Target: ChatterExtension.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '14049F51-8370-4223-8F1B-65C09D6397F7',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'C096718D-B2DD-4F25-99AA-C71D05855622' -- ChatterExtensionConfig.ChatterExtensionId
  );

-- Target: CollaborationGroup.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '88169FC1-A417-45FB-8250-3764B35A6B12',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'EBE4CB9B-7C43-4AC3-8068-10A81FCAC7FF', -- Announcement.ParentId
    'E70AC440-055F-450E-859C-57A9A03F0137', -- CollaborationGroupMember.CollaborationGroupId
    '4B75E523-8240-4476-B1EF-4FEBA241829F', -- CollaborationGroupMemberRequest.CollaborationGroupId
    'C35DCFE6-6362-4D80-BA08-A7A0DF3CF28C', -- CollaborationGroupRecord.CollaborationGroupId
    '8E548DA7-FEF5-4E12-BE28-45B20A73CC44' -- LightningOnboardingConfig.CollaborationGroupId
  );

-- Target: CollaborationRoom.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '01C2BFCE-1994-4254-BE5D-C5CC70AF4FBF',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '92C39D77-5602-4B5C-89A9-9AEA8F2DE05A' -- Swarm.CollaborationRoomId
  );

-- Target: CommissionSchedule.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'FC38E494-5899-423E-95D0-5D3B7089B446',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'E2C62632-D493-4CCB-9563-BBBDAEF2FF2B', -- CommissionScheduleAssignment.CommissionScheduleId
    '0A3F6CC3-CCA4-48AC-805C-7653D40C6282' -- ProducerCommission.CommissionScheduleId
  );

-- Target: CommSubscription.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'D5D2254B-23C3-4C78-A43A-A54BF2F889AF',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '584A9AB6-0883-45A4-92AC-9D264B4FC313' -- CommSubscriptionChannelType.CommunicationSubscriptionId
  );

-- Target: CommSubscriptionChannelType.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'AF491724-FF9A-4FE6-B55E-D377CCBC8ADE',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '2AD0352B-0AE8-43C4-8AC0-1C8776AEEDFD' -- CommSubscriptionConsent.CommSubscriptionChannelTypeId
  );

-- Target: CommSubscriptionConsent.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '9033B969-806B-4203-A293-EED728A739D8',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '6DE4EF17-A713-459A-A842-7EBFA14493DD' -- CommSubscriptionTiming.CommSubscriptionConsentId
  );

-- Target: ConnectedApplication.Id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'F33402F0-06EF-497B-911A-8E48787CB995',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'E67F1DF0-414C-4439-AEC0-330004120635', -- OauthTokenExchHandlerApp.ConnectedApplicationId
    'A3358715-E548-440F-A13C-B1F0FB4BF88F', -- UserAppMenuCustomization.ApplicationId
    'D7ABEB6C-BCDC-49F9-A05B-FA0241FAF443', -- UserProvAccount.ConnectedAppId
    '8589D8E0-3949-4BF8-84C4-3EE782E9A06D', -- UserProvAccountStaging.ConnectedAppId
    'F4EFB087-9B7C-4DDC-9C24-AC2521D8A9EF', -- UserProvisioningConfig.ConnectedAppId
    'AB45D40C-7332-4BFD-99D8-BACD0C4D4ACD', -- UserProvisioningRequest.ConnectedAppId
    '19CAFFD6-758D-47CA-8312-D92CD69D0E77' -- VerificationHistory.ResourceId
  );

-- Target: Contact.Id (27 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '9107EEE2-4DAB-441B-A8AD-EB8FBB10F2D7',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '122B9B53-970A-4F20-B2D1-7A63036B3465', -- AccountContactRole.ContactId
    'A12DA375-7D0B-49DB-B07C-599BAFF16666', -- AccountPlanObjective.ExternalStakeholderId
    '622FBD58-0E45-457B-BB74-F859CEB8A525', -- Asset.ContactId
    '20C4EC97-74DC-4D45-B315-D09DDC9D0EBA', -- BillingScheduleGroup.BillToContactId
    '65CF752C-B55D-4326-BD12-FE3C3EA290F4', -- CampaignMember.ContactId
    '6E1D650E-CC69-4AA7-A9CF-99438C4B6B1F', -- Case.ContactId
    '400CDF44-AF97-4230-9530-F724C1FF4FD0', -- CaseContactRole.ContactId
    'EA44A01A-EF0A-4068-97D9-536F33027B0A', -- ContactDailyMetric.ContactId
    'B6896E0D-B26A-42E8-BA82-F7B5A0881696', -- ContactMonthlyMetric.ContactId
    '6472C11C-30A8-4972-BA23-F955B1F2CA06', -- ContactShare.ContactId
    'A6CF50DB-D131-4914-AEA4-F8CEE0EFD59F', -- Contract.CustomerSignedId
    'B61C895A-F60C-47F8-94C4-9C0ADA3EFDB7', -- ContractContactRole.ContactId
    '254082D1-950E-4C77-8A89-7C248523F3DA', -- CreditMemo.BillToContactId
    'B2A4CF2B-A2A5-4F85-8FE6-C7663D331324', -- FulfillmentOrder.BillToContactId
    '7D35C4A2-ECCA-42B8-B9BC-029C87ED0BC4', -- Invoice.BillToContactId
    '90E11C7E-9689-47A6-9C68-995D6D28B180', -- Lead.ConvertedContactId
    '66FBF7BA-0E47-4392-A56F-C8B967B305DB', -- MessagingEndUser.ContactId
    '342DCDFD-03DC-400A-973E-998E190CE289', -- MessagingSession.EndUserContactId
    'A55A2D81-A0A0-4479-B1DB-D0E647A49FD4', -- OpportunityContactRole.ContactId
    '79D743BB-91E3-4058-94CB-B0B8DE19373D', -- Order.CustomerAuthorizedById
    '83381224-3A04-46DF-92EC-97C2719866A4', -- OrderSummary.BillToContactId
    '4B29A9E9-6A6A-43EA-80A6-2A62A5F041F8', -- PaymentInitiationSource.ContactId
    'CE3D4F0B-7AF5-4CDF-9EF8-4F38E772A37D', -- PendingOrderSummary.BillToContactId
    '7806D59F-EEB9-48AC-9560-C175C284BF4D', -- Prospect.ConvertedContactId
    '2A7F6556-CE44-4D68-B5B1-7DBFF73AD254', -- ReturnOrder.ContactId
    '09B41A2F-1BD4-49F0-BCE6-B31F822CF2BE', -- ServiceAppointment.ContactId
    'D2C9F360-FC8F-4232-8E92-E9D23C977A8B' -- WorkOrder.ContactId
  );

-- Target: ContactPointPhone.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '252FED52-1C3C-4C6E-8183-3E80CE560822',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'AD159E2E-7174-4816-A9C5-C9F7403E9CF6' -- ContactPointAddress.ContactPointPhoneId
  );

-- Target: ContactRequest.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '79D6C492-DD27-442B-B23B-E08FAE57C021',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '8074CB46-9975-4093-BA82-A67E56E9AC86' -- ContactRequestShare.ParentId
  );

-- Target: ContentAsset.Id (8 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '56FF55D7-C8BF-4048-AFF3-32CC67116346',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '5FEA6C5D-1F61-4D95-8A2E-DBA021743F0B', -- AnalyticsContainerWidgetDef.BackgroundSourceId
    'C864D41A-9BC3-49CB-8838-8FE18A7C5F43', -- ChatterExtension.IconId
    'E34B4232-D5DF-45A5-86FE-6DE96DDA2F88', -- ContentWorkspace.WorkspaceImageId
    'C008E837-622E-43FC-815A-440DDAE25A86', -- Location.LogoId
    'B9722AE2-DD3F-41D8-AC80-16778242436B', -- PromptVersion.ImageId
    '0BFAB38D-8B84-43A5-BE02-010540AE5760', -- Recommendation.ImageId
    'A8CF09B7-F095-4ADF-9C40-6AF7632F57FD', -- SvcCatalogCategory.ImageId
    'CAA0083A-0893-4D97-8FC9-A68E9B462C7F' -- SvcCatalogItemDef.ImageId
  );

-- Target: ContentBody.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '085ACA5F-E008-45E2-9818-DB1DEF937394',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '8D6E54BE-098C-4B0B-83CA-BA16065BC5EF', -- ContentNote.LatestContentId
    '95C1608F-76CD-41D4-B597-CF7A9E6E7281' -- ContentVersion.ContentBodyId
  );

-- Target: ContentDistribution.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '8615A507-220A-4F13-971A-0CBFD98BF94C',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'D2557064-DD9F-4DCA-BE02-B8894A1E22E6' -- ContentDistributionView.DistributionId
  );

-- Target: ContentDocument.Id (17 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '14A64D93-8C0B-4A4F-A509-5E92495AFB69',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '4986870B-F8A6-452E-A5E7-FF2D71D23176', -- AttachedContentDocument.ContentDocumentId
    '0743266A-99BA-413E-BF01-7C97FD0B842C', -- AuthorizationFormText.ContentDocumentId
    'C46A1CEE-4D85-4C4D-A4EB-4D5547CA5C54', -- ContentAsset.ContentDocumentId
    'FD565926-D37F-47E0-AC3B-B98C0DEFBC7D', -- ContentDocumentHistory.ContentDocumentId
    'F6328812-AE0C-4EAC-A555-8DB6EA88B7A8', -- ContentDocumentLink.ContentDocumentId
    'F00DDBEF-2384-45DE-93F4-335D62530E8C', -- ContentDocumentSubscription.ContentDocumentId
    '81B1D306-7FD5-45E2-8000-DAF9078C1BF5', -- ContentFolderMember.ChildRecordId
    'E39C78F6-E451-42D8-9084-98729A859765', -- ContentVersion.ContentDocumentId
    '64CE20C0-E6BB-4006-9C47-4645E63A83C7', -- ContentVersionComment.ContentDocumentId
    'BBD3336B-BDBE-4988-980B-59ABC0798CE7', -- ContentWorkspaceDoc.ContentDocumentId
    '813378D4-E2E4-4FA5-A73B-2E21E8EBF90D', -- FolderedContentDocument.ContentDocumentId
    'A9408D93-3A87-4E95-8466-9B002E344F8B', -- Image.ContentDocumentId
    '1E28E637-C042-40F3-BA9C-953A5A6CD792', -- InvoiceDocument.ContentDocumentId
    'B4C3AE8F-2CE1-4539-AE16-57B70089AD36', -- OutgoingEmail.ContentDocumentId
    'B305F841-B856-4E4E-B0E9-BD260FFEFAD7', -- OutgoingEmailRelation.ContentDocumentId
    '695D22D1-278A-40A2-B8A7-523959A66BFB', -- OwnedContentDocument.ContentDocumentId
    '7A9BDAE9-B34B-4BF8-B748-4B2DEA392823' -- VoiceCallRecording.MediaContentId
  );

-- Target: ContentFolder.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '4AC3EA9F-3ABF-4517-8F2C-C70DFB1DB354',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '1FC846B4-180C-4B26-8608-7EAB6E1BC5BD', -- ContentFolderItem.ParentContentFolderId
    'B150679F-D3E3-44DC-8EB0-9F0BE0F13F30', -- ContentFolderLink.ContentFolderId
    '24A32037-DED6-4D68-8B78-42FA31EBB56E', -- ContentFolderMember.ParentContentFolderId
    'DA78ACA5-0C2D-44E5-8A0F-4AB8C8FBFCA4' -- FolderedContentDocument.ParentContentFolderId
  );

-- Target: ContentVersion.Id (6 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '254A0C9D-A060-42F1-B208-AAA684B0D25C',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'EC1CE755-1A65-4174-BD90-FBF59D552928', -- AuthorizationFormConsent.DocumentVersionId
    '8D34439B-5C03-47C6-83EB-6DEFD03E3AA8', -- ContentDistribution.ContentVersionId
    '8B241357-4963-4BDF-9807-E91B4E00CEA3', -- ContentVersionComment.ContentVersionId
    'E39EAAE0-2057-4CF8-B3D0-FB2972C46EF0', -- ContentVersionHistory.ContentVersionId
    'C21F283B-B272-47BB-98D3-4A81D99E1823', -- ContentVersionRating.ContentVersionId
    'CD7F93ED-284D-476D-A6B4-ABC8EF3E9B8C' -- PaymentLink.QrCodeImageId
  );

-- Target: ContentWorkspace.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '995905C1-6369-4EC3-915D-B87563C6BCBF',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '4C8908A6-04DA-4AE5-967E-143DAB68BFBA', -- ContentWorkspaceDoc.ContentWorkspaceId
    '19C2310A-7B76-458F-952C-2CC34BBACDF3', -- ContentWorkspaceMember.ContentWorkspaceId
    '648D9745-8550-45B7-9906-01E998F0973E' -- ContentWorkspaceSubscription.ContentWorkspaceId
  );

-- Target: ContentWorkspacePermission.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '559617C2-8F00-4F53-8599-5353B7DBFD39',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '0769E79D-6C71-4864-B23A-D0B6FE017D88' -- ContentWorkspaceMember.ContentWorkspacePermissionId
  );

-- Target: Contract.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'F62E773F-D2DF-4CBD-97EA-C7BAC427ECE8',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '78B47246-4D53-48F4-9B9B-FDA0650BD3EF', -- AssetContractRelationship.ContractId
    '3F3B3AC0-9C39-4892-835A-9C7409C70C26', -- ContractContactRole.ContractId
    '3EEFDE3F-0A88-44CE-B8D6-202155B9C6AF', -- Opportunity.ContractId
    '26802C9D-B2A3-46A2-9135-090D00E910ED', -- Order.ContractId
    '0DA9A1FF-A04A-4CD6-A401-482BA6B5DBF8' -- QuoteLineItem.PricingContractId
  );

-- Target: ContractLineItem.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '3D8F357E-D0CE-471E-B706-54CA1EDB414D',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '8C1F2910-5712-4290-A1A9-9024A1C9C470' -- ContractLineOutcome.ContractLineItemId
  );

-- Target: ContractLineOutcome.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '237B6299-C962-4403-B6CF-4FC2FD6FD81B',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '43C4A7EB-E6D8-4010-A4C2-077877AC27E1' -- ContractLineOutcomeData.ContractLineOutcomeId
  );

-- Target: Conversation.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'B61B5509-CFD0-4574-9243-3C1E8EEA58BA',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '389822F8-BDDE-4CBB-A952-C7B1947D43FB', -- MessagingSession.ConversationId
    'DAB206B0-FAD0-4C96-B941-F3BD43841467' -- VoiceCall.ConversationId
  );

-- Target: ConversationChannelDefinition.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'CE33334A-E838-4E3B-ABBA-4929FA38989E',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '52FA9491-2621-40DD-A48E-CBD8D518373E', -- CustomMsgChannel.ChannelDefinitionId
    'BA6A0294-A744-4230-8F21-9001701F2440' -- MessagingChannel.ChannelDefinitionId
  );

-- Target: ConversationParticipant.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'BCF37E5A-E998-4FAB-845B-714C08D49BC9',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '47C18872-5A5C-468D-A00A-574B14B34A26' -- VoiceCall.RecipientId
  );

-- Target: ConversationVendorInfo.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '8FAE30D3-D2FF-4F75-ADC2-F253A6565E1F',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '9F4925BD-1974-4D31-ACD9-501E3462F270' -- ConversationChannelDefinition.ConversationVendorInfoId
  );

-- Target: Coupon.Id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '3973C543-E8C2-450E-AAD5-09C404CF0381',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '61BA26A2-3911-47AA-AA0A-BBA9C5E2D983', -- CartDeliveryGroupMethodAdj.AdjustmentBasisReferenceId
    '96B82C16-C878-40E5-8BF1-F4DD74EDE0AF', -- CouponCodeRedemption.CouponId
    '8E00090E-22D3-4803-9DAF-AF7BFB27B43E', -- OrderAdjustmentGroup.AdjustmentBasisReferenceId
    'AF97FBC9-0A93-4785-B854-EFDF72E95F2E', -- OrderAdjustmentGroupSummary.AdjustmentBasisReferenceId
    '0CD6E91C-BE7E-469E-87E2-43B3E9C16854', -- OrderItemAdjustmentLineItem.AdjustmentBasisReferenceId
    '046F5F88-3492-4A6B-BC72-DAE5EB1A7AA8', -- OrderItemAdjustmentLineSummary.AdjustmentBasisReferenceId
    'CF01BFB4-A336-429E-A9E4-859D25AF114B' -- WebCartAdjustmentBasis.AdjustmentBasisReferenceId
  );

-- Target: CreditMemo.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '4755CF3D-1E30-4749-B2CA-2765203CFA94',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '62D79622-09FC-4019-B5E3-88CB189FE0EF', -- CreditMemoAddressGroup.CreditMemoId
    '27BA9967-D1A4-4519-B405-CB555648D4CD', -- CreditMemoInvApplication.CreditMemoId
    '55BD05CB-1ED5-45A7-BEBD-DBE4CD2C7545', -- CreditMemoLine.CreditMemoId
    'AA5DDEDC-E7DB-4825-BEC9-AFAC2466377A' -- PaymentCredit.CreditMemoId
  );

-- Target: CreditMemoAddressGroup.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '292DA008-3419-445C-B342-3D7EB959DEF1',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '485FBC3F-74EC-4798-88BA-B5CC8E86BF00', -- CreditMemoLine.BillingAddressId
    '64019C64-E612-4A9A-946B-A611CF132E05' -- CreditMemoLine.ShippingAddressId
  );

-- Target: CronJobDetail.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'AD67141A-7733-4D2E-871C-E68F94DE9475',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '386E9DC9-FBAF-4D9A-B5F4-1ED629B5A434' -- CronTrigger.CronJobDetailId
  );

-- Target: CronTrigger.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'E4146504-9889-4697-942C-D0373D1BEDB9',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '854C50F4-7BB2-485A-B2C9-D04DF3405E45' -- AsyncApexJob.CronTriggerId
  );

-- Target: CustomBrand.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '001C0F6C-4F02-4F3D-8D6F-31FE887549C1',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'AAECF9DA-59C1-47A4-92AB-37605BFA4926' -- CustomBrandAsset.CustomBrandId
  );

-- Target: CustomHelpMenuSection.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '81819451-0E31-47F0-80FE-0797A7EC99C2',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '9CE80044-B5C1-4D38-AD66-0C2872F3324F' -- CustomHelpMenuItem.ParentId
  );

-- Target: CustomNotificationType.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'BE5131AD-E5AC-4847-8F2F-3C0D5898EAC5',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'EA2D6DD4-27C6-41CB-A87D-DD44488E18E7' -- BroadcastCommunication.CustomNotificationTypeId
  );

-- Target: CustomPermission.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '55004891-D63F-4859-A90F-9022127BDE62',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'DAC697A9-14F8-4D13-8667-D1C43EF0AD56', -- CustomPermissionDependency.CustomPermissionId
    '0B8D355D-50CF-4D74-A231-29139CB1FB73' -- CustomPermissionDependency.RequiredCustomPermissionId
  );

-- Target: Dashboard.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'F68764E8-1068-41F9-BCDD-0228677DA739',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'B446796B-6436-41C3-B9FC-2582BF55497C' -- DashboardComponent.DashboardId
  );

-- Target: DataAssessmentFieldMetric.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '6D8E6E2A-CFC8-4A06-A5C4-D510D9621116',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '416D43CC-FFDD-4827-B605-CD0D8DC001F3' -- DataAssessmentValueMetric.DataAssessmentFieldMetricId
  );

-- Target: DataAssessmentMetric.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'EBB30B22-9D85-4FAF-AB36-9F1D794626E5',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'B78AD724-9A98-4D03-ACD5-50F31D979CCB' -- DataAssessmentFieldMetric.DataAssessmentMetricId
  );

-- Target: DataDetectJobSession.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '636D3E08-320B-4785-AA9F-38E7DA5F941C',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '035CBE38-7C50-47D5-A9F4-E1B0537CAD8F' -- DataDetectScanResult.DataDetectJobSessionId
  );

-- Target: DataDetectPolicy.Id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '26549617-28E8-4C7F-BABD-895A7B43E546',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'C4F194B0-1DCD-43B9-A8D6-22CD5728DCAC', -- DataDetectJobObjectSession.DataDetectPolicyId
    '4893572A-ACFA-444C-BC51-03CE9EB2F9AA', -- DataDetectJobSession.DataDetectPolicyId
    'C69E780D-349A-4015-9CA0-C88AB019697F', -- DataDetectPolicyObject.DataDetectPolicyId
    '22982A08-F07B-4295-A2BE-95CC87D08B75', -- DataDetectPolicySnapshot.DataDetectPolicyId
    '324A4336-83AE-4053-BCEF-A2E926DB1807', -- DataDetPlcyDataSrchExps.DataDetectPolicyId
    '12568E19-77AF-47A0-8284-EB66FCC52E78', -- DataDetPlcyMdatScanCrit.DataDetectPolicyId
    '689D076A-2A33-4C6A-B6BE-3C9D6E8ADD99' -- DataDetPlcySstvDataCatg.DataDetectPolicyId
  );

-- Target: DataDetectPolicyObject.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '41563C94-1F75-4C53-82A6-C1B8B6A902E5',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'B3BE8B2D-EB7B-4A92-B641-0C5F296ECBCF' -- DataDetectPolicyObjField.DataDetectPolicyObjectId
  );

-- Target: DataDetectPolicySnapshot.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'C0A3CD99-91EB-49C0-96E6-F8F008A025BF',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '6C5CC751-8CCB-4DD7-AFBB-FF56BE31319D', -- DataDetectJobObjectSession.DataDetectPolicySnapshotId
    '36F612DB-E907-4625-B7CC-1931AE062758' -- DataDetectJobSession.DataDetectPolicySnapshotId
  );

-- Target: DataUseLegalBasis.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'C78ED193-6FF2-4C5F-9C89-964E9CC01C9E',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'E5B388EB-BFF3-432A-BA25-37EE31CC8F0D' -- DataUsePurpose.LegalBasisId
  );

-- Target: DataUsePurpose.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '6719FAF9-6869-4028-BB1C-307ED6803648',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '7EB68DD5-CF28-4917-99E5-96E5686C844C', -- AuthorizationFormDataUse.DataUsePurposeId
    'CFA9CBE2-5271-4230-8522-28BDB2EE3986', -- CommSubscriptionConsent.DataUsePurposeId
    '7AA4FC22-7AC7-4A7D-9B94-93C932D918EF', -- ContactPointConsent.DataUsePurposeId
    'F0BDF25D-3ED9-4878-999F-FBBE6FBF1BCC' -- ContactPointTypeConsent.DataUsePurposeId
  );

-- Target: DevopsEnvironment.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'E5B14108-1521-4E1E-B312-8C2402299F05',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '92EE021C-9D64-4C16-B428-855979C5049E', -- DevopsPipelineEnvironment.DevopsEnvironmentId
    '9A979BB9-BD03-4562-89BA-23220DA7A7BE', -- DevopsPipelineStage.DevOpsEnvironmentId
    '6B87A1CE-C743-4CB0-BF3B-FD4E47E8AABC' -- WorkItem.DevelopmentEnvironmentId
  );

-- Target: DevopsPipeline.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '335CDE0D-9BB5-4EEA-BBD7-8158273FC23A',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '932AB3C2-6CEF-4BDC-B6A0-86FDDBF01D18', -- DevopsActivityLog.PipelineId
    '1D503559-EC22-4F78-A67E-A1636414B084' -- DevopsProjectPipeline.DevopsPipelineId
  );

-- Target: DevopsPipelineStage.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '558B710F-ACE8-4BF7-A2DA-AE0E469E1F0E',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '890AE3AC-344E-4497-BA55-191E4A5427FD', -- DevopsActivityLog.PipelineStageId
    '4A68B137-6E67-4C03-A53A-FC11C2273B48' -- WorkItem.DevopsPipelineStageId
  );

-- Target: DevopsProject.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'DFB85FA1-509C-461F-8DFB-2D9F5B7EA8B2',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'C5F2D4D1-4151-4812-B186-7B74BD21F4C2', -- DevopsActivityLog.ProjectId
    '1401CE3C-D11B-4F65-8A70-30B64BF3043B' -- WorkItem.DevopsProjectId
  );

-- Target: DevopsRequestInfo.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '1BC21096-2461-40D8-AD79-8B09D8BBADE6',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'CD4E18D8-5658-4799-AAF1-CC865D4D0B6D', -- DevopsActivityLog.DevopsRequestInfoId
    'D19585D6-4378-4EDB-A0E0-7C0F012559B2', -- DevopsPipelnStgProm.RequestInfoId
    '197EE189-3869-47D4-A207-22E21BE0698C' -- WorkItem.RebaseStatusId
  );

-- Target: DigitalSignature.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'D6B82175-E109-43D6-9881-C70CD4BE98B2',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'EA2FCF44-5A49-476C-836D-32C063ADBA17' -- DocumentRecipient.DigitalSignatureId
  );

-- Target: Domain.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'BDC3AA29-441E-485E-8E4A-91B1428A4E22',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'F24810E6-94C9-400B-98C2-55A4B1EFB589' -- DomainSite.DomainId
  );

-- Target: DuplicateRecordSet.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '9F8C9FBD-B898-409C-9D51-2C4BBDDE8581',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '3459A122-9FD7-4B38-B89B-1B6534BCFDC1' -- DuplicateRecordItem.DuplicateRecordSetId
  );

-- Target: DuplicateRule.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '9F936B2C-C754-473B-8611-37D3045BE723',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'E5645AF3-0D97-40AE-A279-117061F4277E' -- DuplicateRecordSet.DuplicateRuleId
  );

-- Target: ElectronicMediaGroup.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '3DC628F6-6D55-44FE-8E74-91AFF1AFBA27',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '9B593523-DB86-47FB-88BB-BC99435EE7EA' -- ProductMedia.ElectronicMediaGroupId
  );

-- Target: EmailDomainKey.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'FA71B527-CFFD-41B8-B86F-C5EAEC68F07C',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'B0CAC496-DCAC-44F3-82DD-7FBDA95B9E3C' -- SenderEmailAddress.EmailDomainKeyId
  );

-- Target: EmailInsight.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'A9C0C1BA-CA25-408C-8D43-9A5C83A6E977',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '92438C3F-E652-41B5-B300-768BF56D836D' -- EmailInsightAction.EmailInsightId
  );

-- Target: EmailMessage.Id (6 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'F7F36EFC-7724-4048-BE63-63F61B7E5D6B',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '3D0D4857-5035-42F8-A8AD-98D19DF0012D', -- ActivityHistory.AlternateDetailId
    '7179F9CC-C547-42C0-BF86-3D4485890337', -- EmailInsight.EmailMessageId
    'BE21CF1E-8FED-4CB0-BBDC-5A2F03869A70', -- EmailMessageMigration.EmailMessageId
    '614DBA40-6CB7-4737-8F8B-F67FB65F74DF', -- EmailMessageRelation.EmailMessageId
    '7D37F479-D13D-44B3-ACC1-B8C52A382C29', -- OpenActivity.AlternateDetailId
    '74AB6BF3-500E-48EE-B250-31DD48BBC1B3' -- UnifiedEmail.DetailId
  );

-- Target: EmailRelay.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'FA268E12-016C-48E6-835D-7702EFCE044A',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '22A779B0-9956-4F60-B672-EB5A4684C17F' -- EmailDomainFilter.EmailRelayId
  );

-- Target: EmailRoutingAddress.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '6033942F-DBBA-4026-88D8-BD5ECF68F247',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'D2396B2A-8F61-4232-8845-B98CA0A9EF62' -- EmailMessage.EmailRoutingAddressId
  );

-- Target: EmailServicesFunction.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'D28564A0-2EA1-4495-9570-95A164D65177',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'F7354E5F-3F84-4ECF-9EE5-AF6CCCBD2B2A' -- EmailServicesAddress.FunctionId
  );

-- Target: EmailTemplate.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '18A5C328-0905-4082-9CDC-401AED84FCAC',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'A89639CD-DD2D-4190-B526-FD718ADF94F9', -- ApprovalAlertContentDef.EmailTemplateId
    '2762E5B4-96FE-458E-94E4-369DF6765408', -- EmailMessage.EmailTemplateId
    '530981E2-C673-4AAB-B5F2-28141137AA79', -- EmailTemplateMonthlyMetric.EmailTemplateId
    'DDD076B8-FBBD-4F99-BE17-007B6D597493' -- NetworkEmailTmplAllowlist.EmailTemplateId
  );

-- Target: Employee.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'EB977D55-2AF9-43DF-8D4C-7A4044C95783',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'EAA00FF8-C4F7-4AC9-89EB-B6E132CA7377' -- EmpUserProvisionProcessErr.EmployeeId
  );

-- Target: EmpUserProvisioningProcess.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '00F62070-FA60-44A7-8871-B64241972BF5',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '1C66D6CF-892E-4478-A850-F70C1175A7F0' -- EmpUserProvisionProcessErr.ProvisioningProcessId
  );

-- Target: EnablementMeasureDefinition.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'A9D38504-450B-43A8-8454-11C58E2723BC',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '9A7D7FC3-5E61-4E05-BA9F-8BBD3673969B', -- EnblMeasureObjectDefinition.EnablementMeasureDefinitionId
    'CD79DBD6-6621-4F1F-ADFF-5086D610C088' -- EnblProgramTaskMeasure.EnablementMeasureDefinitionId
  );

-- Target: EnablementProgram.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'E5090787-2B8D-4EE4-B10F-700605618380',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '21754123-6D7A-47DE-AFC9-8A2C8EC617B8', -- EnablementProgramDefinition.EnablementProgramId
    '175889F8-57E5-4D30-B0F2-464E5AF1EA22', -- EnblProgramSection.EnablementProgramId
    'CACF5772-7C30-42D4-A8E6-43FF0C029C2E', -- EnblProgramTaskDefinition.EnablementProgramId
    '389FB9F1-9043-46B2-AD1D-B159C5697318' -- LearningItem.EnablementProgramId
  );

-- Target: EnblProgramSection.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'FEFD8A65-5236-4A6B-9C60-B8624482A217',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '8571EE39-A6B5-44C6-A2CA-2C266FDF036A' -- EnblProgramTaskDefinition.EnblProgramSectionId
  );

-- Target: EnblProgramTaskDefinition.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '906FCA61-561B-4963-9C28-6BFF5E5CC02B',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '50DDA266-B706-4B2D-AE9E-9A5ACEE5FFFE' -- EnblProgramTaskProgress.EnblProgramTaskDefinitionId
  );

-- Target: EnblProgramTaskMeasure.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '2E66388A-A86E-406F-B2A2-91902E7C6919',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '3C66D515-C879-409A-86E4-E27E16B8A282' -- EnblPgmTaskMeasureProgress.EnblProgramTaskMeasureId
  );

-- Target: EnblProgramTaskSubCategory.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '236B860A-5814-4DA4-BA25-A4D72062D39C',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '835F819B-57EF-4351-80B1-D1645BEF5A5A' -- EnblProgramTaskDefinition.CustomEnblPgmTaskSubCategoryId
  );

-- Target: EngagementChannelType.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '0ACB544F-85D7-4B3C-A539-D2DF01834881',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '6E6DF06D-134D-4002-8967-EDAA3C8F52D9', -- CommSubscriptionChannelType.EngagementChannelTypeId
    '9671CD44-34DE-4D3C-889D-41599D5EFB13' -- CommSubscriptionConsent.EngagementChannelTypeId
  );

-- Target: EngagementSignalMetric.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '899ABEC4-97E2-4010-A4FB-9A69E661A350',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '580250B3-AC71-451D-AB4F-B1AD204939EA', -- AttribModelStageMetric.EngagementSignalMetricId
    '9DFB4687-78C0-479A-9C0F-C9A3318B3B26', -- EngagementSignalCmpndMetric.DenomEngmtSignalMetricId
    '0D3BE3DD-F954-4E6D-AF38-6EC27C8EBE5E' -- EngagementSignalCmpndMetric.NumerEngmtSignalMetricId
  );

-- Target: EnhancedLetterhead.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '0F07BE83-3C7B-48C2-9B8C-8AAB47040231',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '00787EDD-6CA3-4EB2-92E1-E7F44850FDD1' -- EmailTemplate.EnhancedLetterheadId
  );

-- Target: Event.Id (8 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '1CEBA587-7B22-420A-AF0C-7D0AEFC7A33D',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '0DF8DEF7-6148-457C-98D7-4E56D31A3B4E', -- AcceptedEventRelation.EventId
    'B86A55B5-BF18-4C5C-BB3E-272CA6A5BCCB', -- DeclinedEventRelation.EventId
    'FD498835-F197-4DF0-85E4-EDEF08D3787B', -- EventRelation.EventId
    'C30D91FE-398C-4340-96F2-35BA0E3E7E56', -- EventStagedInviteeEmail.EventId
    '17DBF779-23BA-46E2-9882-DC209585FF07', -- ExternalEventMapping.EventId
    '9CF715F4-0606-46FD-BBF2-E20BBB32EE52', -- UndecidedEventRelation.EventId
    '13836082-788C-4164-BC79-9FAE401571D6', -- UnifiedMeeting.DetailId
    'BD56BEB5-FB38-47A3-91C3-1940B1F72A0C' -- VideoCall.EventId
  );

-- Target: EventRelayConfig.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '594F9FB1-3092-45D0-A9B7-5174DA3A3779',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '56FC0EBB-4154-4EFB-8E32-6CCF09173332' -- EventRelayFeedback.EventRelayConfigId
  );

-- Target: ExternalClientApplication.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '01881BA7-6596-4E25-8E22-19FA76523223',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'FF60DF1A-4243-4598-9E23-CC9D4DF1C323' -- ExtlRecShrCnct.ExternalClientApplicationId
  );

-- Target: ExternalDataSource.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'B2059367-ECAD-4D52-999C-41FA1153EAC4',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '3F4DBF63-28D3-4474-943A-A21E2596C6FB' -- ContentVersion.ExternalDataSourceId
  );

-- Target: ExternalEvent.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '850BB69E-292F-412F-A242-42B3F0D1B27C',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'A33EC6A7-BE62-4C14-9A14-73CD0692B794' -- ConferenceNumber.ExternalEventId
  );

-- Target: ExternalSocialAccount.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '57830CEE-6801-49C5-8AEF-2DA9D8BD9FFB',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '13E1DCDB-38DA-43F4-8A4F-7505A897624C' -- SocialPost.OutboundSocialAccountId
  );

-- Target: ExtlRecShrCnct.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '9740F7DD-EDB1-40BD-B0A5-6DA56B6E7188',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '5E96F253-B975-4A9E-A26F-0C3F8B989B5E', -- ExtlRecShrCnctAccnt.ExtlRecShrCnctId
    'A11190D6-A835-435E-800E-1D82EE8F4031', -- ExtlRecShrLead.ExtlRecShrCnctId
    '839A2751-E6B8-4877-844D-F7110EA54A09', -- ExtlRecShrObject.ExtlRecShrCnctId
    '54F51E5C-CB99-48BB-AAA1-71C93E4B3988', -- ExtlRecShrOpportunity.ExtlRecShrCnctId
    'A480662B-1283-4409-8CD2-0CAB12A098F8' -- ExtlRecShrRecordMap.ExtlRecShrCnctId
  );

-- Target: ExtlRecShrField.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'C59DC4B2-D0E1-40C6-AB5E-39000BD87058',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '0D48EBDC-2221-4CD1-9A8B-EB6293F53552', -- ExtlRecShrFieldMap.ImportedFieldId
    'DF16BFDC-75BD-453C-9470-058C382A61E7', -- ExtlRecShrFieldMap.InternalFieldId
    '698B0B1E-89D8-4BFF-B94C-E6968C7FC7C5' -- ExtlRecShrPcklstOptn.ExtlRecShrFieldId
  );

-- Target: ExtlRecShrObject.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '1FF1D3A4-F2BF-4063-BD6F-1BD5F5E3F785',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'B92CF0E0-80BB-41A7-B7EA-9689352D9106' -- ExtlRecShrField.ExtlRecShrObjectId
  );

-- Target: ExtlRecShrPcklstOptn.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '193B7263-DA87-4EDD-9890-1C34B1F7C29C',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '21184965-DB4B-4564-81A3-A5E8A910A968', -- ExtlRecShrPicklistMap.ImportedPcklstOptionId
    'A8B1451C-1553-4480-BA0D-0DCB17030A7B' -- ExtlRecShrPicklistMap.InternalPcklstOptionId
  );

-- Target: FeedComment.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '9C3522E2-987D-41C8-AB81-4DC17A92F144',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '1904E08D-93E7-49CE-978B-FB9C521C4110' -- FeedItem.BestCommentId
  );

-- Target: FeedItem.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'D550CADF-37C1-4F86-AB1F-88433B359C54',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '1865F1A7-D7DD-417C-AFF6-59C2FF279103', -- Announcement.FeedItemId
    '589EBF09-75AE-4E28-9C95-1F5ABC300363' -- WorkThanks.FeedItemId
  );

-- Target: FeedPollChoice.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'E78D07A2-EA62-4049-81B3-F49F9014CAC8',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '99C30AB3-EA5B-48EC-ACDE-C8CACEF46B7A' -- FeedPollVote.ChoiceId
  );

-- Target: FiscalYearSettings.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'D95838DE-A1C9-4600-93DB-751C5C35B8D3',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '0FC5543D-3DB9-4116-AC3B-9CF8C9F6CAFF' -- Period.FiscalYearSettingsId
  );

-- Target: FldSvcObjChg.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'E4119B60-E926-46A3-A5EC-0BD571A3622E',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '9E8EBD6A-EE0C-48CA-91C5-7237CEE58578' -- FldSvcObjChgDtl.FldSvcObjChgId
  );

-- Target: FlowInterview.Id (6 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '4471D6BA-23EE-4EB7-B9DB-2BE1502F4E64',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '57F3B331-A7FE-442D-9298-3D2AEDF0D324', -- DynamicDataCapture.PausedFlowInterviewId
    'A89FA503-0958-4B6F-B2B7-EA2A1E4D889C', -- FlowInterviewShare.ParentId
    'A906A969-FB95-4864-BEF6-F195B7881185', -- FlowOrchestrationInstance.InterviewId
    'A80BDA9C-86B6-4FFE-9708-6459E5E013F2', -- FlowRecordRelation.ParentId
    '793764E2-D850-4E7F-ACAD-34B2BF0EDF18', -- FlowStageRelation.ParentId
    'ACA0A95F-3527-44E1-A59B-5B1AFDD66259' -- RecordAction.FlowInterviewId
  );

-- Target: FlowInterviewLog.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'A5FCAE42-F4D4-4DAC-B1A0-0846FE87902C',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'E7E76186-5B75-4464-9223-DC9C5539AA1E' -- FlowInterviewLogEntry.FlowInterviewLogId
  );

-- Target: FlowOrchestration.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '7E5FC888-3818-4F84-A753-A19F19B5411A',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '573B5829-7705-407A-8DC8-9F63C7563A64', -- FlowOrchestrationVersion.FlowOrchestrationId
    '5E7363A8-EE9D-45FA-9B73-C9F0D9B1EB4D', -- FlowOrchestrationVersion.OverriddenById
    'EF30948E-FF0B-4DEE-8E2F-94AEDB6BDF1B', -- FlowOrchestrationVersion.OverriddenOrchestrationId
    'FFACB61E-685F-479A-9173-A2AB3BA3E883' -- FlowOrchestrationVersion.SourceTemplateId
  );

-- Target: FlowOrchestrationInstance.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '8E9CEFCD-FF98-4C5D-9487-C4E1F8A2E505',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '0A69FECA-2989-4CE6-81AB-6A3475C996C5', -- ApprovalSubmission.FlowOrchestrationInstanceId
    '11D1BA88-881F-4D85-B162-F379D48E5E9C', -- FlowOrchestrationLog.OrchestationInstanceId
    'C21A2DB5-956C-469E-8B5E-00AC4C554240', -- FlowOrchestrationStageInstance.OrchestrationInstanceId
    '943C3DF6-AC47-4C50-9087-B53FFBD57884' -- FlowOrchestrationStepInstance.OrchestrationInstanceId
  );

-- Target: FlowOrchestrationStageInstance.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '99C3ED20-BC7E-4683-B1C5-74E57FA413FC',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '67020B10-20ED-4A53-B19C-6408830C7315' -- FlowOrchestrationStepInstance.StageInstanceId
  );

-- Target: FlowOrchestrationStepInstance.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '2FFACB0A-FE6A-48FE-AAC8-FE533CC68E9D',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'F651BE53-1B35-406D-A92E-2F1EE927DE6A' -- FlowOrchestrationWorkItem.StepInstanceId
  );

-- Target: FlowOrchestrationWorkItem.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'A6297350-C7A2-4ABB-9156-7C6EE496351F',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '2332650D-E52D-4099-8708-9E4AAE82E70D' -- ApprovalWorkItem.FlowOrchestrationWorkItemId
  );

-- Target: FlowRecord.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '57974458-ABE3-4707-8EA1-6C886A3508CB',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'F96CFC9A-E347-4F39-9EFC-F02F4CC6B51A', -- FlowRecordElementOccurrence.FlowRecordId
    'E5B89E9C-ED51-4661-8779-B6B2DD0EFF39', -- FlowRecordVersion.FlowRecordId
    'D5BD4A3E-CA27-4421-92B6-654661EA36F8', -- FlowRecordVersion.OverriddenById
    '9CBC830A-6284-4F2C-ABD2-DDA35F51D1D7' -- FlowRecordVersion.SourceTemplateId
  );

-- Target: FlowRecordElement.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '3B5A2AA8-391E-4F80-AAF3-5A1B894DD5BF',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '66356D0E-DB59-483A-83D9-99AE5D77181E' -- FlowRecordElementOccurrence.FlowRecordElementId
  );

-- Target: FlowRecordVersion.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'C29B535D-56A5-453B-9DA5-15CD65BF1156',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '4BD08897-7879-4180-A934-4E8B2A6DFA98' -- FlowRecordElementOccurrence.FlowRecordVersionId
  );

-- Target: Folder.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'BA22FF32-5C88-4492-9AAA-F055B75CE42C',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '17FC664E-404D-4839-91FB-997491CB5528', -- QuickText.FolderId
    'E13FA914-C20E-4C9A-A152-CB48F96A2E1A', -- QuickTextUsage.FolderId
    '5339D23F-92F2-4D62-88E1-BD1B762ADCC8' -- WaveAutoInstallRequest.FolderId
  );

-- Target: ForecastingColumnDefinition.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '237A1070-C13B-4C5C-83EA-62FBF8B3E731',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '4607080A-C791-4EE4-8283-7B784203F865' -- ForecastingColumnDefinitionLocalization.ParentId
  );

-- Target: ForecastingCustomCategory.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '8315C1B1-5E76-456D-ACCF-73B2D0804836',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '00B1DFD3-637A-4735-8A08-8432D8CF995A', -- FrcstCustmCatgRampRateSrc.ForecastingCustomCategoryId
    'CAE2D71F-B3D4-46F2-88C4-BBDA368FF7FE', -- FrcstCustmzAdjustment.ForecastingCustomCategoryId
    '4E63676B-CC52-4754-B9A2-7CC60209CF97' -- FrcstCustmzOwnerAdjustment.ForecastingCustomCategoryId
  );

-- Target: ForecastingFilter.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '26543AE4-95EC-4F23-A833-5C1C2B7AE0B9',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '9C999CF3-B6AF-4408-AA78-028CFEB659BE' -- ForecastingFilterCondition.ForecastingFilterId
  );

-- Target: ForecastingGroup.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'D540EC59-F504-440A-B959-8178DBAA232C',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '1ABC71B9-393D-49C0-B845-9E1F56657932' -- ForecastingGroupItem.ForecastingGroupId
  );

-- Target: ForecastingGroupItem.Id (6 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'ACC792F1-DD66-43D4-9565-9B363469D93B',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '58AB65C4-B4C7-4FBB-988D-DA4936497518', -- ForecastingAdjustment.ForecastingGroupItemId
    '4BF908DE-1E51-471B-9BFA-F639240EC305', -- ForecastingCustomData.ForecastingGroupItemId
    'D88FF29E-BFD6-4493-B422-9C491799F583', -- ForecastingItem.ForecastingGroupItemId
    'BC5E4263-0DD3-4CFA-A062-4D3D0F439EE4', -- ForecastingOwnerAdjustment.ForecastingGroupItemId
    'E7747918-51A0-4DDA-B7E7-44AB1D8B4556', -- ForecastingQuota.ForecastingGroupItemId
    '6E1F6EE3-9BFE-4F20-94DB-38FE4D118955' -- ForecastingSubmission.ForecastingGroupItemId
  );

-- Target: ForecastingSourceDefinition.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '111A9C58-BD92-45FB-81FB-EBB94D66BA1A',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '6F350C70-5E37-4ED5-9282-5CF917CB3F49', -- ForecastingCustomCategory.ForecastingSourceDefinitionId
    '9AF393F7-1C6E-487F-8609-6EBCAB848C8F', -- ForecastingTypeSource.ForecastingSourceDefinitionId
    '6990EF5E-3EF7-47F8-B1BE-B350908C7A0C', -- ForecastingTypeSource.ParentSourceDefinitionId
    'CD567DC0-A8A7-42B1-B3AC-BC617C032782' -- FrcstCustmCatgRampRateSrc.BaseValueFrcstSrcDefinitionId
  );

-- Target: ForecastingType.Id (9 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '3B405234-957C-4F21-AA30-51B4BBCD44BD',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '4A5F8DA4-BBB3-43DC-AE80-DB49136F1461', -- ForecastingColumnDefinition.ForecastingTypeId
    'DAD874DA-103A-4BCE-A8E3-1818ED1B9CC6', -- ForecastingCustomCategory.ForecastingTypeId
    '91575E60-D9DC-4D96-94B9-DEF4445706A8', -- ForecastingCustomData.ForecastingTypeId
    '4BA8C719-0544-46F2-B490-2482A0C208E2', -- ForecastingFilter.ForecastingTypeId
    '2E3A68C2-5DB5-4AD4-9DB1-FC6024298F59', -- ForecastingGroup.ForecastingTypeId
    'E2280EE4-8152-45FE-9432-57FF48B6B56B', -- ForecastingSubmission.ForecastingTypeId
    'CFAD9012-6EF3-48C7-9A9E-4FD6404872CC', -- ForecastingTypeSource.ForecastingTypeId
    '3054BC19-4784-4287-833C-7C0AD795B487', -- FrcstCustmzAdjustment.ForecastingTypeId
    'E0B84AEB-5B11-432F-B2F2-D62E9517B082' -- FrcstCustmzOwnerAdjustment.ForecastingTypeId
  );

-- Target: ForecastingTypeSource.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '155B7E6B-04BF-4BDB-BA35-622FE3E3708F',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '450D8A0C-23E8-4D78-9C61-8F0722EA73A9' -- ForecastingFilter.ForecastingTypeSourceId
  );

-- Target: FulfillmentOrder.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'E09BBFA2-2486-4432-8C3A-9979375E76A0',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'B5012775-0DFB-4BFE-BCE5-0C8D7AB7C857', -- FulfillmentOrderLineItem.FulfillmentOrderId
    '58BFDC1B-BD84-4C33-9162-0AA0729B23DB' -- PickTicketAssignment.AttachedToId
  );

-- Target: GenAiPlannerDefinition.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'D5F3BC4B-1C1A-4278-BFAB-8AC354257221',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '980D892D-9B18-4F78-8166-422E7EB04322', -- GenAiFunctionDefinition.PlannerId
    '1334DA1E-B269-4D51-9A6B-85EBB418A581', -- GenAiPlannerFunctionDef.PlannerId
    '1C1863D0-CC41-4605-9082-7C0D4C8B0C98', -- GenAiPluginDefinition.PlannerId
    '3427CB9B-18E7-46D7-AF1C-4341C4B915BC' -- GenOpPlanRequest.CopilotId
  );

-- Target: GenAiPlannerFunctionDef.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '1379BFC6-21A7-4644-842A-2CB9F574495A',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '25B34F92-0298-4005-BBC4-2A3E9BCA3F46' -- GenAiFunctionDefinition.ParentId
  );

-- Target: GenAiPluginDefinition.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '6AF10664-CF4B-49AD-B151-6AC13C5D2994',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '23E27D02-2B68-455E-BC10-F2D95717CE9C' -- GenAiFunctionDefinition.PluginId
  );

-- Target: GeoCountry.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'C07620CD-EE52-4B3A-8346-C21A632C90E2',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '637DA592-C70D-4833-B6EB-AB6783FCEAA5', -- GeoState.GeoCountryId
    'DE3370F6-64B1-4847-BA3A-632F2B581661', -- TaxGeoConfig.GeoCountryId
    'D387E9C7-1C40-4115-958E-2E90A4C8A13E' -- TaxRate.GeoCountryId
  );

-- Target: GeoState.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '4984B8F1-052D-4E88-9C2B-D2B65DE6CFC8',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'F76075D3-BF95-4A4B-A920-54E367C5D9C1' -- TaxRate.GeoStateId
  );

-- Target: Group.Id (12 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '7718AC03-73AE-4AB1-A620-6ED974D66591',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '81B30ED5-E007-4F76-8008-FBC4E1CF58A8', -- AgentWork.OriginalGroupId
    'A61B91D9-CDF5-426A-A8D5-5CA4A8A02EA4', -- BroadcastTopicGroup.GroupId
    '7C1E060C-4B90-469E-B57A-1D25E407BA3B', -- ContactCenterChannel.OmniCallbackFallbackQueueId
    'FC0A58AB-F8AE-4ECE-B8CA-EA6FF98BAEF6', -- ContactCenterChannel.VoicemailFallbackQueueId
    '47143B41-7D97-40CC-9BDE-0FA5D90D4F44', -- GroupMember.GroupId
    '881AF893-AE95-4A0A-809C-D74BD1380BEF', -- JobProfileQueueGroup.GroupId
    '2D45F0FD-A9F7-4974-8524-F5A5438B4C98', -- LiveChatButton.QueueId
    '49317BC4-6587-4D96-AFEC-0BA6EB2D814D', -- MessagingChannel.TargetQueueId
    '9781FF5C-2860-4695-B14E-4BFB911A6B6C', -- OmniSupervisorConfigGroup.GroupId
    '94EAF6D4-0F86-45E4-886B-B9B1629067D8', -- OmniSupervisorConfigQueue.QueueId
    '5E88D2BE-174A-4B91-A4B1-34056D8A1244', -- QueueSobject.QueueId
    'F4A6E9EA-0B2A-4656-A513-6776E447A7A6' -- ServiceRequest.AssignedGroupId
  );

-- Target: Holiday.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '93052893-57EA-4FF0-8386-A8FF8074C319',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'C891790D-44CB-4BE6-894E-23154E8FFAEB' -- OperatingHoursHoliday.HolidayId
  );

-- Target: Idea.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'EC40D665-5871-43EC-9C6E-7454C3FD26C2',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'A6124AEE-F01D-46C6-9532-B2DC330C1913' -- IdeaComment.IdeaId
  );

-- Target: Incident.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '1ACD817E-520C-4097-A58B-4C6F29797C69',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '6613FB4F-0A65-4C36-959D-06DD2C01BF82', -- BroadcastCommunication.RelatedRecordId
    '9C458600-2DD9-47DE-AB78-8257E1394C87' -- IncidentRelatedItem.IncidentId
  );

-- Target: Individual.Id (9 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'F37610BD-8900-45AD-9F00-A64D42308542',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '9283B723-5F2B-4F39-B6F8-6465AF8A16D1', -- CommSubscriptionConsent.PartyId
    'F33D89BF-574C-48CA-AB78-0F1AF86E8BCF', -- Contact.IndividualId
    '51FF351E-F96D-4F6F-A9BC-82BDED5EFC2A', -- ContactPointTypeConsent.PartyId
    'B85477E1-4938-4F2C-BEC5-C39121049B0A', -- Customer.PartyId
    '296B88A4-AE97-4224-9251-AFC1FCFDACC6', -- IndividualHistory.IndividualId
    '74E2BD3A-3497-4602-A0C5-D40157625DBF', -- IndividualShare.IndividualId
    '3849F78D-8D8A-443B-AA63-87C1DD4472DE', -- Lead.IndividualId
    '01727DFD-3B52-4E15-9732-20AF55B49106', -- PartyConsent.PartyId
    '518F8198-19BD-401E-A714-567BA7873370' -- Seller.PartyId
  );

-- Target: InternalOrganizationUnit.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'F4336C78-02D6-4DE4-A4AC-14682826D6EE',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '78C5379B-603F-4EEC-A266-8174E0FECF61' -- Employee2.InternalOrganizationUnitId
  );

-- Target: InventoryReservation.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'ECCC1192-5F72-469F-A4EA-AE46052D3836',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'A736BCDB-92ED-4EF4-942C-968AA74713ED' -- InventoryItemReservation.InventoryReservationId
  );

-- Target: Invoice.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '1ED7A520-0050-42B9-9D83-20022767DEA8',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '51B6254E-DD03-4FA4-A1D8-63E385D281CB', -- FulfillmentOrder.InvoiceId
    'EB67D3AD-9DE9-4E7F-9038-D9451FCC4CEB', -- InvoiceAddressGroup.InvoiceId
    'CA877B43-E3E8-430D-8F6B-69D780CBD12C', -- InvoiceLine.InvoiceId
    'FF04C3F4-964B-4F2C-8DA5-658A5CDF9639' -- PaymentLineInvoice.InvoiceId
  );

-- Target: InvoiceAddressGroup.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'A1B578C2-C7B4-4E2F-90E5-A1561FD95926',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '6D847FD4-C03C-40E1-8A9A-33338E8903E4', -- InvoiceLine.BillingAddressId
    'C9FEC9A0-9F8C-453E-ABE6-FA7A3A5B4484' -- InvoiceLine.ShippingAddressId
  );

-- Target: InvoiceBatchRun.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '3E5961AF-A11F-4477-A7C6-03DB1B02F157',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'EF4EA3F6-FD3B-4CB5-ABD0-1A49FCDF537F', -- BillingPeriodItem.InvoiceBatchRunId
    '8ADB5CD3-F59B-4A0D-80DF-22A41F6297B6', -- BillingSchedule.InvoiceBatchRunId
    '821FBC1E-A3DD-48F7-85E4-993EC9131AF8', -- Invoice.InvoiceBatchRunId
    'A4F37545-DC85-43E6-90F6-AA5F0D9FCEFC' -- InvoiceBatchRunRecovery.InvoiceBatchRunId
  );

-- Target: InvoiceLine.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '750D2A5E-3939-41B8-BBA7-9CA018E8B106',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '63BB1C05-6498-4222-89D4-000613EFE2CD' -- BillingPeriodItem.InvoiceLineId
  );

-- Target: JobProfile.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '505D9568-C05A-4C7A-ADBE-0C03C8BCECF1',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '3B6F34A7-2B85-4AC8-96AE-5195E309C81A', -- JobProfileQueueGroup.JobProfileId
    'DD1F7A0B-B03F-43E6-BCB5-F408F229C41E', -- SchedulingAdherenceSummary.JobProfileId
    'DFDE1624-A97B-4A2D-8951-1088CA9161D4', -- ShiftTemplate.JobProfileId
    '71C976D4-899B-4E85-A114-AEF9F67A933C' -- WorkDemographic.JobProfileId
  );

-- Target: Knowledge__kav.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '8E66A49A-AB03-4E90-A570-04653B46EF3C',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '9CC5639A-8133-47F1-8758-EC9850483291' -- SearchActivity.ClickedRecordId
  );

-- Target: Lead.Id (8 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '78366E6F-DC80-4809-8EF8-188B30F5B0BC',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '0C6D0A7B-6003-4E31-BA40-0049A7FE3902', -- CampaignMember.LeadId
    '61114C98-52D9-47B8-8966-B59CEF786CEB', -- DealIndirectPartner.LeadId
    '1C5A8389-0806-4621-9BF3-07945E9212C6', -- ExtlRecShrRecordMap.InternalRecordId
    'AC3FF34A-4647-4DC4-8C3C-CFD6B3D57939', -- LeadDailyMetric.LeadId
    '709744A4-CB28-4D0B-95D2-AE4561CEB16F', -- LeadMonthlyMetric.LeadId
    '1146BFBB-F324-4198-982A-EC39D027A55B', -- LeadShare.LeadId
    '49A6DD73-420B-4A72-9D9A-D70A6F0EE8D8', -- MessagingEndUser.LeadId
    'D8FA1A74-598D-4E01-84B6-F26490D71390' -- Prospect.ConvertedLeadId
  );

-- Target: LearningItem.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'F02112A3-196A-41CB-BEF5-B8A68FB8FC4C',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'BE33ED92-FB73-4025-93C4-4EE0E09E30B6', -- EnblProgramTaskDefinition.LearningItemId
    '4CA437D3-6823-41DE-AF12-A5438E16522C', -- LearningItemAssignment.LearningItemId
    '5B65628B-AC22-41AE-9E68-29634126F84C', -- LearningItemProgress.LearningItemId
    'A1B8C5EE-1367-4529-A887-B39B454E3C4C', -- LearningItemSubmission.LearningItemId
    '86B89016-9E91-4202-BBEC-265E3492CCBE' -- LearningPractice.LearningItemId
  );

-- Target: LearningItemProgress.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '427F5942-46E7-45CC-A37C-6E925C7F915A',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '57473D71-4BE7-43E8-8CB4-B6A433438250', -- EnblProgramTaskProgress.LearningItemProgressId
    'AF0A2CEE-6739-4304-B868-EB422439910B' -- LearningItemAssignment.ProgressId
  );

-- Target: LearningItemType.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '4331B39E-285F-40E0-866F-4AEE765123E8',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '1394D4EB-70B8-4580-B2ED-6297A266A492', -- EnblProgramTaskSubCategory.LearningItemTypeId
    '72C91C5F-8F94-41E3-B7B5-B3D43D689FF6' -- LearningItem.CustomLearningItemTypeId
  );

-- Target: LegalEntity.Id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'ECEF2788-7C43-4B6F-9093-08EE22514F77',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '334DC868-8808-4AD3-B040-97AC203C138A', -- AssetActionSource.LegalEntityId
    'E729A6E5-B62E-42FE-8430-74E6F6DCC123', -- AssetStatePeriod.LegalEntityId
    'F9FE6C3A-F7B7-4716-8009-B402BE42FF5D', -- BillingTreatment.LegalEntityId
    '6344D271-AC65-42FA-B56D-4CF72ADDFE18', -- InvoiceLine.LegalEntityId
    '3A25C8F2-D029-44B1-B563-A91328354674', -- Payment.LegalEntityId
    '14108984-89C6-4549-952F-0A07822A68E2', -- QuoteLineItem.LegalEntityId
    'ACED3B52-1713-44E5-8DB1-DF12B83C8B2D' -- TaxRate.LegalEntityId
  );

-- Target: LinkedArticle.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '83F7A51E-530C-4659-9B8F-84D92DE0054C',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '374F7874-C252-40B0-BEA1-A78E84561608' -- KnowledgeArticleFeedback.LinkedArticleEntityId
  );

-- Target: ListEmail.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '7A1ACE73-D53C-4AC8-8BDF-9C43B4D91029',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '9CEFEB3F-DDD4-4B77-9F19-1D08F87B2885', -- ListEmailIndividualRecipient.ListEmailId
    'F17A6C27-0637-4F56-9638-BA9338687752', -- ListEmailMonthlyMetric.ListEmailId
    '67D7600D-E00C-478E-9CD7-9B3777210A3E' -- ListEmailRecipientSource.ListEmailId
  );

-- Target: ListView.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'F263858D-7685-47CD-BC09-E13E9FE07C53',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'FC5D4694-B2EB-4057-97BF-883C3D899E02', -- CalendarView.ListViewFilterId
    'FD9B1EA0-A808-4EED-87B1-2ABCC98150F2', -- ListViewChartInstance.ListViewContextId
    'C12E5069-45E7-4D4E-8CB2-81FA8E1D76A1', -- PipelineInspectionListView.ListViewId
    '51FA2660-CB89-432A-879E-82565A7FA27D' -- UserListView.ListViewId
  );

-- Target: ListViewChart.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '1BF92BC5-ACF1-43DE-9B2A-14AAAE339B91',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'CBB3FB37-B992-4AC4-999C-1A8A7B600E65' -- ListViewChartInstance.ListViewChartId
  );

-- Target: LiveChatObjectAccessDefinition.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'F9F4D116-2775-42C9-8C0C-385E9255995D',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '009D6FEC-5C8D-4658-A0B8-841804D7C6A5' -- LiveChatObjectAccessConfig.ParentId
  );

-- Target: Location.Id (21 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '4C509B55-3721-4C0F-81AB-D54A10531F48',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'FEB34A87-1C7F-4862-8FFD-B9B91A3B4FAE', -- Address.ParentId
    'BCBA1DB9-5674-427E-9763-2A35814FF9DE', -- AssociatedLocation.LocationId
    'FB4AC166-076A-47EC-AA40-DD53AFC15958', -- FulfillmentOrder.FulfilledFromLocationId
    '46E4B637-55BA-4F43-A2F1-390E900AE377', -- PickTicket.LocationId
    '5D2A9FBC-2A0C-4DEF-B701-6EC2B0C91788', -- PriceProtectExecLineItem.LocationId
    '3FB569C2-756F-4E87-8D64-5D3B78B6D8A1', -- ProductItem.LocationId
    'CBE067D3-0E63-4BF0-A4D3-7926EC82F510', -- ProductRequest.DestinationLocationId
    '07792AA4-AABE-44F3-80B8-018D6674D161', -- ProductRequest.SourceLocationId
    'D84B13AC-B557-432B-910B-3E5EBDE3D991', -- ProductRequestLineItem.DestinationLocationId
    'C8077C4C-4FBD-4E93-9B01-2046D85709CF', -- ProductRequestLineItem.SourceLocationId
    '91B82E67-17CF-47C6-90C1-CFBB49945177', -- ProductTransfer.DestinationLocationId
    'E282C370-4716-4A21-851A-46E72E0179A2', -- ProductTransfer.SourceLocationId
    '8F3D9050-AC36-4206-AE13-CA43E1A0D83A', -- ReturnOrder.DestinationLocationId
    'C8486174-95EA-43F9-B2CA-648B684A2586', -- ReturnOrder.SourceLocationId
    'F7FA2E35-DBC8-4A3E-8732-8409FB7E4579', -- ReturnOrderLineItem.DestinationLocationId
    '93DD0BD5-647D-4633-A33C-6A4AA5E741F6', -- ReturnOrderLineItem.SourceLocationId
    '2C54F1E3-18F8-4E69-ABCF-1A61F2962AFB', -- ServiceResource.LocationId
    '490D7887-9AB1-4B08-916D-E1A9B7F05950', -- Shipment.DestinationLocationId
    '1BE4D465-ADEE-4BCF-B96D-C543C6863F62', -- Shipment.SourceLocationId
    'E8B1A966-7546-41B0-8F98-7D1ECBBA0CEE', -- WorkOrder.LocationId
    '1A03B071-246F-47A6-A1D6-8BF9036CFB9C' -- WorkOrderLineItem.LocationId
  );

-- Target: LocationGroup.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '9B90E457-F5C5-4508-B13D-B6A6ABEFB6CF',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '17A3D713-0712-42DA-BC1D-8BCB1FAE7492' -- DeliveryEstimationSetup.LocationGroupId
  );

-- Target: LoginGeo.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'E550B20D-C4D2-4943-B0C6-1A1A4B1CB03E',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '72B1E476-F6A1-447B-AD39-8C465662BCB9', -- AuthSession.LoginGeoId
    'BB630119-B28F-4E11-9587-8F6DEFE5DD5B', -- LoginHistory.LoginGeoId
    '54DF68A2-F773-4BA7-90FF-A53657B37D7B' -- VerificationHistory.LoginGeoId
  );

-- Target: LoginHistory.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '0D418D2F-FB62-4FAC-BB40-55E5F15F1B91',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'D21584F0-1ECE-45F6-BB4A-354B5441A339', -- AuthSession.LoginHistoryId
    '439D6B15-69BD-405B-BA8E-3D0F0A94DD3F' -- VerificationHistory.LoginHistoryId
  );

-- Target: ManagedContent.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '74E6DD30-45F9-4D94-A41F-F126085AC760',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '09DFA877-4129-4BE2-B0B0-8D6A96DB7918', -- Brief.BrandId
    '6039CC62-7B33-4496-A8AD-2571A97D9213', -- ManagedContentVariant.ManagedContentId
    '8D3C498F-95CF-457B-8192-97E798EB8925', -- NetworkDataCategory.ImageId
    'B16C8373-9E4C-43AD-B65A-CC76E45D9418', -- UserRelatedRecordContent.ManagedContentId
    '7B733BC0-FF34-45FD-98F0-DE36AB3CA245' -- WebStoreMessageContent.ManagedContentId
  );

-- Target: ManagedContentSpace.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'BC606068-E69A-48DF-874D-15F184BAC236',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '7572647D-5941-4D64-A292-EC1E2E0B0390' -- ManagedContent.AuthoredManagedContentSpaceId
  );

-- Target: MatchingRule.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '7C772838-CA87-4F18-B523-7D9972ADB284',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '60C6C326-E2B1-416F-ADEA-DF2FEB006DAB' -- MatchingRuleItem.MatchingRuleId
  );

-- Target: MerchAccPaymentMethodSet.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '4998F21F-374D-465C-BAD8-2B916121286D',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '46A1F927-A02D-4261-8811-1FF005DDE048', -- MerchAccPaymentMethodType.PaymentMethodSetId
    '0AF0E87A-BDBC-48CD-AD46-1F54C41ECF1A' -- PaymentLink.PaymentMethodSetId
  );

-- Target: MerchantAccount.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'A51E8AEF-50C1-49F3-A343-0973F50C94C7',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '39F67B3E-A94B-4463-B56E-5F5CB8809FC1', -- MerchAccPaymentMethodSet.MerchantAccountId
    '411AE25D-1E4B-4CEF-8371-F1E05BA75984', -- MerchantAccountEvent.MerchantAccountId
    '350B2C39-26C7-4ECA-895C-352DEBADAD1D', -- PaymentGateway.MerchantAccountId
    'C5F817D2-3E1C-4698-9B4A-0EFBCF0444D4', -- PaymentIntent.MerchantAccountId
    'B41ABFFE-C9C8-4427-BE94-DDC91DD8366F' -- SavedPaymentMethod.MerchantAccountId
  );

-- Target: MessagingChannel.Id (9 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'FFE15651-0BD5-459B-9DCC-9BAD5508503E',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'FA737892-BAA3-4552-BC34-82B07054906B', -- ContactCenterChannel.ChannelId
    '1CD9A1DD-A33E-4AD3-AC41-2858C41B19C2', -- CustomMsgChannel.MessagingChannelId
    '27345471-D5EA-418B-BF76-A3A8158B2937', -- MessagingChannelSkill.MessagingChannelId
    'BFC89E4C-7976-487F-A61D-1851DA85E247', -- MessagingChannelUsage.MessagingChannelId
    'D63FF71C-C5C4-4150-854B-B0A20AAE04DA', -- MessagingDeliveryError.MessagingChannelId
    '3BEDA334-0393-49FE-A32F-F2082EB27E2B', -- MessagingEndUser.MessagingChannelId
    'F0BD7DC4-3CA3-49DB-9E45-B7EB99B0F694', -- MessagingLink.MessagingChannelId
    '4AED3C85-A563-4A56-A935-E66FA926BECE', -- MessagingSession.MessagingChannelId
    'F3F7FA6F-889D-41D1-8EB4-AF2D9272522D' -- MsgChannelLanguageKeyword.MessagingChannelId
  );

-- Target: MessagingChannelUsage.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '272474F7-07DB-4765-A317-3562D2F13E50',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'B0941E54-B600-48DD-9131-5B49D19EDE0A', -- CommSubscriptionChannelType.MessagingChannelUsageId
    '71B908BF-BCCC-4DDA-A61D-F1918056CD69', -- MsgChannelLanguageKeyword.MessagingChannelUsageId
    'D5F770DA-7F62-4E58-9CD7-BB61691F7790' -- MsgChannelUsageExternalOrg.MessagingChannelUsageId
  );

-- Target: MessagingEndUser.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'F8F4F230-4B37-49AB-9900-94B58FE658BD',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '37501EAD-9F7A-4FCD-9C49-EF1F5CC09F0B', -- MessagingDeliveryError.MessagingEndUserId
    'A36C2DDB-24A3-439A-994B-FCEB5F425043', -- MessagingSession.MessagingEndUserId
    '9A63A389-2C27-4051-855D-46A24DD27F37' -- VoiceCall.EndUserId
  );

-- Target: MessagingTemplate.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '49661CDF-1B01-458A-BF19-FA6283CA05C4',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '3DBDDEC5-C8CC-4986-8B23-071F2F9FA95E' -- MessagingDeliveryError.MessagingTemplateId
  );

-- Target: MLModel.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '701C8319-FF8D-40B4-8536-2F4B204CFC14',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '05FB13B7-029C-4D4A-86B1-212E8F97178D', -- AIRecordInsight.ModelId
    'CC5F0740-36AD-4FFF-AEBD-2659B5E0FE7F', -- MLModelFactor.ModelId
    '07DD102C-E5A5-4072-9C80-402A89A3C66E', -- MLModelFactorComponent.ModelId
    '1293AAF2-4C23-46E3-B95A-445B5C4666DF' -- MLModelMetric.ModelId
  );

-- Target: MLModelFactor.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '65C9F9E2-48E3-45ED-8D53-7FCE0C8858CC',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'F772C60C-83EB-464C-9A32-FA7659984939' -- MLModelFactorComponent.ModelFactorId
  );

-- Target: MLPredictionDefinition.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '2AB29CCC-7B63-4544-9B01-FC6B18EA909E',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '2B96A8FF-A142-4C4B-99CE-2860DC63A395', -- AIRecordInsight.MlPredictionDefinitionId
    'E88BC221-6CC6-4B3B-A138-CBE2DCAE478A' -- MLModel.PredictionDefinitionId
  );

-- Target: MLRecommendationDefinition.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '3AF060FC-587A-444B-BBE4-35E80D59D65B',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'E2D57765-C494-4F9B-B8C8-29EC38C51589' -- MLModel.RecommendationDefinitionId
  );

-- Target: MobileSecurityAssignment.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'BAD551A0-5874-4860-BD16-E0E877F14BE3',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '57374BFF-9A48-4467-A41B-E4C450D689E2', -- MobileSecurityPolicy.MobileSecurityAssignmentId
    '78EDF517-119B-4493-B407-B4FB770740B7' -- MobSecurityCertPinConfig.MobileSecurityAssignmentId
  );

-- Target: NamedCredential.Id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '773EB3E0-EAB9-49B3-9831-D8DC70327EA5',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '64A5B335-6A42-4D4F-A31B-F6A8BCD56A5A', -- ExternalClientApplication.NamedCredentialId
    '293891B3-77BB-4164-975D-CDF900A6975A', -- ExternalDataSource.NamedCredentialId
    '4DC1883B-83A7-4F81-A896-5AF424B1AF24', -- ExtKnowledgeConnector.NamedCredentialId
    'E1A14460-7C38-48DF-B961-E688B0DC70E5', -- ExtlRecShrCnct.NamedCredentialId
    '0BDA4264-F9D7-419D-988E-49FAED553295', -- PaymentGateway.MerchantCredentialId
    '56D9F249-19B7-49D1-9868-B9089C2A6D58', -- TaxEngine.MerchantCredentialId
    '705195BA-9FFC-47A0-818F-0CBF1669D44F' -- UserProvisioningConfig.NamedCredentialId
  );

-- Target: Network.Id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '18778C1F-3E65-46A9-A75F-E1F41FE91375',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '525C0173-97C8-484F-966A-6F7DB84E9FD6', -- BroadcastTopicNetwork.NetworkId
    '35E204A8-B61E-420E-8800-17EE680EBC5F', -- EnablementProgram.NetworkId
    'FC053CB0-1665-4722-ACF0-C8CC533EBBDB', -- NetworkAuthApiSettings.NetworkId
    'A9FE9EE6-BB31-4BE5-9972-D8072FD585D1', -- NetworkDataCategory.NetworkId
    'D221F96E-8177-42A5-B282-57F4C77C29DF', -- NetworkEmailTmplAllowlist.NetworkId
    '2E08F603-4EFC-417E-9659-89868245519D', -- RecommendationResponse.NetworkId
    '981F6FB9-9F80-42F0-897C-E49659DC47FB' -- WebStoreNetwork.NetworkId
  );

-- Target: OauthCustomScope.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '179A47FC-899B-4BB1-B522-E2F5BE792AC7',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '71710493-7FD3-41B7-8138-14B83DE9E9F9' -- OauthCustomScopeApp.OauthCustomScopeId
  );

-- Target: OauthTokenExchangeHandler.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '07A1FEDD-2AC8-4C52-8664-7A15C9C5C648',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '6A277241-5E70-4B80-ADC4-665D38DD37A2' -- OauthTokenExchHandlerApp.OauthTokenExchangeHandlerId
  );

-- Target: ObjectDataImport.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '5BEE08F8-AA59-45CA-8B0D-93C5A05BBE75',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'EDADAEA0-F9CF-45F1-9D4D-67CCAD3182C1' -- ObjectDataImportReference.ObjectDataImportId
  );

-- Target: OmniSupervisorConfig.Id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '1ABAD6EB-EF55-45A3-9430-0F885ED4EA75',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '5EA647C0-44D1-4D12-AE18-AA5BE99D73ED', -- OmniSupervisorConfigAction.OmniSupervisorConfigId
    '77150D1F-931C-4C34-A1E9-D8F4D35E439C', -- OmniSupervisorConfigGroup.OmniSupervisorConfigId
    '9E129356-EC36-4CFB-985A-A29C1C8D77A9', -- OmniSupervisorConfigProfile.OmniSupervisorConfigId
    '72EAB0F0-6C22-4000-B8BF-8ABD0B1F8EEE', -- OmniSupervisorConfigQueue.OmniSupervisorConfigId
    '5DD3C0EA-A0EC-4D69-A78D-73091D16F838', -- OmniSupervisorConfigSkill.OmniSupervisorConfigId
    'B7482D1D-8658-477E-83D1-21C7AFAEA45B', -- OmniSupervisorConfigTab.OmniSupervisorConfigId
    'C2210304-C0EC-463C-BF39-4A9E8A1F5EAE' -- OmniSupervisorConfigUser.OmniSupervisorConfigId
  );

-- Target: OperatingHours.Id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '2992507A-F7DD-4677-B0E8-67F54AD31E71',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '8F1B508E-D581-417C-9930-75DF02C704B1', -- Account.OperatingHoursId
    '5A957920-80FD-4FD7-B750-DB60C2782EC2', -- AppointmentTopicTimeSlot.OperatingHoursId
    '804AAAFA-E48D-41E1-930B-7C3C7833B7D8', -- OperatingHoursHoliday.OperatingHoursId
    '59EEBEE4-4FD9-4D0E-B02E-5A2088B3E52B', -- ServiceResourcePreference.OperatingHoursId
    '9F798195-E540-44C2-97A1-B4341EEC2B70', -- ServiceTerritory.OperatingHoursId
    '0BA47D2B-DE46-4F77-B92C-2F925761CB2E', -- ServiceTerritoryMember.OperatingHoursId
    '4E98134E-CE0A-44A9-99D3-CD6E3291EE4F' -- TimeSlot.OperatingHoursId
  );

-- Target: Opportunity.Id (19 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'FC41A030-8BD8-4B00-AEE4-8460AFBC866E',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '00E0115F-6D99-4E98-9235-854F4155F0F4', -- AccountPartner.OpportunityId
    '0499758C-E1BD-4903-95A6-117265F7F28C', -- DealIndirectPartner.OpportunityId
    'B7B9429B-48AF-430E-A6F3-AF05FDEE8BFE', -- FieldChangeSnapshot.ParentId
    'E43CB1D6-2B52-497A-AFA5-46123034D3D3', -- ForecastingSrcRecJudgment.ReferenceObjectId
    '580D21B7-F32E-4708-9A27-B98120BC5E2A', -- Lead.ConvertedOpportunityId
    '3D141A3F-FA33-4894-9E9B-4CC2CB61A479', -- OpportunityCompetitor.OpportunityId
    'C1768770-6F02-4D72-A721-01839C4366D4', -- OpportunityContactRole.OpportunityId
    'B30D1789-E249-477B-AF7D-69302B58D12A', -- OpportunityFieldHistory.OpportunityId
    '44C1A655-E4A8-443B-B32F-FA0692718D1A', -- OpportunityHistory.OpportunityId
    '04F14841-F82F-4EE6-B529-84B2F8B1040C', -- OpportunityLineItem.OpportunityId
    '42CB2811-C105-4521-90DD-6F0563F0AF28', -- OpportunityPartner.OpportunityId
    '98C77BB6-14D8-4E59-9256-53D657E658C3', -- OpportunityRelatedDeleteLog.OpportunityId
    'D1EC7580-7981-48A1-8977-1A52011D4A55', -- OpportunityShare.OpportunityId
    '80BB7513-1D4F-494B-9175-5CEAAA074F8C', -- OpportunitySplit.OpportunityId
    'F0195E7F-10D1-4426-9765-4404F410D65C', -- Partner.OpportunityId
    'B37C30B0-16C9-437E-86D3-853E4724AC7D', -- PaymentInitiationSource.OpportunityId
    '6D823FC4-3DB3-4CC8-921A-B1FE137BC6D2', -- Prospect.ConvertedOpportunityId
    '1A683F83-B4E2-4123-B4F9-51D1D44B2175', -- RecentFieldChange.ParentId
    '9231E968-4085-4C6A-A160-F6DE650B46C6' -- SfdcPartnerOffer.OpportunityId
  );

-- Target: OpportunityLineItem.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '19690DB8-7523-459E-9562-5650897AF0B7',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '7F166BEF-5905-45EC-9124-65CB8EBB8BEB' -- OpportunityLineItemSplit.OpportunityLineItemId
  );

-- Target: OpportunitySplitType.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'C3EA2BEF-5DA4-4C62-99C1-349B03A2A13B',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '296594A4-D908-4AB9-AC66-1AC5234EEBC8', -- ForecastingType.OpportunitySplitTypeId
    'E9792CB7-EB28-4D73-8DD9-7CDC0B88082B', -- OpportunitySplit.SplitTypeId
    '7FA59CF6-E7B7-45AD-ADE4-31D5C38681B0' -- OpptyLineItemSplitType.OpportunitySplitTypeId
  );

-- Target: OpptyLineItemSplitType.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '61426D90-D27B-4E3D-AEEF-73EC3C8CF961',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '0A779532-4B99-4993-836D-6FB989B88053', -- ForecastingType.OpptyLineItemSplitTypeId
    '0F9AD533-47BC-4164-B9C4-34E0636F20CF' -- OpportunityLineItemSplit.SplitTypeId
  );

-- Target: Order.Id (18 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '99489EF9-4CDC-4E67-8F45-9BE9AE9FE328',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'F0C30273-649B-4116-B29C-05237827E8CC', -- BillingSchedule.ReferenceEntityId
    'E8B7EECF-5FB5-473B-A2DF-7F0A73D183BE', -- FulfillmentOrder.OrderId
    'E785A265-5544-4ADF-9DF7-38AD525BBC56', -- OrderAction.OrderId
    '53656938-F9ED-47D3-9B14-A6E046F2916E', -- OrderAdjustmentGroup.OrderId
    '7E4C3EE1-6C1B-4621-B9FB-6EF69809BCF0', -- OrderChangeLog.ChangeOrderId
    '423AF4F5-B60B-4D3B-9EE2-99DA5CFDB240', -- OrderHistory.OrderId
    'FC6BBF08-7137-405A-B72D-26DC2AAF04BF', -- OrderItem.OrderId
    '293615BB-B6EA-4E8A-BBA5-6041694BC4DC', -- OrderItemRelationship.OrderId
    '235E6285-2E07-44A5-B22F-BDEB8B696D6D', -- OrderShare.OrderId
    '8ED7E2A2-DB35-4F3F-B896-64759FE13137', -- OrderSummary.OriginalOrderId
    'BA6C1493-5532-48B6-94E3-9FCEFF263065', -- OrderSummaryAdditionalInfo.OrderId
    '3CA94F80-06C4-4DB7-8142-F78DD319C2D2', -- OSAsyncChgCompletedEvent.FeeChangeOrderId
    '64F4D111-9B6F-4722-902C-CC52874EDCB4', -- OSAsyncChgCompletedEvent.InFulfillmentChangeOrderId
    '032F598E-EDAB-49CF-BF93-02FE4E683253', -- OSAsyncChgCompletedEvent.PostFulfillmentChangeOrderId
    'CB6201B5-C396-4AFA-8F5B-CC18BF604FF6', -- OSAsyncChgCompletedEvent.PreFulfillmentChangeOrderId
    '13BDFDE6-4922-452B-8EDA-86441B4FD1A8', -- PaymentGroup.SourceObjectId
    '3016A5FF-2DDC-4FCD-8B60-C481BB0C91F4', -- ReturnOrder.OrderId
    '292E3811-ACCC-4B50-9F80-F1214DC3F294' -- WorkOrderLineItem.OrderId
  );

-- Target: OrderDeliveryGroup.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '9B519155-2D06-4492-A772-C655E1A60D5F',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '3AF9A164-DF1C-46BF-8916-5201D6CA8B41' -- OrderItem.OrderDeliveryGroupId
  );

-- Target: OrderDeliveryGroupSummary.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '19FE0210-17E9-4985-B7D8-B8BBB2A20B19',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '0C005071-23D0-4018-848F-EFC0D24EE0E8' -- OrderItemSummary.SummaryId
  );

-- Target: OrderDeliveryMethod.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'D085299D-DD98-4D32-B212-2E15D24F4960',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'DADAEC6F-4F30-48A6-B5CF-CB3D7F2210DB', -- CartDeliveryGroup.DeliveryMethodId
    'E7D50BB0-BE8F-47A6-929F-66F217380ABC' -- FulfillmentOrder.DeliveryMethodId
  );

-- Target: OrderItem.Id (10 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '7FB8F6A2-D61C-48AC-92B9-40001E906864',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'ACCA35A8-615F-443F-8C39-4CF4037C28CD', -- FulfillmentOrderLineItem.OrderItemId
    '19A17EBA-4420-4B8B-B934-1DADA683F4E3', -- OrderAction.OffsetOrderItemId
    '96715798-5059-4C58-88F5-3FF04D2C266F', -- OrderItemRelationship.AssociatedOrderItemId
    '1806EE84-B5CE-40FC-B415-26CB06364045', -- OrderItemRelationship.MainOrderItemId
    '7EC73BCD-7F2A-4F88-9C0D-72838696C6E9', -- OrderItemRelationship.RootOrderItemId
    '9A4E0388-F645-42D9-A1B5-9E1ED88D94D6', -- OrderItemSummary.OriginalOrderItemId
    '97660904-01D9-4065-8FB3-A870F3B16F6A', -- QuoteLineItem.RelatedQuoteLineItemId
    '2CA8CD67-34AB-4B21-AAA3-4B987D8B7BD6', -- QuoteLineWorkSource.OrderItemId
    '3F8D9311-C816-4A89-9253-1436D74A4BCB', -- ReturnOrderLineItem.ChangeOrderItemId
    'EAC8C32B-8DEB-4504-B90D-A4A1B20E0AA4' -- ReturnOrderLineItem.OrderItemId
  );

-- Target: OrderItemRelationship.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '221F2EAC-BABF-4756-877D-A0FBC5326188',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'E126B8DB-DFE4-4444-B11F-4A7584AF8933' -- OrderItemSummaryRelationship.OrderItemRelationshipId
  );

-- Target: OrderItemSummary.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '39B73BD9-A260-4A90-9E6C-A52231818887',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '4D349A7C-FD27-47B6-8798-DFD43E956060', -- FulfillmentOrderLineItem.OrderItemSummaryId
    '87CAA2B2-F7B2-451A-ACDD-B7C06EC5F5A3' -- OrderItemSummaryRelationship.AssociatedOrderItemSummaryId
  );

-- Target: OrderPaymentSummary.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'B97B110E-4F03-412B-8F72-AB0040EECDCB',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '3415C661-B1FA-4172-BFAD-0D3E20B3E4D2', -- OrderPaymentSummaryReference.OrderPaymentSummaryId
    '21106970-FF1B-4001-95CC-06EC6BCA6CEC' -- PaymentCredit.OrderPaymentSummaryId
  );

-- Target: OrderSummary.Id (11 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'D7400C63-A7DD-44AE-B2A3-57413B67AA07',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'F32A30C6-3157-4A32-A575-5C5ECAC10B62', -- FulfillmentOrder.OrderSummaryId
    '0AD04DFD-9658-482A-A8B4-C9E70C8C21C1', -- OrderItemSummary.OrderSummaryId
    '1D9A7D97-76BB-4E2D-B485-C63EBE4717D7', -- OrderItemSummaryRelationship.MainOrderSummaryId
    'E473ECCE-5C8D-4267-AEF4-077B64DBBE97', -- OrderPaymentSummaryReference.OrderSummaryId
    '79199FFF-B8E9-4C2F-8888-C5285536C79F', -- OrderSummaryAdditionalInfo.OrderSummaryId
    '0626E7FF-DC9F-4B01-8E21-8F83B050BE20', -- OrderSummaryRelationship.AssociatedOrderSummaryId
    '9E0F5EFC-042B-4A65-B3EB-5291552781D0', -- OrderSummaryRelationship.MainOrderSummaryId
    '63E60EA5-FD5D-475A-8647-678DDF2B7694', -- OrderSummaryRelationship.RootOrderSummaryId
    '43BADCEC-ED34-4E0D-9A11-36565B178C70', -- OSAsyncChgCompletedEvent.OrderSummaryId
    '99A34E8A-AEB0-47D3-98B4-CD8491038E6D', -- PaymentInitiationSource.OrderSummaryId
    'C74D41EC-566F-4AA9-9219-B7207B9AD4CC' -- ProcessException.OrderSummaryId
  );

-- Target: Organization.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '1A7EF1F2-9890-4ACD-94E5-ED9FC63AC930',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '96CC62EA-8475-48AE-9787-80F03F026FCE' -- Stamp.ParentId
  );

-- Target: OrgWideEmailAddress.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '5AE8B5FC-7278-428A-8047-B92F549D72F5',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '2DC39F16-40CE-4008-A636-BB992B5F3A6B' -- OrgEmailAddressSecurity.OrgWideEmailAddressId
  );

-- Target: PackageLicense.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '737DCF51-56CC-440C-BB2D-FBC48564D26B',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '95DCDFAC-F710-49FA-9C91-7A88F1449DCA' -- UserPackageLicense.PackageLicenseId
  );

-- Target: Payment.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '7FC3AB63-326F-45BB-A86F-7C9E68E519B1',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '31DB35C1-F5D6-4C16-B189-5AA8FB53E97A', -- PaymentCredit.PaymentId
    'C7F626B5-A819-4B0B-A8C8-C0B8D016946F', -- PaymentLineInvoice.PaymentId
    'A1D5B412-DB35-4802-A2FB-C977EEAA61DC', -- PaymentScheduleItem.PaymentId
    '71B07061-5991-41C6-BE44-A667EFBEF9F9', -- Refund.PaymentID
    '339C9E3C-2739-4F36-B332-2D4D5DF719E3' -- RefundLinePayment.PaymentId
  );

-- Target: PaymentAuthorization.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'BD756F3E-3703-43B9-BE7D-45976DC04259',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'F6B1F906-26B6-4A35-BA22-725066EE20A8', -- Payment.PaymentAuthorizationId
    'CCA902DE-06FA-4DF4-A5B4-2FF61DF11758' -- PaymentAuthAdjustment.PaymentAuthorizationId
  );

-- Target: PaymentCredit.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'B7336972-8B01-4F69-82F2-B032997591CB',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '2D5D3925-F8B1-4F09-9616-EE0A38153BAC' -- PaymentCreditLinePayment.PaymentCreditId
  );

-- Target: PaymentGateway.Id (9 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '6E311A9D-3F3D-4312-B057-1008E22D89C6',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '3D07FE22-09F3-4420-8D11-A0D5FE2461D6', -- AlternativePaymentMethod.PaymentGatewayId
    'A7823E22-D5A2-408E-9DB9-3E9837F66727', -- CardPaymentMethod.PaymentGatewayId
    '1D4DF71D-F576-4850-BFE7-1F04F3A14EF3', -- DigitalWallet.PaymentGatewayId
    '789EE965-4CC5-439D-B045-A55460E1B28D', -- Payment.PaymentGatewayId
    '5A12DE29-D70C-4DD6-9F2F-BEFC6B67B154', -- PaymentAuthorization.PaymentGatewayId
    '3FB9AC4D-CD11-49BA-9C1C-4AC42863E929', -- PaymentGatewayLog.PaymentGatewayId
    '4E4EA1D0-38E2-45A0-B601-EFF2D49688FF', -- PaymentIntent.PaymentGatewayId
    '454C8198-01D6-4244-800E-19FB31E993E5', -- Refund.PaymentGatewayId
    '7CFAA244-BC27-4756-B27F-DC5BA7893AD5' -- SavedPaymentMethod.PaymentGatewayId
  );

-- Target: PaymentGatewayLog.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '47AFB4CA-6E12-4AF0-8633-446FB8BA7119',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '8D6A728F-4CD5-4A93-94FB-758FC8E64F64' -- PaymentScheduleItem.LastPaymentGatewayLogId
  );

-- Target: PaymentGatewayProvider.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '3CCB6EF5-1396-47B6-B10A-FAF5BFA52C02',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '31EAF464-0DD1-4FAE-89F3-BDC79271C174', -- GtwyProvPaymentMethodType.PaymentGatewayProviderId
    '7FDFC0E2-A18C-4F6F-A315-2C378E3CBA73' -- PaymentGateway.PaymentGatewayProviderId
  );

-- Target: PaymentGroup.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '83961BC3-30B7-435B-A57E-FA9C0393F7EE',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '3DA8EAA1-5438-4C5A-8805-BFA6EC91C98E', -- Payment.PaymentGroupId
    '288E1D52-10F1-4ABA-A2E6-B683C5ED3E58', -- PaymentAuthorization.PaymentGroupId
    '724F3674-93CA-4952-855F-A49DECAD525E', -- PaymentIntent.PaymentGroupId
    'B5FE34EC-F036-4911-9A8C-07A0ECA1867F', -- Refund.PaymentGroupId
    'F0D00256-2D11-498C-94F0-B265CBBA760D' -- WebCart.PaymentGroupId
  );

-- Target: PaymentInitiationSource.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '0A9F69F4-F8FD-4E14-B1EB-8302C65FEBA7',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'EDC62783-6A92-40EE-A9BC-8C3BAFEED921' -- PaymentIntentEvent.PaymentInitiationSource
  );

-- Target: PaymentIntent.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'C16F66D2-E084-4082-AFDE-E3D824977322',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '04C1614C-CE94-44B7-A73C-70306A81904D', -- PaymentAuthAdjustment.PaymentIntentId
    '23E69A1F-AA1E-48AE-8689-CEF8E917DD56', -- PaymentIntentEvent.PaymentIntent
    '271488FB-BA9F-4957-99E0-496E78A05128' -- Refund.PaymentIntentID
  );

-- Target: PaymentLink.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '8E4A4F1F-8E0D-47DB-B39F-12FE00F13220',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '4141D23A-A5E6-4215-A710-7962F4455225', -- PaymentIntent.PaymentLinkId
    '8F070066-068B-4CB2-BE9E-6DA7479EBFC2', -- PaymentIntentEvent.PaymentLink
    '1FA6B02A-03EC-4FBD-BCF8-4880A910228C' -- PaymentLinkEvent.PaymentLinkId
  );

-- Target: PaymentMethod.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '01AB9002-28A5-4C42-80C4-BEA96BD31EC1',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'F4B1BEAC-B4DB-4084-B72E-0857140A1314', -- Payment.PaymentMethodId
    'C1E07DA5-A1B9-4E2A-8D73-3B10EE8CC07B', -- PaymentAuthorization.PaymentMethodId
    'DB48AE14-9FB3-4951-81A2-C8B163A07740', -- PaymentIntent.PaymentMethodId
    'B78E4CA5-88CC-4AE4-9987-1B8969C0E339' -- Refund.PaymentMethodId
  );

-- Target: PaymentSchedule.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'D46A1058-080F-46FF-A3AE-CA2D29D6FF15',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '40EB9892-24BC-4019-8958-7CADAE43078C' -- PaymentScheduleItem.PaymentScheduleId
  );

-- Target: PaymentScheduleItem.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'BD2036AD-07C1-45EA-B919-EDAF1B5AAEF4',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'D6B571C4-AC45-4DF1-9DF3-E8222451C7DE' -- PaymentLink.PaymentScheduleItemId
  );

-- Target: PaymentSchedulePolicy.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '72703D46-AC0F-4153-AC38-49DDC31498CA',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '16D15EEC-420B-4566-9397-19D2AAA1FF34' -- PaymentScheduleTreatment.PaymentSchedulePolicyId
  );

-- Target: PaymentScheduleTreatment.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '825B9596-164E-441A-A00E-65765B5069C5',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'C5E8981E-6CD5-4378-8115-0768C1F28253' -- PaymentScheduleTreatmentDtl.PaymentScheduleTreatmentId
  );

-- Target: PaymentScheduleTreatmentDtl.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'D8451DE1-2991-4B21-89EB-743094E22E57',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'B0E96EB4-0A2A-495E-BEEB-C19E99E403D0' -- PaymentSchedule.PaymentScheduleTreatmentDtlId
  );

-- Target: PaymentTerm.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'AC052FAB-303E-41F8-B629-6D7339F90758',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'A9AF0441-2756-4337-9247-9C6AEB8DC763', -- BillingScheduleGroup.PaymentTermId
    '34BB3172-9B7C-4E10-930E-E57E6302AD81', -- Invoice.PaymentTermId
    'CBBADBF3-DCFB-42F9-9D8D-149F90D82CFA', -- Order.PaymentTermId
    '161C380A-F52E-4FA8-B6AC-D38A368D0BD5' -- PaymentTermItem.PaymentTermId
  );

-- Target: PendingServiceRouting.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'FD64865B-EF10-449A-A8B7-9F9C6CF05658',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '29BE54F0-A985-468D-AEC9-5A388917799B', -- AgentWork.PendingServiceRoutingId
    'D457DBB2-8F0F-4D53-AA92-B919CFA2BF9A' -- PendingServiceRoutingInteractionInfo.PendingServiceRoutingId
  );

-- Target: Period.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '7B3E3D14-6504-4CA1-BE19-FD1359A63AB8',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '79279443-8C2F-4074-A005-4715A4B95ECF', -- ForecastingCustomData.PeriodId
    'DCFCE3ED-E4CD-4C40-8E6E-B179DCA5FBCB', -- ForecastingSubmission.PeriodId
    '56C86CBF-EAA8-46E4-9685-871677902E71', -- FrcstCustmzAdjustment.PeriodId
    'D5F6B58A-E475-44E7-BFBC-05636195B186' -- FrcstCustmzOwnerAdjustment.PeriodId
  );

-- Target: PermissionSet.Id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'D2F78DE2-EF1F-40F8-8ECA-C9326ACA80D4',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '69EF0B80-242D-4B68-8326-0092BD3582E5', -- FieldPermissions.ParentId
    '70F8FB8A-6E4E-40FB-8E06-650BDD965AA1', -- ObjectPermissions.ParentId
    '57973A75-E967-497C-B5DB-A6218DA74D02', -- PermissionSetAssignment.PermissionSetId
    'C175B3A5-76DF-4081-9C88-69694C0DD3BA', -- PermissionSetGroupComponent.PermissionSetId
    'DD8772A2-706F-4504-BEA6-0CA636564AC8', -- PermissionSetTabSetting.ParentId
    '60DCE3ED-1539-4338-A22E-7A383353D293', -- SessionPermSetActivation.PermissionSetId
    '83B5CDF1-E733-4197-8404-84A94A840210' -- SetupEntityAccess.ParentId
  );

-- Target: PermissionSetGroup.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '79F899CA-E7C5-457F-B51D-A0CDCFED3DBD',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '06D98043-ABCD-4528-9C77-1DD6F8D2AC22', -- NetworkSelfRegistration.PermissionSetGroupId
    'FF6DBB30-3EC3-4D7D-A421-E419C9DF74AB', -- PermissionSet.PermissionSetGroupId
    '81CD0433-806C-4DEA-804A-2502271D81F3', -- PermissionSetAssignment.PermissionSetGroupId
    'AF840064-0BCE-4DAA-9568-4BEEFE60897F', -- PermissionSetGroupComponent.PermissionSetGroupId
    'D819B050-5640-451E-A186-F6D66ACF06B5' -- SessionPermSetActivation.PermissionSetGroupId
  );

-- Target: PermissionSetLicense.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'B3E8F545-8C7C-4B1E-B00D-D60C47A22F42',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '9504C830-6284-4EF0-9A7A-461C63909268', -- ActivePermSetLicenseMetric.PermissionSetLicenseId
    '2020F13A-BB88-48E5-80A7-98550B99A9FB' -- PermissionSetLicenseAssign.PermissionSetLicenseId
  );

-- Target: PersonalizationSchema.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'B77DD442-B20A-4E0C-8F53-92C771DD5ED8',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '66EE6D7D-3E8F-4109-82B6-DDE4CBB7EDF2', -- AbnExperiment.PersonalizationSchemaId
    'AC0D1D0F-91F2-4063-946B-EED7BE6B1AE0' -- PersonalizationPoint.PersonalizationSchemaId
  );

-- Target: PickTicket.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'ECDBA7A8-0E52-4184-B15E-9FAA4389668E',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'F2CB5F40-523F-48C3-B54E-05E89F5E6C53', -- PickTicketAssignment.PickTicketId
    '9B91A5F8-A6BC-452B-A8EE-0A7615BF2309' -- PickTicketProduct.PickTicketId
  );

-- Target: PipelineInspectionListView.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'FB522F38-4DB7-4685-800C-B5249C9DA4E6',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '2267ECD5-C1F2-48AD-82C9-0747E971EF98' -- PplnInspListViewCalcClmn.PipelineInspectionListViewId
  );

-- Target: PipelineInspMetricConfig.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'E1A9DDBB-C60C-4935-80FF-3E226F206328',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '571F4306-1C7C-44DC-A0A0-1D203C24F464' -- PipelineInspMetricConfigLocalization.ParentId
  );

-- Target: PriceAdjustmentGroupShape.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '45EC3764-6309-4A2A-9E9E-8BF8169775B5',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'AE85B59A-583B-46F4-999C-E2C2C392CD9F' -- PriceAdjustmentItemShape.PriceAdjustmentGroupShapeId
  );

-- Target: PriceAdjustmentTier.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '4FCE3B1B-BE2D-4052-B039-FBE2FC07E840',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'A5ACB6A3-8675-424A-883F-2C8D117C8022', -- PriceAdjustmentGroupShape.PriceAdjustmentCauseId
    '1D149543-6140-453A-A2CF-B3E802C144B0', -- PriceAdjustmentItemShape.PriceAdjustmentCauseId
    '5C950598-F731-4B20-ACCF-B35FCCAB1179' -- QuoteLinePriceAdjustment.PriceAdjustmentCauseId
  );

-- Target: Pricebook2.Id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '16D1262D-9F6D-430B-92AF-05D56BBEA6A4',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '7F6493F0-09E0-424F-8EE8-474D6E8CA708', -- Opportunity.Pricebook2Id
    '47C1D2DC-3B4D-4AD4-9980-69C9FD88C8FB', -- Order.Pricebook2Id
    '53B52FED-F721-4C67-A5FC-0A33D1CA4421', -- OrderSummary.Pricebook2Id
    '617EC9AE-2722-441B-ADF2-B78A57F996F0', -- Pricebook2History.Pricebook2Id
    '2CF3ABBD-0E75-4BFD-8D86-94AC67F92B15', -- PricebookEntry.Pricebook2Id
    'B16117DD-1CBB-4DD0-A92A-E70E7AEBC92B', -- WebStore.SortByPriceBookId
    'EDD50A44-C120-499F-8140-487E716BE0FD' -- WorkOrder.Pricebook2Id
  );

-- Target: PricebookEntry.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '153106D0-E341-4D4B-8E04-F98F885F3CD5',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '0775B4EC-BB25-42C5-A13F-737C7F6784E4', -- CartItem.PriceBookEntryId
    '1B166E80-956B-4CF5-9EAB-7E2CAF9536DD', -- OpportunityLineItem.PricebookEntryId
    '1F516CB3-2BF3-4682-B143-158036ECD41F', -- OrderItem.PricebookEntryId
    'FCCB43A8-9FE1-438C-8881-ECAE69B3613B', -- OrderItemSummary.PricebookEntryId
    'AB10A14B-0901-43E9-B2AF-394BA20DE4C9' -- WorkOrderLineItem.PricebookEntryId
  );

-- Target: PriceProtectionTerm.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'F85E45BD-E025-4E35-B207-26AD087AFBB2',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '4AE6063F-677D-49FC-90CD-CC1FA7C8B3A3' -- PriceProtectExecLineItem.PriceProtectionTermId
  );

-- Target: PrivacyHoldReason.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'F317A9AF-1082-450E-A82A-D0A357E6BD74',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'D8DE2036-AEE1-4E64-B4BC-06C2674B782E' -- PrivacyHold.PrivacyHoldReasonId
  );

-- Target: PrivacyJobSession.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '16DC00BE-54C5-4622-B8D0-36191E422ED2',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '5C38581C-4DB4-463B-BCE9-B4CCC76B2373' -- PrivacyObjectSession.PrivacyJobSessionObjectId
  );

-- Target: PrivacyObjectSession.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'CBC76AC1-07D1-43F2-9756-3840E9DBBE6A',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '5BE07CDA-7805-4C64-8A1A-3E2356C812C3' -- PrivacySessionRecordFailure.PrivacyObjectSessionId
  );

-- Target: PrivacyRTBFRequest.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'B31B3895-0398-4CB4-B7A6-9F241F6A848F',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'DE1AB036-4567-48C7-89F9-36CBDAAEADBB' -- PrivacyJobSession.PrivacyRtbfRequestId
  );

-- Target: Problem.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'B505635B-0EF5-4B6D-8E90-A7B6D1977C1F',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '1C1B0918-6FAD-44DB-B8AE-1B2832F74AF3' -- ProblemRelatedItem.ProblemId
  );

-- Target: ProcessDefinition.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'F43CEA6B-1235-4842-95CA-7E2DB358C78B',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'BA06B4E2-53ED-4BCD-9CBB-ADEBC023945D', -- ProcessInstance.ProcessDefinitionId
    '088A99AC-5427-4FAF-9514-A85C476392C0' -- ProcessNode.ProcessDefinitionId
  );

-- Target: ProcessInstance.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '47564865-84E0-4085-9814-3ED12D072BC8',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '92FF46FC-7A90-4E46-862A-9AA203F45290', -- ProcessInstanceHistory.ProcessInstanceId
    'F24D564D-BE4A-4919-8AE7-8DAC90C51642', -- ProcessInstanceNode.ProcessInstanceId
    'F9337966-3DF1-469F-ADA3-B952555A8B0F', -- ProcessInstanceStep.ProcessInstanceId
    'B74B5A3C-ABAA-4BE4-ADEF-9D82A1CB0F6F' -- ProcessInstanceWorkitem.ProcessInstanceId
  );

-- Target: ProcessNode.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '4FC0A858-89C4-4053-A766-CFF1CCC24A5C',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'B11B14BB-C20F-41BE-81B6-BA7BEF248000', -- ProcessInstanceHistory.ProcessNodeId
    '6EB248AB-90CC-41A5-8260-F678E6B3DA35' -- ProcessInstanceNode.ProcessNodeId
  );

-- Target: Product2.Id (36 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '347226DD-D934-4D94-AA14-88F3D58D23B7',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '569A0E32-75C3-4EB7-9480-36FE8DFA4EB0', -- Asset.Product2Id
    '6478ED11-C789-44B8-B633-968A34DDD534', -- BillingScheduleGroup.Product2Id
    'BB76FA6A-8949-457C-AA83-AAEBFCA1DCDA', -- CartItem.Product2Id
    '8471AC89-CF64-4B28-90C6-5ABB7377CABB', -- CommissionScheduleAssignment.Product2Id
    '67E99CB0-6671-415D-B709-E897BA5C083B', -- CreditMemoLine.Product2Id
    'E979BB7B-23E0-446A-9A4D-51917C9330DD', -- FulfillmentOrderLineItem.Product2Id
    '5BFE53EA-1736-4B3D-95E9-332183715C29', -- IncidentRelatedItem.Product2Id
    'A415D42C-4EC6-49F2-8601-175C4F0A6193', -- InventoryItemReservation.ProductId
    '38DC5FD9-8B8A-45D6-964E-9E067CE8E29A', -- InvoiceLine.Product2Id
    '0958DDE5-1C20-4F79-AE3B-35E1C3CD5A05', -- OpportunityLineItem.ProductId
    'DEF2B67B-F61E-4E4A-ABAE-DEB289A75575', -- OrderItem.Product2Id
    '05E4D37E-2553-400E-8C0A-80D0EC9EDD25', -- OrderItemSummary.Product2Id
    '7F9EE4EF-34F1-48B4-85A2-7015C7434089', -- PickTicketProduct.Product2Id
    '7E05E890-7643-496E-BADB-A39336BA1124', -- PricebookEntry.Product2Id
    '449B15E5-602B-4E10-A9E9-0500CE70B619', -- PriceProtectExecLineItem.ProductId
    '4AB6E622-3862-4729-9A37-5CF2915D26A4', -- ProductComponentGroup.ParentProductId
    '67C3A930-677F-47B8-90BA-E89A93980194', -- ProductDetectedPriceChange.ProductId
    '6B049047-DF58-4004-8C98-DAFD9AB76CCC', -- ProductFeaturedProduct.FeaturedProductId
    '880A8DAB-DD36-42D6-A2FD-839A309C2314', -- ProductFeaturedProduct.ProductId
    'B8C1D37B-2695-4954-84B2-1D53E21D5D92', -- ProductItem.Product2Id
    '11D3E694-80B7-43F9-A6A5-048477EE071C', -- ProductMedia.ProductId
    '97894905-35D0-41BF-BA3B-591CA1A1649D', -- ProductQuantityRule.ProductId
    '42A4CF3A-8BAB-4066-A29E-9FD1CFC79AB7', -- ProductRelatedComponent.ChildProductId
    'A13F8B0E-CE8A-4746-A7D0-32CADA286EB0', -- ProductRelatedComponent.ParentProductId
    '93A44AF6-3C35-4998-A321-EDF669DD1342', -- ProductRequestLineItem.Product2Id
    'EB9EF78F-7B73-471E-AE75-CC26DF17B3AC', -- ProductRequired.Product2Id
    'CB4A4C90-ABDF-4EF5-BAC5-B98251C81414', -- ProductSellingModelOption.Product2Id
    'AF32BBD2-379A-4B0C-ADB5-0FEBDB75320B', -- ProductTransfer.Product2Id
    'ECA0EEF2-A782-48D1-9018-867F0A256C5D', -- ProgramProduct.ProductId
    '7C2C4729-C350-4928-9BDA-1AB9605F6AA8', -- ReturnOrderLineItem.Product2Id
    '8D846E8F-5FF3-4F04-B6C9-6BCE519F03C8', -- SalesTransactionItemShape.ProductId
    '23920258-353B-40F5-AA5F-BF7F44508803', -- ShipmentItem.Product2Id
    '9E1E1681-A2A9-48F3-90FA-06FF0301A3B8', -- ShippingConfigSetProduct.Product2Id
    '437A5119-6093-463E-A7C5-744FF4C15C68', -- UsageImpactGroupPgmMeasure.Product2Id
    '7EBCFF9F-47FC-45B1-90DE-17E04EAA414B', -- WebStoreSearchProdSettings.ProductId
    '2CECDBA7-E7E5-4D13-AB9A-472DECFBC993' -- WorkOrderLineItem.Product2Id
  );

-- Target: ProductCategory.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '7F1F2503-65E6-4C19-9340-52ABC068F1E3',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '0DB93D35-612D-4B7F-94BE-8884772F46B1' -- CryptoProdCatgWalletGroup.ProductCategoryId
  );

-- Target: ProductComponentGroup.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '7340BD32-9331-43BE-A263-4CC38D9195B6',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '3A408B5C-FA74-4844-BAD3-DB532BC9C4B3' -- ProductRelatedComponent.ProductComponentGroupId
  );

-- Target: ProductItem.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '79FEFCEE-DB56-40B6-B872-5E4F60271DC4',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '6E1E11A7-9F23-4D6A-980E-B742CD252E0F', -- ProductItemTransaction.ProductItemId
    '0BF28436-4A51-40D6-A478-32CADD45B857', -- ProductTransfer.SourceProductItemId
    '82C637AA-3DB1-4826-A10A-98315E7EE008' -- ReturnOrderLineItem.ProductItemId
  );

-- Target: ProductRelatedComponent.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '6808E1FB-9B79-47E9-AFD1-FBEAB5AA4A78',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '24EBFFAF-B535-40D7-A531-8A928B1C8566', -- AssetRelationship.ProductRelatedComponent
    '3262B559-4DBE-4467-8F0C-6D16571A5803', -- CartItem.ComponentId
    '4482EFAB-0CFA-4963-B455-599F7E6E0D1E', -- OrderItemSummaryRelationship.ProductRelatedComponentId
    'E558D648-0758-4EB6-92CD-DD5A2B30A269' -- QuoteLineRelationship.ProductRelatedComponentId
  );

-- Target: ProductRelationshipType.Id (6 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'E87CFA23-7992-4E0B-8822-191488CA8FC8',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'EE937044-F0EA-4622-A615-936F2A843875', -- AssetRelationship.ProductRelationshipTypeId
    'C8F76C89-8EDC-4C22-AAC2-E20BB305670D', -- OrderItemRelationship.ProductRelationshipTypeId
    'D4E38FDD-D07F-424F-8980-31F0794FCA6D', -- OrderItemSummaryRelationship.ProductRelationshipTypeId
    'C5651AA8-9219-49CC-AB5A-C0558FB0A870', -- ProductRelatedComponent.ProductRelationshipTypeId
    '7DBB75CD-D13D-45B2-98F3-D2754CE1EF85', -- QuoteLineRelationship.ProductRelationshipTypeId
    '8C38954D-232F-4C74-95A8-57005E3735A7' -- SalesTrxnItemRelationShape.ProductRelationshipTypeId
  );

-- Target: ProductRequest.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'CA59EC80-50ED-47DD-AB7C-9A41CE59D478',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '747579D8-AF11-4DFC-A5D3-8D01561D96D9', -- ProductRequestLineItem.ParentId
    'CDFC58EE-3885-46EF-AF35-5B375A91D70B', -- ProductTransfer.ProductRequestId
    'BC665D63-4FC3-495A-A0AD-F3646537CB97' -- ReturnOrder.ProductRequestId
  );

-- Target: ProductRequestLineItem.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '9825A8DE-D8FA-4DE5-BA5B-FEEDA10ED4ED',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '3403C536-4820-42A0-A5A0-3B4F15A709F4', -- ProductTransfer.ProductRequestLineItemId
    '275AF7F5-2B03-4E05-B3D2-FA2646619712' -- ReturnOrderLineItem.ProductRequestLineItemId
  );

-- Target: ProductSellingModel.Id (8 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'D91445EB-9F95-4FBE-B72D-F91C21CE53A5',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '50975525-3EC3-4D52-A129-02ED2D88A06A', -- CartItem.ProductSellingModelId
    '5A0D1246-7BCF-4BAE-A609-8FA4460AC54C', -- OrderItem.ProductSellingModelId
    '246098C2-50E1-4DAD-B89A-215068731318', -- PricebookEntry.ProductSellingModelId
    '4EAEA8DE-9034-448B-B543-DE15B18222E0', -- ProductRelatedComponent.ChildSellingModelId
    'E107DD72-7EAE-4918-A2EA-738405D45F83', -- ProductRelatedComponent.ParentSellingModelId
    'DAD48E3C-40A5-41FD-9863-C61E05C4CD02', -- ProductSellingModelOption.ProductSellingModelId
    '8D21F29A-7F56-43B4-9A2C-D5DA0AADC795', -- QuoteLineItem.ProductSellingModelId
    '9764185F-2495-415A-969E-3855C2F4B66E' -- SalesTransactionItemShape.ProductSellingModelId
  );

-- Target: Profile.Id (9 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'A89D5AFF-2656-45D3-8925-747371C6D159',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '673AD312-F506-497C-9F73-24B4025A8617', -- ActiveProfileMetric.ProfileId
    '5F463102-5707-43F2-A433-0B7C31BB174B', -- MobileSecurityAssignment.ProfileId
    '2F2776F8-A73D-4A2C-B6A3-92BC8FA15BF1', -- Name.ProfileId
    'E51E9E03-BD7D-448A-BEB6-E9F836408944', -- NetworkAuthApiSettings.RegistrationUserDefaultProfileId
    '6603E9D9-797D-4CF0-B091-D310A70244EB', -- OmniSupervisorConfigProfile.ProfileId
    '6DD52A63-DD61-4C45-AF84-3CE52DB0CD22', -- OrgEmailAddressSecurity.ParentId
    '88991B8F-7AB6-4A5C-BCE1-687903ACCFAC', -- RecentlyViewed.ProfileId
    '856CB020-E7F3-46BF-AF89-C72EE46CDCCE', -- User.ProfileId
    '81063954-1C96-4733-85A3-A07CA359B9EA' -- VisualforceAccessMetrics.ProfileId
  );

-- Target: ProfileSkill.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'B057F691-2289-454C-9F20-0FEC4F30923D',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'B09BBD0C-1C3A-4C82-80D4-04B0466858EA', -- ProfileSkillShare.ParentId
    '3DD3EF13-7D08-47FF-8BA1-3DE97F99F3D4' -- ProfileSkillUser.ProfileSkillId
  );

-- Target: ProfileSkillUser.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'FD9061DB-E565-4A9E-9B92-D738CABDF7D6',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'F6829415-532A-40F5-ADE9-1FC613095EAB' -- ProfileSkillEndorsement.ProfileSkillUserId
  );

-- Target: ProgramRebateType.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '4F1022FE-905C-4DF8-9CD9-C730C6B997A3',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '3DDAF564-1FB6-433F-8629-664FC324DB25', -- PriceProtectExecLineItem.CalculationReferenceRecordId
    'F106EC55-1077-42E6-80CB-09C50F85063A' -- PriceProtectionTerm.CalculationReferenceRecordId
  );

-- Target: Promotion.Id (11 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'FF70341B-47CF-46D0-AAB9-C589031B0F71',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '618E6B93-9C17-460E-90BA-3430023BDCF2', -- CartDeliveryGroupMethodAdj.PriceAdjustmentCauseId
    '51A97A1C-49AE-4D46-A4DE-7247DBCFA1DA', -- CartItemPriceAdjustment.PriceAdjustmentCauseId
    '0F659CA8-50FE-43FE-84CF-193E8067C404', -- Coupon.PromotionId
    '0354B75D-E0A5-4020-9149-8B500C040323', -- OrderAdjustmentGroupSummary.AdjustmentCauseId
    'C9AE1D3F-8CF4-4CCE-AB03-C28D0C29704B', -- OrderItemAdjustmentLineItem.AdjustmentCauseId
    '53EEF1C5-256B-4AE6-8FB0-9897F9A6D68F', -- OrderItemAdjustmentLineSummary.AdjustmentCauseId
    '8DF3A3AD-E2D0-45CE-A8B7-D3A5AF1B0A54', -- PromotionMarketSegment.PromotionId
    '00B8C3EC-61B9-4A83-952F-C21F6FC952C8', -- PromotionQualifier.PromotionId
    'EAB1958A-2783-47B7-95FF-72FF82737D8B', -- PromotionTarget.PromotionId
    '7A886477-B8F8-4734-9BD1-DFB6C1F50A05', -- PromotionTier.PromotionId
    'E904DC7C-B263-441F-88F7-69041D64C1EF' -- WebCartAdjustmentGroup.PriceAdjustmentCauseId
  );

-- Target: PromotionSegment.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'C7BCF649-B048-4874-A1D2-09AD0E461E1F',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '3E661954-A057-4703-B679-46788778AA98', -- PromotionMarketSegment.PromotionSegmentId
    '98C87014-1B34-408B-968B-29DD2563A8D1', -- PromotionSegmentBuyerGroup.PromotionSegmentId
    '82AF09E4-4CEA-4C01-BC38-6545B6E9CC48' -- PromotionSegmentSalesStore.PromotionSegmentId
  );

-- Target: PromotionTier.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '010B31F8-13D0-48C1-885A-9CD8D0B3ECDE',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '51D17FC9-7F3C-4706-B268-CE9A265C3B92', -- PromotionQualifier.PromotionTierId
    'C4EEEEB8-ACED-4F6F-A4AE-DF70E456153F' -- PromotionTarget.PromotionTierId
  );

-- Target: Prompt.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '6A82A503-AD6F-4625-8C2A-218D5A070F76',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '998500E4-F80D-4111-87BB-468A22ABA245' -- PromptVersion.ParentId
  );

-- Target: PromptVersion.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '9487C805-2F49-43A2-A13F-18639BE0121C',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '77E316E9-0FE7-454F-BA7E-58DFE45EC611', -- PromptAction.PromptVersionId
    '825915EC-5D0E-4558-BA9B-BE5EE852A50E' -- UiFormulaRule.AssociatedElementId
  );

-- Target: ProrationPolicy.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '8AFC418B-BC53-4FB0-8AE7-58FB5263BCB0',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '06CB9635-7277-4295-A63E-D1A0A41F4185', -- BillingScheduleGroup.ProrationPolicyId
    '654D2F0B-A734-4A02-AF50-6009A3D9AC31', -- OrderItem.ProrationPolicyId
    'A7AFBBF3-F4FF-4AD6-B8DB-B62ECA1A86B6', -- ProductSellingModelOption.ProrationPolicyId
    '0387B3CB-6F0D-4C72-AF48-0016D4062BF7', -- QuoteLineItem.ProrationPolicyId
    '97C0A9E4-0466-49EF-BA3D-E093A23B8739' -- SalesTransactionItemShape.ProrationPolicyId
  );

-- Target: PurchaseQuantityRule.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'DA02B953-3037-43F1-B6DE-F7C67FC9D587',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '1C2A077D-05C4-4EE6-B884-2269692FD97E' -- ProductQuantityRule.PurchaseQuantityRuleId
  );

-- Target: PymtSchdDistributionMethod.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'CC9154A8-6FB9-445C-A219-70D6F124ECEB',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '5640C8CD-F946-4E78-9CA3-13E970BB1E1A' -- PaymentScheduleTreatmentDtl.PymtSchdDistributionMethodId
  );

-- Target: QueueRoutingConfig.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '7AEFE8B4-121B-465D-B61F-AECDF8631072',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'BC4F5FED-829C-4C03-BBCE-A084C2B506F5', -- LiveChatButton.RoutingConfigurationId
    'C5AC74E1-3DF3-4A17-A4AC-D2D89D627BB2' -- ServiceChannel.RoutingConfigurationId
  );

-- Target: QuickText.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '57621B6C-B6D0-4A8C-9543-B4F624A0CC5E',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'FC678045-D271-4CA6-B7DD-76BA179BD29B' -- QuickTextUsage.QuickTextID
  );

-- Target: Quote.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '878E4DBF-6D42-427B-BF61-3D3A2829264E',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '0DAE971B-79B9-4852-B4C5-A0EFFA286131', -- Contract.SourceQuoteId
    '860D8C18-8342-411D-AEB5-5FA93B6899DA', -- PaymentInitiationSource.QuoteId
    '645A3C83-39A7-4811-AF4E-AFCB9CEBD695', -- QuoteAction.QuoteId
    'B0E43B9D-11D7-4C97-89C3-7C6B784A27A2', -- QuoteAdjustmentGroup.QuoteId
    'AFC21C03-C4B3-4365-B14E-22E8BF526A4D' -- QuoteLineRelationship.QuoteId
  );

-- Target: QuoteAction.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '9E40FE8A-271D-426E-90CE-7F6CE4010EE1',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'BE7FA83A-D0C9-42C9-9B3D-8AC7BD9BE444' -- QuoteLineItem.QuoteActionId
  );

-- Target: QuoteDocument.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'AC325AF8-2191-471F-B02D-5CFB42BAC5B6',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '204C4393-D420-406D-AB6C-EA430E6C018E' -- DocumentRecipient.QuoteDocumentId
  );

-- Target: QuoteLineGroup.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'CA18551B-CBD5-44C6-8A7B-A082B20670BF',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '02A35046-787B-484C-AA98-B27144FCB911' -- QuoteLineItem.QuoteLineGroupId
  );

-- Target: QuoteLineItem.Id (6 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '0C46D01E-801F-4AE5-BAB2-366269D7DB11',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '640E1F48-DA21-4CFE-9FD0-FF65D5246B2D', -- QuoteItemTaxItem.QuoteLineItemId
    'C91D84C4-8A0E-4F3F-9FD5-D89B91A15C47', -- QuoteLinePriceAdjustment.QuoteLineItemId
    '6782A021-428D-4036-83EE-92AA9C5C1CAB', -- QuoteLineRelationship.AssociatedQuoteLineId
    '03C160EA-59E5-4D45-B382-3E308BE80161', -- QuoteLineRelationship.MainQuoteLineId
    '2B4C4667-8C57-4946-A6BD-03EF40B6EF11', -- QuoteLineRelationship.RootQuoteLineId
    'F95662A2-854E-493B-8DB3-377140D85F51' -- QuoteLineWorkSource.QuoteLineItemId
  );

-- Target: QuoteLineItemRecipient.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '66A0A4F0-E7FB-4DF5-80EA-FD985458D287',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '082CB525-C2E1-46C1-967B-517F86BDC0A1', -- QuoteLineItem.QuoteLineItemRecipientId
    'F654F706-852B-4236-B270-2DCD6B9EC9F0' -- QuoteRecipientGroupMember.QuoteLineItemRecipientId
  );

-- Target: QuoteRecipientGroup.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '0A64B911-7904-469C-9E78-021A2349D920',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'E2A3BC81-5BF3-41FC-989D-263D1653FE41' -- QuoteRecipientGroupMember.QuoteRecipientGroupId
  );

-- Target: RecordsetFilterCriteria.Id (8 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '9D937C39-6D66-42F2-A2B9-7B2C7EFC5DBA',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '48DB5153-CD3E-4B02-BFB6-EC3430A2D741', -- ApptBundleAggrPolicy.FilterCriteriaId
    'AF80037C-E92C-4753-9D97-B5B60D7B8A8D', -- ApptBundleConfig.CriteriaForAutoUnbundlingId
    'C2814295-5888-4A42-988F-7511E1DFF435', -- ApptBundlePolicy.FilterCriteriaId
    'F3D00E66-3BC8-4D98-828B-CEA456245DF0', -- ContractLineOutcome.RecordsetFilterCriteriaId
    '01BF3FAB-9C33-4891-8783-584A292A27CD', -- RecordsetFltrCritMonitor.RecordsetFilterCriteriaId
    'F3213B92-9486-468F-B0E2-9E768B1BBD9C', -- Shift.RecordsetFilterCriteriaId
    '968D57C9-2CC7-4DF0-A00C-9D2E87555086', -- ShiftTemplate.RecordsetFilterCriteriaId
    'D31F70D9-7886-43FE-893A-6B4538811CDD' -- TimeSlot.RecordSetFilterCriteriaId
  );

-- Target: RecordType.Id (8 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '9717CE32-4460-4837-AD47-4060D6821521',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '335843A4-D47F-410F-8193-942A6BB915A3', -- Asset.RecordTypeId
    '46581A6B-C7D8-4028-B390-BC3E8B8D6B21', -- BuyerGroup.RecordTypeId
    '2CB52786-5B64-4A16-8A8A-99D40D6701DC', -- Campaign.CampaignMemberRecordTypeId
    'E47F7E4C-6F81-4912-9AD2-EC6CC8826CD5', -- GtwyProvPaymentMethodType.RecordTypeId
    '9EB0817F-F3EB-4FB5-8E24-B6DF3FCDA883', -- Idea.RecordTypeId
    '8F00FFA1-D4F7-4593-B2A9-8935469BA171', -- MessagingLink.RecordTypeId
    '19BC9C5C-BC29-4F05-99AA-046D60F9B5FB', -- PromptVersion.TargetRecordType
    '8C399DCF-2C36-4E20-86C8-C53296F58B08' -- VoiceCall.RecordTypeId
  );

-- Target: Refund.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '5C75A31D-42D9-42EA-BEB6-5FBF872A2146',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '12C98EDF-E063-4324-B993-FA02520EB597' -- RefundLinePayment.RefundId
  );

-- Target: Report.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '55F85D6F-0338-47EF-B519-94036110C21A',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '64E3DF25-D949-4F16-8488-A31B93D60EF2' -- ScorecardMetric.ReportId
  );

-- Target: ReturnOrder.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'BEA4EDF4-4C56-4095-A1E8-67282B3FC73B',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '1039697B-F0B1-4757-8DF4-5CC8C5DEC9E7', -- PaymentCredit.ReturnOrderId
    '0DA36358-098F-4220-8414-D08DD1FEA83F', -- ProductTransfer.ReturnOrderId
    '43BCC1E3-2DD2-4684-9806-3940D563AD21', -- ReturnOrderItemAdjustment.ReturnOrderId
    '0F89C6E9-8932-495A-AEEC-DCD8B50F1696', -- ReturnOrderItemTax.ReturnOrderId
    'C8EF3DED-FA04-4ED5-B155-FE1AF6A16AB4' -- ReturnOrderLineItem.ReturnOrderId
  );

-- Target: ReturnOrderItemAdjustment.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '01850EE5-B780-49E3-B83E-E703DC72D31C',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'BB6EB803-BDFD-4754-89A5-3B7C3C437655' -- ReturnOrderItemTax.ReturnOrderItemAdjustmentId
  );

-- Target: ReturnOrderLineItem.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '5762496E-DEDB-49BA-86C0-792DE662644C',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '047F74A9-927D-4DD6-874F-55AE03FCD2F9', -- ProductTransfer.ReturnOrderLineItemId
    '9FFE416F-586C-4A9C-8BCD-7CD2113360C3', -- ReturnOrderItemAdjustment.ReturnOrderLineItemId
    'E02B9DE7-9799-4CDB-996F-946A13DFD135' -- ReturnOrderItemTax.ReturnOrderLineItemId
  );

-- Target: RevenueAsyncOperation.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'F0351145-71C7-4BD9-93BC-0B225FD3490F',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '1B07C7C8-5588-4B5B-94F4-4C1429A8257B' -- RevenueTransactionErrorLog.RevenueAsyncOperationId
  );

-- Target: SalesChannel.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '2B391D98-1283-4D49-B545-3FB0A073854B',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '62437E28-3CDF-4F6E-81CB-41D5BF5E0307', -- OrderSummary.SalesChannelId
    'B96137D4-28BD-42EB-AE12-401762F64FE5' -- PendingOrderSummary.SalesChannelId
  );

-- Target: SalesforceContract.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '61372FFB-4A27-41A5-A50C-092BBC442F68',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'F36B718C-5911-4609-990F-2C4342B7C42E', -- SalesforceInvoice.SalesforceContractId
    '5E33FDE1-D49A-490F-B7F6-FF2623F2A1CA' -- SalesforceQuote.SalesforceContractId
  );

-- Target: SalesTransactionItemShape.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '814DB6B4-567C-4E00-80DA-3A3A990ECA6F',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'B6C83436-D0D3-4972-A3ED-777260A923A6', -- PriceAdjustmentItemShape.SalesTransactionItemShapeId
    '3D76F31C-243E-4F49-B316-4FEAE5BEA0C8', -- SalesTrxnItemRelationShape.AssocSalesTrxnItemShapeId
    '5D228733-3FD5-4854-B316-65011D190188' -- SalesTrxnItemRelationShape.MainSalesTrxnItemShapeId
  );

-- Target: SalesTransactionShape.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'BF0AAA0B-F0C8-4455-89E3-9F70EB3837DE',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '0618FAA7-B76A-4555-A2DA-D1E4E5009B13', -- PriceAdjustmentGroupShape.SalesTransactionShapeId
    '44D9C7EC-A37F-4BBD-8A0B-1E4B62906B49', -- SalesTransactionItemShape.SalesTransactionShapeId
    'E106D81C-3AEC-480A-A02D-5F7D40978985' -- SalesTrxnItemRelationShape.SalesTransactionShapeId
  );

-- Target: SavedPaymentMethod.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '4EC8344A-F7DB-421E-9721-C50634449D35',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '700F2484-B5F0-40B0-91D8-90F4A7EC4FB6', -- AlternativePaymentMethod.SavedPaymentMethodId
    '5B078967-176D-46EF-B30A-3AACFE8695DB', -- CardPaymentMethod.SavedPaymentMethodId
    '2CB41340-94DB-4714-BB7E-9FBAA91AA8F9', -- DigitalWallet.SavedPaymentMethodId
    'D9A7143E-B8F6-42FA-8B83-28AD59E0F892', -- PaymentMethod.SavedPaymentMethodId
    'D172F083-A21F-44DE-B504-7D12D23FE521' -- SavedPaymentMethodEvent.SavedPaymentMethodId
  );

-- Target: SchedulingAdherenceSummary.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'B986F69C-641E-4764-ACFF-418692514F03',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '075516BE-72C8-4D27-A74D-1A6DCC2514CF' -- SchedulingAdherenceDetail.SchedulingAdherenceSummaryId
  );

-- Target: SchedulingRule.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'EE7C8AD8-D88C-4D49-A40F-B7E4464CF5AC',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '11D71D54-65D8-4E3D-83EF-D1B931135CC0' -- SchedulingRuleParameter.SchedulingRuleId
  );

-- Target: Scorecard.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '5953A1D7-05E4-4313-BD01-AF70319B6E68',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'B96D8792-FFB5-4DE0-956E-1A0623E50A6A', -- ScorecardAssociation.ScorecardId
    'AD0DCB80-02AF-4FCD-9EA3-7719346E35C6' -- ScorecardMetric.ScorecardId
  );

-- Target: ServiceAppointment.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '2E076A10-F02E-461D-AD43-03BE8CF9F7CE',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'F9FCA27E-AF3E-4885-8A47-40C277E76575', -- AssignedResource.ServiceAppointmentId
    '97C8497E-07E0-4A01-A834-F002E1DE4AE2', -- FldSvcObjChg.ServiceAppointmentId
    'FA69947B-C8C3-442A-AA78-1160E35C47EC' -- GeolocationBasedAction.ReferenceRecordId
  );

-- Target: ServiceChannel.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '3A4B8ADE-66E4-40C1-919B-C3B1E60B8F93',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '0A543485-F9CF-4B88-88D7-00CD0D546612', -- AgentWork.ServiceChannelId
    'DABA9A5D-D1FF-4E1D-9F99-334019D65C17' -- WorkDemographic.ServiceChannelId
  );

-- Target: ServiceContract.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '00B12450-D73E-4741-A466-A77B3EF61DA6',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'E5212F25-033E-4107-9AAC-0F3579C1FB5B' -- ContractLineOutcome.ServiceContractId
  );

-- Target: ServicePresenceStatus.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '52BE5445-B0DA-4150-B5AC-258F58FB7439',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'A70719DD-3BD9-4C1C-8564-BC643E93C189', -- SchedulingAdherenceDetail.StatusId
    '1DD5D351-42E6-4421-83D9-051BAB558E79', -- ShiftSegmentType.ServicePresenceStatusId
    'B822D1E5-1BEB-4AA6-ACE8-0B9F3FFDC4B3' -- VendorCallCenterStatusMap.ServicePresenceStatusId
  );

-- Target: ServiceResource.Id (11 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '10FE417E-6915-48A8-9D5A-BFA95776D4DD',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'A9ED281B-AF35-427A-A779-FBE8DF11AF53', -- AppointmentScheduleAggr.ServiceResourceId
    '1CBD3598-D135-4C57-8041-D21E93BFD439', -- AppointmentScheduleLog.ServiceResourceId
    '9A8271F0-B49F-4B76-B24E-FD1F8BDBA060', -- AssignedResource.ServiceResourceId
    '60B6FE1F-35E7-408B-BCB5-CE3E62C1CB9A', -- ResourceAbsence.ResourceId
    '8C9EC924-B8E2-4A8F-91BE-74048FAD3802', -- ResourcePreference.ServiceResourceId
    'CFA7631B-D8C3-4403-9702-768C71EE415F', -- SchedulingAdherenceSummary.ServiceResourceId
    'BAF637AE-0C04-4CC9-9B7E-E7AC9389FF17', -- ServiceResourcePreference.ServiceResourceId
    '96D394C0-FE73-42BF-978B-CEA06AC87454', -- ServiceResourceSkill.ServiceResourceId
    '17C9B621-C73A-4E0D-9357-F83167C54EDB', -- ServiceTerritoryMember.ServiceResourceId
    '23FB6492-83F8-4E36-A8FA-33F62A362661', -- Shift.ServiceResourceId
    'C47899CA-C2D7-458D-8634-EA5488647427' -- SkillLevelProgress.ServiceResourceId
  );

-- Target: ServiceTerritory.Id (12 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '1CE42919-60FF-45A2-ABD7-052D8B718B4A',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'E290CA41-A81E-4840-88D3-C2BA38A0488D', -- ApptBundlePolicySvcTerr.ServiceTerritoryId
    '736EE1C0-7B7C-43E0-90C8-C0B980480E1A', -- SchedulingAdherenceSummary.ServiceTerritoryId
    '890897FB-A656-4139-8F5D-E1C09C5F99CC', -- ServiceAppointment.ServiceTerritoryId
    'E0880A66-7736-4E13-B67C-12124BAA5C43', -- ServiceTerritoryMember.ServiceTerritoryId
    'A2D2E4C1-F0B6-404F-81DD-533E6E7C2999', -- ServiceTerritoryWorkType.ServiceTerritoryId
    '858BE831-6A94-4A12-BF7A-A2DA6A866AF8', -- Shift.ServiceTerritoryId
    '3390DE20-5117-43D9-B135-F24CC30915E2', -- WorkCapacityAvailability.ServiceTerritoryId
    '7E09FEF0-F024-4CEA-9615-A4A141A96DBE', -- WorkCapacityLimit.ServiceTerritoryId
    '00ACCDEF-AFCB-4DE9-B400-BD8541562EEF', -- WorkCapacityUsage.ServiceTerritoryId
    '17488A50-70C6-423F-A833-46A64CD0AE50', -- WorkDemographic.ServiceTerritoryId
    '0678022C-8C0C-47F5-B1BF-78B23E18C6ED', -- WorkOrder.ServiceTerritoryId
    '11FFDAAB-EE2C-4160-AEDE-B57D178FDC4B' -- WorkOrderLineItem.ServiceTerritoryId
  );

-- Target: SfdcCustomerForPartner.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '0C9AB66E-105E-466B-B441-B60E7A3390DA',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '9F629DC8-E8A7-4686-A159-521E745714ED', -- SfdcPartnerOffer.CustomerId
    '5CF5833C-5DB5-4DAE-A40C-9B46C1A2F89E', -- SfdcPartnerOrder.SfdcCustomerForPartnerId
    'BFB075A3-FE99-4DEE-9062-FBEFDCE71CE1' -- SfdcPartnerTenant.CustomerId
  );

-- Target: SfdcPartnerOffer.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '8AA1F620-9B05-4C0B-8F45-DEAC63804C62',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '9D2DF110-A318-4375-A0D7-B8E0FFB6C961', -- SfdcPartnerOfferItem.PartnerOfferId
    'D740B487-712D-431D-9E15-0CE645AE39B1' -- SfdcPartnerOrder.OriginatingOfferId
  );

-- Target: SfdcPartnerPackage.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '131314AE-914B-4F93-96D6-18699BDB3B30',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'ACB6FAFD-D967-4030-8AB8-4B7AD8D9CA65' -- SfdcPartnerTenantPackage.PartnerPackageId
  );

-- Target: SfdcPartnerPackageVersion.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '4940DECF-C7D0-4FDF-8429-119A5F02B641',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '1BFA6D67-04D5-4EF6-981A-1C1160780FAA' -- SfdcPartnerTenantPackage.PartnerPackageVersion
  );

-- Target: SfdcPartnerProvisionProduct.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'DB4FF0E4-B518-4A7D-A475-5655EC2E75CF',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'FA0D7B78-F1F5-432B-A8E9-2B4D11D9DE0A', -- SfdcPartnerOfferItem.PartnerProvisionProductId
    'FF5DC4CB-37EA-43C5-B910-50712E99A2A3', -- SfdcPartnerOrderItem.PartnerProvisionProductId
    '08530669-D118-42BD-B8B7-3742C66D1A9F' -- SfdcPartnerProductLicense.PartnerProvisionProductId
  );

-- Target: SfdcPartnerTenant.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '04C17BC7-69B0-44B2-9989-1AF3DAB3E2EA',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '2890ED9E-EC31-4246-86BE-293918F7D4E8', -- SfdcPartnerOrderItem.PartnerTenantId
    'A129B8B3-C6A5-453B-BF2F-97E794C97A37' -- SfdcPartnerTenantPackage.PartnerTenantId
  );

-- Target: SfdcPartnerTenantPackage.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '4927E45C-BF71-4CDF-9937-D81158CD7DB0',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'EA4DE46B-5C5C-434A-B34D-39AC89BFF5A8', -- SfdcPartnerTntPermSetLic.PartnerTenantPackageId
    '5D1A1D06-C9E6-4DE3-A228-3B08323CE9C4' -- SfdcPartnerTntPkgLicense.PartnerTenantPackageId
  );

-- Target: SfdcPartnerTermSet.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'EFEF4DDF-D20E-401F-AA18-7B920801F627',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'B15805CA-D93E-4DD6-AB69-C298422BAF74', -- SfdcPartnerOffer.PartnerTermSetId
    '76224E96-2C4D-47D9-9471-96C7ABE2305F', -- SfdcPartnerOrder.SfdcPartnerTermSetId
    '2CC2249C-AB86-4C72-9B6A-DF17F3E21110' -- SfdcPartnerTermSetProduct.PartnerTermSetId
  );

-- Target: SfdcPartnerTermSetProduct.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '65F95435-6A45-4880-8AC8-63C094399F0B',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '9E01750B-1EEE-46AA-822D-C04258482086' -- SfdcPartnerProvisionProduct.PartnerTermSetProductId
  );

-- Target: Shift.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'D2BBA36D-C5E1-4D90-BE78-122A34720E23',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '43E4C36A-9177-4CD1-99C7-1C1984B939F6', -- ShiftHistory.ShiftId
    '9BED76D4-4D6E-47D9-BCF9-F7D6E6056001', -- ShiftSegment.ShiftId
    '9DE1BFD2-F791-42D8-8335-4D035C6BF133' -- ShiftShare.ParentId
  );

-- Target: ShiftPattern.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '9D6CAB38-2B23-4F29-A15A-4B2776555AF0',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '7A148144-5EF4-42D5-ABE0-1653D32EF152' -- ShiftPatternEntry.ShiftPatternId
  );

-- Target: ShiftSegmentType.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '654EC418-EE95-4AFC-8EAD-9BD08C6FC90C',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'DDC80B18-B9B3-4FC6-B0AC-1143039E0CC7' -- ShiftSegment.SegmentTypeId
  );

-- Target: ShiftTemplate.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '7267F25C-3984-48B7-9582-8ED2C2F134A9',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '03E29BFB-6698-4D9D-8D94-2AFBD43E31E1', -- Shift.ShiftTemplateId
    'E507E0FF-0A89-46C1-BC8B-38032383F25A', -- ShiftPatternEntry.ShiftTemplateId
    'B81363D4-1EF6-4F40-A0CF-C7BF46546600' -- WorkforceCapacityUnit.ShiftTemplateId
  );

-- Target: Shipment.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '5BABF750-92BF-4AC8-BEDC-24B748BF9127',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '9C57B734-6496-4745-9AB1-348FD082A094', -- ProductTransfer.ShipmentId
    'CA48E365-F05D-44B2-BB75-4E2E3C2EFE38' -- ShipmentItem.ShipmentId
  );

-- Target: ShippingCarrier.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '0281E873-9C37-4A09-94D8-3748235F1B5C',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '6E0F591A-DA49-4317-90CF-6F76F4EDC6DD' -- ShippingCarrierMethod.ShippingCarrierId
  );

-- Target: ShippingCarrierMethod.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'D6A7612F-E2DF-48FE-894D-6A980F004F4C',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'ED40CC07-FCFF-4164-A16B-654BE2024275' -- StandardShippingRate.ShippingCarrierMethodId
  );

-- Target: ShippingConfigurationSet.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '493CC2C1-D7C1-4209-A1B9-BCDE98827C02',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'DAAC6C5D-8C6E-4133-B526-AE189D45576A' -- ShippingRateGroup.ShippingProfileId
  );

-- Target: ShippingRateGroup.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '2A224877-153B-4886-8F0D-5CF39DD60D07',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '565A02D6-C348-4BD2-A32B-92609B45E565' -- ShippingRateArea.ShippingRateGroupId
  );

-- Target: Site.Id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '6DC9A233-DFAD-4A07-B204-66FA3C7B4692',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '67A8BA61-FAB6-43E2-9974-CEE521536E7E', -- DomainSite.SiteId
    '5193FB84-78D5-4D29-8272-2D47D05A9CFF', -- LiveChatButton.SiteId
    '3B13B543-8337-4F6D-B20C-C0B903A58291', -- PaymentInitiationSource.SiteId
    'B728AB64-9837-4099-B066-144E517BF654', -- PromptVersion.ExperienceContextId
    '55E547D5-F349-47DC-B30E-3B2CD0A01EBD', -- SiteHistory.SiteId
    '2D070B46-6E72-4281-A62D-BD93EE8640BC', -- SiteIframeWhitelistUrl.SiteId
    '58CF9B84-373E-4470-AD8D-6CD2A77B1B56' -- SiteRedirectMapping.SiteId
  );

-- Target: Skill.Id (6 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'E808EBBF-A99A-4E4D-B006-18C5DB00D110',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '4D82D90E-249C-460A-AD32-DA580651754B', -- LiveChatButton.SkillId
    'BE26F2F3-1093-4BB7-A8EF-63A90A89E8CD', -- MessagingChannelSkill.SkillId
    '5D5B9506-08E1-4493-B716-2BDD0C338966', -- OmniSupervisorConfigSkill.SkillId
    'EBD11957-6C00-48DB-A090-9136ABA307DA', -- ServiceResourceSkill.SkillId
    '481BC029-9759-4B89-822D-2067AB257F2C', -- SkillLevelDefinition.SkillId
    '9B7938BC-5F2C-4C8A-9D45-FA3AD2937217' -- SkillRequirement.SkillId
  );

-- Target: SkillLevelDefinition.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'E26EF53B-5F99-4203-936E-03395AF421BD',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '9B29D2EC-4ECF-4D63-85AD-0378052EEF13' -- SkillLevelProgress.SkillLevelDefinitionId
  );

-- Target: SocialPersona.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '95E51F55-A411-4E3C-9FC3-4F4CFE6A7030',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'BEE6795D-60C9-4814-9A8C-777C19ABD267' -- SocialPost.PersonaId
  );

-- Target: Solution.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '72E84C2F-203C-4E10-90FF-63E10D51E701',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '05A68C8B-E5D6-47BC-B521-7842CB309AFE' -- CaseSolution.SolutionId
  );

-- Target: SourceCodeRepoProvider.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '39B442C1-ECDC-4936-8A4C-7141BF34F35F',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'F1516196-26B7-4137-BB0D-5A95AD31D3CF' -- SourceCodeRepository.SourceCodeRepoProviderId
  );

-- Target: SourceCodeRepository.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'F8D38DF3-3B78-4CBC-93F9-9C2627B328EF',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '1A40EE2F-6770-4EF6-A3A6-11DB915D9AA2' -- DevopsPipeline.SourceCodeRepositoryId
  );

-- Target: SourceCodeRepositoryBranch.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '17830B49-067D-4E72-869E-4CE5A250B5A4',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '2049FA06-F810-4453-8E95-6A2B7DF0A46B', -- DevopsPipelineStage.SourceCodeRepositoryBranchId
    '1395BD26-16E0-4D0E-9E7B-744BA873AF64', -- DevopsPipelnStgPromWkItem.MergeSourceBranchId
    '08F4337F-F980-4553-AF7B-481A5CF6F670', -- WorkItem.RebaseBranchId
    '1FBF7203-ECB3-4199-9A30-C8C68732E1C5' -- WorkItem.SourceCodeRepositoryBranchId
  );

-- Target: StagedInviteeEmail.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'CB522A46-4C70-4B85-AA1D-C9C3E2023E17',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '2B343E60-2494-4A60-AF33-97F1CBE0491B' -- EventStagedInviteeEmail.StagedInviteeEmailId
  );

-- Target: StagedUnmtchdEmailAddr.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'D3632F3D-B3F7-4286-9E12-498A02EC66C7',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '103FEB71-AA28-46D9-9917-CBE2B03917B5' -- StagedUnmtchdEmailAddrRela.StagedUnmatchedEmailAddressId
  );

-- Target: Stamp.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '6F533621-0868-4640-9BF8-BA97E9BFFEA5',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'BD503600-6E5A-4B5E-B3CF-04F66C8562C8' -- StampAssignment.StampId
  );

-- Target: StaticResource.Id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '7D72B7C5-42F6-4369-AF64-DFD6C504E6F6',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'CE4CFB47-57BB-4576-8C86-5CB1B09F19D8', -- ConversationChannelDefinition.CustomIconId
    'C8BFFD90-0D94-4D15-9B74-663B8D01C1DF', -- ConversationVendorInfo.CustomIconId
    'B56F97B8-2A5A-494D-BE9A-692EA436E5AE', -- LiveChatButton.InviteImageId
    '60EEA312-298C-40BC-9281-936EACACE074', -- LiveChatButton.OfflineImageId
    'F1011D2C-9E8B-4E66-8D6A-06D3D08B120A', -- LiveChatButton.OnlineImageId
    '7D2CC0D7-4C45-407B-AD66-E95B05DB94CC', -- PresenceUserConfig.CustomSoundId
    '8B2C212F-2F35-4D9C-BE39-8C58A39FB928' -- ServiceChannel.CustomSoundId
  );

-- Target: SurveyResponse.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '454CD5B0-5711-4152-9479-E4E8A9CCD331',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '36B2DF92-5F7C-4590-A829-81E4C77D61C7' -- KnowledgeArticleFeedback.FeedbackResponseId
  );

-- Target: SvcCatalogCategory.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '0FD2F5BF-2487-4EFE-B744-F86A10F3DBDA',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '9F534630-B058-406B-859D-E0FD7FF6E0E5' -- SvcCatalogCategoryItem.SvcCatalogCategoryId
  );

-- Target: SvcCatalogItemDef.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '61818B96-F9F1-4058-91E3-D913279B8DC9',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'DBEB3F00-2602-421B-A861-2FFACE5AAA51', -- SvcCatalogCategoryItem.SvcCatalogItemDefId
    'A2CEAFD1-6D2E-4842-BAA6-D7BA00BD978E' -- SvcCatalogRequest.SvcCatalogItemDefinitionId
  );

-- Target: SvcCatalogRequest.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'B248821A-20B0-4EBE-81F0-2F16FA7273B8',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'C67705AD-3E00-4525-BA46-07B311FDA10A' -- SvcCatalogReqRelatedItem.SvcCatalogRequestId
  );

-- Target: Swarm.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'C7103947-5E18-404B-9747-B1C130ADFB09',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'E343357A-A897-45CD-A3AA-042B1AE4CED7' -- SwarmMember.SwarmId
  );

-- Target: Task.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '22BFB18C-4946-4A40-A5D5-2CCBCDA75DC5',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'D486314A-0CD2-450D-9C82-04CDBF4734C0', -- EmailStatus.TaskId
    '061E5B26-2C14-4B05-9673-2C57AB052F3E', -- ListEmailSentResult.ActivityId
    '4A4E8282-18CC-4C15-9306-3B58A6C29FA6', -- UnifiedTask.DetailId
    'D0C07BE9-89D9-471E-A745-85C40A8BB414' -- VoiceCall.ActivityId
  );

-- Target: TaxEngine.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '8CF94404-5CD1-4D7E-8E5C-77B0C29A7B9C',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'F8876718-D7B0-4376-980D-767D4AC98763', -- TaxEngineInteractionLog.TaxEngineId
    '8274D773-689A-4A6B-865A-BF27753D8D2B' -- TaxTreatment.TaxEngineId
  );

-- Target: TaxEngineProvider.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'EF23CE50-0914-4709-8BFC-69645179DE4D',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '437237E6-80D3-4C18-8AB2-840C9084230D' -- TaxEngine.TaxEngineProviderId
  );

-- Target: TaxPolicy.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '4141C61D-098A-497F-820F-E7A8E72BA17D',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '7C8E1C33-5CC3-4ABA-A151-6982271044BD', -- Product2.TaxPolicyId
    '92496C4E-82D4-4FA0-A6F8-35754ABD3816', -- TaxTreatment.TaxPolicyId
    '9A4B42AD-5F21-4E6A-A1F2-785A827A9D28' -- WebStore.DefaultTaxPolicyId
  );

-- Target: TaxTreatment.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '16081B66-4AA5-498B-9124-27C444088AF0',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'B631656C-4A3D-4E40-A232-E77BA081AB6B', -- BillingSchedule.TaxTreatmentId
    'F86A13EB-834B-49A2-B130-089C980D2619', -- CartItem.TaxTreatmentId
    '8F3B0216-BAF4-4964-9B4D-07BDA284CCB7', -- OrderItem.TaxTreatmentId
    'D8CB74EF-29A7-4224-9BF2-D1C09C150CEC' -- OrderItemSummary.TaxTreatmentId
  );

-- Target: Territory2.Id (10 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'A47BB9BD-09AA-4FAF-9487-652B253F6A04',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'E8A63F24-F51A-4190-92BA-FF3712FD1B5D', -- ForecastingSrcRecJudgment.Territory2Id
    'E42B583A-A465-439D-B2A7-137045F1F466', -- ForecastingSubmission.Territory2Id
    '2E579F81-0CBF-4809-B9B8-72E40FD1CDAF', -- ObjectUserTerritory2View.Territory2Id
    '8AFFF503-B359-4E6F-B2B8-F4A572BDF2E6', -- OpportunityLineItemSplit.Territory2Id
    '4C1FCB41-36D9-47D5-8A06-2A976273AA45', -- OpportunitySplit.Territory2Id
    '39177AC4-7D32-4AE8-A22A-CEFC38D4005C', -- Territory2AlignmentLog.Territory2Id
    '80F72F76-049E-4A66-A50A-8C7055B26594', -- Territory2ObjectExclusion.Territory2Id
    '80BF614C-E3D5-4B65-92F0-69433AC5289B', -- Territory2ObjSharingConfig.Territory2Id
    'E855EFED-0FEF-4D69-87D0-C709270586DC', -- TerritoryAdminAssignment.Territory2Id
    '6B89CBF5-3D58-4143-8994-A44D9A68C1F8' -- UserTerritory2AssocLog.Territory2Id
  );

-- Target: Territory2Model.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'E5001C29-8E64-46D5-B226-FD4275F1D4D5',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'A8499524-0ED4-4F9F-BED6-6A0FBF081D5B', -- Territory2AlignmentLog.Territory2ModelId
    'C2E9CEB5-C58C-4AB5-8630-958E4D54E1EE', -- TerritoryAdminAssignment.Territory2ModelId
    '1BC3B06F-BDC8-415D-AFF0-BC4BC5526B94' -- UserTerritory2AssocLog.Territory2ModelId
  );

-- Target: TerritoryMgmtObjectConfig.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '392D2CCA-4A97-4BC3-8689-AA944270A824',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '219D73BF-8EFC-432C-A7F8-28D5A73BD8D4' -- Territory2ObjSharingConfig.TerritoryMgmtObjectConfigId
  );

-- Target: TimeSlot.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '9FC7D7A9-A203-4614-921E-192D62A627DE',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'DD2E900C-A3C8-4A3D-9E8C-15A957F5E326' -- AppointmentTopicTimeSlot.TimeSlotId
  );

-- Target: Topic.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '3E9229A8-0E8D-4E41-9A16-5716EB2865F3',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'F05EFBD7-949D-4774-8A83-A7ACA4D4BED2' -- TopicAssignment.TopicId
  );

-- Target: TravelMode.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '4E3AE63C-C1C2-41C7-BAE2-7B8E2476CEF7',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '4BA84D56-F68C-4C2F-8896-2520DEB51D0F', -- ServiceTerritory.TravelModeId
    'EAD22A69-BCDB-49DC-8AE3-B714FC81505E' -- ServiceTerritoryMember.TravelModeId
  );

-- Target: UiFormulaRule.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'E2A9B216-618D-475F-9396-BFE1C8BCD0C6',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '125421E6-4AA1-4500-AE8F-77BAF77D1020' -- UiFormulaCriterion.RuleId
  );

-- Target: UnifiedActivityInsight.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'E32715D6-7321-4581-A26D-EDEC8E17B255',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '3424B96C-476C-475F-8260-A0D3604B0290' -- UnifiedActvtyInsightKeyword.InsightId
  );

-- Target: UnifiedEmail.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '844DDEA0-E5BB-4B34-983D-8E179C9CF6FE',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'F0BA83B7-BB5D-4CB4-A2BD-A37770E7FF65' -- UnifiedEmailParticipant.ActivityId
  );

-- Target: UnifiedMeeting.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '57BA5D08-405A-445D-BDF4-BAD3E5535A5C',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '4DA855A3-CD87-4473-B2F4-8D990F44A1CC' -- UnifiedMeetingParticipant.ActivityId
  );

-- Target: UnifiedTask.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '2BC8357E-4205-4CCE-8DE3-A68D8AC69C4B',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '0443C30B-5182-418B-A412-524ECA1ED3B6' -- UnifiedTaskParticipant.ActivityId
  );

-- Target: UnifiedVideoCall.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '866F4A31-8F6F-40FA-8C5A-A4576BEC7C10',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '5FF4EB22-A4B6-4B72-837D-1717D078501D' -- UnifiedVideoCallParticipant.ActivityId
  );

-- Target: UnifiedVoiceCall.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'A191041D-342A-4F28-AE45-E64C7BAE8D56',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '9E8AB23A-48F3-4A74-9381-8381BF4F8011' -- UnifiedVoiceCallParticipant.ActivityId
  );

-- Target: UnitOfMeasure.Id (8 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '35435653-E1C1-4E6B-8DA7-664CCA3F39AA',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '6A00AB39-4E7F-4547-89DD-446026FE4009', -- AssetRateCardEntry.RateUnitOfMeasureId
    'C4235797-16FA-45FF-8E2A-CF82105BD2AE', -- AttributeDefinition.UnitOfMeasureId
    'DE1FF554-8E4D-4EBE-934D-229459375C9E', -- AttributePicklist.UnitOfMeasureId
    '123065C7-1A2D-4561-8CA9-A9E6CD460ED7', -- CartItemAttribute.UnitOfMeasure
    'B883D387-A2C7-4A30-84CF-4F898B1629F5', -- Product2.UnitOfMeasureId
    '2030BDB1-2064-413A-A7BA-F23905C8B914', -- ProgramRebateType.UnitOfMeasureId
    '96957128-E196-4C6C-A84F-BAF9CB8AF4EB', -- QuoteLineItem.QuantityUnitOfMeasureId
    'C2D28F50-5C3D-4A4E-BC3D-0A59D73BF806' -- UsageImpactGroupFactor.UnitOfMeasureId
  );

-- Target: UsageImpactFactor.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '45F82670-C00B-46EE-BEA3-8D2057E20FCF',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '586D650F-2F03-4B98-9970-026285E2D6FF' -- UsageImpactGroupFactor.UsageImpactFactorId
  );

-- Target: UsageImpactGroup.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'C439114B-55BC-4304-B26A-07FC0DDD2AFC',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'CA76B0D5-852A-4A34-8AB6-1A1037164E45' -- UsageImpactGroupVersion.UsageImpactGroupId
  );

-- Target: UsageImpactGroupVersion.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'A6D5B73C-39BB-43DA-B346-7C8A55FD728A',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'BD2356AE-182B-43FB-9C45-F8F07F7FFA66', -- UsageImpactGroupFactor.UsageImpactGroupVersionId
    '3EF1C5F3-023D-4792-BA1F-779F8F0BBD03' -- UsageImpactGroupPgmMeasure.UsageImpactGroupVersionId
  );

-- Target: User.Id (174 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '66A47A64-A034-4D78-B5D4-3FF21FD9F6ED',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '95568BA5-6885-4673-80F8-F61DE124AE4A', -- Account.OwnerId
    '8CDF806F-FEAF-4612-A07D-23402323ADA7', -- AccountPlanObjective.ObjectiveOwnerId
    'AE626699-CDA1-4069-9E34-6C687FA9D42A', -- ActionCadence.OwnerId
    '02AE299F-BE0F-4126-A7C1-AA073C177F56', -- ActionCadenceStepTracker.CompletedById
    'DFDD808B-7EA4-4E2F-94B9-5D6135440DE5', -- ActivityFieldHistory.ChangedById
    '75BA45A5-49CA-444B-A0B9-B829E013D3EA', -- AgentWork.PreferredUserId
    'C78A9C6D-E29B-4EAD-80A2-7AA04D4E62FC', -- AgentWork.TransferRequesterId
    '76063571-BB97-4528-ADC3-9268247EDC92', -- AgentWork.UserId
    '95BA4C6B-CFFD-4944-B8BA-77E2A98A59AE', -- AnalyticsDashboard.OwnerId
    '3BAEFC7D-A616-491F-A49A-909B0EBBD383', -- AnalyticsVisualization.OwnerId
    '5065F2EE-A6CE-40FE-983A-9281A20DF3E1', -- AnalyticsVizViewDef.OwnerId
    'A0EA0C9E-944D-4325-AE80-28F642E9B556', -- ApexEmailNotification.UserId
    'F85D01F9-86AE-4F32-8AEB-8322C1FE98D3', -- ApexInlineEventLog.LogUserId
    'D3FEAD29-6FFD-4C36-9452-89CFACC75F7D', -- ApexLog.LogUserId
    'DB4EC364-C22B-4638-AC45-82A1C58D20BB', -- ApexTestRunResult.UserId
    '47483CF1-C7E5-4C71-ABA6-CFA3E36D0491', -- ApplicationFormTemplate.ApproverId
    'D5929DA3-BF68-42E6-ABCE-C96FFDC57BCC', -- ApprovalSubmission.OwnerId
    '80620340-DF63-4C33-B486-66F0FB7521A4', -- ApprovalSubmission.SubmittedById
    'F3F58AD2-350D-4F0E-89BB-B57A292390A6', -- ApprovalSubmissionDetail.ActionPerformedById
    'F83E4983-C6D4-4266-9F87-0D29EF3D4289', -- ApprovalWorkItem.AssignedToId
    'DFD41C08-6203-4416-A394-3C2644B0416A', -- ApprovalWorkItem.ReviewedById
    'D92B0369-8095-44FC-8E76-BECBCEC70105', -- Asset.OwnerId
    'C3B82031-0AB8-4CFB-845E-39ACD2A6CBC9', -- AuthSession.UsersId
    'C6D63C16-897D-4BA8-95F5-B487E98E1F04', -- BotDefinition.BotUserId
    '0D3945A0-4A59-450A-9892-DD4106D144ED', -- BusinessAlertStatus.UserId
    '6AF8FBAB-5DBF-4FA1-BECB-99F6A01C178E', -- BuyerAccount.OwnerId
    'CA61CF77-5991-443C-93E5-DB66738D5B7D', -- CallCtrAgentFavTrfrDest.AgentId
    '48EF96C1-626F-4EE3-A2EB-B8D4CCDAF11A', -- Campaign.OwnerId
    '0E696489-009C-40AC-AE65-0B2C60A5A0F3', -- ChangeRequest.ReviewerId
    'ED1140C4-4A7D-416F-A7F5-2016D29BCDCE', -- ClientBrowser.UsersId
    '03EEA778-B2EE-48D9-AAFB-11792AC6FC52', -- CollaborationGroup.OwnerId
    '26BC0F87-CD1D-4204-96EE-B8DE2782A1FB', -- CollaborationGroupMember.MemberId
    'E8C8DA74-EF11-4FE7-AF7F-04B1E68F5744', -- CollaborationGroupMemberRequest.RequesterId
    '7C7E4980-8133-41CB-99B9-6E15564750B7', -- Contact.OwnerId
    '4C335319-73E9-4A92-929D-56F3FB37D9DA', -- ContentDistribution.OwnerId
    'D8463E2D-B508-4844-BCD0-10B119557656', -- ContentDocument.OwnerId
    'E44EC28F-CEB7-4973-A462-EADB0FDF6683', -- ContentDocumentSubscription.UserId
    '7547FDDF-13BD-4A52-A814-BAFCE731A227', -- ContentNotification.UsersId
    'A11F2B6C-482C-4AFF-A3C0-0382A85F6F22', -- ContentTagSubscription.UserId
    '28323353-7B70-4237-85AF-22444BD5535A', -- ContentUserSubscription.SubscribedToUserId
    '6FBE4A51-5613-46B4-9EA0-33708052A900', -- ContentUserSubscription.SubscriberUserId
    'B323F8A1-8C34-45C3-9344-95DA3DFC21B3', -- ContentVersion.ContentModifiedById
    '03F9F860-3F8B-49C6-9171-E2A317A0D89C', -- ContentVersion.OwnerId
    '5BBD4256-7C07-4AC4-B80D-926FCC8975AD', -- ContentVersionRating.UserId
    '3591A78F-2CA9-4EC6-94E3-965322FAE8E4', -- ContentWorkspaceSubscription.UserId
    '1797600E-12F8-4382-BBEB-EF6497B837F3', -- Contract.ActivatedById
    'B44272D8-2DFB-4934-954E-09E08F152A37', -- Contract.CompanySignedId
    '26A86D16-9B13-493C-B49C-209D873083CE', -- Contract.OwnerId
    '0B9C40C2-4046-48CE-BC14-82AF8FC6AC85', -- ConversationApiLog.RequestedById
    '8EB347D0-81C1-441C-B84A-E0A0F93C5261', -- Dashboard.RunningUserId
    'B13A572E-3953-4BA2-A307-972FCF7E3677', -- DataIntegrationRecordPurchasePermission.UserId
    '18B45F3C-9E76-4E0F-AEAA-F396CB83187E', -- DelegatedAccount.ManagedById
    '020CE7B9-F7EC-44E9-B376-EAA368C499B2', -- DeleteEvent.DeletedById
    'D28B3195-3C4C-481C-8A39-A7EDBB3D7917', -- DeliveryEstimationSetup.LastSyncedById
    'B41B7216-F58F-400F-825C-A498B5B3DB7D', -- DevopsActivityLog.PerformedById
    '27C30CB4-51F4-4FE2-9E62-756C1DF58701', -- DevopsEnvDeploymentMbr.ChangedById
    '86C35E40-A5A5-4011-8F44-007BE9248AC7', -- Document.AuthorId
    '98098130-B797-4962-AEC6-E014C1C271B1', -- EmailTemplate.OwnerId
    '4488520F-E1C1-4715-9F5C-FC2B6E8CBAB8', -- EntitySubscription.SubscriberId
    '2B6384D2-65D6-478E-B62A-3A7006079E28', -- ExternalDataUserAuth.UserId
    '9039F8C4-2E22-4FC0-8E71-D60F303A21CA', -- FeedComment.InsertedById
    'EC567140-9743-4061-A984-6472038AE35D', -- FeedItem.InsertedById
    '49E72DC6-47DD-4C24-8907-A82A18F23D07', -- FeedLike.InsertedById
    'DEA1DE25-C9C2-45CB-93AB-F7ADD91B57DB', -- feedSignal.InsertedById
    'F016C48A-AC56-42BF-BDC3-718F45048104', -- FldSvcObjChg.UserId
    '1F427522-50EB-4D5A-89F0-685DB7E66E45', -- FlowOrchestrationInstance.OwnerId
    '1315A0E8-7A52-4799-9B68-93B5FB0A2958', -- FlowOrchestrationStepInstance.OwnerId
    'E2710048-15FF-4783-B68A-09E2EA452263', -- FlowOrchestrationVersion.ActivatedById
    '0DCB9937-FECC-4AE2-8F73-F80BB877CC38', -- FlowOrchestrationWorkItem.AssigneeId
    '9934D8DA-7D38-4AE1-8115-51D73283ADED', -- FlowOrchestrationWorkItem.OwnerId
    'E3785A88-DC49-475C-88E9-B650F858AC01', -- FlowRecordVersion.ActivatedById
    '56DA73A6-BEBF-4008-91D9-1B52D05BF664', -- FlowRecordVersion.PausingUserId
    '02A8D297-EF1A-4859-9198-1B72113D8B8D', -- FlowRecordVersion.ResumingUserId
    'E31FA654-67B4-4267-A5A0-7B3B78EE2BF7', -- ForecastingCustomData.ForecastOwnerId
    '327BE789-1582-41A9-A4D5-0D770F8D3E9B', -- ForecastingSrcRecJudgment.JudgmentOwnerId
    '0B3134EF-4396-4384-9547-61CB798C8117', -- ForecastingSubmission.ForecastOwnerId
    'C945D5FF-E827-4115-84E1-B3E32BE36242', -- Incident.ResolvedById
    '4F6A686B-1536-432B-B697-06F74A2BB84C', -- Individual.OwnerId
    '6F99A780-962E-4C6A-B9D6-4527AA50F3E0', -- KnowledgeArticleFeedback.FeedbackSubmitterId
    'D834996A-CC1F-4620-9F3F-064E57448166', -- LandingPage.ContentLastSavedById
    '0E2BCB36-1206-4A42-B327-01D5733D320D', -- LandingPage.LastPublishedById
    'E4F7BD62-0B83-400F-A966-AE12CF8B94C8', -- LearningItemAssignment.AssigneeId
    '36D5B22D-E243-4B60-92FA-37F89CA0D7B6', -- LearningItemProgress.OwnerId
    'D83B7FBB-A8FC-436C-9311-3299D089A26A', -- LightningExitByPageMetrics.UserId
    '7ED075DA-89E6-490D-B453-2314D8F1F4EA', -- LightningToggleMetrics.UserId
    'BD203526-5FB0-4747-A9C3-F7D93EDEA4DF', -- LightningUsageByAppTypeMetrics.UserId
    '367379BA-7CD5-4FC4-994E-A975A346F1B2', -- LightningUsageByPageMetrics.UserId
    'EA8352FD-10E4-42DC-B58E-131D440796F7', -- ListViewChart.OwnerId
    '65BFC7A9-F83E-4997-A1B8-86AC1A3BE7F1', -- LoginIp.UsersId
    '393F1D92-BA2D-4F15-9335-E094B86D7715', -- MessagingSession.TargetUserId
    '74C96C96-41D3-41D0-84A1-DF4C3BDB5EB1', -- MobSecurityCertPinEvent.UserId
    '8A35551D-010C-42D0-BE3D-074CBA892A86', -- MyDomainDiscoverableLogin.ExecuteApexHandlerAsId
    '7F64E22F-64DC-4477-9806-F882CD52A40A', -- NetworkAuthApiSettings.HeadlessDiscoveryExecutionUserId
    'E875EACB-B3BA-404D-A22A-879B5FA01AF4', -- NetworkAuthApiSettings.RegistrationExecutionUserId
    '0A773287-5483-44B7-A38D-423831D5D8EA', -- Note.OwnerId
    'E5E93C7B-76D1-4A0C-9B93-59DC324E111D', -- NoteAndAttachment.OwnerId
    '4B9BC791-C5AA-47B2-9478-85DAE32093D9', -- OauthToken.UserId
    '8D6A9564-4A2A-43CC-83A1-C565A9252E79', -- OauthTokenExchHandlerApp.ApexExecutionUserId
    '096007DD-00AF-4E29-A8D1-B15B1B655E0A', -- ObjectUserTerritory2View.UserId
    '6B192C81-57BC-4161-AF07-E341F87ED93A', -- OmniSupervisorConfigUser.UserId
    'F25BD5E2-DD95-4325-948E-C804B994AA7B', -- Opportunity.OwnerId
    '67C4DCDE-CCF9-4749-902F-7AF38EB42E7F', -- OpportunityLineItemSplit.SplitOwnerId
    '6110BC47-1E07-4DD8-940F-552429C1E418', -- OpportunitySplit.SplitOwnerId
    '6C4E8298-0568-412B-9E9A-10A31C6CA028', -- Order.ActivatedById
    '5D73093A-25F0-4256-A61E-DE398F1039B0', -- Order.CompanyAuthorizedById
    '169B6E4E-45CF-48AE-B8CD-8806270B14DC', -- OutgoingEmail.OwnerId
    '08FCACCB-2A6F-46CA-80FF-4AB52CAB3D7D', -- OutgoingEmailRelation.OwnerId
    '3858B29C-5BAB-4B84-8EAA-B1820BD1BC0D', -- OwnedContentDocument.OwnerId
    'C4E6A3FF-B7BE-430A-A165-A1143A66072D', -- PaymentIntent.SubmittedById
    'F072688B-08AA-4B1A-B84F-933DF1B0FDF8', -- PendingServiceRouting.TransferRequesterId
    'ECE08CDD-6500-42BD-B2C9-FCE204A9230C', -- PermissionSetAssignment.AssigneeId
    '8523FCDF-CC0F-42B1-AE2C-C06E1379238E', -- PermissionSetLicenseAssign.AssigneeId
    '6B439E29-00D8-4EAA-90AF-5EDC983AE113', -- PersonAccountOwnerPowerUser.UserId
    '3033E006-CD2C-4096-A3A0-DC56CED287BF', -- PersonTraining.AssigneeId
    'B37FE913-4169-4507-8D41-AFEE75C1ED4A', -- PickTicket.AssignedToId
    'B85F5446-FA6F-43FF-8E47-649EACAD0AA1', -- PipelineInspectionListView.UserId
    '77A86674-8E07-4A78-AE73-230C012876F7', -- PlatformAction.InvokedByUserId
    '5FADFF1C-05DB-4EBF-8068-2EE70FF30938', -- Problem.ResolvedById
    '8C113491-90E1-444B-B2CE-6C2A690FF1E2', -- ProcessInstance.LastActorId
    '994EA2AC-0A62-4805-8B12-356014A5D79E', -- ProcessInstance.SubmittedById
    'BB0A5D51-9352-4661-91C4-FEE82F298D4F', -- ProcessInstanceNode.LastActorId
    '75520B63-2178-421E-B391-B255224803E7', -- ProfileSkillEndorsement.UserId
    '037A7B6E-ABFD-4525-A0CD-9384A502440C', -- ProfileSkillUser.UserId
    '67EE5D6E-741B-43DA-972A-4E0D72A4F65F', -- PromptAction.UserId
    'DAECE30E-8CFC-4B76-9E6C-5005BF9720D4', -- PromptVersion.PublishedByUserId
    'CD29388B-88DE-4696-B8E8-C9EAF6EFE18C', -- QuickTextUsage.UserId
    'FB4ED7F9-1C91-4F1C-879B-60CF8D0C738F', -- RecentFieldChange.ValueChangedById
    '60EFE2B5-F3BA-4AC5-AC9F-E7B122CEBB63', -- RecordActionHistory.UserId
    'FECDCCC0-FA35-4CBD-AAC2-3654A5315628', -- ReturnOrder.ReturnedById
    'C54FAAA1-DCBF-435F-9414-5649328466D7', -- SamlSsoConfig.ExecutionUserID
    '86A0985E-B62A-4D3F-ADE1-0209EA2D22E4', -- ServiceRequest.AssignedUserId
    '7AEFD34E-AA97-4A6B-8DF2-C03A47A3AC95', -- ServiceResource.RelatedRecordId
    '74C9BFDE-E199-4D6D-B5E3-3BCEABC4C8B9', -- SessionPermSetActivation.UserId
    '4ED8140B-A254-42C5-B65D-B9556662CE56', -- SfdcPartnerOffer.SentToCustomerById
    '20635A64-6A5A-4F4A-8373-1C23515AD69C', -- SfdcPartnerOrder.SentByUserId
    '04FA34BD-6B31-4CBA-9181-F4DE9E4129AE', -- SfdcPartnerSbscrOffer.RespondingUserId
    '3887C35F-B6FB-40E9-93AB-03F615122CEB', -- Site.AdminId
    'F373DF6C-812C-475D-B327-EF389832AAC2', -- Site.GuestRecordDefaultOwnerId
    '523D6F0C-330E-4CC9-9F02-6AEE73EFB7C2', -- Site.GuestUserId
    'DC193B10-1C39-4BD8-895E-2E832C54E3AD', -- SkillLevelProgress.OwnerId
    '9ADBA6F2-4A7A-477E-A54D-8DBD64AA83A4', -- SocialPost.DeletedById
    '5C5DB358-4593-49DA-8FF2-D736715D6C7E', -- SocialPost.HiddenById
    '9265DEA7-C0B0-45F5-950B-195A97E79602', -- Solution.OwnerId
    '4D0A6D98-C24C-4EB6-B20A-215A3970A845', -- StagedUnmtchdEmailAddr.UserId
    'D69A1050-6E5E-4841-84E0-F60200977A44', -- StampAssignment.SubjectId
    'D8075DC7-8E5F-4086-8A26-739DE6BA8B45', -- SvcCatalogRequest.SubmitterId
    'F02E13B5-67B5-4B93-8965-7BBFE293C035', -- Territory2AlignmentLog.RunAsId
    'A8CDE9AA-76BB-4FC7-9C11-50E3E06B046B', -- ThirdPartyAccountLink.UserId
    'B3767D71-A9DE-4F72-B9B6-CDC766221BD6', -- ThreatDetectionFeedback.UserId
    '5F067DE9-4517-4065-9C18-E0BA08A9CB27', -- TodayGoal.UserId
    '5DE1591E-E9FD-4845-90ED-2723FFBC6931', -- UnifiedActivityInsight.OwnerId
    'B16A4383-8939-422E-8784-0DB3C999964C', -- UserAppInfo.UserId
    '5E58C54D-9648-463C-8550-0FAE1BC3A7DF', -- UserDailyMetric.UserId
    'CF053062-8382-435A-8813-AB4985B3A283', -- UserListView.UserId
    'ABB0AD76-2696-47FE-84E8-2D57D7902E89', -- UserMonthlyMetric.UserId
    'C65D1055-825C-4607-83DB-C47725AC3B42', -- UserProvAccount.SalesforceUserId
    'BAA2654B-3145-4997-A383-2B300CBEEAC7', -- UserProvAccountStaging.SalesforceUserId
    '4D724DC5-948A-495B-92BC-EAC80BE3F55C', -- UserProvisioningLog.UserId
    '6EDB3EB6-FEEC-4D67-A35B-C316F6571425', -- UserProvisioningRequest.ManagerId
    '1E1FDEC3-833A-4383-A706-D945A9DCB879', -- UserProvisioningRequest.SalesforceUserId
    '2E98A3DF-294B-417C-9C6A-1F96643F8161', -- UserRelatedRecordContent.ContentOwnerId
    '23A28CBA-FC0E-45BF-ABBE-78BC0A954C9C', -- UserShare.UserId
    'B20DBFFD-6BE2-4882-AF50-11D615A93941', -- UserTerritory2AssocLog.UserId
    'C18885E0-11B3-4A24-AC0B-D145929667A3', -- VerificationHistory.UserId
    '6A55FA13-5DE5-4E27-BB2B-F8FF06A816D2', -- VideoCall.ConsentedUserId
    'D2A9FE5E-F106-4465-8566-F9C7E8A07166', -- VideoCall.HostId
    '2C1302E7-92A8-473C-8BE5-0F0FA9F3F308', -- VoiceCall.UserId
    '5E501AD9-977B-4572-B03D-B0D1EBCB5C38', -- VoiceMailGreeting2Rep.RepId
    '3A114AE1-140D-4FCF-8EDC-FF0E1941ED96', -- VoiceVendorLine.UserId
    '18ECFA65-9C74-4F7F-8F48-3FF8B5E579FA', -- WorkBadge.GiverId
    '66676A6A-FB58-4270-A1E7-976855EFCB3D', -- WorkBadge.RecipientId
    '703202BD-91CA-4499-9468-64A8FEDE7F28', -- WorkItem.AssignedToId
    '437B2109-1FDD-4304-BC14-811950247761', -- WorkItem.DevelopmentApprovedById
    'D6172366-D111-4FF9-8E26-27703F6B88D9' -- WorkThanks.GiverId
  );

-- Target: UserAccessChange.Id (6 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '19A52284-6B01-4AC9-B806-14069EE61E62',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '942E12F0-23CE-43FD-B657-2FA32C720202', -- PermissionSetAssignment.LastCreatedByChangeId
    '627C8303-296F-42DD-A913-26A4592D6F6E', -- PermissionSetAssignment.LastDeletedByChangeId
    'F5FE9EE1-1691-471A-88A0-D74F6F1FFA75', -- PermissionSetLicenseAssign.LastCreatedByChangeId
    '801CCBD5-32C2-43E6-A67E-AA9776BB2EA1', -- PermissionSetLicenseAssign.LastDeletedByChangeId
    '58E4C663-3C99-4AB1-A79B-0340A879E734', -- UserPackageLicense.LastCreatedByChangeId
    '15BDCB32-B105-43E1-94EA-258035C4A06A' -- UserPackageLicense.LastDeletedByChangeId
  );

-- Target: UserDefinedLabel.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '215F5884-3E59-4004-A9FB-C11CB180F88E',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '7B0A0890-D1BE-4EBB-9C29-99A9246E7E22' -- UserDefinedLabelAssignment.LabelId
  );

-- Target: UserEmailPreferredPerson.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'ED886B0B-28D1-425D-8D5F-F74FF78BC3A8',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '90B00AA6-BFE0-417A-9A3F-789FF7EFEAC9' -- UserEmailPreferredPersonShare.ParentId
  );

-- Target: UserLicense.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '1CC88BDD-E2DF-4E66-84B8-6F439290D338',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'EE41F5D0-8A87-45AE-9247-F6626859AB18', -- ActiveProfileMetric.UserLicenseId
    'CD449C26-E830-4F49-A24E-13B402507312' -- Profile.UserLicenseId
  );

-- Target: UserListView.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '36CFADBA-9BA9-4043-AB2D-5F35C59D99E7',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '26F4CEBC-CFF3-434D-B308-4709166CCBD4' -- UserListViewCriterion.UserListViewId
  );

-- Target: UserProvAccount.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'DD745F5D-C475-4D06-AC62-444DE8639119',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '963023C2-198C-41C2-ABA9-4C4A2CE7F8FD' -- UserProvisioningRequest.UserProvAccountId
  );

-- Target: UserProvisioningConfig.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '134670E3-471E-41FC-96A7-B2BC1536FA4A',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '2B594BDD-7C67-4DFC-A53F-9C59B6B25BC9' -- UserProvisioningRequest.UserProvConfigId
  );

-- Target: UserProvisioningRequest.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'D649C749-D9B5-4CE3-806A-C55D294B6D9F',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '91B9FB81-12CA-4CB7-BB48-8753A2D76857' -- UserProvisioningLog.UserProvisioningRequestId
  );

-- Target: UserRole.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'C8D12E4D-ED66-4563-9F94-D467A2150608',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '9952285C-ACA4-4359-A3E8-604E64BA4E56', -- Name.UserRoleId
    'ED3DE22F-471B-45F8-A8FA-90143DC9AA16', -- RecentlyViewed.UserRoleId
    'ED35CBD5-0F51-44F4-B668-9D80AE18D0CD' -- User.UserRoleId
  );

-- Target: VideoCall.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '05D94728-E880-4007-954F-A5FD25E9D1B7',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '5E9FD76A-F44D-4B38-80CF-A9E34C6A498C', -- GenAIConversationSummary.ConversationRecordId
    '39491530-7342-4F17-BAD8-3F71785A899D', -- LearningItemSubmission.CallId
    'BAF4D95D-C1AD-4535-8CB3-0725BB287790', -- UnifiedVideoCall.DetailId
    '9AA66073-5F19-4E70-B5BD-0CEA985CF473', -- VideoCallParticipant.VideoCallId
    'B633BB24-5686-4E18-B875-71B0F8B2B507' -- VideoCallRecording.VideoCallRecordId
  );

-- Target: VideoCallInsightReason.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '6DDC55D9-A896-4D9D-8051-F39502363B03',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '1FCA6D43-C522-4F12-A724-9C691A3DA7A7' -- VideoCallInsightAction.ActionReferenceId
  );

-- Target: VideoCallParticipant.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'A6D012BF-EB18-4EA8-8D47-75E98508DDD7',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '6CC1C72F-EF26-474C-8849-8F32D76CDDD2' -- VideoCallRecordingStructure.VideoCallParticipantId
  );

-- Target: VideoCallRecording.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'A098D65E-8EB5-4DF8-81F7-A62A56C8183D',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'C2AB0E85-824B-461E-BF01-AA5EBD583EE8', -- VideoCallInsight.VideoCallRecordingId
    'FBFECC87-9D14-4676-B56F-3ED718C3C945' -- VideoCallRecordingStructure.VideoCallRecordingId
  );

-- Target: VoiceCall.Id (3 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '3BB36E1F-ACB2-4757-9DEE-CF6A49FC7403',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '2AA8F64A-0AC1-4FC3-A2D6-DBEB6CDD98B3', -- AgentWorkConversationalData.ChannelSessionRecordId
    'B68A76EC-C0F8-4AB7-B5A6-6D1EE043BC47', -- UnifiedVoiceCall.DetailId
    '0F76EC31-5ED9-4182-A6FB-26AE86867D93' -- VoiceCallRecording.VoiceCallId
  );

-- Target: VoiceCallInsightReason.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '95324A93-4331-4EAB-8387-BFD739BE3A0D',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'DBAAABB8-7CBF-48C9-A98A-10C814CC2F32' -- VoiceCallInsightAction.ActionReferenceId
  );

-- Target: VoiceCallRecording.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '5C761562-302C-46D3-8F71-296EE12E7019',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '0200F3BD-289F-46B8-B7CA-EE2DF00913CA', -- AgentWorkConversationalData.AgentChannelRecordingId
    '7F8D4373-61E6-47C4-87B2-9D67DAF7E97C' -- VoiceCallInsight.VoiceCallRecordingId
  );

-- Target: VoiceMailGreeting2.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '3C45DACE-5646-4E7F-A5DE-E2A5147AE9F4',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'B3F1DCBC-235A-48DD-9C78-18620394FB80' -- VoiceMailGreeting2Rep.VoiceMailGreeting2Id
  );

-- Target: VoiceVendorInfo.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'BFE6C9AC-BACA-4372-AE73-A7AE63F47D63',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '51BDDC95-A90F-4FB0-A9FE-D73AB05EBF8B' -- VoiceVendorLine.VoiceVendorInfoId
  );

-- Target: VoiceVendorLine.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'E2AC4F38-789C-475D-9254-A7E671512D21',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'AE320E32-089C-41A1-9900-1D76EEE6C487' -- VoiceCall.VoiceVendorLineId
  );

-- Target: WebCart.Id (6 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'AC464F34-2BC8-47AF-B3C0-FB36A9868866',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '4ED64F50-0BCC-4BD2-8AA8-95E4AAD5EF0C', -- CartDeliveryGroup.CartId
    '6CEA67D1-AF71-45A8-B883-F53E4CB09594', -- CartItem.CartId
    'E65EFDAB-18C9-4609-B691-A8A52FC3CEC4', -- CartItemPriceAdjustment.CartId
    '06522370-A1DD-4E36-9045-FCECCF4AA0EB', -- PaymentInitiationSource.WebCartId
    '30E626A1-97F8-42E7-8F4F-5A6B641A2C9F', -- WebCartAdjustmentBasis.WebCartId
    'E995F251-AADC-4C48-A888-9CEA8AAE3DA3' -- WebCartAdjustmentGroup.CartId
  );

-- Target: WebCartAdjustmentGroup.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '71CA0D15-FFD6-40C3-BE0A-FDD371B493D7',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'CDD9136D-7334-47B5-AD8D-0324EC3D0643' -- CartItemPriceAdjustment.WebCartAdjustmentGroupId
  );

-- Target: WebStore.Id (13 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'B0C71DC5-DE1C-4DAE-8649-AA3C9532B6EF',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'E758FC34-F222-4057-99C6-41C6C516166F', -- CalculatedInsightRangeBound.SalesStoreId
    '87174F64-B3EB-4F72-8ADE-5A32139FD1CC', -- Order.SalesStoreId
    '05E594A9-9110-4638-95DA-5AD944B2ECD5', -- OrderSummary.SalesStoreId
    '44818DBE-6DE6-49CA-90F3-A39BE3506D5B', -- PaymentInitiationSource.WebStoreId
    'D94E4AC6-40A6-46AF-84C7-BF6CE8F6FB1C', -- PendingOrderSummary.SalesStoreId
    'DB5C2C29-72D0-4137-891C-E5DB25DB5263', -- PromotionSegmentSalesStore.SalesStoreId
    'BB70C7A5-DF84-492D-99A0-BA6DA382C9B3', -- ShippingConfigurationSet.TargetRecordId
    '9C7B1103-51EB-4F4F-9110-55EDE9D5C8D7', -- WebCart.WebStoreId
    'FC69BCE0-AD0A-42CE-AC4C-40CE4F9AA0F7', -- WebstoreBuyerGroup.WebStoreId
    '98C8CAA6-83AE-47BD-8353-E2F1EBE7137F', -- WebStoreInventorySource.WebStoreId
    'C71BA4E4-55AA-4286-BF52-E1C74FE8288D', -- WebStoreNetwork.WebStoreId
    '88F19977-EE9D-4DEA-A585-8291C8FBFF72', -- WebStoreSearchProdSettings.WebStoreId
    '5A609C85-9EA5-4F5D-B92F-E47E623E9320' -- WebStoreShare.ParentId
  );

-- Target: WorkAccess.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '30D13BB4-CC46-4327-872E-71D2798E2337',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'C03BBE45-E7A7-4FDF-987D-C3951F3405FB' -- WorkAccessShare.ParentId
  );

-- Target: WorkBadgeDefinition.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '3746752C-D571-43C9-B5F1-2A2E261627B3',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '9650E5E1-2E95-4821-AA5F-EB8B9D3C3F1A', -- WorkAccess.ParentId
    '38C3FBD4-40ED-46B5-97C2-716327D56830' -- WorkBadge.DefinitionId
  );

-- Target: WorkDemographic.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'B94630D7-9005-4E2D-8FFE-D863370B1426',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'C451E4FA-53EF-4779-84F1-335C658FDC66', -- WorkforceCapacityUnit.WorkDemographicId
    '5F69A6B1-2C2F-4807-B409-B2E1F23082C9' -- WorkloadUnit.WorkDemographicId
  );

-- Target: WorkforceCapacity.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '22FFBFDA-C44E-4EFE-874A-832E05EFDEEC',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'C85F4A14-78FA-4C7D-80EF-3CAD36311F78' -- WorkforceCapacityUnit.WorkforceCapacityId
  );

-- Target: WorkItem.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'C60C5F2D-14DF-4BAF-87BD-5396146E2CD0',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '6933E167-456F-43AD-8D7C-E4A9E76DA9AF', -- DevopsActivityLog.WorkItemId
    '1C002BF7-45B0-48AC-A4C3-452F33B6DBA7' -- DevopsPipelnStgPromWkItem.WorkItemId
  );

-- Target: Workload.Id (2 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '250DBD5E-ED94-43C5-BA30-49B8AECC63F9',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '4AB09524-FF90-43F7-9E49-FD4E6A80D95A', -- WorkforceCapacity.WorkloadId
    'CF3121FB-DDD3-449D-9F69-DF9415FF2797' -- WorkloadUnit.WorkloadId
  );

-- Target: WorkOrder.Id (7 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '30B81558-2C1A-420F-A72F-D6C7D21275BB',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '0B0818FF-100F-49AC-84A0-EC2690A8EE75', -- PaymentInitiationSource.WorkOrderId
    '5A14E971-51A0-4611-9E15-56DD5594039A', -- ProductRequest.WorkOrderId
    '82B97AD8-76D3-4201-B790-630D1AE25097', -- ProductRequestLineItem.WorkOrderId
    '3AC52193-0523-44EA-AAA4-B0613A53F86A', -- WorkOrderHistory.WorkOrderId
    '7C47AE2F-B980-4D06-A2DA-338A487F7085', -- WorkOrderLineItem.WorkOrderId
    'A57F20B4-B69D-4521-BC4C-C7AED31CCE6D', -- WorkOrderShare.ParentId
    '81CB4AC0-1036-4FB6-9507-9977EEA926D3' -- WorkPlan.WorkOrderId
  );

-- Target: WorkOrderLineItem.Id (5 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'DC793038-24C8-4DD5-B041-FDF1FA61954C',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '8C984FD4-84DE-446F-96B0-F9C138AB6B74', -- PaymentInitiationSource.WorkOrderLineItemId
    '753B7B8A-AA4E-40AB-B668-6184A7AF8AA0', -- ProductRequest.WorkOrderLineItemId
    'FA66F4EE-896B-46A1-A84C-2C608AF1C072', -- ProductRequestLineItem.WorkOrderLineItemId
    '51C3DEF4-366E-4F02-9B6A-4692FAD2E256', -- WorkOrderLineItemHistory.WorkOrderLineItemId
    '33DF8776-F498-465D-9A88-8FBF03283E6B' -- WorkPlan.WorkOrderLineItemId
  );

-- Target: WorkPlanTemplate.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '84426438-CFB4-4C0E-86AD-AA327FD2077E',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '0781DEA6-EDEE-457E-8914-9C4A1F46DC76' -- WorkPlan.WorkPlanTemplateId
  );

-- Target: WorkThanks.Id (1 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = 'D7E95861-195C-4D95-BBDD-FAAA5B068B20',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    '14FD423D-098A-463E-9C07-34E50714ACB7' -- WorkBadge.SourceId
  );

-- Target: WorkType.Id (6 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '82DFCB6C-3637-49CD-B6AB-956518B04211',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'A18751F8-9475-48A8-BD55-40F54B664C9B', -- AppointmentTopicTimeSlot.WorkTypeId
    '6D9B8274-696B-41E1-9F18-61C8334300D6', -- ServiceAppointment.WorkTypeId
    'CF7B6913-8589-4A5D-9960-784FE394814E', -- ServiceTerritoryWorkType.WorkTypeId
    '88284328-57FF-4D15-9A83-9BECDB1DC503', -- WorkOrder.WorkTypeId
    '0D5D4065-1796-481D-83E3-0FA27D6574E6', -- WorkOrderLineItem.WorkTypeId
    '8459C3D4-6137-48E9-B718-94EC189E7AAD' -- WorkTypeGroupMember.WorkTypeId
  );

-- Target: WorkTypeGroup.Id (4 field(s))

UPDATE __mj."IntegrationObjectField"
SET "RelatedIntegrationObjectID" = '813EBC1F-FDBA-4FC3-B1F0-0AFF1550B078',
    "RelatedIntegrationObjectFieldName" = 'Id'
WHERE "RelatedIntegrationObjectID" IS NULL
  AND "ID" IN (
    'F58D365C-8CD1-450B-AC77-E347D1B2AC1C', -- AppointmentTopicTimeSlot.WorkTypeGroupId
    'B06B9EBC-525F-47D8-A78B-352E4DC524A3', -- QuoteLineWorkSource.WorkTypeGroupId
    '7A4EF4E0-5599-429B-B5F9-EC766386FD91', -- TimeSlot.WorkTypeGroupId
    'A97ED000-A4B3-4CC1-8850-01AE0D20C0C9' -- WorkTypeGroupMember.WorkTypeGroupId
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
-- IDs and Flyway checksums intact. Idempotent (guarded with RelatedIntegrationObjectID IS NULL).

-- Target: AbnExperiment.Id (1 field(s))
