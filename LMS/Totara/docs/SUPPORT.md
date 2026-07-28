# Totara — Supported & Proven

> **Evidence tier:** 🟢 Live-vendor (real API + real account)  ·  **Last verified:** 2026-07-26  ·  **Proof DB(s):** MJ_CT48

## What this connector supports

**28 objects** declared across **269 fields** (source: `metadata/integration/.totara.integration.json`). 13 declare a write path; 15 are read-only (pull). 0 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| Activity Completion Status | ✓ | — (read-only) | — |
| Blocked Users | ✓ | — (read-only) | — |
| Calendar Events | ✓ | `CD` | — |
| Cohort Members | ✓ | `CD` | — |
| Cohorts | ✓ | `CUD` | — |
| Competencies | ✓ | — (read-only) | — |
| Competency Assignments | ✓ | — (read-only) | — |
| Competency Frameworks | ✓ | — (read-only) | — |
| Contacts | ✓ | `CD` | — |
| Course Categories | ✓ | `CUD` | — |
| Course Completion Status | ✓ | — (read-only) | — |
| Course Contents | ✓ | — (read-only) | — |
| Course Enrolment Methods | ✓ | — (read-only) | — |
| Course Grades Overview | ✓ | — (read-only) | — |
| Courses | ✓ | `CUD` | — |
| Enrolled Users | ✓ | `CD` | — |
| Grade Items | ✓ | — (read-only) | — |
| Group Members | ✓ | `CD` | — |
| Groupings | ✓ | `CUD` | — |
| Groups | ✓ | `CD` | — |
| Messages | ✓ | `CD` | — |
| Notes | ✓ | `CUD` | — |
| Organisation Frameworks | ✓ | — (read-only) | — |
| Organisations | ✓ | — (read-only) | — |
| Position Frameworks | ✓ | — (read-only) | — |
| Positions | ✓ | — (read-only) | — |
| User Badges | ✓ | — (read-only) | — |
| Users | ✓ | `CUD` | — |

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

| Object | Label | Rows (DB-verified) | Which DB |
|---|---|---|---|
| Courses | Proven | 424 | MJ_CT48 |
| Cohorts | Proven | 97 | MJ_CT48 |
| Course_Categories | Proven | 66 | MJ_CT48 |
| Calendar_Events | Proven | 2 | MJ_CT48 |

**Total proven rows: 589** across 4 of 28 declared objects.

**Declared but 0 rows landed (24 of 28, name-matched):** Course Contents, Course Completion Status, Activity Completion Status, Course Enrolment Methods, Users, Enrolled Users, Cohort Members, Groups, Groupings, Group Members, Grade Items, Course Grades Overview, User Badges, Notes, Messages, Contacts, Blocked Users, Organisation Frameworks, Organisations, Position Frameworks, Positions, Competencies, Competency Assignments, Competency Frameworks.

> These objects are declared/supported but landed no rows. **This split does NOT distinguish the reasons** — a zero here is one of: (a) **keyless by design** — the object has no derivable PK (soft keys), so the connector cannot sync it and the test suite *deliberately* skips it (common — often the majority); (b) a genuinely **empty test account**; or (c) a **silent empty-pull** (a real gap). Only the test suite's per-run *coverage* cell (`zeroRowReal` vs `zeroRowLegitEmpty` vs keyless-skipped) classifies which is which; absent that, treat these as **Not proven at the data level**, but do **not** read them as failures — most are keyless-by-design.

> ⚠️ **Coverage: 4 of 28 declared objects (PARTIAL).** These rows are real and DB-verified, but come from a fraction of the catalog — this is **NOT** a full-catalog "all objects" run. The other 24 objects are Not tested (some may be empty on this tenant, but that is unproven). A full-catalog re-sweep (now the test suite default) is required before this connector is proven in the full-coverage sense.

### Push (write / bidirectional)

- **Status: Heavily experimental.** Metadata declares write on several objects; none verified.
- **Declared write surface (metadata):** 13 of 28 objects declare a substantiated write path (Create/Update/Delete APIPath+Method).
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.
- **Coverage:** 4 of 28 declared objects have proven rows; the remainder are Not tested / Discovered (many may be empty in the test account).

---

_Capability section derived from this connector's own metadata on 2026-07-28. Proof numbers are DB ground
truth as of 2026-07-26 (`gen-support-docs.mjs`), and are re-stated verbatim — they change only when a
new live sync is run and the doc is regenerated._
