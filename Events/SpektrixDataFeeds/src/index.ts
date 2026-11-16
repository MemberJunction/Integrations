export * from './SpektrixDataFeedsConnector.js';
export * from './catalog.js';
export * from './config.js';
export * from './watermark.js';
export * from './datafeeds/types.js';
export * from './datafeeds/clientRegistry.js';
export * from './datafeeds/nrbf.js';
export * from './datafeeds/wcfClient.js';
export * from './pii/policy.js';
export * from './pii/pseudonymizer.js';
export * from './pii/anonymize.js';

import { GetSpektrixDataFeedClientFactory, RegisterSpektrixDataFeedClientFactory } from './datafeeds/clientRegistry.js';
import { SpektrixWcfDataFeedClient } from './datafeeds/wcfClient.js';

/** Open App bootstrap entry: importing this module ran the connector's @RegisterClass decorator
 *  and registers the default Node SOAP/MTOM + MS-NRBF client factory when the host hasn't supplied one. */
export function registerConnector(): void {
    if (!GetSpektrixDataFeedClientFactory()) {
        RegisterSpektrixDataFeedClientFactory((options) => new SpektrixWcfDataFeedClient(options));
    }
}
