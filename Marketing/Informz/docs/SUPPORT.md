# Informz — Supported & Proven

> **Evidence tier:** 🧪 Mock-only (proven vs mock server, never live)  ·  **Last verified:** 2026-09-10  ·  **Proof DB(s):** —

> 🧪 **Mock-proven, never live.** This connector was built through the build-connector pipeline for
> AIDP (Blue Cypress's AI Data Platform) at its credential-free gate: spec-conformance against the
> vendor's published API contract, plus a real end-to-end sync through MJAPI into a SQL Server
> database against a **mock Informz server**, outcome-asserted by rowcounts rather than by absence of
> error. **No authenticated call has been made to a Higher Logic tenant and no customer row has ever
> been read.** The only live traffic was unauthenticated service-level probing of
> `partner.informz.net` (see below). The gap is a credential gap, not a defect.

## What this connector supports

**70 objects** declared across **1010 fields** (source: `metadata/integration/.informz.integration.json`). 2 declare a write path; 68 are read-only (pull). 23 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| AccountingCode | ✓ | — (read-only) | — |
| CampaignStep | ✓ | — (read-only) | — |
| CampaignSummary | ✓ | — (read-only) | — |
| CampaignSummaryDemo | ✓ | — (read-only) | — |
| EmailBlockStatus | ✓ | — (read-only) | — |
| Event | ✓ | — (read-only) | ✓ |
| GetCampaignDetails | ✓ | — (read-only) | — |
| GetCampaigns | ✓ | — (read-only) | ✓ |
| GetCampaignSubscriber | ✓ | — (read-only) | ✓ |
| GetCampaignSubscriberHistory | ✓ | — (read-only) | — |
| GetSubscriberInterestChanges | ✓ | — (read-only) | ✓ |
| InterestTargetGroup | ✓ | — (read-only) | — |
| LandingPagesSummary | ✓ | — (read-only) | — |
| LandingPagesSummaryDemo | ✓ | — (read-only) | — |
| Mailing | ✓ | `C` | ✓ |
| MailingActivity | ✓ | — (read-only) | ✓ |
| MailingActivityBounces | ✓ | — (read-only) | — |
| MailingActivityChallenge | ✓ | — (read-only) | — |
| MailingActivityClicks | ✓ | — (read-only) | — |
| MailingActivityDemo | ✓ | — (read-only) | ✓ |
| MailingActivityDomains | ✓ | — (read-only) | — |
| MailingActivityFirstOpen | ✓ | — (read-only) | ✓ |
| MailingActivityFirstOpenByHour | ✓ | — (read-only) | — |
| MailingActivityForwardCount | ✓ | — (read-only) | — |
| MailingActivityOpens | ✓ | — (read-only) | ✓ |
| MailingActivityOpensByHour | ✓ | — (read-only) | — |
| MailingActivityOptout | ✓ | — (read-only) | — |
| MailingActivitySendAFriend | ✓ | — (read-only) | — |
| MailingActivitySubscriberActions | ✓ | — (read-only) | — |
| MailingActivitySubscriberArchive | ✓ | — (read-only) | ✓ |

_First 30 of 70 objects shown, alphabetically. The full catalog is the metadata file cited above._

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

- **248 records synced, 248 succeeded, 0 failed** through the real engine path (connector → MJAPI →
  entity maps → upsert) against the mock vendor server. Not a unit-test double: a live MJAPI against
  a real SQL Server database.
- **Full-catalog coverage: 68 of 68 syncable objects landed rows** (`zeroRowReal: 0`). The remaining
  2 of the 70 declared objects are keyless aggregate grids, legitimately skipped — not silent failures.
- **Idempotency proven**: a second identical sync performed zero work rather than duplicating rows.
- **Incremental** (`GTE` watermark conditions), **Merkle** change detection, **full-sync**,
  **maintenance** and **record-death** paths all pass.
- **Tenant-defined columns are captured as first-class columns**, not dumped into overflow — verified
  in the database: `Subscriber.Membership_Type` = 'Professional'/'Student', `Chapter_Region` =
  'Northeast', with the custom-overflow table **populated = 0**.
- Verification ladder **T0–T7 green** via the `mj-test-runner` harness; **floor-check PASS**, 0
  failures across all 66 bijection slots.

### Live (unauthenticated) service probing

These are the only real calls made to Higher Logic infrastructure, and they carry no credential:

- `…/aapi/InformzService.svc` → **HTTP 200**; `?wsdl` → **200**; `?xsd=xsd0` → **200**.
- The WSDL/XSD remain **contract-opaque** (one `PostInformzMessage(string)` operation, no rich type
  set), which is the premise the entire object model rests on — re-confirmed against the live service.

### Push (write / bidirectional)

- 2 of 70 objects declare a write path (`ActionRequest` documents). Writes were exercised **against
  the mock server only**.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is
  not claimed as "works".

## Residual gap (honest)

- **No live tenant.** Higher Logic validates credentials against a **registered IP address**, so a
  live rung additionally requires a support case to allowlist the connector's egress IP — not just a
  username/password/BrandID.
- **Push API v2 is NOT covered.** Higher Logic publishes a separate REST API at
  `datapushapi.higherlogic.com/v2` (13 documented objects — Addresses, ContactDetails, ContactInfo,
  Demographics, Education, EmailAddresses, Groups, JobHistory, List, Meeting, Orders, PhoneNumbers,
  Product). It is a different host, protocol and auth from the AAPI SOAP door implemented here, and is
  deliberately out of scope for this connector. **"70 of 70 AAPI objects" does not mean "all of Informz".**
- **Deletes** — the AAPI publishes no delete action, so `SupportsDelete` is false by vendor design.
- **Rate-limit / backoff under load** — not stress-tested against the live service.
- **Coverage against a real tenant: 0 of 70 objects** have rows proven from live Higher Logic data.

---

_Capability section derived from this connector's own metadata (`gen-baseline-support-docs.mjs`);
the evidence sections record the mock end-to-end run and the unauthenticated live probe described
above. Supersede this file the moment a credentialed live sync is run._
