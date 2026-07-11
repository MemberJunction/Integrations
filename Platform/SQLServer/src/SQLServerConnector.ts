import { RegisterClass } from '@memberjunction/global';
import { BaseIntegrationConnector } from '@memberjunction/integration-engine';
import { BaseSqlExternalDataSourceConnector } from '@memberjunction/integration-connectors';
// Side-effect import: registers the SQL Server EDS driver ('SQLServerExternalDriver') with the MJGlobal
// ClassFactory so this connector can resolve it at runtime via ExternalDataSourceRouter.
import '@memberjunction/external-data-source-sqlserver';

/**
 * SQL Server ingestion connector — a **thin nominal leaf**. It carries no logic: all
 * connect / introspect / read is delegated to the shared EDS SQL Server driver ('SQLServerExternalDriver'),
 * and incremental sync + record assembly live in {@link BaseSqlExternalDataSourceConnector}. The connection binds to a
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
}
