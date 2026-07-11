# @memberjunction/connector-magnetmail

## 3.0.2

### Patch Changes

- 533fb7a: ClassName follows the catalog convention (== npm package name) so instance discovery matches; legacy 'MagnetMailConnector' key stays registered and a delta migration fixes existing tenants' Integration rows.

## 3.0.1

### Patch Changes

- 6235c0c: Add `push.autoCreateMissingRecords: true` to `.mj-sync.json` so `mj sync push` seeds the connector's metadata cleanly against a DB that doesn't yet hold the Integration/IntegrationObject rows (previously the child-record push failed with "Record not found — set autoCreateMissingRecords=true"). Build-time seed-generation fix only; the published runtime (`dist`) is unchanged.

## 3.0.0

### Major Changes

- 0a94696: MagnetMail connector **v2.0.0** — a full rebuild of the deprecated v1 (breaking override). SOAP-over-`BaseRESTIntegrationConnector` for the `mmapi.asmx` API: two-step `<mmAuthHeader>` session auth, per-operation `ListOperation`/CRUD wiring across 47 objects (36 list ops + 7 write ops), `getMessagesUTC` incremental watermark, and full-record pass-through. Wires the never-shrink sample-union in `IntrospectSchema` (`@memberjunction/connector-schema-merge`) so tenant custom columns are captured, and bounds every string column with an explicit length. Credential type moved from the removed custom `MagnetMail API` to baseline `Basic Auth`. Verified with a full-lifecycle GENUINE-GREEN-MOCK e2e (forward sync, coverage over every object, delta CRUD, idempotent, custom-column capture, pagination, watermark, bidirectional writes) and 37 unit tests.

## 1.1.0

### Minor Changes

- 37cfe35: Sample-union discovery for describe-endpoint connectors: each connector wires MJ's existing `DiscoverFieldsViaFetch` sampler into its declared catalog inside `IntrospectSchema`, unioned per object via the shared pure helper `mergeDeclaredWithSampledFields` — real widths and MJ-discovered custom columns land before the first sync (no `nvarchar(255)` overflow / `STRING_OVERFLOW_SKIPPED`). Connectors with no `IntrospectSchema` of their own get the standard `super.IntrospectSchema → sample → merge → return` override; connectors that already own an `IntrospectSchema` (HubSpot, Salesforce, Nimble AMS, YourMembership) are WRAPPED — their existing logic/caching is preserved and the union runs on the built result before return (Fonteva inherits it via Salesforce's `super`).

  The width rule is NEVER-SHRINK: `MaxLength = max(declared, measured)`. It only ever widens, so connectors that already carry real declared widths from their describe API (Salesforce/Fonteva) are never truncated below the real width, while connectors whose declared catalog has no width still adopt MJ's measured value. Connectors add no discovery/merge/sync logic of their own; MJ owns measurement, type/PK inference, persistence and reconcile. `DiscoverFields` is unchanged (no recursion). Schema-less / already-streaming connectors (PropFuel, FileFeed, RelationalDB, MJtoMJ, ORCID) are unaffected.
