/**
 * NetForumConnector — netFORUM Enterprise xWeb SOAP/XML integration connector.
 *
 * Protocol: SOAP 1.1 over HTTPS. There is NO `BaseSOAPIntegrationConnector` in the
 * engine — the only protocol bases are `BaseIntegrationConnector` (grandparent) and
 * `BaseRESTIntegrationConnector`. This connector rides `BaseRESTIntegrationConnector`
 * and implements SOAP over its HTTP seam: it POSTs SOAP 1.1 envelopes to
 * `/xweb/secure/netForumXML.asmx` via `MakeHTTPRequest` and parses the XML in
 * `NormalizeResponse`. The transport is text/xml, not JSON.
 *
 * ── Wire truth (from the public WSDL: sources/netForumXML_asm.wsdl, 5.9 MB, 277 ops) ──
 *
 *   Endpoint   : POST <tenantHost>/xweb/secure/netForumXML.asmx   (Content-Type: text/xml; charset=utf-8)
 *   Namespace  : http://www.avectra.com/2005/   (Avectra-era, retained by Community Brands)
 *   SOAPAction : http://www.avectra.com/2005/<MethodName>
 *
 *   Auth (TWO-STEP, SOAP — NOT HTTP Basic / WWW-Authenticate / Bearer):
 *     1. Authenticate(userName, password) → the token is in the RESPONSE HEADER,
 *        <soap:Header><AuthorizationToken><Token>. The WSDL declares AuthorizationToken as an OUTPUT
 *        header of Authenticate. The body's AuthenticateResult is NOT the token: on a real tenant it
 *        holds the namespace URI "http://www.avectra.com/2005/". This connector read AuthenticateResult
 *        through 1.3.4 and so sent that URI as its token; netFORUM answers an unrecognised token with
 *        HTTP 500 + faultstring "Locked" on EVERY call, with nothing locked (vendor-confirmed with a
 *        captured response, 2026-09-15). The Authenticate REQUEST carries no AuthorizationToken header.
 *     2. Every subsequent data/CRUD call carries the token in the SOAP HEADER element:
 *          <AuthorizationToken xmlns="http://www.avectra.com/2005/"><Token>{token}</Token></AuthorizationToken>
 *        (NOT an HTTP Authorization header.) Source: WSDL `AuthorizationToken` complexType +
 *        `<soap:header part="AuthorizationToken">` on every WEB-prefixed / GetQuery operation binding.
 *
 *   Read (door = GetQuery):
 *     GetQuery(szObjectName, szColumnList, szWhereClause?, szOrderBy?) → GetQueryResult
 *       - GetQueryResult is a `<s:any>` wildcard DataSet — flattened rows, one element per row.
 *       - szColumnList is sent EMPTY. The vendor's GetQuery page documents both halves: "Asterisk (*)
 *         is not a valid value for szColumnList" (the request faults), and an empty string "returns
 *         the default column listing for the object's primary table — the primary key for the object
 *         will still be returned in the node as the first child". This connector sent `*` through
 *         1.3.2 (fixed in 1.3.4). Consequence: a row carries the tenant's default list columns, NOT
 *         the declared union — FetchChanges warns (WATERMARK_COLUMN_ABSENT) when the watermark
 *         column is missing from what came back, and an IO whose default list lacks a column the
 *         connector needs declares Configuration.columnList (proven live: naming the columns works,
 *         including the watermark, an incremental `>=` predicate on it, and ORDER BY it).
 *       - The "Locked" fault seen alongside those failures was NOT a lock — see the Auth section:
 *         a token read from the wrong element. 1.3.4's changelog attributed it to
 *         MethodsFaultLimitPerDay; that diagnosis was wrong.
 *       - Incremental: szWhereClause = "<watermarkField> >= '<wm>'" where the watermark column is
 *         the IO's per-facade `IncrementalWatermarkField` (e.g. ind_change_date, evt_*_change_date).
 *         There is NO canonical `LastModifiedDate` column — the field is per-facade and is read
 *         from metadata, never hardcoded.
 *       - Row limit: szObjectName supports an `@TOP -1` / `@TOP N` modifier to bypass / bound the
 *         server-side DataGrid row cap. The connector requests the modifier from the IO's accessPath.
 *
 *   Discovery (mechanism, NOT a baked catalog):
 *     - Standard objects come from the Declared metadata (the persisted IntegrationObject rows in
 *       the engine cache — credential-free docs → static metadata, case 1). `DiscoverObjects`
 *       returns the cache; it does NOT enumerate a hardcoded `NF_OBJECTS` array (that was the bug
 *       this IMPROVE round removes).
 *     - Per-object field definitions come from `GetQueryDefinition(szObjectName)` at runtime
 *       (credential-gated, case 2): the response carries the SQL column definition
 *       (Object → ListTable → ListFromTables → ListFromTable[] → Columns → Column[]). The connector
 *       parses that into ExternalFieldSchema. With no credential it falls back to the Declared
 *       fields. The customer's own installed query objects (variable per installation) are reached
 *       the same way — GetQueryDefinition is the discovery MECHANISM, never an answer baked in code.
 *     - `DiscoveryIsAuthoritative` is FALSE: discovery extends the Declared baseline, it does not
 *       enumerate the full credential gamut, so absence in a refresh must NEVER deactivate.
 *
 *   Write (facade CRUD — only where metadata declares the capability + per-operation columns):
 *     - Create/Update route through the IO's per-operation columns (CreateAPIPath/CreateMethod/
 *       CreateBodyShape/CreateBodyKey/CreateIDLocation, Update*) which name the SOAP operation
 *       (e.g. WEBIndividualInsert, InsertFacadeObject). The connector wraps the attributes in a
 *       SOAP envelope for that operation and routes the result through BuildCreatedResult so a 2xx
 *       with no record key fails loudly (no silent record loss / duplicate-create next sync).
 *     - SupportsDelete = false. `DeleteFacadeObject` is not confirmed in any reachable vendor doc;
 *       netFORUM prefers soft-delete via status flags. Held false until verified.
 *
 * Vendor doc URLs:
 *   - WSDL (primary)  : https://myasm.asm.org/xweb/secure/netforumxml.asmx?WSDL
 *   - xWeb Overview   : https://documentation.abila.com/netforum-enterprise/2017.1/Content/xWeb/XWeb_Overview.htm
 *   - GetQuery        : https://documentation.abila.com/netforum-enterprise/2017.1/Content/xWeb/Methods/GetQuery.htm
 */
import { existsSync, mkdirSync, readFileSync, renameSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { RegisterClass } from '@memberjunction/global';
import { Metadata, type IMetadataProvider, type UserInfo } from '@memberjunction/core';
import type {
    MJCompanyIntegrationEntity,
    MJCredentialEntity,
    MJIntegrationObjectEntity,
} from '@memberjunction/core-entities';
import {
    BaseIntegrationConnector,
    BaseRESTIntegrationConnector,
    type RESTAuthContext,
    type RESTResponse,
    type PaginationState,
    type PaginationType,
    type ConnectionTestResult,
    type ExternalRecord,
    type FetchContext,
    type FetchBatchResult,
    type FetchWarning,
    type CreateRecordContext,
    type UpdateRecordContext,
    type DeleteRecordContext,
    type CRUDResult,
    type ExternalObjectSchema,
    type ExternalFieldSchema,
    type SourceSchemaInfo,
    type SourceObjectInfo,
} from '@memberjunction/integration-engine';
import { mergeDeclaredWithSampledFields } from '@memberjunction/connector-schema-merge';

// ─── Constants ───────────────────────────────────────────────────────

/** Avectra-era SOAP namespace, retained by Community Brands. All ops + types use it. */
const SOAP_NS = 'http://www.avectra.com/2005/';
/** Canonical xWeb SOAP endpoint path (per-tenant host; path is constant). */
const DEFAULT_SOAP_PATH = '/xweb/secure/netForumXML.asmx';
const MAX_RETRIES = 3;
const REQUEST_TIMEOUT_MS = 30_000;
const MIN_REQUEST_INTERVAL_MS = 200;
/** Session-token TTL. netFORUM does not publish a token lifetime; re-auth on 401 covers expiry. */
const TOKEN_TTL_MS = 3_600_000;

// ─── Config / auth types ─────────────────────────────────────────────

export interface NetForumConnectionConfig {
    BaseURL: string;
    Username: string;
    Password: string;
}

interface NFAuthContext extends RESTAuthContext {
    /** The session token returned by Authenticate (carried in the SOAP AuthorizationToken header). */
    Token: string;
    Config: NetForumConnectionConfig;
}

interface CachedToken {
    Token: string;
    ExpiresAt: number;
}

/**
 * The per-IO access path the extractor emits into IntegrationObject.Configuration. Read at fetch
 * time so the connector walks the documented door/query rather than assuming one flat query per
 * object. All fields optional — a depth-0 directly-queryable object carries an empty nestingPath.
 */
interface NFAccessPath {
    door?: string;
    queryObject?: string;
    nestingPath?: string[];
    doorArgs?: { szObjectName?: string; topModifier?: string };
}

/** Shape of the per-IO Configuration JSON relevant to this connector. */
interface NFObjectConfig {
    /**
     * Explicit szColumnList, declared ONLY when the tenant's default list lacks a column the connector
     * needs (Individual's default list carries 9 columns and not ind_change_date — proven live 2026-09-15).
     * A declared list REPLACES the default list; the connector appends its own needs (PK, ordering key,
     * watermark) when omitted. Absent ⇒ empty szColumnList ⇒ the tenant's default columns.
     */
    columnList?: string[];
    accessPath?: NFAccessPath;
    stableOrderingKey?: string;
    soapEndpoint?: string;
    soapNamespace?: string;
    getOperation?: string;
    createSoapAction?: string;
    updateSoapAction?: string;
    writeOps?: { createOp?: string; updateOp?: string };
}

/** One `<Column>` of a GetQueryDefinition response, with the table (and alias) that carries it. */
interface NFDefinedColumn {
    Name: string;
    /** `mdc_table_name`, else the enclosing `<lsf_from_table>`; null when the response states neither. */
    Table: string | null;
    /** `<lsf_from_alias>` of the enclosing table — GetQuery MUST use it to name this column when set. */
    Alias: string | null;
    DataType: string | null;
    Description: string | undefined;
    AllowsNull: boolean | undefined;
    MaxLength: number | null;
    /**
     * `<mdc_ext>1</mdc_ext>` — an Extender column: netFORUM stores it in `<table>_ext` and the definition
     * attributes it to that table (`mdc_table_name` = `co_customer_ext`) while listing it under the base
     * table's `<ListFromTable>`. Live rule (PLUS, 2026-09-25, 875 definitions vs 31 explicit reads): when the
     * base table is joined WITHOUT an alias, `co_customer_ext.cst_key_ext` selects fine (all 24 successes);
     * when the base table is joined under an ALIAS (`Chapter`, `cs1`, `Membership`, `email`) the column is
     * "Invalid column name" whichever way it is qualified (every invalid-column fault). Such a column is not sent.
     */
    IsExtension: boolean;
}

/** One `<ListFromTable>` of a definition: the table xWeb joins, its alias, and the join text it uses verbatim. */
interface NFFromTable {
    Table: string | null;
    Alias: string | null;
    Join: string;
}

/** One object's learned facts in `.nf-learned.json` (see NetForumConnector.LoadLearned). */
interface NFLearnedObject {
    unselectable?: string[];
    unexposed?: string[];
    unsendable?: boolean;
    refused?: string;
    injectedKey?: string;
}

/** One connection's learned facts; the section keyed `*` is an operator-written seed every connection reads. */
interface NFLearnedConnection {
    defaultListUnusable?: boolean;
    missingTables?: string[];
    unresolvable?: string[];
    objects?: Record<string, NFLearnedObject>;
}

/** The on-disk shape of what the faults taught this installation, per connection (CompanyIntegration ID). */
interface NFLearnedFile {
    version: 1;
    savedAt?: string;
    note?: string;
    connections?: Record<string, NFLearnedConnection>;
}

/**
 * A parsed GetQueryDefinition response — the vendor's "data dictionary" for one facade object
 * (documentation.abila.com, xWeb › Methods › GetQueryDefinition): `<Object>` → `<ListTable>` (the MAIN
 * table, `<lst_mdt_name>`) → `<ListFromTables>` → `<ListFromTable>` per joined table (`<lsf_from_table>`,
 * `<lsf_from_alias>`, `<Columns>`, and `<ListFromTableColumns>` = the columns an EMPTY szColumnList
 * returns). Key columns are typed `av_key`; the main table's primary key is described "Primary Key".
 */
interface NFQueryDefinition {
    MainTable: string | null;
    /** The main table's primary-key column, when the definition lets us name it; else undefined (keyless, honestly). */
    KeyColumn: string | undefined;
    /** Every column, document order, deduplicated by name (first occurrence kept, main table preferred). */
    Columns: NFDefinedColumn[];
    /** `<lsc_mdc_name>` of the default list — what GetQuery returns for an empty szColumnList. */
    DefaultListColumns: string[];
    /** The from-tables in document order (main table first). */
    FromTables: NFFromTable[];
    /**
     * Why NO GetQuery on this object can compile, when the definition itself says so; undefined when it can.
     * xWeb builds every list query from these from-tables and join texts, so a join that names a main-table key
     * the table does not carry (`pip_cip_key=cpi_key` — live: "Invalid column name 'pip_cip_key'" with the
     * column absent from the object's 185 columns) or a malformed comparison (`ida_ivd_key_product = ivd_type =
     * 'discount'` — live: "Incorrect syntax near '='") fails for the default list and every explicit list alike.
     * Sending anything only spends the tenant's daily fault budget; the fix is in netFORUM's List Table setup.
     */
    BrokenJoin: string | undefined;
}

/**
 * xWeb refuses any GetQuery whose text contains `_entity_key` — the vendor's GetQuery page lists it with
 * select/insert/update/delete/exec/execute as the tokens that make the door answer "Invalid query." (it is
 * netFORUM's multi-entity security column). Every netFORUM table carries a `<prefix>_entity_key`, so a
 * column list built from an object's definition ALWAYS contained one, and every such list was refused: 8 of 8
 * explicit lists on a live tenant (2026-09-24), while the same objects' default lists — which never include
 * it — read fine. The keyword tokens are matched by xWeb as words, not substrings: the vendor's own example
 * filters on `mls_delete_flag=0`, so `_delete_flag` columns stay. Only `_entity_key` is excluded.
 */
function IsQueryableColumn(name: string): boolean {
    return !/_entity_key/i.test(name);
}

/**
 * A name xWeb can be handed as a bare SQL identifier. Column names, tables and aliases go into the
 * statement unquoted, so anything else ("Incorrect syntax near '='." on a live tenant's 711-column
 * object) breaks the whole query; such a qualifier is dropped and the column sent bare.
 */
function IsPlainIdentifier(s: string): boolean {
    return /^[A-Za-z_][A-Za-z0-9_]*$/.test(s);
}

@RegisterClass(BaseIntegrationConnector, '@memberjunction/connector-netforum-enterprise')
export class NetForumConnector extends BaseRESTIntegrationConnector {
    private tokenCache: CachedToken | null = null;
    private lastRequestTime = 0;

    public override get IntegrationName(): string { return 'NetForum Enterprise'; }

    // Capability flags — kept in lockstep with the metadata's per-operation columns.
    // Create/Update are declared on a subset of IOs (those with WEB*Insert/Update or a facade op);
    // the generic CRUD path throws for an IO whose columns are null, so a flag here only asserts
    // "at least one IO supports it". Delete stays false (DeleteFacadeObject unconfirmed in docs).
    public override get SupportsCreate(): boolean { return true; }
    public override get SupportsUpdate(): boolean { return true; }
    public override get SupportsDelete(): boolean { return false; }

    /**
     * §7 — discovery is NOT an authoritative full-gamut enumeration. `DiscoverObjects` returns the
     * Declared baseline (engine cache) and GetQueryDefinition only extends per-object fields; neither
     * enumerates the complete set of objects the credentials expose (customer-installed queries vary).
     * So absence in a refresh proves nothing → the comprehensive-refresh deactivation path must stay
     * off. Returning false keeps the Declared metadata safe from wrongful deactivation.
     */
    public override get DiscoveryIsAuthoritative(): boolean { return false; }

    // ─── Auth — two-step SOAP token ──────────────────────────────────

    /**
     * Step 1 of the two-step auth: POST a SOAP `Authenticate(userName, password)` envelope (which
     * carries NO AuthorizationToken header — it is the bootstrap) and read the token from the SOAP
     * RESPONSE HEADER, `<AuthorizationToken><Token>`, which the WSDL declares as an output header of
     * Authenticate. The body's `AuthenticateResult` is deliberately NOT read: on a real tenant it
     * holds the namespace URI, and sending that as the token gets HTTP 500 "Locked" on every call
     * (what 1.3.4 and earlier did). No fallback to the body — a wrong fallback is exactly this bug.
     * The token is cached and re-used until its TTL elapses or a 401 forces re-auth. Credentials go
     * in the SOAP body elements — there is no HTTP Basic / Bearer here.
     */
    protected async Authenticate(ci: MJCompanyIntegrationEntity, cu: UserInfo): Promise<RESTAuthContext> {
        const config = await this.ParseConfig(ci, cu);
        if (this.tokenCache && this.tokenCache.ExpiresAt > Date.now() + 60_000) {
            return { Token: this.tokenCache.Token, Config: config } as NFAuthContext;
        }
        const body = this.BuildSoapEnvelope('Authenticate', {
            userName: config.Username,
            password: config.Password,
        });
        const url = `${config.BaseURL}${DEFAULT_SOAP_PATH}`;
        const headers = this.SoapHeaders('Authenticate');
        const response = await this.MakeRawHTTPRequest(url, 'POST', headers, body);
        if (response.Status < 200 || response.Status >= 300) {
            throw new Error(`NetForum Authenticate failed: HTTP ${response.Status}${this.SoapFault(response.Body)}`);
        }
        const token = this.ParseAuthenticateToken(this.AsText(response.Body));
        if (!token) {
            throw new Error(
                'NetForum Authenticate response carried no token: expected <AuthorizationToken><Token> in the SOAP ' +
                'response HEADER (the WSDL declares it as an output header of Authenticate). The body\'s ' +
                'AuthenticateResult is not the token — on a real tenant it holds the namespace URI — and is not used.',
            );
        }
        this.tokenCache = { Token: token, ExpiresAt: Date.now() + TOKEN_TTL_MS };
        return { Token: token, Config: config } as NFAuthContext;
    }

    private async ParseConfig(
        ci: MJCompanyIntegrationEntity,
        cu?: UserInfo,
        provider?: IMetadataProvider,
    ): Promise<NetForumConnectionConfig> {
        if (ci.CredentialID) {
            const fromCred = await this.ParseConfigFromCredential(ci.CredentialID, cu, provider);
            if (fromCred) return fromCred;
        }
        if (ci.Configuration) {
            const parsed = JSON.parse(ci.Configuration) as Record<string, string>;
            return this.ExtractConfig(parsed);
        }
        throw new Error('NetForum connector requires either CredentialID or Configuration JSON');
    }

    private async ParseConfigFromCredential(
        credentialID: string,
        cu?: UserInfo,
        provider?: IMetadataProvider,
    ): Promise<NetForumConnectionConfig | null> {
        const md = provider ?? new Metadata();
        const cred = await md.GetEntityObject<MJCredentialEntity>('MJ: Credentials', cu);
        const loaded = await cred.Load(credentialID);
        if (!loaded || !cred.Values) return null;
        const values = JSON.parse(cred.Values) as Record<string, string>;
        return this.ExtractConfig(values);
    }

    private ExtractConfig(values: Record<string, string>): NetForumConnectionConfig {
        const get = (...keys: string[]): string | undefined => {
            for (const key of keys) {
                const hit = Object.entries(values).find(([k]) => k.toLowerCase() === key.toLowerCase());
                if (hit) return String(hit[1] ?? '');
            }
            return undefined;
        };
        const baseURL = get('BaseURL', 'BaseUrl', 'base_url');
        const username = get('Username', 'username', 'user', 'userName');
        const password = get('Password', 'password', 'pass');
        if (!baseURL) throw new Error('NetForum configuration missing required field: BaseURL');
        if (!username) throw new Error('NetForum configuration missing required field: Username');
        if (!password) throw new Error('NetForum configuration missing required field: Password');
        return { BaseURL: this.StripTrailingSlash(baseURL), Username: username, Password: password };
    }

    private StripTrailingSlash(s: string): string { return s.replace(/\/+$/, ''); }

    public async TestConnection(ci: MJCompanyIntegrationEntity, cu: UserInfo): Promise<ConnectionTestResult> {
        try {
            const auth = await this.Authenticate(ci, cu) as NFAuthContext;
            // Read-only smoke: GetVersion is a harmless, token-gated SystemInfo op.
            const url = `${auth.Config.BaseURL}${DEFAULT_SOAP_PATH}`;
            const body = this.BuildSoapEnvelope('GetVersion', {}, auth.Token);
            const r = await this.MakeRawHTTPRequest(url, 'POST', this.SoapHeaders('GetVersion'), body);
            return r.Status >= 200 && r.Status < 300
                ? { Success: true, Message: 'Connected to netFORUM Enterprise xWeb (SOAP)' }
                : { Success: false, Message: `xWeb returned HTTP ${r.Status}` };
        } catch (err) {
            return { Success: false, Message: err instanceof Error ? err.message : String(err) };
        }
    }

    /**
     * Column names GetQueryDefinition returned for an object during THIS process's discovery, keyed by
     * lowercased external name. It exists for one reason: on a tenant whose xWeb default list is itself
     * `*`, an empty szColumnList makes the door fault on its own default ("'*' is not a valid value for
     * szColumnList"), and during introspection the discovered fields are not persisted yet, so
     * GetCachedFields cannot supply a replacement. Step 2 already has the answer — keep it for step 3.
     */
    private readonly DiscoveredColumnsByObject = new Map<string, string[]>();

    /**
     * `<obj_key>` of each enumerated facade object, keyed by lowercased object name. It is the facade
     * object's own GUID — the vendor's GetFacadeObjectList page shows
     * `<obj_name>ProductSubscription</obj_name><obj_key>22210b27-2396-48f0-a6a7-5e1a8eb9bda6</obj_key>` —
     * and NOT a column of the object. 1.6.3 read it as the key COLUMN: `ORDER BY 74a11d45-ec60-…` and a
     * column list containing that GUID went to SQL Server for every enumerated object, which answered
     * "Incorrect syntax near 'a11d45'" (its tokenizer splitting the GUID), "The floating point value
     * '07e325' is out of the range of computer representation" (a hex fragment read as a float) and
     * "Invalid query." — 975 faults and zero rows in one discovery on a live tenant (2026-09-24).
     * Kept as METADATA only: it never reaches szColumnList, szWhereClause or szOrderBy, and it never
     * marks a field IsPrimaryKey. The key comes from the object's own definition (DefinitionByObject).
     */
    private readonly EnumeratedObjectIdByObject = new Map<string, string>();

    /**
     * Parsed GetQueryDefinition per object (lowercased name), fetched at most once per instance per
     * object: DiscoverFields needs the columns, FetchChanges needs the key column and the alias-
     * qualified column list. `null` records a definite non-2xx answer so an object the account cannot
     * describe is not asked again (xWeb counts faults, not calls, against the daily lock budget); a
     * thrown network error is NOT cached, so a transient failure does not leave the object keyless for
     * the life of the process.
     */
    private readonly DefinitionByObject = new Map<string, NFQueryDefinition | null>();

    /**
     * `<connection>|<object>` pairs xWeb has refused with "Account is not authorized to perform Select
     * on <object> object". A grant does not appear between two calls of one run, and each retry is a
     * ~7.5 s HTTP 500 that counts against the fault budget; the second and later calls fail locally.
     */
    private readonly SelectNotAuthorized = new Set<string>();

    /**
     * CompanyIntegration IDs whose xWeb default column list is unusable.
     *
     * xWeb counts FAULTS, not calls, against `MethodsFaultLimitPerDay` (default 100 per user+IP),
     * and it does NOT auto-reset — a vendor clears it by hand. The retry in FetchChanges learns the
     * default is bad by faulting, which is correct once and ruinous repeated: without this set it
     * re-learned it on EVERY call, so a tenant whose default resolves to `*` spent one fault per
     * object. 888 objects on the BC sandbox meant >=888 faults against a budget of 100, which is
     * what locked the account on 2026-09-05 and again on 2026-09-19 — our request shape, not the
     * tenant's data. Remembering the answer costs one fault instead of hundreds.
     */
    private readonly DefaultColumnListUnusable = new Set<string>();
    /** Connections whose default-list verdict is known either way (probe answered) — no more gating. */
    private readonly DefaultListVerdict = new Set<string>();
    /**
     * The one in-flight empty-list request per connection while the default-list verdict is unknown.
     * Sampling runs objects in parallel: without this, every concurrent first request paid its own
     * "'*' is not a valid value" fault before the latch could tell them (3 of 10 faults on a live run).
     */
    private readonly DefaultListProbe = new Map<string, Promise<void>>();
    /**
     * Columns xWeb's SQL cannot select for an object on a connection, learned from a fault that named
     * them ("Invalid column name 'x'." — SQL Server lists every unresolvable column of the statement).
     * The object's definition lists them, the list query's FROM cannot reach them: the vendor's own
     * caveat — GetQuery follows the List Table / From Table setup, not the object's data objects, "and
     * there might be a mismatch in some cases" (6 of a live run's 10 faults, e.g. an Extender key
     * `cst_key_ext` attributed to a joined table that does not carry it). Keyed
     * `<companyIntegrationID>|<object>`; once learned, never sent again on this instance — the fault
     * is paid once per object per process, not on every page of every sync.
     */
    private readonly UnselectableColumns = new Map<string, Set<string>>();
    /**
     * Objects whose explicit column list broke xWeb's SQL ("Incorrect syntax near …") on a connection.
     * The fault names no column, so nothing can be dropped; the list is not sent again on this instance.
     */
    private readonly ExplicitListUnsendable = new Set<string>();
    /**
     * Tables (or aliases) xWeb's generated SQL does not expose under the name the definition gives them, learned
     * from `The multi-part identifier "T.col" could not be bound` (live: `ev_session_fee`, `oe_price`,
     * `oe_product_type`, `ac_ar_period_scheduler` — nothing in those definitions differs from the ones that
     * bind). Keyed `<connection>|<object>`; a column under such a table is sent bare. When the KEY's table is
     * unexposed the key is left out of the list (xWeb prepends the object's primary key to every query anyway)
     * so a bare ORDER BY on it is not ambiguous.
     */
    private readonly UnexposedQualifiers = new Map<string, Set<string>>();
    /** Per `<connection>|<object>`: the name xWeb gave the first column when our key was not in the row. */
    private readonly InjectedKeyByObject = new Map<string, string>();
    /**
     * Tables xWeb's SQL says do not exist in this database ("Invalid object name 'T'"), learned CONNECTION-WIDE from
     * one fault: an Extender table the tenant never created (`np_member_ext`), or a placeholder a list joins
     * (`zz_dummy`). Every column the definitions attribute to T is dropped from every object's list; an object that
     * JOINS T cannot compile at all and is refused before a request (see LearnedRefusals).
     */
    private readonly MissingTables = new Map<string, Set<string>>();
    /**
     * `table.column` pairs SQL Server could not resolve ("Invalid column name 'c'" for a column the definition puts on
     * `table`), learned CONNECTION-WIDE: the same attribution is wrong in every object that carries it (live: every
     * `oe_product_type.*` column in three Price* objects — three faults for one fact). Dropped wherever it appears.
     */
    private readonly UnresolvablePairs = new Map<string, Set<string>>();
    /** `<connection>|<object>` refused from a learned fact (a FROM table that does not exist), with the reason. */
    private readonly LearnedRefusals = new Map<string, string>();
    /** Connections whose learned state has been read from disk this process. */
    private readonly LearnedLoadedFor = new Set<string>();
    /** The operator-written `*` section of .nf-learned.json, kept verbatim across saves. */
    private LearnedSeed: NFLearnedConnection | undefined;
    /**
     * GetQuery requests in flight per instance, bounded: eight parallel samplers drew a burst of 31 HTTP 429
     * answers from the vendor's web server (PLUS 2026-09-25). A 429 is throttling, not a fault — it is waited out
     * and retried, never learned from and never surfaced as a failure until the retries are spent.
     */
    private GetQueryInFlight = 0;
    private readonly GetQueryWaiters: Array<() => void> = [];
    private static readonly GETQUERY_MAX_IN_FLIGHT = 4;
    private static readonly RETRY_AFTER_429_MS = [3000, 8000, 20000];

    /** One GetQuery round trip under the concurrency bound, with 429 waited out and retried. */
    private async SendGetQuery(url: string, args: Record<string, string>, token: string): Promise<RESTResponse> {
        return this.SendSoap('GetQuery', url, args, token);
    }

    /**
     * One xWeb round trip under the shared concurrency bound, with HTTP 429 waited out and retried. GetQuery and
     * GetQueryDefinition both go through here: the vendor's web server throttles the METADATA calls too, and a
     * throttled GetQueryDefinition read as "no definition" left 58 of 878 objects with no columns on a live run
     * (PLUS 2026-09-25) — eight definitions in flight, every 429 cached as a refusal.
     */
    private async SendSoap(action: string, url: string, args: Record<string, string>, token: string): Promise<RESTResponse> {
        if (this.GetQueryInFlight >= NetForumConnector.GETQUERY_MAX_IN_FLIGHT) {
            await new Promise<void>(resolve => this.GetQueryWaiters.push(resolve));
        }
        this.GetQueryInFlight++;
        try {
            let response = await this.MakeRawHTTPRequest(url, 'POST', this.SoapHeaders(action), this.BuildSoapEnvelope(action, args, token));
            for (const delay of NetForumConnector.RETRY_AFTER_429_MS) {
                if (response.Status !== 429) break;
                const hinted = Number((response.Headers ?? {})['retry-after'] ?? (response.Headers ?? {})['Retry-After']);
                await this.Sleep(Number.isFinite(hinted) && hinted > 0 ? Math.min(hinted * 1000, 60000) : delay);
                response = await this.MakeRawHTTPRequest(url, 'POST', this.SoapHeaders(action), this.BuildSoapEnvelope(action, args, token));
            }
            return response;
        } finally {
            this.GetQueryInFlight--;
            const next = this.GetQueryWaiters.shift();
            if (next) next();
        }
    }


    /**
     * Operator hooks, filesystem-keyed so they need no configuration or restart to arm:
     *   - `<OperatorRoot>/logs/netforum-definitions/` exists → every GetQueryDefinition answer is written there as
     *     `<object>.xml` (the vendor's per-object list definition: from-tables, aliases, join text, columns). It is the
     *     only input that explains which listed columns a tenant's list query can actually select, and fetching it
     *     never faults — the way to learn a tenant's rules without spending the daily fault budget.
     *   - `<OperatorRoot>/.nf-definitions-only` exists → FetchChanges stops locally before any GetQuery, so a discovery
     *     run collects the definitions above and costs zero faults. Remove the file to sample and sync again.
     * OperatorRoot defaults to the process working directory (MJAPI: the release's apps/MJAPI). Tests point it elsewhere.
     */
    public static OperatorRoot: string = process.cwd();

    /**
     * `<OperatorRoot>/.nf-learned.json` — what the faults taught, kept ACROSS processes. xWeb counts every fault
     * against its daily lock budget; a fault paid once per PROCESS is paid again after every restart (the RSU
     * restarts the API between discovery and the first sync), so on a large tenant the same ~70 facts cost ~70
     * faults per process. Written after every learn (small file, rare event), read once per connection per process,
     * keyed by object name (one installation, one tenant). Delete the file to forget everything and re-pay.
     */
    private LearnedFilePath(): string { return join(NetForumConnector.OperatorRoot, '.nf-learned.json'); }

    private LoadLearned(faultKey: string): void {
        if (this.LearnedLoadedFor.has(faultKey)) return;
        this.LearnedLoadedFor.add(faultKey);
        let raw: string;
        try { if (!existsSync(this.LearnedFilePath())) return; raw = readFileSync(this.LearnedFilePath(), 'utf8'); } catch { return; }
        let file: NFLearnedFile;
        try { file = JSON.parse(raw) as NFLearnedFile; } catch { return; }
        if (!file || typeof file !== 'object' || !file.connections) return;
        if (file.connections['*'] && typeof file.connections['*'] === 'object') this.LearnedSeed = file.connections['*'];
        const mergeInto = (map: Map<string, Set<string>>, key: string, values: unknown): void => {
            if (!Array.isArray(values)) return;
            const set = map.get(key) ?? new Set<string>();
            for (const v of values) if (typeof v === 'string' && v) set.add(v.toLowerCase());
            map.set(key, set);
        };
        for (const section of [file.connections['*'], file.connections[faultKey]]) {
            if (!section || typeof section !== 'object') continue;
            mergeInto(this.MissingTables, faultKey, section.missingTables);
            mergeInto(this.UnresolvablePairs, faultKey, section.unresolvable);
            if (section.defaultListUnusable === true) { this.DefaultColumnListUnusable.add(faultKey); this.DefaultListVerdict.add(faultKey); }
            for (const [name, o] of Object.entries(section.objects ?? {})) {
                if (!o || typeof o !== 'object') continue;
                const key = `${faultKey}|${name.toLowerCase()}`;
                mergeInto(this.UnselectableColumns, key, o.unselectable);
                mergeInto(this.UnexposedQualifiers, key, o.unexposed);
                if (o.unsendable === true) this.ExplicitListUnsendable.add(key);
                if (typeof o.refused === 'string' && o.refused) this.LearnedRefusals.set(key, o.refused);
                if (typeof o.injectedKey === 'string' && o.injectedKey && !this.InjectedKeyByObject.has(key)) this.InjectedKeyByObject.set(key, o.injectedKey);
            }
        }
    }

    private SaveLearned(): void {
        try {
            const connections: Record<string, NFLearnedConnection> = {};
            if (this.LearnedSeed) connections['*'] = this.LearnedSeed;
            const conn = (faultKey: string): NFLearnedConnection => (connections[faultKey] ??= {});
            const at = (grantKey: string): NFLearnedObject => {
                const bar = grantKey.indexOf('|');
                const c = conn(grantKey.slice(0, bar));
                return ((c.objects ??= {})[grantKey.slice(bar + 1)] ??= {});
            };
            for (const k of this.DefaultColumnListUnusable) conn(k).defaultListUnusable = true;
            for (const [k, v] of this.MissingTables) if (v.size > 0) conn(k).missingTables = [...v].sort();
            for (const [k, v] of this.UnresolvablePairs) if (v.size > 0) conn(k).unresolvable = [...v].sort();
            for (const [k, v] of this.UnselectableColumns) if (v.size > 0) at(k).unselectable = [...v].sort();
            for (const [k, v] of this.UnexposedQualifiers) if (v.size > 0) at(k).unexposed = [...v].sort();
            for (const k of this.ExplicitListUnsendable) at(k).unsendable = true;
            for (const [k, v] of this.LearnedRefusals) at(k).refused = v;
            for (const [k, v] of this.InjectedKeyByObject) at(k).injectedKey = v;
            const file: NFLearnedFile = { version: 1, savedAt: new Date().toISOString(), connections };
            const path = this.LearnedFilePath();
            writeFileSync(`${path}.tmp`, JSON.stringify(file, null, 1));
            renameSync(`${path}.tmp`, path);
        } catch {
            // best effort: the in-memory state still protects this process
        }
    }

    /** Why this object's list cannot compile because of a table learned missing, else undefined. */
    private MissingFromTableReason(def: NFQueryDefinition | null, faultKey: string): string | undefined {
        const missing = this.MissingTables.get(faultKey);
        if (!def || !missing || missing.size === 0) return undefined;
        const t = def.FromTables.find(f => f.Table && missing.has(f.Table.toLowerCase()));
        return t?.Table ? `it joins "${t.Table}", a table xWeb's SQL reported as not existing in this database` : undefined;
    }

    /** True when a defined column is known unselectable connection-wide (its table is missing, or the pair is unresolvable). */
    private ColumnUnresolvable(c: NFDefinedColumn, learnKey: string | undefined): boolean {
        if (!learnKey) return false;
        const faultKey = learnKey.slice(0, learnKey.indexOf('|'));
        const table = (c.Table ?? '').toLowerCase();
        if (table && this.MissingTables.get(faultKey)?.has(table)) return true;
        return this.UnresolvablePairs.get(faultKey)?.has(`${table}.${c.Name.toLowerCase()}`) ?? false;
    }

    private DefinitionsOnlyMode(): boolean {
        try { return existsSync(join(NetForumConnector.OperatorRoot, '.nf-definitions-only')); } catch { return false; }
    }

    private DumpDefinition(objectName: string, xml: string): void {
        try {
            const dir = join(NetForumConnector.OperatorRoot, 'logs', 'netforum-definitions');
            if (!existsSync(dir)) return;
            const safe = objectName.replace(/[^A-Za-z0-9_.-]+/g, '_').slice(0, 120);
            writeFileSync(join(dir, `${safe}.xml`), xml, 'utf8');
        } catch {
            // best-effort diagnostics: never let a dump failure change what the connector does
        }
    }

    // ─── Discovery — Declared cache + runtime GetQueryDefinition ──────

    /**
     * Objects come from the SOURCE whenever the source can list them. netFORUM can:
     * `GetFacadeObjectList` takes an empty request and returns every facade the credential may see
     * (878 on a live tenant against a declared catalog of 34). It is called on every discovery — a
     * connector that can enumerate must never report a baked-in list instead.
     *
     * The declared catalog remains the BASELINE, not the answer: declared rows are curated (APIPath,
     * watermark, primary key, write capability) and an enumerated row carries a name, key and
     * description, so declared always wins a name collision. Enumeration ADDS the rest.
     *
     * Credential-free (or if the account is not granted the method) this degrades to the declared
     * baseline, so the runtime structure self-check still passes without a token.
     */
    public override async DiscoverObjects(
        ci: MJCompanyIntegrationEntity,
        cu: UserInfo,
    ): Promise<ExternalObjectSchema[]> {
        const declared = await this.DeclaredObjects(ci, cu);
        const enumerated = await this.EnumerateFacadeObjects(ci, cu);
        return enumerated ? this.MergeEnumeratedObjects(declared, enumerated) : declared;
    }

    /**
     * One `GetFacadeObjectList` call: the enumerated object universe, or `null` when the source could
     * not be asked — credential-free, network failure, parse failure, or the account not granted the
     * method; the Declared baseline then stands alone, exactly as before.
     */
    private async EnumerateFacadeObjects(ci: MJCompanyIntegrationEntity, cu: UserInfo): Promise<ExternalObjectSchema[] | null> {
        try {
            const auth = await this.Authenticate(ci, cu) as NFAuthContext;
            const url = `${auth.Config.BaseURL}${DEFAULT_SOAP_PATH}`;
            const body = this.BuildSoapEnvelope('GetFacadeObjectList', {}, auth.Token);
            const r = await this.MakeRawHTTPRequest(url, 'POST', this.SoapHeaders('GetFacadeObjectList'), body);
            if (r.Status >= 200 && r.Status < 300) {
                return this.ParseFacadeObjectList(this.AsText(r.Body));
            }
        } catch {
            // Credential-free, network failure, parse failure, or the account not granted
            // GetFacadeObjectList → the Declared baseline stands alone, exactly as before.
        }
        return null;
    }

    /**
     * The Declared baseline (engine cache of persisted IntegrationObject rows).
     *
     * `protected` so a unit-test subclass can supply a canned declared set — the same single-seam
     * idiom MakeRawHTTPRequest uses. The base reads the IntegrationEngineBase singleton, which a
     * test cannot intercept, and the declared-wins guarantee below is worth testing directly.
     */
    protected async DeclaredObjects(
        ci: MJCompanyIntegrationEntity,
        cu: UserInfo,
    ): Promise<ExternalObjectSchema[]> {
        return super.DiscoverObjects(ci, cu);
    }

    /**
     * Parses a GetFacadeObjectList response into the enumerated object universe.
     *
     * Verified shape (live, 2026-09-15): `<ObjectObjects>` containing one `<ObjectObject>` per facade,
     * each carrying `<obj_name>`, `<obj_key>` and `<obj_description>`. 878 rows on a real tenant.
     * `obj_key` is the facade object's GUID (vendor documentation, and a live tenant's SQL faults
     * quoting its fragments) — kept as an identifier (EnumeratedObjectIdByObject), never as a column.
     *
     * Enumerated-only objects are reported HONESTLY as unknown-capability: the list gives a name and
     * a description, never a watermark field or a write path, so `SupportsIncrementalSync` and
     * `SupportsWrite` are false until the Declared metadata says otherwise. Claiming either from a
     * bare name would promise a sync mode the connector cannot deliver.
     */
    private ParseFacadeObjectList(xml: string): ExternalObjectSchema[] {
        const out: ExternalObjectSchema[] = [];
        const seen = new Set<string>();
        for (const row of this.ExtractElements(xml, 'ObjectObject')) {
            const name = this.ParseSoapScalar(row, 'obj_name');
            if (!name) continue;
            const key = name.toLowerCase();
            if (seen.has(key)) continue;
            seen.add(key);
            const description = this.ParseSoapScalar(row, 'obj_description');
            const objKey = this.ParseSoapScalar(row, 'obj_key');
            if (objKey) this.EnumeratedObjectIdByObject.set(key, objKey);
            out.push({
                Name: name,
                Label: description || name,
                Description: description,
                SupportsIncrementalSync: false,
                SupportsWrite: false,
            });
        }
        return out;
    }

    /**
     * Resolves the client's object set per the framework contract (everything.txt §2), which is a
     * three-way reconciliation, NOT a union:
     *
     *   in BOTH          -> keep, and overlay attribute-by-attribute with EXTERNAL SYSTEM PRIORITY.
     *                       The source wins wherever it says something; the declared metadata is the
     *                       FALLBACK for whatever the source is silent about. Asked per attribute,
     *                       not per object: GetFacadeObjectList states a description, and says
     *                       nothing about APIPath, watermark, primary key or write capability — so
     *                       the description comes from the source and the rest from the declaration.
     *
     *   source ONLY      -> add. These are the client's custom/undeclared objects.
     *
     *   declared ONLY    -> EXCLUDE for this client. "if you have metadata for Objects A,B,C, and
     *                       the external system has C,D,E ... you basically exclude A,B for this
     *                       client as potential entity maps". A declared object the source does not
     *                       list is not this tenant's object, and carrying it forward is what
     *                       produces catalog rows that can never be fetched, have no provable
     *                       primary key, and are skipped at materialisation.
     *
     * Exclusion applies ONLY when the source actually enumerated. If the call failed or the account
     * is not granted it, DiscoverObjects returns the declared baseline untouched — absence of an
     * answer must never be read as absence of an object.
     */
    private MergeEnumeratedObjects(
        declared: ExternalObjectSchema[],
        enumerated: ExternalObjectSchema[],
    ): ExternalObjectSchema[] {
        const declaredByName = new Map(declared.map(o => [o.Name.toLowerCase(), o]));
        const resolved: ExternalObjectSchema[] = [];
        for (const src of enumerated) {
            const dec = declaredByName.get(src.Name.toLowerCase());
            if (!dec) {
                resolved.push(src);               // source only — bring it in
                continue;
            }
            // The source's ONLY statement about an object is obj_description. ParseFacadeObjectList
            // synthesises Label from the name when that is empty, so Label alone cannot distinguish
            // "the source described it" from "the source said nothing" — gate both on the raw
            // description, or a silent source would overwrite a curated label with the bare name.
            const sourceSpoke = !!src.Description?.trim();
            resolved.push({
                ...dec,                            // declared is the fallback for everything
                Name: dec.Name,                    // keep the declared casing the catalog is keyed on
                Label: sourceSpoke ? src.Label : dec.Label,
                Description: sourceSpoke ? src.Description : dec.Description,
            });
        }
        return resolved.sort((a, b) => a.Name.localeCompare(b.Name));
    }

    /**
     * Two-stage field discovery. Stage 1 returns the Declared field set (engine cache). Stage 2, when
     * a credential is available, calls the GetQueryDefinition MECHANISM and parses the returned SQL
     * column definition (Object → ListTable → ListFromTables → Column[]) into ExternalFieldSchema —
     * this surfaces customer-added columns the static metadata never saw. With no credential, or on
     * any error, it degrades to the Declared fields (never throws, never bakes a catalog).
     */
    public override async DiscoverFields(
        ci: MJCompanyIntegrationEntity,
        objectName: string,
        cu: UserInfo,
    ): Promise<ExternalFieldSchema[]> {
        // An object this connector enumerated but has not persisted yet is unknown to the engine
        // cache, and the base DiscoverFields throws for it. On a first discovery that is every
        // enumerated-only object — through 1.6.2 they got no columns until the second pass. The
        // endpoint's column list does not depend on the cache, so "not cached" means "nothing
        // declared" and the call goes on to GetQueryDefinition. Anything else the base throws, throws.
        let declared: ExternalFieldSchema[];
        try {
            declared = await super.DiscoverFields(ci, objectName, cu);
        } catch (err) {
            if (!/IntegrationObject not found/.test(err instanceof Error ? err.message : String(err))) throw err;
            declared = [];
        }
        // The base FieldEntityToSchema folds PK into IsUniqueKey and never sets IsPrimaryKey, so
        // re-derive the honest IsPrimaryKey from the cached IOF entities (which carry it explicitly).
        const pkNames = this.DeclaredPrimaryKeyNames(ci, objectName);
        const declaredByName = new Map(
            declared.map(f => [f.Name.toLowerCase(), { ...f, IsPrimaryKey: pkNames.has(f.Name.toLowerCase()) }]),
        );
        // The object's own definition names its columns AND its key (the main table's `av_key`
        // column described "Primary Key", else the `<prefix>_key` naming convention). Nothing here
        // enumerates the facade list: `obj_key` is not a column and has nothing to say about fields.
        const def = await this.DefinitionFor(ci, cu, objectName);
        if (def && def.Columns.length > 0) return this.FieldsFromDefinition(def, declaredByName);
        return declared;
    }

    /**
     * The parsed GetQueryDefinition for `objectName`, fetched once per instance per object, under the shared
     * concurrency bound with 429 waited out. Only a DEFINITE refusal — a SOAP fault, e.g. "Account is not
     * authorized" — is remembered as `null` (faults are the budget xWeb locks the account on, so it is not asked
     * again). A throttle that outlasts the retries, a gateway error or a thrown network error is NOT remembered:
     * the next caller asks again — and when the operator dump directory holds this object's earlier answer
     * (`logs/netforum-definitions/<object>.xml`, the vendor's own words), that answer stands in meanwhile.
     */
    private async DefinitionFor(ci: MJCompanyIntegrationEntity, cu: UserInfo, objectName: string): Promise<NFQueryDefinition | null> {
        const key = objectName.toLowerCase();
        if (this.DefinitionByObject.has(key)) return this.DefinitionByObject.get(key) ?? null;
        try {
            const auth = await this.Authenticate(ci, cu) as NFAuthContext;
            const url = `${auth.Config.BaseURL}${DEFAULT_SOAP_PATH}`;
            const r = await this.SendSoap('GetQueryDefinition', url, { szObjectName: objectName }, auth.Token);
            if (r.Status >= 200 && r.Status < 300) {
                this.DumpDefinition(objectName, this.AsText(r.Body));
                const parsed = this.ParseQueryDefinition(this.AsText(r.Body));
                const def = parsed.Columns.length > 0 ? parsed : null;
                this.DefinitionByObject.set(key, def);
                return def;
            }
            const dumped = this.DumpedDefinition(objectName);
            if (dumped) { this.DefinitionByObject.set(key, dumped); return dumped; }
            if (r.Status !== 429 && this.FaultText(r.Body)) this.DefinitionByObject.set(key, null);   // a definite refusal — not retried per call
        } catch {
            // credential-free / network / parse failure → nothing cached, nothing known
        }
        return null;
    }

    /** The object's definition from the operator dump directory, when a live fetch is refused or throttled; null when absent. */
    private DumpedDefinition(objectName: string): NFQueryDefinition | null {
        try {
            const path = join(NetForumConnector.OperatorRoot, 'logs', 'netforum-definitions', `${objectName}.xml`);
            if (!existsSync(path)) return null;
            const parsed = this.ParseQueryDefinition(readFileSync(path, 'utf8'));
            return parsed.Columns.length > 0 ? parsed : null;
        } catch { return null; }
    }

    /**
     * IntrospectSchema — resolves each object's columns in the contract's order:
     *   1. DiscoverObjects  — the endpoint's object list (GetFacadeObjectList), reconciled in 1.5.0
     *   2. DiscoverFields   — the endpoint's COLUMN list (GetQueryDefinition), added here
     *   3. Sampling         — streams records for what only data can answer: measured string widths,
     *                         primary-key significance, and custom columns findable no other way
     *
     * Step 2 was missing. This method went straight from the declared catalog to sampling, so any
     * object without declared metadata could only get columns if streaming its records happened to
     * work. After 1.5.0 enumerated 878 objects, 862 of them landed with ZERO columns — and therefore
     * no key, no table, and an RSU that emitted a migration with no DDL — while GetQueryDefinition
     * could describe every one of them. Measured 2026-09-18: `Abstract Author` 137 columns,
     * `AccountingPeriod` 58, `Individual` 1161, no faults. The endpoint also returns type,
     * nullability and mdc_width_max, so widths no longer depend on sampling reaching the object.
     *
     * Ordering matters beyond correctness: one schema call per object costs nothing next to paging
     * rows, so the column list no longer competes with the run deadline.
     *
     * Sampling remains UNCONDITIONAL — it is not gated on what the endpoint returned. It is the only
     * source for PK statistics and for columns that exist in data but in no schema.
     *
     * `super.IntrospectSchema` yields the cache-driven Declared catalog (no measured widths). For each
     * object we then call MJ's `DiscoverFieldsViaFetch` — MJ's own read-path sampler that measures real
     * field widths and surfaces custom columns — and the shared PURE `mergeDeclaredWithSampledFields`
     * unions the two by field name (adopt MJ's measured width; append MJ-discovered custom columns). MJ
     * owns everything else (measurement, type/PK inference, persistence, reconcile, sync).
     *
     * Recursion note: `DiscoverFieldsViaFetch` falls back to `DiscoverFields`, never back into THIS
     * method, so there is no infinite recursion. `DiscoverFields` itself does NOT call any
     * ViaFetch/ViaStream — it is the endpoint path.
     *
     * Robustness: objects are sampled IN PARALLEL under a small bounded pool; any per-object failure
     * keeps that object's declared fields, so a single bad sample never breaks introspection.
     */
    /**
     * Test seam over the cache-driven declared catalog, mirroring {@link DeclaredObjects}.
     * `super.IntrospectSchema` reads the IntegrationEngineBase singleton, which a unit test cannot
     * stand up — without this, the step ordering in IntrospectSchema is untestable and the missing
     * DiscoverFields call went unnoticed through 38 passing tests.
     */
    protected async DeclaredSchema(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
    ): Promise<SourceSchemaInfo> {
        return super.IntrospectSchema(companyIntegration, contextUser);
    }

    public override async IntrospectSchema(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<SourceSchemaInfo> {
        const schema = await this.DeclaredSchema(companyIntegration, contextUser);

        await runBounded(schema.Objects, 8, async (obj: SourceObjectInfo) => {
            // Step 2 — the endpoint's column list. DiscoverFields already reconciles GetQueryDefinition
            // against the declared baseline and degrades to declared on any failure, so an empty or
            // faulting response leaves this object exactly as it was.
            try {
                const fromEndpoint = await this.DiscoverFields(companyIntegration, obj.ExternalName, contextUser);
                if (fromEndpoint.length > 0) {
                    // Hand step 2's answer to step 3: sampling needs a named column list on tenants
                    // whose default list is `*`, and nothing else in the run knows these names yet.
                    this.DiscoveredColumnsByObject.set(
                        obj.ExternalName.toLowerCase(),
                        fromEndpoint.map(f => f.Name).filter(n => !!n),
                    );
                    // Same shared merge the sampling pass uses: it folds an ExternalFieldSchema[] into
                    // the object's SourceFieldInfo[] by name, adopting the endpoint's width and
                    // appending columns the declared baseline never had. For an enumerated-only object
                    // the declared side is empty, so the result is simply the endpoint's column list.
                    obj.Fields = mergeDeclaredWithSampledFields(obj.Fields, fromEndpoint);
                }
            } catch {
                // Endpoint unreachable for this object — keep the declared fields and let sampling try.
            }

            // Step 3 — sampling, unchanged and unconditional. Merges measured widths and any column
            // that exists in the data but in neither the declared metadata nor the endpoint.
            try {
                const sampled = await this.DiscoverFieldsViaFetch(companyIntegration, obj.ExternalName, contextUser);
                obj.Fields = mergeDeclaredWithSampledFields(obj.Fields, sampled);
            } catch {
                // Keep what we have — sampling is best-effort and never breaks introspection.
            }
        });

        return schema;
    }

    /**
     * Parses a GetQueryDefinition response into its tables, columns and default list, and names the
     * object's key column when the definition allows it (see KeyColumnFromDefinition). Columns are
     * deduplicated by name: netFORUM list tables join the same table more than once under aliases
     * (Individual joins mb_membership as Membership, ChapterMembership and OrgMembership), so one
     * column name can appear several times — the first occurrence wins, the main table's preferred.
     * Element names per the vendor's own sample: lst_mdt_name, lsf_from_table, lsf_from_alias,
     * mdc_name / mdc_description / mdc_data_type / mdc_nullable / mdc_table_name / mdc_width_max,
     * lsc_mdc_name. A response without <ListFromTable> wrappers still yields its <Column>s.
     */
    private ParseQueryDefinition(xml: string): NFQueryDefinition {
        const mainTable = this.ParseSoapScalar(xml, 'lst_mdt_name') ?? null;
        const columns: NFDefinedColumn[] = [];
        const defaultList: string[] = [];
        const readColumns = (scope: string, table: string | null, alias: string | null): void => {
            for (const colXml of this.ExtractElements(scope, 'Column')) {
                const name = this.ParseSoapScalar(colXml, 'mdc_name');
                if (!name) continue;
                const nullable = this.ParseSoapScalar(colXml, 'mdc_nullable');
                const widthRaw = this.ParseSoapScalar(colXml, 'mdc_width_max');
                columns.push({
                    Name: name,
                    Table: this.ParseSoapScalar(colXml, 'mdc_table_name') ?? table,
                    Alias: alias,
                    DataType: this.ParseSoapScalar(colXml, 'mdc_data_type') ?? null,
                    Description: this.ParseSoapScalar(colXml, 'mdc_description') || undefined,
                    // AllowsNull provable-only: 'mdc_nullable' is an explicit source flag. "0"/"false"/"no" ⇒ NOT NULL.
                    AllowsNull: nullable == null ? undefined : !/^(0|false|no|n)$/i.test(nullable.trim()),
                    MaxLength: widthRaw && /^\d+$/.test(widthRaw) ? Number(widthRaw) : null,
                    IsExtension: (this.ParseSoapScalar(colXml, 'mdc_ext') ?? '').trim() === '1',
                });
            }
        };
        const from: NFFromTable[] = [];
        const fromTables = this.ExtractElements(xml, 'ListFromTable');
        if (fromTables.length > 0) {
            for (const lft of fromTables) {
                const table = this.ParseSoapScalar(lft, 'lsf_from_table') ?? null;
                const alias = this.ParseSoapScalar(lft, 'lsf_from_alias') || null;   // <lsf_from_alias xsi:nil="true"/> → null
                from.push({ Table: table, Alias: alias, Join: this.ParseSoapScalar(lft, 'lsf_from_join') ?? '' });
                readColumns(lft, table, alias);
                for (const dl of this.ExtractElements(lft, 'ListFromTableColumn')) {
                    const n = this.ParseSoapScalar(dl, 'lsc_mdc_name');
                    if (n) defaultList.push(n);
                }
            }
        } else {
            readColumns(xml, null, null);
        }
        // Dedupe by name; a main-table occurrence displaces an earlier joined-table one of the same name.
        const byName = new Map<string, NFDefinedColumn>();
        const isMain = (c: NFDefinedColumn): boolean => !!mainTable && !!c.Table && c.Table.toLowerCase() === mainTable.toLowerCase() && !c.Alias;
        for (const c of columns) {
            const k = c.Name.toLowerCase();
            const prior = byName.get(k);
            if (!prior || (isMain(c) && !isMain(prior))) byName.set(k, c);
        }
        const deduped = [...byName.values()];
        return {
            MainTable: mainTable,
            KeyColumn: this.KeyColumnFromDefinition(mainTable, deduped),
            Columns: deduped,
            DefaultListColumns: defaultList,
            FromTables: from,
            BrokenJoin: this.BrokenJoinReason(mainTable, from, columns),
        };
    }

    /**
     * The reason no GetQuery on this object can compile, read off its own definition — or undefined.
     *
     * Five shapes, all seen live (PLUS 2026-09-25, 875 definitions against ~430 explicit reads) and all
     * predictable without a request: a second root table with no join text (Customer, Certificant); an
     * unbalanced quote or parenthesis in join text (DeferralHeader); a chained comparison `a = b = 'x'`
     * (EventsRegistrant and four siblings); a key compared with a date or text column (`aco_add_date=avt_key`,
     * `cot_cra_code=cra_key` — "Operand type clash" / "Conversion failed"); a join naming a column the
     * definition lists nowhere (`ivd_whs_key`, `spk_key`, `kit_key`, `zz_dummy` — "Invalid column name").
     * Each would otherwise cost a fault per object per process; the fix is in netFORUM's List Table setup.
     */
    private BrokenJoinReason(mainTable: string | null, from: NFFromTable[], columns: NFDefinedColumn[]): string | undefined {
        const typeOf = new Map<string, string>();
        for (const c of columns) if (!typeOf.has(c.Name.toLowerCase())) typeOf.set(c.Name.toLowerCase(), (c.DataType ?? '').toLowerCase());
        const tables = new Set(from.map(f => (f.Table ?? '').toLowerCase()).filter(t => t.length > 0));
        const aliases = new Set(from.map(f => (f.Alias ?? '').toLowerCase()).filter(a => a.length > 0));
        const KEYWORDS = new Set(['and', 'or', 'not', 'null', 'is', 'in', 'like', 'exists', 'between', 'left', 'right', 'inner', 'outer',
            'join', 'on', 'as', 'case', 'when', 'then', 'else', 'end', 'select', 'from', 'where', 'top', 'distinct', 'dbo', 'with', 'nolock']);
        const isKey = (t: string): boolean => /^(av_key|uniqueidentifier)$/.test(t);
        const isDate = (t: string): boolean => /date|time/.test(t);
        const isText = (t: string): boolean => /char|text/.test(t);
        for (const [i, f] of from.entries()) {
            const raw = f.Join ?? '';
            const who = f.Alias ?? f.Table ?? '?';
            // (a) a second root: a from-table after the first with no join text is not joined to anything
            if (i > 0 && raw.trim().length === 0) return `"${who}" is a second root table with no join text`;
            // (b) unbalanced quotes / parentheses — the text cannot be parsed as SQL
            if (((raw.match(/'/g) ?? []).length % 2) === 1) return `unbalanced quote in the join on ${who}: "${raw.trim().slice(0, 80)}"`;
            if ((raw.match(/\(/g) ?? []).length !== (raw.match(/\)/g) ?? []).length) return `unbalanced parenthesis in the join on ${who}: "${raw.trim().slice(0, 80)}"`;
            const join = raw.replace(/'[^']*'/g, "''");
            for (const conjunct of join.split(/\b(?:and|or)\b/i)) {
                // (c) a chained comparison (a = b = 'x') is not T-SQL
                if ((conjunct.match(/(?<![<>!])=(?!=)/g) ?? []).length > 1) return `malformed join on ${who}: "${conjunct.trim().slice(0, 80)}"`;
                // (d) a key compared with a date or text column: the server converts and fails on the first real row
                const cmp = /([A-Za-z_][A-Za-z0-9_.]*)\s*=\s*([A-Za-z_][A-Za-z0-9_.]*)/.exec(conjunct);
                if (cmp) {
                    const tl = typeOf.get(cmp[1].split('.').pop()!.toLowerCase()); const tr = typeOf.get(cmp[2].split('.').pop()!.toLowerCase());
                    if (tl && tr && ((isKey(tl) && (isDate(tr) || isText(tr))) || (isKey(tr) && (isDate(tl) || isText(tl))))) {
                        return `join on ${who} compares "${cmp[1]}" (${tl}) with "${cmp[2]}" (${tr})`;
                    }
                }
            }
            // (e) a column the definition does not list anywhere: the join cannot bind. Function calls, keywords,
            //     table and alias names, and string literals are not columns.
            const withoutCalls = join.replace(/[A-Za-z_][A-Za-z0-9_]*\s*\(/g, '(');
            for (const tok of withoutCalls.match(/[A-Za-z_][A-Za-z0-9_]*/g) ?? []) {
                const t = tok.toLowerCase();
                if (!t.includes('_') || KEYWORDS.has(t) || tables.has(t) || aliases.has(t) || typeOf.has(t)) continue;
                return `join on ${who} names "${tok}", which the definition lists nowhere`;
            }
        }
        return undefined;
    }

    /**
     * The object's key column from its definition — or undefined when the definition cannot say.
     *
     * The rule, in the order the evidence is strong:
     *   1. among the MAIN table's columns (mdc_table_name = lst_mdt_name, unaliased), the key-typed
     *      column (`av_key`, or `uniqueidentifier`) described "Primary Key" — the vendor's own sample
     *      marks `ind_cst_key` exactly so;
     *   2. else the key-typed main-table column named `<prefix>_key`, then `<prefix>_cst_key`, where
     *      prefix is the main table's column prefix (netFORUM: arp_key, evt_key; the customer subclasses
     *      ind_cst_key / org_cst_key);
     *   3. else the main table's first key-typed column in document order (the sample lists the PK first).
     * Without a main table the naming rule alone is applied to all columns and nothing else is guessed:
     * measured on a live tenant, 493 of 878 objects carry more than one `<x>_key` column, and the most
     * frequent prefix is NOT the object's own (AccountingPeriod's would pick atc_key over arp_key) —
     * so a key that cannot be anchored to the main table is left to the sample-based classifier.
     */
    private KeyColumnFromDefinition(mainTable: string | null, columns: NFDefinedColumn[]): string | undefined {
        const isKeyType = (t: string | null): boolean => !!t && /^(av_key|uniqueidentifier)$/i.test(t.trim());
        const main = mainTable
            ? columns.filter(c => !!c.Table && c.Table.toLowerCase() === mainTable.toLowerCase() && !c.Alias)
            : [];
        const pool = main.length > 0 ? main : columns;
        // `_entity_key` is av_key-typed but is not a candidate: xWeb refuses any query that names it.
        const keyed = pool.filter(c => isKeyType(c.DataType) && IsQueryableColumn(c.Name));
        if (keyed.length === 0) return undefined;
        const described = keyed.find(c => /^primary\s+key$/i.test((c.Description ?? '').trim()));
        if (main.length > 0 && described) return described.Name;
        const prefixCounts = new Map<string, number>();
        for (const c of pool) {
            const p = c.Name.toLowerCase().split('_')[0];
            if (p) prefixCounts.set(p, (prefixCounts.get(p) ?? 0) + 1);
        }
        const prefix = [...prefixCounts.entries()].sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))[0]?.[0];
        if (prefix) {
            const exact = keyed.find(c => c.Name.toLowerCase() === `${prefix}_key`);
            if (exact) return exact.Name;
            const cst = keyed.find(c => c.Name.toLowerCase() === `${prefix}_cst_key`);
            if (cst) return cst.Name;
        }
        return main.length > 0 ? keyed[0].Name : undefined;
    }

    /**
     * The definition's columns as ExternalFieldSchema, overlaid on the declared baseline by name.
     * IsPrimaryKey is the declared flag when the declaration carries a key, else the definition's key
     * column — never anything the enumeration said. Declared fields the definition does not list are
     * re-added (the provable-only baseline is never lost).
     */
    private FieldsFromDefinition(def: NFQueryDefinition, declaredByName: Map<string, ExternalFieldSchema>): ExternalFieldSchema[] {
        const declaredHasKey = [...declaredByName.values()].some(f => f.IsPrimaryKey === true);
        const keyLower = !declaredHasKey && def.KeyColumn ? def.KeyColumn.toLowerCase() : undefined;
        const out: ExternalFieldSchema[] = [];
        const seen = new Set<string>();
        for (const c of def.Columns) {
            const k = c.Name.toLowerCase();
            if (seen.has(k)) continue;
            seen.add(k);
            const declared = declaredByName.get(k);
            out.push({
                Name: c.Name,
                Label: declared?.Label ?? c.Name,
                Description: declared?.Description ?? c.Description,
                DataType: declared?.DataType ?? this.MapSoapType(c.DataType),
                IsRequired: declared?.IsRequired ?? false,
                AllowsNull: c.AllowsNull,
                IsPrimaryKey: declared?.IsPrimaryKey === true || k === keyLower,
                IsUniqueKey: declared?.IsUniqueKey ?? false,
                IsReadOnly: declared?.IsReadOnly ?? false,
                IsForeignKey: declared?.IsForeignKey ?? false,
                ForeignKeyTarget: declared?.ForeignKeyTarget ?? null,
                MaxLength: c.MaxLength,
            });
        }
        for (const [k, f] of declaredByName) {
            if (!seen.has(k)) out.push(f);
        }
        return out;
    }

    private MapSoapType(sqlType: string | null): string {
        if (!sqlType) return 'string';
        const t = sqlType.toLowerCase();
        if (/(date|time)/.test(t)) return 'datetime';
        if (/(int|bigint|smallint|tinyint|av_count|av_seq)/.test(t)) return 'number';
        if (/(decimal|numeric|money|float|real|av_percent)/.test(t)) return 'decimal';
        if (/(bit|av_flag)/.test(t)) return 'boolean';
        if (/(uniqueidentifier|av_key)/.test(t)) return 'string';
        return 'string';
    }

    // ─── FetchChanges — GetQuery door walk + per-facade watermark ─────

    /**
     * Fetches a batch via the GetQuery door. Walks the IO's access path from Configuration: the door
     * (GetQuery), the query object name, and any top modifier (@TOP -1 to bypass the DataGrid row
     * cap). Incremental sync uses the IO's per-facade `IncrementalWatermarkField` in the
     * szWhereClause — there is NO canonical LastModifiedDate; the field is metadata-driven.
     *
     * Full-record pass-through: every parsed row becomes ExternalRecord.Fields verbatim — never a
     * filtered/narrow literal — so the framework's custom-column capture sees every column the query
     * returned, including customer-added ones.
     *
     * szColumnList is the EMPTY string, never `*`: the vendor documents `*` as an invalid value that
     * faults the call, and an empty list as "the default column listing for the object's primary
     * table" with the primary key always first. The row therefore carries the tenant's default list
     * columns; when the IO's watermark column is not among them the batch says so
     * (WATERMARK_COLUMN_ABSENT) rather than silently never advancing.
     */
    public override async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
        if (this.DefinitionsOnlyMode()) {
            throw new Error(
                `NetForum GetQuery(${ctx.ObjectName}) not attempted: definitions-only mode ` +
                `(${join(NetForumConnector.OperatorRoot, '.nf-definitions-only')} exists) — this run collects the objects' ` +
                `GetQueryDefinition answers and sends no GetQuery. Remove the file to sample and sync.`,
            );
        }
        const auth = await this.Authenticate(ctx.CompanyIntegration, ctx.ContextUser) as NFAuthContext;
        const obj = this.GetCachedObject(ctx.CompanyIntegration.IntegrationID, ctx.ObjectName);
        const cfg = this.ParseObjectConfig(obj);
        const accessPath = cfg.accessPath ?? {};

        const queryObject = accessPath.queryObject ?? accessPath.doorArgs?.szObjectName ?? ctx.ObjectName;
        // The key: the persisted catalog's primary key when it has one, else the key column the object's
        // OWN definition names (GetQueryDefinition, one metadata call per object per instance). The
        // second case is the first discovery — enumerated objects are sampled before their fields are
        // persisted. NEVER the enumeration's obj_key: that is the facade object's GUID, not a column,
        // and sending it as one is what faulted every read on a live tenant (EnumeratedObjectIdByObject).
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const faultKey = ctx.CompanyIntegration?.ID ?? '';
        const grantKey = `${faultKey}|${ctx.ObjectName.toLowerCase()}`;
        // The object's definition is consulted for EVERY read (one GetQueryDefinition per object per instance): it
        // names the key when nothing is persisted, it is the column list that carries every column, and it says
        // when no query on the object can compile at all.
        this.LoadLearned(faultKey);
        const def = await this.DefinitionFor(ci, ctx.ContextUser as UserInfo, ctx.ObjectName);
        const learnedRefusal = this.LearnedRefusals.get(grantKey) ?? this.MissingFromTableReason(def, faultKey);
        if (learnedRefusal) {
            throw new Error(
                `NetForum GetQuery(${ctx.ObjectName}) not attempted: ${learnedRefusal}. Every GetQuery on it faults, ` +
                `so none is sent (learned from an earlier fault on this installation; see .nf-learned.json); ` +
                `the fix is in netFORUM's List Table setup for "${ctx.ObjectName}".`,
            );
        }
        if (def?.BrokenJoin) {
            throw new Error(
                `NetForum GetQuery(${ctx.ObjectName}) not attempted: this object's list definition cannot compile — ` +
                `${def.BrokenJoin}. Every GetQuery on it faults (default list and explicit list alike), so none is sent; ` +
                `the fix is in netFORUM's List Table setup for "${ctx.ObjectName}".`,
            );
        }
        const persistedKey = this.PrimaryKeyFieldName(obj);
        const definedKey = persistedKey ? undefined : def?.KeyColumn;
        const pkField = persistedKey ?? definedKey;
        const orderingKey = cfg.stableOrderingKey ?? this.InjectedKeyByObject.get(grantKey) ?? pkField;

        // Keyset pagination requires a total order to seek on. With one, we page via
        // `@TOP <BatchSize>` + `WHERE <key> > <AfterKeyValue> ORDER BY <key>`; the metadata
        // `topModifier` is ignored because its only purpose was bypassing the DataGrid row cap,
        // which paging supersedes. Without an ordering key we cannot page safely, so we keep the
        // legacy single unbounded fetch and say so via a warning instead of failing silently.
        // UNPROVEN with an empty szColumnList: the vendor's GetQuery page says @TOP -1 needs named
        // columns ("specific, named fields must be passed ... in order to process using the -1
        // parameter"). If this fallback faults on a live tenant, that sentence is why.
        const canPaginate = !!orderingKey;
        const pageSize = ctx.BatchSize > 0 ? ctx.BatchSize : 0;
        // A discovery sample asks for SampleTargetRecords rows and stops there, so a page larger than
        // the target is waste, and an UNBOUNDED fetch is the whole table read to keep fifty rows —
        // measured live as hours per discovery and the resident memory that the kernel killed.
        // Bound the sample by its target whether or not the object can page: `@TOP n` needs no
        // ordering key (the door builds a plain SELECT TOP n); it only means the rows come in the
        // door's natural order rather than from a keyset position, which is fine for widths and
        // key statistics. Read duck-typed so the connector still compiles against an older engine.
        const sampleCtx = ctx as FetchContext & { IsDiscoverySample?: boolean; SampleTargetRecords?: number };
        const sampleTarget = sampleCtx.IsDiscoverySample === true
            && typeof sampleCtx.SampleTargetRecords === 'number' && sampleCtx.SampleTargetRecords > 0
            ? Math.floor(sampleCtx.SampleTargetRecords)
            : 0;
        const effectivePage = sampleTarget > 0
            ? (pageSize > 0 ? Math.min(pageSize, sampleTarget) : sampleTarget)
            : pageSize;
        const topRows = canPaginate || sampleTarget > 0 ? effectivePage : 0;
        const topModifier = topRows > 0
            ? `@TOP ${topRows}`
            : (accessPath.doorArgs?.topModifier ?? '@TOP -1');
        const szObjectName = topModifier ? `${queryObject} ${topModifier}` : queryObject;

        const watermarkField = obj.IncrementalWatermarkField ?? undefined;
        // Empty by default (the tenant's default list columns), never `*` — see the class header. An IO
        // may declare Configuration.columnList when its default list lacks a column the connector needs;
        // the door returns ONLY named columns, so a declared list is completed with the PK, the ordering
        // key and the watermark — the three columns this method itself reads.
        const args: Record<string, string> = {
            szObjectName,
            szColumnList: this.ColumnListFor(cfg, [pkField, orderingKey, watermarkField]),
        };
        // An object whose definition lists its columns is read with ALL of them. The empty list would return the
        // tenant's default list — a handful of columns (2–18 of up to 300 on a live tenant), which is a partial
        // read presented as a full one — or fault on a `*` default. Declared Configuration.columnList still wins.
        if (!args.szColumnList && def && def.Columns.length > 0) {
            // A statement that broke once is broken with any list: the default list is not a fallback for it.
            if (this.ExplicitListUnsendable.has(grantKey)) throw this.NothingValidToSend(ctx.ObjectName);
            const full = this.ExplicitColumnListFor(obj, [pkField, orderingKey, watermarkField], grantKey);
            if (full) args.szColumnList = full;
        }

        // ORDER BY and WHERE name the key and the watermark QUALIFIED by their table (or alias) whenever
        // the object's definition knows it. xWeb adds its own copy of the object's primary key to every
        // query it builds, so with an explicit column list the result carries the key column twice, and
        // an unqualified `ORDER BY cpo_key` is then "Ambiguous column name 'cpo_key'" — 15 of 16 faults on
        // a live tenant's first explicit-list run (2026-09-24). The default-list reads never hit it (the
        // key appears once). A qualified reference resolves in both cases.
        const predicates: string[] = [];
        if (ctx.WatermarkValue && watermarkField) {
            predicates.push(`${this.QualifiedColumn(ctx.ObjectName, watermarkField, grantKey)} >= '${this.EscapeSqlLiteral(ctx.WatermarkValue)}'`);
        }
        if (canPaginate && ctx.AfterKeyValue) {
            predicates.push(`${this.QualifiedColumn(ctx.ObjectName, orderingKey!, grantKey)} > '${this.EscapeSqlLiteral(ctx.AfterKeyValue)}'`);
        }
        if (predicates.length > 0) args.szWhereClause = predicates.join(' AND ');

        if (orderingKey) args.szOrderBy = this.QualifiedColumn(ctx.ObjectName, orderingKey, grantKey);

        const url = `${auth.Config.BaseURL}${this.SoapEndpoint(cfg)}`;

        // Once this connection is known to have an unusable default list, lead with the explicit list
        // rather than paying another fault to re-discover what we already know (see the field's doc).
        //
        // Deliberately narrow. This only REORDERS two requests that were going to be sent in sequence
        // anyway, and only when an explicit list actually exists; with nothing better to send it falls
        // through to the original empty request unchanged. So a tenant whose defaults are fine never
        // reaches it, and — because netFORUM configures the default list PER OBJECT — an object whose
        // own default is fine on a tenant where others are not still gets its normal request.
        if (this.SelectNotAuthorized.has(grantKey)) {
            throw new Error(
                `NetForum GetQuery(${ctx.ObjectName}) not attempted: this xWeb account is not authorized to ` +
                `Select on "${ctx.ObjectName}" (xWeb said so earlier on this connection; a grant does not appear ` +
                `between calls, and each retry is a fault against the daily budget that locks the account).`,
            );
        }
        if (!args.szColumnList && this.DefaultColumnListUnusable.has(faultKey)) {
            const known = this.ExplicitColumnListFor(obj, [pkField, orderingKey, watermarkField], grantKey);
            if (known) {
                args.szColumnList = known;
            } else {
                // The tenant's default list is known to be unusable and nothing describes this object's
                // columns (no definition, no persisted fields — or the last list broke xWeb's SQL). The only
                // request left is one that will fault, and faults are what lock the account — so it is not sent.
                throw this.NothingValidToSend(ctx.ObjectName);
            }
        }
        // The vendor: "@TOP -1 ... specific, named fields must be passed ... in szColumnList". The
        // legacy unbounded fetch of a keyless object therefore names its columns when it can.
        if (!args.szColumnList && /@TOP\s+-1\b/i.test(szObjectName)) {
            const named = this.ExplicitColumnListFor(obj, [pkField, orderingKey, watermarkField], grantKey);
            if (named) args.szColumnList = named;
        }
        let sentEmptyColumnList = !args.szColumnList;
        let sentArgs: Record<string, string> = args;

        // Sampling runs objects in parallel. While this connection's default-list verdict is unknown, only
        // ONE empty-list request is in flight; a concurrent caller waits for its answer and then decides as
        // if it had come later — otherwise every concurrent first request pays its own "'*' is not a valid
        // value" fault before the latch can tell it (3 of a live run's 10 faults). Once the verdict is known
        // either way there is nothing to wait for, and requests are never serialised.
        if (sentEmptyColumnList && !this.DefaultListVerdict.has(faultKey)) {
            const inflight = this.DefaultListProbe.get(faultKey);
            if (inflight) {
                await inflight;
                if (this.DefaultColumnListUnusable.has(faultKey)) {
                    const known = this.ExplicitColumnListFor(obj, [pkField, orderingKey, watermarkField], grantKey);
                    if (!known) throw this.NothingValidToSend(ctx.ObjectName);
                    args.szColumnList = known;
                    sentEmptyColumnList = false;
                }
            }
        }
        let response: RESTResponse;
        if (sentEmptyColumnList && !this.DefaultListVerdict.has(faultKey) && !this.DefaultListProbe.has(faultKey)) {
            let settle: () => void = () => undefined;
            this.DefaultListProbe.set(faultKey, new Promise<void>(resolve => { settle = resolve; }));
            try {
                response = await this.SendGetQuery(url, args, auth.Token);
                // The verdict is recorded BEFORE the waiters wake, so they read it rather than re-probe.
                if (this.IsInvalidDefaultColumnListFault(response)) { this.DefaultColumnListUnusable.add(faultKey); this.SaveLearned(); }
                this.DefaultListVerdict.add(faultKey);
            } finally {
                this.DefaultListProbe.delete(faultKey);
                settle();
            }
        } else {
            response = await this.SendGetQuery(url, args, auth.Token);
        }

        // The door can reject ITS OWN default list. An empty szColumnList asks xWeb for the object's
        // configured default columns, and on a tenant where that default is `*` the request faults with
        // "'*' is not a valid value for szColumnList" — a fault about the tenant's configuration, not
        // about anything this connector sent. Observed on the BC sandbox 2026-09-18: 862 of 888 objects
        // faulted this way during discovery, ~15s each, which exhausted the run deadline before a single
        // row was persisted. The 26 that worked were exactly the 26 carrying a declared columnList.
        //
        // Retry ONCE with an explicit list. Named columns bypass the default entirely, so this turns a
        // certain failure into a normal fetch without changing behaviour on tenants whose default is
        // usable — they never reach this branch.
        if (this.IsInvalidDefaultColumnListFault(response)) {
            // Remember, but ONLY when the empty list is what the door rejected. A declared
            // Configuration.columnList drawing this same fault is a different defect and must keep
            // surfacing per call, rather than silently changing what every later object sends.
            if (sentEmptyColumnList) this.DefaultColumnListUnusable.add(faultKey);
            const explicit = this.ExplicitColumnListFor(obj, [pkField, orderingKey, watermarkField], grantKey);
            if (explicit) {
                sentArgs = { ...args, szColumnList: explicit };
                response = await this.SendGetQuery(url, sentArgs, auth.Token);
            }
        }

        // A fault teaches, and what it teaches is kept for the object, for the connection and on disk: SQL Server
        // names EVERY column it could not resolve and EVERY qualifier it could not bind, xWeb names a table that
        // does not exist. Learn all of it at once, rebuild the list and retry — up to three rounds, because one
        // fault can hide the next class (a table's columns fall away, then the key on it). A fault that teaches
        // nothing new (the statement broke, "Invalid query.", or the rebuilt list would be the one just refused)
        // ends it: that list is not sent again on this installation. Every learn is persisted (SaveLearned), so a
        // restart — the RSU restarts the API between discovery and the first sync — does not re-pay a single fault.
        for (let round = 0; round < 3 && response.Status >= 400 && sentArgs.szColumnList; round++) {
            const faultText = this.FaultText(response.Body);
            if (!faultText) break;                                   // no SOAP fault (gateway, timeout): nothing to learn
            if (this.IsSqlSyntaxFault(response.Body)) { this.ExplicitListUnsendable.add(grantKey); this.SaveLearned(); break; }
            let learned = false;
            const invalid = this.InvalidColumnNames(response.Body);
            if (invalid.length > 0) {
                const own = this.UnselectableColumns.get(grantKey) ?? new Set<string>();
                for (const n of invalid) {
                    own.add(n);
                    const col = def?.Columns.find(c => c.Name.toLowerCase() === n);
                    if (col?.Table) {
                        const pairs = this.UnresolvablePairs.get(faultKey) ?? new Set<string>();
                        pairs.add(`${col.Table.toLowerCase()}.${n}`);
                        this.UnresolvablePairs.set(faultKey, pairs);
                    }
                }
                this.UnselectableColumns.set(grantKey, own);
                learned = true;
            }
            const missing = this.InvalidObjectNames(response.Body);
            if (missing.length > 0) {
                const tables = this.MissingTables.get(faultKey) ?? new Set<string>();
                for (const t of missing) tables.add(t);
                this.MissingTables.set(faultKey, tables);
                learned = true;
                const reason = this.MissingFromTableReason(def, faultKey);
                if (reason) { this.LearnedRefusals.set(grantKey, reason); this.SaveLearned(); break; }
            }
            const unbound = this.UnboundQualifiers(response.Body);
            if (unbound.length > 0) {
                const own = this.UnexposedQualifiers.get(grantKey) ?? new Set<string>();
                for (const t of unbound) own.add(t);
                this.UnexposedQualifiers.set(grantKey, own);
                learned = true;
            }
            if (!learned) { this.ExplicitListUnsendable.add(grantKey); this.SaveLearned(); break; }
            const rebuilt = this.ExplicitColumnListFor(obj, [pkField, orderingKey, watermarkField], grantKey);
            if (!rebuilt || rebuilt === sentArgs.szColumnList) { this.ExplicitListUnsendable.add(grantKey); this.SaveLearned(); break; }
            this.SaveLearned();
            sentArgs = { ...sentArgs, szColumnList: rebuilt };
            if (sentArgs.szOrderBy && orderingKey) sentArgs.szOrderBy = this.QualifiedColumn(ctx.ObjectName, orderingKey, grantKey);
            if (sentArgs.szWhereClause) {
                const predicates: string[] = [];
                if (ctx.WatermarkValue && watermarkField) predicates.push(`${this.QualifiedColumn(ctx.ObjectName, watermarkField, grantKey)} >= '${this.EscapeSqlLiteral(ctx.WatermarkValue)}'`);
                if (canPaginate && ctx.AfterKeyValue) predicates.push(`${this.QualifiedColumn(ctx.ObjectName, orderingKey!, grantKey)} > '${this.EscapeSqlLiteral(ctx.AfterKeyValue)}'`);
                sentArgs.szWhereClause = predicates.join(' AND ');
            }
            response = await this.SendGetQuery(url, sentArgs, auth.Token);
        }

        if (response.Status < 200 || response.Status >= 300) {
            if (this.IsSelectNotAuthorizedFault(response)) this.SelectNotAuthorized.add(grantKey);
            // The fault text is SQL Server's or xWeb's; the SHAPE of what we sent is ours to report, or
            // the next reader of the run log is left guessing which parameter the door rejected. A broken
            // statement also reports the qualifiers the list used — the next log line names the culprit.
            const syntaxHint = this.IsSqlSyntaxFault(response.Body) ? ` [qualifiers: ${this.QualifierSummary(obj)}]` : '';
            throw new Error(
                `NetForum GetQuery(${ctx.ObjectName}) failed: HTTP ${response.Status}${this.SoapFault(response.Body)}` +
                ` [sent: ${this.DescribeRequestShape(sentArgs)}]${syntaxHint}`,
            );
        }

        const rows = this.NormalizeResponse(response.Body, null);
        const warnings: FetchWarning[] = [];
        if (rows.length === 0) {
            warnings.push({ Code: 'ZERO_ROWS', Message: `GetQuery(${szObjectName}) returned no rows.` });
        }
        if (!canPaginate && topRows === 0) {
            warnings.push({
                Code: 'UNPAGINATED_FETCH',
                Message:
                    `NetForum "${ctx.ObjectName}" has no stable ordering key (Configuration.stableOrderingKey ` +
                    `or a primary-key field), so GetQuery ran unbounded (${topModifier}) and returned the ` +
                    `entire result set in one call. Declare an ordering key to enable keyset paging.`,
                Data: { ObjectName: ctx.ObjectName, RowCount: rows.length },
            });
        } else if (!canPaginate) {
            warnings.push({
                Code: 'SAMPLE_BOUNDED_WITHOUT_KEY',
                Message:
                    `NetForum "${ctx.ObjectName}" has no stable ordering key, so this discovery sample took the ` +
                    `first ${topRows} rows in the door's natural order (${topModifier}) rather than a keyset page. ` +
                    `Widths and key statistics are unaffected; a key would let later syncs page.`,
                Data: { ObjectName: ctx.ObjectName, RowCount: rows.length, SampleTargetRecords: sampleTarget },
            });
        }
        // An empty szColumnList returns the tenant's DEFAULT list columns for the query object, which
        // need not include the IO's watermark column. Without it NewWatermarkValue stays undefined and
        // every sync re-reads the same window — a green run that never advances. Say so.
        if (watermarkField && rows.length > 0 && !rows.some(row => watermarkField in row)) {
            warnings.push({
                Code: 'WATERMARK_COLUMN_ABSENT',
                Message:
                    `NetForum "${ctx.ObjectName}" declares IncrementalWatermarkField "${watermarkField}", but no row of ` +
                    `this GetQuery batch carries that column: with an empty szColumnList, xWeb returns the tenant's ` +
                    `default list columns for "${queryObject}" and "${watermarkField}" is not among them. The watermark ` +
                    `cannot advance, so each sync re-reads the same window. Declare Configuration.columnList on the IO ` +
                    `(the default columns plus "${watermarkField}"), add the column to the object's default list in ` +
                    `netFORUM (List Table setup), or point IncrementalWatermarkField at a column the default list returns.`,
                Data: { ObjectName: ctx.ObjectName, WatermarkField: watermarkField, Columns: Object.keys(rows[0]) },
            });
        }

        // Highest ordering-key value seen → keyset resume position when no watermark exists.
        // With no key known and the tenant's default list sent, the vendor guarantees "the primary key
        // for the object will still be returned in the node as the first child" — so the first column
        // of each row identifies the record, and its NAME is reported for the key classifier.
        // xWeb prepends the object's primary key to EVERY query it builds (INT-45: the explicit list carried it
        // twice), so the first column of a row identifies the record whichever list was sent — and when our
        // key was left out of the list (its table unexposed), that injected column is the key from here on.
        if (pkField && rows.length > 0 && !(pkField in rows[0]) && !(pkField.toLowerCase() in rows[0])) {
            this.InjectedKeyByObject.set(grantKey, Object.keys(rows[0])[0]);
            this.SaveLearned();
        }
        const firstColumn = !pkField && rows.length > 0 ? Object.keys(rows[0])[0] : undefined;
        if (firstColumn) {
            warnings.push({
                Code: 'KEY_FROM_DEFAULT_LIST_FIRST_COLUMN',
                Message:
                    `NetForum "${ctx.ObjectName}" has no known key column; with the tenant's default column list ` +
                    `xWeb returns the object's primary key as the first column of every row, so "${firstColumn}" ` +
                    `identifies these records.`,
                Data: { ObjectName: ctx.ObjectName, FirstColumn: firstColumn },
            });
        }
        const injected = this.InjectedKeyByObject.get(grantKey);
        const idColumn = pkField && rows.length > 0 && !(pkField in rows[0]) && injected ? injected : pkField;
        const seekColumn = orderingKey && rows.length > 0 && !(orderingKey in rows[0]) && injected ? injected : orderingKey;
        let maxKey: string | undefined;
        const records: ExternalRecord[] = rows.map(row => {
            const externalID = idColumn ? String(row[idColumn] ?? '') : (firstColumn ? String(row[firstColumn] ?? '') : '');
            if (seekColumn) {
                const v = row[seekColumn];
                if (v != null) { const s = String(v); if (maxKey === undefined || s > maxKey) maxKey = s; }
            }
            return { ExternalID: externalID, ObjectType: ctx.ObjectName, Fields: row };
        });

        // A full page implies another may exist; a short page is the last one. Only meaningful when
        // paginating — without an ordering key there is no seek position, so the single unbounded
        // fetch is by definition complete.
        const hasMore = canPaginate && topRows > 0 && rows.length >= topRows && maxKey !== undefined;

        // Watermark: when this IO has a watermark field, the engine narrows next sync from the max
        // seen. Advance ONLY on the final page — advancing mid-scan would let a crash between pages
        // skip every later row older than the new watermark.
        let newWatermark: string | undefined;
        if (watermarkField && !hasMore) {
            for (const row of rows) {
                const v = row[watermarkField];
                if (v != null) { const s = String(v); if (newWatermark === undefined || s > newWatermark) newWatermark = s; }
            }
        }

        return {
            Records: records,
            HasMore: hasMore,
            Warnings: warnings.length > 0 ? warnings : undefined,
            NewWatermarkValue: newWatermark,
            NextAfterKeyValue: maxKey,
        };
    }

    private EscapeSqlLiteral(v: string): string { return v.replace(/'/g, "''"); }

    /**
     * The szColumnList for one fetch: empty (tenant default list) unless the IO declares
     * Configuration.columnList. A declared list is completed with `required` — the primary key, the
     * ordering key and the watermark column — because the door returns ONLY the named columns and
     * those are what FetchChanges reads. Comma-joined, as the vendor's own examples are; duplicates
     * (case-insensitive) collapse to the first spelling.
     */
    /**
     * True when a GetQuery response is xWeb refusing its OWN configured default column list. The door
     * substitutes the object's default list for an empty szColumnList, and a tenant whose default is
     * `*` gets that value rejected by the same call that supplied it. Matched on the vendor's wording
     * rather than the status alone, so an unrelated HTTP 500 still surfaces as the error it is.
     */
    private IsInvalidDefaultColumnListFault(response: { Status: number; Body: unknown }): boolean {
        if (response.Status < 400) return false;
        const fault = this.SoapFault(response.Body);
        return typeof fault === 'string' && /not a valid value for szColumnList/i.test(fault);
    }

    /** The SOAP faultstring, unescaped; '' when the body carries none. */
    private FaultText(body: unknown): string {
        return this.ParseSoapScalar(this.AsText(body), 'faultstring') ?? '';
    }

    /**
     * Every column SQL Server reported unresolvable in a fault ("Invalid column name 'x'." — one line per
     * column, all of them in one answer), lowercased, each once. Empty when the fault says something else.
     */
    private InvalidColumnNames(body: unknown): string[] {
        const out = new Set<string>();
        const re = /Invalid column name '([^']+)'/gi;
        const text = this.FaultText(body);
        let m: RegExpExecArray | null;
        while ((m = re.exec(text)) !== null) out.add(m[1].trim().toLowerCase());
        return [...out];
    }

    /** "Incorrect syntax near …" — the statement itself broke; no column is named, nothing can be dropped. */
    /** Every table xWeb's SQL reported as not existing ("Invalid object name 'T'."), lowercased, each once. */
    private InvalidObjectNames(body: unknown): string[] {
        const out = new Set<string>();
        const re = /Invalid object name '([^']+)'/gi;
        const text = this.FaultText(body);
        let m: RegExpExecArray | null;
        while ((m = re.exec(text)) !== null) out.add(m[1].trim().toLowerCase());
        return [...out];
    }

    /** Every qualifier SQL Server could not bind (`The multi-part identifier "T.col" could not be bound`), lowercased, each once. */
    private UnboundQualifiers(body: unknown): string[] {
        const out = new Set<string>();
        const re = /multi-part identifier "([^".]+)\.[^"]+" could not be bound/gi;
        const text = this.FaultText(body);
        let m: RegExpExecArray | null;
        while ((m = re.exec(text)) !== null) out.add(m[1].trim().toLowerCase());
        return [...out];
    }

    private IsSqlSyntaxFault(body: unknown): boolean {
        return /Incorrect syntax near/i.test(this.FaultText(body));
    }

    /** The distinct qualifiers (alias or table) the object's definition supplies — names only, for a fault message. */
    private QualifierSummary(obj: MJIntegrationObjectEntity): string {
        const def = this.DefinitionByObject.get(obj.Name.toLowerCase()) ?? null;
        if (!def) return 'none (no definition for the object)';
        const qs = [...new Set(def.Columns.map(c => c.Alias ?? c.Table ?? '').filter(q => q.length > 0))];
        return qs.slice(0, 20).map(q => `"${q}"`).join(', ') + (qs.length > 20 ? `, … (${qs.length} distinct)` : '');
    }

    /** The refusal to send a request known to fault: the default list is unusable and no list can be built. */
    private NothingValidToSend(objectName: string): Error {
        return new Error(
            `NetForum GetQuery(${objectName}) not attempted: this connection's default column list is ` +
            `unusable ('*' faulted earlier) and no column list can be sent for "${objectName}" — ` +
            `GetQueryDefinition described no columns and none are persisted, or the last list broke xWeb's SQL. ` +
            `Nothing valid to send.`,
        );
    }

    /**
     * An explicit, non-empty column list for an object whose tenant default is unusable, drawn from the
     * best source available at the moment of the call:
     *   1. columns GetQueryDefinition returned earlier in this discovery run (introspection — the
     *      fields are not persisted yet, so this is the only source),
     *   2. the object's cached fields (sync — discovery has already persisted them).
     * `required` is appended because the door returns ONLY named columns and FetchChanges reads the
     * primary key, the ordering key and the watermark. Empty when nothing is known, which leaves the
     * original fault to surface rather than sending a request we cannot justify.
     */
    private ExplicitColumnListFor(obj: MJIntegrationObjectEntity, required: Array<string | undefined>, learnKey?: string): string {
        // Preferred source: the object's definition, which knows each column's table and alias. The
        // vendor requires the alias (or table) prefix wherever a table is joined more than once
        // ("ambiguous column name" / "Object Reference Not Set" otherwise), so every column is sent
        // qualified — `Membership.mbr_src_code`, `co_individual.ind_cst_key` — and each name once.
        // The key column leads, so a row's first element is the key whichever list was sent.
        //
        // `learnKey` (`<connection>|<object>`) applies what earlier faults taught about this object on
        // this connection: columns xWeb could not resolve are left out, and a list that broke xWeb's SQL
        // is not rebuilt at all ('' — the callers' "nothing to send" paths then speak, without a request).
        if (learnKey && this.ExplicitListUnsendable.has(learnKey)) return '';
        const unselectable = learnKey ? this.UnselectableColumns.get(learnKey) : undefined;
        const def = this.DefinitionByObject.get(obj.Name.toLowerCase()) ?? null;
        const out: string[] = [];
        const seen = new Set<string>();
        const add = (name: string | undefined, qualifier: string | null): void => {
            if (!name || !IsQueryableColumn(name) || !IsPlainIdentifier(name)) return;
            const key = name.toLowerCase();
            if (seen.has(key) || unselectable?.has(key)) return;
            seen.add(key);
            const q = qualifier && IsPlainIdentifier(qualifier) ? qualifier : null;
            out.push(q ? `${q}.${name}` : name);
        };
        if (def && def.Columns.length > 0) {
            const unexposed = learnKey ? this.UnexposedQualifiers.get(learnKey) : undefined;
            const qualifierOf = (c: NFDefinedColumn): string | null => {
                const q = c.Alias ?? c.Table;
                return q && unexposed?.has(q.toLowerCase()) ? null : q;
            };
            // An Extender column under an ALIASED join is unselectable (see NFDefinedColumn.IsExtension).
            const sendable = def.Columns.filter(c => !(c.IsExtension && c.Alias) && !this.ColumnUnresolvable(c, learnKey));
            const lead = sendable.find(c => !!def.KeyColumn && c.Name.toLowerCase() === def.KeyColumn!.toLowerCase());
            // The key leads — unless its table is unexposed: then it is left out (xWeb prepends the object's
            // primary key to every query) so that a bare ORDER BY on it names one column, not two.
            const keyOmitted = !!lead && qualifierOf(lead) === null && !!(lead.Alias ?? lead.Table);
            if (lead && !keyOmitted) add(lead.Name, qualifierOf(lead));
            for (const c of sendable) {
                if (keyOmitted && lead && c.Name.toLowerCase() === lead.Name.toLowerCase()) { seen.add(c.Name.toLowerCase()); continue; }
                add(c.Name, qualifierOf(c));
            }
            for (const r of required) { if (keyOmitted && lead && r && r.toLowerCase() === lead.Name.toLowerCase()) continue; add(r, null); }
            return out.join(',');
        }
        const discovered = this.DiscoveredColumnsByObject.get(obj.Name.toLowerCase()) ?? [];
        const known = discovered.length > 0
            ? discovered
            : this.GetCachedFields(obj.ID).map(f => f.Name).filter((n): n is string => !!n);
        if (known.length === 0) return '';
        for (const c of [...known, ...required]) add(c ?? undefined, null);
        return out.join(',');
    }

    /**
     * `<alias-or-table>.<column>` when this instance's parsed definition of the object knows which table
     * carries the column, else the bare column name. Rows still come back with the bare, lowercased column
     * name, so readers keep using `name`; only the SQL sent qualifies.
     */
    private QualifiedColumn(objectName: string, name: string, learnKey?: string): string {
        const def = this.DefinitionByObject.get(objectName.toLowerCase()) ?? null;
        const col = def?.Columns.find(c => c.Name.toLowerCase() === name.toLowerCase());
        const q = col ? (col.Alias ?? col.Table) : null;
        if (q && learnKey && this.UnexposedQualifiers.get(learnKey)?.has(q.toLowerCase())) return name;
        return q && IsPlainIdentifier(q) ? `${q}.${name}` : name;
    }

    /** "Account is not authorized to perform Select on <object> object" — a grant, not a query, failed. */
    private IsSelectNotAuthorizedFault(response: { Status: number; Body: unknown }): boolean {
        if (response.Status < 400) return false;
        const fault = this.SoapFault(response.Body);
        return typeof fault === 'string' && /not authorized to perform select/i.test(fault);
    }

    /**
     * The shape of a GetQuery request for a fault message: which object and TOP, how many columns were
     * named (or that the default list was asked for), the ORDER BY column, and how many WHERE
     * predicates — never a literal value, so a key or watermark value is not copied into a log.
     */
    private DescribeRequestShape(args: Record<string, string>): string {
        const cols = args.szColumnList
            ? `${args.szColumnList.split(',').filter(c => c.trim().length > 0).length} named column(s)`
            : 'default list (empty szColumnList)';
        const where = args.szWhereClause
            ? `${args.szWhereClause.split(/\s+AND\s+/i).length} predicate(s)`
            : 'none';
        return `szObjectName="${args.szObjectName}"; szColumnList=${cols}; szOrderBy=${args.szOrderBy ?? 'none'}; szWhereClause=${where}`;
    }

    private ColumnListFor(cfg: NFObjectConfig, required: Array<string | undefined>): string {
        const declared = Array.isArray(cfg.columnList)
            ? cfg.columnList.filter((c): c is string => typeof c === 'string' && c.trim().length > 0).map(c => c.trim())
            : [];
        if (declared.length === 0) return '';
        const out: string[] = [];
        const seen = new Set<string>();
        for (const c of [...declared, ...required]) {
            if (!c) continue;
            const key = c.toLowerCase();
            if (seen.has(key)) continue;
            seen.add(key);
            out.push(c);
        }
        return out.join(',');
    }

    // ─── CRUD — SOAP facade ops via per-operation metadata columns ────

    /**
     * Create via the SOAP operation named in the IO's CreateBodyKey / Configuration.writeOps.createOp
     * (e.g. WEBIndividualInsert, InsertFacadeObject). The attributes are wrapped in a SOAP envelope
     * for that operation; the new key is read from the response and routed through BuildCreatedResult,
     * so a 2xx that carries no record key FAILS loudly (the silent-create-loss invariant).
     *
     * Overridden (not the generic per-operation REST path) because the body must be a SOAP envelope,
     * not a JSON body — the generic CreateRecord builds a JSON body. We still honor the metadata
     * columns (operation name) and still call BuildCreatedResult.
     */
    public override async CreateRecord(ctx: CreateRecordContext): Promise<CRUDResult> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        if (!obj.SupportsCreate) {
            return { Success: false, StatusCode: 0, ErrorMessage: `CreateRecord not supported for "${ctx.ObjectName}".` };
        }
        const cfg = this.ParseObjectConfig(obj);
        const operation = obj.CreateBodyKey ?? cfg.writeOps?.createOp;
        if (!operation) {
            return { Success: false, StatusCode: 0, ErrorMessage: `Create of "${ctx.ObjectName}" has no SOAP operation configured (CreateBodyKey).` };
        }
        const auth = await this.Authenticate(ci, ctx.ContextUser as UserInfo) as NFAuthContext;
        const url = `${auth.Config.BaseURL}${this.SoapEndpoint(cfg)}`;
        const envelope = this.BuildSoapEnvelope(operation, ctx.Attributes, auth.Token);
        const r = await this.MakeRawHTTPRequest(url, 'POST', this.SoapHeaders(operation), envelope);
        if (r.Status < 200 || r.Status >= 300) {
            return { Success: false, ExternalID: '', StatusCode: r.Status, ErrorMessage: `Create of "${ctx.ObjectName}" failed: HTTP ${r.Status}${this.SoapFault(r.Body)}` };
        }
        const externalID = this.ExtractKeyFromResponse(r.Body);
        return this.BuildCreatedResult(externalID, r.Status, ctx.ObjectName);
    }

    /**
     * Update via the SOAP operation named in UpdateBodyKey / Configuration.writeOps.updateOp.
     * netFORUM exposes no ETag / If-Match — updates are last-write-wins.
     */
    public override async UpdateRecord(ctx: UpdateRecordContext): Promise<CRUDResult> {
        const ci = ctx.CompanyIntegration as MJCompanyIntegrationEntity;
        const obj = this.GetCachedObject(ci.IntegrationID, ctx.ObjectName);
        if (!obj.SupportsUpdate) {
            return { Success: false, ExternalID: ctx.ExternalID, StatusCode: 0, ErrorMessage: `UpdateRecord not supported for "${ctx.ObjectName}".` };
        }
        const cfg = this.ParseObjectConfig(obj);
        const operation = obj.UpdateBodyKey ?? cfg.writeOps?.updateOp;
        if (!operation) {
            return { Success: false, ExternalID: ctx.ExternalID, StatusCode: 0, ErrorMessage: `Update of "${ctx.ObjectName}" has no SOAP operation configured (UpdateBodyKey).` };
        }
        const auth = await this.Authenticate(ci, ctx.ContextUser as UserInfo) as NFAuthContext;
        const url = `${auth.Config.BaseURL}${this.SoapEndpoint(cfg)}`;
        const pkField = this.PrimaryKeyFieldName(obj);
        const attributes: Record<string, unknown> = pkField
            ? { [pkField]: ctx.ExternalID, ...ctx.Attributes }
            : { ...ctx.Attributes };
        const envelope = this.BuildSoapEnvelope(operation, attributes, auth.Token);
        const r = await this.MakeRawHTTPRequest(url, 'POST', this.SoapHeaders(operation), envelope);
        if (r.Status >= 200 && r.Status < 300) {
            return { Success: true, ExternalID: ctx.ExternalID, StatusCode: r.Status };
        }
        return { Success: false, ExternalID: ctx.ExternalID, StatusCode: r.Status, ErrorMessage: `Update of "${ctx.ObjectName}" failed: HTTP ${r.Status}${this.SoapFault(r.Body)}` };
    }

    /**
     * Delete is not supported. DeleteFacadeObject is not confirmed in any reachable vendor doc and
     * netFORUM prefers soft-delete via status flags. SupportsDelete is false, so this returns a clean
     * error rather than silently claiming success.
     */
    public override async DeleteRecord(ctx: DeleteRecordContext): Promise<CRUDResult> {
        return {
            Success: false,
            ExternalID: ctx.ExternalID,
            StatusCode: 0,
            ErrorMessage: 'NetForum connector does not support delete (DeleteFacadeObject unconfirmed; netFORUM uses soft-delete via status flags).',
        };
    }

    private ExtractKeyFromResponse(body: unknown): string | undefined {
        const xml = this.AsText(body);
        // The Insert/Create ops return the new GUID — scan common result/key element names.
        for (const tag of ['key', 'Key', 'AddResult', 'InsertResult', 'CreateResult', 'WEBIndividualInsertResult', 'cst_key']) {
            const v = this.ParseSoapScalar(xml, tag);
            if (v && v.trim().length > 0) return v.trim();
        }
        // Fallback: first GUID-shaped token anywhere in the body.
        const guid = xml.match(/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/);
        return guid ? guid[0] : undefined;
    }

    // ─── Stable ordering key (no-watermark resume) ───────────────────

    /**
     * Returns the IO's stable, monotonic ordering column (the PK / Configuration.stableOrderingKey)
     * so the engine can keyset-resume objects that have no incremental watermark. Null when the IO is
     * unknown or has no stable key — keyset resume is simply unavailable then, not an error.
     */
    public override StableOrderingKey(objectName: string): string | null {
        const ci = this.LastIntegrationID;
        if (!ci) return null;
        try {
            const obj = this.GetCachedObject(ci, objectName);
            const cfg = this.ParseObjectConfig(obj);
            return cfg.stableOrderingKey ?? this.PrimaryKeyFieldName(obj) ?? null;
        } catch {
            return null;
        }
    }

    // ─── SOAP envelope + XML helpers ─────────────────────────────────

    /** Required SOAP 1.1 HTTP headers for a given operation. */
    private SoapHeaders(operation: string): Record<string, string> {
        return {
            'Content-Type': 'text/xml; charset=utf-8',
            'SOAPAction': `${SOAP_NS}${operation}`,
            'User-Agent': 'MemberJunction-Integration/1.0',
        };
    }

    /**
     * Builds a SOAP 1.1 envelope for `operation` with the given body args. When a token is provided
     * (every call except Authenticate), the AuthorizationToken header element carries it — this is
     * the documented SOAP token carrier, NOT an HTTP Authorization header. Values are XML-escaped.
     */
    private BuildSoapEnvelope(operation: string, args: Record<string, unknown>, token?: string): string {
        const header = token
            ? `<soap:Header><AuthorizationToken xmlns="${SOAP_NS}"><Token>${this.EscapeXml(token)}</Token></AuthorizationToken></soap:Header>`
            : '<soap:Header/>';
        const argXml = Object.entries(args)
            .map(([k, v]) => this.ArgElement(k, v))
            .join('');
        return `<?xml version="1.0" encoding="utf-8"?>` +
            `<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">` +
            header +
            `<soap:Body><${operation} xmlns="${SOAP_NS}">${argXml}</${operation}></soap:Body>` +
            `</soap:Envelope>`;
    }

    /** Serializes one SOAP arg. Objects become nested elements; scalars become escaped text. */
    private ArgElement(name: string, value: unknown): string {
        if (value === null || value === undefined) return `<${name} />`;
        if (typeof value === 'object') {
            const inner = Object.entries(value as Record<string, unknown>)
                .map(([k, v]) => this.ArgElement(k, v))
                .join('');
            return `<${name}>${inner}</${name}>`;
        }
        return `<${name}>${this.EscapeXml(String(value))}</${name}>`;
    }

    private EscapeXml(s: string): string {
        return s
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&apos;');
    }

    private UnescapeXml(s: string): string {
        return s
            .replace(/&lt;/g, '<')
            .replace(/&gt;/g, '>')
            .replace(/&quot;/g, '"')
            .replace(/&apos;/g, "'")
            .replace(/&#(\d+);/g, (_m, d: string) => String.fromCharCode(Number(d)))
            .replace(/&amp;/g, '&');
    }

    /**
     * Extracts the text content of the FIRST occurrence of a scalar element by local name, ignoring
     * namespace prefixes. Returns undefined when absent. Used for AuthenticateResult, mdc_* columns,
     * and create-result keys.
     */
    /**
     * The session token from an Authenticate RESPONSE: the <Token> inside the <AuthorizationToken>
     * header element (any namespace prefix, attributes such as soap:actor tolerated). Never the body's
     * AuthenticateResult — see Authenticate(). Returns undefined when the header is absent.
     */
    private ParseAuthenticateToken(xml: string): string | undefined {
        const hdr = /<(?:[\w.-]+:)?AuthorizationToken\b[^>]*>([\s\S]*?)<\/(?:[\w.-]+:)?AuthorizationToken>/i.exec(xml);
        if (!hdr) return undefined;
        const token = this.ParseSoapScalar(hdr[1], 'Token');
        return token && token.length > 0 ? token : undefined;
    }

    private ParseSoapScalar(xml: string, localName: string): string | undefined {
        const re = new RegExp(`<(?:[\\w.-]+:)?${this.EscapeRegExp(localName)}\\b[^>]*>([\\s\\S]*?)</(?:[\\w.-]+:)?${this.EscapeRegExp(localName)}>`);
        const m = re.exec(xml);
        if (!m) return undefined;
        return this.UnescapeXml(m[1]).trim();
    }

    /** Returns the inner XML of every occurrence of an element by local name (namespace-agnostic). */
    private ExtractElements(xml: string, localName: string): string[] {
        const re = new RegExp(`<(?:[\\w.-]+:)?${this.EscapeRegExp(localName)}\\b[^>]*>([\\s\\S]*?)</(?:[\\w.-]+:)?${this.EscapeRegExp(localName)}>`, 'g');
        const out: string[] = [];
        let m: RegExpExecArray | null;
        while ((m = re.exec(xml)) !== null) out.push(m[1]);
        return out;
    }

    private EscapeRegExp(s: string): string { return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); }

    /**
     * Strips the SOAP envelope and the GetQueryResult wrapper, returning each flattened row as a
     * plain object of column→value. netFORUM GetQuery returns a DataSet of repeated row elements
     * (the row element name is the query's "Result"/"<Object>" element). We locate the GetQueryResult
     * payload, then treat every direct child element that itself contains child elements as a row.
     */
    protected NormalizeResponse(rawBody: unknown, _key: string | null): Record<string, unknown>[] {
        const xml = this.AsText(rawBody);
        if (!xml) return [];
        // Unwrap the GetQueryResult body (the <s:any> DataSet). Fall back to the whole body.
        const resultElems = this.ExtractElements(xml, 'GetQueryResult');
        const payload = resultElems.length > 0 ? resultElems[0] : xml;
        return this.ParseRowSet(payload);
    }

    /**
     * Parses a flattened row set. The DataSet shape is `<Results><Result>...cols...</Result>...` (the
     * outer/inner names vary by query, e.g. IndividualObjects/IndividualObject). We find the most
     * common repeated leaf-bearing element name and treat each as a row of column elements.
     */
    private ParseRowSet(xml: string): Record<string, unknown>[] {
        // Identify candidate row element names: any tag that recurs AND contains nested elements.
        const topTags = this.TopLevelTagNames(xml);
        // The row wrapper is usually a single outer element (e.g. <Results>); descend one level if so.
        let scope = xml;
        if (topTags.length === 1) {
            const inner = this.ExtractElements(xml, topTags[0]);
            if (inner.length === 1 && /</.test(inner[0])) scope = inner[0];
        }
        const rowTagCounts = new Map<string, number>();
        for (const tag of this.TopLevelTagNames(scope)) {
            rowTagCounts.set(tag, (rowTagCounts.get(tag) ?? 0) + 1);
        }
        // Pick the most frequent row tag (ties → first). A single-row result still has count 1.
        let rowTag: string | undefined;
        let best = 0;
        for (const [tag, count] of rowTagCounts) {
            if (count > best) { best = count; rowTag = tag; }
        }
        if (!rowTag) return [];
        const rows: Record<string, unknown>[] = [];
        for (const rowXml of this.ExtractElements(scope, rowTag)) {
            const row = this.ParseRowColumns(rowXml);
            if (Object.keys(row).length > 0) rows.push(row);
        }
        return rows;
    }

    /** Parses one row's column elements into a flat object (full-record — every column kept). */
    private ParseRowColumns(rowXml: string): Record<string, unknown> {
        const row: Record<string, unknown> = {};
        const re = /<([\w.-]+)\b[^>]*?(\/)?>(?:([\s\S]*?)<\/\1>)?/g;
        let m: RegExpExecArray | null;
        while ((m = re.exec(rowXml)) !== null) {
            const tag = m[1];
            const selfClosing = m[2] === '/';
            const content = m[3];
            if (selfClosing || content === undefined) { row[tag] = null; continue; }
            // Flattened GetQuery rows carry scalar columns; keep the unescaped text value.
            row[tag] = this.UnescapeXml(content);
        }
        return row;
    }

    /**
     * Returns the local names of the direct (top-level) child elements of an XML fragment, by a
     * depth scan over open/close/self-close tags (so a tag opened at depth 0 is a direct child).
     */
    private TopLevelTagNames(xml: string): string[] {
        const names: string[] = [];
        let depth = 0;
        const tokenRe = /<\/?([\w.-]+)\b[^>]*?(\/)?>/g;
        let t: RegExpExecArray | null;
        while ((t = tokenRe.exec(xml)) !== null) {
            const full = t[0];
            const name = t[1];
            const selfClose = t[2] === '/';
            const isClose = full.startsWith('</');
            if (isClose) { depth--; continue; }
            if (depth === 0) names.push(name);
            if (!selfClose) depth++;
        }
        return names;
    }

    protected ExtractPaginationInfo(
        _rb: unknown,
        _pt: PaginationType,
        _cp: number,
        _co: number,
        _ps: number,
    ): PaginationState {
        // GetQuery returns the full result set in one call — no protocol-level pagination.
        return { HasMore: false };
    }

    protected GetBaseURL(_ci: MJCompanyIntegrationEntity, auth: RESTAuthContext): string {
        return (auth as NFAuthContext).Config.BaseURL;
    }

    /** The base-class abstract BuildHeaders — defers to SoapHeaders for the active operation. */
    protected BuildHeaders(_auth: RESTAuthContext): Record<string, string> {
        return { 'Content-Type': 'text/xml; charset=utf-8', 'User-Agent': 'MemberJunction-Integration/1.0' };
    }

    /** The base-class abstract MakeHTTPRequest — routes through the raw transport. */
    protected async MakeHTTPRequest(
        _auth: RESTAuthContext,
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: unknown,
    ): Promise<RESTResponse> {
        return this.MakeRawHTTPRequest(url, method, headers, typeof body === 'string' ? body : (body == null ? undefined : String(body)));
    }

    /**
     * Raw SOAP transport: POSTs the XML envelope, retries on 401 (re-auth)/429/5xx, and returns the
     * response body as text (SOAP is text/xml). Never logs credentials, the token, or PII.
     *
     * `protected` so a unit-test subclass can override this single transport seam to feed canned
     * SOAP responses (no live network, no credentials) — the only seam tests need to mock.
     */
    protected async MakeRawHTTPRequest(
        url: string,
        method: string,
        headers: Record<string, string>,
        body?: string,
    ): Promise<RESTResponse> {
        await this.Throttle();
        for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
            const controller = new AbortController();
            const timer = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
            try {
                const opts: RequestInit = { method, headers, signal: controller.signal };
                if (body !== undefined && method !== 'GET') opts.body = body;
                const response = await fetch(url, opts);
                clearTimeout(timer);
                this.lastRequestTime = Date.now();
                if (response.status === 401 && attempt === 0) { this.tokenCache = null; continue; }
                if (response.status === 429 && attempt < MAX_RETRIES) {
                    await this.Sleep(this.RetryAfterMs(response, attempt));
                    continue;
                }
                if (response.status >= 500 && attempt < MAX_RETRIES) {
                    await this.Sleep(Math.min(1000 * Math.pow(2, attempt), 30_000));
                    continue;
                }
                const text = await response.text();
                const h: Record<string, string> = {};
                response.headers.forEach((v, k) => { h[k.toLowerCase()] = v; });
                return { Status: response.status, Body: text, Headers: h };
            } catch (e) {
                clearTimeout(timer);
                if (e instanceof Error && e.name === 'AbortError') throw new Error(`NetForum request timed out: ${url}`);
                if (attempt >= MAX_RETRIES) throw e;
                await this.Sleep(Math.min(1000 * Math.pow(2, attempt), 30_000));
            }
        }
        throw new Error(`NetForum request failed after ${MAX_RETRIES} retries: ${url}`);
    }

    private RetryAfterMs(response: Response, attempt: number): number {
        const ra = response.headers.get('retry-after');
        if (ra) {
            const secs = Number(ra);
            if (!Number.isNaN(secs)) return Math.min(secs * 1000, 60_000);
        }
        return Math.min(1000 * Math.pow(2, attempt) + Math.random() * 500, 60_000);
    }

    public override ExtractRetryAfterMs(error: unknown): number | undefined {
        if (error && typeof error === 'object' && 'Headers' in error) {
            const headers = (error as { Headers?: Record<string, string> }).Headers;
            const ra = headers?.['retry-after'];
            if (ra) { const secs = Number(ra); if (!Number.isNaN(secs)) return secs * 1000; }
        }
        return undefined;
    }

    private async Throttle(): Promise<void> {
        const elapsed = Date.now() - this.lastRequestTime;
        if (elapsed < MIN_REQUEST_INTERVAL_MS) await this.Sleep(MIN_REQUEST_INTERVAL_MS - elapsed);
    }
    protected Sleep(ms: number): Promise<void> { return new Promise(r => setTimeout(r, ms)); }

    // ─── Per-object config helpers ───────────────────────────────────

    /** Remembered integration ID from the last fetch, so StableOrderingKey can read the cache. */
    private LastIntegrationID: string | null = null;

    private ParseObjectConfig(obj: MJIntegrationObjectEntity): NFObjectConfig {
        this.LastIntegrationID = obj.IntegrationID ?? this.LastIntegrationID;
        if (!obj.Configuration) return {};
        try {
            return JSON.parse(obj.Configuration) as NFObjectConfig;
        } catch {
            return {};
        }
    }

    private SoapEndpoint(cfg: NFObjectConfig): string {
        return cfg.soapEndpoint ?? DEFAULT_SOAP_PATH;
    }

    private PrimaryKeyFieldName(obj: MJIntegrationObjectEntity): string | undefined {
        const fields = this.GetCachedFields(obj.ID);
        const pk = fields.find(f => f.IsPrimaryKey);
        return pk?.Name;
    }

    /** Lowercased names of the IO's declared primary-key fields, read from the cached IOF entities. */
    private DeclaredPrimaryKeyNames(ci: MJCompanyIntegrationEntity, objectName: string): Set<string> {
        try {
            const obj = this.GetCachedObject(ci.IntegrationID, objectName);
            return new Set(this.GetCachedFields(obj.ID).filter(f => f.IsPrimaryKey).map(f => f.Name.toLowerCase()));
        } catch {
            return new Set<string>();
        }
    }

    /**
     * The `<faultstring>` from a SOAP fault, formatted for appending to an error message.
     *
     * netFORUM says precisely what is wrong and who can fix it — "Account is not authorized to
     * perform Select on Audience object." — and reporting only "HTTP 500" throws that away, turning
     * a one-line permissions answer into a guessing game. Proven live 2026-09-15: ten objects failed
     * discovery for this exact reason and the run reported only the status code.
     *
     * Returns '' when there is no faultstring, so callers can append unconditionally.
     */
    private SoapFault(body: unknown): string {
        const fault = this.ParseSoapScalar(this.AsText(body), 'faultstring');
        return fault ? ` — ${fault}` : '';
    }

    private AsText(body: unknown): string {
        if (typeof body === 'string') return body;
        if (body == null) return '';
        return String(body);
    }
}

export function LoadNetForumConnector() { /* intentionally empty — tree-shaking anchor */ }

/**
 * Minimal bounded promise-pool: runs `worker` over `items` with at most `limit` in flight.
 * (BaseRESTIntegrationConnector.RunBounded is private, so the sample-union override brings its own
 * tiny pool — this is local plumbing, NOT a shared framework artifact.)
 */
async function runBounded<T>(items: T[], limit: number, worker: (item: T) => Promise<void>): Promise<void> {
    const queue = [...items];
    const size = Math.max(1, Math.min(limit, queue.length));
    const runners = Array.from({ length: size }, async () => {
        for (let next = queue.shift(); next !== undefined; next = queue.shift()) {
            await worker(next);
        }
    });
    await Promise.all(runners);
}
