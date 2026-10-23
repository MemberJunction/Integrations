---
"@memberjunction/connector-rasa-io": patch
---

Newsletter, Blast and Sequence Action now declare `contact_id` (linked to Contact) and `email`. rasa.io added both to every insights action event on 2026-10-20 (they aren't in the published spec), so engagement can now be tied to the contact in MJ. Without the declaration the sync dropped them, since it keeps only declared fields. Existing installs pick up the two new columns on the next schema refresh; a full resync backfills older events, which the incremental watermark won't revisit.
