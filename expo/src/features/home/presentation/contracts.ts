export type HomePlatform = 'ios' | 'android' | 'web';

export interface HomeAccountIdentity {
  readonly tag: string;
  readonly name: string;
  readonly subtitle: string;
  readonly imageUrl: string;
}

export type HomeMetricKind =
  | 'legendAttacks'
  | 'warAttacks'
  | 'cwlAttacks'
  | 'raidAttacks'
  | 'clanGames'
  | 'seasonPass'
  | 'rankedAttacks'
  | 'rankedDefenses'
  | 'builders'
  | 'laboratory'
  | 'pets'
  | 'walls';

export interface HomeMetricModel {
  readonly id: string;
  readonly kind: HomeMetricKind;
  readonly done: number;
  readonly total: number | null;
  readonly detail?: string;
  readonly meta?: string;
  readonly displayValue?: string;
}

export interface HomeTodoSummary {
  readonly account?: HomeAccountIdentity;
  readonly status: string;
  readonly metrics: readonly HomeMetricModel[];
  readonly done: number;
  readonly total: number;
}

export interface HomeTodoCardModel {
  readonly accounts: readonly HomeTodoSummary[];
  readonly combined?: HomeTodoSummary;
}

export interface HomeRankedAccount extends HomeAccountIdentity {
  readonly tierIconUrl: string;
  readonly trophies: number;
  readonly rank: number | null;
  readonly attacksDone: number;
  readonly defensesDone: number;
  readonly maxBattles: number | null;
}

export type HomeRankedCardModel =
  | { readonly state: 'loading'; readonly configuredCount: number }
  | { readonly state: 'empty'; readonly configuredCount: number }
  | {
      readonly state: 'ready';
      readonly configuredCount: number;
      readonly accounts: readonly HomeRankedAccount[];
    };

export interface HomeUpgradeAccount extends HomeAccountIdentity {
  readonly completion: number;
  readonly capturedAt: Date;
  readonly needsUpdate: boolean;
  readonly hasActionableQueueWork: boolean;
  readonly builderProjectedSeconds: number;
  readonly labProjectedSeconds: number;
  readonly petProjectedSeconds: number;
  readonly activeBuilders: number;
  readonly totalBuilders: number;
  readonly labActive: boolean;
  readonly hasLab: boolean;
  readonly petsActive: boolean;
  readonly hasPets: boolean;
  readonly wallsAtMax: number;
  readonly wallsTotal: number;
}

export interface HomeMissingUpgradeAccount extends HomeAccountIdentity {
  readonly townHallLevel: number;
}

export interface HomeUpgradeCombined {
  readonly completion: number;
  readonly status: string;
  readonly builderProjectedSeconds: number;
  readonly labProjectedSeconds: number;
  readonly petProjectedSeconds: number;
  readonly activeBuilders: number;
  readonly totalBuilders: number;
  readonly activeLabs: number;
  readonly totalLabs: number;
  readonly activePets: number;
  readonly totalPets: number;
}

export type HomeUpgradeCardModel =
  | { readonly state: 'loading'; readonly configuredCount: number }
  | { readonly state: 'empty'; readonly configuredCount: number }
  | {
      readonly state: 'ready';
      readonly configuredCount: number;
      readonly accounts: readonly HomeUpgradeAccount[];
      readonly missingAccounts: readonly HomeMissingUpgradeAccount[];
      readonly combined: HomeUpgradeCombined;
    };

export interface HomeAnnouncement {
  readonly id: string;
  readonly title: string;
  readonly subtitle: string;
  readonly imageUrl?: string;
  readonly storyUrl?: string;
  readonly html?: string;
  readonly htmlUrl?: string;
  readonly startsAt?: Date;
}

export interface HomeDashboardModel {
  readonly loading: boolean;
  readonly linkedAccountCount: number;
  readonly lastRefresh?: Date;
  readonly announcements: readonly HomeAnnouncement[];
  readonly todo?: HomeTodoCardModel;
  readonly ranked?: HomeRankedCardModel;
  readonly upgrade?: HomeUpgradeCardModel;
  readonly upgradeTrackerEnabled: boolean;
}

export interface HomeDashboardActions {
  refresh(): Promise<void>;
  showRefreshError(message: string): void;
  openManageAccounts(): void;
  openAnnouncement(announcement: HomeAnnouncement): void;
  openTodo(): void;
  openRanked(playerTag: string): void;
  openUpgradeTracker(playerTag: string): void;
}

export type HomeCardId = 'todo' | 'ranked' | 'upgrade';

export function visibleHomeCards(model: HomeDashboardModel): HomeCardId[] {
  const cards: HomeCardId[] = [];
  if (model.todo && model.todo.accounts.length > 0) cards.push('todo');
  if (model.ranked) cards.push('ranked');
  if (model.upgradeTrackerEnabled && model.upgrade) cards.push('upgrade');
  return cards;
}

export function isDesktopHome(platform: HomePlatform, width: number): boolean {
  return platform === 'web' && width >= 900;
}

export function homeContentWidth(width: number): number {
  return width >= 1600 ? 1680 : 1320;
}
export function homeRecapWidth(width: number): number {
  return width >= 1600 ? 1560 : 1120;
}

export function homeComparisonCardWidth(
  availableWidth: number,
  itemCount: number,
  hasSummaryItem = false,
): number {
  if (itemCount <= 1) return Math.min(availableWidth, 552);
  const gap = 16;
  const slotsWithoutNavigation = Math.max(
    1,
    Math.min(itemCount, Math.floor((availableWidth + gap) / (270 + gap))),
  );
  const regularSlots =
    availableWidth < 1400 ? Math.min(3, slotsWithoutNavigation) : slotsWithoutNavigation;
  const navigation = itemCount > regularSlots ? 88 : 0;
  const cardSpace = Math.max(0, availableWidth - navigation);
  let slots = Math.max(
    1,
    Math.min(itemCount, Math.floor((cardSpace + gap) / ((navigation ? 240 : 270) + gap))),
  );
  if (navigation) slots = Math.min(3, slots);
  if (hasSummaryItem) slots = Math.max(2, slots);
  return Math.min(360, Math.max(0, (cardSpace - gap * (slots - 1)) / slots));
}

export function homeComparisonNeedsNavigation(availableWidth: number, itemCount: number): boolean {
  if (itemCount <= 1) return false;
  const gap = 16;
  const slots = Math.max(1, Math.min(itemCount, Math.floor((availableWidth + gap) / (270 + gap))));
  return itemCount > (availableWidth < 1400 ? Math.min(3, slots) : slots);
}

export function normalizedProgress(done: number, total: number | null): number | null {
  if (total === null || total <= 0) return null;
  return Math.max(0, Math.min(1, done / total));
}
