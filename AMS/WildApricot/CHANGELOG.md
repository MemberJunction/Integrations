# @memberjunction/connector-wild-apricot

## 1.3.1

### Patch Changes

- 6ee916d: Relicense to the Business Source License 1.1.

  Metadata and documentation only: the `license` field moves to `BUSL-1.1` and the
  repo gains a LICENSE file. No runtime behaviour, API surface, or dependency
  changes. The bump exists so the new licence metadata reaches npm, since the
  registry shows the licence of the latest published version.

## 1.3.0

### Minor Changes

- d57b5e8: Three live-verified Wild Apricot fixes (minor because the third changes seeded metadata, generating a new migration):

  1. **Auth (code)** — send the literal string `APIKEY` as the HTTP-Basic username and the admin API key as the password (the connector was sending the API key as the username with an empty password). The previous form failed every `client_credentials` token request with `HTTP 401 — invalid_client`, so no data could sync. Corrected → authentication succeeds.

  2. **Contacts pagination (code)** — fetch the `Contact` object via Wild Apricot's stable async EXPORT snapshot: kick off `$async=true` once, poll the `ResultId` to `State='Complete'`, then page that immutable snapshot with `?resultId=<id>&$skip&$top`. The previous live `$async=false&$skip` scan is order-unstable when interleaved with the sync's other requests — pages overlap, so only a fraction of contacts dedup through (observed: 197 of 1,275). The export snapshot returns the complete set (verified: full 1,275 contacts sync).

  3. **AttachmentData disabled (metadata)** — `AttachmentData` declared a GET list path (`/accounts/{accountId}/attachments/GetInfos`) that returns HTTP 404: Wild Apricot has no account-level "list all attachments" endpoint. Marked `Status='Disabled'` so the sync no longer attempts an un-listable object. (Proper attachment sync via the `POST /attachments/GetInfos` info-lookup remains a future enhancement.)

## 1.2.1

### Patch Changes

- 6235c0c: Add `push.autoCreateMissingRecords: true` to `.mj-sync.json` so `mj sync push` seeds the connector's metadata cleanly against a DB that doesn't yet hold the Integration/IntegrationObject rows (previously the child-record push failed with "Record not found — set autoCreateMissingRecords=true"). Build-time seed-generation fix only; the published runtime (`dist`) is unchanged.

## 1.2.0

### Minor Changes

- 53d1772: Wild Apricot connector published as an Open App.

## 1.1.0

### Minor Changes

- 37cfe35: Sample-union discovery for describe-endpoint connectors: each connector wires MJ's existing `DiscoverFieldsViaFetch` sampler into its declared catalog inside `IntrospectSchema`, unioned per object via the shared pure helper `mergeDeclaredWithSampledFields` — real widths and MJ-discovered custom columns land before the first sync (no `nvarchar(255)` overflow / `STRING_OVERFLOW_SKIPPED`). Connectors with no `IntrospectSchema` of their own get the standard `super.IntrospectSchema → sample → merge → return` override; connectors that already own an `IntrospectSchema` (HubSpot, Salesforce, Nimble AMS, YourMembership) are WRAPPED — their existing logic/caching is preserved and the union runs on the built result before return (Fonteva inherits it via Salesforce's `super`).

  The width rule is NEVER-SHRINK: `MaxLength = max(declared, measured)`. It only ever widens, so connectors that already carry real declared widths from their describe API (Salesforce/Fonteva) are never truncated below the real width, while connectors whose declared catalog has no width still adopt MJ's measured value. Connectors add no discovery/merge/sync logic of their own; MJ owns measurement, type/PK inference, persistence and reconcile. `DiscoverFields` is unchanged (no recursion). Schema-less / already-streaming connectors (PropFuel, FileFeed, RelationalDB, MJtoMJ, ORCID) are unaffected.
