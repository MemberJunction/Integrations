---
"@memberjunction/connector-constant-contact": major
---

Constant Contact connector — v2.0.0 (major redo over the previously published 1.x).

Full re-extract + re-verify: 65 in-scope Constant Contact V3 objects (contacts, lists, tags, segments, custom fields, bulk activities, email campaigns, campaign activities, reporting, account services). OAuth2 Authorization Code with rotating refresh tokens (configurable token endpoint), cursor pagination (`_links.next`), incremental via `updated_after`/`after_date`. Separate routes (partner webhooks, SMS, legacy V2/EventSpot, Zapier/Make) documented out-of-scope.

Proven via credential-free mock hybrid-e2e: all objects land rows, idempotent (three-sync zero-growth), incremental narrowing, delta CRUD, custom-column capture; identity invariants validated. Breaking: object set + primary-key identity re-derived from the V3 schema, so this supersedes the prior published metadata.
