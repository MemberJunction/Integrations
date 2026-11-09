import type { PiiClass } from './pii/policy.js';

/**
 * The declared object catalog — the single source for `DiscoverObjects` / `DiscoverFields`, for the
 * personal-data policy the connector applies to every emitted field, and for the mj-sync metadata
 * under `metadata/integration/` (generated from this file by `scripts/build-metadata.mjs`; a test
 * asserts the two never drift).
 *
 * Everything here is PROVEN from the Data Feeds client contract (the client's `customers` and `soap`
 * modules), which is itself a decode of the .NET `Spektrix.DataFeeds.Data` types the service streams.
 * Nothing is inferred from tenant data.
 */

export type CatalogFieldType = 'string' | 'integer' | 'datetime' | 'boolean' | 'json';

export interface CatalogField {
    name: string;
    displayName: string;
    description: string;
    type: CatalogFieldType;
    pii: PiiClass;
    isPrimaryKey?: boolean;
    allowsNull: boolean;
    length?: number;
}

export type CatalogSyncStrategy = 'WatermarkIncremental' | 'FullPullHashDiff';

export interface CatalogObject {
    name: string;
    displayName: string;
    description: string;
    category: string;
    /** The service operation (and response part) the rows come from. There are no REST paths. */
    apiPath: string;
    syncStrategy: CatalogSyncStrategy;
    incrementalWatermarkField: string | null;
    stableOrderingKey: string | null;
    fields: CatalogField[];
}

const OPERATION = 'IDataFeed/GetCustomerData';

const id = (description: string): CatalogField => ({
    name: 'id', displayName: 'Id', description, type: 'integer', pii: 'identifier', isPrimaryKey: true, allowsNull: false,
});

export const CUSTOMER_OBJECT = 'Customer';
export const TAG_OBJECT = 'Tag';
export const TAG_GROUP_OBJECT = 'TagGroup';
export const CUSTOMER_MERGE_OBJECT = 'CustomerMerge';
export const DATA_PROTECTION_STATEMENT_OBJECT = 'DataProtectionStatement';

export const CATALOG: readonly CatalogObject[] = [
    {
        name: CUSTOMER_OBJECT,
        displayName: 'Customer',
        description:
            'A Spektrix customer record (Person or Organisation) from the Data Feeds customer stream. One row per customer; ' +
            'the `type` column tells the two apart and the address columns come from Person.BillingAddress or ' +
            'Organisation.PrimaryAddress. Read incrementally by last-updated date window.',
        category: 'Customers',
        apiPath: `${OPERATION}#customers`,
        syncStrategy: 'WatermarkIncremental',
        incrementalWatermarkField: 'dateLastUpdated',
        stableOrderingKey: 'id',
        fields: [
            id('Spektrix customer id (Spektrix.DataFeeds.Data.Customer.Id).'),
            { name: 'type', displayName: 'Type', description: "'Person' or 'Organisation' — the .NET record type streamed.", type: 'string', pii: 'label', allowsNull: false, length: 20 },
            { name: 'friendlyId', displayName: 'Friendly Id', description: 'Customer-facing reference (FriendlyId).', type: 'string', pii: 'reference', allowsNull: true, length: 50 },
            { name: 'email', displayName: 'Email', description: 'Email address.', type: 'string', pii: 'email', allowsNull: true, length: 320 },
            { name: 'phoneNumber', displayName: 'Phone Number', description: 'Main phone number.', type: 'string', pii: 'phone', allowsNull: true, length: 50 },
            { name: 'mobileNumber', displayName: 'Mobile Number', description: 'Mobile number (Person only).', type: 'string', pii: 'phone', allowsNull: true, length: 50 },
            { name: 'title', displayName: 'Title', description: 'Salutation (Person only).', type: 'string', pii: 'title', allowsNull: true, length: 50 },
            { name: 'firstName', displayName: 'First Name', description: 'First name (Person only).', type: 'string', pii: 'personName', allowsNull: true, length: 200 },
            { name: 'lastName', displayName: 'Last Name', description: 'Last name (Person only).', type: 'string', pii: 'personName', allowsNull: true, length: 200 },
            { name: 'birthDate', displayName: 'Birth Date', description: 'Date of birth (Person only), .NET round-trip format.', type: 'datetime', pii: 'birthDate', allowsNull: true },
            { name: 'organisationName', displayName: 'Organisation Name', description: 'Organisation name (Organisation only; wire Name).', type: 'string', pii: 'organisationName', allowsNull: true, length: 400 },
            { name: 'primaryContactId', displayName: 'Primary Contact Id', description: 'Customer id of the primary contact (Organisation only).', type: 'integer', pii: 'identifier', allowsNull: true },
            { name: 'address_name', displayName: 'Address Name', description: 'Addressee name on the address.', type: 'string', pii: 'addressLine', allowsNull: true, length: 400 },
            { name: 'address_line1', displayName: 'Address Line 1', description: 'Address line 1.', type: 'string', pii: 'addressLine', allowsNull: true, length: 400 },
            { name: 'address_line2', displayName: 'Address Line 2', description: 'Address line 2.', type: 'string', pii: 'addressLine', allowsNull: true, length: 400 },
            { name: 'address_line3', displayName: 'Address Line 3', description: 'Address line 3.', type: 'string', pii: 'addressLine', allowsNull: true, length: 400 },
            { name: 'address_line4', displayName: 'Address Line 4', description: 'Address line 4.', type: 'string', pii: 'addressLine', allowsNull: true, length: 400 },
            { name: 'address_line5', displayName: 'Address Line 5', description: 'Address line 5.', type: 'string', pii: 'addressLine', allowsNull: true, length: 400 },
            { name: 'address_town', displayName: 'Town', description: 'Town / city.', type: 'string', pii: 'geography', allowsNull: true, length: 200 },
            { name: 'address_county', displayName: 'County', description: 'County / state.', type: 'string', pii: 'geography', allowsNull: true, length: 200 },
            { name: 'address_postcode', displayName: 'Postcode', description: 'Postcode / ZIP (reduced to its first three characters when pseudonymized).', type: 'string', pii: 'postcode', allowsNull: true, length: 20 },
            { name: 'address_country', displayName: 'Country', description: 'Country.', type: 'string', pii: 'geography', allowsNull: true, length: 200 },
            { name: 'tagIds', displayName: 'Tag Ids', description: 'JSON array of tag ids applied to the customer (join to Tag.id).', type: 'json', pii: 'identifier', allowsNull: true },
            { name: 'agreedStatementIds', displayName: 'Agreed Statement Ids', description: 'JSON array of data-protection statement ids the customer agreed to (join to DataProtectionStatement.id).', type: 'json', pii: 'identifier', allowsNull: true },
            { name: 'attributes', displayName: 'Attributes', description: 'JSON array of {name, value} custom attributes. Values outside the connection allowlist are nulled in the protective modes.', type: 'json', pii: 'freeText', allowsNull: true },
            { name: 'dateCreated', displayName: 'Date Created', description: 'Record creation stamp, .NET round-trip format.', type: 'datetime', pii: 'timestamp', allowsNull: false },
            { name: 'dateLastUpdated', displayName: 'Date Last Updated', description: 'Last-updated stamp, .NET round-trip format. The incremental watermark field.', type: 'datetime', pii: 'timestamp', allowsNull: false },
        ],
    },
    {
        name: TAG_OBJECT,
        displayName: 'Tag',
        description: 'A customer tag, from the Tags list in the customer feed response header.',
        category: 'Tags',
        apiPath: `${OPERATION}#header/Tags`,
        syncStrategy: 'FullPullHashDiff',
        incrementalWatermarkField: null,
        stableOrderingKey: 'id',
        fields: [
            id('Spektrix tag id.'),
            { name: 'name', displayName: 'Name', description: 'Tag name.', type: 'string', pii: 'label', allowsNull: true, length: 400 },
            { name: 'tagGroupId', displayName: 'Tag Group Id', description: 'Owning tag group (join to TagGroup.id).', type: 'integer', pii: 'identifier', allowsNull: false },
        ],
    },
    {
        name: TAG_GROUP_OBJECT,
        displayName: 'Tag Group',
        description: 'A tag group, from the TagGroups list in the customer feed response header.',
        category: 'Tags',
        apiPath: `${OPERATION}#header/TagGroups`,
        syncStrategy: 'FullPullHashDiff',
        incrementalWatermarkField: null,
        stableOrderingKey: 'id',
        fields: [
            id('Spektrix tag group id.'),
            { name: 'name', displayName: 'Name', description: 'Tag group name.', type: 'string', pii: 'label', allowsNull: true, length: 400 },
        ],
    },
    {
        name: CUSTOMER_MERGE_OBJECT,
        displayName: 'Customer Merge',
        description:
            'A customer merge event (from-customer absorbed into to-customer on date), from the Merges list in the customer ' +
            'feed response header. Composite key from|to. Apply as a pointer, never as a delete.',
        category: 'Customers',
        apiPath: `${OPERATION}#header/Merges`,
        syncStrategy: 'FullPullHashDiff',
        incrementalWatermarkField: null,
        stableOrderingKey: null,
        fields: [
            { name: 'from', displayName: 'From Customer Id', description: 'The customer id that was merged away.', type: 'integer', pii: 'identifier', isPrimaryKey: true, allowsNull: false },
            { name: 'to', displayName: 'To Customer Id', description: 'The surviving customer id.', type: 'integer', pii: 'identifier', isPrimaryKey: true, allowsNull: false },
            { name: 'date', displayName: 'Merge Date', description: 'When the merge happened, .NET round-trip format.', type: 'datetime', pii: 'timestamp', allowsNull: false },
        ],
    },
    {
        name: DATA_PROTECTION_STATEMENT_OBJECT,
        displayName: 'Data Protection Statement',
        description: 'A consent statement customers can agree to, from the DataProtectionStatements list in the customer feed response header.',
        category: 'Statements',
        apiPath: `${OPERATION}#header/DataProtectionStatements`,
        syncStrategy: 'FullPullHashDiff',
        incrementalWatermarkField: null,
        stableOrderingKey: 'id',
        fields: [
            id('Spektrix data protection statement id.'),
            { name: 'name', displayName: 'Name', description: 'Statement name.', type: 'string', pii: 'label', allowsNull: true, length: 1000 },
        ],
    },
];

export function CatalogObjectByName(name: string): CatalogObject | undefined {
    return CATALOG.find((o) => o.name === name);
}

/** `{ fieldName: piiClass }` for one object — the input the anonymizer applies. */
export function PiiClassesFor(object: CatalogObject): Record<string, PiiClass> {
    return Object.fromEntries(object.fields.map((f) => [f.name, f.pii]));
}
