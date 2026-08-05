import { describe, it, expect } from 'vitest';
import { runIdWindowScan, type IdWindowScanOptions } from '../index.js';

/**
 * A fake vendor: it holds a set of ids that exist, plus a set of ids it REFUSES (the vendor validates its
 * own response per record, so any window containing one fails wholesale — the real Moodle/Totara shape).
 * It records every window it was asked for, which is how the bisection tests assert the descent.
 */
function makeVendor(opts: { present: number[]; poisoned?: number[] }) {
    const present = new Set(opts.present);
    const poisoned = new Set(opts.poisoned ?? []);
    const calls: number[][] = [];
    const fetchWindow = async (ids: number[]): Promise<Record<string, unknown>[]> => {
        calls.push(ids);
        if (ids.some((id) => poisoned.has(id))) throw new Error('[invalidresponse] Invalid response value detected');
        return ids.filter((id) => present.has(id)).map((id) => ({ id, name: `rec-${id}` }));
    };
    return { fetchWindow, calls };
}

/** A clock that only moves when a test says so, so budget behaviour is deterministic. */
function makeClock() {
    let t = 0;
    return { now: (): number => t, advance: (ms: number): void => { t += ms; } };
}

function scan(over: Partial<IdWindowScanOptions> & Pick<IdWindowScanOptions, 'FetchWindow'>) {
    return runIdWindowScan({ ObjectName: 'Users', Now: () => 0, ...over });
}

describe('runIdWindowScan', () => {
    it('reads a contiguous range through the bulk-by-key reader and hands back a resumable cursor', async () => {
        const v = makeVendor({ present: [1, 2, 3, 4, 5, 6] });
        const res = await scan({ FetchWindow: v.fetchWindow, Config: { windowSize: 3, windowsPerCall: 2 } });

        expect(res.Records.map((r) => r['id'])).toEqual([1, 2, 3, 4, 5, 6]);
        expect(res.HasMore).toBe(true);
        expect(res.NextAfterKeyValue).toBe('7|0|6|0');
        expect(v.calls).toEqual([[1, 2, 3], [4, 5, 6]]);
    });

    it('resumes exactly where the previous call stopped, never re-reading from the top', async () => {
        const v = makeVendor({ present: [10, 11] });
        const res = await scan({
            FetchWindow: v.fetchWindow,
            Config: { windowSize: 2, windowsPerCall: 1 },
            AfterKeyValue: '10|3|9',
        });

        expect(v.calls).toEqual([[10, 11]]);
        expect(res.NextAfterKeyValue).toBe('12|0|11|0');   // records found → the empty run resets
    });

    it('stops after N consecutive empty windows and reports the range it covered', async () => {
        const v = makeVendor({ present: [] });
        const res = await scan({
            FetchWindow: v.fetchWindow,
            Config: { windowSize: 5, windowsPerCall: 2, maxConsecutiveEmptyWindows: 2 },
        });

        expect(res.HasMore).toBe(false);
        expect(res.NextAfterKeyValue).toBeUndefined();
        const end = res.Warnings?.find((w) => w.Code === 'ID_WINDOW_SCAN_END');
        expect(end?.Data).toMatchObject({ scannedThrough: 10, maxConsecutiveEmptyWindows: 2 });
    });

    it('REGRESSION: the scan-end warning reports the highest id SEEN, not 0', async () => {
        // The call that ends a scan is by construction the all-empty one, so a per-call maximum reports 0 on
        // exactly the warning that needs it. Live, this claimed highestIdSeen:0 after landing 24,682 users.
        const v = makeVendor({ present: [] });
        const res = await scan({
            FetchWindow: v.fetchWindow,
            Config: { windowSize: 5, windowsPerCall: 1, maxConsecutiveEmptyWindows: 1 },
            AfterKeyValue: '100|0|93',
        });

        expect(res.Warnings?.find((w) => w.Code === 'ID_WINDOW_SCAN_END')?.Data).toMatchObject({ highestIdSeen: 93 });
    });

    it('carries the highest id seen forward across calls', async () => {
        const v = makeVendor({ present: [4] });
        const res = await scan({
            FetchWindow: v.fetchWindow,
            Config: { windowSize: 5, windowsPerCall: 1 },
            AfterKeyValue: '1|0|0',
        });
        expect(res.NextAfterKeyValue).toBe('6|0|4|0');

        const v2 = makeVendor({ present: [] });
        const res2 = await scan({
            FetchWindow: v2.fetchWindow,
            Config: { windowSize: 5, windowsPerCall: 1 },
            AfterKeyValue: res.NextAfterKeyValue,
        });
        expect(res2.NextAfterKeyValue).toBe('11|1|4|0');   // still remembers id 4 from the previous call
    });

    it('accepts a two-part cursor written by an older build', async () => {
        const v = makeVendor({ present: [3] });
        const res = await scan({ FetchWindow: v.fetchWindow, Config: { windowSize: 3, windowsPerCall: 1 }, AfterKeyValue: '3|2' });
        expect(v.calls).toEqual([[3, 4, 5]]);
        expect(res.NextAfterKeyValue).toBe('6|0|3|0');
    });

    it('isolates an unreadable id by bisection and keeps every readable record in the window', async () => {
        const v = makeVendor({ present: [1, 2, 3, 4], poisoned: [1] });
        const res = await scan({ FetchWindow: v.fetchWindow, Config: { windowSize: 4, windowsPerCall: 1 } });

        expect(res.Records.map((r) => r['id'])).toEqual([2, 3, 4]);
        expect(res.Warnings?.find((w) => w.Code === 'ID_WINDOW_RECORD_SKIPPED')?.Data).toMatchObject({ id: 1 });
        expect(res.NextAfterKeyValue).toBe('5|0|4|0');     // the whole window was examined; the scan moves on
    });

    it('a window that ERRORS never counts as an empty one', async () => {
        // Otherwise a transient failure trips the past-the-end heuristic and silently drops every later record.
        const v = makeVendor({ present: [], poisoned: [1] });
        const res = await scan({
            FetchWindow: v.fetchWindow,
            Config: { windowSize: 1, windowsPerCall: 1, maxConsecutiveEmptyWindows: 1 },
        });

        expect(res.HasMore).toBe(true);
        expect(res.Warnings?.some((w) => w.Code === 'ID_WINDOW_SCAN_END')).toBe(false);
        expect(res.NextAfterKeyValue).toBe('2|0|0|1');
    });

    it('stops at the budget with partial progress rather than being killed with nothing', async () => {
        const clock = makeClock();
        const v = makeVendor({ present: [1, 2, 3, 4, 5, 6] });
        const res = await runIdWindowScan({
            ObjectName: 'Users',
            Now: clock.now,
            Config: { windowSize: 2, windowsPerCall: 3, budgetMs: 50 },
            FetchWindow: async (ids) => { clock.advance(40); return v.fetchWindow(ids); },
        });

        // Two windows fit (the second starts at t=40, still inside the budget); the third is not started, and
        // the cursor stops at the first id this call did not examine.
        expect(res.Records.map((r) => r['id'])).toEqual([1, 2, 3, 4]);
        expect(res.HasMore).toBe(true);
        expect(res.NextAfterKeyValue).toBe('5|0|4|0');
        expect(res.Warnings?.find((w) => w.Code === 'ID_WINDOW_BUDGET_STOP')?.Data).toMatchObject({ scannedThrough: 4 });
    });

    it('PROGRESS GUARANTEE: an unreadable window with the budget ALREADY spent still advances the cursor', async () => {
        // Without the exemption this call resolves nothing, returns the cursor unchanged, and is the same call
        // forever — the span-lock that produced 61 identical failures and 0 users live.
        const v = makeVendor({ present: [], poisoned: [1, 2, 3, 4] });
        const res = await scan({ FetchWindow: v.fetchWindow, Config: { windowSize: 4, windowsPerCall: 1, budgetMs: 0 } });

        expect(res.Warnings?.find((w) => w.Code === 'ID_WINDOW_RECORD_SKIPPED')?.Data).toMatchObject({ id: 1 });
        expect(res.HasMore).toBe(true);
        expect(res.NextAfterKeyValue).toBe('2|0|0|1');
    });

    it('propagates a rate-limit refusal for the engine to back off, instead of bisecting into the limiter', async () => {
        const reported: unknown[] = [];
        await expect(scan({
            FetchWindow: async () => { throw new Error('429 Too Many Requests (Retry-After: 30)'); },
            RateLimitReport: (e) => { if (e) reported.push(e); },
            Config: { windowSize: 8, windowsPerCall: 1 },
        })).rejects.toThrow(/429/);
        expect(reported).toHaveLength(1);
    });

    it('honours the rate limiter before every request, bisection sub-requests included', async () => {
        let acquires = 0;
        const v = makeVendor({ present: [1, 2], poisoned: [1] });
        await scan({
            FetchWindow: v.fetchWindow,
            RateLimitAcquire: async () => { acquires++; },
            Config: { windowSize: 2, windowsPerCall: 1 },
        });
        expect(acquires).toBe(v.calls.length);
        expect(acquires).toBeGreaterThan(1);   // the window plus its bisection
    });

    it('bounds bisection per call so one pathological window cannot monopolise it', async () => {
        const v = makeVendor({ present: [], poisoned: Array.from({ length: 64 }, (_u, i) => i + 1) });
        await scan({
            FetchWindow: v.fetchWindow,
            Config: { windowSize: 64, windowsPerCall: 1, maxBisectSplitsPerCall: 3 },
        });
        // The left spine descends to isolate the first id (the progress guarantee), then the budget stops it.
        expect(v.calls.length).toBeLessThan(20);
    });

    it('stops re-deriving the bisection once ids are unreadable in a RUN, and returns to bulk on the first good id', async () => {
        // Live shape: not scattered bad ids but an unbroken block (one stray, then 5801-5853). Bisection
        // isolates the first correctly and then starts over for each neighbour — 235 requests to skip 57
        // records. Past the threshold the block is walked one id at a time instead.
        const v = makeVendor({ present: [11, 12, 13, 14, 15], poisoned: Array.from({ length: 10 }, (_u, i) => i + 1) });
        const res = await scan({ FetchWindow: v.fetchWindow, Config: { windowSize: 5, windowsPerCall: 3 } });

        // The SECOND poisoned window is never asked for in bulk and never bisected — it goes straight to singles.
        expect(v.calls.filter((c) => c.length > 1 && c[0] === 6)).toEqual([]);
        // Every one of the 10 unreadable ids is still examined and still individually reported.
        expect(res.Warnings?.filter((w) => w.Code === 'ID_WINDOW_RECORD_SKIPPED').map((w) => w.Data?.['id']))
            .toEqual(Array.from({ length: 10 }, (_u, i) => i + 1));
        // Announced once, not once per window — the whole point is to remove noise.
        expect(res.Warnings?.filter((w) => w.Code === 'ID_WINDOW_SINGLE_STEP')).toHaveLength(1);
        // id 11 succeeds → the run clears → the rest of that window is fetched in ONE request again.
        expect(v.calls).toContainEqual([12, 13, 14, 15]);
        expect(res.Records.map((r) => r['id'])).toEqual([11, 12, 13, 14, 15]);
        expect(res.NextAfterKeyValue).toBe('16|0|15|0');
    });

    it('costs strictly fewer requests than bisecting the same poison block', async () => {
        const poisoned = Array.from({ length: 10 }, (_u, i) => i + 1);
        const cfg = { windowSize: 5, windowsPerCall: 3, maxBisectSplitsPerCall: 999 };

        const fast = makeVendor({ present: [11, 12, 13, 14, 15], poisoned });
        await scan({ FetchWindow: fast.fetchWindow, Config: cfg });

        // Same input with the optimisation switched off (threshold beyond any run this test can produce).
        const slow = makeVendor({ present: [11, 12, 13, 14, 15], poisoned });
        await scan({ FetchWindow: slow.fetchWindow, Config: { ...cfg, singleStepAfterConsecutiveSkips: 999 } });

        expect(fast.calls.length).toBeLessThan(slow.calls.length);
    });

    it('remembers the run of unreadable ids ACROSS calls, so a block spanning calls is only paid for once', async () => {
        // A poison block is far longer than one call's windows. A per-call counter would forget it at every
        // call boundary and pay for the first bisection again and again — which is most of the waste.
        const v1 = makeVendor({ present: [], poisoned: [1, 2] });
        const res = await scan({ FetchWindow: v1.fetchWindow, Config: { windowSize: 2, windowsPerCall: 1 } });
        expect(res.NextAfterKeyValue).toBe('3|0|0|2');

        const v2 = makeVendor({ present: [], poisoned: [3, 4] });
        await scan({ FetchWindow: v2.fetchWindow, Config: { windowSize: 2, windowsPerCall: 1 }, AfterKeyValue: res.NextAfterKeyValue });
        expect(v2.calls[0]).toEqual([3]);                          // straight to singles, no doomed bulk request
        expect(v2.calls.every((c) => c.length === 1)).toBe(true);
    });

    it('reads ids off records through IdOf when the key is not a plain top-level field', async () => {
        const res = await scan({
            FetchWindow: async (ids) => ids.map((id) => ({ nested: { key: id } })),
            IdOf: (r) => (r['nested'] as { key: number }).key,
            Config: { windowSize: 2, windowsPerCall: 1 },
        });
        expect(res.NextAfterKeyValue).toBe('3|0|2|0');
    });
});
