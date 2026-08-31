import { createStore, type StoreApi } from 'zustand/vanilla';

import type { SupportedLocale } from '../../i18n';
import { resolveFlutterStartupLocale } from '../../i18n';
import type { StringStore } from '../../services/storage/auth-storage';
import type { GameDataService } from '../game-data';
import {
  APP_FEATURE_FLAGS,
  defaultFeatureFlagValue,
  type KnownFeatureFlag,
} from '../feature-flags/feature-flags';
import type { RemoteFeatureFlagService } from '../feature-flags/remote-feature-flag-service';

export type AppThemePreference = 'system' | 'light' | 'dark';
export type AppFeatureState = Readonly<Record<KnownFeatureFlag, boolean>>;

export interface AppStateSnapshot {
  readonly locale: SupportedLocale;
  readonly themePreference: AppThemePreference;
  readonly features: AppFeatureState;
  readonly initialized: boolean;
  readonly initialize: () => Promise<void>;
  readonly changeLanguage: (locale: SupportedLocale) => Promise<void>;
  readonly setThemePreference: (mode: AppThemePreference) => Promise<void>;
  readonly toggleTheme: () => Promise<void>;
  readonly isFeatureEnabled: (key: string, fallback?: boolean) => boolean;
}

export interface AppStateDependencies {
  readonly preferences: StringStore;
  readonly gameData: Pick<GameDataService, 'loadTranslationsForLocale'>;
  readonly featureFlags: Pick<RemoteFeatureFlagService, 'refresh' | 'isEnabled'>;
  readonly systemLocale: () => SupportedLocale;
}

export function createAppStateStore(
  dependencies: AppStateDependencies,
): StoreApi<AppStateSnapshot> {
  let initializeInFlight: Promise<void> | null = null;

  const store = createStore<AppStateSnapshot>((set, get) => ({
    locale: 'en',
    themePreference: 'system',
    features: defaultFeatureState(),
    initialized: false,

    initialize: async () => {
      if (get().initialized) return;
      if (initializeInFlight !== null) return initializeInFlight;
      const initialize = (async () => {
        const [storedLocale, storedTheme] = await Promise.all([
          dependencies.preferences.getItem('languageCode'),
          dependencies.preferences.getItem('themeMode'),
        ]);
        const locale =
          storedLocale === null
            ? dependencies.systemLocale()
            : resolveFlutterStartupLocale(storedLocale);
        const themePreference = parseThemePreference(storedTheme);

        await Promise.all([
          dependencies.gameData.loadTranslationsForLocale(appLocale(locale)),
          dependencies.featureFlags.refresh().catch(() => undefined),
        ]);
        set({
          locale,
          themePreference,
          features: currentFeatureState(dependencies.featureFlags),
          initialized: true,
        });
      })();
      initializeInFlight = initialize;
      try {
        await initialize;
      } finally {
        if (initializeInFlight === initialize) initializeInFlight = null;
      }
    },

    changeLanguage: async (locale) => {
      const parsed = appLocale(locale);
      await Promise.all([
        dependencies.preferences.setItem('languageCode', parsed.languageCode),
        parsed.countryCode === undefined
          ? Promise.resolve()
          : dependencies.preferences.setItem('countryCode', parsed.countryCode),
        parsed.scriptCode === undefined
          ? Promise.resolve()
          : dependencies.preferences.setItem('scriptCode', parsed.scriptCode),
        dependencies.gameData.loadTranslationsForLocale(parsed),
      ]);
      set({ locale });
    },

    setThemePreference: async (themePreference) => {
      await dependencies.preferences.setItem('themeMode', themePreference);
      set({ themePreference });
    },

    toggleTheme: async () => {
      const next = get().themePreference === 'dark' ? 'light' : 'dark';
      await get().setThemePreference(next);
    },

    isFeatureEnabled: (key, fallback = defaultFeatureFlagValue(key)) =>
      get().features[key as KnownFeatureFlag] ?? fallback,
  }));

  return store;
}

function defaultFeatureState(): AppFeatureState {
  return Object.fromEntries(
    Object.values(APP_FEATURE_FLAGS).map((key) => [key, defaultFeatureFlagValue(key)]),
  ) as AppFeatureState;
}

function currentFeatureState(
  featureFlags: Pick<RemoteFeatureFlagService, 'isEnabled'>,
): AppFeatureState {
  return Object.fromEntries(
    Object.values(APP_FEATURE_FLAGS).map((key) => [
      key,
      featureFlags.isEnabled(key, defaultFeatureFlagValue(key)),
    ]),
  ) as AppFeatureState;
}

function parseThemePreference(value: string | null): AppThemePreference {
  return value === 'dark' || value === 'light' ? value : 'system';
}

function appLocale(locale: SupportedLocale): {
  languageCode: string;
  countryCode?: string;
  scriptCode?: string;
} {
  const [languageCode, variant] = locale.split('_');
  if (variant === undefined) return { languageCode: languageCode! };
  return variant.length === 4
    ? { languageCode: languageCode!, scriptCode: variant }
    : { languageCode: languageCode!, countryCode: variant };
}
