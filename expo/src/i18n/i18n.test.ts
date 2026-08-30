import {
  createTranslator,
  formatCompactNumber,
  isRtlLocale,
  resolveFlutterStartupLocale,
  resolveLocale,
  toIntlLocale,
} from './i18n';

describe('localization parity helpers', () => {
  it('resolves exact region variants and language fallbacks', () => {
    expect(resolveLocale('en-GB')).toBe('en_GB');
    expect(resolveLocale('fr-CA')).toBe('fr');
    expect(resolveLocale('xx-YY')).toBe('en');
  });

  it('preserves ICU placeholders', () => {
    expect(createTranslator('en')('achievementSummary', { earned: 2, total: 5 })).toBe(
      '2/5 completed',
    );
  });

  it('restores startup languages through Flutter picker order rather than hidden catalogs', () => {
    expect(resolveFlutterStartupLocale('en-US')).toBe('en_GB');
    expect(resolveFlutterStartupLocale('es-ES')).toBe('es');
    expect(resolveFlutterStartupLocale('ur-PK')).toBe('en');
    expect(resolveFlutterStartupLocale('hi-IN')).toBe('en');
  });

  it('marks every supported right-to-left language', () => {
    expect(isRtlLocale('ar')).toBe(true);
    expect(isRtlLocale('he')).toBe(true);
    expect(isRtlLocale('ur')).toBe(true);
    expect(isRtlLocale('en')).toBe(false);
  });

  it('normalizes ARB locale identifiers before passing them to Intl', () => {
    expect(toIntlLocale('en_GB')).toBe('en-GB');
    expect(toIntlLocale('es_ES')).toBe('es-ES');
    expect(toIntlLocale('fr')).toBe('fr');
    expect(() => new Intl.NumberFormat(toIntlLocale('en_GB'))).not.toThrow();
  });

  it('formats compact numbers with the selected app locale', () => {
    expect(formatCompactNumber(160_500_000, 'en_GB')).toBe(
      new Intl.NumberFormat('en-GB', { notation: 'compact' }).format(160_500_000),
    );
    expect(formatCompactNumber(160_500_000, 'fr')).toBe(
      new Intl.NumberFormat('fr', { notation: 'compact' }).format(160_500_000),
    );
  });
});
