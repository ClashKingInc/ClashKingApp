import type { Achievement } from '../../achievements/models';
import type { WarCwl, WarInfo } from '../../war/models';
import type {
  Player,
  PlayerActivityFeed,
  PlayerBattlelogData,
  PlayerCwlHistory,
  PlayerJoinLeavePage,
  PlayerJoinLeaveTotal,
  PlayerHistoryTypeValue,
  PlayerWarStats,
  WarStatsFilter,
} from '../models';

export type PlayerDetailTabKey =
  'home' | 'builder' | 'battles' | 'history' | 'war' | 'cwl' | 'achievements' | 'joinLeave';

export interface PlayerCurrentCwl {
  readonly summary: WarCwl;
  readonly clanTag: string;
  readonly warLeagueName?: string;
}

export interface PlayerDetailPresentationModel {
  readonly player: Player;
  readonly bookmarked: boolean;
  /** True when the player belongs to the signed-in account list. */
  readonly linkedAccount?: boolean;
  readonly verifiedTracking: boolean;
  readonly battlelog?: PlayerBattlelogData | null;
  readonly activity?: PlayerActivityFeed | null;
  readonly cwlHistory?: PlayerCwlHistory | null;
  readonly warStats?: PlayerWarStats | null;
  readonly currentWar?: WarInfo | null;
  readonly currentCwl?: PlayerCurrentCwl | null;
  readonly cachedClanTag?: string | null;
  readonly joinLeave?: PlayerJoinLeavePage | null;
  readonly joinLeaveTotals?: readonly PlayerJoinLeaveTotal[] | null;
  readonly loadingTabs?: ReadonlySet<PlayerDetailTabKey>;
  readonly errorByTab?: Partial<Record<PlayerDetailTabKey, string>>;
}

export interface PlayerDetailPresentationActions {
  goBack(): void;
  loadTab(tab: PlayerDetailTabKey, force?: boolean): Promise<void>;
  loadActivity(type: PlayerHistoryTypeValue, force?: boolean): Promise<void>;
  loadMoreJoinLeave(): Promise<void>;
  toggleBookmark(player: Player): Promise<void>;
  openInGame(tag: string): void;
  copyTag(tag: string): Promise<void>;
  openClan(tag: string): void;
  openWar(war: WarInfo): void;
  openCwl(cwl: PlayerCurrentCwl): void;
  openPlayer(tag: string): void | Promise<void>;
  openRanked(player: Player): void;
  openAchievements(achievement?: Achievement): void;
  updateWarFilter(filter: WarStatsFilter): Promise<void>;
  exportWarStats(filter: WarStatsFilter): Promise<string>;
  loadWarFilterPresets(): Promise<readonly { name: string; filter: WarStatsFilter }[]>;
  saveWarFilterPresets(presets: readonly { name: string; filter: WarStatsFilter }[]): Promise<void>;
  showMessage(message: string): void;
}

export interface PlayerDetailRootProps {
  readonly player: Player;
  readonly service: {
    readonly apiV2Url: string;
    loadPlayerBattlelog(tag: string, force?: boolean): Promise<PlayerBattlelogData>;
    loadPlayerActivity(
      tag: string,
      type?: PlayerHistoryTypeValue,
      force?: boolean,
    ): Promise<PlayerActivityFeed>;
    loadPlayerCwlHistory(tag: string, force?: boolean): Promise<PlayerCwlHistory>;
    loadPlayerWarStatsWithFilter(
      tag: string,
      filter: WarStatsFilter,
    ): Promise<PlayerWarStats | null>;
    loadPlayerJoinLeave(tag: string, before?: Date | null): Promise<PlayerJoinLeavePage>;
    loadPlayerJoinLeaveTotals(tag: string): Promise<readonly PlayerJoinLeaveTotal[]>;
    loadCachedClanTag(tag: string): Promise<string>;
    loadWarFilterPresets(): Promise<readonly { name: string; filter: WarStatsFilter }[]>;
    saveWarFilterPresets(
      presets: readonly { name: string; filter: WarStatsFilter }[],
    ): Promise<void>;
  };
  readonly actions: Omit<
    PlayerDetailPresentationActions,
    | 'loadTab'
    | 'loadActivity'
    | 'loadMoreJoinLeave'
    | 'updateWarFilter'
    | 'exportWarStats'
    | 'loadWarFilterPresets'
    | 'saveWarFilterPresets'
  >;
  readonly bookmarked?: boolean;
  readonly linkedAccount?: boolean;
  readonly verifiedTracking?: boolean;
  readonly currentWar?: WarInfo | null;
  readonly currentCwl?: PlayerCurrentCwl | null;
  readonly initialTab?: PlayerDetailTabKey;
}
