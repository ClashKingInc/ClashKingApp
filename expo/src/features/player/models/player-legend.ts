import { gameDataState } from '@/core/game-data/game-data-state';
import { PlayerEquipment } from './player-items';
import { date, int, number, record, records, string, type JsonRecord } from './parsing';

export class LegendHeroGear {
  constructor(
    readonly name: string,
    readonly level: number,
  ) {}
  static fromJson(json: JsonRecord) {
    return new LegendHeroGear(string(json.name), int(json.level));
  }
}
export class PlayerLegendAttack {
  constructor(
    readonly change: number,
    readonly trophies: number,
    readonly time: number,
    readonly heroGear: readonly LegendHeroGear[],
  ) {}
  static fromJson(json: JsonRecord) {
    return new PlayerLegendAttack(
      int(json.change),
      int(json.trophies),
      int(json.time),
      records(json.hero_gear).map(LegendHeroGear.fromJson),
    );
  }
}
export class PlayerLegendDay {
  constructor(
    readonly attacks: readonly number[],
    readonly defenses: readonly number[],
    readonly trophiesGainedTotal: number,
    readonly trophiesLostTotal: number,
    readonly trophiesTotal: number,
    readonly totalAttacks: number,
    readonly totalDefenses: number,
    readonly newAttacks: readonly PlayerLegendAttack[],
    readonly newDefenses: readonly PlayerLegendAttack[],
    readonly startTrophies: number | null,
    readonly endTrophies: number | null,
  ) {}
  get remainingAttacks() {
    return 8 - this.totalAttacks;
  }
  static fromJson(json: JsonRecord) {
    const numbers = (value: unknown) =>
      Array.isArray(value) ? value.map((item) => int(item)) : [];
    return new PlayerLegendDay(
      numbers(json.attacks),
      numbers(json.defenses),
      int(json.trophies_gained_total),
      int(json.trophies_lost_total),
      int(json.trophies_total),
      int(json.num_attacks),
      int(json.num_defenses),
      records(json.new_attacks).map(PlayerLegendAttack.fromJson),
      records(json.new_defenses).map(PlayerLegendAttack.fromJson),
      typeof json.start_trophies === 'number' ? int(json.start_trophies) : null,
      typeof json.end_trophies === 'number' ? int(json.end_trophies) : null,
    );
  }
  gearCountsFlatFromProfile(equipment: readonly PlayerEquipment[]) {
    const result: Record<string, PlayerEquipment> = {};
    for (const attack of this.newAttacks)
      for (const gear of attack.heroGear)
        if (!result[gear.name]) {
          const profile = equipment.find((item) => item.name === gear.name);
          const meta = record(record(gameDataState.gearsData.gears)[gear.name]);
          result[gear.name] =
            profile ??
            PlayerEquipment.fromRaw({
              name: gear.name,
              level: gear.level,
              maxLevel: int(meta.maxLevel, gear.level),
              isUnlocked: true,
              meta,
            });
        }
    return result;
  }
  get usageCount() {
    const count: Record<string, number> = {};
    for (const attack of this.newAttacks)
      for (const gear of attack.heroGear) count[gear.name] = (count[gear.name] ?? 0) + 1;
    return count;
  }
}
export class PlayerLegendSeason {
  readonly dayOfSeason: number;
  constructor(
    readonly start: Date,
    readonly end: Date,
    readonly duration: number,
    readonly daysInLegend: number,
    readonly endTrophies: number,
    readonly trophiesGainedTotal: number,
    readonly trophiesLostTotal: number,
    readonly trophiesNet: number,
    readonly trophiesNetRevised: number,
    readonly totalAttacks: number,
    readonly totalDefenses: number,
    readonly avgGainedPerAttack: number,
    readonly avgLostPerDefense: number,
    readonly totalPossible: number,
    readonly gainedLostPossible: number,
    readonly gainedRatio: number,
    readonly lostRatio: number,
    readonly attackRatio: number,
    readonly defenseRatio: number,
    readonly days: Readonly<Record<string, PlayerLegendDay>>,
    readonly attackStarsDistribution: ReadonlyMap<number, number>,
    readonly defenseStarsDistribution: ReadonlyMap<number, number>,
    readonly attackStarsDistributionPercentages: ReadonlyMap<number, number>,
    readonly defenseStarsDistributionPercentages: ReadonlyMap<number, number>,
    now = new Date(),
  ) {
    const elapsed = Math.floor((now.getTime() - start.getTime()) / 86_400_000) + 1;
    this.dayOfSeason = Math.min(elapsed, duration);
  }
  get currentDay() {
    const now = new Date();
    if (now.getUTCHours() < 5) now.setUTCDate(now.getUTCDate() - 1);
    return this.days[now.toISOString().split('T')[0]!] ?? null;
  }
  static fromJson(json: JsonRecord) {
    const start = date(json.season_start) ?? new Date(0),
      end = date(json.season_end) ?? new Date(0),
      mapDays = Object.fromEntries(
        Object.entries(record(json.days)).map(([key, value]) => [
          key,
          PlayerLegendDay.fromJson(record(value)),
        ]),
      );
    return new PlayerLegendSeason(
      start,
      end,
      int(json.season_duration),
      int(json.season_days_in_legend),
      int(json.season_end_trophies),
      int(json.season_trophies_gained_total),
      int(json.season_trophies_lost_total),
      int(json.season_trophies_net),
      5000 - int(json.season_trophies_net_revised),
      int(json.season_total_attacks),
      int(json.season_total_defenses),
      number(json.season_average_trophies_gained_per_attack),
      number(json.season_average_trophies_lost_per_defense),
      int(json.season_total_attacks_defenses_possible),
      int(json.season_total_gained_lost_possible),
      number(json.season_trophies_gained_ratio),
      number(json.season_trophies_lost_ratio),
      number(json.season_total_attacks_ratio),
      number(json.season_total_defenses_ratio),
      mapDays,
      numericMap(json.season_stars_distribution_attacks),
      numericMap(json.season_stars_distribution_defenses),
      numericMap(json.season_stars_distribution_attacks_percentages),
      numericMap(json.season_stars_distribution_defenses_percentages),
    );
  }
}
export class PlayerLegendStats {
  constructor(readonly seasons: Readonly<Record<string, PlayerLegendSeason>>) {}
  static fromJson(json: JsonRecord) {
    return new PlayerLegendStats(
      Object.fromEntries(
        Object.entries(json).map(([key, value]) => [
          key,
          PlayerLegendSeason.fromJson(record(value)),
        ]),
      ),
    );
  }
  get allSeasons() {
    return Object.values(this.seasons);
  }
  get currentSeason() {
    return this.currentSeasonAt();
  }
  currentSeasonAt(now = new Date()) {
    return (
      this.allSeasons.find(
        (season) => now > season.start && now < new Date(season.end.getTime() + 86_400_000),
      ) ?? null
    );
  }
  getSpecificSeason(value: Date) {
    return this.allSeasons.find((season) => value >= season.start && value <= season.end) ?? null;
  }
}
export class PlayerLegendClan {
  constructor(
    readonly tag: string,
    readonly name: string,
    readonly badgeUrls: Readonly<Record<string, string>>,
  ) {}
  static fromJson(json: JsonRecord) {
    return new PlayerLegendClan(
      string(json.tag),
      string(json.name),
      Object.fromEntries(
        Object.entries(record(json.badgeUrls)).map(([key, value]) => [key, string(value)]),
      ),
    );
  }
}
export class PlayerLegendRanking {
  constructor(
    readonly tag: string,
    readonly name: string,
    readonly expLevel: number,
    readonly trophies: number,
    readonly attackWins: number,
    readonly defenseWins: number,
    readonly rank: number,
    readonly season: string,
    readonly clan: PlayerLegendClan,
  ) {}
  static fromJson(json: JsonRecord) {
    return new PlayerLegendRanking(
      string(json.tag),
      string(json.name),
      int(json.expLevel),
      int(json.trophies),
      int(json.attackWins),
      int(json.defenseWins),
      int(json.rank),
      string(json.season),
      PlayerLegendClan.fromJson(record(json.clan)),
    );
  }
}
export interface ChartSpot {
  x: number;
  y: number;
}
export class SpotData {
  constructor(
    readonly spots: readonly ChartSpot[],
    readonly minX: number,
    readonly maxX: number,
    readonly minY: number,
    readonly maxY: number,
    readonly rangeX: number,
    readonly rangeY: number,
  ) {}
  static fromLegendRankings(rankings: readonly PlayerLegendRanking[]) {
    if (!rankings.length) return new SpotData([], 0, 0, 0, 0, 1, 1);
    const spots = rankings
      .map((item) => ({
        x: new Date(
          item.season.split('-').length === 2 ? `${item.season}-01` : item.season,
        ).getTime(),
        y: item.trophies,
      }))
      .sort((a, b) => a.x - b.x);
    const xs = spots.map((item) => item.x),
      ys = spots.map((item) => item.y),
      minX = Math.min(...xs),
      maxX = Math.max(...xs),
      minY = Math.min(...ys),
      maxY = Math.max(...ys);
    return new SpotData(
      spots,
      minX,
      maxX,
      minY,
      maxY,
      Math.max((maxX - minX) / 5, 1),
      Math.max((maxY - minY) / 5, 1),
    );
  }
  static getYAxisInterval(min: number, max: number) {
    const range = max - min;
    return range < 50 ? 10 : range < 100 ? 20 : range < 200 ? 50 : 100;
  }
  static roundUpToNext100(value: number) {
    return Math.ceil(value / 100) * 100;
  }
}
function numericMap(value: unknown): ReadonlyMap<number, number> {
  return new Map(Object.entries(record(value)).map(([key, item]) => [Number(key), number(item)]));
}
