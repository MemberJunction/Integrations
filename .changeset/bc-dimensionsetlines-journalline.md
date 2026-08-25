---
"@memberjunction/connector-business-central": minor
---

Address `dimensionSetLines` under a journal line, so dimensions can be written to journal entries.

`dimensionSetLines` was catalogued with a single parent — `/companies({id})/salesOrders({id})/dimensionSetLines`
— which made it impossible to write dimensions to a journal line even though Business Central supports it and
the connector's `CreateRecord` is fully generic. The resource's own `parentType` description names
"Journal Line" first among its valid parents, so the catalog was narrower than the resource it describes.

Verified against a live tenant: BC's `$metadata` declares `dimensionSetLines` as a navigation property on
`journalLine`, the path reads (`200`), and it accepts writes — an empty-body `POST` is rejected with
`400 BadRequest "Values must be provided in the body."`, i.e. on payload validation rather than method. For
contrast, `dimensions` and `dimensionValues` answer `405 BadRequest_MethodNotAllowed`; those are genuinely
read-only, are correctly catalogued as such, and are **not** changed.

Added as a second object, `journalLineDimensionSetLines`, because `UQ_IntegrationObject_Name` is unique on
`(IntegrationID, Name)` and the sales-order parent is in use. `dimensionSetLine` is parent-polymorphic — BC
navigates to it from **24** EntityTypes and `parentType` distinguishes them on the wire — so this adds the
one parent that blocks journal-entry export. The other 22 remain uncatalogued; covering them generally is a
modelling decision rather than a path correction.

Delta migration `V202608251200__business-central__JournalLineDimensionSetLines` inserts the object and its
ten fields, every guard keyed on the unique constraint's own columns rather than on `ID` — the mistake that
broke `V202608240630__pheedloop__UnboundedText`.
