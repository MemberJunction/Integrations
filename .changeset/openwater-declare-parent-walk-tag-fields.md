---
'@memberjunction/connector-openwater': patch
---

Nine parent-walked objects carried a parent id that the catalog never declared.

The nested parent walk already tags every child with the id it was walked under — `if (parentTagName &&
r[parentTagName] == null) r[parentTagName] = parentID` — which is how all 68 `Report` rows on the live run carry
`roundId 82013` without the vendor ever sending it. That part was right. What was missing is that **not one of
the nine walked objects declared the field it is tagged with**, so a value the connector deliberately produces
arrived as if it were an unknown extra.

Two consequences, both observed live:

- **The tag landed in `__mj_integration_CustomOverflow` and only became a column later**, when the engine
  promoted it. That is the whole mechanism behind the first-sync field-map skew in `docs/REQUIRED-FIXES.md` item
  6: run `847A4E5E` ran `ApplicationCategory` with `fieldMapsCount: 0` and errored all 43 writes, then the next
  run had 5 maps and skipped all 43 on content hash. `Report` showed the same skew one notch smaller (2 maps then
  3). Both objects are parent-walked, and in both the disputed field was exactly the walk tag.
- **The parent link was not a relationship anywhere.** Even after promotion the column exists with no
  `RelatedIntegrationObjectID`, so nothing — not CodeGen's soft FK, not the platform's DAG view — knows a
  `Report` belongs to a `Round`.

Now declared on all nine, each with an explicit relation to the object it is walked under:
`ApplicationCategory`, `OtherSessionItemType`, `ScheduleDay`, `ScheduleRoom`, `ScheduleTimeSlot`, `ScheduleItem`,
`SessionType` → `Program`; `Report` → `Rounds`; `FundTransaction` → `Fund`.

Declared as **`String`, not `Integer`**, and that is not laziness — see `docs/REQUIRED-FIXES.md` item 7, filed in
the same pass. A declared unsized `Integer` becomes `NVARCHAR(MAX)`, which SQL Server cannot index, so its soft FK
index is silently skipped: 8 of this connector's 25 relations are unindexed today for exactly that reason, on its
three largest tables. Unsized `String` lands at `NVARCHAR(812)` — sized, indexable, and never a shrink of the two
of these that the engine had already promoted as sized columns. `IsReadOnly` stays `false` (a read-only field with
a relation is what caused the sproc-omission class in Totara).

Shipped as delta migration `V202608050910__openwater__DeclareParentWalkTagFields` (+ hand-authored `.pg.sql`
twin), verified against a live catalog: the insert is guarded per field, and a second, name-driven statement
back-fills the relation onto rows that already exist — necessary because three of the nine were already present
as engine-promoted `MetadataSource='Discovered'` rows with no relation. First apply: 6 inserted, 3 relations
repaired. Re-apply: 0 and 0. Zero of the connector's 19 walk-tag fields are left without a relation.

Also fixed in this pass: `scripts/lint-catalog-completeness.mjs` counted only `spCreateIntegrationObjectField`
calls from generated seeds, so any field shipped by a hand-authored delta read as "declared but never shipped" —
the gate failed on this change while the change was correct. It now also counts fields delivered by guarded
`INSERT INTO … IntegrationObjectField` statements, by their hardcoded ID literals.
