# @memberjunction/connector-stripe

## 0.3.0

### Minor Changes

- 6a2b8e8: Enable MJ Action generation for the Stripe connector.

  The connector had no `GetIntegrationObjects()` override, so the base class returned an empty object
  list, `GetActionGeneratorConfig()` returned null, and **no Stripe Actions were ever generated** — the
  connector was reachable by sync but not by an agent, a flow, or `IntegrationActionExecutor`, despite
  declaring 63 objects and a live-verified read path.

  Both overrides are now present. The object model is derived entirely from the runtime
  IntegrationObject / IntegrationObjectField cache rather than a list baked into code, matching how the
  rest of this connector treats its catalog: if the cache is unseeded — action generation can run
  before the integration is seeded — it returns an empty array and generates nothing, and never falls
  back to a hardcoded subset. A baked fallback is the `catalog-in-code` defect, which silently freezes
  the object universe to whatever was current when the list was written.

  No behaviour change to sync, authentication, pagination, or the declared catalog.

## 0.2.3

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

## 0.2.2

### Patch Changes

- 6235c0c: Add `push.autoCreateMissingRecords: true` to `.mj-sync.json` so `mj sync push` seeds the connector's metadata cleanly against a DB that doesn't yet hold the Integration/IntegrationObject rows (previously the child-record push failed with "Record not found — set autoCreateMissingRecords=true"). Build-time seed-generation fix only; the published runtime (`dist`) is unchanged.

## 0.2.1

### Patch Changes

- 375dd63: Declare the parent FK on `source_transaction.source`. The field existed but was never
  FK-linked (`RelatedIntegrationObjectID` was null), so the sync engine could not resolve the
  `{source}` path template variable in `/v1/sources/{source}/source_transactions` and the object
  never synced. Surfaced by a full-catalog hybrid-e2e run against the real connector package.

  Note: `source` is a get-by-id object (Stripe exposes no list-all-sources endpoint), so
  `source_transaction` remains enumerable only where source ids are available (e.g. via
  `payment_source` = `/v1/customers/{customer}/sources`). The FK declaration fixes the
  relationship/lineage; a connector-author decision remains on whether to re-point the parent at
  `payment_source` for full enumeration.

## 0.2.0

### Minor Changes

- 705b72e: Stripe connector published as an Open App.
