import { describe, it, expect, beforeEach, vi } from 'vitest';
import { readFileSync } from 'node:fs';
import type { RESTAuthContext, RESTResponse, FetchContext } from '@memberjunction/integration-engine';
import type { MJCompanyIntegrationEntity, MJIntegrationObjectEntity, MJIntegrationObjectFieldEntity } from '@memberjunction/core-entities';

// Exercises the REAL read-back of stored records (resolveRecordStorage + LoadStoredRecords) against a
// fake RunView shaped like what the engine builds. The main connector suite substitutes a canned
// store for LoadStoredRecords, so it can't see the queries; this file can.

interface RunViewParams { EntityName: string; ExtraFilter?: string; Fields?: string[]; MaxRows?: number }
type RunViewResult = { Success: boolean; Results: Record<string, unknown>[]; ErrorMessage?: string };

const state = vi.hoisted(() => ({
    calls: [] as RunViewParams[],
    handler: (_p: RunViewParams): RunViewResult => ({ Success: true, Results: [] }),
}));

vi.mock('@memberjunction/core', async (importOriginal) => {
    const actual = await importOriginal<typeof import('@memberjunction/core')>();
    class FakeRunView {
        public async RunView(params: RunViewParams): Promise<RunViewResult> {
            state.calls.push(params);
            return state.handler(params);
        }
    }
    return { ...actual, RunView: FakeRunView };
});

const { ORCIDConnector } = await import('../ORCIDConnector.js');
const { extractSectionRawItems } = await import('../orcidRecordExtraction.js');

const FULL_RECORD = JSON.parse(
    readFileSync(new URL('./fixtures/record-0000-0002-1825-0097.json', import.meta.url), 'utf8')
) as Record<string, unknown>;
const SAMPLE = '0000-0002-1825-0097';
const OTHER = '0000-0001-2345-6789';
const SAMPLE_WORKS = extractSectionRawItems(FULL_RECORD, 'works', SAMPLE);

// An engine-built record table: the source key is the row's (soft) primary key and there is NO `ID`
// column. Columns are the sanitized source names the engine wrote.
const RECORD_ENTITY = 'ORCID Record';
const KEY = 'orcid_id';
const PERSON = 'person';
const ACTIVITIES = 'activities_summary';

function field(name: string, isPk = false): MJIntegrationObjectFieldEntity {
    return { Name: name, IsPrimaryKey: isPk, Type: 'String' } as unknown as MJIntegrationObjectFieldEntity;
}
const OBJECTS: Record<string, { obj: MJIntegrationObjectEntity; fields: MJIntegrationObjectFieldEntity[] }> = {
    works: {
        obj: { ID: 'io-works', Name: 'works' } as unknown as MJIntegrationObjectEntity,
        fields: [field('orcid-id'), field('put-code', true), field('last-modified-date')],
    },
};

class ReadBackConnector extends ORCIDConnector {
    public Calls: string[] = [];
    public Config: Record<string, unknown> = { OrcidIds: [SAMPLE] };
    protected override async Authenticate(): Promise<RESTAuthContext> {
        return { Token: undefined, BaseUrl: 'https://pub.orcid.org/v3.0', Config: { ...this.Config } } as unknown as RESTAuthContext;
    }
    protected override async MakeHTTPRequest(_a: RESTAuthContext, url: string): Promise<RESTResponse> {
        this.Calls.push(url);
        return { Status: 200, Body: FULL_RECORD, Headers: {} };
    }
    protected override GetCachedObject(_i: string, name: string): MJIntegrationObjectEntity { return OBJECTS[name].obj; }
    protected override GetCachedFields(id: string): MJIntegrationObjectFieldEntity[] { return OBJECTS[id.replace(/^io-/, '')].fields; }
    public Load(orcidIds: string[]): Promise<Map<string, Record<string, unknown>>> {
        return this.LoadStoredRecords(ctx(), orcidIds);
    }
}

function ctx(): FetchContext {
    return {
        CompanyIntegration: { ID: 'ci-1', IntegrationID: 'int-1' } as MJCompanyIntegrationEntity,
        ObjectName: 'works',
        WatermarkValue: null,
        BatchSize: 1000,
        ContextUser: {} as never,
    };
}

/** The connection's maps, plus a stored table keyed by orcid_id. `mapped` lists the source fields with a field map. */
function engineStore(opts: {
    mapped?: string[];
    rows?: Record<string, unknown>[];
    tableFails?: boolean;
} = {}): (p: RunViewParams) => RunViewResult {
    const mapped = opts.mapped ?? ['orcid-id', 'person', 'activities-summary'];
    const destOf: Record<string, string> = { 'orcid-id': KEY, person: PERSON, 'activities-summary': ACTIVITIES };
    return (p) => {
        if (p.EntityName === 'MJ: Company Integration Entity Maps') {
            return { Success: true, Results: [{ ID: 'em-record', Entity: RECORD_ENTITY }] };
        }
        if (p.EntityName === 'MJ: Company Integration Field Maps') {
            return { Success: true, Results: mapped.map(s => ({ SourceFieldName: s, DestinationFieldName: destOf[s] })) };
        }
        if (p.EntityName === RECORD_ENTITY) {
            if (opts.tableFails) return { Success: false, Results: [], ErrorMessage: 'Invalid column name' };
            // Behave like the real table: an `ID` column does not exist.
            if ((p.Fields ?? []).includes('ID') || /\bID\b/.test(p.ExtraFilter ?? '')) {
                return { Success: false, Results: [], ErrorMessage: "Invalid column name 'ID'." };
            }
            return { Success: true, Results: opts.rows ?? [] };
        }
        return { Success: false, Results: [], ErrorMessage: `unexpected entity ${p.EntityName}` };
    };
}

/** A stored row as SQL Server returns it: json columns as strings. */
function sqlServerRow(iD: string, withActivities = true): Record<string, unknown> {
    return {
        [KEY]: iD,
        [PERSON]: JSON.stringify(FULL_RECORD['person']),
        [ACTIVITIES]: withActivities ? JSON.stringify(FULL_RECORD['activities-summary']) : null,
    };
}

describe('ORCIDConnector — reading stored records back (engine-built table, no ID column)', () => {
    let c: ReadBackConnector;
    beforeEach(() => {
        state.calls = [];
        c = new ReadBackConnector();
    });

    it('looks rows up by the mapped orcid-id column, never by an ID column', async () => {
        state.handler = engineStore({ rows: [sqlServerRow(SAMPLE)] });
        const stored = await c.Load([SAMPLE]);
        expect(stored.has(SAMPLE)).toBe(true);
        const tableQuery = state.calls.find(p => p.EntityName === RECORD_ENTITY)!;
        expect(tableQuery.ExtraFilter).toBe(`${KEY} IN ('${SAMPLE}')`);
        expect(tableQuery.Fields).toEqual([KEY, PERSON, ACTIVITIES]);
        expect(tableQuery.Fields).not.toContain('ID');
    });

    it('needs no record-map lookup: the key column is the iD', async () => {
        state.handler = engineStore({ rows: [sqlServerRow(SAMPLE)] });
        await c.Load([SAMPLE]);
        expect(state.calls.some(p => p.EntityName === 'MJ: Company Integration Record Maps')).toBe(false);
    });

    it('parses json columns whether they arrive as strings (SQL Server) or objects (PostgreSQL)', async () => {
        state.handler = engineStore({
            rows: [
                sqlServerRow(SAMPLE),
                { [KEY]: OTHER, [PERSON]: FULL_RECORD['person'], [ACTIVITIES]: FULL_RECORD['activities-summary'] },
            ],
        });
        const stored = await c.Load([SAMPLE, OTHER]);
        for (const iD of [SAMPLE, OTHER]) {
            const rec = stored.get(iD)!;
            expect(rec['person']).toEqual(FULL_RECORD['person']);
            expect(rec['activities-summary']).toEqual(FULL_RECORD['activities-summary']);
        }
    });

    it('a row stored before activities-summary existed comes back with person only', async () => {
        state.handler = engineStore({ rows: [sqlServerRow(SAMPLE, false)] });
        const rec = (await c.Load([SAMPLE])).get(SAMPLE)!;
        expect(rec['person']).toBeDefined();
        expect(rec['activities-summary']).toBeUndefined();
    });

    it('an unmapped activities-summary is never requested (the column does not exist yet)', async () => {
        state.handler = engineStore({ mapped: ['orcid-id', 'person'], rows: [sqlServerRow(SAMPLE, false)] });
        await c.Load([SAMPLE]);
        const tableQuery = state.calls.find(p => p.EntityName === RECORD_ENTITY)!;
        expect(tableQuery.Fields).toEqual([KEY, PERSON]);
    });

    it('with no column for orcid-id there is nothing to look rows up by: no table query, nothing stored', async () => {
        state.handler = engineStore({ mapped: ['person', 'activities-summary'] });
        const stored = await c.Load([SAMPLE]);
        expect(stored.size).toBe(0);
        expect(state.calls.some(p => p.EntityName === RECORD_ENTITY)).toBe(false);
    });

    it('ignores rows the query returns for iDs outside the page', async () => {
        state.handler = engineStore({ rows: [sqlServerRow(SAMPLE), sqlServerRow(OTHER)] });
        const stored = await c.Load([SAMPLE]);
        expect([...stored.keys()]).toEqual([SAMPLE]);
    });

    it('resolves where records live once per run, not once per page', async () => {
        state.handler = engineStore({ rows: [sqlServerRow(SAMPLE)] });
        await c.Load([SAMPLE]);
        await c.Load([SAMPLE]);
        expect(state.calls.filter(p => p.EntityName === 'MJ: Company Integration Entity Maps')).toHaveLength(1);
        expect(state.calls.filter(p => p.EntityName === RECORD_ENTITY)).toHaveLength(2);
    });

    it('end to end: a works page is derived from the stored rows with no ORCID call', async () => {
        state.handler = engineStore({ rows: [sqlServerRow(SAMPLE)] });
        const result = await c.FetchChanges(ctx());
        expect(c.Calls).toHaveLength(0);
        expect(result.Records).toHaveLength(SAMPLE_WORKS.length);
        expect(result.Warnings?.some(w => w.Code === 'RECORD_FALLBACK_FETCH')).toBeFalsy();
    });
});
