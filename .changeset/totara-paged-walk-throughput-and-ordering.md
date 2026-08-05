---
'@memberjunction/connector-totara': patch
---

`Enrolled Users` re-read 44% of what it fetched, and its offset pages had no defined boundary.

Live read-only run `9200B480` against the client site ran for 8.6 hours over 208 fetch batches, fetched **50,608
records**, and produced **29,002 distinct keyed rows** — a 1.74x re-read — with only 3 INSERT and 18 UPDATE run
details logged. Everything else was a content-hash skip of a row already present. Three separate causes, two of
them defects in this connector.

**1. The concurrent resume threw away every lane but one (fixed).** The keyset cursor can name exactly one
mid-parent resume offset, and only for the parent at the head of the covered prefix — pointing it anywhere else
would claim a budget-skipped parent as done. With `MaxConcurrency: 2` the walk read two courses at once, the
20000ms budget stopped both mid-way, and only the head course's offset survived. The second lane restarted from
offset 0 on the next call, every call, forever. Its records were kept (upserts are idempotent) so nothing was
lost or wrong — it was pure repeated work, and it is essentially all of the 1.74x. A **paged** parent walk now
runs one parent at a time whatever concurrency the engine offers. Unpaged walks keep full concurrency: one
request per parent either finishes or errors, so there is no partial progress to lose.

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
`core_enrol_get_enrolled_users` returns a full user profile per enrolment, measured at **~68 ms per record** and
linear in rows, so enlarging the page buys nothing. Two facts make that expensive here — the catalog declares all
29 profile fields including the `groups`/`roles`/`preferences`/`enrolledcourses` aggregates, each its own
sub-query, and **course `1` is the site course that every user is enrolled in** (17,937 of the 29,002 rows
landed, sorted first, so it is walked first). Totara documents `options.userfields` to trim the payload, but
trimming drops declared columns, so it is written up in `docs/REQUIRED-FIXES.md` item 7 with the measured numbers
rather than applied silently.

Six regression tests cover the three fixes (64/64 in `TotaraConnector.test.ts`).
