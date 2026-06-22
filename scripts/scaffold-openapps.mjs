#!/usr/bin/env node
/**
 * Scaffolds (or refreshes) the per-connector Open App directories in this repo from the
 * MemberJunction core integration metadata. Each connector becomes an installable Open App
 * under <Category>/<AppDir>/ with:
 *   - mj-app.json          (connector profile: metadata.processOnInstall, no schema/migrations)
 *   - metadata/.mj-sync.json + integration/ + actions/   (the curated IO/IOF catalog + Actions)
 *
 * Every connector references the SAME shared package @memberjunction/integration-connectors;
 * only the seeded metadata differs per connector. The connector CODE lives in
 * packages/integration-connectors and is moved/maintained separately.
 *
 * Source of truth for the metadata is the MJ repo's metadata/integrations + metadata/actions:
 *   MJ_METADATA_DIR=/path/to/MJ/metadata node scripts/scaffold-openapps.mjs
 *
 * This is a one-time extraction helper (and a refresh tool). It is idempotent: re-running
 * overwrites the generated mj-app.json + metadata for each connector. HubSpot is committed by
 * hand as the worked reference and is skipped unless --include-hubspot is passed.
 */
import { readFileSync, writeFileSync, mkdirSync, existsSync, readdirSync, copyFileSync, statSync } from 'node:fs';
import { join, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';

const REPO_ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const MJ_METADATA_DIR = process.env.MJ_METADATA_DIR || process.argv.find((a) => a.startsWith('--source='))?.slice(9);
const INCLUDE_HUBSPOT = process.argv.includes('--include-hubspot');
const REPO_URL = 'https://github.com/MemberJunction/Integrations';
const MJ_VERSION_RANGE = '>=5.43.0 <6.0.0';
const SHARED_PACKAGE = '@memberjunction/integration-connectors';

if (!MJ_METADATA_DIR || !existsSync(MJ_METADATA_DIR)) {
  console.error('Set MJ_METADATA_DIR (or --source=) to the MJ repo metadata/ directory.');
  process.exit(1);
}

/**
 * Per-connector placement + branding. Keyed by the Integration `Name` exactly as it appears
 * in the metadata. category → top-level repo folder; appDir → the connector folder name;
 * color is an optional #RRGGBB accent. Connectors absent here fall back to Platform/derived.
 */
const CONNECTORS = {
  'HubSpot': { category: 'CRM', appDir: 'HubSpot', color: '#ff7a59' },
  'Salesforce': { category: 'CRM', appDir: 'Salesforce', color: '#00a1e0' },
  'Neon CRM': { category: 'CRM', appDir: 'NeonCRM' },
  'Microsoft Dynamics 365 (Dataverse)': { category: 'CRM', appDir: 'DynamicsDataverse' },
  'Blackbaud': { category: 'CRM', appDir: 'Blackbaud' },
  'Aptify': { category: 'AMS', appDir: 'Aptify' },
  'iMIS': { category: 'AMS', appDir: 'iMIS' },
  'Nimble AMS': { category: 'AMS', appDir: 'NimbleAMS' },
  'Novi AMS': { category: 'AMS', appDir: 'Novi' },
  'NetForum Enterprise': { category: 'AMS', appDir: 'NetForum' },
  'Fonteva': { category: 'AMS', appDir: 'Fonteva' },
  'GrowthZone': { category: 'AMS', appDir: 'GrowthZone' },
  'Rhythm Software': { category: 'AMS', appDir: 'Rhythm' },
  'MemberSuite': { category: 'AMS', appDir: 'MemberSuite' },
  'Wicket': { category: 'AMS', appDir: 'Wicket' },
  'Wild Apricot': { category: 'AMS', appDir: 'WildApricot' },
  'YourMembership': { category: 'AMS', appDir: 'YourMembership' },
  'Path LMS': { category: 'LMS', appDir: 'PathLMS' },
  'Reach360': { category: 'LMS', appDir: 'Reach360' },
  'Mailchimp': { category: 'Marketing', appDir: 'Mailchimp', color: '#ffe01b' },
  'Constant Contact': { category: 'Marketing', appDir: 'ConstantContact' },
  'MagnetMail': { category: 'Marketing', appDir: 'MagnetMail' },
  'Rasa.io': { category: 'Marketing', appDir: 'Rasa' },
  'PropFuel': { category: 'Marketing', appDir: 'PropFuel' },
  'QuickBooks': { category: 'Finance', appDir: 'QuickBooks', color: '#2ca01c' },
  'Sage Intacct': { category: 'Finance', appDir: 'SageIntacct' },
  'NetSuite': { category: 'Finance', appDir: 'NetSuite' },
  'Cvent': { category: 'Events', appDir: 'Cvent' },
  'PheedLoop': { category: 'Events', appDir: 'PheedLoop' },
  'OpenWater': { category: 'Events', appDir: 'OpenWater' },
  'SharePoint': { category: 'Platform', appDir: 'SharePoint' },
  'ORCID': { category: 'Platform', appDir: 'ORCID' },
  'MJ to MJ': { category: 'Platform', appDir: 'MJtoMJ' },
};

/** Lowercase-kebab slug used for the app `name` and tags. */
function slugify(name) {
  return name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
}

/** Clamp a description to the manifest's 10–500 char rule (with a safe fallback). */
function clampDescription(text, name) {
  const fallback = `${name} connector for MemberJunction — full curated object catalog.`;
  const d = (text && text.trim().length >= 10 ? text.trim() : fallback);
  return d.length > 500 ? d.slice(0, 497).trimEnd() + '…' : d;
}

/** Collect every integration metadata file: root dotfiles + workshop subdirs. */
function findIntegrationFiles() {
  const dir = join(MJ_METADATA_DIR, 'integrations');
  const out = [];
  for (const f of readdirSync(dir)) {
    if (f.startsWith('.') && f.endsWith('.json') && !['.integrations.json', '.mj-sync.json', '.betty.json'].includes(f)) {
      out.push(join(dir, f));
    }
    const sub = join(dir, f);
    if (!f.startsWith('.') && existsSync(sub) && statSync(sub).isDirectory()) {
      const m = readdirSync(sub).find((x) => x.endsWith('.integration.json'));
      if (m) out.push(join(sub, m));
    }
  }
  return out;
}

/** Read the top-level Integration record's fields from a metadata file. */
function readIntegration(file) {
  const raw = JSON.parse(readFileSync(file, 'utf-8'));
  const recs = Array.isArray(raw) ? raw : [raw];
  for (const r of recs) {
    if (r?.fields?.ClassName) return r.fields;
  }
  return null;
}

/** Locate a connector's generated actions file, if any. */
function findActionsFile(slug) {
  const dir = join(MJ_METADATA_DIR, 'actions', 'integrations-auto-generated');
  if (!existsSync(dir)) return null;
  const candidates = [`.${slug}-actions.json`, ...readdirSync(dir).filter((f) => f.endsWith('-actions.json'))];
  for (const c of candidates) {
    if (existsSync(join(dir, c)) && c.includes(slug.split('-')[0])) return join(dir, c);
  }
  return null;
}

const writeJson = (p, obj) => { mkdirSync(dirname(p), { recursive: true }); writeFileSync(p, JSON.stringify(obj, null, 2) + '\n', 'utf-8'); };

let made = 0;
for (const file of findIntegrationFiles()) {
  const fields = readIntegration(file);
  if (!fields) { console.warn(`skip (no Integration record): ${file}`); continue; }
  const name = fields.Name;
  if (name === 'HubSpot' && !INCLUDE_HUBSPOT) { continue; } // hand-authored reference
  const placement = CONNECTORS[name] || { category: 'Platform', appDir: name.replace(/[^A-Za-z0-9]+/g, '') };
  const slug = slugify(name);
  const appName = `connector-${slug}`;
  const appRoot = join(REPO_ROOT, placement.category, placement.appDir);
  const metaRoot = join(appRoot, 'metadata');

  // mj-app.json (connector profile — no schema, no migrations)
  const manifest = {
    $schema: 'https://memberjunction.org/schemas/mj-app.schema.json',
    manifestVersion: 1,
    name: appName,
    displayName: `${name} Connector`,
    description: clampDescription(fields.Description, name),
    version: '1.0.0',
    license: 'ISC',
    ...(fields.Icon ? { icon: fields.Icon } : {}),
    ...(placement.color ? { color: placement.color } : {}),
    publisher: { name: 'MemberJunction', email: 'dev@memberjunction.com', url: 'https://memberjunction.com' },
    repository: REPO_URL,
    mjVersionRange: MJ_VERSION_RANGE,
    metadata: { directory: 'metadata', processOnInstall: true },
    packages: { server: [{ name: SHARED_PACKAGE, role: 'bootstrap', startupExport: 'registerConnectors' }] },
    categories: [placement.category.toLowerCase()],
    tags: [slug, placement.category.toLowerCase(), 'connector', 'integration'].slice(0, 20),
  };
  writeJson(join(appRoot, 'mj-app.json'), manifest);

  // metadata/.mj-sync.json — push integration before actions
  writeJson(join(metaRoot, '.mj-sync.json'), { directoryOrder: ['integration', 'actions'] });

  // metadata/integration/ — copy the curated catalog, normalizing ImportPath to the ONE
  // shared package (older workshop-built connectors carry aspirational per-connector paths).
  writeJson(join(metaRoot, 'integration', '.mj-sync.json'), { entity: 'MJ: Integrations', filePattern: '**/.*.json', defaults: {} });
  const integRaw = JSON.parse(readFileSync(file, 'utf-8'));
  const integRecs = Array.isArray(integRaw) ? integRaw : [integRaw];
  for (const r of integRecs) {
    if (r?.fields?.ClassName) r.fields.ImportPath = SHARED_PACKAGE;
  }
  writeJson(join(metaRoot, 'integration', `.${slug}.integration.json`), Array.isArray(integRaw) ? integRaw : integRecs[0]);

  // metadata/actions/ (only if the connector has generated actions)
  const actionsFile = findActionsFile(slug);
  if (actionsFile) {
    writeJson(join(metaRoot, 'actions', '.mj-sync.json'), {
      entity: 'MJ: Actions',
      filePattern: '**/.*.json',
      defaults: {},
      lookupFields: { CategoryID: { entity: 'MJ: Action Categories', field: 'Name' } },
      relatedEntities: {
        'MJ: Action Params': { entity: 'MJ: Action Params', foreignKey: 'ActionID' },
        'MJ: Action Result Codes': { entity: 'MJ: Action Result Codes', foreignKey: 'ActionID' },
      },
    });
    copyFileSync(actionsFile, join(metaRoot, 'actions', `.${slug}-actions.json`));
  }

  made++;
  console.log(`✓ ${placement.category}/${placement.appDir}  (${appName}${actionsFile ? ', +actions' : ''})`);
}
console.log(`\nScaffolded ${made} connector Open App(s) into ${REPO_ROOT}.`);
