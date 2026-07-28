# Nimble AMS — Supported & Proven

> **Evidence tier:** 🥇 Client-DB-live (real client tenant, production data)  ·  **Last verified:** 2026-07-26  ·  **Proof DB(s):** MJ_CT48, MJ_SS_E2E

## What this connector supports

**32 objects** declared across **164 fields** (source: `metadata/integration/.nimble-ams.integration.json`). 25 declare a write path; 7 are read-only (pull). 31 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| Account | ✓ | `CU` | ✓ |
| CartItem__c | ✓ | — (read-only) | ✓ |
| CartItemLine__c | ✓ | — (read-only) | ✓ |
| Contact | ✓ | — (read-only) | ✓ |
| EventAnswer__c | ✓ | `CUD` | ✓ |
| EventBadge__c | ✓ | `CUD` | ✓ |
| EventSessionGroup__c | ✓ | `CUD` | ✓ |
| FuseEndpoint | ✓ | — (read-only) | — |
| LmsProduct | ✓ | — (read-only) | ✓ |
| LmsPurchase | ✓ | `U` | ✓ |
| NU__Affiliation__c | ✓ | `CUD` | ✓ |
| NU__Badge__c | ✓ | `CUD` | ✓ |
| NU__Campaign__c | ✓ | `CUD` | ✓ |
| NU__Chapter__c | ✓ | `CUD` | ✓ |
| NU__Committee__c | ✓ | `CUD` | ✓ |
| NU__CommitteeMembership__c | ✓ | `CUD` | ✓ |
| NU__Credential__c | ✓ | `CUD` | ✓ |
| NU__Donation__c | ✓ | `CUD` | ✓ |
| NU__Evaluation__c | ✓ | `CUD` | ✓ |
| NU__Event__c | ✓ | `CUD` | ✓ |
| NU__Invoice__c | ✓ | — (read-only) | ✓ |
| NU__Membership__c | ✓ | `CUD` | ✓ |
| NU__MembershipType__c | ✓ | `CUD` | ✓ |
| NU__Order__c | ✓ | `CUD` | ✓ |
| NU__OrderItem__c | ✓ | `CUD` | ✓ |
| NU__OrderItemLine__c | ✓ | `CUD` | ✓ |
| NU__Payment__c | ✓ | — (read-only) | ✓ |
| NU__Product__c | ✓ | `CUD` | ✓ |
| NU__Schedule__c | ✓ | `CUD` | ✓ |
| NU__Session__c | ✓ | `CUD` | ✓ |

_First 30 of 32 objects shown, alphabetically. The full catalog is the metadata file cited above._

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

| Object | Label | Rows (DB-verified) | Which DB |
|---|---|---|---|
| NU__Order__c | Proven | 140,575 | MJ_CT48 |
| NU__Membership__c | Proven | 119,324 | MJ_CT48 |
| Contact | Proven | 116,157 | MJ_CT48 |
| Contact | Proven | 116,154 | MJ_SS_E2E |
| NU__PaymentLine__c | Proven | 78,451 | MJ_CT48 |
| NU__OrderItemLine__c | Proven `!` | 32,000 `!` | MJ_CT48 |
| NU__ExternalProfile__c | Proven | 8,139 | MJ_CT48 |
| NU__Schedule__c | Proven | 2,353 | MJ_CT48 |
| NU__Coupon__c | Proven | 1,870 | MJ_CT48 |
| NU__Membership__Share | Proven | 1,331 | MJ_CT48 |
| NU__Event__c | Proven | 732 | MJ_SS_E2E |
| NU__SpecialPrice__c | Proven | 374 | MJ_CT48 |
| NU__CommitteePosition__c | Proven | 269 | MJ_CT48 |
| NU__Affiliation__Feed | Proven | 234 | MJ_CT48 |
| NU__MembershipTypeProductLink__c | Proven | 127 | MJ_CT48 |
| NU__CouponRule__c | Proven | 122 | MJ_CT48 |
| NU__CartPayment__c | Proven | 69 | MJ_CT48 |
| NU__CouponDiscountLink__c | Proven | 66 | MJ_CT48 |
| NU__PriceClass__c | Proven | 55 | MJ_CT48 |
| NU__SendEmailResult__c | Proven | 23 | MJ_CT48 |
| NUINT__Integration_Settings__c | Proven | 17 | MJ_CT48 |
| NU__EntityCreditCardIssuer__c | Proven | 16 | MJ_CT48 |
| NU__EventBadge__Share | Proven | 16 | MJ_CT48 |
| NU__Registration2__Feed | Proven | 15 | MJ_CT48 |
| NU__InlineVFExpanderPages__c | Proven | 13 | MJ_CT48 |
| NU__SelfServiceRecoveryQuestion__c | Proven | 12 | MJ_CT48 |
| NU__EntityOrderItem__c | Proven | 9 | MJ_CT48 |
| NU__Entity__c | Proven | 5 | MJ_CT48 |
| NU__CreditCardIssuer__c | Proven | 4 | MJ_CT48 |
| NU__Coupon__Share | Proven | 2 | MJ_CT48 |
| NU__Engagement__Feed | Proven | 2 | MJ_CT48 |
| NU__EntityCrossover__c | Proven | 2 | MJ_CT48 |
| NU__EventSessionGroup__c | Proven | 2 | MJ_CT48 |
| Account | Proven | 1 | MJ_SS_E2E |
| NU__Donation__c | Proven | 1 | MJ_SS_E2E |
| NU__Membership__c | Proven | 1 | MJ_SS_E2E |
| NU__Order__c | Proven | 1 | MJ_SS_E2E |
| NU__CartPaymentLine__c | Proven | 1 | MJ_CT48 |
| NU__Namespace__c | Proven | 1 | MJ_CT48 |
| NUINT__Nimble_Integration_Public_Settings__c | Proven | 1 | MJ_CT48 |

**Total proven rows: 618,547** across 37 distinct objects (40 object×DB landings).

> ℹ️ **`!` = round-number worth a glance (1 object: NU__OrderItemLine__c=32000).** These counts are ≥200 and exactly divisible by 100. That is *sometimes* the signature of an un-paged pull cap — so it's flagged for a look — but a round total is **not** itself evidence of truncation, and where the run's `forward.completeness` check passed, the pull was complete and the round number is just the real count. Treat `!` as "confirm, don't assume broken."

### Push (write / bidirectional)

- **Status: Heavily experimental.** Full C/U/D is wired in the connector class, but no live write side-effect has been executed or verified.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.

---

_Capability section derived from this connector's own metadata on 2026-07-28. Proof numbers are DB ground
truth as of 2026-07-26 (`gen-support-docs.mjs`), and are re-stated verbatim — they change only when a
new live sync is run and the doc is regenerated._
