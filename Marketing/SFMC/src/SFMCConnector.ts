/**
 * SFMCConnector — Salesforce Marketing Cloud **ENGAGEMENT** (formerly ExactTarget / Fuel).
 *
 * ONE VENDOR, TWO TRANSPORTS. Marketing Cloud Engagement is genuinely dual-protocol and the vendor says
 * so itself ("The APIs don't have full parity, and you may need to use both SOAP and REST"). Every
 * Integration Object row therefore carries a `Configuration.transport` marker of `rest` or `soap`, and
 * THAT marker — never a list in this file — decides how the object is read and written:
 *
 *   • `rest` → a JSON request against the tenant's REST instance URL using the IO's `APIPath` + method,
 *              paged with the vendor's `$`-prefixed params (`$page` / `$pageSize` / `$orderBy`).
 *   • `soap` → a POST of a partnerAPI envelope to the tenant's SOAP instance URL, where the OAuth token
 *              rides the `<fueloauth>` SOAP header and `RetrieveRequest.ObjectType` selects the record
 *              set, paged by `OverallStatus=MoreDataAvailable` → `ContinueRequest(RequestID)`.
 *
 * SOAP rides over HTTP here: this class extends `BaseRESTIntegrationConnector`. The engine exports only
 * `BaseIntegrationConnector` and `BaseRESTIntegrationConnector` — there is NO `BaseSOAPIntegrationConnector`
 * in this framework, and inventing one would be a fiction.
 *
 * ZERO TENANT HOST IS BAKED. The vendor's hosts are tenant-subdomained (`{subdomain}.rest.…` /
 * `{subdomain}.soap.…`), and the REST and SOAP base URIs are READ FROM THE TOKEN RESPONSE
 * (`rest_instance_url` / `soap_instance_url`). Only if the token response omits them does the connector
 * fall back to an operator override and then to substituting the connection's own subdomain into the
 * documented template. No host, subdomain, MID or account id appears anywhere in this file.
 *
 * WHY THE CRUD + FETCH METHODS ARE OVERRIDDEN (the "genuinely idiosyncratic" branch of the routing rule):
 *   1. The SOAP half has ONE URL for every object and selects the object INSIDE a posted XML envelope —
 *      the base's `baseURL + APIPath` GET cannot express that.
 *   2. The REST half addresses path parameters in Express style (`/hub/v1/campaigns/:id/assets`), which
 *      the base's `{ID}`-only `SubstituteIDInPath` leaves literal — a broken URL.
 *   3. REST pagination uses `$`-prefixed params with a PER-ENDPOINT page-size maximum, which the base's
 *      generic `page`/`pageSize` builder does not emit.
 * Everything those overrides need still comes from METADATA (the IO's `Configuration.transport`,
 * `soapObjectType`, `pagination`, `incrementalFilterFormat`, `IncrementalWatermarkField`,
 * `StableOrderingKey`, the per-operation `Create*`/`Update*`/`Delete*` columns and the declared IOF set).
 * There is NO object catalog, NO field catalog and NO constraint baked into this file.
 *
 * DATA EXTENSIONS ARE DISCOVERED, NEVER DECLARED. The MECHANISM (`DataExtension`, `DataExtensionField`,
 * `DataExtensionObject[key]`) is vendor-wide and lives in metadata; the individual Data Extensions of a
 * connection are enumerated AT RUNTIME by `DiscoverObjects` (SOAP Retrieve of `DataExtension`) and their
 * columns by `DiscoverFields` (SOAP Retrieve of `DataExtensionField`). Every SFMC Data Extension is
 * customer-defined, so a DE row's columns are tenant-specific by construction and reach
 * `ExternalRecord.Fields` verbatim (full-record pass-through) for the framework's custom-column capture.
 * `DiscoveryIsAuthoritative` stays FALSE — nothing may EVER be deactivated from a discovery result.
 *
 * THROTTLING IS TRANSPORT-SPECIFIC. The vendor documents SOAP throttling as **HTTP 500** carrying a SOAP
 * fault (`faultstring`=`Rate Limited`, `apifault/Code`=17) and REST throttling as **HTTP 429** with a JSON
 * body (`errorcode` 50100 with `Retry-After`, or 50200 with none). `ClassifyError` branches on transport
 * and treats throttle-shaped 500s as retryable-with-backoff rather than fatal — a SOAP service returns 500
 * for application faults, so HTTP status alone is never the signal.
 *
 * NOTHING FROM A NEIGHBOURING PRODUCT: no `api.salesforce.com` / Data Cloud (Marketing Cloud NEXT), no
 * `pi.pardot.com` (Account Engagement), no SOQL / `/services/data` / sObject describe (Salesforce CRM,
 * which ships its own connector).
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
    OAuth2TokenManager,
    computeContentHash,
    serializeKeyValue,
    type ConnectionTestResult,
    type CreateRecordContext,
    type CRUDResult,
    type DeleteRecordContext,
    type ExternalFieldSchema,
    type ExternalObjectSchema,
    type ExternalRecord,
    type FetchBatchResult,
    type FetchContext,
    type FetchWarning,
    type GetRecordContext,
    type OAuth2Token,
    type PaginationState,
    type PaginationType,
    type RESTAuthContext,
    type RESTResponse,
    type SourceFieldInfo,
    type SourceObjectInfo,
    type SourceSchemaInfo,
    type SyncErrorCode,
    type UpdateRecordContext,
} from '@memberjunction/integration-engine';
import { mergeDeclaredWithSampledFields } from '@memberjunction/connector-schema-merge';

// ─── Wire constants (PROTOCOL mechanics only — never an object/field catalog) ────────────────────
// Every value below is a transport constant proven by the pinned vendor corpus
// (packages/Integration/connectors-registry/sfmc/sources/). The vendor's object and field universe
// lives in metadata and in runtime discovery — never here.

/** Tenant-subdomained host templates. Used ONLY when the token response carries no instance URL. */
const AUTH_HOST_TEMPLATE = 'https://{subdomain}.auth.marketingcloudapis.com';
const REST_HOST_TEMPLATE = 'https://{subdomain}.rest.marketingcloudapis.com';
const SOAP_HOST_TEMPLATE = 'https://{subdomain}.soap.marketingcloudapis.com/Service.asmx';
/** The v2 token endpoint path (Configuration.BaseURIModel.template.tokenPath). */
const TOKEN_PATH = '/v2/token';
/** partnerAPI target namespace (etframework.partnerAPI.wsdl `targetNamespace`). */
const PARTNER_NS = 'http://exacttarget.com/wsdl/partnerAPI';
/** SOAP 1.1 envelope namespace. */
const SOAP_ENVELOPE_NS = 'http://schemas.xmlsoap.org/soap/envelope/';
/** XML Schema instance namespace — needed for `xsi:type` on Filter/Objects and `xsi:nil` on results. */
const XSI_NS = 'http://www.w3.org/2001/XMLSchema-instance';
/** Documented SOAP batch ceiling: "The SOAP API returns up to 2500 records at a time per retrieve call." */
const SOAP_BATCH_SIZE = 2500;
/** `RetrieveResponseMsg.OverallStatus` value that means "another batch is waiting". */
const MORE_DATA_AVAILABLE = 'MoreDataAvailable';
/** `apifault/Code` the vendor's own Rate Limiting page shows on a throttled SOAP call (HTTP 500). */
const SOAP_THROTTLE_FAULT_CODE = '17';
/** REST throttle custom error codes (error-handling.json: 50100 with Retry-After, 50200 without). */
const REST_THROTTLE_ERROR_CODES = new Set([50100, 50200]);
/** Refresh margin on the short (~20 min) SFMC token — re-mint well before a long sync crosses expiry. */
const TOKEN_REFRESH_MARGIN_MS = 180_000;
/** Fallback DE row-read ObjectType prefix when the Integration row declares no DynamicObjectModel. */
const DEFAULT_DE_ROW_OBJECT_TYPE = 'DataExtensionObject';
/** Fallback ObjectType for enumerating a business unit's Data Extensions. */
const DEFAULT_DE_OBJECT_TYPE = 'DataExtension';
/** Fallback ObjectType for enumerating a Data Extension's columns. */
const DEFAULT_DE_FIELD_OBJECT_TYPE = 'DataExtensionField';
/** Max pages a single REST fetch call will walk before yielding back to the engine (runaway guard). */
const MAX_REST_PAGES_PER_CALL = 500;
/** Max SOAP continuation batches a single fetch call will walk before yielding (runaway guard). */
const MAX_SOAP_BATCHES_PER_CALL = 200;
/** Parallelism cap for the best-effort sample-union sweep in IntrospectSchema. */
const INTROSPECT_CONCURRENCY = 8;

// ─── Types ───────────────────────────────────────────────────────────────────────────────────────

/** Which wire protocol an Integration Object rides. Read from `Configuration.transport`. */
export type SFMCTransport = 'rest' | 'soap';

/** The four partnerAPI operations this connector issues (WSDL `soapAction` values). */
export type SFMCSoapOperation = 'Retrieve' | 'Create' | 'Update' | 'Delete';

/** Resolved per-connection settings (credential store ∪ CompanyIntegration.Configuration). */
export interface SFMCConfig {
    ClientID: string;
    ClientSecret: string;
    /** Tenant subdomain — the ONLY tenant identifier the connector ever sees, and it comes from config. */
    Subdomain: string;
    /** Optional business-unit MID sent as `account_id` on the token request. */
    AccountID: string | null;
    /** Optional space-delimited scope list. */
    Scope: string | null;
    /** Operator override for the AUTH host (offline replay / private stack). Never a baked default. */
    AuthBaseURL: string | null;
    /** Operator override for the REST host — used ONLY when the token response omits `rest_instance_url`. */
    RestBaseURL: string | null;
    /** Operator override for the SOAP host — used ONLY when the token response omits `soap_instance_url`. */
    SoapBaseURL: string | null;
    /** Operator-supplied values for Express-style `:params` in an IO's APIPath, by object then by param. */
    PathParams: Record<string, Record<string, string>>;
}

/** Auth context threaded through every request: the bearer token plus the token-derived base URIs. */
export interface SFMCAuthContext extends RESTAuthContext {
    Token: string;
    ExpiresAt: Date;
    /** Tenant REST base URI — `rest_instance_url` when the token response carried it. */
    RestBaseURL: string;
    /** Tenant SOAP base URI (the `/Service.asmx` door) — `soap_instance_url` when present. */
    SoapBaseURL: string;
    /** True when the base URIs came from the token response rather than a fallback. */
    BaseURLsFromToken: boolean;
}

/** The structured body handed to {@link SFMCConnector.MakeHTTPRequest} for a SOAP call. */
export interface SFMCSoapRequest {
    Operation: SFMCSoapOperation;
    /** The fully-formed partnerAPI SOAP envelope (already token-bearing). */
    Envelope: string;
    /** The `ObjectType` / `xsi:type` the envelope addresses — diagnostics + mock routing. */
    ObjectType: string;
}

/** A parsed `<soap:Fault>` — `faultstring` plus the vendor's `<apifault>` `Code`/`Message` detail. */
export interface SFMCSoapFault {
    FaultString: string;
    Code: string;
    Message: string;
}

/** The normalized body of a partnerAPI reply, as carried on `RESTResponse.Body._soap`. */
export interface SFMCSoapBody {
    /** `OverallStatus` — `OK`, `MoreDataAvailable`, `Error`, … */
    OverallStatus: string;
    /** `RequestID` — the continuation token for the next `ContinueRequest`. */
    RequestID: string | null;
    /** `Results` elements parsed into plain records (full source shape preserved). */
    Records: Record<string, unknown>[];
    /** Per-`Results` `StatusCode`/`StatusMessage` on a Create/Update/Delete response. */
    ResultStatuses: Array<{ StatusCode: string; StatusMessage: string; NewID: string | null; NewObjectID: string | null }>;
    /** The parsed fault when the reply was a SOAP Fault. */
    Fault: SFMCSoapFault | null;
}

/** A REST error body (`{ message, errorcode, documentation, retryAfter }`) parsed from a non-2xx reply. */
export interface SFMCRestError {
    Message: string;
    ErrorCode: number | null;
    RetryAfterSeconds: number | null;
}

/** Error thrown for a faulted / non-2xx SFMC call. Carries the throttle hint for the adaptive limiter. */
export class SFMCRequestError extends Error {
    public readonly Status: number;
    public readonly Transport: SFMCTransport;
    public readonly VendorCode: string | null;
    public readonly RetryAfterMs: number | undefined;
    public readonly SyncCode: SyncErrorCode;
    constructor(
        message: string,
        status: number,
        transport: SFMCTransport,
        vendorCode: string | null,
        retryAfterMs: number | undefined,
        syncCode: SyncErrorCode,
    ) {
        super(message);
        this.name = 'SFMCRequestError';
        this.Status = status;
        this.Transport = transport;
        this.VendorCode = vendorCode;
        this.RetryAfterMs = retryAfterMs;
        this.SyncCode = syncCode;
    }
}

/** A parsed XML element. Names are LOCAL (namespace prefix stripped) so parsing is prefix-agnostic. */
interface XmlNode {
    Name: string;
    Attributes: Record<string, string>;
    Children: XmlNode[];
    Text: string;
}

/** One resolved page-parameter set for a REST object, taken from its declared `Configuration.pagination`. */
interface RestPageParams {
    PageParam: string;
    SizeParam: string;
    OrderParam: string | null;
    MaxPageSize: number | null;
}

/** Zod shape for the resolved connection config (post key-normalization). */
const ConfigSchema = z.object({
    ClientID: z.string().min(1, 'SFMC ClientID is required (Installed Package API Integration client_id)'),
    ClientSecret: z.string().min(1, 'SFMC ClientSecret is required (Installed Package API Integration client_secret)'),
    // Subdomain is checked in ParseConfig, not here: it is required ONLY when no explicit AuthBaseURL
    // override is supplied (an operator/offline-replay stack addresses the auth host directly).
    Subdomain: z.string(),
    AccountID: z.string().nullable(),
    Scope: z.string().nullable(),
    AuthBaseURL: z.string().nullable(),
    RestBaseURL: z.string().nullable(),
    SoapBaseURL: z.string().nullable(),
    PathParams: z.record(z.string(), z.record(z.string(), z.string())),
});

// ─── Connector ───────────────────────────────────────────────────────────────────────────────────

// Registered under BOTH keys on purpose. The published Open App sets Integration.ClassName to the
// PACKAGE name, which is what MJCentral resolves at runtime; 'SFMCConnector' is kept so the MJ
// monorepo build and the verification ladder, which reference the class name, keep resolving it.
@RegisterClass(BaseIntegrationConnector, '@memberjunction/connector-sfmc')
@RegisterClass(BaseIntegrationConnector, 'SFMCConnector')
export class SFMCConnector extends BaseRESTIntegrationConnector {

    /** One OAuth2 token manager per CompanyIntegration, so two connections never share a token. */
    private readonly tokenManagers = new Map<string, OAuth2TokenManager>();
    /**
     * The Integration ID of the most recent call. `StableOrderingKey(objectName)` is handed no
     * connection, so the metadata lookup it needs is scoped by the last connection this connector
     * instance served — which is the same connection the engine is mid-sync on when it asks.
     */
    private lastIntegrationID: string | null = null;

    // ── Identity + capabilities ──────────────────────────────────────────────────────────────────

    /** Verbatim `MJ: Integrations.Name` — the checked three-way identity invariant. */
    public override get IntegrationName(): string { return 'sfmc'; }

    /** 45 SOAP + 22 REST Integration Objects carry a populated `CreateAPIPath`/`CreateMethod` pair. */
    public override get SupportsCreate(): boolean { return true; }
    /** Both transports publish per-object update verbs (SOAP `Update`; REST `PATCH`/`PUT`). */
    public override get SupportsUpdate(): boolean { return true; }
    /** Both transports publish per-object delete verbs (SOAP `Delete`; REST `DELETE`). */
    public override get SupportsDelete(): boolean { return true; }

    /**
     * FALSE, permanently. There is NO describe-ALL-objects endpoint on this vendor: SOAP `Describe`
     * answers per-object, `Retrieve DataExtension` enumerates only the DE tier, and
     * `/platform/v1/endpoints` covers only its own slice. Mixed coverage means an object's ABSENCE from
     * a discovery result proves nothing, so nothing may ever be deactivated from one.
     */
    public override get DiscoveryIsAuthoritative(): boolean { return false; }

    /**
     * FALSE. A SOAP `Retrieve` returns records in no documented order, so the last batch's
     * `ModifiedDate` is NOT a reliable global high-water mark; the engine must keep advancing to
     * wall-clock rather than trusting a possibly-stale max-seen.
     */
    public override get MonotonicWatermark(): boolean { return false; }

    /**
     * `null` — DELIBERATE. The vendor publishes NO numeric rate limit for either transport ("Marketing
     * Cloud reserves the right to throttle … The throttling rate depends on the rate necessary to
     * stabilize operations"), so declaring a tokens/sec figure here would be fabrication. Throttles are
     * handled REACTIVELY instead, via {@link ExtractRetryAfterMs} feeding the engine's adaptive limiter.
     */
    public override get RateLimitPolicy(): null { return null; }

    /** `null` — no documented concurrency ceiling exists for either transport; the engine's default applies. */
    public override get MaxConcurrencyHint(): null { return null; }

    /**
     * Keyset-resume hint for watermark-less objects: the IO's own declared `StableOrderingKey`.
     * Returns `null` when the object declares none (or the connection isn't known yet) — the engine
     * then simply forgoes keyset resume for that object.
     */
    public override StableOrderingKey(objectName: string): string | null {
        if (!this.lastIntegrationID) return null;
        const obj = IntegrationEngineBase.Instance.GetIntegrationObject(this.lastIntegrationID, objectName);
        const declared = (obj?.StableOrderingKey ?? '').trim();
        return declared.length > 0 ? declared : null;
    }

    /**
     * Throttle back-off hint. REST emits `Retry-After` (and a `retryAfter` body member) on 50100; SOAP
     * emits neither on its throttle-shaped 500, so that case returns `undefined` and the engine falls
     * back to exponential backoff — exactly what the vendor's own best-practices page prescribes.
     */
    public override ExtractRetryAfterMs(error: unknown): number | undefined {
        if (error instanceof SFMCRequestError) return error.RetryAfterMs;
        return undefined;
    }

    // ── TestConnection ───────────────────────────────────────────────────────────────────────────

    /**
     * Credential probe: mint an access token through the v2 endpoint. A successful client-credentials
     * grant proves the Installed Package, the client id/secret and (when supplied) the business-unit MID
     * all resolve — and it is the ONLY call that yields the tenant's REST/SOAP base URIs, so the result
     * reports which of them the token response supplied. Strictly non-mutating; the token is never echoed.
     */
    public async TestConnection(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<ConnectionTestResult> {
        try {
            const auth = await this.Authenticate(companyIntegration, contextUser);
            const origin = auth.BaseURLsFromToken ? 'token response' : 'subdomain template / operator override';
            return {
                Success: true,
                Message:
                    `Marketing Cloud Engagement reachable. Access token minted; base URIs resolved from the ${origin} ` +
                    `(REST ${this.HostOf(auth.RestBaseURL)}, SOAP ${this.HostOf(auth.SoapBaseURL)}).`,
                ServerVersion: 'Marketing Cloud Engagement — REST v1/v2 + SOAP partnerAPI (Service.asmx)',
            };
        } catch (err: unknown) {
            return { Success: false, Message: `SFMC connection failed: ${this.SafeMessage(err)}` };
        }
    }

    // ── Auth / transport seams (abstract on BaseRESTIntegrationConnector) ────────────────────────

    /**
     * OAuth2 **client credentials** against `{auth host}/v2/token`, through the shared
     * {@link OAuth2TokenManager} (no inlined grant logic). `account_id` is appended only when the
     * connection names a business unit, and `scope` only when configured.
     *
     * The token is SHORT-LIVED (vendor guidance ≈20 minutes, timed off `expires_in`) so the manager's
     * refresh margin is widened to {@link TOKEN_REFRESH_MARGIN_MS}: a long full sync re-mints PROACTIVELY
     * on the margin rather than waiting for a 401 to discover expiry mid-stream.
     *
     * The token response is ALSO where this vendor's tenant routing comes from — `rest_instance_url` and
     * `soap_instance_url` land on `OAuth2Token.Extra` and become the connector's base URIs. Neither the
     * token nor the client secret is ever logged.
     */
    protected async Authenticate(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<SFMCAuthContext> {
        const config = await this.ParseConfig(companyIntegration, contextUser);
        const manager = this.TokenManagerFor(companyIntegration);
        const extraParams: Record<string, string> = {};
        if (config.AccountID) extraParams.account_id = config.AccountID;

        const token = await manager.GetAccessToken(
            {
                TokenURL: `${this.AuthBaseFor(config).replace(/\/+$/, '')}${TOKEN_PATH}`,
                ClientId: config.ClientID,
                ClientSecret: config.ClientSecret,
                Scopes: config.Scope ?? undefined,
                ScopeParam: 'scope',
                ExtraParams: Object.keys(extraParams).length > 0 ? extraParams : undefined,
            },
            'client_credentials',
        );
        return this.BuildAuthContext(token, config);
    }

    /**
     * Bearer auth for REST; SOAP content headers + `SOAPAction` when a SOAP operation is named. The
     * partnerAPI carries its token in the `<fueloauth>` SOAP HEADER, not in an Authorization header, so a
     * SOAP request deliberately does not receive one.
     */
    protected BuildHeaders(auth: RESTAuthContext, soapOperation?: SFMCSoapOperation): Record<string, string> {
        if (soapOperation) {
            return {
                'Content-Type': 'text/xml; charset=utf-8',
                'Accept': 'text/xml',
                'SOAPAction': soapOperation,
            };
        }
        const ctx = auth as SFMCAuthContext;
        return {
            'Authorization': `Bearer ${ctx.Token}`,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        };
    }

    /**
     * The REST base URI for this connection. Preference order is the whole point of this method:
     * the TOKEN RESPONSE's `rest_instance_url` first, then an explicit operator override, then the
     * documented `{subdomain}.rest.marketingcloudapis.com` template. No host is baked.
     */
    protected GetBaseURL(companyIntegration: MJCompanyIntegrationEntity, auth: RESTAuthContext): string {
        const ctx = auth as SFMCAuthContext;
        if (ctx?.RestBaseURL) return ctx.RestBaseURL;
        const settings = this.ReadConnectionSettings(companyIntegration);
        const override = this.PickSetting(settings, 'RestBaseURL', 'restInstanceUrl', 'rest_instance_url');
        if (override) return override;
        return this.SubstituteSubdomain(REST_HOST_TEMPLATE, this.PickSetting(settings, 'Subdomain') ?? '');
    }

    /** The SOAP door for this connection — same preference order as {@link GetBaseURL}. */
    protected GetSoapURL(companyIntegration: MJCompanyIntegrationEntity, auth: RESTAuthContext): string {
        const ctx = auth as SFMCAuthContext;
        if (ctx?.SoapBaseURL) return ctx.SoapBaseURL;
        const settings = this.ReadConnectionSettings(companyIntegration);
        const override = this.PickSetting(settings, 'SoapBaseURL', 'soapInstanceUrl', 'soap_instance_url');
        if (override) return this.NormalizeSoapURL(override);
        return this.SubstituteSubdomain(SOAP_HOST_TEMPLATE, this.PickSetting(settings, 'Subdomain') ?? '');
    }

    /**
     * The token response's `soap_instance_url` is the tenant's SOAP HOST (`https://…soap.marketing
     * cloudapis.com/`), while the partnerAPI DOOR is `Service.asmx` on it — the form the documented
     * template and every vendor SOAP sample use. Appending the door when the instance URL carries no
     * `.asmx` path is what makes the token-derived base URI actually callable; a URL that already names
     * the door is left alone.
     */
    private NormalizeSoapURL(instanceURL: string): string {
        return /\.asmx(\/|$|\?)/i.test(instanceURL) ? instanceURL : this.JoinURL(instanceURL, 'Service.asmx');
    }

    /**
     * The single HTTP boundary for BOTH transports. A {@link SFMCSoapRequest} body means "POST this
     * partnerAPI envelope and parse the reply as SOAP"; anything else is a JSON REST request. Mocked
     * test subclasses override THIS method, so they capture the exact outbound envelope/JSON either way.
     */
    protected async MakeHTTPRequest(
        auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown,
    ): Promise<RESTResponse> {
        const soap = this.AsSoapRequest(body);
        if (soap) {
            const httpResponse = await fetch(url, { method, headers, body: soap.Envelope });
            const text = await httpResponse.text();
            return this.ParseSoapResponse(text, httpResponse.status, this.HeadersToObject(httpResponse.headers));
        }
        const init: RequestInit = { method, headers };
        if (body !== undefined && method.toUpperCase() !== 'GET') init.body = JSON.stringify(body);
        const httpResponse = await fetch(url, init);
        const text = await httpResponse.text();
        return {
            Status: httpResponse.status,
            Body: this.ParseJsonBody(text),
            Headers: this.HeadersToObject(httpResponse.headers),
        };
    }

    /**
     * Strips the vendor envelope down to record maps, for BOTH transports.
     *
     * SOAP: the reply was already parsed into `{ _soap }` by {@link ParseSoapResponse}, so the records
     * are handed back directly. REST: the declared `ResponseDataKey` (`items` / `definitions` / `keys` /
     * `messages` / `operations` / `triggers` …) selects the collection; a bare array is returned as-is;
     * and a single-record endpoint (the 34 REST resources addressed by a path parameter) yields a
     * one-element array so the same pipeline handles it.
     */
    protected NormalizeResponse(rawBody: unknown, responseDataKey: string | null): Record<string, unknown>[] {
        const soapBody = this.AsSoapBody(rawBody);
        if (soapBody) return soapBody.Records;
        if (Array.isArray(rawBody)) return rawBody.filter(this.IsRecord).map(r => r);
        if (!this.IsRecord(rawBody)) return [];
        const body = rawBody;
        const declared = responseDataKey && Array.isArray(body[responseDataKey]) ? body[responseDataKey] : null;
        if (declared) return declared.filter(this.IsRecord);
        const generic = this.FirstArrayMember(body);
        if (generic) return generic.filter(this.IsRecord);
        // No collection member anywhere → this is a SINGLE record envelope (a `:param`-addressed resource).
        return Object.keys(body).length > 0 ? [body] : [];
    }

    /**
     * Pagination state, per transport.
     *
     * `Cursor` is the SOAP case: more data iff `OverallStatus === 'MoreDataAvailable'`, and the cursor is
     * the reply's `RequestID` — the exact value the next `ContinueRequest` must carry.
     *
     * `PageNumber` is the REST case and reads the vendor's OWN envelope: `links.next.href` is decisive
     * when present (the campaigns collection publishes it); otherwise a `count`/`page`/`pageSize` triple
     * decides. When the envelope declares NOTHING about paging, this returns `HasMore:false` and the
     * REST fetch loop falls back to the short-page rule — see {@link EnvelopeDeclaresPagination}.
     */
    protected ExtractPaginationInfo(
        rawBody: unknown,
        paginationType: PaginationType,
        currentPage: number,
        currentOffset: number,
        pageSize: number,
    ): PaginationState {
        void currentOffset;
        if (paginationType === 'None') return { HasMore: false };
        if (paginationType === 'Cursor') {
            const soapBody = this.AsSoapBody(rawBody);
            if (!soapBody) return { HasMore: false };
            const hasMore = soapBody.OverallStatus === MORE_DATA_AVAILABLE;
            const state: PaginationState = { HasMore: hasMore };
            if (hasMore && soapBody.RequestID) state.NextCursor = soapBody.RequestID;
            return state;
        }
        return this.ExtractRestPaginationInfo(rawBody, currentPage, pageSize);
    }

    // ── Discovery: declared catalog ∪ THIS connection's Data Extensions ──────────────────────────

    /**
     * Objects = the DECLARED catalog (credential-free, from the persisted metadata the base reads out of
     * the engine cache) UNION this connection's Data Extensions, ENUMERATED AT RUNTIME.
     *
     * The declared half is what makes discovery work with NO credential — the standard universe is always
     * returned, so a credential-free structure self-check re-yields it and never reads as drift. The live
     * credential is purely ADDITIVE: it contributes the tenant's own Data Extensions, which are
     * customer-defined and therefore cannot exist in declared metadata without baking tenant specifics.
     * Enumeration failure (no credential, network, permissions) degrades to the declared catalog —
     * `DiscoveryIsAuthoritative` is false, so an absent DE can never deactivate anything.
     */
    public override async DiscoverObjects(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<ExternalObjectSchema[]> {
        this.lastIntegrationID = companyIntegration.IntegrationID;
        const declared = await super.DiscoverObjects(companyIntegration, contextUser);
        const byName = new Map(declared.map(o => [o.Name, o]));
        for (const de of await this.EnumerateDataExtensions(companyIntegration, contextUser)) {
            const name = this.DataExtensionObjectName(companyIntegration, de.Key);
            if (byName.has(name)) continue;
            byName.set(name, {
                Name: name,
                Label: de.Name || de.Key,
                Description: de.Description || `Marketing Cloud Data Extension "${de.Name || de.Key}" (rows read via SOAP Retrieve ${name}).`,
                SupportsIncrementalSync: false,
                SupportsWrite: true,
            });
        }
        return Array.from(byName.values());
    }

    /**
     * Fields for a DECLARED object come from the persisted metadata (the base's cache-driven path, which
     * needs no credential). Fields for a DISCOVERED Data Extension are enumerated at RUNTIME from
     * `DataExtensionField` — the only place a tenant's DE columns exist — including that DE's own
     * declared primary key, nullability, length and precision, which the vendor DOES report per column.
     */
    public override async DiscoverFields(
        companyIntegration: MJCompanyIntegrationEntity,
        objectName: string,
        contextUser: UserInfo,
    ): Promise<ExternalFieldSchema[]> {
        this.lastIntegrationID = companyIntegration.IntegrationID;
        const deKey = this.DataExtensionKeyFromObjectName(companyIntegration, objectName);
        if (deKey) return this.EnumerateDataExtensionColumns(companyIntegration, deKey, contextUser);
        return super.DiscoverFields(companyIntegration, objectName, contextUser);
    }

    /**
     * Declared schema WIDENED by a live sample, then EXTENDED with this connection's Data Extensions.
     *
     * The sample-union half is the connector standard: `super.IntrospectSchema` returns the declared
     * objects, and each is merged with whatever `DiscoverFieldsViaFetch` actually measured, so a tenant's
     * undeclared members — Subscriber profile attributes, DE-row columns, anything the vendor's own docs
     * could not know — reach the schema instead of vanishing. The merge NEVER shrinks the declared set,
     * and a per-object sampling failure leaves the declared fields standing.
     *
     * `IsAuthoritative` stays false throughout (see {@link DiscoveryIsAuthoritative}).
     */
    public override async IntrospectSchema(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<SourceSchemaInfo> {
        this.lastIntegrationID = companyIntegration.IntegrationID;
        const schema = await super.IntrospectSchema(companyIntegration, contextUser);
        await this.RunBoundedTasks(schema.Objects, INTROSPECT_CONCURRENCY, async (obj) => {
            try {
                const sampled = await this.DiscoverFieldsViaFetch(companyIntegration, obj.ExternalName, contextUser);
                obj.Fields = mergeDeclaredWithSampledFields(obj.Fields, sampled);
            } catch { /* best-effort — declared fields remain authoritative on a sampling failure */ }
        });
        for (const de of await this.EnumerateDataExtensions(companyIntegration, contextUser)) {
            const name = this.DataExtensionObjectName(companyIntegration, de.Key);
            if (schema.Objects.some(o => o.ExternalName === name)) continue;
            const columns = await this.EnumerateDataExtensionColumns(companyIntegration, de.Key, contextUser);
            schema.Objects.push(this.DataExtensionSourceObject(name, de, columns));
        }
        return schema;
    }

    /** Assembles a discovered Data Extension into the engine's `SourceObjectInfo` shape. */
    private DataExtensionSourceObject(
        name: string,
        de: { Key: string; Name: string; Description: string },
        columns: ExternalFieldSchema[],
    ): SourceObjectInfo {
        const fields: SourceFieldInfo[] = columns.map(c => ({
            Name: c.Name,
            Label: c.Label,
            Description: c.Description,
            SourceType: c.DataType,
            IsRequired: c.IsRequired,
            AllowsNull: c.AllowsNull,
            MaxLength: c.MaxLength ?? null,
            Precision: c.Precision ?? null,
            Scale: c.Scale ?? null,
            DefaultValue: c.DefaultValue ?? null,
            IsPrimaryKey: c.IsPrimaryKey,
            IsForeignKey: false,
            ForeignKeyTarget: null,
        }));
        return {
            ExternalName: name,
            ExternalLabel: de.Name || de.Key,
            Description: de.Description || `Marketing Cloud Data Extension "${de.Name || de.Key}".`,
            Fields: fields,
            PrimaryKeyFields: columns.filter(c => c.IsPrimaryKey).map(c => c.Name),
            Relationships: [],
        };
    }

    /**
     * Runtime enumeration of THIS business unit's Data Extensions via SOAP `Retrieve DataExtension`.
     * Best-effort by design: any failure (no credential, no permission, network) yields `[]` so the
     * declared catalog still stands. Walks continuations, so a tenant with >2500 DEs is fully enumerated.
     */
    private async EnumerateDataExtensions(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<Array<{ Key: string; Name: string; Description: string }>> {
        const objectType = this.DeclaredMechanismType(companyIntegration, 0, DEFAULT_DE_OBJECT_TYPE);
        const rows = await this.RetrieveAllSafely(
            companyIntegration, contextUser, objectType,
            ['ObjectID', 'CustomerKey', 'Name', 'Description', 'IsSendable', 'CategoryID', 'ModifiedDate'],
        );
        const out: Array<{ Key: string; Name: string; Description: string }> = [];
        for (const row of rows) {
            const key = this.ScalarString(row.CustomerKey) ?? this.ScalarString(row.Name);
            if (!key) continue;
            out.push({
                Key: key,
                Name: this.ScalarString(row.Name) ?? key,
                Description: this.ScalarString(row.Description) ?? '',
            });
        }
        return out;
    }

    /**
     * Runtime enumeration of one Data Extension's COLUMNS via SOAP `Retrieve DataExtensionField`,
     * filtered to that DE by its CustomerKey. The vendor reports per-column type, length, precision,
     * scale, default, required-ness, nullability and primary-key membership, so every one of those is
     * PROVEN rather than inferred — nothing is fabricated when the vendor stays silent.
     */
    private async EnumerateDataExtensionColumns(
        companyIntegration: MJCompanyIntegrationEntity,
        dataExtensionKey: string,
        contextUser: UserInfo,
    ): Promise<ExternalFieldSchema[]> {
        const objectType = this.DeclaredMechanismType(companyIntegration, 1, DEFAULT_DE_FIELD_OBJECT_TYPE);
        const rows = await this.RetrieveAllSafely(
            companyIntegration, contextUser, objectType,
            ['ObjectID', 'Name', 'FieldType', 'MaxLength', 'Precision', 'Scale', 'DefaultValue',
                'IsRequired', 'IsPrimaryKey', 'IsNillable', 'Ordinal'],
            { Property: 'DataExtension.CustomerKey', Operator: 'equals', Value: dataExtensionKey },
        );
        return rows
            .map(row => this.DataExtensionColumnToSchema(row))
            .filter((f): f is ExternalFieldSchema => f !== null);
    }

    /** Maps one `DataExtensionField` record onto the engine's field-schema shape (provable flags only). */
    private DataExtensionColumnToSchema(row: Record<string, unknown>): ExternalFieldSchema | null {
        const name = this.ScalarString(row.Name);
        if (!name) return null;
        const isPrimaryKey = this.ScalarBoolean(row.IsPrimaryKey) === true;
        const isNillable = this.ScalarBoolean(row.IsNillable);
        const field: ExternalFieldSchema = {
            Name: name,
            Label: name,
            Description: `Tenant-defined Data Extension column (SFMC ${this.ScalarString(row.FieldType) ?? 'Text'}).`,
            DataType: this.MapDataExtensionFieldType(this.ScalarString(row.FieldType)),
            IsRequired: this.ScalarBoolean(row.IsRequired) === true,
            IsUniqueKey: isPrimaryKey,
            IsReadOnly: false,
            IsPrimaryKey: isPrimaryKey,
            MaxLength: this.ScalarNumber(row.MaxLength),
            Precision: this.ScalarNumber(row.Precision),
            Scale: this.ScalarNumber(row.Scale),
            DefaultValue: this.ScalarString(row.DefaultValue) ?? null,
        };
        // Provable-only: assert nullability ONLY when the vendor said so; silence stays undefined.
        if (isNillable !== null) field.AllowsNull = isNillable;
        return field;
    }

    /**
     * Vendor DE column type → the engine's generic type vocabulary. The SFMC set is fixed by the WSDL
     * (`Text`, `Number`, `Date`, `Boolean`, `EmailAddress`, `Phone`, `Decimal`, `Locale`); anything
     * unrecognized degrades to `string`, which is the safe widening.
     */
    private MapDataExtensionFieldType(fieldType: string | null): string {
        switch ((fieldType ?? '').toLowerCase()) {
            case 'number': return 'integer';
            case 'decimal': return 'decimal';
            case 'date': return 'datetime';
            case 'boolean': return 'boolean';
            default: return 'string';
        }
    }

    // ── Read path ────────────────────────────────────────────────────────────────────────────────

    /**
     * Transport dispatch for reads. The `Configuration.transport` marker on the IO decides — never a
     * list in this file. A DISCOVERED Data Extension (persisted by schema-sync with no marker of its
     * own, or not yet persisted at all) is recognised by its ObjectType-shaped NAME and routed to SOAP.
     */
    public override async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
        this.lastIntegrationID = ctx.CompanyIntegration.IntegrationID;
        const obj = this.TryGetCachedObject(ctx.CompanyIntegration.IntegrationID, ctx.ObjectName);
        if (!obj) {
            const deKey = this.DataExtensionKeyFromObjectName(ctx.CompanyIntegration, ctx.ObjectName);
            if (!deKey) throw new Error(`IntegrationObject not found: "${ctx.ObjectName}" for integration ${ctx.CompanyIntegration.IntegrationID}`);
            return this.FetchDataExtensionRows(ctx, deKey);
        }
        return this.ResolveTransport(obj) === 'soap' ? this.FetchSoapChanges(ctx, obj) : this.FetchRestChanges(ctx, obj);
    }

    /**
     * SOAP read. Issues `Retrieve` for the IO's declared `ObjectType`, then — while `OverallStatus` is
     * `MoreDataAvailable` — re-issues `ContinueRequest` with the returned `RequestID` until it is not.
     *
     * THIS LOOP IS THE WHOLE POINT: a single `Retrieve` returns ONE ~2500-record batch, so stopping
     * after it would silently cap every SOAP object at 2500 rows. The loop yields back to the engine when
     * the caller's `BatchSize` is reached, handing the `RequestID` over as `NextCursor` so the engine
     * resumes exactly where this call stopped — continuation state is never lost between calls.
     *
     * Incremental filtering uses ONLY what the IO declares: a `SimpleFilterPart` `greaterThan` on the
     * declared `IncrementalWatermarkField`. An IO with no declared watermark does a FULL scan; the
     * connector never invents one.
     */
    private async FetchSoapChanges(ctx: FetchContext, obj: MJIntegrationObjectEntity): Promise<FetchBatchResult> {
        const fields = this.GetCachedFields(obj.ID);
        const objectType = this.SoapObjectTypeFor(obj);
        const properties = this.RetrievePropertiesFor(obj, fields, ctx.RequestedSourceFields);
        const filter = this.SoapWatermarkFilter(obj, ctx.WatermarkValue);
        const auth = await this.Authenticate(ctx.CompanyIntegration, ctx.ContextUser);
        const url = this.GetSoapURL(ctx.CompanyIntegration, auth);
        const batchLimit = ctx.BatchSize && ctx.BatchSize > 0 ? ctx.BatchSize : SOAP_BATCH_SIZE;

        const raws: Record<string, unknown>[] = [];
        let continueRequestID: string | null = ctx.CurrentCursor ?? null;
        let overallStatus = '';
        let batches = 0;
        do {
            const envelope = this.BuildRetrieveEnvelope(auth, objectType, properties, continueRequestID ? null : filter, continueRequestID);
            const soapBody = await this.SendSoap(ctx.CompanyIntegration, auth, url, 'Retrieve', envelope, objectType);
            for (const row of soapBody.Records) raws.push(row);
            overallStatus = soapBody.OverallStatus;
            continueRequestID = soapBody.RequestID;
            batches++;
        } while (overallStatus === MORE_DATA_AVAILABLE && raws.length < batchLimit && batches < MAX_SOAP_BATCHES_PER_CALL);

        const hasMore = overallStatus === MORE_DATA_AVAILABLE;
        return this.BuildFetchResult(obj, ctx.ObjectName, fields, raws, {
            HasMore: hasMore,
            NextCursor: hasMore && continueRequestID ? continueRequestID : undefined,
        });
    }

    /**
     * REST read. Walks `$page` from the declared start until the vendor's own envelope says to stop
     * (`links.next` absent, or the `count`/`page`/`pageSize` triple exhausted) or a SHORT page arrives —
     * never one un-paged fetch. Page size is the IO's `DefaultPageSize` capped by that endpoint's OWN
     * declared maximum (`Configuration.pagination.pageSizeMax`; the campaigns collection caps at 50) and
     * by the caller's remaining batch capacity.
     *
     * A non-paginating IO (`SupportsPagination=false` / `PaginationType='None'`) issues exactly one
     * request; the 34 single-record resources addressed by an Express-style `:param` are that case, and
     * they emit a `PATH_PARAMS_UNRESOLVED` warning + zero rows rather than firing a malformed URL when no
     * value for the parameter has been supplied.
     */
    private async FetchRestChanges(ctx: FetchContext, obj: MJIntegrationObjectEntity): Promise<FetchBatchResult> {
        const fields = this.GetCachedFields(obj.ID);
        const resolved = this.ResolveRestPath(ctx.CompanyIntegration, obj);
        if (resolved.Unresolved.length > 0) {
            return { Records: [], HasMore: false, Warnings: [this.UnresolvedPathWarning(obj, resolved.Unresolved)] };
        }
        const auth = await this.Authenticate(ctx.CompanyIntegration, ctx.ContextUser);
        const base = this.GetBaseURL(ctx.CompanyIntegration, auth);
        const pathWithFilter = this.AppendRestWatermarkFilter(resolved.Path, obj, ctx.WatermarkValue);
        const fullPath = this.JoinURL(base, pathWithFilter);
        const headers = this.BuildHeaders(auth);
        const paginates = obj.SupportsPagination && obj.PaginationType !== 'None';

        if (!paginates) {
            const response = await this.MakeHTTPRequest(auth, fullPath, 'GET', headers);
            this.ThrowOnRestError(response, `GET ${resolved.Path}`);
            const rows = this.NormalizeResponse(response.Body, obj.ResponseDataKey);
            return this.BuildFetchResult(obj, ctx.ObjectName, fields, rows, { HasMore: false });
        }
        return this.FetchRestPages(ctx, obj, fields, auth, fullPath, headers);
    }

    /** The REST page walk itself — split out so {@link FetchRestChanges} stays a dispatcher. */
    private async FetchRestPages(
        ctx: FetchContext,
        obj: MJIntegrationObjectEntity,
        fields: MJIntegrationObjectFieldEntity[],
        auth: SFMCAuthContext,
        fullPath: string,
        headers: Record<string, string>,
    ): Promise<FetchBatchResult> {
        const params = this.RestPageParamsFor(obj);
        const batchLimit = ctx.BatchSize && ctx.BatchSize > 0 ? ctx.BatchSize : Number.MAX_SAFE_INTEGER;
        const raws: Record<string, unknown>[] = [];
        let page = ctx.CurrentPage && ctx.CurrentPage > 0 ? ctx.CurrentPage : 1;
        let hasMore = true;
        let pages = 0;

        while (hasMore && raws.length < batchLimit && pages < MAX_REST_PAGES_PER_CALL) {
            const pageSize = this.EffectivePageSize(obj, params, batchLimit - raws.length);
            const url = this.BuildRestPaginatedURL(fullPath, params, page, pageSize, obj.StableOrderingKey);
            const response = await this.MakeHTTPRequest(auth, url, 'GET', headers);
            this.ThrowOnRestError(response, `GET ${url}`);
            const rows = this.NormalizeResponse(response.Body, obj.ResponseDataKey);
            for (const row of rows) raws.push(row);
            pages++;
            if (rows.length === 0) { hasMore = false; break; }
            const state = this.ExtractPaginationInfo(response.Body, 'PageNumber', page, 0, pageSize);
            hasMore = this.EnvelopeDeclaresPagination(response.Body) ? state.HasMore : rows.length >= pageSize;
            page = state.NextPage ?? page + 1;
        }
        return this.BuildFetchResult(obj, ctx.ObjectName, fields, raws, {
            HasMore: hasMore,
            NextPage: hasMore ? page : undefined,
        });
    }

    /**
     * Reads rows out of an arbitrary Data Extension through the DECLARED key-addressed row reader —
     * SOAP `Retrieve DataExtensionObject[<CustomerKey>]`, whose `Properties` request lists that DE's
     * OWN columns (discovered at runtime, because every SFMC Data Extension is customer-defined).
     * The resulting record carries those columns verbatim, so a tenant column that exists in NO declared
     * metadata still reaches `ExternalRecord.Fields` and the framework's custom-column capture.
     */
    private async FetchDataExtensionRows(ctx: FetchContext, dataExtensionKey: string): Promise<FetchBatchResult> {
        const columns = await this.EnumerateDataExtensionColumns(ctx.CompanyIntegration, dataExtensionKey, ctx.ContextUser);
        if (columns.length === 0) {
            return { Records: [], HasMore: false, Warnings: [{
                Code: 'DE_COLUMNS_UNKNOWN',
                Message: `"${ctx.ObjectName}": no DataExtensionField columns could be enumerated for Data Extension "${dataExtensionKey}", and the SOAP Retrieve of a Data Extension REQUIRES an explicit Properties list — skipping rather than issuing an invalid request.`,
                Data: { object: ctx.ObjectName, dataExtensionKey },
            }] };
        }
        const auth = await this.Authenticate(ctx.CompanyIntegration, ctx.ContextUser);
        const url = this.GetSoapURL(ctx.CompanyIntegration, auth);
        const objectType = ctx.ObjectName;
        const batchLimit = ctx.BatchSize && ctx.BatchSize > 0 ? ctx.BatchSize : SOAP_BATCH_SIZE;
        const properties = columns.map(c => c.Name);
        const pkNames = columns.filter(c => c.IsPrimaryKey).map(c => c.Name);

        const raws: Record<string, unknown>[] = [];
        let continueRequestID: string | null = ctx.CurrentCursor ?? null;
        let overallStatus = '';
        let batches = 0;
        do {
            const envelope = this.BuildRetrieveEnvelope(auth, objectType, properties, null, continueRequestID);
            const soapBody = await this.SendSoap(ctx.CompanyIntegration, auth, url, 'Retrieve', envelope, objectType);
            for (const row of soapBody.Records) raws.push(row);
            overallStatus = soapBody.OverallStatus;
            continueRequestID = soapBody.RequestID;
            batches++;
        } while (overallStatus === MORE_DATA_AVAILABLE && raws.length < batchLimit && batches < MAX_SOAP_BATCHES_PER_CALL);

        const hasMore = overallStatus === MORE_DATA_AVAILABLE;
        return {
            Records: raws.map(r => this.BuildRecord(r, ctx.ObjectName, pkNames)),
            HasMore: hasMore,
            NextCursor: hasMore && continueRequestID ? continueRequestID : undefined,
        };
    }

    /**
     * Assembles a `FetchBatchResult`: FULL-RECORD pass-through into `ExternalRecord.Fields`, plus the
     * max-seen watermark. The watermark is computed from a FULLY-PARSED page only — any transport or
     * application fault throws upstream of here, so a partially-consumed batch never advances it.
     */
    private BuildFetchResult(
        obj: MJIntegrationObjectEntity,
        objectName: string,
        fields: MJIntegrationObjectFieldEntity[],
        raws: Record<string, unknown>[],
        pagination: { HasMore: boolean; NextPage?: number; NextCursor?: string },
    ): FetchBatchResult {
        const pkNames = this.PrimaryKeyFieldNames(fields);
        const result: FetchBatchResult = {
            Records: raws.map(r => this.BuildRecord(r, objectName, pkNames)),
            HasMore: pagination.HasMore,
        };
        if (pagination.NextPage !== undefined) result.NextPage = pagination.NextPage;
        if (pagination.NextCursor !== undefined) result.NextCursor = pagination.NextCursor;
        const watermark = this.ComputeWatermark(obj, raws);
        if (watermark) result.NewWatermarkValue = watermark;
        return result;
    }

    /**
     * Get-one, per transport. SOAP issues a `Retrieve` with an `equals` `SimpleFilterPart` per declared
     * PK component (composite keys arrive `|`-joined, matching the engine's key serialization); REST
     * substitutes the id into the declared update/read path and GETs it.
     */
    public override async GetRecord(ctx: GetRecordContext): Promise<ExternalRecord | null> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const contextUser = ctx.ContextUser as UserInfo;
        this.lastIntegrationID = ci.IntegrationID;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        const fields = this.GetCachedFields(obj.ID);
        return this.ResolveTransport(obj) === 'soap'
            ? this.GetSoapRecord(ci, contextUser, obj, fields, ctx.ExternalID)
            : this.GetRestRecord(ci, contextUser, obj, fields, ctx.ExternalID);
    }

    /** SOAP get-one: `Retrieve` filtered to the declared PK component(s). */
    private async GetSoapRecord(
        ci: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
        obj: MJIntegrationObjectEntity,
        fields: MJIntegrationObjectFieldEntity[],
        externalID: string,
    ): Promise<ExternalRecord | null> {
        const pkNames = this.PrimaryKeyFieldNames(fields);
        const parts = String(externalID).split('|');
        if (pkNames.length === 0 || parts.length !== pkNames.length) {
            throw new Error(
                `GetRecord for "${obj.Name}": external ID "${externalID}" does not match the declared primary key ` +
                `(${pkNames.join(', ') || 'none declared'}).`,
            );
        }
        const auth = await this.Authenticate(ci, contextUser);
        const objectType = this.SoapObjectTypeFor(obj);
        const envelope = this.BuildRetrieveEnvelope(
            auth, objectType, this.RetrievePropertiesFor(obj, fields),
            { Property: pkNames[0], Operator: 'equals', Value: parts[0] }, null,
        );
        const body = await this.SendSoap(ci, auth, this.GetSoapURL(ci, auth), 'Retrieve', envelope, objectType);
        const match = body.Records.find(r => pkNames.every((n, i) => this.ScalarString(r[n]) === parts[i])) ?? body.Records[0];
        return match ? this.BuildRecord(match, obj.Name, pkNames) : null;
    }

    /** REST get-one: the declared update path (or `APIPath/{id}`) with the id substituted, via GET. */
    private async GetRestRecord(
        ci: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
        obj: MJIntegrationObjectEntity,
        fields: MJIntegrationObjectFieldEntity[],
        externalID: string,
    ): Promise<ExternalRecord | null> {
        const auth = await this.Authenticate(ci, contextUser);
        const template = obj.UpdateAPIPath ?? `${obj.APIPath.replace(/\/+$/, '')}/:id`;
        const path = this.SubstituteRestParams(template, externalID, this.PathParamValues(ci, obj));
        const url = this.JoinURL(this.GetBaseURL(ci, auth), path);
        const response = await this.MakeHTTPRequest(auth, url, 'GET', this.BuildHeaders(auth));
        if (response.Status === 404) return null;
        this.ThrowOnRestError(response, `GET ${path}`);
        const rows = this.NormalizeResponse(response.Body, obj.ResponseDataKey);
        return rows.length > 0 ? this.BuildRecord(rows[0], obj.Name, this.PrimaryKeyFieldNames(fields)) : null;
    }

    // ── Write path ───────────────────────────────────────────────────────────────────────────────
    //
    // Overridden (not inherited) for the reason stated in the class header: the SOAP half posts a
    // partnerAPI envelope to one URL and the REST half uses Express-style `:params` the base's
    // `{ID}`-only substitution leaves literal. Both branches still read their verb, path, body shape and
    // id location from the SAME per-operation metadata columns the base would have used, and CREATE
    // still routes through `BuildCreatedResult` so a 2xx with no record id fails LOUDLY.
    //
    // ACTION-shaped and bulk/async operations recorded as out-of-scope in the Integration's
    // `Configuration.OutOfScopeObjectFamilies` / `ActionCatalogSummary` are DELIBERATELY UNWIRED: a
    // message send, an import start or a contact-delete request is not per-record create semantics and is
    // never smuggled into CreateRecord.

    /** Create, dispatched by transport. Requires the IO's `CreateAPIPath` + `CreateMethod` to be populated. */
    public override async CreateRecord(ctx: CreateRecordContext): Promise<CRUDResult> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const contextUser = ctx.ContextUser as UserInfo;
        this.lastIntegrationID = ci.IntegrationID;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        if (!obj.CreateAPIPath || !obj.CreateMethod) {
            throw new Error(
                `CreateRecord not supported for "${ctx.ObjectName}": CreateAPIPath / CreateMethod not configured on IntegrationObject.`,
            );
        }
        try {
            return this.ResolveTransport(obj) === 'soap'
                ? await this.SoapWrite(ci, contextUser, obj, 'Create', ctx.Attributes, null)
                : await this.RestWrite(ci, contextUser, obj, 'Create', ctx.Attributes, null);
        } catch (err: unknown) {
            return this.BuildCRUDError(err, 'CreateRecord', ctx.ObjectName);
        }
    }

    /** Update, dispatched by transport. Requires the IO's `UpdateAPIPath` + `UpdateMethod`. */
    public override async UpdateRecord(ctx: UpdateRecordContext): Promise<CRUDResult> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const contextUser = ctx.ContextUser as UserInfo;
        this.lastIntegrationID = ci.IntegrationID;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        if (!obj.UpdateAPIPath || !obj.UpdateMethod) {
            throw new Error(
                `UpdateRecord not supported for "${ctx.ObjectName}": UpdateAPIPath / UpdateMethod not configured on IntegrationObject.`,
            );
        }
        try {
            return this.ResolveTransport(obj) === 'soap'
                ? await this.SoapWrite(ci, contextUser, obj, 'Update', ctx.Attributes, ctx.ExternalID)
                : await this.RestWrite(ci, contextUser, obj, 'Update', ctx.Attributes, ctx.ExternalID);
        } catch (err: unknown) {
            return this.BuildCRUDError(err, 'UpdateRecord', ctx.ObjectName);
        }
    }

    /** Delete, dispatched by transport. Requires the IO's `DeleteAPIPath` + `DeleteMethod`. */
    public override async DeleteRecord(ctx: DeleteRecordContext): Promise<CRUDResult> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const contextUser = ctx.ContextUser as UserInfo;
        this.lastIntegrationID = ci.IntegrationID;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        if (!obj.DeleteAPIPath || !obj.DeleteMethod) {
            throw new Error(
                `DeleteRecord not supported for "${ctx.ObjectName}": DeleteAPIPath / DeleteMethod not configured on IntegrationObject.`,
            );
        }
        try {
            return this.ResolveTransport(obj) === 'soap'
                ? await this.SoapWrite(ci, contextUser, obj, 'Delete', {}, ctx.ExternalID)
                : await this.RestWrite(ci, contextUser, obj, 'Delete', {}, ctx.ExternalID);
        } catch (err: unknown) {
            return this.BuildCRUDError(err, 'DeleteRecord', ctx.ObjectName);
        }
    }

    /**
     * The SOAP write: a `CreateRequest` / `UpdateRequest` / `DeleteRequest` envelope whose `<Objects>`
     * carries `xsi:type="par:<ObjectType>"` and the record's own elements. Update and Delete inject the
     * target's identity under the IO's declared PK column when the caller did not supply it. Success is
     * read from each `Results/StatusCode` — a partnerAPI application failure arrives with HTTP 200 and
     * `StatusCode=Error`, so HTTP status alone is never the verdict.
     */
    private async SoapWrite(
        ci: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
        obj: MJIntegrationObjectEntity,
        operation: Exclude<SFMCSoapOperation, 'Retrieve'>,
        attributes: Record<string, unknown>,
        externalID: string | null,
    ): Promise<CRUDResult> {
        const fields = this.GetCachedFields(obj.ID);
        const objectType = this.SoapObjectTypeFor(obj);
        const payload = externalID === null
            ? attributes
            : this.WithInjectedKey(attributes, externalID, this.PrimaryKeyFieldNames(fields));
        const auth = await this.Authenticate(ci, contextUser);
        const envelope = this.BuildWriteEnvelope(auth, operation, objectType, payload);
        const body = await this.SendSoap(ci, auth, this.GetSoapURL(ci, auth), operation, envelope, objectType);

        const failure = body.ResultStatuses.find(r => r.StatusCode.toUpperCase() !== 'OK');
        if (failure) {
            return { Success: false, StatusCode: 200, ErrorMessage: `SFMC ${operation} ${objectType} failed: ${failure.StatusMessage || failure.StatusCode}` };
        }
        if (operation === 'Create') {
            const status = body.ResultStatuses[0];
            const created = status?.NewObjectID ?? status?.NewID ?? this.ScalarString(body.Records[0]?.ObjectID) ?? this.IdentityFromAttributes(attributes, this.PrimaryKeyFieldNames(fields));
            return this.BuildCreatedResult(created, 200, obj.Name);
        }
        return { Success: true, StatusCode: 200, ExternalID: externalID ?? '' };
    }

    /**
     * The REST write: the IO's declared method against its declared path, with Express-style `:params`
     * substituted from the external id (single-param paths) and from the operator's declared
     * `pathParams` map, and the body shaped per the declared `CreateBodyShape`/`CreateBodyKey`.
     */
    private async RestWrite(
        ci: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
        obj: MJIntegrationObjectEntity,
        operation: Exclude<SFMCSoapOperation, 'Retrieve'>,
        attributes: Record<string, unknown>,
        externalID: string | null,
    ): Promise<CRUDResult> {
        const spec = this.RestOperationSpec(obj, operation);
        const params = { ...this.PathParamValues(ci, obj), ...this.StringValued(attributes) };
        const path = this.SubstituteRestParams(spec.Path, externalID, params);
        const remaining = this.UnresolvedParams(path);
        if (remaining.length > 0) {
            return { Success: false, StatusCode: 400, ErrorMessage: `SFMC ${operation} ${obj.Name}: unresolved path parameter(s) ${remaining.join(', ')} in "${spec.Path}".` };
        }
        const auth = await this.Authenticate(ci, contextUser);
        const url = this.JoinURL(this.GetBaseURL(ci, auth), path);
        const body = operation === 'Delete' ? undefined : this.BuildOperationBody(attributes, spec.BodyShape, spec.BodyKey);
        const response = await this.MakeHTTPRequest(auth, url, spec.Method, this.BuildHeaders(auth), body);
        if (response.Status < 200 || response.Status >= 300) {
            const parsed = this.ParseRestError(response);
            return { Success: false, StatusCode: response.Status, ErrorMessage: `SFMC ${operation} ${obj.Name} failed: HTTP ${response.Status} — ${parsed.Message}` };
        }
        if (operation === 'Create') {
            return this.BuildCreatedResult(this.ExtractIDFromResponse(response, spec.IDLocation), response.Status, obj.Name);
        }
        return { Success: true, StatusCode: response.Status, ExternalID: externalID ?? '' };
    }

    /** The declared per-operation columns for a REST verb, read straight off the IO row. */
    private RestOperationSpec(
        obj: MJIntegrationObjectEntity,
        operation: Exclude<SFMCSoapOperation, 'Retrieve'>,
    ): { Path: string; Method: string; BodyShape: string | null; BodyKey: string | null; IDLocation: string | null } {
        if (operation === 'Create') {
            return { Path: obj.CreateAPIPath ?? '', Method: obj.CreateMethod ?? 'POST', BodyShape: obj.CreateBodyShape, BodyKey: obj.CreateBodyKey, IDLocation: obj.CreateIDLocation };
        }
        if (operation === 'Update') {
            return { Path: obj.UpdateAPIPath ?? '', Method: obj.UpdateMethod ?? 'PATCH', BodyShape: obj.UpdateBodyShape, BodyKey: obj.UpdateBodyKey, IDLocation: obj.UpdateIDLocation };
        }
        return { Path: obj.DeleteAPIPath ?? '', Method: obj.DeleteMethod ?? 'DELETE', BodyShape: null, BodyKey: null, IDLocation: obj.DeleteIDLocation };
    }

    // ── SOAP envelope construction ───────────────────────────────────────────────────────────────

    /**
     * A partnerAPI `RetrieveRequestMsg`. Element order follows the WSDL's own `RetrieveRequest` sequence
     * (`ObjectType`, `Properties`, `Filter`, …, `ContinueRequest`), and the token rides the `<fueloauth>`
     * SOAP header exactly as the vendor's authentication page shows it.
     *
     * A continuation (`continueRequestID` non-null) still carries `ObjectType` and `Properties` — the
     * vendor's own .NET and Java samples rebuild both on every `ContinueRequest` — and drops the filter,
     * because the server already holds the original query behind the request id.
     */
    public BuildRetrieveEnvelope(
        auth: SFMCAuthContext,
        objectType: string,
        properties: string[],
        filter: { Property: string; Operator: string; Value: string; IsDate?: boolean } | null,
        continueRequestID: string | null,
    ): string {
        const lines: string[] = [];
        lines.push('    <par:RetrieveRequestMsg>');
        lines.push('      <par:RetrieveRequest>');
        lines.push(`        <par:ObjectType>${this.EscapeXml(objectType)}</par:ObjectType>`);
        for (const property of properties) lines.push(`        <par:Properties>${this.EscapeXml(property)}</par:Properties>`);
        if (filter) {
            const valueElement = filter.IsDate ? 'DateValue' : 'Value';
            lines.push('        <par:Filter xsi:type="par:SimpleFilterPart">');
            lines.push(`          <par:Property>${this.EscapeXml(filter.Property)}</par:Property>`);
            lines.push(`          <par:SimpleOperator>${this.EscapeXml(filter.Operator)}</par:SimpleOperator>`);
            lines.push(`          <par:${valueElement}>${this.EscapeXml(filter.Value)}</par:${valueElement}>`);
            lines.push('        </par:Filter>');
        }
        if (continueRequestID) lines.push(`        <par:ContinueRequest>${this.EscapeXml(continueRequestID)}</par:ContinueRequest>`);
        lines.push('      </par:RetrieveRequest>');
        lines.push('    </par:RetrieveRequestMsg>');
        return this.BuildSoapEnvelope(auth, lines.join('\n'));
    }

    /**
     * A partnerAPI `CreateRequest` / `UpdateRequest` / `DeleteRequest`. `<par:Options/>` is emitted
     * because the WSDL declares it `minOccurs="1"`, and `<par:Objects>` carries the `xsi:type` that
     * selects the object — the same ObjectType token the read path uses, taken from metadata.
     */
    public BuildWriteEnvelope(
        auth: SFMCAuthContext,
        operation: Exclude<SFMCSoapOperation, 'Retrieve'>,
        objectType: string,
        attributes: Record<string, unknown>,
    ): string {
        const lines: string[] = [];
        lines.push(`    <par:${operation}Request>`);
        lines.push('      <par:Options/>');
        lines.push(`      <par:Objects xsi:type="par:${this.EscapeXml(objectType)}">`);
        lines.push(this.RenderSoapNodes(attributes, '        '));
        lines.push('      </par:Objects>');
        lines.push(`    </par:${operation}Request>`);
        return this.BuildSoapEnvelope(auth, lines.filter(l => l.length > 0).join('\n'));
    }

    /** The SOAP 1.1 envelope shell: `<fueloauth>` header (literal vendor form) + the supplied body. */
    public BuildSoapEnvelope(auth: SFMCAuthContext, bodyXml: string): string {
        return '<?xml version="1.0" encoding="utf-8"?>\n' +
            `<soapenv:Envelope xmlns:soapenv="${SOAP_ENVELOPE_NS}" xmlns:par="${PARTNER_NS}" xmlns:xsi="${XSI_NS}">\n` +
            '  <soapenv:Header>\n' +
            `    <fueloauth>${this.EscapeXml(auth?.Token ?? '')}</fueloauth>\n` +
            '  </soapenv:Header>\n' +
            '  <soapenv:Body>\n' +
            `${bodyXml}\n` +
            '  </soapenv:Body>\n' +
            '</soapenv:Envelope>';
    }

    /** Renders write attributes as partnerAPI elements (nested objects → nested elements, arrays → repeats). */
    private RenderSoapNodes(attributes: Record<string, unknown>, indent: string): string {
        const parts: string[] = [];
        for (const [key, value] of Object.entries(attributes)) {
            const rendered = this.RenderSoapNode(key, value, indent);
            if (rendered.length > 0) parts.push(rendered);
        }
        return parts.join('\n');
    }

    private RenderSoapNode(key: string, value: unknown, indent: string): string {
        if (value == null) return '';
        const name = this.EscapeXml(key);
        if (Array.isArray(value)) {
            const children = value.map(item => this.RenderSoapNode(key, item, indent)).filter(s => s.length > 0);
            return children.join('\n');
        }
        if (typeof value === 'object' && !(value instanceof Date)) {
            const inner = this.RenderSoapNodes(value as Record<string, unknown>, `${indent}  `);
            return `${indent}<par:${name}>\n${inner}\n${indent}</par:${name}>`;
        }
        return `${indent}<par:${name}>${this.EscapeXml(this.ScalarText(value))}</par:${name}>`;
    }

    /**
     * Issues one SOAP call and returns its parsed body, raising a CLASSIFIED error first when the reply
     * is a fault or a non-2xx. Every partnerAPI reply goes through here precisely because a SOAP service
     * answers application faults — and throttles — with HTTP 500.
     */
    private async SendSoap(
        ci: MJCompanyIntegrationEntity,
        auth: SFMCAuthContext,
        url: string,
        operation: SFMCSoapOperation,
        envelope: string,
        objectType: string,
    ): Promise<SFMCSoapBody> {
        void ci;
        const request: SFMCSoapRequest = { Operation: operation, Envelope: envelope, ObjectType: objectType };
        const response = await this.MakeHTTPRequest(auth, url, 'POST', this.BuildHeaders(auth, operation), request);
        this.ThrowOnSoapError(response, `${operation} ${objectType}`);
        const body = this.AsSoapBody(response.Body);
        if (!body) {
            throw new SFMCRequestError(
                `SFMC ${operation} ${objectType} returned HTTP ${response.Status} with no partnerAPI body.`,
                response.Status, 'soap', null, undefined, 'CONNECTOR_ERROR',
            );
        }
        return body;
    }

    /**
     * SOAP `Retrieve` helper used by the DISCOVERY paths: walks continuations to exhaustion and returns
     * `[]` on ANY failure. Discovery must degrade, never explode — a connection with no credential must
     * still return its full DECLARED catalog.
     */
    private async RetrieveAllSafely(
        ci: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
        objectType: string,
        properties: string[],
        filter: { Property: string; Operator: string; Value: string } | null = null,
    ): Promise<Record<string, unknown>[]> {
        try {
            const auth = await this.Authenticate(ci, contextUser);
            const url = this.GetSoapURL(ci, auth);
            const out: Record<string, unknown>[] = [];
            let continueRequestID: string | null = null;
            let overallStatus = '';
            let batches = 0;
            do {
                const envelope = this.BuildRetrieveEnvelope(auth, objectType, properties, continueRequestID ? null : filter, continueRequestID);
                const body = await this.SendSoap(ci, auth, url, 'Retrieve', envelope, objectType);
                for (const row of body.Records) out.push(row);
                overallStatus = body.OverallStatus;
                continueRequestID = body.RequestID;
                batches++;
            } while (overallStatus === MORE_DATA_AVAILABLE && batches < MAX_SOAP_BATCHES_PER_CALL);
            return out;
        } catch {
            return [];
        }
    }

    // ── SOAP response parsing ────────────────────────────────────────────────────────────────────

    /**
     * Normalizes a raw partnerAPI reply into `{ _soap }`. A `<soap:Fault>` is detected FIRST (it is the
     * shape both application errors and throttles take), then `OverallStatus` / `RequestID` / `Results`.
     * Namespace prefixes are irrelevant — the parser matches LOCAL names.
     */
    public ParseSoapResponse(xml: string, status: number, headers: Record<string, string>): RESTResponse {
        const root = this.ParseXml(xml);
        const body: SFMCSoapBody = { OverallStatus: '', RequestID: null, Records: [], ResultStatuses: [], Fault: null };
        if (!root) {
            return { Status: status, Body: { _soap: body }, Headers: headers };
        }
        const fault = this.FindFirst(root, 'Fault');
        if (fault) {
            const detail = this.FindFirst(fault, 'apifault') ?? fault;
            body.Fault = {
                FaultString: (this.TextOf(this.FindFirst(fault, 'faultstring')) ?? '').trim(),
                Code: (this.TextOf(this.FindFirst(detail, 'Code')) ?? '').trim(),
                Message: (this.TextOf(this.FindFirst(detail, 'Message')) ?? '').trim(),
            };
            return { Status: status >= 400 ? status : 500, Body: { _soap: body }, Headers: headers };
        }
        body.OverallStatus = (this.TextOf(this.FindFirst(root, 'OverallStatus')) ?? '').trim();
        body.RequestID = (this.TextOf(this.FindFirst(root, 'RequestID')) ?? '').trim() || null;
        this.CollectSoapResults(root, body, this.IsRetrieveResponse(root));
        return { Status: status, Body: { _soap: body }, Headers: headers };
    }

    /**
     * True when the envelope is a RETRIEVE reply (`<RetrieveResponseMsg>`), i.e. its `<Results>` are
     * RECORDS rather than per-operation write statuses.
     *
     * This has to be decided from the RESPONSE TYPE, never from the shape of an individual `<Results>`.
     * The obvious heuristic — "a Results carrying <StatusCode> is a write status" — is wrong on this
     * vendor, because `StatusCode`/`StatusMessage` are ORDINARY DATA FIELDS on retrievable objects
     * (`ResultItem` declares both). Under that heuristic every ResultItem row was filed as a write
     * status and the object silently synced ZERO rows — a real 0-row-forever defect that T5 and the
     * hybrid e2e both caught, and that would have hit any retrievable object owning a StatusCode field.
     */
    private IsRetrieveResponse(root: XmlNode): boolean {
        return this.FindFirst(root, 'RetrieveResponseMsg') !== null;
    }

    /** Pulls every `<Results>` element into records + per-result statuses. */
    private CollectSoapResults(root: XmlNode, body: SFMCSoapBody, isRetrieve: boolean): void {
        for (const result of this.FindAll(root, 'Results')) {
            const statusCode = isRetrieve ? null : this.TextOf(this.FindFirst(result, 'StatusCode'));
            if (statusCode !== null) {
                body.ResultStatuses.push({
                    StatusCode: statusCode.trim(),
                    StatusMessage: (this.TextOf(this.FindFirst(result, 'StatusMessage')) ?? '').trim(),
                    NewID: (this.TextOf(this.FindFirst(result, 'NewID')) ?? '').trim() || null,
                    NewObjectID: (this.TextOf(this.FindFirst(result, 'NewObjectID')) ?? '').trim() || null,
                });
                // A write response nests the affected record under <Object>; a read response IS the record.
                const nested = this.FindFirst(result, 'Object');
                if (nested) body.Records.push(this.NodeToRecord(nested));
                continue;
            }
            body.Records.push(this.NodeToRecord(result));
        }
    }

    /**
     * One `<Results>` element → a plain record carrying the COMPLETE source shape.
     *
     * Two vendor-specific hoists happen here, and only here: `Properties/Property{Name,Value}` (how a
     * `DataExtensionObject` row's columns arrive) and `Attributes/Attribute{Name,Value}` (how a
     * Subscriber's tenant-defined profile attributes arrive) are lifted onto the record root under their
     * own names. That is what puts an UNDECLARED tenant column into `ExternalRecord.Fields` where the
     * framework's custom-column capture can see it; the original nested containers are retained too, so
     * nothing from the source is lost. A hoist NEVER overwrites an envelope member of the same name —
     * the declared key (and therefore the record's identity) always wins.
     */
    private NodeToRecord(node: XmlNode): Record<string, unknown> {
        const record = this.NodeToObject(node);
        this.HoistNameValuePairs(record, 'Properties', 'Property');
        this.HoistNameValuePairs(record, 'Attributes', 'Attribute');
        this.HoistNameValuePairs(record, 'Keys', 'Key');
        return record;
    }

    /** Lifts a `{Name,Value}` collection onto the record root without clobbering existing members. */
    private HoistNameValuePairs(record: Record<string, unknown>, container: string, item: string): void {
        const holder = record[container];
        const items = this.NameValueItems(holder, item);
        for (const pair of items) {
            if (pair.Name.length === 0 || pair.Name in record) continue;
            record[pair.Name] = pair.Value;
        }
    }

    /**
     * Extracts `{Name,Value}` pairs from a hoist container, returning `[]` unless EVERY item matches.
     *
     * The partnerAPI uses BOTH shapes and the parser must accept both: a WRAPPER element whose children
     * are the pairs (`<Properties><Property><Name/><Value/></Property>…</Properties>` on
     * DataExtensionObject) and a REPEATED element that IS the pair
     * (`<Attributes><Name/><Value/></Attributes><Attributes>…` on Subscriber, whose WSDL member is
     * `maxOccurs="unbounded"`). A repeated element parses to an array, a single occurrence to one object.
     */
    private NameValueItems(holder: unknown, item: string): Array<{ Name: string; Value: unknown }> {
        const list = this.NameValueCandidates(holder, item);
        const out: Array<{ Name: string; Value: unknown }> = [];
        for (const entry of list) {
            if (!this.IsRecord(entry)) return [];
            const name = this.ScalarString(entry.Name);
            if (name === null || !('Value' in entry)) return [];
            out.push({ Name: name, Value: entry.Value });
        }
        return out;
    }

    /** The candidate pair nodes inside a hoist container, across the wrapper and repeated-element shapes. */
    private NameValueCandidates(holder: unknown, item: string): unknown[] {
        if (Array.isArray(holder)) return holder;
        if (!this.IsRecord(holder)) return [];
        const wrapped = holder[item];
        if (wrapped !== undefined) return Array.isArray(wrapped) ? wrapped : [wrapped];
        return 'Name' in holder ? [holder] : [];
    }

    /** An element → a plain object. Leaf → text (or null for `xsi:nil`/empty); repeats → arrays. */
    private NodeToObject(node: XmlNode): Record<string, unknown> {
        const out: Record<string, unknown> = {};
        for (const child of node.Children) {
            const value = this.NodeValue(child);
            if (child.Name in out) {
                const existing = out[child.Name];
                if (Array.isArray(existing)) existing.push(value);
                else out[child.Name] = [existing, value];
            } else {
                out[child.Name] = value;
            }
        }
        return out;
    }

    private NodeValue(node: XmlNode): unknown {
        if ((node.Attributes['xsi:nil'] ?? node.Attributes['nil']) === 'true') return null;
        if (node.Children.length === 0) {
            const text = node.Text.trim();
            return text.length === 0 ? null : text;
        }
        return this.NodeToObject(node);
    }

    // ── Error classification (transport-specific: SOAP throttles are 500, REST throttles are 429) ──

    /**
     * Raises a classified error for a faulted or non-2xx SOAP reply.
     *
     * THE THROTTLE-SHAPED 500 IS THE CASE THIS EXISTS FOR. The vendor's own Rate Limiting page documents
     * SOAP throttling as `HTTP 500` carrying `faultstring=Rate Limited` and `apifault/Code=17`. Treating
     * every 500 as fatal would abort a sync on a condition the vendor expects the caller to BACK OFF from,
     * so a throttle-shaped fault classifies as `RATE_LIMIT_EXCEEDED` (retryable) while every other fault
     * is classified on its own code/message. A 429 with `Retry-After`, if this transport ever emits one,
     * is still honoured.
     */
    protected ThrowOnSoapError(response: RESTResponse, operation: string): void {
        const body = this.AsSoapBody(response.Body);
        const fault = body?.Fault ?? null;
        const retryAfterMs = this.RetryAfterFromHeaders(response.Headers);
        if (fault) {
            const throttled = this.IsSoapThrottle(fault);
            throw new SFMCRequestError(
                `SFMC SOAP Fault on ${operation} [${fault.Code || 'n/a'}]: ${fault.Message || fault.FaultString || 'unknown fault'}`,
                response.Status, 'soap', fault.Code || null, retryAfterMs,
                throttled ? 'RATE_LIMIT_EXCEEDED' : this.ClassifySoapFault(fault),
            );
        }
        if (response.Status === 429 || response.Status === 503) {
            throw new SFMCRequestError(
                `SFMC ${operation} rate limited: HTTP ${response.Status}`,
                response.Status, 'soap', null, retryAfterMs, 'RATE_LIMIT_EXCEEDED',
            );
        }
        if (response.Status < 200 || response.Status >= 300) {
            throw new SFMCRequestError(
                `SFMC ${operation} failed: HTTP ${response.Status}`,
                response.Status, 'soap', null, retryAfterMs, ClassifyError(new Error(`HTTP ${response.Status}`)).Code,
            );
        }
    }

    /**
     * Is this SOAP fault the vendor's documented throttle? `apifault/Code=17` is the literal value on the
     * vendor's sample payload; the `faultstring`/`Message` text is matched too because the vendor's code
     * table is explicitly non-exhaustive and a rate-limit fault must never be mistaken for a hard error.
     */
    public IsSoapThrottle(fault: SFMCSoapFault): boolean {
        if (fault.Code.trim() === SOAP_THROTTLE_FAULT_CODE) return true;
        const text = `${fault.FaultString} ${fault.Message}`.toLowerCase();
        return /rate\s*limit|throttl|too many requests/.test(text);
    }

    /** Maps a non-throttle SOAP fault onto the engine's `SyncErrorCode` space by PATTERN, never a frozen list. */
    public ClassifySoapFault(fault: SFMCSoapFault): SyncErrorCode {
        const text = `${fault.Code} ${fault.FaultString} ${fault.Message}`.toLowerCase();
        if (/unauthor|not authenticated|invalid token|expired|forbidden|permission|privilege/.test(text)) return 'CONFIGURATION_ERROR';
        if (/not found|does not exist|unknown object|invalid objecttype/.test(text)) return 'MATCH_RESOLUTION_ERROR';
        if (/invalid|required|malformed|unable to parse|bad request|property .* not retriev/.test(text)) return 'VALIDATION_ERROR';
        if (/timeout|timed out/.test(text)) return 'NETWORK_TIMEOUT';
        return ClassifyError(new Error(`${fault.Code} ${fault.Message || fault.FaultString}`)).Code;
    }

    /**
     * Raises a classified error for a non-2xx REST reply. REST throttling is `HTTP 429` with a JSON body
     * (`errorcode` 50100 carrying `Retry-After`, or 50200 with none — then exponential backoff per the
     * vendor's own best-practices page). A generic REST 500 is NOT this vendor's REST throttle signal and
     * is deliberately NOT conflated with the SOAP 500 rule.
     */
    protected ThrowOnRestError(response: RESTResponse, operation: string): void {
        if (response.Status >= 200 && response.Status < 300) return;
        const parsed = this.ParseRestError(response);
        const headerRetry = this.RetryAfterFromHeaders(response.Headers);
        const retryAfterMs = headerRetry ?? (parsed.RetryAfterSeconds !== null ? parsed.RetryAfterSeconds * 1000 : undefined);
        const throttled = response.Status === 429 || (parsed.ErrorCode !== null && REST_THROTTLE_ERROR_CODES.has(parsed.ErrorCode));
        throw new SFMCRequestError(
            `SFMC ${operation} failed: HTTP ${response.Status}${parsed.ErrorCode !== null ? ` (errorcode ${parsed.ErrorCode})` : ''} — ${parsed.Message}`,
            response.Status, 'rest', parsed.ErrorCode !== null ? String(parsed.ErrorCode) : null, retryAfterMs,
            throttled ? 'RATE_LIMIT_EXCEEDED' : this.ClassifyRestStatus(response.Status),
        );
    }

    /** Maps a REST HTTP status onto the engine's `SyncErrorCode` space (the vendor's documented table). */
    public ClassifyRestStatus(status: number): SyncErrorCode {
        if (status === 401 || status === 403) return 'CONFIGURATION_ERROR';
        if (status === 404 || status === 596) return 'MATCH_RESOLUTION_ERROR';
        if (status === 409) return 'DUPLICATE_KEY';
        if (status === 408 || status === 504) return 'NETWORK_TIMEOUT';
        if (status >= 400 && status < 500) return 'VALIDATION_ERROR';
        return ClassifyError(new Error(`HTTP ${status}`)).Code;
    }

    /** Parses the vendor's REST error body `{ message, errorcode, documentation, retryAfter }`. */
    public ParseRestError(response: RESTResponse): SFMCRestError {
        const body = response.Body;
        if (!this.IsRecord(body)) {
            return { Message: typeof body === 'string' && body.length > 0 ? body.slice(0, 300) : `HTTP ${response.Status}`, ErrorCode: null, RetryAfterSeconds: null };
        }
        const message = this.ScalarString(body.message) ?? this.ScalarString(body.errorMessage) ?? this.ScalarString(body.error) ?? `HTTP ${response.Status}`;
        return {
            Message: message,
            ErrorCode: this.ScalarNumber(body.errorcode),
            RetryAfterSeconds: this.ScalarNumber(body.retryAfter),
        };
    }

    /** `Retry-After` (delta-seconds or HTTP-date) → milliseconds. */
    private RetryAfterFromHeaders(headers: Record<string, string> | undefined): number | undefined {
        const value = headers?.['retry-after'] ?? headers?.['Retry-After'];
        if (!value) return undefined;
        const seconds = Number(value);
        if (Number.isFinite(seconds) && seconds >= 0) return Math.round(seconds * 1000);
        const when = Date.parse(value);
        return Number.isNaN(when) ? undefined : Math.max(0, when - Date.now());
    }

    private BuildCRUDError(err: unknown, operation: string, objectName: string): CRUDResult {
        const status = err instanceof SFMCRequestError ? err.Status : 500;
        return { Success: false, StatusCode: status, ErrorMessage: `${operation} failed for ${objectName}: ${this.SafeMessage(err)}` };
    }

    // ── REST URL / pagination / filter helpers ───────────────────────────────────────────────────

    /**
     * The `$`-prefixed page parameters for one REST object, taken from ITS OWN declared
     * `Configuration.pagination.params`. This matters because the vendor's parameter TABLES document
     * unprefixed `page`/`pageSize`/`orderBy` while its own EXAMPLE REQUESTS send `$page`/`$pageSize`/
     * `$orderBy` — a confirmed table-vs-example disagreement resolved in favour of the examples. The
     * `$pageSize` / `$pagesize` casing likewise varies per endpoint and is read, not assumed.
     */
    public RestPageParamsFor(obj: MJIntegrationObjectEntity): RestPageParams {
        const pagination = this.ReadIOConfigRecord(obj, 'pagination');
        const declared = Array.isArray(pagination?.params)
            ? pagination.params.filter((p): p is string => typeof p === 'string')
            : [];
        const pick = (...candidates: string[]): string | null => {
            for (const candidate of candidates) {
                const hit = declared.find(p => p === candidate);
                if (hit) return hit;
            }
            for (const candidate of candidates) {
                const hit = declared.find(p => p.toLowerCase() === candidate.toLowerCase());
                if (hit) return hit;
            }
            return null;
        };
        return {
            PageParam: pick('$page') ?? '$page',
            SizeParam: pick('$pageSize', '$pagesize') ?? '$pageSize',
            OrderParam: pick('$orderBy', '$orderby'),
            MaxPageSize: this.ScalarNumber(pagination?.pageSizeMax),
        };
    }

    /** Page size = the IO's declared default, capped by the ENDPOINT's own maximum and the batch capacity. */
    public EffectivePageSize(obj: MJIntegrationObjectEntity, params: RestPageParams, remainingCapacity: number): number {
        const declared = obj.DefaultPageSize && obj.DefaultPageSize > 0 ? obj.DefaultPageSize : 50;
        const capped = params.MaxPageSize && params.MaxPageSize > 0 ? Math.min(declared, params.MaxPageSize) : declared;
        const bounded = Number.isFinite(remainingCapacity) && remainingCapacity > 0 ? Math.min(capped, remainingCapacity) : capped;
        return Math.max(1, bounded);
    }

    /** Appends the resolved `$`-prefixed page params (and `$orderBy` when the IO declares an ordering key). */
    public BuildRestPaginatedURL(basePath: string, params: RestPageParams, page: number, pageSize: number, orderBy?: string | null): string {
        const separator = basePath.includes('?') ? '&' : '?';
        let url = `${basePath}${separator}${params.PageParam}=${page}&${params.SizeParam}=${pageSize}`;
        if (params.OrderParam && orderBy) url += `&${params.OrderParam}=${encodeURIComponent(`${orderBy} ASC`)}`;
        return url;
    }

    /** Does the vendor's envelope itself declare paging state (`links.next`, or a count/page/pageSize triple)? */
    public EnvelopeDeclaresPagination(rawBody: unknown): boolean {
        if (!this.IsRecord(rawBody)) return false;
        if (this.NextLinkHref(rawBody) !== null) return true;
        return this.ScalarNumber(rawBody.count) !== null && this.ScalarNumber(rawBody.page) !== null && this.ScalarNumber(rawBody.pageSize) !== null;
    }

    /** The REST half of {@link ExtractPaginationInfo}. */
    private ExtractRestPaginationInfo(rawBody: unknown, currentPage: number, pageSize: number): PaginationState {
        if (!this.IsRecord(rawBody)) return { HasMore: false };
        const state: PaginationState = { HasMore: false, NextPage: currentPage + 1 };
        const total = this.ScalarNumber(rawBody.count);
        if (total !== null) state.TotalRecords = total;
        if (this.NextLinkHref(rawBody) !== null) { state.HasMore = true; return state; }
        const page = this.ScalarNumber(rawBody.page);
        const size = this.ScalarNumber(rawBody.pageSize) ?? pageSize;
        if (total !== null && page !== null && size > 0) { state.HasMore = page * size < total; return state; }
        return state;
    }

    /** `links.next.href` when the envelope publishes one (the campaigns collection does). */
    private NextLinkHref(body: Record<string, unknown>): string | null {
        const links = body.links;
        if (!this.IsRecord(links)) return null;
        const next = links.next;
        if (typeof next === 'string') return next.length > 0 ? next : null;
        if (this.IsRecord(next)) {
            const href = this.ScalarString(next.href);
            return href && href.length > 0 ? href : null;
        }
        return null;
    }

    /**
     * Resolves an IO's `APIPath` for a READ: substitutes every Express-style `:param` from the operator's
     * declared `pathParams` map, and reports any that remain. The connector NEVER fires a URL with an
     * unsubstituted parameter — that would be a guaranteed 404/400 dressed up as a sync attempt.
     */
    public ResolveRestPath(ci: MJCompanyIntegrationEntity, obj: MJIntegrationObjectEntity): { Path: string; Unresolved: string[] } {
        const path = this.SubstituteRestParams(obj.APIPath, null, this.PathParamValues(ci, obj));
        return { Path: path, Unresolved: this.UnresolvedParams(path) };
    }

    /** The non-fatal diagnostic the engine surfaces when a `:param` path could not be resolved. */
    private UnresolvedPathWarning(obj: MJIntegrationObjectEntity, unresolved: string[]): FetchWarning {
        return {
            Code: 'PATH_PARAMS_UNRESOLVED',
            Message:
                `"${obj.Name}": APIPath "${obj.APIPath}" needs value(s) for ${unresolved.join(', ')} that no parent record or ` +
                `connection configuration supplies — declare them under Configuration.pathParams to enable this object. ` +
                `Skipping rather than issuing an invalid request.`,
            Data: { object: obj.Name, apiPath: obj.APIPath, unresolved },
        };
    }

    /** Substitutes `:param` segments (and a bare `{id}`) from the external id and the supplied value map. */
    public SubstituteRestParams(path: string, externalID: string | null, values: Record<string, string>): string {
        const names = this.ParamNames(path);
        let out = path;
        for (const name of names) {
            const value = values[name] ?? values[name.toLowerCase()];
            if (value === undefined) continue;
            out = out.replace(new RegExp(`:${name}\\b`, 'g'), encodeURIComponent(value));
        }
        // An EMPTY-valued query parameter (`…/status?operationID=`) is a declared slot, not a literal —
        // fill it from the same value map before falling back to the external id.
        out = out.replace(/([?&])([A-Za-z0-9_]+)=(?=$|&)/g, (match, sep: string, name: string) => {
            const value = values[name] ?? values[name.toLowerCase()];
            return value === undefined ? match : `${sep}${name}=${encodeURIComponent(value)}`;
        });
        const remaining = this.ParamNames(out);
        if (externalID !== null && remaining.length === 1) {
            out = out.replace(new RegExp(`:${remaining[0]}\\b`, 'g'), encodeURIComponent(externalID));
        }
        if (externalID !== null) {
            out = out.replace(/\{ID\}|\{id\}|\{ExternalID\}/g, encodeURIComponent(externalID));
            out = out.replace(/([?&][A-Za-z0-9_]+=)(?=$|&)/g, (_m, prefix: string) => `${prefix}${encodeURIComponent(externalID)}`);
        }
        return out;
    }

    /** Parameter names still unresolved in a path: `:name` segments plus empty-valued query params. */
    public UnresolvedParams(path: string): string[] {
        const out = this.ParamNames(path);
        for (const match of path.matchAll(/[?&]([A-Za-z0-9_]+)=(?=$|&)/g)) out.push(match[1]);
        return out;
    }

    /** The `:name` parameter names in a path, in order, de-duplicated. */
    private ParamNames(path: string): string[] {
        const names: string[] = [];
        for (const match of path.matchAll(/:([A-Za-z_][A-Za-z0-9_]*)/g)) {
            if (!names.includes(match[1])) names.push(match[1]);
        }
        return names;
    }

    /**
     * Appends the IO's DECLARED REST incremental filter (`Configuration.incrementalFilterFormat`, e.g.
     * `$filter=<watermark> gt '<value>'`) once a watermark exists. An IO that declares a watermark FIELD
     * but no filter FORMAT does a full scan — the vendor publishes no `$filter` for those endpoints and
     * inventing one would silently drop rows.
     */
    public AppendRestWatermarkFilter(path: string, obj: MJIntegrationObjectEntity, watermarkValue: string | null): string {
        if (!obj.SupportsIncrementalSync || !watermarkValue) return path;
        const field = (obj.IncrementalWatermarkField ?? '').trim();
        const template = this.ReadIOConfigString(obj, 'incrementalFilterFormat');
        if (!field || !template) return path;
        const equals = template.indexOf('=');
        if (equals <= 0) return path;
        const paramName = template.slice(0, equals).trim();
        const expression = template.slice(equals + 1)
            .replace(/<watermark>/g, field)
            .replace(/<value>/g, this.FormatWatermark(watermarkValue));
        const separator = path.includes('?') ? '&' : '?';
        return `${path}${separator}${encodeURIComponent(paramName)}=${encodeURIComponent(expression)}`;
    }

    /**
     * The declared SOAP incremental filter: a `SimpleFilterPart` `greaterThan` on the IO's own
     * `IncrementalWatermarkField`, carried in `DateValue` (the WSDL's `xsd:dateTime` slot) because every
     * SOAP watermark this vendor exposes is a date. No declared watermark, or no watermark value yet ⇒
     * NO filter (a full scan); the connector never synthesizes one.
     */
    public SoapWatermarkFilter(
        obj: MJIntegrationObjectEntity,
        watermarkValue: string | null,
    ): { Property: string; Operator: string; Value: string; IsDate: boolean } | null {
        if (!obj.SupportsIncrementalSync || !watermarkValue) return null;
        const field = (obj.IncrementalWatermarkField ?? '').trim();
        if (!field) return null;
        return { Property: field, Operator: 'greaterThan', Value: this.FormatWatermark(watermarkValue), IsDate: true };
    }

    /**
     * Wire timestamp form. A value that already looks like an ISO 8601 timestamp is passed back VERBATIM —
     * it is the same representation the API itself returned, and re-applying an offset is precisely the
     * mis-implementation that silently skips or re-reads rows at a watermark boundary. The vendor
     * publishes no canonical account timezone credential-free (it lives on `v2/userinfo`'s `zoneinfo`),
     * so no offset is ever assumed here; only a non-ISO value (epoch millis) is normalized.
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

    /** Max watermark value seen in a fully-parsed batch, or undefined when the object is not incremental. */
    public ComputeWatermark(obj: MJIntegrationObjectEntity, records: Record<string, unknown>[]): string | undefined {
        if (!obj.SupportsIncrementalSync) return undefined;
        const field = (obj.IncrementalWatermarkField ?? '').trim();
        if (!field) return undefined;
        const lower = field.toLowerCase();
        let max: string | undefined;
        for (const record of records) {
            for (const [key, value] of Object.entries(record)) {
                if (key.toLowerCase() !== lower || value == null) continue;
                const text = this.ScalarText(value);
                if (!max || text > max) max = text;
            }
        }
        return max;
    }

    // ── Metadata readers (every vendor specific comes from metadata, never from code) ────────────

    /**
     * The transport for an object. `Configuration.transport` is authoritative; a DISCOVERED Data
     * Extension (persisted without a marker) is recognised by its `ObjectType[key]`-shaped name, and an
     * object whose APIPath is the SOAP door falls back to SOAP. REST is the residual default — which is
     * correct, because this base class's native protocol is REST.
     */
    public ResolveTransport(obj: MJIntegrationObjectEntity): SFMCTransport {
        const declared = this.ReadIOConfigString(obj, 'transport');
        if (declared === 'soap' || declared === 'rest') return declared;
        if (this.ReadIOConfigString(obj, 'soapObjectType')) return 'soap';
        if (/^[A-Za-z0-9_]+\[.+\]$/.test(obj.Name)) return 'soap';
        if (/\/Service\.asmx$/i.test(obj.APIPath ?? '')) return 'soap';
        return 'rest';
    }

    /** The `RetrieveRequest.ObjectType` token: declared `Configuration.soapObjectType`, else the IO name. */
    public SoapObjectTypeFor(obj: MJIntegrationObjectEntity): string {
        return this.ReadIOConfigString(obj, 'soapObjectType') ?? obj.Name;
    }

    /**
     * The `<Properties>` list a SOAP `Retrieve` must carry (the API rejects a Retrieve without one).
     *
     * Built from the object's DECLARED fields, minus the complex (`json`-typed) members — the partnerAPI
     * rejects a Retrieve that asks for a non-scalar property, so requesting them would fail the whole
     * batch rather than return a little more data. An explicit `Configuration.retrieveProperties` on the
     * IO overrides the derivation entirely, which is the metadata escape hatch for an object whose
     * retrievable set diverges from its declared set.
     */
    public RetrievePropertiesFor(
        obj: MJIntegrationObjectEntity,
        fields: MJIntegrationObjectFieldEntity[],
        requested?: string[],
    ): string[] {
        const override = this.ReadIOConfigRecord(obj, 'retrieveProperties');
        const declaredOverride = Array.isArray(override?.properties)
            ? override.properties.filter((p): p is string => typeof p === 'string')
            : null;
        const base = declaredOverride ?? fields.filter(f => (f.Type ?? '').toLowerCase() !== 'json').map(f => f.Name);
        if (!requested || requested.length === 0) return base;
        const wanted = new Set(requested.map(r => r.toLowerCase()));
        const narrowed = base.filter(n => wanted.has(n.toLowerCase()));
        return narrowed.length > 0 ? narrowed : base;
    }

    /** Declared PK components in Sequence order (empty when the object declares none). */
    public PrimaryKeyFieldNames(fields: MJIntegrationObjectFieldEntity[]): string[] {
        return fields.filter(f => f.IsPrimaryKey).sort((a, b) => a.Sequence - b.Sequence).map(f => f.Name);
    }

    /** An IO by name, or null — the non-throwing sibling of the base's `GetCachedObject`. */
    private TryGetCachedObject(integrationID: string, objectName: string): MJIntegrationObjectEntity | null {
        return IntegrationEngineBase.Instance.GetIntegrationObject(integrationID, objectName) ?? null;
    }

    /** The `Integration.Configuration.DynamicObjectModel.declaredMechanism[index]` ObjectType, or a fallback. */
    private DeclaredMechanismType(ci: MJCompanyIntegrationEntity, index: number, fallback: string): string {
        const model = this.ReadIntegrationConfigRecord(ci, 'DynamicObjectModel');
        const declared = Array.isArray(model?.declaredMechanism) ? model.declaredMechanism : [];
        const value = declared[index];
        return typeof value === 'string' && value.trim().length > 0 ? value.trim() : fallback;
    }

    /** The `ObjectType[key]` name this connector mints for a discovered Data Extension. */
    public DataExtensionObjectName(ci: MJCompanyIntegrationEntity, dataExtensionKey: string): string {
        const model = this.ReadIntegrationConfigRecord(ci, 'DynamicObjectModel');
        const declared = Array.isArray(model?.declaredMechanism) ? model.declaredMechanism : [];
        const template = declared.find((d): d is string => typeof d === 'string' && d.includes('['));
        const prefix = template ? template.slice(0, template.indexOf('[')) : DEFAULT_DE_ROW_OBJECT_TYPE;
        return `${prefix}[${dataExtensionKey}]`;
    }

    /** The Data Extension CustomerKey inside an `ObjectType[key]` object name, or null when it isn't one. */
    public DataExtensionKeyFromObjectName(ci: MJCompanyIntegrationEntity, objectName: string): string | null {
        const match = /^([A-Za-z0-9_]+)\[(.+)\]$/.exec(objectName.trim());
        if (!match) return null;
        const expected = this.DataExtensionObjectName(ci, 'x').replace(/\[x\]$/, '');
        return match[1] === expected ? match[2] : null;
    }

    /** Operator-declared values for an object's `:params` (per-object map wins over the flat map). */
    private PathParamValues(ci: MJCompanyIntegrationEntity, obj: MJIntegrationObjectEntity): Record<string, string> {
        const declared = this.ReadIOConfigRecord(obj, 'pathParams');
        const fromMetadata = declared ? this.StringValued(declared) : {};
        const settings = this.ReadConnectionSettings(ci);
        const raw = settings.pathParams ?? settings.PathParams;
        if (!this.IsRecord(raw)) return fromMetadata;
        const flat = this.StringValued(raw);
        const scoped = this.IsRecord(raw[obj.Name]) ? this.StringValued(raw[obj.Name] as Record<string, unknown>) : {};
        return { ...fromMetadata, ...flat, ...scoped };
    }

    // ── Record shaping ───────────────────────────────────────────────────────────────────────────

    /**
     * FULL-RECORD PASS-THROUGH plus STABLE identity.
     *
     * `Fields` carries the COMPLETE parsed source record — every partnerAPI element and every hoisted
     * Data-Extension / Subscriber-attribute column, declared or not — so the framework's custom-column
     * capture sees everything the source returned.
     *
     * Identity is the DECLARED primary key when every component is present (`ObjectID`, `CustomerKey`,
     * `SubscriberKey` or `id`, whichever the metadata names), joined with `|` for a composite. When the
     * source leaves a component empty — which is the documented state of the tracking-event objects,
     * whose rows are system-generated log records — identity falls back to a deterministic CONTENT HASH
     * of the record. That hash is stable across passes for unchanged content and is NEVER derived from a
     * volatile field, so a re-sync matches rather than duplicating. A single empty PK column is stamped
     * with the same value so the row remains storable.
     */
    public BuildRecord(raw: Record<string, unknown>, objectType: string, pkFieldNames: string[]): ExternalRecord {
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

    /** Injects the write target's identity under the declared PK when the caller did not supply it. */
    private WithInjectedKey(attributes: Record<string, unknown>, externalID: string, pkNames: string[]): Record<string, unknown> {
        if (pkNames.length === 0) return { ...attributes };
        const parts = String(externalID).split('|');
        const out = { ...attributes };
        pkNames.forEach((name, index) => {
            if (out[name] === undefined && parts[index] !== undefined) out[name] = parts[index];
        });
        return out;
    }

    /** The identity a caller SUBMITTED, used when a create response carries no id of its own. */
    private IdentityFromAttributes(attributes: Record<string, unknown>, pkNames: string[]): string | undefined {
        for (const name of pkNames) {
            const value = attributes[name];
            if (value != null && String(value).trim().length > 0) return String(value).trim();
        }
        return undefined;
    }

    // ── Config resolution ────────────────────────────────────────────────────────────────────────

    /** Resolves the connection config from the credential store (secrets) ∪ Configuration JSON (overrides). */
    protected async ParseConfig(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<SFMCConfig> {
        const raw: Record<string, unknown> = {};
        if (companyIntegration.CredentialID) {
            Object.assign(raw, await this.LoadCredentialValues(companyIntegration.CredentialID, contextUser));
        }
        Object.assign(raw, this.ReadConnectionSettings(companyIntegration));

        const candidate: SFMCConfig = {
            ClientID: this.PickSetting(raw, 'ClientID', 'ClientId', 'client_id') ?? '',
            ClientSecret: this.PickSetting(raw, 'ClientSecret', 'client_secret') ?? '',
            Subdomain: this.PickSetting(raw, 'Subdomain', 'subdomain', 'tenantSubdomain') ?? '',
            AccountID: this.PickSetting(raw, 'AccountID', 'AccountId', 'account_id', 'MID') ?? null,
            Scope: this.PickSetting(raw, 'Scope', 'scope', 'scopes') ?? null,
            AuthBaseURL: this.PickSetting(raw, 'AuthBaseURL', 'authInstanceUrl', 'auth_instance_url', 'BaseURL') ?? null,
            RestBaseURL: this.PickSetting(raw, 'RestBaseURL', 'restInstanceUrl', 'rest_instance_url') ?? null,
            SoapBaseURL: this.PickSetting(raw, 'SoapBaseURL', 'soapInstanceUrl', 'soap_instance_url') ?? null,
            PathParams: {},
        };
        const parsed = ConfigSchema.safeParse(candidate);
        if (!parsed.success) {
            throw new Error(`SFMC configuration invalid: ${parsed.error.issues.map(i => i.message).join('; ')}`);
        }
        if (candidate.Subdomain.length === 0 && !candidate.AuthBaseURL) {
            throw new Error('SFMC configuration invalid: Subdomain is required unless an explicit AuthBaseURL override is supplied.');
        }
        return candidate;
    }

    /** The AUTH host: an explicit operator override, else the documented subdomain template. */
    private AuthBaseFor(config: SFMCConfig): string {
        if (config.AuthBaseURL) return config.AuthBaseURL;
        return this.SubstituteSubdomain(AUTH_HOST_TEMPLATE, config.Subdomain);
    }

    /**
     * Turns a minted token into the connector's auth context — and this is where the tenant's base URIs
     * are DECIDED: `rest_instance_url` / `soap_instance_url` off the token response first, then an
     * operator override, then the documented subdomain template. `BaseURLsFromToken` records which.
     */
    private BuildAuthContext(token: OAuth2Token, config: SFMCConfig): SFMCAuthContext {
        const extra = token.Extra ?? {};
        const restFromToken = this.ScalarString(extra.rest_instance_url);
        const soapFromToken = this.ScalarString(extra.soap_instance_url);
        return {
            Token: token.AccessToken,
            ExpiresAt: new Date(token.ExpiresAt),
            RestBaseURL: restFromToken ?? config.RestBaseURL ?? this.SubstituteSubdomain(REST_HOST_TEMPLATE, config.Subdomain),
            SoapBaseURL: this.NormalizeSoapURL(soapFromToken ?? config.SoapBaseURL ?? this.SubstituteSubdomain(SOAP_HOST_TEMPLATE, config.Subdomain)),
            BaseURLsFromToken: restFromToken !== null || soapFromToken !== null,
        };
    }

    /** One token manager per connection, with the refresh margin widened for SFMC's ~20-minute token. */
    private TokenManagerFor(companyIntegration: MJCompanyIntegrationEntity): OAuth2TokenManager {
        const key = companyIntegration.ID ?? companyIntegration.IntegrationID ?? 'default';
        let manager = this.tokenManagers.get(key);
        if (!manager) {
            manager = new OAuth2TokenManager();
            manager.RefreshBufferMs = TOKEN_REFRESH_MARGIN_MS;
            this.tokenManagers.set(key, manager);
        }
        return manager;
    }

    private async LoadCredentialValues(credentialID: string, contextUser: UserInfo): Promise<Record<string, unknown>> {
        const md = new Metadata();
        const credential = await md.GetEntityObject<MJCredentialEntity>('MJ: Credentials', contextUser);
        const loaded = await credential.Load(credentialID);
        if (!loaded || !credential.Values) return {};
        try {
            const parsed: unknown = JSON.parse(credential.Values);
            return this.IsRecord(parsed) ? parsed : {};
        } catch {
            return {};
        }
    }

    /** `CompanyIntegration.Configuration` as a flat settings map (never throws on malformed JSON). */
    private ReadConnectionSettings(companyIntegration: MJCompanyIntegrationEntity): Record<string, unknown> {
        return this.ParseJsonRecord(companyIntegration?.Configuration ?? null);
    }

    /** A named member of the Integration-level `Configuration` (the vendor-wide evidenced facts block). */
    private ReadIntegrationConfigRecord(ci: MJCompanyIntegrationEntity, key: string): Record<string, unknown> | null {
        const integration = IntegrationEngineBase.Instance.GetIntegrationByID(ci.IntegrationID);
        const config = this.ParseJsonRecord(integration?.Configuration ?? null);
        const value = config[key];
        return this.IsRecord(value) ? value : null;
    }

    /** A string member of an IO's `Configuration`. */
    private ReadIOConfigString(obj: MJIntegrationObjectEntity, key: string): string | null {
        const value = this.ParseJsonRecord(obj?.Configuration ?? null)[key];
        return typeof value === 'string' && value.trim().length > 0 ? value.trim() : null;
    }

    /** An object member of an IO's `Configuration`. */
    private ReadIOConfigRecord(obj: MJIntegrationObjectEntity, key: string): Record<string, unknown> | null {
        const value = this.ParseJsonRecord(obj?.Configuration ?? null)[key];
        return this.IsRecord(value) ? value : null;
    }

    // ── XML parsing (prefix-agnostic, single pass) ───────────────────────────────────────────────

    /**
     * A minimal, single-pass XML reader sufficient for the partnerAPI's document shape: elements,
     * attributes, text, CDATA, self-closing tags, comments and the XML declaration. Element names are
     * reduced to their LOCAL name so `par:Results`, `Results` and `ns2:Results` all match, which is what
     * makes the parser robust against whichever prefix a stack happens to emit. Returns a synthetic root
     * whose children are the document's top-level elements.
     */
    public ParseXml(xml: string): XmlNode | null {
        if (!xml || xml.trim().length === 0) return null;
        const root: XmlNode = { Name: '#document', Attributes: {}, Children: [], Text: '' };
        const stack: XmlNode[] = [root];
        const tagRe = /<(\/)?([A-Za-z_][\w.\-]*(?::[A-Za-z_][\w.\-]*)?)((?:"[^"]*"|'[^']*'|[^>"'])*?)(\/)?>/g;
        let cursor = 0;
        let match: RegExpExecArray | null;
        const source = this.StripXmlNoise(xml);
        while ((match = tagRe.exec(source)) !== null) {
            const parent = stack[stack.length - 1];
            parent.Text += source.slice(cursor, match.index);
            cursor = tagRe.lastIndex;
            const [, closing, qualified, attrText, selfClosing] = match;
            const name = qualified.includes(':') ? qualified.slice(qualified.indexOf(':') + 1) : qualified;
            if (closing) {
                if (stack.length > 1) stack.pop();
                continue;
            }
            const node: XmlNode = { Name: name, Attributes: this.ParseAttributes(attrText ?? ''), Children: [], Text: '' };
            parent.Children.push(node);
            if (!selfClosing) stack.push(node);
        }
        stack[stack.length - 1].Text += source.slice(cursor);
        this.DecodeNodeText(root);
        return root;
    }

    /** Removes comments, the XML declaration and DOCTYPE, and unwraps CDATA into escaped text. */
    private StripXmlNoise(xml: string): string {
        return xml
            .replace(/<!--[\s\S]*?-->/g, '')
            .replace(/<\?[\s\S]*?\?>/g, '')
            .replace(/<!DOCTYPE[^>]*>/gi, '')
            .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, (_m, inner: string) => this.EscapeXml(inner));
    }

    private ParseAttributes(attrText: string): Record<string, string> {
        const out: Record<string, string> = {};
        for (const match of attrText.matchAll(/([A-Za-z_][\w.\-]*(?::[A-Za-z_][\w.\-]*)?)\s*=\s*("([^"]*)"|'([^']*)')/g)) {
            out[match[1]] = this.DecodeXml(match[3] ?? match[4] ?? '');
        }
        return out;
    }

    /** Decodes entity references in every node's text, depth-first. */
    private DecodeNodeText(node: XmlNode): void {
        node.Text = this.DecodeXml(node.Text);
        for (const child of node.Children) this.DecodeNodeText(child);
    }

    /** First descendant with the given local name (breadth-first), or null. */
    private FindFirst(node: XmlNode, localName: string): XmlNode | null {
        const queue: XmlNode[] = [...node.Children];
        while (queue.length > 0) {
            const current = queue.shift() as XmlNode;
            if (current.Name === localName) return current;
            for (const child of current.Children) queue.push(child);
        }
        return null;
    }

    /** Every descendant with the given local name (does not descend INTO a match). */
    private FindAll(node: XmlNode, localName: string): XmlNode[] {
        const out: XmlNode[] = [];
        const queue: XmlNode[] = [...node.Children];
        while (queue.length > 0) {
            const current = queue.shift() as XmlNode;
            if (current.Name === localName) { out.push(current); continue; }
            for (const child of current.Children) queue.push(child);
        }
        return out;
    }

    private TextOf(node: XmlNode | null): string | null {
        return node ? node.Text : null;
    }

    // ── Small utilities ──────────────────────────────────────────────────────────────────────────

    /** Narrows an unknown body to the structured SOAP request this connector's SOAP path posts. */
    private AsSoapRequest(body: unknown): SFMCSoapRequest | null {
        if (!this.IsRecord(body)) return null;
        const envelope = body.Envelope;
        const operation = body.Operation;
        if (typeof envelope !== 'string' || typeof operation !== 'string') return null;
        return { Operation: operation as SFMCSoapOperation, Envelope: envelope, ObjectType: this.ScalarString(body.ObjectType) ?? '' };
    }

    /** Narrows a normalized response body to its parsed partnerAPI payload, or null for a REST body. */
    private AsSoapBody(rawBody: unknown): SFMCSoapBody | null {
        if (!this.IsRecord(rawBody)) return null;
        const soap = rawBody._soap;
        if (!this.IsRecord(soap) || !Array.isArray(soap.Records)) return null;
        return soap as unknown as SFMCSoapBody;
    }

    /** Parses a REST body, tolerating an empty body and a non-JSON payload. */
    private ParseJsonBody(text: string): unknown {
        if (!text || text.trim().length === 0) return null;
        try { return JSON.parse(text); } catch { return text; }
    }

    /** Parses a JSON settings/config column into a record (never throws). */
    private ParseJsonRecord(value: string | null): Record<string, unknown> {
        if (!value) return {};
        try {
            const parsed: unknown = JSON.parse(value);
            return this.IsRecord(parsed) ? parsed : {};
        } catch {
            return {};
        }
    }

    /** The first array-valued member of an envelope (the generic collection-detection fallback). */
    private FirstArrayMember(body: Record<string, unknown>): unknown[] | null {
        for (const value of Object.values(body)) {
            if (Array.isArray(value)) return value;
        }
        return null;
    }

    /** Case-insensitive lookup across a settings map, returning the first non-empty match. */
    private PickSetting(settings: Record<string, unknown>, ...keys: string[]): string | null {
        for (const key of keys) {
            for (const [k, v] of Object.entries(settings)) {
                if (k.toLowerCase() !== key.toLowerCase()) continue;
                const text = this.ScalarString(v);
                if (text !== null && text.length > 0) return text;
            }
        }
        return null;
    }

    /** Substitutes the connection's subdomain into a documented host template. */
    private SubstituteSubdomain(template: string, subdomain: string): string {
        return template.replace('{subdomain}', subdomain);
    }

    /** Joins a base URI and a path without doubling or dropping the separator. */
    private JoinURL(baseURL: string, path: string): string {
        const base = baseURL.endsWith('/') ? baseURL.slice(0, -1) : baseURL;
        const suffix = path.startsWith('/') ? path : `/${path}`;
        return `${base}${suffix}`;
    }

    /** Host-only rendering of a URI, for messages that must not echo a full tenant endpoint with a query. */
    private HostOf(url: string): string {
        try { return new URL(url).host; } catch { return url; }
    }

    private IsRecord(value: unknown): value is Record<string, unknown> {
        return typeof value === 'object' && value !== null && !Array.isArray(value);
    }

    private ScalarString(value: unknown): string | null {
        if (value == null) return null;
        if (typeof value === 'string') return value;
        if (typeof value === 'number' || typeof value === 'boolean') return String(value);
        return null;
    }

    private ScalarNumber(value: unknown): number | null {
        if (typeof value === 'number' && Number.isFinite(value)) return value;
        if (typeof value === 'string' && value.trim().length > 0) {
            const parsed = Number(value);
            if (Number.isFinite(parsed)) return parsed;
        }
        return null;
    }

    private ScalarBoolean(value: unknown): boolean | null {
        if (typeof value === 'boolean') return value;
        if (typeof value === 'string') {
            const lower = value.trim().toLowerCase();
            if (lower === 'true') return true;
            if (lower === 'false') return false;
        }
        return null;
    }

    private ScalarText(value: unknown): string {
        if (value instanceof Date) return value.toISOString();
        if (value !== null && typeof value === 'object') return JSON.stringify(value);
        return String(value);
    }

    /** A record's string-valued members, for path-parameter substitution. */
    private StringValued(source: Record<string, unknown>): Record<string, string> {
        const out: Record<string, string> = {};
        for (const [key, value] of Object.entries(source)) {
            const text = this.ScalarString(value);
            if (text !== null) out[key] = text;
        }
        return out;
    }

    /** Bounded-concurrency task runner for the best-effort introspection sweep. */
    private async RunBoundedTasks<T>(items: T[], concurrency: number, worker: (item: T) => Promise<void>): Promise<void> {
        const queue = [...items];
        const lanes = Array.from({ length: Math.max(1, Math.min(concurrency, queue.length)) }, async () => {
            for (;;) {
                const next = queue.shift();
                if (next === undefined) return;
                await worker(next);
            }
        });
        await Promise.all(lanes);
    }

    /** Header list → a lowercase-keyed object. */
    private HeadersToObject(headers: Headers): Record<string, string> {
        const out: Record<string, string> = {};
        headers.forEach((value, key) => { out[key.toLowerCase()] = value; });
        return out;
    }

    /**
     * An error message safe to surface. SFMC bearer tokens are opaque high-entropy strings that a
     * verbose transport error could echo; any `Bearer <token>` / `<fueloauth>` fragment is redacted so a
     * credential can never reach a log, a sync artifact or a UI toast.
     */
    private SafeMessage(err: unknown): string {
        const message = err instanceof Error ? err.message : String(err);
        return this.ScrubSecrets(message);
    }

    /** Redacts bearer tokens, `<fueloauth>` payloads and client secrets from arbitrary text. */
    public ScrubSecrets(text: string): string {
        return text
            .replace(/(Bearer\s+)[A-Za-z0-9._\-]+/gi, '$1***')
            .replace(/(<fueloauth>)[\s\S]*?(<\/fueloauth>)/gi, '$1***$2')
            .replace(/(&lt;fueloauth&gt;)[\s\S]*?(&lt;\/fueloauth&gt;)/gi, '$1***$2')
            .replace(/(client_secret=)[^&\s"']+/gi, '$1***')
            .replace(/("access_token"\s*:\s*")[^"]*(")/gi, '$1***$2');
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
            .replace(/&#x([0-9a-fA-F]+);/g, (_m, hex: string) => String.fromCodePoint(parseInt(hex, 16)))
            .replace(/&#(\d+);/g, (_m, dec: string) => String.fromCodePoint(Number(dec)))
            .replace(/&amp;/g, '&');
    }
}

/** Tree-shaking prevention — import and call from the package entry point / Open App bootstrap. */
export function LoadSFMCConnector(): void { /* no-op */ }
