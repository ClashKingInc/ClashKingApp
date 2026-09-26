import { createContractTestApi, readContractRequest } from '../../../core/api/contract-api.testing';
import {
  RankingBoard,
  RankingLeagueOption,
  RankingLocation,
  RankingPeriod,
  RankingSource,
  type RankingQuery,
} from '../models';
import {
  routeFor,
  RankingsRequestException,
  RankingsService,
  UnsupportedRankingHistoryError,
} from './rankings-service';

function response(body: unknown, status = 200): Response {
  return new Response(status === 204 ? null : body === '' ? '' : JSON.stringify(body), { status });
}

function setup(
  routes: Record<string, { body: unknown; status?: number }>,
  storage?: {
    getString(key: string): Promise<string | null>;
    setString(key: string, value: string): Promise<void>;
    remove(key: string): Promise<void>;
  },
) {
  const calls: { url: string; init?: RequestInit }[] = [];
  const fetchImplementation = jest.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
    const request = await readContractRequest(input, init);
    const url = request.url.toString();
    calls.push({ url, init: request.init });
    const parsed = new URL(url);
    const route = routes[`${parsed.origin}${parsed.pathname}${parsed.search}`];
    return response(route?.body ?? {}, route?.status ?? (route ? 200 : 404));
  });
  const api = createContractTestApi({
    baseUrl: 'https://api.test',
    proxyUrl: 'https://proxy.test',
    environment: 'development',
    tokenProvider: { getAccessToken: async () => 'token' },
    fetchImplementation: fetchImplementation as typeof fetch,
  });
  return { service: new RankingsService(api, storage), calls };
}

function query(overrides: Partial<RankingQuery> = {}): RankingQuery {
  return {
    board: RankingBoard.playerHome,
    location: RankingLocation.worldwide(),
    period: RankingPeriod.current,
    historyDate: new Date(2026, 6, 19),
    townHallLevel: 18,
    leagueTier: RankingLeagueOption.legendOne,
    ...overrides,
  };
}

describe('RankingsService', () => {
  test.each([
    [RankingBoard.playerHome, '/locations/32000007/rankings/players?limit=200', true],
    [
      RankingBoard.playerBuilder,
      '/locations/32000007/rankings/players-builder-base?limit=200',
      true,
    ],
    [RankingBoard.playerTownHall, '/leaderboard/townhalls/18?limit=500', false],
    [RankingBoard.playerRanked, '/leaderboard/league/105000036?limit=500', false],
    [RankingBoard.clanHome, '/locations/32000007/rankings/clans?limit=200', true],
    [RankingBoard.clanBuilder, '/locations/32000007/rankings/clans-builder-base?limit=200', true],
    [RankingBoard.clanCapital, '/locations/32000007/rankings/capitals?limit=200', true],
    [RankingBoard.clanDonations, '/leaderboard/32000007/clan/donations?limit=500', false],
    [RankingBoard.clanWarWins, '/leaderboard/32000007/clan/war-wins?limit=500', false],
    [RankingBoard.clanWinStreak, '/leaderboard/clan/win-streak?limit=500', false],
  ])('matches the live current path for %s', (board, path, official) => {
    expect(
      routeFor(
        query({
          board,
          location: new RankingLocation(32000007, 'United States', true, 'US'),
        }),
      ),
    ).toEqual({ path, official, limit: official ? 200 : 500 });
  });

  test.each([
    [RankingBoard.playerHome, 'player_home_trophies'],
    [RankingBoard.playerBuilder, 'player_builder_base_trophies'],
    [RankingBoard.clanHome, 'clan_home_points'],
    [RankingBoard.clanBuilder, 'clan_builder_base_points'],
    [RankingBoard.clanCapital, 'clan_capital_points'],
  ])('matches the live typed history path for %s', (board, leaderboardType) => {
    expect(routeFor(query({ board, period: RankingPeriod.history }))).toEqual({
      path: `/leaderboard/history/${leaderboardType}/global/2026-07-19`,
      official: false,
      limit: 200,
    });
  });

  test('loads only valid countries with Worldwide pinned first', async () => {
    const { service } = setup({
      'https://api.test/proxy/v1/locations': {
        body: {
          items: [
            { id: 32000008, name: 'Zimbabwe', isCountry: true, countryCode: 'ZW' },
            { id: 32000000, name: 'Europe', isCountry: false },
            { id: 32000007, name: 'Afghanistan', isCountry: true, countryCode: 'AF' },
          ],
        },
      },
    });

    const locations = await service.fetchLocations();
    expect(locations.map((item) => item.name)).toEqual(['Worldwide', 'Afghanistan', 'Zimbabwe']);
  });

  test('persists the location catalog and reuses it without another request', async () => {
    const values = new Map<string, string>();
    const storage = {
      getString: async (key: string) => values.get(key) ?? null,
      setString: async (key: string, value: string) => {
        values.set(key, value);
      },
      remove: async (key: string) => {
        values.delete(key);
      },
    };
    const routes = {
      'https://api.test/proxy/v1/locations': {
        body: {
          items: [
            {
              id: 32000007,
              name: 'United States',
              isCountry: true,
              countryCode: 'US',
            },
          ],
        },
      },
    };
    const first = setup(routes, storage);
    expect((await first.service.fetchLocations()).map((item) => item.name)).toEqual([
      'Worldwide',
      'United States',
    ]);
    expect(first.calls).toHaveLength(1);

    const second = setup({}, storage);
    expect((await second.service.fetchLocations()).map((item) => item.name)).toEqual([
      'Worldwide',
      'United States',
    ]);
    expect(second.calls).toHaveLength(0);
  });

  test('uses the authenticated official proxy route for current rankings', async () => {
    const { service, calls } = setup({
      'https://api.test/proxy/v1/locations/global/rankings/players?limit=200': {
        body: {
          items: [
            { tag: '#ONE', name: 'One', rank: 1, previousRank: 1, expLevel: 200, trophies: 6200 },
          ],
        },
      },
    });

    const result = await service.fetchRankings(query());
    expect(calls[0]?.url).toBe(
      'https://api.test/proxy/v1/locations/global/rankings/players?limit=200',
    );
    expect(calls[0]?.init?.method).toBe('GET');
    expect((calls[0]?.init?.headers as Record<string, string>).authorization).toBe('Bearer token');
    expect(result.source).toBe(RankingSource.official);
    expect(result.limit).toBe(200);
    expect(result.entries[0]?.tag).toBe('#ONE');
  });

  test('uses the ClashKing ranked route and selected tier badge', async () => {
    const { service, calls } = setup({
      'https://api.test/v2/leaderboard/league/105000035?limit=500': {
        body: {
          count: 1,
          items: [
            {
              tag: '#RANKED',
              name: 'Ranked',
              rank: 1,
              trophies: 900,
              townhall_level: 18,
              leagueGroupId: '#GROUP',
            },
          ],
        },
      },
    });
    const result = await service.fetchRankings(
      query({ board: RankingBoard.playerRanked, leagueTier: RankingLeagueOption.legendTwo }),
    );
    expect(calls[0]?.url).toBe('https://api.test/v2/leaderboard/league/105000035?limit=500');
    expect(calls[0]?.init?.method).toBe('GET');
    expect(result.entries[0]?.metricImageUrl).toBe(RankingLeagueOption.legendTwo.iconUrl);
    expect(result.entries[0]?.leagueGroupId).toBe('#GROUP');
  });

  test('maps HTTP 404 to empty ranking results but preserves other statuses', async () => {
    for (const status of [404]) {
      const { service } = setup({
        'https://api.test/v2/leaderboard/townhalls/18?limit=500': { body: '', status },
      });
      await expect(
        service.fetchRankings(query({ board: RankingBoard.playerTownHall })),
      ).resolves.toMatchObject({ entries: [], limit: 500 });
    }

    const { service } = setup({
      'https://api.test/v2/leaderboard/townhalls/18?limit=500': { body: {}, status: 503 },
    });
    await expect(
      service.fetchRankings(query({ board: RankingBoard.playerTownHall })),
    ).rejects.toEqual(new RankingsRequestException(503));
  });

  test('uses the deployed typed history route and rejects unsupported history locally', async () => {
    const { service, calls } = setup({
      'https://api.test/v2/leaderboard/history/player_home_trophies/global/2026-07-19': {
        body: { type: 'player_home_trophies', locationId: 'global', date: '2026-07-19', items: [] },
      },
    });
    await service.fetchRankings(query({ period: RankingPeriod.history }));
    expect(calls[0]?.url).toBe(
      'https://api.test/v2/leaderboard/history/player_home_trophies/global/2026-07-19',
    );

    await expect(
      service.fetchRankings(
        query({ board: RankingBoard.playerRanked, period: RankingPeriod.history }),
      ),
    ).rejects.toBeInstanceOf(UnsupportedRankingHistoryError);
    expect(calls).toHaveLength(1);
  });
});
