export * from './SpektrixDataFeedsConnector.js';
export * from './catalog.js';
export * from './config.js';
export * from './watermark.js';
export * from './datafeeds/types.js';
export * from './datafeeds/clientRegistry.js';
export * from './pii/policy.js';
export * from './pii/pseudonymizer.js';
export * from './pii/anonymize.js';

/** Open App bootstrap entry: importing this module ran the connector's @RegisterClass decorator;
 *  this no-op satisfies the loader's required startupExport and forces the import at MJAPI boot. */
export function registerConnector(): void { /* registration happened on import */ }
