import { defineConfig } from 'vitest/config';

export default defineConfig({
    test: {
        environment: 'node',
        testTimeout: 60000,
        include: ['src/**/*.test.ts'],
        // The template-child tests answer the base class's parent-ID lookup with an in-memory RunView
        // (vi.mock('@memberjunction/core')). The engine is an installed npm package here, which vitest
        // externalizes by default, so it would bypass that mock; inlining it lets the mock reach the
        // engine's own RunView import.
        server: { deps: { inline: ['@memberjunction/integration-engine'] } },
    },
});
