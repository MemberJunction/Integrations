---
"@memberjunction/connector-postgresql": patch
---

ClassName follows the catalog convention (== npm package name) so instance discovery matches; legacy 'PostgresConnector' key stays registered and a delta migration fixes existing tenants' Integration rows.
