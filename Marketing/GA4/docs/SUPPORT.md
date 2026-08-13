# Google Analytics 4 — Supported & Proven

<!-- baseline-stub: no live or mock sync has been run for this connector. Replace this whole file
     with real evidence when one is, and delete this marker — the overview pages key on it. -->

> **Evidence tier:** 🟡 Honest-NA (untested for a documented, non-defect reason)  ·  **Last verified:** 2026-08-07  ·  **Proof DB(s):** —

> 🟡 **Baseline — format-verified, no credential.** This connector was built through the
> build-connector pipeline for AIDP (Blue Cypress's AI Data Platform), whose default gate is the
> credential-free behavioural matrix: spec-conformance against the vendor's published API contract,
> a mock vendor server exercising pull/push/pagination/incremental shapes, and anti-vacuous
> assertions (a green must mean "observed to work", never "ran without error"). **No live system has
> been contacted and no rows have been persisted.** The reason is a credential gap, not a defect.

## What this connector supports

**3 objects** declared across **35 fields** (source: `metadata/integration/.ga4.integration.json`). 0 declare a write path; 3 are read-only (pull). 3 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| PagePerformance | ✓ | — (read-only) | ✓ |
| UtmContentPerformance | ✓ | — (read-only) | ✓ |
| UtmPerformance | ✓ | — (read-only) | ✓ |

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
- **Coverage:** 0 of 3 declared objects have proven rows.

---

_Capability section derived from this connector's own metadata (`gen-baseline-support-docs.mjs`).
There are no proof numbers to re-state: this doc records a build-time floor, not a measured result.
It is superseded the moment a live or mock sync is run and a real SUPPORT.md is written._
