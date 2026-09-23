---
"@memberjunction/connector-totara": patch
---

Parent-scoped `courseid` is writable, so the sync can persist what the fetch injected.

The parent-iteration fetch injects the parent foreign key (`courseid`) into every child record of the parent-scoped objects, but those `courseid` fields were declared `IsReadOnly: true`. CodeGen omits a read-only field from the generated create/update procedures, so there was no parameter for the injected value to land in and every save failed with `@courseid is not a parameter for procedure spCreateCourse_Contents` — a successful fetch that persisted nothing.

This is a read-only *pull* connector: the field is written into MemberJunction and never sent back to Totara, so making it writable changes nothing about what the connector asks the vendor for. Read scope is unchanged — full-record pass-through and the never-shrink sample union still surface every field.

Live-verified against a real Totara tenant when this was first found: Course_Contents 0 to 2,615 rows and Course_Enrolment_Methods 0 to 3, alongside Courses 424, Cohorts 97 and Course_Categories 66 on a full-catalog pull.
