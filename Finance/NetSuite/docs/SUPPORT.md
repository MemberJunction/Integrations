# NetSuite — Supported & Proven

> **Evidence tier:** 🟡 Honest-NA (untested for a documented, non-defect reason)  ·  **Last verified:** 2026-07-26  ·  **Proof DB(s):** —

> 🟡 **Honest-NA:** The test credential returns HTTP 401 (expired/invalid) — untested, no connector defect.

## What this connector supports

**205 objects** declared across **431 fields** (source: `metadata/integration/.netsuite.integration.json`). 203 declare a write path; 2 are read-only (pull). 203 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| Account | ✓ | `CUD` | ✓ |
| Accounting Book | ✓ | `CUD` | ✓ |
| Accounting Period | ✓ | `CUD` | ✓ |
| Advanced Intercompany Journal Entry | ✓ | `CUD` | ✓ |
| Analytical Impact | ✓ | `CUD` | ✓ |
| Assembly Build | ✓ | `CUD` | ✓ |
| Assembly Item | ✓ | `CUD` | ✓ |
| Assembly Unbuild | ✓ | `CUD` | ✓ |
| Automated Clearing House | ✓ | `CUD` | ✓ |
| Billing Account | ✓ | `CUD` | ✓ |
| Billing Revenue Event | ✓ | `CUD` | ✓ |
| Billing Schedule | ✓ | `CUD` | ✓ |
| Bin | ✓ | `CUD` | ✓ |
| Bin Putaway Worksheet | ✓ | `CUD` | ✓ |
| Bin Transfer | ✓ | `CUD` | ✓ |
| Blanket Purchase Order | ✓ | `CUD` | ✓ |
| BOM | ✓ | `CUD` | ✓ |
| BOM Revision | ✓ | `CUD` | ✓ |
| Budget Category | ✓ | `CUD` | ✓ |
| Budget Exchange Rate | ✓ | `CUD` | ✓ |
| Budget Import | ✓ | `CUD` | ✓ |
| Campaign | ✓ | `CUD` | ✓ |
| Campaign Audience | ✓ | `CUD` | ✓ |
| Campaign Category | ✓ | `CUD` | ✓ |
| Campaign Channel | ✓ | `CUD` | ✓ |
| Campaign Family | ✓ | `CUD` | ✓ |
| Campaign Offer | ✓ | `CUD` | ✓ |
| Campaign Response | ✓ | `CUD` | ✓ |
| Campaign Search Engine | ✓ | `CUD` | ✓ |
| Campaign Subscription | ✓ | `CUD` | ✓ |

_First 30 of 205 objects shown, alphabetically. The full catalog is the metadata file cited above._

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

- **No rows landed** in either proof DB at generation time.

### Push (write / bidirectional)

- **Status: Not separately verified.** Untested — credential gap.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.

---

_Capability section derived from this connector's own metadata on 2026-07-28. Proof numbers are DB ground
truth as of 2026-07-26 (`gen-support-docs.mjs`), and are re-stated verbatim — they change only when a
new live sync is run and the doc is regenerated._
