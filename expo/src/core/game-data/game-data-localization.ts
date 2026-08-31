import { gameDataState, isRecord, type JsonRecord } from './game-data-state';

export interface AppLocale {
  readonly languageCode: string;
  readonly countryCode?: string | null;
  readonly scriptCode?: string | null;
}

const CLASHY_LOCALE_CODES: Readonly<Record<string, string>> = {
  ar: 'AR',
  de: 'DE',
  en: 'EN',
  es: 'ES',
  fi: 'FI',
  fr: 'FR',
  it: 'IT',
  ja: 'JP',
  ko: 'KR',
  nl: 'NL',
  no: 'NO',
  pl: 'PL',
  pt: 'PT',
  ru: 'RU',
  tr: 'TR',
  vi: 'VI',
  zh: 'CN',
};

export function exactClashyLocaleCode(locale: AppLocale): string | null {
  return CLASHY_LOCALE_CODES[locale.languageCode.toLowerCase()] ?? null;
}

export function clashyLocaleCodeForAppLocale(locale: AppLocale): string {
  return exactClashyLocaleCode(locale) ?? 'EN';
}

/** Unsupported app locales load English dynamic data but must retain their ARB UI fallback. */
export function hasTranslationsForLocale(locale: AppLocale): boolean {
  return exactClashyLocaleCode(locale) !== null;
}

export function applyGameTranslations(response: JsonRecord, clashyLocale: string): void {
  clearTranslations();
  const translations = response.translations ?? response;
  if (isRecord(translations)) {
    for (const [key, value] of Object.entries(translations)) {
      if (typeof value === 'string') {
        gameDataState.translationsData[key] = value;
        continue;
      }
      if (!isRecord(value)) continue;
      const translated = value[clashyLocale] ?? value[clashyLocale.toLowerCase()];
      if (typeof translated === 'string') {
        gameDataState.translationsData[key] = translated;
      }
    }
  }
  gameDataState.translationLocale = clashyLocale;
}

export function clearGameTranslations(locale = 'EN'): void {
  clearTranslations();
  gameDataState.translationLocale = locale;
}

export function translationForTid(tid: string | null | undefined): string | null {
  if (tid === null || tid === undefined || tid.length === 0) return null;
  return gameDataState.translationsData[tid] ?? null;
}

export function localizedNameForItem(item: JsonRecord | null | undefined): string {
  const tid = item?.TID;
  if (isRecord(tid) && typeof tid.name === 'string') {
    return translationForTid(tid.name) ?? stringValue(item?.name);
  }
  return stringValue(item?.name);
}

export function localizedInfoForItem(item: JsonRecord | null | undefined): string {
  const tid = item?.TID;
  if (isRecord(tid) && typeof tid.info === 'string') {
    return translationForTid(tid.info) ?? stringValue(item?.info);
  }
  return stringValue(item?.info);
}

export function localizedNameForItemOrFallback(
  item: JsonRecord | null | undefined,
  locale: AppLocale,
  fallback: string,
): string {
  const tid = item?.TID;
  if (!isRecord(tid) || typeof tid.name !== 'string') return fallback;
  return localizedNameForTidOrFallback(tid.name, locale, fallback);
}

export function localizedNameForTidOrFallback(
  tid: string,
  locale: AppLocale,
  fallback: string,
): string {
  const clashyLocale = exactClashyLocaleCode(locale);
  if (
    clashyLocale === null ||
    gameDataState.translationLocale !== clashyLocale ||
    Object.keys(gameDataState.translationsData).length === 0
  ) {
    return fallback;
  }
  const translated = translationForTid(tid)?.trim() ?? '';
  return translated.length === 0 ? fallback : translated;
}

function clearTranslations(): void {
  for (const key of Object.keys(gameDataState.translationsData)) {
    delete gameDataState.translationsData[key];
  }
}

function stringValue(value: unknown): string {
  return value === null || value === undefined ? '' : String(value);
}
