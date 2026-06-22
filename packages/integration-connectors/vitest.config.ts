import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    testTimeout: 60000,
    // The live e2e harness is credential/DB-gated and not part of the credential-free
    // unit run; it self-skips via db-availability when no DB is configured.
    include: ['src/**/*.test.ts'],
  },
});
