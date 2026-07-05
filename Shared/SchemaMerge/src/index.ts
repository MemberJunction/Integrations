import type { SourceFieldInfo, ExternalFieldSchema } from '@memberjunction/integration-engine';

/**
 * `mergeDeclaredWithSampledFields` — thin GLUE that unions a connector's DECLARED field list with the
 * fields MJ's OWN sampler (`DiscoverFieldsViaFetch`) already measured. It introduces NO logic of its
 * own. MJ did the measuring, the type inference, and the PK statistics; MJ's Persist/reconcile overlay
 * owns width-shrink protection and PK preservation at persist time. This helper ONLY:
 *
 *   - unions the two arrays BY FIELD NAME;
 *   - for a name in BOTH: keeps the DECLARED field object UNCHANGED except widening `MaxLength` to the
 *     NEVER-SHRINK maximum of the declared and measured widths — `max(declared ?? 0, sampled ?? 0)`,
 *     falling back to whichever is non-null when that max is 0/nullish. This only ever WIDENS: some
 *     connectors (Salesforce/Fonteva) carry REAL declared widths from their describe API, so blindly
 *     adopting the sample could shrink below the real width and truncate — max() is safe on every
 *     connector. No other width math, no PK logic, no type inference — MJ owns all of it;
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

    // Declared fields, in declared order — widen MaxLength to the never-shrink max(declared, measured);
    // nothing else changes. max() only ever grows the width, so a real declared width is never truncated.
    const merged: SourceFieldInfo[] = declaredList.map((d) => {
        const s = sampledByName.get(d.Name);
        if (!s) return d;
        const widened = Math.max(d.MaxLength ?? 0, s.MaxLength ?? 0);
        // If neither side carried a width the max is 0 — keep whatever was non-null (declared wins the tie).
        const nextMaxLength = widened > 0 ? widened : (d.MaxLength ?? s.MaxLength ?? null);
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
