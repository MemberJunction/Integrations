---
'@memberjunction/connector-nimble-ams': patch
'@memberjunction/connector-salesforce': patch
---

Nimble AMS extends the Salesforce base connector instead of duplicating its Salesforce layer.

Nimble carried its own copy of the SOQL stack, which is how the hardening ladder proven on a
customer org existed in exactly one of the three Salesforce-platform connectors while Fonteva
and the base still had the defects. The duplicate is gone: `NimbleAMSConnector` now extends
`SalesforceConnector` and deletes ~230 lines of copied machinery (`FetchSOQL`, `BuildSOQL`,
`FormatSOQLDateTime`, `ResolveWatermarkField`, `ChunkSOQLFields`, `MergeChunkedRecords`).

What Nimble keeps is what is actually Nimble: the Fuse inbound/outbound doors, the LMS REST
family, `NU__`/`NUINT__` namespace scoping, its own OAuth token flow, and the literal-create
body shapes. Its `FetchChanges` routes those families itself and delegates the default door to
the base.

Moved INTO the base with this change (so Fonteva and every future Salesforce connector inherit
them, not just Nimble):

- **Chunked wide projections** — Salesforce's REST edge 431s an over-long request line; a
  674-field object failed batch 1 of every run. Wide projections split into aligned chunks
  (pinned to the one page size Salesforce honors exactly) and reassemble by Id; misalignment
  throws rather than writing half-populated rows.
- **Declared-watermark honoring** — an explicit `IncrementalWatermarkField` now wins over the
  audit-column preference, so objects that expose only `CreatedDate` stop 400-ing.

The SOQL-mechanics test coverage moved with the code: 11 cases now live in the base's suite
(construction, declared-watermark precedence, per-page watermark advance, chunk splitting,
aligned reassembly, misalignment throw, chunked-cursor round-trip) — base 59/59, Nimble 24/24,
Fonteva 62/62 unchanged.
