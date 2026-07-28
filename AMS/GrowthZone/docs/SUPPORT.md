# GrowthZone — Supported & Proven

> **Evidence tier:** 🟢 Live-vendor (real API + real account)  ·  **Last verified:** 2026-07-26  ·  **Proof DB(s):** MJ_CT48

## What this connector supports

**38 objects** declared across **715 fields** (source: `metadata/integration/.growthzone.integration.json`). 0 declare a write path; 38 are read-only (pull). 1 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| Certification | ✓ | — (read-only) | — |
| CertificationComponent | ✓ | — (read-only) | — |
| Contact | ✓ | — (read-only) | ✓ |
| ContactAddress | ✓ | — (read-only) | — |
| ContactCategory | ✓ | — (read-only) | — |
| ContactCustomField | ✓ | — (read-only) | — |
| ContactEmail | ✓ | — (read-only) | — |
| ContactEngagement | ✓ | — (read-only) | — |
| ContactNotes | ✓ | — (read-only) | — |
| ContactPhone | ✓ | — (read-only) | — |
| ContactWebsite | ✓ | — (read-only) | — |
| Directory | ✓ | — (read-only) | — |
| DirectoryListingType | ✓ | — (read-only) | — |
| Event | ✓ | — (read-only) | — |
| EventAttendee | ✓ | — (read-only) | — |
| EventCalendar | ✓ | — (read-only) | — |
| EventExhibitor | ✓ | — (read-only) | — |
| EventExhibitorType | ✓ | — (read-only) | — |
| EventRegistrationType | ✓ | — (read-only) | — |
| EventSession | ✓ | — (read-only) | — |
| EventSponsor | ✓ | — (read-only) | — |
| EventSponsorshipBenefit | ✓ | — (read-only) | — |
| EventTask | ✓ | — (read-only) | — |
| EventVenue | ✓ | — (read-only) | — |
| Group | ✓ | — (read-only) | — |
| GroupCategory | ✓ | — (read-only) | — |
| GroupMember | ✓ | — (read-only) | — |
| Membership | ✓ | — (read-only) | — |
| MembershipChange | ✓ | — (read-only) | — |
| MembershipLevel | ✓ | — (read-only) | — |

_First 30 of 38 objects shown, alphabetically. The full catalog is the metadata file cited above._

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

| Object | Label | Rows (DB-verified) | Which DB |
|---|---|---|---|
| Contact | Proven | 465 | MJ_CT48 |
| ContactAddress | Proven | 230 | MJ_CT48 |
| Event | Proven | 127 | MJ_CT48 |
| Membership | Proven | 90 | MJ_CT48 |

**Total proven rows: 912** across 4 distinct objects.

### Push (write / bidirectional)

- **Status: Heavily experimental.** OAuth connector; write not verified live or mock.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.

---

_Capability section derived from this connector's own metadata on 2026-07-28. Proof numbers are DB ground
truth as of 2026-07-26 (`gen-support-docs.mjs`), and are re-stated verbatim — they change only when a
new live sync is run and the doc is regenerated._
