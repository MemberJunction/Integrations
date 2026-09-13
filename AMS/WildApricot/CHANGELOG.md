# @memberjunction/connector-wild-apricot

## 1.3.3

### Patch Changes

- a0563d1: Record identity ignored every nested field — the same defect fixed in PropFuel 1.2.4, in the three
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
  still collapses; nested key _order_ is ignored while nested _values_ are not) — two of them fail
  against the previous implementation with exactly the collapse described above. OpenWater and
  WildApricot export `canonicalJSON` and gain five cases each, one of which asserts the old expression
  produced identical output for two records that must be distinct.

## 1.3.2

### Patch Changes

- 06b2b4b: Allow MemberJunction 6.x as a peer. Every connector capped its `@memberjunction/*` peers at `<6.0.0`; the ceiling moves to `<7.0.0`, and `mj-app.json.mjVersionRange` moves with it so npm and `mjdev app register` agree. Floors are unchanged, so 5.x hosts are unaffected.

  Why the ceiling is the fix on a 6.x host: pnpm's `auto-install-peers` satisfies an unmet peer range by installing a **second** copy of `@memberjunction/core`, and two copies of core in one process is the failure that surfaces as thousands of unrelated-looking type errors. Business Central hit exactly this and was widened alone (#180, then #208 for the manifest); this brings the other 56 connectors, the two private platform packages, and the shared `connector-id-window-scan` package to the same range, so the duplicate cannot return transitively through a shared dependency either. The scaffolding scripts (`new-connector`, `scaffold-openapps`, `split-into-packages`) now mint `<7.0.0` too, so a new connector does not reintroduce the cap.

  Verified at compile time, not at runtime: all 61 packages in the repo (57 connectors, the two private platform packages, the two shared packages) type-check against `@memberjunction/*@6.1.0-edge.5` — the only 6.x published at the time; there is no stable 6.x yet — with every framework `.d.ts` resolved from the 6.x install and none from 5.x. That check is `npm run check:mj-compat` (`scripts/typecheck-against-mj.mjs`), added with this change so the claim can be re-run against any MJ version. It is API compatibility at the type level; the only runtime evidence on a 6.x host remains the Business Central team's edge deployment.

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
