import { getLocales } from 'expo-localization';
import { IntlMessageFormat } from 'intl-messageformat';
import React, { createContext, useContext, useMemo, type ReactNode } from 'react';

import { catalogs, type MessageKey, type SupportedLocale } from './catalogs.generated';

type MessageValues = Record<string, string | number | Date | boolean | null | undefined>;

export interface I18nValue {
  locale: SupportedLocale;
  isRtl: boolean;
  t: (key: MessageKey, values?: MessageValues) => string;
}

const formatterCache = new Map<string, IntlMessageFormat>();
const I18nContext = createContext<I18nValue | null>(null);
const rtlLanguages = new Set(['ar', 'he', 'ur']);
const flutterStartupLocales = {
  af: 'af',
  ar: 'ar',
  ca: 'ca',
  cs: 'cs',
  da: 'da',
  de: 'de',
  el: 'el',
  en: 'en_GB',
  es: 'es',
  fi: 'fi',
  fr: 'fr',
  he: 'he',
  hu: 'hu',
  it: 'it',
  ja: 'ja',
  ko: 'ko',
  nl: 'nl',
  no: 'no',
  pl: 'pl',
  pt: 'pt',
  ro: 'ro',
  ru: 'ru',
  sr: 'sr',
  sv: 'sv',
  tr: 'tr',
  uk: 'uk',
  vi: 'vi',
  zh: 'zh',
} as const satisfies Readonly<Record<string, SupportedLocale>>;

export const supportedLocales = Object.freeze(Object.keys(catalogs) as SupportedLocale[]);

export function resolveLocale(input?: string | null): SupportedLocale {
  const normalized = input?.replace('-', '_');
  if (normalized && isSupportedLocale(normalized)) return normalized;

  const language = normalized?.split('_')[0];
  if (language && isSupportedLocale(language)) return language;
  return 'en';
}

export function systemLocale(): SupportedLocale {
  const locale = getLocales()[0];
  return resolveFlutterStartupLocale(locale?.languageCode);
}

/** Mirrors MyAppState._loadLanguage, which discards stored/system subtags and
 * resolves the language against lib/l10n/locale.dart's ordered picker list. */
export function resolveFlutterStartupLocale(input?: string | null): SupportedLocale {
  const language = input?.replace('-', '_').split('_', 1)[0]?.toLowerCase();
  return flutterStartupLocales[language as keyof typeof flutterStartupLocales] ?? 'en';
}

export function isRtlLocale(locale: SupportedLocale): boolean {
  return rtlLanguages.has(locale.split('_', 1)[0]!);
}

/** Converts ARB locale identifiers such as `en_GB` to Intl's BCP-47 form. */
export function toIntlLocale(locale: string): string {
  return locale.replaceAll('_', '-');
}

export function formatCompactNumber(value: number, locale: string): string {
  return new Intl.NumberFormat(toIntlLocale(locale), { notation: 'compact' }).format(value);
}

export function createTranslator(locale: SupportedLocale): I18nValue['t'] {
  return (key, values = {}) => {
    const message = catalogs[locale][key] ?? catalogs.en[key];
    if (message === undefined) {
      throw new Error(`Missing localization message: ${locale}.${key}`);
    }
    const cacheKey = `${locale}:${key}`;
    let formatter = formatterCache.get(cacheKey);
    if (!formatter) {
      formatter = new IntlMessageFormat(message, toIntlLocale(locale));
      formatterCache.set(cacheKey, formatter);
    }
    const formatted = formatter.format(values);
    return Array.isArray(formatted) ? formatted.join('') : String(formatted);
  };
}

export function I18nProvider({
  children,
  locale = systemLocale(),
}: {
  children: ReactNode;
  locale?: SupportedLocale;
}) {
  const value = useMemo<I18nValue>(
    () => ({
      locale,
      isRtl: isRtlLocale(locale),
      t: createTranslator(locale),
    }),
    [locale],
  );
  return <I18nContext.Provider value={value}>{children}</I18nContext.Provider>;
}

export function useI18n(): I18nValue {
  const value = useContext(I18nContext);
  if (!value) throw new Error('useI18n must be used inside I18nProvider.');
  return value;
}

function isSupportedLocale(locale: string): locale is SupportedLocale {
  return Object.prototype.hasOwnProperty.call(catalogs, locale);
}
