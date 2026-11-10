import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { BaseRESTIntegrationConnector } from '@memberjunction/integration-engine';
import { RasaConnector } from './RasaConnector';

/**
 * Per-call fetch state and nested-collection parent keys.
 *
 * The engine runs several objects at once on ONE connector instance (`syncConcurrency > 1`). The
 * base's hooks carry no object, so the connector publishes each fetch's context for them to read
 * back after the HTTP round-trip. On instance fields the last fetch to start overwrote the others,
 * and their pages were read with the wrong `DataPath` (PLUS, 2026-11-03: Contacts stopped at 50).
 */

type Obj = {
    APIPath: string;
    ResponseDataKey: string | null;
    Configuration: string;
    IncrementalWatermarkField: string | null;
    SupportsIncrementalSync: boolean;
};

type Internals = {
    NormalizeResponse(body: unknown, key: string | null): Record<string, unknown>[];
    ExtractPaginationInfo(body: unknown, type: string, page: number, offset: number, size: number): { HasMore: boolean };
    responseCtx: unknown;
    GetCachedObject(integrationID: string, name: string): Obj;
};

const contacts: Obj = {
    APIPath: '/v2/contacts',
    ResponseDataKey: 'results',
    Configuration: JSON.stringify({ pkField: 'id' }),
    IncrementalWatermarkField: null,
    SupportsIncrementalSync: false,
};

const identifiers: Obj = {
    APIPath: '/v2/contacts',
    ResponseDataKey: 'results[].identifiers',
    Configuration: JSON.stringify({
        accessPath: { door: '/v2/contacts', nesting: ['identifiers'], parentObject: 'Contact' },
        parentKeyInjectionRequired: { parentObject: 'Contact', parentKeyField: 'id', nesting: ['identifiers'], childKeyField: 'contact_id' },
    }),
    IncrementalWatermarkField: null,
    SupportsIncrementalSync: false,
};

const page = {
    metadata: { next_link: '' },
    results: [
        { id: 'c1', email: 'a@example.com', identifiers: [{ system: 'crm', identifier: '111' }, { system: 'erp', identifier: '9' }] },
        { id: 'c2', email: 'b@example.com', identifiers: [] },
        { email: 'no-id@example.com', identifiers: [{ system: 'crm', identifier: 'orphan' }] },
    ],
};

function fetchContext(objectName: string) {
    return { CompanyIntegration: { IntegrationID: 'i1' }, ObjectName: objectName, WatermarkValue: null } as never;
}

/** The objects in the shipped metadata, with Configuration as the JSON string the entity holds. */
function shippedObjects(): Array<Obj & { Name: string }> {
    const path = fileURLToPath(new URL('../metadata/integration/.rasa.integration.json', import.meta.url));
    const [integration] = JSON.parse(readFileSync(path, 'utf8')) as Array<{
        relatedEntities: { 'MJ: Integration Objects': Array<{ fields: Record<string, unknown> }> };
    }>;
    return integration.relatedEntities['MJ: Integration Objects'].map(({ fields }) => ({
        Name: String(fields.Name),
        APIPath: String(fields.APIPath),
        ResponseDataKey: (fields.ResponseDataKey as string | null) ?? null,
        Configuration: JSON.stringify(fields.Configuration),
        IncrementalWatermarkField: (fields.IncrementalWatermarkField as string | null) ?? null,
        SupportsIncrementalSync: Boolean(fields.SupportsIncrementalSync),
    }));
}

describe('concurrent fetches on one instance', () => {
    afterEach(() => vi.restoreAllMocks());

    it('reads each response with its own object context, whichever call started last', async () => {
        const connector = new RasaConnector();
        const c = connector as unknown as Internals;
        c.GetCachedObject = (_id, name) => (name === 'Contact External Identifier' ? identifiers : contacts);

        // The base fetch: wait (the HTTP round-trip), then normalize, as the real pipeline does. The
        // first call waits longest, so it normalizes after the second call has published its context.
        const delays: Record<string, number> = { Contact: 20, 'Contact External Identifier': 1 };
        vi.spyOn(BaseRESTIntegrationConnector.prototype, 'FetchChanges').mockImplementation(async function (
            this: Internals,
            ctx: { ObjectName: string },
        ) {
            await new Promise(resolve => setTimeout(resolve, delays[ctx.ObjectName]));
            const records = this.NormalizeResponse(page, null).map((f, i) => ({ ExternalID: String(i), ObjectType: ctx.ObjectName, Fields: f }));
            return { Records: records, HasMore: false } as never;
        });

        const [contactBatch, identifierBatch] = await Promise.all([
            connector.FetchChanges(fetchContext('Contact')),
            connector.FetchChanges(fetchContext('Contact External Identifier')),
        ]);

        expect(contactBatch.Records.map(r => r.Fields.id)).toEqual(['c1', 'c2', undefined]);
        expect(identifierBatch.Records.map(r => r.Fields)).toEqual([
            { system: 'crm', identifier: '111', contact_id: 'c1' },
            { system: 'erp', identifier: '9', contact_id: 'c1' },
        ]);
    });
});

describe('nested collections carry their parent key', () => {
    function publishedFor(obj: Obj): Internals {
        const c = new RasaConnector() as unknown as Internals & { PublishResponseContext(obj: Obj, name: string): void };
        c.PublishResponseContext(obj, 'Contact External Identifier');
        return c;
    }

    it('stamps each child with its parent id and drops children of a parent with no id', () => {
        const rows = publishedFor(identifiers).NormalizeResponse(page, null);
        expect(rows).toEqual([
            { system: 'crm', identifier: '111', contact_id: 'c1' },
            { system: 'erp', identifier: '9', contact_id: 'c1' },
        ]);
    });

    it('stamps the parent id with the configuration each nested object ships with', () => {
        const nested = shippedObjects().filter(o => JSON.parse(o.Configuration).parentKeyInjectionRequired);
        expect(nested).toHaveLength(8);
        for (const obj of nested) {
            const { nesting, childKeyField } = JSON.parse(obj.Configuration).parentKeyInjectionRequired as {
                nesting: string[];
                childKeyField: string;
            };
            const body = { metadata: { next_link: '' }, results: [{ id: 'p1', [nesting[0]]: [{ name: 'child' }] }] };
            expect(publishedFor(obj).NormalizeResponse(body, null), obj.Name).toEqual([{ name: 'child', [childKeyField]: 'p1' }]);
        }
    });

    it('pages by the parents, not the children', () => {
        const c = publishedFor(identifiers);
        // 3 parents on a 3-row page is a full page (more may follow), though only 2 children came back.
        expect(c.ExtractPaginationInfo({ ...page, metadata: { next_link: '/v2/contacts?skip=3&limit=3' } }, 'Offset', 1, 0, 3).HasMore).toBe(true);
        // 3 parents on a 50-row page is the last page.
        expect(c.ExtractPaginationInfo(page, 'Offset', 1, 0, 50).HasMore).toBe(false);
    });

    it('leaves an object that only notes the need (no childKeyField) on the plain path', () => {
        const noted: Obj = {
            ...identifiers,
            Configuration: JSON.stringify({ parentKeyInjectionRequired: { parentObject: 'Contact', parentKeyField: 'id', nesting: ['identifiers'] } }),
        };
        expect(publishedFor(noted).NormalizeResponse(page, null)).toEqual([
            { system: 'crm', identifier: '111' },
            { system: 'erp', identifier: '9' },
            { system: 'crm', identifier: 'orphan' },
        ]);
    });
});
