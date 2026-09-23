---
'@memberjunction/connector-nimble-ams': patch
---

Declare the incremental cursor on discovered objects that expose one.

Every discovered object was full-scanning on every sync, silently. `SupportsIncrementalSync: true`
buys nothing on its own: the SOQL door filters on the object's `IncrementalWatermarkField`, and
`ExternalObjectSchema` has no property to carry one, so the cursor was never declared. Measured on
a live org: of 364 discovered objects only the 16 declared ones had a cursor; the other 348 — 114
of them real `__c` objects — had none, and nothing reported it.

`IntrospectSchema` now fills `LastModifiedDate` where an object has no cursor AND the describe
response shows it has that column. The presence check is the point: Salesforce's own companion
types do not all carry it — on the same org, 96 `__History` and 24 `__mdt` objects lack it — and
naming a non-existent field in the SOQL predicate fails the fetch outright. A silent full scan is
the lesser failure, so those objects keep no cursor.

Object scoping is unchanged: discovery still returns everything in the Nimble namespace, and which
tables to sync stays the customer's choice in the picker.
