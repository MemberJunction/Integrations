import { describe, it, expect } from 'vitest';
import { canonicalJSON } from '../WildApricotConnector.js';

describe('canonicalJSON — the identity replacer fix', () => {
    it('distinguishes values that differ ONLY below the top level', () => {
        // `JSON.stringify(v, Object.keys(v).sort())` passes the top-level keys as a REPLACER, and an
        // array replacer is an allow-list applied at EVERY level — so both of these serialised to
        // {"meta":{}} and hashed identically. PropFuel stored 181 of ~2,400 records this way.
        const a = { id: 1, meta: { stage: 'submitted', score: 4 } };
        const b = { id: 1, meta: { stage: 'withdrawn', score: 9 } };
        expect(canonicalJSON(a)).not.toBe(canonicalJSON(b));
        expect(JSON.stringify(a, Object.keys(a).sort())).toBe(JSON.stringify(b, Object.keys(b).sort()));
    });

    it('is insensitive to key order at every level', () => {
        expect(canonicalJSON({ b: 1, a: { d: 2, c: 3 } })).toBe(canonicalJSON({ a: { c: 3, d: 2 }, b: 1 }));
    });

    it('keeps array order, which is semantically meaningful', () => {
        expect(canonicalJSON({ xs: [1, 2] })).not.toBe(canonicalJSON({ xs: [2, 1] }));
    });

    it('omits undefined and serialises null, dates and primitives stably', () => {
        expect(canonicalJSON({ a: 1, b: undefined })).toBe(canonicalJSON({ a: 1 }));
        expect(canonicalJSON({ a: null })).toBe('{"a":null}');
        expect(canonicalJSON(new Date('2026-01-02T03:04:05.000Z'))).toBe('"2026-01-02T03:04:05.000Z"');
    });

    it('does not confuse nested emptiness with a missing branch', () => {
        expect(canonicalJSON({ meta: {} })).not.toBe(canonicalJSON({ meta: { a: 1 } }));
    });
});
