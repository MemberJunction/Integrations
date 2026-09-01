---
"@memberjunction/connector-elevate": patch
---

Let a runtime-discovered object be queried, using the resource name the site itself published

`DiscoverObjects` reads this site's `/api/reports` catalog and adds every resource the declared
catalog omits. Those objects have no declared Configuration at all — the page gives a name and a
field list, nothing else — so `ReadRouteFor` could not resolve a `resourceWireValue` and threw.

The consequence was that every discovered object was born unqueryable: `DiscoverFieldsViaFetch`
failed, no fields were ever learned, and the object surfaced in the table picker reading "No fields
found for this table" with no path to ever sync. On a live tenant that was 18 of 23 objects, while
the 5 declared ones worked normally — which made a working discovery look like a broken one.

`ReadRouteFor` now resolves the wire value from three sources in order: the declared
`resourceWireValue`, the declared access path's own body selector, and finally the resource name
this site returned from `/api/reports`.

The refusal is deliberately unchanged for anything the catalog does NOT list. It exists because the
vendor's own prose spells the accounting resource "accountCode", which the door rejects with HTTP
500 — only "accountingCode" works. The catalog is the opposite kind of evidence: the site returns
the string verbatim rather than describing it in prose, and `CatalogResource.Name` is already
documented as the wire value for the request body's `resource` field. A name absent from the
catalog is still an unproven guess and is still refused.

Matching is case-insensitive, but the string sent is the catalog's exact spelling — the wire value
is what the site said, not what the IntegrationObject happens to be called. A declared wire value
always wins; the catalog is consulted only when the declaration is silent.
