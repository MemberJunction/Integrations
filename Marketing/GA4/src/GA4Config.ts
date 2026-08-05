/**
 * `CompanyIntegration.Configuration` for GA4 — the non-secret half of the setup.
 *
 * The secret half (the service-account key) lives in `MJ: Credentials` and is never read from here.
 * Everything in this file is safe to log, which is why the property id is here rather than in the
 * credential: "which property am I pointed at" is the first question any support conversation asks.
 *
 * Every field except `propertyId` is optional, and every parse failure falls back to the documented
 * default rather than throwing. A malformed `lookbackDays` should not take a working integration
 * offline; a missing `propertyId` genuinely must, because there is nothing to query.
 */

export interface GA4Config {
    /** The numeric GA4 property id, as a string. Digits only — GA4 rejects anything else. */
    propertyId: string;
    /** Days of already-synced history to re-read on every incremental run. See {@link DEFAULT_LOOKBACK_DAYS}. */
    lookbackDays: number;
    /** Earliest date to read when there is no watermark, `YYYY-MM-DD`. */
    startDate: string | null;
    /** Maximum span, in days, of any single GA4 request. See {@link DEFAULT_MAX_WINDOW_DAYS}. */
    maxWindowDays: number;
}

/**
 * Three days.
 *
 * GA4 does not finalize a day when the day ends. Event data continues to arrive and be reprocessed
 * for up to 48 hours, and user-scoped metrics — the two cardinalities — can move for longer as late
 * sessions are stitched onto existing users. A watermark that advanced strictly to the last day seen
 * would therefore land every day's numbers exactly once, at their least accurate, and never correct
 * them.
 *
 * Re-reading the tail is cheap in the only way that matters: the engine's content-hash prefetch turns
 * an unchanged row into zero writes, so the cost of a lookback window is reads, and the days that DID
 * move are precisely the ones that should be rewritten.
 *
 * Three rather than two: GA4's 48 hours is measured from the event, not from midnight in the
 * property's reporting time zone, so a strict two-day window can end a few hours short of it.
 */
export const DEFAULT_LOOKBACK_DAYS = 3;

/** Sanity bound. A lookback longer than this is a request for a full re-read; clear the watermark instead. */
export const MAX_LOOKBACK_DAYS = 400;

/**
 * Ninety days per request.
 *
 * This does NOT bound how much history a run covers — when a window is exhausted and there is more
 * to read, the cursor advances to the next window and the same run keeps going. It bounds the size
 * of any single GA4 response, which matters because a wide date range against a high-cardinality
 * dimension like `pagePath` is exactly the shape that trips GA4's own cardinality limits and starts
 * collapsing rows into the `(other)` bucket. Narrower windows keep each request inside those limits.
 */
export const DEFAULT_MAX_WINDOW_DAYS = 90;

/** GA4's own hard cap on rows per `runReport` request. */
export const GA4_MAX_LIMIT = 250_000;

/**
 * How far back a cold start reads when `startDate` is not configured.
 *
 * Slightly over GA4's default 14-month event-data retention, so the default behaviour is "everything
 * the property still has" rather than an arbitrary window. Properties set to 2-month retention will
 * simply return nothing for the earlier part, at no cost beyond a few empty requests.
 */
export const DEFAULT_COLD_START_DAYS = 430;

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;

/**
 * Parse `CompanyIntegration.Configuration`.
 *
 * @throws when `propertyId` is absent or is not digits — the one unrecoverable case.
 */
export function parseGA4Config(configuration: string | null | undefined): GA4Config {
    const raw = readJSONObject(configuration);

    const propertyId = normalizePropertyId(raw.propertyId);
    if (propertyId === null) {
        throw new Error(
            'GA4: Configuration.propertyId is required and must be the numeric GA4 property id, e.g. {"propertyId":"123456789"}. ' +
                'It is the number shown as "PROPERTY ID" in GA4 Admin → Property Settings — not the measurement id (G-XXXXXXX) and not the account id.'
        );
    }

    return {
        propertyId,
        lookbackDays: clampInt(raw.lookbackDays, DEFAULT_LOOKBACK_DAYS, 0, MAX_LOOKBACK_DAYS),
        startDate: ISO_DATE.test(String(raw.startDate)) ? String(raw.startDate) : null,
        maxWindowDays: clampInt(raw.maxWindowDays, DEFAULT_MAX_WINDOW_DAYS, 1, 400),
    };
}

/**
 * Accept the property id as a string or a number, and tolerate the two forms people paste from the
 * GA4 UI and the API docs — `properties/123456789` and a stray `G-` measurement id is rejected,
 * because silently querying the wrong thing is worse than failing setup.
 */
export function normalizePropertyId(value: unknown): string | null {
    if (typeof value === 'number' && Number.isInteger(value) && value > 0) return String(value);
    if (typeof value !== 'string') return null;
    const trimmed = value.trim().replace(/^properties\//, '');
    return /^\d+$/.test(trimmed) ? trimmed : null;
}

function readJSONObject(text: string | null | undefined): Record<string, unknown> {
    if (!text) return {};
    try {
        const parsed: unknown = JSON.parse(text);
        return parsed !== null && typeof parsed === 'object' && !Array.isArray(parsed)
            ? (parsed as Record<string, unknown>)
            : {};
    } catch {
        return {};
    }
}

function clampInt(value: unknown, fallback: number, min: number, max: number): number {
    const n = typeof value === 'number' ? value : typeof value === 'string' ? Number(value) : NaN;
    if (!Number.isFinite(n)) return fallback;
    return Math.min(max, Math.max(min, Math.trunc(n)));
}
