---
'@memberjunction/connector-netforum-enterprise': patch
---

Stop spending the xWeb fault budget re-learning the same answer.

xWeb counts **faults, not calls**, against `MethodsFaultLimitPerDay` (default 100 per user+IP), and
it does not auto-reset — a vendor clears it by hand. 1.6.1 retries `GetQuery` with an explicit
column list after the empty list faults, which is correct once and ruinous repeated: it re-learned
the tenant's default was unusable on every call, so a tenant whose default resolves to `*` spent one
fault per object. 888 objects on a live tenant is >=888 faults against a budget of 100 — enough to
lock the account mid-discovery, twice.

`FetchChanges` now remembers, per `CompanyIntegration`, that the default list is unusable, and leads
with the explicit list from then on: ~888 faults becomes 1.

Deliberately narrow, so a healthy tenant cannot regress. It only reorders two requests that were
already going to be sent in sequence, and only when an explicit list exists; with nothing better to
send it falls through to the original empty request unchanged. netFORUM configures the default list
*per object*, so an object whose own default is fine still gets its normal request even on a tenant
where others are not. The post-fault retry is retained — the first call on a connection still learns
by faulting, and that retry is what keeps that object from failing outright. The latch is set only
when the empty list is what the door rejected, so a declared `Configuration.columnList` drawing the
same fault keeps surfacing per call instead of silently narrowing what later objects send.
