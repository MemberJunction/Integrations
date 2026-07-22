---
"@memberjunction/connector-mailchimp": major
---

Rebuild the Mailchimp connector to the pure-mechanism convention. The object/field catalog now lives entirely in Declared metadata (76 objects / 767 fields) with discovery inherited from `BaseRESTIntegrationConnector` — no baked catalog, PK/FK, required/readonly, or field constants in code. Behavior is unchanged: HTTP Basic auth with the API key, data-center prefix derived from the key suffix, uniform `count`/`offset` pagination, per-object envelope unwrapping, and named-parent-var nested CRUD. Seed migrations (SQL + PG) regenerated from the refreshed metadata.

Full-depth nested sync — e.g. a list's complete member set rather than only its first page — depends on the engine fix in MemberJunction/MJ#3246.
