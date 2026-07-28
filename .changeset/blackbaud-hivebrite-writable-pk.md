---
'@memberjunction/connector-blackbaud': patch
'@memberjunction/connector-hivebrite': patch
---

Give every writable object a primary key (or withdraw the write it cannot honor).

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
  the POST request-*body* shape (its 12 fields are a strict subset of `tax_declaration`'s 16), not a
  record: no identifier, no GET. `tax_declaration` is already keyed on `declaration_id` and already
  owns GetTaxDeclaration / EditTaxDeclaration / DeleteTaxDeclaration, so rather than drop the
  capability, `CreateTaxDeclaration` now lives there — the same collection-POST + item-PATCH shape the
  sibling `note` object uses. **No capability is lost.**
- **`non_constituent_conversion`** → write withdrawn. The Constituent API's `ConvertToConstituent`
  operation (`/convert/{contact_id}`) converts an existing non-constituent *into* a constituent;
  nothing named "conversion" is stored or returned, and the result is a constituent this catalog
  already models and keys on `id`. There is no identifier to key on and the object declared only the
  request body. Reads are unaffected.

**Hivebrite (3)**

- **`GroupUsers`** → composite key `group_id` + `user_id`. The vendor addresses group membership as
  `POST`/`DELETE /admin/v2/topics/users` with the pair in the body; both halves were already declared
  *and* required ("Unique Group ID" / "Unique User ID"). Same shape as YourMembership's
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
