---
"@memberjunction/connector-bill-com": minor
---

Add the Bill.com (BILL) v3 Connect API connector — accounts receivable.

Covers customers, invoices, and receivable-payments: create and cancel invoices (cancel is
`POST /v3/invoices/{id}/archive`, not a delete or status change), and detect received payments
via incremental sync on `updatedTime`.

Vendor characteristics handled explicitly:
- Session auth with a 35-minute sliding idle expiry and no refresh mechanism — the session is
  cached and reused, with proactive re-login and a single re-login-and-replay on 401. Logins are
  capped at 200/hour, so acquiring one per request is not viable.
- Concurrency capped at 3 per developer key per organization (`BDC_1322`).
- Opaque-cursor pagination terminating on the absence of `nextPage`, not on an empty page.

The catalog and the Action object model are both generated from BILL's published OpenAPI by
`scripts/extract-catalog.mjs`, so they cannot drift apart.

Refunds are deliberately absent: v3 has no AR refund endpoint, `/v3/orders` does not exist, and
negative invoices are unsupported. Evidence tier is mock-only — no write has run against a live
BILL tenant.
