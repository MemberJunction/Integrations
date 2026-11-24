export * from './SlayteConnector.js';

/**
 * Open App bootstrap entry: importing this module executes the connector's
 * `@RegisterClass` decorators; this no-op satisfies the loader's required
 * `startupExport` and ensures the module is retained at MJAPI boot.
 */
export function registerConnector(): void { /* registration happened on import */ }
