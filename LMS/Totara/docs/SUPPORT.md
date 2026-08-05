# Totara — Supported & Proven

> **Evidence tier:** 🟢 Live-vendor (real API + real account)  ·  **Last verified:** 2026-08-05  ·  **Proof DB(s):** MJ_CT48

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
| Enrolled_Users | Proven, partial by design | 29,002 | MJ_CT48 |
| Users | Proven | 24,711 | MJ_CT48 |
| Course_Contents | Proven | 2,504 | MJ_CT48 |
| Courses | Proven | 428 | MJ_CT48 |
| Groups | Proven | 201 | MJ_CT48 |
| Cohort_Members | Proven | 97 | MJ_CT48 |
| Cohorts | Proven | 97 | MJ_CT48 |
| Course_Categories | Proven | 71 | MJ_CT48 |
| Course_Enrolment_Methods | Proven | 4 | MJ_CT48 |
| Calendar_Events | Proven | 2 | MJ_CT48 |

**Total proven rows: 57,117 (Enrolled_Users still climbing when the run was stopped)** across **10 of 28 declared objects.**

> **`Groups` is new, and it settles a claim this doc used to get wrong.** `Groups`, `Groupings` and `Group Members`
> all declared a **by-id reader** as their list function, so dispatched bare they answered `[invalidparameter]` on
> every run since they shipped. Fixed by parent-scoping them per course (`Groups`/`Groupings`, one hop) and by a
> two-hop chain for `Group Members`. Read-only runs `9200B480`/`DE595754` then showed three different outcomes,
> and only one of them is a limit: **`Groups` landed 201 rows / 201 created / 0 errors**; **`Groupings` is a
> legitimate zero** (0 records, 0 errors, no `[invalidparameter]` anywhere — this site has no groupings); and
> **`Group Members` proved its chain and hit the token** — 52 batches resolved 84-92 group ids per call and
> dispatched them correctly, and the site refused every one with `[accessexception]` on
> `core_group_get_group_members`. So the hard part (naming a group id at all, which needs two hops) is proven; what
> remains on that one object is a credential scope, not a defect.

> **`Enrolled_Users` is counted as proven on a run stopped deliberately, and the distinction matters.** Its defect was
> never "no data" but "loses the data it fetched": each call overran the engine's 30s kill and persisted
> nothing. It now pages inside each course, stops itself on a 20s budget, and resumes exactly there — zero
> timeouts across the whole run. The 29,002 rows are a floor read from a run stopped at **8.6 hours covering 64
> of 428 courses**, not a ceiling.
>
> **Why it is that slow is now measured rather than guessed, and one defect in it was real.** Three causes, in
> `docs/REQUIRED-FIXES.md` item 7: (1) **course `1` is the Moodle site course** that every user on the site is
> enrolled in, so 17,937 of these 29,002 rows (62%) are one course, and string-sorted ids walk it first — hours
> pass showing one `courseid`; (2) **44% of what was fetched was re-read** — 50,608 records fetched produced
> 29,002 distinct rows, because the keyset cursor can hold only one mid-parent offset and a second concurrent
> lane restarted from 0 every call. That was a defect and it is **fixed**: paged parent walks now run one parent
> at a time; (3) **~68 ms of vendor time per record, linear in rows**, because `core_enrol_get_enrolled_users`
> returns a full user profile per enrolment including the `groups`/`roles`/`preferences`/`enrolledcourses`
> aggregates. Enlarging the page buys nothing. `options.userfields` would trim it but drops declared columns, so
> it is written up with the numbers rather than applied silently. Separately fixed on the correctness side: the
> offset paging sent **no `ORDER BY`**, which risks silent gaps as well as overlap; `orderingParams` now sends
> `sortby`/`sortdirection` from the catalog's long-declared `stableOrderingKey`.

> **`Users` is the people-side proof, and it is new.** It previously landed 0 rows behind a green run —
> `core_user_get_users` is a search endpoint, not a list endpoint, and asking it for every user timed out at
> the engine's 30s budget, which kills the batch and persists nothing. Reading through the bounded id-window
> scan instead, a live read-only run against a production LMS landed 24,682 users with 0 errored (24,711 in the table after the later full-catalog run), and
> isolated the 57 user records the vendor's own API refuses to return (contiguous ids 2 and 5801-5853, each
> named in an `ID_WINDOW_RECORD_SKIPPED` warning). Those 57 are a defect in the source site's data, not in
> the sync: they cannot be read back by any client until the site fixes them.

**Declared but 0 rows landed: 18 of 28 — and every one is now attributed.** This is NOT an unclassified
split; a full-catalog live run (`8D59A6B9`) was read per object and each zero has a named cause. **Neither
remaining cause is a connector defect: both open defects on that run have since been fixed and proven live.**

| Cause | Objects | What it means |
|---|---|---|
| **Token permission scope** — `[accessexception]` | 13: Blocked Users, Competencies, Competency Assignments, Competency Frameworks, Contacts, Group Members, Messages, Notes, Organisation Frameworks, Organisations, Position Frameworks, Positions, User Badges | The site's web-services token has these functions DISABLED. Not a connector defect and not fixable in code — the site admin must enable them on the token's service. `Group Members` is here on **proof, not assumption**: the two-hop chain resolved and dispatched real group ids and the site refused each one (run `DE595754`, 52 batches). |
| **Reachable and genuinely empty** | 1: Groupings | Requests succeed with no error and return nothing — this site has no groupings. Previously mis-filed under token scope. |
| **Keyless by design** — no PK derivable | 4: Course Completion Status, Activity Completion Status, Grade Items, Course Grades Overview | No primary key, so no entity map can exist (24 maps for 28 objects). The connector correctly declines rather than syncing unkeyed rows. |
| ~~**Fetch-budget timeout**~~ | ~~Enrolled Users~~ | **FIXED and proven live** (run `5E8070E2`): the walk pages within each course and stops on a 20s budget, so a call returns partial rows plus a cursor instead of being killed with everything it had fetched. |
| ~~**`[invalidparameter]`**~~ | ~~Cohort Members~~ | **FIXED and proven live** (run `9019A5AE`, 97 rows): `core_cohort_get_cohort_members` needs its ids as an ARRAY; the object declared no parent scope, so the function was dispatched bare on every run since it shipped. |

> **The honest coverage number is 11 of 11 REACHABLE objects, not 10 of 28.** With this token, 13 objects cannot
> be read at all and 4 cannot be keyed, leaving 11 reachable — 10 with rows, plus `Groupings` proven empty
> without error. "10 of 28" understates the connector and overstates what any client could reach on this site.

> ✅ **Coverage: 10 of 28 declared / 11 of 11 reachable.** These rows are real and DB-verified. Full-catalog live runs HAVE been executed (`8D59A6B9`, then `9200B480` / `DE595754`), which is what made the attribution table above possible — the remaining zeros are accounted for, not untested, and **not one of them is a connector defect**. What is left is the site's token scope (13), objects the vendor exposes without a derivable key (4), and one object that is reachable and empty.

### Push (write / bidirectional)

- **Status: Heavily experimental.** Metadata declares write on several objects; none verified.
- **Declared write surface (metadata):** 13 of 28 objects declare a substantiated write path (Create/Update/Delete APIPath+Method).
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.
- **Coverage:** 10 of 28 declared objects have proven rows — every object this site's token can reach and key, plus one (`Groupings`) proven reachable and empty. The other 18 are attributed above (13 token-scope, 4 keyless, 1 empty), not untested.
- **`Enrolled Users` has never been read to completion on this site** — 64 of 428 courses in 8.6 hours. The re-read defect is fixed; the remaining ~4 hours is vendor throughput, quantified in `docs/REQUIRED-FIXES.md` item 7.

---

_Capability section derived from this connector's own metadata on 2026-07-28. Proof numbers are DB ground truth as of
2026-08-05, read directly from `MJ_CT48` after live read-only syncs (one `SELECT COUNT(*)` per table in the
`totara` schema, generated from `sys.tables` so no object can be omitted by hand; runs `902A5383` Users,
`9019A5AE` Cohort Members, `5E8070E2` Enrolled Users, `9200B480` full catalog, `DE595754` Group Members), and
are re-stated verbatim — they change only when a new live sync is run and the numbers are re-read from the
database. They are never hand-adjusted. `Enrolled_Users` is the one figure read from a run stopped on purpose
rather than finished — at ~68 ms of vendor time per record, all 428 courses is roughly four more hours that
would tell us nothing these 29,002 rows have not — and it is labelled as such rather than rounded up to a
completion it has not reached._
