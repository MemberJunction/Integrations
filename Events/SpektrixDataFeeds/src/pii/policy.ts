/**
 * The personal-data policy vocabulary. Every field this connector emits carries exactly one
 * {@link PiiClass}; the class decides what each {@link PiiMode} does to the value.
 *
 * - `raw`          — values pass through unchanged (requires an explicit decision by the tenant).
 * - `pseudonymize` — deterministic, keyed replacements (HMAC-SHA256 with the connection's key) so the
 *                    same source value always yields the same token: change detection, de-duplication
 *                    and id joins keep working, but nothing identifiable lands.
 * - `suppress`     — personal values are nulled outright.
 *
 * This is pseudonymisation, not anonymisation: with the key, tokens can be re-derived from source
 * values (never the reverse). Describe it to tenants in those words.
 */
export const PII_MODES = ['raw', 'pseudonymize', 'suppress'] as const;
export type PiiMode = (typeof PII_MODES)[number];

export const PII_CLASSES = [
    /** A system id (customer id, tag id). Never personal on its own; always kept. */
    'identifier',
    /** A customer-facing reference (friendly id). Pseudonymized to a token; suppressed to null. */
    'reference',
    'email',
    'phone',
    'personName',
    'organisationName',
    /** Salutation. Low risk and wanted downstream (unified Person.Prefix); kept in pseudonymize, nulled in suppress. */
    'title',
    /** Reduced to 1 January of the birth year in pseudonymize; nulled in suppress. */
    'birthDate',
    /** Street-level address text. Nulled in both protective modes. */
    'addressLine',
    /** Reduced to its first three characters (US ZIP3 / UK outward area) in pseudonymize; nulled in suppress. */
    'postcode',
    /** Town, county, country. Kept in pseudonymize; kept in suppress. */
    'geography',
    /** Key/value attribute lists that may hold anything. Values outside the allowlist are nulled. */
    'freeText',
    /** Created / last-updated stamps. Always kept. */
    'timestamp',
    /** Non-personal labels (tag names, statement names). Always kept. */
    'label',
] as const;
export type PiiClass = (typeof PII_CLASSES)[number];

export function IsPiiMode(value: unknown): value is PiiMode {
    return typeof value === 'string' && (PII_MODES as readonly string[]).includes(value);
}
