# Salesforce Marketing Cloud Engagement — Supported & Proven

> **Evidence tier:** 🧪 Mock-only (proven vs mock server, never live)  ·  **Last verified:** 2026-09-13  ·  **Proof DB(s):** MJ_SS_E2E (local SQL Server)

> 🧪 **Mock-proven, never live.** This connector was built through the build-connector pipeline at its
> credential-free gate: spec-conformance against the vendor's published API contract, plus a real
> end-to-end sync through MJAPI into a SQL Server database against a **mock SFMC server**,
> outcome-asserted by rowcounts rather than by absence of error. **No authenticated call has ever been
> made to a Salesforce Marketing Cloud tenant and no customer row has ever been read.** The only live
> traffic was unauthenticated status probing of the legacy tenant-agnostic gateway
> (`www.exacttargetapis.com`), described below. The gap is a credential gap, not a defect.

> **Product identity.** This is Marketing Cloud **ENGAGEMENT** (formerly ExactTarget). It is *not*
> Marketing Cloud Next, *not* Account Engagement/Pardot, *not* Intelligence/Datorama, *not*
> Personalization, and *not* Salesforce CRM (which has its own connector). Nothing from
> `api.salesforce.com`, `pi.pardot.com` or `/services/data` belongs here.

## What this connector supports

**225 objects** declared across **3,786 fields** (source: `metadata/integration/.sfmc.integration.json`)
— 222 Active plus 3 shipped `Deprecated` (see below). **67** declare a write path (57 create / 50
update / 49 delete); **148** support incremental sync. Transport is chosen per object from metadata:
**164 SOAP** (partner API `Retrieve` / `ContinueRequest`) and **58 REST**.

| Object | Transport | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|---|
| APIProperty | SOAP | ✓ | — (read-only) | — |
| Account | SOAP | ✓ | `CUD` | ✓ |
| AccountDataItem | SOAP | ✓ | — (read-only) | — |
| AccountPrivateLabel | SOAP | ✓ | — (read-only) | ✓ |
| AccountUser | SOAP | ✓ | `CU` | ✓ |
| AddressStatus | SOAP | ✓ | — (read-only) | — |
| Application | REST | ✓ | — (read-only) | — |
| ApplicationKey | REST | ✓ | `UD` | — |
| Asset | REST | ✓ | `D` | ✓ |
| AsyncRequestResult | SOAP | ✓ | — (read-only) | ✓ |
| AsyncResponse | SOAP | ✓ | — (read-only) | — |
| AsyncResult | REST | ✓ | — (read-only) | — |
| AsyncStatus | REST | ✓ | — (read-only) | — |
| Attribute | SOAP | ✓ | — (read-only) | — |
| AttributeMap | SOAP | ✓ | — (read-only) | — |
| AttributeSet | SOAP | ✓ | — (read-only) | ✓ |
| AttributeSetDefinition | REST | ✓ | — (read-only) | — |
| AudienceItem | SOAP | ✓ | — (read-only) | ✓ |
| AuditEvent | REST | ✓ | — (read-only) | — |
| Authentication | SOAP | ✓ | — (read-only) | ✓ |
| Automation | SOAP | ✓ | `CU` | ✓ |
| AutomationActivity | SOAP | ✓ | — (read-only) | ✓ |
| AutomationActivityInstance | SOAP | ✓ | — (read-only) | ✓ |
| AutomationChain | SOAP | ✓ | — (read-only) | ✓ |
| AutomationInstance | SOAP | ✓ | `CU` | ✓ |
| AutomationInstances | SOAP | ✓ | — (read-only) | ✓ |
| AutomationNotification | SOAP | ✓ | — (read-only) | ✓ |
| AutomationTask | SOAP | ✓ | — (read-only) | ✓ |
| AutomationTaskInstance | SOAP | ✓ | — (read-only) | ✓ |
| BaseMOKeyword | SOAP | ✓ | — (read-only) | ✓ |

_First 30 of 222 Active objects shown, alphabetically. The full catalog is the metadata file cited above._

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

- **607 records processed, 607 succeeded, 0 failed** through the real engine path (connector → MJAPI →
  entity maps → upsert) against the mock vendor server — a live MJAPI against a real SQL Server
  database, not a unit-test double. `exitReason: completed`, 0 errors, 0 retry events.
- **Full-catalog coverage: 211 of 211 expected objects landed rows** (`zeroRowReal: 0`). Every one of
  the 222 Active objects is accounted for in that run: **211 covered + 2 structurally un-enumerable +
  9 keyless-in-scope** (the catalog-wide keyless figure is 12 — see the residual section).
- **Idempotency proven**: a second identical sync processed 111 objects and wrote **nothing**
  (all content-hash skipped); no table grew.
- **Incremental** (watermark GTE filter issued), **Merkle** partition change-detection (unchanged
  partition skipped with zero writes), **full-sync**, **maintenance** and **record-death** paths all pass.
- **Tenant-defined Data Extension columns are captured as first-class columns**, via the connector's
  `IntrospectSchema` sample-union — not dumped into custom-overflow. This vendor can never claim the
  "vendor-confirmed-no-customs" waiver: *every* Data Extension is customer-defined.
- Verification ladder **T0–T7 green** via the `mj-test-runner` harness. Unit tests **142/142**.

### Live (unauthenticated) service probing

The only real calls made to Salesforce infrastructure, and they carry no credential:

- 225 declared doors probed against the legacy tenant-agnostic gateway: **0 falsified**, 58
  `gated-exists` (401 — the service prefix is real and auth-gated), 167 `unverified` (596 — the probe
  cannot discriminate credential-free).
- The probe is **degraded by design on this vendor**: base URIs are tenant-specific and come from the
  token response, so no tenant host exists to probe without a credential. Achieved ceiling:
  `format-verified-no-creds`.

### Push (write / bidirectional)

- 67 of 222 Active objects declare a write path.
- **No write round-trip has been exercised end-to-end, against mock or live.** The e2e `WriteBack`
  stage skips for a structural reason: the mock origin is route-replay with no stateful vendor store,
  so a state-reflecting create → read-back → update → delete is not exercisable credential-free.
  Write-path correctness rests on the mocked T4/T5 unit tiers only.
- **No live write side-effect has been executed or verified.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- **No live tenant. Coverage against real SFMC data: 0 of 225 objects.** A live rung needs an
  Installed Package (Server-to-Server API Integration) in a customer or partner tenant.
- **Write round-trip unproven** (see above) — the single largest evidence gap in this connector, and
  material because SFMC is write-capable across *both* transports.
- **3 objects ship `Status='Deprecated'`**: `DataExtensionCreateResult`, `DataExtensionUpdateResult`,
  `TriggeredSendCreateResult`. They extend the WSDL `Result` type — returned *inside* a Create/Update
  response, never members of the retrievable set — so a production `Retrieve` yields nothing forever.
  They are documented with a `Configuration.notRetrievableReason` rather than deleted, and they are
  excluded from the coverage arithmetic rather than counted as covered.
- **2 objects are structurally un-enumerable** and sync 0 rows by vendor design, each with the reason
  recorded in metadata: `DeliveryRecord` (its parent family publishes only a POST *send* action, and
  the call additionally requires a `RecipientSendId` returned only by such a send) and `Nameid`
  (a get-by-id address with no list operation).
- **12 Active objects are keyless** — statistical PK ideation found no unique column in the pinned
  sources, so identity falls back to content hash and CodeGen creates no entity. Each carries a
  `Configuration.keylessReason`. Notably several vendor "ids" are per-call correlation ids
  (`requestServiceMessageID`) or metrics (`ageSeconds`, `invalid`) which would grow duplicates every sync
  if used as identity. (The e2e's `keylessSkipped: 9` is a narrower counter — objects skipped within the
  set it checked — not the catalog-wide figure.)
- **Scope residual**: 225 objects emitted of a 361-name pinned union. All 90 non-emitted names are
  classified by mechanical WSDL/source evidence (enumerations, nested value types, SOAP envelope and
  options machinery, response payloads, casing duplicates) — see the build's scope decision.
- **Rate-limit / backoff under load** — not stress-tested against the live service. Note that on this
  vendor a throttle can arrive as **HTTP 500 with a SOAP fault**, not only as 429.

---

_Supersede this file the moment a credentialed live sync is run._
