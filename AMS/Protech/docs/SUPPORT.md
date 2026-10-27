# Protech (AMS / UX 365) — Supported & Proven

> **Evidence tier:** ⚙️ Synthetic-local (structural only, inherited surface)  ·  **Last verified:** 2026-09-07  ·  **Proof DB(s):** —

## What this connector supports

This connector declares no static object catalog — it is a thin nominal leaf over the Microsoft Dynamics 365 (Dataverse) connector. Protech AMS / UX 365 is a managed solution installed inside a customer's Dynamics 365 environment (publisher prefix `pa_`), so what it supports is whatever tables — standard CE, `pa_*` custom, and other solution-installed — that environment exposes to the supplied Entra ID application user, discovered at connection time via `EntityDefinitions`.

## What is proven

### Pull (read)

- **Structural only.** The inherited Dataverse mechanism (Entra ID client-credentials auth, EntityDefinitions discovery, change-tracking incremental fetch) is the proven surface of `CRM/DynamicsDataverse`; no Protech tenant has been connected.

### Push (write / bidirectional)

- **Status: inherited, unverified.** The Dataverse connector supports full CRUD; no write has been executed against a Protech environment.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- **Live discovery against a real Protech tenant** — the `pa_*` schema has never been enumerated live; no public Protech data dictionary exists to check it against.
- Live **write side-effects** — never executed against a real tenant.
- **Tenant access model** — whether the customer or Protech controls the Entra ID tenant (and can create the app registration + application user) varies by engagement; credentials are typically obtained through Protech support.

---

_Capability section derived from this connector's own metadata on 2026-09-07. Proof numbers are DB ground
truth as of 2026-09-07 (`gen-support-docs.mjs`), and are re-stated verbatim — they change only when a
new live sync is run and the doc is regenerated._
