import { describe, it, expect } from 'vitest';
import { MJGlobal } from '@memberjunction/global';
import { BaseIntegrationConnector } from '@memberjunction/integration-engine';
import { DynamicsDataverseConnector } from '@memberjunction/connector-microsoft-dynamics-365-dataverse';
import { ProtechConnector } from '../ProtechConnector.js';

describe('ProtechConnector', () => {
    it('exposes the integration name', () => {
        expect(new ProtechConnector().IntegrationName).toBe('Protech');
    });

    it('is a thin leaf over the Dataverse connector (inherits the full lifecycle surface)', () => {
        const connector = new ProtechConnector();
        expect(connector).toBeInstanceOf(DynamicsDataverseConnector);
        // The load-bearing inherited behaviors this leaf depends on:
        expect(connector.DiscoveryIsAuthoritative).toBe(true);
        expect(connector.SupportsCreate).toBe(true);
        expect(connector.SupportsUpdate).toBe(true);
        expect(connector.SupportsDelete).toBe(true);
        expect(connector.MonotonicWatermark).toBe(true);
    });

    it('registers under the catalog ClassName convention (className == npm package name)', () => {
        const instance = MJGlobal.Instance.ClassFactory.CreateInstance<BaseIntegrationConnector>(
            BaseIntegrationConnector,
            '@memberjunction/connector-protech'
        );
        expect(instance).toBeInstanceOf(ProtechConnector);
    });
});
