import { createHash } from 'node:crypto';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const lockPath = resolve(root, 'artwork/header-artwork.lock.json');
const args = process.argv.slice(2);
const sync = args.includes('--sync');
const updateLock = args.includes('--update-lock');
const index = args.indexOf('--assets-root');
const sourceRoot = index === -1 ? undefined : args[index + 1];
const hash = (bytes) => createHash('sha256').update(bytes).digest('hex');
if (updateLock && !sync) throw Error('--update-lock requires --sync');
if (sync && !sourceRoot) throw Error('--sync requires --assets-root /path/to/clashking_assets');
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--assets-root') { i++; continue; }
  if (!['--check', '--sync', '--update-lock'].includes(args[i])) throw Error(`Unknown argument: ${args[i]}`);
}
let lock = JSON.parse(await readFile(lockPath, 'utf8'));
if (sync) {
  const bytes = await readFile(resolve(sourceRoot, 'artwork/app-headers.json'));
  const source = JSON.parse(bytes);
  if (source.version !== 1) throw Error('Unsupported artwork manifest');
  if (!updateLock && hash(bytes) !== lock.sourceManifestSha256)
    throw Error('Assets selection changed. Review it, then rerun with --update-lock.');
  lock = { version: 1, sourceRepository: 'https://github.com/ClashKingInc/ClashKingAssets',
    sourceManifest: 'artwork/app-headers.json', sourceManifestSha256: hash(bytes), files: source.files };
}
if (lock.version !== 1 || !Array.isArray(lock.files) || !lock.files.length) throw Error('Invalid artwork lock');
const paths = new Set(), ids = new Set();
for (const entry of lock.files) {
  if (typeof entry.path !== 'string' || !/^clashking\/(headers|landscapes)\/[a-zA-Z0-9_./-]+\.(webp|png|jpg)$/u.test(entry.path)
    || entry.path.split('/').some(part => part === '..' || part === '.' || part === '')
    || !/^[a-f0-9]{64}$/u.test(entry.sha256) || !Number.isSafeInteger(entry.bytes) || entry.bytes <= 0
    || typeof entry.id !== 'string' || ids.has(entry.id) || paths.has(entry.path)) throw Error('Invalid artwork entry');
  paths.add(entry.path); ids.add(entry.id);
  const target = resolve(root, 'assets/generated', entry.path);
  if (!target.startsWith(resolve(root, 'assets/generated') + sep)) throw Error('Invalid output path');
  const bytes = await readFile(sync ? resolve(sourceRoot, 'assets', entry.path) : target);
  if (bytes.byteLength !== entry.bytes || hash(bytes) !== entry.sha256) throw Error(`Artwork bytes differ: ${entry.path}`);
  if (sync) { await mkdir(dirname(target), { recursive: true }); await writeFile(target, bytes); }
}
if (updateLock) await writeFile(lockPath, JSON.stringify(lock, null, 2) + '\n');
console.log(`${sync ? 'Synced' : 'Verified'} ${lock.files.length} pinned bundled header illustrations; no network requests.`);
