---
"@memberjunction/connector-oracle": minor
"@memberjunction/connector-postgresql": minor
"@memberjunction/connector-mysql": minor
"@memberjunction/connector-mongodb": minor
"@memberjunction/connector-snowflake": minor
"@memberjunction/connector-sqlserver": minor
---

EDS-backed ingestion connectors for six engines — Oracle Database, PostgreSQL, MySQL, MongoDB, Snowflake, and SQL Server — published as Open Apps. Each is a thin nominal leaf that delegates connect/introspect/read to the shared `MJ: External Data Sources` driver via `ExternalDataSourceRouter`; incremental sync + record assembly live in `BaseSqlExternalDataSourceConnector`. Requires `@memberjunction/*` >= 5.46.0 (the EDS-consuming connector heart + the per-engine `external-data-source-*` drivers).
