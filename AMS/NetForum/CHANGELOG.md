# @memberjunction/connector-netforum-enterprise

## 1.6.0

### Minor Changes

- a9f3474: Ask the endpoint for an object's columns before sampling its data.

  `IntrospectSchema` went straight from the declared catalog to record sampling, never calling `DiscoverFields`. The contract's order is DiscoverObjects → DiscoverFields → sampling, and the middle step was missing.

  It mattered once 1.5.0 started enumerating the real catalog. On a live netFORUM, discovery found 888 objects; the 862 with no declared metadata could only get columns if streaming their records happened to work, and they landed with **zero** columns — so no primary key, no table, and an RSU that emitted a migration with no DDL. `GetQueryDefinition` could describe every one of them the whole time: measured live, `Abstract Author` 137 columns, `AccountingPeriod` 58, `Individual` 1161, no faults. It also returns data type, nullability and `mdc_width_max`, so widths no longer depend on sampling reaching the object.

  `IntrospectSchema` now merges the endpoint's column list into each object before sampling. Sampling is unchanged and still unconditional — it remains the only source for primary-key statistics and for columns that exist in data but in no schema. Any object whose endpoint call fails or returns nothing keeps exactly the fields it had, so a bad response can never empty a working catalog.

  Cost matters here too: one schema call per object is trivial next to paging rows, so building the column list no longer competes with the run deadline. A discovery observed taking 20 minutes was still in its field-discovery stage when an unrelated restart killed it.

  Also adds a `DeclaredSchema` test seam mirroring `DeclaredObjects`, so `IntrospectSchema`'s step ordering is reachable from unit tests at all — without it the missing call went unnoticed through 38 passing tests.

  Known limits, stated rather than implied:

  - The response carries no key indicator, so enumerated-only objects gain columns but still no primary key, and the schema builder skips objects without one. netFORUM's `<prefix>_key` convention plus `mdc_table_name` makes this derivable; that is a separate change.
  - When sampling fails, `DiscoverFields` now runs twice for that object — once here, once via the sampler's own fallback. Harmless, but redundant.
  - The new test does not mutation-prove the fix and says so in place: deleting the call still passes, because the sampler's fallback reaches the same endpoint. A real guard needs a sampler that succeeds with zero rows.

## 1.5.0

### Minor Changes

- d0acf8c: **Discovery resolves the client's object set from the source, per the framework contract — it no longer unions a baked-in list.** 1.4.0 shipped this behind an opt-in flag that defaulted OFF, so discovery still reported the declared 34 out of the box; and when enabled it _added_ to the declared catalog rather than reconciling with it. Both were wrong against `everything.txt` §2.

  **Enumeration is unconditional.** `GetFacadeObjectList` takes an empty request and returns every facade the credential may see (878 on a live tenant against a declared catalog of 34). A connector whose source can list its objects must ask the source, every time. There is no flag and no cap: the previous justification — that each listed object would cost a `GetQueryDefinition` round trip — was simply false. `BaseRESTIntegrationConnector.IntrospectSchema` is cache-driven (`GetActiveIntegrationObjects` + `GetCachedFields`) and issues no network calls, so enumeration costs exactly one request.

  **The object set is now a three-way reconciliation, not a union.** Per the contract: _"if you have metadata for Objects A,B,C, and the external system has C,D,E ... you basically exclude A,B for this client as potential entity maps"_.

  - **In both** — kept, and overlaid attribute-by-attribute with **external-system priority**, the declaration as fallback. `GetFacadeObjectList` states a description and is silent on APIPath, watermark, primary key and write capability, so the description comes from the source and the rest from the declaration. The overlay is gated on the source's actual statement (`obj_description`), never on a synthesised label — otherwise a silent source overwrites a curated label with the bare object name.
  - **Source only** — added. These are the client's custom and undeclared objects.
  - **Declared only** — excluded. A declared object the source does not list is not this tenant's object.

  That third rule fixes an observed failure. Ten of the declared 34 are not listed for the probe credential, and they are exactly the ten whose `GetQuery` returns 500, whose primary key was never determinable, and which `entity.skipped-no-pk` drops at materialisation. Carrying them forward produced catalog rows that could never be fetched. 1.3.5 recorded this for one of them ("MembershipBilling is not readable by the probe credential"); it is ten.

  **Exclusion applies only when the source actually answered.** A failed, timed-out or ungranted `GetFacadeObjectList` returns the declared baseline untouched — absence of an answer is never absence of an object. Mutation-proved: excluding on a failed call fails two tests.

  `DiscoveryIsAuthoritative` remains **false**. The enumeration is permission-scoped — 878 is what this credential may see, a floor rather than a ceiling — so absence still must not deactivate. Revisiting that is a separate, deliberate decision.

## 1.4.0

### Minor Changes

- 56f99cc: **`DiscoverObjects` can now enumerate the installation instead of only replaying the declared catalog.** Through 1.3.6 the override existed but did nothing except `return super.DiscoverObjects(...)` — the persisted `IntegrationObject` rows — so discovery could never report more objects than were baked into the catalog, whatever the tenant actually exposes. Its own doc comment already claimed "a live credential only ADDS customer-installed query objects (the Discovered extension)"; no code did that. xWeb advertises `GetFacadeObjectList` with an EMPTY request, and on a live tenant it answers 878 facades against a declared catalog of 34. The connector now calls it and unions the result onto the declared baseline.

  **The declared catalog always wins on a name collision.** Declared rows are curated — `APIPath`, watermark field, primary key, pagination, write capability — and the enumeration carries a name, a key and a description. Replacing a declared object with its enumerated stub would silently downgrade a working object to an unsyncable name, so enumerated entries are added only where the declared catalog has no object of that name. Enumerated-only objects report `SupportsIncrementalSync: false` and `SupportsWrite: false`: a bare name proves neither.

  **Enumeration is opt-in (`discoverAllObjects`, default false) and bounded (`discoverAllObjectsMax`, default 250).** `IntrospectSchema` builds from `DiscoverObjects` PLUS `DiscoverFields`, so every object returned costs a `GetQueryDefinition` round trip. Live, this connector takes ~14 minutes for 34 objects; 878 would run far past the engine's 45-minute run deadline and the run would be failed mid-Introspect with nothing persisted — turning a working discovery into one that never finishes. Default-off keeps existing behaviour byte-identical; a failure of any kind (method not granted, network, parse) falls back to the declared baseline.

  **SOAP faults now carry netFORUM's own reason instead of a bare status code.** `Authenticate`, `GetQuery`, create and update reported only `HTTP 500`, discarding the `<faultstring>` the server sent. Live evidence: a discovery run reported `NetForum GetQuery(Audience) failed: HTTP 500` for ten objects, while netFORUM was saying `Account is not authorized to perform Select on Audience object.` — a one-line answer naming both the cause and who can fix it. The status code alone sent the investigation through transport faults, catalog-authoring errors and per-method security before the real cause surfaced.

  Live evidence (2026-09-15, probe tenant): `GetFacadeObjectList` → HTTP 200, 155,737 bytes, 878 `<ObjectObject>` rows of `<obj_name>`/`<obj_key>`/`<obj_description>`. Of the 34 declared objects, 24 are visible to the probe credential and 10 are not — and those 10 are exactly the ones whose `GetQuery` returned 500. `GetFacadeXMLSchema(Audience)` returns the authorization faultstring above, which also shows `GetFacadeObjectList` is permission-scoped: the 878 is what this account may see, a floor rather than a ceiling. 1.3.5 already recorded this for one object ("MembershipBilling is not readable by the probe credential"); it is ten.

  No catalog rows are added, removed or re-minted, and no migration ships with this change. The ten unreadable objects are a NetForum admin grant, not a code defect — the connector's job here is to say so.

## 1.3.6

### Patch Changes

- 7ce078e: **The session token is read from the Authenticate RESPONSE HEADER, not from `AuthenticateResult`.** Through 1.3.4, `Authenticate()` took the body's `<AuthenticateResult>` as the token. On a real tenant that element holds the namespace URI `http://www.avectra.com/2005/`; the token is in `<soap:Header><AuthorizationToken><Token>`, which the WSDL declares as an output header of the Authenticate operation. The connector therefore sent the URI as its token, and netFORUM answers an unrecognised token with HTTP 500 + faultstring `Locked` on every call — with nothing locked. Vendor-confirmed with a captured response. **1.3.4's changelog attributed "Locked" to a MethodsFaultLimitPerDay lock; that diagnosis was wrong.** The `*` column list was a real, separate fault (fixed in 1.3.4); "Locked" was this. There is deliberately no fallback to the body — a wrong fallback is exactly this bug — and a response with no header token now fails loudly instead of sending a guess.

  **Objects whose default column list cannot carry their watermark now declare one.** With the empty `szColumnList`, GetQuery returns the tenant's _default_ list columns, and on a live tenant not one of the 23 incremental objects' default lists includes its `<prefix>_change_date` — so incremental sync could never advance (1.3.4's `WATERMARK_COLUMN_ABSENT` warning would have fired on every one). Three objects (IndividualPhone, IndividualFax, InvoiceDetailCustomer) fault even on the empty list, because their default list is itself `*`. Naming the columns works — including the watermark, an incremental `>=` predicate on it, and ORDER BY it. So an IntegrationObject may declare `Configuration.columnList`; the connector sends it and completes it with the primary key, ordering key and watermark it reads. Twelve objects declare a list proven live — their default columns plus the watermark, minus display columns such as `cst_sort_name_dn` / `cst_eml_address_dn` / `adr_city_state_code` that the door refuses by name: Individual, IndividualEmail, IndividualAddress, IndividualPhone, IndividualFax, Organization, Committee, Invoice, InvoiceDetail, InvoiceDetailCustomer, CentralizedOrderEntry, EventsRegistrant. Each carries a `columnListNote` with its provenance. The ten incremental objects that were empty on the probe tenant keep the empty list and the warning (their default columns are unknowable there); MembershipBilling is not readable by the probe credential ("not authorized to perform Select on Membership object").

  Live evidence, the first for this connector: `Individual @TOP 5`, empty list, `ORDER BY ind_cst_key` → 5 rows × 9 columns with `ind_cst_key`; with the declared list → 10 columns including `ind_change_date`; `ind_change_date >= '2000-01-01'` accepted.

  Ships as delta migration `V202609151700` (+ Postgres twin): corrected auth prose on the Integration and CredentialType rows (they said the token was the `AuthenticateResult` string), `columnList` on the twelve objects, `DeclaredAgainst.catalogLastEditedAt` → 2026-09-15. No rows added or removed, no IDs re-minted.

## 1.3.5

### Patch Changes

- 06b2b4b: Allow MemberJunction 6.x as a peer. Every connector capped its `@memberjunction/*` peers at `<6.0.0`; the ceiling moves to `<7.0.0`, and `mj-app.json.mjVersionRange` moves with it so npm and `mjdev app register` agree. Floors are unchanged, so 5.x hosts are unaffected.

  Why the ceiling is the fix on a 6.x host: pnpm's `auto-install-peers` satisfies an unmet peer range by installing a **second** copy of `@memberjunction/core`, and two copies of core in one process is the failure that surfaces as thousands of unrelated-looking type errors. Business Central hit exactly this and was widened alone (#180, then #208 for the manifest); this brings the other 56 connectors, the two private platform packages, and the shared `connector-id-window-scan` package to the same range, so the duplicate cannot return transitively through a shared dependency either. The scaffolding scripts (`new-connector`, `scaffold-openapps`, `split-into-packages`) now mint `<7.0.0` too, so a new connector does not reintroduce the cap.

  Verified at compile time, not at runtime: all 61 packages in the repo (57 connectors, the two private platform packages, the two shared packages) type-check against `@memberjunction/*@6.1.0-edge.5` — the only 6.x published at the time; there is no stable 6.x yet — with every framework `.d.ts` resolved from the 6.x install and none from 5.x. That check is `npm run check:mj-compat` (`scripts/typecheck-against-mj.mjs`), added with this change so the claim can be re-run against any MJ version. It is API compatibility at the type level; the only runtime evidence on a 6.x host remains the Business Central team's edge deployment.

## 1.3.4

### Patch Changes

- 7438885: GetQuery sends an empty `szColumnList` instead of `*`. The vendor's own GetQuery page says it in so many words — "Asterisk (\*) is not a valid value for szColumnList … you will get this fault" — and the vendor confirmed it against our xWeb credential: every `FetchChanges` call was faulting (surfacing as HTTP 500), and because xWeb counts faulted calls toward `MethodsFaultLimitPerDay` (default 100 a day in the 2017.1 docs, per xWeb user **and IP address**), the faults then locked the calling IP for that user until the next day, which is where the "locked" errors came from. The empty string is the documented form: it "returns the default column listing for the object's primary table", with the primary key always first.

  That is a narrower column set than `*` promised, so a batch whose rows do not carry the object's `IncrementalWatermarkField` now says so (`WATERMARK_COLUMN_ABSENT`) instead of silently never advancing the watermark.

  Not yet proven live, and said so: the same vendor page notes that `@TOP -1` needs named columns ("specific, named fields must be passed … in order to process using the -1 parameter"), and the connector still falls back to `@TOP -1` for an object with no stable ordering key. Every keyed object takes the paged path (`@TOP <BatchSize>` + `ORDER BY`). Whether either form is accepted with an empty list on a real tenant could not be verified for this release because the IP the fix was made from was still locked from the `*` faults.

## 1.3.3

### Patch Changes

- ec5178a: Correct the netFORUM Enterprise auth declaration, and pin the declared catalog's freshness.

  **The auth prose contradicted the code it cited.** `CredentialType.Description`, the credential
  `FieldSchema` field help, and `Integration.Configuration.AuthFlowNote` / `AuthHeaderPattern` /
  `AuthHeaderPatternNote` / `TransportMode` / `TransportModeNote` all described a JSON shim: POST to
  `<BaseURL>/xWeb/JSON/Authenticate` with HTTP Basic, receive an `Authorization: Bearer <token>` for
  later calls. The connector does not do that and never has on this code path.
  `NetForumConnector.Authenticate()` POSTs a SOAP `Authenticate(userName, password)` envelope to
  `<BaseURL>/xweb/secure/netForumXML.asmx` with the credentials as **body elements** — no HTTP
  `Authorization` header is set on that call at all — and reads the token from `AuthenticateResult`.
  Every later call carries it as a SOAP **header element**,
  `<AuthorizationToken><Token>{token}</Token></AuthorizationToken>`. The connector's own file header
  has said so verbatim throughout: _"Auth (TWO-STEP, SOAP — NOT HTTP Basic / WWW-Authenticate /
  Bearer)"_.

  This is operator-facing, not cosmetic: `CredentialType.Description` and `FieldSchema` are what
  someone reads while filling in the credential form, and they are served from the tenant catalog —
  so an operator debugging a failed connection was being told to look for a Bearer header that never
  appears on the wire. `TransportMode` also moves `soap_with_json_shim` → `soap`; the JSON shim is not
  called by this connector and its existence is unverified from this repo.

  The old note cited `NetForumConnector.ts:326-357`, a line range that now lands on unrelated code.
  The replacement cites **symbols** (`Authenticate()`, `BuildSoapEnvelope()`, `SoapHeaders()`), which
  survive edits.

  **The declared catalog had no freshness record.** Provenance was three keys buried inside
  `WSDLOperationCounts` — the fetch date reading as a footnote to a statistic rather than as the
  catalog's evidence base. They move into a `DeclaredAgainst` block (the convention already used by
  `LMS/Elevate` and `Platform/WordPress`), which additionally records what is **not** pinned, because
  an unrecorded gap reads as a settled fact:

  - **no `sha256`** of the 5.94 MB WSDL — a refetch cannot be diffed against what was declared from;
    `totalUniqueOperations` (277) is the only comparable, and a bare count can collide.
  - **no `docSitesFetchedAt`** — the Abila 2017.1 pages are cited throughout the Configuration but
    were never date-stamped.
  - **no `tenantReleaseVersion`** — the two source WSDLs are live tenant instances of unknown release,
    read against a 2017.1 doc set, so a later "missing" object cannot be attributed (catalog wrong, or
    tenant older?). `Platform/WordPress` pins `wp 7.1` / `woocommerce 11.0.1` with zip sha256s for
    exactly this reason.
  - **`catalogLastEditedAt`** — "source fetched" and "catalog edited" are different dates.
    `V202607280915` edited the catalog 37 days after the pin, from the same WSDL read; nothing
    recorded that, so a reader could not tell an evidence-backed edit from a freehand one.

  No object rows, field rows, IDs or capability flags change. Reads and writes are unaffected —
  this ships declared text only, via delta migration `V202608261200` (+ its Postgres twin).

## 1.3.2

### Patch Changes

- 6ee916d: Relicense to the Business Source License 1.1.

  Metadata and documentation only: the `license` field moves to `BUSL-1.1` and the
  repo gains a LICENSE file. No runtime behaviour, API surface, or dependency
  changes. The bump exists so the new licence metadata reaches npm, since the
  registry shows the licence of the latest published version.

## 1.3.1

### Patch Changes

- 517466f: Fix silent record loss in NetForum + ORCID pagination, and declare the missing `connector-schema-merge` runtime dependency in HubSpot + Totara.

  **NetForum**: `FetchChanges` requested `@TOP -1` (the entire result set in one SOAP call) and hardcoded `HasMore: false`, so `BatchSize` was ignored and the computed `NextAfterKeyValue` was discarded. Now issues a `@TOP <BatchSize>` window with an `ORDER BY` on the stable ordering key, applies a `> AfterKeyValue` keyset predicate on resume, and reports `HasMore` from the page fill. Objects with no ordering key can't be paged safely, so they keep the single-call behavior and now emit an `UNPAGINATED_FETCH` warning instead of failing silently. `NewWatermarkValue` advances only on the final page.

  **ORCID**: `ResolveOrcidIdUniverse` sliced the resolved iD universe to `BatchSize` and returned `HasMore: false` — every iD past the first page was permanently discarded on every sync. The universe is now returned whole and sorted, windowed by `AfterKeyValue`, with `HasMore` + `NextAfterKeyValue` set so the scan completes across pages. Watermark advances only on the last page.

  **HubSpot / Totara**: both `import` `@memberjunction/connector-schema-merge` at runtime but declared it under `devDependencies`, which does not ship to consumers — the same `ERR_MODULE_NOT_FOUND` shape that leaves HubSpot broken on npm at 1.1.1. Moved to `dependencies`.

- f100ed8: Withdraw the write from the five netFORUM Enterprise objects that declare no fields and can never
  acquire a primary key.

  A writable `IntegrationObject` with no `IsPrimaryKey` field derives a **keyless entity**. On Postgres,
  MJ's save audit-wrapper then emits an empty record identifier and every save fails with
  `syntax error at or near ","`, while fetch keeps succeeding — the object reads green and persists
  nothing.

  These five are a distinct case from the rest of the fleet: each declares **zero** fields and is marked
  `Configuration.placeholder = true` with `schemaSource: "runtime-discovered (GetFacadeXMLSchema /
GetQueryDefinition)"`. The connector's other ten writable objects each declare hundreds of fields and a
  proper key (`Individual.ind_cst_key`, `Invoice.inv_key`, `Organization.org_cst_key`, …).

  **Runtime discovery cannot rescue them.** `NetForumConnector.ParseQueryDefinition` sets
  `IsPrimaryKey: declared?.IsPrimaryKey ?? false` — a netFORUM column definition does not mark a primary
  key, so a discovered field is _never_ a key and an object with no declared key stays keyless forever.
  There is nothing to stamp and nothing may be invented.

  Evidence is the vendor's own public WSDL for the xWeb SOAP service (`netFORUMXML.asmx?WSDL`, namespace
  `http://www.avectra.com/2005/`), read operation by operation.

  | Object                    | Change           | WSDL evidence                                                                                                                                                                                                                                                                                                                                                                                                 |
  | ------------------------- | ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | `CustomerAction`          | create withdrawn | `InsertCustomerAction(actionCustomerKey, action, actionTypeKey, source, actionDate, actionSubtypeList) -> guid`, but the declared read door `GetActionTypeList()` takes **no arguments** and returns the action **TYPE** list — not customer actions. Nothing written is ever read back, and no fields are declared to build a create body from.                                                              |
  | `CommunicationPreference` | update withdrawn | `SetCustomerCommunicationPreferences(customerKey, ArrayOfMailingListSetting)` → **empty response**. One call carries a customer plus an _array_ of settings — no single record, no returned identity. Already broken: `UpdateRecord` injects the external id via `PrimaryKeyFieldName()`, which reads declared fields only, so the envelope goes out with **no `customerKey` at all**.                        |
  | `CEUCredit`               | create withdrawn | `CeuApplyExternalCredits(individualKey, CeuCreditList)` → `ArrayOfCeuCreditResult` (each `{ceu_key, externalId, resultStatus, resultMessage}`). A bulk apply-many-to-one; keys come back inside an array, so there is no single created record for `BuildCreatedResult`. Its declared read door _is_ the write method.                                                                                        |
  | `AdvocacyData`            | create withdrawn | `CreateAdvocacyData(oNode)` → **empty response**, no identifier at all. Already a hard failure today: `BuildCreatedResult` returns `Success:false` on an empty id rather than silently losing the record. Its declared read door is also the write method.                                                                                                                                                    |
  | `FacadeObject`            | write withdrawn  | A generic meta-accessor, not a record type — the object _name_ is a parameter: `GetFacadeObject(szObjectName, szObjectKey)`, `InsertFacadeObject(szObjectName, oNode)`, `UpdateFacadeObject(szObjectName, szObjectKey, oNode)`. One catalog row would stand for every netFORUM entity without a dedicated `WEB*` method at once, and `UpdateFacadeObject` needs an `szObjectKey` the connector cannot supply. |

  Reads are unaffected on all five. `CustomerAction`'s insert does return a key, so it could be modelled
  properly once a real read door for customer actions is established — that is object authoring, not a
  key stamp, and is deliberately out of scope here.

  Metadata and the delta migration move together in both dialects; the seed migration is untouched.

## 1.3.0

### Minor Changes

- 37cfe35: Sample-union discovery for describe-endpoint connectors: each connector wires MJ's existing `DiscoverFieldsViaFetch` sampler into its declared catalog inside `IntrospectSchema`, unioned per object via the shared pure helper `mergeDeclaredWithSampledFields` — real widths and MJ-discovered custom columns land before the first sync (no `nvarchar(255)` overflow / `STRING_OVERFLOW_SKIPPED`). Connectors with no `IntrospectSchema` of their own get the standard `super.IntrospectSchema → sample → merge → return` override; connectors that already own an `IntrospectSchema` (HubSpot, Salesforce, Nimble AMS, YourMembership) are WRAPPED — their existing logic/caching is preserved and the union runs on the built result before return (Fonteva inherits it via Salesforce's `super`).

  The width rule is NEVER-SHRINK: `MaxLength = max(declared, measured)`. It only ever widens, so connectors that already carry real declared widths from their describe API (Salesforce/Fonteva) are never truncated below the real width, while connectors whose declared catalog has no width still adopt MJ's measured value. Connectors add no discovery/merge/sync logic of their own; MJ owns measurement, type/PK inference, persistence and reconcile. `DiscoverFields` is unchanged (no recursion). Schema-less / already-streaming connectors (PropFuel, FileFeed, RelationalDB, MJtoMJ, ORCID) are unaffected.

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
