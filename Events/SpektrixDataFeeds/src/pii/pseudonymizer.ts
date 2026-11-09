import { createHmac } from 'node:crypto';

/**
 * Keyed, deterministic replacement values. Every method is a pure function of (key, input), so a
 * record pseudonymized twice is byte-identical — which is what lets the engine's content hash and
 * watermark logic work on protected data — and two tenants with different keys never share tokens.
 *
 * Conventions follow the reserved-for-fiction ranges so a protected value can never collide with a
 * real one: `example.invalid` for email (RFC 2606/6761), `555-01xx` for US phone numbers.
 */
export class Pseudonymizer {
    private readonly key: Buffer;

    constructor(key: Buffer | string) {
        const bytes = typeof key === 'string' ? Buffer.from(key, 'utf8') : key;
        if (bytes.byteLength < 16) {
            throw new Error('The pseudonymization key must be at least 16 bytes.');
        }
        this.key = bytes;
    }

    /** Lower-case hex HMAC-SHA256 of the input, truncated to `length` characters. */
    public Token(input: string, length = 16): string {
        return createHmac('sha256', this.key).update(input, 'utf8').digest('hex').slice(0, length);
    }

    /** Same mailbox → same token, regardless of case or surrounding whitespace. */
    public Email(value: string): string {
        return `${this.Token(`email:${value.trim().toLowerCase()}`, 20)}@example.invalid`;
    }

    /** A number in the North American fiction range 555-0100..555-0199, chosen by the input. */
    public Phone(value: string): string {
        const digits = value.replace(/\D+/g, '');
        const n = parseInt(this.Token(`phone:${digits}`, 8), 16) % 100;
        return `+1 555 01${n.toString().padStart(2, '0')}`;
    }

    /** A friendly-id style token: upper-case, 10 characters, prefixed so it reads as synthetic. */
    public Reference(value: string): string {
        return `REF-${this.Token(`ref:${value.trim()}`, 10).toUpperCase()}`;
    }

    /** A stable first name for the seed (usually the customer id), drawn from a fixed pool. */
    public FirstName(seed: string): string {
        return pick(FIRST_NAMES, this.Token(`first:${seed}`, 8));
    }

    /** A stable last name for the seed, drawn from a fixed pool. */
    public LastName(seed: string): string {
        return pick(LAST_NAMES, this.Token(`last:${seed}`, 8));
    }

    public OrganisationName(seed: string): string {
        return `Organisation ${this.Token(`org:${seed}`, 6).toUpperCase()}`;
    }

    /** `YYYY-01-01T00:00:00.0000000` for a .NET round-trip date; null when the year cannot be read. */
    public static BirthYearOnly(value: string): string | null {
        const match = /^(\d{4})-\d{2}-\d{2}T/.exec(value);
        return match ? `${match[1]}-01-01T00:00:00.0000000` : null;
    }

    /** First three characters of the code with spaces removed (US ZIP3; UK outward area). */
    public static PostcodePrefix(value: string): string | null {
        const compact = value.replace(/\s+/g, '').toUpperCase();
        return compact.length >= 3 ? compact.slice(0, 3) : null;
    }
}

function pick(pool: readonly string[], hex: string): string {
    return pool[parseInt(hex, 16) % pool.length]!;
}

const FIRST_NAMES: readonly string[] = [
    'Avery', 'Blake', 'Cameron', 'Dakota', 'Elliot', 'Finley', 'Harper', 'Jordan', 'Kendall', 'Logan',
    'Morgan', 'Parker', 'Quinn', 'Reese', 'Riley', 'Rowan', 'Sawyer', 'Skyler', 'Taylor', 'Emerson',
    'Hayden', 'Jamie', 'Casey', 'Drew', 'Frankie', 'Jesse', 'Kai', 'Lee', 'Marley', 'Noel',
    'Peyton', 'Robin', 'Sam', 'Shay', 'Sidney', 'Tatum', 'Toby', 'Wren', 'Ari', 'Bellamy',
    'Devon', 'Ellis', 'Gray', 'Indigo', 'Jules', 'Lane', 'Micah', 'Oakley',
];

const LAST_NAMES: readonly string[] = [
    'Abbott', 'Archer', 'Baker', 'Barnes', 'Bishop', 'Brooks', 'Carver', 'Chandler', 'Cooper', 'Dalton',
    'Draper', 'Fletcher', 'Foster', 'Gardner', 'Glover', 'Harper', 'Hayward', 'Hunter', 'Jenner', 'Keller',
    'Lambert', 'Mason', 'Mercer', 'Miller', 'Norris', 'Palmer', 'Parrish', 'Porter', 'Prescott', 'Quincy',
    'Reeves', 'Sawyer', 'Sheppard', 'Slater', 'Spencer', 'Stewart', 'Tanner', 'Thatcher', 'Turner', 'Tyler',
    'Walker', 'Ward', 'Weaver', 'Webster', 'Whitaker', 'Wright', 'Yates', 'Ashby', 'Bramwell', 'Carrington',
    'Dunmore', 'Easton', 'Fairfax', 'Granger', 'Hollis', 'Kingsley', 'Landry', 'Marlow', 'Northam', 'Pemberton',
    'Rutledge', 'Sinclair', 'Thorne', 'Winslow',
];
