# @memberjunction/connector-asana

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
