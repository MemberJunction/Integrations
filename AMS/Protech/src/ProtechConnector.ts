import { RegisterClass } from '@memberjunction/global';
import { BaseIntegrationConnector } from '@memberjunction/integration-engine';
import { DynamicsDataverseConnector } from '@memberjunction/connector-microsoft-dynamics-365-dataverse';

/**
 * Protech AMS (UX 365) connector — a **thin nominal leaf** over the generic
 * Microsoft Dynamics 365 (Dataverse) connector. Protech is a managed solution
 * installed INSIDE a customer's Dynamics 365 / Dataverse environment (solutions
 * ProtechCustomization / ProtechPlugins / ProtechServiceEndPoints, publisher
 * prefix `pa_`), so every mechanism — Entra ID client-credentials auth, runtime
 * EntityDefinitions discovery, change-tracking incremental, OData CRUD — is
 * inherited verbatim from {@link DynamicsDataverseConnector}. Discovery is
 * authoritative: the `pa_*` custom tables surface alongside the standard CE
 * tables through the same EntityDefinitions endpoint, so no Protech-specific
 * catalog is declared here. This leaf exists so Protech is a first-class,
 * discoverable Integration with its own identity, credential guidance, and
 * docs — the same pattern as AMS/Fonteva over CRM/Salesforce.
 */
@RegisterClass(BaseIntegrationConnector, '@memberjunction/connector-protech')
export class ProtechConnector extends DynamicsDataverseConnector {
    public override get IntegrationName(): string { return 'Protech'; }
}
