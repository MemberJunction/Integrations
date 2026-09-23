-- Nimble AMS: disable FuseEndpoint, which is an endpoint, not a data object.
--
-- Its own declared Description says so: "The single Nimble Fuse integration endpoint
-- (/services/apexrest/NUINT/NUIntegrationService). A POST-only Apex REST endpoint that routes to
-- admin-configured inbound (External-ID upsert) or outbound (named SOQL read) integration
-- settings. Not a data record." It declares eight fields (Name, Authentication Key, Parameters,
-- InboundRecords, Records, RecordCount, Message, InboundResults) that describe a REQUEST/RESPONSE
-- envelope, none of which is a record key, because there is no record. It cannot be given a
-- primary key honestly and it should not be offered in the picker as a table to sync.
--
-- An Active keyless object either costs the soft-PK classifier a per-tenant inference at every
-- discovery or lands `entity.skipped-no-pk` while still being offered. A Disabled object is
-- neither inferred against nor offered (the engine filters to Status = Active). Disabled is the
-- fleet convention (132 objects across other connectors) and an allowed CK_IntegrationObject_Status
-- value. The Nimble discovery path is unaffected: live Salesforce describe still returns every
-- object in the Nimble namespace, and which tables to sync remains the customer's decision.
--
-- This is the connector-side half of the read-only primary-key gate (scripts/lint-writable-pk.mjs,
-- read-only scope), which exempts non-Active objects for exactly this reason.
--
-- Delta migration: one UPDATE by the object's seeded ID, hardcoded in
-- V202606271410__nimble-ams__Metadata.sql and therefore identical on every tenant. Re-running is a
-- no-op. Audit columns are not set.

UPDATE [__mj].[IntegrationObject]
SET [Status] = 'Disabled'
WHERE [ID] IN (
    '7CD81FDB-379F-40D0-81A0-083DD02E03CA'
);
