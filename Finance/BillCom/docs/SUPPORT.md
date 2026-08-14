# Bill.com — Supported & Proven

> **Evidence tier:** 🟢 Live-vendor (real API + real sandbox account)  ·  **Last verified:** 2026-08-13  ·  **Proof DB(s):** MJ_CONN_GEN
>
> **Known issues:** Read and write are verified against BILL's real API, but only in the sandbox environment — no production write has been executed. `receivable-payments` create remains unproven for a documented reason (see Residual gap).

## What this connector supports

**3 objects** declared across **64 fields** (source: `metadata/integration/.billcom.integration.json`). 3 declare a write path; 0 are read-only (pull). 3 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| Customers (`0cu`) | ✓ | `CU` (update via `PATCH`) | `updatedTime` |
| Invoices (`00e`) | ✓ | `CU` (update via `PUT`) | `updatedTime` |
| Receivable Payments (`0rp`) | ✓ | `C` (charge a customer) | `updatedTime` |

Accounts receivable only. Serves the AIDP use cases: invoice a customer (O-UC6), cancel an unpaid invoice (O-UC7), detect received payments (O-UC8).

The catalog is **extracted** from BILL's published OpenAPI by `scripts/extract-catalog.mjs`, not hand-authored. The same run emits `src/generated/objects.ts`, so the Action surface and the sync catalog cannot drift. Re-run it when BILL revises the API.

**Not modelled:** every AP object (`bills`, `/v3/payments`, vendors) and `credit-memos`. The AR/AP split is enforced by ID prefix — AP payments are `stp` — so an AR sync cannot pull payables.

**Total proven rows: 3** across **2 of 3 declared objects.**

Row counts are deliberately small: the proof tenant is a purpose-made BILL sandbox, and the rows are the ones this verification created (2 customers, 1 invoice). `receivable-payments` returned 0 rows — the object lists and filters correctly, but a sandbox has no received payments.

## Auth

Session-based, unlike every other Finance connector. `POST /login` with username, password, organizationId and devKey returns an opaque `sessionId`, sent with `devKey` as headers.

- The login handshake is `verified` live: 200 with an opaque `sessionId` that authenticates subsequent calls.
- An invalid `sessionId` returns **401** (`BDC_1109`), not 403 — `verified` live. This is the exact condition the connector's re-login branch keys on, so the branch fires when it should.
- **Sessions expire after 35 minutes of inactivity**, sliding, with **no refresh mechanism** — re-login is the only recovery. `declared` from the vendor docs; the expiry was not waited out.
- **Logins are capped at 200/hour**, so the session is cached and reused, never acquired per request. The connector re-logins proactively at 25 minutes idle, and once more on a 401 before replaying. `verified` by unit test.
- Default gateway is **sandbox**. Production must be selected deliberately via the `environment` credential field.

## Rate limits

- **3 concurrent requests per developer key per organization** (`BDC_1322`) — declared as `MaxConcurrencyHint`. This is the binding constraint, far tighter than the hourly ceiling.
- 20,000 requests/hour (`BDC_1144`).

## Pagination

Opaque cursor: send `max` and `page`, read `nextPage`. **Termination is the absence of `nextPage`, not an empty page** — an empty `results[]` carrying a cursor still means continue. `verified` by unit test.

`max` bounds are **server-enforced at 1–100**: `max=1` and `max=100` return 200, while `max=0` and `max=101` both return 400. `verified` live, and it settles a contradiction in BILL's own docs (concepts page says the default is 100; endpoint references say 20). The connector always sends `max` explicitly rather than trusting either.

Cursor advance is `verified` live: with two customers present, `max=1` returns a real `nextPage`; following it yields a **different** cursor and a row set **disjoint** from page one.

## The invoice customer reference diverges between read and write

BILL names and shapes this field differently in each direction, so `invoices` declares **both**:

| Direction | Field | Shape |
|---|---|---|
| Read (`InvoiceResponseDto`) | `customerId` | flat string, `0cu…` — declared **read-only** |
| Write (`InvoiceCreateRequestDto`) | `customer` | nested `InvoiceCustomer` object, `{"id":"0cu…"}` — declared **required**, type `json` |

Because fields are derived from the response DTO, a naive regeneration reintroduces `customerId` as writable and **every O-UC6 invoice create fails with HTTP 400**. The divergence is declared explicitly in `scripts/extract-catalog.mjs` under `writeShape`, and asserted by two unit tests so a regeneration cannot silently drop it.

Both halves were found only by live sandbox writes — sending `customerId` returns `400 "customer: The customer field is required"`, and sending `customer` as a bare ID string returns `400 "Cannot construct instance of ...InvoiceCustomer"`. Neither is reachable from a mock suite or a read-only probe. `verified` live.

## Push (write / bidirectional)

- **Status: Verified in sandbox.** Create, update and archive are exercised against BILL's real API; no production write has been executed.
- **Declared write surface (metadata):** 3 of 3 objects declare a substantiated write path (Create/Update APIPath+Method).
- **O-UC6 — invoice a customer:** `POST /v3/invoices` → **201** with an ID, after `POST /v3/customers` → 201. `verified` live.
- **O-UC7 — cancel an unpaid invoice:** `POST /v3/invoices/{id}/archive` → **200**, and a read-back confirms `archived === true`. A second archive of the same invoice also returns 200, confirming the documented idempotency. `verified` live.
- **Write-verb asymmetry:** customer update via `PATCH` → 200. Invoices update via `PUT`. A global default would break one of them. `verified` live.
- **Field reconciliation:** every key BILL returned on read-back of a created customer *and* a created invoice is declared in the catalog — no unknown fields. Live responses carry fewer keys than declared because BILL omits unpopulated ones.

The write verification runs through a credential broker, refuses to execute unless the gateway is `stage`, uses customer emails on the reserved `.invalid` TLD so no real party can be contacted, and sets `processingOptions.sendEmail = false`.

## Known gaps

- **No refunds.** There is no AR refund endpoint in v3, `/v3/orders` does not exist, and negative invoices are unsupported (`InvoiceStatus` has no state one could occupy). The sanctioned reversing document is a credit memo, which adjusts the ledger without moving money. Descoped — see bc-aidp-next-golive#51.
- **No delete.** Invoices are archived (`POST /v3/invoices/{id}/archive`, idempotent, reversed by `/restore`), not deleted. Cancellation is the `archived` boolean and must not be modelled as a status transition.
- **No payment-received webhook.** BILL's AR events are `invoice.created/updated/archived/restored` only, and `invoice.updated` carries no `0rp` payment ID — so payment detection is poll-authoritative. A webhook can accelerate it but cannot replace it.

## Residual gap (honest)

- **`receivable-payments` create is unproven.** Charging a customer requires `authorizedToCharge=true` plus a customer bank account, neither of which exists in a fresh sandbox. The path is `declared` from `ChargeCustomerRequestDto`; its three required fields (`customerId`, `fundingAccount`, `invoicePayments`) are all present in the catalog, and its field names were checked against the request DTO for the same read/write divergence found on invoices — it has none.
- **No production write.** None should be attempted until the consuming flow is ready: a production invoice is a real ledger entry BILL can email to a real customer, and this connector can archive but never delete.
- **Session expiry not observed.** The 35-minute idle expiry and the proactive 25-minute re-login are covered by unit tests against a stubbed clock, not by a live idle wait.

## Verification status

| Check | Status |
|---|---|
| `tsc --noEmit` | clean |
| Unit suite | 29/29 |
| Repo lint suite (invariants, metadata, writable-pk, pagination, migrations, field lengths, catalog completeness) | clean |
| Migration + changeset | clean — pushed to MJ_CONN_GEN, both dialects generated |
| Live read probe (sandbox gateway) | **pass** |
| Live write verification (sandbox gateway) | **pass** |
