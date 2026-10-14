---
"@memberjunction/connector-business-central": minor
---

Record rules for ERP master-data sync, read from each object's `Configuration`:

- `recordFilter` keeps only rows whose field is in (or not in) a list. `accounts` now declares `{ field: "accountType", in: ["Posting"] }`, so Heading, Total, Begin-Total and End-Total rows no longer reach a GL Accounts map. Skipped rows still advance the watermark.
- `parentCode` copies a parent's code onto each child row. `dimensionValues` now gets `dimensionCode`, read once per company from `/dimensions` (Business Central gives a value only its parent's per-company GUID). A shared Dimension keyed on Code can match on it.

This is the connector's part of bizapps-accounting's master-data contract (docs/ARCHITECTURE.md 2.1, bizapps-accounting#268) until the engine gains a record filter and parent-key resolution (MemberJunction/MJ#5254). The `V202610140600__business-central__MasterDataRules` migration sets both rules and adds the `dimensionCode` field on installed catalogs.
