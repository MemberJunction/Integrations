import { describe, it, expect } from 'vitest';
import { TotaraConnector } from '../TotaraConnector.js';

describe('TotaraConnector', () => {
  it('exposes the integration name', () => {
    expect(new TotaraConnector().IntegrationName).toBe('Totara');
  });
});
