# @memberjunction/connector-rasa-io

## 3.0.6

### Patch Changes

- a71139e: rasa.io: a newsletter, blast or sequence that can't answer a contacts read no longer stops the sync. rasa.io answers `/v2/messaging/{newsletter|blast|sequence}/{id}/contacts` with HTTP 400 when that one item isn't configured for it, e.g. a blast with no target lists ("No target lists configured"). The connector treated that as a failed read, so the object stopped at that item every run: items after it were never read, and the watermark was held, so the same item stopped the next run too. Any 400 on one item's contacts is now read as "no contacts" and the item is skipped with a `PARENT_NOT_CONFIGURED` warning carrying rasa.io's message, the way a 404 on a per-item read already is. rasa.io's message text varies, so it isn't matched. A 400 on the action feeds still fails the read, since there it can mean the date window was rejected.

## 3.0.5

### Patch Changes

- 7495a98: rasa.io: read parent-scoped objects (the newsletter, blast and sequence action and contact feeds) one bounded batch per call. Before, a call read every page of up to 10 parents, so a full history came back as one batch: on one production install, 162k newsletter events failed the sync with "Maximum call stack size exceeded" and saved no watermark. Each call now returns at most the engine's `BatchSize` records and resumes mid-parent from its cursor. The action feeds are read in date windows (`created_since` + `created_before`, 90 days by default) across all parents, oldest first. Each finished window is reported as a safe watermark, so on MJ 6.1+ an interrupted backfill resumes from its last finished window.

  Also:

  - Parents are read from the connection's own record maps. Before, they came from whichever entity map in the database had that object name, so a second rasa.io connection on the same database read the first account's parents.
  - A connection can set `maxLookbackDays` and `historyWindowDays` in its `Configuration`. rasa.io sets the history limit per account; the objects' 725 days stay the default.
  - Fixed a short-page check that ended paging early. The connector compared a page with the object's page size, not with the `limit` it asked for. When the base asked for less than a full page to fit the batch, a full answer to that smaller request was taken as the end of the data.

## 3.0.4

### Patch Changes

- aff3339: rasa.io: read an object configuration whose `watermarkParam` is `null`. The metadata has `null` on the 18 objects with no incremental param, and the config check rejected it, so the connector ignored their whole configuration. The 8 nested collections (Contact External Identifier, Newsletter List, Newsletter Subscription Type, the 4 Sequence collections, Subscription Type Mapping) then carried no parent key (`contact_id`, `newsletter_id`, `sequence_id`, `subscription_type_id`), and discovery lost `recordSchemas` and the access path. After the upgrade, run a schema refresh (MJ Central: Update Catalog) so an existing connection gets the parent-key fields.
- Updated dependencies [904cc70]
  - @memberjunction/connector-schema-merge@1.1.1

## 3.0.3

### Patch Changes

- f38b84a: Opens and deliveries now sync. Newsletter, Blast and Sequence Action were keyed on a tuple that included `url`, which only clicks have, so the engine refused every other event as keyless; they are now keyed on `<parent>_id + id` (rasa.io's event id is unique per event). The eight nested collections (Contact External Identifier, the newsletter and sequence lists and subscription types, Sequence Message, Subscription Type Mapping) now carry their parent's id, declared as a link, and Contact External Identifier pages through every contact. Fetch context is per call, so `syncConcurrency` above 1 is safe. Every object and field description is rewritten in rasa.io terms. Existing installs: see MIGRATION-v3.md §4b (on MJ 6.1.x the old key columns must be unmarked by hand), then run a full sync.

## 3.0.2

### Patch Changes

- 7cc5258: Newsletter, Blast and Sequence Action now declare `contact_id` (linked to Contact) and `email`. rasa.io added both to every insights action event on 2026-10-20 (they aren't in the published spec), so engagement can now be tied to the contact in MJ. Without the declaration the sync dropped them, since it keeps only declared fields. Existing installs pick up the two new columns on the next schema refresh; a full resync backfills older events, which the incremental watermark won't revisit.
- 8a3f2c3: The rasa.io credential gains an optional **API host** field (`baseUrl`). Leave it blank for rasa.io production (`https://api.rasa.io`); set it to reach another rasa.io environment, e.g. `https://api-dev.rasa.io` for client credentials generated in rasa.io's dev dashboard, which production rejects. A host typed without a scheme gets `https://`. The connector already honored this key; the credential form just never showed it, so a connection made in MJ Central could only target production.

## 3.0.1

### Patch Changes

- e9a915d: A 404 on one parent of a per-parent object (e.g. `/v2/insights/blast/{id}/actions`) no longer stops that object's sync. The parent is skipped with a `PARENT_NOT_FOUND` warning that carries rasa.io's message, and the sync moves on. Seen live: `/v2/messaging/blast` and `/v2/messaging/sequence` currently list some of each other's ids, and the insights feed answers "'144' is a sequence, not a blast" (rasa.io is fixing the list endpoints).

## 3.0.0

### Major Changes

- a00dce2: Move the rasa.io connector to the v2 API only, at rasa.io's direction.

  2.x signed in with v1 (`POST /v1/tokens`, username + password + API key) and sent that token to every object, but rasa.io's v2 endpoints don't accept v1 tokens, so every v2 object failed with HTTP 401. 3.0.0 signs in with a v2 **client ID and secret** that the customer generates in the rasa.io dashboard (`POST /v2/tokens`, OAuth2 client-credentials), and reuses the token until shortly before its `expires_in`.

  **Breaking:**

  - **Credential:** the `rasa.io API` credential now takes `clientId` and `clientSecret`. Existing v1 credentials stop working and must be re-entered.
  - **Objects:** the 18 v1 objects (Person and its children, Post, Lead Post, Content Pool Item, Community, Section, Insight Action / Topic / Topic Score, Analytics Activity / Article / Image / Topic) are retired. Their destination tables and data are left in place.
  - **Actions:** the 12 Actions on Person, Post, Insight Action and Insight Topic are disabled. New read-only Get / Search / List Actions are added for Contact and Newsletter Action.

  **New objects:** Newsletter / Blast / Sequence Action (rasa.io's bulk engagement feeds: opens, clicks, deliveries; incremental on `created`), Newsletter / Blast / Sequence Contact, Newsletter Deleted Contact, Segment and Integration Run. The first sync sends an early `created_since`, because rasa.io otherwise defaults it to the last seven days.

  Discovery no longer lists undeclared parent-scoped endpoints, which couldn't be synced. Upgrade steps are in `MIGRATION-v3.md`.

### Patch Changes

- 4441977: Fixes from the first live run against rasa.io's v2 API (api-dev.rasa.io, 2026-10-20).

  - **First sync of the action feeds no longer fails.** rasa.io rejects `created_since` more than 24 months ago (HTTP 400), so the fixed 2000-01-01 starting point is replaced by a rolling 725-day window (`Configuration.maxLookbackDays`). A stored watermark older than the window is moved up to it, with a `WATERMARK_CLAMPED` warning.
  - **Auth header:** the token is sent as `Authorization: Bearer` only. The live API rejects the `rasa-token` header that its spec documents.
  - **Deleted Contact** is fetched once per List: rasa.io requires `list_id`. Its key is now `list_id + id`.
  - **Removed:** `Subscription` (its list endpoint requires a `contact_id`, so a sync would make one request per contact; its create/update writes go with it) and `Integration Run` (internal to rasa.io, per the vendor). 23 objects.

## 2.0.2

### Patch Changes

- 06b2b4b: Allow MemberJunction 6.x as a peer. Every connector capped its `@memberjunction/*` peers at `<6.0.0`; the ceiling moves to `<7.0.0`, and `mj-app.json.mjVersionRange` moves with it so npm and `mjdev app register` agree. Floors are unchanged, so 5.x hosts are unaffected.

  Why the ceiling is the fix on a 6.x host: pnpm's `auto-install-peers` satisfies an unmet peer range by installing a **second** copy of `@memberjunction/core`, and two copies of core in one process is the failure that surfaces as thousands of unrelated-looking type errors. Business Central hit exactly this and was widened alone (#180, then #208 for the manifest); this brings the other 56 connectors, the two private platform packages, and the shared `connector-id-window-scan` package to the same range, so the duplicate cannot return transitively through a shared dependency either. The scaffolding scripts (`new-connector`, `scaffold-openapps`, `split-into-packages`) now mint `<7.0.0` too, so a new connector does not reintroduce the cap.

  Verified at compile time, not at runtime: all 61 packages in the repo (57 connectors, the two private platform packages, the two shared packages) type-check against `@memberjunction/*@6.1.0-edge.5` — the only 6.x published at the time; there is no stable 6.x yet — with every framework `.d.ts` resolved from the 6.x install and none from 5.x. That check is `npm run check:mj-compat` (`scripts/typecheck-against-mj.mjs`), added with this change so the claim can be re-run against any MJ version. It is API compatibility at the type level; the only runtime evidence on a 6.x host remains the Business Central team's edge deployment.

## 2.0.1

### Patch Changes

- 6ee916d: Relicense to the Business Source License 1.1.

  Metadata and documentation only: the `license` field moves to `BUSL-1.1` and the
  repo gains a LICENSE file. No runtime behaviour, API surface, or dependency
  changes. The bump exists so the new licence metadata reaches npm, since the
  registry shows the licence of the latest published version.

## 2.0.0

### Major Changes

- e862951: rasa.io connector rebuilt from the vendor's own API sources (`redo`): the catalog goes from 8 objects to **34 objects / 221 fields**, covering the person-child surface (Person Action / Topic / Send / Attribute), newsletter content (Newsletter, Section, Blast, Content Pool Item, Lead Post), the subscription + sequence surface, contacts, the deletion feeds, and the v2 messaging/list objects.

  **Breaking — rename only, no capability removed.** `Integration.Name` becomes `rasa` (was `Rasa.io`) and all 8 prior objects are renamed from the vendor's URL slugs to MJ's singular PascalCase convention, each mapping 1:1 (`persons`→`Person`, `posts`→`Post`, `insights-actions`→`Insight Action`, `insights-topics`→`Insight Topic`, `person-attributes`→`Person Attribute`, `analytics-activities`→`Analytics Activity`, `analytics-articles`→`Analytics Article`, `analytics-topics`→`Analytics Topic`). Because object names determine destination table names, existing deployments sync into new tables after upgrading; the old tables are left in place and are never dropped automatically. The Integration row **ID is preserved** and the seed migration UPDATEs it rather than inserting, so existing CompanyIntegration rows and stored credentials keep working. `ClassName` is unchanged — the package-name catalog convention from 1.1.0 stands. All 12 Actions were retargeted (`Config.IntegrationName`/`ObjectName`), which is required: they resolve by exact name at run time and would otherwise all fail. Full upgrade steps in `MIGRATION-v2.md`.

  **Three defects found by live end-to-end sync against a real rasa.io tenant and fixed here.** (1) Twelve prose fields — `Post.description` and its siblings across Analytics Article / Analytics Topic / List / Newsletter / Sequence / Blast / Sequence Message / Subscription / Lead Post / Newsletter List / Sequence List — were declared as bounded `string`, which sizes the destination column from the vendor's declared `maxLength` plus headroom (`Post.description` → `NVARCHAR(812)`). Real values run past 8,000 characters, so the framework's overflow policy skipped **6,578 records** rather than truncate. They are now `text` → `NVARCHAR(MAX)` / `TEXT`, and the same sync lands **0** skips. (2) 25 of the 34 objects carried a null `DefaultPageSize` and `PaginationType`; both columns are `NOT NULL`, so the seed **could not be installed on a fresh MemberJunction database at all**. They are filled with the values the connector already applies at run time (`Offset` / 50, its own fallback constant), so behavior is unchanged. (3) The v2 seed creates the 34 new objects but the generator emits only what changed, leaving the 8 renamed v1 objects `Active` and double-syncing the same vendor endpoints into the old slug-named tables — a new `V202608011400__rasa-io__Deprecate_v1_Objects` migration deletes those 8 rows by hardcoded ID (a no-op where v1 was never installed; destination tables are never dropped).

  Connector fixes in this release: discovery no longer over-emits phantom objects (it promoted every `$ref`'d child property to a top-level object, and deduped by name only so a plural-vs-singular pair emitted twice — both produced permanently-empty tables); and a write-only object with no read path is now explicitly refused instead of falling back to `GET {baseURL}/`, whose danger was not the 404 but a vendor root answering 200 with a banner document that the envelope reader would treat as that object's records.

## 1.1.1

### Patch Changes

- 533fb7a: ClassName follows the catalog convention (== npm package name) so instance discovery matches; legacy 'RasaConnector' key stays registered and a delta migration fixes existing tenants' Integration rows.

## 1.1.0

### Minor Changes

- 37cfe35: Sample-union discovery for describe-endpoint connectors: each connector wires MJ's existing `DiscoverFieldsViaFetch` sampler into its declared catalog inside `IntrospectSchema`, unioned per object via the shared pure helper `mergeDeclaredWithSampledFields` — real widths and MJ-discovered custom columns land before the first sync (no `nvarchar(255)` overflow / `STRING_OVERFLOW_SKIPPED`). Connectors with no `IntrospectSchema` of their own get the standard `super.IntrospectSchema → sample → merge → return` override; connectors that already own an `IntrospectSchema` (HubSpot, Salesforce, Nimble AMS, YourMembership) are WRAPPED — their existing logic/caching is preserved and the union runs on the built result before return (Fonteva inherits it via Salesforce's `super`).

  The width rule is NEVER-SHRINK: `MaxLength = max(declared, measured)`. It only ever widens, so connectors that already carry real declared widths from their describe API (Salesforce/Fonteva) are never truncated below the real width, while connectors whose declared catalog has no width still adopt MJ's measured value. Connectors add no discovery/merge/sync logic of their own; MJ owns measurement, type/PK inference, persistence and reconcile. `DiscoverFields` is unchanged (no recursion). Schema-less / already-streaming connectors (PropFuel, FileFeed, RelationalDB, MJtoMJ, ORCID) are unaffected.
