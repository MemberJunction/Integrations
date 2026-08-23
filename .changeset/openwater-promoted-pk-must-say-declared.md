---
'@memberjunction/connector-openwater': patch
---

A field promoted to PRIMARY KEY by a migration must also be relabelled Declared

V202608212210 completed JudgeAssignment's key into the (userId, roundId) pair. On tenants where
`roundId` already existed it did that through an UPDATE rather than the INSERT, and that UPDATE set
IsPrimaryKey/IsRequired/AllowsNull but left `MetadataSource` alone — leaving a PRIMARY KEY still
labelled `Discovered`.

The engine's overlay then does exactly what it is designed to do: `decidePKPromotion` forbids a
*Discovered* field from being part of the key of an object that has a declared PK, so the next
schema refresh demotes it. Observed on a live tenant, the catalog went from
`declared=roundId,userId` back to `declared=userId` — the person-grain collapse V202608212210
existed to fix, where a judge assigned to several rounds folds to one row per person. The self-heal
was correct; the row was mislabelled.

V202608222100 re-asserts `IsPrimaryKey` and sets `MetadataSource = 'Declared'` for that field,
matched by object + field name because the row needing repair is the pre-existing promoted one
whose ID differs per tenant. Idempotent, and a no-op on tenants that took the INSERT path.
