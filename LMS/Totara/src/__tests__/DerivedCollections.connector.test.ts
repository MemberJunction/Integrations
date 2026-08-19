/**
 * Connector-level tests for derived collections: children accumulate FROM THE
 * PARENT'S OWN FETCH as pages arrive, and the child objects drain that buffer with
 * zero additional vendor calls. The mock transport throws on any request with no
 * canned response queued, so "no vendor call happened" is asserted structurally,
 * not inferred.
 */
import { describe, it, expect, beforeEach } from 'vitest';
import type { FetchContext } from '@memberjunction/integration-engine';
import type {
    MJCompanyIntegrationEntity,
    MJIntegrationObjectEntity,
    MJIntegrationObjectFieldEntity,
    UserInfo,
} from '@memberjunction/core-entities';
import { IntegrationEngineBase } from '@memberjunction/integration-engine-base';
import { TotaraConnector, type MoodleRPCRequest } from '../TotaraConnector.js';

// ── Fixtures (same shapes as TotaraConnector.test.ts) ─────────────────────────

function makeIO(over: Partial<MJIntegrationObjectEntity> & { ID: string; Name: string; Configuration: string }): MJIntegrationObjectEntity {
    return {
        DisplayName: over.Name, Description: 'fixture', APIPath: '/webservice/rest/server.php',
        ResponseDataKey: null, DefaultPageSize: 0, SupportsPagination: false, PaginationType: 'None',
        SupportsIncrementalSync: false, SupportsWrite: false, IncrementalWatermarkField: null,
        Status: 'Active', IntegrationID: 'int-1',
        ...over,
    } as unknown as MJIntegrationObjectEntity;
}
function makeIOF(over: Partial<MJIntegrationObjectFieldEntity> & { Name: string }): MJIntegrationObjectFieldEntity {
    return {
        Type: 'string', IsPrimaryKey: false, IsRequired: false, IsReadOnly: false, IsUniqueKey: false,
        Sequence: 0, Status: 'Active', DisplayName: over.Name, ...over,
    } as unknown as MJIntegrationObjectFieldEntity;
}

const PARENT_CFG = JSON.stringify({ wsfunction: 'core_enrol_get_enrolled_users', responseEnvelopeKey: null });
const CHILD_CFG = JSON.stringify({
    derivedCollection: {
        parentObjectName: 'Enrolled Users',
        collectionField: 'roles',
        parentKeyMap: { id: 'userid', courseid: 'courseid' },
        elementKind: 'object',
    },
});

const ci = { ID: 'ci-1', IntegrationID: 'int-1', Configuration: null, CredentialID: null } as unknown as MJCompanyIntegrationEntity;
const user = { ID: 'u-1' } as unknown as UserInfo;

class HarnessConnector extends TotaraConnector {
    public Responses: Array<{ Status: number; Body: unknown; Headers: Record<string, string> }> = [];
    public RequestCount = 0;
    public IOFixtures = new Map<string, MJIntegrationObjectEntity>();
    public IOFFixtures = new Map<string, MJIntegrationObjectFieldEntity[]>();

    protected override async Authenticate(): Promise<never> {
        return { Token: 't', Endpoint: 'https://learn.example.org/webservice/rest/server.php' } as never;
    }
    protected override async MakeHTTPRequest(): Promise<{ Status: number; Body: unknown; Headers: Record<string, string> }> {
        this.RequestCount++;
        const next = this.Responses.shift();
        if (!next) throw new Error('HarnessConnector: vendor request with no canned response — a drain path made a vendor call');
        return next;
    }
    protected override GetCachedObject(_integrationID: string, objectName: string): MJIntegrationObjectEntity {
        const io = this.IOFixtures.get(objectName);
        if (!io) throw new Error(`fixture missing: ${objectName}`);
        return io;
    }
    protected override GetCachedFields(objectID: string): MJIntegrationObjectFieldEntity[] {
        return this.IOFFixtures.get(objectID) ?? [];
    }
    public seed(io: MJIntegrationObjectEntity, fields: MJIntegrationObjectFieldEntity[]): void {
        this.IOFixtures.set(io.Name, io);
        this.IOFFixtures.set(io.ID, fields);
    }
    public queue(body: unknown): void {
        this.Responses.push({ Status: 200, Body: body, Headers: {} });
    }
}

const parentIO = () => makeIO({ ID: 'io-parent', Name: 'Enrolled Users', Configuration: PARENT_CFG });
const childIO = () => makeIO({ ID: 'io-child', Name: 'Enrolled User Roles', Configuration: CHILD_CFG });
const parentFields = () => [
    makeIOF({ Name: 'id', IsPrimaryKey: true, Type: 'integer', Sequence: 0 }),
    makeIOF({ Name: 'courseid', IsPrimaryKey: true, Type: 'integer', Sequence: 1 }),
];
const childFields = () => [
    makeIOF({ Name: 'userid', IsPrimaryKey: true, Type: 'integer', Sequence: 0 }),
    makeIOF({ Name: 'courseid', IsPrimaryKey: true, Type: 'integer', Sequence: 1 }),
    makeIOF({ Name: 'roleid', IsPrimaryKey: true, Type: 'integer', Sequence: 2 }),
];

const PARENT_PAGE = [
    { id: 7, courseid: 12, fullname: 'A', roles: [{ roleid: 5, shortname: 'student' }, { roleid: 3, shortname: 'editingteacher' }] },
    { id: 8, courseid: 12, fullname: 'B', roles: [{ roleid: 5, shortname: 'student' }] },
];

function fetchCtx(objectName: string, over: Partial<FetchContext> = {}): FetchContext {
    return {
        CompanyIntegration: ci, ObjectName: objectName, ContextUser: user,
        BatchSize: 50, CurrentPage: null, CurrentOffset: null, AfterKeyValue: null,
        ModifiedSince: null, FullSync: true,
        ...over,
    } as unknown as FetchContext;
}

function seedEngine(): void {
    IntegrationEngineBase.Instance.SeedForTesting({
        Integrations: [{ ID: 'int-1', Name: 'totara' }],
        IntegrationObjects: [
            { ID: 'io-parent', IntegrationID: 'int-1', Name: 'Enrolled Users', Status: 'Active', Configuration: PARENT_CFG },
            { ID: 'io-child', IntegrationID: 'int-1', Name: 'Enrolled User Roles', Status: 'Active', Configuration: CHILD_CFG },
        ],
    });
}

describe('derived collections — accumulate on the parent fetch, drain with zero vendor calls', () => {
    let c: HarnessConnector;

    beforeEach(() => {
        seedEngine();
        c = new HarnessConnector();
        c.seed(parentIO(), parentFields());
        c.seed(childIO(), childFields());
    });

    it('the parent fetch fills the child buffer as the page arrives; the child drains it with NO vendor call', async () => {
        c.queue(PARENT_PAGE);
        const parent = await c.FetchChanges(fetchCtx('Enrolled Users'));
        expect(parent.Records).toHaveLength(2);
        expect(c.RequestCount).toBe(1);

        // Child fetch: the transport queue is EMPTY — any vendor call would throw.
        const child = await c.FetchChanges(fetchCtx('Enrolled User Roles'));
        expect(c.RequestCount).toBe(1); // unchanged
        expect(child.HasMore).toBe(false);
        expect(child.Records.map(r => r.Fields)).toEqual([
            { userid: 7, courseid: 12, roleid: 5, shortname: 'student' },
            { userid: 7, courseid: 12, roleid: 3, shortname: 'editingteacher' },
            { userid: 8, courseid: 12, roleid: 5, shortname: 'student' },
        ]);
        // Identity is the declared child PK
        expect(child.Records[0].ExternalID).toBe('7|12|5');
    });

    it('drains in BatchSize pages with a resumable offset', async () => {
        c.queue(PARENT_PAGE);
        await c.FetchChanges(fetchCtx('Enrolled Users'));

        const p1 = await c.FetchChanges(fetchCtx('Enrolled User Roles', { BatchSize: 2 }));
        expect(p1.Records).toHaveLength(2);
        expect(p1.HasMore).toBe(true);
        expect(p1.NextOffset).toBe(2);

        const p2 = await c.FetchChanges(fetchCtx('Enrolled User Roles', { BatchSize: 2, CurrentOffset: 2 }));
        expect(p2.Records).toHaveLength(1);
        expect(p2.HasMore).toBe(false);
    });

    it('with NO buffer (child runs first), the child falls back to walking the parent itself', async () => {
        c.queue(PARENT_PAGE); // consumed by the child's fallback parent-walk
        const child = await c.FetchChanges(fetchCtx('Enrolled User Roles'));
        expect(c.RequestCount).toBe(1);
        expect(child.Records).toHaveLength(3);
        expect(child.HasMore).toBe(false);
    });

    it('a duplicated page (engine retry) does not duplicate drained children — identity collapses them', async () => {
        // Two parent fetches from the top: the second resets the buffer, so no dupes at all;
        // dupes WITHIN one buffer (a mid-walk retry) collapse at drain via ExternalID dedupe.
        c.queue(PARENT_PAGE);
        await c.FetchChanges(fetchCtx('Enrolled Users'));
        c.queue(PARENT_PAGE);
        await c.FetchChanges(fetchCtx('Enrolled Users'));

        const child = await c.FetchChanges(fetchCtx('Enrolled User Roles'));
        expect(child.Records).toHaveLength(3);
    });

    it('a malformed derivedCollection fails the CHILD loudly and leaves the PARENT untouched', async () => {
        const badChild = makeIO({ ID: 'io-bad', Name: 'Broken Child', Configuration: JSON.stringify({ derivedCollection: { collectionField: 'roles' } }) });
        c.seed(badChild, []);
        await expect(c.FetchChanges(fetchCtx('Broken Child'))).rejects.toThrow(/parentObjectName/);

        c.queue(PARENT_PAGE);
        const parent = await c.FetchChanges(fetchCtx('Enrolled Users'));
        expect(parent.Records).toHaveLength(2);
    });
});

describe('dropFields — config columns stripped at the connector', () => {
    it('drops declared keys from the record stream before shaping', async () => {
        seedEngine();
        const c = new HarnessConnector();
        const io = makeIO({
            ID: 'io-users', Name: 'Users',
            Configuration: JSON.stringify({ wsfunction: 'core_user_get_users', responseEnvelopeKey: null, dropFields: ['preferences'] }),
        });
        c.seed(io, [makeIOF({ Name: 'id', IsPrimaryKey: true, Type: 'integer' })]);
        c.queue([{ id: 1, fullname: 'A', preferences: [{ name: '_lastloaded', value: '1' }] }]);

        const out = await c.FetchChanges(fetchCtx('Users'));
        expect(out.Records[0].Fields).toEqual({ id: 1, fullname: 'A' });
    });
});
