import { readdirSync, readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const expoRoot = resolve(scriptDirectory, '..');
const flutterCatalogRoot = resolve(expoRoot, '../lib/l10n');
const expoCatalogRoot = resolve(expoRoot, 'src/i18n/arb');
const removedLiveActivityKeys = new Set([
  'settingsLiveActivityTest',
  'settingsLiveActivityStart',
  'settingsLiveActivityStartSubtitle',
  'settingsLiveActivityUpdate',
  'settingsLiveActivityUpdateSubtitle',
  'settingsLiveActivityEnd',
  'settingsLiveActivityEndSubtitle',
]);

const flutterFiles = arbFiles(flutterCatalogRoot);
const expoFiles = arbFiles(expoCatalogRoot);
assertEqual('locale files', flutterFiles, expoFiles);

for (const file of flutterFiles) {
  const flutterCatalog = readArb(flutterCatalogRoot, file);
  const expoCatalog = readArb(expoCatalogRoot, file);
  for (const key of removedLiveActivityKeys) {
    delete flutterCatalog[key];
    delete flutterCatalog[`@${key}`];
  }
  assertEqual(`${file} keys`, Object.keys(flutterCatalog), Object.keys(expoCatalog));
  for (const [key, value] of Object.entries(flutterCatalog)) {
    const actual = expoCatalog[key];
    if (JSON.stringify(actual) !== JSON.stringify(value)) {
      throw new Error(`${file}.${key} differs from the frozen Flutter catalog.`);
    }
  }
}

function arbFiles(root) {
  return readdirSync(root)
    .filter((name) => /^app_[A-Za-z_]+\.arb$/.test(name))
    .sort((left, right) => left.localeCompare(right));
}

function readArb(root, file) {
  return JSON.parse(readFileSync(resolve(root, file), 'utf8'));
}

function assertEqual(label, expected, actual) {
  if (JSON.stringify(expected) !== JSON.stringify(actual)) {
    throw new Error(
      `${label} differ. Expected ${JSON.stringify(expected)}, received ${JSON.stringify(actual)}.`,
    );
  }
}
