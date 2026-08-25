---
"@memberjunction/connector-bill-com": minor
---

Ship Get/Create/Update Actions for Bill.com invoices.

The connector could already write invoices — `invoices` declares `CreateAPIPath` and `UpdateAPIPath`, and
`SupportsCreate`/`SupportsUpdate` are both true — but only through `IntegrationWriteRecord`, which means
from code. Without Action metadata the write surface is not reachable by an agent or a flow, which is the
gap this closes for the accounts-receivable use case.

Actions are generated from the connector's own object model rather than hand-authored: each carries
`DriverClass='IntegrationActionExecutor'` and a `{IntegrationName, ObjectName, Verb}` config triple, and
that triple is the whole implementation. Params are derived from the invoice field set, so an agent sees
the real fields.

**Only three of the twenty-one generated actions are shipped**, because the generator emits a uniform
verb cross-product that does not match this connector's capability:

- `ActionMetadataGenerator` gates Create/Update/Delete/Upsert on a single `SupportsWrite` boolean, so it
  emitted Delete actions for all three objects even though the connector declares
  `SupportsDelete(): false`, and an Update for `receivable-payments`, which has no `UpdateAPIPath`.
- `Search` and `List` are emitted unconditionally, with no check that the connector implements them.

Those would have appeared to an agent as available operations that can only ever return `NOT_SUPPORTED`.
The generator defect is left for a separate fix — it affects every connector, and Business Central's
four-action anomaly is the same code misbehaving on an unseeded cache.

`customers` and `receivable-payments` actions are deliberately not included; only the invoice path was
asked for and only it is verified against the declared surface.
