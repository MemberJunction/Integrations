---
'@memberjunction/connector-aptify': minor
'@memberjunction/connector-blackbaud': minor
'@memberjunction/connector-constant-contact': minor
'@memberjunction/connector-cvent': minor
'@memberjunction/connector-eventbrite': minor
'@memberjunction/connector-growthzone': minor
'@memberjunction/connector-imis': minor
'@memberjunction/connector-mailchimp': minor
'@memberjunction/connector-membersuite': minor
'@memberjunction/connector-microsoft-dynamics-365-dataverse': minor
'@memberjunction/connector-neon-crm': minor
'@memberjunction/connector-netforum-enterprise': minor
'@memberjunction/connector-netsuite': minor
'@memberjunction/connector-novi-ams': minor
'@memberjunction/connector-openwater': minor
'@memberjunction/connector-path-lms': minor
'@memberjunction/connector-pheedloop': minor
'@memberjunction/connector-rasa-io': minor
'@memberjunction/connector-reach360': minor
'@memberjunction/connector-rhythm-software': minor
'@memberjunction/connector-wicket': minor
'@memberjunction/connector-wild-apricot': minor
---

Sample-union discovery for describe-endpoint connectors: each connector overrides its own `IntrospectSchema` to wire MJ's existing `DiscoverFieldsViaFetch` sampler into the declared catalog, unioned per object via the shared pure helper `mergeDeclaredWithSampledFields` — MJ's measured widths are adopted and MJ-discovered custom columns are appended before the first sync (no `nvarchar(255)` overflow / `STRING_OVERFLOW_SKIPPED`). Connectors add no discovery/merge/sync logic of their own; MJ owns measurement, type/PK inference, persistence and reconcile. `DiscoverFields` is unchanged (no recursion); connectors still `extends BaseRESTIntegrationConnector` (no base class, no re-parenting). Schema-less connectors are unaffected.
