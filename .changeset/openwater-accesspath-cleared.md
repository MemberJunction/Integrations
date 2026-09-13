---
'@memberjunction/connector-openwater': patch
---

Five objects have had their AccessPath discarded since creation, so they could never fetch.

Their create calls supplied the access path and cleared it in the same breath:

    p_Configuration := '{"AccessPath":{ ... }}', p_Configuration_Clear := TRUE

`_Clear := TRUE` sets the column to NULL. It is emitted for every nullable parameter and is correct
beside `p_Category := NULL, p_Category_Clear := TRUE` — but passed beside a real value it throws that
value away. The call succeeds, the object is created, `Configuration` is NULL. Both dialects: the
T-SQL twins pass the same flag, which is why `ApplicationFile`, `ApplicationRoundSubmission`,
`ApplicationWinnerType`, `Judge` and `Media` appear in no proving table on any environment.

`FetchChanges` calls `ParseAccessPath(obj)`, which reads `Configuration`. NULL means no access path,
so the parent walk is never entered and the fetch falls through to `FetchDoor`, which requests
`obj.APIPath` literally. For these objects `APIPath` is a **description**, not a URL. Live on run
`f00743e7` (2026-09-13):

```
ApplicationWinnerType       Failed to parse URL from https://api.secure-platform.com(embedded in /v2/Programs rounds[].winnerTypes[])
ApplicationRoundSubmission  Failed to parse URL from https://api.secure-platform.com(embedded in /v2/Applications/{applicationId} roundSubmissions[])
ApplicationFile             Failed to parse URL from https://api.secure-platform.com(embedded in ... submissionFieldValues[])
Media                       HTTP 404 at /v2/Media/{mediaId}                    — the template was never filled
Judge                       HTTP 500 at /v2/JudgeAssignments/AssignedToRound   — roundId was never attached
```

Each held its watermark and retried, so none could ever advance. Every object that *has* its
AccessPath walks correctly on the same run — `Report` landed 69 rows, `ScheduleDay` walked 5
`programId` values cleanly, `FundTransaction` reached its door and found a genuine 401.

**The connector code is correct.** `FetchViaAccessPath` implements `embedded-array`, `detail-embedded`
and `detail-object`. It was never reached.

A new migration restores the five configurations, with the refinements two later migrations intended
but could never apply — `fieldValues[]` → `submissionFieldValues[]` and the `embeddedParentTag` form.
Those statements were no-ops twice over: `REPLACE()` on NULL returns NULL, and
`Configuration NOT LIKE '%…%'` evaluates to NULL rather than true when Configuration is NULL, so the
row never matched. Applied migrations are not edited — Flyway validates their checksums — and the
repair only touches a row whose Configuration lacks an AccessPath.

`scripts/lint-migration-value-then-clear.mjs` fails CI on any parameter given a value and cleared in
the same call. Nothing in review catches this otherwise: the JSON sits in the diff a few hundred
characters before the flag that discards it.
