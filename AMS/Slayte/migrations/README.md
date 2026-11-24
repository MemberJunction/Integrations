# Migrations (generated)

Author `../metadata/` then run `node scripts/build-seed-migrations.mjs AMS/Slayte` against a clean throwaway MJ SQL Server baseline DB to generate both `migrations/V<YYYYMMDDHHMM>__slayte__Metadata.sql` and `migrations-pg/V<YYYYMMDDHHMM>__slayte__Metadata.pg.sql`.

The migration body seeds `__mj`; this connector's `mj_connector_slayte` schema holds only Skyway/Flyway history.
