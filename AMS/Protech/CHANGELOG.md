# @memberjunction/connector-protech

## 0.2.0

### Minor Changes

- ae261aa: Protech AMS (UX 365) published as an Open App, and a discovered Dataverse table can finally be read.

  **The Dataverse fix.** A table that arrives through runtime discovery could never be read, only
  enumerated. `ExternalObjectSchema` — the engine type `DiscoverObjects` returns — has no field for an
  API path, so the only name that survives into the IO row is the table's LOGICAL name. Joined onto the
  org root that produces `<EnvironmentUrl>/pa_batchlog`: singular, and missing the `/api/data/<version>/`
  segment entirely. Dataverse answers 404. The connector already selected `EntitySetName` from
  `EntityDefinitions` and filtered on it being present, then discarded it.

  Requests now pass through a repair that rewrites such a path to
  `<EnvironmentUrl>/api/data/<version>/<entityset>`, resolving the set name from `EntityDefinitions`
  rather than appending an "s" — `pa_country` is `pa_countries`. The version segment comes from the
  connection's `ApiBaseUrl`, so a tenant pinned to another `ApiVersion` keeps it.

  It lives in `MakeHTTPRequest` because that is the only hook that is both async and sees every URL:
  the base class's `BuildFullURL` is private, and `BuildPaginatedURL` / `SubstituteIDInPath` are
  synchronous and cannot await the lookup. One place therefore covers read, change-tracking delta and
  all CRUD. The repair is idempotent — anything already under `/api/data/` is returned untouched — so
  `@odata.nextLink` and `@odata.deltaLink` continuations, which come back absolute and versioned, are
  followed verbatim as before.

  Cost is bounded: the lookup is only reached by a path that actually needs repair, the
  `EntityDefinitions` sweep runs at most once per environment and is seeded for free by any describe
  already in flight, and a name the environment does not expose fails loudly with the offending path
  named instead of being re-swept on every request.

  **Why this blocked Protech specifically.** Dataverse has hidden this behind its 592 pre-seeded
  standard tables, whose `APIPath` is absolute in the frozen catalog. Protech declares no catalog at
  all: it is a thin nominal leaf whose entire `pa_*` schema is solution-installed and therefore only
  ever discovered. Every one of its objects took the broken path, which is why live probing found the
  tables and their columns but no rows. The same latent bug affected any customer's own custom tables
  on a plain Dataverse connection.

  **Protech itself** is a 22-line leaf over `DynamicsDataverseConnector` — Entra ID client-credentials
  auth, runtime `EntityDefinitions` discovery, change-tracking incremental sync and OData CRUD are all
  inherited. Its peer ceiling also moves to `<7.0.0`, matching the repo-wide range its parent already
  shipped in 1.2.3; leaving it at `<6.0.0` would have had pnpm's `auto-install-peers` pull a second
  copy of `@memberjunction/core` on a 6.x host.

  Live reads against a real Protech tenant remain unproven — `docs/SUPPORT.md` still records the
  structural tier honestly, and the IP/app-registration access path is unchanged.

### Patch Changes

- Updated dependencies [ae261aa]
  - @memberjunction/connector-microsoft-dynamics-365-dataverse@1.2.4
