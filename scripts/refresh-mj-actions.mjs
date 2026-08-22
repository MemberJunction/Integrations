#!/usr/bin/env node
/**
 * refresh-mj-actions.mjs — snapshot the MemberJunction core Actions catalog into this repo.
 *
 * WHY THIS EXISTS
 * The overview pages (docs/marketing.html) advertise the platform's ready-made Actions
 * alongside this repo's connectors, but the Actions live in a DIFFERENT repository
 * (MemberJunction/MJ, metadata/actions/**). The docs workflow runs inside THIS repo and
 * cannot see that checkout, so the action list is snapshotted into docs/data/mj-actions.json
 * and committed. This script is the only way that file is produced — it is MANUAL, run by a
 * human with an MJ checkout on disk, not by CI.
 *
 *   node scripts/refresh-mj-actions.mjs /path/to/MJ
 *
 * DETERMINISM
 * The snapshot is stamped with the MJ commit SHA and its COMMITTER DATE, never Date.now().
 * Re-running against the same MJ commit must produce a byte-identical file, otherwise every
 * refresh would churn the generated HTML and the docs workflow would commit noise forever.
 */

import { existsSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const REPO_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const OUT_PATH = path.join(REPO_ROOT, 'docs', 'data', 'mj-actions.json');

/**
 * Vendor-facing action packs: categories that represent an outside system rather than a
 * platform capability. On the marketing page these fold into the integrations grid — either
 * as their own card (no connector exists) or as a "+N ready-made actions" chip on the
 * connector card that already covers that vendor.
 *
 *   display  — marketing name for the vendor
 *   group    — which marketing section the card belongs to when it has no connector
 *   connector— repoSubpath of the connector that already covers this vendor, if any
 */
const VENDOR_PACKS = {
  'Buffer': { display: 'Buffer', group: 'Social Media' },
  'Hootsuite': { display: 'Hootsuite', group: 'Social Media' },
  'Facebook': { display: 'Facebook', group: 'Social Media' },
  'Instagram': { display: 'Instagram', group: 'Social Media' },
  'LinkedIn': { display: 'LinkedIn', group: 'Social Media' },
  'TikTok': { display: 'TikTok', group: 'Social Media' },
  'Twitter': { display: 'X (Twitter)', group: 'Social Media' },
  'YouTube': { display: 'YouTube', group: 'Social Media' },
  'Typeform': { display: 'Typeform', group: 'Forms & Surveys' },
  'JotForm': { display: 'Jotform', group: 'Forms & Surveys' },
  'SurveyMonkey': { display: 'SurveyMonkey', group: 'Forms & Surveys' },
  'Google Forms': { display: 'Google Forms', group: 'Forms & Surveys' },
  'LearnWorlds': { display: 'LearnWorlds', group: 'Learning' },
  'YourMembership': { display: 'YourMembership', group: 'Association Management' },
  'Sage Intacct': { display: 'Sage Intacct', group: 'Finance & Accounting' },
  'Data Enrichment': { display: 'Apollo', group: 'CRM & Fundraising' },
  'QuickBooks': { display: 'QuickBooks', group: 'Finance & Accounting', connector: 'Finance/QuickBooks' },
  'Business Central': { display: 'Microsoft Dynamics 365 Business Central', group: 'Finance & Accounting', connector: 'Finance/BusinessCentral' },
  'Salesforce': { display: 'Salesforce', group: 'CRM & Fundraising', connector: 'CRM/Salesforce' },
  'HubSpot': { display: 'HubSpot', group: 'CRM & Fundraising', connector: 'CRM/HubSpot' },
  'Rasa.io': { display: 'rasa.io', group: 'Marketing & Engagement', connector: 'Marketing/Rasa' },
};

/**
 * Platform capability groups. Everything not in VENDOR_PACKS lands here, in this order.
 * `sources` lists the MJ category names that feed the group; uncategorized actions are
 * routed by the explicit UNCATEGORIZED map below (never by keyword guessing, so the
 * grouping cannot drift when MJ adds an action).
 */
const PLATFORM_GROUPS = [
  { name: 'Data & records', sources: ['Data', 'Database Design'] },
  { name: 'AI & agents', sources: ['AI', 'Agent Management'] },
  { name: 'Lists & audiences', sources: [] },
  { name: 'Documents & files', sources: ['File Storage'] },
  { name: 'Communication', sources: ['Communication'] },
  { name: 'Integration & APIs', sources: ['MCP'] },
  { name: 'Web & research', sources: ['Web'] },
  { name: 'Workflow control', sources: [] },
  { name: 'Machine learning', sources: [] },
  { name: 'E-signature', sources: ['eSignature'] },
  { name: 'Utilities', sources: ['Utilities', 'User Management', 'System', 'Demo'] },
];

/** Explicit home for every action MJ ships without a CategoryID. */
const UNCATEGORIZED = {
  'API Rate Limiter': 'Integration & APIs',
  'GraphQL Query': 'Integration & APIs',
  'HTTP Request': 'Integration & APIs',
  'OAuth Flow': 'Integration & APIs',
  'Add Document Content': 'Documents & files',
  'Create Document': 'Documents & files',
  'Excel Reader': 'Documents & files',
  'File Compress': 'Documents & files',
  'Finalize Document': 'Documents & files',
  'Gamma Generate Presentation': 'Documents & files',
  'Modify Document Section': 'Documents & files',
  'PDF Extractor': 'Documents & files',
  'Preview Document': 'Documents & files',
  'Add View Results To List': 'Lists & audiences',
  'Bulk Update List Item Status': 'Lists & audiences',
  'Compose Lists': 'Lists & audiences',
  'Invite To List': 'Lists & audiences',
  'Materialize List From View': 'Lists & audiences',
  'Move List Members': 'Lists & audiences',
  'Refresh List From Source': 'Lists & audiences',
  'Resolve Audience': 'Lists & audiences',
  'Revoke List Invitation': 'Lists & audiences',
  'Share List': 'Lists & audiences',
  'Unshare List': 'Lists & audiences',
  'Aggregate Data': 'Data & records',
  'CSV Parser': 'Data & records',
  'Data Mapper': 'Data & records',
  'Get Records': 'Data & records',
  'JSON Transform': 'Data & records',
  'XML Parser': 'Data & records',
  'Autotag and Vectorize Content': 'AI & agents',
  'Execute AI Prompt': 'AI & agents',
  'Vectorize Entity': 'AI & agents',
  'Conditional': 'Workflow control',
  'Delay': 'Workflow control',
  'Loop': 'Workflow control',
  'Parallel Execute': 'Workflow control',
  'Retry': 'Workflow control',
  'Promote ML Model': 'Machine learning',
  'Run Experiment Session': 'Machine learning',
  'Schedule Model Scoring': 'Machine learning',
  'Score Record Set': 'Machine learning',
  'Train ML Model': 'Machine learning',
  'Slack Webhook': 'Communication',
  'Teams Webhook': 'Communication',
  'Perplexity Search': 'Web & research',
  'Password Strength': 'Utilities',
};

/** Communication provider package dir -> the name a client would recognise. */
const COMMUNICATION_PROVIDERS = {
  sendgrid: 'SendGrid',
  gmail: 'Gmail',
  MSGraph: 'Microsoft Outlook (Graph)',
  twilio: 'Twilio',
  'expo-push': 'Mobile push (Expo)',
};

/** MJStorage driver file -> the name a client would recognise. */
const STORAGE_DRIVERS = {
  'AWSFileStorage.ts': 'Amazon S3',
  'AzureFileStorage.ts': 'Azure Blob Storage',
  'BoxFileStorage.ts': 'Box',
  'DropboxFileStorage.ts': 'Dropbox',
  'GoogleDriveFileStorage.ts': 'Google Drive',
  'GoogleFileStorage.ts': 'Google Cloud Storage',
  'SharePointFileStorage.ts': 'SharePoint',
};

function walkJson(dir, out = []) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walkJson(full, out);
    else if (entry.name.endsWith('.json')) out.push(full);
  }
  return out.sort();
}

/** CategoryID looks like `@lookup:MJ: Action Categories.Name=Typeform&Parent=Form Builders?create&...` */
function parseCategory(categoryId) {
  if (!categoryId) return { name: null, parent: null };
  const name = /Name=([^&?]+)/.exec(categoryId);
  const parent = /[&?]Parent=([^&?]+)/.exec(categoryId);
  return { name: name ? name[1].trim() : null, parent: parent ? parent[1].trim() : null };
}

function main() {
  const mjRoot = process.argv[2];
  if (!mjRoot) {
    console.error('usage: node scripts/refresh-mj-actions.mjs /path/to/MJ');
    process.exit(1);
  }
  const actionsDir = path.join(mjRoot, 'metadata', 'actions');
  if (!existsSync(actionsDir)) {
    console.error(`Not an MJ checkout — no metadata/actions under ${mjRoot}`);
    process.exit(1);
  }

  // Commit identity of the snapshot. Committer date (%cs, YYYY-MM-DD) rather than the clock,
  // so the same MJ commit always yields the same bytes.
  const git = (...args) => execFileSync('git', ['-C', mjRoot, ...args], { encoding: 'utf8' }).trim();
  const commit = git('rev-parse', '--short', 'HEAD');
  const capturedAt = git('log', '-1', '--format=%cs');

  /** @type {Map<string, {name:string,parent:string|null,actions:{name:string,description:string}[]}>} */
  const byCategory = new Map();
  let totalRecords = 0;
  let activeRecords = 0;

  for (const file of walkJson(actionsDir)) {
    let parsed;
    try {
      parsed = JSON.parse(readFileSync(file, 'utf8'));
    } catch (err) {
      console.error(`Unparseable action metadata: ${path.relative(mjRoot, file)} — ${err.message}`);
      process.exit(1);
    }
    for (const record of Array.isArray(parsed) ? parsed : [parsed]) {
      const fields = record?.fields;
      if (!fields?.Name) continue;
      totalRecords++;
      if (fields.Status !== 'Active') continue;
      activeRecords++;

      const { name: catName, parent } = parseCategory(fields.CategoryID);
      const key = catName ?? '(uncategorized)';
      if (!byCategory.has(key)) byCategory.set(key, { name: key, parent, actions: [] });
      byCategory.get(key).actions.push({
        name: fields.Name,
        description: (fields.Description ?? '').replace(/\s+/g, ' ').trim(),
      });
    }
  }

  // Split into vendor packs (fold into the integrations grid) and platform groups (the
  // "ready-made actions" band). Uncategorized actions are routed one by one.
  const vendorPacks = [];
  /** @type {Map<string, {name:string,actions:{name:string,description:string}[]}>} */
  const platformGroups = new Map(PLATFORM_GROUPS.map((g) => [g.name, { name: g.name, actions: [] }]));
  const sourceToGroup = new Map();
  for (const group of PLATFORM_GROUPS) for (const src of group.sources) sourceToGroup.set(src, group.name);

  const unrouted = [];
  for (const [key, category] of [...byCategory.entries()].sort(([a], [b]) => a.localeCompare(b))) {
    const vendor = VENDOR_PACKS[key];
    if (vendor) {
      vendorPacks.push({
        category: key,
        display: vendor.display,
        group: vendor.group,
        connector: vendor.connector ?? null,
        actionCount: category.actions.length,
        actions: category.actions.slice().sort((a, b) => a.name.localeCompare(b.name)),
      });
      continue;
    }
    if (key === '(uncategorized)') {
      for (const action of category.actions) {
        const target = UNCATEGORIZED[action.name];
        if (!target) { unrouted.push(action.name); continue; }
        platformGroups.get(target).actions.push(action);
      }
      continue;
    }
    const target = sourceToGroup.get(key);
    if (!target) { unrouted.push(`${key} (category)`); continue; }
    platformGroups.get(target).actions.push(...category.actions);
  }

  // Fail loud: an unrouted action would silently vanish from the marketing page, and a
  // silently-shrinking action count is exactly the kind of quiet inaccuracy these pages exist
  // to avoid. Add the name to UNCATEGORIZED (or the category to PLATFORM_GROUPS) and re-run.
  if (unrouted.length) {
    console.error('Unrouted actions/categories — add them to UNCATEGORIZED or PLATFORM_GROUPS:');
    for (const name of unrouted.sort()) console.error(`  - ${name}`);
    process.exit(1);
  }

  const providers = readdirSync(path.join(mjRoot, 'packages', 'Communication', 'providers'), { withFileTypes: true })
    .filter((e) => e.isDirectory() && COMMUNICATION_PROVIDERS[e.name])
    .map((e) => COMMUNICATION_PROVIDERS[e.name])
    .sort();
  const storage = readdirSync(path.join(mjRoot, 'packages', 'MJStorage', 'src', 'drivers'))
    .filter((f) => STORAGE_DRIVERS[f])
    .map((f) => STORAGE_DRIVERS[f])
    .sort();

  const snapshot = {
    schemaVersion: 1,
    source: { repo: 'MemberJunction/MJ', path: 'metadata/actions', commit, capturedAt },
    actionCount: activeRecords,
    vendorPacks: vendorPacks.sort((a, b) => a.display.localeCompare(b.display)),
    platformGroups: PLATFORM_GROUPS.map((g) => platformGroups.get(g.name))
      .filter((g) => g.actions.length)
      .map((g) => ({
        name: g.name,
        actionCount: g.actions.length,
        actions: g.actions.slice().sort((a, b) => a.name.localeCompare(b.name)),
      })),
    communicationProviders: providers,
    fileStorageProviders: storage,
  };

  writeFileSync(OUT_PATH, `${JSON.stringify(snapshot, null, 2)}\n`);
  const vendorActions = vendorPacks.reduce((n, p) => n + p.actionCount, 0);
  console.log(
    `Wrote docs/data/mj-actions.json — ${activeRecords} active actions of ${totalRecords} records ` +
      `(${vendorPacks.length} vendor packs / ${vendorActions} actions, ` +
      `${snapshot.platformGroups.length} platform groups) from MJ ${commit} (${capturedAt}).`,
  );
}

main();
