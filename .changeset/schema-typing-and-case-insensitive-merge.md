---
"@memberjunction/connector-schema-merge": patch
"@memberjunction/connector-nimble-ams": patch
"@memberjunction/connector-netsuite": patch
---

Match declared and sampled field names case-insensitively in `mergeDeclaredWithSampledFields` and map `int`/`integer` and `date` to native schema types in NimbleAMS and NetSuite connectors.
