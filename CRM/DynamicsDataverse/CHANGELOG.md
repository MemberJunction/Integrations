# @memberjunction/connector-microsoft-dynamics-365-dataverse

## 1.2.2

### Patch Changes

- 6ee916d: Relicense to the Business Source License 1.1.

  Metadata and documentation only: the `license` field moves to `BUSL-1.1` and the
  repo gains a LICENSE file. No runtime behaviour, API surface, or dependency
  changes. The bump exists so the new licence metadata reaches npm, since the
  registry shows the licence of the latest published version.

## 1.2.1

### Patch Changes

- e6976ad: Give the six keyless read-only Dataverse catalog objects their documented primary key, so they stop
  being silently dropped at tenant setup.

  A catalog object with no `IsPrimaryKey` field never becomes an MJ entity at all. `SoftPKClassifier`
  runs a cascade at setup — universal-convention, naming heuristic, statistical and composite inference
  over sample rows, then a one-shot LLM — before a synthetic identity-hash fallback that is **off by
  default**. None of those tiers fires for these six: the naming heuristic matches only
  `<object>Id | <objectSingular>Id | id | uuid | guid`, so `appmoduleroleid`, `indexid`,
  `indexattributeid`, `ribbonmetadatarowid`, `roletemplateprivilegeid` and `dependencyid` all miss. The
  verdict is `Confident=false`, and per the classifier's own contract the pipeline then "leaves the IO
  row PK-less; no `__mj.Entity` is created for it until a PK resolves (the runtime D7 rule)". An
  operator who picks "all objects" during setup gets six rows that never materialize — a quieter
  failure than the writable keyless case, which at least reads green before failing to save.

  Every key here is the vendor's own. Each Dataverse table publishes a `PrimaryIdAttribute` in
  Microsoft's table/entity reference — the column the Web API addresses a single record by — and in all
  six cases that attribute is **already a declared field** on the catalog row, so this only sets the
  `IsPrimaryKey` flag on a column that exists. Nothing is created and nothing is inferred.

  | Object                    | Key                       | Microsoft's `PrimaryIdAttribute`                                                                                                                                                    |
  | ------------------------- | ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | `appmoduleroles`          | `appmoduleroleid`         | `appmoduleroleid`. The sibling `appmoduleroleidunique` is the solution-sync identifier, not the record key — the same pairing Dataverse uses across every solution-component table. |
  | `entityindex`             | `indexid`                 | `indexid`, "Unique identifier of the index id".                                                                                                                                     |
  | `indexattributes`         | `indexattributeid`        | `indexattributeid`, "Unique identifier of the index attribute". The declared `indexid` is the parent FK.                                                                            |
  | `ribbonmetadatatoprocess` | `ribbonmetadatarowid`     | `ribbonmetadatarowid`, "Unique identifier for Ribbon Metadata Instance To Process".                                                                                                 |
  | `roletemplateprivileges`  | `roletemplateprivilegeid` | `roletemplateprivilegeid`, "Unique identifier of the role template privileges". The declared `roletemplateid` and `privilegeid` are the two FKs this intersect row joins.           |
  | `runtimedependency`       | `dependencyid`            | `dependencyid`, "Unique identifier of a dependency".                                                                                                                                |

  Each is independently corroborated **from inside this repository**, without consulting the docs at
  all: the catalog row's own `Description` — written by the connector's live, credentialed
  `EntityDefinitions` discovery against a real org — already spells out `PK <column> (GUID)`, naming
  exactly the column stamped here in all six cases. The catalog has recorded the right key since it was
  seeded; only the `IsPrimaryKey` flag that MJ actually reads was never set.

  **Four sibling objects are deliberately left keyless.** `subscriptionstatisticsoffline`,
  `subscriptionstatisticsoutlook`, `subscriptionsyncentryoffline` and `subscriptionsyncentryoutlook`
  each document `PrimaryIdAttribute = subscriptionid`, which _is_ a declared field — but their own
  column sets show a finer row grain than one row per subscription: the statistics tables declare
  `objecttypecode` SystemRequired alongside it, and the sync-entry tables declare `objectid` and
  `objecttypecode` SystemRequired. Dataverse requires every table to name a `PrimaryIdAttribute`, and
  for these internal offline/Outlook-sync bookkeeping tables it names the leading column of a composite
  key. Stamping `subscriptionid` would hand MJ a key that repeats across rows, collapsing many records
  into one on every sync — a silent data loss strictly worse than the current "no entity". They stay
  keyless until a live round-trip settles the real grain.

  **Why a stamp and not a deprecation.** `DynamicsDataverseConnector.DiscoverObjects` has no baked
  object list: it parses the credentialed `EntityDefinitions` describe endpoint at runtime and
  enumerates "the COMPLETE credentialed gamut (standard + custom + solution-installed)".
  `IntegrationSchemaSync` implements REACTIVATE-on-rediscover, so any `Status` change away from
  `Active` on a table the org still exposes would be flipped straight back on the next discovery. For
  this connector a stamp is the only disposition that holds.

  Nothing else in the 592-object catalog moves and no object ends up with more than one primary key —
  both asserted by the generator that produced the metadata edit and the migration together. Metadata
  and the delta migration move in lockstep in both dialects; the `V202606271409` seed is untouched, so
  no existing UUID is re-minted and no Flyway checksum breaks.

## 1.2.0

### Minor Changes

- 37cfe35: Sample-union discovery for describe-endpoint connectors: each connector wires MJ's existing `DiscoverFieldsViaFetch` sampler into its declared catalog inside `IntrospectSchema`, unioned per object via the shared pure helper `mergeDeclaredWithSampledFields` — real widths and MJ-discovered custom columns land before the first sync (no `nvarchar(255)` overflow / `STRING_OVERFLOW_SKIPPED`). Connectors with no `IntrospectSchema` of their own get the standard `super.IntrospectSchema → sample → merge → return` override; connectors that already own an `IntrospectSchema` (HubSpot, Salesforce, Nimble AMS, YourMembership) are WRAPPED — their existing logic/caching is preserved and the union runs on the built result before return (Fonteva inherits it via Salesforce's `super`).

  The width rule is NEVER-SHRINK: `MaxLength = max(declared, measured)`. It only ever widens, so connectors that already carry real declared widths from their describe API (Salesforce/Fonteva) are never truncated below the real width, while connectors whose declared catalog has no width still adopt MJ's measured value. Connectors add no discovery/merge/sync logic of their own; MJ owns measurement, type/PK inference, persistence and reconcile. `DiscoverFields` is unchanged (no recursion). Schema-less / already-streaming connectors (PropFuel, FileFeed, RelationalDB, MJtoMJ, ORCID) are unaffected.

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
