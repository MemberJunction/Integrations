# Higher Logic Thrive Marketing Professional (Informz) — Supported & Proven

> **Evidence tier:** 🥇 Production-live (real vendor API, real production dataset, read-only)  ·  **Last verified:** 2026-11-11  ·  **Proof DB(s):** MJ_SS_E2E_INFORMZ

> **Known issues:** 45 of the 66 active objects use primary keys inferred from their row grain rather than named by the vendor (with merge caveats on simultaneous multi-interest opt-outs and multi-SKU web tracking). PostgreSQL deployments require the MJ engine's ISO-8601 `Date` composite-PK serialization and `.NET` sub-millisecond trailing-zero normalization fix.

## What this connector supports

**69 objects** declared across **985 fields** (source: `metadata/integration/.informz.integration.json`). 1 declares a write path (`Subscriber`: create and update, no delete); 68 are read-only (pull). 6 support incremental sync.

**66 are Active** and **3 are `Status='Disabled'`** because nothing identifies one of their rows (see
[Primary keys](#primary-keys)). Every active object declares a primary key. `MailingActivitySendAFriend` and the
`send_a_friend_count` field of `MailingActivity` / `MailingActivityDemo` were retired by the vendor (the help-center
articles dropped them; Higher Logic stopped offering Send a Friend in December 2019) and are no longer declared;
migration `V202611170749` deprecates the seeded rows on existing installs rather than deleting them.

### How this vendor actually works

- **One SOAP operation for everything.** The Advanced API (AAPI) exposes a single operation,
  `PostInformzMessage`. Each read is a `<GridRequest>` XML document, XML-escaped inside the operation's
  `x` argument. The object is chosen by `<Grid type="…">` inside the document, never by the URL.
- **Credentials travel inside the document.** `<Password>`, `<Brand id="…">` and `<User>` are elements of
  every request. There is no Authorization header and no token exchange.
- **Brand-IP registration.** Higher Logic validates the brand against the IP addresses registered for it,
  so correct credentials still fail from an unregistered machine. The registration procedure is not
  public; it goes through Higher Logic support.
- **Three regional hosts:** `partner.informz.net` (`us`), `partner.informz.ca` (`ca`) and
  `partnertest.informz.net` (`test`). The connection's `Region` setting picks one.
- **Offset paging** with `StartRow` / `NumberOfRows`, at most 1,000 rows per request. The 59 active grids
  with a `sortField` in their Configuration are read in a stable order.
- **Incremental sync and sliding date-window pacing.** Six grids declare native date-filter incremental sync (listed below). To avoid deep-offset SQL timeouts on large historical grids, the connector supports `dateWindowing` (`[windowFrom, windowTo]` date slices where `StartRow` resets per window advance via `v1|...` composite cursors) and `migrationPacing` (`maxWindowsPerRun`, `checkpointPerWindow`, `maxConcurrency`, token-bucket throttling) in `CompanyIntegration.Configuration`. There is no change feed and no webhook.
- **Brand-defined demographics and interests** arrive as rows (name and value) in the demographic and
  interest grids, not as extra columns. Brand-specific elements can be requested per grid with the
  connection's `ExtraReturnFields` setting.
- **Errors** are SOAP faults delivered as HTTP 500, and the vendor's list of fault codes is explicitly
  incomplete. No numeric rate limit is documented; the connector honours `Retry-After` on 429 and 503.

### Connecting

- **Credential type `Informz AAPI`:** `Username`, `Password` and `BrandID` are required; `BrandName` is
  optional. `Region` is a connection setting and defaults to `us`.
- **Test Connection** sends one `NumberOfRows=1` GridRequest to the first Active grid by Sequence. A
  credential or IP refusal surfaces as a configuration error, which the engine does not retry.

## Primary keys

- **21 objects** use a key that the vendor docs name as the record's ID.
- **46 objects** use a key **inferred from the grid's row grain**: its own IDs, dimension fields and event
  dates, never `user_id` (the tenant's optional remote ID). The vendor names no row ID for these
  activity, history, score and summary grids. Every part of a composite key must always be populated,
  because the engine cannot store a row with an empty key part. `Configuration.PrimaryKeyBasis` lists
  them with the reasoning.
- **Known merge risks.** MailingActivityOptout omits `Interest_ID`, which whole-list opt-outs likely
  lack, so opt-outs from several interests at the same instant merge into one row. SubscriberWebTracking
  merges several SKUs bought on one page at one timestamp.
- **3 objects are Disabled** because nothing identifies a row: EmailBlockStatus (the brand's current email
  block), and ScoringSummary and ScoringSummaryDemo (scoring groups identified only by a description).
- **Live data caveat on inferred composite keys.** While live production pulls have now populated most active grids, simultaneous multi-interest opt-outs (`MailingActivityOptout`) and multi-SKU web events (`SubscriberWebTracking`) remain structural merge risks, and grids not used by the verified brand remain unexercised against real payloads.

### Object table

| Object | Status | Primary key | Incremental on |
|---|---|---|---|
| AccountingCode | Active | `accounting_code_id` | — |
| CampaignStep | Active | `step_id` | — |
| CampaignSummary | Active | `campaign_id` (inferred) | — |
| CampaignSummaryDemo | Active | `campaign_id` (inferred) | — |
| EmailBlockStatus | **Disabled** | — (no usable key) | — |
| Event | Active | `event_id` | — |
| GetCampaignDetails | Active | `campaign_id` + `subscriber_id` + `campaign_entry_date` (inferred) | — |
| GetCampaigns | Active | `campaign_id` | — |
| GetCampaignSubscriber | Active | `campaign_id` + `subscriber_id` (inferred) | — |
| GetCampaignSubscriberHistory | Active | `campaign_id` + `step_id` + `subscriber_id` + `step_start_date` (inferred) | — |
| GetSubscriberInterestChanges | Active | `subscriber_id` + `interest_id` + `action` + `action_date` (inferred) | — |
| InterestTargetGroup | Active | `target_group_id` | — |
| LandingPagesSummary | Active | `month_id` + `year_id` + `url` (inferred) | — |
| LandingPagesSummaryDemo | Active | `month_id` + `year_id` + `url` (inferred) | — |
| Mailing | Active | `mailing_id` | — |
| MailingActivity | Active | `mailing_instance_ID` (inferred) | — |
| MailingActivityBounces | Active | `email` + `mailing_instance_id` (inferred) | — |
| MailingActivityChallenge | Active | `challenge_id` | — |
| MailingActivityClicks | Active | `Email` + `Id` + `link_date` + `mailing_instance_id` (inferred) | `link_date` |
| MailingActivityDemo | Active | `mailing_instance_ID` (inferred) | — |
| MailingActivityDomains | Active | `Domain` + `mailing_instance_id` (inferred) | — |
| MailingActivityFirstOpen | Active | `email` + `mailing_instance_id` (inferred) | — |
| MailingActivityFirstOpenByHour | Active | `Day` + `Hour` + `mailing_Instance_id` + `Month` + `Year` (inferred) | — |
| MailingActivityForwardCount | Active | `mailing_instance_id` + `subscriber_id` (inferred) | — |
| MailingActivityOpens | Active | `email` + `mailing_instance_id` + `open_date` (inferred) | `open_date` |
| MailingActivityOpensByHour | Active | `Day` + `Hour` + `mailing_Instance_id` + `Month` + `Year` (inferred) | — |
| MailingActivityOptout | Active | `Email` + `mailing_instance_id` + `optout_date` (inferred) | `optout_date` |
| MailingActivitySubscriberActions | Active | `Email` + `mailing_instance_id` (inferred) | — |
| MailingActivitySubscriberArchive | Active | `Email` + `mailing_instance_id` (inferred) | — |
| MailingActivityTotals | Active | `activity_date` + `mailing_folder_id` (inferred) | — |
| MailingFolder | Active | `folder_id` | — |
| MailingInstance | Active | `mailing_instance_id` | — |
| MailingTemplate | Active | `template_ID` | — |
| MessageCategorySubscribers | Active | `message_category_id` + `subscriber_id` | — |
| ScheduledMailings | Active | `mailing_id` | — |
| ScoringSummary | **Disabled** | — (no usable key) | — |
| ScoringSummaryDemo | **Disabled** | — (no usable key) | — |
| Story | Active | `story_id` | — |
| Subscriber | Active | `subscriber_id` | `modified_date` |
| SubscriberDemographics | Active | `subscriber_demographics_id` | — |
| SubscriberEngagementScore | Active | `subscriber_id` + `type_id` (inferred) | — |
| SubscriberExtendedDemographic | Active | `subscriber_id` + `category_id` + `demographic_id` + `category_extended_field_name` (inferred) | — |
| SubscriberFormUsage | Active | `subscriber_id` + `form_id` + `activity_date` (inferred) | `activity_date` |
| SubscriberInterests | Active | `subscriber_to_interest_id` (inferred) | — |
| SubscriberInterestsDeleted | Active | `subscriber_to_interest_id` (inferred) | `deleted_from_interest_date` |
| SubscriberLeadScore | Active | `subscriber_id` + `type_id` (inferred) | — |
| SubscriberMailingHistory | Active | `Mailing_instance_id` + `Subscriber_ID` (inferred) | — |
| SubscriberMailingHistoryAll | Active | `Mailing_instance_id` + `Subscriber_ID` (inferred) | — |
| SubscriberMessageCategories | Active | `subscriber_id` + `message_category_id` | — |
| SubscriberPersona | Active | `subscriber_id` + `type_id` (inferred) | — |
| SubscriberPersonalInformation | Active | `Subscriber_personal_information_ID` | — |
| SubscriberPrimaryEmailClient | Active | `subscriber_id` + `type_id` (inferred) | — |
| SubscriberSummaryHistory | Active | `month_id` + `year_id` (inferred) | — |
| SubscriberSummaryHistoryDemo | Active | `month_id` + `year_id` (inferred) | — |
| SubscriberWebTracking | Active | `subscriber_id` + `url` + `create_date` + `type` (inferred) | — |
| SubscriberWebTrackingInteractions | Active | `subscriber_id` + `url` + `create_date` + `interaction_category` + `interaction_action` (inferred) | — |
| SubscriberWebTrackingPages | Active | `subscriber_id` + `url` + `create_date` (inferred) | — |
| SuppressedSubscribers | Active | `subscriber_match_id` | — |
| SuppressedSubscribersDemo | Active | `subscriber_match_id` | — |
| TargetGroupCounts | Active | `id` | — |
| UploadHistory | Active | `upload_id` | — |
| WebTrackingInteractionsSummary | Active | `month` + `year` + `category` + `action` (inferred) | — |
| WebTrackingInteractionsSummaryDemo | Active | `month` + `year` + `category` + `action` (inferred) | — |
| WebTrackingPageSummary | Active | `month` + `year` + `type` + `name` (inferred) | — |
| WebTrackingPageSummaryDemo | Active | `month` + `year` + `type` + `name` (inferred) | — |
| WebTrackingPurchaseSummary | Active | `month` + `year` + `sku` (inferred) | — |
| WebTrackingPurchaseSummaryDemo | Active | `month` + `year` + `sku` (inferred) | — |
| WebTrackingSummary | Active | `month` + `year` (inferred) | — |
| WebTrackingSummaryDemo | Active | `month` + `year` (inferred) | — |

## What is proven

### Pull (read)

- **Live production sync (PostgreSQL client tenant, 2026-11-11):** Executed authenticated, brand-IP-registered read-only pulls against Higher Logic into a PostgreSQL environment. All 67 active tables materialized and live data populated core mailing, mailing-instance, campaign, story, interest, target-group, mailing activity (opens, first-opens, clicks, bounces, forwards, archive, domains, subscriber actions), hourly rollups, subscriber demographic/score/persona/client, and web-tracking objects.
- **Live PostgreSQL integration findings:**
  - Composite `Date` primary keys (`MailingActivityClicks`, `MailingActivityOpens`, `SubscriberWebTracking`, etc.) require ISO-8601 key serialization (`toISOString()`) and `.NET` 7-digit fractional-second trailing-zero normalization (`.5700000Z` -> `.570Z`) in the MJ integration engine so PostgreSQL `timestamptz` lookups and `MatchEngine` record maps align 1:1.
  - `MailingInstance.mailing_instance_id` soft-PK metadata should be verified active on existing tenant entity fields when wiring downstream relationships.
- **Hybrid end-to-end sync, 2026-10-23 (`MJ_SS_E2E_INFORMZ`):** Real MJ engine into SQL Server against a mock vendor; all 70 objects applied and the forward run landed 103 of 103 mock rows, capturing creates, updates, hard deletes on `Subscriber`, and an idle second sync. This mock run predated the primary-key additions (49 objects ran keyless at that time).
- **Unit tests:** 55 of 55 pass in `InformzConnector.test.ts` with a mocked transport and the real metadata, including sliding date-window cursors, metered migration pacing and the ActionRequest Subscribe write path (per-key pre-write identity read-back, 409 on ambiguous or partial-key identity collisions, refusal of an identity change or XML 1.0 control characters, demographic `<Field>` elements, fault classification, the interest-action guard).
- **Hybrid end-to-end push, 2026-11-17 (MJ worktree, mock vendor, real MJ engine into SQL Server):** engine push loop 12 of 12 cells and 7 of 7 write round trips (create → read-back link, update, idempotent re-push, delete skipped as unsupported). Needs the MJ integration-engine incremental-push fixes in MemberJunction/MJ PR #6699; without them the engine's push loop selects no Record Changes for any connector.
- **Unauthenticated live probing:** The live WSDL and schema files match the snapshot the catalog was declared against, and every regional host answered.

### Push (write / bidirectional)

- **Status: Supported for `Subscriber` create and update** (mock-proven; no live write has been sent yet). Every
  other object answers a write with 403 and sends nothing. Push is opt-in per entity map; `DefaultSyncDirection`
  stays `Pull`.
- **Mechanics.** One `<ActionRequest>` `Subscribe` document per record, inside the same `PostInformzMessage`
  envelope, credential block and escaping as a `GridRequest`. The only interest action ever sent is
  `AddOrUpdateSubscribers`; any other value, from metadata or a connection setting, is refused before a request
  is made (a list-replacing action would empty the interest for everyone not in the document).
- **Identity.** The ActionResponse carries no subscriber id, so identity is read back from the `subscriber` grid
  (2 rows max). A create queries each identity key on its own (`user_id` EQ ID, then `email` EQ Email) BEFORE
  posting: if either is ambiguous or matches an existing row with a different non-blank partner key, it returns 409
  with nothing sent; if one row already matches both keys and no interests or demographic `<Field>`s are present, it
  links without a write; otherwise (brand-new row, blank stored `user_id` being populated, or an existing match
  carrying interests or `<Field>`s) it posts `Subscribe` and reads back (`user_id` EQ ID AND `email` EQ Email) to
  confirm the single `subscriber_id`. An update re-reads the stored row, refuses a change to `user_id` or `email`
  (409), posts, and confirms the same `subscriber_id` came back. Success is never reported without an ExternalID.
- **Connection settings (tenant data, never metadata).** `SubscribeInterestNames` (interests every Subscribe
  joins) and `SubscribeFieldDefinitions` (`{ Name, DataType?, DefaultValue? }` demographic `<Field>` elements).
  A malformed setting never breaks a read; a write refuses while one exists.
- **Delete: not supported.** The vendor's nearest operation, `Unsubscribe`, is a global consent status change,
  not a record delete, so an MJ row delete must never trigger it. `DeleteRecord` returns 405 and sends nothing.
- **Out of scope** (each with its reason in `Configuration.WriteScope.out`): `BulkUpload`, `CreateMailing`,
  `CreateMessage`, `Optout`, `ScheduleMailing`, `SetMailingOnHold`, `Unsubscribe`,
  `UpdateContactMessageCategoryPreference`.

## Verification performed

| Gate | Result |
|---|---|
| Unit tests (this package) | **55 passed** |
| Hybrid E2E push (mock vendor, real MJ engine, 2026-11-17) | 12 of 12 push-loop cells, 7 of 7 write round trips (needs MJ PR #6699) |
| PR checks (`.github/workflows/pr.yml`, all 18 steps) | pass |
| Verification ladder T0 and T2–T7 | pass |
| Verification ladder T1 (primary-key coverage) | failed at build time with 49 of 70 objects keyless; resolved afterwards by the keys above, not re-run |
| Deploy dry run on a fresh database | real migrate and push: 70 objects and 994 fields, matching the metadata |
| Hybrid E2E (mock vendor, real MJ engine into SQL Server) | 70 of 70 objects landed rows; 103 of 103 rows |
| Reality probe (unauthenticated) | 91 claims: 17 confirmed, 74 unverifiable without a credential, 0 wrong |
| Live, authenticated (PostgreSQL client tenant) | **pass (read-only)**: brand-IP-registered live sync across active catalog |

## Residual gap (honest)

- **Unexercised / brand-optional grids:** Subsets of the 67 active grids yielded no data on the verified tenant because the brand does not use those Informz features or because historical date windows are still pacing forward (`Subscriber` and brand-optional summary/demo/suppression/upload grids).
- **Engine dependency for composite `Date` PKs on PostgreSQL:** Tenants syncing composite-`Date`-PK Informz grids on PostgreSQL require the MJ engine ISO-8601 `Date` serialization and `.NET` sub-millisecond normalization fix (`toISOString()` + trailing-zero trim) to avoid `timestamptz` lookup errors.
- **Inferred primary-key merge caveats:** Two documented row-grain merge risks remain (`MailingActivityOptout` without `Interest_ID`, `SubscriberWebTracking` across multiple SKUs at one timestamp), and unexercised inferred keys have not yet seen real payloads.
- **The `StartRow` paging base edge cases:** Live data confirms multi-page progression in production, though boundary-row skip/overlap behavior at exact 1,000-row cutoffs remains sensitive to vendor `StartRow` semantics (the connector sends `0` then 1-based offsets per vendor examples).
- **Brand-specific element capture (`ExtraReturnFields`)** is unit-tested only and was not exercised in the mock E2E run.
- **Rate limits** remain undocumented by Higher Logic; `migrationPacing` enforces conservative client-side concurrency and token-bucket limits.
- **Write path is mock-proven only.** No live `Subscribe` has been sent; the vendor's match key is undocumented, which is why the connector reads identity back before and after every write. A single live create/update against a test subscriber is the remaining gap.
- **Out of scope by design:** every AAPI ActionRequest except `Subscribe`, Higher Logic Push API v2 (inbound only), Thrive Marketing Enterprise and Thrive Community, and AAPI payload encryption and compression.

---

_Catalog counts and the object table are derived from `metadata/integration/.informz.integration.json`.
Build evidence is from the build-connector run of 2026-10-22 to 2026-10-23
(`connector-informz-1792718947538-3736163f`), supplemented by live brand-IP-registered PostgreSQL production pulls verified through 2026-11-11._
