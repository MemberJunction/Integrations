---
"@memberjunction/connector-growthzone": patch
---

Mark MembershipStatusLookup and MembershipChange as detail-only (listSupported:false, with gap notes). Both are structurally unlistable — {defaultMembershipStatus} is a configured value and {changeType} is an enum with no parent object; two vars behind a single parentObjectName trip the engine's PARENT_CYCLE guard. They previously sat Active while silently fetching zero records.
