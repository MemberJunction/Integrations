#!/usr/bin/env node
/**
 * build-readme-directory.mjs — deterministically generates and maintains the
 * "Full Integration Directory" section inside the root README.md between:
 *   <!-- BEGIN GENERATED CONNECTOR DIRECTORY -->
 *   <!-- END GENERATED CONNECTOR DIRECTORY -->
 *
 * Sources of truth:
 *   - connectors-catalog.json (published, installable Open App connectors)
 *   - scripts/connector-publish-scope.json (published vs held connectors)
 *   - docs/data/marketing-names.json (clean vendor display names & descriptions)
 *   - <Category>/<Connector>/docs/SUPPORT.md & docs/credential-setup.html
 *   - Shared/* and Platform/* code-only helper/primitive packages
 *
 * Usage:
 *   node scripts/build-readme-directory.mjs           # update README.md in place
 *   node scripts/build-readme-directory.mjs --check   # CI gate: exit 1 if README.md is stale
 */

import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const REPO_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const README_PATH = path.join(REPO_ROOT, 'README.md');
const CHECK = process.argv.includes('--check');

const BEGIN_MARKER = '<!-- BEGIN GENERATED CONNECTOR DIRECTORY -->';
const END_MARKER = '<!-- END GENERATED CONNECTOR DIRECTORY -->';

const CATEGORY_META = {
  AMS: {
    title: 'AMS — Association Management Systems',
    blurb: 'Member records, dues, committees, chapters, certifications, orders, and association operations.',
  },
  CRM: {
    title: 'CRM — Customer Relationship Management & Fundraising',
    blurb: 'Accounts, contacts, leads, opportunities, constituents, donations, and custom CRM objects.',
  },
  Events: {
    title: 'Events — Conferences, Registration, Abstracts & Awards',
    blurb: 'Events, attendees, sessions, speakers, exhibitors, submissions, judging, and badge/ticket management.',
  },
  Finance: {
    title: 'Finance — Accounting, ERP, Billing & Payments',
    blurb: 'General ledger, invoices, bills, payments, subscriptions, customers, vendors, and ERP records.',
  },
  LMS: {
    title: 'LMS — Learning Management & Credentialing',
    blurb: 'Courses, learners, enrollments, completions, CEUs/credits, badges, competencies, and hierarchies.',
  },
  Marketing: {
    title: 'Marketing — Email, Automation, Engagement & Analytics',
    blurb: 'Campaigns, mailings, subscribers, recipient-level sends/opens/clicks/bounces, lists, and web analytics.',
  },
  PM: {
    title: 'PM — Project & Time Management',
    blurb: 'Workspaces, projects, tasks, subtasks, assignments, and time-tracking records.',
  },
  Platform: {
    title: 'Platform — Community, Content, Support, Databases & Data Warehouses',
    blurb: 'Online communities, forums, CMS, help desks, document libraries, research registries, and live-introspected SQL/NoSQL databases.',
  },
};

const PRIMITIVE_PACKAGES = [
  {
    subpath: 'Shared/SchemaMerge',
    kind: 'Shared Helper',
    purpose: 'Pure helper (`mergeDeclaredWithSampledFields`) that unions a connector’s declared field catalog with a live data-measured streaming sample during `IntrospectSchema`.',
  },
  {
    subpath: 'Shared/IdWindowScan',
    kind: 'Shared Helper',
    purpose: 'Resumable, budget-aware numeric ID window scanner (`runIdWindowScan`) with automatic window bisection for vendor endpoints that cannot bulk-list objects.',
  },
  {
    subpath: 'Platform/RelationalDB',
    kind: 'Base Connector Primitive',
    purpose: 'Abstract base connector for relational database engines (`SQLServer`, `PostgreSQL`, `MySQL`, `Oracle`, `Snowflake`) with live `INFORMATION_SCHEMA` introspection.',
  },
  {
    subpath: 'Platform/FileFeed',
    kind: 'Base Connector Primitive',
    purpose: 'Generic flat-file and feed ingestion connector primitive for CSV/JSON/delimited data streams.',
  },
];

const RE_TIER =
  /^> \*\*Evidence tier:\*\* (🥇|🟢|⚙️|⚙|🧪|🟡)\s*([^(]+?)\s*\(([^)]*)\)\s*·\s*\*\*Last verified:\*\* (\d{4}-\d{2}-\d{2})/mu;

function readJson(relPath) {
  return JSON.parse(readFileSync(path.join(REPO_ROOT, relPath), 'utf8'));
}

function parseSupportSummary(subpath) {
  const supportFile = path.join(REPO_ROOT, subpath, 'docs', 'SUPPORT.md');
  if (!existsSync(supportFile)) return null;
  const text = readFileSync(supportFile, 'utf8');
  const isBaseline = /baseline-stub:/.test(text);
  const match = RE_TIER.exec(text);
  if (!match) return { emoji: '📄', label: 'Documented', isBaseline };
  const emoji = match[1] === '⚙' ? '⚙️' : match[1];
  const label = isBaseline ? 'Baseline' : match[2].trim();
  return { emoji, label, isBaseline };
}

function cleanDescription(raw) {
  let s = String(raw ?? '').replace(/\s+/g, ' ').trim();
  if (!s) return 'Vendor integration connector for MemberJunction.';
  // Keep up to the first sentence if the raw description is long (> 165 chars)
  if (s.length > 165) {
    const firstSentenceEnd = s.search(/\.(?:\s|$)/);
    if (firstSentenceEnd !== -1 && firstSentenceEnd <= 180) {
      s = s.slice(0, firstSentenceEnd + 1);
    } else {
      const cut = s.slice(0, 162);
      const lastSpace = cut.lastIndexOf(' ');
      s = `${(lastSpace > 80 ? cut.slice(0, lastSpace) : cut).replace(/[,;:\s—-]+$/, '')}…`;
    }
  }
  return s.replace(/\|/g, '\\|');
}

function githubAnchor(heading) {
  return heading
    .toLowerCase()
    .replace(/[^\w\s-]/g, '')
    .trim()
    .replace(/\s/g, '-');
}

export function generateConnectorDirectoryMarkdown() {
  const catalog = readJson('connectors-catalog.json');
  const scope = readJson('scripts/connector-publish-scope.json');
  const marketing = readJson('docs/data/marketing-names.json');

  const catalogBySubpath = new Map(catalog.connectors.map((c) => [c.repoSubpath, c]));
  const publishedConnectors = [];
  const heldConnectors = [];

  for (const subpath of scope.publish) {
    const entry = catalogBySubpath.get(subpath);
    if (!entry) continue;
    const override = marketing.connectors[subpath] ?? {};
    const vendorName =
      override.marketingName ??
      (/^[A-Z]/.test(entry.name) ? entry.name : entry.displayName.replace(/ Connector$/, ''));
    const description = cleanDescription(override.marketingDescription ?? entry.description);
    const support = parseSupportSummary(subpath);
    const hasSetup = existsSync(path.join(REPO_ROOT, subpath, 'docs', 'credential-setup.html'));

    publishedConnectors.push({
      subpath,
      category: entry.category,
      vendorName,
      npmPackage: entry.npmPackage,
      version: entry.version,
      objectCount: entry.objectCount,
      installTag: entry.installTag,
      description,
      support,
      hasSetup,
    });
  }

  for (const subpath of scope.hold) {
    const pkg = readJson(`${subpath}/package.json`);
    const appPath = path.join(REPO_ROOT, subpath, 'mj-app.json');
    const app = existsSync(appPath) ? readJson(`${subpath}/mj-app.json`) : {};
    const override = marketing.connectors[subpath] ?? {};
    const category = subpath.split('/')[0];
    const vendorName =
      override.marketingName ??
      (app.displayName ? app.displayName.replace(/ Connector$/, '') : path.basename(subpath));
    const description = cleanDescription(override.marketingDescription ?? app.description ?? pkg.description);
    const support = parseSupportSummary(subpath);
    const hasSetup = existsSync(path.join(REPO_ROOT, subpath, 'docs', 'credential-setup.html'));

    heldConnectors.push({
      subpath,
      category,
      vendorName,
      npmPackage: pkg.name,
      version: pkg.version,
      description,
      support,
      hasSetup,
    });
  }

  const categories = Object.keys(CATEGORY_META).filter((cat) =>
    publishedConnectors.some((c) => c.category === cat),
  );

  const totalObjects = publishedConnectors.reduce((sum, c) => sum + (c.objectCount ?? 0), 0);

  const lines = [];
  lines.push(BEGIN_MARKER);
  lines.push('');
  lines.push(
    `> **Auto-maintained by CI** (\`scripts/build-readme-directory.mjs\`) from [\`connectors-catalog.json\`](./connectors-catalog.json), [\`scripts/connector-publish-scope.json\`](./scripts/connector-publish-scope.json), and per-connector metadata.`,
  );
  lines.push(
    `> **${publishedConnectors.length} published Open App connectors** across **${categories.length} categories** (${totalObjects.toLocaleString('en-US')}+ declared integration objects, plus live-introspected database/CRM schemas), **${PRIMITIVE_PACKAGES.length} shared/base packages**, and **${heldConnectors.length} held connectors**.`,
  );
  lines.push('');

  // Quick category jump links
  const jumpLinks = categories.map((cat) => {
    const count = publishedConnectors.filter((c) => c.category === cat).length;
    const anchor = githubAnchor(CATEGORY_META[cat].title);
    return `[**${cat}** (${count})](#${anchor})`;
  });
  jumpLinks.push(`[**Shared & Primitives** (${PRIMITIVE_PACKAGES.length})](#${githubAnchor('Shared Libraries & Platform Primitives')})`);
  jumpLinks.push(`[**Held / In Development** (${heldConnectors.length})](#${githubAnchor('Held / In-Development Connectors')})`);
  lines.push(jumpLinks.join(' · '));
  lines.push('');

  for (const cat of categories) {
    const meta = CATEGORY_META[cat] ?? { title: cat, blurb: '' };
    const list = publishedConnectors
      .filter((c) => c.category === cat)
      .sort((a, b) => a.vendorName.localeCompare(b.vendorName, 'en', { sensitivity: 'base' }));

    lines.push(`### ${meta.title}`);
    lines.push('');
    if (meta.blurb) {
      lines.push(`${meta.blurb} (${list.length} connectors)`);
      lines.push('');
    }
    lines.push('| Connector | npm Package | Version | Objects | Docs & Evidence | Description |');
    lines.push('|-----------|-------------|---------|--------:|-----------------|-------------|');

    for (const c of list) {
      const objCell = c.objectCount != null && c.objectCount > 0 ? c.objectCount.toLocaleString('en-US') : 'Live schema';
      const docLinks = [];
      if (c.support) {
        docLinks.push(`[${c.support.emoji} ${c.support.label}](./${c.subpath}/docs/SUPPORT.md)`);
      }
      if (c.hasSetup) {
        docLinks.push(`[Setup](./${c.subpath}/docs/credential-setup.html)`);
      }
      const docsCell = docLinks.length > 0 ? docLinks.join(' · ') : '—';
      lines.push(
        `| [**${c.vendorName}**](./${c.subpath}) | \`${c.npmPackage}\` | \`${c.version}\` | ${objCell} | ${docsCell} | ${c.description} |`,
      );
    }
    lines.push('');
  }

  // Shared Libraries & Platform Primitives
  lines.push('### Shared Libraries & Platform Primitives');
  lines.push('');
  lines.push(
    'Code-only packages and base connector primitives shared across the fleet (no `mj-app.json` schema needed).',
  );
  lines.push('');
  lines.push('| Package | npm | Version | Kind | Description |');
  lines.push('|---------|-----|---------|------|-------------|');
  for (const p of PRIMITIVE_PACKAGES) {
    const pkg = readJson(`${p.subpath}/package.json`);
    lines.push(
      `| [**${path.basename(p.subpath)}**](./${p.subpath}) | \`${pkg.name}\` | \`${pkg.version}\` | ${p.kind} | ${p.purpose} |`,
    );
  }
  lines.push('');

  // Held / In-Development Connectors
  lines.push('### Held / In-Development Connectors');
  lines.push('');
  lines.push(
    'Present in the repository under `scripts/connector-publish-scope.json` (`hold`) with `"private": true` while completing verification or awaiting live tenant credentials.',
  );
  lines.push('');
  lines.push('| Connector | Category | Package | Docs & Evidence | Description |');
  lines.push('|-----------|----------|---------|-----------------|-------------|');
  for (const h of heldConnectors.sort((a, b) => (a.category + '/' + a.vendorName).localeCompare(b.category + '/' + b.vendorName))) {
    const docLinks = [];
    if (h.support) {
      docLinks.push(`[${h.support.emoji} ${h.support.label}](./${h.subpath}/docs/SUPPORT.md)`);
    }
    if (h.hasSetup) {
      docLinks.push(`[Setup](./${h.subpath}/docs/credential-setup.html)`);
    }
    const docsCell = docLinks.length > 0 ? docLinks.join(' · ') : '—';
    lines.push(
      `| [**${h.vendorName}**](./${h.subpath}) | ${h.category} | \`${h.npmPackage}\` | ${docsCell} | ${h.description} |`,
    );
  }
  lines.push('');
  lines.push(END_MARKER);

  return {
    directoryBlock: lines.join('\n'),
    publishedCount: publishedConnectors.length,
  };
}

export function updateReadmeFile({ checkOnly = false } = {}) {
  if (!existsSync(README_PATH)) {
    throw new Error(`README.md not found at ${README_PATH}`);
  }
  const current = readFileSync(README_PATH, 'utf8');
  const beginIdx = current.indexOf(BEGIN_MARKER);
  const endIdx = current.indexOf(END_MARKER);
  if (beginIdx === -1 || endIdx === -1 || endIdx < beginIdx) {
    throw new Error(
      `README.md is missing ${BEGIN_MARKER} ... ${END_MARKER} markers. Cannot update connector directory.`,
    );
  }

  const { directoryBlock, publishedCount } = generateConnectorDirectoryMarkdown();
  let updated =
    current.slice(0, beginIdx) + directoryBlock + current.slice(endIdx + END_MARKER.length);

  // Also keep the top badge count in sync if present
  updated = updated.replace(
    /https:\/\/img\.shields\.io\/badge\/Connectors-\d+_Published-blue\?style=flat-square/g,
    `https://img.shields.io/badge/Connectors-${publishedCount}_Published-blue?style=flat-square`,
  );

  if (checkOnly) {
    if (current !== updated) {
      console.error(
        'README.md connector directory is STALE — run: node scripts/build-readme-directory.mjs',
      );
      process.exit(1);
    }
    console.log(
      `README.md connector directory up to date (${publishedCount} installable connectors).`,
    );
    return;
  }

  if (current !== updated) {
    writeFileSync(README_PATH, updated, 'utf8');
    console.log(
      `Updated README.md connector directory — ${publishedCount} installable connectors.`,
    );
  } else {
    console.log(
      `README.md connector directory already up to date (${publishedCount} installable connectors).`,
    );
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  updateReadmeFile({ checkOnly: CHECK });
}
