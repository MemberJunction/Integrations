# Rhythm Software — Supported & Proven

<!-- baseline-stub: no live or mock sync has been run for this connector. Replace this whole file
     with real evidence when one is, and delete this marker — the overview pages key on it. -->

> **Evidence tier:** 🟡 Honest-NA (untested for a documented, non-defect reason)  ·  **Last verified:** 2026-07-05  ·  **Proof DB(s):** —

> 🟡 **Baseline — format-verified, no credential.** This connector was built through the
> build-connector pipeline for AIDP (Blue Cypress's AI Data Platform), whose default gate is the
> credential-free behavioural matrix: spec-conformance against the vendor's published API contract,
> a mock vendor server exercising pull/push/pagination/incremental shapes, and anti-vacuous
> assertions (a green must mean "observed to work", never "ran without error"). **No live system has
> been contacted and no rows have been persisted.** The reason is a credential gap, not a defect.

## What this connector supports

**377 objects** declared across **14515 fields** (source: `metadata/integration/.rhythm-software.integration.json`). 361 declare a write path; 16 are read-only (pull). 0 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| accreditation:Accreditation | ✓ | `CUD` | — |
| accreditation:AccreditationPhase | ✓ | `CUD` | — |
| accreditation:Activity | ✓ | `CUD` | — |
| accreditation:ActivityType | ✓ | `CUD` | — |
| accreditation:Application | ✓ | `CUD` | — |
| accreditation:ApplicationProcess | ✓ | `CUD` | — |
| accreditation:BillingRun | ✓ | `CUD` | — |
| accreditation:BillingRunAction | ✓ | `CUD` | — |
| accreditation:BillingTemplate | ✓ | `CUD` | — |
| accreditation:Evaluation | ✓ | `CUD` | — |
| accreditation:EvaluationProcess | ✓ | `CUD` | — |
| accreditation:EvaluationType | ✓ | `CUD` | — |
| accreditation:Notice | ✓ | `CUD` | — |
| accreditation:PastPhase | ✓ | `CUD` | — |
| accreditation:Phase | ✓ | `CUD` | — |
| accreditation:Program | ✓ | `CUD` | — |
| accreditation:RecurringBillingRun | ✓ | `CUD` | — |
| accreditation:Report | ✓ | `CUD` | — |
| accreditation:ReportingProcess | ✓ | `CUD` | — |
| accreditation:ReportProcess | ✓ | `CUD` | — |
| accreditation:ReportStatusReason | ✓ | `CUD` | — |
| accreditation:ReportType | ✓ | `CUD` | — |
| accreditation:Statistic | ✓ | — (read-only) | — |
| accreditation:StatusReason | ✓ | `CUD` | — |
| accreditation:TeamCandidate | ✓ | `CUD` | — |
| accreditation:TeamMember | ✓ | `CUD` | — |
| accreditation:TeamMemberRole | ✓ | `CUD` | — |
| accreditation:TeamNotice | ✓ | `CUD` | — |
| accreditation:Visit | ✓ | `CUD` | — |
| accreditation:VisitAssignment | ✓ | `CUD` | — |

_First 30 of 377 objects shown, alphabetically. The full catalog is the metadata file cited above._

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
- **Coverage:** 0 of 377 declared objects have proven rows.

---

_Capability section derived from this connector's own metadata (`gen-baseline-support-docs.mjs`).
There are no proof numbers to re-state: this doc records a build-time floor, not a measured result.
It is superseded the moment a live or mock sync is run and a real SUPPORT.md is written._
