# PheedLoop — Supported & Proven

> **Evidence tier:** 🥇 Client-DB-live (real client tenant, production data)  ·  **Last verified:** 2026-07-26  ·  **Proof DB(s):** MJ_CT48

## What this connector supports

**28 objects** declared across **487 fields** (source: `metadata/integration/.pheedloop.integration.json`). 19 declare a write path; 9 are read-only (pull). 4 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| Attendees | ✓ | `CUD` | — |
| ContactTags | ✓ | `CUD` | — |
| EventAnnouncements | ✓ | `CUD` | — |
| EventAttendance | ✓ | `CD` | — |
| Events | ✓ | `U` | ✓ |
| ExhibitorPromotion | ✓ | — (read-only) | — |
| Exhibitors | ✓ | `CUD` | — |
| ExhibitorsBooths | ✓ | `CUD` | — |
| MemberOrganization | ✓ | `CUD` | — |
| Members | ✓ | `CU` | ✓ |
| Memberships | ✓ | `CUD` | — |
| OrgAnnouncements | ✓ | `CUD` | — |
| RegistrationPromotion | ✓ | — (read-only) | — |
| Registrations | ✓ | — (read-only) | ✓ |
| Reports | ✓ | — (read-only) | — |
| RESTHooks | ✓ | `CUD` | — |
| SessionFormats | ✓ | `CUD` | — |
| SessionRegistration | ✓ | `CUD` | — |
| Sessions | ✓ | `CUD` | — |
| Speakers | ✓ | `CUD` | — |
| SpeakerTags | ✓ | `CUD` | — |
| SponsorPromotion | ✓ | — (read-only) | — |
| Sponsors | ✓ | `CUD` | — |
| SponsorTier | ✓ | `CUD` | — |
| Surcharge | ✓ | — (read-only) | — |
| Tags | ✓ | — (read-only) | — |
| Tickets | ✓ | — (read-only) | — |
| TicketTransferLogs | ✓ | — (read-only) | ✓ |

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

| Object | Label | Rows (DB-verified) | Which DB |
|---|---|---|---|
| Attendees | Proven | 246 | MJ_CT48 |
| Events | Proven | 4 | MJ_CT48 |

**Total proven rows: 250** across 2 distinct objects.

### Push (write / bidirectional)

- **Status: Heavily experimental (Create) / Declared-not-implemented (Update, Delete).** Only Create is wired. Update/Delete report as supported but throw at runtime — not writable in practice. No live write executed.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.

---

_Capability section derived from this connector's own metadata on 2026-07-28. Proof numbers are DB ground
truth as of 2026-07-26 (`gen-support-docs.mjs`), and are re-stated verbatim — they change only when a
new live sync is run and the doc is regenerated._
