#!/usr/bin/env node
/**
 * Validates each connector's migrations: Flyway-named (`V<YYYYMMDDHHMM>__<desc>.sql` / `B…`),
 * strictly-increasing timestamps within a connector, and a matching `.pg.sql` in migrations-pg/.
 * (The PG-drift check is also enforced by build-pg-migrations.mjs --check; this is the structural gate.)
 */
import { readFileSync, readdirSync, statSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
function connectorDirs(dir, out = []) {
  for (const e of readdirSync(dir)) {
    if (['node_modules', 'dist', '.git', '.github', '.changeset', 'scripts', 'packages'].includes(e)) continue;
    const p = join(dir, e); if (!statSync(p).isDirectory()) continue;
    if (existsSync(join(p, 'mj-app.json'))) out.push(p); else connectorDirs(p, out);
  }
  return out;
}

const NAME = /^[BV](\d{12})__[A-Za-z0-9._-]+\.sql$/;
const errors = [];
for (const appDir of connectorDirs(ROOT)) {
  const migDir = join(appDir, 'migrations');
  if (!existsSync(migDir)) continue;
  const rel = appDir.slice(ROOT.length + 1);
  const sql = readdirSync(migDir).filter((f) => f.endsWith('.sql'));
  let last = 0;
  for (const f of sql.sort()) {
    const m = f.match(NAME);
    if (!m) { errors.push(`${rel}/migrations/${f}: not Flyway-named (V<YYYYMMDDHHMM>__<desc>.sql)`); continue; }
    const ts = Number(m[1]);
    if (ts <= last) errors.push(`${rel}/migrations/${f}: timestamp ${ts} not greater than previous ${last}`);
    last = ts;
    if (!existsSync(join(appDir, 'migrations-pg', f.replace(/\.sql$/, '.pg.sql')))) errors.push(`${rel}/migrations/${f}: missing migrations-pg/${f.replace(/\.sql$/, '.pg.sql')} (run npm run migrations:pg)`);
  }
}

if (errors.length) { console.error(`✗ ${errors.length} migration issue(s):\n` + errors.map((e) => '  - ' + e).join('\n')); process.exit(1); }
console.log('✓ migrations valid (names, ordering, PG parity).');
