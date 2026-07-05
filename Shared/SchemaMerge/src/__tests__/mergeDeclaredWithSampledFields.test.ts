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
    it("adopts MJ's measured MaxLength for a field in both; keeps declared width when MJ measured none", () => {
        const d = [
            declared({ Name: 'name', MaxLength: 255 }),
            declared({ Name: 'code', MaxLength: 500 }),
        ];
        const s = [
            sampled({ Name: 'name', MaxLength: 4000 }),   // MJ measured a width -> adopt it verbatim
            sampled({ Name: 'code', MaxLength: null }),   // MJ measured nothing -> keep declared width
        ];
        const out = mergeDeclaredWithSampledFields(d, s);
        expect(out.find((f) => f.Name === 'name')!.MaxLength).toBe(4000);
        expect(out.find((f) => f.Name === 'code')!.MaxLength).toBe(500);
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
        expect(id.MaxLength).toBe(25);        // only the measured width is adopted
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
        expect(custom.MaxLength).toBe(1234);         // MJ's measured width verbatim
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
});
