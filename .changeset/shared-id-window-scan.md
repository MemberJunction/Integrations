---
'@memberjunction/connector-id-window-scan': minor
'@memberjunction/connector-totara': patch
---

New shared helper `@memberjunction/connector-id-window-scan`, and Totara's id-window scan moves into it.

**Why it is shared.** The failure it solves is not Totara's. An object declared with no pagination is read in
one request; on a large tenant that request cannot finish inside the engine's `FetchChangesMs` (30000ms), the
batch is killed, and **a killed batch persists nothing** — the object lands zero rows while its entity map
reports success. `node scripts/audit-unlistable-objects.mjs` finds **765** one-shot readers across the fleet
today, **235** of them named like tables whose size tracks the tenant's size. Every one of those is the same
bet Totara `Users` lost, and none of them should have to rediscover the three non-obvious parts of the fix:

- **The call bounds itself in time, not just each request.** Several bounded windows in one call can overrun
  the budget together and be killed with nothing — the original defect wearing a different hat. `budgetMs`
  (default 20000, under the kill) stops the call and returns partial progress with its cursor
  (`ID_WINDOW_BUDGET_STOP`).
- **One unreadable record costs one record, not the object.** Where a vendor validates its own response per
  record, a single bad row fails the whole call — and since a failed window (correctly) is not an empty one,
  the cursor cannot advance and the scan re-requests it forever (observed live: 61 identical failures, 0 rows).
  Failed windows are bisected to single ids; an id that fails alone is skipped with `ID_WINDOW_RECORD_SKIPPED`
  naming it.
- **Coverage is never traded for speed.** The cursor advances only over ids actually examined, and stopping on
  the past-the-end heuristic always emits `ID_WINDOW_SCAN_END` with the range covered.

The helper is vendor-agnostic — it knows nothing about HTTP, auth, or record shape. A connector supplies
`FetchWindow(ids)` (which must THROW on vendor errors, since that is the signal bisection reads) and maps the
raw rows it gets back. Following the `connector-schema-merge` precedent: one function, no class, no base —
connectors import it, they do not extend anything new.

**Bug fixed in the move: `ID_WINDOW_SCAN_END` always reported `highestIdSeen: 0`.** The value was tracked per
call, but the call that ENDS a scan is by construction the all-empty one — so the field read 0 on exactly the
warning that needs it (observed live reporting `highestIdSeen: 0` immediately after landing 24,682 users). It
now rides the resume cursor, which gains a third part: `"<nextStartId>|<emptyRun>|<highestIdSeen>"`. Two-part
cursors written by an older build still parse, so an in-flight scan resumes rather than restarting.

Totara keeps its behaviour exactly — it now supplies only the Moodle-specific "turn these ids into one RPC
call" and the record mapping — and sheds ~200 lines. Verified live read-only against a production LMS after
the refactor.
