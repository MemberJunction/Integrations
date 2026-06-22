# MemberJunction Integrations

Vendor integration **connectors for MemberJunction, each a self-contained mini Open App** — its own npm
package, schema, metadata-seed migrations (SQL Server + Postgres), and independent release. Every connector
lives under `<Category>/<Connector>/` and installs on demand:

```bash
mj app install https://github.com/MemberJunction/Integrations/CRM/HubSpot
```

Nothing is seeded into a MemberJunction database until you install the connector you want, and installing one
connector pulls **only** that connector's package — connectors are fully decoupled.

## How it works (full Open App model)

Each `<Category>/<Connector>/` is a real Open App, exactly like `bizapps-common`:

- **Its own package** `@memberjunction/connector-<name>` — the `@RegisterClass(BaseIntegrationConnector, …)`
  class + tests. Framework packages are **peer dependencies** (the host supplies them).
- **Its own schema** `mj_connector_<name>` — the app's namespace + `flyway_schema_history` anchor. It holds
  no tables of its own; it only exists so the Open App migration runner runs the connector's migrations.
- **Metadata-seed migrations** — `migrations/` (SQL Server) + `migrations-pg/` (Postgres). The migration body
  runs `EXEC __mj.spCreateIntegrationObject …` to seed the **core** integration catalog
  (`MJ: Integrations` / `Integration Objects` / `Integration Object Fields` + `MJ: Actions`). Installing the
  app runs the standard path: create schema → run migrations.
- **`metadata/`** is the human-editable **source of truth**; the migrations are *generated* from it.

The framework (`@memberjunction/integration-engine`, the Integration/IO/IOF tables, runtime discovery,
credential types, the bizapps Action-Category tree) stays in core MJ. The three-way invariant holds per
connector (`Integration.ClassName` == `@RegisterClass` driver == `IntegrationName`), enforced by
`scripts/validate-invariants.mjs`.

## Repository layout

```
Integrations/
├── CRM/  AMS/  LMS/  Marketing/  Finance/  Events/  Platform/      one mini Open App per connector
│   └── <Connector>/
│       ├── mj-app.json          schema: mj_connector_<name>, migrations: skyway, metadata, bootstrap package
│       ├── package.json  src/   @memberjunction/connector-<name> + tests
│       ├── metadata/            mj-sync source of truth (integration/ + actions/) — author here
│       ├── migrations/          GENERATED SS seed migrations (from `mj sync push`)
│       └── migrations-pg/       GENERATED PG variants (from `mj migrate convert`)
├── scripts/                     new-connector, wrap-migration, build-pg-migrations, validate-*, sync-manifest-versions
├── .github/workflows/           pr.yml (build/test/lint/validate-migrations/changeset) · release.yml (changesets publish)
├── .changeset/                  non-fixed → per-connector independent versions
└── turbo.json
```

`RelationalDB` / `FileFeed` are framework-generic primitives with no vendor catalog → code-only packages
(no `mj-app.json`). Workspaces glob: `["*/*"]`.

## Creating / maintaining a connector

You are only involved in **migration creation**; CI does the rest.

```bash
# 1. Scaffold (one command → buildable, lint-passing skeleton)
npm run new-connector -- CRM Acme --name "Acme CRM"

# 2. Implement CRM/Acme/src/AcmeConnector.ts and author CRM/Acme/metadata/ (the catalog + actions)

# 3. Migration creation (needs a dev MJ DB) — capture the seed SQL, then Flyway-name it
cd CRM/Acme && mj sync push --dir metadata           # writes raw seed SQL into ./migrations
cd ../.. && npm run migrations:wrap -- CRM/Acme       # → migrations/V<ts>__acme__Metadata.sql
npm run migrations:pg -- CRM/Acme                     # → migrations-pg/…pg.sql  (deterministic, no DB)

# 4. Add a changeset (drives this connector's independent version bump) and open a PR to `next`
npm run changeset
```

`pr.yml` then builds/tests the changed connector, runs the invariant + migration lint, checks PG parity, and
requires the changeset. On merge of a release, `release.yml` (changesets) publishes **only** the changed
connector packages, tags each `<pkg>@<version>`, and syncs each `mj-app.json` version/`mjVersionRange`.

## Versioning & install

- **Per-connector independent** versions (changesets non-fixed) — a Salesforce fix never bumps HubSpot.
- `mj app install …/CRM/HubSpot --version X.Y.Z` resolves the connector's scoped tag (`@memberjunction/connector-hubspot@X.Y.Z`).
- Connectors declare `mjVersionRange` (`>=5.43.0 <6.0.0`) and depend on the published MJ framework as peer deps.

## Requirements

Requires a MemberJunction host **≥ 5.43.0** (multi-app-per-repo subpath installs in `@memberjunction/open-app-engine`).

## Development

```bash
npm install
npm run build            # turbo build of every connector package
npm test                 # vitest unit tests
npm run lint             # invariants + migrations
```

## Notes

Connector **Actions** `@lookup` the bizapps Action-Category tree and **credential types**, both core-seeded
MJ metadata with stable IDs (so the baked migration SQL resolves on any install).
