import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { describe, it, expect, beforeEach } from 'vitest';
import type { RESTResponse, PaginationType, FetchContext } from '@memberjunction/integration-engine';
import type {
    MJCompanyIntegrationEntity,
    MJIntegrationObjectEntity,
    MJIntegrationObjectFieldEntity,
} from '@memberjunction/core-entities';
import type { UserInfo } from '@memberjunction/core';
import { AsanaConnector, maxModifiedAt, toAsanaTimestamp } from '../AsanaConnector.js';

/**
 * The SHIPPED catalog, not a hand-made stub.
 *
 * The IntegrationObject rows these tests drive the base class with are read out of the metadata file
 * this package actually deploys. That is the point: the connector's behaviour (which params it
 * appends, which objects it scopes by workspace, which doors iterate a parent) is a function of that
 * metadata, so a test built on an invented stub could pass while the shipped catalog said something
 * else entirely.
 */
interface MetadataObject {
    fields: Record<string, unknown>;
    relatedEntities: { 'MJ: Integration Object Fields': Array<{ fields: Record<string, unknown> }> };
}
interface MetadataDoc {
    fields: Record<string, unknown>;
    relatedEntities: { 'MJ: Integration Objects': MetadataObject[] };
}

const METADATA = JSON.parse(
    readFileSync(
        fileURLToPath(new URL('../../metadata/integration/.asana.integration.json', import.meta.url)),
        'utf-8'
    )
) as MetadataDoc[];

const INTEGRATION = METADATA[0];
const OBJECTS = INTEGRATION.relatedEntities['MJ: Integration Objects'];

const objectMetadata = (name: string): MetadataObject => {
    const found = OBJECTS.find(o => o.fields.Name === name);
    if (!found) throw new Error(`no object "${name}" in the shipped metadata`);
    return found;
};

/** Projects a shipped metadata record into the entity shape the base class reads. */
const ioRow = (name: string): MJIntegrationObjectEntity =>
    ({ ID: `io-${name}`, ...objectMetadata(name).fields } as unknown as MJIntegrationObjectEntity);

const ioFields = (name: string): MJIntegrationObjectFieldEntity[] =>
    objectMetadata(name).relatedEntities['MJ: Integration Object Fields'].map(
        r => r.fields as unknown as MJIntegrationObjectFieldEntity
    );

const optFieldsOf = (name: string): Set<string> =>
    new Set(
        (JSON.parse(objectMetadata(name).fields.DefaultQueryParams as string).opt_fields as string).split(',')
    );

/**
 * MOCKED-ONLY test connector. Overrides just the seams that reach the outside world — the credential
 * load and the HTTP transport — plus the engine metadata cache. Everything else, including the whole
 * paginated fetch loop and URL assembly, is the real production code path.
 */
class TestAsanaConnector extends AsanaConnector {
    public Routes = new Map<string, RESTResponse>();
    public RequestedURLs: string[] = [];
    public TestToken: string | undefined = 'test-pat';
    public TestWorkspace: string | undefined = '111';

    protected override async Authenticate(): Promise<{ Token: string; Workspace: string }> {
        if (!this.TestToken) throw new Error('No Asana credential found — link an "API Key" credential.');
        if (!this.TestWorkspace) throw new Error('Asana workspace is not configured.');
        return { Token: this.TestToken, Workspace: this.TestWorkspace };
    }

    protected override async MakeHTTPRequest(
        _auth: { Token: string; Workspace: string },
        url: string
    ): Promise<RESTResponse> {
        this.RequestedURLs.push(url);
        return this.Routes.get(url) ?? { Status: 404, Body: { errors: [{ message: `unrouted ${url}` }] }, Headers: {} };
    }

    protected override GetCachedObject(_integrationID: string, objectName: string): MJIntegrationObjectEntity {
        return ioRow(objectName);
    }

    protected override GetCachedFields(objectID: string): MJIntegrationObjectFieldEntity[] {
        return ioFields(objectID.replace(/^io-/, ''));
    }

    // Exposed protected seams for direct assertions.
    public callNormalize(body: unknown, key: string | null) { return this.NormalizeResponse(body, key); }
    public callPagination(body: unknown, type: PaginationType) {
        return this.ExtractPaginationInfo(body, type, 1, 0, 100);
    }
    public callBuildPaginatedURL(name: string, cursor?: string, pageSize?: number) {
        const obj = ioRow(name);
        return this.BuildPaginatedURL(obj.APIPath, obj, 1, 0, cursor, pageSize);
    }
    public callAppendParams(name: string, url: string, workspace: string | null, watermark: string | null) {
        this.currentWorkspace = workspace;
        this.currentWatermark = watermark;
        try { return this.AppendDefaultQueryParams(url, ioRow(name)); }
        finally { this.currentWorkspace = null; this.currentWatermark = null; }
    }
    public callTransform(name: string, raw: Record<string, unknown>) {
        return this.TransformRecord(raw, ioRow(name), ioFields(name));
    }
    public callBuildHeaders() { return this.BuildHeaders({ Token: 'test-pat', Workspace: '111' }); }
}

const ctxFor = (objectName: string, over: Partial<FetchContext> = {}): FetchContext => ({
    CompanyIntegration: {
        ID: 'ci-1', IntegrationID: 'int-1', ExternalSystemID: '111',
    } as unknown as MJCompanyIntegrationEntity,
    ObjectName: objectName,
    WatermarkValue: null,
    BatchSize: 100,
    ContextUser: {} as UserInfo,
    ...over,
});

const page = (data: unknown[], nextOffset?: string): RESTResponse => ({
    Status: 200,
    Body: { data, next_page: nextOffset ? { offset: nextOffset, path: '/x', uri: 'https://x' } : null },
    Headers: { 'content-type': 'application/json' },
});

const USERS_PAGE1 =
    'https://app.asana.com/api/1.0/users?limit=100&opt_fields=gid%2Cname%2Cemail%2Cresource_type&workspace=111';

let c: TestAsanaConnector;
beforeEach(() => { c = new TestAsanaConnector(); });

describe('identity', () => {
    it('uses the same name as the shipped Integration record and the package', () => {
        expect(c.IntegrationName).toBe('Asana');
        expect(INTEGRATION.fields.Name).toBe('Asana');
        expect(INTEGRATION.fields.ClassName).toBe('@memberjunction/connector-asana');
        expect(INTEGRATION.fields.ImportPath).toBe('@memberjunction/connector-asana');
    });

    it('sends the opt-in headers Asana gates its current response shapes behind', () => {
        const headers = c.callBuildHeaders();
        expect(headers['Authorization']).toBe('Bearer test-pat');
        expect(headers['Asana-Enable']).toContain('new_goal_memberships');
        expect(headers['Asana-Enable']).toContain('new_user_task_lists');
    });

    it('declares a monotonic watermark and no keyset ordering key', () => {
        expect(c.MonotonicWatermark).toBe(true);
        expect(c.StableOrderingKey('Tasks')).toBeNull();
    });
});

describe('response envelope', () => {
    it("unwraps Asana's data envelope", () => {
        expect(c.callNormalize({ data: [{ gid: '1' }, { gid: '2' }] }, 'data')).toHaveLength(2);
    });

    it('wraps a single-object response so /users/me-shaped bodies are not silently dropped', () => {
        expect(c.callNormalize({ data: { gid: '1' } }, 'data')).toEqual([{ gid: '1' }]);
    });

    it('returns nothing for an error body rather than fabricating a record', () => {
        expect(c.callNormalize({ errors: [{ message: 'nope' }] }, 'data')).toEqual([]);
    });
});

describe('pagination', () => {
    it('reads the cursor out of next_page.offset', () => {
        expect(c.callPagination({ data: [], next_page: { offset: 'eyJ0eXAi' } }, 'Cursor'))
            .toEqual({ HasMore: true, NextCursor: 'eyJ0eXAi' });
    });

    /** next_page is null on the last page — the absence of a cursor IS the end-of-stream signal. */
    it('ends the stream when next_page is null', () => {
        expect(c.callPagination({ data: [{ gid: '1' }], next_page: null }, 'Cursor')).toEqual({ HasMore: false });
    });

    it('ends the stream when next_page carries no offset', () => {
        expect(c.callPagination({ data: [], next_page: { path: '/x' } }, 'Cursor')).toEqual({ HasMore: false });
    });

    /**
     * The base class's Cursor case emits `cursor=`, which Asana ignores rather than errors on — it
     * would re-serve page one. This is the assertion that keeps the override from being "cleaned up".
     */
    it("spells the cursor Asana's way (offset=), not the base class's way (cursor=)", () => {
        const url = c.callBuildPaginatedURL('Users', 'CURSOR123');
        expect(url).toContain('offset=CURSOR123');
        expect(url).not.toContain('cursor=');
    });

    it("clamps limit into Asana's 1..100 range, which it 400s outside of", () => {
        expect(c.callBuildPaginatedURL('Users', undefined, 5000)).toContain('limit=100');
        expect(c.callBuildPaginatedURL('Users', undefined, 0)).toContain('limit=1');
        expect(c.callBuildPaginatedURL('Users', undefined, 40)).toContain('limit=40');
    });

    it('joins with & on a door that already carries a query string', () => {
        // Tasks' door is /tasks?project={project_gid}; a second `?` would be a malformed URL.
        expect(c.callBuildPaginatedURL('Tasks')).toContain('?project={project_gid}&limit=');
    });
});

describe('per-run query params', () => {
    it('scopes the workspace-level listings, and only those', () => {
        expect(c.callAppendParams('Users', '/users?limit=100', '111', null)).toContain('workspace=111');
        expect(c.callAppendParams('Projects', '/projects?limit=100', '111', null)).toContain('workspace=111');
        // The child doors are already scoped by the parent id in their path; Asana rejects a
        // workspace passed alongside project.
        expect(c.callAppendParams('Tasks', '/tasks?project=p1&limit=100', '111', null)).not.toContain('workspace=');
        expect(c.callAppendParams('Subtasks', '/tasks/t1/subtasks?limit=100', '111', null)).not.toContain('workspace=');
    });

    it('applies modified_since only to the object that declares incremental sync', () => {
        const wm = '2026-05-01T00:00:00.000Z';
        expect(c.callAppendParams('Tasks', '/tasks?project=p1', '111', wm)).toContain('modified_since=');
        // Asana would ACCEPT modified_since on Users and silently return a partial set, so a leaked
        // filter here is data loss with no error anywhere.
        expect(c.callAppendParams('Users', '/users', '111', wm)).not.toContain('modified_since=');
    });

    it('omits modified_since on a first (watermark-less) run', () => {
        expect(c.callAppendParams('Tasks', '/tasks?project=p1', '111', null)).not.toContain('modified_since=');
    });

    it('appends the declared opt_fields projection from metadata, not from code', () => {
        const url = c.callAppendParams('Projects', '/projects?limit=100', '111', null);
        expect(decodeURIComponent(url)).toContain('opt_fields=gid,name,resource_type');
        expect(decodeURIComponent(url)).toContain('current_status.color');
    });
});

describe('fetch — through the real base fetch loop', () => {
    it('assembles scope, projection and paging into one request and lands the record', async () => {
        c.Routes.set(USERS_PAGE1, page([{ gid: 'u1', name: 'Ada', email: 'ada@example.com', resource_type: 'user' }]));

        const result = await c.FetchChanges(ctxFor('Users'));

        expect(c.RequestedURLs).toEqual([USERS_PAGE1]);
        expect(result.Records).toHaveLength(1);
        expect(result.Records[0].Fields.gid).toBe('u1');
    });

    /**
     * Page two asks for `limit=99`, not 100: the base narrows the page size to the batch's REMAINING
     * capacity so a page can never overshoot BatchSize. That interacts with the clamp in
     * BuildPaginatedURL, so it is asserted here rather than left implicit.
     */
    it('follows the cursor across pages, narrowing limit to the remaining batch capacity', async () => {
        c.Routes.set(USERS_PAGE1, page([{ gid: 'u1' }], 'NEXT'));
        c.Routes.set(
            'https://app.asana.com/api/1.0/users?offset=NEXT&limit=99&opt_fields=gid%2Cname%2Cemail%2Cresource_type&workspace=111',
            page([{ gid: 'u2' }])
        );

        const result = await c.FetchChanges(ctxFor('Users'));

        expect(c.RequestedURLs).toHaveLength(2);
        expect(result.Records.map(r => r.Fields.gid)).toEqual(['u1', 'u2']);
        expect(result.HasMore).toBe(false);
    });

    it('resolves the workspace from ExternalSystemID, which is where a workspace-scoped vendor keeps it', async () => {
        c.TestWorkspace = '999';
        c.Routes.set(USERS_PAGE1.replace('workspace=111', 'workspace=999'), page([{ gid: 'u1' }]));
        expect((await c.FetchChanges(ctxFor('Users'))).Records).toHaveLength(1);
    });

    it('surfaces a missing credential as an error rather than an empty success', async () => {
        c.TestToken = undefined;
        await expect(c.FetchChanges(ctxFor('Users'))).rejects.toThrow(/credential/i);
    });

    /** The stash is per-call state; leaking it would apply one object's filter to the next. */
    it('clears the per-run scope even when the fetch throws', async () => {
        c.TestToken = undefined;
        await expect(c.FetchChanges(ctxFor('Users'))).rejects.toThrow();
        expect(c.callAppendParams('Tasks', '/tasks?project=p1', null, null)).not.toContain('modified_since=');
    });
});

describe('record flattening', () => {
    it('projects nested {gid} sub-objects onto their declared columns', () => {
        const out = c.callTransform('Projects', {
            gid: 'p1',
            owner: { gid: 'u9', name: 'Ada' },
            team: { gid: 't3' },
            workspace: { gid: '111' },
        });
        expect(out.owner_gid).toBe('u9');
        expect(out.team_gid).toBe('t3');
        expect(out.workspace_gid).toBe('111');
    });

    it('lands null — not undefined — when Asana explicitly nulls a sub-object', () => {
        const out = c.callTransform('Projects', { gid: 'p1', owner: null, current_status: null });
        expect(out.owner_gid).toBeNull();
        expect(out.current_status_color).toBeNull();
        expect(out.current_status_title).toBeNull();
        expect(out.current_status_text).toBeNull();
    });

    it('splits current_status into its three declared columns', () => {
        const out = c.callTransform('Projects', {
            gid: 'p1',
            current_status: { color: 'green', title: 'On track', text: 'All good' },
        });
        expect(out.current_status_color).toBe('green');
        expect(out.current_status_title).toBe('On track');
        expect(out.current_status_text).toBe('All good');
    });

    it('takes the section from the first membership, which is the project door we came through', () => {
        const out = c.callTransform('Tasks', {
            gid: 't1',
            memberships: [{ project: { gid: 'p1' }, section: { gid: 's1', name: 'In Progress' } }],
        });
        expect(out.section_name).toBe('In Progress');
    });

    it('lands a null section rather than nothing when the task is in no section', () => {
        expect(c.callTransform('Tasks', { gid: 't1', memberships: [] }).section_name).toBeNull();
        expect(c.callTransform('Tasks', { gid: 't1', memberships: [{ section: null }] }).section_name).toBeNull();
    });

    /**
     * Custom fields are configured per workspace, so they can never be declared columns. Landing the
     * array as JSON is what lets a tenant project its own — the legacy driver hardcoded four names.
     */
    it('serializes custom_fields to JSON, and nulls an empty array rather than storing "[]"', () => {
        const populated = c.callTransform('Tasks', {
            gid: 't1',
            custom_fields: [{ name: 'ETC', display_value: '8' }],
        });
        expect(JSON.parse(populated.custom_fields_json as string)).toEqual([{ name: 'ETC', display_value: '8' }]);
        expect(c.callTransform('Tasks', { gid: 't1', custom_fields: [] }).custom_fields_json).toBeNull();
    });

    it('leaves every original key in place so full-record custom-column capture still sees them', () => {
        const out = c.callTransform('Tasks', { gid: 't1', assignee: { gid: 'u1' }, some_future_asana_key: 'x' });
        expect(out.assignee).toEqual({ gid: 'u1' });
        expect(out.some_future_asana_key).toBe('x');
    });

    it('survives a record that omits every nested field', () => {
        expect(c.callTransform('Tasks', { gid: 't1' })).toEqual({ gid: 't1' });
    });
});

describe('watermark', () => {
    it('advances to the highest modified_at actually observed', () => {
        const records = [
            { Fields: { modified_at: '2026-03-01T00:00:00.000Z' } },
            { Fields: { modified_at: '2026-05-02T10:00:00.000Z' } },
            { Fields: { modified_at: '2026-04-01T00:00:00.000Z' } },
        ];
        expect(maxModifiedAt(records, null)).toBe('2026-05-02T10:00:00.000Z');
    });

    /** A batch of only-older records must not re-open a window the previous run already closed. */
    it('never moves backwards', () => {
        expect(maxModifiedAt([{ Fields: { modified_at: '2026-01-01T00:00:00.000Z' } }], '2026-05-01T00:00:00.000Z'))
            .toBeNull();
    });

    it('reports no movement for a batch with no timestamps at all', () => {
        expect(maxModifiedAt([{ Fields: { gid: 'x' } }], null)).toBeNull();
        expect(maxModifiedAt([], '2026-05-01T00:00:00.000Z')).toBeNull();
    });

    it('emits NewWatermarkValue only when the batch actually moved it', async () => {
        c.Routes.set(USERS_PAGE1, page([{ gid: 'u1', modified_at: '2026-06-01T00:00:00.000Z' }]));
        expect((await c.FetchChanges(ctxFor('Users'))).NewWatermarkValue).toBe('2026-06-01T00:00:00.000Z');

        c = new TestAsanaConnector();
        c.Routes.set(USERS_PAGE1, page([{ gid: 'u1' }]));
        const unmoved = await c.FetchChanges(ctxFor('Users', { WatermarkValue: '2026-06-01T00:00:00.000Z' }));
        expect(unmoved.NewWatermarkValue).toBeUndefined();
    });

    /** Widening re-reads records (they upsert by gid); narrowing would lose a day of changes. */
    it('widens a date-only watermark to the start of the day rather than narrowing it', () => {
        expect(toAsanaTimestamp('2026-05-01')).toBe('2026-05-01T00:00:00.000Z');
        expect(toAsanaTimestamp('2026-05-01T12:34:56.000Z')).toBe('2026-05-01T12:34:56.000Z');
    });
});

describe('connection test', () => {
    const ME_URL = 'https://app.asana.com/api/1.0/users/me';
    const me = (over: Record<string, unknown> = {}): RESTResponse => ({
        Status: 200,
        Body: { data: { gid: 'u1', name: 'Ada', workspaces: [{ gid: '111', name: 'Acme' }], ...over } },
        Headers: { 'content-type': 'application/json' },
    });

    it('succeeds when the token resolves and the workspace is visible to it', async () => {
        c.Routes.set(ME_URL, me());
        const result = await c.TestConnection({} as MJCompanyIntegrationEntity, {} as UserInfo);
        expect(result.Success).toBe(true);
        expect(result.Message).toContain('Ada');
    });

    it('reports a rejected token distinctly from a permissions problem', async () => {
        c.Routes.set(ME_URL, { Status: 401, Body: {}, Headers: {} });
        const result = await c.TestConnection({} as MJCompanyIntegrationEntity, {} as UserInfo);
        expect(result.Success).toBe(false);
        expect(result.Message).toContain('401');
    });

    /**
     * The failure this exists for: a valid token pointed at a workspace it cannot see authenticates
     * fine and then syncs zero records, forever, with every run green.
     */
    it('fails when the configured workspace is not one the token can see', async () => {
        c.TestWorkspace = '222';
        c.Routes.set(ME_URL, me());
        const result = await c.TestConnection({} as MJCompanyIntegrationEntity, {} as UserInfo);
        expect(result.Success).toBe(false);
        expect(result.Message).toContain('222');
        expect(result.Message).toContain('zero records');
    });

    it('does not fail a token whose workspace list Asana did not return', async () => {
        c.Routes.set(ME_URL, me({ workspaces: [] }));
        expect((await c.TestConnection({} as MJCompanyIntegrationEntity, {} as UserInfo)).Success).toBe(true);
    });

    it('returns a failure result rather than throwing when the credential is missing', async () => {
        c.TestToken = undefined;
        const result = await c.TestConnection({} as MJCompanyIntegrationEntity, {} as UserInfo);
        expect(result.Success).toBe(false);
        expect(result.Message).toMatch(/credential/i);
    });
});

/**
 * These assert the SHIPPED catalog, because a templated door whose parent is undeclared fetches zero
 * rows and still reports success — the silent-empty class that shipped 21 dead PheedLoop objects.
 */
describe('shipped catalog', () => {
    const names = new Set(OBJECTS.map(o => o.fields.Name as string));

    it('declares the four Asana surfaces', () => {
        expect([...names].sort()).toEqual(['Projects', 'Subtasks', 'Tasks', 'Users']);
    });

    it.each([
        ['Tasks', 'Projects', 'project_gid'],
        ['Subtasks', 'Tasks', 'parent_task_gid'],
    ])('declares %s as a child of %s stamped onto %s', (child, parent, fkField) => {
        const cfg = JSON.parse(objectMetadata(child).fields.Configuration as string);
        expect(cfg.parentObjectName).toBe(parent);
        expect(cfg.parentObjectIDFieldName).toBe(fkField);
        // The declared parent must be a real sibling, or the engine warns PARENT_UNRESOLVED and the
        // object fetches nothing.
        expect(names.has(cfg.parentObjectName)).toBe(true);
        // The stamped FK must be a declared column, or the engine writes the parent id nowhere.
        expect(ioFields(child).some(f => f.Name === fkField)).toBe(true);
    });

    it('mirrors APIPath into Configuration.apiPath, which is what the parent validator reads', () => {
        for (const o of OBJECTS) {
            expect(JSON.parse(o.fields.Configuration as string).apiPath).toBe(o.fields.APIPath);
        }
    });

    it('gives every object exactly one primary key', () => {
        for (const o of OBJECTS) {
            const pks = o.relatedEntities['MJ: Integration Object Fields'].filter(f => f.fields.IsPrimaryKey);
            expect(pks.map(p => p.fields.Name)).toEqual(['gid']);
        }
    });

    /** A column with no opt_field behind it lands null on every record while the run reports success. */
    it('requests every column it declares', () => {
        // Derived from a nested sub-object, or stamped by the engine from the parent it iterated —
        // in neither case is the column name itself a valid opt_field.
        const derived = new Map<string, string>([
            ['owner_gid', 'owner.gid'],
            ['team_gid', 'team.gid'],
            ['workspace_gid', 'workspace.gid'],
            ['assignee_gid', 'assignee.gid'],
            ['parent_gid', 'parent.gid'],
            ['current_status_color', 'current_status.color'],
            ['current_status_title', 'current_status.title'],
            ['current_status_text', 'current_status.text'],
            ['section_name', 'memberships.section.name'],
            ['custom_fields_json', 'custom_fields'],
        ]);
        const stamped = new Set(['project_gid', 'parent_task_gid']);

        for (const o of OBJECTS) {
            const name = o.fields.Name as string;
            const optFields = optFieldsOf(name);
            for (const f of o.relatedEntities['MJ: Integration Object Fields']) {
                const column = f.fields.Name as string;
                if (stamped.has(column)) continue;
                const required = derived.get(column) ?? column;
                expect(optFields.has(required), `${name}.${column} needs opt_field "${required}"`).toBe(true);
            }
        }
    });

    it('names modified_at as the watermark field on the one incremental object', () => {
        const incremental = OBJECTS.filter(o => o.fields.SupportsIncrementalSync);
        expect(incremental.map(o => o.fields.Name)).toEqual(['Tasks']);
        expect(incremental[0].fields.IncrementalWatermarkField).toBe('modified_at');
        expect(ioFields('Tasks').some(f => f.Name === 'modified_at')).toBe(true);
    });

    it('ships read-only — no object claims a write capability', () => {
        for (const o of OBJECTS) expect(o.fields.SupportsWrite).toBe(false);
    });
});
