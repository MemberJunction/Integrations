---
"@memberjunction/connector-wild-apricot": patch
"@memberjunction/connector-stripe": patch
"@memberjunction/connector-magnetmail": patch
"@memberjunction/connector-zendesk": patch
---

Add `push.autoCreateMissingRecords: true` to `.mj-sync.json` so `mj sync push` seeds the connector's metadata cleanly against a DB that doesn't yet hold the Integration/IntegrationObject rows (previously the child-record push failed with "Record not found — set autoCreateMissingRecords=true"). Build-time seed-generation fix only; the published runtime (`dist`) is unchanged.
