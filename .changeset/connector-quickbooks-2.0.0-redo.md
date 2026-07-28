---
"@memberjunction/connector-quickbooks": major
---

QuickBooks connector 2.0.0 — REDO (breaking major). A full re-extract of the Intuit Accounting REST API v3 surface, replacing the 1.1.x catalog. Ships as an idempotent delta migration keyed by the immutable 1.1.1 seed UUIDs — the original seed (`V202607111615__quickbooks__Metadata.sql`) is never touched, so tenants already running 1.1.x apply the delta with no Flyway checksum break and no `UQ_IntegrationObject_Name` collision.

**Breaking change — nested reference objects are flattened to dotted child fields.** Where 1.1.x captured a nested reference/complex object as a single field (e.g. `Account.AttachableRef`, `Customer.Fax`), 2.0.0 flattens it to dotted children (`AttachableRef.value`, `Fax.FreeFormNumber`). This is a column-rename with no data loss, but it is not backward-compatible with 1.1.x field names — hence the major bump. 345 surviving-object fields are re-represented this way.

**Catalog scope reconciled to the real testable surface.** The active object catalog is 39 (91 prior − 53 deprecated + 1 added `TaxService`). The 53 removed objects are the abstract/definitional/report envelope types that carry no syncable business records; they are **soft-deprecated** (`Status='Deprecated'`), never pruned, so no applied UUID is re-minted. Object- and field-level arithmetic closes end-to-end: end-state over the 1.1.1 baseline is 92 IOs total / 39 active / 53 deprecated and 2683 active IntegrationObjectFields — verified by applying the exact delivered migration to a fresh 1.1.1 baseline in one shot.

**CredentialTypeID corrected** from `QuickBooks Online OAuth2` to the canonical `QuickBooks Online OAuth` credential type shipped with this Open App.

### What's doable (declared capabilities)

- **39 Integration Objects / 2,683 fields** over the Intuit Accounting REST API v3 — the core accounting surface: `Customer`, `Vendor`, `Employee`, `Invoice`, `Bill`, `Payment`, `BillPayment`, `Estimate`, `PurchaseOrder`, `SalesReceipt`, `CreditMemo`, `RefundReceipt`, `JournalEntry`, `Deposit`, `Transfer`, `Item`, `Account`, `Class`, `Department`, `TaxRate`/`TaxCode`/`TaxAgency`/`TaxService`, `Term`, `PaymentMethod`, `TimeActivity`, `Budget`, and related types.
- **Read (pull): all 39 objects.** 34 use QBO offset pagination (`startPosition` / `maxResults`); 5 singleton/config objects are non-paginated.
- **Incremental sync:** 35 objects carry an `IncrementalWatermarkField` of `MetaData.LastUpdatedTime`, so re-syncs pull only records changed since the last watermark.
- **Write (bidirectional):** the metadata declares **create on 37 objects, update on 36, and delete on the 16 objects QBO permits deletion for**; `TaxService` is create-only. Writes delegate to the generic per-operation CRUD of `BaseRESTIntegrationConnector`.
- **Credential:** `QuickBooks Online OAuth` (OAuth2 authorization-code flow against the Intuit Accounting v3 base URL).

### What was tested (verification)

- **Strict-TypeScript build clean** — `tsc --noEmit` exit 0 against the published `@memberjunction/*` 5.46.0 line; `npm run build` emits `dist`; **38 / 38 unit tests pass**.
- **Migration end-state proven** — the exact delivered SQL-Server migration applied to a fresh 1.1.1 baseline in one shot yields 92 IOs total / 39 active / 53 deprecated / 2,683 active fields; all 946 deprecation statements (53 IO + 893 IOF) land.
- **PostgreSQL twin verified** (`migrations-pg/`) — bracket → unquoted-identifier conversion clean, all 946 deprecation UPDATEs present, migration name/order parity checked.
- **Floor-clean** — `io-name-quality`, `zero-field-io`, `fk-lookup-qualifier` (`@parent:IntegrationID`), and `materializability` graders pass; every declared field maps to a live column (`lint-metadata-fields`); 0 descriptions exceed the `NVARCHAR(255)` catalog limit.
- **Live posture is read-only.** Discovery reads real widths and MJ-discovered custom columns via `mergeDeclaredWithSampledFields` (never-shrink width union). **No live write path is exercised in this release** — the create/update/delete capability above is declared from the vendor contract, not proven against a live company.
