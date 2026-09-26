import {
  ArmySearchEndpoint,
  ArmySetupsEndpoint,
  ArmySetupTimelineEndpoint,
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

import type { ContractApiService } from '../../../core/api/contract-api';
import { ProxyLocationsEndpoint } from '../../../core/api/proxy-contracts';
import { gameDataState, isRecord } from '../../../core/game-data/game-data-state';
import {
  decodeStatsLocationMetadata,
  decodeStatsGroupedCounts,
  StatsArmiesResponse,
  StatsBreakdown,
  StatsClanCountsResponse,
  StatsCwlResponse,
  StatsDateFilter,
  StatsDateRange,
  StatsLegendQuery,
  StatsLegendResponse,
  StatsMetrics,
  StatsPerformanceResponse,
  StatsPlayerCountsResponse,
  StatsRankedQuery,
  StatsWarQuery,
  type StatsArmiesQuery,
  type StatsArmySetupQuery,
  type StatsArmySetupResponse,
  type StatsArmySetupTimelineResponse,
  type StatsCwlQuery,
  type StatsWarHitRate,
  type StatsWarSummary,
} from '../models';

export interface StatsRepositoryContract {
  loadPlayerCounts(fresh?: boolean): Promise<StatsPlayerCountsResponse>;
  loadClanCounts(fresh?: boolean): Promise<StatsClanCountsResponse>;
  loadArmies(request: StatsArmiesQuery, fresh?: boolean): Promise<StatsArmiesResponse>;
  loadArmySetups(request: StatsArmySetupQuery, fresh?: boolean): Promise<StatsArmySetupResponse>;
  loadArmySetupTimeline(
    request: StatsArmySetupQuery,
    fresh?: boolean,
  ): Promise<StatsArmySetupTimelineResponse>;
  loadItems(request: StatsLegendQuery, fresh?: boolean): Promise<StatsLegendResponse>;
  loadRanked(request: StatsRankedQuery, fresh?: boolean): Promise<StatsPerformanceResponse>;
  loadWar(request: StatsWarQuery, fresh?: boolean): Promise<StatsPerformanceResponse>;
  loadCwl(request: StatsCwlQuery, fresh?: boolean): Promise<StatsCwlResponse>;
}

const statsCacheLifetimeMs = 60 * 60 * 1000;
type CacheEntry = { readonly value: object; readonly updatedAt: number };
type ResponseCache = {
  readonly entries: Map<string, CacheEntry>;
  readonly pending: Map<string, Promise<object>>;
};
const responseCaches = new WeakMap<ContractApiService, ResponseCache>();

export class StatsRepository implements StatsRepositoryContract {
  constructor(private readonly contractApi: ContractApiService) {}
  private async cached<T extends object>(
    key: string,
    fresh: boolean,
    load: () => Promise<T>,
  ): Promise<T> {
    let cache = responseCaches.get(this.contractApi);
    if (!cache) {
      cache = { entries: new Map(), pending: new Map() };
      responseCaches.set(this.contractApi, cache);
    }
    const previous = cache.entries.get(key);
    if (!fresh && previous && Date.now() - previous.updatedAt < statsCacheLifetimeMs)
      return previous.value as T;
    if (!fresh && cache.pending.has(key)) return cache.pending.get(key)! as Promise<T>;
    const pending = Promise.resolve().then(load);
    cache.pending.set(key, pending);
    try {
      const value = await pending;
      if (cache.pending.get(key) === pending)
        cache.entries.set(key, { value, updatedAt: Date.now() });
      return value;
    } finally {
      if (cache.pending.get(key) === pending) cache.pending.delete(key);
    }
  }
  async loadPlayerCounts(fresh = false): Promise<StatsPlayerCountsResponse> {
    return this.cached('players', fresh, () => this.fetchPlayerCounts());
  }
  private async fetchPlayerCounts(): Promise<StatsPlayerCountsResponse> {
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
  async loadClanCounts(fresh = false): Promise<StatsClanCountsResponse> {
    return this.cached('clans', fresh, () => this.fetchClanCounts());
  }
  private async fetchClanCounts(): Promise<StatsClanCountsResponse> {
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
      Effect.runPromise(
        this.contractApi.execute(ProxyLocationsEndpoint, { path: {}, query: {}, body: {} }),
      )
        .then(decodeStatsLocationMetadata)
        .catch(() => []),
      Effect.runPromise(
        this.contractApi.execute(ClanMemberBinsEndpoint, { path: {}, query: {}, body: {} }),
      ).catch(() => null),
    ]);
    return new StatsClanCountsResponse(
      decodeStatsGroupedCounts(responses[0], 'location_id'),
      decodeStatsGroupedCounts(responses[1], 'cwl_league_id'),
      decodeStatsGroupedCounts(responses[2], 'capital_league_id'),
      responses[3],
      responses[4]?.items ?? null,
    );
  }
  async loadArmies(request: StatsArmiesQuery, fresh = false): Promise<StatsArmiesResponse> {
    return this.cached(`armies:${JSON.stringify(request.toQuery())}`, fresh, async () =>
      StatsArmiesResponse.fromJson(
        await Effect.runPromise(
          this.contractApi.execute(ArmySearchEndpoint, {
            path: {},
            query: request.toQuery(),
            body: {},
          }),
        ),
        new StatsDateRange(request.filters.dates.start, request.filters.dates.end),
      ),
    );
  }
  async loadArmySetups(
    request: StatsArmySetupQuery,
    fresh = false,
  ): Promise<StatsArmySetupResponse> {
    return this.cached(`army-setups:${JSON.stringify(request)}`, fresh, () =>
      Effect.runPromise(
        this.contractApi.execute(ArmySetupsEndpoint, { path: {}, query: request, body: {} }),
      ),
    );
  }
  async loadArmySetupTimeline(
    request: StatsArmySetupQuery,
    fresh = false,
  ): Promise<StatsArmySetupTimelineResponse> {
    return this.cached(`army-setup-timeline:${JSON.stringify(request)}`, fresh, () =>
      Effect.runPromise(
        this.contractApi.execute(ArmySetupTimelineEndpoint, { path: {}, query: request, body: {} }),
      ),
    );
  }
  async loadItems(request: StatsLegendQuery, fresh = false): Promise<StatsLegendResponse> {
    return this.cached(`items:${JSON.stringify(request.toQuery())}`, fresh, async () =>
      StatsLegendResponse.fromJson(
        await Effect.runPromise(
          this.contractApi.execute(LegendDaysEndpoint, {
            path: {},
            query: request.toQuery(),
            body: {},
          }),
        ),
      ),
    );
  }
  async loadRanked(request: StatsRankedQuery, fresh = false): Promise<StatsPerformanceResponse> {
    return this.cached(`ranked:${JSON.stringify(request.toQuery())}`, fresh, async () => {
      const current = await this.fetchRanked(request);
      const tierIds = [
        request.rankedLeagueTierId + 1,
        request.rankedLeagueTierId - 1,
        request.rankedLeagueTierId - 2,
      ]
        .filter((id) => id >= 105000001 && id <= 105000036)
        .slice(0, 2);
      const nearby = await Promise.allSettled(
        tierIds.map((id) =>
          this.fetchRanked(new StatsRankedQuery(request.dates, request.townHallLevel, id)),
        ),
      );
      const comparisons = [
        new StatsBreakdown(rankedTierName(request.rankedLeagueTierId), current.metrics),
        ...nearby.map(
          (result, index) =>
            new StatsBreakdown(
              rankedTierName(tierIds[index]!),
              result.status === 'fulfilled' ? result.value.metrics : unavailableMetrics(),
            ),
        ),
      ];
      return new StatsPerformanceResponse(
        current.dateRange,
        current.metrics,
        current.breakdowns,
        comparisons,
      );
    });
  }
  async loadWar(request: StatsWarQuery, fresh = false): Promise<StatsPerformanceResponse> {
    return this.cached(`war:${JSON.stringify(request.toQuery())}`, fresh, async () => {
      const current = await this.fetchWar(request);
      const window = {
        'time[after]': StatsDateFilter.formatDate(request.dates.start),
        'time[before]': StatsDateFilter.formatDate(request.dates.end),
        interval: 'day' as const,
      };
      const [hitRates, summaries, sizes] = await Promise.all([
        Effect.runPromise(this.contractApi.execute(WarHitratesEndpoint, {
          path: {}, query: window, body: {},
        })),
        Effect.runPromise(this.contractApi.execute(WarSummaryEndpoint, {
          path: {}, query: window, body: {},
        })),
        Effect.runPromise(this.contractApi.execute(WarSummaryEndpoint, {
          path: {}, query: { ...window, groupBy: 'warSize' }, body: {},
        })),
      ]);
      const unfiltered = request.townHallLevel == null && request.opponentTownHallLevel == null;
      const byTownHall = new Map(current.breakdowns.map((entry) => [entry.key, entry.metrics]));
      const comparisons =
        unfiltered && current.breakdowns.length > 0
          ? Array.from({ length: 18 }, (_, index) => index + 1).map(
              (level) =>
                new StatsBreakdown(
                  `TH${level}`,
                  byTownHall.get(`TH${level}`) ?? unavailableMetrics(),
                ),
            )
          : current.breakdowns;
      return new StatsPerformanceResponse(
        current.dateRange, current.metrics, [], comparisons,
        hitRates.items as readonly StatsWarHitRate[],
        summaries.items as readonly StatsWarSummary[],
        sizes.items as readonly StatsWarSummary[],
      );
    });
  }
  async loadCwl(request: StatsCwlQuery, fresh = false): Promise<StatsCwlResponse> {
    return this.cached(`cwl:${JSON.stringify(request.toQuery())}`, fresh, async () =>
      StatsCwlResponse.fromJson(
        await Effect.runPromise(
          this.contractApi.execute(StatsCwlEndpoint, {
            path: {},
            query: request.toQuery(),
            body: {},
          }),
        ),
      ),
    );
  }
  private async fetchRanked(request: StatsRankedQuery): Promise<StatsPerformanceResponse> {
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
  private async fetchWar(request: StatsWarQuery): Promise<StatsPerformanceResponse> {
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
}

function unavailableMetrics(): StatsMetrics {
  return new StatsMetrics(false, 0, 0, 0, 0, 0, 0, 0, []);
}

function rankedTierName(id: number): string {
  const leagues = gameDataState.playerLeagueData.leagues;
  if (isRecord(leagues)) {
    for (const league of Object.values(leagues)) {
      if (
        isRecord(league) &&
        Number(league._id ?? league.id) === id &&
        typeof league.name === 'string' &&
        league.name.trim()
      )
        return league.name.trim();
    }
  }
  if (id === 105000036) return 'Legend League I';
  if (id === 105000035) return 'Legend League II';
  if (id === 105000034) return 'Legend League III';
  return id === 105000033 ? 'Electro League 33' : `League ${id - 105000000}`;
}
