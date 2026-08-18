---
"@memberjunction/connector-business-central": major
---

Nest eleven child objects under their parent document — they were unreachable against real Business Central.

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
half-covered. Business Central navigates `contactInformation` from `customer`, `vendor` *and* `contact`;
the flat company-level form returns `400 "id type not specified"` because it cannot disambiguate, while
`/customers({id})/contactsInformation` and `/vendors({id})/contactsInformation` both return 200 live. One
`APIPath` expresses one chain, so this stamps the customer side — the object goes from reachable-never to
reachable-for-customers. **Vendor and contact contact-information remain unreachable**, and covering them
needs a separate catalog object per parent, which is a modelling change rather than a path correction and
is deliberately not made here.

Also fixes a stray space in `vendorPayments`' `UpdateAPIPath` / `DeleteAPIPath`
(`/companies({id})/vendorPayments ({id})`), which would not have resolved even flat.

Two objects still do not read on the probed tenant and are **not** connector defects, recorded so they are
not mistaken for regressions: `purchaseCreditMemos` returns `400` with *"You must run the data upgrade for
this API page…"*, a tenant-side API Data Upgrade action (which also blocks `purchaseCreditMemoLines` as its
child), and `picture` could not be exercised because the probed company has no `items`. `picture` and
`attachments` are also the only two objects whose paths use named placeholders (`{companyId}`, `{itemId}`)
rather than the repeated `{id}` the connector's URL builder documents; that inconsistency is left untouched
because no live data existed to test the change against.

Delta migration `V202608172000__business-central__NestedLinePaths` updates installed tenants by row ID; the
original seed is untouched, so no Flyway checksum breaks. No connector code change.
