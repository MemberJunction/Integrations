---
"@memberjunction/connector-stripe": minor
---

Enable MJ Action generation for the Stripe connector.

The connector had no `GetIntegrationObjects()` override, so the base class returned an empty object
list, `GetActionGeneratorConfig()` returned null, and **no Stripe Actions were ever generated** — the
connector was reachable by sync but not by an agent, a flow, or `IntegrationActionExecutor`, despite
declaring 63 objects and a live-verified read path.

Both overrides are now present. The object model is derived entirely from the runtime
IntegrationObject / IntegrationObjectField cache rather than a list baked into code, matching how the
rest of this connector treats its catalog: if the cache is unseeded — action generation can run
before the integration is seeded — it returns an empty array and generates nothing, and never falls
back to a hardcoded subset. A baked fallback is the `catalog-in-code` defect, which silently freezes
the object universe to whatever was current when the list was written.

No behaviour change to sync, authentication, pagination, or the declared catalog.
