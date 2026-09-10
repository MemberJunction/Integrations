# @memberjunction/connector-mailchimp

## 2.0.2

### Patch Changes

- 06b2b4b: Allow MemberJunction 6.x as a peer. Every connector capped its `@memberjunction/*` peers at `<6.0.0`; the ceiling moves to `<7.0.0`, and `mj-app.json.mjVersionRange` moves with it so npm and `mjdev app register` agree. Floors are unchanged, so 5.x hosts are unaffected.

  Why the ceiling is the fix on a 6.x host: pnpm's `auto-install-peers` satisfies an unmet peer range by installing a **second** copy of `@memberjunction/core`, and two copies of core in one process is the failure that surfaces as thousands of unrelated-looking type errors. Business Central hit exactly this and was widened alone (#180, then #208 for the manifest); this brings the other 56 connectors, the two private platform packages, and the shared `connector-id-window-scan` package to the same range, so the duplicate cannot return transitively through a shared dependency either. The scaffolding scripts (`new-connector`, `scaffold-openapps`, `split-into-packages`) now mint `<7.0.0` too, so a new connector does not reintroduce the cap.

  Verified at compile time, not at runtime: all 61 packages in the repo (57 connectors, the two private platform packages, the two shared packages) type-check against `@memberjunction/*@6.1.0-edge.5` — the only 6.x published at the time; there is no stable 6.x yet — with every framework `.d.ts` resolved from the 6.x install and none from 5.x. That check is `npm run check:mj-compat` (`scripts/typecheck-against-mj.mjs`), added with this change so the claim can be re-run against any MJ version. It is API compatibility at the type level; the only runtime evidence on a 6.x host remains the Business Central team's edge deployment.

## 2.0.1

### Patch Changes

- 6ee916d: Relicense to the Business Source License 1.1.

  Metadata and documentation only: the `license` field moves to `BUSL-1.1` and the
  repo gains a LICENSE file. No runtime behaviour, API surface, or dependency
  changes. The bump exists so the new licence metadata reaches npm, since the
  registry shows the licence of the latest published version.

## 2.0.0

### Major Changes

- b6016a8: Rebuild the Mailchimp connector to the pure-mechanism convention. The object/field catalog now lives entirely in Declared metadata (76 objects / 767 fields) with discovery inherited from `BaseRESTIntegrationConnector` — no baked catalog, PK/FK, required/readonly, or field constants in code. Behavior is unchanged: HTTP Basic auth with the API key, data-center prefix derived from the key suffix, uniform `count`/`offset` pagination, per-object envelope unwrapping, and named-parent-var nested CRUD. Seed migrations (SQL + PG) regenerated from the refreshed metadata.

  Full-depth nested sync — e.g. a list's complete member set rather than only its first page — depends on the engine fix in MemberJunction/MJ#3246.

## 1.1.1

### Patch Changes

- 533fb7a: ClassName follows the catalog convention (== npm package name) so instance discovery matches; legacy 'MailchimpConnector' key stays registered and a delta migration fixes existing tenants' Integration rows.

## 1.1.0

### Minor Changes

- 37cfe35: Sample-union discovery for describe-endpoint connectors: each connector wires MJ's existing `DiscoverFieldsViaFetch` sampler into its declared catalog inside `IntrospectSchema`, unioned per object via the shared pure helper `mergeDeclaredWithSampledFields` — real widths and MJ-discovered custom columns land before the first sync (no `nvarchar(255)` overflow / `STRING_OVERFLOW_SKIPPED`). Connectors with no `IntrospectSchema` of their own get the standard `super.IntrospectSchema → sample → merge → return` override; connectors that already own an `IntrospectSchema` (HubSpot, Salesforce, Nimble AMS, YourMembership) are WRAPPED — their existing logic/caching is preserved and the union runs on the built result before return (Fonteva inherits it via Salesforce's `super`).

  The width rule is NEVER-SHRINK: `MaxLength = max(declared, measured)`. It only ever widens, so connectors that already carry real declared widths from their describe API (Salesforce/Fonteva) are never truncated below the real width, while connectors whose declared catalog has no width still adopt MJ's measured value. Connectors add no discovery/merge/sync logic of their own; MJ owns measurement, type/PK inference, persistence and reconcile. `DiscoverFields` is unchanged (no recursion). Schema-less / already-streaming connectors (PropFuel, FileFeed, RelationalDB, MJtoMJ, ORCID) are unaffected.
