/**
 * Date-window arithmetic and the pagination cursor.
 *
 * A GA4 report is addressed by a date range plus an offset into the result, so those three values
 * — `from`, `to`, `offset` — are the whole of this connector's position in its source. They travel
 * in the cursor rather than being recomputed per call, and that is load-bearing: the range is derived
 * from the watermark and the clock, the engine does not advance the watermark until a run ends, and
 * so a run that happens to cross midnight would otherwise recompute a DIFFERENT range on its second
 * page and resume an offset into it. Offsets are only meaningful against the range that produced
 * them.
 *
 * The cursor therefore also carries the run's own `today`, pinning the clock for the whole run.
 *
 * Format: `<today>|<from>|<to>|<offset>`, all dates `YYYY-MM-DD`.
 */
import type { GA4Config } from './GA4Config.js';
import { DEFAULT_COLD_START_DAYS } from './GA4Config.js';

/** An inclusive date range, GA4's `dateRanges` semantics. */
export interface GA4Window {
    From: string;
    To: string;
}

export interface GA4Cursor extends GA4Window {
    /** The run's pinned clock. Every window in the run is derived from this, not from `new Date()`. */
    Today: string;
    /** Rows already consumed within `[From, To]`. */
    Offset: number;
}

const SEP = '|';
const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;
const MS_PER_DAY = 86_400_000;

/** The UTC date of an instant, `YYYY-MM-DD`. */
export function toISODate(d: Date): string {
    return d.toISOString().slice(0, 10);
}

/** Shift an ISO date by whole days. Returns the input unchanged if it is not a valid ISO date. */
export function addDays(iso: string, days: number): string {
    const base = Date.parse(`${iso}T00:00:00Z`);
    if (Number.isNaN(base)) return iso;
    return new Date(base + days * MS_PER_DAY).toISOString().slice(0, 10);
}

/** Lexicographic comparison is date comparison for `YYYY-MM-DD`, which is why this format is used throughout. */
const minDate = (a: string, b: string): string => (a < b ? a : b);
const maxDate = (a: string, b: string): string => (a > b ? a : b);

/**
 * The first window of a run.
 *
 * With a watermark, the window opens `lookbackDays` BEFORE it — re-reading days that are already
 * landed, because GA4 keeps revising recent days for up to 48 hours and a strictly-forward watermark
 * would freeze each day at its least accurate value forever.
 *
 * Without one, the window opens at the configured `startDate`, or {@link DEFAULT_COLD_START_DAYS}
 * back when there is none.
 *
 * The `startDate` floor is applied in BOTH branches on purpose: it is a statement about what this
 * property is allowed to be read for, and the lookback must not be able to reach behind it.
 */
export function initialWindow(config: GA4Config, watermark: string | null, today: string): GA4Window {
    const coldStart = config.startDate ?? addDays(today, -DEFAULT_COLD_START_DAYS);

    let from = watermark && ISO_DATE.test(watermark.slice(0, 10))
        ? addDays(watermark.slice(0, 10), -config.lookbackDays)
        : coldStart;

    if (config.startDate) from = maxDate(from, config.startDate);
    from = minDate(from, today);

    return { From: from, To: windowEnd(from, config, today) };
}

/**
 * The window after this one, or null when the run has reached `today`.
 *
 * Advancing here rather than ending the run is what lets a cold backfill of a year finish in a single
 * run: `maxWindowDays` bounds each REQUEST, not the run.
 */
export function nextWindow(current: GA4Window, config: GA4Config, today: string): GA4Window | null {
    if (current.To >= today) return null;
    const from = addDays(current.To, 1);
    return { From: from, To: windowEnd(from, config, today) };
}

function windowEnd(from: string, config: GA4Config, today: string): string {
    return minDate(addDays(from, config.maxWindowDays - 1), today);
}

export function formatCursor(c: GA4Cursor): string {
    return [c.Today, c.From, c.To, c.Offset].join(SEP);
}

/**
 * Parse a cursor, or null when it is absent or malformed.
 *
 * Null means "start this object over from the watermark", which is always safe: identity is the
 * declared key, so re-reading rows upserts them. Throwing instead would strand the object on a bad
 * cursor with no way forward short of clearing it by hand.
 */
export function parseCursor(raw: string | null | undefined): GA4Cursor | null {
    if (!raw) return null;
    const parts = raw.split(SEP);
    if (parts.length !== 4) return null;

    const [today, from, to, offsetRaw] = parts;
    if (!ISO_DATE.test(today) || !ISO_DATE.test(from) || !ISO_DATE.test(to)) return null;
    if (from > to) return null;

    const offset = Number(offsetRaw);
    if (!Number.isInteger(offset) || offset < 0) return null;

    return { Today: today, From: from, To: to, Offset: offset };
}
