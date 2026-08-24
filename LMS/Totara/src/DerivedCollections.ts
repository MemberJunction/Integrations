/**
 * Derived collections — expanding a parent object's embedded JSON arrays into
 * first-class child objects, in the connector, on the engine versions tenants
 * actually run.
 *
 * Why this exists (profiled live, 2026-08-19): Totara's read functions return
 * nested arrays on their records — `Enrolled_Users.roles` / `.groups` (per-course
 * role and group membership), `Users.customfields` (EAV custom fields: name,
 * shortname, type, value), `Course_Contents.modules` (the modules of each course
 * section), `Cohort_Members.userids` (a scalar id array, up to 12,697 elements on
 * one row). With no way to express "this field is a collection", each landed as an
 * NVARCHAR(MAX) column of JSON text — present, but unqueryable.
 *
 * A derived object is declared in metadata like any other integration object, with
 * `Configuration.derivedCollection` naming the parent object and the array field.
 * The connector serves its FetchChanges by running the PARENT's fetch (same
 * pagination, same parent-scoping, same budgets — the parent cursor rides through
 * unchanged) and exploding each record's array into child records. Discovery
 * samples through the same path, so child fields are discovered from real
 * elements, and the ordinary schema-sync → table → entity-map flow does the rest.
 * No engine change is required anywhere.
 *
 * The element values themselves are carried into the child rows — this is
 * expansion, not exclusion. What we deliberately do NOT expand: parents that
 * embed a collection which already exists as its own synced object (Enrolled
 * Users' `enrolledcourses` re-derives Enrolled Users itself) — declaring a
 * derived object over one of those would duplicate a table we already have.
 */

import type { ExternalRecord } from '@memberjunction/integration-engine';

/** Parsed shape of `Configuration.derivedCollection` on a derived integration object. */
export interface DerivedCollectionConfig {
    /** Name of the parent integration object (its `IntegrationObject.Name`) whose fetch is reused. */
    parentObjectName: string;
    /** The array-valued field on parent records to explode. */
    collectionField: string;
    /**
     * Parent record fields carried onto every child row, renamed: parent field → child field
     * (e.g. `{"id": "userid", "courseid": "courseid"}`). Renaming is how the parent's `id`
     * avoids colliding with an element's own `id`.
     */
    parentKeyMap: Record<string, string>;
    /** 'object' — elements are objects whose keys become fields. 'scalar' — elements are bare values. */
    elementKind: 'object' | 'scalar';
    /** scalar only: the child field name that receives each element value. */
    scalarFieldName?: string;
    /**
     * object only, optional: element key renames (e.g. `{"id": "groupid"}` where the element's
     * `id` is the GROUP id and would otherwise read as ambiguous on the child row).
     */
    elementKeyMap?: Record<string, string>;
}

/** Result of an explode pass: the child records plus counts for the run log. */
export interface ExplodeResult {
    ChildFields: Record<string, unknown>[];
    /** Parent records whose collection field was missing or not an array (absent ≠ empty). */
    ParentsWithoutCollection: number;
    /** Total elements skipped because their kind did not match the declaration. */
    ElementsSkipped: number;
    /** Elements dropped as exact repeats of a row already produced — see ExplodeCollection. */
    ElementsCollapsed: number;
}

/**
 * Parses and validates `Configuration.derivedCollection`. Returns null when absent;
 * throws on a malformed declaration — a half-configured derived object must fail its
 * sync loudly, not quietly emit zero records (the shape of bug that left objects
 * "enabled and empty" for weeks with nobody able to say why).
 */
export function ParseDerivedCollectionConfig(raw: unknown): DerivedCollectionConfig | null {
    if (raw == null) return null;
    if (typeof raw !== 'object' || Array.isArray(raw)) {
        throw new Error('derivedCollection must be an object');
    }
    const r = raw as Record<string, unknown>;
    const parentObjectName = typeof r.parentObjectName === 'string' ? r.parentObjectName.trim() : '';
    const collectionField = typeof r.collectionField === 'string' ? r.collectionField.trim() : '';
    if (!parentObjectName) throw new Error('derivedCollection.parentObjectName is required');
    if (!collectionField) throw new Error('derivedCollection.collectionField is required');

    const elementKind = r.elementKind === 'scalar' ? 'scalar' : r.elementKind === 'object' ? 'object' : null;
    if (!elementKind) throw new Error(`derivedCollection.elementKind must be 'object' or 'scalar'`);

    const parentKeyMap = asStringMap(r.parentKeyMap);
    if (!parentKeyMap || Object.keys(parentKeyMap).length === 0) {
        throw new Error('derivedCollection.parentKeyMap must map at least one parent field — child rows with no parent key are unjoinable');
    }
    const scalarFieldName = typeof r.scalarFieldName === 'string' ? r.scalarFieldName.trim() : '';
    if (elementKind === 'scalar' && !scalarFieldName) {
        throw new Error('derivedCollection.scalarFieldName is required when elementKind is scalar');
    }
    const elementKeyMap = asStringMap(r.elementKeyMap) ?? undefined;

    return {
        parentObjectName,
        collectionField,
        parentKeyMap,
        elementKind,
        scalarFieldName: scalarFieldName || undefined,
        elementKeyMap,
    };
}

function asStringMap(v: unknown): Record<string, string> | null {
    if (v == null || typeof v !== 'object' || Array.isArray(v)) return null;
    const out: Record<string, string> = {};
    for (const [k, val] of Object.entries(v as Record<string, unknown>)) {
        if (typeof val === 'string' && val.trim().length > 0) out[k] = val.trim();
    }
    return out;
}

/**
 * Explodes parent records' collection field into child field-bags. Pure — identity
 * (ExternalID) is stamped by the caller via the connector's ordinary
 * `buildExternalRecord`, so child identity follows the same declared-PK-else-hash
 * rule as every other object.
 *
 * An element that is null, or whose kind contradicts the declaration (a scalar in an
 * object collection, an object in a scalar one), is counted and skipped — one odd
 * element must not fail the page.
 */
export function ExplodeCollection(
    parentRecords: ReadonlyArray<ExternalRecord>,
    config: DerivedCollectionConfig,
): ExplodeResult {
    const out: Record<string, unknown>[] = [];
    const seen = new Set<string>();
    let parentsWithoutCollection = 0;
    let elementsSkipped = 0;
    let elementsCollapsed = 0;

    /** Byte-identical projection = one fact restated. Anything differing is kept. */
    const emit = (row: Record<string, unknown>): void => {
        const sig = JSON.stringify(row, Object.keys(row).sort());
        if (seen.has(sig)) { elementsCollapsed++; return; }
        seen.add(sig);
        out.push(row);
    };

    for (const parent of parentRecords) {
        const arr = parent.Fields?.[config.collectionField];
        if (!Array.isArray(arr)) {
            parentsWithoutCollection++;
            continue;
        }
        // Parent keys resolved once per parent, applied to every element.
        const parentKeys: Record<string, unknown> = {};
        for (const [pField, cField] of Object.entries(config.parentKeyMap)) {
            parentKeys[cField] = parent.Fields[pField];
        }
        for (const el of arr) {
            if (el == null) { elementsSkipped++; continue; }
            if (config.elementKind === 'scalar') {
                if (typeof el === 'object') { elementsSkipped++; continue; }
                emit({ ...parentKeys, [config.scalarFieldName as string]: el });
            } else {
                if (typeof el !== 'object' || Array.isArray(el)) { elementsSkipped++; continue; }
                const child: Record<string, unknown> = { ...parentKeys };
                for (const [k, v] of Object.entries(el as Record<string, unknown>)) {
                    const name = config.elementKeyMap?.[k] ?? k;
                    // Parent keys win a name collision: they are the join identity, and an
                    // element key that would shadow one is exactly why elementKeyMap exists.
                    if (name in parentKeys) { continue; }
                    child[name] = v;
                }
                emit(child);
            }
        }
    }
    return {
        ChildFields: out,
        ParentsWithoutCollection: parentsWithoutCollection,
        ElementsSkipped: elementsSkipped,
        ElementsCollapsed: elementsCollapsed,
    };
}

/**
 * Removes `Configuration.dropFields` keys from a raw source record before it is
 * shaped into an ExternalRecord.
 *
 * For vendor payload that is configuration, not data: Totara `preferences` is
 * Moodle UI widget state (file-picker recents, user-selector toggles — the same
 * nine keys on 100% of rows), `courseformatoptions` is course theming. Dropping at
 * the connector means the key never reaches discovery sampling (no column on fresh
 * installs) nor the record stream (existing columns simply stop being written) —
 * and, unlike deactivating a field map, it cannot be re-captured into
 * CustomOverflow, because the key is gone before the engine ever sees it.
 *
 * Returns the ORIGINAL object when nothing matches — the common path allocates nothing.
 */
export function DropConfiguredFields(
    raw: Record<string, unknown>,
    dropFields: ReadonlyArray<string> | null | undefined,
): Record<string, unknown> {
    if (!dropFields || dropFields.length === 0) return raw;
    let hit = false;
    for (const k of dropFields) {
        if (k in raw) { hit = true; break; }
    }
    if (!hit) return raw;
    const out: Record<string, unknown> = {};
    const drop = new Set(dropFields);
    for (const [k, v] of Object.entries(raw)) {
        if (!drop.has(k)) out[k] = v;
    }
    return out;
}
