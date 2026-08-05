---
'@memberjunction/connector-openwater': patch
---

A single round OpenWater refuses no longer takes the whole `Report` object to zero.

Live, every run: `Report` failed with `HTTP 400` on the first request it made and returned nothing
(`FETCH_ABORTED_INCOMPLETE`, 0 records). The request shape was never the problem. OpenWater's own swagger
(`https://api.secure-platform.com/swagger/v2/swagger.json`) declares `GetApplicationReports` as
`GET /v2/Rounds/{roundId}/ApplicationReports` with `roundId` an int32 path segment and `pageIndex`/`pageSize`
optional query params, authenticated by `X-ClientKey` + `X-ApiKey` — which is exactly the request this
connector issues, with int32 round ids. The 400 is the vendor declining *that round* (judging-only rounds,
programs without sessions, ids outside the token's scope); the swagger documents no 400 at all, so it cannot
be predicted from the catalog.

The defect was what that refusal did to the walk. `FetchViaAccessPath` calls `PaginateLeaf` once per parent
and `PaginateLeaf` threw on any non-2xx, so the first refused round discarded every other round's reports.
One parent the vendor will not answer for is not the object being unfetchable.

A 4xx inside a parent walk is now returned rather than thrown: the walk continues, and the refusal is
recorded as a `LEAF_REQUEST_REJECTED` warning carrying the rejected parent ids, the count per status, the URL
issued and the vendor's own message. Three guards keep that from becoming a new kind of silence — if *every*
request was refused it still throws (a whole-endpoint failure is not a clean zero), a 5xx still throws (a
server fault is not parent-scoped, and walking past it would turn an outage into a quietly partial pull), and
`ZERO_LEAVES` is suppressed when any parent was refused, so a partial pull is never described as the vendor
having nothing to return. 401/403 keep their existing `LEAF_FORBIDDEN` treatment.

**Proven live** on the same client tenant, read-only run `847A4E5E`: `Report` created **68 rows**, all under
`roundId 82013` — one round holds this tenant's reports, the other six answered 200 with nothing. The pull also
drove the connector's first schema evolution, promoting the walk's `roundId` tag out of custom-overflow into a
real `Reports.roundId` column. No round returned a 400 on that run, so `LEAF_REQUEST_REJECTED` itself remains
unit-tested only (three tests); what is proven live is that the object which could never return a row now does.
