# Migrations

These are GENERATED, not hand-authored. The connector's metadata (`../metadata/`) is the source of truth.

**Human step (migration creation):** against a dev MJ database, run from this connector directory:

```bash
mj sync push --dir metadata     # sqlLogging captures the seed SQL (literal __mj) into ./migrations
```

Then standardize the filename to `V<YYYYMMDDHHMM>__<connector>__Metadata.sql` (the helper
`scripts/wrap-migration.mjs` does this). The migration body runs `EXEC __mj.spCreateIntegrationObject …`
to seed the core integration tables; the connector's own `mj_connector_<name>` schema only holds the
Flyway history.

**CI step (automated):** `scripts/build-pg-migrations.mjs` runs `mj migrate convert` to produce the
PostgreSQL variants in `../migrations-pg/`. Do not hand-edit those.
