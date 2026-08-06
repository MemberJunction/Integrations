/**
 * GA4 connector tests.
 *
 * The fetch tests drive the REAL `FetchChanges` — cursor resolution, window arithmetic, request
 * assembly, row projection, warning collection and watermark emission all run as they do in
 * production. Only two things are replaced: the clock, and the one method that talks to Google. So a
 * change that breaks how a page is requested or how a window advances fails here, rather than
 * failing in a scheduled run against a live property nobody is watching.
 *
 * The `shipped catalog` block asserts the metadata JSON that actually ships agrees with the TS
 * catalog the connector answers discovery from. Those two are the same schema stated twice, and
 * their drift is silent: the created columns simply stop matching the emitted records and the sync
 * lands nulls rather than failing.
 */
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, it, expect } from 'vitest';
import type { UserInfo } from '@memberjunction/core';
import type { MJCompanyIntegrationEntity } from '@memberjunction/core-entities';
import type { FetchContext } from '@memberjunction/integration-engine';

import { GA4Connector } from '../GA4Connector.js';
import { GA4_OBJECTS, catalogObject, primaryKeyFields } from '../GA4Objects.js';
import {
    DEFAULT_COLD_START_DAYS,
    DEFAULT_LOOKBACK_DAYS,
    DEFAULT_MAX_WINDOW_DAYS,
    normalizePropertyId,
    parseGA4Config,
} from '../GA4Config.js';
import { normalizePrivateKey, parseServiceAccount } from '../GA4ServiceAccount.js';
import {
    isPermissionError,
    isQuotaError,
    type GA4ReportPort,
    type GA4RunReportRequest,
    type GA4RunReportResponse,
} from '../GA4Report.js';
import {
    MAX_EXTERNAL_ID_LENGTH,
    buildExternalID,
    parseGA4Date,
    parseMetric,
    projectRow,
} from '../GA4Rows.js';
import { addDays, formatCursor, initialWindow, nextWindow, parseCursor } from '../GA4Window.js';

// ── Fixtures ──────────────────────────────────────────────────────────────────

const HERE = dirname(fileURLToPath(import.meta.url));
const SHIPPED_METADATA = join(HERE, '..', '..', 'metadata', 'integration', '.ga4.integration.json');

/** A fixed clock, so every window assertion below is an exact date rather than an offset. */
const TODAY = '2026-08-05';
const NOW = new Date(`${TODAY}T14:23:00Z`);

const PROPERTY_ID = '987654321';

const PEM = ['-----BEGIN PRIVATE KEY-----', 'MIIEvQIBADANBg', '-----END PRIVATE KEY-----', ''].join('\n');

const SERVICE_ACCOUNT_JSON = JSON.stringify({
    serviceAccountJSON: {
        type: 'service_account',
        project_id: 'mj-analytics',
        client_email: 'mj-analytics@mj-analytics.iam.gserviceaccount.com',
        private_key: PEM,
    },
});

function companyIntegration(
    overrides: Partial<{ Configuration: string | null; CredentialID: string | null }> = {}
): MJCompanyIntegrationEntity {
    return {
        Configuration: JSON.stringify({ propertyId: PROPERTY_ID }),
        CredentialID: 'CRED-1',
        ...overrides,
    } as unknown as MJCompanyIntegrationEntity;
}

/** Build a GA4 response the way the API does: values positional, everything a string. */
function response(
    rows: Array<{ dims: string[]; metrics: Array<string | null> }>,
    extra: Partial<GA4RunReportResponse> = {}
): GA4RunReportResponse {
    return {
        rows: rows.map((r) => ({
            dimensionValues: r.dims.map((value) => ({ value })),
            metricValues: r.metrics.map((value) => ({ value })),
        })),
        rowCount: rows.length,
        ...extra,
    };
}

/**
 * A PagePerformance row. Metric order matches the catalog:
 * screenPageViews, totalUsers, activeUsers, sessions, engagedSessions, userEngagementDuration, keyEvents.
 */
function pageRow(date: string, path: string, views = '10'): { dims: string[]; metrics: string[] } {
    return { dims: [date, path], metrics: [views, '7', '5', '9', '6', '432', '1'] };
}

/**
 * A connector with the clock pinned and Google replaced.
 *
 * Everything else — `FetchChanges`, `TestConnection`, the catalog, the projection — is the
 * production code path.
 */
class TestGA4Connector extends GA4Connector {
    public Requests: GA4RunReportRequest[] = [];

    constructor(
        private readonly respond: (
            req: GA4RunReportRequest,
            callIndex: number
        ) => GA4RunReportResponse | Promise<never>,
        private readonly credentialValues: string | null = SERVICE_ACCOUNT_JSON
    ) {
        super();
    }

    protected override Now(): Date {
        return NOW;
    }

    protected override async LoadServiceAccount() {
        return parseServiceAccount(this.credentialValues);
    }

    protected override async Report(): Promise<GA4ReportPort> {
        return {
            RunReport: async (req: GA4RunReportRequest) => {
                this.Requests.push(req);
                return this.respond(req, this.Requests.length - 1);
            },
        };
    }
}

function fetchContext(overrides: Partial<FetchContext> = {}): FetchContext {
    return {
        CompanyIntegration: companyIntegration(),
        ObjectName: 'PagePerformance',
        WatermarkValue: null,
        BatchSize: 100,
        ContextUser: {} as UserInfo,
        ...overrides,
    } as FetchContext;
}

// ── Identity ──────────────────────────────────────────────────────────────────

describe('identity', () => {
    it('names the integration exactly as the shipped metadata does', () => {
        const shipped = JSON.parse(readFileSync(SHIPPED_METADATA, 'utf-8')) as Array<{
            fields: Record<string, string>;
        }>;
        expect(new GA4Connector().IntegrationName).toBe(shipped[0].fields.Name);
    });

    it('declares a monotonic watermark, because a date only moves toward today', () => {
        expect(new GA4Connector().MonotonicWatermark).toBe(true);
    });

    it('offers no stable ordering key — GA4 has no seekable sort column', () => {
        expect(new GA4Connector().StableOrderingKey('PagePerformance')).toBeNull();
    });
});

// ── The catalog ───────────────────────────────────────────────────────────────

describe('catalog', () => {
    it('defines exactly the three report grains', () => {
        expect(GA4_OBJECTS.map((o) => o.Name)).toEqual([
            'PagePerformance',
            'UtmPerformance',
            'UtmContentPerformance',
        ]);
    });

    it('keys every object on date first — without it a report has no stable row identity', () => {
        for (const o of GA4_OBJECTS) {
            expect(primaryKeyFields(o)[0], o.Name).toBe('date');
        }
    });

    it('makes the declared key exactly the requested dimension tuple, in request order', () => {
        // The key IS the dimension tuple. A key field GA4 was never asked for would always be blank.
        for (const o of GA4_OBJECTS) {
            expect(primaryKeyFields(o), o.Name).toEqual(o.Dimensions);
        }
    });

    it('backs every declared column with a requested dimension, a requested metric, or the stamp', () => {
        // The anti-phantom-column law: a column nothing can populate lands NULL forever and reads as
        // missing data rather than as a schema mistake.
        for (const o of GA4_OBJECTS) {
            const sources = new Set([...o.Dimensions, ...o.Metrics, 'propertyId']);
            for (const f of o.Fields) {
                expect(sources.has(f.Name), `${o.Name}.${f.Name}`).toBe(true);
            }
        }
    });

    it('declares a column for every requested dimension and metric', () => {
        // The converse: something fetched but not declared is a wasted request and a lost value.
        for (const o of GA4_OBJECTS) {
            const declared = new Set(o.Fields.map((f) => f.Name));
            for (const name of [...o.Dimensions, ...o.Metrics]) {
                expect(declared.has(name), `${o.Name}.${name}`).toBe(true);
            }
        }
    });

    it('ships no ratio metrics — each would be a quotient of two columns already present', () => {
        const ratios = /Rate$|PerUser$|PerSession$|^average/i;
        for (const o of GA4_OBJECTS) {
            expect(o.Metrics.filter((m) => ratios.test(m)), o.Name).toEqual([]);
        }
    });

    it('uses keyEvents, not the conversions metric GA4 deprecated in May 2024', () => {
        for (const o of GA4_OBJECTS) {
            expect(o.Metrics, o.Name).toContain('keyEvents');
            expect(o.Metrics, o.Name).not.toContain('conversions');
        }
    });

    it('never mixes first-user attribution into a session-scoped report', () => {
        for (const o of GA4_OBJECTS) {
            expect(o.Dimensions.filter((d) => d.startsWith('firstUser')), o.Name).toEqual([]);
        }
    });

    it('emits an ExternalID that fits ExternalSystemRecordID even at every declared max length', () => {
        // nvarchar(750). The declared lengths are what the DB will actually accept, so the worst
        // case is computed from them rather than from a typical value. Both campaign grains blow
        // past 750 when joined — three or four 255-char free-text values — which is precisely the
        // case the digest fallback exists for.
        for (const o of GA4_OBJECTS) {
            const worstValues = o.Fields.filter((f) => f.IsPrimaryKey).map((f) =>
                'x'.repeat(f.Length ?? 0)
            );
            expect(buildExternalID(worstValues).length, o.Name).toBeLessThanOrEqual(750);
        }
    });

    it('keeps the page grain readable — its key cannot overflow, so it never takes the digest', () => {
        const page = catalogObject('PagePerformance');
        const worst = page.Fields.filter((f) => f.IsPrimaryKey).reduce(
            (sum, f) => sum + (f.Length ?? 0) + 1,
            -1
        );
        expect(worst).toBeLessThanOrEqual(MAX_EXTERNAL_ID_LENGTH);
    });

    it('throws for an unknown object, naming the ones that exist', () => {
        expect(() => catalogObject('Sessions')).toThrow(
            /PagePerformance, UtmPerformance, UtmContentPerformance/
        );
    });

    it('makes the finer campaign grain a strict superset of the coarser one', () => {
        // If that ever stops being true, the claim that its additive metrics roll up stops being
        // true with it.
        const coarse = catalogObject('UtmPerformance').Dimensions;
        const fine = catalogObject('UtmContentPerformance').Dimensions;
        expect(fine.slice(0, coarse.length)).toEqual(coarse);
        expect(fine).toHaveLength(coarse.length + 1);
    });
});

// ── The shipped metadata ──────────────────────────────────────────────────────

describe('shipped catalog', () => {
    const shipped = JSON.parse(readFileSync(SHIPPED_METADATA, 'utf-8')) as Array<{
        fields: Record<string, unknown>;
        relatedEntities: {
            'MJ: Integration Objects': Array<{
                fields: Record<string, unknown>;
                relatedEntities: {
                    'MJ: Integration Object Fields': Array<{ fields: Record<string, unknown> }>;
                };
            }>;
        };
    }>;
    const root = shipped[0];
    const objects = root.relatedEntities['MJ: Integration Objects'];

    it('ships one record per catalog object, in catalog order', () => {
        expect(objects.map((o) => o.fields.Name)).toEqual(GA4_OBJECTS.map((o) => o.Name));
    });

    it('ships one field record per catalog field, with matching types and key flags', () => {
        for (const [i, o] of objects.entries()) {
            const catalog = GA4_OBJECTS[i];
            const fields = o.relatedEntities['MJ: Integration Object Fields'];
            expect(fields.map((f) => f.fields.Name), catalog.Name).toEqual(catalog.Fields.map((f) => f.Name));
            for (const [j, f] of fields.entries()) {
                const label = `${catalog.Name}.${catalog.Fields[j].Name}`;
                expect(f.fields.Type, label).toBe(catalog.Fields[j].Type);
                expect(f.fields.IsPrimaryKey, label).toBe(catalog.Fields[j].IsPrimaryKey);
                expect(f.fields.AllowsNull, label).toBe(catalog.Fields[j].AllowsNull);
            }
        }
    });

    it('points ClassName and ImportPath at the published package name', () => {
        expect(root.fields.ClassName).toBe('@memberjunction/connector-ga4');
        expect(root.fields.ImportPath).toBe('@memberjunction/connector-ga4');
    });

    it('looks the credential type up by name rather than hardcoding an ID', () => {
        expect(root.fields.CredentialTypeID).toBe(
            '@lookup:MJ: Credential Types.Name=Google Service Account'
        );
    });

    it('declares an incremental watermark field on every object, and it is date', () => {
        for (const o of objects) {
            expect(o.fields.SupportsIncrementalSync, String(o.fields.Name)).toBe(true);
            expect(o.fields.IncrementalWatermarkField, String(o.fields.Name)).toBe('date');
        }
    });

    it('declares every object read-only', () => {
        for (const o of objects) expect(o.fields.SupportsWrite, String(o.fields.Name)).toBe(false);
    });

    it('keeps every Description within the nvarchar(255) that would fail the push', () => {
        const check = (v: unknown, label: string) =>
            expect(String(v ?? '').length, label).toBeLessThanOrEqual(255);
        check(root.fields.Description, 'Integration');
        for (const o of objects) {
            check(o.fields.Description, String(o.fields.Name));
            for (const f of o.relatedEntities['MJ: Integration Object Fields']) {
                check(f.fields.Description, `${String(o.fields.Name)}.${String(f.fields.Name)}`);
            }
        }
    });
});

// ── Configuration ─────────────────────────────────────────────────────────────

describe('configuration', () => {
    it('requires a property id, and says which number it means', () => {
        expect(() => parseGA4Config('{}')).toThrow(/PROPERTY ID/);
        expect(() => parseGA4Config(null)).toThrow(/propertyId is required/);
    });

    it('accepts the property id as a string, a number, or the properties/ form people paste', () => {
        expect(normalizePropertyId('123')).toBe('123');
        expect(normalizePropertyId(123)).toBe('123');
        expect(normalizePropertyId(' properties/123 ')).toBe('123');
    });

    it('rejects a measurement id — querying the wrong thing silently is worse than failing setup', () => {
        expect(normalizePropertyId('G-ABC1234')).toBeNull();
        expect(() => parseGA4Config('{"propertyId":"G-ABC1234"}')).toThrow(/not the measurement id/);
    });

    it('defaults the tunables rather than failing on a malformed one', () => {
        const c = parseGA4Config('{"propertyId":"1","lookbackDays":"nonsense","maxWindowDays":null}');
        expect(c.lookbackDays).toBe(DEFAULT_LOOKBACK_DAYS);
        expect(c.maxWindowDays).toBe(DEFAULT_MAX_WINDOW_DAYS);
        expect(c.startDate).toBeNull();
    });

    it('clamps the tunables into their supported range', () => {
        expect(parseGA4Config('{"propertyId":"1","lookbackDays":100000}').lookbackDays).toBe(400);
        expect(parseGA4Config('{"propertyId":"1","lookbackDays":-5}').lookbackDays).toBe(0);
        expect(parseGA4Config('{"propertyId":"1","maxWindowDays":0}').maxWindowDays).toBe(1);
    });

    it('ignores a startDate that is not an ISO date', () => {
        expect(parseGA4Config('{"propertyId":"1","startDate":"last year"}').startDate).toBeNull();
    });

    it('treats Configuration that is not JSON as empty, then fails on the missing property id', () => {
        expect(() => parseGA4Config('not json')).toThrow(/propertyId is required/);
    });
});

// ── The service-account key ───────────────────────────────────────────────────

describe('service account', () => {
    it('accepts the key wrapped under serviceAccountJSON', () => {
        const a = parseServiceAccount(SERVICE_ACCOUNT_JSON);
        expect(a.client_email).toBe('mj-analytics@mj-analytics.iam.gserviceaccount.com');
        expect(a.private_key).toContain('BEGIN PRIVATE KEY');
    });

    it('accepts the downloaded key file pasted at the top level, unwrapped', () => {
        const a = parseServiceAccount(
            JSON.stringify({ client_email: 'x@y.iam.gserviceaccount.com', private_key: PEM })
        );
        expect(a.client_email).toBe('x@y.iam.gserviceaccount.com');
    });

    it('accepts the nested key stored as an escaped JSON string', () => {
        const inner = JSON.stringify({ client_email: 'x@y.iam.gserviceaccount.com', private_key: PEM });
        const a = parseServiceAccount(JSON.stringify({ serviceAccountJSON: inner }));
        expect(a.client_email).toBe('x@y.iam.gserviceaccount.com');
    });

    it('restores newlines that a JSON round-trip turned into literal escapes', () => {
        // The single most common GA4 credential failure. Left as-is it surfaces as an OpenSSL
        // decoder error several layers below anything that mentions GA4.
        const flattened = PEM.replace(/\n/g, '\\n');
        expect(flattened).not.toContain('\n');
        expect(normalizePrivateKey(flattened)).toBe(PEM.trim());
    });

    it('leaves an already-unescaped key alone', () => {
        expect(normalizePrivateKey(PEM)).toBe(PEM.trim());
    });

    it('names the missing piece when the credential holds something else', () => {
        expect(() => parseServiceAccount('{}')).toThrow(/client_email and private_key/);
        expect(() => parseServiceAccount(null)).toThrow(/no credential is linked/);
    });

    it('rejects a private_key_id pasted where the key belongs', () => {
        expect(() =>
            parseServiceAccount(JSON.stringify({ client_email: 'a@b.com', private_key: 'a1b2c3d4e5' }))
        ).toThrow(/BEGIN PRIVATE KEY/);
    });
});

// ── Windows and the cursor ────────────────────────────────────────────────────

describe('date windows', () => {
    const config = parseGA4Config('{"propertyId":"1"}');

    it('opens a cold start at the configured startDate', () => {
        const c = parseGA4Config('{"propertyId":"1","startDate":"2026-01-01"}');
        expect(initialWindow(c, null, TODAY).From).toBe('2026-01-01');
    });

    it('opens a cold start at the retention horizon when no startDate is set', () => {
        expect(initialWindow(config, null, TODAY).From).toBe(addDays(TODAY, -DEFAULT_COLD_START_DAYS));
    });

    it('reopens the window behind the watermark, because GA4 keeps revising recent days', () => {
        expect(initialWindow(config, '2026-07-01', TODAY).From).toBe('2026-06-28');
    });

    it('does not let the lookback reach behind the configured startDate', () => {
        const c = parseGA4Config('{"propertyId":"1","startDate":"2026-06-30"}');
        expect(initialWindow(c, '2026-07-01', TODAY).From).toBe('2026-06-30');
    });

    it('caps a window at maxWindowDays, inclusive of both ends', () => {
        const c = parseGA4Config('{"propertyId":"1","startDate":"2026-01-01","maxWindowDays":10}');
        expect(initialWindow(c, null, TODAY)).toEqual({ From: '2026-01-01', To: '2026-01-10' });
    });

    it('never runs a window past today', () => {
        expect(initialWindow(config, addDays(TODAY, -1), TODAY).To).toBe(TODAY);
    });

    it('walks forward one window at a time and stops at today', () => {
        const c = parseGA4Config('{"propertyId":"1","maxWindowDays":10}');
        let w = { From: '2026-07-01', To: '2026-07-10' };
        const seen: string[] = [];
        for (let i = 0; i < 10; i++) {
            const n = nextWindow(w, c, TODAY);
            if (!n) break;
            seen.push(`${n.From}..${n.To}`);
            w = n;
        }
        expect(seen).toEqual([
            '2026-07-11..2026-07-20',
            '2026-07-21..2026-07-30',
            '2026-07-31..2026-08-05',
        ]);
        expect(nextWindow(w, c, TODAY)).toBeNull();
    });

    it('handles a lookback of zero, for a property whose data is already final', () => {
        const c = parseGA4Config('{"propertyId":"1","lookbackDays":0}');
        expect(initialWindow(c, '2026-07-01', TODAY).From).toBe('2026-07-01');
    });

    it('clamps a watermark in the future back to today rather than inverting the window', () => {
        const c = parseGA4Config('{"propertyId":"1","lookbackDays":0}');
        expect(initialWindow(c, '2030-01-01', TODAY)).toEqual({ From: TODAY, To: TODAY });
    });

    it('accepts a watermark carrying a time component', () => {
        expect(initialWindow(config, '2026-07-01T00:00:00Z', TODAY).From).toBe('2026-06-28');
    });
});

describe('cursor', () => {
    it('round-trips', () => {
        const c = { Today: TODAY, From: '2026-07-01', To: '2026-07-10', Offset: 400 };
        expect(parseCursor(formatCursor(c))).toEqual(c);
    });

    it('returns null for anything it cannot trust, so the object restarts from the watermark', () => {
        expect(parseCursor(undefined)).toBeNull();
        expect(parseCursor('')).toBeNull();
        expect(parseCursor('a|b|c')).toBeNull();
        expect(parseCursor(`${TODAY}|nope|2026-07-10|0`)).toBeNull();
        expect(parseCursor(`${TODAY}|2026-07-10|2026-07-01|0`)).toBeNull(); // inverted range
        expect(parseCursor(`${TODAY}|2026-07-01|2026-07-10|-1`)).toBeNull();
        expect(parseCursor(`${TODAY}|2026-07-01|2026-07-10|1.5`)).toBeNull();
    });
});

// ── Row projection ────────────────────────────────────────────────────────────

describe('row projection', () => {
    const page = catalogObject('PagePerformance');

    it('reads values positionally, because GA4 sends the names only in the headers', () => {
        const p = projectRow(page, response([pageRow('20260714', '/pricing', '42')]).rows![0], PROPERTY_ID)!;
        expect(p.Record.Fields).toEqual({
            date: '2026-07-14',
            pagePath: '/pricing',
            screenPageViews: 42,
            totalUsers: 7,
            activeUsers: 5,
            sessions: 9,
            engagedSessions: 6,
            userEngagementDuration: 432,
            keyEvents: 1,
            propertyId: PROPERTY_ID,
        });
    });

    it('builds ExternalID as the key fields joined on the pipe the engine expects', () => {
        const p = projectRow(page, response([pageRow('20260714', '/pricing')]).rows![0], PROPERTY_ID)!;
        expect(p.Record.ExternalID).toBe('2026-07-14|/pricing');
    });

    it('normalizes GA4 YYYYMMDD into a real date', () => {
        expect(parseGA4Date('20260714')).toBe('2026-07-14');
    });

    it('rejects a date that only looks like one', () => {
        // Date.parse would roll 2026-02-31 forward into March and land the row under a day GA4 never
        // reported.
        expect(parseGA4Date('20260231')).toBeNull();
        expect(parseGA4Date('2026-07-14')).toBeNull();
        expect(parseGA4Date('(other)')).toBeNull();
    });

    it('keeps an absent metric null rather than calling it zero', () => {
        expect(parseMetric('')).toBeNull();
        expect(parseMetric(null)).toBeNull();
        expect(parseMetric('not a number')).toBeNull();
        expect(parseMetric('0')).toBe(0);
        expect(parseMetric('1.5')).toBe(1.5);
    });

    it('drops a row whose date GA4 replaced with a sentinel — it has no identity to upsert', () => {
        expect(
            projectRow(page, response([{ dims: ['(other)', '/x'], metrics: [] }]).rows![0], PROPERTY_ID)
        ).toBeNull();
    });

    it('keeps an (other) row when the collapsed dimension is not the key date, but flags it', () => {
        const p = projectRow(page, response([pageRow('20260714', '(other)')]).rows![0], PROPERTY_ID)!;
        expect(p.IsOtherRow).toBe(true);
        expect(p.Record.Fields.pagePath).toBe('(other)');
    });

    it('substitutes a deterministic digest when a key would overflow the record map column', () => {
        // utm_campaign and utm_content are free text on someone else's tracking template. Truncating
        // would merge two distinct campaigns into one row; the digest keeps them apart.
        const long = 'x'.repeat(MAX_EXTERNAL_ID_LENGTH);
        const first = buildExternalID(['2026-07-14', long]);
        expect(first.startsWith('ga4:')).toBe(true);
        expect(first.length).toBeLessThan(750);
        expect(buildExternalID(['2026-07-14', long])).toBe(first);
        expect(buildExternalID(['2026-07-15', long])).not.toBe(first);
    });

    it('leaves a normal key readable', () => {
        expect(buildExternalID(['2026-07-14', '/a'])).toBe('2026-07-14|/a');
    });

    it('preserves GA4 sentinels rather than turning them into nulls', () => {
        const utm = catalogObject('UtmPerformance');
        const row = {
            dims: ['20260714', '(not set)', '(direct)', '(none)'],
            metrics: ['1', '1', '1', '1', '1', '1', '1'],
        };
        const p = projectRow(utm, response([row]).rows![0], PROPERTY_ID)!;
        expect(p.Record.Fields.sessionCampaignName).toBe('(not set)');
        expect(p.Record.ExternalID).toBe('2026-07-14|(not set)|(direct)|(none)');
    });

    it('fills an empty key dimension with (not set) so the row can actually be written', () => {
        // Untagged traffic (direct visits, email-signature links) arrives with an empty campaign
        // and medium. An empty key component does not survive the write: MJ's generated spCreate
        // inserts and then re-selects by primary key, empty is stored as NULL for a nullable
        // column, and `= NULL` matches nothing — the create comes back as "no rows returned from
        // SQL" and the row is lost. Observed live on AIDP against key
        // `2026-08-05||email_signature|`, which failed the entire GA4 run.
        const utm = catalogObject('UtmPerformance');
        const row = {
            dims: ['20260805', '', 'email_signature', ''],
            metrics: ['1', '1', '1', '1', '1', '1', '1'],
        };
        const p = projectRow(utm, response([row]).rows![0], PROPERTY_ID)!;

        expect(p.Record.Fields.sessionCampaignName).toBe('(not set)');
        expect(p.Record.Fields.sessionMedium).toBe('(not set)');
        expect(p.Record.Fields.sessionSource).toBe('email_signature');
        expect(p.Record.ExternalID).toBe('2026-08-05|(not set)|email_signature|(not set)');
    });

    it('leaves a non-key dimension empty — only key components need a stand-in', () => {
        // Scoped to primary-key components on purpose: an empty non-key dimension is a truthful
        // "no value" that writes without issue, so substituting there would invent data.
        //
        // Every dimension on every shipped object is currently a key component, so this branch has
        // no natural fixture. Rather than assert on an object that happens to be all-key today —
        // which would silently stop testing anything the moment that changed — derive one by
        // demoting a single field, so the assertion is about the RULE and not about the catalog.
        const base = catalogObject('UtmContentPerformance');
        const withNonKeyDim = {
            ...base,
            Fields: base.Fields.map((f) =>
                f.Name === 'sessionManualAdContent' ? { ...f, IsPrimaryKey: false } : f
            ),
        };
        const row = {
            dims: ['20260805', '', 'email_signature', '', ''],
            metrics: ['1', '1', '1', '1', '1', '1', '1'],
        };
        const p = projectRow(withNonKeyDim, response([row]).rows![0], PROPERTY_ID)!;

        // the demoted dimension keeps its empty value …
        expect(p.Record.Fields.sessionManualAdContent).toBe('');
        // … while the still-key components are filled, and it drops out of the key entirely
        expect(p.Record.Fields.sessionCampaignName).toBe('(not set)');
        expect(p.Record.ExternalID).toBe('2026-08-05|(not set)|email_signature|(not set)');
    });
});

// ── The fetch loop, end to end ────────────────────────────────────────────────

describe('fetch', () => {
    it("asks GA4 for exactly the catalog's dimensions and metrics, in order", async () => {
        const c = new TestGA4Connector(() => response([]));
        await c.FetchChanges(fetchContext({ ObjectName: 'UtmContentPerformance' }));
        const obj = catalogObject('UtmContentPerformance');
        expect(c.Requests[0].dimensions.map((d) => d.name)).toEqual(obj.Dimensions);
        expect(c.Requests[0].metrics.map((m) => m.name)).toEqual(obj.Metrics);
        expect(c.Requests[0].property).toBe(`properties/${PROPERTY_ID}`);
    });

    it('issues exactly one request per call — the engine allows 30s and does not cancel an overrun', async () => {
        const c = new TestGA4Connector(() =>
            response(
                Array.from({ length: 100 }, (_, i) => pageRow('20260714', `/p${i}`)),
                { rowCount: 5000 }
            )
        );
        await c.FetchChanges(fetchContext());
        expect(c.Requests).toHaveLength(1);
    });

    it('requests the batch size as the page limit, and pages by offset within a window', async () => {
        const c = new TestGA4Connector((_req, i) =>
            response(
                Array.from({ length: 100 }, (_, n) => pageRow('20260714', `/page-${i}-${n}`)),
                { rowCount: 250 }
            )
        );

        const ctx = fetchContext({ WatermarkValue: '2026-08-01' });
        const first = await c.FetchChanges(ctx);
        expect(c.Requests[0].limit).toBe(100);
        expect(c.Requests[0].offset).toBe(0);
        expect(first.HasMore).toBe(true);
        expect(first.Records).toHaveLength(100);
        expect(first.NewWatermarkValue).toBeUndefined();

        const second = await c.FetchChanges({ ...ctx, CurrentCursor: first.NextCursor });
        expect(c.Requests[1].offset).toBe(100);
        // Same window on the second page — the range must not be recomputed mid-run.
        expect(c.Requests[1].dateRanges).toEqual(c.Requests[0].dateRanges);
        expect(second.HasMore).toBe(true);
    });

    it('opens the first window behind the watermark and ends it at today', async () => {
        const c = new TestGA4Connector(() => response([]));
        await c.FetchChanges(fetchContext({ WatermarkValue: '2026-08-01' }));
        expect(c.Requests[0].dateRanges).toEqual([{ startDate: '2026-07-29', endDate: TODAY }]);
    });

    it('advances to the next window once one is exhausted, inside the same run', async () => {
        const config = JSON.stringify({ propertyId: PROPERTY_ID, maxWindowDays: 10, startDate: '2026-07-01' });
        const c = new TestGA4Connector(() => response([pageRow('20260701', '/a')]));
        const ctx = fetchContext({ CompanyIntegration: companyIntegration({ Configuration: config }) });

        const first = await c.FetchChanges(ctx);
        expect(c.Requests[0].dateRanges).toEqual([{ startDate: '2026-07-01', endDate: '2026-07-10' }]);
        expect(first.HasMore).toBe(true);

        const second = await c.FetchChanges({ ...ctx, CurrentCursor: first.NextCursor });
        expect(c.Requests[1].dateRanges).toEqual([{ startDate: '2026-07-11', endDate: '2026-07-20' }]);
        expect(c.Requests[1].offset).toBe(0);
        expect(second.NewWatermarkValue).toBeUndefined();
    });

    it('emits the watermark only when the final window is done', async () => {
        const config = JSON.stringify({ propertyId: PROPERTY_ID, maxWindowDays: 400, startDate: '2026-08-01' });
        const c = new TestGA4Connector(() => response([pageRow('20260801', '/a')]));
        const result = await c.FetchChanges(
            fetchContext({ CompanyIntegration: companyIntegration({ Configuration: config }) })
        );
        expect(c.Requests[0].dateRanges).toEqual([{ startDate: '2026-08-01', endDate: TODAY }]);
        expect(result.HasMore).toBe(false);
        expect(result.NextCursor).toBeUndefined();
        expect(result.NewWatermarkValue).toBe(TODAY);
    });

    it('advances the watermark to today even when the newest days had no traffic', async () => {
        // Using the data's own maximum date instead would strand the watermark behind a quiet
        // weekend and re-read the same empty range on every run.
        const c = new TestGA4Connector(() => response([pageRow('20260710', '/a')]));
        const result = await c.FetchChanges(fetchContext({ WatermarkValue: '2026-08-04' }));
        expect(result.NewWatermarkValue).toBe(TODAY);
    });

    it('walks a whole cold backfill to completion in one run', async () => {
        const config = JSON.stringify({ propertyId: PROPERTY_ID, maxWindowDays: 30, startDate: '2026-05-01' });
        const c = new TestGA4Connector(() => response([pageRow('20260501', '/a')]));
        const ctx = fetchContext({ CompanyIntegration: companyIntegration({ Configuration: config }) });

        let result = await c.FetchChanges(ctx);
        let guard = 0;
        while (result.HasMore && guard++ < 50) {
            result = await c.FetchChanges({ ...ctx, CurrentCursor: result.NextCursor });
        }
        expect(result.HasMore).toBe(false);
        expect(result.NewWatermarkValue).toBe(TODAY);
        // 2026-05-01 .. 2026-08-05 in 30-day windows.
        expect(c.Requests.map((r) => r.dateRanges[0].startDate)).toEqual([
            '2026-05-01',
            '2026-05-31',
            '2026-06-30',
            '2026-07-30',
        ]);
        expect(c.Requests.at(-1)!.dateRanges[0].endDate).toBe(TODAY);
    });

    it('treats an empty page as the end of a window under any response shape', async () => {
        // rowCount deliberately lies here: a response that claims more rows but returns none must
        // still terminate rather than loop on the same offset forever.
        const c = new TestGA4Connector(() => response([], { rowCount: 9999 }));
        const result = await c.FetchChanges(fetchContext({ WatermarkValue: '2026-08-04' }));
        expect(result.HasMore).toBe(false);
        expect(result.NewWatermarkValue).toBe(TODAY);
    });

    it('ends a window when rowCount is missing and the page came up short', async () => {
        const c = new TestGA4Connector(() => ({ rows: response([pageRow('20260804', '/a')]).rows }));
        const result = await c.FetchChanges(fetchContext({ WatermarkValue: '2026-08-04' }));
        expect(result.HasMore).toBe(false);
    });

    it('restarts from the watermark when handed a corrupt cursor rather than stranding the object', async () => {
        const c = new TestGA4Connector(() => response([]));
        await c.FetchChanges(fetchContext({ WatermarkValue: '2026-08-01', CurrentCursor: 'garbage' }));
        expect(c.Requests[0].dateRanges).toEqual([{ startDate: '2026-07-29', endDate: TODAY }]);
        expect(c.Requests[0].offset).toBe(0);
    });

    it('stamps the property id onto every record', async () => {
        const c = new TestGA4Connector(() => response([pageRow('20260804', '/a')]));
        const result = await c.FetchChanges(fetchContext({ WatermarkValue: '2026-08-04' }));
        expect(result.Records[0].Fields.propertyId).toBe(PROPERTY_ID);
        expect(result.Records[0].ObjectType).toBe('PagePerformance');
    });

    it('names the property and the window when Google fails', async () => {
        const c = new TestGA4Connector(() => Promise.reject(new Error('backend error')));
        await expect(c.FetchChanges(fetchContext({ WatermarkValue: '2026-08-04' }))).rejects.toThrow(
            /PagePerformance on property 987654321 over 2026-08-01\.\.2026-08-05 \(offset 0\)/
        );
    });

    it('rejects an unknown object before issuing a request', async () => {
        const c = new TestGA4Connector(() => response([]));
        await expect(c.FetchChanges(fetchContext({ ObjectName: 'Sessions' }))).rejects.toThrow(
            /unknown object/
        );
        expect(c.Requests).toHaveLength(0);
    });

    it("caps the page limit at GA4's own maximum however large the batch is", async () => {
        const c = new TestGA4Connector(() => response([]));
        await c.FetchChanges(fetchContext({ BatchSize: 999_999 }));
        expect(c.Requests[0].limit).toBe(250_000);
    });
});

// ── Warnings ──────────────────────────────────────────────────────────────────

describe('warnings', () => {
    const codes = (r: { Warnings?: Array<{ Code: string }> }) => (r.Warnings ?? []).map((w) => w.Code);

    it('warns when GA4 collapsed rows into (other), but still lands them', async () => {
        const c = new TestGA4Connector(() =>
            response([pageRow('20260804', '(other)')], { metadata: { dataLossFromOtherRow: true } })
        );
        const result = await c.FetchChanges(fetchContext({ WatermarkValue: '2026-08-04' }));
        expect(codes(result)).toContain('CARDINALITY_LIMIT');
        // Dropping them would silently shrink every total computed from this table.
        expect(result.Records).toHaveLength(1);
    });

    it('warns when GA4 withheld rows for privacy thresholding', async () => {
        const c = new TestGA4Connector(() => response([], { metadata: { subjectToThresholding: true } }));
        const result = await c.FetchChanges(fetchContext({ WatermarkValue: '2026-08-04' }));
        expect(codes(result)).toContain('DATA_THRESHOLDED');
    });

    it('warns when a row could not be keyed, and still lands the rest', async () => {
        const c = new TestGA4Connector(() =>
            response([pageRow('20260804', '/a'), { dims: ['(other)', '/b'], metrics: [] }])
        );
        const result = await c.FetchChanges(fetchContext({ WatermarkValue: '2026-08-04' }));
        expect(codes(result)).toContain('UNKEYABLE_ROW');
        expect(result.Records).toHaveLength(1);
    });

    it('warns when the hourly token bucket is spent, before the next request fails', async () => {
        const c = new TestGA4Connector(() =>
            response([], { propertyQuota: { tokensPerHour: { remaining: 0, consumed: 1250 } } })
        );
        const result = await c.FetchChanges(fetchContext({ WatermarkValue: '2026-08-04' }));
        expect(codes(result)).toContain('QUOTA_EXHAUSTED');
    });

    it('asks for the quota alongside the data, so exhaustion is visible rather than inferred', async () => {
        const c = new TestGA4Connector(() => response([]));
        await c.FetchChanges(fetchContext());
        expect(c.Requests[0].returnPropertyQuota).toBe(true);
    });

    it('says nothing when there is nothing to say', async () => {
        const c = new TestGA4Connector(() => response([pageRow('20260804', '/a')]));
        const result = await c.FetchChanges(fetchContext({ WatermarkValue: '2026-08-04' }));
        expect(result.Warnings).toBeUndefined();
    });
});

// ── Connection ────────────────────────────────────────────────────────────────

describe('connection test', () => {
    it('reports the reporting time zone, because every synced date is a day in it', async () => {
        const c = new TestGA4Connector(() => response([], { metadata: { timeZone: 'America/Chicago' } }));
        const r = await c.TestConnection(companyIntegration(), {} as UserInfo);
        expect(r.Success).toBe(true);
        expect(r.Message).toContain('America/Chicago');
        expect(r.ServerVersion).toBe('v1beta');
    });

    it('asks for the smallest possible report', async () => {
        const c = new TestGA4Connector(() => response([]));
        await c.TestConnection(companyIntegration(), {} as UserInfo);
        expect(c.Requests[0].limit).toBe(1);
        expect(c.Requests[0].metrics).toEqual([{ name: 'sessions' }]);
    });

    it('tells the operator that property access is granted in Analytics, not in Cloud Console', async () => {
        // The failure everyone hits: the key works, the API is on, and the service account was never
        // added as a user on the property.
        const c = new TestGA4Connector(() =>
            Promise.reject(Object.assign(new Error('PERMISSION_DENIED'), { code: 7 }))
        );
        const r = await c.TestConnection(companyIntegration(), {} as UserInfo);
        expect(r.Success).toBe(false);
        expect(r.Message).toContain('Property Access Management');
        expect(r.Message).toContain('mj-analytics@mj-analytics.iam.gserviceaccount.com');
    });

    it('separates a spent quota from a broken credential', async () => {
        const c = new TestGA4Connector(() =>
            Promise.reject(Object.assign(new Error('RESOURCE_EXHAUSTED'), { code: 8 }))
        );
        const r = await c.TestConnection(companyIntegration(), {} as UserInfo);
        expect(r.Success).toBe(false);
        expect(r.Message).toMatch(/quota is exhausted/);
        expect(r.Message).toMatch(/credential itself looks fine/);
    });

    it('fails before calling Google when the property id is missing', async () => {
        const c = new TestGA4Connector(() => response([]));
        const r = await c.TestConnection(companyIntegration({ Configuration: '{}' }), {} as UserInfo);
        expect(r.Success).toBe(false);
        expect(c.Requests).toHaveLength(0);
    });

    it('fails before calling Google when the credential is not a service-account key', async () => {
        const c = new TestGA4Connector(() => response([]), '{"apiKey":"nope"}');
        const r = await c.TestConnection(companyIntegration(), {} as UserInfo);
        expect(r.Success).toBe(false);
        expect(r.Message).toContain('client_email and private_key');
        expect(c.Requests).toHaveLength(0);
    });

    it("classifies Google's errors from either transport", () => {
        expect(isPermissionError({ code: 403 })).toBe(true);
        expect(isPermissionError(new Error('caller does not have permission'))).toBe(true);
        expect(isQuotaError({ code: 429 })).toBe(true);
        expect(isQuotaError(new Error('Exhausted property tokens quota'))).toBe(true);
        expect(isQuotaError(new Error('invalid dimension'))).toBe(false);
        expect(isPermissionError(new Error('invalid dimension'))).toBe(false);
    });
});

// ── Discovery ─────────────────────────────────────────────────────────────────

describe('discovery', () => {
    const ci = companyIntegration();
    const user = {} as UserInfo;

    it('answers from the declared catalog, so the connector works before metadata is seeded', async () => {
        const objects = await new GA4Connector().DiscoverObjects(ci, user);
        expect(objects.map((o) => o.Name)).toEqual(GA4_OBJECTS.map((o) => o.Name));
        expect(objects.every((o) => o.SupportsWrite === false)).toBe(true);
    });

    it('carries MaxLength, Precision, Scale and the key flags that the other bridge drops', async () => {
        const fields = await new GA4Connector().DiscoverFields(ci, 'UtmContentPerformance', user);
        const content = fields.find((f) => f.Name === 'sessionManualAdContent')!;
        expect(content.MaxLength).toBe(255);
        expect(content.IsPrimaryKey).toBe(true);
        expect(content.AllowsNull).toBe(false);

        const keyEvents = fields.find((f) => f.Name === 'keyEvents')!;
        expect(keyEvents.Precision).toBe(18);
        expect(keyEvents.Scale).toBe(4);
        expect(keyEvents.IsReadOnly).toBe(true);
    });

    it('exposes the same objects to the action generator', () => {
        expect(new GA4Connector().GetIntegrationObjects().map((o) => o.Name)).toEqual(
            GA4_OBJECTS.map((o) => o.Name)
        );
    });
});
