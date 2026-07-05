import type { SourceFieldInfo, ExternalFieldSchema } from '@memberjunction/integration-engine';

/**
 * `mergeDeclaredWithSampledFields` — thin GLUE that unions a connector's DECLARED field list with the
 * fields MJ's OWN sampler (`DiscoverFieldsViaFetch`) already measured. It introduces NO logic of its
 * own. MJ did the measuring, the type inference, and the PK statistics; MJ's Persist/reconcile overlay
 * owns width-shrink protection and PK preservation at persist time. This helper ONLY:
 *
 *   - unions the two arrays BY FIELD NAME;
 *   - for a name in BOTH: keeps the DECLARED field object UNCHANGED except adopting MJ's measured
 *     `MaxLength` when the sample measured one (the declared catalog carries no real width). No width
 *     math, no max(), no shrink rules, no PK logic, no type inference — just adopt MJ's measured value;
 *   - for a name ONLY in the sample: appends it as-is — a custom column MJ discovered, with MJ's own
 *     type / width / PK-stats — mapped onto the `SourceFieldInfo` shape.
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

    // Declared fields, in declared order — adopt MJ's measured width when it measured one; nothing else changes.
    const merged: SourceFieldInfo[] = declaredList.map((d) => {
        const s = sampledByName.get(d.Name);
        if (!s || s.MaxLength == null) return d;
        return { ...d, MaxLength: s.MaxLength };
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
        MaxLength: s.MaxLength ?? null,
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
