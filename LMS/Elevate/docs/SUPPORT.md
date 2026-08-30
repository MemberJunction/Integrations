# Elevate LMS — Supported & Proven

> **Evidence tier:** 🧪 Mock-only (proven vs mock server, never live)  ·  **Last verified:** 2026-08-25  ·  **Proof DB(s):** SQL Server (`MJ_SS_E2E`, disposable)

> 🧪 **Mock-only:** every claim below was observed against a spec-derived mock vendor server driving the
> real MJ engine into a real SQL Server database. **No live Elevate system has been contacted and no
> vendor rows have been persisted.** The reason is a credential gap, not a defect: Elevate is deployed
> per client, there is no vendor-hosted API host, and no tenant credential existed for this build.

## Shipped by

- **[#269](https://github.com/MemberJunction/Integrations/pull/269)** — `feat(elevate): Cadmium Elevate LMS connector as an Open App`. Adds `LMS/Elevate` (connector, metadata, paired SQL Server + PostgreSQL migrations, 57 unit tests). Green on all 13 repo gates.
- **[#270](https://github.com/MemberJunction/Integrations/pull/270)** — `release: promote next to main — Elevate LMS connector (new)`. Released `@memberjunction/connector-elevate@0.2.0` to npm (tag `LMS-Elevate@0.2.0`).

## What this connector supports

**5 objects** declared across **30 fields** (source: `metadata/integration/.elevate.integration.json`). 1 declares a write path; 4 are read-only (pull). 1 supports incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| Accounting Code | ✓ | — (read-only) | — |
| Earned Credit | ✓ | — (read-only) | — |
| Product | ✓ | — (read-only) | — |
| Product Registration | ✓ | `CD` | ✓ `modified_at` |
| User | ✓ | — (read-only) | — |

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed is in the next section, and nothing else should be read as proven. In particular the
> `CD` on Product Registration is a *declared* create/cancel contract; no write has been executed
> against a live Elevate system.

### How this vendor actually works

Elevate is **not a conventional REST API** and modelling it as one produces a connector that silently
syncs nothing:

- Reads go through a **single POST door** — `POST /api/reports`. The object is chosen by a **body field**
  (`resource`), the columns by an explicit **dot-path `fields` allow-list**, and the rows by a
  SQL-WHERE-like `filters` object.
- Auth is an `api_key` carried in the **request body** — not a header, not a query parameter.
- The base URL is **per-tenant**; there is no vendor-hosted host.
- Writes are `POST /api/registrations` (create) and `POST /registrations/cancel` (cancel — a POST, not a
  DELETE, and note it carries no `/api/` prefix).
- **A single unrecognised field name fails the whole query** (HTTP 500), so the read selector is built
  from declared read-surface columns and runtime-learned labels are proven out of band before use.

## What is proven

### Pull (read)

- **Verification ladder green through `T7d`** — T0–T7 plus T7a and T7d. T7b skipped
  (`transport-requires-credentials`), T7c skipped (`no-public-sandbox`), T8 skipped (no credential).
- **Hybrid e2e on SQL Server (mock mode): run ok, zero failed cells.** Real MJ engine → real database:
  ApplyAll registered all 5 objects; forward sync **processed 6 / succeeded 6** rows with no errors;
  coverage clean (**0 zero-row objects**); watermark narrowing green via content-hash.
- **Idempotency proven:** a second sync processed 2 and wrote **0** (content-hash skip), rows stable.
- **Delta proven** on `Product`: update applied, unchanged row skipped, removed row hard-deleted.
- **Pagination is a proven negative, not an unchecked default.** One unfiltered read returned **29,003
  rows**; the same query partitioned into 15 consecutive yearly windows summed to **exactly 29,003**,
  every window HTTP 200. Five pagination parameters (`limit`, `offset`, `page`, `per_page`, `page_size`)
  were tried and none changed the count. Bulk extraction is therefore date-windowed on the watermark.
- **Error-in-a-200 handled.** The door answers an unrecognised field with an error *envelope* under HTTP
  **200**. A connector checking only the status code would read that as a successful empty page and sync
  zero rows forever; this connector detects and surfaces it.

### Push (write / bidirectional)

**Nothing is proven.** No write has been executed against a live or sandbox Elevate system. The create
and cancel contracts are declared from vendor documentation only.

## Residual gaps (honest)

- **No live verification of any kind.** Mock mode only. A later tenant credential lifts the ceiling via
  `/test-connector elevate --mode live --ad-hoc` with no rebuild.
- **`ProductRegistration` is not exercised end-to-end.** It is PK-bearing and syncable, but the e2e
  materialised only `Product` and `AccountingCode` — MJServer would not build in that sandbox for
  reasons unrelated to Elevate. Its read path is therefore unproven in practice.
- **Fixtures are not shipped with this Open App**, so the green e2e above is **not reproducible from
  this repo** — it was run in the MJ build sandbox. Reproducing it here would also require the repo's
  `test/e2e/mock-vendor-server.mjs` to honour the `BodyContains` route key, which it does not yet; every
  Elevate route posts to the same path, so without it the first route would answer every request.
- **`AccountingCode` / `User` / `EarnedCredit` have no primary key** (read-only tail). `AccountingCode.id`
  carries the same worked-example evidence as the PK-bearing `Product.id`, so that asymmetry looks like
  an extraction inconsistency worth a separate look.
- **`User.email` sits at the 255-char default** while the inferred length is 320. Oversize values are
  **skipped, not truncated** — a 320-character address would be silently dropped.
- **`Category` and `AssetAccess` are declared Report-API resources with zero discoverable fields** across
  all 73 source artifacts; they are deferred to runtime `DiscoverFields` rather than shipped as empty
  shells. The `DataPush*` / `Eventscribe*` / SSO families and the Warpwire / EthosCE add-ons are recorded
  out of scope with reasons.
