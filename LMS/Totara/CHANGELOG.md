# @memberjunction/connector-totara

## 0.3.0

### Minor Changes

- d495a0c: Fix Totara `Users` syncing **zero rows behind a green run**, and ship the paired dialect migrations that carry the fix to installed tenants.

  **The defect.** `core_user_get_users` declares no pagination params, and the vendor documentation is explicit that it is not a list function: _"You can search without criteria, but the function is not designed for it. It could [be] very slow or timeout. The function is designed to search some specific users."_ — and of the wildcard the catalog used, _"you can use % for searching but it may be considerably slower!"_. The seeded Configuration asked for exactly that: `criteria[0][key]=email, criteria[0][value]=%`, i.e. every user in one response. Against a real-sized site the server cannot build that inside the engine's `FetchChangesMs` budget, so the batch is killed and the object persists **0 records while its entity map still reports success**. Observed live against a production LMS (read-only): 3× 30000ms timeouts, 0 users, on a tenant with thousands of them — the failure presents as "this site has no people", not as a fetch error.

  **The fix.** `Users` reads now route through a bounded **id-window scan** against the documented bulk reader `core_user_get_users_by_field` (`field=id`, `values[]`) — an indexed primary-key lookup rather than a search. Every request is bounded by construction, so no single call can exceed the fetch budget, and the scan resumes across `FetchChanges` calls through the engine's keyset channel (`AfterKeyValue`), never re-reading from id 1.

  Declared per-object via `Configuration.idWindowScan` (`wsFunction`, `field`, `windowSize`, `windowsPerCall`, `maxConsecutiveEmptyWindows`), so the mechanism is reusable by any object whose list function cannot be bulk-listed. `defaultArgs` is retained untouched as the legacy fallback when `idWindowScan` is absent.

  **The call bounds itself in time, not just each request.** The engine kills a `FetchChanges` that overruns `FetchChangesMs` (30s) and a killed batch persists **nothing**, so bounding each request was not enough — several bounded windows in one call still overran the budget together and died with 0 records, exactly like the original defect. The scan now carries a `budgetMs` deadline (default 20000, under the kill): it stops issuing windows at the deadline and returns what it scanned plus its cursor, emitting `ID_WINDOW_BUDGET_STOP` so a short batch is never mistaken for a thin id range. At least one window is always attempted, so the cursor can never stall.

  **One unreadable record costs one record, not the object.** Moodle/Totara validate their own response per record: a single user row that fails that validation fails the entire call with `[invalidresponse]`, however many good rows it contained. Observed live: every id window failed that way, and since a failed window is (correctly) not treated as an empty one, the cursor never advanced — the scan re-requested the same window for the life of the run. A failed window is therefore **bisected** down to single ids; everything readable is kept, and an id that still fails alone (after one retry, so a transient blip is not mistaken for a bad record) is skipped with an `ID_WINDOW_RECORD_SKIPPED` warning naming the exact id. Skipped ids never count toward the past-the-end heuristic, and bisection is bounded per call by `maxBisectSplitsPerCall` (default 8) so one pathological window cannot consume a whole call.

  **The shipped window values are the ones proven live, not chosen on paper.** `windowSize:25, windowsPerCall:2` reads 50 users in ~2.5s — an order of magnitude inside the 30s kill even when a window has to be bisected to isolate an unreadable id (25 → 12 → 6 → 3 → 2 → 1 is 5 splits, under the default 8). Wider was tried first and failed against the live site in exactly the two ways the guards now catch: `200 × 5` overran the budget and was killed with 0 records, and a 200-wide window containing one unreadable id could not finish its bisection inside the budget at all. `maxConsecutiveEmptyWindows:40` tolerates a 1,000-id gap of deleted users before the scan concludes it is past the end.

  **Coverage is not traded for speed.** Windows are contiguous, so coverage is complete over the range scanned. The scan stops after `maxConsecutiveEmptyWindows` consecutive empty windows — a heuristic for "past the end of the table" — and stopping **always** emits an `ID_WINDOW_SCAN_END` warning carrying the exact range scanned and the highest id seen, so a premature stop is visible in the run instead of silently truncating the object. A window that _errors_ is explicitly not counted as an empty one: it halts the fold and is retried on the next call, so a transient blip can never trip the stop heuristic and drop every user past it.

  Ships with `V202608041327__totara__UsersIdWindowScan.sql` and its PG twin. Both are delta updates keyed by `WHERE` (no IDs minted, no rows created) and idempotent — re-running is a no-op once `$.idWindowScan` is present. The PG body is hand-authored: the SQL Server source uses `JSON_MODIFY`/`JSON_QUERY`/`ISJSON`, which the conversion pipeline emits as quoted identifiers for functions that do not exist in PostgreSQL, so the auto-converted migration would have failed on every PG tenant.

### Patch Changes

- d495a0c: Both connectors now hold a read deadline that a stalled vendor cannot slip past.

  A vendor that accepts the connection and then goes quiet is the failure mode with no artifact: it is not a
  failed run, it produces no error, and it writes nothing anyone can read. It was observed twice on Totara as
  wedged worker processes that had to be killed from outside the system. Two different bugs, same shape.

  **Totara had no deadline at all.** `MakeHTTPRequest` called bare `fetch` with no signal, so a silent site
  hung the fetch forever. It now passes `AbortSignal.timeout` with a deadline resolved once at `Authenticate`
  — default **25000ms**, deliberately under the engine's `FetchChangesMs = 30000` kill so the connector
  reports the failure itself instead of being killed mid-batch and persisting nothing. An abort is translated
  into an ordinary error naming the function and the deadline (`core_enrol_get_enrolled_users did not respond
within 25000ms`), so the engine retries it like any other transport failure and the run artifact records
  why. Non-abort errors are re-thrown untouched — a refused connection must not be relabelled as a timeout.
  Override per connection with `requestTimeoutMs` in `CompanyIntegration.Configuration`; `0` opts out, for a
  site whose functions are legitimately slower than any sane default.

  **OpenWater had a deadline that disarmed itself at the worst moment.** It paired an `AbortController` with
  `clearTimeout` in a `finally` around the `fetch` call — but `fetch` resolves when the **headers** arrive,
  and the body is read afterwards in `BuildRESTResponse`. The timer was therefore cleared at exactly the
  instant the response body began streaming, so a vendor that answered with headers and then stalled mid-body
  hung indefinitely regardless of the configured timeout. Replaced with `AbortSignal.timeout`, which stays
  armed for the life of the signal, body stream included, and needs no manual teardown. A fresh signal per
  attempt is correct and is now pinned by a test — retries must not share one expiring deadline.

  Six unit tests across the two: signal present, abort translated and named, non-abort passed through, `0`
  opts out, the signal still armed after headers arrive, and one deadline per retry attempt.

- d495a0c: New shared helper `@memberjunction/connector-id-window-scan`, and Totara's id-window scan moves into it.

  **Why it is shared.** The failure it solves is not Totara's. An object declared with no pagination is read in
  one request; on a large tenant that request cannot finish inside the engine's `FetchChangesMs` (30000ms), the
  batch is killed, and **a killed batch persists nothing** — the object lands zero rows while its entity map
  reports success. `node scripts/audit-unlistable-objects.mjs` finds **765** one-shot readers across the fleet
  today, **235** of them named like tables whose size tracks the tenant's size. Every one of those is the same
  bet Totara `Users` lost, and none of them should have to rediscover the three non-obvious parts of the fix:

  - **The call bounds itself in time, not just each request.** Several bounded windows in one call can overrun
    the budget together and be killed with nothing — the original defect wearing a different hat. `budgetMs`
    (default 20000, under the kill) stops the call and returns partial progress with its cursor
    (`ID_WINDOW_BUDGET_STOP`).
  - **One unreadable record costs one record, not the object.** Where a vendor validates its own response per
    record, a single bad row fails the whole call — and since a failed window (correctly) is not an empty one,
    the cursor cannot advance and the scan re-requests it forever (observed live: 61 identical failures, 0 rows).
    Failed windows are bisected to single ids; an id that fails alone is skipped with `ID_WINDOW_RECORD_SKIPPED`
    naming it.
  - **Coverage is never traded for speed.** The cursor advances only over ids actually examined, and stopping on
    the past-the-end heuristic always emits `ID_WINDOW_SCAN_END` with the range covered.

  The helper is vendor-agnostic — it knows nothing about HTTP, auth, or record shape. A connector supplies
  `FetchWindow(ids)` (which must THROW on vendor errors, since that is the signal bisection reads) and maps the
  raw rows it gets back. Following the `connector-schema-merge` precedent: one function, no class, no base —
  connectors import it, they do not extend anything new.

  **Bug fixed in the move: `ID_WINDOW_SCAN_END` always reported `highestIdSeen: 0`.** The value was tracked per
  call, but the call that ENDS a scan is by construction the all-empty one — so the field read 0 on exactly the
  warning that needs it (observed live reporting `highestIdSeen: 0` immediately after landing 24,682 users). It
  now rides the resume cursor, which gains a third part: `"<nextStartId>|<emptyRun>|<highestIdSeen>"`. Two-part
  cursors written by an older build still parse, so an in-flight scan resumes rather than restarting.

  Totara keeps its behaviour exactly — it now supplies only the Moodle-specific "turn these ids into one RPC
  call" and the record mapping — and sheds ~200 lines. Verified live read-only against a production LMS after
  the refactor.

- d495a0c: `Enrolled Users` was keyed on the user id alone, so enrolments silently overwrote each other.

  `core_enrol_get_enrolled_users` is read **per course** — the object is parent-scoped over
  `core_course_get_courses`. A user enrolled in several courses therefore comes back once per course, each
  time carrying _that course's_ roles and groups. The catalog declared one key field, `id` ("ID of the
  user"), marked `IsUniqueKey=1`. Every per-course row upserted onto the same key, so the last course
  written won and the earlier ones were destroyed on the way in.

  Live evidence (production site, read-only, run `5E8070E2`): **26,300 records processed, 13,950 rows landed**, and
  across every course the walk reached, only **2 distinct `courseid` values survived** in the table. Nothing
  errored, nothing warned — the run was green and the object looked populated, which is why this sat behind
  the fetch defects that were fixed first. It is the same family as those: not a failure, an untruth.

  The sibling objects are the control group, and they make the diagnosis exact. `Course Contents` is walked
  by the same parent mechanism in the same run and landed **2,504 rows across 408 distinct courses** — course
  attribution fully intact — because its `id` is a per-record section id. `Enrolled Users` landed 13,950 rows
  across **2**. Same walk, same run, same budget; the only difference is that its `id` identifies the _user_,
  which recurs. Every other `parentScope` object in the catalog was swept for the same shape and is clean, so
  this was the one instance, not the first of many.

  The object's own metadata had the right answer written down the whole time, in
  `writeFunctions.createResponseNote`: _"identity is the composite (userid,courseid)"_. And the write surface
  makes the stakes concrete — `enrol_manual_unenrol_users` is wired as DELETE, and a delete keyed on user id
  alone does not name the course it is unenrolling from.

  Fixed in the metadata and shipped to tenants as a delta migration (both dialects), in four parts:
  `parentScope.childIdField='courseid'` so the parent-id stamp is intentional rather than an accident of
  `paramName` happening to be a sensible column name; `id` demoted to `IsUniqueKey=0`, which it always was in
  fact; and `courseid` declared as a second `IsPrimaryKey` field FK'd to `Courses`. A two-field key is the
  established shape here, not a novelty — 38 objects in the catalog already use one, including HubSpot's
  association objects, which are the same join shape and likewise `IsPrimaryKey=1 / IsUniqueKey=0` on both
  halves.

  **The migration has two create paths, and the interesting one is the promote.** On any tenant that has
  synced this object even once, discovery had _already_ created a `courseid` field — as
  `IsCustom=1 / MetadataSource='Discovered'`, `IsPrimaryKey=0`, and wrongly `IsUniqueKey=1`. An INSERT-only
  migration would have found the row present, no-opped, and changed nothing on exactly the tenants carrying
  the defect. Both branches were exercised against a live catalog: the promote on the discovered row, then
  the row deleted and the create path run to rebuild it through `spCreateIntegrationObjectField` (the same
  entry point the seed uses for the other 269 fields, so audit columns are the sproc's business and not
  hand-written). Re-running touches zero rows.

  **Operators:** this widens the key of an existing synced table. The collapsed rows cannot be recovered —
  the overwritten enrolments were never stored — so the object needs one full, non-incremental pull after the
  migration to repopulate the per-course rows.

- d495a0c: `Groups`, `Groupings` and `Group Members` were dispatched with no parent scope, so all three were unfetchable.

  Each declared a **by-id reader** as its list function — `core_group_get_groups(groupids[])`,
  `core_group_get_groupings(groupingids[])`, `core_group_get_group_members(groupids[])`. A by-id reader answers
  with the records you already name; dispatched bare, as these shipped, Moodle replies `[invalidparameter]` and
  the object lands 0 rows on every run. It is the identical defect `Cohort Members` had, which is fixed and
  proven live at 97 rows.

  Moodle does not offer the same escape from each, so the fix is not uniform:

  - **`Groups` / `Groupings`** — nothing lists a site's groups or groupings. The only enumerators are per-course
    (`core_group_get_course_groups` / `core_group_get_course_groupings`), and they return the full record rather
    than just an id. So the read function becomes the per-course enumerator and the object is parent-scoped over
    `core_course_get_courses` — one hop, the same shape as `Course Contents`. Write functions are untouched.
  - **`Group Members`** — its function takes group ids, and by the above nothing enumerates those site-wide, so
    naming a single id takes **two** hops: `core_course_get_courses` → `core_group_get_course_groups(courseid)`
    → group ids → members.

  Two hops is what the single-level `parentScope` could not model, and that gap is why these objects were left
  declared-but-broken. `parentScope` now nests: a `parentScope` inside a `parentScope` describes how to obtain
  the inputs for the level above it, so every level reads exactly like the top one and depth is arbitrary. The
  connector resolves the chain recursively.

  The expansion is paid for out of the **same wall-clock budget** as the walk, because it costs one request per
  id at each hop — a 408-course site spends 408 requests just to learn the group ids, and spending them
  unbudgeted inside the engine's 30000ms `FetchChangesMs` kill is how `Enrolled Users` used to land nothing. A
  chain cut short by the budget returns what it resolved, emits `PARENT_CHAIN_TRUNCATED`, and is **not cached** —
  caching a partial list would freeze that short view for the whole cache window and make an incomplete run look
  complete. An upstream hop that errors (a course whose groups the token cannot read) costs only its own ids,
  never the enumeration.

  **Proven live — and the earlier "all three are `[accessexception]`" was wrong.** Read-only runs on the production
  site (`9200B480`, `DE595754`), read back out of `MJ_CT48`:

  - **`Groups` — 201 rows.** Walked per-course in batches of 17, 9, 8, 10, 10, 8, 9, 11, 4, 5, 1, 4, 5, 0, 0, 2:
    201 processed, 201 created, **0 errors**. `totara.Groups` holds 201 rows. The per-course enumerator is right and
    the one-hop scope is right.
  - **`Groupings` — a legitimate zero.** 0 records and 0 errors across ~41 per-course batches, with no
    `[invalidparameter]` anywhere. The requests succeed; this site has no groupings.
  - **`Group Members` — the chain works; the token does not have the function.** 52 batches, the two-hop chain
    resolved **84–92 group ids per call** and dispatched them correctly (`groupids=229`), and Totara answered
    `[accessexception]` to every single one. 0 records, 0 rows, and the engine stopped on
    `CONSECUTIVE_EMPTY_BATCHES`. So the part that was in doubt — that two hops can name a group id at all — is
    proven; what remains is a credential scope limit on `core_group_get_group_members`, not a defect. That refusal
    is now attributed once as `LEAF_FORBIDDEN` rather than 52 times as a fetch error (see
    `totara-paged-walk-throughput-and-ordering`).

  `PARENT_CHAIN_TRUNCATED` also fired on every `Group Members` call: enumerating group ids costs one request per
  course, and 84–92 of 428 courses is as far as the 20000ms budget reaches, so the chain is re-enumerated (uncached,
  deliberately) each call. Coverage is not lost, but a site with a readable token would need many calls to cover
  every group — recorded in `docs/REQUIRED-FIXES.md` item 7 alongside the other walk-throughput arithmetic.

  Shipped to tenants as delta migration `V202608050400__totara__GroupObjectsParentScope` (+ hand-authored
  `.pg.sql` twin), verified against a live catalog: 3 rows changed on first apply, 0 on re-apply.

- d495a0c: `Enrolled Users` re-read 44% of what it fetched, and its offset pages had no defined boundary.

  Live read-only run `9200B480` against a production site ran for 8.6 hours over 208 fetch batches, fetched **50,608
  records**, and produced **29,002 distinct keyed rows** — a 1.74x re-read — with only 3 INSERT and 18 UPDATE run
  details logged. Everything else was a content-hash skip of a row already present. Three separate causes, two of
  them defects in this connector.

  **1. The concurrent resume threw away every lane but one (fixed).** The keyset cursor can name exactly one
  mid-parent resume offset, and only for the parent at the head of the covered prefix — pointing it anywhere else
  would claim a budget-skipped parent as done. With `MaxConcurrency: 2` the walk read two courses at once, the
  20000ms budget stopped both mid-way, and only the head course's offset survived. The second lane restarted from
  offset 0 on the next call, every call, forever. Its records were kept (upserts are idempotent) so nothing was
  lost or wrong — it was pure repeated work, and it is essentially all of the 1.74x.

  The first fix here made **paged** parent walks serial, which removed the waste by removing the parallelism.
  `.changeset/totara-parent-walk-deadline-and-transient-retry.md`, in the same release, replaces it: the cursor
  carries an offset **per parent**, so no lane's progress can be discarded and paged walks keep the engine's
  concurrency. Unpaged walks were never affected — one request per parent either finishes or errors, so there is no
  partial progress to lose.

  **2. Offset paging sent no ORDER BY (fixed).** `limitfrom`/`limitnumber` is SQL `OFFSET`/`LIMIT`, and an offset
  over a result set with no `ORDER BY` has no defined page boundary — consecutive pages may repeat rows and, worse,
  may never return others at all. Overlap costs time; **the gaps are silent data loss behind a run that reports
  success.** Both halves of the fix already existed and nothing joined them: the catalog has declared
  `stableOrderingKey: "id"` on every object since it shipped, and Totara documents `sortby` +
  `sortdirection` as options on `core_enrol_get_enrolled_users`, listed beside `limitfrom`/`limitnumber`. A new
  `orderingParams` names the two option params so they can be sent; all four options share one bracket array, so
  ordering could not be bolted on by a second helper starting its own indexes. Objects declaring no
  `orderingParams` are unchanged — the option names are per-wsfunction and are read from the catalog, never
  guessed. Shipped as delta migration `V202608050900__totara__EnrolledUsersStableOrdering` (+ `.pg.sql` twin);
  1 row changed on first apply, 0 on re-apply.

  **3. A permission wall reported as N faults instead of one (fixed).** `core_group_get_group_members` answered
  `[accessexception]` for every group id on all 52 batches of run `DE595754`, and the walk reported 52
  `PARENT_FETCH_ERROR` warnings — reading like 52 separate faults when it is one credential that was never
  granted. `[accessexception]`/`[requiredcapability]`/`[nopermission]` are now attributed as `LEAF_FORBIDDEN`, the
  grain OpenWater already uses: **one** warning naming the wsfunction, the refused count and the vendor's words
  when everything reached was refused, and a distinct partial-refusal warning when only some were. A
  non-permission fault stays per-parent, because it genuinely is per-parent.

  **What is NOT fixed, and is a catalog decision rather than a bug.** The remaining cost is the vendor's:
  `core_enrol_get_enrolled_users` returns a full user profile per enrolment, measured at **~68 ms per record** on the
  193 healthy batches and linear in rows, so enlarging the page does not reduce vendor time. Two facts make that
  expensive here — the catalog declares all
  29 profile fields including the `groups`/`roles`/`preferences`/`enrolledcourses` aggregates, each its own
  sub-query, and **course `1` is the site course that every user is enrolled in** (17,937 of the 29,002 rows
  landed, sorted first, so it is walked first). Totara documents `options.userfields` to trim the payload, but
  trimming drops declared columns, so it is written up in `docs/REQUIRED-FIXES.md` item 7 with the measured numbers
  rather than applied silently.

  Six regression tests cover the three fixes (64/64 in `TotaraConnector.test.ts`).

- d495a0c: Totara: the two remaining objects that landed **zero rows behind a green run** now sync.

  Both were live failures on a production site, not code review findings, and both are the same product-level
  bug class as the Users defect — an object that reports success while persisting nothing.

  **`Cohort Members` was asking the vendor an invalid question, on every run since it shipped.**
  `core_cohort_get_cohort_members` requires the cohorts to read, as an ARRAY (`cohortids[0]=7`); the object
  declared no parent scope, so the connector dispatched the function bare and Totara answered
  `[invalidparameter] Invalid parameter value detected` at batch 1, identically every time. It is now
  parent-scoped over `core_cohort_get_cohorts` (which, unlike the members function, treats its ids as optional
  and lists them all). Two shape facts the walk did not previously model, and a unit test pins each:

  - `paramStyle: 'array'` — Moodle's plural-id functions reject the scalar form. This is the actual
    `[invalidparameter]`, and nothing about the error message says so.
  - `childIdField` — the row's parent FK is SINGULAR (`cohortid`) while the request param is plural
    (`cohortids`). Tagging with the param name would invent a field matching no declared field and leave the
    real FK null.

  **`Enrolled Users` was being killed mid-walk and losing everything it had already fetched.**
  It walks one request per course, and a page cap of N parents says nothing about how long N vendor calls
  take: the engine kills a `FetchChanges` that overruns `FetchChangesMs` (30000) and **a killed batch persists
  nothing**, so it timed out 3x and landed 0 records while its entity map reported success. The walk is now
  bounded in TIME as well as in count (`parentScope.budgetMs`, default 20000, under the kill), returning
  partial rows plus a cursor and a `PARENT_BUDGET_STOP` warning instead of dying with them.

  Bounding the call was necessary and **not sufficient**, which is the part worth carrying elsewhere: _a
  per-call deadline cannot rescue a single request that is itself too big._ The first parent of a call must
  always run, so a course whose one request exceeds the budget times out however the walk is scheduled. Three
  further changes, each driven by a measurement rather than a reading of the code:

  - **The walk pages WITHIN a parent.** `core_enrol_get_enrolled_users` documents `options.limitfrom` /
    `options.limitnumber` — already declared in this object's `paginationParams` and, until now, ignored on the
    parent-scoped path, so every call asked for a whole course at once. `parentScope.pageSize` now bounds each
    request by construction, and a budget stop between pages resumes INTO the parent through a
    `"<courseid>#<offset>"` cursor instead of re-reading its first page forever. pageSize is **50**, measured:
    a 250-user page took **25823ms** live (~10 users/sec — the function builds full user profiles).
  - **The deadline is enforced against work ABOUT TO START.** `elapsed >= budget` will happily dispatch a
    request that lands 26s past it, so the walk stops when `elapsed + slowestRequestSoFar >= budget`. The clock
    starts at method entry, not at the walk, because the engine's timer starts where `FetchChanges` does — and
    the parent-list call is inside it.
  - **The parent-id list is cached** (`parentScope.parentCacheMs`, default 5 min). `core_course_get_courses`
    measured **6147ms**; re-reading it on every resumed call spent a fifth of the budget before the walk began.

  Two properties make the stop safe, and each is a test:

  - **The cursor advances only over the contiguous PREFIX of parents actually examined.** Concurrency finishes
    out of order, so a parent past a budget-skipped one may well have completed; its records are kept (upserts
    are idempotent) but it is not claimed as covered. Claiming it would silently drop the skipped parent —
    which is data loss that no warning would report.
  - **The first parent of a call always runs**, even with the budget already spent. A call that skips every
    parent returns no rows with an unchanged cursor: the same call, forever.

  This is the parent-walk twin of the deadline discipline in `@memberjunction/connector-id-window-scan`, and
  the reason it is stated twice rather than shared once is that the two walk different spaces — an id range
  versus a parent list — with different resume channels. The rule they share is the one worth carrying to any
  connector: **bound the CALL, not just the request.**

- 2167484: The parent walk had no real deadline, retired courses it had failed to read, and could only resume one lane.

  Three defects in the same code path, found by splitting live read-only run `9200B480` (`Enrolled Users`, 8.6 h,
  208 batches, 50,608 records) by batch duration instead of trusting its percentiles. **193 healthy batches read
  48,720 records (96.3%) in 0.92 h at 68 ms/record; 15 pathological batches read 1,888 records (3.7%) in 3.30 h at
  6,296 ms/record.** So 3.7% of the records took 78% of the fetch time, and 31 of the 207 cycles took 84% of the
  wall clock. The p50 batch (17,438 ms) is inside budget and says nothing about where the run went. The run was not
  slow because the vendor is slow.

  **1. The rate-limit wait sat outside the deadline.** `await ctx.RateLimitAcquire()` was not passed through the
  step timer, so its wait never entered `slowestRequestMs`, and nothing re-checked the clock afterwards. A throttled
  walk therefore blew its own budget without bound: the engine measured single `Enrolled Users` calls at up to
  **1,063,987 ms against the 20,000 ms budget** the connector believed it was honouring — 53×, and well past the
  engine's own 30,000 ms `FetchChangesMs` kill, which discards the whole call. The acquire is now timed, and the
  request itself is gated on the budget rather than only the next loop turn. The one exemption is the first request
  of the first parent, which must always go out or the call makes no progress at all. A deadline that only sees the
  awaits it happens to wrap is not a deadline.

  **2. A transient failure retired its parent — silent data loss behind a green run.** Every caught error ended with
  `examined.add(index)`, which marks the parent "nothing left here" and lets the cursor advance past it. For a
  permission refusal that is right: the token will not be granted mid-run. For a 25,000 ms read timeout it is data
  loss. Run `9200B480` aborted **24 requests** that way, across 24 distinct courses at mostly shallow offsets
  (including `courseid=1 (offset 18850)`), each retiring a course whose enrolments had not been fully read — and the
  run reported success. Transport faults (read deadline, `ETIMEDOUT`/`ECONNRESET`/`ECONNREFUSED`/`EAI_AGAIN`, socket
  hang up, 5xx) now keep the parent's offset and count a consecutive-failure attempt on the cursor. The count is
  bounded by `parentScope.maxParentAttempts` (default 3) so this cannot become the opposite bug — the `Users`
  `[invalidresponse]` deadlock was 61 identical failures with no forward progress possible. On reaching the limit
  the parent is passed over with a new **`PARENT_ABANDONED`** warning that names the parents, states their records
  are not synced, and quotes the vendor. The walk never gives up quietly. Permission refusals still retire
  immediately, since retrying them costs budget and buys nothing.

  **3. The cursor now resumes every lane, so paged walks keep their concurrency.** The keyset cursor could name
  exactly one mid-parent offset, and only for the head of the covered prefix — pointing it anywhere else would claim
  a budget-skipped parent as done. That is what forced paged walks serial in
  `.changeset/totara-paged-walk-throughput-and-ordering.md`: it stopped the 1.74× re-read by removing the
  parallelism, a poor trade on an object whose healthy cost is 68 ms/record and which has never once been read to
  completion. The cursor gains an extended wire form — `{"a":"<id>","p":{"<id>":<offset>},"f":{"<id>":<n>}}`, with
  `a` the finished-through parent, `p` any parent's mid-parent offset and `f` its consecutive transient failures —
  and both legacy forms (`"<id>"`, `"<id>#<offset>"`) are still parsed, so an in-flight walk resumes rather than
  restarts. With every lane's progress durable, `parentConcurrency` is back to `ctx.MaxConcurrency`.

  Ordering of the cursor's guarantees is unchanged: it still advances only over the contiguous examined prefix, and
  state belonging to parents before that prefix is dropped rather than resuming into covered ground.

  Also corrected in this pass: `docs/REQUIRED-FIXES.md` item 7 claimed a full pull needs ~4 h of vendor time, from
  scaling 29,002 rows by 428/64 courses — which double-counts the already-complete site course. The site is ≈93,000
  enrolment rows, so **≈1.8 h** at the healthy rate. Its "enlarging the page buys nothing" was also too strong:
  larger pages do not reduce per-record vendor cost, but they do reduce how many independent chances a run takes on
  the intermittent stall above.

  Five regression tests, including the multi-lane cursor round trip and the transient-retry-then-abandon sequence
  (68/68 in `TotaraConnector.test.ts`).

- Updated dependencies [d495a0c]
- Updated dependencies [d495a0c]
  - @memberjunction/connector-id-window-scan@1.1.0

## 0.2.1

### Patch Changes

- 517466f: Fix silent record loss in NetForum + ORCID pagination, and declare the missing `connector-schema-merge` runtime dependency in HubSpot + Totara.

  **NetForum**: `FetchChanges` requested `@TOP -1` (the entire result set in one SOAP call) and hardcoded `HasMore: false`, so `BatchSize` was ignored and the computed `NextAfterKeyValue` was discarded. Now issues a `@TOP <BatchSize>` window with an `ORDER BY` on the stable ordering key, applies a `> AfterKeyValue` keyset predicate on resume, and reports `HasMore` from the page fill. Objects with no ordering key can't be paged safely, so they keep the single-call behavior and now emit an `UNPAGINATED_FETCH` warning instead of failing silently. `NewWatermarkValue` advances only on the final page.

  **ORCID**: `ResolveOrcidIdUniverse` sliced the resolved iD universe to `BatchSize` and returned `HasMore: false` — every iD past the first page was permanently discarded on every sync. The universe is now returned whole and sorted, windowed by `AfterKeyValue`, with `HasMore` + `NextAfterKeyValue` set so the scan completes across pages. Watermark advances only on the last page.

  **HubSpot / Totara**: both `import` `@memberjunction/connector-schema-merge` at runtime but declared it under `devDependencies`, which does not ship to consumers — the same `ERR_MODULE_NOT_FOUND` shape that leaves HubSpot broken on npm at 1.1.1. Moved to `dependencies`.

- 663676d: Fix two silent 0-row sync defects, each shipped with the paired dialect migration that carries the fix to installed tenants.

  **HubSpot — primary key is `hs_object_id`, not `id` (33 CRM objects).** The catalog declared `id` as the PK, but `DiscoverFields` declares — and the sync path populates — `hs_object_id`, read out of the properties bag. The top-level `id` column is never written. With `id` as the PK the generated `spCreate` ends with a read-back `SELECT ... WHERE [id] = @id`; `@id` is NULL, and in SQL `x = NULL` is never true, so the read-back matched zero rows, the create was treated as failed (`Error creating new record, no rows returned from SQL`), and every one of the 33 objects synced **0 rows — silently**, with no meaningful error surfaced.

  **Totara — parent-scoped `courseid` must be writable.** The parent-iteration fetch injects the parent FK `courseid` into each child record of the parent-scoped objects (Course Enrolment Methods, Grade Items, Course Grades Overview, User Badges), but those fields were seeded `IsReadOnly: true`. CodeGen omits read-only fields from the generated create/update stored procedures, so `@courseid` was never a sproc parameter and every save failed with `@courseid is not a parameter for procedure spCreateCourse_Contents` — **0 rows persisted despite a fully successful fetch**. Safe by construction: Totara is a read-only _pull_ connector, so `courseid` is written into MJ and never sent to the vendor.

  Both ship as **delta migrations, not re-seeds**: the existing seeds stay untouched and applied, so no applied UUID is re-minted, no applied migration is deleted, and there is no Flyway checksum break or `UQ_IntegrationObject_Name` collision on tenants already running these connectors. HubSpot's delta creates the 33 missing `hs_object_id` catalog rows (with stable UUID5-derived IDs, so the migration is reproducible byte-for-byte) and clears `IsPrimaryKey` on each object's `id`; Totara's is a guarded in-place `UPDATE`. Both have verified PostgreSQL twins.

- 3b9b36e: Give every writable object a primary key (or withdraw the write it cannot honor).

  A writable `MJ: Integration Object` with no `IsPrimaryKey` field derives a **keyless** entity. On
  Postgres the save audit-wrapper then emits an empty record identifier and every save fails with
  `syntax error at or near ","` — while fetch keeps succeeding, so the object reads green and persists
  nothing. Five objects across these three connectors were in that state.

  Each key is taken from the vendor's own schema, never invented:

  - **Stripe `cash_balance`** → `customer`. Stripe's `CashBalance` schema declares `customer` as a
    property of the object, and the resource is a singleton per customer
    (`/v1/customers/{customer}/cash_balance`, GET + POST only, no collection and no item id). It is
    returned in the payload, so the column is populated rather than null.
  - **Stripe `balance_settings`** → write withdrawn. `BalanceSettings` declares exactly two
    properties, `object` and `payments`; `/v1/balance_settings` takes no path variable because the
    account is implied by the API key. There is nothing to key on, and the object declared no
    create/update/delete operation either — the flag described a capability with no implementation.
    Reads are unaffected.
  - **Totara `Cohort Members`** → `cohortid`. `core_cohort_get_cohort_members` returns one row per
    **cohort** (`{cohortid, userids[]}`), so the cohort is the record identity.
  - **Totara `Group Members`** → `groupid`. `core_group_get_group_members` returns one row per
    **group** (`{groupid, userids[]}`), same shape; the field was already writable.
  - **Eventbrite `Media Upload`** → `upload_token`. Eventbrite's two-step media workflow issues the
    token from `GET /media/upload/` and it identifies the upload for the subsequent POST. It is the
    only identifier in the Media Upload MSON type and it is vendor-issued and returned.

  All three connectors are published, so each ships a **delta** migration (SQL Server + Postgres) that
  UPDATEs the existing catalog rows in place — no IDs minted, no rows created, idempotent by `WHERE`,
  and nothing can collide with an already-applied seed.

## 0.2.0

### Minor Changes

- e8c7693: Totara connector published as an Open App.
