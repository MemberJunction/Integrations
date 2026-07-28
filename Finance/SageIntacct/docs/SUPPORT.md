# Sage Intacct — Supported & Proven

> **Evidence tier:** 🟡 Honest-NA (untested for a documented, non-defect reason)  ·  **Last verified:** 2026-07-26  ·  **Proof DB(s):** —

> 🟡 **Honest-NA:** Credential-helper authored; no live test run yet.

## What this connector supports

**163 objects** declared across **3825 fields** (source: `metadata/integration/.sage-intacct.integration.json`). 142 declare a write path; 21 are read-only (pull). 146 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| ACCRUAL | ✓ | — (read-only) | ✓ |
| ACCUMULATIONTYPE | ✓ | `` | ✓ |
| ACHBANK | ✓ | `` | ✓ |
| AFRSETUP | ✓ | `` | — |
| ALLOCATION | ✓ | `` | ✓ |
| APACCOUNTLABEL | ✓ | `` | ✓ |
| APADJUSTMENT | ✓ | `` | ✓ |
| APADJUSTMENTSUMMARIES | ✓ | `` | — |
| APBILL | ✓ | `` | ✓ |
| APBILLBATCH | ✓ | `` | ✓ |
| APPAYMENTREQUEST | ✓ | `` | ✓ |
| APPYMT | ✓ | `` | ✓ |
| APPYMTDETAIL | ✓ | `` | ✓ |
| APRECURBILL | ✓ | `` | ✓ |
| APRETAINAGERELEASE | ✓ | `` | ✓ |
| APTERM | ✓ | `` | ✓ |
| ARACCOUNTLABEL | ✓ | `` | ✓ |
| ARADJUSTMENT | ✓ | `` | ✓ |
| ARADJUSTMENTSUMMARIES | ✓ | `` | — |
| ARADVANCE | ✓ | `` | ✓ |
| ARINVOICE | ✓ | `` | ✓ |
| ARINVOICEBATCH | ✓ | `` | ✓ |
| ARPYMT | ✓ | `` | ✓ |
| ARRECURINVOICE | ✓ | `` | ✓ |
| ARRETAINAGERELEASE | ✓ | `` | ✓ |
| ARTERM | ✓ | `` | ✓ |
| ATTACHMENTFOLDERS | ✓ | `` | — |
| ATTACHMENTS | ✓ | `` | — |
| BANKACCTRECON | ✓ | `` | ✓ |
| BANKACCTTXNFEED | ✓ | `` | ✓ |

_First 30 of 163 objects shown, alphabetically. The full catalog is the metadata file cited above._

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

- **No rows landed** in either proof DB at generation time.

### Push (write / bidirectional)

- **Status: Not separately verified.** Untested.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.

---

_Capability section derived from this connector's own metadata on 2026-07-28. Proof numbers are DB ground
truth as of 2026-07-26 (`gen-support-docs.mjs`), and are re-stated verbatim — they change only when a
new live sync is run and the doc is regenerated._
