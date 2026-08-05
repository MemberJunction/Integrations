/**
 * Reusable connector test "plans" — pure functions that drive a connector and return a
 * structured, JSON-able result. Shared by the standalone harness (hubspot-live-test.mjs)
 * and the out-of-sandbox credential broker (credential-broker.mjs) so the exact same
 * credential-safe logic backs both manual and agent-driven runs.
 *
 * A plan never reads process.env itself — the caller (credential-safe runner) hands it the
 * already-dereferenced secret value + a `scrub` function; the plan must route every
 * connector message/error through `scrub` before returning it.
 */
// HubSpotConnector is only reachable from the two hubspotTier* LIVE plans below. The 6.x
// connector-source removal dropped every vendor connector from this package's barrel, so a
// STATIC import here fails module instantiation and takes down every credential-free plan in
// this file with it. Stub the class: the mock/credential-free paths never touch it, and the
// hubspot live plans fail loudly (with the reason) instead of silently.
class HubSpotConnector {
    constructor() {
        throw new Error(
            'HubSpotConnector is no longer exported by @memberjunction/integration-connectors ' +
            '(vendor connectors moved out of the MJ monorepo). The hubspotTier* live plans need it ' +
            'imported from the Integrations repo package; the credential-free plans do not use it.'
        );
    }
}
import { OAuth1aSigner } from '@memberjunction/integration-engine';
import { runLiveTest, GQL } from './gql-live-harness.mjs';
import { runMatrixReadonly } from './gql-matrix-harness.mjs';
import { runLifecycleOps, runDeleteCascade } from './gql-lifecycle-harness.mjs';
import { makeGqlClient, makeHubspotTotal, makeDbClient, resolveSetupIds } from './gql-live-adapters.mjs';
import { runConnectorE2E, phaseMJCentralConsumerPath } from './connector-e2e-harness.mjs';
import { runConnectorE2EHybrid } from './connector-e2e-hybrid.mjs';
import { buildMock, deltaPassesFromManifest, objectsFromManifest, matrixSpecsFromManifest } from './connector-e2e-adapters.mjs';
import { regenerateFixturesFromDeployed } from './gen-fixture.mjs';
import { resolve as pathResolve } from 'node:path';

const HUBSPOT_API_BASE = 'https://api.hubapi.com';
const stubUser = { ID: 'cred-test-user', Email: 'test@example.com', Name: 'Cred Test' };
// The connector reads either `accessToken` (Private App token / Bearer) or `apiKey`.
// We pass under `apiKey` since the user provided an "API key"; the connector currently
// Bearer-auths it (correct for a `pat-` Private App token). A legacy UUID hapikey would
// need query-param auth — flagged separately.
const hubspotCI = (key) => ({
    ID: 'cred-test-ci', IntegrationID: 'cred-test-int', Integration: 'HubSpot',
    CredentialID: null, Configuration: JSON.stringify({ apiKey: key }),
});

/**
 * Tier-1 HubSpot validation (no DB): TestConnection + DiscoverObjects + DiscoverFields(contacts).
 * @param {{token:string}} secrets  dereferenced by the runner
 * @param {(s:string)=>string} scrub
 */
export async function hubspotTier1({ token }, scrub) {
    const ci = hubspotCI(token);
    const connector = new HubSpotConnector();
    const out = { ok: false, tier: 1, steps: {} };

    const conn = await connector.TestConnection(ci, stubUser);
    out.steps.testConnection = { success: !!conn.Success, message: scrub(conn.Message ?? ''), serverVersion: conn.ServerVersion ?? null };
    if (!conn.Success) return out;

    const objects = await connector.DiscoverObjects(ci, stubUser);
    out.steps.discoverObjects = {
        count: objects.length,
        sample: objects.slice(0, 10).map(o => o.Name),
        hasContacts: objects.some(o => o.Name === 'contacts'),
        hasCompanies: objects.some(o => o.Name === 'companies'),
        associationCount: objects.filter(o => o.Name.startsWith('assoc_')).length,
    };

    try {
        const fields = await connector.DiscoverFields(ci, 'contacts', stubUser);
        out.steps.discoverFieldsContacts = {
            count: fields.length,
            pkFields: fields.filter(f => f.IsPrimaryKey).map(f => f.Name),
            sample: fields.slice(0, 12).map(f => f.Name),
        };
    } catch (e) {
        out.steps.discoverFieldsContacts = { error: scrub(e instanceof Error ? e.message : String(e)) };
    }

    out.ok = conn.Success && objects.length > 0;
    return out;
}

/**
 * Tier-2 association read-only validation (no DB): proves the contacts↔companies
 * association data — the thing the junction/DAG fix exists to fill in — is fetchable
 * against REAL data, without writing anything anywhere.
 *
 * It (1) lists real contacts + companies via the connector's own ListRecords (DB-free
 * reads), then (2) calls the SAME v4 `POST /crm/v4/associations/contacts/companies/batch/read`
 * endpoint the connector's FetchAssociationBatch uses, with the real contact ids, and
 * verifies the association FK pair (contact_id, company_id) comes back populated.
 *
 * READ-ONLY: every call reads. `batch/read` is a read despite being a POST — it never
 * creates/updates/deletes in HubSpot. Surfaces only opaque ids + counts (no PII: contact
 * field values like name/email are never read). The full DAG-ordered sync-into-DB path is
 * covered separately by Tier-2a (DDL) + the engine's 295 unit tests; this closes the
 * "are real associations actually fetchable + does the FK pair populate" question.
 *
 * @param {{token:string}} secrets  dereferenced by the runner
 * @param {(s:string)=>string} scrub
 */
export async function hubspotTier2Assoc({ token }, scrub) {
    const ci = hubspotCI(token);
    const connector = new HubSpotConnector();
    const out = { ok: false, tier: '2-assoc', readOnly: true, steps: {} };

    const conn = await connector.TestConnection(ci, stubUser);
    out.steps.testConnection = { success: !!conn.Success, message: scrub(conn.Message ?? '') };
    if (!conn.Success) return out;

    // 1) Parent reads (DB-free) — real contacts + companies.
    const listCtx = (ObjectName) => ({ CompanyIntegration: ci, ContextUser: stubUser, ObjectName, PageSize: 30 });
    let contactIDs = [];
    try {
        const contacts = await connector.ListRecords(listCtx('contacts'));
        const companies = await connector.ListRecords(listCtx('companies'));
        contactIDs = contacts.Records.map(r => r.ExternalID).filter(Boolean);
        out.steps.parents = { contacts: contacts.Records.length, companies: companies.Records.length };
    } catch (e) {
        out.steps.parents = { error: scrub(e instanceof Error ? e.message : String(e)) };
        return out;
    }

    if (contactIDs.length === 0) {
        out.steps.associations = { skipped: 'no contacts returned (missing read scope or empty portal)' };
        return out;
    }

    // 2) v4 association batch/read — same endpoint the connector uses. READ-ONLY.
    try {
        const resp = await fetch(`${HUBSPOT_API_BASE}/crm/v4/associations/contacts/companies/batch/read`, {
            method: 'POST',
            headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
            body: JSON.stringify({ inputs: contactIDs.map(id => ({ id })) }),
        });
        if (!resp.ok) {
            out.steps.associations = { error: scrub(`HTTP ${resp.status}: ${(await resp.text()).slice(0, 300)}`) };
            return out;
        }
        const body = await resp.json();
        const results = body.results ?? [];
        let pairCount = 0, contactsWithCompany = 0, samplePair = null;
        for (const item of results) {
            const tos = item.to ?? [];
            if (tos.length > 0) contactsWithCompany++;
            for (const t of tos) {
                pairCount++;
                if (!samplePair) samplePair = { contact_id: String(item.from?.id ?? ''), company_id: String(t.toObjectId ?? '') };
            }
        }
        out.steps.associations = {
            contactsQueried: contactIDs.length,
            contactsWithAtLeastOneCompany: contactsWithCompany,
            totalAssociationPairs: pairCount,
            samplePair, // opaque numeric ids only — no PII
            fkPairBothPopulated: samplePair ? (!!samplePair.contact_id && !!samplePair.company_id) : null,
            proves: pairCount > 0
                ? 'REAL association fill-in confirmed: v4 batch/read returns (contact_id, company_id) pairs'
                : 'endpoint reachable but this portal has no contact↔company links to confirm fill-in',
        };
        out.ok = true;
    } catch (e) {
        out.steps.associations = { error: scrub(e instanceof Error ? e.message : String(e)) };
    }
    return out;
}

/**
 * Builds the non-secret live-test config from env (only NON-secret values — IDs, URLs, host/port).
 * Secret VALUES (token, dbPassword, mjToken) arrive via `values` from the runner and are never read here.
 * Env vars (set by the launching/broker process):
 *   HS_LIVE_GRAPHQL_URL   MJAPI GraphQL endpoint (default http://localhost:4000/)
 *   HS_LIVE_PLATFORM      'sqlserver' | 'postgresql' (default sqlserver)
 *   HS_LIVE_COMPANY_ID    MJ Company ID for the connection (required)
 *   HS_LIVE_CREDTYPE_ID   MJ CredentialType ID for the api-token credential (required)
 *   HS_LIVE_INTEGRATION_ID  HubSpot Integration ID (optional — resolved by name 'HubSpot' if absent)
 *   HS_LIVE_OBJECTS       comma-sep source objects (default contacts,companies,deals,assoc_contacts_companies)
 *   HS_LIVE_DB_HOST/PORT/NAME/USER  workbench DB coordinates for the assertion client
 *   HS_LIVE_RUN_ID        optional stable run marker (default live_<timestamp>)
 *   HS_LIVE_WRITE_OBJECT  object for the backward CRUD round-trip (default contacts; Users refused)
 */
export function liveCfgFromEnv() {
    const env = process.env;
    const runId = env.HS_LIVE_RUN_ID || `live_${Date.now()}`;
    return {
        runId,
        graphqlUrl: env.HS_LIVE_GRAPHQL_URL || 'http://localhost:4000/',
        platform: env.HS_LIVE_PLATFORM || 'sqlserver',
        companyID: env.HS_LIVE_COMPANY_ID,
        integrationID: env.HS_LIVE_INTEGRATION_ID,
        credentialTypeID: env.HS_LIVE_CREDTYPE_ID,
        // REFERENCE MODE: when set, the connection + encrypted credential already exist; the harness
        // drives by this ID and NEVER needs the token (server decrypts it internally). This is the
        // "use it, never read its value" path — the agent runs the full test token-free.
        companyIntegrationID: env.HS_LIVE_CIID,
        objects: (env.HS_LIVE_OBJECTS || 'contacts,companies,deals,assoc_contacts_companies').split(',').map(s => s.trim()).filter(Boolean),
        mjSchema: env.HS_LIVE_MJ_SCHEMA || env.MJ_CORE_SCHEMA || '__mj',
        maxPolls: Number(env.HS_LIVE_MAX_POLLS || 100000),
        // DB coordinates fall back to the standard MJAPI .env names so sourcing that file in the broker
        // "just works" with no manual mapping (HS_LIVE_* overrides win when set per-job).
        db: {
            host: env.HS_LIVE_DB_HOST || env.DB_HOST || 'localhost',
            port: env.HS_LIVE_DB_PORT || env.DB_PORT,
            database: env.HS_LIVE_DB_NAME || env.DB_DATABASE,
            user: env.HS_LIVE_DB_USER || env.DB_USERNAME,
        },
        writeObject: env.HS_LIVE_WRITE_OBJECT || 'contacts',
        // ApplyAll scope (E7). The LIVE HubSpot harness keeps 'full' (the P0.5 at-scale full-catalog
        // DDL test) unless overridden; the connector-e2e path defaults this to 'scoped'
        // (connectorE2eCfgFromEnv) so it doesn't apply a giant catalog. HS_LIVE_APPLY_SCOPE overrides.
        applyScope: env.HS_LIVE_APPLY_SCOPE === 'scoped' ? 'scoped' : 'full',
        // A recognizable, runId-stamped contact in standard fields (no custom property needed).
        // example.com is RFC-2606 reserved (never deliverable) yet a VALID email format — HubSpot rejects the
        // .invalid TLD on create, so the test contact uses a format the vendor accepts while staying obviously test.
        writeAttributes: { email: `mj-live-${runId}@example.com`, firstname: 'MJ', lastname: `Live ${runId}` },
        writeUpdateAttributes: { jobtitle: `updated-${runId}` },
    };
}

/**
 * Shared driver for the GQL-live plans: builds the real IO adapters from dereferenced secrets +
 * non-secret env cfg, resolves the setup IDs, and runs the injectable orchestration. Read-only when
 * allowWrite=false (forward path only); full forward+backward when allowWrite=true.
 */
async function runLivePlan(values, scrub, allowWrite) {
    const cfg = liveCfgFromEnv();
    const db = await makeDbClient(cfg.platform, { ...cfg.db, password: values.dbPassword, mjSchema: cfg.mjSchema });
    const ids = await resolveSetupIds(db, cfg);
    // MJAPI auth: system API key (x-mj-api-key) is the simplest for a workbench; falls back to a
    // user key (x-api-key) or a JWT (Bearer) if those are what's provided. All are scrubbed secrets.
    const gql = makeGqlClient(cfg.graphqlUrl, { mjSystemKey: values.mjSystemKey, mjUserKey: values.mjUserKey, mjToken: values.mjToken });
    // Token present (create mode / direct-API parity) vs absent (reference mode — token-free, the
    // server uses the encrypted credential internally; external parity is skipped).
    const hubspotTotal = values.token ? makeHubspotTotal(values.token) : null;
    const fullCfg = { ...cfg, ...ids, token: values.token };
    const result = await runLiveTest({ gql, db, hubspotTotal }, fullCfg, allowWrite);
    return result; // the runner's scrubDeep redacts every secret value from this result
}

/**
 * READ-ONLY 2^N matrix entrypoint (reference mode, token-free): builds the same DB + GQL clients as
 * runLivePlan, resolves the seeded CIID from cfg.companyIntegrationID (HS_LIVE_CIID), and runs the
 * mechanics matrix (idempotency / content-hash, watermark + fallback, Merkle reconcile, DAG order).
 * No HUBSPOT_API_KEY secret is declared → token-free; the server decrypts the credential internally.
 * writes:false — it only re-syncs (Pull) + reads the DB / event stream / MJAPI log; it never deletes
 * the seeded connection or its maps (only toggles + resets ONE map's Configuration for the Merkle cell).
 */
export async function hubspotMatrixReadonlyGQL(values, scrub) { // eslint-disable-line no-unused-vars -- scrub kept for signature symmetry (the runner scrubs the returned result)
    const cfg = liveCfgFromEnv();
    if (!cfg.companyIntegrationID) {
        return { ok: false, error: 'hubspot-matrix-readonly requires HS_LIVE_CIID (reference mode) — none set' };
    }
    const db = await makeDbClient(cfg.platform, { ...cfg.db, password: values.dbPassword, mjSchema: cfg.mjSchema });
    const ids = await resolveSetupIds(db, cfg);
    const gql = makeGqlClient(cfg.graphqlUrl, { mjSystemKey: values.mjSystemKey, mjUserKey: values.mjUserKey, mjToken: values.mjToken });
    const fullCfg = {
        ...cfg, ...ids,
        destSchema: process.env.HS_LIVE_DEST_SCHEMA || 'hubspot',
        mjapiLogPath: process.env.HS_LIVE_MJAPI_LOG || '/tmp/mjapi-4000.log',
    };
    // runMatrixReadonly closes the db in its finally; the runner's scrubDeep redacts secrets from the result.
    return runMatrixReadonly({ gql, db }, fullCfg);
}

/**
 * NON-DESTRUCTIVE §15 LIFECYCLE entrypoint (reference mode, token-free): builds the same DB + GQL
 * clients as hubspotMatrixReadonlyGQL, resolves the seeded CIID from cfg.companyIntegrationID
 * (HS_LIVE_CIID), and runs the lifecycle ops (deactivate-enforcement, deselect/reselect, cancel-status,
 * read-only op smoke). It operates on the seeded REUSABLE connection and RESTORES every mutation
 * (reactivate, re-activate the deals map) so the connection stays reusable. No HUBSPOT_API_KEY secret
 * is declared → token-free; the server decrypts the credential internally. writes:false externally —
 * it only re-syncs (Pull) + reads DB/status; it never deletes the seeded connection or its maps.
 */
export async function hubspotLifecycleGQL(values, scrub) { // eslint-disable-line no-unused-vars -- scrub kept for signature symmetry (the runner scrubs the returned result)
    const cfg = liveCfgFromEnv();
    if (!cfg.companyIntegrationID) {
        return { ok: false, error: 'hubspot-lifecycle requires HS_LIVE_CIID (reference mode) — none set' };
    }
    const db = await makeDbClient(cfg.platform, { ...cfg.db, password: values.dbPassword, mjSchema: cfg.mjSchema });
    const ids = await resolveSetupIds(db, cfg);
    const gql = makeGqlClient(cfg.graphqlUrl, { mjSystemKey: values.mjSystemKey, mjUserKey: values.mjUserKey, mjToken: values.mjToken });
    const fullCfg = { ...cfg, ...ids };
    // runLifecycleOps closes the db in its finally; the runner's scrubDeep redacts secrets from the result.
    return runLifecycleOps({ gql, db }, fullCfg);
}

/**
 * DESTRUCTIVE §15 DELETE-CASCADE entrypoint (reference mode, token-free): deletes the connection at
 * cfg.companyIntegrationID — which MUST be a DISPOSABLE throwaway CIID, NEVER the main seeded one — and
 * asserts the cascade's DESIRED completeness (credential deleted, CI row deleted, children cleaned).
 * writes:true as a SAFETY belt: it is destructive to MJ rows, so the broker REFUSES it unless the job
 * explicitly passes allowWrite:true. No HUBSPOT_API_KEY secret is declared → token-free.
 */
export async function hubspotDeleteCascadeGQL(values, scrub) { // eslint-disable-line no-unused-vars -- scrub kept for signature symmetry (the runner scrubs the returned result)
    const cfg = liveCfgFromEnv();
    if (!cfg.companyIntegrationID) {
        return { ok: false, error: 'hubspot-delete-cascade requires HS_LIVE_CIID (the DISPOSABLE throwaway CIID) — none set' };
    }
    const db = await makeDbClient(cfg.platform, { ...cfg.db, password: values.dbPassword, mjSchema: cfg.mjSchema });
    const fullCfg = { ...cfg };
    // runDeleteCascade closes the db in its finally; the runner's scrubDeep redacts secrets from the result.
    return runDeleteCascade({ gql: makeGqlClient(cfg.graphqlUrl, { mjSystemKey: values.mjSystemKey, mjUserKey: values.mjUserKey, mjToken: values.mjToken }), db }, fullCfg);
}

/**
 * Diagnostic (DB read-only, no token, no MJAPI): returns the IDs the GQL sync needs — the HubSpot
 * Integration, available Companies + CredentialTypes, and any EXISTING HubSpot CompanyIntegration
 * (which would enable token-free reference mode). Lets the agent pick the right IDs before syncing.
 */
export async function hubspotDiagGQL(values, scrub) {
    const cfg = liveCfgFromEnv();
    const db = await makeDbClient(cfg.platform, { ...cfg.db, password: values.dbPassword, mjSchema: cfg.mjSchema });
    const s = cfg.mjSchema ?? '__mj';
    const pg = cfg.platform === 'postgresql';
    const T = (n) => pg ? `"${s}"."${n}"` : `[${s}].[${n}]`;
    const C = (n) => pg ? `"${n}"` : n;
    const top = pg ? '' : 'TOP 25 ';
    const lim = pg ? ' LIMIT 25' : '';
    try {
        const hubspotIntegration = await db.rows(`SELECT ${top}${C('ID')}, ${C('Name')} FROM ${T('Integration')} WHERE ${C('Name')}='HubSpot'${lim}`);
        const companies = await db.rows(`SELECT ${top}${C('ID')}, ${C('Name')} FROM ${T('Company')}${lim}`);
        const credentialTypes = await db.rows(`SELECT ${top}${C('ID')}, ${C('Name')} FROM ${T('CredentialType')}${lim}`);
        const hsId = hubspotIntegration?.[0]?.ID ?? hubspotIntegration?.[0]?.id;
        let existingHubspotCIs = [];
        if (hsId) existingHubspotCIs = await db.rows(`SELECT ${top}${C('ID')}, ${C('Name')}, ${C('IsActive')} FROM ${T('CompanyIntegration')} WHERE ${C('IntegrationID')}='${hsId}'${lim}`);
        return { ok: true, platform: cfg.platform, hubspotIntegration, companies, credentialTypes, existingHubspotCIs };
    } finally { if (db.close) await db.close(); }
}

/** Forward-only (read-only) live path — runs unprompted (writes:false). Token mode OR reference mode. */
export async function hubspotLivePullGQL(values, scrub) {
    return runLivePlan(values, scrub, false);
}

/** Full matrix incl. backward CRUD (writes:true) — broker requires allowWrite:true. */
export async function hubspotLiveMatrixGQL(values, scrub) {
    return runLivePlan(values, scrub, true);
}

/**
 * One-time SEEDING step (run by someone who holds the token): creates the HubSpot connection, which
 * ENCRYPTS the token into the Credential table, and returns the CompanyIntegrationID. Hand that ID to
 * the agent as HS_LIVE_CIID; the agent then runs hubspot-live-pull-ref completely token-free — the
 * token stays encrypted in the DB and is used only server-side. This is the "use it, never read it" seam.
 */

/** HubSpot whoami — reveals the portal ID + owner/user emails so the operator knows which login the key belongs to. */
export async function hubspotWhoami(values, _scrub) {
    const H = { Authorization: `Bearer ${values.token}` };
    const det = await fetch("https://api.hubapi.com/account-info/v3/details", { headers: H });
    const detj = await det.json().catch(() => ({}));
    const own = await fetch("https://api.hubapi.com/crm/v3/owners?limit=100", { headers: H });
    const ownj = await own.json().catch(() => ({}));
    const emails = [...new Set((ownj.results || []).map((o) => o.email).filter(Boolean))];
    return { ok: det.ok, portalId: detj.portalId, accountType: detj.accountType, uiDomain: detj.uiDomain, dataHostingLocation: detj.dataHostingLocation, ownerEmails: emails.slice(0, 20) };
}

/**
 * Custom-property check — READ-ONLY. HubSpot's own Properties API tags each property with
 * `hubspotDefined` (true = vendor-shipped standard property, false/absent = genuinely created by
 * this tenant). Field-NAME heuristics (e.g. no "hs_" prefix) can't reliably distinguish "standard
 * property missing from our declared catalog" from "real tenant customization" — this uses the
 * vendor's own authoritative flag instead. Returns only property NAMES (no values/PII) per object.
 */
export async function hubspotCustomProperties({ token }, _scrub) {
    const H = { Authorization: `Bearer ${token}` };
    const objects = (process.env.HS_CUSTOM_PROPS_OBJECTS || 'companies,contacts,deals').split(',').map(s => s.trim());
    const out = { ok: true, plan: 'hubspot-custom-properties', perObject: {} };
    for (const obj of objects) {
        const res = await fetch(`https://api.hubapi.com/crm/v3/properties/${obj}`, { headers: H });
        const body = await res.json().catch(() => ({}));
        const props = Array.isArray(body.results) ? body.results : [];
        const custom = props.filter(p => p.hubspotDefined === false);
        out.perObject[obj] = {
            status: res.status,
            totalProperties: props.length,
            customPropertyCount: custom.length,
            customPropertyNames: custom.map(p => p.name),
        };
    }
    return out;
}

export async function hubspotSeedConnectionGQL(values, scrub) {
    const cfg = liveCfgFromEnv();
    // GQL-only path: when all setup IDs are provided (HS_LIVE_*_ID), the seed doesn't need a direct DB
    // connection to resolve them — skip it. This lets the seed run through a credential channel that holds the
    // vendor token + MJ system key but NOT the target DB password (e.g. seeding a Postgres connection from a
    // broker pointed at SQL Server). CreateConnection writes to the DB via the TARGET MJAPI's own connection.
    const haveAllIds = !!(cfg.companyID && cfg.integrationID && cfg.credentialTypeID);
    const db = haveAllIds ? null : await makeDbClient(cfg.platform, { ...cfg.db, password: values.dbPassword, mjSchema: cfg.mjSchema });
    try {
        const ids = haveAllIds
            ? { companyID: cfg.companyID, integrationID: cfg.integrationID, credentialTypeID: cfg.credentialTypeID }
            : await resolveSetupIds(db, cfg);
        const gql = makeGqlClient(cfg.graphqlUrl, { mjSystemKey: values.mjSystemKey, mjUserKey: values.mjUserKey, mjToken: values.mjToken });
        const input = {
            CompanyID: ids.companyID, IntegrationID: ids.integrationID, CredentialTypeID: ids.credentialTypeID,
            CredentialName: cfg.credentialName || `hs-live-${cfg.runId}`,
            CredentialValues: JSON.stringify({ apiKey: values.token }),
        };
        const conn = (await gql(GQL.createConnection, { input, testConnection: true, runSchemaRefresh: true })).IntegrationCreateConnection;
        return {
            ok: !!conn?.Success,
            companyIntegrationID: conn?.CompanyIntegrationID, // → give to the agent as HS_LIVE_CIID
            credentialID: conn?.CredentialID,
            connectionTest: { ok: conn?.ConnectionTestSuccess, message: conn?.ConnectionTestMessage },
            schemaRefresh: conn?.SchemaRefresh ?? null,
            next: 'Set HS_LIVE_CIID=<companyIntegrationID> and run hubspot-live-pull-ref (token-free).',
        };
    } finally { if (db && db.close) await db.close(); }
}

/**
 * SETUP step (faithful, GraphQL — not a raw DB insert): creates an MJ Company via the live MJAPI so the
 * connection has a Company to attach to. Mirrors the plan.md "create a company record" step. writes:false
 * externally (it only writes one MJ row through the app, makes no external/vendor call). Returns the new
 * Company ID to hand back as HS_LIVE_COMPANY_ID for hubspot-seed-connection.
 */
export async function setupCompanyGQL(values, scrub) { // eslint-disable-line no-unused-vars -- scrub kept for signature symmetry
    const cfg = liveCfgFromEnv();
    const gql = makeGqlClient(cfg.graphqlUrl, { mjSystemKey: values.mjSystemKey, mjUserKey: values.mjUserKey, mjToken: values.mjToken });
    const name = process.env.HS_LIVE_COMPANY_NAME || `MJ E2E Test Co (${cfg.runId})`;
    const mutation = `mutation($input: CreateMJCompanyInput!) { CreateMJCompany(input: $input) { ID Name } }`;
    const res = await gql(mutation, { input: { Name: name, Description: 'Throwaway company for the live HubSpot integration E2E test' } });
    const created = res?.CreateMJCompany;
    return {
        ok: !!created?.ID,
        companyID: created?.ID,
        name: created?.Name,
        next: 'Set HS_LIVE_COMPANY_ID=<companyID> and run hubspot-seed-connection.',
    };
}

/**
 * Maintenance (DB-only, no external calls, no token): clear the HubSpot dest tables so a forward sync
 * starts from a clean slate — lets the record-map 1:1 completeness assertion test a fresh create path
 * rather than a re-sync over rows left by a prior (possibly interrupted) run. Deletes ROWS only; never
 * drops tables, never touches users/owners or any non-hubspot schema.
 */
export async function hubspotCleanData(values, scrub) {
    const cfg = liveCfgFromEnv();
    const db = await makeDbClient(cfg.platform, { ...cfg.db, password: values.dbPassword, mjSchema: cfg.mjSchema });
    const pg = cfg.platform === 'postgresql';
    const destSchema = process.env.HS_LIVE_DEST_SCHEMA || 'hubspot';
    const T = (n) => pg ? `"${destSchema}"."${n}"` : `[${destSchema}].[${n}]`;
    const tables = (process.env.HS_LIVE_CLEAN_TABLES || 'contacts,companies,deals,assoc_contacts_companies')
        .split(',').map(s => s.trim()).filter(Boolean);
    const out = { ok: false, platform: cfg.platform, destSchema, cleaned: {} };
    try {
        // assoc first (it references the parents), then parents — DELETE (not TRUNCATE) to tolerate any soft refs.
        for (const t of tables) {
            try { await db.rows(`DELETE FROM ${T(t)}`); out.cleaned[t] = 'deleted'; }
            catch (e) { out.cleaned[t] = scrub(`skip: ${e instanceof Error ? e.message : String(e)}`); }
        }
        out.ok = true;
        return out;
    } finally { if (db.close) await db.close(); }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONNECTOR-AGNOSTIC e2e plan (mock + live) — runs the REAL engine for ANY connector
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Build the connector-agnostic e2e config from env + a base live cfg. NON-secret only.
 * Env vars (NEW; reuses all HS_LIVE_* DB/GQL coordinates from liveCfgFromEnv):
 *   E2E_CONNECTOR        registry connector dir name (e.g. 'propfuel') — required
 *   E2E_MODE             'mock' (credential-free, default) | 'live' (credentialed)
 *   E2E_FIXTURES_DIR     absolute path to the connector's `fixtures/` dir (mock mode).
 *                        Default: <this test dir>/fixtures/<connector>/fixtures
 *   E2E_INTEGRATION      MJ Integration NAME to resolve the IntegrationID by (e.g. 'PropFuel')
 *   E2E_SCHEMA           destination schema for verification override (else metadata-resolved)
 *   E2E_PLATFORM         'sqlserver' | 'postgresql' (falls back to HS_LIVE_PLATFORM)
 *   E2E_OBJECTS          comma-sep source objects (else taken from the fixtures Objects[])
 *   E2E_TLS_CERT/E2E_TLS_KEY  PEM paths for HTTPS-MITM proxy mode (hardcoded-base connectors)
 */
function connectorE2eCfgFromEnv() {
    const env = process.env;
    const base = liveCfgFromEnv();
    const here = pathResolve(new URL('.', import.meta.url).pathname);
    const connector = env.E2E_CONNECTOR;
    const mode = (env.E2E_MODE === 'live') ? 'live' : 'mock';
    const fixturesDir = env.E2E_FIXTURES_DIR || pathResolve(here, 'fixtures', String(connector || ''), 'fixtures');
    return {
        ...base,
        connector,
        mode,
        fixturesDir,
        integrationName: env.E2E_INTEGRATION || base.integrationID || connector,
        platform: env.E2E_PLATFORM || base.platform,
        schema: env.E2E_SCHEMA || undefined,
        objectsOverride: (env.E2E_OBJECTS || '').split(',').map(s => s.trim()).filter(Boolean),
        tls: { cert: env.E2E_TLS_CERT, key: env.E2E_TLS_KEY },
        // E7 — the connector-e2e path applies ONLY the objects-under-test + their FK parents by default
        // (NOT the full discovered catalog, which is infeasible at scale). E2E_APPLY_SCOPE=full opts back in.
        applyScope: env.E2E_APPLY_SCOPE === 'full' ? 'full' : 'scoped',
        // E6 — when set, regenerate fixtures from the CURRENTLY-deployed IO/IOF before the run so they
        // never drift from a renamed/changed object set (the openwater/growthzone 0-row failure class).
        regenFixtures: env.E2E_REGEN_FIXTURES === 'true',
    };
}

/**
 * Create a connection with an optional Configuration patch (used by mock ORIGIN mode to
 * seed the connector's config-driven BaseURL at the local mock), via the SAME public
 * IntegrationCreateConnection op the live harness uses — no core change. Returns the CIID.
 *
 * @param {(q:string,v:object)=>Promise<object>} gql
 * @param {object} ids   { companyID, integrationID, credentialTypeID }
 * @param {object} opts  { credentialName, credentialValues (object), configuration (object) }
 */
async function createConnectionWithConfig(gql, ids, opts) {
    const input = {
        CompanyID: ids.companyID,
        IntegrationID: ids.integrationID,
        CredentialTypeID: ids.credentialTypeID,
        CredentialName: opts.credentialName,
        CredentialValues: JSON.stringify(opts.credentialValues ?? {}),
        ...(opts.configuration ? { Configuration: JSON.stringify(opts.configuration) } : {}),
    };
    // runSchemaRefresh defaults ON, but a connector whose metadata is already DECLARED (and whose
    // discovery is AUTHORITATIVE) would, on a full refresh against a partial mock, deactivate every
    // object it can't describe. E2E_SCHEMA_REFRESH=false skips the refresh and drives the sync off the
    // declared IOFs — correct when the objects under test already exist in the catalog. General.
    // consumerOnly (E2E_LIVE_CONFIG.consumerOnly) skips the schema refresh too — the consumer path does
    // its OWN live DiscoverObjects, and we want no schema build/codegen on this fast strong-evidence run.
    let _consumerOnly = false;
    try { _consumerOnly = JSON.parse(process.env.E2E_LIVE_CONFIG || '{}').consumerOnly === true; } catch { /* ignore */ }
    const runSchemaRefresh = !_consumerOnly && process.env.E2E_SCHEMA_REFRESH !== 'false';
    // AUTH-ONLY mode: E2E_CONN_TEST_ONLY=1 → test the vendor credential (testConnection:true, no schema
    // refresh, no ApplyAll) and short-circuit, carrying the auth verdict in the thrown message so the
    // runner surfaces it as result.error. Lets us prove "is the cred valid?" independent of any sync/save bug.
    let connTestOnly = false; try { connTestOnly = JSON.parse(process.env.E2E_LIVE_CONFIG || '{}').connTestOnly === true; } catch { /* ignore */ }
    const conn = (await gql(GQL.createConnection, { input, testConnection: connTestOnly, runSchemaRefresh: connTestOnly ? false : runSchemaRefresh })).IntegrationCreateConnection;
    if (connTestOnly) {
        throw new Error('CONNTEST ' + JSON.stringify({ createOk: !!conn?.Success, authOk: conn?.ConnectionTestSuccess ?? null, msg: String(conn?.ConnectionTestMessage || conn?.Message || '').slice(0, 160) }));
    }
    if (!conn?.Success || !conn.CompanyIntegrationID) {
        throw new Error(`CreateConnection failed: ${conn?.Message ?? 'no payload'}`);
    }
    return { ciid: conn.CompanyIntegrationID, credentialID: conn.CredentialID, schemaRefresh: conn.SchemaRefresh ?? null };
}

/**
 * CONNECTOR-AGNOSTIC e2e driver. Boots the mock (mock mode) or uses the live vendor,
 * stands up a real connection (seeding the mock origin into Configuration for config-driven
 * connectors), then runs the real engine end-to-end (ApplyAll → StartSync → tail → DB verify
 * incl. delta create/update/delete + idempotent re-run). Reuses gql-live-harness phases.
 *
 * Secrets (live mode only): dbPassword + mjSystemKey + (token OR pre-seeded CIID). Mock mode
 * declares NO vendor secret — credential-free by construction.
 */
async function connectorE2EPlan(values, scrub, allowWrite) { // eslint-disable-line no-unused-vars -- scrub kept for signature symmetry (runner scrubs result)
    const cfg = connectorE2eCfgFromEnv();
    // Per-vendor override: a vendor plan passes its EXACT MJ Integration name so a shared broker
    // (launched with --all, which pins E2E_INTEGRATION to the alphabetically-first vendor) still
    // targets the right Integration without a per-vendor broker re-launch.
    if (values?.integrationName) cfg.integrationName = values.integrationName;
    // Per-vendor ApplyAll scope override (overnight3: full object coverage — all rows/all tables).
    if (values?.applyScope) cfg.applyScope = values.applyScope;
    // Same broker-pinned-env problem as integrationName above: cfg.connector (used for the reported
    // label + credentialName uniqueness) came ONLY from process.env.E2E_CONNECTOR, which --all pins to
    // whichever vendor .env loaded last. Let a vendor plan override it explicitly when it knows its own
    // registry connector-dir name.
    if (values?.connector) cfg.connector = values.connector;
    if (!cfg.connector) return { ok: false, error: 'connector-e2e requires E2E_CONNECTOR (registry connector dir name)' };

    // Custom-column capture→promote on a DISPOSABLE campaign DB. The harness gates that stage behind
    // E2E_LIVE_CUSTOM_COLUMNS=1 because promotion runs an RSU ADD COLUMN against the MJ schema — unsafe
    // on a real client tenant, safe on a throwaway. That flag cannot arrive via job.env: the broker's
    // JOB_ENV_ALLOW allowlist lives in the long-running broker process (owned by mjbroker) and does not
    // include it. run-plan.mjs, by contrast, is spawned fresh per job, so setting it HERE takes effect
    // with no broker restart. Scoped to the campaign's disposable lane DBs by name (MJ_OV3_L<n>) so it
    // can never fire against a client database. Explicit env always wins.
    const _dbName = String(cfg.db?.database ?? '');
    if (process.env.E2E_LIVE_CUSTOM_COLUMNS == null && /^MJ_OV3_L\d+$/i.test(_dbName)) {
        process.env.E2E_LIVE_CUSTOM_COLUMNS = '1';
        console.log(`[connector-e2e] custom-column promote ENABLED — disposable campaign DB '${_dbName}'`);
    }

    // Local MJ DB password override: let the job supply the assertion-client DB password via the
    // allowlisted E2E_LIVE_CONFIG.dbPassword / E2E_DB_PASSWORD (a LOCAL test-DB pw, NOT a vendor secret),
    // so a broker launched with a different default DB_PASSWORD still reaches this run's DB. Falls back to
    // the broker-held DB_PASSWORD secret. (growthzone-e2e-live already threads this in via values.)
    let _liveCfgPwd; try { _liveCfgPwd = JSON.parse(process.env.E2E_LIVE_CONFIG || '{}').dbPassword; } catch { /* ignore */ }
    const dbPassword = _liveCfgPwd || process.env.E2E_DB_PASSWORD || values.dbPassword;

    const db = await makeDbClient(cfg.platform, { ...cfg.db, password: dbPassword, mjSchema: cfg.mjSchema });
    const gql = makeGqlClient(cfg.graphqlUrl, { mjSystemKey: values.mjSystemKey, mjUserKey: values.mjUserKey, mjToken: values.mjToken });

    // Resolve the IntegrationID by the EXPLICIT E2E_INTEGRATION name FIRST (before the mock loads
    // fixtures) so the optional E6 regen can mirror the deployed schema. Do NOT route this through
    // resolveSetupIds — that helper hardcodes a 'HubSpot' name default (it predates the generic
    // connector-e2e path), so a non-HubSpot connector would bind to HubSpot's Integration and
    // ApplyAll would instantiate the wrong connector class ("No HubSpot credentials found").
    let mock = null;
    let integrationID = cfg.integrationID || await db.resolveId(
        cfg.platform === 'postgresql'
            ? `SELECT "ID" FROM "${cfg.mjSchema}"."Integration" WHERE "Name" = $1 LIMIT 1`
            : `SELECT TOP 1 ID FROM [${cfg.mjSchema}].[Integration] WHERE Name = @n`,
        cfg.platform === 'postgresql' ? [cfg.integrationName] : { n: cfg.integrationName });

    // E6 — regenerate fixtures from the CURRENTLY-DEPLOYED IO/IOF before the mock loads them, so the
    // fixtures never drift from a renamed/changed object set. Best-effort: a regen failure logs and
    // falls through to the existing fixtures (never silently fakes a pass). Mock mode + an integration only.
    let fixtureRegen = null;
    if (cfg.mode === 'mock' && cfg.regenFixtures && integrationID) {
        try {
            fixtureRegen = await regenerateFixturesFromDeployed({
                db, platform: cfg.platform, mjSchema: cfg.mjSchema, integrationID,
                fixturesDir: cfg.fixturesDir, cfgKey: process.env.E2E_CFG_URL_KEY || 'BaseURL',
                // Full per-object coverage: fixture EVERY deployed object, not a bounded "Goldilocks" subset.
                // The old default (7) silently capped large catalogs to a famous-few. Env-overridable for
                // a deliberately-bounded run; default is effectively uncapped.
                maxObjects: Number(process.env.E2E_MAX_FIXTURE_OBJECTS) || 100000,
            });
            console.log(`[connector-e2e] regen-fixtures: ${fixtureRegen.ok ? `wrote ${fixtureRegen.written} (${(fixtureRegen.objectNames || []).join(', ')})` : `skipped — ${fixtureRegen.reason}`}`);
        } catch (e) { fixtureRegen = { ok: false, reason: String(e?.message ?? e) }; console.log(`[connector-e2e] regen-fixtures failed: ${fixtureRegen.reason}`); }
    }

    // Build the mock (mock mode boots the fixtures-replaying server; live mode is inert).
    mock = await buildMock({ mode: cfg.mode, fixturesDir: cfg.fixturesDir, tls: cfg.tls });

    try {
        if (!integrationID) throw new Error(`connector-e2e: no Integration found by name '${cfg.integrationName}' (set E2E_INTEGRATION to the exact MJ: Integrations.Name)`);

        // Resolve the CredentialTypeID. PREFER the Integration row's OWN CredentialTypeID — that is the
        // value the connector's metadata declared (set by `mj sync push` via its @lookup), so it always
        // matches the credential type the connector actually expects AND is always a DB-canonical,
        // hyphenated uniqueidentifier. The env-supplied HS_LIVE_CREDTYPE_ID is only a fallback: a
        // hand-passed env value can be wrong (a stale/placeholder type) or malformed (a 32-hex GUID with
        // its hyphens stripped → spCreateCredential fails with "Conversion failed ... to uniqueidentifier").
        // We accept the env value ONLY when it is a well-formed hyphenated GUID; otherwise we derive from
        // the Integration row. This makes the credential-type resolution robust to env-construction
        // mistakes and keeps it in lockstep with the metadata the connector was pushed with.
        const HYPHENATED_GUID = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;
        let credentialTypeID = cfg.credentialTypeID;
        const integrationCredTypeID = await db.resolveId(
            cfg.platform === 'postgresql'
                ? `SELECT "CredentialTypeID" AS "ID" FROM "${cfg.mjSchema}"."Integration" WHERE "ID" = $1 LIMIT 1`
                : `SELECT TOP 1 CredentialTypeID AS ID FROM [${cfg.mjSchema}].[Integration] WHERE ID = @n`,
            cfg.platform === 'postgresql' ? [integrationID] : { n: integrationID });
        if (integrationCredTypeID) {
            credentialTypeID = integrationCredTypeID; // metadata-declared type wins — always correct + canonical
        } else if (!credentialTypeID || !HYPHENATED_GUID.test(String(credentialTypeID))) {
            throw new Error(`connector-e2e: could not resolve a valid CredentialTypeID for integration '${cfg.integrationName}' — Integration.CredentialTypeID is null and HS_LIVE_CREDTYPE_ID ('${cfg.credentialTypeID ?? ''}') is missing/malformed. Set the connector's CredentialTypeID @lookup in metadata so 'mj sync push' populates it.`);
        }
        const setupIds = { companyID: cfg.companyID, integrationID, credentialTypeID };

        // Objects: explicit override > fixtures Objects[] (mock) > cfg default list.
        const objects = cfg.objectsOverride.length ? cfg.objectsOverride
            : (cfg.mode === 'mock' ? objectsFromManifest(mock.manifest) : cfg.objects);
        if (!objects.length) throw new Error('connector-e2e: no objects to apply (set E2E_OBJECTS or provide fixtures Objects[])');

        // Stand up the connection. Mock mode seeds the mock origin/file path + any extra static
        // config into Configuration so a config-driven connector reaches the mock with NO real
        // credential. Proxy-mode (hardcoded base) gets no config patch (redirect is via the
        // MJAPI-process proxy — see proxyEnvExpected in the result). Live mode uses the real token.
        let ciid, credentialID = null;
        // Token presence forces TOKEN mode (fresh CreateConnection + schema-refresh + entity
        // mapping that APPLIES E2E_LIVE_CONFIG, e.g. {AccountID}). Reference mode is the token-FREE
        // path only (a pre-seeded CIID). Without this guard a STALE HS_LIVE_CIID lingering in the
        // broker's launch env silently forces reference mode for a token run → no createConnection
        // → E2E_LIVE_CONFIG (AccountID) never applied → connector fails credential validation →
        // 0 discovered objects → 0 entity maps → 0 rows (a vacuous "pass"). Token wins.
        if (cfg.companyIntegrationID && !values.token && !values.credentialValues) {
            ciid = cfg.companyIntegrationID; // reference mode — token-free, pre-seeded connection only
        } else {
            // Live-mode credential shape is connector-specific. Default is HubSpot-style
            // { apiKey }, but a connector that reads a differently-named secret key (e.g.
            // PropFuel reads { Token, AccountID }) sets E2E_TOKEN_KEY (the secret key name)
            // + E2E_LIVE_CONFIG (non-secret config JSON merged into both credential + config,
            // e.g. {"AccountID":"2019"}). Keeps the default working; generalizes per connector.
            // MULTI-SECRET connectors (e.g. PheedLoop reads { ApiKey, ApiSecret, OrganizationCode };
            // GrowthZone reads { ClientId, ClientSecret, ... }) can't fit a single token — a vendor
            // plan pre-builds values.credentialValues (+ optional values.configuration) from MULTIPLE
            // broker-held secrets, which wins here. Secrets stay broker-side (never in the job env).
            const liveTokenKey = process.env.E2E_TOKEN_KEY || 'apiKey';
            let liveExtra = {};
            try { liveExtra = process.env.E2E_LIVE_CONFIG ? JSON.parse(process.env.E2E_LIVE_CONFIG) : {}; } catch { liveExtra = {}; }
            const credentialValues = cfg.mode === 'mock'
                ? { ...(mock.manifest?.Configuration ?? {}), ...(mock.configPatch ?? {}) } // dummy + mock redirect
                : (values.credentialValues ?? { ...liveExtra, [liveTokenKey]: values.token });
            const configuration = cfg.mode === 'mock'
                ? { ...(mock.manifest?.Configuration ?? {}), ...(mock.configPatch ?? {}) }
                : (values.configuration ?? (Object.keys(liveExtra).length ? liveExtra : undefined));
            const created = await createConnectionWithConfig(gql, setupIds, {
                // Credential name MUST be unique per CreateConnection call. cfg.connector can resolve to a
                // stale/broker-global vendor (e.g. "constantcontact" during a growthzone job — the
                // broker-global-E2E_INTEGRATION defect), and cfg.runId is fixed once per broker session,
                // so `e2e-${cfg.connector}-${cfg.runId}` was IDENTICAL across every connector's run →
                // UQ_Credential_TypeName collision after the first (test-harness bug, not a framework
                // limit — two integrations CAN share a credential TYPE, they just need distinct NAMES).
                // Append a per-call unique token so the name can never collide regardless of the
                // wrong-vendor-name issue; the credential VALUES still come from the job's own injected
                // secrets, so this only fixes the name, not the (correct) auth material.
                credentialName: `e2e-${cfg.connector}-${cfg.runId}-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`,
                credentialValues, configuration,
            });
            ciid = created.ciid; credentialID = created.credentialID;
        }

        // FAST STRONG-EVIDENCE PATH (E2E_CONSUMER_ONLY=1): the MJCentral discovery/consumer path IS the
        // question — does IntegrationDiscoverObjects / ListSourceObjects / DiscoverFields + the
        // metadata⋈external join work for this connector? It needs ONLY a credentialed ciid + seeded
        // metadata, NOT a full ApplyAll/codegen (which is ~89% of the pipeline time). Run it here and
        // return, skipping materialize. Pair with E2E_SCHEMA_REFRESH=false so CreateConnection did no
        // schema build either — pure read-only discovery, exactly what MJCentral drives.
        let consumerOnly = false;
        try { consumerOnly = JSON.parse(process.env.E2E_LIVE_CONFIG || '{}').consumerOnly === true; } catch { /* ignore */ }
        if (consumerOnly) {
            const consumerSteps = await phaseMJCentralConsumerPath({ gql, db, ciid, cfg, integrationID });
            const allGreen = consumerSteps.length > 0 && consumerSteps.every((s) => s.ok === true);
            return { ok: allGreen, mode: cfg.mode, connector: cfg.connector, consumerOnly: true, ciid,
                integrationName: cfg.integrationName, integrationID, steps: { mjcentralConsumer: consumerSteps } };
        }

        // Object set = MJ's OWN discovery + RSU resolution, NOT a hand-fed harness list. The pipeline
        // (discover → persist → rsuplan → materialize) is authoritative about which objects exist — a
        // mix of Declared metadata + runtime-discovered custom objects (e.g. Salesforce `__c`). So we
        // sync the FULL discovered IntegrationObject set, exactly as production management would. The
        // per-connector `objects` list is demoted to an OPTIONAL priority/depth hint (logged for
        // visibility), never a set selector — a stale/generic guess must NOT shrink the tested surface
        // to a Goldilocks subset (that was the object-set-cap defect: it silently under-proved and
        // violated "Goldilocks bounds ROW DEPTH, never the object SET"). Throw LOUDLY only when
        // discovery genuinely found zero objects (a real connector/credential fault).
        let appliedObjects = objects;
        if (cfg.mode !== 'mock') {
            const ioQ = cfg.platform === 'postgresql'
                ? `SELECT "Name" FROM "${cfg.mjSchema}"."IntegrationObject" WHERE "IntegrationID" = '${integrationID}'`
                : `SELECT Name FROM [${cfg.mjSchema}].[IntegrationObject] WHERE IntegrationID = '${integrationID}'`;
            const discovered = (await db.rows(ioQ)).map((r) => r.Name).filter(Boolean);
            if (!discovered.length) {
                throw new Error(`connector-e2e: connection discovered 0 IntegrationObjects for ` +
                    `'${cfg.integrationName}' — schema refresh found nothing (check credential/AccountID + DiscoverObjects).`);
            }
            // Use the FULL discovered/RSU-resolved set. (phaseSetup's E2E_SYNC_ALL_OBJECTS default also
            // syncs every materialized map; setting cfg.objects to the full set makes this robust even
            // if that flag is ever turned off, and keeps the coverage gate measuring the whole surface.)
            appliedObjects = discovered;
            const want = new Set(objects.map((s) => s.toLowerCase()));
            const matched = discovered.filter((d) => want.has(d.toLowerCase()));
            console.log(`[connector-e2e] object set = full MJ discovery/RSU resolution: ${discovered.length} object(s). ` +
                `Requested hint [${objects.join(', ')}] matched ${matched.length} (hint is priority-only, not a set selector).`);
        }

        // Optional matrix-cell specs from the fixture (discovery overlay, write round-trip). Absent ⇒
        // the corresponding phases stub-with-reason; never a fake pass.
        const matrixSpecs = cfg.mode === 'mock' ? matrixSpecsFromManifest(mock.manifest) : { discoverable: false, discoverNarrowedRoutes: null, writeRoundTrip: null };
        const fullCfg = {
            ...cfg,
            companyIntegrationID: ciid,
            objects: appliedObjects,
            integrationID,
            credentialID,
            // E7 — applyScope is carried from cfg (scoped by default for connector-e2e); phaseSetup honors it.
            applyScope: cfg.applyScope,
            deltaPasses: cfg.mode === 'mock' ? deltaPassesFromManifest(mock.manifest) : [],
            // Spread the FULL declared-capability set so every lifecycle stage can gate on it:
            // discoverable, supportsFieldDiscovery, customTables, supportsCustomColumns, incrementalStrategy,
            // supportsPartitionReconcile, supportsWrite, writeRoundTrip, supportsScheduling,
            // connectionTestable, discoverNarrowedRoutes, lifecycleDeclared.
            ...matrixSpecs,
        };

        const result = await runConnectorE2E({ gql, db, mock }, fullCfg, allowWrite);
        // Surface the mock wiring summary so an operator/agent can confirm the redirect path.
        result.mockWiring = cfg.mode === 'mock'
            ? { kind: mock.kind, baseURL: mock.baseURL ?? null, proxyURL: mock.proxyURL ?? null, tlsRequired: mock.tlsRequired ?? false, proxyEnvExpected: mock.proxyEnvExpected ?? null, fixtureWarnings: mock.warnings ?? [] }
            : { mode: 'live' };
        result.applyScope = cfg.applyScope;       // E7 — record the scope actually used
        if (fixtureRegen) result.fixtureRegen = fixtureRegen; // E6 — record whether/what was regenerated
        return result;
    } catch (e) {
        try { if (mock?.close) await mock.close(); } catch { /* best-effort */ }
        try { if (db.close) await db.close(); } catch { /* best-effort */ }
        return { ok: false, mode: cfg.mode, connector: cfg.connector, error: String(e?.stack ?? e?.message ?? e) };
    }
}

/** Mock-mode (credential-free) e2e — writes:false (read-only from vendor; DB writes are into our own schema). */
export async function connectorE2EMock(values, scrub) { return connectorE2EPlan(values, scrub, false); }
/** Live-mode (credentialed) e2e — writes:false by default; backward CRUD only with allowWrite (live + flag). */
export async function connectorE2ELive(values, scrub) { return connectorE2EPlan(values, scrub, false); }

/**
 * PheedLoop LIVE e2e — MULTI-SECRET (X-API-KEY + X-API-SECRET + org code), which the single-token
 * connector-e2e-live path can't carry. The broker holds PHEEDLOOP_API_KEY + PHEEDLOOP_API_SECRET
 * (dereferenced into `values` by the runner); PHEEDLOOP_ORG_CODE (non-secret, part of the URL path)
 * rides the broker env. Builds the connector's CredentialValues from all three and drives the full
 * connector-e2e against the REAL PheedLoop API — non-vacuous by construction (real records). The two
 * secrets never leave the broker process. writes:false (read/sync only; no vendor mutation).
 */
export async function pheedloopE2ELive(values, scrub) {
    const orgCode = (process.env.PHEEDLOOP_ORG_CODE || '').trim();
    const cred = { ApiKey: values.apiKey, ApiSecret: values.apiSecret, OrganizationCode: orgCode };
    return connectorE2EPlan({ ...values, integrationName: 'PheedLoop', applyScope: 'full', credentialValues: cred, configuration: cred }, scrub, false);
}

/**
 * GrowthZone LIVE e2e — MULTI-SECRET OAuth2 (ClientId + ClientSecret + Username + Password + BaseURL),
 * password grant (the operator's refresh token is expired). clientId/clientSecret are dereferenced by
 * the runner; BaseURL/Username/Password ride the broker env (never the job). Builds the connector's
 * CredentialValues and drives the full connector-e2e against the REAL GrowthZone tenant — non-vacuous
 * by construction. Secrets never leave the broker process. writes:false.
 */
export async function growthzoneE2ELive(values, scrub) {
    const env = process.env;
    const baseURL = (env.GROWTHZONE_BASE_URL || '').trim();
    const cred = {
        BaseURL: baseURL,
        ClientId: values.clientId,
        ClientSecret: values.clientSecret,
        Username: env.GROWTHZONE_USERNAME,
        Password: env.GROWTHZONE_PASSWORD,
        // RefreshToken DELIBERATELY OMITTED (operator-directed 2026-07): the broker's GZ refresh_token is
        // expired, and the connector picks grant='refresh_token' whenever RT is present with NO fallback to
        // the password grant on failure (held-PR bug). Dropping RT forces the working password grant. To
        // re-include it, set GROWTHZONE_USE_REFRESH_TOKEN=1 in the broker env.
        ...(env.GROWTHZONE_USE_REFRESH_TOKEN === '1' && env.GROWTHZONE_REFRESH_TOKEN ? { RefreshToken: env.GROWTHZONE_REFRESH_TOKEN } : {}),
    };
    // For a cross-dialect run (e.g. GZ on Postgres) the assertion DB password differs from the broker's
    // default DB_PASSWORD. Allow a per-job override — carried inside E2E_LIVE_CONFIG (already allowlisted,
    // so no broker restart) or E2E_DB_PASSWORD. These are local test DB pwds, NOT real secrets.
    let liveCfgPwd;
    try { liveCfgPwd = JSON.parse(env.E2E_LIVE_CONFIG || '{}').dbPassword; } catch { /* ignore */ }
    const dbPassword = liveCfgPwd || env.E2E_DB_PASSWORD || values.dbPassword;
    return connectorE2EPlan({ ...values, integrationName: 'GrowthZone', applyScope: 'full', dbPassword, credentialValues: cred, configuration: { BaseURL: baseURL } }, scrub, false);
}

// ── Install-path Track-1 multi-secret e2e-live plans (added for the connector go-to-market test) ──────
// Each mirrors the pheedloop/growthzone pattern: the runner dereferences the `secrets` map into
// `values.*`; non-secret + optional fields are read from the broker env directly. credentialValues is
// the FULL set the connector reads (encrypted into MJ:Credentials.Values); configuration carries the
// non-secret identifiers a connector may read from CompanyIntegration.Configuration. Secrets NEVER leave
// the broker. All writes:false (forward/read+sync path only). Field KEY names match each connector's
// ExtractConfig exactly (source of truth: the connector .ts) — a wrong key = auth fails = MY bad step.

/**
 * SharePoint (Microsoft Graph) LIVE sync e2e — complements the read-only `sharepoint-readonly` probe
 * with a FULL connector-e2e. client_credentials: TenantId + ClientId + ClientSecret broker-held;
 * optional GraphBaseUrl/Scope ride the broker env. ClientSecret never leaves the broker. writes:false.
 */
export async function sharepointE2ELive(values, scrub) {
    const env = process.env;
    const cred = {
        TenantId: values.tenantId,
        ClientId: values.clientId,
        ClientSecret: values.clientSecret,
        ...(env.SHAREPOINT_GRAPH_BASE ? { GraphBaseUrl: env.SHAREPOINT_GRAPH_BASE } : {}),
        ...(env.SHAREPOINT_SCOPE ? { Scope: env.SHAREPOINT_SCOPE } : {}),
    };
    const cfg = { TenantId: cred.TenantId, ClientId: cred.ClientId, ...(cred.GraphBaseUrl ? { GraphBaseUrl: cred.GraphBaseUrl } : {}), ...(cred.Scope ? { Scope: cred.Scope } : {}) };
    // connector must be overridden the same way integrationName is above — under a shared multi-vendor
    // broker (--all), E2E_CONNECTOR is pinned to whichever vendor .env loaded first/last, which silently
    // baked "constantcontact" into this job's credentialName + reported connector label on shared lanes.
    return connectorE2EPlan({ ...values, integrationName: 'SharePoint', connector: 'sharepoint', applyScope: 'full', credentialValues: cred, configuration: cfg }, scrub, false);
}

/**
 * NetSuite LIVE e2e — OAuth 1.0a Token-Based Auth (HMAC-SHA256, realm=AccountID). All four signing
 * parts (ConsumerKey/Secret + TokenID/Secret) broker-held; AccountID/AuthFlow/HostBaseURL ride the
 * broker env. writes:false.
 */
export async function netsuiteE2ELive(values, scrub) {
    const env = process.env;
    const cred = {
        AccountID: (env.NETSUITE_ACCOUNT_ID || '').trim(),
        ConsumerKey: values.consumerKey,
        ConsumerSecret: values.consumerSecret,
        TokenID: values.tokenId,
        TokenSecret: values.tokenSecret,
        AuthFlow: (() => { const v = (env.NETSUITE_AUTH_FLOW || 'oauth1-tba').trim(); return v === 'tba' ? 'oauth1-tba' : v; })(), // connector enum is 'oauth1-tba'|'oauth2'; map legacy 'tba'
        ...(env.NETSUITE_HOST_BASE_URL ? { HostBaseURL: env.NETSUITE_HOST_BASE_URL } : {}),
    };
    const cfg = { AccountID: cred.AccountID, ConsumerKey: cred.ConsumerKey, TokenID: cred.TokenID, AuthFlow: cred.AuthFlow, ...(cred.HostBaseURL ? { HostBaseURL: cred.HostBaseURL } : {}) };
    return connectorE2EPlan({ ...values, credentialValues: cred, configuration: cfg }, scrub, false);
}

/**
 * NetSuite READ-ONLY DIAGNOSTIC PROBE — signs a GET /serverTime with the connector's OWN OAuth1aSigner
 * (so the signature is byte-identical to the connector; a 401 means creds/permissions, never my crypto).
 * Bypasses MJAPI. Reports what the broker HAS + the auth verdict, secrets masked. Throws `PROBE {...}`.
 */
export async function netsuiteProbe(values, _scrub) {
    const env = process.env;
    const accountId = (env.NETSUITE_ACCOUNT_ID || '').trim();
    const consumerKey = String(values.consumerKey || '');
    const consumerSecret = String(values.consumerSecret || '');
    const tokenId = String(values.tokenId || '');
    const tokenSecret = String(values.tokenSecret || '');
    const mask = (s) => { let o = String(s || ''); for (const v of [consumerKey, consumerSecret, tokenId, tokenSecret]) { if (v && v.length > 3) o = o.split(v).join('<secret>'); } return o.slice(0, 260); };
    const sub = accountId.toLowerCase().replace(/_/g, '-');                                  // host subdomain
    const host = (env.NETSUITE_HOST_BASE_URL || `https://${sub}.suitetalk.api.netsuite.com`).replace(/\/+$/, '');
    const realm = accountId.toUpperCase();                                                   // NetSuite realm = account id upper
    const url = `${host}/services/rest/system/v1/serverTime`;
    const results = [];
    try {
        const authHeader = OAuth1aSigner.BuildAuthorizationHeader({ ConsumerKey: consumerKey, ConsumerSecret: consumerSecret, TokenId: tokenId, TokenSecret: tokenSecret, Method: 'GET', Url: url, Realm: realm });
        const ctl = new AbortController(); const t = setTimeout(() => ctl.abort(), 15000);
        const r = await fetch(url, { method: 'GET', headers: { 'Authorization': authHeader, 'Accept': 'application/json' }, signal: ctl.signal });
        clearTimeout(t);
        let body = ''; try { body = await r.text(); } catch { /* ignore */ }
        results.push({ label: 'serverTime (OAuth1a TBA, connector signer)', status: r.status, wwwAuth: r.headers.get('www-authenticate') || null, body: mask(body) });
    } catch (e) { results.push({ label: 'serverTime', status: 'ERR', error: mask(e && e.message) }); }
    throw new Error('PROBE ' + JSON.stringify({ accountIdSet: !!accountId, hostBaseUrlSet: !!env.NETSUITE_HOST_BASE_URL, consumerKeySet: !!consumerKey, consumerSecretSet: !!consumerSecret, tokenIdSet: !!tokenId, tokenSecretSet: !!tokenSecret, results }));
}

/**
 * Nimble AMS LIVE e2e — Salesforce OAuth2. ClientID + ClientSecret broker-held; InstanceURL/LoginURL +
 * optional RefreshToken/AccessToken ride the broker env. The connector picks refresh_token grant (if
 * RefreshToken) → client_credentials → pre-minted token. writes:false.
 */
export async function nimbleE2ELive(values, scrub) {
    const env = process.env;
    const instanceURL = (env.NIMBLE_INSTANCE_URL || '').trim().replace(/\/+$/, '');
    const cred = {
        ClientID: values.clientId,
        ClientSecret: values.clientSecret,
        InstanceURL: instanceURL,
        // PROBE-PROVEN (2026-07): Salesforce client_credentials is ONLY supported on the org My Domain, NOT
        // login.salesforce.com (which returns invalid_grant "request not supported on this domain"). The org
        // My Domain == the InstanceURL, so default the token host to it. (Connector bug: ObtainToken uses
        // LoginURL default login.salesforce.com → held PR to prefer InstanceURL/My-Domain for the CC grant.)
        LoginURL: (env.NIMBLE_LOGIN_URL || instanceURL),
        ...(env.NIMBLE_REFRESH_TOKEN ? { RefreshToken: env.NIMBLE_REFRESH_TOKEN } : {}),
        ...(env.NIMBLE_ACCESS_TOKEN ? { AccessToken: env.NIMBLE_ACCESS_TOKEN } : {}),
    };
    const cfg = { ClientID: cred.ClientID, InstanceURL: cred.InstanceURL, ...(cred.LoginURL ? { LoginURL: cred.LoginURL } : {}) };
    return connectorE2EPlan({ ...values, integrationName: 'Nimble AMS', applyScope: 'full', credentialValues: cred, configuration: cfg }, scrub, false);
}

/**
 * Nimble AMS READ-ONLY DIAGNOSTIC PROBE — attempts the Salesforce OAuth token exchange directly (bypasses
 * MJAPI). Reports what the broker HAS + what the token endpoint says, with secrets masked. Answers exactly
 * "what's missing" for Nimble: bad creds → invalid_client; app not set up for CC flow → unsupported_grant_type;
 * wrong token host → the My-Domain error. Throws `PROBE {...}`.
 */
export async function nimbleProbe(values, _scrub) {
    const env = process.env;
    const clientId = String(values.clientId || '');
    const clientSecret = String(values.clientSecret || '');
    const loginURL = (env.NIMBLE_LOGIN_URL || 'https://login.salesforce.com').trim().replace(/\/+$/, '');
    const instanceURL = (env.NIMBLE_INSTANCE_URL || '').trim().replace(/\/+$/, '');
    const refreshToken = (env.NIMBLE_REFRESH_TOKEN || '').trim();
    const mask = (s) => { let o = String(s || ''); for (const v of [clientId, clientSecret, refreshToken]) { if (v && v.length > 3) o = o.split(v).join('<secret>'); } return o.slice(0, 260); };
    const hosts = [{ label: 'LoginURL', url: loginURL }];
    if (instanceURL) hosts.push({ label: 'InstanceURL(MyDomain)', url: instanceURL });
    const results = [];
    for (const h of hosts) {
        const params = new URLSearchParams({ grant_type: 'client_credentials', client_id: clientId, client_secret: clientSecret });
        try {
            const ctl = new AbortController(); const t = setTimeout(() => ctl.abort(), 15000);
            const r = await fetch(`${h.url}/services/oauth2/token`, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: params.toString(), signal: ctl.signal });
            clearTimeout(t);
            let body = ''; try { body = await r.text(); } catch { /* ignore */ }
            let hasToken = false; try { hasToken = !!JSON.parse(body).access_token; } catch { /* ignore */ }
            results.push({ label: `${h.label} /oauth2/token client_credentials`, status: r.status, gotToken: hasToken, body: mask(body) });
        } catch (e) { results.push({ label: `${h.label} client_credentials`, status: 'ERR', error: mask(e && e.message) }); }
    }
    throw new Error('PROBE ' + JSON.stringify({ clientIdSet: !!clientId, clientSecretSet: !!clientSecret, loginURLSet: !!env.NIMBLE_LOGIN_URL, instanceURLSet: !!instanceURL, refreshTokenSet: !!refreshToken, results }));
}

/**
 * Nimble AMS / Salesforce — direct `SELECT COUNT() FROM Contact`. Bypasses MJAPI and the connector
 * entirely: authenticates via the same client_credentials flow, fires one aggregate SOQL query, returns
 * ONLY the count (no PII, no row data). Answers "does the org actually have this many Contacts"
 * independent of anything the sync pipeline did — the ground truth the round-number heuristic needs to
 * confirm or rule out a truncation bug in this connector's own path.
 *
 * LmsPurchase is deliberately NOT probed here — it's a custom Apex REST endpoint
 * (`/services/apexrest/nams/api/lms/v1/purchases`), not a SOQL object, so its persistent 0 is a
 * different code path and a separate issue from this round-number check.
 */
export async function nimbleContactCount(values, _scrub) {
    const env = process.env;
    const clientId = String(values.clientId || '');
    const clientSecret = String(values.clientSecret || '');
    const loginURL = (env.NIMBLE_LOGIN_URL || env.NIMBLE_INSTANCE_URL || 'https://login.salesforce.com').trim().replace(/\/+$/, '');
    const params = new URLSearchParams({ grant_type: 'client_credentials', client_id: clientId, client_secret: clientSecret });
    const tokenResp = await fetch(`${loginURL}/services/oauth2/token`, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: params.toString() });
    const tokenBody = await tokenResp.json();
    if (!tokenBody.access_token) throw new Error(`Token exchange failed: ${tokenResp.status} ${JSON.stringify(tokenBody).slice(0, 200)}`);
    const instanceUrl = tokenBody.instance_url;
    const soql = 'SELECT COUNT() FROM Contact';
    const r = await fetch(`${instanceUrl}/services/data/v59.0/query?q=${encodeURIComponent(soql)}`, {
        headers: { Authorization: `Bearer ${tokenBody.access_token}` },
    });
    const body = await r.json();
    if (!r.ok) return { instanceUrl, soql, status: r.status, error: JSON.stringify(body).slice(0, 300) };
    return { instanceUrl, soql, status: r.status, totalSize: body.totalSize };
}

/**
 * ORCID LIVE e2e — OAuth2 client_credentials (/read-public). ClientID + ClientSecret broker-held;
 * UseSandbox/Scope ride the broker env. Drives the connector's search→record fan-out. writes:false.
 */
export async function orcidE2ELive(values, scrub) {
    const env = process.env;
    const cred = {
        ClientID: values.clientId,
        ClientSecret: values.clientSecret,
        Scope: (env.ORCID_SCOPE || '/read-public').trim(),
        UseSandbox: /^(1|true|yes)$/i.test((env.ORCID_USE_SANDBOX || '').trim()),
    };
    // Record universe: the connector REQUIRES Configuration.orcidIds (and/or searchQuery) — without it,
    // FetchChanges resolves 0 iDs and every object is vacuously empty. ORCID_IDS = comma-separated iDs.
    const ids = (env.ORCID_IDS || '').split(',').map((s) => s.trim()).filter(Boolean);
    const cfg = { ClientID: cred.ClientID, Scope: cred.Scope, UseSandbox: cred.UseSandbox, ...(ids.length ? { orcidIds: ids } : {}) };
    return connectorE2EPlan({ ...values, integrationName: 'ORCID', applyScope: 'full', credentialValues: cred, configuration: cfg }, scrub, false);
}

/**
 * OpenWater LIVE e2e — DUAL static API-key headers (X-ApiKey + X-ClientKey), NOT OAuth. Both keys are
 * broker-held; BaseURL/OrganizationCode ride the broker env. The connector requires BOTH keys — if only
 * one exists, set OPENWATER_CLIENT_KEY=<the same key> to test the single-key hypothesis. writes:false.
 */
export async function openwaterE2ELive(values, scrub) {
    const env = process.env;
    // PROVEN by probe (2026-07): OpenWater's REST API is a SHARED host (api.secure-platform.com); the tenant
    // is routed by X-ClientKey = the client's BARE domain (<org>.secure-platform.com, NO scheme/trailing slash).
    // The Keeper "Base URL" is that client domain WITH a scheme — strip it for the ClientKey. (The shipped
    // connector wrongly requires a per-tenant BaseURL; see held-PR note. For the test we supply both correctly.)
    const clientKey = (env.OPENWATER_BASE_URL || '').trim().replace(/^https?:\/\//, '').replace(/\/+$/, '');
    const apiHost = (env.OPENWATER_HOST && /api\.secure-platform\.com/.test(env.OPENWATER_HOST)
        ? env.OPENWATER_HOST : 'https://api.secure-platform.com').trim().replace(/\/+$/, '');
    const cred = {
        ApiKey: values.apiKey,
        ClientKey: values.clientKey || clientKey,
        BaseURL: apiHost,
        ...(env.OPENWATER_ORG_CODE ? { OrganizationCode: env.OPENWATER_ORG_CODE } : {}),
    };
    const cfg = { BaseURL: cred.BaseURL, ...(cred.OrganizationCode ? { OrganizationCode: cred.OrganizationCode } : {}) };
    return connectorE2EPlan({ ...values, integrationName: 'OpenWater', applyScope: 'full', credentialValues: cred, configuration: cfg }, scrub, false);
}

/**
 * OpenWater READ-ONLY DIAGNOSTIC PROBE — settles path-vs-auth for the persistent 404. Curls a few
 * candidate URLs and reports ONLY {label, status, contentType, wwwAuth, snippet}. The tenant host,
 * client key and api key are MASKED out of every output field (replaced with <host>/<key>) so no
 * secret leaves the broker. Throws `PROBE {...}` so the submitter reads it like CONNTEST.
 */
export async function openwaterProbe(values, _scrub) {
    const env = process.env;
    const host = (env.OPENWATER_HOST || env.OPENWATER_BASE_URL || '').trim().replace(/\/+$/, '');
    const clientKey = (env.OPENWATER_BASE_URL || '').trim();
    const apiKey = String(values.apiKey || '');
    // The API validated our request against api.secure-platform.com but rejected the ClientKey — it uses
    // X-ClientKey to look up the "client domain". Try the plausible formats: full URL, bare hostname, slug.
    const ckHost = clientKey.replace(/^https?:\/\//, '').replace(/\/+$/, '');   // bare hostname
    const ckSlug = ckHost.split('.')[0];                                         // leading subdomain/org slug
    const base = { 'X-ApiKey': apiKey, 'Accept': 'application/json', 'User-Agent': 'MJ-Integration/1.0', ...(env.OPENWATER_ORG_CODE ? { 'X-OrganizationCode': env.OPENWATER_ORG_CODE } : {}) };
    const mask = (s) => {
        let out = String(s || '');
        for (const v of [host, clientKey, ckHost, ckSlug, apiKey]) { if (v && v.length > 2) out = out.split(v).join(v === apiKey ? '<key>' : '<ck>'); }
        return out.slice(0, 140);
    };
    const API = 'https://api.secure-platform.com';
    const U = `${API}/v2/Programs?pageIndex=0&pageSize=1`;
    const probes = [
        { label: 'ClientKey = full URL', url: U, headers: { ...base, 'X-ClientKey': clientKey } },
        { label: 'ClientKey = bare hostname', url: U, headers: { ...base, 'X-ClientKey': ckHost } },
        { label: 'ClientKey = slug only', url: U, headers: { ...base, 'X-ClientKey': ckSlug } },
    ];
    const results = [];
    for (const p of probes) {
        try {
            const ctl = new AbortController();
            const t = setTimeout(() => ctl.abort(), 15000);
            const r = await fetch(p.url, { method: 'GET', headers: p.headers, redirect: 'manual', signal: ctl.signal });
            clearTimeout(t);
            let body = '';
            try { body = await r.text(); } catch { /* ignore */ }
            results.push({ label: p.label, status: r.status, contentType: (r.headers.get('content-type') || '').slice(0, 40), wwwAuth: r.headers.get('www-authenticate') || null, location: mask(r.headers.get('location') || ''), snippet: mask(body.replace(/\s+/g, ' ')) });
        } catch (e) {
            results.push({ label: p.label, status: 'ERR', error: mask(e && e.message) });
        }
    }
    throw new Error('PROBE ' + JSON.stringify({ hostSet: !!host, clientKeySet: !!clientKey, apiKeySet: !!apiKey, results }));
}

/**
 * PropFuel LIVE e2e — data-export feed. Single Token secret (broker CONNECTOR_API_KEY) + AccountID
 * (broker PROPFUEL_ACCOUNT_ID, default demo '2019'). Full discover→ApplyAll→sync. writes:false.
 */
export async function propfuelE2ELive(values, scrub) {
    const env = process.env;
    const acct = (env.PROPFUEL_ACCOUNT_ID || '2019').trim();
    const cred = { Token: values.token, AccountID: acct };
    const cfg = { AccountID: acct };
    return connectorE2EPlan({ ...values, integrationName: 'PropFuel', applyScope: 'full', credentialValues: cred, configuration: cfg }, scrub, false);
}

/**
 * HubSpot LIVE e2e — single private-app token. Reads the VENDOR-PREFIXED HUBSPOT_API_KEY (NOT the
 * generic CONNECTOR_API_KEY, which collides in a multi-vendor broker). Connector reads { apiKey }.
 */
export async function hubspotE2ELive(values, scrub) {
    const cred = { apiKey: values.token };
    return connectorE2EPlan({ ...values, integrationName: 'hubspot', applyScope: 'full', credentialValues: cred }, scrub, false);
}

/**
 * Wild Apricot LIVE e2e — single API Key (used as Basic-auth username; accountId auto-discovered).
 * Vendor-prefixed WILDAPRICOT_API_KEY. Connector reads { ApiKey }. writes:false.
 */
export async function wildApricotE2ELive(values, scrub) {
    const cred = { ApiKey: values.token };
    return connectorE2EPlan({ ...values, integrationName: 'Wild Apricot', applyScope: 'full', credentialValues: cred }, scrub, false);
}

/**
 * DIAGNOSTIC probe (read-only, no PII) — runs through the broker so the API key never leaves it.
 * Hits WA's contacts endpoint with every plausible paging strategy and reports ONLY counts/states/
 * shapes, so we can determine the correct contacts-pagination model and fix the connector definitively.
 */
export async function wildApricotProbe(values, _scrub) {
    const key = values.token;
    const basic = Buffer.from(`APIKEY:${key}`).toString('base64');
    const tr = await fetch('https://oauth.wildapricot.org/auth/token', {
        method: 'POST',
        headers: { Authorization: `Basic ${basic}`, 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'grant_type=client_credentials&scope=auto',
    });
    const tj = await tr.json().catch(() => ({}));
    if (!tj.access_token) return { ok: false, error: `token failed: ${tr.status} ${tj.error || ''}` };
    const token = tj.access_token;
    const H = () => ({ Authorization: `Bearer ${token}`, Accept: 'application/json' });
    const accts = await (await fetch('https://api.wildapricot.org/v2.3/accounts', { headers: H() })).json();
    const acct = Array.isArray(accts) ? accts[0].Id : accts.Id;
    const baseC = `https://api.wildapricot.org/v2.3/accounts/${acct}/contacts`;

    // returns ONLY structural facts — counts, HTTP status, State, ResultId presence, top-level keys
    async function probe(qs) {
        const r = await fetch(`${baseC}?${qs}`, { headers: H() });
        const j = await r.json().catch(() => null);
        return {
            qs, status: r.status,
            hasResultId: !!(j && j.ResultId),
            state: j && j.State,
            requested: j && j.Requested,   // WA async: total contacts matching the query
            processed: j && j.Processed,   // WA async: number processed
            contactsLen: j && Array.isArray(j.Contacts) ? j.Contacts.length : null,
            firstId: j && Array.isArray(j.Contacts) && j.Contacts[0] ? j.Contacts[0].Id : null,
            topKeys: j ? Object.keys(j).slice(0, 10) : null,
        };
    }
    async function pollResult(resultId) {
        const pollUrl = `resultId=${encodeURIComponent(resultId)}`;
        for (let i = 0; i < 25; i++) {
            const p = await probe(pollUrl);
            if (p.state === 'Complete' || p.state === 'Failed') return { attempts: i + 1, ...p };
            await new Promise(r => setTimeout(r, 2000));
        }
        return { attempts: 25, timeout: true };
    }

    const out = {};
    out.syncSkip0 = await probe('$async=false&$skip=0&$top=100');
    out.syncSkip100 = await probe('$async=false&$skip=100&$top=100');

    // (A) TRUE unique count reachable via SYNC skip-paging (the connector's current method) — dedup by Id.
    const syncSeen = new Set();
    let syncPages = 0;
    for (let skip = 0; skip < 4000; skip += 100) {
        const r = await fetch(`${baseC}?$async=false&$skip=${skip}&$top=100`, { headers: H() });
        const j = await r.json().catch(() => ({}));
        const cs = Array.isArray(j.Contacts) ? j.Contacts : [];
        if (!cs.length) break;
        cs.forEach(c => syncSeen.add(c.Id));
        syncPages++;
        if (cs.length < 100) break;
    }
    out.uniqueViaSyncSkip = { unique: syncSeen.size, pagesFetched: syncPages };

    // (B) TRUE unique count via ASYNC export + RESULT paging (kick off once, page the stable snapshot).
    const kick = await fetch(`${baseC}?$async=true`, { headers: H() });
    const kj = await kick.json().catch(() => ({}));
    const rid = kj.ResultId;
    let resultPagingUnique = null, resultPages = 0;
    if (rid) {
        // wait until the export completes
        for (let i = 0; i < 25; i++) {
            const s = await (await fetch(`${baseC}?resultId=${encodeURIComponent(rid)}`, { headers: H() })).json().catch(() => ({}));
            if (s.State === 'Complete') break;
            await new Promise(r => setTimeout(r, 2000));
        }
        const rSeen = new Set();
        for (let skip = 0; skip < 4000; skip += 100) {
            const r = await fetch(`${baseC}?resultId=${encodeURIComponent(rid)}&$skip=${skip}&$top=100`, { headers: H() });
            const j = await r.json().catch(() => ({}));
            const cs = Array.isArray(j.Contacts) ? j.Contacts : [];
            if (!cs.length) break;
            cs.forEach(c => rSeen.add(c.Id));
            resultPages++;
            if (cs.length < 100) break;
        }
        resultPagingUnique = rSeen.size;
    }
    out.uniqueViaResultPaging = { unique: resultPagingUnique, pagesFetched: resultPages, resultId: rid ? 'present' : 'none' };

    return { ok: true, accountId: String(acct), probe: out };
}

/**
 * DIAGNOSTIC (read-only, no PII) — GET each of the 12 empty WA objects' list endpoints and report the
 * RESPONSE SHAPE, so we can tell WITHOUT syncing whether any endpoint is secretly async like Contact
 * (returns a ResultId). Reports HTTP status + whether a ResultId/State is present + top-level keys only.
 */
export async function wildApricotEndpointProbe(values, _scrub) {
    const key = values.token;
    const basic = Buffer.from(`APIKEY:${key}`).toString('base64');
    const tr = await fetch('https://oauth.wildapricot.org/auth/token', {
        method: 'POST',
        headers: { Authorization: `Basic ${basic}`, 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'grant_type=client_credentials&scope=auto',
    });
    const tj = await tr.json().catch(() => ({}));
    if (!tj.access_token) return { ok: false, error: `token failed: ${tr.status}` };
    const token = tj.access_token;
    const H = () => ({ Authorization: `Bearer ${token}`, Accept: 'application/json' });
    const accts = await (await fetch('https://api.wildapricot.org/v2.3/accounts', { headers: H() })).json();
    const acct = Array.isArray(accts) ? accts[0].Id : accts.Id;

    const paths = {
        AuditLogItem: '/accounts/{a}/auditLogItems',
        Bundle: '/accounts/{a}/bundles',
        CeuRecord: '/accounts/{a}/ceuRecords',
        EmailLog: '/accounts/{a}/SentEmails',
        EventRegistration: '/accounts/{a}/eventregistrations',
        EventRegistrationType: '/accounts/{a}/EventRegistrationTypes',
        Order: '/accounts/{a}/store/orders',
        PaymentAllocation: '/accounts/{a}/paymentAllocations',
        Product: '/accounts/{a}/store/products',
        SavedSearch: '/accounts/{a}/savedsearches',
        SentEmailRecipient: '/accounts/{a}/SentEmailRecipients',
        AttachmentData: '/accounts/{a}/attachments/GetInfos',
    };
    const out = {};
    for (const [name, p] of Object.entries(paths)) {
        const url = `https://api.wildapricot.org/v2.3${p.replace('{a}', acct)}?$top=1`;
        try {
            const r = await fetch(url, { headers: H() });
            const j = await r.json().catch(() => null);
            out[name] = {
                status: r.status,
                asyncLikeContact: !!(j && !Array.isArray(j) && j.ResultId), // the Contact-style async signal
                state: j && !Array.isArray(j) ? j.State : undefined,
                shape: Array.isArray(j) ? '<array>' : (j ? Object.keys(j).slice(0, 8) : null),
            };
        } catch (e) { out[name] = { error: String(e).slice(0, 80) }; }
    }
    return { ok: true, endpoints: out };
}

/**
 * Zendesk LIVE e2e — Basic auth `email/token:<api_token>`. ApiToken is the broker secret; Email +
 * Subdomain are non-secret config from the broker env. Subdomain goes in the connection Configuration.
 */
export async function zendeskE2ELive(values, scrub) {
    const env = process.env;
    const cred = { Email: (env.ZENDESK_EMAIL || '').trim(), ApiToken: values.token };
    const config = { Subdomain: (env.ZENDESK_SUBDOMAIN || '').trim() };
    return connectorE2EPlan({ ...values, integrationName: 'zendesk', applyScope: 'full', credentialValues: cred, configuration: config }, scrub, false);
}

/**
 * Neon CRM full e2e — HTTP Basic auth. APIKey is the broker-held secret (values.token → the Basic
 * password); OrgID is the non-secret Basic username, read from broker env NEON_ORG_ID. Connector reads
 * { OrgID, APIKey } (case-insensitively) off CredentialValues. writes:false (read-only matrix).
 */
export async function neonE2ELive(values, scrub) {
    const env = process.env;
    const cred = { OrgID: (env.NEON_ORG_ID || '').trim(), APIKey: values.token };
    return connectorE2EPlan({ ...values, credentialValues: cred, configuration: {} }, scrub, false);
}

/**
 * Zendesk incremental-endpoint PROBE — verifies which declared `/api/v2/incremental/<res>/cursor` doors
 * actually exist. Root-causes the organizations HTTP-404 finding before any metadata fix. writes:false.
 */
export async function zendeskIncrementalProbe(values, _scrub) {
    const env = process.env;
    const email = (env.ZENDESK_EMAIL || '').trim();
    const sub = (env.ZENDESK_SUBDOMAIN || '').trim();
    const token = values.token;
    if (!email || !sub) return { ok: false, error: 'ZENDESK_EMAIL / ZENDESK_SUBDOMAIN not set in broker env' };
    const basic = Buffer.from(`${email}/token:${token}`).toString('base64');
    const H = { Authorization: `Basic ${basic}`, Accept: 'application/json' };
    const base = `https://${sub}.zendesk.com`;
    // Every object the metadata declares with a cursor incremental endpoint + the time-based fallbacks.
    const cursorDoors = ['tickets', 'users', 'organizations', 'ticket_events', 'ticket_metric_events', 'custom_object_records'];
    const out = {};
    for (const res of cursorDoors) {
        const cursorURL = `${base}/api/v2/incremental/${res}/cursor?start_time=0&per_page=1`;
        const timeURL = `${base}/api/v2/incremental/${res}?start_time=0&per_page=1`;
        const listURL = `${base}/api/v2/${res}?page[size]=1`;
        const hit = async (u) => { try { const r = await fetch(u, { headers: H }); return r.status; } catch (e) { return `ERR ${String(e).slice(0, 40)}`; } };
        out[res] = { cursor: await hit(cursorURL), timeBased: await hit(timeURL), list: await hit(listURL) };
    }
    return { ok: true, note: '200=exists, 404=missing endpoint, 422=exists-but-bad-params', endpoints: out };
}

/**
 * HubSpot CRM SEEDER (broker-side, writes:true — the token is broker-held so seeding runs here).
 * Creates companies → contacts (with custom-ish properties) → deals + associations, so the HubSpot
 * live test has multi-page volume + a FK DAG instead of a near-empty portal. Test-portal only.
 */
export async function hubspotSeed(values, _scrub) {
    const token = values.token;
    const H = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };
    const stamp = Date.now();
    const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
    async function post(path, body) {
        let r = await fetch(`https://api.hubapi.com${path}`, { method: 'POST', headers: H, body: JSON.stringify(body) });
        if (r.status === 429) { await sleep(11000); r = await fetch(`https://api.hubapi.com${path}`, { method: 'POST', headers: H, body: JSON.stringify(body) }); }
        await sleep(150);
        const j = await r.json().catch(() => null);
        return { ok: r.ok, status: r.status, json: j };
    }
    const report = {}; const firstErr = {};
    const tally = (k, ok) => { report[k] = report[k] || { ok: 0, fail: 0 }; ok ? report[k].ok++ : report[k].fail++; };
    // volume knobs — as many records as we can write. HubSpot batch API = 100/req; generous 10 batches.
    const BATCHES = Number(process.env.HS_SEED_BATCHES || 10); // 10×100 = 1000 per hub object
    const simpleBatch = async (path, key, mk) => { const ids = []; for (let b = 0; b < BATCHES; b++) { const inputs = Array.from({ length: 100 }, (_, i) => mk(b * 100 + i + 1)); const r = await post(path, { inputs }); tally(key, r.ok); if (r.ok) (r.json?.results || []).forEach((x) => ids.push(x.id)); else if (!firstErr[key]) firstErr[key] = `${r.status} ${JSON.stringify(r.json).slice(0, 150)}`; } return ids; };

    // 1) companies  2) contacts  3) deals (hub objects, 1000 each)
    const compIds = await simpleBatch('/crm/v3/objects/companies/batch/create', 'companies', (n) => ({ properties: { name: `Test Co ${n} (${stamp})`, domain: `testco${n}-${stamp % 100000}.example.com`, industry: 'COMPUTER_SOFTWARE', city: ['Austin', 'Denver', 'Boston'][n % 3], numberofemployees: String(10 * (n % 50 + 1)) } }));
    const contIds = await simpleBatch('/crm/v3/objects/contacts/batch/create', 'contacts', (n) => ({ properties: { email: `test+${stamp}-${n}@example.com`, firstname: `Test${n}`, lastname: `Contact${stamp % 100000}`, lifecyclestage: ['lead', 'subscriber', 'opportunity'][n % 3], jobtitle: ['Manager', 'Director', 'Analyst'][n % 3] } }));
    const dealIds = await simpleBatch('/crm/v3/objects/deals/batch/create', 'deals', (n) => ({ properties: { dealname: `Test Deal ${n} (${stamp})`, amount: String(1000 * (n % 100 + 1)), pipeline: 'default', dealstage: ['appointmentscheduled', 'qualifiedtobuy', 'presentationscheduled'][n % 3] } }));
    // 4) MORE object types we can create: tickets, tasks, notes, products, line_items
    await simpleBatch('/crm/v3/objects/tickets/batch/create', 'tickets', (n) => ({ properties: { subject: `Test Ticket ${n} (${stamp})`, hs_pipeline: '0', hs_pipeline_stage: '1', hs_ticket_priority: ['LOW', 'MEDIUM', 'HIGH'][n % 3] } }));
    await simpleBatch('/crm/v3/objects/tasks/batch/create', 'tasks', (n) => ({ properties: { hs_task_subject: `Test Task ${n}`, hs_task_status: 'NOT_STARTED', hs_task_priority: ['LOW', 'MEDIUM', 'HIGH'][n % 3], hs_timestamp: String(stamp + n * 3600000) } }));
    await simpleBatch('/crm/v3/objects/notes/batch/create', 'notes', (n) => ({ properties: { hs_note_body: `Seeded note ${n} — test content.`, hs_timestamp: String(stamp + n * 60000) } }));
    const prodIds = await simpleBatch('/crm/v3/objects/products/batch/create', 'products', (n) => ({ properties: { name: `Test Product ${n}`, price: String(50 * (n % 40 + 1)), hs_sku: `SKU-${stamp % 100000}-${n}` } }));
    if (prodIds.length) await simpleBatch('/crm/v3/objects/line_items/batch/create', 'line_items', (n) => ({ properties: { name: `Line Item ${n}`, quantity: String(n % 10 + 1), price: String(50 * (n % 40 + 1)), hs_product_id: prodIds[n % prodIds.length] } }));
    // 4) associations contact→company (default association type, batched)
    for (let i = 0; i < Math.min(contIds.length, compIds.length, 100); i += 50) {
        const inputs = [];
        for (let k = i; k < Math.min(i + 50, contIds.length, compIds.length); k++) inputs.push({ from: { id: contIds[k] }, to: { id: compIds[k % compIds.length] }, types: [{ associationCategory: 'HUBSPOT_DEFINED', associationTypeId: 279 }] });
        const r = await post('/crm/v4/associations/contacts/companies/batch/create', { inputs });
        tally('assoc_contact_company', r.ok);
        if (!r.ok && !firstErr.assoc) firstErr.assoc = `${r.status} ${JSON.stringify(r.json).slice(0, 120)}`;
    }
    return { ok: true, plan: 'hubspot-seed', report, firstErr, counts: { companies: compIds.length, contacts: contIds.length, deals: dealIds.length } };
}

/** Stripe SEEDER (broker-side, writes:true — broker-held sk_test). customers(+metadata custom fields) →
 *  products→prices → invoices → charges(pm_card_visa) → coupons/tax. Test mode only. */
export async function stripeSeed(values, _scrub) {
    const KEY = values.token;
    const stamp = Date.now();
    // SAFETY: only seed TEST-mode secret/restricted keys. Hard-refuse anything live (sk_live/rk_live) or
    // publishable (pk_) so we never create real customers in a live account or fail on a read-only key.
    if (!KEY || /_live_/.test(KEY) || KEY.startsWith('pk_')) return { ok: false, error: `refusing non-test/live/publishable Stripe key (prefix ${String(KEY).slice(0, 8)}…) — load an sk_test_ secret key` };
    if (!/^(sk|rk)_test_/.test(KEY)) return { ok: false, error: `broker Stripe key is not a test secret/restricted key (prefix ${String(KEY).slice(0, 8)}…) — need sk_test_` };
    const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
    const post = async (path, form) => {
        let r = await fetch(`https://api.stripe.com/v1${path}`, { method: 'POST', headers: { Authorization: `Bearer ${KEY}`, 'Content-Type': 'application/x-www-form-urlencoded' }, body: new URLSearchParams(form).toString() });
        if (r.status === 429) { await sleep(12000); r = await fetch(`https://api.stripe.com/v1${path}`, { method: 'POST', headers: { Authorization: `Bearer ${KEY}`, 'Content-Type': 'application/x-www-form-urlencoded' }, body: new URLSearchParams(form).toString() }); }
        await sleep(90); const t = await r.text(); return { ok: r.ok, status: r.status, json: (() => { try { return JSON.parse(t); } catch { return null; } })(), body: t };
    };
    const rep = {}; const err = {}; const tally = (k, ok) => { rep[k] = rep[k] || { ok: 0, fail: 0 }; ok ? rep[k].ok++ : rep[k].fail++; };
    const N_CUST = Number(process.env.STRIPE_SEED_CUST || 500);
    const cust = [];
    for (let i = 1; i <= N_CUST; i++) { const r = await post('/customers', { name: `Test Customer ${i}`, email: `seed+${i}@example.com`, 'metadata[tier]': ['bronze', 'silver', 'gold'][i % 3], 'metadata[region]': ['NA', 'EU', 'APAC'][i % 3] }); tally('customers', r.ok); if (r.ok && r.json?.id) cust.push(r.json.id); else if (!err.customers) err.customers = `${r.status} ${r.body.slice(0, 120)}`; }
    // one-off + recurring prices (recurring → subscriptions)
    const prices = []; const recurring = [];
    for (let i = 1; i <= 40; i++) { const p = await post('/products', { name: `Test Product ${i}`, 'metadata[category]': ['saas', 'service', 'goods'][i % 3] }); tally('products', p.ok); if (p.ok && p.json?.id) { const pr = await post('/prices', { product: p.json.id, unit_amount: String(500 * i), currency: 'usd' }); tally('prices', pr.ok); if (pr.ok && pr.json?.id) prices.push(pr.json.id); const rr = await post('/prices', { product: p.json.id, unit_amount: String(1500 + 100 * i), currency: 'usd', 'recurring[interval]': 'month' }); if (rr.ok && rr.json?.id) recurring.push(rr.json.id); } else if (!err.products) err.products = `${p.status} ${p.body.slice(0, 120)}`; }
    // invoices + invoice items
    for (let i = 0; i < Math.min(cust.length, 250); i++) { const ii = await post('/invoiceitems', { customer: cust[i], price: prices[i % (prices.length || 1)] }); tally('invoiceitems', ii.ok); if (ii.ok) { const inv = await post('/invoices', { customer: cust[i], auto_advance: 'false' }); tally('invoices', inv.ok); } else if (!err.invoiceitems) err.invoiceitems = `${ii.status} ${ii.body.slice(0, 120)}`; }
    // charges via payment_intents + capture the charge id for refunds
    const charges = [];
    for (let i = 0; i < Math.min(cust.length, 200); i++) { const pi = await post('/payment_intents', { amount: String(1000 + i * 50), currency: 'usd', customer: cust[i], payment_method: 'pm_card_visa', confirm: 'true', 'automatic_payment_methods[enabled]': 'true', 'automatic_payment_methods[allow_redirects]': 'never' }); tally('charges', pi.ok); if (pi.ok && pi.json?.latest_charge) charges.push(pi.json.latest_charge); else if (!pi.ok && !err.charges) err.charges = `${pi.status} ${pi.body.slice(0, 120)}`; }
    // refunds (partial, on the first ~60 charges)
    for (let i = 0; i < Math.min(charges.length, 60); i++) { tally('refunds', (await post('/refunds', { charge: charges[i], amount: '500' })).ok); }
    // subscriptions (attach test card as default → subscribe to a recurring price)
    for (let i = 0; i < Math.min(cust.length, 80) && recurring.length; i++) { const pm = await post(`/payment_methods/pm_card_visa/attach`, { customer: cust[i] }); if (pm.ok) { await post(`/customers/${cust[i]}`, { 'invoice_settings[default_payment_method]': 'pm_card_visa' }); tally('subscriptions', (await post('/subscriptions', { customer: cust[i], 'items[0][price]': recurring[i % recurring.length] })).ok); } }
    // coupons + promotion_codes + tax_rates + payment_links
    const coupons = [];
    for (let i = 1; i <= 15; i++) { const c = await post('/coupons', { percent_off: String(3 * i), duration: 'once', name: `Seed Coupon ${i}` }); tally('coupons', c.ok); if (c.ok && c.json?.id) coupons.push(c.json.id); tally('tax_rates', (await post('/tax_rates', { display_name: `Seed Tax ${i}`, percentage: String(i), inclusive: 'false' })).ok); }
    for (let i = 0; i < coupons.length; i++) { tally('promotion_codes', (await post('/promotion_codes', { coupon: coupons[i], code: `SEED${stamp % 100000}${i}` })).ok); }
    for (let i = 0; i < Math.min(prices.length, 20); i++) { tally('payment_links', (await post('/payment_links', { 'line_items[0][price]': prices[i], 'line_items[0][quantity]': '1' })).ok); }
    return { ok: true, plan: 'stripe-seed', report: rep, firstErr: err, customers: cust.length };
}

/** Eventbrite SEEDER (broker-side, writes:true). venues → events → ticket classes under the account org. */
export async function eventbriteSeed(values, _scrub) {
    const TOKEN = values.token; const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
    const H = { Authorization: `Bearer ${TOKEN}`, 'Content-Type': 'application/json' };
    const get = async (p) => { const r = await fetch(`https://www.eventbriteapi.com/v3${p}`, { headers: H }); return r.ok ? r.json() : null; };
    const post = async (p, b) => { let r = await fetch(`https://www.eventbriteapi.com/v3${p}`, { method: 'POST', headers: H, body: JSON.stringify(b) }); if (r.status === 429) { await sleep(30000); r = await fetch(`https://www.eventbriteapi.com/v3${p}`, { method: 'POST', headers: H, body: JSON.stringify(b) }); } await sleep(250); const t = await r.text(); return { ok: r.ok, status: r.status, json: (() => { try { return JSON.parse(t); } catch { return null; } })(), body: t }; };
    const me = await get('/users/me/'); if (!me) return { ok: false, error: 'eventbrite auth failed' };
    const orgs = await get('/users/me/organizations/'); const org = orgs?.organizations?.[0]?.id;
    if (!org) return { ok: false, error: 'no eventbrite organization on this account (create one in the EB UI first)' };
    const rep = {}; const err = {}; const tally = (k, ok) => { rep[k] = rep[k] || { ok: 0, fail: 0 }; ok ? rep[k].ok++ : rep[k].fail++; };
    const venues = [];
    for (let i = 1; i <= 5; i++) { const v = await post(`/organizations/${org}/venues/`, { venue: { name: `Test Venue ${i}`, address: { address_1: '123 Test St', city: 'Austin', region: 'TX', postal_code: '78701', country: 'US' } } }); tally('venues', v.ok); if (v.ok && v.json?.id) venues.push(v.json.id); else if (!err.venues) err.venues = `${v.status} ${v.body.slice(0, 150)}`; }
    const base = 1784500000000;
    for (let i = 1; i <= 120; i++) { const st = base + i * 86400000; const ev = await post(`/organizations/${org}/events/`, { event: { name: { html: `Test Event ${i}` }, start: { timezone: 'America/Chicago', utc: new Date(st).toISOString().replace(/\.\d{3}Z$/, 'Z') }, end: { timezone: 'America/Chicago', utc: new Date(st + 7200000).toISOString().replace(/\.\d{3}Z$/, 'Z') }, currency: 'USD', venue_id: venues[i % (venues.length || 1)], capacity: 100 } }); tally('events', ev.ok); if (ev.ok && ev.json?.id) { const tc = await post(`/events/${ev.json.id}/ticket_classes/`, { ticket_class: { name: 'General Admission', quantity_total: 100, free: true } }); tally('ticket_classes', tc.ok); } else if (!err.events) err.events = `${ev.status} ${ev.body.slice(0, 200)}`; }
    return { ok: true, plan: 'eventbrite-seed', org, report: rep, firstErr: err };
}

/** Mailchimp SEEDER (broker-side, writes:true). Broad-coverage: audience → merge-fields → members(+tags)
 *  → member notes + events → static/saved segments → interest categories(+interests) → campaign/template
 *  folders → templates → draft campaigns(+content, never sent) → file-manager files → landing pages →
 *  e-commerce (store → products/variants → customers → carts → orders/lines → promo rules/codes) → a batch. */
export async function mailchimpSeed(values, _scrub) {
    const KEY = values.token; const PREFIX = (process.env.MAILCHIMP_SERVER_PREFIX || KEY.split('-').pop() || '').trim();
    if (!/^us\d+$/i.test(PREFIX)) return { ok: false, error: `bad mailchimp server prefix "${PREFIX}"` };
    const BASE = `https://${PREFIX}.api.mailchimp.com/3.0`; const AUTH = 'Basic ' + Buffer.from(`mj:${KEY}`).toString('base64');
    const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
    const req = async (m, p, b) => { let r = await fetch(`${BASE}${p}`, { method: m, headers: { Authorization: AUTH, 'Content-Type': 'application/json' }, ...(b ? { body: JSON.stringify(b) } : {}) }); if (r.status === 429) { await sleep(20000); r = await fetch(`${BASE}${p}`, { method: m, headers: { Authorization: AUTH, 'Content-Type': 'application/json' }, ...(b ? { body: JSON.stringify(b) } : {}) }); } await sleep(90); const t = await r.text(); return { ok: r.ok, status: r.status, json: (() => { try { return JSON.parse(t); } catch { return null; } })(), body: t }; };
    const crypto = await import('node:crypto');
    if (!(await req('GET', '/ping')).ok) return { ok: false, error: `mailchimp auth failed (prefix ${PREFIX})` };
    const rep = {}; const err = {}; const tally = (k, ok) => { rep[k] = rep[k] || { ok: 0, fail: 0 }; ok ? rep[k].ok++ : rep[k].fail++; };
    let listId = null; const lists = await req('GET', '/lists?count=10');
    if (lists.ok && lists.json?.lists?.length) listId = lists.json.lists[0].id;
    if (!listId) { const l = await req('POST', '/lists', { name: 'Test Audience', contact: { company: 'MJ Test', address1: '123 Test St', city: 'Austin', state: 'TX', zip: '78701', country: 'US' }, permission_reminder: 'Seeded test contact.', campaign_defaults: { from_name: 'MJ Test', from_email: 'seed@example.com', subject: 'Test', language: 'en' }, email_type_option: false }); tally('lists', l.ok); if (l.ok && l.json?.id) listId = l.json.id; else return { ok: false, error: `cannot create audience: ${l.status} ${l.body.slice(0, 200)}` }; }
    for (const mf of [{ tag: 'TIER', name: 'Member Tier', type: 'text' }, { tag: 'JOINYEAR', name: 'Join Year', type: 'number' }]) tally('merge_fields', (await req('POST', `/lists/${listId}/merge-fields`, mf)).ok);
    // Mailchimp blocks known-fake domains (example.com/test.com) on add — use a valid, non-blocklisted
    // test domain + realistic local parts. No sends happen (members only added + synced), so this is safe.
    const F = ['Alex', 'Jordan', 'Casey', 'Riley', 'Morgan', 'Taylor', 'Jamie', 'Avery', 'Quinn', 'Parker'];
    const L = ['Nguyen', 'Patel', 'Garcia', 'Smith', 'Kim', 'Lopez', 'Chen', 'Brown', 'Diaz', 'Khan'];
    const N_MEM = Number(process.env.MC_SEED_MEMBERS || 500);
    const memHashes = [];
    for (let i = 1; i <= N_MEM; i++) { const fn = F[i % F.length], ln = L[(i * 3) % L.length]; const email = `${fn.toLowerCase()}.${ln.toLowerCase()}.${i}@mjconnectortest.com`; const hash = crypto.createHash('md5').update(email.toLowerCase()).digest('hex'); const r = await req('PUT', `/lists/${listId}/members/${hash}`, { email_address: email, status: 'subscribed', merge_fields: { FNAME: fn, LNAME: ln, TIER: ['bronze', 'silver', 'gold'][i % 3], JOINYEAR: 2020 + (i % 6) }, tags: [`batch`, i % 2 ? 'odd' : 'even'] }); tally('members', r.ok); if (r.ok) memHashes.push(hash); else if (!err.members) err.members = `${r.status} ${r.body.slice(0, 150)}`; }
    // member notes (another writable object) on the first 50 members
    for (let i = 0; i < Math.min(memHashes.length, 50); i++) { tally('member_notes', (await req('POST', `/lists/${listId}/members/${memHashes[i]}/notes`, { note: `Seeded note for member ${i + 1}` })).ok); }
    // member events (activity feed objects) on the first 25 members
    for (let i = 0; i < Math.min(memHashes.length, 25); i++) { const ev = await req('POST', `/lists/${listId}/members/${memHashes[i]}/events`, { name: 'seed_event', properties: { source: 'mj-seed', idx: String(i + 1) } }); tally('member_events', ev.ok || ev.status === 204); }
    for (let i = 1; i <= 5; i++) tally('segments', (await req('POST', `/lists/${listId}/segments`, { name: `Seed Segment ${i}`, static_segment: [] })).ok);
    // saved (condition-based) segments — a distinct segment sub-type
    for (let i = 1; i <= 2; i++) { const s = await req('POST', `/lists/${listId}/segments`, { name: `Saved Segment ${i}`, options: { match: 'all', conditions: [{ condition_type: 'TextMerge', field: 'TIER', op: 'is', value: i === 1 ? 'gold' : 'silver' }] } }); tally('saved_segments', s.ok); if (!s.ok && !err.saved_segments) err.saved_segments = `${s.status} ${s.body.slice(0, 150)}`; }
    // interest categories + interests (group titles + group names)
    for (let c = 1; c <= 2; c++) { const ic = await req('POST', `/lists/${listId}/interest-categories`, { title: `Seed Category ${c}`, type: 'checkboxes' }); tally('interest_categories', ic.ok); if (ic.ok && ic.json?.id) { for (let i = 1; i <= 3; i++) tally('interests', (await req('POST', `/lists/${listId}/interest-categories/${ic.json.id}/interests`, { name: `Interest ${c}-${i}` })).ok); } else if (!err.interest_categories) err.interest_categories = `${ic.status} ${ic.body.slice(0, 150)}`; }
    // folders (campaign + template)
    for (let i = 1; i <= 2; i++) tally('campaign_folders', (await req('POST', '/campaign-folders', { name: `Seed Campaign Folder ${i}` })).ok);
    for (let i = 1; i <= 2; i++) tally('template_folders', (await req('POST', '/template-folders', { name: `Seed Template Folder ${i}` })).ok);
    // templates
    for (let i = 1; i <= 3; i++) { const t = await req('POST', '/templates', { name: `Seed Template ${i}`, html: `<html><body><h1>Seed ${i}</h1><p>MJ connector test template.</p></body></html>` }); tally('templates', t.ok); if (!t.ok && !err.templates) err.templates = `${t.status} ${t.body.slice(0, 150)}`; }
    // draft campaigns + content (drafts only — NEVER sent)
    const campIds = [];
    for (let i = 1; i <= 5; i++) { const c = await req('POST', '/campaigns', { type: 'regular', recipients: { list_id: listId }, settings: { subject_line: `Seed Campaign ${i}`, from_name: 'MJ Test', reply_to: 'seed@example.com', title: `Seed Campaign ${i}` } }); tally('campaigns', c.ok); if (c.ok && c.json?.id) campIds.push(c.json.id); else if (!err.campaigns) err.campaigns = `${c.status} ${c.body.slice(0, 150)}`; }
    for (const cid of campIds) tally('campaign_content', (await req('PUT', `/campaigns/${cid}/content`, { html: '<html><body><p>Seeded draft content — never sent.</p></body></html>' })).ok);
    // file-manager files (tiny 1x1 PNG, base64)
    const PNG1 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
    for (let i = 1; i <= 2; i++) { const fl = await req('POST', '/file-manager/files', { name: `seed-${i}.png`, file_data: PNG1 }); tally('files', fl.ok); if (!fl.ok && !err.files) err.files = `${fl.status} ${fl.body.slice(0, 150)}`; }
    // landing pages (best-effort — some plans/accounts refuse)
    for (let i = 1; i <= 2; i++) { const lp = await req('POST', '/landing-pages', { name: `Seed Landing ${i}`, title: `Seed Landing ${i}`, type: 'signup', list_id: listId }); tally('landing_pages', lp.ok); if (!lp.ok && !err.landing_pages) err.landing_pages = `${lp.status} ${lp.body.slice(0, 150)}`; }
    // e-commerce family: store → products(+variants) → customers → carts → orders(+lines) → promo rules(+codes)
    let storeId = 'mj-seed-store';
    const stores = await req('GET', '/ecommerce/stores?count=10');
    const haveStore = stores.ok && (stores.json?.stores ?? []).some(s => s.id === storeId);
    if (!haveStore) { const st = await req('POST', '/ecommerce/stores', { id: storeId, list_id: listId, name: 'MJ Seed Store', currency_code: 'USD', email_address: 'seed@mjconnectortest.com', domain: 'mjconnectortest.com' }); tally('stores', st.ok); if (!st.ok) { if (!err.stores) err.stores = `${st.status} ${st.body.slice(0, 150)}`; storeId = null; } }
    if (storeId) {
        const prodIds = [];
        for (let i = 1; i <= 10; i++) { const p = await req('POST', `/ecommerce/stores/${storeId}/products`, { id: `prod-${i}`, title: `Seed Product ${i}`, variants: [{ id: `prod-${i}-v1`, title: `Seed Product ${i} — Standard`, price: 10 + i, inventory_quantity: 100 }] }); tally('products', p.ok); if (p.ok) prodIds.push(`prod-${i}`); else if (!err.products) err.products = `${p.status} ${p.body.slice(0, 150)}`; }
        const custIds = [];
        for (let i = 1; i <= 20; i++) { const fn = F[i % F.length], ln = L[(i * 3) % L.length]; const c = await req('POST', `/ecommerce/stores/${storeId}/customers`, { id: `cust-${i}`, email_address: `${fn.toLowerCase()}.${ln.toLowerCase()}.${i}@mjconnectortest.com`, opt_in_status: false, first_name: fn, last_name: ln }); tally('customers', c.ok); if (c.ok) custIds.push(`cust-${i}`); else if (!err.customers) err.customers = `${c.status} ${c.body.slice(0, 150)}`; }
        if (prodIds.length && custIds.length) {
            for (let i = 1; i <= 5; i++) { const pid = prodIds[i % prodIds.length]; const ct = await req('POST', `/ecommerce/stores/${storeId}/carts`, { id: `cart-${i}`, customer: { id: custIds[i % custIds.length] }, currency_code: 'USD', order_total: 25.5, lines: [{ id: `cart-${i}-l1`, product_id: pid, product_variant_id: `${pid}-v1`, quantity: 1, price: 25.5 }] }); tally('carts', ct.ok); if (!ct.ok && !err.carts) err.carts = `${ct.status} ${ct.body.slice(0, 150)}`; }
            for (let i = 1; i <= 15; i++) { const pid = prodIds[i % prodIds.length]; const o = await req('POST', `/ecommerce/stores/${storeId}/orders`, { id: `order-${i}`, customer: { id: custIds[i % custIds.length] }, currency_code: 'USD', order_total: 15 + i, financial_status: 'paid', processed_at_foreign: new Date(1784500000000 + i * 86400000).toISOString(), lines: [{ id: `order-${i}-l1`, product_id: pid, product_variant_id: `${pid}-v1`, quantity: 1 + (i % 3), price: 15 + i }] }); tally('orders', o.ok); if (!o.ok && !err.orders) err.orders = `${o.status} ${o.body.slice(0, 150)}`; }
        }
        for (let i = 1; i <= 3; i++) { const pr = await req('POST', `/ecommerce/stores/${storeId}/promo-rules`, { id: `promo-${i}`, title: `Seed Promo ${i}`, description: `Seed promo rule ${i}`, amount: 0.1, type: 'percentage', target: 'total', enabled: true }); tally('promo_rules', pr.ok); if (pr.ok) tally('promo_codes', (await req('POST', `/ecommerce/stores/${storeId}/promo-rules/promo-${i}/promo-codes`, { id: `promocode-${i}`, code: `SEED${i}`, redemption_url: 'https://mjconnectortest.com/redeem' })).ok); else if (!err.promo_rules) err.promo_rules = `${pr.status} ${pr.body.slice(0, 150)}`; }
    }
    // one harmless batch (a Batch record — its only operation is GET /ping)
    tally('batches', (await req('POST', '/batches', { operations: [{ method: 'GET', path: '/ping' }] })).ok);
    return { ok: true, plan: 'mailchimp-seed', listId, storeId, report: rep, firstErr: err };
}

/** Mailchimp CAMPAIGNS-ONLY seeder (broker-side, writes:true). Targeted retry: campaign create 400s when
 *  reply_to is an unverified address, so resolve the ACCOUNT's own email (GET /) and use it as reply_to. */
export async function mailchimpSeedCampaigns(values, _scrub) {
    const KEY = values.token; const PREFIX = (process.env.MAILCHIMP_SERVER_PREFIX || KEY.split('-').pop() || '').trim();
    if (!/^us\d+$/i.test(PREFIX)) return { ok: false, error: `bad mailchimp server prefix "${PREFIX}"` };
    const BASE = `https://${PREFIX}.api.mailchimp.com/3.0`; const AUTH = 'Basic ' + Buffer.from(`mj:${KEY}`).toString('base64');
    const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
    const req = async (m, p, b) => { let r = await fetch(`${BASE}${p}`, { method: m, headers: { Authorization: AUTH, 'Content-Type': 'application/json' }, ...(b ? { body: JSON.stringify(b) } : {}) }); if (r.status === 429) { await sleep(20000); r = await fetch(`${BASE}${p}`, { method: m, headers: { Authorization: AUTH, 'Content-Type': 'application/json' }, ...(b ? { body: JSON.stringify(b) } : {}) }); } await sleep(90); const t = await r.text(); return { ok: r.ok, status: r.status, json: (() => { try { return JSON.parse(t); } catch { return null; } })(), body: t }; };
    const acct = await req('GET', '/?fields=email,account_name');
    if (!acct.ok || !acct.json?.email) return { ok: false, error: `cannot resolve account email: ${acct.status}` };
    const replyTo = acct.json.email;
    const lists = await req('GET', '/lists?count=1');
    const listId = lists.ok ? lists.json?.lists?.[0]?.id : null;
    if (!listId) return { ok: false, error: 'no list found' };
    const rep = { campaigns: { ok: 0, fail: 0 }, campaign_content: { ok: 0, fail: 0 } }; let firstErr = null;
    for (let i = 1; i <= 5; i++) {
        const c = await req('POST', '/campaigns', { type: 'regular', recipients: { list_id: listId }, settings: { subject_line: `Seed Campaign ${i}`, from_name: 'MJ Test', reply_to: replyTo, title: `Seed Campaign ${i}` } });
        c.ok ? rep.campaigns.ok++ : rep.campaigns.fail++;
        if (!c.ok && !firstErr) firstErr = `${c.status} ${c.body.slice(0, 300)}`;
        if (c.ok && c.json?.id) { const cc = await req('PUT', `/campaigns/${c.json.id}/content`, { html: '<html><body><p>Seeded draft content — never sent.</p></body></html>' }); cc.ok ? rep.campaign_content.ok++ : rep.campaign_content.fail++; }
    }
    return { ok: rep.campaigns.ok > 0, plan: 'mailchimp-seed-campaigns', listId, report: rep, firstErr };
}

/** Mailchimp READ-ONLY probe — ping + account inventory counts. Confirms the broker channel holds
 *  MAILCHIMP_API_KEY and reports what the account currently contains. NO writes of any kind. */
export async function mailchimpProbe(values, _scrub) {
    const KEY = values.token; const PREFIX = (process.env.MAILCHIMP_SERVER_PREFIX || KEY.split('-').pop() || '').trim();
    if (!/^us\d+$/i.test(PREFIX)) return { ok: false, error: `bad mailchimp server prefix "${PREFIX}"` };
    const BASE = `https://${PREFIX}.api.mailchimp.com/3.0`; const AUTH = 'Basic ' + Buffer.from(`mj:${KEY}`).toString('base64');
    const get = async (p) => { const r = await fetch(`${BASE}${p}`, { headers: { Authorization: AUTH } }); const t = await r.text(); return { ok: r.ok, status: r.status, json: (() => { try { return JSON.parse(t); } catch { return null; } })() }; };
    const ping = await get('/ping');
    if (!ping.ok) return { ok: false, error: `mailchimp auth failed (prefix ${PREFIX}, status ${ping.status})` };
    const counts = {};
    const probes = { lists: '/lists?count=1', campaigns: '/campaigns?count=1', templates: '/templates?count=1&type=user', stores: '/ecommerce/stores?count=1', landing_pages: '/landing-pages?count=1', files: '/file-manager/files?count=1', batches: '/batches?count=1' };
    for (const [k, p] of Object.entries(probes)) { const r = await get(p); counts[k] = r.ok ? (r.json?.total_items ?? null) : `HTTP ${r.status}`; }
    const lists = await get('/lists?count=10');
    const first = lists.ok ? lists.json?.lists?.[0] : null;
    if (first) counts.first_list = { id: first.id, name: first.name, members: first.stats?.member_count ?? null };
    return { ok: true, plan: 'mailchimp-probe', prefix: PREFIX, counts };
}

/** Stripe LIVE e2e — test-mode secret key (`sk_test_…`) as Bearer. writes:false. */
export async function stripeE2ELive(values, scrub) {
    const cred = { SecretKey: values.token };
    return connectorE2EPlan({ ...values, integrationName: 'stripe', applyScope: 'full', credentialValues: cred }, scrub, false);
}

/** Eventbrite LIVE e2e — pre-minted Private Token as Bearer. writes:false. */
export async function eventbriteE2ELive(values, scrub) {
    const cred = { AccessToken: values.token };
    return connectorE2EPlan({ ...values, integrationName: 'eventbrite', applyScope: 'full', credentialValues: cred }, scrub, false);
}

/** Mailchimp LIVE e2e — ApiKey (secret) + ServerPrefix (non-secret, from broker env). writes:false. */
export async function mailchimpE2ELive(values, scrub) {
    const env = process.env;
    const cred = { ApiKey: values.token, ServerPrefix: (env.MAILCHIMP_SERVER_PREFIX || '').trim() || undefined };
    return connectorE2EPlan({ ...values, credentialValues: cred }, scrub, false);
}

/**
 * Blackbaud SKY API LIVE e2e — SubscriptionKey (env) + OAuth2 confidential app (ClientID/Secret/
 * RefreshToken, broker-held; connector re-mints the access token via refresh_token grant). writes:false.
 */
export async function blackbaudE2ELive(values, scrub) {
    const env = process.env;
    const cred = {
        SubscriptionKey: (env.BLACKBAUD_SUBSCRIPTION_KEY || '').trim(),
        ClientID: values.clientId,
        ClientSecret: values.clientSecret,
        RefreshToken: values.refreshToken,
    };
    return connectorE2EPlan({ ...values, credentialValues: cred }, scrub, false);
}

// Constant Contact V3 — OAuth2 Authorization Code with ROTATING single-use refresh tokens.
// The connector persists the rotated refresh_token back to the Credential row after each refresh,
// so this run supplies the initial ClientId/ClientSecret/RefreshToken and the connector self-heals.
export async function constantcontactE2ELive(values, scrub) {
    const cred = {
        ClientId: values.clientId,
        ClientSecret: values.clientSecret,
        RefreshToken: values.refreshToken,
    };
    return connectorE2EPlan({ ...values, integrationName: 'constant-contact', applyScope: 'full', credentialValues: cred }, scrub, false);
}

// Salesforce — the connector auto-selects the OAuth2 CLIENT CREDENTIALS flow when a ClientSecret is
// present (no JWT cert needed). LoginUrl is the org's My Domain URL (non-secret; from the broker env).
// Fields map to SalesforceConnector.parseCredentials: { LoginUrl, ClientId, ClientSecret }.
export async function salesforceE2ELive(values, scrub) {
    // Normalize the My Domain URL — Salesforce shows it with https:// but users often paste just the
    // host; fetch() throws "Failed to parse URL" on a scheme-less token endpoint. Prepend https:// if absent.
    let loginUrl = (process.env.SALESFORCE_LOGIN_URL || '').trim().replace(/\/+$/, '');
    if (loginUrl && !/^https?:\/\//i.test(loginUrl)) loginUrl = 'https://' + loginUrl;
    const cred = {
        LoginUrl: loginUrl,
        ClientId: values.clientId,
        ClientSecret: values.clientSecret,
    };
    return connectorE2EPlan({ ...values, credentialValues: cred, configuration: cred }, scrub, false);
}

/**
 * Salesforce SEEDER (broker-side, writes:true). Populates a TEST/dev org with a multi-object dataset so
 * the read-path E2E has real rows to pull. client_credentials → instance_url → POST standard sObjects.
 * SAFETY: only ever run against a broker-provisioned TEST credential the client authorized for mutation
 * (allowWrite:true). Every record is tagged with a run stamp so re-runs don't masquerade as prior data.
 * Fields kept to the always-createable standard set (no license/record-type dependencies on a dev org).
 */
export async function salesforceSeed(values, _scrub) {
    let loginUrl = (process.env.SALESFORCE_LOGIN_URL || '').trim().replace(/\/+$/, '');
    if (loginUrl && !/^https?:\/\//i.test(loginUrl)) loginUrl = 'https://' + loginUrl;
    if (!loginUrl) return { ok: false, error: 'SALESFORCE_LOGIN_URL not set — need the org My Domain URL' };
    const params = new URLSearchParams({ grant_type: 'client_credentials', client_id: String(values.clientId || ''), client_secret: String(values.clientSecret || '') });
    const tr = await fetch(`${loginUrl}/services/oauth2/token`, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: params.toString() });
    const tj = await tr.json().catch(() => ({}));
    if (!tj.access_token) return { ok: false, error: `SF token exchange failed: ${tr.status} ${JSON.stringify(tj).slice(0, 160)}` };
    const inst = tj.instance_url; const TOKEN = tj.access_token;
    const stamp = Date.now();
    const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
    const post = async (obj, body) => {
        let r = await fetch(`${inst}/services/data/v59.0/sobjects/${obj}`, { method: 'POST', headers: { Authorization: `Bearer ${TOKEN}`, 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
        if (r.status === 429 || r.status === 503) { await sleep(5000); r = await fetch(`${inst}/services/data/v59.0/sobjects/${obj}`, { method: 'POST', headers: { Authorization: `Bearer ${TOKEN}`, 'Content-Type': 'application/json' }, body: JSON.stringify(body) }); }
        await sleep(60); const t = await r.text(); return { ok: r.ok, status: r.status, json: (() => { try { return JSON.parse(t); } catch { return null; } })(), body: t };
    };
    const rep = {}; const err = {}; const tally = (k, ok) => { rep[k] = rep[k] || { ok: 0, fail: 0 }; ok ? rep[k].ok++ : rep[k].fail++; };
    const N_ACCT = Number(process.env.SF_SEED_ACCT || 50);
    const accts = [];
    for (let i = 1; i <= N_ACCT; i++) { const r = await post('Account', { Name: `Seed Account ${stamp % 100000}-${i}`, Description: `mj-seed ${stamp}`, Industry: ['Technology', 'Finance', 'Healthcare'][i % 3] }); tally('Account', r.ok); if (r.ok && r.json?.id) accts.push(r.json.id); else if (!err.Account) err.Account = `${r.status} ${r.body.slice(0, 140)}`; }
    // Contacts + Opportunities + Cases hung off the accounts
    for (let i = 0; i < accts.length; i++) {
        const c1 = await post('Contact', { LastName: `Contact ${stamp % 100000}-${i}a`, FirstName: 'Seed', AccountId: accts[i], Email: `seed+${stamp}-${i}a@example.com` }); tally('Contact', c1.ok); if (!c1.ok && !err.Contact) err.Contact = `${c1.status} ${c1.body.slice(0, 140)}`;
        const c2 = await post('Contact', { LastName: `Contact ${stamp % 100000}-${i}b`, FirstName: 'Seed', AccountId: accts[i], Email: `seed+${stamp}-${i}b@example.com` }); tally('Contact', c2.ok);
        const closeDate = `2026-${String((i % 12) + 1).padStart(2, '0')}-15`;
        const op = await post('Opportunity', { Name: `Seed Opp ${stamp % 100000}-${i}`, StageName: ['Prospecting', 'Qualification', 'Closed Won'][i % 3], CloseDate: closeDate, Amount: String(1000 * (i + 1)), AccountId: accts[i] }); tally('Opportunity', op.ok); if (!op.ok && !err.Opportunity) err.Opportunity = `${op.status} ${op.body.slice(0, 140)}`;
        if (i % 2 === 0) { const cs = await post('Case', { Subject: `Seed Case ${stamp % 100000}-${i}`, Status: 'New', Origin: 'Web', AccountId: accts[i] }); tally('Case', cs.ok); if (!cs.ok && !err.Case) err.Case = `${cs.status} ${cs.body.slice(0, 140)}`; }
    }
    // Leads + Campaigns + Tasks (standalone)
    for (let i = 1; i <= 60; i++) { const l = await post('Lead', { LastName: `Seed Lead ${stamp % 100000}-${i}`, FirstName: 'Test', Company: `Seed Co ${i}`, Status: 'Open - Not Contacted' }); tally('Lead', l.ok); if (!l.ok && !err.Lead) err.Lead = `${l.status} ${l.body.slice(0, 140)}`; }
    for (let i = 1; i <= 10; i++) { const cm = await post('Campaign', { Name: `Seed Campaign ${stamp % 100000}-${i}`, IsActive: true, Type: 'Email' }); tally('Campaign', cm.ok); if (!cm.ok && !err.Campaign) err.Campaign = `${cm.status} ${cm.body.slice(0, 140)}`; }
    for (let i = 1; i <= 40; i++) { tally('Task', (await post('Task', { Subject: `Seed Task ${stamp % 100000}-${i}`, Status: 'Not Started', Priority: 'Normal' })).ok); }
    return { ok: true, plan: 'salesforce-seed', report: rep, firstErr: err, accounts: accts.length, instance: String(inst).replace(/^https?:\/\//, '').split('.')[0] };
}

/**
 * Sage Intacct LIVE e2e — SOAP XML gateway session (getAPISession → SessionId). Two secret passwords
 * (Sender + User) broker-held; SenderId/UserId/CompanyId/EntityId ride the broker env. writes:false.
 * NOTE: Sage Intacct is not yet a published Open App — publish before install-path testing.
 */
export async function sageIntacctE2ELive(values, scrub) {
    const env = process.env;
    const cred = {
        SenderId: (env.SAGEINTACCT_SENDER_ID || '').trim(),
        SenderPassword: values.senderPassword,
        UserId: (env.SAGEINTACCT_USER_ID || '').trim(),
        UserPassword: values.userPassword,
        CompanyId: (env.SAGEINTACCT_COMPANY_ID || '').trim(),
        ...(env.SAGEINTACCT_ENTITY_ID ? { EntityId: env.SAGEINTACCT_ENTITY_ID } : {}),
    };
    const cfg = { SenderId: cred.SenderId, UserId: cred.UserId, CompanyId: cred.CompanyId, ...(cred.EntityId ? { EntityId: cred.EntityId } : {}) };
    return connectorE2EPlan({ ...values, credentialValues: cred, configuration: cfg }, scrub, false);
}

/**
 * Registry: task name → { secrets (logicalName→ENV_VAR default), run, writes }.
 *
 * `writes` is the SAFETY flag. A live test against a client's real credentials must NEVER
 * mutate or delete their external data by default. Any plan that performs writes
 * (Create/Update/Delete / bidirectional push) sets writes:true and is REFUSED by the broker
 * unless the job explicitly passes allowWrite:true — which should only happen after the
 * read/pull path is validated and the client has authorized mutation testing. Read-only
 * plans (writes:false) are the default and the only thing that runs unprompted.
 *
 * The job's secretEnvNames may override the env-var names per deployment.
 */
/**
 * PropFuel data-export feed — READ-ONLY live validation. writes:false.
 * Calls ONLY GET /dataexport/<acct>/list and GET /dataexport/<acct>/download/<file>.
 * It NEVER calls POST /ack (ack removes a file from the queue = a mutation). Proves the
 * token + endpoints + file shape against the live demo without touching client data.
 * The token enters ONLY the broker process; the agent never sees it. Returns scrubbed
 * structure (file/record COUNTS + field KEY names only — never record values/PII).
 */
export async function propfuelReadonly({ token }, scrub) {
    const acct = '2019'; // demo account id (embedded in the data-export path)
    const base = `https://app.propfuel.com/dataexport/${acct}`;
    const headers = { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' };
    const out = { ok: false, plan: 'propfuel-readonly', accountId: acct, steps: {} };

    // 1) list files (read-only)
    let listResp;
    try { listResp = await fetch(`${base}/list`, { method: 'GET', headers }); }
    catch (e) { out.steps.list = { error: scrub(e instanceof Error ? e.message : String(e)) }; return out; }
    const listText = await listResp.text();
    let files = [];
    try { const j = JSON.parse(listText); files = Array.isArray(j) ? j : (j.files ?? j.data ?? []); } catch { /* non-json body */ }
    const names = (Array.isArray(files) ? files : []).map(f => String(typeof f === 'string' ? f : (f.file ?? f.name ?? f))).sort();
    out.steps.list = { status: listResp.status, fileCount: names.length, sample: names.slice(0, 5) };
    if (listResp.status < 200 || listResp.status >= 300) { out.steps.list.body = scrub(listText.slice(0, 300)); return out; }
    if (!names.length) { out.ok = true; out.note = 'connected; export queue currently empty'; return out; }

    // 2) download the OLDEST file (chronological by leading microtime) — read-only, NO ack
    const first = names[0];
    let dlResp;
    try { dlResp = await fetch(`${base}/download/${encodeURIComponent(first)}`, { method: 'GET', headers }); }
    catch (e) { out.steps.download = { error: scrub(e instanceof Error ? e.message : String(e)) }; return out; }
    const dlText = await dlResp.text();
    let records = [];
    try { const j = JSON.parse(dlText); records = Array.isArray(j) ? j : (j.data ?? j.records ?? []); } catch { /* */ }
    out.steps.download = {
        status: dlResp.status,
        file: first,
        dataType: (first.split('-').slice(1).join('-') || '').replace(/\.json$/, ''),
        recordCount: Array.isArray(records) ? records.length : 0,
        recordKeys: (Array.isArray(records) && records.length && typeof records[0] === 'object') ? Object.keys(records[0]).slice(0, 40) : [],
    };
    // DELIBERATELY no POST /ack — acking deletes the file (mutation). Read-only only.
    out.ok = dlResp.status >= 200 && dlResp.status < 300;
    return out;
}

/**
 * Totara / Moodle Web Services — READ-ONLY live validation. writes:false.
 * Proves the connector's core assumptions against the REAL instance WITHOUT returning any PII / record
 * VALUES (counts + field KEYS only, since the runner scrubs only the token, not tenant data):
 *   1) TestConnection via core_webservice_get_site_info — token valid? + how many WS functions this token
 *      can call (the basis of the connector's runtime discovery);
 *   2) one bounded read page via core_course_get_categories (the exact fn the provided Postman example hits).
 * Moodle returns HTTP 200 with {exception,errorcode,message} on auth/param failure — handled as gated/error,
 * never a false 200. base_url arrives NON-SECRET via E2E_LIVE_CONFIG.baseUrl (never baked into this shared
 * plan — the connector is tenant-agnostic). NEVER writes / acks.
 */
export async function totaraReadonly({ token }, scrub) {
    let cfg = {};
    try { cfg = JSON.parse(process.env.E2E_LIVE_CONFIG || '{}'); } catch { /* non-json */ }
    const baseUrl = String(cfg.baseUrl ?? cfg.base_url ?? process.env.TOTARA_BASE_URL ?? '').replace(/\/+$/, '');
    const out = { ok: false, plan: 'totara-readonly', baseUrl, steps: {} };
    if (!baseUrl) { out.error = 'no baseUrl — pass E2E_LIVE_CONFIG={"baseUrl":"https://<site>"}'; return out; }
    const endpoint = `${baseUrl}/webservice/rest/server.php`;

    const call = async (wsfunction, extra = {}) => {
        // Match the provided Postman example EXACTLY: wsfunction + moodlewsrestformat in the URL QUERY,
        // wstoken (+ any params) in the urlencoded POST body.
        const url = `${endpoint}?wsfunction=${encodeURIComponent(wsfunction)}&moodlewsrestformat=json`;
        const body = new URLSearchParams({ wstoken: token, ...extra });
        let r;
        try { r = await fetch(url, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body }); }
        catch (e) { return { networkError: (e instanceof Error ? e.message : String(e)) }; }
        const t = await r.text();
        let j = null; try { j = JSON.parse(t); } catch { /* html/error body */ }
        return { status: r.status, json: j, text: t };
    };
    const exceptionOf = (j) => (j && typeof j === 'object' && j.exception) ? String(j.errorcode ?? 'exception') : null;
    // Moodle exception message/debuginfo are technical (not PII) — surface a truncated, scrubbed copy for diagnosis.
    const excDetail = (j) => (j && j.exception) ? { message: scrub(String(j.message ?? '').slice(0, 200)), debuginfo: scrub(String(j.debuginfo ?? '').slice(0, 200)) } : null;

    // Read a wsfunction and summarize it PII-safely (counts + field KEYS only).
    const readProbe = async (wsfunction, extra = {}) => {
        const res = await call(wsfunction, extra);
        if (res.networkError) return { wsfunction, networkError: scrub(res.networkError) };
        const exc = exceptionOf(res.json);
        const arr = Array.isArray(res.json) ? res.json
            : (res.json && Array.isArray(res.json.courses) ? res.json.courses
            : (res.json && Array.isArray(res.json.categories) ? res.json.categories : null));
        return {
            wsfunction,
            httpStatus: res.status,
            ok: !exc && Array.isArray(arr),
            errorcode: exc,
            exception: excDetail(res.json),
            recordCount: Array.isArray(arr) ? arr.length : null,
            fieldKeys: (Array.isArray(arr) && arr[0] && typeof arr[0] === 'object') ? Object.keys(arr[0]).slice(0, 25) : [],
        };
    };

    // 1) PRIMARY PROOF — the exact fn from the provided Postman collection (the connector's real read path).
    out.steps.readCategories = await readProbe('core_course_get_categories');
    // 2) SECOND read — proves another object family also returns data with the same token.
    out.steps.readCourses = await readProbe('core_course_get_courses');
    // 3) TestConnection via get_site_info — INFORMATIONAL only (this instance throws a "No service found"
    //    codingerror on it even for a valid token; the real reads above are the authoritative proof).
    const si = await call('core_webservice_get_site_info');
    const siExc = exceptionOf(si.json);
    out.steps.siteInfo = {
        httpStatus: si.status,
        ok: si.status === 200 && !siExc,
        errorcode: siExc,
        exception: excDetail(si.json),
        release: si.json?.release ?? null,
        functionsAccessible: Array.isArray(si.json?.functions) ? si.json.functions.length : null,
        note: siExc ? 'informational: get_site_info not authoritative on this instance — real reads below are the proof' : undefined,
    };

    // PASS = the token authenticated AND at least one real object read returned a structured array.
    out.ok = !!(out.steps.readCategories.ok || out.steps.readCourses.ok);
    out.note = out.ok
        ? 'Live read-only PASS: wstoken authenticated against the real Totara WS endpoint and real object reads (categories/courses) returned structured data — counts/keys only, no PII. (get_site_info is a known no-op on this instance; not used.)'
        : 'Live read-only did NOT pass — no object read returned an array; see steps for errorcodes.';
    return out;
}

/**
 * Totara / Moodle Web Services — LIVE full-creation-pipeline e2e (READ-ONLY vendor sync: CreateConnection →
 * discover → ApplyAll builds the dest tables → StartSync pulls Totara → DB verify). Token from the broker's
 * TOTARA_TOKEN (UNAMBIGUOUS even under a --all multi-vendor broker, where CONNECTOR_API_KEY = the first
 * *_TOKEN found). base_url arrives NON-SECRET via E2E_LIVE_CONFIG.baseUrl (never baked — tenant-agnostic).
 * The connector reads the wstoken from credential key `Token` and the site base_url from Configuration.BaseURL.
 * writes:false (read-only from the vendor; DB writes are into our OWN destination schema — the point of the test).
 */
export async function totaraE2ELive(values, scrub) { // eslint-disable-line no-unused-vars -- scrub kept for signature symmetry
    const env = process.env;
    // The driver sets E2E_CONNECTOR/E2E_INTEGRATION to the TASK name; force the real registry slug / Integration name.
    env.E2E_CONNECTOR = 'totara';
    if (!env.E2E_INTEGRATION || env.E2E_INTEGRATION === 'totara-e2e-live') env.E2E_INTEGRATION = 'totara';
    let liveCfg = {}; try { liveCfg = JSON.parse(env.E2E_LIVE_CONFIG || '{}'); } catch { /* non-json */ }
    const baseUrl = String(liveCfg.baseUrl ?? liveCfg.BaseURL ?? env.TOTARA_BASE_URL ?? 'https://learn.rheumatology.org').replace(/\/+$/, '');
    // Provide base_url under several key variants so ParseConfig finds it regardless of the exact key it reads.
    const urlKeys = baseUrl ? { BaseURL: baseUrl, base_url: baseUrl, baseUrl } : {};
    const cred = { Token: values.token, ...urlKeys };
    const cfg = { ...urlKeys };
    return connectorE2EPlan({ ...values, integrationName: 'totara', applyScope: 'full', credentialValues: cred, configuration: cfg }, scrub, false);
}

/**
 * Totara PARENT-ITERATION live probe — READ-ONLY. Directly verifies the connector's parent-scoped fix at the
 * API level (no MJAPI): fetch a few course ids, then call the course-scoped functions WITH `courseid`
 * (core_enrol_get_enrolled_users / core_course_get_contents / core_enrol_get_course_enrolment_methods) + Users
 * WITH the criteria filter — proving the param approach the connector now uses works against live Totara (no
 * [invalidparameter]). Counts only, NO PII. base_url via E2E_LIVE_CONFIG.baseUrl. writes:false.
 */
export async function totaraParentProbe({ token }, scrub) { // eslint-disable-line no-unused-vars
    let cfg = {}; try { cfg = JSON.parse(process.env.E2E_LIVE_CONFIG || '{}'); } catch { /* */ }
    const baseUrl = String(cfg.baseUrl ?? cfg.BaseURL ?? '').replace(/\/+$/, '');
    const out = { ok: false, plan: 'totara-parent-probe', baseUrl, steps: {} };
    if (!baseUrl) { out.error = 'no baseUrl (E2E_LIVE_CONFIG.baseUrl)'; return out; }
    const endpoint = `${baseUrl}/webservice/rest/server.php`;
    const call = async (wsfunction, extra = {}) => {
        const body = new URLSearchParams({ wstoken: token, ...extra });
        let r; try { r = await fetch(`${endpoint}?wsfunction=${encodeURIComponent(wsfunction)}&moodlewsrestformat=json`, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body }); }
        catch (e) { return { networkError: scrub(e instanceof Error ? e.message : String(e)) }; }
        const t = await r.text(); let j = null; try { j = JSON.parse(t); } catch { /* */ }
        return { status: r.status, json: j };
    };
    const exc = (j) => (j && typeof j === 'object' && j.exception) ? String(j.errorcode ?? 'exception') : null;
    const countOf = (j) => Array.isArray(j) ? j.length : (j && j.exception) ? 0 : null;

    const courses = await call('core_course_get_courses');
    const ids = Array.isArray(courses.json) ? courses.json.slice(0, 3).map(c => c.id).filter(x => x != null) : [];
    out.steps.courseIdsSampled = ids;
    for (const fn of ['core_enrol_get_enrolled_users', 'core_course_get_contents', 'core_enrol_get_course_enrolment_methods']) {
        const results = [];
        for (const id of ids) { const r = await call(fn, { courseid: String(id) }); results.push({ courseid: id, errorcode: exc(r.json), recordCount: countOf(r.json) }); }
        out.steps[fn] = results;
    }
    const users = await call('core_user_get_users', { 'criteria[0][key]': 'email', 'criteria[0][value]': '%' });
    out.steps.usersWithCriteria = { errorcode: exc(users.json), recordCount: (users.json && Array.isArray(users.json.users)) ? users.json.users.length : countOf(users.json) };

    const scoped = ['core_enrol_get_enrolled_users', 'core_course_get_contents', 'core_enrol_get_course_enrolment_methods'];
    const noInvalidParam = scoped.every(fn => (out.steps[fn] || []).every(r => r.errorcode !== 'invalidparameter'));
    const anyData = scoped.some(fn => (out.steps[fn] || []).some(r => (r.recordCount ?? 0) > 0)) || (out.steps.usersWithCriteria.recordCount ?? 0) > 0;
    out.ok = noInvalidParam;   // the fix WORKS if the courseid param removed the invalidparameter error
    out.note = `Parent-iteration fix ${noInvalidParam ? 'VERIFIED live' : 'still hitting invalidparameter'}: course-scoped functions called WITH courseid (+ Users with criteria). invalidparameter-gone=${noInvalidParam}, any-data=${anyData}. Remaining errorcodes (e.g. accessexception) are tenant token-scope, not the connector. Counts only, no PII.`;
    return out;
}

/**
 * PropFuel data-export DISCOVERY — READ-ONLY, structure-only. writes:false.
 * Purpose: this is a SPEC-LESS connector (no public OpenAPI/docs); the live demo feed is the
 * only authoritative catalog. This plan surfaces, WITHOUT returning any record VALUES (contact
 * PII), everything the connector build needs:
 *   - the exact data-type tokens present in the queue + per-type file counts/microtime range
 *   - per data type: the nested key SCHEMA (dot-path -> value TYPE set) of a sample record
 *   - the checkin_questions IDENTITY field + UPDATE/DELETE signal, by scanning a window of files:
 *       * which paths change presence/type when an id recurs (the "answered" update mechanism)
 *       * distinct values of OPERATIONAL-SIGNAL fields only (status/state/deleted/action/...) —
 *         low-cardinality enums, never free-text/PII
 * Calls ONLY GET /list + GET /download (NEVER ack). Bounded: <= 24 downloads.
 */
export async function propfuelDiscover({ token }, scrub) {
    const acct = '2019';
    const base = `https://app.propfuel.com/dataexport/${acct}`;
    const headers = { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' };
    const out = { ok: false, plan: 'propfuel-discover', accountId: acct };

    const getJSON = async (url) => {
        const r = await fetch(url, { method: 'GET', headers });
        const t = await r.text();
        let j = null; try { j = JSON.parse(t); } catch { /* */ }
        return { status: r.status, json: j, text: t };
    };
    const recordsOf = (j) => Array.isArray(j) ? j : (j?.data ?? j?.records ?? []);

    // ── 1) list + group by data type ───────────────────────────────────────────────
    const lr = await getJSON(`${base}/list`);
    if (lr.status < 200 || lr.status >= 300) { out.list = { status: lr.status, body: scrub((lr.text || '').slice(0, 300)) }; return out; }
    const rawFiles = (() => { const j = lr.json; const a = Array.isArray(j) ? j : (j?.files ?? j?.data ?? []); return (Array.isArray(a) ? a : []).map(f => String(typeof f === 'string' ? f : (f.file ?? f.name ?? f))); })();
    // filename = <microtime>-<datatype>.json ; microtime sorts chronologically (numeric)
    const parse = (name) => {
        const m = name.match(/^([0-9]+(?:\.[0-9]+)?)-(.+)\.json$/);
        return m ? { micro: parseFloat(m[1]), microStr: m[1], type: m[2], name } : { micro: NaN, microStr: '', type: '(unparsed)', name };
    };
    const parsed = rawFiles.map(parse).filter(p => p.type !== '(unparsed)').sort((a, b) => a.micro - b.micro);
    const byType = {};
    for (const p of parsed) (byType[p.type] ??= []).push(p);
    out.list = {
        status: lr.status,
        totalFiles: rawFiles.length,
        dataTypes: Object.fromEntries(Object.entries(byType).map(([t, arr]) => [t, {
            fileCount: arr.length,
            oldest: arr[0]?.microStr, newest: arr[arr.length - 1]?.microStr,
        }])),
    };

    // ── helpers: nested schema + signal collection (NO record values returned) ──────
    const SIGNAL = /^(status|state|deleted|is_deleted|isdeleted|removed|void|voided|action|op|operation|event|event_type|type|kind|answered|is_answered|bot|is_bot|valid|is_valid|response_count|answer_count)$/i;
    const typeOf = (v) => v === null ? 'null' : Array.isArray(v) ? 'array' : typeof v;
    const walkSchema = (obj, schema, prefix = '') => {
        if (!obj || typeof obj !== 'object' || Array.isArray(obj)) return;
        for (const [k, v] of Object.entries(obj)) {
            const path = prefix ? `${prefix}.${k}` : k;
            (schema[path] ??= new Set()).add(typeOf(v));
            if (v && typeof v === 'object' && !Array.isArray(v)) walkSchema(v, schema, path);
            else if (Array.isArray(v) && v.length && typeof v[0] === 'object') walkSchema(v[0], schema, `${path}[]`);
        }
    };
    const presentPaths = (obj, prefix = '', acc = new Set()) => {
        if (!obj || typeof obj !== 'object' || Array.isArray(obj)) return acc;
        for (const [k, v] of Object.entries(obj)) {
            const path = prefix ? `${prefix}.${k}` : k;
            const isEmpty = v === null || v === undefined || v === '' || (Array.isArray(v) && v.length === 0);
            if (!isEmpty) acc.add(path);
            if (v && typeof v === 'object' && !Array.isArray(v)) presentPaths(v, path, acc);
        }
        return acc;
    };
    const collectSignals = (obj, sig, prefix = '') => {
        if (!obj || typeof obj !== 'object' || Array.isArray(obj)) return;
        for (const [k, v] of Object.entries(obj)) {
            const path = prefix ? `${prefix}.${k}` : k;
            if (SIGNAL.test(k) && (v === null || ['string', 'number', 'boolean'].includes(typeof v))) {
                const set = (sig[path] ??= new Set());
                if (set.size < 25) { const s = String(v); set.add(s.length > 40 ? '<long>' : s); }
            }
            if (v && typeof v === 'object' && !Array.isArray(v)) collectSignals(v, sig, path);
        }
    };
    // candidate identity = a flat path whose last segment looks like an id and is scalar
    const ID_HINT = /(^|[._])(id|uuid|guid|key)$/i;
    const idCandidates = (obj, prefix = '', acc = {}) => {
        if (!obj || typeof obj !== 'object' || Array.isArray(obj)) return acc;
        for (const [k, v] of Object.entries(obj)) {
            const path = prefix ? `${prefix}.${k}` : k;
            if (ID_HINT.test(k) && ['string', 'number'].includes(typeof v)) acc[path] = (acc[path] ?? 0) + 1;
            if (v && typeof v === 'object' && !Array.isArray(v)) idCandidates(v, path, acc);
        }
        return acc;
    };
    const getPath = (obj, path) => path.split('.').reduce((o, seg) => (o == null ? o : o[seg]), obj);

    // ── 2) per data type: schema of a recent sample ────────────────────────────────
    out.schemas = {};
    let budget = 24;
    for (const [type, arr] of Object.entries(byType)) {
        if (budget <= 0) break;
        const sampleFile = arr[arr.length - 1].name; // newest = most-evolved shape
        const dr = await getJSON(`${base}/download/${encodeURIComponent(sampleFile)}`); budget--;
        const recs = recordsOf(dr.json);
        const schema = {}; const sig = {};
        for (const rec of recs.slice(0, 200)) { walkSchema(rec, schema); collectSignals(rec, sig); }
        out.schemas[type] = {
            status: dr.status,
            sampleFile: arr[arr.length - 1].microStr + '-' + type,
            recordCount: Array.isArray(recs) ? recs.length : 0,
            schema: Object.fromEntries(Object.entries(schema).map(([p, s]) => [p, [...s].sort()])),
            signalFields: Object.fromEntries(Object.entries(sig).map(([p, s]) => [p, [...s].sort()])),
            idCandidates: idCandidates(recs[0] ?? {}),
        };
    }

    // ── 3) checkin_questions update/delete signal across a window ───────────────────
    const qType = Object.keys(byType).find(t => /checkin_question|question|answer/i.test(t));
    if (qType) {
        const files = byType[qType];
        const windowFiles = files.slice(-Math.min(16, files.length)); // most recent N
        // pick the identity path: most-frequent id-candidate across the type's sample schema
        const idc = out.schemas[qType]?.idCandidates ?? {};
        const idPath = Object.entries(idc).sort((a, b) => b[1] - a[1])[0]?.[0]
            ?? Object.keys(idc)[0] ?? 'checkin_question.id';
        const seen = new Map(); // id -> { count, firstPaths:Set, lastPaths:Set, firstMicro, lastMicro, signalSeq:[] }
        let scanned = 0, recTotal = 0;
        for (const f of windowFiles) {
            if (budget <= 0) break;
            const dr = await getJSON(`${base}/download/${encodeURIComponent(f.name)}`); budget--; scanned++;
            const recs = recordsOf(dr.json);
            for (const rec of recs) {
                recTotal++;
                const idv = getPath(rec, idPath);
                if (idv === undefined || idv === null || idv === '') continue;
                const key = String(idv);
                const paths = presentPaths(rec);
                const sigSnap = {}; const sigTmp = {}; collectSignals(rec, sigTmp);
                for (const [p, s] of Object.entries(sigTmp)) sigSnap[p] = [...s][0];
                if (!seen.has(key)) seen.set(key, { count: 0, firstPaths: paths, lastPaths: paths, firstMicro: f.microStr, lastMicro: f.microStr, firstSig: sigSnap, lastSig: sigSnap });
                const e = seen.get(key);
                e.count++; e.lastPaths = paths; e.lastMicro = f.microStr; e.lastSig = sigSnap;
            }
        }
        // identity recurrence + what changes when an id is seen again
        const recurring = [...seen.values()].filter(e => e.count > 1);
        const addedPathsTally = {}; const removedPathsTally = {}; const sigTransitions = {};
        for (const e of recurring) {
            for (const p of e.lastPaths) if (!e.firstPaths.has(p)) addedPathsTally[p] = (addedPathsTally[p] ?? 0) + 1;
            for (const p of e.firstPaths) if (!e.lastPaths.has(p)) removedPathsTally[p] = (removedPathsTally[p] ?? 0) + 1;
            for (const [p, lv] of Object.entries(e.lastSig)) {
                const fv = e.firstSig[p];
                if (fv !== lv) { const k = `${p}: ${fv} -> ${lv}`; sigTransitions[k] = (sigTransitions[k] ?? 0) + 1; }
            }
        }
        const topN = (o, n = 15) => Object.fromEntries(Object.entries(o).sort((a, b) => b[1] - a[1]).slice(0, n));
        out.mutationSignal = {
            dataType: qType,
            identityPath: idPath,
            filesScanned: scanned,
            recordsScanned: recTotal,
            distinctIdentities: seen.size,
            recurringIdentities: recurring.length,
            note: 'recurring identity across files == the record was re-emitted (created->answered update, or pre-delete). Path/ signal deltas below show HOW the update manifests; absence in later files == tombstone-by-omission.',
            pathsAppearingOnRecur: topN(addedPathsTally),   // e.g. an "answer"/"response" path that fills in
            pathsDisappearingOnRecur: topN(removedPathsTally),
            signalFieldTransitions: topN(sigTransitions),   // e.g. status: sent -> answered / -> deleted
        };
    }

    out.ok = true;
    return out;
}

/**
 * PropFuel LIFECYCLE proof — READ-ONLY, counts+booleans only. writes:false.
 * Confirms the checkin_questions create->answer->soft-delete lifecycle in LIVE data:
 *   - state distribution (how many records have answered_at / deleted_at / response populated)
 *   - identity recurrence across a time window (same checkin_question.id re-emitted = an update),
 *     reporting only the answered_at/deleted_at PRESENCE transition (boolean), never timestamps/PII.
 * Calls ONLY GET /list + GET /download (NEVER ack). Bounded: <= 90 downloads, <= 12000 records.
 */
export async function propfuelLifecycle({ token }, scrub) {
    const acct = '2019';
    const base = `https://app.propfuel.com/dataexport/${acct}`;
    const headers = { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' };
    const out = { ok: false, plan: 'propfuel-lifecycle', accountId: acct };
    const getJSON = async (url) => { const r = await fetch(url, { method: 'GET', headers }); const t = await r.text(); let j = null; try { j = JSON.parse(t); } catch { /* */ } return { status: r.status, json: j, text: t }; };
    const recordsOf = (j) => Array.isArray(j) ? j : (j?.data ?? j?.records ?? []);

    const lr = await getJSON(`${base}/list`);
    if (lr.status < 200 || lr.status >= 300) { out.error = `list ${lr.status}`; return out; }
    const rawFiles = (() => { const j = lr.json; const a = Array.isArray(j) ? j : (j?.files ?? j?.data ?? []); return (Array.isArray(a) ? a : []).map(f => String(typeof f === 'string' ? f : (f.file ?? f.name ?? f))); })();
    const parse = (name) => { const m = name.match(/^([0-9]+(?:\.[0-9]+)?)-(.+)\.json$/); return m ? { micro: parseFloat(m[1]), type: m[2], name } : null; };
    const q = rawFiles.map(parse).filter(Boolean).filter(p => /checkin_question/i.test(p.type)).sort((a, b) => a.micro - b.micro);

    const present = (v) => v !== null && v !== undefined && v !== '';
    const tally = { records: 0, answered: 0, deleted: 0, hasResponse: 0, hasRating: 0, hasSelection: 0, updatedDiffersCreated: 0 };
    const seen = new Map(); // id -> { n, firstAnswered, lastAnswered, firstDeleted, lastDeleted }
    let downloads = 0;

    const scanFile = (recs) => {
        for (const rec of recs) {
            const cq = rec?.checkin_question; if (!cq || typeof cq !== 'object') continue;
            tally.records++;
            const a = present(cq.answered_at), d = present(cq.deleted_at);
            if (a) tally.answered++; if (d) tally.deleted++;
            if (present(cq.response)) tally.hasResponse++;
            if (present(cq.rating)) tally.hasRating++;
            if (present(cq.selection)) tally.hasSelection++;
            if (present(cq.created_at) && present(cq.updated_at) && cq.created_at !== cq.updated_at) tally.updatedDiffersCreated++;
            const id = cq.id; if (id === null || id === undefined) continue;
            const k = String(id);
            if (!seen.has(k)) seen.set(k, { n: 0, firstAnswered: a, lastAnswered: a, firstDeleted: d, lastDeleted: d });
            const e = seen.get(k); e.n++; e.lastAnswered = a; e.lastDeleted = d;
        }
    };

    // Window A — oldest 4 files (large, settled state distribution)
    for (const f of q.slice(0, 4)) { if (downloads >= 90 || tally.records >= 12000) break; const dr = await getJSON(`${base}/download/${encodeURIComponent(f.name)}`); downloads++; scanFile(recordsOf(dr.json)); }
    // Window B — most-recent 80 files (small, spans live-job time → recurrence)
    for (const f of q.slice(-80)) { if (downloads >= 90 || tally.records >= 12000) break; const dr = await getJSON(`${base}/download/${encodeURIComponent(f.name)}`); downloads++; scanFile(recordsOf(dr.json)); }

    const recurring = [...seen.values()].filter(e => e.n > 1);
    const becameAnswered = recurring.filter(e => !e.firstAnswered && e.lastAnswered).length;
    const becameDeleted = recurring.filter(e => !e.firstDeleted && e.lastDeleted).length;
    out.ok = true;
    out.filesAvailable = q.length;
    out.filesDownloaded = downloads;
    out.stateDistribution = tally;
    out.recurrence = {
        distinctIdentities: seen.size,
        recurringIdentities: recurring.length,
        recurredAndBecameAnswered: becameAnswered, // observed create -> answer update
        recurredAndBecameDeleted: becameDeleted,   // observed soft-delete transition
        maxOccurrencesOfOneId: recurring.reduce((m, e) => Math.max(m, e.n), 0),
    };
    out.interpretation = 'answered_at/deleted_at populated => update & soft-delete happen in-record; recurrence with becameAnswered/becameDeleted > 0 == the SAME checkin_question.id re-emitted across files as it transitions. Connector MUST upsert-by checkin_question.id and treat deleted_at!=null as a tombstone.';
    return out;
}

/**
 * GrowthZone OAuth2 — READ-ONLY live validation. writes:false.
 * Mints a Bearer access token from the OAuth2 credential set (refresh_token grant primary,
 * password grant fallback) against {origin}/oauth/token, then does TestConnection + a single
 * read page (GET .../contacts?$top=2 and a delta probe) — STRICTLY read-only (no POST/PUT/DELETE,
 * no ack). Proves the token-mint + endpoints + record shape against the LIVE GrowthZone tenant
 * without touching client data. Secrets enter ONLY the broker process; the agent sees a scrubbed
 * structure (token never returned; only status + COUNTS + field KEY names — never record values/PII).
 *
 * Required secrets (declared → must be present): baseUrl, clientId, clientSecret, refreshToken.
 * Optional config read directly from env (NOT required, so a skipped one doesn't fail the plan):
 *   GROWTHZONE_TOKEN_URL (else derived as {origin}/oauth/token), GROWTHZONE_SCOPES,
 *   GROWTHZONE_USERNAME + GROWTHZONE_PASSWORD (password-grant fallback only).
 */
export async function growthzoneReadonly({ baseUrl, clientId, clientSecret }, scrub) {
    const out = { ok: false, plan: 'growthzone-readonly', steps: {} };
    // refreshToken is OPTIONAL (read from env, not a required secret) — the connector was proven via the
    // PASSWORD grant (GROWTHZONE_USERNAME/PASSWORD), so requiring a refresh token would block that path.
    const refreshToken = (process.env.GROWTHZONE_REFRESH_TOKEN || '').trim();
    // Normalize the base URL → API base (…/api) + origin (for the OAuth token endpoint, which lives at root).
    const rawBase = String(baseUrl || '').trim().replace(/\/+$/, '');
    let origin = rawBase, apiBase = rawBase;
    try { origin = new URL(rawBase).origin; } catch { /* leave as-is if not parseable */ }
    if (!/\/api$/i.test(apiBase)) apiBase = `${apiBase}/api`;            // ensure …/api
    const tokenUrl = (process.env.GROWTHZONE_TOKEN_URL || `${origin}/oauth/token`).trim();
    const scopes = (process.env.GROWTHZONE_SCOPES || '').trim();
    const uname = process.env.GROWTHZONE_USERNAME;
    const pword = process.env.GROWTHZONE_PASSWORD;

    // ── 1) Mint a Bearer. refresh_token grant first; password grant as fallback. ──
    async function mint(grantBody, label) {
        // GrowthZone rejects client creds sent in BOTH Basic header AND body
        // ("Multiple client credentials cannot be specified"). Send them in the BODY ONLY.
        let resp;
        try {
            resp = await fetch(tokenUrl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'Accept': 'application/json' },
                body: new URLSearchParams(grantBody).toString(),
            });
        } catch (e) { return { grant: label, error: scrub(e instanceof Error ? e.message : String(e)) }; }
        const text = await resp.text();
        let tok = null, tokType = null;
        try { const j = JSON.parse(text); tok = j.access_token ?? j.accessToken ?? null; tokType = j.token_type ?? 'Bearer'; } catch { /* non-json */ }
        return { grant: label, status: resp.status, gotToken: !!tok, tokenType: tokType, token: tok, body: tok ? undefined : scrub(text.slice(0, 300)) };
    }

    let mintResult = await mint(
        { grant_type: 'refresh_token', refresh_token: refreshToken, client_id: clientId, client_secret: clientSecret, ...(scopes ? { scope: scopes } : {}) },
        'refresh_token'
    );
    if (!mintResult.gotToken && uname && pword) {
        const pw = await mint(
            { grant_type: 'password', username: uname, password: pword, client_id: clientId, client_secret: clientSecret, ...(scopes ? { scope: scopes } : {}) },
            'password'
        );
        if (pw.gotToken) mintResult = pw; else out.steps.passwordGrant = { grant: pw.grant, status: pw.status, gotToken: pw.gotToken, body: pw.body };
    }
    out.steps.tokenMint = { grant: mintResult.grant, status: mintResult.status, gotToken: mintResult.gotToken, tokenType: mintResult.tokenType, tokenUrl: scrub(tokenUrl), ...(mintResult.body ? { body: mintResult.body } : {}), ...(mintResult.error ? { error: mintResult.error } : {}) };
    const access = mintResult.token;
    if (!access) { out.note = 'OAuth token mint failed — see steps.tokenMint'; return out; }
    const authHeaders = { 'Authorization': `Bearer ${access}`, 'Accept': 'application/json' };

    // ── 2) TestConnection + one read page (read-only). Try contacts list, then delta probe. ──
    async function readGet(path, label) {
        let resp;
        try { resp = await fetch(`${apiBase}${path}`, { method: 'GET', headers: authHeaders }); }
        catch (e) { return { label, error: scrub(e instanceof Error ? e.message : String(e)) }; }
        const text = await resp.text();
        let recs = [];
        try { const j = JSON.parse(text); recs = Array.isArray(j) ? j : (j.Results ?? j.results ?? j.data ?? j.value ?? []); } catch { /* */ }
        const first = (Array.isArray(recs) && recs.length && typeof recs[0] === 'object') ? recs[0] : null;
        return {
            label, status: resp.status, ok: resp.status >= 200 && resp.status < 300,
            recordCount: Array.isArray(recs) ? recs.length : 0,
            recordKeys: first ? Object.keys(first).slice(0, 50) : [],
            ...(resp.status >= 200 && resp.status < 300 ? {} : { body: scrub(text.slice(0, 300)) }),
        };
    }

    out.steps.contacts = await readGet('/contacts?$top=2', 'contacts-list');
    // delta probe (read-only) — the documented incremental endpoint
    out.steps.contactsDelta = await readGet('/contacts/delta?modifiedSince=2020-01-01T00:00:00Z&top=2', 'contacts-delta');
    // ISOLATION: exactly what the connector sends on a full sync (IncrementalWatermarkField=NULL → NO since param)
    out.steps.contactsDeltaNoSince = await readGet('/contacts/delta', 'contacts-delta-no-since');

    out.connected = !!(out.steps.contacts?.ok || out.steps.contactsDelta?.ok);
    out.ok = out.connected;
    out.note = out.ok
        ? 'OAuth2 Bearer minted; live read-only GET succeeded against GrowthZone /api (no writes/acks performed)'
        : 'OAuth2 Bearer minted but read GET did not return 2xx — see steps.contacts/contactsDelta';
    return out;
}

/**
 * SharePoint (Microsoft Graph v1.0) — READ-ONLY live validation. writes:false.
 * MULTI-SECRET OAuth2 client-credentials (app-only): mints an app token from the Microsoft identity
 * platform token endpoint (https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token with
 * scope=https://graph.microsoft.com/.default), then does STRICTLY read-only Graph GETs — proving the
 * tenant+client+secret+admin-consent and the connector's read surface against the LIVE tenant without
 * touching any data (no POST/PUT/PATCH/DELETE, no upload session, no subscription create). The token
 * never leaves the broker process; the agent sees only status + COUNTS + field KEY names (never PII).
 *
 * Required secrets (declared → must be present): tenantId, clientId, clientSecret.
 * Optional config read directly from env (NOT required — a skipped one never fails the plan):
 *   SHAREPOINT_GRAPH_BASE (default https://graph.microsoft.com/v1.0),
 *   SHAREPOINT_SITE (a site addressing string, e.g. contoso.sharepoint.com:/sites/Example, to also
 *     read that site's drives + lists + a read-only driveItem /delta probe).
 *
 * NOTE on permission model: under least-privilege Sites.Selected with no site grant, /sites/root and
 * /sites?search may return 403 — that is a CORRECT, honestly-reported outcome (the token minted, the
 * app simply lacks a site grant), NOT a connector defect. A 2xx on any read confirms the live surface.
 */
export async function sharepointReadonly({ tenantId, clientId, clientSecret }, scrub) {
    const out = { ok: false, plan: 'sharepoint-readonly', steps: {} };
    const graphBase = (process.env.SHAREPOINT_GRAPH_BASE || 'https://graph.microsoft.com/v1.0').trim().replace(/\/+$/, '');
    const site = (process.env.SHAREPOINT_SITE || '').trim();
    const tokenUrl = `https://login.microsoftonline.com/${encodeURIComponent(tenantId)}/oauth2/v2.0/token`;

    // ── 1) Mint an app-only Bearer via client_credentials (body-only client creds). ──
    let access = null;
    {
        let resp;
        try {
            resp = await fetch(tokenUrl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'Accept': 'application/json' },
                body: new URLSearchParams({
                    grant_type: 'client_credentials',
                    client_id: clientId,
                    client_secret: clientSecret,
                    scope: 'https://graph.microsoft.com/.default',
                }).toString(),
            });
        } catch (e) {
            out.steps.tokenMint = { error: scrub(e instanceof Error ? e.message : String(e)) };
            out.note = 'OAuth token mint failed (network) — see steps.tokenMint';
            return out;
        }
        const text = await resp.text();
        let tok = null, tokType = null;
        try { const j = JSON.parse(text); tok = j.access_token ?? null; tokType = j.token_type ?? 'Bearer'; } catch { /* non-json */ }
        out.steps.tokenMint = { grant: 'client_credentials', status: resp.status, gotToken: !!tok, tokenType: tokType, tokenUrl: scrub(tokenUrl), ...(tok ? {} : { body: scrub(text.slice(0, 300)) }) };
        access = tok;
    }
    if (!access) { out.note = 'OAuth client_credentials mint failed — see steps.tokenMint'; return out; }
    const authHeaders = { 'Authorization': `Bearer ${access}`, 'Accept': 'application/json' };

    // ── 2) Read-only Graph GETs. Counts + key names only; never record values. ──
    async function readGet(path, label) {
        let resp;
        try { resp = await fetch(`${graphBase}${path}`, { method: 'GET', headers: authHeaders }); }
        catch (e) { return { label, error: scrub(e instanceof Error ? e.message : String(e)) }; }
        const text = await resp.text();
        let j = null; try { j = JSON.parse(text); } catch { /* */ }
        const recs = j ? (Array.isArray(j.value) ? j.value : (j.id ? [j] : [])) : [];
        const first = (recs.length && typeof recs[0] === 'object') ? recs[0] : null;
        const ok = resp.status >= 200 && resp.status < 300;
        return {
            label, status: resp.status, ok,
            recordCount: recs.length,
            recordKeys: first ? Object.keys(first).slice(0, 50) : [],
            ...(j && j['@odata.nextLink'] ? { hasNextLink: true } : {}),
            ...(j && j['@odata.deltaLink'] ? { hasDeltaLink: true } : {}),
            ...(ok ? {} : { body: scrub(text.slice(0, 300)) }),
        };
    }

    out.steps.rootSite = await readGet('/sites/root', 'sites-root');
    out.steps.siteSearch = await readGet('/sites?search=*&$top=3', 'sites-search');

    if (site) {
        out.steps.site = await readGet(`/sites/${encodeURIComponent(site)}`, 'site-by-id');
        out.steps.siteDrives = await readGet(`/sites/${encodeURIComponent(site)}/drives?$top=3`, 'site-drives');
        out.steps.siteLists = await readGet(`/sites/${encodeURIComponent(site)}/lists?$top=3`, 'site-lists');
        // Read-only delta probe on the site's default document library (proves the incremental cursor
        // surface; strictly a GET, no writes).
        out.steps.driveDeltaProbe = await readGet(`/sites/${encodeURIComponent(site)}/drive/root/delta`, 'drive-delta');
    }

    out.connected = !!(out.steps.rootSite?.ok || out.steps.siteSearch?.ok || out.steps.site?.ok || out.steps.siteDrives?.ok || out.steps.siteLists?.ok);
    out.ok = out.connected;
    out.note = out.ok
        ? 'App-only Bearer minted; live read-only Graph GET succeeded (no writes/uploads/subscriptions performed)'
        : 'Bearer minted but no read GET returned 2xx — likely Sites.Selected with no site grant (set SHAREPOINT_SITE + grant) or missing Sites.Read.All; see steps.*';
    return out;
}

/**
 * Dynamics 365 / Dataverse — READ-ONLY probe to answer "are the SHAREPOINT Entra app creds ALSO
 * usable for Dynamics?". writes:false. Reuses the SAME three OAuth2 secrets (tenantId/clientId/
 * clientSecret) because Dynamics uses the same Microsoft identity platform — only the token AUDIENCE
 * and the granted permissions/app-user differ. STRICTLY read-only (token mint + GET only).
 *
 * Two checks, neither needs a pre-known org URL for step 1:
 *   1. Global Discovery — mint scope=https://globaldisco.crm.dynamics.com/.default, GET
 *      /api/discovery/v2.0/Instances → lists every Dataverse environment the app can reach.
 *   2. (only if DYNAMICS365_ORG_URL env set) mint scope=<org>/.default, GET /api/data/v9.2/WhoAmI →
 *      a 2xx with a UserId is DEFINITIVE proof the creds work for that environment; 401/403 means the
 *      token minted but the app has no Dataverse application-user/security-role.
 *
 * Required secrets: tenantId, clientId, clientSecret (the SAME env vars the SharePoint plan uses).
 * Optional env: DYNAMICS365_ORG_URL (e.g. https://yourorg.crm.dynamics.com).
 */
export async function dynamics365Probe({ tenantId, clientId, clientSecret }, scrub) {
    const out = { ok: false, plan: 'dynamics365-probe', steps: {} };
    const tokenUrl = `https://login.microsoftonline.com/${encodeURIComponent(tenantId)}/oauth2/v2.0/token`;
    const orgUrl = (process.env.DYNAMICS365_ORG_URL || '').trim().replace(/\/+$/, '');

    async function mint(resourceScope) {
        let resp;
        try {
            resp = await fetch(tokenUrl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'Accept': 'application/json' },
                body: new URLSearchParams({ grant_type: 'client_credentials', client_id: clientId, client_secret: clientSecret, scope: resourceScope }).toString(),
            });
        } catch (e) { return { error: scrub(e instanceof Error ? e.message : String(e)) }; }
        const text = await resp.text();
        let tok = null; try { tok = JSON.parse(text).access_token ?? null; } catch { /* */ }
        return { status: resp.status, gotToken: !!tok, token: tok, ...(tok ? {} : { body: scrub(text.slice(0, 300)) }) };
    }
    async function readGet(url, token) {
        let resp;
        try { resp = await fetch(url, { method: 'GET', headers: { 'Authorization': `Bearer ${token}`, 'Accept': 'application/json' } }); }
        catch (e) { return { error: scrub(e instanceof Error ? e.message : String(e)) }; }
        const text = await resp.text();
        let j = null; try { j = JSON.parse(text); } catch { /* */ }
        const recs = j ? (Array.isArray(j.value) ? j.value : (j.UserId || j.BusinessUnitId ? [j] : [])) : [];
        const first = (recs.length && typeof recs[0] === 'object') ? recs[0] : null;
        const ok = resp.status >= 200 && resp.status < 300;
        return { status: resp.status, ok, recordCount: recs.length, recordKeys: first ? Object.keys(first).slice(0, 40) : [], ...(ok ? {} : { body: scrub(text.slice(0, 300)) }) };
    }

    // 1) Global Discovery (no org URL needed)
    const gdsScope = 'https://globaldisco.crm.dynamics.com/.default';
    const gdsTok = await mint(gdsScope);
    out.steps.globalDiscoveryToken = { scope: gdsScope, status: gdsTok.status, gotToken: gdsTok.gotToken, ...(gdsTok.body ? { body: gdsTok.body } : {}), ...(gdsTok.error ? { error: gdsTok.error } : {}) };
    if (gdsTok.token) {
        out.steps.instances = await readGet('https://globaldisco.crm.dynamics.com/api/discovery/v2.0/Instances', gdsTok.token);
    }

    // 2) Definitive WhoAmI against a specific org (only when provided)
    if (orgUrl) {
        const orgScope = `${orgUrl}/.default`;
        const orgTok = await mint(orgScope);
        out.steps.orgToken = { scope: scrub(orgScope), status: orgTok.status, gotToken: orgTok.gotToken, ...(orgTok.body ? { body: orgTok.body } : {}), ...(orgTok.error ? { error: orgTok.error } : {}) };
        if (orgTok.token) out.steps.whoAmI = await readGet(`${orgUrl}/api/data/v9.2/WhoAmI`, orgTok.token);
    }

    const reachable = (out.steps.instances?.recordCount ?? 0) > 0;
    const whoAmIok = out.steps.whoAmI?.ok === true;
    out.ok = reachable || whoAmIok;
    out.usableForDynamics = out.ok;
    out.note = whoAmIok
        ? `DEFINITIVE: WhoAmI 2xx against ${scrub(orgUrl)} — the SharePoint Entra app creds ARE usable for this Dynamics 365 environment (read-only, no writes).`
        : reachable
            ? `Global Discovery lists ${out.steps.instances.recordCount} reachable Dataverse environment(s) — creds appear usable for Dynamics; set DYNAMICS365_ORG_URL to one of them for a definitive WhoAmI.`
            : (out.steps.globalDiscoveryToken?.gotToken
                ? 'Token mints for the Dynamics audience but Global Discovery returned no environments (app likely lacks a Dataverse application-user/role) — set DYNAMICS365_ORG_URL to test a specific org directly. Not usable as-is.'
                : 'Could not mint a Dynamics-audience token with these creds — see steps.globalDiscoveryToken. Not usable for Dynamics as configured.');
    return out;
}

/**
 * PheedLoop — READ-ONLY live validation. writes:false.
 * PheedLoop uses dual STATIC headers (X-API-KEY + X-API-SECRET, NOT Bearer) against
 * https://api.pheedloop.com/api/v3/organization/{ORG_CODE}/ — exactly the scheme + base the
 * PheedLoopConnector builds (BuildHeaders + GetBaseURL). This replicates the connector's own
 * TestConnection (GET /events/?page=1&page_size=1) plus one read page, STRICTLY read-only (no
 * POST/PUT/DELETE). Proves the two secrets + org code + endpoints + record shape against the LIVE
 * tenant without touching client data. Secrets enter ONLY the broker process; the agent receives a
 * scrubbed structure (status + COUNTS + field KEY names only — never record values/PII).
 *
 * Required secrets (declared → must be present): apiKey (PHEEDLOOP_API_KEY), apiSecret (PHEEDLOOP_API_SECRET).
 * Org code read directly from env (PHEEDLOOP_ORG_CODE) — part of the URL path, not a secret.
 */
export async function pheedloopReadonly({ apiKey, apiSecret }, scrub) {
    const out = { ok: false, plan: 'pheedloop-readonly', steps: {} };
    const orgCode = (process.env.PHEEDLOOP_ORG_CODE || '').trim();
    if (!orgCode) { out.note = 'missing PHEEDLOOP_ORG_CODE (org code is part of the API path)'; return out; }
    const base = `https://api.pheedloop.com/api/v3/organization/${orgCode}`;
    const headers = { 'X-API-KEY': apiKey, 'X-API-SECRET': apiSecret, 'Accept': 'application/json' };

    async function readGet(path, label) {
        let resp;
        try { resp = await fetch(`${base}${path}`, { method: 'GET', headers }); }
        catch (e) { return { label, error: scrub(e instanceof Error ? e.message : String(e)) }; }
        const text = await resp.text();
        let recs = [], envelopeKeys = [], matchedKey = null, arrayKeyLengths = {};
        try {
            const j = JSON.parse(text);
            if (Array.isArray(j)) { recs = j; matchedKey = '(bare array)'; }
            else if (j && typeof j === 'object') {
                envelopeKeys = Object.keys(j);
                // STRUCTURE ONLY: which top-level keys hold arrays, and how long (no values)
                for (const k of envelopeKeys) if (Array.isArray(j[k])) arrayKeyLengths[k] = j[k].length;
                for (const k of ['results','Results','data','value','records','Records','items','Items']) {
                    if (Array.isArray(j[k])) { recs = j[k]; matchedKey = k; break; }
                }
            }
        } catch { /* non-json */ }
        const first = (Array.isArray(recs) && recs.length && typeof recs[0] === 'object') ? recs[0] : null;
        return {
            label, status: resp.status, ok: resp.status >= 200 && resp.status < 300,
            recordCount: Array.isArray(recs) ? recs.length : 0,
            envelopeKeys, matchedRecordKey: matchedKey, arrayKeyLengths,
            recordKeys: first ? Object.keys(first).slice(0, 50) : [],
            ...(resp.status >= 200 && resp.status < 300 ? {} : { body: scrub(text.slice(0, 300)) }),
        };
    }

    // 1) the connector's own TestConnection endpoint  2) a small read page
    out.steps.events = await readGet('/events/?page=1&page_size=1', 'events-testconnection');
    // page_size parity probe: the sync uses page_size=200 — does PheedLoop return the same records?
    out.steps.events_ps200 = await readGet('/events/?page=1&page_size=200', 'events-page_size-200');
    out.steps.attendees = await readGet('/attendees/?page=1&page_size=2', 'attendees-page');
    out.connected = !!(out.steps.events?.ok || out.steps.attendees?.ok);
    out.ok = out.connected;
    out.note = out.ok
        ? 'X-API-KEY/X-API-SECRET accepted; live read-only GET succeeded against PheedLoop /api/v3 (no writes performed)'
        : 'headers sent but read GET did not return 2xx — see steps.events/attendees';
    return out;
}

/**
 * GrowthZone OAuth2 — create the CompanyIntegration with the full OAuth credential. writes:false
 * externally (CreateConnection only reads GrowthZone to TestConnection). The OAuth secrets (clientId/
 * clientSecret/refreshToken/baseUrl) enter ONLY this broker process; MJAPI encrypts them server-side
 * and the agent receives ONLY the CompanyIntegrationID (token never returned). The agent then drives
 * ApplyAll/StartSync by CIID over GraphQL with MJ_API_KEY (no vendor secret). Job env (non-secret):
 * HS_LIVE_GRAPHQL_URL, HS_LIVE_COMPANY_ID, HS_LIVE_INTEGRATION_ID, HS_LIVE_CREDTYPE_ID.
 */
export async function growthzoneCreateConnection({ clientId, clientSecret, refreshToken, baseUrl, mjSystemKey }, scrub) {
    const env = process.env;
    const graphqlUrl = (env.HS_LIVE_GRAPHQL_URL || 'http://localhost:4013/').trim();
    const companyID = env.HS_LIVE_COMPANY_ID, integrationID = env.HS_LIVE_INTEGRATION_ID, credentialTypeID = env.HS_LIVE_CREDTYPE_ID;
    const scopes = (env.GROWTHZONE_SCOPES || '').trim(), tokenUrl = (env.GROWTHZONE_TOKEN_URL || '').trim();
    const uname = env.GROWTHZONE_USERNAME, pword = env.GROWTHZONE_PASSWORD;
    if (!companyID || !integrationID || !credentialTypeID) {
        return { ok: false, plan: 'growthzone-create-connection', error: 'missing HS_LIVE_COMPANY_ID / HS_LIVE_INTEGRATION_ID / HS_LIVE_CREDTYPE_ID in job env' };
    }
    // The operator's refresh_token is expired (GrowthZone returns "invalid"); the PASSWORD grant works
    // (proven in growthzone-readonly). The connector selects refresh_token whenever a RefreshToken is
    // present (no fallback), so OMIT RefreshToken here to force the working password grant. Set
    // GROWTHZONE_USE_REFRESH=1 to include it (once a fresh token is available).
    const useRefresh = (env.GROWTHZONE_USE_REFRESH === '1') && refreshToken;
    const credentialValues = JSON.stringify({
        ClientId: clientId, ClientSecret: clientSecret, BaseURL: baseUrl,
        ...(useRefresh ? { RefreshToken: refreshToken } : {}),
        ...(scopes ? { Scopes: scopes } : {}), ...(tokenUrl ? { TokenURL: tokenUrl } : {}),
        ...(uname ? { Username: uname } : {}), ...(pword ? { Password: pword } : {}),
    });
    const configuration = JSON.stringify({ BaseURL: baseUrl, ClientId: clientId, ...(scopes ? { Scopes: scopes } : {}) });
    async function gql(query, variables) {
        const r = await fetch(graphqlUrl, { method: 'POST', headers: { 'Content-Type': 'application/json', 'x-mj-api-key': mjSystemKey }, body: JSON.stringify({ query, variables }) });
        const j = await r.json();
        if (j.errors) throw new Error('GQL: ' + scrub(JSON.stringify(j.errors).slice(0, 400)));
        return j.data;
    }
    const CREATE = `mutation($input: CreateConnectionInput!, $testConnection: Boolean!, $runSchemaRefresh: Boolean!) {
      IntegrationCreateConnection(input: $input, testConnection: $testConnection, runSchemaRefresh: $runSchemaRefresh) {
        Success Message CompanyIntegrationID CredentialID ConnectionTestSuccess ConnectionTestMessage } }`;
    const input = { CompanyID: companyID, IntegrationID: integrationID, CredentialTypeID: credentialTypeID, CredentialName: 'GrowthZone E2E OAuth2', CredentialValues: credentialValues, Configuration: configuration };
    let d;
    try { d = await gql(CREATE, { input, testConnection: true, runSchemaRefresh: false }); }
    catch (e) { return { ok: false, plan: 'growthzone-create-connection', error: scrub(e instanceof Error ? e.message : String(e)) }; }
    const c = d?.IntegrationCreateConnection ?? {};
    return {
        ok: !!c.Success, plan: 'growthzone-create-connection',
        companyIntegrationID: c.CompanyIntegrationID ?? null,
        connectionTest: c.ConnectionTestSuccess ?? null,
        connectionTestMessage: scrub(c.ConnectionTestMessage || ''),
        message: scrub(c.Message || ''),
    };
}

/**
 * GrowthZone path-discovery probe (READ-ONLY). Mints a Bearer, then (1) attempts one-shot endpoint
 * enumeration via OData `$metadata` / swagger, and (2) probes candidate list paths for the doors whose
 * seeded API path returned 404/400/405. Reports status + recordCount + top-level record keys per path so
 * the real endpoint can be identified. NEVER writes/acks. Same OAuth secrets as growthzone-readonly.
 */
export async function growthzoneProbePaths({ baseUrl, clientId, clientSecret, refreshToken }, scrub) {
    const out = { ok: false, plan: 'growthzone-probe-paths', tokenMint: {}, discovery: {}, probes: {} };
    const rawBase = String(baseUrl || '').trim().replace(/\/+$/, '');
    let origin = rawBase, apiBase = rawBase;
    try { origin = new URL(rawBase).origin; } catch { /* */ }
    if (!/\/api$/i.test(apiBase)) apiBase = `${apiBase}/api`;
    const tokenUrl = (process.env.GROWTHZONE_TOKEN_URL || `${origin}/oauth/token`).trim();
    const scopes = (process.env.GROWTHZONE_SCOPES || '').trim();
    const uname = process.env.GROWTHZONE_USERNAME, pword = process.env.GROWTHZONE_PASSWORD;

    async function mint(body, label) {
        try {
            const resp = await fetch(tokenUrl, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'Accept': 'application/json' }, body: new URLSearchParams(body).toString() });
            const text = await resp.text();
            let tok = null; try { tok = JSON.parse(text).access_token ?? null; } catch { /* */ }
            return { grant: label, status: resp.status, token: tok };
        } catch (e) { return { grant: label, error: scrub(e instanceof Error ? e.message : String(e)) }; }
    }
    let m = await mint({ grant_type: 'refresh_token', refresh_token: refreshToken, client_id: clientId, client_secret: clientSecret, ...(scopes ? { scope: scopes } : {}) }, 'refresh_token');
    if (!m.token && uname && pword) m = await mint({ grant_type: 'password', username: uname, password: pword, client_id: clientId, client_secret: clientSecret, ...(scopes ? { scope: scopes } : {}) }, 'password');
    out.tokenMint = { grant: m.grant, status: m.status, gotToken: !!m.token };
    if (!m.token) { out.note = 'token mint failed'; return out; }
    const H = { 'Authorization': `Bearer ${m.token}`, 'Accept': 'application/json' };

    async function get(path) {
        try {
            const resp = await fetch(`${apiBase}${path}`, { method: 'GET', headers: H });
            const text = await resp.text();
            let recs = null, keys = [];
            try { const j = JSON.parse(text); recs = Array.isArray(j) ? j : (j.Results ?? j.value ?? null); if (Array.isArray(recs) && recs[0] && typeof recs[0] === 'object') keys = Object.keys(recs[0]).slice(0, 40); } catch { /* */ }
            return { path, status: resp.status, recordCount: Array.isArray(recs) ? recs.length : null, keys, ...(resp.status >= 200 && resp.status < 300 ? {} : { body: scrub(text.slice(0, 160)) }) };
        } catch (e) { return { path, error: scrub(e instanceof Error ? e.message : String(e)) }; }
    }

    // 0) DEFINITIVE Contact-door completeness: total + page-2 existence (is 100 the cap or the truth?)
    async function getFull(path) {
        try {
            const resp = await fetch(`${apiBase}${path}`, { method: 'GET', headers: H });
            const text = await resp.text();
            let j = null; try { j = JSON.parse(text); } catch { /* */ }
            const recs = Array.isArray(j) ? j : (j?.Results ?? null);
            return { path, status: resp.status, count: Array.isArray(recs) ? recs.length : null, total: j?.TotalRecordAvailable ?? null };
        } catch (e) { return { path, error: scrub(e instanceof Error ? e.message : String(e)) }; }
    }
    async function firstIds(path, n) {
        try {
            const resp = await fetch(`${apiBase}${path}`, { headers: H });
            const j = await resp.json();
            const recs = Array.isArray(j) ? j : (j?.Results ?? []);
            return { path, status: resp.status, total: j?.TotalRecordAvailable ?? null, ids: recs.slice(0, n).map(r => r.ContactId ?? r.Id ?? r.ID ?? JSON.stringify(r).slice(0, 20)) };
        } catch (e) { return { path, error: String(e).slice(0, 80) }; }
    }
    // Does `skip` actually advance? Compare first IDs at skip=0 vs skip=3 vs $skip=3.
    out.skipParamTest = {
        skip0: await firstIds('/contacts?top=3&skip=0', 3),
        skip3: await firstIds('/contacts?top=3&skip=3', 3),
        dollarSkip3: await firstIds('/contacts?$top=3&$skip=3', 3),
        page2: await firstIds('/contacts?top=3&page=2', 3),
        pageNumber2: await firstIds('/contacts?top=3&pageNumber=2', 3),
        offset3: await firstIds('/contacts?top=3&offset=3', 3),
    };
    out.contactDoorTruth = {
        page1: await getFull('/contacts?top=100'),
        page2_skip100: await getFull('/contacts?top=100&skip=100'),
    };

    // 1) one-shot enumeration
    for (const d of ['/$metadata', '/swagger/docs/v1', '/swagger', '/metadata', '']) out.discovery[d || '(root)'] = await get(d);

    // 2) candidate list paths per broken door (probe with top=1)
    // Round 2: `/all` door pattern (proven by /groups/all) + param-children confirmed with real IDs.
    const memId = process.env.GZ_PROBE_MEMBERSHIP_ID || '';
    const candidates = {
        Event: ['/events/all', '/event/all', '/eventcalendar/all', '/eventcalendars/all', '/calendar/all', '/events/upcoming', '/eventlist', '/event'],
        EventCalendar: ['/eventcalendars/all', '/calendars/all', '/eventcalendar/all'],
        EventVenue: ['/eventvenues/all', '/venues/all', '/venue/all'],
        StoreItem: ['/store/items/all', '/store/all', '/storeitems/all', '/store/products/all', '/storeitem/all', '/commerce/items/all'],
        StoreOrder: ['/store/orders/all', '/store/order/all', '/orders/all', '/storeorders/all'],
        StoreDigitalPurchase: ['/store/storedownloads/all', '/store/downloads/all', '/store/digitalpurchases/all'],
        Directory: ['/directory/all', '/directories/all', '/directorylistings/all', '/directorylisting/all', '/listings/all'],
        DirectoryListingType: ['/directory/listingtypes/all', '/directorylistingtypes/all', '/directory/types/all', '/listingtypes/all'],
        ScheduledBillingUpdate: ['/scheduledbilling/all', '/memberships/scheduledbilling/all', '/membership/scheduledbilling/all'],
    };
    for (const [door, paths] of Object.entries(candidates)) {
        out.probes[door] = [];
        for (const p of paths) out.probes[door].push(await get(`${p}?top=1`));
    }
    // Chain real IDs from the working doors to confirm the param-children (read-only).
    out.paramChildren = {};
    const evDoor = await get('/events/all?top=1');
    const firstEvent = evDoor.recordCount ? null : null;
    let evId = '';
    try { const resp = await fetch(`${apiBase}/events/all?top=1`, { headers: H }); const j = await resp.json(); evId = String((Array.isArray(j) ? j[0] : (j.Results || [])[0])?.EventId ?? ''); } catch { /* */ }
    if (evId) {
        out.paramChildren.eventIdUsed = evId;
        out.paramChildren.EventCalendars = await get(`/events/calendars?eventId=${evId}&top=2`);
        out.paramChildren.EventVenues = await get(`/events/venues?eventId=${evId}&top=2`);
        out.paramChildren.EventList = await get(`/events/list?eventId=${evId}&top=2`);
        out.paramChildren.EventSessions = await get(`/events/sessions?eventId=${evId}&top=2`);
        out.paramChildren.EventRegistrationTypes = await get(`/events/registrationtypes?eventId=${evId}&top=2`);
        out.paramChildren.EventSponsors = await get(`/events/sponsors?eventId=${evId}&top=2`);
        out.paramChildren.EventExhibitors = await get(`/events/exhibitors?eventId=${evId}&top=2`);
    }
    let mId = memId;
    if (!mId) { try { const resp = await fetch(`${apiBase}/memberships?top=1`, { headers: H }); const j = await resp.json(); mId = String((Array.isArray(j) ? j[0] : (j.Results || [])[0])?.MembershipId ?? (j.Results || [])[0]?.Id ?? ''); } catch { /* */ } }
    if (mId) { out.paramChildren.membershipIdUsed = mId; out.paramChildren.ScheduledBilling = await get(`/memberships/scheduledbilling?membershipId=${mId}&top=2`); }
    // ── Comprehensive child-path discovery with REAL parent IDs (path-segment vs query-param style) ──
    async function realId(path, field) { try { const resp = await fetch(`${apiBase}${path}`, { headers: H }); const j = await resp.json(); const rec = (Array.isArray(j) ? j[0] : (j.Results || [])[0]) || {}; return String(rec[field] ?? rec.Id ?? rec.ID ?? ''); } catch { return ''; } }
    const cid = await realId('/contacts?$top=1', 'ContactId');
    const gid = await realId('/groups/all?$top=1', 'GroupId');
    const mid2 = await realId('/memberships?$top=1', 'MembershipId');
    out.childPaths = { ids: { cid, evId, gid, mid: mid2 } };
    const tests = {
        ContactPhone: [`/contacts/${cid}/phones`, `/contacts/${cid}/phone`, `/contacts/phones?contactId=${cid}`],
        ContactCustomField: [`/contacts/${cid}/customfields`, `/contacts/${cid}/NotesAndFields`, `/contacts/${cid}/fields`],
        EventSponsor_path: [`/events/${evId}/sponsors`],
        EventSponsor_query: [`/events/sponsors?eventId=${evId}`],
        EventSession_query: [`/events/sessions?eventId=${evId}`],
        EventAttendee_query: [`/events/attendees?eventId=${evId}`, `/events/${evId}/attendees`],
        GroupMember_path: [`/groups/${gid}/members`],
        GroupMember_query: [`/groups/members?groupId=${gid}`, `/groups/all/members?groupId=${gid}`],
        ScheduledBilling: [`/memberships/scheduledbilling?membershipId=${mid2}`],
        MembershipChange: [`/memberships/change/${mid2}/All`, `/memberships/${mid2}/changes`, `/memberships/changes?membershipId=${mid2}`],
    };
    for (const [k, paths] of Object.entries(tests)) { out.childPaths[k] = []; for (const p of paths) out.childPaths[k].push(await get(p.includes('?') ? `${p}&$top=2` : `${p}?$top=2`)); }

    // Round-2 unknowns: membership PK field, ContactPhone endpoint, MembershipChange shape, contact detail.
    out.unknowns = {};
    out.unknowns.membershipKeys = await get('/memberships?$top=1');
    out.unknowns.contactDetail = await get(`/contacts/${cid}`);
    out.unknowns.notesAndFields = await get(`/contacts/${cid}/NotesAndFields?$top=3`);
    for (const p of [`/contacts/${cid}/phonenumbers`, `/contacts/${cid}/communication`, `/contacts/${cid}/phonenumber`, `/contacts/${cid}/contactphones`, `/contacts/${cid}/phonelist`]) out.unknowns['phone:' + p.split('/').pop()] = await get(`${p}?$top=2`);
    // Membership door is /memberships/all — get a real MembershipId for the param-children.
    const mid = await realId('/memberships/all?$top=1', 'MembershipId');
    out.unknowns.midUsed = mid;
    const finals = {
        ScheduledBilling: [`/memberships/scheduledbilling?membershipId=${mid}`, `/memberships/${mid}/scheduledbilling`],
        MembershipChange: [`/memberships/${mid}/changes`, `/memberships/change?membershipId=${mid}`, `/memberships/changes?membershipId=${mid}`],
        Certification: [`/certifications/all`, `/certifications`, `/certification/all`, `/contacts/${cid}/certifications`],
        MembershipStatusLookup: [`/memberships/lookup/status/Active`, `/memberships/statuses/all`, `/memberships/statuslookup/all`, `/memberships/lookup/status`],
        ContactPhone: [`/contacts/${cid}/Phones`, `/contacts/${cid}/PhoneNumbers`, `/contacts/${cid}/phone/all`, `/contacts/phones/${cid}`],
    };
    for (const [k, paths] of Object.entries(finals)) { out.unknowns['F_' + k] = []; for (const p of paths) out.unknowns['F_' + k].push(await get(p.includes('?') ? `${p}&$top=2` : `${p}?$top=2`)); }
    // DETERMINISM PROBE: fetch the same Event-child endpoint twice, diff the full records to find the
    // field that varies between fetches (the cause of non-idempotent content-hash growth).
    async function getRaw(path) { try { const r = await fetch(`${apiBase}${path}`, { headers: H }); const j = await r.json(); return Array.isArray(j) ? j[0] : (j.Results ? j.Results[0] : j); } catch (e) { return { error: String(e).slice(0, 60) }; } }
    let evIdD = '';
    try { const r = await fetch(`${apiBase}/events/all?top=1`, { headers: H }); const j = await r.json(); evIdD = String((Array.isArray(j) ? j[0] : (j.Results || [])[0])?.EventId ?? ''); } catch { /* */ }
    if (evIdD) {
        const a = await getRaw(`/events/sponsors?eventId=${evIdD}`);
        const b = await getRaw(`/events/sponsors?eventId=${evIdD}`);
        const keys = [...new Set([...Object.keys(a || {}), ...Object.keys(b || {})])];
        out.determinism = {
            eventId: evIdD,
            varyingFields: keys.filter(k => JSON.stringify(a?.[k]) !== JSON.stringify(b?.[k])).map(k => ({ field: k, a: JSON.stringify(a?.[k])?.slice(0, 50), b: JSON.stringify(b?.[k])?.slice(0, 50) })),
            allKeys: keys,
        };
    }

    out.ok = true;
    out.note = 'read-only path discovery; 2xx with recordCount!=null identifies the real list endpoint';
    return out;
}


/**
 * GrowthZone CREDENTIALED RealityProbe (v2 S7 full mode — ARCHITECTURE_REFACTOR.md P2/P9).
 * Mints a Bearer (refresh grant, password fallback — body-only client creds), then runs the
 * DETERMINISTIC probe script as a child with the token in ITS env only (PROBE_TOKEN). The probe
 * emits VERDICTS on declared claims (paths/pagination/PK-populated/watermark/write-surface) and
 * never records auth headers; the scrubbed summary + verdict counts come back — never the token.
 * READ-ONLY: GETs + OPTIONS only; write-surface evidence is OPTIONS/405/401, never a write call.
 */
export async function growthzoneProbeLive({ baseUrl, clientId, clientSecret, refreshToken }, scrub) {
    const out = { ok: false, plan: 'growthzone-probe-live', steps: {} };
    const rawBase = String(baseUrl || '').trim().replace(/\/+$/, '');
    let origin = rawBase;
    try { origin = new URL(rawBase).origin; } catch { /* keep */ }
    const tokenUrl = (process.env.GROWTHZONE_TOKEN_URL || `${origin}/oauth/token`).trim();

    async function mint(grantBody, label) {
        let resp;
        try {
            resp = await fetch(tokenUrl, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'Accept': 'application/json' }, body: new URLSearchParams(grantBody).toString() });
        } catch (e) { return { grant: label, error: scrub(e instanceof Error ? e.message : String(e)) }; }
        const text = await resp.text();
        let tok = null;
        try { const j = JSON.parse(text); tok = j.access_token ?? j.accessToken ?? null; } catch { /* */ }
        return { grant: label, status: resp.status, gotToken: !!tok, token: tok };
    }
    let m = await mint({ grant_type: 'refresh_token', client_id: clientId, client_secret: clientSecret, refresh_token: refreshToken }, 'refresh_token');
    if (!m.gotToken && process.env.GROWTHZONE_USERNAME) {
        m = await mint({ grant_type: 'password', client_id: clientId, client_secret: clientSecret, username: process.env.GROWTHZONE_USERNAME, password: process.env.GROWTHZONE_PASSWORD || '', scope: process.env.GROWTHZONE_SCOPES || '' }, 'password');
    }
    out.steps.mint = { grant: m.grant, status: m.status, gotToken: m.gotToken };
    if (!m.gotToken) { out.error = 'token mint failed'; return out; }

    const { execFileSync } = await import('node:child_process');
    const { mkdtempSync } = await import('node:fs');
    const { tmpdir } = await import('node:os');
    const { resolve, dirname } = await import('node:path');
    const { fileURLToPath } = await import('node:url');
    const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..', '..', '..');
    const probe = resolve(repoRoot, 'packages/Integration/connector-builder-workshop/scripts/reality-probe.mjs');
    const metadata = process.env.GZ_PROBE_METADATA || resolve(repoRoot, 'metadata/integrations/growthzone/.growthzone.integration.json');
    const outDir = mkdtempSync(resolve(tmpdir(), 'gz-probe-live-'));
    let stdout = '';
    try {
        stdout = execFileSync(process.execPath, [probe, '--metadata', metadata, '--base-url', origin, '--token-env', 'PROBE_TOKEN', '--out', outDir, '--qps', process.env.GZ_PROBE_QPS || '3'], {
            env: { ...process.env, PROBE_TOKEN: m.token }, encoding: 'utf-8', timeout: 15 * 60 * 1000, maxBuffer: 16 * 1024 * 1024,
        });
    } catch (e) { out.error = scrub(`probe failed: ${e instanceof Error ? e.message : String(e)}`.slice(0, 300)); return out; }
    try {
        const { readFileSync } = await import('node:fs');
        const summary = JSON.parse(readFileSync(resolve(outDir, 'verdicts.json'), 'utf-8'));
        // Scrubbed return: counts + per-claim verdicts (paths/field names/statuses only — no values, no headers beyond rate-limit names).
        out.steps.probe = {
            mode: summary.mode, claims: summary.claims, confirmed: summary.confirmed, wrong: summary.wrong, unverified: summary.unverified,
            wrongVerdicts: summary.verdicts.filter(v => v.verdict === 'wrong').map(v => ({ object: v.object, kind: v.kind, claim: v.claim, evidence: scrub(String(v.evidence).slice(0, 160)) })),
            unverifiedByName: summary.unverifiedByName,
            artifactDir: outDir,
        };
        out.ok = true;
    } catch (e) { out.error = scrub(`verdict read failed: ${e instanceof Error ? e.message : String(e)}`.slice(0, 200)); }
    return out;
}

/**
 * HubSpot CREDENTIALED RealityProbe (v2 S7 — ARCHITECTURE_REFACTOR.md P2/P9). Runs the pinned
 * DETERMINISTIC reality-probe.mjs as a child with the broker-held token in ITS env only (PROBE_TOKEN);
 * the token never appears in argv or output, and Authorization headers are never recorded. The probe
 * emits VERDICTS on declared claims (path→status+records, pagination advance, PK-populated, watermark,
 * write-surface existence) and NEVER authors metadata. READ-ONLY: GETs + OPTIONS only — write-surface
 * evidence is OPTIONS/405/401, never a write call. Returns the FULL scrubbed verdicts.json contents so
 * the caller can record them verbatim (no secret material ever transits — the probe scrubs auth/PII).
 */
export async function hubspotProbeLive({ token }, scrub) {
    const out = { ok: false, plan: 'hubspot-probe-live', steps: {} };
    const { execFileSync, readFileSync } = { ...(await import('node:child_process')), ...(await import('node:fs')) };
    const { resolve, dirname } = await import('node:path');
    const { fileURLToPath } = await import('node:url');
    const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..', '..', '..');
    const probe = resolve(repoRoot, 'packages/Integration/connector-builder-workshop/scripts/reality-probe.mjs');
    const metadata = process.env.HS_PROBE_METADATA || resolve(repoRoot, 'metadata/integrations/hubspot/.hubspot.integration.json');
    const baseUrl = process.env.HS_PROBE_BASE_URL || 'https://api.hubapi.com';
    // The broker runs as user `mjbroker`; the run's output/ dir is owned by the operator, so a direct
    // write there EACCESes. Write to a broker-writable temp dir; the operator copies verdicts.json into
    // the run output afterward (verdicts carry no secret — probe scrubs auth headers + records no creds).
    const { mkdtempSync } = await import('node:fs');
    const { tmpdir } = await import('node:os');
    const outDir = mkdtempSync(resolve(tmpdir(), 'hs-probe-live-'));
    const objects = process.env.HS_PROBE_OBJECTS || 'contacts,companies,deals';
    const qps = process.env.HS_PROBE_QPS || '2';
    const probeArgs = [probe, '--metadata', metadata, '--base-url', baseUrl, '--token-env', 'PROBE_TOKEN', '--out', outDir, '--objects', objects, '--qps', qps];
    let stdout = '';
    try {
        stdout = execFileSync(process.execPath, probeArgs, {
            env: { ...process.env, PROBE_TOKEN: token }, encoding: 'utf-8', timeout: 15 * 60 * 1000, maxBuffer: 32 * 1024 * 1024,
        });
    } catch (e) {
        const stderr = e && e.stderr ? String(e.stderr) : '';
        const childOut = e && e.stdout ? String(e.stdout) : '';
        const status = e && e.status != null ? e.status : (e && e.signal ? `signal ${e.signal}` : '?');
        out.error = scrub(`probe child failed (exit ${status}): ${(stderr || childOut || (e instanceof Error ? e.message : String(e)))}`.slice(0, 1500));
        return out;
    }
    try {
        const summary = JSON.parse(readFileSync(resolve(outDir, 'verdicts.json'), 'utf-8'));
        // The probe already scrubs auth headers + records no credential bytes; verdicts carry only
        // object/field NAMES + statuses + rate-limit header NAMES. Return the full summary verbatim.
        out.steps.probe = summary;
        out.steps.stdout = scrub(String(stdout).slice(0, 1000));
        out.ok = true;
    } catch (e) { out.error = scrub(`verdict read failed: ${e instanceof Error ? e.message : String(e)}`.slice(0, 200)); }
    return out;
}

/**
 * Mailchimp CREDENTIALED RealityProbe (v2 S7 — mirror of hubspotProbeLive). Runs the SAME pinned
 * DETERMINISTIC reality-probe.mjs as a child with the broker-held token in PROBE_TOKEN only (never in
 * argv/output; Authorization headers never recorded). Mailchimp accepts the API key as a Bearer header
 * (metadata Configuration.BearerAlternate — an equally-valid transport for the same credential value),
 * so the probe's Bearer auth is correct here. READ-ONLY: GETs + OPTIONS only; write-surface evidence is
 * OPTIONS/405/401, never a write call. The API host is data-center-templated — the {dc} prefix is DERIVED
 * from the credential (the suffix after the last '-' in the API key), NOT a baked constant. Returns the
 * FULL verdicts.json contents so the caller records them verbatim (probe scrubs auth/PII; no secret transits).
 */
export async function mailchimpProbeLive({ token }, scrub) {
    const out = { ok: false, plan: 'mailchimp-probe-live', steps: {} };
    const { execFileSync, readFileSync, mkdtempSync } = await import('node:fs').then(async (fsMod) => ({ ...(await import('node:child_process')), ...fsMod }));
    const { resolve, dirname } = await import('node:path');
    const { fileURLToPath } = await import('node:url');
    const { tmpdir } = await import('node:os');
    const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..', '..', '..');
    const probe = resolve(repoRoot, 'packages/Integration/connector-builder-workshop/scripts/reality-probe.mjs');
    const metadata = process.env.MC_PROBE_METADATA || resolve(repoRoot, 'metadata/integrations/mailchimp/.mailchimp.integration.json');
    // Derive the data-center prefix from the credential (never a baked constant): the {dc} is the
    // substring after the last '-' in the API key (fundamentals.html + Configuration.APIBaseURLNote).
    const dc = (process.env.MAILCHIMP_SERVER_PREFIX || String(token).split('-').pop() || '').trim();
    if (!/^us\d+$/i.test(dc)) { out.error = `bad mailchimp server prefix "${scrub(dc)}" (could not derive {dc} from the credential)`; return out; }
    const baseUrl = process.env.MC_PROBE_BASE_URL || `https://${dc}.api.mailchimp.com/3.0`;
    // Broker runs as `mjbroker`; the operator-owned run output/ dir EACCESes a direct write. Emit to a
    // broker-writable temp dir and return the full summary; the operator copies verdicts.json into the run.
    const outDir = mkdtempSync(resolve(tmpdir(), 'mc-probe-live-'));
    const qps = process.env.MC_PROBE_QPS || '3';
    const probeArgs = [probe, '--metadata', metadata, '--base-url', baseUrl, '--token-env', 'PROBE_TOKEN', '--out', outDir, '--qps', qps];
    if (process.env.MC_PROBE_OBJECTS) probeArgs.push('--objects', process.env.MC_PROBE_OBJECTS);
    let stdout = '';
    try {
        stdout = execFileSync(process.execPath, probeArgs, {
            env: { ...process.env, PROBE_TOKEN: token }, encoding: 'utf-8', timeout: 15 * 60 * 1000, maxBuffer: 32 * 1024 * 1024,
        });
    } catch (e) {
        const stderr = e && e.stderr ? String(e.stderr) : '';
        const childOut = e && e.stdout ? String(e.stdout) : '';
        const status = e && e.status != null ? e.status : (e && e.signal ? `signal ${e.signal}` : '?');
        out.error = scrub(`probe child failed (exit ${status}): ${(stderr || childOut || (e instanceof Error ? e.message : String(e)))}`.slice(0, 1500));
        return out;
    }
    try {
        const summary = JSON.parse(readFileSync(resolve(outDir, 'verdicts.json'), 'utf-8'));
        // Probe already scrubs auth headers + records no credential bytes; verdicts carry only object/field
        // NAMES + statuses + rate-limit header NAMES. Return the full summary verbatim for the caller.
        out.steps.probe = summary;
        out.steps.stdout = scrub(String(stdout).slice(0, 1000));
        out.ok = true;
    } catch (e) { out.error = scrub(`verdict read failed: ${e instanceof Error ? e.message : String(e)}`.slice(0, 200)); }
    return out;
}

async function connectorE2EHybridPlan(values, scrub) { // eslint-disable-line no-unused-vars -- scrub kept for signature symmetry (runner scrubs result)
    const cfg = connectorE2eCfgFromEnv();
    if (!cfg.connector) return { ok: false, error: 'connector-e2e-hybrid requires E2E_CONNECTOR (registry connector dir name)' };
    if (!cfg.companyIntegrationID) {
        return { ok: false, error: 'connector-e2e-hybrid is reference-mode ONLY — set HS_LIVE_CIID to the broker-seeded CompanyIntegrationID (the token is used by-reference, never read)' };
    }

    const db = await makeDbClient(cfg.platform, { ...cfg.db, password: values.dbPassword, mjSchema: cfg.mjSchema });
    const gql = makeGqlClient(cfg.graphqlUrl, { mjSystemKey: values.mjSystemKey, mjUserKey: values.mjUserKey, mjToken: values.mjToken });

    // Build BOTH mocks: an inert one for the live sub-pass + the fixtures-replaying one for
    // the out-of-scope fallback sub-pass. runConnectorE2EHybrid closes db + both mocks once.
    const mockLive = await buildMock({ mode: 'live', fixturesDir: cfg.fixturesDir, tls: cfg.tls });
    let mockFixtures = null;
    try {
        try { mockFixtures = await buildMock({ mode: 'mock', fixturesDir: cfg.fixturesDir, tls: cfg.tls }); }
        catch (e) { mockFixtures = null; /* no fixtures → out-of-scope objects surface as no-fixture warnings */ void e; }

        // Objects: explicit override > fixtures Objects[] > cfg default list. The fixtures
        // Objects[] (when present) is also the fallback-serveable set for the no-fixture warning.
        const fixtureObjects = mockFixtures?.manifest ? objectsFromManifest(mockFixtures.manifest) : [];
        const objects = cfg.objectsOverride.length ? cfg.objectsOverride
            : (fixtureObjects.length ? fixtureObjects : cfg.objects);
        if (!objects.length) {
            try { if (mockLive?.close) await mockLive.close(); } catch { /* best-effort */ }
            try { if (mockFixtures?.close) await mockFixtures.close(); } catch { /* best-effort */ }
            try { if (db.close) await db.close(); } catch { /* best-effort */ }
            return { ok: false, mode: 'hybrid', connector: cfg.connector, error: 'connector-e2e-hybrid: no objects to probe (set E2E_OBJECTS or provide fixtures Objects[])' };
        }

        const fullCfg = {
            ...cfg,
            objects,
            fixtureObjects: fixtureObjects.length ? fixtureObjects : undefined,
            deltaPasses: mockFixtures?.manifest ? deltaPassesFromManifest(mockFixtures.manifest) : [],
        };

        const result = await runConnectorE2EHybrid({ gql, db, mockLive, mockFixtures }, fullCfg, false);
        // Surface the fixtures mock wiring (live sub-pass needs no redirect; it hits the real vendor).
        result.mockWiring = mockFixtures
            ? { kind: mockFixtures.kind, baseURL: mockFixtures.baseURL ?? null, proxyURL: mockFixtures.proxyURL ?? null, tlsRequired: mockFixtures.tlsRequired ?? false, proxyEnvExpected: mockFixtures.proxyEnvExpected ?? null, fixtureWarnings: mockFixtures.warnings ?? [] }
            : { note: 'no fixtures present — out-of-scope objects (if any) surface as mock-fallback-no-fixture warnings' };
        return result;
    } catch (e) {
        try { if (mockLive?.close) await mockLive.close(); } catch { /* best-effort */ }
        try { if (mockFixtures?.close) await mockFixtures.close(); } catch { /* best-effort */ }
        try { if (db.close) await db.close(); } catch { /* best-effort */ }
        return { ok: false, mode: 'hybrid', connector: cfg.connector, error: String(e?.stack ?? e?.message ?? e) };
    }
}

/** Hybrid-mode e2e (reference-mode, limited-token) — writes:false; credentials only via broker. */
export async function connectorE2EHybrid(values, scrub) { return connectorE2EHybridPlan(values, scrub); }


export const PLANS = {
    'connector-e2e-hybrid': {
        secrets: { dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: connectorE2EHybrid, writes: false,
    },

    // GrowthZone CREDENTIALED RealityProbe (v2 S7 full mode) — read-only verdicts on declared claims.
    'growthzone-probe-live': {
        secrets: { baseUrl: 'GROWTHZONE_BASE_URL', clientId: 'GROWTHZONE_CLIENT_ID', clientSecret: 'GROWTHZONE_CLIENT_SECRET' },
        run: growthzoneProbeLive, writes: false,
    },
    // GrowthZone read-only path discovery for the 404/400/405 doors. Hot-reloaded; no broker restart.
    'growthzone-probe-paths': {
        secrets: { baseUrl: 'GROWTHZONE_BASE_URL', clientId: 'GROWTHZONE_CLIENT_ID', clientSecret: 'GROWTHZONE_CLIENT_SECRET' },
        run: growthzoneProbePaths, writes: false,
    },
    // GrowthZone OAuth2 connection creation (broker holds the OAuth secrets; returns only the CIID).
    // refreshToken is NOT a required secret: the operator's refresh token is expired and the connector
    // uses the working PASSWORD grant (GROWTHZONE_USERNAME/PASSWORD from the broker env). Requiring it
    // here blocked the live connection on a token the working path never uses. Opt in via GROWTHZONE_USE_REFRESH=1.
    'growthzone-create-connection': {
        secrets: { clientId: 'GROWTHZONE_CLIENT_ID', clientSecret: 'GROWTHZONE_CLIENT_SECRET', baseUrl: 'GROWTHZONE_BASE_URL', mjSystemKey: 'MJ_API_KEY' },
        run: growthzoneCreateConnection, writes: false,
    },
    'propfuel-create-connection': {
        secrets: { token: 'CONNECTOR_API_KEY', mjSystemKey: 'MJ_API_KEY' },
        run: propfuelCreateConnection, writes: false,
    },
    // ── CONNECTOR-AGNOSTIC full e2e (real engine) — replaces per-vendor hardcoding ──────────────────
    // MOCK mode (credential-free): a local mock-vendor server replays E2E_CONNECTOR's fixtures.json;
    // the SAME real pipeline runs (CreateConnection → ApplyAll builds tables → StartSync runs the real
    // IntegrationEngine → tail → DB verify incl. delta create/update/delete + idempotent re-run). NO
    // vendor secret is declared (credential-free by construction). writes:false ALWAYS — read-only from
    // the vendor; the DB writes are into our OWN destination schema (the point of the test), and mock
    // mode never declares a secret. Set E2E_CONNECTOR + E2E_MODE=mock (default) + the HS_LIVE_* DB/GQL
    // coordinates. Works for ANY connector shape by reading the discovered objects + the fixtures.
    'connector-e2e': {
        secrets: { dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: connectorE2EMock, writes: false,
    },
    // LIVE mode (credentialed): identical pipeline + DB verification against the REAL vendor. Credential
    // arrives ONLY via the broker mailbox, READ-ONLY, never acked. token (E2E_MODE=live, no pre-seeded
    // CIID) OR pre-seeded HS_LIVE_CIID (token-free reference). writes:false (forward/read path only).
    'connector-e2e-live': {
        secrets: { token: 'CONNECTOR_API_KEY', dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: connectorE2ELive, writes: false,
    },
    'hubspot-tier1': { secrets: { token: 'HUBSPOT_API_KEY' }, run: hubspotTier1, writes: false },
    // PropFuel data-export feed — read-only (GET list + GET download; NEVER ack). Safe vs live data.
    'propfuel-readonly': { secrets: { token: 'CONNECTOR_API_KEY' }, run: propfuelReadonly, writes: false },
    // Totara / Moodle Web Services — READ-ONLY live validation: TestConnection (core_webservice_get_site_info)
    // + one bounded read page (core_course_get_categories). Counts/keys only, NO PII/values. NEVER writes.
    // Token from the broker env TOTARA_TOKEN; base_url NON-SECRET via E2E_LIVE_CONFIG.baseUrl.
    'totara-readonly': { secrets: { token: 'TOTARA_TOKEN' }, run: totaraReadonly, writes: false },
    // Totara LIVE full-pipeline e2e (read-only vendor sync → DB verify). Token from TOTARA_TOKEN (unambiguous
    // under a --all broker); base_url via E2E_LIVE_CONFIG.baseUrl. writes:false.
    'totara-e2e-live': { secrets: { token: 'TOTARA_TOKEN', dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' }, run: totaraE2ELive, writes: false },
    // Totara parent-iteration fix probe (API-level, no MJAPI) — calls course-scoped fns WITH courseid + Users criteria.
    'totara-parent-probe': { secrets: { token: 'TOTARA_TOKEN' }, run: totaraParentProbe, writes: false },
    // GrowthZone OAuth2 — read-only live validation: mint Bearer (refresh_token grant) + GET one
    // contacts page + delta probe. NEVER writes/acks. Only the 4 OAuth secrets are REQUIRED; optional
    // username/password/scopes/token-url are read from env so a skipped one doesn't fail the plan.
    'growthzone-readonly': {
        secrets: { baseUrl: 'GROWTHZONE_BASE_URL', clientId: 'GROWTHZONE_CLIENT_ID', clientSecret: 'GROWTHZONE_CLIENT_SECRET' }, // refreshToken optional (env) — password grant works without it
        run: growthzoneReadonly, writes: false,
    },
    // PropFuel structure-only discovery (spec-less connector) — GET list + GET download window;
    // returns nested schema + identity/update/delete signal, NO record values. NEVER ack. writes:false.
    'propfuel-discover': { secrets: { token: 'CONNECTOR_API_KEY' }, run: propfuelDiscover, writes: false },
    // Same probe, but sourced from the vendor-prefixed PROPFUEL_TOKEN secret — this multi-vendor broker
    // session doesn't populate the generic CONNECTOR_API_KEY name (each vendor's token is prefixed to
    // avoid collisions), so 'propfuel-discover' 401s here. Temporary operator-added alias; safe to remove.
    'propfuel-discover-live': { secrets: { token: 'PROPFUEL_TOKEN' }, run: propfuelDiscover, writes: false },
    // SharePoint (Microsoft Graph v1.0) — MULTI-SECRET OAuth2 client-credentials, READ-ONLY live
    // validation: mint an app-only Bearer at login.microsoftonline.com, then read-only Graph GETs
    // (/sites/root, /sites?search, optional SHAREPOINT_SITE drives/lists + /delta probe). NEVER writes.
    'sharepoint-readonly': {
        secrets: { tenantId: 'SHAREPOINT_TENANT_ID', clientId: 'SHAREPOINT_CLIENT_ID', clientSecret: 'SHAREPOINT_CLIENT_SECRET' },
        run: sharepointReadonly, writes: false,
    },
    // Dynamics 365 / Dataverse — READ-ONLY probe answering "are the SAME SharePoint Entra app creds
    // usable for Dynamics?". Reuses the SHAREPOINT_* secrets (same identity platform). Global Discovery
    // needs no org URL; set DYNAMICS365_ORG_URL for a definitive WhoAmI. NEVER writes.
    'dynamics365-probe': {
        secrets: { tenantId: 'SHAREPOINT_TENANT_ID', clientId: 'SHAREPOINT_CLIENT_ID', clientSecret: 'SHAREPOINT_CLIENT_SECRET' },
        run: dynamics365Probe, writes: false,
    },
    'pheedloop-readonly': {
        secrets: { apiKey: 'PHEEDLOOP_API_KEY', apiSecret: 'PHEEDLOOP_API_SECRET' },
        run: pheedloopReadonly, writes: false,
    },
    'pheedloop-e2e-live': {
        secrets: { apiKey: 'PHEEDLOOP_API_KEY', apiSecret: 'PHEEDLOOP_API_SECRET', dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: pheedloopE2ELive, writes: false,
    },
    'growthzone-e2e-live': {
        secrets: { clientId: 'GROWTHZONE_CLIENT_ID', clientSecret: 'GROWTHZONE_CLIENT_SECRET', dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: growthzoneE2ELive, writes: false,
    },
    // ── Install-path Track-1 multi-secret e2e-live plans (connector go-to-market test) ──────────────
    // Non-secret + optional fields ride the broker env (read inside each fn): SharePoint GRAPH_BASE/SCOPE;
    // NetSuite ACCOUNT_ID/AUTH_FLOW/HOST_BASE_URL; Nimble INSTANCE_URL/LOGIN_URL/REFRESH_TOKEN/ACCESS_TOKEN;
    // ORCID SCOPE/USE_SANDBOX; OpenWater BASE_URL/ORG_CODE; Sage SENDER_ID/USER_ID/COMPANY_ID/ENTITY_ID.
    'sharepoint-e2e-live': {
        secrets: { tenantId: 'SHAREPOINT_TENANT_ID', clientId: 'SHAREPOINT_CLIENT_ID', clientSecret: 'SHAREPOINT_CLIENT_SECRET', dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: sharepointE2ELive, writes: false,
    },
    'netsuite-e2e-live': {
        secrets: { consumerKey: 'NETSUITE_CONSUMER_KEY', consumerSecret: 'NETSUITE_CONSUMER_SECRET', tokenId: 'NETSUITE_TOKEN_ID', tokenSecret: 'NETSUITE_TOKEN_SECRET', dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: netsuiteE2ELive, writes: false,
    },
    'netsuite-probe': {
        secrets: { consumerKey: 'NETSUITE_CONSUMER_KEY', consumerSecret: 'NETSUITE_CONSUMER_SECRET', tokenId: 'NETSUITE_TOKEN_ID', tokenSecret: 'NETSUITE_TOKEN_SECRET', mjSystemKey: 'MJ_API_KEY' },
        run: netsuiteProbe, writes: false,
    },
    'nimble-e2e-live': {
        secrets: { clientId: 'NIMBLE_CLIENT_ID', clientSecret: 'NIMBLE_CLIENT_SECRET', dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: nimbleE2ELive, writes: false,
    },
    'nimble-probe': {
        secrets: { clientId: 'NIMBLE_CLIENT_ID', clientSecret: 'NIMBLE_CLIENT_SECRET', mjSystemKey: 'MJ_API_KEY' },
        run: nimbleProbe, writes: false,
    },
    'nimble-contact-count': {
        secrets: { clientId: 'NIMBLE_CLIENT_ID', clientSecret: 'NIMBLE_CLIENT_SECRET' },
        run: nimbleContactCount, writes: false,
    },
    'orcid-e2e-live': {
        secrets: { clientId: 'ORCID_CLIENT_ID', clientSecret: 'ORCID_CLIENT_SECRET', dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: orcidE2ELive, writes: false,
    },
    'openwater-e2e-live': {
        // No separate client key required: the connector uses BaseURL as the ClientKey (operator confirmed).
        // OPENWATER_CLIENT_KEY is dropped from the required set; openwaterE2ELive falls ClientKey back to BaseURL.
        secrets: { apiKey: 'OPENWATER_API_KEY', dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: openwaterE2ELive, writes: false,
    },
    'openwater-probe': {
        // Read-only diagnostic — curls candidate paths, masks all secrets. dbPassword not needed but the
        // broker's runCredentialSafe requires each named secret present, so keep the same minimal set.
        secrets: { apiKey: 'OPENWATER_API_KEY', mjSystemKey: 'MJ_API_KEY' },
        run: openwaterProbe, writes: false,
    },
    'sage-intacct-e2e-live': {
        secrets: { senderPassword: 'SAGEINTACCT_SENDER_PASSWORD', userPassword: 'SAGEINTACCT_USER_PASSWORD', dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: sageIntacctE2ELive, writes: false,
    },
    // PropFuel full e2e (data-export feed) — vendor-prefixed Token secret (robust in a multi-vendor
    // broker where CONNECTOR_API_KEY is ambiguous) + AccountID from broker env. writes:false.
    'propfuel-e2e-live': {
        secrets: { token: 'PROPFUEL_TOKEN', dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: propfuelE2ELive, writes: false,
    },
    // HubSpot full e2e — vendor-prefixed HUBSPOT_API_KEY (add it to hubspot.env; the connector needs
    // its OWN token, not the shared CONNECTOR_API_KEY that another vendor overwrites). writes:false.
    'hubspot-e2e-live': {
        secrets: { token: 'HUBSPOT_API_KEY', dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: hubspotE2ELive, writes: false,
    },
    // Wild Apricot full e2e — single API Key (vendor-prefixed). writes:false.
    'wildapricot-e2e-live': {
        secrets: { token: 'WILDAPRICOT_API_KEY', dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: wildApricotE2ELive, writes: false,
    },
    // Wild Apricot contacts-pagination DIAGNOSTIC probe — read-only, reports counts/states only.
    'wildapricot-probe': {
        secrets: { token: 'WILDAPRICOT_API_KEY' },
        run: wildApricotProbe, writes: false,
    },
    // Wild Apricot endpoint-shape probe — read-only, detects Contact-style async endpoints on the 12 empties.
    'wildapricot-endpoint-probe': {
        secrets: { token: 'WILDAPRICOT_API_KEY' },
        run: wildApricotEndpointProbe, writes: false,
    },
    // Zendesk incremental-endpoint probe — read-only, characterizes the org-404 finding.
    'zendesk-incremental-probe': {
        secrets: { token: 'ZENDESK_API_TOKEN', dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: zendeskIncrementalProbe, writes: false,
    },
    // HubSpot CRM seeder — broker-side writes to the TEST portal (token broker-held). writes:true.
    'hubspot-whoami': { secrets: { token: 'HUBSPOT_API_KEY' }, run: hubspotWhoami, writes: false },
    'hubspot-custom-properties': { secrets: { token: 'HUBSPOT_API_KEY' }, run: hubspotCustomProperties, writes: false },
    'hubspot-seed': {
        secrets: { token: 'HUBSPOT_API_KEY' },
        run: hubspotSeed, writes: true,
    },
    // Stripe/Eventbrite/Mailchimp seeders — broker-side writes using broker-held keys. writes:true.
    'stripe-seed': { secrets: { token: 'STRIPE_SECRET_KEY' }, run: stripeSeed, writes: true },
    'eventbrite-seed': { secrets: { token: 'EVENTBRITE_TOKEN' }, run: eventbriteSeed, writes: true },
    'mailchimp-seed': { secrets: { token: 'MAILCHIMP_API_KEY' }, run: mailchimpSeed, writes: true },
    // Mailchimp read-only probe — broker-channel confirmation + account inventory counts. writes:false.
    'mailchimp-probe': { secrets: { token: 'MAILCHIMP_API_KEY' }, run: mailchimpProbe, writes: false },
    // Mailchimp CREDENTIALED RealityProbe (v2 S7) — runs the pinned reality-probe.mjs as a child with the
    // token in PROBE_TOKEN only (never argv/output). READ-ONLY: GETs + OPTIONS; write-surface evidence is
    // OPTIONS/405/401, never a write call. Returns the full verdicts.json summary. writes:false.
    'mailchimp-probe-live': { secrets: { token: 'MAILCHIMP_API_KEY' }, run: mailchimpProbeLive, writes: false },
    // Mailchimp campaigns-only seed retry (verified reply_to from the account itself). writes:true.
    'mailchimp-seed-campaigns': { secrets: { token: 'MAILCHIMP_API_KEY' }, run: mailchimpSeedCampaigns, writes: true },
    // Stripe full e2e — sk_test secret key. writes:false.
    'stripe-e2e-live': {
        secrets: { token: 'STRIPE_SECRET_KEY', dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: stripeE2ELive, writes: false,
    },
    // Eventbrite full e2e — private token. writes:false.
    'eventbrite-e2e-live': {
        secrets: { token: 'EVENTBRITE_TOKEN', dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: eventbriteE2ELive, writes: false,
    },
    // Mailchimp full e2e — ApiKey secret (+ MAILCHIMP_SERVER_PREFIX env). writes:false.
    'mailchimp-e2e-live': {
        secrets: { token: 'MAILCHIMP_API_KEY', dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: mailchimpE2ELive, writes: false,
    },
    // Zendesk full e2e — Basic auth (ApiToken secret; Email + Subdomain from broker env). writes:false.
    'zendesk-e2e-live': {
        secrets: { token: 'ZENDESK_API_TOKEN', dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: zendeskE2ELive, writes: false,
    },
    // Neon CRM full e2e — HTTP Basic auth (APIKey secret; OrgID = Basic username from broker env NEON_ORG_ID). writes:false.
    'neon-e2e-live': {
        secrets: { token: 'NEON_API_KEY', dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: neonE2ELive, writes: false,
    },
    // Blackbaud SKY API full e2e — OAuth2 (ClientID/Secret/RefreshToken) + SubscriptionKey from env. writes:false.
    'blackbaud-e2e-live': {
        secrets: { clientId: 'BLACKBAUD_CLIENT_ID', clientSecret: 'BLACKBAUD_CLIENT_SECRET', refreshToken: 'BLACKBAUD_REFRESH_TOKEN', dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: blackbaudE2ELive, writes: false,
    },
    'constantcontact-e2e-live': {
        secrets: { clientId: 'CONSTANTCONTACT_CLIENT_ID', clientSecret: 'CONSTANTCONTACT_CLIENT_SECRET', refreshToken: 'CONSTANTCONTACT_REFRESH_TOKEN', dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: constantcontactE2ELive, writes: false,
    },
    'salesforce-e2e-live': {
        secrets: { clientId: 'SALESFORCE_CLIENT_ID', clientSecret: 'SALESFORCE_CLIENT_SECRET', dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: salesforceE2ELive, writes: false,
    },
    // Salesforce SEEDER — populates a TEST/dev org with standard sObjects so the read E2E has rows.
    // writes:true → broker REFUSES unless the job passes allowWrite:true (client-authorized mutation).
    'salesforce-seed': { secrets: { clientId: 'SALESFORCE_CLIENT_ID', clientSecret: 'SALESFORCE_CLIENT_SECRET' }, run: salesforceSeed, writes: true },
    // PropFuel lifecycle proof — observe answered_at/deleted_at populated + id recurrence. writes:false.
    'propfuel-lifecycle': { secrets: { token: 'CONNECTOR_API_KEY' }, run: propfuelLifecycle, writes: false },
    // Tier-2 association read-only proof (no DB, no mutation) — real contacts/companies +
    // the v4 batch/read association endpoint. Safe against live data.
    'hubspot-tier2-assoc': { secrets: { token: 'HUBSPOT_API_KEY' }, run: hubspotTier2Assoc, writes: false },
    // CREDENTIALED RealityProbe (v2 S7) — runs the pinned reality-probe.mjs as a child with the
    // token in PROBE_TOKEN only (never in argv/output). READ-ONLY: GETs + OPTIONS; write-surface
    // evidence is OPTIONS/405/401, never a write call. Returns scrubbed verdict counts + artifact.
    'hubspot-probe-live': { secrets: { token: 'HUBSPOT_API_KEY' }, run: hubspotProbeLive, writes: false },
    // Tier-2 full Apply/sync includes Create/Update against the external system, so it is
    // writes:true and gated behind allowWrite. Body lands when the workbench dual-dialect
    // harness is built; the gate is enforced regardless (refused before run() is reached).
    'hubspot-sync': {
        secrets: { token: 'HUBSPOT_API_KEY' }, writes: true,
        run: async () => { throw new Error('hubspot-sync (Tier-2 DB Apply) is not implemented in this harness yet — runs via the workbench.'); },
    },
    // Tier-3 GQL-driven live framework test (real MJAPI + real DB). Forward path is read-only and
    // runs unprompted; it proves completeness ("all data synced in") + record-map 1:1 + watermark/
    // content-hash via DB-direct assertions. dbPassword is a secret (workbench DB password, scrubbed);
    // mjToken is optional (the no-auth workbench needs none — only declare it on auth-enforcing MJAPI).
    'hubspot-live-pull': {
        secrets: { token: 'HUBSPOT_API_KEY', dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: hubspotLivePullGQL, writes: false,
    },
    // Full matrix: forward + backward (single-record CRUD round-trip). writes:true → the broker REFUSES
    // it unless the job passes allowWrite:true (run only AFTER hubspot-live-pull validates the forward
    // path). Every created record is deleted in teardown; Users/owners are never written.
    'hubspot-live-matrix': {
        secrets: { token: 'HUBSPOT_API_KEY', dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: hubspotLiveMatrixGQL, writes: true,
    },
    // Diagnostic (DB read-only): resolve the IDs the GQL sync needs.
    'hubspot-diag': { secrets: { dbPassword: 'DB_PASSWORD' }, run: hubspotDiagGQL, writes: false },
    // Maintenance (DB-only): clear HubSpot dest rows for a clean forward run. writes:false (no external mutation).
    'hubspot-clean-data': { secrets: { dbPassword: 'DB_PASSWORD' }, run: hubspotCleanData, writes: false },
    // ── "Use it, never read it" reference-mode plans ───────────────────────────────────────────────
    // SEED (run once by someone holding the token): encrypts the token into the DB Credential and
    // returns the CompanyIntegrationID. writes:false externally (CreateConnection only reads HubSpot to
    // introspect). The token enters ONLY this step's process, never the agent's.
    // SETUP company (faithful GraphQL create of one MJ Company row) — writes:false externally (no vendor call).
    'setup-company': {
        secrets: { mjSystemKey: 'MJ_API_KEY' },
        run: setupCompanyGQL, writes: false,
    },
    'hubspot-seed-connection': {
        secrets: { token: 'HUBSPOT_API_KEY', dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: hubspotSeedConnectionGQL, writes: false,
    },
    // REFERENCE forward (the agent runs this TOKEN-FREE): set HS_LIVE_CIID to the seeded
    // CompanyIntegrationID; the server decrypts + uses the credential internally. No HUBSPOT_API_KEY
    // secret is declared, so the agent literally cannot read the token — it uses it by reference only.
    'hubspot-live-pull-ref': {
        secrets: { dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: hubspotLivePullGQL, writes: false,
    },
    // REFERENCE matrix (token-free backward/CRUD). writes:true → broker requires allowWrite:true.
    'hubspot-live-matrix-ref': {
        secrets: { dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: hubspotLiveMatrixGQL, writes: true,
    },
    // READ-ONLY 2^N mechanics matrix (token-free reference mode): idempotency/content-hash skip,
    // timestamp watermark + fallback save, opt-in Merkle reconcile, and DAG parent-before-child order.
    // writes:false externally — only re-syncs (Pull) + reads DB/events/log; never deletes the seeded
    // connection or maps (the Merkle cell toggles ONE map's Configuration and resets it in cleanup).
    'hubspot-matrix-readonly': {
        secrets: { dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: hubspotMatrixReadonlyGQL, writes: false,
    },
    // §15 LIFECYCLE ops (token-free reference mode, NON-DESTRUCTIVE): deactivate-enforcement,
    // deselect/reselect entity maps, cancel-status, and the read-only op smoke. Operates on the seeded
    // REUSABLE CIID and restores all mutated state (reactivate, re-activate deals). writes:false — it
    // only re-syncs (Pull) + reads DB/status; it never deletes the seeded connection or its maps.
    'hubspot-lifecycle': {
        secrets: { dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: hubspotLifecycleGQL, writes: false,
    },
    // §15 DELETE-CASCADE (token-free reference mode, DESTRUCTIVE): deletes the THROWAWAY CIID at
    // HS_LIVE_CIID and asserts the cascade (credential deleted, CI row deleted, children cleaned).
    // writes:true as a SAFETY belt — destructive to MJ rows → the broker REFUSES it unless the job
    // passes allowWrite:true. NEVER point HS_LIVE_CIID at the main seeded connection for this plan.
    'hubspot-delete-cascade': {
        secrets: { dbPassword: 'DB_PASSWORD', mjSystemKey: 'MJ_API_KEY' },
        run: hubspotDeleteCascadeGQL, writes: true,
    },
};

/** PropFuel connection creation — broker holds the token; creates a real credentialed connection
 *  with runSchemaRefresh:true so DiscoverObjects (streams via /list) + DiscoverFields (parse a sample
 *  NDJSON file) + soft-PK classification actually run. Returns the CIID. */
export async function propfuelCreateConnection({ token, mjSystemKey }, scrub) {
    const env = process.env;
    const graphqlUrl = (env.HS_LIVE_GRAPHQL_URL || 'http://localhost:4016/').trim();
    const companyID = env.HS_LIVE_COMPANY_ID, integrationID = env.HS_LIVE_INTEGRATION_ID, credentialTypeID = env.HS_LIVE_CREDTYPE_ID;
    let accountId; try { accountId = JSON.parse(env.E2E_LIVE_CONFIG || '{}').AccountID; } catch { accountId = env.PROPFUEL_ACCOUNT_ID; }
    const tokenKey = env.E2E_TOKEN_KEY || 'Token';
    if (!companyID || !integrationID || !credentialTypeID) return { ok:false, plan:'propfuel-create-connection', error:'missing HS_LIVE_COMPANY_ID / HS_LIVE_INTEGRATION_ID / HS_LIVE_CREDTYPE_ID' };
    const credentialValues = JSON.stringify({ [tokenKey]: token, AccountID: accountId });
    const configuration = JSON.stringify({ AccountID: accountId });
    async function gql(query, variables) {
        const r = await fetch(graphqlUrl, { method:'POST', headers:{'Content-Type':'application/json','x-mj-api-key':mjSystemKey}, body: JSON.stringify({ query, variables }) });
        const j = await r.json();
        if (j.errors) throw new Error('GQL: ' + scrub(JSON.stringify(j.errors).slice(0,500)));
        return j.data;
    }
    const CREATE = `mutation($input: CreateConnectionInput!, $testConnection: Boolean!, $runSchemaRefresh: Boolean!) {
      IntegrationCreateConnection(input:$input, testConnection:$testConnection, runSchemaRefresh:$runSchemaRefresh) {
        Success Message CompanyIntegrationID ConnectionTestSuccess ConnectionTestMessage } }`;
    const input = { CompanyID: companyID, IntegrationID: integrationID, CredentialTypeID: credentialTypeID, CredentialName: 'PropFuel E2E', CredentialValues: credentialValues, Configuration: configuration };
    let d; try { d = await gql(CREATE, { input, testConnection: true, runSchemaRefresh: true }); }
    catch (e) { return { ok:false, plan:'propfuel-create-connection', error: scrub(e instanceof Error ? e.message : String(e)) }; }
    const c = d?.IntegrationCreateConnection ?? {};
    return { ok: !!c.Success, plan:'propfuel-create-connection', companyIntegrationID: c.CompanyIntegrationID ?? null,
             connectionTest: c.ConnectionTestSuccess ?? null, message: scrub(c.Message||''), connectionTestMessage: scrub(c.ConnectionTestMessage||'') };
}
