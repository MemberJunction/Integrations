---
"@memberjunction/connector-nimble-ams": patch
---

`DiscoverObjects` now throws a diagnosable error instead of silently returning an empty list when
Salesforce's global describe response doesn't match the Nimble AMS scope (standard objects
`Account`/`Contact`, or the `NU__`/`NUINT__` managed-package namespace).

Observed live: a connection whose credentials authenticate fine (`TestConnection` passes) but whose
Salesforce org does not have the Nimble AMS managed package installed reported "0 tables" with no
error anywhere — indistinguishable from a genuinely empty source. For an operator who holds only API
credentials and cannot log into the Salesforce org directly to check Setup → Installed Packages, that
silence was a dead end.

Two distinct cases are now surfaced:
- Salesforce returned object metadata, but none of it matched the Nimble AMS scope — almost always
  means the managed package isn't installed in this org, or the credentials point at the wrong org.
- Salesforce returned no object metadata at all — a different, more fundamental problem (API version,
  org-wide describe restriction), not a missing-package question.

No change to matched-object behavior — a normal org with Nimble AMS installed sees identical results.
