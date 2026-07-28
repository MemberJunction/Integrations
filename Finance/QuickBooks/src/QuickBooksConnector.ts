import { RegisterClass } from '@memberjunction/global';
import { Metadata, type IMetadataProvider, type UserInfo } from '@memberjunction/core';
import type {
    MJCompanyIntegrationEntity,
    MJCredentialEntity,
    MJIntegrationObjectEntity,
    MJIntegrationObjectFieldEntity,
} from '@memberjunction/core-entities';
import { IntegrationEngineBase } from '@memberjunction/integration-engine-base';
import {
    BaseIntegrationConnector,
    BaseRESTIntegrationConnector,
    OAuth2TokenManager,
    ClassifyError,
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
    type UpdateRecordContext,
    type DeleteRecordContext,
    type GetRecordContext,
    type CRUDResult,
    type ExternalRecord,
    type SourceSchemaInfo,
    type RateLimitPolicy,
} from '@memberjunction/integration-engine';
import { mergeDeclaredWithSampledFields } from '@memberjunction/connector-schema-merge';

// ─── Design note ─────────────────────────────────────────────────────────
//
// QuickBooks Online Accounting API v3 connector — PURE MECHANISM. The object/field catalog is NOT baked
// here; it lives in the Declared metadata (metadata/integrations/quickbooks/.quickbooks.integration.json),
// seeded from QBO's credential-free OpenAPI/XSD + published docs. DiscoverObjects / DiscoverFields are
// INHERITED from BaseRESTIntegrationConnector (cache-driven over the persisted Declared metadata) — there
// is NO hardcoded object list, NO field catalog, and NO baked PK/FK/required/readonly/unique constants in
// this file. Vendor-wide facts (hosts, minorversion, token endpoint, query/pagination mechanism, rate
// policy) are read at runtime from Integration.Configuration; well-known QBO published values are used only
// as documented fallbacks when a Configuration key is absent (never client/tenant constants).
//
// QBO is genuinely idiosyncratic vs a flat REST vendor, so FetchChanges / GetRecord / UpdateRecord /
// DeleteRecord are OVERRIDDEN (see each method for why):
//  - Reads ride a SQL-like /query DOOR: `GET /v3/company/{realmId}/query?query=<SELECT ...>` where the
//    STARTPOSITION/MAXRESULTS pagination tokens and the `WHERE MetaData.LastUpdatedTime > '<wm>'` watermark
//    live INSIDE the query text (not URL params). Records come back under `QueryResponse.<Entity>`.
//  - Incremental DELETIONS are surfaced ONLY by the Change-Data-Capture door (`GET /cdc`), never by /query.
//  - CompanyInfo / Preferences are singleton read-only resources at `/{entity}/{realmId}` (no query door).
//  - Writes: create/update are a full-object POST to `/{entity}` (id + SyncToken in the BODY, no id in the
//    path). Update carries `sparse:true` for partial updates + the current SyncToken (optimistic
//    concurrency; a stale token is a CONFLICT that is classified, not blind-retried). There is no hard
//    DELETE verb for name-list entities — those DEACTIVATE via `Active=false`; only transaction entities
//    hard-delete via `POST /{entity}?operation=delete`.
//  - Auth: OAuth2 authorization-code refresh (crypto-free, via the shared OAuth2TokenManager). Intuit
//    ROTATES the refresh token on every exchange, so the newest refresh token is PERSISTED back to its
//    source (Credential.Values or CompanyIntegration) — a non-persisting connector authenticates once then
//    dies once Intuit invalidates the superseded token.

// ─── Types ─────────────────────────────────────────────────────────────────

/** Resolved OAuth2 + tenant credentials for one QBO connection. */
interface QuickBooksCredentials {
    ClientId?: string;
    ClientSecret?: string;
    /** The current (rotating) refresh token. */
    RefreshToken?: string;
    /** QuickBooks Company/Realm ID — the tenant selector in every API path. */
    RealmId?: string;
    /** 'production' | 'sandbox' — selects the API host. */
    Environment: 'production' | 'sandbox';
    /** Where the refresh token was loaded from, so a rotated value is written back to the same place. */
    RefreshTokenSource: 'credential' | 'companyIntegration' | 'none';
}

/** Auth context threaded through BuildHeaders / MakeHTTPRequest / GetBaseURL for a run. */
interface QuickBooksAuthContext extends RESTAuthContext {
    /** Bearer access token. */
    Token: string;
    /** Tenant realm id. */
    RealmId: string;
    /** Fully-resolved company base URL, e.g. `https://quickbooks.api.intuit.com/v3/company/{realmId}`. */
    CompanyBaseURL: string;
}

/** Vendor-wide config read from Integration.Configuration (published QBO facts; NOT tenant-specific). */
interface QuickBooksVendorConfig {
    hosts: { production: string; sandbox: string };
    companyPathTemplate: string;
    minorVersion: number;
    tokenEndpoint: string;
    scope: string;
    recordsPath: string;
    correlationHeader: string;
    perMinuteLimit: number;
    concurrentLimit: number;
}

/** Per-object config read from IntegrationObject.Configuration. */
interface QuickBooksObjectConfig {
    /** The QBO entity name for the SQL query / path segment (e.g. `Invoice`). */
    QueryEntity: string;
    /** 'transaction' | 'namelist' | 'read-only' — drives delete-vs-deactivate + read shape. */
    EntityClass: 'transaction' | 'namelist' | 'read-only';
    /** Whether the CDC door surfaces deletions for this entity. */
    CdcEligible: boolean;
    /** 1-based STARTPOSITION base (default 1). */
    SkipBase: number;
}

/** QBO's JSON Fault envelope (lowercased keys relative to the XSD PascalCase). */
interface QuickBooksFaultError {
    message?: string;
    detail?: string;
    code?: string;
    element?: string;
}

// ─── Constants (published QBO facts used ONLY as Configuration fallbacks; no tenant data) ──

const DEFAULT_HOST_PRODUCTION = 'https://quickbooks.api.intuit.com';
const DEFAULT_HOST_SANDBOX = 'https://sandbox-quickbooks.api.intuit.com';
const DEFAULT_COMPANY_PATH_TEMPLATE = 'v3/company/{realmId}';
/** Current QBO minor-version floor (v1–74 deprecated Aug 2025; the server treats anything lower as 75). */
const DEFAULT_MINOR_VERSION = 75;
const DEFAULT_TOKEN_ENDPOINT = 'https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer';
const DEFAULT_SCOPE = 'com.intuit.quickbooks.accounting';
const DEFAULT_RECORDS_PATH = 'QueryResponse';
const DEFAULT_CORRELATION_HEADER = 'intuit_tid';
const DEFAULT_PER_MINUTE_LIMIT = 500;
const DEFAULT_CONCURRENT_LIMIT = 10;

/** QBO caps a single /query at 1000 rows. */
const MAX_QUERY_RESULTS = 1000;
/** Fallback page size when the engine passes no BatchSize. */
const DEFAULT_PAGE_SIZE = 200;
/** Transient-status backoff retries inside the transport. */
const MAX_TRANSIENT_RETRIES = 5;

// ─── QuickBooksConnector ─────────────────────────────────────────────────

/**
 * QuickBooks Online Accounting API (v3) connector.
 *
 * Extends BaseRESTIntegrationConnector (REST/JSON over HTTP). Discovery (DiscoverObjects/DiscoverFields)
 * and generic create are inherited; this class supplies the QBO-specific protocol surface: OAuth2 refresh
 * with rotating-refresh-token persistence, the SQL-like /query read door with in-query pagination +
 * watermark, CDC-based deletion detection, singleton reads, SyncToken-guarded full-object updates, and
 * delete-vs-deactivate routing by entity class.
 *
 * DUAL registration: the TS class symbol `QuickBooksConnector` keeps the sandbox verification ladder green;
 * the package-name key `@memberjunction/connector-quickbooks` is what the Integrations repo's
 * validate-invariants requires as an @RegisterClass key exported by the package's own src.
 */
@RegisterClass(BaseIntegrationConnector, 'QuickBooksConnector')
@RegisterClass(BaseIntegrationConnector, '@memberjunction/connector-quickbooks')
export class QuickBooksConnector extends BaseRESTIntegrationConnector {

    /** One token manager per connector instance (crypto-free OAuth2 round-trip + in-memory access-token cache). */
    private readonly tokenManager = new OAuth2TokenManager();
    /** Cached auth for the lifetime of a single run, keyed by realm so a connection change re-authenticates. */
    private cachedAuth: QuickBooksAuthContext | null = null;
    private cachedAuthRealm: string | null = null;
    /** Last-resolved vendor config, so the credential-free rate/concurrency getters can honor Configuration. */
    private lastVendorConfig: QuickBooksVendorConfig | null = null;

    // ── Identity (T1 three-way invariant) ────────────────────────────

    /** Verbatim `MJ: Integrations.Name`. The T1 three-way name check compares this === metadata display Name. */
    public override get IntegrationName(): string {
        return 'QuickBooks';
    }

    // ── Capability getters (agree with the per-op metadata columns) ──
    // TRUE because SOME IOs carry the corresponding write columns; the generic/overridden per-op paths
    // gate each call on the IO's OWN Create/Update/Delete columns + entity class, so an object whose
    // metadata says "no" is never written blindly.

    public override get SupportsCreate(): boolean { return true; }
    public override get SupportsUpdate(): boolean { return true; }
    public override get SupportsDelete(): boolean { return true; }

    /**
     * Discovery is NON-authoritative: QBO exposes no describe-all/complete-gamut endpoint. DiscoverObjects /
     * IntrospectSchema are cache-driven (re-read persisted Declared metadata), and per-realm custom fields
     * flow through the sample-union enrichment below + the framework's runtime custom-column capture. Absence
     * on a refresh proves nothing → never deactivate.
     */
    public override get DiscoveryIsAuthoritative(): boolean {
        return false;
    }

    // ── Sync-efficiency hooks (§7/§10 — populated from evidenced Configuration facts) ──

    /** QBO: 500 requests/min/realm → ~8.3 tokens/sec sustained; burst capped by the 10-concurrent limit. */
    public override get RateLimitPolicy(): RateLimitPolicy | null {
        const perMin = this.lastVendorConfig?.perMinuteLimit ?? DEFAULT_PER_MINUTE_LIMIT;
        const concurrent = this.lastVendorConfig?.concurrentLimit ?? DEFAULT_CONCURRENT_LIMIT;
        return { TokensPerSec: perMin / 60, Burst: concurrent };
    }

    /** QBO documents a 10-concurrent-request ceiling per realm. */
    public override get MaxConcurrencyHint(): number | null {
        return this.lastVendorConfig?.concurrentLimit ?? DEFAULT_CONCURRENT_LIMIT;
    }

    /** Parse QBO's Retry-After (seconds) off an exhausted-429 error into ms for the engine's precise backoff. */
    public override ExtractRetryAfterMs(error: unknown): number | undefined {
        if (error instanceof QuickBooksRateLimitError) return error.RetryAfterMs;
        return undefined;
    }

    // ── Sample-union field enrichment (MJ connector standard) ─────────

    /**
     * Sample-union enrichment: Declared metadata is spec-derived and misses a realm's per-record CustomField
     * columns. After the base cache-driven introspection (which sets `ExternalName = obj.Name`, i.e. the QBO
     * entity name), we sample each object's live read shape via `DiscoverFieldsViaFetch` and UNION it into the
     * declared set with `mergeDeclaredWithSampledFields` (never-shrink, declared-wins). Best-effort + parallel;
     * a sample failure leaves the declared set untouched. We override IntrospectSchema (NOT DiscoverFields —
     * that would recurse into DiscoverFieldsViaFetch's own fallback). Connector-agnostic.
     */
    public override async IntrospectSchema(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<SourceSchemaInfo> {
        const info = await super.IntrospectSchema(companyIntegration, contextUser);
        await Promise.all(
            info.Objects.map(async (obj) => {
                try {
                    const sampled = await this.DiscoverFieldsViaFetch(companyIntegration, obj.ExternalName, contextUser);
                    obj.Fields = mergeDeclaredWithSampledFields(obj.Fields, sampled);
                } catch {
                    /* best-effort — a sample failure leaves the declared fields as-is */
                }
            }),
        );
        return info;
    }

    // ── TestConnection ────────────────────────────────────────────────

    /** Reads the singleton CompanyInfo resource to verify connectivity + auth (read-only, non-mutating). */
    public async TestConnection(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<ConnectionTestResult> {
        try {
            const auth = await this.Authenticate(companyIntegration, contextUser);
            const vendorCfg = this.resolveVendorConfig(companyIntegration.IntegrationID);
            const url = `${auth.CompanyBaseURL}/companyinfo/${encodeURIComponent(auth.RealmId)}?minorversion=${vendorCfg.minorVersion}`;
            const response = await this.MakeHTTPRequest(auth, url, 'GET', this.BuildHeaders(auth));
            if (response.Status >= 200 && response.Status < 300) {
                const name = this.readCompanyName(response.Body);
                return {
                    Success: true,
                    Message: `Connected to QuickBooks Online (realm ${auth.RealmId})${name ? `: ${name}` : ''}.`,
                    ServerVersion: `QuickBooks Online Accounting API v3 (minorversion ${vendorCfg.minorVersion})`,
                };
            }
            if (response.Status === 401 || response.Status === 403) {
                return { Success: false, Message: `QuickBooks authentication failed (HTTP ${response.Status}). ${this.ExtractErrorMessage(response) ?? ''}`.trim() };
            }
            return { Success: false, Message: `QuickBooks CompanyInfo probe returned HTTP ${response.Status}. ${this.ExtractErrorMessage(response) ?? ''}`.trim() };
        } catch (err: unknown) {
            return { Success: false, Message: `Connection failed: ${err instanceof Error ? err.message : String(err)}` };
        }
    }

    // ── FetchChanges (OVERRIDE — QBO /query door + CDC deletions + singleton reads) ──

    /**
     * OVERRIDE (idiosyncratic): QBO reads ride a SQL-like /query door, not a flat REST collection, so the
     * base's flat/offset URL machinery does not apply. This fetches ONE page (bounded by BatchSize, capped at
     * QBO's 1000/query) and returns HasMore + NextOffset so the engine loops. On an incremental first page it
     * also emits CDC deletion tombstones (the only documented QBO deletion source). Singleton read-only
     * objects (CompanyInfo/Preferences) take the single-GET path.
     */
    public override async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
        const obj = this.GetCachedObject(ctx.CompanyIntegration.IntegrationID, ctx.ObjectName);
        const fields = this.GetCachedFields(obj.ID);
        const objCfg = this.parseObjectConfig(obj);
        const auth = await this.Authenticate(ctx.CompanyIntegration, ctx.ContextUser);
        const vendorCfg = this.resolveVendorConfig(ctx.CompanyIntegration.IntegrationID);

        if (objCfg.EntityClass === 'read-only') {
            return this.fetchSingleton(auth, vendorCfg, obj, fields, objCfg);
        }
        return this.fetchQueryPage(auth, vendorCfg, obj, fields, objCfg, ctx);
    }

    // ── GetRecord (OVERRIDE — QBO `/{entity}/{id}` addressing + entity-name-nested unwrap) ──

    /** OVERRIDE: single-record GET at `/{entity}/{id}?minorversion`; the record is nested under `<Entity>`. */
    public override async GetRecord(ctx: GetRecordContext): Promise<ExternalRecord | null> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const contextUser = ctx.ContextUser as UserInfo;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        const fields = this.GetCachedFields(obj.ID);
        const objCfg = this.parseObjectConfig(obj);
        const auth = await this.Authenticate(ci, contextUser);
        const vendorCfg = this.resolveVendorConfig(ci.IntegrationID);
        const url = `${auth.CompanyBaseURL}/${objCfg.QueryEntity.toLowerCase()}/${encodeURIComponent(ctx.ExternalID)}?minorversion=${vendorCfg.minorVersion}`;
        const response = await this.MakeHTTPRequest(auth, url, 'GET', this.BuildHeaders(auth));
        if (response.Status === 404) return null;
        if (response.Status < 200 || response.Status >= 300) {
            throw new Error(`QuickBooks GetRecord "${ctx.ObjectName}"/${ctx.ExternalID} failed: HTTP ${response.Status} ${this.ExtractErrorMessage(response) ?? ''}`.trim());
        }
        const raw = this.readSingleEntity(response.Body, objCfg.QueryEntity);
        if (!raw) return null;
        return this.buildExternalRecord(raw, obj, fields, objCfg);
    }

    // ── UpdateRecord (OVERRIDE — full-object POST + SyncToken + sparse) ──

    /**
     * OVERRIDE (idiosyncratic): QBO update is a full-object POST to `/{entity}` (no id in path) carrying the
     * record's `Id`, current `SyncToken`, and `sparse:true` (so only supplied fields change). SyncToken is
     * fetch-or-carry: used from the caller's attributes when present, else read live via GetRecord. A stale
     * SyncToken (optimistic-concurrency conflict) is CLASSIFIED and returned as a failure — never blind-retried.
     */
    public override async UpdateRecord(ctx: UpdateRecordContext): Promise<CRUDResult> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const contextUser = ctx.ContextUser as UserInfo;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        if (!obj.SupportsUpdate || !obj.UpdateAPIPath) {
            return { Success: false, StatusCode: 0, ErrorMessage: `UpdateRecord not supported for "${ctx.ObjectName}" (metadata declares no update path).` };
        }
        const objCfg = this.parseObjectConfig(obj);
        const auth = await this.Authenticate(ci, contextUser);
        const vendorCfg = this.resolveVendorConfig(ci.IntegrationID);
        const syncToken = await this.resolveSyncToken(ctx.Attributes, obj, ci, contextUser, ctx.ExternalID);
        if (syncToken == null) {
            return { Success: false, StatusCode: 0, ErrorMessage: `QuickBooks update of "${ctx.ObjectName}"/${ctx.ExternalID}: could not resolve current SyncToken (required for optimistic concurrency).` };
        }
        const body: Record<string, unknown> = { ...ctx.Attributes, Id: ctx.ExternalID, SyncToken: syncToken, sparse: true };
        const url = `${auth.CompanyBaseURL}/${objCfg.QueryEntity.toLowerCase()}?minorversion=${vendorCfg.minorVersion}`;
        const response = await this.MakeHTTPRequest(auth, url, 'POST', this.BuildHeaders(auth), body);
        return this.buildWriteResult(response, ctx.ExternalID, 'update', ctx.ObjectName);
    }

    // ── DeleteRecord (OVERRIDE — hard-delete transactions vs deactivate name-lists) ──

    /**
     * OVERRIDE (idiosyncratic): QBO has NO uniform delete verb. Transaction entities with SupportsDelete
     * hard-delete via `POST /{entity}?operation=delete` ({Id, SyncToken}); name-list entities have no hard
     * delete and instead DEACTIVATE via a sparse update `Active=false` (SyncToken required). Anything else
     * (read-only, or a transaction with delete intentionally unsupported) fails loudly.
     */
    public override async DeleteRecord(ctx: DeleteRecordContext): Promise<CRUDResult> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const contextUser = ctx.ContextUser as UserInfo;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        const objCfg = this.parseObjectConfig(obj);

        // Route FIRST — fail loudly for entity classes that support neither hard-delete nor deactivate,
        // before spending a SyncToken read.
        const hardDelete = objCfg.EntityClass === 'transaction' && obj.SupportsDelete;
        const deactivate = objCfg.EntityClass === 'namelist';
        if (!hardDelete && !deactivate) {
            return { Success: false, StatusCode: 0, ErrorMessage: `QuickBooks "${ctx.ObjectName}" does not support delete or deactivate (entity class: ${objCfg.EntityClass}${objCfg.EntityClass === 'transaction' ? ', delete not enabled' : ''}).` };
        }

        const auth = await this.Authenticate(ci, contextUser);
        const vendorCfg = this.resolveVendorConfig(ci.IntegrationID);
        const syncToken = await this.resolveSyncToken({}, obj, ci, contextUser, ctx.ExternalID);
        if (syncToken == null) {
            return { Success: false, StatusCode: 0, ErrorMessage: `QuickBooks delete of "${ctx.ObjectName}"/${ctx.ExternalID}: could not resolve current SyncToken.` };
        }

        if (hardDelete) {
            const url = `${auth.CompanyBaseURL}/${objCfg.QueryEntity.toLowerCase()}?operation=delete&minorversion=${vendorCfg.minorVersion}`;
            const body = { Id: ctx.ExternalID, SyncToken: syncToken };
            const response = await this.MakeHTTPRequest(auth, url, 'POST', this.BuildHeaders(auth), body);
            return this.buildWriteResult(response, ctx.ExternalID, 'delete', ctx.ObjectName);
        }

        // Name-list "delete" is a soft deactivate: sparse update Active=false.
        const url = `${auth.CompanyBaseURL}/${objCfg.QueryEntity.toLowerCase()}?minorversion=${vendorCfg.minorVersion}`;
        const body = { Id: ctx.ExternalID, SyncToken: syncToken, sparse: true, Active: false };
        const response = await this.MakeHTTPRequest(auth, url, 'POST', this.BuildHeaders(auth), body);
        return this.buildWriteResult(response, ctx.ExternalID, 'deactivate', ctx.ObjectName);
    }

    // ── Abstract REST hooks ───────────────────────────────────────────

    /** Resolves credentials, mints/refreshes the access token via the shared manager, persists a rotated refresh token. */
    protected override async Authenticate(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<QuickBooksAuthContext> {
        const creds = await this.loadCredentials(companyIntegration, contextUser);
        if (!creds.RealmId) {
            throw new Error('QuickBooks connector: no realmId (QuickBooks Company ID) on the Credential or CompanyIntegration.');
        }
        if (this.cachedAuth && this.cachedAuthRealm === creds.RealmId) return this.cachedAuth;
        if (!creds.ClientId || !creds.ClientSecret) {
            throw new Error('QuickBooks connector: OAuth2 clientId/clientSecret not found on the Credential or CompanyIntegration.');
        }
        if (!creds.RefreshToken) {
            throw new Error('QuickBooks connector: no OAuth2 refresh token found — the authorization-code flow must be completed and its refresh token stored first.');
        }
        const vendorCfg = this.resolveVendorConfig(companyIntegration.IntegrationID);
        const token = await this.tokenManager.GetAccessToken(
            {
                TokenURL: vendorCfg.tokenEndpoint,
                ClientId: creds.ClientId,
                ClientSecret: creds.ClientSecret,
                RefreshToken: creds.RefreshToken,
                Scopes: vendorCfg.scope,
                UseBasicAuth: true,
            },
            'refresh_token',
        );
        await this.persistRotatedRefreshToken(companyIntegration, contextUser, creds, token.RefreshToken, token.AccessToken, token.ExpiresAt);

        this.cachedAuth = {
            Token: token.AccessToken,
            RealmId: creds.RealmId,
            CompanyBaseURL: this.buildCompanyBaseURL(vendorCfg, creds),
            ExpiresAt: new Date(token.ExpiresAt),
        };
        this.cachedAuthRealm = creds.RealmId;
        return this.cachedAuth;
    }

    /** Bearer auth + explicit JSON Accept (QBO defaults to XML when Accept is absent). */
    protected override BuildHeaders(auth: RESTAuthContext): Record<string, string> {
        return {
            'Authorization': `Bearer ${(auth as QuickBooksAuthContext).Token}`,
            'Accept': 'application/json',
            'Content-Type': 'application/json',
        };
    }

    /** HTTP transport (fetch) with bounded 429/503 backoff honoring Retry-After. Test subclasses override this. */
    protected override async MakeHTTPRequest(
        _auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown,
    ): Promise<RESTResponse> {
        let lastTid: string | undefined;
        for (let attempt = 0; attempt <= MAX_TRANSIENT_RETRIES; attempt++) {
            const response = await fetch(url, {
                method,
                headers,
                body: body !== undefined && body !== null ? JSON.stringify(body) : undefined,
            });
            const respHeaders: Record<string, string> = {};
            response.headers.forEach((v, k) => { respHeaders[k.toLowerCase()] = v; });
            lastTid = respHeaders[DEFAULT_CORRELATION_HEADER];
            if ((response.status === 429 || response.status === 503) && attempt < MAX_TRANSIENT_RETRIES) {
                await this.sleep(this.computeBackoffMs(respHeaders, attempt));
                continue;
            }
            if (response.status === 429) {
                throw new QuickBooksRateLimitError(`QuickBooks rate limit (HTTP 429) after ${MAX_TRANSIENT_RETRIES} retries: ${method} ${url}`, this.parseRetryAfterMs(respHeaders), lastTid);
            }
            const text = await response.text();
            let parsed: unknown = null;
            if (text.length > 0) {
                try { parsed = JSON.parse(text); } catch { parsed = text; }
            }
            return { Status: response.status, Body: parsed, Headers: respHeaders };
        }
        throw new QuickBooksRateLimitError(`QuickBooks request exhausted retries: ${method} ${url}`, undefined, lastTid);
    }

    /**
     * Strips the QBO envelope to a record array. A /query response nests records under
     * `QueryResponse.<Entity>`; a single-record response nests one object under `<Entity>`. `responseDataKey`
     * carries the entity name. Falls back to the first array found under QueryResponse.
     */
    protected override NormalizeResponse(rawBody: unknown, responseDataKey: string | null): Record<string, unknown>[] {
        if (rawBody == null || typeof rawBody !== 'object') return [];
        const body = rawBody as Record<string, unknown>;
        const queryResponse = body[DEFAULT_RECORDS_PATH];
        if (queryResponse && typeof queryResponse === 'object') {
            const qr = queryResponse as Record<string, unknown>;
            if (responseDataKey && Array.isArray(qr[responseDataKey])) return qr[responseDataKey] as Record<string, unknown>[];
            for (const v of Object.values(qr)) {
                if (Array.isArray(v)) return v as Record<string, unknown>[];
            }
            return [];
        }
        if (responseDataKey) {
            const v = body[responseDataKey];
            if (Array.isArray(v)) return v as Record<string, unknown>[];
            if (v && typeof v === 'object') return [v as Record<string, unknown>];
        }
        return [];
    }

    /** Offset pagination continuation from the QueryResponse totalCount, else a full-page heuristic. */
    protected override ExtractPaginationInfo(
        rawBody: unknown,
        paginationType: PaginationType,
        _currentPage: number,
        currentOffset: number,
        pageSize: number,
    ): PaginationState {
        if (paginationType !== 'Offset') return { HasMore: false };
        const qr = this.readQueryResponse(rawBody);
        const totalCount = typeof qr?.totalCount === 'number' ? qr.totalCount : undefined;
        const fetched = this.countQueryRecords(qr);
        const nextOffset = currentOffset + fetched;
        const hasMore = totalCount != null ? nextOffset < totalCount : fetched >= pageSize;
        return { HasMore: hasMore, NextOffset: hasMore ? nextOffset : undefined, TotalRecords: totalCount };
    }

    /** Company-scoped base URL, e.g. `https://quickbooks.api.intuit.com/v3/company/{realmId}`. */
    protected override GetBaseURL(_companyIntegration: MJCompanyIntegrationEntity, auth: RESTAuthContext): string {
        return (auth as QuickBooksAuthContext).CompanyBaseURL;
    }

    /** OVERRIDE: a created record's Id is nested under the entity name in the QBO create response. */
    protected override ExtractIDFromResponse(response: RESTResponse, _idLocation: string | null): string | undefined {
        if (!response.Body || typeof response.Body !== 'object') return undefined;
        const body = response.Body as Record<string, unknown>;
        for (const v of Object.values(body)) {
            if (v && typeof v === 'object' && !Array.isArray(v)) {
                const id = (v as Record<string, unknown>).Id;
                if (typeof id === 'string' || typeof id === 'number') return String(id);
            }
        }
        return undefined;
    }

    /** OVERRIDE: QBO Fault envelope (`{ fault: { error: [{ message, detail, code }] } }`, lowercased JSON keys). */
    protected override ExtractErrorMessage(response: RESTResponse): string | undefined {
        const errs = this.readFaultErrors(response.Body);
        if (errs.length === 0) return undefined;
        return errs.map(e => `[${e.code ?? '?'}] ${e.message ?? ''}${e.detail ? ` — ${e.detail}` : ''}`.trim()).join('; ');
    }

    // ── Read helpers ──────────────────────────────────────────────────

    /** Fetches one /query page with in-query STARTPOSITION/MAXRESULTS + optional watermark; emits CDC deletes. */
    private async fetchQueryPage(
        auth: QuickBooksAuthContext,
        vendorCfg: QuickBooksVendorConfig,
        obj: MJIntegrationObjectEntity,
        fields: MJIntegrationObjectFieldEntity[],
        objCfg: QuickBooksObjectConfig,
        ctx: FetchContext,
    ): Promise<FetchBatchResult> {
        const offset = ctx.CurrentOffset ?? 0;
        const startPosition = offset + objCfg.SkipBase;
        const maxResults = Math.min(ctx.BatchSize && ctx.BatchSize > 0 ? ctx.BatchSize : DEFAULT_PAGE_SIZE, MAX_QUERY_RESULTS);
        const incremental = obj.SupportsIncrementalSync && !!ctx.WatermarkValue && !!obj.IncrementalWatermarkField;

        const queryText = this.buildQueryText(objCfg.QueryEntity, incremental ? ctx.WatermarkValue : null, obj.IncrementalWatermarkField, startPosition, maxResults);
        const url = `${auth.CompanyBaseURL}/query?query=${encodeURIComponent(queryText)}&minorversion=${vendorCfg.minorVersion}`;
        const response = await this.MakeHTTPRequest(auth, url, 'GET', this.BuildHeaders(auth));
        if (response.Status < 200 || response.Status >= 300) {
            throw new Error(`QuickBooks query "${objCfg.QueryEntity}" failed: HTTP ${response.Status} ${this.ExtractErrorMessage(response) ?? ''}`.trim());
        }

        const raw = this.NormalizeResponse(response.Body, objCfg.QueryEntity);
        const records = raw.map(r => this.buildExternalRecord(r, obj, fields, objCfg));

        const pagination = this.ExtractPaginationInfo(response.Body, 'Offset', 1, offset, maxResults);
        const warnings: FetchWarning[] = [];

        // CDC deletions (the only documented QBO deletion source) — once, on the incremental FIRST page.
        if (incremental && objCfg.CdcEligible && offset === 0) {
            try {
                const tombstones = await this.fetchCdcDeletions(auth, vendorCfg, objCfg, ctx.WatermarkValue as string, obj);
                for (const t of tombstones) records.push(t);
            } catch (e) {
                warnings.push({ Code: 'CDC_DELETIONS_UNAVAILABLE', Message: `CDC deletion probe for "${objCfg.QueryEntity}" failed: ${e instanceof Error ? e.message : String(e)}`, Data: { object: obj.Name } });
            }
        }

        const result: FetchBatchResult = {
            Records: records,
            HasMore: pagination.HasMore,
            NextOffset: pagination.NextOffset,
        };
        const newWatermark = this.maxWatermark(raw, obj.IncrementalWatermarkField);
        if (newWatermark) result.NewWatermarkValue = newWatermark;
        if (warnings.length > 0) result.Warnings = warnings;
        return result;
    }

    /** Single-GET read for QBO singleton resources (CompanyInfo/Preferences) at `/{entity}/{realmId}`. */
    private async fetchSingleton(
        auth: QuickBooksAuthContext,
        vendorCfg: QuickBooksVendorConfig,
        obj: MJIntegrationObjectEntity,
        fields: MJIntegrationObjectFieldEntity[],
        objCfg: QuickBooksObjectConfig,
    ): Promise<FetchBatchResult> {
        const url = `${auth.CompanyBaseURL}/${objCfg.QueryEntity.toLowerCase()}/${encodeURIComponent(auth.RealmId)}?minorversion=${vendorCfg.minorVersion}`;
        const response = await this.MakeHTTPRequest(auth, url, 'GET', this.BuildHeaders(auth));
        if (response.Status < 200 || response.Status >= 300) {
            throw new Error(`QuickBooks read "${objCfg.QueryEntity}" failed: HTTP ${response.Status} ${this.ExtractErrorMessage(response) ?? ''}`.trim());
        }
        const raw = this.readSingleEntity(response.Body, objCfg.QueryEntity);
        const records = raw ? [this.buildExternalRecord(raw, obj, fields, objCfg)] : [];
        return { Records: records, HasMore: false };
    }

    /** Fetches the CDC door and returns deletion tombstones for the object. */
    private async fetchCdcDeletions(
        auth: QuickBooksAuthContext,
        vendorCfg: QuickBooksVendorConfig,
        objCfg: QuickBooksObjectConfig,
        changedSince: string,
        obj: MJIntegrationObjectEntity,
    ): Promise<ExternalRecord[]> {
        const url = `${auth.CompanyBaseURL}/cdc?entities=${encodeURIComponent(objCfg.QueryEntity)}&changedSince=${encodeURIComponent(changedSince)}&minorversion=${vendorCfg.minorVersion}`;
        const response = await this.MakeHTTPRequest(auth, url, 'GET', this.BuildHeaders(auth));
        if (response.Status < 200 || response.Status >= 300) {
            throw new Error(`HTTP ${response.Status} ${this.ExtractErrorMessage(response) ?? ''}`.trim());
        }
        return this.parseCdcDeletions(response.Body, objCfg.QueryEntity, obj.Name);
    }

    /** Walks the CDCResponse envelope, extracting rows whose `status` is Deleted for the given entity. */
    private parseCdcDeletions(body: unknown, queryEntity: string, objectType: string): ExternalRecord[] {
        const out: ExternalRecord[] = [];
        if (!body || typeof body !== 'object') return out;
        const cdc = (body as Record<string, unknown>).CDCResponse;
        if (!Array.isArray(cdc)) return out;
        for (const block of cdc) {
            if (!block || typeof block !== 'object') continue;
            const qrs = (block as Record<string, unknown>).QueryResponse;
            if (!Array.isArray(qrs)) continue;
            for (const qr of qrs) {
                if (!qr || typeof qr !== 'object') continue;
                const arr = (qr as Record<string, unknown>)[queryEntity];
                if (!Array.isArray(arr)) continue;
                for (const item of arr) {
                    if (!item || typeof item !== 'object') continue;
                    const row = item as Record<string, unknown>;
                    const status = typeof row.status === 'string' ? row.status : (typeof row.Status === 'string' ? row.Status : '');
                    if (status.toLowerCase() !== 'deleted') continue;
                    const id = row.Id;
                    if (typeof id !== 'string' && typeof id !== 'number') continue;
                    out.push({ ExternalID: String(id), ObjectType: objectType, Fields: { ...row }, IsDeleted: true });
                }
            }
        }
        return out;
    }

    /**
     * Builds an ExternalRecord with the FULL source record in Fields (custom-column pass-through contract).
     * Mirrors the base ToExternalRecord identity/content-hash semantics: a fully-present PK → joined key;
     * a keyless/partial-key record → a deterministic content hash stamped into the single PK field so it is
     * still syncable + idempotent on re-sync. Never drops a source key.
     */
    private buildExternalRecord(
        raw: Record<string, unknown>,
        obj: MJIntegrationObjectEntity,
        fields: MJIntegrationObjectFieldEntity[],
        objCfg: QuickBooksObjectConfig,
    ): ExternalRecord {
        // applyTransformPreservingKeys runs TransformRecord then re-adds any dropped key → Fields stays FULL.
        const transformed = this.applyTransformPreservingKeys(raw, obj, fields);
        const declaredPk = this.primaryKeyFieldNames(fields);
        const pkNames = declaredPk.length > 0 ? declaredPk : ['Id']; // QBO universal PK
        const allPkPresent = pkNames.every(n => transformed[n] != null && serializeKeyValue(transformed[n]).length > 0);
        const joined = pkNames.map(n => serializeKeyValue(transformed[n])).join('|');
        const resolvedID = allPkPresent ? joined : computeContentHash(transformed);

        let fieldsOut = transformed;
        if (!allPkPresent && pkNames.length === 1 && (transformed[pkNames[0]] == null || serializeKeyValue(transformed[pkNames[0]]).length === 0)) {
            fieldsOut = { ...transformed, [pkNames[0]]: resolvedID };
        }
        const modifiedAt = this.readLastUpdated(raw, obj.IncrementalWatermarkField);
        void objCfg;
        return {
            ExternalID: resolvedID,
            ObjectType: obj.Name,
            Fields: fieldsOut,
            ...(modifiedAt ? { ModifiedAt: modifiedAt } : {}),
        };
    }

    // ── Write helpers ─────────────────────────────────────────────────

    /**
     * Resolves the current SyncToken for an update/delete: from the caller's attributes when present, else a
     * live GetRecord read. QBO's optimistic-concurrency requires the CURRENT token; a stale one is rejected
     * by the server (classified as a conflict at write time), so we prefer a freshly-read token when absent.
     */
    private async resolveSyncToken(
        attributes: Record<string, unknown>,
        obj: MJIntegrationObjectEntity,
        ci: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
        externalID?: string,
    ): Promise<string | null> {
        const carried = attributes.SyncToken;
        if (typeof carried === 'string' && carried.length > 0) return carried;
        if (typeof carried === 'number') return String(carried);
        const id = externalID ?? (typeof attributes.Id === 'string' ? attributes.Id : undefined);
        if (!id) return null;
        const current = await this.GetRecord({ CompanyIntegration: ci, ObjectName: obj.Name, ContextUser: contextUser, ExternalID: id });
        const token = current?.Fields?.SyncToken;
        if (typeof token === 'string' && token.length > 0) return token;
        if (typeof token === 'number') return String(token);
        return null;
    }

    /** Maps a QBO write response to a CRUDResult, classifying a stale-SyncToken conflict distinctly. */
    private buildWriteResult(response: RESTResponse, externalID: string, op: string, objectName: string): CRUDResult {
        if (response.Status >= 200 && response.Status < 300) {
            const returnedId = this.ExtractIDFromResponse(response, 'body') ?? externalID;
            return { Success: true, StatusCode: response.Status, ExternalID: returnedId };
        }
        const message = this.ExtractErrorMessage(response) ?? `HTTP ${response.Status} on ${op}`;
        if (this.isStaleTokenConflict(response)) {
            const severity = ClassifyError(new Error(message)).Severity;
            return {
                Success: false,
                StatusCode: response.Status,
                ErrorMessage: `QuickBooks ${op} of "${objectName}"/${externalID} conflict [${severity}] — stale SyncToken (optimistic concurrency). Re-read the record and retry with its current SyncToken. ${message}`.trim(),
            };
        }
        return { Success: false, StatusCode: response.Status, ErrorMessage: `QuickBooks ${op} of "${objectName}"/${externalID}: ${message}` };
    }

    /** True when the Fault carries QBO's stale-object-version code (5010) or an explicit stale-token message. */
    private isStaleTokenConflict(response: RESTResponse): boolean {
        const errs = this.readFaultErrors(response.Body);
        return errs.some(e => e.code === '5010' || (typeof e.message === 'string' && /stale|sync token|object version/i.test(e.message)));
    }

    // ── Credential resolution + rotating-refresh-token persistence ────

    /** Merges credentials from the linked Credential entity (secrets win) and CompanyIntegration fields/Configuration. */
    private async loadCredentials(companyIntegration: MJCompanyIntegrationEntity, contextUser: UserInfo): Promise<QuickBooksCredentials> {
        const fromCiConfig = companyIntegration.Configuration ? this.parseCredentialJson(companyIntegration.Configuration) : null;
        const fromCiColumns: Partial<QuickBooksCredentials> = {
            ClientId: companyIntegration.ClientID ?? undefined,
            ClientSecret: companyIntegration.ClientSecret ?? undefined,
            RefreshToken: companyIntegration.RefreshToken ?? undefined,
            RealmId: companyIntegration.ExternalSystemID ?? undefined,
        };
        let fromCred: Partial<QuickBooksCredentials> | null = null;
        if (companyIntegration.CredentialID) {
            fromCred = await this.loadFromCredential(companyIntegration.CredentialID, contextUser);
        }
        const merged: QuickBooksCredentials = {
            Environment: 'production',
            RefreshTokenSource: 'none',
            ...(fromCiConfig ?? {}),
            ...this.stripUndefined(fromCiColumns),
            ...this.stripUndefined(fromCred ?? {}),
        };
        // Determine where the refresh token actually came from (credential wins), so a rotation writes back there.
        if (fromCred?.RefreshToken) merged.RefreshTokenSource = 'credential';
        else if (fromCiColumns.RefreshToken || fromCiConfig?.RefreshToken) merged.RefreshTokenSource = 'companyIntegration';
        merged.Environment = this.normalizeEnvironment(merged.Environment);
        return merged;
    }

    /** Loads a Credential row and parses its Values JSON. */
    private async loadFromCredential(credentialID: string, contextUser: UserInfo, provider?: IMetadataProvider): Promise<Partial<QuickBooksCredentials> | null> {
        const md = provider ?? new Metadata();
        const credential = await md.GetEntityObject<MJCredentialEntity>('MJ: Credentials', contextUser);
        const loaded = await credential.Load(credentialID);
        if (!loaded || !credential.Values) return null;
        return this.parseCredentialJson(credential.Values);
    }

    /** Parses a QBO credential/config JSON blob, tolerant of key-casing variants. */
    private parseCredentialJson(json: string): Partial<QuickBooksCredentials> | null {
        let parsed: Record<string, unknown>;
        try { parsed = JSON.parse(json) as Record<string, unknown>; } catch { return null; }
        const env = this.firstString(parsed, ['Environment', 'environment', 'env']);
        return {
            ClientId: this.firstString(parsed, ['ClientId', 'clientId', 'client_id', 'ClientID']),
            ClientSecret: this.firstString(parsed, ['ClientSecret', 'clientSecret', 'client_secret']),
            RefreshToken: this.firstString(parsed, ['RefreshToken', 'refreshToken', 'refresh_token']),
            RealmId: this.firstString(parsed, ['RealmId', 'realmId', 'realm_id', 'RealmID', 'companyId', 'CompanyId']),
            ...(env ? { Environment: this.normalizeEnvironment(env) } : {}),
        };
    }

    /**
     * Persists the (rotated) refresh token back to its source ONLY when it changed. Intuit invalidates the
     * previous refresh token on every exchange, so a connector that fails to persist the new one authenticates
     * once and then dies on the next process. Also caches the fresh access token + expiry on the connection.
     */
    private async persistRotatedRefreshToken(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
        creds: QuickBooksCredentials,
        newRefreshToken: string | undefined,
        accessToken: string,
        expiresAt: number,
    ): Promise<void> {
        if (!newRefreshToken || newRefreshToken === creds.RefreshToken) {
            // No rotation: still refresh the cached access token on the connection (best-effort).
            await this.saveAccessTokenOnConnection(companyIntegration, accessToken, expiresAt);
            return;
        }
        if (creds.RefreshTokenSource === 'credential' && companyIntegration.CredentialID) {
            await this.saveRefreshTokenToCredential(companyIntegration.CredentialID, contextUser, newRefreshToken);
        } else {
            await this.saveRefreshTokenToConnection(companyIntegration, newRefreshToken);
        }
        await this.saveAccessTokenOnConnection(companyIntegration, accessToken, expiresAt);
    }

    /** Writes the rotated refresh token into the Credential.Values JSON (preserving the other keys). */
    private async saveRefreshTokenToCredential(credentialID: string, contextUser: UserInfo, newRefreshToken: string): Promise<void> {
        const md = new Metadata();
        const credential = await md.GetEntityObject<MJCredentialEntity>('MJ: Credentials', contextUser);
        if (!(await credential.Load(credentialID))) return;
        let values: Record<string, unknown> = {};
        try { values = credential.Values ? JSON.parse(credential.Values) as Record<string, unknown> : {}; } catch { values = {}; }
        // Update whichever refresh-token key the blob already used, else the canonical camelCase.
        const key = ['refreshToken', 'RefreshToken', 'refresh_token'].find(k => k in values) ?? 'refreshToken';
        values[key] = newRefreshToken;
        credential.Values = JSON.stringify(values);
        await credential.Save();
    }

    /** Writes the rotated refresh token to the CompanyIntegration.RefreshToken column. */
    private async saveRefreshTokenToConnection(companyIntegration: MJCompanyIntegrationEntity, newRefreshToken: string): Promise<void> {
        companyIntegration.RefreshToken = newRefreshToken;
        await companyIntegration.Save();
    }

    /** Caches the fresh access token + expiry on the connection (best-effort; a save failure is non-fatal). */
    private async saveAccessTokenOnConnection(companyIntegration: MJCompanyIntegrationEntity, accessToken: string, expiresAt: number): Promise<void> {
        try {
            companyIntegration.AccessToken = accessToken;
            companyIntegration.TokenExpirationDate = new Date(expiresAt);
            await companyIntegration.Save();
        } catch {
            /* non-fatal: the in-memory token manager still holds the live access token for this run */
        }
    }

    // ── Config resolution ─────────────────────────────────────────────

    /** Reads Integration.Configuration for vendor-wide facts, with published QBO fallbacks (no tenant data). */
    private resolveVendorConfig(integrationID: string): QuickBooksVendorConfig {
        const raw = this.readIntegrationConfig(integrationID);
        const hosts = (raw?.hosts && typeof raw.hosts === 'object') ? raw.hosts as Record<string, unknown> : {};
        const minor = (raw?.minorVersion && typeof raw.minorVersion === 'object') ? raw.minorVersion as Record<string, unknown> : {};
        const auth = (raw?.authFlow && typeof raw.authFlow === 'object') ? raw.authFlow as Record<string, unknown> : {};
        const rate = (raw?.rateLimitPolicy && typeof raw.rateLimitPolicy === 'object') ? raw.rateLimitPolicy as Record<string, unknown> : {};
        const cfg: QuickBooksVendorConfig = {
            hosts: {
                production: this.asString(hosts.production) ?? DEFAULT_HOST_PRODUCTION,
                sandbox: this.asString(hosts.sandbox) ?? DEFAULT_HOST_SANDBOX,
            },
            companyPathTemplate: this.asString(raw?.companyPathTemplate) ?? DEFAULT_COMPANY_PATH_TEMPLATE,
            minorVersion: this.asNumber(minor.thisBuildTargets) ?? DEFAULT_MINOR_VERSION,
            tokenEndpoint: this.asString(auth.tokenEndpoint) ?? DEFAULT_TOKEN_ENDPOINT,
            scope: this.asString(auth.scope) ?? DEFAULT_SCOPE,
            recordsPath: this.asString(raw?.recordsPath) ?? DEFAULT_RECORDS_PATH,
            correlationHeader: this.asString(raw?.correlationHeader) ?? DEFAULT_CORRELATION_HEADER,
            perMinuteLimit: this.parsePerMinuteLimit(rate.perRealmLimit) ?? DEFAULT_PER_MINUTE_LIMIT,
            concurrentLimit: this.asNumber(rate.concurrentRequestLimit) ?? DEFAULT_CONCURRENT_LIMIT,
        };
        this.lastVendorConfig = cfg;
        return cfg;
    }

    /** Reads the raw Integration.Configuration object from the engine cache (null-tolerant for unit tests). */
    private readIntegrationConfig(integrationID: string): Record<string, unknown> | null {
        try {
            const integration = IntegrationEngineBase.Instance.GetIntegrationByID(integrationID);
            const cfg = integration?.Configuration;
            if (!cfg || typeof cfg !== 'string') return null;
            return JSON.parse(cfg) as Record<string, unknown>;
        } catch {
            return null;
        }
    }

    /** Parses the per-object IntegrationObject.Configuration into a typed shape (QueryEntity/entity class/etc). */
    private parseObjectConfig(obj: MJIntegrationObjectEntity): QuickBooksObjectConfig {
        let cfg: Record<string, unknown> = {};
        const rawCfg = (obj as unknown as { Configuration?: string | null }).Configuration;
        if (rawCfg && typeof rawCfg === 'string') {
            try { cfg = JSON.parse(rawCfg) as Record<string, unknown>; } catch { cfg = {}; }
        }
        const queryEntity = this.asString(cfg.QueryEntity) ?? obj.Name;
        const entityClassRaw = this.asString(cfg.entityClass);
        const entityClass: QuickBooksObjectConfig['EntityClass'] =
            entityClassRaw === 'namelist' || entityClassRaw === 'read-only' ? entityClassRaw : 'transaction';
        const pagination = (cfg.pagination && typeof cfg.pagination === 'object') ? cfg.pagination as Record<string, unknown> : {};
        return {
            QueryEntity: queryEntity,
            EntityClass: entityClass,
            CdcEligible: cfg.cdcEligible === true,
            SkipBase: this.asNumber(pagination.skipParamBase) ?? 1,
        };
    }

    /** Selects the host by environment and applies the company path template with the realm id. */
    private buildCompanyBaseURL(vendorCfg: QuickBooksVendorConfig, creds: QuickBooksCredentials): string {
        const host = (creds.Environment === 'sandbox' ? vendorCfg.hosts.sandbox : vendorCfg.hosts.production).replace(/\/+$/, '');
        const path = vendorCfg.companyPathTemplate.replace('{realmId}', encodeURIComponent(creds.RealmId ?? '')).replace(/^\/+/, '');
        return `${host}/${path}`;
    }

    // ── Query-text builder ────────────────────────────────────────────

    /** Builds a QBO SQL-like SELECT with the watermark WHERE + ORDERBY and STARTPOSITION/MAXRESULTS in-text. */
    private buildQueryText(
        queryEntity: string,
        watermark: string | null,
        watermarkField: string | null,
        startPosition: number,
        maxResults: number,
    ): string {
        let q = `select * from ${queryEntity}`;
        if (watermark && watermarkField) {
            q += ` where ${watermarkField} > '${this.escapeQueryLiteral(watermark)}'`;
            q += ` orderby ${watermarkField}`;
        }
        q += ` startposition ${startPosition} maxresults ${maxResults}`;
        return q;
    }

    /** Escapes a QBO SQL string literal (single quotes doubled). */
    private escapeQueryLiteral(value: string): string {
        return value.replace(/'/g, "''");
    }

    // ── Small read helpers ────────────────────────────────────────────

    private readQueryResponse(body: unknown): Record<string, unknown> | null {
        if (!body || typeof body !== 'object') return null;
        const qr = (body as Record<string, unknown>)[DEFAULT_RECORDS_PATH];
        return (qr && typeof qr === 'object') ? qr as Record<string, unknown> : null;
    }

    private countQueryRecords(qr: Record<string, unknown> | null): number {
        if (!qr) return 0;
        for (const v of Object.values(qr)) {
            if (Array.isArray(v)) return v.length;
        }
        return 0;
    }

    /** Reads a single entity object nested under `<Entity>` in a singleton/get-one response. */
    private readSingleEntity(body: unknown, queryEntity: string): Record<string, unknown> | null {
        if (!body || typeof body !== 'object') return null;
        const b = body as Record<string, unknown>;
        const direct = b[queryEntity];
        if (direct && typeof direct === 'object' && !Array.isArray(direct)) return direct as Record<string, unknown>;
        // Fallback: the first object-valued property that isn't the `time` scalar.
        for (const [k, v] of Object.entries(b)) {
            if (k === 'time') continue;
            if (v && typeof v === 'object' && !Array.isArray(v)) return v as Record<string, unknown>;
        }
        return null;
    }

    private readCompanyName(body: unknown): string | undefined {
        const ci = this.readSingleEntity(body, 'CompanyInfo');
        const name = ci?.CompanyName;
        return typeof name === 'string' ? name : undefined;
    }

    private readFaultErrors(body: unknown): QuickBooksFaultError[] {
        if (!body || typeof body !== 'object') return [];
        const fault = (body as Record<string, unknown>).fault ?? (body as Record<string, unknown>).Fault;
        if (!fault || typeof fault !== 'object') return [];
        const arr = (fault as Record<string, unknown>).error ?? (fault as Record<string, unknown>).Error;
        if (!Array.isArray(arr)) return [];
        return arr.map(e => {
            const o = (e && typeof e === 'object') ? e as Record<string, unknown> : {};
            return {
                message: this.asString(o.message ?? o.Message),
                detail: this.asString(o.detail ?? o.Detail),
                code: this.asString(o.code ?? o.Code),
                element: this.asString(o.element ?? o.Element),
            };
        });
    }

    /** Reads MetaData.LastUpdatedTime (the incremental watermark) off a raw record. */
    private readLastUpdated(raw: Record<string, unknown>, watermarkField: string | null): Date | undefined {
        const iso = this.readWatermarkString(raw, watermarkField);
        if (!iso) return undefined;
        const d = new Date(iso);
        return Number.isNaN(d.getTime()) ? undefined : d;
    }

    /** Resolves a (possibly dotted, e.g. `MetaData.LastUpdatedTime`) watermark path to a string value. */
    private readWatermarkString(raw: Record<string, unknown>, watermarkField: string | null): string | undefined {
        if (!watermarkField) return undefined;
        let cur: unknown = raw;
        for (const seg of watermarkField.split('.')) {
            if (!cur || typeof cur !== 'object') return undefined;
            cur = (cur as Record<string, unknown>)[seg];
        }
        return typeof cur === 'string' ? cur : undefined;
    }

    /** Highest watermark value across a batch (ISO-8601 compares lexically). */
    private maxWatermark(records: Record<string, unknown>[], watermarkField: string | null): string | undefined {
        if (!watermarkField) return undefined;
        let max: string | undefined;
        for (const r of records) {
            const v = this.readWatermarkString(r, watermarkField);
            if (v && (max === undefined || v > max)) max = v;
        }
        return max;
    }

    /** PK field names from the cached fields (universal QBO PK is 'Id'; empty when genuinely keyless). */
    private primaryKeyFieldNames(fields: MJIntegrationObjectFieldEntity[]): string[] {
        return fields.filter(f => f.IsPrimaryKey).map(f => f.Name);
    }

    // ── Rate-limit / backoff helpers ──────────────────────────────────

    private parseRetryAfterMs(headers: Record<string, string>): number | undefined {
        const raw = headers['retry-after'];
        if (!raw) return undefined;
        const seconds = Number(raw);
        if (Number.isFinite(seconds)) return Math.max(0, seconds * 1000);
        const when = new Date(raw).getTime();
        return Number.isFinite(when) ? Math.max(0, when - Date.now()) : undefined;
    }

    private computeBackoffMs(headers: Record<string, string>, attempt: number): number {
        const retryAfter = this.parseRetryAfterMs(headers);
        if (retryAfter != null) return retryAfter;
        return Math.min(30_000, 500 * Math.pow(2, attempt));
    }

    private sleep(ms: number): Promise<void> {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    // ── Tiny typed coercion helpers ───────────────────────────────────

    private normalizeEnvironment(value: string | undefined): 'production' | 'sandbox' {
        return (value ?? '').toLowerCase() === 'sandbox' ? 'sandbox' : 'production';
    }

    private parsePerMinuteLimit(value: unknown): number | undefined {
        if (typeof value === 'number' && Number.isFinite(value)) return value;
        if (typeof value === 'string') {
            const m = value.match(/(\d+)/);
            if (m) return Number(m[1]);
        }
        return undefined;
    }

    private firstString(obj: Record<string, unknown>, keys: string[]): string | undefined {
        for (const k of keys) {
            const v = obj[k];
            if (typeof v === 'string' && v.trim().length > 0) return v.trim();
            if (typeof v === 'number') return String(v);
        }
        return undefined;
    }

    private asString(value: unknown): string | undefined {
        if (typeof value === 'string' && value.trim().length > 0) return value.trim();
        if (typeof value === 'number') return String(value);
        return undefined;
    }

    private asNumber(value: unknown): number | undefined {
        if (typeof value === 'number' && Number.isFinite(value)) return value;
        if (typeof value === 'string') {
            const n = Number(value);
            if (Number.isFinite(n)) return n;
        }
        return undefined;
    }

    /** Removes undefined-valued keys so a spread merge doesn't clobber a lower-precedence real value. */
    private stripUndefined<T extends Record<string, unknown>>(obj: T): Partial<T> {
        const out: Partial<T> = {};
        for (const [k, v] of Object.entries(obj)) {
            if (v !== undefined) (out as Record<string, unknown>)[k] = v;
        }
        return out;
    }
}

// ─── Rate-limit / correlation-aware transport error ────────────────────────

/** Thrown by the transport on an exhausted 429; carries the parsed Retry-After for the engine hook. */
class QuickBooksRateLimitError extends Error {
    public readonly RetryAfterMs?: number;
    public readonly IntuitTid?: string;
    constructor(message: string, retryAfterMs?: number, intuitTid?: string) {
        super(message);
        this.name = 'QuickBooksRateLimitError';
        this.RetryAfterMs = retryAfterMs;
        this.IntuitTid = intuitTid;
    }
}

/** Tree-shaking prevention: referenced from index to keep the @RegisterClass registration alive under bundling. */
export function LoadQuickBooksConnector(): void {
    // no-op — the mere existence of this exported function prevents the class from being tree-shaken.
}
