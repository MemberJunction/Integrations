-- OpenWater: say out loud that the catalog is the contract, and stop advertising a dead host.
--
-- TWO DECLARATION DEFECTS on the Integration row, both about what a reader is told.
--
-- 1. DISCOVERY IS DECLARED-ONLY AND NOTHING SAID SO (docs/REQUIRED-FIXES.md item 4).
--    DiscoverObjects / DiscoverFields / IntrospectSchema read the Declared catalog from the engine
--    cache. That is the right design for this vendor: the published swagger
--    (https://api.secure-platform.com/swagger/v2/swagger.json, 92 paths, read 2026-09-22) has no
--    endpoint that enumerates the object surface, so there is nothing live to reconcile against.
--    But a declared catalog with no record of WHAT it was declared from or WHEN is indistinguishable
--    from a current one: a missing object could mean the connector is wrong or that OpenWater moved
--    after we looked, and nothing says which. The fleet rule for this is
--    Configuration.DeclaredAgainst (scripts/lint-catalog-freshness-pin.mjs); OpenWater was on that
--    lint's grandfathered list. This migration writes the pin (URL, date, sha256, path counts, and
--    how to re-check) and extends Description so the picker-facing text states that the object list
--    is fixed per connector version. OpenWater leaves the grandfathered list in the same change.
--
-- 2. THE CATALOG STILL ADVERTISED A DEAD HOST (docs/REQUIRED-FIXES.md item 5).
--    NavigationBaseURL was https://api.getopenwater.com, which does not resolve (NXDOMAIN). The field
--    is display-only, so nothing failed, but it is the URL a human is shown when they ask where their
--    data comes from. The live API host is the shared https://api.secure-platform.com; each tenant's
--    own UI is a subdomain of secure-platform.com, and that subdomain is the connection's ClientKey.
--    The fleet convention for a per-tenant host is a template (e.g. https://{tenant}.mpxapi.com), so
--    the value becomes https://{tenant}.secure-platform.com.
--
-- Delta migration: one UPDATE on the Integration row. The row is resolved with LOWER(Name) so the
-- predicate does not depend on collation (see lint-migration-name-case.mjs and the 2026-09-13
-- PostgreSQL incident). Integration.Configuration has never been set for OpenWater by any migration,
-- so a plain SET is safe; re-running produces the same values. Audit columns are not set.
--
-- Integration.Description is NVARCHAR(255), so the contract statement in it is compressed to fit; the
-- full reasoning lives in Configuration (NVARCHAR(MAX)).
--
-- No object or field changes. The JSON below is byte-identical to fields.Configuration in
-- metadata/integration/.openwater.integration.json (generated from the same blob).

UPDATE [__mj].[Integration]
SET [Description] = N'OpenWater awards/grants/abstracts/fellowship connector — pull sync of programs, applications, users, invoices, judges, rounds and review objects via Public API v2. Catalog is DECLARED (vendor has no enumeration API); see Configuration.DeclaredAgainst.',
    [NavigationBaseURL] = N'https://{tenant}.secure-platform.com',
    [Configuration] = N'{"DeclaredAgainst":{"swagger":{"url":"https://api.secure-platform.com/swagger/v2/swagger.json","accessedAt":"2026-09-22","sha256":"1abdc36cd18add8a0fea16a66530a9141c2b2c7998906af81130d738b5798747","sizeBytes":437128,"specFormat":"OpenAPI 3.0.1","apiTitle":"OpenWater API 2.0","pathCount":92,"getPathCount":46,"schemaCount":231,"authentication":"none required to read the document"},"catalogIsContract":true,"catalogIsContractNote":"None of the 92 paths enumerates the object surface, so live discovery is not possible for this vendor. DiscoverObjects, DiscoverFields and IntrospectSchema read the Declared catalog from the engine cache and DiscoveryIsAuthoritative stays false, so the platform is never told that a live enumeration happened. The object list is therefore the connector version: a collection OpenWater adds after accessedAt cannot appear on any tenant until this catalog is re-declared against a newer swagger.","howToRecheck":"Fetch swagger.url, compare sha256; if it changed, diff its GET paths against the set of APIPath, AccessPath.doorPath, AccessPath.entryPath, alternativePaths and harvestDetailPath values in this catalog. A GET list path with no match is an undeclared object.","surfaceCoverageAt":"2026-09-22","surfaceCoverageNote":"Every GET path not referenced by the catalog on this date is a per-record detail (/{id}), a form template, or a settings singleton. No undeclared list collection existed. Per-record detail data (Evaluation scores and answers, Session chairs and items, User flags) is tracked separately as extraction work, not as a catalog gap.","catalogLastEditedAt":"2026-09-22","catalogLastEditedNote":"Added this pin, extended Description, and replaced NavigationBaseURL (api.getopenwater.com no longer resolves; the live API host is the shared api.secure-platform.com and each tenant UI lives at its own subdomain, which is the connection ClientKey). No object or field changed."}}'
WHERE LOWER([Name]) = 'openwater';
