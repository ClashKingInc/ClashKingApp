import { ApiClient } from '@/core/api/client';
import type { StringStorage } from '@/core/storage/storage';
import { PlayerCardPreferencesService } from './player-card-preferences';
import { PlayerService } from './player-service';
import { WarStatsFilter } from '../models/war-stats-filter';

class MemoryStorage implements StringStorage {
  readonly values = new Map<string, string>();
  async getString(key: string) {
    return this.values.get(key) ?? null;
  }
  async setString(key: string, value: string) {
    this.values.set(key, value);
  }
  async remove(key: string) {
    this.values.delete(key);
  }
}
function reply(body: unknown, status = 200): Response {
  return {
    status,
    url: '',
    headers: { get: () => null },
    text: async () => JSON.stringify(body),
  } as unknown as Response;
}
function setup(routes: Record<string, unknown | (() => Promise<Response>)>) {
  const calls = new Map<string, number>();
  const fetchMock = jest.fn(async (input: RequestInfo | URL, _init?: RequestInit) => {
    const url = String(input),
      path = new URL(url).pathname + new URL(url).search;
    calls.set(path, (calls.get(path) ?? 0) + 1);
    const route = routes[path];
    if (typeof route === 'function') return route();
    return reply(route ?? {}, route === undefined ? 404 : 200);
  });
  const api = new ApiClient({
    baseUrl: 'https://api.test',
    proxyUrl: 'https://proxy.test',
    environment: 'staging',
    tokenProvider: { getAccessToken: async () => 'token' },
    fetchImplementation: fetchMock as typeof fetch,
  });
  return { api, calls, fetchMock };
}
test('loads canonical official profiles concurrently, coalesces duplicates, and stores clan keys', async () => {
  let resolveResponse: ((value: Response) => void) | undefined;
  const pending = new Promise<Response>((resolve) => {
    resolveResponse = resolve;
  });
  const { api, calls } = setup({ '/players/%23P1': () => pending });
  const storage = new MemoryStorage(),
    service = new PlayerService(api, storage);
  const first = service.loadOfficialPlayerData(['p1', '#P1'], { throwOnError: true }),
    second = service.getPlayerAndClanData('#P1');
  resolveResponse?.(
    reply({ tag: '#P1', name: 'One', clan: { tag: '#CLAN', name: 'Clan', badgeUrls: {} } }),
  );
  await Promise.all([first, second]);
  expect(calls.get('/players/%23P1')).toBe(1);
  expect(service.profiles[0]?.name).toBe('One');
  expect(storage.values.get('player_#P1_clan_tag')).toBe('#CLAN');
  expect(await service.loadCachedClanTag('p1')).toBe('#CLAN');
  expect(service.isLoading).toBe(false);
});
test('rejects an official response whose tag does not match the request', async () => {
  const reportError = jest.fn();
  const { api } = setup({ '/players/%23P1': { tag: '#OTHER', name: 'Other' } }),
    service = new PlayerService(api, undefined, '', reportError);
  await expect(service.loadOfficialPlayerData(['#P1'], { throwOnError: true })).rejects.toThrow(
    'mismatched',
  );
  expect(service.profiles).toHaveLength(0);
  expect(reportError).toHaveBeenCalledWith('player.load_official', expect.any(Error));
});
test('merges battlelogs when one source is unavailable and caches by canonical tag', async () => {
  const { api, calls } = setup({
      '/players/%23P1/battlelog': {
        items: [
          {
            attack: true,
            battleType: 'homeVillage',
            opponentPlayerTag: '#O',
            battleTimestamp: '20260816T120000.000Z',
            armyShareCode: 'u8x5',
          },
        ],
      },
    }),
    service = new PlayerService(api);
  const first = await service.loadPlayerBattlelog('p1'),
    second = await service.loadPlayerBattlelog('#P1');
  expect(first).toBe(second);
  expect(first.officialAvailable).toBe(true);
  expect(first.historyAvailable).toBe(false);
  expect(calls.get('/players/%23P1/battlelog')).toBe(1);
});
test('coalesces CWL and ranked loads and caches global league tiers', async () => {
  const routes = {
    '/player/%23P1/cwl/history?limit=100': { items: [] },
    '/players/%23P1': {
      tag: '#P1',
      name: 'One',
      leagueTier: { id: 30, name: 'Dragon League 30' },
      currentLeagueGroupTag: '#G',
      currentLeagueSeasonId: 123,
    },
    '/players/%23P1/leaguehistory': {
      items: [{ leagueSeasonId: 123, leagueTierId: 30, maxBattles: 14 }],
    },
    '/leaguetiers': { items: [{ id: 30, name: 'Dragon League 30' }] },
    '/leaguegroup/%23G/123?playerTag=%23P1': {
      members: [
        { playerTag: '#P1', playerName: 'One', leagueTrophies: 36 },
        { playerTag: '#P2', leagueTrophies: 50 },
      ],
      attackLogs: [],
      defenseLogs: [],
    },
  };
  const { api, calls } = setup(routes),
    service = new PlayerService(api);
  const rankedChanged = jest.fn();
  service.subscribe(rankedChanged);
  const cwl1 = service.loadPlayerCwlHistory('#P1'),
    cwl2 = service.loadPlayerCwlHistory('p1');
  expect(cwl2).toBe(cwl1);
  await cwl1;
  const [ranked1, ranked2] = await Promise.all([
    service.loadRankedLeagueData('#P1', false, true),
    service.loadRankedLeagueData('p1'),
  ]);
  expect(ranked1).toBe(ranked2);
  expect(ranked1.currentRank).toBe(2);
  expect(ranked1.currentMaxBattles).toBe(14);
  expect(calls.get('/players/%23P1')).toBe(1);
  expect(calls.get('/leaguetiers')).toBe(1);
  expect(rankedChanged).toHaveBeenCalledTimes(1);
});

test('builds the existing war-stat model from deployed per-player history', async () => {
  const path =
    '/player/%23P1/war/stats?limit=25&type=random&time%5Bafter%5D=2026-08-01T00%3A00%3A00.000Z';
  const { api, calls } = setup({
    [path]: {
      items: [
        {
          type: 'random',
          attacksPerMember: 2,
          endTime: '20260820T120000.000Z',
          player: { tag: '#P1', name: 'One', townhallLevel: 18, mapPosition: 1 },
          clan: { tag: '#C' },
          opponent: { tag: '#O' },
          attacks: [
            {
              stars: 3,
              destructionPercentage: 100,
              order: 1,
              fresh: true,
              player: { tag: '#D', townhallLevel: 18, mapPosition: 1 },
            },
          ],
          defenses: [],
        },
      ],
    },
  });
  const service = new PlayerService(api);
  const stats = await service.loadPlayerWarStatsWithFilter(
    '#P1',
    new WarStatsFilter({
      limit: 25,
      warType: 'random',
      startDate: new Date('2026-08-01T00:00:00Z'),
    }),
  );
  expect(calls.get(path)).toBe(1);
  expect(stats?.getSpecificStats('random')).toMatchObject({
    warsCounts: 1,
    totalAttacks: 1,
    missedAttacks: 1,
  });
  expect(stats?.getSpecificStats('random').starsCount['3']).toBe(1);
});
test('search uses exact filter names and tracking headers', async () => {
  const { api, fetchMock } = setup({
      '/player/search?query=Hero&limit=20&clanTags=%23C&leagueIds=1&townhallLevels=17': {
        items: [{ tag: '#P' }],
      },
    }),
    service = new PlayerService(api);
  const result = await service.searchPlayers(' Hero ', {
    clanTags: ['#C'],
    leagueIds: [1],
    townHallLevels: [17],
    extraHeaders: { 'x-ck-user-id': '123' },
  });
  expect(result[0]?.tag).toBe('#P');
  expect(fetchMock.mock.calls[0]?.[1]).toMatchObject({
    headers: expect.objectContaining({ 'x-ck-user-id': '123' }),
  });
});
test('search returns empty for HTTP/shape misses but propagates transport failures', async () => {
  const notFound = setup({}),
    invalidShape = setup({ '/player/search?query=Hero&limit=20': { result: [] } });
  await expect(new PlayerService(notFound.api).searchPlayers('Hero')).resolves.toEqual([]);
  await expect(new PlayerService(invalidShape.api).searchPlayers('Hero')).resolves.toEqual([]);

  const transportApi = new ApiClient({
    baseUrl: 'https://api.test',
    proxyUrl: 'https://proxy.test',
    environment: 'staging',
    fetchImplementation: jest.fn(async () => {
      throw new TypeError('offline');
    }) as typeof fetch,
  });
  await expect(new PlayerService(transportApi).searchPlayers('Hero')).rejects.toThrow('offline');
});
test('ranked history HTTP misses are optional but transport failures propagate', async () => {
  const routes = {
    '/players/%23P1': { tag: '#P1', name: 'One' },
    '/leaguetiers': { items: [] },
  };
  const httpMiss = setup(routes);
  await expect(new PlayerService(httpMiss.api).loadRankedLeagueData('#P1')).resolves.toMatchObject({
    history: [],
  });

  const transport = setup({
    ...routes,
    '/players/%23P1/leaguehistory': async () => {
      throw new TypeError('ranked offline');
    },
  });
  await expect(new PlayerService(transport.api).loadRankedLeagueData('#P1')).rejects.toThrow(
    'ranked offline',
  );
});
test('ranked warmup canonicalizes duplicates and isolates per-account failures', async () => {
  const { api, calls } = setup({
      '/players/%23P1': { tag: '#P1', name: 'One' },
      '/players/%23P1/leaguehistory': { items: [] },
      '/leaguetiers': { items: [] },
      '/players/%23BAD': async () => {
        throw new TypeError('offline');
      },
    }),
    service = new PlayerService(api);

  await expect(service.prefetchRankedLeagueData(['p1', '#P1', '#BAD'])).resolves.toBeUndefined();
  expect(calls.get('/players/%23P1')).toBe(1);
  expect(calls.get('/players/%23BAD')).toBe(1);
  await expect(service.loadRankedLeagueData('#P1')).resolves.toMatchObject({ playerName: 'One' });
  expect(calls.get('/players/%23P1')).toBe(1);
});
test('clearing ranked data prevents an older in-flight response from repopulating the cache', async () => {
  let resolveOld: ((value: Response) => void) | undefined;
  const oldResponse = new Promise<Response>((resolve) => {
    resolveOld = resolve;
  });
  let profileCalls = 0;
  const { api, calls } = setup({
      '/players/%23P1': async () => {
        profileCalls += 1;
        return profileCalls === 1
          ? oldResponse
          : reply({ tag: '#P1', name: 'New profile', trophies: 2 });
      },
      '/players/%23P1/leaguehistory': { items: [] },
      '/leaguetiers': { items: [] },
    }),
    service = new PlayerService(api);

  const older = service.loadRankedLeagueData('#P1');
  service.clearRankedLeagueCache();
  const newer = await service.loadRankedLeagueData('#P1');
  expect(newer.playerName).toBe('New profile');

  resolveOld?.(reply({ tag: '#P1', name: 'Old profile', trophies: 1 }));
  expect((await older).playerName).toBe('Old profile');
  expect((await service.loadRankedLeagueData('#P1')).playerName).toBe('New profile');
  expect(calls.get('/players/%23P1')).toBe(2);
});
test('role text accepts the existing localization translator contract', () => {
  const { api } = setup({}),
    service = new PlayerService(api);
  expect(service.getRoleText('coLeader', (key) => `translated:${key}`)).toBe(
    'translated:clanRoleCoLeader',
  );
  expect(service.getRoleText('leader')).toBe('Leader');
  expect(service.getRoleText('unknown')).toBe('No clan');
});
test('card preferences normalize tags, ignore malformed JSON, persist non-defaults, and clear memory', async () => {
  const storage = new MemoryStorage();
  storage.values.set('player_card_options_v1', 'invalid');
  const service = new PlayerCardPreferencesService(storage);
  await service.load();
  expect(service.loaded).toBe(true);
  await service.setShowRankedOnHome('#abc', false);
  expect(service.isRankedShownOnHome(' ABC ')).toBe(false);
  expect(storage.values.get('player_card_options_v1')).toContain('ABC');
  service.clear();
  expect(service.isRankedShownOnHome('#ABC')).toBe(true);
});
