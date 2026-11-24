---
"@memberjunction/connector-fonteva": patch
"@memberjunction/connector-impexium": patch
"@memberjunction/connector-salesforce": patch
"@memberjunction/connector-openwater": patch
"@memberjunction/connector-higher-logic-thrive-community": patch
"@memberjunction/connector-sfmc": patch
---

Wire `1,570` declared DAG-safe scalar `Configuration.ReferencedType` foreign-key relationships (`RelatedIntegrationObjectID` `@lookup` references and `RelatedIntegrationObjectFieldName`) across Salesforce (`1,509`), Fonteva (`56`), OpenWater (`3`), Impexium (`1`), and HigherLogicThriveCommunity (`1`) with paired SQL Server and PostgreSQL delta migrations (`V202611161330`). Migrations match by `(LOWER(Integration.Name), IntegrationObject.Name, IntegrationObjectField.Name)` and backfill `RelatedIntegrationObjectFieldName` when discovery already populated `RelatedIntegrationObjectID`. Also keeps live Salesforce `/describe` discovery DAG-safe (excluding `CreatedById`/`LastModifiedById`, polymorphic multi-target lookups, and multi-object cycle back-edges while preserving self-references, reading per-connection catalog edges via `GetRelatedIntegrationObjectIDs` when available, and handling pre-existing catalog cycles without stripping valid parent edges), clears two invalid SFMC `ReferencedType` metadata hints (`AutomationActivity.Sequence`, `AutomationNotification.Address`) via `JSON_MODIFY`/`jsonb` so other `Configuration` keys stay intact, removes unused legacy `metadata/additionalSchemaInfo.json` slices across 14 connectors, and adds a permanent CI lint gate (`lint:declared-fks`) in `pr.yml` and `release.yml`.
