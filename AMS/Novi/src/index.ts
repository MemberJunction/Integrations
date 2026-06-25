export * from './NoviConnector.js';

/** Open App bootstrap entry: importing this module ran the connector's @RegisterClass decorator;
 *  this no-op satisfies the loader's required startupExport and forces the import at MJAPI boot. */
export function registerConnector(): void { /* registration happened on import */ }
