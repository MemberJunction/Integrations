# @memberjunction/connector-rasa-io

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
