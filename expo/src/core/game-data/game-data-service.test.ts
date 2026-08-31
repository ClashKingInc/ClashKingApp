import {
  GAME_DATA_PREFERENCE_KEYS,
  GameDataService,
  STATIC_DATA_URL,
  TRANSLATIONS_URL,
  type GameDataFileStore,
  type GameDataPreferences,
} from './game-data-service';
import { gameDataState, resetGameDataStateForTesting } from './game-data-state';

class MemoryFiles implements GameDataFileStore {
  readonly values = new Map<string, string>();

  async read(fileName: string): Promise<string | null> {
    return this.values.get(fileName) ?? null;
  }

  async write(fileName: string, contents: string): Promise<void> {
    this.values.set(fileName, contents);
  }
}

class MemoryPreferences implements GameDataPreferences {
  readonly values = new Map<string, string>();

  async getString(key: string): Promise<string | null> {
    return this.values.get(key) ?? null;
  }

  async setString(key: string, value: string): Promise<void> {
    this.values.set(key, value);
  }
}

function response(status: number, body = '', headers: Record<string, string> = {}): Response {
  const normalized = new Map(
    Object.entries(headers).map(([key, value]) => [key.toLowerCase(), value]),
  );
  return {
    status,
    text: async () => body,
    headers: { get: (key: string) => normalized.get(key.toLowerCase()) ?? null },
  } as unknown as Response;
}

function fetchCalls(mock: jest.Mock): readonly (readonly [unknown, RequestInit | undefined])[] {
  return mock.mock.calls as [unknown, RequestInit | undefined][];
}

function createService(
  options: {
    platform?: 'native' | 'web';
    files?: MemoryFiles;
    preferences?: MemoryPreferences;
    fetchImplementation?: typeof fetch;
    now?: () => Date;
    sleep?: (milliseconds: number) => Promise<void>;
    systemLocales?: () => readonly { languageCode: string }[];
  } = {},
) {
  const files = options.files ?? new MemoryFiles();
  const preferences = options.preferences ?? new MemoryPreferences();
  const service = new GameDataService({
    platform: options.platform ?? 'native',
    files,
    preferences,
    fetchImplementation:
      options.fetchImplementation ??
      (jest.fn(async () => response(500)) as unknown as typeof fetch),
    now: options.now,
    sleep: options.sleep,
    systemLocales: options.systemLocales,
  });
  return { service, files, preferences };
}

beforeEach(resetGameDataStateForTesting);

describe('GameDataService loading and cache parity', () => {
  test('web performs a direct five-second GET without touching persistent storage', async () => {
    const files = new MemoryFiles();
    const preferences = new MemoryPreferences();
    const fetchMock = jest.fn(async () =>
      response(200, JSON.stringify({ troops: [{ name: 'Barbarian' }] })),
    );
    const { service } = createService({
      platform: 'web',
      files,
      preferences,
      fetchImplementation: fetchMock as unknown as typeof fetch,
    });

    await service.loadGameData({ languageCode: 'en' });

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(fetchCalls(fetchMock)[0]?.[0]).toBe(STATIC_DATA_URL);
    expect(fetchCalls(fetchMock)[0]?.[1]).toMatchObject({
      method: 'GET',
      headers: { 'User-Agent': 'ClashKing-App/1.0' },
    });
    expect(files.values.size).toBe(0);
    expect(preferences.values.size).toBe(0);
  });

  test('native uses a fresh six-hour cache without network access', async () => {
    const files = new MemoryFiles();
    const preferences = new MemoryPreferences();
    files.values.set('static_data.json', JSON.stringify({ troops: [{ name: 'Archer' }] }));
    preferences.values.set(GAME_DATA_PREFERENCE_KEYS.staticCachedAt, '2026-08-29T10:00:00.000Z');
    const fetchMock = jest.fn(async () => response(500));
    const { service } = createService({
      files,
      preferences,
      now: () => new Date('2026-08-29T15:59:59.999Z'),
      fetchImplementation: fetchMock as unknown as typeof fetch,
    });

    await service.loadGameData({ languageCode: 'en' });

    expect(fetchMock).not.toHaveBeenCalled();
    expect(gameDataState.troopsData.troops).toHaveProperty('Archer');
  });

  test('an unchanged HEAD validator advances freshness and re-applies the cached file', async () => {
    const files = new MemoryFiles();
    const preferences = new MemoryPreferences();
    files.values.set('static_data.json', JSON.stringify({ troops: [{ name: 'Miner' }] }));
    preferences.values.set(
      GAME_DATA_PREFERENCE_KEYS.staticLastModified,
      'Fri, 28 Aug 2026 10:00:00 GMT',
    );
    const fetchMock = jest.fn(async () =>
      response(204, '', { 'Last-Modified': 'Fri, 28 Aug 2026 10:00:00 GMT' }),
    );
    const { service } = createService({
      files,
      preferences,
      now: () => new Date('2026-08-29T16:00:00.000Z'),
      fetchImplementation: fetchMock as unknown as typeof fetch,
    });

    await service.refreshStaticDataIfChanged();

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(fetchCalls(fetchMock)[0]?.[1]).toMatchObject({ method: 'HEAD' });
    expect(preferences.values.get(GAME_DATA_PREFERENCE_KEYS.staticCachedAt)).toBe(
      '2026-08-29T16:00:00.000Z',
    );
    expect(gameDataState.troopsData.troops).toHaveProperty('Miner');
    expect(gameDataState.revision).toBe(1);
  });

  test('a changed validator retries once after one second and persists the response validator', async () => {
    const files = new MemoryFiles();
    const preferences = new MemoryPreferences();
    files.values.set('static_data.json', JSON.stringify({ troops: [{ name: 'Old' }] }));
    preferences.values.set(GAME_DATA_PREFERENCE_KEYS.staticLastModified, 'old-validator');
    const fetchMock = jest
      .fn()
      .mockResolvedValueOnce(response(200, '', { 'Last-Modified': 'head-validator' }))
      .mockResolvedValueOnce(response(503))
      .mockResolvedValueOnce(
        response(200, JSON.stringify({ troops: [{ name: 'New' }] }), {
          'Last-Modified': 'get-validator',
        }),
      );
    const sleeps: number[] = [];
    const { service } = createService({
      files,
      preferences,
      now: () => new Date('2026-08-29T16:00:00.000Z'),
      sleep: async (milliseconds) => {
        sleeps.push(milliseconds);
      },
      fetchImplementation: fetchMock as unknown as typeof fetch,
    });

    await service.refreshStaticDataIfChanged();

    expect(fetchMock).toHaveBeenCalledTimes(3);
    expect(sleeps).toEqual([1_000]);
    expect(preferences.values.get(GAME_DATA_PREFERENCE_KEYS.staticLastModified)).toBe(
      'get-validator',
    );
    expect(files.values.get('static_data.json')).toContain('New');
    expect(gameDataState.troopsData.troops).toHaveProperty('New');
    // The refresh applies the download and then intentionally re-reads the cache.
    expect(gameDataState.revision).toBe(2);
  });

  test('a HEAD response without Last-Modified leaves freshness unchanged', async () => {
    const files = new MemoryFiles();
    const preferences = new MemoryPreferences();
    files.values.set('static_data.json', JSON.stringify({ troops: [] }));
    const fetchMock = jest.fn(async () => response(200));
    const { service } = createService({
      files,
      preferences,
      fetchImplementation: fetchMock as unknown as typeof fetch,
    });

    await service.refreshStaticDataIfChanged();

    expect(preferences.values.has(GAME_DATA_PREFERENCE_KEYS.staticCachedAt)).toBe(false);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  test('invalid native cache gets one replacement attempt', async () => {
    const files = new MemoryFiles();
    files.values.set('static_data.json', '[]');
    const fetchMock = jest.fn(async () =>
      response(200, JSON.stringify({ troops: [{ name: 'Replacement' }] })),
    );
    const { service } = createService({
      files,
      fetchImplementation: fetchMock as unknown as typeof fetch,
    });

    await service.loadGameData({ languageCode: 'en' });

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(gameDataState.troopsData.troops).toHaveProperty('Replacement');
  });

  test('bundle loads are single-flight', async () => {
    let resolveFetch: ((value: Response) => void) | undefined;
    const fetchMock = jest.fn(
      () =>
        new Promise<Response>((resolve) => {
          resolveFetch = resolve;
        }),
    );
    const { service } = createService({
      platform: 'web',
      fetchImplementation: fetchMock as unknown as typeof fetch,
    });

    const first = service.loadGameData({ languageCode: 'en' });
    const second = service.loadGameData({ languageCode: 'en' });
    expect(fetchMock).toHaveBeenCalledTimes(1);
    resolveFetch?.(response(200, JSON.stringify({ troops: [] })));
    await Promise.all([first, second]);
  });

  test('translation loads are single-flight per Clashy locale', async () => {
    let resolveFetch: ((value: Response) => void) | undefined;
    const fetchMock = jest.fn(
      () =>
        new Promise<Response>((resolve) => {
          resolveFetch = resolve;
        }),
    );
    const { service } = createService({
      platform: 'web',
      fetchImplementation: fetchMock as unknown as typeof fetch,
    });

    const first = service.loadTranslationsForLocale({ languageCode: 'de' });
    const second = service.loadTranslationsForLocale({ languageCode: 'de' });
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(fetchCalls(fetchMock)[0]?.[0]).toBe(TRANSLATIONS_URL);
    resolveFetch?.(response(200, JSON.stringify({ TID: { DE: 'Übersetzung' } })));
    await Promise.all([first, second]);
    expect(gameDataState.translationsData.TID).toBe('Übersetzung');
  });

  test('preferred locale uses stored subtags, then system locale, then English', async () => {
    const preferences = new MemoryPreferences();
    preferences.values.set(GAME_DATA_PREFERENCE_KEYS.languageCode, 'pt');
    preferences.values.set(GAME_DATA_PREFERENCE_KEYS.countryCode, 'BR');
    preferences.values.set(GAME_DATA_PREFERENCE_KEYS.scriptCode, 'Latn');
    const { service } = createService({
      preferences,
      systemLocales: () => [{ languageCode: 'de' }],
    });
    expect(await service.resolvePreferredLocale()).toEqual({
      languageCode: 'pt',
      countryCode: 'BR',
      scriptCode: 'Latn',
    });

    preferences.values.clear();
    expect(await service.resolvePreferredLocale()).toEqual({ languageCode: 'de' });
    const fallback = createService().service;
    expect(await fallback.resolvePreferredLocale()).toEqual({ languageCode: 'en' });
  });
});
