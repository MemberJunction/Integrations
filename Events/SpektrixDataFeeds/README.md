# @memberjunction/connector-spektrix-data-feeds

MemberJunction connector for the **Spektrix Data Feeds** service — the WCF `IDataFeed.GetCustomerData`
operation that carries a Spektrix system's full customer base, which the v3 REST API (see
`Events/Spektrix`) never exposes in bulk.

Read-only. Five objects: `Customer`, `Tag`, `TagGroup`, `CustomerMerge`, `DataProtectionStatement`.

## The two things that make this connector different

**1. The transport client is supplied by the host, not imported here.**
The service is reached through a streaming Node client for the Data Feeds protocol (SOAP/MTOM + .NET
BinaryFormatter decoding) that the integrator supplies. The client certificate it authenticates with is
issued per integrator and may open many Spektrix systems, so it stays wherever its holder runs. This package therefore declares a **port** (`DataFeedClient`, structurally identical
to the client's public API) and the host registers a factory at boot:

```ts
import { SpektrixDataFeedClient } from '<the integrator-supplied data feeds client package>';
import { RegisterSpektrixDataFeedClientFactory } from '@memberjunction/connector-spektrix-data-feeds';

RegisterSpektrixDataFeedClientFactory((options) => new SpektrixDataFeedClient(options));
```

Until a factory is registered, `TestConnection` fails with a message that says so. The same connector
code runs unchanged inside MJAPI or inside a push shim at the certificate holder's site.

**2. Personal data is handled by policy, before any row exists.**
Every connection carries `piiMode` in `CompanyIntegration.Configuration`:

| mode | what lands |
|---|---|
| `pseudonymize` (default) | keyed, deterministic replacements: `<hmac>@example.invalid`, `+1 555 01xx`, a stable synthetic name per customer id, birth year only, ZIP3/outward postcode, street lines nulled, attribute values nulled unless allowlisted |
| `suppress` | personal values nulled; ids, timestamps, town/county/country and labels kept |
| `raw` | values unchanged — only when a tenant has decided so |

The policy is applied inside `FetchChanges`, so the engine's overflow column, last-synced snapshot,
content hash and field maps all see the protected record. Tokens are HMAC-SHA256 with the
credential's `PseudonymKey`, so change detection and id joins keep working and two tenants never share
tokens. The watermark carries the mode (`<iso>|pii=<mode>`) and a run refuses to continue under a
different mode without a full resync. This is pseudonymisation, not anonymisation — say so to tenants.

Each field's class lives in the catalog (`src/catalog.ts`, mirrored into
`IntegrationObjectField.Configuration.pii`).

## Objects and sync

- `Customer` — one row per Person or Organisation, address flattened to `address_*`, lists as JSON
  text. Incremental: the connector reads `[from, to)` windows of `windowDays` (default 30) from
  `fetchWindowStart` (default 2000-01-01) to now, pages each window by cursor, and saves the window end.
  The service prepares a whole window before it sends a byte — minutes for a large one — so one
  request is in flight at a time and the default request timeout is two hours.
- `Tag`, `TagGroup`, `CustomerMerge`, `DataProtectionStatement` — the lists the service puts in the
  response header. Served from the lists captured by the last call (10-minute cache), else from a
  header-only one-minute window. `CustomerMerge` has the composite key `from|to` and is kept as a
  pointer, never applied as a delete.

## Credential type — "Spektrix Data Feeds Certificate"

`ClientName`, `CertificatePfxBase64` (AES-256 pfx; Node cannot open RC2/3DES exports),
`CertificatePassphrase`, `PseudonymKey` (≥16 chars; required for `pseudonymize`), optional `Endpoint`.
Secrets are read only from the `MJ: Credentials` record, never from the connection configuration.

## Operational notes

- Keep `TrackRecordChanges` off for the staging entities and keep them out of any entity vector sync
  or agent context when `piiMode` is not the tenant's intent.
- Error messages carry fixed text and fault codes only — never a credential, configuration or vendor
  body value.
- The ticket and event feeds exist on the same service but are not covered by the client yet; this
  package covers customers only.

## Development

```sh
npm run build            # tsc
npm run build:metadata   # regenerate metadata/integration from the compiled catalog
npm test                 # vitest, no network, no database, synthetic fixtures only
```
