# @memberjunction/connector-hivebrite

## 1.2.2

### Patch Changes

- 6ee916d: Relicense to the Business Source License 1.1.

  Metadata and documentation only: the `license` field moves to `BUSL-1.1` and the
  repo gains a LICENSE file. No runtime behaviour, API surface, or dependency
  changes. The bump exists so the new licence metadata reaches npm, since the
  registry shows the licence of the latest published version.

## 1.2.1

### Patch Changes

- 48b9abf: Give every writable object a primary key (or withdraw the write it cannot honor).

  A writable `MJ: Integration Object` with no `IsPrimaryKey` field derives a **keyless** entity. On
  Postgres the save audit-wrapper then emits an empty record identifier and every save fails with
  `syntax error at or near ","` — while fetch keeps succeeding, so the object reads green and persists
  nothing. Nine objects across these two connectors were in that state.

  Each disposition comes from the vendor's own surface, never an invented key:

  **Blackbaud (6)**

  - **`profile_picture`** → key `constituent_id`. The SKY Constituent API exposes GET and PATCH on
    `/constituents/{constituentId}/profilepicture`. One picture per constituent, no item id anywhere —
    the constituent is the identity, and it was already a declared, populated field.
  - **`acknowledgement`** → new key `acknowledgement_id` (String). SKY Gift API, changelog 2019-01-24
    "Gift Acknowledgement (Edit)": `PATCH /giftacknowledgements/{acknowledgement_id}`. The catalog had
    declared only the editable body (date, letter, status).
  - **`receipt`** → new key `receipt_id` (String). SKY Gift API, changelog 2019-01-16 "Gift Receipt
    (Edit)": `PATCH /giftreceipts/{receipt_id}`. Same story — only amount/date/number/status were
    declared.
  - **`gift_note`** → new key `id` (Int). Blackbaud publishes GetGiftNoteById / EditGiftNote /
    DeleteGiftNote, and the connector already addresses the item as
    `/nxt-data-integration/v1/re/gifts/notes/{id}`. Mirrors the sibling `note` object exactly:
    collection POST, item PATCH, keyed on `id`.
  - **`new_tax_declaration`** → write withdrawn, and its create **moved** to `tax_declaration`. It is
    the POST request-_body_ shape (its 12 fields are a strict subset of `tax_declaration`'s 16), not a
    record: no identifier, no GET. `tax_declaration` is already keyed on `declaration_id` and already
    owns GetTaxDeclaration / EditTaxDeclaration / DeleteTaxDeclaration, so rather than drop the
    capability, `CreateTaxDeclaration` now lives there — the same collection-POST + item-PATCH shape the
    sibling `note` object uses. **No capability is lost.**
  - **`non_constituent_conversion`** → write withdrawn. The Constituent API's `ConvertToConstituent`
    operation (`/convert/{contact_id}`) converts an existing non-constituent _into_ a constituent;
    nothing named "conversion" is stored or returned, and the result is a constituent this catalog
    already models and keys on `id`. There is no identifier to key on and the object declared only the
    request body. Reads are unaffected.

  **Hivebrite (3)**

  - **`GroupUsers`** → composite key `group_id` + `user_id`. The vendor addresses group membership as
    `POST`/`DELETE /admin/v2/topics/users` with the pair in the body; both halves were already declared
    _and_ required ("Unique Group ID" / "Unique User ID"). Same shape as YourMembership's
    `MembersGroups`; the repo already carries 102 composite-key objects.
  - **`FundConfigurationEntity`** → composite key `campaign_id` + `fund_id`. The vendor's own path
    template is `PUT /admin/v2/donations/campaigns/{campaign_id}/funds/{fund_id}` and both path
    variables were already declared fields.
  - **`NotificationSettings`** → new key `user_id` (Int, FK to `User.id`). A singleton per user —
    `PUT /admin/v1/users/{user_id}/notification_settings`, no collection and no item id — so the user is
    the record identity. The 15 declared fields are all preference toggles.

  Both connectors are published, so each ships a **delta** migration (SQL Server + Postgres) against the
  existing catalog rows rather than a re-seed: the seeds stay untouched and applied, no existing UUID is
  re-minted, no Flyway checksum breaks. The UPDATEs are idempotent by `WHERE`; the four created fields
  carry UUID5 IDs derived from `uuid5(DNS, 'memberjunction.integrations/<integration>/<object>/<field>')`
  so the files regenerate byte-identically.

## 1.2.0

### Minor Changes

- 37cfe35: Sample-union discovery for describe-endpoint connectors: each connector wires MJ's existing `DiscoverFieldsViaFetch` sampler into its declared catalog inside `IntrospectSchema`, unioned per object via the shared pure helper `mergeDeclaredWithSampledFields` — real widths and MJ-discovered custom columns land before the first sync (no `nvarchar(255)` overflow / `STRING_OVERFLOW_SKIPPED`). Connectors with no `IntrospectSchema` of their own get the standard `super.IntrospectSchema → sample → merge → return` override; connectors that already own an `IntrospectSchema` (HubSpot, Salesforce, Nimble AMS, YourMembership) are WRAPPED — their existing logic/caching is preserved and the union runs on the built result before return (Fonteva inherits it via Salesforce's `super`).

  The width rule is NEVER-SHRINK: `MaxLength = max(declared, measured)`. It only ever widens, so connectors that already carry real declared widths from their describe API (Salesforce/Fonteva) are never truncated below the real width, while connectors whose declared catalog has no width still adopt MJ's measured value. Connectors add no discovery/merge/sync logic of their own; MJ owns measurement, type/PK inference, persistence and reconcile. `DiscoverFields` is unchanged (no recursion). Schema-less / already-streaming connectors (PropFuel, FileFeed, RelationalDB, MJtoMJ, ORCID) are unaffected.

## 1.1.2

### Patch Changes

- dbffddf: Declare semantic lengths for url/email-class string fields (255 default → url 2048, email 320). Oversize values are skipped, not truncated — silent record-loss risk.

## 1.1.1

### Patch Changes

- cc38129: Widen prose string fields (description/notes/bio/summary/…) from the 255 default to 4000. The engine skips-not-truncates oversize values, so every such field was a silent record-skip risk — live repro: PheedLoop Members.about skipped 54 records/sync at 255 vs real 2,595-char values.

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
