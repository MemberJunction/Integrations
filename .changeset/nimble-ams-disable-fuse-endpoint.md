---
'@memberjunction/connector-nimble-ams': patch
---

`FuseEndpoint` is Disabled: it is an endpoint, not a data object.

Its own declared Description says it is "a POST-only Apex REST endpoint ... Not a data record." Its eight
declared fields describe a request/response envelope, none of which is a record key, because there is no
record. It cannot be given a primary key honestly and should not be offered in the picker as a table to
sync. One delta migration (paired T-SQL and PostgreSQL) sets the row to `Disabled` by its seeded ID.

Live Salesforce describe is unaffected: discovery still returns every object in the Nimble namespace, and
which tables to sync remains the customer's decision. This is the connector-side half of the new read-only
scope of the fleet primary-key gate (`scripts/lint-writable-pk.mjs`).
