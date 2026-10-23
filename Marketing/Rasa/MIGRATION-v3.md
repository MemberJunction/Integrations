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
stored watermark older than that is moved up to it with a `WATERMARK_CLAMPED` warning. Events older than
24 months are not available from rasa.io.

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

**Contact link (3.0.3):** since rasa.io's 2026-10-20 update, every Newsletter / Blast / Sequence Action row
carries `contact_id` and `email` (not in the published spec). `contact_id` resolves via `GET /v2/contacts/{id}`
and is declared as a link to Contact, so engagement joins to the contact in MJ. It is null on some events
(17 of 91 newsletter events on rasa.io dev). The row's own `id` is per event, not the contact.

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
