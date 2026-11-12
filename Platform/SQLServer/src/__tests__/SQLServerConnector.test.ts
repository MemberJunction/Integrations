import { describe, it, expect, vi } from 'vitest';
import type { FetchContext, FetchBatchResult } from '@memberjunction/integration-engine';
import { BaseSqlExternalDataSourceConnector } from '@memberjunction/integration-connectors';

// The real driver package loads `mssql` and registers itself; these tests read from an in-memory table.
vi.mock('@memberjunction/external-data-source-sqlserver', () => ({}));

import { SQLServerConnector } from '../SQLServerConnector.js';

type Row = { id: number; updatedAt: Date | null };

interface RunViewParams {
    incrementalSince?: { Field: string; Value: string };
    defaultOrderByColumns?: readonly string[];
    maxRows?: number;
    offset?: number;
}

const BATCH_SIZE = 200;
const T0 = Date.UTC(2026, 0, 1);
const at = (seconds: number): Date => new Date(T0 + seconds * 1000);

/**
 * An in-memory table that answers RunView the way the SQL Server driver does:
 * `WHERE <field> >= <value> ORDER BY <columns> OFFSET <offset> ROWS FETCH NEXT <maxRows> ROWS ONLY`.
 * NULL sorts first, as it does in SQL Server, and never satisfies `>=`.
 */
class FakeTable {
    public Offsets: number[] = [];
    /** Called before each query with the 1-based page number, to change rows between two pages. */
    public BeforePage: ((page: number, rows: Row[]) => void) | undefined;

    constructor(public Rows: Row[]) {}

    public RunView = async (_dataSource: unknown, params: RunViewParams) => {
        this.Offsets.push(params.offset ?? 0);
        this.BeforePage?.(this.Offsets.length, this.Rows);
        const since = params.incrementalSince;
        const columns = (params.defaultOrderByColumns ?? []) as (keyof Row)[];
        const key = (value: Row[keyof Row]): number => (value == null ? -Infinity : Number(value));
        const rows = this.Rows
            .filter(r => !since || (r.updatedAt != null && r.updatedAt.getTime() >= new Date(since.Value).getTime()))
            .sort((a, b) => {
                for (const column of columns) {
                    const diff = key(a[column]) - key(b[column]);
                    if (diff !== 0) return diff;
                }
                return 0;
            })
            .slice(params.offset ?? 0, (params.offset ?? 0) + (params.maxRows ?? Infinity));
        return { success: true, rows: rows.map(r => ({ ...r })) };
    };
}

/** Binds a connector to the in-memory table instead of an External Data Source row. */
function bind<T extends BaseSqlExternalDataSourceConnector>(connector: T, table: FakeTable, watermarkField: string | null = 'updatedAt'): T {
    const seams = connector as unknown as {
        Resolve: () => Promise<unknown>;
        ResolveObjectMeta: () => Promise<unknown>;
    };
    seams.Resolve = async () => ({ dataSource: {}, driver: { RunView: table.RunView } });
    seams.ResolveObjectMeta = async () => ({ WatermarkField: watermarkField ?? undefined, PrimaryKeyFields: ['id'] });
    return connector;
}

/** The base class's paging, unchanged: what the connector did before the fix. */
class UnfixedConnector extends BaseSqlExternalDataSourceConnector {
    public override get IntegrationName(): string {
        return 'Unfixed';
    }
}

/**
 * The engine's per-object fetch loop, reduced to what it passes between pages (IntegrationEngine,
 * `while (hasMore)`): the watermark becomes the page's NewWatermarkValue when there is one, and the
 * offset becomes the page's NextOffset.
 */
async function scan(
    connector: { FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> },
    storedWatermark: string | null,
): Promise<{ ids: number[]; pages: number; watermark: string | null }> {
    const ids: number[] = [];
    let watermark = storedWatermark;
    let offset: number | undefined;
    let hasMore = true;
    let pages = 0;
    while (hasMore) {
        if (++pages > 1000) throw new Error('scan did not finish');
        const batch = await connector.FetchChanges({
            ObjectName: 'Item',
            WatermarkValue: watermark,
            BatchSize: BATCH_SIZE,
            CurrentOffset: offset,
            CompanyIntegration: {},
            ContextUser: {},
        } as unknown as FetchContext);
        ids.push(...batch.Records.map(r => Number(r.ExternalID)));
        if (batch.NewWatermarkValue) watermark = batch.NewWatermarkValue;
        offset = batch.NextOffset;
        hasMore = batch.HasMore;
    }
    return { ids, pages, watermark };
}

const distinct = (ids: number[]): number => new Set(ids).size;

/** `count` rows, one second apart, starting at second 1. */
const oneRowPerSecond = (count: number): Row[] =>
    Array.from({ length: count }, (_, i) => ({ id: i + 1, updatedAt: at(i + 1) }));

describe('SQLServerConnector.FetchChanges paging', () => {
    it('the base class paging skips most changed rows (#506)', async () => {
        const table = new FakeTable(oneRowPerSecond(7000));
        const result = await scan(bind(new UnfixedConnector(), table), at(0).toISOString());

        expect(result.pages).toBe(8);
        expect(result.ids).toHaveLength(1407);
        // The watermark has moved past the 5,593 rows that were never read.
        expect(result.watermark).toBe(at(7000).toISOString());
    });

    it('reads every changed row, once, when each row has its own watermark', async () => {
        const table = new FakeTable(oneRowPerSecond(7000));
        const result = await scan(bind(new SQLServerConnector(), table), at(0).toISOString());

        expect(result.ids).toHaveLength(7000);
        expect(distinct(result.ids)).toBe(7000);
        expect(result.watermark).toBe(at(7000).toISOString());
        // Every page after the first starts one row in: the row that carries the watermark itself.
        expect(Math.max(...table.Offsets)).toBe(1);
    });

    it('reads every row when all rows share one watermark (a bulk update)', async () => {
        const table = new FakeTable(Array.from({ length: 1000 }, (_, i) => ({ id: i + 1, updatedAt: at(5) })));
        const result = await scan(bind(new SQLServerConnector(), table), at(0).toISOString());

        expect(result.ids).toHaveLength(1000);
        expect(distinct(result.ids)).toBe(1000);
        expect(table.Offsets).toEqual([0, 200, 400, 600, 800]);
    });

    it('reads every row when runs of equal watermarks cross page boundaries', async () => {
        // 150 rows at second 1, 450 at second 2 (crossing two boundaries), 1 at second 3, 399 at second 4.
        const shape: [number, number][] = [[150, 1], [450, 2], [1, 3], [399, 4]];
        const rows: Row[] = [];
        for (const [count, second] of shape) {
            for (let i = 0; i < count; i++) rows.push({ id: rows.length + 1, updatedAt: at(second) });
        }
        const table = new FakeTable(rows);
        const result = await scan(bind(new SQLServerConnector(), table), at(0).toISOString());

        expect(result.ids).toHaveLength(1000);
        expect(distinct(result.ids)).toBe(1000);
        expect(result.watermark).toBe(at(4).toISOString());
    });

    it('counts rows that sit exactly on the stored watermark, whatever its text form', async () => {
        // The stored value names the same instant as the rows, without milliseconds.
        const table = new FakeTable(Array.from({ length: 500 }, (_, i) => ({ id: i + 1, updatedAt: at(0) })));
        const result = await scan(bind(new SQLServerConnector(), table), '2026-01-01T00:00:00Z');

        expect(result.ids).toHaveLength(500);
        expect(distinct(result.ids)).toBe(500);
    });

    it('reads every row of a full sync, including rows with no watermark value', async () => {
        const rows: Row[] = [
            ...Array.from({ length: 450 }, (_, i) => ({ id: i + 1, updatedAt: null })),
            ...Array.from({ length: 600 }, (_, i) => ({ id: i + 451, updatedAt: at(i + 1) })),
        ];
        const table = new FakeTable(rows);
        const result = await scan(bind(new SQLServerConnector(), table), null);

        expect(result.ids).toHaveLength(1050);
        expect(distinct(result.ids)).toBe(1050);
        expect(result.watermark).toBe(at(600).toISOString());
    });

    it('still reads a row that is updated during the scan', async () => {
        const table = new FakeTable(oneRowPerSecond(1000));
        // Before page 3, a row from page 1 and a row not yet read both get a newer watermark.
        table.BeforePage = (page, rows) => {
            if (page !== 3) return;
            rows.find(r => r.id === 10)!.updatedAt = at(5000);
            rows.find(r => r.id === 700)!.updatedAt = at(5001);
        };
        const result = await scan(bind(new SQLServerConnector(), table), at(0).toISOString());

        expect(distinct(result.ids)).toBe(1000);
        // Row 10 is read twice (before and after its update); row 700 once, at its new position.
        expect(result.ids.filter(id => id === 10)).toHaveLength(2);
        expect(result.ids.filter(id => id === 700)).toHaveLength(1);
        expect(result.watermark).toBe(at(5001).toISOString());
    });

    it('keeps plain offset paging for an object with no watermark column', async () => {
        const table = new FakeTable(oneRowPerSecond(1000));
        const result = await scan(bind(new SQLServerConnector(), table, null), null);

        expect(result.ids).toHaveLength(1000);
        expect(distinct(result.ids)).toBe(1000);
        expect(table.Offsets).toEqual([0, 200, 400, 600, 800]);
    });
});
