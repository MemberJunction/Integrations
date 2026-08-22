# @memberjunction/connector-bill-com

## 0.2.1

### Patch Changes

- 6ee916d: Relicense to the Business Source License 1.1.

  Metadata and documentation only: the `license` field moves to `BUSL-1.1` and the
  repo gains a LICENSE file. No runtime behaviour, API surface, or dependency
  changes. The bump exists so the new licence metadata reaches npm, since the
  registry shows the licence of the latest published version.

## 0.2.0

### Minor Changes

- 0567edc: Add the Bill.com (BILL) v3 Connect API connector — accounts receivable.

  Covers customers, invoices, and receivable-payments: create and cancel invoices (cancel is
  `POST /v3/invoices/{id}/archive`, not a delete or status change), and detect received payments
  via incremental sync on `updatedTime`.

  Vendor characteristics handled explicitly:

  - Session auth with a 35-minute sliding idle expiry and no refresh mechanism — the session is
    cached and reused, with proactive re-login and a single re-login-and-replay on 401. Logins are
    capped at 200/hour, so acquiring one per request is not viable.
  - Concurrency capped at 3 per developer key per organization (`BDC_1322`).
  - Opaque-cursor pagination terminating on the absence of `nextPage`, not on an empty page.
  - The invoice customer reference differs between read and write: BILL returns a flat `customerId`
    string but requires a nested `customer` object (`{"id":"0cu…"}`) on create. The catalog declares
    both, since sending the read name fails every create with HTTP 400.

  The catalog and the Action object model are both generated from BILL's published OpenAPI by
  `scripts/extract-catalog.mjs`, so they cannot drift apart.

  Refunds are deliberately absent: v3 has no AR refund endpoint, `/v3/orders` does not exist, and
  negative invoices are unsupported.

  Verified against BILL's real API using a sandbox account (evidence tier 🟢 Live-vendor). Session
  login, all three read paths, the `updatedTime` incremental filter, cursor advance, invoice create,
  invoice archive and its idempotency, and the customers-`PATCH`/invoices-`PUT` asymmetry are all
  confirmed live. Creating a receivable payment is declared but unproven — charging a customer
  requires an authorized customer with a bank account, which a fresh sandbox cannot provide. No write
  has been executed against a production BILL organization.
