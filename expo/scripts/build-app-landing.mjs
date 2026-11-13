import { cp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import ts from 'typescript';
import { prepareAppLanding } from './prepare-app-landing.mjs';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const output = join(root, 'dist');
const stores = await prepareAppLanding();
// dist is the existing, ignored build output. Do not retain the old app bundle
// or its routes when shipping the native-only landing artifact.
await rm(output, { recursive: true, force: true });
await mkdir(output, { recursive: true });
for (const file of [
  'landing',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'favicon.png',
  'auth',
  '.well-known',
  '_redirects',
  '_headers',
  'sw.js',
]) {
  await mkdir(dirname(join(output, file)), { recursive: true });
  await cp(join(root, 'public', file), join(output, file), { recursive: true });
}
let html = await readFile(join(root, 'public/app-landing.html'), 'utf8');
// Store destinations also work without JavaScript, including crawler fetches.
for (const [name, id] of [
  ['App Store', 'ios'],
  ['Google Play', 'android'],
]) {
  const href = stores[name];
  if (!href) continue;
  const escaped = href.replaceAll('&', '&amp;').replaceAll('"', '&quot;');
  html = html
    .replace(
      new RegExp(`id="store-${id}"([\\s\\S]*?)aria-disabled="true"`),
      `id="store-${id}"$1href="${escaped}" rel="noopener noreferrer"`,
    )
    .replace(`id="store-${id}-status">Coming soon`, `id="store-${id}-status">Download the app`);
}
// Inline the tiny portable modules: Pages advanced mode ships one Worker,
// while native stories and web stories retain the same fitting contract.
const worker = await readFile(join(root, 'public/landing/post-preview-worker.js'), 'utf8');
// Compile directly into dist. Changing .gitignore to hide intermediate web
// modules changes Expo's native fingerprint even though no native code moved.
async function portableSource(path) {
  const input = await readFile(join(root, path), 'utf8');
  return ts
    .transpileModule(input, {
      compilerOptions: { target: ts.ScriptTarget.ES2022, module: ts.ModuleKind.ES2022 },
    })
    .outputText.replaceAll('export ', '');
}
const renderer = await portableSource('src/features/home/data/announcement-content.ts');
const storyContract = await portableSource(
  'src/features/home/presentation/announcement-webview-contract.ts',
);
await writeFile(
  join(output, '_worker.js'),
  renderer +
    '\n' +
    storyContract +
    '\n' +
    worker.replace('/* CK_STORE_LINKS */ {}', JSON.stringify(stores)),
);
await writeFile(
  join(output, '_routes.json'),
  JSON.stringify({ version: 1, include: ['/posts/*', '/share/posts/*'], exclude: [] }),
);
await writeFile(join(output, 'index.html'), html);
await writeFile(join(output, '404.html'), html);
console.log('Built native-app landing only; no Expo web application exported.');
