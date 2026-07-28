# @memberjunction/connector-netforum-enterprise

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
