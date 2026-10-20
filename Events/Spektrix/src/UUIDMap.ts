// Vendored into this Open App from the MemberJunction monorepo (@memberjunction/global 6.x UUIDCollections),
// because the published 5.x line this package compiles against does not export UUIDMap yet.

/** Anything that may hold a UUID. */
export type UUIDInput = string | null | undefined;

/** Case- and whitespace-insensitive UUID key. */
export function NormalizeUUID(uuid: UUIDInput): string {
    if (uuid == null) return '';
    return uuid.trim().toLowerCase();
}

/** A Map keyed by UUID that treats case variants of the same ID as one key. */
export class UUIDMap<V> implements Iterable<[string, V]> {
    private readonly entries = new Map<string, V>();

    constructor(entries?: Iterable<readonly [UUIDInput, V]>) {
        if (entries) {
            for (const [id, value] of entries) this.entries.set(NormalizeUUID(id), value);
        }
    }

    /** The value stored for the ID, or undefined. */
    public Get(id: UUIDInput): V | undefined {
        return this.entries.get(NormalizeUUID(id));
    }

    /** Stores a value for the ID, replacing any value stored under a case variant of it. */
    public Set(id: UUIDInput, value: V): this {
        this.entries.set(NormalizeUUID(id), value);
        return this;
    }

    public Has(id: UUIDInput): boolean {
        return this.entries.has(NormalizeUUID(id));
    }

    public Delete(id: UUIDInput): boolean {
        return this.entries.delete(NormalizeUUID(id));
    }

    public Clear(): void {
        this.entries.clear();
    }

    public get Size(): number {
        return this.entries.size;
    }

    /** Normalized keys. */
    public Keys(): IterableIterator<string> {
        return this.entries.keys();
    }

    public Values(): IterableIterator<V> {
        return this.entries.values();
    }

    public [Symbol.iterator](): Iterator<[string, V]> {
        return this.entries.entries();
    }
}
