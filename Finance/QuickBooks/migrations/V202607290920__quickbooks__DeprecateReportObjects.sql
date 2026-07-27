-- QuickBooks Online: deprecate the 20 Report.* catalog objects.
--
-- These rows can never produce a synced record, for four independent reasons — every one of
-- them verifiable from this repository alone, with no live credential required.
--
-- 1. NO PRIMARY KEY -> NO MJ ENTITY IS EVER BUILT.
--    Each Report.* row declares exactly ONE field, "Rows" (nvarchar, IsReadOnly=1), described in
--    the catalog as "Report row data in QBO report envelope (Rows.Row[] JSON)". None is marked
--    IsPrimaryKey. SoftPKClassifier's cascade cannot rescue that: universal-convention has no
--    hint, the naming tier matches only <object>Id / <objectSingular>Id / id / uuid / guid, the
--    statistical and composite tiers need sample rows, and the synthetic identity-hash fallback
--    is OFF by default. The verdict is Confident=false, and per the classifier's own contract
--    the pipeline then "leaves the IO row PK-less; no __mj.Entity is created for it until a PK
--    resolves (the runtime D7 rule)". So an operator who selects "all objects" during setup
--    gets 20 rows that silently never materialize.
--
-- 2. A REPORT IS AN ENVELOPE, NOT A RECORD COLLECTION.
--    The QBO Reports API returns a single Header/Columns/Rows document per call. There is no
--    per-record identifier to stamp, and none may be invented — a fabricated key on a field the
--    connector never populates is an always-null primary key, i.e. the same silent failure in
--    a different disguise. Contrast the connector's real entities (Account, Invoice, Customer …),
--    each of which declares Id as IsPrimaryKey=1 with pagination and incremental sync enabled;
--    every Report.* row has SupportsPagination=0, DefaultPageSize=0, SupportsIncrementalSync=0.
--
-- 3. THE CONNECTOR HAS NO REPORT CODE PATH, AND NEVER READS THE DECLARED APIPath.
--    QuickBooksConnector.FetchChanges and .ListRecords both build
--        SELECT * FROM ${ctx.ObjectName} ... STARTPOSITION n MAXRESULTS m
--    and send it to the /query endpoint via ExecuteQuery, then read
--    body.QueryResponse[objectName]. For "Report.BalanceSheet" that emits
--        SELECT * FROM Report.BalanceSheet ...
--    which is not valid QBO query syntax — reports are not queryable entities; they are fetched
--    from /v3/company/{realmId}/reports/{name}, which this connector never calls. The declared
--    APIPath ("v3/company/{realmId}/reports/BalanceSheet") is therefore dead metadata. Both fetch
--    paths also key every row on String(r['Id'] ?? ''), and a report envelope has no Id.
--
-- 4. REDISCOVERY CANNOT REACTIVATE THEM, SO THIS CHANGE IS STABLE.
--    IntegrationSchemaSync implements REACTIVATE-on-rediscover: a non-Active object that
--    reappears in a later discovery flips back to Active. QuickBooksConnector.DiscoverObjects
--    returns the module-level QUICKBOOKS_OBJECTS constant, which lists ten entities (Customer,
--    Vendor, Account, Invoice, Bill, Item, Payment, Employee, Department, Class) and NOT ONE
--    Report.* entry. The reactivation path can never fire for these rows.
--
-- Status is set to 'Deprecated' rather than 'Disabled' deliberately: 'Disabled' carries the
-- schema-sync meaning "the source dropped this object", which is not what happened here — the
-- endpoints exist, they were simply modelled as record objects when they are not. Deprecated
-- removes them from IntegrationEngineBase.GetActiveIntegrationObjects (which filters on
-- Status = 'Active'), so the wizard and the sync pipeline stop offering rows that cannot work.
--
-- Reads of the real QuickBooks entities are entirely unaffected; nothing else in the catalog
-- moves. Re-modelling reports properly would mean a report-specific fetch path in the connector
-- plus a real identity (realm + report + period), which is object authoring, not a key stamp,
-- and is deliberately out of scope here.
--
-- DELTA migration, deliberately not a re-seed: the catalog rows already exist on installed
-- tenants, so the V202607111615 seed stays untouched and applied — no existing UUID is
-- re-minted, no Flyway checksum breaks, no UQ collision. Every statement is idempotent
-- (keyed by the seeded row ID).

-- ── 1. Report.BalanceSheet ──
UPDATE [__mj].IntegrationObject
SET Status      = N'Deprecated',
    Description = N'Balance Sheet report showing assets, liabilities, and equity. Deprecated: not a syncable record set. The QBO Reports API returns one report envelope (Header/Columns/Rows) rather than a collection of identified records, so this catalog row carries a single Rows blob and no primary key — MJ therefore builds no entity for it. QuickBooksConnector has no report code path at all: FetchChanges and ListRecords both issue SELECT * FROM <ObjectName> against the /query endpoint (reports are not queryable entities) and key every record on r[''Id''], which a report has no equivalent of; the declared reports APIPath is never read. The connector''s own QUICKBOOKS_OBJECTS constant — the source for DiscoverObjects — contains no Report.* entry, so rediscovery will not reactivate this row.'
WHERE ID = '9C283798-FE1E-4A22-8690-8383F561738B';

-- ── 2. Report.ProfitAndLoss ──
UPDATE [__mj].IntegrationObject
SET Status      = N'Deprecated',
    Description = N'Profit and Loss (income statement) report. Deprecated: not a syncable record set. The QBO Reports API returns one report envelope (Header/Columns/Rows) rather than a collection of identified records, so this catalog row carries a single Rows blob and no primary key — MJ therefore builds no entity for it. QuickBooksConnector has no report code path at all: FetchChanges and ListRecords both issue SELECT * FROM <ObjectName> against the /query endpoint (reports are not queryable entities) and key every record on r[''Id''], which a report has no equivalent of; the declared reports APIPath is never read. The connector''s own QUICKBOOKS_OBJECTS constant — the source for DiscoverObjects — contains no Report.* entry, so rediscovery will not reactivate this row.'
WHERE ID = '75282697-12A7-4C60-98DA-73721AFE4A69';

-- ── 3. Report.ProfitAndLossDetail ──
UPDATE [__mj].IntegrationObject
SET Status      = N'Deprecated',
    Description = N'Detailed Profit and Loss report with transaction drill-down. Deprecated: not a syncable record set. The QBO Reports API returns one report envelope (Header/Columns/Rows) rather than a collection of identified records, so this catalog row carries a single Rows blob and no primary key — MJ therefore builds no entity for it. QuickBooksConnector has no report code path at all: FetchChanges and ListRecords both issue SELECT * FROM <ObjectName> against the /query endpoint (reports are not queryable entities) and key every record on r[''Id''], which a report has no equivalent of; the declared reports APIPath is never read. The connector''s own QUICKBOOKS_OBJECTS constant — the source for DiscoverObjects — contains no Report.* entry, so rediscovery will not reactivate this row.'
WHERE ID = '1509DD86-7078-4D07-AC1F-258933EF2B47';

-- ── 4. Report.TrialBalance ──
UPDATE [__mj].IntegrationObject
SET Status      = N'Deprecated',
    Description = N'Trial Balance listing all account debits and credits. Deprecated: not a syncable record set. The QBO Reports API returns one report envelope (Header/Columns/Rows) rather than a collection of identified records, so this catalog row carries a single Rows blob and no primary key — MJ therefore builds no entity for it. QuickBooksConnector has no report code path at all: FetchChanges and ListRecords both issue SELECT * FROM <ObjectName> against the /query endpoint (reports are not queryable entities) and key every record on r[''Id''], which a report has no equivalent of; the declared reports APIPath is never read. The connector''s own QUICKBOOKS_OBJECTS constant — the source for DiscoverObjects — contains no Report.* entry, so rediscovery will not reactivate this row.'
WHERE ID = '64C144F3-2DC2-4550-A609-FB9E3F97B398';

-- ── 5. Report.GeneralLedger ──
UPDATE [__mj].IntegrationObject
SET Status      = N'Deprecated',
    Description = N'General Ledger report with full transaction history per account. Deprecated: not a syncable record set. The QBO Reports API returns one report envelope (Header/Columns/Rows) rather than a collection of identified records, so this catalog row carries a single Rows blob and no primary key — MJ therefore builds no entity for it. QuickBooksConnector has no report code path at all: FetchChanges and ListRecords both issue SELECT * FROM <ObjectName> against the /query endpoint (reports are not queryable entities) and key every record on r[''Id''], which a report has no equivalent of; the declared reports APIPath is never read. The connector''s own QUICKBOOKS_OBJECTS constant — the source for DiscoverObjects — contains no Report.* entry, so rediscovery will not reactivate this row.'
WHERE ID = '6CB05968-640B-484B-A0BB-F199D5345BB5';

-- ── 6. Report.CashFlow ──
UPDATE [__mj].IntegrationObject
SET Status      = N'Deprecated',
    Description = N'Cash Flow statement report. Deprecated: not a syncable record set. The QBO Reports API returns one report envelope (Header/Columns/Rows) rather than a collection of identified records, so this catalog row carries a single Rows blob and no primary key — MJ therefore builds no entity for it. QuickBooksConnector has no report code path at all: FetchChanges and ListRecords both issue SELECT * FROM <ObjectName> against the /query endpoint (reports are not queryable entities) and key every record on r[''Id''], which a report has no equivalent of; the declared reports APIPath is never read. The connector''s own QUICKBOOKS_OBJECTS constant — the source for DiscoverObjects — contains no Report.* entry, so rediscovery will not reactivate this row.'
WHERE ID = 'C6D75084-651A-466D-A563-7F17E9462C58';

-- ── 7. Report.CustomerBalance ──
UPDATE [__mj].IntegrationObject
SET Status      = N'Deprecated',
    Description = N'Customer open balance summary. Deprecated: not a syncable record set. The QBO Reports API returns one report envelope (Header/Columns/Rows) rather than a collection of identified records, so this catalog row carries a single Rows blob and no primary key — MJ therefore builds no entity for it. QuickBooksConnector has no report code path at all: FetchChanges and ListRecords both issue SELECT * FROM <ObjectName> against the /query endpoint (reports are not queryable entities) and key every record on r[''Id''], which a report has no equivalent of; the declared reports APIPath is never read. The connector''s own QUICKBOOKS_OBJECTS constant — the source for DiscoverObjects — contains no Report.* entry, so rediscovery will not reactivate this row.'
WHERE ID = '3E1614CD-D7CD-42C0-9442-0B5314272558';

-- ── 8. Report.CustomerBalanceDetail ──
UPDATE [__mj].IntegrationObject
SET Status      = N'Deprecated',
    Description = N'Customer open balance with per-transaction detail. Deprecated: not a syncable record set. The QBO Reports API returns one report envelope (Header/Columns/Rows) rather than a collection of identified records, so this catalog row carries a single Rows blob and no primary key — MJ therefore builds no entity for it. QuickBooksConnector has no report code path at all: FetchChanges and ListRecords both issue SELECT * FROM <ObjectName> against the /query endpoint (reports are not queryable entities) and key every record on r[''Id''], which a report has no equivalent of; the declared reports APIPath is never read. The connector''s own QUICKBOOKS_OBJECTS constant — the source for DiscoverObjects — contains no Report.* entry, so rediscovery will not reactivate this row.'
WHERE ID = '686B6858-D932-4088-9B55-EA0908F40EF7';

-- ── 9. Report.CustomerSales ──
UPDATE [__mj].IntegrationObject
SET Status      = N'Deprecated',
    Description = N'Sales by Customer summary report. Deprecated: not a syncable record set. The QBO Reports API returns one report envelope (Header/Columns/Rows) rather than a collection of identified records, so this catalog row carries a single Rows blob and no primary key — MJ therefore builds no entity for it. QuickBooksConnector has no report code path at all: FetchChanges and ListRecords both issue SELECT * FROM <ObjectName> against the /query endpoint (reports are not queryable entities) and key every record on r[''Id''], which a report has no equivalent of; the declared reports APIPath is never read. The connector''s own QUICKBOOKS_OBJECTS constant — the source for DiscoverObjects — contains no Report.* entry, so rediscovery will not reactivate this row.'
WHERE ID = 'EDD9A1FF-A976-48F8-8C32-06D93F0D5574';

-- ── 10. Report.CustomerSalesDetail ──
UPDATE [__mj].IntegrationObject
SET Status      = N'Deprecated',
    Description = N'Sales by Customer with per-transaction detail. Deprecated: not a syncable record set. The QBO Reports API returns one report envelope (Header/Columns/Rows) rather than a collection of identified records, so this catalog row carries a single Rows blob and no primary key — MJ therefore builds no entity for it. QuickBooksConnector has no report code path at all: FetchChanges and ListRecords both issue SELECT * FROM <ObjectName> against the /query endpoint (reports are not queryable entities) and key every record on r[''Id''], which a report has no equivalent of; the declared reports APIPath is never read. The connector''s own QUICKBOOKS_OBJECTS constant — the source for DiscoverObjects — contains no Report.* entry, so rediscovery will not reactivate this row.'
WHERE ID = '8C9AE0BF-EA6B-43A3-814B-9AD3B41F889C';

-- ── 11. Report.VendorBalance ──
UPDATE [__mj].IntegrationObject
SET Status      = N'Deprecated',
    Description = N'Vendor open balance summary. Deprecated: not a syncable record set. The QBO Reports API returns one report envelope (Header/Columns/Rows) rather than a collection of identified records, so this catalog row carries a single Rows blob and no primary key — MJ therefore builds no entity for it. QuickBooksConnector has no report code path at all: FetchChanges and ListRecords both issue SELECT * FROM <ObjectName> against the /query endpoint (reports are not queryable entities) and key every record on r[''Id''], which a report has no equivalent of; the declared reports APIPath is never read. The connector''s own QUICKBOOKS_OBJECTS constant — the source for DiscoverObjects — contains no Report.* entry, so rediscovery will not reactivate this row.'
WHERE ID = 'AB93C5B9-7989-4EA0-BB27-3A32B397E58A';

-- ── 12. Report.VendorBalanceDetail ──
UPDATE [__mj].IntegrationObject
SET Status      = N'Deprecated',
    Description = N'Vendor open balance with per-transaction detail. Deprecated: not a syncable record set. The QBO Reports API returns one report envelope (Header/Columns/Rows) rather than a collection of identified records, so this catalog row carries a single Rows blob and no primary key — MJ therefore builds no entity for it. QuickBooksConnector has no report code path at all: FetchChanges and ListRecords both issue SELECT * FROM <ObjectName> against the /query endpoint (reports are not queryable entities) and key every record on r[''Id''], which a report has no equivalent of; the declared reports APIPath is never read. The connector''s own QUICKBOOKS_OBJECTS constant — the source for DiscoverObjects — contains no Report.* entry, so rediscovery will not reactivate this row.'
WHERE ID = 'A5963CB3-5B0A-4E99-86AA-72E678705CB9';

-- ── 13. Report.VendorExpenses ──
UPDATE [__mj].IntegrationObject
SET Status      = N'Deprecated',
    Description = N'Expenses by Vendor summary. Deprecated: not a syncable record set. The QBO Reports API returns one report envelope (Header/Columns/Rows) rather than a collection of identified records, so this catalog row carries a single Rows blob and no primary key — MJ therefore builds no entity for it. QuickBooksConnector has no report code path at all: FetchChanges and ListRecords both issue SELECT * FROM <ObjectName> against the /query endpoint (reports are not queryable entities) and key every record on r[''Id''], which a report has no equivalent of; the declared reports APIPath is never read. The connector''s own QUICKBOOKS_OBJECTS constant — the source for DiscoverObjects — contains no Report.* entry, so rediscovery will not reactivate this row.'
WHERE ID = 'CC5ADFE2-22AE-4A17-989B-B9A39C339636';

-- ── 14. Report.AgedReceivables ──
UPDATE [__mj].IntegrationObject
SET Status      = N'Deprecated',
    Description = N'Aged Receivables summary (customer aging). Deprecated: not a syncable record set. The QBO Reports API returns one report envelope (Header/Columns/Rows) rather than a collection of identified records, so this catalog row carries a single Rows blob and no primary key — MJ therefore builds no entity for it. QuickBooksConnector has no report code path at all: FetchChanges and ListRecords both issue SELECT * FROM <ObjectName> against the /query endpoint (reports are not queryable entities) and key every record on r[''Id''], which a report has no equivalent of; the declared reports APIPath is never read. The connector''s own QUICKBOOKS_OBJECTS constant — the source for DiscoverObjects — contains no Report.* entry, so rediscovery will not reactivate this row.'
WHERE ID = '40077B9E-16F9-473E-B730-A5914AEBE286';

-- ── 15. Report.AgedReceivableDetail ──
UPDATE [__mj].IntegrationObject
SET Status      = N'Deprecated',
    Description = N'Aged Receivables with per-invoice detail. Deprecated: not a syncable record set. The QBO Reports API returns one report envelope (Header/Columns/Rows) rather than a collection of identified records, so this catalog row carries a single Rows blob and no primary key — MJ therefore builds no entity for it. QuickBooksConnector has no report code path at all: FetchChanges and ListRecords both issue SELECT * FROM <ObjectName> against the /query endpoint (reports are not queryable entities) and key every record on r[''Id''], which a report has no equivalent of; the declared reports APIPath is never read. The connector''s own QUICKBOOKS_OBJECTS constant — the source for DiscoverObjects — contains no Report.* entry, so rediscovery will not reactivate this row.'
WHERE ID = '17DBF942-1ED8-43E4-9313-FE65189C81D7';

-- ── 16. Report.AgedPayables ──
UPDATE [__mj].IntegrationObject
SET Status      = N'Deprecated',
    Description = N'Aged Payables summary (vendor aging). Deprecated: not a syncable record set. The QBO Reports API returns one report envelope (Header/Columns/Rows) rather than a collection of identified records, so this catalog row carries a single Rows blob and no primary key — MJ therefore builds no entity for it. QuickBooksConnector has no report code path at all: FetchChanges and ListRecords both issue SELECT * FROM <ObjectName> against the /query endpoint (reports are not queryable entities) and key every record on r[''Id''], which a report has no equivalent of; the declared reports APIPath is never read. The connector''s own QUICKBOOKS_OBJECTS constant — the source for DiscoverObjects — contains no Report.* entry, so rediscovery will not reactivate this row.'
WHERE ID = '5C83870C-B652-47BA-AC2A-B6873C8B5120';

-- ── 17. Report.AgedPayableDetail ──
UPDATE [__mj].IntegrationObject
SET Status      = N'Deprecated',
    Description = N'Aged Payables with per-bill detail. Deprecated: not a syncable record set. The QBO Reports API returns one report envelope (Header/Columns/Rows) rather than a collection of identified records, so this catalog row carries a single Rows blob and no primary key — MJ therefore builds no entity for it. QuickBooksConnector has no report code path at all: FetchChanges and ListRecords both issue SELECT * FROM <ObjectName> against the /query endpoint (reports are not queryable entities) and key every record on r[''Id''], which a report has no equivalent of; the declared reports APIPath is never read. The connector''s own QUICKBOOKS_OBJECTS constant — the source for DiscoverObjects — contains no Report.* entry, so rediscovery will not reactivate this row.'
WHERE ID = '1160A781-7B21-4149-9812-26DC02C59AEB';

-- ── 18. Report.InventoryValuationSummary ──
UPDATE [__mj].IntegrationObject
SET Status      = N'Deprecated',
    Description = N'Inventory valuation summary. Deprecated: not a syncable record set. The QBO Reports API returns one report envelope (Header/Columns/Rows) rather than a collection of identified records, so this catalog row carries a single Rows blob and no primary key — MJ therefore builds no entity for it. QuickBooksConnector has no report code path at all: FetchChanges and ListRecords both issue SELECT * FROM <ObjectName> against the /query endpoint (reports are not queryable entities) and key every record on r[''Id''], which a report has no equivalent of; the declared reports APIPath is never read. The connector''s own QUICKBOOKS_OBJECTS constant — the source for DiscoverObjects — contains no Report.* entry, so rediscovery will not reactivate this row.'
WHERE ID = 'F10253C6-9120-4932-A958-2FB0679E0164';

-- ── 19. Report.ItemSales ──
UPDATE [__mj].IntegrationObject
SET Status      = N'Deprecated',
    Description = N'Sales by Product/Service summary. Deprecated: not a syncable record set. The QBO Reports API returns one report envelope (Header/Columns/Rows) rather than a collection of identified records, so this catalog row carries a single Rows blob and no primary key — MJ therefore builds no entity for it. QuickBooksConnector has no report code path at all: FetchChanges and ListRecords both issue SELECT * FROM <ObjectName> against the /query endpoint (reports are not queryable entities) and key every record on r[''Id''], which a report has no equivalent of; the declared reports APIPath is never read. The connector''s own QUICKBOOKS_OBJECTS constant — the source for DiscoverObjects — contains no Report.* entry, so rediscovery will not reactivate this row.'
WHERE ID = '7DE762BD-14B3-4082-A496-4E815A98A651';

-- ── 20. Report.TaxSummary ──
UPDATE [__mj].IntegrationObject
SET Status      = N'Deprecated',
    Description = N'Sales tax liability summary. Deprecated: not a syncable record set. The QBO Reports API returns one report envelope (Header/Columns/Rows) rather than a collection of identified records, so this catalog row carries a single Rows blob and no primary key — MJ therefore builds no entity for it. QuickBooksConnector has no report code path at all: FetchChanges and ListRecords both issue SELECT * FROM <ObjectName> against the /query endpoint (reports are not queryable entities) and key every record on r[''Id''], which a report has no equivalent of; the declared reports APIPath is never read. The connector''s own QUICKBOOKS_OBJECTS constant — the source for DiscoverObjects — contains no Report.* entry, so rediscovery will not reactivate this row.'
WHERE ID = '61E177B1-FFAB-4D92-B02E-C6D722B817EE';
