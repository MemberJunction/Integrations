# @memberjunction/connector-reply

## 1.0.1

### Patch Changes

- 6ee916d: Relicense to the Business Source License 1.1.

  Metadata and documentation only: the `license` field moves to `BUSL-1.1` and the
  repo gains a LICENSE file. No runtime behaviour, API surface, or dependency
  changes. The bump exists so the new licence metadata reaches npm, since the
  registry shows the licence of the latest published version.

## 1.0.0

### Major Changes

- Initial release of the Reply.io connector — **84 declared objects / 552 fields**, of which **55 are
  `Active`** and **34 support write-back**, covering contacts and accounts, the sequence surface
  (sequences, steps, step variants, templates, schedules, contact enrollment and per-contact previews),
  outreach channels (email accounts, LinkedIn accounts), tasks, the shared inbox, and webhooks, over the
  Reply.io **v3 REST API**.

  **Metadata provenance.** Every object, field, path and capability was extracted from the vendor's
  bundled **OpenAPI v3** specification (`reply-openapi-v3.bundled.yaml`,
  sha256 `6761de96a3ee00890ef83a15c7eb9ae10616bdd1f632425d29a841dbdd37fc6b`) rather than scraped prose,
  so the declared request shapes are contract-validated against the vendor's own document. The 12 unit-test
  fixtures descend from that spec's published example payloads — never synthesized from this connector's own
  metadata, which would make the tier unfalsifiable. Per-file provenance (spec pointer, verbatim vs derived)
  is recorded in `src/__tests__/fixtures/reply/PROVENANCE.json`.

  **Incremental sync is content-hash, not watermark.** Reply exposes no server-side modified-since filter on
  any of the 84 objects, so `SupportsIncrementalSync` is `false` universally and change detection is a full
  walk plus the engine's content-hash diff. This is a property of the vendor API, not a gap in the connector:
  a second pass over unchanged data processes every record and writes **zero**. Near-real-time deltas would
  require Reply's webhook surface, which is outside this connector's read path.

  **Two vendor idiosyncrasies are handled at the class level** (one override covering all 34 write-capable
  objects, each delegating to `super` when an object's per-operation columns are null): (a) bulk endpoints
  answer **HTTP 200 with a dictionary of only the FAILED items**, so status alone is a silent-failure trap and
  the response body must be inspected; and (b) named/nested path variables (`{step_id}`,
  `{knowledge_base_id}`) that the base class's `{id}`-only substitution cannot express.

  **29 of the 84 objects ship `Status='Disabled'`** by an explicit, recorded scope decision (ai-sdr 20,
  live-data 6, inbox 3) — each carries `Configuration.ScopeExclusionFamily` + `ScopeExclusionReason`, so the
  breadth found during discovery is documented as known-but-out-of-scope rather than silently unknown.

  **Verification.** The credential-free hybrid-e2e matrix passes all 22 cells with zero failures against a
  spec-driven mock vendor: all-object coverage proven (`coveredWithRows` == `syncableObjects`, **no** object
  landing 0 rows without a legit-empty reason), forward full sync, content-hash-narrowed incremental,
  idempotent re-run, delta create/update/**delete-tombstone**, DAG layering, Merkle partition skip,
  pagination cursor-follow-and-terminate, adaptive rate-limit under a 429 storm, transient retry with
  dead-lettering, and the write path asserted at the transport boundary (verb + path + body shape) without a
  live mutation. 72 unit tests pass.

  **What only a credential can close** — this release is honest about its ceiling. The S7 reality probe ran
  **unauthenticated**: 49 of 84 doors are proven `gated-exists` via HTTP 401 + `WWW-Authenticate: Bearer`, the
  remaining 35 carry no probe verdict. Un-proven without a token: per-endpoint pagination ceilings beyond the
  declared `DefaultPageSize`, real per-object record presence, declared-PK population against live data, and
  every write round-trip (the machinery is sound and the wiring is spec-correct, but no record has been watched
  to land in a real tenant). Read/pull confidence is high (OpenAPI-contract-validated + mock matrix passed);
  write-back and true rate behavior remain mock-proven only.
