---
"@memberjunction/connector-totara": patch
"@memberjunction/connector-elevate": patch
---

Totara and Elevate get a credential-setup guide, and their credential types actually ship.

Both connectors were missing `docs/credential-setup.html` — the last two of the fleet without one. Both now have a guide written for the customer administrator who has to produce the values: what to create, where, and what to send back.

The same two connectors were also the only ones of twenty-eight whose `.mj-sync.json` did not list `credential-type` in `directoryOrder`. Totara has carried a credential-type definition and a field schema all along, and none of it ever reached a tenant. Elevate had no credential-type at all, so nothing described its fields. Both are fixed: `credential-type` is listed first, as on the other twenty-six, and Elevate gains a definition and schema for the Report API — `SiteUrl` and `ApiKey`, matching what the connector actually reads.
