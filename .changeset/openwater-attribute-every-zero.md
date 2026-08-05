---
'@memberjunction/connector-openwater': patch
---

OpenWater: a zero-row object now always says WHY, so "unexplained zero" stops being a category.

A live full-catalog run scored three objects — `Fund`, `OtherSessionItemType`, `Report` — as zeros with no
attributable cause, and the run's own verdict was *"NOT all-object proven"* because of them. Every other zero
on that run carried a reason (`ZERO_PARENTS`, `SECOND_LAYER_EMPTY`); these three carried nothing, which is the
worst possible reading: indistinguishable from a malformed request, and equally indistinguishable from a
tenant that genuinely has no funds.

The cause was a `console.warn` on line 755. A 401/403 leaf logged to the server console and `break`ed out of
the pagination loop, so the object returned zero records behind a **successful** run. Server console output is
not evidence — nobody reading the run artifact, the entity map, or the UI would ever see it.

Three codes replace that silence, and each is a test:

- **`LEAF_FORBIDDEN`** — the endpoint answered 401/403. This is a credential-scope limit, and it is now stated
  as one, carrying the status and the path. It is explicitly *not* also reported as an empty collection: "the
  token may not read this" and "there is nothing here" are different diagnoses that demand different actions
  (ask the site admin vs. accept the zero).
- **`ZERO_LEAVES`** — parents were found and every leaf came back empty. `ZERO_PARENTS` already covered
  "nothing to walk"; "walked everything, found nothing" had no code at all. The warning names the parent count,
  the request count, and every entry path tried, so the claim is checkable rather than assumed.
- **`EMPTY_COLLECTION`** — a flat collection's first page came back empty with no watermark in play. The
  request succeeded and the vendor returned nothing; that is a finding, not an absence of one.

The last of those is deliberately narrow. An empty *incremental* page is the normal steady state, and warning
on it would train everyone to ignore the warning that matters — so it fires only on a first page with no
watermark.

None of this changes what the connector fetches. It changes what a zero means to the person reading the run,
which is the difference between "this connector is unproven" and "this tenant has no funds, and here is the
request that established it."

**Proven live, and it immediately earned its keep.** Read-only run `F2644D5B` against the same client
tenant, same 13,198 records: every one of the 15 zeros now carries a code — 1 `LEAF_FORBIDDEN`
(`/v2/Funds` answers **401**, which also explains `FundTransaction`'s previously dead-end `ZERO_PARENTS`),
5 `ZERO_LEAVES`, 7 `EMPTY_COLLECTION`, 1 `ZERO_PARENTS`, 1 `FETCH_ABORTED_INCOMPLETE`. Unattributed zeros:
**3 → 0**.

The last of those is `Report`, and it is a real defect that had been hiding inside a silent zero:
`/v2/Rounds/{roundId}/ApplicationReports` returns **HTTP 400** on the first request of every run. Two
follow-on changes, both about the same thing — a request that fails should say what it asked for:

- **A failed read now quotes the vendor and names the URL it issued.** The read path threw a bare
  `HTTP 400` while the *write* paths have called `ExtractErrorMessage` since they shipped. "HTTP 400" does
  not say which of an object's entry paths failed, which parent id was in it, or what OpenWater objected
  to. Reads get the same treatment writes always had.
- **An alternative path templated on a different parameter is skipped, not filled with the wrong id.**
  `InjectParentID`'s docblock has always claimed it "returns null when a path template var is present but
  unset (so an alternativePath that uses a different var is skipped, not mis-substituted)". The code did
  the opposite: after the declared `{roundId}` missed, a fallback filled *the first remaining `{var}`*
  regardless of its name — so `Report` issued `/v2/Programs/{programId}/SessionReports` with a **roundId**
  in the programId slot. That is not a near-miss; it is a well-formed request for the wrong record, and the
  vendor is right to reject it. The code now matches its comment, and the narrowed walk is reported as
  `PATH_SKIPPED_PARAM_MISMATCH` rather than silently dropped — because "we searched everywhere" quietly
  becoming "we searched most places" is the same failure this whole pass exists to remove.

`Report` is not closed: the 400 may also want a query parameter this connector does not send, and the next
live run will say so in the vendor's own words instead of a bare status code. Tracked in
`docs/REQUIRED-FIXES.md` item 2.
