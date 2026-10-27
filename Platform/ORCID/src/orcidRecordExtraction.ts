/**
 * orcidRecordExtraction — pure helpers that turn one parsed ORCID `/record` payload into the
 * per-section items the child objects (works, employments, keywords, …) are built from, with the
 * nested ORCID shapes lifted into flat, column-shaped keys.
 *
 * No MJ imports here: this is ORCID JSON in, flat records out, so it is unit-testable against a
 * saved `/record` fixture with no engine, provider or network. Ported from a production consumer
 * that subclasses ORCIDConnector, where this exact extraction ran over a ~38k-iD universe; the key
 * names here follow this connector's existing ORCID-path convention (`department-name`,
 * `last-modified-date`) rather than that consumer's PascalCase column names.
 *
 * Why a /record-derived model: ORCID's per-section endpoints (`/{iD}/works`, `/{iD}/employments`, …)
 * return exactly the summaries that `/{iD}/record` already carries under `activities-summary` and
 * `person`. Fetching the record once and deriving every section from it cuts the API cost from
 * one call per section per person (12–18) to one call per person.
 */

/** The root object: the only one that calls ORCID. Every other object is derived from its payload. */
export const ROOT_OBJECT_NAME = 'record';

/**
 * Object name → the key under the `/record` `person` block that holds its items. The object names are
 * ORCID's own endpoint names (`/{iD}/email`, `/{iD}/address`, …), so a section-only fallback fetch
 * can use them verbatim.
 */
export const PERSON_SECTION_KEYS: Readonly<Record<string, string>> = {
    'address': 'addresses',
    'email': 'emails',
    'external-identifiers': 'external-identifiers',
    'keywords': 'keywords',
    'other-names': 'other-names',
    'researcher-urls': 'researcher-urls',
};

/** Affiliation-shaped activity sections: identical summary structure, so one flatten covers all seven. */
export const AFFILIATION_SECTIONS: ReadonlySet<string> = new Set([
    'employments', 'educations', 'qualifications', 'distinctions',
    'invited-positions', 'memberships', 'services',
]);

/** Activity sections, keyed exactly as they appear under `activities-summary`. */
export const ACTIVITY_SECTIONS: ReadonlySet<string> = new Set([
    ...AFFILIATION_SECTIONS, 'works', 'fundings', 'peer-reviews', 'research-resources',
]);

/** True when `section` is one the connector derives from a stored `/record` rather than fetching. */
export function isDerivedSection(section: string): boolean {
    return ACTIVITY_SECTIONS.has(section) || section in PERSON_SECTION_KEYS;
}

/** The two `/record` blocks the derived sections are built from. */
export type RecordBlock = 'person' | 'activities-summary';

/** Which `/record` block a section's items live under (the same rule {@link sectionSubtree} navigates by). */
export function sectionSourceBlock(section: string): RecordBlock {
    return section in PERSON_SECTION_KEYS ? 'person' : 'activities-summary';
}

/**
 * True when a stored record actually carries the block `section` derives from. A record row can hold one
 * block and not the other — a row synced before `activities-summary` was a field has `person` only — and
 * deriving an activity section from it would yield zero items that look exactly like "this person has
 * none". The caller must treat a false here as NOT STORED and fetch the record live. A present-but-empty
 * block (`{}`) is stored: that genuinely is a person with nothing in the section.
 */
export function hasSectionSource(record: Record<string, unknown> | undefined, section: string): boolean {
    return record != null && asObj(record[sectionSourceBlock(section)]) != null;
}

// ── structural helpers ───────────────────────────────────────────────────────

export function asObj(v: unknown): Record<string, unknown> | undefined {
    return v && typeof v === 'object' && !Array.isArray(v) ? (v as Record<string, unknown>) : undefined;
}

/**
 * ORCID wraps most scalars as `{ "value": x }`. Unwraps that shape — and ONLY that shape: an object
 * carrying other keys beside `value` (e.g. `amount: { value, currency-code }`) is a structure in its
 * own right and is returned unchanged.
 */
export function valueOf(v: unknown): unknown {
    const o = asObj(v);
    if (o && 'value' in o && Object.keys(o).length === 1) return o['value'];
    return v;
}

/** A non-empty string out of a scalar or `{value}` wrapper, numbers stringified, else null. */
export function str(v: unknown): string | null {
    const u = valueOf(v);
    if (typeof u === 'string') return u.length > 0 ? u : null;
    if (typeof u === 'number' && Number.isFinite(u)) return String(u);
    return null;
}

/** ORCID partial date `{ year:{value}, month:{value}, day:{value} }` → one numeric part, or null. */
export function datePart(dateNode: unknown, key: 'year' | 'month' | 'day'): number | null {
    const d = asObj(dateNode);
    if (!d) return null;
    const raw = str(d[key]);
    if (raw == null) return null;
    const n = Number(raw);
    return Number.isFinite(n) ? n : null;
}

/** Millisecond epoch out of an ORCID timestamp wrapper, a bare number, or an ISO/numeric string. */
export function extractMs(node: unknown): number | null {
    const value = valueOf(node);
    if (value == null) return null;
    if (typeof value === 'number' && Number.isFinite(value)) return value;
    if (typeof value === 'string') {
        if (value.trim() === '') return null;
        const asNum = Number(value);
        if (Number.isFinite(asNum)) return asNum;
        const parsed = Date.parse(value);
        return Number.isNaN(parsed) ? null : parsed;
    }
    return null;
}

/** Writes an ORCID organization block as `<prefix>-name`, `<prefix>-city`, … flat keys. */
function orgFields(node: unknown, out: Record<string, unknown>, prefix: string): void {
    const org = asObj(node);
    if (!org) return;
    out[`${prefix}-name`] = str(org['name']);
    const addr = asObj(org['address']);
    out[`${prefix}-city`] = addr ? str(addr['city']) : null;
    out[`${prefix}-region`] = addr ? str(addr['region']) : null;
    out[`${prefix}-country`] = addr ? str(addr['country']) : null;
    const dis = asObj(org['disambiguated-organization']);
    out[`${prefix}-disambiguated-id`] = dis ? str(dis['disambiguated-organization-identifier']) : null;
    out[`${prefix}-disambiguation-source`] = dis ? str(dis['disambiguation-source']) : null;
}

/** Writes an ORCID partial date as `<prefix>-year` / `-month` / `-day`. */
function dateFields(node: unknown, out: Record<string, unknown>, prefix: string): void {
    out[`${prefix}-year`] = datePart(node, 'year');
    out[`${prefix}-month`] = datePart(node, 'month');
    out[`${prefix}-day`] = datePart(node, 'day');
}

// ── per-section flatten ──────────────────────────────────────────────────────

function flattenWork(raw: Record<string, unknown>, out: Record<string, unknown>): void {
    const title = asObj(raw['title']);
    out['work-title'] = title ? str(title['title']) : null;
    out['work-subtitle'] = title ? str(title['subtitle']) : null;
    out['translated-title'] = title ? str(title['translated-title']) : null;
    dateFields(raw['publication-date'], out, 'publication');
}

function flattenAffiliation(raw: Record<string, unknown>, out: Record<string, unknown>): void {
    dateFields(raw['start-date'], out, 'start');
    dateFields(raw['end-date'], out, 'end');
    orgFields(raw['organization'], out, 'organization');
}

function flattenFunding(raw: Record<string, unknown>, out: Record<string, unknown>): void {
    const title = asObj(raw['title']);
    out['funding-title'] = title ? str(title['title']) : null;
    out['translated-title'] = title ? str(title['translated-title']) : null;
    // `amount` is on the funding DETAIL endpoint only; the /record summary omits it, so this is
    // null for a derived item. Kept so a detail-fetched item (GetRecord, a future opt-in) lands it.
    const amount = asObj(raw['amount']);
    out['amount-value'] = amount ? str(amount['value']) : null;
    out['amount-currency'] = amount ? str(amount['currency-code']) : null;
    dateFields(raw['start-date'], out, 'start');
    dateFields(raw['end-date'], out, 'end');
    orgFields(raw['organization'], out, 'organization');
}

function flattenPeerReview(raw: Record<string, unknown>, out: Record<string, unknown>): void {
    // The summary names it `completion-date`; the detail endpoint `review-completion-date`.
    dateFields(raw['completion-date'] ?? raw['review-completion-date'], out, 'completion');
    orgFields(raw['convening-organization'], out, 'convening-organization');
    const subjName = asObj(raw['subject-name']);
    out['subject-name-title'] = subjName ? str(subjName['title']) : str(raw['subject-name']);
    const sext = asObj(raw['subject-external-identifier']);
    out['subject-external-id-type'] = sext ? str(sext['external-id-type']) : null;
    out['subject-external-id-value'] = sext ? str(sext['external-id-value']) : null;
}

function flattenResearchResource(raw: Record<string, unknown>, out: Record<string, unknown>): void {
    const proposal = asObj(raw['proposal']);
    const title = proposal ? asObj(proposal['title']) : undefined;
    out['resource-title'] = title ? str(title['title']) : null;
    out['url'] = proposal ? str(proposal['url']) : null;
    dateFields(proposal?.['start-date'], out, 'start');
    dateFields(proposal?.['end-date'], out, 'end');
}

/**
 * Flattens one raw section item into flat keys. Starts from a copy of the raw item (every source key
 * is preserved, so nothing the API returned is lost), unwraps each top-level `{value}` scalar in
 * place (`journal-title`, `review-url`, `url`, `country`, …) so a declared String column receives the
 * string rather than a stringified wrapper, lifts the asserting source to `source-name` /
 * `source-orcid`, then applies the section's own flatten. Deterministic, so the engine's content-hash
 * idempotency holds across runs.
 */
export function flattenSectionItem(raw: Record<string, unknown>, section: string): Record<string, unknown> {
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(raw)) out[k] = valueOf(v);

    const src = asObj(raw['source']);
    out['source-name'] = src ? str(src['source-name']) : null;
    const so = src ? asObj(src['source-orcid']) : undefined;
    out['source-orcid'] = so ? str(so['path']) : null;

    switch (section) {
        case 'works': flattenWork(raw, out); break;
        case 'fundings': flattenFunding(raw, out); break;
        case 'peer-reviews': flattenPeerReview(raw, out); break;
        case 'research-resources': flattenResearchResource(raw, out); break;
        default:
            if (AFFILIATION_SECTIONS.has(section)) flattenAffiliation(raw, out);
            break;
    }
    return out;
}

// ── /record navigation ───────────────────────────────────────────────────────

/**
 * The sub-tree of a parsed `/record` that holds one section's items: person sub-sections live under
 * `person`, activities under `activities-summary`. Undefined when the record has no such section.
 */
export function sectionSubtree(recJson: Record<string, unknown>, section: string): unknown {
    const personKey = PERSON_SECTION_KEYS[section];
    if (personKey) return asObj(recJson['person'])?.[personKey];
    return asObj(recJson['activities-summary'])?.[section];
}

/**
 * Walks a section envelope and collects every distinct put-code item. A `put-code`-bearing object IS an
 * item and is not descended into, so an item's own nested ids can't produce false positives. This
 * handles every ORCID envelope shape generically: `group[].work-summary[]`,
 * `affiliation-group[].summaries[].employment-summary`, `peer-review-group[].peer-review-summary[]`,
 * and the person lists (`other-name[]`, `keyword[]`, `email[]`, …).
 */
export function collectPutCodeItems(node: unknown): Record<string, unknown>[] {
    const items: Record<string, unknown>[] = [];
    const walk = (n: unknown): void => {
        if (Array.isArray(n)) { for (const el of n) walk(el); return; }
        const o = asObj(n);
        if (!o) return;
        if ('put-code' in o && o['put-code'] != null) { items.push(o); return; }
        for (const v of Object.values(o)) walk(v);
    };
    walk(node);
    return items;
}

/**
 * The raw put-code items of one section from a parsed `/record`, each tagged with the owning
 * `orcid-id` (the FK to the record object). Empty when the record carries no such section.
 */
export function extractSectionRawItems(recJson: Record<string, unknown>, section: string, iD: string): Record<string, unknown>[] {
    const subtree = sectionSubtree(recJson, section);
    if (subtree == null) return [];
    return collectPutCodeItems(subtree).map(item => ({ ...item, 'orcid-id': iD }));
}
