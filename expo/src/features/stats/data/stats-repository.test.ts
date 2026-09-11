import {
  ArmySearchEndpoint,
  PlayerLeagueTierCountsEndpoint,
  PlayerTownhallCountsEndpoint,
  StatsCwlEndpoint,
  StatsRankedEndpoint,
  StatsWarEndpoint,
} from '@clashking/api-contracts/expo';
import { Effect } from 'effect';

import { type ContractApiService } from '../../../core/api/contract-api';
import { createContractTestApi } from '../../../core/api/contract-api.testing';
import {
  StatsArmiesQuery,
  StatsBattleFilters,
  StatsCwlQuery,
  StatsDateFilter,
  StatsRankedQuery,
  StatsWarQuery,
} from '../models';
import { StatsRepository } from './stats-repository';

describe('StatsRepository', () => {
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
    const ranked = new StatsRankedQuery(dates, 18, 1);
    const war = new StatsWarQuery(dates, 18);
    const cwl = new StatsCwlQuery(dates, 18);
    await repository.loadArmies(armies);
    await repository.loadRanked(ranked);
    await repository.loadWar(war);
    await repository.loadCwl(cwl);
    const expected = [
      ['/v2/stats/armies', armies.toQuery()],
      ['/v2/stats/ranked', ranked.toQuery()],
      ['/v2/stats/war', war.toQuery()],
      ['/v2/stats/cwl', cwl.toQuery()],
    ] as const;
    expect(captured).toHaveLength(expected.length);
    for (const [index, [path, query]] of expected.entries()) {
      const request = captured[index]!;
      const url = new URL(request.url);
      expect(url.origin + url.pathname).toBe(`https://api.test${path}`);
      expect(request.method).toBe('GET');
      expect(request.headers.get('content-type')).toBeNull();
      expect(await request.text()).toBe('');
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
    const ranked = new StatsRankedQuery(dates, 18, 1);
    const war = new StatsWarQuery(dates, 18);
    const cwl = new StatsCwlQuery(dates, 18);

    await repo.loadArmies(armies);
    await repo.loadRanked(ranked);
    await repo.loadWar(war);
    await repo.loadCwl(cwl);

    const expected = [
      [ArmySearchEndpoint, armies],
      [StatsRankedEndpoint, ranked],
      [StatsWarEndpoint, war],
      [StatsCwlEndpoint, cwl],
    ] as const;
    expect(execute).toHaveBeenCalledTimes(expected.length);
    expected.forEach(([endpoint, request], index) => {
      expect(endpoint.method).toBe('GET');
      expect(execute).toHaveBeenNthCalledWith(index + 1, endpoint, {
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
