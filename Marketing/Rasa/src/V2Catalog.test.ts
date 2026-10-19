import { afterEach, describe, expect, it, vi } from 'vitest';
import { RasaConnector } from './RasaConnector';

/** 3.0.0 v2-catalog behaviours that need no network: the first-sync watermark floor and discovery scoping. */

type Internals = {
    AppendDefaultQueryParams(url: string, obj: unknown): string;
    currentWatermark: string | null;
};

/** Minimal IntegrationObject stand-in: only the members the code under test reads. */
function integrationObject(config: Record<string, unknown>, incremental = true) {
    return { SupportsIncrementalSync: incremental, Configuration: JSON.stringify(config), DefaultQueryParams: null };
}

describe('watermark floor', () => {
    const actions = integrationObject({ watermarkParam: 'created_since', watermarkFloor: '2000-01-01T00:00:00Z' });

    it('sends the declared floor when no watermark is stored (first sync)', () => {
        const c = new RasaConnector() as unknown as Internals;
        c.currentWatermark = null;
        const url = c.AppendDefaultQueryParams('https://h/v2/insights/newsletter/n1/actions?limit=500', actions);
        expect(url).toContain('created_since=2000-01-01T00%3A00%3A00Z');
    });

    it('prefers the stored watermark over the floor', () => {
        const c = new RasaConnector() as unknown as Internals;
        c.currentWatermark = '2026-10-01T00:00:00Z';
        const url = c.AppendDefaultQueryParams('https://h/v2/insights/newsletter/n1/actions', actions);
        expect(url).toContain('created_since=2026-10-01T00%3A00%3A00Z');
        expect(url).not.toContain('2000-01-01');
    });

    it('adds nothing for an object with no floor and no watermark', () => {
        const c = new RasaConnector() as unknown as Internals;
        c.currentWatermark = null;
        const obj = integrationObject({ watermarkParam: 'archived_since' });
        expect(c.AppendDefaultQueryParams('https://h/v2/contacts/deleted', obj)).not.toContain('archived_since');
    });

    it('ignores the floor on a non-incremental object', () => {
        const c = new RasaConnector() as unknown as Internals;
        c.currentWatermark = null;
        const obj = integrationObject({ watermarkParam: 'created_since', watermarkFloor: '2000-01-01T00:00:00Z' }, false);
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
