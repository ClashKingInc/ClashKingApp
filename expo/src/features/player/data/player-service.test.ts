import { createContractTestApi } from '@/core/api/contract-api.testing';
import { ApiResponseError, ResponseDecodeError, TransportError } from '@clashking/api-client';
import type { StringStorage } from '@/core/storage/storage';
import { PlayerCardPreferencesService } from './player-card-preferences';
import { PlayerService } from './player-service';
import { WarStatsFilter } from '../models/war-stats-filter';
import { currentLegendDay } from '../models/player-legend';

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
  return new Response(JSON.stringify(body), { status });
}
function officialPlayer(overrides: Record<string, unknown> = {}) {
  const clan = overrides.clan;
  return {
    tag: '#P1',
    name: 'One',
    townHallLevel: 18,
    expLevel: 200,
    trophies: 5000,
    bestTrophies: 5100,
    warStars: 1000,
    attackWins: 100,
    defenseWins: 20,
    achievements: [],
    heroes: [],
    troops: [],
    spells: [],
    ...overrides,
    ...(typeof clan === 'object' && clan !== null
      ? {
          clan: {
            clanLevel: 1,
            badgeUrls: { large: 'https://assets.example/clan.png' },
            ...clan,
          },
        }
      : {}),
  };
}
function rankedMember(playerTag: string, playerName: string, leagueTrophies: number) {
  return {
    playerTag,
    playerName,
    clanTag: '#CLAN',
    clanName: 'Clan',
    leagueTrophies,
    attackWinCount: 1,
    attackLoseCount: 0,
    defenseWinCount: 0,
    defenseLoseCount: 1,
  };
}
function rankedBattlelog(overrides: Record<string, unknown> = {}) {
  return {
    tag: '#P1',
    seasonId: '123',
    leagueGroupId: '#GROUP',
    league: { id: 1, name: 'Ranked League' },
    registeredAttacks: 0,
    registeredDefenses: 0,
    maxBattles: 0,
    attackTrophies: 0,
    defenseTrophies: 0,
    trophies: 0,
    attacks: [],
    defenses: [],
    ...overrides,
  };
}
function legendBattlelog(overrides: Record<string, unknown> = {}) {
  return {
    tag: '#P1',
    day: '2026-08-01',
    attackTrophies: 0,
    defenseTrophies: 0,
    trophies: 0,
    attacks: [],
    defenses: [],
    ...overrides,
  };
}
function warStatsItem(overrides: Record<string, unknown> = {}) {
  const clan = {
    tag: '#C',
    name: 'Clan',
    badgeUrls: { small: '', medium: '', large: '' },
    clanLevel: 1,
    attacks: 1,
    stars: 3,
    destructionPercentage: 100,
  };
  return {
    teamSize: 15,
    attacksPerMember: 2,
    preparationStartTime: '20260819T120000.000Z',
    endTime: '20260820T120000.000Z',
    clan,
    opponent: { ...clan, tag: '#O', name: 'Opponent' },
    type: 'random',
    player: { tag: '#P1', name: 'One', townhallLevel: 18, mapPosition: 1 },
    attacks: [],
    defenses: [],
    ...overrides,
  };
}
function setup(routes: Record<string, unknown | (() => Promise<Response>)>) {
  const calls = new Map<string, number>();
  const fetchMock = jest.fn(async (input: RequestInfo | URL, _init?: RequestInit) => {
    const request = input as Request;
    const url = request.url,
      path = new URL(url).pathname + new URL(url).search;
    calls.set(path, (calls.get(path) ?? 0) + 1);
    const route = routes[path];
    if (typeof route === 'function') return route();
    return reply(route ?? {}, route === undefined ? 404 : 200);
  });
  const api = createContractTestApi({
    baseUrl: 'https://api.test',
    proxyUrl: 'https://proxy.test',
    environment: 'development',
    tokenProvider: { getAccessToken: async () => 'token' },
    fetchImplementation: fetchMock as typeof fetch,
  });
  return { api, calls, fetchMock };
}
test('loads an official player whose achievement completion text is explicitly null', async () => {
  const { api } = setup({
    '/proxy/v1/players/%23P1': officialPlayer({
      achievements: [
        {
          name: 'Bigger & Better',
          stars: 3,
          value: 18,
          target: 15,
          info: 'Upgrade your Town Hall',
          completionInfo: null,
          village: 'home',
        },
      ],
    }),
  });
  const service = new PlayerService(api);
  await expect(service.loadOfficialPlayerData(['#P1'], { throwOnError: true })).resolves.toEqual(
    {},
  );
  expect(service.profiles[0]?.name).toBe('One');
});

test('loads canonical official profiles concurrently, coalesces duplicates, and stores clan keys', async () => {
  let resolveResponse: ((value: Response) => void) | undefined;
  const pending = new Promise<Response>((resolve) => {
    resolveResponse = resolve;
  });
  const { api, calls } = setup({ '/proxy/v1/players/%23P1': () => pending });
  const storage = new MemoryStorage(),
    service = new PlayerService(api, storage);
  const first = service.loadOfficialPlayerData(['p1', '#P1'], { throwOnError: true }),
    second = service.getPlayerAndClanData('#P1');
  resolveResponse?.(reply(officialPlayer({ clan: { tag: '#CLAN', name: 'Clan' } })));
  await Promise.all([first, second]);
  expect(calls.get('/proxy/v1/players/%23P1')).toBe(1);
  expect(service.profiles[0]?.name).toBe('One');
  expect(storage.values.get('player_#P1_clan_tag')).toBe('#CLAN');
  expect(await service.loadCachedClanTag('p1')).toBe('#CLAN');
  expect(service.isLoading).toBe(false);
});
test('rejects an official response whose tag does not match the request', async () => {
  const reportError = jest.fn();
  const { api } = setup({
      '/proxy/v1/players/%23P1': officialPlayer({ tag: '#OTHER', name: 'Other' }),
    }),
    service = new PlayerService(api, undefined, '', reportError);
  await expect(service.loadOfficialPlayerData(['#P1'], { throwOnError: true })).rejects.toThrow(
    'mismatched',
  );
  expect(service.profiles).toHaveLength(0);
  expect(reportError).toHaveBeenCalledWith('player.load_official', expect.any(Error));
});
test('merges battlelogs when one source is unavailable and caches by canonical tag', async () => {
  const { api, calls } = setup({
      '/proxy/v1/players/%23P1/battlelog': {
        items: [
          {
            attack: true,
            battleType: 'homeVillage',
            opponentPlayerTag: '#O',
            opponentName: 'Opponent',
            opponentTownHallLevel: 17,
            stars: 3,
            destructionPercentage: 100,
            lootedResources: [],
            battleTimestamp: '20260816T120000.000Z',
            armyShareCode: 'u8x5',
            battleTime: 30,
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
  expect(calls.get('/proxy/v1/players/%23P1/battlelog')).toBe(1);
  expect(calls.get('/v2/player/%23P1/battlelog/history')).toBe(1);
});
test('coalesces CWL and ranked loads and caches global league tiers', async () => {
  const routes = {
    '/v2/player/%23P1/cwl/history?limit=100': { items: [] },
    '/proxy/v1/players/%23P1': officialPlayer({
      leagueTier: { id: 30, name: 'Dragon League 30' },
      currentLeagueGroupTag: '#G',
      currentLeagueSeasonId: 123,
    }),
    '/proxy/v1/players/%23P1/leaguehistory': {
      items: [
        {
          leagueSeasonId: 123,
          leagueTrophies: 36,
          leagueTierId: 30,
          placement: 2,
          attackWins: 1,
          attackLosses: 0,
          attackStars: 3,
          defenseWins: 0,
          defenseLosses: 1,
          defenseStars: 2,
          maxBattles: 14,
        },
      ],
    },
    '/proxy/v1/leaguetiers': { items: [{ id: 30, name: 'Dragon League 30' }] },
    '/proxy/v1/leaguegroup/%23G/123?playerTag=%23P1': {
      members: [rankedMember('#P1', 'One', 36), rankedMember('#P2', 'Two', 50)],
      attackLogs: [],
      defenseLogs: [],
    },
    '/v2/player/%23P1/ranked/123/battlelog': {
      tag: '#P1',
      seasonId: '123',
      leagueGroupId: '#G',
      league: { id: 30, name: 'Dragon League 30' },
      registeredAttacks: 2,
      registeredDefenses: 2,
      maxBattles: 14,
      attackTrophies: 40,
      defenseTrophies: 38,
      trophies: 78,
      attacks: [
        {
          time: '2026-08-25T12:00:00Z',
          duration: 120,
          townHallLevel: 18,
          opponent: { tag: '#OPPONENT', name: 'Opponent', townHallLevel: 18 },
          stars: 3,
          destructionPercentage: 100,
          shareCode: null,
          familyId: null,
          trophies: 40,
        },
      ],
      defenses: [{ trophies: 38, automatic: true }],
    },
  };
  const { api, calls, fetchMock } = setup(routes),
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
  expect(ranked1.currentBattlelog).toMatchObject({
    leagueGroupId: '#G',
    attacksComplete: false,
    missingRealAttacks: 1,
    automaticDefensesDerived: true,
  });
  expect(ranked1.currentBattlelog?.attacks[0]).toMatchObject({
    opponentPlayerTag: '#OPPONENT',
    stars: 3,
  });
  expect(ranked1.currentBattlelog?.defenses[0]).toMatchObject({
    automatic: true,
    stars: null,
    trophies: 38,
  });
  expect(calls.get('/proxy/v1/players/%23P1')).toBe(1);
  expect(calls.get('/proxy/v1/leaguetiers')).toBe(1);
  expect(calls.get('/v2/player/%23P1/ranked/123/battlelog')).toBe(1);
  const rankedRequest = fetchMock.mock.calls
    .map(([input]) => input as Request)
    .find((request) => request.url.includes('/ranked/123/battlelog'));
  expect(rankedRequest?.method).toBe('GET');
  expect(rankedRequest?.body).toBeNull();
  expect(rankedChanged).toHaveBeenCalledTimes(1);
});

test('builds the existing war-stat model from deployed per-player history', async () => {
  const path =
    '/v2/player/%23P1/war/stats?type=random&limit=25&time%5Bafter%5D=2026-08-01T00%3A00%3A00.000Z';
  const { api, calls } = setup({
    [path]: {
      items: [
        warStatsItem({
          attacks: [
            {
              stars: 3,
              destructionPercentage: 100,
              order: 1,
              duration: 30,
              fresh: true,
              player: { tag: '#D', name: 'Defender', townhallLevel: 18, mapPosition: 1 },
            },
          ],
        }),
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
      '/v2/player/search?query=Hero&limit=20&clanTags=%23C&leagueIds=1&townhallLevels=17': {
        items: [{ tag: '#P', name: 'Player', townHallLevel: 17 }],
        pagination: { limit: 20, hasMore: false, nextCursor: null },
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
  expect((fetchMock.mock.calls[0]?.[0] as Request).headers.get('x-ck-user-id')).toBe('123');
});
test('search returns empty for HTTP/shape misses but propagates transport failures', async () => {
  const notFound = setup({}),
    invalidShape = setup({ '/v2/player/search?query=Hero&limit=20': { result: [] } });
  await expect(new PlayerService(notFound.api).searchPlayers('Hero')).resolves.toEqual([]);
  await expect(new PlayerService(invalidShape.api).searchPlayers('Hero')).resolves.toEqual([]);

  const transportApi = createContractTestApi({
    baseUrl: 'https://api.test',
    proxyUrl: 'https://proxy.test',
    environment: 'development',
    fetchImplementation: jest.fn(async () => {
      throw new TypeError('offline');
    }) as typeof fetch,
  });
  await expect(new PlayerService(transportApi).searchPlayers('Hero')).rejects.toBeInstanceOf(
    TransportError,
  );
});
test('ranked history HTTP misses are optional but transport failures propagate', async () => {
  const routes = {
    '/proxy/v1/players/%23P1': officialPlayer(),
    '/proxy/v1/leaguetiers': { items: [] },
  };
  const httpMiss = setup(routes);
  await expect(new PlayerService(httpMiss.api).loadRankedLeagueData('#P1')).resolves.toMatchObject({
    history: [],
  });

  const transport = setup({
    ...routes,
    '/proxy/v1/players/%23P1/leaguehistory': async () => {
      throw new TypeError('ranked offline');
    },
  });
  await expect(new PlayerService(transport.api).loadRankedLeagueData('#P1')).rejects.toBeInstanceOf(
    TransportError,
  );
});
test.each(['current', 'previous'] as const)(
  'ranked %s group transport failures propagate without caching an incomplete result',
  async (period) => {
    const { api } = setup({
      '/proxy/v1/players/%23P1': officialPlayer(
        period === 'current'
          ? { currentLeagueGroupTag: '#GROUP', currentLeagueSeasonId: 123 }
          : { previousLeagueGroupTag: '#GROUP', previousLeagueSeasonId: 123 },
      ),
      '/proxy/v1/leaguetiers': { items: [] },
      '/proxy/v1/players/%23P1/leaguehistory': { items: [] },
      '/proxy/v1/leaguegroup/%23GROUP/123?playerTag=%23P1': async () => {
        throw new TypeError('group offline');
      },
    });
    await expect(new PlayerService(api).loadRankedLeagueData('#P1')).rejects.toBeInstanceOf(
      TransportError,
    );
  },
);

test('ranked battlelog decode failures propagate and a later load retries', async () => {
  let battlelogCalls = 0;
  const { api, calls } = setup({
      '/proxy/v1/players/%23P1': officialPlayer({ currentLeagueSeasonId: 123 }),
      '/proxy/v1/leaguetiers': { items: [] },
      '/proxy/v1/players/%23P1/leaguehistory': { items: [] },
      '/v2/player/%23P1/ranked/123/battlelog': async () => {
        battlelogCalls += 1;
        return reply(battlelogCalls === 1 ? { tag: '#P1' } : rankedBattlelog());
      },
    }),
    service = new PlayerService(api);

  await expect(service.loadRankedLeagueData('#P1')).rejects.toBeInstanceOf(ResponseDecodeError);
  await expect(service.loadRankedLeagueData('#P1')).resolves.toMatchObject({
    currentBattlelog: { seasonId: '123' },
  });
  expect(calls.get('/v2/player/%23P1/ranked/123/battlelog')).toBe(2);
});

test('ranked battlelog upstream failures propagate and a later load retries', async () => {
  let battlelogCalls = 0;
  const { api, calls } = setup({
      '/proxy/v1/players/%23P1': officialPlayer({ currentLeagueSeasonId: 123 }),
      '/proxy/v1/leaguetiers': { items: [] },
      '/proxy/v1/players/%23P1/leaguehistory': { items: [] },
      '/v2/player/%23P1/ranked/123/battlelog': async () => {
        battlelogCalls += 1;
        return battlelogCalls === 1
          ? reply({ code: 'upstream_unavailable', message: 'down' }, 503)
          : reply(rankedBattlelog());
      },
    }),
    service = new PlayerService(api);

  await expect(service.loadRankedLeagueData('#P1')).rejects.toBeInstanceOf(ApiResponseError);
  await expect(service.loadRankedLeagueData('#P1')).resolves.toMatchObject({
    currentBattlelog: { seasonId: '123' },
  });
  expect(calls.get('/v2/player/%23P1/ranked/123/battlelog')).toBe(2);
});

test('loads and caches an empty canonical Legend day', async () => {
  const path = '/v2/player/%23P1/legend/2026-08-01/battlelog';
  const { api, calls, fetchMock } = setup({ [path]: legendBattlelog() });
  const service = new PlayerService(api);

  await expect(service.loadLegendBattlelog('p1', '2026-08-01')).resolves.toMatchObject({
    tag: '#P1',
    day: '2026-08-01',
    closed: true,
    attacks: [],
    defenses: [],
  });
  await expect(service.loadLegendBattlelog('#P1', '2026-08-01')).resolves.toBeTruthy();
  expect(calls.get(path)).toBe(1);
  const request = fetchMock.mock.calls
    .map(([input]) => input as Request)
    .find((item) => item.url.includes('/legend/2026-08-01/battlelog'));
  expect(request?.method).toBe('GET');
  expect(request?.body).toBeNull();
});

test('treats only a Legend-day 404 as optional absence', async () => {
  const path = '/v2/player/%23P1/legend/2026-08-01/battlelog';
  const { api, calls } = setup({});
  const service = new PlayerService(api);

  await expect(service.loadLegendBattlelog('#P1', '2026-08-01')).resolves.toBeNull();
  await expect(service.loadLegendBattlelog('#P1', '2026-08-01')).resolves.toBeNull();
  expect(calls.get(path)).toBe(1);
});

test('loads a separate Legend experience from current-day and completed-season contracts', async () => {
  const day = currentLegendDay();
  const { api, calls } = setup({
    '/proxy/v1/players/%23P1': officialPlayer({ trophies: 5600, bestTrophies: 5900 }),
    '/v2/player/%23P1/league/history': {
      items: [
        {
          mode: 'legend',
          season: '2026-08',
          league: { id: 1, name: 'Legend League' },
          trophies: 5800,
          attackWins: 200,
          defenseWins: 190,
          rank: 123,
        },
      ],
    },
    [`/v2/player/%23P1/legend/${day}/battlelog`]: legendBattlelog({ day }),
    '/v2/legends/ranks': {
      items: [{ tag: '#P1', name: 'One', trophies: 5600, globalRank: 42 }],
    },
    '/v2/legends/ranks/history': {
      items: [{ tag: '#P1', name: 'One', trophies: 5575, globalRank: 51 }],
    },
  });
  const service = new PlayerService(api);

  const first = service.loadLegendLeagueData('#P1');
  const second = service.loadLegendLeagueData('p1');
  await expect(first).resolves.toMatchObject({
    playerTag: '#P1',
    trophies: 5600,
    currentDay: { day },
    selectedDay: day,
    currentRank: { globalRank: 42 },
    historicalRank: { globalRank: 51 },
    history: [{ season: '2026-08', rank: 123 }],
  });
  await second;
  await service.loadLegendLeagueData('#P1');
  expect(calls.get('/v2/player/%23P1/league/history')).toBe(1);
  expect(calls.get(`/v2/player/%23P1/legend/${day}/battlelog`)).toBe(1);
  expect(calls.get('/v2/legends/ranks')).toBe(1);
  expect(calls.get('/v2/legends/ranks/history')).toBe(1);
});

test('loads and caches a separately selected Legend day', async () => {
  const day = '2026-08-15';
  const previousDay = '2026-08-14';
  const seriesPath =
    '/v2/player/%23P1/legend/series?time%5Bafter%5D=2026-07-19&time%5Bbefore%5D=2026-08-15';
  const { api, calls } = setup({
    '/proxy/v1/players/%23P1': officialPlayer({ trophies: 5600, bestTrophies: 5900 }),
    '/v2/player/%23P1/league/history': { items: [] },
    [`/v2/player/%23P1/legend/${day}/battlelog`]: legendBattlelog({ day }),
    [seriesPath]: {
      tag: '#P1',
      items: [
        { day: previousDay, attackTrophies: 10, defenseTrophies: -15, trophies: -5 },
        { day, attackTrophies: 20, defenseTrophies: -10, trophies: 10 },
      ],
    },
    '/v2/legends/ranks': { items: [] },
    '/v2/legends/ranks/history': {
      items: [{ tag: '#P1', name: 'One', trophies: 5500, globalRank: 80 }],
    },
  });
  const service = new PlayerService(api);
  await expect(service.loadLegendLeagueData('#P1', false, day)).resolves.toMatchObject({
    selectedDay: day,
    currentDay: { day },
    historicalRank: { globalRank: 80 },
    recentDays: [{ day: previousDay }, { day }],
  });
  await service.loadLegendLeagueData('#P1', false, day);
  expect(calls.get(`/v2/player/%23P1/legend/${day}/battlelog`)).toBe(1);
  expect(calls.get(seriesPath)).toBe(1);
  expect(calls.get(`/v2/player/%23P1/legend/${previousDay}/battlelog`)).toBeUndefined();
});

test.each([
  ['decode', { tag: '#P1' }, ResponseDecodeError],
  ['upstream', { code: 'upstream_unavailable', message: 'down' }, ApiResponseError],
] as const)(
  'Legend-day %s failures propagate and a later load retries',
  async (_name, failure, kind) => {
    const path = '/v2/player/%23P1/legend/2026-08-01/battlelog';
    let callsForDay = 0;
    const { api, calls } = setup({
        [path]: async () => {
          callsForDay += 1;
          return callsForDay === 1
            ? reply(failure, kind === ApiResponseError ? 503 : 200)
            : reply(legendBattlelog());
        },
      }),
      service = new PlayerService(api);

    await expect(service.loadLegendBattlelog('#P1', '2026-08-01')).rejects.toBeInstanceOf(kind);
    await expect(service.loadLegendBattlelog('#P1', '2026-08-01')).resolves.toMatchObject({
      day: '2026-08-01',
    });
    expect(calls.get(path)).toBe(2);
  },
);

test('keeps the active ranked group when another member has no clan', async () => {
  const { api } = setup({
    '/proxy/v1/players/%23P1': officialPlayer({
      trophies: 627,
      currentLeagueGroupTag: '#GROUP',
      currentLeagueSeasonId: 123,
    }),
    '/proxy/v1/leaguetiers': { items: [] },
    '/proxy/v1/players/%23P1/leaguehistory': { items: [] },
    '/proxy/v1/leaguegroup/%23GROUP/123?playerTag=%23P1': {
      members: [
        rankedMember('#P1', 'One', 627),
        { ...rankedMember('#NOCLAN', 'Clanless', 242), clanTag: null, clanName: null },
      ],
      attackLogs: [],
      defenseLogs: [],
    },
  });

  const data = await new PlayerService(api).loadRankedLeagueData('#P1');
  expect(data.currentGroup).toMatchObject({ tag: '#GROUP', seasonId: 123 });
  expect(data.currentGroup?.members).toHaveLength(2);
  expect(data.currentRank).toBe(1);
});

test('ranked warmup canonicalizes duplicates and isolates per-account failures', async () => {
  const { api, calls } = setup({
      '/proxy/v1/players/%23P1': officialPlayer(),
      '/proxy/v1/players/%23P1/leaguehistory': { items: [] },
      '/proxy/v1/leaguetiers': { items: [] },
      '/proxy/v1/players/%23BAD': async () => {
        throw new TypeError('offline');
      },
    }),
    service = new PlayerService(api);

  await expect(service.prefetchRankedLeagueData(['p1', '#P1', '#BAD'])).resolves.toBeUndefined();
  expect(calls.get('/proxy/v1/players/%23P1')).toBe(1);
  expect(calls.get('/proxy/v1/players/%23BAD')).toBe(1);
  await expect(service.loadRankedLeagueData('#P1')).resolves.toMatchObject({ playerName: 'One' });
  expect(calls.get('/proxy/v1/players/%23P1')).toBe(1);
});
test('clearing ranked data prevents an older in-flight response from repopulating the cache', async () => {
  let resolveOld: ((value: Response) => void) | undefined;
  const oldResponse = new Promise<Response>((resolve) => {
    resolveOld = resolve;
  });
  let profileCalls = 0;
  const { api, calls } = setup({
      '/proxy/v1/players/%23P1': async () => {
        profileCalls += 1;
        return profileCalls === 1
          ? oldResponse
          : reply(officialPlayer({ name: 'New profile', trophies: 2 }));
      },
      '/proxy/v1/players/%23P1/leaguehistory': { items: [] },
      '/proxy/v1/leaguetiers': { items: [] },
    }),
    service = new PlayerService(api);

  const older = service.loadRankedLeagueData('#P1');
  service.clearRankedLeagueCache();
  const newer = await service.loadRankedLeagueData('#P1');
  expect(newer.playerName).toBe('New profile');

  resolveOld?.(reply(officialPlayer({ name: 'Old profile', trophies: 1 })));
  expect((await older).playerName).toBe('Old profile');
  expect((await service.loadRankedLeagueData('#P1')).playerName).toBe('New profile');
  expect(calls.get('/proxy/v1/players/%23P1')).toBe(2);
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

test('loads and caches activity while preserving exact timer and join/leave contracts', async () => {
  const before = new Date('2026-08-01T00:00:00.000Z');
  const { api, calls } = setup({
      '/v2/player/%23P1/history/changes?type=troop_level&limit=500': { items: [] },
      '/v2/player/%23P1/timers': { items: [] },
      '/v2/player/%23P1/join-leave?limit=50&time%5Bbefore%5D=2026-08-01T00%3A00%3A00.000Z': {
        available: 0,
        items: [],
      },
      '/v2/player/%23P1/join-leave/totals': {
        items: [{ clan: { tag: '#C', name: 'Clan' }, visits: 2, minutes: 60 }],
      },
    }),
    service = new PlayerService(api);

  const first = await service.loadPlayerActivity('p1');
  expect(await service.loadPlayerActivity('#P1')).toBe(first);
  await service.loadPlayerActivity('#P1', 'troop_level', true);
  await service.loadPlayerTimers('p1');
  await service.loadPlayerJoinLeave('p1', before);
  const totals = await service.loadPlayerJoinLeaveTotals('p1');

  expect(calls.get('/v2/player/%23P1/history/changes?type=troop_level&limit=500')).toBe(2);
  expect(calls.get('/v2/player/%23P1/timers')).toBe(1);
  expect(
    calls.get('/v2/player/%23P1/join-leave?limit=50&time%5Bbefore%5D=2026-08-01T00%3A00%3A00.000Z'),
  ).toBe(1);
  expect(totals).toHaveLength(1);
});

test('uses official data, links clans, and emits minimal player JSON', async () => {
  const { api } = setup({}),
    storage = new MemoryStorage(),
    service = new PlayerService(api, storage);
  const listener = jest.fn();
  service.subscribe(listener);
  const player = await service.useOfficialPlayerData({
    tag: '#P1',
    name: 'One',
    townHallLevel: 18,
    clan: { tag: '#C', name: 'Clan', badgeUrls: {} },
  });
  const replacementClan = { tag: '#C', name: 'Replacement' };

  service.linkClansToPlayer([player], [replacementClan]);

  expect(player.clan).toBe(replacementClan);
  expect(storage.values.get('player_#P1_clan_tag')).toBe('#C');
  expect(JSON.parse(service.getMinimalisticPlayerByTag('#P1'))).toEqual({
    player_tag: '#P1',
    name: 'One',
    townHallLevel: 18,
  });
  expect(service.getMinimalisticPlayerByTag('#MISSING')).toBe('{}');
  expect(service.getSelectedProfile('#P1')).toBe(player);
  expect(service.getSelectedProfile(null)).toBeNull();
  expect(listener).toHaveBeenCalledTimes(1);
  service.dispose();
  service.notifyDataChanged();
  expect(listener).toHaveBeenCalledTimes(1);
});

test('hydrates bookmarked and bulk players while retaining existing profiles and enrichment', async () => {
  const { api, calls } = setup({
      '/proxy/v1/players/%23P1': officialPlayer(),
      '/proxy/v1/players/%23P2': officialPlayer({ tag: '#P2', name: 'Two' }),
    }),
    storage = new MemoryStorage(),
    service = new PlayerService(api, storage);
  await service.hydrateBookmarkedPlayers(['p1', '#P1']);

  service.processBulkPlayerData(
    [{ tag: '#P2', last_online: 123 }],
    [
      {
        tag: '#P2',
        name: 'Two',
        clan: { tag: '#C', name: 'Clan', badgeUrls: {} },
      },
    ],
    false,
  );

  expect(calls.get('/proxy/v1/players/%23P1')).toBe(1);
  expect(service.profiles.map(({ tag }) => tag)).toEqual(['#P2', '#P1']);
  expect(service.profiles[0]?.lastOnline).toEqual(new Date(123_000));
  await Promise.resolve();
  expect(storage.values.get('player_#P2_clan_tag')).toBe('#C');
});

test('loads, attaches, filters, and applies bulk war statistics', async () => {
  const warItem = warStatsItem();
  const { api, calls } = setup({
      '/v2/player/%23P1/war/stats?limit=50': { items: [warItem] },
      '/v2/player/%23P1/war/stats?type=cwl&limit=500&time%5Bbefore%5D=2026-09-01T00%3A00%3A00.000Z':
        {
          items: [warItem],
        },
    }),
    service = new PlayerService(api);
  await service.useOfficialPlayerData({ tag: '#P1', name: 'One' });
  const listener = jest.fn();
  service.subscribe(listener);

  await service.loadPlayerWarStats(['p1', '#P1']);
  await service.loadPlayerWarStatsWithFilter(
    '#P1',
    new WarStatsFilter({
      limit: 999,
      warTypes: ['cwl'],
      endDate: new Date('2026-09-01T00:00:00Z'),
    }),
  );
  service.processBulkWarStats([{ tag: '#P1', wars: [] }], false);

  expect(calls.get('/v2/player/%23P1/war/stats?limit=50')).toBe(1);
  expect(
    calls.get(
      '/v2/player/%23P1/war/stats?type=cwl&limit=500&time%5Bbefore%5D=2026-09-01T00%3A00%3A00.000Z',
    ),
  ).toBe(1);
  expect(service.profiles[0]?.warStats).not.toBeNull();
  expect(listener).toHaveBeenCalledTimes(1);
});

test('persists and restores named war filter presets', async () => {
  const { api } = setup({}),
    storage = new MemoryStorage(),
    service = new PlayerService(api, storage);
  const presets = [
    { name: 'CWL only', filter: new WarStatsFilter({ warTypes: ['cwl'], limit: 25 }) },
  ];

  await service.saveWarFilterPresets(presets);
  const restored = await service.loadWarFilterPresets();

  expect(restored).toHaveLength(1);
  expect(restored[0]?.name).toBe('CWL only');
  expect(restored[0]?.filter).toMatchObject({ warType: 'cwl', limit: 25 });
});

test('reports complete battlelog failure and keeps load wrappers notification-safe', async () => {
  const { api } = setup({}),
    service = new PlayerService(api);
  const listener = jest.fn();
  service.subscribe(listener);

  await expect(service.loadPlayerBattlelog('#MISSING')).rejects.toThrow();
  await expect(service.initPlayerData([], { throwOnError: true })).resolves.toEqual({});
  await expect(service.loadPlayerData([], {})).resolves.toBeUndefined();
  await expect(service.loadPlayerWarStats(['#P1'], { throwOnError: true })).rejects.toThrow();

  expect(service.isLoading).toBe(false);
  expect(listener).toHaveBeenCalled();
});
