# @memberjunction/connector-openwater

## 1.4.1

### Patch Changes

- 59e6f46: Detail-only data can now arrive, and winner assignments are at the grain the client counts.

  **Three objects had fields only a per-record GET returns, and none of it could arrive.** The swagger (read
  2026-09-22) shows `/v2/Evaluations/{id}` carrying computed and rank scores plus the inline score, general
  scoring answer and judge team arrays; `/v2/Sessions/{id}` carrying typeId, chairs, items and field values;
  `/v2/Users/{id}` carrying the four role flags, profile field values and sub-account ids. The scores and
  answers are the content of an evaluation. No new extraction mode was needed: the existing `detail-object`
  and `detail-embedded` walks already fetch each door row's own detail, so the per-record GET is declared in
  metadata. Eleven new objects: `EvaluationDetail` and three children, `SessionDetail` and three children,
  `UserDetail` and two children. The judge rosters were audited too and are not affected (same item model,
  different scoping).

  **Winner assignments were declared at the round grain only.** `ApplicationWinnerType` is the round-level
  menu of available types from `/v2/Programs`. The client's 89 counts per-application awards, which live in
  `/v2/Applications/{id} -> roundSubmissions[].winnerTypes[]` as an array of type names. The 1.3.6 change
  said so in its own body; #364 then skipped that array as a duplicate. It is not. New object
  `ApplicationWinnerAssignment`, keyed (applicationId, roundId, name).

  **Two small additions to the detail-embedded walk make the children keyable.** `AccessPath.segmentTags`
  copies an intermediate node's field (the round submission's roundId) onto every element beneath it, never
  overwriting a vendor value; `AccessPath.scalarLeafKey` keeps scalar leaves, which the walker used to drop
  silently (every string in `winnerTypes[]`). With neither declared the walk behaves exactly as before. The
  four #364 children (`ApplicationJudgeScorecard`, `ApplicationReceivedRecommendation`,
  `ApplicationPendingRecommendation`, `ApplicationScoringQuestionScore`) gain `roundId` and their element
  fields, declare composite keys, and leave the read-only PK baseline.

  Every key comes from the swagger's element schemas, so nothing relies on soft-PK inference. Cost is one GET
  per door row per detail walk, shared across siblings by the per-batch detail cache and bounded by #364's
  concurrent slices. One delta migration pair (guarded INSERTs and UPDATEs, `LOWER(Name)` lookups).

## 1.4.0

### Minor Changes

- 97dbcd8: Walk parent details concurrently, and model four embedded collections as their own objects.

  A detail walk is one HTTP call per parent and the loop awaited each one before starting the
  next. Three objects derive from the same Application door, so each paid the full serial cost
  of ~2,079 application details — measured 6,273 records in ~20 minutes on the sandbox, against
  13,518 in 73 seconds for objects that fetch a list directly. Parents are now fetched in bounded
  concurrent slices and processed in order, so the resume cursor and the record budget behave
  exactly as before. Slice width follows the remaining budget, which keeps discovery sampling as
  cheap as it was. `fetchConcurrency` on the connection overrides the default of 8, capped at 16.

  Four collections embedded in an application's round submissions — judge scorecards, received
  and pending recommendations, and aggregated scoring-question scores — were reaching tenants as
  unmapped overflow keys, offered as JSON-blob columns on the parent. They are now declared
  objects walked through the same detail path, each tagged with its applicationId so it joins the
  dependency graph as a child table rather than a stringified array.

  Also repairs the T-SQL twin of the case-sensitivity migration, which carried two orphaned END
  statements and failed with "Incorrect syntax near 'END'". The Postgres twin was unaffected, so
  this never showed on a Postgres tenant — but it meant the catalog repair, and every migration
  after it, could not apply on SQL Server at all.

### Patch Changes

- 140cf18: The catalog now says it is the contract, and no longer advertises a dead host.

  **Discovery is declared-only, and nothing said so.** `DiscoverObjects`, `DiscoverFields` and
  `IntrospectSchema` read the Declared catalog from the engine cache. That is correct for this vendor:
  the published swagger (92 paths, read 2026-09-22) has no endpoint that enumerates the object surface,
  so there is nothing live to reconcile against, and `DiscoveryIsAuthoritative` is honestly false. But
  with no record of what the catalog was declared from or when, a stale catalog was indistinguishable
  from a current one, and the picker looked complete without saying it could only ever be as current as
  the last catalog edit. The Integration row now carries `Configuration.DeclaredAgainst` (swagger URL,
  access date, sha256, path and schema counts, and how to re-check), the Description (bounded to 255 characters by
  the column) states that the catalog is declared and names the pin, and OpenWater leaves the freshness-pin lint's
  grandfathered list. Checked on the same date: every swagger GET path the catalog does not reference is
  a per-record detail, a form template or a settings singleton, so no list collection is undeclared today.

  **The catalog advertised a host that does not resolve.** `NavigationBaseURL` was
  `https://api.getopenwater.com`, which is NXDOMAIN. Display-only, so nothing failed, but it is the URL a
  person is shown when they ask where their data comes from. The value is now the fleet's per-tenant
  template form, `https://{tenant}.secure-platform.com`; the tenant subdomain is the connection's
  ClientKey.

  One delta migration (paired T-SQL and PostgreSQL) updates the Integration row, resolved with
  `LOWER(Name)` so it applies on both dialects. No object or field changed.

## 1.3.10

### Patch Changes

- 4c2541d: Five objects have had their AccessPath discarded since creation, so they could never fetch.

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

  Each held its watermark and retried, so none could ever advance. Every object that _has_ its
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

## 1.3.9

### Patch Changes

- a438a3a: Field declarations that PostgreSQL silently discarded are replayed, and the pattern is now linted.

  Six OpenWater migrations resolved the integration with

            JOIN "__mj"."Integration" i ON i."Name" = 'openwater'

  while the Integration row is named `OpenWater`. SQL Server's default collation is case-INSENSITIVE,
  so the predicate matched there and every row landed. PostgreSQL compares strings case-SENSITIVELY, so
  it matched nothing — and an `INSERT ... SELECT` whose join matches nothing inserts zero rows and
  reports success.

  Measured on a PostgreSQL workspace 2026-09-13: OpenWater installed all 30 objects and **24 field
  declarations never arrived**, leaving five objects with no columns at all — `ApplicationFile`,
  `ApplicationRoundSubmission`, `ApplicationWinnerType`, `Judge`, `Media`. No columns means no primary
  key, so discovery ended each with `entity.skipped-no-pk` (and an empty message), and none of the five
  can ever sync. The same connector on SQL Server has all of them. These five are exactly the objects
  added by the detail-walk work, so the whole of that effort was inert on PostgreSQL.

  They cannot be sampled into existence either: all five are detail-walk children whose `APIPath` is a
  description rather than a URL (`(embedded in /v2/Applications/{applicationId} roundSubmissions[])`),
  reachable only through `Configuration.AccessPath`. The connector walks it at sync time; discovery's
  sampler does not. Two of them say so out loud — `ApplicationWinnerType` fails with `Failed to parse
URL` and `Judge` with an HTTP error — and the other three return nothing, silently. So the declared
  catalog is their only possible source of columns.

  The already-applied migrations are NOT edited — Flyway validates their checksums. Instead a new
  migration per connector replays the affected statements with `lower(...)`. Every replayed statement is
  either `NOT EXISTS`-guarded or an idempotent `UPDATE`, so on a workspace that already has the rows it
  changes nothing.

  Hivebrite carried the same defect in `V202607271500__hivebrite__WritablePK` (4 sites) and is repaired
  the same way.

  A new `scripts/lint-migration-name-case.mjs` fails CI when a migration compares a `Name` column to a
  literal differing only by case from the connector's declared Integration name. The 14 already-applied
  files are grandfathered and that list may only shrink.

## 1.3.8

### Patch Changes

- a0563d1: Record identity ignored every nested field — the same defect fixed in PropFuel 1.2.4, in the three
  connectors that still carried the line.

  `JSON.stringify(value, Object.keys(value).sort())` reads as "serialise with sorted keys". It is not.
  The second argument is a **replacer**, and an array replacer is an **allow-list of property names
  applied at every level** — so passing the top-level keys stripped every nested key from the output,
  and any two values differing only below the top level serialised identically.

  Proven live on PropFuel: a sandbox sync fetched ~2,400 records and stored **181**, because the engine
  did the right thing with a wrong input — two records sharing an identity are one record observed
  twice, so `CollapseDuplicateIdentities` collapsed them. 882 of 884 clicks in a single batch.

  Where each connector used it, and what it cost:

  - **Totara** `ExplodeCollection` — the dedupe signature for exploded collection elements. Its own
    comment says "byte-identical projection = one fact restated. Anything differing is kept", and the
    code did the opposite: two elements differing only in a nested object were counted as repeats and
    **silently dropped**, incrementing `ElementsCollapsed`. This is the sharpest of the three, because
    the drop is deliberate and invisible.
  - **OpenWater** `ContentHash` — the identity fallback when a declared primary key is partial or
    missing. `Fields` carries the full source record for custom-column pass-through, so nested vendor
    JSON is exactly what it hashes.
  - **WildApricot** `stableHash` — the same fallback shape.

  All three now use one `canonicalJSON`: keys sorted **recursively**, array order kept (order is
  semantically meaningful), `undefined` omitted, `Date` via ISO string.

  Pinned by tests that fail on the old code: Totara gains three behavioural cases on the public
  `ExplodeCollection` (two elements differing only in a nested value survive; a genuine restatement
  still collapses; nested key _order_ is ignored while nested _values_ are not) — two of them fail
  against the previous implementation with exactly the collapse described above. OpenWater and
  WildApricot export `canonicalJSON` and gain five cases each, one of which asserts the old expression
  produced identical output for two records that must be distinct.

## 1.3.7

### Patch Changes

- 06b2b4b: Allow MemberJunction 6.x as a peer. Every connector capped its `@memberjunction/*` peers at `<6.0.0`; the ceiling moves to `<7.0.0`, and `mj-app.json.mjVersionRange` moves with it so npm and `mjdev app register` agree. Floors are unchanged, so 5.x hosts are unaffected.

  Why the ceiling is the fix on a 6.x host: pnpm's `auto-install-peers` satisfies an unmet peer range by installing a **second** copy of `@memberjunction/core`, and two copies of core in one process is the failure that surfaces as thousands of unrelated-looking type errors. Business Central hit exactly this and was widened alone (#180, then #208 for the manifest); this brings the other 56 connectors, the two private platform packages, and the shared `connector-id-window-scan` package to the same range, so the duplicate cannot return transitively through a shared dependency either. The scaffolding scripts (`new-connector`, `scaffold-openapps`, `split-into-packages`) now mint `<7.0.0` too, so a new connector does not reintroduce the cap.

  Verified at compile time, not at runtime: all 61 packages in the repo (57 connectors, the two private platform packages, the two shared packages) type-check against `@memberjunction/*@6.1.0-edge.5` — the only 6.x published at the time; there is no stable 6.x yet — with every framework `.d.ts` resolved from the 6.x install and none from 5.x. That check is `npm run check:mj-compat` (`scripts/typecheck-against-mj.mjs`), added with this change so the claim can be re-run against any MJ version. It is API compatibility at the type level; the only runtime evidence on a 6.x host remains the Business Central team's edge deployment.

## 1.3.6

### Patch Changes

- e5b989b: Make a detail walk survivable, and make its zeros say what was actually there

  Once the door paged properly, three defects that the one-page cap had been hiding all surfaced in
  the same run — and every one of them ended in a _successful_ batch that was wrong.

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

  **3. The walk bounded records emitted, not vendor calls made.** `ctx.BatchSize` (engine default 200) stops the walk when enough _records_ accumulate. A sparse child — most Applications carry no
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

  **5. The harvest resumed by the wrong thing.** Bounding the harvest by id count made `parentIDs` a
  prefix of the real parent set, and the walk then resumed by _parent_ offset — so once the offset
  passed the number of ids that prefix could yield, the object emitted nothing, reported `HasMore`,
  and never advanced. The harvest cursor is now a **door-row** position (`detail:h<door>[:<id>]`):
  each call harvests a fresh window of door rows, and a window whose ids could not all be emitted in
  one call resumes at that same window rather than advancing past the remainder. An empty window
  advances the cursor instead of reporting the object exhausted — otherwise a 1,976-parent walk ends
  at door row 25.

  **6. The union discarded every member's resumption state.** An object with `alternativeAccessPaths`
  is several walks unioned, and the union ran them all inside one call while returning
  `HasMore: results.some(...)` — dropping each member's `NextCursor` and `NextPage`. Any resumable
  member (a bounded detail walk, or a leaf that hit the batch cap) therefore said "there is more" while
  naming no continuation, so the engine re-read that member from the start on every call or lost its
  remainder. The union now walks ONE member per call on a `union:<i>|c<cursor>` cursor, so each member
  keeps its own state; a member that claims `HasMore` with no continuation is treated as finished
  rather than re-read forever. Cross-member de-duplication inside a call is no longer needed — members
  are unioned by primary key at the write.

  **7. An embedded leaf could not say which parent produced it.** `ApplicationWinnerType` reads
  `/v2/Programs -> rounds[] -> winnerTypes[]`, where a winner type is `{id, name}` and the SAME type
  id is declared on more than one round. The embedded-array walk kept only the leaf, so the round was
  absent from the row and the object was keyed on `id` alone — distinct (round, type) pairs collapsed
  into one row, 74 stored against a client target of 89. An AccessPath may now declare
  `embeddedParentTag: { sourceKey, asKey }`, which copies the immediate parent's id onto each leaf
  (never overwriting a value the vendor supplied under that name), and `roundId` is DECLARED as part
  of the key in `V202608230600` — declared rather than discovered, because MJ will not let a
  discovered field join the key of an object that already has a declared PK.

- e5b989b: Page a detail walk's door by the DOOR object's rules, not the child's

  `PaginateLeaf` decides whether to page from `obj.SupportsPagination && obj.PaginationType !== 'None'`.
  The door fetch passed the **child** object, and a walked child declares neither — its APIPath is
  literally "(embedded in /v2/Applications/{applicationId} …)". So the door request went out with no
  `pageIndex`/`pageSize` and the vendor answered with its default page. Every detail walk was capped
  at one page of parents, while honestly reporting `HasMore: false`, because it really had consumed
  every parent it was given. It was given ten.

  Measured on a live tenant with 1,976 Applications:

  | object                     | result                                      | target |
  | -------------------------- | ------------------------------------------- | ------ |
  | ApplicationRoundSubmission | 10 records from 10 parents, `hasMore:false` | 1,935  |
  | ApplicationFile            | 0 records from 10 parents (`ZERO_LEAVES`)   | 4,001  |
  | ApplicationWinnerType      | 74 — correct                                | 89     |

  ApplicationWinnerType was right only because its door, `/v2/Programs`, has 5 rows and fits inside a
  single default page — which is what made the cap look like a per-object extraction problem rather
  than one shared defect.

  The door object is now resolved from the catalog by `AccessPath.door` and its pagination governs the
  door request. When the door has no catalog row we fall back to the child, so a misdeclared AccessPath
  behaves as it did before rather than throwing mid-sync.

- e704e04: A field promoted to PRIMARY KEY by a migration must also be relabelled Declared

  V202608212210 completed JudgeAssignment's key into the (userId, roundId) pair. On tenants where
  `roundId` already existed it did that through an UPDATE rather than the INSERT, and that UPDATE set
  IsPrimaryKey/IsRequired/AllowsNull but left `MetadataSource` alone — leaving a PRIMARY KEY still
  labelled `Discovered`.

  The engine's overlay then does exactly what it is designed to do: `decidePKPromotion` forbids a
  _Discovered_ field from being part of the key of an object that has a declared PK, so the next
  schema refresh demotes it. Observed on a live tenant, the catalog went from
  `declared=roundId,userId` back to `declared=userId` — the person-grain collapse V202608212210
  existed to fix, where a judge assigned to several rounds folds to one row per person. The self-heal
  was correct; the row was mislabelled.

  V202608222100 re-asserts `IsPrimaryKey` and sets `MetadataSource = 'Declared'` for that field,
  matched by object + field name because the row needing repair is the pre-existing promoted one
  whose ID differs per tenant. Idempotent, and a no-op on tenants that took the INSERT path.

## 1.3.5

### Patch Changes

- d0dda7e: Detail walks are bounded by the caller's batch size, and resumable.

  A detail walk is one HTTP call per parent — on a real tenant that is ~2,000 application details,
  and `Media` additionally resolves ~4,000 `/v2/Media/{id}` records. Running all of it inside a
  single `FetchChanges` call made the walk unbounded and therefore un-stoppable:
  `DiscoverFieldsViaFetch` streams `FetchChanges` and stops at a record cap, but it can only stop
  BETWEEN batches, so field-sampling ONE detail object paid the entire walk and blew through the
  5-minute discovery budget. Observed as an apply/introspect that could not finish inside any
  gateway timeout.

  The walk now consumes parents from a cursor offset (`detail:<n>`), accumulates until the caller's
  `BatchSize` is met, and hands the remaining offset back. Sampling asks for a handful of records
  and gets them after a handful of calls; a real sync passes a large batch size and still walks
  everything, now across resumable batches — which also makes a killed run cheap to resume. The
  `detail-harvest` id collection is bounded the same way.

  One trap this closes explicitly: once the harvest stops early, the parent list is a PREFIX of the
  real parent set, so its length must not be read as the total. It was, which reported
  `HasMore: false` with door rows still un-harvested — silently dropping every later record. A
  regression test now drives a whole object through batch-sized calls and asserts nothing is lost.

  The per-parent detail cache is bounded too, oldest-first at 500 entries. Its previous
  20,000-entry ceiling was finite but not meaningfully bounded — each entry is a whole application
  detail — so a full walk could hold gigabytes alive, measured as repeated container SIGKILLs on a
  7GB host while an apply sampled these objects. The cache only needs to span one batch (siblings
  walking the same parents), and FIFO eviction keeps the entries actually being reused, where the
  old clear-everything threw out the in-flight batch's own cache.

## 1.3.4

### Patch Changes

- 0e0109a: Detail-walk extraction: reach objects that live behind the application detail.

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

- d68a3a2: The judge pair: a person-grain Judge object, and JudgeAssignment regains its pair grain.

  - **`alternativeAccessPaths`** (new, general): an object may declare additional FULL walks —
    complete AccessPath objects, not just alternative entry paths — when its records live behind
    more than one door. The walks are unioned and deduplicated by primary key.
  - **`Judge`** (new object, first union user): the API has no `/v2/Judges` list endpoint. Judges
    assigned to rounds come from the `AssignedToRound` walk; judges/managers on judge teams come
    embedded in `/v2/JudgeTeams` rows (`judges[]` / `managers[]`, identical JudgeInfo shape). A
    team-only judge never appears in the round walk, so neither source alone is the population.
  - **`JudgeAssignment` PK widened to (userId, roundId)**: with userId alone, a judge assigned to
    several rounds collapsed to one row per person — the object silently held distinct judges
    instead of assignments. The always-injected roundId walk tag joins the key, via delta
    migration `V202608212210` (SQL Server + Postgres) handling both the promoted-field and
    fresh-tenant populations per the V202608050910 precedent. Installed tenants should expect
    re-keyed rows on the next sync; rows keyed under the old person-grain ExternalID are stale
    and can be cleaned after the refill.

## 1.3.3

### Patch Changes

- 6ee916d: Relicense to the Business Source License 1.1.

  Metadata and documentation only: the `license` field moves to `BUSL-1.1` and the
  repo gains a LICENSE file. No runtime behaviour, API surface, or dependency
  changes. The bump exists so the new licence metadata reaches npm, since the
  registry shows the licence of the latest published version.

## 1.3.2

### Patch Changes

- 8f302db: Fix the credential schema and error message that made every connection attempt fail.

  The credential-type's FieldSchema never declared a `BaseURL` property, even though `GetAuth()` has
  always required `Config.BaseURL` — so the connection form was structurally unable to satisfy the
  connector's own runtime requirement, regardless of what the user entered.

  Also corrects both `BaseURL`'s and `ClientKey`'s descriptions, and the runtime error message thrown
  when `BaseURL` is missing. OpenWater's real API host is the SHARED `https://api.secure-platform.com`
  (same value for every customer, confirmed live against its own published swagger) — not a per-tenant
  subdomain as previously claimed. The tenant's own subdomain (e.g. `your-org.secure-platform.com`) is
  instead what `ClientKey` carries, sent as the `X-ClientKey` header to identify the account against
  the shared host.

  No behavioral change to request logic — `BaseURL` was, and remains, a required config value; only
  its documentation and the schema's ability to collect it were wrong.

## 1.3.1

### Patch Changes

- d495a0c: OpenWater: a zero-row object now always says WHY, so "unexplained zero" stops being a category.

  A live full-catalog run scored three objects — `Fund`, `OtherSessionItemType`, `Report` — as zeros with no
  attributable cause, and the run's own verdict was _"NOT all-object proven"_ because of them. Every other zero
  on that run carried a reason (`ZERO_PARENTS`, `SECOND_LAYER_EMPTY`); these three carried nothing, which is the
  worst possible reading: indistinguishable from a malformed request, and equally indistinguishable from a
  tenant that genuinely has no funds.

  The cause was a `console.warn` on line 755. A 401/403 leaf logged to the server console and `break`ed out of
  the pagination loop, so the object returned zero records behind a **successful** run. Server console output is
  not evidence — nobody reading the run artifact, the entity map, or the UI would ever see it.

  Three codes replace that silence, and each is a test:

  - **`LEAF_FORBIDDEN`** — the endpoint answered 401/403. This is a credential-scope limit, and it is now stated
    as one, carrying the status and the path. It is explicitly _not_ also reported as an empty collection: "the
    token may not read this" and "there is nothing here" are different diagnoses that demand different actions
    (ask the site admin vs. accept the zero).
  - **`ZERO_LEAVES`** — parents were found and every leaf came back empty. `ZERO_PARENTS` already covered
    "nothing to walk"; "walked everything, found nothing" had no code at all. The warning names the parent count,
    the request count, and every entry path tried, so the claim is checkable rather than assumed.
  - **`EMPTY_COLLECTION`** — a flat collection's first page came back empty with no watermark in play. The
    request succeeded and the vendor returned nothing; that is a finding, not an absence of one.

  The last of those is deliberately narrow. An empty _incremental_ page is the normal steady state, and warning
  on it would train everyone to ignore the warning that matters — so it fires only on a first page with no
  watermark.

  None of this changes what the connector fetches. It changes what a zero means to the person reading the run,
  which is the difference between "this connector is unproven" and "this tenant has no funds, and here is the
  request that established it."

  **Proven live, and it immediately earned its keep.** Read-only run `F2644D5B` against the same production
  tenant, same 13,198 records: every one of the 15 zeros now carries a code — 1 `LEAF_FORBIDDEN`
  (`/v2/Funds` answers **401**, which also explains `FundTransaction`'s previously dead-end `ZERO_PARENTS`),
  5 `ZERO_LEAVES`, 7 `EMPTY_COLLECTION`, 1 `ZERO_PARENTS`, 1 `FETCH_ABORTED_INCOMPLETE`. Unattributed zeros:
  **3 → 0**.

  The last of those is `Report`, and it is a real defect that had been hiding inside a silent zero:
  `/v2/Rounds/{roundId}/ApplicationReports` returns **HTTP 400** on the first request of every run. Two
  follow-on changes, both about the same thing — a request that fails should say what it asked for:

  - **A failed read now quotes the vendor and names the URL it issued.** The read path threw a bare
    `HTTP 400` while the _write_ paths have called `ExtractErrorMessage` since they shipped. "HTTP 400" does
    not say which of an object's entry paths failed, which parent id was in it, or what OpenWater objected
    to. Reads get the same treatment writes always had.
  - **An alternative path templated on a different parameter is skipped, not filled with the wrong id.**
    `InjectParentID`'s docblock has always claimed it "returns null when a path template var is present but
    unset (so an alternativePath that uses a different var is skipped, not mis-substituted)". The code did
    the opposite: after the declared `{roundId}` missed, a fallback filled _the first remaining `{var}`_
    regardless of its name — so `Report` issued `/v2/Programs/{programId}/SessionReports` with a **roundId**
    in the programId slot. That is not a near-miss; it is a well-formed request for the wrong record, and the
    vendor is right to reject it. The code now matches its comment, and the narrowed walk is reported as
    `PATH_SKIPPED_PARAM_MISMATCH` rather than silently dropped — because "we searched everywhere" quietly
    becoming "we searched most places" is the same failure this whole pass exists to remove.

  `Report` is not closed: the 400 may also want a query parameter this connector does not send, and the next
  live run will say so in the vendor's own words instead of a bare status code. Tracked in
  `docs/REQUIRED-FIXES.md` item 2.

- d495a0c: Nine parent-walked objects carried a parent id that the catalog never declared.

  The nested parent walk already tags every child with the id it was walked under — `if (parentTagName &&
r[parentTagName] == null) r[parentTagName] = parentID` — which is how all 68 `Report` rows on the live run carry
  `roundId 82013` without the vendor ever sending it. That part was right. What was missing is that **not one of
  the nine walked objects declared the field it is tagged with**, so a value the connector deliberately produces
  arrived as if it were an unknown extra.

  Two consequences, both observed live:

  - **The tag landed in `__mj_integration_CustomOverflow` and only became a column later**, when the engine
    promoted it. That is the whole mechanism behind the first-sync field-map skew in `docs/REQUIRED-FIXES.md` item
    6: run `847A4E5E` ran `ApplicationCategory` with `fieldMapsCount: 0` and errored all 43 writes, then the next
    run had 5 maps and skipped all 43 on content hash. `Report` showed the same skew one notch smaller (2 maps then
    3). Both objects are parent-walked, and in both the disputed field was exactly the walk tag.
  - **The parent link was not a relationship anywhere.** Even after promotion the column exists with no
    `RelatedIntegrationObjectID`, so nothing — not CodeGen's soft FK, not the platform's DAG view — knows a
    `Report` belongs to a `Round`.

  Now declared on all nine, each with an explicit relation to the object it is walked under:
  `ApplicationCategory`, `OtherSessionItemType`, `ScheduleDay`, `ScheduleRoom`, `ScheduleTimeSlot`, `ScheduleItem`,
  `SessionType` → `Program`; `Report` → `Rounds`; `FundTransaction` → `Fund`.

  Declared as **`String`, not `Integer`**, and that is not laziness — see `docs/REQUIRED-FIXES.md` item 7, filed in
  the same pass. A declared unsized `Integer` becomes `NVARCHAR(MAX)`, which SQL Server cannot index, so its soft FK
  index is silently skipped: 8 of this connector's 25 relations are unindexed today for exactly that reason, on its
  three largest tables. Unsized `String` lands at `NVARCHAR(812)` — sized, indexable, and never a shrink of the two
  of these that the engine had already promoted as sized columns. `IsReadOnly` stays `false` (a read-only field with
  a relation is what caused the sproc-omission class in Totara).

  Shipped as delta migration `V202608050910__openwater__DeclareParentWalkTagFields` (+ hand-authored `.pg.sql`
  twin), verified against a live catalog: the insert is guarded per field, and a second, name-driven statement
  back-fills the relation onto rows that already exist — necessary because three of the nine were already present
  as engine-promoted `MetadataSource='Discovered'` rows with no relation. First apply: 6 inserted, 3 relations
  repaired. Re-apply: 0 and 0. Zero of the connector's 19 walk-tag fields are left without a relation.

  Also fixed in this pass: `scripts/lint-catalog-completeness.mjs` counted only `spCreateIntegrationObjectField`
  calls from generated seeds, so any field shipped by a hand-authored delta read as "declared but never shipped" —
  the gate failed on this change while the change was correct. It now also counts fields delivered by guarded
  `INSERT INTO … IntegrationObjectField` statements, by their hardcoded ID literals.

- d495a0c: A single round OpenWater refuses no longer takes the whole `Report` object to zero.

  Live, every run: `Report` failed with `HTTP 400` on the first request it made and returned nothing
  (`FETCH_ABORTED_INCOMPLETE`, 0 records). The request shape was never the problem. OpenWater's own swagger
  (`https://api.secure-platform.com/swagger/v2/swagger.json`) declares `GetApplicationReports` as
  `GET /v2/Rounds/{roundId}/ApplicationReports` with `roundId` an int32 path segment and `pageIndex`/`pageSize`
  optional query params, authenticated by `X-ClientKey` + `X-ApiKey` — which is exactly the request this
  connector issues, with int32 round ids. The 400 is the vendor declining _that round_ (judging-only rounds,
  programs without sessions, ids outside the token's scope); the swagger documents no 400 at all, so it cannot
  be predicted from the catalog.

  The defect was what that refusal did to the walk. `FetchViaAccessPath` calls `PaginateLeaf` once per parent
  and `PaginateLeaf` threw on any non-2xx, so the first refused round discarded every other round's reports.
  One parent the vendor will not answer for is not the object being unfetchable.

  A 4xx inside a parent walk is now returned rather than thrown: the walk continues, and the refusal is
  recorded as a `LEAF_REQUEST_REJECTED` warning carrying the rejected parent ids, the count per status, the URL
  issued and the vendor's own message. Three guards keep that from becoming a new kind of silence — if _every_
  request was refused it still throws (a whole-endpoint failure is not a clean zero), a 5xx still throws (a
  server fault is not parent-scoped, and walking past it would turn an outage into a quietly partial pull), and
  `ZERO_LEAVES` is suppressed when any parent was refused, so a partial pull is never described as the vendor
  having nothing to return. 401/403 keep their existing `LEAF_FORBIDDEN` treatment.

  **Proven live** on the same production tenant, read-only run `847A4E5E`: `Report` created **68 rows**, all under
  a single round — one round holds this tenant's reports, the other six answered 200 with nothing. The pull also
  drove the connector's first schema evolution, promoting the walk's `roundId` tag out of custom-overflow into a
  real `Reports.roundId` column. No round returned a 400 on that run, so `LEAF_REQUEST_REJECTED` itself remains
  unit-tested only (three tests); what is proven live is that the object which could never return a row now does.

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

## 1.3.0

### Minor Changes

- 37cfe35: Sample-union discovery for describe-endpoint connectors: each connector wires MJ's existing `DiscoverFieldsViaFetch` sampler into its declared catalog inside `IntrospectSchema`, unioned per object via the shared pure helper `mergeDeclaredWithSampledFields` — real widths and MJ-discovered custom columns land before the first sync (no `nvarchar(255)` overflow / `STRING_OVERFLOW_SKIPPED`). Connectors with no `IntrospectSchema` of their own get the standard `super.IntrospectSchema → sample → merge → return` override; connectors that already own an `IntrospectSchema` (HubSpot, Salesforce, Nimble AMS, YourMembership) are WRAPPED — their existing logic/caching is preserved and the union runs on the built result before return (Fonteva inherits it via Salesforce's `super`).

  The width rule is NEVER-SHRINK: `MaxLength = max(declared, measured)`. It only ever widens, so connectors that already carry real declared widths from their describe API (Salesforce/Fonteva) are never truncated below the real width, while connectors whose declared catalog has no width still adopt MJ's measured value. Connectors add no discovery/merge/sync logic of their own; MJ owns measurement, type/PK inference, persistence and reconcile. `DiscoverFields` is unchanged (no recursion). Schema-less / already-streaming connectors (PropFuel, FileFeed, RelationalDB, MJtoMJ, ORCID) are unaffected.

## 1.2.2

### Patch Changes

- dbffddf: Declare semantic lengths for url/email-class string fields (255 default → url 2048, email 320). Oversize values are skipped, not truncated — silent record-loss risk.

## 1.2.1

### Patch Changes

- cc38129: Widen prose string fields (description/notes/bio/summary/…) from the 255 default to 4000. The engine skips-not-truncates oversize values, so every such field was a silent record-skip risk — live repro: PheedLoop Members.about skipped 54 records/sync at 255 vs real 2,595-char values.

## 1.2.0

### Minor Changes

- 991a336: Fix the seed migration so `mj app install` succeeds — the migration now creates the connector's CredentialType **before** the Integration.

  These connectors define their own `MJ: Credential Types` row (e.g. `PropFuel API`, `GrowthZone OAuth2`, `Salesforce JWT Bearer`) and their `Integration` row references it via `CredentialTypeID`. The published migration seeded the `Integration` but **never created the CredentialType**, so every fresh install aborted at the migration step (which runs before any metadata sync) with:

  ```
  The INSERT statement conflicted with the FOREIGN KEY constraint "FK_Integration_CredentialType" (SQL Server)
  function __mj.spCreateIntegration(...) — FK_Integration_CredentialType (PostgreSQL)
  ```

  Root cause was in the seed-migration generator: it reset the `Integration`/`IntegrationObject`/`IntegrationObjectField` catalog between connectors but **left CredentialType rows in the generation DB**, so `mj sync push`'s SQL-logging saw the type already present and emitted no `spCreateCredentialType` call. Fixed the generator to also delete each connector's own CredentialType before its push, so the create is re-emitted; the existing `directoryOrder` (credential-type before integration) places it ahead of the Integration in the migration.

  Verified: each connector's regenerated migration applies cleanly against a real `__mj` schema (real `FK_Integration_CredentialType` + `spCreate*` functions) — CredentialType created, then Integration, then objects, 0 errors. Both SQL Server and PostgreSQL migrations regenerated; same migration version (in place).

  Connectors that reference a **core** credential type (`OAuth2 Client Credentials`, `Azure Service Principal`, `API Key`, `OAuth2 Password Grant`) are unaffected and unchanged — those types exist on every fresh instance.

  The `spCreateCredentialType` call is also guarded with `IF NOT EXISTS` (both dialects), so installing two connectors that share a credential type (Fonteva and Salesforce both use `Salesforce JWT Bearer`) on the same instance no longer collides — the second install skips the already-created type. Verified: Salesforce-then-Fonteva on one instance, both Integrations created, 0 errors.

## 1.1.0

### Minor Changes

- fe75578: Fix the PostgreSQL seed migration so `mj app install` succeeds on PostgreSQL.

  The 1.0.0 PostgreSQL migration (`migrations-pg/*.pg.sql`) was generated with a stale SS→PG converter (CLI 5.36, which predates the boolean SP-argument coercion shipped in 5.40.x). It emitted the integration-catalog `spCreate*` calls with integer `_Clear` flags (`p_<col>_Clear := 1`) against `BOOLEAN` parameters. Because PostgreSQL resolves function overloads by exact argument type and has no implicit `integer → boolean` cast for a named argument, every such call aborted on apply with:

  ```
  ERROR: function __mj.spCreateIntegrationObject(... p_<col>_clear => integer ...) does not exist
  ```

  Regenerated each `.pg.sql` with CLI 5.43.0, which emits native `:= TRUE`/`:= FALSE`. The same regeneration also corrects a second 5.36 defect: identifier-quoting (`."Configuration"`) leaking into string literals inside seeded descriptions and `Configuration` JSON.

  SQL Server migrations (`migrations/*.sql`) are unchanged — this is a PostgreSQL-only fix.

## 1.0.0

### Major Changes

- 50cb849: Initial release: self-contained Open App shipping its Integration metadata (objects + fields) and credential type. Strict-TypeScript build clean.
