# Slayte — Supported & Proven

> **Evidence tier:** 🧪 Mock-only (unit & contract tests only, never live)  ·  **Last verified:** 2026-11-24  ·  **Proof DB(s):** None (unit-tested with mock transport)

> 🧪 **Mock-only:** every claim below was verified against mocked Slayte API v2 (`2026-10-01`)
> responses in Vitest unit and contract tests. **No live Slayte workspace has been synced and no
> live vendor rows have been persisted.** Held (`"private": true`) while awaiting live workspace
> verification.

## What this connector supports

**19 objects** declared across **222 fields** (source: `metadata/integration/.slayte.integration.json`). 0 declare a write path; all 19 are read-only (pull). 1 supports incremental sync (`EventRegistrant` via `changedSince`).

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| CRMQuery | ✓ | — (read-only) | — |
| Committee | ✓ | — (read-only) | — |
| CommitteeAssignedPosition | ✓ | — (read-only) | — |
| CommitteeMember | ✓ | — (read-only) | — |
| CommitteePosition | ✓ | — (read-only) | — |
| CommitteeTerm | ✓ | — (read-only) | — |
| Directory | ✓ | — (read-only) | — |
| DirectoryEntry | ✓ | — (read-only) | — |
| Event | ✓ | — (read-only) | — |
| EventCompany | ✓ | — (read-only) | — |
| EventGuest | ✓ | — (read-only) | — |
| EventLibrarySession | ✓ | — (read-only) | — |
| EventRegistrant | ✓ | — (read-only) | ✓ |
| EventRegistration | ✓ | — (read-only) | — |
| EventSession | ✓ | — (read-only) | — |
| EventSpeaker | ✓ | — (read-only) | — |
| Individual | ✓ | — (read-only) | — |
| Organization | ✓ | — (read-only) | — |
| RelationshipDefinition | ✓ | — (read-only) | — |

### How this vendor works

- **Per-workspace host:** Slayte has no shared API host; each workspace serves `<SiteUrl>/api/v2/...` authenticated with `X-Api-Key`.
- **Shared CRM Queries for bulk Individuals & Organizations:** Slayte API v2 exposes no REST list route for individuals or organizations. Bulk sync executes workspace-configured Shared CRM Queries (`POST /v2/crm/query/{queryId}/execute?cursor=...`) using `CompanyIntegration.Configuration.individualQueryId` and `organizationQueryId` (and optional `QueryApiKey` when `crm:query` is scoped separately from `crm:read`).
- **Strict key-column validation:** Because a Shared CRM Query returns only the columns configured on that query, both `TestConnection` and `FetchChanges` fail with an actionable error if the query ID is missing or if returned rows omit a recognized UUID primary key column (`individualUuid` / `organizationUuid` / `uuid` / `id`).
- **Zero-based REST paging:** Committee and Event collections use 0-based `page` numbering (`page=0` is the first page, `pageSize` max `250`); the connector translates MJ's 1-based page counter automatically.
- **Hybrid schema discovery:** Metadata declares only built-in Slayte v2 core fields; workspace custom fields and saved-query columns are discovered automatically via `IntrospectSchema` sample-union (`@memberjunction/connector-schema-merge`).

## What is proven

### Pull (read)

- **Status: Mock-only (unit tests).** No live Slayte workspace has been synced yet.
- Verified in Vitest (`src/__tests__/SlayteConnector.test.ts`):
  - Credential & `SiteUrl` normalization (`/api` and `/v2` deduplication, dual `ApiKey`/`QueryApiKey` routing)
  - `TestConnection` (success with `X-Api-Version`, `401 API_KEY_EXPIRED`, `403 SCOPE_REQUIRED`, missing key column failure)
  - Cursor-paginated Shared CRM Query execution (`Individual`, `Organization`), parameter forwarding, warning surfacing, missing query ID / missing key column errors
  - `CRMQuery` catalog listing (`ind` + `org`) and cursor-paginated `DirectoryEntry` walks
  - 0-based REST page translation, `total`-based `HasMore` termination, point-lookup `GetRecord`, `Retry-After` extraction, and `IntrospectSchema` sample-union merge

### Push (write / bidirectional)

- **Status: Not supported (read-only connector).** `SupportsCreate`, `SupportsUpdate`, `SupportsDelete`, and `SupportsUpsert` are all `false`.

## Residual gap (honest)

- **No live workspace sync yet** — connector is held (`"private": true`) pending live credential verification against a real Slayte workspace.
- **Per-record Individual/Organization child walks** (`/v2/crm/individual/{uuid}/membership`, `/relationship`, and organization equivalents) are intentionally excluded in v0.1.0 to avoid N+1 per-record fan-out; bulk Shared CRM Queries cover membership, organization, and address data without per-record walks.
- **Standalone commerce/orders REST endpoints** are not exposed in Slayte API v2 (`2026-10-01`); order columns can be projected through a Shared CRM Query.
