---
"@memberjunction/connector-growthzone": minor
"@memberjunction/connector-pheedloop": minor
"@memberjunction/connector-propfuel": minor
"@memberjunction/connector-neon-crm": minor
"@memberjunction/connector-netsuite": minor
"@memberjunction/connector-fonteva": minor
"@memberjunction/connector-nimble-ams": minor
"@memberjunction/connector-path-lms": minor
"@memberjunction/connector-imis": minor
"@memberjunction/connector-netforum-enterprise": minor
"@memberjunction/connector-openwater": minor
"@memberjunction/connector-salesforce": minor
---

Fix the seed migration so `mj app install` succeeds — the migration now creates the connector's CredentialType **before** the Integration.

These connectors define their own `MJ: Credential Types` row (e.g. `PropFuel API`, `GrowthZone OAuth2`, `Salesforce JWT Bearer`) and their `Integration` row references it via `CredentialTypeID`. The published migration seeded the `Integration` but **never created the CredentialType**, so every fresh install aborted at the migration step (which runs before any metadata sync) with:

```
The INSERT statement conflicted with the FOREIGN KEY constraint "FK_Integration_CredentialType" (SQL Server)
function __mj.spCreateIntegration(...) — FK_Integration_CredentialType (PostgreSQL)
```

Root cause was in the seed-migration generator: it reset the `Integration`/`IntegrationObject`/`IntegrationObjectField` catalog between connectors but **left CredentialType rows in the generation DB**, so `mj sync push`'s SQL-logging saw the type already present and emitted no `spCreateCredentialType` call. Fixed the generator to also delete each connector's own CredentialType before its push, so the create is re-emitted; the existing `directoryOrder` (credential-type before integration) places it ahead of the Integration in the migration.

Verified: each connector's regenerated migration applies cleanly against a real `__mj` schema (real `FK_Integration_CredentialType` + `spCreate*` functions) — CredentialType created, then Integration, then objects, 0 errors. Both SQL Server and PostgreSQL migrations regenerated; same migration version (in place).

Connectors that reference a **core** credential type (`OAuth2 Client Credentials`, `Azure Service Principal`, `API Key`, `OAuth2 Password Grant`) are unaffected and unchanged — those types exist on every fresh instance.

The `spCreateCredentialType` call is also guarded with `IF NOT EXISTS` (both dialects), so installing two connectors that share a credential type (Fonteva and Salesforce both use `Salesforce JWT Bearer`) on the same instance no longer collides — the second install skips the already-created type. Verified: Salesforce-then-Fonteva on one instance, both Integrations created, 0 errors.
