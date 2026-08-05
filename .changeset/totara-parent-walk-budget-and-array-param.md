---
'@memberjunction/connector-totara': patch
---

Totara: the two remaining objects that landed **zero rows behind a green run** now sync.

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

Bounding the call was necessary and **not sufficient**, which is the part worth carrying elsewhere: *a
per-call deadline cannot rescue a single request that is itself too big.* The first parent of a call must
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
