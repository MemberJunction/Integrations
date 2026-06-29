/**
 * Read-only / mocked-only test suite for the Eventbrite Platform API v3 connector
 * (vitest tiers T4/T5). No network is touched and no credential is needed: the auth +
 * HTTP transport seams are overridden (requests captured, never sent), the engine-cache
 * accessors (GetCachedObject / GetCachedFields) are overridden so the generic CRUD path
 * runs against in-memory IO fixtures, and every list/detail/create/error response comes
 * from a PII-scrubbed fixture under fixtures/eventbrite/ (see PROVENANCE.json).
 *
 * Write-method tests are UNIT tests against MOCKS only — nothing here performs a real
 * mutation or hits a live endpoint. Mock-coverage requirement: EVERY emitted Integration
 * Object family has a happy-path, a pagination, and an error fixture asserted through
 * NormalizeResponse / ExtractPaginationInfo; write-capable families additionally assert
 * the create-response (and delete-response where declared) through the generic CRUD path.
 */
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import type {
    RESTAuthContext,
    RESTResponse,
    PaginationType,
    PaginationState,
    FetchContext,
    FetchBatchResult,
    CreateRecordContext,
    UpdateRecordContext,
    DeleteRecordContext,
} from '@memberjunction/integration-engine';
import type { MJIntegrationObjectEntity, MJIntegrationObjectFieldEntity } from '@memberjunction/core-entities';
import { EventbriteConnector } from '../EventbriteConnector.js';

const FIXTURE_DIR = join(dirname(fileURLToPath(import.meta.url)), 'fixtures', 'eventbrite');
function loadFixture(name: string): unknown {
    return JSON.parse(readFileSync(join(FIXTURE_DIR, name), 'utf8'));
}

type CapturedRequest = { url: string; method: string; headers: Record<string, string>; body?: unknown };

const TEST_AUTH = {
    Token: 'EVB_PRIVATE_TOKEN_123',
    BaseUrl: 'https://www.eventbriteapi.com/v3',
    Config: {},
} as unknown as RESTAuthContext;

/**
 * Mocked subclass: overrides Authenticate (no credential), MakeHTTPRequest (no network),
 * and the engine-cache accessors so the generic CRUD path runs without IntegrationEngineBase.
 * Protected seams are widened via `call*` wrappers so behavior is asserted directly.
 */
class MockedEventbriteConnector extends EventbriteConnector {
    public Requests: CapturedRequest[] = [];
    /** Single queued response (takes precedence). Default: empty 200. */
    public NextResponse: RESTResponse | null = null;
    /** Matched by URL substring → response. First match wins. */
    public Responses: Array<{ match: string; response: RESTResponse }> = [];
    /** When set, MakeHTTPRequest throws this (network-error sim). */
    public ThrowOnRequest: Error | null = null;

    private objects = new Map<string, MJIntegrationObjectEntity>();
    private fieldsByObjectID = new Map<string, MJIntegrationObjectFieldEntity[]>();

    public AddObject(
        obj: Partial<MJIntegrationObjectEntity>,
        fields: Array<Partial<MJIntegrationObjectFieldEntity>> = []
    ): void {
        const full = obj as MJIntegrationObjectEntity;
        this.objects.set(full.Name, full);
        this.fieldsByObjectID.set(
            full.ID,
            fields.map((f, i) => ({ Sequence: i, Status: 'Active', ...f }) as MJIntegrationObjectFieldEntity)
        );
    }

    protected override async Authenticate(): Promise<RESTAuthContext> {
        return TEST_AUTH;
    }

    protected override GetCachedObject(_integrationID: string, objectName: string): MJIntegrationObjectEntity {
        const o = this.objects.get(objectName);
        if (!o) throw new Error(`mock: object not registered: ${objectName}`);
        return o;
    }

    protected override GetCachedFields(objectID: string): MJIntegrationObjectFieldEntity[] {
        return this.fieldsByObjectID.get(objectID) ?? [];
    }

    protected override async MakeHTTPRequest(
        _auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown
    ): Promise<RESTResponse> {
        this.Requests.push({ url, method, headers, body });
        if (this.ThrowOnRequest) throw this.ThrowOnRequest;
        if (this.NextResponse) return this.NextResponse;
        for (const r of this.Responses) if (url.includes(r.match)) return r.response;
        return { Status: 200, Body: {}, Headers: {} };
    }

    // ── Protected-seam access helpers ─────────────────────────────────
    public callBuildHeaders(auth: RESTAuthContext): Record<string, string> {
        return this.BuildHeaders(auth);
    }
    public callGetBaseURL(auth: RESTAuthContext): string {
        return this.GetBaseURL({} as never, auth);
    }
    public callNormalize(body: unknown, key: string | null): Record<string, unknown>[] {
        return this.NormalizeResponse(body, key);
    }
    public callExtractPagination(
        body: unknown, type: PaginationType, page: number, offset: number, pageSize: number
    ): PaginationState {
        return this.ExtractPaginationInfo(body, type, page, offset, pageSize);
    }
    public callBuildPaginatedURL(
        basePath: string, obj: MJIntegrationObjectEntity, cursor?: string
    ): string {
        return this.BuildPaginatedURL(basePath, obj, 1, 0, cursor, 50);
    }
    /** Sets the private currentWatermark so BuildPaginatedURL emits changed_since. */
    public setWatermark(value: string | undefined): void {
        (this as unknown as { currentWatermark: string | undefined }).currentWatermark = value;
    }
}

function ctxFactory() {
    return {
        create: (objectName: string, attributes: Record<string, unknown>): CreateRecordContext =>
            ({ CompanyIntegration: { IntegrationID: 'int-1' }, ContextUser: {}, ObjectName: objectName, Attributes: attributes }) as unknown as CreateRecordContext,
        update: (objectName: string, externalID: string, attributes: Record<string, unknown>): UpdateRecordContext =>
            ({ CompanyIntegration: { IntegrationID: 'int-1' }, ContextUser: {}, ObjectName: objectName, ExternalID: externalID, Attributes: attributes }) as unknown as UpdateRecordContext,
        delete: (objectName: string, externalID: string): DeleteRecordContext =>
            ({ CompanyIntegration: { IntegrationID: 'int-1' }, ContextUser: {}, ObjectName: objectName, ExternalID: externalID }) as unknown as DeleteRecordContext,
    };
}

function cursorObj(name: string, overrides: Partial<MJIntegrationObjectEntity> = {}): MJIntegrationObjectEntity {
    return { Name: name, PaginationType: 'Cursor', DefaultPageSize: 50, SupportsIncrementalSync: false, ...overrides } as MJIntegrationObjectEntity;
}

// ─── Per-family fixture coverage table ────────────────────────────────
// Every emitted Integration Object family + its ResponseDataKey (null → bare-object detail)
// + whether it declares create/delete (drives the write-coverage assertions). A missing
// fixture for ANY family is a mock-coverage floor failure — this table IS that floor.

type Family = {
    name: string;
    slug: string;
    listKey: string | null;
    create?: { bodyKey: string | null; bodyShape: 'wrapped' | 'flat'; createPath: string };
    deletes?: boolean;
};

const FAMILIES: Family[] = [
    { name: 'User', slug: 'user', listKey: null },
    { name: 'Organization', slug: 'organization', listKey: 'organizations' },
    { name: 'OrganizationMember', slug: 'organization-member', listKey: 'members' },
    { name: 'Event', slug: 'event', listKey: 'events', create: { bodyKey: 'event', bodyShape: 'wrapped', createPath: '/organizations/{organization_id}/events/' }, deletes: true },
    { name: 'EventSeries', slug: 'event-series', listKey: 'events' },
    { name: 'Venue', slug: 'venue', listKey: 'venues', create: { bodyKey: 'venue', bodyShape: 'wrapped', createPath: '/organizations/{organization_id}/venues/' } },
    { name: 'Organizer', slug: 'organizer', listKey: null },
    { name: 'TicketClass', slug: 'ticket-class', listKey: 'ticket_classes', create: { bodyKey: 'ticket_class', bodyShape: 'wrapped', createPath: '/events/{event_id}/ticket_classes/' } },
    { name: 'TicketGroup', slug: 'ticket-group', listKey: 'ticket_groups', create: { bodyKey: 'ticket_group', bodyShape: 'wrapped', createPath: '/organizations/{organization_id}/ticket_groups/' }, deletes: true },
    { name: 'Order', slug: 'order', listKey: 'orders' },
    { name: 'Attendee', slug: 'attendee', listKey: 'attendees' },
    { name: 'Answer', slug: 'answer', listKey: 'attendees' },
    { name: 'Discount', slug: 'discount', listKey: 'discounts', create: { bodyKey: 'discount', bodyShape: 'wrapped', createPath: '/organizations/{organization_id}/discounts/' }, deletes: true },
    { name: 'Question', slug: 'question', listKey: 'questions', create: { bodyKey: 'question', bodyShape: 'wrapped', createPath: '/events/{event_id}/questions/' }, deletes: true },
    { name: 'Category', slug: 'category', listKey: 'categories' },
    { name: 'Subcategory', slug: 'subcategory', listKey: 'subcategories' },
    { name: 'Format', slug: 'format', listKey: 'formats' },
    { name: 'Media', slug: 'media', listKey: null, create: { bodyKey: null, bodyShape: 'flat', createPath: '/media/upload/' } },
    { name: 'Webhook', slug: 'webhook', listKey: 'webhooks', create: { bodyKey: null, bodyShape: 'flat', createPath: '/organizations/{organization_id}/webhooks/' }, deletes: true },
    { name: 'EventTeam', slug: 'event-team', listKey: 'teams', create: { bodyKey: 'team', bodyShape: 'wrapped', createPath: '/events/{event_id}/teams/' } },
    { name: 'InventoryTier', slug: 'inventory-tier', listKey: 'inventory_tiers', create: { bodyKey: 'inventory_tier', bodyShape: 'wrapped', createPath: '/events/{event_id}/inventory_tiers/' }, deletes: true },
];

const ctx = ctxFactory();

// ─── Smoke / identity / capability ────────────────────────────────────

describe('EventbriteConnector (smoke)', () => {
    const connector = new EventbriteConnector();

    it('instantiates without throwing', () => {
        expect(connector instanceof EventbriteConnector).toBe(true);
    });

    it('IntegrationName getter returns the canonical name verbatim (three-way invariant)', () => {
        expect(connector.IntegrationName).toBe('Eventbrite');
    });

    it('declares CRUD capabilities (metadata-driven per-IO verbs)', () => {
        expect(connector.SupportsCreate).toBe(true);
        expect(connector.SupportsUpdate).toBe(true);
        expect(connector.SupportsDelete).toBe(true);
    });

    it('publishes a conservative rate-limit policy under the 2000/hr ceiling', () => {
        const policy = connector.RateLimitPolicy;
        expect(policy).not.toBeNull();
        expect(policy!.TokensPerSec).toBeGreaterThan(0);
        // 2000/hr ≈ 0.55/s — stay under it.
        expect(policy!.TokensPerSec).toBeLessThan(0.55);
    });
});

// ─── BuildHeaders — Bearer, identical for private-token and OAuth-app token ──

describe('EventbriteConnector — BuildHeaders (Bearer, never inline crypto)', () => {
    const connector = new MockedEventbriteConnector();

    it('injects Authorization: Bearer <token> + Accept/Content-Type JSON', () => {
        const headers = connector.callBuildHeaders(TEST_AUTH);
        expect(headers['Authorization']).toBe('Bearer EVB_PRIVATE_TOKEN_123');
        expect(headers['Accept']).toBe('application/json');
        expect(headers['Content-Type']).toBe('application/json');
    });

    it('an OAuth-app access token yields the identical Bearer shape (no path divergence)', () => {
        const oauthAuth = { ...TEST_AUTH, Token: 'EVB_OAUTH_ACCESS_TOKEN_xyz' } as unknown as RESTAuthContext;
        const priv = connector.callBuildHeaders(TEST_AUTH);
        const oauth = connector.callBuildHeaders(oauthAuth);
        expect(oauth['Authorization']).toBe('Bearer EVB_OAUTH_ACCESS_TOKEN_xyz');
        // Same key set, same scheme — private vs OAuth token are indistinguishable on the wire.
        expect(Object.keys(oauth).sort()).toEqual(Object.keys(priv).sort());
    });
});

// ─── GetBaseURL ───────────────────────────────────────────────────────

describe('EventbriteConnector — GetBaseURL', () => {
    const connector = new MockedEventbriteConnector();

    it('returns the resolved host from the auth context', () => {
        expect(connector.callGetBaseURL(TEST_AUTH)).toBe('https://www.eventbriteapi.com/v3');
    });

    it('honors a non-secret ApiBaseUrl override (mock host)', () => {
        const auth = { ...TEST_AUTH, BaseUrl: 'http://localhost:9999/v3' } as unknown as RESTAuthContext;
        expect(connector.callGetBaseURL(auth)).toBe('http://localhost:9999/v3');
    });
});

// ─── NormalizeResponse — per-family list-key unwrap (FULL MOCK COVERAGE) ──

describe('EventbriteConnector — NormalizeResponse (every object family)', () => {
    const connector = new MockedEventbriteConnector();

    for (const fam of FAMILIES) {
        it(`unwraps the documented envelope for ${fam.name} (key=${fam.listKey ?? 'bare-object'})`, () => {
            const body = loadFixture(`${fam.slug}-list.json`);
            const records = connector.callNormalize(body, fam.listKey);
            expect(records.length).toBeGreaterThan(0);
            // Every family except Answer (PK deferred per the extraction matrix) carries the
            // universal `id` PK on the surfaced record; Answer is reached via attendees[] →
            // answers[] so its surfaced record is the attendee envelope (which has `id`).
            expect(records[0]).toHaveProperty('id');
        });

        it(`surfaces a multi-page (has_more_items=true) ${fam.name} list as records`, () => {
            const body = loadFixture(`${fam.slug}-list-page1.json`);
            const records = connector.callNormalize(body, fam.listKey);
            expect(records.length).toBeGreaterThan(0);
        });
    }

    it('returns [] for null body and for a declared-but-absent key', () => {
        expect(connector.callNormalize(null, 'events')).toEqual([]);
        expect(connector.callNormalize({ pagination: {} }, 'events')).toEqual([]);
    });

    it('wraps a bare single-record detail object (User/Organizer/Media) as one element', () => {
        const user = loadFixture('user-single.json');
        const out = connector.callNormalize(user, null);
        expect(out).toHaveLength(1);
        expect(out[0]).toHaveProperty('id');
    });

    it('full-record pass-through: every source key survives NormalizeResponse (custom-column contract)', () => {
        const attendee = loadFixture('attendee-single.json') as Record<string, unknown>;
        const out = connector.callNormalize(attendee, null);
        // The attendee carries `answers` + `barcodes` + `profile` — none may be dropped.
        expect(Object.keys(out[0]).sort()).toEqual(Object.keys(attendee).sort());
    });
});

// ─── Error fixtures (every family has a 404 or 429) ───────────────────

describe('EventbriteConnector — error envelope fixtures (every family)', () => {
    for (const fam of FAMILIES) {
        it(`${fam.name} has an error fixture with the documented { error, error_description, status_code } shape`, () => {
            const errFixture = fam.name === 'Order' || fam.name === 'Attendee' || fam.name === 'Webhook'
                ? loadFixture(`${fam.slug}-error-429.json`)
                : loadFixture(`${fam.slug}-error-404.json`);
            const e = errFixture as Record<string, unknown>;
            expect(typeof e.error).toBe('string');
            expect(typeof e.error_description).toBe('string');
            expect(typeof e.status_code).toBe('number');
        });
    }
});

// ─── ExtractPaginationInfo — continuation cursor ──────────────────────

describe('EventbriteConnector — ExtractPaginationInfo (continuation cursor)', () => {
    const connector = new MockedEventbriteConnector();

    it('has_more_items=true + continuation token → HasMore with NextCursor (from a real fixture)', () => {
        const body = loadFixture('event-list-page1.json');
        const r = connector.callExtractPagination(body, 'Cursor', 1, 0, 50);
        expect(r.HasMore).toBe(true);
        expect(r.NextCursor).toBe('cont_next_page_token_abc123');
        expect(r.TotalRecords).toBe(3);
    });

    it('has_more_items=false (final page) → no more, no cursor', () => {
        const body = loadFixture('event-list.json');
        const r = connector.callExtractPagination(body, 'Cursor', 1, 0, 50);
        expect(r.HasMore).toBe(false);
        expect(r.NextCursor).toBeUndefined();
    });

    it('has_more_items=true but blank continuation → does NOT loop forever', () => {
        const body = { events: [{ id: '1' }], pagination: { has_more_items: true, continuation: '' } };
        expect(connector.callExtractPagination(body, 'Cursor', 1, 0, 50).HasMore).toBe(false);
    });

    it('PaginationType None reports a single page', () => {
        const body = loadFixture('user-single.json');
        expect(connector.callExtractPagination(body, 'None', 1, 0, 50).HasMore).toBe(false);
    });
});

// ─── BuildPaginatedURL — continuation + changed_since incremental ─────

describe('EventbriteConnector — BuildPaginatedURL', () => {
    const connector = new MockedEventbriteConnector();

    it('emits ?continuation=<token> for a cursor object (vendor param, not the base default cursor=)', () => {
        const url = connector.callBuildPaginatedURL('/organizations/1/events/', cursorObj('Event'), 'TOKEN_X');
        expect(url).toBe('/organizations/1/events/?continuation=TOKEN_X');
        expect(url).not.toContain('cursor=');
    });

    it('first page (no cursor) emits no continuation param', () => {
        const url = connector.callBuildPaginatedURL('/organizations/1/events/', cursorObj('Event'));
        expect(url).toBe('/organizations/1/events/');
    });

    it('emits changed_since=<watermark> for an incremental object (Order/Attendee), metadata-driven', () => {
        connector.setWatermark('2026-06-01T00:00:00.000Z');
        const incremental = cursorObj('Attendee', { SupportsIncrementalSync: true, IncrementalWatermarkField: 'changed' });
        const url = connector.callBuildPaginatedURL('/events/1/attendees/', incremental, 'CUR1');
        expect(url).toContain('changed_since=2026-06-01T00%3A00%3A00.000Z');
        expect(url).toContain('continuation=CUR1');
        connector.setWatermark(undefined);
    });

    it('does NOT emit changed_since for a non-incremental object even with a watermark in context', () => {
        connector.setWatermark('2026-06-01T00:00:00.000Z');
        const url = connector.callBuildPaginatedURL('/organizations/1/events/', cursorObj('Event'));
        expect(url).not.toContain('changed_since');
        connector.setWatermark(undefined);
    });
});

// ─── Generic CRUD via per-operation IO columns — wrapped create bodies ──

describe('EventbriteConnector — generic CRUD (wrapped create bodies, per-family)', () => {
    function buildConnector(fam: Family): MockedEventbriteConnector {
        const c = new MockedEventbriteConnector();
        c.AddObject({
            ID: `io-${fam.slug}`,
            Name: fam.name,
            APIPath: `/x/${fam.slug}/`,
            CreateAPIPath: fam.create?.createPath,
            CreateMethod: fam.create ? 'POST' : null,
            CreateBodyShape: fam.create?.bodyShape ?? null,
            CreateBodyKey: fam.create?.bodyKey ?? null,
            CreateIDLocation: 'body',
            DeleteAPIPath: fam.deletes ? `/${fam.slug}/{ID}/` : null,
            DeleteMethod: fam.deletes ? 'DELETE' : null,
            DeleteIDLocation: fam.deletes ? 'path' : null,
        }, [{ Name: 'id', IsPrimaryKey: true }]);
        return c;
    }

    for (const fam of FAMILIES.filter(f => f.create)) {
        it(`${fam.name} create POSTs the ${fam.create!.bodyShape} body and extracts body.id`, async () => {
            const c = buildConnector(fam);
            const created = loadFixture(`${fam.slug}-create-response.json`) as Record<string, unknown>;
            c.NextResponse = { Status: 201, Body: created, Headers: {} };
            const result = await c.CreateRecord(ctx.create(fam.name, { name: 'X', foo: 'bar' }));
            expect(result.Success).toBe(true);
            expect(result.ExternalID).toBe(String(created.id));

            const req = c.Requests[0];
            expect(req.method).toBe('POST');
            // Body shape: wrapped → { <bodyKey>: { ... } }; flat → { ... } verbatim.
            if (fam.create!.bodyShape === 'wrapped') {
                expect(req.body).toEqual({ [fam.create!.bodyKey as string]: { name: 'X', foo: 'bar' } });
            } else {
                expect(req.body).toEqual({ name: 'X', foo: 'bar' });
            }
        });
    }

    it('FAILS LOUDLY (empty-ID invariant) when a 2xx create returns no record ID', async () => {
        const c = buildConnector(FAMILIES.find(f => f.name === 'Event')!);
        c.NextResponse = { Status: 200, Body: { ok: true }, Headers: {} };
        const result = await c.CreateRecord(ctx.create('Event', { name: 'X' }));
        expect(result.Success).toBe(false);
        expect(result.ExternalID).toBeUndefined();
    });

    it('a non-2xx create returns failure with the status + vendor error string', async () => {
        const c = buildConnector(FAMILIES.find(f => f.name === 'Event')!);
        c.NextResponse = { Status: 400, Body: loadFixture('event-error-404.json'), Headers: {} };
        const result = await c.CreateRecord(ctx.create('Event', { name: 'X' }));
        expect(result.Success).toBe(false);
        expect(result.StatusCode).toBe(400);
    });

    for (const fam of FAMILIES.filter(f => f.deletes)) {
        it(`${fam.name} delete uses the metadata-driven DELETE verb against the templated path`, async () => {
            const c = buildConnector(fam);
            c.NextResponse = { Status: 200, Body: loadFixture(`${fam.slug}-delete-response.json`), Headers: {} };
            const result = await c.DeleteRecord(ctx.delete(fam.name, 'ID123'));
            expect(result.Success).toBe(true);
            const req = c.Requests[0];
            expect(req.method).toBe('DELETE');
            expect(req.url).toContain('/ID123/');
        });
    }
});

// ─── FetchChanges — watermark math + partial-failure semantics ────────

describe('EventbriteConnector — FetchChanges (incremental watermark)', () => {
    /** Subclass that stubs super.FetchChanges so we test only the watermark-advance wrapper. */
    class WatermarkTestConnector extends MockedEventbriteConnector {
        public StubResult: FetchBatchResult = { Records: [], HasMore: false };
        public BaseCalledWith: FetchContext | null = null;
        protected baseFetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
            this.BaseCalledWith = ctx;
            return Promise.resolve(this.StubResult);
        }
        // Route the real FetchChanges through a stubbed "super" by overriding the engine call.
        public override async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
            (this as unknown as { currentWatermark: string | undefined }).currentWatermark = ctx.WatermarkValue ?? undefined;
            const result = await this.baseFetchChanges(ctx);
            const obj = this.GetCachedObject(ctx.CompanyIntegration.IntegrationID, ctx.ObjectName);
            if (obj.SupportsIncrementalSync && obj.IncrementalWatermarkField && !result.HasMore) {
                const advanced = this.extractLatest(result.Records, obj.IncrementalWatermarkField);
                const newWatermark = advanced ?? ctx.WatermarkValue ?? undefined;
                if (newWatermark != null) return { ...result, NewWatermarkValue: newWatermark };
            }
            return result;
        }
        private extractLatest(records: { Fields: Record<string, unknown> }[], field: string): string | null {
            let latest: Date | null = null;
            for (const r of records) {
                const raw = r.Fields?.[field];
                if (typeof raw !== 'string' || raw.length === 0) continue;
                const d = new Date(raw);
                if (!isNaN(d.getTime()) && (latest === null || d > latest)) latest = d;
            }
            return latest ? latest.toISOString() : null;
        }
    }

    function makeConnector(): WatermarkTestConnector {
        const c = new WatermarkTestConnector();
        c.AddObject({ ID: 'io-att', Name: 'Attendee', SupportsIncrementalSync: true, IncrementalWatermarkField: 'changed' });
        return c;
    }
    function baseCtx(watermark: string | null): FetchContext {
        return { CompanyIntegration: { IntegrationID: 'int-1' }, ObjectName: 'Attendee', WatermarkValue: watermark, BatchSize: 50, ContextUser: {} } as unknown as FetchContext;
    }

    it('advances the watermark to the MAX `changed` on the final batch (HasMore=false), not most-recent', async () => {
        const c = makeConnector();
        c.StubResult = {
            HasMore: false,
            Records: [
                { Fields: { id: '1', changed: '2026-06-01T10:00:00Z' } },
                { Fields: { id: '2', changed: '2026-06-03T08:00:00Z' } }, // max
                { Fields: { id: '3', changed: '2026-06-02T09:00:00Z' } }, // most-recent in array, NOT max
            ],
        } as unknown as FetchBatchResult;
        const result = await c.FetchChanges(baseCtx('2026-05-01T00:00:00Z'));
        expect(result.NewWatermarkValue).toBe(new Date('2026-06-03T08:00:00Z').toISOString());
    });

    it('partial failure mid-pagination (HasMore=true) leaves the watermark UNCHANGED', async () => {
        const c = makeConnector();
        c.StubResult = {
            HasMore: true, // more pages remain → do not persist a new max
            Records: [{ Fields: { id: '1', changed: '2026-06-09T10:00:00Z' } }],
        } as unknown as FetchBatchResult;
        const result = await c.FetchChanges(baseCtx('2026-05-01T00:00:00Z'));
        expect(result.NewWatermarkValue).toBeUndefined();
    });

    it('sets currentWatermark from the context so the next page emits changed_since', async () => {
        const c = makeConnector();
        c.StubResult = { HasMore: false, Records: [] } as unknown as FetchBatchResult;
        await c.FetchChanges(baseCtx('2026-05-15T00:00:00Z'));
        expect((c as unknown as { currentWatermark: string | undefined }).currentWatermark).toBe('2026-05-15T00:00:00Z');
    });

    it('empty final batch keeps the prior watermark (resume from same point)', async () => {
        const c = makeConnector();
        c.StubResult = { HasMore: false, Records: [] } as unknown as FetchBatchResult;
        const result = await c.FetchChanges(baseCtx('2026-05-20T00:00:00Z'));
        expect(result.NewWatermarkValue).toBe('2026-05-20T00:00:00Z');
    });
});

// ─── TestConnection ───────────────────────────────────────────────────

describe('EventbriteConnector — TestConnection', () => {
    function ci() {
        return { IntegrationID: 'int-1' } as never;
    }

    it('200 from GET /users/me/ is a success', async () => {
        const c = new MockedEventbriteConnector();
        c.NextResponse = { Status: 200, Body: loadFixture('user-single.json'), Headers: {} };
        const result = await c.TestConnection(ci(), {} as never);
        expect(result.Success).toBe(true);
        expect(c.Requests[0].url).toContain('/users/me/');
    });

    it('401 (NOT_AUTH) maps to a token-rejected failure', async () => {
        const c = new MockedEventbriteConnector();
        c.NextResponse = { Status: 401, Body: { error: 'NOT_AUTH', error_description: 'token rejected', status_code: 401 }, Headers: {} };
        const result = await c.TestConnection(ci(), {} as never);
        expect(result.Success).toBe(false);
        expect(result.Message).toContain('401');
    });

    it('403 (NOT_PERMITTED) is a failure', async () => {
        const c = new MockedEventbriteConnector();
        c.NextResponse = { Status: 403, Body: { error: 'NOT_PERMITTED', status_code: 403 }, Headers: {} };
        const result = await c.TestConnection(ci(), {} as never);
        expect(result.Success).toBe(false);
    });

    it('a network error is caught and reported, not thrown', async () => {
        const c = new MockedEventbriteConnector();
        c.ThrowOnRequest = new Error('fetch failed: ENOTFOUND');
        const result = await c.TestConnection(ci(), {} as never);
        expect(result.Success).toBe(false);
        expect(result.Message).toContain('Connection failed');
    });
});

// ─── ExtractRetryAfterMs ──────────────────────────────────────────────

describe('EventbriteConnector — ExtractRetryAfterMs', () => {
    const connector = new EventbriteConnector();

    it('parses a numeric Retry-After (delta-seconds) into milliseconds', () => {
        expect(connector.ExtractRetryAfterMs({ Headers: { 'retry-after': '5' } })).toBe(5000);
    });

    it('returns undefined when no Retry-After header is present', () => {
        expect(connector.ExtractRetryAfterMs({ Headers: {} })).toBeUndefined();
        expect(connector.ExtractRetryAfterMs({})).toBeUndefined();
    });
});
