---
'@memberjunction/connector-stripe': patch
'@memberjunction/connector-totara': patch
'@memberjunction/connector-eventbrite': patch
---

Give every writable object a primary key (or withdraw the write it cannot honor).

A writable `MJ: Integration Object` with no `IsPrimaryKey` field derives a **keyless** entity. On
Postgres the save audit-wrapper then emits an empty record identifier and every save fails with
`syntax error at or near ","` — while fetch keeps succeeding, so the object reads green and persists
nothing. Five objects across these three connectors were in that state.

Each key is taken from the vendor's own schema, never invented:

- **Stripe `cash_balance`** → `customer`. Stripe's `CashBalance` schema declares `customer` as a
  property of the object, and the resource is a singleton per customer
  (`/v1/customers/{customer}/cash_balance`, GET + POST only, no collection and no item id). It is
  returned in the payload, so the column is populated rather than null.
- **Stripe `balance_settings`** → write withdrawn. `BalanceSettings` declares exactly two
  properties, `object` and `payments`; `/v1/balance_settings` takes no path variable because the
  account is implied by the API key. There is nothing to key on, and the object declared no
  create/update/delete operation either — the flag described a capability with no implementation.
  Reads are unaffected.
- **Totara `Cohort Members`** → `cohortid`, also flipped writable.
  `core_cohort_get_cohort_members` returns one row per **cohort** (`{cohortid, userids[]}`), so the
  cohort is the record identity. CodeGen omits read-only fields from the generated create/update
  sprocs, so a read-only primary key would reproduce the `@courseid is not a parameter for procedure
  spCreateCourse_Contents` failure fixed in `V202607271200`.
- **Totara `Group Members`** → `groupid`. `core_group_get_group_members` returns one row per
  **group** (`{groupid, userids[]}`), same shape; the field was already writable.
- **Eventbrite `Media Upload`** → `upload_token`. Eventbrite's two-step media workflow issues the
  token from `GET /media/upload/` and it identifies the upload for the subsequent POST. It is the
  only identifier in the Media Upload MSON type and it is vendor-issued and returned.

All three connectors are published, so each ships a **delta** migration (SQL Server + Postgres) that
UPDATEs the existing catalog rows in place — no IDs minted, no rows created, idempotent by `WHERE`,
and nothing can collide with an already-applied seed.
