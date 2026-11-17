# GitHub — Supported & Proven

> **Evidence tier:** 🟡 Honest-NA (unit-verified against mocked transport; no persisted DB sync recorded)  ·  **Last verified:** 2026-11-09  ·  **Proof DB(s):** —

> 🟡 **Honest-NA — mocked transport only, no live DB sync.** All behaviour below is verified in unit tests against mocked REST responses and the real connector metadata. **No live persisted database sync or live GitHub repository write has been executed for this doc.**

## What this connector supports

**8 objects** declared across **118 fields** (source: `metadata/integration/.github.integration.json`). 3 declare a write path; 5 are read-only (pull). 6 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| commits | ✓ | — (read-only) | ✓ |
| issue_comments | ✓ | `CU` | ✓ |
| issues | ✓ | `CU` | ✓ |
| pull_request_comments | ✓ | — (read-only) | ✓ |
| pull_requests | ✓ | `CU` | ✓ |
| releases | ✓ | — (read-only) | — |
| repositories | ✓ | — (read-only) | ✓ |
| workflow_runs | ✓ | — (read-only) | — |

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually been executed against a live system is in the next section, and nothing else should be read as proven.

### How this vendor actually works

- **GitHub REST API v3 (`2022-11-28`):** Requests default to `https://api.github.com` with `Accept: application/vnd.github+json` and `X-GitHub-Api-Version: 2022-11-28`, and accept a per-connection `baseUrl` / `NavigationBaseURL` override for GitHub Enterprise Server.
- **Multi-modal authentication:** Supports Personal Access Tokens / 3LO OAuth bearer tokens (`token`, `personalAccessToken`, `accessToken`, `apiToken`) and GitHub App installation tokens (signing a short-lived RS256 JWT from `appId` + PEM `privateKey` and exchanging it via `POST /app/installations/{installationId}/access_tokens`).
- **Repository scoping and `/user/repos` rewrite:** Uses `defaultOwner` / `allowedRepositories` (or `owner` / `repositories` in configuration) to scope traversal, and rewrites `/user/repos` URLs into full endpoint URLs cleanly.
- **Parent-scoped traversal and pagination:** `repositories` serves as the root parent (`full_name` primary key) for the seven repository-scoped child objects (`{full_name}` path parameter). Pagination parses RFC 5988 `Link: <...>; rel="next"` headers alongside `page` / `per_page` (clamped `1..100`).
- **Incremental sync:** Uses `since` (`updated_at` / `committed_at`) on `repositories`, `issues`, `issue_comments`, `pull_request_comments`, and `commits`, and `sort=updated&direction=desc` client-side watermark cutoff ordering on `pull_requests`. `releases` and `workflow_runs` have no `since` filter and run full syncs per repository.

## What is proven

### Pull (read)

- **No persisted DB sync recorded.** No rows have been synced into a proof database for this connector.
- **Unit tests (15 passed in `GitHubConnector.test.ts`):** Verify PAT and GitHub App RS256 JWT authentication, `/user/repos` URL rewriting, RFC 5988 `Link` header pagination, parent `full_name` PK alignment, `since` and `pull_requests` watermark ordering, `workflow_runs` envelope unwrapping, record flattening (`head_ref`, `base_ref`, `author_login`, `merged_by_login`, `committed_at`), and `TestConnection`.
- **Seed migrations & PR CI gates:** SQL Server (`V202611050930__github__Metadata.sql`) and PostgreSQL (`.pg.sql`) seed migrations and repository CI gates validate the 8 objects and 118 fields.

### Push (write / bidirectional)

- **Status: Heavily experimental.** Create (`POST`) and Update (`PATCH`) are wired and unit-tested for `issues`, `issue_comments`, and `pull_requests`, with `SupportsCreate` and `SupportsUpdate` getters aligned to object metadata.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- **No persisted sync against a live database** has been recorded for this connector yet.
- **Live write side-effects** (`issues`, `issue_comments`, `pull_requests`) have never been executed against a real GitHub repository.
- **Full-refresh objects:** `releases` and `workflow_runs` do not support `since` filtering in GitHub REST v3 and re-read per repository on every sync.
- **Rate limits under load:** GitHub secondary/abuse rate limits and large-organization multi-repository fan-out have not been stress-tested against production tenants.
- **Deletes / tombstoning** and conflict / echo-loop resolution are not exercised.
