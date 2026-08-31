import type { StringStore } from '../../services/storage/auth-storage';
import {
  GAME_ASSET_CACHE_DURATION_MS,
  GameAssetManifestLoadError,
  GameAssetManifestService,
  PreferenceGameAssetManifestCache,
  type CachedGameAssetManifest,
  type GameAssetManifestCache,
} from './repository';

const validJson = JSON.stringify({
  version: 1,
  assets: [
    {
      path: 'heroes/king.png',
      category: 'heroes',
      display_name: 'king',
      extension: 'png',
      url: 'https://assets.test/heroes/king.png',
    },
  ],
});

class MemoryCache implements GameAssetManifestCache {
  value: CachedGameAssetManifest | null = null;
  read = jest.fn(async () => this.value);
  write = jest.fn(async (value: CachedGameAssetManifest) => {
    this.value = value;
  });
  clear = jest.fn(async () => {
    this.value = null;
  });
}

function response(body: string, status = 200): Response {
  return { ok: status >= 200 && status < 300, status, text: async () => body } as Response;
}

describe('GameAssetManifestService', () => {
  it('uses fresh persistent then memory cache without a network call', async () => {
    const cache = new MemoryCache();
    cache.value = { json: validJson, fetchedAt: new Date(1_000) };
    const fetchImplementation = jest.fn(async () => response(validJson));
    const service = new GameAssetManifestService({
      cache,
      fetchImplementation: fetchImplementation as typeof fetch,
      now: () => new Date(1_000 + GAME_ASSET_CACHE_DURATION_MS),
    });
    const first = await service.load();
    const second = await service.load();
    expect(second).toBe(first);
    expect(fetchImplementation).not.toHaveBeenCalled();
  });

  it('force refreshes, writes successful JSON best-effort, and preserves a newer timestamp', async () => {
    const cache = new MemoryCache();
    const times = [new Date(1_000), new Date(2_000)];
    const service = new GameAssetManifestService({
      cache,
      fetchImplementation: jest.fn(async () => response(validJson)) as typeof fetch,
      now: () => times.shift() ?? new Date(2_000),
    });
    await service.load({ forceRefresh: true });
    expect(cache.write).toHaveBeenCalledWith({ json: validJson, fetchedAt: new Date(2_000) });
  });

  it('falls back to stale disk and stale memory when refresh fails', async () => {
    const cache = new MemoryCache();
    cache.value = { json: validJson, fetchedAt: new Date(0) };
    const fetchImplementation = jest.fn(async () => response('', 503));
    const service = new GameAssetManifestService({
      cache,
      fetchImplementation: fetchImplementation as typeof fetch,
      now: () => new Date(GAME_ASSET_CACHE_DURATION_MS + 1),
    });
    const stale = await service.load();
    expect(stale.assets).toHaveLength(1);
    cache.value = null;
    await expect(service.load({ forceRefresh: true })).resolves.toBe(stale);
  });

  it('clears invalid cache and reports a typed load error when network also fails', async () => {
    const cache = new MemoryCache();
    cache.value = { json: '{broken', fetchedAt: new Date() };
    const service = new GameAssetManifestService({
      cache,
      fetchImplementation: jest.fn(async () => {
        throw new TypeError('offline');
      }) as typeof fetch,
    });
    await expect(service.load()).rejects.toBeInstanceOf(GameAssetManifestLoadError);
    expect(cache.clear).toHaveBeenCalledTimes(1);
  });
});

describe('PreferenceGameAssetManifestCache', () => {
  it('uses Flutter-compatible preference keys and millisecond timestamp strings', async () => {
    const values = new Map<string, string>();
    const store: StringStore = {
      getItem: async (key) => values.get(key) ?? null,
      setItem: async (key, value) => {
        values.set(key, value);
      },
      removeItem: async (key) => {
        values.delete(key);
      },
    };
    const cache = new PreferenceGameAssetManifestCache(store);
    await cache.write({ json: validJson, fetchedAt: new Date(1234) });
    await expect(cache.read()).resolves.toEqual({ json: validJson, fetchedAt: new Date(1234) });
    expect(values.get('game_asset_manifest_v1')).toBe(validJson);
    expect(values.get('game_asset_manifest_v1_fetched_at')).toBe('1234');
  });
});
