---
"@memberjunction/connector-rasa-io": patch
---

rasa.io: a newsletter, blast or sequence that can't answer a contacts read no longer stops the sync. rasa.io answers `/v2/messaging/{newsletter|blast|sequence}/{id}/contacts` with HTTP 400 when that one item isn't configured for it, e.g. a blast with no target lists ("No target lists configured"). The connector treated that as a failed read, so the object stopped at that item every run: items after it were never read, and the watermark was held, so the same item stopped the next run too. Any 400 on one item's contacts is now read as "no contacts" and the item is skipped with a `PARENT_NOT_CONFIGURED` warning carrying rasa.io's message, the way a 404 on a per-item read already is. rasa.io's message text varies, so it isn't matched. A 400 on the action feeds still fails the read, since there it can mean the date window was rejected.
