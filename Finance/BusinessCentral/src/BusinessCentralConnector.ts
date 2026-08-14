import { RegisterClass } from '@memberjunction/global';
import { Metadata, type UserInfo } from '@memberjunction/core';
import type {
    MJCompanyIntegrationEntity,
    MJCredentialEntity,
    MJIntegrationObjectEntity,
    MJIntegrationObjectFieldEntity,
} from '@memberjunction/core-entities';
import {
    BaseIntegrationConnector,
    BaseRESTIntegrationConnector,
    OAuth2TokenManager,
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
    type CreateRecordContext,
    type UpdateRecordContext,
    type DeleteRecordContext,
    type CRUDResult,
    type ExternalRecord,
    type ExternalObjectSchema,
    type ExternalFieldSchema,
    type SourceSchemaInfo,
    type RateLimitPolicy,
    type SyncErrorCode,
    type IntegrationObjectInfo,
    type ActionGeneratorConfig,
} from '@memberjunction/integration-engine';
import { IntegrationEngineBase } from '@memberjunction/integration-engine-base';
import { mergeDeclaredWithSampledFields } from '@memberjunction/connector-schema-merge';

// ─── Design note ────────────────────────────────────────────────────────
//
// Microsoft Dynamics 365 Business Central — REST/JSON (OData v4) over HTTPS.
//
// This connector is PURE MECHANISM. The object/field catalog is NOT baked here — it lives in the
// Declared metadata (metadata/integrations/business-central/.business-central.integration.json), seeded
// from Microsoft's credential-free API-v2.0 reference corpus (case-1 discovery). At runtime the connector
// ADDITIVELY discovers the tenant's own surface from the two $metadata (EDMX) endpoints — the standard
// `/api/{apiVersion}/$metadata` entity sets and the tenant's PUBLISHED `/ODataV4/$metadata` web-service
// pages (e.g. Detailed_Customer_Ledger_Entries). There is NO hardcoded object list, NO field catalog and
// NO baked PK/FK/required/readonly constants in this file. Credential-free discovery re-yields the full
// standard universe from the Declared baseline (so a credential-free structure self-check never reads as
// drift); a live credential only ADDS the tenant's extensions.
//
// What this class supplies (the Business Central protocol shape):
//  - Auth: OAuth2 client-credentials (S2S) against Microsoft Entra ID, via the shared OAuth2TokenManager
//    (NO inline crypto). The token is resolved LAZILY PER REQUEST behind an expiry-aware cache — never
//    frozen at connect (the replaced driver froze it and long syncs died mid-flight on a 401 reported as a
//    generic request error — ContextBC.md §3/§7.1). A 401 AFTER a token was attached is treated as expiry:
//    re-acquire once and retry. A 403 is reachable-but-not-permitted (a permission/scope problem).
//  - URL: ONE dual-surface builder covering both grammars — webapi
//    `{server}/v2.0/[{tenantId}/]{environment}/api/{apiVersion}/companies({companyId})/{entitySet}` (company
//    GUID UNQUOTED) and odatav4 `{server}/v2.0/[{tenantId}/]{environment}/ODataV4/Company('{companyId}')/{page}`
//    (company GUID SINGLE-QUOTED). EVERY segment — server, tenant, environment, apiVersion, company — comes
//    from configuration; `Production` is NEVER hardcoded (ContextBC.md §4/§7.2: the replaced driver could not
//    target a sandbox at all, so a stage run of the write path posted into the production ledger).
//  - Company scoping: `companies` is the enumerable root; company-scoped sets iterate under the configured
//    company (or several — a run can address multiple companies, which the legacy multi-company journal
//    write depended on — or ALL reachable companies when configured to enumerate).
//  - Pagination: server-driven continuation. `@odata.nextLink` is followed to exhaustion, absolute-URL-safe,
//    with a per-page resumable checkpoint cursor. No `$skip`/`$top` is ever fabricated (the GrowthZone
//    `skip`-vs-`$skip` defect capped every object at one page while returning HTTP 200).
//  - OData query building: $filter values are escaped (single quotes doubled) and URL-encoded;
//    Edm.DateTimeOffset watermark literals are UNQUOTED per OData v4.
//  - Incremental: `$filter=<watermarkField> gt <ISO8601>` ONLY for objects the frozen contract marks
//    SupportsIncrementalSync with an IncrementalWatermarkField. Others full-walk (engine content-hash diff).
//  - Writes: per-operation metadata-driven CRUD with BC-specific path resolution (company + parent segments),
//    the OData If-Match/@odata.etag precondition on PATCH/DELETE (re-read + retry once on a precondition
//    failure), and serialized write pacing. NO live write is possible in this build: the write path is
//    exercised only against the spec-derived mock (GENUINE-GREEN-MOCK).
//
// Overrides vs. the generic base are justified inline at each method.

// ─── Public URL grammar (exported: unit-tested against BOTH surfaces) ─────

/** The two Business Central HTTP surfaces. They differ in company-key QUOTING; getting it wrong yields a 404. */
export type BusinessCentralSurface = 'webapi' | 'odatav4';

/** Every URL segment Business Central needs. All values are configuration — nothing is hardcoded. */
export interface BusinessCentralURLParts {
    /** API host root, e.g. `https://api.businesscentral.dynamics.com` (no trailing slash required). */
    Server: string;
    /**
     * Azure tenant ID / user-domain segment. OPTIONAL: Microsoft documents BOTH
     * `/v2.0/{tenantId}/{environment}/…` (form A) and `/v2.0/{environment}/…` (form B) as current, and the
     * reality probe confirmed BOTH route (401, never 404). Omit to emit form B.
     */
    TenantId?: string | null;
    /** BC environment name, e.g. `Production` or `Sandbox`. NEVER defaulted to `Production` by this code. */
    Environment: string;
    /** API version segment for the webapi surface, e.g. `v2.0`. Unused by the odatav4 surface. */
    ApiVersion?: string;
    /** BC company GUID. Omit for tenant-scoped resources (`companies`, `subscriptions`). */
    CompanyId?: string | null;
}

/** Trims trailing slashes so segment joins never double up. */
function trimTrailingSlash(value: string): string {
    return value.replace(/\/+$/, '');
}

/**
 * Builds the API ROOT (everything before the company/entity-set segments) for a surface.
 *
 * webapi:  `{server}/v2.0/[{tenantId}/]{environment}/api/{apiVersion}`
 * odatav4: `{server}/v2.0/[{tenantId}/]{environment}/ODataV4`
 */
export function BuildBusinessCentralRootURL(surface: BusinessCentralSurface, parts: BusinessCentralURLParts): string {
    const server = trimTrailingSlash(parts.Server);
    const tenantSegment = parts.TenantId && parts.TenantId.trim().length > 0
        ? `/${encodeURIComponent(parts.TenantId.trim())}`
        : '';
    const environment = encodeURIComponent(parts.Environment);
    if (surface === 'odatav4') {
        return `${server}/v2.0${tenantSegment}/${environment}/ODataV4`;
    }
    const apiVersion = encodeURIComponent(parts.ApiVersion ?? 'v2.0');
    return `${server}/v2.0${tenantSegment}/${environment}/api/${apiVersion}`;
}

/**
 * Builds the company-scope path SEGMENT for a surface — the one place the two grammars genuinely diverge:
 *
 *   webapi  → `companies({guid})`     — company GUID **UNQUOTED**
 *   odatav4 → `Company('{guid}')`     — company GUID **SINGLE-QUOTED**
 *
 * A literal single quote inside the id is escaped by doubling (OData string-literal rule).
 */
export function BuildBusinessCentralCompanySegment(surface: BusinessCentralSurface, companyId: string): string {
    if (surface === 'odatav4') {
        return `Company('${EscapeODataStringLiteral(companyId)}')`;
    }
    return `companies(${encodeURIComponent(companyId)})`;
}

/**
 * Full resource URL for either surface. `resource` is the entity set (webapi) or published page (odatav4),
 * optionally with its own trailing key segment. When `CompanyId` is absent the resource is tenant-scoped
 * (`companies`, `subscriptions`) and no company segment is emitted.
 */
export function BuildBusinessCentralResourceURL(
    surface: BusinessCentralSurface,
    parts: BusinessCentralURLParts,
    resource: string,
): string {
    const root = BuildBusinessCentralRootURL(surface, parts);
    const path = resource.replace(/^\/+/, '');
    if (!parts.CompanyId || parts.CompanyId.trim().length === 0) {
        return path.length > 0 ? `${root}/${path}` : root;
    }
    const companySegment = BuildBusinessCentralCompanySegment(surface, parts.CompanyId.trim());
    return path.length > 0 ? `${root}/${companySegment}/${path}` : `${root}/${companySegment}`;
}

/**
 * Escapes an OData v4 string literal: a single quote is doubled. Applied to EVERY value interpolated into a
 * `$filter`, even values that came from Business Central itself (ContextBC.md §7.5 — the replaced driver
 * string-interpolated document numbers and ledger entry numbers straight into `$filter`).
 */
export function EscapeODataStringLiteral(value: string): string {
    return value.replace(/'/g, "''");
}

/** Quotes + escapes a value as an OData string literal (`O'Brien` → `'O''Brien'`). */
export function ODataStringLiteral(value: string): string {
    return `'${EscapeODataStringLiteral(value)}'`;
}

/**
 * Formats a watermark value as an `Edm.DateTimeOffset` literal — **UNQUOTED** in OData v4 (quoting it is a
 * type error, not a no-op). Accepts an ISO-8601 string or anything `Date` can parse; a non-parsable value is
 * returned trimmed so a caller-supplied literal passes through unchanged.
 */
export function ODataDateTimeOffsetLiteral(value: string): string {
    const trimmed = value.trim();
    const parsed = new Date(trimmed);
    return Number.isNaN(parsed.getTime()) ? trimmed : parsed.toISOString();
}

/** Appends an already-built query string to a URL, choosing `?` or `&`. */
export function AppendQueryString(url: string, query: string): string {
    if (query.length === 0) return url;
    return `${url}${url.includes('?') ? '&' : '?'}${query}`;
}

// ─── Connection configuration ───────────────────────────────────────────

/** Resolved Business Central connection configuration (credential + non-secret config, merged). */
export interface BusinessCentralConnectionConfig {
    /** Azure app-registration client ID. */
    ClientId: string;
    /** Azure app-registration client secret. */
    ClientSecret: string;
    /** Azure tenant ID (the legacy driver overloaded `CompanyIntegration.APIKey` with this). */
    TenantId: string;
    /** BC API host root. Defaults to the documented public host. */
    Server: string;
    /** Entra ID authority host. Defaults to `https://login.microsoftonline.com`. */
    AuthorityHost: string;
    /** OAuth2 scope. Defaults to `<resource>/.default`. */
    Scope: string;
    /** BC environment name (`Production`, `Sandbox`, a named sandbox…). REQUIRED — never defaulted to Production. */
    Environment: string;
    /** webapi API version segment. Defaults to `v2.0`. */
    ApiVersion: string;
    /** Emit the tenant segment in the URL (form A). Both forms are documented + probe-confirmed to route. */
    IncludeTenantSegment: boolean;
    /** Primary BC company GUID (the legacy driver overloaded `CompanyIntegration.ExternalSystemID` with this). */
    CompanyId?: string;
    /** Additional company GUIDs to address in one run (multi-company). */
    CompanyIds?: string[];
    /** Enumerate `companies` at runtime and sync every reachable company. */
    AllCompanies: boolean;
    /** Milliseconds to wait between successive writes. Context-empirical (legacy driver's only rate control). */
    WritePacingMs: number;
    /** `Prefer: odata.maxpagesize=<n>` client hint. Omitted when unset (server-driven paging decides). */
    MaxPageSize?: number;
    /** Max parent records enumerated when walking a nested access path (guards runaway fan-out). */
    MaxParentFanout: number;
    /** Emit `$select` when the engine supplies RequestedSourceFields. Docs-unproven for v2.0 → opt-in. */
    UseSelect: boolean;
    /** What to send as `If-Match` when no ETag can be resolved: `wildcard` (`*`) or `fail`. */
    IfMatchFallback: 'wildcard' | 'fail';
    /** Max transport retries for a throttled/transient response. */
    MaxRetries: number;
}

/** Auth context carried through the REST pipeline. */
export interface BusinessCentralAuthContext extends RESTAuthContext {
    /** The resolved connection configuration for this CompanyIntegration. */
    Config: BusinessCentralConnectionConfig;
    /** Access token captured when the context was built. MakeHTTPRequest refreshes it per request. */
    AccessToken: string;
}

/** Business Central OData error envelope (`{"error":{"code":"…","message":"…"}}`). */
interface ODataErrorEnvelope {
    error?: { code?: string; message?: string | { value?: string } };
}

/** Collection envelope: records under `value`, continuation under `@odata.nextLink`. */
interface ODataCollectionEnvelope {
    value?: unknown;
    '@odata.nextLink'?: unknown;
    '@odata.context'?: unknown;
}

/** Resume checkpoint encoded into FetchBatchResult.NextCursor. */
interface BusinessCentralResumeState {
    /** Absolute continuation URL for the in-flight collection, when a page boundary was reached. */
    u?: string;
    /** Remaining concrete collection URLs (company × parent expansion) still to walk. */
    r: string[];
}

/** A single concrete collection URL plus the scope that produced it (for diagnostics). */
interface ResolvedCollection {
    URL: string;
    CompanyId?: string;
}

// ─── Constants ──────────────────────────────────────────────────────────

/** Documented public Business Central API host. */
const DEFAULT_SERVER = 'https://api.businesscentral.dynamics.com';

/** Microsoft Entra ID authority host used by the client-credentials grant. */
const DEFAULT_AUTHORITY_HOST = 'https://login.microsoftonline.com';

/** Documented app-only scope for the Business Central API. */
const DEFAULT_SCOPE = 'https://api.businesscentral.dynamics.com/.default';

/** webapi version segment default (Microsoft's documented current version). */
const DEFAULT_API_VERSION = 'v2.0';

/** Legacy driver's hardcoded pre-POST sleep — context-empirical, NOT a Microsoft-documented limit. */
const DEFAULT_WRITE_PACING_MS = 500;

/** Documented per-user max concurrent requests (5); used as the concurrency hint + parent fan-out ceiling. */
const DOCUMENTED_MAX_CONCURRENT_REQUESTS = 5;

/** Documented per-user speed rate: 600 req/min (production), 300 req/min (sandbox). */
const PRODUCTION_REQUESTS_PER_MINUTE = 600;
const SANDBOX_REQUESTS_PER_MINUTE = 300;

/** Default ceiling on parent records enumerated while walking a nested access path. */
const DEFAULT_MAX_PARENT_FANOUT = 500;

/** Default transport retry budget for 429/503/504. */
const DEFAULT_MAX_RETRIES = 5;

/** Response property carrying the OData concurrency token (vendor example: inventoryPostingGroup GET). */
const ETAG_PROPERTY = '@odata.etag';

// ─── BusinessCentralConnector ───────────────────────────────────────────

/**
 * Microsoft Dynamics 365 Business Central connector.
 *
 * ONE registration only, under the TS class symbol — which is also the persisted metadata `ClassName`
 * (`metadata/integrations/business-central/.business-central.integration.json`). A second, slug-cased
 * registration previously existed to quiet a T1 three-way-name failure; that was appeasement of a gate
 * reading a bad metadata value, and two registrations for one class is a registry collision waiting to
 * happen. If T1 disagrees again, the fix is in the metadata, never a second decorator.
 */
@RegisterClass(BaseIntegrationConnector, 'BusinessCentralConnector')
export class BusinessCentralConnector extends BaseRESTIntegrationConnector {

    /** Shared OAuth2 helper — caches the token and re-mints inside the expiry buffer (never a frozen token). */
    private tokenManager = new OAuth2TokenManager();

    /** Resolved configuration per CompanyIntegration ID (non-secret + secret merge). */
    private configCache = new Map<string, BusinessCentralConnectionConfig>();

    /** `objectName|externalId` → last-seen `@odata.etag`, captured on read for the If-Match precondition. */
    private etagCache = new Map<string, string>();

    /**
     * `objectName(lowercased)` → the surface it was DISCOVERED on, recorded during {@link DiscoverObjects}.
     * This is a runtime observation (not a baked catalog): it lets a tenant-published ODataV4 page be fetched
     * with the ODataV4 grammar even before an explicit `surface` tag has been persisted onto its
     * IntegrationObject.Configuration. An explicit tag always wins.
     */
    private discoveredSurfaces = new Map<string, BusinessCentralSurface>();

    /** Serializes writes so pacing is honored (never a naive parallel Promise.all over journal lines). */
    private writeChain: Promise<void> = Promise.resolve();

    // ── Identity (T1 three-way invariant) ─────────────────────────────

    /** Verbatim `MJ: Integrations.Name`. The T1 three-way name check compares this === metadata Name. */
    public override get IntegrationName(): string {
        return 'business-central';
    }

    // ── Capability getters (in lockstep with the per-operation metadata columns) ──

    public override get SupportsCreate(): boolean { return true; }
    public override get SupportsUpdate(): boolean { return true; }
    public override get SupportsDelete(): boolean { return true; }

    // ── Action generation ────────────────────────────────────────────

    /**
     * Shapes the cached Declared catalog into the ActionMetadataGenerator's hint structure, so one MJ
     * Action is generated per applicable object/verb. Without this the base class returns an empty
     * array, `GetActionGeneratorConfig()` returns null, and **no Business Central Actions exist at
     * all** — the connector is reachable by sync and by IntegrationWriteRecord, but not by an agent or
     * a flow. That is what keeps A-UC7 (stage a JE batch) from being invoked like any other Action.
     *
     * Derived entirely from the runtime IntegrationObject / IntegrationObjectField cache. When that
     * cache is unseeded — action generation can run before the integration is seeded — this returns an
     * empty array and generates nothing. It must never fall back to a hardcoded list: with 83 declared
     * objects, a fallback serving a familiar handful still looks like it worked, which is precisely the
     * `catalog-in-code` defect.
     */
    public override GetIntegrationObjects(): IntegrationObjectInfo[] {
        const engine = IntegrationEngineBase.Instance;
        const integration = engine.Integrations.find(i => i.Name === this.IntegrationName);
        if (!integration) return [];

        return engine.GetActiveIntegrationObjects(integration.ID).map(obj => ({
            Name: obj.Name,
            DisplayName: obj.DisplayName ?? obj.Name,
            Description: obj.Description ?? undefined,
            SupportsWrite: obj.SupportsWrite,
            Fields: engine.GetIntegrationObjectFields(obj.ID).map(f => ({
                Name: f.Name,
                DisplayName: f.DisplayName ?? f.Name,
                Description: f.Description ?? undefined,
                Type: f.Type ?? 'string',
                IsRequired: f.IsRequired,
                IsReadOnly: f.IsReadOnly,
                IsPrimaryKey: f.IsPrimaryKey,
            })),
        }));
    }

    public override GetActionGeneratorConfig(): ActionGeneratorConfig | null {
        const config = super.GetActionGeneratorConfig();
        if (!config) return null;
        config.IconClass = 'fa-brands fa-microsoft';
        return config;
    }

    /**
     * NOT authoritative. No Microsoft statement asserts that either `$metadata` endpoint is a complete,
     * permission-filtered enumeration of everything a credential can reach — the one related statement runs
     * the OTHER way ("all authorized users have access to metadata… only users with sufficient permissions
     * can access actual data"). Absence therefore proves nothing and must never deactivate a declared object.
     * Mirrors `Configuration.CompanyScoping.discoveryIsAuthoritative = false` in the frozen contract.
     */
    public override get DiscoveryIsAuthoritative(): boolean {
        return false;
    }

    // ── Sync-efficiency hooks (§7/§10 — populated ONLY from evidenced contract facts) ──

    /**
     * Documented per-user "speed rate": 600 req/min production, 300 req/min sandbox. Expressed as tokens/sec.
     * The environment is read from the last-resolved connection config; before any connection is resolved the
     * conservative sandbox rate applies. Backoff factor is deliberately aggressive because Business Central
     * does NOT document a `Retry-After` header on 429 — the engine must self-pace rather than trust a hint.
     */
    public override get RateLimitPolicy(): RateLimitPolicy | null {
        const perMinute = this.isProductionEnvironment() ? PRODUCTION_REQUESTS_PER_MINUTE : SANDBOX_REQUESTS_PER_MINUTE;
        const tokensPerSec = perMinute / 60;
        return {
            TokensPerSec: tokensPerSec,
            Burst: DOCUMENTED_MAX_CONCURRENT_REQUESTS,
            ThrottleBackoffFactor: 0.5,
            MinTokensPerSec: SANDBOX_REQUESTS_PER_MINUTE / 60 / 2,
        };
    }

    /** Documented per-user ceiling of 5 concurrent requests (a 6th queues; an 8-minute queue wait 503s). */
    public override get MaxConcurrencyHint(): number | null {
        return DOCUMENTED_MAX_CONCURRENT_REQUESTS;
    }

    /**
     * Parses a throttle hint from a Business Central error. Microsoft does NOT document `Retry-After` on 429
     * (grep of both rate-limit pages: zero hits), so this reads whatever the LIVE response actually carried —
     * `retry-after` (seconds or HTTP-date) or an `x-ms-ratelimit-*-reset` hint — and returns undefined when
     * the response carried none. Nothing is assumed.
     */
    public override ExtractRetryAfterMs(error: unknown): number | undefined {
        const headers = this.extractHeadersFromError(error);
        if (!headers) return undefined;
        const retryAfter = headers['retry-after'];
        if (typeof retryAfter === 'string' && retryAfter.length > 0) {
            const seconds = Number(retryAfter);
            if (Number.isFinite(seconds) && seconds >= 0) return Math.round(seconds * 1000);
            const asDate = Date.parse(retryAfter);
            if (!Number.isNaN(asDate)) return Math.max(0, asDate - Date.now());
        }
        const reset = headers['x-ms-ratelimit-burst-reset'] ?? headers['x-ms-ratelimit-timeremaining'];
        if (typeof reset === 'string') {
            const seconds = Number(reset);
            if (Number.isFinite(seconds) && seconds >= 0) return Math.round(seconds * 1000);
        }
        return undefined;
    }

    /**
     * Keyset-resume ordering key, read from the object's declared `StableOrderingKey` (the frozen contract
     * carries one per object — `id` on 76 of 83, an entity-specific key on the report-style resources).
     * Never guessed: null when the metadata declares none.
     */
    public override StableOrderingKey(objectName: string): string | null {
        const obj = this.findCachedObject(objectName);
        return obj?.StableOrderingKey ?? null;
    }

    // ── Discovery — MECHANISM, never a baked catalog ───────────────────

    /**
     * Objects = the credential-free Declared baseline (Microsoft's published API-v2.0 reference corpus,
     * persisted as metadata) UNIONed with whatever this tenant's `$metadata` documents at runtime.
     *
     * The baseline path requires NO credential, so a credential-free structure self-check always re-yields
     * the full standard universe (this is the T3 deadlock fix — an auth-gated endpoint must never be the ONLY
     * discovery path). A live credential is purely ADDITIVE: it contributes the tenant's published ODataV4
     * pages (e.g. Detailed_Customer_Ledger_Entries) and any extension entity sets. Different tenants
     * legitimately discover different sets.
     */
    public override async DiscoverObjects(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<ExternalObjectSchema[]> {
        const declared = await super.DiscoverObjects(companyIntegration, contextUser);
        const byName = new Map<string, ExternalObjectSchema>(declared.map(o => [o.Name.toLowerCase(), o]));
        for (const surface of ['webapi', 'odatav4'] as BusinessCentralSurface[]) {
            const edmx = await this.tryFetchMetadataDocument(companyIntegration, contextUser, surface);
            if (!edmx) continue;
            for (const set of ParseEDMXEntitySets(edmx)) {
                // Record which surface serves this set BEFORE the dedupe, so a set that also exists in the
                // Declared baseline still gets its surface observed.
                if (!this.discoveredSurfaces.has(set.toLowerCase())) {
                    this.discoveredSurfaces.set(set.toLowerCase(), surface);
                }
                if (byName.has(set.toLowerCase())) continue;
                byName.set(set.toLowerCase(), {
                    Name: set,
                    Label: set,
                    Description: `Discovered from the ${surface} $metadata document of this Business Central connection.`,
                    SupportsIncrementalSync: false,
                    SupportsWrite: false,
                });
            }
        }
        return Array.from(byName.values());
    }

    /**
     * Fields = the Declared field set for the object UNIONed with the entity type's properties as this
     * tenant's `$metadata` declares them. Constraint flags come from the EDMX itself (`Nullable`, the `<Key>`
     * PropertyRef) — never guessed, never sampled at build time. Objects absent from the EDMX simply keep
     * their declared fields.
     */
    public override async DiscoverFields(
        companyIntegration: MJCompanyIntegrationEntity,
        objectName: string,
        contextUser: UserInfo,
    ): Promise<ExternalFieldSchema[]> {
        const declared = await this.safeDeclaredFields(companyIntegration, objectName, contextUser);
        const byName = new Map<string, ExternalFieldSchema>(declared.map(f => [f.Name.toLowerCase(), f]));
        for (const surface of ['webapi', 'odatav4'] as BusinessCentralSurface[]) {
            const edmx = await this.tryFetchMetadataDocument(companyIntegration, contextUser, surface);
            if (!edmx) continue;
            for (const field of ParseEDMXFieldsForEntitySet(edmx, objectName)) {
                if (byName.has(field.Name.toLowerCase())) continue;
                byName.set(field.Name.toLowerCase(), field);
            }
        }
        return Array.from(byName.values());
    }

    /**
     * Sample-union field enrichment (the MJ connector standard): after the base cache-driven introspection,
     * sample each object's live read shape and UNION it into the declared field set (never-shrink,
     * declared-wins). This is what carries a tenant's custom columns into the schema. Wired at
     * `IntrospectSchema` — NEVER at `DiscoverFields`, which would recurse through DiscoverFieldsViaFetch's
     * fallback. Best-effort + parallel: a per-object sample failure leaves that object's declared fields intact.
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

    /**
     * Read-only reachability + auth probe: GET the enumerable `companies` root on the webapi surface.
     * 401 = credential problem; 403 = reachable but the app registration lacks the API permission (a
     * permission/scope problem, NOT an invalid credential and NOT a connector defect).
     */
    public async TestConnection(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<ConnectionTestResult> {
        try {
            const auth = await this.Authenticate(companyIntegration, contextUser);
            const url = BuildBusinessCentralResourceURL('webapi', this.urlParts(auth.Config, null), 'companies');
            const response = await this.MakeHTTPRequest(auth, url, 'GET', this.BuildHeaders(auth));
            if (response.Status >= 200 && response.Status < 300) {
                const companies = this.NormalizeResponse(response.Body, 'value');
                return {
                    Success: true,
                    Message: `Connected to Business Central (environment "${auth.Config.Environment}"): ${companies.length} company/companies reachable.`,
                    ServerVersion: `Business Central API ${auth.Config.ApiVersion}`,
                };
            }
            if (response.Status === 401) {
                return { Success: false, Message: 'Business Central rejected the credential (HTTP 401). Check the client ID/secret and tenant ID.' };
            }
            if (response.Status === 403) {
                return {
                    Success: false,
                    Message: 'Business Central is reachable but the app registration is not permitted (HTTP 403). '
                        + 'Grant the API.ReadWrite.All application permission on the Dynamics 365 Business Central API and admin-consent it. '
                        + 'This is a permission/scope problem, not an invalid credential.',
                };
            }
            return { Success: false, Message: `Business Central GET companies returned HTTP ${response.Status}. ${this.ExtractErrorMessage(response) ?? ''}`.trim() };
        } catch (err: unknown) {
            return { Success: false, Message: `Connection failed: ${this.errorMessage(err)}` };
        }
    }

    /**
     * Releases every per-connection resource this connector holds — the cached OAuth token, the resolved
     * configuration, and the ETag cache. Real, not a stub (ContextBC.md §7.7: the replaced driver's
     * `disconnect()` logged "Method not implemented").
     */
    public Disconnect(): void {
        this.tokenManager.Reset();
        this.configCache.clear();
        this.etagCache.clear();
        this.discoveredSurfaces.clear();
        this.writeChain = Promise.resolve();
    }

    // ── Abstract REST hooks ───────────────────────────────────────────

    /**
     * Resolves the connection configuration and returns a context carrying a CURRENT access token. Token
     * acquisition runs through the shared OAuth2TokenManager (client-credentials against Entra ID), which
     * re-mints inside its expiry buffer — so the token is lazy + expiring, never frozen for the life of a run.
     * MakeHTTPRequest re-resolves it per request, so a long sync cannot outlive its token.
     */
    protected override async Authenticate(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<BusinessCentralAuthContext> {
        this.cachedIntegrationID = companyIntegration.IntegrationID;
        const config = await this.ResolveConfig(companyIntegration, contextUser);
        const accessToken = await this.acquireAccessToken(config);
        return { Config: config, AccessToken: accessToken };
    }

    /** Static per-request headers. The Authorization value is refreshed by MakeHTTPRequest before it goes out. */
    protected override BuildHeaders(auth: RESTAuthContext): Record<string, string> {
        const ctx = auth as BusinessCentralAuthContext;
        const headers: Record<string, string> = {
            'Authorization': `Bearer ${ctx.AccessToken}`,
            'Accept': 'application/json',
            'Content-Type': 'application/json',
        };
        if (ctx.Config.MaxPageSize && ctx.Config.MaxPageSize > 0) {
            headers['Prefer'] = `odata.maxpagesize=${ctx.Config.MaxPageSize}`;
        }
        return headers;
    }

    /**
     * HTTP transport. Owns: per-request token freshness, 401-after-token → re-acquire once, real exponential
     * backoff honoring an observed `Retry-After` on 429/503/504, and structured error surfacing. Test
     * subclasses override this to capture the outbound request and return canned responses.
     */
    protected override async MakeHTTPRequest(
        auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown,
    ): Promise<RESTResponse> {
        const ctx = auth as BusinessCentralAuthContext;
        let reauthorized = false;
        for (let attempt = 0; ; attempt++) {
            const token = await this.acquireAccessToken(ctx.Config);
            ctx.AccessToken = token;
            const outbound: Record<string, string> = { ...headers, 'Authorization': `Bearer ${token}` };
            const response = await this.SendHTTP(url, method, outbound, body);

            if (response.Status === 401 && !reauthorized) {
                // A 401 AFTER a token was attached means the token expired/was revoked mid-run — re-acquire once.
                reauthorized = true;
                this.tokenManager.Reset();
                continue;
            }
            const throttled = response.Status === 429 || response.Status === 503 || response.Status === 504;
            if (throttled && attempt < ctx.Config.MaxRetries) {
                await this.sleep(this.computeBackoffMs(response, attempt));
                continue;
            }
            return response;
        }
    }

    /**
     * The single network boundary — separated from MakeHTTPRequest so the retry/token logic above stays
     * testable while a test subclass can stub ONLY the socket.
     */
    protected async SendHTTP(
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown,
    ): Promise<RESTResponse> {
        const response = await fetch(url, {
            method,
            headers,
            body: body !== undefined && body !== null ? JSON.stringify(body) : undefined,
        });
        const respHeaders: Record<string, string> = {};
        response.headers.forEach((value, key) => { respHeaders[key.toLowerCase()] = value; });
        const text = await response.text();
        let parsed: unknown = null;
        if (text.length > 0) {
            try { parsed = JSON.parse(text); } catch { parsed = text; }
        }
        return { Status: response.status, Body: parsed, Headers: respHeaders };
    }

    /**
     * OData collection envelope: records live under `value`. A single-record body (an entity GET) is returned
     * as a one-element array; a bare array passes through. Nothing is stripped from the records themselves —
     * full-record pass-through is what lets the framework capture custom columns.
     */
    protected override NormalizeResponse(rawBody: unknown, responseDataKey: string | null): Record<string, unknown>[] {
        if (rawBody == null) return [];
        if (Array.isArray(rawBody)) return rawBody as Record<string, unknown>[];
        if (typeof rawBody !== 'object') return [];
        const body = rawBody as Record<string, unknown>;
        const key = responseDataKey ?? 'value';
        const collection = body[key];
        if (Array.isArray(collection)) return collection as Record<string, unknown>[];
        if ('value' in body && Array.isArray(body.value)) return body.value as Record<string, unknown>[];
        return [body];
    }

    /**
     * Server-driven paging: continuation lives in `@odata.nextLink`, an ABSOLUTE URL that must be followed
     * verbatim. No `$skip`/`$top` is fabricated. Casing variants are tolerated because Microsoft's docs never
     * name the property literally (recorded as a named residual) — the OData v4 standard name is tried first.
     */
    protected override ExtractPaginationInfo(
        rawBody: unknown,
        paginationType: PaginationType,
        _currentPage: number,
        _currentOffset: number,
        _pageSize: number,
    ): PaginationState {
        if (paginationType === 'None') return { HasMore: false };
        const nextLink = ExtractODataNextLink(rawBody);
        if (!nextLink) return { HasMore: false };
        return { HasMore: true, NextCursor: nextLink };
    }

    /**
     * Absolute-URL-safe pagination: a continuation cursor IS the next request URL, so it is returned verbatim.
     * Without a cursor the base path is used unchanged — Business Central drives the page size itself (the
     * client hint rides the `Prefer` header, never a query param).
     */
    protected override BuildPaginatedURL(
        basePath: string,
        _obj: MJIntegrationObjectEntity,
        _page: number,
        _offset: number,
        cursor?: string,
        _effectivePageSize?: number,
    ): string {
        if (cursor && /^https?:\/\//i.test(cursor)) return cursor;
        return basePath;
    }

    /** API root for the object's surface. The company + entity-set segments are appended by the fetch/CRUD paths. */
    protected override GetBaseURL(_companyIntegration: MJCompanyIntegrationEntity, auth: RESTAuthContext): string {
        const ctx = auth as BusinessCentralAuthContext;
        return BuildBusinessCentralRootURL('webapi', this.urlParts(ctx.Config, null));
    }

    /**
     * Captures the record's `@odata.etag` for the If-Match precondition on a later PATCH/DELETE. Returns the
     * raw record UNCHANGED (identity) so the base's fast path applies and every source key — including
     * `@odata.etag` itself — reaches `ExternalRecord.Fields`.
     */
    protected override TransformRecord(
        raw: Record<string, unknown>,
        obj: MJIntegrationObjectEntity,
        fields: MJIntegrationObjectFieldEntity[],
    ): Record<string, unknown> {
        const etag = raw[ETAG_PROPERTY];
        if (typeof etag === 'string' && etag.length > 0) {
            const id = this.recordIdentity(raw, this.primaryKeyNames(fields));
            if (id) this.etagCache.set(this.etagKey(obj.Name, id), etag);
        }
        return raw;
    }

    /** Maps an OData error payload to a SyncErrorCode off the CODE, never the message. */
    public ClassifyODataError(response: RESTResponse): SyncErrorCode {
        const code = this.odataErrorCode(response)?.toLowerCase() ?? '';
        if (response.Status === 429) return 'RATE_LIMIT_EXCEEDED';
        if (response.Status === 503 || response.Status === 504) return 'NETWORK_TIMEOUT';
        if (response.Status === 401) return 'CONFIGURATION_ERROR';
        if (response.Status === 403) return 'CONFIGURATION_ERROR';
        if (code.includes('unauthorized')) return 'CONFIGURATION_ERROR';
        if (code.includes('requestdatainvalid') || code.includes('badrequest') || code.includes('validation')) return 'VALIDATION_ERROR';
        if (code.includes('entitywithsamekeyexists') || code.includes('conflict')) return 'DUPLICATE_KEY';
        if (code.includes('notfound')) return 'MATCH_RESOLUTION_ERROR';
        if (code.includes('internal') || code.includes('server')) return 'CONNECTOR_ERROR';
        return 'UNKNOWN_ERROR';
    }

    /** Business Central error message extraction: `error.message` may be a string or `{value}`. */
    protected override ExtractErrorMessage(response: RESTResponse): string | undefined {
        if (!response.Body || typeof response.Body !== 'object') return undefined;
        const envelope = response.Body as ODataErrorEnvelope;
        const message = envelope.error?.message;
        if (typeof message === 'string') return message;
        if (message && typeof message === 'object' && typeof message.value === 'string') return message.value;
        return super.ExtractErrorMessage(response);
    }

    // ── FetchChanges — company-scoped access-path walk ────────────────

    /**
     * OVERRIDE (genuinely idiosyncratic — three reasons, none expressible through the generic base):
     *  1. The COMPANY segment is a connection-scoped path variable, not a synced-parent iteration: every
     *     company-scoped `APIPath` starts `/companies({id})` and the id comes from configuration (one, several,
     *     or every reachable company), not from a parent object's records.
     *  2. Multi-level paths repeat the SAME `{id}` token (`/companies({id})/journals({id})/journalLines`) —
     *     positionally distinct variables the base's name-keyed substitution would collapse to one value.
     *  3. Paging is a server-driven ABSOLUTE `@odata.nextLink` with a per-page resumable checkpoint spanning
     *     the company × parent expansion.
     *
     * The walk: resolve the company scope → expand each nested `{…}` segment by ENUMERATING the parent
     * collection at runtime (never a baked parent list) → page each concrete collection to exhaustion,
     * deduping by primary key → track max watermark. A batch-size stop returns a resume cursor; a thrown
     * error returns nothing, so the engine leaves the watermark untouched (partial-failure semantics).
     */
    public override async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
        const obj = this.GetCachedObject(ctx.CompanyIntegration.IntegrationID, ctx.ObjectName);
        const fields = this.GetCachedFields(obj.ID);
        const pkNames = this.primaryKeyNames(fields);
        const auth = await this.Authenticate(ctx.CompanyIntegration, ctx.ContextUser);
        const warnings: FetchWarning[] = [];

        const resume = DecodeResumeCursor(ctx.CurrentCursor);
        let pending: string[];
        let currentURL: string | undefined;
        if (resume) {
            pending = [...resume.r];
            currentURL = resume.u;
        } else {
            const collections = await this.ResolveCollections(auth, obj, ctx, warnings);
            pending = collections.map(c => c.URL);
            currentURL = pending.shift();
        }

        const records: ExternalRecord[] = [];
        const seen = new Set<string>();
        let maxWatermark: string | null = null;
        const batchLimit = ctx.BatchSize > 0 ? ctx.BatchSize : Number.MAX_SAFE_INTEGER;

        while (currentURL) {
            const response = await this.MakeHTTPRequest(auth, currentURL, 'GET', this.BuildHeaders(auth));
            if (response.Status === 403) {
                warnings.push({
                    Code: 'FORBIDDEN',
                    Message: `HTTP 403 for "${obj.Name}" — reachable but the app registration lacks permission for this resource; skipped.`,
                    Data: { url: currentURL },
                });
                currentURL = pending.shift();
                continue;
            }
            if (response.Status < 200 || response.Status >= 300) {
                throw new Error(
                    `Business Central fetch of "${obj.Name}" failed: HTTP ${response.Status} `
                    + `[${this.ClassifyODataError(response)}] ${this.ExtractErrorMessage(response) ?? ''}`.trim(),
                );
            }

            for (const raw of this.NormalizeResponse(response.Body, obj.ResponseDataKey)) {
                const transformed = this.applyTransformPreservingKeys(raw, obj, fields);
                const record = this.BuildExternalRecord(transformed, obj.Name, pkNames);
                if (seen.has(record.ExternalID)) continue; // dedupe by PK across pages/companies
                seen.add(record.ExternalID);
                records.push(record);
                maxWatermark = this.trackWatermark(maxWatermark, transformed, obj.IncrementalWatermarkField);
            }

            const state = this.ExtractPaginationInfo(response.Body, obj.PaginationType, 1, 0, obj.DefaultPageSize ?? 0);
            const nextLink = state.HasMore ? state.NextCursor : undefined;
            currentURL = nextLink ?? pending.shift();

            if (records.length >= batchLimit && currentURL) {
                // Per-page checkpoint: a long first sync resumes exactly here.
                return this.buildFetchResult(records, warnings, maxWatermark, true, EncodeResumeCursor({ u: currentURL, r: pending }));
            }
        }

        return this.buildFetchResult(records, warnings, maxWatermark, false, undefined);
    }

    // ── CRUD ──────────────────────────────────────────────────────────
    //
    // OVERRIDDEN for every write verb — genuinely idiosyncratic, not a re-implementation of the generic
    // dispatch. All three overrides still read the SAME per-operation metadata columns the base reads
    // (Create/Update/DeleteAPIPath + Method + BodyShape + BodyKey + IDLocation) and still route creates
    // through BuildCreatedResult. What they add, and why the base cannot:
    //   · the company + parent path segments (base substitutes the ExternalID into the FIRST `{id}` — which
    //     for Business Central is the COMPANY slot, producing a guaranteed 404);
    //   · the OData If-Match/@odata.etag precondition required on PATCH and DELETE, with one re-read + retry
    //     when the tag is stale;
    //   · serialized write pacing (never a parallel fan-out of journal-line POSTs).

    /** Create — company/parent-scoped POST. ID extraction + failure semantics stay on the base contract. */
    public override async CreateRecord(ctx: CreateRecordContext): Promise<CRUDResult> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const contextUser = ctx.ContextUser as UserInfo;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        if (!obj.CreateAPIPath || !obj.CreateMethod) {
            throw new Error(
                `CreateRecord not supported for "${ctx.ObjectName}": CreateAPIPath / CreateMethod not configured on IntegrationObject.`,
            );
        }
        const auth = await this.Authenticate(ci, contextUser);
        const url = this.ResolveWriteURL(auth, obj.CreateAPIPath, ctx.Attributes, null, this.ResolveSurface(obj));
        const body = this.BuildOperationBody(ctx.Attributes, obj.CreateBodyShape, obj.CreateBodyKey);
        const response = await this.PacedRequest(() => this.MakeHTTPRequest(auth, url, obj.CreateMethod as string, this.BuildHeaders(auth), body));
        if (response.Status >= 200 && response.Status < 300) {
            this.captureETagFromResponse(obj.Name, response);
            const externalID = this.extractCreatedID(obj, response);
            return this.BuildCreatedResult(externalID, response.Status, ctx.ObjectName);
        }
        return this.failureResult(response, 'create');
    }

    /**
     * Extracts the created record's ExternalID using the object's METADATA primary key before falling back
     * to the base's conventional `id`/`ID`/`externalID` scan.
     *
     * Most Business Central entities key on a plain `id`, which the base handles. Seven do NOT —
     * `subscriptions` (`subscriptionId`), `agedAccountsPayables`/`vendorPurchases` (`vendorId`),
     * `agedAccountsReceivables`/`customerSales` (`customerId`), `contactsInformation` (`contactId`), and
     * `trialBalances` (`accountId`). For those, the base scan finds nothing, so a perfectly successful
     * create (BC returns 201 with the new record) would be reported as a failure — and, worse, the record's
     * identity would be lost, so the next sync would create it AGAIN. That is exactly the duplicate-create
     * hazard `BuildCreatedResult`'s loud-on-empty-id invariant exists to prevent, so the fix belongs here
     * rather than in a weakened invariant.
     *
     * Reading `IsPrimaryKey` from the field cache keeps this metadata-driven: it needs no hardcoded list of
     * the seven, and it stays correct if the vendor's key naming changes or new objects are added.
     * Composite keys are delimiter-joined, matching `ToExternalRecord`'s convention.
     */
    private extractCreatedID(obj: MJIntegrationObjectEntity, response: RESTResponse): string | undefined {
        const created = this.NormalizeResponse(response.Body, obj.ResponseDataKey)[0];
        if (created) {
            const pkNames = this.GetCachedFields(obj.ID)
                .filter((f) => f.IsPrimaryKey)
                .sort((a, b) => a.Sequence - b.Sequence)
                .map((f) => f.Name);
            if (pkNames.length > 0 && pkNames.every((n) => created[n] != null && String(created[n]).length > 0)) {
                return pkNames.map((n) => String(created[n])).join('|');
            }
        }
        return this.ExtractIDFromResponse(response, obj.CreateIDLocation);
    }

    /** Update — company/parent-scoped PATCH with the required `If-Match`; one re-read + retry on a stale tag. */
    public override async UpdateRecord(ctx: UpdateRecordContext): Promise<CRUDResult> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const contextUser = ctx.ContextUser as UserInfo;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        if (!obj.UpdateAPIPath || !obj.UpdateMethod) {
            throw new Error(
                `UpdateRecord not supported for "${ctx.ObjectName}": UpdateAPIPath / UpdateMethod not configured on IntegrationObject.`,
            );
        }
        const auth = await this.Authenticate(ci, contextUser);
        const url = this.ResolveWriteURL(auth, obj.UpdateAPIPath, ctx.Attributes, ctx.ExternalID, this.ResolveSurface(obj));
        const body = this.BuildOperationBody(ctx.Attributes, obj.UpdateBodyShape, obj.UpdateBodyKey);
        const response = await this.ConditionalWrite(auth, obj, ctx.ObjectName, ctx.ExternalID, url, obj.UpdateMethod, body);
        if (response.Status >= 200 && response.Status < 300) {
            this.captureETagFromResponse(obj.Name, response);
            return { Success: true, StatusCode: response.Status, ExternalID: ctx.ExternalID };
        }
        return this.failureResult(response, 'update');
    }

    /** Delete — company/parent-scoped DELETE with the required `If-Match`; one re-read + retry on a stale tag. */
    public override async DeleteRecord(ctx: DeleteRecordContext): Promise<CRUDResult> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const contextUser = ctx.ContextUser as UserInfo;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        if (!obj.DeleteAPIPath || !obj.DeleteMethod) {
            throw new Error(
                `DeleteRecord not supported for "${ctx.ObjectName}": DeleteAPIPath / DeleteMethod not configured on IntegrationObject.`,
            );
        }
        const auth = await this.Authenticate(ci, contextUser);
        const url = this.ResolveWriteURL(auth, obj.DeleteAPIPath, {}, ctx.ExternalID, this.ResolveSurface(obj));
        const response = await this.ConditionalWrite(auth, obj, ctx.ObjectName, ctx.ExternalID, url, obj.DeleteMethod, undefined);
        if (response.Status >= 200 && response.Status < 300) {
            this.etagCache.delete(this.etagKey(obj.Name, ctx.ExternalID));
            return { Success: true, StatusCode: response.Status, ExternalID: ctx.ExternalID };
        }
        return this.failureResult(response, 'delete');
    }

    // ── Configuration resolution ──────────────────────────────────────

    /**
     * Resolves the connection configuration from (in precedence order) the linked Credential's `Values` JSON,
     * the CompanyIntegration `Configuration` JSON, and finally the LEGACY CompanyIntegration column overloads
     * documented in ContextBC.md §2.2 — `APIKey` actually holds the AZURE TENANT ID and `ExternalSystemID`
     * actually holds the BC COMPANY GUID. Those overloads are enforced by nothing upstream, so they are
     * mapped here explicitly rather than by name-resemblance.
     */
    public async ResolveConfig(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<BusinessCentralConnectionConfig> {
        const cacheKey = companyIntegration.ID;
        const cached = this.configCache.get(cacheKey);
        if (cached) return cached;

        const fromConfig = companyIntegration.Configuration ? parseJsonObject(companyIntegration.Configuration) : null;
        const fromCredential = companyIntegration.CredentialID
            ? await this.loadCredentialValues(companyIntegration.CredentialID, contextUser)
            : null;
        const merged: Record<string, unknown> = { ...(fromConfig ?? {}), ...(fromCredential ?? {}) };

        const clientId = firstString(merged, ['ClientId', 'clientId', 'ClientID', 'client_id'])
            ?? companyIntegration.ClientID ?? '';
        const clientSecret = firstString(merged, ['ClientSecret', 'clientSecret', 'client_secret'])
            ?? companyIntegration.ClientSecret ?? '';
        // §2.2 overload: the legacy CompanyIntegration.APIKey column carries the AZURE TENANT ID.
        const tenantId = firstString(merged, ['TenantId', 'tenantId', 'TenantID', 'tenant_id', 'AzureTenantId'])
            ?? companyIntegration.APIKey ?? '';
        // §2.2 overload: the legacy CompanyIntegration.ExternalSystemID column carries the BC COMPANY GUID.
        const companyId = firstString(merged, ['CompanyId', 'companyId', 'CompanyID', 'company_id', 'BusinessCentralCompanyId'])
            ?? companyIntegration.ExternalSystemID ?? undefined;
        const environment = firstString(merged, ['Environment', 'environment', 'EnvironmentName', 'environmentName']);

        if (!clientId || !clientSecret) {
            throw new Error('Business Central connector: ClientId / ClientSecret not found on the Credential, the Configuration JSON, or the CompanyIntegration.');
        }
        if (!tenantId) {
            throw new Error('Business Central connector: TenantId not found. Note the legacy convention — CompanyIntegration.APIKey holds the AZURE TENANT ID, not an API key.');
        }
        if (!environment) {
            throw new Error(
                'Business Central connector: Environment is REQUIRED and is never defaulted. Set it explicitly '
                + '(e.g. "Production" or your sandbox name) — the replaced driver hardcoded "Production", so a stage run '
                + 'of the write path posted into the production ledger.',
            );
        }

        const config: BusinessCentralConnectionConfig = {
            ClientId: clientId,
            ClientSecret: clientSecret,
            TenantId: tenantId,
            Server: firstString(merged, ['Server', 'server', 'BaseURL', 'baseUrl', 'ServerURL']) ?? DEFAULT_SERVER,
            AuthorityHost: firstString(merged, ['AuthorityHost', 'authorityHost', 'Authority', 'AuthorityURL']) ?? DEFAULT_AUTHORITY_HOST,
            Scope: firstString(merged, ['Scope', 'scope', 'Scopes']) ?? DEFAULT_SCOPE,
            Environment: environment,
            ApiVersion: firstString(merged, ['ApiVersion', 'apiVersion', 'APIVersion']) ?? DEFAULT_API_VERSION,
            IncludeTenantSegment: firstBoolean(merged, ['IncludeTenantSegment', 'includeTenantSegment', 'UseTenantSegment']) ?? true,
            CompanyId: companyId,
            CompanyIds: firstStringArray(merged, ['CompanyIds', 'companyIds', 'Companies']),
            AllCompanies: firstBoolean(merged, ['AllCompanies', 'allCompanies', 'SyncAllCompanies']) ?? false,
            WritePacingMs: firstNumber(merged, ['WritePacingMs', 'writePacingMs']) ?? DEFAULT_WRITE_PACING_MS,
            MaxPageSize: firstNumber(merged, ['MaxPageSize', 'maxPageSize', 'ODataMaxPageSize']),
            MaxParentFanout: firstNumber(merged, ['MaxParentFanout', 'maxParentFanout']) ?? DEFAULT_MAX_PARENT_FANOUT,
            UseSelect: firstBoolean(merged, ['UseSelect', 'useSelect']) ?? false,
            IfMatchFallback: firstString(merged, ['IfMatchFallback', 'ifMatchFallback']) === 'fail' ? 'fail' : 'wildcard',
            MaxRetries: firstNumber(merged, ['MaxRetries', 'maxRetries']) ?? DEFAULT_MAX_RETRIES,
        };
        this.configCache.set(cacheKey, config);
        return config;
    }

    // ── Surface selection ─────────────────────────────────────────────

    /**
     * Which of the two Business Central grammars serves an object, in precedence order:
     *  1. the object's OWN declared surface tag (`IntegrationObject.Configuration.surface`);
     *  2. the surface it was observed on during runtime `$metadata` discovery (a tenant-published ODataV4
     *     page such as `Detailed_Customer_Ledger_Entries` lands here);
     *  3. `webapi` — the standard API-v2.0 surface every Declared object in the frozen contract uses.
     *
     * This is what makes the dual-surface builder reachable at FETCH and WRITE time, not only in discovery:
     * an ODataV4 page addressed with webapi grammar (or vice-versa) yields a 404, not a validation error.
     */
    protected ResolveSurface(obj: MJIntegrationObjectEntity): BusinessCentralSurface {
        const declared = obj.Configuration ? parseJsonObject(obj.Configuration) : null;
        const tag = declared ? firstString(declared, ['surface', 'Surface', 'apiSurface', 'APISurface']) : undefined;
        if (tag && tag.toLowerCase() === 'odatav4') return 'odatav4';
        if (tag && tag.toLowerCase() === 'webapi') return 'webapi';
        return this.discoveredSurfaces.get(obj.Name.toLowerCase()) ?? 'webapi';
    }

    // ── Collection resolution (the access-path walk) ──────────────────

    /**
     * Expands one IntegrationObject's `APIPath` into the concrete collection URLs to walk:
     * company scope × every nested parent segment. Nested parents are ENUMERATED at runtime from the API
     * (never a baked list), bounded by `MaxParentFanout`. Emits a FetchWarning when a nested object resolves
     * to zero parents (the classic silent-empty) or when the fan-out cap truncates the walk.
     */
    protected async ResolveCollections(
        auth: BusinessCentralAuthContext,
        obj: MJIntegrationObjectEntity,
        ctx: FetchContext,
        warnings: FetchWarning[],
    ): Promise<ResolvedCollection[]> {
        const surface = this.ResolveSurface(obj);
        const segments = ParsePathSegments(obj.APIPath);
        // webapi: company scoping is expressed as the leading `companies({id})` segment of the declared path.
        // odatav4: the published-page path carries NO company segment — `Company('{id}')` is always prepended.
        const companyScoped = surface === 'odatav4'
            || (segments.length > 1 && segments[0].Name.toLowerCase() === 'companies');
        const companyIds = companyScoped ? await this.ResolveCompanyScope(auth) : [null];
        const query = this.BuildCollectionQuery(obj, ctx);
        const out: ResolvedCollection[] = [];

        for (const companyId of companyIds) {
            const bases = await this.expandNestedSegments(auth, obj, surface, segments, companyId, warnings);
            for (const base of bases) {
                out.push({ URL: AppendQueryString(base, query), CompanyId: companyId ?? undefined });
            }
        }
        if (out.length === 0) {
            warnings.push({
                Code: 'ZERO_COLLECTIONS',
                Message: `No collection URL could be resolved for "${obj.Name}" — no company in scope, or no parent records for its nested access path.`,
                Data: { apiPath: obj.APIPath },
            });
        }
        return out;
    }

    /**
     * The companies in scope for this run: the explicit list (multi-company), the single configured company,
     * or — when configured to — every company the credential can reach, enumerated from the `companies` root.
     */
    protected async ResolveCompanyScope(auth: BusinessCentralAuthContext): Promise<(string | null)[]> {
        const config = auth.Config;
        const explicit = [
            ...(config.CompanyIds ?? []),
            ...(config.CompanyId ? [config.CompanyId] : []),
        ].filter((v, i, arr) => v.length > 0 && arr.indexOf(v) === i);
        if (!config.AllCompanies && explicit.length > 0) return explicit;

        const url = BuildBusinessCentralResourceURL('webapi', this.urlParts(config, null), 'companies');
        const response = await this.MakeHTTPRequest(auth, url, 'GET', this.BuildHeaders(auth));
        if (response.Status < 200 || response.Status >= 300) {
            if (explicit.length > 0) return explicit;
            throw new Error(`Business Central could not enumerate companies: HTTP ${response.Status} ${this.ExtractErrorMessage(response) ?? ''}`.trim());
        }
        const discovered = this.NormalizeResponse(response.Body, 'value')
            .map(r => (typeof r.id === 'string' ? r.id : null))
            .filter((v): v is string => v !== null);
        return discovered.length > 0 ? discovered : (explicit.length > 0 ? explicit : [null]);
    }

    /**
     * Walks the nested `{…}` segments of an access path, enumerating each intermediate collection's ids at
     * runtime. `/companies({id})/journals({id})/journalLines` → for the company in scope, enumerate `journals`,
     * then emit one `…/journals({journalId})/journalLines` URL per journal. Depth-0 (a flat top-level set) is
     * the empty-expansion case and returns a single URL.
     */
    private async expandNestedSegments(
        auth: BusinessCentralAuthContext,
        obj: MJIntegrationObjectEntity,
        surface: BusinessCentralSurface,
        segments: PathSegment[],
        companyId: string | null,
        warnings: FetchWarning[],
    ): Promise<string[]> {
        const config = auth.Config;
        const root = BuildBusinessCentralRootURL(surface, this.urlParts(config, companyId));
        let prefixes: string[] = [root];

        // On the ODataV4 surface the company segment is NOT part of the declared page path — prepend it here,
        // single-quoted (`Company('{guid}')`), which is the one place the two grammars genuinely diverge.
        if (surface === 'odatav4') {
            if (!companyId) {
                warnings.push({
                    Code: 'NO_COMPANY_IN_SCOPE',
                    Message: `"${obj.Name}" is served by the ODataV4 surface, which is always company-scoped, but no company GUID is configured or reachable.`,
                });
                return [];
            }
            prefixes = [`${root}/${BuildBusinessCentralCompanySegment('odatav4', companyId)}`];
        }

        for (let i = 0; i < segments.length; i++) {
            const segment = segments[i];
            const isCompanySegment = i === 0
                && (segment.Name.toLowerCase() === 'companies' || segment.Name.toLowerCase() === 'company')
                && segment.HasKey;
            if (isCompanySegment) {
                // Already prepended on odatav4; skip so it is never emitted twice.
                if (surface === 'odatav4') continue;
                if (!companyId) {
                    warnings.push({
                        Code: 'NO_COMPANY_IN_SCOPE',
                        Message: `"${obj.Name}" is company-scoped but no company GUID is configured or reachable.`,
                    });
                    return [];
                }
                prefixes = prefixes.map(p => `${p}/${BuildBusinessCentralCompanySegment('webapi', companyId)}`);
                continue;
            }
            if (!segment.HasKey) {
                prefixes = prefixes.map(p => `${p}/${segment.Name}`);
                continue;
            }
            // A keyed intermediate segment: enumerate the parent collection's ids at runtime.
            const expanded: string[] = [];
            for (const prefix of prefixes) {
                const parentIds = await this.enumerateParentIds(auth, `${prefix}/${segment.Name}`, config.MaxParentFanout);
                if (parentIds.length === 0) {
                    warnings.push({
                        Code: 'ZERO_PARENTS',
                        Message: `"${obj.Name}" found zero "${segment.Name}" parents — its nested collection cannot be reached, so this object contributes no rows.`,
                        Data: { parentCollection: `${prefix}/${segment.Name}` },
                    });
                    continue;
                }
                if (parentIds.length >= config.MaxParentFanout) {
                    warnings.push({
                        Code: 'PARENT_FANOUT_CAPPED',
                        Message: `"${obj.Name}" parent enumeration of "${segment.Name}" hit the MaxParentFanout cap (${config.MaxParentFanout}); later parents were not walked.`,
                    });
                }
                for (const id of parentIds) {
                    expanded.push(`${prefix}/${segment.Name}(${encodeURIComponent(id)})`);
                }
            }
            prefixes = expanded;
        }
        return prefixes;
    }

    /** Enumerates the `id` values of a parent collection, following continuation links up to the fan-out cap. */
    private async enumerateParentIds(auth: BusinessCentralAuthContext, collectionURL: string, cap: number): Promise<string[]> {
        const ids: string[] = [];
        let url: string | undefined = collectionURL;
        while (url && ids.length < cap) {
            const response: RESTResponse = await this.MakeHTTPRequest(auth, url, 'GET', this.BuildHeaders(auth));
            if (response.Status < 200 || response.Status >= 300) break;
            for (const record of this.NormalizeResponse(response.Body, 'value')) {
                const id = record.id;
                if (typeof id === 'string' && id.length > 0) ids.push(id);
                if (ids.length >= cap) break;
            }
            url = ExtractODataNextLink(response.Body) ?? undefined;
        }
        return ids;
    }

    /**
     * Builds the query string for a collection read: the incremental `$filter` (ONLY for objects whose
     * metadata declares both `SupportsIncrementalSync` and an `IncrementalWatermarkField` — a watermark filter
     * is never sent to an object that does not support it), an optional `$select` narrowing, and a
     * metadata-DECLARED `$expand`.
     *
     * `$expand` is the structural replacement for the legacy driver's N+1 per-record ledger lookups
     * (ContextBC.md §5/§7.3): the related collection rides the SAME response instead of one extra GET per
     * parent record. It is read from the object's own `IntegrationObject.Configuration.expand` (a string or
     * a string array) — MECHANISM driven by metadata, never a navigation-property list baked into this file.
     * No declared expand ⇒ no `$expand` emitted, so this can never invent a navigation property the contract
     * does not carry. (This connector issues no per-record lookups at all, so the N+1 shape is structurally
     * absent even before an expand is declared.)
     */
    protected BuildCollectionQuery(obj: MJIntegrationObjectEntity, ctx: FetchContext): string {
        const parts: string[] = [];
        if (ctx.WatermarkValue && obj.SupportsIncrementalSync && obj.IncrementalWatermarkField) {
            const literal = ODataDateTimeOffsetLiteral(ctx.WatermarkValue);
            // Edm.DateTimeOffset literals are UNQUOTED in OData v4; the whole expression is URL-encoded.
            parts.push(`$filter=${encodeURIComponent(`${obj.IncrementalWatermarkField} gt ${literal}`)}`);
        }
        const config = this.configCache.get(ctx.CompanyIntegration.ID);
        if (config?.UseSelect && ctx.RequestedSourceFields && ctx.RequestedSourceFields.length > 0) {
            parts.push(`$select=${encodeURIComponent(ctx.RequestedSourceFields.join(','))}`);
        }
        const expand = this.DeclaredExpand(obj);
        if (expand.length > 0) {
            parts.push(`$expand=${encodeURIComponent(expand.join(','))}`);
        }
        return parts.join('&');
    }

    /**
     * The navigation properties this object's metadata declares for `$expand`, from
     * `IntegrationObject.Configuration.expand` (string, comma-delimited string, or string array).
     * Empty when the contract declares none — nothing is guessed.
     */
    protected DeclaredExpand(obj: MJIntegrationObjectEntity): string[] {
        const declared = obj.Configuration ? parseJsonObject(obj.Configuration) : null;
        if (!declared) return [];
        const asArray = firstStringArray(declared, ['expand', 'Expand', 'expandNavigationProperties']);
        if (asArray && asArray.length > 0) return asArray;
        const asString = firstString(declared, ['expand', 'Expand', 'expandNavigationProperties']);
        return asString ? asString.split(',').map(v => v.trim()).filter(v => v.length > 0) : [];
    }

    // ── Write helpers ─────────────────────────────────────────────────

    /**
     * Resolves a write path template into an absolute URL: the company segment from configuration, each
     * intermediate keyed segment from the record's own attributes (`journals({id})` ← `journalId`), and the
     * final keyed segment from the ExternalID. Fails loudly rather than issuing a request with an
     * unresolved segment key.
     */
    protected ResolveWriteURL(
        auth: BusinessCentralAuthContext,
        template: string,
        attributes: Record<string, unknown>,
        externalID: string | null,
        surface: BusinessCentralSurface = 'webapi',
    ): string {
        const config = auth.Config;
        const parsed = ParsePathSegments(template);
        // On odatav4 the company segment is prepended below in its quoted form, so drop any declared one
        // rather than emitting it twice (and keep the keyed-segment indexing consistent).
        const segments = surface === 'odatav4'
            && parsed.length > 0
            && parsed[0].HasKey
            && ['companies', 'company'].includes(parsed[0].Name.toLowerCase())
            ? parsed.slice(1)
            : parsed;
        const companyId = this.writeCompanyId(config, attributes);
        const idComponents = externalID != null ? String(externalID).split('|') : [];
        const keyedSegments = segments.filter(s => s.HasKey);
        let keyedIndex = 0;
        let url = BuildBusinessCentralRootURL(surface, this.urlParts(config, companyId));

        // ODataV4 published pages carry no company segment in their declared path — prepend the quoted form.
        if (surface === 'odatav4') {
            if (!companyId) {
                throw new Error(
                    `Business Central write of "${template}": the ODataV4 surface is always company-scoped but no company GUID `
                    + 'is configured on the connection or present on the record.',
                );
            }
            url += `/${BuildBusinessCentralCompanySegment('odatav4', companyId)}`;
        }

        for (let i = 0; i < segments.length; i++) {
            const segment = segments[i];
            if (!segment.HasKey) {
                url += `/${segment.Name}`;
                continue;
            }
            const isCompanySegment = i === 0
                && (segment.Name.toLowerCase() === 'companies' || segment.Name.toLowerCase() === 'company');
            const isFinalKeyed = keyedIndex === keyedSegments.length - 1;
            keyedIndex++;
            let value: string | undefined;
            if (isCompanySegment) {
                value = companyId ?? undefined;
            } else if (isFinalKeyed && externalID != null) {
                value = idComponents[idComponents.length - 1];
            } else {
                value = this.parentKeyFromAttributes(segment.Name, attributes)
                    ?? idComponents[keyedIndex - 2];
            }
            if (value === undefined || value === null || value === '') {
                throw new Error(
                    `Business Central write of "${template}": could not resolve the key for segment "${segment.Name}". `
                    + `Supply it on the record (e.g. "${singularize(segment.Name)}Id") or in the connection configuration.`,
                );
            }
            url += `/${segment.Name}(${segment.QuotedKey ? ODataStringLiteral(value) : encodeURIComponent(value)})`;
        }
        return url;
    }

    /**
     * Executes a PATCH/DELETE with the OData `If-Match` precondition. The tag comes from the read-time ETag
     * cache; when unknown it is re-read from the record (a single GET). A precondition failure (412, or a
     * Business Central `conflict`-class code) triggers ONE re-read + retry with the fresh tag.
     */
    protected async ConditionalWrite(
        auth: BusinessCentralAuthContext,
        obj: MJIntegrationObjectEntity,
        objectName: string,
        externalID: string,
        url: string,
        method: string,
        body: unknown,
    ): Promise<RESTResponse> {
        let etag = this.etagCache.get(this.etagKey(obj.Name, externalID)) ?? await this.readETag(auth, url, obj.Name, externalID);
        if (!etag) {
            if (auth.Config.IfMatchFallback === 'fail') {
                throw new Error(
                    `Business Central ${method} of "${objectName}" (${externalID}): no @odata.etag could be resolved and `
                    + 'IfMatchFallback is "fail". Read the record first, or set IfMatchFallback="wildcard" to bypass the concurrency check.',
                );
            }
            etag = '*';
        }
        const send = (tag: string): Promise<RESTResponse> => this.PacedRequest(
            () => this.MakeHTTPRequest(auth, url, method, { ...this.BuildHeaders(auth), 'If-Match': tag }, body),
        );

        const first = await send(etag);
        if (first.Status !== 412 && !this.isPreconditionFailure(first)) return first;
        const fresh = await this.readETag(auth, url, obj.Name, externalID);
        if (!fresh) return first;
        return send(fresh);
    }

    /** GETs the target record purely to read its `@odata.etag` (also refreshes the cache). */
    private async readETag(auth: BusinessCentralAuthContext, url: string, objectName: string, externalID: string): Promise<string | null> {
        const response = await this.MakeHTTPRequest(auth, url, 'GET', this.BuildHeaders(auth));
        if (response.Status < 200 || response.Status >= 300) return null;
        const etag = this.etagFromBody(response.Body) ?? (typeof response.Headers?.['etag'] === 'string' ? response.Headers['etag'] : null);
        if (etag) this.etagCache.set(this.etagKey(objectName, externalID), etag);
        return etag;
    }

    /**
     * Serializes writes and applies `writePacingMs` between them. Context-empirical (the replaced driver's
     * only rate control was a hardcoded 500 ms sleep before every POST) — preserved deliberately so a
     * journal-line push is never a naive parallel fan-out, and configurable because 500 ms is a port artifact,
     * not a Microsoft-documented limit.
     */
    protected PacedRequest<T>(operation: () => Promise<T>): Promise<T> {
        const pacingMs = this.lastKnownWritePacingMs();
        const run = this.writeChain.then(async () => {
            if (pacingMs > 0) await this.sleep(pacingMs);
            return operation();
        });
        this.writeChain = run.then(() => undefined, () => undefined);
        return run;
    }

    // ── Small helpers ─────────────────────────────────────────────────

    /** URL parts for a surface build, honoring the tenant-segment form choice. */
    private urlParts(config: BusinessCentralConnectionConfig, companyId: string | null): BusinessCentralURLParts {
        return {
            Server: config.Server,
            TenantId: config.IncludeTenantSegment ? config.TenantId : null,
            Environment: config.Environment,
            ApiVersion: config.ApiVersion,
            CompanyId: companyId,
        };
    }

    /**
     * Acquires (or reuses) a non-expired access token via the shared OAuth2 client-credentials helper.
     * `protected` so a test subclass can stub token minting WITHOUT stubbing the transport — that keeps the
     * real per-request token-refresh / 401-re-acquire logic in {@link MakeHTTPRequest} under test.
     */
    protected async acquireAccessToken(config: BusinessCentralConnectionConfig): Promise<string> {
        const token = await this.tokenManager.GetAccessToken(
            {
                TokenURL: `${trimTrailingSlash(config.AuthorityHost)}/${encodeURIComponent(config.TenantId)}/oauth2/v2.0/token`,
                ClientId: config.ClientId,
                ClientSecret: config.ClientSecret,
                Scopes: config.Scope,
            },
            'client_credentials',
        );
        return token.AccessToken;
    }

    /** True when the last-resolved connection targets a production environment (drives the documented rate). */
    private isProductionEnvironment(): boolean {
        for (const config of this.configCache.values()) {
            if (config.Environment.trim().toLowerCase() === 'production') return true;
        }
        return false;
    }

    /** Pacing value from the last-resolved connection (falls back to the documented port artifact default). */
    private lastKnownWritePacingMs(): number {
        let pacing = DEFAULT_WRITE_PACING_MS;
        for (const config of this.configCache.values()) pacing = config.WritePacingMs;
        return pacing;
    }

    /** Company GUID for a write: the record's own `companyId` attribute wins, else the configured company. */
    private writeCompanyId(config: BusinessCentralConnectionConfig, attributes: Record<string, unknown>): string | null {
        const fromRecord = attributes['companyId'] ?? attributes['CompanyId'];
        if (typeof fromRecord === 'string' && fromRecord.length > 0) return fromRecord;
        return config.CompanyId ?? config.CompanyIds?.[0] ?? null;
    }

    /** Resolves a parent segment's key from the record's attributes (`journals` → `journalId`/`journalID`). */
    private parentKeyFromAttributes(segmentName: string, attributes: Record<string, unknown>): string | undefined {
        const singular = singularize(segmentName);
        // Named-parent candidates first (`journalLines` carries `journalId`), then Business Central's
        // GENERIC sub-entity parent key: entities reachable under several different parent documents
        // — dimensionSetLines (salesOrders / purchaseInvoices / journals / …), documentAttachments —
        // do not carry a `<parent>Id` field at all. BC models them with `parentId` + `parentType`, so
        // `parentId` is the only key such a record can supply for its parent segment.
        const candidates = [
            `${singular}Id`, `${singular}ID`, `${singular}_id`, `${segmentName}Id`, singular, segmentName,
            'parentId', 'parentID',
        ];
        for (const key of candidates) {
            const value = attributes[key];
            if (typeof value === 'string' && value.length > 0) return value;
            if (typeof value === 'number') return String(value);
        }
        return undefined;
    }

    /** PK field names for an object, ordered by Sequence; `['id']` when the metadata declares none. */
    private primaryKeyNames(fields: MJIntegrationObjectFieldEntity[]): string[] {
        const pk = fields.filter(f => f.IsPrimaryKey).sort((a, b) => a.Sequence - b.Sequence).map(f => f.Name);
        return pk.length > 0 ? pk : ['id'];
    }

    /**
     * Builds an ExternalRecord with FULL-RECORD pass-through (`Fields` is the complete source record — never a
     * filtered literal), mirroring the base's composite-PK join and content-hash identity fallback.
     */
    protected BuildExternalRecord(raw: Record<string, unknown>, objectType: string, pkNames: string[]): ExternalRecord {
        const allPresent = pkNames.length > 0 && pkNames.every(n => raw[n] != null && serializeKeyValue(raw[n]).length > 0);
        const joined = pkNames.map(n => serializeKeyValue(raw[n])).join('|');
        const externalID = allPresent ? joined : computeContentHash(raw);
        let fields = raw;
        if (!allPresent && pkNames.length === 1) {
            fields = { ...raw, [pkNames[0]]: externalID };
        }
        return { ExternalID: externalID, ObjectType: objectType, Fields: fields };
    }

    /** The record's identity string for the ETag cache (composite PKs join with `|`, matching ExternalID). */
    private recordIdentity(raw: Record<string, unknown>, pkNames: string[]): string | null {
        const values = pkNames.map(n => (raw[n] == null ? '' : serializeKeyValue(raw[n])));
        if (values.some(v => v.length === 0)) return null;
        return values.join('|');
    }

    /** Tracks the max watermark seen; string comparison is safe for ISO-8601 / OData date-time values. */
    private trackWatermark(current: string | null, raw: Record<string, unknown>, watermarkField: string | null): string | null {
        if (!watermarkField) return current;
        const value = raw[watermarkField];
        if (typeof value !== 'string' || value.length === 0) return current;
        if (current === null) return value;
        return value > current ? value : current;
    }

    /** Assembles the FetchBatchResult, omitting empty optional members. */
    private buildFetchResult(
        records: ExternalRecord[],
        warnings: FetchWarning[],
        maxWatermark: string | null,
        hasMore: boolean,
        nextCursor: string | undefined,
    ): FetchBatchResult {
        const result: FetchBatchResult = { Records: records, HasMore: hasMore };
        if (warnings.length > 0) result.Warnings = warnings;
        if (maxWatermark) result.NewWatermarkValue = maxWatermark;
        if (nextCursor) result.NextCursor = nextCursor;
        return result;
    }

    /** Failure CRUDResult carrying the classified error code alongside the vendor message. */
    private failureResult(response: RESTResponse, operation: string): CRUDResult {
        const code = this.ClassifyODataError(response);
        return {
            Success: false,
            StatusCode: response.Status,
            ErrorMessage: `[${code}] ${this.ExtractErrorMessage(response) ?? `HTTP ${response.Status} on ${operation}`}`,
        };
    }

    /** True when a response looks like an OData concurrency precondition failure. */
    private isPreconditionFailure(response: RESTResponse): boolean {
        if (response.Status === 412) return true;
        const code = this.odataErrorCode(response)?.toLowerCase() ?? '';
        return code.includes('preconditionfailed') || code.includes('etagmismatch');
    }

    /** Reads `error.code` from an OData error envelope. */
    private odataErrorCode(response: RESTResponse): string | undefined {
        if (!response.Body || typeof response.Body !== 'object') return undefined;
        const code = (response.Body as ODataErrorEnvelope).error?.code;
        return typeof code === 'string' ? code : undefined;
    }

    /** Captures the `@odata.etag` from a write response body, when the vendor echoed the record back. */
    private captureETagFromResponse(objectName: string, response: RESTResponse): void {
        const etag = this.etagFromBody(response.Body);
        if (!etag) return;
        const body = response.Body as Record<string, unknown>;
        const id = typeof body.id === 'string' ? body.id : null;
        if (id) this.etagCache.set(this.etagKey(objectName, id), etag);
    }

    /** Reads the concurrency token off a record body. */
    private etagFromBody(body: unknown): string | null {
        if (!body || typeof body !== 'object') return null;
        const value = (body as Record<string, unknown>)[ETAG_PROPERTY];
        return typeof value === 'string' && value.length > 0 ? value : null;
    }

    /** Cache key for a record's ETag. */
    private etagKey(objectName: string, externalID: string): string {
        return `${objectName}|${externalID}`;
    }

    /** Declared fields for an object, tolerating an object that is not in the persisted metadata cache. */
    private async safeDeclaredFields(
        companyIntegration: MJCompanyIntegrationEntity,
        objectName: string,
        contextUser: UserInfo,
    ): Promise<ExternalFieldSchema[]> {
        try {
            return await super.DiscoverFields(companyIntegration, objectName, contextUser);
        } catch {
            return [];
        }
    }

    /**
     * The cached IntegrationObject for a name, or null when the metadata cache has no such object.
     * `StableOrderingKey` is ADVISORY — an unknown object must degrade to null, never throw.
     */
    private findCachedObject(objectName: string): MJIntegrationObjectEntity | null {
        const integrationID = this.cachedIntegrationID;
        if (!integrationID) return null;
        try {
            return this.GetCachedObject(integrationID, objectName);
        } catch {
            return null;
        }
    }

    /**
     * IntegrationID observed on the most recent Authenticate call (i.e. every fetch/CRUD/discovery entry
     * point) — used only for advisory metadata lookups such as {@link StableOrderingKey}, which the engine
     * may call outside a fetch and which must therefore never depend on a live connection.
     */
    private cachedIntegrationID: string | null = null;

    /**
     * Fetches a `$metadata` (EDMX) document for a surface. Returns null when no credential/connection is
     * available or the endpoint is not reachable — discovery then falls back to the credential-free Declared
     * baseline, which is what keeps a keyless structure check green.
     */
    private async tryFetchMetadataDocument(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
        surface: BusinessCentralSurface,
    ): Promise<string | null> {
        try {
            const auth = await this.Authenticate(companyIntegration, contextUser);
            const url = `${BuildBusinessCentralRootURL(surface, this.urlParts(auth.Config, null))}/$metadata`;
            const response = await this.MakeHTTPRequest(auth, url, 'GET', { ...this.BuildHeaders(auth), 'Accept': 'application/xml' });
            if (response.Status < 200 || response.Status >= 300) return null;
            return typeof response.Body === 'string' ? response.Body : null;
        } catch {
            return null;
        }
    }

    /** Loads a Credential row and parses its `Values` JSON. */
    private async loadCredentialValues(credentialID: string, contextUser: UserInfo): Promise<Record<string, unknown> | null> {
        const md = new Metadata();
        const credential = await md.GetEntityObject<MJCredentialEntity>('MJ: Credentials', contextUser);
        const loaded = await credential.Load(credentialID);
        if (!loaded || !credential.Values) return null;
        return parseJsonObject(credential.Values);
    }

    /** Pulls response headers off a thrown transport error, when the caller attached them. */
    private extractHeadersFromError(error: unknown): Record<string, string> | null {
        if (!error || typeof error !== 'object') return null;
        const candidate = error as { Headers?: unknown; headers?: unknown; response?: { Headers?: unknown; headers?: unknown } };
        const headers = candidate.Headers ?? candidate.headers ?? candidate.response?.Headers ?? candidate.response?.headers;
        if (!headers || typeof headers !== 'object') return null;
        const out: Record<string, string> = {};
        for (const [key, value] of Object.entries(headers as Record<string, unknown>)) {
            if (typeof value === 'string') out[key.toLowerCase()] = value;
        }
        return out;
    }

    /** Computes a throttle backoff, honoring an observed `Retry-After` when the response carried one. */
    private computeBackoffMs(response: RESTResponse, attempt: number): number {
        const hinted = this.ExtractRetryAfterMs({ Headers: response.Headers });
        if (hinted !== undefined) return Math.min(hinted, 60_000);
        return Math.min(1_000 * Math.pow(2, attempt) + Math.floor(Math.random() * 250), 60_000);
    }

    /** Narrows an unknown thrown value to a message (never `catch (error: any)`). */
    private errorMessage(error: unknown): string {
        return error instanceof Error ? error.message : String(error);
    }

    /** Sleep helper. */
    protected sleep(ms: number): Promise<void> {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}

// ─── Path parsing (exported for unit testing) ────────────────────────────

/** One `/name` or `/name({key})` segment of an OData path template. */
export interface PathSegment {
    /** Segment name (the entity set / navigation property). */
    Name: string;
    /** Whether the segment carries a key predicate. */
    HasKey: boolean;
    /** Whether the key predicate is single-quoted (string key, e.g. `subscriptions('{id}')`). */
    QuotedKey: boolean;
}

/**
 * Parses an OData path template into segments. Handles the two key forms Business Central's reference pages
 * use — unquoted GUID keys `companies({id})` and quoted string keys `subscriptions('{id}')` — and tolerates
 * the transposed-quote form present on one documented path.
 */
export function ParsePathSegments(path: string): PathSegment[] {
    const segments: PathSegment[] = [];
    for (const rawSegment of path.split('/')) {
        const segment = rawSegment.trim();
        if (segment.length === 0) continue;
        const match = segment.match(/^([^(]+)(\((.*)\))?$/);
        if (!match) {
            segments.push({ Name: segment, HasKey: false, QuotedKey: false });
            continue;
        }
        const name = match[1];
        const hasKey = match[2] !== undefined;
        const keyBody = match[3] ?? '';
        segments.push({ Name: name, HasKey: hasKey, QuotedKey: hasKey && keyBody.includes("'") });
    }
    return segments;
}

/** Naive singularization used only to derive an attribute name from a segment (`journals` → `journal`). */
export function singularize(name: string): string {
    if (name.endsWith('ies')) return `${name.slice(0, -3)}y`;
    if (name.endsWith('sses') || name.endsWith('shes') || name.endsWith('ches')) return name.slice(0, -2);
    if (name.endsWith('s') && !name.endsWith('ss')) return name.slice(0, -1);
    return name;
}

// ─── Continuation + resume helpers (exported for unit testing) ───────────

/**
 * Reads the server-driven continuation link from an OData response body. The OData v4 standard name
 * (`@odata.nextLink`) is tried first; casing/prefix variants are tolerated because Microsoft's Business
 * Central documentation never names the property literally (a recorded named residual, not an assumption).
 */
export function ExtractODataNextLink(body: unknown): string | null {
    if (!body || typeof body !== 'object' || Array.isArray(body)) return null;
    const envelope = body as ODataCollectionEnvelope & Record<string, unknown>;
    const direct = envelope['@odata.nextLink'];
    if (typeof direct === 'string' && direct.length > 0) return direct;
    for (const [key, value] of Object.entries(envelope)) {
        if (key.toLowerCase().replace(/^@/, '').replace('odata.', '') !== 'nextlink') continue;
        if (typeof value === 'string' && value.length > 0) return value;
    }
    return null;
}

/** Encodes the resume checkpoint (in-flight continuation URL + remaining collections) into an opaque cursor. */
export function EncodeResumeCursor(state: BusinessCentralResumeState): string {
    return Buffer.from(JSON.stringify(state), 'utf8').toString('base64');
}

/** Decodes a resume cursor; returns null for an absent/unrecognized cursor (a fresh walk then starts). */
export function DecodeResumeCursor(cursor: string | undefined | null): BusinessCentralResumeState | null {
    if (!cursor || cursor.length === 0) return null;
    try {
        const parsed = JSON.parse(Buffer.from(cursor, 'base64').toString('utf8')) as BusinessCentralResumeState;
        if (!parsed || !Array.isArray(parsed.r)) return null;
        return { u: typeof parsed.u === 'string' ? parsed.u : undefined, r: parsed.r.filter(v => typeof v === 'string') };
    } catch {
        return null;
    }
}

// ─── EDMX parsing (runtime discovery mechanism — exported for unit testing) ──

/** Entity-set names declared by an EDMX ($metadata) document's EntityContainer. */
export function ParseEDMXEntitySets(edmx: string): string[] {
    const sets: string[] = [];
    const regex = /<EntitySet\b[^>]*\bName="([^"]+)"/g;
    let match = regex.exec(edmx);
    while (match !== null) {
        sets.push(match[1]);
        match = regex.exec(edmx);
    }
    return sets;
}

/**
 * Field schemas for one entity set, read from the EDMX: the set's EntityType, that type's `<Property>`
 * declarations (name, EDM type, `Nullable`) and its `<Key><PropertyRef>` primary key. Constraints come from
 * the document — never inferred from data.
 */
export function ParseEDMXFieldsForEntitySet(edmx: string, entitySetName: string): ExternalFieldSchema[] {
    const setMatch = new RegExp(`<EntitySet\\b[^>]*\\bName="${escapeRegExp(entitySetName)}"[^>]*\\bEntityType="([^"]+)"`, 'i').exec(edmx);
    if (!setMatch) return [];
    const typeName = setMatch[1].split('.').pop() ?? setMatch[1];
    const typeMatch = new RegExp(`<EntityType\\b[^>]*\\bName="${escapeRegExp(typeName)}"[^>]*>([\\s\\S]*?)</EntityType>`, 'i').exec(edmx);
    if (!typeMatch) return [];
    const typeBody = typeMatch[1];

    const keyNames = new Set<string>();
    const keyBlock = /<Key>([\s\S]*?)<\/Key>/i.exec(typeBody);
    if (keyBlock) {
        const refRegex = /<PropertyRef\b[^>]*\bName="([^"]+)"/g;
        let ref = refRegex.exec(keyBlock[1]);
        while (ref !== null) {
            keyNames.add(ref[1]);
            ref = refRegex.exec(keyBlock[1]);
        }
    }

    const fields: ExternalFieldSchema[] = [];
    const propRegex = /<Property\b([^>]*)\/?>/g;
    let prop = propRegex.exec(typeBody);
    while (prop !== null) {
        const attrs = prop[1];
        const name = /\bName="([^"]+)"/.exec(attrs)?.[1];
        const type = /\bType="([^"]+)"/.exec(attrs)?.[1];
        const nullableAttr = /\bNullable="(true|false)"/i.exec(attrs)?.[1];
        const maxLengthAttr = /\bMaxLength="(\d+)"/i.exec(attrs)?.[1];
        if (name) {
            const isKey = keyNames.has(name);
            fields.push({
                Name: name,
                Label: name,
                DataType: type ?? 'Edm.String',
                IsRequired: nullableAttr === 'false',
                AllowsNull: nullableAttr === undefined ? undefined : nullableAttr.toLowerCase() === 'true',
                IsPrimaryKey: isKey ? true : undefined,
                IsUniqueKey: isKey,
                IsReadOnly: false,
                MaxLength: maxLengthAttr ? Number(maxLengthAttr) : null,
            });
        }
        prop = propRegex.exec(typeBody);
    }
    return fields;
}

/** Escapes a string for literal use inside a RegExp. */
function escapeRegExp(value: string): string {
    return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// ─── JSON/config helpers ────────────────────────────────────────────────

/** Parses a JSON object, returning null for invalid or non-object JSON. */
function parseJsonObject(json: string): Record<string, unknown> | null {
    try {
        const parsed: unknown = JSON.parse(json);
        return parsed && typeof parsed === 'object' && !Array.isArray(parsed) ? parsed as Record<string, unknown> : null;
    } catch {
        return null;
    }
}

/** First non-empty string among candidate keys. */
function firstString(source: Record<string, unknown>, keys: string[]): string | undefined {
    for (const key of keys) {
        const value = source[key];
        if (typeof value === 'string' && value.trim().length > 0) return value.trim();
    }
    return undefined;
}

/** First boolean among candidate keys (accepts the string forms `"true"`/`"false"`). */
function firstBoolean(source: Record<string, unknown>, keys: string[]): boolean | undefined {
    for (const key of keys) {
        const value = source[key];
        if (typeof value === 'boolean') return value;
        if (typeof value === 'string' && (value.toLowerCase() === 'true' || value.toLowerCase() === 'false')) {
            return value.toLowerCase() === 'true';
        }
    }
    return undefined;
}

/** First finite number among candidate keys (accepts numeric strings). */
function firstNumber(source: Record<string, unknown>, keys: string[]): number | undefined {
    for (const key of keys) {
        const value = source[key];
        if (typeof value === 'number' && Number.isFinite(value)) return value;
        if (typeof value === 'string' && value.trim().length > 0) {
            const parsed = Number(value);
            if (Number.isFinite(parsed)) return parsed;
        }
    }
    return undefined;
}

/** First string-array among candidate keys (also accepts a comma-delimited string). */
function firstStringArray(source: Record<string, unknown>, keys: string[]): string[] | undefined {
    for (const key of keys) {
        const value = source[key];
        if (Array.isArray(value)) {
            const strings = value.filter((v): v is string => typeof v === 'string' && v.trim().length > 0).map(v => v.trim());
            if (strings.length > 0) return strings;
        }
        if (typeof value === 'string' && value.includes(',')) {
            const strings = value.split(',').map(v => v.trim()).filter(v => v.length > 0);
            if (strings.length > 0) return strings;
        }
    }
    return undefined;
}

/** Tree-shaking prevention — call from the package entry point. */
export function LoadBusinessCentralConnector(): void { /* no-op */ }
