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
  it('reports a failed translation load without waiting for remote feature flags', async () => {
    const failure = new Error('Translation unavailable');
    let finishRefresh!: () => void;
    const refresh = new Promise<void>((resolve) => {
      finishRefresh = resolve;
    });
    const store = createAppStateStore({
      preferences: new MemoryStore(),
      gameData: {
        loadTranslationsForLocale: async () => {
          throw failure;
        },
      },
      featureFlags: {
        refresh: () => refresh,
        isEnabled: (_key, fallback) => fallback ?? true,
      },
      systemLocale: () => 'en',
    });
    let settled = false;
    const initialization = store
      .getState()
      .initialize()
      .catch((error: unknown) => {
        settled = true;
        return error;
      });
    for (let turn = 0; turn < 10; turn += 1) await Promise.resolve();
    const settledBeforeRefresh = settled;
    finishRefresh();
    expect(await initialization).toBe(failure);
    expect(settledBeforeRefresh).toBe(true);
    expect(store.getState().initialized).toBe(false);
  });

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

  it('defaults to dark before and after loading missing preferences, while retaining the system locale', async () => {
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

    expect(store.getState().themePreference).toBe('dark');
    await store.getState().initialize();
    expect(store.getState().locale).toBe('en_GB');
    expect(store.getState().themePreference).toBe('dark');

    await store.getState().toggleTheme();
    expect(store.getState().themePreference).toBe('light');
    await store.getState().toggleTheme();
    expect(store.getState().themePreference).toBe('dark');
  });

  it.each(['dark', 'light', 'system'] as const)(
    'preserves an explicitly saved %s theme',
    async (theme) => {
      const preferences = new MemoryStore();
      await preferences.setItem('themeMode', theme);
      const store = createAppStateStore({
        preferences,
        gameData: { loadTranslationsForLocale: async () => undefined },
        featureFlags: {
          refresh: async () => undefined,
          isEnabled: (_key, fallback) => fallback ?? true,
        },
        systemLocale: () => 'en',
      });
      await store.getState().initialize();
      expect(store.getState().themePreference).toBe(theme);
    },
  );

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
