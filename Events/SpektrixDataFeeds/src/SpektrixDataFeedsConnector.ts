import { Metadata, type UserInfo } from '@memberjunction/core';
import type { MJCompanyIntegrationEntity, MJCredentialEntity } from '@memberjunction/core-entities';
import { RegisterClass } from '@memberjunction/global';
import {
    BaseIntegrationConnector,
    type ConnectionTestResult,
    type ExternalFieldSchema,
    type ExternalObjectSchema,
    type ExternalRecord,
    type FetchBatchResult,
    type FetchContext,
} from '@memberjunction/integration-engine';
import {
    CATALOG,
    CUSTOMER_MERGE_OBJECT,
    CUSTOMER_OBJECT,
    CatalogObjectByName,
    DATA_PROTECTION_STATEMENT_OBJECT,
    PiiClassesFor,
    TAG_GROUP_OBJECT,
    TAG_OBJECT,
    type CatalogObject,
} from './catalog.js';
import { ParseConnectionSettings, ParseJsonObject, ReadNonEmptyString, type ConnectionSettings, type CredentialValues } from './config.js';
import { GetSpektrixDataFeedClientFactory, NO_CLIENT_REGISTERED_MESSAGE } from './datafeeds/clientRegistry.js';
import type { CustomerDataFeed, DataFeedClient, DataFeedCustomer, DataFeedLookups } from './datafeeds/types.js';
import { AnonymizeRecord, FlattenCustomer } from './pii/anonymize.js';
import { PII_MODES } from './pii/policy.js';
import { Pseudonymizer } from './pii/pseudonymizer.js';
import { DecodeCursor, DecodeWatermark, EncodeCursor, EncodeWatermark, ParseDotNetDateTime, PlanWindow } from './watermark.js';

/**
 * Engine surface that exists from MJ 6.x but not in the 5.46 types this repo builds against. Read
 * through these so the same source compiles and behaves on both.
 */
type FetchContextCompat = FetchContext & { IsDiscoverySample?: boolean; SampleTargetRecords?: number };

/** Mirrors `ConnectorSettingDescriptor` in `@memberjunction/integration-engine` ≥ 6.x (not exported by 5.46). */
export interface SpektrixDataFeedsSettingDescriptor {
    Key: string;
    Label: string;
    Group: string;
    Type: 'number' | 'boolean' | 'string' | 'enum';
    Options?: string[];
    Default?: string | number | boolean | null;
    Min?: number;
    Max?: number;
    Tier: 'basic' | 'advanced' | 'expert';
    AppliesTo: 'connection' | 'object';
    Description: string;
    Sensitive: boolean;
}

/** A resolved, ready-to-call client for one connection, with the policy inputs that go with it. */
interface ResolvedConnection {
    client: DataFeedClient;
    settings: ConnectionSettings;
    pseudonymizer: Pseudonymizer | undefined;
}

const TWO_HOURS_MS = 2 * 60 * 60 * 1000;
const HEADER_ONLY_WINDOW_MS = 60 * 1000;
const SAMPLE_LOOKBACK_MS = 30 * 24 * 60 * 60 * 1000;

/**
 * Spektrix Data Feeds connector — the customer side of Spektrix that the v3 REST API does not expose
 * in bulk. Reads `IDataFeed.GetCustomerData` in date windows through a host-registered client (see
 * `datafeeds/clientRegistry.ts`), flattens each customer to one row, and applies the connection's
 * personal-data policy (`piiMode`) BEFORE a record exists anywhere the engine can see it: the
 * overflow column, the last-synced snapshot, the content hash and the field maps all read the output
 * of {@link FetchChanges}, so this class is the single choke point for what lands.
 *
 * Read-only by design: the service has no write operations.
 */
@RegisterClass(BaseIntegrationConnector, 'SpektrixDataFeedsConnector')
export class SpektrixDataFeedsConnector extends BaseIntegrationConnector {
    /** Rows of the window currently being paged out, keyed by connection + window. One window per connection at a time. */
    private readonly windowBuffers = new Map<string, ExternalRecord[]>();
    /** Header lists from the most recent feed call, reused by the lookup objects for `lookupCacheMs`. */
    private readonly lookupCache = new Map<string, { at: number; lookups: DataFeedLookups }>();

    public override get IntegrationName(): string {
        return 'Spektrix Data Feeds';
    }
    public override get SupportsCreate(): boolean {
        return false;
    }
    public override get SupportsUpdate(): boolean {
        return false;
    }
    public override get SupportsDelete(): boolean {
        return false;
    }
    /** Our watermark is the window end we chose, in our own format — strictly monotonic, so the engine must save it as-is. */
    public override get MonotonicWatermark(): boolean {
        return true;
    }
    /** The feed enumerates nothing about the catalog; absence from a window proves nothing. Never deactivate. */
    public override get DiscoveryIsAuthoritative(): boolean {
        return false;
    }
    /** One feed call in flight: the service prepares a whole window before sending a byte. */
    public override get MaxConcurrencyHint(): number | null {
        return 1;
    }
    /** Present on the base class from MJ 6.x; a plain getter so 5.46 compiles too. */
    public get FetchChangesTimeoutMs(): number | null {
        return TWO_HOURS_MS;
    }

    /** The base getter exists from MJ 6.x; on 5.46 it is absent and only this connector's settings are returned. */
    public get SettingsSchema(): SpektrixDataFeedsSettingDescriptor[] {
        const inherited: unknown = Reflect.get(BaseIntegrationConnector.prototype, 'SettingsSchema', this);
        const base = Array.isArray(inherited) ? (inherited as SpektrixDataFeedsSettingDescriptor[]) : [];
        return [...base, ...SPEKTRIX_DATA_FEEDS_SETTINGS];
    }

    // ── Lifecycle ───────────────────────────────────────────────────────────────────────────────

    public async TestConnection(companyIntegration: MJCompanyIntegrationEntity, contextUser: UserInfo): Promise<ConnectionTestResult> {
        try {
            const { client, settings } = await this.resolveConnection(companyIntegration, contextUser);
            const feed = await this.requestFeed(client, settings, this.headerOnlyWindow());
            this.rememberLookups(companyIntegration.ID, feed);
            feed.close();
            return {
                Success: true,
                Message: `Connected to the Spektrix Data Feeds service (${feed.tags.length} tags, ${feed.tagGroups.length} tag groups, ${feed.dataProtectionStatements.length} statements visible).`,
            };
        } catch (err) {
            return { Success: false, Message: DescribeError(err) };
        }
    }

    public async DiscoverObjects(_companyIntegration: MJCompanyIntegrationEntity, _contextUser: UserInfo): Promise<ExternalObjectSchema[]> {
        return CATALOG.map((o) => ({
            Name: o.name,
            Label: o.displayName,
            Description: o.description,
            SupportsIncrementalSync: o.incrementalWatermarkField !== null,
            SupportsWrite: false,
        }));
    }

    public async DiscoverFields(_companyIntegration: MJCompanyIntegrationEntity, objectName: string, _contextUser: UserInfo): Promise<ExternalFieldSchema[]> {
        const object = this.requireObject(objectName);
        const pkCount = object.fields.filter((f) => f.isPrimaryKey).length;
        return object.fields.map((f) => ({
            Name: f.name,
            Label: f.displayName,
            Description: f.description,
            DataType: f.type,
            IsRequired: false,
            AllowsNull: f.allowsNull,
            IsPrimaryKey: f.isPrimaryKey === true,
            IsUniqueKey: f.isPrimaryKey === true && pkCount === 1,
            IsReadOnly: true,
            MaxLength: f.length ?? null,
        }));
    }

    public async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
        const object = this.requireObject(ctx.ObjectName);
        if (object.name === CUSTOMER_OBJECT) return this.fetchCustomers(ctx as FetchContextCompat, object);
        return this.fetchLookup(ctx, object);
    }


    // ── Customer stream (windowed, incremental) ─────────────────────────────────────────────────

    private async fetchCustomers(ctx: FetchContextCompat, object: CatalogObject): Promise<FetchBatchResult> {
        const settings = ParseConnectionSettings(ctx.CompanyIntegration.Configuration);
        const stored = DecodeWatermark(ctx.WatermarkValue);
        this.guardPiiMode(stored?.piiMode ?? null, settings);

        const now = this.CurrentTime();
        const cursor = DecodeCursor(ctx.CurrentCursor);
        let offset = 0;
        let window: { from: Date; to: Date } | null;
        if (cursor) {
            window = { from: new Date(cursor.from), to: new Date(cursor.to) };
            offset = cursor.offset;
        } else {
            const start = this.firstWindowStart(ctx, stored?.to ?? null, settings, now);
            window = PlanWindow(start, settings.windowDays, now);
            if (window === null) {
                // Nothing newer than the stored watermark can exist yet. Keep the watermark where it is.
                return { Records: [], HasMore: false, NewWatermarkValue: EncodeWatermark({ to: start.toISOString(), piiMode: settings.piiMode }) };
            }
        }

        const key = `${ctx.CompanyIntegration.ID}|${window.from.toISOString()}|${window.to.toISOString()}`;
        const buffer = this.windowBuffers.get(key) ?? (await this.loadWindow(ctx, object, settings, window, key));
        const slice = buffer.slice(offset, offset + Math.max(1, ctx.BatchSize));
        const next = offset + slice.length;
        const windowDone = next >= buffer.length || ctx.IsDiscoverySample === true;

        if (!windowDone) {
            return {
                Records: slice,
                HasMore: true,
                NextCursor: EncodeCursor({ from: window.from.toISOString(), to: window.to.toISOString(), offset: next }),
                // Mid-window the safe watermark is the window START: an interrupted run re-reads this window.
                NewWatermarkValue: EncodeWatermark({ to: window.from.toISOString(), piiMode: settings.piiMode }),
            };
        }

        this.windowBuffers.delete(key);
        const more = window.to.getTime() < now.getTime() && ctx.IsDiscoverySample !== true;
        const nextWindow = more ? PlanWindow(window.to, settings.windowDays, now) : null;
        return {
            Records: slice,
            HasMore: nextWindow !== null,
            NextCursor: nextWindow ? EncodeCursor({ from: nextWindow.from.toISOString(), to: nextWindow.to.toISOString(), offset: 0 }) : undefined,
            NewWatermarkValue: EncodeWatermark({ to: window.to.toISOString(), piiMode: settings.piiMode }),
        };
    }

    private firstWindowStart(ctx: FetchContextCompat, storedTo: string | null, settings: ConnectionSettings, now: Date): Date {
        if (ctx.IsDiscoverySample) return new Date(now.getTime() - SAMPLE_LOOKBACK_MS);
        const text = storedTo ?? settings.fetchWindowStart;
        const ms = Date.parse(text);
        if (Number.isNaN(ms)) throw new Error('fetchWindowStart must be an ISO-8601 date or date-time.');
        return new Date(ms);
    }

    private async loadWindow(
        ctx: FetchContextCompat,
        object: CatalogObject,
        settings: ConnectionSettings,
        window: { from: Date; to: Date },
        key: string,
    ): Promise<ExternalRecord[]> {
        const resolved = await this.resolveConnection(ctx.CompanyIntegration, ctx.ContextUser);
        const feed = await this.requestFeed(resolved.client, settings, window);
        this.rememberLookups(ctx.CompanyIntegration.ID, feed);
        const classes = PiiClassesFor(object);
        const limit = ctx.IsDiscoverySample ? Math.max(1, ctx.SampleTargetRecords ?? ctx.BatchSize) : Number.POSITIVE_INFINITY;
        const records: ExternalRecord[] = [];
        try {
            for await (const customer of feed.customers) {
                records.push(this.toCustomerRecord(customer, classes, resolved));
                if (records.length >= limit) break;
            }
        } finally {
            feed.close();
        }
        this.windowBuffers.set(key, records);
        return records;
    }

    private toCustomerRecord(customer: DataFeedCustomer, classes: ReturnType<typeof PiiClassesFor>, resolved: ResolvedConnection): ExternalRecord {
        const fields = AnonymizeRecord(FlattenCustomer(customer), classes, {
            mode: resolved.settings.piiMode,
            pseudonymizer: resolved.pseudonymizer,
            attributeAllowlist: resolved.settings.piiAttributeAllowlist,
            nameSeed: String(customer.id),
        });
        return {
            ExternalID: String(customer.id),
            ObjectType: CUSTOMER_OBJECT,
            Fields: fields,
            ModifiedAt: ParseDotNetDateTime(customer.dateLastUpdated),
            IsDeleted: false,
        };
    }

    private guardPiiMode(storedMode: string | null, settings: ConnectionSettings): void {
        if (storedMode && storedMode !== settings.piiMode && !settings.allowPiiModeChange) {
            throw new Error(
                `piiMode changed from '${storedMode}' to '${settings.piiMode}' since the last sync. Rows of both shapes would share one table. ` +
                    'Clear the watermark and resync in full, or set allowPiiModeChange: true to accept that.',
            );
        }
    }

    // ── Header lists (Tag, TagGroup, CustomerMerge, DataProtectionStatement) ────────────────────

    private async fetchLookup(ctx: FetchContext, object: CatalogObject): Promise<FetchBatchResult> {
        const lookups = await this.getLookups(ctx.CompanyIntegration, ctx.ContextUser);
        const row = (id: string, fields: Record<string, unknown>, modifiedAt?: Date): ExternalRecord => ({
            ExternalID: id,
            ObjectType: object.name,
            Fields: fields,
            ModifiedAt: modifiedAt,
            IsDeleted: false,
        });
        let records: ExternalRecord[];
        switch (object.name) {
            case TAG_OBJECT:
                records = lookups.tags.map((t) => row(String(t.id), { id: t.id, name: t.name, tagGroupId: t.tagGroupId }));
                break;
            case TAG_GROUP_OBJECT:
                records = lookups.tagGroups.map((g) => row(String(g.id), { id: g.id, name: g.name }));
                break;
            case DATA_PROTECTION_STATEMENT_OBJECT:
                records = lookups.dataProtectionStatements.map((s) => row(String(s.id), { id: s.id, name: s.name }));
                break;
            case CUSTOMER_MERGE_OBJECT:
                records = lookups.merges.map((m) => row(`${m.from}|${m.to}`, { from: m.from, to: m.to, date: m.date }, ParseDotNetDateTime(m.date)));
                break;
            default:
                throw new Error(`Object '${object.name}' is not a header list.`);
        }
        return { Records: records, HasMore: false };
    }

    private async getLookups(companyIntegration: MJCompanyIntegrationEntity, contextUser: UserInfo): Promise<DataFeedLookups> {
        const settings = ParseConnectionSettings(companyIntegration.Configuration);
        const cached = this.lookupCache.get(companyIntegration.ID);
        if (cached && this.CurrentTime().getTime() - cached.at <= settings.lookupCacheMs) return cached.lookups;
        const { client } = await this.resolveConnection(companyIntegration, contextUser);
        const feed = await this.requestFeed(client, settings, this.headerOnlyWindow());
        try {
            return this.rememberLookups(companyIntegration.ID, feed);
        } finally {
            feed.close();
        }
    }

    private rememberLookups(companyIntegrationID: string, feed: CustomerDataFeed): DataFeedLookups {
        const lookups: DataFeedLookups = {
            tags: feed.tags,
            tagGroups: feed.tagGroups,
            merges: feed.merges,
            dataProtectionStatements: feed.dataProtectionStatements,
        };
        this.lookupCache.set(companyIntegrationID, { at: this.CurrentTime().getTime(), lookups });
        return lookups;
    }

    // ── Client + credentials ───────────────────────────────────────────────────────────────────

    private async resolveConnection(companyIntegration: MJCompanyIntegrationEntity, contextUser: UserInfo): Promise<ResolvedConnection> {
        const factory = GetSpektrixDataFeedClientFactory();
        if (!factory) throw new Error(NO_CLIENT_REGISTERED_MESSAGE);
        const settings = ParseConnectionSettings(companyIntegration.Configuration);
        const credential = await this.LoadCredentialValues(companyIntegration, contextUser);

        const clientName = credential.ClientName ?? settings.ClientName;
        if (!clientName) throw new Error('ClientName is missing: set it on the credential or the connection configuration.');
        if (!credential.CertificatePfxBase64) throw new Error('CertificatePfxBase64 is missing from the credential.');
        const pfx = DecodeBase64Strict(credential.CertificatePfxBase64, 'CertificatePfxBase64');

        let pseudonymizer: Pseudonymizer | undefined;
        if (settings.piiMode === 'pseudonymize') {
            if (!credential.PseudonymKey) throw new Error("PseudonymKey is missing from the credential; it is required while piiMode is 'pseudonymize'.");
            pseudonymizer = new Pseudonymizer(credential.PseudonymKey);
        }

        const client = factory({
            clientName,
            pfx,
            passphrase: credential.CertificatePassphrase,
            endpoint: credential.Endpoint ?? settings.Endpoint,
            idleTimeoutMs: settings.idleTimeoutMs,
        });
        return { client, settings, pseudonymizer };
    }

    /**
     * Secrets come ONLY from the connection's `MJ: Credentials` record; `ClientName` and `Endpoint` may
     * fall back to the connection configuration. Nothing read here is ever logged. Protected so tests
     * substitute values without a database.
     */
    protected async LoadCredentialValues(companyIntegration: MJCompanyIntegrationEntity, contextUser: UserInfo): Promise<CredentialValues> {
        let values: Record<string, unknown> | null = null;
        if (companyIntegration.CredentialID) {
            const credential = await new Metadata().GetEntityObject<MJCredentialEntity>('MJ: Credentials', contextUser);
            if (await credential.Load(companyIntegration.CredentialID)) values = ParseJsonObject(credential.Values);
        }
        const config = ParseJsonObject(companyIntegration.Configuration);
        return {
            ClientName: ReadNonEmptyString(values, 'ClientName') ?? ReadNonEmptyString(config, 'ClientName'),
            CertificatePfxBase64: ReadNonEmptyString(values, 'CertificatePfxBase64'),
            CertificatePassphrase: ReadNonEmptyString(values, 'CertificatePassphrase'),
            PseudonymKey: ReadNonEmptyString(values, 'PseudonymKey'),
            Endpoint: ReadNonEmptyString(values, 'Endpoint') ?? ReadNonEmptyString(config, 'Endpoint'),
        };
    }

    private async requestFeed(client: DataFeedClient, settings: ConnectionSettings, window: { from: Date; to: Date }): Promise<CustomerDataFeed> {
        return client.getCustomerData({ from: window.from, to: window.to }, { signal: AbortSignal.timeout(settings.requestTimeoutMs) });
    }

    /** A one-minute window ending now: enough to receive the header lists without a meaningful customer stream. */
    private headerOnlyWindow(): { from: Date; to: Date } {
        const now = this.CurrentTime();
        return { from: new Date(now.getTime() - HEADER_ONLY_WINDOW_MS), to: now };
    }

    private requireObject(name: string): CatalogObject {
        const object = CatalogObjectByName(name);
        if (!object) throw new Error(`Unknown Spektrix Data Feeds object '${name}'.`);
        return object;
    }

    /** The clock. Isolated so tests plan windows deterministically. */
    protected CurrentTime(): Date {
        return new Date();
    }
}

/** Fixed message text only — never a value from the credential, the configuration or the vendor body. */
export function DescribeError(err: unknown): string {
    if (!(err instanceof Error)) return 'Unknown error.';
    const faultCode = (err as { faultCode?: unknown }).faultCode;
    if (typeof faultCode === 'string') return `The Spektrix Data Feeds service returned a SOAP fault (${faultCode}).`;
    switch (err.name) {
        case 'ClientCertificateError':
            return 'The client certificate could not be opened. Check the passphrase, and re-export the pfx with AES-256 if it is an older RC2/3DES export.';
        case 'DataFeedResponseError':
            return 'The endpoint did not return a Spektrix data feed response.';
        case 'AbortError':
        case 'TimeoutError':
            return 'The Spektrix Data Feeds service did not answer within the configured timeout.';
        default:
            return err.message;
    }
}

export function DecodeBase64Strict(value: string, label: string): Buffer {
    const compact = value.replace(/\s+/g, '');
    if (compact === '' || !/^[A-Za-z0-9+/]+={0,2}$/.test(compact) || compact.length % 4 !== 0) {
        throw new Error(`${label} is not valid base-64.`);
    }
    return Buffer.from(compact, 'base64');
}

const SPEKTRIX_DATA_FEEDS_SETTINGS: readonly SpektrixDataFeedsSettingDescriptor[] = [
    {
        Key: 'piiMode',
        Label: 'Personal data mode',
        Group: 'Personal data',
        Type: 'enum',
        Options: [...PII_MODES],
        Default: 'pseudonymize',
        Tier: 'basic',
        AppliesTo: 'connection',
        Description:
            "raw lands values unchanged; pseudonymize replaces personal values with keyed, deterministic tokens (needs the credential's PseudonymKey); suppress nulls them. Changing the mode requires a full resync.",
        Sensitive: false,
    },
    {
        Key: 'piiAttributeAllowlist',
        Label: 'Attribute names kept',
        Group: 'Personal data',
        Type: 'string',
        Default: '',
        Tier: 'advanced',
        AppliesTo: 'connection',
        Description: 'Comma-separated custom attribute names whose values survive pseudonymize and suppress. Everything else is nulled.',
        Sensitive: false,
    },
    {
        Key: 'allowPiiModeChange',
        Label: 'Allow mode change without resync',
        Group: 'Personal data',
        Type: 'boolean',
        Default: false,
        Tier: 'expert',
        AppliesTo: 'connection',
        Description: 'Lets a sync continue after piiMode changed, mixing row shapes in one table. Leave off.',
        Sensitive: false,
    },
    {
        Key: 'fetchWindowStart',
        Label: 'First window start',
        Group: 'Windows',
        Type: 'string',
        Default: '2000-01-01T00:00:00Z',
        Tier: 'advanced',
        AppliesTo: 'connection',
        Description: 'ISO date the first sync starts from when no watermark exists.',
        Sensitive: false,
    },
    {
        Key: 'windowDays',
        Label: 'Window width (days)',
        Group: 'Windows',
        Type: 'number',
        Default: 30,
        Min: 1,
        Max: 3660,
        Tier: 'advanced',
        AppliesTo: 'connection',
        Description: 'Days per GetCustomerData request. The service prepares the whole window before sending; wider windows mean fewer, longer calls.',
        Sensitive: false,
    },
    {
        Key: 'idleTimeoutMs',
        Label: 'Idle timeout (ms)',
        Group: 'Windows',
        Type: 'number',
        Default: 3600000,
        Min: 1000,
        Tier: 'expert',
        AppliesTo: 'connection',
        Description: 'Drop the connection after this long with no bytes received.',
        Sensitive: false,
    },
    {
        Key: 'requestTimeoutMs',
        Label: 'Request timeout (ms)',
        Group: 'Windows',
        Type: 'number',
        Default: 7200000,
        Min: 1000,
        Tier: 'expert',
        AppliesTo: 'connection',
        Description: 'Overall ceiling for one window request, preparation and streaming included.',
        Sensitive: false,
    },
    {
        Key: 'lookupCacheMs',
        Label: 'Header list cache (ms)',
        Group: 'Windows',
        Type: 'number',
        Default: 600000,
        Min: 0,
        Tier: 'expert',
        AppliesTo: 'connection',
        Description: 'How long the tag, tag group, merge and statement lists from the last call serve the lookup objects before a fresh header-only call.',
        Sensitive: false,
    },
];
