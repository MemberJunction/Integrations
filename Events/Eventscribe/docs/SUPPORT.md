# Eventscribe (Cadmium) — Supported & Proven

> **Evidence tier:** 🧪 Mock-only (proven vs mock server, never live)  ·  **Last verified:** 2026-08-27  ·  **Proof DB(s):** SQL Server (`MJ_SS_E2E`, disposable)

> 🧪 **Mock-only:** every claim below was observed against a fixture-driven mock vendor server driving
> the real MJ engine into a real SQL Server database. **No live Eventscribe system has been contacted
> and no vendor rows have been written.** The reason is a credential gap, not a defect: no Cadmium
> tenant credential existed for this build. The honest ceiling is `format-verified-no-creds`.

## What this connector supports

**38 objects** declared across **658 fields** (source: `metadata/integration/.eventscribe.integration.json`).
**22 are Active**; **16 are `Status='Disabled'`** — the EdgeReg Registration family, deliberately out of
scope (see below). 27 objects carry a primary key.

### How this vendor actually works

Eventscribe is **not a conventional REST API** and modelling it as one produces a connector that
silently syncs nothing:

- Every call is **RPC over query-string**: `GET <base>?APIKey=<key>&Method=<methodName>[&eID=<eventID>]`.
  The object is chosen by the `Method` **query parameter**, not by the path.
- There are **four distinct product hosts** (`mycadmium.com`, `conferenceharvester.com` ×2,
  `conferenceabstracts.com`). Base URLs resolve **per object** from
  `Integration.Configuration.BaseURLsByFamily` — a connector that bakes one base URL fails at runtime.
- Auth is an `APIKey` **query parameter**. There is no authorization header.
- Rate limits: **1 request/second** standard, dropping to **1 request/minute** for
  `getPresentationsWithPresenters` and `getAllExhibitorsWithBooth`.
- Roughly half the objects have **no read door of their own** — they arrive nested inside a parent's
  response under a declared container key, walked via `Configuration.accessPath`.

### Object matrix

`Push` is a **capability declaration, not proven behaviour** — no write has been executed against a
live Eventscribe system. `Rows` is what actually landed in SQL Server during the mock e2e.

| Object | Rows (mock e2e) | Push (C/U/D) |
|---|---|---|
| Abstract | ✓ 5 | — |
| Account | **0** (by design — see below) | `CUD` |
| Asset | ✓ 5 | — |
| Author | ✓ 5 | — |
| Booth | ✓ 10 | `CU` |
| Exhibitor | **0** (open item — see below) | `CU` |
| ExhibitorStaff | ✓ 5 | `CU` |
| Favorite | **0** (by design — see below) | `CUD` |
| Handout | not exercised | — |
| MediaAsset | not exercised | — |
| Payment | ✓ 10 | — |
| PosterImages | not exercised | — |
| Presentation | ✓ 5 | `D` |
| Presenter | ✓ 5 | — |
| Purchase | ✓ 10 | — |
| Review | ✓ 5 | — |
| ReviewQuestion | ✓ 3 | — |
| Slide | not exercised | — |
| Submission | ✓ 5 | — |
| SubmissionAuthor | ✓ 10 | — |
| Submitter | ✓ 5 | — |
| WwAsset | ✓ 10 | — |

**15 of 18 syncable objects landed rows.** 4 further objects are keyless and were skipped by the
coverage gate rather than tested.

## Incremental sync: none

No in-scope object supports incremental sync. The platform's **only** documented incremental signal
(`watermark.startParam` / `endParam`) lives in the EdgeReg Registration family, which is out of scope.
Activating incremental therefore requires bringing EdgeReg in scope first.

## Deliberately out of scope: EdgeReg Registration (16 objects, `Status='Disabled'`)

EdgeReg is a different host, **XML over JSP**, and a different credential pair
(`AccountToken` + `ActivityToken`) — a second connector, not a family of this one. The connector
**refuses** these objects with a structured `UNSUPPORTED_WIRE_FORMAT` warning rather than guessing.
Recorded in `Integration.Configuration.OutOfScopeObjectFamilies` including the incremental-signal note,
so a future build knows exactly what activating it would gain.

## Known gaps — read before relying on this

1. **`Account` and `Favorite` sync 0 rows, correctly.** `Account.Configuration.requiresRecordKeyToRead`
   records that the vendor documents **no bulk-list door**: `getAccount` addresses ONE record by a
   caller-supplied key. The connector returns an empty batch rather than calling it unkeyed.
   `Favorite` is nested under `Account`, so it inherits that. Enumerating either needs a key set from
   a parent object or an operator-supplied id list.
2. **`Exhibitor` syncs 0 rows — OPEN, not explained.** Its door works: `getAllExhibitorsWithBooth`
   fires and every object nested under it lands rows (Booth 10, Payment 10, Purchase 10). The
   connector itself is proven correct — driving `FetchChanges('Exhibitor')` against the fixture emits
   one record per exhibitor. The loss is **downstream in the sync/persist layer**, which recorded
   `UPDATE` actions against rows that do not exist (a silent no-op). Needs engine-side investigation.
3. **Pagination unproven** for `getPresentationsWithPresenters` and siblings. The vendor states
   "pagination required" but never names the parameter, so `SupportsPagination=false` and the connector
   issues a single unpaged call. Refusing to invent a parameter name is deliberate; needs live
   verification.
4. **10 write capabilities disabled.** `Presentation` and `Presenter` (plus 3 EdgeReg objects) name
   `addUpdatePresentation` / `addUpdatePresenter` with **zero documented request-body shape**. Flags set
   false rather than inventing one.
5. **7 primary keys withdrawn as unevidenced** — e.g. `Handout.Pdf` and `Slide.Pdf` (CDN file URLs),
   `ERPurchase.BillingID` (the vendor's own sample shows `888888` twice, disproving uniqueness). Those
   objects sync without an idempotent identity until evidence exists.
6. **`NoExplicitTypeError` on MJAPI boot — NOT specific to this connector.** Running a full
   `mj codegen` against a database holding *any* connector's entities generates GraphQL resolver
   classes into `packages/MJAPI/src/generated/generated.ts` that fail to bind. The MJ hybrid-e2e
   runbook documents this as a known condition and names `salesforceAccount_`, `propfuel*`, `orcid`,
   `openwater`, `path_lms` and `growthzone` as hitting it; the prescribed remedy is to restore that
   generated file to HEAD, which is what was done here. Recorded for completeness only — it is a
   property of the shared CodeGen/MJAPI boundary, not a defect in this connector, and it is not a
   deployment blocker any more than it is for the connectors already shipped.

## Verification performed

| Gate | Result |
|---|---|
| Unit tests (this package) | **110 passed** |
| `packages/Integration/connectors` (MJ repo) | 955 passed / 26 skipped |
| Verification ladder T0–T7d | green (T7/T7b/T7c/T8 honest skips) |
| DeployPreflight | ok, 0 violations |
| RealityProbe family coverage | 5/5 families |
| Hybrid E2E (mock, real MJ engine → real SQL Server) | 15/18 objects landed rows |
| MJ deterministic integration tier | 50/54 (remaining 4 are environment, not this connector) |
| Bijection floor-check | **not obtained** — the gate could not read the 1.28 MB metadata file (harness limitation) |
