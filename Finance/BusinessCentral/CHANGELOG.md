# @memberjunction/connector-business-central

## 2.0.0

### Major Changes

- 2f58b9b: Nest eleven child objects under their parent document — they were unreachable against real Business Central.

  `salesInvoiceLines`, `salesOrderLines`, `salesQuoteLines`, `salesCreditMemoLines`, `purchaseInvoiceLines`,
  `purchaseOrderLines`, `purchaseCreditMemoLines`, `customerPayments`, `vendorPayments` and
  `timeRegistrationEntries` addressed their collection directly under the company
  (`/companies({id})/salesInvoiceLines`). That URL is structurally valid OData — Business Central publishes
  the navigation property on the `company` EntityType and Microsoft's reference documents the form — but the
  service refuses it at runtime with `400 Application_DialogException`, "You must specify a parent ID". Every
  one of the ten failed on **both** read and write, since `CreateAPIPath` carried the same flat path.

  The nested form each object actually requires was already recorded on its own row, in
  `Configuration.nestedAlternatePaths` and `Configuration.documentedPaths`; the generator promoted the flat
  variant of the two documented forms into the operative path columns. `APIPath`, `CreateAPIPath`,
  `UpdateAPIPath` and `DeleteAPIPath` now carry the nested variant, matching `journalLines`, which was
  already correct. Parent bindings are taken from a live tenant's `/api/v2.0/$metadata` NavigationProperty
  graph rather than from naming.

  Found by the first full-catalog read sweep against a live Business Central tenant. The credential-free
  suite could not have caught it: the mock replays fixtures at whatever path the catalog declares, so a wrong
  path is self-consistent and green — and the catalog and the mock were generated from the same Microsoft
  corpus that advertises the flat form. Five of the ten are confirmed by a live 200-with-rows read on the
  nested path; the other five share the same metadata binding but their parent collection was empty in the
  probed company.

  `contactsInformation` is the eleventh and is a **partial** fix, stated as such rather than quietly
  half-covered. Business Central navigates `contactInformation` from `customer`, `vendor` _and_ `contact`;
  the flat company-level form returns `400 "id type not specified"` because it cannot disambiguate, while
  `/customers({id})/contactsInformation` and `/vendors({id})/contactsInformation` both return 200 live. One
  `APIPath` expresses one chain, so this stamps the customer side — the object goes from reachable-never to
  reachable-for-customers. **Vendor and contact contact-information remain unreachable**, and covering them
  needs a separate catalog object per parent, which is a modelling change rather than a path correction and
  is deliberately not made here.

  Also fixes a stray space in `vendorPayments`' `UpdateAPIPath` / `DeleteAPIPath`
  (`/companies({id})/vendorPayments ({id})`), which would not have resolved even flat.

  Two objects still do not read on the probed tenant and are **not** connector defects, recorded so they are
  not mistaken for regressions: `purchaseCreditMemos` returns `400` with _"You must run the data upgrade for
  this API page…"_, a tenant-side API Data Upgrade action (which also blocks `purchaseCreditMemoLines` as its
  child), and `picture` could not be exercised because the probed company has no `items`. `picture` and
  `attachments` are also the only two objects whose paths use named placeholders (`{companyId}`, `{itemId}`)
  rather than the repeated `{id}` the connector's URL builder documents; that inconsistency is left untouched
  because no live data existed to test the change against.

  Delta migration `V202608172000__business-central__NestedLinePaths` updates installed tenants by row ID; the
  original seed is untouched, so no Flyway checksum breaks. No connector code change.

## 1.2.0

### Minor Changes

- 08388cc: Batch writes for Business Central via OData `$batch`.

  The connector inherited the framework's default batch implementation, which loops single-record
  `CreateRecord` — and Business Central serializes every write through a paced chain, so each record
  costs a round trip plus a pacing sleep. A 60-line journal batch was 60 requests and 60 sleeps. It is
  now one request.

  Constraints taken from Microsoft's contract rather than inferred:

  - **100 operations per envelope**, the documented ceiling. Larger inputs are chunked, so a 250-line
    journal is three envelopes rather than an error.
  - **Responses are matched by `id`, never by position.** Response order is not guaranteed to mirror
    request order; matching positionally would attribute one record's created ID to a different record.
  - **Partial success is normal.** Each sub-response carries its own status, so results are built per
    record using the same ID extraction and error classification as the single-record path.
  - **A missing sub-response fails that record loudly** rather than defaulting to success — a silently
    dropped create becomes a duplicate on the next sync.

  Falls back to the sequential path where batching cannot apply: a single record, the `odatav4` surface
  (published pages do not share the API's batch grammar), or a mixed set of CompanyIntegrations or
  objects, since one envelope is scoped to a single tenant and entity set.

- 08388cc: Post a journal batch to the general ledger.

  Creating `journals` and `journalLines` stages a batch — it sits in Business Central unposted, and
  nothing reaches the general ledger until it is posted. `PostJournal()` is that step, so A-UC7 can now
  complete rather than stopping at staging.

  Posting is an OData **bound action**, not a CRUD verb, so it cannot travel through the generic
  Create/Update/Delete surface and cannot be emitted by `ActionMetadataGenerator`, whose verb set is
  fixed at Get/Create/Update/Delete/Upsert/Search/List. It is therefore an explicit connector method
  that the consuming app calls directly or wraps in an Action of its own.

  The action name is **case sensitive** in an asymmetric way: `Microsoft.NAV.post`, with a capitalised
  namespace and a lower-case first word. `Microsoft.NAV.Post` returns 404, which reads as "no such
  journal" and sends debugging toward the ID rather than the verb. Pinned by test.

  Posting is irreversible through the API — a posted journal is corrected with a reversing entry, not
  un-posted — so a successful return should be treated as a ledger mutation rather than a staging step.

- 08388cc: Allow MemberJunction 6.x as a peer.

  Both packages capped their MJ peers at `<6.0.0`. Under pnpm with `auto-install-peers`, a 6.x host
  therefore resolves a **second** copy of `@memberjunction/core` to satisfy the connector, and two copies
  of core in one process is the failure that produces thousands of unrelated-looking type errors.

  Widening only the connector would not have been enough: `connector-schema-merge` is a runtime
  dependency of the Business Central connector and carried its own `<6.0.0` ceiling, so the duplicate
  would have come back transitively. Both ceilings move to `<7.0.0`.

  The floor is unchanged, so 5.x consumers are unaffected.

  Basis for the claim: the BizApps Accounting team reported running this connector against an MJ
  6.1.0-edge host, with the peer ranges as the friction rather than the code. This range widening
  reflects that evidence — it is not a claim that 6.x is separately regression-tested here.

### Patch Changes

- 08388cc: Make `$batch` writes transactional, and stop reporting rolled-back creates as successes.

  Business Central's batch endpoint is all-or-nothing only when asked: Microsoft's contract is that
  `Isolation: snapshot` makes the batch run in one transaction, and "if an inner request fails after
  another request(s) has committed changes, all changes within a batch will be reverted as if the batch
  request never happened." The header is now sent. For journal lines this is the behaviour you want by
  default — a half-staged journal batch is worse than none, because it looks real and will not balance.

  That exposed a correctness bug in the batch results. Under snapshot isolation Business Central still
  reports each operation's own status, so a create that was rolled back still comes back as 201. The
  previous implementation reported those as successful, handing the caller an `ExternalID` for a record
  that does not exist — and because the caller believed it existed, the next sync would not recreate it.
  Any failure in an envelope now fails every record in it, with the vendor's message and an explicit
  note that the batch was reverted.

  Two smaller fixes alongside:

  - **Positional fallback when ids are absent.** Responses are matched by `id`, but Business Central does
    not always echo one — Microsoft's own transactional example returns `"id": null` for every operation.
    When no response carries an id, results are matched by position rather than failing every record.
  - **A short response list now fails the batch.** Fewer responses than operations means at least one
    outcome is unknown, and under a transactional batch an unknown failure may have reverted the rest.
    This was previously mishandled because `Array.find` returns `undefined` both when nothing matches and
    when the matched element is itself `undefined`, so the missing-response branch never ran.

- Updated dependencies [08388cc]
  - @memberjunction/connector-schema-merge@1.1.0

## 1.1.0

### Minor Changes

- 668c41c: Enable MJ Action generation for the Business Central connector.

  The connector had no `GetIntegrationObjects()` override, so the base class returned an empty object
  list, `GetActionGeneratorConfig()` returned null, and **no Business Central Actions were ever
  generated** — despite 83 declared objects covering the full accounting surface. The connector was
  reachable by pull sync and by `IntegrationWriteRecord`, but not by an agent, a flow, or
  `IntegrationActionExecutor`.

  Both overrides are now present. The object model is derived entirely from the runtime
  IntegrationObject / IntegrationObjectField cache rather than a list baked into code: when the cache is
  unseeded — action generation can run before the integration is seeded — it returns an empty array and
  generates nothing, and never falls back to a hardcoded subset. With 83 objects, a fallback serving a
  familiar handful would still look like it worked, which is the `catalog-in-code` defect.

  Write capability carries through per object, so read-only objects cannot generate write Actions.
  `accounts` is read-only in Business Central — a journal entry posts _to_ an account, it never creates
  one — and a Create Action there would fail at the vendor every time.

  Also declares `@memberjunction/integration-engine-base` as a peer dependency, which the connector now
  imports directly rather than relying on transitive resolution.

  No behaviour change to sync, authentication, pagination, or the declared catalog.

## 1.0.1

### Patch Changes

- 1d3fd86: Fix two write-path defects found by the credential-free behavioural suite.

  `CreateRecord` read the new record's ID by scanning the response for a literal `id`-shaped key. Business
  Central objects whose primary key is named something else (`customerId`, `number`, a composite pair) came
  back with an empty `ExternalID`, so the record map was never written and the next sync re-created the row.
  The ID is now read from the object's own primary-key metadata, with the previous scan kept as a fallback.

  `parentKeyFromAttributes` did not recognise the generic `parentId` / `parentID` attribute that Business
  Central sub-entities carry, so a nested create (`/companies({id})/salesInvoices({id})/dimensionSetLines`)
  could not resolve its parent segment and produced a malformed URL.

  Both are covered by new unit tests. No metadata, schema or migration change.
