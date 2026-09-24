---
"@memberjunction/connector-netforum-enterprise": patch
---

Never name an `_entity_key` column in a GetQuery, and never send a request that is known to fault.

The first live discovery on 1.6.4 read rows from netFORUM for the first time (17 objects, real keys in the `ORDER BY`), then stopped at ten faults. Eight of the ten were `Invalid query.` on explicit column lists — 10 to 172 alias-qualified columns, no GUID, a valid key. The vendor's GetQuery page names the cause: xWeb refuses any query containing `_entity_key` (with select/insert/update/delete/exec/execute), and every netFORUM table carries a `<prefix>_entity_key`, so every list built from a definition was refused. The default lists, which never include it, were the ones that read.

- `_entity_key` columns are still discovered as columns, but never reach `szColumnList`, `szOrderBy` or `szWhereClause`, and are never chosen as the key even though they are `av_key`-typed. Keyword tokens are matched by xWeb as words (its own example filters on `mls_delete_flag=0`), so `_delete_flag` and similar columns stay.
- When the connection's default list is already known to be unusable and nothing describes an object's columns (no definition, no persisted fields), the connector no longer sends the one request left, which can only fault. Two of the ten faults were exactly that.
