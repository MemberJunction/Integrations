---
"@memberjunction/connector-totara": patch
---

Bound the discovery sampler.

`IntrospectSchema` sampled every object through an unbounded `Promise.all`, issuing one live request per object simultaneously and honouring neither `MaxConcurrency` nor the rate limiter, while the same class deliberately runs its `FetchChanges` walk through a bounded-lane runner. From a single Node process that is a burst large enough to stall the event loop: cheap platform reads then time out and the per-env circuit breaker reports the whole workspace unavailable. Now routed through the existing `runParentBounded` helper at a fixed ceiling of 4 — `IntrospectSchema` receives no `FetchContext`, so there is no `MaxConcurrency` to read at that call site. Ordering and best-effort semantics are unchanged.

(The two Nimble AMS fixes that shipped alongside this — watermark resolution against real fields, and the 120s discovery deadline — moved to the consolidated Nimble hardening PR.)
