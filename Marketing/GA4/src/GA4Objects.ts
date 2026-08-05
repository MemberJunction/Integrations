/**
 * The declared object/field catalog — the single source of truth for this connector's schema.
 *
 * WHY A TS CATALOG. This is a `--base` connector: the Data API has no "list my tables" surface to
 * introspect. A GA4 report is a request you compose, not a resource you discover, so the objects
 * below are *defined* reports — a chosen set of dimensions and metrics with a name — and
 * `DiscoverObjects`/`DiscoverFields` answer from this table. It also has to work BEFORE the
 * integration metadata is seeded, which is the state the connector is in at first setup.
 *
 * `scripts/gen-integration-metadata.mjs` projects this table into
 * `metadata/integration/.ga4.integration.json`, so this file is the authority and that JSON is a
 * build artifact. Maintaining both by hand is what makes the two drift silently: the created columns
 * stop matching the emitted records and the sync lands nulls rather than failing.
 *
 * ── WHY THREE OBJECTS AND NOT ONE ────────────────────────────────────────────────────────────────
 *
 * The three differ only in their dimension list, and it is tempting to ship the finest grain alone
 * and let consumers roll up. That would be wrong, and the reason is worth stating once here because
 * it is the single most consequential design fact in this connector:
 *
 *   **GA4's user metrics are cardinalities, and cardinalities are not additive.**
 *
 * `totalUsers` and `activeUsers` are counts of DISTINCT users, de-duplicated by GA4 at exactly the
 * grain you requested. One person who arrives twice in a day from two campaigns counts once in a
 * campaign-less report and once in EACH campaign row of a campaign-scoped one. So summing the
 * campaign rows does not give you the campaign-less answer — it gives you a number that is too big by
 * however much your audiences overlap, and nothing in the data says by how much.
 *
 * `sessions`, `engagedSessions`, `screenPageViews`, `keyEvents` and `userEngagementDuration` ARE
 * additive and could be rolled up. The user counts cannot be, ever. Since a rollup that is right for
 * five columns and quietly wrong for two is worse than no rollup at all, each grain that anyone
 * actually wants user counts at is asked of GA4 directly, as its own report.
 *
 * That is also why each object is its own `runReport` call rather than one call re-projected: the
 * de-duplication has to happen inside GA4, at the grain requested.
 *
 * ── WHAT IS DELIBERATELY NOT HERE ────────────────────────────────────────────────────────────────
 *
 * No ratio metrics (`bounceRate`, `engagementRate`, `sessionKeyEventRate`, …). Every one is a
 * quotient of two columns already present, so landing it adds a number that is correct only at the
 * exact grain it was fetched at and silently wrong the moment anyone groups the table — the same
 * non-additivity trap as above, but without the excuse of being un-derivable. Consumers divide.
 *
 * No `firstUser*` attribution dimensions. They attribute to the first touch EVER rather than to the
 * touch that drove the session, so mixing them into the same row as session-scoped metrics produces
 * a table where the dimensions and the numbers answer different questions.
 */
import type { IntegrationObjectInfo } from '@memberjunction/integration-engine';

/**
 * The complete set of type tokens the schema builder understands.
 *
 * `IntegrationObjectField.Type` is a plain `nvarchar(200)` with no check constraint, and an
 * unrecognized token does not error — it falls through to `NVARCHAR(MAX)`. This union is the schema
 * builder's TYPE_MAP key set, so an unsupported token is a compile error here instead of a silently
 * unbounded column at deploy time.
 */
export type CatalogType =
    | 'nvarchar' | 'string' | 'text' | 'integer' | 'bigint' | 'decimal'
    | 'boolean' | 'datetime' | 'date' | 'uuid' | 'json' | 'float' | 'time';

/** One IntegrationObjectField, with the five attributes `IntegrationFieldInfo` cannot express. */
export interface CatalogField {
    Name: string;
    DisplayName: string;
    Description: string;
    Type: CatalogType;
    Length?: number;
    Precision?: number;
    Scale?: number;
    IsPrimaryKey: boolean;
    IsUniqueKey: boolean;
    IsRequired: boolean;
    IsReadOnly: boolean;
    AllowsNull: boolean;
}

/** One IntegrationObject — here, one *defined report*. */
export interface CatalogObject {
    Name: string;
    DisplayName: string;
    Description: string;
    /**
     * `IntegrationObject.APIPath` is NOT NULL. Every object goes to the same `:runReport` endpoint
     * and differs only in its request body, so the path carries the object name as a fragment to
     * stay unique and to name what actually varies.
     */
    APIPath: string;
    Category: string;
    SupportsIncrementalSync: boolean;
    IncrementalWatermarkField: string | null;
    PaginationType: 'Cursor';
    /** GA4 API dimension names, in request order. Positionally aligned to `dimensionValues`. */
    Dimensions: string[];
    /** GA4 API metric names, in request order. Positionally aligned to `metricValues`. */
    Metrics: string[];
    Fields: CatalogField[];
}

// ── Field constructors ────────────────────────────────────────────────────────
// Everything here is read-only: a GA4 report is a computed answer, not a record you can write back.

const dimField = (
    Name: string,
    Description: string,
    Length: number,
    pk: boolean
): CatalogField => ({
    Name,
    DisplayName: Name,
    Description,
    Type: 'nvarchar',
    Length,
    IsPrimaryKey: pk,
    IsUniqueKey: false,
    IsRequired: pk,
    IsReadOnly: true,
    // Never null in practice: GA4 substitutes its own sentinels — '(not set)', '(direct)', '(none)'
    // — rather than omitting a dimension value. Declared NOT NULL for the key components so the
    // constraint states that, and nullable elsewhere so a future dimension that CAN be absent does
    // not need a schema change.
    AllowsNull: !pk,
});

/** A whole-number metric. GA4 returns every metric as a string; these parse as integers. */
const countField = (Name: string, Description: string): CatalogField => ({
    Name,
    DisplayName: Name,
    Description,
    Type: 'bigint',
    IsPrimaryKey: false,
    IsUniqueKey: false,
    IsRequired: false,
    IsReadOnly: true,
    AllowsNull: true,
});

/** A metric GA4 types as FLOAT. `keyEvents` is one — it is float-typed even though it counts. */
const rateField = (Name: string, Description: string): CatalogField => ({
    Name,
    DisplayName: Name,
    Description,
    Type: 'decimal',
    Precision: 18,
    Scale: 4,
    IsPrimaryKey: false,
    IsUniqueKey: false,
    IsRequired: false,
    IsReadOnly: true,
    AllowsNull: true,
});

// ── Shared field groups ───────────────────────────────────────────────────────

/**
 * The reporting day, as a real date rather than GA4's `YYYYMMDD` string.
 *
 * It is the first key component of every object because it is what makes these rows *records* at
 * all. A GA4 report aggregated over a range is a single answer that changes shape every time the
 * range moves; adding `date` to the dimensions turns it into one stable row per day, which is the
 * only form that can be upserted by key across runs.
 */
const DATE_FIELD = dimField(
    'date',
    'The reporting day in the property\'s configured reporting time zone. GA4 returns this as YYYYMMDD; it is normalized to a date here.',
    10,
    true
);

/**
 * Provenance, stamped by the connector rather than returned by GA4.
 *
 * Not part of the key: one CompanyIntegration row addresses exactly one property, so within a synced
 * table it is constant. It is carried anyway because the table outlives the configuration that
 * produced it, and "which property is this?" is otherwise unanswerable from the data.
 */
const PROPERTY_ID_FIELD: CatalogField = {
    Name: 'propertyId',
    DisplayName: 'propertyId',
    Description: 'The numeric GA4 property this row was read from. Stamped by the connector from Configuration.propertyId; GA4 does not return it.',
    Type: 'nvarchar',
    Length: 32,
    IsPrimaryKey: false,
    IsUniqueKey: false,
    IsRequired: false,
    IsReadOnly: true,
    AllowsNull: true,
};

/** The additive engagement counts, shared by all three reports. */
const ENGAGEMENT_METRIC_FIELDS: CatalogField[] = [
    countField('sessions', 'Sessions in this row\'s grain. Additive across rows.'),
    countField('engagedSessions', 'Sessions that lasted 10+ seconds, had a key event, or had 2+ screen views. Additive across rows.'),
    countField(
        'userEngagementDuration',
        'Total time the app or site was in the foreground, in SECONDS, summed over the row. Additive across rows. Divide by sessions or users for an average — the average itself is deliberately not landed, because an average cannot be re-aggregated.'
    ),
    countField('screenPageViews', 'Screen and page views, counting repeat views of the same page. Additive across rows.'),
    rateField(
        'keyEvents',
        'Key events (what GA4 called "conversions" before the May 2024 rename). Float-typed by GA4 because a key event can be weighted. Additive across rows.'
    ),
];

/**
 * The two user cardinalities.
 *
 * Split out from the additive metrics and described as non-additive on every object, because this is
 * the fact that gets a downstream rollup wrong, and the column description is the only place a
 * consumer reading the landed table will encounter it.
 */
const USER_METRIC_FIELDS: CatalogField[] = [
    countField(
        'totalUsers',
        'DISTINCT users in this row\'s grain. NOT ADDITIVE — GA4 de-duplicates users at the grain requested, so summing rows double-counts anyone who appears in more than one. Use the object whose grain you want.'
    ),
    countField(
        'activeUsers',
        'DISTINCT users who had an engaged session. NOT ADDITIVE, for the same reason as totalUsers.'
    ),
];

/** The UTM dimensions, in GA4 request order. Session-scoped — see the object descriptions. */
const CAMPAIGN_DIM_FIELDS: CatalogField[] = [
    dimField(
        'sessionCampaignName',
        'utm_campaign for the session. GA4 returns \'(not set)\' / \'(direct)\' / \'(organic)\' verbatim rather than null; those sentinels are preserved.',
        255,
        true
    ),
    dimField('sessionSource', 'utm_source for the session, e.g. google, newsletter, (direct).', 255, true),
    dimField('sessionMedium', 'utm_medium for the session, e.g. cpc, email, organic, (none).', 255, true),
];

// ── The catalog ───────────────────────────────────────────────────────────────

export const GA4_OBJECTS: CatalogObject[] = [
    {
        Name: 'PagePerformance',
        DisplayName: 'Page Performance',
        Description:
            'Daily traffic and engagement per page path. One row per (date, pagePath). The page-level report the legacy AIDP provider read, minus its slug-to-Blog join — this lands the raw dimensioned rows and the CRM join happens downstream.',
        APIPath: '/v1beta/properties/{propertyId}:runReport#PagePerformance',
        Category: 'Marketing',
        SupportsIncrementalSync: true,
        IncrementalWatermarkField: 'date',
        PaginationType: 'Cursor',
        Dimensions: ['date', 'pagePath'],
        Metrics: ['screenPageViews', 'totalUsers', 'activeUsers', 'sessions', 'engagedSessions', 'userEngagementDuration', 'keyEvents'],
        Fields: [
            DATE_FIELD,
            dimField(
                'pagePath',
                'Page path WITHOUT the query string (GA4 dimension pagePath, not pagePathPlusQueryString) — so /pricing?utm_source=x and /pricing are one row, which is what a page-performance report wants.',
                512,
                true
            ),
            ...ENGAGEMENT_METRIC_FIELDS,
            ...USER_METRIC_FIELDS,
            PROPERTY_ID_FIELD,
        ],
    },
    {
        Name: 'UtmPerformance',
        DisplayName: 'UTM Performance',
        Description:
            'Daily traffic per campaign / source / medium; one row per (date, campaign, source, medium). Session-scoped: a session is credited to the campaign that drove it. Read user counts at THIS grain — they are cardinalities and do not sum up from finer rows.',
        APIPath: '/v1beta/properties/{propertyId}:runReport#UtmPerformance',
        Category: 'Marketing',
        SupportsIncrementalSync: true,
        IncrementalWatermarkField: 'date',
        PaginationType: 'Cursor',
        Dimensions: ['date', 'sessionCampaignName', 'sessionSource', 'sessionMedium'],
        Metrics: ['sessions', 'totalUsers', 'activeUsers', 'engagedSessions', 'userEngagementDuration', 'screenPageViews', 'keyEvents'],
        Fields: [
            DATE_FIELD,
            ...CAMPAIGN_DIM_FIELDS,
            ...ENGAGEMENT_METRIC_FIELDS,
            ...USER_METRIC_FIELDS,
            PROPERTY_ID_FIELD,
        ],
    },
    {
        Name: 'UtmContentPerformance',
        DisplayName: 'UTM Content Performance',
        Description:
            'The daily campaign report split one level finer, by utm_content; one row per (date, campaign, source, medium, content). utm_content carries the variant tag, so an A/B comparison lives here. Additive metrics roll up to UtmPerformance; user counts do not.',
        APIPath: '/v1beta/properties/{propertyId}:runReport#UtmContentPerformance',
        Category: 'Marketing',
        SupportsIncrementalSync: true,
        IncrementalWatermarkField: 'date',
        PaginationType: 'Cursor',
        Dimensions: ['date', 'sessionCampaignName', 'sessionSource', 'sessionMedium', 'sessionManualAdContent'],
        Metrics: ['sessions', 'totalUsers', 'activeUsers', 'engagedSessions', 'userEngagementDuration', 'screenPageViews', 'keyEvents'],
        Fields: [
            DATE_FIELD,
            ...CAMPAIGN_DIM_FIELDS,
            dimField(
                'sessionManualAdContent',
                'utm_content for the session (GA4 UI name "Session manual ad content"). Free text set by whoever built the link; \'(not set)\' when absent. Any variant convention encoded in it belongs to the tagger and is parsed downstream, not here.',
                255,
                true
            ),
            ...ENGAGEMENT_METRIC_FIELDS,
            ...USER_METRIC_FIELDS,
            PROPERTY_ID_FIELD,
        ],
    },
];

const BY_NAME = new Map(GA4_OBJECTS.map((o) => [o.Name, o]));

/** Look an object up, or throw naming the ones that exist — the message worth getting. */
export function catalogObject(name: string): CatalogObject {
    const found = BY_NAME.get(name);
    if (!found) {
        throw new Error(
            `GA4: unknown object '${name}'. This connector defines: ${GA4_OBJECTS.map((o) => o.Name).join(', ')}.`
        );
    }
    return found;
}

/** The key field names of an object, in declared order — the order `ExternalID` joins them in. */
export function primaryKeyFields(o: CatalogObject): string[] {
    return o.Fields.filter((f) => f.IsPrimaryKey).map((f) => f.Name);
}

/** Narrow a catalog object back to the framework type, which cannot carry the extra attributes. */
export function toIntegrationObjectInfo(o: CatalogObject): IntegrationObjectInfo {
    return {
        Name: o.Name,
        DisplayName: o.DisplayName,
        Description: o.Description,
        SupportsWrite: false,
        Fields: o.Fields.map((f) => ({
            Name: f.Name,
            DisplayName: f.DisplayName,
            Description: f.Description,
            Type: f.Type,
            IsRequired: f.IsRequired,
            IsReadOnly: f.IsReadOnly,
            IsPrimaryKey: f.IsPrimaryKey,
        })),
    };
}
