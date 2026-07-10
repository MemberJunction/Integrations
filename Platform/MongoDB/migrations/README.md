# Migrations

GENERATED at publish time, not hand-authored. The connector's metadata (`../metadata/`) is the source of truth.

**This Open App is staged for MemberJunction 5.46.0** — it consumes the EDS-consuming connector heart
(`@memberjunction/integration-connectors`) and the `MongoExternalDriver` EDS driver, both of which publish in 5.46.0.
Until then it is not buildable/installable. At 5.46.0 ship:

1. Add the `@memberjunction/*` peers to devDependencies (`^5.46.0`) and `npm install`; decide whether to bundle
   `@memberjunction/external-data-source-mongodb` as a dependency (self-contained connector) vs. keep it a peer.
2. `mj sync push --dir metadata` against a fresh 5.46 DB (sqlLogging captures the seed SQL here), then
   `wrap-migration.mjs` → `V<YYYYMMDDHHMM>__mongodb__Metadata.sql`, then `build-pg-migrations.mjs`.
3. Run `scripts/validate-invariants.mjs`, build, and un-draft the PR.
