import { describe, it, expect } from 'vitest';
import { HigherLogicVanillaConnector } from '../HigherLogicVanillaConnector.js';

describe('HigherLogicVanillaConnector', () => {
  it('exposes the integration name', () => {
    expect(new HigherLogicVanillaConnector().IntegrationName).toBe('Higher Logic Vanilla');
  });
});
