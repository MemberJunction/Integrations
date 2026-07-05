---
'@memberjunction/connector-wicket': minor
---

Sample-union discovery: override the connector's OWN `IntrospectSchema` to wire MJ's existing
`DiscoverFieldsViaFetch` sampler into the declared catalog. `super.IntrospectSchema` (declared, no
measured widths) is unioned per object with MJ's read-path sample via the shared pure helper
`mergeDeclaredWithSampledFields` — measured widths are adopted and MJ-discovered custom columns are
appended before the first sync (no nvarchar(255) overflow / STRING_OVERFLOW_SKIPPED). The connector
adds NO discovery/merge/sync logic of its own; MJ owns measurement, type/PK inference, persistence and
reconcile. `DiscoverFields` is unchanged (no recursion); the connector still `extends
BaseRESTIntegrationConnector` — no base class, no re-parenting.
