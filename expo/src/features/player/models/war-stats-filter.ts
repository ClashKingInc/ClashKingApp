import { bool, int, isRecord, nullableInt, nullableString, type JsonRecord } from './parsing';
export interface WarStatsFilterInput {
  season?: string | null;
  startDate?: Date | null;
  endDate?: Date | null;
  ownTownHall?: number | null;
  enemyTownHall?: number | null;
  ownTownHalls?: readonly number[] | null;
  enemyTownHalls?: readonly number[] | null;
  sameTownHall?: boolean;
  warType?: string;
  warTypes?: readonly string[] | null;
  freshAttacksOnly?: boolean | null;
  minStars?: number | null;
  maxStars?: number | null;
  allowedStars?: readonly number[] | null;
  minDestruction?: number | null;
  maxDestruction?: number | null;
  minMapPosition?: number | null;
  maxMapPosition?: number | null;
  limit?: number;
  metadata?: JsonRecord | null;
}
export class WarStatsFilter {
  readonly season: string | null;
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
  readonly metadata: JsonRecord | null;
  constructor(i: WarStatsFilterInput = {}) {
    this.season = i.season ?? null;
    this.startDate = i.startDate ?? null;
    this.endDate = i.endDate ?? null;
    this.ownTownHall = i.ownTownHall ?? null;
    this.enemyTownHall = i.enemyTownHall ?? null;
    this.ownTownHalls = i.ownTownHalls ?? null;
    this.enemyTownHalls = i.enemyTownHalls ?? null;
    this.sameTownHall = i.sameTownHall ?? false;
    this.warType = i.warType ?? 'all';
    this.warTypes = i.warTypes ?? null;
    this.freshAttacksOnly = i.freshAttacksOnly ?? null;
    this.minStars = i.minStars ?? null;
    this.maxStars = i.maxStars ?? null;
    this.allowedStars = i.allowedStars ?? null;
    this.minDestruction = i.minDestruction ?? null;
    this.maxDestruction = i.maxDestruction ?? null;
    this.minMapPosition = i.minMapPosition ?? null;
    this.maxMapPosition = i.maxMapPosition ?? null;
    this.limit = i.limit ?? 1000;
    this.metadata = i.metadata ?? null;
  }
  static fromJson(j: JsonRecord) {
    const own = Array.isArray(j.own_th) ? j.own_th.map((value) => int(value)) : null,
      enemy = Array.isArray(j.enemy_th) ? j.enemy_th.map((value) => int(value)) : null,
      types = Array.isArray(j.type) ? j.type.map(String) : null;
    return new WarStatsFilter({
      season: nullableString(j.season),
      startDate: typeof j.timestamp_start === 'number' ? new Date(j.timestamp_start * 1000) : null,
      endDate: typeof j.timestamp_end === 'number' ? new Date(j.timestamp_end * 1000) : null,
      ownTownHall: own?.length === 1 ? own[0]! : null,
      enemyTownHall: enemy?.length === 1 ? enemy[0]! : null,
      ownTownHalls: own,
      enemyTownHalls: enemy,
      sameTownHall: bool(j.same_th),
      warType: types?.length === 1 ? types[0]! : 'all',
      warTypes: types,
      freshAttacksOnly: typeof j.fresh_only === 'boolean' ? j.fresh_only : null,
      allowedStars: Array.isArray(j.stars) ? j.stars.map((value) => int(value)) : null,
      minDestruction: typeof j.min_destruction === 'number' ? j.min_destruction : null,
      maxDestruction: typeof j.max_destruction === 'number' ? j.max_destruction : null,
      minMapPosition: nullableInt(j.map_position_min),
      maxMapPosition: nullableInt(j.map_position_max),
      limit: int(j.limit, 1000),
      metadata: isRecord(j.metadata) ? j.metadata : null,
    });
  }
  toJson(): JsonRecord {
    const d: JsonRecord = { same_th: this.sameTownHall, limit: this.limit };
    if (this.warTypes?.length && !this.warTypes.includes('all')) d.type = this.warTypes;
    else if (this.warType !== 'all') d.type = this.warType;
    if (this.season) d.season = this.season;
    if (this.startDate) d.timestamp_start = Math.trunc(this.startDate.getTime() / 1000);
    if (this.endDate) d.timestamp_end = Math.trunc(this.endDate.getTime() / 1000);
    if (this.ownTownHalls?.length) d.own_th = this.ownTownHalls;
    else if (this.ownTownHall !== null) d.own_th = this.ownTownHall;
    if (this.enemyTownHalls?.length) d.enemy_th = this.enemyTownHalls;
    else if (this.enemyTownHall !== null) d.enemy_th = this.enemyTownHall;
    if (this.freshAttacksOnly !== null) d.fresh_only = this.freshAttacksOnly;
    if (this.allowedStars?.length) d.stars = this.allowedStars;
    else {
      if (this.minStars !== null) d.min_stars = this.minStars;
      if (this.maxStars !== null) d.max_stars = this.maxStars;
    }
    if (this.minDestruction !== null) d.min_destruction = this.minDestruction;
    if (this.maxDestruction !== null) d.max_destruction = this.maxDestruction;
    if (this.minMapPosition !== null) d.map_position_min = this.minMapPosition;
    if (this.maxMapPosition !== null) d.map_position_max = this.maxMapPosition;
    if (this.metadata) d.metadata = this.metadata;
    return d;
  }
  static defaultFilter() {
    return new WarStatsFilter({ warType: 'all', limit: 50 });
  }
  hasActiveFilters() {
    return (
      this.season !== null ||
      this.startDate !== null ||
      this.endDate !== null ||
      this.ownTownHall !== null ||
      this.enemyTownHall !== null ||
      !!this.ownTownHalls?.length ||
      !!this.enemyTownHalls?.length ||
      this.sameTownHall ||
      this.warType !== 'all' ||
      !!this.warTypes?.length ||
      this.freshAttacksOnly !== null ||
      this.minStars !== null ||
      this.maxStars !== null ||
      !!this.allowedStars?.length ||
      this.minDestruction !== null ||
      this.maxDestruction !== null ||
      this.minMapPosition !== null ||
      this.maxMapPosition !== null
    );
  }
}
