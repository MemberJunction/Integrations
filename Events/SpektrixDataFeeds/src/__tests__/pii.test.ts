import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { CATALOG, CUSTOMER_OBJECT, PiiClassesFor } from '../catalog.js';
import type { DataFeedCustomer } from '../datafeeds/types.js';
import { AnonymizeRecord, FlattenCustomer } from '../pii/anonymize.js';
import { Pseudonymizer } from '../pii/pseudonymizer.js';

const here = dirname(fileURLToPath(import.meta.url));
const FIXTURE = JSON.parse(readFileSync(join(here, 'fixtures', 'customers.synthetic.json'), 'utf8')) as { customers: DataFeedCustomer[] };
const CLASSES = PiiClassesFor(CATALOG.find((o) => o.name === CUSTOMER_OBJECT)!);
const KEY = 'unit-test-key-0123456789abcdef';
const [person, blankPerson, organisation] = FIXTURE.customers as [DataFeedCustomer, DataFeedCustomer, DataFeedCustomer];

/** Every string that identifies the synthetic patron; none may survive a protective mode. */
const RAW_MARKERS = ['Zebediah', 'Fixturesmith', 'example.org', 'example.ORG', '206 000', 'Synthetic', 'Apt 4', '12345-6789', '1980-02-29', 'ZXCV-1001', 'ORG-2001', 'wheelchair', 'sample-org'];

function allText(record: Record<string, unknown>): string {
    return JSON.stringify(record);
}

describe('FlattenCustomer', () => {
    it('produces exactly the catalog columns, in catalog order', () => {
        const flat = FlattenCustomer(person);
        expect(Object.keys(flat)).toEqual(Object.keys(CLASSES));
    });

    it('takes the address from BillingAddress for a Person and PrimaryAddress for an Organisation', () => {
        expect(FlattenCustomer(person)['address_town']).toBe('Exampleville');
        expect(FlattenCustomer(organisation)['address_town']).toBe('Sampletown');
        expect(FlattenCustomer(organisation)['organisationName']).toBe('Sample Org Inc');
        expect(FlattenCustomer(person)['organisationName']).toBeNull();
    });

    it('stores list values as JSON text so they land in the declared json columns', () => {
        const flat = FlattenCustomer(person);
        expect(flat['tagIds']).toBe('[10,20]');
        expect(JSON.parse(flat['attributes'] as string)).toHaveLength(2);
        expect(FlattenCustomer(blankPerson)['tagIds']).toBeNull();
    });
});

describe('AnonymizeRecord — raw', () => {
    it('returns the input unchanged', () => {
        const flat = FlattenCustomer(person);
        expect(AnonymizeRecord(flat, CLASSES, { mode: 'raw' })).toBe(flat);
    });
});

describe('AnonymizeRecord — pseudonymize', () => {
    const p = new Pseudonymizer(KEY);
    const run = (c: DataFeedCustomer, allow: string[] = []) =>
        AnonymizeRecord(FlattenCustomer(c), CLASSES, { mode: 'pseudonymize', pseudonymizer: p, attributeAllowlist: allow, nameSeed: String(c.id) });

    it('lets no identifying source value through, for a Person or an Organisation', () => {
        for (const c of [person, organisation]) {
            const text = allText(run(c));
            for (const marker of RAW_MARKERS) expect(text, marker).not.toContain(marker);
        }
    });

    it('keeps identifiers, timestamps, labels and geography', () => {
        const out = run(person);
        expect(out['id']).toBe(1001);
        expect(out['type']).toBe('Person');
        expect(out['dateLastUpdated']).toBe('2026-10-01T23:59:59.0000000Z');
        expect(out['tagIds']).toBe('[10,20]');
        expect(out['agreedStatementIds']).toBe('[1,2]');
        expect(out['address_town']).toBe('Exampleville');
        expect(out['address_county']).toBe('Example County');
        expect(out['address_country']).toBe('United States');
        expect(out['title']).toBe('Dr');
        expect(run(organisation)['primaryContactId']).toBe(1001);
    });

    it('reduces the birth date to 1 January of the year and the postcode to its first three characters', () => {
        const out = run(person);
        expect(out['birthDate']).toBe('1980-01-01T00:00:00.0000000');
        expect(out['address_postcode']).toBe('123');
    });

    it('nulls every street-level address line', () => {
        const out = run(person);
        for (const k of ['address_name', 'address_line1', 'address_line2', 'address_line3', 'address_line4', 'address_line5']) expect(out[k]).toBeNull();
    });

    it('emits fiction-range replacements for email and phone', () => {
        const out = run(person);
        expect(out['email']).toMatch(/^[0-9a-f]{20}@example\.invalid$/);
        expect(out['phoneNumber']).toMatch(/^\+1 555 01\d\d$/);
        expect(out['mobileNumber']).toMatch(/^\+1 555 01\d\d$/);
        expect(out['friendlyId']).toMatch(/^REF-[0-9A-F]{10}$/);
    });

    it('is deterministic for the same key and differs under another key', () => {
        const a = run(person);
        const b = run(person);
        expect(a).toEqual(b);
        const other = new Pseudonymizer('another-unit-test-key-abcdef0123');
        const c = AnonymizeRecord(FlattenCustomer(person), CLASSES, { mode: 'pseudonymize', pseudonymizer: other, nameSeed: '1001' });
        expect(c['email']).not.toBe(a['email']);
        expect(c['firstName']).not.toBe(a['firstName']);
    });

    it('matches the same mailbox regardless of case, so de-duplication still works', () => {
        expect(p.Email('Zebediah.Fixturesmith@Example.ORG')).toBe(p.Email('zebediah.fixturesmith@example.org'));
    });

    it('gives a customer one stable synthetic name, seeded by id not by the real name', () => {
        const renamed: DataFeedCustomer = { ...person, firstName: 'Someone', lastName: 'Else' } as DataFeedCustomer;
        expect(run(renamed)['firstName']).toBe(run(person)['firstName']);
        expect(run(renamed)['lastName']).toBe(run(person)['lastName']);
    });

    it('keeps attribute names, nulls values unless the name is allowlisted (case-insensitive)', () => {
        const none = JSON.parse(run(person)['attributes'] as string) as Array<{ name: string; value: string | null }>;
        expect(none.map((a) => a.name)).toEqual(['Membership', 'Notes']);
        expect(none.every((a) => a.value === null)).toBe(true);
        const allowed = JSON.parse(run(person, ['membership'])['attributes'] as string) as Array<{ name: string; value: string | null }>;
        expect(allowed[0]!.value).toBe('Gold');
        expect(allowed[1]!.value).toBeNull();
    });

    it('passes nulls through as nulls', () => {
        const out = run(blankPerson);
        expect(out['email']).toBeNull();
        expect(out['birthDate']).toBeNull();
        expect(out['attributes']).toBeNull();
    });

    it('refuses to run without a key', () => {
        expect(() => AnonymizeRecord(FlattenCustomer(person), CLASSES, { mode: 'pseudonymize' })).toThrow(/key/);
    });
});

describe('AnonymizeRecord — suppress', () => {
    it('nulls personal values, keeps identifiers, timestamps and geography, needs no key', () => {
        const out = AnonymizeRecord(FlattenCustomer(person), CLASSES, { mode: 'suppress' });
        for (const marker of RAW_MARKERS) expect(allText(out), marker).not.toContain(marker);
        for (const k of ['email', 'phoneNumber', 'mobileNumber', 'firstName', 'lastName', 'title', 'birthDate', 'friendlyId', 'address_line1', 'address_postcode']) {
            expect(out[k], k).toBeNull();
        }
        expect(out['id']).toBe(1001);
        expect(out['address_town']).toBe('Exampleville');
        expect(out['dateCreated']).toBe('2019-04-12T09:30:15.1234567');
    });
});

describe('Pseudonymizer', () => {
    it('rejects a short key', () => {
        expect(() => new Pseudonymizer('short')).toThrow(/16 bytes/);
    });
    it('static helpers handle malformed input by returning null', () => {
        expect(Pseudonymizer.BirthYearOnly('not a date')).toBeNull();
        expect(Pseudonymizer.PostcodePrefix('A1')).toBeNull();
        expect(Pseudonymizer.PostcodePrefix('sw1a 1aa')).toBe('SW1');
    });
});
