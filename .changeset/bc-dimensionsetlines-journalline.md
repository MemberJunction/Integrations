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

Delta migration `V202608251200__business-central__JournalLineDimensionSetLines` seeds the object and its ten
fields through `spCreateIntegrationObject` / `spCreateIntegrationObjectField` — the same calls the original
`V202608041723` seed emits — rather than raw `INSERT`s, so the row goes through the same defaulting and
validation as the 83 around it. A delta migration is the only safe shape here: regenerating the seed would
supersede the published `V202608041723` and change its Flyway checksum on every tenant that has already run
it.

The object and field IDs in the migration are the same GUIDs the metadata catalog carries. That parity was
missing in the first draft of this change: the catalog entry had been copied from the sibling
`dimensionSetLines` object and kept **its** primary keys, so the catalog declared two objects sharing one ID
and ten field IDs. A `mj sync push` would have written each pair twice and silently collapsed the two objects
into one. Fixed here, and the file now carries 84 distinct object IDs and 1,332 distinct field IDs.
