# Higher Logic Thrive Marketing Professional (Informz) — Supported & Proven

> **Evidence tier:** 🧪 Mock-only (proven vs mock server, never live)  ·  **Last verified:** 2026-10-23  ·  **Proof DB(s):** SQL Server (`MJ_SS_E2E_INFORMZ`, disposable)

> **Known issues:** 46 of the 67 active objects use primary keys inferred from their row grain rather than named by the vendor, and none has been checked against live data. The `StartRow` paging base is undocumented and unproven live.

> 🧪 **Mock-only:** every claim below was observed against a fixture-driven mock vendor server driving
> the real MJ engine into a real SQL Server database. **No authenticated call to Higher Logic has been
> made and no vendor rows have been read.** The reason is an access gap, not a defect: Higher Logic
> accepts API calls only from IP addresses registered for the brand, and no registration existed for
> this build. The honest ceiling is `format-verified-no-creds`.

## What this connector supports

**70 objects** declared across **994 fields** (source: `metadata/integration/.informz.integration.json`). 0 declare a write path; 70 are read-only (pull). 6 support incremental sync.

**67 are Active** and **3 are `Status='Disabled'`** because nothing identifies one of their rows (see
[Primary keys](#primary-keys)). Every active object declares a primary key.

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
- **Incremental sync** is a date condition on 6 objects (listed in the table below). There is no change
  feed and no webhook.
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
- **None of the 46 inferred keys has been checked against real data.** A key that is not unique silently
  merges rows, so check for merged rows on the first live sync.

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
| MailingActivitySendAFriend | Active | `from_email` + `mailing_instance_id` + `friend_email` (inferred) | — |
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

- **Hybrid end-to-end sync, 2026-10-23** (real MJ engine into real SQL Server, vendor mocked): all 70
  objects applied, and the forward run landed 103 of 103 rows, with every object landing rows. Creates,
  updates and a hard delete on Subscriber at the mock vendor were picked up on the next sync (8 of 8
  changes). An unchanged second sync did no work.
- **The end-to-end run predates the primary keys.** It ran with 49 objects keyless (content-hash
  identity). The keys were added afterwards to meet this repo's primary-key rule, so the end-to-end run
  does not exercise them; the unit tests do.
- **Unit tests:** 33 of 33 pass, with a mocked transport and the real metadata.
- **Unauthenticated live probing** of Higher Logic (no credential sent): the live WSDL and schema files
  match the snapshot the catalog was declared against, and every regional host answered. A real grid
  name and a made-up one return the same fault without a credential, so grid names cannot be checked
  unauthenticated.

### Push (write / bidirectional)

- **Status: Not supported.** The connector is pull-only by design. The AAPI documents 9 write operations
  (`<ActionRequest>` documents such as `Subscribe` and `CreateMailing`). They are recorded in
  `Configuration.OutOfScopeObjectFamilies` as an operator decision, and the connector refuses any write.

## Verification performed

| Gate | Result |
|---|---|
| Unit tests (this package) | **33 passed** |
| PR checks (`.github/workflows/pr.yml`, all 18 steps) | pass |
| Verification ladder T0 and T2–T7 | pass |
| Verification ladder T1 (primary-key coverage) | failed at build time with 49 of 70 objects keyless; resolved afterwards by the keys above, not re-run |
| Deploy dry run on a fresh database | real migrate and push: 70 objects and 994 fields, matching the metadata |
| Hybrid E2E (mock vendor, real MJ engine into SQL Server) | 70 of 70 objects landed rows; 103 of 103 rows |
| Reality probe (unauthenticated) | 91 claims: 17 confirmed, 74 unverifiable without a credential, 0 wrong |
| Live, authenticated | **not run**: brand-IP registration pending |

## Residual gap (honest)

- **No live call.** Nothing has been read from a real brand. Higher Logic must first register the calling
  machine's IP for the brand, and the registration procedure is not public.
- **46 inferred primary keys are unverified** against real data, with two known merge risks (see Primary
  keys above).
- **The paging base is unproven.** The docs never say whether `StartRow` is a 0-based offset or a 1-based
  row number; the connector follows the docs' own example (0 for the first page, then 1-based). Paging is
  proven only by unit tests, because the end-to-end run paged 0 objects. A wrong base would skip or
  repeat one row at every page boundary.
- **Brand-specific element capture is not proven end to end.** `ExtraReturnFields` is unit-tested only;
  the end-to-end run never exercised the custom-column path.
- **Unresolved in the vendor docs:** `<User>` versus `<Username>` as the credential element, and which
  fault an unregistered IP produces.
- **Rate limits** are undocumented and untested under load.
- **Out of scope by design:** the AAPI write surface, Higher Logic Push API v2 (inbound only), Thrive
  Marketing Enterprise and Thrive Community, and AAPI payload encryption and compression.

---

_Catalog counts and the object table are derived from `metadata/integration/.informz.integration.json`.
Build evidence is from the build-connector run of 2026-10-22 to 2026-10-23
(`connector-informz-1792718947538-3736163f`). Supersede this file when a live, authenticated sync is run._
