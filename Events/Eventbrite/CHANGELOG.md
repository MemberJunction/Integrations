# @memberjunction/connector-eventbrite

## 2.0.0

### Major Changes

- 9e06305: Eventbrite connector v2.0.0 — full rebuild superseding the prior 18-object build.

  Breaking: the object set and IO naming changed (33 syncable objects, spaced display
  names e.g. "Event Team"/"Inventory Tier" vs the prior "EventTeam"/"InventoryTier"), so
  existing 1.0.0 installs' data mappings do not carry over — a major bump.

  - 33 Integration Objects (was 18) with per-operation CRUD, continuation-token pagination,
    and `changed_since` incremental sync on Attendee/Order.
  - Nested/array fields typed `json` (NVARCHAR MAX); `GetBaseURL` config override for
    region/test endpoints.
  - Regenerated seed migration (SQL Server + PostgreSQL), install-tested: seeds 1 Integration
    - 33 Objects + 346 Fields into the core `__mj` catalog.
  - Proven end-to-end through the real MJ IntegrationEngine (credential-free e2e = ok:true,
    all objects landing rows, writes round-tripping, watermark/content-hash/delta all green).

## 1.1.0

### Minor Changes

- 37cfe35: Sample-union discovery for describe-endpoint connectors: each connector wires MJ's existing `DiscoverFieldsViaFetch` sampler into its declared catalog inside `IntrospectSchema`, unioned per object via the shared pure helper `mergeDeclaredWithSampledFields` — real widths and MJ-discovered custom columns land before the first sync (no `nvarchar(255)` overflow / `STRING_OVERFLOW_SKIPPED`). Connectors with no `IntrospectSchema` of their own get the standard `super.IntrospectSchema → sample → merge → return` override; connectors that already own an `IntrospectSchema` (HubSpot, Salesforce, Nimble AMS, YourMembership) are WRAPPED — their existing logic/caching is preserved and the union runs on the built result before return (Fonteva inherits it via Salesforce's `super`).

  The width rule is NEVER-SHRINK: `MaxLength = max(declared, measured)`. It only ever widens, so connectors that already carry real declared widths from their describe API (Salesforce/Fonteva) are never truncated below the real width, while connectors whose declared catalog has no width still adopt MJ's measured value. Connectors add no discovery/merge/sync logic of their own; MJ owns measurement, type/PK inference, persistence and reconcile. `DiscoverFields` is unchanged (no recursion). Schema-less / already-streaming connectors (PropFuel, FileFeed, RelationalDB, MJtoMJ, ORCID) are unaffected.
