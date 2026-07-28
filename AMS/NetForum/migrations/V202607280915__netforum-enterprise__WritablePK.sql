-- netFORUM Enterprise: the five writable objects that carried no primary key.
--
-- A writable IntegrationObject with no IsPrimaryKey field yields a KEYLESS derived entity. On
-- Postgres, MJ's save audit-wrapper then emits an empty record identifier and every save fails with
--     syntax error at or near ","
-- while fetch keeps succeeding — so the object reads green and persists nothing.
--
-- These five are a distinct case from the rest of the fleet: each declares ZERO fields and is marked
-- Configuration.placeholder = true with schemaSource "runtime-discovered (GetFacadeXMLSchema /
-- GetQueryDefinition)". The other ten writable netFORUM objects each declare hundreds of fields and
-- a proper key (Individual.ind_cst_key, Invoice.inv_key, Organization.org_cst_key, …).
--
-- Runtime discovery cannot rescue them. NetForumConnector.ParseQueryDefinition sets
--     IsPrimaryKey: declared?.IsPrimaryKey ?? false
-- because a netFORUM column definition does not mark a primary key — so a discovered field is NEVER
-- a key, and an object with no DECLARED key stays keyless forever. There is nothing to stamp (zero
-- fields) and nothing may be invented, so the honest disposition is to withdraw the write.
--
-- Evidence below is the vendor's own public WSDL for the xWeb SOAP service
-- (netFORUMXML.asmx?WSDL, namespace http://www.avectra.com/2005/), read operation by operation.
--
-- 1. CustomerAction -> WITHDRAW create.
--    The WSDL shows the write and the declared read door are about different things:
--        InsertCustomerAction(actionCustomerKey:guid, action:string, actionTypeKey:guid,
--                             source:string, actionDate:dateTime, actionSubtypeList:ArrayOfGuid)
--            -> InsertCustomerActionResult : guid
--        GetActionTypeList()   -- no arguments
--            -> GetActionTypeListResult    -- the action TYPE list, not customer actions
--    So nothing written is ever read back, and the object declares no fields at all — MJ has no
--    columns to populate a create body from. The insert does return a key, so a future change could
--    model this properly once a real read door for customer actions is established; that is object
--    authoring, not a key stamp.
--
-- 2. CommunicationPreference -> WITHDRAW update.
--    A bulk set-for-customer command, per the WSDL:
--        SetCustomerCommunicationPreferences(customerKey:string,
--                                            preferences:ArrayOfMailingListSetting)
--            -> SetCustomerCommunicationPreferencesResponse   -- EMPTY, no result element
--    One call carries the customer plus an ARRAY of MailingListSetting rows; there is no single
--    record and no returned identity. Worse, this is actively broken today: NetForumConnector
--    .UpdateRecord injects the external id through PrimaryKeyFieldName(), which reads the DECLARED
--    fields only, so with none declared it is undefined and the envelope goes out with no
--    customerKey at all.
--
-- 3. CEUCredit -> WITHDRAW create.
--    A bulk apply-many-to-one command, per the WSDL:
--        CeuApplyExternalCredits(individualKey:guid, credits:CeuCreditList)
--            -> ArrayOfCeuCreditResult   -- each CeuCreditResult: { ceu_key:guid, externalId,
--                                        --   resultStatus, resultMessage }
--    One call applies a LIST of credits to one individual, and the keys come back inside an array —
--    there is no single created record for BuildCreatedResult to key on. The catalog row's own
--    Description already flags it "(write-oriented)", and its declared read door IS the write method.
--
-- 4. AdvocacyData -> WITHDRAW create.
--    The create returns nothing, per the WSDL:
--        CreateAdvocacyData(oNode:any)
--            -> CreateAdvocacyDataResponse   -- EMPTY, no result element
--    That is already a hard failure today, not a latent one: NetForumConnector.CreateRecord routes
--    the extracted key through BuildCreatedResult, which returns Success:false on an empty id rather
--    than silently losing the record. Like CEUCredit, its declared read door IS the write method.
--
-- 5. FacadeObject -> WITHDRAW write.
--    A generic meta-accessor, not a record type. The object NAME is a parameter, per the WSDL:
--        GetFacadeObject(szObjectName:string, szObjectKey:string)
--        InsertFacadeObject(szObjectName:string, oNode:any)
--        UpdateFacadeObject(szObjectName:string, szObjectKey:string, oNode:any)
--    One catalog row therefore stands for every netFORUM entity without a dedicated WEB* method, all
--    at once — its rows would be heterogeneous. And UpdateFacadeObject needs szObjectKey, which
--    UpdateRecord cannot supply while no primary key is declared.
--
-- Reads are unaffected on all five.
--
-- DELTA migration, deliberately not a re-seed: the catalog rows already exist on installed tenants,
-- so the V202606271422 seed stays untouched and applied — no existing UUID is re-minted, no Flyway
-- checksum breaks, no UQ collision. Every statement is idempotent (keyed by the seeded row ID).

-- ── 1. CustomerAction ──
UPDATE [__mj].IntegrationObject
SET SupportsWrite  = 0,
    SupportsCreate = 0,
    Description    = N'netFORUM Enterprise CustomerAction (TaxonomyLeaf, operations-only — no DataObjectType root). Customer activity records via GetActionTypeList/InsertCustomerAction. Read schema runtime-discovered. The declared read door does not read this object: InsertCustomerAction(actionCustomerKey, action, actionTypeKey, source, actionDate, actionSubtypeList) returns a new guid, but GetActionTypeList takes no arguments and returns the action TYPE list — not customer actions — so a written record is never read back. Write withdrawn: the object declares no fields, so it derives a keyless (and columnless) entity whose saves cannot carry an identifier; runtime GetQueryDefinition discovery can never supply a primary key, because it sets IsPrimaryKey from the Declared metadata only. Reads are unaffected.'
WHERE ID = '111E61F6-B9C1-43BF-A866-7B8A469295ED';

-- ── 2. CommunicationPreference ──
UPDATE [__mj].IntegrationObject
SET SupportsWrite  = 0,
    SupportsUpdate = 0,
    Description    = N'netFORUM Enterprise CommunicationPreference (TaxonomyLeaf, operations-only — no DataObjectType root). Customer opt-in/opt-out preferences via Get/SetCustomerCommunicationPreferences. Schema runtime-discovered. Bulk set-for-customer command, not a record: SetCustomerCommunicationPreferences(customerKey, ArrayOfMailingListSetting) returns an EMPTY response. With no declared primary key the connector cannot inject the customerKey — UpdateRecord''s PrimaryKeyFieldName reads the declared fields only and returns undefined — so the call would fire without saying which customer it applies to. Write withdrawn: the object declares no fields, so it derives a keyless (and columnless) entity whose saves cannot carry an identifier; runtime GetQueryDefinition discovery can never supply a primary key, because it sets IsPrimaryKey from the Declared metadata only. Reads are unaffected.'
WHERE ID = '86021DCA-F7FC-4ABC-BEBC-DB06F4B87930';

-- ── 3. CEUCredit ──
UPDATE [__mj].IntegrationObject
SET SupportsWrite  = 0,
    SupportsCreate = 0,
    Description    = N'netFORUM Enterprise CEUCredit (TaxonomyLeaf, operations-only — no DataObjectType root). Continuing Education Unit records via CeuApplyExternalCredits (write-oriented). Read schema runtime-discovered. Bulk apply-credits command, not a record: CeuApplyExternalCredits(individualKey, CeuCreditList) applies a LIST of credits to one individual and returns ArrayOfCeuCreditResult — a per-credit ceu_key inside an array, not a single created id. Write withdrawn: the object declares no fields, so it derives a keyless (and columnless) entity whose saves cannot carry an identifier; runtime GetQueryDefinition discovery can never supply a primary key, because it sets IsPrimaryKey from the Declared metadata only. Reads are unaffected.'
WHERE ID = 'BB0BD4B6-FCA6-424E-AA20-6C1B02A1D8AA';

-- ── 4. AdvocacyData ──
UPDATE [__mj].IntegrationObject
SET SupportsWrite  = 0,
    SupportsCreate = 0,
    Description    = N'netFORUM Enterprise AdvocacyData (TaxonomyLeaf, operations-only — no DataObjectType root). Advocacy data records via CreateAdvocacyData (write-oriented). Read schema runtime-discovered. Create returns no identifier at all: CreateAdvocacyData(oNode) has an EMPTY response, so BuildCreatedResult already returns Success:false on every call today. Write withdrawn: the object declares no fields, so it derives a keyless (and columnless) entity whose saves cannot carry an identifier; runtime GetQueryDefinition discovery can never supply a primary key, because it sets IsPrimaryKey from the Declared metadata only. Reads are unaffected.'
WHERE ID = 'C3DCE8A2-C463-403C-9DF7-A8E338A43B98';

-- ── 5. FacadeObject ──
UPDATE [__mj].IntegrationObject
SET SupportsWrite  = 0,
    SupportsCreate = 0,
    SupportsUpdate = 0,
    Description    = N'netFORUM Enterprise FacadeObject (TaxonomyLeaf, operations-only — no DataObjectType root). Generic facade covering entities without dedicated WEB* methods (Get/Insert/UpdateFacadeObject). szObjectName-addressable; schema via GetFacadeXMLSchema at run Generic meta-accessor, not an object: szObjectName is a PARAMETER of Get/Insert/UpdateFacadeObject, so one catalog row would stand for every entity in the tenant at once. UpdateFacadeObject also needs szObjectKey, which the connector cannot supply with no declared primary key. Write withdrawn: the object declares no fields, so it derives a keyless (and columnless) entity whose saves cannot carry an identifier; runtime GetQueryDefinition discovery can never supply a primary key, because it sets IsPrimaryKey from the Declared metadata only. Reads are unaffected.'
WHERE ID = 'AA42F449-4F21-440C-ABED-32FE632FC4FA';
