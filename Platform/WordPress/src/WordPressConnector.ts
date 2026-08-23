import { RegisterClass } from '@memberjunction/global';
import { Metadata, type UserInfo } from '@memberjunction/core';
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
    buildBasicAuthHeaderValue,
    ClassifyError,
    type RESTAuthContext,
    type RESTResponse,
    type PaginationState,
    type PaginationType,
    type ConnectionTestResult,
    type ExternalObjectSchema,
    type ExternalFieldSchema,
    type FetchContext,
    type FetchBatchResult,
    type FetchWarning,
    type ExternalRecord,
    type SourceSchemaInfo,
    type SourceObjectInfo,
    type SyncErrorCode,
    type ErrorSeverity,
    type DeleteRecordContext,
    type CRUDResult,
} from '@memberjunction/integration-engine';
import { mergeDeclaredWithSampledFields } from '@memberjunction/connector-schema-merge';

// ─── Design note ──────────────────────────────────────────────────────────────
//
// The connector is PURE MECHANISM. There is NO baked object list, NO field catalog and NO
// PK/FK/required/readonly constants in this file. The stock-install FLOOR (WP 7.1 + WooCommerce
// 11.0.1, 78 record types / 1,052 fields / 222 paths) lives in the Declared metadata
// (metadata/integrations/wordpress/.wordpress.integration.json) and reaches the connector through the
// IntegrationEngineBase cache. On top of that floor the connector UNIONS what the CONNECTION's own
// site actually exposes, because WordPress's object universe is PER-SITE, never per-vendor:
//
//   * `DiscoverObjects` GETs the site's own ROUTE INDEX (`GET <apiRoot>`) and derives listable
//     collections from the registered routes — so a site's custom post types, custom taxonomies and
//     third-party plugin namespaces become visible objects that no pinned source could have known.
//   * `DiscoverFields` issues `OPTIONS <route>` and reads the endpoint's real JSON Schema.
//   * `IntrospectSchema` unions declared ∪ route-index-discovered ∪ OPTIONS-described ∪ live-sampled.
//
// Nothing is ever DEACTIVATED from discovery (`DiscoveryIsAuthoritative` stays false): a namespace can
// vanish from one site's index behind a feature flag or a lazy-load filter, and field visibility is
// capability-gated (`context=edit`), so absence proves nothing.
//
// What this class supplies (the WordPress protocol shape over REST/JSON):
//  - Auth: HTTP Basic (RFC 7617) with a WordPress APPLICATION PASSWORD, encoded via the shared
//    auth-helper (buildBasicAuthHeaderValue) — NO inline base64/crypto. An optional WooCommerce
//    consumer key/secret pair is supported for `wc/v3`, including the documented query-param fallback
//    for hosts that strip `Authorization`. A Woo-ONLY credential cannot read `wp/v2` at all, so those
//    objects fail with an explicit capability warning instead of an empty-but-green sync.
//  - Base URL: PER-CONNECTION and DERIVED, never string-concatenated. WordPress is self-hosted and the
//    REST prefix is filterable (`rest_get_url_prefix()`), so the API root comes from the site's own
//    advertised REST URL (the `Link: <…>; rel="https://api.w.org/"` header) with `{site}/wp-json/` and
//    the permalink-less `{site}/?rest_route=/` forms as fallbacks.
//  - Pagination: `page` + `per_page` clamped to the documented cap, terminated on `X-WP-TotalPages`
//    (or the `Link rel="next"` header, or a short page), with `X-WP-Total` surfaced as the expected
//    count and a STABLE SORT (`orderby=id&order=asc`) to minimise offset drift.
//  - `context=edit` with a GRACEFUL, LOUD degrade to `context=view` on 401/403.
//  - Incremental: per-object, strictly FROM METADATA. Objects whose metadata declares no watermark
//    (wp/v2/users, wc/v3/customers, and the six objects that register `modified_after` but expose no
//    modified column) get NO delta path — the connector never synthesises one.
//  - FULL-RECORD pass-through: `_fields` is deliberately never sent, so per-site `meta` and
//    plugin-added properties reach the framework's custom-column capture.

// ─── Constants (protocol facts, not a catalog) ────────────────────────────────

/** Documented `per_page` ceiling for a WP REST collection; a request above it is REJECTED, not clamped. */
const WP_DEFAULT_MAX_PER_PAGE = 100;
/** The rel value WordPress uses to advertise its REST API root from the site's homepage. */
const WP_API_LINK_REL = 'https://api.w.org/';
/** Sentinel path segment marking "this site answers at `?rest_route=`, not at a REST prefix path". */
const REST_ROUTE_SENTINEL = '/__mj_rest_route__';

// ─── Types ────────────────────────────────────────────────────────────────────

/** Parsed WordPress connection credential. Every field is optional — a credential-free connection is legal (public routes). */
interface WordPressCredentials {
    /** The tenant's own site root, e.g. `https://example.org`. There is no vendor host. */
    SiteUrl?: string;
    /** Explicit REST API root override (sandbox/mock redirection by DATA, never a code branch). */
    ApiRoot?: string;
    /** WordPress user login (the Basic userid). */
    Username?: string;
    /** WordPress Application Password (the Basic password). */
    ApplicationPassword?: string;
    /** WooCommerce REST consumer key (`wc/v3` ONLY). */
    WooConsumerKey?: string;
    /** WooCommerce REST consumer secret (`wc/v3` ONLY). */
    WooConsumerSecret?: string;
}

/** Resolved per-connection auth + routing context. */
interface WordPressAuthContext extends RESTAuthContext {
    /** The DERIVED REST API root (already includes the site's real REST prefix). */
    ApiRoot: string;
    /** True when the root is the `?rest_route=` form (site without pretty permalinks). */
    UsesRestRouteQuery: boolean;
    /** `Authorization` header value to send, or null when the connection is credential-free. */
    AuthorizationHeader: string | null;
    /** True when an Application Password pair was supplied (authenticates BOTH namespaces). */
    HasApplicationPassword: boolean;
    /** True when a WooCommerce consumer key/secret pair was supplied (`wc/*` only). */
    HasWooCredential: boolean;
    /** Woo key/secret to append as query params, when the connection opts into that fallback. */
    WooQueryAuth: { Key: string; Secret: string } | null;
    /** The IntegrationID this context was resolved for (used for per-object metadata lookups off the request path). */
    IntegrationID: string;
}

/** One route entry as WordPress reports it in the site route index. */
interface WordPressRouteEntry {
    namespace?: string;
    methods?: string[];
    endpoints?: Array<{ methods?: string[]; args?: Record<string, unknown> }>;
}

/** The site route index (`GET <apiRoot>`). */
interface WordPressRouteIndex {
    name?: string;
    description?: string;
    url?: string;
    namespaces?: string[];
    routes?: Record<string, WordPressRouteEntry>;
    /** The site's UTC offset in HOURS (`WP_REST_Server::get_index()` — public, credential-free). WordPress
     *  has emitted it as a float in current releases and as the raw `gmt_offset` option string in older
     *  ones, so both forms are accepted. Load-bearing for the site-local watermark projection. */
    gmt_offset?: number | string;
    /** Olson timezone name when the site is configured by city rather than by raw offset (may be ''). */
    timezone_string?: string;
}

/** A single property of an `OPTIONS <route>` endpoint schema. */
interface WordPressSchemaProperty {
    description?: string;
    type?: string | string[];
    format?: string;
    readonly?: boolean;
    required?: boolean;
    maxLength?: number;
    enum?: unknown[];
    context?: string[];
}

/** The `schema` block returned by `OPTIONS <route>`. */
interface WordPressOptionsResponse {
    schema?: { title?: string; type?: string; properties?: Record<string, WordPressSchemaProperty> };
}

/** WordPress's uniform `WP_Error` JSON serialisation (wp/v2, wc/v3 and /batch/v1 alike). */
interface WordPressErrorEnvelope {
    code?: string;
    message?: string;
    data?: { status?: number } & Record<string, unknown>;
}

/** A classified WordPress failure — derived from the error ENVELOPE, not from the status alone. */
export interface WordPressErrorClassification {
    /** Engine-level sync error code (the `SyncErrorCode` union the run artifact reports). */
    Code: SyncErrorCode;
    /** Engine-level severity. */
    Severity: ErrorSeverity;
    /** The vendor's stable machine code (`rest_no_route`, `woocommerce_rest_authentication_error`, …), when present. */
    VendorCode: string | null;
    /** Whether the engine should retry (429/503/transport), per `IsRetryableError` semantics. */
    Retryable: boolean;
    /** Short machine-ish reason naming WHY this classification was chosen. */
    Reason: string;
}

// ─── WordPressConnector ───────────────────────────────────────────────────────

/**
 * WordPress connector — extends BaseRESTIntegrationConnector (REST/JSON over HTTP).
 *
 * Serves BOTH in-scope namespaces (`wp/v2` core and `wc/v3` WooCommerce) off ONE self-hosted site root.
 * Pagination, template-var (per-parent) read traversal and the generic metadata-driven CRUD are
 * inherited; this class supplies the WordPress-specific protocol surface plus the §7/§10 sync-efficiency
 * hooks the frozen contract actually evidences.
 */
@RegisterClass(BaseIntegrationConnector, 'WordPressConnector')
export class WordPressConnector extends BaseRESTIntegrationConnector {

    /** Resolved auth per CompanyIntegration.ID — Application Passwords and Woo keys never expire. */
    private authCache = new Map<string, WordPressAuthContext>();
    /** Route index per API root, fetched once per connector lifetime (656 routes on a stock install). */
    private routeIndexCache = new Map<string, WordPressRouteIndex>();
    /** Response headers keyed by the PARSED BODY OBJECT — the race-free way to get `X-WP-TotalPages`
     *  into `ExtractPaginationInfo`, whose signature only receives the body. Weak so nothing is retained. */
    private headersByBody = new WeakMap<object, Record<string, string>>();
    /** Route paths that answered 401/403 to `context=edit` and have been degraded to `context=view`. */
    private contextDegraded = new Set<string>();
    /** Per-object query params for the ACTIVE fetch, consumed by AppendDefaultQueryParams. Keyed by object name. */
    private activeFetchParams = new Map<string, Record<string, string>>();
    /** Objects whose capability warnings have already been logged (keep the log honest, not noisy). */
    private warnedOnce = new Set<string>();
    /** Last non-2xx READ outcome per route path. The base's paginated loop SWALLOWS a 403 into an empty
     *  result; without this the connector could not tell "forbidden" from "genuinely no records". */
    private lastReadFailureByPath = new Map<string, { Status: number; Body: unknown }>();

    // ── Identity (T1 three-way invariant) ─────────────────────────────────────

    /** Verbatim `MJ: Integrations.Name`. Load-bearing: T1 compares this === the metadata Name. */
    public override get IntegrationName(): string {
        return 'WordPress';
    }

    // ── Capability getters (kept in lockstep with the per-operation IO columns) ──

    public override get SupportsCreate(): boolean { return true; }
    public override get SupportsUpdate(): boolean { return true; }
    public override get SupportsDelete(): boolean { return true; }

    /**
     * FALSE, and deliberately so — the two levels of authority differ and one boolean cannot express both.
     * OBJECT level: the route index enumerates every route the site REGISTERED for that request, but a
     * namespace can be absent because of a feature flag (`wc/v4` needs `rest-api-v4`) or WooCommerce's
     * per-request lazy-load filter, so absence does not mean the vendor dropped it. FIELD level: schema
     * visibility is capability-gated (`context=edit` + the matching capability), so an under-privileged
     * credential legitimately receives a THINNER schema. Deactivating on either would wipe real metadata.
     */
    public override get DiscoveryIsAuthoritative(): boolean {
        return false;
    }

    // ── Sync-efficiency hooks (§7/§10) ────────────────────────────────────────

    /**
     * NULL on purpose. Neither `wp/v2` nor `wc/v3` documents ANY rate limit — WordPress core imposes none
     * and the WooCommerce v3 docs have no rate-limit section (`Configuration.RateLimitPolicy.vendorDocumented
     * = false`, and the metadata records that no number may be emitted). Real limits are HOST/CDN-imposed and
     * per-tenant. Publishing a `TokensPerSec` here would fabricate a vendor commitment that does not exist;
     * the engine derives a conservative rate instead and `ExtractRetryAfterMs` + `MaxConcurrencyHint` below
     * carry the obligations that ARE real.
     */
    public override get RateLimitPolicy(): null {
        return null;
    }

    /**
     * Deliberately LOW. The thing being loaded is the TENANT'S OWN WEBSITE — the same PHP workers that serve
     * their visitors — and deep offset paging is O(offset) in their database. Two in flight is the
     * conservative default the metadata's `connectorObligation` calls for.
     */
    public override get MaxConcurrencyHint(): number { return 2; }

    /**
     * Honours `429` + `Retry-After` (and `503`) ADAPTIVELY: parses both the delta-seconds and the HTTP-date
     * forms of the header off the error the transport threw, so the engine's AIMD bucket backs off by the
     * host's actual instruction rather than a guess.
     */
    public override ExtractRetryAfterMs(error: unknown): number | undefined {
        const headers = error instanceof WordPressHTTPError
            ? error.Headers
            : this.headersFromUnknownError(error);
        if (!headers) return undefined;
        const raw = headers['retry-after'] ?? headers['Retry-After'];
        if (raw == null) return undefined;
        const seconds = Number(raw);
        if (Number.isFinite(seconds) && seconds >= 0) return Math.ceil(seconds * 1000);
        const when = Date.parse(String(raw));
        if (Number.isFinite(when)) return Math.max(0, when - Date.now());
        return undefined;
    }

    /**
     * Keyset resume for the objects with NO usable server-side watermark — read from the IO metadata's
     * `StableOrderingKey` (`id` for most collections, `slug`/`code`/`name`/`instance_id` where that is the
     * declared key), never guessed. Null when the object declares no stable key.
     *
     * DELIBERATELY NULL for every object that DOES declare a usable server-side date filter. That is the
     * ENGINE'S OWN CONTRACT, not a preference: `IntegrationEngine`'s §8a keyset block treats "has a
     * StableOrderingKey" and "uses a timestamp watermark" as MUTUALLY EXCLUSIVE — `isKeysetConnector`
     * forces `initialWatermark = null` on every run, and a clean scan then CLEARS the keyset marker instead
     * of saving a timestamp (its own comment: a connector whose object has a usable server-side date
     * incremental MUST NOT declare a StableOrderingKey for that object). Declaring a key for a
     * watermark-capable object therefore (a) never hands `FetchContext.WatermarkValue` back to the
     * connector, so the `modified_after` filter is built but never issued, and (b) never persists a
     * watermark at all — a DEAD incremental that silently full-re-lists forever. Which of the two applies
     * is a PER-OBJECT metadata fact, so it is READ from metadata here rather than declaring both and
     * getting neither.
     *
     * The metadata `StableOrderingKey` COLUMN is untouched and still drives the `orderby=id&order=asc`
     * stable sort in {@link buildObjectQueryParams}; only the engine-facing keyset signal is withheld.
     */
    public override StableOrderingKey(objectName: string): string | null {
        const obj = this.tryGetCachedObjectByName(objectName);
        if (!obj) return null;
        if (this.hasLiveIncrementalWatermark(obj)) return null;
        const declared = obj.StableOrderingKey;
        if (declared && declared.trim().length > 0) return declared.trim();
        const pk = this.GetCachedFields(obj.ID).find(f => f.IsPrimaryKey);
        return pk?.Name ?? null;
    }

    /**
     * Whether this object has a LIVE server-side incremental filter — all three metadata facts present:
     * the `SupportsIncrementalSync` flag, the `IncrementalWatermarkField` the max-seen is read from, and a
     * `Configuration.incrementalWatermark.filterParam` to actually put on the wire. Anything less is a
     * DECORATIVE watermark and the object is treated as full-scan-only.
     *
     * FALSE, correctly, for `wp/v2/users` and `wc/v3/customers` (their controllers inherit no date params
     * at all) and for the six objects that register `modified_after` but expose no modified column
     * (MenuItem, GlobalStyle, FontFamily, FontFamilyFontFace, OrderRefund, Refund) — every one of which
     * carries a null `incrementalWatermark` plus an `incrementalNote` in the metadata.
     */
    private hasLiveIncrementalWatermark(obj: MJIntegrationObjectEntity, cfg?: WordPressObjectConfig | null): boolean {
        if (!obj.SupportsIncrementalSync || !obj.IncrementalWatermarkField) return false;
        const resolved = cfg === undefined ? this.objectConfig(obj) : cfg;
        const filterParam = resolved?.incrementalWatermark?.filterParam;
        return typeof filterParam === 'string' && filterParam.length > 0;
    }

    // ── Discovery ─────────────────────────────────────────────────────────────

    /**
     * DYNAMIC discovery. The Declared metadata is the stock-install FLOOR — never the ceiling — so this
     * reads the CONNECTION's OWN route index (`GET <apiRoot>`) and UNIONS the per-site remainder on top:
     * custom post types, custom taxonomies and third-party plugin namespaces, all of which flow through the
     * same core controllers with a different `rest_base` and are therefore invisible to any pinned source.
     *
     * A route becomes a candidate object when it is a GET collection route (no path capture in its own last
     * segment) that registers `per_page` — i.e. a LISTABLE collection, the discriminator that separates a
     * record set from the RPC routes (`/wp/v2/block-renderer/…`, `/oembed/1.0/proxy`).
     *
     * Namespaces the OPERATOR scoped out are skipped by READING the metadata's own structured
     * `Configuration.OutOfScopeObjectFamilies[].kind` — first-party RPC/admin/legacy/transport surfaces are
     * not record collections. Third-party plugin namespaces are NOT skipped: the metadata's own reason text
     * says they are "reachable at runtime via route-index discovery", which is exactly this path.
     *
     * A discovery failure NEVER removes the declared floor — the union degrades to the floor with a warning.
     */
    public override async DiscoverObjects(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<ExternalObjectSchema[]> {
        const declaredObjects = this.getCachedObjects(companyIntegration.IntegrationID);
        const out: ExternalObjectSchema[] = declaredObjects.map(obj => ({
            ID: obj.ID,
            Name: obj.Name,
            Label: obj.DisplayName ?? obj.Name,
            Description: obj.Description ?? undefined,
            SupportsIncrementalSync: obj.SupportsIncrementalSync,
            SupportsWrite: obj.SupportsWrite,
        }));

        let index: WordPressRouteIndex | null = null;
        try {
            const auth = await this.Authenticate(companyIntegration, contextUser);
            index = await this.loadRouteIndex(auth);
        } catch (err) {
            this.warnOnce(
                'route-index',
                `[WordPress] Route-index discovery unavailable (${this.errText(err)}). Falling back to the DECLARED ` +
                `stock-install floor only — this site's custom post types, custom taxonomies and plugin namespaces ` +
                `will NOT be surfaced until discovery succeeds. Nothing was deactivated.`,
            );
            return out;
        }

        const excludedNamespaces = this.readScopedOutNamespaces(companyIntegration);
        const declaredPaths = new Set(declaredObjects.map(o => this.canonicalRoutePath(this.declaredListPath(o))));
        const takenNames = new Set(out.map(o => o.Name.toLowerCase()));

        for (const candidate of this.deriveCollectionRoutes(index)) {
            if (excludedNamespaces.has(candidate.Namespace)) continue;
            if (declaredPaths.has(this.canonicalRoutePath(candidate.Path))) continue;
            const name = candidate.Path;
            if (takenNames.has(name.toLowerCase())) continue;
            takenNames.add(name.toLowerCase());
            out.push({
                // The NAME is the route path on purpose: a runtime-discovered IntegrationObject has its
                // APIPath defaulted from the ExternalName by the persist layer, so naming it by its path is
                // what makes a newly-found custom post type / plugin collection immediately FETCHABLE
                // instead of a visible-but-dead object.
                Name: name,
                Label: this.humanLabelForRoute(candidate.Path, candidate.Namespace),
                Description:
                    `Discovered from this site's route index in namespace "${candidate.Namespace}" — not part of the ` +
                    `declared stock-install floor (per-site custom post type, custom taxonomy or plugin collection).`,
                SupportsIncrementalSync: false,   // provable-only: no watermark evidence for an unknown route
                SupportsWrite: candidate.SupportsWrite,
            });
        }
        return out;
    }

    /**
     * Field discovery via `OPTIONS <route>` — WordPress's self-describing endpoint schema. The result is
     * UNIONED over the Declared field set and NEVER shrinks it: field visibility is capability-gated, so an
     * under-privileged credential legitimately sees a thinner schema and its ABSENCES prove nothing.
     *
     * A templated collection path (`/wc/v3/orders/{order_id}/notes`) has no literal URL to OPTIONS without a
     * real parent id, so those objects return their declared fields unchanged rather than a fabricated set.
     */
    public override async DiscoverFields(
        companyIntegration: MJCompanyIntegrationEntity,
        objectName: string,
        contextUser: UserInfo,
    ): Promise<ExternalFieldSchema[]> {
        let declared: ExternalFieldSchema[] = [];
        try {
            declared = await super.DiscoverFields(companyIntegration, objectName, contextUser);
        } catch {
            declared = [];   // a route-index-discovered object has no cached IOFs yet — OPTIONS is all we have
        }

        const routePath = this.optionsRoutePathFor(companyIntegration.IntegrationID, objectName);
        if (!routePath) return declared;

        try {
            const auth = await this.Authenticate(companyIntegration, contextUser);
            const described = await this.describeRoute(auth, routePath);
            return this.unionFieldSchemas(declared, described);
        } catch (err) {
            this.warnOnce(
                `options:${objectName}`,
                `[WordPress] OPTIONS ${routePath} failed for "${objectName}" (${this.errText(err)}) — keeping the ` +
                `declared field set unchanged. NO field was deactivated (field absence is capability-gated and never authoritative).`,
            );
            return declared;
        }
    }

    /**
     * Union introspection — the layer where the per-site truth actually lands in the schema:
     *   1. `super.IntrospectSchema` returns the persisted DECLARED objects (the stock-install floor).
     *   2. Objects the ROUTE INDEX exposes but the floor never declared are APPENDED (per-site customs).
     *   3. Every object's field set is UNIONED with the live `OPTIONS` schema and with a live record SAMPLE
     *      (`DiscoverFieldsViaFetch` → `mergeDeclaredWithSampledFields`, never-shrink / declared-wins /
     *      capacities widened), so a tenant's registered `meta` keys and plugin-added properties reach the
     *      schema instead of being silently dropped at field-mapping time.
     * Every step is best-effort and additive — a failure leaves the declared set exactly as it was.
     */
    public override async IntrospectSchema(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<SourceSchemaInfo> {
        const info = await super.IntrospectSchema(companyIntegration, contextUser);
        const known = new Set(info.Objects.map(o => o.ExternalName.toLowerCase()));

        // (2) per-site remainder from the route index
        try {
            const discovered = await this.DiscoverObjects(companyIntegration, contextUser);
            for (const obj of discovered) {
                if (known.has(obj.Name.toLowerCase())) continue;
                known.add(obj.Name.toLowerCase());
                const fields = await this.DiscoverFields(companyIntegration, obj.Name, contextUser);
                info.Objects.push(this.toSourceObjectInfo(obj, fields));
            }
        } catch (err) {
            this.warnOnce('introspect-union', `[WordPress] Per-site object union skipped: ${this.errText(err)}`);
        }

        // (3) OPTIONS + sample-union field enrichment
        await Promise.all(info.Objects.map(async (obj) => {
            try {
                const described = await this.DiscoverFields(companyIntegration, obj.ExternalName, contextUser);
                obj.Fields = mergeDeclaredWithSampledFields(obj.Fields, described);
            } catch { /* best-effort — a describe failure leaves the declared fields as-is */ }
            try {
                const sampled = await this.DiscoverFieldsViaFetch(companyIntegration, obj.ExternalName, contextUser);
                obj.Fields = mergeDeclaredWithSampledFields(obj.Fields, sampled);
            } catch { /* best-effort — a sample failure leaves the declared fields as-is */ }
        }));

        return info;
    }

    // ── Fetch ─────────────────────────────────────────────────────────────────

    /**
     * OVERRIDDEN for four things the generic path cannot express, then delegated:
     *   1. DUAL-NAMESPACE CREDENTIAL GUARD — a Woo-only consumer key/secret cannot read `wp/v2` at ALL
     *      (`WC_REST_Authentication::is_request_to_rest_api()` matches only `wc/`/`wc-` URIs), so those
     *      objects surface an explicit capability warning instead of an empty-but-green sync.
     *   2. PER-OBJECT QUERY PARAMS — the stable sort and the metadata-declared incremental filter, staged
     *      for `AppendDefaultQueryParams` (which the base calls for every page of every request).
     *   3. WATERMARK — max-seen over the object's declared `IncrementalWatermarkField`, persisted ONLY on a
     *      fully-drained pass so a partial batch never advances it.
     *   4. GRACEFUL DEGRADES — an unregistered route (a gated Woo feature such as order fulfillments) and a
     *      capability-forbidden collection become a WARNED zero-record result, not a failed sync.
     *
     * `ctx.RequestedSourceFields` is deliberately IGNORED: WordPress's `_fields` param would truncate the
     * record to whatever the connector thought to ask for, which is exactly what breaks the framework's
     * custom/overflow capture of per-site `meta` and plugin-added properties.
     */
    public override async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
        const obj = this.GetCachedObject(ctx.CompanyIntegration.IntegrationID, ctx.ObjectName);
        const cfg = this.objectConfig(obj);
        const auth = await this.Authenticate(ctx.CompanyIntegration, ctx.ContextUser);

        const guard = this.namespaceCredentialGuard(obj, cfg, auth);
        if (guard) return { Records: [], HasMore: false, Warnings: [guard] };

        if (this.isGlobalStylesObject(obj, cfg)) return this.fetchGlobalStyles(obj, cfg, ctx, auth);

        const warnings: FetchWarning[] = [];
        this.clearReadFailures(obj, cfg);
        this.activeFetchParams.set(obj.Name, await this.buildObjectQueryParams(obj, cfg, ctx, auth));
        let result: FetchBatchResult;
        try {
            result = await super.FetchChanges(ctx);
        } catch (err) {
            const graceful = this.gracefulFetchFailure(obj, this.statusFromError(err), this.bodyFromError(err))
                ?? this.parentResolutionUnavailable(obj, err);
            if (!graceful) throw err;
            return graceful;
        } finally {
            this.activeFetchParams.delete(obj.Name);
        }

        // The base swallows a 403 into an empty batch — surface the recorded refusal instead of a
        // legitimately-empty object, so a capability gap can never read as an empty-but-green sync.
        const swallowed = result.Records.length === 0 ? this.recordedReadFailure(obj, cfg) : null;
        if (swallowed) {
            const graceful = this.gracefulFetchFailure(obj, swallowed.Status, swallowed.Body);
            if (graceful) return graceful;
        }

        if (result.Warnings) warnings.push(...result.Warnings);

        // Soft-delete capture: WordPress post types DELETE to `status=trash` and trashed rows stay listable.
        // Only an authenticated caller can ever see them, so the sweep is gated on a real credential.
        const trash = await this.fetchTrashedRecords(obj, cfg, ctx, auth, result);
        if (trash.Records.length > 0) result.Records = [...result.Records, ...trash.Records];
        if (trash.Warning) warnings.push(trash.Warning);

        this.markTrashedAsDeleted(result.Records);

        const watermark = this.maxWatermark(obj, result.Records);
        return {
            ...result,
            Warnings: warnings.length > 0 ? warnings : undefined,
            // Advance ONLY on a fully-drained pass — a partial batch (or a mid-iteration failure, which
            // never reaches here) leaves the stored watermark untouched so the next run resumes cleanly.
            NewWatermarkValue: !result.HasMore && watermark ? watermark : undefined,
        };
    }

    // ── Abstract REST hooks ───────────────────────────────────────────────────

    /**
     * Resolves the per-connection credential AND the DERIVED REST API root. Cached per CompanyIntegration —
     * Application Passwords and Woo consumer keys are long-lived with no refresh endpoint, so there is
     * nothing to renew. A credential-free connection is LEGAL and does not throw: WordPress's route index
     * and `OPTIONS` are public, which is what lets discovery work without a secret.
     */
    protected override async Authenticate(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<RESTAuthContext> {
        const cached = this.authCache.get(companyIntegration.ID);
        if (cached) return cached;

        const creds = await this.loadCredentials(companyIntegration, contextUser);
        const siteUrl = (creds.SiteUrl ?? '').trim().replace(/\/+$/, '');
        if (!siteUrl && !creds.ApiRoot) {
            throw new Error(
                'No WordPress site URL configured. WordPress is SELF-HOSTED — there is no vendor host — so the ' +
                'connection must supply "siteUrl" (the tenant\'s own site root) on its credential or Configuration JSON.',
            );
        }

        const root = await this.deriveApiRoot(siteUrl, creds.ApiRoot ?? null);
        const hasAppPassword = !!(creds.Username && creds.ApplicationPassword);
        const hasWoo = !!(creds.WooConsumerKey && creds.WooConsumerSecret);

        let header: string | null = null;
        if (hasAppPassword) {
            header = buildBasicAuthHeaderValue({ Username: creds.Username!, Password: creds.ApplicationPassword! });
        } else if (hasWoo) {
            // Woo accepts its key/secret as HTTP Basic over HTTPS. It reaches `wc/*` ONLY — the wp/v2 guard
            // in FetchChanges makes that asymmetry explicit rather than letting core objects come back empty.
            header = buildBasicAuthHeaderValue({ Username: creds.WooConsumerKey!, Password: creds.WooConsumerSecret! });
            this.warnOnce(
                'woo-only-credential',
                '[WordPress] This connection supplies a WooCommerce consumer key/secret but NO Application Password. ' +
                'A Woo key pair cannot authenticate wp/v2 at all, so every WordPress-core object will be reported as a ' +
                'capability gap rather than synced. Add an Application Password to cover wp/v2.',
            );
        } else {
            this.warnOnce(
                'no-credential',
                '[WordPress] No credential supplied. Public routes (route index, OPTIONS, published content) still ' +
                'answer, but every capability-gated collection and field will be unavailable to this connection.',
            );
        }

        const ctx: WordPressAuthContext = {
            ApiRoot: root.Root,
            UsesRestRouteQuery: root.UsesRestRouteQuery,
            AuthorizationHeader: header,
            HasApplicationPassword: hasAppPassword,
            HasWooCredential: hasWoo,
            WooQueryAuth: hasWoo && this.wooQueryParamAuthEnabled(companyIntegration)
                ? { Key: creds.WooConsumerKey!, Secret: creds.WooConsumerSecret! }
                : null,
            IntegrationID: companyIntegration.IntegrationID,
        };
        this.authCache.set(companyIntegration.ID, ctx);
        return ctx;
    }

    /** Static request headers plus the resolved Basic credential (absent on a credential-free connection). */
    protected override BuildHeaders(auth: RESTAuthContext): Record<string, string> {
        const ctx = auth as WordPressAuthContext;
        const headers: Record<string, string> = {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        };
        if (ctx.AuthorizationHeader) headers['Authorization'] = ctx.AuthorizationHeader;
        return headers;
    }

    /**
     * The single wire choke point. Beyond the raw transport it owns four WordPress-specific concerns:
     *   1. `?rest_route=` rewriting for a site without pretty permalinks.
     *   2. The Woo consumer key/secret QUERY-PARAM fallback on `wc/*` URLs, for hosts that strip
     *      `Authorization` (Woo gives query params precedence over the header).
     *   3. `context=edit` injection on reads, with a ONE-SHOT graceful degrade to `context=view` on 401/403
     *      that LOGS the fields that will now be missing rather than downgrading silently.
     *   4. Throwing `429`/`503` as a typed error carrying the response headers, so the engine's adaptive
     *      limiter can honour `Retry-After` instead of seeing an opaque message.
     */
    protected override async MakeHTTPRequest(
        auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown,
    ): Promise<RESTResponse> {
        const ctx = auth as WordPressAuthContext;
        let requestURL = this.rewriteForRestRoute(ctx, url);
        requestURL = this.appendWooQueryAuth(ctx, requestURL);

        const routeKey = this.pathOf(requestURL);
        const isRead = method.toUpperCase() === 'GET';
        const contextAlreadySet = this.hasQueryParam(requestURL, 'context');
        const injectContext = isRead && !contextAlreadySet && !this.contextDegraded.has(routeKey);
        if (injectContext) {
            requestURL = this.withQueryParam(requestURL, 'context', 'edit');
        } else if (isRead && !contextAlreadySet) {
            // Already degraded on this route — say `view` on the wire rather than relying on a default,
            // so the request is self-describing in a site's access log and in a captured trace.
            requestURL = this.withQueryParam(requestURL, 'context', 'view');
        }

        let response = await this.rawRequest(requestURL, method, headers, body);

        if (injectContext && (response.Status === 401 || response.Status === 403)) {
            this.contextDegraded.add(routeKey);
            this.warnOnce(
                `context-degrade:${routeKey}`,
                `[WordPress] CAPABILITY DEGRADE on ${routeKey}: this credential may not read context=edit ` +
                `(HTTP ${response.Status} ${this.vendorCodeOf(response.Body) ?? 'no vendor code'}). Falling back to ` +
                `context=view. The following declared fields are context=edit-gated and will be MISSING from every ` +
                `record on this route: [${this.contextGatedFieldsForPath(ctx, routeKey).join(', ') || 'none declared'}]. ` +
                `This is a thinner schema than the vendor documents — grant the credential the matching capability to close it.`,
            );
            response = await this.rawRequest(
                this.withQueryParam(this.stripQueryParam(requestURL, 'context'), 'context', 'view'),
                method, headers, body,
            );
        }

        if (response.Status === 429 || response.Status === 503) {
            const classified = this.ClassifyWordPressResponse(response.Status, response.Body);
            throw new WordPressHTTPError(
                `[WordPress] HTTP ${response.Status} (${classified.Reason}) from ${routeKey}`,
                response.Status, response.Headers, classified.VendorCode,
            );
        }
        // Remember a forbidden/absent READ. The base's paginated loop turns a 403 into a SILENT empty
        // result; recording it here is what lets FetchChanges report a capability gap rather than a
        // legitimately-empty object.
        if (isRead && (response.Status === 401 || response.Status === 403 || response.Status === 404)) {
            this.lastReadFailureByPath.set(routeKey, { Status: response.Status, Body: response.Body });
        }
        return response;
    }

    /**
     * Strips the WordPress collection envelope. Three declared response shapes, discriminated STRUCTURALLY
     * from the body itself (the signature receives no object row, and the shape is unambiguous in the bytes):
     *   - `array`         → a bare JSON array of records (73 of the declared objects).
     *   - `object-map`    → `{ "<slug>": {…}, … }` (types, statuses, taxonomies, menu-locations) → its values.
     *   - `single-object` → one document (settings, system status) → a one-element list.
     * A `responseDataKey` still wins when the metadata declares one.
     */
    protected override NormalizeResponse(rawBody: unknown, responseDataKey: string | null): Record<string, unknown>[] {
        if (rawBody == null) return [];
        if (Array.isArray(rawBody)) return rawBody as Record<string, unknown>[];
        if (typeof rawBody !== 'object') return [];
        const body = rawBody as Record<string, unknown>;

        if (responseDataKey) {
            const keyed = body[responseDataKey];
            if (Array.isArray(keyed)) return keyed as Record<string, unknown>[];
            if (keyed && typeof keyed === 'object') return [keyed as Record<string, unknown>];
        }

        // A WP_Error envelope is never a record. Non-2xx already threw; this guards a 2xx-wrapped error.
        if (typeof body.code === 'string' && typeof body.message === 'string' && body.data != null) return [];

        const values = Object.values(body);
        const isObjectMap =
            values.length > 0 &&
            values.every(v => v != null && typeof v === 'object' && !Array.isArray(v));
        if (isObjectMap) return values as Record<string, unknown>[];

        return [body];
    }

    /**
     * WordPress pagination is OFFSET-based page numbering whose termination signal lives in the RESPONSE
     * HEADERS, not the body — so the headers recorded against this exact body object are consulted first:
     *   `X-WP-TotalPages` (authoritative), else the RFC-5988 `Link rel="next"`, else a short page.
     * `X-WP-Total` is surfaced as the expected count. Completeness on a deep scan is BEST-EFFORT: page
     * numbering is offset arithmetic, so concurrent writes shift rows across page boundaries; the
     * `orderby=id&order=asc` stable sort reduces but does not eliminate that drift, and exactness is never claimed.
     */
    protected override ExtractPaginationInfo(
        rawBody: unknown,
        paginationType: PaginationType,
        currentPage: number,
        _currentOffset: number,
        pageSize: number,
    ): PaginationState {
        if (paginationType !== 'PageNumber') return { HasMore: false };

        const headers = rawBody != null && typeof rawBody === 'object'
            ? this.headersByBody.get(rawBody as object)
            : undefined;
        const total = this.toPositiveInt(headers?.['x-wp-total']);
        const totalPages = this.toPositiveInt(headers?.['x-wp-totalpages']);

        if (totalPages != null) {
            return { HasMore: currentPage < totalPages, NextPage: currentPage + 1, TotalRecords: total ?? undefined };
        }
        const link = headers?.['link'];
        if (link != null) {
            const hasNext = link.includes('rel="next"');
            return { HasMore: hasNext, NextPage: currentPage + 1, TotalRecords: total ?? undefined };
        }
        const received = Array.isArray(rawBody) ? rawBody.length : 0;
        return {
            HasMore: received > 0 && pageSize > 0 && received >= pageSize,
            NextPage: currentPage + 1,
            TotalRecords: total ?? undefined,
        };
    }

    /** The DERIVED per-connection REST API root (resolved in Authenticate — never `siteUrl + '/wp-json'`). */
    protected override GetBaseURL(_companyIntegration: MJCompanyIntegrationEntity, auth: RESTAuthContext): string {
        const ctx = auth as WordPressAuthContext;
        return ctx.UsesRestRouteQuery
            ? `${ctx.ApiRoot.replace(/\/+$/, '')}${REST_ROUTE_SENTINEL}`
            : ctx.ApiRoot.replace(/\/+$/, '');
    }

    /**
     * `page` + `per_page`, with `per_page` CLAMPED to the cap the object's own metadata declares
     * (`Configuration.pagination.maxPageSize`, 100 on every in-scope collection). WordPress REJECTS a
     * request above the cap rather than clamping it server-side, so the clamp has to happen here.
     */
    protected override BuildPaginatedURL(
        basePath: string,
        obj: MJIntegrationObjectEntity,
        page: number,
        offset: number,
        cursor?: string,
        effectivePageSize?: number,
    ): string {
        if (obj.PaginationType !== 'PageNumber') {
            return super.BuildPaginatedURL(basePath, obj, page, offset, cursor, effectivePageSize);
        }
        const cfg = this.objectConfig(obj);
        const cap = this.toPositiveInt(cfg?.pagination?.maxPageSize) ?? WP_DEFAULT_MAX_PER_PAGE;
        const wanted = effectivePageSize ?? obj.DefaultPageSize ?? cap;
        const size = Math.max(1, Math.min(wanted, cap));
        const sep = basePath.includes('?') ? '&' : '?';
        return `${basePath}${sep}page=${page}&per_page=${size}`;
    }

    /**
     * Appends the DECLARED default query params (base behaviour) and then the per-object params this fetch
     * staged: the stable sort and the metadata-declared incremental filter. Params already present in the
     * URL are never duplicated.
     */
    protected override AppendDefaultQueryParams(url: string, obj: MJIntegrationObjectEntity): string {
        let out = super.AppendDefaultQueryParams(url, obj);
        const params = this.activeFetchParams.get(obj.Name);
        if (!params) return out;
        for (const [key, value] of Object.entries(params)) {
            if (this.hasQueryParam(out, key)) continue;
            out = this.withQueryParam(out, key, value);
        }
        return out;
    }

    /** Reads the vendor's `message` out of the `{ code, message, data:{ status } }` envelope. */
    protected override ExtractErrorMessage(response: RESTResponse): string | undefined {
        const envelope = this.errorEnvelope(response.Body);
        if (envelope?.message) {
            return envelope.code ? `${envelope.code}: ${envelope.message}` : envelope.message;
        }
        return super.ExtractErrorMessage(response);
    }

    // ── CRUD ──────────────────────────────────────────────────────────────────
    //
    // Create / Update / Get use the INHERITED generic per-operation path: every write-capable IO carries
    // CreateAPIPath+CreateMethod / UpdateAPIPath+UpdateMethod in metadata, and WordPress takes ordinary flat
    // JSON bodies — there is nothing idiosyncratic for those verbs to override.

    /**
     * OVERRIDDEN for the one genuinely idiosyncratic verb: WordPress DELETE semantics are PER-OBJECT and
     * parameterised, which the generic path (a bare `DELETE <path>`) cannot express.
     *   - `requiresForce` (revisions, terms, users, widgets, Woo terms/notes/webhooks…) → `?force=true`;
     *     without it those routes reject the request outright.
     *   - `requiresReassign` (wp/v2/users) → `&reassign=<user id>`; WordPress requires it because deleting a
     *     user must say where their content goes. The id comes from the connection's
     *     `Configuration.userDeleteReassignID` and is NEVER guessed — an unset value is a loud error, because
     *     inventing one would silently reassign a customer's content to an arbitrary account.
     *   - Everything else keeps the vendor default, which for post types is a SOFT delete to `status=trash`.
     * All of this is READ FROM METADATA (`Configuration.deleteSemantics`), not decided here.
     */
    public override async DeleteRecord(ctx: DeleteRecordContext): Promise<CRUDResult> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const contextUser = ctx.ContextUser as UserInfo;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        if (!obj.DeleteAPIPath || !obj.DeleteMethod) return super.DeleteRecord(ctx);

        const cfg = this.objectConfig(obj);
        const semantics = cfg?.deleteSemantics;
        if (!semantics?.requiresForce && !semantics?.requiresReassign) return super.DeleteRecord(ctx);

        const auth = await this.Authenticate(ci, contextUser);
        const baseURL = this.GetBaseURL(ci, auth);
        const headers = this.BuildHeaders(auth);
        let path = this.SubstituteIDInPath(obj.DeleteAPIPath, ctx.ExternalID, obj.DeleteIDLocation);
        if (semantics.requiresForce) path = this.withQueryParam(path, 'force', 'true');
        if (semantics.requiresReassign) {
            const reassign = this.readConnectionConfigString(ci, ['userDeleteReassignID', 'UserDeleteReassignID']);
            if (!reassign) {
                return {
                    Success: false,
                    StatusCode: 400,
                    ErrorMessage:
                        `DeleteRecord("${ctx.ObjectName}") requires a "reassign" target: WordPress will not delete a ` +
                        `user without saying which user inherits their content. Set Configuration.userDeleteReassignID ` +
                        `on this connection. The connector will not choose one.`,
                };
            }
            path = this.withQueryParam(path, 'reassign', reassign);
        }

        const url = `${baseURL.replace(/\/+$/, '')}${path.startsWith('/') ? path : `/${path}`}`;
        const response = await this.MakeHTTPRequest(auth, url, obj.DeleteMethod, headers);
        if (response.Status >= 200 && response.Status < 300) {
            return { Success: true, StatusCode: response.Status, ExternalID: ctx.ExternalID };
        }
        return {
            Success: false,
            StatusCode: response.Status,
            ErrorMessage: this.ExtractErrorMessage(response) ?? `HTTP ${response.Status} on delete`,
        };
    }

    // ── Connection test ───────────────────────────────────────────────────────

    /**
     * Two-part test, because "reachable" and "authenticated" are different facts:
     *   1. The site's REST root must answer with a route index (proves it IS a WordPress REST API, and that
     *      the derived API root — Link header / `/wp-json/` / `?rest_route=/` — was resolved correctly).
     *   2. The supplied credential must actually authenticate: `wp/v2/users/me` for an Application Password,
     *      or a `wc/v3` read for a Woo-only key pair.
     * A credential-free connection reports failure with an explicit message — discovery works without a
     * secret, but a connection is not "successful" when nothing can be authorised.
     */
    public override async TestConnection(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<ConnectionTestResult> {
        try {
            const auth = await this.Authenticate(companyIntegration, contextUser) as WordPressAuthContext;
            const index = await this.loadRouteIndex(auth);
            const namespaces = index.namespaces ?? [];
            const site = index.name ?? 'the site';

            if (!auth.HasApplicationPassword && !auth.HasWooCredential) {
                return {
                    Success: false,
                    Message:
                        `Reached the WordPress REST API for "${site}" at ${auth.ApiRoot} (${namespaces.length} namespace(s) ` +
                        `registered), but NO credential is configured. Supply a WordPress username + Application Password ` +
                        `(covers wp/v2 and wc/v3), or a WooCommerce consumer key/secret (wc/v3 only).`,
                };
            }

            const headers = this.BuildHeaders(auth);
            const probePath = auth.HasApplicationPassword ? '/wp/v2/users/me' : '/wc/v3/data';
            const probe = await this.MakeHTTPRequest(
                auth, `${this.GetBaseURL(companyIntegration, auth)}${probePath}`, 'GET', headers,
            );
            if (probe.Status >= 200 && probe.Status < 300) {
                const scope = auth.HasApplicationPassword
                    ? 'wp/v2 + wc/v3 (Application Password authenticates every namespace)'
                    : 'wc/v3 ONLY (a WooCommerce key pair cannot read wp/v2)';
                return {
                    Success: true,
                    Message: `WordPress connection to "${site}" successful at ${auth.ApiRoot}. Authorised scope: ${scope}. ` +
                        `Namespaces registered on this site: ${namespaces.join(', ') || 'none reported'}.`,
                };
            }
            const classified = this.ClassifyWordPressResponse(probe.Status, probe.Body);
            return {
                Success: false,
                Message:
                    `Reached ${auth.ApiRoot} but the credential was rejected on ${probePath}: HTTP ${probe.Status} ` +
                    `(${classified.VendorCode ?? classified.Reason}). ` +
                    (auth.HasApplicationPassword
                        ? 'Check the username + Application Password, and note that Application Passwords are unavailable ' +
                          'over plain HTTP outside a local environment.'
                        : 'Check the WooCommerce consumer key/secret and its read/write permission scope.'),
            };
        } catch (err) {
            return { Success: false, Message: `WordPress connection test error: ${this.errText(err)}` };
        }
    }

    // ── Error classification ──────────────────────────────────────────────────

    /**
     * Classifies from the ERROR ENVELOPE, not the status alone. WordPress serialises every failure across
     * wp/v2, wc/v3 and /batch/v1 as `{ code, message, data:{ status } }`, and `code` is the stable
     * machine-readable discriminator (`message` is localised and must never be parsed).
     *
     * The distinction that matters operationally: a `403` carrying a WordPress JSON envelope is the API
     * refusing a capability (fix the credential), while a `403` carrying an HTML body never reached the API
     * at all — it is a WAF / host / mod_security block, and retrying it is pointless. Anything unrecognised
     * falls through to the engine's own `ClassifyError`.
     */
    public ClassifyWordPressResponse(status: number, body: unknown): WordPressErrorClassification {
        const envelope = this.errorEnvelope(body);
        const vendorCode = envelope?.code ?? null;
        const isHtml = typeof body === 'string' && /<\s*(html|!doctype|head|body)/i.test(body);

        if (status === 429) {
            return { Code: 'RATE_LIMIT_EXCEEDED', Severity: 'Warning', VendorCode: vendorCode, Retryable: true, Reason: 'throttled' };
        }
        if (status === 503) {
            return { Code: 'NETWORK_TIMEOUT', Severity: 'Warning', VendorCode: vendorCode, Retryable: true, Reason: 'service-unavailable' };
        }
        if ((status === 403 || status === 406 || status === 401) && isHtml) {
            return {
                Code: 'CONNECTOR_ERROR', Severity: 'Critical', VendorCode: null, Retryable: false,
                Reason: 'waf-or-host-block-html-body',
            };
        }
        if (status === 401 || status === 403) {
            return {
                Code: 'CONFIGURATION_ERROR', Severity: 'Critical', VendorCode: vendorCode, Retryable: false,
                Reason: 'capability-or-credential',
            };
        }
        if (status === 404) {
            return {
                Code: 'CONFIGURATION_ERROR', Severity: 'Warning', VendorCode: vendorCode, Retryable: false,
                Reason: vendorCode === 'rest_no_route' ? 'route-not-registered' : 'not-found',
            };
        }
        if (status === 400) {
            return { Code: 'VALIDATION_ERROR', Severity: 'Warning', VendorCode: vendorCode, Retryable: false, Reason: 'invalid-param' };
        }
        if (status === 413) {
            return { Code: 'VALIDATION_ERROR', Severity: 'Warning', VendorCode: vendorCode, Retryable: false, Reason: 'payload-too-large' };
        }
        if (status >= 500) {
            return { Code: 'CONNECTOR_ERROR', Severity: 'Critical', VendorCode: vendorCode, Retryable: false, Reason: 'server-error' };
        }
        const fallback = ClassifyError(new Error(envelope?.message ?? `HTTP ${status}`));
        return { Code: fallback.Code, Severity: fallback.Severity, VendorCode: vendorCode, Retryable: false, Reason: 'unclassified' };
    }

    // ── Transport internals ───────────────────────────────────────────────────

    /** The raw HTTP call. Isolated so test subclasses can capture the wire without losing the WP behaviours above. */
    protected async rawRequest(
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown,
    ): Promise<RESTResponse> {
        const response = await fetch(url, {
            method,
            headers,
            body: body !== undefined ? JSON.stringify(body) : undefined,
        });
        const respHeaders: Record<string, string> = {};
        response.headers.forEach((v, k) => { respHeaders[k.toLowerCase()] = v; });
        const text = await response.text();
        let parsed: unknown = null;
        if (text.length > 0) {
            try { parsed = JSON.parse(text); } catch { parsed = text; }
        }
        if (parsed != null && typeof parsed === 'object') this.headersByBody.set(parsed as object, respHeaders);
        return { Status: response.status, Body: parsed, Headers: respHeaders };
    }

    /** Rewrites `<site>/__mj_rest_route__/wp/v2/posts?x=1` → `<site>/?rest_route=/wp/v2/posts&x=1`. */
    private rewriteForRestRoute(auth: WordPressAuthContext, url: string): string {
        if (!auth.UsesRestRouteQuery || !url.includes(REST_ROUTE_SENTINEL)) return url;
        const [beforeQuery, query] = this.splitQuery(url);
        const idx = beforeQuery.indexOf(REST_ROUTE_SENTINEL);
        const origin = beforeQuery.slice(0, idx);
        const route = beforeQuery.slice(idx + REST_ROUTE_SENTINEL.length) || '/';
        const rest = `rest_route=${encodeURIComponent(route.startsWith('/') ? route : `/${route}`)}`;
        return `${origin}/?${rest}${query ? `&${query}` : ''}`;
    }

    /**
     * WooCommerce accepts `?consumer_key=&consumer_secret=` and gives them PRECEDENCE over the
     * `Authorization` header — the one hard functional advantage of the Woo key pair, for hosts that strip
     * `Authorization`. Applied ONLY to `wc/` routes and ONLY when the connection opts in.
     */
    private appendWooQueryAuth(auth: WordPressAuthContext, url: string): string {
        if (!auth.WooQueryAuth) return url;
        if (!/\/wc[/-]/.test(url) && !/rest_route=%2Fwc/i.test(url)) return url;
        if (this.hasQueryParam(url, 'consumer_key')) return url;
        return this.withQueryParam(
            this.withQueryParam(url, 'consumer_key', auth.WooQueryAuth.Key),
            'consumer_secret', auth.WooQueryAuth.Secret,
        );
    }

    // ── API-root derivation ───────────────────────────────────────────────────

    /**
     * Derives the REST API root the way WordPress itself advertises it — NEVER by concatenating
     * `siteUrl + '/wp-json'`. The REST prefix is filterable via `rest_get_url_prefix()`, so a site can serve
     * it from anywhere, and a site without pretty permalinks answers only at `?rest_route=/`. Order:
     *   1. an explicit `apiRoot` on the connection (sandbox/mock redirection by DATA);
     *   2. the `Link: <…>; rel="https://api.w.org/"` response header on the site root (HEAD, then GET);
     *   3. the same `<link>` element in the homepage HTML;
     *   4. `{siteUrl}/wp-json/`, verified by an actual route index;
     *   5. `{siteUrl}/?rest_route=/`, verified the same way.
     */
    private async deriveApiRoot(siteUrl: string, explicit: string | null): Promise<{ Root: string; UsesRestRouteQuery: boolean }> {
        if (explicit && /^https?:\/\//i.test(explicit.trim())) {
            const root = explicit.trim().replace(/\/+$/, '');
            return { Root: root, UsesRestRouteQuery: /[?&]rest_route=/.test(root) };
        }

        for (const method of ['HEAD', 'GET'] as const) {
            try {
                const probe = await this.rawRequest(siteUrl || '/', method, { 'Accept': 'text/html,*/*' });
                const advertised = this.readAdvertisedApiRoot(probe);
                if (advertised) {
                    return { Root: advertised.replace(/\/+$/, ''), UsesRestRouteQuery: /[?&]rest_route=/.test(advertised) };
                }
            } catch { /* fall through to the conventional roots */ }
        }

        for (const candidate of [`${siteUrl}/wp-json`, `${siteUrl}/?rest_route=/`]) {
            try {
                const probe = await this.rawRequest(candidate, 'GET', { 'Accept': 'application/json' });
                if (probe.Status >= 200 && probe.Status < 300 && this.looksLikeRouteIndex(probe.Body)) {
                    const usesQuery = candidate.includes('rest_route=');
                    return { Root: usesQuery ? `${siteUrl}` : candidate, UsesRestRouteQuery: usesQuery };
                }
            } catch { /* try the next form */ }
        }

        throw new Error(
            `Could not derive a WordPress REST API root from "${siteUrl}". The site advertised no ` +
            `Link rel="${WP_API_LINK_REL}" header or homepage <link>, and neither ${siteUrl}/wp-json nor ` +
            `${siteUrl}/?rest_route=/ returned a route index. The REST API may be disabled or blocked by the host.`,
        );
    }

    /** Reads the advertised REST root out of a `Link` response header or a homepage `<link>` element. */
    private readAdvertisedApiRoot(response: RESTResponse): string | null {
        const linkHeader = response.Headers?.['link'];
        if (linkHeader) {
            const fromHeader = this.matchApiLink(linkHeader);
            if (fromHeader) return fromHeader;
        }
        if (typeof response.Body === 'string') {
            const m = response.Body.match(
                new RegExp(`<link[^>]+rel=["']${WP_API_LINK_REL.replace(/[/.]/g, '\\$&')}["'][^>]+href=["']([^"']+)["']`, 'i'),
            ) ?? response.Body.match(
                new RegExp(`<link[^>]+href=["']([^"']+)["'][^>]+rel=["']${WP_API_LINK_REL.replace(/[/.]/g, '\\$&')}["']`, 'i'),
            );
            if (m) return m[1];
        }
        return null;
    }

    /** Extracts the `<url>` whose `rel` is the WordPress API rel from an RFC-5988 Link header value. */
    private matchApiLink(linkHeader: string): string | null {
        for (const part of linkHeader.split(',')) {
            if (!part.includes(WP_API_LINK_REL)) continue;
            const m = part.match(/<([^>]+)>/);
            if (m) return m[1].trim();
        }
        return null;
    }

    /** A body is a route index when it carries the `routes` map (and usually `namespaces`). */
    private looksLikeRouteIndex(body: unknown): boolean {
        if (!body || typeof body !== 'object' || Array.isArray(body)) return false;
        const b = body as Record<string, unknown>;
        return b.routes != null && typeof b.routes === 'object';
    }

    // ── Route index ───────────────────────────────────────────────────────────

    /** Fetches (and caches per API root) the site's own route index. `context=view` is explicit so the
     *  `context=edit` injector leaves this public discovery call alone. */
    private async loadRouteIndex(auth: RESTAuthContext): Promise<WordPressRouteIndex> {
        const ctx = auth as WordPressAuthContext;
        const cached = this.routeIndexCache.get(ctx.ApiRoot);
        if (cached) return cached;

        const url = this.withQueryParam(
            `${this.GetBaseURL({} as MJCompanyIntegrationEntity, ctx)}/`, 'context', 'view',
        );
        const response = await this.MakeHTTPRequest(ctx, url, 'GET', this.BuildHeaders(ctx));
        if (response.Status < 200 || response.Status >= 300 || !this.looksLikeRouteIndex(response.Body)) {
            throw new Error(
                `Route index at ${ctx.ApiRoot} returned HTTP ${response.Status} without a routes map ` +
                `(${this.vendorCodeOf(response.Body) ?? 'no vendor code'}).`,
            );
        }
        const index = response.Body as WordPressRouteIndex;
        this.routeIndexCache.set(ctx.ApiRoot, index);
        return index;
    }

    /**
     * Derives LISTABLE COLLECTIONS from the route index. A route qualifies when it is readable, carries no
     * path capture of its own, is not a namespace root, and registers `per_page` — the discriminator that
     * separates a record collection from the RPC routes WordPress also registers.
     */
    private deriveCollectionRoutes(index: WordPressRouteIndex): Array<{ Path: string; Namespace: string; SupportsWrite: boolean }> {
        const out: Array<{ Path: string; Namespace: string; SupportsWrite: boolean }> = [];
        for (const [path, entry] of Object.entries(index.routes ?? {})) {
            if (path === '/' || /\(\?P</.test(path)) continue;
            const ns = (entry.namespace ?? '').trim();
            if (!ns) continue;                       // e.g. /batch/v1 — a write TRANSPORT, not a record family
            if (path === `/${ns}`) continue;         // the namespace root index
            const methods = (entry.methods ?? []).map(m => m.toUpperCase());
            if (!methods.includes('GET')) continue;

            const readEndpoint = (entry.endpoints ?? []).find(e => (e.methods ?? []).map(m => m.toUpperCase()).includes('GET'));
            if (!readEndpoint?.args || !('per_page' in readEndpoint.args)) continue;

            out.push({
                Path: path,
                Namespace: ns,
                SupportsWrite: methods.includes('POST') || methods.includes('PUT') || methods.includes('PATCH'),
            });
        }
        return out;
    }

    /**
     * Namespaces the OPERATOR scoped out of 1.0.0, read from the Integration row's own
     * `Configuration.OutOfScopeObjectFamilies[].kind`. First-party RPC / admin / analytics / legacy /
     * transport / alias namespaces are not record collections and stay out. `third-party-plugin` and the
     * per-site remainder are NOT excluded — the metadata's own reasons say those are "reachable at runtime
     * via route-index discovery", which is precisely this path.
     */
    private readScopedOutNamespaces(companyIntegration: MJCompanyIntegrationEntity): Set<string> {
        const out = new Set<string>();
        const integration = this.tryGetIntegration(companyIntegration.IntegrationID);
        const cfg = this.parseJsonObject(integration?.Configuration ?? null);
        const families = cfg?.['OutOfScopeObjectFamilies'];
        if (!Array.isArray(families)) return out;
        for (const raw of families) {
            if (!raw || typeof raw !== 'object') continue;
            const fam = raw as Record<string, unknown>;
            const kind = typeof fam.kind === 'string' ? fam.kind : '';
            const ns = typeof fam.namespace === 'string' ? fam.namespace.trim() : '';
            if (!ns || ns === '(per-site)') continue;
            if (kind.startsWith('first-party') || kind === 'vendored-third-party-namespace') out.add(ns);
        }
        return out;
    }

    // ── OPTIONS field description ─────────────────────────────────────────────

    /** Issues `OPTIONS <route>` and maps the endpoint's JSON Schema properties to ExternalFieldSchema. */
    private async describeRoute(auth: RESTAuthContext, routePath: string): Promise<ExternalFieldSchema[]> {
        const ctx = auth as WordPressAuthContext;
        const url = `${this.GetBaseURL({} as MJCompanyIntegrationEntity, ctx)}${routePath}`;
        const response = await this.MakeHTTPRequest(ctx, url, 'OPTIONS', this.BuildHeaders(ctx));
        if (response.Status < 200 || response.Status >= 300) {
            const classified = this.ClassifyWordPressResponse(response.Status, response.Body);
            throw new Error(`OPTIONS ${routePath} → HTTP ${response.Status} (${classified.VendorCode ?? classified.Reason})`);
        }
        const body = response.Body as WordPressOptionsResponse | null;
        const properties = body?.schema?.properties;
        if (!properties) return [];

        const pkName = this.itemRouteKeyName(routePath);
        const out: ExternalFieldSchema[] = [];
        for (const [name, prop] of Object.entries(properties)) {
            out.push(this.schemaPropertyToField(name, prop, pkName));
        }
        return out;
    }

    /**
     * Maps ONE JSON Schema property to a field schema, provable-only throughout: `IsPrimaryKey` is set only
     * when the property is the one the route's own ITEM path addresses records by (Tier-1 addressing-path
     * evidence, the same class the extractor used); `AllowsNull` only when the declared type union contains
     * `null`; `IsForeignKey` is never inferred, because WordPress publishes no machine-readable FK model.
     */
    private schemaPropertyToField(name: string, prop: WordPressSchemaProperty, pkName: string | null): ExternalFieldSchema {
        const types = Array.isArray(prop.type) ? prop.type : (prop.type ? [prop.type] : []);
        const nullable = types.includes('null');
        const concrete = types.filter(t => t !== 'null');
        const isPK = pkName != null && name === pkName;
        return {
            Name: name,
            Label: name,
            Description: prop.description,
            DataType: prop.format === 'date-time' ? 'datetime' : (concrete[0] ?? 'string'),
            IsRequired: prop.required === true,
            AllowsNull: nullable ? true : undefined,
            IsPrimaryKey: isPK ? true : undefined,
            IsUniqueKey: isPK,
            IsReadOnly: prop.readonly === true,
            IsForeignKey: false,
            ForeignKeyTarget: null,
            MaxLength: this.toPositiveInt(prop.maxLength) ?? null,
        };
    }

    /**
     * UNION of declared × described, keyed by field name. Declared WINS on every attribute (it is the
     * docs-provable maximum a fully-privileged credential sees); a described-only field is APPENDED as a
     * per-site custom. Nothing is ever removed — a thinner runtime schema is a capability artefact.
     */
    private unionFieldSchemas(declared: ExternalFieldSchema[], described: ExternalFieldSchema[]): ExternalFieldSchema[] {
        const byName = new Map(declared.map(f => [f.Name, f]));
        const out = [...declared];
        for (const field of described) {
            const existing = byName.get(field.Name);
            if (!existing) { out.push(field); byName.set(field.Name, field); continue; }
            if (existing.MaxLength == null && field.MaxLength != null) existing.MaxLength = field.MaxLength;
            if (!existing.Description && field.Description) existing.Description = field.Description;
        }
        return out;
    }

    /** The literal (untemplated) collection path to OPTIONS for an object, or null when it is parent-templated. */
    private optionsRoutePathFor(integrationID: string, objectName: string): string | null {
        const obj = this.tryGetCachedObject(integrationID, objectName);
        // A route-index-discovered object is NAMED by its path, so it can be described directly.
        const path = obj ? this.declaredListPath(obj) : (objectName.startsWith('/') ? objectName : null);
        if (!path) return null;
        if (/\{\w+\}/.test(path)) return null;
        return path;
    }

    /** Name of the key an item route addresses records by, e.g. `/wp/v2/posts` → `id` via its `{id}` sibling. */
    private itemRouteKeyName(collectionPath: string): string | null {
        const index = [...this.routeIndexCache.values()][0];
        if (!index?.routes) return null;
        const prefix = `${collectionPath}/`;
        for (const path of Object.keys(index.routes)) {
            if (!path.startsWith(prefix)) continue;
            const tail = path.slice(prefix.length);
            const m = tail.match(/^\(\?P<(\w+)>/);
            if (m) return m[1] === 'id' ? 'id' : m[1];
        }
        return null;
    }

    // ── Query-param construction ──────────────────────────────────────────────

    /**
     * The per-object read parameters, every one of them READ FROM METADATA:
     *   - STABLE SORT (`orderby=id&order=asc`) on the page-numbered collections whose declared
     *     `StableOrderingKey` is `id`, to minimise the offset drift page arithmetic is prone to.
     *   - The INCREMENTAL filter, and ONLY where the object declares one. The six objects that register
     *     `modified_after` but expose no modified column, plus `wp/v2/users` and `wc/v3/customers` (whose
     *     controllers inherit no date params at all), carry a null watermark in metadata and therefore get
     *     NO delta path here. The connector never synthesises one, and never rounds an insert-only
     *     high-water up to "incremental supported".
     */
    private async buildObjectQueryParams(
        obj: MJIntegrationObjectEntity,
        cfg: WordPressObjectConfig | null,
        ctx: FetchContext,
        auth: RESTAuthContext,
    ): Promise<Record<string, string>> {
        const params: Record<string, string> = {};

        if (obj.SupportsPagination && obj.PaginationType === 'PageNumber' && obj.StableOrderingKey === 'id') {
            params.orderby = 'id';
            params.order = 'asc';
        }

        const watermark = cfg?.incrementalWatermark;
        if (watermark?.filterParam && this.hasLiveIncrementalWatermark(obj, cfg) && ctx.WatermarkValue) {
            const since = await this.watermarkFilterValue(obj, watermark, ctx.WatermarkValue, auth);
            if (since) {
                params[watermark.filterParam] = since;
                if (watermark.datesAreGmt) params.dates_are_gmt = 'true';
                // An incremental pass orders by the watermark so the max-seen advances monotonically.
                if (watermark.orderby) { params.orderby = watermark.orderby; params.order = 'asc'; }
                // `beforeParam` (`modified_before`) is DELIBERATELY not sent. `FetchContext` carries no
                // upper bound — the engine never bounds the window — so any `modified_before` this
                // connector invented would be a fabricated ceiling that could drop records committed
                // mid-run. The param stays declared in metadata for the day the engine supplies a bound.
            }
        }
        return params;
    }

    /**
     * Renders the stored watermark into the exact string the object's declared filter param compares
     * against, with ROUND-TRIP FIDELITY as the first rule: the value normally came FROM this object's own
     * watermark field, so it is already in the vendor's own representation and goes back verbatim.
     *
     * THE ONE CASE THAT IS NOT A ROUND TRIP: after a CLEAN FULL sync the engine deliberately replaces the
     * connector's max-seen value with wall-clock `new Date().toISOString()` — an INSTANT, in UTC, carrying
     * a `Z`. For a `dates_are_gmt` object that is exactly right: WooCommerce compares against the `_gmt`
     * columns, and this connector already sends `dates_are_gmt=true` alongside. For a SITE-LOCAL object it
     * is not: `WP_REST_Posts_Controller` date_query's `modified_after` against `post_modified`, the
     * site-local column, so on a site behind UTC a UTC instant is LATER than the same moment's local wall
     * clock and the next incremental would silently SKIP everything modified inside the offset window.
     * Project it into the site's own wall clock using the `gmt_offset` the REST index publishes.
     *
     * When the site publishes no usable offset the value is passed through UNSHIFTED and the gap is said
     * out loud — a guessed offset would fabricate a vendor fact, and an unshifted filter is no worse than
     * the value the engine stored.
     */
    private async watermarkFilterValue(
        obj: MJIntegrationObjectEntity,
        watermark: NonNullable<WordPressObjectConfig['incrementalWatermark']>,
        stored: string,
        auth: RESTAuthContext,
    ): Promise<string | null> {
        const normalized = this.toWordPressDate(stored);
        if (!normalized) return null;
        // No designator → it round-tripped from the object's own field, which is already in the column's
        // own representation. GMT-column object → a UTC instant is exactly what it compares against.
        if (!/(Z|[+-]\d{2}:?\d{2})$/.test(normalized) || watermark.datesAreGmt === true) return normalized;

        const offsetMinutes = await this.siteGmtOffsetMinutes(auth);
        if (offsetMinutes === null) {
            this.warnOnce(
                'watermark-site-offset-unknown',
                `[WordPress] The stored watermark for "${obj.Name}" is an absolute UTC instant (the engine advances ` +
                `to wall-clock "now" after a clean full sync) but "${watermark.filterParam}" compares against the ` +
                `SITE-LOCAL "${watermark.field ?? obj.IncrementalWatermarkField}" column, and this site publishes no ` +
                `"gmt_offset" in its REST index. The filter is sent UNSHIFTED: on a site behind UTC the next ` +
                `incremental can skip records modified inside the offset window. Re-run a full sync, or set the ` +
                `site's timezone, to close it — the connector will not guess an offset.`,
            );
            return normalized;
        }
        const instant = Date.parse(normalized);
        if (!Number.isFinite(instant)) return normalized;
        return new Date(instant + offsetMinutes * 60_000).toISOString().replace(/\.\d{3}Z$/, '');
    }

    /**
     * The site's UTC offset in MINUTES, read from the `gmt_offset` the public REST index advertises
     * (hours, possibly fractional — India is 5.5, Chatham is 12.75). Null when the site does not publish
     * one or the index is unreachable; callers must then decline to shift rather than assume UTC.
     */
    private async siteGmtOffsetMinutes(auth: RESTAuthContext): Promise<number | null> {
        try {
            const index = await this.loadRouteIndex(auth);
            const raw = index.gmt_offset;
            if (raw === null || raw === undefined) return null;
            const hours = typeof raw === 'number' ? raw : Number(String(raw).trim());
            if (!Number.isFinite(hours) || String(raw).trim() === '') return null;
            return Math.round(hours * 60);
        } catch {
            return null;
        }
    }

    /**
     * Normalises a stored watermark to the ISO-8601 form WordPress's date params accept — with ROUND-TRIP
     * FIDELITY as the first rule. The watermark came FROM the object's own `modified` / `date_modified_gmt`
     * field, which WordPress renders WITHOUT a timezone designator and interprets in the SITE's timezone
     * (unless `dates_are_gmt` is set). Re-projecting such a value through UTC would silently shift the
     * filter by the site's offset and skip or re-fetch records, so an already-ISO value is handed back
     * verbatim; only a non-ISO representation is converted.
     */
    private toWordPressDate(value: string): string | null {
        const trimmed = value.trim();
        if (!trimmed) return null;
        if (/^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}(:\d{2})?(\.\d+)?(Z|[+-]\d{2}:?\d{2})?$/.test(trimmed)) {
            return trimmed.replace(' ', 'T').replace(/\.\d+/, '');
        }
        const parsed = Date.parse(trimmed);
        if (!Number.isFinite(parsed)) return null;
        return new Date(parsed).toISOString().replace(/\.\d{3}Z$/, '');
    }

    /** Max value of the object's declared watermark field across a batch — max-SEEN, never most-recent. */
    private maxWatermark(obj: MJIntegrationObjectEntity, records: ExternalRecord[]): string | null {
        const field = obj.IncrementalWatermarkField;
        if (!obj.SupportsIncrementalSync || !field || records.length === 0) return null;
        let best: string | null = null;
        let bestMs = Number.NEGATIVE_INFINITY;
        for (const record of records) {
            const raw = record.Fields[field];
            if (typeof raw !== 'string' || raw.length === 0) continue;
            const ms = Date.parse(raw);
            if (!Number.isFinite(ms) || ms <= bestMs) continue;
            bestMs = ms;
            best = raw;
        }
        return best;
    }

    // ── Namespace credential guard ────────────────────────────────────────────

    /**
     * A WooCommerce consumer key/secret CANNOT read `wp/v2` — `WC_REST_Authentication::is_request_to_rest_api()`
     * matches only URIs whose path after the REST prefix begins `wc/` or `wc-`. So a Woo-only connection must
     * report every core object as an explicit CAPABILITY GAP rather than sync it empty and green.
     */
    private namespaceCredentialGuard(
        obj: MJIntegrationObjectEntity,
        cfg: WordPressObjectConfig | null,
        auth: RESTAuthContext,
    ): FetchWarning | null {
        const ctx = auth as WordPressAuthContext;
        if (ctx.HasApplicationPassword || !ctx.HasWooCredential) return null;
        const ns = cfg?.namespace ?? '';
        if (ns.startsWith('wc/') || ns.startsWith('wc-')) return null;
        return {
            Code: 'CAPABILITY_WOO_ONLY_CREDENTIAL',
            Message:
                `"${obj.Name}" lives in namespace "${ns || 'wp/v2'}", which a WooCommerce consumer key/secret cannot ` +
                `authenticate at all. This connection has NO WordPress Application Password, so no record was fetched — ` +
                `this is a credential gap, not an empty object. Add a username + Application Password to sync wp/v2.`,
            Data: { object: obj.Name, namespace: ns, hasApplicationPassword: false, hasWooCredential: true },
        };
    }

    // ── Graceful degrades ─────────────────────────────────────────────────────

    /**
     * Turns the two failures that are FACTS ABOUT THE SITE (rather than sync faults) into a warned
     * zero-record result:
     *   - 404 / `rest_no_route` — the route is not registered on THIS site. WooCommerce order fulfillments
     *     sit behind `FeaturesUtil::feature_is_enabled('fulfillments')`, and any gated or plugin-provided
     *     route can be absent the same way. That is correct behaviour for the site, not a broken sync.
     *   - 401 / 403 with a WordPress envelope — the credential lacks the capability for this collection.
     * Everything else (5xx, transport, throttling) propagates so the engine retries or fails loudly.
     */
    private gracefulFetchFailure(obj: MJIntegrationObjectEntity, status: number | null, body: unknown): FetchBatchResult | null {
        if (status == null) return null;
        const classified = this.ClassifyWordPressResponse(status, body);

        if (status === 404) {
            return { Records: [], HasMore: false, Warnings: [{
                Code: 'ROUTE_NOT_REGISTERED',
                Message:
                    `"${obj.Name}" (${obj.APIPath}) is not registered on this site — the route index has no such route ` +
                    `(${classified.VendorCode ?? 'HTTP 404'}). WordPress route registration is per-site and feature-gated, ` +
                    `so this is an ABSENT capability on this install, not a sync failure. Nothing was deactivated.`,
                Data: { object: obj.Name, path: obj.APIPath, status, vendorCode: classified.VendorCode },
            }] };
        }
        if (status === 401 || status === 403) {
            return { Records: [], HasMore: false, Warnings: [{
                Code: classified.Reason === 'waf-or-host-block-html-body' ? 'BLOCKED_BY_HOST_OR_WAF' : 'CAPABILITY_FORBIDDEN',
                Message: classified.Reason === 'waf-or-host-block-html-body'
                    ? `"${obj.Name}" was blocked BEFORE reaching the WordPress REST API — HTTP ${status} with an HTML body ` +
                      `is a WAF / host / mod_security block, not an API capability refusal. Retrying will not help; the ` +
                      `site's host or firewall must allow this request.`
                    : `"${obj.Name}" is forbidden to this credential (HTTP ${status}, ${classified.VendorCode ?? 'no vendor code'}). ` +
                      `WordPress capability checks are per-route, so this is a permission gap on the credential — no record ` +
                      `was fetched and nothing was deactivated.`,
                Data: { object: obj.Name, status, vendorCode: classified.VendorCode, reason: classified.Reason },
            }] };
        }
        return null;
    }

    /**
     * A NESTED collection (`/wc/v3/orders/{order_id}/notes`, `/wp/v2/posts/{parent}/revisions`, …) fans out
     * one request per parent, and the base resolves those parent ids from the ALREADY-SYNCED rows in the MJ
     * target database. When no metadata provider is reachable — the parent object has not been mapped or
     * synced yet, or the connector is running outside a database context — that is a DAG-ordering fact, not
     * a connector fault: surface it as a named warning so the run artifact shows WHY the object is empty,
     * instead of failing the whole sync or reporting a silent zero.
     */
    private parentResolutionUnavailable(obj: MJIntegrationObjectEntity, err: unknown): FetchBatchResult | null {
        const message = this.errText(err);
        if (!/RunView|Metadata\.?Provider|No provider|provider is not set/i.test(message)) return null;
        return { Records: [], HasMore: false, Warnings: [{
            Code: 'PARENT_RESOLUTION_UNAVAILABLE',
            Message:
                `"${obj.Name}" is a nested collection (${obj.APIPath}) whose parent ids are read from the already-synced ` +
                `parent records, and that lookup was unavailable (${message}). Sync the parent object first, or map it, ` +
                `so this object has parents to iterate. No record was fetched and nothing was deactivated.`,
            Data: { object: obj.Name, path: obj.APIPath, reason: 'parent-id-lookup-unavailable' },
        }] };
    }

    /** Clears any read failure remembered for this object's route, so a retry starts from a clean slate. */
    private clearReadFailures(obj: MJIntegrationObjectEntity, cfg: WordPressObjectConfig | null): void {
        const path = cfg?.listPath ?? obj.APIPath;
        for (const key of [...this.lastReadFailureByPath.keys()]) {
            if (key.endsWith(path)) this.lastReadFailureByPath.delete(key);
        }
    }

    /** The non-2xx read outcome recorded for this object's route during the pass just completed. */
    private recordedReadFailure(obj: MJIntegrationObjectEntity, cfg: WordPressObjectConfig | null): { Status: number; Body: unknown } | null {
        const path = cfg?.listPath ?? obj.APIPath;
        for (const [key, value] of this.lastReadFailureByPath) {
            if (key.endsWith(path)) return value;
        }
        return null;
    }

    // ── Soft-delete (trash) capture ───────────────────────────────────────────

    /**
     * WordPress post types SOFT-delete: `DELETE` moves the row to `status=trash` and trashed rows stay
     * listable via `status=trash`. This sweep captures them so a soft delete is visible to the engine.
     *
     * HONEST LIMITS, stated rather than papered over: there is NO deleted-records feed anywhere in wp/v2 or
     * wc/v3, and a HARD delete (`?force=true`) leaves no tombstone at all — so full deletion reconciliation
     * remains a declared KEY SWEEP, not detection. The sweep runs only on a fully-drained pass, only for
     * objects whose metadata declares trash semantics in `wp/v2`, and only for an AUTHENTICATED connection
     * (an anonymous caller can never see trash, and `status` is itself capability-gated).
     */
    private async fetchTrashedRecords(
        obj: MJIntegrationObjectEntity,
        cfg: WordPressObjectConfig | null,
        ctx: FetchContext,
        auth: RESTAuthContext,
        mainPass: FetchBatchResult,
    ): Promise<{ Records: ExternalRecord[]; Warning?: FetchWarning }> {
        const wpAuth = auth as WordPressAuthContext;
        if (mainPass.HasMore) return { Records: [] };
        if (!wpAuth.HasApplicationPassword) return { Records: [] };
        const semantics = cfg?.deleteSemantics?.semantics ?? '';
        if (!semantics.startsWith('soft-delete-to-trash') && !semantics.startsWith('trash-gated')) return { Records: [] };
        if ((cfg?.namespace ?? '') !== 'wp/v2') return { Records: [] };
        if (!this.GetCachedFields(obj.ID).some(f => f.Name === 'status')) return { Records: [] };

        const seen = new Set(mainPass.Records.map(r => r.ExternalID));
        this.activeFetchParams.set(obj.Name, { ...await this.buildObjectQueryParams(obj, cfg, ctx, auth), status: 'trash' });
        try {
            const pass = await super.FetchChanges({ ...ctx, CurrentPage: undefined, CurrentOffset: undefined, AfterKeyValue: null });
            return { Records: pass.Records.filter(r => !seen.has(r.ExternalID)) };
        } catch (err) {
            return { Records: [], Warning: {
                Code: 'SOFT_DELETE_SWEEP_UNAVAILABLE',
                Message:
                    `Soft-delete (status=trash) sweep for "${obj.Name}" could not run (${this.errText(err)}). The ` +
                    `\`status\` parameter is capability-gated, so trashed records are invisible to this credential. ` +
                    `WordPress publishes NO deleted-records feed and a hard delete leaves no tombstone, so deletion ` +
                    `reconciliation for this object remains a declared KEY SWEEP — the connector does not claim delete detection.`,
                Data: { object: obj.Name },
            } };
        } finally {
            this.activeFetchParams.delete(obj.Name);
        }
    }

    /** Flags any record carrying WordPress's `trash` status so the engine applies the connection's DeleteBehavior. */
    private markTrashedAsDeleted(records: ExternalRecord[]): void {
        for (const record of records) {
            if (record.Fields['status'] === 'trash') record.IsDeleted = true;
        }
    }

    // ── Global styles (declared KnownGap: "wp/v2 global styles enumeration") ──

    /** True for the one declared object whose collection route WordPress never registers. */
    private isGlobalStylesObject(obj: MJIntegrationObjectEntity, cfg: WordPressObjectConfig | null): boolean {
        const path = cfg?.listPath ?? obj.APIPath;
        return path.startsWith('/wp/v2/global-styles/') && /\{\w+\}/.test(path);
    }

    /**
     * WordPress core registers NO collection route for global styles — only `/wp/v2/global-styles/{id}` and
     * `/revisions` — so the ids cannot be listed and the object would otherwise sync zero rows while looking
     * healthy (the declared metadata records this in `KnownGaps: "wp/v2 global styles enumeration"`).
     *
     * The ids ARE reachable through WordPress's own HAL links: each theme record advertises its user global
     * styles post as `_links["wp:user-global-styles"]`. This walks that link — the source's own model, not a
     * guessed URL — and fetches each id. When the link is absent the object reports an EXPLICIT warning
     * rather than a silent empty success.
     */
    private async fetchGlobalStyles(
        obj: MJIntegrationObjectEntity,
        cfg: WordPressObjectConfig | null,
        ctx: FetchContext,
        auth: RESTAuthContext,
    ): Promise<FetchBatchResult> {
        const baseURL = this.GetBaseURL(ctx.CompanyIntegration, auth);
        const headers = this.BuildHeaders(auth);
        const fields = this.GetCachedFields(obj.ID);
        const pkNames = fields.filter(f => f.IsPrimaryKey).sort((a, b) => a.Sequence - b.Sequence).map(f => f.Name);

        let themes: Record<string, unknown>[];
        try {
            const response = await this.MakeHTTPRequest(auth, `${baseURL}/wp/v2/themes?status=active`, 'GET', headers);
            if (response.Status < 200 || response.Status >= 300) {
                throw new Error(`HTTP ${response.Status} (${this.vendorCodeOf(response.Body) ?? 'no vendor code'})`);
            }
            themes = this.NormalizeResponse(response.Body, null);
        } catch (err) {
            return { Records: [], HasMore: false, Warnings: [this.globalStylesWarning(obj, `active theme lookup failed: ${this.errText(err)}`)] };
        }

        const ids = new Set<string>();
        for (const theme of themes) {
            for (const id of this.userGlobalStyleIDs(theme)) ids.add(id);
        }
        if (ids.size === 0) {
            return { Records: [], HasMore: false, Warnings: [this.globalStylesWarning(obj, 'no theme advertised a wp:user-global-styles link')] };
        }

        const itemPath = cfg?.listPath ?? obj.APIPath;
        const records: ExternalRecord[] = [];
        for (const id of ids) {
            try {
                const url = `${baseURL}${itemPath.replace(/\{\w+\}/, encodeURIComponent(id))}`;
                const response = await this.MakeHTTPRequest(auth, url, 'GET', headers);
                if (response.Status < 200 || response.Status >= 300) continue;
                for (const raw of this.NormalizeResponse(response.Body, obj.ResponseDataKey)) {
                    records.push(this.buildRecord(raw, obj.Name, pkNames));
                }
            } catch { /* one unreadable global-styles row must not fail the object */ }
        }
        return { Records: records, HasMore: false };
    }

    /** Extracts global-styles ids from a theme record's HAL `_links`. */
    private userGlobalStyleIDs(theme: Record<string, unknown>): string[] {
        const links = theme['_links'];
        if (!links || typeof links !== 'object') return [];
        const out: string[] = [];
        for (const [rel, value] of Object.entries(links as Record<string, unknown>)) {
            if (!/user-global-styles$/i.test(rel) || !Array.isArray(value)) continue;
            for (const entry of value) {
                const href = entry && typeof entry === 'object' ? (entry as Record<string, unknown>).href : null;
                if (typeof href !== 'string') continue;
                const m = href.match(/\/global-styles\/([^/?#]+)/);
                if (m) out.push(decodeURIComponent(m[1]));
            }
        }
        return out;
    }

    /** The honest, named warning for an unenumerable global-styles object. */
    private globalStylesWarning(obj: MJIntegrationObjectEntity, detail: string): FetchWarning {
        return {
            Code: 'GLOBAL_STYLES_NOT_ENUMERABLE',
            Message:
                `"${obj.Name}" cannot be listed: WordPress core registers NO collection route for global styles, only ` +
                `/wp/v2/global-styles/{id}. The connector resolves ids from the active theme's own ` +
                `wp:user-global-styles link, and that failed here (${detail}). Zero records is a KNOWN vendor ` +
                `enumeration gap for this object, not an empty data set.`,
            Data: { object: obj.Name, detail },
        };
    }

    /**
     * Builds an ExternalRecord with the FULL source record in `Fields` — never a narrow literal. The
     * framework's custom-column capture diffs `keys(Fields)` against the active field maps, so anything
     * dropped here (per-site `meta`, plugin-added properties) would be invisible and unrecoverable.
     */
    private buildRecord(raw: Record<string, unknown>, objectType: string, pkFieldNames: string[]): ExternalRecord {
        const usable = pkFieldNames.length > 0
            && pkFieldNames.every(n => raw[n] != null && String(raw[n]).length > 0);
        const externalID = usable
            ? pkFieldNames.map(n => String(raw[n])).join('|')
            : (raw.id != null ? String(raw.id) : '');
        return { ExternalID: externalID, ObjectType: objectType, Fields: raw };
    }

    // ── Credential loading ────────────────────────────────────────────────────

    /** Reads the credential from the linked `MJ: Credentials` row, merged over the connection Configuration JSON. */
    private async loadCredentials(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<WordPressCredentials> {
        let fromCredential: WordPressCredentials | null = null;
        if (companyIntegration.CredentialID) {
            try {
                const md = new Metadata();
                const credential = await md.GetEntityObject<MJCredentialEntity>('MJ: Credentials', contextUser);
                const loaded = await credential.Load(companyIntegration.CredentialID);
                if (loaded && credential.Values) fromCredential = this.parseCredentialJson(credential.Values);
            } catch {
                // A credential the connection cannot load is a configuration problem, not a crash: the
                // Configuration fallback below still applies and Authenticate reports what is missing.
            }
        }
        const fromConfig = companyIntegration.Configuration
            ? this.parseCredentialJson(companyIntegration.Configuration)
            : null;
        return {
            SiteUrl: fromCredential?.SiteUrl ?? fromConfig?.SiteUrl,
            ApiRoot: fromCredential?.ApiRoot ?? fromConfig?.ApiRoot,
            Username: fromCredential?.Username ?? fromConfig?.Username,
            ApplicationPassword: fromCredential?.ApplicationPassword ?? fromConfig?.ApplicationPassword,
            WooConsumerKey: fromCredential?.WooConsumerKey ?? fromConfig?.WooConsumerKey,
            WooConsumerSecret: fromCredential?.WooConsumerSecret ?? fromConfig?.WooConsumerSecret,
        };
    }

    /** Extracts the WordPress credential fields from a credential/Configuration JSON string. */
    private parseCredentialJson(json: string): WordPressCredentials | null {
        const parsed = this.parseJsonObject(json);
        if (!parsed) return null;
        return {
            SiteUrl: this.firstString(parsed, ['siteUrl', 'SiteUrl', 'site_url', 'BaseURL', 'baseURL', 'BaseUrl', 'baseUrl']),
            ApiRoot: this.firstString(parsed, ['apiRoot', 'ApiRoot', 'restApiRoot', 'RestApiRoot', 'APIBaseURL']),
            Username: this.firstString(parsed, ['username', 'Username', 'user', 'login']),
            ApplicationPassword: this.firstString(parsed, ['applicationPassword', 'ApplicationPassword', 'appPassword', 'password', 'Password']),
            WooConsumerKey: this.firstString(parsed, ['wooConsumerKey', 'WooConsumerKey', 'consumer_key', 'consumerKey']),
            WooConsumerSecret: this.firstString(parsed, ['wooConsumerSecret', 'WooConsumerSecret', 'consumer_secret', 'consumerSecret']),
        };
    }

    /** Whether this connection opted into Woo's query-param credential fallback (hosts that strip Authorization). */
    private wooQueryParamAuthEnabled(companyIntegration: MJCompanyIntegrationEntity): boolean {
        const cfg = this.parseJsonObject(companyIntegration.Configuration);
        if (!cfg) return false;
        for (const key of ['wooAuthViaQueryParams', 'WooAuthViaQueryParams', 'wooQueryParamAuth']) {
            const v = cfg[key];
            if (v === true || v === 'true') return true;
        }
        return false;
    }

    /** Reads a trimmed string value from the connection Configuration JSON. */
    private readConnectionConfigString(companyIntegration: MJCompanyIntegrationEntity, keys: string[]): string | null {
        const cfg = this.parseJsonObject(companyIntegration.Configuration);
        if (!cfg) return null;
        const v = this.firstString(cfg, keys);
        return v != null && v.length > 0 ? v : null;
    }

    // ── Metadata accessors (seams; test subclasses override these) ────────────

    /** All ACTIVE IntegrationObjects for the integration; `[]` when the engine cache is unavailable. */
    protected getCachedObjects(integrationID: string): MJIntegrationObjectEntity[] {
        try {
            return IntegrationEngineBase.Instance.GetActiveIntegrationObjects(integrationID);
        } catch {
            return [];
        }
    }

    /** The Integration row itself (for the Integration-level Configuration blob); null when unavailable. */
    protected tryGetIntegration(_integrationID: string): { Configuration?: string | null } | null {
        try {
            return IntegrationEngineBase.Instance.GetIntegrationByName(this.IntegrationName) ?? null;
        } catch {
            return null;
        }
    }

    /** Non-throwing IntegrationObject lookup by integration + name. */
    private tryGetCachedObject(integrationID: string, objectName: string): MJIntegrationObjectEntity | null {
        try {
            return this.GetCachedObject(integrationID, objectName);
        } catch {
            return null;
        }
    }

    /** Non-throwing IntegrationObject lookup by name alone (used by StableOrderingKey, called early). */
    private tryGetCachedObjectByName(objectName: string): MJIntegrationObjectEntity | null {
        const integrationID = this.tryGetIntegrationID();
        return integrationID ? this.tryGetCachedObject(integrationID, objectName) : null;
    }

    /** This connector's own `MJ: Integrations.ID`; null when the engine cache is not loaded yet. */
    protected tryGetIntegrationID(): string | null {
        try {
            return IntegrationEngineBase.Instance.GetIntegrationByName(this.IntegrationName)?.ID ?? null;
        } catch {
            return null;
        }
    }

    /** The declared collection path for an object (`Configuration.listPath`, else its APIPath). */
    private declaredListPath(obj: MJIntegrationObjectEntity): string {
        return this.objectConfig(obj)?.listPath ?? obj.APIPath;
    }

    /** Typed view of an IntegrationObject's Configuration JSON. */
    private objectConfig(obj: MJIntegrationObjectEntity): WordPressObjectConfig | null {
        const parsed = this.parseJsonObject(obj.Configuration);
        return parsed ? (parsed as unknown as WordPressObjectConfig) : null;
    }

    /** The `context=edit`-gated field names declared for whichever object owns this request path. */
    private contextGatedFieldsForPath(auth: WordPressAuthContext, routePath: string): string[] {
        for (const obj of this.getCachedObjects(auth.IntegrationID)) {
            const cfg = this.objectConfig(obj);
            const declared = cfg?.listPath ?? obj.APIPath;
            if (!declared || !routePath.endsWith(declared)) continue;
            return cfg?.contextGatedFields ?? [];
        }
        return [];
    }

    // ── Small helpers ─────────────────────────────────────────────────────────

    /** Canonical form of a route path with its captures collapsed, so `{id}` and `(?P<id>[\\d]+)` compare equal. */
    private canonicalRoutePath(path: string): string {
        return path
            .replace(/\(\?P<[^>]+>[^)]*\)/g, '{}')
            .replace(/\{\w+\}/g, '{}')
            .replace(/\/+$/, '');
    }

    /** A readable label for a discovered route, e.g. `/wp/v2/my-events` → `My Events (wp/v2)`. */
    private humanLabelForRoute(path: string, namespace: string): string {
        const tail = path.startsWith(`/${namespace}/`) ? path.slice(namespace.length + 2) : path.replace(/^\//, '');
        const words = tail.split('/').filter(Boolean).join(' ').replace(/[_-]+/g, ' ').trim();
        const label = words.replace(/\b\w/g, c => c.toUpperCase());
        return `${label || tail} (${namespace})`;
    }

    /** Builds a SourceObjectInfo for a route-index-discovered object. */
    private toSourceObjectInfo(obj: ExternalObjectSchema, fields: ExternalFieldSchema[]): SourceObjectInfo {
        return {
            ExternalName: obj.Name,
            ExternalLabel: obj.Label,
            Description: obj.Description,
            Fields: fields.map(f => ({
                Name: f.Name,
                Label: f.Label,
                Description: f.Description,
                SourceType: f.DataType,
                IsRequired: f.IsRequired,
                AllowsNull: f.AllowsNull,
                MaxLength: f.MaxLength ?? null,
                Precision: f.Precision ?? null,
                Scale: f.Scale ?? null,
                DefaultValue: f.DefaultValue ?? null,
                IsPrimaryKey: f.IsPrimaryKey ?? false,
                IsUniqueKey: f.IsUniqueKey,
                IsReadOnly: f.IsReadOnly,
                IsForeignKey: f.IsForeignKey ?? false,
                ForeignKeyTarget: f.ForeignKeyTarget ?? null,
            })),
            PrimaryKeyFields: fields.filter(f => f.IsPrimaryKey === true).map(f => f.Name),
            Relationships: [],
        };
    }

    /** Parses the `{ code, message, data:{ status } }` envelope out of a response body. */
    private errorEnvelope(body: unknown): WordPressErrorEnvelope | null {
        if (!body || typeof body !== 'object' || Array.isArray(body)) return null;
        const b = body as Record<string, unknown>;
        if (typeof b.code !== 'string' && typeof b.message !== 'string') return null;
        return {
            code: typeof b.code === 'string' ? b.code : undefined,
            message: typeof b.message === 'string' ? b.message : undefined,
            data: (b.data && typeof b.data === 'object' ? b.data : undefined) as WordPressErrorEnvelope['data'],
        };
    }

    /** The vendor's stable machine code from a response body, when it carries one. */
    private vendorCodeOf(body: unknown): string | null {
        return this.errorEnvelope(body)?.code ?? null;
    }

    /**
     * Reads the HTTP status back out of a failure. `WordPressHTTPError` carries it directly; the base
     * class's paginated loop raises `HTTP <status> from <url>: <body preview>`, which is our own package's
     * stable message format.
     */
    private statusFromError(err: unknown): number | null {
        if (err instanceof WordPressHTTPError) return err.Status;
        const m = this.errText(err).match(/HTTP (\d{3})\b/);
        return m ? Number(m[1]) : null;
    }

    /**
     * Recovers the response body from a failure so it can be classified from the WordPress error ENVELOPE
     * rather than the bare status. The base class's paginated loop raises
     * `HTTP <status> from <url>: <body preview>`, so the preview is parsed back out; an HTML body (a WAF
     * block) is returned as the raw string, which is exactly what the classifier keys on.
     */
    private bodyFromError(err: unknown): unknown {
        const message = this.errText(err);
        const jsonAt = message.indexOf('{');
        if (jsonAt >= 0) {
            const slice = message.slice(jsonAt);
            try { return JSON.parse(slice); } catch { return slice; }
        }
        const htmlAt = message.search(/<\s*(!doctype|html)/i);
        return htmlAt >= 0 ? message.slice(htmlAt) : message;
    }

    /** Best-effort header extraction from an arbitrary thrown value (for ExtractRetryAfterMs). */
    private headersFromUnknownError(error: unknown): Record<string, string> | undefined {
        if (!error || typeof error !== 'object') return undefined;
        const e = error as Record<string, unknown>;
        const source = (e.response && typeof e.response === 'object' ? e.response : e) as Record<string, unknown>;
        const headers = source.headers ?? source.Headers;
        if (headers && typeof headers === 'object') return headers as Record<string, string>;
        return undefined;
    }

    /** Parses a JSON string into a plain object; null for absent/invalid/non-object input. */
    private parseJsonObject(json: string | null | undefined): Record<string, unknown> | null {
        if (!json || typeof json !== 'string') return null;
        try {
            const parsed: unknown = JSON.parse(json);
            return parsed && typeof parsed === 'object' && !Array.isArray(parsed)
                ? parsed as Record<string, unknown>
                : null;
        } catch {
            return null;
        }
    }

    /** First present, non-empty string among the given keys. */
    private firstString(obj: Record<string, unknown>, keys: string[]): string | undefined {
        for (const k of keys) {
            const v = obj[k];
            if (typeof v === 'string' && v.length > 0) return v;
            if (typeof v === 'number' && Number.isFinite(v)) return String(v);
        }
        return undefined;
    }

    /** Coerces a header/metadata value to a positive integer, or null. */
    private toPositiveInt(value: unknown): number | null {
        if (value == null) return null;
        const n = typeof value === 'number' ? value : Number(String(value).trim());
        return Number.isFinite(n) && n > 0 ? Math.floor(n) : null;
    }

    /** Path component of a URL (no query), tolerant of a non-absolute input. */
    private pathOf(url: string): string {
        try { return new URL(url).pathname; } catch { return this.splitQuery(url)[0]; }
    }

    /** Splits a URL into `[beforeQuery, query]`. */
    private splitQuery(url: string): [string, string] {
        const i = url.indexOf('?');
        return i < 0 ? [url, ''] : [url.slice(0, i), url.slice(i + 1)];
    }

    /** Whether the URL already carries a query param of this name (case-insensitive). */
    private hasQueryParam(url: string, name: string): boolean {
        const [, query] = this.splitQuery(url);
        if (!query) return false;
        const lower = name.toLowerCase();
        return query.split('&').some(pair => decodeURIComponent(pair.split('=')[0] ?? '').toLowerCase() === lower);
    }

    /** Appends a query param (URL-encoded), preserving anything already present. */
    private withQueryParam(url: string, name: string, value: string): string {
        const sep = url.includes('?') ? '&' : '?';
        return `${url}${sep}${encodeURIComponent(name)}=${encodeURIComponent(value)}`;
    }

    /** Removes every occurrence of a query param from a URL. */
    private stripQueryParam(url: string, name: string): string {
        const [before, query] = this.splitQuery(url);
        if (!query) return url;
        const lower = name.toLowerCase();
        const kept = query.split('&').filter(pair => decodeURIComponent(pair.split('=')[0] ?? '').toLowerCase() !== lower);
        return kept.length > 0 ? `${before}?${kept.join('&')}` : before;
    }

    /** Logs a capability/diagnostic warning exactly once per key, so an honest signal never becomes noise. */
    private warnOnce(key: string, message: string): void {
        if (this.warnedOnce.has(key)) return;
        this.warnedOnce.add(key);
        console.warn(message);
    }

    /** Message text of an arbitrary thrown value. */
    private errText(err: unknown): string {
        return err instanceof Error ? err.message : String(err);
    }
}

/** Non-2xx that must reach the ENGINE with its headers intact (429/503 → the adaptive AIMD bucket). */
class WordPressHTTPError extends Error {
    public readonly Status: number;
    public readonly Headers: Record<string, string>;
    public readonly VendorCode: string | null;
    constructor(message: string, status: number, headers: Record<string, string>, vendorCode: string | null) {
        super(message);
        this.name = 'WordPressHTTPError';
        this.Status = status;
        this.Headers = headers;
        this.VendorCode = vendorCode;
    }
}

/**
 * Typed view of the per-object `Configuration` JSON the extractor emitted. This is a SHAPE, not a catalog:
 * it says what KIND of facts the metadata carries (namespace, list path, pagination cap, watermark params,
 * delete semantics, context-gated field names) — every VALUE is read from the metadata at runtime.
 */
interface WordPressObjectConfig {
    namespace?: string;
    listPath?: string;
    getOnePath?: string | null;
    responseShape?: string;
    pkField?: string | null;
    pagination?: { type?: string; pageParam?: string; sizeParam?: string; maxPageSize?: number } | null;
    incrementalWatermark?: {
        field?: string;
        filterParam?: string;
        beforeParam?: string;
        datesAreGmt?: boolean;
        orderby?: string;
    } | null;
    incrementalNote?: string | null;
    contextGatedFields?: string[];
    deleteSemantics?: {
        semantics?: string;
        requiresForce?: boolean;
        requiresReassign?: boolean;
        hardDeleteParam?: string;
    } | null;
    parentObjectName?: string;
    parentObjectIDFieldName?: string;
}
