import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import type { UserInfo } from '@memberjunction/core';
import type { MJCompanyIntegrationEntity } from '@memberjunction/core-entities';
import type { FetchContext } from '@memberjunction/integration-engine';
import { CATALOG, CUSTOMER_MERGE_OBJECT, CUSTOMER_OBJECT, TAG_OBJECT } from '../catalog.js';
import type { CredentialValues } from '../config.js';
import { ClearSpektrixDataFeedClientFactory, RegisterSpektrixDataFeedClientFactory } from '../datafeeds/clientRegistry.js';
import type { CustomerDataFeed, DataFeedClientOptions, DataFeedCustomer, DataFeedDateRange, DataFeedLookups } from '../datafeeds/types.js';
import { DescribeError, SpektrixDataFeedsConnector } from '../SpektrixDataFeedsConnector.js';
import { DecodeCursor, DecodeWatermark, EncodeWatermark } from '../watermark.js';

const here = dirname(fileURLToPath(import.meta.url));
const FIXTURE = JSON.parse(readFileSync(join(here, 'fixtures', 'customers.synthetic.json'), 'utf8')) as {
    lookups: DataFeedLookups;
    customers: DataFeedCustomer[];
};

const NOW = new Date('2026-11-08T12:00:00.000Z');
const USER = {} as UserInfo;
const PFX_B64 = Buffer.from('not-a-real-pfx-only-bytes-for-the-test').toString('base64');

interface FeedCall {
    options: DataFeedClientOptions;
    range: DataFeedDateRange;
    closed: boolean;
}

/** A scripted stand-in for the Data Feeds client: returns the fixture for any window, records every call. */
function installFakeClient(customers: DataFeedCustomer[] = FIXTURE.customers, onCall?: (range: DataFeedDateRange) => void): FeedCall[] {
    const calls: FeedCall[] = [];
    RegisterSpektrixDataFeedClientFactory((options) => ({
        async getCustomerData(range: DataFeedDateRange = {}): Promise<CustomerDataFeed> {
            onCall?.(range);
            const call: FeedCall = { options, range, closed: false };
            calls.push(call);
            async function* stream(): AsyncGenerator<DataFeedCustomer> {
                for (const c of customers) yield c;
            }
            return { ...FIXTURE.lookups, customers: stream(), close: () => { call.closed = true; } };
        },
    }));
    return calls;
}

class TestConnector extends SpektrixDataFeedsConnector {
    public Credential: CredentialValues = {
        ClientName: 'exampletheatre',
        CertificatePfxBase64: PFX_B64,
        CertificatePassphrase: 'pfx-pass',
        PseudonymKey: 'unit-test-key-0123456789abcdef',
    };
    public Now = NOW;
    protected override async LoadCredentialValues(): Promise<CredentialValues> {
        return this.Credential;
    }
    protected override CurrentTime(): Date {
        return this.Now;
    }
}

function companyIntegration(config: Record<string, unknown> = {}, id = 'ci-1'): MJCompanyIntegrationEntity {
    const ci: Partial<MJCompanyIntegrationEntity> = { ID: id, CredentialID: null, Configuration: JSON.stringify(config) };
    return ci as MJCompanyIntegrationEntity;
}

type FetchContextCompat = FetchContext & { IsDiscoverySample?: boolean; SampleTargetRecords?: number };

function ctx(connector: TestConnector, objectName: string, overrides: Partial<FetchContextCompat> = {}, config: Record<string, unknown> = {}): FetchContextCompat {
    void connector;
    return {
        CompanyIntegration: companyIntegration(config),
        ObjectName: objectName,
        WatermarkValue: null,
        BatchSize: 100,
        ContextUser: USER,
        ...overrides,
    };
}

/** Drives FetchChanges to completion the way the engine does: feed NextCursor back until HasMore is false. */
async function drain(connector: TestConnector, first: FetchContext) {
    const batches = [];
    let cursor: string | undefined;
    let more = true;
    while (more) {
        const batch = await connector.FetchChanges({ ...first, CurrentCursor: cursor });
        batches.push(batch);
        cursor = batch.NextCursor;
        more = batch.HasMore;
        if (batches.length > 50) throw new Error('did not terminate');
    }
    return batches;
}

beforeEach(() => ClearSpektrixDataFeedClientFactory());
afterEach(() => ClearSpektrixDataFeedClientFactory());

describe('surface', () => {
    it('is read-only, monotonic-watermark, non-authoritative, single in flight', () => {
        const c = new TestConnector();
        expect(c.IntegrationName).toBe('Spektrix Data Feeds');
        expect(c.SupportsCreate).toBe(false);
        expect(c.SupportsUpdate).toBe(false);
        expect(c.SupportsDelete).toBe(false);
        expect(c.MonotonicWatermark).toBe(true);
        expect(c.DiscoveryIsAuthoritative).toBe(false);
        expect(c.MaxConcurrencyHint).toBe(1);
        expect(c.SettingsSchema.map((s) => s.Key)).toContain('piiMode');
    });

    it('discovers the declared catalog with its keys and types', async () => {
        const c = new TestConnector();
        const objects = await c.DiscoverObjects(companyIntegration(), USER);
        expect(objects.map((o) => o.Name)).toEqual(CATALOG.map((o) => o.name));
        expect(objects.find((o) => o.Name === CUSTOMER_OBJECT)!.SupportsIncrementalSync).toBe(true);
        expect(objects.find((o) => o.Name === TAG_OBJECT)!.SupportsIncrementalSync).toBe(false);
        const fields = await c.DiscoverFields(companyIntegration(), CUSTOMER_OBJECT, USER);
        const id = fields.find((f) => f.Name === 'id')!;
        expect(id.IsPrimaryKey).toBe(true);
        expect(id.IsUniqueKey).toBe(true);
        expect(id.DataType).toBe('integer');
        const mergeFields = await c.DiscoverFields(companyIntegration(), CUSTOMER_MERGE_OBJECT, USER);
        expect(mergeFields.filter((f) => f.IsPrimaryKey).map((f) => f.Name)).toEqual(['from', 'to']);
        expect(mergeFields.every((f) => !f.IsUniqueKey)).toBe(true);
    });
});

describe('TestConnection', () => {
    it('fails with a clear message when the host registered no client', async () => {
        const c = new TestConnector();
        const result = await c.TestConnection(companyIntegration(), USER);
        expect(result.Success).toBe(false);
        expect(result.Message).toMatch(/RegisterSpektrixDataFeedClientFactory/);
    });

    it('fails when the credential lacks the certificate, naming the field and never its value', async () => {
        installFakeClient();
        const c = new TestConnector();
        c.Credential = { ClientName: 'exampletheatre' };
        const result = await c.TestConnection(companyIntegration(), USER);
        expect(result.Success).toBe(false);
        expect(result.Message).toContain('CertificatePfxBase64');
    });

    it('fails when piiMode is pseudonymize and no key is set', async () => {
        installFakeClient();
        const c = new TestConnector();
        c.Credential = { ...c.Credential, PseudonymKey: undefined };
        const result = await c.TestConnection(companyIntegration(), USER);
        expect(result.Success).toBe(false);
        expect(result.Message).toContain('PseudonymKey');
    });

    it('requests a one-minute header-only window, closes the feed and reports the lists seen', async () => {
        const calls = installFakeClient();
        const c = new TestConnector();
        const result = await c.TestConnection(companyIntegration(), USER);
        expect(result.Success).toBe(true);
        expect(result.Message).toContain('3 tags');
        expect(calls).toHaveLength(1);
        expect(calls[0]!.closed).toBe(true);
        expect(calls[0]!.options.clientName).toBe('exampletheatre');
        expect(Buffer.from(calls[0]!.options.pfx).toString('base64')).toBe(PFX_B64);
        expect(calls[0]!.options.passphrase).toBe('pfx-pass');
        const { from, to } = calls[0]!.range as { from: Date; to: Date };
        expect(to.getTime()).toBe(NOW.getTime());
        expect(to.getTime() - from.getTime()).toBe(60_000);
    });

    it('describes a SOAP fault by code only', () => {
        const fault = Object.assign(new Error('Spektrix data feed fault a:AccessDenied: tenant xyz is not authorised'), { name: 'DataFeedFaultError', faultCode: 'a:AccessDenied' });
        expect(DescribeError(fault)).toBe('The Spektrix Data Feeds service returned a SOAP fault (a:AccessDenied).');
        expect(DescribeError(fault)).not.toContain('xyz');
    });
});

describe('FetchChanges — Customer', () => {
    it('walks windows from fetchWindowStart to now, pages each window by BatchSize, and ends on a window-end watermark that carries the mode', async () => {
        const calls = installFakeClient();
        const c = new TestConnector();
        const config = { fetchWindowStart: '2026-10-01T00:00:00Z', windowDays: 20 };
        const batches = await drain(c, ctx(c, CUSTOMER_OBJECT, { BatchSize: 2 }, config));

        // Two windows: 1–21 Oct and 21 Oct–8 Nov 12:00 (now). Three fixture rows per window at BatchSize 2 → 2 batches each.
        expect(calls).toHaveLength(2);
        expect((calls[0]!.range.from as Date).toISOString()).toBe('2026-10-01T00:00:00.000Z');
        expect((calls[0]!.range.to as Date).toISOString()).toBe('2026-10-21T00:00:00.000Z');
        expect((calls[1]!.range.from as Date).toISOString()).toBe('2026-10-21T00:00:00.000Z');
        expect((calls[1]!.range.to as Date).toISOString()).toBe(NOW.toISOString());
        expect(calls.every((k) => k.closed)).toBe(true);

        expect(batches).toHaveLength(4);
        expect(batches.map((b) => b.Records.length)).toEqual([2, 1, 2, 1]);
        const last = batches[batches.length - 1]!;
        expect(last.HasMore).toBe(false);
        expect(DecodeWatermark(last.NewWatermarkValue)).toEqual({ to: NOW.toISOString(), piiMode: 'pseudonymize' });
        // Mid-window the watermark offered is the window start, so an interrupted run re-reads the window.
        expect(DecodeWatermark(batches[0]!.NewWatermarkValue)!.to).toBe('2026-10-01T00:00:00.000Z');
        expect(DecodeCursor(batches[0]!.NextCursor)).toEqual({ from: '2026-10-01T00:00:00.000Z', to: '2026-10-21T00:00:00.000Z', offset: 2 });
    });

    it('resumes from the stored watermark and returns nothing when it is already at now', async () => {
        const calls = installFakeClient();
        const c = new TestConnector();
        const wm = EncodeWatermark({ to: NOW.toISOString(), piiMode: 'pseudonymize' });
        const batch = await c.FetchChanges(ctx(c, CUSTOMER_OBJECT, { WatermarkValue: wm }));
        expect(batch.Records).toEqual([]);
        expect(batch.HasMore).toBe(false);
        expect(batch.NewWatermarkValue).toBe(wm);
        expect(calls).toHaveLength(0);

        const earlier = EncodeWatermark({ to: '2026-11-01T00:00:00.000Z', piiMode: 'pseudonymize' });
        await drain(c, ctx(c, CUSTOMER_OBJECT, { WatermarkValue: earlier }));
        expect(calls).toHaveLength(1);
        expect((calls[0]!.range.from as Date).toISOString()).toBe('2026-11-01T00:00:00.000Z');
    });

    it('emits one pseudonymized row per customer with the Spektrix id as ExternalID and no raw personal value', async () => {
        installFakeClient();
        const c = new TestConnector();
        const [batch] = await drain(c, ctx(c, CUSTOMER_OBJECT, { WatermarkValue: EncodeWatermark({ to: '2026-11-08T00:00:00.000Z', piiMode: 'pseudonymize' }) }));
        expect(batch!.Records.map((r) => r.ExternalID)).toEqual(['1001', '1002', '2001']);
        expect(batch!.Records.every((r) => r.ObjectType === CUSTOMER_OBJECT)).toBe(true);
        const text = JSON.stringify(batch!.Records.map((r) => r.Fields));
        for (const marker of ['Zebediah', 'Fixturesmith', 'example.org', '206 000', 'Synthetic', '12345-6789']) expect(text).not.toContain(marker);
        expect(batch!.Records[0]!.Fields['email']).toMatch(/@example\.invalid$/);
        expect(batch!.Records[0]!.ModifiedAt?.toISOString()).toBe('2026-10-01T23:59:59.000Z');
    });

    it('lands raw values only when the connection says piiMode raw', async () => {
        installFakeClient();
        const c = new TestConnector();
        c.Credential = { ...c.Credential, PseudonymKey: undefined }; // raw needs no key
        const wm = EncodeWatermark({ to: '2026-11-08T00:00:00.000Z', piiMode: 'raw' });
        const [batch] = await drain(c, ctx(c, CUSTOMER_OBJECT, { WatermarkValue: wm }, { piiMode: 'raw' }));
        expect(batch!.Records[0]!.Fields['email']).toBe('Zebediah.Fixturesmith@Example.ORG');
    });

    it('refuses to continue under a different piiMode than the watermark was written with', async () => {
        installFakeClient();
        const c = new TestConnector();
        const wm = EncodeWatermark({ to: '2026-11-01T00:00:00.000Z', piiMode: 'raw' });
        await expect(c.FetchChanges(ctx(c, CUSTOMER_OBJECT, { WatermarkValue: wm }))).rejects.toThrow(/piiMode changed from 'raw' to 'pseudonymize'/);
        const batch = await c.FetchChanges(ctx(c, CUSTOMER_OBJECT, { WatermarkValue: wm }, { allowPiiModeChange: true }));
        expect(batch.Records.length).toBeGreaterThan(0);
    });

    it('samples a recent window and stops at the target during discovery', async () => {
        const calls = installFakeClient();
        const c = new TestConnector();
        const batch = await c.FetchChanges(ctx(c, CUSTOMER_OBJECT, { IsDiscoverySample: true, SampleTargetRecords: 2, BatchSize: 50 }));
        expect(batch.Records).toHaveLength(2);
        expect(batch.HasMore).toBe(false);
        const from = calls[0]!.range.from as Date;
        expect(NOW.getTime() - from.getTime()).toBe(30 * 24 * 60 * 60 * 1000);
    });
});

describe('FetchChanges — header lists', () => {
    it('serves Tag, TagGroup, CustomerMerge and DataProtectionStatement from one header-only call', async () => {
        const calls = installFakeClient();
        const c = new TestConnector();
        const tags = await c.FetchChanges(ctx(c, TAG_OBJECT));
        const groups = await c.FetchChanges(ctx(c, 'TagGroup'));
        const merges = await c.FetchChanges(ctx(c, CUSTOMER_MERGE_OBJECT));
        const statements = await c.FetchChanges(ctx(c, 'DataProtectionStatement'));
        expect(calls).toHaveLength(1);
        expect(calls[0]!.closed).toBe(true);
        expect(tags.Records.map((r) => r.ExternalID)).toEqual(['10', '20', '30']);
        expect(tags.Records[0]!.Fields).toEqual({ id: 10, name: 'Subscriber', tagGroupId: 1 });
        expect(groups.Records).toHaveLength(2);
        expect(merges.Records[0]!.ExternalID).toBe('1002|1001');
        expect(merges.Records[0]!.Fields).toEqual({ from: 1002, to: 1001, date: '2025-03-04T10:15:00.0000000' });
        expect(statements.Records.map((r) => r.Fields['name'])).toEqual(['Email marketing', 'Post']);
        for (const b of [tags, groups, merges, statements]) expect(b.HasMore).toBe(false);
    });

    it('re-reads the header once the cache has aged out', async () => {
        const calls = installFakeClient();
        const c = new TestConnector();
        await c.FetchChanges(ctx(c, TAG_OBJECT));
        c.Now = new Date(NOW.getTime() + 11 * 60 * 1000);
        await c.FetchChanges(ctx(c, TAG_OBJECT));
        expect(calls).toHaveLength(2);
    });

    it('reuses the header lists captured by a Customer window read', async () => {
        const calls = installFakeClient();
        const c = new TestConnector();
        await drain(c, ctx(c, CUSTOMER_OBJECT, { WatermarkValue: EncodeWatermark({ to: '2026-11-08T00:00:00.000Z', piiMode: 'pseudonymize' }) }));
        await c.FetchChanges(ctx(c, TAG_OBJECT));
        expect(calls).toHaveLength(1);
    });
});

describe('FetchChanges — guards', () => {
    it('rejects an unknown object', async () => {
        installFakeClient();
        const c = new TestConnector();
        await expect(c.FetchChanges(ctx(c, 'Ticket'))).rejects.toThrow(/Unknown Spektrix Data Feeds object/);
    });

    it('rejects a malformed configuration by key name only', async () => {
        installFakeClient();
        const c = new TestConnector();
        await expect(c.FetchChanges(ctx(c, CUSTOMER_OBJECT, {}, { windowDays: 'thirty-ish' }))).rejects.toThrow(/windowDays/);
        await expect(c.FetchChanges(ctx(c, CUSTOMER_OBJECT, {}, { windowDays: 'thirty-ish' }))).rejects.not.toThrow(/thirty-ish/);
    });
});
