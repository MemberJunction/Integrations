import type { DataFeedClientFactory } from './types.js';

/**
 * Where the host hands this connector a Data Feeds client implementation.
 *
 * The registry lives on `globalThis` under a symbol so a duplicated copy of this module (bundler
 * code-splitting, a nested node_modules) still sees the one registration — the same reason MJ's
 * singletons use a global object store rather than a static field.
 *
 * Host wiring (wherever the certificate lives — MJAPI, or a push shim at the certificate holder's site):
 * ```ts
 * import { SpektrixDataFeedClient } from '<the integrator-supplied data feeds client package>';
 * import { RegisterSpektrixDataFeedClientFactory } from '@memberjunction/connector-spektrix-data-feeds';
 * RegisterSpektrixDataFeedClientFactory((o) => new SpektrixDataFeedClient(o));
 * ```
 */
const REGISTRY_KEY = Symbol.for('@memberjunction/connector-spektrix-data-feeds/client-factory');

type RegistryHost = typeof globalThis & { [REGISTRY_KEY]?: DataFeedClientFactory };

export function RegisterSpektrixDataFeedClientFactory(factory: DataFeedClientFactory): void {
    (globalThis as RegistryHost)[REGISTRY_KEY] = factory;
}

export function GetSpektrixDataFeedClientFactory(): DataFeedClientFactory | undefined {
    return (globalThis as RegistryHost)[REGISTRY_KEY];
}

/** Test and shutdown hook. */
export function ClearSpektrixDataFeedClientFactory(): void {
    delete (globalThis as RegistryHost)[REGISTRY_KEY];
}

export const NO_CLIENT_REGISTERED_MESSAGE =
    'No Spektrix Data Feeds client is registered. The host must call RegisterSpektrixDataFeedClientFactory ' +
    'with the Spektrix Data Feeds client before this connection can be used.';
