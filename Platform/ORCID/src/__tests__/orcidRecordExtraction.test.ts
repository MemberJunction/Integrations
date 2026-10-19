import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import {
    ROOT_OBJECT_NAME,
    AFFILIATION_SECTIONS,
    isDerivedSection,
    valueOf,
    str,
    datePart,
    extractMs,
    sectionSubtree,
    collectPutCodeItems,
    extractSectionRawItems,
    flattenSectionItem,
} from '../orcidRecordExtraction.js';

// ORCID's own published sample record (Josiah Carberry, a fictional researcher ORCID maintains for
// exactly this purpose) as served by GET https://pub.orcid.org/v3.0/0000-0002-1825-0097/record.
// Real envelope shapes for every activity and person section; no real person's data.
const SAMPLE_ID = '0000-0002-1825-0097';
const RECORD = JSON.parse(
    readFileSync(new URL('./fixtures/record-0000-0002-1825-0097.json', import.meta.url), 'utf8')
) as Record<string, unknown>;

describe('orcidRecordExtraction — scalar helpers', () => {
    it('valueOf unwraps a bare {value} wrapper and nothing else', () => {
        expect(valueOf({ value: 'x' })).toBe('x');
        expect(valueOf({ value: 1700000000000 })).toBe(1700000000000);
        // An object with more than the value key is a structure (e.g. amount), not a wrapper.
        expect(valueOf({ value: '100', 'currency-code': 'USD' })).toEqual({ value: '100', 'currency-code': 'USD' });
        expect(valueOf('plain')).toBe('plain');
        expect(valueOf(null)).toBeNull();
    });

    it('str yields a non-empty string, stringifies numbers, and nulls the rest', () => {
        expect(str({ value: 'Professor' })).toBe('Professor');
        expect(str('')).toBeNull();
        expect(str(42)).toBe('42');
        expect(str(undefined)).toBeNull();
        expect(str({ nested: true })).toBeNull();
    });

    it('datePart reads ORCID partial dates and tolerates missing parts', () => {
        const d = { year: { value: '1930' }, month: { value: '02' }, day: null };
        expect(datePart(d, 'year')).toBe(1930);
        expect(datePart(d, 'month')).toBe(2);
        expect(datePart(d, 'day')).toBeNull();
        expect(datePart(null, 'year')).toBeNull();
    });

    it('extractMs reads a wrapper, a number, a numeric string and an ISO string', () => {
        expect(extractMs({ value: 1494016313835 })).toBe(1494016313835);
        expect(extractMs(1494016313835)).toBe(1494016313835);
        expect(extractMs('1494016313835')).toBe(1494016313835);
        expect(extractMs('2017-05-05T20:31:53.835Z')).toBe(1494016313835);
        expect(extractMs('')).toBeNull();
        expect(extractMs(null)).toBeNull();
    });

    it('isDerivedSection is true for every section and false for the root', () => {
        for (const s of ['works', 'employments', 'fundings', 'peer-reviews', 'research-resources', 'keywords', 'email', 'address']) {
            expect(isDerivedSection(s)).toBe(true);
        }
        expect(isDerivedSection(ROOT_OBJECT_NAME)).toBe(false);
        expect(isDerivedSection('nonsense')).toBe(false);
    });
});

describe('orcidRecordExtraction — /record navigation', () => {
    it('finds activity sections under activities-summary and person sections under person', () => {
        expect(sectionSubtree(RECORD, 'works')).toBeDefined();
        expect(sectionSubtree(RECORD, 'employments')).toBeDefined();
        expect(sectionSubtree(RECORD, 'keywords')).toBeDefined();
        expect(sectionSubtree(RECORD, 'other-names')).toBeDefined();
        expect(sectionSubtree(RECORD, 'no-such-section')).toBeUndefined();
    });

    it('collectPutCodeItems walks every ORCID envelope shape and does not descend into an item', () => {
        // works: group[].work-summary[]
        const works = collectPutCodeItems(sectionSubtree(RECORD, 'works'));
        expect(works.length).toBeGreaterThan(0);
        for (const w of works) expect(w['put-code']).toBeDefined();
        // employments: affiliation-group[].summaries[].employment-summary
        const emps = collectPutCodeItems(sectionSubtree(RECORD, 'employments'));
        expect(emps.length).toBeGreaterThan(0);
        expect(emps[0]['role-title']).toBeDefined();
        // peer-reviews: group[].peer-review-group[].peer-review-summary[]
        const prs = collectPutCodeItems(sectionSubtree(RECORD, 'peer-reviews'));
        expect(prs.length).toBeGreaterThan(0);
        expect(prs[0]['reviewer-role']).toBe('reviewer');
        // person lists: other-name[]
        const names = collectPutCodeItems(sectionSubtree(RECORD, 'other-names'));
        expect(names.length).toBeGreaterThan(0);
        expect(typeof names[0]['content']).toBe('string');
    });

    it('a put-code item is a leaf: nested external-ids never produce extra items', () => {
        const works = collectPutCodeItems(sectionSubtree(RECORD, 'works'));
        const putCodes = works.map(w => w['put-code']);
        expect(new Set(putCodes).size).toBe(putCodes.length);
    });

    it('extractSectionRawItems tags every item with the owning orcid-id and is empty for a missing section', () => {
        const items = extractSectionRawItems(RECORD, 'works', SAMPLE_ID);
        expect(items.length).toBeGreaterThan(0);
        for (const it of items) expect(it['orcid-id']).toBe(SAMPLE_ID);
        expect(extractSectionRawItems(RECORD, 'no-such-section', SAMPLE_ID)).toEqual([]);
        expect(extractSectionRawItems({}, 'works', SAMPLE_ID)).toEqual([]);
    });

    it('an empty person list (emails, addresses) yields no items rather than an error', () => {
        expect(extractSectionRawItems(RECORD, 'email', SAMPLE_ID)).toEqual([]);
        expect(extractSectionRawItems(RECORD, 'address', SAMPLE_ID)).toEqual([]);
    });
});

describe('orcidRecordExtraction — flattenSectionItem', () => {
    const first = (section: string): Record<string, unknown> => {
        const items = extractSectionRawItems(RECORD, section, SAMPLE_ID);
        expect(items.length).toBeGreaterThan(0);
        return flattenSectionItem(items[0], section);
    };

    it('preserves every raw key (nothing the API returned is lost)', () => {
        const raw = extractSectionRawItems(RECORD, 'works', SAMPLE_ID)[0];
        const flat = flattenSectionItem(raw, 'works');
        for (const k of Object.keys(raw)) expect(k in flat).toBe(true);
    });

    it('unwraps top-level {value} wrappers in place so declared String columns get strings', () => {
        const work = first('works');
        // journal-title is `{ value: "…" }` on the wire; the declared column is String(1000).
        expect(typeof work['journal-title'] === 'string' || work['journal-title'] == null).toBe(true);
        const url = first('researcher-urls');
        expect(typeof url['url']).toBe('string');
        expect(url['url']).toMatch(/^https?:\/\//);
    });

    it('lifts the asserting source to source-name / source-orcid', () => {
        const emp = first('employments');
        expect(emp['source-name']).toBe('Josiah Carberry');
        expect(emp['source-orcid']).toBe(SAMPLE_ID);
        const work = first('works');
        expect(typeof work['source-name']).toBe('string');
        // A client-asserted item has no source-orcid.
        expect(work['source-orcid'] == null || typeof work['source-orcid'] === 'string').toBe(true);
    });

    it('works: title, subtitle, and publication date parts', () => {
        const work = first('works');
        expect(work['work-title']).toBe('A Methodology for the Emulation of Architecture');
        expect(work['work-subtitle']).toBe('Journal of Psychoceramics');
        expect(work['translated-title']).toBeNull();
        expect(typeof work['publication-year']).toBe('number');
    });

    it('affiliations: organization block, partial dates, and an ongoing role with no end date', () => {
        const emp = first('employments');
        expect(emp['department-name']).toBe('Psychoceramics');
        expect(emp['role-title']).toBe('Professor');
        expect(emp['organization-name']).toBe('Wesleyan University');
        expect(emp['organization-city']).toBe('Middletown');
        expect(emp['organization-region']).toBe('CT');
        expect(emp['organization-country']).toBe('US');
        expect(emp['organization-disambiguated-id']).toBe('5468');
        expect(emp['organization-disambiguation-source']).toBe('RINGGOLD');
        expect(emp['start-year']).toBe(1930);
        expect(emp['start-month']).toBe(2);
        expect(emp['start-day']).toBe(29);
        expect(emp['end-year']).toBeNull();
        expect(emp['end-month']).toBeNull();
        expect(emp['end-day']).toBeNull();
    });

    it('every affiliation section flattens with the same shape', () => {
        const raw = extractSectionRawItems(RECORD, 'employments', SAMPLE_ID)[0];
        for (const section of AFFILIATION_SECTIONS) {
            const flat = flattenSectionItem(raw, section);
            expect(flat['organization-name']).toBe('Wesleyan University');
            expect(flat['start-year']).toBe(1930);
        }
    });

    it('fundings: title, type, organization, dates; amount is null off the summary', () => {
        const summary = {
            'put-code': 1,
            title: { title: { value: 'A Grant' }, 'translated-title': null },
            type: 'grant',
            'organization-defined-type': null,
            'start-date': { year: { value: '2020' }, month: null, day: null },
            'end-date': { year: { value: '2022' }, month: { value: '12' }, day: null },
            organization: { name: 'NSF', address: { city: 'Alexandria', region: 'VA', country: 'US' }, 'disambiguated-organization': { 'disambiguated-organization-identifier': 'https://doi.org/10.13039/100000001', 'disambiguation-source': 'FUNDREF' } },
            source: { 'source-name': { value: 'NSF' }, 'source-orcid': null },
            'last-modified-date': { value: 1600000000000 },
        };
        const flat = flattenSectionItem(summary, 'fundings');
        expect(flat['funding-title']).toBe('A Grant');
        expect(flat['type']).toBe('grant');
        expect(flat['organization-name']).toBe('NSF');
        expect(flat['organization-disambiguation-source']).toBe('FUNDREF');
        expect(flat['start-year']).toBe(2020);
        expect(flat['end-month']).toBe(12);
        expect(flat['amount-value']).toBeNull();
        expect(flat['amount-currency']).toBeNull();
        expect(flat['source-name']).toBe('NSF');
    });

    it('fundings: amount lands when a detail payload supplies it', () => {
        const detail = { 'put-code': 1, amount: { value: '150000', 'currency-code': 'USD' } };
        const flat = flattenSectionItem(detail, 'fundings');
        expect(flat['amount-value']).toBe('150000');
        expect(flat['amount-currency']).toBe('USD');
        // amount itself is a structure, not a wrapper — preserved as-is for the json column.
        expect(flat['amount']).toEqual({ value: '150000', 'currency-code': 'USD' });
    });

    it('peer-reviews: completion date, convening organization, and subject', () => {
        const pr = first('peer-reviews');
        expect(pr['reviewer-role']).toBe('reviewer');
        expect(typeof pr['completion-year']).toBe('number');
        expect(typeof pr['convening-organization-name']).toBe('string');
        expect('subject-name-title' in pr).toBe(true);
        expect('subject-external-id-type' in pr).toBe(true);
    });

    it('person sub-sections: external identifiers and keywords', () => {
        const ext = first('external-identifiers');
        expect(ext['external-id-type']).toBe('Scopus Author ID');
        expect(ext['external-id-value']).toBe('7007156898');
        expect(typeof ext['external-id-url']).toBe('string');
        const kw = first('keywords');
        expect(typeof kw['content']).toBe('string');
    });

    it('is deterministic: the same item flattens to the same keys and values every time', () => {
        const raw = extractSectionRawItems(RECORD, 'works', SAMPLE_ID)[0];
        expect(flattenSectionItem(raw, 'works')).toEqual(flattenSectionItem(raw, 'works'));
    });
});
