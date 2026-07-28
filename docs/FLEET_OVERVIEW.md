# Connector fleet — what is proven, and how

Every connector in this repo ships a `docs/SUPPORT.md` stating what it declares, what has actually
been executed against a real system, and what has not. This page is the roll-up of those files and is
generated from them, so the two can't disagree.

**30 connectors documented · 644,493 rows verified in a database · 0 verified live writes.**

That last number is not a typo, and it is the single most important line here. Read on.

## What the evidence tiers mean

A green connector is not one that compiled. It is one whose rows we can point at in a database. The
tiers below rank *the nature of the evidence*, not the quality of the code — a connector can be
excellent and sit in the bottom tier simply because nobody has had a credential for it yet.

| Tier | What it means | What it does **not** mean |
|---|---|---|
| 🥇 **Client-DB-live** | Ran against a real client tenant with production data; rows landed in a database we can query. | That every declared object was exercised — check the per-connector coverage note. |
| 🟢 **Live-vendor** | Ran against the vendor's real API using a real (often sandbox or developer) account. | That the data volume or shape matches a production tenant. |
| ⚙️ **Synthetic-local** | Ran against a disposable local instance. Proves the mechanics — connect, discover, page, parse. | Anything about the vendor's real API, which was never contacted. |
| 🧪 **Mock-only** | Ran against a mock server built from the vendor's own specification. Proves request and response shape. | That the real API behaves as its specification claims. |
| 🟡 **Honest-NA** | Not tested, for a stated non-defect reason — usually no credential was obtainable. | That the connector is broken. It means untested, and the reason is written down. |

Two rules that apply to every row on this page:

1. **"Declares a write path" is a capability declaration, not a proven behaviour.** A connector that
   advertises Create/Update/Delete has code for them. Whether that code has ever successfully changed a
   record in a live system is a separate question, answered in its `SUPPORT.md`.
2. **No connector in this repo has a verified live write.** Writes have been proven against mocks, and
   read paths have been proven against live systems, but no write side-effect has been executed and
   confirmed against a real tenant. Anything that reads as "bidirectional works" is overstating what
   was measured.

A ⚠️ in the *Objects with rows* column means the run covered only part of the declared catalog — real
rows, partial coverage. The per-connector doc says which objects.

*Objects with rows* can exceed *objects declared*. That isn't an error: some connectors discover their
catalog from the live system rather than reading it from the static metadata this repo ships, so a sync
can land rows for objects the static catalog doesn't list. Nimble AMS and PropFuel both look like this.

A live-vendor connector showing no rows was proven a different way — usually authentication and live
schema discovery against the real API, without a persisted sync. Its `SUPPORT.md` says exactly what ran.

## 🥇 Client-DB-live

| Connector | Objects declared | Objects with rows | Rows verified | Setup guide |
|---|---:|---:|---:|:--:|
| [NimbleAMS](../AMS/NimbleAMS/docs/SUPPORT.md) | 32 | 37 | 618,547 | [✓](../AMS/NimbleAMS/docs/credential-setup.html) |
| [PheedLoop](../Events/PheedLoop/docs/SUPPORT.md) | 28 | 2 | 250 | [✓](../Events/PheedLoop/docs/credential-setup.html) |
| [OpenWater](../Events/OpenWater/docs/SUPPORT.md) | 25 | 1 | 5 | [✓](../Events/OpenWater/docs/credential-setup.html) |

## 🟢 Live-vendor

| Connector | Objects declared | Objects with rows | Rows verified | Setup guide |
|---|---:|---:|---:|:--:|
| [Stripe](../Finance/Stripe/docs/SUPPORT.md) | 63 | 24 ⚠️ | 11,931 | [✓](../Finance/Stripe/docs/credential-setup.html) |
| [PropFuel](../Marketing/PropFuel/docs/SUPPORT.md) | 1 | 2 | 4,500 | [✓](../Marketing/PropFuel/docs/credential-setup.html) |
| [SharePoint](../Platform/SharePoint/docs/SUPPORT.md) | 25 | 4 | 2,781 | [✓](../Platform/SharePoint/docs/credential-setup.html) |
| [Zendesk](../Platform/Zendesk/docs/SUPPORT.md) | 99 | 31 ⚠️ | 2,624 | [✓](../Platform/Zendesk/docs/credential-setup.html) |
| [WildApricot](../AMS/WildApricot/docs/SUPPORT.md) | 25 | 1 ⚠️ | 1,275 | [✓](../AMS/WildApricot/docs/credential-setup.html) |
| [GrowthZone](../AMS/GrowthZone/docs/SUPPORT.md) | 38 | 4 | 912 | [✓](../AMS/GrowthZone/docs/credential-setup.html) |
| [Eventbrite](../Events/Eventbrite/docs/SUPPORT.md) | 33 | 11 ⚠️ | 677 | [✓](../Events/Eventbrite/docs/credential-setup.html) |
| [Totara](../LMS/Totara/docs/SUPPORT.md) | 28 | 4 ⚠️ | 589 | — |
| [Mailchimp](../Marketing/Mailchimp/docs/SUPPORT.md) | 87 | 8 ⚠️ | 349 | [✓](../Marketing/Mailchimp/docs/credential-setup.html) |
| [ORCID](../Platform/ORCID/docs/SUPPORT.md) | 12 | 2 | 45 | [✓](../Platform/ORCID/docs/credential-setup.html) |
| [HubSpot](../CRM/HubSpot/docs/SUPPORT.md) | 168 | 2 ⚠️ | 8 | [✓](../CRM/HubSpot/docs/credential-setup.html) |
| [Salesforce](../CRM/Salesforce/docs/SUPPORT.md) | 1,695 | — | — | [✓](../CRM/Salesforce/docs/credential-setup.html) |
| [ConstantContact](../Marketing/ConstantContact/docs/SUPPORT.md) | 65 | — | — | [✓](../Marketing/ConstantContact/docs/credential-setup.html) |

## ⚙️ Synthetic-local

| Connector | Objects declared | Objects with rows | Rows verified | Setup guide |
|---|---:|---:|---:|:--:|
| [MJtoMJ](../Platform/MJtoMJ/docs/SUPPORT.md) | 6 | — | — | [✓](../Platform/MJtoMJ/docs/credential-setup.html) |
| [MySQL](../Platform/MySQL/docs/SUPPORT.md) | discovered live | — | — | [✓](../Platform/MySQL/docs/credential-setup.html) |
| [Oracle](../Platform/Oracle/docs/SUPPORT.md) | discovered live | — | — | [✓](../Platform/Oracle/docs/credential-setup.html) |
| [PostgreSQL](../Platform/PostgreSQL/docs/SUPPORT.md) | discovered live | — | — | [✓](../Platform/PostgreSQL/docs/credential-setup.html) |
| [SQLServer](../Platform/SQLServer/docs/SUPPORT.md) | discovered live | — | — | [✓](../Platform/SQLServer/docs/credential-setup.html) |

## 🧪 Mock-only

| Connector | Objects declared | Objects with rows | Rows verified | Setup guide |
|---|---:|---:|---:|:--:|
| [MagnetMail](../Marketing/MagnetMail/docs/SUPPORT.md) | 47 | — | — | — |

## 🟡 Honest-NA — untested, reason stated

| Connector | Objects declared | Objects with rows | Rows verified | Setup guide |
|---|---:|---:|---:|:--:|
| [Impexium](../AMS/Impexium/docs/SUPPORT.md) | 46 | — | — | — |
| [Blackbaud](../CRM/Blackbaud/docs/SUPPORT.md) | 84 | — | — | — |
| [NetSuite](../Finance/NetSuite/docs/SUPPORT.md) | 205 | — | — | [✓](../Finance/NetSuite/docs/credential-setup.html) |
| [SageIntacct](../Finance/SageIntacct/docs/SUPPORT.md) | 163 | — | — | — |
| [HigherLogicThriveCommunity](../Platform/HigherLogicThriveCommunity/docs/SUPPORT.md) | 35 | — | — | — |
| [HigherLogicVanilla](../Platform/HigherLogicVanilla/docs/SUPPORT.md) | 65 | — | — | — |
| [MongoDB](../Platform/MongoDB/docs/SUPPORT.md) | discovered live | — | — | [✓](../Platform/MongoDB/docs/credential-setup.html) |
| [Snowflake](../Platform/Snowflake/docs/SUPPORT.md) | discovered live | — | — | [✓](../Platform/Snowflake/docs/credential-setup.html) |

## Reading a proof row

Each `SUPPORT.md` proof table names the database the rows were counted in (`MJ_CT48`,
`MJ_ALLOWLIST`, `MJ_SS_E2E` — the databases used for live sync runs). That column exists so a claim
can be re-checked rather than taken on trust: the number came from counting rows in that database after
a sync, not from a test asserting its own success.

## Credential setup guides

Connectors with a ✓ above ship a `docs/credential-setup.html` — a self-contained page you can send to
a client, walking them through obtaining the credential and telling them exactly which values to return.
Open it in a browser; it needs no server and no network.

---

_Generated from the per-connector `docs/SUPPORT.md` files. Regenerate after any new live sync so the
totals stay tied to the underlying evidence._
