---
'@memberjunction/connector-openwater': patch
---

Detail-walk extraction: reach objects that live behind the application detail.

The Public API v2 exposes an application's per-round state only inside
`/v2/Applications/{applicationId}` — the detail carries `roundSubmissions[]`, each element
carries `fieldValues[]`, and file-upload field values carry a `mediaId` resolvable at
`/v2/Media/{mediaId}`. None of that is reachable by the paginated-leaf walker, so three new
AccessPath extraction modes are added, plus a harvest parent source:

- `detail-embedded` — records are a nested array inside a per-parent detail response,
  walked via `nestingSegments`, optionally filtered by `elementFilter` (equality or key
  presence), and tagged with the parent id.
- `detail-object` — each parent's detail response IS one record, tagged with its id.
- `parentSource: 'detail-harvest'` — parent ids are harvested by walking each door row's
  detail through `harvestSegments`, collecting `harvestIdKey` values (deduped).

Detail responses are cached per connector instance (10-minute TTL, bounded), so sibling
objects walking the same details in one sync — and the Media id-harvest — pay each
per-application call once. A 404 detail (parent deleted between list and detail) is
skipped, never failing the object.

Four objects ship on these modes, seeded by delta migration
`V202608211500__openwater__DetailWalkObjects` (SQL Server + Postgres):
`ApplicationRoundSubmission` (PK applicationId+roundId), `ApplicationFile` (file-upload
field values, PK mediaId), `Media` (PK mediaId), `ApplicationWinnerType` (embedded via
`Programs -> rounds[] -> winnerTypes[]`, which also exercises two-level embedded-array
descent). All id fields are declared unsized String per the V202608050910 sizing doctrine.
