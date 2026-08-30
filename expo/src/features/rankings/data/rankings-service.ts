import type { ApiClient, ApiResponse } from '../../../core/api/client';
import {
  RankingBoard,
  RankingEntry,
  RankingPeriod,
  RankingResult,
  type RankingQuery,
  RankingLocation,
} from '../models';

const ALL_HTTP_STATUSES = Array.from({ length: 500 }, (_, index) => index + 100);

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
  constructor(private readonly api: ApiClient) {}

  async fetchLocations(): Promise<readonly RankingLocation[]> {
    const response = await this.api.proxyGet('/locations', {
      acceptedStatuses: ALL_HTTP_STATUSES,
    });
    const decoded = decodeSuccessful(response);
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
    return [RankingLocation.worldwide(), ...locations];
  }

  async fetchRankings(query: RankingQuery): Promise<RankingResult> {
    const route = routeFor(query);
    const response = route.official
      ? await this.api.proxyGet(route.path, { acceptedStatuses: ALL_HTTP_STATUSES })
      : await this.api.get(route.path, { acceptedStatuses: ALL_HTTP_STATUSES });
    const decoded = decodeSuccessful(response, true);
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

function decodeSuccessful(response: ApiResponse, emptyOnNoData = false): unknown {
  if (emptyOnNoData && (response.status === 204 || response.status === 404)) return null;
  if (response.status !== 200) throw new RankingsRequestException(response.status);
  if (response.bodyText.trim().length === 0) return null;
  return JSON.parse(response.bodyText) as unknown;
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
