#!/usr/bin/env node
/**
 * Scaffolds a new connector mini Open App.  Usage:
 *
 *   node scripts/new-connector.mjs <Category> <ClassBase> [--name "Display Name"] [--rest|--base]
 *   e.g. node scripts/new-connector.mjs CRM Acme --name "Acme CRM"
 *
 * Produces a buildable, lint-passing connector at <Category>/<ClassBase>/ ready for metadata authoring:
 *   - mj-app.json        full Open App (schema mj_connector_<slug> + migrations + metadata + bootstrap package)
 *   - package.json       @memberjunction/connector-<slug> (framework as peerDependencies)
 *   - tsconfig.json  vitest.config.ts
 *   - src/<ClassBase>Connector.ts  +  src/index.ts (registerConnector shim)  +  src/__tests__/
 *   - metadata/          .mj-sync.json (+ integration/ + actions/ sync configs)  ← author the catalog here
 *   - migrations/ + migrations-pg/  (README; SQL is generated later via `mj sync push` + convert)
 *
 * After scaffolding: author metadata/, run `mj sync push` (migration creation), add a changeset, open a PR.
 */
import { writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const [category, classBase] = process.argv.slice(2).filter((a) => !a.startsWith('--'));
const displayFlag = process.argv.indexOf('--name');
const display = displayFlag > -1 ? process.argv[displayFlag + 1] : classBase;
const useBase = process.argv.includes('--base'); // extend BaseIntegrationConnector instead of REST

if (!category || !classBase) {
  console.error('Usage: node scripts/new-connector.mjs <Category> <ClassBase> [--name "Display Name"] [--base]');
  process.exit(1);
}

const slug = classBase.replace(/([a-z0-9])([A-Z])/g, '$1-$2').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
const pkg = `@memberjunction/connector-${slug}`;
const schema = `mj_connector_${slug.replace(/-/g, '_')}`;
const className = `${classBase}Connector`;
const appDir = join(ROOT, category, classBase);
if (existsSync(appDir)) { console.error(`${category}/${classBase} already exists`); process.exit(1); }

const write = (rel, content) => { const p = join(appDir, rel); mkdirSync(dirname(p), { recursive: true }); writeFileSync(p, content); };
const json = (rel, o) => write(rel, JSON.stringify(o, null, 2) + '\n');
const RANGE = '>=5.43.0 <6.0.0', PINNED = '^5.43.0';
const base = useBase ? 'BaseIntegrationConnector' : 'BaseRESTIntegrationConnector';

json('mj-app.json', {
  $schema: 'https://memberjunction.org/schemas/mj-app.schema.json',
  manifestVersion: 1, name: `connector-${slug}`, displayName: `${display} Connector`,
  description: `${display} connector for MemberJunction — full curated object catalog.`,
  version: '0.1.0', license: 'ISC',
  publisher: { name: 'MemberJunction', email: 'dev@memberjunction.com', url: 'https://memberjunction.com' },
  repository: 'https://github.com/MemberJunction/Integrations', mjVersionRange: RANGE,
  schema: { name: schema, createIfNotExists: true },
  migrations: { directory: 'migrations', engine: 'skyway' },
  metadata: { directory: 'metadata' },
  packages: { server: [{ name: pkg, role: 'bootstrap', startupExport: 'registerConnector' }] },
  categories: [category.toLowerCase()], tags: [slug, category.toLowerCase(), 'connector', 'integration'],
});

json('package.json', {
  name: pkg, version: '0.1.0', description: `MemberJunction ${classBase} connector.`,
  type: 'module', main: 'dist/index.js', types: 'dist/index.d.ts', files: ['/dist'],
  scripts: { build: 'tsc && tsc-alias -f', test: 'vitest run' }, author: 'MemberJunction.com', license: 'ISC',
  peerDependencies: { '@memberjunction/core': RANGE, '@memberjunction/core-entities': RANGE, '@memberjunction/global': RANGE, '@memberjunction/integration-engine': RANGE },
  dependencies: { zod: '~3.24.4' },
  devDependencies: { '@memberjunction/core': PINNED, '@memberjunction/core-entities': PINNED, '@memberjunction/global': PINNED, '@memberjunction/integration-engine': PINNED, '@types/node': '24.10.11', 'tsc-alias': '^1.8.16', typescript: '^5.9.3', vitest: '^4.0.18' },
  repository: { type: 'git', url: 'https://github.com/MemberJunction/Integrations' },
});

json('tsconfig.json', { extends: '../../tsconfig.base.json', compilerOptions: { outDir: 'dist', rootDir: 'src' }, include: ['src/**/*'], exclude: ['node_modules', 'dist', 'src/__tests__/**', 'src/**/*.test.ts'] });
write('vitest.config.ts', `import { defineConfig } from 'vitest/config';\n\nexport default defineConfig({ test: { environment: 'node', testTimeout: 60000, include: ['src/**/*.test.ts'] } });\n`);

write(`src/${className}.ts`, `import { RegisterClass } from '@memberjunction/global';
import { BaseIntegrationConnector, ${useBase ? '' : 'BaseRESTIntegrationConnector, '}} from '@memberjunction/integration-engine';

/**
 * ${display} connector. Implement the lifecycle surface (TestConnection, DiscoverObjects/Fields,
 * FetchChanges, generic CRUD) per the connector conventions in .claude/rules.
 */
@RegisterClass(BaseIntegrationConnector, '${className}')
export class ${className} extends ${base} {
  public override get IntegrationName(): string { return '${display}'; }
  // TODO: implement TestConnection / DiscoverObjects / DiscoverFields / FetchChanges / CRUD
}
`);

write('src/index.ts', `export * from './${className}.js';

/** Open App bootstrap entry: importing this module ran the connector's @RegisterClass decorator;
 *  this no-op satisfies the loader's required startupExport and forces the import at MJAPI boot. */
export function registerConnector(): void { /* registration happened on import */ }
`);

write(`src/__tests__/${className}.test.ts`, `import { describe, it, expect } from 'vitest';
import { ${className} } from '../${className}.js';

describe('${className}', () => {
  it('exposes the integration name', () => {
    expect(new ${className}().IntegrationName).toBe('${display}');
  });
});
`);

// metadata skeleton (author the catalog here, then `mj sync push`)
json('metadata/.mj-sync.json', { directoryOrder: ['integration', 'actions'], sqlLogging: { enabled: true, outputDirectory: '../migrations', formatAsMigration: false } });
json('metadata/integration/.mj-sync.json', { entity: 'MJ: Integrations', filePattern: '**/.*.json', defaults: {} });
json('metadata/actions/.mj-sync.json', { entity: 'MJ: Actions', filePattern: '**/.*.json', defaults: {}, lookupFields: { CategoryID: { entity: 'MJ: Action Categories', field: 'Name' } }, relatedEntities: { 'MJ: Action Params': { entity: 'MJ: Action Params', foreignKey: 'ActionID' }, 'MJ: Action Result Codes': { entity: 'MJ: Action Result Codes', foreignKey: 'ActionID' } } });

mkdirSync(join(appDir, 'migrations'), { recursive: true });
mkdirSync(join(appDir, 'migrations-pg'), { recursive: true });
write('migrations/README.md', `# Migrations (generated)\n\nAuthor \`../metadata/\` then run \`mj sync push --dir metadata\` to capture the seed SQL here,\nname it \`V<YYYYMMDDHHMM>__${slug}__Metadata.sql\` (\`scripts/wrap-migration.mjs\`), and let CI convert to\n\`../migrations-pg/\`. The migration body seeds \`__mj\`; this connector's \`${schema}\` schema holds only Flyway history.\n`);
write('migrations-pg/.gitkeep', '');

console.log(`✓ Scaffolded ${category}/${classBase}  →  ${pkg}  (schema ${schema})\n  Next: implement src/${className}.ts, author metadata/, then \`mj sync push\` + add a changeset.`);
