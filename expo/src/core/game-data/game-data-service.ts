import {
  applyGameTranslations,
  clashyLocaleCodeForAppLocale,
  clearGameTranslations,
  type AppLocale,
} from './game-data-localization';
import { applyGameDataBundle } from './game-data-normalization';
import { gameDataState, isRecord, type JsonRecord } from './game-data-state';

export const STATIC_DATA_URL = 'https://assets.clashk.ing/static_data.json';
export const TRANSLATIONS_URL = 'https://assets.clashk.ing/translations.json';
export const GAME_DATA_USER_AGENT = 'ClashKing-App/1.0';
export const GAME_DATA_CACHE_FRESHNESS_MS = 6 * 60 * 60 * 1_000;

export const GAME_DATA_PREFERENCE_KEYS = {
  languageCode: 'languageCode',
  countryCode: 'countryCode',
  scriptCode: 'scriptCode',
  staticLastModified: 'game_data_static_last_modified',
  staticCachedAt: 'game_data_static_cached_at',
  translationsLastModified: 'game_data_translations_last_modified',
  translationsCachedAt: 'game_data_translations_cached_at',
} as const;

export type GameDataPlatform = 'native' | 'web';

export interface GameDataFileStore {
  read(fileName: string): Promise<string | null>;
  write(fileName: string, contents: string): Promise<void>;
}

export interface GameDataPreferences {
  getString(key: string): Promise<string | null>;
  setString(key: string, value: string): Promise<void>;
}

export interface GameDataServiceOptions {
  readonly platform: GameDataPlatform;
  readonly files: GameDataFileStore;
  readonly preferences: GameDataPreferences;
  readonly fetchImplementation?: typeof fetch;
  readonly now?: () => Date;
  readonly sleep?: (milliseconds: number) => Promise<void>;
  readonly systemLocales?: () => readonly AppLocale[];
}

interface CachedJsonAsset {
  readonly label: string;
  readonly fileName: string;
  readonly lastModifiedKey: string;
  readonly cachedAtKey: string;
}

const STATIC_DATA_CACHE: CachedJsonAsset = {
  label: 'static_data',
  fileName: 'static_data.json',
  lastModifiedKey: GAME_DATA_PREFERENCE_KEYS.staticLastModified,
  cachedAtKey: GAME_DATA_PREFERENCE_KEYS.staticCachedAt,
};

const TRANSLATIONS_CACHE: CachedJsonAsset = {
  label: 'translations_data',
  fileName: 'translations.json',
  lastModifiedKey: GAME_DATA_PREFERENCE_KEYS.translationsLastModified,
  cachedAtKey: GAME_DATA_PREFERENCE_KEYS.translationsCachedAt,
};

export class GameDataService {
  private readonly platform: GameDataPlatform;
  private readonly files: GameDataFileStore;
  private readonly preferences: GameDataPreferences;
  private readonly fetchImplementation: typeof fetch;
  private readonly now: () => Date;
  private readonly sleep: (milliseconds: number) => Promise<void>;
  private readonly systemLocales: () => readonly AppLocale[];
  private bundleLoad: Promise<void> | null = null;
  private staticRefresh: Promise<void> | null = null;
  private readonly translationLoads = new Map<string, Promise<void>>();

  constructor(options: GameDataServiceOptions) {
    this.platform = options.platform;
    this.files = options.files;
    this.preferences = options.preferences;
    this.fetchImplementation = options.fetchImplementation ?? fetch;
    this.now = options.now ?? (() => new Date());
    this.sleep =
      options.sleep ??
      ((milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds)));
    this.systemLocales = options.systemLocales ?? (() => []);
  }

  async loadGameData(locale?: AppLocale): Promise<void> {
    const preferredLocale = locale ?? (await this.resolvePreferredLocale());
    await Promise.all([this.loadBundle(), this.loadTranslationsForLocale(preferredLocale)]);
  }

  async loadFreshGameData(locale?: AppLocale): Promise<void> {
    await this.loadGameData(locale);
    if (this.platform === 'web') return;
    await this.refreshStaticDataIfChanged();
  }

  async refreshStaticDataIfChanged(): Promise<void> {
    if (this.staticRefresh !== null) return this.staticRefresh;
    const refresh = this.refreshStaticDataIfChangedOnce();
    this.staticRefresh = refresh;
    try {
      await refresh;
    } finally {
      if (this.staticRefresh === refresh) this.staticRefresh = null;
    }
  }

  async loadTranslationsForLocale(locale: AppLocale): Promise<void> {
    const clashyLocale = clashyLocaleCodeForAppLocale(locale);
    if (
      gameDataState.translationLocale === clashyLocale &&
      Object.keys(gameDataState.translationsData).length > 0
    ) {
      return;
    }
    if (clashyLocale === 'EN') {
      clearGameTranslations(clashyLocale);
      return;
    }

    const existing = this.translationLoads.get(clashyLocale);
    if (existing !== undefined) return existing;
    const load = this.loadTranslationsOnce(clashyLocale);
    this.translationLoads.set(clashyLocale, load);
    try {
      await load;
    } finally {
      if (this.translationLoads.get(clashyLocale) === load) {
        this.translationLoads.delete(clashyLocale);
      }
    }
  }

  async resolvePreferredLocale(): Promise<AppLocale> {
    const languageCode = await this.preferences.getString(GAME_DATA_PREFERENCE_KEYS.languageCode);
    const countryCode = await this.preferences.getString(GAME_DATA_PREFERENCE_KEYS.countryCode);
    const scriptCode = await this.preferences.getString(GAME_DATA_PREFERENCE_KEYS.scriptCode);
    if (languageCode !== null && languageCode.length > 0) {
      return {
        languageCode,
        countryCode: countryCode !== null && countryCode.length > 0 ? countryCode : null,
        scriptCode: scriptCode !== null && scriptCode.length > 0 ? scriptCode : null,
      };
    }
    return this.systemLocales()[0] ?? { languageCode: 'en' };
  }

  private async loadBundle(): Promise<void> {
    if (this.bundleLoad !== null) return this.bundleLoad;
    const load = this.loadBundleOnce();
    this.bundleLoad = load;
    try {
      await load;
    } finally {
      if (this.bundleLoad === load) this.bundleLoad = null;
    }
  }

  private async loadBundleOnce(): Promise<void> {
    try {
      applyGameDataBundle(await this.loadCachedJsonAsset(STATIC_DATA_CACHE, STATIC_DATA_URL));
    } catch {
      // Flutter deliberately retains the last valid in-memory static bundle.
    }
  }

  private async loadTranslationsOnce(clashyLocale: string): Promise<void> {
    try {
      applyGameTranslations(
        await this.loadCachedJsonAsset(TRANSLATIONS_CACHE, TRANSLATIONS_URL),
        clashyLocale,
      );
    } catch {
      clearGameTranslations(clashyLocale);
    }
  }

  private async loadCachedJsonAsset(asset: CachedJsonAsset, url: string): Promise<JsonRecord> {
    if (this.platform === 'web') {
      return this.downloadJsonAssetForWeb(asset, url);
    }

    const cachedBody = await this.files.read(asset.fileName);
    const cachedLastModified = await this.preferences.getString(asset.lastModifiedKey);
    if (cachedBody !== null) {
      try {
        const cached = parseJsonObject(cachedBody, `Cached ${asset.label}`);
        const cachedAt = await this.preferences.getString(asset.cachedAtKey);
        if (this.cacheNeedsRefresh(cachedAt)) {
          const refresh =
            asset.fileName === STATIC_DATA_CACHE.fileName
              ? this.refreshStaticDataIfChanged()
              : this.refreshCachedJsonAsset(asset, url, cachedLastModified);
          void refresh.catch(() => undefined);
        }
        return cached;
      } catch {
        // Invalid cache is replaced with the same one-attempt behavior as Flutter.
      }
    }

    return this.downloadJsonAsset(asset, url, null, 1);
  }

  private async downloadJsonAssetForWeb(asset: CachedJsonAsset, url: string): Promise<JsonRecord> {
    const response = await this.fetchWithTimeout(url, 'GET', 5_000);
    if (response.status !== 200) {
      throw new Error(`HTTP ${response.status} for ${asset.label}`);
    }
    return parseJsonObject(await response.text(), asset.label);
  }

  private cacheNeedsRefresh(cachedAt: string | null): boolean {
    if (cachedAt === null) return true;
    const timestamp = Date.parse(cachedAt);
    if (Number.isNaN(timestamp)) return true;
    return this.now().getTime() - timestamp >= GAME_DATA_CACHE_FRESHNESS_MS;
  }

  private async refreshStaticDataIfChangedOnce(): Promise<void> {
    const cachedBody = await this.files.read(STATIC_DATA_CACHE.fileName);
    if (cachedBody === null) {
      await this.loadBundle();
      return;
    }
    const cachedLastModified = await this.preferences.getString(STATIC_DATA_CACHE.lastModifiedKey);
    await this.refreshCachedJsonAsset(STATIC_DATA_CACHE, STATIC_DATA_URL, cachedLastModified);

    // This re-read is intentional: Flutter repairs in-memory data even when HEAD is unchanged.
    const body = await this.files.read(STATIC_DATA_CACHE.fileName);
    if (body === null) throw new Error('Cached static_data is missing');
    applyGameDataBundle(parseJsonObject(body, 'Cached static_data'));
  }

  private async refreshCachedJsonAsset(
    asset: CachedJsonAsset,
    url: string,
    cachedLastModified: string | null,
  ): Promise<void> {
    const remoteLastModified = await this.fetchLastModified(url);
    if (remoteLastModified === null) return;
    if (cachedLastModified !== null && remoteLastModified === cachedLastModified) {
      await this.preferences.setString(asset.cachedAtKey, this.nowIso());
      return;
    }

    try {
      const updated = await this.downloadJsonAsset(asset, url, remoteLastModified, 2);
      if (asset.fileName === STATIC_DATA_CACHE.fileName) {
        applyGameDataBundle(updated);
      } else if (gameDataState.translationLocale !== 'EN') {
        applyGameTranslations(updated, gameDataState.translationLocale);
      }
    } catch {
      // Flutter keeps the cached asset when a refresh fails.
    }
  }

  private async fetchLastModified(url: string): Promise<string | null> {
    try {
      const response = await this.fetchWithTimeout(url, 'HEAD', 5_000);
      if (response.status >= 200 && response.status < 300) {
        return response.headers.get('last-modified');
      }
    } catch {
      // A missing validator or HEAD failure leaves cache freshness unchanged.
    }
    return null;
  }

  private async downloadJsonAsset(
    asset: CachedJsonAsset,
    url: string,
    remoteLastModified: string | null,
    maxRetries: number,
  ): Promise<JsonRecord> {
    for (let attempt = 1; attempt <= maxRetries; attempt += 1) {
      try {
        const response = await this.fetchWithTimeout(url, 'GET', 10_000);
        if (response.status === 200) {
          const body = await response.text();
          const decoded = parseJsonObject(body, asset.label);
          await this.files.write(asset.fileName, body);
          const lastModified = response.headers.get('last-modified') ?? remoteLastModified;
          if (lastModified !== null && lastModified.length > 0) {
            await this.preferences.setString(asset.lastModifiedKey, lastModified);
          }
          await this.preferences.setString(asset.cachedAtKey, this.nowIso());
          return decoded;
        }
      } catch {
        // Retry below, matching the Dart service's status/exception handling.
      }
      if (attempt === maxRetries) {
        throw new Error(`Final failure for ${asset.label}`);
      }
      await this.sleep(1_000 * 2 ** (attempt - 1));
    }
    throw new Error(`Unable to load ${asset.label}`);
  }

  private async fetchWithTimeout(
    url: string,
    method: 'GET' | 'HEAD',
    timeoutMilliseconds: number,
  ): Promise<Response> {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), timeoutMilliseconds);
    try {
      return await this.fetchImplementation(url, {
        method,
        headers: { 'User-Agent': GAME_DATA_USER_AGENT },
        signal: controller.signal,
      });
    } finally {
      clearTimeout(timeout);
    }
  }

  private nowIso(): string {
    return this.now().toISOString();
  }
}

export function isSuperTroop(name: string): boolean {
  return itemHasType(gameDataState.troopsData.troops, name, 'super-troop');
}

export function isSiegeMachine(name: string): boolean {
  return itemHasType(gameDataState.troopsData.troops, name, 'siege-machine');
}

export function isPet(name: string): boolean {
  const pets = gameDataState.petsData.pets;
  return isRecord(pets) && Object.hasOwn(pets, name);
}

export function getMaxTownHallLevel(): number {
  const value = gameDataState.gameData.max_TownHall;
  return typeof value === 'number' ? Math.trunc(value) : 0;
}

function itemHasType(section: unknown, name: string, type: string): boolean {
  if (!isRecord(section)) return false;
  const item = section[name];
  return isRecord(item) && item.type === type;
}

function parseJsonObject(body: string, label: string): JsonRecord {
  const decoded: unknown = JSON.parse(body);
  if (!isRecord(decoded)) throw new Error(`${label} is not a JSON object`);
  return decoded;
}
