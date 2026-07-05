---
'@memberjunction/connector-aptify': minor
'@memberjunction/connector-blackbaud': minor
'@memberjunction/connector-constant-contact': minor
'@memberjunction/connector-cvent': minor
'@memberjunction/connector-eventbrite': minor
'@memberjunction/connector-growthzone': minor
'@memberjunction/connector-hivebrite': minor
'@memberjunction/connector-hubspot': minor
'@memberjunction/connector-imis': minor
'@memberjunction/connector-magnetmail': minor
'@memberjunction/connector-mailchimp': minor
'@memberjunction/connector-membersuite': minor
'@memberjunction/connector-microsoft-dynamics-365-dataverse': minor
'@memberjunction/connector-neon-crm': minor
'@memberjunction/connector-netforum-enterprise': minor
'@memberjunction/connector-netsuite': minor
'@memberjunction/connector-nimble-ams': minor
'@memberjunction/connector-novi-ams': minor
'@memberjunction/connector-openwater': minor
'@memberjunction/connector-path-lms': minor
'@memberjunction/connector-pheedloop': minor
'@memberjunction/connector-quickbooks': minor
'@memberjunction/connector-rasa-io': minor
'@memberjunction/connector-reach360': minor
'@memberjunction/connector-rhythm-software': minor
'@memberjunction/connector-sage-intacct': minor
'@memberjunction/connector-salesforce': minor
'@memberjunction/connector-sharepoint': minor
'@memberjunction/connector-wicket': minor
'@memberjunction/connector-wild-apricot': minor
'@memberjunction/connector-yourmembership': minor
---

Sample-union discovery for describe-endpoint connectors: each connector wires MJ's existing `DiscoverFieldsViaFetch` sampler into its declared catalog inside `IntrospectSchema`, unioned per object via the shared pure helper `mergeDeclaredWithSampledFields` — real widths and MJ-discovered custom columns land before the first sync (no `nvarchar(255)` overflow / `STRING_OVERFLOW_SKIPPED`). Connectors with no `IntrospectSchema` of their own get the standard `super.IntrospectSchema → sample → merge → return` override; connectors that already own an `IntrospectSchema` (HubSpot, Salesforce, Nimble AMS, YourMembership) are WRAPPED — their existing logic/caching is preserved and the union runs on the built result before return (Fonteva inherits it via Salesforce's `super`).

The width rule is NEVER-SHRINK: `MaxLength = max(declared, measured)`. It only ever widens, so connectors that already carry real declared widths from their describe API (Salesforce/Fonteva) are never truncated below the real width, while connectors whose declared catalog has no width still adopt MJ's measured value. Connectors add no discovery/merge/sync logic of their own; MJ owns measurement, type/PK inference, persistence and reconcile. `DiscoverFields` is unchanged (no recursion). Schema-less / already-streaming connectors (PropFuel, FileFeed, RelationalDB, MJtoMJ, ORCID) are unaffected.
