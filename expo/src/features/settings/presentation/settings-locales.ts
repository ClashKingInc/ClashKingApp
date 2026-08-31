import type { SupportedLocale } from '../../../i18n';

export interface SettingsLocaleOption {
  readonly locale: SupportedLocale;
  readonly label: string;
  readonly flagUrl: string;
}

/**
 * This deliberately mirrors lib/l10n/locale.dart instead of exposing every
 * generated catalog. Flutter keeps base English, regional Spanish, Hindi, and
 * Urdu catalogs out of the user-facing picker.
 */
export const SETTINGS_LOCALES: readonly SettingsLocaleOption[] = [
  { locale: 'af', label: 'Afrikaans', flagUrl: 'https://flagcdn.com/w320/za.png' },
  { locale: 'ar', label: 'العربية', flagUrl: 'https://flagcdn.com/w320/sa.png' },
  { locale: 'ca', label: 'Català', flagUrl: 'https://flagcdn.com/w320/es.png' },
  { locale: 'cs', label: 'Čeština', flagUrl: 'https://flagcdn.com/w320/cz.png' },
  { locale: 'da', label: 'Dansk', flagUrl: 'https://flagcdn.com/w320/dk.png' },
  { locale: 'de', label: 'Deutsch', flagUrl: 'https://flagcdn.com/w320/de.png' },
  { locale: 'el', label: 'Ελληνικά', flagUrl: 'https://flagcdn.com/w320/gr.png' },
  { locale: 'en_GB', label: 'English (UK)', flagUrl: 'https://flagcdn.com/w320/gb.png' },
  { locale: 'en_US', label: 'English (US)', flagUrl: 'https://flagcdn.com/w320/us.png' },
  { locale: 'es', label: 'Español', flagUrl: 'https://flagcdn.com/w320/es.png' },
  { locale: 'fi', label: 'Suomi', flagUrl: 'https://flagcdn.com/w320/fi.png' },
  { locale: 'fr', label: 'Français', flagUrl: 'https://flagcdn.com/w320/fr.png' },
  { locale: 'he', label: 'עברית', flagUrl: 'https://flagcdn.com/w320/il.png' },
  { locale: 'hu', label: 'Magyar', flagUrl: 'https://flagcdn.com/w320/hu.png' },
  { locale: 'it', label: 'Italiano', flagUrl: 'https://flagcdn.com/w320/it.png' },
  { locale: 'ja', label: '日本語', flagUrl: 'https://flagcdn.com/w320/jp.png' },
  { locale: 'ko', label: '한국어', flagUrl: 'https://flagcdn.com/w320/kr.png' },
  { locale: 'nl', label: 'Nederlands', flagUrl: 'https://flagcdn.com/w320/nl.png' },
  { locale: 'no', label: 'Norsk', flagUrl: 'https://flagcdn.com/w320/no.png' },
  { locale: 'pl', label: 'Polski', flagUrl: 'https://flagcdn.com/w320/pl.png' },
  { locale: 'pt', label: 'Português', flagUrl: 'https://flagcdn.com/w320/pt.png' },
  { locale: 'ro', label: 'Română', flagUrl: 'https://flagcdn.com/w320/ro.png' },
  { locale: 'ru', label: 'Русский', flagUrl: 'https://flagcdn.com/w320/ru.png' },
  { locale: 'sr', label: 'Српски', flagUrl: 'https://flagcdn.com/w320/rs.png' },
  { locale: 'sv', label: 'Svenska', flagUrl: 'https://flagcdn.com/w320/se.png' },
  { locale: 'tr', label: 'Türkçe', flagUrl: 'https://flagcdn.com/w320/tr.png' },
  { locale: 'uk', label: 'Українська', flagUrl: 'https://flagcdn.com/w320/ua.png' },
  { locale: 'vi', label: 'Tiếng Việt', flagUrl: 'https://flagcdn.com/w320/vn.png' },
  { locale: 'zh', label: '中文', flagUrl: 'https://flagcdn.com/w320/cn.png' },
] as const;

export function selectedSettingsLocale(currentLocale: SupportedLocale): SupportedLocale {
  const exact = SETTINGS_LOCALES.find((option) => option.locale === currentLocale);
  if (exact) return exact.locale;
  const language = currentLocale.split('_', 1)[0];
  return (
    SETTINGS_LOCALES.find((option) => option.locale.split('_', 1)[0] === language)?.locale ??
    'en_GB'
  );
}
