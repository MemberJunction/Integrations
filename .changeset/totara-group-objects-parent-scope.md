---
'@memberjunction/connector-totara': patch
---

`Groups`, `Groupings` and `Group Members` were dispatched with no parent scope, so all three were unfetchable.

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
