import type { SourceFieldInfo, ExternalFieldSchema } from '@memberjunction/integration-engine';

/**
 * Standard varchar width tiers used to give a MEASURED width headroom.
 *
 * Why headroom: MJ's sampler reads a BOUNDED number of rows, so the max length it
 * observes is a FLOOR, not the truth — the single longest value can easily be
 * outside the sample. Sizing a column to the exact observed max therefore skips
 * any later record that's even one char longer (this is the class that dropped 99
 * PheedLoop members: `about` measured 2348, a real bio was 2595 → skipped). Round
 * a measured width UP to the next tier so an unsampled slightly-longer value fits.
 * Above the top tier the field is genuinely large — keep the measured value.
 */
const WIDTH_TIERS = [32, 64, 128, 256, 512, 1024, 2048, 4000] as const;
function withHeadroom(measured: number | null | undefined): number {
    const w = measured ?? 0;
    if (w <= 0) return 0;
    for (const tier of WIDTH_TIERS) if (w <= tier) return tier;
    return w;
}

/**
 * `mergeDeclaredWithSampledFields` — unions a connector's DECLARED field list with the fields MJ's OWN
 * sampler (`DiscoverFieldsViaFetch`) measured. MJ did the measuring, type inference, and PK statistics;
 * MJ's Persist/reconcile owns width-shrink protection and PK preservation at persist time. This helper:
 *
 *   - unions the two arrays BY FIELD NAME;
 *   - for a name in BOTH: keeps the DECLARED field UNCHANGED except its `MaxLength`, which NEVER shrinks.
 *     When the DECLARED width is the larger (a real describe-API width, e.g. Salesforce/Fonteva) it is
 *     kept EXACTLY — declared widths are authoritative and are never inflated. When the MEASURED width
 *     is larger, the sample is driving the size and may have missed the tail, so it is rounded UP for
 *     headroom (`withHeadroom`) — never below the declared width;
 *   - for a name ONLY in the sample: appends it as a custom column MJ discovered, with MJ's own type /
 *     PK-stats and a headroom'd measured width, mapped onto the `SourceFieldInfo` shape.
 *
 * Declared order is preserved; custom columns are appended in sample order.
 *
 * @param declared  Declared fields for one object (`SourceObjectInfo.Fields` from `super.IntrospectSchema`).
 * @param sampled   MJ-measured fields for the same object (`DiscoverFieldsViaFetch` → `ExternalFieldSchema[]`).
 */
export function mergeDeclaredWithSampledFields(
    declared: SourceFieldInfo[],
    sampled: ExternalFieldSchema[],
): SourceFieldInfo[] {
    const declaredList = declared ?? [];
    const sampledList = sampled ?? [];

    const sampledByName = new Map<string, ExternalFieldSchema>();
    for (const s of sampledList) {
        if (s?.Name && !sampledByName.has(s.Name)) sampledByName.set(s.Name, s);
    }
    const declaredNames = new Set(declaredList.map((f) => f.Name));

    // Declared fields, in declared order — widen MaxLength to the never-shrink max(declared, measured);
    // nothing else changes. max() only ever grows the width, so a real declared width is never truncated.
    const merged: SourceFieldInfo[] = declaredList.map((d) => {
        const s = sampledByName.get(d.Name);
        if (!s) return d;
        const declaredW = d.MaxLength ?? 0;
        const sampledW = s.MaxLength ?? 0;
        // Never shrink. Declared wins when it's the larger (authoritative describe-API width — kept
        // exactly, no headroom). When the MEASURED width exceeds declared, the sample is driving the
        // size and may have missed the tail, so round it UP for headroom.
        const nextMaxLength =
            sampledW > declaredW
                ? withHeadroom(sampledW)
                : declaredW > 0
                  ? declaredW
                  : (sampledW > 0 ? sampledW : (d.MaxLength ?? null));
        if (nextMaxLength === d.MaxLength) return d;
        return { ...d, MaxLength: nextMaxLength };
    });

    // Custom columns MJ discovered (sample-only names) — appended as-is, in sample order.
    const appended = new Set<string>();
    for (const s of sampledList) {
        if (!s?.Name || declaredNames.has(s.Name) || appended.has(s.Name)) continue;
        appended.add(s.Name);
        merged.push(sampledFieldToDeclared(s));
    }

    return merged;
}

/** Maps a sampled `ExternalFieldSchema` onto the `SourceFieldInfo` shape, adopting MJ's values verbatim. */
function sampledFieldToDeclared(s: ExternalFieldSchema): SourceFieldInfo {
    return {
        Name: s.Name,
        Label: s.Label ?? s.Name,
        Description: s.Description,
        SourceType: s.DataType,
        IsRequired: s.IsRequired,
        AllowsNull: s.AllowsNull,
        // Custom column — purely measured, so give it headroom (a sample can miss the longest value).
        MaxLength: s.MaxLength != null && s.MaxLength > 0 ? withHeadroom(s.MaxLength) : (s.MaxLength ?? null),
        Precision: s.Precision ?? null,
        Scale: s.Scale ?? null,
        DefaultValue: s.DefaultValue ?? null,
        IsPrimaryKey: s.IsPrimaryKey ?? false,
        IsUniqueKey: s.IsUniqueKey,
        IsReadOnly: s.IsReadOnly,
        IsForeignKey: s.IsForeignKey ?? false,
        ForeignKeyTarget: s.ForeignKeyTarget ?? null,
    };
}
