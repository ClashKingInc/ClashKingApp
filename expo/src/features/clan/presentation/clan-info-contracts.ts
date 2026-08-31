import type { Player } from '../../player/models/player';
import type { WarInfo } from '../../war/models';
import type {
  Clan,
  ClanJoinLeave,
  ClanLeaderboardHistory,
  ClanLeaderboardHistorySummary,
  ClanLeaderboardTypeValue,
  ClanLegendHistory,
  ClanLegendHistorySummary,
  ClanProfileHistory,
  ClanRecords,
  ClanWarLog,
  ClanWarStats,
  CwlRankingHistoryEntry,
} from '../models';
import type { ClanWarStatsFilter } from '../models/clan-war-stats-filter';

export type ClanInfoTabKey =
  | 'members'
  | 'warLog'
  | 'joinLeave'
  | 'statistics'
  | 'rankings'
  | 'cwlHistory'
  | 'leaderboardHistory'
  | 'legendHistory'
  | 'records';

export type ClanInfoFeatureFlags = Readonly<Partial<Record<ClanInfoTabKey, boolean>>>;

export interface ClanInfoPresentationModel {
  readonly clan: Clan;
  readonly bookmarked: boolean;
  readonly activeUserTags: ReadonlySet<string>;
  readonly featureFlags?: ClanInfoFeatureFlags;
  readonly ongoingWar?: 'war' | 'cwl';
  /** Mirrors Flutter's nullable CWL ranking tile tap target. */
  readonly hasCwlLeagueData?: boolean;
}

export interface ClanInfoPresentationActions {
  goBack(): void;
  copyClanTag(tag: string): Promise<void>;
  toggleClanBookmark(clan: Clan): Promise<void>;
  openClanInGame(clan: Clan): void;
  openDiscord(inviteCode: string): Promise<void>;
  openWar(clan: Clan): void;
  openHistoricalWar(war: WarInfo): void;
  openCwl(clan: Clan): void;
  openCapital(clan: Clan): void;
  showMessage(message: string): void;
  loadPlayer(tag: string): Promise<Player>;
  openPlayer(player: Player): void;
  loadJoinLeave(clan: Clan): Promise<ClanJoinLeave>;
  loadMoreJoinLeave(clan: Clan, current: ClanJoinLeave): Promise<ClanJoinLeave>;
  loadWarLog(clan: Clan): Promise<ClanWarLog | null>;
  loadWarStats(clan: Clan, filter: ClanWarStatsFilter): Promise<ClanWarStats>;
  loadCwlHistory(clanTag: string): Promise<readonly CwlRankingHistoryEntry[]>;
  loadLeaderboardSummary(
    clanTag: string,
    type: ClanLeaderboardTypeValue,
  ): Promise<ClanLeaderboardHistorySummary>;
  loadLeaderboardHistory(
    clanTag: string,
    type: ClanLeaderboardTypeValue,
    after: Date,
    before: Date,
  ): Promise<ClanLeaderboardHistory>;
  loadLegendSummary(clanTag: string): Promise<ClanLegendHistorySummary>;
  loadLegendHistory(clanTag: string, after: Date, before: Date): Promise<ClanLegendHistory>;
  loadRecords(clanTag: string): Promise<ClanRecords>;
  loadProfileHistory(clanTag: string): Promise<ClanProfileHistory>;
}

export const clanInfoTabOrder: readonly ClanInfoTabKey[] = [
  'members',
  'warLog',
  'joinLeave',
  'statistics',
  'rankings',
  'cwlHistory',
  'leaderboardHistory',
  'legendHistory',
  'records',
];

export function visibleClanInfoTabs(flags?: ClanInfoFeatureFlags): ClanInfoTabKey[] {
  return clanInfoTabOrder.filter((tab) => flags?.[tab] !== false);
}

export function extractDiscordInviteCode(description: string): string | null {
  const match = description
    .replace(/[\s\n\r]/g, ' ')
    .match(/(?:https?:\/\/)?(?:discord\.com\/invite\/|discord\.gg\/)([a-zA-Z0-9]+)/);
  return match?.[1] ?? null;
}
