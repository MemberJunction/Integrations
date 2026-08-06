---
"@memberjunction/connector-business-central": patch
---

Fix two write-path defects found by the credential-free behavioural suite.

`CreateRecord` read the new record's ID by scanning the response for a literal `id`-shaped key. Business
Central objects whose primary key is named something else (`customerId`, `number`, a composite pair) came
back with an empty `ExternalID`, so the record map was never written and the next sync re-created the row.
The ID is now read from the object's own primary-key metadata, with the previous scan kept as a fallback.

`parentKeyFromAttributes` did not recognise the generic `parentId` / `parentID` attribute that Business
Central sub-entities carry, so a nested create (`/companies({id})/salesInvoices({id})/dimensionSetLines`)
could not resolve its parent segment and produced a malformed URL.

Both are covered by new unit tests. No metadata, schema or migration change.
