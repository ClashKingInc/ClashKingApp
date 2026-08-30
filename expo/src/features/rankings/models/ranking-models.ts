import { ImageAssets } from '../../../core/assets/image-assets';

export const RankingAudience = {
  players: 'players',
  clans: 'clans',
} as const;
export type RankingAudienceValue = (typeof RankingAudience)[keyof typeof RankingAudience];

export const RankingPeriod = {
  current: 'current',
  history: 'history',
} as const;
export type RankingPeriodValue = (typeof RankingPeriod)[keyof typeof RankingPeriod];

export const RankingSource = {
  official: 'official',
  clashKing: 'clashKing',
} as const;
export type RankingSourceValue = (typeof RankingSource)[keyof typeof RankingSource];

export interface RankingBoardValue {
  readonly name: RankingBoardName;
  readonly audience: RankingAudienceValue;
  readonly source: RankingSourceValue;
  readonly supportsLocation: boolean;
  readonly supportsHistory: boolean;
  readonly supportsWorldwide: boolean;
  readonly iconUrl: string;
  readonly isClan: boolean;
}

function board(
  name: RankingBoardName,
  audience: RankingAudienceValue,
  source: RankingSourceValue,
  supportsLocation: boolean,
  supportsHistory: boolean,
  iconUrl: string,
  supportsWorldwide = true,
): RankingBoardValue {
  return Object.freeze({
    name,
    audience,
    source,
    supportsLocation,
    supportsHistory,
    supportsWorldwide,
    iconUrl,
    isClan: audience === RankingAudience.clans,
  });
}

export type RankingBoardName =
  | 'playerHome'
  | 'playerBuilder'
  | 'playerTownHall'
  | 'playerRanked'
  | 'clanHome'
  | 'clanBuilder'
  | 'clanCapital'
  | 'clanDonations'
  | 'clanWarWins'
  | 'clanWinStreak';

export const RankingBoard = {
  playerHome: board(
    'playerHome',
    RankingAudience.players,
    RankingSource.official,
    true,
    true,
    ImageAssets.trophies,
  ),
  playerBuilder: board(
    'playerBuilder',
    RankingAudience.players,
    RankingSource.official,
    true,
    true,
    ImageAssets.builderBaseTrophy,
  ),
  playerTownHall: board(
    'playerTownHall',
    RankingAudience.players,
    RankingSource.clashKing,
    false,
    false,
    ImageAssets.trophies,
  ),
  playerRanked: board(
    'playerRanked',
    RankingAudience.players,
    RankingSource.clashKing,
    false,
    false,
    ImageAssets.legendLeagueOne,
  ),
  clanHome: board(
    'clanHome',
    RankingAudience.clans,
    RankingSource.official,
    true,
    true,
    ImageAssets.trophies,
  ),
  clanBuilder: board(
    'clanBuilder',
    RankingAudience.clans,
    RankingSource.official,
    true,
    true,
    ImageAssets.builderBaseTrophy,
  ),
  clanCapital: board(
    'clanCapital',
    RankingAudience.clans,
    RankingSource.official,
    true,
    true,
    ImageAssets.capitalTrophy,
  ),
  clanDonations: board(
    'clanDonations',
    RankingAudience.clans,
    RankingSource.clashKing,
    true,
    false,
    ImageAssets.clanGamesMedals,
    false,
  ),
  clanWarWins: board(
    'clanWarWins',
    RankingAudience.clans,
    RankingSource.clashKing,
    true,
    false,
    ImageAssets.war,
    false,
  ),
  clanWinStreak: board(
    'clanWinStreak',
    RankingAudience.clans,
    RankingSource.clashKing,
    false,
    false,
    ImageAssets.war,
  ),
} as const;

export const rankingBoards = Object.values(RankingBoard);

export class RankingLocation {
  constructor(
    readonly id: number | null,
    readonly name: string,
    readonly isCountry: boolean,
    readonly countryCode: string | null = null,
    readonly isWorldwide = false,
  ) {}

  static worldwide(): RankingLocation {
    return new RankingLocation(null, 'Worldwide', false, null, true);
  }

  static fromJson(json: Record<string, unknown>): RankingLocation {
    return new RankingLocation(
      asIntOrNull(json.id),
      stringValue(json.name),
      json.isCountry === true,
      json.countryCode == null ? null : stringValue(json.countryCode).toUpperCase(),
    );
  }

  get apiPath(): string {
    return this.isWorldwide ? 'global' : String(this.id);
  }

  get hasValidCountryCode(): boolean {
    return this.isCountry && /^[A-Za-z]{2}$/.test(this.countryCode ?? '');
  }

  equals(other: RankingLocation): boolean {
    return this.id === other.id && this.isWorldwide === other.isWorldwide;
  }
}

export class RankingLeagueOption {
  static readonly legendOne = new RankingLeagueOption(
    105000036,
    'Legend League 1',
    ImageAssets.legendLeagueOne,
  );
  static readonly legendTwo = new RankingLeagueOption(
    105000035,
    'Legend League 2',
    ImageAssets.legendLeagueTwo,
  );
  static readonly legendThree = new RankingLeagueOption(
    105000034,
    'Legend League 3',
    ImageAssets.legendLeagueThree,
  );

  constructor(
    readonly id: number,
    readonly name: string,
    readonly iconUrl: string,
  ) {}
}

export interface RankingQuery {
  readonly board: RankingBoardValue;
  readonly location: RankingLocation;
  readonly period: RankingPeriodValue;
  readonly historyDate: Date;
  readonly townHallLevel: number;
  readonly leagueTier: RankingLeagueOption;
}

export class RankingResult {
  constructor(
    readonly entries: readonly RankingEntry[],
    readonly source: RankingSourceValue,
    readonly limit: number,
  ) {}
}

export class RankingEntry {
  constructor(
    readonly audience: RankingAudienceValue,
    readonly rank: number,
    readonly previousRank: number,
    readonly tag: string,
    readonly name: string,
    readonly subtitle: string,
    readonly score: number,
    readonly imageUrl: string,
    readonly metricImageUrl: string,
    readonly townHallLevel: number,
    readonly clanBadgeUrl = '',
  ) {}

  get movement(): string {
    if (this.previousRank <= 0 || this.rank <= 0) return '=';
    const delta = this.previousRank - this.rank;
    return delta === 0 ? '=' : delta > 0 ? `+${delta}` : String(delta);
  }

  static fromJson(
    json: Record<string, unknown>,
    rankingBoard: RankingBoardValue,
    rankedLeagueIconUrl?: string,
  ): RankingEntry {
    const tag = firstString(json, ['tag', 'player_tag', 'clan_tag']);
    const townHall = firstInt(json, ['townHallLevel', 'townhall_level', 'townhallLevel']);
    const clanName =
      nestedString(json.clan, 'name') ?? firstString(json, ['clan_name', 'clanName']);
    const clanTag = nestedString(json.clan, 'tag') ?? firstString(json, ['clan_tag', 'clanTag']);
    const subtitle = rankingBoard.isClan
      ? [
          ...(clanName ? [clanName] : []),
          ...(clanTag && clanTag !== tag ? [clanTag] : []),
          ...(!clanName && !clanTag && tag ? [tag] : []),
        ].join(' · ')
      : clanName;
    const includedClanBadge =
      nestedString(json.clan, 'badgeUrls.small') ??
      nestedString(json.clan, 'badge_urls.small') ??
      nestedString(json.clan, 'badgeUrls.medium') ??
      nestedString(json.clan, 'badge_urls.medium') ??
      nestedString(json.clan, 'badgeUrls.large') ??
      nestedString(json.clan, 'badge_urls.large') ??
      nestedString(json.clan, 'badge') ??
      firstString(json, ['clan_badge', 'clanBadge']);
    const clanBadgeUrl =
      rankingBoard.isClan || !clanTag
        ? ''
        : rankingBoard.source === RankingSource.official
          ? ImageAssets.clanBadgeForTag(clanTag)
          : includedClanBadge;
    const leagueIcon =
      nestedString(json.leagueTier, 'iconUrls.medium') ??
      nestedString(json.leagueTier, 'iconUrls.large') ??
      nestedString(json.leagueTier, 'iconUrls.small') ??
      nestedString(json.leagueTier, 'badge') ??
      nestedString(json.league, 'iconUrls.medium') ??
      nestedString(json.league, 'iconUrls.large') ??
      nestedString(json.league, 'iconUrls.small') ??
      nestedString(json.league, 'badge');
    const builderIcon =
      rankingBoard === RankingBoard.playerBuilder
        ? ImageAssets.getBuilderBaseLeagueImage(json.builderBaseLeague)
        : null;
    const badgeUrl =
      nestedString(json.badgeUrls, 'small') ??
      nestedString(json.badge_urls, 'small') ??
      nestedString(json.badgeUrls, 'medium') ??
      nestedString(json.badge_urls, 'medium') ??
      nestedString(json.badgeUrls, 'large') ??
      nestedString(json.badge_urls, 'large') ??
      firstString(json, ['badge_url']);
    const rankedIcon =
      rankingBoard === RankingBoard.playerRanked
        ? (rankedLeagueIconUrl ?? rankingBoard.iconUrl)
        : null;
    const playerImage =
      rankingBoard === RankingBoard.playerBuilder
        ? (builderIcon ?? rankingBoard.iconUrl)
        : townHall > 0
          ? ImageAssets.townHall(townHall)
          : (rankedIcon ?? leagueIcon ?? rankingBoard.iconUrl);
    return new RankingEntry(
      rankingBoard.audience,
      firstInt(json, ['rank', 'placement']),
      firstInt(json, ['previousRank', 'previous_rank']),
      tag,
      firstString(json, ['name', 'player_name', 'clan_name'], rankingBoard.isClan ? tag : ''),
      subtitle,
      scoreFor(json, rankingBoard),
      rankingBoard.isClan ? badgeUrl || ImageAssets.clanCastle : playerImage,
      rankingBoard.isClan
        ? rankingBoard.iconUrl
        : (rankedIcon ?? leagueIcon ?? rankingBoard.iconUrl),
      townHall,
      clanBadgeUrl,
    );
  }
}

function scoreFor(json: Record<string, unknown>, rankingBoard: RankingBoardValue): number {
  const keys =
    rankingBoard === RankingBoard.playerBuilder
      ? ['builderBaseTrophies', 'builder_base_trophies', 'versusTrophies', 'trophies']
      : rankingBoard === RankingBoard.playerRanked
        ? ['league_trophies', 'leagueTrophies', 'trophies']
        : rankingBoard === RankingBoard.clanHome
          ? ['clanPoints', 'clan_points']
          : rankingBoard === RankingBoard.clanBuilder
            ? [
                'clanBuilderBasePoints',
                'builderBasePoints',
                'clanVersusPoints',
                'clan_builder_base_points',
              ]
            : rankingBoard === RankingBoard.clanCapital
              ? ['clanCapitalPoints', 'capitalPoints', 'clan_capital_points']
              : rankingBoard === RankingBoard.clanDonations
                ? ['donations', 'troops_donated']
                : rankingBoard === RankingBoard.clanWarWins
                  ? ['war_wins', 'warWins']
                  : rankingBoard === RankingBoard.clanWinStreak
                    ? ['war_win_streak', 'warWinStreak']
                    : ['trophies'];
  return firstInt(json, keys);
}

function firstInt(json: Record<string, unknown>, keys: readonly string[]): number {
  for (const key of keys) {
    const value = asIntOrNull(json[key]);
    if (value !== null) return value;
  }
  return 0;
}

function asIntOrNull(value: unknown): number | null {
  if (typeof value === 'number' && Number.isFinite(value)) return Math.trunc(value);
  const text = String(value ?? '');
  if (!/^[+-]?\d+$/.test(text)) return null;
  const parsed = Number.parseInt(text, 10);
  return Number.isNaN(parsed) ? null : parsed;
}

function firstString(
  json: Record<string, unknown>,
  keys: readonly string[],
  fallback = '',
): string {
  for (const key of keys) {
    const value = stringValue(json[key]);
    if (value) return value;
  }
  return fallback;
}

function nestedString(raw: unknown, path: string): string | null {
  let current = raw;
  for (const segment of path.split('.')) {
    if (!isRecord(current)) return null;
    current = current[segment];
  }
  const value = stringValue(current);
  return value || null;
}

function stringValue(value: unknown): string {
  return value == null ? '' : String(value).trim();
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
