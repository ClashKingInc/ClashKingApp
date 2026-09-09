import type {
  ArmySearchEndpoint,
  EndpointRequest,
  StatsCwlEndpoint,
  StatsRankedEndpoint,
  StatsWarEndpoint,
} from '@clashking/api-contracts/expo';

type ArmySearchQueryContract = EndpointRequest<typeof ArmySearchEndpoint>['query'];
type StatsCwlQueryContract = EndpointRequest<typeof StatsCwlEndpoint>['query'];
interface StatsItemsQueryContract {
  readonly startDate?: string;
  readonly endDate?: string;
  readonly townHallLevel?: number;
  readonly opponentTownHallLevel?: number;
  readonly equalTownHalls?: boolean;
  readonly leagueTierId?: number;
  readonly includeItems?: readonly string[];
  readonly excludeItems?: readonly string[];
  readonly minimumSampleSize: number;
  readonly items: readonly string[];
}
type StatsRankedQueryContract = EndpointRequest<typeof StatsRankedEndpoint>['query'];
type StatsWarQueryContract = EndpointRequest<typeof StatsWarEndpoint>['query'];

export const StatsAudience = { battle: 'battle', world: 'world' } as const;
export type StatsAudienceValue = (typeof StatsAudience)[keyof typeof StatsAudience];
export const StatsSection = {
  ranked: 'ranked',
  armies: 'armies',
  items: 'items',
  war: 'war',
  cwl: 'cwl',
  overview: 'overview',
  players: 'players',
  clans: 'clans',
} as const;
export type StatsSectionValue = (typeof StatsSection)[keyof typeof StatsSection];
export const statsSections = Object.values(StatsSection);
export const StatsItemType = {
  troop: 'troop',
  spell: 'spell',
  hero: 'hero',
  pet: 'pet',
  equipment: 'equipment',
} as const;
export type StatsItemTypeValue = (typeof StatsItemType)[keyof typeof StatsItemType];
const armyItemIdentityPattern =
  /^(?:troop|super_troop|spell|siege_machine|hero|hero_equipment|pet):\d+$/u;

export function isArmyItemIdentity(value: string): boolean {
  return armyItemIdentityPattern.test(value.trim());
}

export class StatsDateFilter {
  constructor(
    readonly start: Date,
    readonly end: Date,
  ) {}
  get inclusiveDays(): number {
    return Math.round((utcDay(this.end) - utcDay(this.start)) / 86_400_000) + 1;
  }
  toQuery(): Pick<StatsRankedQueryContract, 'startDate' | 'endDate'> {
    return {
      startDate: StatsDateFilter.formatDate(this.start),
      endDate: StatsDateFilter.formatDate(this.end),
    };
  }
  static formatDate(value: Date): string {
    return `${value.getFullYear().toString().padStart(4, '0')}-${(value.getMonth() + 1).toString().padStart(2, '0')}-${value.getDate().toString().padStart(2, '0')}`;
  }
}
export class StatsItemQuantityFilter {
  constructor(
    readonly item: string,
    readonly minQuantity?: number,
    readonly maxQuantity?: number,
  ) {}
  toStatsQueryValue(): string {
    return [this.item.trim(), this.minQuantity, this.maxQuantity]
      .map((value) => value ?? '')
      .join(':')
      .replace(/:+$/u, '');
  }
  toArmyQueryValue(): string {
    const identity = this.item.trim();
    if (!isArmyItemIdentity(identity)) {
      throw new RangeError('Army items must use type:itemId.');
    }
    return [identity, this.minQuantity, this.maxQuantity]
      .map((value) => value ?? '')
      .join(':')
      .replace(/:+$/u, '');
  }
}
export class StatsBattleFilters {
  constructor(
    readonly dates: StatsDateFilter,
    readonly townHallLevel?: number,
    readonly opponentTownHallLevel?: number,
    readonly equalTownHalls?: boolean,
    readonly rankedLeagueTierId?: number,
    readonly includeItems: readonly StatsItemQuantityFilter[] = [],
    readonly excludeItems: readonly string[] = [],
    readonly minimumSampleSize = 100,
  ) {}
  toQuery(): Omit<StatsItemsQueryContract, 'items'> {
    return {
      ...this.dates.toQuery(),
      ...(this.townHallLevel == null ? {} : { townHallLevel: this.townHallLevel }),
      ...(this.opponentTownHallLevel == null
        ? {}
        : { opponentTownHallLevel: this.opponentTownHallLevel }),
      ...(this.equalTownHalls == null ? {} : { equalTownHalls: this.equalTownHalls }),
      ...(this.rankedLeagueTierId == null ? {} : { leagueTierId: this.rankedLeagueTierId }),
      ...(this.includeItems.length
        ? { includeItems: this.includeItems.map((item) => item.toStatsQueryValue()) }
        : {}),
      ...(this.excludeItems.length ? { excludeItems: [...this.excludeItems] } : {}),
      minimumSampleSize: this.minimumSampleSize,
    };
  }
}
export class StatsArmiesQuery {
  constructor(
    readonly filters: StatsBattleFilters,
    readonly limit = 25,
    readonly sortBy: NonNullable<ArmySearchQueryContract['sort']> = 'usage',
  ) {}
  toQuery(): ArmySearchQueryContract {
    const identities = this.filters.includeItems.map((item) => item.item.trim().split(':'));
    const heroIds = identities
      .filter(([type]) => type === 'hero')
      .map(([, id]) => id)
      .filter(Boolean);
    const equipmentIds = identities
      .filter(([type]) => type === 'hero_equipment')
      .map(([, id]) => id)
      .filter(Boolean);
    return {
      'time[after]': StatsDateFilter.formatDate(this.filters.dates.start),
      'time[before]': StatsDateFilter.formatDate(this.filters.dates.end),
      ...(heroIds.length ? { heroIds: heroIds.join(',') } : {}),
      ...(equipmentIds.length ? { equipmentIds: equipmentIds.join(',') } : {}),
      minimumAttacks: this.filters.minimumSampleSize,
      limit: this.limit,
      sort: this.sortBy,
      direction: 'desc',
    };
  }
}
export class StatsItemSelector {
  static readonly validEquipmentHeroes = new Set([
    'Barbarian King',
    'Archer Queen',
    'Grand Warden',
    'Royal Champion',
    'Minion Prince',
  ]);
  constructor(
    readonly item: string,
    readonly type: StatsItemTypeValue,
    readonly hero?: string,
  ) {}
  get isValid(): boolean {
    return (
      this.item.trim().length > 0 &&
      (this.type !== StatsItemType.equipment ||
        StatsItemSelector.validEquipmentHeroes.has(this.hero?.trim() ?? ''))
    );
  }
  toQueryValue(): string {
    return [this.type, this.item.trim(), this.hero?.trim()].filter(Boolean).join(':');
  }
}
export class StatsItemsQuery {
  constructor(
    readonly filters: StatsBattleFilters,
    readonly items: readonly StatsItemSelector[],
  ) {}
  toQuery(): StatsItemsQueryContract {
    return {
      ...this.filters.toQuery(),
      items: this.items.map((item) => item.toQueryValue()),
    };
  }
}
export class StatsRankedQuery {
  constructor(
    readonly dates: StatsDateFilter,
    readonly townHallLevel: number,
    readonly rankedLeagueTierId: number,
  ) {}
  toQuery(): StatsRankedQueryContract {
    return {
      ...this.dates.toQuery(),
      townHallLevel: this.townHallLevel,
      leagueTierId: this.rankedLeagueTierId,
    };
  }
}
export class StatsWarQuery {
  constructor(
    readonly dates: StatsDateFilter,
    readonly townHallLevel?: number,
    readonly opponentTownHallLevel?: number,
    readonly equalTownHalls = true,
  ) {}
  toQuery(): StatsWarQueryContract {
    return {
      ...this.dates.toQuery(),
      ...(this.townHallLevel == null ? {} : { townHallLevel: this.townHallLevel }),
      ...(this.opponentTownHallLevel == null
        ? {}
        : { opponentTownHallLevel: this.opponentTownHallLevel }),
      equalTownHalls: this.equalTownHalls,
    };
  }
}
export class StatsCwlQuery extends StatsWarQuery {
  constructor(
    dates: StatsDateFilter,
    townHallLevel?: number,
    opponentTownHallLevel?: number,
    equalTownHalls = true,
    readonly cwlLeagueId?: number,
    readonly seasons: readonly string[] = [],
  ) {
    super(dates, townHallLevel, opponentTownHallLevel, equalTownHalls);
  }
  override toQuery(): StatsCwlQueryContract {
    return {
      ...super.toQuery(),
      ...(this.cwlLeagueId == null ? {} : { cwlLeagueId: this.cwlLeagueId }),
      ...(this.seasons.length ? { seasons: [...this.seasons] } : {}),
    };
  }
}
export class StatsDateRange {
  constructor(
    readonly start: Date | null,
    readonly end: Date | null,
  ) {}
  static fromJson(value: unknown): StatsDateRange {
    const json = record(value);
    return new StatsDateRange(date(json.start), date(json.end));
  }
}
export class StatsDailyPoint {
  constructor(
    readonly date: string,
    readonly sampleSize: number,
    readonly averageStars: number,
    readonly averageDestruction: number,
    readonly zeroStarRate: number,
    readonly oneStarRate: number,
    readonly twoStarRate: number,
    readonly threeStarRate: number,
    readonly useCount?: number,
    readonly usageRate?: number,
  ) {}
  static fromJson(value: unknown): StatsDailyPoint {
    const j = record(value);
    return new StatsDailyPoint(
      text(j.date),
      integer(j.sampleSize),
      decimal(j.averageStars),
      decimal(j.averageDestruction),
      decimal(j.zeroStarRate),
      decimal(j.oneStarRate),
      decimal(j.twoStarRate),
      decimal(j.threeStarRate),
      optionalInteger(j.useCount),
      optionalDecimal(j.usageRate),
    );
  }
  static fromOverviewJson(value: unknown): StatsDailyPoint {
    const j = record(value);
    return new StatsDailyPoint(
      text(j.date),
      integer(j.sample_size),
      decimal(j.average_stars),
      decimal(j.average_destruction),
      decimal(j.zero_star_rate),
      decimal(j.one_star_rate),
      decimal(j.two_star_rate),
      decimal(j.three_star_rate),
      optionalInteger(j.use_count),
      optionalDecimal(j.usage_rate),
    );
  }
}
export class StatsMetrics {
  constructor(
    readonly available: boolean,
    readonly sampleSize: number,
    readonly averageStars: number,
    readonly averageDestruction: number,
    readonly zeroStarRate: number,
    readonly oneStarRate: number,
    readonly twoStarRate: number,
    readonly threeStarRate: number,
    readonly daily: readonly StatsDailyPoint[],
    readonly usageRate?: number,
  ) {}
  static fromJson(value: unknown): StatsMetrics {
    const j = record(value);
    return new StatsMetrics(
      j.available === true,
      integer(j.sampleSize),
      decimal(j.averageStars),
      decimal(j.averageDestruction),
      decimal(j.zeroStarRate),
      decimal(j.oneStarRate),
      decimal(j.twoStarRate),
      decimal(j.threeStarRate),
      list(j.daily).map(StatsDailyPoint.fromJson),
      optionalDecimal(j.usageRate),
    );
  }
  static fromOverviewJson(value: unknown): StatsMetrics {
    const j = record(value);
    return new StatsMetrics(
      j.available === true,
      integer(j.sample_size),
      decimal(j.average_stars),
      decimal(j.average_destruction),
      decimal(j.zero_star_rate),
      decimal(j.one_star_rate),
      decimal(j.two_star_rate),
      decimal(j.three_star_rate),
      list(j.daily).map(StatsDailyPoint.fromOverviewJson),
      optionalDecimal(j.usage_rate),
    );
  }
}
export class StatsGlobalCounts {
  constructor(
    readonly playersInWar: number,
    readonly clansInWar: number,
    readonly totalJoinLeaves: number,
    readonly playersInLegends: number,
    readonly playerCount: number,
    readonly clanCount: number,
    readonly warsStored: number,
  ) {}
  static fromJson(value: unknown): StatsGlobalCounts {
    const j = record(value);
    return new StatsGlobalCounts(
      integer(j.players_in_war),
      integer(j.clans_in_war),
      integer(j.total_join_leaves),
      integer(j.players_in_legends),
      integer(j.player_count),
      integer(j.clan_count),
      integer(j.wars_stored),
    );
  }
}
export class StatsGroupedCount {
  constructor(
    readonly id: number | null,
    readonly count: number,
  ) {}
  static fromJson(value: unknown, key: string): StatsGroupedCount {
    const j = record(value);
    return new StatsGroupedCount(j[key] == null ? null : integer(j[key]), integer(j.count));
  }
}
export class StatsPlayerCountsResponse {
  constructor(
    readonly townHalls: readonly StatsGroupedCount[],
    readonly leagueTiers: readonly StatsGroupedCount[],
  ) {}
}
export class StatsClanCountsResponse {
  constructor(
    readonly locations: readonly StatsGroupedCount[],
    readonly cwlLeagues: readonly StatsGroupedCount[],
    readonly capitalLeagues: readonly StatsGroupedCount[],
  ) {}
}
export function decodeStatsGroupedCounts(
  value: unknown,
  key: string,
): readonly StatsGroupedCount[] {
  return list(record(value).items).map((item) => StatsGroupedCount.fromJson(item, key));
}
export class StatsOverviewResponse {
  constructor(
    readonly dateRange: StatsDateRange,
    readonly counts: StatsGlobalCounts,
    readonly ranked: StatsMetrics,
    readonly war: StatsMetrics,
    readonly cwl: StatsMetrics,
  ) {}
  static fromJson(value: unknown): StatsOverviewResponse {
    const j = record(value);
    return new StatsOverviewResponse(
      StatsDateRange.fromJson(j.date_range),
      StatsGlobalCounts.fromJson(j.counts),
      StatsMetrics.fromOverviewJson(j.ranked),
      StatsMetrics.fromOverviewJson(j.war),
      StatsMetrics.fromOverviewJson(j.cwl),
    );
  }
}
export class StatsArmyResult {
  constructor(
    readonly armyShareCode: string | null,
    readonly armyItems: readonly string[],
    readonly armyCounts: Readonly<Record<string, number>>,
    readonly metrics: StatsMetrics,
  ) {}
  static fromJson(value: unknown): StatsArmyResult {
    const j = record(value);
    const items = list(j.items).map((value) => {
      const item = record(value);
      return {
        key: `${text(item.type)}:${integer(item.itemId)}`,
        quantity: integer(item.quantity),
      };
    });
    const starCounts = record(j.starCounts);
    const attacks = integer(j.attacks);
    return new StatsArmyResult(
      j.shareCode == null ? null : text(j.shareCode),
      items.length ? items.map((item) => item.key) : [text(j.name)],
      Object.fromEntries(items.map((item) => [item.key, item.quantity])),
      new StatsMetrics(
        attacks > 0,
        attacks,
        attacks === 0
          ? 0
          : (integer(starCounts.one) +
              integer(starCounts.two) * 2 +
              integer(starCounts.three) * 3) /
              attacks,
        decimal(j.averageDestruction),
        attacks === 0 ? 0 : integer(starCounts.zero) / attacks,
        attacks === 0 ? 0 : integer(starCounts.one) / attacks,
        attacks === 0 ? 0 : integer(starCounts.two) / attacks,
        attacks === 0 ? 0 : integer(starCounts.three) / attacks,
        [],
      ),
    );
  }
}
export class StatsArmiesResponse {
  constructor(
    readonly dateRange: StatsDateRange,
    readonly items: readonly StatsArmyResult[],
    readonly count: number,
  ) {}
  static fromJson(value: unknown, dates = new StatsDateRange(null, null)): StatsArmiesResponse {
    const j = record(value);
    const items = list(j.items).map(StatsArmyResult.fromJson);
    return new StatsArmiesResponse(dates, items, items.length);
  }
}
export class StatsItemResult {
  constructor(
    readonly item: string,
    readonly type: string,
    readonly useCount: number,
    readonly metrics: StatsMetrics,
    readonly hero?: string,
    readonly compositionShare?: number,
  ) {}
  static fromJson(value: unknown): StatsItemResult {
    const j = record(value);
    return new StatsItemResult(
      text(j.item),
      text(j.type),
      integer(j.useCount),
      StatsMetrics.fromJson(j),
      j.hero == null ? undefined : text(j.hero),
      optionalDecimal(j.compositionShare),
    );
  }
}
export class StatsItemsResponse {
  constructor(
    readonly dateRange: StatsDateRange,
    readonly items: readonly StatsItemResult[],
    readonly count: number,
  ) {}
  static fromJson(value: unknown): StatsItemsResponse {
    const j = record(value);
    return new StatsItemsResponse(
      StatsDateRange.fromJson(j.dateRange),
      list(j.items).map(StatsItemResult.fromJson),
      integer(j.count),
    );
  }
}
export class StatsBreakdown {
  constructor(
    readonly key: string,
    readonly metrics: StatsMetrics,
  ) {}
  static fromJson(value: unknown): StatsBreakdown {
    const j = record(value);
    return new StatsBreakdown(text(j.key), StatsMetrics.fromJson(j.metrics));
  }
}
export class StatsPerformanceResponse {
  constructor(
    readonly dateRange: StatsDateRange,
    readonly metrics: StatsMetrics,
    readonly breakdowns: readonly StatsBreakdown[],
  ) {}
  static fromJson(value: unknown): StatsPerformanceResponse {
    const j = record(value);
    return new StatsPerformanceResponse(
      StatsDateRange.fromJson(j.dateRange),
      StatsMetrics.fromJson(j.metrics),
      list(j.breakdowns).map(StatsBreakdown.fromJson),
    );
  }
}
function record(value: unknown): Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : {};
}
function list(value: unknown): readonly unknown[] {
  return Array.isArray(value) ? value : [];
}
function text(value: unknown): string {
  return value == null ? '' : String(value);
}
function integer(value: unknown): number {
  const number = Number(value);
  return Number.isFinite(number) ? Math.trunc(number) : 0;
}
function optionalInteger(value: unknown): number | undefined {
  return value == null ? undefined : integer(value);
}
function decimal(value: unknown): number {
  const number = Number(value);
  return Number.isFinite(number) ? number : 0;
}
function optionalDecimal(value: unknown): number | undefined {
  return value == null ? undefined : decimal(value);
}
function date(value: unknown): Date | null {
  const parsed = new Date(text(value));
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}
function utcDay(value: Date): number {
  return Date.UTC(value.getFullYear(), value.getMonth(), value.getDate());
}
