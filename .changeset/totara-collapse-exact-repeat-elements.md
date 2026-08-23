---
"@memberjunction/connector-totara": patch
---

Collapse exact-repeat elements when exploding a derived collection.

Measured on a live tenant: `Enrolled_User_Roles` held 54,119 rows for 42,519 distinct keys —
11,632 excess. All 11,200 duplicate key groups were byte-identical on every captured column and
were written within the same second, i.e. the source listed the same `roleid` twice for one
enrolment (the same role held in more than one context) inside a single batch. No cross-batch
identity check can catch that, and the rows re-inserted on every sync, so the excess grew each run.

A child row is a projection of (parent key + element), so two byte-identical projections are one
fact restated. `ExplodeCollection` now emits a set: identical rows collapse, and a row differing in
ANY field is kept, so a genuinely distinct fact can never be lost. The collapsed count is reported
as a `DERIVED_ELEMENTS_COLLAPSED` warning rather than being silent — if a field that would
distinguish two elements is undeclared or removed by `dropFields`, that warning is the signal.
