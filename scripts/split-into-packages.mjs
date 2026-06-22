#!/usr/bin/env node
/**
 * Splits the single shared `@memberjunction/integration-connectors` package into ONE PACKAGE PER
 * CONNECTOR, so each Open App is fully self-contained and independent (installing one connector
 * pulls only that connector's code — no coupling). Stays a single monorepo.
 *
 * For each connector <Class>Connector.ts in packages/integration-connectors/src:
 *   - the connector that has an Open App (<Category>/<Connector>/mj-app.json) becomes that dir's
 *     own npm package: package.json + tsconfig + src/<Class>.ts + index.ts + __tests__/.
 *   - RelationalDB / FileFeed (framework primitives, no vendor catalog / Open App) become code-only
 *     packages under Platform/ (no mj-app.json).
 * mj-app.json + the Integration metadata's ImportPath are repointed at the connector's OWN package.
 *
 * Dependencies are derived per connector from its actual imports (framework → peer deps; zod/mssql/
 * jsonwebtoken → deps; a connector→connector source import, e.g. Fonteva→Salesforce, → a dep on that
 * sibling's package, with the import rewritten to the package specifier).
 *
 * The cross-connector live harness (e2e-sync.test.ts + db-availability.ts) is NOT a per-connector
 * unit test and is dropped from the packages (live testing is separate, credential-gated).
 *
 * Run from the repo root:  node scripts/split-into-packages.mjs
 */
import { readFileSync, writeFileSync, mkdirSync, readdirSync, statSync, existsSync, rmSync, cpSync } from 'node:fs';
import { join, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const SHARED = join(ROOT, 'packages', 'integration-connectors', 'src');
const TESTS = join(SHARED, '__tests__');
const RANGE = '>=5.43.0 <6.0.0';
const PINNED = '^5.43.0';
const FRAMEWORK = new Set(['@memberjunction/core', '@memberjunction/core-entities', '@memberjunction/global', '@memberjunction/integration-engine', '@memberjunction/integration-engine-base']);
const EXTERNAL = { jsonwebtoken: '9.0.3', mssql: '^12.2.0', zod: '~3.24.4' };

const writeJson = (p, o) => { mkdirSync(dirname(p), { recursive: true }); writeFileSync(p, JSON.stringify(o, null, 2) + '\n'); };

// ---- 1. Build className -> { dir, pkg, openApp } from the Open App dirs + the two primitives ----
function findOpenApps(dir, out = []) {
  for (const e of readdirSync(dir)) {
    if (['node_modules', 'dist', '.git', '.github', '.changeset', 'scripts', 'packages'].includes(e)) continue;
    const p = join(dir, e);
    if (statSync(p).isDirectory()) findOpenApps(p, out);
    else if (e === 'mj-app.json') out.push(p);
  }
  return out;
}
const byClass = {};
for (const manifestPath of findOpenApps(ROOT)) {
  const appDir = dirname(manifestPath);
  const manifest = JSON.parse(readFileSync(manifestPath, 'utf-8'));
  const integDir = join(appDir, 'metadata', 'integration');
  const integFile = readdirSync(integDir).find((f) => f.endsWith('.integration.json'));
  const raw = JSON.parse(readFileSync(join(integDir, integFile), 'utf-8'));
  const recs = Array.isArray(raw) ? raw : [raw];
  const className = recs.find((r) => r?.fields?.ClassName)?.fields.ClassName;
  byClass[className] = { dir: appDir, pkg: '@memberjunction/' + manifest.name, openApp: true, manifestPath, manifest, integDir, integFile };
}
// primitives with no Open App
byClass['RelationalDBConnector'] = { dir: join(ROOT, 'Platform', 'RelationalDB'), pkg: '@memberjunction/connector-relational-db', openApp: false };
byClass['FileFeedConnector'] = { dir: join(ROOT, 'Platform', 'FileFeed'), pkg: '@memberjunction/connector-file-feed', openApp: false };

// ---- 2. Per connector: collect its files, derive deps, write the package ----
const connectorFiles = readdirSync(SHARED).filter((f) => f.endsWith('Connector.ts'));
const testFiles = existsSync(TESTS) ? readdirSync(TESTS).filter((f) => f.endsWith('.ts')) : [];
const DROP_TESTS = new Set(['e2e-sync.test.ts', 'db-availability.ts']);

const importsOf = (txt) => [...txt.matchAll(/from ['"]([^'"]+)['"]/g)].map((m) => m[1]);
const siblingClassOf = (spec) => { const m = spec.match(/^\.\/(\w+Connector)\.js$/); return m ? m[1] : null; };

const built = [];
for (const file of connectorFiles) {
  const className = file.replace('.ts', '');
  const info = byClass[className];
  if (!info) { console.warn(`! no mapping for ${className} — skipped`); continue; }
  const tdir = info.dir;
  const srcDir = join(tdir, 'src');
  const tDir = join(srcDir, '__tests__');
  mkdirSync(tDir, { recursive: true });

  // the connector source + its tests (anything starting with the class name) + fixtures they need
  const myTests = testFiles.filter((t) => t.startsWith(className) && !DROP_TESTS.has(t));
  const allMyFiles = [join(SHARED, file), ...myTests.map((t) => join(TESTS, t))];

  // derive deps + collect sibling rewrites
  const peer = new Set(), deps = {}, devExtra = {};
  const rewrites = {};
  for (const fp of allMyFiles) {
    let txt = readFileSync(fp, 'utf-8');
    for (const spec of importsOf(txt)) {
      if (FRAMEWORK.has(spec)) peer.add(spec);
      else if (EXTERNAL[spec]) { deps[spec] = EXTERNAL[spec]; if (spec === 'jsonwebtoken') devExtra['@types/jsonwebtoken'] = '^9.0.10'; }
      else { const sib = siblingClassOf(spec); if (sib && byClass[sib]) { deps[byClass[sib].pkg] = '^1.0.0'; rewrites[spec] = byClass[sib].pkg; } }
    }
  }

  // write source + tests with sibling imports rewritten to package specifiers
  const applyRewrites = (txt) => { for (const [from, to] of Object.entries(rewrites)) txt = txt.split(`'${from}'`).join(`'${to}'`).split(`"${from}"`).join(`"${to}"`); return txt; };
  writeFileSync(join(srcDir, file), applyRewrites(readFileSync(join(SHARED, file), 'utf-8')));
  for (const t of myTests) writeFileSync(join(tDir, t), applyRewrites(readFileSync(join(TESTS, t), 'utf-8')));

  // fixtures referenced by this connector's tests
  for (const t of myTests) {
    for (const m of readFileSync(join(TESTS, t), 'utf-8').matchAll(/fixtures\/([\w-]+)/g)) {
      const sub = m[1]; const from = join(TESTS, 'fixtures', sub);
      if (existsSync(from)) cpSync(from, join(tDir, 'fixtures', sub), { recursive: true });
    }
  }

  // index.ts: re-export the connector + a no-op startup shim the Open App loader names
  writeFileSync(join(srcDir, 'index.ts'),
    `export * from './${className}.js';\n\n` +
    `/** Open App bootstrap entry: importing this module ran the connector's @RegisterClass decorator;\n` +
    ` *  this no-op satisfies the loader's required startupExport and forces the import at MJAPI boot. */\n` +
    `export function registerConnector(): void { /* registration happened on import */ }\n`);

  // package.json
  const peerDependencies = {}, devDependencies = { '@types/node': '24.10.11', 'tsc-alias': '^1.8.16', typescript: '^5.9.3', vitest: '^4.0.18', ...devExtra };
  for (const f of [...peer].sort()) { peerDependencies[f] = RANGE; devDependencies[f] = PINNED; }
  writeJson(join(tdir, 'package.json'), {
    name: info.pkg, version: '1.0.0',
    description: `MemberJunction ${className.replace('Connector', '')} connector.`,
    type: 'module', main: 'dist/index.js', types: 'dist/index.d.ts', files: ['/dist'],
    scripts: { build: 'tsc && tsc-alias -f', test: 'vitest run' },
    author: 'MemberJunction.com', license: 'ISC',
    peerDependencies, dependencies: Object.fromEntries(Object.entries(deps).sort()), devDependencies,
    repository: { type: 'git', url: 'https://github.com/MemberJunction/Integrations' },
  });
  writeJson(join(tdir, 'tsconfig.json'), { extends: '../../tsconfig.base.json', compilerOptions: { outDir: 'dist', rootDir: 'src' }, include: ['src/**/*'], exclude: ['node_modules', 'dist', 'src/__tests__/**', 'src/**/*.test.ts'] });
  writeFileSync(join(tdir, 'vitest.config.ts'), `import { defineConfig } from 'vitest/config';\n\nexport default defineConfig({ test: { environment: 'node', testTimeout: 60000, include: ['src/**/*.test.ts'] } });\n`);

  // repoint the Open App at its own package + fix the metadata ImportPath
  if (info.openApp) {
    info.manifest.packages.server = [{ name: info.pkg, role: 'bootstrap', startupExport: 'registerConnector' }];
    writeJson(info.manifestPath, info.manifest);
    const ip = join(info.integDir, info.integFile);
    const raw = JSON.parse(readFileSync(ip, 'utf-8'));
    const recs = Array.isArray(raw) ? raw : [raw];
    for (const r of recs) if (r?.fields?.ClassName) r.fields.ImportPath = info.pkg;
    writeJson(ip, Array.isArray(raw) ? raw : recs[0]);
  }
  built.push(`${basename(dirname(tdir))}/${basename(tdir)}  ${info.pkg}${myTests.length ? `  (+${myTests.length} test)` : ''}`);
}

// ---- 3. Remove the old shared package + repoint the workspace ----
rmSync(join(ROOT, 'packages', 'integration-connectors'), { recursive: true, force: true });
const rootPkg = JSON.parse(readFileSync(join(ROOT, 'package.json'), 'utf-8'));
rootPkg.workspaces = ['*/*'];
writeJson(join(ROOT, 'package.json'), rootPkg);

console.log(`Built ${built.length} per-connector packages:\n  ` + built.sort().join('\n  '));
