---
'@memberjunction/connector-openwater': patch
---

Make a detail walk survivable, and make its zeros say what was actually there

Once the door paged properly, three defects that the one-page cap had been hiding all surfaced in
the same run — and every one of them ended in a *successful* batch that was wrong.

**1. The declared field-value segment did not exist.** `ApplicationFile` and `Media` descended
`roundSubmissions[] -> fieldValues[]`. The payload names that array `submissionFieldValues`. The
walk paged the door to 1,976 rows, fetched every parent detail, descended into a key that is absent,
and reported success with zero records: ApplicationFile 0 of 4,001, Media 0 of 4,001. The segment
was taken from vendor documentation rather than an observed response — the thing the catalog rule
("provably know, not guessed") exists to prevent. Corrected in the metadata and in a delta
migration (`V202608230150`), so an already-seeded tenant is repaired rather than only new ones.

**2. A zero could not be told from a wrong path.** `ZERO_LEAVES`/`ZERO_PARENTS` said nothing
matched, which is the same message for "this tenant has no files" and "the declared key is
misspelled" — opposite problems. Both paths now attach the shape actually present at each declared
segment (`HARVEST_SHAPE`, `NESTING_SHAPE`): key **names and types only**, capped, so no member data
is ever emitted. That diagnostic is what identified defect 1, in one run.

**3. The walk bounded records emitted, not vendor calls made.** `ctx.BatchSize` (engine default
200) stops the walk when enough *records* accumulate. A sparse child — most Applications carry no
files — never reaches it, so the walk kept going to the end of the parent set: ~1,976 detail
requests inside one `FetchChanges`, well past the engine's 30s timeout, and on timeout the entire
batch is discarded. Live, the moment the door began paging: ApplicationFile, Media and
ApplicationRoundSubmission all died with `Operation 'FetchChanges(X)' timed out after 30000ms`.
Parents (and harvest door rows) are now bounded at 100 per call and the walk yields its cursor, so
each call finishes and the engine simply calls again.

**4. Re-enumerating the door on every resumed batch drew a rate limit.** A resumed call re-read the
door from page 0 — ~20 pages of 100 — before touching a single parent; measured live as
`HTTP 429 at /v2/Applications?pageIndex=4&pageSize=100`, which then threw, discarding the four pages
already in hand and taking the object to zero. Door enumerations are now cached per
(integration, door, path) for resumed calls (a fresh walk still re-reads, so new parents appear),
a mid-enumeration 429 keeps the pages it has and reports `HasMore` (`RATE_LIMITED_PARTIAL`), and a
truncated enumeration is **never cached** and leaves the object incomplete (`DOOR_TRUNCATED`) so it
cannot be mistaken for the whole parent set.

Also adds `DOOR_ROWS`, which reports each door's row count and the pagination rules actually applied
— counts and flags only. A capped door is otherwise invisible: the walk consumes every parent it was
given and truthfully reports `HasMore: false`, so a short door reads as a complete one. That is the
shape of every bug in this path, and it is now visible from the run's own events.
