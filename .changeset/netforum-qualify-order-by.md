---
"@memberjunction/connector-netforum-enterprise": patch
---

Qualify `ORDER BY` and the paging predicate with the key's table.

xWeb adds its own copy of the object's primary key to every query it builds. With an explicit column list the result therefore carries the key twice, and an unqualified `ORDER BY cpo_key` fails as SQL Server's "Ambiguous column name 'cpo_key'" — 15 of the 16 faults on the first live run whose explicit lists xWeb accepted (1.6.5, 2026-09-24). Default-list reads never hit it because the key appears once. The ORDER BY, the keyset predicate and the watermark predicate now name the column as `<table-or-alias>.<column>` whenever the object's definition knows the table, which resolves in both cases; rows are still read by the bare column name. Nothing in the vendor's documentation states that the key is injected into explicit-list queries; the fault text is where it shows.
