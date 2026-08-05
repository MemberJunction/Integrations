import { describe, it, expect } from 'vitest';
import { RasaConnector } from './RasaConnector';

/**
 * Regression guard for DEFECT-12 — the sample-union race.
 *
 * `FetchChanges` publishes its per-object response context onto INSTANCE state (`responseCtx`,
 * `currentWatermark`, `pendingWarnings`) and reads it back AFTER the HTTP round-trip. When
 * `IntrospectSchema` sampled the catalog with `Promise.all`, every concurrent call overwrote
 * `responseCtx`, so each response was normalized against some other object's `DataPath`, matched
 * nothing, and returned ZERO records — cleanly, no throw, no warning. Live evidence: 17 of the 18
 * objects that reached the sampler logged `rows=0 | cols: []`; the resulting all-null field widths
 * are what let the framework's unknown-width default drop 8,841 records.
 *
 * These tests pin the two properties that make the enrichment sound, without any network:
 *   1. objects are sampled STRICTLY SEQUENTIALLY (max concurrent FetchChanges === 1);
 *   2. a per-object failure is REPORTED, not swallowed by a bare `catch {}`, and does not abort
 *      the remaining objects.
 */
describe('RasaConnector.IntrospectSchema sample-union', () => {
    /** Builds a connector whose super-call and sampler are stubbed, recording sampling concurrency. */
    function makeHarness(sampleImpl: (name: string) => Promise<unknown>) {
        const objects = ['Person', 'Post', 'Community', 'Insight Topic', 'Content Pool Item'];
        let inFlight = 0;
        let maxInFlight = 0;
        const order: string[] = [];

        const connector = new RasaConnector();
        const proto = Object.getPrototypeOf(Object.getPrototypeOf(connector));

        // Stub the base introspection so no cache/DB/network is needed.
        proto.IntrospectSchema = async () => ({
            Objects: objects.map(name => ({ Name: name, ExternalName: name, Fields: [] })),
        });

        // Stub the sampler, instrumented to observe overlap.
        (connector as unknown as Record<string, unknown>).DiscoverFieldsViaFetch = async (
            _ci: unknown,
            name: string,
        ) => {
            order.push(name);
            maxInFlight = Math.max(maxInFlight, ++inFlight);
            try {
                return await sampleImpl(name);
            } finally {
                inFlight--;
            }
        };

        return { connector, objects, order, maxInFlight: () => maxInFlight };
    }

    const ci = {} as never;
    const user = {} as never;

    it('samples objects strictly sequentially — never overlapping FetchChanges', async () => {
        const h = makeHarness(async () => {
            // Yield to the event loop; under Promise.all this is where the overlap appeared.
            await new Promise(resolve => setTimeout(resolve, 1));
            return [];
        });

        await h.connector.IntrospectSchema(ci, user);

        expect(h.maxInFlight()).toBe(1);
        expect(h.order).toEqual(h.objects);
    });

    it('reports a per-object sample failure instead of swallowing it, and keeps going', async () => {
        const warnings: string[] = [];
        const originalWarn = console.warn;
        console.warn = (msg?: unknown) => void warnings.push(String(msg));

        try {
            const h = makeHarness(async name => {
                if (name === 'Post') throw new Error('no read path');
                return [];
            });

            const info = await h.connector.IntrospectSchema(ci, user);

            // Every object was still attempted — one failure must not abort the catalog.
            expect(h.order).toEqual(h.objects);
            expect(info.Objects).toHaveLength(h.objects.length);
            // ...and the failure is visible, naming both the object and the cause.
            expect(warnings.some(w => w.includes('Post') && w.includes('no read path'))).toBe(true);
        } finally {
            console.warn = originalWarn;
        }
    });
});
