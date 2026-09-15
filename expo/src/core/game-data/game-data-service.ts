import {
  applyGameTranslations,
  clashyLocaleCodeForAppLocale,
  clearGameTranslations,
  type AppLocale,
} from './game-data-localization';
import { applyGameDataBundle } from './game-data-normalization';
import { gameDataState, isRecord, type JsonRecord } from './game-data-state';
import {
  applyAssetManifest,
  ASSET_MANIFEST_URL,
  validateAssetManifest,
  manifestData,
} from '../assets/asset-manifest';
import { FileUpdateIndex, type FileIndexStorage } from '../assets/file-update-index';
import { CryptoDigestAlgorithm, digestStringAsync } from 'expo-crypto';

export const STATIC_DATA_URL = 'https://assets.clashk.ing/static_data';
export const TRANSLATIONS_URL = 'https://assets.clashk.ing/translations';
export const GAME_DATA_USER_AGENT = 'ClashKing-App/1.0';
export const GAME_DATA_CACHE_FRESHNESS_MS = 60 * 1_000;

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

export type GameDataPreferences = FileIndexStorage;

export interface GameDataServiceOptions {
  readonly fileIndex?: FileUpdateIndex;
  readonly platform: GameDataPlatform;
  readonly files: GameDataFileStore;
  readonly preferences: GameDataPreferences;
  readonly fetchImplementation?: typeof fetch;
  readonly now?: () => Date;
  readonly sleep?: (milliseconds: number) => Promise<void>;
  readonly systemLocales?: () => readonly AppLocale[];
}

interface JsonCache {
  readonly sha?: string;
  readonly body: string;
  readonly etag: string | null;
  readonly lastModified: string | null;
  readonly checkedAt: string;
}

interface CachedJsonAsset {
  readonly sha?: string;
  readonly label: string;
  readonly fileName: string;
  readonly lastModifiedKey: string;
  readonly cachedAtKey: string;
}

const MANIFEST_CACHE: CachedJsonAsset = {
  label: 'asset_manifest',
  fileName: 'asset_manifest.json',
  lastModifiedKey: 'asset_manifest.lastModified',
  cachedAtKey: 'asset_manifest.cachedAt',
};

function dataCache(fileName: string, sha?: string): CachedJsonAsset {
  return {
    label: fileName,
    fileName,
    sha,
    lastModifiedKey: fileName + '.lastModified',
    cachedAtKey: fileName + '.cachedAt',
  };
}

export class GameDataService {
  private readonly fileIndex: FileUpdateIndex;
  private readonly files: GameDataFileStore;
  private readonly preferences: GameDataPreferences;
  private readonly fetchImplementation: typeof fetch;
  private readonly now: () => Date;
  private readonly systemLocales: () => readonly AppLocale[];
  private bundleLoad: Promise<void> | null = null;
  private readonly refreshes = new Map<string, Promise<JsonRecord>>();
  private readonly attempts = new Map<string, number>();
  private readonly translationLoads = new Map<string, Promise<void>>();
  private desiredLocale = 'EN';

  constructor(options: GameDataServiceOptions) {
    this.fileIndex = options.fileIndex ?? new FileUpdateIndex(options.preferences);
    this.files = options.files;
    this.preferences = options.preferences;
    this.fetchImplementation = options.fetchImplementation ?? fetch;
    this.now = options.now ?? (() => new Date());
    this.systemLocales = options.systemLocales ?? (() => []);
  }

  async loadGameData(locale?: AppLocale): Promise<void> {
    await this.fileIndex.hydrate();
    const preferredLocale = locale ?? (await this.resolvePreferredLocale());
    await Promise.all([this.loadBundle(), this.loadTranslationsForLocale(preferredLocale)]);
    void this.refreshGameDataIfChanged(preferredLocale);
  }

  async loadFreshGameData(locale?: AppLocale): Promise<void> {
    await this.loadGameData(locale);
    await this.refreshGameDataIfChanged(locale);
  }

  async refreshGameDataIfChanged(locale?: AppLocale): Promise<void> {
    const preferred = clashyLocaleCodeForAppLocale(locale ?? (await this.resolvePreferredLocale()));
    const manifest = await this.refreshStaticDataIfChanged();
    const entry = manifest
      ? manifestData(manifest).translations.find(
          (item) => item.path === `translations/${preferred}.json`,
        )
      : undefined;
    if (preferred !== 'EN') {
      await this.refreshAsset(
        dataCache(
          `translations_${preferred}.json`,
          isRecord(entry) && typeof entry.sha === 'string' ? entry.sha : undefined,
        ),
        `${TRANSLATIONS_URL}/${preferred}.json`,
      )
        .then((data) => {
          // A locale switch during the request must not restore the old language.
          if (this.desiredLocale === preferred) applyGameTranslations(data, preferred);
        })
        .catch(() => undefined);
    }
  }

  async refreshStaticDataIfChanged(): Promise<JsonRecord | undefined> {
    try {
      const manifest = await this.refreshAsset(MANIFEST_CACHE, ASSET_MANIFEST_URL);
      await this.noticeManifest(manifest);
      applyAssetManifest(manifest);
      await this.loadSections(manifest, true).catch(() => undefined);
      return manifest;
    } catch {
      // Keep the last good body on network, decode, or storage failure.
    }
  }

  async loadTranslationsForLocale(locale: AppLocale): Promise<void> {
    const clashyLocale = clashyLocaleCodeForAppLocale(locale);
    this.desiredLocale = clashyLocale;
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
      const manifest = await this.loadCachedJsonAsset(MANIFEST_CACHE, ASSET_MANIFEST_URL);
      await this.noticeManifest(manifest);
      applyAssetManifest(manifest);
      await this.loadSections(manifest, false);
    } catch {
      // Flutter deliberately retains the last valid in-memory static bundle.
    }
  }

  private async loadTranslationsOnce(clashyLocale: string): Promise<void> {
    try {
      const data = await this.loadCachedJsonAsset(
        dataCache(`translations_${clashyLocale}.json`),
        `${TRANSLATIONS_URL}/${clashyLocale}.json`,
      );
      if (this.desiredLocale === clashyLocale) applyGameTranslations(data, clashyLocale);
    } catch {
      if (this.desiredLocale === clashyLocale) clearGameTranslations(clashyLocale);
    }
  }

  private async noticeManifest(manifest: JsonRecord): Promise<void> {
    const available = new Map(
      [...validateAssetManifest(manifest)].map(([path, image]) => [path, image.sha]),
    );
    const data = manifestData(manifest);
    for (const item of [...data.stats, ...data.translations]) available.set(item.path, item.sha);
    await this.fileIndex.notice(available);
  }

  private async loadSections(manifest: JsonRecord, refresh: boolean): Promise<void> {
    const entries = manifestData(manifest).stats;
    if (!entries.length) throw new Error('Empty static data index');
    const bundle: JsonRecord = {};
    // Bound concurrency instead of starting every section request at once.
    for (let offset = 0; offset < entries.length; offset += 4) {
      await Promise.all(
        entries.slice(offset, offset + 4).map(async (entry) => {
          if (typeof entry.sha !== 'string' || !/^[a-f0-9]{64}$/.test(entry.sha))
            throw new Error('Invalid section hash');
          const path = String(entry.path);
          const name = path.slice('static_data/'.length, -5);
          const asset = dataCache(`static_data_${name}.json`, entry.sha);
          const url = `https://assets.clashk.ing/${path}`;
          const cached = await this.readCache(asset).catch(() => null);
          if (cached?.sha === entry.sha) await this.reconcileSavedFile(asset, url, cached);
          const data =
            cached?.sha === entry.sha
              ? parseJsonObject(cached.body, asset.label)
              : await (refresh
                  ? this.refreshAsset(asset, url)
                  : this.loadCachedJsonAsset(asset, url));
          if (!Array.isArray(data.items)) throw new Error('Invalid static data section');
          bundle[name] = data.items;
        }),
      );
    }
    // Never replace the in-memory bundle with a partially downloaded set.
    applyGameDataBundle(bundle);
  }

  private async readCache(asset: CachedJsonAsset): Promise<JsonCache | null> {
    const slot = await this.preferences.getString(asset.fileName + '.slot');
    if (slot === 'a' || slot === 'b') {
      const saved = await this.files.read(asset.fileName + '.' + slot);
      if (saved !== null) {
        try {
          const value: unknown = JSON.parse(saved);
          if (
            isRecord(value) &&
            typeof value.body === 'string' &&
            (value.etag === null || typeof value.etag === 'string') &&
            (value.lastModified === null || typeof value.lastModified === 'string') &&
            typeof value.checkedAt === 'string'
          ) {
            this.validateAssetBody(asset, value.body);
            return {
              body: value.body,
              etag: value.etag,
              sha: typeof value.sha === 'string' ? value.sha : undefined,
              lastModified: value.lastModified,
              checkedAt: value.checkedAt,
            };
          }
        } catch {
          /* Fall back to the previous unversioned cache. */
        }
      }
    }
    const body = await this.files.read(asset.fileName);
    if (body === null) return null;
    try {
      this.validateAssetBody(asset, body);
      return {
        body,
        etag: null,
        lastModified: await this.preferences.getString(asset.lastModifiedKey),
        checkedAt: (await this.preferences.getString(asset.cachedAtKey)) ?? '',
      };
    } catch {
      return null;
    }
  }

  private async saveCache(asset: CachedJsonAsset, record: JsonCache): Promise<void> {
    // Each persisted body + SHA is our local inventory of installed JSON, separate
    // from the downloaded manifest of available versions. Failed downloads never
    // advance this SHA, so mismatches survive process termination and retry on launch.
    // Write the inactive slot first, then commit one pointer. A failed write never
    // pairs a new validator with an old body or destroys the last complete record.
    const previous = await this.preferences.getString(asset.fileName + '.slot');
    const slot = previous === 'a' ? 'b' : 'a';
    await this.files.write(asset.fileName + '.' + slot, JSON.stringify(record));
    await this.preferences.setString(asset.fileName + '.slot', slot);
  }

  private async reconcileSavedFile(
    asset: CachedJsonAsset,
    url: string,
    cache: JsonCache,
  ): Promise<void> {
    if (!cache.sha || asset === MANIFEST_CACHE) return;
    const local = await this.fileIndex.get(url);
    if (local?.installedSha === cache.sha && local.pendingSha !== cache.sha) return;
    await this.fileIndex.prepare(url, new URL(url).pathname.slice(1));
    const slot = await this.preferences.getString(asset.fileName + '.slot');
    if (slot) await this.fileIndex.commit(url, asset.fileName + '.' + slot, cache.sha);
  }

  private validateAssetBody(asset: CachedJsonAsset, body: string): void {
    const data = parseJsonObject(body, asset.label);
    if (asset === MANIFEST_CACHE) validateAssetManifest(data);
    else if (asset.fileName.startsWith('static_data_') && !Array.isArray(data.items))
      throw new Error('Invalid static data section');
    else if (
      asset.fileName.startsWith('translations_') &&
      Object.values(data).some((value) => typeof value !== 'string')
    )
      throw new Error('Invalid translation catalog');
  }

  private async loadCachedJsonAsset(asset: CachedJsonAsset, url: string): Promise<JsonRecord> {
    const cache = await this.readCache(asset).catch(() => null);
    const pending =
      asset === MANIFEST_CACHE ? undefined : (await this.fileIndex.get(url))?.pendingSha;
    if (cache !== null && !pending && (!asset.sha || cache.sha === asset.sha)) {
      return parseJsonObject(cache.body, asset.label);
    }
    return this.refreshAsset(asset, url);
  }

  private cacheNeedsRefresh(checkedAt: string): boolean {
    const age = this.now().getTime() - Date.parse(checkedAt);
    return !Number.isFinite(age) || age < 0 || age >= GAME_DATA_CACHE_FRESHNESS_MS;
  }

  private refreshAsset(asset: CachedJsonAsset, url: string): Promise<JsonRecord> {
    const refreshKey = url + (asset.sha ?? '');
    const existing = this.refreshes.get(refreshKey);
    if (existing) return existing;
    const refresh = this.refreshAssetOnce(asset, url);
    this.refreshes.set(refreshKey, refresh);
    void refresh
      .finally(() => {
        if (this.refreshes.get(refreshKey) === refresh) this.refreshes.delete(refreshKey);
      })
      .catch(() => undefined);
    return refresh;
  }

  private async refreshAssetOnce(asset: CachedJsonAsset, url: string): Promise<JsonRecord> {
    const cache = await this.readCache(asset).catch(() => null);
    const local =
      asset === MANIFEST_CACHE
        ? undefined
        : await this.fileIndex.prepare(url, new URL(url).pathname.slice(1), asset.sha);
    const expectedSha = local?.pendingSha ?? asset.sha;
    if (cache?.sha && cache.sha === expectedSha) await this.reconcileSavedFile(asset, url, cache);
    const now = this.now().getTime();
    const attemptKey = url + (expectedSha ?? '');
    const lastAttempt = this.attempts.get(attemptKey);
    if (
      (cache &&
        (!expectedSha || cache.sha === expectedSha) &&
        !this.cacheNeedsRefresh(cache.checkedAt)) ||
      (lastAttempt !== undefined &&
        now >= lastAttempt &&
        now - lastAttempt < GAME_DATA_CACHE_FRESHNESS_MS)
    ) {
      if (cache) return parseJsonObject(cache.body, asset.label);
      throw new Error('Metadata retry is waiting for the next refresh interval');
    }
    this.attempts.set(attemptKey, now);
    const headers: Record<string, string> = { 'User-Agent': GAME_DATA_USER_AGENT };
    if (cache?.etag) headers['If-None-Match'] = cache.etag;
    else if (cache?.lastModified) headers['If-Modified-Since'] = cache.lastModified;
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 10_000);
    try {
      const response = await this.fetchImplementation(url, {
        method: 'GET',
        headers,
        signal: controller.signal,
        cache: 'no-cache',
      });
      let record: JsonCache;
      if (response.status === 304 && cache) {
        if (
          expectedSha &&
          cache.sha !== expectedSha &&
          (await digestStringAsync(CryptoDigestAlgorithm.SHA256, cache.body)) !== expectedSha
        )
          throw new Error('Section is not updated yet');
        record = { ...cache, sha: expectedSha ?? cache.sha, checkedAt: this.now().toISOString() };
      } else if (response.status === 200) {
        const body = await response.text();
        this.validateAssetBody(asset, body);
        const actualSha = await digestStringAsync(CryptoDigestAlgorithm.SHA256, body);
        if (expectedSha && actualSha !== expectedSha)
          throw new Error('Downloaded section does not match manifest');
        record = {
          sha: actualSha,
          body,
          etag: response.headers.get('etag'),
          lastModified: response.headers.get('last-modified'),
          checkedAt: this.now().toISOString(),
        };
      } else throw new Error(`HTTP ${response.status} for ${asset.label}`);
      const decoded = parseJsonObject(record.body, asset.label);
      if (asset === MANIFEST_CACHE) await this.noticeManifest(decoded);
      // A valid downloaded body is usable even if persistence is unavailable.
      await this.saveCache(asset, record)
        .then(async () => {
          if (asset !== MANIFEST_CACHE && record.sha) {
            const slot = await this.preferences.getString(asset.fileName + '.slot');
            await this.fileIndex.commit(url, asset.fileName + '.' + slot, record.sha);
          }
        })
        .catch(() => undefined);
      return decoded;
    } catch (error) {
      if (cache) return parseJsonObject(cache.body, asset.label);
      throw error;
    } finally {
      clearTimeout(timer);
    }
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
