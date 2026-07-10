export * from './PostgresConnector.js';

/** Open App bootstrap entry: importing this module ran the connector's @RegisterClass decorator (and the
 *  EDS driver's, via the side-effect import); this no-op satisfies the loader's required startupExport
 *  and forces the import at MJAPI boot. */
export function registerConnector(): void { /* registration happened on import */ }
