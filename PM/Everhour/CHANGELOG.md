# @memberjunction/connector-everhour

## 0.2.0

### Minor Changes

- e360e10: New Everhour connector: team users, projects, per-project tasks and team-wide time records.

  Four objects, 57 declared fields, read-only, `X-Api-Key` with the API version pinned to 1.2 (Everhour
  calls its API BETA and otherwise serves whatever is newest, which would reshape responses under a
  catalog validated against something else).

  **The `as:` prefix is the vendor's id, not an addressing convention.** An Everhour project id is
  literally `as:1234567890` for an Asana-backed project, `jr:…` for Jira, `ev:…` for one created
  natively — it is part of the identifier, documented in Everhour's own Project schema. The legacy AIDP
  driver looked like it was doing something exotic (`/projects/as:${externalId}/tasks`) only because it
  had _stripped_ the prefix on the way in, with `id.slice(3)`, to make the remainder match an Asana gid,
  and then had to reattach it to make the next call. Keeping every id exactly as Everhour issued it
  retires the question entirely: nothing in this connector is Asana-aware, and no addressing switch is
  needed.

  That prefix does have one consequence. The engine substitutes template variables with
  `encodeURIComponent`, so `{project_id}` becomes `as%3A1234567890` — and the substitution helper is
  private, so the path cannot be corrected where it is built. `MakeHTTPRequest` decodes `%3A` back to a
  literal colon on the way out. A colon is legal in both a path segment and a query value under RFC
  3986, so this is narrow by construction: only `%3A` is touched, never a general URL decode that would
  corrupt an encoded `&` or space.

  **Time records come from the team-wide door.** The legacy driver read time one project at a time,
  which is an N+1 over the project list and, at Everhour's ~20 requests / 10 seconds, the dominant cost
  of a run. `/team/time?from=&to=` returns the same records in one paged stream, so TimeRecords has no
  parent at all and `from`/`to` supplies the incremental filter directly. `from` is deliberately
  backdated by a lookback window (default 7 days, tenant-tunable as `Configuration.lookbackDays`): a
  record's `date` is the day the work happened, but the record stays editable afterwards, so filtering
  strictly from the high-water mark would land those edits never. Re-reading a week costs only reads —
  records upsert by id and the content-hash prefetch turns unchanged ones into zero writes.

  **Money stays in cents and durations in seconds**, as Everhour reports them. The legacy driver divided
  fees, rates and budgets by 100 on the way into its own schema; that is a presentation choice belonging
  to whoever consumes the data, and doing it in the connector would make the landed value disagree with
  both the API response and Everhour's own UI. Every field description names its unit.

  Two smaller things worth knowing: Everhour spells its page size `limit` where the base emits
  `pageSize`, so `BuildPaginatedURL` is overridden and clamps to the documented per-endpoint maxima
  (tasks 250). And `page` is documented on tasks and time but _not_ on `/projects` — it does work there,
  but the guarantee that a doc omission cannot become an infinite loop comes from the base's
  duplicate-page guard, not from the vendor.
