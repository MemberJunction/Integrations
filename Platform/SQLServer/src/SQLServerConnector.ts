import { RegisterClass } from '@memberjunction/global';
import { BaseIntegrationConnector, type FetchContext, type FetchBatchResult } from '@memberjunction/integration-engine';
import { BaseSqlExternalDataSourceConnector } from '@memberjunction/integration-connectors';
// Side-effect import: registers the SQL Server EDS driver ('SQLServerExternalDriver') with the MJGlobal
// ClassFactory so this connector can resolve it at runtime via ExternalDataSourceRouter.
import '@memberjunction/external-data-source-sqlserver';

/**
 * SQL Server ingestion connector — a **thin leaf**. All connect / introspect / read is delegated to the
 * shared EDS SQL Server driver ('SQLServerExternalDriver'), and incremental sync + record assembly live in
 * {@link BaseSqlExternalDataSourceConnector}. The one piece of logic here is the page position
 * {@link FetchChanges} hands back to the engine (see that method). The connection binds to a
 * shared `MJ: External Data Sources` row via `CompanyIntegration.Configuration.externalDataSourceID`
 * (credentials + host on that EDS row, via CredentialEngine). Exists so SQL Server is a first-class,
 * discoverable Integration consistent with every other connector.
 *
 * Requires @memberjunction/* >= 5.46.0 (the EDS-consuming connector heart + the SQLServerExternalDriver driver).
 */
// Primary key follows the catalog convention (className == npm package name;
// see scripts/build-connectors-catalog.mjs) — instance discovery reports the
// package name, so the legacy bare key never matched in the catalog. The
// legacy alias stays registered so pre-migration tenant Integration rows
// keep resolving.
@RegisterClass(BaseIntegrationConnector, '@memberjunction/connector-sqlserver')
@RegisterClass(BaseIntegrationConnector, 'SQLServerConnector')
export class SQLServerConnector extends BaseSqlExternalDataSourceConnector {
    public override get IntegrationName(): string {
        return 'SQL Server';
    }

    /**
     * Fetches one page through the base class, then corrects the offset the engine is told to use next.
     *
     * The base class returns `NextOffset = offset + BatchSize`: a position in the set the scan started
     * with. The engine does not keep that set. For every page after the first it passes
     * `WatermarkValue` raised to this page's `NewWatermarkValue`, together with that offset. The next
     * query is then `WHERE <watermark> >= <raised value> ... OFFSET n × BatchSize`: it starts after the
     * rows already read and skips a further `n × BatchSize` rows. Most changed rows were never fetched,
     * the run reported success, and the stored watermark moved past them (#506).
     *
     * So the offset is given relative to the watermark the engine will send. Rows come back ordered by
     * watermark, then primary key. Of the rows at or above the next watermark, the only ones already read
     * are those that carry exactly that watermark value, and they sort first. `NextOffset` is their
     * count. When a whole page carries the watermark value the page was asked for, the count continues
     * from the offset that page started at.
     *
     * Each page is then a short seek from the newest watermark read so far. A row that changes during
     * the scan moves to a later watermark and is read later in the same scan, or by the next run.
     *
     * Limit: if a row that was already read, and that shares the newest watermark value with rows not
     * yet read, is updated or deleted between two pages, one of those unread rows is skipped. Removing
     * that needs a seek on (watermark, primary key) in the driver.
     *
     * No state is kept here. An object with no watermark column, or a page whose last row has no
     * watermark value, keeps the base class's plain offset.
     */
    public override async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
        const result = await super.FetchChanges(ctx);
        const nextWatermark = result.NewWatermarkValue;
        if (!result.HasMore || nextWatermark == null) {
            return result;
        }
        const { WatermarkField: watermarkField } = await this.ResolveObjectMeta(ctx);
        if (!watermarkField) {
            return result;
        }

        // Rows are in watermark order, so the ones carrying the newest value are at the end of the page.
        // MaxWatermark renders a single row's value the same way it rendered NewWatermarkValue.
        let readAtNextWatermark = 0;
        for (let i = result.Records.length - 1; i >= 0; i--) {
            if (this.MaxWatermark([result.Records[i].Fields], watermarkField) !== nextWatermark) {
                break;
            }
            readAtNextWatermark++;
        }

        // The watermark did not move: this page lies inside one run of equal values, which began
        // `ctx.CurrentOffset` rows before it.
        const carried = ctx.WatermarkValue === nextWatermark ? (ctx.CurrentOffset ?? 0) : 0;
        return { ...result, NextOffset: carried + readAtNextWatermark };
    }
}
