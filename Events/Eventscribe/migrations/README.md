# Migrations (generated)

Author `../metadata/` then run `mj sync push --dir metadata` to capture the seed SQL here,
name it `V<YYYYMMDDHHMM>__eventscribe__Metadata.sql` (`scripts/wrap-migration.mjs`), and let CI convert to
`../migrations-pg/`. The migration body seeds `__mj`; this connector's `mj_connector_eventscribe` schema holds only Flyway history.
