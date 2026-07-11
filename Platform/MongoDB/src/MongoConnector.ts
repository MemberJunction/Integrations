import { RegisterClass } from '@memberjunction/global';
import { BaseIntegrationConnector } from '@memberjunction/integration-engine';
import { BaseDocumentDataSourceConnector } from '@memberjunction/integration-connectors';
// Side-effect import: registers the MongoDB EDS driver ('MongoExternalDriver') with the MJGlobal
// ClassFactory so this connector can resolve it at runtime via ExternalDataSourceRouter.
import '@memberjunction/external-data-source-mongodb';

/**
 * MongoDB ingestion connector — a **thin nominal leaf**. It carries no logic: all
 * connect / introspect / read is delegated to the shared EDS MongoDB driver ('MongoExternalDriver'),
 * and incremental sync + record assembly live in {@link BaseDocumentDataSourceConnector}. The connection binds to a
 * shared `MJ: External Data Sources` row via `CompanyIntegration.Configuration.externalDataSourceID`
 * (credentials + host on that EDS row, via CredentialEngine). Exists so MongoDB is a first-class,
 * discoverable Integration consistent with every other connector.
 *
 * Requires @memberjunction/* >= 5.46.0 (the EDS-consuming connector heart + the MongoExternalDriver driver).
 */
// Primary key follows the catalog convention (className == npm package name;
// see scripts/build-connectors-catalog.mjs) — instance discovery reports the
// package name, so the legacy bare key never matched in the catalog. The
// legacy alias stays registered so pre-migration tenant Integration rows
// keep resolving.
@RegisterClass(BaseIntegrationConnector, '@memberjunction/connector-mongodb')
@RegisterClass(BaseIntegrationConnector, 'MongoConnector')
export class MongoConnector extends BaseDocumentDataSourceConnector {
    public override get IntegrationName(): string {
        return 'MongoDB';
    }
}
