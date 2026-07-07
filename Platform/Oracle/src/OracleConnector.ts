import { RegisterClass } from '@memberjunction/global';
import { BaseIntegrationConnector } from '@memberjunction/integration-engine';
import { BaseSqlExternalDataSourceConnector } from '@memberjunction/integration-connectors';
// Side-effect import: registers the Oracle Database EDS driver ('OracleExternalDriver') with the MJGlobal
// ClassFactory so this connector can resolve it at runtime via ExternalDataSourceRouter.
import '@memberjunction/external-data-source-oracle';

/**
 * Oracle Database ingestion connector — a **thin nominal leaf**. It carries no logic: all
 * connect / introspect / read is delegated to the shared EDS Oracle Database driver ('OracleExternalDriver'),
 * and incremental sync + record assembly live in {@link BaseSqlExternalDataSourceConnector}. The connection binds to a
 * shared `MJ: External Data Sources` row via `CompanyIntegration.Configuration.externalDataSourceID`
 * (credentials + host on that EDS row, via CredentialEngine). Exists so Oracle Database is a first-class,
 * discoverable Integration consistent with every other connector.
 *
 * Requires @memberjunction/* >= 5.46.0 (the EDS-consuming connector heart + the OracleExternalDriver driver).
 */
@RegisterClass(BaseIntegrationConnector, 'OracleConnector')
export class OracleConnector extends BaseSqlExternalDataSourceConnector {
    public override get IntegrationName(): string {
        return 'Oracle Database';
    }
}
