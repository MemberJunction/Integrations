# SharePoint — Supported & Proven

> **Evidence tier:** 🟢 Live-vendor (real API + real account)  ·  **Last verified:** 2026-07-26  ·  **Proof DB(s):** MJ_SS_E2E, MJ_CT48

## What this connector supports

**25 objects** declared across **362 fields** (source: `metadata/integration/.sharepoint.integration.json`). 4 declare a write path; 21 are read-only (pull). 3 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| BaseSitePage | ✓ | — (read-only) | — |
| ColumnDefinition | ✓ | — (read-only) | — |
| ColumnLink | ✓ | — (read-only) | — |
| ContentType | ✓ | — (read-only) | — |
| DocumentSetVersion | ✓ | — (read-only) | — |
| Drive | ✓ | — (read-only) | — |
| DriveItem | ✓ | `` | ✓ |
| DriveItemVersion | ✓ | — (read-only) | — |
| ItemActivity | ✓ | — (read-only) | — |
| ItemActivityStat | ✓ | — (read-only) | — |
| ItemAnalytics | ✓ | — (read-only) | — |
| ItemRetentionLabel | ✓ | — (read-only) | — |
| List | ✓ | `` | — |
| ListItem | ✓ | `` | ✓ |
| ListItemVersion | ✓ | — (read-only) | — |
| Permission | ✓ | — (read-only) | — |
| SharedDriveItem | ✓ | — (read-only) | — |
| Site | ✓ | — (read-only) | ✓ |
| SitePage | ✓ | — (read-only) | — |
| Subscription | ✓ | `` | — |
| TermStoreGroup | ✓ | — (read-only) | — |
| TermStoreRelation | ✓ | — (read-only) | — |
| TermStoreSet | ✓ | — (read-only) | — |
| TermStoreStore | ✓ | — (read-only) | — |
| TermStoreTerm | ✓ | — (read-only) | — |

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

| Object | Label | Rows (DB-verified) | Which DB |
|---|---|---|---|
| ListItem | Proven | 966 | MJ_SS_E2E |
| Drive | Proven | 489 | MJ_SS_E2E |
| List | Proven | 456 | MJ_SS_E2E |
| Site | Proven | 435 | MJ_SS_E2E |
| Site | Proven | 435 | MJ_CT48 |

**Total proven rows: 2,781** across 4 distinct objects (5 object×DB landings).

### Push (write / bidirectional)

- **Status: Heavily experimental (Create-only).** Only ListItem create is wired; no live write executed.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.

---

_Capability section derived from this connector's own metadata on 2026-07-28. Proof numbers are DB ground
truth as of 2026-07-26 (`gen-support-docs.mjs`), and are re-stated verbatim — they change only when a
new live sync is run and the doc is regenerated._
