import type {
    DataFeedAddress,
    DataFeedCustomer,
    DataFeedCustomerAttribute,
    DataFeedOrganisation,
    DataFeedPerson,
    DotNetDateTime,
} from './types.js';

/**
 * Streaming decoder (plus minimal encoder for tests) for Microsoft `.NET BinaryFormatter`
 * (`[MS-NRBF]`) object graphs carried inside Spektrix Data Feeds `GetCustomerData` streams.
 *
 * Supports:
 * - Both 4-byte little-endian length-framed NRBF messages and back-to-back raw NRBF graphs.
 * - Inheritance-mangled C# auto-property backing fields (`Customer+<Id>k__BackingField`,
 *   `<FirstName>k__BackingField`), camelCase/PascalCase properties, and `List<T>` (`_items`/`_size`).
 * - `.NET` 64-bit binary `DateTime` ticks + `DateTimeKind` formatted as round-trip ISO strings.
 */

const RECORD_SERIALIZED_STREAM_HEADER = 0x00;
const RECORD_CLASS_WITH_ID = 0x01;
const RECORD_CLASS_WITH_MEMBERS_AND_TYPES = 0x04;
const RECORD_SYSTEM_CLASS_WITH_MEMBERS_AND_TYPES = 0x05;
const RECORD_BINARY_OBJECT_STRING = 0x06;
const RECORD_BINARY_ARRAY = 0x07;
const RECORD_MEMBER_PRIMITIVE_TYPED = 0x08;
const RECORD_MEMBER_REFERENCE = 0x09;
const RECORD_OBJECT_NULL = 0x0a;
const RECORD_MESSAGE_END = 0x0b;
const RECORD_BINARY_LIBRARY = 0x0c;
const RECORD_OBJECT_NULL_MULTIPLE_256 = 0x0d;
const RECORD_OBJECT_NULL_MULTIPLE = 0x0e;
const RECORD_ARRAY_SINGLE_PRIMITIVE = 0x0f;
const RECORD_ARRAY_SINGLE_OBJECT = 0x10;
const RECORD_ARRAY_SINGLE_STRING = 0x11;

const BIN_PRIMITIVE = 0;
const BIN_STRING = 1;
const BIN_OBJECT = 2;
const BIN_SYSTEM_CLASS = 3;
const BIN_CLASS = 4;
const BIN_OBJECT_ARRAY = 5;
const BIN_STRING_ARRAY = 6;
const BIN_PRIMITIVE_ARRAY = 7;

const PRIM_BOOLEAN = 1;
const PRIM_BYTE = 2;
const PRIM_CHAR = 3;
const PRIM_DECIMAL = 5;
const PRIM_DOUBLE = 6;
const PRIM_INT16 = 7;
const PRIM_INT32 = 8;
const PRIM_INT64 = 9;
const PRIM_SBYTE = 10;
const PRIM_SINGLE = 11;
const PRIM_TIMESPAN = 12;
const PRIM_DATETIME = 13;
const PRIM_UINT16 = 14;
const PRIM_UINT32 = 15;
const PRIM_UINT64 = 16;
const PRIM_NULL = 17;
const PRIM_STRING = 18;

interface MemberSpec {
    name: string;
    binaryType: number;
    primitiveType?: number;
    className?: string;
}

interface ClassSchema {
    name: string;
    members: MemberSpec[];
}

class RefMarker {
    constructor(public readonly id: number) {}
}

class NullSpanMarker {
    constructor(public readonly count: number) {}
}

class NeedMoreBytesError extends Error {}

function responseError(message: string): Error {
    return Object.assign(new Error(message), { name: 'DataFeedResponseError' });
}

class NrbfCursor {
    public pos = 0;
    constructor(private readonly buf: Buffer) {}

    public get remaining(): number {
        return this.buf.length - this.pos;
    }

    public ensure(n: number): void {
        if (this.pos + n > this.buf.length) throw new NeedMoreBytesError();
    }

    public readU8(): number {
        this.ensure(1);
        return this.buf.readUInt8(this.pos++);
    }

    public readI8(): number {
        this.ensure(1);
        return this.buf.readInt8(this.pos++);
    }

    public readI16(): number {
        this.ensure(2);
        const v = this.buf.readInt16LE(this.pos);
        this.pos += 2;
        return v;
    }

    public readU16(): number {
        this.ensure(2);
        const v = this.buf.readUInt16LE(this.pos);
        this.pos += 2;
        return v;
    }

    public readI32(): number {
        this.ensure(4);
        const v = this.buf.readInt32LE(this.pos);
        this.pos += 4;
        return v;
    }

    public readU32(): number {
        this.ensure(4);
        const v = this.buf.readUInt32LE(this.pos);
        this.pos += 4;
        return v;
    }

    public readI64(): bigint {
        this.ensure(8);
        const v = this.buf.readBigInt64LE(this.pos);
        this.pos += 8;
        return v;
    }

    public readU64(): bigint {
        this.ensure(8);
        const v = this.buf.readBigUInt64LE(this.pos);
        this.pos += 8;
        return v;
    }

    public readF32(): number {
        this.ensure(4);
        const v = this.buf.readFloatLE(this.pos);
        this.pos += 4;
        return v;
    }

    public readF64(): number {
        this.ensure(8);
        const v = this.buf.readDoubleLE(this.pos);
        this.pos += 8;
        return v;
    }

    public readVarUint(): number {
        let result = 0;
        let shift = 0;
        for (let i = 0; i < 5; i++) {
            const b = this.readU8();
            result |= (b & 0x7f) << shift;
            if ((b & 0x80) === 0) return result >>> 0;
            shift += 7;
        }
        throw responseError('Invalid NRBF 7-bit string length.');
    }

    public readString(): string {
        const len = this.readVarUint();
        this.ensure(len);
        const str = this.buf.toString('utf8', this.pos, this.pos + len);
        this.pos += len;
        return str;
    }

    public readUtf8Char(): string {
        const b0 = this.readU8();
        let len = 1;
        if ((b0 & 0x80) === 0) len = 1;
        else if ((b0 & 0xe0) === 0xc0) len = 2;
        else if ((b0 & 0xf0) === 0xe0) len = 3;
        else if ((b0 & 0xf8) === 0xf0) len = 4;
        const rest = len - 1;
        this.ensure(rest);
        const slice = Buffer.concat([Buffer.from([b0]), this.buf.subarray(this.pos, this.pos + rest)]);
        this.pos += rest;
        return slice.toString('utf8');
    }
}

/** Converts .NET 64-bit binary DateTime data to round-trip ISO text. */
export function DecodeDotNetBinaryDateTime(raw: bigint): DotNetDateTime {
    const u = BigInt.asUintN(64, raw);
    const kind = Number((u >> 62n) & 0x3n);
    const ticks = u & 0x3fffffffffffffffn;
    const subSec = Number(ticks % 10_000_000n);
    const totalSeconds = ticks / 10_000_000n;
    const secOfDay = Number(totalSeconds % 86400n);
    const daysSince0001 = Number(totalSeconds / 86400n);

    // Civil date from days since 0001-01-01 using Howard Hinnant's civil_from_days shifted from 0000-03-01 (daysSince0001 + 306)
    const z = daysSince0001 + 306;
    const era = Math.floor((z >= 0 ? z : z - 146096) / 146097);
    const doe = z - era * 146097;
    const yoe = Math.floor((doe - Math.floor(doe / 1460) + Math.floor(doe / 36524) - Math.floor(doe / 146096)) / 365);
    const y0 = yoe + era * 400;
    const doy = doe - (365 * yoe + Math.floor(yoe / 4) - Math.floor(yoe / 100));
    const mp = Math.floor((5 * doy + 2) / 153);
    const d = doy - Math.floor((153 * mp + 2) / 5) + 1;
    const m = mp + (mp < 10 ? 3 : -9);
    const y = y0 + (m <= 2 ? 1 : 0);

    const hh = Math.floor(secOfDay / 3600);
    const mm = Math.floor((secOfDay % 3600) / 60);
    const ss = secOfDay % 60;

    const p2 = (n: number): string => String(n).padStart(2, '0');
    const p4 = (n: number): string => String(n).padStart(4, '0');
    const p7 = (n: number): string => String(n).padStart(7, '0');
    return `${p4(y)}-${p2(m)}-${p2(d)}T${p2(hh)}:${p2(mm)}:${p2(ss)}.${p7(subSec)}${kind === 1 ? 'Z' : ''}`;
}

/** Encodes a round-trip .NET ISO string into 64-bit binary DateTime bits for test fixtures. */
export function EncodeDotNetBinaryDateTime(iso: string): bigint {
    const m = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.(\d+))?(Z)?/.exec(iso);
    if (!m) throw new Error(`Unsupported DateTime string: ${iso}`);
    const y = Number(m[1]);
    const mo = Number(m[2]);
    const d = Number(m[3]);
    const hh = Number(m[4]);
    const mm = Number(m[5]);
    const ss = Number(m[6]);
    const frac = (m[7] ?? '').padEnd(7, '0').slice(0, 7);
    const kind = m[8] === 'Z' ? 1n : 0n;

    // inverse civil_from_days
    const adjY = y - (mo <= 2 ? 1 : 0);
    const era = Math.floor((adjY >= 0 ? adjY : adjY - 399) / 400);
    const yoe = adjY - era * 400;
    const doy = Math.floor((153 * (mo + (mo > 2 ? -3 : 9)) + 2) / 5) + d - 1;
    const doe = yoe * 365 + Math.floor(yoe / 4) - Math.floor(yoe / 100) + doy;
    const daysSince0001 = BigInt(era * 146097 + doe - 306);

    const totalSec = daysSince0001 * 86400n + BigInt(hh * 3600 + mm * 60 + ss);
    const ticks = totalSec * 10_000_000n + BigInt(Number(frac));
    return (kind << 62n) | ticks;
}

/** Decodes one complete `[MS-NRBF]` graph starting at buffer offset 0, returning the root JS value + bytes consumed. */
export function DecodeNrbfGraph(buf: Buffer): { value: unknown; bytesRead: number } {
    const c = new NrbfCursor(buf);
    const schemas = new Map<number, ClassSchema>();
    const objects = new Map<number, unknown>();
    let rootId = 0;
    let firstTopLevel: unknown = undefined;
    let hasFirstTopLevel = false;

    const readPrimitive = (primType: number): unknown => {
        switch (primType) {
            case PRIM_BOOLEAN:
                return c.readU8() !== 0;
            case PRIM_BYTE:
                return c.readU8();
            case PRIM_CHAR:
                return c.readUtf8Char();
            case PRIM_DECIMAL: {
                const text = c.readString();
                const n = Number(text);
                return Number.isNaN(n) ? text : n;
            }
            case PRIM_DOUBLE:
                return c.readF64();
            case PRIM_INT16:
                return c.readI16();
            case PRIM_INT32:
                return c.readI32();
            case PRIM_INT64: {
                const v = c.readI64();
                return v >= BigInt(Number.MIN_SAFE_INTEGER) && v <= BigInt(Number.MAX_SAFE_INTEGER) ? Number(v) : v.toString();
            }
            case PRIM_SBYTE:
                return c.readI8();
            case PRIM_SINGLE:
                return c.readF32();
            case PRIM_TIMESPAN:
                return c.readI64().toString();
            case PRIM_DATETIME:
                return DecodeDotNetBinaryDateTime(c.readU64());
            case PRIM_UINT16:
                return c.readU16();
            case PRIM_UINT32:
                return c.readU32();
            case PRIM_UINT64: {
                const v = c.readU64();
                return v <= BigInt(Number.MAX_SAFE_INTEGER) ? Number(v) : v.toString();
            }
            case PRIM_NULL:
                return null;
            case PRIM_STRING:
                return c.readString();
            default:
                throw responseError(`Unsupported NRBF primitive type ${primType}.`);
        }
    };

    const readClassSchema = (hasLibrary: boolean): { objectId: number; schema: ClassSchema } => {
        const objectId = c.readI32();
        const name = c.readString();
        const memberCount = c.readI32();
        const memberNames: string[] = [];
        for (let i = 0; i < memberCount; i++) memberNames.push(c.readString());
        const binaryTypes: number[] = [];
        for (let i = 0; i < memberCount; i++) binaryTypes.push(c.readU8());

        const members: MemberSpec[] = [];
        for (let i = 0; i < memberCount; i++) {
            const bt = binaryTypes[i]!;
            const m: MemberSpec = { name: memberNames[i]!, binaryType: bt };
            if (bt === BIN_PRIMITIVE || bt === BIN_PRIMITIVE_ARRAY) {
                m.primitiveType = c.readU8();
            } else if (bt === BIN_SYSTEM_CLASS) {
                m.className = c.readString();
            } else if (bt === BIN_CLASS) {
                m.className = c.readString();
                c.readI32(); // libraryId
            }
            members.push(m);
        }
        if (hasLibrary) c.readI32(); // libraryId
        const schema = { name, members };
        schemas.set(objectId, schema);
        return { objectId, schema };
    };

    const readClassValues = (objectId: number, schema: ClassSchema): Record<string, unknown> => {
        const obj: Record<string, unknown> = { __nrbfType: schema.name };
        objects.set(objectId, obj);
        for (const member of schema.members) {
            obj[member.name] =
                member.binaryType === BIN_PRIMITIVE
                    ? readPrimitive(member.primitiveType!)
                    : readRecord(false);
        }
        return obj;
    };

    const readSequenceElements = (count: number): unknown[] => {
        const out: unknown[] = [];
        while (out.length < count) {
            const item = readRecord(true);
            if (item instanceof NullSpanMarker) {
                for (let i = 0; i < item.count && out.length < count; i++) out.push(null);
            } else {
                out.push(item);
            }
        }
        return out;
    };

    const readRecord = (allowNullSpan: boolean): unknown => {
        const tag = c.readU8();
        switch (tag) {
            case RECORD_SERIALIZED_STREAM_HEADER: {
                rootId = c.readI32();
                c.readI32(); // headerId
                const major = c.readI32();
                const minor = c.readI32();
                if (major !== 1 || minor !== 0) throw responseError(`Unsupported NRBF stream version ${major}.${minor}.`);
                return undefined;
            }
            case RECORD_BINARY_LIBRARY: {
                c.readI32(); // libraryId
                c.readString(); // libraryName
                return undefined;
            }
            case RECORD_CLASS_WITH_MEMBERS_AND_TYPES: {
                const { objectId, schema } = readClassSchema(true);
                return readClassValues(objectId, schema);
            }
            case RECORD_SYSTEM_CLASS_WITH_MEMBERS_AND_TYPES: {
                const { objectId, schema } = readClassSchema(false);
                return readClassValues(objectId, schema);
            }
            case RECORD_CLASS_WITH_ID: {
                const objectId = c.readI32();
                const metaId = c.readI32();
                const schema = schemas.get(metaId);
                if (!schema) throw responseError(`NRBF ClassWithId references unknown metadata ${metaId}.`);
                return readClassValues(objectId, schema);
            }
            case RECORD_BINARY_OBJECT_STRING: {
                const objectId = c.readI32();
                const val = c.readString();
                objects.set(objectId, val);
                return val;
            }
            case RECORD_MEMBER_PRIMITIVE_TYPED:
                return readPrimitive(c.readU8());
            case RECORD_MEMBER_REFERENCE:
                return new RefMarker(c.readI32());
            case RECORD_OBJECT_NULL:
                return null;
            case RECORD_OBJECT_NULL_MULTIPLE_256:
                if (!allowNullSpan) throw responseError('Unexpected ObjectNullMultiple256.');
                return new NullSpanMarker(c.readU8());
            case RECORD_OBJECT_NULL_MULTIPLE:
                if (!allowNullSpan) throw responseError('Unexpected ObjectNullMultiple.');
                return new NullSpanMarker(c.readI32());
            case RECORD_ARRAY_SINGLE_PRIMITIVE: {
                const objectId = c.readI32();
                const len = c.readI32();
                const prim = c.readU8();
                const arr: unknown[] = [];
                objects.set(objectId, arr);
                for (let i = 0; i < len; i++) arr.push(readPrimitive(prim));
                return arr;
            }
            case RECORD_ARRAY_SINGLE_OBJECT:
            case RECORD_ARRAY_SINGLE_STRING: {
                const objectId = c.readI32();
                const len = c.readI32();
                const arr: unknown[] = [];
                objects.set(objectId, arr);
                arr.push(...readSequenceElements(len));
                return arr;
            }
            case RECORD_BINARY_ARRAY: {
                const objectId = c.readI32();
                const arrayType = c.readU8();
                const rank = c.readI32();
                let total = 1;
                for (let i = 0; i < rank; i++) total *= c.readI32();
                if (arrayType === 3 || arrayType === 4 || arrayType === 5) {
                    for (let i = 0; i < rank; i++) c.readI32(); // lowerBounds
                }
                const bt = c.readU8();
                let prim: number | undefined;
                if (bt === BIN_PRIMITIVE || bt === BIN_PRIMITIVE_ARRAY) prim = c.readU8();
                else if (bt === BIN_SYSTEM_CLASS) c.readString();
                else if (bt === BIN_CLASS) {
                    c.readString();
                    c.readI32();
                }
                const arr: unknown[] = [];
                objects.set(objectId, arr);
                if (bt === BIN_PRIMITIVE && prim !== undefined) {
                    for (let i = 0; i < total; i++) arr.push(readPrimitive(prim));
                } else {
                    arr.push(...readSequenceElements(total));
                }
                return arr;
            }
            case RECORD_MESSAGE_END:
                return MESSAGE_END_SENTINEL;
            default:
                throw responseError(`Unsupported NRBF record type 0x${tag.toString(16)}.`);
        }
    };

    const MESSAGE_END_SENTINEL = Symbol('MessageEnd');

    // First record must be SerializedStreamHeader (0x00)
    if (c.remaining < 17 || buf[0] !== RECORD_SERIALIZED_STREAM_HEADER) {
        throw responseError('Invalid NRBF stream: missing SerializedStreamHeader.');
    }
    readRecord(false);

    while (true) {
        const rec = readRecord(false);
        if (rec === MESSAGE_END_SENTINEL) break;
        if (rec !== undefined && !hasFirstTopLevel) {
            firstTopLevel = rec;
            hasFirstTopLevel = true;
        }
    }

    const resolve = (val: unknown, seen: WeakSet<object>): unknown => {
        if (val instanceof RefMarker) {
            const target = objects.get(val.id);
            return target === undefined ? null : resolve(target, seen);
        }
        if (Array.isArray(val)) {
            if (seen.has(val)) return val;
            seen.add(val);
            for (let i = 0; i < val.length; i++) val[i] = resolve(val[i], seen);
            return val;
        }
        if (val && typeof val === 'object') {
            const obj = val as Record<string, unknown>;
            if (seen.has(obj)) return obj;
            seen.add(obj);
            for (const key of Object.keys(obj)) {
                obj[key] = resolve(obj[key], seen);
            }
            // Unwrap List<T> instances serialized by BinaryFormatter
            const tName = typeof obj['__nrbfType'] === 'string' ? (obj['__nrbfType'] as string) : '';
            if (tName.startsWith('System.Collections.Generic.List`1') && Array.isArray(obj['_items'])) {
                const size = typeof obj['_size'] === 'number' ? obj['_size'] : (obj['_items'] as unknown[]).length;
                return (obj['_items'] as unknown[]).slice(0, size);
            }
            return obj;
        }
        return val;
    };

    const rootRaw = rootId !== 0 && objects.has(rootId) ? objects.get(rootId) : firstTopLevel;
    return { value: resolve(rootRaw, new WeakSet()), bytesRead: c.pos };
}

/** Normalizes C# backing field / inherited property names (`Customer+<Email>k__BackingField` → `email`). */
function normalizePropMap(raw: Record<string, unknown>): Record<string, unknown> {
    const out: Record<string, unknown> = {};
    for (const [key, val] of Object.entries(raw)) {
        if (key === '__nrbfType') continue;
        // e.g. "Customer+<Id>k__BackingField" or "<FirstName>k__BackingField" or "Base+<Foo>k__BackingField"
        const plusIdx = key.lastIndexOf('+');
        let clean = plusIdx >= 0 ? key.slice(plusIdx + 1) : key;
        const backing = /^<([^>]+)>k__BackingField$/.exec(clean);
        if (backing) clean = backing[1]!;
        const lower = clean.charAt(0).toLowerCase() + clean.slice(1);
        if (!(lower in out) || out[lower] === null || out[lower] === undefined) {
            out[lower] = val;
        }
    }
    return out;
}

function asStr(v: unknown): string | null {
    return typeof v === 'string' ? v : null;
}

function asNum(v: unknown): number | null {
    return typeof v === 'number' && Number.isFinite(v) ? v : null;
}

function asIntArray(v: unknown): number[] | null {
    if (!Array.isArray(v)) return null;
    const nums = v.filter((x): x is number => typeof x === 'number' && Number.isFinite(x));
    return nums;
}

function toAddress(v: unknown): DataFeedAddress | null {
    if (!v || typeof v !== 'object') return null;
    const m = normalizePropMap(v as Record<string, unknown>);
    return {
        country: asStr(m['country']),
        county: asStr(m['county']),
        line1: asStr(m['line1']),
        line2: asStr(m['line2']),
        line3: asStr(m['line3']),
        line4: asStr(m['line4']),
        line5: asStr(m['line5']),
        name: asStr(m['name']),
        postcode: asStr(m['postcode']),
        town: asStr(m['town']),
    };
}

function toAttributes(v: unknown): DataFeedCustomerAttribute[] | null {
    if (!Array.isArray(v)) return null;
    return v
        .filter((item): item is Record<string, unknown> => Boolean(item && typeof item === 'object'))
        .map((item) => {
            const m = normalizePropMap(item);
            return { name: asStr(m['name']), value: asStr(m['value']) };
        });
}

/** Converts a decoded NRBF object (`Person`, `Organisation`, or flat DTO) into {@link DataFeedCustomer}. */
export function MapNrbfObjectToCustomer(raw: unknown): DataFeedCustomer | null {
    if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return null;
    const rec = raw as Record<string, unknown>;
    const typeName = typeof rec['__nrbfType'] === 'string' ? (rec['__nrbfType'] as string) : '';
    const m = normalizePropMap(rec);

    const id = asNum(m['id']);
    if (id === null) return null;

    const explicitType = asStr(m['type']);
    const isOrg =
        explicitType === 'Organisation' ||
        /Organisation/i.test(typeName) ||
        ('primaryAddress' in m && !('firstName' in m || 'lastName' in m || 'billingAddress' in m));

    const common = {
        id,
        friendlyId: asStr(m['friendlyId']),
        email: asStr(m['email']),
        phoneNumber: asStr(m['phoneNumber']),
        dateCreated: asStr(m['dateCreated']) ?? '0001-01-01T00:00:00.0000000',
        dateLastUpdated: asStr(m['dateLastUpdated']) ?? '0001-01-01T00:00:00.0000000',
        agreedStatementIds: asIntArray(m['agreedStatementIds']),
        tagIds: asIntArray(m['tagIds']),
        attributes: toAttributes(m['attributes']),
    };

    if (isOrg) {
        const org: DataFeedOrganisation = {
            type: 'Organisation',
            ...common,
            primaryAddress: toAddress(m['primaryAddress']),
            name: asStr(m['name']),
            primaryContactId: asNum(m['primaryContactId']),
        };
        return org;
    }

    const person: DataFeedPerson = {
        type: 'Person',
        ...common,
        billingAddress: toAddress(m['billingAddress']),
        birthDate: asStr(m['birthDate']),
        firstName: asStr(m['firstName']),
        lastName: asStr(m['lastName']),
        mobileNumber: asStr(m['mobileNumber']),
        title: asStr(m['title']),
    };
    return person;
}

function isNrbfHeaderAt(buf: Buffer, offset: number): boolean {
    if (buf.length < offset + 17) return false;
    return (
        buf[offset] === RECORD_SERIALIZED_STREAM_HEADER &&
        buf.readInt32LE(offset + 9) === 1 &&
        buf.readInt32LE(offset + 13) === 0
    );
}

/**
 * Incrementally yields {@link DataFeedCustomer} objects from a chunked binary NRBF stream.
 * Automatically handles both 4-byte LE length-prefixed frames and raw concatenated NRBF graphs,
 * as well as an array wrapper at root.
 */
export async function* DecodeNrbfCustomerStream(chunks: AsyncIterable<Uint8Array>): AsyncGenerator<DataFeedCustomer> {
    let pending: Buffer<ArrayBufferLike> = Buffer.alloc(0);
    let framing: 'unknown' | 'length-prefixed' | 'raw' = 'unknown';

    const yieldDecoded = function* (val: unknown): Generator<DataFeedCustomer> {
        if (Array.isArray(val)) {
            for (const item of val) {
                const c = MapNrbfObjectToCustomer(item);
                if (c) yield c;
            }
        } else {
            const c = MapNrbfObjectToCustomer(val);
            if (c) yield c;
        }
    };

    const drainBuffer = function* (): Generator<DataFeedCustomer> {
        while (pending.length > 0) {
            if (framing === 'unknown') {
                if (pending.length < 21) return;
                if (isNrbfHeaderAt(pending, 4)) {
                    framing = 'length-prefixed';
                } else if (isNrbfHeaderAt(pending, 0)) {
                    framing = 'raw';
                } else {
                    throw responseError('Unexpected binary framing in Spektrix Data Feeds stream.');
                }
            }

            if (framing === 'length-prefixed') {
                if (pending.length < 4) return;
                const frameLen = pending.readUInt32LE(0);
                if (frameLen === 0) {
                    pending = pending.subarray(4);
                    continue;
                }
                if (pending.length < 4 + frameLen) return;
                const frame = pending.subarray(4, 4 + frameLen);
                pending = pending.subarray(4 + frameLen);
                const { value } = DecodeNrbfGraph(frame);
                yield* yieldDecoded(value);
            } else {
                try {
                    const { value, bytesRead } = DecodeNrbfGraph(pending);
                    pending = pending.subarray(bytesRead);
                    yield* yieldDecoded(value);
                } catch (err) {
                    if (err instanceof NeedMoreBytesError) return;
                    throw err;
                }
            }
        }
    };

    for await (const chunk of chunks) {
        if (chunk.byteLength === 0) continue;
        const b = Buffer.from(chunk.buffer, chunk.byteOffset, chunk.byteLength);
        pending = pending.length === 0 ? b : Buffer.concat([pending, b]);
        yield* drainBuffer();
    }

    if (pending.length > 0) {
        // Final drain attempt if a short stream (<21 bytes total) wasn't long enough earlier
        if (framing === 'unknown' && pending.length >= 17 && isNrbfHeaderAt(pending, 0)) {
            framing = 'raw';
        }
        yield* drainBuffer();
        if (pending.length > 0) {
            throw responseError(`Truncated NRBF frame (${pending.length} trailing byte(s)).`);
        }
    }
}

/**
 * Minimal `[MS-NRBF]` serializer for synthetic unit tests (encodes `DataFeedCustomer` as a
 * .NET `Spektrix.DataFeeds.Data.Person` or `Organisation` graph, matching C# backing-field names).
 */
export function EncodeNrbfCustomerForTest(customer: DataFeedCustomer, lengthPrefixed = true): Buffer {
    const parts: Buffer[] = [];
    let nextId = 2;
    const allocId = (): number => nextId++;

    const writeVarUint = (n: number): void => {
        let v = n >>> 0;
        while (v >= 0x80) {
            parts.push(Buffer.from([(v & 0x7f) | 0x80]));
            v >>>= 7;
        }
        parts.push(Buffer.from([v]));
    };

    const writeStr = (s: string): void => {
        const bytes = Buffer.from(s, 'utf8');
        writeVarUint(bytes.length);
        parts.push(bytes);
    };

    const u8 = (v: number): void => {
        parts.push(Buffer.from([v]));
    };
    const i32 = (v: number): void => {
        const b = Buffer.allocUnsafe(4);
        b.writeInt32LE(v, 0);
        parts.push(b);
    };
    const i64u = (v: bigint): void => {
        const b = Buffer.allocUnsafe(8);
        b.writeBigUInt64LE(BigInt.asUintN(64, v), 0);
        parts.push(b);
    };

    const writeObjStringOrNull = (val: string | null): void => {
        if (val === null) {
            u8(RECORD_OBJECT_NULL);
        } else {
            u8(RECORD_BINARY_OBJECT_STRING);
            i32(allocId());
            writeStr(val);
        }
    };

    const writeIntListOrNull = (vals: number[] | null): void => {
        if (vals === null) {
            u8(RECORD_OBJECT_NULL);
            return;
        }
        const listId = allocId();
        const libId = 100;
        u8(RECORD_SYSTEM_CLASS_WITH_MEMBERS_AND_TYPES);
        i32(listId);
        writeStr('System.Collections.Generic.List`1[[System.Int32]]');
        i32(2);
        writeStr('_items');
        writeStr('_size');
        u8(BIN_PRIMITIVE_ARRAY);
        u8(BIN_PRIMITIVE);
        u8(PRIM_INT32);
        u8(PRIM_INT32);
        void libId;
        // _items ArraySinglePrimitive
        u8(RECORD_ARRAY_SINGLE_PRIMITIVE);
        i32(allocId());
        i32(vals.length);
        u8(PRIM_INT32);
        for (const n of vals) i32(n);
        // _size inline int32
        i32(vals.length);
    };

    const writeAddressOrNull = (addr: DataFeedAddress | null): void => {
        if (!addr) {
            u8(RECORD_OBJECT_NULL);
            return;
        }
        u8(RECORD_CLASS_WITH_MEMBERS_AND_TYPES);
        i32(allocId());
        writeStr('Spektrix.DataFeeds.Data.Address');
        const fields: Array<[string, string | null]> = [
            ['<Country>k__BackingField', addr.country],
            ['<County>k__BackingField', addr.county],
            ['<Line1>k__BackingField', addr.line1],
            ['<Line2>k__BackingField', addr.line2],
            ['<Line3>k__BackingField', addr.line3],
            ['<Line4>k__BackingField', addr.line4],
            ['<Line5>k__BackingField', addr.line5],
            ['<Name>k__BackingField', addr.name],
            ['<Postcode>k__BackingField', addr.postcode],
            ['<Town>k__BackingField', addr.town],
        ];
        i32(fields.length);
        for (const [k] of fields) writeStr(k);
        for (let i = 0; i < fields.length; i++) u8(BIN_STRING);
        i32(2); // libraryId
        for (const [, v] of fields) writeObjStringOrNull(v);
    };

    const writeAttributesOrNull = (attrs: DataFeedCustomerAttribute[] | null): void => {
        if (!attrs) {
            u8(RECORD_OBJECT_NULL);
            return;
        }
        u8(RECORD_SYSTEM_CLASS_WITH_MEMBERS_AND_TYPES);
        i32(allocId());
        writeStr('System.Collections.Generic.List`1[[Spektrix.DataFeeds.Data.Attribute]]');
        i32(2);
        writeStr('_items');
        writeStr('_size');
        u8(BIN_OBJECT_ARRAY);
        u8(BIN_PRIMITIVE);
        u8(PRIM_INT32);

        u8(RECORD_ARRAY_SINGLE_OBJECT);
        i32(allocId());
        i32(attrs.length);
        for (const attr of attrs) {
            u8(RECORD_CLASS_WITH_MEMBERS_AND_TYPES);
            i32(allocId());
            writeStr('Spektrix.DataFeeds.Data.Attribute');
            i32(2);
            writeStr('<Name>k__BackingField');
            writeStr('<Value>k__BackingField');
            u8(BIN_STRING);
            u8(BIN_STRING);
            i32(2);
            writeObjStringOrNull(attr.name);
            writeObjStringOrNull(attr.value);
        }
        i32(attrs.length);
    };

    // Header + Library
    u8(RECORD_SERIALIZED_STREAM_HEADER);
    i32(1);
    i32(-1);
    i32(1);
    i32(0);

    u8(RECORD_BINARY_LIBRARY);
    i32(2);
    writeStr('Spektrix.DataFeeds.Data, Version=1.5.1.0');

    const rootId = 1;
    if (customer.type === 'Person') {
        u8(RECORD_CLASS_WITH_MEMBERS_AND_TYPES);
        i32(rootId);
        writeStr('Spektrix.DataFeeds.Data.Person');
        const names = [
            'Customer+<Id>k__BackingField',
            'Customer+<FriendlyId>k__BackingField',
            'Customer+<Email>k__BackingField',
            'Customer+<PhoneNumber>k__BackingField',
            'Customer+<DateCreated>k__BackingField',
            'Customer+<DateLastUpdated>k__BackingField',
            'Customer+<AgreedStatementIds>k__BackingField',
            'Customer+<TagIds>k__BackingField',
            'Customer+<Attributes>k__BackingField',
            '<BillingAddress>k__BackingField',
            '<BirthDate>k__BackingField',
            '<FirstName>k__BackingField',
            '<LastName>k__BackingField',
            '<MobileNumber>k__BackingField',
            '<Title>k__BackingField',
        ];
        i32(names.length);
        for (const n of names) writeStr(n);
        // BinaryTypes: Id(int32), FriendlyId(str), Email(str), Phone(str), DateCreated(dt), DateLastUpdated(dt), Agreed(obj), Tags(obj), Attrs(obj), BillingAddr(obj), BirthDate(obj/boxed dt), First(str), Last(str), Mobile(str), Title(str)
        u8(BIN_PRIMITIVE);
        u8(BIN_STRING);
        u8(BIN_STRING);
        u8(BIN_STRING);
        u8(BIN_PRIMITIVE);
        u8(BIN_PRIMITIVE);
        u8(BIN_OBJECT);
        u8(BIN_OBJECT);
        u8(BIN_OBJECT);
        u8(BIN_OBJECT);
        u8(BIN_OBJECT);
        u8(BIN_STRING);
        u8(BIN_STRING);
        u8(BIN_STRING);
        u8(BIN_STRING);
        // additional infos for primitives only
        u8(PRIM_INT32);
        u8(PRIM_DATETIME);
        u8(PRIM_DATETIME);
        i32(2); // libraryId

        i32(customer.id);
        writeObjStringOrNull(customer.friendlyId);
        writeObjStringOrNull(customer.email);
        writeObjStringOrNull(customer.phoneNumber);
        i64u(EncodeDotNetBinaryDateTime(customer.dateCreated));
        i64u(EncodeDotNetBinaryDateTime(customer.dateLastUpdated));
        writeIntListOrNull(customer.agreedStatementIds);
        writeIntListOrNull(customer.tagIds);
        writeAttributesOrNull(customer.attributes);
        writeAddressOrNull(customer.billingAddress);
        if (customer.birthDate) {
            u8(RECORD_MEMBER_PRIMITIVE_TYPED);
            u8(PRIM_DATETIME);
            i64u(EncodeDotNetBinaryDateTime(customer.birthDate));
        } else {
            u8(RECORD_OBJECT_NULL);
        }
        writeObjStringOrNull(customer.firstName);
        writeObjStringOrNull(customer.lastName);
        writeObjStringOrNull(customer.mobileNumber);
        writeObjStringOrNull(customer.title);
    } else {
        u8(RECORD_CLASS_WITH_MEMBERS_AND_TYPES);
        i32(rootId);
        writeStr('Spektrix.DataFeeds.Data.Organisation');
        const names = [
            'Customer+<Id>k__BackingField',
            'Customer+<FriendlyId>k__BackingField',
            'Customer+<Email>k__BackingField',
            'Customer+<PhoneNumber>k__BackingField',
            'Customer+<DateCreated>k__BackingField',
            'Customer+<DateLastUpdated>k__BackingField',
            'Customer+<AgreedStatementIds>k__BackingField',
            'Customer+<TagIds>k__BackingField',
            'Customer+<Attributes>k__BackingField',
            '<PrimaryAddress>k__BackingField',
            '<Name>k__BackingField',
            '<PrimaryContactId>k__BackingField',
        ];
        i32(names.length);
        for (const n of names) writeStr(n);
        u8(BIN_PRIMITIVE);
        u8(BIN_STRING);
        u8(BIN_STRING);
        u8(BIN_STRING);
        u8(BIN_PRIMITIVE);
        u8(BIN_PRIMITIVE);
        u8(BIN_OBJECT);
        u8(BIN_OBJECT);
        u8(BIN_OBJECT);
        u8(BIN_OBJECT);
        u8(BIN_STRING);
        u8(BIN_OBJECT);
        u8(PRIM_INT32);
        u8(PRIM_DATETIME);
        u8(PRIM_DATETIME);
        i32(2);

        i32(customer.id);
        writeObjStringOrNull(customer.friendlyId);
        writeObjStringOrNull(customer.email);
        writeObjStringOrNull(customer.phoneNumber);
        i64u(EncodeDotNetBinaryDateTime(customer.dateCreated));
        i64u(EncodeDotNetBinaryDateTime(customer.dateLastUpdated));
        writeIntListOrNull(customer.agreedStatementIds);
        writeIntListOrNull(customer.tagIds);
        writeAttributesOrNull(customer.attributes);
        writeAddressOrNull(customer.primaryAddress);
        writeObjStringOrNull(customer.name);
        if (customer.primaryContactId !== null) {
            u8(RECORD_MEMBER_PRIMITIVE_TYPED);
            u8(PRIM_INT32);
            i32(customer.primaryContactId);
        } else {
            u8(RECORD_OBJECT_NULL);
        }
    }

    u8(RECORD_MESSAGE_END);
    const body = Buffer.concat(parts);
    if (!lengthPrefixed) return body;
    const lenPrefix = Buffer.allocUnsafe(4);
    lenPrefix.writeUInt32LE(body.length, 0);
    return Buffer.concat([lenPrefix, body]);
}
