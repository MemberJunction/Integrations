# PropFuel — Supported & Proven

> **Evidence tier:** 🟢 Live-vendor (real API + real account)  ·  **Last verified:** 2026-07-26  ·  **Proof DB(s):** MJ_CT48

## What this connector supports

**1 objects** declared across **0 fields** (source: `metadata/integration/.propfuel.integration.json`). 0 declare a write path; 1 are read-only (pull). 1 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| propfuel_data_export_file | ✓ | — (read-only) | ✓ |

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

| Object | Label | Rows (DB-verified) | Which DB |
|---|---|---|---|
| clicks | Proven `!` | 4,000 `!` | MJ_CT48 |
| checkin_questions | Proven `!` | 500 `!` | MJ_CT48 |

**Total proven rows: 4,500** across 2 distinct objects.

> ℹ️ **`!` = round-number worth a glance (2 objects: clicks=4000, checkin_questions=500).** These counts are ≥200 and exactly divisible by 100. That is *sometimes* the signature of an un-paged pull cap — so it's flagged for a look — but a round total is **not** itself evidence of truncation, and where the run's `forward.completeness` check passed, the pull was complete and the round number is just the real count. Treat `!` as "confirm, don't assume broken."

### Push (write / bidirectional)

- **Status: Not supported.** Read-only connector — no write path exists.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.

---

_Capability section derived from this connector's own metadata on 2026-07-28. Proof numbers are DB ground
truth as of 2026-07-26 (`gen-support-docs.mjs`), and are re-stated verbatim — they change only when a
new live sync is run and the doc is regenerated._
