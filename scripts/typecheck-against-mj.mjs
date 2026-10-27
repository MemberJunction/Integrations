#!/usr/bin/env node
/**
 * typecheck-against-mj.mjs — does every package in this repo compile against a GIVEN MemberJunction
 * version, rather than the 5.x the workspace happens to have installed?
 *
 * WHY THIS EXISTS
 *   A peer range like `>=5.42.0 <7.0.0` is a CLAIM about MJ 6.x. The workspace builds against 5.x
 *   (devDependencies), so `npm run build` cannot tell you whether that claim is true — it re-proves 5.x.
 *   This script installs the requested MJ version into a scratch directory and type-checks each package
 *   with the five framework packages resolved from there instead. Compile-time API compatibility only:
 *   a pass here is not a runtime pass against a 6.x host.
 *
 * HOW (and the two things that silently make it a no-op if you get them wrong)
 *   Each package gets a throwaway tsconfig that `extends` its own and maps the framework packages via
 *   `paths`. Nothing in the repo is modified.
 *   1. The `paths` targets are the entry `.d.ts` FILES, not the package directories. Connectors compile in
 *      ESM mode (NodeNext + "type": "module"), and ESM-mode resolution treats a bare-directory target as a
 *      relative directory import, which ESM forbids — the candidate fails and TypeScript quietly falls back
 *      to the repo's 5.x copy. The first version of this harness passed 61/61 that way and had proven nothing.
 *      (Safe because no package imports a `@memberjunction/*` subpath; the script checks that.)
 *   2. `typeRoots` is set explicitly. The throwaway config lives outside the repo, so TypeScript's automatic
 *      `@types` lookup walks the wrong ancestors and every Node global (`fetch`, `Buffer`, `console`) vanishes.
 *   The script then PROVES the mapping with `--explainFiles` on one package and fails if any framework
 *   `.d.ts` still came from the repo's own node_modules.
 *
 * USAGE
 *   node scripts/typecheck-against-mj.mjs                    # against the `edge` dist-tag (currently 6.x)
 *   node scripts/typecheck-against-mj.mjs --mj 6.1.0-edge.5  # a specific version
 *   node scripts/typecheck-against-mj.mjs --mj latest        # sanity: should match `npm run build`
 *   node scripts/typecheck-against-mj.mjs --only NetForum    # substring filter on the package dir
 *   --scratch <dir>  where to install (default: <os tmpdir>/mj-compat); an install of the same version is reused.
 */
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync, spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const ROOT = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const PKGS = ['core', 'core-entities', 'global', 'integration-engine', 'integration-engine-base'];
const args = process.argv.slice(2);
const opt = (name, dflt) => { const i = args.indexOf(name); return i >= 0 && args[i + 1] ? args[i + 1] : dflt; };
const requested = opt('--mj', 'edge');
const scratch = opt('--scratch', path.join(os.tmpdir(), 'mj-compat'));
const only = opt('--only', null);

// 1. Resolve the version and install it (once per version).
const version = execFileSync('npm', ['view', `@memberjunction/core@${requested}`, 'version'], { encoding: 'utf8' }).trim().split('\n').pop();
if (!/^\d+\.\d+\.\d+/.test(version)) { console.error(`Could not resolve @memberjunction/core@${requested}`); process.exit(2); }
const installDir = path.join(scratch, `mj-${version}`);
const mj = path.join(installDir, 'node_modules', '@memberjunction');
const installed = () => { try { return JSON.parse(fs.readFileSync(path.join(mj, 'core', 'package.json'), 'utf8')).version === version; } catch { return false; } };
if (!installed()) {
  fs.mkdirSync(installDir, { recursive: true });
  if (!fs.existsSync(path.join(installDir, 'package.json'))) fs.writeFileSync(path.join(installDir, 'package.json'), '{"name":"mj-compat-scratch","private":true}\n');
  console.log(`Installing @memberjunction/*@${version} into ${installDir} …`);
  execFileSync('npm', ['install', '--ignore-scripts', '--no-audit', '--no-fund', '--loglevel=error', ...PKGS.map(p => `@memberjunction/${p}@${version}`)], { cwd: installDir, stdio: 'inherit' });
}
for (const p of PKGS) if (!fs.existsSync(path.join(mj, p, 'dist', 'index.d.ts'))) { console.error(`@memberjunction/${p}@${version} has no dist/index.d.ts — the entry-file mapping below needs one.`); process.exit(2); }
console.log(`Type-checking against @memberjunction/*@${version}\n`);

// 2. Refuse to proceed if any source imports a framework SUBPATH — the entry-file mapping would not cover it.
const subpath = execFileSync('bash', ['-c', `grep -rhoE "from '@memberjunction/(${PKGS.join('|')})/[^']+'" --include='*.ts' ${ROOT}/*/*/src ${ROOT}/Shared/*/src 2>/dev/null | sort -u || true`], { encoding: 'utf8' }).trim();
if (subpath) { console.error('Subpath imports of a framework package exist; extend the paths mapping before trusting this check:\n' + subpath); process.exit(2); }

// 3. One throwaway tsconfig per package, checked 4 at a time.
const tsconfigDir = path.join(scratch, 'tsconfigs');
fs.mkdirSync(tsconfigDir, { recursive: true });
const dirs = execFileSync('find', [ROOT, '-maxdepth', '3', '-name', 'tsconfig.json', '-not', '-path', '*/node_modules/*'], { encoding: 'utf8' })
  .trim().split('\n').map(p => path.dirname(p)).filter(d => d !== ROOT && (!only || d.includes(only))).sort();
const tsc = path.join(ROOT, 'node_modules', '.bin', 'tsc');

function configFor(d) {
  const paths = {};
  for (const p of PKGS) paths[`@memberjunction/${p}`] = [path.join(mj, p, 'dist', 'index.d.ts')];
  const typeRoots = [path.join(d, 'node_modules', '@types'), path.join(ROOT, 'node_modules', '@types')].filter(t => fs.existsSync(t));
  const cfgPath = path.join(tsconfigDir, path.relative(ROOT, d).replace(/\//g, '__') + '.json');
  fs.writeFileSync(cfgPath, JSON.stringify({ extends: path.join(d, 'tsconfig.json'), compilerOptions: { noEmit: true, baseUrl: d, paths, typeRoots }, include: [path.join(d, 'src', '**', '*')] }, null, 2));
  return cfgPath;
}

function check(d) {
  return new Promise(resolve => {
    const cfgPath = configFor(d);
    const t0 = Date.now();
    const child = spawn(tsc, ['-p', cfgPath, '--pretty', 'false'], { cwd: d });
    let out = '';
    child.stdout.on('data', c => { out += c; });
    child.stderr.on('data', c => { out += c; });
    child.on('close', code => {
      const errors = out.split('\n').filter(l => /error TS\d+/.test(l)).map(e => e.replace(ROOT + '/', ''));
      resolve({ dir: path.relative(ROOT, d), ok: code === 0, errors, ms: Date.now() - t0 });
    });
  });
}

const results = [];
const queue = [...dirs];
await Promise.all(Array.from({ length: 4 }, async () => {
  for (let d = queue.shift(); d !== undefined; d = queue.shift()) {
    const r = await check(d);
    results.push(r);
    console.log(`${r.ok ? 'PASS' : 'FAIL'}  ${r.dir.padEnd(38)} ${String(r.errors.length).padStart(3)} error(s)  ${r.ms}ms`);
    if (!r.ok) for (const e of r.errors.slice(0, 5)) console.log(`        ${e.slice(0, 230)}`);
  }
}));

// 4. Prove the mapping took effect, on the first package checked.
let proof = { from6: 0, from5: 0 };
if (dirs.length > 0) {
  let out = '';
  try { out = execFileSync(tsc, ['-p', configFor(dirs[0]), '--explainFiles', '--pretty', 'false'], { cwd: dirs[0], encoding: 'utf8' }); } catch (e) { out = String(e.stdout ?? '') + String(e.stderr ?? ''); }
  const fw = new RegExp(`node_modules/@memberjunction/(${PKGS.join('|')})/.*\\.d\\.ts$`);
  // explainFiles prints program files relative to cwd and TypeScript reports REAL paths, so classify by
  // realpath on both sides — a symlinked scratch dir would otherwise count every 6.x file as 5.x.
  const realMj = fs.realpathSync(mj);
  const files = out.split('\n').filter(l => l.length > 0 && !l.startsWith(' ') && fw.test(l.trim()));
  const real = (l) => { try { return fs.realpathSync(path.resolve(dirs[0], l.trim())); } catch { return path.resolve(dirs[0], l.trim()); } };
  const from6 = files.filter(l => real(l).startsWith(realMj + path.sep)).length;
  proof = { from6, from5: files.length - from6 };
}

results.sort((a, b) => a.dir.localeCompare(b.dir));
const pass = results.filter(r => r.ok).length;
console.log(`\nMapping proof (${path.relative(ROOT, dirs[0] ?? ROOT)}): ${proof.from6} framework .d.ts from the ${version} install, ${proof.from5} from the repo's own node_modules.`);
console.log(`${pass}/${results.length} package(s) type-check against @memberjunction/*@${version}.`);
if (proof.from6 === 0 || proof.from5 > 0) { console.error('✗ The mapping did not take effect — this result proves nothing. See the header comment.'); process.exit(1); }
if (pass !== results.length) { console.error('✗ FAILING: ' + results.filter(r => !r.ok).map(r => r.dir).join(', ')); process.exit(1); }
console.log('✓ compile-time compatible.');
