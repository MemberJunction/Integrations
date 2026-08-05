# OpenWater connector — required fixes for the next release

Open items found while proving this connector against a live client tenant (read-only). Each entry names
the failure as a *user* experiences it, the evidence, and what the fix has to do. Delete an entry when it
ships — a changeset entry is the record of the fix, this file is the record of the debt.

Nothing here is speculative: every item was observed in a live run, not inferred from reading code.

---

## 1. Three objects returned zero rows with no reason at all — FIXED

Live full-catalog run `3BA35740` scored `Fund`, `OtherSessionItemType` and `Report` as zeros with **no
attributable cause**, and the run's own verdict was *"NOT all-object proven"* because of them. Every other
zero on that run carried a reason; these three carried nothing, which is the worst possible reading —
indistinguishable from a malformed request, and equally indistinguishable from a tenant that genuinely has
no funds.

The cause was a `console.warn`. A 401/403 leaf logged to the server console and `break`ed out of the
pagination loop, so the object returned zero records behind a **successful** run. Server console output is
not evidence: nobody reading the run artifact, the entity map, or the UI would ever see it.

**Fixed** by three warning codes that travel with the batch — `LEAF_FORBIDDEN` (401/403, carrying status
and path), `ZERO_LEAVES` (parents walked, every leaf empty, naming parent count / request count / every
entry path tried) and `EMPTY_COLLECTION` (a flat first page genuinely empty, no watermark in play).
`EMPTY_COLLECTION` is deliberately narrow — an empty *incremental* page is the normal steady state, and
warning on it would train everyone to ignore the warning that matters. Changeset
`openwater-attribute-every-zero`; four unit tests pin the four cases apart.

---

## 2. `Report` fails with HTTP 400 on the first request, every run — FIXED

Exposed by item 1: with the zeros attributed, `Report` was the one of the three that turned out to be a
genuine defect rather than a permission limit or an empty collection. Live run `F2644D5B`:

```
record.error  Report  OpenWater fetch failed for "Report": HTTP 400
warning       Report  FETCH_ABORTED_INCOMPLETE  batchIndex 1, recordsFetchedBeforeFailure 0
```

It fails on the **first** request of the object, so it is a request-shape defect, not a data or throughput
one — the same class as Totara's `Cohort Members` `[invalidparameter]`. The parent ids are good
(`openwater.Rounds` holds 7 rows with plain numeric ids such as `82013`), so the walk reaches the leaf and
the leaf rejects it.

Two candidate causes, both visible in the declared access path
(`/v2/Rounds/{roundId}/ApplicationReports`, alternates `/v2/Rounds/{roundId}/JudgeReports` and
`/v2/Programs/{programId}/SessionReports`):

1. **`InjectParentID` mis-substitutes across parameter names.** Its own doc comment says it "returns null
   when a path template var is present but unset (so an alternativePath that uses a different var is
   skipped, not mis-substituted)" — but the code does the opposite: after the declared `{roundId}` misses,
   a fallback fills *any single remaining `{var}`* with the same id, so
   `/v2/Programs/{programId}/SessionReports` is issued with a **roundId** in the programId slot. Comment and
   code disagree, and the code is the wrong one.
2. The `ApplicationReports` endpoint may need a query parameter this connector does not send.

Cause 1 was real and is fixed: `InjectParentID` now matches its comment, so
`/v2/Programs/{programId}/SessionReports` is skipped (`PATH_SKIPPED_PARAM_MISMATCH`) instead of being issued
with a roundId in the programId slot. The read path also quotes the vendor and names the URL actually
issued, because a bare `HTTP 400` says nothing about which of three declared paths failed.

Cause 2 is **ruled out against the vendor's own contract.** OpenWater publishes a swagger document at
`https://api.secure-platform.com/swagger/v2/swagger.json` (92 paths, unauthenticated). `GetApplicationReports`
is declared as:

```
GET /v2/Rounds/{roundId}/ApplicationReports
  roundId   path    required  integer(int32)
  pageIndex query   optional  integer(int32)
  pageSize  query   optional  integer(int32)
  X-ClientKey / X-ApiKey  header required;  X-OrganizationCode  header optional
```

That is exactly what this connector issues, with exactly the headers `BuildHeaders` sets, and round ids that
are int32 (`82013`). `JudgeReports` and `SessionReports` are identical in shape. **There is no missing
parameter** — the request is well-formed, and a 400 is OpenWater declining *that particular round*
(judging-only rounds, programs without sessions, ids outside the token's scope). The swagger declares only a
200 response, so the refusal is not documented and cannot be predicted from the catalog.

**The actual defect is therefore what the 400 did to the walk, and that is what is fixed.** `PaginateLeaf`
threw on any non-2xx, and `FetchViaAccessPath` calls it once per parent — so the first refused round
discarded every *other* round's reports and the object returned zero records with `FETCH_ABORTED_INCOMPLETE`.
One parent the vendor will not answer for is not the object being unfetchable.

Now: a 4xx inside a parent walk is returned rather than thrown, the walk continues, and the refusal is
recorded against its parent as `LEAF_REQUEST_REJECTED` (naming the rejected parent ids, the counts per
status, and the vendor's words). Three guards keep that from becoming a new silence — if **every** request
was refused it still throws (a whole-endpoint failure is not a clean zero); a **5xx** still throws, since a
server fault is not parent-scoped; and `ZERO_LEAVES` is suppressed when any parent was refused, because a
partial pull must never be described as the vendor having nothing to return. 401/403 keep their existing
`LEAF_FORBIDDEN` treatment.

Three regression tests cover the three behaviours (44/44 in `OpenWaterConnector.test.ts`).

**Proven live.** Read-only run `847A4E5E` (2026-08-05, same client tenant) walked all 7 rounds and created
**68 `Report` rows** — an object that had never returned a single row. Every row carries `roundId 82013`: one
round holds this tenant's reports and the other six answered 200 with nothing, which is the correct outcome
and is now distinguishable from the failure it used to look like. The pull also drove this connector's first
schema evolution — the engine promoted the walk's `roundId` tag out of custom-overflow into a real
`Reports.roundId` column (`sync.schema_update`, `restartRequiredForGraphQL: true`).

**One limit, stated rather than glossed:** no round returned a 400 on that run, so `LEAF_REQUEST_REJECTED`
itself was not exercised live — it is covered by three unit tests only. The 400 was never reproducible on
demand (the swagger declares no 4xx response for this route), so the honest position is that the object is
proven and the guard is unit-proven. If a future run does record a rejection, the warning now carries the
round ids and the vendor's own message, which the original bare `HTTP 400` did not.

---

## 3. The e2e harness shrinks this connector's coverage denominator by 8 (harness, not connector)

`connector-e2e-harness.mjs` exempts an object from the must-test coverage denominator when its `APIPath`
byte-equals one of its own Create/Update/Delete paths, on the stated premise that this "never exempts a
genuine read endpoint (a listable object's APIPath differs from its write paths)".

**That premise does not hold for ordinary REST collections.** `GET /v2/Users` lists and `POST /v2/Users`
creates — correctly the same URI. On this connector the rule fires on eight objects (Application,
JudgeTeam, ScheduleDay, ScheduleItem, ScheduleRoom, ScheduleTimeSlot, Session, User), reports them as
`keylessSkipped: 8`, and drops `syncableObjects` from 25 to 17. Two of the eight are the **largest proven
objects on the connector** (`User` 2,106 rows, `Application` 1,935) — they are as listable as anything here.

Consequences, both bad in the same direction: the artifact says "keyless" about objects that all declare a
primary key (verified in `__mj.IntegrationObjectField` — all 25 objects, no exceptions), and the
`untestedSyncable` gate can never fire for those eight, so a thin fixture that skipped them would still
read green.

**Fix should:** distinguish a write-only sub-resource from a REST collection by whether the object has a
real list capability (pagination type, or a successful list probe), not by URI equality. The existing
pagination guard on the get-by-id heuristic immediately above it is the right shape — all eight objects
here are `PaginationType='PageNumber'`, which is already sufficient to tell them apart.

This is harness-side (`packages/Integration/connectors/test/`), not connector-side, so it is recorded here
rather than fixed here. `docs/SUPPORT.md` states the honest 10-of-25 rather than the harness's 10-of-17.

---

## 4. Discovery is declared-only — a new vendor object is invisible until someone updates the catalog

`DiscoverObjects` returns the metadata catalog rather than probing the vendor, so this connector cannot
report an object OpenWater added after the catalog was authored. Nimble AMS is the fleet's counter-example
(authoritative live Salesforce describe; 32 declared → 37 objects with rows).

Not a defect today — it is an explicit design choice and `DiscoveryIsAuthoritative` reports it honestly, so
nothing downstream is misled. It is a ceiling: coverage on this connector can only ever be as current as
the last catalog edit.

**Fix should:** probe the v2 API's own route surface during discovery and report unknown collections as
new objects, or state in the connector's description that the catalog is the contract.

---

## 5. The catalog still advertises a dead host

`NavigationBaseURL` is `https://api.getopenwater.com`. The working tenant reaches
`https://api.secure-platform.com`. The field is display-only, so nothing fails — but it is the URL a human
is shown when they ask where their data comes from, and it points at nothing.

**Fix should:** carry the host from the connection's own configuration rather than a constant, or set the
constant to the live host.

---

## 6. The first sync after an apply can run an object with **zero field maps** (engine, not connector)

New on run `847A4E5E` (2026-08-05). `ApplicationCategory` fetched its 43 records correctly and then failed
**all 43 writes**:

```
sync.entity-map.start  ApplicationCategory  phase=pull-detail  fieldMapsCount: 0  fieldMaps: []
sync.record.error      [ApplicationCategory] Failed to create Application Categories record:
                       Error creating new record, no rows returned from SQL
sync.entity-map.complete  recordsProcessed 43  recordsErrored 43
```

With no field maps the engine has nothing to map onto, so every value fell through to
`__mj_integration_CustomOverflow` (`{"id":6067,"name":"ACR Master Designation","code":"01","programId":"102013"}`
— the payload is plainly correct), every declared column went in as `NULL`, the primary key came out null, and
the insert returned no rows. It is the same downstream shape as the Postgres `syntax error at or near ","`
class: an empty record id, arriving from a mapping gap rather than a missing PK declaration.

**It is not the connector.** The connector logged `recordCount: 43` for that batch, and the identical fetch on
the very next run — `fieldMapsCount: 5` — skipped all 43 on content-hash against rows already in
`openwater.ApplicationCategory`. Nothing about the connector, the catalog or the credentials changed between
the two runs; only the field maps the engine had. `Report` shows the same skew one notch smaller: 2 field maps
on run 1, 3 on run 2. Both objects are parent-walked, and both are missing exactly the field the walk *tags*
onto the record (`programId`, `roundId`) — the field the engine promotes out of overflow rather than one
declared in the catalog. So the two runs disagree about a set the apply step is still settling.

Nothing was lost here (run 2 reconciled), but a first sync is exactly when a customer is watching, and the
failure mode is 43 red records on a connector that is working.

**Mitigated on the catalog side, which removes the trigger.** The skew existed because the walk tag was the one
field arriving *undeclared* — the engine had to discover and promote it, so run 1 and run 2 genuinely held
different field-map sets. All nine walked objects now **declare** the parent id they are tagged with
(`programId` / `roundId` / `fundId`), shipped as `V202608050910__openwater__DeclareParentWalkTagFields` (+ `.pg`
twin), so it is a mapped column from row 1 and there is nothing to promote. That does not fix the engine bug —
a zero-field-map map should still refuse rather than error 43 times — but the specific path that produced this
run's 43 failures is closed.

**Fix should:** make a Pull entity map with **zero** field maps a refusal, not an attempt — an object whose
every value would land in overflow cannot produce a keyed row, so erroring 43 times is strictly worse than
declining once with a reason. Belongs upstream in the engine's sync path (`@memberjunction/integration-engine`),
which is why it is recorded here rather than fixed here.

---

## 7. A declared `Integer` foreign key becomes `NVARCHAR(MAX)` and is then silently un-indexable (engine, not connector)

Found by reading the shipped schema in `MJ_CT48` rather than the code. Of the **25** declared soft foreign keys
in this catalog, exactly **17 carry an `IDX_AUTO_MJ_FKEY_*` index and 8 do not** — and the 8 are precisely the
columns that landed `NVARCHAR(MAX)`:

| Table | Rows | Unindexed FK columns |
|---|---|---|
| `openwater.Evaluation` | 7,251 | `programId`, `roundId`, `applicationId` |
| `openwater.Application` | 1,935 | `programId`, `userId` |
| `openwater.DeletedApplication` | 1,751 | `programId`, `applicationId`, `userId` |

Those are the three largest tables in the schema, and every join a consumer would write across them — an
application to its program, an evaluation to its application — is a scan over `NVARCHAR(MAX)`. Every **sized**
column that declares a relation IS indexed, so the correlation is exact: **width, not relation, decides whether
the FK index appears.**

**The chain, each link verified against the live database:**

1. The catalog declares these fields `"Type": "Integer"` with **no `Length`** (they are vendor integer ids, so
   `Integer` is the honest declaration).
2. The schema builder maps a declared `Integer`/`integer` with no length to **`NVARCHAR(MAX)`**. (Proven by
   comparison in the same database: an unsized `String`/`string` becomes `NVARCHAR(812)`, and columns the engine
   promotes out of `__mj_integration_CustomOverflow` are always sized — 255 or 812. Only declared-unsized-Integer
   reaches MAX.)
3. CodeGen emits `IDX_AUTO_MJ_FKEY_<table>_<column>` for every field with a `RelatedIntegrationObjectID`.
4. **SQL Server cannot index an `NVARCHAR(MAX)` column** (a key column is limited to 900 bytes), so the index is
   skipped.
5. Nothing reports step 4. The migration succeeds, the relation row is present and correct in
   `__mj.IntegrationObjectField`, the platform draws the relationship in its DAG viewer, and the index simply is
   not there. There is no warning in any run log, no failed migration, no row anywhere that says so.

**Fix must** do one of two things, and the first is better:

- **Give `Integer` a sane default width** in the schema builder (an integer id needs ~20 characters, not
  1,073,741,823) — or honour the declared type as an actual integer column. Either makes the FK indexable.
- **Failing that, refuse silently-lossy FKs loudly**: when a field carries a relation and its column cannot be
  indexed, emit a warning naming the table, column and reason. A soft FK that cannot be indexed is a
  performance cliff sold as a relationship.

This is engine/CodeGen behaviour (`@memberjunction/integration-engine`, `IntegrationSchemaSync` and the CodeGen
index emitter), so it is recorded here rather than fixed here.

**What was done connector-side, deliberately, and why it is not `Integer`:** the nine walk-tag fields added for
item 6 declare `"Type": "String"` with no `Length`. The instinct was `Integer`, and checking the database first
is what stopped it: nine more unsized `Integer` FKs would have been nine more unindexable `NVARCHAR(MAX)`
columns on tables that will grow, and worse, two of the three already existed as engine-promoted **sized**
columns (812 and 255) — declaring them `Integer` would have *widened working columns to MAX* and removed
indexes that are there today. Unsized `String` lands at `NVARCHAR(812)`: sized, indexable, and never a shrink of
an existing column. Once this item ships, those nine can be re-declared `Integer` honestly.
