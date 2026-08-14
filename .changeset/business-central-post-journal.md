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

The action name is **case sensitive** in an asymmetric way: `Microsoft.NAV.post`, with a capitalised
namespace and a lower-case first word. `Microsoft.NAV.Post` returns 404, which reads as "no such
journal" and sends debugging toward the ID rather than the verb. Pinned by test.

Posting is irreversible through the API — a posted journal is corrected with a reversing entry, not
un-posted — so a successful return should be treated as a ledger mutation rather than a staging step.
