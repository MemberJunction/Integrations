# @memberjunction/connector-zendesk

## 1.1.4

### Patch Changes

- 06b2b4b: Allow MemberJunction 6.x as a peer. Every connector capped its `@memberjunction/*` peers at `<6.0.0`; the ceiling moves to `<7.0.0`, and `mj-app.json.mjVersionRange` moves with it so npm and `mjdev app register` agree. Floors are unchanged, so 5.x hosts are unaffected.

  Why the ceiling is the fix on a 6.x host: pnpm's `auto-install-peers` satisfies an unmet peer range by installing a **second** copy of `@memberjunction/core`, and two copies of core in one process is the failure that surfaces as thousands of unrelated-looking type errors. Business Central hit exactly this and was widened alone (#180, then #208 for the manifest); this brings the other 56 connectors, the two private platform packages, and the shared `connector-id-window-scan` package to the same range, so the duplicate cannot return transitively through a shared dependency either. The scaffolding scripts (`new-connector`, `scaffold-openapps`, `split-into-packages`) now mint `<7.0.0` too, so a new connector does not reintroduce the cap.

  Verified at compile time, not at runtime: all 61 packages in the repo (57 connectors, the two private platform packages, the two shared packages) type-check against `@memberjunction/*@6.1.0-edge.5` — the only 6.x published at the time; there is no stable 6.x yet — with every framework `.d.ts` resolved from the 6.x install and none from 5.x. That check is `npm run check:mj-compat` (`scripts/typecheck-against-mj.mjs`), added with this change so the claim can be re-run against any MJ version. It is API compatibility at the type level; the only runtime evidence on a 6.x host remains the Business Central team's edge deployment.

## 1.1.3

### Patch Changes

- 6ee916d: Relicense to the Business Source License 1.1.

  Metadata and documentation only: the `license` field moves to `BUSL-1.1` and the
  repo gains a LICENSE file. No runtime behaviour, API surface, or dependency
  changes. The bump exists so the new licence metadata reaches npm, since the
  registry shows the licence of the latest published version.

## 1.1.2

### Patch Changes

- 533fb7a: ClassName follows the catalog convention (== npm package name) so instance discovery matches; legacy 'ZendeskConnector' key stays registered and a delta migration fixes existing tenants' Integration rows.

## 1.1.1

### Patch Changes

- 6235c0c: Add `push.autoCreateMissingRecords: true` to `.mj-sync.json` so `mj sync push` seeds the connector's metadata cleanly against a DB that doesn't yet hold the Integration/IntegrationObject rows (previously the child-record push failed with "Record not found — set autoCreateMissingRecords=true"). Build-time seed-generation fix only; the published runtime (`dist`) is unchanged.

## 1.1.0

### Minor Changes

- ba26bdf: Zendesk connector **v1.0.0** — a new REST/JSON Open App for the Zendesk Support API (`api/v2`) over per-tenant `https://{subdomain}.zendesk.com` with Basic auth (email/API token). Extends `BaseRESTIntegrationConnector` across 99 objects — tickets, users, organizations, groups, ticket fields/forms/metrics, macros/triggers/automations, the help center (articles/sections/categories/comments/votes), community, custom objects + their records/fields/access-rules (parent-templated children resolved via `custom_object_key`), talk/chat/routing, and audit/tracking streams. Cursor + offset pagination, Incremental Export watermark sync, read + write (create/update/delete), and full-record pass-through. Wires the never-shrink sample-union in `IntrospectSchema` (`@memberjunction/connector-schema-merge`) so tenant custom columns are captured, and bounds every string column with an explicit inferred length (no `nvarchar(255)` overflow). Credential type is the baseline `Basic Auth`. Verified with a full-lifecycle GENUINE-GREEN-MOCK e2e (2 consecutive all-green runs: forward sync, coverage over every object, delta CRUD, idempotent, custom-column capture, pagination, watermark/content-hash, bidirectional writes) and 34 unit tests. **Predicated on framework 5.45** (`MJ#3047`) — the reserved-word-PK content-hash idempotency fix required by `custom_objects` (PK `key`); scaffolding `id`/`custom_object_key` IOFs are shipped Status=Disabled for a future non-reserved-PK migration.
