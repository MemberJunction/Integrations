---
'@memberjunction/connector-openwater': patch
---

The catalog now says it is the contract, and no longer advertises a dead host.

**Discovery is declared-only, and nothing said so.** `DiscoverObjects`, `DiscoverFields` and
`IntrospectSchema` read the Declared catalog from the engine cache. That is correct for this vendor:
the published swagger (92 paths, read 2026-09-22) has no endpoint that enumerates the object surface,
so there is nothing live to reconcile against, and `DiscoveryIsAuthoritative` is honestly false. But
with no record of what the catalog was declared from or when, a stale catalog was indistinguishable
from a current one, and the picker looked complete without saying it could only ever be as current as
the last catalog edit. The Integration row now carries `Configuration.DeclaredAgainst` (swagger URL,
access date, sha256, path and schema counts, and how to re-check), the Description (bounded to 255 characters by
the column) states that the catalog is declared and names the pin, and OpenWater leaves the freshness-pin lint's
grandfathered list. Checked on the same date: every swagger GET path the catalog does not reference is
a per-record detail, a form template or a settings singleton, so no list collection is undeclared today.

**The catalog advertised a host that does not resolve.** `NavigationBaseURL` was
`https://api.getopenwater.com`, which is NXDOMAIN. Display-only, so nothing failed, but it is the URL a
person is shown when they ask where their data comes from. The value is now the fleet's per-tenant
template form, `https://{tenant}.secure-platform.com`; the tenant subdomain is the connection's
ClientKey.

One delta migration (paired T-SQL and PostgreSQL) updates the Integration row, resolved with
`LOWER(Name)` so it applies on both dialects. No object or field changed.
