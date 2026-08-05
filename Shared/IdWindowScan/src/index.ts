import type { FetchWarning } from '@memberjunction/integration-engine';

/**
 * ID-WINDOW SCAN — how to read an object whose "list" function is not a list function.
 *
 * A depressing number of vendor APIs expose an object that cannot actually be listed: the documented
 * list call has no pagination params, or it is a SEARCH endpoint that the vendor's own docs warn will
 * "be very slow or timeout" without narrow criteria. Asked for everything, it never answers inside the
 * engine's `FetchChangesMs` budget, the batch is KILLED, and the object persists **zero records behind
 * an otherwise-green run** — the worst failure shape there is, because it reads as "this tenant has no
 * people" rather than as an error. (Found live on Totara/Moodle `core_user_get_users`; the same shape
 * exists wherever a bulk reader takes an explicit key list but the list endpoint takes none.)
 *
 * The way out is to stop asking the question the server cannot answer. Nearly every such API also
 * offers a BULK-BY-KEY reader — "give me the records for exactly these ids" — which is an indexed
 * primary-key lookup rather than a search. This helper walks the object's numeric key in bounded
 * windows through that reader, so **every request is bounded by construction**, and resumes across
 * `FetchChanges` calls via the engine's keyset channel so a scan spans as many calls as it needs
 * without ever re-reading from the top.
 *
 * Three properties are load-bearing, and each one was paid for by a live failure:
 *
 *  1. **The CALL bounds itself in time, not just each request.** Bounding requests alone is not enough —
 *     several bounded windows in one call can overrun the budget together and be killed with nothing,
 *     which is the original defect wearing a different hat. The scan carries `budgetMs` (under the
 *     engine's kill), returns what it scanned with its cursor, and says so via `ID_WINDOW_BUDGET_STOP`.
 *  2. **One unreadable record costs one record, not the object.** Some vendors validate their own
 *     response per record, so a single bad row fails the whole call however many good rows it held.
 *     Since a failed window (correctly) is not an empty one, the cursor cannot advance and the scan
 *     re-requests the same window forever. Failed windows are therefore BISECTED to single ids; an id
 *     that fails alone is skipped with `ID_WINDOW_RECORD_SKIPPED` naming it, and the scan moves on.
 *  3. **Coverage is never traded for speed.** Windows are contiguous and the cursor only ever advances
 *     over the prefix actually examined, so no id is stepped over unread. Stopping on the past-the-end
 *     heuristic ALWAYS emits `ID_WINDOW_SCAN_END` with the range covered, so a premature stop is visible
 *     in the run instead of silently truncating the object.
 *
 * The helper is deliberately vendor-agnostic: it knows nothing about HTTP, auth, or record shape. The
 * caller supplies {@link IdWindowScanOptions.FetchWindow}, which turns a list of ids into raw records
 * (and THROWS on any vendor or transport error — that is the signal bisection reads), and maps the raw
 * records it gets back into `ExternalRecord`s itself.
 */

/** Knobs, as read from an object's `Configuration.idWindowScan`. Every one has a working default. */
export interface IdWindowScanConfig {
    /** Name of the numeric key being walked. Used in messages and to read the id off a raw record. Default `'id'`. */
    field?: string;
    /** Ids per request. Keep it small enough that a FULL BISECTION of one window still fits the budget. Default 25. */
    windowSize?: number;
    /** Windows attempted per `FetchChanges` call (run concurrently, folded in order). Default 2. */
    windowsPerCall?: number;
    /** Consecutive empty windows that mean "past the end of the table". Default 40. */
    maxConsecutiveEmptyWindows?: number;
    /**
     * Wall-clock budget for the whole call. MUST be under the engine's `FetchChangesMs` (30000), because a
     * call the engine kills persists NOTHING. Default 20000. Zero is meaningful and testable: "one window,
     * then stop".
     */
    budgetMs?: number;
    /** Bisection splits allowed per call, so one pathological window cannot monopolise it. Default 8. */
    maxBisectSplitsPerCall?: number;
    /**
     * Consecutive unreadable ids after which the scan stops bisecting and reads id-at-a-time until one
     * succeeds. Default 2. Live evidence: unreadable ids arrive in CONTIGUOUS BLOCKS (one bad profile field
     * on a batch of accounts created together), so re-deriving the same bisection tree for each neighbour is
     * pure waste — 235 requests to skip 57 records, observed. Raise it to bisect longer before giving up on
     * bulk reads; there is no correctness difference either way, only cost.
     */
    singleStepAfterConsecutiveSkips?: number;
}

/** What one window actually yielded: the records read, and the last id of the contiguous prefix EXAMINED. */
interface IdWindowResult {
    Records: Record<string, unknown>[];
    /** `windowStart - 1` means nothing was read at all. */
    ResolvedThrough: number;
}

class IdWindowDeadlineError extends Error {
    constructor() {
        super('id-window scan reached its fetch budget');
        this.name = 'IdWindowDeadlineError';
    }
}

export interface IdWindowScanOptions {
    /** Object name, used only in warning text. */
    ObjectName: string;
    /** Knobs (typically the object's `Configuration.idWindowScan`). */
    Config?: IdWindowScanConfig;
    /** The engine's keyset cursor from the previous call (`FetchContext.AfterKeyValue`). */
    AfterKeyValue?: string | null;
    /** `FetchContext.MaxConcurrency` — how many windows may be in flight at once. Default 1. */
    MaxConcurrency?: number;
    /** `FetchContext.RateLimitAcquire` — awaited before every request, including bisection sub-requests. */
    RateLimitAcquire?: () => Promise<void>;
    /** `FetchContext.RateLimitReport` — called after every response, and with the error on a rate-limit refusal. */
    RateLimitReport?: (error?: unknown) => void;
    /**
     * Read exactly these ids. MUST THROW on any vendor or transport error — a thrown error is what triggers
     * bisection, and an error swallowed into an empty array reads as "past the end of the table" instead.
     * Rate-limit refusals should throw with a message matching 429 / "rate limit" / "Retry-After" so the scan
     * propagates them for the engine's backoff rather than bisecting into the limiter.
     */
    FetchWindow: (ids: number[]) => Promise<Record<string, unknown>[]>;
    /** How to read the id off a raw record. Defaults to `Number.parseInt(record[field])`. */
    IdOf?: (record: Record<string, unknown>) => number;
    /** Clock seam, for deterministic tests. Defaults to `Date.now`. */
    Now?: () => number;
}

export interface IdWindowScanResult {
    /** RAW records, in id order. The caller maps these to `ExternalRecord`s. */
    Records: Record<string, unknown>[];
    /** False only when the past-the-end heuristic fired — i.e. the scan is complete. */
    HasMore: boolean;
    /** Opaque cursor to hand back as `FetchContext.AfterKeyValue`. Absent once `HasMore` is false. */
    NextAfterKeyValue?: string;
    /** Diagnostics for the engine's run artifact. Never empty-but-present; absent when there are none. */
    Warnings?: FetchWarning[];
}

/** Bounded-concurrency map. Kept local so the package stays dependency-free. */
async function runBounded<T>(items: T[], limit: number, worker: (item: T) => Promise<void>): Promise<void> {
    const queue = [...items];
    const lanes = Array.from({ length: Math.max(1, Math.min(limit, queue.length)) }, async () => {
        for (;;) {
            const next = queue.shift();
            if (next === undefined) return;
            await worker(next);
        }
    });
    await Promise.all(lanes);
}

/**
 * The cursor is `"<nextStartId>|<consecutiveEmptyWindows>|<highestIdSeen>|<consecutiveSkips>"`.
 *
 * `highestIdSeen` rides the cursor rather than being tracked per call because the call that ENDS a scan is,
 * by construction, the one whose windows were all empty — so a per-call maximum reports 0 on exactly the
 * warning that needs it (observed: `ID_WINDOW_SCAN_END` claiming `highestIdSeen: 0` after landing 24,682
 * users). `consecutiveSkips` rides it for the same reason: a poison block is far longer than one call's
 * couple of windows, so a per-call counter would forget it at every call boundary and pay for the first
 * bisection again and again. Shorter cursors from an older build still parse; the missing parts start at 0.
 */
function parseCursor(
    raw: string | null | undefined,
): { StartId: number; EmptyRun: number; HighestSeen: number; SkipRun: number } {
    const out = { StartId: 1, EmptyRun: 0, HighestSeen: 0, SkipRun: 0 };
    if (!raw) return out;
    const [rawStart, rawEmpty, rawHighest, rawSkips] = String(raw).split('|');
    const start = Number.parseInt(rawStart ?? '', 10);
    const empty = Number.parseInt(rawEmpty ?? '', 10);
    const highest = Number.parseInt(rawHighest ?? '', 10);
    const skips = Number.parseInt(rawSkips ?? '', 10);
    if (Number.isFinite(start) && start > 0) out.StartId = start;
    if (Number.isFinite(empty) && empty >= 0) out.EmptyRun = empty;
    if (Number.isFinite(highest) && highest >= 0) out.HighestSeen = highest;
    if (Number.isFinite(skips) && skips >= 0) out.SkipRun = skips;
    return out;
}

/**
 * Run one `FetchChanges` worth of id-window scanning. See the module header for the why.
 *
 * @returns raw records plus the cursor to resume from; `HasMore:false` only when the scan is genuinely done.
 */
export async function runIdWindowScan(options: IdWindowScanOptions): Promise<IdWindowScanResult> {
    const objectName = options.ObjectName;
    const cfg = options.Config ?? {};
    const field = cfg.field ?? 'id';
    const windowSize = positive(cfg.windowSize) ?? 25;
    const windowsPerCall = positive(cfg.windowsPerCall) ?? 2;
    const maxEmpty = positive(cfg.maxConsecutiveEmptyWindows) ?? 40;
    const budgetMs = nonNegative(cfg.budgetMs) ?? 20000;
    const now = options.Now ?? Date.now;
    const idOf = options.IdOf ?? ((record: Record<string, unknown>): number => Number.parseInt(String(record[field] ?? ''), 10));

    const startedAt = now();
    const outOfTime = (): boolean => now() - startedAt >= budgetMs;

    const cursor = parseCursor(options.AfterKeyValue);
    const startId = cursor.StartId;
    let emptyRun = cursor.EmptyRun;
    let highestSeen = cursor.HighestSeen;

    const warnings: FetchWarning[] = [];
    const windows = Array.from({ length: windowsPerCall }, (_unused, w) => startId + w * windowSize);
    const perWindow = new Map<number, IdWindowResult>();
    // Ids the vendor could not return AT ALL. Recorded so the fold can tell "this window held nothing" from
    // "this window held records we were refused" — only the former is evidence of being past the end.
    const skippedIds = new Set<number>();
    const bisectBudget = { remaining: positive(cfg.maxBisectSplitsPerCall) ?? 8 };
    // THE PROGRESS GUARANTEE. The deadline (and the bisect budget) are suspended until at least one id has
    // been EXAMINED — read, or proven unreadable. Not "one request issued": a call whose single request hit a
    // poisoned window would resolve nothing, return empty with an unchanged cursor, and be the same call
    // forever. Once one id is resolved the cursor can advance, so everything after that obeys the deadline.
    const resolved = { any: false };
    const deadlineHit = (): boolean => outOfTime() && resolved.any;
    // Carried across calls on the cursor — a poison block outlives any one call's windows.
    const skipRun = { count: cursor.SkipRun };

    const scanCtx: ScanContext = {
        ObjectName: objectName,
        Field: field,
        FetchWindow: options.FetchWindow,
        RateLimitAcquire: options.RateLimitAcquire,
        RateLimitReport: options.RateLimitReport,
        Warnings: warnings,
        SkippedIds: skippedIds,
        BisectBudget: bisectBudget,
        Resolved: resolved,
        SkipRun: skipRun,
        SingleStepAfter: positive(cfg.singleStepAfterConsecutiveSkips) ?? 2,
        SingleStepAnnounced: { done: false },
    };

    await runBounded(windows, Math.max(1, options.MaxConcurrency ?? 1), async (windowStart) => {
        // ONLY the first window carries the progress exemption. The windows run concurrently, so if they all
        // ignored the deadline while nothing was resolved, an unreadable range would put every lane into its
        // own bisection at once — several times the work the budget allows, and the call is killed with
        // nothing again. The cursor only ever needs the FIRST window to advance.
        const gate = windowStart === startId ? deadlineHit : outOfTime;
        if (gate()) return; // never started → left unset → the fold resumes from here
        perWindow.set(windowStart, await fetchWindowResilient(scanCtx, windowStart, windowSize, gate));
    });

    const out: Record<string, unknown>[] = [];
    let nextStartId = startId;
    let stopped = false;
    for (const windowStart of windows) {
        const result = perWindow.get(windowStart);
        if (result === undefined) break; // window never started — resume here next call
        // Advance ONLY over the contiguous prefix actually resolved. A window cut short mid-bisection still
        // contributes everything it read; the scan resumes at the first id it did not reach, so no id is ever
        // stepped over unexamined and no completed work is thrown away.
        nextStartId = result.ResolvedThrough + 1;
        const fullyResolved = result.ResolvedThrough >= windowStart + windowSize - 1;
        const refusedHere = [...skippedIds].some((id) => id >= windowStart && id < windowStart + windowSize);
        if (result.Records.length === 0) {
            if (!refusedHere && fullyResolved) emptyRun++;
        } else {
            emptyRun = 0;
            for (const raw of result.Records) {
                const idVal = idOf(raw);
                if (Number.isFinite(idVal) && idVal > highestSeen) highestSeen = idVal;
                out.push(raw);
            }
        }
        if (emptyRun >= maxEmpty) {
            stopped = true;
            break;
        }
        // Partially resolved → everything after it in this call is unexamined. Stop folding so the cursor stays
        // at the first unread id; later windows this call may have completed, but honouring them would step
        // over the gap.
        if (!fullyResolved) break;
    }

    // Ran out of budget before working through the windows this call planned. Not an error and not the end of
    // the scan — say so explicitly, so a short batch is never mistaken for a thin id range.
    if (!stopped && nextStartId < startId + windowsPerCall * windowSize && outOfTime()) {
        warnings.push({
            Code: 'ID_WINDOW_BUDGET_STOP',
            Message:
                `"${objectName}": stopped this batch at the ${budgetMs}ms fetch budget having scanned ` +
                `${field} ${startId}-${nextStartId - 1}; the rest resumes on the next call.`,
            Data: { object: objectName, scannedThrough: nextStartId - 1, budgetMs, windowSize, windowsPerCall },
        });
    }

    if (stopped) {
        warnings.push({
            Code: 'ID_WINDOW_SCAN_END',
            Message:
                `"${objectName}": stopped after ${emptyRun} consecutive empty ${field} windows ` +
                `(${emptyRun * windowSize} ids with no records). Scanned ${field} 1-${nextStartId - 1}, ` +
                `highest ${field} seen ${highestSeen}. If this site has id gaps wider than that, raise ` +
                `Configuration.idWindowScan.maxConsecutiveEmptyWindows.`,
            Data: {
                object: objectName,
                scannedThrough: nextStartId - 1,
                highestIdSeen: highestSeen,
                windowSize,
                maxConsecutiveEmptyWindows: maxEmpty,
            },
        });
    }

    return {
        Records: out,
        HasMore: !stopped,
        NextAfterKeyValue: stopped ? undefined : `${nextStartId}|${emptyRun}|${highestSeen}|${skipRun.count}`,
        Warnings: warnings.length ? warnings : undefined,
    };
}

/** Everything the recursive window fetch needs, gathered so the recursion signature stays readable. */
interface ScanContext {
    ObjectName: string;
    Field: string;
    FetchWindow: (ids: number[]) => Promise<Record<string, unknown>[]>;
    RateLimitAcquire?: (() => Promise<void>) | undefined;
    RateLimitReport?: ((error?: unknown) => void) | undefined;
    Warnings: FetchWarning[];
    SkippedIds: Set<number>;
    BisectBudget: { remaining: number };
    Resolved: { any: boolean };
    /** Consecutive ids proven unreadable. Reset by ANY successful read; rides the cursor across calls. */
    SkipRun: { count: number };
    /** `SkipRun.count` at which bulk reads are abandoned for id-at-a-time. */
    SingleStepAfter: number;
    /** Single-step is announced once per call, not once per window — the point is to REMOVE noise. */
    SingleStepAnnounced: { done: boolean };
}

/** One request for a contiguous id window. Throws on any transport or in-band vendor error. */
async function fetchWindowRequest(
    ctx: ScanContext,
    windowStart: number,
    windowSize: number,
    outOfTime: () => boolean,
): Promise<Record<string, unknown>[]> {
    // The deadline is checked on BOTH sides of the rate-limit acquire. Checking only before issuing is not
    // enough: acquiring a token can block for an unbounded time, so a request cleared at 19s can still be in
    // flight past the engine's 30s kill — which is how a bisecting call overran its budget and was killed with
    // nothing to show, the exact failure the budget exists to prevent.
    if (outOfTime()) throw new IdWindowDeadlineError();
    if (ctx.RateLimitAcquire) await ctx.RateLimitAcquire();
    if (outOfTime()) throw new IdWindowDeadlineError();
    const ids = Array.from({ length: windowSize }, (_unused, i) => windowStart + i);
    const records = await ctx.FetchWindow(ids);
    ctx.RateLimitReport?.();
    // Marked resolved only AFTER a successful read. A window that failed has examined nothing; marking it
    // resolved would re-arm the deadline and strand the bisection that was about to isolate the bad id.
    ctx.Resolved.any = true;
    // A read that worked is the end of the poison block, whatever its size — one good id is enough to
    // justify going back to bulk requests.
    ctx.SkipRun.count = 0;
    return records;
}

/**
 * Fetch one id window, ISOLATING the ids the vendor refuses instead of losing the window to them.
 *
 * Returns the records read plus `ResolvedThrough` — the last id of the CONTIGUOUS PREFIX actually examined.
 * A window cut short by the deadline or the bisect budget reports the prefix it got through, so the caller
 * resumes at the first unread id: partial progress is kept, and no id is ever stepped over unexamined.
 */
async function fetchWindowResilient(
    ctx: ScanContext,
    windowStart: number,
    windowSize: number,
    outOfTime: () => boolean,
): Promise<IdWindowResult> {
    const nothingRead: IdWindowResult = { Records: [], ResolvedThrough: windowStart - 1 };
    // Already inside a run of unreadable ids → do not pay for a bulk request that is about to fail and a
    // bisection that is about to re-derive what the last window already proved. See fetchWindowSingleStep.
    if (windowSize > 1 && ctx.SkipRun.count >= ctx.SingleStepAfter) {
        return await fetchWindowSingleStep(ctx, windowStart, windowSize, outOfTime);
    }
    try {
        const records = await fetchWindowRequest(ctx, windowStart, windowSize, outOfTime);
        return { Records: records, ResolvedThrough: windowStart + windowSize - 1 };
    } catch (e) {
        if (e instanceof IdWindowDeadlineError) return nothingRead; // out of budget → resume here next call
        const msg = e instanceof Error ? e.message : String(e);
        if (/429|rate.?limit|Retry-After/i.test(msg)) {
            ctx.RateLimitReport?.(e); // rate limit → propagate for the engine's backoff, never bisect into it
            throw e;
        }

        if (windowSize === 1) {
            // Single id. Retry once: a record that fails the vendor's own validation fails every time, a blip
            // does not — so one retry is what separates "bad record" from "bad moment".
            try {
                const records = await fetchWindowRequest(ctx, windowStart, 1, outOfTime);
                return { Records: records, ResolvedThrough: windowStart };
            } catch (retryErr) {
                if (retryErr instanceof IdWindowDeadlineError) return nothingRead;
                const retryMsg = retryErr instanceof Error ? retryErr.message : String(retryErr);
                ctx.SkippedIds.add(windowStart);
                ctx.Resolved.any = true; // an id proven unreadable is still an id examined
                ctx.SkipRun.count++;
                ctx.Warnings.push({
                    Code: 'ID_WINDOW_RECORD_SKIPPED',
                    Message:
                        `"${ctx.ObjectName}" ${ctx.Field}=${windowStart} could not be read and was SKIPPED — the ` +
                        `rest of the range synced normally. The vendor rejects its own response for this record ` +
                        `(typically one field that fails the vendor's return validation): ${retryMsg}`,
                    Data: { object: ctx.ObjectName, field: ctx.Field, id: windowStart, error: retryMsg },
                });
                return { Records: [], ResolvedThrough: windowStart }; // examined, unreadable — move on
            }
        }

        ctx.Warnings.push({
            Code: 'ID_WINDOW_FETCH_ERROR',
            Message:
                `"${ctx.ObjectName}" ${ctx.Field} window ${windowStart}-${windowStart + windowSize - 1}: ${msg} ` +
                `— bisecting to isolate the unreadable ${ctx.Field}(s).`,
            Data: { object: ctx.ObjectName, windowStart, windowSize },
        });

        // Bisect. The halves are sequential and the result is the CONTIGUOUS prefix: if the left half stops
        // short the right half is never attributed, because ids in the gap would otherwise be stepped over as
        // if they had been examined.
        // While nothing has been resolved yet the descent continues regardless of budget — but only down the
        // LEFT spine (the `return left` below fires immediately, since a left half that resolved nothing is
        // short). That isolates the first id in ~log2(windowSize) requests, which is what makes the progress
        // guarantee cheap even against a wholly unreadable window.
        if (ctx.Resolved.any && (ctx.BisectBudget.remaining <= 0 || outOfTime())) return nothingRead;
        ctx.BisectBudget.remaining--;
        const half = Math.floor(windowSize / 2);
        const left = await fetchWindowResilient(ctx, windowStart, half, outOfTime);
        if (left.ResolvedThrough < windowStart + half - 1) return left;
        if (ctx.BisectBudget.remaining <= 0 || outOfTime()) return left; // keep the prefix rather than lose it
        const right = await fetchWindowResilient(ctx, windowStart + half, windowSize - half, outOfTime);
        return {
            Records: [...left.Records, ...right.Records],
            ResolvedThrough: Math.max(left.ResolvedThrough, right.ResolvedThrough),
        };
    }
}

/**
 * Read a window ONE ID AT A TIME, for as long as the ids keep proving unreadable.
 *
 * Unreadable ids are not scattered — live evidence is a single stray plus an unbroken block of 53. Bisection
 * isolates the first of those correctly, but it starts over for the next id, and the next: the descent
 * 25→12→6→3→2→1 was paid 57 times to skip 57 records, 235 requests in all. Once a run of ids has already been
 * proven unreadable, the bulk request is a request known to fail and the descent is a rediscovery of what the
 * previous window just established, so both are skipped.
 *
 * This is a COST optimisation with no bearing on coverage: every id is still examined individually, still
 * skipped with its own `ID_WINDOW_RECORD_SKIPPED`, and `ResolvedThrough` is still the contiguous prefix
 * actually read. The first id that SUCCEEDS clears the run, and the rest of the window is fetched in bulk
 * again — the fast path is the normal path the moment the block ends.
 */
async function fetchWindowSingleStep(
    ctx: ScanContext,
    windowStart: number,
    windowSize: number,
    outOfTime: () => boolean,
): Promise<IdWindowResult> {
    if (!ctx.SingleStepAnnounced.done) {
        ctx.SingleStepAnnounced.done = true;
        ctx.Warnings.push({
            Code: 'ID_WINDOW_SINGLE_STEP',
            Message:
                `"${ctx.ObjectName}": ${ctx.SkipRun.count} consecutive unreadable ${ctx.Field}s, so this range is ` +
                `being read one ${ctx.Field} at a time instead of bisected per window. Coverage is unchanged — ` +
                `every ${ctx.Field} is still tried and every skip still reported. Bulk reads resume at the first ` +
                `${ctx.Field} that succeeds.`,
            Data: { object: ctx.ObjectName, field: ctx.Field, windowStart, windowSize, consecutiveSkips: ctx.SkipRun.count },
        });
    }

    const records: Record<string, unknown>[] = [];
    let resolvedThrough = windowStart - 1;
    for (let id = windowStart; id < windowStart + windowSize; id++) {
        if (ctx.SkipRun.count < ctx.SingleStepAfter) {
            // An id came back: the block is over. Read everything left in this window as one request, which
            // re-enters the ordinary path (the guard above no longer fires), so there is no recursion risk.
            const rest = await fetchWindowResilient(ctx, id, windowStart + windowSize - id, outOfTime);
            return {
                Records: [...records, ...rest.Records],
                ResolvedThrough: Math.max(resolvedThrough, rest.ResolvedThrough),
            };
        }
        const one = await fetchWindowResilient(ctx, id, 1, outOfTime);
        if (one.ResolvedThrough < id) break; // deadline mid-window → keep the prefix, resume here next call
        records.push(...one.Records);
        resolvedThrough = id;
    }
    return { Records: records, ResolvedThrough: resolvedThrough };
}

function positive(value: number | undefined): number | undefined {
    return typeof value === 'number' && Number.isFinite(value) && value > 0 ? Math.floor(value) : undefined;
}

function nonNegative(value: number | undefined): number | undefined {
    return typeof value === 'number' && Number.isFinite(value) && value >= 0 ? Math.floor(value) : undefined;
}
