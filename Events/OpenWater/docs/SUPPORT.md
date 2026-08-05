# OpenWater — Supported & Proven

> **Evidence tier:** 🥇 Client-DB-live (real client tenant, production data)  ·  **Last verified:** 2026-08-05  ·  **Proof DB(s):** MJ_CT48

## What this connector supports

**25 objects** declared across **175 fields** (source: `metadata/integration/.openwater.integration.json`). 10 declare a write path; 15 are read-only (pull). 11 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| Application | ✓ | `CD` | ✓ |
| ApplicationCategory | ✓ | — (read-only) | — |
| BillingLineItem | ✓ | — (read-only) | ✓ |
| DeletedApplication | ✓ | — (read-only) | ✓ |
| DeletedSession | ✓ | — (read-only) | ✓ |
| Evaluation | ✓ | `U` | ✓ |
| Fund | ✓ | — (read-only) | — |
| FundTransaction | ✓ | — (read-only) | — |
| Invoice | ✓ | — (read-only) | ✓ |
| JudgeAssignment | ✓ | `CD` | — |
| JudgeRecusal | ✓ | — (read-only) | — |
| JudgeTeam | ✓ | `C` | — |
| OtherSessionItemType | ✓ | — (read-only) | — |
| Payment | ✓ | — (read-only) | ✓ |
| Program | ✓ | — (read-only) | ✓ |
| Refund | ✓ | — (read-only) | ✓ |
| Report | ✓ | — (read-only) | — |
| Rounds | ✓ | — (read-only) | — |
| ScheduleDay | ✓ | `CUD` | — |
| ScheduleItem | ✓ | `CD` | — |
| ScheduleRoom | ✓ | `CUD` | — |
| ScheduleTimeSlot | ✓ | `CUD` | — |
| Session | ✓ | `CD` | ✓ |
| SessionType | ✓ | — (read-only) | — |
| User | ✓ | `CU` | ✓ |

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

| Object | Label | Rows (DB-verified) | Which DB |
|---|---|---|---|
| Evaluation | Proven | 7,251 | MJ_CT48 |
| User | Proven | 2,106 | MJ_CT48 |
| Application | Proven | 1,935 | MJ_CT48 |
| DeletedApplication | Proven | 1,751 | MJ_CT48 |
| JudgeAssignment | Proven | 89 | MJ_CT48 |
| ApplicationCategory | Proven | 43 | MJ_CT48 |
| Report | Proven | 68 | MJ_CT48 |
| JudgeRecusal | Proven | 9 | MJ_CT48 |
| Rounds | Proven | 7 | MJ_CT48 |
| Program | Proven | 5 | MJ_CT48 |
| SessionType | Proven | 2 | MJ_CT48 |

**Total proven rows: 13,266** across **11 of 25 declared objects.**

> **This section previously read "5 rows across 1 object", and that was the doc lagging the evidence, not
> the connector lagging the fleet.** A live full-catalog run (`3BA35740`) against a real client tenant
> processed **13,198 records with 0 failed** (13,194 succeeded, 4 skipped by the row-hash), and the counts
> above are that run read back out of `MJ_CT48` table by table. The stale figure came from a generator run
> against a DB that had since been torn down. `Report`'s 68 rows arrived later, on run `847A4E5E`
> (2026-08-05), which is the run that proved the parent-rejection fix — see the `Report` block below.

**Declared but 0 rows landed: 14 of 25.** Every one of them was fetched — **there are no keyless objects
on this connector.** All 25 declare exactly one primary key (`JudgeAssignment` and `JudgeRecusal` declare a
two-part key), verified against the deployed `__mj.IntegrationObjectField` rows, so all 25 are syncable and
all 25 got an entity map.

| Cause | Objects | What it means |
|---|---|---|
| **Parent layer had nothing to walk** — `ZERO_PARENTS` | FundTransaction | The `Fund` door returned no records, so there was nothing to enumerate transactions under. Stated by the connector, not inferred. |
| **Flat collection genuinely empty** — `EMPTY_COLLECTION` | BillingLineItem, DeletedSession, Invoice, JudgeTeam, Payment, Refund, Session | This client runs awards/judging, not ticketed sessions or invoiced billing — the finance and session halves of the product are unused here. Each request succeeded and returned nothing. |
| **Token is not permitted the endpoint** — `LEAF_FORBIDDEN` | Fund | `/v2/Funds` answers **HTTP 401**. A credential-scope limit, not an empty collection — and it explains `FundTransaction`'s `ZERO_PARENTS` directly above, which was previously a dead end. |
| **Parents walked, every leaf empty** — `ZERO_LEAVES` | OtherSessionItemType, ScheduleDay, ScheduleItem, ScheduleRoom, ScheduleTimeSlot | Each walked all 5 programs over 5 requests and every one returned zero. The paths resolved; this tenant has no scheduling data. |
| ~~**Fetch aborted on a vendor error** — `FETCH_ABORTED_INCOMPLETE`~~ | ~~Report~~ | **Resolved.** `/v2/Rounds/{roundId}/ApplicationReports` answered **HTTP 400** on the first round walked, and the connector threw — discarding every other round. On the fixed build the walk survives a refused parent, and `Report` landed **68 rows** (run `847A4E5E`, 2026-08-05). It is now in the proven table above, not this one. |

> **The run artifact's `keylessSkipped: 8` is a harness artifact, not a fact about this connector, and the
> coverage denominator it produces (17, not 25) is too generous.** The e2e harness exempts an object from
> the must-test denominator when its `APIPath` byte-equals one of its own write paths, on the stated premise
> that "a listable object's APIPath differs from its write paths". That premise does not hold for ordinary
> REST collections: `GET /v2/Users` lists and `POST /v2/Users` creates, and they are correctly the same URI.
> The eight objects it exempts here — Application, JudgeTeam, ScheduleDay, ScheduleItem, ScheduleRoom,
> ScheduleTimeSlot, Session, User — include the two largest proven objects on the connector (`User` 2,106
> rows, `Application` 1,935). Reported for the harness; **the honest coverage number for this connector is
> 10 of 25, and that is what this document states.**

> **The three unattributed zeros were the honest gap in this connector. They are now closed in code and the
> fix is proven live.** Run `3BA35740` scored `Fund`, `OtherSessionItemType` and `Report` as zeros with **no
> reason at all**, and its own verdict was *"NOT all-object proven"* because of them. The cause was a
> `console.warn`: a 401/403 leaf logged to the server console and broke out of pagination, so the object
> returned zero records behind a **successful** run. Server console output is not evidence — nobody reading
> the run artifact, the entity map, or the UI would ever see it. The connector now emits `LEAF_FORBIDDEN`
> (carrying status and path), `ZERO_LEAVES` (naming parent count, request count, and every path tried) and
> `EMPTY_COLLECTION` (a flat first page genuinely empty, no watermark in play). Changeset
> `openwater-attribute-every-zero`; four unit tests pin the four cases apart.
>
> Live read-only run **`F2644D5B`** on the fixed build, same tenant, same 13,198 records: **every one of the
> 15 zeros now carries a code** — 1 `LEAF_FORBIDDEN`, 5 `ZERO_LEAVES`, 7 `EMPTY_COLLECTION`, 1
> `ZERO_PARENTS`, 1 `FETCH_ABORTED_INCOMPLETE`. The unattributed-zero count went **3 → 0**, and the
> attribution table above is that run read line by line, not a prediction. **A zero on this connector can no
> longer be silent** — and the one that turned out to be a real defect (`Report`, HTTP 400) is a defect
> because the fix made it say so.

> **`Report` — the one zero that was a real defect — is fixed, and now proven: 68 rows.** The 400 was never a
> malformed request: OpenWater's own swagger
> (`api.secure-platform.com/swagger/v2/swagger.json`) declares `GetApplicationReports` as
> `GET /v2/Rounds/{roundId}/ApplicationReports` with `roundId` an int32 path segment, `pageIndex`/`pageSize`
> optional, and the two custom auth headers this connector already sends — exactly the request issued, with
> int32 round ids. The 400 is OpenWater declining *that round*. The defect was that one declined round threw
> and took the other six with it. A 4xx inside a parent walk is now non-fatal and attributed
> (`LEAF_REQUEST_REJECTED`, carrying the rejected parent ids and the vendor's words), while all-refused and
> 5xx still fail the object.
>
> Live read-only run **`847A4E5E`** on the fixed build walked all 7 rounds and **created 68 `Report` rows**,
> every one carrying `roundId 82013` — one round holds this tenant's reports and the other six are genuinely
> empty. The rows are in `openwater.Report` and were read back with `SELECT COUNT(*)`. The pull also produced
> the first schema evolution this connector has triggered: the engine promoted the walk's `roundId` tag out of
> custom-overflow into a real `Reports.roundId` column (`sync.schema_update`, `restartRequiredForGraphQL`).
>
> **One honest limit:** no round returned a 400 on this run, so the new `LEAF_REQUEST_REJECTED` path was not
> exercised live — it is covered by three unit tests only. What is proven live is the thing that matters: the
> object that could never return a row now returns 68.

> **The parent walk's tag is now a declared, related column — not a discovered one.** The walk already stamps
> every child with the id it was walked under, which is how all 68 `Report` rows carry `roundId 82013`. But none
> of the nine walked objects **declared** that field, so it arrived as an unknown extra: into
> `__mj_integration_CustomOverflow`, promoted to a real column only later (visible on run `847A4E5E` as
> `sync.schema_update` for `Reports.roundId`), and with **no relationship** back to the parent object even after
> promotion. All nine now declare it — `ApplicationCategory`, `OtherSessionItemType`, `ScheduleDay`,
> `ScheduleRoom`, `ScheduleTimeSlot`, `ScheduleItem`, `SessionType` → `Program`; `Report` → `Rounds`;
> `FundTransaction` → `Fund` — each with an explicit `RelatedIntegrationObjectID`, shipped as
> `V202608050910__openwater__DeclareParentWalkTagFields` (+ `.pg.sql` twin). Verified against the live catalog:
> 6 fields inserted, 3 relations back-filled onto rows the engine had already promoted, then 0/0 on re-apply, and
> **zero of the connector's 19 walk-tag fields are left without a relation.** This also removes the trigger for
> the zero-field-map failure in `docs/REQUIRED-FIXES.md` item 6, since the disputed field was in every case the
> walk tag.
>
> **They are declared `String`, not `Integer`, on purpose** — reading the shipped schema first is what caught it.
> A declared unsized `Integer` becomes `NVARCHAR(MAX)`, which SQL Server cannot index, so CodeGen's soft-FK index
> is silently skipped: **8 of this connector's 25 relations have no `IDX_AUTO_MJ_FKEY_*` index today**, and they
> are exactly the `NVARCHAR(MAX)` columns, on `Evaluation` (7,251 rows), `Application` (1,935) and
> `DeletedApplication` (1,751). That is `docs/REQUIRED-FIXES.md` item 7 — an engine defect, recorded not fixed.

> ✅ **Coverage: 11 of 25 declared.** These rows are real and DB-verified. A full-catalog live run HAS been
> executed across all 25 objects, which is what made the attribution above possible — the 14 zeros are
> accounted for, not untested.

### Push (write / bidirectional)

- **Status: Heavily experimental.** Full C/U/D is wired in the class; **no live write has been executed.**
- **Declared write surface (metadata):** 10 of 25 objects declare a substantiated write path.
- Every run recorded here was queued **read-only** — `syncDirection: 'Pull'`, no `allowWrite` — because
  this endpoint is a live client system. Bidirectional is not claimed as "works".

## Residual gap (honest)

- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested (the run applied `SyncConcurrency 1`,
  `RateLimitTokensPerSec 3`, deliberately gentle against a client endpoint).
- **No live object discovery.** This connector is declared-only: `DiscoverObjects` returns the metadata
  catalog rather than probing the vendor, so a new object appearing in OpenWater will not show up until the
  catalog is updated. Nimble AMS is the fleet's counter-example (authoritative live describe).
- **Coverage:** 11 of 25 declared objects have proven rows. The other 14 fetched successfully and are
  attributed above — not untested, and not keyless.
- **The first sync after an apply can run an object with zero field maps.** On run `847A4E5E`,
  `ApplicationCategory` fetched its 43 records correctly but the engine logged `fieldMapsCount: 0` for that one
  entity map, so every value fell through to `__mj_integration_CustomOverflow`, the primary key came out null,
  and all 43 creates failed. The very next sync logged `fieldMapsCount: 5` and skipped all 43 on content-hash —
  no data was lost and nothing about the connector changed. This is an engine/apply-ordering defect, not a
  connector defect; it is written up in `docs/REQUIRED-FIXES.md` item 6. The catalog-side trigger for it — the
  walk tag arriving undeclared — is now closed (see the declared-parent-link note above).
- **8 of 25 declared foreign keys are not indexed**, and nothing anywhere reports it: they are the columns a
  declared unsized `Integer` turns into `NVARCHAR(MAX)`, which SQL Server cannot use as an index key, so the
  soft-FK index is skipped in silence. They sit on the three largest tables in the schema. Engine/CodeGen defect,
  written up in `docs/REQUIRED-FIXES.md` item 7.

---

_Capability section derived from this connector's own metadata on 2026-07-28. Proof numbers are DB ground
truth as of 2026-08-05, read directly from `MJ_CT48` (`SELECT COUNT(*)` per `openwater.*` table) after live
read-only full-catalog syncs (runs `3BA35740` and `847A4E5E`), and are re-stated verbatim — they change only
when a new live sync is run and the numbers are re-read from the database. They are never hand-adjusted._
