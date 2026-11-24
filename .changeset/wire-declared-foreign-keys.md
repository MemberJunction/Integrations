---
"@memberjunction/connector-fonteva": patch
"@memberjunction/connector-impexium": patch
"@memberjunction/connector-salesforce": patch
"@memberjunction/connector-openwater": patch
"@memberjunction/connector-higher-logic-thrive-community": patch
"@memberjunction/connector-sfmc": patch
---

Wire `1,570` declared DAG-safe scalar `Configuration.ReferencedType` foreign-key relationships (`RelatedIntegrationObjectID` `@lookup` references and `RelatedIntegrationObjectFieldName`) across Salesforce (`1,509`), Fonteva (`56`), OpenWater (`3`), Impexium (`1`), and HigherLogicThriveCommunity (`1`) with paired SQL Server and converter-generated PostgreSQL delta migrations (`V202611161330`). Migrations match by `(LOWER(Integration.Name), IntegrationObject.Name, IntegrationObjectField.Name)` and backfill `RelatedIntegrationObjectFieldName` when discovery already populated `RelatedIntegrationObjectID`. Also keeps live Salesforce/Fonteva `/describe` discovery DAG-safe (excluding `CreatedById`/`LastModifiedById` and multi-object cycle back-edges while preserving self-references and respecting existing catalog edges during scoped refreshes), clears two invalid SFMC `ReferencedType` metadata hints (`AutomationActivity.Sequence`, `AutomationNotification.Address`), removes unused legacy `metadata/additionalSchemaInfo.json` slices across 14 connectors, and adds a permanent CI lint gate (`lint:declared-fks`).
