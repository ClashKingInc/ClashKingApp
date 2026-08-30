export interface ClanWarStatsFilterOptions {
  readonly startDate?: Date | null;
  readonly endDate?: Date | null;
  readonly ownTownHall?: number | null;
  readonly enemyTownHall?: number | null;
  readonly ownTownHalls?: readonly number[] | null;
  readonly enemyTownHalls?: readonly number[] | null;
  readonly sameTownHall?: boolean;
  readonly warType?: string;
  readonly warTypes?: readonly string[] | null;
  readonly freshAttacksOnly?: boolean | null;
  readonly minStars?: number | null;
  readonly maxStars?: number | null;
  readonly allowedStars?: readonly number[] | null;
  readonly minDestruction?: number | null;
  readonly maxDestruction?: number | null;
  readonly minMapPosition?: number | null;
  readonly maxMapPosition?: number | null;
  readonly limit?: number;
}

export class ClanWarStatsFilter {
  readonly startDate: Date | null;
  readonly endDate: Date | null;
  readonly ownTownHall: number | null;
  readonly enemyTownHall: number | null;
  readonly ownTownHalls: readonly number[] | null;
  readonly enemyTownHalls: readonly number[] | null;
  readonly sameTownHall: boolean;
  readonly warType: string;
  readonly warTypes: readonly string[] | null;
  readonly freshAttacksOnly: boolean | null;
  readonly minStars: number | null;
  readonly maxStars: number | null;
  readonly allowedStars: readonly number[] | null;
  readonly minDestruction: number | null;
  readonly maxDestruction: number | null;
  readonly minMapPosition: number | null;
  readonly maxMapPosition: number | null;
  readonly limit: number;

  constructor(options: ClanWarStatsFilterOptions = {}) {
    this.startDate = options.startDate ?? null;
    this.endDate = options.endDate ?? null;
    this.ownTownHall = options.ownTownHall ?? null;
    this.enemyTownHall = options.enemyTownHall ?? null;
    this.ownTownHalls = options.ownTownHalls ?? null;
    this.enemyTownHalls = options.enemyTownHalls ?? null;
    this.sameTownHall = options.sameTownHall ?? false;
    this.warType = options.warType ?? 'all';
    this.warTypes = options.warTypes ?? null;
    this.freshAttacksOnly = options.freshAttacksOnly ?? null;
    this.minStars = options.minStars ?? null;
    this.maxStars = options.maxStars ?? null;
    this.allowedStars = options.allowedStars ?? null;
    this.minDestruction = options.minDestruction ?? null;
    this.maxDestruction = options.maxDestruction ?? null;
    this.minMapPosition = options.minMapPosition ?? null;
    this.maxMapPosition = options.maxMapPosition ?? null;
    this.limit = options.limit ?? 50;
  }

  toJson(): Record<string, unknown> {
    const data: Record<string, unknown> = { limit: this.limit, same_th: this.sameTownHall };
    if (this.warTypes?.length && !this.warTypes.includes('all')) data.type = this.warTypes;
    else if (this.warType !== 'all') data.type = this.warType;
    if (this.startDate) data.timestamp_start = Math.floor(this.startDate.getTime() / 1000);
    if (this.endDate) data.timestamp_end = Math.floor(this.endDate.getTime() / 1000);
    if (this.ownTownHalls?.length) data.own_th = this.ownTownHalls;
    else if (this.ownTownHall !== null) data.own_th = this.ownTownHall;
    if (this.enemyTownHalls?.length) data.enemy_th = this.enemyTownHalls;
    else if (this.enemyTownHall !== null) data.enemy_th = this.enemyTownHall;
    if (this.freshAttacksOnly !== null) data.fresh_only = this.freshAttacksOnly;
    if (this.allowedStars?.length) data.stars = this.allowedStars;
    else {
      if (this.minStars !== null) data.min_stars = this.minStars;
      if (this.maxStars !== null) data.max_stars = this.maxStars;
    }
    if (this.minDestruction !== null) data.min_destruction = this.minDestruction;
    if (this.maxDestruction !== null) data.max_destruction = this.maxDestruction;
    if (this.minMapPosition !== null) data.map_position_min = this.minMapPosition;
    if (this.maxMapPosition !== null) data.map_position_max = this.maxMapPosition;
    return data;
  }

  copyWith(options: ClanWarStatsFilterOptions): ClanWarStatsFilter {
    return new ClanWarStatsFilter({
      startDate: hasOption(options, 'startDate') ? options.startDate : this.startDate,
      endDate: hasOption(options, 'endDate') ? options.endDate : this.endDate,
      ownTownHall: hasOption(options, 'ownTownHall') ? options.ownTownHall : this.ownTownHall,
      enemyTownHall: hasOption(options, 'enemyTownHall')
        ? options.enemyTownHall
        : this.enemyTownHall,
      ownTownHalls: hasOption(options, 'ownTownHalls') ? options.ownTownHalls : this.ownTownHalls,
      enemyTownHalls: hasOption(options, 'enemyTownHalls')
        ? options.enemyTownHalls
        : this.enemyTownHalls,
      sameTownHall: options.sameTownHall ?? this.sameTownHall,
      warType: options.warType ?? this.warType,
      warTypes: hasOption(options, 'warTypes') ? options.warTypes : this.warTypes,
      freshAttacksOnly: hasOption(options, 'freshAttacksOnly')
        ? options.freshAttacksOnly
        : this.freshAttacksOnly,
      minStars: hasOption(options, 'minStars') ? options.minStars : this.minStars,
      maxStars: hasOption(options, 'maxStars') ? options.maxStars : this.maxStars,
      allowedStars: hasOption(options, 'allowedStars') ? options.allowedStars : this.allowedStars,
      minDestruction: hasOption(options, 'minDestruction')
        ? options.minDestruction
        : this.minDestruction,
      maxDestruction: hasOption(options, 'maxDestruction')
        ? options.maxDestruction
        : this.maxDestruction,
      minMapPosition: hasOption(options, 'minMapPosition')
        ? options.minMapPosition
        : this.minMapPosition,
      maxMapPosition: hasOption(options, 'maxMapPosition')
        ? options.maxMapPosition
        : this.maxMapPosition,
      limit: options.limit ?? this.limit,
    });
  }

  static defaultFilter(now = new Date()): ClanWarStatsFilter {
    return new ClanWarStatsFilter({
      startDate: new Date(now.getTime() - 180 * 24 * 60 * 60 * 1000),
      endDate: now,
    });
  }

  hasActiveFilters(): boolean {
    return Boolean(
      this.ownTownHall !== null ||
      this.enemyTownHall !== null ||
      this.ownTownHalls?.length ||
      this.enemyTownHalls?.length ||
      this.sameTownHall ||
      this.warType !== 'all' ||
      this.warTypes?.length ||
      this.freshAttacksOnly !== null ||
      this.minStars !== null ||
      this.maxStars !== null ||
      this.allowedStars?.length ||
      this.minDestruction !== null ||
      this.maxDestruction !== null ||
      this.minMapPosition !== null ||
      this.maxMapPosition !== null,
    );
  }

  getFilterSummary(): string {
    const filters: string[] = [];
    if (this.ownTownHalls?.length) filters.push(`TH${this.ownTownHalls.join(', ')} attacks`);
    else if (this.ownTownHall !== null) filters.push(`TH${this.ownTownHall} attacks`);
    if (this.enemyTownHalls?.length) filters.push(`vs TH${this.enemyTownHalls.join(', ')}`);
    else if (this.enemyTownHall !== null) filters.push(`vs TH${this.enemyTownHall}`);
    if (this.sameTownHall) filters.push('Same TH only');
    if (this.warTypes?.length)
      filters.push(`${this.warTypes.map((value) => value.toUpperCase()).join(', ')} wars`);
    else if (this.warType !== 'all') filters.push(`${this.warType.toUpperCase()} wars`);
    if (this.freshAttacksOnly === true) filters.push('Fresh attacks only');
    if (this.allowedStars?.length) filters.push(`${this.allowedStars.join(', ')} ⭐ only`);
    else if (this.minStars !== null && this.maxStars !== null)
      filters.push(`${this.minStars}-${this.maxStars} stars`);
    else if (this.minStars !== null) filters.push(`${this.minStars}+ stars`);
    else if (this.maxStars !== null) filters.push(`≤${this.maxStars} stars`);
    if (this.minDestruction !== null && this.maxDestruction !== null)
      filters.push(
        `${this.minDestruction.toFixed(0)}-${this.maxDestruction.toFixed(0)}% destruction`,
      );
    else if (this.minDestruction !== null)
      filters.push(`${this.minDestruction.toFixed(0)}%+ destruction`);
    else if (this.maxDestruction !== null)
      filters.push(`≤${this.maxDestruction.toFixed(0)}% destruction`);
    return filters.length ? filters.join(', ') : 'No filters applied';
  }
}

function hasOption(
  options: ClanWarStatsFilterOptions,
  key: keyof ClanWarStatsFilterOptions,
): boolean {
  return Object.prototype.hasOwnProperty.call(options, key);
}
