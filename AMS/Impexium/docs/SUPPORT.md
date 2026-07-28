# Impexium — Supported & Proven

> **Evidence tier:** 🟡 Honest-NA (untested for a documented, non-defect reason)  ·  **Last verified:** 2026-07-26  ·  **Proof DB(s):** —

> 🟡 **Honest-NA:** No live plan / credential in this campaign.

## What this connector supports

**46 objects** declared across **433 fields** (source: `metadata/integration/.impexium.integration.json`). 23 declare a write path; 23 are read-only (pull). 4 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| AbandonedCheckouts | ✓ | — (read-only) | — |
| Activities | ✓ | `C` | — |
| Addresses | ✓ | `C` | — |
| AwardIndividualRecipients | ✓ | — (read-only) | — |
| AwardNominations | ✓ | `CU` | — |
| AwardOrganizationRecipients | ✓ | — (read-only) | — |
| Awards | ✓ | — (read-only) | — |
| Categories | ✓ | `CD` | — |
| Certifications | ✓ | — (read-only) | — |
| CommitteeMembers | ✓ | `CU` | — |
| CommitteeNominees | ✓ | `C` | — |
| CommitteePositions | ✓ | — (read-only) | — |
| Committees | ✓ | — (read-only) | — |
| Countries | ✓ | — (read-only) | — |
| CourseAttendees | ✓ | — (read-only) | — |
| CustomerRequests | ✓ | `CU` | — |
| CustomFieldDefinitions | ✓ | — (read-only) | — |
| CustomFieldValues | ✓ | `C` | — |
| EducationCredits | ✓ | `C` | — |
| Emails | ✓ | `CU` | — |
| EventAttendance | ✓ | `U` | — |
| EventCancellations | ✓ | — (read-only) | ✓ |
| EventRegistrations | ✓ | — (read-only) | ✓ |
| Events | ✓ | — (read-only) | — |
| Exams | ✓ | — (read-only) | ✓ |
| ExamScores | ✓ | `C` | — |
| Exhibitors | ✓ | — (read-only) | — |
| Exhibits | ✓ | — (read-only) | — |
| Individuals | ✓ | `C` | — |
| Licenses | ✓ | — (read-only) | — |

_First 30 of 46 objects shown, alphabetically. The full catalog is the metadata file cited above._

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

- **No rows landed** in either proof DB at generation time.

### Push (write / bidirectional)

- **Status: Heavily experimental.** Metadata declares write; nothing verified.
- **Declared write surface (metadata):** 23 of 46 objects declare a substantiated write path (Create/Update/Delete APIPath+Method).
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.
- **Coverage:** 0 of 46 declared objects have proven rows; the remainder are Not tested / Discovered (many may be empty in the test account).

---

_Capability section derived from this connector's own metadata on 2026-07-28. Proof numbers are DB ground
truth as of 2026-07-26 (`gen-support-docs.mjs`), and are re-stated verbatim — they change only when a
new live sync is run and the doc is regenerated._
