import type { ApiClient } from '../../../core/api/client';
import {
  decodeStatsGroupedCounts,
  StatsArmiesResponse,
  StatsClanCountsResponse,
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
  constructor(private readonly api: ApiClient) {}

  async loadOverview(dates: StatsDateFilter): Promise<StatsOverviewResponse> {
    const query = new URLSearchParams({
      start_date: formatDate(dates.start),
      end_date: formatDate(dates.end),
    });
    return StatsOverviewResponse.fromJson(
      await this.api.requestRecord(`/stats/overview?${query}`, { requiresAuth: false }),
    );
  }
  async loadPlayerCounts(): Promise<StatsPlayerCountsResponse> {
    const responses = await Promise.all([
      this.api.requestRecord('/counts/players/town-halls', { requiresAuth: false }),
      this.api.requestRecord('/counts/players/builder-halls', { requiresAuth: false }),
      this.api.requestRecord('/counts/players/league-tiers', { requiresAuth: false }),
    ]);
    return new StatsPlayerCountsResponse(
      decodeStatsGroupedCounts(responses[0], 'townhall_level'),
      decodeStatsGroupedCounts(responses[1], 'builderhall_level'),
      decodeStatsGroupedCounts(responses[2], 'league_tier_id'),
    );
  }
  async loadClanCounts(): Promise<StatsClanCountsResponse> {
    const responses = await Promise.all([
      this.api.requestRecord('/counts/clans/locations', { requiresAuth: false }),
      this.api.requestRecord('/counts/clans/cwl-leagues', { requiresAuth: false }),
      this.api.requestRecord('/counts/clans/capital-leagues', { requiresAuth: false }),
    ]);
    return new StatsClanCountsResponse(
      decodeStatsGroupedCounts(responses[0], 'location_id'),
      decodeStatsGroupedCounts(responses[1], 'cwl_league_id'),
      decodeStatsGroupedCounts(responses[2], 'capital_league_id'),
    );
  }
  async loadArmies(request: StatsArmiesQuery): Promise<StatsArmiesResponse> {
    return StatsArmiesResponse.fromJson(await this.query('/stats/armies', request.toJson()));
  }
  async loadItems(request: StatsItemsQuery): Promise<StatsItemsResponse> {
    return StatsItemsResponse.fromJson(await this.query('/stats/items', request.toJson()));
  }
  async loadRanked(request: StatsRankedQuery): Promise<StatsPerformanceResponse> {
    return StatsPerformanceResponse.fromJson(await this.query('/stats/ranked', request.toJson()));
  }
  async loadWar(request: StatsWarQuery): Promise<StatsPerformanceResponse> {
    return StatsPerformanceResponse.fromJson(await this.query('/stats/war', request.toJson()));
  }
  async loadCwl(request: StatsCwlQuery): Promise<StatsPerformanceResponse> {
    return StatsPerformanceResponse.fromJson(await this.query('/stats/cwl', request.toJson()));
  }

  private query(path: string, body: Record<string, unknown>): Promise<Record<string, unknown>> {
    return this.api.requestRecord(path, { method: 'QUERY', body, requiresAuth: false });
  }
}

function formatDate(value: Date): string {
  return `${value.getFullYear().toString().padStart(4, '0')}-${(value.getMonth() + 1).toString().padStart(2, '0')}-${value.getDate().toString().padStart(2, '0')}`;
}
