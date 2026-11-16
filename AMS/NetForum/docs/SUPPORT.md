# NetForum Enterprise — Supported & Proven

> **Evidence tier:** 🥇 Production-live (real vendor API, real production dataset, read-only)  ·  **Last verified:** 2026-11-10  ·  **Proof DB(s):** —

> **Known issues:** xWeb enforces a vendor-side daily fault lock when repeated SOAP faults occur; unlearned broken facade definitions consume probe budget. Very wide live-enumerated catalogs require staged table onboarding, Explorer form-bundle exclusion, and elevated CodeGen V8 heap sizing.

## What this connector supports

**34 objects** declared across **17221 fields** (source: `metadata/integration/.netforum-enterprise.integration.json`). 10 declare a write path; 24 are read-only (pull). 23 support incremental sync.

Beyond the 34 seeded baseline objects, `DiscoverObjects` (`GetFacadeObjectList`) and `DiscoverFields` (`GetQueryDefinition`) dynamically enumerate a tenant's full live xWeb facade surface, so production environments routinely discover and sync hundreds of facade objects.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| AccreditationArea | ✓ | — (read-only) | ✓ |
| AdvocacyData | ✓ | — (read-only) | — |
| Audience | ✓ | — (read-only) | — |
| CentralizedOrderEntry | ✓ | — (read-only) | ✓ |
| CEUCredit | ✓ | — (read-only) | — |
| Chapter | ✓ | — (read-only) | ✓ |
| Committee | ✓ | — (read-only) | ✓ |
| CommitteeNominations | ✓ | `C` | ✓ |
| CommunicationPreference | ✓ | — (read-only) | — |
| ContactRequest | ✓ | `C` | ✓ |
| CustomerAction | ✓ | — (read-only) | — |
| ElectronicSubscription | ✓ | — (read-only) | — |
| EventsRegistrant | ✓ | — (read-only) | ✓ |
| EventsRegistrantGroup | ✓ | — (read-only) | ✓ |
| EventsRegistrantSession | ✓ | — (read-only) | ✓ |
| ExhibitorBoothNew | ✓ | — (read-only) | ✓ |
| ExhibitorNew | ✓ | — (read-only) | ✓ |
| FacadeObject | ✓ | — (read-only) | — |
| FundraisingEvent | ✓ | — (read-only) | — |
| FundraisingGift | ✓ | — (read-only) | ✓ |
| Individual | ✓ | `CU` | ✓ |
| IndividualAddress | ✓ | `CU` | ✓ |
| IndividualEmail | ✓ | `CU` | ✓ |
| IndividualFax | ✓ | `CU` | ✓ |
| IndividualPhone | ✓ | `CU` | ✓ |
| Invoice | ✓ | `C` | ✓ |
| InvoiceDetail | ✓ | — (read-only) | ✓ |
| InvoiceDetailAdditional | ✓ | — (read-only) | ✓ |
| InvoiceDetailCustomer | ✓ | — (read-only) | ✓ |
| Membership | ✓ | — (read-only) | — |

_First 30 of 34 objects shown, alphabetically. The full catalog is the metadata file cited above._

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually been executed against a live system is in the next section, and nothing else should be read as proven.

### How this vendor actually works

- **SOAP xWeb (`netForumXML`):** Authenticates via `Authenticate` session tokens, issues bounded concurrent `GetQuery` reads, and honours configurable per-request `requestTimeoutMs` (clamped 5 s to 10 min; paired with `fetchTimeoutMs`) so slow multi-table views do not time out prematurely.
- **Definition-driven primary keys and keyset paging:** Derives keys from `GetQueryDefinition` main-table `av_key` columns (`<prefix>_key` / `<prefix>_cst_key`), never treating the facade GUID `obj_key` as a column and never naming xWeb-blocked `*_entity_key` columns in `szColumnList`, `szWhereClause`, or `szOrderBy`. Qualifies `ORDER BY` and keyset predicates with the table/alias name because xWeb injects an extra copy of the key on explicit column lists.
- **Append-only + change-date incremental sync (`1.7.1` + joined-table watermarks):** Sends qualified `(<change_date> >= X OR <add_date> >= X)` when the main table defines both columns, ensuring newly inserted append-only ledger/participation/history rows with `NULL` `change_date` are read and advance the watermark. When an object's declared watermark sits on a joined table rather than the key's table, the predicate also ORs the key table's `<prefix>_change_date` and `<prefix>_add_date` so newly added parent rows without a joined row are still read.
- **Fault-budget protection and join hygiene (`1.7.0`–`1.7.1`):** Persists object-scoped fault learning in `.nf-learned.json` (unselectable columns, ambiguous columns, unauthorized facades, unusable default lists) outside deploy-replaced directories to protect xWeb's daily fault lock; falls back to own-table column lists when joined facade lists fail SQL; omits non-lookup `INNER JOIN` columns (`ROW_FILTERING_JOINS_LEFT_OUT`) that silently filter out records (`Individual`, `Organization`); and detaches parsed XML strings (`DetachText`) so V8 regex captures do not retain multi-MB SOAP pages in memory.
- **PostgreSQL and RSU operational considerations:** Maps unbounded strings cleanly to `TEXT`, onboards wide facade catalogs selectively through RSU, guards against duplicate GraphQL type collisions, and excludes generated NetForum forms from Explorer bundle builds with raised CodeGen V8 heap limits.

## What is proven

### Pull (read)

- **Live production syncs (SQL Server and PostgreSQL tenants):** Proven in scheduled nightly and manual production runs across live client environments, covering both declared baseline objects and large dynamically discovered xWeb facade catalogs.
- **Verified live behaviors:** `GetFacadeObjectList` / `GetQueryDefinition` enumeration, steady-state zero-fault protection via `.nf-learned.json`, own-table column fallback, non-lookup `INNER JOIN` exclusion, `add_date OR change_date` incremental reads, keyset pagination resume, and bounded memory usage via `DetachText`.
- **Unit suite:** 123 vitest tests across 9 test files driving `netforum-fake-xweb` verify fault learning, own-table fallback, row-filtering joins, watermark literals and integrity, append-only watermarks, request timeouts, ambiguous-column recovery, and parsed-value memory detachment.

### Push (write / bidirectional)

- **Status: Heavily experimental.** 10 declared objects advertise Create/Update paths in metadata, but no live write has been executed.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- **Vendor daily fault lock:** xWeb locks the account on repeated daily SOAP faults and cannot be cleared client-side; probing unlearned custom facades remains governed by the persisted daily probe budget.
- **Large-catalog MJ operational overhead:** Syncing hundreds of enumerated facade tables approaches MJ metadata/CodeGen limits and requires Explorer form-bundle exclusion, raised V8 heap ceilings for CodeGen, and staged onboarding of wide tables.
- **Live write side-effects**, deletes / tombstoning, and conflict / echo-loop resolution have never been executed or verified against a real tenant.
