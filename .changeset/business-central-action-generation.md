---
"@memberjunction/connector-business-central": minor
---

Enable MJ Action generation for the Business Central connector.

The connector had no `GetIntegrationObjects()` override, so the base class returned an empty object
list, `GetActionGeneratorConfig()` returned null, and **no Business Central Actions were ever
generated** — despite 83 declared objects covering the full accounting surface. The connector was
reachable by pull sync and by `IntegrationWriteRecord`, but not by an agent, a flow, or
`IntegrationActionExecutor`.

Both overrides are now present. The object model is derived entirely from the runtime
IntegrationObject / IntegrationObjectField cache rather than a list baked into code: when the cache is
unseeded — action generation can run before the integration is seeded — it returns an empty array and
generates nothing, and never falls back to a hardcoded subset. With 83 objects, a fallback serving a
familiar handful would still look like it worked, which is the `catalog-in-code` defect.

Write capability carries through per object, so read-only objects cannot generate write Actions.
`accounts` is read-only in Business Central — a journal entry posts *to* an account, it never creates
one — and a Create Action there would fail at the vendor every time.

Also declares `@memberjunction/integration-engine-base` as a peer dependency, which the connector now
imports directly rather than relying on transitive resolution.

No behaviour change to sync, authentication, pagination, or the declared catalog.
