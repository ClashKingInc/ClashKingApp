import { createHash } from 'node:crypto';
import { GameDataService } from './game-data-service';
import { gameDataState, resetGameDataStateForTesting } from './game-data-state';
import { ASSET_MANIFEST_URL } from '../assets/asset-manifest';
import { FileUpdateIndex } from '../assets/file-update-index';

jest.mock('expo-crypto', () => ({
  CryptoDigestAlgorithm: { SHA256: 'sha256' },
  digestStringAsync: async (_: string, text: string) => jest.requireActual<typeof import('node:crypto')>('node:crypto').createHash('sha256').update(text).digest('hex'),
}));
class MemoryStore {
  readonly values = new Map<string, string>();
  async read(key: string) { return this.values.get(key) ?? null; }
  async write(key: string, value: string) { this.values.set(key, value); }
  getString = this.read;
  setString = this.write;
}
const sha = (text: string) => createHash('sha256').update(text).digest('hex');
const response = (status: number, body = '', headers: Record<string, string> = {}) => ({
  status, text: async () => body, headers: { get: (key: string) => headers[key.toLowerCase()] ?? null },
}) as Response;
function setup() {
  let now = new Date('2026-09-05T00:00:00Z');
  const files = new MemoryStore();
  const preferences = new MemoryStore();
  const sections: Record<string, string> = {
    troops: JSON.stringify({ items: [{ name: 'Barbarian' }] }), spells: JSON.stringify({ items: [] }),
  };
  const fetchMock = jest.fn(async (url: string, _options?: RequestInit) => {
    if (url === ASSET_MANIFEST_URL) return response(200, JSON.stringify({ version: 2, assets: {},
      data: Object.entries(sections).map(([name, body]) => ({ path: 'static_data/' + name + '.json', sha: sha(body) })),
    }), { 'last-modified': 'Sat, 05 Sep 2026 00:00:00 GMT' });
    const name = url.split('/').pop()!.replace('.json', '');
    if (url.includes('/translations/')) return response(200, JSON.stringify({ TID: name }));
    return response(200, sections[name]!, { etag: '"' + sha(sections[name]!) + '"' });
  });
  const options = { platform: 'native' as const, files, preferences,
    fetchImplementation: fetchMock as unknown as typeof fetch, now: () => now };
  return { service: new GameDataService(options), files, preferences, sections, fetchMock, options,
    advance: () => { now = new Date(now.getTime() + 60_000); } };
}
beforeEach(resetGameDataStateForTesting);

test('restart reconciles JSON saved before an interrupted local-index commit', async () => {
  const s = setup();
  const index = new FileUpdateIndex(s.preferences);
  const options = { ...s.options, fileIndex: index };
  const service = new GameDataService(options);
  await service.loadFreshGameData({ languageCode: 'en' });
  s.sections.troops = JSON.stringify({ items: [{ name: 'Archer' }] });
  s.advance();
  const commit = jest.spyOn(index, 'commit').mockRejectedValue(new Error('app interrupted'));
  await service.refreshStaticDataIfChanged();
  const url = 'https://assets.clashk.ing/static_data/troops.json';
  expect((await index.get(url))?.pendingSha).toBe(sha(s.sections.troops!));
  commit.mockRestore();
  s.fetchMock.mockClear();
  resetGameDataStateForTesting();
  await new GameDataService(options).loadFreshGameData({ languageCode: 'en' });
  expect(await index.get(url)).toMatchObject({ sha: sha(s.sections.troops!), pendingSha: null });
  expect(s.fetchMock).not.toHaveBeenCalled();
});

test('a saved new manifest does not mark failed JSON downloads complete, including after restart', async () => {
  const s = setup();
  const original = s.fetchMock.getMockImplementation()!;
  let translated = JSON.stringify({ TID: 'old French' });
  let failing = false;
  s.fetchMock.mockImplementation(async (url, options) => {
    if (url === ASSET_MANIFEST_URL) {
      const result = await original(url, options);
      const manifest = JSON.parse(await result.text());
      manifest.data.push({ path: 'translations/FR.json', sha: sha(translated) });
      return response(200, JSON.stringify(manifest));
    }
    if (failing) throw new Error('download interrupted');
    if (url.endsWith('/translations/FR.json')) return response(200, translated);
    return original(url, options);
  });
  await s.service.loadFreshGameData({ languageCode: 'fr' });
  const record = (file: string) => JSON.parse(s.files.values.get(file + '.' + s.preferences.values.get(file + '.slot'))!);
  const oldTroopsSha = record('static_data_troops.json').sha;
  const oldFrenchSha = record('translations_FR.json').sha;
  s.sections.troops = JSON.stringify({ items: [{ name: 'Archer' }] });
  translated = JSON.stringify({ TID: 'new French' });
  failing = true;
  s.advance();
  await s.service.refreshGameDataIfChanged({ languageCode: 'fr' });
  expect(JSON.parse(record('asset_manifest.json').body).data).toContainEqual({
    path: 'static_data/troops.json', sha: sha(s.sections.troops!),
  });
  expect(record('static_data_troops.json').sha).toBe(oldTroopsSha);
  expect(record('translations_FR.json').sha).toBe(oldFrenchSha);

  // Reopen immediately: even a still-fresh manifest must retry stale local files.
  failing = false;
  s.fetchMock.mockClear();
  resetGameDataStateForTesting();
  await new GameDataService(s.options).loadFreshGameData({ languageCode: 'fr' });
  expect(record('static_data_troops.json').sha).toBe(sha(s.sections.troops!));
  expect(record('translations_FR.json').sha).toBe(sha(translated));
  expect(gameDataState.troopsData.troops).toHaveProperty('Archer');
  expect(gameDataState.translationsData.TID).toBe('new French');
  expect(s.fetchMock.mock.calls.map(([url]) => url).sort()).toEqual([
    'https://assets.clashk.ing/static_data/troops.json',
    'https://assets.clashk.ing/translations/FR.json',
  ]);
});

test('failed pending-update persistence retains the previous manifest for retry', async () => {
  const s = setup();
  const original = s.fetchMock.getMockImplementation()!;
  let imageSha = 'a'.repeat(64);
  s.fetchMock.mockImplementation(async (url, options) => {
    const result = await original(url, options);
    if (url !== ASSET_MANIFEST_URL) return result;
    const manifest = JSON.parse(await result.text());
    manifest.assets = { icons: [{ path: 'icons/example.webp', sha: imageSha, animated: false }] };
    return response(200, JSON.stringify(manifest));
  });
  const fileIndex = new FileUpdateIndex(s.preferences);
  const notice = jest.spyOn(fileIndex, 'notice');
  const options = { ...s.options, fileIndex };
  const service = new GameDataService(options);
  await service.loadFreshGameData({ languageCode: 'en' });
  const before = s.preferences.values.get('asset_manifest.json.slot');
  imageSha = 'b'.repeat(64);
  notice.mockRejectedValueOnce(new Error('disk unavailable'));
  s.advance();
  await service.refreshStaticDataIfChanged();
  expect(s.preferences.values.get('asset_manifest.json.slot')).toBe(before);
  await new GameDataService(options).loadFreshGameData({ languageCode: 'en' });
  expect(notice).toHaveBeenLastCalledWith(expect.any(Map));
  expect(s.preferences.values.get('asset_manifest.json.slot')).not.toBe(before);
});
test('split files persist and a later offline launch reuses them', async () => {
  const s = setup();
  await s.service.loadGameData({ languageCode: 'en' });
  expect(s.fetchMock.mock.calls.map(([url]) => url)).toEqual([
    ASSET_MANIFEST_URL, 'https://assets.clashk.ing/static_data/troops.json', 'https://assets.clashk.ing/static_data/spells.json',
  ]);
  expect(gameDataState.troopsData.troops).toHaveProperty('Barbarian');
  s.fetchMock.mockRejectedValue(new Error('offline'));
  resetGameDataStateForTesting();
  await new GameDataService(s.options).loadGameData({ languageCode: 'en' });
  expect(s.fetchMock).toHaveBeenCalledTimes(3);
  expect(gameDataState.troopsData.troops).toHaveProperty('Barbarian');
});
test('manifest Last-Modified produces one conditional request and no section downloads on 304', async () => {
  const s = setup();
  await s.service.loadGameData({ languageCode: 'en' });
  s.advance();
  s.fetchMock.mockResolvedValue(response(304));
  await s.service.refreshStaticDataIfChanged();
  expect(s.fetchMock).toHaveBeenCalledTimes(4);
  expect(s.fetchMock.mock.calls[3]?.[1]?.headers).toMatchObject({ 'If-Modified-Since': 'Sat, 05 Sep 2026 00:00:00 GMT' });
  expect(gameDataState.troopsData.troops).toHaveProperty('Barbarian');
});

test('malformed manifest cannot overwrite the saved working manifest', async () => {
  const s = setup();
  await s.service.loadGameData({ languageCode: 'en' });
  const before = s.preferences.values.get('asset_manifest.json.slot');
  s.advance();
  s.fetchMock.mockResolvedValue(response(200, '{"assets":[],"data":[]}'));
  await s.service.refreshStaticDataIfChanged();
  expect(s.preferences.values.get('asset_manifest.json.slot')).toBe(before);
  expect(gameDataState.troopsData.troops).toHaveProperty('Barbarian');
});
test('only a changed section downloads and replaces its old body', async () => {
  const s = setup();
  await s.service.loadGameData({ languageCode: 'en' });
  s.sections.troops = JSON.stringify({ items: [{ name: 'Archer' }] });
  s.advance();
  await s.service.refreshStaticDataIfChanged();
  expect(s.fetchMock.mock.calls.slice(3).map(([url]) => url)).toEqual([
    ASSET_MANIFEST_URL, 'https://assets.clashk.ing/static_data/troops.json',
  ]);
  expect(gameDataState.troopsData.troops).toHaveProperty('Archer');
});
test.each(['offline', 'invalid-json', 'wrong-hash'])('keeps the last good body on %s', async (failure) => {
  const s = setup();
  await s.service.loadGameData({ languageCode: 'en' });
  const original = s.fetchMock.getMockImplementation()!;
  s.sections.troops = JSON.stringify({ items: [{ name: 'New' }] });
  s.fetchMock.mockImplementation(async (url, options) => {
    if (url === ASSET_MANIFEST_URL) return original(url, options);
    if (failure === 'offline') throw new Error('offline');
    return response(200, failure === 'invalid-json' ? '{' : '{"items":[]}');
  });
  s.advance();
  await s.service.refreshStaticDataIfChanged();
  expect(gameDataState.troopsData.troops).toHaveProperty('Barbarian');
  const slot = s.preferences.values.get('static_data_troops.json.slot');
  expect(JSON.parse(s.files.values.get('static_data_troops.json.' + slot)!).body).toContain('Barbarian');
});
test('only selected languages download and switching back reuses cached files', async () => {
  const s = setup();
  await s.service.loadTranslationsForLocale({ languageCode: 'fr' });
  await s.service.loadTranslationsForLocale({ languageCode: 'de' });
  await s.service.loadTranslationsForLocale({ languageCode: 'fr' });
  expect(s.fetchMock.mock.calls.map(([url]) => url)).toEqual([
    'https://assets.clashk.ing/translations/FR.json', 'https://assets.clashk.ing/translations/DE.json',
  ]);
  expect(gameDataState.translationsData.TID).toBe('FR');
});
test('late translation response cannot undo a switch to English', async () => {
  const s = setup();
  let finish!: (value: Response) => void;
  s.fetchMock.mockImplementationOnce(() => new Promise((resolve) => { finish = resolve; }));
  const pending = s.service.loadTranslationsForLocale({ languageCode: 'fr' });
  await new Promise<void>((resolve) => setImmediate(resolve));
  await s.service.loadTranslationsForLocale({ languageCode: 'en' });
  finish(response(200, '{"TID":"FR"}'));
  await pending;
  expect(gameDataState.translationLocale).toBe('EN');
});
test('concurrent loads share requests, failed cache writes retain the old pointer', async () => {
  const s = setup();
  await Promise.all([s.service.loadGameData({ languageCode: 'en' }), s.service.loadGameData({ languageCode: 'en' })]);
  expect(s.fetchMock).toHaveBeenCalledTimes(3);
  const key = 'static_data_troops.json.slot';
  const before = s.preferences.values.get(key);
  jest.spyOn(s.files, 'write').mockRejectedValue(new Error('disk full'));
  s.sections.troops = JSON.stringify({ items: [{ name: 'New' }] });
  s.advance();
  await s.service.refreshStaticDataIfChanged();
  expect(s.preferences.values.get(key)).toBe(before);
  expect(gameDataState.troopsData.troops).toHaveProperty('New');
});
