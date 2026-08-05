# @memberjunction/connector-openwater

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
