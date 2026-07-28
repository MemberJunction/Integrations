# Stripe — Supported & Proven

> **Evidence tier:** 🟢 Live-vendor (real API + real account)  ·  **Last verified:** 2026-07-26  ·  **Proof DB(s):** MJ_ALLOWLIST
>
> ⚠️ **Marquee / high-stake connector** — its claims carry more weight, so the proof-vs-stake gap is flagged below.

## What this connector supports

**63 objects** declared across **1437 fields** (source: `metadata/integration/.stripe.integration.json`). 46 declare a write path; 17 are read-only (pull). 30 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| account | ✓ | `` | ✓ |
| apple_pay_domain | ✓ | `` | — |
| application_fee | ✓ | — (read-only) | ✓ |
| balance | ✓ | — (read-only) | — |
| balance_settings | ✓ | — (read-only) | — |
| balance_transaction | ✓ | — (read-only) | ✓ |
| capability | ✓ | `` | — |
| cash_balance | ✓ | `` | — |
| charge | ✓ | `` | ✓ |
| checkout.session | ✓ | `` | ✓ |
| country_spec | ✓ | — (read-only) | — |
| coupon | ✓ | `` | ✓ |
| credit_note | ✓ | `` | ✓ |
| credit_note_line_item | ✓ | — (read-only) | — |
| customer | ✓ | `` | ✓ |
| customer_balance_transaction | ✓ | `` | ✓ |
| customer_cash_balance_transaction | ✓ | `` | — |
| dispute | ✓ | `` | ✓ |
| event | ✓ | — (read-only) | ✓ |
| exchange_rate | ✓ | — (read-only) | — |
| external_account | ✓ | `` | — |
| fee_refund | ✓ | `` | — |
| invoice | ✓ | `` | ✓ |
| invoice_payment | ✓ | — (read-only) | ✓ |
| invoice_rendering_template | ✓ | `` | — |
| invoiceitem | ✓ | `` | ✓ |
| item | ✓ | — (read-only) | — |
| line_item | ✓ | `` | — |
| mandate | ✓ | — (read-only) | — |
| payment_attempt_record | ✓ | — (read-only) | — |

_First 30 of 63 objects shown, alphabetically. The full catalog is the metadata file cited above._

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

| Object | Label | Rows (DB-verified) | Which DB |
|---|---|---|---|
| event | Proven | 6,092 | MJ_ALLOWLIST |
| customer | Proven | 1,516 | MJ_ALLOWLIST |
| payment_intent | Proven | 858 | MJ_ALLOWLIST |
| balance_transaction | Proven | 801 | MJ_ALLOWLIST |
| tax_code | Proven | 673 | MJ_ALLOWLIST |
| charge | Proven | 618 | MJ_ALLOWLIST |
| payment_intent_amount_details_line_item | Proven | 258 | MJ_ALLOWLIST |
| price | Proven | 257 | MJ_ALLOWLIST |
| refund | Proven | 180 | MJ_ALLOWLIST |
| plan | Proven | 137 | MJ_ALLOWLIST |
| product | Proven | 137 | MJ_ALLOWLIST |
| country_spec | Proven | 121 | MJ_ALLOWLIST |
| coupon | Proven | 45 | MJ_ALLOWLIST |
| invoice | Proven | 45 | MJ_ALLOWLIST |
| line_item | Proven | 45 | MJ_ALLOWLIST |
| tax_rate | Proven | 45 | MJ_ALLOWLIST |
| payment_link | Proven | 40 | MJ_ALLOWLIST |
| invoice_payment | Proven | 18 | MJ_ALLOWLIST |
| checkout_session | Proven | 15 | MJ_ALLOWLIST |
| subscription | Proven | 15 | MJ_ALLOWLIST |
| setup_intent | Proven | 9 | MJ_ALLOWLIST |
| payout | Proven | 3 | MJ_ALLOWLIST |
| payment_method_domain | Proven | 2 | MJ_ALLOWLIST |
| payment_method_configuration | Proven | 1 | MJ_ALLOWLIST |

**Total proven rows: 11,931** across 24 of 63 declared objects.

**Declared but 0 rows landed (39 of 63, name-matched):** account, application_fee, balance, balance_settings, capability, cash_balance, credit_note, credit_note_line_item, customer_balance_transaction, customer_cash_balance_transaction, dispute, external_account, fee_refund, invoice_rendering_template, invoiceitem, item, mandate, payment_attempt_record, payment_method, payment_record, payment_source, person, promotion_code, quote, setup_attempt, shipping_rate, source, source_transaction, subscription_item, subscription_schedule, tax_id, token, topup, transfer, transfer_reversal, exchange_rate, review, apple_pay_domain, product_feature.

> These objects are declared/supported but landed no rows. **This split does NOT distinguish the reasons** — a zero here is one of: (a) **keyless by design** — the object has no derivable PK (soft keys), so the connector cannot sync it and the test suite *deliberately* skips it (common — often the majority); (b) a genuinely **empty test account**; or (c) a **silent empty-pull** (a real gap). Only the test suite's per-run *coverage* cell (`zeroRowReal` vs `zeroRowLegitEmpty` vs keyless-skipped) classifies which is which; absent that, treat these as **Not proven at the data level**, but do **not** read them as failures — most are keyless-by-design.

> ⚠️ **Coverage: 24 of 63 declared objects (PARTIAL).** These rows are real and DB-verified, but come from a fraction of the catalog — this is **NOT** a full-catalog "all objects" run. The other 39 objects are Not tested (some may be empty on this tenant, but that is unproven). A full-catalog re-sweep (now the test suite default) is required before this connector is proven in the full-coverage sense.

### Push (write / bidirectional)

- **Status: Mock-verified.** sk_test SANDBOX key (test, not live). Mock bidirectional 32/32; no live write executed.
- **Declared write surface (metadata):** 47 of 63 objects declare a substantiated write path (Create/Update/Delete APIPath+Method).
- **Mock evidence:** write proven **32/32** against the mock vendor server only — NOT a live tenant.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.
- **Coverage:** 24 of 63 declared objects have proven rows; the remainder are Not tested / Discovered (many may be empty in the test account).

---

_Capability section derived from this connector's own metadata on 2026-07-28. Proof numbers are DB ground
truth as of 2026-07-26 (`gen-support-docs.mjs`), and are re-stated verbatim — they change only when a
new live sync is run and the doc is regenerated._
