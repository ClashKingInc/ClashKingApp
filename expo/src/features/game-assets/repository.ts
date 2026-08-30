import type { StringStore } from '../../services/storage/auth-storage';
import { GameAssetManifest } from './models';

export const GAME_ASSET_MANIFEST_URL = 'https://assets.clashk.ing/manifest.json';
export const GAME_ASSET_CACHE_DURATION_MS = 30 * 60 * 1000;
export const GAME_ASSET_REQUEST_TIMEOUT_MS = 20 * 1000;

export interface CachedGameAssetManifest {
  readonly json: string;
  readonly fetchedAt: Date;
}

export interface GameAssetManifestCache {
  read(): Promise<CachedGameAssetManifest | null>;
  write(manifest: CachedGameAssetManifest): Promise<void>;
  clear(): Promise<void>;
}

export interface GameAssetManifestRepository {
  load(options?: { forceRefresh?: boolean }): Promise<GameAssetManifest>;
}

export class GameAssetManifestLoadError extends Error {
  constructor(message: string, options?: ErrorOptions) {
    super(message, options);
    this.name = 'GameAssetManifestLoadError';
  }
}

export class PreferenceGameAssetManifestCache implements GameAssetManifestCache {
  static readonly jsonKey = 'game_asset_manifest_v1';
  static readonly fetchedAtKey = 'game_asset_manifest_v1_fetched_at';

  constructor(private readonly store: StringStore) {}

  async read(): Promise<CachedGameAssetManifest | null> {
    const [json, fetchedAt] = await Promise.all([
      this.store.getItem(PreferenceGameAssetManifestCache.jsonKey),
      this.store.getItem(PreferenceGameAssetManifestCache.fetchedAtKey),
    ]);
    if (json === null || fetchedAt === null) return null;
    const milliseconds = Number(fetchedAt);
    if (!Number.isFinite(milliseconds)) throw new TypeError('Invalid game asset cache timestamp');
    return { json, fetchedAt: new Date(milliseconds) };
  }

  async write(manifest: CachedGameAssetManifest): Promise<void> {
    await Promise.all([
      this.store.setItem(PreferenceGameAssetManifestCache.jsonKey, manifest.json),
      this.store.setItem(
        PreferenceGameAssetManifestCache.fetchedAtKey,
        String(manifest.fetchedAt.getTime()),
      ),
    ]);
  }

  async clear(): Promise<void> {
    await Promise.all([
      this.store.removeItem(PreferenceGameAssetManifestCache.jsonKey),
      this.store.removeItem(PreferenceGameAssetManifestCache.fetchedAtKey),
    ]);
  }
}

export class GameAssetManifestService implements GameAssetManifestRepository {
  private memoryManifest: GameAssetManifest | null = null;
  private memoryFetchedAt: Date | null = null;

  constructor(
    private readonly options: {
      readonly cache: GameAssetManifestCache;
      readonly fetchImplementation?: typeof fetch;
      readonly now?: () => Date;
      readonly cacheDurationMs?: number;
      readonly requestTimeoutMs?: number;
    },
  ) {}

  async load({
    forceRefresh = false,
  }: { forceRefresh?: boolean } = {}): Promise<GameAssetManifest> {
    const now = (this.options.now ?? (() => new Date()))();
    if (!forceRefresh && this.memoryManifest && this.isFresh(this.memoryFetchedAt, now)) {
      return this.memoryManifest;
    }

    let cached: CachedGameAssetManifest | null = null;
    try {
      cached = await this.options.cache.read();
      if (!forceRefresh && cached && this.isFresh(cached.fetchedAt, now)) {
        return this.remember(this.decode(cached.json), cached.fetchedAt);
      }
    } catch {
      await this.discardInvalidCache();
      cached = null;
    }

    try {
      const controller = new AbortController();
      const timeout = setTimeout(
        () => controller.abort(),
        this.options.requestTimeoutMs ?? GAME_ASSET_REQUEST_TIMEOUT_MS,
      );
      let response: Response;
      try {
        response = await (this.options.fetchImplementation ?? fetch)(GAME_ASSET_MANIFEST_URL, {
          signal: controller.signal,
        });
      } finally {
        clearTimeout(timeout);
      }
      if (!response.ok) {
        throw new GameAssetManifestLoadError(`Manifest request failed (${response.status})`);
      }
      const rawJson = await response.text();
      const manifest = this.decode(rawJson);
      const fetchedAt = (this.options.now ?? (() => new Date()))();
      this.remember(manifest, fetchedAt);
      try {
        await this.options.cache.write({ json: rawJson, fetchedAt });
      } catch {
        // Flutter intentionally treats persistence as best effort after a network success.
      }
      return manifest;
    } catch (error) {
      if (this.memoryManifest) return this.memoryManifest;
      if (cached) {
        try {
          return this.remember(this.decode(cached.json), cached.fetchedAt);
        } catch {
          await this.discardInvalidCache();
        }
      }
      if (error instanceof GameAssetManifestLoadError) throw error;
      throw new GameAssetManifestLoadError('Could not load the game asset manifest', {
        cause: error,
      });
    }
  }

  private isFresh(fetchedAt: Date | null, now: Date): boolean {
    return (
      fetchedAt !== null &&
      now.getTime() - fetchedAt.getTime() <=
        (this.options.cacheDurationMs ?? GAME_ASSET_CACHE_DURATION_MS)
    );
  }

  private remember(manifest: GameAssetManifest, fetchedAt: Date): GameAssetManifest {
    this.memoryManifest = manifest;
    this.memoryFetchedAt = fetchedAt;
    return manifest;
  }

  private decode(rawJson: string): GameAssetManifest {
    return GameAssetManifest.fromJson(JSON.parse(rawJson));
  }

  private async discardInvalidCache(): Promise<void> {
    try {
      await this.options.cache.clear();
    } catch {
      // A broken cache must not prevent a fresh network request.
    }
  }
}
