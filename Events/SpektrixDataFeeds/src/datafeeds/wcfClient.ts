import * as http from 'node:http';
import * as https from 'node:https';
import * as tls from 'node:tls';
import { PassThrough } from 'node:stream';
import { DecodeNrbfCustomerStream } from './nrbf.js';
import type {
    CustomerDataFeed,
    DataFeedClient,
    DataFeedClientOptions,
    DataFeedCustomer,
    DataFeedCustomerMerge,
    DataFeedDataProtectionStatement,
    DataFeedDateRange,
    DataFeedLookups,
    DataFeedTag,
    DataFeedTagGroup,
} from './types.js';

const SOAP_ACTION_GET_CUSTOMER_DATA = 'http://system.spektrix.com/api/datafeeds/IDataFeed/GetCustomerData';
const DEFAULT_IDLE_TIMEOUT_MS = 60 * 60 * 1000;

function certError(): Error {
    return Object.assign(
        new Error('The client certificate could not be opened.'),
        { name: 'ClientCertificateError' },
    );
}

function responseError(message: string): Error {
    return Object.assign(new Error(message), { name: 'DataFeedResponseError' });
}

function faultError(faultCode: string): Error {
    return Object.assign(new Error(`Spektrix data feed SOAP fault: ${faultCode}`), {
        name: 'DataFeedFaultError',
        faultCode,
    });
}

function emptyLookups(): DataFeedLookups {
    return { dataProtectionStatements: [], merges: [], tagGroups: [], tags: [] };
}

function formatDateArg(v: Date | string | null | undefined): string | null {
    if (v === null || v === undefined) return null;
    if (v instanceof Date) return v.toISOString();
    return String(v);
}

function escapeXml(s: string): string {
    return s
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&apos;');
}

function unescapeXml(s: string): string {
    return s
        .replace(/&#x([0-9a-fA-F]+);/g, (_m, h: string) => String.fromCodePoint(parseInt(h, 16)))
        .replace(/&#(\d+);/g, (_m, d: string) => String.fromCodePoint(parseInt(d, 10)))
        .replace(/&quot;/g, '"')
        .replace(/&apos;/g, "'")
        .replace(/&gt;/g, '>')
        .replace(/&lt;/g, '<')
        .replace(/&amp;/g, '&');
}

function extractSoapFaultCode(xml: string): string | null {
    if (!/<(?:[\w.-]+:)?Fault\b/i.test(xml)) return null;
    // SOAP 1.1 <faultcode>...</faultcode> or SOAP 1.2 <Code><Value>...</Value></Code>
    const m11 = /<(?:[\w.-]+:)?faultcode\b[^>]*>([\s\S]*?)<\/(?:[\w.-]+:)?faultcode>/i.exec(xml);
    if (m11?.[1]) return unescapeXml(m11[1].trim());
    const m12 = /<(?:[\w.-]+:)?Value\b[^>]*>([\s\S]*?)<\/(?:[\w.-]+:)?Value>/i.exec(xml);
    if (m12?.[1]) return unescapeXml(m12[1].trim());
    return 'Server';
}

function extractBlocks(xml: string, localName: string): string[] {
    const out: string[] = [];
    const re = new RegExp(`<(?:[\\w.-]+:)?${localName}\\b([^>]*)>([\\s\\S]*?)<\\/(?:[\\w.-]+:)?${localName}>`, 'g');
    let match: RegExpExecArray | null;
    while ((match = re.exec(xml)) !== null) {
        out.push(match[2] ?? '');
    }
    return out;
}

function extractTagText(xml: string, localName: string): string | null {
    const nilRe = new RegExp(`<(?:[\\w.-]+:)?${localName}\\b[^>]*\\bnil="true"[^>]*/\\s*>`);
    if (nilRe.test(xml)) return null;
    const re = new RegExp(`<(?:[\\w.-]+:)?${localName}\\b([^>]*)>([\\s\\S]*?)<\\/(?:[\\w.-]+:)?${localName}>`);
    const match = re.exec(xml);
    if (!match) return null;
    if (/\bnil="true"/.test(match[1] ?? '')) return null;
    return unescapeXml((match[2] ?? '').trim());
}

/** Parses `CustomerDataMessage` SOAP headers (`DataProtectionStatements`, `Merges`, `TagGroups`, `Tags`). */
export function ParseCustomerDataSoapHeaders(xml: string): DataFeedLookups {
    const headerBlocks = extractBlocks(xml, 'Header');
    const headerXml = headerBlocks.length > 0 ? headerBlocks.join('\n') : xml;

    const dpsContainer = extractBlocks(headerXml, 'DataProtectionStatements').join('\n');
    const dataProtectionStatements: DataFeedDataProtectionStatement[] = extractBlocks(dpsContainer, 'DataProtectionStatement').map((b) => ({
        id: Number(extractTagText(b, 'Id') ?? 0),
        name: extractTagText(b, 'Name'),
    }));

    const mergesContainer = extractBlocks(headerXml, 'Merges').join('\n');
    const merges: DataFeedCustomerMerge[] = extractBlocks(mergesContainer, 'CustomerMerge').map((b) => ({
        date: extractTagText(b, 'Date') ?? '',
        from: Number(extractTagText(b, 'From') ?? 0),
        to: Number(extractTagText(b, 'To') ?? 0),
    }));

    const tgContainer = extractBlocks(headerXml, 'TagGroups').join('\n');
    const tagGroups: DataFeedTagGroup[] = extractBlocks(tgContainer, 'TagGroup').map((b) => ({
        id: Number(extractTagText(b, 'Id') ?? 0),
        name: extractTagText(b, 'Name'),
    }));

    const tagsContainer = extractBlocks(headerXml, 'Tags').join('\n');
    const tags: DataFeedTag[] = extractBlocks(tagsContainer, 'Tag').map((b) => ({
        id: Number(extractTagText(b, 'Id') ?? 0),
        name: extractTagText(b, 'Name'),
        tagGroupId: Number(extractTagText(b, 'TagGroupId') ?? 0),
    }));

    return { dataProtectionStatements, merges, tagGroups, tags };
}

function parseBoundary(contentType: string): string | null {
    const m = /boundary=(?:"([^"]+)"|([^;\s]+))/i.exec(contentType);
    return m ? (m[1] ?? m[2] ?? null) : null;
}

function buildDateRangeSoapEnvelope(range: DataFeedDateRange): string {
    const fromStr = formatDateArg(range.from);
    const toStr = formatDateArg(range.to);
    const fromXml = fromStr ? `<From>${escapeXml(fromStr)}</From>` : '<From i:nil="true" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"/>';
    const toXml = toStr ? `<To>${escapeXml(toStr)}</To>` : '<To i:nil="true" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"/>';
    return (
        '<?xml version="1.0" encoding="utf-8"?>' +
        '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">' +
        '<s:Body>' +
        '<DateRangeMessage xmlns="http://system.spektrix.com/api/datafeeds/">' +
        fromXml +
        toXml +
        '</DateRangeMessage>' +
        '</s:Body>' +
        '</s:Envelope>'
    );
}

/** Reads header-terminated buffered chunks and turns a streaming HTTP response into incremental multipart parts. */
class BufferedByteReader {
    private pending: Buffer<ArrayBufferLike> = Buffer.alloc(0);
    private done = false;
    private iterator: AsyncIterator<Buffer>;

    constructor(private readonly res: http.IncomingMessage) {
        this.iterator = (async function* () {
            for await (const chunk of res) {
                yield Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk as Uint8Array);
            }
        })();
    }

    private async fill(): Promise<boolean> {
        if (this.done) return false;
        const next = await this.iterator.next();
        if (next.done) {
            this.done = true;
            return false;
        }
        this.pending = this.pending.length === 0 ? next.value : Buffer.concat([this.pending, next.value]);
        return true;
    }

    public async readUntilDelimiter(delim: Buffer, altDelim?: Buffer): Promise<{ before: Buffer; found: boolean }> {
        while (true) {
            let idx = this.pending.indexOf(delim);
            let matchLen = delim.length;
            if (altDelim) {
                const altIdx = this.pending.indexOf(altDelim);
                if (altIdx >= 0 && (idx < 0 || altIdx < idx)) {
                    idx = altIdx;
                    matchLen = altDelim.length;
                }
            }
            if (idx >= 0) {
                const before = this.pending.subarray(0, idx);
                this.pending = this.pending.subarray(idx + matchLen);
                return { before, found: true };
            }
            if (!(await this.fill())) {
                const rest = this.pending;
                this.pending = Buffer.alloc(0);
                return { before: rest, found: false };
            }
        }
    }

    public async startsWithClosingBoundary(): Promise<boolean> {
        while (this.pending.length < 2) {
            if (!(await this.fill())) break;
        }
        return this.pending.length >= 2 && this.pending[0] === 0x2d && this.pending[1] === 0x2d;
    }

    public async readHeaders(): Promise<string | null> {
        while (true) {
            let idx = this.pending.indexOf('\r\n\r\n');
            let sepLen = 4;
            const lfIdx = this.pending.indexOf('\n\n');
            if (lfIdx >= 0 && (idx < 0 || lfIdx < idx)) {
                idx = lfIdx;
                sepLen = 2;
            }
            if (idx >= 0) {
                const headers = this.pending.subarray(0, idx).toString('utf8');
                this.pending = this.pending.subarray(idx + sepLen);
                return headers;
            }
            if (!(await this.fill())) return null;
        }
    }

    /** Yields raw bytes up to `boundary` (`\r\n--boundary` or `--boundary--`), keeping a small tail buffer so split delimiters are matched accurately. */
    public async *streamUntilBoundary(boundaryMarker: Buffer): AsyncGenerator<Uint8Array> {
        const crlfMarker = Buffer.concat([Buffer.from('\r\n'), boundaryMarker]);
        const lfMarker = Buffer.concat([Buffer.from('\n'), boundaryMarker]);
        const keepLen = crlfMarker.length + 2;

        while (true) {
            const crlfIdx = this.pending.indexOf(crlfMarker);
            if (crlfIdx >= 0) {
                if (crlfIdx > 0) yield this.pending.subarray(0, crlfIdx);
                this.pending = this.pending.subarray(crlfIdx + crlfMarker.length);
                return;
            }
            const lfIdx = this.pending.indexOf(lfMarker);
            if (lfIdx >= 0) {
                if (lfIdx > 0) yield this.pending.subarray(0, lfIdx);
                this.pending = this.pending.subarray(lfIdx + lfMarker.length);
                return;
            }
            if (this.pending.length > keepLen) {
                const safeEnd = this.pending.length - keepLen;
                yield this.pending.subarray(0, safeEnd);
                this.pending = this.pending.subarray(safeEnd);
            }
            if (!(await this.fill())) {
                // Check one final time without CR/LF prefix if stream ended abruptly right at marker
                const endIdx = this.pending.indexOf(boundaryMarker);
                if (endIdx >= 0) {
                    if (endIdx > 0) yield this.pending.subarray(0, endIdx);
                    this.pending = Buffer.alloc(0);
                    return;
                }
                if (this.pending.length > 0) {
                    yield this.pending;
                    this.pending = Buffer.alloc(0);
                }
                return;
            }
        }
    }

    public consumePrefixCrlf(): void {
        if (this.pending.subarray(0, 2).equals(Buffer.from('\r\n'))) {
            this.pending = this.pending.subarray(2);
        } else if (this.pending[0] === 0x0a) {
            this.pending = this.pending.subarray(1);
        }
    }

    public async readAllText(): Promise<string> {
        const chunks: Buffer[] = [];
        if (this.pending.length > 0) {
            chunks.push(this.pending);
            this.pending = Buffer.alloc(0);
        }
        while (await this.fill()) {
            chunks.push(this.pending);
            this.pending = Buffer.alloc(0);
        }
        return Buffer.concat(chunks).toString('utf8');
    }
}

/**
 * Default Node WCF SOAP 1.1 / MTOM + MS-NRBF streaming client for Spektrix `IDataFeed.GetCustomerData`.
 * Also supports JSON/NDJSON replay/bridge endpoints when `options.endpoint` serves those content types.
 */
export class SpektrixWcfDataFeedClient implements DataFeedClient {
    constructor(private readonly options: DataFeedClientOptions) {}

    public async getCustomerData(range: DataFeedDateRange = {}, callOptions?: { signal?: AbortSignal }): Promise<CustomerDataFeed> {
        const endpoint =
            this.options.endpoint ??
            `https://api.system.spektrix.com/${encodeURIComponent(this.options.clientName)}/api/datafeeds/datafeeds.svc`;
        const url = new URL(endpoint);
        const isHttps = url.protocol === 'https:';

        if (isHttps) {
            // Validate certificate + passphrase up front so invalid / RC2-3DES exports throw ClientCertificateError clearly.
            try {
                tls.createSecureContext({
                    pfx: Buffer.from(this.options.pfx),
                    passphrase: this.options.passphrase,
                });
            } catch {
                throw certError();
            }
        }

        const soapBody = Buffer.from(buildDateRangeSoapEnvelope(range), 'utf8');
        const idleTimeoutMs = this.options.idleTimeoutMs ?? DEFAULT_IDLE_TIMEOUT_MS;

        const res = await new Promise<http.IncomingMessage>((resolve, reject) => {
            const headers: Record<string, string | number> = {
                'Content-Type': 'text/xml; charset=utf-8',
                SOAPAction: `"${SOAP_ACTION_GET_CUSTOMER_DATA}"`,
                'Content-Length': soapBody.byteLength,
                Accept: 'multipart/related, text/xml, application/x-ndjson, application/json',
            };

            const onError = (err: unknown): void => {
                const msg = err instanceof Error ? err.message : String(err);
                const code = (err as { code?: string })?.code ?? '';
                if (/pkcs12|pfx|mac verify|bad decrypt|unsupported.*cipher|rc2|certificate|ERR_OSSL/i.test(`${msg} ${code}`)) {
                    reject(certError());
                    return;
                }
                if (err instanceof Error && (err.name === 'AbortError' || err.name === 'TimeoutError')) {
                    reject(err);
                    return;
                }
                reject(err);
            };

            const req = isHttps
                ? https.request(
                      url,
                      {
                          method: 'POST',
                          headers,
                          pfx: Buffer.from(this.options.pfx),
                          passphrase: this.options.passphrase,
                          signal: callOptions?.signal,
                          timeout: idleTimeoutMs,
                      },
                      resolve,
                  )
                : http.request(
                      url,
                      {
                          method: 'POST',
                          headers,
                          signal: callOptions?.signal,
                          timeout: idleTimeoutMs,
                      },
                      resolve,
                  );

            req.on('timeout', () => {
                req.destroy(Object.assign(new Error('Request timed out'), { name: 'TimeoutError' }));
            });
            req.on('error', onError);
            req.end(soapBody);
        });

        const contentType = String(res.headers['content-type'] ?? '').toLowerCase();
        const close = (): void => {
            if (!res.destroyed) res.destroy();
        };

        try {
            if (contentType.includes('application/json') || contentType.includes('application/x-ndjson')) {
                return await this.handleJsonResponse(res, contentType, close);
            }

            const boundary = parseBoundary(String(res.headers['content-type'] ?? ''));
            if (res.statusCode && res.statusCode >= 400 && !boundary) {
                const text = await new BufferedByteReader(res).readAllText();
                const code = extractSoapFaultCode(text);
                if (code) throw faultError(code);
                throw responseError(`Spektrix Data Feeds returned HTTP ${res.statusCode}.`);
            }

            if (boundary) {
                return await this.handleMtomResponse(res, boundary, close);
            }

            // Plain SOAP XML response (either fault, inline base64 <Customers>, or empty stream)
            const text = await new BufferedByteReader(res).readAllText();
            const code = extractSoapFaultCode(text);
            if (code) throw faultError(code);
            if (!/<(?:[\w.-]+:)?Envelope\b/i.test(text)) {
                throw responseError('Response was neither multipart MTOM nor a SOAP Envelope.');
            }
            const lookups = ParseCustomerDataSoapHeaders(text);
            const rawB64 = extractTagText(text, 'Customers');
            const trimmedB64 = rawB64?.replace(/\s+/g, '') ?? '';
            async function* streamInline(): AsyncGenerator<DataFeedCustomer> {
                if (trimmedB64.length === 0) return;
                const pt = new PassThrough();
                pt.end(Buffer.from(trimmedB64, 'base64'));
                yield* DecodeNrbfCustomerStream(pt);
            }
            return { ...lookups, customers: streamInline(), close };
        } catch (err) {
            close();
            throw err;
        }
    }

    private async handleMtomResponse(
        res: http.IncomingMessage,
        boundary: string,
        close: () => void,
    ): Promise<CustomerDataFeed> {
        const reader = new BufferedByteReader(res);
        const delim = Buffer.from(`--${boundary}`);

        // Skip preamble up to first "--<boundary>"
        const preamble = await reader.readUntilDelimiter(delim);
        if (!preamble.found) {
            throw responseError('Invalid MTOM response: missing MIME boundary.');
        }
        reader.consumePrefixCrlf();

        // Part 1: SOAP XML Envelope (headers + optional xop:Include)
        const part1Headers = await reader.readHeaders();
        if (part1Headers === null) throw responseError('Invalid MTOM response: missing SOAP part headers.');

        const part1Result = await reader.readUntilDelimiter(
            Buffer.from(`\r\n--${boundary}`),
            Buffer.from(`\n--${boundary}`),
        );
        const soapXml = part1Result.before.toString('utf8');

        const code = extractSoapFaultCode(soapXml);
        if (code) throw faultError(code);
        if (!/<(?:[\w.-]+:)?Envelope\b/i.test(soapXml)) {
            throw responseError('MTOM SOAP part is not a valid SOAP Envelope.');
        }
        const lookups = ParseCustomerDataSoapHeaders(soapXml);

        const hasPart2 = part1Result.found && !(await reader.startsWithClosingBoundary());
        if (!hasPart2) {
            const rawB64 = extractTagText(soapXml, 'Customers')?.replace(/\s+/g, '') ?? '';
            async function* inlineOrEmpty(): AsyncGenerator<DataFeedCustomer> {
                if (rawB64.length === 0) return;
                const pt = new PassThrough();
                pt.end(Buffer.from(rawB64, 'base64'));
                yield* DecodeNrbfCustomerStream(pt);
            }
            return { ...lookups, customers: inlineOrEmpty(), close };
        }

        reader.consumePrefixCrlf();
        const part2Headers = await reader.readHeaders();
        if (part2Headers === null) {
            throw responseError('Invalid MTOM response: missing binary attachment headers.');
        }

        const customers = (async function* (): AsyncGenerator<DataFeedCustomer> {
            try {
                yield* DecodeNrbfCustomerStream(reader.streamUntilBoundary(delim));
            } finally {
                close();
            }
        })();

        return { ...lookups, customers, close };
    }

    private async handleJsonResponse(
        res: http.IncomingMessage,
        contentType: string,
        close: () => void,
    ): Promise<CustomerDataFeed> {
        if (contentType.includes('application/x-ndjson')) {
            const lines = (async function* () {
                let buf = '';
                for await (const chunk of res) {
                    buf += Buffer.isBuffer(chunk) ? chunk.toString('utf8') : String(chunk);
                    let nl = buf.indexOf('\n');
                    while (nl >= 0) {
                        const line = buf.slice(0, nl).trim();
                        buf = buf.slice(nl + 1);
                        if (line.length > 0) yield line;
                        nl = buf.indexOf('\n');
                    }
                }
                if (buf.trim().length > 0) yield buf.trim();
            })();

            const it = lines[Symbol.asyncIterator]();
            const first = await it.next();
            let lookups = emptyLookups();
            const bufferedFirstCustomers: DataFeedCustomer[] = [];
            if (!first.done && typeof first.value === 'string') {
                const parsed = JSON.parse(first.value) as Record<string, unknown>;
                if ('lookups' in parsed && parsed['lookups'] && typeof parsed['lookups'] === 'object') {
                    lookups = parsed['lookups'] as DataFeedLookups;
                } else if ('dataProtectionStatements' in parsed || 'tags' in parsed) {
                    lookups = {
                        dataProtectionStatements: (parsed['dataProtectionStatements'] as DataFeedDataProtectionStatement[]) ?? [],
                        merges: (parsed['merges'] as DataFeedCustomerMerge[]) ?? [],
                        tagGroups: (parsed['tagGroups'] as DataFeedTagGroup[]) ?? [],
                        tags: (parsed['tags'] as DataFeedTag[]) ?? [],
                    };
                } else {
                    bufferedFirstCustomers.push(parsed as unknown as DataFeedCustomer);
                }
            }
            const customers = (async function* (): AsyncGenerator<DataFeedCustomer> {
                try {
                    for (const c of bufferedFirstCustomers) yield c;
                    while (true) {
                        const n = await it.next();
                        if (n.done || typeof n.value !== 'string') break;
                        yield JSON.parse(n.value) as DataFeedCustomer;
                    }
                } finally {
                    close();
                }
            })();
            return { ...lookups, customers, close };
        }

        const text = await new BufferedByteReader(res).readAllText();
        const body = JSON.parse(text) as DataFeedLookups & { customers?: DataFeedCustomer[] };
        const lookups: DataFeedLookups = {
            dataProtectionStatements: body.dataProtectionStatements ?? [],
            merges: body.merges ?? [],
            tagGroups: body.tagGroups ?? [],
            tags: body.tags ?? [],
        };
        async function* jsonCustomers(): AsyncGenerator<DataFeedCustomer> {
            for (const c of body.customers ?? []) yield c;
        }
        return { ...lookups, customers: jsonCustomers(), close };
    }
}
