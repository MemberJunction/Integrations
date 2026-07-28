import { describe, it, expect } from 'vitest';
import type { RESTResponse, RESTAuthContext, CreateRecordContext } from '@memberjunction/integration-engine';
import type { MJIntegrationObjectEntity } from '@memberjunction/core-entities';
import { MailchimpConnector } from '../MailchimpConnector.js';

// Smoke tests — verifies the connector's basic identity + capability surface.
// These pass without HTTP mocks or credentials. Failures here indicate a
// regression in capability declarations or naming (three-way invariant axis).
describe('MailchimpConnector (smoke)', () => {
    const connector = new MailchimpConnector();

    describe('Identity', () => {
        it('should instantiate without throwing', () => {
            expect(connector).toBeDefined();
            expect(connector instanceof MailchimpConnector).toBe(true);
        });

        // The getter must be VERBATIM `MJ: Integrations.Name` — that string is the
        // resolution key, so a "nicer" value here silently breaks object lookup. The
        // metadata name is the lowercase slug `mailchimp`, so this is the only passing
        // value. (The repo currently carries two naming conventions — 35 connectors use
        // a display name, 12 newer ones a lowercase slug. That split is real and worth
        // settling, but it is a fleet-wide decision, not a Mailchimp one; this test
        // asserts the invariant, not a preference.)
        it('IntegrationName getter is verbatim the metadata Integration name', () => {
            expect(connector.IntegrationName).toBe('mailchimp');
        });
    });

    describe('Capability declarations', () => {
        it('declared CRUD flags match expected shape', () => {
            expect(connector.SupportsCreate).toBe(true);
            expect(connector.SupportsUpdate).toBe(true);
            expect(connector.SupportsDelete).toBe(true);
            // FALSE on purpose. The connector implements no SearchRecords override, so
            // the base default stands. Declaring `true` here would be a capability lie —
            // callers gate on this flag, and the engine would route a search to a method
            // that does not exist. Mailchimp filtering flows through query params on the
            // listing path instead.
            expect(connector.SupportsSearch).toBe(false);
        });
    });
    describe('GetDefaultConfiguration', () => {
        it('should return a configuration object', () => {
            const config = connector.GetDefaultConfiguration();
            expect(config).toBeDefined();
            // Config null is acceptable for connectors that defer to runtime discovery
            if (config !== null) {
                expect(typeof config).toBe('object');
            }
        });
    });

});

/**
 * The subset of `MJ: Integration Objects` columns that CreateRecord actually reads. Declaring it
 * explicitly keeps the stub honest: if the connector starts reading another column, this shape
 * stops covering the code path and the omission is visible here rather than silently defaulting.
 */
type CreateOperationColumns = Pick<
    MJIntegrationObjectEntity,
    'CreateAPIPath' | 'CreateMethod' | 'CreateIDLocation' | 'CreateBodyShape' | 'CreateBodyKey'
>;

/**
 * Test connector that overrides the auth + HTTP transport seams so CreateRecord runs end-to-end
 * down to the BuildCreatedResult boundary without credentials or a real network call.
 *
 * It also stubs `GetCachedObject`. That method reads the IntegrationEngine's live catalog cache,
 * which only exists after a metadata load against a database — so without the stub these tests
 * die at cache lookup and never reach the boundary they exist to guard. The stub returns the
 * REAL shape of `lists/{list_id}/members` as declared in this connector's own metadata, so the
 * nested-parent-var branch of CreateRecord (the code v2 actually added) is what executes.
 */
class TestMailchimpConnector extends MailchimpConnector {
    public NextResponse: RESTResponse = { Status: 200, Body: {}, Headers: {} };

    protected override async Authenticate(): Promise<RESTAuthContext> {
        // Mailchimp's BuildHeaders reads auth.Config.ApiKey, so the mock auth must carry a Config.
        return { Token: 'test-token', DataCenter: 'us20', Config: { ApiKey: 'test-key' } } as RESTAuthContext;
    }

    protected override async MakeHTTPRequest(): Promise<RESTResponse> {
        return this.NextResponse;
    }

    protected override GetCachedObject(): MJIntegrationObjectEntity {
        const columns: CreateOperationColumns = {
            CreateAPIPath: '/lists/{list_id}/members',
            CreateMethod: 'POST',
            CreateIDLocation: 'body',
            CreateBodyShape: 'flat',
            CreateBodyKey: null
        };
        // A BaseEntity subclass cannot be constructed off a database; the connector only ever
        // reads the columns above, so a structural double is the faithful stand-in here.
        return columns as MJIntegrationObjectEntity;
    }
}

function createCtx(objectName: string, attributes: Record<string, unknown>): CreateRecordContext {
    return {
        CompanyIntegration: { IntegrationID: 'test-integration' },
        ContextUser: {},
        ObjectName: objectName,
        Attributes: attributes
    } as CreateRecordContext;
}

// Regression guard for the silent record-loss bug (HubSpot-association class, base helper
// BuildCreatedResult): a 2xx create whose response body carries no record id must fail loudly,
// not return Success:true and lose the record (duplicate creates on the next sync).
describe('MailchimpConnector create (response id validation)', () => {
    const nestedCtx = () => createCtx('lists/{list_id}/members', { list_id: 'abc', email_address: 'a@b.co' });

    it('returns Success=false on a 2xx create whose body has no id', async () => {
        const connector = new TestMailchimpConnector();
        connector.NextResponse = { Status: 200, Body: {}, Headers: {} };

        const result = await connector.CreateRecord(nestedCtx());

        expect(result.Success).toBe(false);
        expect(result.ErrorMessage).toContain('no record ID');
    });

    it('returns Success=true with the ExternalID when the body carries an id', async () => {
        const connector = new TestMailchimpConnector();
        connector.NextResponse = { Status: 200, Body: { id: 'abc123' }, Headers: {} };

        const result = await connector.CreateRecord(nestedCtx());

        expect(result.Success).toBe(true);
        expect(result.ExternalID).toBe('abc123');
    });
});
