import { SETTINGS_LOCALES, selectedSettingsLocale } from './settings-locales';

describe('settings locale manifest', () => {
  it('matches the exact Flutter user-facing list and order', () => {
    expect(SETTINGS_LOCALES.map(({ locale }) => locale)).toEqual([
      'af',
      'ar',
      'ca',
      'cs',
      'da',
      'de',
      'el',
      'en_GB',
      'en_US',
      'es',
      'fi',
      'fr',
      'he',
      'hu',
      'it',
      'ja',
      'ko',
      'nl',
      'no',
      'pl',
      'pt',
      'ro',
      'ru',
      'sr',
      'sv',
      'tr',
      'uk',
      'vi',
      'zh',
    ]);
  });

  it('uses Flutter first-match selection for a locale without a variant', () => {
    expect(selectedSettingsLocale('en')).toBe('en_GB');
    expect(selectedSettingsLocale('en_US')).toBe('en_US');
    expect(selectedSettingsLocale('es_ES')).toBe('es');
  });
});
