import { afterEach, describe, expect, it, vi } from 'vitest';
import { RasaConnector } from './RasaConnector';

/** v2-catalog behaviours that need no network: the action feeds' lookback window and discovery scoping. */

type Internals = {
    AppendDefaultQueryParams(url: string, obj: unknown): string;
    currentWatermark: string | null;
    pendingWarnings: { Code: string }[];
};

/** Minimal IntegrationObject stand-in: only the members the code under test reads. */
function integrationObject(config: Record<string, unknown>, incremental = true) {
    return { SupportsIncrementalSync: incremental, Configuration: JSON.stringify(config), DefaultQueryParams: null };
}

describe('lookback window', () => {
    // rasa.io rejects created_since more than 24 months ago; the action feeds declare 725 days.
    const actions = integrationObject({ watermarkParam: 'created_since', maxLookbackDays: 725 });
    const sent = (url: string) => new URL(url).searchParams.get('created_since');

    afterEach(() => vi.useRealTimers());
    const at = (iso: string) => {
        vi.useFakeTimers();
        vi.setSystemTime(new Date(iso));
    };

    it('sends now − maxLookbackDays, rounded up to UTC midnight, on a first sync', () => {
        at('2026-10-20T16:54:23Z');
        const c = new RasaConnector() as unknown as Internals;
        c.currentWatermark = null;
        const url = c.AppendDefaultQueryParams('https://h/v2/insights/newsletter/n1/actions?limit=500', actions);
        // 2026-10-20T16:54:23Z − 725 d = 2024-10-25T16:54:23Z → next midnight; inside the vendor's 24 months.
        expect(sent(url)).toBe('2024-10-26T00:00:00Z');
    });

    it('sends the same value on every page of a pass', () => {
        const c = new RasaConnector() as unknown as Internals;
        c.currentWatermark = null;
        at('2026-10-20T01:00:00Z');
        const first = sent(c.AppendDefaultQueryParams('https://h/v2/x', actions));
        at('2026-10-20T23:59:00Z');
        expect(sent(c.AppendDefaultQueryParams('https://h/v2/x?skip=500', actions))).toBe(first);
    });

    it('keeps a stored watermark inside the window', () => {
        at('2026-10-20T00:00:00Z');
        const c = new RasaConnector() as unknown as Internals;
        c.currentWatermark = '2026-10-01T00:00:00Z';
        const url = c.AppendDefaultQueryParams('https://h/v2/insights/newsletter/n1/actions', actions);
        expect(sent(url)).toBe('2026-10-01T00:00:00Z');
        expect(c.pendingWarnings).toHaveLength(0);
    });

    it('clamps a stored watermark older than the window, with one warning', () => {
        at('2026-10-20T00:00:00Z');
        const c = new RasaConnector() as unknown as Internals;
        c.currentWatermark = '2023-01-01T00:00:00Z';
        c.AppendDefaultQueryParams('https://h/v2/x', actions);
        const url = c.AppendDefaultQueryParams('https://h/v2/x?skip=500', actions);
        expect(sent(url)).toBe('2024-10-25T00:00:00Z'); // exactly midnight: no rounding
        expect(c.pendingWarnings.map(w => w.Code)).toEqual(['WATERMARK_CLAMPED']);
    });

    it('adds nothing for an object with no lookback and no watermark', () => {
        const c = new RasaConnector() as unknown as Internals;
        c.currentWatermark = null;
        const obj = integrationObject({ watermarkParam: 'archived_since' });
        expect(c.AppendDefaultQueryParams('https://h/v2/contacts/deleted', obj)).not.toContain('archived_since');
    });

    it('ignores the lookback on a non-incremental object', () => {
        const c = new RasaConnector() as unknown as Internals;
        c.currentWatermark = null;
        const obj = integrationObject({ watermarkParam: 'created_since', maxLookbackDays: 725 }, false);
        expect(c.AppendDefaultQueryParams('https://h/v2/x', obj)).not.toContain('created_since');
    });
});

describe('DiscoverObjects scoping', () => {
    afterEach(() => vi.unstubAllGlobals());

    /** A two-door v2 spec: one top-level list endpoint, one parent-scoped analytics endpoint. */
    const spec = {
        swagger: '2.0',
        basePath: '/v2',
        paths: {
            '/widgets': { get: { summary: 'List widgets', responses: { '200': { schema: { $ref: '#/definitions/WidgetsResponse' } } } } },
            '/analytics/newsletter/{id}/articles': {
                get: { summary: 'Article stats', responses: { '200': { schema: { $ref: '#/definitions/ArticlesResponse' } } } },
            },
        },
        definitions: {
            WidgetsResponse: { type: 'object', properties: { results: { type: 'array', items: { $ref: '#/definitions/Widget' } } } },
            Widget: { type: 'object', properties: { id: { type: 'string' } } },
            ArticlesResponse: { type: 'object', properties: { results: { type: 'array', items: { $ref: '#/definitions/ArticleStat' } } } },
            ArticleStat: { type: 'object', properties: { url: { type: 'string' } } },
        },
    };

    it('does not emit undeclared parent-scoped doors as objects, and only reads the v2 spec', async () => {
        const fetched: string[] = [];
        vi.stubGlobal('fetch', async (url: string) => {
            fetched.push(String(url));
            return new Response(JSON.stringify(spec), { status: 200 });
        });
        const connector = new RasaConnector();
        const base = Object.getPrototypeOf(Object.getPrototypeOf(connector)) as { DiscoverObjects: unknown };
        const original = base.DiscoverObjects;
        base.DiscoverObjects = async () => [];
        try {
            const objects = await connector.DiscoverObjects({ IntegrationID: 'int-1' } as never, {} as never);
            const doors = objects.map(o => o.Description);
            expect(objects).toHaveLength(1);
            expect(doors.some(d => d?.includes('List widgets'))).toBe(true);
            expect(fetched).toEqual(['https://api-docs.rasa.io/swagger.json']);
        } finally {
            base.DiscoverObjects = original;
        }
    });
});
