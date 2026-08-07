---
"@memberjunction/connector-totara": patch
---

Give Totara its own credential type declaring `BaseURL` + `Token` (wstoken).

`TotaraConnector.ts` has always required both `base_url` and `wstoken` at runtime (zod: "Totara
base_url is required" / "Totara base_url must be an absolute http(s) URL"). But Totara's Integration
record pointed `CredentialTypeID` at the generic, shared "API Key" credential type, which declares
only a single API-key-shaped field — no `BaseURL`. Every connection attempt through the platform's
connection form was therefore structurally unable to satisfy the connector's own runtime requirement,
regardless of what the user entered — the same class of defect fixed for OpenWater in a separate
changeset.

No behavioral change to request logic — `BaseURL` was, and remains, a required config value; only
the credential type's ability to collect it was missing.
