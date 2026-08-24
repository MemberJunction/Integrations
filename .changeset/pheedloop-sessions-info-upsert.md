---
"@memberjunction/connector-pheedloop": patch
---

PheedLoop: `Speakers.sessions_information` upserts instead of colliding with the copy discovery already created.

`V202608240630__pheedloop__UnboundedText` guarded its INSERT on `[ID]`. That is the wrong key. On any tenant whose discovery has run, the field already exists under an ID the migration never chose, so the guard matched nothing, the INSERT ran, and the database rejected it:

```
duplicate key value violates unique constraint "UQ_IntegrationObjectField_Name"
```

PostgreSQL runs each migration transactionally, so the fifteen type widenings in the same file rolled back with it and the whole upgrade failed.

Now keyed on `(IntegrationObjectID, Name)` — the constraint's own key — as an UPDATE followed by a guarded INSERT. The UPDATE is also the correct intent rather than a collision dodge: a discovered field carries `MetadataSource='Discovered'` and a sampled width, and declaring it means saying so, so the row is moved to `text` / no Length / `Declared`. The existing row's `ID` is deliberately preserved, since field maps and `IsKeyField` wiring reference it.
