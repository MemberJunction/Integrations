# Migrations (generated)

Author `../metadata/` then run `mj sync push --dir metadata` to capture the seed SQL here,
name it `V<YYYYMMDDHHMM>__protech__Metadata.sql` (`scripts/wrap-migration.mjs`), and let CI convert to
`../migrations-pg/`. The migration body seeds `__mj`; this connector's `mj_connector_protech` schema holds only Flyway history.
