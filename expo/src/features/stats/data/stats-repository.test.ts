import {
  PlayerLeagueTierCountsEndpoint,
  PlayerTownhallCountsEndpoint,
  StatsArmiesEndpoint,
  StatsCwlEndpoint,
  StatsItemsEndpoint,
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
  StatsItemsQuery,
  StatsItemSelector,
  StatsRankedQuery,
  StatsWarQuery,
} from '../models';
import { StatsRepository } from './stats-repository';

describe('StatsRepository', () => {
  it('sends all five POST bodies through the real shared transport and decodes their responses', async () => {
    const captured: Request[] = [];
    const dateRange = { start: '2026-08-01', end: '2026-08-30' };
    const metrics = {
      available: true,
      sample_size: 10,
      average_stars: 2.5,
      average_destruction: 90,
      zero_star_rate: 0,
      one_star_rate: 0,
      two_star_rate: 0.5,
      three_star_rate: 0.5,
      daily: [],
    };
    const fetchImplementation: typeof fetch = async (input, init) => {
      const request = new Request(input, init);
      captured.push(request.clone());
      const path = new URL(request.url).pathname;
      return Response.json(
        path === '/v2/stats/armies' || path === '/v2/stats/items'
          ? { date_range: dateRange, items: [], count: 0 }
          : { date_range: dateRange, metrics },
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
    const items = new StatsItemsQuery(filters, [new StatsItemSelector('Barbarian', 'troop')]);
    const ranked = new StatsRankedQuery(dates, 18, 1);
    const war = new StatsWarQuery(dates, 18);
    const cwl = new StatsCwlQuery(dates, 18);
    await repository.loadArmies(armies);
    await repository.loadItems(items);
    await repository.loadRanked(ranked);
    await repository.loadWar(war);
    await repository.loadCwl(cwl);
    const expected = [
      ['/v2/stats/armies', armies],
      ['/v2/stats/items', items],
      ['/v2/stats/ranked', ranked],
      ['/v2/stats/war', war],
      ['/v2/stats/cwl', cwl],
    ] as const;
    expect(captured).toHaveLength(expected.length);
    for (const [index, [path, query]] of expected.entries()) {
      const request = captured[index]!;
      expect(request.url).toBe(`https://api.test${path}`);
      expect(request.method).toBe('POST');
      expect(request.headers.get('content-type')).toBe('application/json');
      expect(await request.json()).toEqual(query.toJson());
    }
  });

  it('rejects malformed successful stats payloads at the shared contract boundary', async () => {
    const repository = new StatsRepository(
      createContractTestApi({
        baseUrl: 'https://api.test',
        fetchImplementation: async () => Response.json({ date_range: {}, metrics: {} }),
      }),
    );
    const dates = new StatsDateFilter(new Date(2026, 7, 1), new Date(2026, 7, 30));
    await expect(repository.loadRanked(new StatsRankedQuery(dates, 18, 1))).rejects.toMatchObject({
      _tag: 'ResponseDecodeError',
      operationId: StatsRankedEndpoint.operationId,
    });
  });

  it('uses POST with a JSON body for every former QUERY stats operation', async () => {
    const execute = jest.fn(() =>
      Effect.succeed({ date_range: { start: '2026-08-01', end: '2026-08-30' }, metrics: {} }),
    ) as unknown as jest.MockedFunction<ContractApiService['execute']>;
    const executeStatus = jest.fn() as unknown as ContractApiService['executeStatus'];
    const repo = new StatsRepository({ execute, executeStatus });
    const dates = new StatsDateFilter(new Date(2026, 7, 1), new Date(2026, 7, 30));
    const filters = new StatsBattleFilters(dates, 18);
    const armies = new StatsArmiesQuery(filters);
    const items = new StatsItemsQuery(filters, [new StatsItemSelector('Barbarian', 'troop')]);
    const ranked = new StatsRankedQuery(dates, 18, 1);
    const war = new StatsWarQuery(dates, 18);
    const cwl = new StatsCwlQuery(dates, 18);

    await repo.loadArmies(armies);
    await repo.loadItems(items);
    await repo.loadRanked(ranked);
    await repo.loadWar(war);
    await repo.loadCwl(cwl);

    const expected = [
      [StatsArmiesEndpoint, armies],
      [StatsItemsEndpoint, items],
      [StatsRankedEndpoint, ranked],
      [StatsWarEndpoint, war],
      [StatsCwlEndpoint, cwl],
    ] as const;
    expect(execute).toHaveBeenCalledTimes(expected.length);
    expected.forEach(([endpoint, request], index) => {
      expect(endpoint.method).toBe('POST');
      expect(execute).toHaveBeenNthCalledWith(index + 1, endpoint, {
        path: {},
        query: {},
        body: request.toJson(),
      });
    });
    expect(executeStatus).not.toHaveBeenCalled();
  });

  it('uses the exact public overview/count routes', async () => {
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

  it('uses the shared POST contract for battle stats requests', async () => {
    const execute = jest.fn(() =>
      Effect.succeed({ date_range: { start: '2026-08-01', end: '2026-08-30' }, metrics: {} }),
    ) as unknown as jest.MockedFunction<ContractApiService['execute']>;
    const executeStatus = jest.fn() as unknown as ContractApiService['executeStatus'];
    const repo = new StatsRepository({ execute, executeStatus });
    const dates = new StatsDateFilter(new Date(2026, 7, 1), new Date(2026, 7, 30));
    await repo.loadRanked(new StatsRankedQuery(dates, 18, 1));
    expect(execute).toHaveBeenCalledWith(StatsRankedEndpoint, {
      path: {},
      query: {},
      body: {
        dates: { start_date: '2026-08-01', end_date: '2026-08-30' },
        townhall_level: 18,
        ranked_league_tier_id: 1,
      },
    });
  });
});
