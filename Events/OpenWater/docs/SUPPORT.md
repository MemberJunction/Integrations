# OpenWater — Supported & Proven

> **Evidence tier:** 🥇 Client-DB-live (real client tenant, production data)  ·  **Last verified:** 2026-07-26  ·  **Proof DB(s):** MJ_CT48

## What this connector supports

**25 objects** declared across **166 fields** (source: `metadata/integration/.openwater.integration.json`). 10 declare a write path; 15 are read-only (pull). 11 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| Application | ✓ | `CD` | ✓ |
| ApplicationCategory | ✓ | — (read-only) | — |
| BillingLineItem | ✓ | — (read-only) | ✓ |
| DeletedApplication | ✓ | — (read-only) | ✓ |
| DeletedSession | ✓ | — (read-only) | ✓ |
| Evaluation | ✓ | `U` | ✓ |
| Fund | ✓ | — (read-only) | — |
| FundTransaction | ✓ | — (read-only) | — |
| Invoice | ✓ | — (read-only) | ✓ |
| JudgeAssignment | ✓ | `CD` | — |
| JudgeRecusal | ✓ | — (read-only) | — |
| JudgeTeam | ✓ | `C` | — |
| OtherSessionItemType | ✓ | — (read-only) | — |
| Payment | ✓ | — (read-only) | ✓ |
| Program | ✓ | — (read-only) | ✓ |
| Refund | ✓ | — (read-only) | ✓ |
| Report | ✓ | — (read-only) | — |
| Rounds | ✓ | — (read-only) | — |
| ScheduleDay | ✓ | `CUD` | — |
| ScheduleItem | ✓ | `CD` | — |
| ScheduleRoom | ✓ | `CUD` | — |
| ScheduleTimeSlot | ✓ | `CUD` | — |
| Session | ✓ | `CD` | ✓ |
| SessionType | ✓ | — (read-only) | — |
| User | ✓ | `CU` | ✓ |

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

| Object | Label | Rows (DB-verified) | Which DB |
|---|---|---|---|
| Program | Proven | 5 | MJ_CT48 |

**Total proven rows: 5** across 1 distinct objects.

### Push (write / bidirectional)

- **Status: Heavily experimental.** Full C/U/D wired in the class; no live write executed. (A live run once moved 13,170 rows into a since-torn-down DB — read direction.)
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.

---

_Capability section derived from this connector's own metadata on 2026-07-28. Proof numbers are DB ground
truth as of 2026-07-26 (`gen-support-docs.mjs`), and are re-stated verbatim — they change only when a
new live sync is run and the doc is regenerated._
