---
"@memberjunction/connector-pheedloop": patch
---

PheedLoop connector: declare a rate-limit policy, and stop bounding free-text fields.

Fifteen prose fields were declared `Type: string, Length: 4000` — a width that came from sampling, not from the source. PheedLoop returns unbounded prose in all fifteen (a session `about`, an exhibitor `description`, a speaker bio), and a declared ceiling becomes a physical column width, so anything past it was truncated on the way in, silently. They are now `text`, which carries no Length.

Adds `Speakers.sessions_information` — the expanded per-session detail returned by `GET /events/{eventCode}/speakers/` alongside the `sessions` code list. Read-only, and unbounded for the same reason: one speaker with several sessions runs well past any sampled width.

The catalog change ships as a delta migration (`V202608240630__pheedloop__UnboundedText`) rather than a re-seed, so installed tenants keep their existing rows and Flyway checksums: fifteen keyed `UPDATE`s plus one guarded `INSERT`, idempotent on re-run, in both SQL Server and PostgreSQL. Metadata alone would have reached no tenant — upgrades apply only new migrations, and fresh installs run the old seed.
