---
"@memberjunction/connector-rasa-io": patch
---

rasa.io: a blast with no audience no longer stops the Blast Contact sync. rasa.io answers `/v2/messaging/blast/{id}/contacts` for such a blast with HTTP 400 "No target lists configured" instead of an empty page. The connector treated that as a failed read, so the object stopped at that blast every run: blasts after it were never read, and the watermark was held, so the same blast stopped the next run too. That one answer is now read as "no contacts" and the blast is skipped with a `PARENT_HAS_NO_AUDIENCE` warning, the way a 404 on a per-parent read already is. Any other 400 still fails the read.
