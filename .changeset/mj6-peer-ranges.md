---
"@memberjunction/connector-business-central": minor
"@memberjunction/connector-schema-merge": minor
---

Allow MemberJunction 6.x as a peer.

Both packages capped their MJ peers at `<6.0.0`. Under pnpm with `auto-install-peers`, a 6.x host
therefore resolves a **second** copy of `@memberjunction/core` to satisfy the connector, and two copies
of core in one process is the failure that produces thousands of unrelated-looking type errors.

Widening only the connector would not have been enough: `connector-schema-merge` is a runtime
dependency of the Business Central connector and carried its own `<6.0.0` ceiling, so the duplicate
would have come back transitively. Both ceilings move to `<7.0.0`.

The floor is unchanged, so 5.x consumers are unaffected.

Basis for the claim: the BizApps Accounting team reported running this connector against an MJ
6.1.0-edge host, with the peer ranges as the friction rather than the code. This range widening
reflects that evidence — it is not a claim that 6.x is separately regression-tested here.
