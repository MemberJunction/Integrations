---
"@memberjunction/connector-rasa-io": patch
---

rasa.io: the newsletter, blast and sequence contact feeds declare the fields rasa.io returns today. `/v2/messaging/{newsletter|blast|sequence}/{id}/contacts` sends a contact's IDs in other systems as `external_identifiers`, not `identifiers`, and adds `is_subscribed`. Neither was declared, so they reached a table only where discovery happened to add them, while the declared `identifiers` column stayed empty on every row. Newsletter, Blast and Sequence Contact now declare `external_identifiers` (JSON) and `is_subscribed` (boolean). `identifiers` is set to `Disabled` on Newsletter and Blast Contact, so its column stays on existing installs but nothing new is built from it. Sequence Contact keeps `identifiers` until a sequence feed has been seen. `/v2/contacts` still sends `identifiers`, so Contact is unchanged.
