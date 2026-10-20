---
"@memberjunction/connector-rasa-io": patch
---

A 404 on one parent of a per-parent object (e.g. `/v2/insights/blast/{id}/actions`) no longer stops that object's sync. The parent is skipped with a `PARENT_NOT_FOUND` warning that carries rasa.io's message, and the sync moves on. Seen live: `/v2/messaging/blast` and `/v2/messaging/sequence` currently list some of each other's ids, and the insights feed answers "'144' is a sequence, not a blast" (rasa.io is fixing the list endpoints).
