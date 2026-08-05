---
'@memberjunction/connector-id-window-scan': patch
---

Unreadable ids come in blocks, so the scan stops re-deriving the same bisection for each one.

Bisection is what stops a single unreadable record from costing the whole object, and it isolates the
first bad id correctly. What the live run exposed is that it then starts over for the *next* id, and the
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
