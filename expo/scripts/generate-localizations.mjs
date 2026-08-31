import { parse } from '@formatjs/icu-messageformat-parser';
import { readdirSync, readFileSync, mkdirSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const expoRoot = resolve(scriptDirectory, '..');
const sourceCatalogRoot = resolve(expoRoot, 'src/i18n/arb');
const outputRoot = resolve(expoRoot, 'src/i18n/catalogs');
const generatedModulePath = resolve(expoRoot, 'src/i18n/catalogs.generated.ts');

const files = readdirSync(sourceCatalogRoot)
  .filter((name) => /^app_[A-Za-z_]+\.arb$/.test(name))
  .sort((left, right) => left.localeCompare(right));
const template = readArb('app_en.arb');
const templateMessages = messagesFrom(template);
const templateKeys = Object.keys(templateMessages);
const catalogs = [];

for (const file of files) {
  const locale = file.slice('app_'.length, -'.arb'.length);
  const rawMessages = messagesFrom(readArb(file));
  const missing = templateKeys.filter((key) => typeof rawMessages[key] !== 'string');
  if (missing.length > 0) {
    throw new Error(`${file} is missing ${missing.length} messages: ${missing.join(', ')}`);
  }

  const messages = Object.fromEntries(
    templateKeys.map((key) => {
      const message = rawMessages[key];
      validateMessage(locale, key, message);
      return [key, message];
    }),
  );
  catalogs.push({ locale, messages });
}

mkdirSync(outputRoot, { recursive: true });
const expected = new Map();
for (const { locale, messages } of catalogs) {
  expected.set(resolve(outputRoot, `${locale}.json`), `${JSON.stringify(messages, null, 2)}\n`);
}
expected.set(generatedModulePath, generatedModule(catalogs.map(({ locale }) => locale)));

if (process.argv.includes('--check')) {
  for (const [path, contents] of expected) {
    if (readFileSync(path, 'utf8') !== contents) {
      throw new Error(`Generated localization is stale: ${path}`);
    }
  }
} else {
  for (const [path, contents] of expected) writeFileSync(path, contents);
}

function readArb(file) {
  return JSON.parse(readFileSync(resolve(sourceCatalogRoot, file), 'utf8'));
}

function messagesFrom(arb) {
  return Object.fromEntries(
    Object.entries(arb).filter(([key, value]) => !key.startsWith('@') && typeof value === 'string'),
  );
}

function validateMessage(locale, key, message) {
  try {
    parse(message, { captureLocation: false, shouldParseSkeletons: true });
  } catch (error) {
    throw new Error(`Invalid ICU message ${locale}.${key}: ${error.message}`);
  }
}

function generatedModule(locales) {
  const imports = locales
    .map((locale) => `import ${identifier(locale)} from './catalogs/${locale}.json';`)
    .join('\n');
  const entries = locales
    .map((locale) => `  ${JSON.stringify(locale)}: ${identifier(locale)},`)
    .join('\n');
  return `${imports}\n\nexport const catalogs = {\n${entries}\n} as const;\n\nexport type SupportedLocale = keyof typeof catalogs;\nexport type MessageKey = keyof typeof catalogs.en;\n`;
}

function identifier(locale) {
  return `catalog${locale.replace(/[^A-Za-z0-9]/g, '_')}`;
}
