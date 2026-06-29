---
"@memberjunction/connector-fonteva": minor
"@memberjunction/connector-growthzone": minor
"@memberjunction/connector-membersuite": minor
"@memberjunction/connector-netforum-enterprise": minor
"@memberjunction/connector-nimble-ams": minor
"@memberjunction/connector-imis": minor
"@memberjunction/connector-microsoft-dynamics-365-dataverse": minor
"@memberjunction/connector-neon-crm": minor
"@memberjunction/connector-salesforce": minor
"@memberjunction/connector-openwater": minor
"@memberjunction/connector-pheedloop": minor
"@memberjunction/connector-netsuite": minor
"@memberjunction/connector-path-lms": minor
"@memberjunction/connector-propfuel": minor
"@memberjunction/connector-hivebrite": minor
"@memberjunction/connector-orcid": minor
"@memberjunction/connector-sharepoint": minor
"@memberjunction/connector-novi-ams": minor
"@memberjunction/connector-rhythm-software": minor
---

Fix the PostgreSQL seed migration so `mj app install` succeeds on PostgreSQL.

The 1.0.0 PostgreSQL migration (`migrations-pg/*.pg.sql`) was generated with a stale SS→PG converter (CLI 5.36, which predates the boolean SP-argument coercion shipped in 5.40.x). It emitted the integration-catalog `spCreate*` calls with integer `_Clear` flags (`p_<col>_Clear := 1`) against `BOOLEAN` parameters. Because PostgreSQL resolves function overloads by exact argument type and has no implicit `integer → boolean` cast for a named argument, every such call aborted on apply with:

```
ERROR: function __mj.spCreateIntegrationObject(... p_<col>_clear => integer ...) does not exist
```

Regenerated each `.pg.sql` with CLI 5.43.0, which emits native `:= TRUE`/`:= FALSE`. The same regeneration also corrects a second 5.36 defect: identifier-quoting (`."Configuration"`) leaking into string literals inside seeded descriptions and `Configuration` JSON.

SQL Server migrations (`migrations/*.sql`) are unchanged — this is a PostgreSQL-only fix.
