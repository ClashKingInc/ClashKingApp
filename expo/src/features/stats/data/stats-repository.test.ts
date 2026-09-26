import {
  ArmySearchEndpoint,
  ClanCapitalLeagueCountsEndpoint,
  ClanLocationCountsEndpoint,
  ClanMemberBinsEndpoint,
  CwlLeagueCountsEndpoint,
  LegendDaysEndpoint,
  PlayerLeagueTierCountsEndpoint,
  PlayerTownhallCountsEndpoint,
  StatsCwlEndpoint,
  StatsRankedEndpoint,
  StatsWarEndpoint,
  WarHitratesEndpoint,
  WarSummaryEndpoint,
} from '@clashking/api-contracts/expo';
import { Effect } from 'effect';
import { ProxyLocationsEndpoint } from '../../../core/api/proxy-contracts';

import { type ContractApiService } from '../../../core/api/contract-api';
import { createContractTestApi } from '../../../core/api/contract-api.testing';
import {
  StatsArmiesQuery,
  StatsBattleFilters,
  StatsCwlQuery,
  StatsDateFilter,
  StatsLegendCohort,
  StatsLegendQuery,
  StatsRankedQuery,
  StatsWarQuery,
} from '../models';
import { StatsRepository } from './stats-repository';

describe('StatsRepository', () => {
  it('reuses successful stats responses across screen repository instances for one hour', async () => {
    let now = 100_000;
    const clock = jest.spyOn(Date, 'now').mockImplementation(() => now);
    const fetchImplementation = jest.fn(async () => Response.json({ items: [], count: 0 }));
    const api = createContractTestApi({
      baseUrl: 'https://api.test/v2',
      fetchImplementation,
    });
    try {
      await new StatsRepository(api).loadPlayerCounts();
      now += 59 * 60 * 1000;
      await new StatsRepository(api).loadPlayerCounts();
      expect(fetchImplementation).toHaveBeenCalledTimes(2);

      now += 60 * 1000;
      await new StatsRepository(api).loadPlayerCounts();
      expect(fetchImplementation).toHaveBeenCalledTimes(4);
    } finally {
      clock.mockRestore();
    }
  });

  it('shares an in-flight stats request when the screen remounts', async () => {
    let release!: () => void;
    const gate = new Promise<void>((resolve) => {
      release = resolve;
    });
    const fetchImplementation = jest.fn(async () => {
      await gate;
      return Response.json({ items: [], count: 0 });
    });
    const api = createContractTestApi({ baseUrl: 'https://api.test/v2', fetchImplementation });
    const first = new StatsRepository(api).loadPlayerCounts();
    const second = new StatsRepository(api).loadPlayerCounts();
    release();
    await Promise.all([first, second]);
    expect(fetchImplementation).toHaveBeenCalledTimes(2);
  });

  it('loads Town Hall comparisons alongside daily hit rates and war-size summaries', async () => {
    const metrics = {
      available: true,
      sampleSize: 10,
      averageStars: 2.5,
      averageDestruction: 90,
      zeroStarRate: 0,
      oneStarRate: 0,
      twoStarRate: 0.5,
      threeStarRate: 0.5,
      daily: [],
    };
    const execute = jest.fn((endpoint, input) =>
      Effect.succeed(endpoint === WarHitratesEndpoint ? { items: [{
        period: '2026-08-30', townHall: 18, attacks: 10,
        stars: [{ stars: 0, count: 0 }, { stars: 1, count: 0 }, { stars: 2, count: 5 }, { stars: 3, count: 5 }],
        averageStars: 2.5, averageDestruction: 90, averageDuration: 120,
      }] } : endpoint === WarSummaryEndpoint ? { items: [{
        period: '2026-08-30', ...(input.query.groupBy ? { warSize: 15 } : { missedAttacks: 2 }),
        wars: 3, accounts: 45, townHalls: [{ level: 18, count: 40 }], draws: 0,
      }] } : {
        dateRange: { start: '2026-08-01', end: '2026-08-30' },
        metrics,
        breakdowns: [{ key: 'TH18', metrics }],
      }),
    ) as unknown as jest.MockedFunction<ContractApiService['execute']>;
    const repo = new StatsRepository({ execute, executeStatus: jest.fn() });
    const dates = new StatsDateFilter(new Date(2026, 7, 1), new Date(2026, 7, 30));

    const result = await repo.loadWar(new StatsWarQuery(dates));

    expect(execute).toHaveBeenCalledTimes(4);
    expect(result.comparisons).toHaveLength(18);
    expect(result.comparisons[0]).toMatchObject({ key: 'TH1', metrics: { available: false } });
    expect(result.comparisons[17]).toMatchObject({ key: 'TH18', metrics: { sampleSize: 10 } });
    expect(result.warHitRates[0]).toMatchObject({ townHall: 18, attacks: 10 });
    expect(result.warSummaries[0]).toMatchObject({ wars: 3, missedAttacks: 2 });
    expect(result.warSizes[0]).toMatchObject({ warSize: 15, wars: 3 });
  });

  it('compares the selected Legend tier with its real neighboring tier IDs', async () => {
    const execute = jest.fn(() =>
      Effect.succeed({
        dateRange: { start: '2026-08-01', end: '2026-08-30' },
        metrics: {
          available: false,
          sampleSize: 0,
          averageStars: 0,
          averageDestruction: 0,
          zeroStarRate: 0,
          oneStarRate: 0,
          twoStarRate: 0,
          threeStarRate: 0,
          daily: [],
        },
      }),
    ) as unknown as jest.MockedFunction<ContractApiService['execute']>;
    const repo = new StatsRepository({ execute, executeStatus: jest.fn() });
    const dates = new StatsDateFilter(new Date(2026, 7, 1), new Date(2026, 7, 30));

    const result = await repo.loadRanked(new StatsRankedQuery(dates, 18, 105000036));

    expect(
      execute.mock.calls.map(
        ([, request]) => (request.query as { leagueTierId: number }).leagueTierId,
      ),
    ).toEqual([105000036, 105000035, 105000034]);
    expect(result.comparisons.map((entry) => entry.key)).toEqual([
      'Legend League I',
      'Legend League II',
      'Legend League III',
    ]);
  });

  it('sends every canonical stats GET query through the shared transport and decodes responses', async () => {
    const captured: Request[] = [];
    const dateRange = { start: '2026-08-01', end: '2026-08-30' };
    const metrics = {
      available: true,
      sampleSize: 10,
      averageStars: 2.5,
      averageDestruction: 90,
      zeroStarRate: 0,
      oneStarRate: 0,
      twoStarRate: 0.5,
      threeStarRate: 0.5,
      daily: [],
    };
    const fetchImplementation: typeof fetch = async (input, init) => {
      const request = new Request(input, init);
      captured.push(request.clone());
      const path = new URL(request.url).pathname;
      return Response.json(
        path === '/v2/stats/armies'
          ? { cohort: 'legend_i', items: [] }
          : path === '/v2/stats/wars/hitrates' || path === '/v2/stats/wars/summary'
            ? { items: [] }
          : path === '/v2/stats/legend/days'
            ? { cohort: 'top_200', items: [] }
            : path === '/v2/stats/cwl'
              ? { season: '2026-08', clanCount: 0, registeredPlayerCount: 0, groupCount: 0, items: [] }
            : { dateRange, metrics },
      );
    };
    const repository = new StatsRepository(
      createContractTestApi({
        baseUrl: 'https://api.test/v2',
        fetchImplementation,
      }),
    );
    const dates = new StatsDateFilter(new Date(2026, 7, 1), new Date(2026, 7, 30));
    const filters = new StatsBattleFilters(dates, 18);
    const armies = new StatsArmiesQuery(filters);
    const legends = new StatsLegendQuery(dates, StatsLegendCohort.top200);
    const ranked = new StatsRankedQuery(dates, 18, 1);
    const war = new StatsWarQuery(dates, 18);
    const cwl = new StatsCwlQuery('2026-08');
    await repository.loadArmies(armies);
    await repository.loadItems(legends);
    await repository.loadRanked(ranked);
    await repository.loadWar(war);
    await repository.loadCwl(cwl);
    const expected = [
      ['/v2/stats/armies', armies.toQuery()],
      ['/v2/stats/legend/days', legends.toQuery()],
      ['/v2/stats/ranked', ranked.toQuery()],
      ['/v2/stats/war', war.toQuery()],
      ['/v2/stats/cwl', cwl.toQuery()],
    ] as const;
    expect(captured.length).toBeGreaterThanOrEqual(expected.length);
    for (const [path, query] of expected) {
      const request = captured.find((candidate) => {
        const url = new URL(candidate.url);
        if (url.pathname !== path) return false;
        return Object.entries(query).every(
          ([key, value]) =>
            url.searchParams.getAll(key).join(',') ===
            (Array.isArray(value) ? value : [value]).map(String).join(','),
        );
      });
      expect(request).toBeDefined();
      const url = new URL(request!.url);
      expect(url.origin + url.pathname).toBe(`https://api.test${path}`);
      expect(request!.method).toBe('GET');
      expect(request!.headers.get('content-type')).toBeNull();
      expect(await request!.text()).toBe('');
      expect([...url.searchParams.keys()].sort()).toEqual(Object.keys(query).sort());
      for (const [key, value] of Object.entries(query)) {
        expect(url.searchParams.getAll(key)).toEqual(
          (Array.isArray(value) ? value : [value]).map(String),
        );
      }
    }
  });

  it('rejects malformed successful stats payloads at the shared contract boundary', async () => {
    const repository = new StatsRepository(
      createContractTestApi({
        baseUrl: 'https://api.test',
        fetchImplementation: async () => Response.json({ dateRange: {}, metrics: {} }),
      }),
    );
    const dates = new StatsDateFilter(new Date(2026, 7, 1), new Date(2026, 7, 30));
    await expect(repository.loadRanked(new StatsRankedQuery(dates, 18, 1))).rejects.toMatchObject({
      _tag: 'ResponseDecodeError',
      operationId: StatsRankedEndpoint.operationId,
    });
  });

  it('uses GET query parameters and no body for every stats operation', async () => {
    const execute = jest.fn(() =>
      Effect.succeed({ dateRange: { start: '2026-08-01', end: '2026-08-30' }, metrics: {} }),
    ) as unknown as jest.MockedFunction<ContractApiService['execute']>;
    const executeStatus = jest.fn() as unknown as ContractApiService['executeStatus'];
    const repo = new StatsRepository({ execute, executeStatus });
    const dates = new StatsDateFilter(new Date(2026, 7, 1), new Date(2026, 7, 30));
    const filters = new StatsBattleFilters(dates, 18);
    const armies = new StatsArmiesQuery(filters);
    const legends = new StatsLegendQuery(dates, StatsLegendCohort.top200);
    const ranked = new StatsRankedQuery(dates, 18, 1);
    const war = new StatsWarQuery(dates, 18);
    const cwl = new StatsCwlQuery('2026-08');

    await repo.loadArmies(armies);
    await repo.loadItems(legends);
    await repo.loadRanked(ranked);
    await repo.loadWar(war);
    await repo.loadCwl(cwl);

    const expected = [
      [ArmySearchEndpoint, armies],
      [LegendDaysEndpoint, legends],
      [StatsRankedEndpoint, ranked],
      [StatsWarEndpoint, war],
      [StatsCwlEndpoint, cwl],
    ] as const;
    expect(execute.mock.calls.length).toBeGreaterThanOrEqual(expected.length);
    expected.forEach(([endpoint, request]) => {
      expect(endpoint.method).toBe('GET');
      expect(execute).toHaveBeenCalledWith(endpoint, {
        path: {},
        query: request.toQuery(),
        body: {},
      });
    });
    expect(executeStatus).not.toHaveBeenCalled();
  });

  it('uses the exact public player-count routes', async () => {
    const execute = jest.fn(() => Effect.succeed({ items: [] })) as unknown as jest.MockedFunction<
      ContractApiService['execute']
    >;
    const executeStatus = jest.fn(() =>
      Effect.succeed({ ok: true, status: 200, value: { items: [] } }),
    ) as unknown as jest.MockedFunction<ContractApiService['executeStatus']>;
    const repo = new StatsRepository({ execute, executeStatus });
    await repo.loadPlayerCounts();
    expect(execute.mock.calls.map(([endpoint]) => endpoint)).toEqual([
      PlayerTownhallCountsEndpoint,
      PlayerLeagueTierCountsEndpoint,
    ]);
    expect(executeStatus).not.toHaveBeenCalled();
  });

  it('enriches clan location counts with authoritative location metadata', async () => {
    const execute = jest.fn((endpoint: unknown) => {
      if (endpoint === ClanLocationCountsEndpoint) {
        return Effect.succeed({ items: [{ location_id: 32000006, count: 42 }] });
      }
      if (endpoint === CwlLeagueCountsEndpoint) return Effect.succeed({ items: [] });
      if (endpoint === ClanCapitalLeagueCountsEndpoint) return Effect.succeed({ items: [] });
      if (endpoint === ClanMemberBinsEndpoint) return Effect.succeed({
        totalClans: 42,
        items: [
          { minMembers: 0, maxMembers: 0, count: 2 },
          { minMembers: 1, maxMembers: 5, count: 40 },
        ],
      });
      if (endpoint === ProxyLocationsEndpoint) {
        return Effect.succeed({
          items: [{ id: 32000006, name: 'United States', isCountry: true, countryCode: 'US' }],
        });
      }
      return Effect.die(new Error('Unexpected endpoint'));
    }) as unknown as jest.MockedFunction<ContractApiService['execute']>;
    const repo = new StatsRepository({ execute, executeStatus: jest.fn() });

    const result = await repo.loadClanCounts();

    expect(result.locations).toEqual([{ id: 32000006, count: 42 }]);
    expect(result.locationMetadata).toEqual([
      { id: 32000006, name: 'United States', countryCode: 'US' },
    ]);
    expect(result.memberBins).toEqual([
      { minMembers: 0, maxMembers: 0, count: 2 },
      { minMembers: 1, maxMembers: 5, count: 40 },
    ]);
  });

  it('keeps clan counts when optional location metadata fails', async () => {
    const execute = jest.fn((endpoint: unknown) => {
      if (endpoint === ClanLocationCountsEndpoint) {
        return Effect.succeed({ items: [{ location_id: 32000006, count: 42 }] });
      }
      if (endpoint === CwlLeagueCountsEndpoint) return Effect.succeed({ items: [] });
      if (endpoint === ClanCapitalLeagueCountsEndpoint) return Effect.succeed({ items: [] });
      if (endpoint === ClanMemberBinsEndpoint) return Effect.fail(new Error('not deployed'));
      if (endpoint === ProxyLocationsEndpoint) return Effect.fail(new Error('offline'));
      return Effect.die(new Error('Unexpected endpoint'));
    }) as unknown as jest.MockedFunction<ContractApiService['execute']>;
    const repo = new StatsRepository({ execute, executeStatus: jest.fn() });

    const result = await repo.loadClanCounts();

    expect(result.locations).toEqual([{ id: 32000006, count: 42 }]);
    expect(result.locationMetadata).toEqual([]);
    expect(result.memberBins).toBeNull();
  });

  it('loads real player distributions without calling the unavailable Builder Hall route', async () => {
    const requests: Request[] = [];
    const repository = new StatsRepository(
      createContractTestApi({
        baseUrl: 'https://api.test/v2',
        fetchImplementation: async (input, init) => {
          const request = new Request(input, init);
          requests.push(request);
          switch (new URL(request.url).pathname) {
            case '/v2/counts/players/town-halls':
              return Response.json({ items: [{ townhall_level: 18, count: 42 }], count: 1 });
            case '/v2/counts/players/league-tiers':
              return Response.json({ items: [{ league_tier_id: 1, count: 23 }], count: 1 });
            case '/v2/counts/players/builder-halls':
              return Response.json(
                {
                  code: 'not_implemented',
                  message: 'Builder Hall counts are not implemented',
                },
                { status: 501 },
              );
            default:
              throw new Error(`Unexpected stats request: ${request.url}`);
          }
        },
      }),
    );

    const result = await repository.loadPlayerCounts();

    expect(result.townHalls).toEqual([{ id: 18, count: 42 }]);
    expect(result.leagueTiers).toEqual([{ id: 1, count: 23 }]);
    expect(result).not.toHaveProperty('builderHalls');
    expect(requests.map((request) => [request.method, new URL(request.url).pathname])).toEqual([
      ['GET', '/v2/counts/players/town-halls'],
      ['GET', '/v2/counts/players/league-tiers'],
    ]);
  });

  it('uses the canonical camelCase GET contract for battle stats requests', async () => {
    const execute = jest.fn(() =>
      Effect.succeed({ dateRange: { start: '2026-08-01', end: '2026-08-30' }, metrics: {} }),
    ) as unknown as jest.MockedFunction<ContractApiService['execute']>;
    const executeStatus = jest.fn() as unknown as ContractApiService['executeStatus'];
    const repo = new StatsRepository({ execute, executeStatus });
    const dates = new StatsDateFilter(new Date(2026, 7, 1), new Date(2026, 7, 30));
    await repo.loadRanked(new StatsRankedQuery(dates, 18, 1));
    expect(execute).toHaveBeenCalledWith(StatsRankedEndpoint, {
      path: {},
      query: {
        startDate: '2026-08-01',
        endDate: '2026-08-30',
        townHallLevel: 18,
        leagueTierId: 1,
      },
      body: {},
    });
  });
});
