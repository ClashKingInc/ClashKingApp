import {
  ArmySearchEndpoint,
  ClanCapitalLeagueCountsEndpoint,
  ClanLocationCountsEndpoint,
  CwlLeagueCountsEndpoint,
  PlayerLeagueTierCountsEndpoint,
  PlayerTownhallCountsEndpoint,
  StatsCwlEndpoint,
  StatsRankedEndpoint,
  StatsOverviewEndpoint,
  StatsWarEndpoint,
} from '@clashking/api-contracts/expo';
import { Effect } from 'effect';

import type { ContractApiService } from '../../../core/api/contract-api';
import {
  decodeStatsGroupedCounts,
  StatsArmiesResponse,
  StatsClanCountsResponse,
  StatsDateRange,
  StatsItemsResponse,
  StatsOverviewResponse,
  StatsPerformanceResponse,
  StatsPlayerCountsResponse,
  type StatsArmiesQuery,
  type StatsCwlQuery,
  type StatsDateFilter,
  type StatsItemsQuery,
  type StatsRankedQuery,
  type StatsWarQuery,
} from '../models';

export interface StatsRepositoryContract {
  loadOverview(dates: StatsDateFilter): Promise<StatsOverviewResponse>;
  loadPlayerCounts(): Promise<StatsPlayerCountsResponse>;
  loadClanCounts(): Promise<StatsClanCountsResponse>;
  loadArmies(request: StatsArmiesQuery): Promise<StatsArmiesResponse>;
  loadItems(request: StatsItemsQuery): Promise<StatsItemsResponse>;
  loadRanked(request: StatsRankedQuery): Promise<StatsPerformanceResponse>;
  loadWar(request: StatsWarQuery): Promise<StatsPerformanceResponse>;
  loadCwl(request: StatsCwlQuery): Promise<StatsPerformanceResponse>;
}

export class StatsRepository implements StatsRepositoryContract {
  constructor(private readonly contractApi: ContractApiService) {}

  async loadOverview(dates: StatsDateFilter): Promise<StatsOverviewResponse> {
    return StatsOverviewResponse.fromJson(
      await Effect.runPromise(
        this.contractApi.execute(StatsOverviewEndpoint, {
          path: {},
          query: { start_date: formatDate(dates.start), end_date: formatDate(dates.end) },
          body: {},
        }),
      ),
    );
  }
  async loadPlayerCounts(): Promise<StatsPlayerCountsResponse> {
    const responses = await Promise.all([
      Effect.runPromise(
        this.contractApi.execute(PlayerTownhallCountsEndpoint, { path: {}, query: {}, body: {} }),
      ),
      Effect.runPromise(
        this.contractApi.execute(PlayerLeagueTierCountsEndpoint, { path: {}, query: {}, body: {} }),
      ),
    ]);
    return new StatsPlayerCountsResponse(
      decodeStatsGroupedCounts(responses[0], 'townhall_level'),
      decodeStatsGroupedCounts(responses[1], 'league_tier_id'),
    );
  }
  async loadClanCounts(): Promise<StatsClanCountsResponse> {
    const responses = await Promise.all([
      Effect.runPromise(
        this.contractApi.execute(ClanLocationCountsEndpoint, { path: {}, query: {}, body: {} }),
      ),
      Effect.runPromise(
        this.contractApi.execute(CwlLeagueCountsEndpoint, { path: {}, query: {}, body: {} }),
      ),
      Effect.runPromise(
        this.contractApi.execute(ClanCapitalLeagueCountsEndpoint, {
          path: {},
          query: {},
          body: {},
        }),
      ),
    ]);
    return new StatsClanCountsResponse(
      decodeStatsGroupedCounts(responses[0], 'location_id'),
      decodeStatsGroupedCounts(responses[1], 'cwl_league_id'),
      decodeStatsGroupedCounts(responses[2], 'capital_league_id'),
    );
  }
  async loadArmies(request: StatsArmiesQuery): Promise<StatsArmiesResponse> {
    return StatsArmiesResponse.fromJson(
      await Effect.runPromise(
        this.contractApi.execute(ArmySearchEndpoint, {
          path: {},
          query: request.toQuery(),
          body: {},
        }),
      ),
      new StatsDateRange(request.filters.dates.start, request.filters.dates.end),
    );
  }
  async loadItems(_request: StatsItemsQuery): Promise<StatsItemsResponse> {
    throw new RangeError('Item statistics are no longer available.');
  }
  async loadRanked(request: StatsRankedQuery): Promise<StatsPerformanceResponse> {
    return StatsPerformanceResponse.fromJson(
      await Effect.runPromise(
        this.contractApi.execute(StatsRankedEndpoint, {
          path: {},
          query: request.toQuery(),
          body: {},
        }),
      ),
    );
  }
  async loadWar(request: StatsWarQuery): Promise<StatsPerformanceResponse> {
    return StatsPerformanceResponse.fromJson(
      await Effect.runPromise(
        this.contractApi.execute(StatsWarEndpoint, {
          path: {},
          query: request.toQuery(),
          body: {},
        }),
      ),
    );
  }
  async loadCwl(request: StatsCwlQuery): Promise<StatsPerformanceResponse> {
    return StatsPerformanceResponse.fromJson(
      await Effect.runPromise(
        this.contractApi.execute(StatsCwlEndpoint, {
          path: {},
          query: request.toQuery(),
          body: {},
        }),
      ),
    );
  }
}

function formatDate(value: Date): string {
  return `${value.getFullYear().toString().padStart(4, '0')}-${(value.getMonth() + 1).toString().padStart(2, '0')}-${value.getDate().toString().padStart(2, '0')}`;
}
