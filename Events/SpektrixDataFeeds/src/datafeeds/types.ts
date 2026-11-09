/**
 * The port this connector reads the Spektrix Data Feeds service through.
 *
 * The shapes below are STRUCTURAL copies of the public API of the integrator-supplied streaming Node
 * client for the WCF `IDataFeed.GetCustomerData` operation, so an instance of that client's
 * `SpektrixDataFeedClient` satisfies {@link DataFeedClient} with no adapter. That client is not published,
 * and the certificate that authenticates it cannot leave its holder's servers, so this connector never
 * imports it: the HOST registers a factory at boot (see `clientRegistry.ts`) wherever the certificate lives.
 */

/** A .NET DateTime in round-trip format, e.g. `2026-06-30T12:00:00.0000000`; ends in `Z` only when UTC. */
export type DotNetDateTime = string;

export interface DataFeedAddress {
    country: string | null;
    county: string | null;
    line1: string | null;
    line2: string | null;
    line3: string | null;
    line4: string | null;
    line5: string | null;
    name: string | null;
    postcode: string | null;
    town: string | null;
}

export interface DataFeedCustomerAttribute {
    name: string | null;
    value: string | null;
}

interface DataFeedCustomerBase {
    id: number;
    friendlyId: string | null;
    email: string | null;
    phoneNumber: string | null;
    dateCreated: DotNetDateTime;
    dateLastUpdated: DotNetDateTime;
    agreedStatementIds: number[] | null;
    tagIds: number[] | null;
    attributes: DataFeedCustomerAttribute[] | null;
}

export interface DataFeedPerson extends DataFeedCustomerBase {
    type: 'Person';
    billingAddress: DataFeedAddress | null;
    birthDate: DotNetDateTime | null;
    firstName: string | null;
    lastName: string | null;
    mobileNumber: string | null;
    title: string | null;
}

export interface DataFeedOrganisation extends DataFeedCustomerBase {
    type: 'Organisation';
    primaryAddress: DataFeedAddress | null;
    name: string | null;
    primaryContactId: number | null;
}

export type DataFeedCustomer = DataFeedPerson | DataFeedOrganisation;

export interface DataFeedTag {
    id: number;
    name: string | null;
    tagGroupId: number;
}

export interface DataFeedTagGroup {
    id: number;
    name: string | null;
}

export interface DataFeedCustomerMerge {
    date: DotNetDateTime;
    from: number;
    to: number;
}

export interface DataFeedDataProtectionStatement {
    id: number;
    name: string | null;
}

/** The lists the service sends in the response header alongside the customer stream. */
export interface DataFeedLookups {
    dataProtectionStatements: DataFeedDataProtectionStatement[];
    merges: DataFeedCustomerMerge[];
    tagGroups: DataFeedTagGroup[];
    tags: DataFeedTag[];
}

export interface CustomerDataFeed extends DataFeedLookups {
    /** Streams from the open connection. Iterate once. Order is not fixed; match by `id`. */
    customers: AsyncIterable<DataFeedCustomer>;
    /** Releases the connection. */
    close(): void;
}

export interface DataFeedDateRange {
    /** A Date is sent as UTC; a string is sent as written and must be an xs:dateTime. */
    from?: Date | string | null;
    to?: Date | string | null;
}

export interface DataFeedClient {
    getCustomerData(range?: DataFeedDateRange, options?: { signal?: AbortSignal }): Promise<CustomerDataFeed>;
}

export interface DataFeedClientOptions {
    /** The Spektrix client (system) name, as it appears in the system URL. */
    clientName: string;
    /** The client certificate and private key as PKCS#12 bytes. */
    pfx: Uint8Array;
    passphrase?: string;
    /** Replaces the production endpoint (test servers, replay harnesses). */
    endpoint?: string;
    /** Destroys the connection after this many ms with no data. Spektrix can take minutes to prepare a feed. */
    idleTimeoutMs?: number;
}

export type DataFeedClientFactory = (options: DataFeedClientOptions) => DataFeedClient;
