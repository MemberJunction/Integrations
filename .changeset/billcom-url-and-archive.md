---
'@memberjunction/connector-bill-com': patch
---

Stop repeating the API version in every URL, and expose invoice archive/restore.

**The version segment belonged to the path, and the base carried it too.** Every object path in the
catalog is an OpenAPI path beginning `/v3/…`, while `ResolveBaseURL` returned a gateway already
ending in `/connect/v3`. The engine builds a request as base + path, so a create went to
`…/connect/v3/v3/customers` and came back 404 — as did every update, read and fetch. Nothing caught
it: `Login` is the one endpoint the connector addresses itself, so `TestConnection` reported success
on a connection where no other verb worked, and the mock suite asserts on request bodies rather than
URLs. The gateway constants lose the version, `Login` asks for `/v3/login` explicitly, and both
`ResolveBaseURL` and `GetBaseURL` normalise whatever they are handed — a trailing `/v3` is stripped
rather than rejected, because `…/connect/v3` is the spelling the credential type's own `apiUrl` help
text recommends and existing connections are configured that way. Both spellings now resolve to the
same requests, so no database needs repairing.

**Cancellation had no supported path.** In BILL, cancelling an AR invoice means archiving it:
`InvoiceStatus` has no VOID or CANCELED value, and `DeleteRecord` correctly refuses because archive
is not a delete. The catalog has always declared `archivePath`, `archiveMethod` and `restorePath` on
the invoices object, but nothing called them. `UpdateRecord({archived: true})` cannot stand in — the
invoices object updates with `PUT`, and BILL's PUT is a full replace that answers
`400 customer: must not be null; invoiceLineItems: must not be null`. New `ArchiveInvoice` and
`RestoreInvoice` verbs POST the sub-resource, reading the path from the object's `Configuration` so a
vendor change stays a metadata edit, and falling back to the documented path when the seed predates
the key or the object is not cached at all — a cancel should not fail because discovery has not run.
Both are idempotent, matching the endpoint. Note for consumers confirming a cancellation: BILL leaves
`status` at `OPEN` and moves `archived` to true with `recordStatus` `INACTIVE`, so the check is
`archived`, never `status`.

**Validation failures now say what was wrong.** BILL reports them as a bare array of
`{timestamp, severity, message}`, which reaches `typeof body === 'object'` but carries none of the
keys `ExtractErrorMessage` looked for, so every 400 surfaced as `HTTP 400 on <verb>` with the reason
discarded. Array bodies are joined on `message`.

Verified against the BILL stage sandbox: customer and invoice create, read-back, archive (including a
second archive returning 200), and a duplicate `invoiceNumber` correctly refused with 422.
