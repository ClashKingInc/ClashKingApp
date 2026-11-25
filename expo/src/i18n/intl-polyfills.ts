/* eslint-disable @typescript-eslint/no-require-imports -- Load Intl fallbacks synchronously only when needed. */
import { shouldPolyfill as needsCanonicalLocales } from '@formatjs/intl-getcanonicallocales/should-polyfill.js';
import { loadPluralRulesLocaleData, type SupportedLocale } from './catalogs.generated';

const preparedLocales = new Set<SupportedLocale>();
let pluralRulesPolyfilled = false;

if (needsCanonicalLocales()) require('@formatjs/intl-getcanonicallocales/polyfill-force.js');
if (!hasUsableLocale()) require('@formatjs/intl-locale/polyfill-force.js');

function hasUsableLocale(): boolean {
  try {
    // MessageFormat uses maximization for ICU skeletons and locale matching.
    return typeof Intl.Locale === 'function' &&
      new Intl.Locale('und-x-private').toString() === 'und-x-private' &&
      typeof new Intl.Locale('en').maximize().region === 'string';
  } catch {
    return false;
  }
}

export function ensureIntl(locale: SupportedLocale): void {
  if (preparedLocales.has(locale)) return;

  // Match FormatJS's native checks, including runtimes that mishandle fractions.
  const tag = locale.replaceAll('_', '-');
  if (!pluralRulesPolyfilled && (
    typeof Intl.PluralRules !== 'function' ||
    Intl.PluralRules.supportedLocalesOf(tag).length === 0 ||
    new Intl.PluralRules('en', { minimumFractionDigits: 2 }).select(1) === 'one'
  )) {
    require('@formatjs/intl-pluralrules/polyfill-force.js');
    pluralRulesPolyfilled = true;
    // Revisit locales that previously used the native implementation.
    preparedLocales.clear();
    loadPluralRulesLocaleData('en');
  }

  if (pluralRulesPolyfilled && Intl.PluralRules.supportedLocalesOf(tag).length === 0)
    loadPluralRulesLocaleData(locale);
  preparedLocales.add(locale);
}

ensureIntl('en');
