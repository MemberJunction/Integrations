---
"@memberjunction/connector-pheedloop": minor
---

Declare parent objects for all 20 event-scoped list fetches (Configuration.parentObjectName="Events"; SessionRegistration uses the per-var parentObjectNames map with Sessions). These objects previously emitted PARENT_UNRESOLVED and silently fetched ZERO records — the engine's §19 contract resolves template vars by authored metadata only. Also widens Members.about to 4000 (live bios up to 2,595 chars were skipped by the 255 default, skipped-not-truncated) and deactivates Reports (/reports/{reportCode}/ has no parent object supplying report codes — not list-syncable).
