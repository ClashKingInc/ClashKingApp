import type {
  ArmySearchEndpoint,
  EndpointRequest,
  LegendDaysEndpoint,
  StatsCwlEndpoint,
  StatsRankedEndpoint,
  StatsWarEndpoint,
} from '@clashking/api-contracts/expo';

type ArmySearchQueryContract = EndpointRequest<typeof ArmySearchEndpoint>['query'];
type LegendDaysQueryContract = EndpointRequest<typeof LegendDaysEndpoint>['query'];
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
export const StatsLegendCohort = {
  legend: 'legend_i',
  top1000: 'top_1000',
  top100: 'top_100',
  top200: 'top_200',
} as const;
export type StatsLegendCohortValue = (typeof StatsLegendCohort)[keyof typeof StatsLegendCohort];
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
    readonly cohort: StatsLegendCohortValue = StatsLegendCohort.legend,
  ) {}
  toQuery(): ArmySearchQueryContract {
    const maximumLimit = this.filters.dates.inclusiveDays === 1 ? 250 : 10;
    const limit = Math.max(1, Math.min(Math.trunc(this.limit), maximumLimit));
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
      limit,
      sort: this.sortBy,
      direction: 'desc',
      cohort: this.cohort,
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
export class StatsLegendQuery {
  constructor(
    readonly dates: StatsDateFilter,
    readonly cohort: StatsLegendCohortValue = StatsLegendCohort.legend,
  ) {}
  toQuery(): LegendDaysQueryContract {
    return {
      'time[after]': StatsDateFilter.formatDate(this.dates.start),
      'time[before]': StatsDateFilter.formatDate(this.dates.end),
      cohort: this.cohort,
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
export class StatsCwlQuery {
  constructor(readonly season?: string) {}
  toQuery(): StatsCwlQueryContract {
    return this.season ? { season: this.season } : {};
  }
}

export interface StatsCwlTownHallCount { readonly level: number; readonly count: number }
export interface StatsCwlHitRate {
  readonly level: number;
  readonly attacks: number;
  readonly threeStarAttacks: number;
  readonly threeStarRate: number | null;
}
export interface StatsCwlBucket {
  readonly leagueId: number;
  readonly warSize: number;
  readonly groupCount: number;
  readonly clanCount: number;
  readonly registeredPlayerCount: number;
  readonly townHallDistribution: readonly StatsCwlTownHallCount[];
  readonly sameTownHallHitRates: readonly StatsCwlHitRate[] | null;
  readonly finalizedWars: number;
  readonly archivedWars: number;
  readonly calculatedAt: string;
}
export interface StatsCwlSeasonSummary {
  readonly season: string;
  readonly clanCount: number;
  readonly registeredPlayerCount: number;
  readonly groupCount: number;
}
export class StatsCwlResponse {
  constructor(
    readonly season: string | null,
    readonly clanCount: number,
    readonly registeredPlayerCount: number,
    readonly groupCount: number,
    readonly items: readonly StatsCwlBucket[],
    readonly availableSeasons: readonly string[] = [],
    readonly history: readonly StatsCwlSeasonSummary[] = [],
  ) {}
  static fromJson(value: unknown): StatsCwlResponse {
    const j = record(value);
    return new StatsCwlResponse(
      j.season == null ? null : text(j.season),
      integer(j.clanCount), integer(j.registeredPlayerCount), integer(j.groupCount),
      list(j.items).map((value) => {
        const item = record(value);
        return {
          leagueId: integer(item.leagueId), warSize: integer(item.warSize),
          groupCount: integer(item.groupCount), clanCount: integer(item.clanCount),
          registeredPlayerCount: integer(item.registeredPlayerCount),
          townHallDistribution: list(item.townHallDistribution).map((value) => {
            const count = record(value);
            return { level: integer(count.level), count: integer(count.count) };
          }),
          sameTownHallHitRates: item.sameTownHallHitRates == null ? null : list(item.sameTownHallHitRates).map((value) => {
            const hit = record(value);
            return { level: integer(hit.level), attacks: integer(hit.attacks),
              threeStarAttacks: integer(hit.threeStarAttacks),
              threeStarRate: hit.threeStarRate == null ? null : decimal(hit.threeStarRate) };
          }),
          finalizedWars: integer(item.finalizedWars), archivedWars: integer(item.archivedWars),
          calculatedAt: text(item.calculatedAt),
        };
      }),
      list(j.availableSeasons).map(text).filter(Boolean),
      list(j.history).map((value) => {
        const summary = record(value);
        return {
          season: text(summary.season),
          clanCount: integer(summary.clanCount),
          registeredPlayerCount: integer(summary.registeredPlayerCount),
          groupCount: integer(summary.groupCount),
        };
      }).filter((summary) => summary.season.length > 0),
    );
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
export interface StatsLocationMetadata {
  readonly id: number;
  readonly name: string;
  readonly countryCode: string;
}
export interface StatsClanMemberBin {
  readonly minMembers: number;
  readonly maxMembers: number;
  readonly count: number;
}
export function decodeStatsLocationMetadata(value: unknown): readonly StatsLocationMetadata[] {
  return list(record(value).items).flatMap((item) => {
    const json = record(item);
    const id = integer(json.id);
    const name = text(json.name).trim();
    if (id <= 0 || !name) return [];
    const countryCode = text(json.countryCode).trim().toUpperCase();
    return [{ id, name, countryCode: /^[A-Z]{2}$/u.test(countryCode) ? countryCode : '' }];
  });
}
export class StatsClanCountsResponse {
  constructor(
    readonly locations: readonly StatsGroupedCount[],
    readonly cwlLeagues: readonly StatsGroupedCount[],
    readonly capitalLeagues: readonly StatsGroupedCount[],
    readonly locationMetadata: readonly StatsLocationMetadata[] = [],
    readonly memberBins: readonly StatsClanMemberBin[] | null = null,
  ) {}
}
export function decodeStatsGroupedCounts(
  value: unknown,
  key: string,
): readonly StatsGroupedCount[] {
  return list(record(value).items).map((item) => StatsGroupedCount.fromJson(item, key));
}
export class StatsArmyResult {
  constructor(
    readonly familyId: string,
    readonly name: string | null,
    readonly armyShareCode: string,
    readonly players: number | null,
    readonly totalLegendAttacks: number,
    readonly averageDuration: number | null,
    readonly metrics: StatsMetrics,
  ) {}
  static fromJson(value: unknown): StatsArmyResult {
    const j = record(value);
    const starCounts = record(j.starCounts);
    const attacks = integer(j.attacks);
    const totalLegendAttacks = integer(j.totalLegendAttacks);
    return new StatsArmyResult(
      text(j.familyId),
      j.name == null ? null : text(j.name),
      text(j.shareCode),
      j.players == null ? null : integer(j.players),
      totalLegendAttacks,
      j.averageDuration == null ? null : decimal(j.averageDuration),
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
        totalLegendAttacks === 0 ? 0 : attacks / totalLegendAttacks,
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
export class StatsLegendItemUse {
  constructor(
    readonly id: number,
    readonly uses: number,
    readonly triples: number,
  ) {}
  static fromJson(value: unknown): StatsLegendItemUse {
    const j = record(value);
    return new StatsLegendItemUse(integer(j.id), integer(j.uses), integer(j.triples));
  }
}
export class StatsLegendPetAssignmentUse {
  constructor(
    readonly petId: number,
    readonly heroId: number,
    readonly uses: number,
    readonly triples: number,
  ) {}
  static fromJson(value: unknown): StatsLegendPetAssignmentUse {
    const j = record(value);
    return new StatsLegendPetAssignmentUse(
      integer(j.petId),
      integer(j.heroId),
      integer(j.uses),
      integer(j.triples),
    );
  }
}
export class StatsLegendDay {
  constructor(
    readonly day: string,
    readonly attacks: number,
    readonly players: number,
    readonly starCounts: readonly [number, number, number, number],
    readonly averageDuration: number | null,
    readonly averageDestruction: number | null,
    readonly heroes: readonly StatsLegendItemUse[],
    readonly pets: readonly StatsLegendItemUse[],
    readonly equipment: readonly StatsLegendItemUse[],
    readonly petAssignments: readonly StatsLegendPetAssignmentUse[],
    readonly troops: readonly StatsLegendItemUse[] = [],
    readonly spells: readonly StatsLegendItemUse[] = [],
    readonly sieges: readonly StatsLegendItemUse[] = [],
    readonly equipmentPairs: readonly {
      heroId: number;
      equipmentIds: readonly number[];
      uses: number;
      triples: number;
    }[] = [],
    readonly petCombos: readonly {
      petIds: readonly number[];
      uses: number;
      triples: number;
    }[] = [],
  ) {}
  static fromJson(value: unknown): StatsLegendDay {
    const j = record(value);
    const stars = record(j.starCounts);
    return new StatsLegendDay(
      text(j.day),
      integer(j.attacks),
      integer(j.players),
      [integer(stars.zero), integer(stars.one), integer(stars.two), integer(stars.three)],
      j.averageDuration == null ? null : decimal(j.averageDuration),
      j.averageDestruction == null ? null : decimal(j.averageDestruction),
      list(j.heroes).map(StatsLegendItemUse.fromJson),
      list(j.pets).map(StatsLegendItemUse.fromJson),
      list(j.equipment).map(StatsLegendItemUse.fromJson),
      list(j.petAssignments).map(StatsLegendPetAssignmentUse.fromJson),
      list(j.troops).map(StatsLegendItemUse.fromJson),
      list(j.spells).map(StatsLegendItemUse.fromJson),
      list(j.sieges).map(StatsLegendItemUse.fromJson),
      list(j.equipmentPairs).map((value) => {
        const item = record(value);
        return {
          heroId: integer(item.heroId),
          equipmentIds: list(item.equipmentIds).map(integer),
          uses: integer(item.uses),
          triples: integer(item.triples),
        };
      }),
      list(j.petCombos).map((value) => {
        const item = record(value);
        return {
          petIds: list(item.petIds).map(integer),
          uses: integer(item.uses),
          triples: integer(item.triples),
        };
      }),
    );
  }
  get metrics(): StatsMetrics {
    const weightedStars = this.starCounts.reduce((sum, count, stars) => sum + count * stars, 0);
    return new StatsMetrics(
      this.attacks > 0,
      this.attacks,
      this.attacks === 0 ? 0 : weightedStars / this.attacks,
      this.averageDestruction ?? 0,
      this.attacks === 0 ? 0 : this.starCounts[0] / this.attacks,
      this.attacks === 0 ? 0 : this.starCounts[1] / this.attacks,
      this.attacks === 0 ? 0 : this.starCounts[2] / this.attacks,
      this.attacks === 0 ? 0 : this.starCounts[3] / this.attacks,
      [],
    );
  }
}
export class StatsLegendResponse {
  constructor(
    readonly cohort: StatsLegendCohortValue,
    readonly items: readonly StatsLegendDay[],
  ) {}
  static fromJson(value: unknown): StatsLegendResponse {
    const j = record(value);
    const cohort = text(j.cohort);
    return new StatsLegendResponse(
      Object.values(StatsLegendCohort).includes(cohort as StatsLegendCohortValue)
        ? (cohort as StatsLegendCohortValue)
        : StatsLegendCohort.legend,
      list(j.items).map(StatsLegendDay.fromJson),
    );
  }
}
export class StatsTroopStatsResponse {
  constructor(
    readonly legend: StatsLegendResponse,
    readonly top1000: StatsLegendResponse | null,
    readonly top200: StatsLegendResponse | null,
  ) {}
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
export interface StatsWarHitRate {
  readonly period: string;
  readonly townHall: number;
  readonly attacks: number;
  readonly stars: readonly { readonly stars: number; readonly count: number }[];
  readonly averageStars: number;
  readonly averageDestruction: number;
  readonly averageDuration: number;
}
export interface StatsWarSummary {
  readonly period: string;
  readonly warSize?: number;
  readonly wars: number;
  readonly accounts: number;
  readonly townHalls: readonly { readonly level: number; readonly count: number }[];
  readonly draws: number;
  readonly missedAttacks?: number;
}
export class StatsPerformanceResponse {
  constructor(
    readonly dateRange: StatsDateRange,
    readonly metrics: StatsMetrics,
    readonly breakdowns: readonly StatsBreakdown[],
    readonly comparisons: readonly StatsBreakdown[] = [],
    readonly warHitRates: readonly StatsWarHitRate[] = [],
    readonly warSummaries: readonly StatsWarSummary[] = [],
    readonly warSizes: readonly StatsWarSummary[] = [],
  ) {}
  static fromJson(value: unknown): StatsPerformanceResponse {
    const j = record(value);
    return new StatsPerformanceResponse(
      StatsDateRange.fromJson(j.dateRange),
      StatsMetrics.fromJson(j.metrics),
      list(j.breakdowns).map(StatsBreakdown.fromJson),
      list(j.comparisons).map(StatsBreakdown.fromJson),
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
