---
"@memberjunction/connector-pheedloop": patch
---

Repair `Speakers.sessions_information` — guard on the key the unique constraint actually uses.

`V202608240630__pheedloop__UnboundedText` declared the field with a plain `INSERT` guarded on `[ID]`. That
is the wrong key: on any tenant whose discovery has already run the field exists, created by discovery
under an ID the migration never chose. The guard matched nothing, the `INSERT` ran, and the database
rejected it with `duplicate key value violates unique constraint "UQ_IntegrationObjectField_Name"`.
PostgreSQL runs each migration transactionally, so that failure rolled back the fifteen width-widening
`UPDATE`s alongside it — on those tenants the migration achieved nothing at all.

The correction ships as a **new** migration rather than an edit. `V202608240630` was published in
`@memberjunction/connector-pheedloop@1.4.3`; tenants where discovery had not run applied it successfully
and Flyway recorded its checksum. Rewriting that file in place would change the checksum and fail
validation for every one of them, converting a fixable gap into a broken migration history. The published
file is left byte-for-byte intact.

`V202608250100__pheedloop__SessionsInfoUpsert` upserts on `(IntegrationObjectID, Name)` and re-states the
fifteen width declarations, so it is self-sufficient on either tenant: one that rolled back gets both the
field and the widths; one that succeeded re-sets identical values. `ID` is deliberately not rewritten when
the row exists — field maps and `IsKeyField` wiring reference it.
