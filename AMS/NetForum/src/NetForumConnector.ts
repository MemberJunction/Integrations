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
        try {
            const auth = await this.Authenticate(ci, cu) as NFAuthContext;
            const url = `${auth.Config.BaseURL}${DEFAULT_SOAP_PATH}`;
            const body = this.BuildSoapEnvelope('GetFacadeObjectList', {}, auth.Token);
            const r = await this.MakeRawHTTPRequest(url, 'POST', this.SoapHeaders('GetFacadeObjectList'), body);
            if (r.Status >= 200 && r.Status < 300) {
                return this.MergeEnumeratedObjects(declared, this.ParseFacadeObjectList(this.AsText(r.Body)));
            }
        } catch {
            // Credential-free, network failure, parse failure, or the account not granted
            // GetFacadeObjectList → the Declared baseline stands alone, exactly as before.
        }
        return declared;
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
        const declared = await super.DiscoverFields(ci, objectName, cu);
        // The base FieldEntityToSchema folds PK into IsUniqueKey and never sets IsPrimaryKey, so
        // re-derive the honest IsPrimaryKey from the cached IOF entities (which carry it explicitly).
        const pkNames = this.DeclaredPrimaryKeyNames(ci, objectName);
        const declaredByName = new Map(
            declared.map(f => [f.Name.toLowerCase(), { ...f, IsPrimaryKey: pkNames.has(f.Name.toLowerCase()) }]),
        );
        try {
            const auth = await this.Authenticate(ci, cu) as NFAuthContext;
            const url = `${auth.Config.BaseURL}${DEFAULT_SOAP_PATH}`;
            const body = this.BuildSoapEnvelope('GetQueryDefinition', { szObjectName: objectName }, auth.Token);
            const r = await this.MakeRawHTTPRequest(url, 'POST', this.SoapHeaders('GetQueryDefinition'), body);
            if (r.Status >= 200 && r.Status < 300) {
                const discovered = this.ParseQueryDefinition(this.AsText(r.Body), declaredByName);
                if (discovered.length > 0) return discovered;
            }
        } catch {
            // credential-free / network / parse failure → fall through to Declared
        }
        return declared;
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
     * Parses a GetQueryDefinition response (the SQL column definition) into ExternalFieldSchema[].
     * Each `<Column>` carries mdc_name / mdc_description / mdc_data_type / mdc_nullable /
     * mdc_width_max. Declared metadata wins for PK identity (a column definition does not mark a PK);
     * discovery contributes the full column corpus + provable nullability/length.
     */
    private ParseQueryDefinition(
        xml: string,
        declaredByName: Map<string, ExternalFieldSchema>,
    ): ExternalFieldSchema[] {
        const out: ExternalFieldSchema[] = [];
        const seen = new Set<string>();
        for (const colXml of this.ExtractElements(xml, 'Column')) {
            const name = this.ParseSoapScalar(colXml, 'mdc_name');
            if (!name || seen.has(name.toLowerCase())) continue;
            seen.add(name.toLowerCase());
            const declared = declaredByName.get(name.toLowerCase());
            const dataType = this.ParseSoapScalar(colXml, 'mdc_data_type');
            const description = this.ParseSoapScalar(colXml, 'mdc_description');
            const nullable = this.ParseSoapScalar(colXml, 'mdc_nullable');
            const widthRaw = this.ParseSoapScalar(colXml, 'mdc_width_max');
            const maxLength = widthRaw && /^\d+$/.test(widthRaw) ? Number(widthRaw) : null;
            // AllowsNull provable-only: 'mdc_nullable' is an explicit source flag. "0"/"false"/"no" ⇒ NOT NULL.
            const allowsNull = nullable == null
                ? undefined
                : !/^(0|false|no|n)$/i.test(nullable.trim());
            out.push({
                Name: name,
                Label: declared?.Label ?? name,
                Description: declared?.Description ?? (description || undefined),
                DataType: declared?.DataType ?? this.MapSoapType(dataType ?? null),
                IsRequired: declared?.IsRequired ?? false,
                AllowsNull: allowsNull,
                IsPrimaryKey: declared?.IsPrimaryKey ?? false,
                IsUniqueKey: declared?.IsUniqueKey ?? false,
                IsReadOnly: declared?.IsReadOnly ?? false,
                IsForeignKey: declared?.IsForeignKey ?? false,
                ForeignKeyTarget: declared?.ForeignKeyTarget ?? null,
                MaxLength: maxLength,
            });
        }
        // Re-add any Declared field GetQueryDefinition did not surface (provable-only baseline never lost).
        for (const [key, f] of declaredByName) {
            if (!seen.has(key)) out.push(f);
        }
        return out;
    }

    private MapSoapType(sqlType: string | null): string {
        if (!sqlType) return 'string';
        const t = sqlType.toLowerCase();
        if (/(date|time)/.test(t)) return 'datetime';
        if (/(int|bigint|smallint|tinyint)/.test(t)) return 'number';
        if (/(decimal|numeric|money|float|real)/.test(t)) return 'decimal';
        if (/bit/.test(t)) return 'boolean';
        if (/uniqueidentifier/.test(t)) return 'string';
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
        const auth = await this.Authenticate(ctx.CompanyIntegration, ctx.ContextUser) as NFAuthContext;
        const obj = this.GetCachedObject(ctx.CompanyIntegration.IntegrationID, ctx.ObjectName);
        const cfg = this.ParseObjectConfig(obj);
        const accessPath = cfg.accessPath ?? {};

        const queryObject = accessPath.queryObject ?? accessPath.doorArgs?.szObjectName ?? ctx.ObjectName;
        const orderingKey = cfg.stableOrderingKey ?? this.PrimaryKeyFieldName(obj);

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
        const topModifier = canPaginate && pageSize > 0
            ? `@TOP ${pageSize}`
            : (accessPath.doorArgs?.topModifier ?? '@TOP -1');
        const szObjectName = topModifier ? `${queryObject} ${topModifier}` : queryObject;

        const watermarkField = obj.IncrementalWatermarkField ?? undefined;
        const pkField = this.PrimaryKeyFieldName(obj);
        // Empty by default (the tenant's default list columns), never `*` — see the class header. An IO
        // may declare Configuration.columnList when its default list lacks a column the connector needs;
        // the door returns ONLY named columns, so a declared list is completed with the PK, the ordering
        // key and the watermark — the three columns this method itself reads.
        const args: Record<string, string> = {
            szObjectName,
            szColumnList: this.ColumnListFor(cfg, [pkField, orderingKey, watermarkField]),
        };

        const predicates: string[] = [];
        if (ctx.WatermarkValue && watermarkField) {
            predicates.push(`${watermarkField} >= '${this.EscapeSqlLiteral(ctx.WatermarkValue)}'`);
        }
        if (canPaginate && ctx.AfterKeyValue) {
            predicates.push(`${orderingKey} > '${this.EscapeSqlLiteral(ctx.AfterKeyValue)}'`);
        }
        if (predicates.length > 0) args.szWhereClause = predicates.join(' AND ');

        if (orderingKey) args.szOrderBy = orderingKey;

        const url = `${auth.Config.BaseURL}${this.SoapEndpoint(cfg)}`;

        // Once this connection is known to have an unusable default list, lead with the explicit list
        // rather than paying another fault to re-discover what we already know (see the field's doc).
        //
        // Deliberately narrow. This only REORDERS two requests that were going to be sent in sequence
        // anyway, and only when an explicit list actually exists; with nothing better to send it falls
        // through to the original empty request unchanged. So a tenant whose defaults are fine never
        // reaches it, and — because netFORUM configures the default list PER OBJECT — an object whose
        // own default is fine on a tenant where others are not still gets its normal request.
        const faultKey = ctx.CompanyIntegration?.ID ?? '';
        if (!args.szColumnList && this.DefaultColumnListUnusable.has(faultKey)) {
            const known = this.ExplicitColumnListFor(obj, [pkField, orderingKey, watermarkField]);
            if (known) args.szColumnList = known;
        }
        const sentEmptyColumnList = !args.szColumnList;

        let response = await this.MakeRawHTTPRequest(
            url, 'POST', this.SoapHeaders('GetQuery'), this.BuildSoapEnvelope('GetQuery', args, auth.Token),
        );

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
            const explicit = this.ExplicitColumnListFor(obj, [pkField, orderingKey, watermarkField]);
            if (explicit) {
                response = await this.MakeRawHTTPRequest(
                    url, 'POST', this.SoapHeaders('GetQuery'),
                    this.BuildSoapEnvelope('GetQuery', { ...args, szColumnList: explicit }, auth.Token),
                );
            }
        }

        if (response.Status < 200 || response.Status >= 300) {
            throw new Error(`NetForum GetQuery(${ctx.ObjectName}) failed: HTTP ${response.Status}${this.SoapFault(response.Body)}`);
        }

        const rows = this.NormalizeResponse(response.Body, null);
        const warnings: FetchWarning[] = [];
        if (rows.length === 0) {
            warnings.push({ Code: 'ZERO_ROWS', Message: `GetQuery(${szObjectName}) returned no rows.` });
        }
        if (!canPaginate) {
            warnings.push({
                Code: 'UNPAGINATED_FETCH',
                Message:
                    `NetForum "${ctx.ObjectName}" has no stable ordering key (Configuration.stableOrderingKey ` +
                    `or a primary-key field), so GetQuery ran unbounded (${topModifier}) and returned the ` +
                    `entire result set in one call. Declare an ordering key to enable keyset paging.`,
                Data: { ObjectName: ctx.ObjectName, RowCount: rows.length },
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
        let maxKey: string | undefined;
        const records: ExternalRecord[] = rows.map(row => {
            const externalID = pkField ? String(row[pkField] ?? '') : '';
            if (orderingKey) {
                const v = row[orderingKey];
                if (v != null) { const s = String(v); if (maxKey === undefined || s > maxKey) maxKey = s; }
            }
            return { ExternalID: externalID, ObjectType: ctx.ObjectName, Fields: row };
        });

        // A full page implies another may exist; a short page is the last one. Only meaningful when
        // paginating — without an ordering key there is no seek position, so the single unbounded
        // fetch is by definition complete.
        const hasMore = canPaginate && pageSize > 0 && rows.length >= pageSize && maxKey !== undefined;

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
    private ExplicitColumnListFor(obj: MJIntegrationObjectEntity, required: Array<string | undefined>): string {
        const discovered = this.DiscoveredColumnsByObject.get(obj.Name.toLowerCase()) ?? [];
        const known = discovered.length > 0
            ? discovered
            : this.GetCachedFields(obj.ID).map(f => f.Name).filter((n): n is string => !!n);
        if (known.length === 0) return '';
        const out: string[] = [];
        const seen = new Set<string>();
        for (const c of [...known, ...required]) {
            if (!c) continue;
            const key = c.toLowerCase();
            if (seen.has(key)) continue;
            seen.add(key);
            out.push(c);
        }
        return out.join(',');
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
    private Sleep(ms: number): Promise<void> { return new Promise(r => setTimeout(r, ms)); }

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
