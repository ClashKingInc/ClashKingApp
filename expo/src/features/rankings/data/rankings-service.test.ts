import { ApiClient } from '../../../core/api/client';
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
  return {
    status,
    url: '',
    headers: new Headers(),
    text: async () => (body === '' ? '' : JSON.stringify(body)),
  } as Response;
}

function setup(routes: Record<string, { body: unknown; status?: number }>) {
  const calls: { url: string; init?: RequestInit }[] = [];
  const fetchImplementation = jest.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = String(input);
    calls.push({ url, init });
    const parsed = new URL(url);
    const route = routes[`${parsed.origin}${parsed.pathname}${parsed.search}`];
    return response(route?.body ?? {}, route?.status ?? (route ? 200 : 404));
  });
  const api = new ApiClient({
    baseUrl: 'https://api.test',
    proxyUrl: 'https://proxy.test',
    environment: 'staging',
    tokenProvider: { getAccessToken: async () => 'token' },
    fetchImplementation: fetchImplementation as typeof fetch,
  });
  return { service: new RankingsService(api), calls };
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
      'https://proxy.test/locations': {
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

  test('uses the authenticated official proxy route for current rankings', async () => {
    const { service, calls } = setup({
      'https://proxy.test/locations/global/rankings/players?limit=200': {
        body: { items: [{ tag: '#ONE', name: 'One', rank: 1, trophies: 6200 }] },
      },
    });

    const result = await service.fetchRankings(query());
    expect(calls[0]?.url).toBe('https://proxy.test/locations/global/rankings/players?limit=200');
    expect(calls[0]?.init?.method).toBe('GET');
    expect((calls[0]?.init?.headers as Record<string, string>).Authorization).toBe('Bearer token');
    expect(result.source).toBe(RankingSource.official);
    expect(result.limit).toBe(200);
    expect(result.entries[0]?.tag).toBe('#ONE');
  });

  test('uses the ClashKing ranked route and selected tier badge', async () => {
    const { service, calls } = setup({
      'https://api.test/leaderboard/league/105000035?limit=500': {
        body: {
          items: [{ tag: '#RANKED', name: 'Ranked', placement: 1, league_trophies: 900 }],
        },
      },
    });
    const result = await service.fetchRankings(
      query({ board: RankingBoard.playerRanked, leagueTier: RankingLeagueOption.legendTwo }),
    );
    expect(calls[0]?.url).toBe('https://api.test/leaderboard/league/105000035?limit=500');
    expect(calls[0]?.init?.method).toBe('GET');
    expect(result.entries[0]?.metricImageUrl).toBe(RankingLeagueOption.legendTwo.iconUrl);
  });

  test('maps HTTP 204 and 404 to empty ranking results but preserves other statuses', async () => {
    for (const status of [204, 404]) {
      const { service } = setup({
        'https://api.test/leaderboard/townhalls/18?limit=500': { body: '', status },
      });
      await expect(
        service.fetchRankings(query({ board: RankingBoard.playerTownHall })),
      ).resolves.toMatchObject({ entries: [], limit: 500 });
    }

    const { service } = setup({
      'https://api.test/leaderboard/townhalls/18?limit=500': { body: {}, status: 503 },
    });
    await expect(
      service.fetchRankings(query({ board: RankingBoard.playerTownHall })),
    ).rejects.toEqual(new RankingsRequestException(503));
  });

  test('uses the deployed typed history route and rejects unsupported history locally', async () => {
    const { service, calls } = setup({
      'https://api.test/leaderboard/history/player_home_trophies/global/2026-07-19': {
        body: { items: [] },
      },
    });
    await service.fetchRankings(query({ period: RankingPeriod.history }));
    expect(calls[0]?.url).toBe(
      'https://api.test/leaderboard/history/player_home_trophies/global/2026-07-19',
    );

    await expect(
      service.fetchRankings(
        query({ board: RankingBoard.playerRanked, period: RankingPeriod.history }),
      ),
    ).rejects.toBeInstanceOf(UnsupportedRankingHistoryError);
    expect(calls).toHaveLength(1);
  });
});
