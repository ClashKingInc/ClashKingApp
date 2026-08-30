import { int, intMap, number, record, records, string, type JsonRecord } from './parsing';
import { WarInfo } from '../../war/models/war';
export { WarInfo as WarInfoSnapshot } from '../../war/models/war';
export class EnemyTownhallStats {
  constructor(
    readonly averageStars: number,
    public averageDestruction: number,
    public count: number,
    readonly starsCount: Record<string, number>,
  ) {}
  static fromJson(j: JsonRecord) {
    return new EnemyTownhallStats(
      number(j.averageStars),
      number(j.averageDestruction),
      int(j.count),
      intMap(j.starsCount),
    );
  }
  get starsCountDef() {
    return { ...this.starsCount };
  }
  merge(other: EnemyTownhallStats) {
    const total = this.count + other.count;
    this.averageDestruction = total
      ? (this.averageDestruction * this.count + other.averageDestruction * other.count) / total
      : 0;
    this.count = total;
    for (const key of Object.keys(this.starsCount))
      this.starsCount[key] = (this.starsCount[key] ?? 0) + (other.starsCount[key] ?? 0);
  }
  copy() {
    return new EnemyTownhallStats(this.averageStars, this.averageDestruction, this.count, {
      ...this.starsCount,
    });
  }
}
export class PlayerWarTypeStats {
  constructor(
    readonly warsCounts: number,
    readonly totalAttacks: number,
    readonly totalDefenses: number,
    readonly missedAttacks: number,
    readonly missedDefenses: number,
    readonly starsCount: Record<string, number>,
    readonly starsCountDef: Record<string, number>,
    readonly byEnemyTownhall: Record<string, EnemyTownhallStats>,
    readonly byEnemyTownhallDef: Record<string, EnemyTownhallStats>,
  ) {}
  static fromJson(j: JsonRecord) {
    const parse = (value: unknown) =>
      Object.fromEntries(
        Object.entries(record(value)).map(([key, item]) => [
          key,
          EnemyTownhallStats.fromJson(record(item)),
        ]),
      );
    return new PlayerWarTypeStats(
      int(j.warsCounts),
      int(j.totalAttacks),
      int(j.totalDefenses),
      int(j.missedAttacks),
      int(j.missedDefenses),
      intMap(j.starsCount),
      intMap(j.starsCountDef),
      parse(j.byEnemyTownhall),
      parse(j.byEnemyTownhallDef),
    );
  }
  get averageStars() {
    return averageStars(this.starsCount, this.totalAttacks);
  }
  get averageStarsDef() {
    return averageStars(this.starsCountDef, this.totalDefenses);
  }
  get averageDestruction() {
    return weighted(this.byEnemyTownhall);
  }
  get averageDestructionDef() {
    return weighted(this.byEnemyTownhallDef);
  }
  getStarsCountAgainstTh(th: number | null) {
    if (th === null || !Object.keys(this.byEnemyTownhall).length) return this.starsCount;
    const result: Record<string, number> = { '0': 0, '1': 0, '2': 0, '3': 0 };
    for (const [key, stats] of Object.entries(this.byEnemyTownhall))
      if (key.endsWith(`vs${th}`))
        for (const [stars, count] of Object.entries(stats.starsCount))
          result[stars] = (result[stars] ?? 0) + count;
    return result;
  }
}
export class PlayerWarStats {
  constructor(
    readonly name: string,
    readonly tag: string,
    readonly townhallLevel: number,
    readonly timeRange: Record<string, number>,
    readonly statsByType: Record<string, PlayerWarTypeStats>,
    readonly wars: readonly PlayerWarStatsData[],
  ) {}
  static fromJson(json: JsonRecord, playerTag?: string | null, wars?: unknown[] | null) {
    try {
      return new PlayerWarStats(
        string(json.name),
        string(json.tag),
        int(json.townhallLevel),
        Object.keys(record(json.timeRange)).length ? intMap(json.timeRange) : { start: 0, end: 0 },
        Object.fromEntries(
          Object.entries(record(json.stats)).map(([key, value]) => [
            key,
            PlayerWarTypeStats.fromJson(record(value)),
          ]),
        ),
        (wars ?? (Array.isArray(json.wars) ? json.wars : []))
          .filter((item) => item && typeof item === 'object')
          .map((item) => PlayerWarStatsData.fromJson(record(item), playerTag ?? string(json.tag))),
      );
    } catch {
      return new PlayerWarStats(
        string(json.name),
        string(json.tag),
        int(json.townhallLevel),
        { start: 0, end: 0 },
        {},
        [],
      );
    }
  }
  getSpecificStats(type: string) {
    return this.statsByType[type] ?? emptyType();
  }
  getStatsForTypes(
    types: readonly string[],
    options: {
      attackerThFilter?: readonly number[] | null;
      defenderThFilter?: readonly number[] | null;
      equalThSelected?: boolean;
    } = {},
  ) {
    if (!types.length) return this.statsByType.all ?? emptyType();
    const selected = types
      .map((type) => this.statsByType[type])
      .filter((item): item is PlayerWarTypeStats => !!item);
    const offense = filterTownHalls(
      selected.map((value) => value.byEnemyTownhall),
      options,
      false,
    );
    const defense = filterTownHalls(
      selected.map((value) => value.byEnemyTownhallDef),
      options,
      true,
    );
    return new PlayerWarTypeStats(
      selected.reduce((s, v) => s + v.warsCounts, 0),
      Object.values(offense).reduce((sum, value) => sum + value.count, 0),
      Object.values(defense).reduce((sum, value) => sum + value.count, 0),
      selected.reduce((s, v) => s + v.missedAttacks, 0),
      selected.reduce((s, v) => s + v.missedDefenses, 0),
      sumMaps(Object.values(offense).map((value) => value.starsCount)),
      sumMaps(Object.values(defense).map((value) => value.starsCountDef)),
      offense,
      defense,
    );
  }
}

export interface WarHistoryFilter {
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
}

export function buildPlayerWarStatsFromHistory(
  values: readonly unknown[],
  playerTag: string,
  filter: WarHistoryFilter = {},
): PlayerWarStats {
  const history = records(values).filter((item) => historyMatches(item, filter));
  const firstPlayer = record(history[0]?.player);
  const types = new Map<string, JsonRecord[]>();
  for (const item of history) {
    const type = normalizedWarType(item.type);
    types.set(type, [...(types.get(type) ?? []), item]);
  }
  const all = aggregateHistory(history, filter);
  const statsByType: Record<string, PlayerWarTypeStats> = { all };
  for (const [type, items] of types) statsByType[type] = aggregateHistory(items, filter);
  const times = history.map((item) => Date.parse(string(item.endTime))).filter(Number.isFinite);
  return new PlayerWarStats(
    string(firstPlayer.name),
    string(firstPlayer.tag, playerTag),
    int(firstPlayer.townhallLevel),
    {
      start: times.length ? Math.trunc(Math.min(...times) / 1000) : 0,
      end: times.length ? Math.trunc(Math.max(...times) / 1000) : 0,
    },
    statsByType,
    history.map((item) => historyData(item, playerTag)),
  );
}

function aggregateHistory(items: JsonRecord[], filter: WarHistoryFilter): PlayerWarTypeStats {
  const attacks = items.flatMap((item) =>
    records(item.attacks)
      .filter((attack) => attackMatches(record(item.player), attack, filter, false))
      .map((attack) => ({ owner: record(item.player), attack })),
  );
  const defenses = items.flatMap((item) =>
    records(item.defenses)
      .filter((attack) => attackMatches(record(item.player), attack, filter, true))
      .map((attack) => ({ owner: record(item.player), attack })),
  );
  return new PlayerWarTypeStats(
    items.length,
    attacks.length,
    defenses.length,
    items.reduce(
      (sum, item) =>
        sum + Math.max(0, int(item.attacksPerMember, 1) - records(item.attacks).length),
      0,
    ),
    items.reduce(
      (sum, item) =>
        sum + Math.max(0, int(item.attacksPerMember, 1) - records(item.defenses).length),
      0,
    ),
    countStars(attacks.map(({ attack }) => attack)),
    countStars(defenses.map(({ attack }) => attack)),
    groupTownHalls(attacks, false),
    groupTownHalls(defenses, true),
  );
}

function historyData(item: JsonRecord, playerTag: string): PlayerWarStatsData {
  const player = record(item.player);
  const own = string(player.tag, playerTag);
  const attacks = records(item.attacks).map((attack) => historyAttack(attack, player, false));
  const defenses = records(item.defenses).map((attack) => historyAttack(attack, player, true));
  const member = new WarMemberData(
    own,
    string(player.name),
    int(player.townhallLevel),
    int(player.mapPosition),
    defenses.length,
    attacks,
    defenses,
  );
  // The player-history endpoint only returns completed wars and may omit the
  // live-war `state` field. Preserve an explicit state if one is supplied, but
  // otherwise project the history record as ended so detail presentation does
  // not misleadingly show an unknown state.
  return new PlayerWarStatsData(
    WarInfo.fromJson({ ...item, state: string(item.state, 'warEnded') }),
    member,
  );
}

function historyAttack(item: JsonRecord, owner: JsonRecord, defense: boolean): WarAttackSnapshot {
  const other = record(item.player);
  const ownTag = string(owner.tag);
  const otherTag = string(other.tag);
  return WarAttackSnapshot.fromJson({
    ...item,
    attackerTag: defense ? otherTag : ownTag,
    defenderTag: defense ? ownTag : otherTag,
    attacker: defense ? other : owner,
    defender: defense ? owner : other,
  });
}

function historyMatches(item: JsonRecord, filter: WarHistoryFilter): boolean {
  const type = normalizedWarType(item.type);
  const requested = filter.warTypes?.length
    ? filter.warTypes
    : filter.warType && filter.warType !== 'all'
      ? [filter.warType]
      : [];
  if (requested.length && !requested.includes(type)) return false;
  const end = Date.parse(string(item.endTime));
  if (filter.startDate && end < filter.startDate.getTime()) return false;
  if (filter.endDate && end > filter.endDate.getTime()) return false;
  return true;
}

function attackMatches(
  owner: JsonRecord,
  attack: JsonRecord,
  filter: WarHistoryFilter,
  defense: boolean,
): boolean {
  const other = record(attack.player);
  const ownTh = int(owner.townhallLevel);
  const enemyTh = int(other.townhallLevel);
  const attackerTh = defense ? enemyTh : ownTh;
  const defenderTh = defense ? ownTh : enemyTh;
  const ownAllowed = filter.ownTownHalls?.length
    ? filter.ownTownHalls
    : filter.ownTownHall == null
      ? []
      : [filter.ownTownHall];
  const enemyAllowed = filter.enemyTownHalls?.length
    ? filter.enemyTownHalls
    : filter.enemyTownHall == null
      ? []
      : [filter.enemyTownHall];
  if (ownAllowed.length && !ownAllowed.includes(attackerTh)) return false;
  if (enemyAllowed.length && !enemyAllowed.includes(defenderTh)) return false;
  if (filter.sameTownHall === true && attackerTh !== defenderTh) return false;
  if (!defense && filter.freshAttacksOnly === true && attack.fresh !== true) return false;
  const stars = int(attack.stars);
  if (filter.allowedStars?.length && !filter.allowedStars.includes(stars)) return false;
  if (filter.minStars != null && stars < filter.minStars) return false;
  if (filter.maxStars != null && stars > filter.maxStars) return false;
  const destruction = number(attack.destructionPercentage);
  if (filter.minDestruction != null && destruction < filter.minDestruction) return false;
  if (filter.maxDestruction != null && destruction > filter.maxDestruction) return false;
  const position = int(other.mapPosition);
  if (filter.minMapPosition != null && position < filter.minMapPosition) return false;
  if (filter.maxMapPosition != null && position > filter.maxMapPosition) return false;
  return true;
}

function countStars(attacks: JsonRecord[]): Record<string, number> {
  const result: Record<string, number> = { '0': 0, '1': 0, '2': 0, '3': 0 };
  for (const attack of attacks) {
    const stars = String(int(attack.stars));
    result[stars] = (result[stars] ?? 0) + 1;
  }
  return result;
}

function groupTownHalls(
  values: { owner: JsonRecord; attack: JsonRecord }[],
  defense: boolean,
): Record<string, EnemyTownhallStats> {
  const grouped = new Map<string, JsonRecord[]>();
  for (const value of values) {
    const own = int(value.owner.townhallLevel);
    const other = int(record(value.attack.player).townhallLevel);
    const key = defense ? `${other}vs${own}` : `${own}vs${other}`;
    grouped.set(key, [...(grouped.get(key) ?? []), value.attack]);
  }
  return Object.fromEntries(
    [...grouped].map(([key, attacks]) => {
      const stars = countStars(attacks);
      const destruction = attacks.reduce(
        (sum, attack) => sum + number(attack.destructionPercentage),
        0,
      );
      const totalStars = attacks.reduce((sum, attack) => sum + int(attack.stars), 0);
      return [
        key,
        new EnemyTownhallStats(
          attacks.length ? totalStars / attacks.length : 0,
          attacks.length ? destruction / attacks.length : 0,
          attacks.length,
          stars,
        ),
      ];
    }),
  );
}

function normalizedWarType(value: unknown): string {
  const type = string(value).toLowerCase();
  return type === 'cwl' || type === 'friendly' ? type : 'random';
}
export class PlayerWarStatsData {
  constructor(
    readonly warDetails: WarInfo,
    readonly memberData: WarMemberData,
  ) {}
  static fromJson(json: JsonRecord, tag: string) {
    const member = records(json.members).find((item) => item.tag === tag);
    return new PlayerWarStatsData(
      WarInfo.fromJson(record(json.war_data)),
      member ? WarMemberData.fromJson(member) : WarMemberData.empty(),
    );
  }
}
export class WarMemberData {
  constructor(
    readonly tag: string,
    readonly name: string,
    readonly townhallLevel: number,
    readonly mapPosition: number,
    readonly opponentAttacks: number,
    readonly attacks: readonly WarAttackSnapshot[],
    readonly defenses: readonly WarAttackSnapshot[],
  ) {}
  static fromJson(j: JsonRecord) {
    return new WarMemberData(
      string(j.tag),
      string(j.name),
      int(j.townhallLevel),
      int(j.mapPosition),
      int(j.opponentAttacks),
      records(j.attacks).map(WarAttackSnapshot.fromJson),
      records(j.defenses).map(WarAttackSnapshot.fromJson),
    );
  }
  static empty() {
    return new WarMemberData('', '', 0, 0, 0, [], []);
  }
}
export class MiniWarMember {
  constructor(
    readonly tag: string,
    readonly name: string,
    readonly townhallLevel: number,
    readonly mapPosition: number,
    readonly opponentAttacks: number | null,
  ) {}
  static fromJson(json: JsonRecord) {
    return new MiniWarMember(
      string(json.tag),
      string(json.name),
      int(json.townhallLevel),
      int(json.mapPosition),
      typeof json.opponentAttacks === 'number' ? int(json.opponentAttacks) : null,
    );
  }
}
export class WarAttackSnapshot {
  constructor(
    readonly attackerTag: string,
    readonly defenderTag: string,
    readonly stars: number,
    readonly destructionPercentage: number,
    readonly order: number,
    readonly duration: number | null,
    readonly defender: MiniWarMember | null,
    readonly attacker: MiniWarMember | null,
  ) {}
  static fromJson(json: JsonRecord) {
    return new WarAttackSnapshot(
      string(json.attackerTag),
      string(json.defenderTag),
      int(json.stars),
      int(json.destructionPercentage),
      int(json.order),
      typeof json.duration === 'number' ? int(json.duration) : null,
      json.defender ? MiniWarMember.fromJson(record(json.defender)) : null,
      json.attacker ? MiniWarMember.fromJson(record(json.attacker)) : null,
    );
  }
  toJson() {
    return {
      attackerTag: this.attackerTag,
      defenderTag: this.defenderTag,
      stars: this.stars,
      destructionPercentage: this.destructionPercentage,
      order: this.order,
      duration: this.duration,
    };
  }
}
export class ClanInfo {
  constructor(
    readonly tag: string,
    readonly name: string,
    readonly badgeUrls: JsonRecord,
    readonly clanLevel: number,
    readonly attacks: number,
    readonly stars: number,
    readonly destructionPercentage: number,
  ) {}
  static fromJson(j: JsonRecord) {
    return new ClanInfo(
      string(j.tag),
      string(j.name),
      record(j.badgeUrls),
      int(j.clanLevel),
      int(j.attacks),
      int(j.stars),
      number(j.destructionPercentage),
    );
  }
}
export class PlayerWarStatsDetails {
  constructor(
    readonly state: string,
    readonly teamSize: number,
    readonly attacksPerMember: number,
    readonly battleModifier: string,
    readonly preparationStartTime: string,
    readonly startTime: string,
    readonly endTime: string,
    readonly clan: ClanInfo,
    readonly opponent: ClanInfo,
    readonly type: string,
  ) {}
  static fromJson(j: JsonRecord) {
    return new PlayerWarStatsDetails(
      string(j.state),
      int(j.teamSize),
      int(j.attacksPerMember),
      string(j.battleModifier),
      string(j.preparationStartTime),
      string(j.startTime),
      string(j.endTime),
      ClanInfo.fromJson(record(j.clan)),
      ClanInfo.fromJson(record(j.opponent)),
      string(j.type),
    );
  }
}
const emptyType = () => new PlayerWarTypeStats(0, 0, 0, 0, 0, {}, {}, {}, {});
const averageStars = (map: Record<string, number>, total: number) =>
  total
    ? Object.entries(map).reduce((sum, [stars, count]) => sum + Number(stars) * count, 0) / total
    : 0;
const weighted = (map: Record<string, EnemyTownhallStats>) => {
  const values = Object.values(map),
    count = values.reduce((sum, item) => sum + item.count, 0);
  return count
    ? values.reduce((sum, item) => sum + item.averageDestruction * item.count, 0) / count
    : 0;
};
const sumMaps = (maps: Record<string, number>[]) => {
  const out: Record<string, number> = {};
  for (const map of maps)
    for (const [key, value] of Object.entries(map)) out[key] = (out[key] ?? 0) + value;
  return out;
};
function filterTownHalls(
  maps: Record<string, EnemyTownhallStats>[],
  options: {
    attackerThFilter?: readonly number[] | null;
    defenderThFilter?: readonly number[] | null;
    equalThSelected?: boolean;
  },
  defense: boolean,
) {
  const result: Record<string, EnemyTownhallStats> = {};
  for (const map of maps) {
    for (const [key, value] of Object.entries(map)) {
      const match = /^(\d+)vs(\d+)$/.exec(key);
      if (!match) continue;
      const attacker = Number(match[1]);
      const defender = Number(match[2]);
      const attackerMatches =
        !options.attackerThFilter?.length || options.attackerThFilter.includes(attacker);
      const defenderMatches =
        !options.defenderThFilter?.length || options.defenderThFilter.includes(defender);
      const included = defense
        ? (options.equalThSelected === true && attacker === defender) ||
          (attackerMatches && defenderMatches)
        : options.equalThSelected === true
          ? attacker === defender && attackerMatches && defenderMatches
          : attackerMatches && defenderMatches;
      if (!included) continue;
      if (result[key]) result[key].merge(value);
      else result[key] = value.copy();
    }
  }
  return result;
}
