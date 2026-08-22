---
'@memberjunction/connector-openwater': patch
---

Detail walks are bounded by the caller's batch size, and resumable.

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
