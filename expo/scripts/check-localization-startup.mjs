import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { test } from 'node:test';
import ts from 'typescript';

function localizationFixture() {
  const root = new URL('../src/i18n/', import.meta.url);
  const modules = new Map();
  const requests = [];

  // Execute the real source with Node's JSON and FormatJS modules. Only Expo's
  // device-locale API is stubbed.
  function load(file) {
    if (modules.has(file)) return modules.get(file).exports;
    const source = new URL(file, root);
    const module = { exports: {} };
    const requireFromSource = createRequire(source);
    const require = (specifier) => {
      requests.push(specifier);
      if (specifier === 'expo-localization') return { getLocales: () => [] };
      if (specifier.startsWith('./') && !specifier.endsWith('.json'))
        return load(specifier.slice(2) + '.ts');
      return requireFromSource(specifier);
    };
    const { outputText } = ts.transpileModule(readFileSync(source, 'utf8'), {
      compilerOptions: {
        module: ts.ModuleKind.CommonJS,
        target: ts.ScriptTarget.ES2022,
        jsx: ts.JsxEmit.ReactJSX,
        esModuleInterop: true,
      },
      fileName: file,
    });
    modules.set(file, module);
    new Function('require', 'module', 'exports', outputText)(require, module, module.exports);
    return module.exports;
  }

  return { load, requests };
}

const loadedCatalogs = (requests) => requests.filter((name) => name.startsWith('./catalogs/'));
const loadedPluralData = (requests) => requests.filter((name) => name.includes('/locale-data/'));

test('enumerating locales loads English only and selecting a language works synchronously offline', () => {
  const { load, requests } = localizationFixture();
  const { createTranslator, supportedLocales } = load('i18n.tsx');
  assert.ok(supportedLocales.includes('nl'));
  assert.deepEqual(loadedCatalogs(requests), ['./catalogs/en.json']);

  const english = createTranslator('en');
  const dutch = createTranslator('nl');
  assert.notEqual(dutch('generalLoading'), english('generalLoading'));
  assert.deepEqual(loadedCatalogs(requests), ['./catalogs/en.json', './catalogs/nl.json']);
  assert.deepEqual(loadedPluralData(requests), []);
  assert.equal(requests.some((name) => name.endsWith('/polyfill-force.js')), false);
});

test('missing Intl capabilities load fallback rules for the requested locales', () => {
  const keys = ['getCanonicalLocales', 'Locale', 'PluralRules'];
  const descriptors = new Map(keys.map((key) => [key, Object.getOwnPropertyDescriptor(Intl, key)]));
  const PluralRules = Intl.PluralRules;
  class LimitedPluralRules extends PluralRules {
    static supportedLocalesOf(locale) {
      return locale === 'pl' ? [] : PluralRules.supportedLocalesOf(locale);
    }
  }
  delete Intl.getCanonicalLocales;
  delete Intl.Locale;
  Intl.PluralRules = LimitedPluralRules;

  try {
    const { load, requests } = localizationFixture();
    const { ensureIntl } = load('intl-polyfills.ts');
    assert.equal(typeof Intl.getCanonicalLocales, 'function');
    assert.equal(typeof Intl.Locale, 'function');
    ensureIntl('ru');
    assert.deepEqual(loadedPluralData(requests), []);

    ensureIntl('pl');
    assert.equal(new Intl.PluralRules('pl').select(2), 'few');
    assert.deepEqual(loadedPluralData(requests).map((name) => name.split('/').at(-1)), ['en.js', 'pl.js']);

    ensureIntl('ru');
    ensureIntl('ru');
    assert.equal(new Intl.PluralRules('ru').select(5), 'many');
    assert.deepEqual(loadedPluralData(requests).map((name) => name.split('/').at(-1)), ['en.js', 'pl.js', 'ru.js']);
  } finally {
    for (const [key, descriptor] of descriptors) Object.defineProperty(Intl, key, descriptor);
  }
});
