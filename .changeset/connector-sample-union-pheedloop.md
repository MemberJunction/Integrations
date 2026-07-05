---
'@memberjunction/connector-pheedloop': minor
---

Sample-union discovery: override the connector's OWN `IntrospectSchema` to UNION the declared catalog
(`super.IntrospectSchema`) with a bounded, read-only streaming data sample (`DiscoverFieldsViaFetch`)
via the shared pure helper `mergeDeclaredWithSampledFields`. First-sync string widths are now
data-measured (no nvarchar(255) overflow / STRING_OVERFLOW_SKIPPED), custom columns present in real
payloads surface before the first sync, and a statistical PK is adopted only where the catalog declares
none. `DiscoverFields` is unchanged (no recursion), and the connector still `extends
BaseRESTIntegrationConnector` — no base class, no re-parenting.
