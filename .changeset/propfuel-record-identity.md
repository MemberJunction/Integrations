---
'@memberjunction/connector-propfuel': patch
---

PropFuel: record identity stripped every nested field, so most records shared one id.

`stableHash` built its identity with `JSON.stringify(record, Object.keys(record).sort())`. The
second argument to `JSON.stringify` is a REPLACER, and an array replacer is an allow-list of
property names applied at EVERY level — not an ordering hint for the top level. Passing the
top-level keys therefore stripped every NESTED key from the serialisation.

A PropFuel export row is nested (`{campaign:{...}, contact:{...}, click:{...}}`), so every record
serialised to `{"campaign":{},"click":{},"contact":{}}` and every record in a file with the same
shape hashed to the same value. `BuildRecordIdentity` falls back to this hash for every data type
whose payload has no top-level `id`/`uuid`/`externalID`, which is all of them.

Downstream the engine did exactly the right thing with a wrong input: two records sharing an
ExternalID are one source record observed twice, so `CollapseDuplicateIdentities` collapsed them.

Measured on a live account 2026-09-13: a batch of 884 `clicks` contained 2 distinct identities and
882 were collapsed; 1000 `opens` → 998 collapsed; 500 `checkin_questions` → 499 collapsed. The sync
fetched roughly 2,400 records and stored 181, reporting success with warnings. The colliding hash
`566c9995` from that run reproduces exactly from two synthetic records that differ in every nested
field.

Replaced with a recursive canonical serialisation — keys sorted at every depth, array order kept
(order is semantically meaningful), `undefined` omitted. Five regression tests cover the nested
case, key-order stability, depth, array order, and the flat records the old code happened to handle
correctly by accident; two of them fail against the previous implementation.

Note for existing installs: this CHANGES every ExternalID. Rows written under the old hash will not
match the new identity, so they are not updated in place — they need reconciling rather than a
plain re-sync.
