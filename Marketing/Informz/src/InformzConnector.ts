/**
 * InformzConnector — Higher Logic Thrive Marketing Professional (formerly Informz).
 *
 * ONE DOOR, TWO DOCUMENTS. The vendor's Advanced API (AAPI) is a WCF SOAP service with EXACTLY one
 * operation, `PostInformzMessage(x: string)` (verified against the pinned WSDL/xsd0 snapshot). Its
 * single argument is a fully-formed XML DOCUMENT in namespace `http://partner.informz.net/aapi/2009/08/`,
 * of one of two types:
 *   • `<GridRequest>`   → READ.  The object is selected by the `<Grid type="...">` TOKEN (never a URL path).
 *   • `<ActionRequest>` → WRITE. The operation is selected by the action element name.
 *
 * SOAP rides over HTTP here: this class extends `BaseRESTIntegrationConnector` — the engine exports only
 * `BaseIntegrationConnector` and `BaseRESTIntegrationConnector`; there is NO `BaseSOAPIntegrationConnector`.
 *
 * WHY the read/CRUD paths are overridden (the CRUD-routing rule's "genuinely idiosyncratic" branch):
 * the base's generic per-operation dispatch builds `baseURL + APIPath` and issues a GET with query-string
 * pagination. On this vendor EVERY object shares ONE URL and the object/operation lives INSIDE a POSTed
 * XML document, so `FetchChanges` / `GetRecord` / `CreateRecord` / `UpdateRecord` are overridden to build
 * that document. Everything they need is read from METADATA (IO `Configuration.gridType`,
 * `StableOrderingKey`, `IncrementalWatermarkField`, `Create*`/`Update*` columns, and the declared IOF set) —
 * no object catalog, no field catalog and no constraint is baked into this file.
 *
 * Auth: there is NO token exchange, NO Authorization header and NO crypto — the credential triple travels
 * IN THE DOCUMENT BODY as `<Password>`, `<Brand id="NNNN">Brand Name</Brand>`, `<User>` (the `<User>` vs
 * `<Username>` discrepancy is resolved to `<User>` by the frozen contract's
 * `DocumentShapes.userVsUsernameDiscrepancy` verdict). Higher Logic additionally validates the Brand against
 * a REGISTERED EGRESS IP, so a correct credential still fails from an unregistered host. Documents are
 * SCRUBBED before any logging (see {@link InformzConnector.ScrubDocument}).
 *
 * Discovery: there is no describe-all endpoint anywhere in this API, so the object/field universe comes from
 * the DECLARED metadata (case 1 — credential-free, inherited from the REST base's cache-driven
 * `DiscoverObjects`/`DiscoverFields`), and a live credential is ADDITIVE ONLY: `IntrospectSchema` unions the
 * declared set with a live sample so a brand's TENANT-DEFINED demographics / extended demographics /
 * interests reach the schema. `DiscoveryIsAuthoritative` stays FALSE — nothing may ever be deactivated from
 * a discovery absence on this vendor.
 */
import { RegisterClass } from '@memberjunction/global';
import { Metadata, type UserInfo } from '@memberjunction/core';
import type {
    MJCompanyIntegrationEntity,
    MJCredentialEntity,
    MJIntegrationObjectEntity,
    MJIntegrationObjectFieldEntity,
} from '@memberjunction/core-entities';
import { IntegrationEngineBase } from '@memberjunction/integration-engine-base';
import { z } from 'zod';
import {
    BaseIntegrationConnector,
    BaseRESTIntegrationConnector,
    ClassifyError,
    computeContentHash,
    serializeKeyValue,
    type ConnectionTestResult,
    type CRUDResult,
    type CreateRecordContext,
    type ExternalRecord,
    type FetchBatchResult,
    type FetchContext,
    type GetRecordContext,
    type PaginationState,
    type PaginationType,
    type RESTAuthContext,
    type RESTResponse,
    type SourceSchemaInfo,
    type SyncErrorCode,
    type UpdateRecordContext,
} from '@memberjunction/integration-engine';
import { mergeDeclaredWithSampledFields } from '@memberjunction/connector-schema-merge';

// ─── Wire constants (transport mechanics only — NOT a catalog) ───────────────────────────────────
// Every value below is a PROTOCOL constant proven by the pinned WSDL/xsd0 snapshot; the vendor's object
// and field universe lives in metadata, never here.

/** Fallback AAPI namespace when the Integration row carries no `Configuration.Transport.namespace`. */
const DEFAULT_NAMESPACE = 'http://partner.informz.net/aapi/2009/08/';
/** Fallback region endpoints (Integration `Configuration.Transport.endpoints` overrides these). */
const DEFAULT_ENDPOINTS: Readonly<Record<string, string>> = Object.freeze({
    us: 'https://partner.informz.net/aapi/InformzService.svc',
    ca: 'https://partner.informz.ca/aapi/InformzService.svc',
    test: 'https://partnertest.informz.net/aapi/InformzService.svc',
});
/** The service's single operation (wsdl:operation name, xsd0 element name). */
const SOAP_OPERATION = 'PostInformzMessage';
/** The single operation's argument element name (xsd0: `<xs:element name="x" type="xs:string"/>`). */
const SOAP_ARGUMENT_ELEMENT = 'x';
/** The single operation's result element name (xsd0). */
const SOAP_RESULT_ELEMENT = 'PostInformzMessageResult';
/** SOAPAction for the one operation (wsdl:binding → soap:operation soapAction). */
const SOAP_ACTION = 'http://partner.informz.net/aapi/2009/08/IInformzWebServiceContract/PostInformzMessage';
/** Documented hard ceiling: "Each request can return a maximum of 1,000 rows." */
const VENDOR_MAX_ROWS_PER_REQUEST = 1000;

// ─── Types ───────────────────────────────────────────────────────────────────────────────────────

/** Resolved per-connection settings (credential store ∪ CompanyIntegration.Configuration). */
interface InformzConfig {
    User: string;
    Password: string;
    BrandID: string;
    BrandName: string;
    Region: string;
    /** Fully-resolved service endpoint (region-selected, or an explicit operator/test override). */
    Endpoint: string;
    Namespace: string;
    /** Optional operator override for the grid page size; capped at the vendor's 1,000-row ceiling. */
    PageSize: number | null;
}

/** Auth context threaded through every request. Carries the in-BODY credential triple — no headers. */
export interface InformzAuthContext extends RESTAuthContext {
    User: string;
    Password: string;
    BrandID: string;
    BrandName: string;
    Endpoint: string;
    Namespace: string;
    PageSize: number | null;
}

/** The two AAPI document types. */
export type InformzDocumentType = 'GridRequest' | 'ActionRequest';

/**
 * The structured request handed to {@link InformzConnector.MakeHTTPRequest} as its `body`: the AAPI
 * DOCUMENT plus its type. MakeHTTPRequest is where the SOAP envelope is built (the document is carried as
 * the escaped string argument of `PostInformzMessage`), so a mocked subclass that overrides
 * MakeHTTPRequest captures the exact outbound document.
 */
export interface InformzRequest {
    DocumentType: InformzDocumentType;
    /** The fully-formed AAPI XML document (already credential-bearing). */
    Xml: string;
}

/** One `<Condition>` in a GridRequest `<Conditions>` block. */
export interface InformzCondition {
    DataElement: string;
    /** Single-value comparator (EQ NEQ GT LT LTE GTE). Mutually exclusive with Between/Set. */
    Comparator?: 'EQ' | 'NEQ' | 'GT' | 'LT' | 'LTE' | 'GTE';
    /** Values: one for Single, two (from,to — earlier FIRST) for Between, many for Collection. */
    DataValues: string[];
    /** Collection set-operator (EQ NEQ IN NOTIN — the wire token for "Not In" is `NOTIN`, no space). */
    SetOperator?: 'EQ' | 'NEQ' | 'IN' | 'NOTIN';
    /** Range form: `<Between>` with the earlier DataValue listed first. */
    Between?: boolean;
}

/** One `<Grid>` block of a GridRequest document. */
export interface InformzGridSpec {
    /** The `<Grid type="...">` token, taken from IO metadata — NEVER hardcoded. */
    GridType: string;
    Conditions: InformzCondition[];
    ReturnFields: string[];
    SortField: string | null;
    SortOrder: 'asc' | 'desc';
    StartRow: number | null;
    NumberOfRows: number | null;
}

/** A parsed `<Record>` set for one `<Grid type>` in a GridResponse. */
export interface InformzGridResult {
    GridType: string;
    Records: Record<string, unknown>[];
}

/** A parsed `InformzServiceFault` (Code/Message/Reason per the pinned xsd2 fault schema). */
export interface InformzFault {
    Code: string;
    Reason: string;
}

/** Error thrown for a non-2xx / faulted AAPI call. Carries the throttle hint for the adaptive limiter. */
export class InformzRequestError extends Error {
    public readonly Status: number;
    public readonly FaultCode: string | null;
    public readonly RetryAfterMs: number | undefined;
    public readonly SyncCode: SyncErrorCode;
    constructor(message: string, status: number, faultCode: string | null, retryAfterMs: number | undefined, syncCode: SyncErrorCode) {
        super(message);
        this.name = 'InformzRequestError';
        this.Status = status;
        this.FaultCode = faultCode;
        this.RetryAfterMs = retryAfterMs;
        this.SyncCode = syncCode;
    }
}

/** Zod shape for the resolved connection config (post key-normalization). */
const ConfigSchema = z.object({
    User: z.string().min(1, 'Informz <User> is required (credential key "User")'),
    Password: z.string().min(1, 'Informz <Password> is required (credential key "Password")'),
    BrandID: z.string().min(1, 'Informz Brand id is required (credential key "BrandID")'),
    BrandName: z.string(),
    Region: z.string().min(1),
    Endpoint: z.string().min(1),
    Namespace: z.string().min(1),
    PageSize: z.number().int().positive().max(VENDOR_MAX_ROWS_PER_REQUEST).nullable(),
});

// ─── Connector ───────────────────────────────────────────────────────────────────────────────────

// Registered under BOTH the package name (how the catalog resolves an installed Open App connector,
// and what MJ: Integrations.ClassName carries) and the legacy bare class name, so an existing
// Integration row pinned to 'InformzConnector' keeps resolving after this ships.
@RegisterClass(BaseIntegrationConnector, '@memberjunction/connector-informz')
@RegisterClass(BaseIntegrationConnector, 'InformzConnector')
export class InformzConnector extends BaseRESTIntegrationConnector {

    /**
     * Case-variant source element names dropped by {@link TransformRecord} per object, surfaced to
     * {@link ExcludedSourceKeys} so the base's key-preserving re-add does not resurrect a duplicate
     * column for a datum that was merely re-cased onto its declared name.
     */
    private readonly reCasedKeys = new Map<string, Set<string>>();

    // ── Identity + capabilities ──────────────────────────────────────────────────────────────────

    /** Verbatim `MJ: Integrations.Name` (the three-way identity invariant). */
    public override get IntegrationName(): string { return 'informz'; }

    /** ActionRequest documents exist for per-record create (CreateMailing, Subscribe) — wired below. */
    public override get SupportsCreate(): boolean { return true; }
    /** Subscribe is a documented per-record UPSERT; the Subscriber IO carries Update* columns. */
    public override get SupportsUpdate(): boolean { return true; }
    /** No delete/purge action exists anywhere in the documented ActionRequest surface. */
    public override get SupportsDelete(): boolean { return false; }

    /**
     * FALSE, permanently. There is no describe-all/introspection endpoint on this API: the catalog is the
     * vendor's PUBLISHED documentation, not a live per-credential capability list, so an object/field
     * absent at runtime proves nothing and must never deactivate anything.
     */
    public override get DiscoveryIsAuthoritative(): boolean { return false; }

    /**
     * Retry-After / throttle hint. No numeric rate limit is documented anywhere in the vendor corpus
     * (`DeclaredCapabilityLimits.no-numeric-rate-limit-documented`), so there is no policy to declare —
     * but an observed 429/503 must still be honoured ADAPTIVELY, which is what this feeds.
     */
    public override ExtractRetryAfterMs(error: unknown): number | undefined {
        if (error instanceof InformzRequestError) return error.RetryAfterMs;
        return undefined;
    }

    // ── TestConnection ───────────────────────────────────────────────────────────────────────────

    /**
     * Credential probe: a Count-only GridRequest against the FIRST active object in metadata (never a
     * hardcoded grid token). A well-formed GridResponse proves credential + brand + egress-IP acceptance.
     */
    public async TestConnection(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<ConnectionTestResult> {
        try {
            const objects = IntegrationEngineBase.Instance.GetActiveIntegrationObjects(companyIntegration.IntegrationID);
            if (objects.length === 0) {
                return { Success: false, Message: 'No active Integration Objects are configured for Informz — nothing to probe.' };
            }
            const auth = await this.Authenticate(companyIntegration, contextUser);
            const gridType = this.GridTypeFor(objects[0]);
            const xml = this.BuildGridRequestDocument(auth, [{
                GridType: gridType, Conditions: [], ReturnFields: ['Count'],
                SortField: null, SortOrder: 'asc', StartRow: null, NumberOfRows: null,
            }]);
            const response = await this.MakeHTTPRequest(
                auth, this.GetBaseURL(companyIntegration, auth), 'POST', this.BuildHeaders(auth),
                { DocumentType: 'GridRequest', Xml: xml },
            );
            this.ThrowOnFault(response, `GridRequest(${gridType})`);
            return {
                Success: true,
                Message: `Informz AAPI reachable for brand ${auth.BrandID} (probe grid "${gridType}").`,
                ServerVersion: 'Informz AAPI 2009/08 (PostInformzMessage, SOAP 1.1)',
            };
        } catch (err: unknown) {
            const message = err instanceof Error ? err.message : String(err);
            return { Success: false, Message: `Informz connection failed: ${message}` };
        }
    }

    // ── Auth / transport seams (abstract on BaseRESTIntegrationConnector) ────────────────────────

    /**
     * NO network call and NO token exchange: Informz credentials travel in the document body, so
     * "authenticating" is resolving the credential triple + region endpoint for this connection.
     * (Deliberately NOT routed through `auth-helpers` — there is no signing, hashing or grant flow here.)
     */
    protected async Authenticate(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<InformzAuthContext> {
        const config = await this.ParseConfig(companyIntegration, contextUser);
        return {
            User: config.User,
            Password: config.Password,
            BrandID: config.BrandID,
            BrandName: config.BrandName,
            Endpoint: config.Endpoint,
            Namespace: config.Namespace,
            PageSize: config.PageSize,
        };
    }

    /** SOAP 1.1 content headers. There is NO Authorization header on this vendor — by design. */
    protected BuildHeaders(auth: RESTAuthContext): Record<string, string> {
        void auth;
        return {
            'Content-Type': 'text/xml; charset=utf-8',
            'Accept': 'text/xml',
            'SOAPAction': `"${SOAP_ACTION}"`,
        };
    }

    /**
     * REGION-SELECTED endpoint. Resolved from the Integration row's `Configuration.Transport.endpoints`
     * keyed by the connection's `Region` (us|ca|test, default us). ZERO tenant-specific host is baked
     * anywhere — the tenant is identified purely by the credential + `<Brand id>`.
     */
    protected GetBaseURL(companyIntegration: MJCompanyIntegrationEntity, auth: RESTAuthContext): string {
        const ctx = auth as InformzAuthContext;
        if (ctx?.Endpoint) return ctx.Endpoint;
        return this.ResolveEndpoint(companyIntegration, this.ReadConnectionSettings(companyIntegration));
    }

    /**
     * The SOAP transport boundary. `body` MUST be an {@link InformzRequest}; this builds the SOAP 1.1
     * envelope carrying the AAPI document as the ESCAPED string argument of `PostInformzMessage`, POSTs it,
     * and normalizes the reply into `{ Document }` (the unescaped inner AAPI document) or `{ _fault }`.
     * Mocked test subclasses override this to capture the outbound document.
     */
    protected async MakeHTTPRequest(
        auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown
    ): Promise<RESTResponse> {
        const request = body as InformzRequest | undefined;
        if (!request || typeof request.Xml !== 'string') {
            throw new Error('InformzConnector.MakeHTTPRequest requires an InformzRequest body ({ DocumentType, Xml }).');
        }
        const envelope = this.BuildSoapEnvelope(auth as InformzAuthContext, request.Xml);
        const httpResponse = await fetch(url, { method, headers, body: envelope });
        const text = await httpResponse.text();
        return this.ParseSoapResponse(text, httpResponse.status, this.HeadersToObject(httpResponse.headers));
    }

    /**
     * Strips the AAPI envelope down to record maps. Generic over `<Grid type>` (returns every grid's
     * records in document order) because a single GridRequest MAY carry multiple `<Grid>` blocks; the
     * per-object read path uses {@link ParseGridRecords}, which selects the requested token.
     */
    protected NormalizeResponse(rawBody: unknown, responseDataKey: string | null): Record<string, unknown>[] {
        void responseDataKey; // the record path is invariant on this vendor: GridResponse/Grids/Grid/Record
        const doc = this.ResponseDocument(rawBody);
        if (!doc) return [];
        return this.ParseGridResponse(doc).flatMap(g => g.Records);
    }

    /**
     * OFFSET pagination. `<StartRow>` is the ORDINAL of the first row (the vendor's own worked example
     * pages 0 → 51 for a 50-row page), so the next start is `max(start,1) + rowsReturned`. A SHORT page
     * (fewer rows than requested) terminates the scan; a `Count` total, when the response carries one,
     * bounds it too.
     */
    protected ExtractPaginationInfo(
        rawBody: unknown,
        paginationType: PaginationType,
        currentPage: number,
        currentOffset: number,
        pageSize: number
    ): PaginationState {
        if (paginationType === 'None') return { HasMore: false };
        const doc = this.ResponseDocument(rawBody);
        const grids = doc ? this.ParseGridResponse(doc) : [];
        const count = grids.reduce((n, g) => n + g.Records.length, 0);
        const total = this.ExtractCountTotal(grids);
        const start = currentOffset <= 0 ? 1 : currentOffset;
        const nextOffset = start + count;
        const hasMore = count > 0 && pageSize > 0 && count >= pageSize
            && (total == null || nextOffset <= total);
        const state: PaginationState = { HasMore: hasMore, NextOffset: nextOffset, NextPage: currentPage + 1 };
        if (total != null) state.TotalRecords = total;
        return state;
    }

    /**
     * Per-record reshaping: the vendor's `<Field element="...">` names are CASE-VARIANT against its own
     * documented Data-Element tables (the subscriber sample returns `email` where the table declares
     * `Email`; the mailing_instance sample returns `mailing_id` where the table declares `Mailing_ID`).
     * Re-case an element onto its DECLARED name when they differ only by case, so the declared field maps
     * instead of silently landing in custom overflow as a near-duplicate. An element with NO declared
     * counterpart is left VERBATIM — that is exactly how a brand's tenant-defined demographic / extended
     * demographic / interest element reaches the framework's custom-column capture.
     */
    protected override TransformRecord(
        raw: Record<string, unknown>,
        obj: MJIntegrationObjectEntity,
        fields: MJIntegrationObjectFieldEntity[]
    ): Record<string, unknown> {
        const declaredByLower = new Map<string, string>();
        for (const f of fields) declaredByLower.set(f.Name.toLowerCase(), f.Name);
        let changed = false;
        const out: Record<string, unknown> = {};
        const dropped = new Set<string>();
        for (const [key, value] of Object.entries(raw)) {
            const declared = declaredByLower.get(key.toLowerCase());
            if (declared && declared !== key && !(declared in raw)) {
                out[declared] = value;
                dropped.add(key);
                changed = true;
            } else {
                out[key] = value;
            }
        }
        if (!changed) return raw; // identity fast-path — base skips the key-preserving re-add entirely
        this.reCasedKeys.set(obj.Name, dropped);
        return out;
    }

    /** The case-variant keys {@link TransformRecord} folded onto their declared names for this object. */
    protected override ExcludedSourceKeys(objectName: string): string[] {
        return Array.from(this.reCasedKeys.get(objectName) ?? []);
    }

    // ── Schema introspection: declared ∪ live sample (tenant customs) ────────────────────────────

    /**
     * Never-shrink SAMPLE-UNION. The declared catalog documents the demographic/interest WRAPPER shape but
     * never the per-brand NAMES, so a live sample is the only way a tenant's own demographic / extended
     * demographic / interest elements reach the schema. Declared attributes stay authoritative; sampling
     * only widens and appends. Per-object, parallel, best-effort — a sampling failure leaves the declared
     * fields standing (and, credential-free, EVERY object still returns its full declared field set).
     */
    public override async IntrospectSchema(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<SourceSchemaInfo> {
        const schema = await super.IntrospectSchema(companyIntegration, contextUser);
        await Promise.all(schema.Objects.map(async (obj) => {
            try {
                const sampled = await this.DiscoverFieldsViaFetch(companyIntegration, obj.ExternalName, contextUser);
                obj.Fields = mergeDeclaredWithSampledFields(obj.Fields, sampled);
            } catch { /* best-effort — declared fields remain authoritative on a sampling failure */ }
        }));
        return schema;
    }

    // ── Read path ────────────────────────────────────────────────────────────────────────────────

    /**
     * Fetch ONE page of a grid. Builds the GridRequest document from METADATA: the `<Grid type>` token,
     * the full declared `<ReturnFields>` set (so custom/overflow capture can see everything the brand
     * returns), the metadata's stable `<SortField>` (offset paging without a stable sort silently drops
     * and duplicates rows), `<StartRow>`/`<NumberOfRows>`, and — only when the IO declares a watermark
     * field — a GTE `<Condition>` on it. An IO with NO declared watermark does a FULL scan; the connector
     * never invents one.
     */
    public override async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
        const obj = this.GetCachedObject(ctx.CompanyIntegration.IntegrationID, ctx.ObjectName);
        const fields = this.GetCachedFields(obj.ID);
        const gridType = this.GridTypeFor(obj);
        const auth = await this.Authenticate(ctx.CompanyIntegration, ctx.ContextUser);

        const paginates = obj.SupportsPagination && obj.PaginationType !== 'None';
        const startRow = paginates ? (ctx.CurrentOffset ?? 0) : null;
        const pageSize = this.ResolvePageSize(obj, ctx, auth);
        const returnFields = this.ReturnFieldsFor(fields, ctx.RequestedSourceFields);
        const conditions = this.BuildIncrementalConditions(obj, ctx.WatermarkValue);

        const xml = this.BuildGridRequestDocument(auth, [{
            GridType: gridType,
            Conditions: conditions,
            ReturnFields: returnFields,
            SortField: paginates ? this.SortFieldFor(obj, fields) : null,
            SortOrder: 'asc',
            StartRow: startRow,
            NumberOfRows: paginates ? pageSize : null,
        }]);

        const response = await this.MakeHTTPRequest(
            auth, this.GetBaseURL(ctx.CompanyIntegration, auth), 'POST', this.BuildHeaders(auth),
            { DocumentType: 'GridRequest', Xml: xml },
        );
        this.ThrowOnFault(response, `GridRequest(${gridType})`);

        const doc = this.ResponseDocument(response.Body);
        const raws = this.ParseGridRecords(doc, gridType);
        const pkFieldNames = this.PrimaryKeyFieldNames(fields);
        const records = raws.map(r => this.BuildRecord(
            this.applyTransformPreservingKeys(r, obj, fields),
            ctx.ObjectName,
            pkFieldNames,
        ));

        const pagination = this.ExtractPaginationInfo(
            response.Body, (obj.PaginationType ?? 'None') as PaginationType,
            ctx.CurrentPage ?? 1, startRow ?? 0, pageSize,
        );

        // Watermark advances ONLY on a fully-parsed page: a mid-iteration failure throws above, so the
        // engine never persists a partial high-water mark.
        const newWatermark = this.ComputeWatermark(obj, raws);

        const result: FetchBatchResult = {
            Records: records,
            HasMore: paginates ? pagination.HasMore : false,
            NextOffset: paginates ? pagination.NextOffset : undefined,
        };
        if (newWatermark) result.NewWatermarkValue = newWatermark;
        return result;
    }

    /**
     * Get-one. The base's generic `APIPath/{id}` GET cannot express a single-door SOAP read, so this
     * issues a GridRequest with an EQ `<Condition>` per declared PK component (composite PKs arrive
     * `|`-joined, matching the engine's key serialization).
     */
    public override async GetRecord(ctx: GetRecordContext): Promise<ExternalRecord | null> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const contextUser = ctx.ContextUser as UserInfo;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        const fields = this.GetCachedFields(obj.ID);
        const pkFieldNames = this.PrimaryKeyFieldNames(fields);
        const parts = String(ctx.ExternalID).split('|');
        if (pkFieldNames.length === 0 || parts.length !== pkFieldNames.length) {
            throw new Error(
                `GetRecord for "${ctx.ObjectName}": external ID "${ctx.ExternalID}" does not match the declared ` +
                `primary key (${pkFieldNames.join(', ') || 'none declared'}).`
            );
        }
        const auth = await this.Authenticate(ci, contextUser);
        const gridType = this.GridTypeFor(obj);
        const xml = this.BuildGridRequestDocument(auth, [{
            GridType: gridType,
            Conditions: pkFieldNames.map((name, i) => ({ DataElement: name, Comparator: 'EQ' as const, DataValues: [parts[i]] })),
            ReturnFields: this.ReturnFieldsFor(fields),
            SortField: null, SortOrder: 'asc', StartRow: null, NumberOfRows: null,
        }]);
        const response = await this.MakeHTTPRequest(
            auth, this.GetBaseURL(ci, auth), 'POST', this.BuildHeaders(auth),
            { DocumentType: 'GridRequest', Xml: xml },
        );
        this.ThrowOnFault(response, `GridRequest(${gridType})`);
        const raws = this.ParseGridRecords(this.ResponseDocument(response.Body), gridType);
        if (raws.length === 0) return null;
        return this.BuildRecord(this.applyTransformPreservingKeys(raws[0], obj, fields), ctx.ObjectName, pkFieldNames);
    }

    // ── Write path (ActionRequest documents) ─────────────────────────────────────────────────────

    /**
     * Create via the documented ActionRequest document. The action element name comes from the IO's
     * `CreateBodyKey` (fallback: the last segment of `CreateAPIPath`) — never hardcoded — and the payload
     * shape from `Configuration.writeActions[].recordElement`. Routes through `BuildCreatedResult`, so a
     * 2xx that yields no record ID fails LOUDLY instead of silently losing the record.
     *
     * Bulk-job and action-shaped operations (BulkUpload, ScheduleMailing, SetMailingOnHold, Unsubscribe,
     * Optout, UpdateContactMessageCategoryPreference) are DELIBERATELY UNWIRED — they are not per-record
     * create/update semantics and must never be smuggled in here.
     */
    public override async CreateRecord(ctx: CreateRecordContext): Promise<CRUDResult> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const contextUser = ctx.ContextUser as UserInfo;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        if (!obj.CreateAPIPath || !obj.CreateMethod) {
            throw new Error(
                `CreateRecord not supported for "${ctx.ObjectName}": CreateAPIPath / CreateMethod not configured on IntegrationObject.`
            );
        }
        const action = this.ActionNameFor(obj.CreateBodyKey, obj.CreateAPIPath);
        try {
            const auth = await this.Authenticate(ci, contextUser);
            const xml = this.BuildActionRequestDocument(auth, action, this.RecordElementFor(obj, action), ctx.Attributes);
            const response = await this.MakeHTTPRequest(
                auth, this.GetBaseURL(ci, auth), 'POST', this.BuildHeaders(auth),
                { DocumentType: 'ActionRequest', Xml: xml },
            );
            this.ThrowOnFault(response, `ActionRequest(${action})`);
            const doc = this.ResponseDocument(response.Body);
            const status = this.ExtractActionStatus(doc, action);
            if (status && status.Status.toLowerCase() !== 'success') {
                return {
                    Success: false, StatusCode: response.Status,
                    ErrorMessage: `Informz ${action} reported failure: ${status.Message || status.Status}`,
                };
            }
            const externalID = this.ExtractActionID(doc, obj, ctx.Attributes);
            return this.BuildCreatedResult(externalID, response.Status, ctx.ObjectName);
        } catch (err: unknown) {
            return this.BuildCRUDError(err, 'CreateRecord', ctx.ObjectName);
        }
    }

    /**
     * Update via the documented ActionRequest document. Informz's per-record write for subscribers is the
     * idempotent `Subscribe` UPSERT (same document as create), so `UpdateBodyKey`/`UpdateAPIPath` legitimately
     * name the same action; the target record's ID is injected into the payload under the action's record key.
     */
    public override async UpdateRecord(ctx: UpdateRecordContext): Promise<CRUDResult> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const contextUser = ctx.ContextUser as UserInfo;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        if (!obj.UpdateAPIPath || !obj.UpdateMethod) {
            throw new Error(
                `UpdateRecord not supported for "${ctx.ObjectName}": UpdateAPIPath / UpdateMethod not configured on IntegrationObject.`
            );
        }
        const action = this.ActionNameFor(obj.UpdateBodyKey, obj.UpdateAPIPath);
        try {
            const auth = await this.Authenticate(ci, contextUser);
            const recordElement = this.RecordElementFor(obj, action);
            const attributes = this.WithInjectedID(ctx.Attributes, ctx.ExternalID, obj, recordElement);
            const xml = this.BuildActionRequestDocument(auth, action, recordElement, attributes);
            const response = await this.MakeHTTPRequest(
                auth, this.GetBaseURL(ci, auth), 'POST', this.BuildHeaders(auth),
                { DocumentType: 'ActionRequest', Xml: xml },
            );
            this.ThrowOnFault(response, `ActionRequest(${action})`);
            const status = this.ExtractActionStatus(this.ResponseDocument(response.Body), action);
            if (status && status.Status.toLowerCase() !== 'success') {
                return {
                    Success: false, StatusCode: response.Status,
                    ErrorMessage: `Informz ${action} reported failure: ${status.Message || status.Status}`,
                };
            }
            return { Success: true, StatusCode: response.Status, ExternalID: ctx.ExternalID };
        } catch (err: unknown) {
            return this.BuildCRUDError(err, 'UpdateRecord', ctx.ObjectName);
        }
    }

    // ── Document builders ────────────────────────────────────────────────────────────────────────

    /**
     * Builds a `<GridRequest>` document. Element order follows the vendor's published samples exactly:
     * `Password`, `Brand`, `User`, `Grids` → per grid `Conditions`, `ReturnFields`, `SortField`,
     * `StartRow`, `NumberOfRows`.
     */
    public BuildGridRequestDocument(auth: InformzAuthContext, grids: InformzGridSpec[]): string {
        const ns = auth.Namespace || DEFAULT_NAMESPACE;
        const parts: string[] = [];
        parts.push(`<GridRequest xmlns="${ns}">`);
        parts.push(`  <Password>${this.EscapeXml(auth.Password)}</Password>`);
        parts.push(`  <Brand id="${this.EscapeXml(auth.BrandID)}">${this.EscapeXml(auth.BrandName)}</Brand>`);
        parts.push(`  <User>${this.EscapeXml(auth.User)}</User>`);
        parts.push('  <Grids>');
        for (const grid of grids) {
            parts.push(`    <Grid type="${this.EscapeXml(grid.GridType)}">`);
            if (grid.Conditions.length > 0) {
                parts.push('      <Conditions>');
                for (const c of grid.Conditions) parts.push(this.RenderCondition(c));
                parts.push('      </Conditions>');
            }
            if (grid.ReturnFields.length > 0) {
                parts.push('      <ReturnFields>');
                for (const f of grid.ReturnFields) parts.push(`        <DataElement>${this.EscapeXml(f)}</DataElement>`);
                parts.push('      </ReturnFields>');
            }
            if (grid.SortField) {
                parts.push(`      <SortField order="${grid.SortOrder}">${this.EscapeXml(grid.SortField)}</SortField>`);
            }
            if (grid.StartRow != null) parts.push(`      <StartRow>${grid.StartRow}</StartRow>`);
            if (grid.NumberOfRows != null) parts.push(`      <NumberOfRows>${grid.NumberOfRows}</NumberOfRows>`);
            parts.push('    </Grid>');
        }
        parts.push('  </Grids>');
        parts.push('</GridRequest>');
        return parts.join('\n');
    }

    /**
     * Builds an `<ActionRequest>` document. Element order follows the vendor's published samples:
     * `Brand`, `User`, `Password`, `Actions` → `<action>`.
     *
     * Payload shape is metadata-driven via `Configuration.writeActions[].recordElement`:
     *   • recordElement === action (or absent) → the action's nodes are the attributes themselves, emitted
     *     in the caller's order (CreateMailing: Name/FriendlyFrom/EmailFrom/…/Stories).
     *   • recordElement !== action → the documented SUBSCRIBER-record shape:
     *     `<SubscriberData><Subscribers><Subscriber><Email/><ID/><Fields><Field element="…"/></Fields>…`
     *     with `<Email>` FIRST and an UPPERCASE `<ID>` SECOND (an explicit, verbatim vendor requirement).
     */
    public BuildActionRequestDocument(
        auth: InformzAuthContext,
        action: string,
        recordElement: string | null,
        attributes: Record<string, unknown>,
    ): string {
        const ns = auth.Namespace || DEFAULT_NAMESPACE;
        const body = recordElement && recordElement !== action
            ? this.RenderRecordAction(recordElement, attributes)
            : this.RenderNodes(attributes, '      ');
        return [
            `<ActionRequest xmlns="${ns}">`,
            `  <Brand id="${this.EscapeXml(auth.BrandID)}">${this.EscapeXml(auth.BrandName)}</Brand>`,
            `  <User>${this.EscapeXml(auth.User)}</User>`,
            `  <Password>${this.EscapeXml(auth.Password)}</Password>`,
            '  <Actions>',
            `    <${action}>`,
            body,
            `    </${action}>`,
            '  </Actions>',
            '</ActionRequest>',
        ].filter(line => line.length > 0).join('\n');
    }

    /** SOAP 1.1 envelope carrying the AAPI document as the escaped string argument of the one operation. */
    public BuildSoapEnvelope(auth: InformzAuthContext, document: string): string {
        const ns = auth?.Namespace || DEFAULT_NAMESPACE;
        return '<?xml version="1.0" encoding="utf-8"?>\n' +
            '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">\n' +
            '  <soap:Body>\n' +
            `    <${SOAP_OPERATION} xmlns="${ns}">\n` +
            `      <${SOAP_ARGUMENT_ELEMENT}>${this.EscapeXml(document)}</${SOAP_ARGUMENT_ELEMENT}>\n` +
            `    </${SOAP_OPERATION}>\n` +
            '  </soap:Body>\n' +
            '</soap:Envelope>';
    }

    /**
     * Redacts the credential elements so a document can be logged/attached without leaking secrets.
     *
     * The frozen contract's `AuthPreconditions.credentialShape` is `[user, password, brandId, region]`, and
     * the vendor's own Document-notes call the Brand id "your unique account ID" — so the Brand's `id`
     * ATTRIBUTE is a credential component, not a harmless label, and is redacted alongside the element text.
     *
     * Both wire forms are handled: the RAW document, and the XML-ESCAPED form the document takes as the
     * string argument of `PostInformzMessage` inside the SOAP envelope. Scrubbing a whole envelope
     * therefore redacts exactly as thoroughly as scrubbing the bare document — otherwise a handler that
     * attached the outbound envelope (the thing actually on the wire) would leak the whole credential triple.
     */
    public ScrubDocument(document: string): string {
        let out = document;
        for (const [lt, gt, quote] of [['<', '>', '"'], ['&lt;', '&gt;', '&quot;']] as const) {
            for (const element of ['Password', 'User', 'Username']) {
                out = out.replace(new RegExp(`(${lt}${element}${gt})[\\s\\S]*?(${lt}/${element}${gt})`, 'gi'), '$1***$2');
            }
            const idAttr = new RegExp(`(\\bid\\s*=\\s*)(${quote})[\\s\\S]*?(${quote})`, 'gi');
            out = out.replace(
                new RegExp(`(${lt}Brand\\b)([\\s\\S]*?)(${gt})[\\s\\S]*?(${lt}/Brand${gt})`, 'gi'),
                (_match, open: string, attrs: string, close: string, closeTag: string) =>
                    `${open}${attrs.replace(idAttr, '$1$2***$3')}${close}***${closeTag}`,
            );
        }
        return out;
    }

    private RenderCondition(condition: InformzCondition): string {
        const el = `        <DataElement>${this.EscapeXml(condition.DataElement)}</DataElement>`;
        const values = condition.DataValues.map(v => `        <DataValue>${this.EscapeXml(v)}</DataValue>`);
        if (condition.Between) {
            // Vendor TIP: the earlier (from) DataValue MUST be listed before the later (to) DataValue.
            return ['      <Condition>', '        <Between>', el, ...values, '        </Between>', '      </Condition>'].join('\n');
        }
        if (condition.SetOperator) {
            return [
                '      <Condition>', '        <Collection>', el, ...values,
                `        <SetOperator>${condition.SetOperator}</SetOperator>`,
                '        </Collection>', '      </Condition>',
            ].join('\n');
        }
        return [
            '      <Condition>', '        <Single>', el, ...values,
            `        <Comparator>${condition.Comparator ?? 'EQ'}</Comparator>`,
            '        </Single>', '      </Condition>',
        ].join('\n');
    }

    /** The documented subscriber-record action payload (Subscribe family). */
    private RenderRecordAction(recordElement: string, attributes: Record<string, unknown>): string {
        const emailKey = Object.keys(attributes).find(k => k.toLowerCase() === 'email');
        const idKey = Object.keys(attributes).find(k => k.toLowerCase() === 'id' || k.toLowerCase() === 'user_id');
        const rest = Object.entries(attributes).filter(([k]) => k !== emailKey && k !== idKey);
        const lines: string[] = ['      <SubscriberData>', '        <Subscribers>', `          <${recordElement}>`];
        if (emailKey) lines.push(`            <Email>${this.EscapeXml(this.ScalarText(attributes[emailKey]))}</Email>`);
        if (idKey) lines.push(`            <ID>${this.EscapeXml(this.ScalarText(attributes[idKey]))}</ID>`);
        if (rest.length > 0) {
            lines.push('            <Fields>');
            for (const [k, v] of rest) {
                if (v == null) continue;
                lines.push(`              <Field element="${this.EscapeXml(k)}">${this.EscapeXml(this.ScalarText(v))}</Field>`);
            }
            lines.push('            </Fields>');
        }
        lines.push(`          </${recordElement}>`, '        </Subscribers>', '      </SubscriberData>');
        return lines.join('\n');
    }

    /** Renders attribute nodes recursively (nested objects → nested elements; arrays → repeated elements). */
    private RenderNodes(attributes: Record<string, unknown>, indent: string): string {
        const parts: string[] = [];
        for (const [key, value] of Object.entries(attributes)) {
            const rendered = this.RenderNode(key, value, indent);
            if (rendered) parts.push(rendered);
        }
        return parts.join('\n');
    }

    private RenderNode(key: string, value: unknown, indent: string): string {
        if (value == null) return '';
        if (Array.isArray(value)) {
            // A plural attribute renders as a wrapper with singular children when its items are objects
            // (CreateMailing's <Stories><Story>…</Story></Stories>).
            const singular = key.endsWith('ies') ? `${key.slice(0, -3)}y` : key.endsWith('s') ? key.slice(0, -1) : key;
            const children = value
                .map(item => this.RenderNode(singular, item, `${indent}  `))
                .filter(s => s.length > 0);
            if (children.length === 0) return '';
            return `${indent}<${key}>\n${children.join('\n')}\n${indent}</${key}>`;
        }
        if (typeof value === 'object') {
            const children = this.RenderNodes(value as Record<string, unknown>, `${indent}  `);
            return `${indent}<${key}>\n${children}\n${indent}</${key}>`;
        }
        return `${indent}<${key}>${this.EscapeXml(this.ScalarText(value))}</${key}>`;
    }

    // ── Response parsing ─────────────────────────────────────────────────────────────────────────

    /**
     * Normalizes a raw SOAP reply. A SOAP Fault is delivered as HTTP 500 by every SOAP stack, so status
     * alone is NOT the error signal: the body is inspected for `<Fault>`/`InformzServiceFault` first, and
     * the fault's `Code`/`Reason` are surfaced for classification.
     */
    public ParseSoapResponse(xml: string, status: number, headers: Record<string, string>): RESTResponse {
        const bodyInner = this.ExtractElementInner(xml, 'Body') ?? xml;
        const faultInner = this.ExtractElementInner(bodyInner, 'Fault');
        if (faultInner) {
            const detail = this.ExtractElementInner(faultInner, 'InformzServiceFault') ?? faultInner;
            const fault: InformzFault = {
                Code: (this.ExtractElementInner(detail, 'Code') ?? this.ExtractElementInner(faultInner, 'faultcode') ?? 'UNKNOWN').trim(),
                Reason: (this.ExtractElementInner(detail, 'Reason')
                    ?? this.ExtractElementInner(detail, 'Message')
                    ?? this.ExtractElementInner(faultInner, 'faultstring')
                    ?? 'unknown SOAP fault').trim(),
            };
            return { Status: status >= 400 ? status : 500, Body: { _fault: fault }, Headers: headers };
        }
        const result = this.ExtractElementInner(bodyInner, SOAP_RESULT_ELEMENT);
        // The document may arrive escaped (xs:string, the WSDL-declared shape) or, from a lenient
        // gateway/replay, verbatim; accept both, and accept a bare document with no SOAP envelope.
        const document = result != null
            ? this.DecodeXml(result).trim()
            : (/<(?:\w+:)?(?:GridResponse|ActionResponse)\b/i.test(xml) ? xml.trim() : '');
        return { Status: status, Body: { Document: document }, Headers: headers };
    }

    /** Extracts the inner AAPI document string from a normalized response body. */
    public ResponseDocument(body: unknown): string {
        if (typeof body === 'string') return body;
        if (body && typeof body === 'object') {
            const doc = (body as Record<string, unknown>).Document;
            if (typeof doc === 'string') return doc;
        }
        return '';
    }

    /**
     * Parses a `<GridResponse>` document into per-grid record sets.
     * `<Record row="n"><Fields><Field element="name">value</Field></Fields></Record>`; a SELF-CLOSING or
     * empty `<Field/>` becomes NULL (not an empty string, which would defeat content-hash idempotency),
     * and a self-closing `<Grid type="x" />` is a legitimate ZERO-ROW result, never an error.
     */
    public ParseGridResponse(document: string): InformzGridResult[] {
        const out: InformzGridResult[] = [];
        if (!document) return out;
        const gridOpen = /<(?:\w+:)?Grid\b([^>]*?)(\/?)>/gi;
        let match: RegExpExecArray | null;
        while ((match = gridOpen.exec(document)) !== null) {
            const attrs = match[1] ?? '';
            const selfClosing = match[2] === '/';
            const gridType = this.ReadAttribute(attrs, 'type') ?? '';
            if (selfClosing) { out.push({ GridType: gridType, Records: [] }); continue; }
            const closeIdx = document.toLowerCase().indexOf('</grid>', gridOpen.lastIndex);
            const inner = closeIdx === -1 ? document.slice(gridOpen.lastIndex) : document.slice(gridOpen.lastIndex, closeIdx);
            out.push({ GridType: gridType, Records: this.ParseRecords(inner) });
            if (closeIdx !== -1) gridOpen.lastIndex = closeIdx + '</grid>'.length;
        }
        return out;
    }

    /** Records for ONE grid token; an absent token yields `[]` (never a throw, never another grid's rows). */
    public ParseGridRecords(document: string, gridType: string): Record<string, unknown>[] {
        const grids = this.ParseGridResponse(document);
        const exact = grids.find(g => g.GridType.toLowerCase() === gridType.toLowerCase());
        if (exact) return exact.Records;
        // A single-grid response whose type attribute is absent still belongs to the requested grid.
        const untyped = grids.find(g => g.GridType === '');
        return grids.length === 1 && untyped ? untyped.Records : [];
    }

    private ParseRecords(gridInner: string): Record<string, unknown>[] {
        const records: Record<string, unknown>[] = [];
        const recordRe = /<(?:\w+:)?Record\b[^>]*?(\/)?>/gi;
        let match: RegExpExecArray | null;
        while ((match = recordRe.exec(gridInner)) !== null) {
            if (match[1] === '/') { records.push({}); continue; }
            const closeIdx = gridInner.toLowerCase().indexOf('</record>', recordRe.lastIndex);
            const inner = closeIdx === -1 ? gridInner.slice(recordRe.lastIndex) : gridInner.slice(recordRe.lastIndex, closeIdx);
            records.push(this.ParseFields(inner));
            if (closeIdx !== -1) recordRe.lastIndex = closeIdx + '</record>'.length;
        }
        return records;
    }

    private ParseFields(recordInner: string): Record<string, unknown> {
        const fields: Record<string, unknown> = {};
        const fieldRe = /<(?:\w+:)?Field\b([^>]*?)(?:\/>|>([\s\S]*?)<\/(?:\w+:)?Field>)/gi;
        let match: RegExpExecArray | null;
        while ((match = fieldRe.exec(recordInner)) !== null) {
            const name = this.ReadAttribute(match[1] ?? '', 'element');
            if (!name) continue;
            const raw = match[2];
            // Empty element (`<Field element="x" />` or `<Field element="x"></Field>`) → NULL.
            fields[name] = raw == null || raw.trim().length === 0 ? null : this.DecodeXml(raw.trim());
        }
        return fields;
    }

    /** The `Count` total when a response carries one (the documented paging-planning element). */
    private ExtractCountTotal(grids: InformzGridResult[]): number | null {
        for (const grid of grids) {
            for (const rec of grid.Records) {
                for (const [k, v] of Object.entries(rec)) {
                    if (k.toLowerCase() !== 'count') continue;
                    const n = Number(v);
                    if (Number.isFinite(n)) return n;
                }
            }
        }
        return null;
    }

    /** `<ActionStatus><Status>success|failure</Status><Message>…` for a named action's response block. */
    public ExtractActionStatus(document: string, action: string): { Status: string; Message: string } | null {
        if (!document) return null;
        const scope = this.ExtractElementInner(document, action) ?? document;
        const statusBlock = this.ExtractElementInner(scope, 'ActionStatus');
        if (!statusBlock) return null;
        return {
            Status: (this.ExtractElementInner(statusBlock, 'Status') ?? '').trim(),
            Message: this.DecodeXml((this.ExtractElementInner(statusBlock, 'Message') ?? '').trim()),
        };
    }

    /**
     * The created record's external ID. Preference order:
     *   1. a response element whose name matches the object's declared PK ignoring case/underscores
     *      (`MAILING_ID` ↔ `<MailingID>`);
     *   2. the identity the caller SUBMITTED — for the `Subscribe` upsert the vendor returns only a
     *      status + counts, and the record's durable identity is the `<ID>`/`<Email>` key that was sent.
     */
    private ExtractActionID(
        document: string,
        obj: MJIntegrationObjectEntity,
        attributes: Record<string, unknown>,
    ): string | undefined {
        const fields = this.GetCachedFields(obj.ID);
        const pkNames = this.PrimaryKeyFieldNames(fields);
        const squash = (s: string): string => s.toLowerCase().replace(/[^a-z0-9]/g, '');
        for (const pk of pkNames) {
            const target = squash(pk);
            const elementRe = /<(?:\w+:)?([A-Za-z0-9_]+)\s*>([^<]*)<\/(?:\w+:)?\1>/g;
            let match: RegExpExecArray | null;
            while ((match = elementRe.exec(document)) !== null) {
                if (squash(match[1]) === target && match[2].trim().length > 0) return match[2].trim();
            }
        }
        for (const key of ['ID', 'id', 'user_id', 'Email', 'email']) {
            const found = Object.keys(attributes).find(k => k.toLowerCase() === key.toLowerCase());
            if (found && attributes[found] != null && String(attributes[found]).trim().length > 0) {
                return String(attributes[found]).trim();
            }
        }
        return undefined;
    }

    // ── Fault handling / classification ──────────────────────────────────────────────────────────

    /** The parsed fault on a response, or null. */
    public ExtractFault(body: unknown): InformzFault | null {
        if (body && typeof body === 'object') {
            const f = (body as Record<string, unknown>)._fault;
            if (f && typeof f === 'object') {
                const rec = f as Record<string, unknown>;
                return { Code: String(rec.Code ?? 'UNKNOWN'), Reason: String(rec.Reason ?? 'unknown SOAP fault') };
            }
        }
        return null;
    }

    /**
     * Maps a fault (or transport failure) onto the engine's `SyncErrorCode` space. The vendor's own code
     * table is explicitly NON-EXHAUSTIVE ("SOME possible SOAP fault codes"), so codes are matched by
     * PATTERN — never against a frozen list — and anything unrecognized falls through to the engine's
     * generic `ClassifyError`, not to a parse error.
     */
    public ClassifyFault(code: string | null, reason: string): SyncErrorCode {
        const c = (code ?? '').toLowerCase();
        if (/credential|validuser|systemaccess|ipaddress|brandnotfound|namespace/.test(c)) return 'CONFIGURATION_ERROR';
        if (/invaliddata|invaliddocument|invalidmessage|invalidgrid|unexpectedinput|unknownaction|unknownrequest|insufficient|mismatched|conflicting|multipledefault/.test(c)) {
            return 'VALIDATION_ERROR';
        }
        if (/itemnotfound/.test(c)) return 'MATCH_RESOLUTION_ERROR';
        if (/configurationerror/.test(c)) return 'CONFIGURATION_ERROR';
        return ClassifyError(new Error(`${code ?? ''} ${reason}`)).Code;
    }

    /**
     * Raises a classified error for a faulted or non-2xx response. Called on EVERY AAPI reply because an
     * application fault arrives as HTTP 500 with a 200-shaped body path — status alone proves nothing.
     */
    protected ThrowOnFault(response: RESTResponse, operation: string): void {
        const fault = this.ExtractFault(response.Body);
        if (fault) {
            throw new InformzRequestError(
                `Informz SOAP Fault on ${operation} [${fault.Code}]: ${fault.Reason}`,
                response.Status, fault.Code, this.RetryAfterFromHeaders(response.Headers),
                this.ClassifyFault(fault.Code, fault.Reason),
            );
        }
        if (response.Status < 200 || response.Status >= 300) {
            const retryAfterMs = this.RetryAfterFromHeaders(response.Headers);
            const throttled = response.Status === 429 || response.Status === 503;
            throw new InformzRequestError(
                `Informz ${operation} failed: HTTP ${response.Status}${throttled ? ' (rate limited)' : ''}`,
                response.Status, null, retryAfterMs,
                throttled ? 'RATE_LIMIT_EXCEEDED' : ClassifyError(new Error(`HTTP ${response.Status}`)).Code,
            );
        }
        const document = this.ResponseDocument(response.Body);
        if (!document) {
            throw new InformzRequestError(
                `Informz ${operation} returned HTTP ${response.Status} with no AAPI document in the SOAP body.`,
                response.Status, null, undefined, 'CONNECTOR_ERROR',
            );
        }
    }

    /** Parses `Retry-After` (delta-seconds or HTTP-date) and `X-RateLimit-Reset` into milliseconds. */
    private RetryAfterFromHeaders(headers: Record<string, string> | undefined): number | undefined {
        if (!headers) return undefined;
        const lower: Record<string, string> = {};
        for (const [k, v] of Object.entries(headers)) lower[k.toLowerCase()] = v;
        const retryAfter = lower['retry-after'];
        if (retryAfter) {
            const seconds = Number(retryAfter);
            if (Number.isFinite(seconds) && seconds >= 0) return Math.round(seconds * 1000);
            const when = Date.parse(retryAfter);
            if (!Number.isNaN(when)) return Math.max(0, when - Date.now());
        }
        const reset = lower['x-ratelimit-reset'];
        if (reset) {
            const n = Number(reset);
            if (Number.isFinite(n) && n > 0) {
                // Epoch seconds vs a relative delta — both are seen in the wild; treat a large value as epoch.
                return n > 1_000_000_000 ? Math.max(0, n * 1000 - Date.now()) : Math.round(n * 1000);
            }
        }
        return undefined;
    }

    private BuildCRUDError(err: unknown, operation: string, objectName: string): CRUDResult {
        const message = err instanceof Error ? err.message : String(err);
        const status = err instanceof InformzRequestError ? err.Status : 500;
        return { Success: false, StatusCode: status, ErrorMessage: `${operation} failed for ${objectName}: ${message}` };
    }

    // ── Metadata readers (every vendor specific comes from metadata, never from code) ────────────

    /** The `<Grid type="…">` token for an object: `Configuration.gridType`, else the APIPath's last segment. */
    public GridTypeFor(obj: MJIntegrationObjectEntity): string {
        const cfg = this.ReadObjectConfig(obj);
        const declared = typeof cfg.gridType === 'string' ? cfg.gridType.trim() : '';
        if (declared) return declared;
        const segments = (obj.APIPath ?? '').split('/').filter(s => s.length > 0);
        const last = segments[segments.length - 1];
        if (!last) {
            throw new Error(`Informz object "${obj.Name}" has no grid token (Configuration.gridType) and no usable APIPath.`);
        }
        return last;
    }

    /** The full declared `<ReturnFields>` set — response-metadata pseudo-fields (`Count`) excluded. */
    public ReturnFieldsFor(fields: MJIntegrationObjectFieldEntity[], requested?: string[]): string[] {
        const declared = fields
            .filter(f => (f.Category ?? '') !== 'Response Metadata')
            .map(f => f.Name);
        if (!requested || requested.length === 0) return declared;
        const wanted = new Set(requested.map(r => r.toLowerCase()));
        const narrowed = declared.filter(n => wanted.has(n.toLowerCase()));
        return narrowed.length > 0 ? narrowed : declared;
    }

    /**
     * The stable `<SortField>`: the IO's declared `StableOrderingKey`, else its first declared PK component,
     * else its watermark field. Offset paging over a mutating table DROPS and DUPLICATES rows without one,
     * so a sort key is always emitted for a paged grid.
     */
    public SortFieldFor(obj: MJIntegrationObjectEntity, fields: MJIntegrationObjectFieldEntity[]): string | null {
        const declared = (obj.StableOrderingKey ?? '').trim();
        if (declared) return declared;
        const pk = this.PrimaryKeyFieldNames(fields);
        if (pk.length > 0) return pk[0];
        return (obj.IncrementalWatermarkField ?? '').trim() || null;
    }

    /**
     * Incremental conditions. A GTE `<Condition>` on the IO's DECLARED `IncrementalWatermarkField` — the
     * vendor's only delta mechanism (no cursor, no delta token, no webhook). No declared watermark field,
     * or no watermark value yet ⇒ NO condition (a full scan); the connector never synthesizes a watermark.
     */
    public BuildIncrementalConditions(obj: MJIntegrationObjectEntity, watermarkValue: string | null): InformzCondition[] {
        if (!obj.SupportsIncrementalSync) return [];
        const field = (obj.IncrementalWatermarkField ?? '').trim();
        if (!field || !watermarkValue) return [];
        return [{ DataElement: field, Comparator: 'GTE', DataValues: [this.FormatWatermark(watermarkValue)] }];
    }

    /**
     * Wire timestamp format. Values returned by the API are ALREADY UTC (`…Z`, converted from the vendor's
     * internal EST storage), so a value read from a GridResponse is passed back VERBATIM — re-applying an
     * offset is the documented mis-implementation. A non-ISO value (epoch millis) is normalized to ISO.
     */
    public FormatWatermark(watermark: string): string {
        const trimmed = watermark.trim();
        if (/^\d{4}-\d{2}-\d{2}([T ]|$)/.test(trimmed)) return trimmed;
        if (/^\d+$/.test(trimmed)) {
            const asNumber = Number(trimmed);
            if (Number.isFinite(asNumber) && asNumber > 100_000_000_000) return new Date(asNumber).toISOString();
        }
        const parsed = Date.parse(trimmed);
        return Number.isNaN(parsed) ? trimmed : new Date(parsed).toISOString();
    }

    /** Max watermark value seen in a fully-parsed page, or undefined when the object is not incremental. */
    public ComputeWatermark(obj: MJIntegrationObjectEntity, records: Record<string, unknown>[]): string | undefined {
        if (!obj.SupportsIncrementalSync) return undefined;
        const field = (obj.IncrementalWatermarkField ?? '').trim();
        if (!field) return undefined;
        const lower = field.toLowerCase();
        let max: string | undefined;
        for (const record of records) {
            for (const [k, v] of Object.entries(record)) {
                if (k.toLowerCase() !== lower || v == null) continue;
                const s = String(v);
                if (!max || s > max) max = s;
            }
        }
        return max;
    }

    /** Page size: the connection override, else the IO's DefaultPageSize, bounded by BatchSize and 1,000. */
    public ResolvePageSize(obj: MJIntegrationObjectEntity, ctx: FetchContext, auth: InformzAuthContext): number {
        const declared = obj.DefaultPageSize && obj.DefaultPageSize > 0 ? obj.DefaultPageSize : VENDOR_MAX_ROWS_PER_REQUEST;
        const batch = ctx.BatchSize && ctx.BatchSize > 0 ? ctx.BatchSize : declared;
        const override = auth.PageSize && auth.PageSize > 0 ? auth.PageSize : null;
        return Math.max(1, Math.min(override ?? Math.min(declared, batch), VENDOR_MAX_ROWS_PER_REQUEST));
    }

    /** The ActionRequest action element name: `Create/UpdateBodyKey`, else the path's last segment. */
    public ActionNameFor(bodyKey: string | null, apiPath: string): string {
        const declared = (bodyKey ?? '').trim();
        if (declared) return declared;
        const segments = apiPath.split('/').filter(s => s.length > 0);
        const last = segments[segments.length - 1];
        if (!last) throw new Error(`Informz write path "${apiPath}" carries no action name.`);
        return last;
    }

    /** `Configuration.writeActions[].recordElement` for the action (null when the action has no record wrapper). */
    public RecordElementFor(obj: MJIntegrationObjectEntity, action: string): string | null {
        const cfg = this.ReadObjectConfig(obj);
        const actions = cfg.writeActions;
        if (!Array.isArray(actions)) return null;
        for (const entry of actions) {
            if (!entry || typeof entry !== 'object') continue;
            const rec = entry as Record<string, unknown>;
            if (String(rec.action ?? '') !== action) continue;
            const element = typeof rec.recordElement === 'string' ? rec.recordElement.trim() : '';
            return element.length > 0 ? element : null;
        }
        return null;
    }

    /** Injects the update target's ID under the record key when the caller didn't supply it. */
    private WithInjectedID(
        attributes: Record<string, unknown>,
        externalID: string,
        obj: MJIntegrationObjectEntity,
        recordElement: string | null,
    ): Record<string, unknown> {
        const out = { ...attributes };
        if (recordElement) {
            const hasID = Object.keys(out).some(k => k.toLowerCase() === 'id' || k.toLowerCase() === 'user_id');
            if (!hasID) out.ID = externalID;
            return out;
        }
        const pk = this.PrimaryKeyFieldNames(this.GetCachedFields(obj.ID))[0];
        if (pk && out[pk] === undefined) out[pk] = externalID;
        return out;
    }

    // ── Config resolution ────────────────────────────────────────────────────────────────────────

    /** Resolves the connection config from the credential store (secrets) ∪ Configuration JSON (overrides). */
    protected async ParseConfig(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<InformzConfig> {
        const raw: Record<string, unknown> = {};
        if (companyIntegration.CredentialID) {
            Object.assign(raw, await this.LoadCredentialValues(companyIntegration.CredentialID, contextUser));
        }
        Object.assign(raw, this.ReadConnectionSettings(companyIntegration));

        const pick = (...keys: string[]): string | undefined => {
            for (const key of keys) {
                for (const [k, v] of Object.entries(raw)) {
                    if (k.toLowerCase() === key.toLowerCase() && v != null && String(v).length > 0) return String(v);
                }
            }
            return undefined;
        };
        const pageSizeRaw = pick('pageSize', 'numberOfRows');
        const pageSize = pageSizeRaw != null && /^\d+$/.test(pageSizeRaw) ? Number(pageSizeRaw) : null;
        const candidate: InformzConfig = {
            User: pick('User', 'Username', 'user') ?? '',
            Password: pick('Password', 'pass') ?? '',
            BrandID: pick('BrandID', 'BrandId', 'brand_id', 'brand') ?? '',
            BrandName: pick('BrandName', 'brand_name') ?? '',
            Region: (pick('Region') ?? this.ReadTransportConfig(companyIntegration).defaultRegion ?? 'us').toLowerCase(),
            Endpoint: '',
            Namespace: this.ReadTransportConfig(companyIntegration).namespace ?? DEFAULT_NAMESPACE,
            PageSize: pageSize != null && pageSize > 0 ? Math.min(pageSize, VENDOR_MAX_ROWS_PER_REQUEST) : null,
        };
        candidate.Endpoint = this.ResolveEndpoint(companyIntegration, raw, candidate.Region);
        const parsed = ConfigSchema.safeParse(candidate);
        if (!parsed.success) {
            throw new Error(`Informz configuration invalid: ${parsed.error.issues.map(i => i.message).join('; ')}`);
        }
        return candidate;
    }

    private async LoadCredentialValues(credentialID: string, contextUser: UserInfo): Promise<Record<string, unknown>> {
        const md = new Metadata();
        const credential = await md.GetEntityObject<MJCredentialEntity>('MJ: Credentials', contextUser);
        const loaded = await credential.Load(credentialID);
        if (!loaded || !credential.Values) return {};
        try {
            return JSON.parse(credential.Values) as Record<string, unknown>;
        } catch {
            return {};
        }
    }

    /** `CompanyIntegration.Configuration` parsed as a flat settings map (never throws on malformed JSON). */
    private ReadConnectionSettings(companyIntegration: MJCompanyIntegrationEntity): Record<string, unknown> {
        if (!companyIntegration?.Configuration) return {};
        try {
            const parsed = JSON.parse(companyIntegration.Configuration) as unknown;
            return parsed && typeof parsed === 'object' && !Array.isArray(parsed) ? parsed as Record<string, unknown> : {};
        } catch {
            return {};
        }
    }

    /** `Integration.Configuration.Transport` — the vendor-wide endpoint table + namespace. */
    private ReadTransportConfig(companyIntegration: MJCompanyIntegrationEntity): {
        endpoints: Record<string, string>; defaultRegion: string; namespace: string;
    } {
        const fallback = { endpoints: { ...DEFAULT_ENDPOINTS }, defaultRegion: 'us', namespace: DEFAULT_NAMESPACE };
        const integration = IntegrationEngineBase.Instance.GetIntegrationByID(companyIntegration.IntegrationID);
        if (!integration?.Configuration) return fallback;
        try {
            const cfg = JSON.parse(integration.Configuration) as Record<string, unknown>;
            const transport = cfg.Transport;
            if (!transport || typeof transport !== 'object') return fallback;
            const t = transport as Record<string, unknown>;
            const endpoints: Record<string, string> = {};
            if (t.endpoints && typeof t.endpoints === 'object') {
                for (const [k, v] of Object.entries(t.endpoints as Record<string, unknown>)) {
                    if (typeof v === 'string' && v.length > 0) endpoints[k.toLowerCase()] = v;
                }
            }
            return {
                endpoints: Object.keys(endpoints).length > 0 ? endpoints : fallback.endpoints,
                defaultRegion: typeof t.defaultRegion === 'string' ? t.defaultRegion.toLowerCase() : 'us',
                namespace: typeof t.namespace === 'string' && t.namespace.length > 0 ? t.namespace : DEFAULT_NAMESPACE,
            };
        } catch {
            return fallback;
        }
    }

    /**
     * Region → endpoint. An explicit `BaseURL`/`Endpoint` in the connection Configuration wins (the operator
     * / offline-replay override); otherwise the region key selects from the Integration's endpoint table,
     * defaulting to the configured default region. No tenant host is ever baked here.
     */
    private ResolveEndpoint(
        companyIntegration: MJCompanyIntegrationEntity,
        settings: Record<string, unknown>,
        region?: string,
    ): string {
        for (const key of ['BaseURL', 'Endpoint', 'baseUrl', 'endpoint', 'url']) {
            const found = Object.entries(settings).find(([k]) => k.toLowerCase() === key.toLowerCase());
            if (found && typeof found[1] === 'string' && found[1].length > 0) return found[1];
        }
        const transport = this.ReadTransportConfig(companyIntegration);
        const settingsRegion = Object.entries(settings).find(([k]) => k.toLowerCase() === 'region');
        const wanted = (region ?? (typeof settingsRegion?.[1] === 'string' ? settingsRegion[1] : transport.defaultRegion)).toLowerCase();
        return transport.endpoints[wanted] ?? transport.endpoints[transport.defaultRegion] ?? DEFAULT_ENDPOINTS.us;
    }

    private ReadObjectConfig(obj: MJIntegrationObjectEntity): Record<string, unknown> {
        if (!obj.Configuration) return {};
        try {
            const parsed = JSON.parse(obj.Configuration) as unknown;
            return parsed && typeof parsed === 'object' && !Array.isArray(parsed) ? parsed as Record<string, unknown> : {};
        } catch {
            return {};
        }
    }

    // ── Record shaping ───────────────────────────────────────────────────────────────────────────

    /**
     * FULL-RECORD PASS-THROUGH. `Fields` carries the COMPLETE parsed source record — every
     * `<Field element="…">` the brand returned, including undeclared tenant demographics / interests — so
     * the framework's custom-column capture can see them. Identity is the declared PK when every component
     * is present, else a deterministic CONTENT HASH (stable across passes, never a volatile field), which
     * is also stamped into a single empty PK column so the row remains storable.
     */
    private BuildRecord(
        raw: Record<string, unknown>,
        objectType: string,
        pkFieldNames: string[],
    ): ExternalRecord {
        const allPkPresent = pkFieldNames.length > 0
            && pkFieldNames.every(name => raw[name] != null && serializeKeyValue(raw[name]).length > 0);
        const resolvedID = allPkPresent
            ? pkFieldNames.map(name => serializeKeyValue(raw[name])).join('|')
            : computeContentHash(raw);
        let fields = raw;
        if (!allPkPresent && pkFieldNames.length === 1
            && (raw[pkFieldNames[0]] == null || serializeKeyValue(raw[pkFieldNames[0]]).length === 0)) {
            fields = { ...raw, [pkFieldNames[0]]: resolvedID };
        }
        return { ExternalID: resolvedID, ObjectType: objectType, Fields: fields };
    }

    /** Declared PK components in Sequence order (empty when the object declares none). */
    public PrimaryKeyFieldNames(fields: MJIntegrationObjectFieldEntity[]): string[] {
        return fields
            .filter(f => f.IsPrimaryKey)
            .sort((a, b) => a.Sequence - b.Sequence)
            .map(f => f.Name);
    }

    // ── XML utilities ────────────────────────────────────────────────────────────────────────────

    private ReadAttribute(attrs: string, name: string): string | null {
        const re = new RegExp(`${name}\\s*=\\s*("([^"]*)"|'([^']*)')`, 'i');
        const m = attrs.match(re);
        if (!m) return null;
        return (m[2] ?? m[3] ?? '').trim();
    }

    /** Inner content of the first element with the given LOCAL name (namespace-agnostic). */
    private ExtractElementInner(xml: string, localName: string): string | null {
        const escaped = localName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        const re = new RegExp(`<(?:\\w+:)?${escaped}(?:\\s[^>]*)?>([\\s\\S]*?)<\\/(?:\\w+:)?${escaped}>`, 'i');
        const m = xml.match(re);
        return m ? m[1] : null;
    }

    private HeadersToObject(headers: Headers): Record<string, string> {
        const out: Record<string, string> = {};
        headers.forEach((value, key) => { out[key.toLowerCase()] = value; });
        return out;
    }

    private ScalarText(value: unknown): string {
        if (value instanceof Date) return value.toISOString();
        return String(value);
    }

    private EscapeXml(value: string): string {
        return value
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&apos;');
    }

    private DecodeXml(value: string): string {
        return value
            .replace(/&lt;/g, '<')
            .replace(/&gt;/g, '>')
            .replace(/&quot;/g, '"')
            .replace(/&apos;/g, "'")
            .replace(/&#(\d+);/g, (_m, d: string) => String.fromCharCode(Number(d)))
            .replace(/&amp;/g, '&');
    }
}

/** Tree-shaking prevention — import and call from the package entry point / Open App bootstrap. */
export function LoadInformzConnector(): void { /* no-op */ }
