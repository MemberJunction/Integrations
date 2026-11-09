import { IsPiiMode, type PiiMode } from './pii/policy.js';

/**
 * The watermark this connector saves is the END of the last completed `GetCustomerData` window plus
 * the personal-data mode the rows were written under, e.g. `2026-11-08T00:00:00.000Z|pii=pseudonymize`.
 * Carrying the mode lets the next run refuse to append rows of a different shape to the same table.
 */
export interface DataFeedWatermark {
    /** ISO-8601 UTC instant: the exclusive upper bound already fetched. */
    to: string;
    /** Absent when the stored value predates the mode suffix. */
    piiMode: PiiMode | null;
}

export function EncodeWatermark(w: DataFeedWatermark): string {
    return w.piiMode ? `${w.to}|pii=${w.piiMode}` : w.to;
}

export function DecodeWatermark(value: string | null | undefined): DataFeedWatermark | null {
    if (!value || value.trim() === '') return null;
    const [to, ...rest] = value.split('|');
    const modePart = rest.find((p) => p.startsWith('pii='));
    const mode = modePart?.slice(4);
    if (!to || Number.isNaN(Date.parse(to))) return null;
    return { to: to.trim(), piiMode: IsPiiMode(mode) ? mode : null };
}

/** Where a paged read of one window stands: the window itself and how many rows have been handed out. */
export interface WindowCursor {
    from: string;
    to: string;
    offset: number;
}

export function EncodeCursor(c: WindowCursor): string {
    return JSON.stringify(c);
}

export function DecodeCursor(value: string | null | undefined): WindowCursor | null {
    if (!value) return null;
    try {
        const parsed: unknown = JSON.parse(value);
        if (parsed && typeof parsed === 'object') {
            const o = parsed as Record<string, unknown>;
            if (typeof o['from'] === 'string' && typeof o['to'] === 'string' && typeof o['offset'] === 'number') {
                return { from: o['from'], to: o['to'], offset: o['offset'] };
            }
        }
    } catch {
        /* fall through */
    }
    return null;
}

/** `[from, min(from + days, now))`. Returns null when `from` is not before `now`. */
export function PlanWindow(from: Date, windowDays: number, now: Date): { from: Date; to: Date } | null {
    if (from.getTime() >= now.getTime()) return null;
    const end = new Date(from.getTime() + windowDays * 24 * 60 * 60 * 1000);
    return { from, to: end.getTime() < now.getTime() ? end : now };
}

/**
 * .NET round-trip text → Date. The fraction is cut to milliseconds; a value with no zone is read as
 * UTC (Spektrix sends server-local time unspecified, so this is approximate and only informs
 * `ExternalRecord.ModifiedAt`, never the watermark).
 */
export function ParseDotNetDateTime(value: string | null | undefined): Date | undefined {
    if (!value) return undefined;
    const trimmed = value.replace(/(\.\d{3})\d+/, '$1');
    const withZone = /(Z|[+-]\d{2}:\d{2})$/.test(trimmed) ? trimmed : `${trimmed}Z`;
    const ms = Date.parse(withZone);
    return Number.isNaN(ms) ? undefined : new Date(ms);
}
