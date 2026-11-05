# `@memberjunction/connector-github`

GitHub REST API v3 (`2022-11-28`) Open App connector for the MemberJunction Integration Engine.

## Overview

`@memberjunction/connector-github` (`GitHubConnector`) extends `BaseRESTIntegrationConnector` to synchronize GitHub repository metadata, issues, comments, pull requests, review comments, releases, commits, and GitHub Actions workflow runs into MemberJunction, as well as create and update issues, issue comments, and pull requests.

## Supported Objects

| Object Name | Display Name | Endpoint | Incremental Sync | Write Support |
|---|---|---|---|---|
| `repositories` | Repositories | `GET /user/repos` / `GET /orgs/{owner}/repos` / `GET /installation/repositories` | `updated_at` (`since`) | Read-only |
| `issues` | Issues | `GET /repos/{full_name}/issues` | `updated_at` (`since`) | `POST`, `PATCH` |
| `issue_comments` | Issue Comments | `GET /repos/{full_name}/issues/comments` | `updated_at` (`since`) | `POST`, `PATCH` |
| `pull_requests` | Pull Requests | `GET /repos/{full_name}/pulls` | `updated_at` | `POST`, `PATCH` |
| `pull_request_comments` | Pull Request Review Comments | `GET /repos/{full_name}/pulls/comments` | `updated_at` (`since`) | Read-only |
| `releases` | Releases | `GET /repos/{full_name}/releases` | Full sync | Read-only |
| `commits` | Commits | `GET /repos/{full_name}/commits` | `committed_at` (`since`) | Read-only |
| `workflow_runs` | Workflow Runs | `GET /repos/{full_name}/actions/runs` | Full sync | Read-only |

## Authentication

Configure credentials via a linked `MJ: Credential` entity or `CompanyIntegration.Configuration`:

### 1. Personal Access Token (PAT) or OAuth Token
```json
{
  "token": "ghp_your_personal_access_token",
  "owner": "MemberJunction",
  "repositories": ["MemberJunction/MJ", "MemberJunction/Integrations"]
}
```

### 2. GitHub App Installation Token (Recommended for Organizations)
```json
{
  "appId": "123456",
  "installationId": "98765432",
  "privateKey": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----",
  "owner": "MemberJunction"
}
```
The connector signs a short-lived RS256 JWT (`iat = now - 60s`, `exp = now + 9m`) and exchanges it against `POST /app/installations/{installationId}/access_tokens`.
