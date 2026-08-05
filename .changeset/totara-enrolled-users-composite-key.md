---
'@memberjunction/connector-totara': patch
---

`Enrolled Users` was keyed on the user id alone, so enrolments silently overwrote each other.

`core_enrol_get_enrolled_users` is read **per course** — the object is parent-scoped over
`core_course_get_courses`. A user enrolled in several courses therefore comes back once per course, each
time carrying *that course's* roles and groups. The catalog declared one key field, `id` ("ID of the
user"), marked `IsUniqueKey=1`. Every per-course row upserted onto the same key, so the last course
written won and the earlier ones were destroyed on the way in.

Live evidence (ACR, read-only, run `5E8070E2`): **26,300 records processed, 13,950 rows landed**, and
across every course the walk reached, only **2 distinct `courseid` values survived** in the table. Nothing
errored, nothing warned — the run was green and the object looked populated, which is why this sat behind
the fetch defects that were fixed first. It is the same family as those: not a failure, an untruth.

The sibling objects are the control group, and they make the diagnosis exact. `Course Contents` is walked
by the same parent mechanism in the same run and landed **2,504 rows across 408 distinct courses** — course
attribution fully intact — because its `id` is a per-record section id. `Enrolled Users` landed 13,950 rows
across **2**. Same walk, same run, same budget; the only difference is that its `id` identifies the *user*,
which recurs. Every other `parentScope` object in the catalog was swept for the same shape and is clean, so
this was the one instance, not the first of many.

The object's own metadata had the right answer written down the whole time, in
`writeFunctions.createResponseNote`: *"identity is the composite (userid,courseid)"*. And the write surface
makes the stakes concrete — `enrol_manual_unenrol_users` is wired as DELETE, and a delete keyed on user id
alone does not name the course it is unenrolling from.

Fixed in the metadata and shipped to tenants as a delta migration (both dialects), in four parts:
`parentScope.childIdField='courseid'` so the parent-id stamp is intentional rather than an accident of
`paramName` happening to be a sensible column name; `id` demoted to `IsUniqueKey=0`, which it always was in
fact; and `courseid` declared as a second `IsPrimaryKey` field FK'd to `Courses`. A two-field key is the
established shape here, not a novelty — 38 objects in the catalog already use one, including HubSpot's
association objects, which are the same join shape and likewise `IsPrimaryKey=1 / IsUniqueKey=0` on both
halves.

**The migration has two create paths, and the interesting one is the promote.** On any tenant that has
synced this object even once, discovery had *already* created a `courseid` field — as
`IsCustom=1 / MetadataSource='Discovered'`, `IsPrimaryKey=0`, and wrongly `IsUniqueKey=1`. An INSERT-only
migration would have found the row present, no-opped, and changed nothing on exactly the tenants carrying
the defect. Both branches were exercised against a live catalog: the promote on the discovered row, then
the row deleted and the create path run to rebuild it through `spCreateIntegrationObjectField` (the same
entry point the seed uses for the other 269 fields, so audit columns are the sproc's business and not
hand-written). Re-running touches zero rows.

**Operators:** this widens the key of an existing synced table. The collapsed rows cannot be recovered —
the overwritten enrolments were never stored — so the object needs one full, non-incremental pull after the
migration to repopulate the per-course rows.
