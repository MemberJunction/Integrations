---
"@memberjunction/connector-business-central": patch
---

Make `$batch` writes transactional, and stop reporting rolled-back creates as successes.

Business Central's batch endpoint is all-or-nothing only when asked: Microsoft's contract is that
`Isolation: snapshot` makes the batch run in one transaction, and "if an inner request fails after
another request(s) has committed changes, all changes within a batch will be reverted as if the batch
request never happened." The header is now sent. For journal lines this is the behaviour you want by
default — a half-staged journal batch is worse than none, because it looks real and will not balance.

That exposed a correctness bug in the batch results. Under snapshot isolation Business Central still
reports each operation's own status, so a create that was rolled back still comes back as 201. The
previous implementation reported those as successful, handing the caller an `ExternalID` for a record
that does not exist — and because the caller believed it existed, the next sync would not recreate it.
Any failure in an envelope now fails every record in it, with the vendor's message and an explicit
note that the batch was reverted.

Two smaller fixes alongside:

- **Positional fallback when ids are absent.** Responses are matched by `id`, but Business Central does
  not always echo one — Microsoft's own transactional example returns `"id": null` for every operation.
  When no response carries an id, results are matched by position rather than failing every record.
- **A short response list now fails the batch.** Fewer responses than operations means at least one
  outcome is unknown, and under a transactional batch an unknown failure may have reverted the rest.
  This was previously mishandled because `Array.find` returns `undefined` both when nothing matches and
  when the matched element is itself `undefined`, so the missing-response branch never ran.
