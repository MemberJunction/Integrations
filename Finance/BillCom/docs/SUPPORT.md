# Bill.com connector — support & evidence

> **Evidence tier:** ✅ Live read + write (auth, all three read paths, and the O-UC6/O-UC7 write path exercised against a real BILL sandbox tenant) · **Last verified:** 2026-08-13 · **Proof:** unit suite, 29 assertions + live read probe + live write verification, sandbox gateway

Claims below are marked `verified` (exercised against a live tenant or in code) or `declared` (asserted from the vendor contract but not run).

## Scope

Accounts receivable only. Serves the AIDP use cases: invoice a customer (O-UC6), cancel an unpaid invoice (O-UC7), detect received payments (O-UC8).

| Object | Fields | Incremental | Write |
|---|---|---|---|
| `customers` (`0cu`) | 20 | `updatedTime` | Create, Update (`PATCH`) |
| `invoices` (`00e`) | 28 | `updatedTime` | Create, Update (`PUT`) |
| `receivable-payments` (`0rp`) | 16 | `updatedTime` | Create (charge a customer) |

The catalog is **extracted** from BILL's published OpenAPI by `scripts/extract-catalog.mjs`, not hand-authored. The same run emits `src/generated/objects.ts`, so the Action surface and the sync catalog cannot drift. Re-run it when BILL revises the API.

**Not modelled:** every AP object (`bills`, `/v3/payments`, vendors) and `credit-memos`. The AR/AP split is enforced by ID prefix — AP payments are `stp` — so an AR sync cannot pull payables.

### The invoice customer reference diverges between read and write

BILL names and shapes this field differently in each direction, so `invoices` declares **both**:

| Direction | Field | Shape |
|---|---|---|
| Read (`InvoiceResponseDto`) | `customerId` | flat string, `0cu…` — declared **read-only** |
| Write (`InvoiceCreateRequestDto`) | `customer` | nested `InvoiceCustomer` object, `{"id":"0cu…"}` — declared **required, `json`** |

Because fields are derived from the response DTO, a naive regeneration reintroduces `customerId` as writable and **every O-UC6 invoice create fails with HTTP 400**. The divergence is declared explicitly in `scripts/extract-catalog.mjs` under `writeShape`, and asserted by two unit tests so a regeneration cannot silently drop it.

Both halves were found only by live sandbox writes — sending `customerId` returns `400 "customer: The customer field is required"`, and sending `customer` as a bare ID string returns `400 "Cannot construct instance of ...InvoiceCustomer"`. Neither is reachable from a mock suite or a read-only probe. `verified` live.

## Auth

Session-based, unlike every other Finance connector. `POST /login` with username, password, organizationId and devKey returns an opaque `sessionId`, sent with `devKey` as headers.

- The login handshake is `verified` live: `POST /login` against the sandbox gateway returns 200 with an opaque `sessionId`, and that session authenticates subsequent reads.
- **Sessions expire after 35 minutes of inactivity**, sliding, with **no refresh mechanism** — re-login is the only recovery. `declared` from the vendor docs; the expiry itself was not waited out.
- **Logins are capped at 200/hour**, so the session is cached and reused, never acquired per request. The connector re-logins proactively at 25 minutes idle, and once more on a 401 before replaying the request. `verified` by unit test.
- Default gateway is **sandbox**. Production must be selected deliberately via the `environment` credential field.

## Rate limits

- **3 concurrent requests per developer key per organization** (`BDC_1322`) — declared as `MaxConcurrencyHint`. This is the binding constraint, far tighter than the hourly ceiling.
- 20,000 requests/hour (`BDC_1144`).

## Pagination

Opaque cursor: send `max` (1–100) and `page`, read `nextPage`. **Termination is the absence of `nextPage`, not an empty page** — an empty `results[]` carrying a cursor still means continue. `verified` by unit test.

`max` is always sent explicitly because the vendor docs contradict themselves on the default (concepts page says 100; endpoint references say 20).

## Known gaps

- **No refunds.** There is no AR refund endpoint in v3, `/v3/orders` does not exist, and negative invoices are unsupported (`InvoiceStatus` has no state one could occupy). The sanctioned reversing document is a credit memo, which adjusts the ledger without moving money. Descoped — see bc-aidp-next-golive#51.
- **No delete.** Invoices are archived (`POST /v3/invoices/{id}/archive`, idempotent, reversed by `/restore`), not deleted. Cancellation is the `archived` boolean and must not be modelled as a status transition.
- **No payment-received webhook.** BILL's AR events are `invoice.created/updated/archived/restored` only, and `invoice.updated` carries no `0rp` payment ID — so payment detection is poll-authoritative. A webhook can accelerate it but cannot replace it.
- **Write proof is sandbox-only.** Create, update and archive are `verified` against a BILL sandbox tenant. No write has been executed against a production BILL organization, and none should be until the consuming flow is ready — a production invoice is a real ledger entry that BILL can email to a real customer, and this connector can archive but never delete.
- **`receivable-payments` create is unproven.** Charging a customer requires `authorizedToCharge=true` plus a customer bank account, neither of which exists in a fresh sandbox. The path is `declared` from `ChargeCustomerRequestDto`; its three required fields (`customerId`, `fundingAccount`, `invoicePayments`) are all present in the catalog.

## Verification status

| Check | Status |
|---|---|
| `tsc --noEmit` | clean |
| Unit suite | 29/29 |
| `lint:invariants`, `lint:metadata`, `lint:writable-pk`, `lint:pagination`, `lint:migrations` | clean |
| Migration + changeset | clean — pushed to a local MJ database |
| Live read probe (sandbox gateway) | **pass** — see below |
| Live write verification (sandbox gateway) | **pass** — see below |

### Live read probe — 2026-08-13, sandbox gateway

Run through the credential broker, so no credential was visible to the agent that authored this connector.

**Verified:** session login returns 200 with a `sessionId`; `customers`, `invoices` and `receivable-payments` each return 200 with the `results` envelope the catalog expects; the `updatedTime:gte` incremental filter is accepted (200) on all three, which is what the sync watermark depends on.

**Also verified live** (deep read pass, same tenant):

| Claim | Evidence |
|---|---|
| Re-login triggers on the right condition | an invalid `sessionId` returns **401** (`BDC_1109`), not 403 — the branch the connector keys on |
| `max` bounds are 1–100 | `max=1`/`max=100` → 200; `max=0`/`max=101` → **400**. Server-enforced, which settles the contradiction between BILL's concepts page (100) and endpoint references (20) |
| By-ID URL templates are correct | `GET /v3/{object}/{id}` returns **404** (`BDC_1205`) on all three objects — BILL routed the path and rejected the record. Listing never exercises this path, so a wrong template would otherwise survive until the first production lookup |
| Sync query dialect is accepted | `sort=updatedTime:desc` and `filters=updatedTime:gte:"…"` both 200 on all three objects |

### Live write verification — 2026-08-13, sandbox gateway

Also run through the credential broker. The plan refuses to execute unless the gateway is `stage`, customer emails use the reserved `.invalid` TLD so no real party can be contacted, and invoices are created with `processingOptions.sendEmail = false`.

| Use case / behaviour | Evidence |
|---|---|
| **O-UC6** — invoice a customer | `POST /v3/invoices` → **201** with an ID, after `POST /v3/customers` → 201 |
| **O-UC7** — cancel an unpaid invoice | `POST /v3/invoices/{id}/archive` → **200**, and a read-back confirms `archived === true` |
| Archive is idempotent | a second archive of the same invoice → **200**, no error — as documented |
| Write-verb asymmetry | customer update via `PATCH` → **200**. Invoices use `PUT`; a global default would break one |
| Cursor genuinely advances | with two customers, `max=1` returns a `nextPage`; following it yields a **different** cursor and a row set **disjoint** from page one |
| Live field names match the catalog | every key BILL returned on read-back of a created customer *and* invoice is declared in the catalog — **no unknown fields**. Live responses carry fewer keys than declared because BILL omits unpopulated fields |

This run also found the `customer`/`customerId` divergence documented above, which would have broken O-UC6 on every call in production.
