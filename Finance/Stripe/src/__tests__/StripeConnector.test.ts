import { describe, it, expect } from 'vitest';
import { StripeConnector } from '../StripeConnector.js';

describe('StripeConnector', () => {
  it('exposes the integration name', () => {
    expect(new StripeConnector().IntegrationName).toBe('stripe');
  });
});
