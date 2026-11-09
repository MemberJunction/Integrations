#!/usr/bin/env node
/**
 * Generates metadata/integration/.spektrix-data-feeds.integration.json from the compiled catalog
 * (dist/catalog.js), so DiscoverObjects/DiscoverFields, the PII policy and the mj-sync seed can never
 * drift. IDs are UUIDv5 of a fixed namespace + the object/field path, so re-running yields the same
 * IDs and the seed migration stays deterministic.
 *
 *   npm run build && node scripts/build-metadata.mjs
 */
import { createHash } from 'node:crypto';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { CATALOG } from '../dist/catalog.js';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const NAMESPACE = '7c9e6679-7425-40de-944b-e07fc1f90ae7'; // fixed, never change: it pins every ID below
const INTEGRATION_NAME = 'Spektrix Data Feeds';

function uuid5(name) {
    const ns = Buffer.from(NAMESPACE.replace(/-/g, ''), 'hex');
    const hash = createHash('sha1').update(Buffer.concat([ns, Buffer.from(name, 'utf8')])).digest();
    hash[6] = (hash[6] & 0x0f) | 0x50;
    hash[8] = (hash[8] & 0x3f) | 0x80;
    const hex = hash.subarray(0, 16).toString('hex').toUpperCase();
    return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

const integration = {
    fields: {
        Name: INTEGRATION_NAME,
        ClassName: 'SpektrixDataFeedsConnector',
        ImportPath: '@memberjunction/connector-spektrix-data-feeds',
        Description:
            'Spektrix Data Feeds — the WCF customer feed (IDataFeed.GetCustomerData) that carries the bulk customer base the v3 REST API does not expose. ' +
            'Read-only, windowed by last-updated date, with a per-connection personal-data policy (raw / pseudonymize / suppress) applied before any row lands.',
        Icon: 'fa-solid fa-file-shield',
        CredentialTypeID: '@lookup:MJ: Credential Types.Name=Spektrix Data Feeds Certificate',
        Configuration: {
            Transport: 'SOAP 1.1 over MTOM (multipart/related) to https://api.system.spektrix.com/{ClientName}/api/datafeeds/datafeeds.svc; customer records are a length-framed .NET BinaryFormatter (MS-NRBF) stream.',
            TransportClient: 'Integrator-supplied streaming Node client for the Data Feeds protocol, registered by the host via RegisterSpektrixDataFeedClientFactory; this package never imports it.',
            AuthScheme: 'TLS client certificate (PKCS#12). The certificate is issued per integrator and may grant access to many Spektrix systems; it must stay where its holder runs the client.',
            OperationsInScope: ['IDataFeed.GetCustomerData'],
            OperationsKnownOutOfScope: [
                { operation: 'IDataFeed ticket feed (TicketData service wrapper)', reason: 'not yet covered by the TypeScript client; sales rows wait on it' },
                { operation: 'IDataFeed event feed (EventData service wrapper)', reason: 'catalogue data already covered by the Spektrix v3 connector' },
            ],
            IncrementalSyncCapability: 'GetCustomerData takes From/To and returns customers whose DateLastUpdated falls in the range; the connector walks date windows and stores the window end as the watermark.',
            PaginationCapability: 'None at the service; the connector pages a buffered window by cursor.',
            RateLimits: { documentedNumbers: null, guidance: 'One request in flight; the service prepares the whole window before sending the first byte, which can take minutes.' },
            DeleteSemantics: 'No deletion feed. Customer merges arrive as (from, to, date) pointers and are kept as rows, never applied as deletes.',
            WriteCapability: 'None.',
            DiscoveryIsAuthoritative: false,
            PersonalDataPolicy: {
                setting: 'CompanyIntegration.Configuration.piiMode',
                modes: ['raw', 'pseudonymize', 'suppress'],
                default: 'pseudonymize',
                appliedAt: 'FetchChanges, before the record reaches the engine (overflow, snapshot, content hash and field maps all see the policy output)',
                perFieldClass: 'IntegrationObjectField.Configuration.pii',
                watermarkCarriesMode: true,
            },
            DeclaredAgainst: 'Data Feeds client types 0.1.0 (2026-11-03), decoding Spektrix.DataFeeds.Data.Person / Organisation / Address / Attribute',
        },
    },
    relatedEntities: {
        'MJ: Integration Objects': CATALOG.map((o, index) => ({
            fields: {
                Name: o.name,
                DisplayName: o.displayName,
                Description: o.description,
                APIPath: o.apiPath,
                Category: o.category,
                Status: 'Active',
                Sequence: index + 1,
                PaginationType: 'None',
                SupportsPagination: false,
                SupportsIncrementalSync: o.incrementalWatermarkField !== null,
                IncrementalWatermarkField: o.incrementalWatermarkField,
                SyncStrategy: o.syncStrategy,
                StableOrderingKey: o.stableOrderingKey,
                ContentHashApplicable: true,
                SupportsWrite: false,
                SupportsCreate: false,
                SupportsUpdate: false,
                SupportsDelete: false,
                IsCustom: false,
                MetadataSource: 'Declared',
                Configuration: {
                    operation: 'IDataFeed.GetCustomerData',
                    pk: {
                        fields: o.fields.filter((f) => f.isPrimaryKey).map((f) => f.name),
                        soft: true,
                        basis: 'documented identity in Spektrix.DataFeeds.Data; composite keys are |-joined in field order',
                    },
                    piiClasses: Object.fromEntries(o.fields.map((f) => [f.name, f.pii])),
                },
                IntegrationID: '@parent:ID',
            },
            relatedEntities: {
                'MJ: Integration Object Fields': o.fields.map((f, fi) => ({
                    fields: {
                        Name: f.name,
                        DisplayName: f.displayName,
                        Description: f.description,
                        Type: f.type,
                        Category: f.isPrimaryKey ? 'Identifier' : null,
                        Length: f.length ?? null,
                        Precision: null,
                        Scale: null,
                        AllowsNull: f.allowsNull,
                        DefaultValue: null,
                        IsPrimaryKey: f.isPrimaryKey === true,
                        IsUniqueKey: f.isPrimaryKey === true && o.fields.filter((x) => x.isPrimaryKey).length === 1,
                        IsRequired: false,
                        IsReadOnly: true,
                        Sequence: fi + 1,
                        Configuration: { pii: f.pii, specType: f.type, source: 'Spektrix.DataFeeds.Data via the Data Feeds client' },
                        Status: 'Active',
                        IsCustom: false,
                        MetadataSource: 'Declared',
                        IntegrationObjectID: '@parent:ID',
                    },
                    primaryKey: { ID: uuid5(`${INTEGRATION_NAME}/${o.name}/${f.name}`) },
                })),
            },
            primaryKey: { ID: uuid5(`${INTEGRATION_NAME}/${o.name}`) },
        })),
    },
    primaryKey: { ID: uuid5(INTEGRATION_NAME) },
};

const out = join(ROOT, 'metadata', 'integration', '.spektrix-data-feeds.integration.json');
mkdirSync(dirname(out), { recursive: true });
writeFileSync(out, JSON.stringify([integration], null, 2) + '\n');
console.log(`wrote ${out}: ${CATALOG.length} objects, ${CATALOG.reduce((n, o) => n + o.fields.length, 0)} fields`);
