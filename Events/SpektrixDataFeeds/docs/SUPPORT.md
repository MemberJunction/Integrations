# Spektrix Data Feeds — Supported & Proven

> **Evidence tier:** 🟡 Honest-NA (unit-verified against synthetic fixtures; mTLS client certificate stays with holder)  ·  **Last verified:** 2026-11-16  ·  **Proof DB(s):** —

> 🟡 **Honest-NA — fixture-verified, no live WCF run.** This connector is verified through unit suites against synthetic WCF/NRBF payloads and fixtures. **No live Spektrix Data Feeds endpoint has been called and no rows have been persisted.** Authentication requires a per-integrator mTLS `.pfx` client certificate held by the integrator, and this package is currently held (`private: true`) pending release readiness.

## What this connector supports

**5 objects** declared across **37 fields** (source: `metadata/integration/.spektrix-data-feeds.integration.json`). 0 declare a write path; 5 are read-only (pull). 1 supports incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| Customer | ✓ | — (read-only) | ✓ |
| CustomerMerge | ✓ | — (read-only) | — |
| DataProtectionStatement | ✓ | — (read-only) | — |
| Tag | ✓ | — (read-only) | — |
| TagGroup | ✓ | — (read-only) | — |

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually been executed against a live system is in the next section, and nothing else should be read as proven.

### How this vendor actually works

- **Bulk customer extraction over WCF.** Reads `IDataFeed.GetCustomerData`, which carries a Spektrix system's bulk customer base that the v3 REST API (`Events/Spektrix`) never exposes in bulk.
- **Built-in streaming WCF client + host-registrable port.** Ships `SpektrixWcfDataFeedClient` (Node SOAP/MTOM + MS-NRBF `.NET BinaryFormatter` streaming decoder, registered by default in `registerConnector()`) while still exposing the `DataFeedClient` port (`RegisterSpektrixDataFeedClientFactory`) so an integrator host can supply a custom transport or run inside a push shim at the certificate holder's site.
- **Windowed `Customer` sync and header-list caching.** `Customer` reads sequential `[from, to)` date windows (`windowDays`, default 30, from `fetchWindowStart`) with a two-hour default `requestTimeoutMs` because the service prepares an entire window before sending bytes. `Tag`, `TagGroup`, `CustomerMerge` (composite key `from|to`, stored as a pointer rather than applied as a delete), and `DataProtectionStatement` are served from the response header lists cached for `lookupCacheMs` (default 10 minutes), falling back to a one-minute header-only window.
- **On-ingest personal-data policy.** Each connection resolves an effective `piiMode` (`pseudonymize` default via keyed HMAC-SHA256 `PseudonymKey`, `suppress`, or `raw`) along with the `anonymizePII` boolean toggle via `ResolveEffectivePiiMode`. Transformations apply inside `FetchChanges` before overflow, snapshots, content hashes, or field maps see any record, and the active mode is pinned in the watermark (`<iso>|pii=<mode>`) unless `allowPiiModeChange` is explicitly enabled.
- **Credential type `Spektrix Data Feeds Certificate`:** `ClientName`, AES-256 `CertificatePfxBase64`, `CertificatePassphrase`, `PseudonymKey` (required for `pseudonymize`), and optional `Endpoint`, read strictly from `MJ: Credentials`.

## What is proven

### Pull (read)

- **No live rows landed.** No authenticated call to a live Spektrix Data Feeds WCF service or persisted MJ database sync has been executed yet.
- **Unit-verified against synthetic fixtures:** 46 vitest tests across `SpektrixDataFeedsConnector.test.ts` (21), `pii.test.ts` (18), `catalog.test.ts` (4), and `wcfClient.test.ts` (3) covering MTOM + MS-NRBF streaming decode and mTLS options, deterministic pseudonymization/suppression/raw policies, watermark mode-lock enforcement, lookup caching, and strict catalog-to-metadata parity (`build-metadata.mjs`).
- **Seed migrations generated and linted:** SQL Server (`V202611091145__spektrix-data-feeds__Metadata.sql`) and PostgreSQL (`.pg.sql`) seed migrations generated for the credential type, integration, 5 objects, and 37 fields.

### Push (write / bidirectional)

- **Status: Not supported.** Read-only by design; the Spektrix Data Feeds WCF service exposes no write operations.

## Residual gap (honest)

- **No live authenticated WCF call** against a real Spektrix Data Feeds endpoint has been executed yet (requires an integrator mTLS `.pfx` client certificate).
- **No persisted MJ database sync** or end-to-end engine run has been executed yet.
- **Held from publish** (`private: true` in `scripts/connector-publish-scope.json`) until release readiness.
- **Customer feed scope only:** ticket and event feeds on the same WCF service are out of scope.
- **Certificate format constraint:** Node TLS requires AES-256 `.pfx` exports; legacy RC2/3DES `.pfx` certificates must be re-exported before connecting.
