/**
 * Projection of a GA4 report row into an `ExternalRecord`.
 *
 * Pure: row in, record out. This is where the two things GA4 does differently from a normal API get
 * handled — values are POSITIONAL rather than named, and everything, including counts, arrives as a
 * string.
 */
import { createHash } from 'node:crypto';
import type { ExternalRecord } from '@memberjunction/integration-engine';
import type { CatalogObject } from './GA4Objects.js';
import type { GA4Row } from './GA4Report.js';

/**
 * Upper bound for `ExternalID`.
 *
 * `CompanyIntegrationRecordMap.ExternalSystemRecordID` is `nvarchar(750)`. A key that overflows it
 * does not corrupt anything — the insert fails and the record is dead-lettered — but the row never
 * lands, silently, for as long as the offending value keeps appearing. Below this length the key is
 * the readable join; above it, {@link buildExternalID} substitutes a digest. The margin under 750 is
 * for the fallback prefix.
 */
export const MAX_EXTERNAL_ID_LENGTH = 700;

/** GA4's sentinel for rows collapsed together once a dimension exceeds its cardinality limit. */
export const OTHER_ROW_SENTINEL = '(other)';

/**
 * GA4's own literal for a dimension that has no value on a row. Used to fill empty primary-key
 * components — see `projectRow`. This is the vendor's spelling, not ours, so a consumer joining
 * these rows to anything else in GA4 sees the same token they would in the GA4 UI.
 */
export const GA4_UNSET_DIMENSION = '(not set)';

/**
 * Build the `ExternalID` from the declared key values.
 *
 * It must equal the key fields joined on '|' — that is what the engine's REST base class produces
 * and what a `--base` connector therefore has to reproduce by hand. A mismatch does not throw:
 * identity silently falls back to a content hash, and every run re-inserts every row.
 *
 * The digest fallback exists because two key components here are free text set by whoever built a
 * marketing link. `utm_campaign` and `utm_content` have no length limit, and a tracking template
 * that stuffs a few hundred characters into one is not exotic. Truncating would be the worse answer:
 * two distinct campaigns sharing a prefix would collapse into one row and silently merge their
 * numbers, which is a wrong answer rather than a missing one. The digest is deterministic, so the
 * same row keeps the same identity across runs, and the `ga4:` prefix makes an audit of the record
 * map able to tell the two forms apart.
 */
export function buildExternalID(keyValues: string[]): string {
    const joined = keyValues.join('|');
    if (joined.length <= MAX_EXTERNAL_ID_LENGTH) return joined;
    return `ga4:${createHash('sha256').update(joined, 'utf8').digest('hex')}`;
}

/**
 * GA4's `date` dimension is `YYYYMMDD` with no separators. Returns null for anything else — including
 * `(other)`, which GA4 can in principle substitute for any dimension.
 */
export function parseGA4Date(value: string): string | null {
    if (!/^\d{8}$/.test(value)) return null;
    const iso = `${value.slice(0, 4)}-${value.slice(4, 6)}-${value.slice(6, 8)}`;
    // Rejects 2026-02-31 and friends: Date.parse accepts them and rolls over, which would land a row
    // under a date GA4 never reported.
    const parsed = new Date(`${iso}T00:00:00Z`);
    return Number.isNaN(parsed.getTime()) || parsed.toISOString().slice(0, 10) !== iso ? null : iso;
}

/**
 * Parse a GA4 metric value.
 *
 * Every metric arrives as a string, including integers, and a metric that is genuinely absent for a
 * row arrives as `''` rather than being omitted. Absent stays null (the column is nullable and "no
 * data" is not the same claim as "zero"); anything present but unparseable becomes null too, rather
 * than a 0 that would read as a measured value.
 */
export function parseMetric(value: string | null | undefined): number | null {
    if (value === null || value === undefined || value === '') return null;
    const n = Number(value);
    return Number.isFinite(n) ? n : null;
}

/** Positional read of a nullable-everything array, flattened to a plain string. */
function valueAt(list: Array<{ value?: string | null } | null> | null | undefined, i: number): string {
    return list?.[i]?.value ?? '';
}

export interface ProjectedRow {
    Record: ExternalRecord;
    /** True when any dimension of this row is GA4's `(other)` aggregate. */
    IsOtherRow: boolean;
}

/**
 * Project one report row.
 *
 * Returns null when the row cannot be keyed — in practice only when `date` is not a real date, which
 * means GA4 substituted a sentinel for it. A row with no usable key cannot be upserted, and emitting
 * it with a made-up key would create a row that is re-inserted on every run forever.
 *
 * `dimensionValues` and `metricValues` are aligned by POSITION to the request's `dimensions` and
 * `metrics`, not by name — GA4 sends the names once in the headers and never again. The catalog's
 * `Dimensions`/`Metrics` arrays are the request order, so they are also the read order, and that
 * single fact is why those arrays live next to the field list rather than being derived from it.
 */
export function projectRow(obj: CatalogObject, row: GA4Row, propertyId: string): ProjectedRow | null {
    const fields: Record<string, unknown> = {};
    let isOtherRow = false;

    for (let i = 0; i < obj.Dimensions.length; i++) {
        const name = obj.Dimensions[i];
        const raw = valueAt(row.dimensionValues, i);
        if (raw === OTHER_ROW_SENTINEL) isOtherRow = true;

        if (name === 'date') {
            const iso = parseGA4Date(raw);
            if (iso === null) return null;
            fields.date = iso;
        } else {
            fields[name] = raw;
        }
    }

    for (let i = 0; i < obj.Metrics.length; i++) {
        fields[obj.Metrics[i]] = parseMetric(valueAt(row.metricValues, i));
    }

    fields.propertyId = propertyId;

    // A primary-key component must never be empty. GA4 reports untagged traffic with an empty
    // `sessionCampaignName` / `sessionMedium` (direct visits, email-signature links, anything with
    // no UTM tagging), and an empty component does not survive the write: MJ's generated
    // `spCreate` inserts the row and then re-selects it by primary key, an empty string is stored
    // as NULL for a nullable column, and `= NULL` matches nothing — so the create comes back as
    // "no rows returned from SQL" and the row is dropped. GA4's own convention for a dimension
    // with no value is the literal `(not set)`, so use that rather than inventing a sentinel.
    for (const f of obj.Fields) {
        if (f.IsPrimaryKey && f.Name !== 'date' && fields[f.Name] === '') {
            fields[f.Name] = GA4_UNSET_DIMENSION;
        }
    }

    const keyValues = obj.Fields.filter((f) => f.IsPrimaryKey).map((f) => String(fields[f.Name] ?? ''));

    return {
        Record: {
            ExternalID: buildExternalID(keyValues),
            ObjectType: obj.Name,
            Fields: fields,
        },
        IsOtherRow: isOtherRow,
    };
}
