/**
 * The seam between this connector and Google.
 *
 * Everything that talks to the network lives behind {@link GA4ReportPort}, which has exactly one
 * method. That is not indirection for its own sake: it is what lets the whole fetch loop — window
 * arithmetic, cursor advance, `(other)`-row detection, record projection, watermark — be exercised
 * against canned responses with no credential, which is the only verification available to this
 * connector before a live property exists to point it at.
 *
 * The types below are the subset of the v1beta `runReport` request/response this connector uses,
 * declared locally rather than imported from the Google client. Two reasons: the generated protobuf
 * types make everything optional and nullable, which pushes a `?? ''` onto every field access at the
 * call site; and a test fake should not have to construct a protobuf.
 */

/** A `runReport` request. Field names match the REST/JSON API exactly. */
export interface GA4RunReportRequest {
    /** `properties/<numeric id>`. */
    property: string;
    dateRanges: Array<{ startDate: string; endDate: string }>;
    dimensions: Array<{ name: string }>;
    metrics: Array<{ name: string }>;
    limit: number;
    offset: number;
    /** Ask GA4 to report remaining quota alongside the data, so exhaustion is visible before it bites. */
    returnPropertyQuota?: boolean;
}

export interface GA4Row {
    dimensionValues?: Array<{ value?: string | null } | null> | null;
    metricValues?: Array<{ value?: string | null } | null> | null;
}

export interface GA4QuotaBucket {
    consumed?: number | null;
    remaining?: number | null;
}

export interface GA4RunReportResponse {
    rows?: GA4Row[] | null;
    /** Total rows matching the query, across all pages. GA4 returns this on every page. */
    rowCount?: number | null;
    dimensionHeaders?: Array<{ name?: string | null } | null> | null;
    metricHeaders?: Array<{ name?: string | null } | null> | null;
    metadata?: {
        /** True when cardinality limits forced some rows into an aggregate `(other)` row. */
        dataLossFromOtherRow?: boolean | null;
        /** True when results were withheld or thresholded for privacy (small audiences). */
        subjectToThresholding?: boolean | null;
        timeZone?: string | null;
        currencyCode?: string | null;
    } | null;
    propertyQuota?: {
        tokensPerDay?: GA4QuotaBucket | null;
        tokensPerHour?: GA4QuotaBucket | null;
        concurrentRequests?: GA4QuotaBucket | null;
        potentiallyThresholdedRequestsPerHour?: GA4QuotaBucket | null;
    } | null;
}

/** The one operation this connector performs against Google. */
export interface GA4ReportPort {
    RunReport(request: GA4RunReportRequest): Promise<GA4RunReportResponse>;
}

/**
 * The live port, over `@google-analytics/data`'s `BetaAnalyticsDataClient`.
 *
 * The client is imported lazily and constructed once per port instance. Lazy because the Google
 * client drags in `google-gax` and its gRPC stack — a substantial import that a test run, a
 * `TestConnection` against a misconfigured credential, or an MJAPI boot that never syncs GA4 should
 * not pay for. Once per instance because the client caches its OAuth token: rebuilding it per request
 * would mint a fresh JWT and round-trip Google's token endpoint on every page of every window.
 */
export class DefaultGA4ReportPort implements GA4ReportPort {
    private client: { runReport: (req: unknown) => Promise<unknown[]> } | null = null;

    constructor(
        private readonly clientEmail: string,
        private readonly privateKey: string
    ) {}

    public async RunReport(request: GA4RunReportRequest): Promise<GA4RunReportResponse> {
        const client = await this.Client();
        const result = await client.runReport(request);
        // The Google client returns [response, request, callOptions]; only the first is data.
        return (result[0] ?? {}) as GA4RunReportResponse;
    }

    private async Client(): Promise<{ runReport: (req: unknown) => Promise<unknown[]> }> {
        if (this.client) return this.client;
        const mod = await import('@google-analytics/data');
        const Ctor = mod.BetaAnalyticsDataClient;
        this.client = new Ctor({
            credentials: { client_email: this.clientEmail, private_key: this.privateKey },
        }) as unknown as { runReport: (req: unknown) => Promise<unknown[]> };
        return this.client;
    }
}

/**
 * Is this error Google's rate limiter?
 *
 * GA4 meters by "analytics tokens" against per-hour and per-day buckets, and a report over a wide
 * date range costs more tokens than a narrow one. Exhaustion arrives as gRPC code 8
 * (RESOURCE_EXHAUSTED) or HTTP 429 depending on the transport, and it is transient — the hourly
 * bucket refills on the hour — so it is worth telling apart from a permission failure, which is not.
 */
export function isQuotaError(error: unknown): boolean {
    const code = (error as { code?: unknown })?.code;
    if (code === 8 || code === 429) return true;
    const message = error instanceof Error ? error.message : String(error);
    return /RESOURCE_EXHAUSTED|quota|rate limit|429/i.test(message);
}

/**
 * Is this error Google saying the service account cannot see the property?
 *
 * The single most common GA4 setup failure, and the one whose raw message is least helpful: creating
 * the service account and enabling the Data API are not enough — the service account's email must
 * ALSO be added as a user on the GA4 property itself, which happens in the Analytics UI rather than
 * in Cloud Console. Detected so `TestConnection` can say that instead of "PERMISSION_DENIED".
 */
export function isPermissionError(error: unknown): boolean {
    const code = (error as { code?: unknown })?.code;
    if (code === 7 || code === 403) return true;
    const message = error instanceof Error ? error.message : String(error);
    return /PERMISSION_DENIED|403|caller does not have permission|User does not have sufficient permissions/i.test(message);
}
