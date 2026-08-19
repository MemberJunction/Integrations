# @memberjunction/connector-pheedloop

## 1.4.2

### Patch Changes

- 6ee916d: Relicense to the Business Source License 1.1.

  Metadata and documentation only: the `license` field moves to `BUSL-1.1` and the
  repo gains a LICENSE file. No runtime behaviour, API surface, or dependency
  changes. The bump exists so the new licence metadata reaches npm, since the
  registry shows the licence of the latest published version.

## 1.4.1

### Patch Changes

- bc7ee68: Give every writable NeonCRM, Cvent, Impexium, PheedLoop and MagnetMail catalog object a primary key —
  or withdraw the write it cannot honor without one.

  A writable `IntegrationObject` with no `IsPrimaryKey` field derives a **keyless entity**. On Postgres,
  MJ's save audit-wrapper then emits an empty record identifier and every save fails with
  `syntax error at or near ","`, while fetch keeps succeeding — so the object reads green and persists
  nothing. Twenty objects across these five connectors were in that state.

  Metadata and delta migrations (both dialects) move together; the seed migrations are untouched, so no
  existing UUID is re-minted and no Flyway checksum breaks. Every change is evidenced below.

  **Neon CRM** — the custom-object family models each resource twice: a request-BODY shape
  (`Status=Disabled`, empty `APIPath`, `NoEnumerableEndpoint`) and the readable record `<X>Response`
  (`Status=Active`, enumerable, carrying the vendor's `DetailAPIPath`). The write was declared on the
  bodies; the keys belong on the records.

  | Object                           | Change                         | Evidence                                                                                                                                                                                                                         |
  | -------------------------------- | ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | `CustomObjectFormLayoutResponse` | **create** `id` (bigint) as PK | API v2.10 release notes publish `GET \| PUT/PATCH \| DELETE /customObjects/{apiAlias}/formLayouts/{id}`; `{id}` already fills the object's own `DetailAPIPath`/`DeleteAPIPath`. bigint matches every sibling key in this family. |
  | `CustomObjectListLayoutResponse` | **create** `id` (bigint) as PK | Same, for `/listLayouts/{id}`.                                                                                                                                                                                                   |
  | `CustomObjectFormLayout`         | write withdrawn                | Request-body shape; its field set is a strict subset of the `Response` record that the vendor actually addresses.                                                                                                                |
  | `CustomObjectListLayout`         | write withdrawn                | Same.                                                                                                                                                                                                                            |
  | `CustomObjectValidatorRule`      | write withdrawn                | Same — `CustomObjectValidatorRuleResponse` is already keyed on `id`.                                                                                                                                                             |
  | `CustomObjectField`              | write withdrawn                | No identifier at all: the vendor addresses a field as `/customObjects/{idOrApiAlias}/fields/{fieldAlias}` and this shape declares no alias.                                                                                      |

  The four withdrawn bodies' create/update is deliberately **not** re-homed onto the `Response` records
  here: those rows are `Status=Disabled`, so the operation has never run against a tenant, and re-homing
  it would newly _enable_ an unverified write path — the opposite of this change's purpose. (For
  `CustomObjectField` it would also be unfaithful: the `Response` collapses the 19 typed attribute
  variants into one `attribute` object.) Re-homing belongs in a change that can verify the request body
  live.

  **Cvent**

  | Object                       | Change                                    | Evidence                                                                                                                                                                                                               |
  | ---------------------------- | ----------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | `event-feature`              | **stamp** `type`                          | `PUT /events/{id}/features/{type}` — `type` is that path variable, already declared and required. Matches Cvent's house pattern: a parent-scoped child keys on its own item token, never on the parent.                |
  | `session-file`               | **create** `id` (String, read-only) as PK | Addressed as `.../docs/{fileId}`. The identical sibling `program-item-session-document` (`/docs`, item `/docs/{fileId}`) declares `id` — "ID of the session document", String, read-only, PK; so does `existing-file`. |
  | `speaker-file`               | **create** `id` (String, read-only) as PK | Same shape, same `{fileId}` token.                                                                                                                                                                                     |
  | `CommunicationConfiguration` | write withdrawn                           | Account-level singleton: `PUT /logs/communications/configuration` addresses the account's one configuration. No collection, no item id, one declared field — nothing to key on, and nothing may be invented.           |

  Read-only keys are correct and functionally proven: HubSpot's `V202607271200` stamped `hs_object_id`
  with `IsReadOnly` across 33 objects and saves persist on Postgres.

  **Impexium (re:Members AMS)** — its keyed `Individual` sub-resources key either on a server id
  (`Addresses.id`, `Phones.id`) or on a **natural key** when the vendor assigns none (`Emails.address`,
  `Categories.code`, `Memberships.code`). These eight split cleanly along that line.

  | Object                                                                      | Change                  | Evidence                                                                                                                                                                                                                                                                                                                                                                                                                              |
  | --------------------------------------------------------------------------- | ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | `Links`                                                                     | **stamp** `url`         | `url` is the only required field, and delete carries `DeleteIDLocation='body'` with the connector's own note that Links identifies the target via the request body — MJ fills that from the key. Same natural-key shape as sibling `Emails` (`address`).                                                                                                                                                                              |
  | `SessionRegistrations`                                                      | **stamp** `sessionCode` | `POST /Events/{Event Code}/Sessions/Register/{Customer ID}` already scopes event + customer in the path; `sessionCode` is the single required body field naming which session. Same shape as sibling `Categories` (`code`).                                                                                                                                                                                                           |
  | `EducationCredits`, `Activities`, `Notes`, `Relationships`, `Notifications` | create withdrawn        | Add-command request bodies, not records: every declared field is a writable body field — not one read-only or server-assigned field among them — and each carries `CreateIDLocation='n/a'`. That already fails at runtime today: `BaseIntegrationConnector.BuildCreatedResult` returns `Success:false` on an empty id. Microsoft's published Impexium connector documents the same five operations as add-only with no return schema. |
  | `EventAttendance`                                                           | update withdrawn        | A command: `PUT /Events/Registrants/{recordNumber}/Attended`. `UpdateIDLocation='path'` fills `{recordNumber}` from the external id, so keying on the object's single declared field (`eventOrSessionCode`) would send the event code where the registrant record number belongs — actively wrong, not merely useless.                                                                                                                |

  **PheedLoop** — `EventAttendance` write withdrawn. It is the event-scoped check-in _envelope_: all four
  declared fields are read-only arrays of attendee codes (`checked_in`/`not_checked_in` from
  `GET .../attendance/`, `attendees`/`errored_attendees` from `POST .../checkin/`), so a row is a whole
  event's aggregate with no per-record identity. Per-attendee check-in is unaffected — the sibling
  `SessionRegistration` is keyed on the attendee `code` and keeps full create/update/delete.

  **MagnetMail** — `RecipientSuppressionList` write withdrawn. It is the `uploadSuppressionList` request
  payload, and the catalog row already says so: its own `Configuration` records
  _"write-only-object: type of the uploadSuppressionList write payload (bulk suppress). No read
  operation response contains a RecipientSuppressionList element."_ (provenance: `scripts/wsdl.xml`).
  Its three fields are the bulk-suppress arguments; there is no identifier and none may be invented. The
  `Recipient` object is keyed on `id` and keeps create/update.

  Reads are unaffected on every withdrawn object. Repo-wide, writable objects with no primary key drop
  from 92 to 72.

## 1.4.0

### Minor Changes

- 37cfe35: Sample-union discovery for describe-endpoint connectors: each connector wires MJ's existing `DiscoverFieldsViaFetch` sampler into its declared catalog inside `IntrospectSchema`, unioned per object via the shared pure helper `mergeDeclaredWithSampledFields` — real widths and MJ-discovered custom columns land before the first sync (no `nvarchar(255)` overflow / `STRING_OVERFLOW_SKIPPED`). Connectors with no `IntrospectSchema` of their own get the standard `super.IntrospectSchema → sample → merge → return` override; connectors that already own an `IntrospectSchema` (HubSpot, Salesforce, Nimble AMS, YourMembership) are WRAPPED — their existing logic/caching is preserved and the union runs on the built result before return (Fonteva inherits it via Salesforce's `super`).

  The width rule is NEVER-SHRINK: `MaxLength = max(declared, measured)`. It only ever widens, so connectors that already carry real declared widths from their describe API (Salesforce/Fonteva) are never truncated below the real width, while connectors whose declared catalog has no width still adopt MJ's measured value. Connectors add no discovery/merge/sync logic of their own; MJ owns measurement, type/PK inference, persistence and reconcile. `DiscoverFields` is unchanged (no recursion). Schema-less / already-streaming connectors (PropFuel, FileFeed, RelationalDB, MJtoMJ, ORCID) are unaffected.

## 1.3.2

### Patch Changes

- 8795574: Ship the catalog delta migration (V202607032105) — the wave-1/2 metadata fixes
  (20 parent declarations, Members.about → 4000, 17 url/email widths, Reports →
  Disabled) previously existed only in the authoring JSON and never reached any
  tenant's `__mj` catalog: upgrades apply only NEW migrations and the seed was
  never regenerated. Generated per the documented pipeline (`mj sync push`
  against the released-seed state + `wrap-migration.mjs`), so `mj app upgrade`
  now converges existing installs and fresh installs run seed + delta. Also
  fixes `Status: "Inactive"` → `"Disabled"` (Inactive violates
  CK_IntegrationObject_Status on every MJ database).

## 1.3.1

### Patch Changes

- dbffddf: Declare semantic lengths for url/email-class string fields (255 default → url 2048, email 320). Oversize values are skipped, not truncated — silent record-loss risk.

## 1.3.0

### Minor Changes

- 197c567: Declare parent objects for all 20 event-scoped list fetches (Configuration.parentObjectName="Events"; SessionRegistration uses the per-var parentObjectNames map with Sessions). These objects previously emitted PARENT_UNRESOLVED and silently fetched ZERO records — the engine's §19 contract resolves template vars by authored metadata only. Also widens Members.about to 4000 (live bios up to 2,595 chars were skipped by the 255 default, skipped-not-truncated) and deactivates Reports (/reports/{reportCode}/ has no parent object supplying report codes — not list-syncable).

## 1.2.0

### Minor Changes

- 991a336: Fix the seed migration so `mj app install` succeeds — the migration now creates the connector's CredentialType **before** the Integration.

  These connectors define their own `MJ: Credential Types` row (e.g. `PropFuel API`, `GrowthZone OAuth2`, `Salesforce JWT Bearer`) and their `Integration` row references it via `CredentialTypeID`. The published migration seeded the `Integration` but **never created the CredentialType**, so every fresh install aborted at the migration step (which runs before any metadata sync) with:

  ```
  The INSERT statement conflicted with the FOREIGN KEY constraint "FK_Integration_CredentialType" (SQL Server)
  function __mj.spCreateIntegration(...) — FK_Integration_CredentialType (PostgreSQL)
  ```

  Root cause was in the seed-migration generator: it reset the `Integration`/`IntegrationObject`/`IntegrationObjectField` catalog between connectors but **left CredentialType rows in the generation DB**, so `mj sync push`'s SQL-logging saw the type already present and emitted no `spCreateCredentialType` call. Fixed the generator to also delete each connector's own CredentialType before its push, so the create is re-emitted; the existing `directoryOrder` (credential-type before integration) places it ahead of the Integration in the migration.

  Verified: each connector's regenerated migration applies cleanly against a real `__mj` schema (real `FK_Integration_CredentialType` + `spCreate*` functions) — CredentialType created, then Integration, then objects, 0 errors. Both SQL Server and PostgreSQL migrations regenerated; same migration version (in place).

  Connectors that reference a **core** credential type (`OAuth2 Client Credentials`, `Azure Service Principal`, `API Key`, `OAuth2 Password Grant`) are unaffected and unchanged — those types exist on every fresh instance.

  The `spCreateCredentialType` call is also guarded with `IF NOT EXISTS` (both dialects), so installing two connectors that share a credential type (Fonteva and Salesforce both use `Salesforce JWT Bearer`) on the same instance no longer collides — the second install skips the already-created type. Verified: Salesforce-then-Fonteva on one instance, both Integrations created, 0 errors.

## 1.1.0

### Minor Changes

- fe75578: Fix the PostgreSQL seed migration so `mj app install` succeeds on PostgreSQL.

  The 1.0.0 PostgreSQL migration (`migrations-pg/*.pg.sql`) was generated with a stale SS→PG converter (CLI 5.36, which predates the boolean SP-argument coercion shipped in 5.40.x). It emitted the integration-catalog `spCreate*` calls with integer `_Clear` flags (`p_<col>_Clear := 1`) against `BOOLEAN` parameters. Because PostgreSQL resolves function overloads by exact argument type and has no implicit `integer → boolean` cast for a named argument, every such call aborted on apply with:

  ```
  ERROR: function __mj.spCreateIntegrationObject(... p_<col>_clear => integer ...) does not exist
  ```

  Regenerated each `.pg.sql` with CLI 5.43.0, which emits native `:= TRUE`/`:= FALSE`. The same regeneration also corrects a second 5.36 defect: identifier-quoting (`."Configuration"`) leaking into string literals inside seeded descriptions and `Configuration` JSON.

  SQL Server migrations (`migrations/*.sql`) are unchanged — this is a PostgreSQL-only fix.

## 1.0.0

### Major Changes

- 50cb849: Initial release: self-contained Open App shipping its Integration metadata (objects + fields) and credential type. Strict-TypeScript build clean.
