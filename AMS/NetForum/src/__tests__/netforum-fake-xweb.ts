/**
 * Shared harness for the behavioural NetForum tests ported from the Gate-7 smoke scripts
 * (netforum-object-scoped-faults / -own-table-fallback / -watermark-literal / -watermark-integrity).
 *
 * The REAL NetForumConnector runs; only its edges are replaced on the instance: Authenticate, the engine-cache
 * accessors (GetCachedObject / GetCachedFields), DefinitionFor (a parsed GetQueryDefinition built from a compact
 * world spec) and SendGetQuery (a fake xWeb). Every assertion built on it is about the requests the connector SENDS,
 * what FetchChanges returns or throws, and what it persists in `.nf-learned.json`.
 *
 * Not a test file itself (vitest only collects `*.test.ts`).
 */
import { afterEach, beforeEach, vi } from 'vitest';
import { existsSync, mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import type { FetchBatchResult, FetchContext, RESTResponse } from '@memberjunction/integration-engine';
import type { MJCompanyIntegrationEntity, MJIntegrationObjectEntity, MJIntegrationObjectFieldEntity } from '@memberjunction/core-entities';
import type { UserInfo } from '@memberjunction/core';
import { NetForumConnector } from '../NetForumConnector.js';

// ── the connector's internal shapes the harness stands in for ─────────────────────────────────────

/** Mirrors the connector's parsed GetQueryDefinition column (NFDefinedColumn). */
export interface FakeDefinedColumn {
    Name: string;
    Table: string | null;
    Alias: string | null;
    FromTable: string | null;
    DataType: string | null;
    Description: string | undefined;
    AllowsNull: boolean | undefined;
    MaxLength: number | null;
    IsExtension: boolean;
}

/** Mirrors the connector's parsed GetQueryDefinition (NFQueryDefinition). */
export interface FakeDefinition {
    MainTable: string | null;
    KeyColumn: string | undefined;
    Columns: FakeDefinedColumn[];
    DefaultListColumns: string[];
    FromTables: Array<{ Table: string | null; Alias: string | null; Join: string; JoinType: string }>;
    BrokenJoin: string | undefined;
}

export type ProbeKind = 'default' | 'legacy' | 'own';

/** The private members the harness replaces or reads, typed so no `any` is needed. */
interface ConnectorInternals {
    Authenticate(ci: MJCompanyIntegrationEntity, cu: UserInfo): Promise<{ Config: { BaseURL: string }; Token: string }>;
    GetCachedObject(integrationID: string, objectName: string): MJIntegrationObjectEntity;
    GetCachedFields(objectID: string): MJIntegrationObjectFieldEntity[];
    DefinitionFor(ci: MJCompanyIntegrationEntity, cu: UserInfo, objectName: string): Promise<FakeDefinition | null>;
    SendGetQuery(url: string, args: Record<string, string>, token: string): Promise<RESTResponse>;
    DefinitionByObject: Map<string, FakeDefinition | null>;
    UtcDay(): string;
    LastIntegrationID: string | null;
}

interface ConnectorStatics {
    PROBE_FAULTS_PER_DAY: Record<ProbeKind, number>;
}

export const internals = (c: NetForumConnector): ConnectorInternals => c as unknown as ConnectorInternals;
export const statics = (): ConnectorStatics => NetForumConnector as unknown as ConnectorStatics;

// ── the fake world ────────────────────────────────────────────────────────────────────────────────

/** `[table, column, alias?]` — one column of an object's definition. */
export type DefColumn = [string, string, string?];

/**
 * One object of the fake tenant.
 *   def                parsed GetQueryDefinition ({ MainTable?, KeyColumn, Columns }) or absent (no definition)
 *   fields             persisted IOFs [[name, isPk]]
 *   pk                 the persisted primary-key field (shorthand for fields = [[pk, true]])
 *   wm                 IncrementalWatermarkField
 *   defaultFault       fault text for an EMPTY szColumnList (the tenant's default list), else defaultCols are returned
 *   mode               'joinedBreaks': any JOINED column (other table, or an aliased join) → "Incorrect syntax near"
 *                        (except names in allowJoined); an own-table-only list reads
 *                      'allBreaks': every explicit list → "Incorrect syntax near"
 *                      'conversion': any `>=` predicate → "Conversion failed when converting date and/or time"
 *                      'ok' (default): every list reads
 *   invalid            bare names that draw "Invalid column name" when named
 *   invalidOneAtATime  bare names that draw "Invalid column name" ONE per request (the first one named)
 *   ownTable           the table xWeb's statement is built on when it is not def.MainTable ('joinedBreaks' judges by it)
 *   values             { column: [v1, v2, …] } — the values xWeb returns for a column, one per row
 *   def.joins          { '<alias or table>': { type, on } } — a from-table's `<lsf_from_join_type>` ('Join', 'Left Join')
 *                      and `<lsf_from_join>`; a table not listed gets no join type and a placeholder join
 *   def.ext            { column: '<table>_ext' } — an Extender column (mdc_ext = 1): listed under its DefColumn table,
 *                      its mdc_table_name the `_ext` table
 */
export interface FakeObject {
    def?: {
        MainTable?: string; KeyColumn: string; Columns: DefColumn[];
        joins?: Record<string, { type?: string; on: string }>;
        ext?: Record<string, string>;
    };
    fields?: Array<[string, boolean]>;
    pk?: string;
    wm?: string;
    defaultFault?: string;
    defaultCols?: string[];
    mode?: 'ok' | 'joinedBreaks' | 'allBreaks' | 'conversion';
    invalid?: string[];
    invalidOneAtATime?: string[];
    allowJoined?: string[];
    ownTable?: string;
    values?: Record<string, string[]>;
    /**
     * xWeb prepends its own copy of the object's primary key to every query it builds. A list that ALSO names this key
     * bare, read with a bare ORDER BY / WHERE on it, draws SQL Server's "Ambiguous column name '<key>'"; a list that
     * leaves the key out still returns it as the first column (xWeb's copy).
     */
    ambiguousKey?: string;
    /** Bare names that draw "Ambiguous column name" whenever a list names them unqualified (two joined tables carry them). */
    ambiguousBare?: string[];
    /** The object's own Configuration JSON (e.g. a declared `columnList`). */
    config?: Record<string, unknown>;
}
export type World = Record<string, FakeObject>;

/** One GetQuery the connector sent. */
export interface SentCall {
    obj: string;
    list: string;
    orderBy: string;
    where: string;
}

const esc = (s: string): string => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

export const fault = (msg: string): RESTResponse => ({
    Status: 500,
    Headers: {},
    Body: `<?xml version="1.0"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body>` +
        `<soap:Fault><faultcode>soap:Server</faultcode><faultstring>${esc(msg)}</faultstring></soap:Fault></soap:Body></soap:Envelope>`,
});

export const rowsBody = (cols: string[], values?: Record<string, string[]>): RESTResponse => {
    const n = Math.max(2, ...Object.values(values ?? {}).map(v => v.length));
    const val = (c: string, i: number): string => values?.[c.toLowerCase()]?.[i - 1] ?? `${c}-v${i}`;
    const row = (i: number): string => `<Result>${cols.map(c => `<${c}>${val(c, i)}</${c}>`).join('')}</Result>`;
    return {
        Status: 200,
        Headers: {},
        Body: `<?xml version="1.0"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body>` +
            `<GetQueryResponse><GetQueryResult><Results>${Array.from({ length: n }, (_, k) => row(k + 1)).join('')}</Results>` +
            `</GetQueryResult></GetQueryResponse></soap:Body></soap:Envelope>`,
    };
};

export const STAR = "'*' is not a valid value for szColumnList.";

/** A connector over `world`, persisting under `root`, recording every GetQuery into `calls`. */
export function makeConnector(world: World, root: string, calls: SentCall[]): NetForumConnector {
    NetForumConnector.OperatorRoot = root;
    const c = new NetForumConnector();
    const x = internals(c);
    x.Authenticate = async () => ({ Config: { BaseURL: 'https://xweb.invalid' }, Token: 't' });
    x.GetCachedObject = (_iid: string, name: string) => ({
        ID: `io-${name}`, Name: name, IntegrationID: 'I1', Configuration: world[name]?.config ? JSON.stringify(world[name].config) : null,
        IncrementalWatermarkField: world[name]?.wm ?? null,
    }) as unknown as MJIntegrationObjectEntity;
    x.GetCachedFields = (id: string) => {
        const w = world[String(id).replace(/^io-/, '')];
        const fields: Array<[string, boolean]> = w?.fields ?? (w?.pk ? [[w.pk, true]] : []);
        return fields.map(([Name, IsPrimaryKey]) => ({ Name, IsPrimaryKey })) as unknown as MJIntegrationObjectFieldEntity[];
    };
    x.DefinitionFor = async (_ci: MJCompanyIntegrationEntity, _cu: UserInfo, name: string) => {
        const w = world[name]?.def;
        const def: FakeDefinition | null = w ? {
            MainTable: w.MainTable ?? w.Columns[0][0],
            KeyColumn: w.KeyColumn,
            DefaultListColumns: [],
            BrokenJoin: undefined,
            FromTables: [...new Set(w.Columns.map(([t, , a]) => `${t}|${a ?? ''}`))].map((ta, i) => {
                const [t, a] = ta.split('|');
                const j = w.joins?.[a || t];
                return { Table: t || null, Alias: a || null, Join: j?.on ?? (i === 0 ? '' : `${a || t}.x = y`), JoinType: j?.type ?? '' };
            }),
            Columns: w.Columns.map(([Table, Name, Alias]) => ({
                Name, Table: w.ext?.[Name] ?? (Table || null), Alias: Alias ?? null, FromTable: Table || null,
                DataType: 'nvarchar', Description: undefined, AllowsNull: undefined, MaxLength: null, IsExtension: !!w.ext?.[Name],
            })),
        } : null;
        x.DefinitionByObject.set(name.toLowerCase(), def);
        return def;
    };
    x.SendGetQuery = async (_url: string, args: Record<string, string>) => {
        const name = args.szObjectName.split(' ')[0];
        const w: FakeObject = world[name] ?? {};
        calls.push({ obj: name, list: args.szColumnList ?? '', orderBy: args.szOrderBy ?? '', where: args.szWhereClause ?? '' });
        await new Promise(r => setTimeout(r, 5)); // let concurrent callers overlap
        if (w.mode === 'conversion' && />=/.test(args.szWhereClause ?? '')) {
            return fault('Check the Error Log for more details: Conversion failed when converting date and/or time from character string.');
        }
        if (!args.szColumnList) return w.defaultFault ? fault(w.defaultFault) : rowsBody(w.defaultCols ?? ['dflt_key', 'dflt_a']);
        const items = args.szColumnList.split(',').map(s => s.trim());
        const named = items.map(s => s.split('.').pop()!.toLowerCase());
        const seq = named.find(n => (w.invalidOneAtATime ?? []).includes(n));
        if (seq) return fault(`Invalid column name '${seq}'.`);
        const bad = named.filter(n => (w.invalid ?? []).includes(n));
        if (bad.length) return fault(bad.map(n => `Invalid column name '${n}'.`).join('\n'));
        const bareItem = (n: string): boolean => items.some(it => it.toLowerCase() === n.toLowerCase());
        const ambBare = (w.ambiguousBare ?? []).find(bareItem);
        if (ambBare) return fault(`Ambiguous column name '${ambBare}'.`);
        if (w.ambiguousKey && bareItem(w.ambiguousKey)) {
            const bareRef = new RegExp(`(^|[^.\\w])${w.ambiguousKey}\\b`, 'i');
            if (bareRef.test(args.szOrderBy ?? '') || bareRef.test(args.szWhereClause ?? '')) {
                return fault(`Check the Error Log for more details: Ambiguous column name '${w.ambiguousKey}'.`);
            }
        }
        if (w.mode === 'allBreaks') return fault(`Incorrect syntax near '${w.def!.MainTable ?? w.def!.Columns[0][0]}'.`);
        if (w.mode === 'joinedBreaks') {
            const main = (w.ownTable ?? w.def!.MainTable ?? w.def!.Columns[0][0]).toLowerCase();
            const joined = items.find(it => {
                const n = it.split('.').pop()!.toLowerCase();
                if ((w.allowJoined ?? []).includes(n)) return false;
                const col = w.def!.Columns.find(([, cn]) => cn.toLowerCase() === n);
                return !!col && (col[0].toLowerCase() !== main || !!col[2]);
            });
            if (joined) return fault(`Incorrect syntax near '${joined.split('.')[0]}'.`);
        }
        // xWeb's own copy of the key leads every row when the list left the key out.
        if (w.ambiguousKey && !named.includes(w.ambiguousKey.toLowerCase())) return rowsBody([w.ambiguousKey.toLowerCase(), ...named], w.values);
        return rowsBody(named, w.values);
    };
    return c;
}

export const ctxFor = (ObjectName: string, WatermarkValue: string | null = null): FetchContext => ({
    CompanyIntegration: { ID: 'CI1', IntegrationID: 'I1' },
    ContextUser: {},
    ObjectName,
    BatchSize: 100,
    WatermarkValue,
    AfterKeyValue: null,
}) as unknown as FetchContext;

export type FetchOutcome = { ok: true; r: FetchBatchResult } | { ok: false; e: Error };

/** FetchChanges, with a throw captured as an outcome (the smoke scripts' `fetch`). */
export async function fetchObject(c: NetForumConnector, name: string, wm: string | null = null): Promise<FetchOutcome> {
    try {
        return { ok: true, r: await c.FetchChanges(ctxFor(name, wm)) };
    } catch (e) {
        return { ok: false, e: e instanceof Error ? e : new Error(String(e)) };
    }
}

export const errorOf = (o: FetchOutcome): string => (o.ok ? '' : o.e.message);
export const warningsOf = (o: FetchOutcome): NonNullable<FetchBatchResult['Warnings']> => (o.ok ? o.r.Warnings ?? [] : []);

// ── the learned file ──────────────────────────────────────────────────────────────────────────────

export interface LearnedObjectView {
    unsendable?: boolean;
    ownListUsable?: boolean;
    ownListUnsendable?: boolean;
    unselectable?: string[];
    legacyCleared?: boolean;
    [k: string]: unknown;
}
export interface LearnedSectionView {
    probeFaults?: Partial<Record<ProbeKind, { day: string; count: number }>>;
    objects?: Record<string, LearnedObjectView>;
    unresolvable?: unknown;
    defaultListUnusable?: unknown;
    [k: string]: unknown;
}
export interface LearnedFileView {
    version?: number;
    connections?: Record<string, LearnedSectionView>;
}

export const learnedAt = (dir: string): LearnedFileView => {
    const path = join(dir, '.nf-learned.json');
    return existsSync(path) ? JSON.parse(readFileSync(path, 'utf8')) as LearnedFileView : {};
};
export const objOf = (root: string, name: string): LearnedObjectView =>
    learnedAt(root).connections?.CI1?.objects?.[name.toLowerCase()] ?? {};

// ── per-test isolation ────────────────────────────────────────────────────────────────────────────

/**
 * Installs per-test hooks: a fresh temp OperatorRoot (so `.nf-learned.json` never lands in the package and no state
 * leaks between tests), LearnedRoot null, the static probe budgets and console.warn restored afterwards. Returns
 * `freshRoot()` for scenarios that want several roots (e.g. a "restart" reading the same file) and the captured warns.
 */
export function isolateConnectorState(): { freshRoot: () => string; warned: string[] } {
    const originalOperatorRoot = NetForumConnector.OperatorRoot;
    const originalLearnedRoot = NetForumConnector.LearnedRoot;
    const originalBudgets = statics().PROBE_FAULTS_PER_DAY;
    const roots: string[] = [];
    const warned: string[] = [];
    const freshRoot = (): string => {
        const r = mkdtempSync(join(tmpdir(), 'nf-test-'));
        roots.push(r);
        return r;
    };
    beforeEach(() => {
        NetForumConnector.OperatorRoot = freshRoot();
        NetForumConnector.LearnedRoot = null;
        warned.length = 0;
        vi.spyOn(console, 'warn').mockImplementation((...a: unknown[]) => { warned.push(a.map(String).join(' ')); });
    });
    afterEach(() => {
        vi.restoreAllMocks();
        NetForumConnector.OperatorRoot = originalOperatorRoot;
        NetForumConnector.LearnedRoot = originalLearnedRoot;
        statics().PROBE_FAULTS_PER_DAY = originalBudgets;
        for (const r of roots.splice(0)) rmSync(r, { recursive: true, force: true });
    });
    return { freshRoot, warned };
}
