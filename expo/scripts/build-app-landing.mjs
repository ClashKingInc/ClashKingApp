import { cp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { prepareAppLanding } from './prepare-app-landing.mjs';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const output = join(root, 'dist');
await prepareAppLanding();
// dist is the existing, ignored build output. Do not retain the old app bundle
// or its routes when shipping the native-only landing artifact.
await rm(output, { recursive: true, force: true });
await mkdir(output, { recursive: true });
for (const file of [
  'landing',
  'icons/Icon-192.png',
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
const stores = {};
for (const [label, value, host] of [
  ['App Store', process.env.CK_IOS_STORE_URL, 'apps.apple.com'],
  ['Google Play', process.env.CK_ANDROID_STORE_URL, 'play.google.com'],
]) {
  if (!value) continue;
  const url = new URL(value);
  if (url.protocol !== 'https:' || url.hostname !== host)
    throw new Error('Invalid ' + label + ' URL');
  stores[label] = url.href;
}
if (Object.keys(stores).length)
  html = html.replace(
    '</head>',
    '<script>globalThis.CLASHKING_STORE_LINKS=' +
      JSON.stringify(stores).replaceAll('<', '\\u003c') +
      ';</script></head>',
  );
await writeFile(join(output, 'index.html'), html);
await writeFile(join(output, '404.html'), html);
console.log('Built native-app landing only; no Expo web application exported.');
