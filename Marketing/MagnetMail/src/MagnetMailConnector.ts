/**
 * MagnetMailConnector — Higher Logic Marketing Enterprise (formerly Real Magnet / MagnetMail).
 *
 * Legacy SOAP/XML email-marketing platform (`mmapi.asmx`, WSDL document/literal, 55 operations).
 * SOAP rides over HTTP here: this connector extends BaseRESTIntegrationConnector (the ONLY protocol
 * bases the engine exports are BaseIntegrationConnector + BaseRESTIntegrationConnector — there is no
 * BaseSOAPIntegrationConnector) and implements the SOAP 1.1 protocol over the REST base's HTTP seam.
 *
 * WHY the read/write paths are overridden (genuinely idiosyncratic, per the CRUD-routing rule):
 *   - Every operation is a POST to the SAME endpoint (`/mmapi.asmx`); the operation is selected by the
 *     `SOAPAction` header + the body element, NOT by the URL. The base's generic GET-based read loop and
 *     REST-body CRUD cannot express that, so FetchChanges / CreateRecord / UpdateRecord are overridden to
 *     build SOAP envelopes. `CreateBodyShape/UpdateBodyShape = 'literal'` in the frozen metadata is the
 *     explicit "the connector builds the envelope" signal.
 *
 * Auth (two-step SESSION token — no crypto, so auth-helpers do not apply: this is a plaintext
 * credential-for-session-token exchange over TLS, with no signing/hashing/JWT primitive to delegate):
 *   1. POST `Authenticate(username, password)` to the shared endpoint (NO <mmAuthHeader> on this one call).
 *   2. Read `AuthenticationResult.sessionId` + `.user_id`.
 *   3. Attach BOTH verbatim in the <mmAuthHeader> SOAP HEADER (ns http://www.magnetmail.net/) of every
 *      subsequent operation. The session is cached for a TTL and re-obtained on expiry.
 *
 * The per-object SOAP OPERATION name (list/create/update) is read from the IntegrationObject's
 * `Configuration` JSON (`ListOperation` / `CreateOperation` / `UpdateOperation`) — the catalog is NEVER
 * baked into this code (connector-code-conventions § "NEVER bake a catalog"). See CODE_REPORT.md for the
 * frozen-metadata gap where those Configuration keys are not yet emitted.
 *
 * NOTE: the WSDL is a FIXED, versionless surface fetched once at build time — NOT a live per-credential
 * describe endpoint — so DiscoveryIsAuthoritative stays false (never disable Declared rows on absence).
 */
import { RegisterClass } from '@memberjunction/global';
import { Metadata, type UserInfo } from '@memberjunction/core';
import type {
    MJCompanyIntegrationEntity,
    MJCredentialEntity,
    MJIntegrationObjectEntity,
    MJIntegrationObjectFieldEntity,
} from '@memberjunction/core-entities';
import { z } from 'zod';
import {
    BaseIntegrationConnector,
    BaseRESTIntegrationConnector,
    computeContentHash,
    serializeKeyValue,
    type RESTAuthContext,
    type RESTResponse,
    type PaginationState,
    type PaginationType,
    type ConnectionTestResult,
    type FetchContext,
    type FetchBatchResult,
    type FetchWarning,
    type ExternalRecord,
    type CreateRecordContext,
    type UpdateRecordContext,
    type CRUDResult,
    type SourceSchemaInfo,
} from '@memberjunction/integration-engine';
import { mergeDeclaredWithSampledFields } from '@memberjunction/connector-schema-merge';

// ─── Constants ───────────────────────────────────────────────────────

const DEFAULT_ENDPOINT = 'https://hlma-apie1.magnetmail.net/mmapi.asmx';
const DEFAULT_NAMESPACE = 'http://www.magnetmail.net/';
const DEFAULT_SESSION_TTL_MS = 25 * 60 * 1000;
const DEFAULT_COLD_START_DATE = '2010-01-01';
const DEFAULT_WINDOW_DAYS = 30;
const MS_PER_DAY = 86_400_000;
const ISO_DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

// ─── Types ───────────────────────────────────────────────────────────

/** Non-secret + secret connection settings, resolved from the credential store and Configuration JSON. */
interface MagnetMailConfig {
    Username: string;
    Password: string;
    Endpoint: string;
    Namespace: string;
    SessionTTLMs: number;
}

/** Auth context carried through every request. SessionID + UserId feed the <mmAuthHeader> SOAP header. */
export interface MagnetMailAuthContext extends RESTAuthContext {
    /** AuthenticationResult.sessionId — the mmAuthHeader session token. */
    SessionID: string;
    /** AuthenticationResult.user_id — the mmAuthHeader account-scope id (NOT the login username). */
    UserId: string;
    /** Resolved SOAP endpoint URL. */
    Endpoint: string;
    /** Resolved SOAP target namespace. */
    Namespace: string;
}

/**
 * The structured SOAP request the connector hands to {@link MagnetMailConnector.MakeHTTPRequest} as its
 * `body`. MakeHTTPRequest is where the SOAP 1.1 envelope is actually built (per the task contract), from
 * this descriptor + the auth context — so tests that mock MakeHTTPRequest capture the meaningful wire
 * intent (action + args) and the envelope XML itself is unit-tested via {@link buildSoapEnvelope}.
 */
export interface SoapRequest {
    /** SOAP operation name (== body element name == SOAPAction suffix). */
    Action: string;
    /** Operation body arguments (may nest objects / arrays; rendered recursively). */
    Args: Record<string, unknown>;
    /** Whether to emit the <mmAuthHeader> SOAP header (false only for the Authenticate call). */
    IncludeAuthHeader: boolean;
    /** Optional wrapper element the args nest inside (e.g. `criteria` for search operations). */
    WrapperElement?: string | null;
}

/** Metered migration pacing & run-budget configuration (`CompanyIntegration.Configuration.migrationPacing`). */
export interface MagnetMailMigrationPacing {
    tokensPerSec?: number;
    burst?: number;
    maxConcurrency?: number;
    minDelayBetweenRequestsMs?: number;
    maxRequestsPerRun?: number;
    maxWindowsPerRun?: number;
    checkpointPerWindow?: boolean;
}

/** Per-object or global sliding date-window configuration for MagnetMail SOAP operations. */
export interface MagnetMailDateWindowConfig {
    startDate?: string;
    windowDays?: number;
    lookbackDays?: number;
    fromParam?: string;
    toParam?: string;
    capThreshold?: number;
}

/** Inclusive `[From, To]` ISO `YYYY-MM-DD` date window. */
export interface MagnetMailDateWindow {
    From: string;
    To: string;
}

/** Composite cursor `v1|<Today>|<From>|<To>|<InnerPage>|<ScopeKey>` for resumable windowed SOAP harvests. */
export interface MagnetMailWindowCursor {
    Today: string;
    From: string;
    To: string;
    InnerPage: number;
    ScopeKey: string;
}

/** Per-SOAP-operation WSDL parameter conventions (5 date-range conventions + 4 pagination conventions + criteria wrapper). */
export interface SoapOperationConvention {
    WrapperElement?: string;
    PageNumberParam?: string;
    PageCountParam?: string;
    FromParam?: string;
    ToParam?: string;
}

/**
 * WSDL-verified per-operation parameter conventions across MagnetMail's 55 SOAP operations:
 * - 4 distinct pagination conventions (`pageNumber`/`pageCount`, `page`/`recordsPerPage`, `pageNo`/`pageSize`, `PageNo`/`PageSize`)
 * - 5 distinct date-range conventions (`sentStartDate`/`sentEndDate`, `fromDate`/`toDate`, `startDate`/`endDate`, `start_date`/`end_date`, `SearchStartDate`/`SearchEndDate`)
 * - 6 `<criteria>`-wrapped operations (`searchForRecipients`, `GetMessageLinkTracking`, `GetMessageSentTracking`, `GetMessageOpenTracking`, `GetUnsubscribeTracking`, `SearchPersonifySubscriptionMappings`)
 */
export const SOAP_OPERATION_CONVENTIONS: Readonly<Record<string, SoapOperationConvention>> = {
    getGroupRecipients: { PageNumberParam: 'pageNumber', PageCountParam: 'pageCount' },
    getDetailedTracking: { PageNumberParam: 'page', PageCountParam: 'recordsPerPage', FromParam: 'fromDate', ToParam: 'toDate' },
    getDetailedTrackingUTC: { PageNumberParam: 'page', PageCountParam: 'recordsPerPage', FromParam: 'fromDate', ToParam: 'toDate' },
    searchForRecipients: { WrapperElement: 'criteria', PageNumberParam: 'pageNo', PageCountParam: 'pageSize' },
    GetMessageLinkTracking: { WrapperElement: 'criteria', PageNumberParam: 'PageNo', PageCountParam: 'PageSize', FromParam: 'SearchStartDate', ToParam: 'SearchEndDate' },
    GetMessageSentTracking: { WrapperElement: 'criteria', PageNumberParam: 'PageNo', PageCountParam: 'PageSize', FromParam: 'SearchStartDate', ToParam: 'SearchEndDate' },
    GetMessageOpenTracking: { WrapperElement: 'criteria', PageNumberParam: 'PageNo', PageCountParam: 'PageSize', FromParam: 'SearchStartDate', ToParam: 'SearchEndDate' },
    GetUnsubscribeTracking: { WrapperElement: 'criteria', PageNumberParam: 'PageNo', PageCountParam: 'PageSize', FromParam: 'SearchStartDate', ToParam: 'SearchEndDate' },
    SearchPersonifySubscriptionMappings: { WrapperElement: 'criteria' },
    getMessages: { FromParam: 'sentStartDate', ToParam: 'sentEndDate' },
    getMessagesUTC: { FromParam: 'sentStartDate', ToParam: 'sentEndDate' },
    getMessageList: { FromParam: 'sentStartDate', ToParam: 'sentEndDate' },
    getMessageListUtc: { FromParam: 'sentStartDate', ToParam: 'sentEndDate' },
    getUnsubscribes: { FromParam: 'fromDate', ToParam: 'toDate' },
    getSpamComplaints: { FromParam: 'fromDate', ToParam: 'toDate' },
    getSubscribedRecipients: { FromParam: 'startDate', ToParam: 'endDate' },
    getSuppressedRecipientList: { FromParam: 'start_date', ToParam: 'end_date' },
};

// ─── Date Window Arithmetic ──────────────────────────────────────────

export function toISODate(d: Date): string {
    return d.toISOString().slice(0, 10);
}

export function addDays(iso: string, days: number): string {
    const base = Date.parse(`${iso.slice(0, 10)}T00:00:00Z`);
    if (Number.isNaN(base)) return iso;
    return new Date(base + days * MS_PER_DAY).toISOString().slice(0, 10);
}

export function daysBetween(fromIso: string, toIso: string): number {
    const a = Date.parse(`${fromIso.slice(0, 10)}T00:00:00Z`);
    const b = Date.parse(`${toIso.slice(0, 10)}T00:00:00Z`);
    if (Number.isNaN(a) || Number.isNaN(b)) return DEFAULT_WINDOW_DAYS;
    return Math.max(1, Math.ceil((b - a) / MS_PER_DAY));
}

const minDate = (a: string, b: string): string => (a < b ? a : b);
const maxDate = (a: string, b: string): string => (a > b ? a : b);

export function initialMagnetMailDateWindow(
    cfg: MagnetMailDateWindowConfig,
    watermark: string | null | undefined,
    today: string
): MagnetMailDateWindow {
    const startFloor = cfg.startDate && ISO_DATE_RE.test(cfg.startDate.slice(0, 10))
        ? cfg.startDate.slice(0, 10)
        : DEFAULT_COLD_START_DATE;
    const lookback = Math.max(0, cfg.lookbackDays ?? 0);
    const windowDays = Math.max(1, cfg.windowDays ?? DEFAULT_WINDOW_DAYS);

    let from = watermark && ISO_DATE_RE.test(watermark.slice(0, 10))
        ? addDays(watermark.slice(0, 10), -lookback)
        : startFloor;
    if (cfg.startDate && ISO_DATE_RE.test(cfg.startDate.slice(0, 10))) {
        from = maxDate(from, cfg.startDate.slice(0, 10));
    }
    from = minDate(from, today);
    const to = minDate(addDays(from, windowDays - 1), today);
    return { From: from, To: to };
}

export function nextMagnetMailDateWindow(
    current: MagnetMailDateWindow,
    cfg: MagnetMailDateWindowConfig,
    today: string
): MagnetMailDateWindow | null {
    if (current.To >= today) return null;
    const windowDays = Math.max(1, cfg.windowDays ?? DEFAULT_WINDOW_DAYS);
    const from = addDays(current.To, 1);
    const to = minDate(addDays(from, windowDays - 1), today);
    return { From: from, To: to };
}

export function bisectMagnetMailDateWindow(current: MagnetMailDateWindow): MagnetMailDateWindow | null {
    if (current.From >= current.To) return null;
    const span = daysBetween(current.From, current.To);
    const half = Math.max(0, Math.floor(span / 2) - 1);
    const mid = addDays(current.From, half);
    if (mid >= current.To) return { From: current.From, To: current.From };
    return { From: current.From, To: mid };
}

export function formatMagnetMailWindowCursor(c: MagnetMailWindowCursor): string {
    return ['v1', c.Today, c.From, c.To, String(Math.max(1, c.InnerPage || 1)), c.ScopeKey || ''].join('|');
}

export function parseMagnetMailWindowCursor(raw: string | null | undefined): MagnetMailWindowCursor | null {
    if (!raw || !raw.startsWith('v1|')) return null;
    const parts = raw.split('|');
    if (parts.length < 5) return null;
    const [, today, from, to, innerRaw, scopeKey = ''] = parts;
    if (!ISO_DATE_RE.test(today) || !ISO_DATE_RE.test(from) || !ISO_DATE_RE.test(to)) return null;
    const innerPage = Math.max(1, parseInt(innerRaw, 10) || 1);
    return { Today: today, From: from, To: to, InnerPage: innerPage, ScopeKey: scopeKey };
}

/** Cached session state. */
interface CachedSession {
    Auth: MagnetMailAuthContext;
    CreatedAt: number;
    TTLMs: number;
}

/** Zod schema for the resolved config (post key-normalization). */
const ConfigSchema = z.object({
    Username: z.string().min(1, 'MagnetMail username is required'),
    Password: z.string().min(1, 'MagnetMail password is required'),
    Endpoint: z.string().min(1),
    Namespace: z.string().min(1),
    SessionTTLMs: z.number().positive(),
});

// ─── Connector ───────────────────────────────────────────────────────

// Primary key follows the catalog convention (className == npm package name;
// see scripts/build-connectors-catalog.mjs) — instance discovery reports the
// package name, so the legacy bare key never matched in the catalog. The
// legacy alias stays registered so pre-migration tenant Integration rows
// keep resolving.
@RegisterClass(BaseIntegrationConnector, '@memberjunction/connector-magnetmail')
@RegisterClass(BaseIntegrationConnector, 'MagnetMailConnector')
export class MagnetMailConnector extends BaseRESTIntegrationConnector {

    /** Cached session token (protected so the mocked test subclass can seed it without a live auth call). */
    protected cachedSession: CachedSession | null = null;
    private activePacing: MagnetMailMigrationPacing | null = null;

    // ── Identity + capabilities ──────────────────────────────────────

    /** Verbatim MJ: Integrations.Name (three-way identity invariant). */
    public override get IntegrationName(): string { return 'magnetmail'; }

    /** Vendor supports create (addRecipient / addGroup / createMagnetMailMessage / …) — wired via SOAP override. */
    public override get SupportsCreate(): boolean { return true; }
    /** Vendor supports update (editRecipient / editMagnetMailMessage) — wired via SOAP override. */
    public override get SupportsUpdate(): boolean { return true; }
    /** NO delete/remove operation exists anywhere in the 55-operation WSDL surface — honestly false. */
    public override get SupportsDelete(): boolean { return false; }

    /**
     * The WSDL is a fixed, versionless surface fetched once at build — NOT a live per-credential describe
     * endpoint. Keep the base default so the comprehensive-refresh deactivation path never disables
     * Declared IO/IOF rows on absence.
     */
    public override get DiscoveryIsAuthoritative(): boolean { return false; }

    /** Conservative rate-limit policy for legacy SOAP endpoint; dynamically overridden by `migrationPacing`. */
    public get RateLimitPolicy(): { TokensPerSec: number; Burst: number } | null {
        const tokensPerSec = this.activePacing?.tokensPerSec ?? 2;
        const burst = this.activePacing?.burst ?? 4;
        return { TokensPerSec: tokensPerSec, Burst: burst };
    }

    /** Serializes legacy SOAP queries by default; dynamically overridden by `migrationPacing.maxConcurrency`. */
    public get MaxConcurrencyHint(): number {
        return this.activePacing?.maxConcurrency ?? 2;
    }

    /** Injectable sleep seam for metered migration pacing (overridden in unit tests for zero-delay assertions). */
    protected async Sleep(ms: number): Promise<void> {
        await new Promise(resolve => setTimeout(resolve, ms));
    }

    // ── TestConnection (abstract on BaseIntegrationConnector) ─────────

    public async TestConnection(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<ConnectionTestResult> {
        try {
            const auth = await this.Authenticate(companyIntegration, contextUser);
            return {
                Success: true,
                Message: `Authenticated to MagnetMail (user_id=${auth.UserId})`,
                ServerVersion: 'MagnetMail mmapi.asmx (SOAP 1.1)',
            };
        } catch (err: unknown) {
            const message = err instanceof Error ? err.message : String(err);
            const authFailure = /fault|authenticat|unauthor|session|invalid/i.test(message);
            return {
                Success: false,
                Message: authFailure
                    ? `MagnetMail authentication failed: ${message}`
                    : `MagnetMail connection error: ${message}`,
            };
        }
    }

    // ── Auth (abstract on BaseRESTIntegrationConnector) ───────────────

    /** Two-step SOAP session auth with TTL caching. Returns the mmAuthHeader session context. */
    protected async Authenticate(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<MagnetMailAuthContext> {
        if (this.isSessionValid()) return this.cachedSession!.Auth;

        const config = await this.ParseConfig(companyIntegration, contextUser);
        const preAuth = this.preAuthContext(config);
        const request: SoapRequest = {
            Action: 'Authenticate',
            Args: { username: config.Username, password: config.Password },
            IncludeAuthHeader: false,
        };
        const response = await this.MakeHTTPRequest(preAuth, config.Endpoint, 'POST', this.BuildHeaders(preAuth), request);
        this.throwOnSoapFault(response, 'Authenticate');

        const result = this.unwrapSoapResult(response.Body);
        const sessionId = this.readNestedString(result, 'sessionId') ?? this.readNestedString(result, 'AuthenticateResult');
        const userId = this.readNestedString(result, 'user_id') ?? '';
        if (!sessionId) {
            throw new Error('MagnetMail Authenticate returned no sessionId');
        }
        const auth: MagnetMailAuthContext = {
            SessionID: sessionId,
            UserId: userId,
            Endpoint: config.Endpoint,
            Namespace: config.Namespace,
        };
        this.cachedSession = { Auth: auth, CreatedAt: Date.now(), TTLMs: config.SessionTTLMs };
        return auth;
    }

    /** Content-type headers for a SOAP 1.1 POST. The per-operation SOAPAction is added in MakeHTTPRequest. */
    protected BuildHeaders(_auth: RESTAuthContext): Record<string, string> {
        return {
            'Content-Type': 'text/xml; charset=utf-8',
            'Accept': 'text/xml',
        };
    }

    /** The SOAP endpoint URL. For SOAP the operation is in the SOAPAction + body, not the path. */
    protected GetBaseURL(_companyIntegration: MJCompanyIntegrationEntity, auth: RESTAuthContext): string {
        return (auth as MagnetMailAuthContext).Endpoint ?? DEFAULT_ENDPOINT;
    }

    // ── HTTP transport — builds + POSTs the SOAP envelope ─────────────

    /**
     * The SOAP transport boundary. `body` MUST be a {@link SoapRequest}; MakeHTTPRequest builds the SOAP
     * 1.1 envelope from it (+ the auth context's <mmAuthHeader>), POSTs with `Content-Type: text/xml` and
     * `SOAPAction: "<namespace><action>"`, and parses the XML response into a JS object (faults surfaced
     * as `Body._soapFault`). Test subclasses override this to capture the request and return canned bodies.
     */
    protected async MakeHTTPRequest(
        auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown
    ): Promise<RESTResponse> {
        const soapAuth = auth as MagnetMailAuthContext;
        const request = body as SoapRequest | undefined;
        if (!request || typeof request.Action !== 'string') {
            throw new Error('MagnetMailConnector.MakeHTTPRequest requires a SoapRequest body (Action + Args)');
        }
        const envelope = this.buildSoapEnvelope(soapAuth, request);
        const soapAction = `${soapAuth.Namespace ?? DEFAULT_NAMESPACE}${request.Action}`;
        const reqHeaders: Record<string, string> = { ...headers, 'SOAPAction': `"${soapAction}"` };

        const httpResponse = await fetch(url, { method, headers: reqHeaders, body: envelope });
        const text = await httpResponse.text();
        return this.parseSoapResponse(text, httpResponse.status, this.headersToObject(httpResponse.headers));
    }

    // ── NormalizeResponse (abstract) — strip <action>Result wrapper ───

    /**
     * Strips the SOAP `<{action}Response>` / `<{action}Result>` envelope, then locates the record set.
     * When `responseDataKey` (the XSD record-type name, e.g. `Recipient`) is given it is deep-found —
     * which also transparently descends any `AccessPath` nesting (`RecipientSuppressionList` →
     * `ArrayOfRecipient` → `Recipient`) without the connector needing to hard-code the path. A single
     * record object is returned as a one-element array; a missing/nil set as `[]`.
     */
    protected NormalizeResponse(rawBody: unknown, responseDataKey: string | null): Record<string, unknown>[] {
        if (rawBody == null) return [];
        const unwrapped = this.unwrapSoapResult(rawBody);
        if (unwrapped == null) return [];

        let target: unknown = unwrapped;
        if (responseDataKey) {
            const found = this.deepFindKey(unwrapped, responseDataKey);
            if (found === undefined) return []; // declared record type absent → no records
            target = found;
        } else if (unwrapped && typeof unwrapped === 'object' && !Array.isArray(unwrapped)) {
            const arr = this.firstArrayValue(unwrapped as Record<string, unknown>);
            if (arr) target = arr;
        }

        return this.toRecordArray(target);
    }

    // ── ExtractPaginationInfo (abstract) — pageNumber/pageCount ───────

    /**
     * SOAP has no envelope-level pagination metadata; HasMore is inferred from whether a FULL page came
     * back (record count == pageSize). Operations declared `PaginationType: None` never take page args and
     * always report a single page.
     */
    protected ExtractPaginationInfo(
        rawBody: unknown,
        paginationType: PaginationType,
        currentPage: number,
        currentOffset: number,
        pageSize: number
    ): PaginationState {
        if (paginationType === 'None') return { HasMore: false };
        const count = this.recordCount(rawBody);
        const hasMore = pageSize > 0 && count >= pageSize;
        if (paginationType === 'Offset') {
            return { HasMore: hasMore, NextOffset: currentOffset + count };
        }
        // PageNumber (MagnetMail's pageNumber/pageCount) and any other page-style: advance the page number.
        return { HasMore: hasMore, NextPage: currentPage + 1 };
    }

    // ── IntrospectSchema (declared + sampled field union) ─────────────

    /**
     * Never-shrink SAMPLE-UNION: enrich each object's DECLARED (WSDL/metadata) field set with fields
     * observed by live SAMPLING (`DiscoverFieldsViaFetch`), so a tenant's custom/undeclared columns are
     * captured at connection time without ever losing or narrowing a declared field. Declared attributes
     * stay authoritative; sampling only fills gaps, widens capacities, and appends undeclared columns
     * (`mergeDeclaredWithSampledFields` — max(declared, sampled)). Per object, parallel + best-effort: a
     * sampling failure for one object never fails introspection (its declared fields stand). Connector-
     * agnostic wiring — no MagnetMail-specific logic here.
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

    // ── FetchChanges (SOAP read) ──────────────────────────────────────

    /**
     * SOAP read for one object. Reads the list SOAP operation from the IO's Configuration (`ListOperation`
     * / `SoapListAction`), applies pageNumber/pageCount when the object supports pagination, and the
     * incremental date-range param when SupportsIncrementalSync. Fetches ONE page per call; the engine
     * loops on HasMore + NextPage. Full-record pass-through: every source key reaches Fields.
     */
    public override async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
        const obj = this.GetCachedObject(ctx.CompanyIntegration.IntegrationID, ctx.ObjectName);
        const fields = this.GetCachedFields(obj.ID);
        const cfg = this.readIOConfig(obj);
        const pacing = this.readMigrationPacing(ctx.CompanyIntegration);
        this.activePacing = pacing;

        const listOp = this.readConfigString(cfg, 'ListOperation') ?? this.readConfigString(cfg, 'SoapListAction');
        if (!listOp) {
            // The list SOAP operation isn't wired in this IO's Configuration. Surface it loudly instead of
            // silently returning nothing (see CODE_REPORT.md — frozen-metadata operation-mapping gap).
            return {
                Records: [],
                HasMore: false,
                Warnings: [{
                    Code: 'NO_LIST_OPERATION',
                    Message: `"${obj.Name}": no SOAP list operation in Configuration (expected Configuration.ListOperation). ` +
                        `Cannot fetch until the operation is wired.`,
                    Data: { object: obj.Name },
                }],
            };
        }

        const auth = await this.Authenticate(ctx.CompanyIntegration, ctx.ContextUser);
        const windowCfg = this.resolveDateWindowConfig(ctx.CompanyIntegration, obj, cfg, listOp);
        const resumedCursor = parseMagnetMailWindowCursor(ctx.CurrentCursor) ?? parseMagnetMailWindowCursor(ctx.WatermarkValue);
        if (windowCfg || resumedCursor) {
            return this.fetchDateWindowedChanges(ctx, obj, fields, cfg, listOp, auth, pacing, windowCfg ?? {}, resumedCursor);
        }

        const page = ctx.CurrentPage ?? 1;
        const offset = ctx.CurrentOffset ?? 0;
        const pageSize = obj.DefaultPageSize && obj.DefaultPageSize > 0 ? obj.DefaultPageSize : Math.max(1, ctx.BatchSize);
        const convention = SOAP_OPERATION_CONVENTIONS[listOp];

        if ((page > 1 || offset > 0) && pacing?.minDelayBetweenRequestsMs && pacing.minDelayBetweenRequestsMs > 0) {
            await this.Sleep(pacing.minDelayBetweenRequestsMs);
        }

        const args = this.buildFetchArgs(obj, cfg, ctx, page, pageSize, listOp);
        const wrapper = this.readConfigString(cfg, 'CriteriaWrapper') ?? convention?.WrapperElement ?? null;
        const request: SoapRequest = { Action: listOp, Args: args, IncludeAuthHeader: true, WrapperElement: wrapper };

        const response = await this.MakeHTTPRequest(auth, auth.Endpoint, 'POST', this.BuildHeaders(auth), request);
        this.throwOnSoapFault(response, listOp);

        const rawRecords = this.NormalizeResponse(response.Body, obj.ResponseDataKey);
        const pkFieldNames = this.primaryKeyFieldNames(fields);
        const records = rawRecords.map(r => this.buildExternalRecord(
            this.applyTransformPreservingKeys(r, obj, fields),
            ctx.ObjectName,
            pkFieldNames
        ));

        const pagination = this.ExtractPaginationInfo(response.Body, obj.PaginationType as PaginationType, page, offset, pageSize);
        const newWatermark = this.computeWatermark(obj, cfg, rawRecords);

        return {
            Records: records,
            HasMore: pagination.HasMore,
            NextPage: pagination.NextPage,
            NextOffset: pagination.NextOffset,
            NewWatermarkValue: newWatermark,
        };
    }

    /**
     * Stateful sliding date-window harvest for MagnetMail SOAP operations (`v1|<Today>|<From>|<To>|<InnerPage>|`).
     * Supports all 5 WSDL date-range parameter conventions and all 4 pagination conventions, plus adaptive
     * window bisection for non-paginated operations (`getUnsubscribes`, `getSpamComplaints`, `getMessagesUTC`, etc.)
     * and metered run-budget controls (`maxRequestsPerRun`, `maxWindowsPerRun`, `checkpointPerWindow`).
     */
    private async fetchDateWindowedChanges(
        ctx: FetchContext,
        obj: MJIntegrationObjectEntity,
        fields: MJIntegrationObjectFieldEntity[],
        cfg: Record<string, unknown>,
        listOp: string,
        auth: MagnetMailAuthContext,
        pacing: MagnetMailMigrationPacing | null,
        windowCfg: MagnetMailDateWindowConfig,
        resumedCursor: MagnetMailWindowCursor | null
    ): Promise<FetchBatchResult> {
        const convention = SOAP_OPERATION_CONVENTIONS[listOp];
        const fromParam = windowCfg.fromParam
            ?? this.readConfigString(cfg, 'WatermarkFromParam')
            ?? obj.IncrementalWatermarkField
            ?? convention?.FromParam
            ?? 'fromDate';
        const toParam = windowCfg.toParam
            ?? this.readConfigString(cfg, 'WatermarkToParam')
            ?? convention?.ToParam
            ?? 'toDate';
        const wrapper = this.readConfigString(cfg, 'CriteriaWrapper') ?? convention?.WrapperElement ?? null;
        const pageSize = obj.DefaultPageSize && obj.DefaultPageSize > 0 ? obj.DefaultPageSize : Math.max(1, ctx.BatchSize || 100);
        const batchLimit = ctx.BatchSize && ctx.BatchSize > 0 ? ctx.BatchSize : Number.MAX_SAFE_INTEGER;
        const minDelayMs = pacing?.minDelayBetweenRequestsMs ?? 0;
        const maxRequests = pacing?.maxRequestsPerRun && pacing.maxRequestsPerRun > 0 ? pacing.maxRequestsPerRun : Number.MAX_SAFE_INTEGER;
        const maxWindows = pacing?.maxWindowsPerRun && pacing.maxWindowsPerRun > 0 ? pacing.maxWindowsPerRun : Number.MAX_SAFE_INTEGER;
        const checkpointPerWindow = pacing?.checkpointPerWindow === true;
        const capThreshold = windowCfg.capThreshold ?? 0;
        const supportsPaging = Boolean(
            (obj.SupportsPagination && obj.PaginationType !== 'None')
            || convention?.PageNumberParam
            || this.readConfigString(cfg, 'PageNumberParam')
        );

        const today = resumedCursor?.Today ?? toISODate(new Date());
        let window: MagnetMailDateWindow = resumedCursor
            ? { From: resumedCursor.From, To: resumedCursor.To }
            : initialMagnetMailDateWindow(windowCfg, ctx.WatermarkValue, today);
        let innerPage = resumedCursor?.InnerPage ?? 1;

        const out: ExternalRecord[] = [];
        const warnings: FetchWarning[] = [];
        const pkFieldNames = this.primaryKeyFieldNames(fields);
        let requestsMade = 0;
        let windowsCompleted = 0;
        let lastCompletedWindowTo: string | null = null;
        let maxRecordWatermark: string | undefined;
        let hasMore = true;

        while (hasMore && out.length < batchLimit) {
            if (requestsMade >= maxRequests || windowsCompleted >= maxWindows) {
                break;
            }
            if (requestsMade > 0 && minDelayMs > 0) {
                await this.Sleep(minDelayMs);
            }

            const args = this.buildWindowedFetchArgs(obj, cfg, listOp, window, innerPage, pageSize, fromParam, toParam, supportsPaging);
            const request: SoapRequest = { Action: listOp, Args: args, IncludeAuthHeader: true, WrapperElement: wrapper };
            const response = await this.MakeHTTPRequest(auth, auth.Endpoint, 'POST', this.BuildHeaders(auth), request);
            this.throwOnSoapFault(response, listOp);
            requestsMade++;

            const rawRecords = this.NormalizeResponse(response.Body, obj.ResponseDataKey);

            // Adaptive window bisection when a non-paginated SOAP op returns >= capThreshold rows across a multi-day window
            if (!supportsPaging && capThreshold > 0 && rawRecords.length >= capThreshold) {
                const bisected = bisectMagnetMailDateWindow(window);
                if (bisected) {
                    warnings.push({
                        Code: 'WINDOW_BISECTED',
                        Message: `"${obj.Name}" (${listOp}): window [${window.From}, ${window.To}] returned ${rawRecords.length} rows (>= cap ${capThreshold}); bisecting to [${bisected.From}, ${bisected.To}].`,
                        Data: { object: obj.Name, operation: listOp, originalFrom: window.From, originalTo: window.To, bisectedTo: bisected.To },
                    });
                    window = bisected;
                    innerPage = 1;
                    continue;
                }
            }

            for (const r of rawRecords) {
                out.push(this.buildExternalRecord(
                    this.applyTransformPreservingKeys(r, obj, fields),
                    ctx.ObjectName,
                    pkFieldNames
                ));
            }
            const batchWm = this.computeWatermark(obj, cfg, rawRecords);
            if (batchWm && (!maxRecordWatermark || batchWm > maxRecordWatermark)) {
                maxRecordWatermark = batchWm;
            }

            // Inner pagination within [window.From, window.To]
            if (supportsPaging && pageSize > 0 && rawRecords.length >= pageSize) {
                innerPage++;
                continue;
            }

            // Window [window.From, window.To] is fully drained!
            lastCompletedWindowTo = window.To;
            windowsCompleted++;
            innerPage = 1;

            const nextWin = nextMagnetMailDateWindow(window, windowCfg, today);
            if (nextWin) {
                window = nextWin;
                if (checkpointPerWindow) {
                    break;
                }
            } else {
                hasMore = false;
                break;
            }
        }

        const nextCursor = hasMore
            ? formatMagnetMailWindowCursor({ Today: today, From: window.From, To: window.To, InnerPage: innerPage, ScopeKey: '' })
            : undefined;

        const candidateWm = maxRecordWatermark ?? lastCompletedWindowTo ?? undefined;
        return {
            Records: out,
            HasMore: hasMore,
            NextCursor: nextCursor,
            NewWatermarkValue: (!hasMore || lastCompletedWindowTo != null) ? candidateWm : undefined,
            Warnings: warnings.length > 0 ? warnings : undefined,
        };
    }

    // ── CRUD (SOAP mutation envelopes) ────────────────────────────────

    /**
     * SOAP create. Reads the mutation SOAP action from Configuration.CreateOperation, builds a `literal`
     * SOAP envelope, POSTs it, and routes the result through BuildCreatedResult so a 2xx with no record ID
     * fails LOUDLY (never a silent record-loss / duplicate-on-next-sync).
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
        const cfg = this.readIOConfig(obj);
        const action = this.readConfigString(cfg, 'CreateOperation');
        if (!action) {
            return {
                Success: false,
                StatusCode: 400,
                ErrorMessage: `CreateRecord for "${ctx.ObjectName}": Configuration.CreateOperation (SOAP action) not configured.`,
            };
        }

        try {
            const auth = await this.Authenticate(ci, contextUser);
            const request: SoapRequest = { Action: action, Args: ctx.Attributes, IncludeAuthHeader: true };
            const response = await this.MakeHTTPRequest(auth, auth.Endpoint, 'POST', this.BuildHeaders(auth), request);
            this.throwOnSoapFault(response, action);
            // A 200/literal SOAP body can STILL signal failure in-band (SaveResult.error/errorObj/msg) — a SOAP
            // Fault is not the only failure signal this API uses (frozen contract ErrorResponseShape). Detect it
            // BEFORE trusting the id, so a create is never counted as success on a vendor-signalled error.
            const inBandError = this.extractInBandError(response.Body);
            if (inBandError) {
                return { Success: false, StatusCode: response.Status, ErrorMessage: `CreateRecord failed for ${ctx.ObjectName}: ${inBandError}` };
            }
            const externalID = this.extractMutationId(response.Body, obj);
            return this.BuildCreatedResult(externalID, response.Status, ctx.ObjectName);
        } catch (err: unknown) {
            return this.buildCRUDError(err, 'CreateRecord', ctx.ObjectName);
        }
    }

    /**
     * SOAP update. Reads the mutation SOAP action from Configuration.UpdateOperation, injects the target
     * ExternalID into the body under the object's primary-key field name, and POSTs the `literal` envelope.
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
        const cfg = this.readIOConfig(obj);
        const action = this.readConfigString(cfg, 'UpdateOperation');
        if (!action) {
            return {
                Success: false,
                StatusCode: 400,
                ErrorMessage: `UpdateRecord for "${ctx.ObjectName}": Configuration.UpdateOperation (SOAP action) not configured.`,
            };
        }

        try {
            const auth = await this.Authenticate(ci, contextUser);
            const fields = this.GetCachedFields(obj.ID);
            const pkName = this.primaryKeyFieldNames(fields)[0];
            const args: Record<string, unknown> = { ...ctx.Attributes };
            if (pkName && args[pkName] === undefined) args[pkName] = ctx.ExternalID;
            const request: SoapRequest = { Action: action, Args: args, IncludeAuthHeader: true };
            const response = await this.MakeHTTPRequest(auth, auth.Endpoint, 'POST', this.BuildHeaders(auth), request);
            this.throwOnSoapFault(response, action);
            // In-band error check (same rationale as CreateRecord): an edit* response can carry error/errorObj/msg
            // inside a structurally-successful 200 body.
            const inBandError = this.extractInBandError(response.Body);
            if (inBandError) {
                return { Success: false, StatusCode: response.Status, ErrorMessage: `UpdateRecord failed for ${ctx.ObjectName}: ${inBandError}` };
            }
            return { Success: true, StatusCode: response.Status, ExternalID: ctx.ExternalID };
        } catch (err: unknown) {
            return this.buildCRUDError(err, 'UpdateRecord', ctx.ObjectName);
        }
    }

    // ── SOAP envelope building ────────────────────────────────────────

    /** Builds a SOAP 1.1 envelope with the optional <mmAuthHeader> header and the operation body. */
    protected buildSoapEnvelope(auth: MagnetMailAuthContext, request: SoapRequest): string {
        const ns = auth.Namespace ?? DEFAULT_NAMESPACE;
        const header = request.IncludeAuthHeader
            ? `  <soap:Header>\n    <mmAuthHeader xmlns="${ns}">\n` +
              `      <sessionId>${this.escapeXml(auth.SessionID ?? '')}</sessionId>\n` +
              `      <user_id>${this.escapeXml(auth.UserId ?? '')}</user_id>\n` +
              `    </mmAuthHeader>\n  </soap:Header>\n`
            : '';

        const argsXml = this.renderArgs(request.Args);
        const inner = request.WrapperElement
            ? `      <${request.WrapperElement}>\n${argsXml}\n      </${request.WrapperElement}>`
            : argsXml;

        return `<?xml version="1.0" encoding="utf-8"?>\n` +
            `<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">\n` +
            `${header}  <soap:Body>\n` +
            `    <${request.Action} xmlns="${ns}">\n` +
            `${inner}\n` +
            `    </${request.Action}>\n` +
            `  </soap:Body>\n` +
            `</soap:Envelope>`;
    }

    /** Renders args as XML child elements, recursing into nested objects/arrays; nulls are skipped. */
    protected renderArgs(args: Record<string, unknown>, indent = '      '): string {
        const parts: string[] = [];
        for (const [key, value] of Object.entries(args)) {
            const rendered = this.renderXmlValue(key, value, indent);
            if (rendered) parts.push(rendered);
        }
        return parts.join('\n');
    }

    private renderXmlValue(key: string, value: unknown, indent: string): string {
        if (value == null) return '';
        if (Array.isArray(value)) {
            return value
                .map(item => this.renderXmlValue(key, item, indent))
                .filter(s => s.length > 0)
                .join('\n');
        }
        if (typeof value === 'object') {
            const children = this.renderArgs(value as Record<string, unknown>, indent + '  ');
            return `${indent}<${key}>\n${children}\n${indent}</${key}>`;
        }
        return `${indent}<${key}>${this.escapeXml(String(value))}</${key}>`;
    }

    // ── SOAP response parsing (XML → JS) ──────────────────────────────

    /** Parses a SOAP response envelope into a normalized RESTResponse (Body = parsed <soap:Body> content). */
    protected parseSoapResponse(xml: string, status: number, headers: Record<string, string>): RESTResponse {
        const bodyInner = this.extractElementInner(xml, 'Body') ?? xml;
        const fault = this.extractElementInner(bodyInner, 'Fault');
        if (fault) {
            return {
                Status: status && status >= 400 ? status : 500,
                Body: {
                    _soapFault: {
                        faultcode: this.extractElementInner(fault, 'faultcode')?.trim() ?? 'UNKNOWN',
                        faultstring: this.extractElementInner(fault, 'faultstring')?.trim() ?? 'unknown SOAP fault',
                    },
                },
                Headers: headers,
            };
        }
        return { Status: status, Body: this.xmlToObject(bodyInner), Headers: headers };
    }

    /** Recursively converts an XML fragment's inner content into a JS value (object / array / scalar). */
    protected xmlToObject(xml: string): unknown {
        const normalized = xml.replace(/<(\w+(?::\w+)?)((?:\s[^>]*?)?)\/>/g, '<$1></$1>');
        const children = this.extractChildren(normalized);
        if (children.length === 0) {
            return this.coerceScalar(normalized.trim());
        }
        const obj: Record<string, unknown> = {};
        for (const child of children) {
            const value = this.xmlToObject(child.inner);
            const existing = obj[child.tag];
            if (existing === undefined) {
                obj[child.tag] = value;
            } else if (Array.isArray(existing)) {
                existing.push(value);
            } else {
                obj[child.tag] = [existing, value];
            }
        }
        return obj;
    }

    private extractChildren(xml: string): Array<{ tag: string; inner: string }> {
        const results: Array<{ tag: string; inner: string }> = [];
        const regex = /<(?:\w+:)?(\w+)(?:\s[^>]*)?>([\s\S]*?)<\/(?:\w+:)?\1>/g;
        let match: RegExpExecArray | null;
        while ((match = regex.exec(xml)) !== null) {
            results.push({ tag: match[1], inner: match[2] });
        }
        return results;
    }

    /** Returns the inner content of the first element with the given LOCAL name (namespace-agnostic). */
    private extractElementInner(xml: string, localName: string): string | null {
        const re = new RegExp(`<(?:\\w+:)?${this.escapeRegex(localName)}(?:\\s[^>]*)?>([\\s\\S]*?)<\\/(?:\\w+:)?${this.escapeRegex(localName)}>`, 'i');
        const m = xml.match(re);
        return m ? m[1] : null;
    }

    private coerceScalar(raw: string): unknown {
        if (raw === '') return null;
        if (raw === 'true') return true;
        if (raw === 'false') return false;
        if (/^-?\d+$/.test(raw)) return parseInt(raw, 10);
        if (/^-?\d+\.\d+$/.test(raw)) return parseFloat(raw);
        return this.decodeXml(raw);
    }

    // ── Fault handling ────────────────────────────────────────────────

    /** Returns the parsed SOAP fault ({faultcode, faultstring}) if present, else null. */
    protected extractSoapFault(body: unknown): { faultcode: string; faultstring: string } | null {
        if (body && typeof body === 'object') {
            const f = (body as Record<string, unknown>)._soapFault;
            if (f && typeof f === 'object') {
                const rec = f as Record<string, unknown>;
                return {
                    faultcode: String(rec.faultcode ?? 'UNKNOWN'),
                    faultstring: String(rec.faultstring ?? 'unknown SOAP fault'),
                };
            }
        }
        return null;
    }

    /**
     * Reads the vendor's IN-BAND error signal from a mutation response body (SaveResult / *Result wrapper).
     * Per the frozen contract's ErrorResponseShape: a 200/literal SOAP body can signal failure via `error`
     * (s:double, 0 = success by convention), an `errorObj` (tns:Error: errorCode/errorMessage/errorDetails/…),
     * and/or a human `msg` — a SOAP Fault is NOT the only failure signal this API uses. Returns a
     * human-readable message when the body signals an error, else null.
     */
    protected extractInBandError(body: unknown): string | null {
        const result = this.unwrapSoapResult(body);
        if (!result || typeof result !== 'object' || Array.isArray(result)) return null;
        const rec = result as Record<string, unknown>;

        // errorObj (tns:Error) present with substance → failure.
        const errObj = rec.errorObj;
        if (errObj && typeof errObj === 'object' && !Array.isArray(errObj)) {
            const eo = errObj as Record<string, unknown>;
            const substantive = (v: unknown): boolean =>
                v != null && String(v).trim().length > 0 && String(v).trim() !== '0';
            if ([eo.errorNumber, eo.errorCode, eo.errorMessage, eo.errorDetails, eo.errorType].some(substantive)) {
                const msg = [eo.errorMessage, eo.errorDetails].find(v => v != null && String(v).trim().length > 0);
                return String(msg ?? `errorCode=${eo.errorCode ?? eo.errorNumber ?? 'unknown'}`);
            }
        }

        // Numeric `error` flag: null/absent/0 = success; anything else = failure.
        const errFlag = rec.error;
        if (errFlag != null) {
            const n = typeof errFlag === 'number' ? errFlag : Number(String(errFlag));
            if (Number.isFinite(n) && n !== 0) {
                const humanMsg = typeof rec.msg === 'string' && rec.msg.trim().length > 0 ? rec.msg.trim() : undefined;
                return humanMsg ?? `vendor error flag=${n}`;
            }
        }
        return null;
    }

    /** Throws a descriptive error when a response carries a SOAP fault, and invalidates the session. */
    protected throwOnSoapFault(response: RESTResponse, action: string): void {
        const fault = this.extractSoapFault(response.Body);
        if (fault) {
            this.cachedSession = null; // a fault may be an expired session — force re-auth next call
            throw new Error(`MagnetMail SOAP Fault on ${action} [${fault.faultcode}]: ${fault.faultstring}`);
        }
    }

    // ── Config / session helpers ──────────────────────────────────────

    private isSessionValid(): boolean {
        if (!this.cachedSession) return false;
        return Date.now() - this.cachedSession.CreatedAt < this.cachedSession.TTLMs;
    }

    private preAuthContext(config: MagnetMailConfig): MagnetMailAuthContext {
        return { SessionID: '', UserId: '', Endpoint: config.Endpoint, Namespace: config.Namespace };
    }

    /** Resolves connection config from the credential store (secrets) + Configuration JSON (overrides). */
    protected async ParseConfig(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<MagnetMailConfig> {
        const raw: Record<string, unknown> = {};
        if (companyIntegration.CredentialID) {
            Object.assign(raw, await this.loadCredentialValues(companyIntegration.CredentialID, contextUser));
        }
        if (companyIntegration.Configuration) {
            try {
                Object.assign(raw, JSON.parse(companyIntegration.Configuration) as Record<string, unknown>);
            } catch {
                // non-fatal: fall through to whatever the credential store provided
            }
        }
        return this.normalizeConfig(raw);
    }

    private async loadCredentialValues(credentialID: string, contextUser: UserInfo): Promise<Record<string, unknown>> {
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

    private normalizeConfig(raw: Record<string, unknown>): MagnetMailConfig {
        const pick = (...keys: string[]): string | undefined => {
            for (const key of keys) {
                for (const [k, v] of Object.entries(raw)) {
                    if (k.toLowerCase() === key.toLowerCase() && typeof v === 'string' && v.length > 0) return v;
                }
            }
            return undefined;
        };
        const candidate = {
            Username: pick('username', 'user', 'userId', 'user_id', 'login') ?? '',
            Password: pick('password', 'pass', 'pwd') ?? '',
            Endpoint: pick('endpoint', 'url') ?? DEFAULT_ENDPOINT,
            Namespace: pick('namespace', 'ns') ?? DEFAULT_NAMESPACE,
            SessionTTLMs: typeof raw.SessionTTLMs === 'number' ? raw.SessionTTLMs : DEFAULT_SESSION_TTL_MS,
        };
        const parsed = ConfigSchema.safeParse(candidate);
        if (!parsed.success) {
            throw new Error(`MagnetMail configuration invalid: ${parsed.error.issues.map(i => i.message).join('; ')}`);
        }
        return candidate;
    }

    // ── Fetch-arg + watermark helpers ─────────────────────────────────

    private buildFetchArgs(
        obj: MJIntegrationObjectEntity,
        cfg: Record<string, unknown>,
        ctx: FetchContext,
        page: number,
        pageSize: number,
        listOp?: string
    ): Record<string, unknown> {
        const convention = listOp ? SOAP_OPERATION_CONVENTIONS[listOp] : undefined;
        const args: Record<string, unknown> = {};
        const extraArgs = cfg.ExtraArgs;
        if (extraArgs && typeof extraArgs === 'object' && !Array.isArray(extraArgs)) {
            Object.assign(args, extraArgs as Record<string, unknown>);
        }
        if (obj.SupportsPagination && obj.PaginationType !== 'None') {
            const pageParam = this.readConfigString(cfg, 'PageNumberParam') ?? convention?.PageNumberParam ?? 'pageNumber';
            const sizeParam = this.readConfigString(cfg, 'PageCountParam') ?? convention?.PageCountParam ?? 'pageCount';
            args[pageParam] = page;
            args[sizeParam] = pageSize;
        }
        const fromParam = obj.IncrementalWatermarkField ?? this.readConfigString(cfg, 'WatermarkFromParam') ?? convention?.FromParam;
        if (obj.SupportsIncrementalSync && ctx.WatermarkValue && fromParam) {
            args[fromParam] = this.formatWatermark(ctx.WatermarkValue);
            const toParam = this.readConfigString(cfg, 'WatermarkToParam') ?? (!obj.IncrementalWatermarkField ? convention?.ToParam : undefined);
            if (toParam) args[toParam] = this.formatWatermark(new Date().toISOString());
        }
        return args;
    }

    private buildWindowedFetchArgs(
        obj: MJIntegrationObjectEntity,
        cfg: Record<string, unknown>,
        listOp: string,
        window: MagnetMailDateWindow,
        innerPage: number,
        pageSize: number,
        fromParam: string,
        toParam: string,
        supportsPaging: boolean
    ): Record<string, unknown> {
        const convention = SOAP_OPERATION_CONVENTIONS[listOp];
        const args: Record<string, unknown> = {};
        const extraArgs = cfg.ExtraArgs;
        if (extraArgs && typeof extraArgs === 'object' && !Array.isArray(extraArgs)) {
            Object.assign(args, extraArgs as Record<string, unknown>);
        }
        if (supportsPaging) {
            const pageParam = this.readConfigString(cfg, 'PageNumberParam') ?? convention?.PageNumberParam ?? 'pageNumber';
            const sizeParam = this.readConfigString(cfg, 'PageCountParam') ?? convention?.PageCountParam ?? 'pageCount';
            args[pageParam] = innerPage;
            args[sizeParam] = pageSize;
        }
        args[fromParam] = window.From;
        args[toParam] = window.To;
        return args;
    }

    /** Max record-side watermark value in the batch, or undefined when not incremental / no field present. */
    private computeWatermark(
        obj: MJIntegrationObjectEntity,
        cfg: Record<string, unknown>,
        records: Record<string, unknown>[]
    ): string | undefined {
        if (!obj.SupportsIncrementalSync) return undefined;
        const valueField = this.readConfigString(cfg, 'WatermarkValueField') ?? obj.IncrementalWatermarkField;
        if (!valueField) return undefined;
        let max: string | undefined;
        for (const record of records) {
            const v = record[valueField];
            if (v != null) {
                const s = String(v);
                if (!max || s > max) max = s;
            }
        }
        return max;
    }

    private formatWatermark(watermark: string): string {
        if (/^\d+$/.test(watermark)) {
            const asNum = Number(watermark);
            if (Number.isFinite(asNum) && asNum > 100000000000) return new Date(asNum).toISOString();
        }
        return watermark;
    }

    // ── Record + response shaping helpers ─────────────────────────────

    private toRecordArray(target: unknown): Record<string, unknown>[] {
        if (target == null) return [];
        if (Array.isArray(target)) {
            return target.filter(x => x != null && typeof x === 'object') as Record<string, unknown>[];
        }
        if (typeof target === 'object') return [target as Record<string, unknown>];
        return [];
    }

    /** Descends `Response`/`Result` wrapper elements to expose the inner payload. */
    protected unwrapSoapResult(body: unknown): unknown {
        let current = body;
        for (let depth = 0; depth < 6; depth++) {
            if (!current || typeof current !== 'object' || Array.isArray(current)) return current;
            const keys = Object.keys(current as Record<string, unknown>);
            const wrapperKey = keys.find(k => /(?:Response|Result)$/i.test(k));
            if (!wrapperKey || keys.length === 0) return current;
            current = (current as Record<string, unknown>)[wrapperKey];
        }
        return current;
    }

    /** Depth-first search for the first value under `key` anywhere in the object tree. */
    private deepFindKey(body: unknown, key: string): unknown {
        if (!body || typeof body !== 'object') return undefined;
        if (Array.isArray(body)) {
            for (const item of body) {
                const found = this.deepFindKey(item, key);
                if (found !== undefined) return found;
            }
            return undefined;
        }
        const rec = body as Record<string, unknown>;
        if (key in rec) return rec[key];
        for (const value of Object.values(rec)) {
            const found = this.deepFindKey(value, key);
            if (found !== undefined) return found;
        }
        return undefined;
    }

    private firstArrayValue(body: Record<string, unknown>): unknown[] | null {
        for (const value of Object.values(body)) {
            if (Array.isArray(value)) return value;
            if (value && typeof value === 'object') {
                const nested = this.firstArrayValue(value as Record<string, unknown>);
                if (nested) return nested;
            }
        }
        return null;
    }

    private recordCount(rawBody: unknown): number {
        const unwrapped = this.unwrapSoapResult(rawBody);
        if (Array.isArray(unwrapped)) return unwrapped.length;
        if (unwrapped && typeof unwrapped === 'object') {
            const arr = this.firstArrayValue(unwrapped as Record<string, unknown>);
            if (arr) return arr.length;
            return Object.keys(unwrapped as Record<string, unknown>).length > 0 ? 1 : 0;
        }
        return 0;
    }

    private readNestedString(body: unknown, key: string): string | undefined {
        const v = this.deepFindKey(body, key);
        return v == null ? undefined : String(v);
    }

    /**
     * §4 identity: uses the declared PK when every component is present + non-empty, else a deterministic
     * content hash (so PK-less / partial-key records stay syncable + dedupable). Full-record pass-through:
     * Fields carries the complete source record (with the synthetic id stamped into a single empty PK).
     */
    private buildExternalRecord(
        raw: Record<string, unknown>,
        objectType: string,
        pkFieldNames: string[]
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

    private primaryKeyFieldNames(fields: MJIntegrationObjectFieldEntity[]): string[] {
        const pk = fields.filter(f => f.IsPrimaryKey).sort((a, b) => a.Sequence - b.Sequence).map(f => f.Name);
        return pk.length > 0 ? pk : ['id'];
    }

    private extractMutationId(body: unknown, obj: MJIntegrationObjectEntity): string | undefined {
        const result = this.unwrapSoapResult(body);
        // SaveResult.id is the documented create-id location; also try the object's PK field name.
        const fromId = this.readNestedString(result, 'id') ?? this.readNestedString(result, 'ID');
        if (fromId) return fromId;
        const fields = this.GetCachedFields(obj.ID);
        const pkName = this.primaryKeyFieldNames(fields)[0];
        return pkName ? this.readNestedString(result, pkName) : undefined;
    }

    private buildCRUDError(err: unknown, operation: string, objectName: string): CRUDResult {
        const message = err instanceof Error ? err.message : String(err);
        return { Success: false, ErrorMessage: `${operation} failed for ${objectName}: ${message}`, StatusCode: 500 };
    }

    // ── IO & CI Configuration JSON readers ────────────────────────────

    private readIOConfig(obj: MJIntegrationObjectEntity): Record<string, unknown> {
        if (!obj.Configuration) return {};
        try {
            const parsed = JSON.parse(obj.Configuration) as unknown;
            return parsed && typeof parsed === 'object' && !Array.isArray(parsed) ? parsed as Record<string, unknown> : {};
        } catch {
            return {};
        }
    }

    private readConfigString(cfg: Record<string, unknown>, key: string): string | null {
        const v = cfg[key];
        return typeof v === 'string' && v.trim().length > 0 ? v.trim() : null;
    }

    private readMigrationPacing(companyIntegration: MJCompanyIntegrationEntity): MagnetMailMigrationPacing | null {
        if (!companyIntegration.Configuration) return null;
        try {
            const parsed = JSON.parse(companyIntegration.Configuration) as Record<string, unknown>;
            const raw = parsed.migrationPacing;
            if (!raw || typeof raw !== 'object') return null;
            const p = raw as Record<string, unknown>;
            return {
                tokensPerSec: typeof p.tokensPerSec === 'number' ? p.tokensPerSec : undefined,
                burst: typeof p.burst === 'number' ? p.burst : undefined,
                maxConcurrency: typeof p.maxConcurrency === 'number' ? p.maxConcurrency : undefined,
                minDelayBetweenRequestsMs: typeof p.minDelayBetweenRequestsMs === 'number' ? p.minDelayBetweenRequestsMs : undefined,
                maxRequestsPerRun: typeof p.maxRequestsPerRun === 'number' ? p.maxRequestsPerRun : undefined,
                maxWindowsPerRun: typeof p.maxWindowsPerRun === 'number' ? p.maxWindowsPerRun : undefined,
                checkpointPerWindow: p.checkpointPerWindow === true || p.checkpointPerWindow === 'true',
            };
        } catch {
            return null;
        }
    }

    private resolveDateWindowConfig(
        companyIntegration: MJCompanyIntegrationEntity,
        obj: MJIntegrationObjectEntity,
        ioCfg: Record<string, unknown>,
        listOp: string
    ): MagnetMailDateWindowConfig | null {
        const ioWin = (ioCfg.dateWindowing && typeof ioCfg.dateWindowing === 'object')
            ? (ioCfg.dateWindowing as Record<string, unknown>)
            : null;
        let ciWin: Record<string, unknown> | null = null;
        let globalStartDate: string | undefined;
        let globalWindowDays: number | undefined;

        if (companyIntegration.Configuration) {
            try {
                const parsed = JSON.parse(companyIntegration.Configuration) as Record<string, unknown>;
                if (typeof parsed.startDate === 'string') globalStartDate = parsed.startDate;
                if (typeof parsed.windowDays === 'number') globalWindowDays = parsed.windowDays;
                const dw = parsed.dateWindowing;
                if (dw === true) {
                    ciWin = {};
                } else if (dw && typeof dw === 'object') {
                    const dwRec = dw as Record<string, unknown>;
                    const perObj = dwRec[obj.Name] ?? dwRec[listOp];
                    if (perObj === true) ciWin = {};
                    else if (perObj && typeof perObj === 'object') ciWin = perObj as Record<string, unknown>;
                    else if (dwRec.enabled === true) ciWin = dwRec;
                }
            } catch {
                /* ignore malformed JSON */
            }
        }

        const ioEnabled = ioWin != null && ioWin.enabled === true;
        if (!ciWin && !ioEnabled) return null;

        const merged: Record<string, unknown> = { ...(ioWin ?? {}), ...(ciWin ?? {}) };
        return {
            startDate: typeof merged.startDate === 'string' ? merged.startDate : globalStartDate,
            windowDays: typeof merged.windowDays === 'number' ? merged.windowDays : globalWindowDays,
            lookbackDays: typeof merged.lookbackDays === 'number' ? merged.lookbackDays : undefined,
            fromParam: typeof merged.fromParam === 'string' ? merged.fromParam : undefined,
            toParam: typeof merged.toParam === 'string' ? merged.toParam : undefined,
            capThreshold: typeof merged.capThreshold === 'number' ? merged.capThreshold : undefined,
        };
    }

    // ── XML utils ─────────────────────────────────────────────────────

    private headersToObject(headers: Headers): Record<string, string> {
        const out: Record<string, string> = {};
        headers.forEach((value, key) => { out[key.toLowerCase()] = value; });
        return out;
    }

    private escapeXml(value: string): string {
        return value
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&apos;');
    }

    private decodeXml(value: string): string {
        return value
            .replace(/&lt;/g, '<')
            .replace(/&gt;/g, '>')
            .replace(/&quot;/g, '"')
            .replace(/&apos;/g, "'")
            .replace(/&amp;/g, '&');
    }

    private escapeRegex(value: string): string {
        return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    }
}

/** Tree-shaking prevention — import and call from the package entry point. */
export function LoadMagnetMailConnector(): void { /* no-op */ }
