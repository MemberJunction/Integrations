---
'@memberjunction/connector-elevate': patch
---

Isolate an unusable column by bisection instead of discarding the whole batch.

Verification asks the door for every runtime-discovered column in one query. When it refuses, the
connector drops the field the vendor NAMES and retries. This door names nothing: a bad field name
comes back as a bare `HTTP 500` with no message, so `Classification.UnknownField` is null, and the
whole batch was abandoned on the first refusal.

Live consequence on a tenant: 32 discovered columns on one object and 26 on another, verified NONE,
every run — the same few unusable names poisoned the same batch each time. The objects still synced
on their declared columns (2 and 4 respectively), so the loss was invisible: no error, no missing
data, just a permanently narrow read surface.

The names are not junk. `LearnLabels` reads the door's own `response.labels` dictionary, which mixes
queryable columns with relation and rollup keys (`user`, `product`, `stats`, `count`). Those are not
read selectors, and nothing in the name distinguishes them — the only way to know is to ask.

So the batch is now halved on an unattributed refusal, recursively. A subset of one that still fails
is the offender and is remembered as rejected, reaching the same terminal state a named rejection
does, by isolation rather than by the vendor's cooperation. Every column the door accepts is
verified. Recursion depth is bounded, so a door failing for reasons unrelated to field names (an
outage mid-verification) costs a bounded number of requests and leaves everything UNVERIFIED rather
than rejecting good columns one at a time.

The invariant that made this safe to change is unchanged and still tested: no request that reads
data ever carries an unproven name, so a bad label can never cost a row.
