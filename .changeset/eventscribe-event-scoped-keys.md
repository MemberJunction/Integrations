---
"@memberjunction/connector-eventscribe": minor
---

Keep each event's records apart: every active object gains an `EventScope` field, and on the 17 keyed objects it joins the primary key.

All connections of one connector write into the same tables, and the engine matches an incoming row to an existing one by the entity's primary key across the whole table. Every key was a Cadmium id alone, so a client with one connection per product per event got one row per id: the same author, presenter or exhibitor in two events became a single row holding whichever event synced last.

The connector now stamps `EventScope` on every record it reads — list reads, nested door walks and single-record re-reads. The value is the connection's configured `eID` when there is one. With no eID it is the connection's own ID, so two connections share a scope only by naming the same event. An empty value is refused rather than stamped. `ExternalID` stays the vendor key, so update, delete and read-one requests are unchanged, and the stamp is stripped from every outbound write body. The five keyless objects carry `EventScope` as a plain column, which makes their content-hash identity per event too. The connection test says which way the connection will be keyed.

Ships as `V202609281056__eventscribe__EventScopeKey` (22 new field rows, both dialects; no existing row changes). Set eID before a connection's first sync if you need it: adding one later changes that connection's scope.
