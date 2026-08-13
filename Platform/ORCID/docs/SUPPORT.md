# ORCID — Supported & Proven

> **Evidence tier:** 🥇 Production-live (real production system, real data)  ·  **Last verified:** 2026-07-26  ·  **Proof DB(s):** MJ_CT48
>
> **Known issues:** In production use with a client today, and still needs work — treat it as live but not finished.

## What this connector supports

**12 objects** declared across **192 fields** (source: `metadata/integration/.orcid.integration.json`). 0 declare a write path; 12 are read-only (pull). 12 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| distinctions | ✓ | — (read-only) | ✓ |
| educations | ✓ | — (read-only) | ✓ |
| employments | ✓ | — (read-only) | ✓ |
| fundings | ✓ | — (read-only) | ✓ |
| invited-positions | ✓ | — (read-only) | ✓ |
| memberships | ✓ | — (read-only) | ✓ |
| peer-reviews | ✓ | — (read-only) | ✓ |
| qualifications | ✓ | — (read-only) | ✓ |
| record | ✓ | — (read-only) | ✓ |
| research-resources | ✓ | — (read-only) | ✓ |
| services | ✓ | — (read-only) | ✓ |
| works | ✓ | — (read-only) | ✓ |

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

| Object | Label | Rows (DB-verified) | Which DB |
|---|---|---|---|
| employments | Proven | 38 | MJ_CT48 |
| fundings | Proven | 7 | MJ_CT48 |

**Total proven rows: 45** across 2 distinct objects.

### Push (write / bidirectional)

- **Status: Heavily experimental.** Write not verified.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.

---

_Capability section derived from this connector's own metadata on 2026-07-28. Proof numbers are DB ground
truth as of 2026-07-26 (`gen-support-docs.mjs`), and are re-stated verbatim — they change only when a
new live sync is run and the doc is regenerated._
