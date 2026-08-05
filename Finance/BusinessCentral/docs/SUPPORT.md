# Microsoft Dynamics 365 Business Central — Supported & Proven

> **Evidence tier:** 🧪 Mock-only (proven vs mock server, never live)  ·  **Last verified:** 2026-08-05  ·  **Proof DB(s):** MJ_BC_E2E

## What this integration supports

**83 objects** declared (source: `.business-central.integration.json`). 54 declare a write path; 29 are read-only (pull).

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| accounts | ✓ | — (read-only) | ✓ |
| accountingPeriods | ✓ | — (read-only) | ✓ |
| agedAccountsPayables | ✓ | — (read-only) | — |
| agedAccountsReceivables | ✓ | — (read-only) | — |
| applyVendorEntries | ✓ | `-U-` | ✓ |
| attachments | ✓ | `CUD` | ✓ |
| balanceSheets | ✓ | — (read-only) | — |
| bankAccounts | ✓ | `CUD` | ✓ |
| cashFlowStatements | ✓ | — (read-only) | — |
| companies | ✓ | — (read-only) | — |
| companyInformation | ✓ | `-U-` | ✓ |
| contacts | ✓ | `CUD` | ✓ |
| contactsInformation | ✓ | — (read-only) | — |
| countriesRegions | ✓ | `CUD` | ✓ |
| currencies | ✓ | `CUD` | ✓ |
| currencyExchangeRates | ✓ | — (read-only) | ✓ |
| customers | ✓ | `CUD` | ✓ |
| customerContacts | ✓ | `-UD` | — |
| customerFinancialDetails | ✓ | — (read-only) | ✓ |
| customerPayments | ✓ | `CUD` | ✓ |
| customerPaymentJournals | ✓ | `CUD` | ✓ |
| customerReturnReasons | ✓ | `CUD` | ✓ |
| customerSales | ✓ | — (read-only) | — |
| defaultDimensions | ✓ | `CUD` | ✓ |
| dimensions | ✓ | — (read-only) | ✓ |
| dimensionSetLines | ✓ | `CUD` | — |
| dimensionValues | ✓ | — (read-only) | ✓ |
| disputeStatus | ✓ | `CUD` | — |
| documentAttachments | ✓ | `CUD` | ✓ |
| employees | ✓ | `CUD` | ✓ |
| fixedAssets | ✓ | `CUD` | ✓ |
| fixedAssetLocations | ✓ | `CUD` | ✓ |
| generalLedgerEntries | ✓ | — (read-only) | ✓ |
| generalLedgerSetup | ✓ | — (read-only) | ✓ |
| generalProductPostingGroups | ✓ | — (read-only) | ✓ |
| incomeStatements | ✓ | — (read-only) | — |
| inventoryPostingGroups | ✓ | — (read-only) | ✓ |
| items | ✓ | `CUD` | ✓ |
| itemCategories | ✓ | `CUD` | ✓ |
| itemLedgerEntries | ✓ | — (read-only) | ✓ |
| itemVariants | ✓ | `CUD` | ✓ |
| jobQueueEntries | ✓ | — (read-only) | ✓ |
| jobQueueLogEntries | ✓ | — (read-only) | ✓ |
| journals | ✓ | `CUD` | ✓ |
| journalLines | ✓ | `CUD` | ✓ |
| locations | ✓ | `CUD` | ✓ |
| opportunities | ✓ | `CUD` | ✓ |
| paymentMethods | ✓ | `CUD` | ✓ |
| paymentTerms | ✓ | `CUD` | ✓ |
| pdfDocument | ✓ | — (read-only) | — |
| picture | ✓ | `-UD` | — |
| projects | ✓ | `CUD` | ✓ |
| purchaseCreditMemos | ✓ | `CUD` | ✓ |
| purchaseCreditMemoLines | ✓ | `CUD` | — |
| purchaseInvoices | ✓ | `CUD` | ✓ |
| purchaseInvoiceLines | ✓ | `CUD` | — |
| purchaseOrders | ✓ | `CUD` | ✓ |
| purchaseOrderLines | ✓ | `CUD` | — |
| purchaseReceipts | ✓ | — (read-only) | ✓ |
| purchaseReceiptLines | ✓ | — (read-only) | — |
| retainedEarningsStatements | ✓ | — (read-only) | — |
| salesCreditMemos | ✓ | `CUD` | ✓ |
| salesCreditMemoLines | ✓ | `CUD` | — |
| salesInvoices | ✓ | `CUD` | ✓ |
| salesInvoiceLines | ✓ | `CUD` | — |
| salesOrders | ✓ | `CUD` | ✓ |
| salesOrderLines | ✓ | `CUD` | — |
| salespeoplePurchasers | ✓ | `CUD` | ✓ |
| salesQuotes | ✓ | `CUD` | ✓ |
| salesQuoteLines | ✓ | `CUD` | — |
| salesShipments | ✓ | — (read-only) | ✓ |
| salesShipmentLines | ✓ | — (read-only) | — |
| shipmentMethods | ✓ | `CUD` | ✓ |
| subscriptions | ✓ | `CUD` | ✓ |
| taxAreas | ✓ | `CUD` | ✓ |
| taxGroups | ✓ | `CUD` | ✓ |
| timeRegistrationEntries | ✓ | `CUD` | — |
| trialBalances | ✓ | — (read-only) | — |
| unitsOfMeasure | ✓ | `CUD` | ✓ |
| vendors | ✓ | `CUD` | ✓ |
| vendorPayments | ✓ | `CUD` | ✓ |
| vendorPaymentJournals | ✓ | `CUD` | ✓ |
| vendorPurchases | ✓ | — (read-only) | — |

## What is proven

### Pull (read)

> 🧪 **These rows came from the MOCK vendor server, not from Microsoft Dynamics 365 Business Central.** They are genuine rows — the connector, the sync engine, the field mapping and the SQL upsert are all the production code paths, and the counts below were read straight out of the database — but the HTTP peer was a fixture replay. They prove the connector *works*; they do **not** prove anything about real Microsoft Dynamics 365 Business Central data, real payload variety, or real rate behaviour. Only a credential closes that.

| Object | Label | Rows (DB-verified) | Which DB |
|---|---|---|---|
| customers | Proven | 5 | MJ_BC_E2E |
| accountingPeriods | Proven | 3 | MJ_BC_E2E |
| accounts | Proven | 3 | MJ_BC_E2E |
| agedAccountsPayables | Proven | 3 | MJ_BC_E2E |
| agedAccountsReceivables | Proven | 3 | MJ_BC_E2E |
| applyVendorEntries | Proven | 3 | MJ_BC_E2E |
| attachments | Proven | 3 | MJ_BC_E2E |
| balanceSheets | Proven | 3 | MJ_BC_E2E |
| bankAccounts | Proven | 3 | MJ_BC_E2E |
| cashFlowStatements | Proven | 3 | MJ_BC_E2E |
| companies | Proven | 3 | MJ_BC_E2E |
| companyInformation | Proven | 3 | MJ_BC_E2E |
| contacts | Proven | 3 | MJ_BC_E2E |
| contactsInformation | Proven | 3 | MJ_BC_E2E |
| countriesRegions | Proven | 3 | MJ_BC_E2E |
| currencies | Proven | 3 | MJ_BC_E2E |
| currencyExchangeRates | Proven | 3 | MJ_BC_E2E |
| customerContacts | Proven | 3 | MJ_BC_E2E |
| customerFinancialDetails | Proven | 3 | MJ_BC_E2E |
| customerPaymentJournals | Proven | 3 | MJ_BC_E2E |
| customerPayments | Proven | 3 | MJ_BC_E2E |
| customerReturnReasons | Proven | 3 | MJ_BC_E2E |
| customerSales | Proven | 3 | MJ_BC_E2E |
| defaultDimensions | Proven | 3 | MJ_BC_E2E |
| dimensions | Proven | 3 | MJ_BC_E2E |
| dimensionSetLines | Proven | 3 | MJ_BC_E2E |
| dimensionValues | Proven | 3 | MJ_BC_E2E |
| disputeStatus | Proven | 3 | MJ_BC_E2E |
| documentAttachments | Proven | 3 | MJ_BC_E2E |
| employees | Proven | 3 | MJ_BC_E2E |
| fixedAssetLocations | Proven | 3 | MJ_BC_E2E |
| fixedAssets | Proven | 3 | MJ_BC_E2E |
| generalLedgerEntries | Proven | 3 | MJ_BC_E2E |
| generalLedgerSetup | Proven | 3 | MJ_BC_E2E |
| generalProductPostingGroups | Proven | 3 | MJ_BC_E2E |
| incomeStatements | Proven | 3 | MJ_BC_E2E |
| inventoryPostingGroups | Proven | 3 | MJ_BC_E2E |
| itemCategories | Proven | 3 | MJ_BC_E2E |
| itemLedgerEntries | Proven | 3 | MJ_BC_E2E |
| items | Proven | 3 | MJ_BC_E2E |
| itemVariants | Proven | 3 | MJ_BC_E2E |
| jobQueueEntries | Proven | 3 | MJ_BC_E2E |
| jobQueueLogEntries | Proven | 3 | MJ_BC_E2E |
| journalLines | Proven | 3 | MJ_BC_E2E |
| journals | Proven | 3 | MJ_BC_E2E |
| locations | Proven | 3 | MJ_BC_E2E |
| opportunities | Proven | 3 | MJ_BC_E2E |
| paymentMethods | Proven | 3 | MJ_BC_E2E |
| paymentTerms | Proven | 3 | MJ_BC_E2E |
| pdfDocument | Proven | 3 | MJ_BC_E2E |
| picture | Proven | 3 | MJ_BC_E2E |
| projects | Proven | 3 | MJ_BC_E2E |
| purchaseCreditMemoLines | Proven | 3 | MJ_BC_E2E |
| purchaseCreditMemos | Proven | 3 | MJ_BC_E2E |
| purchaseInvoiceLines | Proven | 3 | MJ_BC_E2E |
| purchaseInvoices | Proven | 3 | MJ_BC_E2E |
| purchaseOrderLines | Proven | 3 | MJ_BC_E2E |
| purchaseOrders | Proven | 3 | MJ_BC_E2E |
| purchaseReceiptLines | Proven | 3 | MJ_BC_E2E |
| purchaseReceipts | Proven | 3 | MJ_BC_E2E |
| retainedEarningsStatements | Proven | 3 | MJ_BC_E2E |
| salesCreditMemoLines | Proven | 3 | MJ_BC_E2E |
| salesCreditMemos | Proven | 3 | MJ_BC_E2E |
| salesInvoiceLines | Proven | 3 | MJ_BC_E2E |
| salesInvoices | Proven | 3 | MJ_BC_E2E |
| salesOrderLines | Proven | 3 | MJ_BC_E2E |
| salesOrders | Proven | 3 | MJ_BC_E2E |
| salespeoplePurchasers | Proven | 3 | MJ_BC_E2E |
| salesQuoteLines | Proven | 3 | MJ_BC_E2E |
| salesQuotes | Proven | 3 | MJ_BC_E2E |
| salesShipmentLines | Proven | 3 | MJ_BC_E2E |
| salesShipments | Proven | 3 | MJ_BC_E2E |
| shipmentMethods | Proven | 3 | MJ_BC_E2E |
| subscriptions | Proven | 3 | MJ_BC_E2E |
| taxAreas | Proven | 3 | MJ_BC_E2E |
| taxGroups | Proven | 3 | MJ_BC_E2E |
| timeRegistrationEntries | Proven | 3 | MJ_BC_E2E |
| trialBalances | Proven | 3 | MJ_BC_E2E |
| unitsOfMeasure | Proven | 3 | MJ_BC_E2E |
| vendorPaymentJournals | Proven | 3 | MJ_BC_E2E |
| vendorPayments | Proven | 3 | MJ_BC_E2E |
| vendorPurchases | Proven | 3 | MJ_BC_E2E |
| vendors | Proven | 3 | MJ_BC_E2E |

**Total proven rows: 251** across 83 of 83 declared objects.

> ✅ **Coverage: 83 of 83 declared objects (FULL CATALOG).** Every declared object landed rows — this is an "all objects" MJCentral-parity run, not a subset. No object in the catalog is untested.

### Push (write / bidirectional)

- **Status: Mock-verified, full write surface.** Every one of the **50 flat-writable objects** completed a
  create → update → delete round-trip against a *stateful* mock vendor store, and each leg was asserted
  twice: once that the operation succeeded with a non-empty `ExternalID`, and once on the **request shape**
  (method, URL segment nesting, body) actually put on the wire. `bidirectional.coverage.all-writable`
  records `flatWritableObjects=50, roundTripped=50, missing=[]`. Four writable objects
  (`applyVendorEntries`, `companyInformation`, `customerContacts`, `picture`) are template-path or nested
  writes and are structural skips, listed explicitly rather than dropped.
- **Declared write surface (metadata):** 54 of 83 objects declare a substantiated write path.
- **No live write side-effect has been executed or verified.** The store the writes landed in is a mock.
  What is proven is that the connector forms the correct request and correctly reads the created record's
  identity back out of the response; what is *not* proven is that Business Central accepts it. Only a
  credential closes that, and none exists.
- **Delete semantics remain formally UNPROVEN.** BC's `Integration.Configuration` sets
  `DeleteSemantics=null` with an explicit note that no reviewed fact family states whether a BC `DELETE`
  hard-deletes or soft-archives. The connector deliberately does not guess. The delete round-trip proves
  the connector *issues* a correct DELETE, not what BC does with it.

## How thoroughly this was tested

> **Suite:** hybrid-e2e (the deep behavioural suite — real MJAPI + real SQL Server + a mock HTTP peer)
> · **Run:** 2026-08-05 (run 25) · **Result:** **517 assertions passed, 0 failed, `ok: true`**
> · **Verdict:** GENUINE-GREEN-MOCK

This is the full behavioural suite, not a smoke test. The connector was deployed into an isolated database
(`MJ_BC_E2E`), its whole 83-object catalog materialised via ApplyAll, and synced through a live MJAPI
instance — the same code path a customer runs. Forward sync moved **251 of 251 records with 0 failures**,
and **all 83 declared objects landed rows**.

**Independently verified (not self-reported by the suite):** row counts were re-counted directly in SQL
Server, outside the suite — `tables=83, totalRows=251, zeroRowTables=0`. A suite reporting its own success
is exactly the failure mode this document exists to catch: an earlier run of this connector produced a
*vacuous* green on the delete rung purely because no rows had ever landed.

### 🚨 Four of these results depend on MJ engine fixes that are not yet in MJ `next`

This is the single most important caveat on the page, and it is stated before the results rather than
after them. The run above was executed against an MJ build carrying **two engine changes** that are not in
`@memberjunction/integration-engine` as published. A **control run against the stock engine, changing
nothing else, scores 513 passed / 4 failed** (`ok: false`):

| Cell | Stock-engine result | Cause |
|---|---|---|
| `forward.full.clean` | 245 succeeded, **6 failed** — `no rows returned from SQL` | Concurrent `RunView` calls share one connection; `LoadFieldMaps` silently degraded to an empty map set instead of throwing |
| `forward.incremental.narrowed` | `mode=NEITHER` — 251 processed, 6 succeeded | knock-on of the above: records that never landed cannot content-hash-skip |
| `coverage.all-objects` | `zeroRowReal=1` (`currencyExchangeRates`) | knock-on |
| `retry.transient-recovers` | `retryEvents=0, processed=0` | a 5xx is not classified as retryable, so the fetch is swallowed rather than retried |

Both are **cross-vendor MJ engine defects**, not BC scaffolding — the field-map load path and the error
classifier are shared by every connector — and they are being raised as a separate MJ pull request. But
the honest statement is: **the 517/0 above cannot be claimed against a stock MJ engine today.** Against
stock MJ, this connector scores 513/4. The connector-side fixes in this PR stand on their own; these four
cells do not.

### Passed on strong evidence

Each of these asserted a real outcome against real numbers. The measurement is given so a reader can judge
the claim rather than trust the word "passed".

| Behaviour | What was actually measured |
|---|---|
| `setup` | scoped ApplyAll materialised all 83 declared objects, created 83 entity maps, 0 warnings |
| `forward.full.run` | `Processed 251 / Succeeded 251 / Failed 0 / Skipped 0`, `exitReason=completed`, 0 errors |
| `forward.full.nodataloss` | 0 dropped-record warnings — no record silently counted as Skipped and lost |
| `forward.completeness` | per object: destination rows > 0 AND `recordMapOneToOne=true`, checked for **all 83 objects** |
| `coverage.all-objects` | `deployedObjects=83, coveredWithRows=83, zeroRowReal=0, untestedSyncableObjects=0` |
| `watermark.gte-filter-issued` | `strategy=server-side-filter` — a real `?$filter=lastModifiedDateTime gt …` observed on the wire across 109 recorded requests |
| `forward.incremental.narrowed` | `mode=content-hash-skip` — 251 processed, **0 written** on unchanged data |
| `idempotent.no-redundant-writes` | second pass: `Processed 248 / Succeeded 0 / Skipped 248` — zero redundant writes |
| `idempotent.rows-stable` | row counts identical before and after, checked on **every one of the 83 entities** |
| `delta.0.update` | changed source record propagated and the destination field read back **by value** (`displayName` → `Fixture customers 1 (updated)`) |
| `delta.1.present` | a newly-appearing external ID propagated and landed as a new destination row |
| `delta.2.delete` | a source deletion propagated — `outcome=hard-deleted (row removed)`, verified against a table that genuinely had rows in it |
| `custom.overflow-captured` | an unmapped vendor key reached `__mj_integration_CustomOverflow` on `Customers` |
| `custom.candidate-surfaced` | `Customers.mj_e2e_ovf_late(string)` surfaced as a promotion candidate |
| `custom.promoted` | promotion added 1 real column |
| `custom.column-minted` | **both** the physical table column and its `EntityField` verified present after CodeGen |
| `dag.full-hierarchy` | 83 objects, 106 FK edges, 4 layers (46/12/17/8), 0 unplaced, 0 cycles |
| `merkle.unchanged-partition-skipped` | partition rollup-hash match ⇒ batch skipped with 0 writes on the reconcile re-sync |
| `discover-columns.fields-present` | 1,484 `IntegrationObjectField` rows surfaced — column discovery is not vacuous |
| `discover-overlay.absence-does-not-deactivate` | `vendors` genuinely omitted from the served catalog; `statusAfter=Active` — a non-authoritative discovery correctly does **not** deactivate |
| `retry.transient-recovers` | a one-shot 500 retried through to clean completion **and the retried fetch landed records** (`processed=5`) — a zero-processed "clean" run would be a swallowed fetch, not a recovery |
| `concurrency.within-layer-parallel` | sibling-object requests landed within a 5 ms window — within-layer parallelism observed on the wire |
| `scheduled-job.*` | a job created, listed, toggled and deleted through the live API |
| `bidirectional.*` (50 objects × 6) | create/update/delete each asserted for success **and** request shape |
| `teardown` | 83 entity maps deleted with field maps, watermarks and record maps; the pre-seeded connection and encrypted credential left intact |

### Passed, but on thin evidence — do not read these as proven

The suite reported `ok`. In each case the sample was too small to demonstrate the behaviour, and saying so
is more useful than the pass.

| Behaviour | Why it is thin |
|---|---|
| `pagination.non-advancing-bounded` | proves the **anti-infinite-loop guard** only: `pageRequests=1, processed=2`. Termination: proven. Paging through a real multi-page result set: not proven. |
| `rate-limit.backoff-and-recover` | `retryEvents=0` over 5 list-route requests. The run completed cleanly through a 429 window, which is all this shows; AIMD backoff and `Retry-After` honouring are **not** demonstrated. |
| `retry.watermark-not-advanced` | correct outcome (`before == after`) but over `Processed 0` — no work occurred, so the assertion carries little weight. |
| `dag.topological-layering` | `hasParentChildEdge=false` — the objects selected for this cell had no parent-child edge, so parent-before-child *ordering* was never put to the test. Shape proven, ordering not. |
| `discover-columns.softpk-inference` | 0 soft-PK verdicts — the credential-free mock cannot feed the classifier real describe/sample data. The classifier is unit-proven elsewhere; this run does not exercise it. |

### Skipped with a stated reason

- **`backward`** — mock mode; there is no live vendor store for a real write round-trip.

### Behaviours NOT asserted at all

- Any behaviour of the **real** Business Central API — payload variety, real pagination volumes, real error
  bodies, real throttling. The HTTP peer was a fixture replay throughout.
- Live **write side-effects** — no record has ever been created, updated or deleted in a real BC tenant.
- **Multi-page cursor following** against a real result set (only the termination guard was exercised).
- **Backoff and `Retry-After` handling** under real throttling.
- **Parent-before-child sync ordering** — the DAG shape is proven, the ordering behaviour is not.
- **What BC does with a `DELETE`** — hard or soft — remains formally unproven.

### Limitation vs. omission

Every gap above is classified, because "we couldn't" and "we didn't" are different admissions:

| Gap | Class |
|---|---|
| No live API call, no live write, no real throttling behaviour | **Genuine limitation** — no Business Central credential exists; unobtainable without one |
| Soft-PK inference unexercised | **Genuine limitation** — needs a real describe/sample response |
| Delete semantics unknown | **Genuine limitation** — undocumented by the vendor; guessing would be worse |
| Multi-page cursor following | **Omission** — a multi-page fixture could have been authored and was not |
| Parent-before-child ordering | **Omission** — a parent-child pair could have been selected for that cell and was not |
| Observed backoff events | **Omission** — the mock can emit a longer 429 storm than the one used |

## Residual gap (honest)

- **No credential for Business Central exists and none was ever used.** Zero live API calls have been made
  against `api.businesscentral.dynamics.com` at any point in this connector's history.
- **Four suite cells depend on unpublished MJ engine fixes** — see the boxed section above. Against a stock
  engine this connector scores 513/4.
- **Write is mock-proven, never live.** Request shape and identity read-back are proven; vendor acceptance
  is not.
- **Delete / tombstone semantics are formally UNPROVEN.**
- **Rate-limit / backoff under load** — not stress-tested.

_Numbers on this page come from run 25 of the hybrid-e2e suite (2026-08-05) and from direct SQL counts in
`MJ_BC_E2E`. Re-run `/test-connector business-central` after any change; if a credential ever arrives, run
it in live mode and the mock-only tier above lifts._
