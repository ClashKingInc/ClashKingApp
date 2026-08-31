import type { SupportedLocale } from '../../i18n';
import type { StringStore } from '../../services/storage/auth-storage';
import { createAppStateStore } from './app-state';

class MemoryStore implements StringStore {
  readonly values = new Map<string, string>();
  async getItem(key: string) {
    return this.values.get(key) ?? null;
  }
  async setItem(key: string, value: string) {
    this.values.set(key, value);
  }
  async removeItem(key: string) {
    this.values.delete(key);
  }
}

describe('app state parity', () => {
  it('loads persisted locale/theme, translations, and remote flags once', async () => {
    const preferences = new MemoryStore();
    await preferences.setItem('languageCode', 'fr');
    await preferences.setItem('themeMode', 'dark');
    const loadedLocales: unknown[] = [];
    let refreshes = 0;
    const store = createAppStateStore({
      preferences,
      gameData: {
        loadTranslationsForLocale: async (locale) => {
          loadedLocales.push(locale);
        },
      },
      featureFlags: {
        refresh: async () => {
          refreshes += 1;
        },
        isEnabled: (key, fallback) => (key === 'posts' ? false : (fallback ?? true)),
      },
      systemLocale: () => 'en',
    });

    await Promise.all([store.getState().initialize(), store.getState().initialize()]);

    expect(store.getState()).toMatchObject({
      locale: 'fr',
      themePreference: 'dark',
      initialized: true,
    });
    expect(store.getState().features.posts).toBe(false);
    expect(loadedLocales).toEqual([{ languageCode: 'fr' }]);
    expect(refreshes).toBe(1);
  });

  it('falls back to the supported system locale and preserves Flutter theme toggling', async () => {
    const preferences = new MemoryStore();
    const store = createAppStateStore({
      preferences,
      gameData: { loadTranslationsForLocale: async () => undefined },
      featureFlags: {
        refresh: async () => undefined,
        isEnabled: (_key, fallback) => fallback ?? true,
      },
      systemLocale: () => 'en_GB',
    });

    await store.getState().initialize();
    expect(store.getState().locale).toBe('en_GB');
    expect(store.getState().themePreference).toBe('system');

    await store.getState().toggleTheme();
    expect(store.getState().themePreference).toBe('dark');
    await store.getState().toggleTheme();
    expect(store.getState().themePreference).toBe('light');
  });

  it('restores persisted language codes with Flutter first-match locale behavior', async () => {
    const preferences = new MemoryStore();
    await preferences.setItem('languageCode', 'en');
    const store = createAppStateStore({
      preferences,
      gameData: { loadTranslationsForLocale: async () => undefined },
      featureFlags: {
        refresh: async () => undefined,
        isEnabled: (_key, fallback) => fallback ?? true,
      },
      systemLocale: () => 'en_US',
    });

    await store.getState().initialize();
    expect(store.getState().locale).toBe('en_GB');
  });

  it('persists locale subtags before publishing the change', async () => {
    const preferences = new MemoryStore();
    const translations: SupportedLocale[] = [];
    const store = createAppStateStore({
      preferences,
      gameData: {
        loadTranslationsForLocale: async (locale) => {
          translations.push(`${locale.languageCode}_${locale.countryCode}` as SupportedLocale);
        },
      },
      featureFlags: {
        refresh: async () => undefined,
        isEnabled: (_key, fallback) => fallback ?? true,
      },
      systemLocale: () => 'en',
    });

    await store.getState().changeLanguage('en_US');

    expect(preferences.values.get('languageCode')).toBe('en');
    expect(preferences.values.get('countryCode')).toBe('US');
    expect(store.getState().locale).toBe('en_US');
    expect(translations).toEqual(['en_US']);
  });
});
