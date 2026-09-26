import {
  armySetupQuery,
  StatsArmiesQuery,
  StatsArmiesResponse,
  StatsAudience,
  StatsClanCountsResponse,
  StatsCwlQuery,
  StatsCwlResponse,
  StatsDateFilter,
  StatsLegendCohort,
  StatsLegendQuery,
  StatsLegendResponse,
  StatsTroopStatsResponse,
  StatsPerformanceResponse,
  StatsPlayerCountsResponse,
  StatsSection,
  StatsWarQuery,
  statsSections,
  type StatsAudienceValue,
  type StatsArmySetupResponse,
  type StatsArmySetupTimelineResponse,
  type StatsItemQuantityFilter,
  type StatsLegendCohortValue,
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
const statsCacheLifetimeMs = 60 * 60 * 1000;

export class StatsProvider {
  private readonly listeners = new Set<() => void>();
  private readonly states = new Map<StatsSectionValue, StatsLoadState>();
  private readonly requestVersions = new Map<StatsSectionValue, number>();
  private readonly armySetupStates = new Map<string, StatsLoadState>();
  private revision = 0;
  audience: StatsAudienceValue = StatsAudience.battle;
  section: StatsSectionValue = StatsSection.war;
  private readonly sectionDates = new Map<StatsSectionValue, StatsDateFilter>();
  readonly chartGranularities = new Map<StatsSectionValue, 'day' | 'week' | 'month'>();
  private readonly defaultDates: StatsDateFilter;
  get dates(): StatsDateFilter {
    return this.datesFor(this.section);
  }
  set dates(value: StatsDateFilter) {
    this.sectionDates.set(this.section, value);
  }
  datesFor(section: StatsSectionValue): StatsDateFilter {
    return this.sectionDates.get(section) ?? this.defaultDates;
  }
  warDates: StatsDateFilter;
  cwlDates: StatsDateFilter;
  armiesTownHall?: number;
  armiesLeagueTier?: number;
  armiesMinimumSample = 100;
  armiesLimit = 25;
  armiesSortBy: StatsArmiesQuery['sortBy'] = 'usage';
  armiesInclude: readonly StatsItemQuantityFilter[] = [];
  armiesExclude: readonly string[] = [];
  armyRankLimit?: 200 | 1000;
  armySetupSort: 'usage' | 'tripleRate' = 'usage';
  legendCohort: StatsLegendCohortValue = StatsLegendCohort.legend;
  warTownHall?: number;
  warOpponentTownHall?: number;
  warEqualTownHalls = true;
  cwlTownHall?: number;
  cwlOpponentTownHall?: number;
  cwlEqualTownHalls = true;
  cwlLeagueId?: number;
  cwlSeasons: readonly string[] = [];
  cwlSeason?: string;
  cwlLatestSeason?: string;
  rankedTownHall = 18;
  rankedLeagueTier = 105000036;

  constructor(
    private readonly repository: StatsRepositoryContract,
    private readonly now = () => new Date(),
  ) {
    const today = day(this.now());
    this.defaultDates = new StatsDateFilter(addDays(today, -89), today);
    this.warDates = this.defaultDates;
    this.cwlDates = new StatsDateFilter(
      new Date(today.getFullYear(), today.getMonth() - 1, 1),
      new Date(today.getFullYear(), today.getMonth(), 0),
    );
  }
  subscribe(listener: () => void): () => void {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }
  getSnapshot = (): number => this.revision;
  dispose(): void {
    this.listeners.clear();
    for (const section of statsSections) {
      this.requestVersions.set(section, (this.requestVersions.get(section) ?? 0) + 1);
      const state = this.states.get(section);
      if (state?.status === StatsLoadStatus.loading) this.states.delete(section);
      else if (state?.isRefreshing) this.states.set(section, { ...state, isRefreshing: false });
    }
  }
  stateFor(value: StatsSectionValue): StatsLoadState {
    return this.states.get(value) ?? idleState;
  }
  get currentState(): StatsLoadState {
    return this.stateFor(this.section);
  }
  ensureLoaded(): void {
    void this.load(this.section);
  }
  selectSection(value: StatsSectionValue): void {
    if (this.section === value) return;
    this.section = value;
    this.audience =
      value === StatsSection.players || value === StatsSection.clans
        ? StatsAudience.world
        : StatsAudience.battle;
    this.notify();
    void this.load(value);
  }
  selectAudience(value: StatsAudienceValue): void {
    if (this.audience === value) return;
    this.audience = value;
    this.section = value === StatsAudience.battle ? StatsSection.war : StatsSection.players;
    this.notify();
    void this.load(this.section);
  }
  async setDates(start: Date, end: Date): Promise<void> {
    const next = new StatsDateFilter(day(start), day(end));
    if (!Number.isFinite(next.inclusiveDays) || next.inclusiveDays < 1 || next.inclusiveDays > 90)
      throw new RangeError('Stats date ranges must contain 1 to 90 days.');
    this.dates = next;
    this.invalidate(this.section);
    if (this.section === StatsSection.armies) this.armySetupStates.clear();
    this.notify();
    await this.load(this.section);
  }
  async setWarDates(start: Date, end: Date): Promise<void> {
    const next = new StatsDateFilter(day(start), day(end));
    if (
      !Number.isFinite(next.inclusiveDays) ||
      next.inclusiveDays < 1 ||
      next.inclusiveDays > 20000
    )
      throw new RangeError('Invalid war date range.');
    this.warDates = next;
    this.requestVersions.set(
      StatsSection.war,
      (this.requestVersions.get(StatsSection.war) ?? 0) + 1,
    );
    this.states.delete(StatsSection.war);
    this.notify();
    await this.load(StatsSection.war);
  }
  updateArmiesFilters(value: {
    townHall?: number | null;
    leagueTier?: number | null;
    minimumSample?: number;
    limit?: number;
    sortBy?: StatsArmiesQuery['sortBy'];
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
  updateArmySetupFilters(value: {
    rankLimit?: 200 | 1000 | null;
    sort?: 'usage' | 'tripleRate';
  }): void {
    const previousKey = this.armySetupKey();
    const nextRankLimit =
      value.rankLimit === null ? undefined : (value.rankLimit ?? this.armyRankLimit);
    const nextSort = value.sort ?? this.armySetupSort;
    if (nextRankLimit === this.armyRankLimit && nextSort === this.armySetupSort) return;
    const previousState = this.states.get(StatsSection.armies);
    if (previousState?.data && previousState.status !== StatsLoadStatus.loading)
      this.armySetupStates.set(previousKey, { ...previousState, isRefreshing: false });
    this.armyRankLimit = nextRankLimit;
    this.armySetupSort = nextSort;
    this.requestVersions.set(
      StatsSection.armies,
      (this.requestVersions.get(StatsSection.armies) ?? 0) + 1,
    );
    const cached = this.armySetupStates.get(this.armySetupKey());
    if (cached) this.states.set(StatsSection.armies, cached);
    else this.states.delete(StatsSection.armies);
    this.notify();
    void this.load(StatsSection.armies);
  }
  private armySetupKey(): string {
    const dates = this.datesFor(StatsSection.armies);
    return `${dates.start.getTime()}:${dates.end.getTime()}:${this.armyRankLimit ?? 'all'}:${this.armySetupSort}`;
  }
  loadArmySetupVariants(groupKey: string, fresh = false): Promise<StatsArmySetupResponse> {
    return this.repository.loadArmySetups(
      armySetupQuery(
        this.datesFor(StatsSection.armies),
        this.armyRankLimit,
        groupKey,
        undefined,
        this.armySetupSort,
      ),
      fresh,
    );
  }
  loadArmySetupTimeline(
    groupKey: string,
    variantKey?: string,
    fresh = false,
  ): Promise<StatsArmySetupTimelineResponse> {
    return this.repository.loadArmySetupTimeline(
      armySetupQuery(
        this.datesFor(StatsSection.armies),
        this.armyRankLimit,
        groupKey,
        variantKey,
        this.armySetupSort,
      ),
      fresh,
    );
  }
  updateLegendCohort(value: StatsLegendCohortValue): void {
    if (this.legendCohort === value) return;
    this.legendCohort = value;
    this.invalidate(StatsSection.items);
    this.invalidate(StatsSection.armies);
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
  setCwlSeason(season?: string): void {
    if (this.cwlSeason === season) return;
    this.cwlSeason = season;
    this.invalidate(StatsSection.cwl);
    this.notify();
    void this.load(StatsSection.cwl);
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
        ((old.status === StatsLoadStatus.data || old.status === StatsLoadStatus.empty) &&
          old.updatedAt != null &&
          this.now().getTime() - old.updatedAt.getTime() < statsCacheLifetimeMs))
    )
      return;
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
      const data = await this.loadSection(target, force);
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
  private loadSection(target: StatsSectionValue, fresh: boolean): Promise<object> {
    const dates = this.datesFor(target);
    switch (target) {
      case StatsSection.players:
        return this.repository.loadPlayerCounts(fresh);
      case StatsSection.clans:
        return this.repository.loadClanCounts(fresh);
      case StatsSection.armies:
        return this.repository.loadArmySetups(
          armySetupQuery(dates, this.armyRankLimit, undefined, undefined, this.armySetupSort),
          fresh,
        );
      case StatsSection.items:
        return Promise.allSettled([
          this.repository.loadItems(new StatsLegendQuery(dates, StatsLegendCohort.legend), fresh),
          this.repository.loadItems(new StatsLegendQuery(dates, StatsLegendCohort.top1000), fresh),
          this.repository.loadItems(new StatsLegendQuery(dates, StatsLegendCohort.top200), fresh),
        ]).then(([legend, top1000, top200]) => {
          if (legend.status === 'rejected') throw legend.reason;
          return new StatsTroopStatsResponse(
            legend.value,
            top1000.status === 'fulfilled' ? top1000.value : null,
            top200.status === 'fulfilled' ? top200.value : null,
          );
        });
      case StatsSection.war:
        return this.repository.loadWar(
          new StatsWarQuery(
            this.warDates,
            this.warTownHall,
            this.warOpponentTownHall,
            this.warEqualTownHalls,
          ),
          fresh,
        );
      case StatsSection.cwl:
        return this.repository.loadCwl(new StatsCwlQuery(this.cwlSeason), fresh).then((data) => {
          if (this.cwlSeason == null) this.cwlLatestSeason = data.season ?? undefined;
          return data;
        });
      case StatsSection.ranked:
        return this.repository.loadItems(
          new StatsLegendQuery(dates, StatsLegendCohort.legend),
          fresh,
        );
    }
  }
  private invalidate(target: StatsSectionValue): void {
    this.requestVersions.set(target, (this.requestVersions.get(target) ?? 0) + 1);
    this.states.delete(target);
  }
  private notify(): void {
    this.revision += 1;
    for (const listener of this.listeners) listener();
  }
}
function isEmpty(value: object): boolean {
  if (value instanceof StatsTroopStatsResponse) return value.legend.items.length === 0;
  if (value instanceof StatsLegendResponse) return value.items.length === 0;
  if (value instanceof StatsPerformanceResponse) return !value.metrics.available;
  if (value instanceof StatsCwlResponse) return value.items.length === 0;
  if (value instanceof StatsPlayerCountsResponse)
    return value.townHalls.length + value.leagueTiers.length === 0;
  if (value instanceof StatsClanCountsResponse)
    return (
      value.locations.length +
        value.cwlLeagues.length +
        value.capitalLeagues.length +
        (value.memberBins?.length ?? 0) ===
      0
    );
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
