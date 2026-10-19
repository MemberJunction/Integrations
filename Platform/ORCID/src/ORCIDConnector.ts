import { RegisterClass } from '@memberjunction/global';
import { Metadata, RunView, type IMetadataProvider, type UserInfo } from '@memberjunction/core';
import type { MJCompanyIntegrationEntity, MJCredentialEntity, MJIntegrationObjectEntity, MJIntegrationObjectFieldEntity } from '@memberjunction/core-entities';
import {
    BaseIntegrationConnector,
    BaseRESTIntegrationConnector,
    type RESTAuthContext,
    type RESTResponse,
    type PaginationState,
    type PaginationType,
    type ConnectionTestResult,
    type FetchContext,
    type FetchBatchResult,
    type ExternalRecord,
    type FetchWarning,
    type RateLimitPolicy,
} from '@memberjunction/integration-engine';
import {
    ROOT_OBJECT_NAME,
    collectPutCodeItems,
    extractSectionRawItems,
    flattenSectionItem,
    extractMs as extractMsFromNode,
    valueOf as unwrapValue,
} from './orcidRecordExtraction.js';

// ─── Connection configuration ─────────────────────────────────────────

/**
 * Per-connection configuration for the ORCID connector.
 *
 * The ORCID Public API has NO list-all-records endpoint — the iD universe is
 * not enumerable. Instead the universe is SCOPED PER CONNECTION via
 * CompanyIntegration.Configuration. At least one of `searchQuery` / `orcidIds`
 * must be provided.
 */
export interface ORCIDConnectionConfig {
    /**
     * OAuth2 client_credentials grant — client identifier. From the credential store.
     * Omit BOTH this and ClientSecret to run against the ORCID Public API anonymously.
     */
    ClientID?: string;
    /** OAuth2 client_credentials grant — client secret. From the credential store. */
    ClientSecret?: string;
    /** OAuth2 token endpoint. Defaults to the production/sandbox host based on UseSandbox. */
    TokenURL?: string;
    /** OAuth2 scope. Defaults to '/read-public'. */
    Scope?: string;
    /** When true, use the ORCID sandbox hosts (sandbox.orcid.org / pub.sandbox.orcid.org). */
    UseSandbox?: boolean;
    /**
     * Lucene query string for GET /search or /expanded-search resolving the iD universe at runtime.
     * Examples: 'affiliation-org-name:"Harvard University"', 'given-names:Albert family-name:Einstein'.
     */
    SearchQuery?: string;
    /** Whether to use /expanded-search instead of /search. Default: false (plain /search). */
    UseExpandedSearch?: boolean;
    /** Explicit list of ORCID iDs to sync directly (in addition to / instead of searchQuery). */
    OrcidIds?: string[];
    /**
     * Upper bound on the number of iDs resolved from a search per sync ("Goldilocks" — do NOT drain
     * the ~10k ORCID cap). Default: 1000. Explicit OrcidIds are always synced and are not bounded.
     */
    MaxSearchResults?: number;
    /** HTTP request timeout in milliseconds. Default: 30000. */
    RequestTimeoutMs?: number;
    /** Maximum retries for rate-limited / transient failures. Default: 4. */
    MaxRetries?: number;
    /** Minimum interval between outbound requests (ms). Default: 100 (~10 req/s, well under the 40/s burst cap). */
    MinRequestIntervalMs?: number;
    /**
     * Non-secret API host override (e.g. a local mock for replay testing). When unset, the
     * production/sandbox host is selected by UseSandbox. Same pattern as Path LMS / GrowthZone —
     * required for mock-floor e2e testability.
     */
    ApiBaseUrl?: string;
}

/**
 * Authenticated context carried through one FetchChanges cycle.
 *
 * `Token` is undefined in ANONYMOUS mode — the ORCID Public API serves public records with no
 * credential at all, so a connection configured with no credential skips the OAuth grant
 * entirely and sends no Authorization header. See `parseConfig` for how the mode is chosen.
 */
interface ORCIDAuthContext extends RESTAuthContext {
    /** Bearer token, or undefined in anonymous mode (matches the base RESTAuthContext contract). */
    Token?: string;
    /** Token expiry. Undefined in anonymous mode — there is no token to expire or refresh. */
    ExpiresAt?: Date;
    BaseUrl: string;
    Config: ORCIDConnectionConfig;
}

/** Token response from the ORCID OAuth token endpoint. */
interface ORCIDTokenResponse {
    access_token: string;
    token_type: string;
    expires_in: number;
    scope?: string;
}

/** A single result row from GET /search (orcid-identifier.path is the iD). */
interface ORCIDSearchResult {
    'orcid-identifier'?: { path?: string; uri?: string };
}

/** Envelope from GET /search. */
interface ORCIDSearchResponse {
    result?: ORCIDSearchResult[] | null;
    'num-found'?: number;
}

// ─── Constants ────────────────────────────────────────────────────────

const PROD_TOKEN_URL = 'https://orcid.org/oauth/token';
const SANDBOX_TOKEN_URL = 'https://sandbox.orcid.org/oauth/token';
const PROD_API_HOST = 'https://pub.orcid.org/v3.0';
const SANDBOX_API_HOST = 'https://pub.sandbox.orcid.org/v3.0';
const DEFAULT_SCOPE = '/read-public';

/** Refresh the access token 60s before hard expiry. */
const TOKEN_REFRESH_BUFFER_MS = 60 * 1000;

const DEFAULT_REQUEST_TIMEOUT_MS = 30000;
const DEFAULT_MAX_RETRIES = 4;
const DEFAULT_MIN_REQUEST_INTERVAL_MS = 100;
const DEFAULT_MAX_SEARCH_RESULTS = 1000;
/** ORCID search caps a single page at 1000 rows. */
const SEARCH_PAGE_ROWS = 1000;
/** ORCID documented burst limit is 40 req/s; stay comfortably under it. */
const RATE_LIMIT_TOKENS_PER_SEC = 10;

/**
 * iDs per `FetchChanges` page for the ROOT object — the one that calls ORCID. The engine kills any
 * FetchChanges call that runs past its 30s timeout, and its adaptive controller cuts concurrency to 1
 * after failures, so a page must finish under 30s even when fetched SEQUENTIALLY: 10 iDs × ~1.5s
 * worst-case ≈ 15s. A page sized for the concurrent-happy case plus a concurrency cut times out on
 * every page (death spiral); concurrency only makes a small page faster. Also bounds memory to one
 * page of records. Sized from a production deployment that learned this live.
 */
const RECORD_IDS_PER_PAGE = 10;
/**
 * iDs per page for a DERIVED section: one local read for the stored records plus in-memory
 * extraction, no ORCID call, so the page can be larger. Still bounded: a prolific author's works
 * section alone can run to thousands of items.
 */
const DERIVED_IDS_PER_PAGE = 100;

/** Source fields of the record object that a derived section is rebuilt from. */
const RECORD_PERSON_FIELD = 'person';
const RECORD_ACTIVITIES_FIELD = 'activities-summary';

/** One iD's root fetch: its items, or the error that was already turned into an ID_FETCH_FAILED warning. */
interface FetchOneOutcome {
    Items?: Record<string, unknown>[];
    Error?: unknown;
}

/** Where the engine stores synced `record` rows for one connection, resolved once per connection. */
interface RecordStorage {
    /** MJ entity the `record` object is mapped to (its name, for RunView). */
    EntityName: string;
    /** The entity's ID, for the record-map lookup. */
    EntityID: string;
    /** Destination column holding the source `person` block. */
    PersonColumn: string;
    /** Destination column holding the source `activities-summary` block. */
    ActivitiesColumn: string;
}

// ─── Connector implementation ─────────────────────────────────────────

/**
 * Connector for the ORCID Public API v3.0 (read-only).
 *
 * Authenticates via OAuth2 2-legged client_credentials (scope `/read-public`)
 * to obtain a bearer token, OR runs ANONYMOUSLY when no credential is configured:
 * the ORCID Public API serves public records with no token at all, so a connection
 * that supplies neither ClientID nor ClientSecret skips the grant and sends no
 * Authorization header. Supplying only one half of the pair is still an error.
 * ORCID is NOT enumerable — there is no
 * "list all records" endpoint — so every sync is SCOPED per connection via
 * `CompanyIntegration.Configuration` (`searchQuery` Lucene query and/or an
 * explicit `orcidIds` array).
 *
 * ONE CALL PER PERSON. Only the root `record` object calls ORCID (`GET /{iD}/record`,
 * fetched concurrently within a page under the engine's adaptive rate limiter). The
 * record payload already carries every section summary under `activities-summary` and
 * `person`, and the engine stores those blocks on the synced record row, so every child
 * object (works, employments, keywords, …) is DERIVED by reading the stored record back
 * and extracting its items — no API call. Previously each section issued its own
 * `GET /{iD}/<section>` per person, which at ~10 req/s made a 50k-member universe a
 * multi-day load (12 calls/person) instead of ~1.5 hours (1 call/person). An iD whose
 * record is not stored yet (section-only sync, failed record) falls back to one
 * `/record` call so a section is never silently empty.
 *
 * Pull-only: SupportsCreate/Update/Delete are false (the Public API is
 * read-only; writes require the Member API which is out of scope). Incremental
 * sync narrows client-side on each section's `last-modified-date`; the
 * search-scoped universe has no cursor so it re-resolves each run and dedup
 * rides content-hash idempotency in the base ToExternalRecord path.
 *
 * Rides BaseRESTIntegrationConnector (JSON over HTTP via Accept:
 * application/json). FetchChanges is overridden so the ROOT iD set is sourced from
 * the Configuration universe rather than a parent table.
 */
@RegisterClass(BaseIntegrationConnector, '@memberjunction/connector-orcid')
export class ORCIDConnector extends BaseRESTIntegrationConnector {

    /** Cached auth context (token + resolved host). Invalidated on token expiry or 401. */
    private authState: ORCIDAuthContext | null = null;
    /** Timestamp of the last outbound request, used for throttling. */
    private lastRequestTime = 0;
    /**
     * The resolved iD universe, keyed by the scope config that produced it. FetchChanges runs once
     * per page — thousands of times over a large universe — and a search-scoped universe would
     * otherwise re-run its Lucene query (up to 10 pages of 1000) on every one of them.
     */
    private universeCache: { Key: string; Ids: string[] } | null = null;
    /** Where this connection's `record` rows live, resolved once per CompanyIntegration. */
    private recordStorageCache: { CompanyIntegrationID: string; Storage: RecordStorage | null } | null = null;

    // ── Capability getters (PULL-ONLY) ──────────────────────────────────

    public override get SupportsCreate(): boolean { return false; }
    public override get SupportsUpdate(): boolean { return false; }
    public override get SupportsDelete(): boolean { return false; }

    public override get IntegrationName(): string { return 'ORCID'; }

    // ── Sync-efficiency hooks ───────────────────────────────────────────

    /**
     * ORCID documents a 40 req/s burst ceiling (HTTP 503 over it) and a daily quota
     * (HTTP 429 with X-Rate-Limit-* + Retry-After). Run conservatively under the burst cap.
     */
    public override get RateLimitPolicy(): RateLimitPolicy | null {
        return { TokensPerSec: RATE_LIMIT_TOKENS_PER_SEC, Burst: 40, ThrottleBackoffFactor: 0.5 };
    }

    /**
     * ORCID's per-request latency (~1.4s typical) makes the sync LATENCY-bound, not rate-bound, at
     * the engine's default concurrency of 4: 4 in-flight ≈ 3 req/s against the ~10 req/s the
     * RateLimitPolicy above already permits. Raising the ceiling lets the engine's adaptive
     * controller ramp until the token bucket — the real constraint — becomes binding. This is a
     * CEILING, not a floor: the AIMD controller still cuts on 429/503.
     */
    public override get MaxConcurrencyHint(): number | null { return 16; }

    /** Parse ORCID's Retry-After (delta-seconds or HTTP-date) into milliseconds. */
    public override ExtractRetryAfterMs(error: unknown): number | undefined {
        const headers = (error as { Headers?: Record<string, string> })?.Headers;
        if (!headers) return undefined;
        const retryAfter = headers['retry-after'] ?? headers['Retry-After'];
        if (typeof retryAfter !== 'string' || retryAfter.length === 0) return undefined;
        const asSeconds = Number(retryAfter);
        if (!isNaN(asSeconds) && asSeconds >= 0) return Math.round(asSeconds * 1000);
        const asDate = Date.parse(retryAfter);
        if (!isNaN(asDate)) {
            const delta = asDate - Date.now();
            if (delta > 0) return delta;
        }
        return undefined;
    }

    /**
     * The search-scoped iD universe has no stable, monotonic ordering key — it is
     * re-resolved from the Lucene query each run (insert/delete-volatile), so keyset
     * resume is N/A. Dedup rides content-hash idempotency. Returns null for every object.
     */
    public override StableOrderingKey(_objectName: string): string | null { return null; }

    // ─── TestConnection ──────────────────────────────────────────────

    /**
     * Verifies connectivity by resolving auth (a client_credentials token, or anonymous when no
     * credential is configured), then issuing a lightweight probe against a well-known public
     * iD's /record. A 401/403 is a failure in BOTH modes — that probe record is public, so being
     * turned away means the host or the credential is wrong.
     */
    public async TestConnection(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<ConnectionTestResult> {
        try {
            const auth = await this.Authenticate(companyIntegration, contextUser) as ORCIDAuthContext;
            // ORCID's canonical sample public record (Sofia Garcia / Josiah Carberry-style); a 200 or 404
            // both prove the token + host are valid (the probe iD may differ between prod and sandbox).
            const probeUrl = `${auth.BaseUrl}/0000-0002-1825-0097/record`;
            const headers = this.BuildHeaders(auth);
            const resp = await this.MakeHTTPRequest(auth, probeUrl, 'GET', headers);
            if (resp.Status === 401 || resp.Status === 403) {
                return { Success: false, Message: `ORCID TestConnection failed: HTTP ${resp.Status} (auth rejected)` };
            }
            if (resp.Status >= 500) {
                return { Success: false, Message: `ORCID TestConnection failed: HTTP ${resp.Status} (server error)` };
            }
            const host = auth.Config.UseSandbox ? 'sandbox' : 'production';
            return {
                Success: true,
                Message: auth.Token == null
                    ? `Successfully reached the ORCID Public API anonymously — no credential configured (${host}).`
                    : `Successfully authenticated against ORCID Public API (${host}).`,
                ServerVersion: 'ORCID Public API v3.0',
            };
        } catch (err: unknown) {
            const message = err instanceof Error ? err.message : String(err);
            return { Success: false, Message: `Connection failed: ${message}` };
        }
    }

    // ─── FetchChanges (Configuration-scoped iD universe) ──────────────

    /**
     * Fetches records for the given object, sourcing the iD universe from
     * CompanyIntegration.Configuration (search query and/or explicit list).
     *
     * - ROOT IO ('record'): GET /{iD}/record for each iD in the page, concurrently.
     * - DERIVED IOs (every section): read the page's stored records back from the
     *   engine's synced rows and extract the section's items — no ORCID call. An iD
     *   with no stored record falls back to one /record fetch.
     *
     * Incremental: for sections that carry `last-modified-date`, narrow client-side
     * to records strictly newer than ctx.WatermarkValue, and return the max-seen
     * watermark as NewWatermarkValue (persisted by the engine on full-batch success
     * only). The iD universe itself has no cursor (search is re-resolved each run);
     * dedup rides content-hash idempotency in ToExternalRecord.
     */
    public override async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
        const obj = this.GetCachedObject(ctx.CompanyIntegration.IntegrationID, ctx.ObjectName);
        const fields = this.GetCachedFields(obj.ID);
        const auth = await this.Authenticate(ctx.CompanyIntegration, ctx.ContextUser) as ORCIDAuthContext;

        const universe = await this.ResolveOrcidIdUniverse(auth);
        const warnings: FetchWarning[] = [];
        if (universe.length === 0) {
            warnings.push({
                Code: 'ZERO_SCOPE',
                Message:
                    `ORCID "${ctx.ObjectName}": no iDs resolved from CompanyIntegration.Configuration. ` +
                    `Set "searchQuery" (Lucene) and/or "orcidIds" to scope the sync.`,
            });
            return { Records: [], HasMore: false, Warnings: warnings };
        }

        const section = ctx.ObjectName === ROOT_OBJECT_NAME ? null : ctx.ObjectName;

        // Keyset window over the sorted iD universe. The page is counted in iDs, not records: one
        // iD expands to an unbounded number of section items, so bounding the iD count is what
        // actually bounds memory and request volume. The root page is capped hard at
        // RECORD_IDS_PER_PAGE regardless of BatchSize (see that constant: the engine's 30s timeout
        // must hold with concurrency cut to 1); a derived page makes no API call and can be larger.
        // Previously the universe was sliced to BatchSize and the remainder DISCARDED while still
        // reporting HasMore:false — every iD past the first BatchSize was silently unsyncable.
        const remaining = ctx.AfterKeyValue
            ? universe.filter(id => id > ctx.AfterKeyValue!)
            : universe;
        const cap = section == null ? RECORD_IDS_PER_PAGE : DERIVED_IDS_PER_PAGE;
        const pageSize = ctx.BatchSize > 0 ? Math.min(ctx.BatchSize, cap) : cap;
        const orcidIds = remaining.slice(0, pageSize);
        const hasMore = remaining.length > orcidIds.length;

        if (orcidIds.length === 0) {
            return { Records: [], HasMore: false, Warnings: warnings.length > 0 ? warnings : undefined };
        }

        const watermark = this.parseWatermark(ctx.WatermarkValue);
        const pkFieldNames = fields.filter(f => f.IsPrimaryKey).map(f => f.Name);

        const out: ExternalRecord[] = [];
        let maxSeen = watermark;
        let skippedIdCount = 0;

        const addItems = (items: Record<string, unknown>[]): void => {
            for (const raw of items) {
                const lmd = this.extractLastModifiedMs(raw);
                // Incremental narrowing: skip records not newer than the watermark.
                if (watermark != null && lmd != null && lmd <= watermark) continue;
                if (lmd != null && (maxSeen == null || lmd > maxSeen)) maxSeen = lmd;
                out.push(this.toRecord(raw, obj, fields, pkFieldNames));
            }
        };

        // Per-iD isolation: one bad iD (persistent 5xx, malformed record) must not abort the whole
        // page. This matters more under keyset paging — the engine can only step past a failed
        // page for offset/page pagination (`canSkipPage`), so a throw here would stall the scan at
        // this iD on EVERY subsequent run, permanently. 403/404 are already handled as empty inside
        // FetchForId; this catches everything else.
        const fetchRecordIsolated = async (iD: string): Promise<FetchOneOutcome> => {
            try {
                return { Items: await this.FetchForId(auth, obj, iD, null) };
            } catch (err) {
                skippedIdCount++;
                warnings.push({
                    Code: 'ID_FETCH_FAILED',
                    Message:
                        `ORCID "${ctx.ObjectName}": iD ${iD} failed and was skipped — ` +
                        `${err instanceof Error ? err.message : String(err)}`,
                    Data: { orcidId: iD, objectName: ctx.ObjectName },
                });
                return { Error: err };
            }
        };

        if (section == null) {
            // ROOT: the only object that calls ORCID. Fan the page across the engine's in-flight
            // budget so throughput reaches the rate ceiling instead of the sequential-latency floor.
            const fetched = await this.fetchRecordsConcurrently(ctx, orcidIds, fetchRecordIsolated);
            for (const iD of orcidIds) {
                const items = fetched.get(iD);
                if (items) addItems(items);
            }
        } else {
            // DERIVED: rebuild this section from the stored records — one local read per page, no
            // ORCID call. The record object is the FK parent of every section, so the engine's
            // dependency ordering has already synced it; an iD that is nevertheless missing (a
            // section-only run, a record that failed its own fetch) is fetched live so the section
            // is never silently empty for it.
            const stored = await this.LoadStoredRecords(ctx, orcidIds);
            const missing = orcidIds.filter(iD => !stored.has(iD));
            if (missing.length > 0) {
                const fetched = await this.fetchRecordsConcurrently(ctx, missing, fetchRecordIsolated);
                for (const [iD, items] of fetched) {
                    const record = items[0];
                    if (record) stored.set(iD, record);
                }
                warnings.push({
                    Code: 'RECORD_FALLBACK_FETCH',
                    Message:
                        `ORCID "${ctx.ObjectName}": ${missing.length} of ${orcidIds.length} iDs had no stored record ` +
                        `and were fetched live. Sync the record object first to avoid the extra calls.`,
                    Data: { objectName: ctx.ObjectName, count: missing.length, orcidIds: missing },
                });
            }
            for (const iD of orcidIds) {
                const record = stored.get(iD);
                if (record) addItems(extractSectionRawItems(record, section, iD));
            }
        }

        const result: FetchBatchResult = { Records: out, HasMore: hasMore };
        if (hasMore) result.NextAfterKeyValue = orcidIds[orcidIds.length - 1];

        // Advance the watermark ONLY on the final page. Advancing mid-scan is unsafe: if the run
        // dies after page 1, page 2's records older than the new watermark would be skipped forever.
        // Deriving it from the last page alone can UNDER-advance, which is safe — it costs a re-fetch
        // that content-hash idempotency in ToExternalRecord dedups.
        //
        // Also HOLD the watermark when any iD was skipped above. Swallowing a per-iD failure means
        // the engine sees a clean fetch, so it can't hold the watermark for us — advancing here would
        // permanently strand the skipped iD's updates below the new watermark. Holding costs a
        // re-fetch next run (content-hash dedups it) and lets the failed iD self-heal.
        if (!hasMore && skippedIdCount === 0 && maxSeen != null && maxSeen !== watermark) {
            result.NewWatermarkValue = String(maxSeen);
        }
        if (warnings.length > 0) result.Warnings = warnings;
        return result;
    }

    /**
     * Runs `fetchOne` over `orcidIds` with up to `ctx.MaxConcurrency` in flight, each request paced by
     * the engine's adaptive token bucket: `RateLimitAcquire` before each call, and afterwards either a
     * clean report (ramps the shared rate back up) or, when the failure was a throttle (429/503, after
     * the transport's own retries), the error itself so the engine backs off and honours Retry-After.
     * Any other failure (a 500, a malformed record) is NOT reported: the engine treats every reported
     * error as a throttle, and a bad record is no reason to slow the whole connection down. Order of
     * completion is irrelevant — results are keyed by iD. With no engine hooks (tests, older engines)
     * this degrades to one in flight, the old behaviour.
     */
    private async fetchRecordsConcurrently(
        ctx: FetchContext,
        orcidIds: string[],
        fetchOne: (iD: string) => Promise<FetchOneOutcome>
    ): Promise<Map<string, Record<string, unknown>[]>> {
        const results = new Map<string, Record<string, unknown>[]>();
        const concurrency = Math.max(1, Math.min(ctx.MaxConcurrency ?? 1, orcidIds.length));
        let next = 0;
        const worker = async (): Promise<void> => {
            while (next < orcidIds.length) {
                const iD = orcidIds[next++];
                if (ctx.RateLimitAcquire) await ctx.RateLimitAcquire();
                const outcome = await fetchOne(iD);
                if (outcome.Items) {
                    ctx.RateLimitReport?.();
                    results.set(iD, outcome.Items);
                } else if (this.isThrottleError(outcome.Error)) {
                    ctx.RateLimitReport?.(outcome.Error);
                }
            }
        };
        await Promise.all(Array.from({ length: concurrency }, worker));
        return results;
    }

    /** True for the HTTP statuses ORCID uses to say "slow down" (FetchForId attaches the status). */
    private isThrottleError(err: unknown): boolean {
        const status = (err as { Status?: unknown } | null)?.Status;
        return status === 429 || status === 503;
    }

    /**
     * Reads the stored `record` rows for a page of iDs back from the engine's synced entity, as
     * `{ person, 'activities-summary' }` payloads a derived section can be extracted from. Resolves
     * where the rows live from the connection's own entity map and field maps (so the destination
     * column names are whatever the engine wrote, on either SQL dialect), then goes iD → MJ row via
     * the engine's record map and reads the two blocks by row ID. Returns only the iDs found; the
     * caller fetches the rest live. Protected so a test can substitute a canned store.
     */
    protected async LoadStoredRecords(ctx: FetchContext, orcidIds: string[]): Promise<Map<string, Record<string, unknown>>> {
        const out = new Map<string, Record<string, unknown>>();
        if (orcidIds.length === 0) return out;
        const storage = await this.resolveRecordStorage(ctx);
        if (!storage) return out;

        const quote = (s: string): string => `'${s.replace(/'/g, "''")}'`;
        const rv = new RunView();
        const maps = await rv.RunView<{ ExternalSystemRecordID: string; EntityRecordID: string }>({
            EntityName: 'MJ: Company Integration Record Maps',
            ExtraFilter:
                `CompanyIntegrationID=${quote(ctx.CompanyIntegration.ID)} AND EntityID=${quote(storage.EntityID)} ` +
                `AND ExternalSystemRecordID IN (${orcidIds.map(quote).join(',')})`,
            Fields: ['ExternalSystemRecordID', 'EntityRecordID'],
            ResultType: 'simple',
        }, ctx.ContextUser);
        if (!maps.Success || maps.Results.length === 0) return out;

        const idByRow = new Map<string, string>();
        for (const row of maps.Results) {
            const ext = String(row.ExternalSystemRecordID ?? '').trim().toUpperCase();
            const mj = String(row.EntityRecordID ?? '').trim();
            if (ext && mj) idByRow.set(mj, ext);
        }
        if (idByRow.size === 0) return out;

        const rows = await rv.RunView<Record<string, unknown>>({
            EntityName: storage.EntityName,
            ExtraFilter: `ID IN (${[...idByRow.keys()].map(quote).join(',')})`,
            Fields: ['ID', storage.PersonColumn, storage.ActivitiesColumn],
            ResultType: 'simple',
        }, ctx.ContextUser);
        if (!rows.Success) return out;

        for (const row of rows.Results) {
            const iD = idByRow.get(String(row['ID'] ?? ''));
            if (!iD) continue;
            const person = this.parseStoredJson(row[storage.PersonColumn]);
            const activities = this.parseStoredJson(row[storage.ActivitiesColumn]);
            if (!person && !activities) continue; // a row synced before activities-summary existed
            out.set(iD, { [RECORD_PERSON_FIELD]: person, [RECORD_ACTIVITIES_FIELD]: activities });
        }
        return out;
    }

    /** A stored json column arrives as an object (PG) or its string form (SQL Server); either → object. */
    private parseStoredJson(value: unknown): Record<string, unknown> | undefined {
        if (value == null) return undefined;
        if (typeof value === 'object' && !Array.isArray(value)) return value as Record<string, unknown>;
        if (typeof value === 'string' && value.trim().startsWith('{')) {
            try {
                const parsed: unknown = JSON.parse(value);
                return parsed && typeof parsed === 'object' && !Array.isArray(parsed) ? parsed as Record<string, unknown> : undefined;
            } catch { return undefined; }
        }
        return undefined;
    }

    /**
     * Resolves the connection's `record` storage once: its entity map (`ExternalObjectName='record'`),
     * then the active source→destination field maps for the two blocks. A missing map for a block
     * falls back to the source name, which is what the engine uses when no map renames it. Null when
     * the record object has no entity map on this connection (nothing to read back from).
     */
    private async resolveRecordStorage(ctx: FetchContext): Promise<RecordStorage | null> {
        const ciID = ctx.CompanyIntegration.ID;
        if (this.recordStorageCache && this.recordStorageCache.CompanyIntegrationID === ciID) {
            return this.recordStorageCache.Storage;
        }

        let storage: RecordStorage | null = null;
        const rv = new RunView();
        const entityMap = await rv.RunView<{ ID: string; EntityID: string; Entity: string }>({
            EntityName: 'MJ: Company Integration Entity Maps',
            ExtraFilter: `CompanyIntegrationID='${ciID.replace(/'/g, "''")}' AND ExternalObjectName='${ROOT_OBJECT_NAME}'`,
            Fields: ['ID', 'EntityID', 'Entity'],
            MaxRows: 1,
            ResultType: 'simple',
        }, ctx.ContextUser);
        const map = entityMap.Success ? entityMap.Results[0] : undefined;
        if (map?.Entity && map.EntityID) {
            const dest = new Map<string, string>();
            const fieldMaps = await rv.RunView<{ SourceFieldName: string; DestinationFieldName: string }>({
                EntityName: 'MJ: Company Integration Field Maps',
                ExtraFilter: `EntityMapID='${String(map.ID).replace(/'/g, "''")}' AND Status='Active'`,
                Fields: ['SourceFieldName', 'DestinationFieldName'],
                ResultType: 'simple',
            }, ctx.ContextUser);
            if (fieldMaps.Success) {
                for (const fm of fieldMaps.Results) {
                    if (fm.SourceFieldName && fm.DestinationFieldName) dest.set(fm.SourceFieldName, fm.DestinationFieldName);
                }
            }
            storage = {
                EntityName: String(map.Entity),
                EntityID: String(map.EntityID),
                PersonColumn: dest.get(RECORD_PERSON_FIELD) ?? RECORD_PERSON_FIELD,
                ActivitiesColumn: dest.get(RECORD_ACTIVITIES_FIELD) ?? RECORD_ACTIVITIES_FIELD,
            };
        }
        this.recordStorageCache = { CompanyIntegrationID: ciID, Storage: storage };
        return storage;
    }

    /**
     * Fetches the raw item array for a single iD + object. For the root record IO this is
     * a single-element array (the record itself); for a section it is the expanded group items.
     * A section fetch here hits ORCID's per-section endpoint directly; the sync path no longer
     * uses it (sections derive from the stored record), but GetRecord-style callers and
     * subclasses still can.
     */
    protected async FetchForId(
        auth: ORCIDAuthContext,
        obj: MJIntegrationObjectEntity,
        iD: string,
        section: string | null
    ): Promise<Record<string, unknown>[]> {
        const path = section == null ? `/${encodeURIComponent(iD)}/record` : `/${encodeURIComponent(iD)}/${section}`;
        const url = `${auth.BaseUrl}${path}`;
        const headers = this.BuildHeaders(auth);
        const resp = await this.MakeHTTPRequest(auth, url, 'GET', headers);
        if (resp.Status === 404) return [];
        if (resp.Status === 403) {
            console.warn(`[ORCID] HTTP 403 for "${obj.Name}" iD ${iD} — skipping (insufficient scope/visibility).`);
            return [];
        }
        if (resp.Status < 200 || resp.Status >= 300) {
            throw Object.assign(
                new Error(`ORCID fetch failed for "${obj.Name}" iD ${iD}: HTTP ${resp.Status}`),
                { Status: resp.Status, Headers: resp.Headers }
            );
        }
        const body = resp.Body as Record<string, unknown> | null;
        if (!body) return [];
        if (section == null) {
            // The full record — tag with the iD so the PK (orcid-id) is always present.
            body['orcid-id'] = iD;
            return [body];
        }
        return this.expandSection(body, section, iD);
    }

    /**
     * Expands an ORCID activity-section group envelope into individual item objects.
     *
     * ORCID groups items under section-specific wrappers (e.g. works →
     * `group[].work-summary[]`, employments → `affiliation-group[].summaries[]`).
     * We walk the generic shape: any array whose elements carry a `put-code` is a
     * leaf item; we flatten all such arrays found anywhere in the envelope. Each
     * item is tagged with the parent `orcid-id` (the FK to record).
     */
    protected expandSection(body: Record<string, unknown>, _section: string, iD: string): Record<string, unknown>[] {
        return collectPutCodeItems(body).map(item => ({ ...item, 'orcid-id': iD }));
    }

    // ─── iD universe resolution ──────────────────────────────────────

    /**
     * Resolves the in-scope ORCID iD universe from CompanyIntegration.Configuration:
     * the explicit `orcidIds` list (always included) plus the result of running the
     * Lucene `searchQuery` against /search (or /expanded-search), bounded by
     * MaxSearchResults to avoid draining the ~10k cap. Returns a de-duplicated set,
     * sorted lexicographically.
     *
     * Returns the COMPLETE universe — batching is the caller's job. ORCID iDs are a
     * fixed 16-digit dashed format, so a lexicographic sort is a total, stable order
     * and therefore a valid keyset pagination key for FetchChanges.
     */
    protected async ResolveOrcidIdUniverse(auth: ORCIDAuthContext): Promise<string[]> {
        const cfg = auth.Config;
        const cacheKey = JSON.stringify([cfg.SearchQuery ?? '', cfg.UseExpandedSearch === true, cfg.MaxSearchResults ?? null, cfg.OrcidIds ?? []]);
        if (this.universeCache?.Key === cacheKey) return this.universeCache.Ids;
        const ids = new Set<string>();

        for (const explicit of cfg.OrcidIds ?? []) {
            const normalized = this.normalizeOrcidId(explicit);
            if (normalized) ids.add(normalized);
        }

        if (cfg.SearchQuery && cfg.SearchQuery.trim().length > 0) {
            const fromSearch = await this.RunSearch(auth, cfg.SearchQuery, cfg.MaxSearchResults ?? DEFAULT_MAX_SEARCH_RESULTS);
            for (const id of fromSearch) ids.add(id);
        }

        const sorted = Array.from(ids).sort();
        this.universeCache = { Key: cacheKey, Ids: sorted };
        return sorted;
    }

    /**
     * Runs the Lucene query against ORCID /search (or /expanded-search) with offset
     * pagination (start/rows), accumulating iDs up to maxResults ("Goldilocks" bound).
     * Search is unordered and may return duplicates across pages — de-duplicated by the caller.
     */
    private async RunSearch(auth: ORCIDAuthContext, query: string, maxResults: number): Promise<string[]> {
        const path = auth.Config.UseExpandedSearch ? '/expanded-search' : '/search';
        const headers = this.BuildHeaders(auth);
        const collected: string[] = [];
        let start = 0;

        while (collected.length < maxResults) {
            const rows = Math.min(SEARCH_PAGE_ROWS, maxResults - collected.length);
            const url = `${auth.BaseUrl}${path}?q=${encodeURIComponent(query)}&start=${start}&rows=${rows}`;
            const resp = await this.MakeHTTPRequest(auth, url, 'GET', headers);
            if (resp.Status < 200 || resp.Status >= 300) {
                throw Object.assign(
                    new Error(`ORCID search failed (HTTP ${resp.Status}) for query "${query}"`),
                    { Status: resp.Status, Headers: resp.Headers }
                );
            }
            const body = resp.Body as ORCIDSearchResponse | null;
            const results = body?.result ?? [];
            if (results.length === 0) break;
            for (const r of results) {
                const id = this.normalizeOrcidId(r['orcid-identifier']?.path);
                if (id) collected.push(id);
            }
            start += rows;
            // Stop when the API has returned fewer than a full page (exhausted).
            if (results.length < rows) break;
        }
        return collected;
    }

    /** Normalizes a raw iD string to the canonical 0000-0000-0000-0000 form, or null if unusable. */
    private normalizeOrcidId(raw: string | undefined | null): string | null {
        if (typeof raw !== 'string') return null;
        const trimmed = raw.trim();
        if (trimmed.length === 0) return null;
        // Accept a bare iD or a full URI; take the trailing path segment.
        const seg = trimmed.replace(/\/+$/, '').split('/').pop() ?? trimmed;
        return /^[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{3}[0-9X]$/i.test(seg) ? seg.toUpperCase() : null;
    }

    // ─── Record transformation ────────────────────────────────────────

    /**
     * Builds the ExternalRecord, preserving the FULL raw source record in Fields
     * (full-record pass-through) while flattening the declared scalar fields out of
     * ORCID's nested JSON via TransformRecord/applyTransformPreservingKeys. PK identity
     * (orcid-id for record, put-code for sections) drives the ExternalID; partial keys
     * fall back to the base content-hash identity.
     */
    protected toRecord(
        raw: Record<string, unknown>,
        obj: MJIntegrationObjectEntity,
        fields: MJIntegrationObjectFieldEntity[],
        pkFieldNames: string[]
    ): ExternalRecord {
        const flattened = this.applyTransformPreservingKeys(raw, obj, fields);
        const usablePk = pkFieldNames.length > 0
            && pkFieldNames.every(name => flattened[name] != null && String(flattened[name]).length > 0);
        const externalID = usablePk
            ? pkFieldNames.map(name => String(flattened[name])).join('|')
            : '';
        return {
            ExternalID: externalID, // empty → engine treats as content-hash identity downstream
            ObjectType: obj.Name,
            Fields: flattened,
        };
    }

    /**
     * Per-record reshaping: ORCID returns deeply-nested JSON; pull the declared scalar
     * convenience fields up to the top level so the generated columns are populated, while
     * the full raw record (every nested blob) is preserved by applyTransformPreservingKeys.
     *
     * Root record: the person/history scalars (name, biography, claimed, …). Section item: the
     * shared flatten in orcidRecordExtraction — `{value}` wrappers unwrapped in place, the
     * asserting source lifted to `source-name`/`source-orcid`, and the section's nested shapes
     * (title, organization, partial dates, amount, review subject) lifted into flat keys that
     * match the declared fields.
     */
    protected override TransformRecord(
        raw: Record<string, unknown>,
        obj: MJIntegrationObjectEntity,
        _fields: MJIntegrationObjectFieldEntity[]
    ): Record<string, unknown> {
        const out: Record<string, unknown> = obj.Name === ROOT_OBJECT_NAME
            ? { ...raw }
            : flattenSectionItem(raw, obj.Name);

        // Common to record + sections: ORCID wraps a millis timestamp as { value: <ms> }.
        out['last-modified-date'] = this.coerceDate(raw['last-modified-date']);
        if ('created-date' in raw) out['created-date'] = this.coerceDate(raw['created-date']);

        if (obj.Name === ROOT_OBJECT_NAME) {
            this.flattenRecordScalars(raw, out);
        }
        return out;
    }

    /** Flattens the record IO's person/history-derived convenience scalars. */
    private flattenRecordScalars(raw: Record<string, unknown>, out: Record<string, unknown>): void {
        const person = this.asObject(raw['person']);
        const name = person ? this.asObject(person['name']) : undefined;
        if (name) {
            out['given-names'] = this.valueOf(name['given-names']);
            out['family-name'] = this.valueOf(name['family-name']);
            out['credit-name'] = this.valueOf(name['credit-name']);
        }
        const biography = person ? this.asObject(person['biography']) : undefined;
        if (biography) out['biography'] = this.valueOf(biography['content']) ?? biography['content'];

        const history = this.asObject(raw['history']);
        if (history) {
            out['submission-date'] = this.coerceDate(history['submission-date']);
            if (typeof history['claimed'] === 'boolean') out['claimed'] = history['claimed'];
            if (typeof history['verified-email'] === 'boolean') out['verified-email'] = history['verified-email'];
        }
        // Convenience JSON sections (kept as-is; full blobs preserved via pass-through).
        const p = person ?? {};
        if (person) {
            out['emails'] = p['emails'];
            out['researcher-urls'] = p['researcher-urls'];
            out['keywords'] = p['keywords'];
            out['other-names'] = p['other-names'];
            out['addresses'] = p['addresses'];
            out['external-identifiers'] = p['external-identifiers'];
        }
    }

    // ── Value coercion helpers ──────────────────────────────────────────

    /** ORCID scalar wrapper: { value: <x> } → <x>; otherwise returns the value as-is. */
    private valueOf(node: unknown): unknown {
        return unwrapValue(node);
    }

    /** ORCID date wrapper: { value: <millis> } → ISO string; passthrough on already-scalar/empty. */
    private coerceDate(node: unknown): string | null {
        const ms = this.extractMs(node);
        if (ms == null) return null;
        return new Date(ms).toISOString();
    }

    /** Extracts the last-modified-date millis from a record (for watermark comparison). */
    protected extractLastModifiedMs(raw: Record<string, unknown>): number | null {
        return this.extractMs(raw['last-modified-date']);
    }

    /** Pulls a millisecond epoch out of an ORCID timestamp wrapper or a scalar number/ISO string. */
    private extractMs(node: unknown): number | null {
        return extractMsFromNode(node);
    }

    private asObject(node: unknown): Record<string, unknown> | undefined {
        return node && typeof node === 'object' && !Array.isArray(node) ? node as Record<string, unknown> : undefined;
    }

    protected parseWatermark(value: string | null): number | null {
        if (value == null) return null;
        const ms = this.extractMs(value);
        return ms;
    }

    // ─── Auth + transport (abstract base requirements) ────────────────

    protected async Authenticate(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<RESTAuthContext> {
        if (this.authState && this.isTokenValid(this.authState)) {
            return this.authState;
        }
        const config = await this.parseConfig(companyIntegration, contextUser);
        const state = this.IsAnonymousConfig(config)
            ? await this.buildAnonymousState(config)
            : await this.buildTokenState(config);
        this.authState = state;
        return state;
    }

    /**
     * True when the connection carries no client_credentials pair — anonymous Public API mode.
     * `parseConfig` has already rejected the half-configured case, so "no ClientID" here means
     * "no credential was supplied at all", never "the secret went missing".
     */
    protected IsAnonymousConfig(config: ORCIDConnectionConfig): boolean {
        return !config.ClientID;
    }

    /** Anonymous state: no grant, no token, nothing to refresh. */
    private async buildAnonymousState(config: ORCIDConnectionConfig): Promise<ORCIDAuthContext> {
        return {
            Token: undefined,
            ExpiresAt: undefined,
            BaseUrl: config.ApiBaseUrl ?? (config.UseSandbox ? SANDBOX_API_HOST : PROD_API_HOST),
            Config: config,
        };
    }

    /** Credentialed state: exchange the client_credentials grant for a bearer token. */
    private async buildTokenState(config: ORCIDConnectionConfig): Promise<ORCIDAuthContext> {
        const token = await this.obtainAccessToken(config);
        return {
            Token: token.access_token,
            ExpiresAt: new Date(Date.now() + (token.expires_in * 1000)),
            BaseUrl: config.ApiBaseUrl ?? (config.UseSandbox ? SANDBOX_API_HOST : PROD_API_HOST),
            Config: config,
        };
    }

    protected BuildHeaders(auth: RESTAuthContext): Record<string, string> {
        const orcidAuth = auth as ORCIDAuthContext;
        // Anonymous mode sends NO Authorization header — ORCID rejects a malformed/empty bearer,
        // whereas an absent header is the documented public-access path.
        return orcidAuth.Token == null
            ? { 'Accept': 'application/json' }
            : { 'Authorization': `Bearer ${orcidAuth.Token}`, 'Accept': 'application/json' };
    }

    /** Not used by the overridden FetchChanges; retained for any base-pipeline callers (GetRecord). */
    protected NormalizeResponse(rawBody: unknown, responseDataKey: string | null): Record<string, unknown>[] {
        if (rawBody == null) return [];
        if (responseDataKey) {
            const obj = this.asObject(rawBody);
            const inner = obj ? obj[responseDataKey] : undefined;
            if (Array.isArray(inner)) return inner as Record<string, unknown>[];
            if (inner && typeof inner === 'object') return [inner as Record<string, unknown>];
            return [];
        }
        if (Array.isArray(rawBody)) return rawBody as Record<string, unknown>[];
        if (typeof rawBody === 'object') return [rawBody as Record<string, unknown>];
        return [];
    }

    /** ORCID per-iD endpoints are not paginated — every object declares PaginationType=None. */
    protected ExtractPaginationInfo(
        _rawBody: unknown,
        _paginationType: PaginationType,
        currentPage: number,
        currentOffset: number,
        _pageSize: number
    ): PaginationState {
        return { HasMore: false, NextPage: currentPage, NextOffset: currentOffset };
    }

    protected GetBaseURL(
        _companyIntegration: MJCompanyIntegrationEntity,
        auth: RESTAuthContext
    ): string {
        return (auth as ORCIDAuthContext).BaseUrl;
    }

    // ─── Token lifecycle ──────────────────────────────────────────────

    private isTokenValid(state: ORCIDAuthContext): boolean {
        // Anonymous state never expires — there is no token to go stale.
        if (state.Token == null || state.ExpiresAt == null) return true;
        return state.ExpiresAt.getTime() - Date.now() > TOKEN_REFRESH_BUFFER_MS;
    }

    /**
     * Exchanges the client_credentials grant for a bearer token at the ORCID token
     * endpoint. POST form: grant_type=client_credentials, client_id, client_secret,
     * scope=/read-public.
     */
    private async obtainAccessToken(config: ORCIDConnectionConfig): Promise<ORCIDTokenResponse> {
        if (!config.ClientID || !config.ClientSecret) {
            throw new Error('ORCIDConnector: ClientID and ClientSecret are required for the client_credentials grant.');
        }
        const tokenUrl = config.TokenURL ?? (config.UseSandbox ? SANDBOX_TOKEN_URL : PROD_TOKEN_URL);
        const params = new URLSearchParams({
            grant_type: 'client_credentials',
            client_id: config.ClientID,
            client_secret: config.ClientSecret,
            scope: config.Scope ?? DEFAULT_SCOPE,
        });
        const resp = await fetch(tokenUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Accept': 'application/json',
            },
            body: params.toString(),
        });
        if (!resp.ok) {
            const text = await resp.text();
            throw new Error(`ORCID OAuth token request failed (HTTP ${resp.status}): ${text.slice(0, 500)}`);
        }
        const payload = await resp.json() as ORCIDTokenResponse;
        if (!payload.access_token || typeof payload.access_token !== 'string') {
            throw new Error('ORCID OAuth token response missing access_token');
        }
        return payload;
    }

    // ─── HTTP transport with retry + throttling ───────────────────────

    protected async MakeHTTPRequest(
        auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown
    ): Promise<RESTResponse> {
        const orcidAuth = auth as ORCIDAuthContext;
        const cfg = orcidAuth.Config;
        const maxRetries = cfg.MaxRetries ?? DEFAULT_MAX_RETRIES;
        const timeoutMs = cfg.RequestTimeoutMs ?? DEFAULT_REQUEST_TIMEOUT_MS;
        const minInterval = cfg.MinRequestIntervalMs ?? DEFAULT_MIN_REQUEST_INTERVAL_MS;
        let currentHeaders = headers;

        for (let attempt = 0; attempt <= maxRetries; attempt++) {
            await this.throttle(minInterval);
            try {
                const resp = await this.doFetch(url, method, currentHeaders, body, timeoutMs);
                this.lastRequestTime = Date.now();

                if (resp.Status === 401 && attempt < maxRetries && !this.IsAnonymousConfig(cfg)) {
                    // Token expired/revoked — drop the cache, refresh against the held credentials, retry.
                    // Skipped in anonymous mode: there is no grant to re-run, and a 401 there means the
                    // resource simply isn't public. Retrying would just burn the retry budget on a
                    // response that will never change.
                    this.authState = null;
                    const refreshed = await this.obtainAccessToken(cfg);
                    const refreshedState: ORCIDAuthContext = {
                        Token: refreshed.access_token,
                        ExpiresAt: new Date(Date.now() + (refreshed.expires_in * 1000)),
                        BaseUrl: cfg.ApiBaseUrl ?? (cfg.UseSandbox ? SANDBOX_API_HOST : PROD_API_HOST),
                        Config: cfg,
                    };
                    this.authState = refreshedState;
                    currentHeaders = this.BuildHeaders(refreshedState);
                    continue;
                }
                if ((resp.Status === 429 || resp.Status === 503) && attempt < maxRetries) {
                    await this.sleep(this.backoffFromResponse(resp, attempt));
                    continue;
                }
                return resp;
            } catch (err: unknown) {
                if (attempt === maxRetries) throw err;
                if (!this.isRetryableError(err)) throw err;
                await this.sleep(this.backoffMs(attempt));
            }
        }
        throw new Error(`ORCID request to ${url} exhausted ${maxRetries + 1} attempts`);
    }

    /** Single fetch() with an AbortController-backed timeout. */
    private async doFetch(
        url: string,
        method: string,
        headers: Record<string, string>,
        body: unknown,
        timeoutMs: number
    ): Promise<RESTResponse> {
        const controller = new AbortController();
        const handle = setTimeout(() => controller.abort(), timeoutMs);
        try {
            const resp = await fetch(url, {
                method,
                headers,
                body: body !== undefined ? JSON.stringify(body) : undefined,
                signal: controller.signal,
            });
            const respHeaders: Record<string, string> = {};
            resp.headers.forEach((value, key) => { respHeaders[key.toLowerCase()] = value; });
            const text = await resp.text();
            const parsed = text.length > 0 ? this.safeParseJSON(text) : null;
            return { Status: resp.status, Body: parsed, Headers: respHeaders };
        } finally {
            clearTimeout(handle);
        }
    }

    private safeParseJSON(text: string): unknown {
        try { return JSON.parse(text) as unknown; } catch { return text; }
    }

    private isRetryableError(err: unknown): boolean {
        const msg = err instanceof Error ? err.message : String(err);
        return /abort|timeout|ECONNRESET|ENOTFOUND|ETIMEDOUT|network/i.test(msg);
    }

    private backoffMs(attempt: number): number {
        const base = Math.min(1000 * Math.pow(2, attempt), 20000);
        const jitter = Math.floor(Math.random() * 500);
        return base + jitter;
    }

    private backoffFromResponse(resp: RESTResponse, attempt: number): number {
        const fromHeader = this.ExtractRetryAfterMs({ Headers: resp.Headers });
        if (fromHeader != null) return Math.min(fromHeader, 30000);
        return this.backoffMs(attempt);
    }

    private async throttle(minIntervalMs: number): Promise<void> {
        const elapsed = Date.now() - this.lastRequestTime;
        if (elapsed < minIntervalMs) await this.sleep(minIntervalMs - elapsed);
    }

    private sleep(ms: number): Promise<void> {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    // ─── Config parsing ───────────────────────────────────────────────

    /**
     * Resolves the connection config: OAuth2 secrets (ClientID/ClientSecret/TokenURL/Scope) from the
     * credential store; the iD-universe scope (searchQuery/orcidIds) + host selection (useSandbox)
     * from CompanyIntegration.Configuration. Secrets are NEVER baked into code.
     */
    private async parseConfig(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<ORCIDConnectionConfig> {
        const fromCredential = companyIntegration.CredentialID
            ? await this.loadFromCredential(companyIntegration.CredentialID, contextUser)
            : null;
        const fromConfig = this.parseConfigurationJson(companyIntegration.Configuration);

        const merged: ORCIDConnectionConfig = { ...fromCredential, ...fromConfig };
        // Credential secrets win over any duplicate in Configuration; scope/host win from Configuration.
        if (fromCredential) {
            merged.ClientID = fromCredential.ClientID ?? merged.ClientID;
            merged.ClientSecret = fromCredential.ClientSecret ?? merged.ClientSecret;
            merged.TokenURL = fromCredential.TokenURL ?? merged.TokenURL;
            merged.Scope = merged.Scope ?? fromCredential.Scope;
        }

        // Credential mode selection. ORCID's Public API serves public records WITHOUT a token, so a
        // connection that supplies no credential at all is a legitimate anonymous configuration —
        // not an error. A PARTIAL credential still is: half a client_credentials pair can only be a
        // misconfiguration, and silently degrading it to anonymous would hide the real problem
        // behind a sync that quietly returns only public data.
        const hasClientID = !!merged.ClientID;
        const hasClientSecret = !!merged.ClientSecret;
        if (hasClientID !== hasClientSecret) {
            throw new Error(
                'ORCIDConnector: ClientID and ClientSecret must BOTH be provided (OAuth2 client_credentials), ' +
                'or both omitted to use the anonymous Public API.'
            );
        }
        if ((!merged.SearchQuery || merged.SearchQuery.trim().length === 0) && (!merged.OrcidIds || merged.OrcidIds.length === 0)) {
            // Not fatal at auth time — surfaced as a ZERO_SCOPE warning per object in FetchChanges.
            merged.OrcidIds = [];
        }
        return merged;
    }

    /** Parses the non-secret scope/host config from CompanyIntegration.Configuration JSON. */
    private parseConfigurationJson(raw: string | null): Partial<ORCIDConnectionConfig> {
        if (!raw || raw.trim().length === 0) return {};
        let parsed: Record<string, unknown>;
        try {
            parsed = JSON.parse(raw) as Record<string, unknown>;
        } catch {
            throw new Error('ORCIDConnector: CompanyIntegration.Configuration is not valid JSON.');
        }
        const out: Partial<ORCIDConnectionConfig> = {};
        const str = (v: unknown): string | undefined => (typeof v === 'string' ? v : undefined);
        out.SearchQuery = str(parsed['searchQuery']);
        out.UseExpandedSearch = parsed['useExpandedSearch'] === true;
        out.UseSandbox = parsed['useSandbox'] === true;
        if (Array.isArray(parsed['orcidIds'])) {
            out.OrcidIds = (parsed['orcidIds'] as unknown[]).filter(x => typeof x === 'string') as string[];
        }
        if (typeof parsed['maxSearchResults'] === 'number') out.MaxSearchResults = parsed['maxSearchResults'] as number;
        // Allow non-secret OAuth host overrides from Configuration (secrets never live here).
        out.TokenURL = str(parsed['tokenUrl']);
        out.ApiBaseUrl = str(parsed['apiBaseUrl'] ?? parsed['BaseURL']);
        // Fallback client credentials from Configuration — the credential store remains preferred
        // (the parseConfig merge gives fromCredential precedence). This matches the GrowthZone /
        // Path LMS pattern and is what makes credential-free replay harnesses possible.
        out.ClientID = str(parsed['ClientID'] ?? parsed['clientId']);
        out.ClientSecret = str(parsed['ClientSecret'] ?? parsed['clientSecret']);
        out.Scope = str(parsed['scope']);
        if (typeof parsed['requestTimeoutMs'] === 'number') out.RequestTimeoutMs = parsed['requestTimeoutMs'] as number;
        if (typeof parsed['maxRetries'] === 'number') out.MaxRetries = parsed['maxRetries'] as number;
        if (typeof parsed['minRequestIntervalMs'] === 'number') out.MinRequestIntervalMs = parsed['minRequestIntervalMs'] as number;
        return out;
    }

    /** Loads OAuth2 secrets from the MJ credential store (generic OAuth2 client-credentials schema). */
    private async loadFromCredential(
        credentialID: string,
        contextUser: UserInfo,
        provider?: IMetadataProvider
    ): Promise<Partial<ORCIDConnectionConfig> | null> {
        const md = provider ?? new Metadata();
        const credential = await md.GetEntityObject<MJCredentialEntity>('MJ: Credentials', contextUser);
        const loaded = await credential.Load(credentialID);
        if (!loaded || !credential.Values) return null;
        let raw: Record<string, unknown>;
        try {
            raw = JSON.parse(credential.Values) as Record<string, unknown>;
        } catch {
            return null;
        }
        const get = (...keys: string[]): string | undefined => {
            for (const k of keys) {
                const hit = Object.entries(raw).find(([key]) => key.toLowerCase() === k.toLowerCase());
                if (hit && typeof hit[1] === 'string') return hit[1] as string;
            }
            return undefined;
        };
        return {
            ClientID: get('ClientID', 'clientId', 'client_id'),
            ClientSecret: get('ClientSecret', 'clientSecret', 'client_secret'),
            TokenURL: get('TokenURL', 'tokenUrl', 'token_url'),
            Scope: get('Scope', 'scope'),
        };
    }
}

/** Tree-shaking prevention function — import and call from the module entry point. */
export function LoadORCIDConnector(): void { /* no-op */ }
