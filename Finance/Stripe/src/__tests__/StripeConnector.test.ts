import { describe, it, expect } from 'vitest';
import type { IntegrationObjectInfo } from '@memberjunction/integration-engine';
import { StripeConnector } from '../StripeConnector.js';

describe('StripeConnector', () => {
  it('exposes the integration name', () => {
    expect(new StripeConnector().IntegrationName).toBe('stripe');
  });
});

/**
 * Stands in for a populated IntegrationEngineBase cache. Overriding the object source — rather than
 * stubbing the engine singleton — exercises the real base-class config assembly, which is what the
 * connector's override actually contributes to.
 */
class SeededStripeConnector extends StripeConnector {
  public override GetIntegrationObjects(): IntegrationObjectInfo[] {
    return [
      {
        Name: 'charge',
        DisplayName: 'Charge',
        Description: 'A Stripe charge.',
        SupportsWrite: true,
        Fields: [
          { Name: 'id', DisplayName: 'Id', Type: 'string', IsRequired: true, IsReadOnly: true, IsPrimaryKey: true },
          { Name: 'amount', DisplayName: 'Amount', Type: 'int', IsRequired: true, IsReadOnly: false, IsPrimaryKey: false },
        ],
      },
    ];
  }
}

/**
 * Action generation is what makes a connector reachable by an agent or a flow rather than only by a
 * sync. It was absent entirely until now: the base class returns an empty object list by default,
 * which makes GetActionGeneratorConfig() return null, which means zero Stripe Actions are ever
 * generated. These tests pin both halves of the fix.
 */
describe('action generation surface', () => {
  const connector = new StripeConnector();

  it('returns an empty catalog when the metadata cache is unseeded — never a baked list', () => {
    // The `catalog-in-code` defect: falling back to a hardcoded subset silently freezes the object
    // universe to whatever was fashionable when the list was written. Stripe declares 63 objects in
    // metadata; a baked fallback would quietly serve a handful and still look like it worked.
    const objects = connector.GetIntegrationObjects();
    expect(Array.isArray(objects)).toBe(true);
    expect(objects.length).toBe(0);
  });

  it('generates no config while the catalog is empty, rather than an empty-object config', () => {
    // A config with no objects would emit an Action category containing nothing.
    expect(connector.GetActionGeneratorConfig()).toBeNull();
  });

  it('produces a config carrying the objects once the catalog resolves', () => {
    const config = new SeededStripeConnector().GetActionGeneratorConfig();
    expect(config).not.toBeNull();
    expect(config?.IntegrationName).toBe('stripe');
    expect(config?.Objects).toHaveLength(1);
    expect(config?.Objects[0].Name).toBe('charge');
  });

  it('stamps the Stripe icon so generated Actions are identifiable in the UI', () => {
    expect(new SeededStripeConnector().GetActionGeneratorConfig()?.IconClass).toBe('fa-brands fa-stripe');
  });
});
