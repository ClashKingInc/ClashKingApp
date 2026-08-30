import {
  StatsArmiesQuery,
  StatsArmiesResponse,
  StatsAudience,
  StatsBattleFilters,
  StatsClanCountsResponse,
  StatsCwlQuery,
  StatsDateFilter,
  StatsItemsQuery,
  StatsItemsResponse,
  StatsPerformanceResponse,
  StatsPlayerCountsResponse,
  StatsRankedQuery,
  StatsSection,
  StatsWarQuery,
  statsSections,
  type StatsAudienceValue,
  type StatsItemQuantityFilter,
  type StatsItemSelector,
  type StatsSectionValue,
} from '../models';
import type { StatsRepositoryContract } from './stats-repository';

export const StatsLoadStatus = {
  idle: 'idle',
  loading: 'loading',
  data: 'data',
  empty: 'empty',
  error: 'error',
} as const;
export type StatsLoadStatusValue = (typeof StatsLoadStatus)[keyof typeof StatsLoadStatus];
export interface StatsLoadState {
  readonly status: StatsLoadStatusValue;
  readonly data?: object;
  readonly error?: unknown;
  readonly updatedAt?: Date;
  readonly isRefreshing: boolean;
}
const idleState: StatsLoadState = { status: StatsLoadStatus.idle, isRefreshing: false };

export class StatsProvider {
  private readonly listeners = new Set<() => void>();
  private readonly states = new Map<StatsSectionValue, StatsLoadState>();
  private readonly requestVersions = new Map<StatsSectionValue, number>();
  audience: StatsAudienceValue = StatsAudience.battle;
  section: StatsSectionValue = StatsSection.ranked;
  dates: StatsDateFilter;
  armiesTownHall?: number;
  armiesLeagueTier?: number;
  armiesMinimumSample = 100;
  armiesLimit = 25;
  armiesSortBy = 'usage_rate';
  armiesInclude: readonly StatsItemQuantityFilter[] = [];
  armiesExclude: readonly string[] = [];
  itemsTownHall?: number;
  itemsLeagueTier?: number;
  itemSelectors: readonly StatsItemSelector[] = [];
  warTownHall?: number;
  warOpponentTownHall?: number;
  warEqualTownHalls = true;
  cwlTownHall?: number;
  cwlOpponentTownHall?: number;
  cwlEqualTownHalls = true;
  cwlLeagueId?: number;
  cwlSeasons: readonly string[] = [];
  rankedTownHall = 18;
  rankedLeagueTier = 1;

  constructor(
    private readonly repository: StatsRepositoryContract,
    private readonly now = () => new Date(),
  ) {
    const today = day(this.now());
    this.dates = new StatsDateFilter(addDays(today, -29), today);
  }
  subscribe(listener: () => void): () => void {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }
  dispose(): void {
    this.listeners.clear();
    for (const section of statsSections)
      this.requestVersions.set(section, (this.requestVersions.get(section) ?? 0) + 1);
  }
  stateFor(value: StatsSectionValue): StatsLoadState {
    return this.states.get(value) ?? idleState;
  }
  get currentState(): StatsLoadState {
    return this.stateFor(this.section);
  }
  ensureLoaded(): void {
    if (this.currentState.status === StatsLoadStatus.idle) void this.load(this.section);
  }
  selectSection(value: StatsSectionValue): void {
    if (this.section === value) return;
    this.section = value;
    this.notify();
    if (this.stateFor(value).status === StatsLoadStatus.idle) void this.load(value);
  }
  selectAudience(value: StatsAudienceValue): void {
    if (this.audience === value) return;
    this.audience = value;
    this.section = value === StatsAudience.battle ? StatsSection.ranked : StatsSection.overview;
    this.notify();
    if (this.currentState.status === StatsLoadStatus.idle) void this.load(this.section);
  }
  async setDates(start: Date, end: Date): Promise<void> {
    const next = new StatsDateFilter(day(start), day(end));
    if (next.end < next.start || next.inclusiveDays > 90)
      throw new RangeError('Stats date ranges must contain 1 to 90 days.');
    this.dates = next;
    for (const section of statsSections)
      this.requestVersions.set(section, (this.requestVersions.get(section) ?? 0) + 1);
    this.states.clear();
    this.notify();
    await this.load(this.section);
  }
  updateArmiesFilters(value: {
    townHall?: number | null;
    leagueTier?: number | null;
    minimumSample?: number;
    limit?: number;
    sortBy?: string;
    include?: readonly StatsItemQuantityFilter[];
    exclude?: readonly string[];
  }): void {
    this.armiesTownHall =
      value.townHall === null ? undefined : (value.townHall ?? this.armiesTownHall);
    this.armiesLeagueTier =
      value.leagueTier === null ? undefined : (value.leagueTier ?? this.armiesLeagueTier);
    this.armiesMinimumSample = value.minimumSample ?? this.armiesMinimumSample;
    this.armiesLimit = value.limit ?? this.armiesLimit;
    this.armiesSortBy = value.sortBy ?? this.armiesSortBy;
    this.armiesInclude = value.include ?? this.armiesInclude;
    this.armiesExclude = value.exclude ?? this.armiesExclude;
    this.invalidate(StatsSection.armies);
    this.notify();
  }
  updateItemFilters(value: { townHall?: number | null; leagueTier?: number | null }): void {
    this.itemsTownHall =
      value.townHall === null ? undefined : (value.townHall ?? this.itemsTownHall);
    this.itemsLeagueTier =
      value.leagueTier === null ? undefined : (value.leagueTier ?? this.itemsLeagueTier);
    this.invalidate(StatsSection.items);
    this.notify();
  }
  setItemSelectors(value: readonly StatsItemSelector[]): void {
    this.itemSelectors = value.filter((item) => item.isValid);
    this.invalidate(StatsSection.items);
    this.notify();
  }
  updateWarFilters(value: {
    townHall?: number | null;
    opponentTownHall?: number | null;
    equalTownHalls?: boolean;
  }): void {
    this.warTownHall = value.townHall === null ? undefined : (value.townHall ?? this.warTownHall);
    this.warOpponentTownHall =
      value.opponentTownHall === null
        ? undefined
        : (value.opponentTownHall ?? this.warOpponentTownHall);
    this.warEqualTownHalls = value.equalTownHalls ?? this.warEqualTownHalls;
    this.invalidate(StatsSection.war);
    this.notify();
  }
  updateCwlFilters(value: {
    townHall?: number | null;
    opponentTownHall?: number | null;
    equalTownHalls?: boolean;
    leagueId?: number | null;
    seasons?: readonly string[];
  }): void {
    this.cwlTownHall = value.townHall === null ? undefined : (value.townHall ?? this.cwlTownHall);
    this.cwlOpponentTownHall =
      value.opponentTownHall === null
        ? undefined
        : (value.opponentTownHall ?? this.cwlOpponentTownHall);
    this.cwlEqualTownHalls = value.equalTownHalls ?? this.cwlEqualTownHalls;
    this.cwlLeagueId = value.leagueId === null ? undefined : (value.leagueId ?? this.cwlLeagueId);
    this.cwlSeasons = value.seasons ?? this.cwlSeasons;
    this.invalidate(StatsSection.cwl);
    this.notify();
  }
  updateRankedFilters(value: { townHall: number; leagueTier: number }): void {
    this.rankedTownHall = value.townHall;
    this.rankedLeagueTier = value.leagueTier;
    this.invalidate(StatsSection.ranked);
    this.notify();
  }
  refresh(): Promise<void> {
    return this.load(this.section, true);
  }
  async load(target: StatsSectionValue, force = false): Promise<void> {
    const old = this.stateFor(target);
    if (
      !force &&
      (old.status === StatsLoadStatus.loading ||
        old.status === StatsLoadStatus.data ||
        old.status === StatsLoadStatus.empty)
    )
      return;
    if (target === StatsSection.items && this.itemSelectors.length === 0) {
      this.states.set(target, { status: StatsLoadStatus.empty, isRefreshing: false });
      this.notify();
      return;
    }
    const version = (this.requestVersions.get(target) ?? 0) + 1;
    this.requestVersions.set(target, version);
    this.states.set(target, {
      status: old.data ? old.status : StatsLoadStatus.loading,
      ...(old.data ? { data: old.data } : {}),
      ...(old.updatedAt ? { updatedAt: old.updatedAt } : {}),
      isRefreshing: old.data != null,
    });
    this.notify();
    try {
      const data = await this.loadSection(target);
      if (this.requestVersions.get(target) !== version) return;
      this.states.set(target, {
        status: isEmpty(data) ? StatsLoadStatus.empty : StatsLoadStatus.data,
        data,
        updatedAt: this.now(),
        isRefreshing: false,
      });
    } catch (error) {
      if (this.requestVersions.get(target) !== version) return;
      this.states.set(target, {
        status: old.data ? old.status : StatsLoadStatus.error,
        ...(old.data ? { data: old.data } : {}),
        error,
        ...(old.updatedAt ? { updatedAt: old.updatedAt } : {}),
        isRefreshing: false,
      });
    }
    this.notify();
  }
  private loadSection(target: StatsSectionValue): Promise<object> {
    switch (target) {
      case StatsSection.overview:
        return this.repository.loadOverview(this.dates);
      case StatsSection.players:
        return this.repository.loadPlayerCounts();
      case StatsSection.clans:
        return this.repository.loadClanCounts();
      case StatsSection.armies:
        return this.repository.loadArmies(
          new StatsArmiesQuery(
            new StatsBattleFilters(
              this.dates,
              this.armiesTownHall,
              undefined,
              undefined,
              this.armiesLeagueTier,
              this.armiesInclude,
              this.armiesExclude,
              this.armiesMinimumSample,
            ),
            this.armiesLimit,
            this.armiesSortBy,
          ),
        );
      case StatsSection.items:
        return this.repository.loadItems(
          new StatsItemsQuery(
            new StatsBattleFilters(
              this.dates,
              this.itemsTownHall,
              undefined,
              undefined,
              this.itemsLeagueTier,
            ),
            this.itemSelectors,
          ),
        );
      case StatsSection.war:
        return this.repository.loadWar(
          new StatsWarQuery(
            this.dates,
            this.warTownHall,
            this.warOpponentTownHall,
            this.warEqualTownHalls,
          ),
        );
      case StatsSection.cwl:
        return this.repository.loadCwl(
          new StatsCwlQuery(
            this.dates,
            this.cwlTownHall,
            this.cwlOpponentTownHall,
            this.cwlEqualTownHalls,
            this.cwlLeagueId,
            this.cwlSeasons,
          ),
        );
      case StatsSection.ranked:
        return this.repository.loadRanked(
          new StatsRankedQuery(this.dates, this.rankedTownHall, this.rankedLeagueTier),
        );
    }
  }
  private invalidate(target: StatsSectionValue): void {
    this.requestVersions.set(target, (this.requestVersions.get(target) ?? 0) + 1);
    this.states.delete(target);
  }
  private notify(): void {
    for (const listener of this.listeners) listener();
  }
}
function isEmpty(value: object): boolean {
  if (value instanceof StatsItemsResponse) return value.items.length === 0;
  if (value instanceof StatsPerformanceResponse) return !value.metrics.available;
  if (value instanceof StatsPlayerCountsResponse)
    return value.townHalls.length + value.builderHalls.length + value.leagueTiers.length === 0;
  if (value instanceof StatsClanCountsResponse)
    return value.locations.length + value.cwlLeagues.length + value.capitalLeagues.length === 0;
  if (value instanceof StatsArmiesResponse) return false;
  return false;
}
function day(value: Date): Date {
  return new Date(value.getFullYear(), value.getMonth(), value.getDate());
}
function addDays(value: Date, amount: number): Date {
  const next = new Date(value);
  next.setDate(next.getDate() + amount);
  return next;
}
