import { describe, it, expect } from 'vitest';
import type { SourceFieldInfo, ExternalFieldSchema } from '@memberjunction/integration-engine';
import { mergeDeclaredWithSampledFields } from '../index.js';

/** Minimal declared-field factory (all required SourceFieldInfo props). */
function declared(partial: Partial<SourceFieldInfo> & { Name: string }): SourceFieldInfo {
    return {
        Label: partial.Name,
        SourceType: 'string',
        IsRequired: false,
        MaxLength: null,
        Precision: null,
        Scale: null,
        DefaultValue: null,
        IsPrimaryKey: false,
        IsForeignKey: false,
        ForeignKeyTarget: null,
        ...partial,
    };
}

/** Minimal sampled-field factory (ExternalFieldSchema, as MJ's DiscoverFieldsViaFetch returns it). */
function sampled(partial: Partial<ExternalFieldSchema> & { Name: string }): ExternalFieldSchema {
    return {
        Label: partial.Name,
        DataType: 'string',
        IsRequired: false,
        IsUniqueKey: false,
        IsReadOnly: true,
        ...partial,
    };
}

describe('mergeDeclaredWithSampledFields (pure glue — adopts MJ values, no logic)', () => {
    it('widens MaxLength to the never-shrink max(declared, measured) and never truncates a real declared width', () => {
        const d = [
            declared({ Name: 'name', MaxLength: 255 }),   // sample is wider  -> widen to sample
            declared({ Name: 'code', MaxLength: 500 }),   // sample is narrower -> NEVER shrink, keep declared
            declared({ Name: 'note', MaxLength: null }),  // declared has none -> adopt measured
        ];
        const s = [
            sampled({ Name: 'name', MaxLength: 4000 }),
            sampled({ Name: 'code', MaxLength: 128 }),
            sampled({ Name: 'note', MaxLength: 900 }),
        ];
        const out = mergeDeclaredWithSampledFields(d, s);
        expect(out.find((f) => f.Name === 'name')!.MaxLength).toBe(4000); // measured>declared → headroom (4000 tier)
        expect(out.find((f) => f.Name === 'code')!.MaxLength).toBe(500);  // declared>measured → kept EXACTLY, no headroom
        expect(out.find((f) => f.Name === 'note')!.MaxLength).toBe(1024); // measured 900 → next tier (headroom vs the tail)
    });

    it('gives a MEASURED width headroom (buckets up) but keeps a DECLARED width exact', () => {
        // The regression that skipped 99 PheedLoop members: `about` measured 2348, a real bio was 2595.
        const d = [
            declared({ Name: 'about', MaxLength: null }),  // no declared width → sample drives → bucket up
            declared({ Name: 'sfField', MaxLength: 255 }), // real describe-API width, sample smaller → kept EXACT
        ];
        const s = [
            sampled({ Name: 'about', MaxLength: 2348 }),
            sampled({ Name: 'sfField', MaxLength: 100 }),
        ];
        const out = mergeDeclaredWithSampledFields(d, s);
        expect(out.find((f) => f.Name === 'about')!.MaxLength).toBe(4000); // 2348 → 4000, so a 2595 value fits
        expect(out.find((f) => f.Name === 'sfField')!.MaxLength).toBe(255); // declared authoritative, NOT inflated
    });

    it('keeps the declared width when MJ measured none, and null when neither side has one', () => {
        const d = [
            declared({ Name: 'code', MaxLength: 500 }),
            declared({ Name: 'flag', MaxLength: null }),
        ];
        const s = [
            sampled({ Name: 'code', MaxLength: null }),   // MJ measured nothing -> keep declared width
            sampled({ Name: 'flag', MaxLength: null }),   // neither side -> stays null
        ];
        const out = mergeDeclaredWithSampledFields(d, s);
        expect(out.find((f) => f.Name === 'code')!.MaxLength).toBe(500);
        expect(out.find((f) => f.Name === 'flag')!.MaxLength).toBeNull();
    });

    it('leaves a matched declared field otherwise UNCHANGED (no type/semantics/PK logic)', () => {
        const d = [declared({ Name: 'id', SourceType: 'decimal', IsRequired: true, IsReadOnly: true, IsPrimaryKey: true, MaxLength: 18 })];
        // The sample disagrees on type/required/readonly/PK — all of that must be ignored (MJ's Persist owns it).
        const s = [sampled({ Name: 'id', DataType: 'string', IsRequired: false, IsReadOnly: false, IsPrimaryKey: false, MaxLength: 25 })];
        const out = mergeDeclaredWithSampledFields(d, s);
        const id = out.find((f) => f.Name === 'id')!;
        expect(id.SourceType).toBe('decimal');
        expect(id.IsRequired).toBe(true);
        expect(id.IsReadOnly).toBe(true);
        expect(id.IsPrimaryKey).toBe(true);  // declared PK untouched — helper does no PK logic
        expect(id.MaxLength).toBe(32);       // measured 25 → next tier (headroom)
    });

    it('appends a sample-only field as a custom column, adopting MJ type/width/PK verbatim', () => {
        const d = [declared({ Name: 'id', IsPrimaryKey: true })];
        const s = [
            sampled({ Name: 'id' }),
            sampled({ Name: 'x_custom', DataType: 'text', MaxLength: 1234, IsPrimaryKey: true, IsReadOnly: true }),
        ];
        const out = mergeDeclaredWithSampledFields(d, s);
        const custom = out.find((f) => f.Name === 'x_custom')!;
        expect(custom).toBeDefined();
        expect(custom.SourceType).toBe('text');     // MJ's type verbatim
        expect(custom.MaxLength).toBe(2048);        // measured 1234 → next tier (headroom)
        expect(custom.IsPrimaryKey).toBe(true);      // MJ's PK-stat verbatim
        expect(custom.IsReadOnly).toBe(true);
    });

    it('is deterministic: declared order preserved, custom columns appended in sample order (dedup)', () => {
        const d = [declared({ Name: 'a' }), declared({ Name: 'b' })];
        const s = [
            sampled({ Name: 'b' }),
            sampled({ Name: 'z_custom' }),
            sampled({ Name: 'a' }),
            sampled({ Name: 'm_custom' }),
            sampled({ Name: 'z_custom' }), // duplicate sample-only -> appended once
        ];
        const out = mergeDeclaredWithSampledFields(d, s).map((f) => f.Name);
        expect(out).toEqual(['a', 'b', 'z_custom', 'm_custom']);
    });

    it('handles empty inputs safely', () => {
        expect(mergeDeclaredWithSampledFields([], [])).toEqual([]);
        const d = [declared({ Name: 'only' })];
        expect(mergeDeclaredWithSampledFields(d, []).map((f) => f.Name)).toEqual(['only']);
    });

    // ── I1 — carry the sampled statistical PK onto an otherwise-keyless object (the sharpest fix) ──
    describe('I1 — adopts the sampled PK when the object declares none (else keyless → never syncs)', () => {
        it('carries a proven sampled PK onto a declared field when NO field declares a PK', () => {
            const d = [declared({ Name: 'email', MaxLength: 255 }), declared({ Name: 'name', MaxLength: 255 })];
            const s = [sampled({ Name: 'email', IsPrimaryKey: true }), sampled({ Name: 'name' })];
            const out = mergeDeclaredWithSampledFields(d, s);
            expect(out.find((f) => f.Name === 'email')!.IsPrimaryKey).toBe(true);  // proven key adopted → object can sync
            expect(out.find((f) => f.Name === 'name')!.IsPrimaryKey).toBe(false);
        });

        it('never overrides or duplicates a real declared PK — declared always wins', () => {
            const d = [declared({ Name: 'id', IsPrimaryKey: true, MaxLength: 18 }), declared({ Name: 'email', MaxLength: 255 })];
            // sample thinks email is unique too, but the object already has a declared PK → no adoption.
            const s = [sampled({ Name: 'id', IsPrimaryKey: true }), sampled({ Name: 'email', IsPrimaryKey: true })];
            const out = mergeDeclaredWithSampledFields(d, s);
            expect(out.find((f) => f.Name === 'id')!.IsPrimaryKey).toBe(true);
            expect(out.find((f) => f.Name === 'email')!.IsPrimaryKey).toBe(false);
        });

        it('adopts a sampled COMPOSITE PK across multiple declared fields on a keyless object', () => {
            const d = [declared({ Name: 'org_id' }), declared({ Name: 'user_id' }), declared({ Name: 'role' })];
            const s = [sampled({ Name: 'org_id', IsPrimaryKey: true }), sampled({ Name: 'user_id', IsPrimaryKey: true }), sampled({ Name: 'role' })];
            const out = mergeDeclaredWithSampledFields(d, s);
            expect(out.filter((f) => f.IsPrimaryKey).map((f) => f.Name)).toEqual(['org_id', 'user_id']);
        });
    });

    // ── I2 — headroom for a TIGHT declared guess (a declared width below the sample's own headroom tier) ──
    describe('I2 — bumps a tight declared width guess to the sample headroom tier (roomy declared kept exact)', () => {
        it('bumps a declared width sitting below the sample headroom tier; keeps a comfortably-roomy one exact', () => {
            const d = [
                declared({ Name: 'title', MaxLength: 100 }), // guess 100, sample 90 → headroom(90)=128 > 100 → TIGHT → bump
                declared({ Name: 'sku', MaxLength: 256 }),   // sample 90 → headroom 128 ≤ 256 → roomy → keep exact
            ];
            const s = [sampled({ Name: 'title', MaxLength: 90 }), sampled({ Name: 'sku', MaxLength: 90 })];
            const out = mergeDeclaredWithSampledFields(d, s);
            expect(out.find((f) => f.Name === 'title')!.MaxLength).toBe(128);
            expect(out.find((f) => f.Name === 'sku')!.MaxLength).toBe(256);
        });

        it('the I2 bump never shrinks — result is always >= the declared width', () => {
            const d = [declared({ Name: 'c', MaxLength: 60 })];   // sample 50 → headroom(50)=64 > 60 → bump to 64
            const s = [sampled({ Name: 'c', MaxLength: 50 })];
            expect(mergeDeclaredWithSampledFields(d, s)[0].MaxLength).toBe(64);
        });
    });
});
