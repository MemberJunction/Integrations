-- Business Central: nest the ten child objects under their parent document.
--
-- WHAT IS WRONG TODAY.
--   Ten catalog objects address their collection directly under the company:
--       /companies({id})/salesInvoiceLines
--   That URL is structurally valid OData -- Business Central publishes the navigation property on the
--   'company' EntityType, and Microsoft's API reference documents the form -- but the service REFUSES
--   it at runtime with HTTP 400 Application_DialogException, "You must specify a parent ID". The
--   record is only addressable beneath its owning document:
--       /companies({id})/salesInvoices({id})/salesInvoiceLines
--   Both forms are already recorded on each row: Configuration.documentedPaths carries the nested and
--   the flat variant, and Configuration.nestedAlternatePaths carries the nested one. The generator
--   promoted the flat variant into the operative APIPath / CreateAPIPath / UpdateAPIPath /
--   DeleteAPIPath columns. This migration promotes the nested variant instead. journalLines was
--   already correct and is the shape copied here.
--
-- HOW THIS WAS FOUND, AND WHY IT SURVIVED THE SUITE.
--   A full-catalog read sweep against a live Business Central tenant (Test environment, 2026-08-17) --
--   the first live credential this connector has ever had. All ten returned 400 on the flat path and
--   200 with rows on the nested path. The credential-free suite could not have caught it: the mock
--   replays fixtures at whatever path the catalog declares, so a wrong path is self-consistent and
--   green. The catalog and the mock were generated from the same Microsoft corpus that advertises the
--   flat form.
--
-- EVIDENCE PER OBJECT.
--   Parent bindings come from the tenant's own /api/v2.0/$metadata NavigationProperty graph, not from
--   naming. Five were additionally confirmed by a live 200-with-rows read on the nested path; the
--   other five carry the same metadata binding but their parent collection is empty in the probed
--   company, so the nested leg could not be exercised. Each is marked below.
--
-- ALSO FIXED: vendorPayments carried a stray space in UpdateAPIPath / DeleteAPIPath
--   ("/companies({id})/vendorPayments ({id})"), which would not have resolved even flat.
--
-- DELTA migration, deliberately not a re-seed: the catalog rows already exist on installed tenants, so
-- V202608041723 stays untouched and applied -- no UUID re-minted, no Flyway checksum broken. Every
-- statement is idempotent (keyed by the seeded row ID).

-- ── 1. salesInvoiceLines -> under salesInvoices (live-verified: 200 with rows on the nested path) ──
UPDATE [__mj].IntegrationObject
SET APIPath = N'/companies({id})/salesInvoices({id})/salesInvoiceLines',
    CreateAPIPath = N'/companies({id})/salesInvoices({id})/salesInvoiceLines',
    UpdateAPIPath = N'/companies({id})/salesInvoices({id})/salesInvoiceLines({id})',
    DeleteAPIPath = N'/companies({id})/salesInvoices({id})/salesInvoiceLines({id})'
WHERE ID = 'FA548CF0-6886-4E98-AF18-1D867A37D555';

-- ── 2. salesOrderLines -> under salesOrders (metadata-bound; parent collection empty in the probed company) ──
UPDATE [__mj].IntegrationObject
SET APIPath = N'/companies({id})/salesOrders({id})/salesOrderLines',
    CreateAPIPath = N'/companies({id})/salesOrders({id})/salesOrderLines',
    UpdateAPIPath = N'/companies({id})/salesOrders({id})/salesOrderLines({id})',
    DeleteAPIPath = N'/companies({id})/salesOrders({id})/salesOrderLines({id})'
WHERE ID = '0C25CEEA-EA24-4793-8CB1-42AEE2BA2C6E';

-- ── 3. salesQuoteLines -> under salesQuotes (metadata-bound; parent collection empty in the probed company) ──
UPDATE [__mj].IntegrationObject
SET APIPath = N'/companies({id})/salesQuotes({id})/salesQuoteLines',
    CreateAPIPath = N'/companies({id})/salesQuotes({id})/salesQuoteLines',
    UpdateAPIPath = N'/companies({id})/salesQuotes({id})/salesQuoteLines({id})',
    DeleteAPIPath = N'/companies({id})/salesQuotes({id})/salesQuoteLines({id})'
WHERE ID = '3C468773-029B-44FA-A27D-DC11C960E8EA';

-- ── 4. salesCreditMemoLines -> under salesCreditMemos (live-verified: 200 with rows on the nested path) ──
UPDATE [__mj].IntegrationObject
SET APIPath = N'/companies({id})/salesCreditMemos({id})/salesCreditMemoLines',
    CreateAPIPath = N'/companies({id})/salesCreditMemos({id})/salesCreditMemoLines',
    UpdateAPIPath = N'/companies({id})/salesCreditMemos({id})/salesCreditMemoLines({id})',
    DeleteAPIPath = N'/companies({id})/salesCreditMemos({id})/salesCreditMemoLines({id})'
WHERE ID = 'BA191E34-1419-4210-9063-B87B0C95B368';

-- ── 5. purchaseInvoiceLines -> under purchaseInvoices (live-verified: 200 with rows on the nested path) ──
UPDATE [__mj].IntegrationObject
SET APIPath = N'/companies({id})/purchaseInvoices({id})/purchaseInvoiceLines',
    CreateAPIPath = N'/companies({id})/purchaseInvoices({id})/purchaseInvoiceLines',
    UpdateAPIPath = N'/companies({id})/purchaseInvoices({id})/purchaseInvoiceLines({id})',
    DeleteAPIPath = N'/companies({id})/purchaseInvoices({id})/purchaseInvoiceLines({id})'
WHERE ID = '21F2FCA0-CC29-43C5-ACB8-BDA42320E1CC';

-- ── 6. purchaseOrderLines -> under purchaseOrders (metadata-bound; parent collection empty in the probed company) ──
UPDATE [__mj].IntegrationObject
SET APIPath = N'/companies({id})/purchaseOrders({id})/purchaseOrderLines',
    CreateAPIPath = N'/companies({id})/purchaseOrders({id})/purchaseOrderLines',
    UpdateAPIPath = N'/companies({id})/purchaseOrders({id})/purchaseOrderLines({id})',
    DeleteAPIPath = N'/companies({id})/purchaseOrders({id})/purchaseOrderLines({id})'
WHERE ID = 'CE38D98C-D230-492E-B7B5-38532C6DAE5B';

-- ── 7. purchaseCreditMemoLines -> under purchaseCreditMemos (metadata-bound; parent collection empty in the probed company) ──
UPDATE [__mj].IntegrationObject
SET APIPath = N'/companies({id})/purchaseCreditMemos({id})/purchaseCreditMemoLines',
    CreateAPIPath = N'/companies({id})/purchaseCreditMemos({id})/purchaseCreditMemoLines',
    UpdateAPIPath = N'/companies({id})/purchaseCreditMemos({id})/purchaseCreditMemoLines({id})',
    DeleteAPIPath = N'/companies({id})/purchaseCreditMemos({id})/purchaseCreditMemoLines({id})'
WHERE ID = 'FCF54CDE-FB14-40BA-B91B-9457F06F0A64';

-- ── 8. customerPayments -> under customerPaymentJournals (live-verified: 200 with rows on the nested path) ──
UPDATE [__mj].IntegrationObject
SET APIPath = N'/companies({id})/customerPaymentJournals({id})/customerPayments',
    CreateAPIPath = N'/companies({id})/customerPaymentJournals({id})/customerPayments',
    UpdateAPIPath = N'/companies({id})/customerPaymentJournals({id})/customerPayments({id})',
    DeleteAPIPath = N'/companies({id})/customerPaymentJournals({id})/customerPayments({id})'
WHERE ID = '9F25B405-AC14-4FCA-805E-DE42A9E85EDF';

-- ── 9. vendorPayments -> under vendorPaymentJournals (live-verified: 200 with rows on the nested path) ──
UPDATE [__mj].IntegrationObject
SET APIPath = N'/companies({id})/vendorPaymentJournals({id})/vendorPayments',
    CreateAPIPath = N'/companies({id})/vendorPaymentJournals({id})/vendorPayments',
    UpdateAPIPath = N'/companies({id})/vendorPaymentJournals({id})/vendorPayments({id})',
    DeleteAPIPath = N'/companies({id})/vendorPaymentJournals({id})/vendorPayments({id})'
WHERE ID = '3AB4FBF5-C78F-4A05-ABE2-C85FC3E510B1';

-- ── 10. timeRegistrationEntries -> under employees (metadata-bound; parent collection empty in the probed company) ──
UPDATE [__mj].IntegrationObject
SET APIPath = N'/companies({id})/employees({id})/timeRegistrationEntries',
    CreateAPIPath = N'/companies({id})/employees({id})/timeRegistrationEntries',
    UpdateAPIPath = N'/companies({id})/employees({id})/timeRegistrationEntries({id})',
    DeleteAPIPath = N'/companies({id})/employees({id})/timeRegistrationEntries({id})'
WHERE ID = 'A53AEE61-19BC-4023-9D50-3BAE9F2FE856';

-- ── 11. contactsInformation -> under customers (live-verified: flat 400 "id type not specified",
--        nested 200) ──
--   POLYMORPHIC PARENT, AND THEREFORE A PARTIAL FIX. Business Central navigates contactInformation
--   from customer, vendor AND contact, and Microsoft documents both
--       /companies({id})/customers({id})/contactsInformation
--       /companies({id})/vendors({id})/contactsInformation
--   Both were confirmed to return HTTP 200 on the live tenant; the flat company-level form returns
--   400 "id type not specified" because it cannot disambiguate the parent type. A single APIPath can
--   express only one chain, so this stamps the customer side — the object goes from reachable-never
--   to reachable-for-customers. VENDOR AND CONTACT CONTACT-INFORMATION REMAIN UNREACHABLE and are
--   NOT silently covered by this row; syncing them needs a separate catalog object per parent, which
--   is a modelling change rather than a path correction and is deliberately not made here.
UPDATE [__mj].IntegrationObject
SET APIPath = N'/companies({id})/customers({id})/contactsInformation'
WHERE ID = 'A8A7B200-5D54-453B-9F25-893EB11BA2B9';
