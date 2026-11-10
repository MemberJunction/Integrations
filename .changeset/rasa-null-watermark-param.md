---
"@memberjunction/connector-rasa-io": patch
---

rasa.io: read an object configuration whose `watermarkParam` is `null`. The metadata has `null` on the 18 objects with no incremental param, and the config check rejected it, so the connector ignored their whole configuration. The 8 nested collections (Contact External Identifier, Newsletter List, Newsletter Subscription Type, the 4 Sequence collections, Subscription Type Mapping) then carried no parent key (`contact_id`, `newsletter_id`, `sequence_id`, `subscription_type_id`), and discovery lost `recordSchemas` and the access path. After the upgrade, run a schema refresh (MJ Central: Update Catalog) so an existing connection gets the parent-key fields.
