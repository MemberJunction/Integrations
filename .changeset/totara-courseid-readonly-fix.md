---
"@memberjunction/connector-totara": patch
---

fix(totara): parent-scoped `courseid` must be writable so the sync can persist it

The parent-iteration fetch injects the parent FK (`courseid`) into each child record of the parent-scoped objects (Course Contents, Course Enrolment Methods, Enrolled Users), but those `courseid` fields were declared `IsReadOnly: true`. CodeGen omits read-only fields from the create/update stored procedures, so `@courseid` was not a sproc parameter and every save failed with `@courseid is not a parameter for procedure spCreateCourse_Contents` — 0 rows persisted despite a successful fetch.

Flip those `courseid` fields to `IsReadOnly: false` (this is a read-only *pull* connector, so the field is written into MJ, never sent to the vendor). Read scope is unchanged — full-record pass-through and the never-shrink sample-union still surface every field; this only makes the injected parent FK a write column.

Live-verified against a real Totara tenant: Course_Contents 0 → 2,615 rows, Course_Enrolment_Methods 0 → 3, alongside Courses 424 / Cohorts 97 / Course_Categories 66 (full-catalog pull).
