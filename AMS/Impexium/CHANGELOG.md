# @memberjunction/connector-impexium

## 1.0.2

### Patch Changes

- 6ee916d: Relicense to the Business Source License 1.1.

  Metadata and documentation only: the `license` field moves to `BUSL-1.1` and the
  repo gains a LICENSE file. No runtime behaviour, API surface, or dependency
  changes. The bump exists so the new licence metadata reaches npm, since the
  registry shows the licence of the latest published version.

## 1.0.1

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

## 1.0.0

### Major Changes

- 9aae94e: Initial release: self-contained Impexium (re:Members AMS) connector Open App shipping its Integration metadata (46 objects + 433 fields) and referencing the baseline `API Key with Endpoint` credential type. Strict-TypeScript build clean; hybrid-e2e GENUINE-GREEN-MOCK verified (all objects sync, content-hash idempotent).
