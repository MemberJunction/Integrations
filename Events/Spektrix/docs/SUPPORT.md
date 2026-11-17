# Spektrix — Supported & Proven

> **Evidence tier:** 🥇 Production-live (real vendor API, real production dataset, read-only)  ·  **Last verified:** 2026-10-22  ·  **Proof DB(s):** —

> **Known issues:** Full-refresh only — 0 of 65 objects support incremental sync. Bulk customer enumeration is not exposed by the v3 REST API and requires the companion Spektrix Data Feeds connector (`Events/SpektrixDataFeeds`).

## What this connector supports

**65 objects** declared across **497 fields** (source: `metadata/integration/.spektrix.integration.json`). 7 declare a write path; 58 are read-only (pull). 0 support incremental sync.

**40 objects are Active** and **25 are `Status='Disabled'`** (12 out-of-scope/sub-objects plus 13 keyless sub-objects disabled to satisfy the 5.x `lint-writable-pk` gate where 6.x content-hash identity is unavailable).

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| Address | — (Disabled) | — | — |
| AdministrativeDivision | — (Disabled) | — | — |
| AttributeDefinition | — (Disabled) | — | — |
| Band | ✓ | — (read-only) | — |
| Charge | — (Disabled) | — | — |
| Config | — (Disabled) | — | — |
| ContactPreferenceGroup | ✓ | — (read-only) | — |
| ContactPreferenceItem | ✓ | — (read-only) | — |
| Country | ✓ | — (read-only) | — |
| Customer | ✓ | `CU` | — |
| CustomerAddress | ✓ | `CUD` | — |
| CustomerAgreedStatement | ✓ | `CD` | — |
| CustomerInventoryTicketSubscription | — (Disabled) | — | — |
| CustomerSubscription | — (Disabled) | — | — |
| CustomerTag | ✓ | `CD` | — |
| CustomerTagGroup | ✓ | — (read-only) | — |
| CustomItem | — (Disabled) | — | — |
| CustomItemsAvailabilityDto | — (Disabled) | — | — |
| CustomPaymentType | ✓ | — (read-only) | — |
| DataProtectionStatement | ✓ | — (read-only) | — |
| Delivery | — (Disabled) | — | — |
| Donation | ✓ | — (read-only) | — |
| Event | ✓ | `CU` | — |
| EventAvailabilityDto | ✓ | — (read-only) | — |
| EventInstanceAvailabilityDto | ✓ | — (read-only) | — |
| EventRelatedEvent | ✓ | — (read-only) | — |
| EventRelatedStockItem | ✓ | — (read-only) | — |
| Fund | ✓ | — (read-only) | — |
| GiftVoucher | ✓ | — (read-only) | — |
| Instance | ✓ | — (read-only) | — |

_First 30 of 65 objects shown, alphabetically. The full catalog is the metadata file cited above._

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually been executed against a live system is in the next section, and nothing else should be read as proven.

### How this vendor actually works

- **Every request is HMAC-SHA1 signed (`SpektrixAPI3`).** Sends a `Date` header and `Authorization: SpektrixAPI3 <ApiLoginName>:<Signature>` computed over `METHOD\nFULL-URL\nDATE[\nBASE64(MD5(body))]` using the base64-decoded `ApiSecretKey` in System Owner mode.
- **Per-tenant base URL from `ClientName`.** Resolves `https://system.spektrix.com/<ClientName>/api/v3` dynamically per connection rather than using a single shared host.
- **Nested object doors and `$expand`.** `Customer` has no bulk list endpoint in REST v3 (direct GETs require an id or lookup value); `Customer` and Order line items arrive nested inside `/orders`, walked generically via `Configuration.accessPath` and `$expand` query parameters.
- **Calendar-month date windows instead of pagination.** REST v3 exposes no general page cursor, so heavy doors read in calendar-month batches (`fetchWindow` / `accessPath.doorFetchWindow`) using each object's exact vendor query parameter names (`instanceStart_from`/`instanceStart_to`, `startFrom`/`startTo`, `DateFrom`/`DateTo`, `start_from`/`start_to`), resumable via `NextAfterKeyValue`.
- **Tenant-specific custom attributes.** `attribute_*` properties are discovered per tenant via `IntrospectSchema` (unioning declared fields with a bounded live sample) and captured across 14 documented attribute-bearing objects; honours `Retry-After` on 429 and 503.

## What is proven

### Pull (read)

- **Live production sync (PostgreSQL tenant, 2026-10-22):** Executed read-only against a live customer Spektrix tenant on PostgreSQL, materializing and populating core ticketing, event, instance, seating plan/availability status, price/price-list/pricing-set, band, membership, offer, stock-item, contact-preference, data-protection, tag/tag-group, custom-payment-type, country, tribute-type, and venue tables.
- **Build-time verification:** Hybrid end-to-end run against a mock Spektrix vendor and the real MJ engine on SQL Server (`MJ_SS_E2E`), unauthenticated RealityProbe against the Spektrix API Help surface, and **61 unit tests** (`SpektrixConnector.test.ts` and `HmacRequestSigner.test.ts`) passing in package.

### Push (write / bidirectional)

- **Status: Heavily experimental.** 7 objects declare write paths (`Customer`, `CustomerAddress`, `CustomerAgreedStatement`, `CustomerTag`, `Event`, `Order`, `PriceList`), exercised against the mock vendor server during build verification only.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- **Full-refresh only (`0` of 65 objects incremental):** Every sync re-reads configured objects/windows in full, which increases run cost as tenant history grows.
- **Partial live-catalog coverage:** A subset of the 40 active objects was not materialized on the initial live deployment, and 25 objects remain `Status='Disabled'`.
- **No bulk customer endpoint in REST v3:** Bulk customer extraction is absent by vendor design and lives in the companion `Events/SpektrixDataFeeds` connector.
- **Inferred wire-name casing on unexercised objects:** Fields on objects not yet exercised against a live tenant rely on camelCase inference from Spektrix Help models, and `PriceList` write payload mapping (`updatedPrice` <- `amount`) is inferred.
- **Live write side-effects**, deletes / tombstoning, and rate-limit behavior under sustained production load are unverified.
