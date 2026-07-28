# Mailchimp — Supported & Proven

> **Evidence tier:** 🟢 Live-vendor (real API + real account)  ·  **Last verified:** 2026-07-26  ·  **Proof DB(s):** MJ_CT48

## What this connector supports

**87 objects** declared across **916 fields** (source: `metadata/integration/.mailchimp.integration.json`). 42 declare a write path; 45 are read-only (pull). 9 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| account-exports | ✓ | `` | — |
| activity-feed.chimp-chatter | ✓ | — (read-only) | — |
| audiences | ✓ | — (read-only) | — |
| audiences.contacts | ✓ | `` | ✓ |
| authorized-apps | ✓ | — (read-only) | — |
| automations | ✓ | `` | ✓ |
| automations.emails | ✓ | `` | — |
| automations.emails.queue | ✓ | `` | — |
| automations.removed-subscribers | ✓ | `` | — |
| batch-webhooks | ✓ | `` | — |
| batches | ✓ | `` | — |
| campaign-folders | ✓ | `` | — |
| campaigns | ✓ | `` | ✓ |
| campaigns.content | ✓ | `` | — |
| campaigns.feedback | ✓ | `` | — |
| campaigns.send-checklist | ✓ | — (read-only) | — |
| connected-sites | ✓ | `` | — |
| conversations | ✓ | — (read-only) | — |
| conversations.messages | ✓ | — (read-only) | — |
| ecommerce.orders | ✓ | — (read-only) | — |
| ecommerce.stores | ✓ | `` | — |
| ecommerce.stores.carts | ✓ | `` | — |
| ecommerce.stores.carts.lines | ✓ | `` | — |
| ecommerce.stores.customers | ✓ | `` | — |
| ecommerce.stores.orders | ✓ | `` | — |
| ecommerce.stores.orders.lines | ✓ | `` | — |
| ecommerce.stores.products | ✓ | `` | — |
| ecommerce.stores.products.images | ✓ | `` | — |
| ecommerce.stores.products.variants | ✓ | `` | — |
| ecommerce.stores.promo-rules | ✓ | `` | — |

_First 30 of 87 objects shown, alphabetically. The full catalog is the metadata file cited above._

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

| Object | Label | Rows (DB-verified) | Which DB |
|---|---|---|---|
| lists__list_id__members | Proven `!` | 200 `!` | MJ_CT48 |
| templates | Proven | 122 | MJ_CT48 |
| lists__list_id__segments | Proven | 10 | MJ_CT48 |
| lists__list_id__merge_fields | Proven | 8 | MJ_CT48 |
| campaigns | Proven | 5 | MJ_CT48 |
| lists__list_id__interest_categories | Proven | 2 | MJ_CT48 |
| account | Proven | 1 | MJ_CT48 |
| lists | Proven | 1 | MJ_CT48 |

**Total proven rows: 349** across 8 of 76 declared objects.

> ℹ️ **`!` = round-number worth a glance (1 object: lists__list_id__members=200).** These counts are ≥200 and exactly divisible by 100. That is *sometimes* the signature of an un-paged pull cap — so it's flagged for a look — but a round total is **not** itself evidence of truncation, and where the run's `forward.completeness` check passed, the pull was complete and the round number is just the real count. Treat `!` as "confirm, don't assume broken."

**Declared but 0 rows landed (68 of 76, name-matched):** account-exports, activity-feed/chimp-chatter, audiences, authorized-apps, batch-webhooks, batches, campaign-folders, ecommerce/stores, file-manager/files, file-manager/folders, landing-pages, reporting/landing-pages, reporting/surveys, reports, sms-campaigns, template-folders, verified-domains, audiences/{audience_id}/contacts, campaigns/{campaign_id}/content, campaigns/{campaign_id}/feedback, campaigns/{campaign_id}/send-checklist, ecommerce/stores/{store_id}/carts, ecommerce/stores/{store_id}/customers, ecommerce/stores/{store_id}/orders, ecommerce/stores/{store_id}/products, ecommerce/stores/{store_id}/promo-rules, file-manager/folders/{folder_id}/files, landing-pages/{page_id}/content, lists/{list_id}/abuse-reports, lists/{list_id}/activity, lists/{list_id}/clients, lists/{list_id}/growth-history, lists/{list_id}/locations, lists/{list_id}/signup-forms, lists/{list_id}/surveys, lists/{list_id}/tag-search, lists/{list_id}/webhooks, reporting/surveys/{survey_id}/questions, reporting/surveys/{survey_id}/responses, reports/{campaign_id}/abuse-reports, reports/{campaign_id}/advice, reports/{campaign_id}/click-details, reports/{campaign_id}/domain-performance, reports/{campaign_id}/ecommerce-product-activity, reports/{campaign_id}/eepurl, reports/{campaign_id}/email-activity, reports/{campaign_id}/locations, reports/{campaign_id}/open-details, reports/{campaign_id}/sent-to, reports/{campaign_id}/sub-reports, reports/{campaign_id}/unsubscribed, sms-campaigns/{sms_campaign_id}/content, templates/{template_id}/default-content, ecommerce/stores/{store_id}/carts/{cart_id}/lines, ecommerce/stores/{store_id}/orders/{order_id}/lines, ecommerce/stores/{store_id}/products/{product_id}/images, ecommerce/stores/{store_id}/products/{product_id}/variants, ecommerce/stores/{store_id}/promo-rules/{promo_rule_id}/promo-codes, lists/{list_id}/interest-categories/{interest_category_id}/interests, lists/{list_id}/members/{subscriber_hash}/activity, lists/{list_id}/members/{subscriber_hash}/activity-feed, lists/{list_id}/members/{subscriber_hash}/events, lists/{list_id}/members/{subscriber_hash}/goals, lists/{list_id}/members/{subscriber_hash}/notes, lists/{list_id}/members/{subscriber_hash}/tags, lists/{list_id}/segments/{segment_id}/members, reporting/surveys/{survey_id}/questions/{question_id}/answers, reports/{campaign_id}/click-details/{link_id}/members.

> These objects are declared/supported but landed no rows. **This split does NOT distinguish the reasons** — a zero here is one of: (a) **keyless by design** — the object has no derivable PK (soft keys), so the connector cannot sync it and the test suite *deliberately* skips it (common — often the majority); (b) a genuinely **empty test account**; or (c) a **silent empty-pull** (a real gap). Only the test suite's per-run *coverage* cell (`zeroRowReal` vs `zeroRowLegitEmpty` vs keyless-skipped) classifies which is which; absent that, treat these as **Not proven at the data level**, but do **not** read them as failures — most are keyless-by-design.

> ⚠️ **Coverage: 8 of 76 declared objects (PARTIAL).** These rows are real and DB-verified, but come from a fraction of the catalog — this is **NOT** a full-catalog "all objects" run. The other 68 objects are Not tested (some may be empty on this tenant, but that is unproven). A full-catalog re-sweep (now the test suite default) is required before this connector is proven in the full-coverage sense.

### Push (write / bidirectional)

- **Status: Heavily experimental.** Metadata declares write on many objects; none verified live or mock.
- **Declared write surface (metadata):** 40 of 76 objects declare a substantiated write path (Create/Update/Delete APIPath+Method).
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.
- **Coverage:** 8 of 76 declared objects have proven rows; the remainder are Not tested / Discovered (many may be empty in the test account).

---

_Capability section derived from this connector's own metadata on 2026-07-28. Proof numbers are DB ground
truth as of 2026-07-26 (`gen-support-docs.mjs`), and are re-stated verbatim — they change only when a
new live sync is run and the doc is regenerated._
