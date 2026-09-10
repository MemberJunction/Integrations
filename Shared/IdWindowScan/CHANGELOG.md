# @memberjunction/connector-id-window-scan

## 1.1.1

### Patch Changes

- 06b2b4b: Allow MemberJunction 6.x as a peer. Every connector capped its `@memberjunction/*` peers at `<6.0.0`; the ceiling moves to `<7.0.0`, and `mj-app.json.mjVersionRange` moves with it so npm and `mjdev app register` agree. Floors are unchanged, so 5.x hosts are unaffected.

  Why the ceiling is the fix on a 6.x host: pnpm's `auto-install-peers` satisfies an unmet peer range by installing a **second** copy of `@memberjunction/core`, and two copies of core in one process is the failure that surfaces as thousands of unrelated-looking type errors. Business Central hit exactly this and was widened alone (#180, then #208 for the manifest); this brings the other 56 connectors, the two private platform packages, and the shared `connector-id-window-scan` package to the same range, so the duplicate cannot return transitively through a shared dependency either. The scaffolding scripts (`new-connector`, `scaffold-openapps`, `split-into-packages`) now mint `<7.0.0` too, so a new connector does not reintroduce the cap.

  Verified at compile time, not at runtime: all 61 packages in the repo (57 connectors, the two private platform packages, the two shared packages) type-check against `@memberjunction/*@6.1.0-edge.5` — the only 6.x published at the time; there is no stable 6.x yet — with every framework `.d.ts` resolved from the 6.x install and none from 5.x. That check is `npm run check:mj-compat` (`scripts/typecheck-against-mj.mjs`), added with this change so the claim can be re-run against any MJ version. It is API compatibility at the type level; the only runtime evidence on a 6.x host remains the Business Central team's edge deployment.

## 1.1.0

### Minor Changes

- d495a0c: New shared helper `@memberjunction/connector-id-window-scan`, and Totara's id-window scan moves into it.

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

### Patch Changes

- d495a0c: Unreadable ids come in blocks, so the scan stops re-deriving the same bisection for each one.

  Bisection is what stops a single unreadable record from costing the whole object, and it isolates the
  first bad id correctly. What the live run exposed is that it then starts over for the _next_ id, and the
  next: the skipped ids were not scattered but an unbroken block (one stray at `id=2`, then `5801-5853`),
  and every window in it paid the full 25 → 12 → 6 → 3 → 2 → 1 descent again. **235 requests to skip 57
  records**, roughly a minute of a 20-second budget spent rediscovering what the previous window had just
  established.

  Once `singleStepAfterConsecutiveSkips` ids in a row (default **2**) have been proven unreadable, the scan
  stops issuing the bulk request it knows will fail and reads the range one id at a time instead. The first
  id that succeeds clears the run and the remainder of that window is fetched in bulk again — the fast path
  is the normal path the moment the block ends.

  The counter rides the **cursor**, not the call. A poison block is far longer than one call's couple of
  windows, so a per-call counter would forget it at every call boundary and pay for the first bisection over
  and over, which is most of the waste. The cursor gains a fourth part
  (`nextStartId|emptyWindows|highestIdSeen|consecutiveSkips`); shorter cursors written by an older build
  still parse, with the new part starting at zero.

  **Coverage is unchanged, and that is the point** — this is a cost fix, not a correctness one. Every id is
  still examined individually, every skip still emits its own `ID_WINDOW_RECORD_SKIPPED` naming the id, and
  `ResolvedThrough` is still the contiguous prefix actually read, so no id is stepped over unexamined. The
  one new diagnostic, `ID_WINDOW_SINGLE_STEP`, is emitted **once per call** rather than per window, because
  removing noise is half of what this fixes.

  Three tests: a poison block walks singly and returns to bulk on the first good id (with every skip still
  individually reported); the same block costs strictly fewer requests than with the optimisation disabled;
  and the run survives a call boundary, so the second call goes straight to singles instead of re-issuing a
  doomed bulk request.
