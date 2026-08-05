# Totara connector — required fixes for the next release

Open defects found while proving this connector against a live production LMS (read-only). Each entry
names the failure as a *user* experiences it, the evidence, and what the fix has to do. Delete an entry
when it ships — a changeset entry is the record of the fix, this file is the record of the debt.

Nothing here is speculative: every item was observed in a live run, not inferred from reading code.

---

## 1. Users landed 0 rows behind a green run — FIXED and PROVEN LIVE

`core_user_get_users` is not a list function. Fixed by the id-window scan
(`Configuration.idWindowScan` + `fetchIdWindowScan`, changeset `totara-users-id-window-scan`).
Unit-tested (4 tests) and the delta migration is verified idempotent against SQL Server.

Two further live failures were found while verifying that fix, and both are now fixed in the same
changeset:

- **The whole call, not just each request, has to fit the budget.** Five bounded windows in one call still
  overran `FetchChangesMs` together and were killed with 0 records — the original symptom exactly. The scan
  now carries a `budgetMs` deadline (20000) and returns partial progress with its cursor
  (`ID_WINDOW_BUDGET_STOP`).
- **A single unreadable record killed the whole object, forever.** Totara answered every id window with
  `[invalidresponse]` (it validates its own response per record, so one bad user row fails the entire call).
  Because a failed window is correctly not treated as an empty one, the cursor never advanced: 61 identical
  failures in one run, 0 users, no forward progress possible. Failed windows are now bisected to single ids;
  an id that fails alone is skipped with `ID_WINDOW_RECORD_SKIPPED` naming it, and the scan moves on.

**Closed out.** A live read-only run against the production site landed **24,682 users, 0 errored** (run
`902A5383`, Status Success), and `SUPPORT.md` was re-read from the database afterwards — 27,783 rows across
7 of 28 objects, up from 589 across 4. (Items 2 and 2b below have since carried that to **9 of 28 — every
reachable object on this site**; `SUPPORT.md` holds the current numbers.)

The scan itself no longer lives in this connector: it moved to `@memberjunction/connector-id-window-scan`
so the other **235** fleet objects with the same one-shot shape (`npm run audit:unlistable`) do not have to
rediscover the budget, bisection, and cursor rules. Totara now supplies only the Moodle-specific "turn these
ids into one request". The refactor was re-proven live — same bisect descent, same isolated id, same counts.

---

## 1a. Unreadable ids come in CONTIGUOUS BLOCKS, so bisection repeats per id — FIXED

The live run's skipped ids were not scattered: `id=2`, then an unbroken block `5801–5853`. Every one of
those windows had to be bisected from scratch (25 → 12 → 6 → 3 → 2 → 1) to isolate a single id, and the
next window did it all over again — 235 `ID_WINDOW_FETCH_ERROR`s to skip 57 records. The scan stayed
correct and inside its budget throughout, so this is a cost item, not a defect: a poison block of 53 ids
burned roughly a minute of wall clock that a smarter strategy would not.

**Fixed** exactly as scoped: after `singleStepAfterConsecutiveSkips` ids in a row are proven unreadable
(default 2), the scan stops issuing the bulk request it knows will fail and reads id-at-a-time until one
succeeds, at which point the rest of the window is fetched in bulk again. The counter rides the **cursor**
rather than the call — a poison block outlives one call's windows, and a per-call counter would forget it
at every boundary and re-pay the first bisection, which is most of the waste. Changeset
`id-window-poison-blocks-walk-once`; three tests, one of which asserts the request count is strictly lower
than with the optimisation disabled.

Coverage is untouched: every id is still examined individually and still named in its own
`ID_WINDOW_RECORD_SKIPPED`. The new `ID_WINDOW_SINGLE_STEP` is emitted once per call, not per window.

**Also worth reporting to the site owner, not fixing here:** 57 of their user records cannot be read back
by their own API (Moodle/Totara return validation), and a block that dense points at one bad profile field
on a batch of accounts created together. Those users will never sync from any client until it is fixed —
the connector names each one in an `ID_WINDOW_RECORD_SKIPPED` warning precisely so this is actionable.

---

## 1b. A resumed run ignores the run's `EntityMapIDs` filter (engine, not connector)

Killing MJAPI mid-run and restarting it resumes the run — but a run started with `entityMapIDs` scoped to
a single map resumes **all 24** maps (`[IntegrationEngine] Resuming 24 remaining entity maps (of 24 total)`).
Harmless in test, wrong in production: an operator who deliberately narrowed a sync gets a full one after
any restart, against a live vendor.

Engine-side (`IntegrationEngine.resume*`), so it is filed here only because Totara exposed it.

**Fix must:** persist the run's map filter with the run and re-apply it on resume.

A resumed run also **stops writing to its run artifact**: `logs/integration-runs/<runID>/progress.jsonl`
froze at the moment of the restart while the resume kept working for many minutes (visible only on the
server console). Every consumer that reads the artifact — including the platform's progress UI — shows a
resumed run as dead. Same fix area: reattach the `SyncLogger` to the existing run on resume.

---

## 2. `Enrolled Users` / `Course Enrolment Methods` blew the fetch budget — FIXED and PROVEN LIVE

Both walk parents (one call per course) inside the same `FetchChangesMs = 30000` budget that killed
Users. `Enrolled Users` timed out 3× at 30000ms and persisted 0 records in the same live run. The walk was
keyset-resumable and still died, because resumability is not a time bound: a page cap of N parents says
nothing about how long N vendor calls take, and a killed batch persists **nothing** — including the parents
it had already fetched.

The failure mode was the dangerous one — a fetch timeout is reported as a warning while the entity map
still reports success, so the object read as "this site has no enrolments" rather than as an error.

**Fixed** by bounding the walk in time (`parentScope.budgetMs`, default 20000, under the kill): the call
returns `HasMore:true` with partial progress and a `PARENT_BUDGET_STOP` warning. The cursor advances only
over the contiguous PREFIX of parents actually examined — records from parents that finished out of order
past a skipped one are kept (upserts are idempotent) but not claimed as covered, so a budget stop can never
silently drop a parent. The first parent of a call always runs, so the walk cannot stall. Changeset
`totara-parent-walk-budget-and-array-param`; seven unit tests.

**Bounding the call was necessary and not sufficient**, and this is the part worth carrying to other
connectors: *a per-call deadline cannot rescue a single request that is itself too big.* After the budget
landed, the object still timed out — proven only by instrumenting the deployed build and reading the clock
rather than the code:

| measured live | |
| --- | --- |
| `core_course_get_courses` (the parent list) | **6147ms**, every call |
| `core_enrol_get_enrolled_users`, one 250-user page | **25823ms** (~10 users/sec — full user profiles) |

One page was the bomb; the budget merely watched it explode. Three further changes, each from a number:
the walk now **pages within a parent** (`pageSize: 50`, resuming into it via a `"<courseid>#<offset>"`
cursor); the deadline gates work **about to start** (`elapsed + slowestRequestSoFar >= budget`, since 900ms
into a 1000ms budget is not permission to start a 900ms request); and the parent list is **cached**
(`parentCacheMs`, default 5 min) so a resumed walk stops paying 6s of its 20s budget before it begins.

Live read-only run `5E8070E2`: **zero 30000ms timeouts** (was 3 per run), records persisting every batch,
each call stopping itself around 350 records and resuming exactly there. The remaining cost is the vendor's,
not ours — at ~17 records/sec this object is a long tail, but it is now a tail that makes forward progress
instead of a green run with nothing in it.

---

## 2b. `Cohort Members` failed with `[invalidparameter]` on every run — FIXED and PROVEN LIVE

Full-catalog live run `8D59A6B9`: `Cohort Members` stopped at batch 1 with
`Totara/Moodle Web Services error [invalidparameter] Invalid parameter value detected`, 0 records. It failed
identically every run, so it was a request-shape defect, not a data or permission problem — the other 15
zero-row objects on that run fail with `[accessexception]` instead, which is the site's token scope and not
ours to fix.

The shape: `core_cohort_get_cohort_members` requires the cohorts to read, as an ARRAY (`cohortids[0]=7`).
The object declared no parent scope at all, so the connector dispatched the function bare. Fixed by
parent-scoping it over `core_cohort_get_cohorts` with `paramStyle:'array'` and an explicit `childIdField`
(the row's FK is singular `cohortid`; the request param is plural `cohortids` — tagging with the param name
would have invented a field matching nothing and left the real FK null). Delta migration
`V202608041720__totara__CohortMembersParentScope` (+ hand-authored `.pg.sql`); two unit tests pin the wire
shape. **Live read-only run `9019A5AE`: 97 rows, one per cohort, matching the 97 rows in `Cohorts`.**

Worth stating plainly because it was previously invisible: of the 21 objects that landed no rows, only TWO
were connector defects (this and `Enrolled Users` above) — both now fixed. 15 are blocked by the token's
permission scope and 4 are keyless by design. The reachable ceiling on this site is 9 objects.

---

## 2c. Two more objects are shaped like `Cohort Members` — FIXED and PROVEN LIVE (2 of 3; the third is a token limit)

`core_group_get_groups(groupids[])` and `core_group_get_groupings(groupingids[])` are by-id readers, not
listers — the same defect class as 2b — and `Group Members` needs a TWO-level walk to reach its parents
(Courses → `core_group_get_course_groups(courseid)` → group ids → `core_group_get_group_members`), which the
single-level `parentScope` did not model.

This was previously left declared-as-is on the grounds that an unprovable guess at a parent chain is worse
than a documented gap. That reasoning held for a *guess*. It does not hold here: the chain is the one Moodle
documents, and leaving three objects dispatching a by-id reader bare is a known-broken request shape, not an
unknown. So the fix ships, with the limit stated rather than hidden.

**Groups / Groupings** — nothing in Moodle lists a site's groups or groupings. The only enumerators are
per-course (`core_group_get_course_groups` / `core_group_get_course_groupings`) and they return the FULL
record, not just an id, so the read function itself becomes the per-course enumerator and the object is
parent-scoped over `core_course_get_courses`. One hop, the same shape as `Course Contents`; write functions
untouched.

**Group Members** — keeps `core_group_get_group_members` and gains the two-hop chain. `parentScope` now
nests: a `parentScope` inside a `parentScope` says how to obtain the inputs for the level above it, so each
level reads exactly like the top one and depth is arbitrary. Two is what the catalog needs.

The chain is paid for out of the **same wall-clock budget** as the walk — one request per id at each hop, so
a 408-course site spends 408 requests just to learn the group ids, and spending those unbudgeted inside the
30000ms `FetchChangesMs` kill is precisely how `Enrolled Users` used to land nothing (item 2). A chain cut
short returns what it resolved, warns `PARENT_CHAIN_TRUNCATED`, and is deliberately **not cached**, so the
next call finishes the job instead of inheriting a short list that looks complete. An upstream hop that errors
costs only its own ids.

Three unit tests (64/64 in `TotaraConnector.test.ts`) pin the wire shape of both hops, the per-hop error
tolerance, and the truncation warning. Delta migration `V202608050400__totara__GroupObjectsParentScope`
(+ hand-authored `.pg.sql`), verified live against the test catalog: 3 rows on first apply, 0 on re-apply.

**PROVEN LIVE — and the previous paragraph here, which said all three were `[accessexception]`, was wrong.**
Read-only runs `9200B480` and `DE595754` on a live production site, read back out of `MJ_CT48`:

| Object | Live outcome | Verdict |
|---|---|---|
| `Groups` | Per-course batches 17, 9, 8, 10, 10, 8, 9, 11, 4, 5, 1, 4, 5, 0, 0, 2 → **201 processed, 201 created, 0 errors**. `totara.Groups` = **201 rows**. | **Proven.** The per-course enumerator and the one-hop scope are both right. |
| `Groupings` | 0 records, 0 errors across ~41 per-course batches. No `[invalidparameter]` anywhere. | **Legitimate zero.** The requests succeed; this site has no groupings. |
| `Group Members` | 52 batches; the two-hop chain resolved **84–92 group ids per call** and dispatched them correctly (`groupids=229`); Totara answered `[accessexception]` to **every one**. 0 records, engine stopped on `CONSECUTIVE_EMPTY_BATCHES`. | **Chain proven, function not granted.** The thing that was in doubt — that two hops can name a group id at all — works. What remains is a credential scope limit on `core_group_get_group_members`. |

So the `[accessexception]` was never about all three objects, and it was never about the chain: `Groups` reads
fine through the same first hop. Only `core_group_get_group_members` itself is ungranted on this token.

**One thing that fix exposed, now also fixed:** 52 identical refusals were reported as 52 `PARENT_FETCH_ERROR`
warnings, which reads like 52 separate faults instead of one ungranted credential. Permission refusals
(`[accessexception]` / `[requiredcapability]` / `[nopermission]`) are now attributed once as `LEAF_FORBIDDEN` —
the grain OpenWater already used — with a distinct partial-refusal form when only some parents are refused. See
`.changeset/totara-paged-walk-throughput-and-ordering.md`.

**Still owed:** `PARENT_CHAIN_TRUNCATED` fired on every `Group Members` call — enumerating group ids costs one
request per course and 84–92 of 428 courses is as far as the 20000ms budget reaches, so the chain is
re-enumerated (uncached, deliberately) every call. Coverage is not lost, but on a site whose token *can* read
group members this would need many calls to reach every group. The arithmetic is in item 7.

---

## 2d. `Enrolled Users` was keyed on the user id alone, so enrolments overwrote each other — FIXED

Found by auditing the landed rows rather than the run: run `5E8070E2` **processed 26,300 records and left
13,950 rows**, and across every course the walk reached only **2 distinct `courseid` values survived**.
Nothing errored and nothing warned. `core_enrol_get_enrolled_users` is read per course, so a user enrolled
in several courses returns once per course with that course's roles and groups — but the catalog declared a
single key field, `id` ("ID of the user"), marked `IsUniqueKey=1`. Every per-course row upserted onto the
same key and the last one written won.

This belongs to the same family as items 1 and 2, and is the most dangerous member of it: those produced a
green run with *nothing* in it, this produces a green run with something *plausible* in it.

`enrol_manual_unenrol_users` is wired as this object's DELETE, which makes the key wrong on the write side
too — a delete keyed on user id alone does not name the course it is unenrolling from.

**Fixed** by declaring the composite `(courseid, id)` the object's own metadata always claimed
(`writeFunctions.createResponseNote`: *"identity is the composite (userid,courseid)"*): `childIdField` added
to `parentScope`, `id` demoted to `IsUniqueKey=0`, `courseid` declared as a second key FK'd to `Courses`.
Delta migration `V202608050300__totara__EnrolledUsersCompositeKey` in both dialects, verified idempotent
against a live catalog — including the branch that PROMOTES the `courseid` row discovery had already
created as a custom column, without which the migration would no-op on precisely the tenants that have the
defect. Changeset `totara-enrolled-users-composite-key`.

The sibling objects are the control group and make the diagnosis exact: `Course Contents` is walked by the
same parent mechanism in the same run and landed **2,504 rows across 408 distinct courses**, because its
`id` is a per-record section id. Same walk, same budget — the only difference is that `Enrolled Users`' `id`
identifies the user, which recurs. Every `parentScope` object in the catalog was swept for this shape
(`Cohort Members`, `Course Contents`, `Course Enrolment Methods`) and all are clean, so this was the one
instance rather than the first of many.

**Still owed:** one full non-incremental pull to prove the per-course rows separate live. The catalog side
is verified; the row-level proof needs a re-run against the site.

---

## 3. The HTTP client has no read timeout — FIXED

`MakeHTTPRequest` set no socket/read deadline. A vendor endpoint that accepts the connection and then
never responds hung the fetch indefinitely — observed twice as wedged worker processes that had to be
killed externally, not as failed runs. That is the failure mode with no artifact: no error, no row, nothing
for anyone to read.

**Fixed** with an `AbortSignal.timeout` resolved once at `Authenticate` — default **25000ms**, under the
engine's `FetchChangesMs = 30000` kill so the connector reports the failure itself rather than being killed
mid-batch and persisting nothing. The abort surfaces as an ordinary error naming the function and the
deadline, so the engine retries it like any other transport failure; a non-abort error is re-thrown
untouched, because a refused connection must not be relabelled as a timeout. Configurable per connection
via `requestTimeoutMs` in `CompanyIntegration.Configuration` (`0` disables it). Changeset
`read-deadline-that-outlives-the-fetch`; four unit tests.

The same pass found the twin defect in OpenWater — it *had* a timeout, but cleared it in a `finally` around
the `fetch` call, i.e. at exactly the moment the response body started streaming, so a stall mid-body still
hung. Recorded here because the two are one lesson: **the deadline has to outlive the call that resolves on
headers.**

---

## 4. Write-phase record errors are invisible

`Course_Categories` deterministically failed to write 62 of 65 records on two consecutive passes with
**no reason recorded anywhere**: every `sync.record.error` in the run artifact carries `phase:"fetch"`,
and all 66 catalog rows read `SyncStatus='Active'`. The count is reported; the cause is not.

This is not Totara-specific — it is a connector/engine observability gap that Totara exposed. Anyone
debugging a partial write today has literally nothing to read.

**Fix must:** emit a `phase:"write"` record error carrying the failing record key and the underlying
error, so a partial write is diagnosable from the run artifact alone.

---

## 5. The PG migration converter silently emits invalid SQL for JSON functions — FIXED

`scripts/build-pg-migrations.mjs` does not translate `JSON_MODIFY`, `JSON_QUERY`, or `ISJSON`. It emits
them as quoted identifiers — `"JSON_MODIFY"(...)` — i.e. calls to functions that do not exist in
PostgreSQL. The generated file looks plausible and passes generation; it would have failed on every PG
tenant at apply time.

Caught only by reading the generated output by hand. `V202608041327__totara__UsersIdWindowScan.pg.sql`
therefore carries a hand-authored jsonb body with a comment saying so.

This is repo-level, not Totara-level, and it affects any connector shipping a JSON-manipulating delta
migration — which is the normal shape for a Configuration fix.

**Fixed** by making generation fail loudly. Translating the JSON functions was the wrong half of the
choice — it would put a second, hand-maintained T-SQL→jsonb translator in this repo, competing with the
converter it wraps and wrong in a different way. Instead `build-pg-migrations.mjs` now audits every
`.pg.sql` after conversion and under `--check`, and exits 1 naming the file and the function.

The check is the general shape, not a list of JSON functions: **a quoted ALL-CAPS identifier used as a
function call** — `"JSON_MODIFY"(` — is the converter's signature for *any* builtin it could not
translate, so the next untranslatable one is caught without editing the guard. Comments, string
literals, and dollar-quoted bodies are stripped before matching, so the honest prose in
`V202608041327__totara__UsersIdWindowScan.pg.sql` ("the converter emits `"JSON_MODIFY"(...)`") is not
flagged as the defect it documents — verified both ways: zero hits across all 83 existing `.pg.sql`
files, and a deliberately planted bad file caught on its code line while the comment beside it was
ignored.

---

## 6. An integer soft-FK column becomes `NVARCHAR(MAX)`, which cannot be indexed — ApplyAll dies (engine)

**This blocks every run.** Live run `live_1785904275762` (2026-08-05) never reached a single fetch — it died
in setup:

```
ApplyAll failed: Pipeline failed: Error executing SQL
  ALTER TABLE ALTER COLUMN courseid failed because one or more objects access this column.
  Preceding errors: The index 'IDX_AUTO_MJ_FKEY_Groups__totara_courseid' is dependent on column 'courseid'.
  Query: -- Auto-generated by MJ SchemaEngine … Action: AlterTables
         ALTER TABLE [totara].[Groups] ALTER COLUMN [courseid] NVARCHAR(MAX) NULL;
```

Two MJ subsystems want incompatible things from the same column, and neither knows about the other:

- The **schema builder** maps a field declared `integer` with no length to `NVARCHAR(MAX)`. Read the ALTER
  batch and the rule is exact: every `integer` field goes to `NVARCHAR(MAX)` (`Groups.courseid`,
  `Groups.descriptionformat`, `Users.suspended/mailformat/firstaccess/lastaccess/confirmed`), every unsized
  `string` field goes to `NVARCHAR(812)`.
- **CodeGen** reads the soft FKs in `additionalSchemaInfo` and creates `IDX_AUTO_MJ_FKEY_<table>_<column>` on
  each FK column. SQL Server cannot put an `NVARCHAR(MAX)` column in an index key.

So the first ApplyAll after CodeGen has created those indexes fails, and fails identically on every retry.
Seven such indexes existed on this schema — `Groups.courseid`, `Groupings.courseid`, `Notes.courseid`,
`Notes.userid`, `Messages.useridfrom`, `Messages.useridto`, `User_Badges.courseid` — and every one of those
columns is declared `integer` in the catalog. This is a fleet-level SQL Server hazard, not a Totara quirk:
any connector that declares an integer field and a soft FK on it arms the same trap.

**The engine already knows how to do this correctly for primary keys, which is what makes it a defect rather
than a limitation.** `Enrolled Users.courseid` is declared `integer` too, but it is part of the primary key,
and its column is `NVARCHAR(812)` — sized, and therefore indexable. The sizing rule that keeps a PK usable is
simply not applied to a column an index is about to be built on.

**Fix should:** size a declared-integer column whenever anything will index it — the same treatment a PK
column already gets — rather than defaulting it to `MAX`. Failing that, the FK-index step and the column-type
step must at least agree, so a tenant is never left with a pipeline that cannot succeed.

**What set it off, stated plainly:** the two objects in that ALTER batch are `Groups` and `Users` — exactly the
two this session's delta migrations touched (`V202608050400` group parent-scope, `V202608041327` Users id-window).
Changing an object's `Configuration` marks it dirty, the builder re-diffs it, and the re-diff surfaces a type
drift that has been sitting in the table since it was created: the columns are `NVARCHAR(255)` and current
policy wants `NVARCHAR(812)`/`MAX`. Neither migration changed a field, a type, or an FK. So these changes are
the **detonator, not the cause** — the mine is the drift plus the index, and the next `Configuration` edit to
any object on any connector treads on it the same way. The immediately preceding live run passed ApplyAll only
because it touched no dirty object.

Engine-side (`@memberjunction/integration-engine` / CodeGen), so it is recorded here rather than fixed here.
**Unblocked for proving only** by dropping the seven `IDX_AUTO_MJ_FKEY_*` indexes in the scratch DB
(`MJ_CT48`); CodeGen recreates them, at which point the trap re-arms. Nothing in this connector can avoid it
while a declared `integer` means `MAX`.

Already-generated files are audited too, not only newly converted ones — a bad file committed before
this guard existed must not stay invisible merely because it is not new. Both `pr.yml` and `release.yml`
already run `--check`, so this is enforced on every PR with no new CI wiring.

The escape hatch is unchanged and now named in the failure message: delete the generated file and
hand-author the `.pg.sql` with the jsonb body, as `UsersIdWindowScan` does.

---

## 7. `Enrolled Users` — the healthy vendor cost is ~1.8 h per full pull; the 8.6 h run was mostly a broken deadline

Live read-only run `9200B480` ran **8.6 hours** on this object alone and did not finish: 208 fetch batches,
**50,608 records fetched**, **29,002 rows** in `totara.Enrolled_Users`, **64 of 428 courses** covered.

**The first version of this item said the vendor is simply this slow, and that was wrong.** It rested on a single
per-record figure and the p50 of the batch durations, both of which look healthy — and stopped there. The run did
not go where p50 says it went. Split the 208 batches by duration:

| Batches | Records | Fetch time | Per record |
|---|---|---|---|
| 193 healthy | 48,720 (96.3%) | 0.92 h | **68 ms** |
| 15 pathological | 1,888 (3.7%) | 3.30 h | **6,296 ms** |

**3.7% of the records consumed 78% of the fetch time**, and at wall-clock level 31 of the 207 cycles ate **84%** of
the run. The largest single batch was **1,063,987 ms against a 20,000 ms budget** — 53× the deadline the connector
believed it was enforcing. That is not a vendor throughput limit, it is two connector defects, both now fixed:
`ctx.RateLimitAcquire()` was awaited outside the timer with no clock re-check after it, so a throttled walk had no
deadline at all; and 24 requests aborted on the 25,000 ms read timeout each *retired* a course whose enrolments
were unread. See `.changeset/totara-parent-walk-deadline-and-transient-retry.md`.

**Measured, from the run log:**

| Quantity | Value | How it was measured |
|---|---|---|
| Wall clock | 30,972 s (8.6 h) | first `sync.fetch.batch.start` → last `…complete` |
| Fetch time | 15,207 s (49%) | sum of `durationMs` |
| Persist time | 15,766 s (51%) | sum of gaps between a batch completing and the next starting |
| Batch fetch, p50 / p90 / max | 17,438 / 19,702 / **1,063,987** ms | `durationMs` percentiles — p50 is inside budget and tells you nothing about where the run went |
| Requests aborted on the read deadline | 24, across 24 distinct courses at mostly shallow offsets | `did not respond within 25000ms` — intermittent vendor slowness, not a deep-offset effect |
| Page size | 50 records | `parentScope.pageSize` |
| **Healthy per-record vendor cost** | **~68 ms** | 193 batches, and it is **linear in rows** — the code's own earlier live note measured ~26 s for a 250-row page |

**What a full pull actually costs.** The whole site is ≈**93,000 enrolment rows** (17,937 for the site course plus
~176 × 428 for the rest), so ~3.2× what has been read so far. At the healthy 68 ms/record that is **≈1.8 hours of
vendor time**, not the ~4 h this item previously claimed — that figure came from scaling 29,002 rows by 428/64
courses, which double-counts the already-completed site course.

Per-record cost is linear, so enlarging the page does not reduce *vendor* time: five 50-row requests and one
250-row request cost the same ~17 s, which is also why the 20000ms budget fits about 250 records however it is
sliced. It does change something else, though, and the earlier "enlarging the page buys nothing" overstated it:
fewer, larger requests mean fewer independent chances to hit the intermittent stall above, at the cost of losing
more work when one does. That is a real trade-off on this endpoint rather than a no-op, and it is left alone for
now because the deadline fix addresses the stall directly.

**Why each record is that expensive:** `core_enrol_get_enrolled_users` returns a full user profile per
*enrolment*, and this catalog declares all 29 of those fields — including `groups`, `roles`, `preferences`,
`customfields` and `enrolledcourses`, each of which is its own sub-query per user. `enrolledcourses` is
particularly circular here: this object **is** the enrolment table, so every row carries a list of the rows
around it.

**Why the first hours look like nothing is happening:** **course `1` is the site course**, which in Moodle/Totara
every user on the site is enrolled in — ~24,711 enrolments. Parent ids sort as strings, so `"1"` is walked first,
and **17,937 of the 29,002 rows landed (62%) are that one course**. A watcher sees hours pass and one `courseid`
in the table. Nothing in the connector recognises that a single parent can be the entire site.

**Fix should:** send `options.userfields` limited to the fields actually wanted, which Totara documents on this
function precisely for this reason. **This is deliberately not done here**, because it drops declared columns —
`groups`/`roles`/`preferences`/`customfields`/`enrolledcourses` would stop arriving, and that is a catalog
decision with a customer-visible consequence, not a connector optimisation. The mechanism is one metadata key
away (the same shape `orderingParams` uses); what is needed first is a decision about which of the 29 fields an
enrolment row is actually for. Trimming to the identity plus the profile scalars would cut the payload by roughly
the aggregate sub-queries' share, which is where the 68 ms lives.

**Also worth a product decision, separately:** whether the site course belongs in an enrolment sync at all. It is
62% of the rows and it duplicates the user table.

The same arithmetic bounds `Group Members` (item 2c): its chain costs one request per course just to learn the
group ids, and 84–92 of 428 courses is as far as one budget reaches.
