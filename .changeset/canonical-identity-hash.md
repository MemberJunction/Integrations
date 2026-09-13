---
'@memberjunction/connector-openwater': patch
'@memberjunction/connector-wild-apricot': patch
'@memberjunction/connector-totara': patch
---

Record identity ignored every nested field — the same defect fixed in PropFuel 1.2.4, in the three
connectors that still carried the line.

`JSON.stringify(value, Object.keys(value).sort())` reads as "serialise with sorted keys". It is not.
The second argument is a **replacer**, and an array replacer is an **allow-list of property names
applied at every level** — so passing the top-level keys stripped every nested key from the output,
and any two values differing only below the top level serialised identically.

Proven live on PropFuel: a sandbox sync fetched ~2,400 records and stored **181**, because the engine
did the right thing with a wrong input — two records sharing an identity are one record observed
twice, so `CollapseDuplicateIdentities` collapsed them. 882 of 884 clicks in a single batch.

Where each connector used it, and what it cost:

- **Totara** `ExplodeCollection` — the dedupe signature for exploded collection elements. Its own
  comment says "byte-identical projection = one fact restated. Anything differing is kept", and the
  code did the opposite: two elements differing only in a nested object were counted as repeats and
  **silently dropped**, incrementing `ElementsCollapsed`. This is the sharpest of the three, because
  the drop is deliberate and invisible.
- **OpenWater** `ContentHash` — the identity fallback when a declared primary key is partial or
  missing. `Fields` carries the full source record for custom-column pass-through, so nested vendor
  JSON is exactly what it hashes.
- **WildApricot** `stableHash` — the same fallback shape.

All three now use one `canonicalJSON`: keys sorted **recursively**, array order kept (order is
semantically meaningful), `undefined` omitted, `Date` via ISO string.

Pinned by tests that fail on the old code: Totara gains three behavioural cases on the public
`ExplodeCollection` (two elements differing only in a nested value survive; a genuine restatement
still collapses; nested key *order* is ignored while nested *values* are not) — two of them fail
against the previous implementation with exactly the collapse described above. OpenWater and
WildApricot export `canonicalJSON` and gain five cases each, one of which asserts the old expression
produced identical output for two records that must be distinct.
