# Microsoft Dynamics 365 Business Central — Supported & Proven

> **Evidence tier:** 🟢 Live-vendor (real API + real tenant, read + write)  ·  **Last verified:** 2026-08-17  ·  **Proof DB(s):** MJ_BC_E2E
>
> Tenant: Blue Cypress `Test` environment, company *Association Success Corp*. Prior tier: 🧪 mock-only,
> superseded — see "What the mock got wrong" below.

## Read this first: the previous version of this page was wrong

Until 2026-08-17 this document claimed **"83 of 83 declared objects proven"** on the strength of a
credential-free run against a mock vendor. The first live credential this connector has ever had was
obtained on 2026-08-17, and the first full-catalog read sweep against real Business Central found **13 of
83 objects returning HTTP errors**. Eleven were a genuine catalog defect; two are environmental.

The old claim was not a lie, but it was **unfalsifiable**. The mock replays fixtures at whatever path the
catalog declares, so a wrong path is self-consistent and green. The catalog and the mock were generated
from the same Microsoft corpus, which documents *both* a flat and a nested form for these objects — the
generator picked the flat one, and the mock dutifully answered it. No credential-free run could have
caught this, which is exactly why "proven against a mock" and "proven" are different words.

## What the mock got wrong

Eleven objects addressed their collection directly under the company:

```
/companies({id})/salesInvoiceLines          →  400 Application_DialogException
                                               "You must specify a parent ID"
/companies({id})/salesInvoices({id})/salesInvoiceLines  →  200, rows
```

Affected: `salesInvoiceLines`, `salesOrderLines`, `salesQuoteLines`, `salesCreditMemoLines`,
`purchaseInvoiceLines`, `purchaseOrderLines`, `purchaseCreditMemoLines`, `customerPayments`,
`vendorPayments`, `timeRegistrationEntries`, `contactsInformation`. All eleven failed on **read and
write** alike, since `CreateAPIPath` carried the same flat path. `journalLines` was correctly nested and
is the shape the fix copies.

Fixed in `V202608172000__business-central__NestedLinePaths`. After the fix the same sweep returns **2
errors instead of 13**, and neither remaining one is a connector defect.

## Live read coverage — the whole catalog, one company

Swept every one of the 83 declared objects against the live tenant, after the path fix:

| Outcome | Count |
|---|---|
| reachable, returned rows | **42** |
| reachable, genuinely empty in this company | 37 |
| parent collection empty, child not exercisable | 2 |
| errored | **2** |

The 37 zero-row objects are **not** failures and **not** proof — Association Success Corp simply has no
`items`, `salesOrders`, `employees`, `projects` and so on. They resolved (HTTP 200, correct shape) but
landed nothing, so they are recorded as *reachable, unproven for data*. A company with a fuller data set
would move most of them into the proven column, and that run has not been done.

### The two remaining errors, classified

| Object | Result | Class |
|---|---|---|
| `purchaseCreditMemos` | `400` — *"You must run the data upgrade for this API page… schedule upgrade for Purchase Credit Memos"* | **Tenant action**, not a connector defect. Also blocks its child `purchaseCreditMemoLines`. |
| `picture` | `404` | **Not exercisable here** — the company has no `items`, and `picture` is the one object whose path uses named placeholders (`{companyId}`, `{itemId}`) rather than the repeated `{id}` the URL builder documents. Untested in both respects. |

## Write — live-verified, on the journal path only

Real records were created, updated, deleted and **posted** in the live Test environment.

| Behaviour | Evidence |
|---|---|
| `journals` create | `POST {code}` alone → `201`; only `code` is required, as documented |
| `journalLines` batch create | 4 lines in one `$batch` envelope → all `201`, rows read back |
| `$batch` operation ceiling | 101 operations → `HTTP 500`, *"maximum number of '100' query operations… allowed"* — the documented limit is real and enforced |
| **Atomic rollback** | reproduced **3×**: a poisoned envelope returns `201` **with real GUIDs** for the operations BC then reverts; row count unchanged. The connector must not trust per-operation status, and does not. |
| `$batch` response shape | BC returns **one** sub-response when operation 0 fails, but **all** of them when a later operation fails — both branches of the connector's id-matching logic are now characterised live |
| `lineNumber` collision | duplicate `lineNumber` fails the **entire** envelope (`Internal_EntityWithSameKeyExists`); allocate-above-max succeeds |
| `accountId` typing | GUID → `201`; `accountNumber` → `201`; an account *number* in `accountId` → `400` |
| `PATCH` + watermark | `lastModifiedDateTime` advanced `2024-11-14` → `2026-08-17`, and the changed record reappeared under `$filter=… gt <ts>` — incremental narrowing proven on a writable entity, not just a read-only one |
| `DELETE` journal lines | `204`, rows removed |
| **Posting to the ledger** | `Microsoft.NAV.Post` → `204`; entries `6238`/`6239` landed in `generalLedgerEntries`, balanced `10.00` debit / `10.00` credit. Sign convention confirmed: **positive amount → debit, negative → credit**. |

> ⚠️ **`Microsoft.NAV.post` is NOT case-sensitive.** The developer guide states that `.Post` with a
> capital P returns 404 and is therefore a safe no-op. It is not — it returns `204` and **posts**. The
> ledger entries above were created by exactly that call, made in the belief it would fail. Treat any
> casing of the post action as live and irreversible.

## Custom objects — the tenant's own surface

The `odatav4` surface is live-verified for the first time. The tenant publishes **115 web-service pages**,
read through the connector's second URL grammar (company key **single-quoted by name**, not the GUID):

```
/ODataV4/Company('Association%20Success%20Corp')/Chart_of_Accounts   200, 40 fields
/ODataV4/Company('…')/G_LEntries                                     200, 30 fields
/ODataV4/Company('…')/Cust_LedgerEntries                             200, 26 fields
```

Genuinely tenant-specific pages exist here — `bdcBankAccountPostingGroup`, `bdcCashReceiptJournal`,
`bdcGeneralLedgerSetup`, `BankAccountLedgerEntries_bc` — none of which appear in the 83-object standard
catalog. Additive discovery of them is **not yet asserted end-to-end**; what is proven is that the surface
is reachable and the URL grammar is correct.

## Engine-side behavioural matrix — re-run green on the corrected catalog

> **Suite:** connector-e2e (real MJAPI + real SQL Server + mock HTTP peer) · **Run:** 2026-08-17,
> `runId=live_1787021820128` · **Result:** **55 passed, 0 failed, 2 skipped, `ok: true`**

Re-run after the path corrections, against a database rebuilt from scratch (schema dropped, catalog
re-applied, 83 entities and 83 views generated by CodeGen):

```
coverage.all-objects:  deployedObjects=83  coveredWithRows=83  zeroRowReal=0
```

Every stage green — `forward`, `delta` 8/8, `bidirectional` 7/7, `customColumns` 4/4, `merkle` 4/4,
`scheduledJob` 4/4, `discoverOverlay` 3/3, `dag` 3/3, plus `watermark`, `pagination`, `concurrency`,
`faultScope` and `idempotent`. The two skips are declared: `backward` (mock mode has no live vendor
store) and one `discoverColumns` cell.

**Read this for exactly what it is.** MJAPI, SQL Server, CodeGen and the sync engine are real; the HTTP
peer is a fixture replay. It proves the *engine-side* behaviour the live credential could not reach —
ApplyAll deployability, record-map 1:1, DAG layering, idempotency, Merkle partition skip, custom-column
capture and promote, dead-lettering. It proves **nothing** about real Business Central; that half rests
entirely on the live evidence above, and the two halves are not interchangeable. The earlier green on
this same suite is exactly what hid the flat-path defect for months.

Getting here required three fixes to the harness environment, none of them connector changes: a
`mj.config.cjs` in `RSU_WORK_DIR` (CodeGen otherwise resolves its output path against `/`), nested
fixture routes for `contactsInformation`, and purging `mj_e2e_*` probe artifacts left inconsistent
across `IntegrationObjectField` / `EntityField` / physical columns by a prior run's teardown.

## What is still NOT proven

- **Write beyond journals.** Of the 54 objects declaring a write path, only `journals` and `journalLines`
  have been written live. The other 52 are mock-shape-proven only.
- **37 objects returned no rows** because this company has no such data. Reachable ≠ proven.
- **Rate limiting / backoff** under real throttling — never triggered.
- **Vendor and contact `contactsInformation`** — unreachable by design of the fix; see the changeset.
- **`picture` and `attachments` named-placeholder paths** — untested, deliberately unchanged.

## Limitation vs. omission

| Gap | Class |
|---|---|
| Engine matrix is mock-peer only | **Genuine limitation** — a live-peer matrix needs the harness pointed at real BC, which no plan currently does |
| 52 writable objects unwritten live | **Omission** — a company with a smaller blast radius than the real-books copy was not available |
| 37 objects with no data | **Limitation of this company**, not of the connector — a fuller company closes it |
| `purchaseCreditMemos` | **Tenant limitation** — needs the API Data Upgrade run |
| Vendor/contact contact-information | **Genuine modelling limitation** — one `APIPath`, three parents |
| Rate-limit behaviour | **Omission** — never stressed |

_Evidence on this page comes from live calls against `api.businesscentral.dynamics.com` on 2026-08-17,
Test environment, company Association Success Corp. Re-run the sweep after any catalog change; the
`business-central-readonly` broker plan holds the credential and never exposes it._
