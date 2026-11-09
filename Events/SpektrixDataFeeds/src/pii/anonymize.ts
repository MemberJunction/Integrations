import type { DataFeedCustomer, DataFeedCustomerAttribute } from '../datafeeds/types.js';
import type { PiiClass, PiiMode } from './policy.js';
import { Pseudonymizer } from './pseudonymizer.js';

/**
 * Applies the personal-data policy to one flat record. Pure: same inputs, same output.
 *
 * `classes` maps field name → class (from the catalog). A field with no class is left untouched —
 * the catalog test guarantees every declared field has one, so an unclassified key can only be a
 * programming error upstream, and leaving it visible is the honest failure mode.
 */
export interface AnonymizeOptions {
    mode: PiiMode;
    /** Required for `pseudonymize`; ignored otherwise. */
    pseudonymizer?: Pseudonymizer;
    /** Attribute names whose values survive the protective modes (case-insensitive). */
    attributeAllowlist?: readonly string[];
    /** The seed for name replacement — the customer id, so a customer keeps one synthetic name across runs. */
    nameSeed?: string;
}

export function AnonymizeRecord(
    fields: Record<string, unknown>,
    classes: Record<string, PiiClass>,
    options: AnonymizeOptions,
): Record<string, unknown> {
    if (options.mode === 'raw') return fields;
    const p = options.pseudonymizer;
    if (options.mode === 'pseudonymize' && !p) {
        throw new Error('piiMode pseudonymize requires a pseudonymization key.');
    }
    const out: Record<string, unknown> = {};
    for (const [name, value] of Object.entries(fields)) {
        const cls = classes[name];
        out[name] = cls === undefined ? value : applyClass(cls, name, value, options, p);
    }
    return out;
}

function applyClass(
    cls: PiiClass,
    name: string,
    value: unknown,
    options: AnonymizeOptions,
    p: Pseudonymizer | undefined,
): unknown {
    if (value === null || value === undefined) return value ?? null;
    const suppress = options.mode === 'suppress';
    switch (cls) {
        case 'identifier':
        case 'timestamp':
        case 'label':
        case 'geography':
            return value;
        case 'title':
            return suppress ? null : value;
        case 'reference':
            return suppress || !p ? null : p.Reference(String(value));
        case 'email':
            return suppress || !p ? null : p.Email(String(value));
        case 'phone':
            return suppress || !p ? null : p.Phone(String(value));
        case 'personName': {
            if (suppress || !p) return null;
            const seed = options.nameSeed ?? String(value);
            return /first/i.test(name) ? p.FirstName(seed) : p.LastName(seed);
        }
        case 'organisationName':
            return suppress || !p ? null : p.OrganisationName(options.nameSeed ?? String(value));
        case 'birthDate':
            return suppress ? null : Pseudonymizer.BirthYearOnly(String(value));
        case 'addressLine':
            return null;
        case 'postcode':
            return suppress ? null : Pseudonymizer.PostcodePrefix(String(value));
        case 'freeText':
            return redactAttributes(value, options.attributeAllowlist ?? []);
    }
}

/** `attributes` is a JSON text of `{name, value}[]`; values outside the allowlist become null. */
function redactAttributes(value: unknown, allowlist: readonly string[]): unknown {
    const list = parseAttributes(value);
    if (list === null) return null;
    const allowed = new Set(allowlist.map((a) => a.trim().toLowerCase()));
    const redacted = list.map((a) => ({
        name: a.name,
        value: a.name !== null && allowed.has(a.name.trim().toLowerCase()) ? a.value : null,
    }));
    return JSON.stringify(redacted);
}

function parseAttributes(value: unknown): DataFeedCustomerAttribute[] | null {
    const raw: unknown = typeof value === 'string' ? safeParse(value) : value;
    if (!Array.isArray(raw)) return null;
    return raw.map((item) => {
        const o = (item ?? {}) as Record<string, unknown>;
        return { name: typeof o['name'] === 'string' ? o['name'] : null, value: typeof o['value'] === 'string' ? o['value'] : null };
    });
}

function safeParse(text: string): unknown {
    try {
        return JSON.parse(text);
    } catch {
        return null;
    }
}

/**
 * Flattens a streamed customer into the wire-flat record the catalog declares: one row, address
 * columns prefixed `address_`, list values as JSON text so they land in the declared `json` columns
 * rather than being exploded into overflow keys by the engine's record flattener.
 */
export function FlattenCustomer(customer: DataFeedCustomer): Record<string, unknown> {
    const address = customer.type === 'Person' ? customer.billingAddress : customer.primaryAddress;
    const json = (v: unknown): string | null => (v === null || v === undefined ? null : JSON.stringify(v));
    return {
        id: customer.id,
        type: customer.type,
        friendlyId: customer.friendlyId,
        email: customer.email,
        phoneNumber: customer.phoneNumber,
        mobileNumber: customer.type === 'Person' ? customer.mobileNumber : null,
        title: customer.type === 'Person' ? customer.title : null,
        firstName: customer.type === 'Person' ? customer.firstName : null,
        lastName: customer.type === 'Person' ? customer.lastName : null,
        birthDate: customer.type === 'Person' ? customer.birthDate : null,
        organisationName: customer.type === 'Organisation' ? customer.name : null,
        primaryContactId: customer.type === 'Organisation' ? customer.primaryContactId : null,
        address_name: address?.name ?? null,
        address_line1: address?.line1 ?? null,
        address_line2: address?.line2 ?? null,
        address_line3: address?.line3 ?? null,
        address_line4: address?.line4 ?? null,
        address_line5: address?.line5 ?? null,
        address_town: address?.town ?? null,
        address_county: address?.county ?? null,
        address_postcode: address?.postcode ?? null,
        address_country: address?.country ?? null,
        tagIds: json(customer.tagIds),
        agreedStatementIds: json(customer.agreedStatementIds),
        attributes: json(customer.attributes),
        dateCreated: customer.dateCreated,
        dateLastUpdated: customer.dateLastUpdated,
    };
}
