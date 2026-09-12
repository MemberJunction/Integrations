# @memberjunction/connector-asana

## 0.2.2

### Patch Changes

- 06b2b4b: Allow MemberJunction 6.x as a peer. Every connector capped its `@memberjunction/*` peers at `<6.0.0`; the ceiling moves to `<7.0.0`, and `mj-app.json.mjVersionRange` moves with it so npm and `mjdev app register` agree. Floors are unchanged, so 5.x hosts are unaffected.

  Why the ceiling is the fix on a 6.x host: pnpm's `auto-install-peers` satisfies an unmet peer range by installing a **second** copy of `@memberjunction/core`, and two copies of core in one process is the failure that surfaces as thousands of unrelated-looking type errors. Business Central hit exactly this and was widened alone (#180, then #208 for the manifest); this brings the other 56 connectors, the two private platform packages, and the shared `connector-id-window-scan` package to the same range, so the duplicate cannot return transitively through a shared dependency either. The scaffolding scripts (`new-connector`, `scaffold-openapps`, `split-into-packages`) now mint `<7.0.0` too, so a new connector does not reintroduce the cap.

  Verified at compile time, not at runtime: all 61 packages in the repo (57 connectors, the two private platform packages, the two shared packages) type-check against `@memberjunction/*@6.1.0-edge.5` — the only 6.x published at the time; there is no stable 6.x yet — with every framework `.d.ts` resolved from the 6.x install and none from 5.x. That check is `npm run check:mj-compat` (`scripts/typecheck-against-mj.mjs`), added with this change so the claim can be re-run against any MJ version. It is API compatibility at the type level; the only runtime evidence on a 6.x host remains the Business Central team's edge deployment.

## 0.2.1

### Patch Changes

- 6ee916d: Relicense to the Business Source License 1.1.

  Metadata and documentation only: the `license` field moves to `BUSL-1.1` and the
  repo gains a LICENSE file. No runtime behaviour, API surface, or dependency
  changes. The bump exists so the new licence metadata reaches npm, since the
  registry shows the licence of the latest published version.

## 0.2.0

### Minor Changes

- 1a6bd43: New Asana connector: workspace users, projects, top-level tasks and subtasks over the REST API v1.0.

  Four objects, 57 declared fields, read-only, bearer personal-access-token. `Tasks` and `Subtasks` are
  templated child doors (`/tasks?project={project_gid}` and `/tasks/{parent_task_gid}/subtasks`) because
  Asana publishes no workspace-wide task listing — both declare their parent in `Configuration` so the
  engine iterates the synced parent and stamps the scope onto every child record.

  Three things the vendor forces that are worth naming, because each one fails silently rather than
  loudly:

  **Asana spells its cursor `offset`, not `cursor`.** The base's `BuildPaginatedURL` emits
  `cursor=…&limit=…`; Asana ignores the unknown parameter and re-serves page one, so the fetch loops on
  the first page and reports success. `BuildPaginatedURL` is overridden for the `Cursor` case to emit
  Asana's spelling, and to clamp `limit` into 1..100 (the vendor's hard maximum — the base narrows the
  page size to the batch's remaining capacity, so a request for 99 is normal and a request for 200 is
  not).

  **Workspace scope is a query parameter, not a template var.** `/users` and `/projects` are
  workspace-scoped and a template var would need a synced `Workspaces` object to iterate; there is none,
  so it would resolve to a permanent `PARENT_UNRESOLVED` and zero rows. The workspace comes off the
  credential and is appended per request instead.

  **Nested vendor objects are flattened onto same-named top-level keys.** A declared column maps only
  from a top-level key of the same name, so `owner: {gid}` lands NULL unless it becomes `owner_gid`
  first — `owner`/`team`/`workspace`/`assignee`/`parent` are flattened, `current_status` is split into
  its colour/title/text, and the section name is lifted out of the first project membership rather than
  paid for with a per-task `GET` as the legacy driver did.

  Custom fields are configured per workspace and can never be declared columns, so the whole array lands
  as `custom_fields_json` for consumers to project.

  `TestConnection` fails when the configured workspace is not in the token's visible workspace list.
  That combination authenticates cleanly and then syncs zero records forever, which is the failure worth
  catching at connect time rather than at 2am.
