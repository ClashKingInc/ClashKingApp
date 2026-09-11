import {
  LeaderboardClanDonationsEndpoint,
  LeaderboardClanWarWinsEndpoint,
  LeaderboardClanWinStreakEndpoint,
  LeaderboardHistoryEndpoint,
  LeaderboardLeagueEndpoint,
  LeaderboardTownhallsEndpoint,
} from '@clashking/api-contracts/expo';
import {
  ProxyBuilderClanRankingsEndpoint,
  ProxyBuilderPlayerRankingsEndpoint,
  ProxyCapitalRankingsEndpoint,
  ProxyClanRankingsEndpoint,
  ProxyLocationsEndpoint,
  ProxyPlayerRankingsEndpoint,
} from '../../../core/api/proxy-contracts';
import { Effect } from 'effect';
import { ApiResponseError } from '@clashking/api-client';

import type { ContractApiService } from '../../../core/api/contract-api';
import { STORAGE_KEYS, type StringStorage } from '../../../core/storage/storage';
import {
  RankingBoard,
  RankingEntry,
  RankingPeriod,
  RankingResult,
  type RankingQuery,
  RankingLocation,
} from '../models';

export interface RankingsServiceContract {
  fetchLocations(): Promise<readonly RankingLocation[]>;
  fetchRankings(query: RankingQuery): Promise<RankingResult>;
}

export class RankingsRequestException extends Error {
  constructor(readonly statusCode: number) {
    super(`Rankings request failed (${statusCode}).`);
    this.name = 'RankingsRequestException';
  }

  get isNoData(): boolean {
    return this.statusCode === 204 || this.statusCode === 404;
  }

  override toString(): string {
    return this.message;
  }
}

export class UnsupportedRankingHistoryError extends Error {
  constructor(boardName: string) {
    super(`History is not available for ${boardName}.`);
    this.name = 'UnsupportedRankingHistoryError';
  }
}

export class RankingsService implements RankingsServiceContract {
  constructor(
    private readonly api: ContractApiService,
    private readonly storage?: StringStorage,
  ) {}

  async fetchLocations(): Promise<readonly RankingLocation[]> {
    const cached = await this.readCachedLocations();
    if (cached) return cached;
    const decoded = await Effect.runPromise(
      this.api.execute(ProxyLocationsEndpoint, { path: {}, query: {}, body: {} }),
    );
    const rawItems = isRecord(decoded) ? decoded.items : null;
    if (!Array.isArray(rawItems)) {
      throw new TypeError('Locations response does not contain items.');
    }

    const locations = rawItems
      .filter(isRecord)
      .map((item) => RankingLocation.fromJson(item))
      .filter(
        (location) =>
          location.id !== null && location.name.length > 0 && location.hasValidCountryCode,
      )
      .sort((a, b) => {
        if (a.isCountry !== b.isCountry) return a.isCountry ? 1 : -1;
        return a.name.toLowerCase().localeCompare(b.name.toLowerCase());
      });
    const result = [RankingLocation.worldwide(), ...locations];
    await this.storage
      ?.setString(
        STORAGE_KEYS.rankingLocations,
        JSON.stringify(
          locations.map(({ id, name, isCountry, countryCode }) => ({
            id,
            name,
            isCountry,
            countryCode,
          })),
        ),
      )
      .catch(() => undefined);
    return result;
  }

  private async readCachedLocations(): Promise<readonly RankingLocation[] | null> {
    const encoded = await this.storage?.getString(STORAGE_KEYS.rankingLocations).catch(() => null);
    if (!encoded) return null;
    try {
      const value: unknown = JSON.parse(encoded);
      if (!Array.isArray(value)) return null;
      const locations = value
        .filter(isRecord)
        .map((item) => RankingLocation.fromJson(item))
        .filter(
          (location) =>
            location.id !== null && location.name.length > 0 && location.hasValidCountryCode,
        );
      return locations.length > 0 ? [RankingLocation.worldwide(), ...locations] : null;
    } catch {
      return null;
    }
  }

  async fetchRankings(query: RankingQuery): Promise<RankingResult> {
    const route = routeFor(query);
    let decoded: Record<string, unknown>;
    try {
      decoded = await this.fetchRankingPayload(query);
    } catch (error) {
      if (!(error instanceof ApiResponseError)) throw error;
      const failure = new RankingsRequestException(error.status);
      if (failure.isNoData) return new RankingResult([], query.board.source, route.limit);
      throw failure;
    }
    const rawItems = isRecord(decoded) ? decoded.items : null;
    if (decoded === null || rawItems == null) {
      return new RankingResult([], query.board.source, route.limit);
    }
    if (!Array.isArray(rawItems)) {
      throw new TypeError('Ranking response does not contain items.');
    }

    const entries = rawItems
      .filter(isRecord)
      .map((item) =>
        RankingEntry.fromJson(
          item,
          query.board,
          query.board === RankingBoard.playerRanked ? query.leagueTier.iconUrl : undefined,
        ),
      )
      .filter((entry) => entry.tag.length > 0);
    return new RankingResult(entries, query.board.source, route.limit);
  }

  private fetchRankingPayload(query: RankingQuery): Promise<Record<string, unknown>> {
    const body = {};
    if (query.period === RankingPeriod.history) {
      const leaderboardType = leaderboardHistoryType(query.board);
      return Effect.runPromise(
        this.api.execute(LeaderboardHistoryEndpoint, {
          path: {
            leaderboardType,
            locationId: query.location.apiPath,
            date: formatLocalDate(query.historyDate),
          },
          query: {},
          body,
        }),
      );
    }
    const locationId = query.location.apiPath;
    if (query.board === RankingBoard.playerHome)
      return Effect.runPromise(
        this.api.execute(ProxyPlayerRankingsEndpoint, {
          path: { locationId },
          query: { limit: 200 },
          body,
        }),
      );
    if (query.board === RankingBoard.playerBuilder)
      return Effect.runPromise(
        this.api.execute(ProxyBuilderPlayerRankingsEndpoint, {
          path: { locationId },
          query: { limit: 200 },
          body,
        }),
      );
    if (query.board === RankingBoard.playerTownHall)
      return Effect.runPromise(
        this.api.execute(LeaderboardTownhallsEndpoint, {
          path: { townhallLevel: query.townHallLevel },
          query: { limit: 500 },
          body,
        }),
      );
    if (query.board === RankingBoard.playerRanked)
      return Effect.runPromise(
        this.api.execute(LeaderboardLeagueEndpoint, {
          path: { leagueTierId: query.leagueTier.id },
          query: { limit: 500 },
          body,
        }),
      );
    if (query.board === RankingBoard.clanHome)
      return Effect.runPromise(
        this.api.execute(ProxyClanRankingsEndpoint, {
          path: { locationId },
          query: { limit: 200 },
          body,
        }),
      );
    if (query.board === RankingBoard.clanBuilder)
      return Effect.runPromise(
        this.api.execute(ProxyBuilderClanRankingsEndpoint, {
          path: { locationId },
          query: { limit: 200 },
          body,
        }),
      );
    if (query.board === RankingBoard.clanCapital)
      return Effect.runPromise(
        this.api.execute(ProxyCapitalRankingsEndpoint, {
          path: { locationId },
          query: { limit: 200 },
          body,
        }),
      );
    if (query.board === RankingBoard.clanDonations)
      return Effect.runPromise(
        this.api.execute(LeaderboardClanDonationsEndpoint, {
          path: { locationId: query.location.id! },
          query: { limit: 500 },
          body,
        }),
      );
    if (query.board === RankingBoard.clanWarWins)
      return Effect.runPromise(
        this.api.execute(LeaderboardClanWarWinsEndpoint, {
          path: { locationId: query.location.id! },
          query: { limit: 500 },
          body,
        }),
      );
    return Effect.runPromise(
      this.api.execute(LeaderboardClanWinStreakEndpoint, { path: {}, query: { limit: 500 }, body }),
    );
  }
}

interface RankingRoute {
  readonly path: string;
  readonly official: boolean;
  readonly limit: number;
}

export function routeFor(query: RankingQuery): RankingRoute {
  const board = query.board;
  if (query.period === RankingPeriod.history) {
    const date = formatLocalDate(query.historyDate);
    let leaderboardType: string;
    if (board === RankingBoard.playerHome) {
      leaderboardType = 'player_home_trophies';
    } else if (board === RankingBoard.playerBuilder) {
      leaderboardType = 'player_builder_base_trophies';
    } else if (board === RankingBoard.clanHome) {
      leaderboardType = 'clan_home_points';
    } else if (board === RankingBoard.clanBuilder) {
      leaderboardType = 'clan_builder_base_points';
    } else if (board === RankingBoard.clanCapital) {
      leaderboardType = 'clan_capital_points';
    } else {
      throw new UnsupportedRankingHistoryError(board.name);
    }
    const path = `/leaderboard/history/${leaderboardType}/${query.location.apiPath}/${date}`;
    return { path, official: false, limit: 200 };
  }

  if (board === RankingBoard.playerHome) {
    return officialRoute(`/locations/${query.location.apiPath}/rankings/players?limit=200`);
  }
  if (board === RankingBoard.playerBuilder) {
    return officialRoute(
      `/locations/${query.location.apiPath}/rankings/players-builder-base?limit=200`,
    );
  }
  if (board === RankingBoard.playerTownHall) {
    return clashKingRoute(`/leaderboard/townhalls/${query.townHallLevel}?limit=500`);
  }
  if (board === RankingBoard.playerRanked) {
    return clashKingRoute(`/leaderboard/league/${query.leagueTier.id}?limit=500`);
  }
  if (board === RankingBoard.clanHome) {
    return officialRoute(`/locations/${query.location.apiPath}/rankings/clans?limit=200`);
  }
  if (board === RankingBoard.clanBuilder) {
    return officialRoute(
      `/locations/${query.location.apiPath}/rankings/clans-builder-base?limit=200`,
    );
  }
  if (board === RankingBoard.clanCapital) {
    return officialRoute(`/locations/${query.location.apiPath}/rankings/capitals?limit=200`);
  }
  if (board === RankingBoard.clanDonations) {
    return clashKingRoute(`/leaderboard/${query.location.id}/clan/donations?limit=500`);
  }
  if (board === RankingBoard.clanWarWins) {
    return clashKingRoute(`/leaderboard/${query.location.id}/clan/war-wins?limit=500`);
  }
  return clashKingRoute('/leaderboard/clan/win-streak?limit=500');
}

function officialRoute(path: string): RankingRoute {
  return { path, official: true, limit: 200 };
}

function clashKingRoute(path: string): RankingRoute {
  return { path, official: false, limit: 500 };
}

function leaderboardHistoryType(board: RankingQuery['board']): string {
  if (board === RankingBoard.playerHome) return 'player_home_trophies';
  if (board === RankingBoard.playerBuilder) return 'player_builder_base_trophies';
  if (board === RankingBoard.clanHome) return 'clan_home_points';
  if (board === RankingBoard.clanBuilder) return 'clan_builder_base_points';
  if (board === RankingBoard.clanCapital) return 'clan_capital_points';
  throw new UnsupportedRankingHistoryError(board.name);
}

function formatLocalDate(value: Date): string {
  const year = value.getFullYear();
  const month = String(value.getMonth() + 1).padStart(2, '0');
  const day = String(value.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
