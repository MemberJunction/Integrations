import { describe, it, expect } from 'vitest';
import { type SentCall, type World, errorOf, fetchObject, isolateConnectorState, makeConnector, warningsOf } from './netforum-fake-xweb.js';

/**
 * Ported from scripts/smoke/netforum-watermark-literal.mjs.
 *
 * The incremental watermark predicate must be a literal netFORUM's SQL Server parses.
 *
 * The defect (a live tenant, 2026-10-12, first runs after MJ-RUN-53): FetchChanges echoed the watermark exactly as
 * xWeb serialised it — `2026-08-19T14:37:00-05:00` — into `szWhereClause`. SQL Server `datetime` / `smalldatetime`
 * cannot convert a string carrying a UTC offset ("Conversion failed when converting date and/or time from character
 * string" ×19, "... to smalldatetime data type" ×24 in one run), so ~43 objects faulted on every 5-minute run — each
 * one counted against xWeb's ~100 faults/day lock. Required: an unambiguous, language-independent literal
 * `YYYYMMDD HH:MM:00` (floored to the minute, so smalldatetime rounding can never move it later); an offset keeps
 * netFORUM's own wall clock (xWeb appends the SERVER's offset to its local time); a `Z` value backs off 24 h because
 * its wall clock is not netFORUM's. Inclusive `>=` means an earlier literal only re-reads rows — never skips one.
 */
describe('NetForumConnector — the watermark predicate is a literal SQL Server parses', () => {
    const { freshRoot } = isolateConnectorState();

    const wmObject = (): World[string] => ({
        wm: 'wm_change_date',
        fields: [['wm_key', true], ['wm_name', false], ['wm_change_date', false]],
        def: { MainTable: 'wm_table', KeyColumn: 'wm_key', Columns: [['wm_table', 'wm_key'], ['wm_table', 'wm_name'], ['wm_table', 'wm_change_date']] },
    });

    it.each([
        ['offset from xWeb (the live failure)', '2026-08-19T14:37:00-05:00', '20260819 14:37:00'],
        ['offset, older row', '2023-08-07T11:19:43-05:00', '20230807 11:19:00'],
        ['seeded value with milliseconds', '2026-09-24T14:18:00.000', '20260924 14:18:00'],
        ['seconds are floored to the minute', '2026-09-23T18:28:16.000', '20260923 18:28:00'],
        ['space-separated', '2026-09-23 18:28:59', '20260923 18:28:00'],
        ['Z value backs off 24 h', '2026-05-21T14:05:00Z', '20260520 14:05:00'],
    ])('%s: %s -> %s', async (_label, wm, want) => {
        const calls: SentCall[] = [];
        const r = await fetchObject(makeConnector({ Obj: wmObject() }, freshRoot(), calls), 'Obj', wm);
        const where = calls.map(x => x.where).join(' | ');
        expect(r.ok, errorOf(r)).toBe(true);
        expect(where).toContain(`'${want}'`);
        expect(where, 'no ISO T, offset or Z survives into the literal').not.toMatch(/T\d\d:|[+-]\d\d:\d\d'|Z'/);
    });

    // Not a date (e.g. a row-key GUID a keyset resume left on the watermark row): NEVER sent as a date predicate —
    // SQL Server answers "Conversion failed", which the connector once learned as "this column list breaks xWeb"
    // (a live tenant, 2026-10-14, 26 objects refused). The read goes out unfiltered and warns WATERMARK_NOT_A_DATE.
    it.each(['12345', 'd1f032ab-dae9-4392-9af6-5fec96826e0b'])('a non-date watermark (%s) is not sent as a predicate, and is reported', async (wm) => {
        const calls: SentCall[] = [];
        const r = await fetchObject(makeConnector({ ObjX: wmObject() }, freshRoot(), calls), 'ObjX', wm);
        const sent = calls.map(x => x.where).join(' ');
        expect(r.ok, errorOf(r)).toBe(true);
        expect(sent).not.toContain(wm);
        expect(sent).not.toMatch(/>=/);
        expect(warningsOf(r).some(w => w.Code === 'WATERMARK_NOT_A_DATE')).toBe(true);
    });
});
