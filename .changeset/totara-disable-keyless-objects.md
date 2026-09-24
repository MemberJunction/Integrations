---
'@memberjunction/connector-totara': patch
---

Four objects the vendor exposes without any derivable key are now Disabled instead of offered.

`Course Completion Status`, `Activity Completion Status`, `Grade Items` and `Course Grades Overview`
declare fields but no primary key, and none can be given one honestly: their wsfunctions are
per-(course, user) or per-user readers with no row identity of their own, and two of the four could only
be walked per course-user pair (428 x 24,682 requests on the proving site). `docs/SUPPORT.md` has called
them "keyless by design" since 2026-08-05 and no entity map has ever existed for them.

What was wrong was not the declining but the offering. An Active keyless object either costs the soft-PK
classifier a per-tenant inference at every discovery, or lands `entity.skipped-no-pk` while the picker
still shows it as data that could arrive. A Disabled object is neither inferred against nor offered. One
delta migration (paired T-SQL and PostgreSQL) sets the four rows to `Disabled` by their seeded IDs.

This is the connector-side half of the new read-only scope of the fleet primary-key gate
(`scripts/lint-writable-pk.mjs`), which exempts non-Active objects for exactly this reason.
