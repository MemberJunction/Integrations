---
"@memberjunction/connector-whova": minor
---

Add the Whova connector as an Open App, ported from the MemberJunction monorepo
(`packages/Integration/connectors/src/WhovaConnector.ts`), which is being emptied of
connector source in favour of this repo.

Whova is an events / conference-management platform. The connector is read-only across
the three objects Whova exposes programmatically — Attendees, Orders and Registrants —
each scoped by a required per-tenant Event.

**Honest scope — this connector ships un-provable and is held back from npm.**
Whova publishes no machine-readable API contract and no native third-party REST API;
access is partner-gated. That has three consequences the port preserves rather than
papers over:

- The base URL, auth scheme and per-object REST paths are resolved at runtime from the
  credential / `CompanyIntegration.Configuration` rather than hardcoded, because no
  credential-free source establishes them.
- The three seeded Integration Objects carry an **empty `APIPath` and `Status = 'Disabled'`**.
  `IntegrationObject.APIPath` is non-nullable, and no path is provable from public
  documentation, so an empty string is recorded as "not yet discovered" — asserting
  nothing — with `Configuration.APIPathPendingDiscovery` and `Configuration.APIPathNote`
  spelling that out for anyone who reads the row. Fabricating a plausible path would have
  produced a connector that looks live and silently isn't.
- `package.json` is `"private": true`, so the package sits on the publish **hold** list.
  It is not published to npm until a credential plus discovered paths let the objects be
  enabled and the connector proven against a live tenant.

Two changes were made against the monorepo source during the port, both behaviour-preserving:

- `@RegisterClass(BaseIntegrationConnector, '@memberjunction/connector-whova')` is now the
  primary registration key, matching this repo's four-way identity invariant (class key ≡
  `Integrations.ClassName` ≡ `ImportPath` ≡ package name). The bare `'WhovaConnector'`
  symbol stays registered as an alias so any catalog row seeded while the connector lived
  in the monorepo keeps resolving.
- `LoadCredentials` now returns `WhovaResolvedCredentials & { Token: string }`, expressing
  in the type the guarantee its own token check already enforced at runtime. This repo
  compiles under `strict: true`, which the monorepo's server tsconfig did not.

All 23 existing unit tests port over unchanged and pass.
