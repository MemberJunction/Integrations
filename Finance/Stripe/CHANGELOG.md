# @memberjunction/connector-stripe

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
