# rasa.io connector — v2.x → v3.0.0 migration record

This is a **breaking (major)** release: the connector moves to rasa.io's **v2 API only**, at the vendor's
direction ("if we have to make changes, then we should look into using V2 only. And if anything is missing in
the V2 API, we can get it added ASAP"). Two things break: the **credential** changes shape, and the **v1
objects are retired**.

Why it was needed: 2.x minted a v1 token (`POST /v1/tokens`) and sent it to every object, including the 17 on
v2 paths. v2 does not accept v1 tokens, so every v2 object failed (recorded in 2.x metadata as
`HTTP 401 on GET /v2/lists with a valid v1 session token`).

## 1. The credential changes: client ID + secret

| | 2.x | 3.0.0 |
|---|---|---|
| Fields | `username`, `password`, `apiKey` (+ optional `communityIdentifier`) | `clientId`, `clientSecret` (+ optional `baseUrl`, from 3.0.2) |
| Where the customer gets them | API key from the legacy rasa.io dashboard | Generated in the rasa.io dashboard |
| Token exchange | `POST /v1/tokens`, HTTP Basic + `{ key }` | `POST /v2/tokens`, JSON `{ grant_type: "client_credentials", client_id, client_secret }` |
| Token lifetime | fixed 45 min | the response's `expires_in`, refreshed 60 s early |

The `rasa.io API` Credential Type keeps its ID and name, so `Integration.CredentialTypeID` is unchanged; only
its field schema and description change. **Existing credentials stop working**: re-enter the connection with
a v2 client ID and secret. A v1-shaped credential fails with a message saying exactly that.

Header: the token is sent as `Authorization: Bearer`. The v2 spec's security definition names a custom
`rasa-token` header, but the live API rejects it (HTTP 401 with `rasa-token` alone, verified 2026-10-20).

API host (3.0.2): the credential's optional **API host** (`baseUrl`) defaults to rasa.io production,
`https://api.rasa.io`. Client credentials generated in rasa.io's dev dashboard only work against
`https://api-dev.rasa.io` (production's `/v2/tokens` rejects them), so a test connection to rasa.io dev sets
it. A bare host (`api-dev.rasa.io`) gets `https://`.

The customer's rasa.io account needs **API access** turned on for the engagement feeds. Without it, every
`/v2/insights/*` call answers HTTP 403 `insufficient_scope`. rasa.io says it is generally on for enterprise
clients; confirm before connecting.

## 2. The Integration row is unchanged

`Integration.ID`, `Name` (`rasa`), `ClassName` and `ImportPath` are all unchanged, so existing
`CompanyIntegration` rows and sync history keep pointing at the same integration. Only `Description` and the
`Configuration` notes are updated.

## 3. 18 v1 objects are retired

`V202610161600__rasa-io__Retire_v1_Objects` deletes these IntegrationObject rows (and their fields) by
hardcoded ID. **Their destination tables are not dropped and no synced data is deleted.**

| Retired object | v2 replacement |
|---|---|
| Person, Deleted Person | Contact, Deleted Contact (already in 2.x) |
| Person Action | Newsletter / Blast / Sequence Action (new) |
| Person Send | Delivery events are in the action feeds (`action_type = 'delivered'`), per rasa.io |
| Insight Action | Newsletter / Blast / Sequence Action (new) |
| Person Topic, Insight Topic, Insight Topic Score | Not modeled: v2 has `/insights/newsletter/{id}/topics` and per-contact topics (see §6) |
| Analytics Activity / Article / Image / Topic | Deferred (see §6) |
| Person Attribute | None in v2 yet |
| Community | Newsletter is the closest v2 resource (already in 2.x); fields not compared |
| Section, Post, Content Pool Item, Lead Post | None in v2 yet |

## 4. 8 v2 objects are added (23 total)

| Object | Endpoint | Sync |
|---|---|---|
| Newsletter Action | `/v2/insights/newsletter/{id}/actions` | Incremental on `created` (`created_since`) |
| Blast Action | `/v2/insights/blast/{id}/actions` | Incremental on `created` |
| Sequence Action | `/v2/insights/sequence/{id}/actions` | Incremental on `created` |
| Newsletter Contact | `/v2/messaging/newsletter/{id}/contacts` | Full pull |
| Blast Contact | `/v2/messaging/blast/{id}/contacts` | Full pull |
| Sequence Contact | `/v2/messaging/sequence/{id}/contacts` | Full pull |
| Newsletter Deleted Contact | `/v2/messaging/newsletter/{id}/contacts/deleted` | Deletion feed on `archived_date` |
| Segment | `/v2/segments` | Full pull |

The action feeds are rasa.io's recommended bulk engagement source (one call per newsletter/blast/sequence,
not per contact). Each row is keyed on the parent id plus `id + action_type + timestamp + url`.

**History window:** rasa.io defaults `created_since` to seven days ago and rejects a value more than 24 months
ago (HTTP 400 "created_since must not be more than 24 months ago"). The action feeds declare
`Configuration.maxLookbackDays: 725`: a first sync sends `now − 725 days` (rounded up to UTC midnight), and a
stored watermark older than that is moved up to it with a `WATERMARK_CLAMPED` warning. The limit is set per
rasa.io account, and rasa.io can raise it; a connection whose account allows more sets its own
`maxLookbackDays` (see §4c).

## 4a. Changed or removed after the first live run

- **Deleted Contact** (`/v2/contacts/deleted`) is fetched once per List: rasa.io requires `list_id` (HTTP 400
  without it). It now depends on List being synced first, and its key is `list_id + id`.
- **Subscription** is removed by `V202610201700__rasa-io__Retire_Subscription_And_Integration_Run`:
  `GET /v2/subscriptions` requires a `contact_id`, so a sync would make one request per contact. Its
  create/update writes go with it. Newsletter / Blast / Sequence Contact rows still carry each contact's
  `subscriptions`.
- **Integration Run** is removed by the same migration: it is internal to rasa.io (per the vendor).

**Vendor issue, fixed 2026-10-20:** `/v2/messaging/blast` returned sequence messages as well as blasts, and
`/v2/messaging/sequence` included blasts. rasa.io fixed both lists (verified on rasa.io dev 2026-10-20: no
repeats, no overlap, every id's insights feed answers 200). Blast / Sequence Action still skip a parent that
answers HTTP 404 (e.g. a deleted blast) with a `PARENT_NOT_FOUND` warning instead of failing.

**Contact link (3.0.2):** since rasa.io's 2026-10-20 update, every Newsletter / Blast / Sequence Action row
carries `contact_id` and `email` (not in the published spec). `contact_id` resolves via `GET /v2/contacts/{id}`
and is declared as a link to Contact, so engagement joins to the contact in MJ. It is null on some events
(17 of 91 newsletter events on rasa.io dev). The row's own `id` is per event, not the contact.

## 4b. Keys, parent links and descriptions (3.0.3)

- **Event keys.** Newsletter / Blast / Sequence Action were keyed on `<parent>_id + id + action_type +
  timestamp + url`. Opens and deliveries have no `url`, so the engine refused them as keyless records and
  only clicks were stored (first production sync: 53,169 clicks of about 131k newsletter events, and 0 blast
  events, which were all opens). They are now keyed on `<parent>_id + id`: rasa.io's event `id` is unique per
  event (all 53,169 clicks, and a 500-row page of opens).
- **Parent links on nested collections.** The eight objects read from inside their parent's records
  (Contact External Identifier, Newsletter List, Newsletter Subscription Type, Sequence List, Sequence
  Exclude List, Sequence Subscription Type, Sequence Message, Subscription Type Mapping) now carry the
  parent's id (`contact_id`, `newsletter_id`, `sequence_id`, `subscription_type_id`), declared as a link to
  the parent. Before, a list shared by two newsletters collapsed to one row, and an external identifier could
  not be joined back to its contact. The link-table keys become `<parent>_id + id` (`contact_id +
  identifier`); Sequence Message and Subscription Type Mapping keep `id`. Contact External Identifier now
  pages through every contact (it read only the first page).
- **Concurrent fetches.** The per-object fetch context moved from instance fields to a per-call scope, so
  a connection with `syncConcurrency` above 1 no longer reads one object's pages with another's settings.
- **Descriptions.** Every object and field description is rewritten in rasa.io terms (177 were generated
  filler such as "Email — Contact field 'email' (Contact), rasa.io v2.").

**Upgrading an existing install:**

1. Upgrade the package and apply its migration (`V202611041422__rasa-io__Metadata`), then refresh the
   connection's tables so the eight new parent-key columns are added.
2. The event tables' old key columns must stop being key columns. CodeGen on **MJ 6.2.0 or later** drops soft
   key columns the schema no longer declares. On **MJ 6.1.x** it does not, so unmark `action_type`,
   `timestamp` and `url` as primary keys on the three action entities by hand (Entity Field `IsPrimaryKey` and
   `IsSoftPrimaryKey`), and remove them from those tables' soft key in the schema's additional schema info, or
   the next CodeGen puts them back. Until then the engine keeps refusing opens.
3. Run a **full** sync ("Sync all history") of the three action feeds and the eight nested collections. An
   incremental sync won't revisit events or rows already past the watermark.

**The refresh in step 1 empties the re-keyed tables** on MJ versions with re-key handling (6.2.0 or later, or
an install patched with it). When a table's key changes, the schema refresh deletes that table's rows and its
record maps, and leaves the table empty until the next sync reloads it. Here that is the three action tables
and the eight nested collections. Every row comes back from rasa.io in the full sync in step 3, so run that
sync straight after the refresh. Until it finishes, those tables are empty and anything that reads them
(queries, lists, reports) sees no data.

## 4c. Large histories and several accounts (3.0.5)

**Bounded batches.** The 8 parent-scoped objects (Newsletter / Blast / Sequence Action and Contact, Newsletter
Deleted Contact, Deleted Contact) are read one batch per call: at most the engine's `BatchSize` records, and
at most 10 parents visited. The cursor carries the parent being read and that parent's next page, so a call
can stop mid-parent and the next one resumes there. Before 3.0.5 a call read every page of up to 10 parents,
and a full history came back as one batch (a production install on MJ 6.1.6: 162k newsletter events, "Maximum call stack size
exceeded", no watermark saved).

**Windows on the action feeds.** Newsletter / Blast / Sequence Action are read in date windows
(`created_since` + `created_before`), oldest first, each window across every parent. The last window has no
upper bound. When a window is done for every parent, the next window's start is reported as the watermark.
On MJ 6.1 and later the engine saves that watermark every 25 batches and when a run stops early, for
example at its limit of 5,000 batches per object. An interrupted backfill then resumes from its last
finished window. On MJ 5.x an interrupted run saves no watermark, so a very large backfill has to
finish in one run.

**One connection per account.** Each rasa.io account needs its own connection, because each v2 client ID and
secret belongs to one account. Parents are read from the connection's own record maps, so connections on one
database don't read each other's newsletters. (The base connector reads the first entity map with that
object name in the database, whichever connection it belongs to.)

**Per-connection settings** in `CompanyIntegration.Configuration`, next to the engine's `syncConcurrency`
and `fetchTimeoutMs`:

| Key | Default | Meaning |
|---|---|---|
| `maxLookbackDays` | each object's own (725 on the action feeds) | How far back the action feeds go. Set it when rasa.io has raised the account's limit; a value past the account's limit fails with HTTP 400. |
| `historyWindowDays` | 90 | Width of one window on the action feeds. |

A connection with `maxLookbackDays` set reads that much history on its first full sync. One already synced
only goes further back on a full sync ("Sync all history").

## 4d. Contact feed fields

rasa.io's per-item contact feeds (`/v2/messaging/{newsletter|blast|sequence}/{id}/contacts`) send a
contact's IDs in other systems as `external_identifiers`, not `identifiers`, and add `is_subscribed`. On one
production install, `identifiers` was empty on all 54,291 Newsletter Contact rows while `external_identifiers`
was set on 54,287. `/v2/contacts` still sends `identifiers`, so Contact is unchanged.

- Newsletter, Blast and Sequence Contact declare `external_identifiers` (JSON array of `system`, `identifier`
  and `system_identifier`) and `is_subscribed` (boolean).
- `identifiers` is `Disabled` on Newsletter and Blast Contact. Its column is not dropped, so queries that name
  it keep working; it stays empty. Sequence Contact keeps `identifiers` until a sequence feed has been seen.

**Upgrading an existing install:** apply the migration and refresh the connection's tables. The refresh adds
the two columns where discovery hadn't already, and changes no keys, so no table is emptied. The contact feeds
are full pulls, so the next sync fills every row.

## 5. Actions: 12 disabled, 6 added

The 12 Actions on `Person`, `Post`, `Insight Action` and `Insight Topic` are set to `Status = 'Disabled'` by the
retire migration (not deleted, so execution logs and agent links to them stay valid). The 2.x migrations never
seeded these Actions, so on most databases the UPDATE matches no rows; it covers any that got them another way.
Six read-only Actions are added by the 3.0.0 seed delta (`V202610161602`), generated with the framework's `ActionMetadataGenerator`:

- `Rasa.io - Get / Search / List Contact`
- `Rasa.io - Get / Search / List Newsletter Action`

## 6. Deferred or not yet in v2

- **v2 analytics aggregates** (`/v2/analytics/{newsletter,sequence,blast}/{id}/…`): windowed roll-ups
  (`date_range` up to `last_three_months`), derivable from the action events. Not modeled.
- **Per-contact insights** (`/v2/insights/contact/{id}/actions`, `/topics`): rasa.io describes these as
  on-demand single-contact lookups; the bulk connector uses the per-newsletter feeds.
- **Topics** (`/v2/insights/newsletter/{id}/topics`, per-contact topics): not modeled in this release.
- **No v2 equivalent yet:** person attributes, posts, sections, content pool, lead posts. rasa.io will
  add missing v2 features on request.

Discovery no longer surfaces undeclared parent-scoped endpoints (any undeclared door with a path parameter),
since they cannot be fetched without a declared parent and would only produce tables that fail to sync.

## 7. Upgrade checklist

1. Upgrade the package and apply its migrations (MJC upgrade, or `mj app install`).
2. In the rasa.io dashboard, generate a v2 client ID and secret.
3. Update the connection's credential with them and run **Test Connection** (`GET /v2/lists`).
4. Re-run discovery and select the new objects you want (the action feeds are the engagement data).
5. Old v1 destination tables are left in place; drop them yourself once you no longer need their data.
