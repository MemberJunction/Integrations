# Cvent — Supported & Proven

<!-- baseline-stub: no live or mock sync has been run for this connector. Replace this whole file
     with real evidence when one is, and delete this marker — the overview pages key on it. -->

> **Evidence tier:** 🟡 Honest-NA (untested for a documented, non-defect reason)  ·  **Last verified:** 2026-07-28  ·  **Proof DB(s):** —

> 🟡 **Baseline — format-verified, no credential.** This connector was built through the
> build-connector pipeline for AIDP (Blue Cypress's AI Data Platform), whose default gate is the
> credential-free behavioural matrix: spec-conformance against the vendor's published API contract,
> a mock vendor server exercising pull/push/pagination/incremental shapes, and anti-vacuous
> assertions (a green must mean "observed to work", never "ran without error"). **No live system has
> been contacted and no rows have been persisted.** The reason is a credential gap, not a defect.

## What this connector supports

**179 objects** declared across **2193 fields** (source: `metadata/integration/.cvent.integration.json`). 51 declare a write path; 128 are read-only (pull). 67 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| account-budget-item-list-response | ✓ | — (read-only) | ✓ |
| activity | ✓ | `C` | — |
| AgendaItem1 | ✓ | — (read-only) | — |
| AirActualDetail | ✓ | — (read-only) | — |
| AirReservationDetail | ✓ | — (read-only) | — |
| AlternateTravelDetail | ✓ | — (read-only) | ✓ |
| Anniversary | ✓ | — (read-only) | — |
| appointment-attendee | ✓ | — (read-only) | ✓ |
| appointment-availability | ✓ | — (read-only) | ✓ |
| appointment-event | ✓ | — (read-only) | ✓ |
| appointment-type | ✓ | — (read-only) | — |
| appointment-with-questions | ✓ | — (read-only) | ✓ |
| attendee | ✓ | `CU` | ✓ |
| attendee-appointment-meeting-interest | ✓ | — (read-only) | ✓ |
| attendee-audience-segment-association | ✓ | — (read-only) | — |
| attendee-credit | ✓ | — (read-only) | ✓ |
| attendee-insights | ✓ | — (read-only) | ✓ |
| attendee-insights-stats | ✓ | — (read-only) | — |
| attendee-signature-response | ✓ | — (read-only) | ✓ |
| audience-segment-response | ✓ | `CUD` | ✓ |
| available-night | ✓ | — (read-only) | — |
| available-time | ✓ | — (read-only) | — |
| badge | ✓ | `CU` | — |
| booth-staff-response | ✓ | `CD` | — |
| bounce-details | ✓ | — (read-only) | — |
| brand | ✓ | — (read-only) | ✓ |
| budget-allocations-paginated-response | ✓ | — (read-only) | — |
| budget-item-list-response | ✓ | `CU` | — |
| budget-vendor-response | ✓ | — (read-only) | ✓ |
| bulk-job | ✓ | `C` | — |

_First 30 of 179 objects shown, alphabetically. The full catalog is the metadata file cited above._

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

- **No rows landed.** No live or mock sync has been run for this connector; there is no proof DB.
- Build-time verification only: the declared request shapes conform to the vendor's API contract.

### Push (write / bidirectional)

- **Status: Not verified.** No write has been executed against any system, live or mock.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- **Everything beyond format verification** — no credential has been used for this connector, so no
  row count, field-shape sample, or write side-effect has been observed against a real tenant.
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.
- **Coverage:** 0 of 179 declared objects have proven rows.

---

_Capability section derived from this connector's own metadata (`gen-baseline-support-docs.mjs`).
There are no proof numbers to re-state: this doc records a build-time floor, not a measured result.
It is superseded the moment a live or mock sync is run and a real SUPPORT.md is written._
