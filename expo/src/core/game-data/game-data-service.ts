import { ASSET_ORIGIN } from '../assets/asset-origin';
import {
  applyGameTranslations,
  clashyLocaleCodeForAppLocale,
  clearGameTranslations,
  type AppLocale,
} from './game-data-localization';
import { applyGameDataBundle } from './game-data-normalization';
import { applyLocalGameAssets } from './local-game-assets';
import { gameDataState, isRecord, type JsonRecord } from './game-data-state';
import {
  applyAssetManifest,
  ASSET_MANIFEST_URL,
  installImageManifest,
  isManifestSha,
  validateAssetManifest,
  manifestData,
  manifestTranslations,
  readImageCatalog,
  type ManifestDataEntry,
} from '../assets/asset-manifest';
import { CryptoDigestAlgorithm, digestStringAsync } from 'expo-crypto';

export const STATIC_DATA_URL = `${ASSET_ORIGIN}/static_data`;
export const TRANSLATIONS_URL = `${ASSET_ORIGIN}/translations`;
export const GAME_DATA_USER_AGENT = 'ClashKing-App/1.0';
export const GAME_DATA_CACHE_FRESHNESS_MS = 60 * 1_000;
const STARTUP_METADATA_URL = `${ASSET_ORIGIN}/app_metadata/v1`;

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
  removeString(key: string): Promise<void>;
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

interface JsonCache {
  readonly sha?: string;
  readonly body: string;
  readonly etag: string | null;
  readonly lastModified: string | null;
  readonly checkedAt: string;
}

interface CachedJsonAsset {
  readonly sha?: string;
  readonly immutable?: boolean;
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

const LEGACY_WIKI_MANIFEST = 'game_asset_manifest_v1';
const LEGACY_WIKI_FETCHED_AT = 'game_asset_manifest_v1_fetched_at';

interface StartupMetadataIndex {
  readonly staticSha: string;
  readonly imagesSha: string;
  readonly translations: readonly ManifestDataEntry[];
}
type MetadataLoadMode = 'cached' | 'refresh' | 'force';

function dataCache(fileName: string, sha?: string): CachedJsonAsset {
  return {
    label: fileName,
    fileName,
    sha,
    lastModifiedKey: fileName + '.lastModified',
    cachedAtKey: fileName + '.cachedAt',
  };
}

const STARTUP_INDEX_CACHE = dataCache('app_startup_index.json');
const STARTUP_INDEX_MISSING_AT = 'app_startup_index.missingAt';

function readStartupIndex(value: JsonRecord): StartupMetadataIndex {
  if (value.version !== 1 || !isManifestSha(value.staticSha) || !isManifestSha(value.imagesSha))
    throw new Error('Invalid startup metadata index');
  return {
    staticSha: value.staticSha,
    imagesSha: value.imagesSha,
    translations: manifestTranslations(value.translations),
  };
}

function translationCache(locale: string, entries?: readonly ManifestDataEntry[]): CachedJsonAsset {
  const entry = entries?.find(
    (item) => item.path === `translations/${locale}.json`,
  );
  return dataCache(`translations_${locale}.json`, entry?.sha);
}

export class GameDataService {
  private readonly files: GameDataFileStore;
  private readonly preferences: GameDataPreferences;
  private readonly fetchImplementation: typeof fetch;
  private readonly platform: GameDataPlatform;
  private readonly now: () => Date;
  private readonly systemLocales: () => readonly AppLocale[];
  private manifest?: JsonRecord;
  private manifestLoad?: Promise<JsonRecord>;
  private manifestRefresh?: Promise<JsonRecord>;
  private startupLoad?: Promise<readonly ManifestDataEntry[] | undefined>;
  private startupIndex?: StartupMetadataIndex;
  private appliedImageCatalog?: string;
  private appliedSections: string | null = null;
  private readonly refreshes = new Map<string, Promise<JsonRecord>>();
  private readonly attempts = new Map<string, number>();
  private readonly translationLoads = new Map<string, Promise<void>>();
  private desiredLocale = 'EN';

  constructor(options: GameDataServiceOptions) {
    this.files = options.files;
    this.preferences = options.preferences;
    // A raw Window.fetch stored on this service is invoked with the service
    // as `this`, which browsers reject with "Illegal invocation". Keep the
    // browser receiver intact without changing injected transports.
    this.fetchImplementation = options.fetchImplementation ?? ((input, init) => fetch(input, init));
    this.platform = options.platform;
    this.now = options.now ?? (() => new Date());
    this.systemLocales = options.systemLocales ?? (() => []);
  }

  async loadGameData(locale?: AppLocale): Promise<void> {
    const preferredLocale = locale ?? (await this.resolvePreferredLocale());
    await Promise.all([this.loadStartupData('cached'), this.loadTranslationsForLocale(preferredLocale)]);
    void this.refreshGameDataIfChanged(preferredLocale);
  }

  async loadFreshGameData(locale?: AppLocale): Promise<void> {
    await this.loadGameData(locale);
    await this.refreshGameDataIfChanged(locale);
  }

  async refreshGameDataIfChanged(locale?: AppLocale): Promise<void> {
    const preferred = clashyLocaleCodeForAppLocale(locale ?? (await this.resolvePreferredLocale()));
    const translations = await this.loadStartupData('refresh');
    if (preferred !== 'EN') {
      await this.refreshAsset(
        translationCache(preferred, translations ?? this.translationEntries()),
        `${TRANSLATIONS_URL}/${preferred}.json`,
      )
        .then((data) => {
          // A locale switch during the request must not restore the old language.
          if (this.desiredLocale === preferred) applyGameTranslations(data, preferred);
        })
        .catch(() => undefined);
    }
  }

  loadAssetManifest(mode: MetadataLoadMode = 'cached'): Promise<JsonRecord> {
    if (mode !== 'cached') {
      const pending = this.manifestLoad;
      this.manifestRefresh ??= (async () => {
        await pending?.catch(() => undefined);
        const manifest = await this.refreshAsset(
          MANIFEST_CACHE,
          ASSET_MANIFEST_URL,
          mode === 'force',
        ).catch((error) => {
          if (this.manifest) return this.manifest;
          throw error;
        });
        return this.installManifest(manifest);
      })().finally(() => {
        this.manifestRefresh = undefined;
      });
      return this.manifestRefresh;
    }
    if (this.manifest) return Promise.resolve(this.manifest);
    if (this.manifestRefresh) return this.manifestRefresh;
    this.manifestLoad ??= this.loadCachedJsonAsset(MANIFEST_CACHE, ASSET_MANIFEST_URL)
      .then((manifest) => this.installManifest(manifest))
      .finally(() => {
        this.manifestLoad = undefined;
      });
    return this.manifestLoad;
  }

  private installManifest(manifest: JsonRecord): JsonRecord {
    if (manifest === this.manifest) return manifest;
    if (!this.appliedImageCatalog) applyAssetManifest(manifest);
    this.manifest = manifest;
    return manifest;
  }

  async refreshStaticDataIfChanged(force = false): Promise<JsonRecord | undefined> {
    if (force) await this.startupLoad;
    await this.loadStartupData(force ? 'force' : 'refresh');
    // A manual Wiki refresh also revalidates the detailed catalogue it displays.
    if (force && this.startupIndex)
      return this.loadAssetManifest('force').catch(() => this.manifest);
    return this.manifest;
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

  private loadStartupData(mode: MetadataLoadMode): Promise<readonly ManifestDataEntry[] | undefined> {
    this.startupLoad ??= this.loadStartupDataOnce(mode).finally(() => {
      this.startupLoad = undefined;
    });
    return this.startupLoad;
  }

  private async loadStartupDataOnce(mode: MetadataLoadMode): Promise<readonly ManifestDataEntry[] | undefined> {
    try {
      const savedIndex = mode === 'cached' ? await this.readCache(STARTUP_INDEX_CACHE).catch(() => null) : null;
      if (mode === 'cached' && !savedIndex) {
        const legacy = await this.loadCompleteLegacyCache();
        if (legacy) return manifestData(legacy).translations;
      }
      const missingAt = this.startupIndex ? null : await this.preferences
        .getString(STARTUP_INDEX_MISSING_AT).catch(() => null);
      if (!savedIndex && missingAt && !this.cacheNeedsRefresh(missingAt))
        throw new Error('Startup metadata unavailable');
      const url = `${STARTUP_METADATA_URL}/index.json`;
      const index = readStartupIndex(savedIndex
        ? parseJsonObject(savedIndex.body, STARTUP_INDEX_CACHE.label)
        : await this.refreshAsset(STARTUP_INDEX_CACHE, url, mode === 'force'));
      const [stats, images] = await Promise.all([
        this.appliedSections === index.staticSha ? undefined : this.loadStartupPart('static', index.staticSha),
        this.appliedImageCatalog === index.imagesSha ? undefined : this.loadStartupPart('images', index.imagesSha),
      ]);
      if (images && this.appliedImageCatalog !== images.sha) {
        installImageManifest(readImageCatalog(images.body));
        this.appliedImageCatalog = images.sha;
      }
      if (stats && this.appliedSections !== stats.sha) {
        applyGameDataBundle(await applyLocalGameAssets(stats.body, this.fetchImplementation));
        this.appliedSections = stats.sha;
      }
      this.startupIndex = index;
      return index.translations;
    } catch {
      // Older CDN releases still serve the full Wiki manifest and individual sections.
      try {
        const manifest = await this.loadAssetManifest(mode);
        if (this.appliedImageCatalog) {
          applyAssetManifest(manifest);
          this.appliedImageCatalog = undefined;
        }
        this.startupIndex = undefined;
        await this.loadSections(manifest, mode).catch(() => undefined);
        return manifestData(manifest).translations;
      } catch {
        // Keep the last valid in-memory data on network or storage failure.
      }
    }
  }

  private async loadCompleteLegacyCache(): Promise<JsonRecord | undefined> {
    try {
      const saved = await this.readCache(MANIFEST_CACHE);
      if (!saved) return undefined;
      const manifest = parseJsonObject(saved.body, MANIFEST_CACHE.label);
      await this.loadSections(manifest, 'cache-only');
      return this.installManifest(manifest);
    } catch {
      // A partial legacy cache must not start individual downloads before probing the new index.
      return undefined;
    }
  }

  private async loadStartupPart(kind: 'static' | 'images', sha: string) {
    const asset = { ...dataCache(`app_startup_${kind}.json`, sha), immutable: true };
    const cache = await this.readCache(asset).catch(() => null);
    if (cache?.sha === sha) return { sha, body: parseJsonObject(cache.body, asset.label) };
    try {
      const body = await this.refreshAsset(asset, `${STARTUP_METADATA_URL}/${kind}-${sha}.json`);
      return { sha, body };
    } catch (error) {
      // Each payload retains its last good version if a new object is temporarily unavailable.
      if (!cache || !isManifestSha(cache.sha)) throw error;
      return { sha: cache.sha, body: parseJsonObject(cache.body, asset.label) };
    }
  }

  private translationEntries(): readonly ManifestDataEntry[] | undefined {
    return this.startupIndex?.translations ?? (this.manifest && manifestData(this.manifest).translations);
  }

  private async loadTranslationsOnce(clashyLocale: string): Promise<void> {
    try {
      const data = await this.loadCachedJsonAsset(
        translationCache(clashyLocale, this.translationEntries()),
        `${TRANSLATIONS_URL}/${clashyLocale}.json`,
      );
      if (this.desiredLocale === clashyLocale) applyGameTranslations(data, clashyLocale);
    } catch {
      if (this.desiredLocale === clashyLocale) clearGameTranslations(clashyLocale);
    }
  }

  private async loadSections(manifest: JsonRecord, mode: MetadataLoadMode | 'cache-only'): Promise<void> {
    const entries = manifestData(manifest).stats;
    if (!entries.length) throw new Error('Empty static data index');
    const signature = JSON.stringify(entries.map((entry) => [entry.path, entry.sha]));
    if (this.appliedSections === signature) return;
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
          const url = `${ASSET_ORIGIN}/${path}`;
          const cached = await this.readCache(asset).catch(() => null);
          if (mode === 'cache-only' && cached?.sha !== entry.sha)
            throw new Error('Incomplete cached static data');
          const data =
            cached?.sha === entry.sha
              ? parseJsonObject(cached.body, asset.label)
              : await (mode === 'cached'
                  ? this.loadCachedJsonAsset(asset, url)
                  : this.refreshAsset(asset, url));
          if (!Array.isArray(data.items)) throw new Error('Invalid static data section');
          bundle[name] = data.items;
        }),
      );
    }
    // Never replace the in-memory bundle with a partially downloaded set.
    applyGameDataBundle(await applyLocalGameAssets(bundle, this.fetchImplementation));
    this.appliedSections = signature;
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
    if (body === null) return asset === MANIFEST_CACHE ? this.migrateWikiManifest() : null;
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

  private async migrateWikiManifest(): Promise<JsonCache | null> {
    const body = await this.preferences.getString(LEGACY_WIKI_MANIFEST);
    if (!body) return null;
    try {
      this.validateAssetBody(MANIFEST_CACHE, body);
    } catch {
      return null;
    }
    const record = { body, etag: null, lastModified: null, checkedAt: '' };
    await this.saveCache(MANIFEST_CACHE, record).catch(() => undefined);
    return record;
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
    if (asset === MANIFEST_CACHE)
      await Promise.allSettled([
        this.preferences.removeString(LEGACY_WIKI_MANIFEST),
        this.preferences.removeString(LEGACY_WIKI_FETCHED_AT),
      ]);
  }

  private validateAssetBody(asset: CachedJsonAsset, body: string): void {
    const data = parseJsonObject(body, asset.label);
    if (asset === MANIFEST_CACHE) validateAssetManifest(data);
    else if (asset === STARTUP_INDEX_CACHE) readStartupIndex(data);
    else if (asset.fileName === 'app_startup_images.json') readImageCatalog(data);
    else if (asset.fileName === 'app_startup_static.json') {
      const sections = Object.entries(data);
      if (!sections.length || sections.some(([name, items]) => !/^[a-z_]+$/.test(name) || !Array.isArray(items)))
        throw new Error('Invalid startup static data');
    } else if (asset.fileName.startsWith('static_data_') && !Array.isArray(data.items))
      throw new Error('Invalid static data section');
    else if (
      asset.fileName.startsWith('translations_') &&
      Object.values(data).some((value) => typeof value !== 'string')
    )
      throw new Error('Invalid translation catalog');
  }

  private async loadCachedJsonAsset(asset: CachedJsonAsset, url: string): Promise<JsonRecord> {
    const cache = await this.readCache(asset).catch(() => null);
    if (cache !== null && (!asset.sha || cache.sha === asset.sha)) {
      return parseJsonObject(cache.body, asset.label);
    }
    return this.refreshAsset(asset, url);
  }

  private cacheNeedsRefresh(checkedAt: string): boolean {
    const age = this.now().getTime() - Date.parse(checkedAt);
    return !Number.isFinite(age) || age < 0 || age >= GAME_DATA_CACHE_FRESHNESS_MS;
  }

  private refreshAsset(asset: CachedJsonAsset, url: string, force = false): Promise<JsonRecord> {
    const refreshKey = url + (asset.sha ?? '');
    const existing = this.refreshes.get(refreshKey);
    if (existing) return existing;
    const refresh = this.refreshAssetOnce(asset, url, force);
    this.refreshes.set(refreshKey, refresh);
    void refresh
      .finally(() => {
        if (this.refreshes.get(refreshKey) === refresh) this.refreshes.delete(refreshKey);
      })
      .catch(() => undefined);
    return refresh;
  }

  private async refreshAssetOnce(
    asset: CachedJsonAsset,
    url: string,
    force: boolean,
  ): Promise<JsonRecord> {
    const expectedSha = asset.sha;
    const saved = await this.readCache(asset).catch(() => null);
    const cache = asset.immutable && saved?.sha !== expectedSha ? null : saved;
    const now = this.now().getTime();
    const attemptKey = url + (expectedSha ?? '');
    const lastAttempt = this.attempts.get(attemptKey);
    const hasFreshCache =
      cache &&
      (!expectedSha || cache.sha === expectedSha) &&
      !this.cacheNeedsRefresh(cache.checkedAt);
    const attemptedRecently =
      lastAttempt !== undefined &&
      now >= lastAttempt &&
      now - lastAttempt < GAME_DATA_CACHE_FRESHNESS_MS;
    if (!force && (hasFreshCache || attemptedRecently)) {
      if (cache) return parseJsonObject(cache.body, asset.label);
      throw new Error('Metadata retry is waiting for the next refresh interval');
    }
    this.attempts.set(attemptKey, now);
    // A native User-Agent override is not a portable browser request header;
    // it can cause a rejected cross-origin preflight instead of loading data.
    const headers: Record<string, string> =
      this.platform === 'web' ? {} : { 'User-Agent': GAME_DATA_USER_AGENT };
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
      } else {
        if (response.status === 404 && asset === STARTUP_INDEX_CACHE && !cache) {
          await this.preferences.setString(STARTUP_INDEX_MISSING_AT, this.now().toISOString())
            .catch(() => undefined);
        }
        throw new Error(`HTTP ${response.status} for ${asset.label}`);
      }
      const decoded = parseJsonObject(record.body, asset.label);
      // A valid downloaded body is usable even if persistence is unavailable.
      await this.saveCache(asset, record).catch(() => undefined);
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
