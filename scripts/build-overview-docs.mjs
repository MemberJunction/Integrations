#!/usr/bin/env node
/**
 * build-overview-docs.mjs — generate the two fleet-wide overview pages.
 *
 *   docs/marketing.html   what a prospect sees: which systems we connect, what the platform can
 *                         do with them once connected, and how confident we are — in plain language.
 *   docs/technical.html   what an engineer needs: evidence tier, what was actually measured,
 *                         what was NOT, package/version/install coordinates, links to the proof.
 *
 * Both are single-file, self-contained, zero-network HTML in the same design system as the
 * per-connector docs/credential-setup.html guides.
 *
 * WHY GENERATED
 * The truth about this fleet lives in three places that drift independently: connectors-catalog.json
 * (what's installable, at what version), the per-connector docs/SUPPORT.md files (what was actually
 * proven, and at what tier), and the MJ core Actions catalog (snapshotted into docs/data/). A
 * hand-maintained overview goes stale the moment any one of them moves — which is exactly how the
 * current one-pager ended up advertising connectors that were never published. Generating from the
 * sources means the page can only ever say what the repo can back up.
 *
 *   node scripts/build-overview-docs.mjs                # write both pages
 *   node scripts/build-overview-docs.mjs --check        # fail if either is stale (byte compare)
 *   node scripts/build-overview-docs.mjs --parse-only   # validate SUPPORT.md formats, render nothing
 *
 * DETERMINISM — the property the whole workflow rests on
 * The docs workflow regenerates on every push to main and commits the result. If output varied with
 * the wall clock, every push would produce a commit, which would need a back-merge, forever. So
 * there is NO Date.now() here: every date on the page is derived from the inputs (the newest
 * "Last verified" across all SUPPORT.md files, and the MJ snapshot's captured date). A run that
 * changes nothing produces byte-identical files and the workflow commits nothing.
 *
 * HONESTY RULES (inherited from docs/FLEET_OVERVIEW.md — do not soften these when editing)
 *   1. "Declares a write path" is a capability declaration, never a proven behaviour.
 *   2. No connector in this repo has a verified live write. Neither page may imply otherwise.
 */

import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const REPO_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const GITHUB_BLOB = 'https://github.com/MemberJunction/Integrations/blob/main';

const CHECK = process.argv.includes('--check');
const PARSE_ONLY = process.argv.includes('--parse-only');

/* ------------------------------------------------------------------ *
 * Evidence tiers
 * ------------------------------------------------------------------ */

/**
 * The repo's evidence ladder, keyed by EMOJI rather than by label: the 🥇 tier is written both as
 * "Production-live" and "Client-DB-live" in different files, and the label is display text, not an
 * identity. `rank` orders strongest-first on the technical page. `marketing` is the plain-language
 * equivalent — positive where the evidence earns it, never overstated, and never naming an internal
 * proof database.
 */
const TIERS = {
  '🥇': {
    label: 'Production-live',
    key: 'production-live',
    rank: 0,
    marketing: 'Proven in production',
    marketingBlurb: 'Run against a real production system with real data.',
  },
  '🟢': {
    label: 'Live-vendor',
    key: 'live-vendor',
    rank: 1,
    marketing: 'Verified against the live service',
    marketingBlurb: 'Run against the vendor’s real API using a real account.',
  },
  '⚙️': {
    label: 'Synthetic-local',
    key: 'synthetic-local',
    rank: 2,
    marketing: 'Verified against a live instance',
    marketingBlurb: 'Run against a real instance of the system, with test data rather than production data.',
  },
  '🧪': {
    label: 'Mock-only',
    key: 'mock-only',
    rank: 3,
    marketing: 'Verified against the vendor’s API specification',
    marketingBlurb: 'Run against a test double built from the vendor’s published contract.',
  },
  '🟡': {
    label: 'Honest-NA',
    key: 'honest-na',
    rank: 4,
    marketing: 'Standards-built, awaiting live verification',
    marketingBlurb: 'Built and checked against the vendor’s contract; no credential was available to run it live.',
  },
};

/** A SUPPORT.md carrying the baseline-stub marker is not an evidence claim — it is the build floor. */
const BASELINE = {
  key: 'baseline',
  rank: 5,
  label: 'Baseline',
  gloss: 'format-verified, no credential',
  marketing: 'Standards-verified build',
  marketingBlurb:
    'Built and verified against the vendor’s published API contract and a test double; no credential was available to run it live.',
};

/* ------------------------------------------------------------------ *
 * SUPPORT.md parsing
 * ------------------------------------------------------------------ */

const RE_TITLE = /^# (.+?) — Supported & Proven\s*$/m;
const RE_TIER =
  /^> \*\*Evidence tier:\*\* (🥇|🟢|⚙️|⚙|🧪|🟡)\s*([^(]+?)\s*\(([^)]*)\)\s*·\s*\*\*Last verified:\*\* (\d{4}-\d{2}-\d{2})\s*·\s*\*\*Proof DB\(s\):\*\* (.+?)\s*$/mu;
// The "fields" and "incremental" clauses are optional (BusinessCentral omits both), and the whole
// line is absent for the source-leaf database connectors, which discover their objects live.
const RE_DECLARED =
  /^\*\*([\d,]+) objects?\*\* declared(?: across \*\*([\d,]+) fields\*\*)? \(source: `([^`]+)`\)\. ([\d,]+) declare a write path; ([\d,]+) (?:are|is) read-only \(pull\)\.(?: ([\d,]+) (?:support|supports) incremental sync\.)?/m;
// Five observed shapes, including a parenthetical inside the bold and a bold-wrapped denominator.
const RE_ROWS =
  /\*\*Total proven rows: ([\d,]+)(?:\s*\([^)]*\))?\*\* across \*{0,2}([\d,]+)(?: of ([\d,]+) declared| distinct)? objects/;
const RE_PUSH_STATUS = /^- \*\*Status: ([^*]+?)\*\*\s*(.*)$/m;
// Optional. A connector can be genuinely live-verified AND still carry outstanding defects — Totara is
// verified against the real service with known bugs, ORCID is in client production and unfinished. The
// tier alone cannot say that, and a reader who sees only "Verified against the live service" would
// reasonably assume there is nothing outstanding.
const RE_KNOWN_ISSUES = /^> \*\*Known issues:\*\* (.+?)\s*$/mu;

const num = (s) => (s == null ? null : Number(String(s).replace(/,/g, '')));

/** Strip markdown emphasis/code/links down to the plain sentence a page can show. */
function plain(markdown) {
  return markdown
    .replace(/\*\*(.+?)\*\*/g, '$1')
    .replace(/`([^`]+)`/g, '$1')
    .replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')
    .replace(/\s+/g, ' ')
    .trim();
}

/** Slice the body of a markdown section, stopping at the next heading of the same or higher level. */
function section(text, headingRe, stopRe) {
  const parts = text.split(headingRe);
  if (parts.length < 2) return '';
  return parts[1].split(stopRe)[0];
}

/**
 * Parse one docs/SUPPORT.md. Throws on a malformed file rather than degrading: a connector whose
 * evidence doc silently failed to parse would be rendered as if it had no evidence at all, which
 * understates real proof — the opposite failure from the one these pages guard against, but a
 * misrepresentation either way.
 */
function parseSupport(text, relPath) {
  const fail = (what) => {
    throw new Error(`${relPath}: could not parse ${what} — SUPPORT.md format has drifted.`);
  };

  const title = RE_TITLE.exec(text) ?? fail('the title line (`# <Vendor> — Supported & Proven`)');
  const tier = RE_TIER.exec(text) ?? fail('the evidence-tier line');

  const emoji = tier[1] === '⚙' ? '⚙️' : tier[1];
  const tierDef = TIERS[emoji] ?? fail(`an unknown evidence tier "${emoji}"`);
  const proofDbsRaw = tier[5].trim();

  const knownIssues = RE_KNOWN_ISSUES.exec(text);
  const declared = RE_DECLARED.exec(text);
  const rows = RE_ROWS.exec(text);

  const pushBody = section(text, /^### Push[^\n]*$/m, /^## /m);
  const pushMatch = RE_PUSH_STATUS.exec(pushBody);

  const gapBody = section(text, /^## Residual gap \(honest\)\s*$/m, /^## |^---\s*$/m);
  const gaps = [...gapBody.matchAll(/^- (.+(?:\n(?!-|\s*$).+)*)$/gm)].map((m) => plain(m[1]));

  return {
    isBaseline: /baseline-stub:/.test(text),
    vendor: title[1].trim(),
    tier: emoji,
    tierLabel: tier[2].trim(),
    tierGloss: tier[3].trim(),
    tierRank: tierDef.rank,
    lastVerified: tier[4],
    proofDbs: proofDbsRaw === '—' ? [] : proofDbsRaw.split(/,\s*/),
    knownIssues: knownIssues ? plain(knownIssues[1]) : null,
    declared: declared
      ? {
          objects: num(declared[1]),
          fields: num(declared[2]),
          source: declared[3],
          write: num(declared[4]),
          readOnly: num(declared[5]),
          incremental: num(declared[6]) ?? 0,
        }
      : null,
    proven: rows
      ? { rows: num(rows[1]), objects: num(rows[2]), ofDeclared: num(rows[3]) }
      : { rows: 0, objects: 0, ofDeclared: null },
    push: pushMatch
      ? { status: pushMatch[1].replace(/\.$/, '').trim(), detail: plain(pushMatch[2]) }
      : { status: 'Not stated', detail: '' },
    gaps,
  };
}

/* ------------------------------------------------------------------ *
 * Model
 * ------------------------------------------------------------------ */

const readJson = (p) => JSON.parse(readFileSync(p, 'utf8'));

function buildModel() {
  const catalog = readJson(path.join(REPO_ROOT, 'connectors-catalog.json'));
  const scope = readJson(path.join(REPO_ROOT, 'scripts', 'connector-publish-scope.json'));
  const names = readJson(path.join(REPO_ROOT, 'docs', 'data', 'marketing-names.json'));
  const actions = readJson(path.join(REPO_ROOT, 'docs', 'data', 'mj-actions.json'));

  const catalogBySubpath = new Map(catalog.connectors.map((c) => [c.repoSubpath, c]));
  const connectors = [];

  for (const subpath of [...scope.publish, ...scope.hold]) {
    const entry = catalogBySubpath.get(subpath) ?? null;
    const published = entry !== null;
    const connectorDir = path.join(REPO_ROOT, subpath);

    const supportPath = path.join(connectorDir, 'docs', 'SUPPORT.md');
    const support = existsSync(supportPath)
      ? parseSupport(readFileSync(supportPath, 'utf8'), `${subpath}/docs/SUPPORT.md`)
      : null;

    let manifest = {};
    const manifestPath = path.join(connectorDir, 'mj-app.json');
    if (existsSync(manifestPath)) manifest = readJson(manifestPath);

    const override = names.connectors[subpath] ?? {};
    const category = subpath.split('/')[0];
    const fallbackName =
      entry && /^[A-Z]/.test(entry.name)
        ? entry.name
        : (entry?.displayName ?? manifest.displayName ?? path.basename(subpath)).replace(/ Connector$/, '');

    connectors.push({
      subpath,
      category,
      section: override.section ?? names.categoryToSection[category],
      marketingName: override.marketingName ?? fallbackName,
      marketingDescription: override.marketingDescription ?? null,
      description: entry?.description ?? manifest.description ?? '',
      objectCount: entry?.objectCount ?? support?.declared?.objects ?? null,
      npmPackage: entry?.npmPackage ?? null,
      version: entry?.version ?? null,
      mjVersionRange: entry?.mjVersionRange ?? null,
      installTag: entry?.installTag ?? null,
      published,
      support,
      hasCredentialGuide: existsSync(path.join(connectorDir, 'docs', 'credential-setup.html')),
    });
  }

  connectors.sort((a, b) => a.marketingName.localeCompare(b.marketingName, 'en', { sensitivity: 'base' }));

  // The page's "as of" date is the newest fact on it — never the clock. See the determinism note.
  const dates = connectors.map((c) => c.support?.lastVerified).filter(Boolean);
  dates.push(actions.source.capturedAt);
  const dataAsOf = dates.sort().at(-1);

  return { catalog, scope, names, actions, connectors, dataAsOf, ...fleetStats(connectors) };
}

function fleetStats(connectors) {
  const published = connectors.filter((c) => c.published);
  const tierCounts = new Map();
  let provenRows = 0;
  let liveRows = 0;
  let documented = 0;
  let baseline = 0;
  let undocumented = 0;

  for (const c of published) {
    const key = tierKey(c);
    tierCounts.set(key, (tierCounts.get(key) ?? 0) + 1);
    if (!c.support) undocumented++;
    else if (c.support.isBaseline) baseline++;
    else documented++;

    const rows = c.support?.proven.rows ?? 0;
    provenRows += rows;
    // "Live" here means rows pulled from a real system (🥇 or 🟢) — mock and synthetic-local rows
    // are real measurements too, but they are not evidence about a customer's actual data.
    if (!c.support?.isBaseline && (c.support?.tier === '🥇' || c.support?.tier === '🟢')) liveRows += rows;
  }

  return {
    published,
    held: connectors.filter((c) => !c.published),
    tierCounts,
    provenRows,
    liveRows,
    documented,
    baseline: baseline + undocumented,
    advertised: reconcileAdvertised(connectors),
  };
}

/**
 * Reconcile the systems Sales advertises against what the repo can actually back.
 *
 * WHY THIS IS ON THE PAGE
 * Without it the register enumerates only what exists, which makes it silent on the more expensive
 * question: what is being sold that isn't built. Two failure modes hide in that silence —
 *
 *   1. A system on the AD list with no connector and no action pack. Priced as an integration,
 *      nothing to install.
 *   2. A system backed only by an action pack. An agent can act on it; no data lands in
 *      MemberJunction, so there is nothing to report on. On a flat list it looks identical to a
 *      connector that replicates 32 objects.
 *
 * Both surface during delivery rather than during the sale, which is the expensive end.
 */
function reconcileAdvertised(connectors) {
  const file = path.join(REPO_ROOT, 'docs', 'data', 'advertised-systems.json');
  if (!existsSync(file)) return null;
  const doc = JSON.parse(readFileSync(file, 'utf8'));
  const bySub = new Map(connectors.map((c) => [c.subpath, c]));

  const rows = [];
  for (const category of doc.categories) {
    for (const system of category.systems) {
      const connector = system.matches ? bySub.get(system.matches) : null;
      let kind;
      if (connector && connector.published) kind = 'data';
      else if (connector) kind = 'held';
      else if (system.matches) kind = 'missing'; // named a subpath that no longer exists
      else if (system.actionPack) kind = 'action';
      else if (system.provider) kind = 'provider';
      else kind = 'absent';
      rows.push({ category: category.name, name: system.name, kind, connector, system });
    }
  }

  const tally = {};
  for (const r of rows) tally[r.kind] = (tally[r.kind] ?? 0) + 1;
  return { source: doc.source, rows, tally, total: rows.length };
}

/** Tier identity for a connector: baseline stubs and missing docs collapse to the build floor. */
function tierKey(connector) {
  if (!connector.support || connector.support.isBaseline) return BASELINE.key;
  return TIERS[connector.support.tier].key;
}

function tierInfo(connector) {
  if (!connector.support || connector.support.isBaseline) {
    return { ...BASELINE, emoji: '' };
  }
  const def = TIERS[connector.support.tier];
  return {
    ...def,
    emoji: connector.support.tier,
    label: connector.support.tierLabel,
    gloss: connector.support.tierGloss,
  };
}

/* ------------------------------------------------------------------ *
 * HTML helpers
 * ------------------------------------------------------------------ */

const esc = (s) =>
  String(s ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');

const fmt = (n) => (n == null ? '—' : Number(n).toLocaleString('en-US'));

/** "2026-08-12" -> "Q3 2026" — the marketing page dates itself by quarter, like the one-pager. */
function quarter(isoDate) {
  const [year, month] = isoDate.split('-').map(Number);
  return `Q${Math.floor((month - 1) / 3) + 1} ${year}`;
}

/**
 * Turn an engineer-written catalog description into a line a prospect can read.
 *
 * The descriptions in connectors-catalog.json come from each connector's metadata and are written
 * for whoever maintains it — "syncs Salesforce-native OrderApi__* + EventApi__* objects via FDService
 * Apex REST + the Salesforce platform REST API". The vendor and the subject matter are the useful
 * half; the transport, auth scheme and endpoint names are noise on a marketing page. So: take the
 * first sentence, cut the trailing implementation clause, drop a parenthetical aside, and cap the
 * length at a word boundary. A `marketingDescription` in marketing-names.json overrides all of this
 * when a connector deserves a hand-written line.
 */
function marketingBlurb(text) {
  let s = String(text ?? '').replace(/\s+/g, ' ').trim();

  const stop = s.search(/\.(?:\s|$)/);
  if (stop !== -1) s = s.slice(0, stop);

  // Cut the "how it talks to them" clause — everything from the transport preposition onward.
  s = s.replace(/\s+(?:via|through|over|using|with)\s+[^,;]*(?:API|REST|SOAP|GraphQL|OAuth|SDK|endpoint)[^.]*$/i, '');
  // Drop a trailing parenthetical aside, which is almost always an object-name list.
  s = s.replace(/\s*\([^)]*\)\s*$/, '');
  s = s.replace(/[\s,;:—-]+$/, '');

  if (s.length > 132) {
    const cut = s.slice(0, 132);
    s = `${cut.slice(0, cut.lastIndexOf(' '))}…`;
  }
  return s ? `${s}${/[.…]$/.test(s) ? '' : '.'}` : '';
}

/** Shared design tokens, lifted from the per-connector credential-setup.html guides. */
const TOKENS = `
  :root {
    --ink:#17222e; --ink-soft:#45566a; --muted:#6b7c8f; --line:#dbe4ec; --line-soft:#eaf0f5;
    --paper:#ffffff; --surface:#f4f8fb; --surface-2:#eef4f9;
    --brand:#0b6fb8; --brand-deep:#0a4d80;
    --navy:#14243d; --navy-2:#1d3557;
    --ok:#1a7f52; --ok-bg:#e9f6ef; --ok-line:#bfe4d0;
    --warn:#9a6b00; --warn-bg:#fbf3df; --warn-line:#ecdcae;
    --bar:#0b6fb8; --bar-track:#e3ecf4;
    --radius:14px;
    --shadow: 0 1px 2px rgba(23,34,46,.05), 0 8px 28px -12px rgba(23,34,46,.18);
    --mono: ui-monospace,"SF Mono","SFMono-Regular",Menlo,Consolas,monospace;
    --sans: system-ui,-apple-system,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  }
  @media (prefers-color-scheme: dark) {
    :root:not([data-theme="light"]) {
      --ink:#e9eef4; --ink-soft:#b4c1cf; --muted:#8698a8; --line:#27343f; --line-soft:#1d2831;
      --paper:#111a22; --surface:#0e161d; --surface-2:#1a2732;
      --brand:#4aa6e6; --brand-deep:#9bd2f4;
      --ok:#4cc38a; --ok-bg:#12291f; --ok-line:#1f5238;
      --warn:#e3b445; --warn-bg:#2a2410; --warn-line:#4a3d13;
      --bar:#4aa6e6; --bar-track:#1d2831;
      --shadow: 0 1px 2px rgba(0,0,0,.4), 0 10px 30px -14px rgba(0,0,0,.6);
    }
  }
  :root[data-theme="dark"] {
    --ink:#e9eef4; --ink-soft:#b4c1cf; --muted:#8698a8; --line:#27343f; --line-soft:#1d2831;
    --paper:#111a22; --surface:#0e161d; --surface-2:#1a2732;
    --brand:#4aa6e6; --brand-deep:#9bd2f4;
    --ok:#4cc38a; --ok-bg:#12291f; --ok-line:#1f5238;
    --warn:#e3b445; --warn-bg:#2a2410; --warn-line:#4a3d13;
    --bar:#4aa6e6; --bar-track:#1d2831;
    --shadow: 0 1px 2px rgba(0,0,0,.4), 0 10px 30px -14px rgba(0,0,0,.6);
  }

  * { box-sizing:border-box; }
  html { -webkit-text-size-adjust:100%; }
  body { margin:0; font-family:var(--sans); color:var(--ink); background:var(--surface);
         line-height:1.6; font-size:16.5px; -webkit-font-smoothing:antialiased; }
  a { color:var(--brand); }
  .wrap { max-width:1080px; margin:0 auto; padding:0 22px 80px; }
  .eyebrow { text-transform:uppercase; letter-spacing:.14em; font-size:12px; font-weight:700; color:var(--brand); margin:0; }
  .card { background:var(--paper); border:1px solid var(--line); border-radius:var(--radius); box-shadow:var(--shadow); }
  .pad { padding:20px 22px; }
  .pill { display:inline-flex; align-items:center; gap:6px; font-size:13px; font-weight:600; color:var(--ink-soft);
          background:var(--paper); border:1px solid var(--line); border-radius:999px; padding:5px 12px; }
  footer { margin-top:52px; padding-top:20px; border-top:1px solid var(--line); color:var(--muted); font-size:13.5px; }
  .genstamp { font-family:var(--mono); font-size:12px; color:var(--muted); }
`;

/* ------------------------------------------------------------------ *
 * Marketing page
 * ------------------------------------------------------------------ */

function renderMarketing(model) {
  const { names, actions, published, dataAsOf } = model;

  // Vendor packs with no connector of their own become cards; packs that DO have a connector are
  // folded into that connector's card as an extra chip, so nothing appears twice.
  const packsByConnector = new Map();
  const standalonePacks = [];
  for (const pack of actions.vendorPacks) {
    if (pack.connector) packsByConnector.set(pack.connector, pack);
    else standalonePacks.push(pack);
  }

  /** section key -> { connectors[], packs[] } */
  const bySection = new Map(names.sections.map((s) => [s.key, { ...s, connectors: [], packs: [] }]));
  for (const c of published) bySection.get(c.section)?.connectors.push(c);
  for (const pack of standalonePacks) {
    const key = names.vendorGroupToSection[pack.group];
    if (key) bySection.get(key)?.packs.push(pack);
  }

  // The communications section is populated entirely from the platform's own delivery providers.
  const commsSection = bySection.get('communications');
  for (const provider of actions.communicationProviders) {
    commsSection.packs.push({ display: provider, provider: true });
  }

  const sections = names.sections
    .map((s) => bySection.get(s.key))
    .filter((s) => s.connectors.length + s.packs.length > 0);

  const totalCount = sections.reduce((n, s) => n + s.connectors.length + s.packs.length, 0);
  const actionTotal = Math.floor(actions.actionCount / 100) * 100;

  const cardsFor = (s) => {
    const cards = [];
    for (const c of s.connectors) {
      const tier = tierInfo(c);
      const pack = packsByConnector.get(c.subpath);
      const chips = [];
      if (c.objectCount) chips.push(`${fmt(c.objectCount)} data objects`);
      if (pack) chips.push(`${pack.actionCount} ready-made actions`);
      cards.push(`
        <li class="conn">
          <p class="conn-name">${esc(c.marketingName)}</p>
          <p class="conn-desc">${esc(c.marketingDescription ?? marketingBlurb(c.description))}</p>
          <p class="conn-meta" style="margin-top:auto">
            ${chips.map((chip) => `<span class="chip">${esc(chip)}</span>`).join('\n            ')}
            <span class="chip conf" title="${esc(tier.marketingBlurb)}">${esc(tier.marketing)}</span>${
              c.support?.knownIssues ? '\n            <span class="chip warnchip" title="Verified, with known issues still outstanding.">known issues</span>' : ''
            }
          </p>
        </li>`);
    }
    for (const pack of s.packs) {
      const detail = pack.provider
        ? 'Send email, SMS and push through the platform’s communication framework.'
        : `${pack.actionCount} ready-made actions your agents can call directly.`;
      cards.push(`
        <li class="conn">
          <p class="conn-name">${esc(pack.display)}</p>
          <p class="conn-desc">${esc(detail)}</p>
          <p class="conn-meta"><span class="chip">${pack.provider ? 'Delivery provider' : `${pack.actionCount} actions`}</span></p>
        </li>`);
    }
    return cards.join('');
  };

  const sectionHtml = sections
    .map(
      (s) => `
      <section class="catsec">
        <h2 class="cathead"><span class="catrule" style="--accent:${esc(s.accent)}"></span>${esc(
          s.label,
        )} <span class="catcount">(${s.connectors.length + s.packs.length})</span></h2>
        <ul class="conngrid">${cardsFor(s)}
        </ul>
      </section>`,
    )
    .join('\n');

  const actionGroups = actions.platformGroups
    .map(
      (g) => `
          <li><span class="agname">${esc(g.name)}</span><span class="agcount">${g.actionCount}</span></li>`,
    )
    .join('');

  return `<!-- GENERATED by scripts/build-overview-docs.mjs — do not edit by hand.
     Edits are overwritten on the next push to main. Change the generator, the curated names in
     docs/data/marketing-names.json, or the per-connector docs/SUPPORT.md files instead. -->
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>MemberJunction Integrations</title>
<style>${TOKENS}
  header.hero { background:linear-gradient(160deg, var(--navy), var(--navy-2)); color:#eaf1f8; }
  .hero-inner { max-width:1080px; margin:0 auto; padding:34px 22px 40px; }
  .brandrow { display:flex; align-items:center; gap:11px; font-weight:600; font-size:14px; color:#a9c0d8; }
  .brandmark { width:22px; height:22px; border-radius:6px; background:linear-gradient(135deg,#3f95cf,#0b6fb8);
               box-shadow:inset 0 0 0 1.5px rgba(255,255,255,.25); flex:0 0 auto; }
  .hero .eyebrow { color:#8fb4d8; margin-top:22px; }
  .hero h1 { margin:8px 0 0; font-size:clamp(30px,5vw,42px); line-height:1.1; letter-spacing:-.02em;
             text-wrap:balance; max-width:16ch; color:#fff; }
  .hero .lede { margin:14px 0 0; font-size:18px; color:#c6d8ea; max-width:60ch; }
  .stats { display:flex; flex-wrap:wrap; gap:9px; margin-top:24px; }
  .stat { display:inline-flex; align-items:baseline; gap:7px; background:rgba(255,255,255,.09);
          border:1px solid rgba(255,255,255,.16); border-radius:999px; padding:6px 14px; font-size:13.5px; color:#c6d8ea; }
  .stat b { color:#fff; font-size:15px; font-variant-numeric:tabular-nums; }

  .catsec { margin-top:30px; }
  .cathead { display:flex; align-items:center; gap:10px; margin:0 0 12px; font-size:13px; font-weight:700;
             letter-spacing:.1em; text-transform:uppercase; color:var(--ink-soft); }
  .catrule { width:26px; height:3px; border-radius:2px; background:var(--accent); flex:0 0 auto; }
  .catcount { color:var(--muted); font-weight:600; letter-spacing:.04em; }
  .conngrid { list-style:none; margin:0; padding:0; display:grid; gap:12px;
              grid-template-columns:repeat(auto-fill, minmax(258px, 1fr)); }
  .conn { background:var(--paper); border:1px solid var(--line); border-radius:12px; padding:14px 16px;
          display:flex; flex-direction:column; }
  .conn-name { margin:0; font-weight:700; font-size:15.5px; letter-spacing:-.01em; }
  .conn-desc { margin:5px 0 0; font-size:13.5px; color:var(--ink-soft); line-height:1.5; }
  .conn-meta { margin:10px 0 0; padding-top:2px; display:flex; flex-wrap:wrap; gap:6px; align-items:flex-start; }
  .chip { font-size:11.5px; font-weight:600; color:var(--muted); background:var(--surface-2);
          border:1px solid var(--line-soft); border-radius:999px; padding:2px 9px; }
  .chip.conf { color:var(--brand-deep); background:transparent; border-color:var(--line); }
  .chip.warnchip { color:var(--warn); background:var(--warn-bg); border-color:var(--warn-line); font-weight:700; }

  .band { display:grid; gap:14px; grid-template-columns:repeat(auto-fit, minmax(300px,1fr)); margin-top:30px; }
  .band h3 { margin:0 0 8px; font-size:13px; letter-spacing:.08em; text-transform:uppercase; color:var(--brand); }
  .band p { margin:0 0 10px; color:var(--ink-soft); font-size:15px; }
  .band ul { margin:0; padding-left:18px; color:var(--ink-soft); font-size:15px; }
  .band li + li { margin-top:7px; }
  .band b { color:var(--ink); }

  .actions { margin-top:30px; }
  .aggrid { list-style:none; margin:12px 0 0; padding:0; display:grid; gap:8px;
            grid-template-columns:repeat(auto-fill, minmax(190px,1fr)); }
  .aggrid li { display:flex; align-items:center; justify-content:space-between; gap:10px;
               background:var(--surface-2); border:1px solid var(--line-soft); border-radius:9px; padding:8px 12px; }
  .agname { font-size:13.5px; font-weight:600; color:var(--ink-soft); }
  .agcount { font-family:var(--mono); font-size:13px; color:var(--brand-deep); font-variant-numeric:tabular-nums; }
  .provline { margin:14px 0 0; font-size:13.5px; color:var(--muted); }
  .provline b { color:var(--ink-soft); }

  .legend { margin-top:30px; }
  .legend dl { margin:10px 0 0; display:grid; gap:8px; grid-template-columns:minmax(190px,auto) 1fr; font-size:14px; }
  .legend dt { font-weight:700; color:var(--ink); }
  .legend dd { margin:0; color:var(--ink-soft); }
  @media (max-width:560px) { .legend dl { grid-template-columns:1fr; gap:2px; } .legend dd { margin-bottom:8px; } }
</style>
</head>
<body>

<header class="hero">
  <div class="hero-inner">
    <div class="brandrow"><span class="brandmark"></span> MemberJunction</div>
    <p class="eyebrow">${totalCount} pre-built integrations · Open source · Single-tenant</p>
    <h1>Connect the systems you already run.</h1>
    <p class="lede">MemberJunction has pre-built connectors for the AMS, CRM, events, learning, finance and
      marketing tools associations and nonprofits use every day. Your data lands in one layer you own.</p>
    <div class="stats">
      <span class="stat"><b>${totalCount}</b> integrations</span>
      <span class="stat"><b>${sections.length}</b> categories</span>
      <span class="stat"><b>${actionTotal}+</b> ready-made actions</span>
      <span class="stat"><b>${fmt(model.liveRows)}</b> records verified from live systems</span>
    </div>
  </div>
</header>

<main class="wrap">
${sectionHtml}

  <div class="band">
    <div class="card pad">
      <h3>How it connects</h3>
      <p>Each connector either replicates your data read-only or syncs it on a schedule, and
         <b>your source systems are never modified</b>. What lands in MemberJunction is one unified
         layer you own — open source and single-tenant.</p>
      <p>Install a connector from the catalog, point it at your account, and it discovers the objects
         and fields available to you rather than assuming a fixed shape.</p>
    </div>
    <div class="card pad">
      <h3>What you can do with it</h3>
      <p>Once your systems are connected, MemberJunction's AI can work across all of it.</p>
      <ul>
        <li><b>Agents</b> run multi-step work across every connected system, not just one-off answers.</li>
        <li><b>Knowledge Hub</b> searches, classifies and de-duplicates your records and content in one place.</li>
        <li><b>DB AutoDoc</b> documents your databases automatically, so even undocumented systems become usable quickly.</li>
      </ul>
    </div>
  </div>

  <section class="actions card pad">
    <h3 class="eyebrow">${actionTotal}+ ready-made actions</h3>
    <p style="margin:8px 0 0; color:var(--ink-soft); font-size:15px;">
      Beyond moving data, the platform ships ${fmt(actions.actionCount)} actions your agents can call directly —
      no code to write for the common work.</p>
    <ul class="aggrid">${actionGroups}
    </ul>
    <p class="provline"><b>Email, SMS &amp; push:</b> ${esc(actions.communicationProviders.join(' · '))}</p>
    <p class="provline"><b>File storage:</b> ${esc(actions.fileStorageProviders.join(' · '))}</p>
  </section>

  <section class="legend card pad">
    <h3 class="eyebrow">What our confidence labels mean</h3>
    <p style="margin:8px 0 0; color:var(--ink-soft); font-size:15px;">
      We label every integration by how far it has actually been proven, not by how far it could go.
      The full engineering detail — what was measured, and what was not — is in the
      <a href="technical.html">technical overview</a>.</p>
    <dl>
${[...Object.values(TIERS), BASELINE]
  .sort((a, b) => a.rank - b.rank)
  .map((t) => `      <dt>${esc(t.marketing)}</dt>\n      <dd>${esc(t.marketingBlurb)}</dd>`)
  .join('\n')}
    </dl>
    <p class="provline">Connectors read your data. Write-back exists for some systems but is not yet
      verified against a live tenant, so we do not claim it.</p>
  </section>

  <footer>
    Open source · 200+ TypeScript packages on GitHub · Single-tenant · Current as of ${quarter(dataAsOf)}, updated regularly.
    <br><span class="genstamp">Generated from the connector catalog and per-connector evidence docs · data as of ${esc(dataAsOf)}</span>
  </footer>
</main>
</body>
</html>
`;
}

/* ------------------------------------------------------------------ *
 * Landing page
 * ------------------------------------------------------------------ */

/**
 * docs/index.html — the GitHub Pages root.
 *
 * Pages serves this directory from `main`, so without an index the site root is a 404 and every
 * link has to carry a filename. This is deliberately thin: two doors and the headline numbers.
 * Anything substantive belongs on the page it describes, not duplicated here where it would need
 * to be kept in step.
 */
function renderIndex(model) {
  const { published, dataAsOf, actions } = model;

  return `<!-- GENERATED by scripts/build-overview-docs.mjs — do not edit by hand. -->
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>MemberJunction Integrations</title>
<style>${TOKENS}
  body { display:grid; place-items:center; min-height:100vh; }
  .shell { max-width:760px; padding:44px 22px 56px; }
  h1 { margin:10px 0 0; font-size:clamp(28px,5vw,38px); line-height:1.12; letter-spacing:-.02em; }
  .lede { margin:12px 0 0; color:var(--ink-soft); font-size:17.5px; max-width:56ch; }
  .stats { display:flex; flex-wrap:wrap; gap:8px; margin-top:20px; }
  .doors { display:grid; gap:14px; grid-template-columns:repeat(auto-fit,minmax(280px,1fr)); margin-top:26px; }
  .door { display:block; text-decoration:none; color:inherit; background:var(--paper); border:1px solid var(--line);
          border-radius:var(--radius); box-shadow:var(--shadow); padding:20px 22px; transition:border-color .15s ease; }
  .door:hover { border-color:var(--brand); }
  .door h2 { margin:0; font-size:17px; letter-spacing:-.01em; color:var(--brand-deep); }
  .door p { margin:7px 0 0; font-size:14.5px; color:var(--ink-soft); line-height:1.5; }
  .door .go { margin:12px 0 0; font-size:13px; font-weight:700; color:var(--brand); }
  .brandrow { display:flex; align-items:center; gap:11px; font-weight:600; font-size:14px; color:var(--ink-soft); }
  .brandmark { width:22px; height:22px; border-radius:6px; background:linear-gradient(135deg,var(--brand),var(--brand-deep));
               box-shadow:inset 0 0 0 1.5px rgba(255,255,255,.25); flex:0 0 auto; }
</style>
</head>
<body>
<div class="shell">
  <div class="brandrow"><span class="brandmark"></span> MemberJunction</div>
  <h1>Integrations</h1>
  <p class="lede">Pre-built connectors for the systems associations and nonprofits already run, plus the
    platform actions that work across them once connected.</p>
  <div class="stats">
    <span class="pill"><b>${published.length}</b> connectors</span>
    <span class="pill"><b>${Math.floor(actions.actionCount / 100) * 100}+</b> ready-made actions</span>
    <span class="pill"><b>${fmt(model.liveRows)}</b> records verified from live systems</span>
  </div>

  <div class="doors">
    <a class="door" href="marketing.html">
      <h2>Integrations overview</h2>
      <p>What we connect to, what data lands, and how far each integration has been proven — in plain language.</p>
      <p class="go">View the overview →</p>
    </a>
    <a class="door" href="technical.html">
      <h2>Engineering evidence</h2>
      <p>Per-connector evidence tier, rows actually measured, declared versus proven surface, write status, and versions.</p>
      <p class="go">View the evidence →</p>
    </a>
  </div>

  <footer>
    Open source · Single-tenant · Data as of ${esc(dataAsOf)}
    <br><span class="genstamp">Generated by scripts/build-overview-docs.mjs — regenerated on every push to main.</span>
  </footer>
</div>
</body>
</html>
`;
}

/* ------------------------------------------------------------------ *
 * Technical page
 * ------------------------------------------------------------------ */

function renderTechnical(model) {
  const { published, held, tierCounts, dataAsOf, actions } = model;

  const tierRows = [...Object.entries(TIERS), [BASELINE.key, BASELINE]]
    .map(([emoji, def]) => ({
      emoji: def === BASELINE ? '' : emoji,
      def,
      count: tierCounts.get(def.key) ?? 0,
    }))
    .sort((a, b) => a.def.rank - b.def.rank);
  const tierMax = Math.max(...tierRows.map((r) => r.count), 1);

  // Evidence tiers are ordinal and each row is labelled with its own count, so magnitude is encoded
  // by bar length in a single hue. A stacked multi-hue bar would need adjacent steps that colour-
  // blind readers cannot separate — length plus a text label has neither problem.
  const tierChart = tierRows
    .map(
      (r) => `
        <li class="tierrow">
          <span class="tierlabel">${r.emoji ? `<span class="badge">${r.emoji}</span> ` : ''}${esc(
            r.def.label,
          )}</span>
          <span class="meter"><span class="meterfill" style="width:${((r.count / tierMax) * 100).toFixed(1)}%"></span></span>
          <span class="tiercount">${r.count}</span>
        </li>`,
    )
    .join('');

  const connectorRow = (c) => {
    const tier = tierInfo(c);
    const s = c.support;
    const docs = [];
    if (s) docs.push(`<a href="${GITHUB_BLOB}/${c.subpath}/docs/SUPPORT.md">evidence</a>`);
    if (c.hasCredentialGuide) docs.push(`<a href="${GITHUB_BLOB}/${c.subpath}/docs/credential-setup.html">setup</a>`);

    const coverage = s?.proven.rows
      ? `${fmt(s.proven.objects)}${s.proven.ofDeclared ? ` of ${fmt(s.proven.ofDeclared)}` : ''} objects`
      : 'no rows landed';
    const declared = s?.declared
      ? `${fmt(s.declared.objects)} obj · ${fmt(s.declared.fields)} fld`
      : c.objectCount
        ? `${fmt(c.objectCount)} obj`
        : 'discovered live';
    // Baseline connectors all carry the same boilerplate gap, and their tier already says it —
    // repeating it on every row buries the caveats that are actually connector-specific.
    const caveat = s && !s.isBaseline ? (s.gaps?.[0] ?? '') : '';

    return `
      <tr>
        <th scope="row">
          <span class="cname">${esc(c.marketingName)}</span>
          <span class="cpath">${esc(c.subpath)}</span>
        </th>
        <td><span class="badge">${tier.emoji}</span> ${esc(tier.label)}${
          s?.knownIssues ? ' <span class="flag">known issues</span>' : ''
        }<span class="sub">${esc(s ? s.lastVerified : BASELINE.gloss)}</span>${
          s?.knownIssues ? `<span class="sub issue">${esc(s.knownIssues)}</span>` : ''
        }</td>
        <td>${declared}<span class="sub">${s?.declared ? `${fmt(s.declared.write)} declare write` : 'no declared catalog'}</span></td>
        <td class="numcell">${s?.proven.rows ? fmt(s.proven.rows) : '0'}<span class="sub">${esc(coverage)}</span></td>
        <td>${esc(s?.push.status ?? 'Not stated')}<span class="sub">${esc(
          // Deliberately a COUNT, not the database names. The names live in each connector's own
          // SUPPORT.md (linked from this row), which is where someone re-checking a claim will go.
          // Repeating internal environment identifiers on a page built to be shared adds a surface
          // — and a "whose data is that?" question — for no gain the link doesn't already cover.
          s?.proofDbs.length
            ? `verified in ${s.proofDbs.length} proof database${s.proofDbs.length === 1 ? '' : 's'}`
            : 'no proof database',
        )}</span></td>
        <td>${c.version ? `<code>${esc(c.version)}</code><span class="sub">${esc(c.mjVersionRange ?? '')}</span>` : '—'}</td>
        <td>${docs.join(' · ') || '—'}</td>
      </tr>${
        caveat
          ? `
      <tr class="caveatrow"><td colspan="7"><span class="caveatlabel">Residual gap</span> ${esc(caveat)}</td></tr>`
          : ''
      }`;
  };

  const tableFor = (list) => `
      <div class="tablewrap">
        <table>
          <thead>
            <tr>
              <th scope="col">Connector</th><th scope="col">Evidence tier</th><th scope="col">Declared surface</th>
              <th scope="col">Rows proven</th><th scope="col">Write status</th><th scope="col">Version</th><th scope="col">Docs</th>
            </tr>
          </thead>
          <tbody>${list.map(connectorRow).join('')}
          </tbody>
        </table>
      </div>`;

  const categories = [...new Set(published.map((c) => c.category))].sort();
  const categorySections = categories
    .map((cat) => {
      const list = published.filter((c) => c.category === cat);
      return `
    <section>
      <h2>${esc(cat)} <span class="catcount">(${list.length})</span></h2>
      ${tableFor(list)}
    </section>`;
    })
    .join('');

  return `<!-- GENERATED by scripts/build-overview-docs.mjs — do not edit by hand.
     Edits are overwritten on the next push to main. The numbers here come from each connector's
     own docs/SUPPORT.md and from connectors-catalog.json; change those, not this file. -->
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Integrations Evidence Overview</title>
<style>${TOKENS}
  header.hero { background:var(--paper); border-bottom:1px solid var(--line); }
  .hero-inner { max-width:1080px; margin:0 auto; padding:30px 22px 32px; }
  h1 { margin:8px 0 0; font-size:clamp(26px,4vw,34px); line-height:1.15; letter-spacing:-.02em; }
  .lede { margin:12px 0 0; color:var(--ink-soft); max-width:70ch; }

  .tiles { display:grid; gap:12px; grid-template-columns:repeat(auto-fit,minmax(158px,1fr)); margin-top:22px; }
  .tile { background:var(--paper); border:1px solid var(--line); border-radius:12px; padding:14px 16px; }
  .tile .v { font-size:26px; font-weight:700; letter-spacing:-.02em; font-variant-numeric:tabular-nums; }
  .tile .k { font-size:12.5px; color:var(--muted); margin-top:2px; }
  .tile.flag { border-color:var(--warn-line); background:var(--warn-bg); }
  .tile.flag .v { color:var(--warn); }

  .tierlist { list-style:none; margin:12px 0 0; padding:0; display:flex; flex-direction:column; gap:7px; }
  .tierrow { display:grid; grid-template-columns:minmax(150px,190px) 1fr 34px; align-items:center; gap:12px; font-size:13.5px; }
  .tierlabel { color:var(--ink-soft); font-weight:600; }
  .meter { height:9px; border-radius:5px; background:var(--bar-track); overflow:hidden; }
  .meterfill { display:block; height:100%; border-radius:5px; background:var(--bar); }
  .tiercount { font-family:var(--mono); font-size:13px; text-align:right; color:var(--ink); font-variant-numeric:tabular-nums; }
  .badge { font-size:14px; }

  .rules { margin-top:22px; }
  .rules ol { margin:10px 0 0; padding-left:20px; color:var(--ink-soft); }
  .rules li + li { margin-top:8px; }
  .rules b { color:var(--ink); }

  h2 { margin:34px 0 10px; font-size:14px; letter-spacing:.1em; text-transform:uppercase; color:var(--brand); }
  .catcount { color:var(--muted); }
  .tablewrap { overflow-x:auto; border:1px solid var(--line); border-radius:12px; background:var(--paper); }
  table { border-collapse:collapse; width:100%; min-width:960px; font-size:13.5px; }
  thead th { text-align:left; font-size:11.5px; letter-spacing:.06em; text-transform:uppercase; color:var(--muted);
             font-weight:700; padding:10px 14px; border-bottom:1px solid var(--line); white-space:nowrap; }
  tbody th, tbody td { padding:11px 14px; border-bottom:1px solid var(--line-soft); vertical-align:top; text-align:left; }
  tbody th { font-weight:600; }
  tbody tr:last-child td, tbody tr:last-child th { border-bottom:0; }
  .cname { display:block; }
  .cpath, .sub { display:block; font-size:11.5px; color:var(--muted); font-weight:400; margin-top:2px; }
  .cpath { font-family:var(--mono); }
  .numcell { font-variant-numeric:tabular-nums; }
  code { font-family:var(--mono); font-size:12.5px; background:var(--surface-2); border-radius:4px; padding:1px 5px; }
  .caveatrow td { padding-top:0; font-size:12.5px; color:var(--muted); border-bottom:1px solid var(--line-soft); }
  .caveatlabel { font-weight:700; color:var(--ink-soft); text-transform:uppercase; letter-spacing:.05em; font-size:10.5px; margin-right:6px; }
  .held { margin-top:34px; }
  .held p { color:var(--ink-soft); font-size:14.5px; margin:0 0 12px; }
  .advgroup { margin-top:18px; border-left:3px solid var(--line); padding-left:14px; }
  .advgroup h3 { margin:0 0 4px; font-size:15px; letter-spacing:-.01em; }
  .advgroup p { margin:0 0 8px; font-size:13.5px; color:var(--muted); }
  /* The 960px min-width above exists for the wide evidence tables; these have three columns and
     would otherwise overflow and wrap the detail cell onto its own line. */
  .advgroup table { min-width:0; table-layout:fixed; }
  .advgroup tbody td { padding:7px 12px 7px 0; vertical-align:baseline; }
  .flag { display:inline-block; margin-left:6px; padding:1px 6px; border-radius:999px; font-size:10.5px;
          font-weight:700; letter-spacing:.02em; text-transform:uppercase;
          color:var(--warn); background:var(--warn-bg); border:1px solid var(--warn-line); }
  .sub.issue { color:var(--warn); margin-top:4px; }
  .advgroup td.advmeta { font-size:12px; color:var(--muted); }
  .advgroup tbody td:nth-child(1) { width:32%; }
  .advgroup tbody td:nth-child(2) { width:34%; }
  .advgroup tbody td:nth-child(3) { width:34%; }
  .advgroup.k-absent { border-left-color:#b4342b; }
  .advgroup.k-action { border-left-color:var(--warn); }
  .advgroup.k-held   { border-left-color:var(--warn); }
  .advgroup.k-prov   { border-left-color:var(--line); }
  .advgroup.k-data   { border-left-color:var(--ok); }
</style>
</head>
<body>

<header class="hero">
  <div class="hero-inner">
    <p class="eyebrow">MemberJunction Integrations · engineering overview</p>
    <h1>What each connector actually proves</h1>
    <p class="lede">One row per connector: the evidence tier it has earned, what was measured to earn it,
      and — just as importantly — what was not. Every number here is read from that connector's own
      <code>docs/SUPPORT.md</code>; nothing on this page is asserted by hand. For the client-facing
      version, see the <a href="marketing.html">integrations overview</a>.</p>

    <div class="tiles">
      <div class="tile"><div class="v">${published.length}</div><div class="k">published connectors</div></div>
      <div class="tile"><div class="v">${model.documented}</div><div class="k">with measured evidence</div></div>
      <div class="tile"><div class="v">${model.baseline}</div><div class="k">at the build baseline</div></div>
      <div class="tile"><div class="v">${fmt(model.provenRows)}</div><div class="k">rows proven, all tiers</div></div>
      <div class="tile"><div class="v">${fmt(model.liveRows)}</div><div class="k">rows from live systems</div></div>
      <div class="tile flag"><div class="v">0</div><div class="k">verified live writes, fleet-wide</div></div>
    </div>
  </div>
</header>

<main class="wrap">

  <section class="card pad" style="margin-top:24px;">
    <p class="eyebrow">Evidence tier distribution</p>
    <ul class="tierlist">${tierChart}
    </ul>
  </section>

  <section class="card pad rules">
    <p class="eyebrow">Two rules this page will not bend</p>
    <ol>
      <li><b>"Declares a write path" is a capability declaration, not a proven behaviour.</b>
        A connector's metadata can declare Create/Update/Delete on every object it knows about; that says
        what the code will attempt, not what has been observed to work.</li>
      <li><b>No connector in this repo has a verified live write.</b> Write paths have been exercised
        against mock vendor servers for some connectors and against nothing at all for others. Anything
        that reads as "bidirectional works" is overstating what was measured.</li>
    </ol>
    <p style="margin:12px 0 0; color:var(--muted); font-size:13.5px;">
      Rows proven are counted from a queryable database so a claim can be re-checked rather than taken
      on trust. A connector at the <b>${esc(BASELINE.label)}</b> tier has passed the credential-free build
      matrix — spec conformance, mock vendor server, anti-vacuous assertions — but has contacted no live system.</p>
  </section>

${categorySections}

  <section class="held">
    <h2>Held — built, not published <span class="catcount">(${held.length})</span></h2>
    <p>Present in the repo and excluded from the catalog by <code>private: true</code>, so
      <code>mj app install</code> cannot resolve them. Listed for completeness; they are not offered to clients.</p>
    ${tableFor(held)}
  </section>

${renderAdvertised(model.advertised)}

  <footer>
    Evidence data as of ${esc(dataAsOf)} · package versions as of the current <code>connectors-catalog.json</code> ·
    platform actions snapshot from MemberJunction/MJ <code>${esc(actions.source.commit)}</code> (${esc(
      actions.source.capturedAt,
    )}).
    <br><span class="genstamp">Generated by scripts/build-overview-docs.mjs — regenerated on every push to main.</span>
  </footer>
</main>
</body>
</html>
`;
}

/**
 * "What Sales advertises vs what the repo can back" — the section that makes this a reconciliation
 * rather than an inventory.
 *
 * Ordered worst-first on purpose: the systems with nothing behind them are the ones that cost money
 * when they surface late, so they are not buried under the 37 rows that are fine.
 */
function renderAdvertised(adv) {
  if (!adv) return '';

  const KIND = {
    absent: {
      label: 'Not built',
      cls: 'k-absent',
      what: 'No connector, no action pack, no provider in the repo. Nothing to install.',
    },
    action: {
      label: 'Actions only',
      cls: 'k-action',
      what: 'An agent can act on this system. No data replicates into MemberJunction, so there is nothing to report on.',
    },
    held: {
      label: 'Built, held',
      cls: 'k-held',
      what: 'Code exists but <code>private: true</code> keeps it out of the catalog — not installable today.',
    },
    provider: {
      label: 'Outbound channel',
      cls: 'k-prov',
      what: 'A delivery channel MemberJunction sends through, not a system it reads from.',
    },
    missing: {
      label: 'Mapping stale',
      cls: 'k-absent',
      what: 'advertised-systems.json names a connector path that no longer exists — fix the mapping.',
    },
    data: { label: 'Data integration', cls: 'k-data', what: 'Replicates records into MemberJunction.' },
  };
  const ORDER = ['absent', 'missing', 'held', 'action', 'provider', 'data'];

  const groups = ORDER.map((kind) => {
    const rows = adv.rows.filter((r) => r.kind === kind);
    if (!rows.length) return '';
    const meta = KIND[kind];
    const items = rows
      .map((r) => {
        const detail =
          r.kind === 'data'
            ? `${fmt(r.connector.support?.proven.rows ?? 0)} rows proven · ${r.connector.declared?.objects ?? r.connector.objectCount ?? '—'} objects`
            : r.kind === 'action'
              ? `pack: ${esc(r.system.actionPack)}`
              : r.kind === 'held'
                ? `<code>${esc(r.system.matches)}</code>`
                : '';
        return `<tr><td><b>${esc(r.name)}</b></td><td class="advmeta">${esc(r.category)}</td><td class="advmeta">${detail}</td></tr>`;
      })
      .join('\n');
    return `
    <div class="advgroup ${meta.cls}">
      <h3>${meta.label} <span class="catcount">(${rows.length})</span></h3>
      <p>${meta.what}</p>
      <div class="scroll"><table><tbody>${items}</tbody></table></div>
    </div>`;
  }).join('\n');

  const notBuilt = adv.tally.absent ?? 0;
  const actionOnly = adv.tally.action ?? 0;

  return `
  <section class="held">
    <h2>Advertised vs built <span class="catcount">(${adv.total} systems on the AD list)</span></h2>
    <p>Reconciles ${esc(adv.source)} against this repo. The register above lists what exists; this
      lists what is <em>sold</em>, and where the two disagree. Two disagreements cost money if they
      surface during delivery rather than during the sale:
      <b>${notBuilt} advertised systems have nothing behind them</b>, and
      <b>${actionOnly} are actions-only</b> — an agent can act on them, but no data lands, so a deal
      scoped as a data integration has no data to integrate.</p>
    <p style="margin:10px 0 0; color:var(--muted); font-size:13.5px;">
      Keep <code>docs/data/advertised-systems.json</code> in step with whatever Sales actually
      circulates — this section is only as accurate as that list.</p>
    ${groups}
  </section>`;
}

/* ------------------------------------------------------------------ *
 * Entry point
 * ------------------------------------------------------------------ */

function main() {
  let model;
  try {
    model = buildModel();
  } catch (err) {
    console.error(`✗ ${err.message}`);
    process.exit(1);
  }

  if (PARSE_ONLY) {
    const parsed = model.connectors.filter((c) => c.support).length;
    console.log(`✓ ${parsed} docs/SUPPORT.md file(s) parsed cleanly (${model.baseline} at the build baseline).`);
    return;
  }

  const outputs = [
    ['docs/index.html', renderIndex(model)],
    ['docs/marketing.html', renderMarketing(model)],
    ['docs/technical.html', renderTechnical(model)],
  ];

  if (CHECK) {
    const stale = outputs.filter(([rel, html]) => {
      const full = path.join(REPO_ROOT, rel);
      return !existsSync(full) || readFileSync(full, 'utf8') !== html;
    });
    if (stale.length) {
      console.error(`✗ Stale: ${stale.map(([rel]) => rel).join(', ')}`);
      console.error('  Run: node scripts/build-overview-docs.mjs');
      process.exit(1);
    }
    console.log(`✓ ${outputs.map(([rel]) => rel).join(', ')} are up to date.`);
    return;
  }

  for (const [rel, html] of outputs) writeFileSync(path.join(REPO_ROOT, rel), html);
  console.log(
    `Wrote ${outputs.map(([rel]) => rel).join(', ')} — ${model.published.length} published ` +
      `(${model.documented} with measured evidence, ${model.baseline} at baseline), ${model.held.length} held, ` +
      `${fmt(model.actions.actionCount)} platform actions, data as of ${model.dataAsOf}.`,
  );
}

main();
