# @memberjunction/connector-zendesk

## 1.1.1

### Patch Changes

- 6235c0c: Add `push.autoCreateMissingRecords: true` to `.mj-sync.json` so `mj sync push` seeds the connector's metadata cleanly against a DB that doesn't yet hold the Integration/IntegrationObject rows (previously the child-record push failed with "Record not found — set autoCreateMissingRecords=true"). Build-time seed-generation fix only; the published runtime (`dist`) is unchanged.

## 1.1.0

### Minor Changes

- ba26bdf: Zendesk connector **v1.0.0** — a new REST/JSON Open App for the Zendesk Support API (`api/v2`) over per-tenant `https://{subdomain}.zendesk.com` with Basic auth (email/API token). Extends `BaseRESTIntegrationConnector` across 99 objects — tickets, users, organizations, groups, ticket fields/forms/metrics, macros/triggers/automations, the help center (articles/sections/categories/comments/votes), community, custom objects + their records/fields/access-rules (parent-templated children resolved via `custom_object_key`), talk/chat/routing, and audit/tracking streams. Cursor + offset pagination, Incremental Export watermark sync, read + write (create/update/delete), and full-record pass-through. Wires the never-shrink sample-union in `IntrospectSchema` (`@memberjunction/connector-schema-merge`) so tenant custom columns are captured, and bounds every string column with an explicit inferred length (no `nvarchar(255)` overflow). Credential type is the baseline `Basic Auth`. Verified with a full-lifecycle GENUINE-GREEN-MOCK e2e (2 consecutive all-green runs: forward sync, coverage over every object, delta CRUD, idempotent, custom-column capture, pagination, watermark/content-hash, bidirectional writes) and 34 unit tests. **Predicated on framework 5.45** (`MJ#3047`) — the reserved-word-PK content-hash idempotency fix required by `custom_objects` (PK `key`); scaffolding `id`/`custom_object_key` IOFs are shipped Status=Disabled for a future non-reserved-PK migration.
