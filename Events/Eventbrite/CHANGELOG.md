# @memberjunction/connector-eventbrite

## 2.0.2

### Patch Changes

- 3b9b36e: Give every writable object a primary key (or withdraw the write it cannot honor).

  A writable `MJ: Integration Object` with no `IsPrimaryKey` field derives a **keyless** entity. On
  Postgres the save audit-wrapper then emits an empty record identifier and every save fails with
  `syntax error at or near ","` — while fetch keeps succeeding, so the object reads green and persists
  nothing. Five objects across these three connectors were in that state.

  Each key is taken from the vendor's own schema, never invented:

  - **Stripe `cash_balance`** → `customer`. Stripe's `CashBalance` schema declares `customer` as a
    property of the object, and the resource is a singleton per customer
    (`/v1/customers/{customer}/cash_balance`, GET + POST only, no collection and no item id). It is
    returned in the payload, so the column is populated rather than null.
  - **Stripe `balance_settings`** → write withdrawn. `BalanceSettings` declares exactly two
    properties, `object` and `payments`; `/v1/balance_settings` takes no path variable because the
    account is implied by the API key. There is nothing to key on, and the object declared no
    create/update/delete operation either — the flag described a capability with no implementation.
    Reads are unaffected.
  - **Totara `Cohort Members`** → `cohortid`. `core_cohort_get_cohort_members` returns one row per
    **cohort** (`{cohortid, userids[]}`), so the cohort is the record identity.
  - **Totara `Group Members`** → `groupid`. `core_group_get_group_members` returns one row per
    **group** (`{groupid, userids[]}`), same shape; the field was already writable.
  - **Eventbrite `Media Upload`** → `upload_token`. Eventbrite's two-step media workflow issues the
    token from `GET /media/upload/` and it identifies the upload for the subsequent POST. It is the
    only identifier in the Media Upload MSON type and it is vendor-issued and returned.

  All three connectors are published, so each ships a **delta** migration (SQL Server + Postgres) that
  UPDATEs the existing catalog rows in place — no IDs minted, no rows created, idempotent by `WHERE`,
  and nothing can collide with an already-applied seed.

## 2.0.1

### Patch Changes

- 533fb7a: ClassName follows the catalog convention (== npm package name) so instance discovery matches; legacy 'EventbriteConnector' key stays registered and a delta migration fixes existing tenants' Integration rows.

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
