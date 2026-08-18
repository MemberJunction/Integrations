# @memberjunction/connector-constant-contact

## 2.0.1

### Patch Changes

- 6ee916d: Relicense to the Business Source License 1.1.

  Metadata and documentation only: the `license` field moves to `BUSL-1.1` and the
  repo gains a LICENSE file. No runtime behaviour, API surface, or dependency
  changes. The bump exists so the new licence metadata reaches npm, since the
  registry shows the licence of the latest published version.

## 2.0.0

### Major Changes

- a447780: Constant Contact connector — v2.0.0 (major redo over the previously published 1.x).

  Full re-extract + re-verify: 65 in-scope Constant Contact V3 objects (contacts, lists, tags, segments, custom fields, bulk activities, email campaigns, campaign activities, reporting, account services). OAuth2 Authorization Code with rotating refresh tokens (configurable token endpoint), cursor pagination (`_links.next`), incremental via `updated_after`/`after_date`. Separate routes (partner webhooks, SMS, legacy V2/EventSpot, Zapier/Make) documented out-of-scope.

  Proven via credential-free mock hybrid-e2e: all objects land rows, idempotent (three-sync zero-growth), incremental narrowing, delta CRUD, custom-column capture; identity invariants validated. Breaking: object set + primary-key identity re-derived from the V3 schema, so this supersedes the prior published metadata.

## 1.1.1

### Patch Changes

- 533fb7a: ClassName follows the catalog convention (== npm package name) so instance discovery matches; legacy 'ConstantContactConnector' key stays registered and a delta migration fixes existing tenants' Integration rows.

## 1.1.0

### Minor Changes

- 37cfe35: Sample-union discovery for describe-endpoint connectors: each connector wires MJ's existing `DiscoverFieldsViaFetch` sampler into its declared catalog inside `IntrospectSchema`, unioned per object via the shared pure helper `mergeDeclaredWithSampledFields` — real widths and MJ-discovered custom columns land before the first sync (no `nvarchar(255)` overflow / `STRING_OVERFLOW_SKIPPED`). Connectors with no `IntrospectSchema` of their own get the standard `super.IntrospectSchema → sample → merge → return` override; connectors that already own an `IntrospectSchema` (HubSpot, Salesforce, Nimble AMS, YourMembership) are WRAPPED — their existing logic/caching is preserved and the union runs on the built result before return (Fonteva inherits it via Salesforce's `super`).

  The width rule is NEVER-SHRINK: `MaxLength = max(declared, measured)`. It only ever widens, so connectors that already carry real declared widths from their describe API (Salesforce/Fonteva) are never truncated below the real width, while connectors whose declared catalog has no width still adopt MJ's measured value. Connectors add no discovery/merge/sync logic of their own; MJ owns measurement, type/PK inference, persistence and reconcile. `DiscoverFields` is unchanged (no recursion). Schema-less / already-streaming connectors (PropFuel, FileFeed, RelationalDB, MJtoMJ, ORCID) are unaffected.
