---
"@memberjunction/connector-fonteva": patch
"@memberjunction/connector-growthzone": patch
"@memberjunction/connector-impexium": patch
"@memberjunction/connector-nimble-ams": patch
"@memberjunction/connector-imis": patch
"@memberjunction/connector-neon-crm": patch
"@memberjunction/connector-salesforce": patch
"@memberjunction/connector-cvent": patch
"@memberjunction/connector-eventbrite": patch
"@memberjunction/connector-openwater": patch
"@memberjunction/connector-netsuite": patch
"@memberjunction/connector-path-lms": patch
"@memberjunction/connector-propfuel": patch
"@memberjunction/connector-higher-logic-thrive-community": patch
"@memberjunction/connector-hivebrite": patch
"@memberjunction/connector-orcid": patch
---

Wire `4,982` declared scalar `Configuration.ReferencedType` foreign-key relationships (`RelatedIntegrationObjectID` `@lookup` references and `RelatedIntegrationObjectFieldName`) across Salesforce, Fonteva, OpenWater, Impexium, and HigherLogicThriveCommunity with paired SQL Server and PostgreSQL delta migrations (`V202611161330`), and remove unused legacy `metadata/additionalSchemaInfo.json` slices across 14 connectors.
