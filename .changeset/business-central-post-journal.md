---
"@memberjunction/connector-business-central": minor
---

Post a journal batch to the general ledger.

Creating `journals` and `journalLines` stages a batch — it sits in Business Central unposted, and
nothing reaches the general ledger until it is posted. `PostJournal()` is that step, so A-UC7 can now
complete rather than stopping at staging.

Posting is an OData **bound action**, not a CRUD verb, so it cannot travel through the generic
Create/Update/Delete surface and cannot be emitted by `ActionMetadataGenerator`, whose verb set is
fixed at Get/Create/Update/Delete/Upsert/Search/List. It is therefore an explicit connector method
that the consuming app calls directly or wraps in an Action of its own.

The action name Microsoft documents is `Microsoft.NAV.post`, with a capitalised namespace and a
lower-case first word, and that is the form the connector sends.

**Correction (2026-08-17):** an earlier draft of this note claimed `Microsoft.NAV.Post` returns 404 and
was "pinned by test". Both halves were wrong. The test asserted only the constant's value, never the
404, and live testing against a real tenant showed the capitalised form returning **204 and posting the
journal to the general ledger**. Both casings post. Do not reach for the capitalised form as a safe way
to exercise the code path — there isn't one.

Posting is irreversible through the API — a posted journal is corrected with a reversing entry, not
un-posted — so a successful return should be treated as a ledger mutation rather than a staging step.
