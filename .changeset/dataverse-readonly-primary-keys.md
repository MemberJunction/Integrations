---
'@memberjunction/connector-microsoft-dynamics-365-dataverse': patch
---

Give the six keyless read-only Dataverse catalog objects their documented primary key, so they stop
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

| Object | Key | Microsoft's `PrimaryIdAttribute` |
| --- | --- | --- |
| `appmoduleroles` | `appmoduleroleid` | `appmoduleroleid`. The sibling `appmoduleroleidunique` is the solution-sync identifier, not the record key — the same pairing Dataverse uses across every solution-component table. |
| `entityindex` | `indexid` | `indexid`, "Unique identifier of the index id". |
| `indexattributes` | `indexattributeid` | `indexattributeid`, "Unique identifier of the index attribute". The declared `indexid` is the parent FK. |
| `ribbonmetadatatoprocess` | `ribbonmetadatarowid` | `ribbonmetadatarowid`, "Unique identifier for Ribbon Metadata Instance To Process". |
| `roletemplateprivileges` | `roletemplateprivilegeid` | `roletemplateprivilegeid`, "Unique identifier of the role template privileges". The declared `roletemplateid` and `privilegeid` are the two FKs this intersect row joins. |
| `runtimedependency` | `dependencyid` | `dependencyid`, "Unique identifier of a dependency". |

Each is independently corroborated **from inside this repository**, without consulting the docs at
all: the catalog row's own `Description` — written by the connector's live, credentialed
`EntityDefinitions` discovery against a real org — already spells out `PK <column> (GUID)`, naming
exactly the column stamped here in all six cases. The catalog has recorded the right key since it was
seeded; only the `IsPrimaryKey` flag that MJ actually reads was never set.

**Four sibling objects are deliberately left keyless.** `subscriptionstatisticsoffline`,
`subscriptionstatisticsoutlook`, `subscriptionsyncentryoffline` and `subscriptionsyncentryoutlook`
each document `PrimaryIdAttribute = subscriptionid`, which *is* a declared field — but their own
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
