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
 *   - for a name in BOTH: keeps the DECLARED field UNCHANGED except its `MaxLength` (which NEVER shrinks)
 *     and — when the object declares NO primary key — its `IsPrimaryKey`, which adopts the sampled
 *     statistical PK (I1: otherwise a proven key is dropped and the object is skipped as keyless). Width:
 *     when the MEASURED width is larger the sample drives the size and is rounded UP for headroom; when
 *     DECLARED is larger it usually wins exactly (a real describe-API width, e.g. Salesforce/Fonteva),
 *     UNLESS the declared width sits below the sample's own headroom tier — a tight metadata guess that
 *     could still overflow — in which case it too is bumped to the sample's headroom tier (I2). Never
 *     below the declared width; a declared PK, when present, always wins;
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

    // I1 — does the object declare ANY primary key? If not, a statistically-proven sampled PK is the
    // only thing standing between this object and being dropped from sync as keyless, so we adopt it
    // below. If it DOES declare a PK, declared always wins — we never add a second PK or override one.
    const hasDeclaredPK = declaredList.some((f) => f.IsPrimaryKey === true);

    // Declared fields, in declared order — widen MaxLength to the never-shrink max(declared, measured)
    // and, when the object is otherwise keyless, adopt the sampled PK. Nothing else changes.
    const merged: SourceFieldInfo[] = declaredList.map((d) => {
        const s = sampledByName.get(d.Name);
        if (!s) return d;
        const declaredW = d.MaxLength ?? 0;
        const sampledW = s.MaxLength ?? 0;
        // Never shrink. When the MEASURED width exceeds declared, the sample is driving the size and may
        // have missed the tail → round UP for headroom. When declared is the larger, it USUALLY wins
        // exactly (a real describe-API width). BUT a metadata-GUESSED declared width can sit BELOW the
        // sample's own headroom tier — a sign the guess is tight and an unsampled longer value could
        // overflow (I2). In that case bump to the sample's headroom tier (never below declared); if
        // declared already clears the sample's headroom it is comfortably roomy → keep it exact.
        let nextMaxLength: number | null;
        if (sampledW > declaredW) {
            nextMaxLength = withHeadroom(sampledW);
        } else if (declaredW > 0) {
            const sampleHeadroom = withHeadroom(sampledW);
            nextMaxLength = sampleHeadroom > declaredW ? sampleHeadroom : declaredW;
        } else {
            nextMaxLength = sampledW > 0 ? sampledW : (d.MaxLength ?? null);
        }
        // I1 — carry the sampled statistical PK onto this declared field only when the object declares no
        // PK of its own. This is the sharpest fix: without it the sampled PK is lost (declared kept
        // unchanged except width) and an object with real columns but no declared key stays keyless and
        // never syncs. Declared PK, when present, always wins (guarded by hasDeclaredPK).
        const adoptSampledPK = !hasDeclaredPK && s.IsPrimaryKey === true;

        if (nextMaxLength === (d.MaxLength ?? null) && !adoptSampledPK) return d;
        return adoptSampledPK
            ? { ...d, MaxLength: nextMaxLength, IsPrimaryKey: true }
            : { ...d, MaxLength: nextMaxLength };
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
