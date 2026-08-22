# Migrations (generated)

Author `../metadata/` then run `mj sync push --dir metadata` to capture the seed SQL here,
name it `V<YYYYMMDDHHMM>__word-press__Metadata.sql` (`scripts/wrap-migration.mjs`), and let CI convert to
`../migrations-pg/`. The migration body seeds `__mj`; this connector's `mj_connector_word_press` schema holds only Flyway history.
