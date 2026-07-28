---
"@memberjunction/connector-nimble-ams": patch
---

Nimble AMS — two live-verified sync fixes (0 → 7,221 Contacts synced after the fix).

- **SOQL fetch was a total blocker.** `BuildSOQL` issued `SELECT FIELDS(ALL)`, which Salesforce rejects unless a `LIMIT ≤ 200` is present — but the connector deliberately omits `LIMIT` so Salesforce's native `nextRecordsUrl` pagination isn't capped. The two requirements are mutually exclusive, so every SOQL object returned HTTP 400 `MALFORMED_QUERY` ("The SOQL FIELDS function must have a LIMIT of at most 200") and synced 0 rows. Replaced `FIELDS(ALL)` with a describe-driven explicit field list (compound `address`/`location` fields excluded — they can't be SELECTed directly, which is why `FIELDS(ALL)` was originally used). An explicit SELECT has no `LIMIT` requirement, so native pagination is preserved and every object now fetches.
- **client_credentials token host.** The token exchange was posted to `LoginUrl` (default `login.salesforce.com`), which returns `invalid_grant` "request not supported on this domain" — Salesforce's client_credentials flow is only valid against the org's My Domain host. `ObtainToken` now uses the InstanceURL (My Domain) as the token host for the client_credentials grant; the refresh_token grant is unchanged.
