---
'@memberjunction/connector-totara': patch
---

The parent walk had no real deadline, retired courses it had failed to read, and could only resume one lane.

Three defects in the same code path, found by splitting live read-only run `9200B480` (`Enrolled Users`, 8.6 h,
208 batches, 50,608 records) by batch duration instead of trusting its percentiles. **193 healthy batches read
48,720 records (96.3%) in 0.92 h at 68 ms/record; 15 pathological batches read 1,888 records (3.7%) in 3.30 h at
6,296 ms/record.** So 3.7% of the records took 78% of the fetch time, and 31 of the 207 cycles took 84% of the
wall clock. The p50 batch (17,438 ms) is inside budget and says nothing about where the run went. The run was not
slow because the vendor is slow.

**1. The rate-limit wait sat outside the deadline.** `await ctx.RateLimitAcquire()` was not passed through the
step timer, so its wait never entered `slowestRequestMs`, and nothing re-checked the clock afterwards. A throttled
walk therefore blew its own budget without bound: the engine measured single `Enrolled Users` calls at up to
**1,063,987 ms against the 20,000 ms budget** the connector believed it was honouring — 53×, and well past the
engine's own 30,000 ms `FetchChangesMs` kill, which discards the whole call. The acquire is now timed, and the
request itself is gated on the budget rather than only the next loop turn. The one exemption is the first request
of the first parent, which must always go out or the call makes no progress at all. A deadline that only sees the
awaits it happens to wrap is not a deadline.

**2. A transient failure retired its parent — silent data loss behind a green run.** Every caught error ended with
`examined.add(index)`, which marks the parent "nothing left here" and lets the cursor advance past it. For a
permission refusal that is right: the token will not be granted mid-run. For a 25,000 ms read timeout it is data
loss. Run `9200B480` aborted **24 requests** that way, across 24 distinct courses at mostly shallow offsets
(including `courseid=1 (offset 18850)`), each retiring a course whose enrolments had not been fully read — and the
run reported success. Transport faults (read deadline, `ETIMEDOUT`/`ECONNRESET`/`ECONNREFUSED`/`EAI_AGAIN`, socket
hang up, 5xx) now keep the parent's offset and count a consecutive-failure attempt on the cursor. The count is
bounded by `parentScope.maxParentAttempts` (default 3) so this cannot become the opposite bug — the `Users`
`[invalidresponse]` deadlock was 61 identical failures with no forward progress possible. On reaching the limit
the parent is passed over with a new **`PARENT_ABANDONED`** warning that names the parents, states their records
are not synced, and quotes the vendor. The walk never gives up quietly. Permission refusals still retire
immediately, since retrying them costs budget and buys nothing.

**3. The cursor now resumes every lane, so paged walks keep their concurrency.** The keyset cursor could name
exactly one mid-parent offset, and only for the head of the covered prefix — pointing it anywhere else would claim
a budget-skipped parent as done. That is what forced paged walks serial in
`.changeset/totara-paged-walk-throughput-and-ordering.md`: it stopped the 1.74× re-read by removing the
parallelism, a poor trade on an object whose healthy cost is 68 ms/record and which has never once been read to
completion. The cursor gains an extended wire form — `{"a":"<id>","p":{"<id>":<offset>},"f":{"<id>":<n>}}`, with
`a` the finished-through parent, `p` any parent's mid-parent offset and `f` its consecutive transient failures —
and both legacy forms (`"<id>"`, `"<id>#<offset>"`) are still parsed, so an in-flight walk resumes rather than
restarts. With every lane's progress durable, `parentConcurrency` is back to `ctx.MaxConcurrency`.

Ordering of the cursor's guarantees is unchanged: it still advances only over the contiguous examined prefix, and
state belonging to parents before that prefix is dropped rather than resuming into covered ground.

Also corrected in this pass: `docs/REQUIRED-FIXES.md` item 7 claimed a full pull needs ~4 h of vendor time, from
scaling 29,002 rows by 428/64 courses — which double-counts the already-complete site course. The site is ≈93,000
enrolment rows, so **≈1.8 h** at the healthy rate. Its "enlarging the page buys nothing" was also too strong:
larger pages do not reduce per-record vendor cost, but they do reduce how many independent chances a run takes on
the intermittent stall above.

Five regression tests, including the multi-lane cursor round trip and the transient-retry-then-abandon sequence
(68/68 in `TotaraConnector.test.ts`).
