/**
 * Bounds tests: every request carries a deadline, and one FetchChanges call can never download an
 * unbounded backlog. Both are survivability properties rather than features — an unbounded request
 * or an unbounded batch fails in a way nothing above the connector can recover from, so each is
 * asserted structurally instead of trusted.
 */
import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import type { RESTResponse, FetchContext } from '@memberjunction/integration-engine';
import type { MJCompanyIntegrationEntity } from '@memberjunction/core-entities';
import type { UserInfo } from '@memberjunction/core';
import { PropFuelConnector } from '../PropFuelConnector.js';

const ACCOUNT = '2019';
const BASE = `https://app.propfuel.com/dataexport/${ACCOUNT}`;
const LIST_URL = `${BASE}/list`;
const downloadURL = (file: string) => `${BASE}/download/${encodeURIComponent(file)}`;

/** Routes by URL and counts downloads; auth/transport only, so no live call is possible. */
class BoundsConnector extends PropFuelConnector {
    public Routes = new Map<string, RESTResponse>();
    public Downloads: string[] = [];
    public TimeoutMs: number | undefined;

    protected override async Authenticate(): Promise<{ Token: string; AccountID: string; RequestTimeoutMs?: number }> {
        return { Token: 't', AccountID: ACCOUNT, RequestTimeoutMs: this.TimeoutMs };
    }
    protected override async MakeHTTPRequest(
        _auth: { Token: string; AccountID: string },
        url: string
    ): Promise<RESTResponse> {
        if (url.includes('/download/')) this.Downloads.push(url);
        return this.Routes.get(url) ?? { Status: 404, Body: {}, Headers: {} };
    }
}

/** Exercises the REAL MakeHTTPRequest (transport not overridden) so the signal can be inspected. */
class TransportConnector extends PropFuelConnector {
    public TimeoutMs: number | undefined;
    protected override async Authenticate(): Promise<{ Token: string; AccountID: string; RequestTimeoutMs?: number }> {
        return { Token: 't', AccountID: ACCOUNT, RequestTimeoutMs: this.TimeoutMs };
    }
    public callTransport(url: string): Promise<RESTResponse> {
        const self = this as unknown as {
            MakeHTTPRequest: (a: unknown, u: string, m: string, h: Record<string, string>) => Promise<RESTResponse>;
        };
        return self.MakeHTTPRequest({ Token: 't', AccountID: ACCOUNT, RequestTimeoutMs: this.TimeoutMs }, url, 'GET', {});
    }
}

const companyIntegration = {} as unknown as MJCompanyIntegrationEntity;
const contextUser = {} as unknown as UserInfo;

function ctx(over: Partial<FetchContext> = {}): FetchContext {
    return {
        CompanyIntegration: companyIntegration,
        ContextUser: contextUser,
        ObjectName: 'opens',
        BatchSize: null,
        AfterKeyValue: null,
        WatermarkValue: null,
        ...over,
    } as unknown as FetchContext;
}

describe('every request carries a deadline', () => {
    let fetchMock: ReturnType<typeof vi.fn>;

    beforeEach(() => {
        fetchMock = vi.fn(async (_url: string, init?: RequestInit) => ({
            status: 200,
            headers: { forEach: (cb: (v: string, k: string) => void) => cb('application/json', 'content-type') },
            text: async () => '[]',
            __init: init,
        }));
        vi.stubGlobal('fetch', fetchMock as unknown as typeof fetch);
    });
    afterEach(() => { vi.unstubAllGlobals(); });

    it('arms an AbortSignal on the default path', async () => {
        const c = new TransportConnector();
        await c.callTransport(LIST_URL);
        const init = fetchMock.mock.calls[0][1] as RequestInit;
        expect(init.signal).toBeInstanceOf(AbortSignal);
        expect(init.signal!.aborted).toBe(false);
    });

    it('requestTimeoutMs: 0 opts out of the DEFAULT deadline, not out of ending', async () => {
        const c = new TransportConnector();
        c.TimeoutMs = 0;
        await c.callTransport(LIST_URL);
        const init = fetchMock.mock.calls[0][1] as RequestInit;
        // The opt-out must still produce a signal — an unbounded request is the failure mode this exists to remove.
        expect(init.signal).toBeInstanceOf(AbortSignal);
    });

    it('honours an explicit per-connection deadline', async () => {
        const c = new TransportConnector();
        c.TimeoutMs = 1;
        await c.callTransport(LIST_URL);
        const init = fetchMock.mock.calls[0][1] as RequestInit;
        expect(init.signal).toBeInstanceOf(AbortSignal);
        // A 1ms deadline is aborted essentially immediately; proves the value is actually used.
        await new Promise(r => setTimeout(r, 25));
        expect(init.signal!.aborted).toBe(true);
    });
});

describe('one FetchChanges call cannot download an unbounded backlog', () => {
    let c: BoundsConnector;

    beforeEach(() => {
        c = new BoundsConnector();
    });

    it('caps files per call when BatchSize is absent (was: the entire backlog)', async () => {
        // 300 candidate files, one record each: the record cap (50k) can never trigger, so only the
        // FILE cap stands between this call and 300 downloads.
        const files = Array.from({ length: 300 }, (_, i) => `${1000 + i}.0-opens.json`);
        c.Routes.set(LIST_URL, { Status: 200, Body: files, Headers: { 'content-type': 'application/json' } });
        for (const f of files) {
            c.Routes.set(downloadURL(f), { Status: 200, Body: [{ id: f }], Headers: { 'content-type': 'application/json' } });
        }
        const result = await c.FetchChanges(ctx());
        expect(c.Downloads.length).toBe(250);
        expect(result.Records).toHaveLength(250);
        // Bounded, not lossy: the engine is told to come back for the rest.
        expect(result.HasMore).toBe(true);
        expect(result.NextAfterKeyValue).toBeTruthy();
    });

    it('an explicit BatchSize still wins', async () => {
        const files = Array.from({ length: 10 }, (_, i) => `${1000 + i}.0-opens.json`);
        c.Routes.set(LIST_URL, { Status: 200, Body: files, Headers: { 'content-type': 'application/json' } });
        for (const f of files) {
            c.Routes.set(downloadURL(f), { Status: 200, Body: [{ id: f }], Headers: { 'content-type': 'application/json' } });
        }
        const result = await c.FetchChanges(ctx({ BatchSize: 3 }));
        expect(result.Records.length).toBeGreaterThanOrEqual(3);
        expect(result.Records.length).toBeLessThan(10);
        expect(result.HasMore).toBe(true);
    });

    it('resumes from the cursor across calls, losing nothing', async () => {
        const files = Array.from({ length: 300 }, (_, i) => `${1000 + i}.0-opens.json`);
        c.Routes.set(LIST_URL, { Status: 200, Body: files, Headers: { 'content-type': 'application/json' } });
        for (const f of files) {
            c.Routes.set(downloadURL(f), { Status: 200, Body: [{ id: f }], Headers: { 'content-type': 'application/json' } });
        }
        const first = await c.FetchChanges(ctx());
        const second = await c.FetchChanges(ctx({ AfterKeyValue: first.NextAfterKeyValue as string }));
        expect(second.Records).toHaveLength(50);   // 300 - 250 already taken
        expect(second.HasMore).toBe(false);
        // No file is fetched twice across the two calls.
        expect(new Set(c.Downloads).size).toBe(c.Downloads.length);
    });
});
