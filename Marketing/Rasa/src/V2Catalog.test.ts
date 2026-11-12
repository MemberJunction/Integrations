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

describe('404 on a per-parent read', () => {
    afterEach(() => vi.unstubAllGlobals());

    type Transport = {
        responseCtx: { ObjectName: string; DataPath: string | null; UnwrapDeclared: boolean; ParentScoped: boolean } | null;
        pendingWarnings: { Code: string; Message: string }[];
        MakeHTTPRequest(auth: unknown, url: string, method: string, headers: Record<string, string>): Promise<{ Status: number; Body: unknown }>;
    };

    // The live payload (2026-10-20): /v2/messaging/blast lists sequence 144, whose blast feed 404s.
    const wrongType = {
        code: 404,
        metadata: { errors: "'144' is a sequence, not a blast. Use /v2/insights/sequence/144/<report>", next_link: '' },
        results: [],
    };

    function connectorAnswering404(parentScoped: boolean): Transport {
        vi.stubGlobal('fetch', async () => new Response(JSON.stringify(wrongType), { status: 404 }));
        const c = new RasaConnector() as unknown as Transport;
        c.responseCtx = { ObjectName: 'Blast Action', DataPath: 'results', UnwrapDeclared: false, ParentScoped: parentScoped };
        c.pendingWarnings = [];
        return c;
    }

    it('answers an empty page and warns with the vendor message, so the sync moves to the next parent', async () => {
        const c = connectorAnswering404(true);
        const res = await c.MakeHTTPRequest({ Token: 't' }, 'https://h/v2/insights/blast/144/actions?limit=500', 'GET', {});
        expect(res.Status).toBe(200);
        expect(res.Body).toMatchObject({ results: [] });
        expect(c.pendingWarnings).toHaveLength(1);
        expect(c.pendingWarnings[0].Code).toBe('PARENT_NOT_FOUND');
        expect(c.pendingWarnings[0].Message).toContain('/v2/insights/blast/144/actions');
        expect(c.pendingWarnings[0].Message).toContain("'144' is a sequence, not a blast");
    });

    it('leaves a 404 on a top-level object to fail as before', async () => {
        const c = connectorAnswering404(false);
        const res = await c.MakeHTTPRequest({ Token: 't' }, 'https://h/v2/lists', 'GET', {});
        expect(res.Status).toBe(404);
        expect(c.pendingWarnings).toHaveLength(0);
    });

    it('does not mask a 404 on a write', async () => {
        const c = connectorAnswering404(true);
        const res = await c.MakeHTTPRequest({ Token: 't' }, 'https://h/v2/insights/blast/144/actions', 'POST', {});
        expect(res.Status).toBe(404);
    });
});

describe('400 on one parent\'s contacts', () => {
    afterEach(() => vi.unstubAllGlobals());

    type Transport = {
        responseCtx: { ObjectName: string; DataPath: string | null; UnwrapDeclared: boolean; ParentScoped: boolean } | null;
        pendingWarnings: { Code: string; Message: string }[];
        MakeHTTPRequest(auth: unknown, url: string, method: string, headers: Record<string, string>): Promise<{ Status: number; Body: unknown }>;
    };

    // The live payload (2026-11-11): a blast with no audience answers its contacts read with a 400.
    const noAudience = {
        code: 400,
        event: '',
        metadata: { errors: 'No target lists configured', next_link: '', record_count: 0 },
        results: [],
    };
    const otherMessage = { code: 400, metadata: { errors: 'Sequence has no messages', next_link: '' } };
    const tooOld = { code: 400, metadata: { errors: 'created_since cannot be more than 24 months ago', next_link: '' } };

    function connectorAnswering400(body: unknown, parentScoped = true): Transport {
        vi.stubGlobal('fetch', async () => new Response(JSON.stringify(body), { status: 400 }));
        const c = new RasaConnector() as unknown as Transport;
        c.responseCtx = { ObjectName: 'Blast Contact', DataPath: 'results', UnwrapDeclared: false, ParentScoped: parentScoped };
        c.pendingWarnings = [];
        return c;
    }

    it('answers an empty page and warns, so the sync moves on to the next blast', async () => {
        const c = connectorAnswering400(noAudience);
        const res = await c.MakeHTTPRequest({ Token: 't' }, 'https://h/v2/messaging/blast/282/contacts?limit=25', 'GET', {});
        expect(res.Status).toBe(200);
        expect(res.Body).toMatchObject({ results: [] });
        expect(c.pendingWarnings).toHaveLength(1);
        expect(c.pendingWarnings[0].Code).toBe('PARENT_NOT_CONFIGURED');
        expect(c.pendingWarnings[0].Message).toContain('HTTP 400 on GET /v2/messaging/blast/282/contacts');
        expect(c.pendingWarnings[0].Message).toContain('No target lists configured');
    });

    it('skips whatever the message says, on newsletter and sequence contacts too', async () => {
        for (const url of ['https://h/v2/messaging/sequence/144/contacts?skip=50&limit=50', 'https://h/v2/messaging/newsletter/9/contacts']) {
            const c = connectorAnswering400(otherMessage);
            const res = await c.MakeHTTPRequest({ Token: 't' }, url, 'GET', {});
            expect(res.Status).toBe(200);
            expect(c.pendingWarnings[0].Code).toBe('PARENT_NOT_CONFIGURED');
        }
    });

    it('leaves a 400 on an action feed to fail the read (its date window may be what was rejected)', async () => {
        const c = connectorAnswering400(tooOld);
        const res = await c.MakeHTTPRequest({ Token: 't' }, 'https://h/v2/insights/blast/282/actions', 'GET', {});
        expect(res.Status).toBe(400);
        expect(c.pendingWarnings).toHaveLength(0);
    });

    it('leaves the 400 to fail on a top-level object', async () => {
        const c = connectorAnswering400(noAudience, false);
        const res = await c.MakeHTTPRequest({ Token: 't' }, 'https://h/v2/messaging/blast', 'GET', {});
        expect(res.Status).toBe(400);
    });
});

describe('engagement events carry the contact (rasa.io 2026-10-20)', () => {
    it('declares contact_id (linked to Contact) and email on every action feed', async () => {
        const { readFileSync } = await import('node:fs');
        const { fileURLToPath } = await import('node:url');
        const path = fileURLToPath(new URL('../metadata/integration/.rasa.integration.json', import.meta.url));
        const [integration] = JSON.parse(readFileSync(path, 'utf8')) as Array<{
            relatedEntities: { 'MJ: Integration Objects': Array<{
                fields: { Name: string };
                relatedEntities: { 'MJ: Integration Object Fields': Array<{ fields: Record<string, unknown> }> };
            }> };
        }>;
        for (const name of ['Newsletter Action', 'Blast Action', 'Sequence Action']) {
            const obj = integration.relatedEntities['MJ: Integration Objects'].find(o => o.fields.Name === name);
            const fields = obj?.relatedEntities['MJ: Integration Object Fields'].map(f => f.fields) ?? [];
            const contact = fields.find(f => f.Name === 'contact_id');
            expect(contact, `${name}.contact_id`).toMatchObject({
                Type: 'string',
                AllowsNull: true,
                IsPrimaryKey: false,
                RelatedIntegrationObjectFieldName: 'id',
            });
            expect(String(contact?.RelatedIntegrationObjectID)).toContain('Name=Contact&');
            expect(fields.find(f => f.Name === 'email'), `${name}.email`).toMatchObject({ Type: 'string', AllowsNull: true });
        }
    });
});

describe('keys (3.0.3)', () => {
    type Field = Record<string, unknown> & { Name: string };
    type Obj = {
        fields: { Name: string; SupportsPagination: boolean; Configuration: Record<string, unknown> };
        relatedEntities: { 'MJ: Integration Object Fields': Array<{ fields: Field }> };
    };
    async function catalog(): Promise<Map<string, { obj: Obj['fields']; fields: Field[] }>> {
        const { readFileSync } = await import('node:fs');
        const { fileURLToPath } = await import('node:url');
        const path = fileURLToPath(new URL('../metadata/integration/.rasa.integration.json', import.meta.url));
        const [integration] = JSON.parse(readFileSync(path, 'utf8')) as Array<{ relatedEntities: { 'MJ: Integration Objects': Obj[] } }>;
        return new Map(
            integration.relatedEntities['MJ: Integration Objects'].map(o => [
                o.fields.Name,
                { obj: o.fields, fields: o.relatedEntities['MJ: Integration Object Fields'].map(f => f.fields) },
            ]),
        );
    }
    const pkOf = (fields: Field[]) => fields.filter(f => f.IsPrimaryKey).map(f => f.Name).sort();

    it('keys each event on its parent and rasa.io event id, so opens (no url) are stored', async () => {
        const all = await catalog();
        for (const [name, parent] of [['Newsletter Action', 'newsletter_id'], ['Blast Action', 'blast_id'], ['Sequence Action', 'sequence_id']]) {
            const { obj, fields } = all.get(name)!;
            expect(obj.Configuration.pkField, name).toBe(`${parent}+id`);
            expect(pkOf(fields), name).toEqual([parent, 'id'].sort());
        }
    });

    it('stamps every nested collection with its parent key, declared as a field linked to the parent', async () => {
        const all = await catalog();
        const nested = [...all.values()].filter(o => (o.obj.Configuration.accessPath as { nesting?: string[] } | undefined)?.nesting?.length);
        expect(nested.map(o => o.obj.Name).sort()).toHaveLength(8);
        for (const { obj, fields } of nested) {
            const inject = obj.Configuration.parentKeyInjectionRequired as { parentObject: string; childKeyField: string };
            expect(inject?.childKeyField, obj.Name).toBeTruthy();
            const key = fields.find(f => f.Name === inject.childKeyField);
            expect(key, `${obj.Name}.${inject.childKeyField}`).toMatchObject({ IsRequired: true, RelatedIntegrationObjectFieldName: 'id' });
            expect(String(key?.RelatedIntegrationObjectID)).toContain(`Name=${inject.parentObject}&`);
            // The declared pkField and the fields flagged IsPrimaryKey agree.
            expect(pkOf(fields), obj.Name).toEqual(String(obj.Configuration.pkField).split('+').sort());
        }
        expect(all.get('Contact External Identifier')!.obj.SupportsPagination).toBe(true);
    });

    it("reads every object's shipped configuration, a null watermarkParam included", async () => {
        const c = new RasaConnector() as unknown as { ObjectConfig(obj: { Configuration: string }): Record<string, unknown> };
        for (const { obj } of (await catalog()).values()) {
            const shipped = obj.Configuration;
            expect(c.ObjectConfig({ Configuration: JSON.stringify(shipped) }), obj.Name).toMatchObject({
                pkField: shipped.pkField,
                recordSchemas: shipped.recordSchemas,
                watermarkParam: shipped.watermarkParam,
            });
        }
    });

    it('describes every active column in rasa.io terms, with no generated filler', async () => {
        const filler = /^[^—]+ — .+ field '[^']+' \([^)]*\), rasa\.io v2\./;
        for (const { obj, fields } of (await catalog()).values()) {
            for (const f of fields) {
                expect(String(f.Description ?? ''), `${obj.Name}.${f.Name}`).not.toMatch(filler);
                expect(String(f.Description ?? '').length, `${obj.Name}.${f.Name}`).toBeGreaterThan(0);
            }
        }
    });
});
