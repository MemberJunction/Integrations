---
"@memberjunction/connector-rasa-io": patch
---

Opens and deliveries now sync. Newsletter, Blast and Sequence Action were keyed on a tuple that included `url`, which only clicks have, so the engine refused every other event as keyless; they are now keyed on `<parent>_id + id` (rasa.io's event id is unique per event). The eight nested collections (Contact External Identifier, the newsletter and sequence lists and subscription types, Sequence Message, Subscription Type Mapping) now carry their parent's id, declared as a link, and Contact External Identifier pages through every contact. Fetch context is per call, so `syncConcurrency` above 1 is safe. Every object and field description is rewritten in rasa.io terms. Existing installs: see MIGRATION-v3.md §4b (on MJ 6.1.x the old key columns must be unmarked by hand), then run a full sync.
