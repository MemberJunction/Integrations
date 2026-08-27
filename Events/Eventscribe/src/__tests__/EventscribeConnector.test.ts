import { describe, it, expect } from 'vitest';
import type {
    RESTAuthContext,
    RESTResponse,
    PaginationType,
    FetchContext,
    CreateRecordContext,
    UpdateRecordContext,
    DeleteRecordContext,
} from '@memberjunction/integration-engine';
import type {
    MJCompanyIntegrationEntity,
    MJIntegrationObjectEntity,
    MJIntegrationObjectFieldEntity,
} from '@memberjunction/core-entities';
import { IntegrationEngineBase } from '@memberjunction/integration-engine-base';
import { EventscribeConnector, EventscribeAPIError } from '../EventscribeConnector.js';

// ─── Fixtures ─────────────────────────────────────────────────────────────────
//
// PROVENANCE: metadata-derived. Every SHAPE below (family tags, base URLs, `Method` dispatch, the
// `metadata{totalRecords,pages,page}` pagination envelope, the `{"error": ...}` envelope, the 404+[]
// empty case, the nesting container keys, the non-atomic array-body batch) traces to the frozen
// contract's own Configuration facts in
// `metadata/integrations/eventscribe/.eventscribe.integration.json`. Every VALUE is synthetic: no
// event id, no account id, no credential byte, no PII, no network, no mutation. This file is the
// T4/T5 mocked tier — the live round-trip tier is a separate harness.

/** `MJ: Integrations.Configuration` for eventscribe, reduced to the keys this connector reads. */
const INTEGRATION_CONFIGURATION = JSON.stringify({
    AuthFlow: 'api-key',
    AuthCredentialTransport: 'query-param',
    AuthCredentialParamLocation: 'query',
    AuthCredentialParamName: 'APIKey',
    AuthHeaderPattern: null,
    AuthMultiTenantParam: { name: 'eID', required: false },
    ReadContract: { methodParamName: 'Method', isRequiredOnEveryRequest: true },
    BaseURLsByFamily: [
        { family: 'eventscribe-web', baseUrl: 'https://mycadmium.com/webservices' },
        { family: 'asset', baseUrl: 'https://mycadmium.com/webservices' },
        { family: 'education-harvester', baseUrl: 'https://www.conferenceharvester.com/conferenceportal3/webservices' },
        { family: 'expo-harvester', baseUrl: 'https://www.conferenceharvester.com/conferenceportal3/webservices' },
        { family: 'abstract-scorecard', baseUrl: 'https://www.conferenceabstracts.com/webservices' },
    ],
    RateLimits: {
        standard: { requestsPerWindow: 1, windowMs: 1000, appliesTo: 'most methods, vendor-wide' },
        overrides: [
            {
                methods: ['getPresentationsWithPresenters', 'getAllExhibitorsWithBooth'],
                requestsPerWindow: 1,
                windowMs: 60000,
            },
        ],
    },
    BatchSemantics: {
        addUpdateAccount: {
            requestShape: 'JSON array in the raw POST body (single-object writes still require wrapping in a one-element array)',
            atomicity: 'non-atomic -- each record in the array is processed INDEPENDENTLY',
            partialFailureBehavior:
                'If ANY record in the batch fails, the overall HTTP response status is 400 -- but valid records in ' +
                'the SAME request are still created/updated.',
        },
        arrayBodyWriteConvention: {
            description:
                "The same 'raw JSON array in the POST body, one object per record, wrap a single record in a " +
                "1-element array' convention is documented verbatim for addUpdateExhibitor, addUpdateBooth, " +
                'addUpdateExhibitorStaff, and unassignBooth (expo-harvester family) in addition to addUpdateAccount.',
        },
    },
    ErrorContract: { shape: '{"error": "<human-readable message>"}', statusCodesObserved: [400, 404] },
    DiscoveryIsAuthoritative: false,
});

function makeIO(over: Partial<MJIntegrationObjectEntity> & { ID: string; Name: string }): MJIntegrationObjectEntity {
    return {
        DisplayName: over.Name,
        Description: 'fixture',
        Category: null,
        APIPath: '/eventScribeAPIs.asp',
        ResponseDataKey: null,
        DefaultPageSize: 100,
        SupportsPagination: false,
        PaginationType: 'None',
        SupportsWrite: false,
        SupportsCreate: false,
        SupportsUpdate: false,
        SupportsDelete: false,
        SupportsIncrementalSync: false,
        IncrementalWatermarkField: null,
        StableOrderingKey: null,
        ContentHashApplicable: true,
        SyncStrategy: 'FullPullHashDiff',
        Configuration: null,
        DefaultQueryParams: null,
        Status: 'Active',
        Sequence: 0,
        CreateAPIPath: null, CreateMethod: null, CreateBodyShape: null, CreateBodyKey: null, CreateIDLocation: null,
        UpdateAPIPath: null, UpdateMethod: null, UpdateBodyShape: null, UpdateBodyKey: null, UpdateIDLocation: null,
        DeleteAPIPath: null, DeleteMethod: null, DeleteIDLocation: null,
        ...over,
    } as unknown as MJIntegrationObjectEntity;
}

function makeIOF(over: Partial<MJIntegrationObjectFieldEntity> & { Name: string }): MJIntegrationObjectFieldEntity {
    return {
        ID: `iof-${over.Name}`,
        DisplayName: over.Name,
        Type: 'nvarchar',
        Length: 255, Precision: null, Scale: null, DefaultValue: null,
        IsPrimaryKey: false, IsRequired: false, IsReadOnly: false, IsUniqueKey: false,
        AllowsNull: true, Sequence: 0, Status: 'Active', Configuration: null,
        RelatedIntegrationObjectID: null, RelatedIntegrationObjectFieldName: null,
        ...over,
    } as unknown as MJIntegrationObjectFieldEntity;
}

const vendorRate = { requestsPerWindow: 1, windowMs: 1000, appliesTo: 'most methods, vendor-wide', scope: 'vendor-wide-default' };

// ── abstract-scorecard: paginated, `results` envelope, its own door ────────────
const authorIO = makeIO({
    ID: 'io-author', Name: 'Author', Category: 'abstract-scorecard',
    APIPath: '/api.asp', ResponseDataKey: 'results',
    SupportsPagination: true, PaginationType: 'PageNumber', DefaultPageSize: 100,
    StableOrderingKey: 'AuthorID',
    DefaultQueryParams: JSON.stringify({ Method: 'getAuthors' }),
    Configuration: JSON.stringify({
        family: 'abstract-scorecard',
        absoluteEndpoint: 'https://www.conferenceabstracts.com/webservices/api.asp',
        dispatch: { mechanism: 'query-param:Method', methodParamName: 'Method', methodValue: 'getAuthors' },
        accessPath: { doorOperation: 'getAuthors', doorObject: 'Author', nestingFieldPath: '', depth: 0, isArray: true },
        pagination: {
            paramName: 'Page', type: 'PageNumber', pageSize: 100,
            envelope: { totalRecordsKey: 'totalRecords', totalPagesKey: 'pages', currentPageKey: 'page', container: 'metadata' },
        },
        rateLimit: vendorRate,
    }),
});
const authorIOFs = [
    makeIOF({ Name: 'AuthorID', Type: 'int', IsPrimaryKey: true, IsUniqueKey: true, Sequence: 0 }),
    makeIOF({ Name: 'AuthorFirstName', Sequence: 1 }),
];

// ── asset: bare-array envelope, the documented 404+[] empty case ───────────────
const assetIO = makeIO({
    ID: 'io-asset', Name: 'Asset', Category: 'asset',
    APIPath: '/eventScribeAPIs.asp',
    StableOrderingKey: 'HarvesterID',
    DefaultQueryParams: JSON.stringify({ Method: 'Assets' }),
    Configuration: JSON.stringify({
        family: 'asset',
        absoluteEndpoint: 'https://mycadmium.com/webservices/eventScribeAPIs.asp',
        dispatch: { mechanism: 'query-param:Method', methodParamName: 'Method', methodValue: 'Assets' },
        accessPath: { doorOperation: 'Assets', doorObject: 'Asset', nestingFieldPath: '', depth: 0, isArray: true },
        rateLimit: vendorRate,
    }),
});
const assetIOFs = [
    makeIOF({ Name: 'HarvesterID', Type: 'int', IsPrimaryKey: true, Sequence: 0 }),
    makeIOF({ Name: 'PresentationTitle', Sequence: 1 }),
];

// ── asset nested leaves: depth-1 under the `Assets` door ──────────────────────
//
// Handout is the frozen contract's canonical NO-PRIMARY-KEY object. `Pdf` was withdrawn as a primary
// key upstream (T1 PkSourceMatrix rejected it as unevidenced — it is not ID-shaped and the source
// documents no own-identity field for this nested leaf); it REMAINS an ordinary nullable column, and
// `StableOrderingKey` was nulled because it pointed at that withdrawn key. The fixture mirrors that
// exactly, so the tests below exercise the contract's no-identity path rather than a key it retracted.
const handoutIO = makeIO({
    ID: 'io-handout', Name: 'Handout', Category: 'asset',
    APIPath: '/eventScribeAPIs.asp',
    StableOrderingKey: null,
    DefaultQueryParams: JSON.stringify({ Method: 'Assets' }),
    Configuration: JSON.stringify({
        family: 'asset',
        absoluteEndpoint: 'https://mycadmium.com/webservices/eventScribeAPIs.asp',
        dispatch: { mechanism: 'query-param:Method', methodParamName: 'Method', methodValue: 'Assets' },
        accessPath: { doorOperation: 'Assets', doorObject: 'Asset', nestingFieldPath: 'Asset → Handouts[]', depth: 1, isArray: true },
        nestedContainerKey: 'Handouts',
        parentObjectName: 'Asset',
        parentObjectIDFieldName: 'HarvesterID',
        rateLimit: vendorRate,
    }),
});
const handoutIOFs = [
    // NO IsPrimaryKey anywhere: `Pdf` is an ordinary column after the upstream PK withdrawal.
    makeIOF({ Name: 'Pdf', Sequence: 0 }),
    makeIOF({ Name: 'PresenterID', Type: 'int', Sequence: 1 }),
];

/** `nestingFieldPath` with NO explicit `nestedContainerKey`, and a NON-array container (isArray:false). */
const posterImagesIO = makeIO({
    ID: 'io-posterimages', Name: 'PosterImages', Category: 'asset',
    APIPath: '/eventScribeAPIs.asp',
    DefaultQueryParams: JSON.stringify({ Method: 'Assets' }),
    Configuration: JSON.stringify({
        family: 'asset',
        absoluteEndpoint: 'https://mycadmium.com/webservices/eventScribeAPIs.asp',
        dispatch: { mechanism: 'query-param:Method', methodParamName: 'Method', methodValue: 'Assets' },
        accessPath: { doorOperation: 'Assets', doorObject: 'Asset', nestingFieldPath: 'Asset → PosterImages', depth: 1, isArray: false },
        parentObjectName: 'Asset',
        parentObjectIDFieldName: 'HarvesterID',
        rateLimit: vendorRate,
    }),
});
const posterImagesIOFs = [makeIOF({ Name: 'Thumbnail', Sequence: 0 })];

// ── eventscribe-web: write surface + the record-key gate ──────────────────────
const accountIO = makeIO({
    ID: 'io-account', Name: 'Account', Category: 'eventscribe-web',
    APIPath: '/eventScribeAPIs.asp',
    SupportsWrite: true, SupportsCreate: true, SupportsUpdate: true, SupportsDelete: true,
    StableOrderingKey: 'AccountID',
    DefaultQueryParams: JSON.stringify({ Method: 'getAccount' }),
    CreateAPIPath: '/eventScribeAPIs.asp?Method=addUpdateAccount', CreateMethod: 'POST',
    CreateBodyShape: 'flat', CreateBodyKey: null, CreateIDLocation: 'n/a',
    UpdateAPIPath: '/eventScribeAPIs.asp?Method=addUpdateAccount&AccountID={ID}', UpdateMethod: 'POST',
    UpdateBodyShape: 'flat', UpdateBodyKey: null, UpdateIDLocation: 'path',
    DeleteAPIPath: '/eventScribeAPIs.asp?Method=cancelAccount&AccountID={ID}', DeleteMethod: 'GET',
    DeleteIDLocation: 'path',
    Configuration: JSON.stringify({
        family: 'eventscribe-web',
        absoluteEndpoint: 'https://mycadmium.com/webservices/eventScribeAPIs.asp',
        dispatch: { mechanism: 'query-param:Method', methodParamName: 'Method', methodValue: 'getAccount' },
        accessPath: { doorOperation: 'getAccount', doorObject: 'Account', nestingFieldPath: '', depth: 0, isArray: true },
        requiresRecordKeyToRead:
            "No bulk-list operation is documented for this object: its only read door ('getAccount') addresses ONE " +
            'record and requires a caller-supplied key.',
        rateLimit: vendorRate,
        writeOperation: { operationId: 'addUpdateAccount', verb: 'POST', idParam: 'AccountID', bodyShape: 'flat', createIDLocation: 'n/a' },
        deleteOperation: { operationId: 'cancelAccount', verb: 'GET', idParam: 'AccountID' },
    }),
});
const accountIOFs = [
    makeIOF({ Name: 'AccountID', Type: 'int', IsPrimaryKey: true, IsUniqueKey: true, Sequence: 0 }),
    makeIOF({ Name: 'EmailAddress', Sequence: 1 }),
];

// ── expo-harvester: the heavy 60 s door + a nested child + an id-bearing write ─
const exhibitorIO = makeIO({
    ID: 'io-exhibitor', Name: 'Exhibitor', Category: 'expo-harvester',
    APIPath: '/HarvesterJsonAPI.asp',
    SupportsWrite: true, SupportsCreate: true, SupportsUpdate: true,
    StableOrderingKey: 'ExhibitorID',
    DefaultQueryParams: JSON.stringify({ Method: 'getAllExhibitorsWithBooth' }),
    Configuration: JSON.stringify({
        family: 'expo-harvester',
        absoluteEndpoint: 'https://www.conferenceharvester.com/conferenceportal3/webservices/HarvesterJsonAPI.asp',
        dispatch: { mechanism: 'query-param:Method', methodParamName: 'Method', methodValue: 'getAllExhibitorsWithBooth' },
        accessPath: { doorOperation: 'getAllExhibitorsWithBooth', doorObject: 'Exhibitor', nestingFieldPath: '', depth: 0, isArray: true },
        rateLimit: { requestsPerWindow: 1, windowMs: 60000, scope: 'object-override' },
    }),
});
const exhibitorIOFs = [makeIOF({ Name: 'ExhibitorID', Type: 'int', IsPrimaryKey: true, Sequence: 0 })];

const boothIO = makeIO({
    ID: 'io-booth', Name: 'Booth', Category: 'expo-harvester',
    APIPath: '/HarvesterJsonAPI.asp',
    SupportsWrite: true, SupportsCreate: true, SupportsUpdate: true,
    StableOrderingKey: 'BoothID',
    DefaultQueryParams: JSON.stringify({ Method: 'getAllExhibitorsWithBooth' }),
    CreateAPIPath: '/HarvesterJsonAPI.asp?Method=addUpdateBooth', CreateMethod: 'POST',
    CreateBodyShape: 'flat', CreateBodyKey: null, CreateIDLocation: 'body',
    UpdateAPIPath: '/HarvesterJsonAPI.asp?Method=addUpdateBooth&BoothID={ID}', UpdateMethod: 'POST',
    UpdateBodyShape: 'flat', UpdateBodyKey: null, UpdateIDLocation: 'path',
    Configuration: JSON.stringify({
        family: 'expo-harvester',
        absoluteEndpoint: 'https://www.conferenceharvester.com/conferenceportal3/webservices/HarvesterJsonAPI.asp',
        dispatch: { mechanism: 'query-param:Method', methodParamName: 'Method', methodValue: 'getAllExhibitorsWithBooth' },
        accessPath: { doorOperation: 'getAllExhibitorsWithBooth', doorObject: 'Exhibitor', nestingFieldPath: 'Exhibitor → Booths[]', depth: 1, isArray: true },
        nestedContainerKey: 'Booths',
        parentObjectName: 'Exhibitor',
        parentObjectIDFieldName: 'ExhibitorID',
        rateLimit: vendorRate,
        writeOperation: { operationId: 'addUpdateBooth', verb: 'POST', idParam: 'BoothID', bodyShape: 'flat', createIDLocation: 'body' },
    }),
});
const boothIOFs = [
    makeIOF({ Name: 'BoothID', Type: 'int', IsPrimaryKey: true, Sequence: 0 }),
    makeIOF({ Name: 'BoothNumber', Sequence: 1 }),
];

/**
 * abstract-scorecard junction, depth-1 under the `getSingleSubmission` door. The contract's only
 * COMPOSITE-key object: `AuthorID` + `SubmissionID` together, in Sequence order.
 */
const submissionAuthorIO = makeIO({
    ID: 'io-submissionauthor', Name: 'SubmissionAuthor', Category: 'abstract-scorecard',
    APIPath: '/api.asp', ResponseDataKey: 'results',
    StableOrderingKey: 'AuthorID',
    DefaultQueryParams: JSON.stringify({ Method: 'getSubmissionIDsByAuthorID' }),
    Configuration: JSON.stringify({
        family: 'abstract-scorecard',
        absoluteEndpoint: 'https://www.conferenceabstracts.com/webservices/api.asp',
        dispatch: { mechanism: 'query-param:Method', methodParamName: 'Method', methodValue: 'getSubmissionIDsByAuthorID' },
        accessPath: { doorOperation: 'getSingleSubmission', doorObject: 'Submission', nestingFieldPath: 'Submission → Authors[]', depth: 1, isArray: true },
        nestedContainerKey: 'Authors',
        parentObjectName: 'Submission',
        parentObjectIDFieldName: 'SubmissionID',
        rateLimit: vendorRate,
    }),
});
const submissionAuthorIOFs = [
    makeIOF({ Name: 'AuthorID', Type: 'int', IsPrimaryKey: true, Sequence: 0 }),
    makeIOF({ Name: 'SubmissionID', Type: 'int', IsPrimaryKey: true, Sequence: 1 }),
    makeIOF({ Name: 'AuthorRole', Sequence: 2 }),
];

/** The door object the junction hangs off. */
const submissionIO = makeIO({
    ID: 'io-submission', Name: 'Submission', Category: 'abstract-scorecard',
    APIPath: '/api.asp', ResponseDataKey: 'results',
    StableOrderingKey: 'SubmissionID',
    DefaultQueryParams: JSON.stringify({ Method: 'getSubmissions' }),
    Configuration: JSON.stringify({
        family: 'abstract-scorecard',
        absoluteEndpoint: 'https://www.conferenceabstracts.com/webservices/api.asp',
        dispatch: { mechanism: 'query-param:Method', methodParamName: 'Method', methodValue: 'getSubmissions' },
        accessPath: { doorOperation: 'getSubmissions', doorObject: 'Submission', nestingFieldPath: '', depth: 0, isArray: true },
        rateLimit: vendorRate,
    }),
});
const submissionIOFs = [makeIOF({ Name: 'SubmissionID', Type: 'int', IsPrimaryKey: true, Sequence: 0 })];

// ── education-harvester: the per-OBJECT 60 s override (not in the integration list) ─
const presentationIO = makeIO({
    ID: 'io-presentation', Name: 'Presentation', Category: 'education-harvester',
    APIPath: '/HarvesterJsonAPI.asp',
    StableOrderingKey: 'PresentationID',
    DefaultQueryParams: JSON.stringify({ Method: 'getPresentations' }),
    Configuration: JSON.stringify({
        family: 'education-harvester',
        absoluteEndpoint: 'https://www.conferenceharvester.com/conferenceportal3/webservices/HarvesterJsonAPI.asp',
        dispatch: { mechanism: 'query-param:Method', methodParamName: 'Method', methodValue: 'getPresentations' },
        accessPath: { doorOperation: 'getPresentations', doorObject: 'Presentation', nestingFieldPath: '', depth: 0, isArray: true },
        rateLimit: { requestsPerWindow: 1, windowMs: 60000, scope: 'object-override' },
    }),
});
const presentationIOFs = [makeIOF({ Name: 'PresentationID', Type: 'int', IsPrimaryKey: true, Sequence: 0 })];

/**
 * Presentation WITH its declared delete columns. `deletePresentation` carries NO record identifier:
 * `DeleteIDLocation = 'n/a'`, no `{ID}` placeholder, `deleteOperation.idParam = null` — the frozen
 * contract's gap list records that the op "documents no ID parameter at all in its parameters array".
 */
const presentationDeleteIO = makeIO({
    ...presentationIO,
    ID: 'io-presentation', Name: 'Presentation',
    SupportsWrite: true, SupportsDelete: true,
    DeleteAPIPath: '/HarvesterJsonAPI.asp?Method=deletePresentation', DeleteMethod: 'GET', DeleteIDLocation: 'n/a',
    Configuration: JSON.stringify({
        family: 'education-harvester',
        absoluteEndpoint: 'https://www.conferenceharvester.com/conferenceportal3/webservices/HarvesterJsonAPI.asp',
        dispatch: { mechanism: 'query-param:Method', methodParamName: 'Method', methodValue: 'getPresentations' },
        accessPath: { doorOperation: 'getPresentations', doorObject: 'Presentation', nestingFieldPath: '', depth: 0, isArray: true },
        rateLimit: { requestsPerWindow: 1, windowMs: 60000, scope: 'object-override' },
        deleteOperation: { operationId: 'deletePresentation', verb: 'GET', idParam: null, switchedRemove: null },
    }),
});

/** Favorite's switched add-or-remove delete: also no id param, and the generic delete sends no body. */
const favoriteDeleteIO = makeIO({
    ID: 'io-favorite', Name: 'Favorite', Category: 'eventscribe-web',
    APIPath: '/eventScribeAPIs.asp',
    SupportsWrite: true, SupportsDelete: true,
    StableOrderingKey: 'id',
    DefaultQueryParams: JSON.stringify({ Method: 'getAccount' }),
    DeleteAPIPath: '/eventScribeAPIs.asp?Method=addRemoveFavorite&FavoriteMethod=Remove',
    DeleteMethod: 'POST', DeleteIDLocation: 'n/a',
    Configuration: JSON.stringify({
        family: 'eventscribe-web',
        absoluteEndpoint: 'https://mycadmium.com/webservices/eventScribeAPIs.asp',
        dispatch: { mechanism: 'query-param:Method', methodParamName: 'Method', methodValue: 'getAccount' },
        accessPath: { doorOperation: 'getAccount', doorObject: 'Account', nestingFieldPath: 'Account → Favorites[]', depth: 1, isArray: true },
        nestedContainerKey: 'Favorites',
        parentObjectName: 'Account',
        parentObjectIDFieldName: 'AccountID',
        rateLimit: vendorRate,
        deleteOperation: {
            operationId: 'addRemoveFavorite', verb: 'POST', idParam: null,
            switchedRemove: { param: 'FavoriteMethod', removeValue: 'Remove' },
        },
    }),
});
const favoriteDeleteIOFs = [makeIOF({ Name: 'id', Type: 'int', IsPrimaryKey: true, Sequence: 0 })];

/** An object with an `outOfScope` family that carries NO BaseURLsByFamily key — the last-resort path. */
const edgeRegIO = makeIO({
    ID: 'io-erfee', Name: 'ERFee', Category: 'edgereg-registration',
    APIPath: '/getFeesXML.jsp',
    Configuration: JSON.stringify({
        family: 'edgereg-registration',
        absoluteEndpoint: 'https://websvcs.edgereg.net/er/API/EROnline/getFeesXML.jsp',
        dispatch: { mechanism: 'distinct-filename', methodParamName: 'Method', methodValue: null },
        accessPath: { doorOperation: 'getFeesXML', doorObject: 'ERFee', nestingFieldPath: '', depth: 0, isArray: true },
        rateLimit: vendorRate,
    }),
});

/** An object whose Configuration names no family the table knows and no absoluteEndpoint. */
const unroutableIO = makeIO({ ID: 'io-unroutable', Name: 'Unroutable', Configuration: null });

// ─── Test doubles ─────────────────────────────────────────────────────────────

interface CapturedRequest {
    url: string;
    method: string;
    headers: Record<string, string>;
    body: unknown;
}

interface CannedResponse {
    match?: (req: { url: string; method: string; body: unknown }) => boolean;
    response: RESTResponse;
}

/**
 * The canonical Mocked<Connector> pattern: overrides ONLY the transport boundary (`rawRequest`), the
 * engine-cache seams and the clock. Every Eventscribe behaviour under test — per-family URL
 * resolution, the APIKey/Method/eID query assembly, pagination advance, the 404+[] empty case, the
 * error envelope, the nested door walk, the non-atomic batch — is the REAL connector code. Nothing
 * hits a live endpoint and nothing mutates.
 */
class MockedEventscribeConnector extends EventscribeConnector {
    public Captured: CapturedRequest[] = [];
    public Canned: CannedResponse[] = [];
    public Slept: number[] = [];
    public IOFixtures = new Map<string, MJIntegrationObjectEntity>();
    public IOFFixtures = new Map<string, MJIntegrationObjectFieldEntity[]>();
    public IntegrationConfigJSON: string | null = INTEGRATION_CONFIGURATION;

    protected override async rawRequest(
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown,
    ): Promise<RESTResponse> {
        this.Captured.push({ url, method, headers, body });
        const idx = this.Canned.findIndex(c => !c.match || c.match({ url, method, body }));
        if (idx < 0) throw new Error(`MockedEventscribeConnector: no canned response for ${method} ${url}`);
        const [canned] = this.Canned.splice(idx, 1);
        return canned.response;
    }

    /** Records the pacing DECISION instead of waiting for it — the assertion is the number, not the wall clock. */
    protected override async Sleep(ms: number): Promise<void> {
        this.Slept.push(ms);
    }

    protected override IntegrationConfigurationJSON(): string | null {
        return this.IntegrationConfigJSON;
    }

    protected override GetCachedObject(_integrationID: string, objectName: string): MJIntegrationObjectEntity {
        const io = this.IOFixtures.get(objectName);
        if (!io) throw new Error(`IntegrationObject not found: "${objectName}"`);
        return io;
    }
    protected override GetCachedFields(objectID: string): MJIntegrationObjectFieldEntity[] {
        return this.IOFFixtures.get(objectID) ?? [];
    }
    protected override getCachedObjects(_integrationID: string): MJIntegrationObjectEntity[] {
        return [...this.IOFixtures.values()];
    }
    protected override tryGetIntegrationID(): string | null {
        return 'int-eventscribe';
    }

    // ── Public seams for direct unit assertions ──
    public PublicNormalize(body: unknown, key: string | null): Record<string, unknown>[] {
        return this.NormalizeResponse(body, key);
    }
    public PublicBuildHeaders(auth: RESTAuthContext): Record<string, string> {
        return this.BuildHeaders(auth);
    }
    public PublicAuthenticate(ci: MJCompanyIntegrationEntity): Promise<RESTAuthContext> {
        return this.Authenticate(ci, contextUser);
    }
    public PublicGetBaseURL(ci: MJCompanyIntegrationEntity, auth: RESTAuthContext, objectName: string): string {
        return this.GetBaseURL(ci, auth, objectName);
    }
    public PublicExtractPagination(
        body: unknown,
        type: PaginationType,
        page: number,
        pageSize: number,
        obj: MJIntegrationObjectEntity,
    ): { HasMore: boolean; NextPage?: number; TotalRecords?: number } {
        return this.ExtractPaginationInfo(body, type, page, 0, pageSize, obj);
    }
    public PublicBuildPaginatedURL(basePath: string, obj: MJIntegrationObjectEntity, page: number): string {
        return this.BuildPaginatedURL(basePath, obj, page, 0, undefined, undefined);
    }
    public PublicSendRequest(auth: RESTAuthContext, url: string, method: string): Promise<RESTResponse> {
        return this.SendRequest(auth, url, method, this.BuildHeaders(auth));
    }
    public PublicMakeRequest(auth: RESTAuthContext, url: string, method: string): Promise<RESTResponse> {
        return this.MakeHTTPRequest(auth, url, method, this.BuildHeaders(auth));
    }
    /** Every URL the connector actually put on the wire, in order. */
    public URLs(): string[] {
        return this.Captured.map(c => c.url);
    }
    public LastBody(): unknown {
        return this.Captured[this.Captured.length - 1].body;
    }
}

const contextUser = { ID: 'test', Email: 'test@example.com', Name: 'test' } as unknown as Parameters<EventscribeConnector['TestConnection']>[1];
const FIXTURE_KEY = 'fixture-placeholder-not-a-real-credential';
const FIXTURE_EVENT = 'fixture-event-scope';

function makeCI(configuration: Record<string, unknown> = { APIKey: FIXTURE_KEY, eID: FIXTURE_EVENT }): MJCompanyIntegrationEntity {
    return {
        ID: 'ci-eventscribe',
        IntegrationID: 'int-eventscribe',
        Name: 'eventscribe',
        CredentialID: null,
        Configuration: JSON.stringify(configuration),
    } as unknown as MJCompanyIntegrationEntity;
}

function ok(body: unknown, headers: Record<string, string> = {}): RESTResponse {
    return { Status: 200, Body: body, Headers: headers };
}

function status(code: number, body: unknown): RESTResponse {
    return { Status: code, Body: body, Headers: {} };
}

function makeConnector(
    objects: Array<[MJIntegrationObjectEntity, MJIntegrationObjectFieldEntity[]]>,
): MockedEventscribeConnector {
    const c = new MockedEventscribeConnector();
    for (const [io, iofs] of objects) {
        c.IOFixtures.set(io.Name, io);
        c.IOFFixtures.set(io.ID, iofs);
    }
    return c;
}

function fetchCtx(ci: MJCompanyIntegrationEntity, objectName: string, over: Partial<FetchContext> = {}): FetchContext {
    return {
        CompanyIntegration: ci,
        ObjectName: objectName,
        WatermarkValue: null,
        BatchSize: 500,
        ContextUser: contextUser,
        ...over,
    } as FetchContext;
}

function crudCtx<T extends object>(ci: MJCompanyIntegrationEntity, objectName: string, extra: T): T & {
    CompanyIntegration: unknown; ContextUser: unknown; ObjectName: string;
} {
    return { CompanyIntegration: ci, ContextUser: contextUser, ObjectName: objectName, ...extra };
}

// ─── Tests ────────────────────────────────────────────────────────────────────

describe('EventscribeConnector — identity and declared capabilities', () => {
    it('returns the verbatim MJ: Integrations.Name from the IntegrationName getter', () => {
        expect(new EventscribeConnector().IntegrationName).toBe('eventscribe');
    });

    it('declares create, update and delete — the addUpdate*/cancel operations documented in metadata', () => {
        const c = new EventscribeConnector();
        expect(c.SupportsCreate).toBe(true);
        expect(c.SupportsUpdate).toBe(true);
        expect(c.SupportsDelete).toBe(true);
    });

    it('never claims authoritative discovery — Cadmium publishes no describe endpoint', () => {
        expect(new EventscribeConnector().DiscoveryIsAuthoritative).toBe(false);
    });

    it('declares batch write — the addUpdate* operations take a real JSON-array body', () => {
        expect(new EventscribeConnector().SupportsBatchWrite).toBe(true);
    });

    it('derives the rate-limit policy from Configuration.RateLimits, not a constant', () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        expect(c.RateLimitPolicy).toEqual(expect.objectContaining({ TokensPerSec: 1, Burst: 1 }));
        expect(c.MaxConcurrencyHint).toBe(1);
        // No metadata ⇒ NO policy invented here; the engine keeps its own default.
        c.IntegrationConfigJSON = null;
        expect(c.RateLimitPolicy).toBeNull();
        expect(c.MaxConcurrencyHint).toBeNull();
    });

    it('returns the StableOrderingKey the object metadata declares, and null for an unknown object', () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        expect(c.StableOrderingKey('Asset')).toBe('HarvesterID');
        expect(c.StableOrderingKey('NoSuchObject')).toBeNull();
    });
});

describe('EventscribeConnector — multi-host base URL resolution (per OBJECT, from metadata)', () => {
    const ci = makeCI();

    it('resolves a distinct base URL for every one of the five in-scope family tags', async () => {
        const c = makeConnector([
            [accountIO, accountIOFs], [assetIO, assetIOFs], [presentationIO, presentationIOFs],
            [exhibitorIO, exhibitorIOFs], [authorIO, authorIOFs],
        ]);
        const auth = await c.PublicAuthenticate(ci);
        expect(c.PublicGetBaseURL(ci, auth, 'Account')).toBe('https://mycadmium.com/webservices');
        expect(c.PublicGetBaseURL(ci, auth, 'Asset')).toBe('https://mycadmium.com/webservices');
        expect(c.PublicGetBaseURL(ci, auth, 'Presentation'))
            .toBe('https://www.conferenceharvester.com/conferenceportal3/webservices');
        expect(c.PublicGetBaseURL(ci, auth, 'Exhibitor'))
            .toBe('https://www.conferenceharvester.com/conferenceportal3/webservices');
        expect(c.PublicGetBaseURL(ci, auth, 'Author')).toBe('https://www.conferenceabstracts.com/webservices');
    });

    // Regression (hybrid e2e, mock mode): the mock harness redirects a connector by setting ONE
    // config key (`ConfigUrlKey`, default `BaseURL`). This connector resolved per family and never
    // consulted it, so every request escaped to the real mycadmium.com hosts and the run landed
    // 0 rows while otherwise looking healthy. `Configuration.BaseURL` is the explicit single-origin
    // override — unset in production, where the family map remains the real resolver.
    const withOverride = (origin: string): string =>
        JSON.stringify({ ...JSON.parse(INTEGRATION_CONFIGURATION as string), BaseURL: origin });

    it('routes EVERY family to Configuration.BaseURL when the single-origin override is set', async () => {
        const c = makeConnector([
            [accountIO, accountIOFs], [assetIO, assetIOFs], [presentationIO, presentationIOFs],
            [exhibitorIO, exhibitorIOFs], [authorIO, authorIOFs],
        ]);
        c.IntegrationConfigJSON = withOverride('http://127.0.0.1:61067');
        const auth = await c.PublicAuthenticate(ci);
        for (const obj of ['Account', 'Asset', 'Presentation', 'Exhibitor', 'Author']) {
            expect(c.PublicGetBaseURL(ci, auth, obj)).toBe('http://127.0.0.1:61067');
        }
    });

    it('override beats a per-object Configuration.baseUrl (no object may escape the mock)', async () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        c.IntegrationConfigJSON = withOverride('http://127.0.0.1:61067');
        const auth = await c.PublicAuthenticate(ci);
        expect(c.PublicGetBaseURL(ci, auth, 'Asset')).toBe('http://127.0.0.1:61067');
    });

    it('trims a trailing slash on the override', async () => {
        const c = makeConnector([[accountIO, accountIOFs]]);
        c.IntegrationConfigJSON = withOverride('http://127.0.0.1:61067/');
        const auth = await c.PublicAuthenticate(ci);
        expect(c.PublicGetBaseURL(ci, auth, 'Account')).toBe('http://127.0.0.1:61067');
    });

    // Regression: the override MUST be readable from the CONNECTION's Configuration, not only the
    // Integration row. A mock/sandbox harness patches CompanyIntegration.Configuration; an earlier
    // version read solely the Integration row, so the override never fired and every request went to
    // the real Cadmium hosts — a full e2e that ran green on 20 cells and synced 0 rows.
    it('reads the single-origin override from CompanyIntegration.Configuration (per connection)', async () => {
        const c = makeConnector([
            [accountIO, accountIOFs], [assetIO, assetIOFs], [presentationIO, presentationIOFs],
            [exhibitorIO, exhibitorIOFs], [authorIO, authorIOFs],
        ]);
        const ciWithOverride = makeCI({ APIKey: FIXTURE_KEY, eID: FIXTURE_EVENT, BaseURL: 'http://127.0.0.1:51285' });
        const auth = await c.PublicAuthenticate(ciWithOverride);
        for (const obj of ['Account', 'Asset', 'Presentation', 'Exhibitor', 'Author']) {
            expect(c.PublicGetBaseURL(ciWithOverride, auth, obj)).toBe('http://127.0.0.1:51285');
        }
    });

    it('per-connection override wins over the Integration-level one', async () => {
        const c = makeConnector([[accountIO, accountIOFs]]);
        c.IntegrationConfigJSON = withOverride('http://integration-level.invalid');
        const ciWithOverride = makeCI({ APIKey: FIXTURE_KEY, eID: FIXTURE_EVENT, BaseURL: 'http://127.0.0.1:51285' });
        const auth = await c.PublicAuthenticate(ciWithOverride);
        expect(c.PublicGetBaseURL(ciWithOverride, auth, 'Account')).toBe('http://127.0.0.1:51285');
    });

    it('ignores an empty/blank per-connection BaseURL and falls through', async () => {
        const c = makeConnector([[accountIO, accountIOFs]]);
        const ciBlank = makeCI({ APIKey: FIXTURE_KEY, eID: FIXTURE_EVENT, BaseURL: '   ' });
        const auth = await c.PublicAuthenticate(ciBlank);
        expect(c.PublicGetBaseURL(ciBlank, auth, 'Account')).toBe('https://mycadmium.com/webservices');
    });

    it('falls back to the family map when the override is absent (production path unchanged)', async () => {
        const c = makeConnector([[accountIO, accountIOFs], [authorIO, authorIOFs]]);
        const auth = await c.PublicAuthenticate(ci);
        expect(c.PublicGetBaseURL(ci, auth, 'Account')).toBe('https://mycadmium.com/webservices');
        expect(c.PublicGetBaseURL(ci, auth, 'Author')).toBe('https://www.conferenceabstracts.com/webservices');
    });

    it("keeps 'asset' and 'eventscribe-web' as SEPARATE tags even though they resolve to the same host", () => {
        const table = JSON.parse(INTEGRATION_CONFIGURATION).BaseURLsByFamily as Array<{ family: string; baseUrl: string }>;
        const families = table.map(e => e.family);
        expect(families).toContain('asset');
        expect(families).toContain('eventscribe-web');
        expect(table.find(e => e.family === 'asset')!.baseUrl)
            .toBe(table.find(e => e.family === 'eventscribe-web')!.baseUrl);
    });

    it('falls back to the absoluteEndpoint minus the declared APIPath when the family has no table entry', async () => {
        const c = makeConnector([[edgeRegIO, []]]);
        const auth = await c.PublicAuthenticate(ci);
        expect(c.PublicGetBaseURL(ci, auth, 'ERFee')).toBe('https://websvcs.edgereg.net/er/API/EROnline');
    });

    it('REFUSES to invent a host when no metadata resolves one', async () => {
        const c = makeConnector([[unroutableIO, []]]);
        const auth = await c.PublicAuthenticate(ci);
        expect(() => c.PublicGetBaseURL(ci, auth, 'Unroutable')).toThrow(/No base URL resolves/);
    });

    // EVERY request — flat read, nested door walk, connection test, batch write — must resolve its host
    // through the ONE `GetBaseURL` seam. A path that reached around it (calling the private resolver
    // directly) would keep obeying the declared vendor host while the rest of the connector honoured an
    // operator's override, sending half a sync to the wrong origin. Overriding the seam the way a
    // deployment (or an offline replay) does is the cheapest way to prove no path escapes it.
    describe('every request path resolves through the GetBaseURL seam', () => {
        /** Redirect the ORIGIN, preserve the connector's own path construction. */
        function redirectOrigin(c: MockedEventscribeConnector, origin: string): void {
            const target = c as unknown as { GetBaseURL: (...args: unknown[]) => string };
            const original = target.GetBaseURL.bind(c);
            target.GetBaseURL = (...args: unknown[]): string => {
                const resolved = new URL(original(...args));
                return new URL(origin).origin + resolved.pathname;
            };
        }

        it('honours the override on a FLAT (depth-0) read', async () => {
            const c = makeConnector([[assetIO, assetIOFs]]);
            redirectOrigin(c, 'https://gateway.example.invalid');
            c.Canned.push({ response: ok([]) });
            await c.FetchChanges(fetchCtx(ci, 'Asset'));
            expect(new URL(c.URLs()[0]).origin).toBe('https://gateway.example.invalid');
            expect(new URL(c.URLs()[0]).pathname).toBe('/webservices/eventScribeAPIs.asp');
        });

        it('honours the override on a NESTED door walk too — the door URL is not resolved separately', async () => {
            const c = makeConnector([[assetIO, assetIOFs], [handoutIO, handoutIOFs]]);
            redirectOrigin(c, 'https://gateway.example.invalid');
            c.Canned.push({ response: ok([{ HarvesterID: 11, Handouts: [{ Pdf: 'x' }] }]) });
            const result = await c.FetchChanges(fetchCtx(ci, 'Handout'));
            const url = new URL(c.URLs()[0]);
            expect(url.origin).toBe('https://gateway.example.invalid');
            expect(url.pathname).toBe('/webservices/eventScribeAPIs.asp');
            expect(url.searchParams.get('Method')).toBe('Assets');
            expect(result.Records).toHaveLength(1);
        });

        it('honours the override in TestConnection', async () => {
            const c = makeConnector([[authorIO, authorIOFs]]);
            redirectOrigin(c, 'https://gateway.example.invalid');
            c.Canned.push({ response: ok({ metadata: { totalRecords: 0, pages: 0, page: 1 }, results: [] }) });
            const result = await c.TestConnection(ci, contextUser);
            expect(result.Success).toBe(true);
            expect(new URL(c.URLs()[0]).origin).toBe('https://gateway.example.invalid');
        });
    });
});

describe('EventscribeConnector — credential transport (QUERY PARAM, never a header)', () => {
    const ci = makeCI();

    it('puts NOTHING auth-related in the headers', async () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        const headers = c.PublicBuildHeaders(await c.PublicAuthenticate(ci));
        expect(headers).toEqual({ Accept: 'application/json', 'Content-Type': 'application/json' });
        const joined = JSON.stringify(headers).toLowerCase();
        expect(joined).not.toContain('authorization');
        expect(joined).not.toContain('bearer');
        expect(joined).not.toContain(FIXTURE_KEY.toLowerCase());
    });

    it('assembles APIKey + Method + eID onto the query string of a real read', async () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        c.Canned.push({ response: ok([{ HarvesterID: 1, PresentationTitle: 'Fixture Session' }]) });
        await c.FetchChanges(fetchCtx(ci, 'Asset'));

        const url = new URL(c.URLs()[0]);
        expect(url.origin + url.pathname).toBe('https://mycadmium.com/webservices/eventScribeAPIs.asp');
        expect(url.searchParams.get('Method')).toBe('Assets');
        expect(url.searchParams.get('APIKey')).toBe(FIXTURE_KEY);
        expect(url.searchParams.get('eID')).toBe(FIXTURE_EVENT);
    });

    it('omits eID entirely when the connection carries no event scope', async () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        c.Canned.push({ response: ok([]) });
        await c.FetchChanges(fetchCtx(makeCI({ APIKey: FIXTURE_KEY }), 'Asset'));
        const url = new URL(c.URLs()[0]);
        expect(url.searchParams.get('APIKey')).toBe(FIXTURE_KEY);
        expect(url.searchParams.has('eID')).toBe(false);
    });

    it('refuses to run without an API key — the credential is mandatory on every request', async () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        await expect(c.PublicAuthenticate(makeCI({}))).rejects.toThrow(/No API key configured/);
    });

    it('refuses to guess the credential parameter name when metadata does not supply it', async () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        c.IntegrationConfigJSON = JSON.stringify({ ReadContract: { methodParamName: 'Method' } });
        const auth = await c.PublicAuthenticate(ci);
        await expect(c.PublicSendRequest(auth, 'https://mycadmium.com/webservices/eventScribeAPIs.asp?Method=Assets', 'GET'))
            .rejects.toThrow(/AuthCredentialParamName is not set/);
    });
});

describe('EventscribeConnector — NormalizeResponse envelopes', () => {
    const c = makeConnector([[assetIO, assetIOFs]]);

    it('treats a BARE JSON ARRAY as the record list (Asset / Expo shape)', () => {
        expect(c.PublicNormalize([{ HarvesterID: 1 }, { HarvesterID: 2 }], null)).toHaveLength(2);
    });

    it('applies ResponseDataKey only where the metadata declares one', () => {
        const body = { metadata: { totalRecords: 2, pages: 1, page: 1 }, results: [{ AuthorID: 7 }] };
        expect(c.PublicNormalize(body, 'results')).toEqual([{ AuthorID: 7 }]);
        // Same body, no declared key ⇒ the envelope itself is the single record, not a silent [].
        expect(c.PublicNormalize(body, null)).toEqual([body]);
    });

    it('treats a single record object as a one-element result (getAccount / getSingle* doors)', () => {
        expect(c.PublicNormalize({ AccountID: 5 }, null)).toEqual([{ AccountID: 5 }]);
    });

    it('never returns an error envelope as a record', () => {
        expect(c.PublicNormalize({ error: 'Invalid API Key' }, null)).toEqual([]);
    });

    it('returns an empty list for a null or scalar body rather than throwing', () => {
        expect(c.PublicNormalize(null, null)).toEqual([]);
        expect(c.PublicNormalize('not json', null)).toEqual([]);
    });
});

describe('EventscribeConnector — the documented error contract', () => {
    const ci = makeCI();

    it('treats HTTP 404 with a body of [] as an EMPTY RESULT, not an error', async () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        c.Canned.push({ response: status(404, []) });
        const result = await c.FetchChanges(fetchCtx(ci, 'Asset'));
        expect(result.Records).toEqual([]);
        expect(result.HasMore).toBe(false);
    });

    it('normalises that 404+[] to a 200 at the transport boundary so no path sees a failure', async () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        c.Canned.push({ response: status(404, []) });
        const auth = await c.PublicAuthenticate(ci);
        const response = await c.PublicSendRequest(auth, 'https://mycadmium.com/webservices/eventScribeAPIs.asp?Method=Assets', 'GET');
        expect(response.Status).toBe(200);
        expect(response.Body).toEqual([]);
    });

    it('does NOT swallow a 404 that carries a real error body', async () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        c.Canned.push({ response: status(404, { error: 'Event not found' }) });
        const auth = await c.PublicAuthenticate(ci);
        const response = await c.PublicSendRequest(auth, 'https://mycadmium.com/webservices/eventScribeAPIs.asp?Method=Assets', 'GET');
        expect(response.Status).toBe(404);
    });

    // ── REGRESSION: the read path must never assemble records out of a failed response ──
    //
    // The flat/paginated read the base class drives was the ONE transport path with no status gate of
    // its own, so a 500 body reached record assembly unclassified. These lock the gate: a failed read
    // RAISES the connector's own classified error, and never returns rows.

    it('RAISES on an HTTP 500 during a flat read instead of returning records', async () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        c.Canned.push({ response: status(500, { error: 'mock 500' }) });
        await expect(c.FetchChanges(fetchCtx(ci, 'Asset'))).rejects.toBeInstanceOf(EventscribeAPIError);
    });

    it('classifies that read-path 500 as a RETRYABLE server error, never as an empty success', async () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        c.Canned.push({ response: status(500, { error: 'Internal Server Error' }) });
        try {
            await c.FetchChanges(fetchCtx(ci, 'Asset'));
            throw new Error('expected the read to raise');
        } catch (err) {
            const apiError = err as EventscribeAPIError;
            expect(apiError).toBeInstanceOf(EventscribeAPIError);
            expect(apiError.Status).toBe(500);
            expect(apiError.Classification.Code).toBe('CONNECTOR_ERROR');
            expect(apiError.Classification.Severity).toBe('Critical');
            expect(apiError.Classification.Retryable).toBe(true);
            expect(apiError.Classification.Reason).toBe('server-error');
            expect(apiError.message).not.toContain(FIXTURE_KEY);
        }
    });

    it('RAISES on a MALFORMED 500 body too — a non-JSON payload is not a record source', async () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        c.Canned.push({ response: status(500, '<html>500 Internal Server Error</html>') });
        await expect(c.FetchChanges(fetchCtx(ci, 'Asset'))).rejects.toBeInstanceOf(EventscribeAPIError);
    });

    it('RAISES mid-pagination rather than returning the pages it already read', async () => {
        const c = makeConnector([[authorIO, authorIOFs]]);
        c.Canned.push({ response: ok({ metadata: { totalRecords: 200, pages: 2, page: 1 }, results: [{ AuthorID: 1 }] }) });
        c.Canned.push({ response: status(500, { error: 'mock 500' }) });
        await expect(c.FetchChanges(fetchCtx(ci, 'Author'))).rejects.toBeInstanceOf(EventscribeAPIError);
        // Both pages were attempted, and the partial first page never became a batch — so the
        // watermark cannot advance over a read that failed half way.
        expect(c.URLs()).toHaveLength(2);
    });

    it('leaves the NON-read verbs on the documented non-throwing path', async () => {
        // A create against the same vendor rejection still reports a failed CRUDResult (the generic
        // dispatch builds it from the status), and GetRecord still answers null on a 404.
        const c = makeConnector([[accountIO, accountIOFs]]);
        c.Canned.push({ response: status(400, { error: 'Invalid AccountID' }) });
        const created = await c.CreateRecord(crudCtx(ci, 'Account', { Attributes: { AccountEmail: 'fixture@example.org' } }));
        expect(created.Success).toBe(false);
        expect(created.StatusCode).toBe(400);

        c.Canned.push({ response: status(404, { error: 'not found' }) });
        const record = await c.GetRecord(crudCtx(ci, 'Account', { ExternalID: '404' }));
        expect(record).toBeNull();
    });

    it('treats a 200 carrying {"error": ...} as a FAILURE, never as an empty read', async () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        c.Canned.push({ response: ok({ error: 'Invalid API Key' }) });
        const auth = await c.PublicAuthenticate(ci);
        await expect(
            c.PublicMakeRequest(auth, 'https://mycadmium.com/webservices/eventScribeAPIs.asp?Method=Assets', 'GET'),
        ).rejects.toBeInstanceOf(EventscribeAPIError);
    });

    it('classifies that success-status error envelope and carries the vendor message', async () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        c.Canned.push({ response: ok({ error: 'Invalid API Key' }) });
        const auth = await c.PublicAuthenticate(ci);
        try {
            await c.PublicMakeRequest(auth, 'https://mycadmium.com/webservices/eventScribeAPIs.asp?Method=Assets', 'GET');
            throw new Error('expected a classified failure');
        } catch (err) {
            const apiError = err as EventscribeAPIError;
            expect(apiError.Status).toBe(200);
            expect(apiError.VendorMessage).toBe('Invalid API Key');
            expect(apiError.Classification.Reason).toBe('error-envelope-on-success-status');
            expect(apiError.Classification.Retryable).toBe(false);
            // The message must never carry the credential.
            expect(apiError.message).not.toContain(FIXTURE_KEY);
        }
    });

    it('maps the documented status codes to structured verdicts', () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        expect(c.ClassifyEventscribeResponse(400, 'bad request').Code).toBe('VALIDATION_ERROR');
        expect(c.ClassifyEventscribeResponse(429, undefined).Retryable).toBe(true);
        expect(c.ClassifyEventscribeResponse(503, undefined).Code).toBe('CONNECTOR_ERROR');
        expect(c.ClassifyEventscribeResponse(401, undefined).Code).toBe('CONFIGURATION_ERROR');
    });
});

describe('EventscribeConnector — PageNumber pagination (only where metadata declares it)', () => {
    const ci = makeCI();

    function page(n: number, pages: number, rows: Record<string, unknown>[]): unknown {
        return { metadata: { totalRecords: pages * 100, pages, page: n }, results: rows };
    }

    it('emits ONLY the declared page parameter — no invented page-size param', () => {
        const c = makeConnector([[authorIO, authorIOFs]]);
        expect(c.PublicBuildPaginatedURL('https://www.conferenceabstracts.com/webservices/api.asp', authorIO, 2))
            .toBe('https://www.conferenceabstracts.com/webservices/api.asp?Page=2');
        // A non-paginated object gets no parameters at all.
        expect(c.PublicBuildPaginatedURL('https://mycadmium.com/webservices/eventScribeAPIs.asp', assetIO, 2))
            .toBe('https://mycadmium.com/webservices/eventScribeAPIs.asp');
    });

    it('advances while the envelope reports more pages, and stops on the last one', () => {
        const c = makeConnector([[authorIO, authorIOFs]]);
        expect(c.PublicExtractPagination(page(1, 3, []), 'PageNumber', 1, 100, authorIO))
            .toEqual({ HasMore: true, NextPage: 2, TotalRecords: 300 });
        expect(c.PublicExtractPagination(page(3, 3, []), 'PageNumber', 3, 100, authorIO))
            .toEqual({ HasMore: false, NextPage: undefined, TotalRecords: 300 });
    });

    it('falls back to totalRecords when the envelope reports no page count', () => {
        const c = makeConnector([[authorIO, authorIOFs]]);
        const body = { metadata: { totalRecords: 250, page: 1 }, results: [] };
        expect(c.PublicExtractPagination(body, 'PageNumber', 1, 100, authorIO)).toEqual({ HasMore: true, NextPage: 2, TotalRecords: 250 });
    });

    it('reports HasMore:false rather than inventing a counter when no envelope is declared', () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        expect(c.PublicExtractPagination({ metadata: { pages: 9, page: 1 } }, 'PageNumber', 1, 100, assetIO))
            .toEqual({ HasMore: false });
    });

    it('walks the real page sequence end to end and carries Page + Method + APIKey on every request', async () => {
        const c = makeConnector([[authorIO, authorIOFs]]);
        c.Canned.push({ response: ok(page(1, 2, [{ AuthorID: 1, AuthorFirstName: 'A' }])) });
        c.Canned.push({ response: ok(page(2, 2, [{ AuthorID: 2, AuthorFirstName: 'B' }])) });

        const result = await c.FetchChanges(fetchCtx(ci, 'Author'));
        expect(result.Records.map(r => r.ExternalID)).toEqual(['1', '2']);

        const urls = c.URLs().map(u => new URL(u));
        expect(urls).toHaveLength(2);
        expect(urls.map(u => u.searchParams.get('Page'))).toEqual(['1', '2']);
        for (const u of urls) {
            expect(u.origin + u.pathname).toBe('https://www.conferenceabstracts.com/webservices/api.asp');
            expect(u.searchParams.get('Method')).toBe('getAuthors');
            expect(u.searchParams.get('APIKey')).toBe(FIXTURE_KEY);
        }
    });

    it('does NOT paginate an object whose metadata declares SupportsPagination=false', async () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        c.Canned.push({ response: ok([{ HarvesterID: 1 }]) });
        await c.FetchChanges(fetchCtx(ci, 'Asset'));
        expect(c.URLs()).toHaveLength(1);
        expect(new URL(c.URLs()[0]).searchParams.has('Page')).toBe(false);
    });
});

describe('EventscribeConnector — nested access-path walk (depth >= 1)', () => {
    const ci = makeCI();

    const assetDoorRows = [
        {
            HarvesterID: 11, PresentationTitle: 'Fixture Session One',
            Handouts: [
                { Pdf: 'https://example.org/fixture/one.pdf', PresenterID: 501, SiteCustomTag: 'cohort-a' },
                { Pdf: 'https://example.org/fixture/two.pdf', PresenterID: 502 },
            ],
            PosterImages: { Thumbnail: 'https://example.org/fixture/thumb.png' },
        },
        { HarvesterID: 12, PresentationTitle: 'Fixture Session Two', Handouts: [] },
    ];

    it('fires the DOOR operation, not a flat query for the nested object itself', async () => {
        const c = makeConnector([[assetIO, assetIOFs], [handoutIO, handoutIOFs]]);
        c.Canned.push({ response: ok(assetDoorRows) });
        await c.FetchChanges(fetchCtx(ci, 'Handout'));
        const url = new URL(c.URLs()[0]);
        expect(url.origin + url.pathname).toBe('https://mycadmium.com/webservices/eventScribeAPIs.asp');
        expect(url.searchParams.get('Method')).toBe('Assets');
        expect(url.searchParams.get('APIKey')).toBe(FIXTURE_KEY);
    });

    it('descends the declared container key and emits the LEAF rows, tagged with the parent key', async () => {
        const c = makeConnector([[assetIO, assetIOFs], [handoutIO, handoutIOFs]]);
        c.Canned.push({ response: ok(assetDoorRows) });
        const result = await c.FetchChanges(fetchCtx(ci, 'Handout'));

        expect(result.Records).toHaveLength(2);
        expect(result.Records.map(r => r.ObjectType)).toEqual(['Handout', 'Handout']);
        expect(result.Records[0].Fields.HarvesterID).toBe(11);
        expect(result.Records[1].Fields.HarvesterID).toBe(11);
        expect(result.HasMore).toBe(false);
    });

    it('passes the FULL source row through to ExternalRecord.Fields — no projection', async () => {
        const c = makeConnector([[assetIO, assetIOFs], [handoutIO, handoutIOFs]]);
        c.Canned.push({ response: ok(assetDoorRows) });
        const result = await c.FetchChanges(fetchCtx(ci, 'Handout'));
        // `SiteCustomTag` is declared by NO IntegrationObjectField — it must still reach Fields so the
        // framework's custom-column capture can see it.
        expect(result.Records[0].Fields).toEqual(expect.objectContaining({
            Pdf: 'https://example.org/fixture/one.pdf',
            PresenterID: 501,
            SiteCustomTag: 'cohort-a',
            HarvesterID: 11,
        }));
    });

    it('handles a NON-array container (accessPath.isArray=false) as a single leaf record', async () => {
        const c = makeConnector([[assetIO, assetIOFs], [posterImagesIO, posterImagesIOFs]]);
        c.Canned.push({ response: ok(assetDoorRows) });
        const result = await c.FetchChanges(fetchCtx(ci, 'PosterImages'));
        expect(result.Records).toHaveLength(1);
        expect(result.Records[0].Fields.Thumbnail).toBe('https://example.org/fixture/thumb.png');
        // Container key derived from `nestingFieldPath` alone — no explicit nestedContainerKey declared.
        expect(result.Records[0].Fields.HarvesterID).toBe(11);
    });

    it('walks a different family/host with the same machinery (Booth under the Exhibitor door)', async () => {
        const c = makeConnector([[exhibitorIO, exhibitorIOFs], [boothIO, boothIOFs]]);
        c.Canned.push({
            response: ok([{ ExhibitorID: 900, Booths: [{ BoothID: 4001, BoothNumber: '12A' }] }]),
        });
        const result = await c.FetchChanges(fetchCtx(ci, 'Booth'));
        const url = new URL(c.URLs()[0]);
        expect(url.origin + url.pathname)
            .toBe('https://www.conferenceharvester.com/conferenceportal3/webservices/HarvesterJsonAPI.asp');
        expect(url.searchParams.get('Method')).toBe('getAllExhibitorsWithBooth');
        expect(result.Records).toHaveLength(1);
        expect(result.Records[0].ExternalID).toBe('4001');
        expect(result.Records[0].Fields.ExhibitorID).toBe(900);
    });

    it('warns loudly (rather than silently succeeding) when no door record carried the container', async () => {
        const c = makeConnector([[assetIO, assetIOFs], [handoutIO, handoutIOFs]]);
        c.Canned.push({ response: ok([{ HarvesterID: 13, PresentationTitle: 'No handouts' }]) });
        const result = await c.FetchChanges(fetchCtx(ci, 'Handout'));
        expect(result.Records).toEqual([]);
        expect(result.Warnings?.[0].Code).toBe('EMPTY_NESTED_CONTAINER');
    });

    it('falls back to a content-hash identity for an object the contract declares NO primary key for', async () => {
        const c = makeConnector([[assetIO, assetIOFs], [handoutIO, handoutIOFs]]);
        c.Canned.push({ response: ok([{ HarvesterID: 11, Handouts: [{ PresenterID: 777 }] }]) });
        const result = await c.FetchChanges(fetchCtx(ci, 'Handout'));
        expect(result.Records).toHaveLength(1);
        // No PK declared ⇒ no idempotent-identity claim: a stable content hash, never a key value.
        expect(result.Records[0].ExternalID).toEqual(expect.any(String));
        expect(result.Records[0].ExternalID.length).toBeGreaterThan(0);
        expect(result.Records[0].ExternalID).not.toBe('777');
    });

    it('does NOT claim identity from `Pdf` — the contract withdrew that primary key', async () => {
        const c = makeConnector([[assetIO, assetIOFs], [handoutIO, handoutIOFs]]);
        c.Canned.push({ response: ok(assetDoorRows) });
        const result = await c.FetchChanges(fetchCtx(ci, 'Handout'));
        // `Pdf` survives as an ordinary column and is still passed through in full...
        expect(result.Records[0].Fields.Pdf).toBe('https://example.org/fixture/one.pdf');
        // ...but it is NOT the record's identity any more.
        expect(result.Records[0].ExternalID).not.toBe('https://example.org/fixture/one.pdf');
        // Two distinct leaves still get two distinct identities via the content hash.
        expect(result.Records[0].ExternalID).not.toBe(result.Records[1].ExternalID);
    });

    it('never substitutes a guessed `ID` column when the object declares no primary key', async () => {
        const c = makeConnector([[assetIO, assetIOFs], [handoutIO, handoutIOFs]]);
        // A tenant payload that happens to carry a column literally named `ID`. The declared field set
        // marks NOTHING as a primary key, so this must NOT become the record's identity — substituting
        // it would be exactly the unproven guess the upstream PK withdrawal removed.
        c.Canned.push({ response: ok([{ HarvesterID: 11, Handouts: [{ ID: 424242, Pdf: 'x.pdf' }] }]) });
        const result = await c.FetchChanges(fetchCtx(ci, 'Handout'));
        expect(result.Records).toHaveLength(1);
        expect(result.Records[0].ExternalID).not.toBe('424242');
        expect(result.Records[0].Fields.ID).toBe(424242);   // still passed through, just not claimed
    });

    it('reports NO stable ordering key for a PK-less object (the column was nulled upstream)', () => {
        const c = makeConnector([[assetIO, assetIOFs], [handoutIO, handoutIOFs]]);
        expect(c.StableOrderingKey('Handout')).toBeNull();
        // ...while an object whose key SURVIVED the withdrawal still reports it.
        expect(c.StableOrderingKey('Asset')).toBe('HarvesterID');
    });

    it('still builds a key-joined identity for an object whose PK the contract KEPT', async () => {
        const c = makeConnector([[exhibitorIO, exhibitorIOFs], [boothIO, boothIOFs]]);
        c.Canned.push({ response: ok([{ ExhibitorID: 900, Booths: [{ BoothID: 4001 }] }]) });
        const result = await c.FetchChanges(fetchCtx(ci, 'Booth'));
        expect(result.Records[0].ExternalID).toBe('4001');
    });

    it('joins a COMPOSITE key with "|" in declared Sequence order', async () => {
        const c = makeConnector([[submissionIO, submissionIOFs], [submissionAuthorIO, submissionAuthorIOFs]]);
        c.Canned.push({
            response: ok({ results: [{ SubmissionID: 3001, Authors: [{ AuthorID: 77, AuthorRole: 'Presenting' }] }] }),
        });
        const result = await c.FetchChanges(fetchCtx(ci, 'SubmissionAuthor'));
        expect(result.Records).toHaveLength(1);
        // AuthorID (Sequence 0) then SubmissionID (Sequence 1) — the parent key the nested payload omits
        // is tagged on from the door row, so both halves are present.
        expect(result.Records[0].ExternalID).toBe('77|3001');
        expect(result.Records[0].Fields.AuthorRole).toBe('Presenting');
    });

    it('degrades a composite key to a content hash when one half is missing — a soft key never rejects a row', async () => {
        const c = makeConnector([[submissionIO, submissionIOFs], [submissionAuthorIO, submissionAuthorIOFs]]);
        // Door row carries no SubmissionID at all, so the junction's second key half cannot be filled.
        c.Canned.push({ response: ok({ results: [{ Authors: [{ AuthorID: 77 }] }] }) });
        const result = await c.FetchChanges(fetchCtx(ci, 'SubmissionAuthor'));
        expect(result.Records).toHaveLength(1);
        expect(result.Records[0].ExternalID).not.toContain('|');
        expect(result.Records[0].ExternalID.length).toBeGreaterThan(0);
    });
});

describe('EventscribeConnector — the record-key gate', () => {
    const ci = makeCI();

    it('refuses to enumerate an object whose only door needs a caller-supplied record key', async () => {
        const c = makeConnector([[accountIO, accountIOFs]]);
        const result = await c.FetchChanges(fetchCtx(ci, 'Account'));
        expect(result.Records).toEqual([]);
        expect(result.Warnings?.[0].Code).toBe('REQUIRES_RECORD_KEY');
        // Crucially: it never fires a request it knows cannot enumerate, and never invents a key param.
        expect(c.URLs()).toHaveLength(0);
    });

    it('propagates the gate to a nested object whose DOOR object is the key-requiring one', async () => {
        const favoriteIO = makeIO({
            ID: 'io-favorite', Name: 'Favorite', Category: 'eventscribe-web',
            DefaultQueryParams: JSON.stringify({ Method: 'getAccount' }),
            Configuration: JSON.stringify({
                family: 'eventscribe-web',
                absoluteEndpoint: 'https://mycadmium.com/webservices/eventScribeAPIs.asp',
                dispatch: { methodParamName: 'Method', methodValue: 'getAccount' },
                accessPath: { doorOperation: 'getAccount', doorObject: 'Account', nestingFieldPath: 'Account → Favorites[]', depth: 1, isArray: true },
                nestedContainerKey: 'Favorites',
                parentObjectName: 'Account',
                parentObjectIDFieldName: 'AccountID',
            }),
        });
        const c = makeConnector([[accountIO, accountIOFs], [favoriteIO, []]]);
        const result = await c.FetchChanges(fetchCtx(ci, 'Favorite'));
        expect(result.Warnings?.[0].Code).toBe('REQUIRES_RECORD_KEY');
        expect(c.URLs()).toHaveLength(0);
    });
});

describe('EventscribeConnector — vendor rate-limit spacing (from metadata, never a constant)', () => {
    const ci = makeCI();

    it('spaces two calls to the same standard method by the vendor-wide window', async () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        c.Canned.push({ response: ok([]) }, { response: ok([]) });
        await c.FetchChanges(fetchCtx(ci, 'Asset'));
        await c.FetchChanges(fetchCtx(ci, 'Asset'));
        expect(c.Slept).toHaveLength(1);
        expect(c.Slept[0]).toBeGreaterThan(0);
        expect(c.Slept[0]).toBeLessThanOrEqual(1000);
    });

    it('honours the 60 s override for a method named in Integration.Configuration.RateLimits.overrides', async () => {
        const c = makeConnector([[exhibitorIO, exhibitorIOFs]]);
        c.Canned.push({ response: ok([]) }, { response: ok([]) });
        await c.FetchChanges(fetchCtx(ci, 'Exhibitor'));
        await c.FetchChanges(fetchCtx(ci, 'Exhibitor'));
        expect(c.Slept).toHaveLength(1);
        expect(c.Slept[0]).toBeGreaterThan(1000);
        expect(c.Slept[0]).toBeLessThanOrEqual(60000);
    });

    it('honours a PER-OBJECT rateLimit override the integration-level list does not name', async () => {
        const c = makeConnector([[presentationIO, presentationIOFs]]);
        c.Canned.push({ response: ok([]) }, { response: ok([]) });
        await c.FetchChanges(fetchCtx(ci, 'Presentation'));
        await c.FetchChanges(fetchCtx(ci, 'Presentation'));
        expect(c.Slept).toHaveLength(1);
        expect(c.Slept[0]).toBeGreaterThan(1000);
    });

    it('applies the documented window only to the hosts the metadata declares', async () => {
        const c = makeConnector([[exhibitorIO, exhibitorIOFs]]);
        const auth = await c.PublicAuthenticate(ci);
        // Two calls to the SAME heavy method on a host that appears NOWHERE in BaseURLsByFamily or any
        // object's absoluteEndpoint. The vendor's 60 s allowance describes Cadmium's own service; this
        // connector holds no documented allowance for another operator's host and must not invent one.
        const foreign = 'https://gateway.example.invalid/webservices/HarvesterJsonAPI.asp?Method=getAllExhibitorsWithBooth';
        c.Canned.push({ response: ok([]) }, { response: ok([]) });
        await c.PublicSendRequest(auth, foreign, 'GET');
        await c.PublicSendRequest(auth, foreign, 'GET');
        expect(c.Slept).toEqual([]);

        // Same method, same connector, DECLARED host ⇒ the documented spacing is honoured.
        const declared = 'https://www.conferenceharvester.com/conferenceportal3/webservices/HarvesterJsonAPI.asp?Method=getAllExhibitorsWithBooth';
        c.Canned.push({ response: ok([]) }, { response: ok([]) });
        await c.PublicSendRequest(auth, declared, 'GET');
        await c.PublicSendRequest(auth, declared, 'GET');
        expect(c.Slept).toHaveLength(1);
        expect(c.Slept[0]).toBeGreaterThan(1000);
    });

    it('paces EVERY host when the metadata names none — the conservative default', async () => {
        const c = makeConnector([[unroutableIO, []]]);
        c.IntegrationConfigJSON = JSON.stringify({
            AuthCredentialParamName: 'APIKey',
            ReadContract: { methodParamName: 'Method' },
            RateLimits: { standard: { requestsPerWindow: 1, windowMs: 1000 } },
        });
        const auth = await c.PublicAuthenticate(ci);
        const url = 'https://anything.example.invalid/x.asp?Method=whatever';
        c.Canned.push({ response: ok([]) }, { response: ok([]) });
        await c.PublicSendRequest(auth, url, 'GET');
        await c.PublicSendRequest(auth, url, 'GET');
        expect(c.Slept).toHaveLength(1);
    });

    it('paces nothing at all when the metadata declares no window', async () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        c.IntegrationConfigJSON = JSON.stringify({
            AuthCredentialParamName: 'APIKey',
            ReadContract: { methodParamName: 'Method' },
            BaseURLsByFamily: [{ family: 'asset', baseUrl: 'https://mycadmium.com/webservices' }],
        });
        c.Canned.push({ response: ok([]) }, { response: ok([]) });
        await c.FetchChanges(fetchCtx(ci, 'Asset'));
        await c.FetchChanges(fetchCtx(ci, 'Asset'));
        expect(c.Slept).toEqual([]);
    });
});

describe('EventscribeConnector — write path (generic dispatch + the array-body convention)', () => {
    const ci = makeCI();

    it('builds the create request from the IntegrationObject columns, wrapped in a one-element array', async () => {
        const c = makeConnector([[accountIO, accountIOFs]]);
        c.Canned.push({ response: ok([{ AccountID: 4242, Transaction: 'INSERT' }]) });
        const result = await c.CreateRecord(crudCtx(ci, 'Account', { Attributes: { EmailAddress: 'fixture@example.org' } }) as CreateRecordContext);

        const url = new URL(c.URLs()[0]);
        expect(c.Captured[0].method).toBe('POST');
        expect(url.origin + url.pathname).toBe('https://mycadmium.com/webservices/eventScribeAPIs.asp');
        expect(url.searchParams.get('Method')).toBe('addUpdateAccount');
        expect(url.searchParams.get('APIKey')).toBe(FIXTURE_KEY);
        // Configuration.BatchSemantics: "single-object writes still require wrapping in a one-element array".
        expect(c.LastBody()).toEqual([{ EmailAddress: 'fixture@example.org' }]);
        // CreateIDLocation is 'n/a', but when the vendor DOES echo the record's own declared key the
        // connector uses it — 'n/a' means "no id is promised", not "ignore one that arrived".
        expect(result.Success).toBe(true);
        expect(result.ExternalID).toBe('4242');
    });

    it("fails LOUDLY when an 'n/a' create really does come back without a trackable id", async () => {
        const c = makeConnector([[accountIO, accountIOFs]]);
        c.Canned.push({ response: ok([{ Transaction: 'INSERT' }]) });
        const result = await c.CreateRecord(crudCtx(ci, 'Account', { Attributes: { EmailAddress: 'fixture@example.org' } }) as CreateRecordContext);
        // Never reported green: an untrackable create causes duplicate creates on the next sync.
        expect(result.Success).toBe(false);
        expect(result.ErrorMessage).toMatch(/no record ID/);
    });

    it("reads the created id from the vendor's own key name when IDLocation is 'body'", async () => {
        const c = makeConnector([[boothIO, boothIOFs]]);
        c.Canned.push({ response: ok([{ BoothID: 4001, BoothNumber: '12A' }]) });
        const result = await c.CreateRecord(crudCtx(ci, 'Booth', { Attributes: { BoothNumber: '12A' } }) as CreateRecordContext);
        expect(new URL(c.URLs()[0]).searchParams.get('Method')).toBe('addUpdateBooth');
        expect(result.Success).toBe(true);
        expect(result.ExternalID).toBe('4001');
    });

    it('substitutes the external id into the declared update path template', async () => {
        const c = makeConnector([[accountIO, accountIOFs]]);
        c.Canned.push({ response: ok([{ AccountID: 4242 }]) });
        const result = await c.UpdateRecord(crudCtx(ci, 'Account', {
            ExternalID: '4242', Attributes: { EmailAddress: 'fixture@example.org' },
        }) as UpdateRecordContext);
        const url = new URL(c.URLs()[0]);
        expect(url.searchParams.get('Method')).toBe('addUpdateAccount');
        expect(url.searchParams.get('AccountID')).toBe('4242');
        expect(result.Success).toBe(true);
    });

    it('routes the delete through the declared cancel operation and verb', async () => {
        const c = makeConnector([[accountIO, accountIOFs]]);
        c.Canned.push({ response: ok({ Transaction: 'CANCELLED' }) });
        const result = await c.DeleteRecord(crudCtx(ci, 'Account', { ExternalID: '4242' }) as DeleteRecordContext);
        const url = new URL(c.URLs()[0]);
        expect(c.Captured[0].method).toBe('GET');
        expect(url.searchParams.get('Method')).toBe('cancelAccount');
        expect(url.searchParams.get('AccountID')).toBe('4242');
        expect(result.Success).toBe(true);
    });

    it('REFUSES a delete whose declared operation carries no record identifier — nothing goes on the wire', async () => {
        // Presentation's delete: `DeleteIDLocation = 'n/a'`, no {ID} placeholder, and
        // `deleteOperation.idParam = null` (the vendor documents no ID parameter at all). Firing that
        // path would be an UNIDENTIFIED destructive request carrying only the key, the event scope and
        // the Method name.
        const c = makeConnector([[presentationDeleteIO, presentationIOFs]]);
        const result = await c.DeleteRecord(crudCtx(ci, 'Presentation', { ExternalID: '9001' }) as DeleteRecordContext);
        expect(result.Success).toBe(false);
        expect(result.ErrorMessage).toMatch(/no record identifier/);
        expect(c.Captured).toHaveLength(0);   // the request was never sent
        expect(result.StatusCode).toBe(0);    // ...so there is no HTTP status to misreport
    });

    it('REFUSES the switched add-or-remove delete too — the base sends no body to identify the record', async () => {
        const c = makeConnector([[favoriteDeleteIO, favoriteDeleteIOFs]]);
        const result = await c.DeleteRecord(crudCtx(ci, 'Favorite', { ExternalID: '55' }) as DeleteRecordContext);
        expect(result.Success).toBe(false);
        expect(c.Captured).toHaveLength(0);
    });

    it('does NOT refuse a delete that declares an identifier — the guard is narrow', async () => {
        const c = makeConnector([[accountIO, accountIOFs]]);
        c.Canned.push({ response: ok({ Transaction: 'CANCELLED' }) });
        const result = await c.DeleteRecord(crudCtx(ci, 'Account', { ExternalID: '4242' }) as DeleteRecordContext);
        expect(result.Success).toBe(true);
        expect(c.Captured).toHaveLength(1);
    });

    it('reports a vendor rejection as a failed CRUDResult carrying the vendor message', async () => {
        const c = makeConnector([[accountIO, accountIOFs]]);
        c.Canned.push({ response: status(400, { error: 'EmailAddress is required' }) });
        const result = await c.CreateRecord(crudCtx(ci, 'Account', { Attributes: {} }) as CreateRecordContext);
        expect(result.Success).toBe(false);
        expect(result.StatusCode).toBe(400);
        expect(result.ErrorMessage).toBe('EmailAddress is required');
    });

    it('refuses a write for an object whose metadata declares no write columns', async () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        await expect(c.CreateRecord(crudCtx(ci, 'Asset', { Attributes: {} }) as CreateRecordContext))
            .rejects.toThrow(/CreateRecord not supported/);
    });
});

describe('EventscribeConnector — NON-ATOMIC batch write (HTTP 400 with partial success)', () => {
    const ci = makeCI();

    it('sends ONE request carrying the whole array', async () => {
        const c = makeConnector([[accountIO, accountIOFs]]);
        c.Canned.push({ response: ok([{ AccountID: 1 }, { AccountID: 2 }]) });
        await c.BatchCreateRecords([
            crudCtx(ci, 'Account', { Attributes: { EmailAddress: 'a@example.org' } }) as CreateRecordContext,
            crudCtx(ci, 'Account', { Attributes: { EmailAddress: 'b@example.org' } }) as CreateRecordContext,
        ]);
        expect(c.Captured).toHaveLength(1);
        expect(c.LastBody()).toEqual([{ EmailAddress: 'a@example.org' }, { EmailAddress: 'b@example.org' }]);
    });

    it('inspects the PER-RECORD results on a 400 instead of failing the whole batch', async () => {
        const c = makeConnector([[accountIO, accountIOFs]]);
        c.Canned.push({
            response: status(400, [
                { AccountID: 1, Transaction: 'UPDATE' },
                { error: 'EmailAddress is not a valid address' },
                { AccountID: 3, Transaction: 'INSERT' },
            ]),
        });
        const results = await c.BatchCreateRecords([
            crudCtx(ci, 'Account', { Attributes: { EmailAddress: 'a@example.org' } }) as CreateRecordContext,
            crudCtx(ci, 'Account', { Attributes: { EmailAddress: 'not-an-address' } }) as CreateRecordContext,
            crudCtx(ci, 'Account', { Attributes: { EmailAddress: 'c@example.org' } }) as CreateRecordContext,
        ]);
        expect(results.map(r => r.Success)).toEqual([true, false, true]);
        expect(results[1].ErrorMessage).toBe('EmailAddress is not a valid address');
        expect(results.every(r => r.StatusCode === 400)).toBe(true);
    });

    it('keeps the per-record results POSITIONAL when they arrive under a container key', async () => {
        const c = makeConnector([[boothIO, boothIOFs]]);
        c.Canned.push({
            response: status(400, { results: [{ BoothID: 4001 }, { error: 'Booth number already taken' }] }),
        });
        const results = await c.BatchCreateRecords([
            crudCtx(ci, 'Booth', { Attributes: { BoothNumber: '12A' } }) as CreateRecordContext,
            crudCtx(ci, 'Booth', { Attributes: { BoothNumber: '12A' } }) as CreateRecordContext,
        ]);
        expect(results.map(r => r.Success)).toEqual([true, false]);
        expect(results[0].ExternalID).toBe('4001');
    });

    it('degrades CONSERVATIVELY when the per-record results cannot be located', async () => {
        const c = makeConnector([[accountIO, accountIOFs]]);
        c.Canned.push({ response: status(400, { error: 'Malformed request' }) });
        const results = await c.BatchCreateRecords([
            crudCtx(ci, 'Account', { Attributes: { EmailAddress: 'a@example.org' } }) as CreateRecordContext,
            crudCtx(ci, 'Account', { Attributes: { EmailAddress: 'b@example.org' } }) as CreateRecordContext,
        ]);
        // No record is ever claimed successful on a guess; addUpdate* is an upsert, so a re-push is idempotent.
        expect(results.map(r => r.Success)).toEqual([false, false]);
        expect(results[0].ErrorMessage).toBe('Malformed request');
    });

    it('falls back to the per-record path for an update whose declared URL carries an {ID} template', async () => {
        const c = makeConnector([[accountIO, accountIOFs]]);
        c.Canned.push({ response: ok([{ AccountID: 1 }]) }, { response: ok([{ AccountID: 2 }]) });
        const results = await c.BatchUpdateRecords([
            crudCtx(ci, 'Account', { ExternalID: '1', Attributes: { EmailAddress: 'a@example.org' } }) as UpdateRecordContext,
            crudCtx(ci, 'Account', { ExternalID: '2', Attributes: { EmailAddress: 'b@example.org' } }) as UpdateRecordContext,
        ]);
        expect(results.map(r => r.Success)).toEqual([true, true]);
        // Two requests, each carrying its own record key — never a batch with the id stripped out of the URL.
        expect(c.Captured).toHaveLength(2);
        expect(c.URLs().map(u => new URL(u).searchParams.get('AccountID'))).toEqual(['1', '2']);
    });

    it('routes a mixed-object batch to each object\'s own host and operation', async () => {
        const c = makeConnector([[accountIO, accountIOFs], [boothIO, boothIOFs]]);
        c.Canned.push(
            { match: r => r.url.includes('addUpdateAccount'), response: ok([{ AccountID: 1 }]) },
            { match: r => r.url.includes('addUpdateBooth'), response: ok([{ BoothID: 4001 }]) },
        );
        const results = await c.BatchCreateRecords([
            crudCtx(ci, 'Account', { Attributes: { EmailAddress: 'a@example.org' } }) as CreateRecordContext,
            crudCtx(ci, 'Booth', { Attributes: { BoothNumber: '12A' } }) as CreateRecordContext,
        ]);
        expect(results.map(r => r.Success)).toEqual([true, true]);
        const hosts = c.URLs().map(u => new URL(u).host).sort();
        expect(hosts).toEqual(['mycadmium.com', 'www.conferenceharvester.com']);
    });
});

describe('EventscribeConnector — read-one goes through the READ door, never the write Method', () => {
    const ci = makeCI();

    /** GetRecordContext is CRUDContext + ExternalID. */
    function getCtx(objectName: string, externalID: string) {
        return crudCtx(ci, objectName, { ExternalID: externalID });
    }

    it('dispatches the DECLARED read door with the record key on the query string', async () => {
        const c = makeConnector([[accountIO, accountIOFs]]);
        c.Canned = [{ response: ok([{ AccountID: '1', EmailAddress: 'a@example.test' }]) }];

        const rec = await c.GetRecord(getCtx('Account', '1'));

        const url = c.URLs()[0];
        expect(url).toContain('Method=getAccount');
        expect(url).toContain('AccountID=1');
        expect(url).toContain(`APIKey=${FIXTURE_KEY}`);
        expect(c.Captured[0].method).toBe('GET');
        expect(rec?.ExternalID).toBe('1');
        // FULL source row reaches Fields — never a projection.
        expect(rec?.Fields).toEqual({ AccountID: '1', EmailAddress: 'a@example.test' });
    });

    it('NEVER dispatches the write Method on a read — the generic path would have sent addUpdateAccount', async () => {
        const c = makeConnector([[accountIO, accountIOFs]]);
        c.Canned = [{ response: ok([{ AccountID: '1' }]) }];

        await c.GetRecord(getCtx('Account', '1'));

        // UpdateAPIPath names addUpdateAccount; nothing carrying it may reach the wire on a read.
        expect(accountIO.UpdateAPIPath).toContain('addUpdateAccount');
        expect(c.URLs().some(u => u.includes('addUpdateAccount'))).toBe(false);
    });

    it('returns null for a 404 rather than throwing', async () => {
        const c = makeConnector([[accountIO, accountIOFs]]);
        c.Canned = [{ response: status(404, { error: 'Account not found.' }) }];
        expect(await c.GetRecord(getCtx('Account', '1'))).toBeNull();
    });

    it('returns null when the door answers with no rows', async () => {
        const c = makeConnector([[accountIO, accountIOFs]]);
        c.Canned = [{ response: ok([]) }];
        expect(await c.GetRecord(getCtx('Account', '1'))).toBeNull();
    });

    it('surfaces a 200 carrying an error envelope as a failure, not as "record not found"', async () => {
        const c = makeConnector([[accountIO, accountIOFs]]);
        c.Canned = [{ response: ok({ error: 'Invalid API key.' }) }];
        await expect(c.GetRecord(getCtx('Account', '1'))).rejects.toBeInstanceOf(EventscribeAPIError);
    });

    it('REFUSES a nested object — a depth-1 leaf has no single-record door of its own', async () => {
        const c = makeConnector([[handoutIO, handoutIOFs]]);
        await expect(c.GetRecord(getCtx('Handout', 'x'))).rejects.toThrow(/no read door of its own/i);
        expect(c.Captured).toHaveLength(0);
    });

    it('falls back to the single DECLARED primary key when no write/delete idParam is declared', async () => {
        // Author declares no writeOperation/deleteOperation, but DOES declare exactly one PK.
        const c = makeConnector([[authorIO, authorIOFs]]);
        c.Canned = [{ response: ok({ results: [{ AuthorID: '7' }] }) }];
        const rec = await c.GetRecord(getCtx('Author', '7'));
        expect(c.URLs()[0]).toContain('AuthorID=7');
        expect(rec?.ExternalID).toBe('7');
    });

    it('REFUSES a COMPOSITE-key object — no multi-key single-record door is documented', async () => {
        // A depth-0 object carrying the contract's composite key, so the depth gate does NOT mask this.
        const compositeIO = makeIO({
            ID: 'io-composite', Name: 'Composite', Category: 'abstract-scorecard',
            APIPath: '/api.asp', ResponseDataKey: 'results',
            DefaultQueryParams: JSON.stringify({ Method: 'getSubmissions' }),
            Configuration: JSON.stringify({
                family: 'abstract-scorecard',
                dispatch: { methodParamName: 'Method', methodValue: 'getSubmissions' },
                accessPath: { doorOperation: 'getSubmissions', doorObject: 'Composite', nestingFieldPath: '', depth: 0, isArray: true },
                rateLimit: vendorRate,
            }),
        });
        const c = makeConnector([[compositeIO, submissionAuthorIOFs]]);
        await expect(c.GetRecord(getCtx('Composite', '1|2'))).rejects.toThrow(/no record-key parameter is declared/i);
        expect(c.Captured).toHaveLength(0);
    });

    it('REFUSES a nested composite junction on the depth gate, before any key question arises', async () => {
        const c = makeConnector([[submissionAuthorIO, submissionAuthorIOFs], [submissionIO, submissionIOFs]]);
        await expect(c.GetRecord(getCtx('SubmissionAuthor', '1|2'))).rejects.toThrow(/no read door of its own/i);
        expect(c.Captured).toHaveLength(0);
    });

    it('REFUSES a PK-less object rather than substituting a guessed identifier column', async () => {
        const keylessIO = makeIO({
            ID: 'io-keyless', Name: 'Keyless', Category: 'asset',
            DefaultQueryParams: JSON.stringify({ Method: 'Assets' }),
            Configuration: JSON.stringify({
                family: 'asset',
                dispatch: { methodParamName: 'Method', methodValue: 'Assets' },
                accessPath: { doorOperation: 'Assets', doorObject: 'Asset', nestingFieldPath: '', depth: 0, isArray: true },
                rateLimit: vendorRate,
            }),
        });
        const c = makeConnector([[keylessIO, [makeIOF({ Name: 'Pdf' })]]]);
        await expect(c.GetRecord(getCtx('Keyless', 'x'))).rejects.toThrow(/no record-key parameter is declared/i);
        expect(c.Captured).toHaveLength(0);
    });

    it('resolves the read through the per-OBJECT host, like every other request', async () => {
        const c = makeConnector([[boothIO, boothIOFs], [exhibitorIO, exhibitorIOFs]]);
        c.Canned = [{ response: ok([{ ExhibitorID: '5' }]) }];
        await c.GetRecord(getCtx('Exhibitor', '5'));
        expect(c.URLs()[0]).toContain('https://www.conferenceharvester.com/conferenceportal3/webservices/HarvesterJsonAPI.asp');
    });
});

describe('EventscribeConnector — TestConnection', () => {
    const ci = makeCI();

    it('probes the first enumerable door and reports success on a 2xx', async () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        c.Canned.push({ response: ok([]) });
        const result = await c.TestConnection(ci, contextUser);
        expect(result.Success).toBe(true);
        expect(new URL(c.URLs()[0]).searchParams.get('Method')).toBe('Assets');
    });

    it('SKIPS an object whose door needs a caller-supplied record key', async () => {
        const c = makeConnector([[accountIO, accountIOFs], [assetIO, assetIOFs]]);
        c.Canned.push({ response: ok([]) });
        const result = await c.TestConnection(ci, contextUser);
        expect(result.Success).toBe(true);
        expect(new URL(c.URLs()[0]).searchParams.get('Method')).toBe('Assets');
    });

    it('reports failure — without leaking the credential — when the vendor rejects the key', async () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        c.Canned.push({ response: ok({ error: 'Invalid API Key' }) });
        const result = await c.TestConnection(ci, contextUser);
        expect(result.Success).toBe(false);
        expect(result.Message).not.toContain(FIXTURE_KEY);
        expect(result.Message).not.toContain(FIXTURE_EVENT);
    });

    it('says so plainly when no ACTIVE objects are seeded', async () => {
        const c = makeConnector([]);
        const result = await c.TestConnection(ci, contextUser);
        expect(result.Success).toBe(false);
        expect(result.Message).toMatch(/No ACTIVE IntegrationObjects/);
    });
});

describe('EventscribeConnector — no catalog lives in the connector source', () => {
    /** Seeds the engine cache the INHERITED discovery reads, so the test exercises the real source. */
    function seedEngine(objects: MJIntegrationObjectEntity[], fields: MJIntegrationObjectFieldEntity[]): void {
        IntegrationEngineBase.Instance.SeedForTesting({
            Integrations: [{ ID: 'int-eventscribe', Name: 'eventscribe', Configuration: INTEGRATION_CONFIGURATION }],
            IntegrationObjects: objects.map(o => ({ ...(o as unknown as Record<string, unknown>), IntegrationID: 'int-eventscribe' })),
            IntegrationObjectFields: fields.map(f => ({ ...(f as unknown as Record<string, unknown>) })),
        } as Parameters<typeof IntegrationEngineBase.Instance.SeedForTesting>[0]);
    }

    it('discovers objects from the engine-cached Declared rows, not a literal list', async () => {
        const c = makeConnector([[assetIO, assetIOFs], [authorIO, authorIOFs]]);
        seedEngine([assetIO, authorIO], [...assetIOFs, ...authorIOFs]);
        const objects = await c.DiscoverObjects(makeCI(), contextUser);
        expect(objects.map(o => o.Name).sort()).toEqual(['Asset', 'Author']);

        // Remove one from the METADATA and discovery follows — proving the source is the metadata,
        // not a frozen array in the .ts.
        seedEngine([assetIO], assetIOFs);
        const after = await c.DiscoverObjects(makeCI(), contextUser);
        expect(after.map(o => o.Name)).toEqual(['Asset']);
    });

    it('discovers fields from the engine-cached Declared IOF rows', async () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        seedEngine([assetIO], assetIOFs);
        const fields = await c.DiscoverFields(makeCI(), 'Asset', contextUser);
        expect(fields.map(f => f.Name)).toEqual(['HarvesterID', 'PresentationTitle']);
        // The base surfaces a declared PK as a unique key on this projection.
        expect(fields.find(f => f.Name === 'HarvesterID')?.IsUniqueKey).toBe(true);
    });
});

// ── EdgeReg-shaped fixtures: XML on the wire, a declared server-side time window ──
//
// PROVENANCE: metadata-derived. The frozen contract emits the EdgeReg objects in full (catalog
// completeness) but seeds them `Status='Disabled'` with `Configuration.responseFormat='xml'`, a
// different credential model, and the corpus's ONLY documented watermark contract
// (`watermark.startParam`/`endParam`). These fixtures exercise what the connector does if an
// operator activates one anyway. Values are synthetic.

const erRegistrantIO = makeIO({
    ID: 'io-erregistrant', Name: 'ERRegistrant', Category: 'edgereg-registration',
    APIPath: '/getRegistrationInformationXML.jsp',
    Status: 'Disabled',
    SupportsIncrementalSync: true, IncrementalWatermarkField: 'RegistrationTime',
    SyncStrategy: 'WatermarkIncremental', StableOrderingKey: 'RegistrantID',
    Configuration: JSON.stringify({
        family: 'edgereg-registration',
        absoluteEndpoint: 'https://websvcs.edgereg.net/er/API/EROnline/getRegistrationInformationXML.jsp',
        dispatch: { mechanism: 'distinct-filename', methodParamName: 'Method', methodValue: null },
        accessPath: { doorOperation: 'getRegistrationInformationXML', doorObject: 'ERRegistrant', nestingFieldPath: '', depth: 0, isArray: true },
        rateLimit: vendorRate,
        responseFormat: 'xml',
        outOfScope: { family: 'edgereg-registration', emittedButDisabled: true, credentialModel: 'AccountToken (+ ActivityToken)' },
        watermark: {
            field: 'RegistrationTime', startParam: 'StartTime', endParam: 'EndTime',
            valueFormat: '05/29/2022 14:00:00', urlEncodeRequired: true,
        },
    }),
});
const erRegistrantIOFs = [
    makeIOF({ Name: 'RegistrantID', Type: 'int', IsPrimaryKey: true, Sequence: 0 }),
    makeIOF({ Name: 'RegistrationTime', Type: 'datetime', Sequence: 1 }),
];

/** The SAME watermark contract, but declared `json` — proves the window is generic, not EdgeReg-specific. */
const jsonWatermarkIO = makeIO({
    ...(erRegistrantIO as unknown as Record<string, unknown>),
    ID: 'io-jsonwatermark', Name: 'JsonWatermarked', Status: 'Active',
    Configuration: JSON.stringify({
        family: 'abstract-scorecard',
        absoluteEndpoint: 'https://www.conferenceabstracts.com/webservices/api.asp',
        dispatch: { mechanism: 'query-param:Method', methodParamName: 'Method', methodValue: 'getSubmissions' },
        accessPath: { doorOperation: 'getSubmissions', doorObject: 'JsonWatermarked', nestingFieldPath: '', depth: 0, isArray: true },
        rateLimit: vendorRate,
        responseFormat: 'json',
        watermark: { field: 'RegistrationTime', startParam: 'StartTime', endParam: 'EndTime' },
    }),
    APIPath: '/api.asp',
    DefaultQueryParams: JSON.stringify({ Method: 'getSubmissions' }),
} as Partial<MJIntegrationObjectEntity> & { ID: string; Name: string });

describe('EventscribeConnector — refuses a wire format it cannot parse (no silent zero rows)', () => {
    const ci = makeCI();

    it('never fires a request for an object whose metadata declares a non-JSON responseFormat', async () => {
        const c = makeConnector([[erRegistrantIO, erRegistrantIOFs]]);
        const result = await c.FetchChanges(fetchCtx(ci, 'ERRegistrant'));
        expect(result.Records).toEqual([]);
        expect(c.Captured).toHaveLength(0);
    });

    it('reports a STRUCTURED warning naming the declared format and credential model', async () => {
        const c = makeConnector([[erRegistrantIO, erRegistrantIOFs]]);
        const result = await c.FetchChanges(fetchCtx(ci, 'ERRegistrant'));
        const warning = (result.Warnings ?? [])[0];
        expect(warning?.Code).toBe('UNSUPPORTED_WIRE_FORMAT');
        expect(warning?.Data?.responseFormat).toBe('xml');
        expect(String(warning?.Data?.credentialModel)).toContain('AccountToken');
        expect(warning?.Message).toContain('ERRegistrant');
    });

    it('lets a JSON object through untouched — the gate keys on the DECLARED format, not the family', async () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        c.Canned = [{ response: ok([{ HarvesterID: 1, PresentationTitle: 'x' }]) }];
        const result = await c.FetchChanges(fetchCtx(ci, 'Asset'));
        expect(result.Records).toHaveLength(1);
        expect((result.Warnings ?? []).length).toBe(0);
    });
});

describe('EventscribeConnector — declared incremental window + max-seen watermark', () => {
    const ci = makeCI();

    it('appends the DECLARED startParam when the engine supplies a watermark', async () => {
        const c = makeConnector([[jsonWatermarkIO, erRegistrantIOFs]]);
        c.Canned = [{ response: ok([{ RegistrantID: 1, RegistrationTime: '2024-03-01T00:00:00Z' }]) }];
        await c.FetchChanges(fetchCtx(ci, 'JsonWatermarked', { WatermarkValue: '2024-02-01T00:00:00Z' }));
        const url = c.URLs()[0];
        expect(url).toContain('StartTime=2024-02-01T00%3A00%3A00Z');
        // The declared endParam is deliberately NOT sent — an upper bound would drop late writes.
        expect(url).not.toContain('EndTime=');
        // The credential + dispatch params still ride the same URL.
        expect(url).toContain('Method=getSubmissions');
        expect(url).toContain(`APIKey=${FIXTURE_KEY}`);
    });

    it('sends NO window parameter on a full pull (no watermark yet)', async () => {
        const c = makeConnector([[jsonWatermarkIO, erRegistrantIOFs]]);
        c.Canned = [{ response: ok([{ RegistrantID: 1, RegistrationTime: '2024-03-01T00:00:00Z' }]) }];
        await c.FetchChanges(fetchCtx(ci, 'JsonWatermarked'));
        expect(c.URLs()[0]).not.toContain('StartTime=');
    });

    it('advances the watermark to the MAX value seen in the batch', async () => {
        const c = makeConnector([[jsonWatermarkIO, erRegistrantIOFs]]);
        c.Canned = [{
            response: ok([
                { RegistrantID: 1, RegistrationTime: '2024-03-01T00:00:00Z' },
                { RegistrantID: 2, RegistrationTime: '2024-05-09T12:00:00Z' },
                { RegistrantID: 3, RegistrationTime: '2024-04-02T00:00:00Z' },
            ]),
        }];
        const result = await c.FetchChanges(fetchCtx(ci, 'JsonWatermarked', { WatermarkValue: '2024-02-01T00:00:00Z' }));
        expect(result.NewWatermarkValue).toBe('2024-05-09T12:00:00Z');
    });

    it('never moves the watermark BACKWARDS when the batch is all older records', async () => {
        const c = makeConnector([[jsonWatermarkIO, erRegistrantIOFs]]);
        c.Canned = [{ response: ok([{ RegistrantID: 1, RegistrationTime: '2024-01-01T00:00:00Z' }]) }];
        const result = await c.FetchChanges(fetchCtx(ci, 'JsonWatermarked', { WatermarkValue: '2024-02-01T00:00:00Z' }));
        expect(result.NewWatermarkValue).toBeUndefined();
    });

    it('leaves the watermark UNCHANGED when the batch throws mid-iteration', async () => {
        const c = makeConnector([[jsonWatermarkIO, erRegistrantIOFs]]);
        c.Canned = [{ response: status(500, { error: 'upstream exploded' }) }];
        await expect(c.FetchChanges(fetchCtx(ci, 'JsonWatermarked', { WatermarkValue: '2024-02-01T00:00:00Z' })))
            .rejects.toThrow();
    });

    it('emits NO watermark for a full-pull object, however date-like its columns look', async () => {
        const c = makeConnector([[assetIO, assetIOFs]]);
        c.Canned = [{ response: ok([{ HarvesterID: 1, StartDateTime: '2024-05-09T12:00:00Z' }]) }];
        const result = await c.FetchChanges(fetchCtx(ci, 'Asset'));
        expect(result.NewWatermarkValue).toBeUndefined();
    });
});
