---
"@memberjunction/connector-rasa-io": patch
---

rasa.io: read parent-scoped objects (the newsletter, blast and sequence action and contact feeds) one bounded batch per call. Before, a call read every page of up to 10 parents, so a full history came back as one batch: on one production install, 162k newsletter events failed the sync with "Maximum call stack size exceeded" and saved no watermark. Each call now returns at most the engine's `BatchSize` records and resumes mid-parent from its cursor. The action feeds are read in date windows (`created_since` + `created_before`, 90 days by default) across all parents, oldest first. Each finished window is reported as a safe watermark, so on MJ 6.1+ an interrupted backfill resumes from its last finished window.

Also:
- Parents are read from the connection's own record maps. Before, they came from whichever entity map in the database had that object name, so a second rasa.io connection on the same database read the first account's parents.
- A connection can set `maxLookbackDays` and `historyWindowDays` in its `Configuration`. rasa.io sets the history limit per account; the objects' 725 days stay the default.
- Fixed a short-page check that ended paging early. The connector compared a page with the object's page size, not with the `limit` it asked for. When the base asked for less than a full page to fit the batch, a full answer to that smaller request was taken as the end of the data.
